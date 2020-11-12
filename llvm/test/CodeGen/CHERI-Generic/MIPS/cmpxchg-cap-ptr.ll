; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --function-signature --scrub-attributes --force-update
; DO NOT EDIT -- This file was generated from test/CodeGen/CHERI-Generic/Inputs/cmpxchg-cap-ptr.ll
; Check that we can generate sensible code for atomic operations using capability pointers on capabilities
; in both hybrid and purecap mode.
; See https://github.com/CTSRD-CHERI/llvm-project/issues/470
; RUN: llc -mtriple=mips64 -mcpu=cheri128 -mattr=+cheri128 --relocation-model=pic -target-abi purecap < %s | FileCheck %s --check-prefix=PURECAP
; RUN: llc -mtriple=mips64 -mcpu=cheri128 -mattr=+cheri128 --relocation-model=pic -target-abi n64 < %s | FileCheck %s --check-prefix=HYBRID

define { i8, i1 } @test_cmpxchg_strong_i8(i8 addrspace(200)* %ptr, i8 %exp, i8 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_i8:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB0_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllb $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB0_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB0_1 Depth=1
; PURECAP-NEXT:    cscb $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB0_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB0_3: # %entry
; PURECAP-NEXT:    sll $1, $3, 24
; PURECAP-NEXT:    sra $1, $1, 24
; PURECAP-NEXT:    xor $1, $2, $1
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_strong_i8:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB0_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllb $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB0_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB0_1 Depth=1
; HYBRID-NEXT:    cscb $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB0_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB0_3: # %entry
; HYBRID-NEXT:    sll $1, $3, 24
; HYBRID-NEXT:    sra $1, $1, 24
; HYBRID-NEXT:    xor $1, $2, $1
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg i8 addrspace(200)* %ptr, i8 %exp, i8 %new acq_rel acquire
  ret { i8, i1 } %0
}

define { i16, i1 } @test_cmpxchg_strong_i16(i16 addrspace(200)* %ptr, i16 %exp, i16 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_i16:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB1_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllh $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB1_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB1_1 Depth=1
; PURECAP-NEXT:    csch $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB1_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB1_3: # %entry
; PURECAP-NEXT:    sll $1, $3, 16
; PURECAP-NEXT:    sra $1, $1, 16
; PURECAP-NEXT:    xor $1, $2, $1
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_strong_i16:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB1_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllh $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB1_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB1_1 Depth=1
; HYBRID-NEXT:    csch $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB1_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB1_3: # %entry
; HYBRID-NEXT:    sll $1, $3, 16
; HYBRID-NEXT:    sra $1, $1, 16
; HYBRID-NEXT:    xor $1, $2, $1
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg i16 addrspace(200)* %ptr, i16 %exp, i16 %new acq_rel acquire
  ret { i16, i1 } %0
}

define { i32, i1 } @test_cmpxchg_strong_i32(i32 addrspace(200)* %ptr, i32 %exp, i32 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_i32:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB2_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllw $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB2_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB2_1 Depth=1
; PURECAP-NEXT:    cscw $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB2_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB2_3: # %entry
; PURECAP-NEXT:    xor $1, $2, $3
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_strong_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB2_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllw $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB2_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB2_1 Depth=1
; HYBRID-NEXT:    cscw $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB2_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB2_3: # %entry
; HYBRID-NEXT:    xor $1, $2, $3
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg i32 addrspace(200)* %ptr, i32 %exp, i32 %new acq_rel acquire
  ret { i32, i1 } %0
}

define { i64, i1 } @test_cmpxchg_strong_i64(i64 addrspace(200)* %ptr, i64 %exp, i64 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_i64:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB3_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    clld $2, $c3
; PURECAP-NEXT:    bne $2, $4, .LBB3_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB3_1 Depth=1
; PURECAP-NEXT:    cscd $1, $5, $c3
; PURECAP-NEXT:    beqz $1, .LBB3_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB3_3: # %entry
; PURECAP-NEXT:    xor $1, $2, $4
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_strong_i64:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB3_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    clld $2, $c3
; HYBRID-NEXT:    bne $2, $4, .LBB3_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB3_1 Depth=1
; HYBRID-NEXT:    cscd $1, $5, $c3
; HYBRID-NEXT:    beqz $1, .LBB3_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB3_3: # %entry
; HYBRID-NEXT:    xor $1, $2, $4
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg i64 addrspace(200)* %ptr, i64 %exp, i64 %new acq_rel acquire
  ret { i64, i1 } %0
}

define { i8 addrspace(200)*, i1 } @test_cmpxchg_strong_cap(i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_cap:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB4_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllc $c1, $c3
; PURECAP-NEXT:    ceq $1, $c1, $c4
; PURECAP-NEXT:    beqz $1, .LBB4_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB4_1 Depth=1
; PURECAP-NEXT:    cscc $1, $c5, $c3
; PURECAP-NEXT:    beqz $1, .LBB4_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB4_3: # %entry
; PURECAP-NEXT:    ceq $2, $c1, $c4
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    cmove $c3, $c1
;
; HYBRID-LABEL: test_cmpxchg_strong_cap:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB4_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllc $c1, $c3
; HYBRID-NEXT:    ceq $1, $c1, $c4
; HYBRID-NEXT:    beqz $1, .LBB4_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB4_1 Depth=1
; HYBRID-NEXT:    cscc $1, $c5, $c3
; HYBRID-NEXT:    beqz $1, .LBB4_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB4_3: # %entry
; HYBRID-NEXT:    ceq $2, $c1, $c4
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    cmove $c3, $c1
entry:
  %0 = cmpxchg i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new acq_rel acquire
  ret { i8 addrspace(200)*, i1 } %0
}

define { i32 addrspace(200)*, i1 } @test_cmpxchg_strong_cap_i32(i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_strong_cap_i32:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB5_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllc $c1, $c3
; PURECAP-NEXT:    ceq $1, $c1, $c4
; PURECAP-NEXT:    beqz $1, .LBB5_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB5_1 Depth=1
; PURECAP-NEXT:    cscc $1, $c5, $c3
; PURECAP-NEXT:    beqz $1, .LBB5_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB5_3: # %entry
; PURECAP-NEXT:    ceq $2, $c1, $c4
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    cmove $c3, $c1
;
; HYBRID-LABEL: test_cmpxchg_strong_cap_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB5_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllc $c1, $c3
; HYBRID-NEXT:    ceq $1, $c1, $c4
; HYBRID-NEXT:    beqz $1, .LBB5_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB5_1 Depth=1
; HYBRID-NEXT:    cscc $1, $c5, $c3
; HYBRID-NEXT:    beqz $1, .LBB5_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB5_3: # %entry
; HYBRID-NEXT:    ceq $2, $c1, $c4
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    cmove $c3, $c1
entry:
  %0 = cmpxchg weak i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new acq_rel acquire
  ret { i32 addrspace(200)*, i1 } %0
}


define { i8, i1 } @test_cmpxchg_weak_i8(i8 addrspace(200)* %ptr, i8 %exp, i8 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_i8:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB6_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllb $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB6_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB6_1 Depth=1
; PURECAP-NEXT:    cscb $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB6_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB6_3: # %entry
; PURECAP-NEXT:    sll $1, $3, 24
; PURECAP-NEXT:    sra $1, $1, 24
; PURECAP-NEXT:    xor $1, $2, $1
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_weak_i8:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB6_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllb $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB6_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB6_1 Depth=1
; HYBRID-NEXT:    cscb $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB6_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB6_3: # %entry
; HYBRID-NEXT:    sll $1, $3, 24
; HYBRID-NEXT:    sra $1, $1, 24
; HYBRID-NEXT:    xor $1, $2, $1
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg weak i8 addrspace(200)* %ptr, i8 %exp, i8 %new acq_rel acquire
  ret { i8, i1 } %0
}

define { i16, i1 } @test_cmpxchg_weak_i16(i16 addrspace(200)* %ptr, i16 %exp, i16 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_i16:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB7_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllh $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB7_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB7_1 Depth=1
; PURECAP-NEXT:    csch $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB7_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB7_3: # %entry
; PURECAP-NEXT:    sll $1, $3, 16
; PURECAP-NEXT:    sra $1, $1, 16
; PURECAP-NEXT:    xor $1, $2, $1
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_weak_i16:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB7_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllh $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB7_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB7_1 Depth=1
; HYBRID-NEXT:    csch $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB7_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB7_3: # %entry
; HYBRID-NEXT:    sll $1, $3, 16
; HYBRID-NEXT:    sra $1, $1, 16
; HYBRID-NEXT:    xor $1, $2, $1
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg weak i16 addrspace(200)* %ptr, i16 %exp, i16 %new acq_rel acquire
  ret { i16, i1 } %0
}

define { i32, i1 } @test_cmpxchg_weak_i32(i32 addrspace(200)* %ptr, i32 %exp, i32 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_i32:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sll $1, $5, 0
; PURECAP-NEXT:    sll $3, $4, 0
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB8_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllw $2, $c3
; PURECAP-NEXT:    bne $2, $3, .LBB8_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB8_1 Depth=1
; PURECAP-NEXT:    cscw $4, $1, $c3
; PURECAP-NEXT:    beqz $4, .LBB8_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB8_3: # %entry
; PURECAP-NEXT:    xor $1, $2, $3
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_weak_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sll $1, $5, 0
; HYBRID-NEXT:    sll $3, $4, 0
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB8_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllw $2, $c3
; HYBRID-NEXT:    bne $2, $3, .LBB8_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB8_1 Depth=1
; HYBRID-NEXT:    cscw $4, $1, $c3
; HYBRID-NEXT:    beqz $4, .LBB8_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB8_3: # %entry
; HYBRID-NEXT:    xor $1, $2, $3
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg weak i32 addrspace(200)* %ptr, i32 %exp, i32 %new acq_rel acquire
  ret { i32, i1 } %0
}

define { i64, i1 } @test_cmpxchg_weak_i64(i64 addrspace(200)* %ptr, i64 %exp, i64 %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_i64:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB9_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    clld $2, $c3
; PURECAP-NEXT:    bne $2, $4, .LBB9_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB9_1 Depth=1
; PURECAP-NEXT:    cscd $1, $5, $c3
; PURECAP-NEXT:    beqz $1, .LBB9_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB9_3: # %entry
; PURECAP-NEXT:    xor $1, $2, $4
; PURECAP-NEXT:    sltiu $3, $1, 1
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    nop
;
; HYBRID-LABEL: test_cmpxchg_weak_i64:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB9_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    clld $2, $c3
; HYBRID-NEXT:    bne $2, $4, .LBB9_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB9_1 Depth=1
; HYBRID-NEXT:    cscd $1, $5, $c3
; HYBRID-NEXT:    beqz $1, .LBB9_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB9_3: # %entry
; HYBRID-NEXT:    xor $1, $2, $4
; HYBRID-NEXT:    sltiu $3, $1, 1
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    nop
entry:
  %0 = cmpxchg weak i64 addrspace(200)* %ptr, i64 %exp, i64 %new acq_rel acquire
  ret { i64, i1 } %0
}

define { i8 addrspace(200)*, i1 } @test_cmpxchg_weak_cap(i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_cap:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB10_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllc $c1, $c3
; PURECAP-NEXT:    ceq $1, $c1, $c4
; PURECAP-NEXT:    beqz $1, .LBB10_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB10_1 Depth=1
; PURECAP-NEXT:    cscc $1, $c5, $c3
; PURECAP-NEXT:    beqz $1, .LBB10_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB10_3: # %entry
; PURECAP-NEXT:    ceq $2, $c1, $c4
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    cmove $c3, $c1
;
; HYBRID-LABEL: test_cmpxchg_weak_cap:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB10_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllc $c1, $c3
; HYBRID-NEXT:    ceq $1, $c1, $c4
; HYBRID-NEXT:    beqz $1, .LBB10_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB10_1 Depth=1
; HYBRID-NEXT:    cscc $1, $c5, $c3
; HYBRID-NEXT:    beqz $1, .LBB10_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB10_3: # %entry
; HYBRID-NEXT:    ceq $2, $c1, $c4
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    cmove $c3, $c1
entry:
  %0 = cmpxchg weak i8 addrspace(200)* addrspace(200)* %ptr, i8 addrspace(200)* %exp, i8 addrspace(200)* %new acq_rel acquire
  ret { i8 addrspace(200)*, i1 } %0
}

define { i32 addrspace(200)*, i1 } @test_cmpxchg_weak_cap_i32(i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new) nounwind {
; PURECAP-LABEL: test_cmpxchg_weak_cap_i32:
; PURECAP:       # %bb.0: # %entry
; PURECAP-NEXT:    sync
; PURECAP-NEXT:  .LBB11_1: # %entry
; PURECAP-NEXT:    # =>This Inner Loop Header: Depth=1
; PURECAP-NEXT:    cllc $c1, $c3
; PURECAP-NEXT:    ceq $1, $c1, $c4
; PURECAP-NEXT:    beqz $1, .LBB11_3
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  # %bb.2: # %entry
; PURECAP-NEXT:    # in Loop: Header=BB11_1 Depth=1
; PURECAP-NEXT:    cscc $1, $c5, $c3
; PURECAP-NEXT:    beqz $1, .LBB11_1
; PURECAP-NEXT:    nop
; PURECAP-NEXT:  .LBB11_3: # %entry
; PURECAP-NEXT:    ceq $2, $c1, $c4
; PURECAP-NEXT:    sync
; PURECAP-NEXT:    cjr $c17
; PURECAP-NEXT:    cmove $c3, $c1
;
; HYBRID-LABEL: test_cmpxchg_weak_cap_i32:
; HYBRID:       # %bb.0: # %entry
; HYBRID-NEXT:    sync
; HYBRID-NEXT:  .LBB11_1: # %entry
; HYBRID-NEXT:    # =>This Inner Loop Header: Depth=1
; HYBRID-NEXT:    cllc $c1, $c3
; HYBRID-NEXT:    ceq $1, $c1, $c4
; HYBRID-NEXT:    beqz $1, .LBB11_3
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  # %bb.2: # %entry
; HYBRID-NEXT:    # in Loop: Header=BB11_1 Depth=1
; HYBRID-NEXT:    cscc $1, $c5, $c3
; HYBRID-NEXT:    beqz $1, .LBB11_1
; HYBRID-NEXT:    nop
; HYBRID-NEXT:  .LBB11_3: # %entry
; HYBRID-NEXT:    ceq $2, $c1, $c4
; HYBRID-NEXT:    sync
; HYBRID-NEXT:    jr $ra
; HYBRID-NEXT:    cmove $c3, $c1
entry:
  %0 = cmpxchg weak i32 addrspace(200)* addrspace(200)* %ptr, i32 addrspace(200)* %exp, i32 addrspace(200)* %new acq_rel acquire
  ret { i32 addrspace(200)*, i1 } %0
}
