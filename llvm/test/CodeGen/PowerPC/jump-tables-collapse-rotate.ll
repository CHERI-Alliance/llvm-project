; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=powerpc64le-unknown-linux-gnu -o - \
; RUN:   -ppc-asm-full-reg-names -verify-machineinstrs %s | FileCheck %s

; Function Attrs: nounwind
define dso_local zeroext i32 @test(i32 signext %l) nounwind {
; CHECK-LABEL: test:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr r0
; CHECK-NEXT:    std r0, 16(r1)
; CHECK-NEXT:    stdu r1, -32(r1)
; CHECK-NEXT:    addi r3, r3, -1
; CHECK-NEXT:    cmplwi r3, 5
; CHECK-NEXT:    bgt cr0, .LBB0_3
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    addis r4, r2, .LC0@toc@ha
; CHECK-NEXT:    rldic r3, r3, 2, 30
; CHECK-NEXT:    ld r4, .LC0@toc@l(r4)
; CHECK-NEXT:    lwax r3, r3, r4
; CHECK-NEXT:    add r3, r3, r4
; CHECK-NEXT:    mtctr r3
; CHECK-NEXT:    bctr
; CHECK-NEXT:  .LBB0_2: # %sw.bb
; CHECK-NEXT:    li r3, 2
; CHECK-NEXT:    bl test1
; CHECK-NEXT:    nop
; CHECK-NEXT:    b .LBB0_10
; CHECK-NEXT:  .LBB0_3: # %sw.default
; CHECK-NEXT:    li r3, 1
; CHECK-NEXT:    bl test1
; CHECK-NEXT:    nop
; CHECK-NEXT:    bl test3
; CHECK-NEXT:    nop
; CHECK-NEXT:    b .LBB0_10
; CHECK-NEXT:  .LBB0_4: # %sw.bb3
; CHECK-NEXT:    li r3, 3
; CHECK-NEXT:    b .LBB0_9
; CHECK-NEXT:  .LBB0_5: # %sw.bb5
; CHECK-NEXT:    li r3, 4
; CHECK-NEXT:    bl test2
; CHECK-NEXT:    nop
; CHECK-NEXT:    bl test3
; CHECK-NEXT:    nop
; CHECK-NEXT:    b .LBB0_10
; CHECK-NEXT:  .LBB0_6: # %sw.bb8
; CHECK-NEXT:    li r3, 5
; CHECK-NEXT:    bl test4
; CHECK-NEXT:    nop
; CHECK-NEXT:    b .LBB0_10
; CHECK-NEXT:  .LBB0_7: # %sw.bb10
; CHECK-NEXT:    li r3, 66
; CHECK-NEXT:    bl test4
; CHECK-NEXT:    nop
; CHECK-NEXT:    bl test1
; CHECK-NEXT:    nop
; CHECK-NEXT:    b .LBB0_10
; CHECK-NEXT:  .LBB0_8: # %sw.bb13
; CHECK-NEXT:    li r3, 66
; CHECK-NEXT:  .LBB0_9: # %return
; CHECK-NEXT:    bl test2
; CHECK-NEXT:    nop
; CHECK-NEXT:  .LBB0_10: # %return
; CHECK-NEXT:    clrldi r3, r3, 32
; CHECK-NEXT:    addi r1, r1, 32
; CHECK-NEXT:    ld r0, 16(r1)
; CHECK-NEXT:    mtlr r0
; CHECK-NEXT:    blr
entry:
  switch i32 %l, label %sw.default [
    i32 1, label %sw.bb
    i32 2, label %sw.bb3
    i32 3, label %sw.bb5
    i32 4, label %sw.bb8
    i32 5, label %sw.bb10
    i32 6, label %sw.bb13
  ]

sw.default:                                       ; preds = %entry
  %call = tail call signext i32 @test1(i32 signext 1)
  %call1 = tail call signext i32 @test3(i32 signext %call)
  br label %return

sw.bb:                                            ; preds = %entry
  %call2 = tail call signext i32 @test1(i32 signext 2)
  br label %return

sw.bb3:                                           ; preds = %entry
  %call4 = tail call signext i32 @test2(i32 signext 3)
  br label %return

sw.bb5:                                           ; preds = %entry
  %call6 = tail call signext i32 @test2(i32 signext 4)
  %call7 = tail call signext i32 @test3(i32 signext %call6)
  br label %return

sw.bb8:                                           ; preds = %entry
  %call9 = tail call signext i32 @test4(i32 signext 5)
  br label %return

sw.bb10:                                          ; preds = %entry
  %call11 = tail call signext i32 @test4(i32 signext 66)
  %call12 = tail call signext i32 @test1(i32 signext %call11)
  br label %return

sw.bb13:                                          ; preds = %entry
  %call14 = tail call signext i32 @test2(i32 signext 66)
  br label %return

return:                                           ; preds = %sw.bb13, %sw.bb10, %sw.bb8, %sw.bb5, %sw.bb3, %sw.bb, %sw.default
  %retval.0 = phi i32 [ %call1, %sw.default ], [ %call14, %sw.bb13 ], [ %call12, %sw.bb10 ], [ %call9, %sw.bb8 ], [ %call7, %sw.bb5 ], [ %call4, %sw.bb3 ], [ %call2, %sw.bb ]
  ret i32 %retval.0
}

declare signext i32 @test3(i32 signext)

declare signext i32 @test1(i32 signext)

declare signext i32 @test2(i32 signext)

declare signext i32 @test4(i32 signext)
