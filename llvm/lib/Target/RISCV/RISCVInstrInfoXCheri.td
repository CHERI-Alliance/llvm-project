//===-- RISCVInstrInfoXCheri.td - XCheri RISCV instructions -*- tblgen-*---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// RISC-V specific DAG Nodes.
//===----------------------------------------------------------------------===//

// Target-dependent type requirements.
def SDT_RISCVCapCall        : SDTypeProfile<0, -1, [SDTCisVT<0, YLenVT>]>;

def SDT_RISCVCheriBoolUnary : SDTypeProfile<1, 1, [
  SDTCisInt<0>, SDTCisVT<1, YLenVT>
]>;

def SDT_RISCVCheriBoolBinary : SDTypeProfile<1, 2, [
  SDTCisInt<0>, SDTCisVT<1, YLenVT>, SDTCisVT<2, YLenVT>
]>;

// Target-dependent nodes.
def riscv_cap_call        : SDNode<"RISCVISD::CAP_CALL", SDT_RISCVCapCall,
                                   [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                                    SDNPVariadic]>;
def riscv_cap_tail        : SDNode<"RISCVISD::CAP_TAIL", SDT_RISCVCapCall,
                                   [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                                    SDNPVariadic]>;
def riscv_cap_tag_get     : SDNode<"RISCVISD::CAP_TAG_GET",
                                   SDT_RISCVCheriBoolUnary>;
def riscv_cap_sealed_get  : SDNode<"RISCVISD::CAP_SEALED_GET",
                                   SDT_RISCVCheriBoolUnary>;
def riscv_cap_subset_test : SDNode<"RISCVISD::CAP_SUBSET_TEST",
                                   SDT_RISCVCheriBoolBinary>;
def riscv_cap_equal_exact : SDNode<"RISCVISD::CAP_EQUAL_EXACT",
                                   SDT_RISCVCheriBoolBinary>;
def riscv_cllc            : SDNode<"RISCVISD::CLLC", SDT_RISCVSymLoad>;
def riscv_clgc            : SDNode<"RISCVISD::CLGC", SDT_RISCVSymLoad,
                                   [SDNPHasChain, SDNPMayLoad, SDNPMemOperand]>;
def riscv_cla_tls_ie      : SDNode<"RISCVISD::CLA_TLS_IE", SDT_RISCVSymLoad,
                                   [SDNPHasChain, SDNPMayLoad, SDNPMemOperand]>;
def riscv_clc_tls_gd      : SDNode<"RISCVISD::CLC_TLS_GD", SDT_RISCVSymLoad>;

//===----------------------------------------------------------------------===//
// Operand and SDNode transformation definitions.
//===----------------------------------------------------------------------===//

def cap_call_symbol : Operand<YLenVT> {
  let ParserMatchClass = CallSymbol;
}

def pseudo_cap_jump_symbol : Operand<YLenVT> {
  let ParserMatchClass = PseudoJumpSymbol;
}

def CheriZeroOffsetMemOpOperand : AsmOperandClass {
  let Name = "CheriZeroOffsetMemOpOperand";
  let RenderMethod = "addRegOperands";
  let PredicateMethod = "isV9CR";
  let ParserMethod = "parseZeroOffsetMemOp";
}

def V9CRMemZeroOffset : MemOperand<YGPR> {
  let ParserMatchClass = CheriZeroOffsetMemOpOperand;
  let PrintMethod = "printV9CRZeroOffsetMemOp";
}

def YGPRZeroOffsetMemOpOperand : AsmOperandClass {
  let Name = "YGPRZeroOffsetMemOpOperand";
  let RenderMethod = "addRegOperands";
  let PredicateMethod = "isYGPR";
  let ParserMethod = "parseZeroOffsetMemOp";
  let DiagnosticType = "InvalidYGPR";
}

def YGPRMemZeroOffset : MemOperand<YGPR> {
  let ParserMatchClass = YGPRZeroOffsetMemOpOperand;
  let PrintMethod = "printV9CRZeroOffsetMemOp";
}

def RVYCompatZeroOffsetMemOpOperand : AsmOperandClass {
  let Name = "RVYCompatZeroOffsetMemOpOperand";
  let RenderMethod = "addRegOperands";
  let PredicateMethod = "isRVYOrV9Reg";
  let ParserMethod = "parseZeroOffsetMemOp";
  let DiagnosticType = "InvalidRVYCompatGPCR";
}

def RVYCompatMemZeroOffset : MemOperand<YGPR> {
  let ParserMatchClass = RVYCompatZeroOffsetMemOpOperand;
  let PrintMethod = "printV9CRZeroOffsetMemOp";
}

// These mirror the V9CR-family RegisterOperands in RISCVRegisterInfo.td: the
// base register of a capability memory operand needs the same "c"-prefixed
// printing as a bare V9CR operand (see printV9CR / V9CRRegisterOperand for
// why this can't just be the register's default name).
def GPCRMem : MemOperand<YGPR> {
  let ParserMatchClass = V9CROperand;
  let PrintMethod = "printV9CR";
}
def RVYCompatGPCRMem : MemOperand<YGPR> {
  let ParserMatchClass = RVYCompatGPCROperand;
  let PrintMethod = "printV9CR";
}

def CSPMem : MemOperand<YSP> {
  let ParserMatchClass = V9CSPOperand;
  let PrintMethod = "printV9CR";
}
def RVYCompatCSPMem : MemOperand<YSP> {
  let ParserMatchClass = RVYCompatCSPOperand;
  let PrintMethod = "printV9CR";
}

def GPCRCMem : MemOperand<YGPRC> {
  let ParserMatchClass = V9CRCOperand;
  let PrintMethod = "printV9CR";
}
def RVYCompatGPCRCMem : MemOperand<YGPRC> {
  let ParserMatchClass = RVYCompatGPCRCOperand;
  let PrintMethod = "printV9CR";
}

// A 9-bit unsigned immediate where the least significant four bits are zero.
def uimm9_lsb0000 : Operand<XLenVT>,
                    ImmLeaf<XLenVT, [{return isShiftedUInt<5, 4>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<9, "Lsb0000">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<9>";
  let MCOperandPredicate = [{
    int64_t Imm;
    if (!MCOp.evaluateAsConstantImm(Imm))
      return false;
    return isShiftedUInt<5, 4>(Imm);
  }];
}

// A 10-bit unsigned immediate where the least significant four bits are zero.
def uimm10_lsb0000 : Operand<XLenVT>,
                     ImmLeaf<XLenVT, [{return isShiftedUInt<6, 4>(Imm);}]> {
  let ParserMatchClass = UImmAsmOperand<10, "Lsb0000">;
  let EncoderMethod = "getImmOpValue";
  let DecoderMethod = "decodeUImmOperand<10>";
  let MCOperandPredicate = [{
    int64_t Imm;
    if (!MCOp.evaluateAsConstantImm(Imm))
      return false;
    return isShiftedUInt<6, 4>(Imm);
  }];
}

def CapFrameAddrRegImm : ComplexPattern<cPTR, 2,
                                        "SelectCapFrameAddrRegImm",
                                        [frameindex, cptradd]>;
def CapRegImm : ComplexPattern<cPTR, 2, "SelectCapRegImm">;

//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

include "RISCVInstrFormatsXCheri.td"

//===----------------------------------------------------------------------===//
// Instruction Class Templates
//===----------------------------------------------------------------------===//

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Cheri_SrcDst<bits<7> funct7, bits<5> funct5, bits<3> funct3, RISCVOpcode opcode,
                   string opcodestr, DAGOperand rdClass=GPR,
                   DAGOperand rs1Operand=V9CR>
      : RVInstCheriSrcDst<funct7, funct5, funct3, opcode, (outs rdClass:$rd),
                          (ins rs1Operand:$rs1), opcodestr, "$rd, $rs1">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class CheriRVInstR<bits<7> funct7, bits<3> funct3, RISCVOpcode opcode,
                   string opcodestr, DAGOperand rdClass=GPR,
                   DAGOperand rs1Class=GPR, DAGOperand rs2Class=GPR>
      : RVInstR<funct7, funct3, opcode, (outs rdClass:$rd),
                (ins rs1Class:$rs1, rs2Class:$rs2), opcodestr, "$rd, $rs1, $rs2"
               >;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class CheriRVInstrI<bits<3> funct3, RISCVOpcode opcode, string opcodestr, bit simm>
      : RVInstI<funct3, opcode, (outs V9CR:$rd),
                (ins V9CR:$rs1, !if(simm,simm12,uimm12):$imm12),
                opcodestr, "$rd, $rs1, $imm12">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Cheri_r<bits<5> funct5, string opcodestr, DAGOperand rdClass=GPR,
              DAGOperand rs1Operand=V9CR>
    : RVInstCheriSrcDst<0x7f, funct5, 0, OPC_CHERI, (outs rdClass:$rd),
                        (ins rs1Operand:$rs1), opcodestr, "$rd, $rs1">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Cheri_rr<bits<7> funct7, string opcodestr, DAGOperand rdClass=V9CR,
               DAGOperand rs2Class=GPR, DAGOperand rs1Class=V9CR>
    : RVInstR<funct7, 0, OPC_CHERI, (outs rdClass:$rd),
              (ins rs1Class:$rs1, rs2Class:$rs2),
              opcodestr, "$rd, $rs1, $rs2">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
class Cheri_ri<bits<3> funct3, string opcodestr, bit simm>
    : RVInstI<funct3, OPC_CHERI, (outs V9CR:$rd),
              (ins V9CR:$rs1, !if(simm,simm12,uimm12):$imm12),
              opcodestr, "$rd, $rs1, $imm12">;

let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in
class Cheri_clear<bits<5> funct5, string opcodestr>
    : RVInstCheriClear<0x7f, funct5, 0, OPC_CHERI, (outs),
                       (ins uimm2:$quarter, uimm8:$mask),
                       opcodestr, "$quarter, $mask">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class CheriLoad_r<bits<5> op, string opcodestr, DAGOperand rdClass,
                  RegisterOperand rs1Operand>
    : RVInstCheriSrcDst<0x7d, op, 0, OPC_CHERI, (outs rdClass:$rd),
                        (ins rs1Operand:$rs1), opcodestr, "$rd, $rs1">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class CheriStore_r<bits<5> op, string opcodestr, DAGOperand rs2Class,
                   RegisterOperand rs1Operand>
    : RVInstCheriTwoSrc<0x7c, op, 0, OPC_CHERI, (outs),
                        (ins rs2Class:$rs2, rs1Operand:$rs1),
                        opcodestr, "$rs2, $rs1">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1, Constraints = "$rd = $rs2" in
class CheriStoreCond_r<bits<5> op, string opcodestr, DAGOperand rs2Class,
                       RegisterOperand rs1Operand>
    : RVInstCheriTwoSrc<0x7c, op, 0, OPC_CHERI, (outs rs2Class:$rd),
                        (ins rs2Class:$rs2, rs1Operand:$rs1),
                        opcodestr, "$rs2, $rs1">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class LR_C_r<bit aq, bit rl, bits<3> funct3, string opcodestr>
    : RVInstRAtomic<0b00010, aq, rl, funct3, OPC_AMO,
                    (outs V9CR:$rd), (ins GPRMemZeroOffset:$rs1),
                    opcodestr, "$rd, $rs1"> {
  let rs2 = 0;
}

multiclass LR_C_r_aq_rl<string clenstr, bits<3> funct3, string opcodestr> {
  defvar optUnderScore = !if(!eq(clenstr, ""), "", "_");
  def optUnderScore # clenstr       : LR_C_r<0, 0, funct3, opcodestr>;
  def _AQ # optUnderScore # clenstr    : LR_C_r<1, 0, funct3, opcodestr # ".aq">;
  def _RL # optUnderScore # clenstr    : LR_C_r<0, 1, funct3, opcodestr # ".rl">;
  def _AQ_RL # optUnderScore # clenstr : LR_C_r<1, 1, funct3, opcodestr # ".aqrl">;
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 1 in
class AMO_C_rr<bits<5> funct5, bit aq, bit rl, bits<3> funct3, string opcodestr,
               DAGOperand rdClass>
    : RVInstRAtomic<funct5, aq, rl, funct3, OPC_AMO,
                    (outs rdClass:$rd), (ins GPRMemZeroOffset:$rs1, V9CR:$rs2),
                    opcodestr, "$rd, $rs2, $rs1">;

multiclass AMO_C_rr_aq_rl<string clenstr, bits<5> funct5, bits<3> funct3,
                          string opcodestr, DAGOperand rdClass> {
  defvar optUnderScore = !if(!eq(clenstr, ""), "", "_");
  def optUnderScore  # clenstr       : AMO_C_rr<funct5, 0, 0, funct3, opcodestr, rdClass>;
  def _AQ # optUnderScore # clenstr    : AMO_C_rr<funct5, 1, 0, funct3, opcodestr # ".aq",
                                   rdClass>;
  def _RL # optUnderScore # clenstr    : AMO_C_rr<funct5, 0, 1, funct3, opcodestr # ".rl",
                                   rdClass>;
  def _AQ_RL # optUnderScore # clenstr : AMO_C_rr<funct5, 1, 1, funct3, opcodestr # ".aqrl",
                                   rdClass>;
}

multiclass CheriLoad_ri<bits<3> funct3, string opcodestr> {
  let hasSideEffects = 0, mayLoad = 1, mayStore = 0,
      DecoderNamespace = "CapModeOnly_" in
  def "" : RVInstI<funct3, OPC_LOAD, (outs GPR:$rd),
                   (ins RVYCompatGPCRMem:$rs1, simm12:$imm12), opcodestr,
                   "$rd, ${imm12}(${rs1})">;
  def : InstAlias<"c" # opcodestr # " $rd, ${imm12}(${rs1})",
                  (!cast<Instruction>(NAME) GPR:$rd, GPCRMem:$rs1, simm12:$imm12),
                  0>;
}

multiclass CheriStore_ri<bits<3> funct3, string opcodestr> {
  let hasSideEffects = 0, mayLoad = 0, mayStore = 1,
      DecoderNamespace = "CapModeOnly_" in
  def "" : RVInstS<funct3, OPC_STORE, (outs),
                   (ins GPR:$rs2, RVYCompatGPCRMem:$rs1, simm12:$imm12),
                   opcodestr, "$rs2, ${imm12}(${rs1})">;
  def : InstAlias<"c" # opcodestr # "$rs2, ${imm12}(${rs1})",
                  (!cast<Instruction>(NAME) GPR:$rs2, GPCRMem:$rs1, simm12:$imm12),
                  0>;
}


multiclass CLR_r<bit aq, bit rl, bits<3> funct3, string opcodestr,
                 string Namespace> {
  let hasSideEffects = 0, mayLoad = 1, mayStore = 0,
      DecoderNamespace = Namespace in
  def "" : RVInstRAtomic<0b00010, aq, rl, funct3, OPC_AMO,
                         (outs GPR:$rd), (ins RVYCompatMemZeroOffset:$rs1),
                         opcodestr, "$rd, $rs1"> {
    let rs2 = 0;
  }
  def : InstAlias<"c" # opcodestr # "$rd, $rs1",
                  (!cast<Instruction>(NAME) GPR:$rd, V9CRMemZeroOffset:$rs1),
                  0>;
}

multiclass CLR_r_aq_rl<bits<3> funct3, string opcodestr,
                       string Namespace = "CapModeOnly_"> {
  defm ""     : CLR_r<0, 0, funct3, opcodestr, Namespace>;
  defm _AQ    : CLR_r<1, 0, funct3, opcodestr # ".aq", Namespace>;
  defm _RL    : CLR_r<0, 1, funct3, opcodestr # ".rl", Namespace>;
  defm _AQ_RL : CLR_r<1, 1, funct3, opcodestr # ".aqrl", Namespace>;
}

multiclass CAMO_rr<bits<5> funct5, bit aq, bit rl, bits<3> funct3,
                   string opcodestr, string Namespace> {
  let hasSideEffects = 0, mayLoad = 1, mayStore = 1,
      DecoderNamespace = Namespace in
  def "" : RVInstRAtomic<funct5, aq, rl, funct3, OPC_AMO,
                         (outs GPR:$rd), (ins RVYCompatMemZeroOffset:$rs1, GPR:$rs2),
                         opcodestr, "$rd, $rs2, $rs1">;
  def : InstAlias<"c" # opcodestr # "$rd, $rs2, $rs1",
                  (!cast<Instruction>(NAME) GPR:$rd, V9CRMemZeroOffset:$rs1,
                   GPR:$rs2), 0>;
}

multiclass CAMO_rr_aq_rl<bits<5> funct5, bits<3> funct3, string opcodestr,
                         string Namespace = "CapModeOnly_"> {
  defm ""     : CAMO_rr<funct5, 0, 0, funct3, opcodestr, Namespace>;
  defm _AQ    : CAMO_rr<funct5, 1, 0, funct3, opcodestr # ".aq", Namespace>;
  defm _RL    : CAMO_rr<funct5, 0, 1, funct3, opcodestr # ".rl", Namespace>;
  defm _AQ_RL : CAMO_rr<funct5, 1, 1, funct3, opcodestr # ".aqrl", Namespace>;
}

multiclass CLR_C_r<bit aq, bit rl, bits<3> funct3, string opcodestr,
                   string Namespace> {
let hasSideEffects = 0, mayLoad = 1, mayStore = 0,
    DecoderNamespace = Namespace in
  def "" : RVInstRAtomic<0b00010, aq, rl, funct3, OPC_AMO,
                         (outs V9CR:$rd), (ins V9CRMemZeroOffset:$rs1),
                         opcodestr, "$rd, $rs1"> {
    let rs2 = 0;
  }
  def : InstAlias<"c" # opcodestr # "$rd, $rs1",
                  (!cast<Instruction>(NAME) V9CR:$rd, V9CRMemZeroOffset:$rs1),
                  0>;
}

multiclass CLR_C_r_aq_rl<string clenstr, bits<3> funct3, string opcodestr,
                         string Namespace = "CapModeOnly_"> {
  defvar optUnderScore = !if(!eq(clenstr, ""), "", "_");
  defm optUnderScore # clenstr       : CLR_C_r<0, 0, funct3, opcodestr, Namespace>;
  defm _AQ # optUnderScore # clenstr    : CLR_C_r<1, 0, funct3, opcodestr # ".aq", Namespace>;
  defm _RL # optUnderScore # clenstr    : CLR_C_r<0, 1, funct3, opcodestr # ".rl", Namespace>;
  defm _AQ_RL # optUnderScore # clenstr : CLR_C_r<1, 1, funct3, opcodestr # ".aqrl", Namespace>;
}

multiclass CAMO_C_rr<bits<5> funct5, bit aq, bit rl, bits<3> funct3,
                string opcodestr, DAGOperand rdClass, string Namespace> {
  let hasSideEffects = 0, mayLoad = 1, mayStore = 1,
      DecoderNamespace = Namespace in
  def "" : RVInstRAtomic<funct5, aq, rl, funct3, OPC_AMO,
                         (outs rdClass:$rd),
                         (ins V9CRMemZeroOffset:$rs1, V9CR:$rs2),
                         opcodestr, "$rd, $rs2, $rs1">;
  def : InstAlias<"c" # opcodestr # "$rd, $rs2, $rs1",
                 (!cast<Instruction>(NAME) rdClass:$rd, V9CRMemZeroOffset:$rs1,
                  V9CR:$rs2), 0>;
}

multiclass CAMO_C_rr_aq_rl<string clenstr, bits<5> funct5, bits<3> funct3,
                          string opcodestr, DAGOperand rdClass,
                          string Namespace = "CapModeOnly_"> {
  defvar optUnderScore = !if(!eq(clenstr, ""), "", "_");
  defm optUnderScore # clenstr       : CAMO_C_rr<funct5, 0, 0, funct3, opcodestr, rdClass,
                                     Namespace>;
  defm _AQ # optUnderScore # clenstr    : CAMO_C_rr<funct5, 1, 0, funct3, opcodestr # ".aq",
                                     rdClass, Namespace>;
  defm _RL # optUnderScore # clenstr    : CAMO_C_rr<funct5, 0, 1, funct3, opcodestr # ".rl",
                                     rdClass, Namespace>;
  defm _AQ_RL # optUnderScore # clenstr : CAMO_C_rr<funct5, 1, 1, funct3, opcodestr # ".aqrl",
                                     rdClass, Namespace>;
}

multiclass CAMO_cas<bits<5> funct5, bit aq, bit rl, bits<3> funct3, string opcodestr,
              DAGOperand RC, string Namespace> {
  let hasSideEffects = 0, mayLoad = 1, mayStore = 1, Constraints = "$rd = $rd_wb",
      DecoderNamespace = Namespace in
  def "" : RVInstRAtomic<funct5, aq, rl, funct3, OPC_AMO,
                         (outs RC:$rd_wb), (ins RC:$rd, V9CRMemZeroOffset:$rs1, RC:$rs2),
                         opcodestr, "$rd, $rs2, $rs1">;
  def : InstAlias<"c" # opcodestr # "$rd, $rs2, $rs1",
                  (!cast<Instruction>(NAME) RC:$rd, V9CRMemZeroOffset:$rs1,
                   RC:$rs2), 0>;
}

multiclass CAMO_cas_aq_rl<bits<5> funct5, bits<3> funct3, string opcodestr,
                         DAGOperand RC, string Namespace = "CapModeOnly_"> {
  defm ""     : CAMO_cas<funct5, 0, 0, funct3, opcodestr, RC, Namespace>;
  defm _AQ    : CAMO_cas<funct5, 1, 0, funct3, opcodestr # ".aq", RC, Namespace>;
  defm _RL    : CAMO_cas<funct5, 0, 1, funct3, opcodestr # ".rl", RC, Namespace>;
  defm _AQ_RL : CAMO_cas<funct5, 1, 1, funct3, opcodestr # ".aqrl", RC, Namespace>;
}

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class CCheriStackLoad<bits<3> funct3, string OpcodeStr,
                      DAGOperand cls, DAGOperand opnd,
                      DAGOperand rs1Operand = RVYCompatCSPMem>
    : RVInst16CI<funct3, 0b10, (outs cls:$rd), (ins rs1Operand:$rs1, opnd:$imm),
                 OpcodeStr, "$rd, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class CCheriStackStore<bits<3> funct3, string OpcodeStr,
                       DAGOperand cls, DAGOperand opnd,
                       DAGOperand rs1Operand = RVYCompatCSPMem>
    : RVInst16CSS<funct3, 0b10, (outs), (ins cls:$rs2, rs1Operand:$rs1, opnd:$imm),
                  OpcodeStr, "$rs2, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
class CCheriLoad_ri<bits<3> funct3, string OpcodeStr,
                    DAGOperand cls, DAGOperand opnd,
                    DAGOperand rs1Operand = RVYCompatGPCRCMem>
    : RVInst16CL<funct3, 0b00, (outs cls:$rd), (ins rs1Operand:$rs1, opnd:$imm),
                 OpcodeStr, "$rd, ${imm}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
class CCheriStore_rri<bits<3> funct3, string OpcodeStr,
                      DAGOperand cls, DAGOperand opnd,
                      DAGOperand rs1Operand = RVYCompatGPCRCMem>
    : RVInst16CS<funct3, 0b00, (outs), (ins cls:$rs2, rs1Operand:$rs1, opnd:$imm),
                 OpcodeStr, "$rs2, ${imm}(${rs1})">;

//===----------------------------------------------------------------------===//
// Capability-Inspection Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
def CGetPerm   : Cheri_r<0x0, "cgetperm">;
def : InstAlias<"gcperm $rd, $rs1", (CGetPerm GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ypermr $rd, $rs1", (CGetPerm GPR:$rd, YGPR:$rs1), 0>;
def CGetType   : Cheri_r<0x1, "cgettype">;
def : InstAlias<"gctype $rd, $rs1", (CGetType GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ytyper $rd, $rs1", (CGetType GPR:$rd, YGPR:$rs1), 0>;
def CGetBase   : Cheri_r<0x2, "cgetbase">;
def : InstAlias<"gcbase $rd, $rs1", (CGetBase GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ybaser $rd, $rs1", (CGetBase GPR:$rd, YGPR:$rs1), 0>;
def CGetLen    : Cheri_r<0x3, "cgetlen">;
def : InstAlias<"gclen $rd, $rs1", (CGetLen GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ylenr $rd, $rs1", (CGetLen GPR:$rd, YGPR:$rs1), 0>;
def CGetTag    : Cheri_r<0x4, "cgettag">;
def : InstAlias<"gctag $rd, $rs1", (CGetTag GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ytagr $rd, $rs1", (CGetTag GPR:$rd, YGPR:$rs1), 0>;
def CGetSealed : Cheri_r<0x5, "cgetsealed">;
def CGetOffset : Cheri_r<0x6, "cgetoffset">;
def CGetFlags  : Cheri_r<0x7, "cgetflags">;
// NB: No alias for gcmode->cgetflags since the result is inverted.
def CGetHigh   : Cheri_r<0x17, "cgethigh">;
def : InstAlias<"gchi $rd, $rs1", (CGetHigh GPR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"yhir $rd, $rs1", (CGetHigh GPR:$rd, YGPR:$rs1), 0>;
// For backwards compatibility we still accept cgetaddr from assembly.
let mayStore = false, mayLoad = false, Size = 4, isCodeGenOnly = false,
hasSideEffects = false in
def PseudoCGetAddr : Pseudo<(outs GPR:$rd), (ins V9CR:$cs1), [],
                            "cgetaddr", "$rd, $cs1"> { let Predicates = [HasZCheriPurecapOrCheri]; }
}

//===----------------------------------------------------------------------===//
// Capability-Modification Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
let defsCanBeSealed = 1 in
def CSeal           : Cheri_rr<0xb, "cseal", V9CR, V9CR>;
def CUnseal         : Cheri_rr<0xc, "cunseal", V9CR, V9CR>;
def CAndPerm        : Cheri_rr<0xd, "candperm">;
def : InstAlias<"acperm $rd, $rs1, $rs2", (CAndPerm V9CR:$rd, V9CR:$rs1, GPR:$rs2), 0>;
def CSetFlags       : Cheri_rr<0xe, "csetflags">;
// NB: No alias for scmode->csetflags since the argument is inverted.
def CSetOffset      : Cheri_rr<0xf, "csetoffset">;
def CSetAddr        : Cheri_rr<0x10, "csetaddr">;
def : InstAlias<"scaddr $rd, $rs1, $rs2", (CSetAddr V9CR:$rd, V9CR:$rs1, GPR:$rs2), 0>;
def : InstAlias<"yaddrw $rd, $rs1, $rs2", (CSetAddr YGPR:$rd, YGPR:$rs1, GPR:$rs2), 0>;
def CSetHigh        : Cheri_rr<0x16, "csethigh">;
def : InstAlias<"schi $rd, $rs1, $rs2", (CSetHigh V9CR:$rd, V9CR:$rs1, GPR:$rs2), 0>;
def : InstAlias<"yhiw $rd, $rs1, $rs2", (CSetHigh YGPR:$rd, YGPR:$rs1, GPR:$rs2), 0>;
let isReMaterializable = 1, isAsCheapAsAMove = 1 in
def CIncOffset      : Cheri_rr<0x11, "cincoffset">;
def : InstAlias<"add $cd, $cs1, $rs2",
                (CIncOffset V9CR:$cd, V9CR:$cs1, GPR:$rs2), 0>;
def : InstAlias<"yadd $cd, $cs1, $rs2",
                (CIncOffset YGPR:$cd, YGPR:$cs1, GPR:$rs2), 0>;
let isReMaterializable = 1, isAsCheapAsAMove = 1 in
def CIncOffsetImm   : Cheri_ri<0x1, "cincoffset", 1>;
def : InstAlias<"addi $cd, $cs1, $imm",
                (CIncOffsetImm V9CR:$cd, V9CR:$cs1, simm12:$imm), 0>;
def : InstAlias<"add $cd, $cs1, $imm",
                (CIncOffsetImm V9CR:$cd, V9CR:$cs1, simm12:$imm), 0>;
def : InstAlias<"yaddi $cd, $cs1, $imm",
                (CIncOffsetImm YGPR:$cd, YGPR:$cs1, simm12:$imm), 0>;
def : InstAlias<"yadd $cd, $cs1, $imm",
                (CIncOffsetImm YGPR:$cd, YGPR:$cs1, simm12:$imm), 0>;
def CSetBounds      : Cheri_rr<0x8, "csetbounds">;
def : InstAlias<"scbndsr $cd, $cs1, $rs2",
                (CSetBounds V9CR:$cd, V9CR:$cs1, GPR:$rs2), 0>;
def : InstAlias<"ybndsrw $rd, $rs1, $rs2", (CSetBounds YGPR:$rd, YGPR:$rs1, GPR:$rs2), 0>;
def CSetBoundsExact : Cheri_rr<0x9, "csetboundsexact">;
def : InstAlias<"scbnds $cd, $cs1, $rs2",
                (CSetBoundsExact V9CR:$cd, V9CR:$cs1, GPR:$rs2), 0>;
def : InstAlias<"ybndsw $cd, $cs1, $rs2",
                (CSetBoundsExact YGPR:$cd, YGPR:$cs1, GPR:$rs2), 0>;
def CSetBoundsImm   : Cheri_ri<0x2, "csetbounds", 0>;
// TODO: should restrict the valid immediates for scbnds(i)
def : InstAlias<"scbndsi $cd, $cs1, $imm",
                (CSetBoundsImm V9CR:$cd, V9CR:$cs1, uimm12:$imm), 0>;
def : InstAlias<"scbnds $cd, $cs1, $imm",
                (CSetBoundsImm V9CR:$cd, V9CR:$cs1, uimm12:$imm), 0>;
def : InstAlias<"ybndsw $cd, $cs1, $imm",
                (CSetBoundsImm YGPR:$cd, YGPR:$cs1, uimm12:$imm), 0>;
def : InstAlias<"ybndswi $rd, $rs1, $imm", (CSetBoundsImm YGPR:$rd, YGPR:$rs1, uimm12:$imm), 0>;
def CClearTag       : Cheri_r<0xb, "ccleartag", V9CR>;
let defsCanBeSealed = 1 in
def CBuildCap       : Cheri_rr<0x1d, "cbuildcap", V9CR, V9CR, V9CRC0IsDDC>;
def : InstAlias<"cbld $cd, $cs1, $cs2",
                (CBuildCap V9CR:$cd, V9CRNoC0:$cs1, V9CR:$cs2), 0>;
def : InstAlias<"ybld $cd, $cs1, $cs2",
                (CBuildCap YGPR:$cd, YGPRNoX0:$cs1, YGPR:$cs2), 0>;
def CCopyType       : Cheri_rr<0x1e, "ccopytype", V9CR, V9CR>;
let defsCanBeSealed = 1 in
def CCSeal          : Cheri_rr<0x1f, "ccseal", V9CR, V9CR>;
let defsCanBeSealed = 1 in
def CSealEntry      : Cheri_r<0x11, "csealentry", V9CR>;
def : InstAlias<"sentry $rd, $rs1", (CSealEntry V9CR:$rd, V9CR:$rs1), 0>;
def : InstAlias<"ysentry $rd, $rs1", (CSealEntry YGPR:$rd, YGPR:$rs1), 0>;

def : InstAlias<"cincoffsetimm $cd, $cs1, $imm",
                (CIncOffsetImm V9CR:$cd, V9CR:$cs1, simm12:$imm), 0>;
def : InstAlias<"csetboundsimm $cd, $cs1, $imm",
                (CSetBoundsImm V9CR:$cd, V9CR:$cs1, uimm12:$imm), 0>;
}

//===----------------------------------------------------------------------===//
// Pointer-Arithmetic Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCodeGenOnly = 0,
    isAsmParserOnly = 1 in
def PseudoCSub : Pseudo<(outs GPR:$rd), (ins V9CR:$cs1, V9CR:$cs2), [],
                        "csub", "$rd, $cs1, $cs2">;
let isMoveReg = 1, isReMaterializable = 1, isAsCheapAsAMove = 1,
    defsCanBeSealed = 1 in
def CMove       : Cheri_r<0xa, "cmove", V9CR>;
def : InstAlias<"cmv $cd, $cs1", (CMove V9CR:$cd, V9CR:$cs1), 0>;
def : InstAlias<"ymv $cd, $cs1", (CMove YGPR:$cd, YGPR:$cs1), 0>;
}

//===----------------------------------------------------------------------===//
// Control-Flow Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
let isCall = 1, hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def JALR_CAP : RVInstCheriSrcDst<0x7f, 0xc, 0, OPC_CHERI, (outs V9CR:$rd),
                                 (ins V9CR:$rs1), "jalr.cap", "$rd, $rs1">;

let isCall = 1, hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def JALR_PCC : RVInstCheriSrcDst<0x7f, 0x14, 0, OPC_CHERI, (outs GPR:$rd),
                                 (ins GPR:$rs1), "jalr.pcc", "$rd, $rs1">;

let isCall = 1, hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def CInvoke : RVInstCheriTwoSrc<0x7e, 0x1, 0, OPC_CHERI, (outs),
                                (ins V9CR:$rs1, V9CR:$rs2),
                                "cinvoke", "$rs1, $rs2">;

def : InstAlias<"jalr.cap $cs1", (JALR_CAP X1_Y, V9CR:$cs1), 1>;
def : InstAlias<"jr.cap $cs1",   (JALR_CAP X0_Y, V9CR:$cs1), 1>;
def : InstAlias<"ret.cap",       (JALR_CAP X0_Y,        X1_Y), 2>;

def : InstAlias<"jalr.pcc $cs1", (JALR_PCC X1, GPR:$cs1), 1>;
def : InstAlias<"jr.pcc $cs1",   (JALR_PCC X0, GPR:$cs1), 1>;
def : InstAlias<"ret.pcc",       (JALR_PCC X0,       X1), 2>;
}

//===----------------------------------------------------------------------===//
// Assertion Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
def CTestSubset : Cheri_rr<0x20, "ctestsubset", GPR, V9CR, V9CRC0IsDDC>;
def : InstAlias<"scss $rd, $cs1, $cs2",
                (CTestSubset GPR:$rd, V9CRNoC0:$cs1, V9CR:$cs2), 0>;
def : InstAlias<"yss $rd, $cs1, $cs2",
                (CTestSubset GPR:$rd, YGPRNoX0:$cs1, YGPR:$cs2), 0>;
def CSEQX       : Cheri_rr<0x21, "csetequalexact", GPR, V9CR, V9CR>;

def : InstAlias<"cseqx $rd, $cs1, $cs2", (CSEQX GPR:$rd, V9CR:$cs1, V9CR:$cs2)>;
def : InstAlias<"sceq $rd, $cs1, $cs2", (CSEQX GPR:$rd, V9CR:$cs1, V9CR:$cs2), 0>;
def : InstAlias<"yeq $rd, $cs1, $cs2", (CSEQX GPR:$rd, YGPR:$cs1, YGPR:$cs2), 0>;
}

//===----------------------------------------------------------------------===//
// Special Capabilty Register Access Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
let hasSideEffects = 1, mayLoad = 0, mayStore = 0 in
def CSpecialRW : RVInstCheriSCR<0x1, 0, OPC_CHERI, (outs V9CR:$rd),
                                (ins special_capreg:$imm5, V9CR:$rs1),
                                "cspecialrw", "$rd, $imm5, $rs1">;

def : InstAlias<"cspecialr $cd, $scr",
                (CSpecialRW V9CR:$cd, special_capreg:$scr,           X0_Y)>;
def : InstAlias<"cspecialw $scr, $cs",
                (CSpecialRW       X0_Y, special_capreg:$scr, V9CRNoC0:$cs)>;
}

//===----------------------------------------------------------------------===//
// Fast Register-Clearing Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri], hasSideEffects = 1 in {
def CClear  : Cheri_clear<0xe, "cclear">;
def FPClear : Cheri_clear<0x10, "fpclear">;
}

//===----------------------------------------------------------------------===//
// Adjusting to Compressed Capability Precision Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri] in {
def CRRL : Cheri_r<0x8, "croundrepresentablelength", GPR, GPR>;
def CRAM : Cheri_r<0x9, "crepresentablealignmentmask", GPR, GPR>;

def : InstAlias<"crrl $rd, $rs1", (CRRL GPR:$rd, GPR:$rs1)>;
def : InstAlias<"cram $rd, $rs1", (CRAM GPR:$rd, GPR:$rs1)>;
def : InstAlias<"yamask $rd, $rs1", (CRAM GPR:$rd, GPR:$rs1), 0>;
}

//===----------------------------------------------------------------------===//
// Tag-Memory Access Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri], hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def CLoadTags : Cheri_r<0x12, "cloadtags", GPR, V9CRMemZeroOffset>;

//===----------------------------------------------------------------------===//
// Memory-Access with Explicit Address Type Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasZCheriPurecapOrCheri] in {
def LB_DDC  : CheriLoad_r<0b00000, "lb.ddc",  GPR, GPRMemZeroOffset>;
def LH_DDC  : CheriLoad_r<0b00001, "lh.ddc",  GPR, GPRMemZeroOffset>;
def LW_DDC  : CheriLoad_r<0b00010, "lw.ddc",  GPR, GPRMemZeroOffset>;
def LBU_DDC : CheriLoad_r<0b00100, "lbu.ddc", GPR, GPRMemZeroOffset>;
def LHU_DDC : CheriLoad_r<0b00101, "lhu.ddc", GPR, GPRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in {
def LWU_DDC : CheriLoad_r<0b00110, "lwu.ddc", GPR, GPRMemZeroOffset>;
def LD_DDC  : CheriLoad_r<0b00011, "ld.ddc",  GPR, GPRMemZeroOffset>;
}

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, IsRV32] in
def LC_DDC_64  : CheriLoad_r<0b00011, "lc.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in
def LC_DDC_128 : CheriLoad_r<0b10111, "lc.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri] in {
def SB_DDC  : CheriStore_r<0b00000, "sb.ddc", GPR, GPRMemZeroOffset>;
def SH_DDC  : CheriStore_r<0b00001, "sh.ddc", GPR, GPRMemZeroOffset>;
def SW_DDC  : CheriStore_r<0b00010, "sw.ddc", GPR, GPRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in {
def SD_DDC  : CheriStore_r<0b00011, "sd.ddc", GPR, GPRMemZeroOffset>;
}

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, IsRV32] in
def SC_DDC_64  : CheriStore_r<0b00011, "sc.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in
def SC_DDC_128 : CheriStore_r<0b00100, "sc.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri] in {
def LB_CAP  : CheriLoad_r<0b01000, "lb.cap",  GPR, V9CRMemZeroOffset>;
def LH_CAP  : CheriLoad_r<0b01001, "lh.cap",  GPR, V9CRMemZeroOffset>;
def LW_CAP  : CheriLoad_r<0b01010, "lw.cap",  GPR, V9CRMemZeroOffset>;
def LBU_CAP : CheriLoad_r<0b01100, "lbu.cap", GPR, V9CRMemZeroOffset>;
def LHU_CAP : CheriLoad_r<0b01101, "lhu.cap", GPR, V9CRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in {
def LWU_CAP : CheriLoad_r<0b01110, "lwu.cap", GPR, V9CRMemZeroOffset>;
def LD_CAP  : CheriLoad_r<0b01011, "ld.cap",  GPR, V9CRMemZeroOffset>;
}

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, IsRV32] in
def LC_CAP_64  : CheriLoad_r<0b01011, "lc.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in
def LC_CAP_128 : CheriLoad_r<0b11111, "lc.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri] in {
def SB_CAP  : CheriStore_r<0b01000, "sb.cap", GPR, V9CRMemZeroOffset>;
def SH_CAP  : CheriStore_r<0b01001, "sh.cap", GPR, V9CRMemZeroOffset>;
def SW_CAP  : CheriStore_r<0b01010, "sw.cap", GPR, V9CRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in {
def SD_CAP  : CheriStore_r<0b01011, "sd.cap", GPR, V9CRMemZeroOffset>;
}

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, IsRV32] in
def SC_CAP_64  : CheriStore_r<0b01011, "sc.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, IsRV64] in
def SC_CAP_128 : CheriStore_r<0b01100, "sc.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def LR_B_DDC  : CheriLoad_r<0b10000, "lr.b.ddc",  GPR, GPRMemZeroOffset>;
def LR_H_DDC  : CheriLoad_r<0b10001, "lr.h.ddc",  GPR, GPRMemZeroOffset>;
def LR_W_DDC  : CheriLoad_r<0b10010, "lr.w.ddc",  GPR, GPRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def LR_D_DDC  : CheriLoad_r<0b10011, "lr.d.ddc",  GPR, GPRMemZeroOffset>;

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV32] in
def LR_C_DDC_64  : CheriLoad_r<0b10011, "lr.c.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def LR_C_DDC_128 : CheriLoad_r<0b10100, "lr.c.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def LR_B_CAP  : CheriLoad_r<0b11000, "lr.b.cap",  GPR, V9CRMemZeroOffset>;
def LR_H_CAP  : CheriLoad_r<0b11001, "lr.h.cap",  GPR, V9CRMemZeroOffset>;
def LR_W_CAP  : CheriLoad_r<0b11010, "lr.w.cap",  GPR, V9CRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def LR_D_CAP  : CheriLoad_r<0b11011, "lr.d.cap",  GPR, V9CRMemZeroOffset>;

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV32] in
def LR_C_CAP_64  : CheriLoad_r<0b11011, "lr.c.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def LR_C_CAP_128 : CheriLoad_r<0b11100, "lr.c.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def SC_B_DDC  : CheriStoreCond_r<0b10000, "sc.b.ddc",  GPR, GPRMemZeroOffset>;
def SC_H_DDC  : CheriStoreCond_r<0b10001, "sc.h.ddc",  GPR, GPRMemZeroOffset>;
def SC_W_DDC  : CheriStoreCond_r<0b10010, "sc.w.ddc",  GPR, GPRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def SC_D_DDC  : CheriStoreCond_r<0b10011, "sc.d.ddc",  GPR, GPRMemZeroOffset>;

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV32] in
def SC_C_DDC_64  : CheriStoreCond_r<0b10011, "sc.c.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def SC_C_DDC_128 : CheriStoreCond_r<0b10100, "sc.c.ddc", V9CR, GPRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def SC_B_CAP  : CheriStoreCond_r<0b11000, "sc.b.cap",  GPR, V9CRMemZeroOffset>;
def SC_H_CAP  : CheriStoreCond_r<0b11001, "sc.h.cap",  GPR, V9CRMemZeroOffset>;
def SC_W_CAP  : CheriStoreCond_r<0b11010, "sc.w.cap",  GPR, V9CRMemZeroOffset>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def SC_D_CAP  : CheriStoreCond_r<0b11011, "sc.d.cap",  GPR, V9CRMemZeroOffset>;

let DecoderNamespace = "RISCV32Only_",
    Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV32] in
def SC_C_CAP_64  : CheriStoreCond_r<0b11011, "sc.c.cap", V9CR, V9CRMemZeroOffset>;

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in
def SC_C_CAP_128 : CheriStoreCond_r<0b11100, "sc.c.cap", V9CR, V9CRMemZeroOffset>;

//===----------------------------------------------------------------------===//
// Memory-Access Instructions
//===----------------------------------------------------------------------===//

let Predicates = [HasCheri, IsRV32, NotCapMode] in {
let DecoderNamespace = "RISCV32Only_",
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def LC_64  : RVInstI<0x3, OPC_LOAD, (outs V9CR:$rd),
                     (ins GPR:$rs1, simm12:$imm12),
                     "lc", "$rd, ${imm12}(${rs1})">;

let DecoderNamespace = "RISCV32Only_",
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def SC_64  : RVInstS<0x3, OPC_STORE, (outs),
                     (ins V9CR:$rs2, GPR:$rs1, simm12:$imm12),
                     "sc", "$rs2, ${imm12}(${rs1})">;

let EmitPriority = 0 in {
def : InstAlias<"lc $rd, (${rs1})",
                (LC_64  V9CR:$rd, GPR:$rs1, 0)>;
def : InstAlias<"sc $rs2, (${rs1})",
                (SC_64  V9CR:$rs2, GPR:$rs1, 0)>;
def : InstAlias<"ly $rd, ${imm12}(${rs1})",
                (LC_64  YGPR:$rd, GPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"sy $rs2, ${imm12}(${rs1})",
                (SC_64  YGPR:$rs2, GPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"ly $rd, (${rs1})",
                (LC_64  YGPR:$rd, GPR:$rs1, 0), 0>;
def : InstAlias<"sy $rs2, (${rs1})",
                (SC_64  YGPR:$rs2, GPR:$rs1, 0), 0>;
}
}

let Predicates = [HasCheri, IsRV64, NotCapMode] in {
let hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def LC_128  : RVInstI<0x2, OPC_MISC_MEM, (outs V9CR:$rd),
                      (ins GPR:$rs1, simm12:$imm12),
                      "lc", "$rd, ${imm12}(${rs1})">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def SC_128  : RVInstS<0x4, OPC_STORE, (outs),
                      (ins V9CR:$rs2, GPR:$rs1, simm12:$imm12),
                      "sc", "$rs2, ${imm12}(${rs1})">;

let EmitPriority = 0 in {
def : InstAlias<"lc $rd, (${rs1})",
                (LC_128  V9CR:$rd, GPR:$rs1, 0)>;
def : InstAlias<"sc $rs2, (${rs1})",
                (SC_128  V9CR:$rs2, GPR:$rs1, 0)>;
def : InstAlias<"ly $rd, ${imm12}(${rs1})",
                (LC_128  YGPR:$rd, GPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"sy $rs2, ${imm12}(${rs1})",
                (SC_128  YGPR:$rs2, GPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"ly $rd, (${rs1})",
                (LC_128  YGPR:$rd, GPR:$rs1, 0), 0>;
def : InstAlias<"sy $rs2, (${rs1})",
                (SC_128  YGPR:$rs2, GPR:$rs1, 0), 0>;
}
}

// Atomic instruction aliases multiclass for integer mode.
multiclass AtomicInstAliases<string asm, string opnds, string inst, string sfx,
                             dag args> {
  def : InstAlias<asm#opnds, !con((!cast<Instruction>(inst#sfx)), args), 0>;
  def : InstAlias<asm#".aq"#opnds,
                  !con((!cast<Instruction>(inst#"_AQ"#sfx)), args), 0>;
  def : InstAlias<asm#".rl"#opnds,
                  !con((!cast<Instruction>(inst#"_RL"#sfx)), args), 0>;
  def : InstAlias<asm#".aqrl"#opnds,
                  !con((!cast<Instruction>(inst#"_AQ_RL"#sfx)), args), 0>;
}

let Predicates = [HasCheri, HasStdExtA, IsRV32, NotCapMode] in {
let DecoderNamespace = "RISCV32Only_" in {
defm LR_C       : LR_C_r_aq_rl<"64", 0b011, "lr.c">;
defm SC_C       : AMO_C_rr_aq_rl<"64", 0b00011, 0b011, "sc.c", GPR>;
defm AMOSWAP_C  : AMO_C_rr_aq_rl<"64", 0b00001, 0b011, "amoswap.c", V9CR>;
}

defm : AtomicInstAliases<"lr.y", " $rd, $rs1", "LR_C", "_64",
                         (? YGPR:$rd, GPRMemZeroOffset:$rs1)>;
defm : AtomicInstAliases<"sc.y", " $rd, $rs2, $rs1", "SC_C", "_64",
                         (? GPR:$rd, GPRMemZeroOffset:$rs1, YGPR:$rs2)>;
defm : AtomicInstAliases<"amoswap.y", " $rd, $rs2, $rs1", "AMOSWAP_C", "_64",
                         (? YGPR:$rd, GPRMemZeroOffset:$rs1, YGPR:$rs2)>;
}

let Predicates = [HasCheri, HasStdExtA, IsRV64, NotCapMode] in {
defm LR_C       : LR_C_r_aq_rl<"128", 0b100, "lr.c">;
defm SC_C       : AMO_C_rr_aq_rl<"128", 0b00011, 0b100, "sc.c", GPR>;
defm AMOSWAP_C  : AMO_C_rr_aq_rl<"128", 0b00001, 0b100, "amoswap.c", V9CR>;

defm : AtomicInstAliases<"lr.y", " $rd, $rs1", "LR_C", "_128",
                         (? YGPR:$rd, GPRMemZeroOffset:$rs1)>;
defm : AtomicInstAliases<"sc.y", " $rd, $rs2, $rs1", "SC_C", "_128",
                         (? GPR:$rd, GPRMemZeroOffset:$rs1, YGPR:$rs2)>;
defm : AtomicInstAliases<"amoswap.y", " $rd, $rs2, $rs1", "AMOSWAP_C", "_128",
                         (? YGPR:$rd, GPRMemZeroOffset:$rs1, YGPR:$rs2)>;
}

//===----------------------------------------------------------------------===//
// Capability Mode Instructions
//===----------------------------------------------------------------------===//


/// 'I' (Integer) base

let DecoderNamespace = "CapModeOnly_" in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in {
let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
def AUIPCC : RVInstU<OPC_AUIPC, (outs V9CR:$rd), (ins uimm20_auipc:$imm20),
                     "auipc", "$rd, $imm20">;

let isCall = 1 in
def CJAL : RVInstJ<OPC_JAL, (outs V9CR:$rd), (ins simm21_lsb0_jal:$imm20),
                   "jal", "$rd, $imm20">;

let isCall = 1 in
def CJALR : RVInstI<0b000, OPC_JALR, (outs V9CR:$rd),
                    (ins V9CR:$rs1, simm12:$imm12),
                    "jalr", "$rd, ${imm12}(${rs1})">;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode]
} // hasSideEffects = 0, mayLoad = 0, mayStore = 0
} // DecoderNameSpace = "CapModeOnly_"

multiclass CPrefixedInstAlias<string Asm, dag Result, int Emit = 0> {
  def : InstAlias<"c" # Asm, Result, 0>;
  def : InstAlias<Asm, Result, Emit>;
}
def : MnemonicAlias<"auipcc", "auipc">;

multiclass CoercingLoadAlias<string opcodestr, Instruction inst, RegisterClass rdClass> {
  def : InstAlias<opcodestr # " $rd, (${rs1})", (inst rdClass:$rd, RVYCompatGPCRMem:$rs1, 0), 0>;
  def : InstAlias<opcodestr # " $rd, ${offset}(${rs1})", (inst rdClass:$rd, RVYCompatGPCRMem:$rs1, simm12:$offset), 0>;
  def : InstAlias<"c" # opcodestr # " $rd, (${rs1})", (inst rdClass:$rd, GPCRMem:$rs1, 0), 0>;
  def : InstAlias<"c" # opcodestr # " $rd, ${offset}(${rs1})", (inst rdClass:$rd, GPCRMem:$rs1, simm12:$offset), 0>;
}

multiclass CoercingStoreAlias<string opcodestr, Instruction inst, RegisterClass rs2Class> {
  def : InstAlias<opcodestr # " $rs2, (${rs1})", (inst rs2Class:$rs2, RVYCompatGPCRMem:$rs1, 0), 0>;
  def : InstAlias<opcodestr # " $rs2, ${offset}(${rs1})", (inst rs2Class:$rs2, RVYCompatGPCRMem:$rs1, simm12:$offset), 0>;
  def : InstAlias<"c" # opcodestr # " $rs2, (${rs1})", (inst rs2Class:$rs2, GPCRMem:$rs1, 0), 0>;
  def : InstAlias<"c" # opcodestr # " $rs2, ${offset}(${rs1})", (inst rs2Class:$rs2, GPCRMem:$rs1, simm12:$offset), 0>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
// "cj" is the non-canonical form, but we provide this for completeness.
def : InstAlias<"j $offset",    (CJAL X0_Y, simm21_lsb0_jal:$offset), 1>;
def : InstAlias<"cj $offset",   (CJAL X0_Y, simm21_lsb0_jal:$offset), 0>;
def : InstAlias<"jal $offset",  (CJAL X1_Y, simm21_lsb0_jal:$offset), 1>;
def : InstAlias<"cjal $offset", (CJAL X1_Y, simm21_lsb0_jal:$offset), 0>;
def : InstAlias<"jal $rd, $offset",
                (CJAL RVYCompatGPCR:$rd, simm21_lsb0_jal:$offset), 0>;
def : InstAlias<"cjal $rd, $offset",
                (CJAL V9CR:$rd, simm21_lsb0_jal:$offset), 0>;
def : InstAlias<"jalr $rd, ${offset}(${rs1})",
                (CJALR RVYCompatGPCR:$rd, RVYCompatGPCR:$rs1, simm12:$offset), 0>;
def : InstAlias<"cjalr $rd, ${offset}(${rs1})",
                (CJALR V9CR:$rd, V9CR:$rs1, simm12:$offset), 0>;

// Non-zero offset aliases of "cjalr" are the lowest weight, followed by the
// two-register form, then the one-register forms and finally "cret".
def : InstAlias<"jr $rs",                 (CJALR                X0_Y,  RVYCompatGPCR:$rs, 0), 3>;
def : InstAlias<"cjr $rs",                (CJALR                X0_Y,           V9CR:$rs, 0), 0>;
def : InstAlias<"jr ${offset}(${rs})",    (CJALR                X0_Y,  RVYCompatGPCR:$rs, simm12:$offset), 1>;
def : InstAlias<"cjr ${offset}(${rs})",   (CJALR                X0_Y,           V9CR:$rs, simm12:$offset), 0>;
def : InstAlias<"jalr $rs",               (CJALR                X1_Y,  RVYCompatGPCR:$rs, 0), 3>;
def : InstAlias<"cjalr $rs",              (CJALR                X1_Y,           V9CR:$rs, 0), 0>;
def : InstAlias<"jalr ${offset}(${rs})",  (CJALR                X1_Y,  RVYCompatGPCR:$rs, simm12:$offset), 1>;
def : InstAlias<"cjalr ${offset}(${rs})", (CJALR                X1_Y,           V9CR:$rs, simm12:$offset), 0>;
def : InstAlias<"jalr $rd, $rs",          (CJALR RVYCompatGPCR:$rd,  RVYCompatGPCR:$rs, 0), 2>;
def : InstAlias<"cjalr $rd, $rs",         (CJALR          V9CR:$rd,           V9CR:$rs, 0), 0>;
def : InstAlias<"ret",                    (CJALR                X0_Y,                 X1_Y, 0), 4>;
def : InstAlias<"cret",                   (CJALR                X0_Y,                 X1_Y, 0), 0>;

// Non-canonical forms for jump targets also accepted by the assembler.
def : InstAlias<"jr $rs, $offset",         (CJALR                X0_Y, RVYCompatGPCR:$rs, simm12:$offset), 0>;
def : InstAlias<"cjr $rs, $offset",        (CJALR                X0_Y,          V9CR:$rs, simm12:$offset), 0>;
def : InstAlias<"jalr $rs, $offset",       (CJALR                X1_Y, RVYCompatGPCR:$rs, simm12:$offset), 0>;
def : InstAlias<"cjalr $rs, $offset",      (CJALR                X1_Y,          V9CR:$rs, simm12:$offset), 0>;
def : InstAlias<"jalr $rd, $rs, $offset",  (CJALR RVYCompatGPCR:$rd, RVYCompatGPCR:$rs, simm12:$offset), 0>;
def : InstAlias<"cjalr $rd, $rs, $offset", (CJALR          V9CR:$rd,          V9CR:$rs, simm12:$offset), 0>;
// Allow both `auipc c1`/`auipc x1` for RVY 0.9.3 and RVY 1.0 compatibility.
def : InstAlias<"auipc $rd, $imm20", (AUIPCC RVYCompatGPCR:$rd, uimm20_auipc:$imm20), 0>;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode]


let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
defm CLB  : CheriLoad_ri<0b000, "lb">;
defm CLH  : CheriLoad_ri<0b001, "lh">;
defm CLW  : CheriLoad_ri<0b010, "lw">;
defm CLBU : CheriLoad_ri<0b100, "lbu">;
defm CLHU : CheriLoad_ri<0b101, "lhu">;

defm CSB : CheriStore_ri<0b000, "sb">;
defm CSH : CheriStore_ri<0b001, "sh">;
defm CSW : CheriStore_ri<0b010, "sw">;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode] in {
defm CLWU   : CheriLoad_ri<0b110, "lwu">;
defm CLD    : CheriLoad_ri<0b011, "ld">;
defm CSD    : CheriStore_ri<0b011, "sd">;
} // Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode]

let Predicates = [HasCheri, IsRV32, IsCapMode] in {
let DecoderNamespace = "RISCV32CapModeOnly_",
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def CLC_64  : RVInstI<0x3, OPC_LOAD, (outs V9CR:$rd),
                      (ins GPCRMem:$rs1, simm12:$imm12),
                      "lc", "$rd, ${imm12}(${rs1})">;
def : InstAlias<"clc $rd, ${imm12}(${rs1})",
                (CLC_64  V9CR:$rd, GPCRMem:$rs1, simm12:$imm12), 0>;

let DecoderNamespace = "RISCV32CapModeOnly_",
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def CSC_64  : RVInstS<0x3, OPC_STORE, (outs),
                      (ins V9CR:$rs2, GPCRMem:$rs1, simm12:$imm12),
                      "sc", "$rs2, ${imm12}(${rs1})">;
def : InstAlias<"csc $rs2, ${imm12}(${rs1})",
                (CSC_64  V9CR:$rs2, GPCRMem:$rs1, simm12:$imm12), 0>;

defm : CPrefixedInstAlias<"lc $rd, (${rs1})", (CLC_64 V9CR:$rd, GPCRMem:$rs1, 0)>;
defm : CPrefixedInstAlias<"sc $rs2, (${rs1})", (CSC_64 V9CR:$rs2, GPCRMem:$rs1, 0)>;
def : InstAlias<"ly $rd, ${imm12}(${rs1})",
                (CLC_64  YGPR:$rd, YGPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"sy $rs2, ${imm12}(${rs1})",
                (CSC_64  YGPR:$rs2, YGPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"ly $rd, (${rs1})",
                (CLC_64  YGPR:$rd, YGPR:$rs1, 0), 0>;
def : InstAlias<"sy $rs2, (${rs1})",
                (CSC_64  YGPR:$rs2, YGPR:$rs1, 0), 0>;
}

let Predicates = [HasCheri, IsRV64, IsCapMode] in {
let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def CLC_128  : RVInstI<0x2, OPC_MISC_MEM, (outs V9CR:$rd),
                       (ins GPCRMem:$rs1, simm12:$imm12),
                       "lc", "$rd, ${imm12}(${rs1})">;
def : InstAlias<"clc $rd, ${imm12}(${rs1})",
                (CLC_128  V9CR:$rd, GPCRMem:$rs1, simm12:$imm12), 0>;

let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def CSC_128  : RVInstS<0x4, OPC_STORE, (outs),
                       (ins V9CR:$rs2, GPCRMem:$rs1, simm12:$imm12),
                       "sc", "$rs2, ${imm12}(${rs1})">;
def : InstAlias<"csc $rs2, ${imm12}(${rs1})",
                (CSC_128  V9CR:$rs2, GPCRMem:$rs1, simm12:$imm12), 0>;

defm : CPrefixedInstAlias<"lc $rd, (${rs1})", (CLC_128 V9CR:$rd, GPCRMem:$rs1, 0)>;
defm : CPrefixedInstAlias<"sc $rs2, (${rs1})", (CSC_128 V9CR:$rs2, GPCRMem:$rs1, 0)>;
def : InstAlias<"ly $rd, ${imm12}(${rs1})",
                (CLC_128  YGPR:$rd, YGPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"sy $rs2, ${imm12}(${rs1})",
                (CSC_128  YGPR:$rs2, YGPR:$rs1, simm12:$imm12), 0>;
def : InstAlias<"ly $rd, (${rs1})",
                (CLC_128  YGPR:$rd, YGPR:$rs1, 0), 0>;
def : InstAlias<"sy $rs2, (${rs1})",
                (CSC_128  YGPR:$rs2, YGPR:$rs1, 0), 0>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
defm : CoercingLoadAlias<"lb", CLB, GPR>;
defm : CoercingLoadAlias<"lh", CLH, GPR>;
defm : CoercingLoadAlias<"lw", CLW, GPR>;
defm : CoercingLoadAlias<"lbu", CLBU, GPR>;
defm : CoercingLoadAlias<"lhu", CLHU, GPR>;

defm : CoercingStoreAlias<"sb", CSB, GPR>;
defm : CoercingStoreAlias<"sh", CSH, GPR>;
defm : CoercingStoreAlias<"sw", CSW, GPR>;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode] in {
defm : CoercingLoadAlias<"lwu", CLWU, GPR>;
defm : CoercingLoadAlias<"ld", CLD, GPR>;
defm : CoercingStoreAlias<"sd", CSD, GPR>;
} // Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode]

/// 'A' (Atomic Instructions) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsCapMode] in {
defm CLR_B       : CLR_r_aq_rl<0b000, "lr.b">,
                       Sched<[WriteCHERIAtomicLDB, ReadCHERIAtomicLDB]>;
defm CSC_B       : CAMO_rr_aq_rl<0b00011, 0b000, "sc.b">,
                       Sched<[WriteCHERIAtomicSTB, ReadCHERIAtomicSTB]>;

defm CLR_H       : CLR_r_aq_rl<0b001, "lr.h">,
                       Sched<[WriteCHERIAtomicLDH, ReadCHERIAtomicLDH]>;
defm CSC_H       : CAMO_rr_aq_rl<0b00011, 0b001, "sc.h">,
                       Sched<[WriteCHERIAtomicSTH, ReadCHERIAtomicSTH]>;

defm CLR_W       : CLR_r_aq_rl<0b010, "lr.w">;
defm CSC_W       : CAMO_rr_aq_rl<0b00011, 0b010, "sc.w">;
defm CAMOSWAP_W  : CAMO_rr_aq_rl<0b00001, 0b010, "amoswap.w">;
defm CAMOADD_W   : CAMO_rr_aq_rl<0b00000, 0b010, "amoadd.w">;
defm CAMOXOR_W   : CAMO_rr_aq_rl<0b00100, 0b010, "amoxor.w">;
defm CAMOAND_W   : CAMO_rr_aq_rl<0b01100, 0b010, "amoand.w">;
defm CAMOOR_W    : CAMO_rr_aq_rl<0b01000, 0b010, "amoor.w">;
defm CAMOMIN_W   : CAMO_rr_aq_rl<0b10000, 0b010, "amomin.w">;
defm CAMOMAX_W   : CAMO_rr_aq_rl<0b10100, 0b010, "amomax.w">;
defm CAMOMINU_W  : CAMO_rr_aq_rl<0b11000, 0b010, "amominu.w">;
defm CAMOMAXU_W  : CAMO_rr_aq_rl<0b11100, 0b010, "amomaxu.w">;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64, IsCapMode] in {
defm CLR_D       : CLR_r_aq_rl<0b011, "lr.d">;
defm CSC_D       : CAMO_rr_aq_rl<0b00011, 0b011, "sc.d">;
defm CAMOSWAP_D  : CAMO_rr_aq_rl<0b00001, 0b011, "amoswap.d">;
defm CAMOADD_D   : CAMO_rr_aq_rl<0b00000, 0b011, "amoadd.d">;
defm CAMOXOR_D   : CAMO_rr_aq_rl<0b00100, 0b011, "amoxor.d">;
defm CAMOAND_D   : CAMO_rr_aq_rl<0b01100, 0b011, "amoand.d">;
defm CAMOOR_D    : CAMO_rr_aq_rl<0b01000, 0b011, "amoor.d">;
defm CAMOMIN_D   : CAMO_rr_aq_rl<0b10000, 0b011, "amomin.d">;
defm CAMOMAX_D   : CAMO_rr_aq_rl<0b10100, 0b011, "amomax.d">;
defm CAMOMINU_D  : CAMO_rr_aq_rl<0b11000, 0b011, "amominu.d">;
defm CAMOMAXU_D  : CAMO_rr_aq_rl<0b11100, 0b011, "amomaxu.d">;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64, IsCapMode]

let Predicates = [HasCheri, HasStdExtA, IsRV32, IsCapMode] in {
defm CLR_C       : CLR_C_r_aq_rl<"64", 0b011, "lr.c", "RISCV32CapModeOnly_">;
defm CSC_C       : CAMO_C_rr_aq_rl<"64", 0b00011, 0b011, "sc.c", GPR,
                                   "RISCV32CapModeOnly_">;
defm CAMOSWAP_C  : CAMO_C_rr_aq_rl<"64", 0b00001, 0b011, "amoswap.c", V9CR,
                                   "RISCV32CapModeOnly_">;
defm : AtomicInstAliases<"lr.y", " $rd, $rs1", "CLR_C", "_64",
                         (? YGPR:$rd, YGPRMemZeroOffset:$rs1)>;
defm : AtomicInstAliases<"sc.y", " $rd, $rs2, $rs1", "CSC_C", "_64",
                         (? GPR:$rd, YGPRMemZeroOffset:$rs1, YGPR:$rs2)>;
defm : AtomicInstAliases<"amoswap.y", " $rd, $rs2, $rs1", "CAMOSWAP_C", "_64",
                         (? YGPR:$rd, YGPRMemZeroOffset:$rs1, YGPR:$rs2)>;
}

let Predicates = [HasCheri, HasStdExtA, IsRV64, IsCapMode] in {
defm CLR_C       : CLR_C_r_aq_rl<"128", 0b100, "lr.c">;
defm CSC_C       : CAMO_C_rr_aq_rl<"128", 0b00011, 0b100, "sc.c", GPR>;
defm CAMOSWAP_C  : CAMO_C_rr_aq_rl<"128", 0b00001, 0b100, "amoswap.c", V9CR>;
defm : AtomicInstAliases<"lr.y", " $rd, $rs1", "CLR_C", "_128",
                         (? YGPR:$rd, YGPRMemZeroOffset:$rs1)>;
defm : AtomicInstAliases<"sc.y", " $rd, $rs2, $rs1", "CSC_C", "_128",
                         (? GPR:$rd, YGPRMemZeroOffset:$rs1, YGPR:$rs2)>;
defm : AtomicInstAliases<"amoswap.y", " $rd, $rs2, $rs1", "CAMOSWAP_C", "_128",
                         (? YGPR:$rd, YGPRMemZeroOffset:$rs1, YGPR:$rs2)>;
}

/// Zacas (Atomic Compare-and-Swap)

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsCapMode] in {
defm CAMOCAS_W : CAMO_cas_aq_rl<0b00101, 0b010, "amocas.w", GPR>;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsRV32, IsCapMode] in {
defm CAMOCAS_D_RV32 : CAMO_cas_aq_rl<0b00101, 0b011, "amocas.d", GPRPairRV32,
                                     "RISCV32CapModeOnly_">;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsRV32, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsRV64, IsCapMode] in {
defm CAMOCAS_D_RV64 : CAMO_cas_aq_rl<0b00101, 0b011, "amocas.d", GPR>;
defm CAMOCAS_Q : CAMO_cas_aq_rl<0b00101, 0b100, "amocas.q", GPRPairRV64>;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtZacas, IsRV64, IsCapMode]

/// Zabha (Byte and Halfword Atomic Memory Operations)

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtZabha, IsCapMode] in {
defm CAMOSWAP_B  : CAMO_rr_aq_rl<0b00001, 0b000, "amoswap.b">;
defm CAMOADD_B   : CAMO_rr_aq_rl<0b00000, 0b000, "amoadd.b">;
defm CAMOXOR_B   : CAMO_rr_aq_rl<0b00100, 0b000, "amoxor.b">;
defm CAMOAND_B   : CAMO_rr_aq_rl<0b01100, 0b000, "amoand.b">;
defm CAMOOR_B    : CAMO_rr_aq_rl<0b01000, 0b000, "amoor.b">;
defm CAMOMIN_B   : CAMO_rr_aq_rl<0b10000, 0b000, "amomin.b">;
defm CAMOMAX_B   : CAMO_rr_aq_rl<0b10100, 0b000, "amomax.b">;
defm CAMOMINU_B  : CAMO_rr_aq_rl<0b11000, 0b000, "amominu.b">;
defm CAMOMAXU_B  : CAMO_rr_aq_rl<0b11100, 0b000, "amomaxu.b">;

defm CAMOSWAP_H  : CAMO_rr_aq_rl<0b00001, 0b001, "amoswap.h">;
defm CAMOADD_H   : CAMO_rr_aq_rl<0b00000, 0b001, "amoadd.h">;
defm CAMOXOR_H   : CAMO_rr_aq_rl<0b00100, 0b001, "amoxor.h">;
defm CAMOAND_H   : CAMO_rr_aq_rl<0b01100, 0b001, "amoand.h">;
defm CAMOOR_H    : CAMO_rr_aq_rl<0b01000, 0b001, "amoor.h">;
defm CAMOMIN_H   : CAMO_rr_aq_rl<0b10000, 0b001, "amomin.h">;
defm CAMOMAX_H   : CAMO_rr_aq_rl<0b10100, 0b001, "amomax.h">;
defm CAMOMINU_H  : CAMO_rr_aq_rl<0b11000, 0b001, "amominu.h">;
defm CAMOMAXU_H  : CAMO_rr_aq_rl<0b11100, 0b001, "amomaxu.h">;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtZabha, IsCapMode]

// If Zacas extension is also implemented, Zabha further provides AMOCAS.[B|H].
let Predicates = [HasZCheriPurecapOrCheri, HasStdExtZabha, HasStdExtZacas,
                  IsCapMode] in {
defm CAMOCAS_B : CAMO_cas_aq_rl<0b00101, 0b000, "amocas.b", GPR>;
defm CAMOCAS_H : CAMO_cas_aq_rl<0b00101, 0b001, "amocas.h", GPR>;
}

/// 'F' (Single-Precision Floating-Point) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtF, IsCapMode] in {
let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def CFLW : RVInstI<0b010, OPC_LOAD_FP, (outs FPR32:$rd),
                   (ins GPCRMem:$rs1, simm12:$imm12),
                   "flw", "$rd, ${imm12}(${rs1})">;

let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def CFSW : RVInstS<0b010, OPC_STORE_FP, (outs),
                   (ins FPR32:$rs2, GPCRMem:$rs1, simm12:$imm12),
                   "fsw", "$rs2, ${imm12}(${rs1})">;

defm : CoercingLoadAlias<"flw", CFLW, FPR32>;
defm : CoercingStoreAlias<"fsw", CFSW, FPR32>;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtF, IsCapMode]

/// 'D' (Single-Precision Floating-Point) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsCapMode] in {
let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 1, mayStore = 0 in
def CFLD : RVInstI<0b011, OPC_LOAD_FP, (outs FPR64:$rd),
                   (ins RVYCompatGPCRMem:$rs1, simm12:$imm12),
                   "fld", "$rd, ${imm12}(${rs1})">;

let DecoderNamespace = "CapModeOnly_",
    hasSideEffects = 0, mayLoad = 0, mayStore = 1 in
def CFSD : RVInstS<0b011, OPC_STORE_FP, (outs),
                   (ins FPR64:$rs2, RVYCompatGPCRMem:$rs1, simm12:$imm12),
                   "fsd", "$rs2, ${imm12}(${rs1})">;

defm : CoercingLoadAlias<"fld", CFLD, FPR64>;
defm : CoercingStoreAlias<"fsd", CFSD, FPR64>;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsCapMode]

/// 'C' (Compressed Instructions) extension

let DecoderNamespace = "CapModeOnly_" in {
let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {

let hasSideEffects = 0, mayLoad = 0, mayStore = 0, Uses = [X2_Y] in
def C_CIncOffsetImm4CSPN : RVInst16CIW<0b000, 0b00, (outs V9CRC:$rd),
                                       (ins V9CSP:$rs1, uimm10_lsb00nonzero:$imm),
                                       "c.cincoffset4cspn", "$rd, $rs1, $imm"> {
  bits<5> rs1;
  let Inst{12-11} = imm{5-4};
  let Inst{10-7} = imm{9-6};
  let Inst{6} = imm{2};
  let Inst{5} = imm{3};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in
def C_CFLD : CCheriLoad_ri<0b001, "c.fld", FPR64C, uimm8_lsb000> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CLC_128 : CCheriLoad_ri<0b001, "c.lc", V9CRC, uimm9_lsb0000, GPCRCMem> {
  bits<9> imm;
  let Inst{12-11} = imm{5-4};
  let Inst{10} = imm{8};
  let Inst{6-5} = imm{7-6};
}

def C_CLW : CCheriLoad_ri<0b010, "c.lw", GPRC, uimm7_lsb00> {
  bits<7> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6} = imm{2};
  let Inst{5} = imm{6};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in
def C_CLC_64 : CCheriLoad_ri<0b011, "c.lc", V9CRC, uimm8_lsb000, GPCRCMem> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CLD : CCheriLoad_ri<0b011, "c.ld", GPRC, uimm8_lsb000> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in
def C_CFSD : CCheriStore_rri<0b101, "c.fsd", FPR64C, uimm8_lsb000> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CSC_128 : CCheriStore_rri<0b101, "c.sc", V9CRC, uimm9_lsb0000, GPCRCMem> {
  bits<9> imm;
  let Inst{12-11} = imm{5-4};
  let Inst{10} = imm{8};
  let Inst{6-5} = imm{7-6};
}

def C_CSW : CCheriStore_rri<0b110, "c.sw", GPRC, uimm7_lsb00> {
  bits<7> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6} = imm{2};
  let Inst{5} = imm{6};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]  in
def C_CSC_64 : CCheriStore_rri<0b111, "c.sc", V9CRC, uimm8_lsb000, GPCRCMem> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CSD : CCheriStore_rri<0b111, "c.sd", GPRC, uimm8_lsb000> {
  bits<8> imm;
  let Inst{12-10} = imm{5-3};
  let Inst{6-5} = imm{7-6};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCall = 1,
    DecoderNamespace = "RISCV32CapModeOnly_", Defs = [X1_Y],
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]  in
def C_CJAL : RVInst16CJ<0b001, 0b01, (outs), (ins simm12_lsb0:$offset),
                        "c.jal", "$offset">;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def C_CIncOffsetImm16CSP : RVInst16CI<0b011, 0b01, (outs V9CSP:$rd_wb),
                                      (ins V9CSP:$rd, simm10_lsb0000nonzero:$imm),
                                      "c.cincoffset16csp", "$rd, $imm"> {
  let Constraints = "$rd = $rd_wb";
  let Inst{12} = imm{9};
  let Inst{11-7} = 2;
  let Inst{6} = imm{4};
  let Inst{5} = imm{6};
  let Inst{4-3} = imm{8-7};
  let Inst{2} = imm{5};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in
def C_CFLDCSP : CCheriStackLoad<0b001, "c.fldsp", FPR64, uimm9_lsb000> {
  let Inst{6-5} = imm{4-3};
  let Inst{4-2} = imm{8-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CLCCSP_128 : CCheriStackLoad<0b001, "c.lcsp", V9CRNoC0, uimm10_lsb0000, CSPMem> {
  let Inst{6} = imm{4};
  let Inst{5-2} = imm{9-6};
}

def C_CLWCSP : CCheriStackLoad<0b010, "c.lwsp", GPRNoX0, uimm8_lsb00> {
  let Inst{6-4} = imm{4-2};
  let Inst{3-2} = imm{7-6};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in
def C_CLCCSP_64 : CCheriStackLoad<0b011, "c.lcsp", V9CRNoC0, uimm9_lsb000, CSPMem> {
  let Inst{6-5} = imm{4-3};
  let Inst{4-2} = imm{8-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CLDCSP : CCheriStackLoad<0b011, "c.ldsp", GPRNoX0, uimm9_lsb000> {
  let Inst{6-5} = imm{4-3};
  let Inst{4-2} = imm{8-6};
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0 in
def C_CJR : RVInst16CR<0b1000, 0b10, (outs), (ins V9CRNoC0:$rs1),
                       "c.jr", "$rs1"> {
  let isBranch = 1;
  let isBarrier = 1;
  let isTerminator = 1;
  let isIndirectBranch = 1;
  let rs2 = 0;
}

let hasSideEffects = 0, mayLoad = 0, mayStore = 0,
    isCall = 1, Defs = [X1_Y], rs2 = 0 in
def C_CJALR : RVInst16CR<0b1001, 0b10, (outs), (ins V9CRNoC0:$rs1),
                         "c.jalr", "$rs1">;

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in
def C_CFSDCSP : CCheriStackStore<0b101, "c.fsdsp", FPR64, uimm9_lsb000> {
  let Inst{12-10} = imm{5-3};
  let Inst{9-7}   = imm{8-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CSCCSP_128 : CCheriStackStore<0b101, "c.scsp", V9CR, uimm10_lsb0000, CSPMem> {
  let Inst{12-11} = imm{5-4};
  let Inst{10-7}  = imm{9-6};
}

def C_CSWCSP : CCheriStackStore<0b110, "c.swsp", GPR, uimm8_lsb00> {
  let Inst{12-9} = imm{5-2};
  let Inst{8-7}  = imm{7-6};
}

let DecoderNamespace = "RISCV32CapModeOnly_",
    Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in
def C_CSCCSP_64 : CCheriStackStore<0b111, "c.scsp", V9CR, uimm9_lsb000, CSPMem> {
  let Inst{12-10} = imm{5-3};
  let Inst{9-7}   = imm{8-6};
}

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in
def C_CSDCSP : CCheriStackStore<0b111, "c.sdsp", GPR, uimm9_lsb000> {
  let Inst{12-10} = imm{5-3};
  let Inst{9-7}   = imm{8-6};
}

} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]
} // DecoderNamespace = "CapModeOnly_"

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : InstAlias<"c.cincoffsetimm4cspn $rd, $rs1, $imm",
                (C_CIncOffsetImm4CSPN V9CRC:$rd, V9CSP:$rs1, uimm10_lsb00nonzero:$imm), 0>;
def : InstAlias<"c.cincoffsetimm16csp $rd, $imm",
                (C_CIncOffsetImm16CSP V9CSP:$rd, simm10_lsb0000nonzero:$imm), 0>;
def : InstAlias<"c.addi4spn $rd, $rs1, $imm", (C_CIncOffsetImm4CSPN V9CRC:$rd, V9CSP:$rs1, uimm10_lsb00nonzero:$imm)>;
def : InstAlias<"c.addi16sp $rd, $imm", (C_CIncOffsetImm16CSP V9CSP:$rd, simm10_lsb0000nonzero:$imm), 0>;
def : InstAlias<"c.clw $rd, ${imm}(${rs1})", (C_CLW GPRC:$rd, V9CRC:$rs1, uimm7_lsb00:$imm), 0>;
def : InstAlias<"c.csw $rs2, ${imm}(${rs1})", (C_CSW GPRC:$rs2, V9CRC:$rs1, uimm7_lsb00:$imm), 0>;
def : InstAlias<"c.clwcsp $rd, ${imm}(${rs1})", (C_CLWCSP GPRNoX0:$rd, V9CSP:$rs1, uimm8_lsb00:$imm), 0>;
def : InstAlias<"c.cswcsp $rs2, ${imm}(${rs1})", (C_CSWCSP GPR:$rs2, V9CSP:$rs1, uimm8_lsb00:$imm), 0>;
def : InstAlias<"c.cjalr $rs1", (C_CJALR V9CRNoC0:$rs1), 0>;
def : InstAlias<"c.jalr $rs1", (C_CJALR RVYCompatGPCRNoC0:$rs1)>;
def : InstAlias<"c.cjr $rs1", (C_CJR V9CRNoC0:$rs1), 0>;
def : InstAlias<"c.jr $rs1", (C_CJR RVYCompatGPCRNoC0:$rs1)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]
let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : InstAlias<"c.cld $rd, ${imm}(${rs1})", (C_CLD GPRC:$rd, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.csd $rs2, ${imm}(${rs1})", (C_CSD GPRC:$rs2, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.cldcsp $rd, ${imm}(${rs1})", (C_CLDCSP GPRNoX0:$rd, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.csdcsp $rs2, ${imm}(${rs1})", (C_CSDCSP GPR:$rs2, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.csc $rs2, ${imm}(${rs1})", (C_CSC_128 V9CRC:$rs2, V9CRC:$rs1, uimm9_lsb0000:$imm), 0>;
def : InstAlias<"c.sy $rs2, ${imm}(${rs1})", (C_CSC_128 YGPRC:$rs2, YGPRC:$rs1, uimm9_lsb0000:$imm), 0>;
def : InstAlias<"c.csccsp $rs2, ${imm}(${rs1})", (C_CSCCSP_128 V9CR:$rs2, V9CSP:$rs1, uimm10_lsb0000:$imm), 0>;
def : InstAlias<"c.sysp $rs2, ${imm}(${rs1})", (C_CSCCSP_128 YGPRC:$rs2, YSP:$rs1, uimm10_lsb0000:$imm), 0>;
def : InstAlias<"c.clc $rd, ${imm}(${rs1})", (C_CLC_128 V9CRC:$rd, V9CRC:$rs1, uimm9_lsb0000:$imm), 0>;
def : InstAlias<"c.ly $rd, ${imm}(${rs1})", (C_CLC_128 YGPRC:$rd, YGPRC:$rs1, uimm9_lsb0000:$imm), 0>;
def : InstAlias<"c.clccsp $rd, ${imm}(${rs1})", (C_CLCCSP_128 V9CRNoC0:$rd, V9CSP:$rs1, uimm10_lsb0000:$imm), 0>;
def : InstAlias<"c.lysp $rd, ${imm}(${rs1})", (C_CLCCSP_128 YGPRNoX0:$rd, YSP:$rs1, uimm10_lsb0000:$imm), 0>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]
let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : InstAlias<"c.csc $rs2, ${imm}(${rs1})", (C_CSC_64 V9CRC:$rs2, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.sy $rs2, ${imm}(${rs1})", (C_CSC_64 YGPRC:$rs2, YGPRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.csccsp $rs2, ${imm}(${rs1})", (C_CSCCSP_64 V9CR:$rs2, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.sysp $rs2, ${imm}(${rs1})", (C_CSCCSP_64 YGPRC:$rs2, YSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.clc $rd, ${imm}(${rs1})", (C_CLC_64 V9CRC:$rd, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.ly $rd, ${imm}(${rs1})", (C_CLC_64 YGPRC:$rd, YGPRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.clccsp $rd, ${imm}(${rs1})", (C_CLCCSP_64 V9CRNoC0:$rd, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.lysp $rd, ${imm}(${rs1})", (C_CLCCSP_64 YGPRNoX0:$rd, YSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.cjal $offset", (C_CJAL simm12_lsb0:$offset), 0>;
} // [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]
let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32,
                  IsCapMode] in {
def : InstAlias<"c.cfld $rd, ${imm}(${rs1})", (C_CFLD FPR64C:$rd, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.cfsd $rs2, ${imm}(${rs1})", (C_CFSD FPR64C:$rs2, V9CRC:$rs1, uimm8_lsb000:$imm), 0>;
def : InstAlias<"c.cfldcsp $rd, ${imm}(${rs1})", (C_CFLDCSP FPR64:$rd, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.cfsdcsp $rs2, ${imm}(${rs1})", (C_CFSDCSP FPR64:$rs2, V9CSP:$rs1, uimm9_lsb000:$imm), 0>;
def : InstAlias<"c.cj $offset", (C_J simm12_lsb0:$offset), 0>;
}

//===----------------------------------------------------------------------===//
// Pseudo-instructions and codegen patterns
//===----------------------------------------------------------------------===//

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCodeGenOnly = 0,
    isAsmParserOnly = 1, Size = 8 in
def PseudoCLLC : Pseudo<(outs V9CR:$dst), (ins bare_symbol:$src), [],
                        "llc", "$dst, $src">;
def : InstAlias<"cllc $dst, $src", (PseudoCLLC V9CR:$dst, bare_symbol:$src), 0>;

def : Pat<(riscv_cllc tglobaladdr:$in), (PseudoCLLC tglobaladdr:$in)>;
def : Pat<(riscv_cllc tblockaddress:$in), (PseudoCLLC tblockaddress:$in)>;
def : Pat<(riscv_cllc tjumptable:$in), (PseudoCLLC tjumptable:$in)>;
def : Pat<(riscv_cllc tconstpool:$in), (PseudoCLLC tconstpool:$in)>;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0, isCodeGenOnly = 0,
    isAsmParserOnly = 1, Size = 8 in
def PseudoCLGC : Pseudo<(outs V9CR:$dst), (ins bare_symbol:$src), [],
                        "lgc", "$dst, $src">;
def : InstAlias<"clgc $dst, $src", (PseudoCLGC V9CR:$dst, bare_symbol:$src), 0>;

def : Pat<(riscv_clgc tglobaladdr:$in), (PseudoCLGC tglobaladdr:$in)>;

let hasSideEffects = 0, mayLoad = 1, mayStore = 0, isCodeGenOnly = 0,
    isAsmParserOnly = 1, Size = 8 in
def PseudoCLA_TLS_IE : Pseudo<(outs GPR:$dst), (ins bare_symbol:$src), [],
                              "cla.tls.ie", "$dst, $src">;

def : Pat<(riscv_cla_tls_ie tglobaltlsaddr:$in),
          (PseudoCLA_TLS_IE  tglobaltlsaddr:$in)>;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCodeGenOnly = 0,
    isAsmParserOnly = 1, Size = 8 in
def PseudoCLC_TLS_GD : Pseudo<(outs V9CR:$dst), (ins bare_symbol:$src), [],
                              "clc.tls.gd", "$dst, $src">;

def : Pat<(riscv_clc_tls_gd tglobaltlsaddr:$in),
          (PseudoCLC_TLS_GD  tglobaltlsaddr:$in)>;

let hasSideEffects = 0, mayLoad = 0, mayStore = 0, isCodeGenOnly = 0 in
def PseudoCIncOffsetTPRel : Pseudo<(outs V9CR:$rd),
                                   (ins V9CR:$rs1, GPRNoX0:$rs2,
                                        tprel_add_symbol:$src), [],
                                   "cincoffset", "$rd, $rs1, $rs2, $src">;
def : InstAlias<"cadd $rd, $rs1, $rs2, $src",
                (PseudoCIncOffsetTPRel V9CR:$rd, V9CR:$rs1, GPRNoX0:$rs2, tprel_add_symbol:$src), 0>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsRV32] in {

// Stores an FPR via splitting to two GPRs.
let hasSideEffects = 0, mayLoad = 0, mayStore = 1,
    Constraints = "@earlyclobber $tmplo,@earlyclobber $tmphi",
    usesCustomInserter = 1 in
def SplitStoreF64Pseudo
    : Pseudo<(outs GPR:$tmplo, GPR:$tmphi, GPR:$tmpdst),
             (ins FPR64:$src, GPR:$dst), []>;

// Stores an FPR via splitting to two GPRs.
let hasSideEffects = 0, mayLoad = 0, mayStore = 1,
    Constraints = "@earlyclobber $tmplo,@earlyclobber $tmphi",
    usesCustomInserter = 1 in
def CheriSplitStoreF64Pseudo
    : Pseudo<(outs GPR:$tmplo, GPR:$tmphi, V9CR:$tmpdst),
             (ins FPR64:$src, V9CR:$dst), []>;

} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsRV32]

class PatGpcr<SDPatternOperator OpNode, RVInstCheriSrcDst Inst, ValueType RetVt=XLenVT>
    : Pat<(RetVt (OpNode V9CR:$rs1)), (Inst V9CR:$rs1)>;

class PatGpcrGpcr<SDPatternOperator OpNode, RVInst Inst, ValueType RetVt=YLenVT>
    : Pat<(RetVt (OpNode V9CR:$rs1, V9CR:$rs2)), (Inst V9CR:$rs1, V9CR:$rs2)>;

class PatGpcrGpr<SDPatternOperator OpNode, RVInst Inst>
    : Pat<(OpNode V9CR:$rs1, (XLenVT GPR:$rs2)), (Inst V9CR:$rs1, GPR:$rs2)>;

class PatGpcrSimm12<SDPatternOperator OpNode, RVInstI Inst>
    : Pat<(OpNode V9CR:$rs1, simm12:$imm12), (Inst V9CR:$rs1, simm12:$imm12)>;

class PatGpcrUimm12<SDPatternOperator OpNode, RVInstI Inst>
    : Pat<(OpNode V9CR:$rs1, uimm12:$imm12), (Inst V9CR:$rs1, uimm12:$imm12)>;

class PatGprGpcr<SDPatternOperator OpNode, RVInst Inst>
    : Pat<(OpNode GPR:$rs1, V9CR:$rs2), (Inst GPR:$rs1, V9CR:$rs2)>;

/// Capability-Inspection Instructions

let Predicates = [HasCheri] in {
def : PatGpcr<int_cheri_cap_perms_get, CGetPerm>;
def : PatGpcr<int_cheri_cap_type_get, CGetType>;
def : PatGpcr<int_cheri_cap_base_get, CGetBase>;
def : PatGpcr<int_cheri_cap_length_get, CGetLen>;
def : PatGpcr<riscv_cap_tag_get, CGetTag>;
def : PatGpcr<riscv_cap_sealed_get, CGetSealed>;
def : PatGpcr<int_cheri_cap_offset_get, CGetOffset>;
def : PatGpcr<int_cheri_cap_flags_get, CGetFlags>;
def : Pat<(XLenVT (int_cheri_cap_address_get V9CR:$cs1)), (PseudoCGetAddr V9CR:$cs1)>{ let Predicates = [HasZCheriPurecapOrCheri]; }
def : PatGpcr<int_cheri_cap_high_get, CGetHigh>;
}

/// Capability-Modification Instructions

// C(Un)Seal is not part of the bakewell specification so we can no longer support
// the __builtin_cheri_(un)seal builtin.
let Predicates = [HasCheri] in {
  def : PatGpcrGpcr<int_cheri_cap_seal, CSeal>;
  def : PatGpcrGpcr<int_cheri_cap_unseal, CUnseal>;
  def : PatGpcrGpr<int_cheri_cap_perms_and, CAndPerm>;
  def : PatGpcrGpr<int_cheri_cap_flags_set, CSetFlags>;
  def : PatGpcrGpr<int_cheri_cap_offset_set, CSetOffset>;
  def : PatGpcrGpr<int_cheri_cap_address_set, CSetAddr>;
  def : PatGpcrGpr<int_cheri_cap_high_set, CSetHigh>;
  def : PatGpcrGpr<cptradd, CIncOffset>;
  def : PatGpcrSimm12<cptradd, CIncOffsetImm>;
  def : PatGpcrGpr<int_cheri_cap_bounds_set, CSetBounds>;
  def : PatGpcrGpr<int_cheri_cap_bounds_set_exact, CSetBoundsExact>;
  def : PatGpcrUimm12<int_cheri_cap_bounds_set, CSetBoundsImm>;
  def : PatGpcr<int_cheri_cap_tag_clear, CClearTag, YLenVT>;
  def : PatGpcrGpcr<int_cheri_cap_build, CBuildCap>;
  def : PatGpcrGpcr<int_cheri_cap_type_copy, CCopyType>;
  def : PatGpcrGpcr<int_cheri_cap_conditional_seal, CCSeal>;
  def : PatGpcr<int_cheri_cap_seal_entry, CSealEntry, YLenVT>;
} // HasCheri

// TODO: Make this rematerialisable like MIPS
let Predicates = [HasCheri] in {
  def : PatGpcrGpr<int_cheri_bounded_stack_cap, CSetBounds>;
  def : PatGpcrUimm12<int_cheri_bounded_stack_cap, CSetBoundsImm>;
  def : PatGpcrGpr<int_cheri_bounded_stack_cap_dynamic, CSetBounds>;
  def : PatGpcrUimm12<int_cheri_bounded_stack_cap_dynamic, CSetBoundsImm>;
  def : Pat<(CapFrameAddrRegImm V9CR:$rs1, simm12:$imm12),
            (CIncOffsetImm V9CR:$rs1, simm12:$imm12)>;
}


/// Pointer-Arithmetic Instructions

// int_cheri_cap_to_pointer and int_cheri_cap_from_pointer are expanded in C++
// code for ISAv9, so we don't need replacement patterns here.
def : Pat<(XLenVT (int_cheri_cap_diff V9CR:$cs1, V9CR:$cs2)),
          (SUB (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)),
               (XLenVT (EXTRACT_SUBREG V9CR:$cs2, sub_cap_addr)))>;

let Predicates = [IsPureCapABI, NotHasZCheriPurecap] in {
def : Pat<(inttoptr (XLenVT GPR:$rs2)), (CIncOffset X0_Y, GPR:$rs2)>;
def : Pat<(inttoptr simm12:$imm12), (CIncOffsetImm X0_Y, simm12:$imm12)>;
def : Pat<(XLenVT (ptrtoint V9CR:$rs1)), (PseudoCGetAddr V9CR:$rs1)>;
}

/// Null Capability Patterns

def : Pat<(inttoptr (XLenVT 0)), (YLenVT (COPY X0_Y))>;
def : Pat<(ptrtoint (YLenVT (inttoptr (XLenVT 0)))),
          (XLenVT (COPY (XLenVT X0)))>;

/// Pointer-Comparison Instructions

// Currently no dedicated instructions, so we:
// * Rely on a merged register file
// * Break untagged < tagged semantics
// * Can't implement exact equality
class CheriSetCCPatGpcrGpcr<PatFrag CondOp, dag GprGprDag>
    : Pat<(XLenVT (CondOp V9CR:$cs1, V9CR:$cs2)),
          (OutPatFrag<(ops node:$rs1, node:$rs2), GprGprDag>
            (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)),
            (XLenVT (EXTRACT_SUBREG V9CR:$cs2, sub_cap_addr)))>;

multiclass CheriSetCCPatGpcrImm<PatFrag CondOp, Operand ImmTy, dag GprImmDag> {
  def : Pat<(XLenVT (CondOp V9CR:$cs1, (inttoptr ImmTy:$imm12))),
            (OutPatFrag<(ops node:$rs1, node:$imm12), GprImmDag>
              (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)), ImmTy:$imm12)>;
  def : Pat<(XLenVT (CondOp V9CR:$cs1, (cptradd (inttoptr (XLenVT 0)), ImmTy:$imm12))),
            (OutPatFrag<(ops node:$rs1, node:$imm12), GprImmDag>
              (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)), ImmTy:$imm12)>;
  def : Pat<(XLenVT (CondOp V9CR:$cs1,
              (int_cheri_cap_offset_set (inttoptr (XLenVT 0)), ImmTy:$imm12))),
            (OutPatFrag<(ops node:$rs1, node:$imm12), GprImmDag>
              (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)), ImmTy:$imm12)>;
  def : Pat<(XLenVT (CondOp V9CR:$cs1,
              (int_cheri_cap_address_set (inttoptr (XLenVT 0)), ImmTy:$imm12))),
            (OutPatFrag<(ops node:$rs1, node:$imm12), GprImmDag>
              (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)), ImmTy:$imm12)>;
}

multiclass CheriSetCCPatGpcrSimm12<PatFrag CondOp, dag GprImmDag>
    : CheriSetCCPatGpcrImm<CondOp, simm12, GprImmDag>;

multiclass CheriSetCCPatGpcrSimm12Plus1<PatFrag CondOp, dag GprImmDag>
    : CheriSetCCPatGpcrImm<CondOp, simm12_plus1, GprImmDag>;

class CheriSetCCPatGpcrNull<PatFrag CondOp, dag GprDag>
    : Pat<(XLenVT (CondOp V9CR:$cs1, (inttoptr (XLenVT 0)))),
          (OutPatFrag<(ops node:$rs1), GprDag>
            (XLenVT (EXTRACT_SUBREG V9CR:$cs1, sub_cap_addr)))>;

class Swap<PatFrag BinFrag>
    : PatFrag<(ops node:$a, node:$b), (BinFrag $b, $a)>;

// NB: Constants are wrapped as (cptradd (inttoptr 0) C) so the operand order
// isn't canonicalised like for integers so we have to add extra patterns for
// the commutative and inverse cases. Maybe we should support Constant:cN,
// represent them as (inttoptr C), or just canonicalise the current form?

def  : CheriSetCCPatGpcrGpcr<setlt, (SLT node:$rs1, node:$rs2)>;
defm : CheriSetCCPatGpcrSimm12<setlt, (SLTI node:$rs1, node:$imm12)>;
defm : CheriSetCCPatGpcrSimm12<Swap<setgt>, (SLTI node:$rs1, node:$imm12)>;
def  : CheriSetCCPatGpcrGpcr<setult, (SLTU node:$rs1, node:$rs2)>;
defm : CheriSetCCPatGpcrSimm12<setult, (SLTIU node:$rs1, node:$imm12)>;
defm : CheriSetCCPatGpcrSimm12<Swap<setugt>, (SLTIU node:$rs1, node:$imm12)>;

def  : CheriSetCCPatGpcrNull<seteq, (SLTIU node:$rs1, 1)>;
def  : CheriSetCCPatGpcrGpcr<seteq, (SLTIU (XOR node:$rs1, node:$rs2), 1)>;
defm : CheriSetCCPatGpcrSimm12Plus1<
           seteq, (SLTIU (ADDI node:$rs1, (NegImm node:$imm12)), 1)>;
defm : CheriSetCCPatGpcrSimm12Plus1<
           Swap<seteq>, (SLTIU (ADDI node:$rs1, (NegImm node:$imm12)), 1)>;
def  : CheriSetCCPatGpcrNull<setne, (SLTU (XLenVT X0), node:$rs1)>;
def  : CheriSetCCPatGpcrGpcr<setne, (SLTU (XLenVT X0), (XOR node:$rs1, node:$rs2))>;
defm : CheriSetCCPatGpcrSimm12Plus1<
           setne, (SLTU (XLenVT X0), (ADDI node:$rs1, (NegImm node:$imm12)))>;
defm : CheriSetCCPatGpcrSimm12Plus1<
           Swap<setne>, (SLTU (XLenVT X0), (ADDI node:$rs1, (NegImm node:$imm12)))>;
def  : CheriSetCCPatGpcrGpcr<setugt, (SLTU node:$rs2, node:$rs1)>;
def  : CheriSetCCPatGpcrGpcr<setuge, (XORI (SLTU node:$rs1, node:$rs2), 1)>;
def  : CheriSetCCPatGpcrGpcr<setule, (XORI (SLTU node:$rs2, node:$rs1), 1)>;
def  : CheriSetCCPatGpcrGpcr<setgt, (SLT node:$rs2, node:$rs1)>;
def  : CheriSetCCPatGpcrGpcr<setge, (XORI (SLT node:$rs1, node:$rs2), 1)>;
def  : CheriSetCCPatGpcrGpcr<setle, (XORI (SLT node:$rs2, node:$rs1), 1)>;

defm Select_GPCR : SelectCC_GPR_rrirr<V9CR, YLenVT>;

/// Control-Flow Instructions

// No dedicated instructions; see above

class CheriBccPat<PatFrag CondOp, RVInstB Inst>
    : Pat<(brcond (XLenVT (CondOp V9CR:$rs1, V9CR:$rs2)), bb:$imm12),
          (Inst
            (XLenVT (EXTRACT_SUBREG V9CR:$rs1, sub_cap_addr)),
            (XLenVT (EXTRACT_SUBREG V9CR:$rs2, sub_cap_addr)),
            simm13_lsb0:$imm12)>;

def : CheriBccPat<seteq, BEQ>;
def : CheriBccPat<setne, BNE>;
def : CheriBccPat<setlt, BLT>;
def : CheriBccPat<setge, BGE>;
def : CheriBccPat<setult, BLTU>;
def : CheriBccPat<setuge, BGEU>;

class CheriBccSwapPat<PatFrag CondOp, RVInst InstBcc>
    : Pat<(brcond (XLenVT (CondOp V9CR:$rs1, V9CR:$rs2)), bb:$imm12),
          (InstBcc
            (XLenVT (EXTRACT_SUBREG V9CR:$rs2, sub_cap_addr)),
            (XLenVT (EXTRACT_SUBREG V9CR:$rs1, sub_cap_addr)),
            simm13_lsb0:$imm12)>;

def : CheriBccSwapPat<setgt, BLT>;
def : CheriBccSwapPat<setle, BGE>;
def : CheriBccSwapPat<setugt, BLTU>;
def : CheriBccSwapPat<setule, BGEU>;

/// Assertion Instructions

let Predicates = [HasCheri] in {
def : PatGpcrGpcr<riscv_cap_subset_test, CTestSubset, XLenVT>;
def : PatGpcrGpcr<riscv_cap_equal_exact, CSEQX, XLenVT>;
}

/// Special Capability Register Access Instructions

let Predicates = [HasCheri] in
def : Pat<(int_cheri_ddc_get), (CSpecialRW SCR_DDC.Encoding, X0_Y)>;
let Predicates = [HasZCheriPurecapOrCheri, IsPureCapABI] in
def : Pat<(int_cheri_stack_cap_get), (YLenVT (COPY X2_Y))>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in
def : Pat<(int_cheri_pcc_get), (AUIPCC 0)>;

let Predicates = [HasCheri, NotCapMode] in
def : Pat<(int_cheri_pcc_get), (CSpecialRW SCR_PCC.Encoding, X0_Y)>;

/// Fast Register-Clearing Instructions

/// Adjusting to Compressed Capability Precision Instructions

let Predicates = [HasCheri] in {
def : PatGpr<int_cheri_round_representable_length, CRRL>;
def : PatGpr<int_cheri_representable_alignment_mask, CRAM>;
}

/// Tag-Memory Access Instructions

let Predicates = [HasCheri] in
def : PatGpcr<int_cheri_cap_load_tags, CLoadTags, XLenVT>;

/// Memory-Access with Explicit Address Type Instructions

multiclass CheriExplicitLdPat<PatFrag LoadOp, RVInst Inst,
                              DAGOperand AddrTy,
                              ValueType AddrVt = XLenVT,
                              ValueType ReturnVt = XLenVT> {
  def : Pat<(ReturnVt (LoadOp (AddrVt AddrTy:$rs1))), (Inst AddrTy:$rs1)>;
}

multiclass CheriExplicitStPat<PatFrag StoreOp, RVInst Inst,
                              DAGOperand StTy, DAGOperand AddrTy,
                              ValueType StoreVt = XLenVT,
                              ValueType AddrVt = XLenVT> {
  def : Pat<(StoreOp (StoreVt StTy:$rs2), (AddrVt AddrTy:$rs1)), (Inst StTy:$rs2, AddrTy:$rs1)>;
}

/// DDC-relative loads

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
defm : CheriExplicitLdPat<sextloadi8, LB_DDC, GPR>;
defm : CheriExplicitLdPat<extloadi8, LB_DDC, GPR>;
defm : CheriExplicitLdPat<sextloadi16, LH_DDC, GPR>;
defm : CheriExplicitLdPat<extloadi16, LH_DDC, GPR>;
defm : CheriExplicitLdPat<zextloadi8, LBU_DDC, GPR>;
defm : CheriExplicitLdPat<zextloadi16, LHU_DDC, GPR>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsRV32] in {
defm : CheriExplicitLdPat<load, LW_DDC, GPR>;
defm : CheriExplicitLdPat<load, LC_DDC_64, GPR, XLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsRV64] in {
defm : CheriExplicitLdPat<sextloadi32, LW_DDC, GPR>;
defm : CheriExplicitLdPat<extloadi32, LW_DDC, GPR>;
defm : CheriExplicitLdPat<load, LD_DDC, GPR>;
defm : CheriExplicitLdPat<zextloadi32, LWU_DDC, GPR>;
defm : CheriExplicitLdPat<load, LC_DDC_128, GPR, XLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtF] in
def : Pat<(load (XLenVT GPR:$rs1)), (FMV_W_X (LW_DDC (XLenVT GPR:$rs1)))>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtD, IsRV32] in
def : Pat<(load (XLenVT GPR:$rs1)),
          (BuildPairF64Pseudo (LW_DDC (XLenVT GPR:$rs1)),
                              (LW_DDC (ADDI (XLenVT GPR:$rs1), 4)))>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtD, IsRV64] in
def : Pat<(load (XLenVT GPR:$rs1)), (FMV_D_X (LD_DDC (XLenVT GPR:$rs1)))>;

/// DDC-relative stores

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in {
defm : CheriExplicitStPat<truncstorei8, SB_DDC, GPR, GPR>;
defm : CheriExplicitStPat<truncstorei16, SH_DDC, GPR, GPR>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsRV32] in {
defm : CheriExplicitStPat<store, SW_DDC, GPR, GPR>;
defm : CheriExplicitStPat<store, SC_DDC_64, V9CR, GPR, YLenVT, XLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsRV64] in {
defm : CheriExplicitStPat<truncstorei32, SW_DDC, GPR, GPR>;
defm : CheriExplicitStPat<store, SD_DDC, GPR, GPR>;
defm : CheriExplicitStPat<store, SC_DDC_128, V9CR, GPR, YLenVT, XLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtF] in
def : Pat<(store FPR32:$rs2, (XLenVT GPR:$rs1)),
          (SW_DDC (FMV_X_W FPR32:$rs2), (XLenVT GPR:$rs1))>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtD, IsRV32] in
def : Pat<(store FPR64:$rs2, (XLenVT GPR:$rs1)),
          (KILL (SplitStoreF64Pseudo FPR64:$rs2, (XLenVT GPR:$rs1)))>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, HasStdExtD, IsRV64] in
def : Pat<(store FPR64:$rs2, (XLenVT GPR:$rs1)),
          (SD_DDC (FMV_X_D FPR64:$rs2), (XLenVT GPR:$rs1))>;

/// Capability loads

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode] in {
defm : CheriExplicitLdPat<sextloadi8, LB_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<extloadi8, LB_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<sextloadi16, LH_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<extloadi16, LH_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<zextloadi8, LBU_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<zextloadi16, LHU_CAP, V9CR, YLenVT, XLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, IsRV32] in {
defm : CheriExplicitLdPat<load, LW_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<load, LC_CAP_64, V9CR, YLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, IsRV64] in {
defm : CheriExplicitLdPat<sextloadi32, LW_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<extloadi32, LW_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<load, LD_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<zextloadi32, LWU_CAP, V9CR, YLenVT, XLenVT>;
defm : CheriExplicitLdPat<load, LC_CAP_128, V9CR, YLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtF] in
def : Pat<(load V9CR:$rs1), (FMV_W_X (LW_CAP V9CR:$rs1))>;

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtD, IsRV32] in
def : Pat<(load V9CR:$rs1),
          (BuildPairF64Pseudo (LW_CAP V9CR:$rs1),
                              (LW_CAP (CIncOffsetImm V9CR:$rs1, 4)))>;

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtD, IsRV64] in
def : Pat<(load V9CR:$rs1), (FMV_D_X (LD_CAP V9CR:$rs1))>;

/// Capability stores

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode] in {
defm : CheriExplicitStPat<truncstorei8, SB_CAP, GPR, V9CR, XLenVT, YLenVT>;
defm : CheriExplicitStPat<truncstorei16, SH_CAP, GPR, V9CR, XLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, IsRV32] in {
defm : CheriExplicitStPat<store, SW_CAP, GPR, V9CR, XLenVT, YLenVT>;
defm : CheriExplicitStPat<store, SC_CAP_64, V9CR, V9CR, YLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, IsRV64] in {
defm : CheriExplicitStPat<truncstorei32, SW_CAP, GPR, V9CR, XLenVT, YLenVT>;
defm : CheriExplicitStPat<store, SD_CAP, GPR, V9CR, XLenVT, YLenVT>;
defm : CheriExplicitStPat<store, SC_CAP_128, V9CR, V9CR, YLenVT, YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtF] in
def : Pat<(store FPR32:$rs2, V9CR:$rs1),
          (SW_CAP (FMV_X_W FPR32:$rs2), V9CR:$rs1)>;

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtD, IsRV32] in
def : Pat<(store FPR64:$rs2, V9CR:$rs1),
          (KILL (CheriSplitStoreF64Pseudo FPR64:$rs2, V9CR:$rs1))>;

let Predicates = [HasZCheriPurecapOrCheri, NotCapMode, HasStdExtD, IsRV64] in
def : Pat<(store FPR64:$rs2, V9CR:$rs1),
          (SD_CAP (FMV_X_D FPR64:$rs2), V9CR:$rs1)>;

/// Non-Capability Mode Instructions

/// Memory-Access Instructions


multiclass AMOCapPat<string CLenStr, string AtomicOp, string BaseInst> {
  defvar optUnderScore = !if(!eq(CLenStr, ""), "", "_");
  def : PatGprGpcr<!cast<PatFrag>(AtomicOp#"_monotonic"),
                   !cast<RVInst>(BaseInst#optUnderScore#CLenStr)>;
  def : PatGprGpcr<!cast<PatFrag>(AtomicOp#"_acquire"),
                   !cast<RVInst>(BaseInst#"_AQ"#optUnderScore#CLenStr)>;
  def : PatGprGpcr<!cast<PatFrag>(AtomicOp#"_release"),
                   !cast<RVInst>(BaseInst#"_RL"#optUnderScore#CLenStr)>;
  def : PatGprGpcr<!cast<PatFrag>(AtomicOp#"_acq_rel"),
                   !cast<RVInst>(BaseInst#"_AQ_RL"#optUnderScore#CLenStr)>;
  def : PatGprGpcr<!cast<PatFrag>(AtomicOp#"_seq_cst"),
                   !cast<RVInst>(BaseInst#"_AQ_RL"#optUnderScore#CLenStr)>;
}

let Predicates = [HasCheri, IsRV32, NotCapMode] in {
def : LdPat<load, LC_64, c64>;
def : StPat<store, SC_64, V9CR, c64>;
} // Predicates = [HasCheri, IsRV32, NotCapMode]

let Predicates = [HasCheri, IsRV64, NotCapMode] in {
def : LdPat<load, LC_128, c128>;
def : StPat<store, SC_128, V9CR, c128>;
} // Predicates = [HasCheri, IsRV64, NotCapMode]

let Predicates = [HasCheri, HasStdExtA, IsRV32, NotCapMode] in {
def : LdPat<atomic_load_cap, LC_64, c64>;
def : StPat<atomic_store_cap, SC_64, V9CR, c64>;
defm : AMOCapPat<"64", "atomic_swap_cap", "AMOSWAP_C">;
} // Predicates = [HasCheri, HasStdExtA, IsRV32, NotCapMode]

let Predicates = [HasCheri, HasStdExtA, IsRV64, NotCapMode] in {
def : LdPat<atomic_load_cap, LC_128, c128>;
def : StPat<atomic_store_cap, SC_128, V9CR, c128>;
defm : AMOCapPat<"128", "atomic_swap_cap", "AMOSWAP_C">;
} // Predicates = [HasCheri, HasStdExtA, IsRV64, NotCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def PseudoAtomicLoadAddCap : PseudoAMO<V9CR> { let Size = 16; }
def PseudoAtomicLoadSubCap : PseudoAMO<V9CR> { let Size = 20; }
def PseudoAtomicLoadAndCap : PseudoAMO<V9CR> { let Size = 20; }
def PseudoAtomicLoadOrCap : PseudoAMO<V9CR> { let Size = 20; }
def PseudoAtomicLoadXorCap : PseudoAMO<V9CR> { let Size = 20; }
def PseudoAtomicLoadMaxCap : PseudoAMO<V9CR> { let Size = 24; }
def PseudoAtomicLoadMinCap : PseudoAMO<V9CR> { let Size = 24; }
def PseudoAtomicLoadUMaxCap : PseudoAMO<V9CR> { let Size = 24; }
def PseudoAtomicLoadUMinCap : PseudoAMO<V9CR> { let Size = 24; }
def PseudoAtomicLoadNandCap : PseudoAMO<V9CR> { let Size = 24; }
def PseudoCmpXchgCap : PseudoCmpXchg<V9CR> { let Size = 16; }
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA]f

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, NotCapMode] in {
defm : PseudoAMOPat<"atomic_load_add_cap", PseudoAtomicLoadAddCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_sub_cap", PseudoAtomicLoadSubCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_and_cap", PseudoAtomicLoadAndCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_or_cap", PseudoAtomicLoadOrCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_xor_cap", PseudoAtomicLoadXorCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_max_cap", PseudoAtomicLoadMaxCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_min_cap", PseudoAtomicLoadMinCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_umax_cap", PseudoAtomicLoadUMaxCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_umin_cap", PseudoAtomicLoadUMinCap, V9CR>;
defm : PseudoAMOPat<"atomic_load_nand_cap", PseudoAtomicLoadNandCap, V9CR>;
defm : PseudoCmpXchgPat<"atomic_cmp_swap_cap", PseudoCmpXchgCap, YLenVT, V9CR>;
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, NotCapMode]

/// Capability Mode Instructions

multiclass CheriLdPat<PatFrag LoadOp, RVInst Inst, ValueType ReturnVt = XLenVT> {
  def : Pat<(ReturnVt (LoadOp (CapRegImm V9CR:$rs1, simm12:$imm12))),
            (Inst V9CR:$rs1, simm12:$imm12)>;
}

multiclass CheriStPat<PatFrag StoreOp, RVInst Inst, DAGOperand StTy, ValueType StoreVt = XLenVT> {
  def : Pat<(StoreOp (StoreVt StTy:$rs2), (CapRegImm V9CR:$rs1, simm12:$imm12)),
            (Inst (StoreVt StTy:$rs2), V9CR:$rs1, simm12:$imm12)>;
}

multiclass CheriAtomicStPat<PatFrag StoreOp, RVInst Inst, DAGOperand StTy, ValueType StoreVt>
    : CheriStPat<StoreOp, Inst, StTy, StoreVt>;

multiclass CheriAMOPat<string AtomicOp, string BaseInst> {
  def : PatGpcrGpr<!cast<PatFrag>(AtomicOp#"_monotonic"),
                   !cast<RVInst>(BaseInst)>;
  def : PatGpcrGpr<!cast<PatFrag>(AtomicOp#"_acquire"),
                   !cast<RVInst>(BaseInst#"_AQ")>;
  def : PatGpcrGpr<!cast<PatFrag>(AtomicOp#"_release"),
                   !cast<RVInst>(BaseInst#"_RL")>;
  def : PatGpcrGpr<!cast<PatFrag>(AtomicOp#"_acq_rel"),
                   !cast<RVInst>(BaseInst#"_AQ_RL")>;
  def : PatGpcrGpr<!cast<PatFrag>(AtomicOp#"_seq_cst"),
                   !cast<RVInst>(BaseInst#"_AQ_RL")>;
}

multiclass CheriAMOSubPat<string AtomicOp, string BaseInst> {
  def : Pat<(!cast<PatFrag>(AtomicOp#"_monotonic") V9CR:$addr, (XLenVT GPR:$incr)),
            (!cast<RVInst>(BaseInst) V9CR:$addr, (SUB (XLenVT X0), (XLenVT GPR:$incr)))>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_acquire") V9CR:$addr, (XLenVT GPR:$incr)),
            (!cast<RVInst>(BaseInst#"_AQ") V9CR:$addr, (SUB (XLenVT X0), (XLenVT GPR:$incr)))>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_release") V9CR:$addr, (XLenVT GPR:$incr)),
            (!cast<RVInst>(BaseInst#"_RL") V9CR:$addr, (SUB (XLenVT X0), (XLenVT GPR:$incr)))>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_acq_rel") V9CR:$addr, (XLenVT GPR:$incr)),
            (!cast<RVInst>(BaseInst#"_AQ_RL") V9CR:$addr, (SUB (XLenVT X0), (XLenVT GPR:$incr)))>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_seq_cst") V9CR:$addr, (XLenVT GPR:$incr)),
            (!cast<RVInst>(BaseInst#"_AQ_RL") V9CR:$addr, (SUB (XLenVT X0), (XLenVT GPR:$incr)))>;
}

class PseudoCheriAMO<DAGOperand ValTy=GPR>
    : Pseudo<(outs ValTy:$res, ValTy:$scratch),
             (ins V9CR:$addr, ValTy:$incr, ixlenimm:$ordering), []> {
  let Constraints = "@earlyclobber $res,@earlyclobber $scratch";
  let mayLoad = 1;
  let mayStore = 1;
  let hasSideEffects = 0;
}

multiclass PseudoCheriAMOPat<string AtomicOp, Instruction BaseInst,
                             DAGOperand ValTy=GPR, ValueType vt=XLenVT> {
  def : Pat<(!cast<PatFrag>(AtomicOp#"_monotonic") V9CR:$addr, (vt ValTy:$incr)),
            (BaseInst V9CR:$addr, ValTy:$incr, 2)>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_acquire") V9CR:$addr, (vt ValTy:$incr)),
            (BaseInst V9CR:$addr, ValTy:$incr, 4)>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_release") V9CR:$addr, (vt ValTy:$incr)),
            (BaseInst V9CR:$addr, ValTy:$incr, 5)>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_acq_rel") V9CR:$addr, (vt ValTy:$incr)),
            (BaseInst V9CR:$addr, ValTy:$incr, 6)>;
  def : Pat<(!cast<PatFrag>(AtomicOp#"_seq_cst") V9CR:$addr, (vt ValTy:$incr)),
            (BaseInst V9CR:$addr, ValTy:$incr, 7)>;
}

class PseudoCheriCmpXchg<DAGOperand ValTy=GPR>
    : Pseudo<(outs ValTy:$res, GPR:$scratch),
             (ins V9CR:$addr, ValTy:$cmpval, ValTy:$newval, ixlenimm:$ordering), []> {
  let Constraints = "@earlyclobber $res,@earlyclobber $scratch";
  let mayLoad = 1;
  let mayStore = 1;
  let hasSideEffects = 0;
}

multiclass PseudoCheriCmpXchgPat<string Op, Pseudo CmpXchgInst,
                                 DAGOperand ValTy=GPR, ValueType vt=XLenVT> {
  def : Pat<(!cast<PatFrag>(Op#"_monotonic") V9CR:$addr, (vt ValTy:$cmp), (vt ValTy:$new)),
            (CmpXchgInst V9CR:$addr, ValTy:$cmp, ValTy:$new, 2)>;
  def : Pat<(!cast<PatFrag>(Op#"_acquire") V9CR:$addr, (vt ValTy:$cmp), (vt ValTy:$new)),
            (CmpXchgInst V9CR:$addr, ValTy:$cmp, ValTy:$new, 4)>;
  def : Pat<(!cast<PatFrag>(Op#"_release") V9CR:$addr, (vt ValTy:$cmp), (vt ValTy:$new)),
            (CmpXchgInst V9CR:$addr, ValTy:$cmp, ValTy:$new, 5)>;
  def : Pat<(!cast<PatFrag>(Op#"_acq_rel") V9CR:$addr, (vt ValTy:$cmp), (vt ValTy:$new)),
            (CmpXchgInst V9CR:$addr, ValTy:$cmp, ValTy:$new, 6)>;
  def : Pat<(!cast<PatFrag>(Op#"_seq_cst") V9CR:$addr, (vt ValTy:$cmp), (vt ValTy:$new)),
            (CmpXchgInst V9CR:$addr, ValTy:$cmp, ValTy:$new, 7)>;
}

multiclass CheriAMOCapPat<string CLenStr, string AtomicOp, string BaseInst> {
  defvar optUnderScore = !if(!eq(CLenStr, ""), "", "_");
  def : PatGpcrGpcr<!cast<PatFrag>(AtomicOp#"_monotonic"),
                    !cast<RVInst>(BaseInst#optUnderScore#CLenStr), YLenVT>;
  def : PatGpcrGpcr<!cast<PatFrag>(AtomicOp#"_acquire"),
                    !cast<RVInst>(BaseInst#"_AQ"#optUnderScore#CLenStr), YLenVT>;
  def : PatGpcrGpcr<!cast<PatFrag>(AtomicOp#"_release"),
                    !cast<RVInst>(BaseInst#"_RL"#optUnderScore#CLenStr), YLenVT>;
  def : PatGpcrGpcr<!cast<PatFrag>(AtomicOp#"_acq_rel"),
                    !cast<RVInst>(BaseInst#"_AQ_RL"#optUnderScore#CLenStr), YLenVT>;
  def : PatGpcrGpcr<!cast<PatFrag>(AtomicOp#"_seq_cst"),
                    !cast<RVInst>(BaseInst#"_AQ_RL"#optUnderScore#CLenStr), YLenVT>;
}

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA] in {
def PseudoCheriAtomicSwap8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadAdd8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadSub8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadAnd8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadOr8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadXor8 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadMax8 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadMin8 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadUMax8 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadUMin8 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadNand8 : PseudoCheriAMO { let Size = 20; }
def PseudoCheriCmpXchg8 : PseudoCheriCmpXchg { let Size = 16; }

def PseudoCheriAtomicSwap16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadAdd16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadSub16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadAnd16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadOr16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadXor16 : PseudoCheriAMO { let Size = 16; }
def PseudoCheriAtomicLoadMax16 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadMin16 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadUMax16 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadUMin16 : PseudoCheriAMO { let Size = 24; }
def PseudoCheriAtomicLoadNand16 : PseudoCheriAMO { let Size = 20; }
def PseudoCheriCmpXchg16 : PseudoCheriCmpXchg { let Size = 16; }

def PseudoCheriAtomicLoadNand32 : PseudoCheriAMO { let Size = 20; }
def PseudoCheriCmpXchg32 : PseudoCheriCmpXchg { let Size = 16; }

def PseudoCheriAtomicLoadAddCap : PseudoCheriAMO<V9CR> { let Size = 16; }
def PseudoCheriAtomicLoadSubCap : PseudoCheriAMO<V9CR> { let Size = 20; }
def PseudoCheriAtomicLoadAndCap : PseudoCheriAMO<V9CR> { let Size = 20; }
def PseudoCheriAtomicLoadOrCap : PseudoCheriAMO<V9CR> { let Size = 20; }
def PseudoCheriAtomicLoadXorCap : PseudoCheriAMO<V9CR> { let Size = 20; }
def PseudoCheriAtomicLoadMaxCap : PseudoCheriAMO<V9CR> { let Size = 24; }
def PseudoCheriAtomicLoadMinCap : PseudoCheriAMO<V9CR> { let Size = 24; }
def PseudoCheriAtomicLoadUMaxCap : PseudoCheriAMO<V9CR> { let Size = 24; }
def PseudoCheriAtomicLoadUMinCap : PseudoCheriAMO<V9CR> { let Size = 24; }
def PseudoCheriAtomicLoadNandCap : PseudoCheriAMO<V9CR> { let Size = 24; }
def PseudoCheriCmpXchgCap : PseudoCheriCmpXchg<V9CR> { let Size = 16; }
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64] in {
def PseudoCheriAtomicLoadNand64 : PseudoCheriAMO { let Size = 20; }
def PseudoCheriCmpXchg64 : PseudoCheriCmpXchg { let Size = 16; }
} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64]

/// 'I' (Integer) base

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI] in {
let isBarrier = 1, isBranch = 1, isTerminator = 1 in
def PseudoCBR : Pseudo<(outs), (ins simm21_lsb0_jal:$imm20), [(br bb:$imm20)]>,
                PseudoInstExpansion<(CJAL X0_Y, simm21_lsb0_jal:$imm20)>;

let isCall = 1, Defs = [X1_Y] in
let isBarrier = 1, isBranch = 1, isIndirectBranch = 1, isTerminator = 1 in
def PseudoCBRIND : Pseudo<(outs), (ins V9CR:$rs1, simm12:$imm12), []>,
                   PseudoInstExpansion<(CJALR X0_Y, V9CR:$rs1, simm12:$imm12)>;

def : Pat<(brind V9CR:$rs1), (PseudoCBRIND V9CR:$rs1, 0)>;
def : Pat<(brind (cptradd V9CR:$rs1, simm12:$imm12)),
          (PseudoCBRIND V9CR:$rs1, simm12:$imm12)>;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI]

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode],
    isCall = 1, isBarrier = 1, isCodeGenOnly = 0, hasSideEffects = 0,
    mayStore = 0, mayLoad = 0, Size = 8 in
def PseudoCCALLReg : Pseudo<(outs V9CR:$rd),
                            (ins cap_call_symbol:$func), []> {
  let AsmString = "call\t$rd, $func";
}
let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in
def : InstAlias<"ccall $rd, $func",
                  (PseudoCCALLReg V9CR:$rd, cap_call_symbol:$func),
                  0>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode],
    isCall = 1, Defs = [X1_Y], isCodeGenOnly = 0, Size = 8 in
def PseudoCCALL : Pseudo<(outs), (ins cap_call_symbol:$func), []> {
  let AsmString = "call\t$func";
}
let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in
def : InstAlias<"ccall $func",
                  (PseudoCCALL cap_call_symbol:$func),
                  0>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI] in {
def : Pat<(riscv_cap_call tglobaladdr:$func),
          (PseudoCCALL tglobaladdr:$func)>;
def : Pat<(riscv_cap_call texternalsym:$func),
          (PseudoCCALL texternalsym:$func)>;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI]

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI],
    isCall = 1, Defs = [X1_Y] in
def PseudoCCALLIndirect : Pseudo<(outs), (ins V9CR:$rs1),
                                 [(riscv_cap_call V9CR:$rs1)]>,
                          PseudoInstExpansion<(CJALR X1_Y, V9CR:$rs1, 0)>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI],
    isBarrier = 1, isReturn = 1, isTerminator = 1 in
def PseudoCRET : Pseudo<(outs), (ins), [(riscv_ret_glue)]>,
                 PseudoInstExpansion<(CJALR X0_Y, X1_Y, 0)>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode],
    isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, Uses = [X2_Y],
    isCodeGenOnly = 0, Size = 8 in
def PseudoCTAIL : Pseudo<(outs), (ins cap_call_symbol:$dst), []> {
  let AsmString = "tail\t$dst";
}
let Predicates = [HasZCheriPurecapOrCheri, IsCapMode] in
def : InstAlias<"ctail $dst",
                  (PseudoCTAIL cap_call_symbol:$dst),
                  0>, Requires<[HasCheri]>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI],
    isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, Uses = [X2_Y] in
def PseudoCTAILIndirect : Pseudo<(outs), (ins V9CRTC:$rs1),
                                 [(riscv_cap_tail V9CRTC:$rs1)]>,
                          PseudoInstExpansion<(CJALR X0_Y, V9CR:$rs1, 0)>;

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI] in {
def : Pat<(riscv_cap_tail tglobaladdr:$dst),
          (PseudoCTAIL texternalsym:$dst)>;
def : Pat<(riscv_cap_tail texternalsym:$dst),
          (PseudoCTAIL texternalsym:$dst)>;
} // Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI]

let Predicates = [HasZCheriPurecapOrCheri, IsCapMode, IsPureCapABI] in
let isCall = 0, isBarrier = 1, isBranch = 1, isTerminator = 1, Size = 8,
    isCodeGenOnly = 0, hasSideEffects = 0, mayStore = 0, mayLoad = 0 in
def PseudoCJump : Pseudo<(outs V9CR:$rd),
                         (ins pseudo_cap_jump_symbol:$target), []> {
  let AsmString = "jump\t$target, $rd";
}

defm : CheriLdPat<sextloadi8, CLB>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriLdPat<extloadi8, CLB>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriLdPat<sextloadi16, CLH>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriLdPat<extloadi16, CLH>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriLdPat<load, CLW>, Requires<[HasZCheriPurecapOrCheri, IsRV32, IsCapMode]>;
defm : CheriLdPat<zextloadi8, CLBU>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriLdPat<zextloadi16, CLHU>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;

defm : CheriStPat<truncstorei8, CSB, GPR>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriStPat<truncstorei16, CSH, GPR>, Requires<[HasZCheriPurecapOrCheri, IsCapMode]>;
defm : CheriStPat<store, CSW, GPR>, Requires<[HasZCheriPurecapOrCheri, IsRV32, IsCapMode]>;

let Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode] in {

/// Loads

defm : CheriLdPat<sextloadi32, CLW>;
defm : CheriLdPat<extloadi32, CLW>;
defm : CheriLdPat<zextloadi32, CLWU>;
defm : CheriLdPat<load, CLD>;

/// Stores

defm : CheriStPat<truncstorei32, CSW, GPR>;
defm : CheriStPat<store, CSD, GPR>;
} // Predicates = [HasZCheriPurecapOrCheri, IsRV64, IsCapMode]

/// Other pseudo-instructions

// Pessimistically assume the stack pointer will be clobbered
let Predicates = [HasZCheriPurecapOrCheri, IsPureCapABI] in {
let Defs = [X2_Y], Uses = [X2_Y] in {
def ADJCALLSTACKDOWNCAP : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                 [(callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUPCAP   : Pseudo<(outs), (ins i32imm:$amt1, i32imm:$amt2),
                                 [(callseq_end timm:$amt1, timm:$amt2)]>;
} // Defs = [X2_Y], Uses = [X2_Y]
} // Predicates = [HasZCheriPurecapOrCheri, IsPureCapABI]

/// 'A' (Atomic Instructions) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsCapMode] in {

/// Atomic loads and stores

// Fences will be inserted for atomic load/stores according to the logic in
// RISCVTargetLowering::{emitLeadingFence,emitTrailingFence}.

defm : CheriLdPat<atomic_load_8,  CLB>;
defm : CheriLdPat<atomic_load_16, CLH>;
defm : CheriLdPat<atomic_load_32, CLW>;

defm : CheriAtomicStPat<atomic_store_8,  CSB, GPR, XLenVT>;
defm : CheriAtomicStPat<atomic_store_16, CSH, GPR, XLenVT>;
defm : CheriAtomicStPat<atomic_store_32, CSW, GPR, XLenVT>;

/// AMOs

defm : CheriAMOPat<"atomic_swap_i32", "CAMOSWAP_W">;
defm : CheriAMOPat<"atomic_load_add_i32", "CAMOADD_W">;
defm : CheriAMOSubPat<"atomic_load_sub_i32", "CAMOADD_W">;
defm : CheriAMOPat<"atomic_load_and_i32", "CAMOAND_W">;
defm : CheriAMOPat<"atomic_load_or_i32", "CAMOOR_W">;
defm : CheriAMOPat<"atomic_load_xor_i32", "CAMOXOR_W">;
defm : CheriAMOPat<"atomic_load_max_i32", "CAMOMAX_W">;
defm : CheriAMOPat<"atomic_load_min_i32", "CAMOMIN_W">;
defm : CheriAMOPat<"atomic_load_umax_i32", "CAMOMAXU_W">;
defm : CheriAMOPat<"atomic_load_umin_i32", "CAMOMINU_W">;

/// Pseudo AMOs

defm : PseudoCheriAMOPat<"atomic_swap_i8", PseudoCheriAtomicSwap8>;
defm : PseudoCheriAMOPat<"atomic_load_add_i8", PseudoCheriAtomicLoadAdd8>;
defm : PseudoCheriAMOPat<"atomic_load_sub_i8", PseudoCheriAtomicLoadSub8>;
defm : PseudoCheriAMOPat<"atomic_load_and_i8", PseudoCheriAtomicLoadAnd8>;
defm : PseudoCheriAMOPat<"atomic_load_or_i8", PseudoCheriAtomicLoadOr8>;
defm : PseudoCheriAMOPat<"atomic_load_xor_i8", PseudoCheriAtomicLoadXor8>;
defm : PseudoCheriAMOPat<"atomic_load_max_i8", PseudoCheriAtomicLoadMax8>;
defm : PseudoCheriAMOPat<"atomic_load_min_i8", PseudoCheriAtomicLoadMin8>;
defm : PseudoCheriAMOPat<"atomic_load_umax_i8", PseudoCheriAtomicLoadUMax8>;
defm : PseudoCheriAMOPat<"atomic_load_umin_i8", PseudoCheriAtomicLoadUMin8>;
defm : PseudoCheriAMOPat<"atomic_load_nand_i8", PseudoCheriAtomicLoadNand8>;

defm : PseudoCheriAMOPat<"atomic_swap_i16", PseudoCheriAtomicSwap16>;
defm : PseudoCheriAMOPat<"atomic_load_add_i16", PseudoCheriAtomicLoadAdd16>;
defm : PseudoCheriAMOPat<"atomic_load_sub_i16", PseudoCheriAtomicLoadSub16>;
defm : PseudoCheriAMOPat<"atomic_load_and_i16", PseudoCheriAtomicLoadAnd16>;
defm : PseudoCheriAMOPat<"atomic_load_or_i16", PseudoCheriAtomicLoadOr16>;
defm : PseudoCheriAMOPat<"atomic_load_xor_i16", PseudoCheriAtomicLoadXor16>;
defm : PseudoCheriAMOPat<"atomic_load_max_i16", PseudoCheriAtomicLoadMax16>;
defm : PseudoCheriAMOPat<"atomic_load_min_i16", PseudoCheriAtomicLoadMin16>;
defm : PseudoCheriAMOPat<"atomic_load_umax_i16", PseudoCheriAtomicLoadUMax16>;
defm : PseudoCheriAMOPat<"atomic_load_umin_i16", PseudoCheriAtomicLoadUMin16>;
defm : PseudoCheriAMOPat<"atomic_load_nand_i16", PseudoCheriAtomicLoadNand16>;

defm : PseudoCheriAMOPat<"atomic_load_nand_i32", PseudoCheriAtomicLoadNand32>;

defm : PseudoCheriAMOPat<"atomic_load_add_cap", PseudoCheriAtomicLoadAddCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_sub_cap", PseudoCheriAtomicLoadSubCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_and_cap", PseudoCheriAtomicLoadAndCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_or_cap", PseudoCheriAtomicLoadOrCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_xor_cap", PseudoCheriAtomicLoadXorCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_max_cap", PseudoCheriAtomicLoadMaxCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_min_cap", PseudoCheriAtomicLoadMinCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_umax_cap", PseudoCheriAtomicLoadUMaxCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_umin_cap", PseudoCheriAtomicLoadUMinCap, V9CR, YLenVT>;
defm : PseudoCheriAMOPat<"atomic_load_nand_cap", PseudoCheriAtomicLoadNandCap, V9CR, YLenVT>;

/// Compare and exchange

defm : PseudoCheriCmpXchgPat<"atomic_cmp_swap_i8", PseudoCheriCmpXchg8>;
defm : PseudoCheriCmpXchgPat<"atomic_cmp_swap_i16", PseudoCheriCmpXchg16>;
defm : PseudoCheriCmpXchgPat<"atomic_cmp_swap_i32", PseudoCheriCmpXchg32>;

defm : PseudoCheriCmpXchgPat<"atomic_cmp_swap_cap", PseudoCheriCmpXchgCap, V9CR, YLenVT>;

} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64, IsCapMode] in {

/// 64-bit atomic loads and stores

// Fences will be inserted for atomic load/stores according to the logic in
// RISCVTargetLowering::{emitLeadingFence,emitTrailingFence}.
defm : CheriLdPat<atomic_load_64, CLD>;
defm : CheriAtomicStPat<atomic_store_64, CSD, GPR, XLenVT>;

/// 64-bit AMOs

defm : CheriAMOPat<"atomic_swap_i64", "CAMOSWAP_D">;
defm : CheriAMOPat<"atomic_load_add_i64", "CAMOADD_D">;
defm : CheriAMOSubPat<"atomic_load_sub_i64", "CAMOADD_D">;
defm : CheriAMOPat<"atomic_load_and_i64", "CAMOAND_D">;
defm : CheriAMOPat<"atomic_load_or_i64", "CAMOOR_D">;
defm : CheriAMOPat<"atomic_load_xor_i64", "CAMOXOR_D">;
defm : CheriAMOPat<"atomic_load_max_i64", "CAMOMAX_D">;
defm : CheriAMOPat<"atomic_load_min_i64", "CAMOMIN_D">;
defm : CheriAMOPat<"atomic_load_umax_i64", "CAMOMAXU_D">;
defm : CheriAMOPat<"atomic_load_umin_i64", "CAMOMINU_D">;

/// 64-bit pseudo AMOs

defm : PseudoCheriAMOPat<"atomic_load_nand_i64", PseudoCheriAtomicLoadNand64>;

/// 64-bit compare and exchange

defm : PseudoCheriCmpXchgPat<"atomic_cmp_swap_i64", PseudoCheriCmpXchg64>;

} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtA, IsRV64, IsCapMode]

let Predicates = [HasCheri, HasStdExtA, IsRV32, IsCapMode] in {
defm : CheriLdPat<atomic_load_cap, CLC_64, YLenVT>;
defm : CheriAtomicStPat<atomic_store_cap, CSC_64, V9CR, YLenVT>;
defm : CheriAMOCapPat<"64", "atomic_swap_cap", "CAMOSWAP_C">;
} // Predicates = [HasCheri, HasStdExtA, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasStdExtA, IsRV64, IsCapMode] in {
defm : CheriLdPat<atomic_load_cap, CLC_128, YLenVT>;
defm : CheriAtomicStPat<atomic_store_cap, CSC_128, V9CR, YLenVT>;
defm : CheriAMOCapPat<"128", "atomic_swap_cap", "CAMOSWAP_C">;
} // Predicates = [HasCheri, HasStdExtA, IsRV64, IsCapMode]

/// 'F' (Single-Precision Floating-Point) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtF, IsCapMode] in {

/// Loads

defm : CheriLdPat<load, CFLW, f32>;

/// Stores

defm : CheriStPat<store, CFSW, FPR32, f32>;

} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtF, IsCapMode]

/// 'D' (Single-Precision Floating-Point) extension

let Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsCapMode] in {

/// Loads

defm : CheriLdPat<load, CFLD, f64>;

/// Stores

defm : CheriStPat<store, CFSD, FPR64, f64>;

} // Predicates = [HasZCheriPurecapOrCheri, HasStdExtD, IsCapMode]

/// 'XCheri' extension

let Predicates = [HasCheri, IsRV32, IsCapMode] in {
defm : CheriLdPat<load, CLC_64, YLenVT>;
defm : CheriStPat<store, CSC_64, V9CR, YLenVT>;
} // Predicates = [HasCheri, IsRV32, IsCapMode]

let Predicates = [HasCheri, IsRV64, IsCapMode] in {
defm : CheriLdPat<load, CLC_128, YLenVT>;
defm : CheriStPat<store, CSC_128, V9CR, YLenVT>;
} // Predicates = [HasCheri, IsRV64, IsCapMode]

//===----------------------------------------------------------------------===//
// Compress Instruction tablegen backend.
//===----------------------------------------------------------------------===//

// Quadrant 0
let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CIncOffsetImm V9CRC:$rd, V9CSP:$rs1, uimm10_lsb00nonzero:$imm),
                  (C_CIncOffsetImm4CSPN V9CRC:$rd, V9CSP:$rs1, uimm10_lsb00nonzero:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in {
def : CompressPat<(CFLD FPR64C:$rd, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CFLD FPR64C:$rd, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CLC_128 V9CRC:$rd, GPCRCMem:$rs1, uimm9_lsb0000:$imm),
                  (C_CLC_128 V9CRC:$rd, GPCRCMem:$rs1, uimm9_lsb0000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CLW GPRC:$rd, RVYCompatGPCRCMem:$rs1, uimm7_lsb00:$imm),
                  (C_CLW GPRC:$rd, RVYCompatGPCRCMem:$rs1, uimm7_lsb00:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : CompressPat<(CLC_64 V9CRC:$rd, GPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CLC_64 V9CRC:$rd, GPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CLD GPRC:$rd, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CLD GPRC:$rd, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in {
def : CompressPat<(CFSD FPR64C:$rs2, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CFSD FPR64C:$rs2, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CSC_128 V9CRC:$rs2, GPCRCMem:$rs1, uimm9_lsb0000:$imm),
                  (C_CSC_128 V9CRC:$rs2, GPCRCMem:$rs1, uimm9_lsb0000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CSW GPRC:$rs2, RVYCompatGPCRCMem:$rs1, uimm7_lsb00:$imm),
                  (C_CSW GPRC:$rs2, RVYCompatGPCRCMem:$rs1, uimm7_lsb00:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : CompressPat<(CSC_64 V9CRC:$rs2, GPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CSC_64 V9CRC:$rs2, GPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CSD GPRC:$rs2, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm),
                  (C_CSD GPRC:$rs2, RVYCompatGPCRCMem:$rs1, uimm8_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

// Quadrant 1
let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : CompressPat<(CJAL X1_Y, simm12_lsb0:$offset),
                  (C_CJAL simm12_lsb0:$offset)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CIncOffsetImm X2_Y, X2_Y, simm10_lsb0000nonzero:$imm),
                  (C_CIncOffsetImm16CSP X2_Y, simm10_lsb0000nonzero:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CJAL X0_Y, simm12_lsb0:$offset),
                  (C_J simm12_lsb0:$offset)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

// Quadrant 2
let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in {
def : CompressPat<(CFLD FPR64:$rd, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CFLDCSP FPR64:$rd, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CLC_128 V9CRNoC0:$rd, CSPMem:$rs1, uimm10_lsb0000:$imm),
                  (C_CLCCSP_128 V9CRNoC0:$rd, CSPMem:$rs1, uimm10_lsb0000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CLW GPRNoX0:$rd, RVYCompatCSPMem:$rs1,  uimm8_lsb00:$imm),
                  (C_CLWCSP GPRNoX0:$rd, RVYCompatCSPMem:$rs1, uimm8_lsb00:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : CompressPat<(CLC_64 V9CRNoC0:$rd, CSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CLCCSP_64 V9CRNoC0:$rd, CSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CLD GPRNoX0:$rd, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CLDCSP GPRNoX0:$rd, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CJALR X0_Y, V9CRNoC0:$rs1, 0),
                  (C_CJR V9CRNoC0:$rs1)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CJALR X1_Y, V9CRNoC0:$rs1, 0),
                  (C_CJALR V9CRNoC0:$rs1)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode] in {
def : CompressPat<(CFSD FPR64:$rs2, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CFSDCSP FPR64:$rs2, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, HasStdExtD, IsRV32, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CSC_128 V9CR:$rs2, CSPMem:$rs1, uimm10_lsb0000:$imm),
                  (C_CSCCSP_128 V9CR:$rs2, CSPMem:$rs1, uimm10_lsb0000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode] in {
def : CompressPat<(CSW GPR:$rs2, RVYCompatCSPMem:$rs1, uimm8_lsb00:$imm),
                  (C_CSWCSP GPR:$rs2, RVYCompatCSPMem:$rs1, uimm8_lsb00:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsCapMode]

let Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode] in {
def : CompressPat<(CSC_64 V9CR:$rs2, CSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CSCCSP_64 V9CR:$rs2, CSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasCheri, HasCheriRVC, HasStdExtC, IsRV32, IsCapMode]

let Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode] in {
def : CompressPat<(CSD GPR:$rs2, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm),
                  (C_CSDCSP GPR:$rs2, RVYCompatCSPMem:$rs1, uimm9_lsb000:$imm)>;
} // Predicates = [HasZCheriPurecapOrCheri, HasCheriRVC, HasStdExtC, IsRV64, IsCapMode]


//===----------------------------------------------------------------------===//
// RISCV CHERI Zba extension
//===----------------------------------------------------------------------===//

let DecoderNamespace = "CapModeOnly_" in {

let Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsCapMode] in {
def C_SH1ADD : C_ALU_rr<0b0010000, 0b010, "sh1add">,
             Sched<[WriteSHXADD, ReadSHXADD, ReadSHXADD]>;
def C_SH2ADD : C_ALU_rr<0b0010000, 0b100, "sh2add">,
             Sched<[WriteSHXADD, ReadSHXADD, ReadSHXADD]>;
def C_SH3ADD : C_ALU_rr<0b0010000, 0b110, "sh3add">,
             Sched<[WriteSHXADD, ReadSHXADD, ReadSHXADD]>;
} // Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsCapMode]

let Predicates = [HasStdExtZba, IsRV64, HasZCheriPurecapOrCheri, IsCapMode] in {
def C_SH1ADD_UW : C_ALUW_rr<0b0010000, 0b010, "sh1add.uw">,
                  Sched<[WriteSHXADD32, ReadSHXADD32, ReadSHXADD32]>;
def C_SH2ADD_UW : C_ALUW_rr<0b0010000, 0b100, "sh2add.uw">,
                  Sched<[WriteSHXADD32, ReadSHXADD32, ReadSHXADD32]>;
def C_SH3ADD_UW : C_ALUW_rr<0b0010000, 0b110, "sh3add.uw">,
                  Sched<[WriteSHXADD32, ReadSHXADD32, ReadSHXADD32]>;
} // Predicates = [HasStdExtZba, IsRV64, HasZCheriPurecapOrCheri, IsCapMode]


} // DecoderNamespace = "CapModeOnly_"


let Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsCapMode] in {

foreach i = {1,2,3} in {
  defvar shxadd = !cast<Instruction>("C_SH"#i#"ADD");
  def : Pat<(cptradd V9CR:$rs2, (shl (XLenVT GPR:$rs1), (XLenVT i))),
            (shxadd GPR:$rs1, V9CR:$rs2)>;
  def : Pat<(XLenVT (add_like_non_imm12 (shl GPR:$rs1, (XLenVT i)), GPR:$rs2)),
            (XLenVT (EXTRACT_SUBREG (shxadd GPR:$rs1, (SUBREG_TO_REG V9CR, $rs2, sub_cap_addr)), sub_cap_addr))>;
  def : Pat<(XLenVT (riscv_shl_add GPR:$rs1, (XLenVT i), GPR:$rs2)),
            (XLenVT (EXTRACT_SUBREG (shxadd GPR:$rs1, (SUBREG_TO_REG V9CR, $rs2, sub_cap_addr)), sub_cap_addr))>;

  // TODO - handle more complex patterns
}

multiclass ZbaMultPat<int n, RVInst First, RVInst Second> {
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT n)), GPR:$rs2),
          (XLenVT (EXTRACT_SUBREG
            (First
              (XLenVT (EXTRACT_SUBREG (Second GPR:$rs1, (SUBREG_TO_REG V9CR, $rs1, sub_cap_addr)), sub_cap_addr)),
              (SUBREG_TO_REG V9CR, $rs2, sub_cap_addr)
            ),
          sub_cap_addr))>;
def : Pat<(cptradd V9CR:$rs2, (mul_oneuse GPR:$rs1, (XLenVT n))),
          (First (XLenVT (EXTRACT_SUBREG (Second GPR:$rs1, (SUBREG_TO_REG V9CR, $rs1, sub_cap_addr)), sub_cap_addr)), V9CR:$rs2)
         >;
}
defm : ZbaMultPat<6,  C_SH1ADD, C_SH1ADD>;
defm : ZbaMultPat<10, C_SH1ADD, C_SH2ADD>;
defm : ZbaMultPat<18, C_SH1ADD, C_SH3ADD>;
defm : ZbaMultPat<12, C_SH2ADD, C_SH1ADD>;
defm : ZbaMultPat<20, C_SH2ADD, C_SH2ADD>;
defm : ZbaMultPat<36, C_SH2ADD, C_SH3ADD>;
defm : ZbaMultPat<24, C_SH3ADD, C_SH1ADD>;
defm : ZbaMultPat<40, C_SH3ADD, C_SH2ADD>;
defm : ZbaMultPat<72, C_SH3ADD, C_SH3ADD>;

} // Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsCapMode]

let Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsRV64, IsCapMode] in {
def : Pat<(cptradd V9CR:$rs2, (shl (and (XLenVT GPR:$rs1), 0xFFFFFFFF), (i64 1))),
          (C_SH1ADD_UW GPR:$rs1, V9CR:$rs2)>;
def : Pat<(cptradd V9CR:$rs2, (shl (and (XLenVT GPR:$rs1), 0xFFFFFFFF), (i64 2))),
          (C_SH2ADD_UW GPR:$rs1, V9CR:$rs2)>;
def : Pat<(cptradd V9CR:$rs2, (shl (and (XLenVT GPR:$rs1), 0xFFFFFFFF), (i64 3))),
          (C_SH3ADD_UW GPR:$rs1, V9CR:$rs2)>;
} // Predicates = [HasStdExtZba, HasZCheriPurecapOrCheri, IsRV64, IsCapMode]

//===----------------------------------------------------------------------===//
// Zish4add
//===----------------------------------------------------------------------===//
//
// Instructions
let Predicates = [HasStdExtZish4add, IsRV64, IsCapMode], DecoderNamespace = "CapModeOnly_" in {
def C_SH4ADD : C_ALU_rr<0b0010000, 0b111, "sh4add">,
               Sched<[WriteSHXADD, ReadSHXADD, ReadSHXADD]>;
}

let Predicates = [HasStdExtZish4add, IsRV64, NotCapMode] in {
def SH4ADD   : ALU_rr<0b0010000, 0b111, "sh4add">,
               Sched<[WriteSHXADD, ReadSHXADD, ReadSHXADD]>;
}

// Codegen patterns

let Predicates = [HasStdExtZish4add, IsRV64, NotCapMode] in {
def : Pat<(XLenVT (add_non_imm12 (shl GPR:$rs1, (XLenVT 4)), GPR:$rs2)),
          (SH4ADD GPR:$rs1, GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 272)), GPR:$rs2),
          (SH4ADD (SH4ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;

}

let Predicates = [HasStdExtZish4add, HasStdExtZba, NotCapMode, IsRV64] in {
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 34)), GPR:$rs2),
          (SH1ADD (SH4ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 68)), GPR:$rs2),
          (SH2ADD (SH4ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 136)), GPR:$rs2),
          (SH3ADD (SH4ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 48)), GPR:$rs2),
          (SH4ADD (SH1ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 80)), GPR:$rs2),
          (SH4ADD (SH2ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
def : Pat<(add (mul_oneuse GPR:$rs1, (XLenVT 144)), GPR:$rs2),
          (SH4ADD (SH3ADD GPR:$rs1, GPR:$rs1), GPR:$rs2)>;
}

let Predicates = [HasStdExtZish4add, IsRV64, IsCapMode] in {
def : Pat<(cptradd V9CR:$rs2, (shl (XLenVT GPR:$rs1), (XLenVT 4))),
          (C_SH4ADD GPR:$rs1, V9CR:$rs2)>;
def : Pat<(XLenVT (add_non_imm12 (shl GPR:$rs1, (XLenVT 4)), GPR:$rs2)),
          (XLenVT (EXTRACT_SUBREG (C_SH4ADD GPR:$rs1, (SUBREG_TO_REG V9CR, $rs2, sub_cap_addr)), sub_cap_addr))>;
defm : ZbaMultPat<272, C_SH4ADD, C_SH4ADD>;
}

let Predicates = [HasStdExtZish4add, HasStdExtZba, IsCapMode, IsRV64] in {
defm : ZbaMultPat<34 , C_SH1ADD, C_SH4ADD>;
defm : ZbaMultPat<68 , C_SH2ADD, C_SH4ADD>;
defm : ZbaMultPat<136, C_SH3ADD, C_SH4ADD>;
defm : ZbaMultPat<48 , C_SH4ADD, C_SH1ADD>;
defm : ZbaMultPat<80 , C_SH4ADD, C_SH2ADD>;
defm : ZbaMultPat<144, C_SH4ADD, C_SH3ADD>;
}
