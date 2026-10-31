// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_gowin_hdmi_pll.h for the primary calling header

#include "Vtb_gowin_hdmi_pll__pch.h"

void Vtb_gowin_hdmi_pll___024root___timing_ready(Vtb_gowin_hdmi_pll___024root* vlSelf);

VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___eval_static(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_static\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    {
        // Inlined CFunc: _eval_static__TOP
        vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m = 0U;
        vlSelfRef.tb_gowin_hdmi_pll__DOT__reset = 1U;
        vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m = 0U;
        vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked = 0U;
        vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter = 0U;
    }
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0 = 0U;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__reset__0 = 1U;
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0 = 0U;
    Vtb_gowin_hdmi_pll___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___eval_final(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_final\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___eval_settle(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_settle\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

bool Vtb_gowin_hdmi_pll___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vtb_gowin_hdmi_pll___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge tb_gowin_hdmi_pll.clk_27m)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(posedge tb_gowin_hdmi_pll.reset)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @(negedge tb_gowin_hdmi_pll.clk_27m)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 3U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 3 is active: @(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 4U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 4 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___ctor_var_reset(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___ctor_var_reset\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__reset__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
