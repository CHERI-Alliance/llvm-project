; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -unify-loop-exits -enable-new-pm=0 -S | FileCheck %s

define void @loop_1(i1 %PredEntry, i1 %PredB, i1 %PredC, i1 %PredD) {
; CHECK-LABEL: @loop_1(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br i1 [[PREDENTRY:%.*]], label [[A:%.*]], label [[G:%.*]]
; CHECK:       A:
; CHECK-NEXT:    br label [[B:%.*]]
; CHECK:       B:
; CHECK-NEXT:    br i1 [[PREDB:%.*]], label [[C:%.*]], label [[LOOP_EXIT_GUARD:%.*]]
; CHECK:       C:
; CHECK-NEXT:    br i1 [[PREDC:%.*]], label [[D:%.*]], label [[LOOP_EXIT_GUARD]]
; CHECK:       D:
; CHECK-NEXT:    br i1 [[PREDD:%.*]], label [[A]], label [[LOOP_EXIT_GUARD]]
; CHECK:       E:
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       F:
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       G:
; CHECK-NEXT:    br label [[F:%.*]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
; CHECK:       loop.exit.guard:
; CHECK-NEXT:    [[GUARD_E:%.*]] = phi i1 [ true, [[B]] ], [ false, [[C]] ], [ false, [[D]] ]
; CHECK-NEXT:    br i1 [[GUARD_E]], label [[E:%.*]], label [[F]]
;
entry:
  br i1 %PredEntry, label %A, label %G

A:
  br label %B

B:
  br i1 %PredB, label %C, label %E

C:
  br i1 %PredC, label %D, label %F

D:
  br i1 %PredD, label %A, label %F

E:
  br label %exit

F:
  br label %exit

G:
  br label %F

exit:
  ret void
}

define void @loop_2(i1 %PredA, i1 %PredB, i1 %PredC) {
; CHECK-LABEL: @loop_2(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[A:%.*]]
; CHECK:       A:
; CHECK-NEXT:    br i1 [[PREDA:%.*]], label [[B:%.*]], label [[LOOP_EXIT_GUARD:%.*]]
; CHECK:       B:
; CHECK-NEXT:    br i1 [[PREDB:%.*]], label [[C:%.*]], label [[LOOP_EXIT_GUARD]]
; CHECK:       C:
; CHECK-NEXT:    br i1 [[PREDC:%.*]], label [[D:%.*]], label [[LOOP_EXIT_GUARD]]
; CHECK:       D:
; CHECK-NEXT:    br label [[A]]
; CHECK:       X:
; CHECK-NEXT:    br label [[EXIT:%.*]]
; CHECK:       Y:
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       Z:
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret void
; CHECK:       loop.exit.guard:
; CHECK-NEXT:    [[GUARD_X:%.*]] = phi i1 [ true, [[A]] ], [ false, [[B]] ], [ false, [[C]] ]
; CHECK-NEXT:    [[GUARD_Y:%.*]] = phi i1 [ false, [[A]] ], [ true, [[B]] ], [ false, [[C]] ]
; CHECK-NEXT:    br i1 [[GUARD_X]], label [[X:%.*]], label [[LOOP_EXIT_GUARD1:%.*]]
; CHECK:       loop.exit.guard1:
; CHECK-NEXT:    br i1 [[GUARD_Y]], label [[Y:%.*]], label [[Z:%.*]]
;
entry:
  br label %A

A:
  br i1 %PredA, label %B, label %X

B:
  br i1 %PredB, label %C, label %Y

C:
  br i1 %PredC, label %D, label %Z

D:
  br label %A

X:
  br label %exit

Y:
  br label %exit

Z:
  br label %exit

exit:
  ret void
}
