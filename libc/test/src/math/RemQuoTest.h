//===-- Utility class to test different flavors of remquo -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIBC_TEST_SRC_MATH_REMQUOTEST_H
#define LLVM_LIBC_TEST_SRC_MATH_REMQUOTEST_H

#include "utils/FPUtil/BasicOperations.h"
#include "utils/FPUtil/FPBits.h"
#include "utils/FPUtil/TestHelpers.h"
#include "utils/MPFRWrapper/MPFRUtils.h"
#include "utils/UnitTest/Test.h"
#include <math.h>

namespace mpfr = __llvm_libc::testing::mpfr;

template <typename T>
class RemQuoTestTemplate : public __llvm_libc::testing::Test {
  using FPBits = __llvm_libc::fputil::FPBits<T>;
  using UIntType = typename FPBits::UIntType;

  const T zero = __llvm_libc::fputil::FPBits<T>::zero();
  const T negZero = __llvm_libc::fputil::FPBits<T>::negZero();
  const T inf = __llvm_libc::fputil::FPBits<T>::inf();
  const T negInf = __llvm_libc::fputil::FPBits<T>::negInf();
  const T nan = __llvm_libc::fputil::FPBits<T>::buildNaN(1);

public:
  typedef T (*RemQuoFunc)(T, T, int *);

  void testSpecialNumbers(RemQuoFunc func) {
    int quotient;
    T x, y;

    y = T(1.0);
    x = inf;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));
    x = negInf;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));

    x = T(1.0);
    y = zero;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));
    y = negZero;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));

    y = nan;
    x = T(1.0);
    EXPECT_FP_EQ(nan, func(x, y, &quotient));

    y = T(1.0);
    x = nan;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));

    x = nan;
    y = nan;
    EXPECT_FP_EQ(nan, func(x, y, &quotient));

    x = zero;
    y = T(1.0);
    EXPECT_FP_EQ(func(x, y, &quotient), zero);

    x = negZero;
    y = T(1.0);
    EXPECT_FP_EQ(func(x, y, &quotient), negZero);

    x = T(1.125);
    y = inf;
    EXPECT_FP_EQ(func(x, y, &quotient), x);
    EXPECT_EQ(quotient, 0);
  }

  void testEqualNumeratorAndDenominator(RemQuoFunc func) {
    T x = T(1.125), y = T(1.125);
    int q;

    // When the remainder is zero, the standard requires it to
    // have the same sign as x.

    EXPECT_FP_EQ(func(x, y, &q), zero);
    EXPECT_EQ(q, 1);

    EXPECT_FP_EQ(func(x, -y, &q), zero);
    EXPECT_EQ(q, -1);

    EXPECT_FP_EQ(func(-x, y, &q), negZero);
    EXPECT_EQ(q, -1);

    EXPECT_FP_EQ(func(-x, -y, &q), negZero);
    EXPECT_EQ(q, 1);
  }

  void testSubnormalRange(RemQuoFunc func) {
    constexpr UIntType count = 1000001;
    constexpr UIntType step =
        (FPBits::maxSubnormal - FPBits::minSubnormal) / count;
    for (UIntType v = FPBits::minSubnormal, w = FPBits::maxSubnormal;
         v <= FPBits::maxSubnormal && w >= FPBits::minSubnormal;
         v += step, w -= step) {
      T x = FPBits(v), y = FPBits(w);
      mpfr::BinaryOutput<T> result;
      mpfr::BinaryInput<T> input{x, y};
      result.f = func(x, y, &result.i);
      ASSERT_MPFR_MATCH(mpfr::Operation::RemQuo, input, result, 0.0);
    }
  }

  void testNormalRange(RemQuoFunc func) {
    constexpr UIntType count = 1000001;
    constexpr UIntType step = (FPBits::maxNormal - FPBits::minNormal) / count;
    for (UIntType v = FPBits::minNormal, w = FPBits::maxNormal;
         v <= FPBits::maxNormal && w >= FPBits::minNormal;
         v += step, w -= step) {
      T x = FPBits(v), y = FPBits(w);
      mpfr::BinaryOutput<T> result;
      mpfr::BinaryInput<T> input{x, y};
      result.f = func(x, y, &result.i);

      // In normal range on x86 platforms, the long double implicit 1 bit can be
      // zero making the numbers NaN. Hence we test for them separately.
      if (isnan(x) || isnan(y)) {
        ASSERT_NE(isnan(result.f), 0);
        continue;
      }

      ASSERT_MPFR_MATCH(mpfr::Operation::RemQuo, input, result, 0.0);
    }
  }
};

#define LIST_REMQUO_TESTS(T, func)                                             \
  using RemQuoTest = RemQuoTestTemplate<T>;                                    \
  TEST_F(RemQuoTest, SpecialNumbers) { testSpecialNumbers(&func); }            \
  TEST_F(RemQuoTest, EqualNumeratorAndDenominator) {                           \
    testEqualNumeratorAndDenominator(&func);                                   \
  }                                                                            \
  TEST_F(RemQuoTest, SubnormalRange) { testSubnormalRange(&func); }            \
  TEST_F(RemQuoTest, NormalRange) { testNormalRange(&func); }

#endif // LLVM_LIBC_TEST_SRC_MATH_REMQUOTEST_H
