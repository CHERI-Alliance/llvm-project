; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -global-isel -march=amdgcn -mcpu=gfx906 -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX906 %s
; RUN: llc -global-isel -march=amdgcn -mcpu=gfx1011 -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX10 %s
; RUN: llc -global-isel -march=amdgcn -mcpu=gfx1012 -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX10 %s

define i32 @v_udot4(i32 %a, i32 %b, i32 %c) {
; GFX906-LABEL: v_udot4:
; GFX906:       ; %bb.0:
; GFX906-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX906-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX906-NEXT:    s_setpc_b64 s[30:31]
;
; GFX10-LABEL: v_udot4:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX10-NEXT:    ; implicit-def: $vcc_hi
; GFX10-NEXT:    s_setpc_b64 s[30:31]
  %r = call i32 @llvm.amdgcn.udot4(i32 %a, i32 %b, i32 %c, i1 false)
  ret i32 %r
}

define i32 @v_udot4_clamp(i32 %a, i32 %b, i32 %c) {
; GFX906-LABEL: v_udot4_clamp:
; GFX906:       ; %bb.0:
; GFX906-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX906-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2 clamp
; GFX906-NEXT:    s_setpc_b64 s[30:31]
;
; GFX10-LABEL: v_udot4_clamp:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2 clamp
; GFX10-NEXT:    ; implicit-def: $vcc_hi
; GFX10-NEXT:    s_setpc_b64 s[30:31]
  %r = call i32 @llvm.amdgcn.udot4(i32 %a, i32 %b, i32 %c, i1 true)
  ret i32 %r
}

; FIXME: bitcast should not expand
define i32 @v_udot4_cast_v4i8(<4 x i8> %a, <4 x i8> %b, i32 %c) {
; GFX906-LABEL: v_udot4_cast_v4i8:
; GFX906:       ; %bb.0:
; GFX906-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX906-NEXT:    s_movk_i32 s4, 0xff
; GFX906-NEXT:    v_and_b32_e32 v1, s4, v1
; GFX906-NEXT:    v_lshlrev_b16_e32 v1, 8, v1
; GFX906-NEXT:    v_or_b32_sdwa v0, v0, v1 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX906-NEXT:    v_and_b32_e32 v1, s4, v3
; GFX906-NEXT:    v_lshlrev_b16_e32 v1, 8, v1
; GFX906-NEXT:    v_or_b32_sdwa v1, v2, v1 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX906-NEXT:    v_bfe_u32 v0, v0, 0, 16
; GFX906-NEXT:    v_bfe_u32 v1, v1, 0, 16
; GFX906-NEXT:    v_and_b32_e32 v2, s4, v7
; GFX906-NEXT:    v_lshl_or_b32 v0, v1, 16, v0
; GFX906-NEXT:    v_and_b32_e32 v1, s4, v5
; GFX906-NEXT:    v_lshlrev_b16_e32 v1, 8, v1
; GFX906-NEXT:    v_lshlrev_b16_e32 v2, 8, v2
; GFX906-NEXT:    v_or_b32_sdwa v1, v4, v1 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX906-NEXT:    v_or_b32_sdwa v2, v6, v2 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX906-NEXT:    v_bfe_u32 v1, v1, 0, 16
; GFX906-NEXT:    v_bfe_u32 v2, v2, 0, 16
; GFX906-NEXT:    v_lshl_or_b32 v1, v2, 16, v1
; GFX906-NEXT:    v_dot4_u32_u8 v0, v0, v1, v8
; GFX906-NEXT:    s_setpc_b64 s[30:31]
;
; GFX10-LABEL: v_udot4_cast_v4i8:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    s_movk_i32 s4, 0xff
; GFX10-NEXT:    ; implicit-def: $vcc_hi
; GFX10-NEXT:    v_and_b32_sdwa v1, v1, s4 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
; GFX10-NEXT:    v_and_b32_sdwa v3, v3, s4 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
; GFX10-NEXT:    v_and_b32_sdwa v5, v5, s4 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
; GFX10-NEXT:    v_and_b32_sdwa v7, v7, s4 dst_sel:BYTE_1 dst_unused:UNUSED_PAD src0_sel:DWORD src1_sel:DWORD
; GFX10-NEXT:    v_or_b32_sdwa v0, v0, v1 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX10-NEXT:    v_or_b32_sdwa v1, v2, v3 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX10-NEXT:    v_or_b32_sdwa v2, v4, v5 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX10-NEXT:    v_or_b32_sdwa v3, v6, v7 dst_sel:DWORD dst_unused:UNUSED_PAD src0_sel:BYTE_0 src1_sel:DWORD
; GFX10-NEXT:    v_bfe_u32 v0, v0, 0, 16
; GFX10-NEXT:    v_bfe_u32 v1, v1, 0, 16
; GFX10-NEXT:    v_bfe_u32 v2, v2, 0, 16
; GFX10-NEXT:    v_bfe_u32 v3, v3, 0, 16
; GFX10-NEXT:    v_lshl_or_b32 v7, v1, 16, v0
; GFX10-NEXT:    v_lshl_or_b32 v1, v3, 16, v2
; GFX10-NEXT:    v_dot4_u32_u8 v0, v7, v1, v8
; GFX10-NEXT:    s_setpc_b64 s[30:31]
  %a.cast = bitcast <4 x i8> %a to i32
  %b.cast = bitcast <4 x i8> %b to i32
  %r = call i32 @llvm.amdgcn.udot4(i32 %a.cast, i32 %b.cast, i32 %c, i1 false)
  ret i32 %r
}

define i32 @v_udot4_fnegf32_a(float %a, i32 %b, i32 %c) {
; GFX906-LABEL: v_udot4_fnegf32_a:
; GFX906:       ; %bb.0:
; GFX906-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX906-NEXT:    v_xor_b32_e32 v0, 0x80000000, v0
; GFX906-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX906-NEXT:    s_setpc_b64 s[30:31]
;
; GFX10-LABEL: v_udot4_fnegf32_a:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    v_xor_b32_e32 v0, 0x80000000, v0
; GFX10-NEXT:    ; implicit-def: $vcc_hi
; GFX10-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX10-NEXT:    s_setpc_b64 s[30:31]
  %neg.a = fneg float %a
  %cast.neg.a = bitcast float %neg.a to i32
  %r = call i32 @llvm.amdgcn.udot4(i32 %cast.neg.a, i32 %b, i32 %c, i1 false)
  ret i32 %r
}

define i32 @v_udot4_fnegv2f16_a(<2 x half> %a, i32 %b, i32 %c) {
; GFX906-LABEL: v_udot4_fnegv2f16_a:
; GFX906:       ; %bb.0:
; GFX906-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX906-NEXT:    v_xor_b32_e32 v0, 0x80008000, v0
; GFX906-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX906-NEXT:    s_setpc_b64 s[30:31]
;
; GFX10-LABEL: v_udot4_fnegv2f16_a:
; GFX10:       ; %bb.0:
; GFX10-NEXT:    s_waitcnt vmcnt(0) expcnt(0) lgkmcnt(0)
; GFX10-NEXT:    s_waitcnt_vscnt null, 0x0
; GFX10-NEXT:    v_xor_b32_e32 v0, 0x80008000, v0
; GFX10-NEXT:    ; implicit-def: $vcc_hi
; GFX10-NEXT:    v_dot4_u32_u8 v0, v0, v1, v2
; GFX10-NEXT:    s_setpc_b64 s[30:31]
  %neg.a = fneg <2 x half> %a
  %cast.neg.a = bitcast <2 x half> %neg.a to i32
  %r = call i32 @llvm.amdgcn.udot4(i32 %cast.neg.a, i32 %b, i32 %c, i1 false)
  ret i32 %r
}

declare i32 @llvm.amdgcn.udot4(i32, i32, i32, i1 immarg) #0

attributes #0 = { nounwind readnone speculatable }
