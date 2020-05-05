// RUN: %clang_cc1 -D__ARM_FEATURE_SVE -D__ARM_FEATURE_SVE2 -triple aarch64-none-linux-gnu -target-feature +sve2 -fallow-half-arguments-and-returns -S -O1 -Werror -Wall -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -D__ARM_FEATURE_SVE -D__ARM_FEATURE_SVE2 -DSVE_OVERLOADED_FORMS -triple aarch64-none-linux-gnu -target-feature +sve2 -fallow-half-arguments-and-returns -S -O1 -Werror -Wall -emit-llvm -o - %s | FileCheck %s
// RUN: %clang_cc1 -D__ARM_FEATURE_SVE -triple aarch64-none-linux-gnu -target-feature +sve -fallow-half-arguments-and-returns -fsyntax-only -verify -verify-ignore-unexpected=error %s
// RUN: %clang_cc1 -D__ARM_FEATURE_SVE -DSVE_OVERLOADED_FORMS -triple aarch64-none-linux-gnu -target-feature +sve -fallow-half-arguments-and-returns -fsyntax-only -verify=overload -verify-ignore-unexpected=error %s

#include <arm_sve.h>

#ifdef SVE_OVERLOADED_FORMS
// A simple used,unused... macro, long enough to represent any SVE builtin.
#define SVE_ACLE_FUNC(A1,A2_UNUSED,A3,A4_UNUSED) A1##A3
#else
#define SVE_ACLE_FUNC(A1,A2,A3,A4) A1##A2##A3##A4
#endif

svint16_t test_svlogb_f16_z(svbool_t pg, svfloat16_t op)
{
  // CHECK-LABEL: test_svlogb_f16_z
  // CHECK: %[[PG:.*]] = call <vscale x 8 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv8i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 8 x i16> @llvm.aarch64.sve.flogb.nxv8f16(<vscale x 8 x i16> zeroinitializer, <vscale x 8 x i1> %[[PG]], <vscale x 8 x half> %op)
  // CHECK: ret <vscale x 8 x i16> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_z'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f16_z'}}
  return SVE_ACLE_FUNC(svlogb,_f16,_z,)(pg, op);
}

svint32_t test_svlogb_f32_z(svbool_t pg, svfloat32_t op)
{
  // CHECK-LABEL: test_svlogb_f32_z
  // CHECK: %[[PG:.*]] = call <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 4 x i32> @llvm.aarch64.sve.flogb.nxv4f32(<vscale x 4 x i32> zeroinitializer, <vscale x 4 x i1> %[[PG]], <vscale x 4 x float> %op)
  // CHECK: ret <vscale x 4 x i32> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_z'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f32_z'}}
  return SVE_ACLE_FUNC(svlogb,_f32,_z,)(pg, op);
}

svint64_t test_svlogb_f64_z(svbool_t pg, svfloat64_t op)
{
  // CHECK-LABEL: test_svlogb_f64_z
  // CHECK: %[[PG:.*]] = call <vscale x 2 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv2i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 2 x i64> @llvm.aarch64.sve.flogb.nxv2f64(<vscale x 2 x i64> zeroinitializer, <vscale x 2 x i1> %[[PG]], <vscale x 2 x double> %op)
  // CHECK: ret <vscale x 2 x i64> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_z'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f64_z'}}
  return SVE_ACLE_FUNC(svlogb,_f64,_z,)(pg, op);
}

svint16_t test_svlogb_f16_m(svint16_t inactive, svbool_t pg, svfloat16_t op)
{
  // CHECK-LABEL: test_svlogb_f16_m
  // CHECK: %[[PG:.*]] = call <vscale x 8 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv8i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 8 x i16> @llvm.aarch64.sve.flogb.nxv8f16(<vscale x 8 x i16> %inactive, <vscale x 8 x i1> %[[PG]], <vscale x 8 x half> %op)
  // CHECK: ret <vscale x 8 x i16> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_m'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f16_m'}}
  return SVE_ACLE_FUNC(svlogb,_f16,_m,)(inactive, pg, op);
}

svint32_t test_svlogb_f32_m(svint32_t inactive, svbool_t pg, svfloat32_t op)
{
  // CHECK-LABEL: test_svlogb_f32_m
  // CHECK: %[[PG:.*]] = call <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 4 x i32> @llvm.aarch64.sve.flogb.nxv4f32(<vscale x 4 x i32> %inactive, <vscale x 4 x i1> %[[PG]], <vscale x 4 x float> %op)
  // CHECK: ret <vscale x 4 x i32> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_m'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f32_m'}}
  return SVE_ACLE_FUNC(svlogb,_f32,_m,)(inactive, pg, op);
}

svint64_t test_svlogb_f64_m(svint64_t inactive, svbool_t pg, svfloat64_t op)
{
  // CHECK-LABEL: test_svlogb_f64_m
  // CHECK: %[[PG:.*]] = call <vscale x 2 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv2i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 2 x i64> @llvm.aarch64.sve.flogb.nxv2f64(<vscale x 2 x i64> %inactive, <vscale x 2 x i1> %[[PG]], <vscale x 2 x double> %op)
  // CHECK: ret <vscale x 2 x i64> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_m'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f64_m'}}
  return SVE_ACLE_FUNC(svlogb,_f64,_m,)(inactive, pg, op);
}

svint16_t test_svlogb_f16_x(svbool_t pg, svfloat16_t op)
{
  // CHECK-LABEL: test_svlogb_f16_x
  // CHECK: %[[PG:.*]] = call <vscale x 8 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv8i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 8 x i16> @llvm.aarch64.sve.flogb.nxv8f16(<vscale x 8 x i16> undef, <vscale x 8 x i1> %[[PG]], <vscale x 8 x half> %op)
  // CHECK: ret <vscale x 8 x i16> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_x'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f16_x'}}
  return SVE_ACLE_FUNC(svlogb,_f16,_x,)(pg, op);
}

svint32_t test_svlogb_f32_x(svbool_t pg, svfloat32_t op)
{
  // CHECK-LABEL: test_svlogb_f32_x
  // CHECK: %[[PG:.*]] = call <vscale x 4 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv4i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 4 x i32> @llvm.aarch64.sve.flogb.nxv4f32(<vscale x 4 x i32> undef, <vscale x 4 x i1> %[[PG]], <vscale x 4 x float> %op)
  // CHECK: ret <vscale x 4 x i32> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_x'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f32_x'}}
  return SVE_ACLE_FUNC(svlogb,_f32,_x,)(pg, op);
}

svint64_t test_svlogb_f64_x(svbool_t pg, svfloat64_t op)
{
  // CHECK-LABEL: test_svlogb_f64_x
  // CHECK: %[[PG:.*]] = call <vscale x 2 x i1> @llvm.aarch64.sve.convert.from.svbool.nxv2i1(<vscale x 16 x i1> %pg)
  // CHECK: %[[INTRINSIC:.*]] = call <vscale x 2 x i64> @llvm.aarch64.sve.flogb.nxv2f64(<vscale x 2 x i64> undef, <vscale x 2 x i1> %[[PG]], <vscale x 2 x double> %op)
  // CHECK: ret <vscale x 2 x i64> %[[INTRINSIC]]
  // overload-warning@+2 {{implicit declaration of function 'svlogb_x'}}
  // expected-warning@+1 {{implicit declaration of function 'svlogb_f64_x'}}
  return SVE_ACLE_FUNC(svlogb,_f64,_x,)(pg, op);
}
