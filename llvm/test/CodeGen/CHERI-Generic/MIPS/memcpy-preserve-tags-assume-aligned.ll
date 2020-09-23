; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --force-update
; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/memcpy-preserve-tags-assume-aligned.ll
; Check that __builtin_assume_aligned does the right thing and allows us to elide the memcpy
; call even with must_preserve_cheri_tags attribute (run instcombine to propagate assume information)
; RUN: %cheri128_purecap_opt -S -instcombine < %s | %cheri128_purecap_llc -O2 -o - | FileCheck %s
target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200-P200-G200"

; Function Attrs: argmemonly nounwind
declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8 addrspace(200)* nocapture readonly, i64, i1) #2
declare void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* nocapture writeonly, i8 addrspace(200)* nocapture readonly, i64, i1) #2
declare void @llvm.assume(i1) addrspace(200)

define void @memcpy_assume(i8 addrspace(200)* addrspace(200)* %local_cap_ptr, i8 addrspace(200)* %align1) addrspace(200) nounwind {
; CHECK-LABEL: memcpy_assume:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    clc $c1, $zero, 0($c3)
; CHECK-NEXT:    csc $c1, $zero, 0($c4)
; CHECK-NEXT:    clc $c1, $zero, 16($c3)
; CHECK-NEXT:    cjr $c17
; CHECK-NEXT:    csc $c1, $zero, 16($c4)
entry:
  %ptrint = ptrtoint i8 addrspace(200)* %align1 to i64
  %maskedptr = and i64 %ptrint, 15
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  %0 = bitcast i8 addrspace(200)* addrspace(200)* %local_cap_ptr to i8 addrspace(200)*
  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* align 1 %align1, i8 addrspace(200)* align 16 %0, i64 32, i1 false) must_preserve_cheri_tags
  ret void
}

define void @memmove_assume(i8 addrspace(200)* addrspace(200)* %local_cap_ptr, i8 addrspace(200)* %align1) addrspace(200) nounwind {
; CHECK-LABEL: memmove_assume:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    clc $c1, $zero, 16($c3)
; CHECK-NEXT:    clc $c2, $zero, 0($c3)
; CHECK-NEXT:    csc $c1, $zero, 16($c4)
; CHECK-NEXT:    cjr $c17
; CHECK-NEXT:    csc $c2, $zero, 0($c4)
entry:
  %ptrint = ptrtoint i8 addrspace(200)* %align1 to i64
  %maskedptr = and i64 %ptrint, 15
  %maskcond = icmp eq i64 %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  %0 = bitcast i8 addrspace(200)* addrspace(200)* %local_cap_ptr to i8 addrspace(200)*
  call void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* align 1 %align1, i8 addrspace(200)* align 16 %0, i64 32, i1 false) must_preserve_cheri_tags
  ret void
}

