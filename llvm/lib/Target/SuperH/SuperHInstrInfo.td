//===-- SuperHInstrInfo.td -------------------------------------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//

include "SuperHInstrFormats.td"

//===----------------------------------------------------------------------===//
// Describe constraints
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Describe LLVM IR constraints
//===----------------------------------------------------------------------===//

def i32immSExt8 : ImmLeaf<i32, [{ return isInt<8>(Imm); }]>;

def SuperHCallTarget : Operand<i32>;

def SuperHBRATarget : Operand<OtherVT>;

def SuperHMemOperand : Operand<i32> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops GPR, i32imm);
}

def SuperHPCMemOperand : Operand<i32> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops PCR, i32imm);
}

// Operand for CONSTPOOL_ENTRY pseudo-instruction.
def SuperHCPInstOperand : Operand<i32>;

def SuperHMemPattern8 : ComplexPattern<i32, 2, "SelectAddr<8>", [], []>;
def SuperHMemPattern16 : ComplexPattern<i32, 2, "SelectAddr<16>", [], []>;
def SuperHMemPattern32 : ComplexPattern<i32, 2, "SelectAddr<32>", [], []>;

//===----------------------------------------------------------------------===//
// Describe profiles and nodes
//===----------------------------------------------------------------------===//

def SuperHRet : SDNode<"SuperHISD::Ret", SDTNone,
                   [ SDNPHasChain, SDNPOptInGlue, SDNPVariadic ]>;

def SDT_SuperHCall : SDTypeProfile<0, -1, [ SDTCisVT<0, iPTR>]>;

def SuperHCall : SDNode<"SuperHISD::Call", SDT_SuperHCall,
    [ SDNPHasChain, SDNPOutGlue, SDNPOptInGlue, SDNPVariadic ]>;

def SDT_SuperHWrapper : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>, SDTCisPtrTy<0>]>;

def SuperHWrapper : SDNode <"SuperHISD::Wrapper", SDT_SuperHWrapper>;

def SuperHShl : SDNode <"SuperHISD::SHL", SDTIntShiftOp>;

def SuperHSrl : SDNode <"SuperHISD::SRL", SDTIntShiftOp>;

//===----------------------------------------------------------------------===//
// Describe instructions
//===----------------------------------------------------------------------===//

// FIXME: Fix itineraries.

def NOP : FZERO<0x9, (outs), (ins), "nop", [], NoItinerary>;

let hasSideEffects = 0, isNotDuplicable = 1 in
def CONSTPOOL_ENTRY : Pseudo<(outs),
                             (ins SuperHCPInstOperand:$id, SuperHCPInstOperand:$idx,
                              i32imm:$size),
                             "cpi", [], NoItinerary>;

let isReturn = 1, isTerminator = 1, hasDelaySlot = 1, Uses = [ PR ] in {
  def RTS : FZERO<0xB, (outs), (ins), "rts", [ (SuperHRet) ], NoItinerary>;
}

let isCall = 1, hasDelaySlot = 1, Defs = [ R0, PR ]  in {
def JSR : FM<0x4, 0xB, (outs), (ins GPR:$rm),
             "jsr\t$rm", [ (SuperHCall GPR:$rm) ], NoItinerary>;

def BSR : FD12<0xB, (outs), (ins SuperHCallTarget:$disp),
               "bsr\t$disp", [ (SuperHCall tglobaladdr:$disp) ], NoItinerary>;
}

let isBranch = 1, isTerminator = 1, hasDelaySlot = 1 in {
def BRA : FD12<0xA, (outs), (ins SuperHBRATarget:$disp),
               "bra\t$disp", [ (br bb:$disp) ],
               NoItinerary>;

let Uses = [ SR ] in {
def BT : FD<0x89, (outs), (ins SuperHBRATarget:$disp),
            "bt\t$disp", [ (brcond SR, bb:$disp) ],
            NoItinerary>;
}
}

let usesCustomInserter = 1 in {
  def MOV32ir : Pseudo<(outs GPR:$rn), (ins i32imm:$imm),
                       "mov\t$imm, r0", [ (set i32:$rn, imm:$imm) ],
                       NoItinerary>;
}

def MOV8ri : FNI<0xE, (outs GPR:$rn), (ins i32imm:$imm),
                 "mov\t$imm, $rn", [ (set i32:$rn, i32immSExt8:$imm) ],
                 NoItinerary>;

def MOV32rr : FNM<0x6, 0x3, (outs GPR:$rn), (ins GPR:$rm),
                  "mov\t$rm, $rn", [], NoItinerary>;

let mayLoad = 1 in {
def MOV8mr : FNM<0x6, 0x0, (outs GPR:$rn), (ins GPR:$rm),
                 "mov.b\t@$rm, $rn",
                 [ (set i32:$rn, (sextloadi8 i32:$rm)) ], NoItinerary>;
def MOV16mr : FNM<0x6, 0x1, (outs GPR:$rn), (ins GPR:$rm),
                  "mov.w\t@$rm, $rn",
                  [ (set i32:$rn, (sextloadi16 i32:$rm)) ], NoItinerary>;
def MOV32mr : FNM<0x6, 0x2, (outs GPR:$rn), (ins GPR:$rm),
                  "mov.l\t@$rm, $rn",
                  [ (set i32:$rn, (load i32:$rm)) ], NoItinerary>;

let Constraints = "$rn = $rnsrc" in {
def MOV32rmpush : FNM<0x2, 0x6, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
                     "mov.l\t$rm, @-$rn",
                     [], NoItinerary>;
}
}

let mayStore = 1 in {
def MOV8rm : FNM<0x2, 0x0, (outs), (ins GPR:$rm, GPR:$rn),
                 "mov.b\t$rm, @$rn",
                 [ (truncstorei8 i32:$rm, i32:$rn) ], NoItinerary>;
def MOV16rm : FNM<0x2, 0x1, (outs), (ins GPR:$rm, GPR:$rn),
                  "mov.w\t$rm, @$rn",
                  [ (truncstorei16 i32:$rm, i32:$rn) ], NoItinerary>;
def MOV32rm : FNM<0x2, 0x2, (outs), (ins GPR:$rm, GPR:$rn),
                  "mov.l\t$rm, @$rn",
                  [ (store i32:$rm, i32:$rn) ], NoItinerary>;

let Constraints = "$rm = $rmsrc" in {
def MOV32mrpop : FNM<0x6, 0x6, (outs GPR:$rn, GPR:$rm), (ins GPR:$rmsrc),
                      "mov.l\t@${rm}+, $rn",
                      [], NoItinerary>;
}
}

let Constraints = "$rn = $rnsrc" in {
let isCommutable = 1, isAdd = 1 in {
def ADDrr : FNM<0x3, 0xC, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
                "add\t$rm, $rn",
                [ (set i32:$rn, (add i32:$rm, i32:$rnsrc)) ],
                NoItinerary>;

def ADDri : FNI<0x7, (outs GPR:$rn), (ins GPR:$rnsrc, i32imm:$imm),
                "add\t$imm, $rn",
                [ (set i32:$rn, (add i32:$rnsrc, i32immSExt8:$imm)) ],
                NoItinerary>;
}

def SUBrr : FNM<0x3, 0xB, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
                "sub\t$rm, $rn",
                [ (set i32:$rn, (sub i32:$rm, i32:$rnsrc)) ],
                NoItinerary>;

def ANDrr : FNM<0x2, 0x9, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
                "and\t$rm, $rn",
                [ (set i32:$rn, (and i32:$rm, i32:$rnsrc)) ],
                NoItinerary>;

def ORrr : FNM<0x2, 0xB, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
               "or\t$rm, $rn",
               [ (set i32:$rn, (or i32:$rm, i32:$rnsrc)) ],
               NoItinerary>;

def XORrr : FNM<0x2, 0xA, (outs GPR:$rn), (ins GPR:$rm, GPR:$rnsrc),
                "xor\t$rm, $rn",
                [ (set i32:$rn, (xor i32:$rm, i32:$rnsrc)) ],
                NoItinerary>;

let Defs = [ SR ] in {
def SHAL : FN<0x4, 0x20, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shal\t$rn",
              [ (set GPR:$rn, (SuperHShl GPR:$rnsrc, (i32 1))) ],
              NoItinerary>;

def SHAR : FN<0x4, 0x21, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shar\t$rn",
              [ (set i32:$rn, (sra i32:$rnsrc, (i32 1))) ],
              NoItinerary>;

def SHLR : FN<0x4, 0x1, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shlr\t$rn",
              [ (set i32:$rn, (SuperHSrl i32:$rnsrc, (i32 1))) ],
              NoItinerary>;
}

def SHLL2 : FN<0x4, 0x8, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shll2\t$rn",
              [ (set i32:$rn, (SuperHShl i32:$rnsrc, (i32 2))) ],
              NoItinerary>;

def SHLL8 : FN<0x4, 0x18, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shll8\t$rn",
              [ (set i32:$rn, (SuperHShl i32:$rnsrc, (i32 8))) ],
              NoItinerary>;

def SHLL16 : FN<0x4, 0x28, (outs GPR:$rn), (ins GPR:$rnsrc),
               "shll16\t$rn",
               [ (set i32:$rn, (SuperHShl i32:$rnsrc, (i32 16))) ],
               NoItinerary>;

def SHLR2 : FN<0x4, 0x9, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shlr2\t$rn",
              [ (set i32:$rn, (SuperHSrl i32:$rnsrc, (i32 2))) ],
              NoItinerary>;

def SHLR8 : FN<0x4, 0x19, (outs GPR:$rn), (ins GPR:$rnsrc),
              "shlr8\t$rn",
              [ (set i32:$rn, (SuperHSrl i32:$rnsrc, (i32 8))) ],
              NoItinerary>;

def SHLR16 : FN<0x4, 0x29, (outs GPR:$rn), (ins GPR:$rnsrc),
               "shlr16\t$rn",
               [ (set i32:$rn, (SuperHSrl i32:$rnsrc, (i32 16))) ],
               NoItinerary>;
}

def : Pat<(i32 (SuperHSrl i32:$rn, (i32 0))), (i32 $rn)>;

def : Pat<(i32 (SuperHShl i32:$rn, (i32 0))), (i32 $rn)>;

let Defs = [ R0 ], Uses = [ R0 ] in {
def ANDri : FI<0xC8, (outs), (ins i32imm:$imm),
               "and\t$imm, r0",
               [ (set R0, (and R0, i32immSExt8:$imm)) ],
               NoItinerary>;
def ORri : FI<0xCB, (outs), (ins i32imm:$imm),
              "or\t$imm, r0",
              [ (set R0, (or R0, i32immSExt8:$imm)) ],
              NoItinerary>;
def XORri : FI<0xCA, (outs), (ins i32imm:$imm),
              "xor\t$imm, r0",
              [ (set R0, (xor R0, i32immSExt8:$imm)) ],
              NoItinerary>;
}

let Defs = [ MAC ] in {
def CLRMAC : FZERO<0x28, (outs), (ins),
                   "clrmac",
                   [ (set MAC, (i64 0)) ],
                   NoItinerary>;
}

class ST<string type, bits<8> data, string regname, Register reg>
  : FN<0x0, data, (outs GPR:$rn), (ins),
       "st"#type#"\t"#regname#", $rn", [], NoItinerary> {
         let Defs = [ reg ];
}

class LD<string type, bits<8> data, string regname, Register reg>
  : FN<0x4, data, (outs), (ins GPR:$rn),
       "ld"#type#"\t$rn, "#regname, [], NoItinerary> {
         let Uses = [ reg ];
}

// Multiply and accumulate high
def STSMACH : ST<"s", 0xA, "mach", MACH>;
def LDSMACH : LD<"s", 0xA, "mach", MACH>;

// Multiply and accumulate low
def STSMACL : ST<"s", 0x1A, "macl", MACL>;
def LDSMACL : LD<"s", 0x1A, "macl", MACL>;

// Procedure Register
def STSPR : ST<"s", 0x2A, "pr", PR>;
def LDSPR : LD<"s", 0x2A, "pr", PR>;

// Program Counter????

// Status Register
// STC SR, Rn: 0000 nnnn 0000 0010
def STCSR : ST<"c", 0x02, "sr", SR>;
// LDC Rm, SR: 0100 mmmm 0000 1110
def LDCSR : LD<"c", 0x0E, "sr", SR>;

// Global Base Register
// STC GBR, Rn: 0000 nnnn 0001 0010
def STCGBR : ST<"c", 0x12, "gbr", GBR>;
// LDC Rm, GBR: 0100 mmmm 0001 1110
def LDCGBR : LD<"c", 0x1E, "gbr", GBR>;

// Vector Base Register
// STC VBR, Rn: 0000 nnnn 0010 0010
def STCVBR : ST<"c", 0x22, "vbr", VBR>;
// LDC Rm, VBR: 0100 mmmm 0010 1110
def LDCVBR : LD<"c", 0x2E, "vbr", VBR>;

let mayLoad = 1 in {
let Defs = [ R0 ] in {
def MOV8mr0 : FMD<0x84, (outs), (ins GPR:$rm, i32imm:$disp),
                  "mov.b\t@($disp, $rm), r0",
                  [ (set R0, (sextloadi8 (SuperHMemPattern8 GPR:$rm, i32imm:$disp))) ],
                  NoItinerary>;
def MOV16mr0 : FMD<0x85, (outs), (ins GPR:$rm, i32imm:$disp),
                  "mov.w\t@($disp, $rm), r0",
                  [ (set R0, (sextloadi16 (SuperHMemPattern16 GPR:$rm, i32imm:$disp))) ],
                  NoItinerary>;
}

def MOV32mrd : FNMD<0x5, (outs GPR:$rn), (ins GPR:$rm, i32imm:$disp),
                    "mov.l\t@($disp, $rm), $rn",
                    [ (set i32:$rn, (load (SuperHMemPattern32 GPR:$rm, i32imm:$disp))) ],
                    NoItinerary>;
}

let mayStore = 1 in {
let Uses = [ R0 ] in {
def MOV8r0m : FMD<0x80, (outs), (ins GPR:$rm, i32imm:$disp),
                   "mov.b\tr0, @($disp, $rm)",
                   [ (truncstorei8 R0, (SuperHMemPattern8 GPR:$rm, i32imm:$disp)) ],
                   NoItinerary>;
def MOV16r0m : FMD<0x81, (outs), (ins GPR:$rm, i32imm:$disp),
                   "mov.w\tr0, @($disp, $rm)",
                   [ (truncstorei16 R0, (SuperHMemPattern16 GPR:$rm, i32imm:$disp)) ],
                   NoItinerary>;
}

// MOV.L Rm, @(disp, Rn): operand order matches FNMD fields rn(base), disp, rm(data)
def MOV32rmd : FNMD<0x1, (outs), (ins GPR:$rn, i32imm:$disp, GPR:$rm),
                    "mov.l\t$rm, @($disp, $rn)",
                    [ (store i32:$rm, (SuperHMemPattern32 GPR:$rn, i32imm:$disp)) ],
                    NoItinerary>;
}

let isCommutable = 1 in {
let Defs = [ MACL ] in {
def MULrr : FNM<0x0, 0x7, (outs), (ins GPR:$rm, GPR:$rn),
                "mul.l\t$rm, $rn",
                [ (set MACL, (mul i32:$rm, i32:$rn)) ],
                NoItinerary>;
}

let Uses = [ R0 ] in {
def MULrr0 : FN<0x4, 0x80, (outs GPR:$rn), (ins GPR:$rnsrc),
               "mulr\tr0, $rn",
               [ (set i32:$rn, (mul R0, i32:$rnsrc)) ],
               NoItinerary>;
}
}

def : Pat<(i32 (mulhu i32:$rm, i32:$rn)),
          (i32 (MULrr i32:$rm, i32:$rn))>;


let Uses = [ PC ] in {
def MOV32PCR : FND8<0xD, (outs GPR:$rn), (ins i32imm:$disp),
                    "mov.l\t@($disp, pc), $rn",
                    [],
                    NoItinerary>;
}

def : Pat<(load (SuperHWrapper tconstpool:$src)), (MOV32PCR tconstpool:$src)>;

def : Pat<(SuperHWrapper tglobaladdr:$src), (MOV32PCR tconstpool:$src)>;

// Memory load/store patterns are embedded in instruction definitions above.

let isCompare = 1, Defs = [ SR ] in { // Sets the T bit
class CMP<bits<4> op, bits<4> data, string asmstr, CondCode CC>
    : FNM<op, data, (outs), (ins GPR:$rm, GPR:$rn), asmstr,
      [ (set SR, (setcc GPR:$rm, GPR:$rn, CC)) ], NoItinerary> {}

def CMPEQrr : CMP<0x3, 0x0, "cmp/eq\t$rm, $rn", SETEQ>;
def CMPHSrr : CMP<0x3, 0x2, "cmp/hs\t$rm, $rn", SETGE>;
def CMPGErr : CMP<0x3, 0x3, "cmp/ge\t$rm, $rn", SETUGE>;
def CMPHIrr : CMP<0x3, 0x6, "cmp/hi\t$rm, $rn", SETULE>;
def CMPGTrr : CMP<0x3, 0x7, "cmp/gt\t$rm, $rn", SETGT>;

def CMPPLrz : FN<0x4, 0x15, (outs), (ins GPR:$rn),
                 "cmp/pl\t$rn",
                 [ (set SR, (setcc GPR:$rn, (i32 0), SETGT)) ], NoItinerary>;

def CMPPZrz : FN<0x4, 0x11, (outs), (ins GPR:$rn),
                 "cmp/pz\t$rn",
                 [ (set SR, (setcc GPR:$rn, (i32 0), SETGE)) ], NoItinerary>;

let Uses = [ R0 ] in {
def CMPEQRi : FI<0x88, (outs), (ins i32imm:$imm),
                 "cmp/eq\t$imm, r0",
                 [ (set SR, (setcc R0, i32immSExt8:$imm, SETEQ)) ],
                 NoItinerary>;
}
}

// SuperH does not support `a < b` cmp. `a < b` <=> `b >= a`
def : Pat<(setcc (i32 GPR:$rm), (i32 GPR:$rn), SETLT),
          (CMPGErr $rn, $rm)>;

// SuperH does not support `a u< b` cmp. `a u< b` <=> `b u>= a`
def : Pat<(setcc (i32 GPR:$rm), (i32 GPR:$rn), SETULT),
          (CMPGErr $rn, $rm)>;

// SuperH does not support `a u< b` cmp. `a u< b` <=> `b u>= a`
def : Pat<(setcc (i32 GPR:$rm), (i32 GPR:$rn), SETUGT),
          (CMPHIrr $rn, $rm)>;

// SuperH does not support `a <= b` cmp. `a <= b` <=> `b > a`
def : Pat<(setcc (i32 GPR:$rm), (i32 GPR:$rn), SETLE),
          (CMPGTrr $rn, $rm)>;

def SWAP16rr : FNM<0x6, 0x8, (outs GPR:$rn), (ins GPR:$rm),
                  "swap.b\t$rm, $rn",
                  [ (set i32:$rn, (rotr (bswap i32:$rm), (i32 16))) ],
                  NoItinerary>;

def SWAP32rr : FNM<0x6, 0x9, (outs GPR:$rn), (ins GPR:$rm),
                  "swap.l\t$rm, $rn",
                  [ (set i32:$rn, (bswap i32:$rm)) ],
                  NoItinerary>;
