; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=i686-unknown -mattr=+sse4.1 | FileCheck %s --check-prefix=X32
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+sse4.1 | FileCheck %s --check-prefix=X64

define <2 x i64> @shl1(<4 x i32> %r, <4 x i32> %a) nounwind readnone ssp {
; X32-LABEL: shl1:
; X32:       # %bb.0: # %entry
; X32-NEXT:    pslld $23, %xmm1
; X32-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X32-NEXT:    cvttps2dq %xmm1, %xmm1
; X32-NEXT:    pmulld %xmm1, %xmm0
; X32-NEXT:    retl
;
; X64-LABEL: shl1:
; X64:       # %bb.0: # %entry
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    pmulld %xmm1, %xmm0
; X64-NEXT:    retq
entry:
; CHECK-NOT: shll
; CHECK: pslld
; CHECK: paddd
; CHECK: cvttps2dq
; CHECK: pmulld

  %shl = shl <4 x i32> %r, %a                     ; <<4 x i32>> [#uses=1]
  %tmp2 = bitcast <4 x i32> %shl to <2 x i64>     ; <<2 x i64>> [#uses=1]
  ret <2 x i64> %tmp2
}

define <2 x i64> @shl2(<16 x i8> %r, <16 x i8> %a) nounwind readnone ssp {
; X32-LABEL: shl2:
; X32:       # %bb.0: # %entry
; X32-NEXT:    movdqa %xmm0, %xmm2
; X32-NEXT:    psllw $5, %xmm1
; X32-NEXT:    movdqa %xmm2, %xmm3
; X32-NEXT:    psllw $4, %xmm3
; X32-NEXT:    pand {{\.LCPI.*}}, %xmm3
; X32-NEXT:    movdqa %xmm1, %xmm0
; X32-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X32-NEXT:    movdqa %xmm2, %xmm3
; X32-NEXT:    psllw $2, %xmm3
; X32-NEXT:    pand {{\.LCPI.*}}, %xmm3
; X32-NEXT:    paddb %xmm1, %xmm1
; X32-NEXT:    movdqa %xmm1, %xmm0
; X32-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X32-NEXT:    movdqa %xmm2, %xmm3
; X32-NEXT:    paddb %xmm3, %xmm3
; X32-NEXT:    paddb %xmm1, %xmm1
; X32-NEXT:    movdqa %xmm1, %xmm0
; X32-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X32-NEXT:    movdqa %xmm2, %xmm0
; X32-NEXT:    retl
;
; X64-LABEL: shl2:
; X64:       # %bb.0: # %entry
; X64-NEXT:    movdqa %xmm0, %xmm2
; X64-NEXT:    psllw $5, %xmm1
; X64-NEXT:    movdqa %xmm2, %xmm3
; X64-NEXT:    psllw $4, %xmm3
; X64-NEXT:    pand {{.*}}(%rip), %xmm3
; X64-NEXT:    movdqa %xmm1, %xmm0
; X64-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X64-NEXT:    movdqa %xmm2, %xmm3
; X64-NEXT:    psllw $2, %xmm3
; X64-NEXT:    pand {{.*}}(%rip), %xmm3
; X64-NEXT:    paddb %xmm1, %xmm1
; X64-NEXT:    movdqa %xmm1, %xmm0
; X64-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X64-NEXT:    movdqa %xmm2, %xmm3
; X64-NEXT:    paddb %xmm3, %xmm3
; X64-NEXT:    paddb %xmm1, %xmm1
; X64-NEXT:    movdqa %xmm1, %xmm0
; X64-NEXT:    pblendvb %xmm0, %xmm3, %xmm2
; X64-NEXT:    movdqa %xmm2, %xmm0
; X64-NEXT:    retq
entry:
; CHECK-NOT: shlb
; CHECK: pblendvb
; CHECK: pblendvb
; CHECK: pblendvb
  %shl = shl <16 x i8> %r, %a                     ; <<16 x i8>> [#uses=1]
  %tmp2 = bitcast <16 x i8> %shl to <2 x i64>     ; <<2 x i64>> [#uses=1]
  ret <2 x i64> %tmp2
}
