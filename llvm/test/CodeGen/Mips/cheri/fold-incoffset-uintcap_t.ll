; REQUIRES: clang
; RUN: %cheri_opt %s -S -O3 | FileCheck %s -check-prefix IR
; RUN: %cheri_opt %s -S -O3 | %cheri_llc -o - | FileCheck %s
target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-n32:64-S128"
target triple = "cheri-unknown-freebsd"


; Compiled from this source code:
;
; void* __capability add_cap() {
;   char* __capability cap = (char* __capability)100;
;   return cap + 924;
; }
;
; __uintcap_t add_uintcap_t() {
;   __uintcap_t cap = (__uintcap_t)100;
;   return cap + 924;
; }

; Function Attrs: nounwind
define ptr addrspace(200) @add_cap() #0 {
entry:
  %cap = alloca ptr addrspace(200), align 16
  store ptr addrspace(200) getelementptr (i8, ptr addrspace(200) null, i64 100), ptr %cap, align 16
  %0 = load ptr addrspace(200), ptr %cap, align 16
  %add.ptr = getelementptr inbounds i8, ptr addrspace(200) %0, i64 924
  ret ptr addrspace(200) %add.ptr
  ; This creates a potentially valid capability:
  ; IR-LABEL: @add_cap()
  ; IR:       ret ptr addrspace(200) getelementptr (i8, ptr addrspace(200) null, i64 1024)
  ; CHECK-LABEL: add_cap
  ; CHECK: daddiu $1, $zero, 1024
  ; CHECK: jr $ra
  ; CHECK: cincoffset $c3, $cnull, $1
}

; Function Attrs: nounwind
define ptr addrspace(200) @add_uintcap_t() #0 {
entry:
  %cap = alloca ptr addrspace(200), align 16
  %0 = call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) null, i64 100)
  store ptr addrspace(200) %0, ptr %cap, align 16
  %1 = load ptr addrspace(200), ptr %cap, align 16
  %2 = call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) null, i64 924)
  %3 = call i64 @llvm.cheri.cap.offset.get.i64(ptr addrspace(200) %1)
  %4 = call i64 @llvm.cheri.cap.offset.get.i64(ptr addrspace(200) %2)
  %add = add i64 %3, %4
  %5 = call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) %1, i64 %add)
  ret ptr addrspace(200) %5
  ; This always creates an untagged capability:
  ; IR-LABEL: @add_uintcap_t()
  ; IR: ret ptr addrspace(200) getelementptr (i8, ptr addrspace(200) null, i64 1024)

  ; CHECK-LABEL: add_uintcap_t
  ; CHECK: daddiu	$1, $zero, 1024
  ; CHECK: jr	$ra
  ; CHECK: cincoffset	$c3, $cnull, $1
}

; Function Attrs: nounwind willreturn memory(none)
declare ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200), i64) #1

; Function Attrs: nounwind willreturn memory(none)
declare i64 @llvm.cheri.cap.offset.get.i64(ptr addrspace(200)) #1

attributes #0 = { nounwind }
attributes #1 = { nounwind willreturn memory(none) }
