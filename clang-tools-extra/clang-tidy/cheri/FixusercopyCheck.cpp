//===--- FixusercopyCheck.cpp - clang-tidy --------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "FixusercopyCheck.h"
#include "CheriUtil.h"
#include "clang/AST/ASTContext.h"
#include "clang/ASTMatchers/ASTMatchFinder.h"

using namespace clang::ast_matchers;

namespace clang::tidy::cheri {

void FixusercopyCheck::registerMatchers(MatchFinder *Finder) {
  // clang-format off
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("copy_from_user")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("copy_to_user")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("__copy_from_user")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("__copy_to_user")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("__copy_from_user_inatomic")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("__copy_to_user_inatomic")).bind("decl"))).bind("call"), this);
  Finder->addMatcher(callExpr(callee(functionDecl(
    hasName("__copy_from_user_inatomic_nocache")).bind("decl"))).bind("call"), this);
  // clang-format on
}

const Type *FixusercopyCheck::getPointeeType(ASTContext *Ctx, const Expr *E) {
  const Type *Ret = nullptr;

  /*
   * If (after removing casts) we end up with the address of something
   * trust the type of that something (unless it is a character array).
   */
  const auto *E2 = E;
  while (const auto *C = dyn_cast<CastExpr>(E2))
    E2 = C->getSubExpr();
  if (const auto *U = dyn_cast<UnaryOperator>(E2)) {
    if (U->getOpcode() == UO_AddrOf) {
      Ret = U->getSubExpr()->getType().getTypePtr();
      goto out;
    }
  }

  /*
   * Go through cast expressions of the pointer until we find a
   * pointer target type that looks like the real thing.
   */
  while (1) {
    Ret = E->getType().getTypePtr();
    if (!Ret)
      return nullptr;
    if (Ret->isArrayType())
      break;
    Ret = Ret->getAs<PointerType>();
    if (!Ret)
      return nullptr;
    Ret = Ret->getPointeeType().getTypePtr();
    if (!Ret)
      return nullptr;
    if (auto *R = Ret->getAs<RecordType>())
      return R;
    if (auto *R = Ret->getAs<PointerType>())
      return R;

    if (const auto *C = dyn_cast<CastExpr>(E)) {
      E = C->getSubExpr();
      continue;
    }
    if (const auto *P = dyn_cast<ParenExpr>(E)) {
      E = P->getSubExpr();
      continue;
    }

    break;
  }

out:
  /*
   * Do not report void or character as the target type.
   * These likely mean that we didn't find the correct type.
   */
  if (!Ret)
    return nullptr;
  while (const auto *A = dyn_cast<ArrayType>(Ret)) {
    if (A->isConstantArrayType())
      break;
    Ret = A->getElementType().getTypePtr();
  }

  const auto *CT = Ctx->getCanonicalType(Ret->getUnqualifiedDesugaredType());
  if (const auto *BT = dyn_cast<BuiltinType>(CT)) {
    switch (BT->getKind()) {
    case BuiltinType::Void:
    case BuiltinType::Char_S:
    case BuiltinType::Char_U:
    case BuiltinType::SChar:
    case BuiltinType::UChar:
    case BuiltinType::Char8:
      return nullptr;
    default:
      break;
    }
  }

  return Ret;
}

/*
 * Return true if the type is a pointer or contains pointers.
 */
bool FixusercopyCheck::checkPtr(ASTContext *Ctx, const Type *T) {
  if (!T)
    return false;

  if (Util::isCapability(Ctx, T))
    return true;

  if (const auto *A = dyn_cast<ArrayType>(T))
    return checkPtr(Ctx, A->getElementType().getTypePtr());

  const auto *R = T->getAs<RecordType>();
  if (!R)
    return false;

  auto *RD = R->getDecl();
  if (!RD)
    return false;

  for (const auto F : RD->fields()) {
    if (checkPtr(Ctx, F->getType().getTypePtr()))
      return true;
  }

  return false;
}

bool FixusercopyCheck::checkNonPtr(ASTContext *Ctx, const Type *OrigT) {
  const Type *T = OrigT;
  if (checkPtr(Ctx, T))
    return false;
  while (const auto *A = dyn_cast<ArrayType>(T))
    T = A->getElementType().getTypePtr();
  if (T->getAs<RecordType>())
    return true;
  if (T->isConstantArrayType())
    return true;

  const auto *CT = Ctx->getCanonicalType(T->getUnqualifiedDesugaredType());
  if (const auto *BT = dyn_cast<BuiltinType>(CT)) {
    switch (BT->getKind()) {
    case BuiltinType::Void:
    case BuiltinType::Char_S:
    case BuiltinType::Char_U:
    case BuiltinType::SChar:
    case BuiltinType::UChar:
    case BuiltinType::Char8:
      if (OrigT->isConstantArrayType())
        return true;
      break;
    default:
      return true;
    }
  }

  return false;
}

bool FixusercopyCheck::isBufferPlusOffset(ASTContext *Ctx, const Expr *E) {
  /* Strip casts */
  while (const auto *C = dyn_cast<CastExpr>(E))
    E = C->getSubExpr();

  /* Then strip parenthesis */
  while (const auto *P = dyn_cast<ParenExpr>(E))
    E = P->getSubExpr();

  /* Only interested in binary "+" expressions. */
  const auto Binop = dyn_cast<BinaryOperator>(E);
  if (!Binop || Binop->getOpcode() != BO_Add)
    return false;

  const auto *L = Binop->getLHS();
  const auto *R = Binop->getRHS();

  /*
   * If the offset is fixed, it might be an offset into some struct.
   * Thus don't pretend it is a character buffer offset.
   */
  if (R->getIntegerConstantExpr(*Ctx))
    return false;

  /* Check what the type of the LHS is. */
  const auto *LT = L->getType().getTypePtr()->getAs<PointerType>();
  if (!LT)
    return false;
  const auto *T = LT->getPointeeType().getTypePtr();
  if (!T)
    return false;
  const auto *CT = Ctx->getCanonicalType(T->getUnqualifiedDesugaredType());
  if (!CT)
    return false;
  const auto *BT = dyn_cast<BuiltinType>(CT);
  if (!BT)
    return false;

  /*
   * The LHS is a pointer and it points to a basic type.
   * Assume the character and void types indicate buffers.
   */
  switch (BT->getKind()) {
    case BuiltinType::Void:
    case BuiltinType::Char_S:
    case BuiltinType::Char_U:
    case BuiltinType::SChar:
    case BuiltinType::UChar:
    case BuiltinType::Char8:
      return true;
    default:
      break;
  }

  return false;
}

void FixusercopyCheck::check(const MatchFinder::MatchResult &Result) {
  auto Ctx = Result.Context;
  const auto *Call = Result.Nodes.getNodeAs<CallExpr>("call");

  if (!Call)
    return;

  if (Call->getNumArgs() < 3)
    diag(Call->getExprLoc(),
         "CHERI: ERROR: Too few arguments to user copy function");

  const Expr *A1 = Call->getArg(0);
  const Expr *A2 = Call->getArg(1);
  const Expr *A3 = Call->getArg(2);

  /* Fix size copy with less than 16-byte is always ok. */
  const auto Size = A3->getIntegerConstantExpr(*Ctx);
  if (Size && !Size->sge(16))
    return;

  const Type *T1 = getPointeeType(Ctx, A1);
  const Type *T2 = getPointeeType(Ctx, A2);
  const Type *T3 = nullptr;
  if (const auto *Utt = dyn_cast<UnaryExprOrTypeTraitExpr>(A3)) {
    if (Utt->getKind() == UETT_SizeOf)
      T3 = Utt->getTypeOfArgument().getTypePtr();
  }

  /*
   * If at least one argument allows us to derive a type and that
   * type is known to contain pointers warn about the issue.
   */
  if (checkPtr(Ctx, T1) || checkPtr(Ctx, T2) || checkPtr(Ctx, T3)) {
    const auto *Decl = Result.Nodes.getNodeAs<FunctionDecl>("decl");
    const auto Name = Decl->getDeclName().getAsString() + "_with_ptr";
    auto Callee = Call->getCallee();
    auto R = CharSourceRange::getTokenRange(Callee->getBeginLoc(),
                                            Callee->getEndLoc());
    diag(Call->getExprLoc(),
         "CHERI: Tags will be stripped during copy. Use `..._with_ptr` instead")
        << FixItHint::CreateReplacement(R, Name);
    return;
  }

#ifdef NOTYET
  /*
   * If neither of the arguments reveals the type warn because we
   * do not know what's copied.
   */
  if (!T1 && !T2 && !T3) {
    /*
     * If the size is non-constant and one side looks like a buffer
     * plus offset assume that it is copying opaque data.
     */
    if (!Size && (isBufferPlusOffset(Ctx, A1) || isBufferPlusOffset(Ctx, A2)))
      return;
    diag(Call->getExprLoc(),
         "CHERI: Cannot determine type of user copy");
    return;
  }

  /*
   * For each argument where we have a type check if we are reasonably
   * sure that it does not contain a pointer and warn if we aren't.
   */
  if (T1 && !checkNonPtr(Ctx, T1))
    diag(A1->getExprLoc(),
         "CHERI: Don't know if this contains pointers.");
  if (T2 && !checkNonPtr(Ctx, T2))
    diag(A2->getExprLoc(),
         "CHERI: Don't know if this contains pointers.");
  if (T3 && !checkNonPtr(Ctx, T3))
    diag(A3->getExprLoc(),
         "CHERI: Don't know if this contains pointers.");
#endif
}

} // namespace clang::tidy::cheri
