//+------------------------------------------------------------------+
//|                                             SonicR_PropFirm.mq5 |
//|                         SonicR PropFirm EA - Optimized for PropFirms |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"
#property version   "2.00"
#property strict
#property description "SonicR PropFirm EA 2.0 - Advanced PropFirm challenge trading system"

// Include necessary files
#include <Trade\Trade.mqh>
#include "Include\SonicR_Core.mqh"
#include "Include\SonicR_SR.mqh"
#include "Include\SonicR_RiskManager.mqh"
#include "Include\SonicR_ExitManager.mqh"
#include "Include\SonicR_Filters.mqh"
#include "Include\SonicR_PropSettings.mqh"
#include "Include\SonicR_Logger.mqh"
#include "Include\SonicR_Dashboard.mqh"
#include "Include\SonicR_AdaptiveFilters.mqh"  // New include for adaptive filters
#include "Include\SonicR_PVSRA.mqh"  // Include PVSRA component

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

enum ENUM_EA_STATE
{
    STATE_INITIALIZING,    // Initializing
    STATE_SCANNING,        // Scanning for signals
    STATE_WAITING,         // Waiting for entry conditions
    STATE_EXECUTING,       // Executing trade
    STATE_MONITORING,      // Monitoring open positions
    STATE_STOPPED          // EA stopped (emergency, error, etc.)
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

// Global objects
CLogger* g_logger = NULL;                       // Logger
CSonicRCore* g_sonicCore = NULL;                // Core strategy
CSonicRSR* g_srSystem = NULL;                   // Support/Resistance system
CRiskManager* g_riskManager = NULL;             // Risk management
CEntryManager* g_entryManager = NULL;           // Entry management
CExitManager* g_exitManager = NULL;             // Exit management
CStateMachine* g_stateMachine = NULL;           // State machine
CSessionFilter* g_sessionFilter = NULL;         // Session filter
CNewsFilter* g_newsFilter = NULL;               // News filter
CMarketRegimeFilter* g_marketRegimeFilter = NULL; // Market regime filter
CDashboard* g_dashboard = NULL;                 // Dashboard
CPropSettings* g_propSettings = NULL;           // PropFirm settings
CTrade* g_trade = NULL;                         // MT5 trade object
CAdaptiveFilters* g_adaptiveFilters = NULL;     // Adaptive filters
CPVSRA* g_pvsra = NULL;                         // PVSRA analysis

// State variables
bool g_initialized = false;
bool g_shutdownRequested = false;
datetime g_lastMarketRegimeCheck = 0;
int g_successfulTrades = 0;
int g_failedTrades = 0;
double g_totalProfit = 0.0;
double g_totalLoss = 0.0;
datetime g_lastBarTime = 0;

// Multi-Symbol variables
string g_enabledSymbols[];                      // Array of enabled symbols
int g_symbolCount = 0;                          // Count of enabled symbols
MqlRates g_symbolRates[][100];                  // Price data for each symbol
datetime g_lastBarTimes[];                      // Last bar time for each symbol
double g_riskUsed = 0.0;                        // Current risk used across all symbols
bool g_symbolIsProcessing[];                    // Flag if a symbol is currently processing
int g_tradeCounts[];                            // Count of trades for each symbol

//+------------------------------------------------------------------+
//| Safe delete template function for proper memory management       |
//+------------------------------------------------------------------+
template <typename T>
void SafeDelete(T* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

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
    
    // Initialize logger first for proper initialization logging
    g_logger = new CLogger(EAName, MagicNumber, EnableDetailedLogging, SaveLogsToFile);
    if(g_logger == NULL) {
        Print("ERROR: Failed to initialize Logger. Out of memory?");
        return INIT_FAILED;
    }
    
    g_logger.Info("Initializing SonicR PropFirm EA v2.00...");
    
    // Initialize MT5 trade object
    g_trade = new CTrade();
    if(g_trade == NULL) {
        g_logger.Error("Failed to initialize Trade object");
        return INIT_FAILED;
    }
    
    g_trade.SetExpertMagicNumber(MagicNumber);
    g_trade.SetDeviationInPoints(SlippagePoints);
    g_trade.LogLevel(LOG_LEVEL_ERRORS); // Only log errors from trade object
    
    // Initialize SR system with new parameters
    g_srSystem = new CSonicRSR();
    if(g_srSystem == NULL) {
        g_logger.Error("Failed to initialize SR system");
        return INIT_FAILED;
    }
    
    // Configure SR system with user parameters
    g_srSystem.SetParameters(SRLookbackPeriod, SRQualityThreshold, UseMultiTimeframeSR);
    
    if(!g_srSystem.Initialize()) {
        g_logger.Error("Failed to initialize SR system indicators");
        return INIT_FAILED;
    }
    
    // Initialize PVSRA system
    g_pvsra = new CPVSRA();
    if(g_pvsra == NULL) {
        g_logger.Error("Failed to initialize PVSRA system");
        return INIT_FAILED;
    }
    
    // Set logger for PVSRA
    g_pvsra.SetLogger(g_logger);
    
    // Configure PVSRA settings
    g_pvsra.SetParameters(VolumeAvgPeriod, SpreadAvgPeriod, ConfirmationBars);
    g_pvsra.SetThresholds(VolumeThreshold, SpreadThreshold);
    
    // Initialize PVSRA
    if(!g_pvsra.Initialize()) {
        g_logger.Error("Failed to initialize PVSRA indicators");
        return INIT_FAILED;
    }
    
    // Initialize core strategy
    g_sonicCore = new CSonicRCore();
    if(g_sonicCore == NULL) {
        g_logger.Error("Failed to initialize SonicCore");
        return INIT_FAILED;
    }
    
    if(!g_sonicCore.Initialize()) {
        g_logger.Error("Failed to initialize SonicCore indicators");
        return INIT_FAILED;
    }
    
    // Initialize risk manager
    g_riskManager = new CRiskManager(RiskPercent, MaxDailyDD, MaxTotalDD, MaxTradesPerDay);
    if(g_riskManager == NULL) {
        g_logger.Error("Failed to initialize RiskManager");
        return INIT_FAILED;
    }
    
    // Set recovery mode settings
    if(UseRecoveryMode) {
        g_riskManager.SetRecoveryMode(true, RecoveryReduceFactor);
    }
    
    // Initialize state machine
    g_stateMachine = new CStateMachine();
    if(g_stateMachine == NULL) {
        g_logger.Error("Failed to initialize StateMachine");
        return INIT_FAILED;
    }
    
    // Initialize PropFirm settings
    g_propSettings = new CPropSettings(PropFirmType, ChallengePhase);
    if(g_propSettings == NULL) {
        g_logger.Error("Failed to initialize PropSettings");
        return INIT_FAILED;
    }
    
    // Set custom values if PropFirm type is CUSTOM
    if(PropFirmType == PROP_FIRM_CUSTOM) {
        g_propSettings.SetCustomValues(CustomTargetProfit, CustomMaxDrawdown, CustomDailyDrawdown);
    }
    
    // Set challenge timeframe
    datetime startDate = TimeCurrent() - (ChallengeDaysTotal - ChallengeDaysRemaining) * 86400; // 86400 seconds = 1 day
    g_propSettings.SetChallengeTimeframe(startDate, ChallengeDaysTotal);
    
    // Auto-detect phase if requested
    if(AutoDetectPhase) {
        ENUM_CHALLENGE_PHASE detectedPhase = g_propSettings.AutoDetectPhase();
        if(detectedPhase != ChallengePhase) {
            g_logger.Warning("Auto-detected phase " + EnumToString(detectedPhase) + 
                            " differs from input parameter " + EnumToString(ChallengePhase));
            g_propSettings.SetPhase(detectedPhase);
        }
    }
    
    // Initialize entry manager
    g_entryManager = new CEntryManager(g_sonicCore, g_riskManager, g_trade);
    if(g_entryManager == NULL) {
        g_logger.Error("Failed to initialize EntryManager");
        return INIT_FAILED;
    }
    
    g_entryManager.SetMinRR(MinRR);
    g_entryManager.SetMinSignalQuality(MinSignalQuality);
    g_entryManager.SetUseScoutEntries(UseScoutEntries);
    g_entryManager.SetRetrySettings(MaxRetryAttempts, RetryDelayMs);
    
    // Initialize exit manager
    g_exitManager = new CExitManager(
        UsePartialClose, TP1Percent, TP1Distance, TP2Distance, 
        UseBreakEven, BreakEvenTrigger, BreakEvenOffset, 
        UseTrailing, TrailingStart, TrailingStep, UseAdaptiveTrailing
    );
    
    if(g_exitManager == NULL) {
        g_logger.Error("Failed to initialize ExitManager");
        return INIT_FAILED;
    }
    
    g_exitManager.SetMagicNumber(MagicNumber);
    g_exitManager.SetSlippage(SlippagePoints);
    g_exitManager.SetUseVirtualSL(UseVirtualSL);
    
    // Initialize session filter
    g_sessionFilter = new CSessionFilter(
        EnableLondonSession, EnableNewYorkSession, 
        EnableLondonNYOverlap, EnableAsianSession,
        FridayEndHour, AllowMondayTrading, AllowFridayTrading
    );
    
    if(g_sessionFilter == NULL) {
        g_logger.Error("Failed to initialize SessionFilter");
        return INIT_FAILED;
    }
    
    g_sessionFilter.SetQualityThreshold(SessionQualityThreshold);
    
    // Initialize news filter
    g_newsFilter = new CNewsFilter(UseNewsFilter, NewsMinutesBefore, NewsMinutesAfter, HighImpactOnly);
    if(g_newsFilter == NULL) {
        g_logger.Error("Failed to initialize NewsFilter");
        return INIT_FAILED;
    }
    
    // Initialize market regime filter
    g_marketRegimeFilter = new CMarketRegimeFilter();
    if(g_marketRegimeFilter == NULL) {
        g_logger.Error("Failed to initialize MarketRegimeFilter");
        return INIT_FAILED;
    }
    
    g_marketRegimeFilter.Configure(
        UseMarketRegimeFilter, 
        TradeBullishRegime, TradeBearishRegime, 
        TradeRangingRegime, TradeVolatileRegime
    );
    
    // Initialize dashboard if required
    InitializeDashboard();
    
    // Initialize adaptive filters
    g_adaptiveFilters = new CAdaptiveFilters();
    if(g_adaptiveFilters == NULL) {
        g_logger.Error("Failed to initialize AdaptiveFilters");
        return INIT_FAILED;
    }
    
    // Set logger for adaptive filters
    g_adaptiveFilters.SetLogger(g_logger);
    
    // Set progress thresholds for adaptive filters
    g_adaptiveFilters.SetProgressThresholds(EmergencyProgressThreshold, ConservativeProgressThreshold);
    
    // Initialize PVSRA if enabled
    if(UsePVSRA) {
        g_pvsra = new CPVSRA(VolumeAvgPeriod, SpreadAvgPeriod, VolumeThreshold, SpreadThreshold, ConfirmationBars);
        if(g_pvsra == NULL) {
            g_logger.Error("Failed to initialize PVSRA system");
            return INIT_FAILED;
        }
        
        g_pvsra.SetLogger(g_logger);
        g_logger.Info("PVSRA system initialized");
    }
    
    // Initialize multi-symbol trading if enabled
    if(EnableMultiSymbolTrading) {
        InitializeEnabledSymbols();
        
        // Initialize arrays for symbol rates
        ArrayResize(g_symbolRates, g_symbolCount);
        
        // Pre-load some historical data for each symbol
        for(int i = 0; i < g_symbolCount; i++) {
            string symbol = g_enabledSymbols[i];
            // Load the last 100 bars
            int copied = CopyRates(symbol, PERIOD_CURRENT, 0, 100, g_symbolRates[i]);
            if(copied <= 0) {
                g_logger.Warning("Failed to copy rates for " + symbol + ", error: " + IntegerToString(GetLastError()));
            } else {
                g_logger.Debug("Loaded " + IntegerToString(copied) + " bars for " + symbol);
                
                // Initialize last bar time
                g_lastBarTimes[i] = g_symbolRates[i][0].time;
            }
        }
        
        g_logger.Info("Multi-symbol trading initialized with " + IntegerToString(g_symbolCount) + " symbols");
    }
    
    // Update PropFirm settings
    g_propSettings.Update();
    
    // Log adaptive filters status
    if(UseAdaptiveFilters) {
        g_logger.Info("Adaptive Filters: Enabled - Challenge progress: " + 
                     DoubleToString(g_propSettings.GetProgressPercent(), 1) + "%, " +
                     "Days remaining: " + IntegerToString(ChallengeDaysRemaining));
    } else {
        g_logger.Info("Adaptive Filters: Disabled");
    }
    
    // Log successful initialization with more details
    g_logger.Info("Initialization complete. Running SonicR PropFirm EA 2.0 in " + 
                 EnumToString(g_propSettings.GetPhase()) + " phase for " + 
                 EnumToString(g_propSettings.GetPropFirm()) + 
                 " with adaptive filters " + (UseAdaptiveFilters ? "enabled" : "disabled") +
                 " and PVSRA analysis " + (UsePVSRA ? "enabled" : "disabled"));
    
    g_initialized = true;
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Log EA stopping
    if(g_logger != NULL) {
        g_logger.Info("Stopping SonicR PropFirm EA. Reason: " + IntegerToString(reason));
    }
    
    // Remove dashboard if exists
    if(g_dashboard != NULL) {
        g_dashboard.Remove();
    }
    
    // Free resources using SafeDelete template function
    SafeDelete(g_dashboard);
    SafeDelete(g_marketRegimeFilter);
    SafeDelete(g_newsFilter);
    SafeDelete(g_sessionFilter);
    SafeDelete(g_srSystem);     // Free SR system resources
    SafeDelete(g_exitManager);
    SafeDelete(g_entryManager);
    SafeDelete(g_propSettings);
    SafeDelete(g_stateMachine);
    SafeDelete(g_riskManager);
    SafeDelete(g_sonicCore);
    SafeDelete(g_adaptiveFilters);  // Free adaptive filters resources
    
    // Cleanup and free PVSRA
    if(g_pvsra != NULL) {
        g_pvsra.Cleanup();
        SafeDelete(g_pvsra);
    }
    
    SafeDelete(g_trade);
    SafeDelete(g_logger);
    
    // Delete chart objects
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
    // Skip if not initialized or shutdown requested
    if(!g_initialized || g_shutdownRequested) {
        return;
    }
    
    // Process the current chart symbol
    int currentSymbolIndex = -1;
    for(int i = 0; i < g_symbolCount; i++) {
        if(g_enabledSymbols[i] == _Symbol) {
            currentSymbolIndex = i;
            break;
        }
    }
    
    // Always process the current chart symbol first
    if(currentSymbolIndex >= 0) {
        ProcessCurrentSymbol(currentSymbolIndex);
    }
    
    // Process other symbols if multi-symbol trading is enabled
    if(EnableMultiSymbolTrading) {
        // Count active symbols
        int activeSymbols = 0;
        for(int i = 0; i < g_symbolCount; i++) {
            if(g_symbolIsProcessing[i]) activeSymbols++;
        }
        
        // Process each symbol if not exceeding maximum active symbols
        for(int i = 0; i < g_symbolCount; i++) {
            // Skip current chart symbol as it's already processed
            if(i == currentSymbolIndex) continue;
            
            // Check if we can process more symbols
            if(activeSymbols >= MaxActiveSymbols) break;
            
            // Process this symbol
            ProcessSymbol(i);
            activeSymbols++;
        }
    }
    
    // Manage global risk across all symbols
    ManageGlobalRisk();
}

//+------------------------------------------------------------------+
//| Process the current chart symbol                                 |
//+------------------------------------------------------------------+
void ProcessCurrentSymbol(int symbolIndex)
{
    // Check if symbol is valid
    if(symbolIndex < 0 || symbolIndex >= g_symbolCount) return;
    
    // Set flag that we're processing this symbol
    g_symbolIsProcessing[symbolIndex] = true;
    
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != g_lastBarTime);
    
    if(isNewBar) {
        g_lastBarTime = currentBarTime;
        g_logger.Debug("New bar opened at " + TimeToString(currentBarTime));
        
        // Only update "heavy" components on new bar
        g_sonicCore.UpdateFull();  // Full update including pattern detection
        
        // Update SR system on new bar
        if(g_srSystem != NULL) {
            g_srSystem.Update();
        }
        
        // Update PVSRA if enabled
        if(UsePVSRA && g_pvsra != NULL) {
            g_pvsra.Update();
        }
        
        // Update market regime hourly
        if(TimeCurrent() - g_lastMarketRegimeCheck >= 3600) { // Update hourly
            g_marketRegimeFilter.Update(g_sonicCore);
            g_lastMarketRegimeCheck = TimeCurrent();
            
            // Log current market regime
            g_logger.Info("Current market regime: " + g_marketRegimeFilter.GetCurrentRegimeAsString());
        }
        
        // Update adaptive filters on new bar
        if(UseAdaptiveFilters && g_adaptiveFilters != NULL) {
            g_adaptiveFilters.Update(g_sonicCore);
            
            // Adjust parameters based on market regime
            double adxThreshold = g_adaptiveFilters.GetADXThreshold(_Symbol);
            int maxTrades = g_adaptiveFilters.GetMaxTradesForRegime();
            double riskPercent = g_adaptiveFilters.GetBaseRiskPercent(_Symbol);
            double minRR = g_adaptiveFilters.GetMinRR();
            bool useScoutEntries = g_adaptiveFilters.ShouldUseScoutEntries();
            
            // Adjust based on PropFirm challenge progress
            g_adaptiveFilters.AdjustForChallengeProgress(ChallengeDaysRemaining, ChallengeDaysTotal);
            
            // Update other components
            g_riskManager.SetMaxTradesPerDay(maxTrades);
            g_riskManager.SetRiskPercent(riskPercent);
            g_entryManager.SetMinRR(minRR);
            g_entryManager.SetUseScoutEntries(useScoutEntries);
            
            // Log updated info
            static datetime lastAdaptiveLog = 0;
            if(TimeCurrent() - lastAdaptiveLog >= 3600) {  // Log hourly
                g_logger.Info("Adaptive filters: " + g_adaptiveFilters.GetCurrentRegimeAsString() + 
                             ", Risk: " + DoubleToString(riskPercent, 2) + 
                             ", MaxTrades: " + IntegerToString(maxTrades) +
                             ", MinRR: " + DoubleToString(minRR, 1));
                lastAdaptiveLog = TimeCurrent();
            }
        }
    } else {
        // When not a new bar, only do light updates
        g_sonicCore.UpdateLight();  // Only update price, no pattern analysis
    }
    
    // Update components needed for every tick
    g_riskManager.Update();
    g_propSettings.Update();
    g_exitManager.Update();  // Manage open positions
    
    // Process state machine
    ProcessStateMachine(isNewBar);
    
    // Update dashboard if needed
    if(g_dashboard != NULL) {
        g_dashboard.Update();
    }
    
    // Clear flag that we're done processing this symbol
    g_symbolIsProcessing[symbolIndex] = false;
}

//+------------------------------------------------------------------+
//| Manage global risk across all symbols                            |
//+------------------------------------------------------------------+
void ManageGlobalRisk()
{
    // Reset risk used
    g_riskUsed = 0.0;
    
    // Calculate total risk used
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(OrderGetTicket(i))) {
            // Find symbol index
            string orderSymbol = OrderGetString(ORDER_SYMBOL);
            int symbolIndex = -1;
            for(int j = 0; j < g_symbolCount; j++) {
                if(g_enabledSymbols[j] == orderSymbol) {
                    symbolIndex = j;
                    break;
                }
            }
            
            if(symbolIndex >= 0) {
                // Get symbol params
                SymbolParams* symbolParams = g_adaptiveFilters.GetSymbolParams(orderSymbol);
                
                // Add to risk used
                g_riskUsed += g_riskManager.GetRiskPercent() * symbolParams.riskMultiplier;
            }
        }
    }
    
    // Add risk from open positions
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionSelect(PositionGetTicket(i))) {
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            int symbolIndex = -1;
            for(int j = 0; j < g_symbolCount; j++) {
                if(g_enabledSymbols[j] == posSymbol) {
                    symbolIndex = j;
                    break;
                }
            }
            
            if(symbolIndex >= 0) {
                // Get symbol params
                SymbolParams* symbolParams = g_adaptiveFilters.GetSymbolParams(posSymbol);
                
                // Add to risk used
                g_riskUsed += g_riskManager.GetRiskPercent() * symbolParams.riskMultiplier;
            }
        }
    }
    
    // Log excessive risk
    if(g_riskUsed > TotalRiskLimit) {
        static datetime lastRiskWarning = 0;
        if(TimeCurrent() - lastRiskWarning >= 600) { // Log every 10 minutes
            g_logger.Warning("Total risk used (" + DoubleToString(g_riskUsed, 2) + 
                           "%) exceeds limit (" + DoubleToString(TotalRiskLimit, 2) + "%)");
            lastRiskWarning = TimeCurrent();
        }
    }
}

//+------------------------------------------------------------------+
//| Process based on current state                                   |
//+------------------------------------------------------------------+
void ProcessStateMachine(bool isNewBar)
{
    // Get current state
    ENUM_EA_STATE currentState = g_stateMachine.GetCurrentState();
    
    // Process according to state
    switch(currentState) {
        case STATE_INITIALIZING:
            // Transition to scanning
            g_stateMachine.TransitionTo(STATE_SCANNING, "Initialization complete");
            break;
            
        case STATE_SCANNING: {
            // Only scan for signals on new bars
            if(isNewBar) {
                // Check if trading is allowed by the filters
                if(IsTradingAllowed()) {
                    // Check for new signals
                    int signal = g_entryManager.CheckForSignal();
                    
                    if(signal != 0) {
                        g_logger.Info("Signal detected: " + (signal > 0 ? "BUY" : "SELL") + 
                                    " with quality " + DoubleToString(g_entryManager.GetSignalQuality(), 2));
                        
                        // Confirm signal with S/R system
                        bool srConfirmed = g_srSystem.ConfirmSignal(signal);
                        
                        // Confirm signal with PVSRA if enabled
                        bool pvsraConfirmed = true; // Default to true if not using PVSRA
                        if(UsePVSRA) {
                            pvsraConfirmed = g_sonicCore.IsPVSRAConfirming(signal);
                            g_logger.Info("PVSRA confirmation: " + (pvsraConfirmed ? "YES" : "NO"));
                        }
                        
                        // Both systems must confirm
                        if(srConfirmed && (!UsePVSRA || pvsraConfirmed)) {
                            g_logger.Info("Signal confirmed by confirmation systems");
                            g_stateMachine.TransitionTo(STATE_WAITING, "Signal detected and confirmed");
                        }
                        else {
                            g_logger.Info("Signal rejected by confirmation systems");
                            // Stay in scanning state
                        }
                    }
                }
            }
            
            // Always manage open positions
            g_exitManager.ManageExits();
            break;
        }
            
        case STATE_WAITING: {
            // Check if trading conditions are still valid
            if(IsTradingAllowed()) {
                // Prepare entry
                if(g_entryManager.PrepareEntry(g_entryManager.GetCurrentSignal())) {
                    g_stateMachine.TransitionTo(STATE_EXECUTING, "Entry conditions met");
                }
            } else {
                // Trading not allowed, go back to scanning
                g_stateMachine.TransitionTo(STATE_SCANNING, "Trading conditions no longer valid");
            }
            
            // Always manage open positions
            g_exitManager.ManageExits();
            break;
        }
            
        case STATE_EXECUTING: {
            // Declare variables before switch-case
            int retryCount = 0;
            bool executionSuccess = false;
            
            while(retryCount < MaxRetryAttempts && !executionSuccess) {
                executionSuccess = g_entryManager.ExecuteTrade();
                
                if(executionSuccess) {
                    g_logger.Info("Trade executed successfully on attempt " + IntegerToString(retryCount + 1));
                    g_stateMachine.TransitionTo(STATE_MONITORING, "Trade executed");
                    
                    // Update trade statistics
                    g_successfulTrades++;
                    break;
                } else {
                    retryCount++;
                    if(retryCount < MaxRetryAttempts) {
                        g_logger.Warning("Trade execution failed, retrying attempt " + IntegerToString(retryCount + 1));
                        Sleep(RetryDelayMs);
                    }
                }
            }
            
            // If all attempts failed
            if(!executionSuccess) {
                g_logger.Error("Failed to execute trade after " + IntegerToString(MaxRetryAttempts) + " attempts");
                g_stateMachine.TransitionTo(STATE_SCANNING, "Trade execution failed");
                
                // Update trade statistics
                g_failedTrades++;
            }
            break;
        }
            
        case STATE_MONITORING: {
            // Manage open positions
            g_exitManager.ManageExits();
            
            // Check if no open positions
            if(PositionsTotal() == 0) {
                g_stateMachine.TransitionTo(STATE_SCANNING, "No open positions");
            }
            
            // Check for new signals on new bar
            if(isNewBar && IsTradingAllowed()) {
                int signal = g_entryManager.CheckForSignal();
                
                if(signal != 0) {
                    g_logger.Info("New signal detected while monitoring");
                    g_stateMachine.TransitionTo(STATE_WAITING, "New signal detected");
                }
            }
            break;
        }
            
        case STATE_STOPPED: {
            // Check if we can resume trading
            if(g_riskManager.IsTradeAllowed() && !g_riskManager.IsInEmergencyMode()) {
                g_logger.Info("Resuming trading after stop");
                g_stateMachine.TransitionTo(STATE_SCANNING, "Resumed after stop");
            }
            break;
        }
    }
    
    // Update state machine timeouts
    g_stateMachine.Update();
}

//+------------------------------------------------------------------+
//| Check if trading is allowed by all filters                       |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Check risk manager first
    if(!g_riskManager.IsTradeAllowed()) {
        g_logger.Info("Trading not allowed: Risk limits reached");
        return false;
    }
    
    // Check session filter
    if(!g_sessionFilter.IsTradingAllowed()) {
        g_logger.Info("Trading not allowed: Outside allowed sessions");
        return false;
    }
    
    // Check news filter
    if(g_newsFilter.IsNewsTime()) {
        g_logger.Info("Trading not allowed: High impact news nearby");
        return false;
    }
    
    // Check market regime filter
    if(!g_marketRegimeFilter.IsRegimeFavorable()) {
        g_logger.Info("Trading not allowed: Unfavorable market regime");
        return false;
    }
    
    // All checks passed
    return true;
}

//+------------------------------------------------------------------+
//| Expert chart event function                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Forward chart events to dashboard if active
    if(g_dashboard != NULL) {
        g_dashboard.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Expert tester function                                           |
//+------------------------------------------------------------------+
double OnTester()
{
    // Calculate score for optimization
    double balanceDD = TesterStatistics(STAT_BALANCE_DD);
    if(balanceDD <= 0) balanceDD = 0.01; // Avoid division by zero
    
    double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
    if(profitFactor <= 0) profitFactor = 0.01;
    
    double recovery = TesterStatistics(STAT_RECOVERY_FACTOR);
    double profit = TesterStatistics(STAT_PROFIT);
    double sharpe = TesterStatistics(STAT_SHARPE_RATIO);
    double trades = TesterStatistics(STAT_TRADES);
    
    // Ensure valid values
    if(sharpe < 0) sharpe = 0;
    if(trades < 10) return 0; // Too few trades
    
    // Calculate custom score for PropFirm optimization
    double backtestScore = (profit / balanceDD) * profitFactor * recovery * (1 + sharpe/10);
    
    // Log backtest completion
    if(g_logger != NULL) {
        g_logger.Info("Backtest completed");
        g_logger.Info("Statistics: Profit = " + DoubleToString(profit, 2) + 
                     ", DD = " + DoubleToString(balanceDD, 2) + 
                     ", PF = " + DoubleToString(profitFactor, 2) + 
                     ", Score = " + DoubleToString(backtestScore, 2));
    }
    
    return backtestScore;
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
    // Handle trade transactions if needed
    if(g_logger != NULL && trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        double dealProfit = 0.0;
        
        // Get deal info using API
        if(!HistoryDealSelect(trans.deal)) {
            g_logger.Warning("Cannot select deal " + IntegerToString(trans.deal));
            return;
        }
        
        dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
        
        g_logger.Info("New deal: " + IntegerToString(trans.deal) + ", Order: " + 
                     IntegerToString(trans.order) + ", Volume: " + DoubleToString(trans.volume, 2) + 
                     ", Profit: " + DoubleToString(dealProfit, 2));
        
        // Update P/L statistics
        if(dealProfit > 0) {
            g_totalProfit += dealProfit;
            
            // Update adaptive filters with winning trade result
            if(UseAdaptiveFilters && g_adaptiveFilters != NULL) {
                g_adaptiveFilters.UpdateBasedOnResults(true, _Symbol);
            }
        } else if(dealProfit < 0) {
            g_totalLoss += MathAbs(dealProfit);
            
            // Update adaptive filters with losing trade result
            if(UseAdaptiveFilters && g_adaptiveFilters != NULL) {
                g_adaptiveFilters.UpdateBasedOnResults(false, _Symbol);
            }
        }
    }
}

// Initializing dashboard components
void InitializeDashboard()
{
    // Initialize dashboard if required
    if(DisplayDashboard) {
        g_dashboard = new CDashboard();
        if(g_dashboard == NULL) {
            g_logger.Warning("Failed to initialize Dashboard. Continuing without dashboard.");
        }
        else {
            g_dashboard.SetLogger(g_logger);
            g_dashboard.SetDependencies(g_sonicCore, g_riskManager, g_stateMachine, g_propSettings);
            g_dashboard.SetAdaptiveFilters(g_adaptiveFilters); // Set adaptive filters for dashboard
            g_dashboard.SetPVSRA(g_pvsra); // Set PVSRA for dashboard
            
            // Set colors for dashboard
            g_dashboard.SetColors(BullishColor, BearishColor, NeutralColor, TextColor, BackgroundColor);
            g_dashboard.SetFontSize(FontSize);
            g_dashboard.SetShowDetailedStats(ShowDetailedStats);
            
            g_dashboard.Create();
        }
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
    
    // Resize other arrays
    ArrayResize(g_lastBarTimes, g_symbolCount);
    ArrayResize(g_symbolIsProcessing, g_symbolCount);
    ArrayResize(g_tradeCounts, g_symbolCount);
    
    // Initialize arrays
    for(int i = 0; i < g_symbolCount; i++)
    {
        g_lastBarTimes[i] = 0;
        g_symbolIsProcessing[i] = false;
        g_tradeCounts[i] = 0;
    }
    
    // Log the enabled symbols
    string symbolList = "Multi-Symbol Trading enabled for: ";
    for(int i = 0; i < g_symbolCount; i++)
    {
        symbolList += g_enabledSymbols[i];
        if(i < g_symbolCount - 1) symbolList += ", ";
    }
    g_logger.Info(symbolList);
}

//+------------------------------------------------------------------+
//| Add a symbol to the enabled list if valid                         |
//+------------------------------------------------------------------+
void AddSymbolIfEnabled(string symbol, bool checkIfExists = false)
{
    // Check if symbol exists in the Market Watch
    if(!SymbolSelect(symbol, true))
    {
        g_logger.Warning("Symbol " + symbol + " not found in Market Watch, skipping");
        return;
    }
    
    // Check if we already have this symbol (if required)
    if(checkIfExists)
    {
        for(int i = 0; i < g_symbolCount; i++)
        {
            if(g_enabledSymbols[i] == symbol)
            {
                return; // Symbol already in the list
            }
        }
    }
    
    // Add symbol to the list
    g_symbolCount++;
    ArrayResize(g_enabledSymbols, g_symbolCount);
    g_enabledSymbols[g_symbolCount - 1] = symbol;
}

//+------------------------------------------------------------------+
//| Process a single symbol                                          |
//+------------------------------------------------------------------+
void ProcessSymbol(int symbolIndex)
{
    if(symbolIndex < 0 || symbolIndex >= g_symbolCount) return;
    
    string symbol = g_enabledSymbols[symbolIndex];
    g_symbolIsProcessing[symbolIndex] = true;
    
    // Check if this is the current chart symbol
    bool isCurrentSymbol = (symbol == _Symbol);
    
    // Get current bar time for this symbol
    datetime currentBarTime = iTime(symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != g_lastBarTimes[symbolIndex]);
    
    if(isNewBar)
    {
        g_lastBarTimes[symbolIndex] = currentBarTime;
        g_logger.Debug("New bar for " + symbol + " at " + TimeToString(currentBarTime));
        
        // Get symbol-specific parameters
        SymbolParams* symbolParams = g_adaptiveFilters.GetSymbolParams(symbol);
        
        // Check if trading is allowed for this symbol
        if(!symbolParams.isEnabled)
        {
            g_logger.Debug("Trading for " + symbol + " is disabled in symbol parameters");
            g_symbolIsProcessing[symbolIndex] = false;
            return;
        }
        
        // Check if maximum daily trades for this symbol reached
        if(g_tradeCounts[symbolIndex] >= symbolParams.maxTradesPerDay)
        {
            g_logger.Debug("Max daily trades reached for " + symbol + ": " + IntegerToString(g_tradeCounts[symbolIndex]));
            g_symbolIsProcessing[symbolIndex] = false;
            return;
        }
        
        // Only process further if it's the current chart symbol or multi-symbol trading is enabled
        if(isCurrentSymbol || EnableMultiSymbolTrading)
        {
            // For current chart symbol, use the standard processing in OnTick
            if(isCurrentSymbol)
            {
                // This is handled by the main OnTick function
            }
            else
            {
                // For other symbols, use a different approach
                ProcessOtherSymbol(symbolIndex);
            }
        }
    }
    
    g_symbolIsProcessing[symbolIndex] = false;
}

//+------------------------------------------------------------------+
//| Process a non-chart symbol                                       |
//+------------------------------------------------------------------+
void ProcessOtherSymbol(int symbolIndex)
{
    if(symbolIndex < 0 || symbolIndex >= g_symbolCount) return;
    
    string symbol = g_enabledSymbols[symbolIndex];
    
    // Get symbol-specific parameters
    SymbolParams* symbolParams = g_adaptiveFilters.GetSymbolParams(symbol);
    
    // Check spread
    double currentSpread = SymbolInfoInteger(symbol, SYMBOL_SPREAD) * SymbolInfoDouble(symbol, SYMBOL_POINT);
    if(currentSpread > symbolParams.spreadMaxPoints * SymbolInfoDouble(symbol, SYMBOL_POINT))
    {
        g_logger.Debug(symbol + " spread too high: " + DoubleToString(currentSpread, 5) + 
                      " > " + DoubleToString(symbolParams.spreadMaxPoints * SymbolInfoDouble(symbol, SYMBOL_POINT), 5));
        return;
    }
    
    // Check if we have enough risk available
    double riskForSymbol = g_riskManager.GetRiskPercent() * symbolParams.riskMultiplier;
    if(g_riskUsed + riskForSymbol > TotalRiskLimit)
    {
        g_logger.Debug("Not enough risk available for " + symbol + ". Used: " + 
                      DoubleToString(g_riskUsed, 2) + "%, Needed: " + DoubleToString(riskForSymbol, 2) + 
                      "%, Limit: " + DoubleToString(TotalRiskLimit, 2) + "%");
        return;
    }
    
    // Check correlation if we have open positions
    if(PositionsTotal() > 0)
    {
        // TODO: Implement correlation check
    }
    
    // Process signals for this symbol
    // This would need to be implemented with symbol-specific versions of your signal processing
    // For now, we'll just log that we would process it
    g_logger.Info("Processing signals for " + symbol);
    
    // Placeholder for signal processing
    // In a real implementation, you would:
    // 1. Fetch data for this symbol
    // 2. Run your strategy on this data
    // 3. Execute trades if signals are found
    
    // After processing, update your risk used
    // g_riskUsed += riskForSymbol; // Uncomment when actually implementing trades
}