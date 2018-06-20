; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i386-apple-darwin10.0 | FileCheck %s --check-prefix=CHECK-X86
; RUN: llc < %s -mtriple=x86_64-grtev4-linux-gnu | FileCheck %s --check-prefix=CHECK-X64

@g_14 = global i8 -6, align 1                     ; <i8*> [#uses=1]

declare i32 @func_16(i8 signext %p_19, i32 %p_20) nounwind

define i32 @func_35(i64 %p_38) nounwind ssp {
; CHECK-X86-LABEL: func_35:
; CHECK-X86:       ## %bb.0: ## %entry
; CHECK-X86-NEXT:    subl $12, %esp
; CHECK-X86-NEXT:    movsbl _g_14, %eax
; CHECK-X86-NEXT:    xorl %ecx, %ecx
; CHECK-X86-NEXT:    testl $255, %eax
; CHECK-X86-NEXT:    setg %cl
; CHECK-X86-NEXT:    subl $8, %esp
; CHECK-X86-NEXT:    pushl %ecx
; CHECK-X86-NEXT:    pushl %eax
; CHECK-X86-NEXT:    calll _func_16
; CHECK-X86-NEXT:    addl $16, %esp
; CHECK-X86-NEXT:    movl $1, %eax
; CHECK-X86-NEXT:    addl $12, %esp
; CHECK-X86-NEXT:    retl
;
; CHECK-X64-LABEL: func_35:
; CHECK-X64:       # %bb.0: # %entry
; CHECK-X64-NEXT:    pushq %rax
; CHECK-X64-NEXT:    movsbl {{.*}}(%rip), %edi
; CHECK-X64-NEXT:    xorl %esi, %esi
; CHECK-X64-NEXT:    testl $255, %edi
; CHECK-X64-NEXT:    setg %sil
; CHECK-X64-NEXT:    callq func_16
; CHECK-X64-NEXT:    movl $1, %eax
; CHECK-X64-NEXT:    popq %rcx
; CHECK-X64-NEXT:    retq
entry:
  %tmp = load i8, i8* @g_14                           ; <i8> [#uses=2]
  %conv = zext i8 %tmp to i32                     ; <i32> [#uses=1]
  %cmp = icmp sle i32 1, %conv                    ; <i1> [#uses=1]
  %conv2 = zext i1 %cmp to i32                    ; <i32> [#uses=1]
  %call = call i32 @func_16(i8 signext %tmp, i32 %conv2) ssp ; <i32> [#uses=1]
  ret i32 1
}

define void @fail(i16 %a, <2 x i8> %b) {
; CHECK-X86-LABEL: fail:
; CHECK-X86:       ## %bb.0:
; CHECK-X86-NEXT:    subl $12, %esp
; CHECK-X86-NEXT:    .cfi_def_cfa_offset 16
; CHECK-X86-NEXT:    movzwl {{[0-9]+}}(%esp), %ecx
; CHECK-X86-NEXT:    cmpb $123, {{[0-9]+}}(%esp)
; CHECK-X86-NEXT:    sete %al
; CHECK-X86-NEXT:    testl $263, %ecx ## imm = 0x107
; CHECK-X86-NEXT:    je LBB1_2
; CHECK-X86-NEXT:  ## %bb.1:
; CHECK-X86-NEXT:    testb %al, %al
; CHECK-X86-NEXT:    jne LBB1_2
; CHECK-X86-NEXT:  ## %bb.3: ## %no
; CHECK-X86-NEXT:    calll _bar
; CHECK-X86-NEXT:    addl $12, %esp
; CHECK-X86-NEXT:    retl
; CHECK-X86-NEXT:  LBB1_2: ## %yes
; CHECK-X86-NEXT:    addl $12, %esp
; CHECK-X86-NEXT:    retl
;
; CHECK-X64-LABEL: fail:
; CHECK-X64:       # %bb.0:
; CHECK-X64-NEXT:    pushq %rax
; CHECK-X64-NEXT:    .cfi_def_cfa_offset 16
; CHECK-X64-NEXT:    testw $263, %di # imm = 0x107
; CHECK-X64-NEXT:    je .LBB1_2
; CHECK-X64-NEXT:  # %bb.1:
; CHECK-X64-NEXT:    pand {{.*}}(%rip), %xmm0
; CHECK-X64-NEXT:    pcmpeqd {{.*}}(%rip), %xmm0
; CHECK-X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm0[1,0,3,2]
; CHECK-X64-NEXT:    pand %xmm0, %xmm1
; CHECK-X64-NEXT:    pextrw $4, %xmm1, %eax
; CHECK-X64-NEXT:    testb $1, %al
; CHECK-X64-NEXT:    jne .LBB1_2
; CHECK-X64-NEXT:  # %bb.3: # %no
; CHECK-X64-NEXT:    callq bar
; CHECK-X64-NEXT:    popq %rax
; CHECK-X64-NEXT:    .cfi_def_cfa_offset 8
; CHECK-X64-NEXT:    retq
; CHECK-X64-NEXT:  .LBB1_2: # %yes
; CHECK-X64-NEXT:    .cfi_def_cfa_offset 16
; CHECK-X64-NEXT:    popq %rax
; CHECK-X64-NEXT:    .cfi_def_cfa_offset 8
; CHECK-X64-NEXT:    retq
  %1 = icmp eq <2 x i8> %b, <i8 40, i8 123>
  %2 = extractelement <2 x i1> %1, i32 1
  %3 = and i16 %a, 263
  %4 = icmp eq i16 %3, 0
  %merge = or i1 %4, %2
  br i1 %merge, label %yes, label %no

yes:                                              ; preds = %0
  ret void

no:                                               ; preds = %0
  call void @bar()
  ret void
}

declare void @bar()
