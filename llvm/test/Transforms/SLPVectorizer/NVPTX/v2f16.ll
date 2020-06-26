; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt < %s -basic-aa -slp-vectorizer -S -mtriple=nvptx64-nvidia-cuda -mcpu=sm_70 | FileCheck %s
; RUN: opt < %s -basic-aa -slp-vectorizer -S -mtriple=nvptx64-nvidia-cuda -mcpu=sm_40 | FileCheck %s -check-prefix=NOVECTOR

define void @fusion(i8* noalias nocapture align 256 dereferenceable(19267584) %arg, i8* noalias nocapture readonly align 256 dereferenceable(19267584) %arg1, i32 %arg2, i32 %arg3) local_unnamed_addr #0 {
; CHECK-LABEL: @fusion(
; CHECK-NEXT:    [[TMP:%.*]] = shl nuw nsw i32 [[ARG2:%.*]], 6
; CHECK-NEXT:    [[TMP4:%.*]] = or i32 [[TMP]], [[ARG3:%.*]]
; CHECK-NEXT:    [[TMP5:%.*]] = shl nuw nsw i32 [[TMP4]], 2
; CHECK-NEXT:    [[TMP6:%.*]] = zext i32 [[TMP5]] to i64
; CHECK-NEXT:    [[TMP7:%.*]] = or i64 [[TMP6]], 1
; CHECK-NEXT:    [[TMP10:%.*]] = bitcast i8* [[ARG1:%.*]] to half*
; CHECK-NEXT:    [[TMP11:%.*]] = getelementptr inbounds half, half* [[TMP10]], i64 [[TMP6]]
; CHECK-NEXT:    [[TMP15:%.*]] = bitcast i8* [[ARG:%.*]] to half*
; CHECK-NEXT:    [[TMP16:%.*]] = getelementptr inbounds half, half* [[TMP15]], i64 [[TMP6]]
; CHECK-NEXT:    [[TMP17:%.*]] = getelementptr inbounds half, half* [[TMP10]], i64 [[TMP7]]
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast half* [[TMP11]] to <2 x half>*
; CHECK-NEXT:    [[TMP2:%.*]] = load <2 x half>, <2 x half>* [[TMP1]], align 8
; CHECK-NEXT:    [[TMP3:%.*]] = fmul fast <2 x half> [[TMP2]], <half 0xH5380, half 0xH5380>
; CHECK-NEXT:    [[TMP4:%.*]] = fadd fast <2 x half> [[TMP3]], <half 0xH57F0, half 0xH57F0>
; CHECK-NEXT:    [[TMP21:%.*]] = getelementptr inbounds half, half* [[TMP15]], i64 [[TMP7]]
; CHECK-NEXT:    [[TMP5:%.*]] = bitcast half* [[TMP16]] to <2 x half>*
; CHECK-NEXT:    store <2 x half> [[TMP4]], <2 x half>* [[TMP5]], align 8
; CHECK-NEXT:    ret void
;
; NOVECTOR-LABEL: @fusion(
; NOVECTOR-NEXT:    [[TMP:%.*]] = shl nuw nsw i32 [[ARG2:%.*]], 6
; NOVECTOR-NEXT:    [[TMP4:%.*]] = or i32 [[TMP]], [[ARG3:%.*]]
; NOVECTOR-NEXT:    [[TMP5:%.*]] = shl nuw nsw i32 [[TMP4]], 2
; NOVECTOR-NEXT:    [[TMP6:%.*]] = zext i32 [[TMP5]] to i64
; NOVECTOR-NEXT:    [[TMP7:%.*]] = or i64 [[TMP6]], 1
; NOVECTOR-NEXT:    [[TMP10:%.*]] = bitcast i8* [[ARG1:%.*]] to half*
; NOVECTOR-NEXT:    [[TMP11:%.*]] = getelementptr inbounds half, half* [[TMP10]], i64 [[TMP6]]
; NOVECTOR-NEXT:    [[TMP12:%.*]] = load half, half* [[TMP11]], align 8
; NOVECTOR-NEXT:    [[TMP13:%.*]] = fmul fast half [[TMP12]], 0xH5380
; NOVECTOR-NEXT:    [[TMP14:%.*]] = fadd fast half [[TMP13]], 0xH57F0
; NOVECTOR-NEXT:    [[TMP15:%.*]] = bitcast i8* [[ARG:%.*]] to half*
; NOVECTOR-NEXT:    [[TMP16:%.*]] = getelementptr inbounds half, half* [[TMP15]], i64 [[TMP6]]
; NOVECTOR-NEXT:    store half [[TMP14]], half* [[TMP16]], align 8
; NOVECTOR-NEXT:    [[TMP17:%.*]] = getelementptr inbounds half, half* [[TMP10]], i64 [[TMP7]]
; NOVECTOR-NEXT:    [[TMP18:%.*]] = load half, half* [[TMP17]], align 2
; NOVECTOR-NEXT:    [[TMP19:%.*]] = fmul fast half [[TMP18]], 0xH5380
; NOVECTOR-NEXT:    [[TMP20:%.*]] = fadd fast half [[TMP19]], 0xH57F0
; NOVECTOR-NEXT:    [[TMP21:%.*]] = getelementptr inbounds half, half* [[TMP15]], i64 [[TMP7]]
; NOVECTOR-NEXT:    store half [[TMP20]], half* [[TMP21]], align 2
; NOVECTOR-NEXT:    ret void
;
  %tmp = shl nuw nsw i32 %arg2, 6
  %tmp4 = or i32 %tmp, %arg3
  %tmp5 = shl nuw nsw i32 %tmp4, 2
  %tmp6 = zext i32 %tmp5 to i64
  %tmp7 = or i64 %tmp6, 1
  %tmp10 = bitcast i8* %arg1 to half*
  %tmp11 = getelementptr inbounds half, half* %tmp10, i64 %tmp6
  %tmp12 = load half, half* %tmp11, align 8
  %tmp13 = fmul fast half %tmp12, 0xH5380
  %tmp14 = fadd fast half %tmp13, 0xH57F0
  %tmp15 = bitcast i8* %arg to half*
  %tmp16 = getelementptr inbounds half, half* %tmp15, i64 %tmp6
  store half %tmp14, half* %tmp16, align 8
  %tmp17 = getelementptr inbounds half, half* %tmp10, i64 %tmp7
  %tmp18 = load half, half* %tmp17, align 2
  %tmp19 = fmul fast half %tmp18, 0xH5380
  %tmp20 = fadd fast half %tmp19, 0xH57F0
  %tmp21 = getelementptr inbounds half, half* %tmp15, i64 %tmp7
  store half %tmp20, half* %tmp21, align 2
  ret void
}

attributes #0 = { nounwind }
