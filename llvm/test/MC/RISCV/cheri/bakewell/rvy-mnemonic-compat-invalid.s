# RUN: not llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases 2>&1 | FileCheck %s
# RUN: not llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases 2>&1 | FileCheck %s
# RUN: not llvm-mc %s --defsym PURECAP=1 -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases 2>&1 | FileCheck %s
# RUN: not llvm-mc %s --defsym PURECAP=1 -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases 2>&1 | FileCheck %s

## Check that RVY mnemonics reject DDC as an operand for compatibility with the RVY specification.
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
ybld x1, ddc, c3
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
ybld x1, x2, ddc
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
yss x1, ddc, x3
# CHECK: :[[@LINE+1]]:13: error: invalid operand for instruction
yss x1, x2, ddc

## Check that ypermc rejects rd == rs1 since expansion requires a temporary register.
# CHECK: :[[@LINE+1]]:8: error: expanding RVY compatible mnemonic requires destination and source capability registers to be different since this needs a temporary register to negate the mask
ypermc x1, x1, x3

.ifndef PURECAP
## Check that in hybrid mode capability base registers are rejected for capability loads/stores.
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
ly x1, 0(c2)
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
sy x1, 0(c2)
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
lw x1, 0(c2)

## Check that in hybrid mode jumps reject capability registers.
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
jr c1
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
jalr c1, c2
# CHECK-HYBRID: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
jal c1, 20

## Check that in hybrid mode lc/sc do not coerce destination/source registers.
# CHECK-HYBRID: :[[@LINE+1]]:4: error: invalid operand for instruction
lc x1, 0(x2)
# CHECK-HYBRID: :[[@LINE+1]]:4: error: invalid operand for instruction
sc x1, 0(x2)
.endif

## Check that XCheri mnemonics do not coerce arguments.
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
cgetbase x1, x2
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
cgetperm x1, x2
# CHECK: :[[@LINE+1]]:12: error: invalid operand for instruction
csetbounds x1, x2, x3
# CHECK: :[[@LINE+1]]:10: error: invalid operand for instruction
csetaddr x1, x2, x3
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
cinvoke x1, x2


## Check that we don't coerce arguments for .ddc and .cap instructions in hybrid and purecap modes
# CHECK: :[[@LINE+1]]:8: error: invalid operand for instruction
lc.ddc x1, 0(x2)
# CHECK: :[[@LINE+1]]:8: error: invalid operand for instruction
sc.ddc x1, 0(x2)
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
lc.cap c1, 0(x2)
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
sc.cap c1, 0(x2)
