; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -instcombine -S < %s | FileCheck %s

; Check that we can turn the icmp sle into icmp ult, regardless of the
; order of the incoming values of the PHI node.

declare i1 @cond()

define void @phi_recurrence_start_first() {
; CHECK-LABEL: @phi_recurrence_start_first(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[WHILE_COND:%.*]]
; CHECK:       while.cond:
; CHECK-NEXT:    [[CELL_0:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[START:%.*]], [[FOR_COND26:%.*]] ]
; CHECK-NEXT:    [[COND_V:%.*]] = call i1 @cond()
; CHECK-NEXT:    br i1 [[COND_V]], label [[IF_THEN:%.*]], label [[WHILE_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[START]] = add nuw nsw i32 [[CELL_0]], 1
; CHECK-NEXT:    br i1 [[COND_V]], label [[FOR_COND11:%.*]], label [[FOR_COND26]]
; CHECK:       for.cond11:
; CHECK-NEXT:    [[I_1:%.*]] = phi i32 [ [[START]], [[IF_THEN]] ], [ [[STEP:%.*]], [[FOR_COND11]] ]
; CHECK-NEXT:    [[CMP13:%.*]] = icmp ult i32 [[I_1]], 100
; CHECK-NEXT:    [[STEP]] = add nuw nsw i32 [[I_1]], 1
; CHECK-NEXT:    br i1 [[CMP13]], label [[FOR_COND11]], label [[WHILE_END]]
; CHECK:       for.cond26:
; CHECK-NEXT:    br label [[WHILE_COND]]
; CHECK:       while.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %while.cond

while.cond:                                       ; preds = %entry, %for.cond26
  %cell.0 = phi i32 [ 0, %entry ], [ %start, %for.cond26 ]
  %cond.v = call i1 @cond()
  br i1 %cond.v, label %if.then, label %while.end

if.then:                                          ; preds = %while.cond
  %start = add nsw i32 %cell.0, 1
  br i1 %cond.v, label %for.cond11, label %for.cond26

for.cond11:                                       ; preds = %for.cond11, %if.then
  %i.1 = phi i32 [ %start, %if.then ], [ %step, %for.cond11 ]
  %cmp13 = icmp sle i32 %i.1, 99
  %step = add nsw i32 %i.1, 1
  br i1 %cmp13, label %for.cond11, label %while.end

for.cond26:                                       ; preds = %if.then
  br label %while.cond

while.end:                                        ; preds = %while.cond, %for.cond11
  ret void
}

define void @phi_recurrence_step_first() {
; CHECK-LABEL: @phi_recurrence_step_first(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[WHILE_COND:%.*]]
; CHECK:       while.cond:
; CHECK-NEXT:    [[CELL_0:%.*]] = phi i32 [ 0, [[ENTRY:%.*]] ], [ [[START:%.*]], [[FOR_COND26:%.*]] ]
; CHECK-NEXT:    [[COND_V:%.*]] = call i1 @cond()
; CHECK-NEXT:    br i1 [[COND_V]], label [[IF_THEN:%.*]], label [[WHILE_END:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    [[START]] = add nuw nsw i32 [[CELL_0]], 1
; CHECK-NEXT:    br i1 [[COND_V]], label [[FOR_COND11:%.*]], label [[FOR_COND26]]
; CHECK:       for.cond11:
; CHECK-NEXT:    [[I_1:%.*]] = phi i32 [ [[STEP:%.*]], [[FOR_COND11]] ], [ [[START]], [[IF_THEN]] ]
; CHECK-NEXT:    [[CMP13:%.*]] = icmp ult i32 [[I_1]], 100
; CHECK-NEXT:    [[STEP]] = add nuw nsw i32 [[I_1]], 1
; CHECK-NEXT:    br i1 [[CMP13]], label [[FOR_COND11]], label [[WHILE_END]]
; CHECK:       for.cond26:
; CHECK-NEXT:    br label [[WHILE_COND]]
; CHECK:       while.end:
; CHECK-NEXT:    ret void
;
entry:
  br label %while.cond

while.cond:                                       ; preds = %entry, %for.cond26
  %cell.0 = phi i32 [ 0, %entry ], [ %start, %for.cond26 ]
  %cond.v = call i1 @cond()
  br i1 %cond.v, label %if.then, label %while.end

if.then:                                          ; preds = %while.cond
  %start = add nsw i32 %cell.0, 1
  br i1 %cond.v, label %for.cond11, label %for.cond26

for.cond11:                                       ; preds = %for.cond11, %if.then
  %i.1 = phi i32 [ %step, %for.cond11 ], [ %start, %if.then]
  %cmp13 = icmp sle i32 %i.1, 99
  %step = add nsw i32 %i.1, 1
  br i1 %cmp13, label %for.cond11, label %while.end

for.cond26:                                       ; preds = %if.then
  br label %while.cond

while.end:                                        ; preds = %while.cond, %for.cond11
  ret void
}
