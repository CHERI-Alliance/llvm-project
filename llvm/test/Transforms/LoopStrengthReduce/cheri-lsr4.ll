; RUN: %riscv32_cheri_purecap_llc --filetype=asm -o - %s | FileCheck %s
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128-pf200:64:64:64:32-A200-P200-G200"
target triple = "riscv32-unknown-unknown"

; This test would previously try to take the index negatively out of bounds
; and then bring it back in with constant offsets.
; CHECK: do.end
; CHECK-NOT: neg
; CHECK: call alloc

define dso_local void @bad(i32 noundef %val) local_unnamed_addr addrspace(200) #0 {
entry:
  %buf = alloca [5 x i8], align 1, addrspace(200)
  br label %do.body

do.body:                                          ; preds = %do.body, %entry
  %val.addr.0 = phi i32 [ %val, %entry ], [ %shr, %do.body ]
  %p.0.idx = phi i32 [ 5, %entry ], [ %p.0.add, %do.body ]
  %0 = trunc i32 %val.addr.0 to i8
  %conv = and i8 %0, 127
  %p.0.add = add nsw i32 %p.0.idx, -1
  %1 = call addrspace(200) ptr addrspace(200) @llvm.cheri.bounded.stack.cap.i32(ptr addrspace(200) %buf, i32 5)
  %incdec.ptr.ptr = getelementptr inbounds i8, ptr addrspace(200) %1, i32 %p.0.add
  store i8 %conv, ptr addrspace(200) %incdec.ptr.ptr, align 1
  %shr = lshr i32 %val.addr.0, 7
  %cmp.not = icmp eq i32 %shr, 0
  br i1 %cmp.not, label %do.end, label %do.body

do.end:                                           ; preds = %do.body
  %2 = call addrspace(200) ptr addrspace(200) @llvm.cheri.bounded.stack.cap.i32(ptr addrspace(200) %buf, i32 5)
  %add.ptr.ptr = getelementptr inbounds nuw i8, ptr addrspace(200) %2, i32 5
  %3 = call addrspace(200) i32 @llvm.cheri.cap.diff.i32(ptr addrspace(200) nonnull %add.ptr.ptr, ptr addrspace(200) nonnull %incdec.ptr.ptr)
  %call = call addrspace(200) ptr addrspace(200) @alloc(i32 noundef %3) #6
  %tobool.not = icmp eq ptr addrspace(200) %call, null
  br i1 %tobool.not, label %if.end, label %while.cond.preheader

while.cond.preheader:                             ; preds = %do.end
  %cmp7.not20 = icmp eq i32 %p.0.add, 4
  br i1 %cmp7.not20, label %while.end, label %while.body.preheader

while.body.preheader:                             ; preds = %while.cond.preheader
  br label %while.body

while.body:                                       ; preds = %while.body.preheader, %while.body
  %p.1.ptr23 = phi ptr addrspace(200) [ %p.1.ptr, %while.body ], [ %incdec.ptr.ptr, %while.body.preheader ]
  %c.022 = phi ptr addrspace(200) [ %incdec.ptr10, %while.body ], [ %call, %while.body.preheader ]
  %p.1.idx21 = phi i32 [ %p.1.add, %while.body ], [ %p.0.add, %while.body.preheader ]
  %p.1.add = add nsw i32 %p.1.idx21, 1
  %4 = load i8, ptr addrspace(200) %p.1.ptr23, align 1
  %incdec.ptr10 = getelementptr inbounds nuw i8, ptr addrspace(200) %c.022, i32 1
  store i8 %4, ptr addrspace(200) %c.022, align 1
  %5 = call addrspace(200) ptr addrspace(200) @llvm.cheri.bounded.stack.cap.i32(ptr addrspace(200) %buf, i32 5)
  %p.1.ptr = getelementptr inbounds i8, ptr addrspace(200) %5, i32 %p.1.add
  %cmp7.not = icmp eq i32 %p.1.add, 4
  br i1 %cmp7.not, label %while.end.loopexit, label %while.body

while.end.loopexit:                               ; preds = %while.body
  br label %while.end

while.end:                                        ; preds = %while.end.loopexit, %while.cond.preheader
  %c.0.lcssa = phi ptr addrspace(200) [ %call, %while.cond.preheader ], [ %incdec.ptr10, %while.end.loopexit ]
  %p.1.ptr.lcssa = phi ptr addrspace(200) [ %incdec.ptr.ptr, %while.cond.preheader ], [ %p.1.ptr, %while.end.loopexit ]
  %6 = load i8, ptr addrspace(200) %p.1.ptr.lcssa, align 1
  store i8 %6, ptr addrspace(200) %c.0.lcssa, align 1
  br label %if.end

if.end:                                           ; preds = %while.end, %do.end
  ret void
}

; Function Attrs: optsize
declare dso_local ptr addrspace(200) @alloc(i32 noundef %0) local_unnamed_addr addrspace(200) #2

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.cheri.cap.diff.i32(ptr addrspace(200) %0, ptr addrspace(200) %1) addrspace(200) #3

; Function Attrs: nounwind willreturn memory(none)
declare ptr addrspace(200) @llvm.cheri.bounded.stack.cap.i32(ptr addrspace(200) %0, i32 %1) addrspace(200) #4

attributes #0 = { nounwind optsize}
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { optsize}
attributes #3 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #4 = { nounwind willreturn memory(none) }
attributes #5 = { nounwind }
attributes #6 = { nobuiltin nounwind optsize "no-builtins" }
