# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --allow-unused-prefixes -check-prefixes=CHECK,CHECK-32 %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --allow-unused-prefixes -check-prefixes=CHECK,CHECK-64 %s

## Check that RVY mnemonics are accepted and we can use GPR register names
# CHECK: lc cra, 0(sp) # encoding: [0x8f,0x40,0x01,0x00]
ly x1, 0(x2)
# CHECK-NEXT: sc cra, 0(sp) # encoding: [0x23,0x40,0x11,0x00]
sy x1, 0(x2)
# CHECK-NEXT: lr.c cra, (sp) # encoding: [0xaf,0x40,0x01,0x10]
lr.y x1, (x2)
# CHECK-NEXT: lr.c.aq cra, (sp) # encoding: [0xaf,0x40,0x01,0x14]
lr.y.aq x1, (x2)
# CHECK-NEXT: sc.c gp, cgp, (sp) # encoding: [0xaf,0x41,0x31,0x18]
sc.y x3, x3, (x2)
# CHECK-NEXT: amoswap.c cra, cgp, (sp) # encoding: [0xaf,0x40,0x31,0x08]
amoswap.y x1, x3, (x2)
