# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-32 %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-64 %s

## Check that RVY mnemonics are accepted and we can use C register names
# CHECK-32: lc ca0, 0(ca1) # encoding: [0x0f,0xc5,0x05,0x00]
# CHECK-64: lc ca0, 0(ca1) # encoding: [0x0f,0xc5,0x05,0x00]
ly ca0, 0(ca1)
# CHECK-32-NEXT: sc ca0, 0(ca1) # encoding: [0x23,0xc0,0xa5,0x00]
# CHECK-64-NEXT: sc ca0, 0(ca1) # encoding: [0x23,0xc0,0xa5,0x00]
sy ca0, 0(ca1)
# CHECK-32-NEXT: lr.c ca0, (ca1) # encoding: [0x2f,0xc5,0x05,0x10]
# CHECK-64-NEXT: lr.c ca0, (ca1) # encoding: [0x2f,0xc5,0x05,0x10]
lr.y ca0, (ca1)
# CHECK-32-NEXT: lr.c.aq ca0, (ca1) # encoding: [0x2f,0xc5,0x05,0x14]
# CHECK-64-NEXT: lr.c.aq ca0, (ca1) # encoding: [0x2f,0xc5,0x05,0x14]
lr.y.aq ca0, (ca1)
# CHECK-32-NEXT: sc.c a0, ca1, (ca2) # encoding: [0x2f,0x45,0xb6,0x18]
# CHECK-64-NEXT: sc.c a0, ca1, (ca2) # encoding: [0x2f,0x45,0xb6,0x18]
sc.y a0, ca1, (ca2)
# CHECK-32-NEXT: amoswap.c ca0, ca1, (ca2) # encoding: [0x2f,0x45,0xb6,0x08]
# CHECK-64-NEXT: amoswap.c ca0, ca1, (ca2) # encoding: [0x2f,0x45,0xb6,0x08]
amoswap.y ca0, ca1, (ca2)
