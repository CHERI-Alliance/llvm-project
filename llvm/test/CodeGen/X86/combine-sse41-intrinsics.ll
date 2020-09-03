; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=sse4.1 | FileCheck %s --check-prefixes=CHECK,SSE
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=avx    | FileCheck %s --check-prefixes=CHECK,AVX


define <2 x double> @test_x86_sse41_blend_pd(<2 x double> %a0, <2 x double> %a1) {
; CHECK-LABEL: test_x86_sse41_blend_pd:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <2 x double> @llvm.x86.sse41.blendpd(<2 x double> %a0, <2 x double> %a1, i32 0)
  ret <2 x double> %1
}

define <4 x float> @test_x86_sse41_blend_ps(<4 x float> %a0, <4 x float> %a1) {
; CHECK-LABEL: test_x86_sse41_blend_ps:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <4 x float> @llvm.x86.sse41.blendps(<4 x float> %a0, <4 x float> %a1, i32 0)
  ret <4 x float> %1
}

define <8 x i16> @test_x86_sse41_pblend_w(<8 x i16> %a0, <8 x i16> %a1) {
; CHECK-LABEL: test_x86_sse41_pblend_w:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <8 x i16> @llvm.x86.sse41.pblendw(<8 x i16> %a0, <8 x i16> %a1, i32 0)
  ret <8 x i16> %1
}

define <2 x double> @test2_x86_sse41_blend_pd(<2 x double> %a0, <2 x double> %a1) {
; SSE-LABEL: test2_x86_sse41_blend_pd:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: test2_x86_sse41_blend_pd:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = call <2 x double> @llvm.x86.sse41.blendpd(<2 x double> %a0, <2 x double> %a1, i32 -1)
  ret <2 x double> %1
}

define <4 x float> @test2_x86_sse41_blend_ps(<4 x float> %a0, <4 x float> %a1) {
; SSE-LABEL: test2_x86_sse41_blend_ps:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: test2_x86_sse41_blend_ps:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = call <4 x float> @llvm.x86.sse41.blendps(<4 x float> %a0, <4 x float> %a1, i32 -1)
  ret <4 x float> %1
}

define <8 x i16> @test2_x86_sse41_pblend_w(<8 x i16> %a0, <8 x i16> %a1) {
; SSE-LABEL: test2_x86_sse41_pblend_w:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: test2_x86_sse41_pblend_w:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = call <8 x i16> @llvm.x86.sse41.pblendw(<8 x i16> %a0, <8 x i16> %a1, i32 -1)
  ret <8 x i16> %1
}

define <2 x double> @test3_x86_sse41_blend_pd(<2 x double> %a0) {
; CHECK-LABEL: test3_x86_sse41_blend_pd:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <2 x double> @llvm.x86.sse41.blendpd(<2 x double> %a0, <2 x double> %a0, i32 7)
  ret <2 x double> %1
}

define <4 x float> @test3_x86_sse41_blend_ps(<4 x float> %a0) {
; CHECK-LABEL: test3_x86_sse41_blend_ps:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <4 x float> @llvm.x86.sse41.blendps(<4 x float> %a0, <4 x float> %a0, i32 7)
  ret <4 x float> %1
}

define <8 x i16> @test3_x86_sse41_pblend_w(<8 x i16> %a0) {
; CHECK-LABEL: test3_x86_sse41_pblend_w:
; CHECK:       # %bb.0:
; CHECK-NEXT:    retq
  %1 = call <8 x i16> @llvm.x86.sse41.pblendw(<8 x i16> %a0, <8 x i16> %a0, i32 7)
  ret <8 x i16> %1
}

define double @demandedelts_blendvpd(<2 x double> %a0, <2 x double> %a1, <2 x double> %a2) {
; SSE-LABEL: demandedelts_blendvpd:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd %xmm0, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    blendvpd %xmm0, %xmm1, %xmm3
; SSE-NEXT:    movapd %xmm3, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: demandedelts_blendvpd:
; AVX:       # %bb.0:
; AVX-NEXT:    vblendvpd %xmm2, %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = shufflevector <2 x double> %a0, <2 x double> undef, <2 x i32> zeroinitializer
  %2 = shufflevector <2 x double> %a1, <2 x double> undef, <2 x i32> zeroinitializer
  %3 = shufflevector <2 x double> %a2, <2 x double> undef, <2 x i32> zeroinitializer
  %4 = tail call <2 x double> @llvm.x86.sse41.blendvpd(<2 x double> %1, <2 x double> %2, <2 x double> %3)
  %5 = extractelement <2 x double> %4, i32 0
  ret double %5
}

define float @demandedelts_blendvps(<4 x float> %a0, <4 x float> %a1, <4 x float> %a2) {
; SSE-LABEL: demandedelts_blendvps:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps %xmm0, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    blendvps %xmm0, %xmm1, %xmm3
; SSE-NEXT:    movaps %xmm3, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: demandedelts_blendvps:
; AVX:       # %bb.0:
; AVX-NEXT:    vblendvps %xmm2, %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = shufflevector <4 x float> %a0, <4 x float> undef, <4 x i32> zeroinitializer
  %2 = shufflevector <4 x float> %a1, <4 x float> undef, <4 x i32> zeroinitializer
  %3 = shufflevector <4 x float> %a2, <4 x float> undef, <4 x i32> zeroinitializer
  %4 = tail call <4 x float> @llvm.x86.sse41.blendvps(<4 x float> %1, <4 x float> %2, <4 x float> %3)
  %5 = extractelement <4 x float> %4, i32 0
  ret float %5
}

define <16 x i8> @demandedelts_pblendvb(<16 x i8> %a0, <16 x i8> %a1, <16 x i8> %a2) {
; SSE-LABEL: demandedelts_pblendvb:
; SSE:       # %bb.0:
; SSE-NEXT:    movdqa %xmm0, %xmm3
; SSE-NEXT:    movdqa %xmm2, %xmm0
; SSE-NEXT:    pblendvb %xmm0, %xmm1, %xmm3
; SSE-NEXT:    pxor %xmm0, %xmm0
; SSE-NEXT:    pshufb %xmm0, %xmm3
; SSE-NEXT:    movdqa %xmm3, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: demandedelts_pblendvb:
; AVX:       # %bb.0:
; AVX-NEXT:    vpblendvb %xmm2, %xmm1, %xmm0, %xmm0
; AVX-NEXT:    vpxor %xmm1, %xmm1, %xmm1
; AVX-NEXT:    vpshufb %xmm1, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1 = shufflevector <16 x i8> %a0, <16 x i8> undef, <16 x i32> zeroinitializer
  %2 = shufflevector <16 x i8> %a1, <16 x i8> undef, <16 x i32> zeroinitializer
  %3 = shufflevector <16 x i8> %a2, <16 x i8> undef, <16 x i32> zeroinitializer
  %4 = tail call <16 x i8> @llvm.x86.sse41.pblendvb(<16 x i8> %1, <16 x i8> %2, <16 x i8> %3)
  %5 = shufflevector <16 x i8> %4, <16 x i8> undef, <16 x i32> zeroinitializer
  ret <16 x i8> %5
}

define <2 x i64> @demandedbits_blendvpd(i64 %a0, i64 %a2, <2 x double> %a3) {
; SSE-LABEL: demandedbits_blendvpd:
; SSE:       # %bb.0:
; SSE-NEXT:    movq %rdi, %rax
; SSE-NEXT:    orq $1, %rax
; SSE-NEXT:    orq $4, %rdi
; SSE-NEXT:    movq %rax, %xmm1
; SSE-NEXT:    movq %rdi, %xmm2
; SSE-NEXT:    movq {{.*#+}} xmm1 = xmm1[0],zero
; SSE-NEXT:    movq {{.*#+}} xmm2 = xmm2[0],zero
; SSE-NEXT:    blendvpd %xmm0, %xmm2, %xmm1
; SSE-NEXT:    psrlq $11, %xmm1
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: demandedbits_blendvpd:
; AVX:       # %bb.0:
; AVX-NEXT:    movq %rdi, %rax
; AVX-NEXT:    orq $1, %rax
; AVX-NEXT:    orq $4, %rdi
; AVX-NEXT:    vmovq %rax, %xmm1
; AVX-NEXT:    vmovq %rdi, %xmm2
; AVX-NEXT:    vmovq {{.*#+}} xmm1 = xmm1[0],zero
; AVX-NEXT:    vmovq {{.*#+}} xmm2 = xmm2[0],zero
; AVX-NEXT:    vblendvpd %xmm0, %xmm2, %xmm1, %xmm0
; AVX-NEXT:    vpsrlq $11, %xmm0, %xmm0
; AVX-NEXT:    retq
  %1  = or i64 %a0, 1
  %2  = or i64 %a0, 4
  %3  = bitcast i64 %1 to double
  %4  = bitcast i64 %2 to double
  %5  = insertelement <2 x double> zeroinitializer, double %3, i32 0
  %6  = insertelement <2 x double> zeroinitializer, double %4, i32 0
  %7  = tail call <2 x double> @llvm.x86.sse41.blendvpd(<2 x double> %5, <2 x double> %6, <2 x double> %a3)
  %8  = bitcast <2 x double> %7 to <2 x i64>
  %9  = lshr <2 x i64> %8, <i64 11, i64 11>
  ret <2 x i64> %9
}

define <16 x i8> @xor_pblendvb(<16 x i8> %a0, <16 x i8> %a1, <16 x i8> %a2) {
; SSE-LABEL: xor_pblendvb:
; SSE:       # %bb.0:
; SSE-NEXT:    movdqa %xmm0, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    pblendvb %xmm0, %xmm3, %xmm1
; SSE-NEXT:    movdqa %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: xor_pblendvb:
; AVX:       # %bb.0:
; AVX-NEXT:    vpblendvb %xmm2, %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = xor <16 x i8> %a2, <i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1, i8 -1>
  %2 = tail call <16 x i8> @llvm.x86.sse41.pblendvb(<16 x i8> %a0, <16 x i8> %a1, <16 x i8> %1)
  ret <16 x i8> %2
}

define <4 x float> @xor_blendvps(<4 x float> %a0, <4 x float> %a1, <4 x float> %a2) {
; SSE-LABEL: xor_blendvps:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps %xmm0, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    blendvps %xmm0, %xmm3, %xmm1
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: xor_blendvps:
; AVX:       # %bb.0:
; AVX-NEXT:    vblendvps %xmm2, %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = bitcast <4 x float> %a2 to <4 x i32>
  %2 = xor <4 x i32> %1, <i32 -1, i32 -1, i32 -1, i32 -1>
  %3 = bitcast <4 x i32> %2 to <4 x float>
  %4 = tail call <4 x float> @llvm.x86.sse41.blendvps(<4 x float> %a0, <4 x float> %a1, <4 x float> %3)
  ret <4 x float> %4
}

define <2 x double> @xor_blendvpd(<2 x double> %a0, <2 x double> %a1, <2 x double> %a2) {
; SSE-LABEL: xor_blendvpd:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd %xmm0, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    blendvpd %xmm0, %xmm3, %xmm1
; SSE-NEXT:    movapd %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: xor_blendvpd:
; AVX:       # %bb.0:
; AVX-NEXT:    vblendvpd %xmm2, %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
  %1 = bitcast <2 x double> %a2 to <4 x i32>
  %2 = xor <4 x i32> %1, <i32 -1, i32 -1, i32 -1, i32 -1>
  %3 = bitcast <4 x i32> %2 to <2 x double>
  %4 = tail call <2 x double> @llvm.x86.sse41.blendvpd(<2 x double> %a0, <2 x double> %a1, <2 x double> %3)
  ret <2 x double> %4
}

declare <2 x double> @llvm.x86.sse41.blendpd(<2 x double>, <2 x double>, i32)
declare <4 x float> @llvm.x86.sse41.blendps(<4 x float>, <4 x float>, i32)
declare <8 x i16> @llvm.x86.sse41.pblendw(<8 x i16>, <8 x i16>, i32)

declare <2 x double> @llvm.x86.sse41.blendvpd(<2 x double>, <2 x double>, <2 x double>)
declare <4 x float> @llvm.x86.sse41.blendvps(<4 x float>, <4 x float>, <4 x float>)
declare <16 x i8> @llvm.x86.sse41.pblendvb(<16 x i8>, <16 x i8>, <16 x i8>)
