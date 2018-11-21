//===--- MacroUsageCheck.cpp - clang-tidy----------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MacroUsageCheck.h"
#include "clang/Frontend/CompilerInstance.h"
#include "clang/Lex/PPCallbacks.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/Regex.h"
#include <algorithm>
#include <cctype>

namespace clang {
namespace tidy {
namespace cppcoreguidelines {

namespace {

bool isCapsOnly(StringRef Name) {
  return std::all_of(Name.begin(), Name.end(), [](const char c) {
    if (std::isupper(c) || std::isdigit(c) || c == '_')
      return true;
    return false;
  });
}

class MacroUsageCallbacks : public PPCallbacks {
public:
  MacroUsageCallbacks(MacroUsageCheck *Check, const SourceManager &SM,
                      StringRef RegExp, bool CapsOnly, bool IgnoreCommandLine)
      : Check(Check), SM(SM), RegExp(RegExp), CheckCapsOnly(CapsOnly),
        IgnoreCommandLineMacros(IgnoreCommandLine) {}
  void MacroDefined(const Token &MacroNameTok,
                    const MacroDirective *MD) override {
    if (MD->getMacroInfo()->isUsedForHeaderGuard() ||
        MD->getMacroInfo()->getNumTokens() == 0)
      return;

    if (IgnoreCommandLineMacros &&
        SM.isWrittenInCommandLineFile(MD->getLocation()))
      return;

    StringRef MacroName = MacroNameTok.getIdentifierInfo()->getName();
    if (!CheckCapsOnly && !llvm::Regex(RegExp).match(MacroName))
      Check->warnMacro(MD, MacroName);

    if (CheckCapsOnly && !isCapsOnly(MacroName))
      Check->warnNaming(MD, MacroName);
  }

private:
  MacroUsageCheck *Check;
  const SourceManager &SM;
  StringRef RegExp;
  bool CheckCapsOnly;
  bool IgnoreCommandLineMacros;
};
} // namespace

void MacroUsageCheck::storeOptions(ClangTidyOptions::OptionMap &Opts) {
  Options.store(Opts, "AllowedRegexp", AllowedRegexp);
  Options.store(Opts, "CheckCapsOnly", CheckCapsOnly);
  Options.store(Opts, "IgnoreCommandLineMacros", IgnoreCommandLineMacros);
}

void MacroUsageCheck::registerPPCallbacks(CompilerInstance &Compiler) {
  if (!getLangOpts().CPlusPlus11)
    return;

  Compiler.getPreprocessor().addPPCallbacks(
      llvm::make_unique<MacroUsageCallbacks>(this, Compiler.getSourceManager(),
                                             AllowedRegexp, CheckCapsOnly,
                                             IgnoreCommandLineMacros));
}

void MacroUsageCheck::warnMacro(const MacroDirective *MD, StringRef MacroName) {
  StringRef Message =
      "macro '%0' used to declare a constant; consider using a 'constexpr' "
      "constant";

  /// A variadic macro is function-like at the same time. Therefore variadic
  /// macros are checked first and will be excluded for the function-like
  /// diagnostic.
  if (MD->getMacroInfo()->isVariadic())
    Message = "variadic macro '%0' used; consider using a 'constexpr' "
              "variadic template function";
  else if (MD->getMacroInfo()->isFunctionLike())
    Message = "function-like macro '%0' used; consider a 'constexpr' template "
              "function";

  diag(MD->getLocation(), Message) << MacroName;
}

void MacroUsageCheck::warnNaming(const MacroDirective *MD,
                                 StringRef MacroName) {
  diag(MD->getLocation(), "macro definition does not define the macro name "
                          "'%0' using all uppercase characters")
      << MacroName;
}

} // namespace cppcoreguidelines
} // namespace tidy
} // namespace clang
