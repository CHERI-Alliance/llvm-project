//===--- RISCVCheriCommonLoadAddress.cpp - Common address materialization -===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Group address materialization instructions for read-only and read-write uses
// of the same globals, such that CSE can deduplicate effectively.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVTargetMachine.h"
#include "llvm/CodeGen/MachineDominators.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Debug.h"
#include "llvm/Target/TargetOptions.h"
#include <optional>
using namespace llvm;

#define DEBUG_TYPE "riscv-cheri-common-load-address"
#define RISCV_CHERI_COMMON_LOAD_ADDRESS_NAME "RISC-V CHERI Common Load Address"
namespace {

class RISCVCheriCommonLoadAddress : public MachineFunctionPass {
  const RISCVSubtarget *ST = nullptr;
  const RISCVInstrInfo *TII;
  MachineRegisterInfo *MRI;
  DenseMap<std::pair<const GlobalValue *, unsigned>, SmallVector<MachineInstr *, 2>> BaseMIs;
  DenseMap<MachineInstr *, SmallVector<MachineInstr *, 2>> DupMIs;

public:
  static char ID;

  bool searchMBB(MachineBasicBlock &MBB, MachineDominatorTree *DT);
  bool runOnMachineFunction(MachineFunction &Fn) override;

  RISCVCheriCommonLoadAddress() : MachineFunctionPass(ID) {}

  MachineFunctionProperties getRequiredProperties() const override {
    return MachineFunctionProperties().set(
        MachineFunctionProperties::Property::IsSSA);
  }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    AU.addRequired<MachineDominatorTreeWrapperPass>();
    AU.addPreserved<MachineDominatorTreeWrapperPass>();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

  StringRef getPassName() const override {
    return RISCV_CHERI_COMMON_LOAD_ADDRESS_NAME;
  }
};
} // end anonymous namespace

char RISCVCheriCommonLoadAddress::ID = 0;
INITIALIZE_PASS(RISCVCheriCommonLoadAddress, DEBUG_TYPE,
                RISCV_CHERI_COMMON_LOAD_ADDRESS_NAME, false, false)

bool RISCVCheriCommonLoadAddress::searchMBB(MachineBasicBlock &MBB,
                                            MachineDominatorTree *DT) {
  bool FoundCandidates = false;
  for (MachineInstr &MI : MBB) {
    if ((MI.getOpcode() == RISCV::PseudoCLGC ||
         MI.getOpcode() == RISCV::PseudoCLLC) && MI.getOperand(1).isGlobal()) {
      FoundCandidates = true;
      LLVM_DEBUG(dbgs() << "Checking " << MI << " as either base or duplicate\n");
      const GlobalValue *GV = MI.getOperand(1).getGlobal();
      unsigned Flags = MI.getOperand(1).getTargetFlags();
      SmallVector<MachineInstr *, 2> &DefMIs = BaseMIs[{GV, Flags}];
      if (DefMIs.empty()) {
        // We haven't encountered any existing load addresses for this global.
        LLVM_DEBUG(dbgs() << "Considering " << MI << " as a potential base\n");
        DefMIs.push_back(&MI);
        continue;
      }

      // There are existing load addresses for this global; look through them to
      // see if any are reusable at this point.
      MachineInstr *UsableDef = nullptr;
      for (MachineInstr *DefMI : DefMIs) {
        if (DT->dominates(DefMI, &MI)) {
          UsableDef = DefMI;
          break;
        }
      }
      if (!UsableDef) {
        LLVM_DEBUG(dbgs() << "Considering " << MI << " as a potential base; "
                          << "existing base defs do not dominate\n");
        DefMIs.push_back(&MI);
        continue;
      }

      LLVM_DEBUG(dbgs() << "Considering " << MI << " as a duplicate of base: "
                        << *UsableDef << "\n");
      DupMIs[UsableDef].push_back(&MI);
    }
  }
  return FoundCandidates;
}

bool RISCVCheriCommonLoadAddress::runOnMachineFunction(MachineFunction &Fn) {
  if (skipFunction(Fn.getFunction()))
    return false;

  SmallVector<MachineDomTreeNode*, 32> Scopes;
  SmallVector<MachineDomTreeNode*, 8> WorkList;
  DenseMap<MachineDomTreeNode*, unsigned> OpenChildren;

  LLVM_DEBUG(
      dbgs() << "********** "
             << RISCV_CHERI_COMMON_LOAD_ADDRESS_NAME
             << " **********\n"
             << "********** Function: " << Fn.getName() << '\n');

  ST = &Fn.getSubtarget<RISCVSubtarget>();
  TII = static_cast<const RISCVInstrInfo *>(ST->getInstrInfo());

  // This is a CHERI-specific pass.
  if (!ST->hasAnyCheriExt())
    return false;

  MVT PtrVT = ST->typeForCapabilities();

  MRI = &Fn.getRegInfo();

  BaseMIs.clear();
  DupMIs.clear();
  MachineDominatorTree *DT =
      &getAnalysis<MachineDominatorTreeWrapperPass>().getDomTree();
  MachineDomTreeNode *Node = DT->getRootNode();

  // The main logic in this pass involves collecting groups of CLLC+CLGCs that
  // could be deduplicated to use a single defining CLLC/CLGC. This means we
  // need to visit in an order that allows us to see any possible base
  // instructions before seeing any possible re-uses. We use a DFS walk of the
  // dominator tree to do this, then check individually whether instructions
  // dominate their potential re-uses.
  WorkList.push_back(Node);
  do {
    Node = WorkList.pop_back_val();
    Scopes.push_back(Node);
    OpenChildren[Node] = Node->getNumChildren();
    append_range(WorkList, Node->children());
  } while (!WorkList.empty());

  bool FoundCandidates = false;
  for (MachineDomTreeNode *N : Scopes)
    FoundCandidates |= searchMBB(*N->getBlock(), DT);

  // Nothing to do.
  if (!FoundCandidates)
    return false;

  LLVM_DEBUG(dbgs() <<
      "Preparing duplicate load addresses to be CSE-d with base defs\n");

  for (auto Entry : DupMIs) {
    MachineInstr *BaseMI = Entry.first;
    LLVM_DEBUG(dbgs() << "Checking duplicates of " << *BaseMI << "\n");

    // The point of this pass:
    // We'd prefer to use CLLC to load addresses because it's faster, however if
    // any of the load addresses in a deduplicatable group had to be CLGC we
    // should make all of them match, so CSE can deduplicate them, which overall
    // should end up being faster.
    bool ContainsCLGC = BaseMI->getOpcode() == RISCV::PseudoCLGC;
    for (MachineInstr *DupMI : Entry.second) {
      LLVM_DEBUG(dbgs() << "  duplicate " << *DupMI << "\n");
      if (DupMI->getOpcode() == RISCV::PseudoCLGC)
        ContainsCLGC = true;
    }

    // Need a machinememop on any CLGCs to enable CSE to see them as constant.
    MachineMemOperand *MemOp = Fn.getMachineMemOperand(
        MachinePointerInfo::getGOT(Fn),
        MachineMemOperand::MOLoad | MachineMemOperand::MODereferenceable |
            MachineMemOperand::MOInvariant,
        LLT(PtrVT), Align(PtrVT.getFixedSizeInBits() / 8));

    if (ContainsCLGC) {
      LLVM_DEBUG(dbgs() << "  group should be CLGC\n");
      BuildMI(*BaseMI->getParent(), BaseMI, BaseMI->getDebugLoc(), TII->get(RISCV::PseudoCLGC), BaseMI->getOperand(0).getReg())
          .add(BaseMI->getOperand(1))
          .addMemOperand(MemOp);
      BaseMI->removeFromParent();
      for (MachineInstr *DupMI : Entry.second) {
        BuildMI(*DupMI->getParent(), DupMI, DupMI->getDebugLoc(), TII->get(RISCV::PseudoCLGC), DupMI->getOperand(0).getReg())
            .add(DupMI->getOperand(1))
            .addMemOperand(MemOp);
        DupMI->removeFromParent();
      }
    }
  }

  return true;
}

/// Returns an instance of the CHERI Common Load Address Optimization pass.
FunctionPass *llvm::createRISCVCheriCommonLoadAddressPass() {
  return new RISCVCheriCommonLoadAddress();
}
