// RUN: llvm-tblgen -gen-asm-matcher -I %p/../../include %s | FileCheck %s

// Check that a RegisterClass can set ParserMatchClass to a custom
// AsmOperandClass without wrapping it in a RegisterOperand.

include "llvm/Target/Target.td"

def ArchInstrInfo : InstrInfo { }
def Arch : Target {
  let InstructionSet = ArchInstrInfo;
}

def R0 : Register<"r0">;
def R1 : Register<"r1">;

def MyRegAsmOperand : AsmOperandClass {
  let Name = "MyReg";
  let PredicateMethod = "isMyReg";
  let RenderMethod = "addRegOperands";
  let DiagnosticType = "InvalidMyReg";
}

def MyReg : RegisterClass<"Arch", [i32], 0, (add R0, R1)> {
  let ParserMatchClass = MyRegAsmOperand;
}

def foo : Instruction {
  let Size = 2;
  let OutOperandList = (outs);
  let InOperandList = (ins MyReg:$r);
  let AsmString = "foo $r";
  let Namespace = "Arch";
}

// Only one MatchClassKind enumerator should exist for MyReg.
// CHECK-NOT: // register class 'MyReg'
// CHECK: MCK_MyReg, // user defined class 'MyRegAsmOperand'

// CHECK: case MCK_MyReg: {
// CHECK-NEXT: DiagnosticPredicate DP(Operand.isMyReg());
// CHECK-NEXT: if (DP.isMatch())
// CHECK-NEXT:   return MCTargetAsmParser::Match_Success;
// CHECK-NEXT: if (DP.isNearMatch())
// CHECK-NEXT:   return ArchAsmParser::Match_InvalidMyReg;
// CHECK-NEXT: break;
// CHECK-NEXT: }
