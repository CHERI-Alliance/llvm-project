; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -correlated-propagation -cvp-dont-add-nowrap-flags=false -S | FileCheck %s

define void @test0(i32 %a) {
; CHECK-LABEL: @test0(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[A:%.*]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp sgt i32 %a, 100
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

define void @test1(i32 %a) {
; CHECK-LABEL: @test1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i32 [[A:%.*]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp ugt i32 %a, 100
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

define void @test2(i32 %a) {
; CHECK-LABEL: @test2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i32 [[A:%.*]], -1
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp ugt i32 %a, -1
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

define void @test3(i32 %a) {
; CHECK-LABEL: @test3(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[A:%.*]], -1
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp sgt i32 %a, -1
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

define void @test4(i32 %a) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i32 [[A:%.*]], 2147483647
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp ugt i32 %a, 2147483647
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

define void @test5(i32 %a) {
; CHECK-LABEL: @test5(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp sle i32 [[A:%.*]], 2147483647
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp sle i32 %a, 2147483647
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check for a corner case where an integer value is represented with a constant
; LVILatticeValue instead of constantrange. Check that we don't fail with an
; assertion in this case.
@b = global i32 0, align 4
define void @test6(i32 %a) {
; CHECK-LABEL: @test6(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 [[A:%.*]], ptrtoint (i32* @b to i32)
; CHECK-NEXT:    ret void
;
bb:
  %sub = sub i32 %a, ptrtoint (i32* @b to i32)
  ret void
}

; Check that we can gather information for conditions in the form of
;   and ( i s< 100, Unknown )
define void @test7(i32 %a, i1 %flag) {
; CHECK-LABEL: @test7(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp ugt i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP:%.*]] = and i1 [[CMP_1]], [[FLAG:%.*]]
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp ugt i32 %a, 100
  %cmp = and i1 %cmp.1, %flag
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions in the form of
;   and ( i s< 100, i s> 0 )
define void @test8(i32 %a) {
; CHECK-LABEL: @test8(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp slt i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sgt i32 [[A]], 0
; CHECK-NEXT:    [[CMP:%.*]] = and i1 [[CMP_1]], [[CMP_2]]
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp slt i32 %a, 100
  %cmp.2 = icmp sgt i32 %a, 0
  %cmp = and i1 %cmp.1, %cmp.2
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that for conditions in the form of cond1 && cond2 we don't mistakenly
; assume that !cond1 && !cond2 holds down to false path.
define void @test8_neg(i32 %a) {
; CHECK-LABEL: @test8_neg(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sge i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sle i32 [[A]], 0
; CHECK-NEXT:    [[CMP:%.*]] = and i1 [[CMP_1]], [[CMP_2]]
; CHECK-NEXT:    br i1 [[CMP]], label [[EXIT:%.*]], label [[BB:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sge i32 %a, 100
  %cmp.2 = icmp sle i32 %a, 0
  %cmp = and i1 %cmp.1, %cmp.2
  br i1 %cmp, label %exit, label %bb

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions in the form of
;   and ( i s< 100, and (i s> 0, Unknown )
define void @test9(i32 %a, i1 %flag) {
; CHECK-LABEL: @test9(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp slt i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sgt i32 [[A]], 0
; CHECK-NEXT:    [[CMP_3:%.*]] = and i1 [[CMP_2]], [[FLAG:%.*]]
; CHECK-NEXT:    [[CMP:%.*]] = and i1 [[CMP_1]], [[CMP_3]]
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp slt i32 %a, 100
  %cmp.2 = icmp sgt i32 %a, 0
  %cmp.3 = and i1 %cmp.2, %flag
  %cmp = and i1 %cmp.1, %cmp.3
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions in the form of
;   and ( i s> Unknown, ... )
define void @test10(i32 %a, i32 %b, i1 %flag) {
; CHECK-LABEL: @test10(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sgt i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[CMP:%.*]] = and i1 [[CMP_1]], [[FLAG:%.*]]
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sgt i32 %a, %b
  %cmp = and i1 %cmp.1, %flag
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

@limit = external global i32
define i32 @test11(i32* %p, i32 %i) {
; CHECK-LABEL: @test11(
; CHECK-NEXT:    [[LIMIT:%.*]] = load i32, i32* [[P:%.*]], !range !0
; CHECK-NEXT:    [[WITHIN_1:%.*]] = icmp slt i32 [[LIMIT]], [[I:%.*]]
; CHECK-NEXT:    [[I_MINUS_7:%.*]] = add i32 [[I]], -7
; CHECK-NEXT:    [[WITHIN_2:%.*]] = icmp slt i32 [[LIMIT]], [[I_MINUS_7]]
; CHECK-NEXT:    [[WITHIN:%.*]] = and i1 [[WITHIN_1]], [[WITHIN_2]]
; CHECK-NEXT:    br i1 [[WITHIN]], label [[THEN:%.*]], label [[ELSE:%.*]]
; CHECK:       then:
; CHECK-NEXT:    [[I_MINUS_6:%.*]] = sub nuw nsw i32 [[I]], 6
; CHECK-NEXT:    ret i32 [[I_MINUS_6]]
; CHECK:       else:
; CHECK-NEXT:    ret i32 0
;
  %limit = load i32, i32* %p, !range !{i32 0, i32 2147483647}
  %within.1 = icmp slt i32 %limit, %i
  %i.minus.7 = add i32 %i, -7
  %within.2 = icmp slt i32 %limit, %i.minus.7
  %within = and i1 %within.1, %within.2
  br i1 %within, label %then, label %else

then:
  %i.minus.6 = sub i32 %i, 6
  ret i32 %i.minus.6

else:
  ret i32 0
}

; Check that we can gather information for conditions is the form of
;   or ( i s<= -100, Unknown )
define void @test12(i32 %a, i1 %flag) {
; CHECK-LABEL: @test12(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sle i32 [[A:%.*]], -100
; CHECK-NEXT:    [[CMP:%.*]] = or i1 [[CMP_1]], [[FLAG:%.*]]
; CHECK-NEXT:    br i1 [[CMP]], label [[EXIT:%.*]], label [[BB:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sle i32 %a, -100
  %cmp = or i1 %cmp.1, %flag
  br i1 %cmp, label %exit, label %bb

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions is the form of
;   or ( i s>= 100, i s<= 0 )
define void @test13(i32 %a) {
; CHECK-LABEL: @test13(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sge i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sle i32 [[A]], 0
; CHECK-NEXT:    [[CMP:%.*]] = or i1 [[CMP_1]], [[CMP_2]]
; CHECK-NEXT:    br i1 [[CMP]], label [[EXIT:%.*]], label [[BB:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sge i32 %a, 100
  %cmp.2 = icmp sle i32 %a, 0
  %cmp = or i1 %cmp.1, %cmp.2
  br i1 %cmp, label %exit, label %bb

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that for conditions is the form of cond1 || cond2 we don't mistakenly
; assume that cond1 || cond2 holds down to true path.
define void @test13_neg(i32 %a) {
; CHECK-LABEL: @test13_neg(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp slt i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sgt i32 [[A]], 0
; CHECK-NEXT:    [[CMP:%.*]] = or i1 [[CMP_1]], [[CMP_2]]
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp slt i32 %a, 100
  %cmp.2 = icmp sgt i32 %a, 0
  %cmp = or i1 %cmp.1, %cmp.2
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions is the form of
;   or ( i s>=100, or (i s<= 0, Unknown )
define void @test14(i32 %a, i1 %flag) {
; CHECK-LABEL: @test14(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sge i32 [[A:%.*]], 100
; CHECK-NEXT:    [[CMP_2:%.*]] = icmp sle i32 [[A]], 0
; CHECK-NEXT:    [[CMP_3:%.*]] = or i1 [[CMP_2]], [[FLAG:%.*]]
; CHECK-NEXT:    [[CMP:%.*]] = or i1 [[CMP_1]], [[CMP_3]]
; CHECK-NEXT:    br i1 [[CMP]], label [[EXIT:%.*]], label [[BB:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sge i32 %a, 100
  %cmp.2 = icmp sle i32 %a, 0
  %cmp.3 = or i1 %cmp.2, %flag
  %cmp = or i1 %cmp.1, %cmp.3
  br i1 %cmp, label %exit, label %bb

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; Check that we can gather information for conditions is the form of
;   or ( i s<= Unknown, ... )
define void @test15(i32 %a, i32 %b, i1 %flag) {
; CHECK-LABEL: @test15(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP_1:%.*]] = icmp sle i32 [[A:%.*]], [[B:%.*]]
; CHECK-NEXT:    [[CMP:%.*]] = or i1 [[CMP_1]], [[FLAG:%.*]]
; CHECK-NEXT:    br i1 [[CMP]], label [[EXIT:%.*]], label [[BB:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 [[A]], 1
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp.1 = icmp sle i32 %a, %b
  %cmp = or i1 %cmp.1, %flag
  br i1 %cmp, label %exit, label %bb

bb:
  %sub = sub i32 %a, 1
  br label %exit

exit:
  ret void
}

; single basic block loop
; because the loop exit condition is SLT, we can supplement the iv sub
; (iv.next def) with an nsw.
define i32 @test16(i32* %n, i32* %a) {
; CHECK-LABEL: @test16(
; CHECK-NEXT:  preheader:
; CHECK-NEXT:    br label [[LOOP:%.*]]
; CHECK:       loop:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, [[PREHEADER:%.*]] ], [ [[IV_NEXT:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[ACC:%.*]] = phi i32 [ 0, [[PREHEADER]] ], [ [[ACC_CURR:%.*]], [[LOOP]] ]
; CHECK-NEXT:    [[X:%.*]] = load atomic i32, i32* [[A:%.*]] unordered, align 8
; CHECK-NEXT:    fence acquire
; CHECK-NEXT:    [[ACC_CURR]] = sub i32 [[ACC]], [[X]]
; CHECK-NEXT:    [[IV_NEXT]] = sub nsw i32 [[IV]], -1
; CHECK-NEXT:    [[NVAL:%.*]] = load atomic i32, i32* [[N:%.*]] unordered, align 8
; CHECK-NEXT:    [[CMP:%.*]] = icmp slt i32 [[IV_NEXT]], [[NVAL]]
; CHECK-NEXT:    br i1 [[CMP]], label [[LOOP]], label [[EXIT:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret i32 [[ACC_CURR]]
;
preheader:
  br label %loop

loop:
  %iv = phi i32 [ 0, %preheader ], [ %iv.next, %loop ]
  %acc = phi i32 [ 0, %preheader ], [ %acc.curr, %loop ]
  %x = load atomic i32, i32* %a unordered, align 8
  fence acquire
  %acc.curr = sub i32 %acc, %x
  %iv.next = sub i32 %iv, -1
  %nval = load atomic i32, i32* %n unordered, align 8
  %cmp = icmp slt i32 %iv.next, %nval
  br i1 %cmp, label %loop, label %exit

exit:
  ret i32 %acc.curr
}

define void @test17(i32 %a) {
; CHECK-LABEL: @test17(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[A:%.*]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nsw i32 1, [[A]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp sgt i32 %a, 100
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 1, %a
  br label %exit

exit:
  ret void
}

define void @test18(i32 %a) {
; CHECK-LABEL: @test18(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp sgt i32 [[A:%.*]], 10000
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw i32 -2, [[A]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp sgt i32 %a, 10000
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 -2, %a
  br label %exit

exit:
  ret void
}

define void @test19(i32 %a) {
; CHECK-LABEL: @test19(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ult i32 [[A:%.*]], 100
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub nuw nsw i32 -1, [[A]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp ult i32 %a, 100
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 -1, %a
  br label %exit

exit:
  ret void
}

define void @test20(i32 %a) {
; CHECK-LABEL: @test20(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[CMP:%.*]] = icmp ugt i32 [[A:%.*]], 2147483647
; CHECK-NEXT:    br i1 [[CMP]], label [[BB:%.*]], label [[EXIT:%.*]]
; CHECK:       bb:
; CHECK-NEXT:    [[SUB:%.*]] = sub i32 0, [[A]]
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
;
entry:
  %cmp = icmp ugt i32 %a, 2147483647
  br i1 %cmp, label %bb, label %exit

bb:
  %sub = sub i32 0, %a
  br label %exit

exit:
  ret void
}
