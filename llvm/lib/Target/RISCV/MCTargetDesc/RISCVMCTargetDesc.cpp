//===-- RISCVMCTargetDesc.cpp - RISCV Target Descriptions -----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// This file provides RISCV-specific target descriptions.
///
//===----------------------------------------------------------------------===//

#include "RISCVMCTargetDesc.h"
#include "RISCVELFStreamer.h"
#include "RISCVInstPrinter.h"
#include "RISCVMCAsmInfo.h"
#include "RISCVTargetStreamer.h"
#include "TargetInfo/RISCVTargetInfo.h"
#include "Utils/RISCVBaseInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/Register.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "RISCVGenInstrInfo.inc"

#define GET_REGINFO_MC_DESC
#include "RISCVGenRegisterInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "RISCVGenSubtargetInfo.inc"

using namespace llvm;

static MCInstrInfo *createRISCVMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitRISCVMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createRISCVMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitRISCVMCRegisterInfo(X, RISCV::X1);
  return X;
}

static MCAsmInfo *createRISCVMCAsmInfo(const MCRegisterInfo &MRI,
                                       const Triple &TT,
                                       const MCTargetOptions &Options) {
  RISCVABI::ABI ABI = RISCVABI::getTargetABI(Options.getABIName());
  MCAsmInfo *MAI = new RISCVMCAsmInfo(TT, ABI);

  Register SPReg;
  if (ABI != RISCVABI::ABI_Unknown && RISCVABI::isCheriPureCapABI(ABI))
    SPReg = RISCV::C2;
  else
    SPReg = RISCV::X2;

  unsigned SP = MRI.getDwarfRegNum(SPReg, true);
  MCCFIInstruction Inst = MCCFIInstruction::createDefCfa(nullptr, SP, 0);
  MAI->addInitialFrameState(Inst);

  return MAI;
}

static MCSubtargetInfo *createRISCVMCSubtargetInfo(const Triple &TT,
                                                   StringRef CPU, StringRef FS) {
  std::string CPUName = std::string(CPU);
  if (CPUName.empty())
    CPUName = TT.isArch64Bit() ? "generic-rv64" : "generic-rv32";
  return createRISCVMCSubtargetInfoImpl(TT, CPUName, FS);
}

static MCInstPrinter *createRISCVMCInstPrinter(const Triple &T,
                                               unsigned SyntaxVariant,
                                               const MCAsmInfo &MAI,
                                               const MCInstrInfo &MII,
                                               const MCRegisterInfo &MRI) {
  return new RISCVInstPrinter(MAI, MII, MRI);
}

static MCTargetStreamer *
createRISCVObjectTargetStreamer(MCStreamer &S, const MCSubtargetInfo &STI) {
  const Triple &TT = STI.getTargetTriple();
  if (TT.isOSBinFormatELF())
    return new RISCVTargetELFStreamer(S, STI);
  return nullptr;
}

static MCStreamer *
createRISCVMCStreamer(const Triple &TT, MCContext &Context,
                      std::unique_ptr<MCAsmBackend> &&MAB,
                      std::unique_ptr<MCObjectWriter> &&OW,
                      std::unique_ptr<MCCodeEmitter> &&Emitter,
                      bool RelaxAll) {
  if (!TT.isOSBinFormatELF())
    return nullptr;

  RISCVELFStreamer *S =
      new RISCVELFStreamer(Context, std::move(MAB), std::move(OW),
                           std::move(Emitter), TT.isArch64Bit());
  if (RelaxAll)
    S->getAssembler().setRelaxAll(true);
  return S;
}

static MCTargetStreamer *createRISCVAsmTargetStreamer(MCStreamer &S,
                                                      formatted_raw_ostream &OS,
                                                      MCInstPrinter *InstPrint,
                                                      bool isVerboseAsm) {
  return new RISCVTargetAsmStreamer(S, OS);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeRISCVTargetMC() {
  for (Target *T : {&getTheRISCV32Target(), &getTheRISCV64Target()}) {
    TargetRegistry::RegisterMCAsmInfo(*T, createRISCVMCAsmInfo);
    TargetRegistry::RegisterMCInstrInfo(*T, createRISCVMCInstrInfo);
    TargetRegistry::RegisterMCRegInfo(*T, createRISCVMCRegisterInfo);
    TargetRegistry::RegisterMCAsmBackend(*T, createRISCVAsmBackend);
    TargetRegistry::RegisterMCCodeEmitter(*T, createRISCVMCCodeEmitter);
    TargetRegistry::RegisterMCInstPrinter(*T, createRISCVMCInstPrinter);
    TargetRegistry::RegisterMCSubtargetInfo(*T, createRISCVMCSubtargetInfo);
    TargetRegistry::RegisterELFStreamer(*T, createRISCVMCStreamer);
    TargetRegistry::RegisterObjectTargetStreamer(
        *T, createRISCVObjectTargetStreamer);

    // Register the asm target streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createRISCVAsmTargetStreamer);
  }
}
