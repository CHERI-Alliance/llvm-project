# RUN: not llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases 2>&1 | FileCheck %s
# RUN: not llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases 2>&1 | FileCheck %s

## Check that RVY mnemonics reject DDC as an operand for compatibility with the RVY specification.
# CHECK: :[[@LINE+1]]:11: error: invalid operand for instruction
ybld ca0, ddc, ca1
# CHECK: :[[@LINE+1]]:16: error: invalid operand for instruction
ybld ca0, ca1, ddc
# CHECK: :[[@LINE+1]]:9: error: invalid operand for instruction
yss a0, ddc, ca1
# CHECK: :[[@LINE+1]]:14: error: invalid operand for instruction
yss a0, ca1, ddc

## Check that in hybrid mode capability base registers are rejected for capability loads.
# CHECK: :[[@LINE+1]]:1: error: instruction requires the following: Capability Pointer Mode
ly ca0, 0(ca1)

## Check that ypermc rejects rd == rs1 since expansion requires a temporary register.
# CHECK: :[[@LINE+1]]:8: error: expanding RVY compatible mnemonic requires destination and source capability registers to be different since this needs a temporary register to negate the mask
ypermc ca0, ca0, a1
