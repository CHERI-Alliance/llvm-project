; RUN: opt -S -passes=instcombine -o - %s | FileCheck %s
; Reduced test case for a crash in the new optimization to fold multiple setoffset calls (orignally found when compiling libunwind)
target datalayout = "pf200:128:128:128:64-A200-P200-G200"

; Function Attrs: nounwind willreturn memory(none)
declare ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200), i64) addrspace(200) #0

define ptr addrspace(200) @test() addrspace(200) {
entry:
  %0 = sext i8 undef to i64
  %1 = call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) null, i64 %0)
  %2 = call ptr addrspace(200) @llvm.cheri.cap.offset.set.i64(ptr addrspace(200) %1, i64 10)
  ret ptr addrspace(200) %2
}

; CHECK-LABEL: define ptr addrspace(200) @test()
; CHECK-NEXT:   entry:
; CHECK-NEXT:    ret ptr addrspace(200) getelementptr (i8, ptr addrspace(200) null, i64 10)
; CHECK-NEXT: }
