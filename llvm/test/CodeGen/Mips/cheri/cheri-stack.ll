; RUN: %cheri_purecap_llc -O0 %s -o - | %cheri_FileCheck %s -check-prefixes CHECK
; ModuleID = 'cheri-stack.c'

declare i32 @use_arg(ptr addrspace(200))

define i32 @no_stack() local_unnamed_addr {
entry:
; Check that a function that doesn't use the stack doesn't manipulate the stack
; pointer.  Note that at higher optimisation levels, the delay slot would be
; filled with the addiu.
; CHECK-LABEL: no_stack
; CHECK: addiu	$2, $zero, 1
; CHECK-NEXT: cjr	$c17
; CHECK-NEXT: nop
  ret i32 1
}

define i32 @has_alloca() local_unnamed_addr {
entry:
; Check that a function that allocates a buffer on the stack correctly derives
; it from the frame capability
; CHECK-LABEL: has_alloca
; CHECK: cincoffset	$c[[ALLOCREG:([0-9]+|sp)]], $c11, [[#CAP_SIZE - 4]]
; CHECK-NEXT: csetbounds	$c3, $c[[ALLOCREG]], 4
  %var = alloca i32, align 4, addrspace(200)
  %0 = bitcast ptr addrspace(200) %var to ptr addrspace(200)
  call void @llvm.lifetime.start.p200(i64 4, ptr addrspace(200) nonnull %0)
  %call = call i32 @use_arg(ptr addrspace(200) nonnull %var)
  call void @llvm.lifetime.end.p200(i64 4, ptr addrspace(200) nonnull %0)
  ret i32 %call
}

define i32 @has_spill(i32 signext %x) local_unnamed_addr {
entry:
; Check that we spill and reload relative to the correct frame capability and
; that we're loading from the same place that we spill
; CHECK-LABEL: has_spill
;
; CHECK: cincoffset	$c11, $c11, -[[#FRAMESIZE:]]
; CHECK: csc	$c17, $zero, [[C17OFFSET:([0-9]+|sp)]]($c11)
; CHECK: csw    ${{([0-9]+)}}, $zero, [[#CAP_SIZE - 8]]($c11)
; CHECK: clcbi $c12, %capcall20(use_arg)
; CHECK: cjalr	$c12, $c17
; CHECK: clw	${{([0-9]+)}}, $zero, [[#CAP_SIZE - 8]]($c11)
; CHECK: clc	$c17, $zero, [[C17OFFSET]]($c11)
; CHECK: cincoffset	$c11, $c11, [[#FRAMESIZE]]

  %x.addr = alloca i32, align 4, addrspace(200)
  store i32 %x, ptr addrspace(200) %x.addr, align 4
  %call = call i32 @use_arg(ptr addrspace(200) nonnull %x.addr)
  %add = add nsw i32 %call, %x
  ret i32 %add
}

define i32 @dynamic_alloca(i64 %x) local_unnamed_addr {
entry:
; Check that we are able to handle dynamic allocations
; Again, because we're at -O0, we get a load of redundant copies
; CHECK-LABEL: dynamic_alloca
; CHECK: cincoffset	$c24, $c11, $zero
; CHECK:      dsll $1, $4, 2
; CHECK:   croundrepresentablelength $[[REPRSIZE:[0-9]+]], $[[SIZE:[0-9]+]]
; CHECK:      cmove $c[[TEMPCAP:[0-9]+]], $c11
; CHECK-NEXT: cgetaddr	$[[ADDR:([0-9]+|sp)]], $c[[TEMPCAP]]
; CHECK-NEXT: dsubu	$[[ADDR]], $[[ADDR]], $[[REPRSIZE]]
; CHECK-NEXT: crepresentablealignmentmask $[[SP_ALIGN_MASK:[0-9]+]], $[[SIZE]]
; CHECK-NEXT: and	$[[ADDR1:([0-9]+|sp)]], $[[ADDR]], $[[SP_ALIGN_MASK]]
; CHECK-NEXT: csetaddr $c[[TEMPCAP1:([0-9]+)]], $c[[TEMPCAP]], $[[ADDR1]]
; CHECK-NEXT: csetbounds $c[[TEMPCAP2:([0-9]+)]], $c[[TEMPCAP1]], $[[REPRSIZE]]
; CHECK-NEXT: cmove $c11, $c[[TEMPCAP1]]
; CHECK-NEXT: csetbounds $c{{[0-9]+}}, $c[[TEMPCAP2]], ${{([0-9]+)}}
; CHECK: clcbi	$c12, %capcall20(use_arg)($c1)
  %vla = alloca i32, i64 %x, align 4, addrspace(200)
  %call = call i32 @use_arg(ptr addrspace(200) nonnull %vla)
  ret i32 %call
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p200(i64 immarg, ptr addrspace(200) nocapture) #0

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p200(i64 immarg, ptr addrspace(200) nocapture) #0

attributes #0 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
