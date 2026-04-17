//=====-- OR1KMCAsmInfo.h - OR1K asm properties -----------*- C++ -*--====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the OR1KMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef OR1K_MCASM_INFO_H
#define OR1K_MCASM_INFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
class Triple;
class MCSpecifierExpr;
class raw_ostream;

class OR1KMCAsmInfo : public MCAsmInfoELF {
  virtual void anchor();
public:
  explicit OR1KMCAsmInfo(const Triple &TT);
  void printSpecifierExpr(raw_ostream &OS,
                          const MCSpecifierExpr &Expr) const override;
};

namespace OR1K {
using Specifier = uint16_t;
enum {
  S_None = 0,
  S_ABS_HI,
  S_ABS_LO,
  S_PLT,
  S_GOTPCHI,
  S_GOTPCLO,
  S_GOTOFFHI,
  S_GOTOFFLO,
  S_GOT,
};
} // namespace OR1K

} // namespace llvm

#endif
