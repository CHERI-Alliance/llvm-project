// RUN: not llvm-mc --triple riscv32 --mattr=+experimental-zyhybrid <%s 2>&1 \
// RUN:   | FileCheck %s --implicit-check-not=error:
// RUN: not llvm-mc --triple riscv64 --mattr=+experimental-zyhybrid <%s 2>&1 \
// RUN:   | FileCheck %s --implicit-check-not=error:

/// FIXME: this fork also defines "ymodew" as a Zcherihybrid InstAlias for
/// SCMODE (RISCVInstrInfoZCheriPurecap.td), so once the RVY match fails the
/// near-miss reporting prefers that alias and complains about the missing
/// extension instead. Upstream, which has no such alias, reports
/// "register must be a GPR excluding zero (x0)" here. The valid encodings
/// still assemble correctly (see rvy-zyhybrid.s). Same duplicate-mnemonic
/// issue as yadd/ybndswi in rvy-basic-invalid.s.
ymodew x0, a0, a0
// CHECK: :[[#@LINE-1]]:1: error: instruction requires the following: 'Zcherihybrid' (Backwards compatiblity for 'Zcheripurecap' with RISCV)
