//===--- Mips.cpp - Implement Mips target feature support -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements Mips TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "Mips.h"
#include "Targets.h"
#include "clang/Basic/Diagnostic.h"
#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCTargetOptions.h"

using namespace clang;
using namespace clang::targets;


const Builtin::Info MipsTargetInfo::BuiltinInfo[] = {
#define BUILTIN(ID, TYPE, ATTRS)                                               \
  {#ID, TYPE, ATTRS, nullptr, ALL_LANGUAGES, nullptr},
#define LIBBUILTIN(ID, TYPE, ATTRS, HEADER)                                    \
  {#ID, TYPE, ATTRS, HEADER, ALL_LANGUAGES, nullptr},
#include "clang/Basic/BuiltinsMips.def"
};

bool MipsTargetInfo::processorSupportsGPR64() const {
  return llvm::StringSwitch<bool>(CPU)
      .Case("cheri128", true)
      .Case("cheri256", true)
      .Case("mips3", true)
      .Case("mips4", true)
      .Case("mips5", true)
      .Case("mips64", true)
      .Case("mips64r2", true)
      .Case("mips64r3", true)
      .Case("mips64r5", true)
      .Case("mips64r6", true)
      .Case("octeon", true)
      .Default(false);
  return false;
}

static constexpr llvm::StringLiteral ValidCPUNames[] = {
    {"cheri128"}, {"cheri256"}, {"cheri64"},
    {"mips1"},  {"mips2"},    {"mips3"},    {"mips4"},    {"mips5"},
    {"mips32"}, {"mips32r2"}, {"mips32r3"}, {"mips32r5"}, {"mips32r6"},
    {"mips64"}, {"mips64r2"}, {"mips64r3"}, {"mips64r5"}, {"mips64r6"},
    {"octeon"}, {"p5600"}};

bool MipsTargetInfo::isValidCPUName(StringRef Name) const {
  return llvm::find(ValidCPUNames, Name) != std::end(ValidCPUNames);
}

void MipsTargetInfo::fillValidCPUList(
    SmallVectorImpl<StringRef> &Values) const {
  Values.append(std::begin(ValidCPUNames), std::end(ValidCPUNames));
}

void MipsTargetInfo::getTargetDefines(const LangOptions &Opts,
                                      MacroBuilder &Builder) const {
  if (BigEndian) {
    DefineStd(Builder, "MIPSEB", Opts);
    Builder.defineMacro("_MIPSEB");
  } else {
    DefineStd(Builder, "MIPSEL", Opts);
    Builder.defineMacro("_MIPSEL");
  }

  Builder.defineMacro("__mips__");
  Builder.defineMacro("_mips");
  if (Opts.GNUMode)
    Builder.defineMacro("mips");

  if (ABI == "o32") {
    Builder.defineMacro("__mips", "32");
    Builder.defineMacro("_MIPS_ISA", "_MIPS_ISA_MIPS32");
  } else {
    Builder.defineMacro("__mips", "64");
    Builder.defineMacro("__mips64");
    Builder.defineMacro("__mips64__");
    Builder.defineMacro("_MIPS_ISA", "_MIPS_ISA_MIPS64");
  }

  const std::string ISARev = llvm::StringSwitch<std::string>(getCPU())
                                 .Cases("mips32", "mips64", "1")
                                 .Cases("mips32r2", "mips64r2", "2")
                                 .Cases("mips32r3", "mips64r3", "3")
                                 .Cases("mips32r5", "mips64r5", "5")
                                 .Cases("mips32r6", "mips64r6", "6")
                                 .Default("");
  if (!ISARev.empty())
    Builder.defineMacro("__mips_isa_rev", ISARev);

  if (ABI == "o32") {
    Builder.defineMacro("__mips_o32");
    Builder.defineMacro("_ABIO32", "1");
    Builder.defineMacro("_MIPS_SIM", "_ABIO32");
  } else if (ABI == "n32") {
    Builder.defineMacro("__mips_n32");
    Builder.defineMacro("_ABIN32", "2");
    Builder.defineMacro("_MIPS_SIM", "_ABIN32");
  } else if (ABI == "n64") {
    Builder.defineMacro("__mips_n64");
    Builder.defineMacro("_ABI64", "3");
    Builder.defineMacro("_MIPS_SIM", "_ABI64");
  } else
    llvm_unreachable("Invalid ABI.");

  if (!IsNoABICalls) {
    Builder.defineMacro("__mips_abicalls");
    if (CanUseBSDABICalls)
      Builder.defineMacro("__ABICALLS__");
  }

  Builder.defineMacro("__REGISTER_PREFIX__", "");

  switch (FloatABI) {
  case HardFloat:
    Builder.defineMacro("__mips_hard_float", Twine(1));
    break;
  case SoftFloat:
    Builder.defineMacro("__mips_soft_float", Twine(1));
    break;
  }

  if (IsSingleFloat)
    Builder.defineMacro("__mips_single_float", Twine(1));

  Builder.defineMacro("__mips_fpr", HasFP64 ? Twine(64) : Twine(32));
  Builder.defineMacro("_MIPS_FPSET",
                      Twine(32 / (HasFP64 || IsSingleFloat ? 1 : 2)));

  if (IsMips16)
    Builder.defineMacro("__mips16", Twine(1));

  if (IsMicromips)
    Builder.defineMacro("__mips_micromips", Twine(1));

  if (IsNan2008)
    Builder.defineMacro("__mips_nan2008", Twine(1));

  if (IsAbs2008)
    Builder.defineMacro("__mips_abs2008", Twine(1));

  switch (DspRev) {
  default:
    break;
  case DSP1:
    Builder.defineMacro("__mips_dsp_rev", Twine(1));
    Builder.defineMacro("__mips_dsp", Twine(1));
    break;
  case DSP2:
    Builder.defineMacro("__mips_dsp_rev", Twine(2));
    Builder.defineMacro("__mips_dspr2", Twine(1));
    Builder.defineMacro("__mips_dsp", Twine(1));
    break;
  }

  if (HasMSA)
    Builder.defineMacro("__mips_msa", Twine(1));

  if (IsCHERI) {
    Builder.defineMacro("__CHERI__", Twine(1));
    if (CapabilityABI) {
      Builder.defineMacro("__CHERI_SANDBOX__", Twine(4));
      Builder.defineMacro("__CHERI_PURE_CAPABILITY__", Twine(2));
      auto CapTableABI = llvm::MCTargetOptions::cheriCapabilityTableABI();
      if (CapTableABI != llvm::CheriCapabilityTableABI::Legacy) {
        Builder.defineMacro("__CHERI_CAPABILITY_TABLE__",
                            Twine(((int)CapTableABI) + 1));
      }
      auto CapTlsABI = llvm::MCTargetOptions::cheriCapabilityTlsABI();
      if (CapTlsABI != llvm::CheriCapabilityTlsABI::Legacy) {
        Builder.defineMacro("__CHERI_CAPABILITY_TLS__",
                            Twine((int)CapTlsABI));
      }
    }

    // Macros for use with the set and get permissions builtins.
    Builder.defineMacro("__CHERI_CAP_PERMISSION_GLOBAL__", Twine(1<<0));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_EXECUTE__",
            Twine(1<<1));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_LOAD__", Twine(1<<2));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_STORE__", Twine(1<<3));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_LOAD_CAPABILITY__",
            Twine(1<<4));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_STORE_CAPABILITY__",
            Twine(1<<5));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_STORE_LOCAL__",
            Twine(1<<6));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_SEAL__", Twine(1<<7));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_CCALL__", Twine(1<<8));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_PERMIT_UNSEAL__", Twine(1<<9));
    Builder.defineMacro("__CHERI_CAP_PERMISSION_ACCESS_SYSTEM_REGISTERS__", Twine(1<<10));

    Builder.defineMacro("_MIPS_SZCAP", Twine(getCHERICapabilityWidth()));
    if (getCHERICapabilityWidth() == 128)
        Builder.defineMacro("_MIPS_CAP_ALIGN_MASK", "0xfffffffffffffff0");
    else
        Builder.defineMacro("_MIPS_CAP_ALIGN_MASK", "0xffffffffffffffe0");


    Builder.defineMacro("__capability",
      Twine("__attribute__((cheri_capability))"));
  }
  if (DisableMadd4)
    Builder.defineMacro("__mips_no_madd4", Twine(1));

  Builder.defineMacro("_MIPS_SZPTR", Twine(getPointerWidth(0)));
  Builder.defineMacro("_MIPS_SZINT", Twine(getIntWidth()));
  Builder.defineMacro("_MIPS_SZLONG", Twine(getLongWidth()));

  Builder.defineMacro("_MIPS_ARCH", "\"" + CPU + "\"");
  Builder.defineMacro("_MIPS_ARCH_" + StringRef(CPU).upper());

  // These shouldn't be defined for MIPS-I but there's no need to check
  // for that since MIPS-I isn't supported.
  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_1");
  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_2");
  Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_4");

  // 32-bit MIPS processors don't have the necessary lld/scd instructions
  // found in 64-bit processors. In the case of O32 on a 64-bit processor,
  // the instructions exist but using them violates the ABI since they
  // require 64-bit GPRs and O32 only supports 32-bit GPRs.
  if (IsCHERI || ABI == "n32" || ABI == "n64")
    Builder.defineMacro("__GCC_HAVE_SYNC_COMPARE_AND_SWAP_8");


  if (getTriple().getOS() == llvm::Triple::UnknownOS &&
      getTriple().isOSBinFormatELF())
    Builder.defineMacro("__ELF__");
}

bool MipsTargetInfo::hasFeature(StringRef Feature) const {
  return llvm::StringSwitch<bool>(Feature)
      .Case("mips", true)
      .Case("fp64", HasFP64)
      .Default(false);
}

ArrayRef<Builtin::Info> MipsTargetInfo::getTargetBuiltins() const {
  return llvm::makeArrayRef(BuiltinInfo, clang::Mips::LastTSBuiltin -
                                             Builtin::FirstTSBuiltin);
}

bool MipsTargetInfo::validateTarget(DiagnosticsEngine &Diags) const {
  // microMIPS64R6 backend was removed.
  if (getTriple().isMIPS64() && IsMicromips && (ABI == "n32" || ABI == "n64")) {
    Diags.Report(diag::err_target_unsupported_cpu_for_micromips) << CPU;
    return false;
  }
  // FIXME: It's valid to use O32 on a 64-bit CPU but the backend can't handle
  //        this yet. It's better to fail here than on the backend assertion.
  if (processorSupportsGPR64() && ABI == "o32") {
    Diags.Report(diag::err_target_unsupported_abi) << ABI << CPU;
    return false;
  }

  // 64-bit ABI's require 64-bit CPU's.
  if (!processorSupportsGPR64() && (ABI == "n32" || ABI == "n64")) {
    Diags.Report(diag::err_target_unsupported_abi) << ABI << CPU;
    return false;
  }

  // FIXME: It's valid to use O32 on a mips64/mips64el triple but the backend
  //        can't handle this yet. It's better to fail here than on the
  //        backend assertion.
  if (getTriple().isMIPS64() && ABI == "o32") {
    Diags.Report(diag::err_target_unsupported_abi_for_triple)
        << ABI << getTriple().str();
    return false;
  }

  // FIXME: It's valid to use N32/N64 on a mips/mipsel triple but the backend
  //        can't handle this yet. It's better to fail here than on the
  //        backend assertion.
  if (getTriple().isMIPS32() && (ABI == "n32" || ABI == "n64")) {
    Diags.Report(diag::err_target_unsupported_abi_for_triple)
        << ABI << getTriple().str();
    return false;
  }

  return true;
}
