//+------------------------------------------------------------------+
//|                                             SonicR_PropFirm.mq5 |
//|                         SonicR PropFirm EA - Optimized for PropFirms |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"
#property version   "1.70"
#property strict
#property description "SonicR PropFirm EA - Price Action based EA optimized for PropFirm challenges"

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

// State variables
bool g_initialized = false;
bool g_shutdownRequested = false;
datetime g_lastMarketRegimeCheck = 0;
int g_successfulTrades = 0;
int g_failedTrades = 0;
double g_totalProfit = 0.0;
double g_totalLoss = 0.0;
datetime g_lastBarTime = 0;

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
    
    g_logger.Info("Initializing SonicR PropFirm EA v1.70...");
    
    // Initialize MT5 trade object
    g_trade = new CTrade();
    if(g_trade == NULL) {
        g_logger.Error("Failed to initialize Trade object");
        return INIT_FAILED;
    }
    
    g_trade.SetExpertMagicNumber(MagicNumber);
    g_trade.SetDeviationInPoints(SlippagePoints);
    g_trade.LogLevel(LOG_LEVEL_ERRORS); // Only log errors from trade object
    
    // Initialize SR system
    g_srSystem = new CSonicRSR();
    if(g_srSystem == NULL) {
        g_logger.Error("Failed to initialize SR system");
        return INIT_FAILED;
    }
    
    if(!g_srSystem.Initialize()) {
        g_logger.Error("Failed to initialize SR system indicators");
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
    if(DisplayDashboard) {
        g_dashboard = new CDashboard();
        if(g_dashboard == NULL) {
            g_logger.Warning("Failed to initialize Dashboard. Continuing without dashboard.");
        }
        else {
            g_dashboard.SetDependencies(g_sonicCore, g_riskManager, g_stateMachine, g_propSettings);
            g_dashboard.Create();
        }
    }
    
    // Update PropFirm settings
    g_propSettings.Update();
    
    // Log successful initialization
    g_logger.Info("Initialization complete. Running in " + EnumToString(g_propSettings.GetPhase()) + 
                " phase for " + EnumToString(g_propSettings.GetPropFirm()));
    
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
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Skip if not initialized or shutdown requested
    if(!g_initialized || g_shutdownRequested) {
        return;
    }
    
    // Check for new bar
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != g_lastBarTime);
    
    if(isNewBar) {
        g_lastBarTime = currentBarTime;
        g_logger.Debug("New bar opened at " + TimeToString(currentBarTime));
        
        // Update market regime on new bar, but not every bar (hourly check)
        if(TimeCurrent() - g_lastMarketRegimeCheck >= 3600) { // Update every hour
            g_marketRegimeFilter.Update(g_sonicCore);
            g_lastMarketRegimeCheck = TimeCurrent();
            
            // Log current market regime
            g_logger.Info("Current market regime: " + g_marketRegimeFilter.GetCurrentRegimeAsString());
        }
    }
    
    // Update core components
    g_sonicCore.Update();
    g_riskManager.Update();
    g_propSettings.Update();
    g_exitManager.Update();
    
    // Process actions based on state machine
    ProcessStateMachine(isNewBar);
    
    // Update dashboard if active
    if(g_dashboard != NULL) {
        g_dashboard.Update();
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
                        if(g_srSystem.ConfirmSignal(signal)) {
                            g_logger.Info("Signal confirmed by SR system");
                            g_stateMachine.TransitionTo(STATE_WAITING, "Signal detected and confirmed");
                        }
                        else {
                            g_logger.Info("Signal rejected by SR system");
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
        } else if(dealProfit < 0) {
            g_totalLoss += MathAbs(dealProfit);
        }
    }
}