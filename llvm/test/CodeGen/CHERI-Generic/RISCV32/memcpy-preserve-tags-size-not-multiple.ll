; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --force-update
; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/memcpy-preserve-tags-size-not-multiple.ll
; RUN: %riscv32_cheri_purecap_llc -o - -O0 -verify-machineinstrs %s | FileCheck %s -check-prefixes CHECK
; Check that we can inline memmove/memcpy despite having the must_preserve_cheri_tags property and the size not
; being a multiple of CAP_SIZE. Since the pointers are aligned we can start with capability copies and use
; word/byte copies for the trailing bytes.
declare void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* nocapture, i8 addrspace(200)* nocapture readonly, i64, i1) addrspace(200) #1
declare void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* nocapture, i8 addrspace(200)* nocapture readonly, i64, i1) addrspace(200) #1

define void @test_string_memmove(i8 addrspace(200)* %dst, i8 addrspace(200)* %src) addrspace(200) nounwind {
; CHECK-LABEL: test_string_memmove:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    clw a2, 40(ca1)
; CHECK-NEXT:    clb a3, 44(ca1)
; CHECK-NEXT:    clc ca4, 32(ca1)
; CHECK-NEXT:    clc ca5, 16(ca1)
; CHECK-NEXT:    clc ca6, 0(ca1)
; CHECK-NEXT:    csc ca6, 0(ca0)
; CHECK-NEXT:    clc ca6, 24(ca1)
; CHECK-NEXT:    clc ca1, 8(ca1)
; CHECK-NEXT:    csc ca1, 8(ca0)
; CHECK-NEXT:    csc ca5, 16(ca0)
; CHECK-NEXT:    csc ca6, 24(ca0)
; CHECK-NEXT:    csc ca4, 32(ca0)
; CHECK-NEXT:    csb a3, 44(ca0)
; CHECK-NEXT:    csw a2, 40(ca0)
; CHECK-NEXT:    cret
entry:
  ; Note: has must_preserve_cheri_tags, but this memmove can still be inlined since it's aligned
  call void @llvm.memmove.p200i8.p200i8.i64(i8 addrspace(200)* align 16 %dst, i8 addrspace(200)* align 16 %src, i64 45, i1 false) #0
  ret void
}

define void @test_string_memcpy(i8 addrspace(200)* %dst, i8 addrspace(200)* %src) addrspace(200) nounwind {
; CHECK-LABEL: test_string_memcpy:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    clb a2, 44(ca1)
; CHECK-NEXT:    csb a2, 44(ca0)
; CHECK-NEXT:    clw a2, 40(ca1)
; CHECK-NEXT:    csw a2, 40(ca0)
; CHECK-NEXT:    clc ca2, 32(ca1)
; CHECK-NEXT:    csc ca2, 32(ca0)
; CHECK-NEXT:    clc ca2, 24(ca1)
; CHECK-NEXT:    csc ca2, 24(ca0)
; CHECK-NEXT:    clc ca2, 16(ca1)
; CHECK-NEXT:    csc ca2, 16(ca0)
; CHECK-NEXT:    clc ca2, 8(ca1)
; CHECK-NEXT:    csc ca2, 8(ca0)
; CHECK-NEXT:    clc ca1, 0(ca1)
; CHECK-NEXT:    csc ca1, 0(ca0)
; CHECK-NEXT:    cret
entry:
  ; Note: has must_preserve_cheri_tags, but this memcpy can still be inlined since it's aligned
  call void @llvm.memcpy.p200i8.p200i8.i64(i8 addrspace(200)* align 16 %dst, i8 addrspace(200)* align 16 %src, i64 45, i1 false) #0
  ret void
}

attributes #0 = { "frontend-memtransfer-type"="'struct Test'" must_preserve_cheri_tags }
