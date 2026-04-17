//===-- OR1KMCAsmInfo.cpp - OR1K asm properties -----------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the OR1KMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "OR1KMCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

void OR1KMCAsmInfo::anchor() { }

void OR1KMCAsmInfo::printSpecifierExpr(raw_ostream &OS,
                                       const MCSpecifierExpr &Expr) const {
  printExpr(OS, *Expr.getSubExpr());
  switch (Expr.getSpecifier()) {
  default: llvm_unreachable("Invalid kind!");
  case OR1K::S_None: break;
  case OR1K::S_ABS_HI:    OS << "@ha"; break;
  case OR1K::S_ABS_LO:    OS << "@lo"; break;
  case OR1K::S_PLT:       OS << "@plt"; break;
  case OR1K::S_GOTPCHI:   OS << "@gotpchi"; break;
  case OR1K::S_GOTPCLO:   OS << "@gotpclo"; break;
  case OR1K::S_GOTOFFHI:  OS << "@gotoffhi"; break;
  case OR1K::S_GOTOFFLO:  OS << "@gotofflo"; break;
  case OR1K::S_GOT:       OS << "@got"; break;
  }
}

OR1KMCAsmInfo::OR1KMCAsmInfo(const Triple &TT) {
  IsLittleEndian              = false;
  PrivateGlobalPrefix         = ".L";
  WeakRefDirective            = "\t.weak\t";
  ExceptionsType              = ExceptionHandling::DwarfCFI;
  DwarfRegNumForCFI           = true;
  SupportsDebugInformation    = true;

  // OR1K assembly requires ".section" before ".bss"
  UsesELFSectionDirectiveForBSS = true;
}
