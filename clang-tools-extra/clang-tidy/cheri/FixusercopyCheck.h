//===--- FixusercopyCheck.h - clang-tidy ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_CHERI_FIXUSERCOPYCHECK_H
#define LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_CHERI_FIXUSERCOPYCHECK_H

#include "../ClangTidyCheck.h"

namespace clang::tidy::cheri {

/// Check invocations of the linux user copy functions for cases where
/// data with pointers is copied and suggest use fo the ..._with_ptr
/// variant.
class FixusercopyCheck : public ClangTidyCheck {
public:
  FixusercopyCheck(StringRef Name, ClangTidyContext *Context)
      : ClangTidyCheck(Name, Context) {}
  const Type *getPointeeType(ASTContext *Ctx, const Expr *E);
  bool checkPtr(ASTContext *Ctx, const Type *T);
  bool checkNonPtr(ASTContext *Ctx, const Type *T);
  bool isBufferPlusOffset(ASTContext *Ctx, const Expr *E);
  void registerMatchers(ast_matchers::MatchFinder *Finder) override;
  void check(const ast_matchers::MatchFinder::MatchResult &Result) override;
};

} // namespace clang::tidy::cheri

#endif // LLVM_CLANG_TOOLS_EXTRA_CLANG_TIDY_CHERI_FIXUSERCOPYCHECK_H
