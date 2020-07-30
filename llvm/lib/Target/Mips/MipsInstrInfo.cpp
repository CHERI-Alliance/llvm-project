//===- MipsInstrInfo.cpp - Mips Instruction Information -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the Mips implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "MipsInstrInfo.h"
#include "MCTargetDesc/MipsBaseInfo.h"
#include "MCTargetDesc/MipsMCTargetDesc.h"
#include "MipsSubtarget.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineOperand.h"
#include "llvm/CodeGen/TargetOpcodes.h"
#include "llvm/CodeGen/TargetSubtargetInfo.h"
#include "llvm/IR/DebugInfoMetadata.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/MC/MCInstrDesc.h"
#include "llvm/Target/TargetMachine.h"
#include <cassert>

using namespace llvm;

#define GET_INSTRINFO_CTOR_DTOR
#include "MipsGenInstrInfo.inc"

// Pin the vtable to this file.
void MipsInstrInfo::anchor() {}

MipsInstrInfo::MipsInstrInfo(const MipsSubtarget &STI, unsigned UncondBr)
    : MipsGenInstrInfo(STI.isABI_CheriPureCap() ?
          Mips::ADJCALLSTACKCAPDOWN : Mips::ADJCALLSTACKDOWN,
        STI.isABI_CheriPureCap() ?
          Mips::ADJCALLSTACKCAPUP: Mips::ADJCALLSTACKUP),
      Subtarget(STI), UncondBrOpc(UncondBr) {}

const MipsInstrInfo *MipsInstrInfo::create(MipsSubtarget &STI) {
  if (STI.inMips16Mode())
    return createMips16InstrInfo(STI);

  return createMipsSEInstrInfo(STI);
}

bool MipsInstrInfo::isZeroImm(const MachineOperand &op) const {
  return op.isImm() && op.getImm() == 0;
}

/// insertNoop - If data hazard condition is found insert the target nop
/// instruction.
// FIXME: This appears to be dead code.
void MipsInstrInfo::
insertNoop(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI) const
{
  DebugLoc DL;
  BuildMI(MBB, MI, DL, get(Mips::NOP));
}

MachineMemOperand *
MipsInstrInfo::GetMemOperand(MachineBasicBlock &MBB, int FI,
                             MachineMemOperand::Flags Flags) const {
  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();

  return MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(MF, FI),
                                 Flags, MFI.getObjectSize(FI),
                                 MFI.getObjectAlign(FI));
}

//===----------------------------------------------------------------------===//
// Branch Analysis
//===----------------------------------------------------------------------===//

void MipsInstrInfo::AnalyzeCondBr(const MachineInstr *Inst, unsigned Opc,
                                  MachineBasicBlock *&BB,
                                  SmallVectorImpl<MachineOperand> &Cond) const {
  assert(getAnalyzableBrOpc(Opc) && "Not an analyzable branch");
  int NumOp = Inst->getNumExplicitOperands();

  // for both int and fp branches, the last explicit operand is the
  // MBB.
  BB = Inst->getOperand(NumOp-1).getMBB();
  Cond.push_back(MachineOperand::CreateImm(Opc));

  for (int i = 0; i < NumOp-1; i++)
    Cond.push_back(Inst->getOperand(i));
}

bool MipsInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                  MachineBasicBlock *&TBB,
                                  MachineBasicBlock *&FBB,
                                  SmallVectorImpl<MachineOperand> &Cond,
                                  bool AllowModify) const {
  SmallVector<MachineInstr*, 2> BranchInstrs;
  BranchType BT = analyzeBranch(MBB, TBB, FBB, Cond, AllowModify, BranchInstrs);

  return (BT == BT_None) || (BT == BT_Indirect);
}

void MipsInstrInfo::BuildCondBr(MachineBasicBlock &MBB, MachineBasicBlock *TBB,
                                const DebugLoc &DL,
                                ArrayRef<MachineOperand> Cond) const {
  unsigned Opc = Cond[0].getImm();
  const MCInstrDesc &MCID = get(Opc);
  MachineInstrBuilder MIB = BuildMI(&MBB, DL, MCID);

  for (unsigned i = 1; i < Cond.size(); ++i) {
    assert((Cond[i].isImm() || Cond[i].isReg()) &&
           "Cannot copy operand for conditional branch!");
    MIB.add(Cond[i]);
  }
  MIB.addMBB(TBB);
}

unsigned MipsInstrInfo::insertBranch(MachineBasicBlock &MBB,
                                     MachineBasicBlock *TBB,
                                     MachineBasicBlock *FBB,
                                     ArrayRef<MachineOperand> Cond,
                                     const DebugLoc &DL,
                                     int *BytesAdded) const {
  // Shouldn't be a fall through.
  assert(TBB && "insertBranch must not be told to insert a fallthrough");
  assert(!BytesAdded && "code size not handled");

  // # of condition operands:
  //  Unconditional branches: 0
  //  Floating point branches: 1 (opc)
  //  Int BranchZero: 2 (opc, reg)
  //  Int Branch: 3 (opc, reg0, reg1)
  assert((Cond.size() <= 3) &&
         "# of Mips branch conditions must be <= 3!");

  // Two-way Conditional branch.
  if (FBB) {
    BuildCondBr(MBB, TBB, DL, Cond);
    BuildMI(&MBB, DL, get(UncondBrOpc)).addMBB(FBB);
    return 2;
  }

  // One way branch.
  // Unconditional branch.
  if (Cond.empty())
    BuildMI(&MBB, DL, get(UncondBrOpc)).addMBB(TBB);
  else // Conditional branch.
    BuildCondBr(MBB, TBB, DL, Cond);
  return 1;
}

unsigned MipsInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                     int *BytesRemoved) const {
  assert(!BytesRemoved && "code size not handled");

  MachineBasicBlock::reverse_iterator I = MBB.rbegin(), REnd = MBB.rend();
  unsigned removed = 0;

  // Up to 2 branches are removed.
  // Note that indirect branches are not removed.
  while (I != REnd && removed < 2) {
    // Skip past debug instructions.
    if (I->isDebugInstr()) {
      ++I;
      continue;
    }
    if (!getAnalyzableBrOpc(I->getOpcode()))
      break;
    // Remove the branch.
    I->eraseFromParent();
    I = MBB.rbegin();
    ++removed;
  }

  return removed;
}

/// reverseBranchCondition - Return the inverse opcode of the
/// specified Branch instruction.
bool MipsInstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  assert( (Cond.size() && Cond.size() <= 3) &&
          "Invalid Mips branch condition!");
  Cond[0].setImm(getOppositeBranchOpc(Cond[0].getImm()));
  return false;
}

MipsInstrInfo::BranchType MipsInstrInfo::analyzeBranch(
    MachineBasicBlock &MBB, MachineBasicBlock *&TBB, MachineBasicBlock *&FBB,
    SmallVectorImpl<MachineOperand> &Cond, bool AllowModify,
    SmallVectorImpl<MachineInstr *> &BranchInstrs) const {
  MachineBasicBlock::reverse_iterator I = MBB.rbegin(), REnd = MBB.rend();

  // Skip all the debug instructions.
  while (I != REnd && I->isDebugInstr())
    ++I;

  if (I == REnd || !isUnpredicatedTerminator(*I)) {
    // This block ends with no branches (it just falls through to its succ).
    // Leave TBB/FBB null.
    TBB = FBB = nullptr;
    return BT_NoBranch;
  }

  MachineInstr *LastInst = &*I;
  unsigned LastOpc = LastInst->getOpcode();
  BranchInstrs.push_back(LastInst);

  // Not an analyzable branch (e.g., indirect jump).
  if (!getAnalyzableBrOpc(LastOpc))
    return LastInst->isIndirectBranch() ? BT_Indirect : BT_None;

  // Get the second to last instruction in the block.
  unsigned SecondLastOpc = 0;
  MachineInstr *SecondLastInst = nullptr;

  // Skip past any debug instruction to see if the second last actual
  // is a branch.
  ++I;
  while (I != REnd && I->isDebugInstr())
    ++I;

  if (I != REnd) {
    SecondLastInst = &*I;
    SecondLastOpc = getAnalyzableBrOpc(SecondLastInst->getOpcode());

    // Not an analyzable branch (must be an indirect jump).
    if (isUnpredicatedTerminator(*SecondLastInst) && !SecondLastOpc)
      return BT_None;
  }

  // If there is only one terminator instruction, process it.
  if (!SecondLastOpc) {
    // Unconditional branch.
    if (LastInst->isUnconditionalBranch()) {
      TBB = LastInst->getOperand(0).getMBB();
      return BT_Uncond;
    }

    // Conditional branch
    AnalyzeCondBr(LastInst, LastOpc, TBB, Cond);
    return BT_Cond;
  }

  // If we reached here, there are two branches.
  // If there are three terminators, we don't know what sort of block this is.
  if (++I != REnd && isUnpredicatedTerminator(*I))
    return BT_None;

  BranchInstrs.insert(BranchInstrs.begin(), SecondLastInst);

  // If second to last instruction is an unconditional branch,
  // analyze it and remove the last instruction.
  if (SecondLastInst->isUnconditionalBranch()) {
    // Return if the last instruction cannot be removed.
    if (!AllowModify)
      return BT_None;

    TBB = SecondLastInst->getOperand(0).getMBB();
    LastInst->eraseFromParent();
    BranchInstrs.pop_back();
    return BT_Uncond;
  }

  // Conditional branch followed by an unconditional branch.
  // The last one must be unconditional.
  if (!LastInst->isUnconditionalBranch())
    return BT_None;

  AnalyzeCondBr(SecondLastInst, SecondLastOpc, TBB, Cond);
  FBB = LastInst->getOperand(0).getMBB();

  return BT_CondUncond;
}

bool MipsInstrInfo::isBranchOffsetInRange(unsigned BranchOpc,
                                          int64_t BrOffset) const {
  switch (BranchOpc) {
  case Mips::B:
  case Mips::BAL:
  case Mips::BAL_BR:
  case Mips::BAL_BR_MM:
  case Mips::BC1F:
  case Mips::BC1FL:
  case Mips::BC1T:
  case Mips::BC1TL:
  case Mips::BEQ:     case Mips::BEQ64:
  case Mips::BEQL:
  case Mips::BGEZ:    case Mips::BGEZ64:
  case Mips::BGEZL:
  case Mips::BGEZAL:
  case Mips::BGEZALL:
  case Mips::BGTZ:    case Mips::BGTZ64:
  case Mips::BGTZL:
  case Mips::BLEZ:    case Mips::BLEZ64:
  case Mips::BLEZL:
  case Mips::BLTZ:    case Mips::BLTZ64:
  case Mips::BLTZL:
  case Mips::BLTZAL:
  case Mips::BLTZALL:
  case Mips::BNE:     case Mips::BNE64:
  case Mips::BNEL:
    return isInt<18>(BrOffset);

  // microMIPSr3 branches
  case Mips::B_MM:
  case Mips::BC1F_MM:
  case Mips::BC1T_MM:
  case Mips::BEQ_MM:
  case Mips::BGEZ_MM:
  case Mips::BGEZAL_MM:
  case Mips::BGTZ_MM:
  case Mips::BLEZ_MM:
  case Mips::BLTZ_MM:
  case Mips::BLTZAL_MM:
  case Mips::BNE_MM:
  case Mips::BEQZC_MM:
  case Mips::BNEZC_MM:
    return isInt<17>(BrOffset);

  // microMIPSR3 short branches.
  case Mips::B16_MM:
    return isInt<11>(BrOffset);

  case Mips::BEQZ16_MM:
  case Mips::BNEZ16_MM:
    return isInt<8>(BrOffset);

  // MIPSR6 branches.
  case Mips::BALC:
  case Mips::BC:
    return isInt<28>(BrOffset);

  case Mips::BC1EQZ:
  case Mips::BC1NEZ:
  case Mips::BC2EQZ:
  case Mips::BC2NEZ:
  case Mips::BEQC:   case Mips::BEQC64:
  case Mips::BNEC:   case Mips::BNEC64:
  case Mips::BGEC:   case Mips::BGEC64:
  case Mips::BGEUC:  case Mips::BGEUC64:
  case Mips::BGEZC:  case Mips::BGEZC64:
  case Mips::BGTZC:  case Mips::BGTZC64:
  case Mips::BLEZC:  case Mips::BLEZC64:
  case Mips::BLTC:   case Mips::BLTC64:
  case Mips::BLTUC:  case Mips::BLTUC64:
  case Mips::BLTZC:  case Mips::BLTZC64:
  case Mips::BNVC:
  case Mips::BOVC:
  case Mips::BGEZALC:
  case Mips::BEQZALC:
  case Mips::BGTZALC:
  case Mips::BLEZALC:
  case Mips::BLTZALC:
  case Mips::BNEZALC:
    return isInt<18>(BrOffset);

  case Mips::BEQZC:  case Mips::BEQZC64:
  case Mips::BNEZC:  case Mips::BNEZC64:
    return isInt<23>(BrOffset);

  // microMIPSR6 branches
  case Mips::BC16_MMR6:
    return isInt<11>(BrOffset);

  case Mips::BEQZC16_MMR6:
  case Mips::BNEZC16_MMR6:
    return isInt<8>(BrOffset);

  case Mips::BALC_MMR6:
  case Mips::BC_MMR6:
    return isInt<27>(BrOffset);

  case Mips::BC1EQZC_MMR6:
  case Mips::BC1NEZC_MMR6:
  case Mips::BC2EQZC_MMR6:
  case Mips::BC2NEZC_MMR6:
  case Mips::BGEZALC_MMR6:
  case Mips::BEQZALC_MMR6:
  case Mips::BGTZALC_MMR6:
  case Mips::BLEZALC_MMR6:
  case Mips::BLTZALC_MMR6:
  case Mips::BNEZALC_MMR6:
  case Mips::BNVC_MMR6:
  case Mips::BOVC_MMR6:
    return isInt<17>(BrOffset);

  case Mips::BEQC_MMR6:
  case Mips::BNEC_MMR6:
  case Mips::BGEC_MMR6:
  case Mips::BGEUC_MMR6:
  case Mips::BGEZC_MMR6:
  case Mips::BGTZC_MMR6:
  case Mips::BLEZC_MMR6:
  case Mips::BLTC_MMR6:
  case Mips::BLTUC_MMR6:
  case Mips::BLTZC_MMR6:
    return isInt<18>(BrOffset);

  case Mips::BEQZC_MMR6:
  case Mips::BNEZC_MMR6:
    return isInt<23>(BrOffset);

  // DSP branches.
  case Mips::BPOSGE32:
    return isInt<18>(BrOffset);
  case Mips::BPOSGE32_MM:
  case Mips::BPOSGE32C_MMR3:
    return isInt<17>(BrOffset);

  // cnMIPS branches.
  case Mips::BBIT0:
  case Mips::BBIT032:
  case Mips::BBIT1:
  case Mips::BBIT132:
    return isInt<18>(BrOffset);

  // CHERI branches:
  case Mips::CBTU:
  case Mips::CBTS:
  case Mips::CBEZ:
  case Mips::CBNZ:
    return isInt<18>(BrOffset);


  // MSA branches.
  case Mips::BZ_B:
  case Mips::BZ_H:
  case Mips::BZ_W:
  case Mips::BZ_D:
  case Mips::BZ_V:
  case Mips::BNZ_B:
  case Mips::BNZ_H:
  case Mips::BNZ_W:
  case Mips::BNZ_D:
  case Mips::BNZ_V:
    return isInt<18>(BrOffset);
  }

  llvm_unreachable("Unknown branch instruction!");
}

/// Return the corresponding compact (no delay slot) form of a branch.
unsigned MipsInstrInfo::getEquivalentCompactForm(
    const MachineBasicBlock::iterator I) const {
  unsigned Opcode = I->getOpcode();
  bool canUseShortMicroMipsCTI = false;

  if (Subtarget.inMicroMipsMode()) {
    switch (Opcode) {
    case Mips::BNE:
    case Mips::BNE_MM:
    case Mips::BEQ:
    case Mips::BEQ_MM:
    // microMIPS has NE,EQ branches that do not have delay slots provided one
    // of the operands is zero.
      if (I->getOperand(1).getReg() == Subtarget.getABI().GetZeroReg())
        canUseShortMicroMipsCTI = true;
      break;
    // For microMIPS the PseudoReturn and PseudoIndirectBranch are always
    // expanded to JR_MM, so they can be replaced with JRC16_MM.
    case Mips::JR:
    case Mips::PseudoReturn:
    case Mips::PseudoIndirectBranch:
      canUseShortMicroMipsCTI = true;
      break;
    }
  }

  // MIPSR6 forbids both operands being the zero register.
  if (Subtarget.hasMips32r6() && (I->getNumOperands() > 1) &&
      (I->getOperand(0).isReg() &&
       (I->getOperand(0).getReg() == Mips::ZERO ||
        I->getOperand(0).getReg() == Mips::ZERO_64)) &&
      (I->getOperand(1).isReg() &&
       (I->getOperand(1).getReg() == Mips::ZERO ||
        I->getOperand(1).getReg() == Mips::ZERO_64)))
    return 0;

  if (Subtarget.hasMips32r6() || canUseShortMicroMipsCTI) {
    switch (Opcode) {
    case Mips::B:
      return Mips::BC;
    case Mips::BAL:
      return Mips::BALC;
    case Mips::BEQ:
    case Mips::BEQ_MM:
      if (canUseShortMicroMipsCTI)
        return Mips::BEQZC_MM;
      else if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BEQC;
    case Mips::BNE:
    case Mips::BNE_MM:
      if (canUseShortMicroMipsCTI)
        return Mips::BNEZC_MM;
      else if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BNEC;
    case Mips::BGE:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BGEC;
    case Mips::BGEU:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BGEUC;
    case Mips::BGEZ:
      return Mips::BGEZC;
    case Mips::BGTZ:
      return Mips::BGTZC;
    case Mips::BLEZ:
      return Mips::BLEZC;
    case Mips::BLT:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BLTC;
    case Mips::BLTU:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BLTUC;
    case Mips::BLTZ:
      return Mips::BLTZC;
    case Mips::BEQ64:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BEQC64;
    case Mips::BNE64:
      if (I->getOperand(0).getReg() == I->getOperand(1).getReg())
        return 0;
      return Mips::BNEC64;
    case Mips::BGTZ64:
      return Mips::BGTZC64;
    case Mips::BGEZ64:
      return Mips::BGEZC64;
    case Mips::BLTZ64:
      return Mips::BLTZC64;
    case Mips::BLEZ64:
      return Mips::BLEZC64;
    // For MIPSR6, the instruction 'jic' can be used for these cases. Some
    // tools will accept 'jrc reg' as an alias for 'jic 0, $reg'.
    case Mips::JR:
    case Mips::PseudoIndirectBranchR6:
    case Mips::PseudoReturn:
    case Mips::TAILCALLR6REG:
      if (canUseShortMicroMipsCTI)
        return Mips::JRC16_MM;
      return Mips::JIC;
    case Mips::JALRPseudo:
      return Mips::JIALC;
    case Mips::JR64:
    case Mips::PseudoIndirectBranch64R6:
    case Mips::PseudoReturn64:
    case Mips::TAILCALL64R6REG:
      return Mips::JIC64;
    case Mips::JALR64Pseudo:
      return Mips::JIALC64;
    default:
      return 0;
    }
  }

  return 0;
}

/// Predicate for distingushing between control transfer instructions and all
/// other instructions for handling forbidden slots. Consider inline assembly
/// as unsafe as well.
bool MipsInstrInfo::SafeInForbiddenSlot(const MachineInstr &MI) const {
  if (MI.isInlineAsm())
    return false;

  return (MI.getDesc().TSFlags & MipsII::IsCTI) == 0;
}

/// Predicate for distingushing instructions that have forbidden slots.
bool MipsInstrInfo::HasForbiddenSlot(const MachineInstr &MI) const {
  return (MI.getDesc().TSFlags & MipsII::HasForbiddenSlot) != 0;
}

/// Return the number of bytes of code the specified instruction may be.
unsigned MipsInstrInfo::getInstSizeInBytes(const MachineInstr &MI) const {
  switch (MI.getOpcode()) {
  default:
    return MI.getDesc().getSize();
  case  TargetOpcode::INLINEASM:
  case  TargetOpcode::INLINEASM_BR: {       // Inline Asm: Variable size.
    const MachineFunction *MF = MI.getParent()->getParent();
    const char *AsmStr = MI.getOperand(0).getSymbolName();
    return getInlineAsmLength(AsmStr, *MF->getTarget().getMCAsmInfo());
  }
  case Mips::CONSTPOOL_ENTRY:
    // If this machine instr is a constant pool entry, its size is recorded as
    // operand #2.
    return MI.getOperand(2).getImm();
  }
}

MachineInstrBuilder
MipsInstrInfo::genInstrWithNewOpc(unsigned NewOpc,
                                  MachineBasicBlock::iterator I) const {
  MachineInstrBuilder MIB;

  // Certain branches have two forms: e.g beq $1, $zero, dest vs beqz $1, dest
  // Pick the zero form of the branch for readable assembly and for greater
  // branch distance in non-microMIPS mode.
  // Additional MIPSR6 does not permit the use of register $zero for compact
  // branches.
  // FIXME: Certain atomic sequences on mips64 generate 32bit references to
  // Mips::ZERO, which is incorrect. This test should be updated to use
  // Subtarget.getABI().GetZeroReg() when those atomic sequences and others
  // are fixed.
  int ZeroOperandPosition = -1;
  bool BranchWithZeroOperand = false;
  if (I->isBranch() && !I->isPseudo()) {
    auto TRI = I->getParent()->getParent()->getSubtarget().getRegisterInfo();
    ZeroOperandPosition = I->findRegisterUseOperandIdx(Mips::ZERO, false, TRI);
    BranchWithZeroOperand = ZeroOperandPosition != -1;
  }

  if (BranchWithZeroOperand) {
    switch (NewOpc) {
    case Mips::BEQC:
      NewOpc = Mips::BEQZC;
      break;
    case Mips::BNEC:
      NewOpc = Mips::BNEZC;
      break;
    case Mips::BGEC:
      NewOpc = Mips::BGEZC;
      break;
    case Mips::BLTC:
      NewOpc = Mips::BLTZC;
      break;
    case Mips::BEQC64:
      NewOpc = Mips::BEQZC64;
      break;
    case Mips::BNEC64:
      NewOpc = Mips::BNEZC64;
      break;
    }
  }

  MIB = BuildMI(*I->getParent(), I, I->getDebugLoc(), get(NewOpc));

  // For MIPSR6 JI*C requires an immediate 0 as an operand, JIALC(64) an
  // immediate 0 as an operand and requires the removal of it's implicit-def %ra
  // implicit operand as copying the implicit operations of the instructio we're
  // looking at will give us the correct flags.
  if (NewOpc == Mips::JIC || NewOpc == Mips::JIALC || NewOpc == Mips::JIC64 ||
      NewOpc == Mips::JIALC64) {

    if (NewOpc == Mips::JIALC || NewOpc == Mips::JIALC64)
      MIB->RemoveOperand(0);

    for (unsigned J = 0, E = I->getDesc().getNumOperands(); J < E; ++J) {
      MIB.add(I->getOperand(J));
    }

    MIB.addImm(0);

    // If I has an MCSymbol operand (used by asm printer, to emit R_MIPS_JALR),
    // add it to the new instruction.
    for (unsigned J = I->getDesc().getNumOperands(), E = I->getNumOperands();
         J < E; ++J) {
      const MachineOperand &MO = I->getOperand(J);
      if (MO.isMCSymbol() && (MO.getTargetFlags() & MipsII::MO_JALR))
        MIB.addSym(MO.getMCSymbol(), MipsII::MO_JALR);
    }


  } else {
    for (unsigned J = 0, E = I->getDesc().getNumOperands(); J < E; ++J) {
      if (BranchWithZeroOperand && (unsigned)ZeroOperandPosition == J)
        continue;

      MIB.add(I->getOperand(J));
    }
  }

  MIB.copyImplicitOps(*I);
  MIB.cloneMemRefs(*I);
  return MIB;
}

bool MipsInstrInfo::findCommutedOpIndices(const MachineInstr &MI,
                                          unsigned &SrcOpIdx1,
                                          unsigned &SrcOpIdx2) const {
  assert(!MI.isBundle() &&
         "TargetInstrInfo::findCommutedOpIndices() can't handle bundles");

  const MCInstrDesc &MCID = MI.getDesc();
  if (!MCID.isCommutable())
    return false;

  switch (MI.getOpcode()) {
  case Mips::DPADD_U_H:
  case Mips::DPADD_U_W:
  case Mips::DPADD_U_D:
  case Mips::DPADD_S_H:
  case Mips::DPADD_S_W:
  case Mips::DPADD_S_D:
    // The first operand is both input and output, so it should not commute
    if (!fixCommutedOpIndices(SrcOpIdx1, SrcOpIdx2, 2, 3))
      return false;

    if (!MI.getOperand(SrcOpIdx1).isReg() || !MI.getOperand(SrcOpIdx2).isReg())
      return false;
    return true;
  }
  return TargetInstrInfo::findCommutedOpIndices(MI, SrcOpIdx1, SrcOpIdx2);
}

// ins, ext, dext*, dins have the following constraints:
// X <= pos      <  Y
// X <  size     <= Y
// X <  pos+size <= Y
//
// dinsm and dinsu have the following constraints:
// X <= pos      <  Y
// X <= size     <= Y
// X <  pos+size <= Y
//
// The callee of verifyInsExtInstruction however gives the bounds of
// dins[um] like the other (d)ins (d)ext(um) instructions, so that this
// function doesn't have to vary it's behaviour based on the instruction
// being checked.
static bool verifyInsExtInstruction(const MachineInstr &MI, StringRef &ErrInfo,
                                    const int64_t PosLow, const int64_t PosHigh,
                                    const int64_t SizeLow,
                                    const int64_t SizeHigh,
                                    const int64_t BothLow,
                                    const int64_t BothHigh) {
  MachineOperand MOPos = MI.getOperand(2);
  if (!MOPos.isImm()) {
    ErrInfo = "Position is not an immediate!";
    return false;
  }
  int64_t Pos = MOPos.getImm();
  if (!((PosLow <= Pos) && (Pos < PosHigh))) {
    ErrInfo = "Position operand is out of range!";
    return false;
  }

  MachineOperand MOSize = MI.getOperand(3);
  if (!MOSize.isImm()) {
    ErrInfo = "Size operand is not an immediate!";
    return false;
  }
  int64_t Size = MOSize.getImm();
  if (!((SizeLow < Size) && (Size <= SizeHigh))) {
    ErrInfo = "Size operand is out of range!";
    return false;
  }

  if (!((BothLow < (Pos + Size)) && ((Pos + Size) <= BothHigh))) {
    ErrInfo = "Position + Size is out of range!";
    return false;
  }

  return true;
}

//  Perform target specific instruction verification.
template<unsigned Width, unsigned Scale>
bool checkScaledImmediate(const MachineInstr &MI, StringRef& ErrInfo, unsigned OpndIdx) {
  assert(MI.getDesc().OpInfo[OpndIdx].OperandType == MCOI::OPERAND_IMMEDIATE);
  if (MI.getOperand(OpndIdx).isImm() && !isShiftedInt<Width, Scale>(MI.getOperand(OpndIdx).getImm())) {
    ErrInfo = "Operand immediate is not representable!";
    return false;
  }
  return true;
}


bool MipsInstrInfo::verifyInstruction(const MachineInstr &MI,
                                      StringRef &ErrInfo) const {
  // Verify that ins and ext instructions are well formed.
  switch (MI.getOpcode()) {
    case Mips::EXT:
    case Mips::EXT_MM:
    case Mips::INS:
    case Mips::INS_MM:
    case Mips::DINS:
      return verifyInsExtInstruction(MI, ErrInfo, 0, 32, 0, 32, 0, 32);
    case Mips::DINSM:
      // The ISA spec has a subtle difference between dinsm and dextm
      // in that it says:
      // 2 <= size <= 64 for 'dinsm' but 'dextm' has 32 < size <= 64.
      // To make the bounds checks similar, the range 1 < size <= 64 is checked
      // for 'dinsm'.
      return verifyInsExtInstruction(MI, ErrInfo, 0, 32, 1, 64, 32, 64);
    case Mips::DINSU:
      // The ISA spec has a subtle difference between dinsu and dextu in that
      // the size range of dinsu is specified as 1 <= size <= 32 whereas size
      // for dextu is 0 < size <= 32. The range checked for dinsu here is
      // 0 < size <= 32, which is equivalent and similar to dextu.
      return verifyInsExtInstruction(MI, ErrInfo, 32, 64, 0, 32, 32, 64);
    case Mips::DEXT:
      return verifyInsExtInstruction(MI, ErrInfo, 0, 32, 0, 32, 0, 63);
    case Mips::DEXTM:
      return verifyInsExtInstruction(MI, ErrInfo, 0, 32, 32, 64, 32, 64);
    case Mips::DEXTU:
      return verifyInsExtInstruction(MI, ErrInfo, 32, 64, 0, 32, 32, 64);
    case Mips::TAILCALLREG:
    case Mips::PseudoIndirectBranch:
    case Mips::JR:
    case Mips::JR64:
    case Mips::JALR:
    case Mips::JALR64:
    case Mips::JALRPseudo:
      if (!Subtarget.useIndirectJumpsHazard())
        return true;

      ErrInfo = "invalid instruction when using jump guards!";
      return false;

    // Check that we don't use the cjalr output register (usually $c17) in the
    // delay slot since it will have changed
    case Mips::CapJumpLinkPseudo:
    case Mips::CJALR:
      // errs() << "CAPJUMPLINK: (delay slot: " << MI.hasDelaySlot()
      //    << ", bundle size: " << MI.getBundleSize() << ") "; MI.dump();
      if (MI.isBundledWithSucc()) {
        auto &OutputOp =
            MI.getOpcode() == Mips::CJALR ? MI.getOperand(0) : MI.getOperand(2);
        if (MI.getOpcode() ==
            Mips::CapJumpLinkPseudo) // Op2 here is implicitly c17:
          assert(OutputOp.isReg() && OutputOp.getReg() == Mips::C17);
        auto DelaySlotInstr = MI.getNextNode();
        if (DelaySlotInstr->readsRegister(Mips::C17)) {
          ErrInfo = "Filled CapJumpLinkPseudo delay slot with a read of $c17 "
                    "(which will have been clobbered!)";
          return false;
        }
      }
      return true;
    // FIXME: duplicating all this here is silly, tablegen should
    //   be able to generate those checks!
    case Mips::CAPLOADU8:
    case Mips::CAPLOADU832:
    case Mips::CAPLOAD8:
    case Mips::CAPLOAD832:
    case Mips::CAPSTORE8:
    case Mips::CAPSTORE832:
      return checkScaledImmediate<8, 0>(MI, ErrInfo, 2);
    case Mips::CAPLOADU16:
    case Mips::CAPLOADU1632:
    case Mips::CAPLOAD16:
    case Mips::CAPLOAD1632:
    case Mips::CAPSTORE16:
    case Mips::CAPSTORE1632:
      return checkScaledImmediate<8, 1>(MI, ErrInfo, 2);
    case Mips::CAPLOADU32:
    case Mips::CAPLOAD3264:
    case Mips::CAPSTORE32:
    case Mips::CAPSTORE3264:
      return checkScaledImmediate<8, 2>(MI, ErrInfo, 2);
    case Mips::CAPLOAD64:
    case Mips::CAPSTORE64:
      return checkScaledImmediate<8, 3>(MI, ErrInfo, 2);
    case Mips::STORECAP:
    case Mips::LOADCAP:
      return checkScaledImmediate<11, 4>(MI, ErrInfo, 2);
    case Mips::LOADCAP_BigImm:
      return checkScaledImmediate<16, 4>(MI, ErrInfo, 1);
    case Mips::CIncOffsetImm:
      return checkScaledImmediate<11, 0>(MI, ErrInfo, 2);
    case Mips::CSetBoundsImm:
      // FIXME: actually 11 bit unsigned
      return checkScaledImmediate<12, 0>(MI, ErrInfo, 2);
    default:
      return true;
  }

  return true;
}

std::pair<unsigned, unsigned>
MipsInstrInfo::decomposeMachineOperandsTargetFlags(unsigned TF) const {
  return std::make_pair(TF, 0u);
}

ArrayRef<std::pair<unsigned, const char*>>
MipsInstrInfo::getSerializableDirectMachineOperandTargetFlags() const {
 using namespace MipsII;

 static const std::pair<unsigned, const char*> Flags[] = {
    {MO_GOT,          "mips-got"},
    {MO_GOT_CALL,     "mips-got-call"},
    {MO_GPREL,        "mips-gprel"},
    {MO_ABS_HI,       "mips-abs-hi"},
    {MO_ABS_LO,       "mips-abs-lo"},
    {MO_TLSGD,        "mips-tlsgd"},
    {MO_TLSLDM,       "mips-tlsldm"},
    {MO_DTPREL_HI,    "mips-dtprel-hi"},
    {MO_DTPREL_LO,    "mips-dtprel-lo"},
    {MO_GOTTPREL,     "mips-gottprel"},
    {MO_TPREL_HI,     "mips-tprel-hi"},
    {MO_TPREL_LO,     "mips-tprel-lo"},
    {MO_GPOFF_HI,     "mips-gpoff-hi"},
    {MO_GPOFF_LO,     "mips-gpoff-lo"},
    {MO_GOT_DISP,     "mips-got-disp"},
    {MO_GOT_PAGE,     "mips-got-page"},
    {MO_GOT_OFST,     "mips-got-ofst"},
    {MO_HIGHER,       "mips-higher"},
    {MO_HIGHEST,      "mips-highest"},
    {MO_GOT_HI16,     "mips-got-hi16"},
    {MO_GOT_LO16,     "mips-got-lo16"},
    {MO_CALL_HI16,    "mips-call-hi16"},
    {MO_CALL_LO16,    "mips-call-lo16"},
    {MO_JALR,         "mips-jalr"},

    { MO_PCREL_LO,  "mips-pcrel-lo16" },
    { MO_PCREL_HI,  "mips-pcrel-hi16" },

    { MO_CAPTAB11,         "mips-captable11" },
    { MO_CAPTAB_CALL11,    "mips-captable11-call" },
    { MO_CAPTAB20,         "mips-captable20" },
    { MO_CAPTAB_CALL20,    "mips-captable20-call" },
    { MO_CAPTAB_LO16,      "mips-captable-lo16" },
    { MO_CAPTAB_HI16,      "mips-captable-hi16" },
    { MO_CAPTAB_CALL_LO16, "mips-captable-lo16-call" },
    { MO_CAPTAB_CALL_HI16, "mips-captable-hi16-call" },

    { MO_CAPTABLE_OFF_HI, "mips-captable-off-hi" },
    { MO_CAPTABLE_OFF_LO, "mips-captable-off-lo" },

    { MO_CAPTAB_TLSGD_HI16,  "mips-captable-tlsgd-hi16" },
    { MO_CAPTAB_TLSGD_LO16,  "mips-captable-tlsgd-lo16" },
    { MO_CAPTAB_TLSLDM_HI16, "mips-captable-tlsldm-hi16" },
    { MO_CAPTAB_TLSLDM_LO16, "mips-captable-tlsldm-lo16" },
    { MO_CAPTAB_TPREL_HI16,  "mips-captable-gottprel-hi16" },
    { MO_CAPTAB_TPREL_LO16,  "mips-captable-gottprel-lo16" },
  };
  return makeArrayRef(Flags);
}

Optional<ParamLoadedValue>
MipsInstrInfo::describeLoadedValue(const MachineInstr &MI, Register Reg) const {
  DIExpression *Expr =
      DIExpression::get(MI.getMF()->getFunction().getContext(), {});

  // TODO: Special MIPS instructions that need to be described separately.
  if (auto RegImm = isAddImmediate(MI, Reg)) {
    Register SrcReg = RegImm->Reg;
    int64_t Offset = RegImm->Imm;
    // When SrcReg is $zero, treat loaded value as immediate only.
    // Ex. $a2 = ADDiu $zero, 10
    if (SrcReg == Mips::ZERO || SrcReg == Mips::ZERO_64) {
      return ParamLoadedValue(MI.getOperand(2), Expr);
    }
    Expr = DIExpression::prepend(Expr, DIExpression::ApplyOffset, Offset);
    return ParamLoadedValue(MachineOperand::CreateReg(SrcReg, false), Expr);
  } else if (auto DestSrc = isCopyInstr(MI)) {
    const MachineFunction *MF = MI.getMF();
    const TargetRegisterInfo *TRI = MF->getSubtarget().getRegisterInfo();
    Register DestReg = DestSrc->Destination->getReg();
    // TODO: Handle cases where the Reg is sub- or super-register of the
    // DestReg.
    if (TRI->isSuperRegister(Reg, DestReg) || TRI->isSubRegister(Reg, DestReg))
      return None;
  }

  return TargetInstrInfo::describeLoadedValue(MI, Reg);
}

Optional<int64_t>
MipsInstrInfo::getAsIntImmediate(const MachineOperand &Op,
                                 const MachineRegisterInfo &MRI) const {
  if (Op.isImm())
    return Op.getImm();
  if (Op.isReg()) {
    Register Reg = Op.getReg();
    if (Reg == Mips::ZERO || Reg == Mips::ZERO_64)
      return 0;
    if (Reg.isVirtual()) {
      auto *Def = MRI.getUniqueVRegDef(Reg);
      switch (Def->getOpcode()) {
      default:
        return None; // Unknown immediate
      case Mips::ADDiu:
      case Mips::DADDiu:
      case Mips::ORi:
      case Mips::ORi64: {
        Register BaseReg = Def->getOperand(1).getReg();
        if (BaseReg == Mips::ZERO || BaseReg == Mips::ZERO_64)
          return Def->getOperand(2).getImm();
        return None;
      }
      }
    }
  }
  return None; // Unknown immediate
}

bool MipsInstrInfo::isSetBoundsInstr(const MachineInstr &I,
                                     const MachineOperand *&Base,
                                     const MachineOperand *&Size) const {
  switch (I.getOpcode()) {
  default:
    return false;
  case Mips::CSetBounds:
  case Mips::CSetBoundsExact:
  case Mips::CSetBoundsImm:
    Base = &I.getOperand(1);
    Size = &I.getOperand(2);
    return true;
  }
}

bool MipsInstrInfo::isPtrAddInstr(const MachineInstr &I,
                                  const MachineOperand *&Base,
                                  const MachineOperand *&Increment) const {
  switch (I.getOpcode()) {
  default:
    return false;
  case Mips::CIncOffsetImm:
  case Mips::CIncOffset:
    Base = &I.getOperand(1);
    Increment = &I.getOperand(2);
    return true;
  }
}

Optional<RegImmPair> MipsInstrInfo::isAddImmediate(const MachineInstr &MI,
                                                   Register Reg) const {
  // TODO: Handle cases where Reg is a super- or sub-register of the
  // destination register.
  const MachineOperand &Op0 = MI.getOperand(0);
  if (!Op0.isReg() || Reg != Op0.getReg())
    return None;

  switch (MI.getOpcode()) {
  case Mips::ADDiu:
  case Mips::DADDiu: {
    const MachineOperand &Dop = MI.getOperand(0);
    const MachineOperand &Sop1 = MI.getOperand(1);
    const MachineOperand &Sop2 = MI.getOperand(2);
    // Value is sum of register and immediate. Immediate value could be
    // global string address which is not supported.
    if (Dop.isReg() && Sop1.isReg() && Sop2.isImm())
      return RegImmPair{Sop1.getReg(), Sop2.getImm()};
    // TODO: Handle case where Sop1 is a frame-index.
  }
  }
  return None;
}
