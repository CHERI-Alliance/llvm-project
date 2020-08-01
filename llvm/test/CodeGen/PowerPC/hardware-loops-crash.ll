; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -hardware-loops -S -verify-loop-lcssa | FileCheck %s

target datalayout = "E-m:e-i64:64-n32:64"
target triple = "ppc64-unknown-linux-elf"

declare i1 @cond() readnone

; Make sure we do not crash on the test.

define void @test() {
; CHECK-LABEL: @test(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    br label [[WHILE_COND:%.*]]
; CHECK:       while.cond:
; CHECK-NEXT:    br label [[FOR_BODY:%.*]]
; CHECK:       for.body:
; CHECK-NEXT:    br label [[FOR_INC:%.*]]
; CHECK:       for.inc:
; CHECK-NEXT:    [[C_0:%.*]] = call i1 @cond()
; CHECK-NEXT:    br i1 [[C_0]], label [[WHILE_COND25:%.*]], label [[FOR_BODY]]
; CHECK:       while.cond25:
; CHECK-NEXT:    [[INDVAR:%.*]] = phi i64 [ [[INDVAR_NEXT:%.*]], [[LAND_RHS:%.*]] ], [ 0, [[FOR_INC]] ]
; CHECK-NEXT:    [[INDVARS_IV349:%.*]] = phi i64 [ [[INDVARS_IV_NEXT350:%.*]], [[LAND_RHS]] ], [ 50, [[FOR_INC]] ]
; CHECK-NEXT:    [[CMP26_NOT:%.*]] = icmp eq i64 [[INDVARS_IV349]], 0
; CHECK-NEXT:    br i1 [[CMP26_NOT]], label [[WHILE_END187:%.*]], label [[LAND_RHS]]
; CHECK:       land.rhs:
; CHECK-NEXT:    [[INDVARS_IV_NEXT350]] = add nsw i64 [[INDVARS_IV349]], -1
; CHECK-NEXT:    [[C_1:%.*]] = call i1 @cond()
; CHECK-NEXT:    [[INDVAR_NEXT]] = add i64 [[INDVAR]], 1
; CHECK-NEXT:    br i1 [[C_1]], label [[WHILE_COND25]], label [[WHILE_END:%.*]]
; CHECK:       while.end:
; CHECK-NEXT:    [[INDVAR_LCSSA1:%.*]] = phi i64 [ [[INDVAR]], [[LAND_RHS]] ]
; CHECK-NEXT:    [[C_2:%.*]] = call i1 @cond()
; CHECK-NEXT:    br i1 [[C_2]], label [[WHILE_END187]], label [[WHILE_COND35_PREHEADER:%.*]]
; CHECK:       while.cond35.preheader:
; CHECK-NEXT:    [[TMP0:%.*]] = mul nsw i64 [[INDVAR_LCSSA1]], -1
; CHECK-NEXT:    [[TMP1:%.*]] = add i64 [[TMP0]], 51
; CHECK-NEXT:    call void @llvm.set.loop.iterations.i64(i64 [[TMP1]])
; CHECK-NEXT:    br label [[WHILE_COND35:%.*]]
; CHECK:       while.cond35:
; CHECK-NEXT:    [[TMP2:%.*]] = call i1 @llvm.loop.decrement.i64(i64 1)
; CHECK-NEXT:    br i1 [[TMP2]], label [[LAND_RHS37:%.*]], label [[IF_END51:%.*]]
; CHECK:       land.rhs37:
; CHECK-NEXT:    br label [[WHILE_COND35]]
; CHECK:       if.end51:
; CHECK-NEXT:    br label [[WHILE_COND_BACKEDGE:%.*]]
; CHECK:       while.cond.backedge:
; CHECK-NEXT:    br label [[WHILE_COND]]
; CHECK:       while.end187:
; CHECK-NEXT:    ret void
;
entry:
  br label %while.cond

while.cond:                                       ; preds = %while.cond.backedge, %entry
  br label %for.body

for.body:                                         ; preds = %for.inc, %while.cond
  br label %for.inc

for.inc:                                          ; preds = %for.body
  %c.0 = call i1 @cond()
  br i1 %c.0, label %while.cond25, label %for.body

while.cond25:                                     ; preds = %land.rhs, %for.inc
  %indvars.iv349 = phi i64 [ %indvars.iv.next350, %land.rhs ], [ 50, %for.inc ]
  %cmp26.not = icmp eq i64 %indvars.iv349, 0
  br i1 %cmp26.not, label %while.end187, label %land.rhs

land.rhs:                                         ; preds = %while.cond25
  %indvars.iv.next350 = add nsw i64 %indvars.iv349, -1
  %c.1 = call i1 @cond()
  br i1 %c.1, label %while.cond25, label %while.end

while.end:                                        ; preds = %land.rhs
  %c.2 = call i1 @cond()
  br i1 %c.2, label %while.end187, label %while.cond35.preheader

while.cond35.preheader:                           ; preds = %while.end
  %0 = and i64 %indvars.iv349, 4294967295
  br label %while.cond35

while.cond35:                                     ; preds = %land.rhs37, %while.cond35.preheader
  %indvars.iv351 = phi i64 [ %0, %while.cond35.preheader ], [ %indvars.iv.next352, %land.rhs37 ]
  %cmp36 = icmp sgt i64 %indvars.iv351, 0
  br i1 %cmp36, label %land.rhs37, label %if.end51

land.rhs37:                                       ; preds = %while.cond35
  %indvars.iv.next352 = add nsw i64 %indvars.iv351, -1
  br label %while.cond35

if.end51:                                         ; preds = %while.cond35
  br label %while.cond.backedge

while.cond.backedge:                              ; preds = %if.end51
  br label %while.cond

while.end187:                                     ; preds = %while.end, %while.cond25
  ret void
}
