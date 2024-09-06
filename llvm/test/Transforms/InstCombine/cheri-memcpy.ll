; RUN: opt < %s -passes=instcombine -S | FileCheck %s
source_filename = "copyptr.c"
target datalayout = "E-m:e-pf200:128:128:128:64-i8:8:32-i16:16:32-i64:64-n32:64-S128-A200"
target triple = "cheri-unknown-freebsd"

%struct.name_t = type { ptr addrspace(200) }

@x = common local_unnamed_addr addrspace(200) global %struct.name_t zeroinitializer, align 16

; Function Attrs: nounwind
define void @test(ptr addrspace(200) %str) local_unnamed_addr #0 {
entry:
  %0 = bitcast ptr addrspace(200) %str to ptr addrspace(200)
; Check that the memcpy is expanded to a load and store pair
; CHECK:   load ptr addrspace(200)
; CHECK:  store ptr addrspace(200)
  call void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) align 16 %0, ptr addrspace(200) align 16 @x, i64 16, i1 false)
  ret void
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p200.p200.i64(ptr addrspace(200) noalias nocapture writeonly, ptr addrspace(200) noalias nocapture readonly, i64, i1 immarg) #1

attributes #0 = { nounwind }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
