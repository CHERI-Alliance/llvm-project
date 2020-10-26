; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

; Canonicalize rotate by constant to funnel shift intrinsics.
; This should help cost modeling for vectorization, inlining, etc.
; If a target does not have a rotate instruction, the expansion will
; be exactly these same 3 basic ops (shl/lshr/or).

define i32 @rotl_i32_constant(i32 %x) {
; CHECK-LABEL: @rotl_i32_constant(
; CHECK-NEXT:    [[R:%.*]] = call i32 @llvm.fshl.i32(i32 [[X:%.*]], i32 [[X]], i32 11)
; CHECK-NEXT:    ret i32 [[R]]
;
  %shl = shl i32 %x, 11
  %shr = lshr i32 %x, 21
  %r = or i32 %shr, %shl
  ret i32 %r
}

define i42 @rotr_i42_constant(i42 %x) {
; CHECK-LABEL: @rotr_i42_constant(
; CHECK-NEXT:    [[R:%.*]] = call i42 @llvm.fshl.i42(i42 [[X:%.*]], i42 [[X]], i42 31)
; CHECK-NEXT:    ret i42 [[R]]
;
  %shl = shl i42 %x, 31
  %shr = lshr i42 %x, 11
  %r = or i42 %shr, %shl
  ret i42 %r
}

define i8 @rotr_i8_constant_commute(i8 %x) {
; CHECK-LABEL: @rotr_i8_constant_commute(
; CHECK-NEXT:    [[R:%.*]] = call i8 @llvm.fshl.i8(i8 [[X:%.*]], i8 [[X]], i8 5)
; CHECK-NEXT:    ret i8 [[R]]
;
  %shl = shl i8 %x, 5
  %shr = lshr i8 %x, 3
  %r = or i8 %shl, %shr
  ret i8 %r
}

define i88 @rotl_i88_constant_commute(i88 %x) {
; CHECK-LABEL: @rotl_i88_constant_commute(
; CHECK-NEXT:    [[R:%.*]] = call i88 @llvm.fshl.i88(i88 [[X:%.*]], i88 [[X]], i88 44)
; CHECK-NEXT:    ret i88 [[R]]
;
  %shl = shl i88 %x, 44
  %shr = lshr i88 %x, 44
  %r = or i88 %shl, %shr
  ret i88 %r
}

; Vector types are allowed.

define <2 x i16> @rotl_v2i16_constant_splat(<2 x i16> %x) {
; CHECK-LABEL: @rotl_v2i16_constant_splat(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i16> @llvm.fshl.v2i16(<2 x i16> [[X:%.*]], <2 x i16> [[X]], <2 x i16> <i16 1, i16 1>)
; CHECK-NEXT:    ret <2 x i16> [[R]]
;
  %shl = shl <2 x i16> %x, <i16 1, i16 1>
  %shr = lshr <2 x i16> %x, <i16 15, i16 15>
  %r = or <2 x i16> %shl, %shr
  ret <2 x i16> %r
}

define <2 x i16> @rotl_v2i16_constant_splat_undef0(<2 x i16> %x) {
; CHECK-LABEL: @rotl_v2i16_constant_splat_undef0(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i16> @llvm.fshl.v2i16(<2 x i16> [[X:%.*]], <2 x i16> [[X]], <2 x i16> <i16 1, i16 1>)
; CHECK-NEXT:    ret <2 x i16> [[R]]
;
  %shl = shl <2 x i16> %x, <i16 undef, i16 1>
  %shr = lshr <2 x i16> %x, <i16 15, i16 15>
  %r = or <2 x i16> %shl, %shr
  ret <2 x i16> %r
}

define <2 x i16> @rotl_v2i16_constant_splat_undef1(<2 x i16> %x) {
; CHECK-LABEL: @rotl_v2i16_constant_splat_undef1(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i16> @llvm.fshl.v2i16(<2 x i16> [[X:%.*]], <2 x i16> [[X]], <2 x i16> <i16 1, i16 1>)
; CHECK-NEXT:    ret <2 x i16> [[R]]
;
  %shl = shl <2 x i16> %x, <i16 1, i16 1>
  %shr = lshr <2 x i16> %x, <i16 15, i16 undef>
  %r = or <2 x i16> %shl, %shr
  ret <2 x i16> %r
}

; Non-power-of-2 vector types are allowed.

define <2 x i17> @rotr_v2i17_constant_splat(<2 x i17> %x) {
; CHECK-LABEL: @rotr_v2i17_constant_splat(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i17> @llvm.fshl.v2i17(<2 x i17> [[X:%.*]], <2 x i17> [[X]], <2 x i17> <i17 12, i17 12>)
; CHECK-NEXT:    ret <2 x i17> [[R]]
;
  %shl = shl <2 x i17> %x, <i17 12, i17 12>
  %shr = lshr <2 x i17> %x, <i17 5, i17 5>
  %r = or <2 x i17> %shr, %shl
  ret <2 x i17> %r
}

define <2 x i17> @rotr_v2i17_constant_splat_undef0(<2 x i17> %x) {
; CHECK-LABEL: @rotr_v2i17_constant_splat_undef0(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i17> @llvm.fshl.v2i17(<2 x i17> [[X:%.*]], <2 x i17> [[X]], <2 x i17> <i17 12, i17 12>)
; CHECK-NEXT:    ret <2 x i17> [[R]]
;
  %shl = shl <2 x i17> %x, <i17 12, i17 undef>
  %shr = lshr <2 x i17> %x, <i17 undef, i17 5>
  %r = or <2 x i17> %shr, %shl
  ret <2 x i17> %r
}

define <2 x i17> @rotr_v2i17_constant_splat_undef1(<2 x i17> %x) {
; CHECK-LABEL: @rotr_v2i17_constant_splat_undef1(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i17> @llvm.fshl.v2i17(<2 x i17> [[X:%.*]], <2 x i17> [[X]], <2 x i17> <i17 12, i17 12>)
; CHECK-NEXT:    ret <2 x i17> [[R]]
;
  %shl = shl <2 x i17> %x, <i17 12, i17 undef>
  %shr = lshr <2 x i17> %x, <i17 5, i17 undef>
  %r = or <2 x i17> %shr, %shl
  ret <2 x i17> %r
}

; Allow arbitrary shift constants.
; Support undef elements.

define <2 x i32> @rotr_v2i32_constant_nonsplat(<2 x i32> %x) {
; CHECK-LABEL: @rotr_v2i32_constant_nonsplat(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i32> @llvm.fshl.v2i32(<2 x i32> [[X:%.*]], <2 x i32> [[X]], <2 x i32> <i32 17, i32 19>)
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %shl = shl <2 x i32> %x, <i32 17, i32 19>
  %shr = lshr <2 x i32> %x, <i32 15, i32 13>
  %r = or <2 x i32> %shl, %shr
  ret <2 x i32> %r
}

define <2 x i32> @rotr_v2i32_constant_nonsplat_undef0(<2 x i32> %x) {
; CHECK-LABEL: @rotr_v2i32_constant_nonsplat_undef0(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i32> @llvm.fshl.v2i32(<2 x i32> [[X:%.*]], <2 x i32> [[X]], <2 x i32> <i32 0, i32 19>)
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %shl = shl <2 x i32> %x, <i32 undef, i32 19>
  %shr = lshr <2 x i32> %x, <i32 15, i32 13>
  %r = or <2 x i32> %shl, %shr
  ret <2 x i32> %r
}

define <2 x i32> @rotr_v2i32_constant_nonsplat_undef1(<2 x i32> %x) {
; CHECK-LABEL: @rotr_v2i32_constant_nonsplat_undef1(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i32> @llvm.fshl.v2i32(<2 x i32> [[X:%.*]], <2 x i32> [[X]], <2 x i32> <i32 17, i32 0>)
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %shl = shl <2 x i32> %x, <i32 17, i32 19>
  %shr = lshr <2 x i32> %x, <i32 15, i32 undef>
  %r = or <2 x i32> %shl, %shr
  ret <2 x i32> %r
}

define <2 x i36> @rotl_v2i36_constant_nonsplat(<2 x i36> %x) {
; CHECK-LABEL: @rotl_v2i36_constant_nonsplat(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i36> @llvm.fshl.v2i36(<2 x i36> [[X:%.*]], <2 x i36> [[X]], <2 x i36> <i36 21, i36 11>)
; CHECK-NEXT:    ret <2 x i36> [[R]]
;
  %shl = shl <2 x i36> %x, <i36 21, i36 11>
  %shr = lshr <2 x i36> %x, <i36 15, i36 25>
  %r = or <2 x i36> %shl, %shr
  ret <2 x i36> %r
}

define <3 x i36> @rotl_v3i36_constant_nonsplat_undef0(<3 x i36> %x) {
; CHECK-LABEL: @rotl_v3i36_constant_nonsplat_undef0(
; CHECK-NEXT:    [[R:%.*]] = call <3 x i36> @llvm.fshl.v3i36(<3 x i36> [[X:%.*]], <3 x i36> [[X]], <3 x i36> <i36 21, i36 11, i36 0>)
; CHECK-NEXT:    ret <3 x i36> [[R]]
;
  %shl = shl <3 x i36> %x, <i36 21, i36 11, i36 undef>
  %shr = lshr <3 x i36> %x, <i36 15, i36 25, i36 undef>
  %r = or <3 x i36> %shl, %shr
  ret <3 x i36> %r
}

; The most basic rotate by variable - no guards for UB due to oversized shifts.
; This cannot be canonicalized to funnel shift target-independently. The safe
; expansion includes masking for the shift amount that is not included here,
; so it could be more expensive.

define i32 @rotl_i32(i32 %x, i32 %y) {
; CHECK-LABEL: @rotl_i32(
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 32, [[Y:%.*]]
; CHECK-NEXT:    [[SHL:%.*]] = shl i32 [[X:%.*]], [[Y]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 [[X]], [[SUB]]
; CHECK-NEXT:    [[R:%.*]] = or i32 [[SHR]], [[SHL]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %sub = sub i32 32, %y
  %shl = shl i32 %x, %y
  %shr = lshr i32 %x, %sub
  %r = or i32 %shr, %shl
  ret i32 %r
}

; Non-power-of-2 types should follow the same reasoning. Left/right is determined by subtract.

define i37 @rotr_i37(i37 %x, i37 %y) {
; CHECK-LABEL: @rotr_i37(
; CHECK-NEXT:    [[SUB:%.*]] = sub i37 37, [[Y:%.*]]
; CHECK-NEXT:    [[SHL:%.*]] = shl i37 [[X:%.*]], [[SUB]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i37 [[X]], [[Y]]
; CHECK-NEXT:    [[R:%.*]] = or i37 [[SHR]], [[SHL]]
; CHECK-NEXT:    ret i37 [[R]]
;
  %sub = sub i37 37, %y
  %shl = shl i37 %x, %sub
  %shr = lshr i37 %x, %y
  %r = or i37 %shr, %shl
  ret i37 %r
}

; Commute 'or' operands.

define i8 @rotr_i8_commute(i8 %x, i8 %y) {
; CHECK-LABEL: @rotr_i8_commute(
; CHECK-NEXT:    [[SUB:%.*]] = sub i8 8, [[Y:%.*]]
; CHECK-NEXT:    [[SHL:%.*]] = shl i8 [[X:%.*]], [[SUB]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i8 [[X]], [[Y]]
; CHECK-NEXT:    [[R:%.*]] = or i8 [[SHL]], [[SHR]]
; CHECK-NEXT:    ret i8 [[R]]
;
  %sub = sub i8 8, %y
  %shl = shl i8 %x, %sub
  %shr = lshr i8 %x, %y
  %r = or i8 %shl, %shr
  ret i8 %r
}

; Vector types should follow the same rules.

define <4 x i32> @rotl_v4i32(<4 x i32> %x, <4 x i32> %y) {
; CHECK-LABEL: @rotl_v4i32(
; CHECK-NEXT:    [[SUB:%.*]] = sub <4 x i32> <i32 32, i32 32, i32 32, i32 32>, [[Y:%.*]]
; CHECK-NEXT:    [[SHL:%.*]] = shl <4 x i32> [[X:%.*]], [[Y]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr <4 x i32> [[X]], [[SUB]]
; CHECK-NEXT:    [[R:%.*]] = or <4 x i32> [[SHL]], [[SHR]]
; CHECK-NEXT:    ret <4 x i32> [[R]]
;
  %sub = sub <4 x i32> <i32 32, i32 32, i32 32, i32 32>, %y
  %shl = shl <4 x i32> %x, %y
  %shr = lshr <4 x i32> %x, %sub
  %r = or <4 x i32> %shl, %shr
  ret <4 x i32> %r
}

; Non-power-of-2 vector types should follow the same rules.

define <3 x i42> @rotr_v3i42(<3 x i42> %x, <3 x i42> %y) {
; CHECK-LABEL: @rotr_v3i42(
; CHECK-NEXT:    [[SUB:%.*]] = sub <3 x i42> <i42 42, i42 42, i42 42>, [[Y:%.*]]
; CHECK-NEXT:    [[SHL:%.*]] = shl <3 x i42> [[X:%.*]], [[SUB]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr <3 x i42> [[X]], [[Y]]
; CHECK-NEXT:    [[R:%.*]] = or <3 x i42> [[SHR]], [[SHL]]
; CHECK-NEXT:    ret <3 x i42> [[R]]
;
  %sub = sub <3 x i42> <i42 42, i42 42, i42 42>, %y
  %shl = shl <3 x i42> %x, %sub
  %shr = lshr <3 x i42> %x, %y
  %r = or <3 x i42> %shr, %shl
  ret <3 x i42> %r
}

; This is the canonical pattern for a UB-safe rotate-by-variable with power-of-2-size scalar type.
; The backend expansion of funnel shift for targets that don't have a rotate instruction should
; match the original IR, so it is always good to canonicalize to the intrinsics for this pattern.

define i32 @rotl_safe_i32(i32 %x, i32 %y) {
; CHECK-LABEL: @rotl_safe_i32(
; CHECK-NEXT:    [[R:%.*]] = call i32 @llvm.fshl.i32(i32 [[X:%.*]], i32 [[X]], i32 [[Y:%.*]])
; CHECK-NEXT:    ret i32 [[R]]
;
  %negy = sub i32 0, %y
  %ymask = and i32 %y, 31
  %negymask = and i32 %negy, 31
  %shl = shl i32 %x, %ymask
  %shr = lshr i32 %x, %negymask
  %r = or i32 %shr, %shl
  ret i32 %r
}

; Extra uses don't change anything.

define i16 @rotl_safe_i16_commute_extra_use(i16 %x, i16 %y, i16* %p) {
; CHECK-LABEL: @rotl_safe_i16_commute_extra_use(
; CHECK-NEXT:    [[NEGY:%.*]] = sub i16 0, [[Y:%.*]]
; CHECK-NEXT:    [[NEGYMASK:%.*]] = and i16 [[NEGY]], 15
; CHECK-NEXT:    store i16 [[NEGYMASK]], i16* [[P:%.*]], align 2
; CHECK-NEXT:    [[R:%.*]] = call i16 @llvm.fshl.i16(i16 [[X:%.*]], i16 [[X]], i16 [[Y]])
; CHECK-NEXT:    ret i16 [[R]]
;
  %negy = sub i16 0, %y
  %ymask = and i16 %y, 15
  %negymask = and i16 %negy, 15
  store i16 %negymask, i16* %p
  %shl = shl i16 %x, %ymask
  %shr = lshr i16 %x, %negymask
  %r = or i16 %shl, %shr
  ret i16 %r
}

; Left/right is determined by the negation.

define i64 @rotr_safe_i64(i64 %x, i64 %y) {
; CHECK-LABEL: @rotr_safe_i64(
; CHECK-NEXT:    [[R:%.*]] = call i64 @llvm.fshr.i64(i64 [[X:%.*]], i64 [[X]], i64 [[Y:%.*]])
; CHECK-NEXT:    ret i64 [[R]]
;
  %negy = sub i64 0, %y
  %ymask = and i64 %y, 63
  %negymask = and i64 %negy, 63
  %shl = shl i64 %x, %negymask
  %shr = lshr i64 %x, %ymask
  %r = or i64 %shr, %shl
  ret i64 %r
}

; Extra uses don't change anything.

define i8 @rotr_safe_i8_commute_extra_use(i8 %x, i8 %y, i8* %p) {
; CHECK-LABEL: @rotr_safe_i8_commute_extra_use(
; CHECK-NEXT:    [[NEGY:%.*]] = sub i8 0, [[Y:%.*]]
; CHECK-NEXT:    [[YMASK:%.*]] = and i8 [[Y]], 7
; CHECK-NEXT:    [[NEGYMASK:%.*]] = and i8 [[NEGY]], 7
; CHECK-NEXT:    [[SHL:%.*]] = shl i8 [[X:%.*]], [[NEGYMASK]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i8 [[X]], [[YMASK]]
; CHECK-NEXT:    store i8 [[SHR]], i8* [[P:%.*]], align 1
; CHECK-NEXT:    [[R:%.*]] = or i8 [[SHL]], [[SHR]]
; CHECK-NEXT:    ret i8 [[R]]
;
  %negy = sub i8 0, %y
  %ymask = and i8 %y, 7
  %negymask = and i8 %negy, 7
  %shl = shl i8 %x, %negymask
  %shr = lshr i8 %x, %ymask
  store i8 %shr, i8* %p
  %r = or i8 %shl, %shr
  ret i8 %r
}

; Vectors follow the same rules.

define <2 x i32> @rotl_safe_v2i32(<2 x i32> %x, <2 x i32> %y) {
; CHECK-LABEL: @rotl_safe_v2i32(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i32> @llvm.fshl.v2i32(<2 x i32> [[X:%.*]], <2 x i32> [[X]], <2 x i32> [[Y:%.*]])
; CHECK-NEXT:    ret <2 x i32> [[R]]
;
  %negy = sub <2 x i32> zeroinitializer, %y
  %ymask = and <2 x i32> %y, <i32 31, i32 31>
  %negymask = and <2 x i32> %negy, <i32 31, i32 31>
  %shl = shl <2 x i32> %x, %ymask
  %shr = lshr <2 x i32> %x, %negymask
  %r = or <2 x i32> %shr, %shl
  ret <2 x i32> %r
}

; Vectors follow the same rules.

define <3 x i16> @rotr_safe_v3i16(<3 x i16> %x, <3 x i16> %y) {
; CHECK-LABEL: @rotr_safe_v3i16(
; CHECK-NEXT:    [[R:%.*]] = call <3 x i16> @llvm.fshr.v3i16(<3 x i16> [[X:%.*]], <3 x i16> [[X]], <3 x i16> [[Y:%.*]])
; CHECK-NEXT:    ret <3 x i16> [[R]]
;
  %negy = sub <3 x i16> zeroinitializer, %y
  %ymask = and <3 x i16> %y, <i16 15, i16 15, i16 15>
  %negymask = and <3 x i16> %negy, <i16 15, i16 15, i16 15>
  %shl = shl <3 x i16> %x, %negymask
  %shr = lshr <3 x i16> %x, %ymask
  %r = or <3 x i16> %shr, %shl
  ret <3 x i16> %r
}

; These are optionally UB-free rotate left/right patterns that are narrowed to a smaller bitwidth.
; See PR34046, PR16726, and PR39624 for motivating examples:
; https://bugs.llvm.org/show_bug.cgi?id=34046
; https://bugs.llvm.org/show_bug.cgi?id=16726
; https://bugs.llvm.org/show_bug.cgi?id=39624

define i16 @rotate_left_16bit(i16 %v, i32 %shift) {
; CHECK-LABEL: @rotate_left_16bit(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHIFT:%.*]] to i16
; CHECK-NEXT:    [[CONV2:%.*]] = call i16 @llvm.fshl.i16(i16 [[V:%.*]], i16 [[V]], i16 [[TMP1]])
; CHECK-NEXT:    ret i16 [[CONV2]]
;
  %and = and i32 %shift, 15
  %conv = zext i16 %v to i32
  %shl = shl i32 %conv, %and
  %sub = sub i32 16, %and
  %shr = lshr i32 %conv, %sub
  %or = or i32 %shr, %shl
  %conv2 = trunc i32 %or to i16
  ret i16 %conv2
}

; Commute the 'or' operands and try a vector type.

define <2 x i16> @rotate_left_commute_16bit_vec(<2 x i16> %v, <2 x i32> %shift) {
; CHECK-LABEL: @rotate_left_commute_16bit_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc <2 x i32> [[SHIFT:%.*]] to <2 x i16>
; CHECK-NEXT:    [[CONV2:%.*]] = call <2 x i16> @llvm.fshl.v2i16(<2 x i16> [[V:%.*]], <2 x i16> [[V]], <2 x i16> [[TMP1]])
; CHECK-NEXT:    ret <2 x i16> [[CONV2]]
;
  %and = and <2 x i32> %shift, <i32 15, i32 15>
  %conv = zext <2 x i16> %v to <2 x i32>
  %shl = shl <2 x i32> %conv, %and
  %sub = sub <2 x i32> <i32 16, i32 16>, %and
  %shr = lshr <2 x i32> %conv, %sub
  %or = or <2 x i32> %shl, %shr
  %conv2 = trunc <2 x i32> %or to <2 x i16>
  ret <2 x i16> %conv2
}

; Change the size, rotation direction (the subtract is on the left-shift), and mask op.

define i8 @rotate_right_8bit(i8 %v, i3 %shift) {
; CHECK-LABEL: @rotate_right_8bit(
; CHECK-NEXT:    [[TMP1:%.*]] = zext i3 [[SHIFT:%.*]] to i8
; CHECK-NEXT:    [[CONV2:%.*]] = call i8 @llvm.fshr.i8(i8 [[V:%.*]], i8 [[V]], i8 [[TMP1]])
; CHECK-NEXT:    ret i8 [[CONV2]]
;
  %and = zext i3 %shift to i32
  %conv = zext i8 %v to i32
  %shr = lshr i32 %conv, %and
  %sub = sub i32 8, %and
  %shl = shl i32 %conv, %sub
  %or = or i32 %shl, %shr
  %conv2 = trunc i32 %or to i8
  ret i8 %conv2
}

; The shifted value does not need to be a zexted value; here it is masked.
; The shift mask could be less than the bitwidth, but this is still ok.

define i8 @rotate_right_commute_8bit(i32 %v, i32 %shift) {
; CHECK-LABEL: @rotate_right_commute_8bit(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHIFT:%.*]] to i8
; CHECK-NEXT:    [[TMP2:%.*]] = and i8 [[TMP1]], 3
; CHECK-NEXT:    [[TMP3:%.*]] = trunc i32 [[V:%.*]] to i8
; CHECK-NEXT:    [[CONV2:%.*]] = call i8 @llvm.fshr.i8(i8 [[TMP3]], i8 [[TMP3]], i8 [[TMP2]])
; CHECK-NEXT:    ret i8 [[CONV2]]
;
  %and = and i32 %shift, 3
  %conv = and i32 %v, 255
  %shr = lshr i32 %conv, %and
  %sub = sub i32 8, %and
  %shl = shl i32 %conv, %sub
  %or = or i32 %shr, %shl
  %conv2 = trunc i32 %or to i8
  ret i8 %conv2
}

; If the original source does not mask the shift amount,
; we still do the transform by adding masks to make it safe.

define i8 @rotate8_not_safe(i8 %v, i32 %shamt) {
; CHECK-LABEL: @rotate8_not_safe(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHAMT:%.*]] to i8
; CHECK-NEXT:    [[RET:%.*]] = call i8 @llvm.fshl.i8(i8 [[V:%.*]], i8 [[V]], i8 [[TMP1]])
; CHECK-NEXT:    ret i8 [[RET]]
;
  %conv = zext i8 %v to i32
  %sub = sub i32 8, %shamt
  %shr = lshr i32 %conv, %sub
  %shl = shl i32 %conv, %shamt
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i8
  ret i8 %ret
}

; A non-power-of-2 destination type can't be masked as above.

define i9 @rotate9_not_safe(i9 %v, i32 %shamt) {
; CHECK-LABEL: @rotate9_not_safe(
; CHECK-NEXT:    [[CONV:%.*]] = zext i9 [[V:%.*]] to i32
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 9, [[SHAMT:%.*]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 [[CONV]], [[SUB]]
; CHECK-NEXT:    [[SHL:%.*]] = shl i32 [[CONV]], [[SHAMT]]
; CHECK-NEXT:    [[OR:%.*]] = or i32 [[SHR]], [[SHL]]
; CHECK-NEXT:    [[RET:%.*]] = trunc i32 [[OR]] to i9
; CHECK-NEXT:    ret i9 [[RET]]
;
  %conv = zext i9 %v to i32
  %sub = sub i32 9, %shamt
  %shr = lshr i32 %conv, %sub
  %shl = shl i32 %conv, %shamt
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i9
  ret i9 %ret
}

; We should narrow (v << (s & 15)) | (v >> (-s & 15))
; when both v and s have been promoted.

define i16 @rotateleft_16_neg_mask(i16 %v, i16 %shamt) {
; CHECK-LABEL: @rotateleft_16_neg_mask(
; CHECK-NEXT:    [[OR:%.*]] = call i16 @llvm.fshl.i16(i16 [[V:%.*]], i16 [[V]], i16 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i16 [[OR]]
;
  %neg = sub i16 0, %shamt
  %lshamt = and i16 %shamt, 15
  %lshamtconv = zext i16 %lshamt to i32
  %rshamt = and i16 %neg, 15
  %rshamtconv = zext i16 %rshamt to i32
  %conv = zext i16 %v to i32
  %shl = shl i32 %conv, %lshamtconv
  %shr = lshr i32 %conv, %rshamtconv
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i16
  ret i16 %ret
}

define i16 @rotateleft_16_neg_mask_commute(i16 %v, i16 %shamt) {
; CHECK-LABEL: @rotateleft_16_neg_mask_commute(
; CHECK-NEXT:    [[OR:%.*]] = call i16 @llvm.fshl.i16(i16 [[V:%.*]], i16 [[V]], i16 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i16 [[OR]]
;
  %neg = sub i16 0, %shamt
  %lshamt = and i16 %shamt, 15
  %lshamtconv = zext i16 %lshamt to i32
  %rshamt = and i16 %neg, 15
  %rshamtconv = zext i16 %rshamt to i32
  %conv = zext i16 %v to i32
  %shl = shl i32 %conv, %lshamtconv
  %shr = lshr i32 %conv, %rshamtconv
  %or = or i32 %shl, %shr
  %ret = trunc i32 %or to i16
  ret i16 %ret
}

define i8 @rotateright_8_neg_mask(i8 %v, i8 %shamt) {
; CHECK-LABEL: @rotateright_8_neg_mask(
; CHECK-NEXT:    [[OR:%.*]] = call i8 @llvm.fshr.i8(i8 [[V:%.*]], i8 [[V]], i8 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i8 [[OR]]
;
  %neg = sub i8 0, %shamt
  %rshamt = and i8 %shamt, 7
  %rshamtconv = zext i8 %rshamt to i32
  %lshamt = and i8 %neg, 7
  %lshamtconv = zext i8 %lshamt to i32
  %conv = zext i8 %v to i32
  %shl = shl i32 %conv, %lshamtconv
  %shr = lshr i32 %conv, %rshamtconv
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i8
  ret i8 %ret
}

define i8 @rotateright_8_neg_mask_commute(i8 %v, i8 %shamt) {
; CHECK-LABEL: @rotateright_8_neg_mask_commute(
; CHECK-NEXT:    [[OR:%.*]] = call i8 @llvm.fshr.i8(i8 [[V:%.*]], i8 [[V]], i8 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i8 [[OR]]
;
  %neg = sub i8 0, %shamt
  %rshamt = and i8 %shamt, 7
  %rshamtconv = zext i8 %rshamt to i32
  %lshamt = and i8 %neg, 7
  %lshamtconv = zext i8 %lshamt to i32
  %conv = zext i8 %v to i32
  %shl = shl i32 %conv, %lshamtconv
  %shr = lshr i32 %conv, %rshamtconv
  %or = or i32 %shl, %shr
  %ret = trunc i32 %or to i8
  ret i8 %ret
}

; The shift amount may already be in the wide type,
; so we need to truncate it going into the rotate pattern.

define i16 @rotateright_16_neg_mask_wide_amount(i16 %v, i32 %shamt) {
; CHECK-LABEL: @rotateright_16_neg_mask_wide_amount(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHAMT:%.*]] to i16
; CHECK-NEXT:    [[RET:%.*]] = call i16 @llvm.fshr.i16(i16 [[V:%.*]], i16 [[V]], i16 [[TMP1]])
; CHECK-NEXT:    ret i16 [[RET]]
;
  %neg = sub i32 0, %shamt
  %rshamt = and i32 %shamt, 15
  %lshamt = and i32 %neg, 15
  %conv = zext i16 %v to i32
  %shl = shl i32 %conv, %lshamt
  %shr = lshr i32 %conv, %rshamt
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i16
  ret i16 %ret
}

define i16 @rotateright_16_neg_mask_wide_amount_commute(i16 %v, i32 %shamt) {
; CHECK-LABEL: @rotateright_16_neg_mask_wide_amount_commute(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHAMT:%.*]] to i16
; CHECK-NEXT:    [[RET:%.*]] = call i16 @llvm.fshr.i16(i16 [[V:%.*]], i16 [[V]], i16 [[TMP1]])
; CHECK-NEXT:    ret i16 [[RET]]
;
  %neg = sub i32 0, %shamt
  %rshamt = and i32 %shamt, 15
  %lshamt = and i32 %neg, 15
  %conv = zext i16 %v to i32
  %shl = shl i32 %conv, %lshamt
  %shr = lshr i32 %conv, %rshamt
  %or = or i32 %shl, %shr
  %ret = trunc i32 %or to i16
  ret i16 %ret
}

define i64 @rotateright_64_zext_neg_mask_amount(i64 %0, i32 %1) {
; CHECK-LABEL: @rotateright_64_zext_neg_mask_amount(
; CHECK-NEXT:    [[TMP3:%.*]] = zext i32 [[TMP1:%.*]] to i64
; CHECK-NEXT:    [[TMP4:%.*]] = call i64 @llvm.fshr.i64(i64 [[TMP0:%.*]], i64 [[TMP0]], i64 [[TMP3]])
; CHECK-NEXT:    ret i64 [[TMP4]]
;
  %3 = and i32 %1, 63
  %4 = zext i32 %3 to i64
  %5 = lshr i64 %0, %4
  %6 = sub nsw i32 0, %1
  %7 = and i32 %6, 63
  %8 = zext i32 %7 to i64
  %9 = shl i64 %0, %8
  %10 = or i64 %5, %9
  ret i64 %10
}

define i8 @rotateleft_8_neg_mask_wide_amount(i8 %v, i32 %shamt) {
; CHECK-LABEL: @rotateleft_8_neg_mask_wide_amount(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHAMT:%.*]] to i8
; CHECK-NEXT:    [[RET:%.*]] = call i8 @llvm.fshl.i8(i8 [[V:%.*]], i8 [[V]], i8 [[TMP1]])
; CHECK-NEXT:    ret i8 [[RET]]
;
  %neg = sub i32 0, %shamt
  %lshamt = and i32 %shamt, 7
  %rshamt = and i32 %neg, 7
  %conv = zext i8 %v to i32
  %shl = shl i32 %conv, %lshamt
  %shr = lshr i32 %conv, %rshamt
  %or = or i32 %shr, %shl
  %ret = trunc i32 %or to i8
  ret i8 %ret
}

define i8 @rotateleft_8_neg_mask_wide_amount_commute(i8 %v, i32 %shamt) {
; CHECK-LABEL: @rotateleft_8_neg_mask_wide_amount_commute(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[SHAMT:%.*]] to i8
; CHECK-NEXT:    [[RET:%.*]] = call i8 @llvm.fshl.i8(i8 [[V:%.*]], i8 [[V]], i8 [[TMP1]])
; CHECK-NEXT:    ret i8 [[RET]]
;
  %neg = sub i32 0, %shamt
  %lshamt = and i32 %shamt, 7
  %rshamt = and i32 %neg, 7
  %conv = zext i8 %v to i32
  %shl = shl i32 %conv, %lshamt
  %shr = lshr i32 %conv, %rshamt
  %or = or i32 %shl, %shr
  %ret = trunc i32 %or to i8
  ret i8 %ret
}

define i64 @rotateleft_64_zext_neg_mask_amount(i64 %0, i32 %1) {
; CHECK-LABEL: @rotateleft_64_zext_neg_mask_amount(
; CHECK-NEXT:    [[TMP3:%.*]] = zext i32 [[TMP1:%.*]] to i64
; CHECK-NEXT:    [[TMP4:%.*]] = call i64 @llvm.fshl.i64(i64 [[TMP0:%.*]], i64 [[TMP0]], i64 [[TMP3]])
; CHECK-NEXT:    ret i64 [[TMP4]]
;
  %3 = and i32 %1, 63
  %4 = zext i32 %3 to i64
  %5 = shl i64 %0, %4
  %6 = sub nsw i32 0, %1
  %7 = and i32 %6, 63
  %8 = zext i32 %7 to i64
  %9 = lshr i64 %0, %8
  %10 = or i64 %5, %9
  ret i64 %10
}

; Non-power-of-2 types. This could be transformed, but it's not a typical rotate pattern.

define i9 @rotateleft_9_neg_mask_wide_amount_commute(i9 %v, i33 %shamt) {
; CHECK-LABEL: @rotateleft_9_neg_mask_wide_amount_commute(
; CHECK-NEXT:    [[NEG:%.*]] = sub i33 0, [[SHAMT:%.*]]
; CHECK-NEXT:    [[LSHAMT:%.*]] = and i33 [[SHAMT]], 8
; CHECK-NEXT:    [[RSHAMT:%.*]] = and i33 [[NEG]], 8
; CHECK-NEXT:    [[CONV:%.*]] = zext i9 [[V:%.*]] to i33
; CHECK-NEXT:    [[SHL:%.*]] = shl i33 [[CONV]], [[LSHAMT]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i33 [[CONV]], [[RSHAMT]]
; CHECK-NEXT:    [[OR:%.*]] = or i33 [[SHL]], [[SHR]]
; CHECK-NEXT:    [[RET:%.*]] = trunc i33 [[OR]] to i9
; CHECK-NEXT:    ret i9 [[RET]]
;
  %neg = sub i33 0, %shamt
  %lshamt = and i33 %shamt, 8
  %rshamt = and i33 %neg, 8
  %conv = zext i9 %v to i33
  %shl = shl i33 %conv, %lshamt
  %shr = lshr i33 %conv, %rshamt
  %or = or i33 %shl, %shr
  %ret = trunc i33 %or to i9
  ret i9 %ret
}

; Fold or(shl(v,x),lshr(v,bw-x)) iff x < bw

define i64 @rotl_sub_mask(i64 %0, i64 %1) {
; CHECK-LABEL: @rotl_sub_mask(
; CHECK-NEXT:    [[TMP3:%.*]] = call i64 @llvm.fshl.i64(i64 [[TMP0:%.*]], i64 [[TMP0]], i64 [[TMP1:%.*]])
; CHECK-NEXT:    ret i64 [[TMP3]]
;
  %3 = and i64 %1, 63
  %4 = shl i64 %0, %3
  %5 = sub nuw nsw i64 64, %3
  %6 = lshr i64 %0, %5
  %7 = or i64 %6, %4
  ret i64 %7
}

; Fold or(lshr(v,x),shl(v,bw-x)) iff x < bw

define i64 @rotr_sub_mask(i64 %0, i64 %1) {
; CHECK-LABEL: @rotr_sub_mask(
; CHECK-NEXT:    [[TMP3:%.*]] = call i64 @llvm.fshr.i64(i64 [[TMP0:%.*]], i64 [[TMP0]], i64 [[TMP1:%.*]])
; CHECK-NEXT:    ret i64 [[TMP3]]
;
  %3 = and i64 %1, 63
  %4 = lshr i64 %0, %3
  %5 = sub nuw nsw i64 64, %3
  %6 = shl i64 %0, %5
  %7 = or i64 %6, %4
  ret i64 %7
}

define <2 x i64> @rotr_sub_mask_vector(<2 x i64> %0, <2 x i64> %1) {
; CHECK-LABEL: @rotr_sub_mask_vector(
; CHECK-NEXT:    [[TMP3:%.*]] = call <2 x i64> @llvm.fshr.v2i64(<2 x i64> [[TMP0:%.*]], <2 x i64> [[TMP0]], <2 x i64> [[TMP1:%.*]])
; CHECK-NEXT:    ret <2 x i64> [[TMP3]]
;
  %3 = and <2 x i64> %1, <i64 63, i64 63>
  %4 = lshr <2 x i64> %0, %3
  %5 = sub nuw nsw <2 x i64> <i64 64, i64 64>, %3
  %6 = shl <2 x i64> %0, %5
  %7 = or <2 x i64> %6, %4
  ret <2 x i64> %7
}

; Convert select pattern to masked shift that ends in 'or'.

define i32 @rotr_select(i32 %x, i32 %shamt) {
; CHECK-LABEL: @rotr_select(
; CHECK-NEXT:    [[R:%.*]] = call i32 @llvm.fshr.i32(i32 [[X:%.*]], i32 [[X]], i32 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i32 [[R]]
;
  %cmp = icmp eq i32 %shamt, 0
  %sub = sub i32 32, %shamt
  %shr = lshr i32 %x, %shamt
  %shl = shl i32 %x, %sub
  %or = or i32 %shr, %shl
  %r = select i1 %cmp, i32 %x, i32 %or
  ret i32 %r
}

; Convert select pattern to masked shift that ends in 'or'.

define i8 @rotr_select_commute(i8 %x, i8 %shamt) {
; CHECK-LABEL: @rotr_select_commute(
; CHECK-NEXT:    [[R:%.*]] = call i8 @llvm.fshr.i8(i8 [[X:%.*]], i8 [[X]], i8 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i8 [[R]]
;
  %cmp = icmp eq i8 %shamt, 0
  %sub = sub i8 8, %shamt
  %shr = lshr i8 %x, %shamt
  %shl = shl i8 %x, %sub
  %or = or i8 %shl, %shr
  %r = select i1 %cmp, i8 %x, i8 %or
  ret i8 %r
}

; Convert select pattern to masked shift that ends in 'or'.

define i16 @rotl_select(i16 %x, i16 %shamt) {
; CHECK-LABEL: @rotl_select(
; CHECK-NEXT:    [[R:%.*]] = call i16 @llvm.fshl.i16(i16 [[X:%.*]], i16 [[X]], i16 [[SHAMT:%.*]])
; CHECK-NEXT:    ret i16 [[R]]
;
  %cmp = icmp eq i16 %shamt, 0
  %sub = sub i16 16, %shamt
  %shr = lshr i16 %x, %sub
  %shl = shl i16 %x, %shamt
  %or = or i16 %shr, %shl
  %r = select i1 %cmp, i16 %x, i16 %or
  ret i16 %r
}

; Convert select pattern to masked shift that ends in 'or'.

define <2 x i64> @rotl_select_commute(<2 x i64> %x, <2 x i64> %shamt) {
; CHECK-LABEL: @rotl_select_commute(
; CHECK-NEXT:    [[R:%.*]] = call <2 x i64> @llvm.fshl.v2i64(<2 x i64> [[X:%.*]], <2 x i64> [[X]], <2 x i64> [[SHAMT:%.*]])
; CHECK-NEXT:    ret <2 x i64> [[R]]
;
  %cmp = icmp eq <2 x i64> %shamt, zeroinitializer
  %sub = sub <2 x i64> <i64 64, i64 64>, %shamt
  %shr = lshr <2 x i64> %x, %sub
  %shl = shl <2 x i64> %x, %shamt
  %or = or <2 x i64> %shl, %shr
  %r = select <2 x i1> %cmp, <2 x i64> %x, <2 x i64> %or
  ret <2 x i64> %r
}

; Negative test - the transform is only valid with power-of-2 types.

define i24 @rotl_select_weird_type(i24 %x, i24 %shamt) {
; CHECK-LABEL: @rotl_select_weird_type(
; CHECK-NEXT:    [[CMP:%.*]] = icmp eq i24 [[SHAMT:%.*]], 0
; CHECK-NEXT:    [[SUB:%.*]] = sub i24 24, [[SHAMT]]
; CHECK-NEXT:    [[SHR:%.*]] = lshr i24 [[X:%.*]], [[SUB]]
; CHECK-NEXT:    [[SHL:%.*]] = shl i24 [[X]], [[SHAMT]]
; CHECK-NEXT:    [[OR:%.*]] = or i24 [[SHL]], [[SHR]]
; CHECK-NEXT:    [[R:%.*]] = select i1 [[CMP]], i24 [[X]], i24 [[OR]]
; CHECK-NEXT:    ret i24 [[R]]
;
  %cmp = icmp eq i24 %shamt, 0
  %sub = sub i24 24, %shamt
  %shr = lshr i24 %x, %sub
  %shl = shl i24 %x, %shamt
  %or = or i24 %shl, %shr
  %r = select i1 %cmp, i24 %x, i24 %or
  ret i24 %r
}

define i32 @rotl_select_zext_shamt(i32 %x, i8 %y) {
; CHECK-LABEL: @rotl_select_zext_shamt(
; CHECK-NEXT:    [[TMP1:%.*]] = zext i8 [[Y:%.*]] to i32
; CHECK-NEXT:    [[R:%.*]] = call i32 @llvm.fshl.i32(i32 [[X:%.*]], i32 [[X]], i32 [[TMP1]])
; CHECK-NEXT:    ret i32 [[R]]
;
  %rem = and i8 %y, 31
  %cmp = icmp eq i8 %rem, 0
  %sh_prom = zext i8 %rem to i32
  %sub = sub nuw nsw i8 32, %rem
  %sh_prom1 = zext i8 %sub to i32
  %shr = lshr i32 %x, %sh_prom1
  %shl = shl i32 %x, %sh_prom
  %or = or i32 %shl, %shr
  %r = select i1 %cmp, i32 %x, i32 %or
  ret i32 %r
}

define i64 @rotr_select_zext_shamt(i64 %x, i32 %y) {
; CHECK-LABEL: @rotr_select_zext_shamt(
; CHECK-NEXT:    [[TMP1:%.*]] = zext i32 [[Y:%.*]] to i64
; CHECK-NEXT:    [[R:%.*]] = call i64 @llvm.fshr.i64(i64 [[X:%.*]], i64 [[X]], i64 [[TMP1]])
; CHECK-NEXT:    ret i64 [[R]]
;
  %rem = and i32 %y, 63
  %cmp = icmp eq i32 %rem, 0
  %sh_prom = zext i32 %rem to i64
  %shr = lshr i64 %x, %sh_prom
  %sub = sub nuw nsw i32 64, %rem
  %sh_prom1 = zext i32 %sub to i64
  %shl = shl i64 %x, %sh_prom1
  %or = or i64 %shl, %shr
  %r = select i1 %cmp, i64 %x, i64 %or
  ret i64 %r
}

; Test that the transform doesn't crash when there's an "or" with a ConstantExpr operand.

@external_global = external global i8

define i32 @rotl_constant_expr(i32 %shamt) {
; CHECK-LABEL: @rotl_constant_expr(
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 ptrtoint (i8* @external_global to i32), [[SHAMT:%.*]]
; CHECK-NEXT:    [[R:%.*]] = or i32 [[SHR]], shl (i32 ptrtoint (i8* @external_global to i32), i32 11)
; CHECK-NEXT:    ret i32 [[R]]
;
  %shr = lshr i32 ptrtoint (i8* @external_global to i32), %shamt
  %r = or i32 %shr, shl (i32 ptrtoint (i8* @external_global to i32), i32 11)
  ret i32 %r
}

; PR20750 - https://bugs.llvm.org/show_bug.cgi?id=20750
; This IR corresponds to C source where the shift amount is a smaller type than the rotated value:
; unsigned int rotate32_doubleand1(unsigned int v, unsigned char r) { r = r & 31; return (v << r) | (v >> (((32 - r)) & 31)); }

define i32 @rotateleft32_doubleand1(i32 %v, i8 %r) {
; CHECK-LABEL: @rotateleft32_doubleand1(
; CHECK-NEXT:    [[Z:%.*]] = zext i8 [[R:%.*]] to i32
; CHECK-NEXT:    [[OR:%.*]] = call i32 @llvm.fshl.i32(i32 [[V:%.*]], i32 [[V]], i32 [[Z]])
; CHECK-NEXT:    ret i32 [[OR]]
;
  %m = and i8 %r, 31
  %z = zext i8 %m to i32
  %neg = sub nsw i32 0, %z
  %and2 = and i32 %neg, 31
  %shl = shl i32 %v, %z
  %shr = lshr i32 %v, %and2
  %or = or i32 %shr, %shl
  ret i32 %or
}

define i32 @rotateright32_doubleand1(i32 %v, i16 %r) {
; CHECK-LABEL: @rotateright32_doubleand1(
; CHECK-NEXT:    [[Z:%.*]] = zext i16 [[R:%.*]] to i32
; CHECK-NEXT:    [[OR:%.*]] = call i32 @llvm.fshr.i32(i32 [[V:%.*]], i32 [[V]], i32 [[Z]])
; CHECK-NEXT:    ret i32 [[OR]]
;
  %m = and i16 %r, 31
  %z = zext i16 %m to i32
  %neg = sub nsw i32 0, %z
  %and2 = and i32 %neg, 31
  %shl = shl i32 %v, %and2
  %shr = lshr i32 %v, %z
  %or = or i32 %shr, %shl
  ret i32 %or
}
