; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512vl,+avx512bw,+prefer-256-bit | FileCheck %s --check-prefix=CHECK --check-prefix=AVX256BW
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512vl,+avx512bw,-prefer-256-bit | FileCheck %s --check-prefix=CHECK --check-prefix=AVX512BW
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512bw,+prefer-256-bit | FileCheck %s --check-prefix=CHECK --check-prefix=AVX512BW
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -mattr=+avx512bw,-prefer-256-bit | FileCheck %s --check-prefix=CHECK --check-prefix=AVX512BW

define <32 x i8> @test_div7_32i8(<32 x i8> %a) {
; AVX256BW-LABEL: test_div7_32i8:
; AVX256BW:       # %bb.0:
; AVX256BW-NEXT:    vextracti128 $1, %ymm0, %xmm1
; AVX256BW-NEXT:    vpmovzxbw {{.*#+}} ymm1 = xmm1[0],zero,xmm1[1],zero,xmm1[2],zero,xmm1[3],zero,xmm1[4],zero,xmm1[5],zero,xmm1[6],zero,xmm1[7],zero,xmm1[8],zero,xmm1[9],zero,xmm1[10],zero,xmm1[11],zero,xmm1[12],zero,xmm1[13],zero,xmm1[14],zero,xmm1[15],zero
; AVX256BW-NEXT:    vmovdqa {{.*#+}} ymm2 = [37,37,37,37,37,37,37,37,37,37,37,37,37,37,37,37]
; AVX256BW-NEXT:    vpmullw %ymm2, %ymm1, %ymm1
; AVX256BW-NEXT:    vpsrlw $8, %ymm1, %ymm1
; AVX256BW-NEXT:    vpmovzxbw {{.*#+}} ymm3 = xmm0[0],zero,xmm0[1],zero,xmm0[2],zero,xmm0[3],zero,xmm0[4],zero,xmm0[5],zero,xmm0[6],zero,xmm0[7],zero,xmm0[8],zero,xmm0[9],zero,xmm0[10],zero,xmm0[11],zero,xmm0[12],zero,xmm0[13],zero,xmm0[14],zero,xmm0[15],zero
; AVX256BW-NEXT:    vpmullw %ymm2, %ymm3, %ymm2
; AVX256BW-NEXT:    vpsrlw $8, %ymm2, %ymm2
; AVX256BW-NEXT:    vpackuswb %ymm1, %ymm2, %ymm1
; AVX256BW-NEXT:    vpermq {{.*#+}} ymm1 = ymm1[0,2,1,3]
; AVX256BW-NEXT:    vpsubb %ymm1, %ymm0, %ymm0
; AVX256BW-NEXT:    vpsrlw $1, %ymm0, %ymm0
; AVX256BW-NEXT:    vpand {{.*}}(%rip), %ymm0, %ymm0
; AVX256BW-NEXT:    vpaddb %ymm1, %ymm0, %ymm0
; AVX256BW-NEXT:    vpsrlw $2, %ymm0, %ymm0
; AVX256BW-NEXT:    vpand {{.*}}(%rip), %ymm0, %ymm0
; AVX256BW-NEXT:    retq
;
; AVX512BW-LABEL: test_div7_32i8:
; AVX512BW:       # %bb.0:
; AVX512BW-NEXT:    vpmovzxbw {{.*#+}} zmm1 = ymm0[0],zero,ymm0[1],zero,ymm0[2],zero,ymm0[3],zero,ymm0[4],zero,ymm0[5],zero,ymm0[6],zero,ymm0[7],zero,ymm0[8],zero,ymm0[9],zero,ymm0[10],zero,ymm0[11],zero,ymm0[12],zero,ymm0[13],zero,ymm0[14],zero,ymm0[15],zero,ymm0[16],zero,ymm0[17],zero,ymm0[18],zero,ymm0[19],zero,ymm0[20],zero,ymm0[21],zero,ymm0[22],zero,ymm0[23],zero,ymm0[24],zero,ymm0[25],zero,ymm0[26],zero,ymm0[27],zero,ymm0[28],zero,ymm0[29],zero,ymm0[30],zero,ymm0[31],zero
; AVX512BW-NEXT:    vpmullw {{.*}}(%rip), %zmm1, %zmm1
; AVX512BW-NEXT:    vpsrlw $8, %zmm1, %zmm1
; AVX512BW-NEXT:    vpmovwb %zmm1, %ymm1
; AVX512BW-NEXT:    vpsubb %ymm1, %ymm0, %ymm0
; AVX512BW-NEXT:    vpsrlw $1, %ymm0, %ymm0
; AVX512BW-NEXT:    vpand {{.*}}(%rip), %ymm0, %ymm0
; AVX512BW-NEXT:    vpaddb %ymm1, %ymm0, %ymm0
; AVX512BW-NEXT:    vpsrlw $2, %ymm0, %ymm0
; AVX512BW-NEXT:    vpand {{.*}}(%rip), %ymm0, %ymm0
; AVX512BW-NEXT:    retq
  %res = udiv <32 x i8> %a, <i8 7, i8 7, i8 7, i8 7,i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7,i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7,i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7, i8 7,i8 7, i8 7, i8 7, i8 7>
  ret <32 x i8> %res
}

define <32 x i8> @test_mul_32i8(<32 x i8> %a, <32 x i8> %b) {
; AVX256BW-LABEL: test_mul_32i8:
; AVX256BW:       # %bb.0:
; AVX256BW-NEXT:    vpunpckhbw {{.*#+}} ymm2 = ymm1[8],ymm0[8],ymm1[9],ymm0[9],ymm1[10],ymm0[10],ymm1[11],ymm0[11],ymm1[12],ymm0[12],ymm1[13],ymm0[13],ymm1[14],ymm0[14],ymm1[15],ymm0[15],ymm1[24],ymm0[24],ymm1[25],ymm0[25],ymm1[26],ymm0[26],ymm1[27],ymm0[27],ymm1[28],ymm0[28],ymm1[29],ymm0[29],ymm1[30],ymm0[30],ymm1[31],ymm0[31]
; AVX256BW-NEXT:    vpunpckhbw {{.*#+}} ymm3 = ymm0[8,8,9,9,10,10,11,11,12,12,13,13,14,14,15,15,24,24,25,25,26,26,27,27,28,28,29,29,30,30,31,31]
; AVX256BW-NEXT:    vpmullw %ymm2, %ymm3, %ymm2
; AVX256BW-NEXT:    vmovdqa {{.*#+}} ymm3 = [255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255]
; AVX256BW-NEXT:    vpand %ymm3, %ymm2, %ymm2
; AVX256BW-NEXT:    vpunpcklbw {{.*#+}} ymm1 = ymm1[0],ymm0[0],ymm1[1],ymm0[1],ymm1[2],ymm0[2],ymm1[3],ymm0[3],ymm1[4],ymm0[4],ymm1[5],ymm0[5],ymm1[6],ymm0[6],ymm1[7],ymm0[7],ymm1[16],ymm0[16],ymm1[17],ymm0[17],ymm1[18],ymm0[18],ymm1[19],ymm0[19],ymm1[20],ymm0[20],ymm1[21],ymm0[21],ymm1[22],ymm0[22],ymm1[23],ymm0[23]
; AVX256BW-NEXT:    vpunpcklbw {{.*#+}} ymm0 = ymm0[0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,16,16,17,17,18,18,19,19,20,20,21,21,22,22,23,23]
; AVX256BW-NEXT:    vpmullw %ymm1, %ymm0, %ymm0
; AVX256BW-NEXT:    vpand %ymm3, %ymm0, %ymm0
; AVX256BW-NEXT:    vpackuswb %ymm2, %ymm0, %ymm0
; AVX256BW-NEXT:    retq
;
; AVX512BW-LABEL: test_mul_32i8:
; AVX512BW:       # %bb.0:
; AVX512BW-NEXT:    vpmovzxbw {{.*#+}} zmm1 = ymm1[0],zero,ymm1[1],zero,ymm1[2],zero,ymm1[3],zero,ymm1[4],zero,ymm1[5],zero,ymm1[6],zero,ymm1[7],zero,ymm1[8],zero,ymm1[9],zero,ymm1[10],zero,ymm1[11],zero,ymm1[12],zero,ymm1[13],zero,ymm1[14],zero,ymm1[15],zero,ymm1[16],zero,ymm1[17],zero,ymm1[18],zero,ymm1[19],zero,ymm1[20],zero,ymm1[21],zero,ymm1[22],zero,ymm1[23],zero,ymm1[24],zero,ymm1[25],zero,ymm1[26],zero,ymm1[27],zero,ymm1[28],zero,ymm1[29],zero,ymm1[30],zero,ymm1[31],zero
; AVX512BW-NEXT:    vpmovzxbw {{.*#+}} zmm0 = ymm0[0],zero,ymm0[1],zero,ymm0[2],zero,ymm0[3],zero,ymm0[4],zero,ymm0[5],zero,ymm0[6],zero,ymm0[7],zero,ymm0[8],zero,ymm0[9],zero,ymm0[10],zero,ymm0[11],zero,ymm0[12],zero,ymm0[13],zero,ymm0[14],zero,ymm0[15],zero,ymm0[16],zero,ymm0[17],zero,ymm0[18],zero,ymm0[19],zero,ymm0[20],zero,ymm0[21],zero,ymm0[22],zero,ymm0[23],zero,ymm0[24],zero,ymm0[25],zero,ymm0[26],zero,ymm0[27],zero,ymm0[28],zero,ymm0[29],zero,ymm0[30],zero,ymm0[31],zero
; AVX512BW-NEXT:    vpmullw %zmm1, %zmm0, %zmm0
; AVX512BW-NEXT:    vpmovwb %zmm0, %ymm0
; AVX512BW-NEXT:    retq
  %res = mul <32 x i8> %a, %b
  ret <32 x i8> %res
}
