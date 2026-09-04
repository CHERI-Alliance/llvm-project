//===-- RISCVBaseInfo.cpp - Top level definitions for RISC-V MC -----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone enum definitions for the RISC-V target
// useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//

#include "RISCVBaseInfo.h"
#include "RISCVMCTargetDesc.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/TargetParser/TargetParser.h"
#include "llvm/TargetParser/Triple.h"

namespace llvm {

extern const SubtargetFeatureKV RISCVFeatureKV[RISCV::NumSubtargetFeatures];

namespace RISCVSysReg {
#define GET_SysRegsList_IMPL
#include "RISCVGenSearchableTables.inc"
} // namespace RISCVSysReg

namespace RISCVSpecialCapReg {
#define GET_SpecialCapRegsList_IMPL
#include "RISCVGenSearchableTables.inc"
} // namespace RISCVSpecialCapReg

namespace RISCVCheriSysReg {
#define GET_CheriSysRegsList_IMPL
#include "RISCVGenSearchableTables.inc"
} // namespace RISCVCheriSysReg

namespace RISCVInsnOpcode {
#define GET_RISCVOpcodesList_IMPL
#include "RISCVGenSearchableTables.inc"
} // namespace RISCVInsnOpcode

namespace RISCVABI {
ABI computeTargetABI(const Triple &TT, const FeatureBitset &FeatureBits,
                     StringRef ABIName) {
  auto TargetABI = getTargetABI(ABIName);
  bool IsRV64 = TT.isArch64Bit();
  bool IsRVE = FeatureBits[RISCV::FeatureStdExtE];

  if (!ABIName.empty() && TargetABI == ABI_Unknown) {
    errs()
        << "'" << ABIName
        << "' is not a recognized ABI for this target (ignoring target-abi)\n";
  } else if ((ABIName.starts_with("ilp32") || ABIName.starts_with("il32")) &&
             IsRV64) {
    errs() << "32-bit ABIs are not supported for 64-bit targets (ignoring "
              "target-abi)\n";
    TargetABI = ABI_Unknown;
  } else if ((ABIName.starts_with("lp64") || ABIName.starts_with("l64")) &&
             !IsRV64) {
    errs() << "64-bit ABIs are not supported for 32-bit targets (ignoring "
              "target-abi)\n";
    TargetABI = ABI_Unknown;
  } else if ((ABIName.starts_with("il32pc") || ABIName.starts_with("l64pc")) &&
             !(FeatureBits[RISCV::FeatureStdExtXCheri] || FeatureBits[RISCV::FeatureStdExtZCheriPureCap])) {
    errs() << "Pure-capability ABI can't be used for a target that "
              "doesn't support the XCheri instruction set extension (ignoring "
              "target-abi)\n";
    TargetABI = ABI_Unknown;
  } else if (!IsRV64 && IsRVE && TargetABI != ABI_ILP32E &&
             TargetABI != ABI_IL32PC64E && TargetABI != ABI_Unknown) {
    // TODO: move this checking to RISCVTargetLowering and RISCVAsmParser
    errs() << "Only the ilp32e and il32pc64e ABIs are supported for RV32E "
              "(ignoring target-abi)\n";
    TargetABI = ABI_Unknown;
  } else if (IsRV64 && IsRVE && TargetABI != ABI_LP64E &&
             TargetABI != ABI_Unknown) {
    // TODO: move this checking to RISCVTargetLowering and RISCVAsmParser
    errs()
        << "Only the lp64e ABI is supported for RV64E (ignoring target-abi)\n";
    TargetABI = ABI_Unknown;
  }

  if ((TargetABI == RISCVABI::ABI::ABI_ILP32E ||
       (TargetABI == ABI_Unknown && IsRVE && !IsRV64)) &&
      FeatureBits[RISCV::FeatureStdExtD])
    report_fatal_error("ILP32E cannot be used with the D ISA extension");

  if (TargetABI != ABI_Unknown)
    return TargetABI;

  // If no explicit ABI is given, try to compute the default ABI.
  auto ISAInfo = RISCVFeatures::parseFeatureBits(IsRV64, FeatureBits);
  if (!ISAInfo)
    report_fatal_error(ISAInfo.takeError());
  return getTargetABI((*ISAInfo)->computeDefaultABI());
}

ABI getTargetABI(StringRef ABIName) {
  auto TargetABI = StringSwitch<ABI>(ABIName)
                       .Case("ilp32", ABI_ILP32)
                       .Case("ilp32f", ABI_ILP32F)
                       .Case("ilp32d", ABI_ILP32D)
                       .Case("ilp32e", ABI_ILP32E)
                       .Case("il32pc64", ABI_IL32PC64)
                       .Case("il32pc64f", ABI_IL32PC64F)
                       .Case("il32pc64d", ABI_IL32PC64D)
                       .Case("il32pc64e", ABI_IL32PC64E)
                       .Case("lp64", ABI_LP64)
                       .Case("lp64f", ABI_LP64F)
                       .Case("lp64d", ABI_LP64D)
                       .Case("lp64e", ABI_LP64E)
                       .Case("l64pc128", ABI_L64PC128)
                       .Case("l64pc128f", ABI_L64PC128F)
                       .Case("l64pc128d", ABI_L64PC128D)
                       .Default(ABI_Unknown);
  return TargetABI;
}

// To avoid the BP value clobbered by a function call, we need to choose a
// callee saved register to save the value. RV32E only has X8 and X9 as callee
// saved registers and X8 will be used as fp. So we choose X9 as bp.
MCRegister getBPReg(ABI TargetABI) {
  return isCheriPureCapABI(TargetABI) ? RISCV::X9_Y : RISCV::X9;
}

// Returns the register holding shadow call stack pointer.
MCRegister getSCSPReg(ABI TargetABI) {
  return isCheriPureCapABI(TargetABI) ? RISCV::X3_Y : RISCV::X3;
}

// Returns the register used for bounded mem/var args
MCRegister getCheriBoundedArgReg() { return RISCV::X31_Y; }

} // namespace RISCVABI

namespace RISCVV9CRName {

MCRegister lookup(StringRef Name) {
  return StringSwitch<MCRegister>(Name)
      .Cases("c0", "cnull", RISCV::X0_Y)
      .Cases("c1", "cra", RISCV::X1_Y)
      .Cases("c2", "csp", RISCV::X2_Y)
      .Cases("c3", "cgp", RISCV::X3_Y)
      .Cases("c4", "ctp", RISCV::X4_Y)
      .Cases("c5", "ct0", RISCV::X5_Y)
      .Cases("c6", "ct1", RISCV::X6_Y)
      .Cases("c7", "ct2", RISCV::X7_Y)
      .Cases("c8", "cs0", "cfp", RISCV::X8_Y)
      .Cases("c9", "cs1", RISCV::X9_Y)
      .Cases("c10", "ca0", RISCV::X10_Y)
      .Cases("c11", "ca1", RISCV::X11_Y)
      .Cases("c12", "ca2", RISCV::X12_Y)
      .Cases("c13", "ca3", RISCV::X13_Y)
      .Cases("c14", "ca4", RISCV::X14_Y)
      .Cases("c15", "ca5", RISCV::X15_Y)
      .Cases("c16", "ca6", RISCV::X16_Y)
      .Cases("c17", "ca7", RISCV::X17_Y)
      .Cases("c18", "cs2", RISCV::X18_Y)
      .Cases("c19", "cs3", RISCV::X19_Y)
      .Cases("c20", "cs4", RISCV::X20_Y)
      .Cases("c21", "cs5", RISCV::X21_Y)
      .Cases("c22", "cs6", RISCV::X22_Y)
      .Cases("c23", "cs7", RISCV::X23_Y)
      .Cases("c24", "cs8", RISCV::X24_Y)
      .Cases("c25", "cs9", RISCV::X25_Y)
      .Cases("c26", "cs10", RISCV::X26_Y)
      .Cases("c27", "cs11", RISCV::X27_Y)
      .Cases("c28", "ct3", RISCV::X28_Y)
      .Cases("c29", "ct4", RISCV::X29_Y)
      .Cases("c30", "ct5", RISCV::X30_Y)
      .Cases("c31", "ct6", RISCV::X31_Y)
      .Default(MCRegister());
}

const char *get(MCRegister Reg, bool ABI) {
  switch (Reg.id()) {
  default:
    return nullptr;
  case RISCV::X0_Y:
    return ABI ? "cnull" : "c0";
  case RISCV::X1_Y:
    return ABI ? "cra" : "c1";
  case RISCV::X2_Y:
    return ABI ? "csp" : "c2";
  case RISCV::X3_Y:
    return ABI ? "cgp" : "c3";
  case RISCV::X4_Y:
    return ABI ? "ctp" : "c4";
  case RISCV::X5_Y:
    return ABI ? "ct0" : "c5";
  case RISCV::X6_Y:
    return ABI ? "ct1" : "c6";
  case RISCV::X7_Y:
    return ABI ? "ct2" : "c7";
  case RISCV::X8_Y:
    return ABI ? "cs0" : "c8";
  case RISCV::X9_Y:
    return ABI ? "cs1" : "c9";
  case RISCV::X10_Y:
    return ABI ? "ca0" : "c10";
  case RISCV::X11_Y:
    return ABI ? "ca1" : "c11";
  case RISCV::X12_Y:
    return ABI ? "ca2" : "c12";
  case RISCV::X13_Y:
    return ABI ? "ca3" : "c13";
  case RISCV::X14_Y:
    return ABI ? "ca4" : "c14";
  case RISCV::X15_Y:
    return ABI ? "ca5" : "c15";
  case RISCV::X16_Y:
    return ABI ? "ca6" : "c16";
  case RISCV::X17_Y:
    return ABI ? "ca7" : "c17";
  case RISCV::X18_Y:
    return ABI ? "cs2" : "c18";
  case RISCV::X19_Y:
    return ABI ? "cs3" : "c19";
  case RISCV::X20_Y:
    return ABI ? "cs4" : "c20";
  case RISCV::X21_Y:
    return ABI ? "cs5" : "c21";
  case RISCV::X22_Y:
    return ABI ? "cs6" : "c22";
  case RISCV::X23_Y:
    return ABI ? "cs7" : "c23";
  case RISCV::X24_Y:
    return ABI ? "cs8" : "c24";
  case RISCV::X25_Y:
    return ABI ? "cs9" : "c25";
  case RISCV::X26_Y:
    return ABI ? "cs10" : "c26";
  case RISCV::X27_Y:
    return ABI ? "cs11" : "c27";
  case RISCV::X28_Y:
    return ABI ? "ct3" : "c28";
  case RISCV::X29_Y:
    return ABI ? "ct4" : "c29";
  case RISCV::X30_Y:
    return ABI ? "ct5" : "c30";
  case RISCV::X31_Y:
    return ABI ? "ct6" : "c31";
  // DDC is a member of ISAv9OnlyYGPRX0IsDDC alongside X1_Y..X31_Y and has no
  // separate architectural/ABI spelling.
  case RISCV::DDC:
    return "ddc";
  }
}

} // namespace RISCVV9CRName

namespace RISCVFeatures {

void validate(const Triple &TT, const FeatureBitset &FeatureBits) {
  if (TT.isArch64Bit() && !FeatureBits[RISCV::Feature64Bit])
    report_fatal_error("RV64 target requires an RV64 CPU");
  if (!TT.isArch64Bit() && !FeatureBits[RISCV::Feature32Bit])
    report_fatal_error("RV32 target requires an RV32 CPU");
  if (FeatureBits[RISCV::Feature32Bit] &&
      FeatureBits[RISCV::Feature64Bit])
    report_fatal_error("RV32 and RV64 can't be combined");
  // TODO: Support capability variant of R_RISCV_ADD
  if (FeatureBits[RISCV::FeatureStdExtXCheri] && FeatureBits[RISCV::FeatureRelax])
    report_fatal_error("CHERI does not currently support linker relaxation");
}

llvm::Expected<std::unique_ptr<RISCVISAInfo>>
parseFeatureBits(bool IsRV64, const FeatureBitset &FeatureBits) {
  unsigned XLen = IsRV64 ? 64 : 32;
  std::vector<std::string> FeatureVector;
  // Convert FeatureBitset to FeatureVector.
  for (auto Feature : RISCVFeatureKV) {
    if (FeatureBits[Feature.Value] &&
        llvm::RISCVISAInfo::isSupportedExtensionFeature(Feature.Key))
      FeatureVector.push_back(std::string("+") + Feature.Key);
  }
  return llvm::RISCVISAInfo::parseFeatures(XLen, FeatureVector);
}

} // namespace RISCVFeatures

// Include the auto-generated portion of the compress emitter.
#define GEN_UNCOMPRESS_INSTR
#define GEN_COMPRESS_INSTR
#include "RISCVGenCompressInstEmitter.inc"

bool RISCVRVC::compress(MCInst &OutInst, const MCInst &MI,
                        const MCSubtargetInfo &STI) {
  return compressInst(OutInst, MI, STI);
}

bool RISCVRVC::uncompress(MCInst &OutInst, const MCInst &MI,
                          const MCSubtargetInfo &STI) {
  return uncompressInst(OutInst, MI, STI);
}

// Lookup table for fli.s for entries 2-31.
static constexpr std::pair<uint8_t, uint8_t> LoadFP32ImmArr[] = {
    {0b01101111, 0b00}, {0b01110000, 0b00}, {0b01110111, 0b00},
    {0b01111000, 0b00}, {0b01111011, 0b00}, {0b01111100, 0b00},
    {0b01111101, 0b00}, {0b01111101, 0b01}, {0b01111101, 0b10},
    {0b01111101, 0b11}, {0b01111110, 0b00}, {0b01111110, 0b01},
    {0b01111110, 0b10}, {0b01111110, 0b11}, {0b01111111, 0b00},
    {0b01111111, 0b01}, {0b01111111, 0b10}, {0b01111111, 0b11},
    {0b10000000, 0b00}, {0b10000000, 0b01}, {0b10000000, 0b10},
    {0b10000001, 0b00}, {0b10000010, 0b00}, {0b10000011, 0b00},
    {0b10000110, 0b00}, {0b10000111, 0b00}, {0b10001110, 0b00},
    {0b10001111, 0b00}, {0b11111111, 0b00}, {0b11111111, 0b10},
};

int RISCVLoadFPImm::getLoadFPImm(APFloat FPImm) {
  assert((&FPImm.getSemantics() == &APFloat::IEEEsingle() ||
          &FPImm.getSemantics() == &APFloat::IEEEdouble() ||
          &FPImm.getSemantics() == &APFloat::IEEEhalf()) &&
         "Unexpected semantics");

  // Handle the minimum normalized value which is different for each type.
  if (FPImm.isSmallestNormalized() && !FPImm.isNegative())
    return 1;

  // Convert to single precision to use its lookup table.
  bool LosesInfo;
  APFloat::opStatus Status = FPImm.convert(
      APFloat::IEEEsingle(), APFloat::rmNearestTiesToEven, &LosesInfo);
  if (Status != APFloat::opOK || LosesInfo)
    return -1;

  APInt Imm = FPImm.bitcastToAPInt();

  if (Imm.extractBitsAsZExtValue(21, 0) != 0)
    return -1;

  bool Sign = Imm.extractBitsAsZExtValue(1, 31);
  uint8_t Mantissa = Imm.extractBitsAsZExtValue(2, 21);
  uint8_t Exp = Imm.extractBitsAsZExtValue(8, 23);

  auto EMI = llvm::lower_bound(LoadFP32ImmArr, std::make_pair(Exp, Mantissa));
  if (EMI == std::end(LoadFP32ImmArr) || EMI->first != Exp ||
      EMI->second != Mantissa)
    return -1;

  // Table doesn't have entry 0 or 1.
  int Entry = std::distance(std::begin(LoadFP32ImmArr), EMI) + 2;

  // The only legal negative value is -1.0(entry 0). 1.0 is entry 16.
  if (Sign) {
    if (Entry == 16)
      return 0;
    return -1;
  }

  return Entry;
}

float RISCVLoadFPImm::getFPImm(unsigned Imm) {
  assert(Imm != 1 && Imm != 30 && Imm != 31 && "Unsupported immediate");

  // Entry 0 is -1.0, the only negative value. Entry 16 is 1.0.
  uint32_t Sign = 0;
  if (Imm == 0) {
    Sign = 0b1;
    Imm = 16;
  }

  uint32_t Exp = LoadFP32ImmArr[Imm - 2].first;
  uint32_t Mantissa = LoadFP32ImmArr[Imm - 2].second;

  uint32_t I = Sign << 31 | Exp << 23 | Mantissa << 21;
  return bit_cast<float>(I);
}

void RISCVZC::printRlist(unsigned SlistEncode, raw_ostream &OS) {
  OS << "{ra";
  if (SlistEncode > 4) {
    OS << ", s0";
    if (SlistEncode == 15)
      OS << "-s11";
    else if (SlistEncode > 5 && SlistEncode <= 14)
      OS << "-s" << (SlistEncode - 5);
  }
  OS << "}";
}

} // namespace llvm
