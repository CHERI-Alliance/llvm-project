; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mcpu=btver2 | FileCheck %s

define <2 x i64> @test5(i64* %base, <2 x i64> %src0) {
; CHECK-LABEL: test5:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vpinsrq $1, (%rdi), %xmm0, %xmm0
; CHECK-NEXT:    retq
 %res = call <2 x i64> @llvm.masked.expandload.v2i64(i64* %base, <2 x i1> <i1 false, i1 true>, <2 x i64> %src0)
 ret <2 x i64>%res
}
declare <2 x i64> @llvm.masked.expandload.v2i64(i64*, <2 x i1>, <2 x i64>)

define void @test11(i64* %base, <2 x i64> %V, <2 x i1> %mask) {
; CHECK-LABEL: test11:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vpsllq $63, %xmm1, %xmm1
; CHECK-NEXT:    vmovmskpd %xmm1, %eax
; CHECK-NEXT:    testb $1, %al
; CHECK-NEXT:    jne .LBB1_1
; CHECK-NEXT:  # %bb.2: # %else
; CHECK-NEXT:    testb $2, %al
; CHECK-NEXT:    jne .LBB1_3
; CHECK-NEXT:  .LBB1_4: # %else2
; CHECK-NEXT:    retq
; CHECK-NEXT:  .LBB1_1: # %cond.store
; CHECK-NEXT:    vmovq %xmm0, (%rdi)
; CHECK-NEXT:    addq $8, %rdi
; CHECK-NEXT:    testb $2, %al
; CHECK-NEXT:    je .LBB1_4
; CHECK-NEXT:  .LBB1_3: # %cond.store1
; CHECK-NEXT:    vpextrq $1, %xmm0, (%rdi)
; CHECK-NEXT:    retq
 call void @llvm.masked.compressstore.v2i64(<2 x i64> %V, i64* %base, <2 x i1> %mask)
 ret void
}
declare void @llvm.masked.compressstore.v2i64(<2 x i64>, i64* , <2 x i1>)
