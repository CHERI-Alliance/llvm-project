# RUN: llvm-mc %s -triple=riscv32 -mattr=+c,+zca,+zcheripurecap,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM,CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc -filetype=obj -triple=riscv32 -mattr=+c,+zca,+zcheripurecap,+cap-mode < %s \
# RUN:     | llvm-objdump --no-print-imm-hex --mattr=+zca,+zcheripurecap,+cap-mode -M no-aliases -d -r - \
# RUN:     | FileCheck --check-prefixes=CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc %s -triple=riscv64 -mattr=+zca,+zcheripurecap,+cap-mode -riscv-no-aliases -show-encoding \
# RUN:     | FileCheck -check-prefixes=CHECK-ASM,CHECK-ASM-AND-OBJ %s
# RUN: llvm-mc -filetype=obj -triple=riscv64 -mattr=+zca,+zcheripurecap,+cap-mode < %s \
# RUN:     | llvm-objdump --no-print-imm-hex --mattr=+zca,+zcheripurecap,+cap-mode -M no-aliases -d -r - \
# RUN:     | FileCheck --check-prefixes=CHECK-ASM-AND-OBJ %s
#
# RUN: not llvm-mc -triple riscv32 \
# RUN:     -riscv-no-aliases -show-encoding < %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK-NO-EXT %s
# RUN: not llvm-mc -triple riscv64 \
# RUN:     -riscv-no-aliases -show-encoding < %s 2>&1 \
# RUN:     | FileCheck -check-prefixes=CHECK-NO-EXT %s

# CHECK-ASM-AND-OBJ: c.mv ca0, ca1
# CHECK-ASM: encoding: [0x2e,0x85]
# CHECK-NO-EXT: error: instruction requires the following: 'C' (Compressed Instructions) or 'Zca' (part of the C extension, excluding compressed floating point loads/stores), 'Zcheripurecap' (CHERI aware Instructions), Capability Pointer Mode{{$}}
c.mv ca0, ca1

# CHECK-ASM-AND-OBJ: c.mv ca0, ca1
# CHECK-ASM: encoding: [0x2e,0x85]
# CHECK-NO-EXT: error: instruction requires the following: CHERI Extension{{$}}
cmv ca0, ca1

# CHECK-ASM-AND-OBJ: c.mv ca0, ca1
# CHECK-ASM: encoding: [0x2e,0x85]
# CHECK-NO-EXT: error: instruction requires the following: CHERI Extension{{$}}
caddi ca0, ca1, 0
