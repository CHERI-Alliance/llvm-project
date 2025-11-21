// REQUIRES: clang
// RUN: %riscv64_bakewell_purecap_cc1 -emit-obj %s -o %t.o
// RUN-NOT: llvm-readobj -r %t.o | FileCheck --check-prefix OBJ-CAPRELOCS %s
// RUN: ld.lld %t.o -static -o %t-static.exe
// RUN: llvm-readobj --cap-relocs %t-static.exe | FileCheck --check-prefixes DUMP-CAPRELOCS %s

int value;

__attribute__((cheri_dont_seal)) static int * __leave_unsealed(void)
{
  return (&value);
}

static int *(*leave_unsealed)(void) = __leave_unsealed;

void __start(void) {
  leave_unsealed();
}

// DUMP-CAPRELOCS: __cap_relocs {
// DUMP-CAPRELOCS: 0x{{[0-9A-F]+}} FUNC(UNSEALED) - 0x{{[0-9A-F]+}} [0x{{[0-9A-F]+}}-0x{{[0-9A-F]+}}]
