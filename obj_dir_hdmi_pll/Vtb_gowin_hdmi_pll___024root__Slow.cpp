// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_gowin_hdmi_pll.h for the primary calling header

#include "Vtb_gowin_hdmi_pll__pch.h"

void Vtb_gowin_hdmi_pll___024root___ctor_var_reset(Vtb_gowin_hdmi_pll___024root* vlSelf);

Vtb_gowin_hdmi_pll___024root::Vtb_gowin_hdmi_pll___024root(Vtb_gowin_hdmi_pll__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vtb_gowin_hdmi_pll___024root___ctor_var_reset(this);
}

void Vtb_gowin_hdmi_pll___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vtb_gowin_hdmi_pll___024root::~Vtb_gowin_hdmi_pll___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
