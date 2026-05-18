# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv32 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+a,+zcheripurecap,+zcherihybrid,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK %s

# CHECK: gcperm a0, ca1 # encoding: [0x33,0x85,0x15,0x10]
ypermr a0, ca1
# CHECK-NEXT: gctype a0, ca1 # encoding: [0x33,0x85,0x25,0x10]
ytyper a0, ca1
# CHECK-NEXT: gcbase a0, ca1 # encoding: [0x33,0x85,0x55,0x10]
ybaser a0, ca1
# CHECK-NEXT: gclen a0, ca1 # encoding: [0x33,0x85,0x65,0x10]
ylenr a0, ca1
# CHECK-NEXT: gctag a0, ca1 # encoding: [0x33,0x85,0x05,0x10]
ytagr a0, ca1
# CHECK-NEXT: gchi a0, ca1 # encoding: [0x33,0x85,0x45,0x10]
yhir a0, ca1
# CHECK-NEXT: scaddr ca0, ca1, a2 # encoding: [0x33,0x95,0xc5,0x0c]
yaddrw ca0, ca1, a2
# CHECK-NEXT: schi ca0, ca1, a2 # encoding: [0x33,0xb5,0xc5,0x0c]
yhiw ca0, ca1, a2
# CHECK-NEXT: cadd ca0, ca1, a2 # encoding: [0x33,0x85,0xc5,0x0c]
yadd ca0, ca1, a2
# CHECK-NEXT: caddi ca0, ca1, -173 # encoding: [0x1b,0xa5,0x35,0xf5]
yaddi ca0, ca1, -173
# CHECK-NEXT: caddi ca0, ca1, -173 # encoding: [0x1b,0xa5,0x35,0xf5]
yadd ca0, ca1, -173
# CHECK-NEXT: sentry ca0, ca1 # encoding: [0x33,0x85,0x85,0x10]
ysentry ca0, ca1
# CHECK-NEXT: cbld ca0, ca1, ca2 # encoding: [0x33,0xd5,0xc5,0x0c]
ybld ca0, ca1, ca2
# CHECK-NEXT: scbndsr ca0, ca1, a2 # encoding: [0x33,0x95,0xc5,0x0e]
ybndsrw ca0, ca1, a2
# CHECK-NEXT: scbnds ca0, ca1, a2 # encoding: [0x33,0x85,0xc5,0x0e]
ybndsw ca0, ca1, a2
# CHECK-NEXT: scbndsi ca0, ca1, 12 # encoding: [0x13,0xd5,0xc5,0x04]
ybndsw ca0, ca1, 12
# CHECK-NEXT: scbndsi ca0, ca1, 12 # encoding: [0x13,0xd5,0xc5,0x04]
ybndswi ca0, ca1, 12
# CHECK-NEXT: cmv ca0, ca1 # encoding: [0x33,0x85,0x05,0x0c]
ymv ca0, ca1
# CHECK-NEXT: cram a0, a1 # encoding: [0x33,0x85,0x75,0x10]
yamask a0, a1
# CHECK-NEXT: scss a0, ca1, ca2 # encoding: [0x33,0xe5,0xc5,0x0c]
yss a0, ca1, ca2
# CHECK-NEXT: sceq a0, ca1, ca2 # encoding: [0x33,0xc5,0xc5,0x0c]
yeq a0, ca1, ca2
# CHECK-NEXT: gcmode a0, ca1 # encoding: [0x33,0x85,0x35,0x10]
ymoder a0, ca1
# CHECK-NEXT: scmode ca0, ca1, a2 # encoding: [0x33,0xf5,0xc5,0x0c]
ymodew ca0, ca1, a2
# CHECK-NEXT: xori a0, a2, -1 # encoding: [0x13,0x45,0xf6,0xff]
# CHECK-NEXT: acperm ca0, ca1, a0 # encoding: [0x33,0xa5,0xa5,0x0c]
ypermc ca0, ca1, a2
