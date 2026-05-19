# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s

# CHECK: gcperm ra, csp # encoding: [0xb3,0x00,0x11,0x10]
ypermr x1, x2
# CHECK-NEXT: gctype ra, csp # encoding: [0xb3,0x00,0x21,0x10]
ytyper x1, x2
# CHECK-NEXT: gcbase ra, csp # encoding: [0xb3,0x00,0x51,0x10]
ybaser x1, x2
# CHECK-NEXT: gclen ra, csp # encoding: [0xb3,0x00,0x61,0x10]
ylenr x1, x2
# CHECK-NEXT: gctag ra, csp # encoding: [0xb3,0x00,0x01,0x10]
ytagr x1, x2
# CHECK-NEXT: gchi ra, csp # encoding: [0xb3,0x00,0x41,0x10]
yhir x1, x2
# CHECK-NEXT: scaddr cra, csp, gp # encoding: [0xb3,0x10,0x31,0x0c]
yaddrw x1, x2, x3
# CHECK-NEXT: schi cra, csp, gp # encoding: [0xb3,0x30,0x31,0x0c]
yhiw x1, x2, x3
# CHECK-NEXT: cadd cra, csp, gp # encoding: [0xb3,0x00,0x31,0x0c]
yadd x1, x2, x3
# CHECK-NEXT: caddi cra, csp, -173 # encoding: [0x9b,0x20,0x31,0xf5]
yaddi x1, x2, -173
# CHECK-NEXT: caddi cra, csp, -173 # encoding: [0x9b,0x20,0x31,0xf5]
yadd x1, x2, -173
# CHECK-NEXT: sentry cra, csp # encoding: [0xb3,0x00,0x81,0x10]
ysentry x1, x2
# CHECK-NEXT: cbld cra, csp, cgp # encoding: [0xb3,0x50,0x31,0x0c]
ybld x1, x2, x3
# CHECK-NEXT: scbndsr cra, csp, gp # encoding: [0xb3,0x10,0x31,0x0e]
ybndsrw x1, x2, x3
# CHECK-NEXT: scbnds cra, csp, gp # encoding: [0xb3,0x00,0x31,0x0e]
ybndsw x1, x2, x3
# CHECK-NEXT: scbndsi cra, csp, 12 # encoding: [0x93,0x50,0xc1,0x04]
ybndsw x1, x2, 12
# CHECK-NEXT: scbndsi cra, csp, 12 # encoding: [0x93,0x50,0xc1,0x04]
ybndswi x1, x2, 12
# CHECK-NEXT: cmv cra, csp # encoding: [0xb3,0x00,0x01,0x0c]
ymv x1, x2
# CHECK-NEXT: cram ra, sp # encoding: [0xb3,0x00,0x71,0x10]
yamask x1, x2
# CHECK-NEXT: scss ra, csp, cgp # encoding: [0xb3,0x60,0x31,0x0c]
yss x1, x2, x3
# CHECK-NEXT: sceq ra, csp, cgp # encoding: [0xb3,0x40,0x31,0x0c]
yeq x1, x2, x3
# CHECK-NEXT: xori ra, gp, -1 # encoding: [0x93,0xc0,0xf1,0xff]
# CHECK-NEXT: acperm cra, csp, ra # encoding: [0xb3,0x20,0x11,0x0c]
ypermc x1, x2, x3
# CHECK-NEXT: gcmode ra, csp # encoding: [0xb3,0x00,0x31,0x10]
ymoder x1, x2
# CHECK-NEXT: scmode cra, csp, gp # encoding: [0xb3,0x70,0x31,0x0c]
ymodew x1, x2, x3

## Check that add always uses integer add when using x registers instead of coercing.
# CHECK: cadd cra, csp, gp # encoding: [0xb3,0x00,0x31,0x0c]
add c1, c2, x3
# CHECK-NEXT: caddi cra, csp, 123 # encoding: [0x9b,0x20,0xb1,0x07]
add c1, c2, 123
# CHECK-NEXT: add ra, sp, gp # encoding: [0xb3,0x00,0x31,0x00]
add x1, x2, x3
# CHECK-NEXT: addi ra, sp, 123 # encoding: [0x93,0x00,0xb1,0x07]
add x1, x2, 123

## Check that mv always uses integer mv when using x registers instead of coercing.
# CHECK: cmv cra, csp # encoding: [0xb3,0x00,0x01,0x0c]
mv c1, c2
# CHECK-NEXT: addi ra, sp, 0 # encoding: [0x93,0x00,0x01,0x00]
mv x1, x2

