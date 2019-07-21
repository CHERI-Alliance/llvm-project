; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -instcombine -S | FileCheck %s

define i64 @rem_signed(i64 %x1, i64 %y2) {
; CHECK-LABEL: @rem_signed(
; CHECK-NEXT:    [[TMP1:%.*]] = srem i64 [[X1:%.*]], [[Y2:%.*]]
; CHECK-NEXT:    ret i64 [[TMP1]]
;
  %r = sdiv i64 %x1, %y2
  %r7 = mul i64 %r, %y2
  %r8 = sub i64 %x1, %r7
  ret i64 %r8
}

define <4 x i32> @rem_signed_vec(<4 x i32> %t, <4 x i32> %u) {
; CHECK-LABEL: @rem_signed_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = srem <4 x i32> [[T:%.*]], [[U:%.*]]
; CHECK-NEXT:    ret <4 x i32> [[TMP1]]
;
  %k = sdiv <4 x i32> %t, %u
  %l = mul <4 x i32> %k, %u
  %m = sub <4 x i32> %t, %l
  ret <4 x i32> %m
}

define i64 @rem_unsigned(i64 %x1, i64 %y2) {
; CHECK-LABEL: @rem_unsigned(
; CHECK-NEXT:    [[TMP1:%.*]] = urem i64 [[X1:%.*]], [[Y2:%.*]]
; CHECK-NEXT:    ret i64 [[TMP1]]
;
  %r = udiv i64 %x1, %y2
  %r7 = mul i64 %r, %y2
  %r8 = sub i64 %x1, %r7
  ret i64 %r8
}

; PR28672 - https://llvm.org/bugs/show_bug.cgi?id=28672

define i8 @big_divisor(i8 %x) {
; CHECK-LABEL: @big_divisor(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ult i8 [[X:%.*]], -127
; CHECK-NEXT:    [[TMP2:%.*]] = add i8 [[X]], 127
; CHECK-NEXT:    [[REM:%.*]] = select i1 [[TMP1]], i8 [[X]], i8 [[TMP2]]
; CHECK-NEXT:    ret i8 [[REM]]
;
  %rem = urem i8 %x, 129
  ret i8 %rem
}

define i5 @biggest_divisor(i5 %x) {
; CHECK-LABEL: @biggest_divisor(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i5 [[X:%.*]], -1
; CHECK-NEXT:    [[TMP2:%.*]] = zext i1 [[TMP1]] to i5
; CHECK-NEXT:    [[REM:%.*]] = add i5 [[TMP2]], [[X]]
; CHECK-NEXT:    ret i5 [[REM]]
;
  %rem = urem i5 %x, -1
  ret i5 %rem
}

define i8 @urem_with_sext_bool_divisor(i1 %x, i8 %y) {
; CHECK-LABEL: @urem_with_sext_bool_divisor(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq i8 [[Y:%.*]], -1
; CHECK-NEXT:    [[REM:%.*]] = select i1 [[TMP1]], i8 0, i8 [[Y]]
; CHECK-NEXT:    ret i8 [[REM]]
;
  %s = sext i1 %x to i8
  %rem = urem i8 %y, %s
  ret i8 %rem
}

define <2 x i8> @urem_with_sext_bool_divisor_vec(<2 x i1> %x, <2 x i8> %y) {
; CHECK-LABEL: @urem_with_sext_bool_divisor_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp eq <2 x i8> [[Y:%.*]], <i8 -1, i8 -1>
; CHECK-NEXT:    [[REM:%.*]] = select <2 x i1> [[TMP1]], <2 x i8> zeroinitializer, <2 x i8> [[Y]]
; CHECK-NEXT:    ret <2 x i8> [[REM]]
;
  %s = sext <2 x i1> %x to <2 x i8>
  %rem = urem <2 x i8> %y, %s
  ret <2 x i8> %rem
}

define <2 x i4> @big_divisor_vec(<2 x i4> %x) {
; CHECK-LABEL: @big_divisor_vec(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ult <2 x i4> [[X:%.*]], <i4 -3, i4 -3>
; CHECK-NEXT:    [[TMP2:%.*]] = add <2 x i4> [[X]], <i4 3, i4 3>
; CHECK-NEXT:    [[REM:%.*]] = select <2 x i1> [[TMP1]], <2 x i4> [[X]], <2 x i4> [[TMP2]]
; CHECK-NEXT:    ret <2 x i4> [[REM]]
;
  %rem = urem <2 x i4> %x, <i4 13, i4 13>
  ret <2 x i4> %rem
}

define i8 @urem1(i8 %x, i8 %y) {
; CHECK-LABEL: @urem1(
; CHECK-NEXT:    [[TMP1:%.*]] = urem i8 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i8 [[TMP1]]
;
  %A = udiv i8 %x, %y
  %B = mul i8 %A, %y
  %C = sub i8 %x, %B
  ret i8 %C
}

define i8 @srem1(i8 %x, i8 %y) {
; CHECK-LABEL: @srem1(
; CHECK-NEXT:    [[TMP1:%.*]] = srem i8 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i8 [[TMP1]]
;
  %A = sdiv i8 %x, %y
  %B = mul i8 %A, %y
  %C = sub i8 %x, %B
  ret i8 %C
}

define i8 @urem2(i8 %x, i8 %y) {
; CHECK-LABEL: @urem2(
; CHECK-NEXT:    [[TMP1:%.*]] = urem i8 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = sub i8 0, [[TMP1]]
; CHECK-NEXT:    ret i8 [[C]]
;
  %A = udiv i8 %x, %y
  %B = mul i8 %A, %y
  %C = sub i8 %B, %x
  ret i8 %C
}

define i8 @urem3(i8 %x) {
; CHECK-LABEL: @urem3(
; CHECK-NEXT:    [[TMP1:%.*]] = urem i8 [[X:%.*]], 3
; CHECK-NEXT:    [[B1:%.*]] = sub i8 [[X]], [[TMP1]]
; CHECK-NEXT:    [[C:%.*]] = add i8 [[B1]], [[X]]
; CHECK-NEXT:    ret i8 [[C]]
;
  %A = udiv i8 %x, 3
  %B = mul i8 %A, -3
  %C = sub i8 %x, %B
  ret i8 %C
}

; (((X / Y) * Y) / Y) -> X / Y

define i32 @sdiv_mul_sdiv(i32 %x, i32 %y) {
; CHECK-LABEL: @sdiv_mul_sdiv(
; CHECK-NEXT:    [[R:%.*]] = sdiv i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %div = sdiv i32 %x, %y
  %mul = mul i32 %div, %y
  %r = sdiv i32 %mul, %y
  ret i32 %r
}

; (((X / Y) * Y) / Y) -> X / Y

define i32 @udiv_mul_udiv(i32 %x, i32 %y) {
; CHECK-LABEL: @udiv_mul_udiv(
; CHECK-NEXT:    [[R:%.*]] = udiv i32 [[X:%.*]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %div = udiv i32 %x, %y
  %mul = mul i32 %div, %y
  %r = udiv i32 %mul, %y
  ret i32 %r
}

define i32 @test1(i32 %A) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    ret i32 0
;
  %B = srem i32 %A, 1	; ISA constant 0
  ret i32 %B
}

define i32 @test3(i32 %A) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    [[B:%.*]] = and i32 [[A:%.*]], 7
; CHECK-NEXT:    ret i32 [[B]]
;
  %B = urem i32 %A, 8
  ret i32 %B
}

define <2 x i32> @vec_power_of_2_constant_splat_divisor(<2 x i32> %A) {
; CHECK-LABEL: @vec_power_of_2_constant_splat_divisor(
; CHECK-NEXT:    [[B:%.*]] = and <2 x i32> [[A:%.*]], <i32 7, i32 7>
; CHECK-NEXT:    ret <2 x i32> [[B]]
;
  %B = urem <2 x i32> %A, <i32 8, i32 8>
  ret <2 x i32> %B
}

define <2 x i19> @weird_vec_power_of_2_constant_splat_divisor(<2 x i19> %A) {
; CHECK-LABEL: @weird_vec_power_of_2_constant_splat_divisor(
; CHECK-NEXT:    [[B:%.*]] = and <2 x i19> [[A:%.*]], <i19 7, i19 7>
; CHECK-NEXT:    ret <2 x i19> [[B]]
;
  %B = urem <2 x i19> %A, <i19 8, i19 8>
  ret <2 x i19> %B
}

define i1 @test3a(i32 %A) {
; CHECK-LABEL: @test3a(
; CHECK-NEXT:    [[B1:%.*]] = and i32 [[A:%.*]], 7
; CHECK-NEXT:    [[C:%.*]] = icmp ne i32 [[B1]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = srem i32 %A, -8
  %C = icmp ne i32 %B, 0
  ret i1 %C
}

define <2 x i1> @test3a_vec(<2 x i32> %A) {
; CHECK-LABEL: @test3a_vec(
; CHECK-NEXT:    [[B1:%.*]] = and <2 x i32> [[A:%.*]], <i32 7, i32 7>
; CHECK-NEXT:    [[C:%.*]] = icmp ne <2 x i32> [[B1]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %B = srem <2 x i32> %A, <i32 -8, i32 -8>
  %C = icmp ne <2 x i32> %B, zeroinitializer
  ret <2 x i1> %C
}

define i32 @test4(i32 %X, i1 %C) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[TMP1:%.*]] = select i1 [[C:%.*]], i32 0, i32 7
; CHECK-NEXT:    [[R:%.*]] = and i32 [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret i32 [[R]]
;
  %V = select i1 %C, i32 1, i32 8
  %R = urem i32 %X, %V
  ret i32 %R
}

define i32 @test5(i32 %X, i8 %B) {
; CHECK-LABEL: @test5(
; CHECK-NEXT:    [[SHIFT_UPGRD_1:%.*]] = zext i8 [[B:%.*]] to i32
; CHECK-NEXT:    [[AMT:%.*]] = shl nuw i32 32, [[SHIFT_UPGRD_1]]
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[AMT]], -1
; CHECK-NEXT:    [[V:%.*]] = and i32 [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret i32 [[V]]
;
  %shift.upgrd.1 = zext i8 %B to i32
  %Amt = shl i32 32, %shift.upgrd.1
  %V = urem i32 %X, %Amt
  ret i32 %V
}

define i32 @test6(i32 %A) {
; CHECK-LABEL: @test6(
; CHECK-NEXT:    ret i32 undef
;
  %B = srem i32 %A, 0	;; undef
  ret i32 %B
}

define i32 @test7(i32 %A) {
; CHECK-LABEL: @test7(
; CHECK-NEXT:    ret i32 0
;
  %B = mul i32 %A, 8
  %C = srem i32 %B, 4
  ret i32 %C
}

define i32 @test8(i32 %A) {
; CHECK-LABEL: @test8(
; CHECK-NEXT:    ret i32 0
;
  %B = shl i32 %A, 4
  %C = srem i32 %B, 8
  ret i32 %C
}

define i32 @test9(i32 %A) {
; CHECK-LABEL: @test9(
; CHECK-NEXT:    ret i32 0
;
  %B = mul i32 %A, 64
  %C = urem i32 %B, 32
  ret i32 %C
}

define i32 @test10(i8 %c) {
; CHECK-LABEL: @test10(
; CHECK-NEXT:    ret i32 0
;
  %tmp.1 = zext i8 %c to i32
  %tmp.2 = mul i32 %tmp.1, 4
  %tmp.3 = sext i32 %tmp.2 to i64
  %tmp.5 = urem i64 %tmp.3, 4
  %tmp.6 = trunc i64 %tmp.5 to i32
  ret i32 %tmp.6
}

define i32 @test11(i32 %i) {
; CHECK-LABEL: @test11(
; CHECK-NEXT:    ret i32 0
;
  %tmp.1 = and i32 %i, -2
  %tmp.3 = mul i32 %tmp.1, 2
  %tmp.5 = urem i32 %tmp.3, 4
  ret i32 %tmp.5
}

define i32 @test12(i32 %i) {
; CHECK-LABEL: @test12(
; CHECK-NEXT:    ret i32 0
;
  %tmp.1 = and i32 %i, -4
  %tmp.5 = srem i32 %tmp.1, 2
  ret i32 %tmp.5
}

define i32 @test13(i32 %i) {
; CHECK-LABEL: @test13(
; CHECK-NEXT:    ret i32 0
;
  %x = srem i32 %i, %i
  ret i32 %x
}

define i64 @test14(i64 %x, i32 %y) {
; CHECK-LABEL: @test14(
; CHECK-NEXT:    [[SHL:%.*]] = shl i32 1, [[Y:%.*]]
; CHECK-NEXT:    [[ZEXT:%.*]] = zext i32 [[SHL]] to i64
; CHECK-NEXT:    [[TMP1:%.*]] = add nsw i64 [[ZEXT]], -1
; CHECK-NEXT:    [[UREM:%.*]] = and i64 [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret i64 [[UREM]]
;
  %shl = shl i32 1, %y
  %zext = zext i32 %shl to i64
  %urem = urem i64 %x, %zext
  ret i64 %urem
}

define i64 @test15(i32 %x, i32 %y) {
; CHECK-LABEL: @test15(
; CHECK-NEXT:    [[NOTMASK:%.*]] = shl nsw i32 -1, [[Y:%.*]]
; CHECK-NEXT:    [[TMP1:%.*]] = xor i32 [[NOTMASK]], -1
; CHECK-NEXT:    [[TMP2:%.*]] = and i32 [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    [[UREM:%.*]] = zext i32 [[TMP2]] to i64
; CHECK-NEXT:    ret i64 [[UREM]]
;
  %shl = shl i32 1, %y
  %zext0 = zext i32 %shl to i64
  %zext1 = zext i32 %x to i64
  %urem = urem i64 %zext1, %zext0
  ret i64 %urem
}

define i32 @test16(i32 %x, i32 %y) {
; CHECK-LABEL: @test16(
; CHECK-NEXT:    [[SHR:%.*]] = lshr i32 [[Y:%.*]], 11
; CHECK-NEXT:    [[AND:%.*]] = and i32 [[SHR]], 4
; CHECK-NEXT:    [[TMP1:%.*]] = or i32 [[AND]], 3
; CHECK-NEXT:    [[REM:%.*]] = and i32 [[TMP1]], [[X:%.*]]
; CHECK-NEXT:    ret i32 [[REM]]
;
  %shr = lshr i32 %y, 11
  %and = and i32 %shr, 4
  %add = add i32 %and, 4
  %rem = urem i32 %x, %add
  ret i32 %rem
}

define i32 @test17(i32 %X) {
; CHECK-LABEL: @test17(
; CHECK-NEXT:    [[TMP1:%.*]] = icmp ne i32 [[X:%.*]], 1
; CHECK-NEXT:    [[A:%.*]] = zext i1 [[TMP1]] to i32
; CHECK-NEXT:    ret i32 [[A]]
;
  %A = urem i32 1, %X
  ret i32 %A
}

define i32 @test18(i16 %x, i32 %y) {
; CHECK-LABEL: @test18(
; CHECK-NEXT:    [[TMP1:%.*]] = and i16 [[X:%.*]], 4
; CHECK-NEXT:    [[TMP2:%.*]] = icmp eq i16 [[TMP1]], 0
; CHECK-NEXT:    [[TMP3:%.*]] = select i1 [[TMP2]], i32 63, i32 31
; CHECK-NEXT:    [[TMP4:%.*]] = and i32 [[TMP3]], [[Y:%.*]]
; CHECK-NEXT:    ret i32 [[TMP4]]
;
  %1 = and i16 %x, 4
  %2 = icmp ne i16 %1, 0
  %3 = select i1 %2, i32 32, i32 64
  %4 = urem i32 %y, %3
  ret i32 %4
}

define i32 @test19(i32 %x, i32 %y) {
; CHECK-LABEL: @test19(
; CHECK-NEXT:    [[A:%.*]] = shl i32 1, [[X:%.*]]
; CHECK-NEXT:    [[B:%.*]] = shl i32 1, [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = and i32 [[A]], [[B]]
; CHECK-NEXT:    [[D:%.*]] = add i32 [[C]], [[A]]
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[D]], -1
; CHECK-NEXT:    [[E:%.*]] = and i32 [[TMP1]], [[Y]]
; CHECK-NEXT:    ret i32 [[E]]
;
  %A = shl i32 1, %x
  %B = shl i32 1, %y
  %C = and i32 %A, %B
  %D = add i32 %C, %A
  %E = urem i32 %y, %D
  ret i32 %E
}

define i32 @test19_commutative0(i32 %x, i32 %y) {
; CHECK-LABEL: @test19_commutative0(
; CHECK-NEXT:    [[A:%.*]] = shl i32 1, [[X:%.*]]
; CHECK-NEXT:    [[B:%.*]] = shl i32 1, [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = and i32 [[B]], [[A]]
; CHECK-NEXT:    [[D:%.*]] = add i32 [[C]], [[A]]
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[D]], -1
; CHECK-NEXT:    [[E:%.*]] = and i32 [[TMP1]], [[Y]]
; CHECK-NEXT:    ret i32 [[E]]
;
  %A = shl i32 1, %x
  %B = shl i32 1, %y
  %C = and i32 %B, %A ; swapped
  %D = add i32 %C, %A
  %E = urem i32 %y, %D
  ret i32 %E
}

define i32 @test19_commutative1(i32 %x, i32 %y) {
; CHECK-LABEL: @test19_commutative1(
; CHECK-NEXT:    [[A:%.*]] = shl i32 1, [[X:%.*]]
; CHECK-NEXT:    [[B:%.*]] = shl i32 1, [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = and i32 [[A]], [[B]]
; CHECK-NEXT:    [[D:%.*]] = add i32 [[A]], [[C]]
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[D]], -1
; CHECK-NEXT:    [[E:%.*]] = and i32 [[TMP1]], [[Y]]
; CHECK-NEXT:    ret i32 [[E]]
;
  %A = shl i32 1, %x
  %B = shl i32 1, %y
  %C = and i32 %A, %B
  %D = add i32 %A, %C ; swapped
  %E = urem i32 %y, %D
  ret i32 %E
}

define i32 @test19_commutative2(i32 %x, i32 %y) {
; CHECK-LABEL: @test19_commutative2(
; CHECK-NEXT:    [[A:%.*]] = shl i32 1, [[X:%.*]]
; CHECK-NEXT:    [[B:%.*]] = shl i32 1, [[Y:%.*]]
; CHECK-NEXT:    [[C:%.*]] = and i32 [[B]], [[A]]
; CHECK-NEXT:    [[D:%.*]] = add i32 [[A]], [[C]]
; CHECK-NEXT:    [[TMP1:%.*]] = add i32 [[D]], -1
; CHECK-NEXT:    [[E:%.*]] = and i32 [[TMP1]], [[Y]]
; CHECK-NEXT:    ret i32 [[E]]
;
  %A = shl i32 1, %x
  %B = shl i32 1, %y
  %C = and i32 %B, %A ; swapped
  %D = add i32 %A, %C ; swapped
  %E = urem i32 %y, %D
  ret i32 %E
}

define <2 x i64> @test20(<2 x i64> %X, <2 x i1> %C) {
; CHECK-LABEL: @test20(
; CHECK-NEXT:    [[R:%.*]] = select <2 x i1> [[C:%.*]], <2 x i64> <i64 1, i64 2>, <2 x i64> zeroinitializer
; CHECK-NEXT:    ret <2 x i64> [[R]]
;
  %V = select <2 x i1> %C, <2 x i64> <i64 1, i64 2>, <2 x i64> <i64 8, i64 9>
  %R = urem <2 x i64> %V, <i64 2, i64 3>
  ret <2 x i64> %R
}

define i32 @test21(i1 %c0, i32* %p) {
; CHECK-LABEL: @test21(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C0:%.*]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[V:%.*]] = load volatile i32, i32* [[P:%.*]], align 4
; CHECK-NEXT:    [[PHITMP:%.*]] = srem i32 [[V]], 5
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    [[LHS:%.*]] = phi i32 [ [[PHITMP]], [[IF_THEN]] ], [ 0, [[ENTRY:%.*]] ]
; CHECK-NEXT:    ret i32 [[LHS]]
;
entry:
  br i1 %c0, label %if.then, label %if.end

if.then:
  %v = load volatile i32, i32* %p
  br label %if.end

if.end:
  %lhs = phi i32 [ %v, %if.then ], [ 5, %entry ]
  %rem = srem i32 %lhs, 5
  ret i32 %rem
}

@a = common global [5 x i16] zeroinitializer, align 2
@b = common global i16 0, align 2

define i32 @pr27968_0(i1 %c0, i32* %p) {
; CHECK-LABEL: @pr27968_0(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C0:%.*]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[V:%.*]] = load volatile i32, i32* [[P:%.*]], align 4
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    br i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b), label [[REM_IS_SAFE:%.*]], label [[REM_IS_UNSAFE:%.*]]
; CHECK:       rem.is.safe:
; CHECK-NEXT:    ret i32 0
; CHECK:       rem.is.unsafe:
; CHECK-NEXT:    ret i32 0
;
entry:
  br i1 %c0, label %if.then, label %if.end

if.then:
  %v = load volatile i32, i32* %p
  br label %if.end

if.end:
  %lhs = phi i32 [ %v, %if.then ], [ 5, %entry ]
  br i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b), label %rem.is.safe, label %rem.is.unsafe

rem.is.safe:
  %rem = srem i32 %lhs, zext (i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b) to i32)
  ret i32 %rem

rem.is.unsafe:
  ret i32 0
}

define i32 @pr27968_1(i1 %c0, i1 %always_false, i32* %p) {
; CHECK-LABEL: @pr27968_1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C0:%.*]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[V:%.*]] = load volatile i32, i32* [[P:%.*]], align 4
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    [[LHS:%.*]] = phi i32 [ [[V]], [[IF_THEN]] ], [ 5, [[ENTRY:%.*]] ]
; CHECK-NEXT:    br i1 [[ALWAYS_FALSE:%.*]], label [[REM_IS_SAFE:%.*]], label [[REM_IS_UNSAFE:%.*]]
; CHECK:       rem.is.safe:
; CHECK-NEXT:    [[REM:%.*]] = srem i32 [[LHS]], -2147483648
; CHECK-NEXT:    ret i32 [[REM]]
; CHECK:       rem.is.unsafe:
; CHECK-NEXT:    ret i32 0
;
entry:
  br i1 %c0, label %if.then, label %if.end

if.then:
  %v = load volatile i32, i32* %p
  br label %if.end

if.end:
  %lhs = phi i32 [ %v, %if.then ], [ 5, %entry ]
  br i1 %always_false, label %rem.is.safe, label %rem.is.unsafe

rem.is.safe:
  %rem = srem i32 %lhs, -2147483648
  ret i32 %rem

rem.is.unsafe:
  ret i32 0
}

define i32 @pr27968_2(i1 %c0, i32* %p) {
; CHECK-LABEL: @pr27968_2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C0:%.*]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[V:%.*]] = load volatile i32, i32* [[P:%.*]], align 4
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    br i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b), label [[REM_IS_SAFE:%.*]], label [[REM_IS_UNSAFE:%.*]]
; CHECK:       rem.is.safe:
; CHECK-NEXT:    ret i32 0
; CHECK:       rem.is.unsafe:
; CHECK-NEXT:    ret i32 0
;
entry:
  br i1 %c0, label %if.then, label %if.end

if.then:
  %v = load volatile i32, i32* %p
  br label %if.end

if.end:
  %lhs = phi i32 [ %v, %if.then ], [ 5, %entry ]
  br i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b), label %rem.is.safe, label %rem.is.unsafe

rem.is.safe:
  %rem = urem i32 %lhs, zext (i1 icmp eq (i16* getelementptr inbounds ([5 x i16], [5 x i16]* @a, i64 0, i64 4), i16* @b) to i32)
  ret i32 %rem

rem.is.unsafe:
  ret i32 0
}

define i32 @pr27968_3(i1 %c0, i1 %always_false, i32* %p) {
; CHECK-LABEL: @pr27968_3(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[C0:%.*]], label [[IF_THEN:%.*]], label [[IF_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[V:%.*]] = load volatile i32, i32* [[P:%.*]], align 4
; CHECK-NEXT:    [[PHITMP:%.*]] = and i32 [[V]], 2147483647
; CHECK-NEXT:    br label [[IF_END]]
; CHECK:       if.end:
; CHECK-NEXT:    [[LHS:%.*]] = phi i32 [ [[PHITMP]], [[IF_THEN]] ], [ 5, [[ENTRY:%.*]] ]
; CHECK-NEXT:    br i1 [[ALWAYS_FALSE:%.*]], label [[REM_IS_SAFE:%.*]], label [[REM_IS_UNSAFE:%.*]]
; CHECK:       rem.is.safe:
; CHECK-NEXT:    ret i32 [[LHS]]
; CHECK:       rem.is.unsafe:
; CHECK-NEXT:    ret i32 0
;
entry:
  br i1 %c0, label %if.then, label %if.end

if.then:
  %v = load volatile i32, i32* %p
  br label %if.end

if.end:
  %lhs = phi i32 [ %v, %if.then ], [ 5, %entry ]
  br i1 %always_false, label %rem.is.safe, label %rem.is.unsafe

rem.is.safe:
  %rem = urem i32 %lhs, -2147483648
  ret i32 %rem

rem.is.unsafe:
  ret i32 0
}

define i32 @test22(i32 %A) {
; CHECK-LABEL: @test22(
; CHECK-NEXT:    [[AND:%.*]] = and i32 [[A:%.*]], 2147483647
; CHECK-NEXT:    [[MUL:%.*]] = urem i32 [[AND]], 2147483647
; CHECK-NEXT:    ret i32 [[MUL]]
;
  %and = and i32 %A, 2147483647
  %mul = srem i32 %and, 2147483647
  ret i32 %mul
}

define <2 x i32> @test23(<2 x i32> %A) {
; CHECK-LABEL: @test23(
; CHECK-NEXT:    [[AND:%.*]] = and <2 x i32> [[A:%.*]], <i32 2147483647, i32 2147483647>
; CHECK-NEXT:    [[MUL:%.*]] = urem <2 x i32> [[AND]], <i32 2147483647, i32 2147483647>
; CHECK-NEXT:    ret <2 x i32> [[MUL]]
;
  %and = and <2 x i32> %A, <i32 2147483647, i32 2147483647>
  %mul = srem <2 x i32> %and, <i32 2147483647, i32 2147483647>
  ret <2 x i32> %mul
}

define i1 @test24(i32 %A) {
; CHECK-LABEL: @test24(
; CHECK-NEXT:    [[B:%.*]] = and i32 [[A:%.*]], 2147483647
; CHECK-NEXT:    [[C:%.*]] = icmp ne i32 [[B]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = urem i32 %A, 2147483648 ; signbit
  %C = icmp ne i32 %B, 0
  ret i1 %C
}

define <2 x i1> @test24_vec(<2 x i32> %A) {
; CHECK-LABEL: @test24_vec(
; CHECK-NEXT:    [[B:%.*]] = and <2 x i32> [[A:%.*]], <i32 2147483647, i32 2147483647>
; CHECK-NEXT:    [[C:%.*]] = icmp ne <2 x i32> [[B]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %B = urem <2 x i32> %A, <i32 2147483648, i32 2147483648>
  %C = icmp ne <2 x i32> %B, zeroinitializer
  ret <2 x i1> %C
}

define i1 @test25(i32 %A) {
; CHECK-LABEL: @test25(
; CHECK-NEXT:    [[B:%.*]] = srem i32 [[A:%.*]], -2147483648
; CHECK-NEXT:    [[C:%.*]] = icmp ne i32 [[B]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = srem i32 %A, 2147483648 ; signbit
  %C = icmp ne i32 %B, 0
  ret i1 %C
}

define <2 x i1> @test25_vec(<2 x i32> %A) {
; CHECK-LABEL: @test25_vec(
; CHECK-NEXT:    [[B:%.*]] = srem <2 x i32> [[A:%.*]], <i32 -2147483648, i32 -2147483648>
; CHECK-NEXT:    [[C:%.*]] = icmp ne <2 x i32> [[B]], zeroinitializer
; CHECK-NEXT:    ret <2 x i1> [[C]]
;
  %B = srem <2 x i32> %A, <i32 2147483648, i32 2147483648>
  %C = icmp ne <2 x i32> %B, zeroinitializer
  ret <2 x i1> %C
}

define i1 @test26(i32 %A, i32 %B) {
; CHECK-LABEL: @test26(
; CHECK-NEXT:    [[C:%.*]] = shl nuw i32 1, [[B:%.*]]
; CHECK-NEXT:    [[D:%.*]] = srem i32 [[A:%.*]], [[C]]
; CHECK-NEXT:    [[E:%.*]] = icmp ne i32 [[D]], 0
; CHECK-NEXT:    ret i1 [[E]]
;
  %C = shl i32 1, %B ; not a constant
  %D = srem i32 %A, %C
  %E = icmp ne i32 %D, 0
  ret i1 %E
}

define i1 @test27(i32 %A, i32* %remdst) {
; CHECK-LABEL: @test27(
; CHECK-NEXT:    [[B:%.*]] = srem i32 [[A:%.*]], -2147483648
; CHECK-NEXT:    store i32 [[B]], i32* [[REMDST:%.*]], align 1
; CHECK-NEXT:    [[C:%.*]] = icmp ne i32 [[B]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = srem i32 %A, 2147483648 ; signbit
  store i32 %B, i32* %remdst, align 1 ; extra use of rem
  %C = icmp ne i32 %B, 0
  ret i1 %C
}

define i1 @test28(i32 %A) {
; CHECK-LABEL: @test28(
; CHECK-NEXT:    [[B:%.*]] = srem i32 [[A:%.*]], -2147483648
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[B]], 0
; CHECK-NEXT:    ret i1 [[C]]
;
  %B = srem i32 %A, 2147483648 ; signbit
  %C = icmp eq i32 %B, 0 ; another equality predicate
  ret i1 %C
}

; FP division-by-zero is not UB.

define double @PR34870(i1 %cond, double %x, double %y) {
; CHECK-LABEL: @PR34870(
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[COND:%.*]], double [[Y:%.*]], double 0.000000e+00
; CHECK-NEXT:    [[FMOD:%.*]] = frem double [[X:%.*]], [[SEL]]
; CHECK-NEXT:    ret double [[FMOD]]
;
  %sel = select i1 %cond, double %y, double 0.0
  %fmod = frem double %x, %sel
  ret double %fmod
}

