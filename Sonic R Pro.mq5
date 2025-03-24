//+------------------------------------------------------------------+
//|                                             SonicR_PropFirm.mq5 |
//|                         SonicR PropFirm EA - Optimized for PropFirms |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"
#property version   "3.00"
#property strict
#property description "SonicR PropFirm EA 3.0 - Advanced PropFirm challenge trading system with Modular Architecture"

// Include cấu trúc module mới
#include "Include/Modules/SonicR_Modules.mqh"

// Enumerations
enum ENUM_PROP_FIRM
{
    PROP_FIRM_FTMO,        // FTMO
    PROP_FIRM_THE5ERS,     // The5ers
    PROP_FIRM_E8,          // E8 Funding
    PROP_FIRM_MFF,         // MyForexFunds
    PROP_FIRM_CUSTOM       // Custom Settings
};

enum ENUM_CHALLENGE_PHASE
{
    PHASE_CHALLENGE,       // Challenge Phase
    PHASE_VERIFICATION,    // Verification Phase
    PHASE_FUNDED           // Funded Account
};

// Input parameters
// --- General Settings ---
input string GeneralSettings = "===== General Settings =====";
input string EAName = "SonicR PropFirm";        // EA Name
input int MagicNumber = 234567;                 // Magic Number
input bool UseVirtualSL = true;                 // Use Virtual SL and TP
input bool DisplayDashboard = true;             // Display Dashboard
input int MaxRetryAttempts = 3;                 // Maximum Retry Attempts
input int RetryDelayMs = 200;                   // Retry Delay (ms)
input bool EnableDetailedLogging = true;        // Enable Detailed Logging
input bool SaveLogsToFile = true;               // Save Logs to File

// --- PropFirm Settings ---
input string PropFirmSettings = "===== PropFirm Settings =====";
input ENUM_PROP_FIRM PropFirmType = PROP_FIRM_FTMO; // PropFirm Type
input ENUM_CHALLENGE_PHASE ChallengePhase = PHASE_CHALLENGE; // Challenge Phase
input bool AutoDetectPhase = true;              // Auto-detect Phase
input double CustomTargetProfit = 10.0;         // Custom Target Profit (%)
input double CustomMaxDrawdown = 10.0;          // Custom Max Drawdown (%)
input double CustomDailyDrawdown = 5.0;         // Custom Daily Drawdown (%)

// --- Risk Management Settings ---
input string RiskSettings = "===== Risk Management =====";
input double RiskPercent = 0.5;                 // Risk Percent per Trade
input double MaxDailyDD = 3.0;                  // Max Daily Drawdown (%)
input double MaxTotalDD = 5.0;                  // Max Total Drawdown (%)
input int MaxTradesPerDay = 3;                  // Max Trades per Day
input int SlippagePoints = 5;                   // Slippage (points)
input bool UseRecoveryMode = true;              // Use Recovery Mode
input double RecoveryReduceFactor = 0.5;        // Recovery Size Reduction Factor

// --- Session Filter Settings ---
input string SessionSettings = "===== Session Filter =====";
input bool EnableLondonSession = true;          // Enable London Session
input bool EnableNewYorkSession = true;         // Enable New York Session
input bool EnableLondonNYOverlap = true;        // Enable London-NY Overlap
input bool EnableAsianSession = false;          // Enable Asian Session
input int FridayEndHour = 16;                   // Friday End Hour (GMT)
input bool AllowMondayTrading = true;           // Allow Monday Trading
input bool AllowFridayTrading = true;           // Allow Friday Trading
input double SessionQualityThreshold = 60.0;    // Session Quality Threshold (0-100)

// --- Exit Management Settings ---
input string ExitSettings = "===== Exit Management =====";
input bool UsePartialClose = true;              // Use Partial Close
input double TP1Percent = 50.0;                 // TP1 Percent to Close
input double TP1Distance = 1.5;                 // TP1 Distance (x SL)
input double TP2Distance = 2.5;                 // TP2 Distance (x SL)
input bool UseBreakEven = true;                 // Use Break-Even
input double BreakEvenTrigger = 0.7;            // Break-Even Trigger (x SL)
input double BreakEvenOffset = 5.0;             // Break-Even Offset (points)
input bool UseTrailing = true;                  // Use Trailing Stop
input double TrailingStart = 1.5;               // Trailing Start (x SL)
input double TrailingStep = 15.0;               // Trailing Step (points)
input bool UseAdaptiveTrailing = true;          // Use Adaptive Trailing

// --- Signal Settings ---
input string SignalSettings = "===== Signal Settings =====";
input double MinRR = 1.5;                       // Minimum R:R Ratio
input double MinSignalQuality = 70.0;           // Minimum Signal Quality
input bool UseScoutEntries = false;             // Use Scout Entries

// --- News Filter Settings ---
input string NewsSettings = "===== News Filter =====";
input bool UseNewsFilter = true;                // Use News Filter
input int NewsMinutesBefore = 30;               // Minutes Before News
input int NewsMinutesAfter = 15;                // Minutes After News
input bool HighImpactOnly = true;               // High Impact Only

// --- Market Regime Filter Settings ---
input string MarketRegimeSettings = "===== Market Regime Filter =====";
input bool UseMarketRegimeFilter = true;        // Use Market Regime Filter
input bool TradeBullishRegime = true;           // Trade Bullish Regime
input bool TradeBearishRegime = true;           // Trade Bearish Regime
input bool TradeRangingRegime = true;           // Trade Ranging Regime
input bool TradeVolatileRegime = false;         // Trade Volatile Regime

// --- Adaptive Filters Settings ---
input string AdaptiveFiltersSettings = "===== Adaptive Filters =====";
input bool UseAdaptiveFilters = true;           // Use Adaptive Filters
input int ChallengeDaysTotal = 30;              // Total Challenge Days
input int ChallengeDaysRemaining = 30;          // Days Remaining in Challenge
input double EmergencyProgressThreshold = 30.0; // Emergency Progress Threshold (%)
input double ConservativeProgressThreshold = 80.0; // Conservative Progress Threshold (%)

// --- Multi-Symbol Trading Settings ---
input string MultiSymbolSettings = "===== Multi-Symbol Trading =====";
input bool EnableMultiSymbolTrading = false;    // Enable Multi-Symbol Trading
input bool Trade_EURUSD = true;                 // Trade EURUSD
input bool Trade_GBPUSD = true;                 // Trade GBPUSD
input bool Trade_USDJPY = true;                 // Trade USDJPY
input bool Trade_AUDUSD = false;                // Trade AUDUSD
input bool Trade_USDCAD = false;                // Trade USDCAD
input bool Trade_EURJPY = false;                // Trade EURJPY
input bool Trade_GBPJPY = false;                // Trade GBPJPY
input bool Trade_XAUUSD = false;                // Trade XAUUSD
input bool Trade_US30 = false;                  // Trade US30
input double TotalRiskLimit = 5.0;              // Total Risk Limit (%)
input bool SyncEntries = true;                  // Synchronize Entries
input int MaxActiveSymbols = 3;                 // Maximum Active Symbols

// --- PVSRA Settings ---
input string PVSRASettings = "===== PVSRA Settings =====";
input bool UsePVSRA = true;                   // Use PVSRA Analysis
input int VolumeAvgPeriod = 20;               // Volume Average Period
input int SpreadAvgPeriod = 10;               // Spread Average Period
input int ConfirmationBars = 3;               // Confirmation Bars
input double VolumeThreshold = 1.5;           // Volume Threshold (150% of avg)
input double SpreadThreshold = 0.7;           // Spread Threshold (70% of avg)

// --- SR System Settings ---
input string SRSettings = "===== Support/Resistance Settings =====";
input bool UseSRFilter = true;                // Use S/R Filter
input bool UseMultiTimeframeSR = true;        // Use Multi-Timeframe S/R
input int SRLookbackPeriod = 100;             // S/R Lookback Period
input double SRQualityThreshold = 70.0;       // S/R Zone Quality Threshold

// --- Dashboard Settings ---
input string DashboardSettings = "===== Dashboard Settings =====";
input color BullishColor = clrForestGreen;    // Bullish Color
input color BearishColor = clrFireBrick;      // Bearish Color
input color NeutralColor = clrDarkGray;       // Neutral Color
input color TextColor = clrWhite;             // Text Color
input color BackgroundColor = C'33,33,33';    // Background Color
input int FontSize = 8;                      // Font Size
input bool ShowDetailedStats = true;          // Show Detailed Statistics

// Đối tượng module chính
CSonicRModules* g_modules = NULL;

// Mảng lưu trữ các cặp tiền được bật
string g_enabledSymbols[];
int g_symbolCount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Validate input parameters
    if(RiskPercent <= 0 || RiskPercent > 5) {
        Print("ERROR: RiskPercent invalid (", RiskPercent, "). Must be > 0 and <= 5.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(MaxDailyDD <= 0 || MaxDailyDD > 10) {
        Print("ERROR: MaxDailyDD invalid (", MaxDailyDD, "). Must be > 0 and <= 10.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(MaxTotalDD <= 0 || MaxTotalDD > 20) {
        Print("ERROR: MaxTotalDD invalid (", MaxTotalDD, "). Must be > 0 and <= 20.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    Print("Initializing SonicR PropFirm EA v3.00...");
    
    // Khởi tạo danh sách các cặp tiền tệ được bật
    InitializeEnabledSymbols();
    
    // Khởi tạo modules
    g_modules = new CSonicRModules();
    if(g_modules == NULL) {
        Print("ERROR: Failed to initialize SonicR Modules");
        return INIT_FAILED;
    }
    
    // Khởi tạo tất cả các module với các tham số đầu vào
    if(!g_modules.Initialize(
        // EA info
        EAName, MagicNumber, EnableDetailedLogging, SaveLogsToFile, DisplayDashboard,
        
        // Risk
        RiskPercent, MaxDailyDD, MaxTotalDD, MaxTradesPerDay, UseRecoveryMode, RecoveryReduceFactor,
        
        // PropFirm
        PropFirmType, ChallengePhase, AutoDetectPhase, CustomTargetProfit, CustomMaxDrawdown, CustomDailyDrawdown,
        
        // Challenge timelines
        ChallengeDaysTotal, ChallengeDaysRemaining, EmergencyProgressThreshold, ConservativeProgressThreshold,
        
        // Trading
        UseVirtualSL, SlippagePoints, MinRR, MinSignalQuality, UseScoutEntries, MaxRetryAttempts, RetryDelayMs,
        
        // Exit parameters
        UsePartialClose, TP1Percent, TP1Distance, TP2Distance, 
        UseBreakEven, BreakEvenTrigger, BreakEvenOffset,
        UseTrailing, TrailingStart, TrailingStep, UseAdaptiveTrailing,
        
        // Sessions
        EnableLondonSession, EnableNewYorkSession, EnableLondonNYOverlap, EnableAsianSession,
        FridayEndHour, AllowMondayTrading, AllowFridayTrading, SessionQualityThreshold,
        
        // News
        UseNewsFilter, NewsMinutesBefore, NewsMinutesAfter, HighImpactOnly,
        
        // Market Regime
        UseMarketRegimeFilter, TradeBullishRegime, TradeBearishRegime, TradeRangingRegime, TradeVolatileRegime,
        
        // PVSRA
        UsePVSRA, VolumeAvgPeriod, SpreadAvgPeriod, ConfirmationBars, VolumeThreshold, SpreadThreshold,
        
        // SR
        UseSRFilter, UseMultiTimeframeSR, SRLookbackPeriod, SRQualityThreshold,
        
        // Multi-Symbol Trading
        EnableMultiSymbolTrading, TotalRiskLimit, MaxActiveSymbols, SyncEntries, g_enabledSymbols
    )) {
        Print("ERROR: Module initialization failed");
        return INIT_FAILED;
    }
    
    Print("SonicR PropFirm EA v3.00 initialized successfully");
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    Print("Stopping SonicR PropFirm EA. Reason: " + GetDeinitReasonText(reason));
    
    // Giải phóng bộ nhớ
    if(g_modules != NULL) {
        g_modules.Cleanup();
        delete g_modules;
        g_modules = NULL;
    }
    
    // Xóa các đối tượng trên biểu đồ
    ObjectsDeleteAll(0, "SonicR_");
}

//+------------------------------------------------------------------+
//| Get deinit reason as text                                        |
//+------------------------------------------------------------------+
string GetDeinitReasonText(int reason)
{
    switch(reason) {
        case REASON_PROGRAM: return "Program";
        case REASON_REMOVE: return "Removed from chart";
        case REASON_RECOMPILE: return "Recompiled";
        case REASON_CHARTCHANGE: return "Chart changed";
        case REASON_CHARTCLOSE: return "Chart closed";
        case REASON_PARAMETERS: return "Parameters changed";
        case REASON_ACCOUNT: return "Account changed";
        case REASON_TEMPLATE: return "Template applied";
        case REASON_INITFAILED: return "Init failed";
        case REASON_CLOSE: return "Terminal closed";
        default: return "Unknown reason: " + IntegerToString(reason);
    }
}

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
{
    if(g_modules != NULL) {
        g_modules.OnTick();
    }
}

//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    if(g_modules != NULL) {
        g_modules.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Expert tester function                                           |
//+------------------------------------------------------------------+
double OnTester()
{
    if(g_modules != NULL) {
        return g_modules.OnTester();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
    if(g_modules != NULL) {
        g_modules.OnTradeTransaction(trans, request, result);
    }
}

//+------------------------------------------------------------------+
//| Initialize enabled symbols list                                  |
//+------------------------------------------------------------------+
void InitializeEnabledSymbols()
{
    // Clear existing symbol list
    ArrayResize(g_enabledSymbols, 0);
    g_symbolCount = 0;
    
    // Always add the current chart symbol first
    AddSymbolIfEnabled(_Symbol, true);
    
    // Check each input parameter for enabled symbols
    if(Trade_EURUSD && _Symbol != "EURUSD") AddSymbolIfEnabled("EURUSD", true);
    if(Trade_GBPUSD && _Symbol != "GBPUSD") AddSymbolIfEnabled("GBPUSD", true);
    if(Trade_USDJPY && _Symbol != "USDJPY") AddSymbolIfEnabled("USDJPY", true);
    if(Trade_AUDUSD && _Symbol != "AUDUSD") AddSymbolIfEnabled("AUDUSD", true);
    if(Trade_USDCAD && _Symbol != "USDCAD") AddSymbolIfEnabled("USDCAD", true);
    if(Trade_EURJPY && _Symbol != "EURJPY") AddSymbolIfEnabled("EURJPY", true);
    if(Trade_GBPJPY && _Symbol != "GBPJPY") AddSymbolIfEnabled("GBPJPY", true);
    if(Trade_XAUUSD && _Symbol != "XAUUSD") AddSymbolIfEnabled("XAUUSD", true);
    if(Trade_US30 && _Symbol != "US30") AddSymbolIfEnabled("US30", true);
    
    // Log the enabled symbols
    string symbolList = "Multi-Symbol Trading " + (EnableMultiSymbolTrading ? "enabled" : "disabled") + " for: ";
    for(int i = 0; i < g_symbolCount; i++) {
        symbolList += g_enabledSymbols[i];
        if(i < g_symbolCount - 1) symbolList += ", ";
    }
    Print(symbolList);
}

//+------------------------------------------------------------------+
//| Add a symbol to the enabled list if valid                         |
//+------------------------------------------------------------------+
void AddSymbolIfEnabled(string symbol, bool checkIfExists = false)
{
    // Check if symbol exists in the Market Watch
    if(!SymbolSelect(symbol, true)) {
        Print("WARNING: Symbol " + symbol + " not found in Market Watch, skipping");
        return;
    }
    
    // Check if we already have this symbol (if required)
    if(checkIfExists) {
        for(int i = 0; i < g_symbolCount; i++) {
            if(g_enabledSymbols[i] == symbol) {
                return; // Symbol already in the list
            }
        }
    }
    
    // Add symbol to the list
    g_symbolCount++;
    ArrayResize(g_enabledSymbols, g_symbolCount);
    g_enabledSymbols[g_symbolCount - 1] = symbol;
} 