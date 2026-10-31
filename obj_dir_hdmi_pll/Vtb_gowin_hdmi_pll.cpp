// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vtb_gowin_hdmi_pll__pch.h"

//============================================================
// Constructors

Vtb_gowin_hdmi_pll::Vtb_gowin_hdmi_pll(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vtb_gowin_hdmi_pll__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vtb_gowin_hdmi_pll::Vtb_gowin_hdmi_pll(const char* _vcname__)
    : Vtb_gowin_hdmi_pll(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vtb_gowin_hdmi_pll::~Vtb_gowin_hdmi_pll() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vtb_gowin_hdmi_pll___024root___eval_debug_assertions(Vtb_gowin_hdmi_pll___024root* vlSelf);
#endif  // VL_DEBUG
void Vtb_gowin_hdmi_pll___024root___eval_static(Vtb_gowin_hdmi_pll___024root* vlSelf);
void Vtb_gowin_hdmi_pll___024root___eval_initial(Vtb_gowin_hdmi_pll___024root* vlSelf);
void Vtb_gowin_hdmi_pll___024root___eval_settle(Vtb_gowin_hdmi_pll___024root* vlSelf);
void Vtb_gowin_hdmi_pll___024root___eval(Vtb_gowin_hdmi_pll___024root* vlSelf);

void Vtb_gowin_hdmi_pll::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vtb_gowin_hdmi_pll::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vtb_gowin_hdmi_pll___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vtb_gowin_hdmi_pll___024root___eval_static(&(vlSymsp->TOP));
        Vtb_gowin_hdmi_pll___024root___eval_initial(&(vlSymsp->TOP));
        Vtb_gowin_hdmi_pll___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vtb_gowin_hdmi_pll___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vtb_gowin_hdmi_pll::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vtb_gowin_hdmi_pll::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vtb_gowin_hdmi_pll::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vtb_gowin_hdmi_pll___024root___eval_final(Vtb_gowin_hdmi_pll___024root* vlSelf);

VL_ATTR_COLD void Vtb_gowin_hdmi_pll::final() {
    contextp()->executingFinal(true);
    Vtb_gowin_hdmi_pll___024root___eval_final(&(vlSymsp->TOP));
    contextp()->executingFinal(false);
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vtb_gowin_hdmi_pll::hierName() const { return vlSymsp->name(); }
const char* Vtb_gowin_hdmi_pll::modelName() const { return "Vtb_gowin_hdmi_pll"; }
unsigned Vtb_gowin_hdmi_pll::threads() const { return 1; }
void Vtb_gowin_hdmi_pll::prepareClone() const { contextp()->prepareClone(); }
void Vtb_gowin_hdmi_pll::atClone() const {
    contextp()->threadPoolpOnClone();
}
