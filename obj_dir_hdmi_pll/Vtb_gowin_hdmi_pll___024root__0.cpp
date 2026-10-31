// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_gowin_hdmi_pll.h for the primary calling header

#include "Vtb_gowin_hdmi_pll__pch.h"

VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__0(Vtb_gowin_hdmi_pll___024root* vlSelf);
VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__1(Vtb_gowin_hdmi_pll___024root* vlSelf);
VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__2(Vtb_gowin_hdmi_pll___024root* vlSelf);

void Vtb_gowin_hdmi_pll___024root___eval_initial(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_initial\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__2(vlSelf);
}

void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription);
void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e43fc__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription);
void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h9976415a__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__0(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    double tb_gowin_hdmi_pll__DOT__start_time;
    tb_gowin_hdmi_pll__DOT__start_time = 0;
    double tb_gowin_hdmi_pll__DOT__end_time;
    tb_gowin_hdmi_pll__DOT__end_time = 0;
    double tb_gowin_hdmi_pll__DOT__measured_period;
    tb_gowin_hdmi_pll__DOT__measured_period = 0;
    IData/*31:0*/ tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0;
    tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0 = 0;
    IData/*31:0*/ tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1;
    tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0;
    IData/*31:0*/ tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2;
    tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2 = 0;
    IData/*31:0*/ tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3;
    tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3 = 0;
    // Body
    VL_WRITEF_NX("------------------------------------\n Gowin HDMI PLL Testbench\n------------------------------------\n",0);
    tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0 = 3U;
    while (VL_LTS_III(32, 0U, tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0)) {
        Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(vlSelf, 
                                                                 "@(posedge tb_gowin_hdmi_pll.clk_27m)");
        co_await vlSelfRef.__VtrigSched_h232e443d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_gowin_hdmi_pll.clk_27m)", 
                                                             "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                             39);
        tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0 
            = (tb_gowin_hdmi_pll__DOT__unnamedblk1_1__DOT____Vrepeat0 
               - (IData)(1U));
    }
    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e43fc__0(vlSelf, 
                                                             "@(negedge tb_gowin_hdmi_pll.clk_27m)");
    co_await vlSelfRef.__VtrigSched_h232e43fc__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(negedge tb_gowin_hdmi_pll.clk_27m)", 
                                                         "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                         40);
    vlSelfRef.tb_gowin_hdmi_pll__DOT__reset = 0U;
    tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1 = 0x00000064U;
    while (VL_LTS_III(32, 0U, tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1)) {
        Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(vlSelf, 
                                                                 "@(posedge tb_gowin_hdmi_pll.clk_27m)");
        co_await vlSelfRef.__VtrigSched_h232e443d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_gowin_hdmi_pll.clk_27m)", 
                                                             "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                             44);
        tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1 
            = (tb_gowin_hdmi_pll__DOT__unnamedblk1_2__DOT____Vrepeat1 
               - (IData)(1U));
    }
    if (VL_UNLIKELY(((1U & (~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked)))))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb_gowin_hdmi_pll.sv:47: Assertion failed in %m: FAIL: PLL did not lock\n",3, 'M',vlSymsp->name(),"tb_gowin_hdmi_pll", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000));
        VL_STOP_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 47, "", false);
    }
    VL_WRITEF_NX("PASS: PLL locked\n",0);
    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(vlSelf, 
                                                             "@(posedge tb_gowin_hdmi_pll.clk_27m)");
    co_await vlSelfRef.__VtrigSched_h232e443d__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_gowin_hdmi_pll.clk_27m)", 
                                                         "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                         55);
    tb_gowin_hdmi_pll__DOT__start_time = VL_TIME_UNITED_D(1000);
    tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2 = 0x0000000aU;
    while (VL_LTS_III(32, 0U, tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2)) {
        Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(vlSelf, 
                                                                 "@(posedge tb_gowin_hdmi_pll.clk_27m)");
        co_await vlSelfRef.__VtrigSched_h232e443d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_gowin_hdmi_pll.clk_27m)", 
                                                             "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                             58);
        tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2 
            = (tb_gowin_hdmi_pll__DOT__unnamedblk1_3__DOT____Vrepeat2 
               - (IData)(1U));
    }
    tb_gowin_hdmi_pll__DOT__end_time = VL_TIME_UNITED_D(1000);
    tb_gowin_hdmi_pll__DOT__measured_period = ((tb_gowin_hdmi_pll__DOT__end_time 
                                                - tb_gowin_hdmi_pll__DOT__start_time) 
                                               / 10.0);
    VL_WRITEF_NX("\nInput clock:\nMeasured period: %.3f ns\nExpected period: 37.037 ns\n",1
                 , 'D',tb_gowin_hdmi_pll__DOT__measured_period);
    if (VL_UNLIKELY((((tb_gowin_hdmi_pll__DOT__measured_period 
                       < 3.70169999999999959e+01) | 
                      (tb_gowin_hdmi_pll__DOT__measured_period 
                       > 3.70570000000000022e+01))))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb_gowin_hdmi_pll.sv:70: Assertion failed in %m: FAIL: Input clock frequency incorrect\n",3, 'M',vlSymsp->name(),"tb_gowin_hdmi_pll", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000));
        VL_STOP_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 70, "", false);
    }
    VL_WRITEF_NX("PASS: Input clock is approximately 27 MHz\n",0);
    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h9976415a__0(vlSelf, 
                                                             "@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)");
    co_await vlSelfRef.__VtrigSched_h9976415a__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)", 
                                                         "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                         78);
    tb_gowin_hdmi_pll__DOT__start_time = VL_TIME_UNITED_D(1000);
    tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3 = 0x00000014U;
    while (VL_LTS_III(32, 0U, tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3)) {
        Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h9976415a__0(vlSelf, 
                                                                 "@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)");
        co_await vlSelfRef.__VtrigSched_h9976415a__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)", 
                                                             "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                                             81);
        tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3 
            = (tb_gowin_hdmi_pll__DOT__unnamedblk1_4__DOT____Vrepeat3 
               - (IData)(1U));
    }
    tb_gowin_hdmi_pll__DOT__end_time = VL_TIME_UNITED_D(1000);
    tb_gowin_hdmi_pll__DOT__measured_period = ((tb_gowin_hdmi_pll__DOT__end_time 
                                                - tb_gowin_hdmi_pll__DOT__start_time) 
                                               / 20.0);
    VL_WRITEF_NX("\nPLL output clock:\nMeasured period: %.3f ns\nExpected period: 7.407 ns\n",1
                 , 'D',tb_gowin_hdmi_pll__DOT__measured_period);
    if (VL_UNLIKELY((((tb_gowin_hdmi_pll__DOT__measured_period 
                       < 7.38700000000000045e+00) | 
                      (tb_gowin_hdmi_pll__DOT__measured_period 
                       > 7.42699999999999960e+00))))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb_gowin_hdmi_pll.sv:93: Assertion failed in %m: FAIL: PLL output frequency incorrect\n",3, 'M',vlSymsp->name(),"tb_gowin_hdmi_pll", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000));
        VL_STOP_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 93, "", false);
    }
    VL_WRITEF_NX("PASS: PLL output is approximately 135 MHz\n",0);
    vlSelfRef.tb_gowin_hdmi_pll__DOT__reset = 1U;
    co_await vlSelfRef.__VdlySched.delay(0x00000000000003e8ULL, 
                                         nullptr, "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                         102);
    if (VL_UNLIKELY((vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked))) {
        VL_WRITEF_NX("[%0t] %%Fatal: tb_gowin_hdmi_pll.sv:105: Assertion failed in %m: FAIL: PLL lock did not clear during reset\n",3, 'M',vlSymsp->name(),"tb_gowin_hdmi_pll", 'T',-9
                     , '#',64,VL_TIME_UNITED_Q(1000));
        VL_STOP_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 105, "", false);
    }
    VL_WRITEF_NX("PASS: Reset clears PLL lock\n\n------------------------------------\n ALL PLL TESTS PASSED\n------------------------------------\n",0);
    VL_FINISH_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 114, "");
    co_return;
}

VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__1(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m = 0U;
    while (true) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000000e78ULL, 
                                             nullptr, 
                                             "24_HDMI/gowin_hdmi_pll.sv", 
                                             27);
        vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m 
            = (1U & ((~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__reset)) 
                     & (~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m))));
    }
    co_return;
}

VlCoroutine Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__2(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_initial__TOP__Vtiming__2\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    while (VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish())) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000004857ULL, 
                                             nullptr, 
                                             "24_HDMI/tb_gowin_hdmi_pll.sv", 
                                             31);
        vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m = 
            (1U & (~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m)));
    }
    co_return;
}

bool Vtb_gowin_hdmi_pll___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vtb_gowin_hdmi_pll___024root___timing_ready(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___timing_ready\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h232e443d__0.ready("@(posedge tb_gowin_hdmi_pll.clk_27m)");
    }
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h232e43fc__0.ready("@(negedge tb_gowin_hdmi_pll.clk_27m)");
    }
    if ((8ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h9976415a__0.ready("@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)");
    }
}

void Vtb_gowin_hdmi_pll___024root___timing_resume(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___timing_resume\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h232e443d__0.moveToResumeQueue(
                                                          "@(posedge tb_gowin_hdmi_pll.clk_27m)");
    vlSelfRef.__VtrigSched_h232e43fc__0.moveToResumeQueue(
                                                          "@(negedge tb_gowin_hdmi_pll.clk_27m)");
    vlSelfRef.__VtrigSched_h9976415a__0.moveToResumeQueue(
                                                          "@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)");
    vlSelfRef.__VtrigSched_h232e443d__0.resume("@(posedge tb_gowin_hdmi_pll.clk_27m)");
    vlSelfRef.__VtrigSched_h232e43fc__0.resume("@(negedge tb_gowin_hdmi_pll.clk_27m)");
    vlSelfRef.__VtrigSched_h9976415a__0.resume("@(posedge tb_gowin_hdmi_pll.dut.sim_clk_135m)");
    if ((0x0000000000000010ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vtb_gowin_hdmi_pll___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_gowin_hdmi_pll___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vtb_gowin_hdmi_pll___024root___eval_phase__act(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_phase__act\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    {
        // Inlined CFunc: _eval_triggers_vec__act
        vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                        ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                          << 4U) 
                                                         | (((((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m) 
                                                               & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0))) 
                                                              << 3U) 
                                                             | (((~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m)) 
                                                                 & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0)) 
                                                                << 2U)) 
                                                            | ((((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__reset) 
                                                                 & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__reset__0))) 
                                                                << 1U) 
                                                               | ((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m) 
                                                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0))))))));
        vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0 
            = vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m;
        vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__reset__0 
            = vlSelfRef.tb_gowin_hdmi_pll__DOT__reset;
        vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0 
            = vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m;
    }
    Vtb_gowin_hdmi_pll___024root___timing_ready(vlSelf);
    Vtb_gowin_hdmi_pll___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_gowin_hdmi_pll___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vtb_gowin_hdmi_pll___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vtb_gowin_hdmi_pll___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vtb_gowin_hdmi_pll___024root___timing_resume(vlSelf);
    }
    return (__VactExecute);
}

bool Vtb_gowin_hdmi_pll___024root___eval_phase__inact(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_phase__inact\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 1, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vtb_gowin_hdmi_pll___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vtb_gowin_hdmi_pll___024root___eval_phase__nba(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_phase__nba\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vtb_gowin_hdmi_pll___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        {
            // Inlined CFunc: _eval_nba
            if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
                {
                    // Inlined CFunc: _nba_sequent__TOP__0
                    CData/*3:0*/ __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter;
                    __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter = 0;
                    CData/*0:0*/ __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked;
                    __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked = 0;
                    __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter 
                        = vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter;
                    __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked 
                        = vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked;
                    if (vlSelfRef.tb_gowin_hdmi_pll__DOT__reset) {
                        __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter = 0U;
                        __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked = 0U;
                    } else if ((1U & (~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked)))) {
                        if ((9U == (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter))) {
                            __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked = 1U;
                        } else {
                            __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter 
                                = (0x0000000fU & ((IData)(1U) 
                                                  + (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter)));
                        }
                    }
                    vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter 
                        = __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__lock_counter;
                    vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked 
                        = __Vinline_0__eval_nba___Vinline_0__nba_sequent__TOP__0___Vdly__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_locked;
                }
            }
        }
        Vtb_gowin_hdmi_pll___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vtb_gowin_hdmi_pll___024root___eval(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00002710U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vtb_gowin_hdmi_pll___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 1, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 10000 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00002710U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 1, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 10000 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00002710U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vtb_gowin_hdmi_pll___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("24_HDMI/tb_gowin_hdmi_pll.sv", 1, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 10000 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vtb_gowin_hdmi_pll___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vtb_gowin_hdmi_pll___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vtb_gowin_hdmi_pll___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e443d__0\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((((~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m)) 
                                    & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0)) 
                                   << 2U) | ((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m) 
                                             & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0 
        = vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
    }
    if ((4ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h232e43fc__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e43fc__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h232e43fc__0\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((((~ (IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m)) 
                                    & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0)) 
                                   << 2U) | ((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m) 
                                             & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0))))));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__clk_27m__0 
        = vlSelfRef.tb_gowin_hdmi_pll__DOT__clk_27m;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h232e443d__0.ready(__VeventDescription);
    }
    if ((4ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h232e43fc__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

void Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h9976415a__0(Vtb_gowin_hdmi_pll___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root____VbeforeTrig_h9976415a__0\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)((((IData)(vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m) 
                                   & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0))) 
                                  << 3U)));
    vlSelfRef.__Vtrigprevexpr___TOP__tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m__0 
        = vlSelfRef.tb_gowin_hdmi_pll__DOT__dut__DOT__sim_clk_135m;
    if ((8ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h9976415a__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h9976415a__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vtb_gowin_hdmi_pll___024root___eval_debug_assertions(Vtb_gowin_hdmi_pll___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_gowin_hdmi_pll___024root___eval_debug_assertions\n"); );
    Vtb_gowin_hdmi_pll__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
