; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=thumbv8.1m.main-arm-none-eabi -mattr=+mve,+fullfp16 -verify-machineinstrs %s -o - | FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-MVE
; RUN: llc -mtriple=thumbv8.1m.main-arm-none-eabi -mattr=+mve.fp -verify-machineinstrs %s -o - | FileCheck %s --check-prefix=CHECK --check-prefix=CHECK-MVEFP

define arm_aapcs_vfpcc <4 x float> @fceil_float32_t(<4 x float> %src) {
; CHECK-MVE-LABEL: fceil_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vrintp.f32 s7, s3
; CHECK-MVE-NEXT:    vrintp.f32 s6, s2
; CHECK-MVE-NEXT:    vrintp.f32 s5, s1
; CHECK-MVE-NEXT:    vrintp.f32 s4, s0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: fceil_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintp.f32 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.ceil.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @fceil_float16_t(<8 x half> %src) {
; CHECK-MVE-LABEL: fceil_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmovx.f16 s4, s0
; CHECK-MVE-NEXT:    vrintp.f16 s8, s1
; CHECK-MVE-NEXT:    vrintp.f16 s4, s4
; CHECK-MVE-NEXT:    vmov r0, s4
; CHECK-MVE-NEXT:    vrintp.f16 s4, s0
; CHECK-MVE-NEXT:    vmov r1, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s3
; CHECK-MVE-NEXT:    vmov.16 q1[0], r1
; CHECK-MVE-NEXT:    vrintp.f16 s0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[1], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s1
; CHECK-MVE-NEXT:    vmov.16 q1[2], r0
; CHECK-MVE-NEXT:    vrintp.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintp.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[3], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[4], r0
; CHECK-MVE-NEXT:    vrintp.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintp.f16 s8, s3
; CHECK-MVE-NEXT:    vmov.16 q1[5], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmov.16 q1[6], r0
; CHECK-MVE-NEXT:    vmov r0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[7], r0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: fceil_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintp.f16 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.ceil.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @fceil_float64_t(<2 x double> %src) {
; CHECK-LABEL: fceil_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl ceil
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl ceil
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.ceil.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

define arm_aapcs_vfpcc <4 x float> @ftrunc_float32_t(<4 x float> %src) {
; CHECK-MVE-LABEL: ftrunc_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vrintz.f32 s7, s3
; CHECK-MVE-NEXT:    vrintz.f32 s6, s2
; CHECK-MVE-NEXT:    vrintz.f32 s5, s1
; CHECK-MVE-NEXT:    vrintz.f32 s4, s0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: ftrunc_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintz.f32 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.trunc.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @ftrunc_float16_t(<8 x half> %src) {
; CHECK-MVE-LABEL: ftrunc_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmovx.f16 s4, s0
; CHECK-MVE-NEXT:    vrintz.f16 s8, s1
; CHECK-MVE-NEXT:    vrintz.f16 s4, s4
; CHECK-MVE-NEXT:    vmov r0, s4
; CHECK-MVE-NEXT:    vrintz.f16 s4, s0
; CHECK-MVE-NEXT:    vmov r1, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s3
; CHECK-MVE-NEXT:    vmov.16 q1[0], r1
; CHECK-MVE-NEXT:    vrintz.f16 s0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[1], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s1
; CHECK-MVE-NEXT:    vmov.16 q1[2], r0
; CHECK-MVE-NEXT:    vrintz.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintz.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[3], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[4], r0
; CHECK-MVE-NEXT:    vrintz.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintz.f16 s8, s3
; CHECK-MVE-NEXT:    vmov.16 q1[5], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmov.16 q1[6], r0
; CHECK-MVE-NEXT:    vmov r0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[7], r0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: ftrunc_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintz.f16 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.trunc.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @ftrunc_float64_t(<2 x double> %src) {
; CHECK-LABEL: ftrunc_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl trunc
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl trunc
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.trunc.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

define arm_aapcs_vfpcc <4 x float> @frint_float32_t(<4 x float> %src) {
; CHECK-MVE-LABEL: frint_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vrintx.f32 s7, s3
; CHECK-MVE-NEXT:    vrintx.f32 s6, s2
; CHECK-MVE-NEXT:    vrintx.f32 s5, s1
; CHECK-MVE-NEXT:    vrintx.f32 s4, s0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: frint_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintx.f32 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.rint.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @frint_float16_t(<8 x half> %src) {
; CHECK-MVE-LABEL: frint_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmovx.f16 s4, s0
; CHECK-MVE-NEXT:    vrintx.f16 s8, s1
; CHECK-MVE-NEXT:    vrintx.f16 s4, s4
; CHECK-MVE-NEXT:    vmov r0, s4
; CHECK-MVE-NEXT:    vrintx.f16 s4, s0
; CHECK-MVE-NEXT:    vmov r1, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s3
; CHECK-MVE-NEXT:    vmov.16 q1[0], r1
; CHECK-MVE-NEXT:    vrintx.f16 s0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[1], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s1
; CHECK-MVE-NEXT:    vmov.16 q1[2], r0
; CHECK-MVE-NEXT:    vrintx.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[3], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[4], r0
; CHECK-MVE-NEXT:    vrintx.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintx.f16 s8, s3
; CHECK-MVE-NEXT:    vmov.16 q1[5], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmov.16 q1[6], r0
; CHECK-MVE-NEXT:    vmov r0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[7], r0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: frint_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintx.f16 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.rint.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @frint_float64_t(<2 x double> %src) {
; CHECK-LABEL: frint_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl rint
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl rint
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.rint.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

define arm_aapcs_vfpcc <4 x float> @fnearbyint_float32_t(<4 x float> %src) {
; CHECK-LABEL: fnearbyint_float32_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vrintr.f32 s7, s3
; CHECK-NEXT:    vrintr.f32 s6, s2
; CHECK-NEXT:    vrintr.f32 s5, s1
; CHECK-NEXT:    vrintr.f32 s4, s0
; CHECK-NEXT:    vmov q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.nearbyint.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @fnearbyint_float16_t(<8 x half> %src) {
; CHECK-LABEL: fnearbyint_float16_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    vmovx.f16 s4, s0
; CHECK-NEXT:    vrintr.f16 s8, s1
; CHECK-NEXT:    vrintr.f16 s4, s4
; CHECK-NEXT:    vmov r0, s4
; CHECK-NEXT:    vrintr.f16 s4, s0
; CHECK-NEXT:    vmov r1, s4
; CHECK-NEXT:    vmovx.f16 s0, s3
; CHECK-NEXT:    vmov.16 q1[0], r1
; CHECK-NEXT:    vrintr.f16 s0, s0
; CHECK-NEXT:    vmov.16 q1[1], r0
; CHECK-NEXT:    vmov r0, s8
; CHECK-NEXT:    vmovx.f16 s8, s1
; CHECK-NEXT:    vmov.16 q1[2], r0
; CHECK-NEXT:    vrintr.f16 s8, s8
; CHECK-NEXT:    vmov r0, s8
; CHECK-NEXT:    vrintr.f16 s8, s2
; CHECK-NEXT:    vmov.16 q1[3], r0
; CHECK-NEXT:    vmov r0, s8
; CHECK-NEXT:    vmovx.f16 s8, s2
; CHECK-NEXT:    vmov.16 q1[4], r0
; CHECK-NEXT:    vrintr.f16 s8, s8
; CHECK-NEXT:    vmov r0, s8
; CHECK-NEXT:    vrintr.f16 s8, s3
; CHECK-NEXT:    vmov.16 q1[5], r0
; CHECK-NEXT:    vmov r0, s8
; CHECK-NEXT:    vmov.16 q1[6], r0
; CHECK-NEXT:    vmov r0, s0
; CHECK-NEXT:    vmov.16 q1[7], r0
; CHECK-NEXT:    vmov q0, q1
; CHECK-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.nearbyint.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @fnearbyint_float64_t(<2 x double> %src) {
; CHECK-LABEL: fnearbyint_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl nearbyint
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl nearbyint
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.nearbyint.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

define arm_aapcs_vfpcc <4 x float> @ffloor_float32_t(<4 x float> %src) {
; CHECK-MVE-LABEL: ffloor_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vrintm.f32 s7, s3
; CHECK-MVE-NEXT:    vrintm.f32 s6, s2
; CHECK-MVE-NEXT:    vrintm.f32 s5, s1
; CHECK-MVE-NEXT:    vrintm.f32 s4, s0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: ffloor_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintm.f32 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.floor.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @ffloor_float16_t(<8 x half> %src) {
; CHECK-MVE-LABEL: ffloor_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmovx.f16 s4, s0
; CHECK-MVE-NEXT:    vrintm.f16 s8, s1
; CHECK-MVE-NEXT:    vrintm.f16 s4, s4
; CHECK-MVE-NEXT:    vmov r0, s4
; CHECK-MVE-NEXT:    vrintm.f16 s4, s0
; CHECK-MVE-NEXT:    vmov r1, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s3
; CHECK-MVE-NEXT:    vmov.16 q1[0], r1
; CHECK-MVE-NEXT:    vrintm.f16 s0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[1], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s1
; CHECK-MVE-NEXT:    vmov.16 q1[2], r0
; CHECK-MVE-NEXT:    vrintm.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintm.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[3], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[4], r0
; CHECK-MVE-NEXT:    vrintm.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrintm.f16 s8, s3
; CHECK-MVE-NEXT:    vmov.16 q1[5], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmov.16 q1[6], r0
; CHECK-MVE-NEXT:    vmov r0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[7], r0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: ffloor_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrintm.f16 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.floor.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @ffloor_float64_t(<2 x double> %src) {
; CHECK-LABEL: ffloor_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl floor
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl floor
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.floor.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

define arm_aapcs_vfpcc <4 x float> @fround_float32_t(<4 x float> %src) {
; CHECK-MVE-LABEL: fround_float32_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vrinta.f32 s7, s3
; CHECK-MVE-NEXT:    vrinta.f32 s6, s2
; CHECK-MVE-NEXT:    vrinta.f32 s5, s1
; CHECK-MVE-NEXT:    vrinta.f32 s4, s0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: fround_float32_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrinta.f32 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <4 x float> @llvm.round.v4f32(<4 x float> %src)
  ret <4 x float> %0
}

define arm_aapcs_vfpcc <8 x half> @fround_float16_t(<8 x half> %src) {
; CHECK-MVE-LABEL: fround_float16_t:
; CHECK-MVE:       @ %bb.0: @ %entry
; CHECK-MVE-NEXT:    vmovx.f16 s4, s0
; CHECK-MVE-NEXT:    vrinta.f16 s8, s1
; CHECK-MVE-NEXT:    vrinta.f16 s4, s4
; CHECK-MVE-NEXT:    vmov r0, s4
; CHECK-MVE-NEXT:    vrinta.f16 s4, s0
; CHECK-MVE-NEXT:    vmov r1, s4
; CHECK-MVE-NEXT:    vmovx.f16 s0, s3
; CHECK-MVE-NEXT:    vmov.16 q1[0], r1
; CHECK-MVE-NEXT:    vrinta.f16 s0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[1], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s1
; CHECK-MVE-NEXT:    vmov.16 q1[2], r0
; CHECK-MVE-NEXT:    vrinta.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrinta.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[3], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmovx.f16 s8, s2
; CHECK-MVE-NEXT:    vmov.16 q1[4], r0
; CHECK-MVE-NEXT:    vrinta.f16 s8, s8
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vrinta.f16 s8, s3
; CHECK-MVE-NEXT:    vmov.16 q1[5], r0
; CHECK-MVE-NEXT:    vmov r0, s8
; CHECK-MVE-NEXT:    vmov.16 q1[6], r0
; CHECK-MVE-NEXT:    vmov r0, s0
; CHECK-MVE-NEXT:    vmov.16 q1[7], r0
; CHECK-MVE-NEXT:    vmov q0, q1
; CHECK-MVE-NEXT:    bx lr
;
; CHECK-MVEFP-LABEL: fround_float16_t:
; CHECK-MVEFP:       @ %bb.0: @ %entry
; CHECK-MVEFP-NEXT:    vrinta.f16 q0, q0
; CHECK-MVEFP-NEXT:    bx lr
entry:
  %0 = call fast <8 x half> @llvm.round.v8f16(<8 x half> %src)
  ret <8 x half> %0
}

define arm_aapcs_vfpcc <2 x double> @fround_float64_t(<2 x double> %src) {
; CHECK-LABEL: fround_float64_t:
; CHECK:       @ %bb.0: @ %entry
; CHECK-NEXT:    .save {r7, lr}
; CHECK-NEXT:    push {r7, lr}
; CHECK-NEXT:    .vsave {d8, d9}
; CHECK-NEXT:    vpush {d8, d9}
; CHECK-NEXT:    vmov q4, q0
; CHECK-NEXT:    vmov r0, r1, d9
; CHECK-NEXT:    bl round
; CHECK-NEXT:    vmov r2, r3, d8
; CHECK-NEXT:    vmov d9, r0, r1
; CHECK-NEXT:    mov r0, r2
; CHECK-NEXT:    mov r1, r3
; CHECK-NEXT:    bl round
; CHECK-NEXT:    vmov d8, r0, r1
; CHECK-NEXT:    vmov q0, q4
; CHECK-NEXT:    vpop {d8, d9}
; CHECK-NEXT:    pop {r7, pc}
entry:
  %0 = call fast <2 x double> @llvm.round.v2f64(<2 x double> %src)
  ret <2 x double> %0
}

declare <4 x float> @llvm.ceil.v4f32(<4 x float>)
declare <4 x float> @llvm.trunc.v4f32(<4 x float>)
declare <4 x float> @llvm.rint.v4f32(<4 x float>)
declare <4 x float> @llvm.nearbyint.v4f32(<4 x float>)
declare <4 x float> @llvm.floor.v4f32(<4 x float>)
declare <4 x float> @llvm.round.v4f32(<4 x float>)
declare <8 x half> @llvm.ceil.v8f16(<8 x half>)
declare <8 x half> @llvm.trunc.v8f16(<8 x half>)
declare <8 x half> @llvm.rint.v8f16(<8 x half>)
declare <8 x half> @llvm.nearbyint.v8f16(<8 x half>)
declare <8 x half> @llvm.floor.v8f16(<8 x half>)
declare <8 x half> @llvm.round.v8f16(<8 x half>)
declare <2 x double> @llvm.ceil.v2f64(<2 x double>)
declare <2 x double> @llvm.trunc.v2f64(<2 x double>)
declare <2 x double> @llvm.rint.v2f64(<2 x double>)
declare <2 x double> @llvm.nearbyint.v2f64(<2 x double>)
declare <2 x double> @llvm.floor.v2f64(<2 x double>)
declare <2 x double> @llvm.round.v2f64(<2 x double>)
