// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_gowin_hdmi_pll.h for the primary calling header

#ifndef VERILATED_VTB_GOWIN_HDMI_PLL___024ROOT_H_
#define VERILATED_VTB_GOWIN_HDMI_PLL___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vtb_gowin_hdmi_pll__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_gowin_hdmi_pll___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_gowin_hdmi_pll__DOT__clk_27m;
    CData/*0:0*/ tb_gowin_hdmi_pll__DOT__reset;
    CData/*0:0*/ tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m;
    CData/*0:0*/ tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked;
    CData/*3:0*/ tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__reset__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h232e443d__0;
    VlTriggerScheduler __VtrigSched_h232e43fc__0;
    VlTriggerScheduler __VtrigSched_h9976415a__0;

    // INTERNAL VARIABLES
    Vtb_gowin_hdmi_pll__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vtb_gowin_hdmi_pll___024root(Vtb_gowin_hdmi_pll__Syms* symsp, const char* namep);
    ~Vtb_gowin_hdmi_pll___024root();
    VL_UNCOPYABLE(Vtb_gowin_hdmi_pll___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
