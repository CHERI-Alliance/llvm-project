# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck --check-prefixes=CHECK %s

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
# CHECK-NEXT: scbndsi cra, csp, 496 # encoding: [0x93,0x50,0xf1,0x07]
ybndsw x1, x2, 496
# CHECK-NEXT: scbndsi cra, csp, 496 # encoding: [0x93,0x50,0xf1,0x07]
ybndswi x1, x2, 496
# CHECK-NEXT: cmv cra, csp # encoding: [0xb3,0x00,0x01,0x0c]
ymv x1, x2
# CHECK-NEXT: cram ra, sp # encoding: [0xb3,0x00,0x71,0x10]
yamask x1, x2
# CHECK-NEXT: scss ra, csp, cgp # encoding: [0xb3,0x60,0x31,0x0c]
yss x1, x2, x3
# CHECK-NEXT: sceq ra, csp, cgp # encoding: [0xb3,0x40,0x31,0x0c]
yeq x1, x2, x3
# CHECK-NEXT: gcmode ra, csp # encoding: [0xb3,0x00,0x31,0x10]
ymoder x1, x2
# CHECK-NEXT: scmode cra, csp, gp # encoding: [0xb3,0x70,0x31,0x0c]
ymodew x1, x2, x3

## Check that ABI register names work as expected
# CHECK: gcperm ra, csp # encoding: [0xb3,0x00,0x11,0x10]
ypermr ra, sp
# CHECK-NEXT: caddi cra, csp, -173 # encoding: [0x9b,0x20,0x31,0xf5]
yaddi ra, sp, -173
# CHECK-NEXT: sentry cra, csp # encoding: [0xb3,0x00,0x81,0x10]
ysentry ra, sp
# CHECK-NEXT: cbld cra, csp, cgp # encoding: [0xb3,0x50,0x31,0x0c]
ybld ra, sp, gp
