// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VTB_GOWIN_HDMI_PLL__SYMS_H_
#define VERILATED_VTB_GOWIN_HDMI_PLL__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vtb_gowin_hdmi_pll.h"

// INCLUDE MODULE CLASSES
#include "Vtb_gowin_hdmi_pll___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vtb_gowin_hdmi_pll__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vtb_gowin_hdmi_pll* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vtb_gowin_hdmi_pll___024root   TOP;

    // CONSTRUCTORS
    Vtb_gowin_hdmi_pll__Syms(VerilatedContext* contextp, const char* namep, Vtb_gowin_hdmi_pll* modelp);
    ~Vtb_gowin_hdmi_pll__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
