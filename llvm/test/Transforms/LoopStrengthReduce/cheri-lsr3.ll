; RUN: %riscv32_cheri_purecap_llc --filetype=asm -o - %s | \
; RUN:   FileCheck %s --check-prefix=CHECK-PURECAP-RV32
target datalayout = "e-m:e-p:32:32-i64:64-n32-S128-pf200:64:64:64:32-A200-P200-G200"

; Verify that a non-constant address calculation is not hoisted out of the loop by LSR

; CHECK-PURECAP-RV32-LABEL: foo:
; CHECK-PURECAP-RV32: cgetbase
; CHECK-PURECAP-RV32: csetaddr
; CHECK-PURECAP-RV32-NOT: cincoffset
; CHECK-PURECAP-RV32: .LBB0_1:

; Function Attrs: minsize mustprogress nounwind optsize
define dso_local noundef ptr addrspace(200) @foo(i32 noundef %option) local_unnamed_addr addrspace(200) #0 {
entry:
  %x = alloca [16 x i32], align 4, addrspace(200)
  %0 = tail call ptr addrspace(200) asm "", "={c2}"() #3
  %1 = tail call noundef i32 @llvm.cheri.cap.address.get.i32(ptr addrspace(200) %0)
  %2 = tail call noundef i32 @llvm.cheri.cap.base.get.i32(ptr addrspace(200) %0)
  %3 = tail call ptr addrspace(200) @llvm.cheri.cap.address.set.i32(ptr addrspace(200) %0, i32 %2)
  %4 = xor i32 %2, -1
  %sub7.i = add i32 %1, %4
  br label %for.cond.i

for.cond.i:                                       ; preds = %for.body.i, %entry
  %i.0.i = phi i32 [ %sub7.i, %entry ], [ %dec.i, %for.body.i ]
  %cmp.i = icmp sgt i32 %i.0.i, 0
  br i1 %cmp.i, label %for.body.i, label %exit

for.body.i:                                       ; preds = %for.cond.i
  %arrayidx.i.i = getelementptr inbounds nuw i8, ptr addrspace(200) %3, i32 %i.0.i
  %5 = load i8, ptr addrspace(200) %arrayidx.i.i, align 1
  %cmp9.not.i = icmp eq i8 %5, 0
  %dec.i = add nsw i32 %i.0.i, -1
  br i1 %cmp9.not.i, label %for.cond.i, label %if.then.i.i

if.then.i.i:                                      ; preds = %for.body.i
  tail call void @llvm.trap()
  unreachable

exit: ; preds = %for.cond.i
  ret ptr addrspace(200) null
}

; Function Attrs: nounwind willreturn memory(none)
declare i32 @llvm.cheri.cap.address.get.i32(ptr addrspace(200)) addrspace(200) #1

; Function Attrs: nounwind willreturn memory(none)
declare i32 @llvm.cheri.cap.base.get.i32(ptr addrspace(200)) addrspace(200) #1

; Function Attrs: nounwind willreturn memory(none)
declare ptr addrspace(200) @llvm.cheri.cap.address.set.i32(ptr addrspace(200), i32) addrspace(200) #1

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() addrspace(200) #2

attributes #0 = { minsize mustprogress nounwind optsize }
attributes #1 = { nounwind willreturn memory(none) }
attributes #2 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #3 = { nounwind memory(none) }
