; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --force-update
; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/cmpxchg-cap-ptr.ll
; Check that we can generate sensible code for atomic operations using capability pointers on capabilities
; in both hybrid and purecap mode.
; See https://github.com/CTSRD-CHERI/llvm-project/issues/470
; RUN: llc -mtriple=riscv64 --relocation-model=pic -target-abi l64pc128d -mattr=+xcheri,+cap-mode,+f,+d -mattr=+a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-ATOMICS
; RUN: llc -mtriple=riscv64 --relocation-model=pic -target-abi l64pc128d -mattr=+xcheri,+cap-mode,+f,+d -mattr=-a < %s | FileCheck %s --check-prefixes=PURECAP,PURECAP-LIBCALLS
; RUN: llc -mtriple=riscv64 --relocation-model=pic -target-abi lp64d -mattr=+xcheri,+f,+d -mattr=+a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-ATOMICS
; RUN: llc -mtriple=riscv64 --relocation-model=pic -target-abi lp64d -mattr=+xcheri,+f,+d -mattr=+a < %s | FileCheck %s --check-prefixes=HYBRID,HYBRID-LIBCALLS

define { i8, i1 } @test_cmpxchg_strong_i8(i8 addrspace(200)* %ptr, i8 %exp, i8 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_i8:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    slli a1, a1, 56
; PURECAP-ATOMICS-NEXT:    srai a1, a1, 56
; PURECAP-ATOMICS-NEXT:  .LBB0_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.b.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB0_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB0_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.b.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB0_1
; PURECAP-ATOMICS-NEXT:  .LBB0_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_i8:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    csb a1, 15(csp)
; PURECAP-LIBCALLS-NEXT:    addi a1, zero, 1
; PURECAP-LIBCALLS-NEXT:    cincoffset ca3, csp, 15
; PURECAP-LIBCALLS-NEXT:    csetbounds ca1, ca3, a1
; PURECAP-LIBCALLS-NEXT:  .LBB0_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_1)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB0_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clb a1, 15(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_i8:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sb a1, 7(sp)
; HYBRID-NEXT:    addi a1, sp, 7
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_1_c@plt
; HYBRID-NEXT:    lb a1, 7(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg i8 addrspace(200)* %ptr, i8 %exp, i8 %new acq_rel acquire
  ret { i8, i1 } %0
}

define { i16, i1 } @test_cmpxchg_strong_i16(i16 addrspace(200)* %ptr, i16 %exp, i16 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_i16:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    slli a1, a1, 48
; PURECAP-ATOMICS-NEXT:    srai a1, a1, 48
; PURECAP-ATOMICS-NEXT:  .LBB1_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.h.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB1_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB1_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.h.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB1_1
; PURECAP-ATOMICS-NEXT:  .LBB1_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_i16:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 2
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 14
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csh a1, 14(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB1_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_2)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB1_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clh a1, 14(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_i16:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sh a1, 6(sp)
; HYBRID-NEXT:    addi a1, sp, 6
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_2_c@plt
; HYBRID-NEXT:    lh a1, 6(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg i16 addrspace(200)* %ptr, i16 %exp, i16 %new acq_rel acquire
  ret { i16, i1 } %0
}

define { i32, i1 } @test_cmpxchg_strong_i32(i32 addrspace(200)* %ptr, i32 %exp, i32 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_i32:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    sext.w a1, a1
; PURECAP-ATOMICS-NEXT:  .LBB2_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.w.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB2_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB2_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.w.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB2_1
; PURECAP-ATOMICS-NEXT:  .LBB2_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_i32:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 12
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csw a1, 12(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB2_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_4)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB2_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clw a1, 12(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sw a1, 4(sp)
; HYBRID-NEXT:    addi a1, sp, 4
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_4_c@plt
; HYBRID-NEXT:    lw a1, 4(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg i32 addrspace(200)* %ptr, i32 %exp, i32 %new acq_rel acquire
  ret { i32, i1 } %0
}

define { i64, i1 } @test_cmpxchg_strong_i64(i64 addrspace(200)* %ptr, i64 %exp, i64 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_i64:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB3_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.d.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB3_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB3_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.d.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB3_1
; PURECAP-ATOMICS-NEXT:  .LBB3_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_i64:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 8
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 8
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csd a1, 8(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB3_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_8)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB3_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    cld a1, 8(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_i64:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sd a1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_8_c@plt
; HYBRID-NEXT:    ld a1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg i64 addrspace(200)* %ptr, i64 %exp, i64 %new acq_rel acquire
  ret { i64, i1 } %0
}

define { i8 addrspace(200)*, i1 } @test_cmpxchg_strong_cap(i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_cap:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB4_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.c.aq ca3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB4_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB4_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.c.aq a4, ca2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB4_1
; PURECAP-ATOMICS-NEXT:  .LBB4_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    cmove ca0, ca3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_cap:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 16
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 0
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB4_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_cap)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB4_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    cmove ca0, ca1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_cap:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -32
; HYBRID-NEXT:    sd ra, 24(sp)
; HYBRID-NEXT:    sc ca1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_cap_c@plt
; HYBRID-NEXT:    lc ca1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    cmove ca0, ca1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 24(sp)
; HYBRID-NEXT:    addi sp, sp, 32
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new acq_rel acquire
  ret { i8 addrspace(200)*, i1 } %0
}

define { i32 addrspace(200)*, i1 } @test_cmpxchg_strong_cap_i32(i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_strong_cap_i32:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB5_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.c.aq ca3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB5_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB5_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.c.aq a4, ca2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB5_1
; PURECAP-ATOMICS-NEXT:  .LBB5_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    cmove ca0, ca3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_strong_cap_i32:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 16
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 0
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB5_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_cap)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB5_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    cmove ca0, ca1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_strong_cap_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -32
; HYBRID-NEXT:    sd ra, 24(sp)
; HYBRID-NEXT:    sc ca1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_cap_c@plt
; HYBRID-NEXT:    lc ca1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    cmove ca0, ca1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 24(sp)
; HYBRID-NEXT:    addi sp, sp, 32
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new acq_rel acquire
  ret { i32 addrspace(200)*, i1 } %0
}


define { i8, i1 } @test_cmpxchg_weak_i8(i8 addrspace(200)* %ptr, i8 %exp, i8 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_i8:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    slli a1, a1, 56
; PURECAP-ATOMICS-NEXT:    srai a1, a1, 56
; PURECAP-ATOMICS-NEXT:  .LBB6_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.b.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB6_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB6_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.b.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB6_1
; PURECAP-ATOMICS-NEXT:  .LBB6_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_i8:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    csb a1, 15(csp)
; PURECAP-LIBCALLS-NEXT:    addi a1, zero, 1
; PURECAP-LIBCALLS-NEXT:    cincoffset ca3, csp, 15
; PURECAP-LIBCALLS-NEXT:    csetbounds ca1, ca3, a1
; PURECAP-LIBCALLS-NEXT:  .LBB6_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_1)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB6_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clb a1, 15(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_i8:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sb a1, 7(sp)
; HYBRID-NEXT:    addi a1, sp, 7
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_1_c@plt
; HYBRID-NEXT:    lb a1, 7(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i8 addrspace(200)* %ptr, i8 %exp, i8 %new acq_rel acquire
  ret { i8, i1 } %0
}

define { i16, i1 } @test_cmpxchg_weak_i16(i16 addrspace(200)* %ptr, i16 %exp, i16 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_i16:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    slli a1, a1, 48
; PURECAP-ATOMICS-NEXT:    srai a1, a1, 48
; PURECAP-ATOMICS-NEXT:  .LBB7_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.h.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB7_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB7_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.h.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB7_1
; PURECAP-ATOMICS-NEXT:  .LBB7_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_i16:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 2
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 14
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csh a1, 14(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB7_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_2)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB7_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clh a1, 14(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_i16:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sh a1, 6(sp)
; HYBRID-NEXT:    addi a1, sp, 6
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_2_c@plt
; HYBRID-NEXT:    lh a1, 6(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i16 addrspace(200)* %ptr, i16 %exp, i16 %new acq_rel acquire
  ret { i16, i1 } %0
}

define { i32, i1 } @test_cmpxchg_weak_i32(i32 addrspace(200)* %ptr, i32 %exp, i32 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_i32:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:    sext.w a1, a1
; PURECAP-ATOMICS-NEXT:  .LBB8_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.w.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB8_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB8_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.w.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB8_1
; PURECAP-ATOMICS-NEXT:  .LBB8_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_i32:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 12
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csw a1, 12(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB8_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_4)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB8_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clw a1, 12(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sw a1, 4(sp)
; HYBRID-NEXT:    addi a1, sp, 4
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_4_c@plt
; HYBRID-NEXT:    lw a1, 4(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i32 addrspace(200)* %ptr, i32 %exp, i32 %new acq_rel acquire
  ret { i32, i1 } %0
}

define { i64, i1 } @test_cmpxchg_weak_i64(i64 addrspace(200)* %ptr, i64 %exp, i64 %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_i64:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB9_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.d.aq a3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB9_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB9_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.d.rl a4, a2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB9_1
; PURECAP-ATOMICS-NEXT:  .LBB9_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    mv a0, a3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_i64:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 8
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 8
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csd a1, 8(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB9_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_8)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB9_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    cld a1, 8(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    mv a0, a1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_i64:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -16
; HYBRID-NEXT:    sd ra, 8(sp)
; HYBRID-NEXT:    sd a1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_8_c@plt
; HYBRID-NEXT:    ld a1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    mv a0, a1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 8(sp)
; HYBRID-NEXT:    addi sp, sp, 16
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i64 addrspace(200)* %ptr, i64 %exp, i64 %new acq_rel acquire
  ret { i64, i1 } %0
}

define { i8 addrspace(200)*, i1 } @test_cmpxchg_weak_cap(i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_cap:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB10_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.c.aq ca3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB10_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB10_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.c.aq a4, ca2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB10_1
; PURECAP-ATOMICS-NEXT:  .LBB10_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    cmove ca0, ca3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_cap:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 16
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 0
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB10_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_cap)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB10_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    cmove ca0, ca1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_cap:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -32
; HYBRID-NEXT:    sd ra, 24(sp)
; HYBRID-NEXT:    sc ca1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_cap_c@plt
; HYBRID-NEXT:    lc ca1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    cmove ca0, ca1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 24(sp)
; HYBRID-NEXT:    addi sp, sp, 32
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new acq_rel acquire
  ret { i8 addrspace(200)*, i1 } %0
}

define { i32 addrspace(200)*, i1 } @test_cmpxchg_weak_cap_i32(i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new) nounwind {
; PURECAP-ATOMICS-LABEL: test_cmpxchg_weak_cap_i32:
; PURECAP-ATOMICS:       # %bb.0: # %entry
; PURECAP-ATOMICS-NEXT:  .LBB11_1: # %entry
; PURECAP-ATOMICS-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-ATOMICS-NEXT:    clr.c.aq ca3, (ca0)
; PURECAP-ATOMICS-NEXT:    bne a3, a1, .LBB11_3
; PURECAP-ATOMICS-NEXT:  # %bb.2: # %entry
; PURECAP-ATOMICS-NEXT:    # in Loop: Header=BB11_1 Depth=1
; PURECAP-ATOMICS-NEXT:    csc.c.aq a4, ca2, (ca0)
; PURECAP-ATOMICS-NEXT:    bnez a4, .LBB11_1
; PURECAP-ATOMICS-NEXT:  .LBB11_3: # %entry
; PURECAP-ATOMICS-NEXT:    xor a0, a3, a1
; PURECAP-ATOMICS-NEXT:    seqz a1, a0
; PURECAP-ATOMICS-NEXT:    cmove ca0, ca3
; PURECAP-ATOMICS-NEXT:    cret
;
; PURECAP-LIBCALLS-LABEL: test_cmpxchg_weak_cap_i32:
; PURECAP-LIBCALLS:       # %bb.0: # %entry
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, -32
; PURECAP-LIBCALLS-NEXT:    csc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 16
; PURECAP-LIBCALLS-NEXT:    cincoffset ca4, csp, 0
; PURECAP-LIBCALLS-NEXT:    csetbounds ca6, ca4, a3
; PURECAP-LIBCALLS-NEXT:    csc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:  .LBB11_1: # %entry
; PURECAP-LIBCALLS-NEXT:    # Label of block must be emitted
; PURECAP-LIBCALLS-NEXT:    auipcc ca5, %captab_pcrel_hi(__atomic_compare_exchange_cap)
; PURECAP-LIBCALLS-NEXT:    clc ca5, %pcrel_lo(.LBB11_1)(ca5)
; PURECAP-LIBCALLS-NEXT:    addi a3, zero, 4
; PURECAP-LIBCALLS-NEXT:    addi a4, zero, 2
; PURECAP-LIBCALLS-NEXT:    cmove ca1, ca6
; PURECAP-LIBCALLS-NEXT:    cjalr ca5
; PURECAP-LIBCALLS-NEXT:    clc ca1, 0(csp)
; PURECAP-LIBCALLS-NEXT:    mv a2, a0
; PURECAP-LIBCALLS-NEXT:    cmove ca0, ca1
; PURECAP-LIBCALLS-NEXT:    mv a1, a2
; PURECAP-LIBCALLS-NEXT:    clc cra, 16(csp)
; PURECAP-LIBCALLS-NEXT:    cincoffset csp, csp, 32
; PURECAP-LIBCALLS-NEXT:    cret
;
; HYBRID-LABEL: test_cmpxchg_weak_cap_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    addi sp, sp, -32
; HYBRID-NEXT:    sd ra, 24(sp)
; HYBRID-NEXT:    sc ca1, 0(sp)
; HYBRID-NEXT:    mv a1, sp
; HYBRID-NEXT:    addi a3, zero, 4
; HYBRID-NEXT:    addi a4, zero, 2
; HYBRID-NEXT:    call __atomic_compare_exchange_cap_c@plt
; HYBRID-NEXT:    lc ca1, 0(sp)
; HYBRID-NEXT:    mv a2, a0
; HYBRID-NEXT:    cmove ca0, ca1
; HYBRID-NEXT:    mv a1, a2
; HYBRID-NEXT:    ld ra, 24(sp)
; HYBRID-NEXT:    addi sp, sp, 32
; HYBRID-NEXT:    ret
entry:
  %0 = cmpxchg weak i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new acq_rel acquire
  ret { i32 addrspace(200)*, i1 } %0
}
