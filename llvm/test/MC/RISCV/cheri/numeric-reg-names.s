# Capability registers must keep printing their "c"-prefixed architectural
# name under -M numeric, independent of the underlying register's AsmName
# (see RISCVInstPrinter::printV9CR).

# RUN: llvm-mc -triple riscv64 -mattr=+xcheri -M numeric %s \
# RUN:     | FileCheck -check-prefix=CHECK-NUMERIC %s
# RUN: llvm-mc -filetype=obj -triple riscv64 -mattr=+xcheri < %s \
# RUN:     | llvm-objdump --no-print-imm-hex -d -M numeric --mattr=+xcheri - \
# RUN:     | FileCheck -check-prefix=CHECK-NUMERIC %s

# CHECK-NUMERIC: cincoffset c1, c0, 1
cincoffset cra, cnull, 1

# CHECK-NUMERIC: cincoffset c1, c1, 1
cincoffset cra, cra, 1

# CHECK-NUMERIC: cincoffset c1, c2, 1
cincoffset cra, csp, 1

# CHECK-NUMERIC: cincoffset c1, c3, 1
cincoffset cra, cgp, 1

# CHECK-NUMERIC: cincoffset c1, c4, 1
cincoffset cra, ctp, 1

# CHECK-NUMERIC: cincoffset c1, c5, 1
cincoffset cra, ct0, 1

# CHECK-NUMERIC: cincoffset c1, c6, 1
cincoffset cra, ct1, 1

# CHECK-NUMERIC: cincoffset c1, c7, 1
cincoffset cra, ct2, 1

# CHECK-NUMERIC: cincoffset c1, c8, 1
cincoffset cra, cs0, 1

# CHECK-NUMERIC: cincoffset c1, c9, 1
cincoffset cra, cs1, 1

# CHECK-NUMERIC: cincoffset c1, c10, 1
cincoffset cra, ca0, 1

# CHECK-NUMERIC: cincoffset c1, c11, 1
cincoffset cra, ca1, 1

# CHECK-NUMERIC: cincoffset c1, c12, 1
cincoffset cra, ca2, 1

# CHECK-NUMERIC: cincoffset c1, c13, 1
cincoffset cra, ca3, 1

# CHECK-NUMERIC: cincoffset c1, c14, 1
cincoffset cra, ca4, 1

# CHECK-NUMERIC: cincoffset c1, c15, 1
cincoffset cra, ca5, 1

# CHECK-NUMERIC: cincoffset c1, c16, 1
cincoffset cra, ca6, 1

# CHECK-NUMERIC: cincoffset c1, c17, 1
cincoffset cra, ca7, 1

# CHECK-NUMERIC: cincoffset c1, c18, 1
cincoffset cra, cs2, 1

# CHECK-NUMERIC: cincoffset c1, c19, 1
cincoffset cra, cs3, 1

# CHECK-NUMERIC: cincoffset c1, c20, 1
cincoffset cra, cs4, 1

# CHECK-NUMERIC: cincoffset c1, c21, 1
cincoffset cra, cs5, 1

# CHECK-NUMERIC: cincoffset c1, c22, 1
cincoffset cra, cs6, 1

# CHECK-NUMERIC: cincoffset c1, c23, 1
cincoffset cra, cs7, 1

# CHECK-NUMERIC: cincoffset c1, c24, 1
cincoffset cra, cs8, 1

# CHECK-NUMERIC: cincoffset c1, c25, 1
cincoffset cra, cs9, 1

# CHECK-NUMERIC: cincoffset c1, c26, 1
cincoffset cra, cs10, 1

# CHECK-NUMERIC: cincoffset c1, c27, 1
cincoffset cra, cs11, 1

# CHECK-NUMERIC: cincoffset c1, c28, 1
cincoffset cra, ct3, 1

# CHECK-NUMERIC: cincoffset c1, c29, 1
cincoffset cra, ct4, 1

# CHECK-NUMERIC: cincoffset c1, c30, 1
cincoffset cra, ct5, 1

# CHECK-NUMERIC: cincoffset c1, c31, 1
cincoffset cra, ct6, 1

# DDC has no separate architectural/ABI spelling.
# CHECK-NUMERIC: cbuildcap c1, ddc, c3
cbuildcap cra, ddc, cgp
