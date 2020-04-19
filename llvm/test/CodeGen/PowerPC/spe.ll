; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -verify-machineinstrs < %s -mtriple=powerpc-unknown-linux-gnu \
; RUN:          -mattr=+spe |  FileCheck %s

declare float @llvm.fabs.float(float)
define float @test_float_abs(float %a) #0 {
; CHECK-LABEL: test_float_abs:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsabs 3, 3
; CHECK-NEXT:    blr
  entry:
    %0 = tail call float @llvm.fabs.float(float %a)
    ret float %0
}

define float @test_fnabs(float %a) #0 {
; CHECK-LABEL: test_fnabs:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsnabs 3, 3
; CHECK-NEXT:    blr
  entry:
    %0 = tail call float @llvm.fabs.float(float %a)
    %sub = fsub float -0.000000e+00, %0
    ret float %sub
}

define float @test_fdiv(float %a, float %b) {
; CHECK-LABEL: test_fdiv:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsdiv 3, 3, 4
; CHECK-NEXT:    blr
entry:
  %v = fdiv float %a, %b
  ret float %v

}

define float @test_fmul(float %a, float %b) {
; CHECK-LABEL: test_fmul:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsmul 3, 3, 4
; CHECK-NEXT:    blr
  entry:
  %v = fmul float %a, %b
  ret float %v
}

define float @test_fadd(float %a, float %b) {
; CHECK-LABEL: test_fadd:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsadd 3, 3, 4
; CHECK-NEXT:    blr
  entry:
  %v = fadd float %a, %b
  ret float %v
}

define float @test_fsub(float %a, float %b) {
; CHECK-LABEL: test_fsub:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efssub 3, 3, 4
; CHECK-NEXT:    blr
  entry:
  %v = fsub float %a, %b
  ret float %v
}

define float @test_fneg(float %a) {
; CHECK-LABEL: test_fneg:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efsneg 3, 3
; CHECK-NEXT:    blr
  entry:
  %v = fsub float -0.0, %a
  ret float %v
}

define float @test_dtos(double %a) {
; CHECK-LABEL: test_dtos:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efscfd 3, 3
; CHECK-NEXT:    blr
  entry:
  %v = fptrunc double %a to float
  ret float %v
}

define i32 @test_fcmpgt(float %a, float %b) {
; CHECK-LABEL: test_fcmpgt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpgt 0, 3, 4
; CHECK-NEXT:    ble 0, .LBB8_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB8_3
; CHECK-NEXT:  .LBB8_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB8_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ogt float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_fcmpugt(float %a, float %b) {
; CHECK-LABEL: test_fcmpugt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB9_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB9_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efscmpgt 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB9_4
; CHECK-NEXT:  # %bb.3: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    b .LBB9_5
; CHECK-NEXT:  .LBB9_4: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:  .LBB9_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ugt float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_fcmple(float %a, float %b) {
; CHECK-LABEL: test_fcmple:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB10_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efscmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB10_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efscmpgt 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB10_4
; CHECK-NEXT:  # %bb.3: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB10_5
; CHECK-NEXT:  .LBB10_4: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB10_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ole float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_fcmpule(float %a, float %b) {
; CHECK-LABEL: test_fcmpule:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpgt 0, 3, 4
; CHECK-NEXT:    bgt 0, .LBB11_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB11_3
; CHECK-NEXT:  .LBB11_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB11_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ule float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

; The type of comparison found in C's if (x == y)
define i32 @test_fcmpeq(float %a, float %b) {
; CHECK-LABEL: test_fcmpeq:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpeq 0, 3, 4
; CHECK-NEXT:    ble 0, .LBB12_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB12_3
; CHECK-NEXT:  .LBB12_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB12_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp oeq float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

; (un)ordered tests are expanded to une and oeq so verify
define i1 @test_fcmpuno(float %a, float %b) {
; CHECK-LABEL: test_fcmpuno:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    efscmpeq 1, 4, 4
; CHECK-NEXT:    li 5, 1
; CHECK-NEXT:    crand 20, 5, 1
; CHECK-NEXT:    bc 12, 20, .LBB13_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 5, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB13_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp uno float %a, %b
  ret i1 %r
}

define i1 @test_fcmpord(float %a, float %b) {
; CHECK-LABEL: test_fcmpord:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efscmpeq 0, 4, 4
; CHECK-NEXT:    efscmpeq 1, 3, 3
; CHECK-NEXT:    li 5, 1
; CHECK-NEXT:    crnand 20, 5, 1
; CHECK-NEXT:    bc 12, 20, .LBB14_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 5, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB14_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp ord float %a, %b
  ret i1 %r
}

define i1 @test_fcmpueq(float %a, float %b) {
; CHECK-LABEL: test_fcmpueq:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    efscmpeq 1, 4, 4
; CHECK-NEXT:    crnand 20, 5, 1
; CHECK-NEXT:    efscmpeq 0, 3, 4
; CHECK-NEXT:    li 5, 1
; CHECK-NEXT:    crnor 20, 1, 20
; CHECK-NEXT:    bc 12, 20, .LBB15_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 5, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB15_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp ueq float %a, %b
  ret i1 %r
}

define i1 @test_fcmpne(float %a, float %b) {
; CHECK-LABEL: test_fcmpne:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efscmpeq 0, 4, 4
; CHECK-NEXT:    efscmpeq 1, 3, 3
; CHECK-NEXT:    crand 20, 5, 1
; CHECK-NEXT:    efscmpeq 0, 3, 4
; CHECK-NEXT:    li 5, 1
; CHECK-NEXT:    crorc 20, 1, 20
; CHECK-NEXT:    bc 12, 20, .LBB16_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 5, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB16_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp one float %a, %b
  ret i1 %r
}

define i32 @test_fcmpune(float %a, float %b) {
; CHECK-LABEL: test_fcmpune:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpeq 0, 3, 4
; CHECK-NEXT:    bgt 0, .LBB17_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB17_3
; CHECK-NEXT:  .LBB17_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB17_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp une float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_fcmplt(float %a, float %b) {
; CHECK-LABEL: test_fcmplt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmplt 0, 3, 4
; CHECK-NEXT:    ble 0, .LBB18_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB18_3
; CHECK-NEXT:  .LBB18_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB18_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp olt float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i1 @test_fcmpult(float %a, float %b) {
; CHECK-LABEL: test_fcmpult:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    efscmpeq 1, 4, 4
; CHECK-NEXT:    crnand 20, 5, 1
; CHECK-NEXT:    efscmplt 0, 3, 4
; CHECK-NEXT:    li 5, 1
; CHECK-NEXT:    crnor 20, 1, 20
; CHECK-NEXT:    bc 12, 20, .LBB19_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 5, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB19_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp ult float %a, %b
  ret i1 %r
}

define i32 @test_fcmpge(float %a, float %b) {
; CHECK-LABEL: test_fcmpge:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB20_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efscmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB20_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efscmplt 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB20_4
; CHECK-NEXT:  # %bb.3: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB20_5
; CHECK-NEXT:  .LBB20_4: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB20_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp oge float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_fcmpuge(float %a, float %b) {
; CHECK-LABEL: test_fcmpuge:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    efscmplt 0, 3, 4
; CHECK-NEXT:    bgt 0, .LBB21_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB21_3
; CHECK-NEXT:  .LBB21_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB21_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp uge float %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}


define i32 @test_ftoui(float %a) {
; CHECK-LABEL: test_ftoui:
; CHECK:       # %bb.0:
; CHECK-NEXT:    efsctuiz 3, 3
; CHECK-NEXT:    blr
  %v = fptoui float %a to i32
  ret i32 %v
}

define i32 @test_ftosi(float %a) {
; CHECK-LABEL: test_ftosi:
; CHECK:       # %bb.0:
; CHECK-NEXT:    efsctsiz 3, 3
; CHECK-NEXT:    blr
  %v = fptosi float %a to i32
  ret i32 %v
}

define float @test_ffromui(i32 %a) {
; CHECK-LABEL: test_ffromui:
; CHECK:       # %bb.0:
; CHECK-NEXT:    efscfui 3, 3
; CHECK-NEXT:    blr
  %v = uitofp i32 %a to float
  ret float %v
}

define float @test_ffromsi(i32 %a) {
; CHECK-LABEL: test_ffromsi:
; CHECK:       # %bb.0:
; CHECK-NEXT:    efscfsi 3, 3
; CHECK-NEXT:    blr
  %v = sitofp i32 %a to float
  ret float %v
}

define i32 @test_fasmconst(float %x) {
; CHECK-LABEL: test_fasmconst:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -32(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 32
; CHECK-NEXT:    stw 3, 20(1)
; CHECK-NEXT:    stw 3, 24(1)
; CHECK-NEXT:    lwz 3, 20(1)
; CHECK-NEXT:    #APP
; CHECK-NEXT:    efsctsi 3, 3
; CHECK-NEXT:    #NO_APP
; CHECK-NEXT:    addi 1, 1, 32
; CHECK-NEXT:    blr
entry:
  %x.addr = alloca float, align 8
  store float %x, float* %x.addr, align 8
  %0 = load float, float* %x.addr, align 8
  %1 = call i32 asm sideeffect "efsctsi $0, $1", "=f,f"(float %0)
  ret i32 %1
; Check that it's not loading a double
}

; Double tests

define void @test_double_abs(double * %aa) #0 {
; CHECK-LABEL: test_double_abs:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evldd 4, 0(3)
; CHECK-NEXT:    efdabs 4, 4
; CHECK-NEXT:    evstdd 4, 0(3)
; CHECK-NEXT:    blr
  entry:
    %0 = load double, double * %aa
    %1 = tail call double @llvm.fabs.f64(double %0) #2
    store double %1, double * %aa
    ret void
}

; Function Attrs: nounwind readnone
declare double @llvm.fabs.f64(double) #1

define void @test_dnabs(double * %aa) #0 {
; CHECK-LABEL: test_dnabs:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evldd 4, 0(3)
; CHECK-NEXT:    efdnabs 4, 4
; CHECK-NEXT:    evstdd 4, 0(3)
; CHECK-NEXT:    blr
  entry:
    %0 = load double, double * %aa
    %1 = tail call double @llvm.fabs.f64(double %0) #2
    %sub = fsub double -0.000000e+00, %1
    store double %sub, double * %aa
    ret void
}

define double @test_ddiv(double %a, double %b) {
; CHECK-LABEL: test_ddiv:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efddiv 4, 3, 5
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
entry:
  %v = fdiv double %a, %b
  ret double %v

}

define double @test_dmul(double %a, double %b) {
; CHECK-LABEL: test_dmul:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdmul 4, 3, 5
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
  entry:
  %v = fmul double %a, %b
  ret double %v
}

define double @test_dadd(double %a, double %b) {
; CHECK-LABEL: test_dadd:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdadd 4, 3, 5
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
  entry:
  %v = fadd double %a, %b
  ret double %v
}

define double @test_dsub(double %a, double %b) {
; CHECK-LABEL: test_dsub:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdsub 4, 3, 5
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
  entry:
  %v = fsub double %a, %b
  ret double %v
}

define double @test_dneg(double %a) {
; CHECK-LABEL: test_dneg:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdneg 4, 3
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
  entry:
  %v = fsub double -0.0, %a
  ret double %v
}

define double @test_stod(float %a) {
; CHECK-LABEL: test_stod:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efdcfs 4, 3
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
  entry:
  %v = fpext float %a to double
  ret double %v
}

; (un)ordered tests are expanded to une and oeq so verify
define i1 @test_dcmpuno(double %a, double %b) {
; CHECK-LABEL: test_dcmpuno:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    li 7, 1
; CHECK-NEXT:    efdcmpeq 0, 3, 3
; CHECK-NEXT:    efdcmpeq 1, 5, 5
; CHECK-NEXT:    crand 20, 5, 1
; CHECK-NEXT:    bc 12, 20, .LBB35_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 7, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB35_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp uno double %a, %b
  ret i1 %r
}

define i1 @test_dcmpord(double %a, double %b) {
; CHECK-LABEL: test_dcmpord:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    li 7, 1
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    efdcmpeq 1, 3, 3
; CHECK-NEXT:    crnand 20, 5, 1
; CHECK-NEXT:    bc 12, 20, .LBB36_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 7, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB36_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp ord double %a, %b
  ret i1 %r
}

define i32 @test_dcmpgt(double %a, double %b) {
; CHECK-LABEL: test_dcmpgt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmpgt 0, 3, 5
; CHECK-NEXT:    ble 0, .LBB37_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB37_3
; CHECK-NEXT:  .LBB37_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB37_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ogt double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmpugt(double %a, double %b) {
; CHECK-LABEL: test_dcmpugt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB38_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efdcmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB38_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efdcmpgt 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB38_4
; CHECK-NEXT:  # %bb.3: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    b .LBB38_5
; CHECK-NEXT:  .LBB38_4: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:  .LBB38_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ugt double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmple(double %a, double %b) {
; CHECK-LABEL: test_dcmple:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmpgt 0, 3, 5
; CHECK-NEXT:    bgt 0, .LBB39_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB39_3
; CHECK-NEXT:  .LBB39_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB39_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ule double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmpule(double %a, double %b) {
; CHECK-LABEL: test_dcmpule:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmpgt 0, 3, 5
; CHECK-NEXT:    bgt 0, .LBB40_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB40_3
; CHECK-NEXT:  .LBB40_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB40_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ule double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

; The type of comparison found in C's if (x == y)
define i32 @test_dcmpeq(double %a, double %b) {
; CHECK-LABEL: test_dcmpeq:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmpeq 0, 3, 5
; CHECK-NEXT:    ble 0, .LBB41_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB41_3
; CHECK-NEXT:  .LBB41_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB41_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp oeq double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmpueq(double %a, double %b) {
; CHECK-LABEL: test_dcmpueq:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB42_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efdcmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB42_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efdcmpeq 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB42_4
; CHECK-NEXT:  # %bb.3: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    b .LBB42_5
; CHECK-NEXT:  .LBB42_4: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:  .LBB42_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ueq double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i1 @test_dcmpne(double %a, double %b) {
; CHECK-LABEL: test_dcmpne:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    li 7, 1
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    efdcmpeq 1, 3, 3
; CHECK-NEXT:    efdcmpeq 5, 3, 4
; CHECK-NEXT:    crand 24, 5, 1
; CHECK-NEXT:    crorc 20, 21, 24
; CHECK-NEXT:    bc 12, 20, .LBB43_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 7, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB43_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp one double %a, %b
  ret i1 %r
}

define i32 @test_dcmpune(double %a, double %b) {
; CHECK-LABEL: test_dcmpune:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmpeq 0, 3, 5
; CHECK-NEXT:    bgt 0, .LBB44_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB44_3
; CHECK-NEXT:  .LBB44_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB44_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp une double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmplt(double %a, double %b) {
; CHECK-LABEL: test_dcmplt:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmplt 0, 3, 5
; CHECK-NEXT:    ble 0, .LBB45_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB45_3
; CHECK-NEXT:  .LBB45_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB45_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp olt double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i32 @test_dcmpult(double %a, double %b) {
; CHECK-LABEL: test_dcmpult:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    bc 4, 1, .LBB46_4
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    efdcmpeq 0, 3, 3
; CHECK-NEXT:    bc 4, 1, .LBB46_4
; CHECK-NEXT:  # %bb.2: # %entry
; CHECK-NEXT:    efdcmplt 0, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB46_4
; CHECK-NEXT:  # %bb.3: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:    b .LBB46_5
; CHECK-NEXT:  .LBB46_4: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:  .LBB46_5: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp ult double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define i1 @test_dcmpge(double %a, double %b) {
; CHECK-LABEL: test_dcmpge:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evmergelo 4, 5, 6
; CHECK-NEXT:    li 7, 1
; CHECK-NEXT:    efdcmpeq 0, 4, 4
; CHECK-NEXT:    efdcmpeq 1, 3, 3
; CHECK-NEXT:    efdcmplt 5, 3, 4
; CHECK-NEXT:    crand 24, 5, 1
; CHECK-NEXT:    crorc 20, 21, 24
; CHECK-NEXT:    bc 12, 20, .LBB47_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    ori 3, 7, 0
; CHECK-NEXT:    blr
; CHECK-NEXT:  .LBB47_2: # %entry
; CHECK-NEXT:    addi 3, 0, 0
; CHECK-NEXT:    blr
  entry:
  %r = fcmp oge double %a, %b
  ret i1 %r
}

define i32 @test_dcmpuge(double %a, double %b) {
; CHECK-LABEL: test_dcmpuge:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdcmplt 0, 3, 5
; CHECK-NEXT:    bgt 0, .LBB48_2
; CHECK-NEXT:  # %bb.1: # %tr
; CHECK-NEXT:    li 3, 1
; CHECK-NEXT:    b .LBB48_3
; CHECK-NEXT:  .LBB48_2: # %fa
; CHECK-NEXT:    li 3, 0
; CHECK-NEXT:  .LBB48_3: # %ret
; CHECK-NEXT:    stw 3, 12(1)
; CHECK-NEXT:    lwz 3, 12(1)
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
  entry:
  %r = alloca i32, align 4
  %c = fcmp uge double %a, %b
  br i1 %c, label %tr, label %fa
tr:
  store i32 1, i32* %r, align 4
  br label %ret
fa:
  store i32 0, i32* %r, align 4
  br label %ret
ret:
  %0 = load i32, i32* %r, align 4
  ret i32 %0
}

define double @test_dselect(double %a, double %b, i1 %c) {
; CHECK-LABEL: test_dselect:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    andi. 7, 7, 1
; CHECK-NEXT:    evmergelo 5, 5, 6
; CHECK-NEXT:    evmergelo 4, 3, 4
; CHECK-NEXT:    bc 12, 1, .LBB49_2
; CHECK-NEXT:  # %bb.1: # %entry
; CHECK-NEXT:    evor 4, 5, 5
; CHECK-NEXT:  .LBB49_2: # %entry
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
entry:
  %r = select i1 %c, double %a, double %b
  ret double %r
}

define i32 @test_dtoui(double %a) {
; CHECK-LABEL: test_dtoui:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdctuiz 3, 3
; CHECK-NEXT:    blr
entry:
  %v = fptoui double %a to i32
  ret i32 %v
}

define i32 @test_dtosi(double %a) {
; CHECK-LABEL: test_dtosi:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    efdctsiz 3, 3
; CHECK-NEXT:    blr
entry:
  %v = fptosi double %a to i32
  ret i32 %v
}

define double @test_dfromui(i32 %a) {
; CHECK-LABEL: test_dfromui:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efdcfui 4, 3
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
entry:
  %v = uitofp i32 %a to double
  ret double %v
}

define double @test_dfromsi(i32 %a) {
; CHECK-LABEL: test_dfromsi:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    efdcfsi 4, 3
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    blr
entry:
  %v = sitofp i32 %a to double
  ret double %v
}

define i32 @test_dasmconst(double %x) {
; CHECK-LABEL: test_dasmconst:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    stwu 1, -16(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 16
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    evstdd 3, 8(1)
; CHECK-NEXT:    #APP
; CHECK-NEXT:    efdctsi 3, 3
; CHECK-NEXT:    #NO_APP
; CHECK-NEXT:    addi 1, 1, 16
; CHECK-NEXT:    blr
entry:
  %x.addr = alloca double, align 8
  store double %x, double* %x.addr, align 8
  %0 = load double, double* %x.addr, align 8
  %1 = call i32 asm sideeffect "efdctsi $0, $1", "=d,d"(double %0)
  ret i32 %1
}

declare double @test_spill_spe_regs(double, double);
define dso_local void @test_func2() #0 {
; CHECK-LABEL: test_func2:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    blr
entry:
  ret void
}

declare void @test_memset(i8* nocapture writeonly, i8, i32, i1)
@global_var1 = global i32 0, align 4
define double @test_spill(double %a, i32 %a1, i64 %a2, i8 * %a3, i32 *%a4, i32* %a5) nounwind {
; CHECK-LABEL: test_spill:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr 0
; CHECK-NEXT:    stw 0, 4(1)
; CHECK-NEXT:    stwu 1, -272(1)
; CHECK-NEXT:    li 5, 256
; CHECK-NEXT:    evstddx 30, 1, 5 # 8-byte Folded Spill
; CHECK-NEXT:    li 5, 264
; CHECK-NEXT:    evstddx 31, 1, 5 # 8-byte Folded Spill
; CHECK-NEXT:    li 5, .LCPI56_0@l
; CHECK-NEXT:    lis 6, .LCPI56_0@ha
; CHECK-NEXT:    evlddx 5, 6, 5
; CHECK-NEXT:    evstdd 14, 128(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 15, 136(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 16, 144(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 17, 152(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 18, 160(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 19, 168(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 20, 176(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 21, 184(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 22, 192(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 23, 200(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 24, 208(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 25, 216(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 26, 224(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 27, 232(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 28, 240(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 29, 248(1) # 8-byte Folded Spill
; CHECK-NEXT:    evmergelo 3, 3, 4
; CHECK-NEXT:    lwz 4, 280(1)
; CHECK-NEXT:    efdadd 3, 3, 3
; CHECK-NEXT:    efdadd 3, 3, 5
; CHECK-NEXT:    evstdd 3, 24(1) # 8-byte Folded Spill
; CHECK-NEXT:    stw 4, 20(1) # 4-byte Folded Spill
; CHECK-NEXT:    #APP
; CHECK-NEXT:    #NO_APP
; CHECK-NEXT:    addi 3, 1, 76
; CHECK-NEXT:    li 4, 0
; CHECK-NEXT:    li 5, 24
; CHECK-NEXT:    li 6, 1
; CHECK-NEXT:    li 30, 0
; CHECK-NEXT:    bl test_memset
; CHECK-NEXT:    lwz 3, 20(1) # 4-byte Folded Reload
; CHECK-NEXT:    stw 30, 0(3)
; CHECK-NEXT:    bl test_func2
; CHECK-NEXT:    addi 3, 1, 32
; CHECK-NEXT:    li 4, 0
; CHECK-NEXT:    li 5, 20
; CHECK-NEXT:    li 6, 1
; CHECK-NEXT:    bl test_memset
; CHECK-NEXT:    evldd 4, 24(1) # 8-byte Folded Reload
; CHECK-NEXT:    li 5, 264
; CHECK-NEXT:    evmergehi 3, 4, 4
; CHECK-NEXT:    evlddx 31, 1, 5 # 8-byte Folded Reload
; CHECK-NEXT:    li 5, 256
; CHECK-NEXT:    # kill: def $r3 killed $r3 killed $s3
; CHECK-NEXT:    # kill: def $r4 killed $r4 killed $s4
; CHECK-NEXT:    evlddx 30, 1, 5 # 8-byte Folded Reload
; CHECK-NEXT:    evldd 29, 248(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 28, 240(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 27, 232(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 26, 224(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 25, 216(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 24, 208(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 23, 200(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 22, 192(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 21, 184(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 20, 176(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 19, 168(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 18, 160(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 17, 152(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 16, 144(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 15, 136(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 14, 128(1) # 8-byte Folded Reload
; CHECK-NEXT:    lwz 0, 276(1)
; CHECK-NEXT:    addi 1, 1, 272
; CHECK-NEXT:    mtlr 0
; CHECK-NEXT:    blr
entry:
  %v1 = alloca [13 x i32], align 4
  %v2 = alloca [11 x i32], align 4
  %0 = fadd double %a, %a
  call void asm sideeffect "","~{s0},~{s3},~{s4},~{s5},~{s6},~{s7},~{s8},~{s9},~{s10},~{s11},~{s12},~{s13},~{s14},~{s15},~{s16},~{s17},~{s18},~{s19},~{s20},~{s21},~{s22},~{s23},~{s24},~{s25},~{s26},~{s27},~{s28},~{s29},~{s30},~{s31}"() nounwind
  %1 = fadd double %0, 3.14159
  %2 = bitcast [13 x i32]* %v1 to i8*
  call void @test_memset(i8* align 4 %2, i8 0, i32 24, i1 true)
  store i32 0, i32* %a5, align 4
  call void @test_func2()
  %3 = bitcast [11 x i32]* %v2 to i8*
  call void @test_memset(i8* align 4 %3, i8 0, i32 20, i1 true)
  br label %return

return:
  ret double %1

}

define dso_local float @test_fma(i32 %d) local_unnamed_addr #0 {
; CHECK-LABEL: test_fma:
; CHECK:       # %bb.0: # %entry
; CHECK-NEXT:    mflr 0
; CHECK-NEXT:    stw 0, 4(1)
; CHECK-NEXT:    stwu 1, -48(1)
; CHECK-NEXT:    .cfi_def_cfa_offset 48
; CHECK-NEXT:    .cfi_offset lr, 4
; CHECK-NEXT:    .cfi_offset r29, -12
; CHECK-NEXT:    .cfi_offset r30, -8
; CHECK-NEXT:    .cfi_offset r29, -40
; CHECK-NEXT:    .cfi_offset r30, -32
; CHECK-NEXT:    cmpwi 3, 1
; CHECK-NEXT:    stw 29, 36(1) # 4-byte Folded Spill
; CHECK-NEXT:    stw 30, 40(1) # 4-byte Folded Spill
; CHECK-NEXT:    evstdd 29, 8(1) # 8-byte Folded Spill
; CHECK-NEXT:    evstdd 30, 16(1) # 8-byte Folded Spill
; CHECK-NEXT:    blt 0, .LBB57_3
; CHECK-NEXT:  # %bb.1: # %for.body.preheader
; CHECK-NEXT:    mr 30, 3
; CHECK-NEXT:    li 29, 0
; CHECK-NEXT:    # implicit-def: $r5
; CHECK-NEXT:  .LBB57_2: # %for.body
; CHECK-NEXT:    #
; CHECK-NEXT:    efscfsi 3, 29
; CHECK-NEXT:    mr 4, 3
; CHECK-NEXT:    bl fmaf
; CHECK-NEXT:    addi 29, 29, 1
; CHECK-NEXT:    cmplw 30, 29
; CHECK-NEXT:    mr 5, 3
; CHECK-NEXT:    bne 0, .LBB57_2
; CHECK-NEXT:    b .LBB57_4
; CHECK-NEXT:  .LBB57_3:
; CHECK-NEXT:    # implicit-def: $r5
; CHECK-NEXT:  .LBB57_4: # %for.cond.cleanup
; CHECK-NEXT:    evldd 30, 16(1) # 8-byte Folded Reload
; CHECK-NEXT:    evldd 29, 8(1) # 8-byte Folded Reload
; CHECK-NEXT:    mr 3, 5
; CHECK-NEXT:    lwz 30, 40(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 29, 36(1) # 4-byte Folded Reload
; CHECK-NEXT:    lwz 0, 52(1)
; CHECK-NEXT:    addi 1, 1, 48
; CHECK-NEXT:    mtlr 0
; CHECK-NEXT:    blr
entry:
  %cmp8 = icmp sgt i32 %d, 0
  br i1 %cmp8, label %for.body, label %for.cond.cleanup

for.cond.cleanup:                                 ; preds = %for.body, %entry
  %e.0.lcssa = phi float [ undef, %entry ], [ %0, %for.body ]
  ret float %e.0.lcssa

for.body:                                         ; preds = %for.body, %entry
  %f.010 = phi i32 [ %inc, %for.body ], [ 0, %entry ]
  %e.09 = phi float [ %0, %for.body ], [ undef, %entry ]
  %conv = sitofp i32 %f.010 to float
  %0 = tail call float @llvm.fma.f32(float %conv, float %conv, float %e.09)
  %inc = add nuw nsw i32 %f.010, 1
  %exitcond = icmp eq i32 %inc, %d
  br i1 %exitcond, label %for.cond.cleanup, label %for.body
}

; Function Attrs: nounwind readnone speculatable willreturn
declare float @llvm.fma.f32(float, float, float) #1

attributes #1 = { nounwind readnone speculatable willreturn }
