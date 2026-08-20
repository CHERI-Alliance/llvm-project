//===-- RISCVTransformForCheriCMV.cpp - Aid compression of moves on CHERI -===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// On ZCheriPurecap, we have overridden the encoding for the compressed integer
// move with our compressed capability move. This means that no patterns for
// integer moves will generate a compressed instruction. Since a capability move
// is identical to an integer move of its corresponding integer subregister, we
// can use the capability move instead. Since tablegen's compress code is not
// capable of expressing or handling this relationship, we use this pass to
// rewrite integer move patterns into capability move patterns, that will later
// get compressed as normal into the compressed capability moves.
//
// Note this is not necessarily just a code size optimisation; some targets will
// have faster paths for cmv instructions.
//
//===----------------------------------------------------------------------===//

#include "RISCV.h"
#include "RISCVSubtarget.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "riscv-make-compressible"
#define RISCV_CHERI_CMV_OPT_NAME "RISC-V Transform for CHERI CMV"

namespace {

struct RISCVCheriCMVOpt : public MachineFunctionPass {
  static char ID;

  bool runOnMachineFunction(MachineFunction &Fn) override;

  RISCVCheriCMVOpt() : MachineFunctionPass(ID) {}

  StringRef getPassName() const override { return RISCV_CHERI_CMV_OPT_NAME; }
};
} // namespace

char RISCVCheriCMVOpt::ID = 0;
INITIALIZE_PASS(RISCVCheriCMVOpt, "riscv-transform-for-cheri-cmv",
                RISCV_CHERI_CMV_OPT_NAME, false, false)

static bool updateToCompressibleCADDI(MachineInstr &MI) {
  const RISCVSubtarget &STI = MI.getMF()->getSubtarget<RISCVSubtarget>();
  const RISCVInstrInfo &TII = *STI.getInstrInfo();

  Register DstReg;
  Register SrcReg;

  switch (MI.getOpcode()) {
  default:
    return false;
  case RISCV::ADDI: {
    DstReg = MI.getOperand(0).getReg();
    SrcReg = MI.getOperand(1).getReg();
    uint64_t Imm = MI.getOperand(2).getImm();

    // Will this be a move?
    if (SrcReg == RISCV::X0 || Imm != 0)
      return false;

    break;
  }
  case RISCV::ADD: {
    DstReg = MI.getOperand(0).getReg();
    Register Rs1 = MI.getOperand(1).getReg();
    Register Rs2 = MI.getOperand(2).getReg();

    // Will this be a move?
    if (Rs1 == RISCV::X0 && Rs2 != RISCV::X0)
      SrcReg = Rs2;
    else if (Rs2 == RISCV::X0 && Rs1 != RISCV::X0)
      SrcReg = Rs1;
    else
      return false;

    break;
  }
  }

  MI.setDesc(TII.get(RISCV::CADDI));
  MI.getOperand(0).setReg(DstReg - RISCV::X0 + RISCV::C0);
  MI.getOperand(1).setReg(SrcReg - RISCV::X0 + RISCV::C0);
  // May not already be an immediate hence we cannot use setImm.
  MI.getOperand(2).ChangeToImmediate(0);

  return true;
}

bool RISCVCheriCMVOpt::runOnMachineFunction(MachineFunction &Fn) {
  if (skipFunction(Fn.getFunction()))
    return false;

  const RISCVSubtarget &STI = Fn.getSubtarget<RISCVSubtarget>();
  const RISCVInstrInfo &TII = *STI.getInstrInfo();

  // These optimizations only make sense if compressed instructions are emitted,
  // and we are using ZCheriPurecap.
  if (!STI.hasStdExtCOrZca() ||
      !STI.hasFeature(RISCV::FeatureStdExtZCheriPureCap) ||
      STI.hasFeature(RISCV::FeatureCheriNoRVC))
    return false;

  // Try to update to compressible CADDI.
  bool Changed = false;
  for (MachineBasicBlock &MBB : Fn) {
    LLVM_DEBUG(dbgs() << "MBB: " << MBB.getName() << "\n");
    for (MachineInstr &MI : MBB)
      Changed |= updateToCompressibleCADDI(MI);
  }

  return Changed;
}

/// Returns an instance of the CHERI CMV Optimization pass.
FunctionPass *llvm::createRISCVCheriCMVOptPass() {
  return new RISCVCheriCMVOpt();
}
