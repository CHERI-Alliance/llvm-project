; RUN: sed s/_ADDRTYPE_/i64/g %s > %t.64.ll
; RUN: sed s/_ADDRTYPE_/i32/g %s > %t.32.ll
; RUN: llc -mtriple=riscv64-codasip-linux-musl -mattr=+zcherihybrid -o - %t.64.ll | FileCheck %s
; RUN: llc -mtriple=riscv32-codasip-linux-musl -mattr=+zcherihybrid -o - %t.32.ll | FileCheck %s

define dso_local _ADDRTYPE_ @pccGetAddr() local_unnamed_addr {
; CHECK-LABEL: pccGetAddr:
; CHECK:       # %bb.0:
; CHECK-NEXT:    .option capmode
; CHECK-NEXT:    modesw.cap
; CHECK-NEXT:    auipc ca0, 0
; CHECK-NEXT:    .option nocapmode
; CHECK-NEXT:    modesw.int
; CHECK-NEXT:    mv a0, a0
; CHECK-NEXT:    ret
  %1 = tail call ptr addrspace(200) @llvm.cheri.pcc.get()
  %2 = tail call _ADDRTYPE_ @llvm.cheri.cap.address.get._ADDRTYPE_(ptr addrspace(200) %1)
  ret _ADDRTYPE_ %2
}

declare ptr addrspace(200) @llvm.cheri.pcc.get()
declare _ADDRTYPE_ @llvm.cheri.cap.address.get._ADDRTYPE_(ptr addrspace(200))

