# REQUIRES: riscv
# RUN: llvm-mc -filetype=obj -triple=riscv64-unknown-elf --mattr=+zcheripurecap,+cap-mode --target-abi=l64pc128 %s -o %t.rv64.o
# RUN: ld.lld --local-caprelocs=elf %t.rv64.o -o %t.rv64

# RUN: llvm-readobj --relocs %t.rv64 | FileCheck %s --check-prefix=RELOCS
# RUN: llvm-objdump -s --section=.rela.dyn %t.rv64 | FileCheck %s --check-prefix=RELADYN
# RUN: llvm-objdump -s --section=.data %t.rv64 | FileCheck %s --check-prefix=DATA
# RUN: llvm-objdump -s --section=.rodata %t.rv64 | FileCheck %s --check-prefix=RODATA
# RUN: llvm-readobj --cap-relocs-cbuildcap %t.rv64 | FileCheck %s --check-prefix=CAPRELOCS
# RUN: llvm-readelf -s %t.rv64 | FileCheck %s --check-prefix=SYM

# RELOCS:      Relocations [
# RELOCS-NEXT:   Section ({{[0-9]+}}) .rela.dyn {
# RELOCS-NEXT:     0x121F0 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS-NEXT:     0x12200 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS-NEXT:     0x12210 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS-NEXT:   }

# RELADYN: Contents of section .rela.dyn:
# RELADYN-NEXT: 10190
# RELADYN-NEXT: 101a0
# RELADYN-NEXT: 101b0
# RELADYN-NEXT: 101c0
# RELADYN-NEXT: 101d0

# DATA: Contents of section .data:
# DATA-NEXT: 121f0   e4110100 00000000 dc817d08 00d8ef01
#                    address = 0x111e4 -> matches symbol VA (_start)
# DATA-NEXT: 12200   20220100 00000000 20228904 0078ee01
#                    address = 0x12220 -> matches symbol VA (x)
# DATA-NEXT: 12210   dc010100 00000000 dc017804 0058ee01
#                    address = 0x101dc -> matches symbol VA (y)
#                    [    address    ] [      meta     ]

# RODATA: Contents of section .rodata:

# CAPRELOCS-LABEL: CHERI CBuildCap Capability Relocations [
# CAPRELOCS-NEXT:    Section ({{.+}}) .rela.dyn {
# CAPRELOCS-NEXT:      0x121F0 FUNC - 0x111E4 [0x101D8-0x111F0]
# CAPRELOCS-NEXT:      0x12200 DATA - 0x12220 [0x12220-0x12224]
# CAPRELOCS-NEXT:      0x12210 RODATA - 0x101DC [0x101DC-0x101E0]
# CAPRELOCS-NEXT:    }
# CAPRELOCS-NEXT:  ]

# SYM:      0000000000010190    72 NOTYPE  LOCAL  HIDDEN      1 __rela_dyn_start
# SYM-NEXT: 00000000000101d8    0  NOTYPE  LOCAL  HIDDEN      1 __rela_dyn_end
# SYM:      00000000000111e4    12 FUNC    GLOBAL DEFAULT     3 _start
# SYM:      0000000000012220    4  OBJECT  GLOBAL DEFAULT     5 x
# SYM:      00000000000101dc    4  OBJECT  GLOBAL DEFAULT     2 y


# RUN: llvm-mc -filetype=obj -triple=riscv32-unknown-elf --mattr=+zcheripurecap,+cap-mode --target-abi=il32pc64 %s -o %t.rv32.o
# RUN: ld.lld --local-caprelocs=elf %t.rv32.o -o %t.rv32

# RUN: llvm-readobj --relocs %t.rv32 | FileCheck %s --check-prefix=RELOCS32
# RUN: llvm-objdump -s --section=.rela.dyn %t.rv32 | FileCheck %s --check-prefix=RELADYN32
# RUN: llvm-objdump -s --section=.data %t.rv32 | FileCheck %s --check-prefix=DATA32
# RUN: llvm-readobj --cap-relocs-cbuildcap %t.rv32 | FileCheck %s --check-prefix=CAPRELOCS32
# RUN: llvm-readelf -s %t.rv32 | FileCheck %s --check-prefix=SYM32

# RELOCS32:      Relocations [
# RELOCS32-NEXT:   Section ({{[0-9]+}}) .rela.dyn {
# RELOCS32-NEXT:     0x12180 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS32-NEXT:     0x12188 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS32-NEXT:     0x12190 R_RISCV_CHERI_RELATIVE - 0x0
# RELOCS32-NEXT:   }

#RELADYN32: Contents of section .rela.dyn:
#RELADYN32-NEXT: 100f4
#RELADYN32-NEXT: 10104
#RELADYN32-NEXT: 10114

# DATA32: Contents of section .data:
# DATA32-NEXT: 12180  4c110100 146414d1 98210100 98710afd
#                     [ addr ] [ meta ] [ addr ] [ meta ]
#                     address = 0x1114c -> matches symbol VA (_start)
#                     address = 0x12198 -> matches symbol VA (x)
#
# DATA32-NEXT: 12190  44010100 442109f7
#                     [ addr ] [ meta ]
#                     address = 0x10144 -> matches symbol VA (y)

# CAPRELOCS32-LABEL: CHERI CBuildCap Capability Relocations [
# CAPRELOCS32-NEXT:    Section ({{.+}}) .rela.dyn {
# CAPRELOCS32-NEXT:      0x12180 FUNC - 0x1114C [0x10140-0x11180]
# CAPRELOCS32-NEXT:      0x12188 DATA - 0x12198 [0x12198-0x1219C]
# CAPRELOCS32-NEXT:      0x12190 RODATA - 0x10144 [0x10144-0x10148]
# CAPRELOCS32-NEXT:    }
# CAPRELOCS32-NEXT:  ]

# SYM32:      000100f4    36 NOTYPE  LOCAL  HIDDEN      1 __rela_dyn_start
# SYM32-NEXT: 00010118    0  NOTYPE  LOCAL  HIDDEN      1 __rela_dyn_end
# SYM32:      0001114c    12 FUNC    GLOBAL DEFAULT     3 _start
# SYM32:      00012198    4  OBJECT  GLOBAL DEFAULT     5 x
# SYM32:      00010144    4  OBJECT  GLOBAL DEFAULT     2 y

.global _start, x, y, foo, bar
.data
.type foo,@object
foo:
  ## create a function relocation
  .chericap _start
  ## create a object relocation
  .chericap x
  ## const reloc
  .chericap y
.size foo, . - foo

.type x,@object
x:
  .word 3
  .size x, 4

.rodata
  .word 0
.type y,@object
y:
  .word 7
  .size y, 4

.text
.type bar,@function
bar:
  nop
.size bar, . - bar

.type _start,@function
_start:
  nop
  nop
  nop
.size _start, . - _start

.weak __rela_dyn_start
.hidden __rela_dyn_start
.weak __rela_dyn_end
.hidden __rela_dyn_end
