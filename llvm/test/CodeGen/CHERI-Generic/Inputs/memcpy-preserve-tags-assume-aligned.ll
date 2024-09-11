; Check that __builtin_assume_aligned does the right thing and allows us to elide the memcpy
; call even with must_preserve_cheri_tags attribute (run instcombine to propagate assume information)
; RUN: opt @PURECAP_HARDFLOAT_ARGS@ -S -passes=instcombine < %s | llc @PURECAP_HARDFLOAT_ARGS@ -O2 -o - | FileCheck %s
target datalayout = "@PURECAP_DATALAYOUT@"

declare void @llvm.memcpy.p200.p200.iCAPRANGE(ptr addrspace(200) nocapture writeonly, ptr addrspace(200)  nocapture readonly, iCAPRANGE, i1)
declare void @llvm.memmove.p200.p200.iCAPRANGE(ptr addrspace(200) nocapture writeonly, ptr addrspace(200) nocapture readonly, iCAPRANGE, i1)
declare void @llvm.assume(i1) addrspace(200)

define void @memcpy_assume(ptr addrspace(200) %local_cap_ptr, ptr addrspace(200) %align1) addrspace(200) nounwind {
  %ptrint = ptrtoint ptr addrspace(200) %align1 to iCAPRANGE
  %maskedptr = and iCAPRANGE %ptrint, 15
  %maskcond = icmp eq iCAPRANGE %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  %1 = bitcast ptr addrspace(200) %local_cap_ptr to ptr addrspace(200)
  call void @llvm.memcpy.p200.p200.iCAPRANGE(ptr addrspace(200) align 1 %align1, ptr addrspace(200) align 16 %1, iCAPRANGE 32, i1 false) must_preserve_cheri_tags
  ret void
}

define void @memmove_assume(ptr addrspace(200) %local_cap_ptr, ptr addrspace(200) %align1) addrspace(200) nounwind {
  %ptrint = ptrtoint ptr addrspace(200) %align1 to iCAPRANGE
  %maskedptr = and iCAPRANGE %ptrint, 15
  %maskcond = icmp eq iCAPRANGE %maskedptr, 0
  tail call void @llvm.assume(i1 %maskcond)
  %1 = bitcast ptr addrspace(200) %local_cap_ptr to ptr addrspace(200)
  call void @llvm.memmove.p200.p200.iCAPRANGE(ptr addrspace(200) align 1 %align1, ptr addrspace(200) align 16 %1, iCAPRANGE 32, i1 false) must_preserve_cheri_tags
  ret void
}

