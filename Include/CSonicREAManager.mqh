//+------------------------------------------------------------------+
//| CSonicREAManager.mqh                                             |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include MQL5 Standard Library
#include <stdlib.mqh>      // For string conversions, NULL
#include <Trade\Trade.mqh> // For CTrade, AccountInfo..., SymbolInfo...
#include <Object.mqh>     // For CObject, MqlDateTime, TimeToString etc.
#include <Charts\ChartObjects.mqh> // For chart objects and events

// Include core functionality
#include "Constants.mqh"
#include "Enums.mqh"
#include "Structs.mqh"

// Include component modules
#include "CIndicatorManager.mqh"
#include "CSRManager.mqh"
#include "CTradeManager.mqh"
#include "CRiskManager.mqh"
#include "CFilterManager.mqh"
#include "CSession.mqh"
#include "CLogger.mqh"
#include "CDashboard.mqh"

//+------------------------------------------------------------------+
//| Main EA Manager Class                                            |
//+------------------------------------------------------------------+
class CSonicREAManager {
private:
    // Components
    CIndicatorManager* m_indicators;     // Manages all indicators and signals
    CSRManager* m_srManager;             // Manages support/resistance levels
    CTradeManager* m_tradeManager;       // Manages trade execution and monitoring
    CRiskManager* m_riskManager;         // Manages risk calculations
    CFilterManager* m_filterManager;     // Manages various filters
    CSession* m_session;                 // Manages trading sessions
    CLogger* m_logger;                   // Handles logging and reporting
    CDashboard* m_dashboard;             // Manages visual dashboard

    // EA Settings
    string m_symbol;                     // Trading symbol
    ENUM_TIMEFRAMES m_timeframe;         // Main timeframe
    int m_magicNumber;                   // EA Magic number
    
    // EA State
    bool m_initialized;                  // Initialization flag
    bool m_isPaused;                     // Pause flag
    bool m_isEmergencyMode;              // Emergency mode flag
    
    // PropFirm Settings
    ENUM_PROP_FIRM_TYPE m_propFirmType;
    ENUM_CHALLENGE_PHASE m_challengePhase;
    
    // Risk Management Settings
    double m_riskPercent;
    double m_maxDailyDrawdown;
    double m_maxTotalDrawdown;
    int m_maxDailyTrades;
    int m_maxConcurrentTrades;
    double m_portfolioMaxRisk;
    double m_maxCorrelationThreshold;
    
    // Order Management Settings
    double m_partialClosePercent;
    double m_breakEvenLevel;
    double m_trailingActivationR;
    double m_takeProfitMultiplier1;
    int m_maxRetryAttempts;
    int m_retryDelayMs;
    
    // SuperTrend Settings
    int m_superTrendPeriod;
    double m_superTrendMultiplier;
    
    // Strategy Settings
    int m_ema34Period;
    int m_ema89Period;
    int m_ema200Period;
    int m_adxPeriod;
    double m_adxThreshold;
    int m_macdFastPeriod;
    int m_macdSlowPeriod;
    int m_macdSignalPeriod;
    int m_atrPeriod;
    int m_requiredConfluenceScore;
    
    // Market Filter Settings
    bool m_useNewsFilter;
    int m_newsBefore;
    int m_newsAfter;
    bool m_useSessionFilter;
    int m_gmtOffset;
    bool m_useADXFilter;
    bool m_usePropFirmHoursFilter;
    
    // UI Settings
    bool m_enableDashboard;
    int m_dashboardX;
    int m_dashboardY;
    color m_bullishColor;
    color m_bearishColor;
    color m_neutralColor;
    
    // Logging Settings
    bool m_enableDetailedLogging;
    bool m_saveDailyReports;
    bool m_enableEmailAlerts;
    bool m_enablePushNotifications;
    int m_logLevel;
    
    // Private methods for internal logic
    
    // Clean up components when initialization fails
    void CleanupComponents() {
        if (m_indicators != NULL) {
            delete m_indicators;
            m_indicators = NULL;
        }
        
        if (m_srManager != NULL) {
            delete m_srManager;
            m_srManager = NULL;
        }
        
        if (m_tradeManager != NULL) {
            delete m_tradeManager;
            m_tradeManager = NULL;
        }
        
        if (m_riskManager != NULL) {
            delete m_riskManager;
            m_riskManager = NULL;
        }
        
        if (m_filterManager != NULL) {
            delete m_filterManager;
            m_filterManager = NULL;
        }
        
        if (m_session != NULL) {
            delete m_session;
            m_session = NULL;
        }
        
        if (m_dashboard != NULL) {
            delete m_dashboard;
            m_dashboard = NULL;
        }
        
        // Logger should be deleted last as other components might try to log during cleanup
        if (m_logger != NULL) {
            delete m_logger;
            m_logger = NULL;
        }
    }
    
    // Checks if trading conditions are favorable
    bool CanTrade() {
        // Check if EA is paused
        if (m_isPaused) {
            if (m_logger != NULL) {
                m_logger->Debug("EA is paused, no trading allowed");
            }
            return false;
        }
        
        // Check if in emergency mode
        if (m_isEmergencyMode) {
            if (m_logger != NULL) {
                m_logger->Warning("EA is in emergency mode, trading with reduced risk");
            }
            // We don't return false here, just let RiskManager reduce the risk
        }
        
        // Let the filter manager check all filters
        if (m_filterManager != NULL && !m_filterManager->IsMarketConditionFavorable()) {
            // FilterManager will log the specific reasons
            return false;
        }
        
        // Check if risk limits allow new trades
        if (m_riskManager != NULL && !m_riskManager->CanOpenNewTrade()) {
            // RiskManager will log the specific reasons and already checks portfolio risk
            return false;
        }
        
        // All checks passed
        return true;
    }
    
    // Process signals and execute trades if conditions are favorable
    void ProcessSignals() {
        // Skip if indicators manager isn't initialized
        if (m_indicators == NULL) return;
        
        // Skip if no signals
        if (!m_indicators->IsBuySignalActive() && !m_indicators->IsSellSignalActive()) {
            return;
        }
        
        // Check if we can trade
        if (!CanTrade()) {
            if (m_logger != NULL) {
                m_logger->Info("Trading conditions not met, skipping signals");
            }
            return;
        }
        
        // Process buy signal
        if (m_indicators->IsBuySignalActive()) {
            if (m_logger != NULL) {
                m_logger->Info("Buy signal detected, executing order...");
            }
            
            // Calculate entry parameters
            double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
            double stopLoss = m_indicators->CalculateBuyStopLoss();
            
            // Get adjusted risk % *before* calculating lot size
            double adjustedRiskPercent = m_riskManager != NULL ? m_riskManager->GetAdjustedRiskPercent() : m_riskPercent;

            // Calculate lot size based on risk
            double lotSize = m_riskManager != NULL ? m_riskManager->CalculateLotSize(entryPrice, stopLoss) : 0.01;
            
            if (lotSize <= 0) {
                if (m_logger != NULL) {
                    m_logger->Warning("Invalid lot size calculated, skipping buy order");
                }
                return;
            }
            
            // Execute the order
            if (m_tradeManager != NULL && m_tradeManager->ExecuteBuyOrder(entryPrice, stopLoss, lotSize)) {
                if (m_logger != NULL) {
                    m_logger->Info("Buy order executed successfully");
                }
                
                // Track the new trade in risk manager
                if (m_riskManager != NULL) {
                    m_riskManager->TrackNewTrade();
                    // Add the used risk percentage to portfolio risk
                    m_riskManager->AddPortfolioRisk(adjustedRiskPercent);
                }
            }
        }
        
        // Process sell signal
        if (m_indicators->IsSellSignalActive()) {
            if (m_logger != NULL) {
                m_logger->Info("Sell signal detected, executing order...");
            }
            
            // Calculate entry parameters
            double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
            double stopLoss = m_indicators->CalculateSellStopLoss();
            
            // Get adjusted risk % *before* calculating lot size
            double adjustedRiskPercent = m_riskManager != NULL ? m_riskManager->GetAdjustedRiskPercent() : m_riskPercent;

            // Calculate lot size based on risk
            double lotSize = m_riskManager != NULL ? m_riskManager->CalculateLotSize(entryPrice, stopLoss) : 0.01;
            
            if (lotSize <= 0) {
                if (m_logger != NULL) {
                    m_logger->Warning("Invalid lot size calculated, skipping sell order");
                }
                return;
            }
            
            // Execute the order
            if (m_tradeManager != NULL && m_tradeManager->ExecuteSellOrder(entryPrice, stopLoss, lotSize)) {
                if (m_logger != NULL) {
                    m_logger->Info("Sell order executed successfully");
                }
                
                // Track the new trade in risk manager
                if (m_riskManager != NULL) {
                    m_riskManager->TrackNewTrade();
                    // Add the used risk percentage to portfolio risk
                    m_riskManager->AddPortfolioRisk(adjustedRiskPercent);
                }
            }
        }
    }
    
public:
    // Constructor & Destructor
    CSonicREAManager(string symbol = NULL, ENUM_TIMEFRAMES timeframe = PERIOD_H1) {
        // Initialize member variables
        m_symbol = (symbol == NULL || symbol == "") ? Symbol() : symbol;
        m_timeframe = timeframe;
        m_magicNumber = DEFAULT_MAGIC_NUMBER;  // Set default, can be changed
        
        // Initialize component pointers
        m_indicators = NULL;
        m_srManager = NULL;
        m_tradeManager = NULL;
        m_riskManager = NULL;
        m_filterManager = NULL;
        m_session = NULL;
        m_logger = NULL;
        m_dashboard = NULL;
        
        // Set state to defaults
        m_initialized = false;
        m_isPaused = false;
        m_isEmergencyMode = false;
        
        // Initialize settings to default values
        // PropFirm
        m_propFirmType = PROP_FIRM_FTMO;
        m_challengePhase = PHASE_CHALLENGE;
        
        // Risk
        m_riskPercent = DEFAULT_RISK_PERCENT;
        m_maxDailyDrawdown = DEFAULT_MAX_DAILY_DD;
        m_maxTotalDrawdown = DEFAULT_MAX_TOTAL_DD;
        m_maxDailyTrades = DEFAULT_MAX_DAILY_TRADES;
        m_maxConcurrentTrades = DEFAULT_MAX_CONCURRENT;
        m_portfolioMaxRisk = 5.0;
        m_maxCorrelationThreshold = 0.7;
        
        // Order
        m_partialClosePercent = DEFAULT_PARTIAL_CLOSE;
        m_breakEvenLevel = DEFAULT_BE_LEVEL;
        m_trailingActivationR = DEFAULT_TRAILING_LEVEL;
        m_takeProfitMultiplier1 = DEFAULT_TP1_MULTIPLIER;
        m_maxRetryAttempts = DEFAULT_MAX_RETRY;
        m_retryDelayMs = DEFAULT_RETRY_DELAY;
        
        // SuperTrend
        m_superTrendPeriod = DEFAULT_SUPERTREND_PERIOD;
        m_superTrendMultiplier = DEFAULT_SUPERTREND_MULT;
        
        // Strategy
        m_ema34Period = DEFAULT_EMA34_PERIOD;
        m_ema89Period = DEFAULT_EMA89_PERIOD;
        m_ema200Period = DEFAULT_EMA200_PERIOD;
        m_adxPeriod = DEFAULT_ADX_PERIOD;
        m_adxThreshold = DEFAULT_ADX_THRESHOLD;
        m_macdFastPeriod = DEFAULT_MACD_FAST;
        m_macdSlowPeriod = DEFAULT_MACD_SLOW;
        m_macdSignalPeriod = DEFAULT_MACD_SIGNAL;
        m_atrPeriod = DEFAULT_ATR_PERIOD;
        m_requiredConfluenceScore = 2;
        
        // Market Filters
        m_useNewsFilter = true;
        m_newsBefore = DEFAULT_NEWS_BEFORE;
        m_newsAfter = DEFAULT_NEWS_AFTER;
        m_useSessionFilter = true;
        m_gmtOffset = DEFAULT_GMT_OFFSET;
        m_useADXFilter = true;
        m_usePropFirmHoursFilter = true;
        
        // UI
        m_enableDashboard = true;
        m_dashboardX = DASHBOARD_X;
        m_dashboardY = DASHBOARD_Y;
        m_bullishColor = clrGreen;
        m_bearishColor = clrRed;
        m_neutralColor = clrGray;
        
        // Logging
        m_enableDetailedLogging = true;
        m_saveDailyReports = true;
        m_enableEmailAlerts = false;
        m_enablePushNotifications = false;
        m_logLevel = 2; // INFO
    }
    
    ~CSonicREAManager() {
        // Clean up components to prevent memory leaks
        CleanupComponents();
    }
    
    // Initialize the EA and all components
    bool Initialize() {
        // Prevent double initialization
        if (m_initialized) {
            return true;
        }
        
        // Create and initialize the logger first (for error messages)
        m_logger = new CLogger();
        if (m_logger == NULL) {
            Print("ERROR: Failed to create Logger");
            return false;
        }
        
        // Initialize logger with settings
        if (!m_logger->Initialize(
                m_enableDetailedLogging,  
                (ENUM_LOG_LEVEL)m_logLevel,
                m_enableEmailAlerts,
                m_enablePushNotifications)) {
            Print("ERROR: Failed to initialize Logger");
            delete m_logger;  // Clean up the logger
            m_logger = NULL;
            return false;
        }
        
        m_logger->Info("Initializing SonicR PropFirm EA v3.0");
        
        // Initialize session manager
        m_logger->Debug("Creating Session Manager");
        m_session = new CSession(m_gmtOffset);
        if (m_session == NULL) {
            m_logger->Error("Failed to create Session Manager");
            CleanupComponents();  // Clean up all components
            return false;
        }
        m_session->SetUseSessionFilter(m_useSessionFilter);
        m_logger->Debug("Session Manager created successfully");
        
        // Initialize SR Manager
        m_logger->Debug("Creating SR Manager");
        m_srManager = new CSRManager(m_symbol, m_timeframe);
        if (m_srManager == NULL) {
            m_logger->Error("Failed to create SR Manager");
            CleanupComponents();
            return false;
        }
        if (!m_srManager->Initialize()) {
            m_logger->Error("Failed to initialize SR Manager");
            CleanupComponents();
            return false;
        }
        m_logger->Debug("SR Manager initialized successfully");
        
        // Initialize indicator manager
        m_logger->Debug("Creating Indicator Manager");
        m_indicators = new CIndicatorManager(m_symbol, m_timeframe);
        if (m_indicators == NULL) {
            m_logger->Error("Failed to create Indicator Manager");
            CleanupComponents();
            return false;
        }
        
        // Configure indicator manager with settings
        m_indicators->SetEMAPeriods(m_ema34Period, m_ema89Period, m_ema200Period);
        m_indicators->SetADXPeriod(m_adxPeriod);
        m_indicators->SetMACDParameters(m_macdFastPeriod, m_macdSlowPeriod, m_macdSignalPeriod);
        m_indicators->SetATRPeriod(m_atrPeriod);
        m_indicators->SetRequiredConfluenceScore(m_requiredConfluenceScore);
        m_indicators->SetSRManager(m_srManager); // Connect to SR Manager
        
        // Initialize indicator manager
        if (!m_indicators->Initialize()) {
            m_logger->Error("Failed to initialize Indicator Manager");
            CleanupComponents();
            return false;
        }
        m_logger->Debug("Indicator Manager initialized successfully");
        
        // Initialize risk manager
        m_logger->Debug("Creating Risk Manager");
        m_riskManager = new CRiskManager();
        if (m_riskManager == NULL) {
            m_logger->Error("Failed to create Risk Manager");
            CleanupComponents();
            return false;
        }
        
        // Configure risk manager with settings
        m_riskManager->SetRiskPercent(m_riskPercent);
        m_riskManager->SetMaxDailyDrawdown(m_maxDailyDrawdown);
        m_riskManager->SetMaxTotalDrawdown(m_maxTotalDrawdown);
        m_riskManager->SetMaxDailyTrades(m_maxDailyTrades);
        m_riskManager->SetMaxConcurrentTrades(m_maxConcurrentTrades);
        m_riskManager->SetPortfolioMaxRisk(m_portfolioMaxRisk);
        m_riskManager->SetMaxCorrelationThreshold(m_maxCorrelationThreshold);
        m_riskManager->SetPropFirmSettings(m_propFirmType, m_challengePhase);
        m_riskManager->SetLogger(m_logger); // Connect to Logger
        
        // Initialize risk manager
        if (!m_riskManager->Initialize()) {
            m_logger->Error("Failed to initialize Risk Manager");
            CleanupComponents();
            return false;
        }
        m_logger->Debug("Risk Manager initialized successfully");
        
        // Initialize trade manager
        m_logger->Debug("Creating Trade Manager");
        m_tradeManager = new CTradeManager(m_symbol, m_magicNumber);
        if (m_tradeManager == NULL) {
            m_logger->Error("Failed to create Trade Manager");
            CleanupComponents();
            return false;
        }
        
        // Configure trade manager with settings
        m_tradeManager->SetPartialClosePercent(m_partialClosePercent);
        m_tradeManager->SetBreakEvenLevel(m_breakEvenLevel);
        m_tradeManager->SetTrailingActivationR(m_trailingActivationR);
        m_tradeManager->SetTakeProfitMultiplier(m_takeProfitMultiplier1);
        m_tradeManager->SetMaxRetryAttempts(m_maxRetryAttempts);
        m_tradeManager->SetRetryDelayMs(m_retryDelayMs);
        m_tradeManager->SetSuperTrendParameters(m_superTrendPeriod, m_superTrendMultiplier);
        m_tradeManager->SetLogger(m_logger); // Connect to Logger
        
        // Initialize trade manager
        if (!m_tradeManager->Initialize()) {
            m_logger->Error("Failed to initialize Trade Manager");
            CleanupComponents();
            return false;
        }
        m_logger->Debug("Trade Manager initialized successfully");
        
        // Initialize filter manager
        m_logger->Debug("Creating Filter Manager");
        m_filterManager = new CFilterManager();
        if (m_filterManager == NULL) {
            m_logger->Error("Failed to create Filter Manager");
            CleanupComponents();
            return false;
        }
        
        // Configure filter manager
        m_filterManager->SetNewsFilter(m_useNewsFilter, m_newsBefore, m_newsAfter);
        m_filterManager->SetADXFilter(m_useADXFilter, m_adxThreshold);
        m_filterManager->SetPropFirmHoursFilter(m_usePropFirmHoursFilter);
        m_filterManager->SetPropFirmSettings(m_propFirmType, m_challengePhase);
        m_filterManager->SetSymbol(m_symbol);
        m_filterManager->SetIndicatorManager(m_indicators); // Connect to Indicators
        m_filterManager->SetSession(m_session); // Connect to Session
        m_filterManager->SetLogger(m_logger); // Connect to Logger
        
        // Initialize filter manager
        if (!m_filterManager->Initialize()) {
            m_logger->Error("Failed to initialize Filter Manager");
            CleanupComponents();
            return false;
        }
        m_logger->Debug("Filter Manager initialized successfully");
        
        // Initialize dashboard if enabled
        if (m_enableDashboard) {
            m_logger->Debug("Creating Dashboard");
            m_dashboard = new CDashboard();
            if (m_dashboard == NULL) {
                m_logger->Warning("Failed to create Dashboard, continuing without visual display");
            } else {
                // Configure dashboard
                m_dashboard->SetPosition(m_dashboardX, m_dashboardY);
                m_dashboard->SetColors(m_bullishColor, m_bearishColor, m_neutralColor);
                m_dashboard->SetLogger(m_logger); // Connect to Logger
                
                // Set data providers
                m_dashboard->SetIndicatorManager(m_indicators);
                m_dashboard->SetTradeManager(m_tradeManager);
                m_dashboard->SetRiskManager(m_riskManager);
                m_dashboard->SetFilterManager(m_filterManager);
                
                // Initialize dashboard
                if (!m_dashboard->Initialize()) {
                    m_logger->Warning("Failed to initialize Dashboard, continuing without visual display");
                    delete m_dashboard;
                    m_dashboard = NULL;
                } else {
                    m_logger->Debug("Dashboard initialized successfully");
                }
            }
        }
        
        // Sync with existing trades for the current symbol
        if (m_tradeManager != NULL) {
            m_tradeManager->SyncExistingTrades();
        }
        
        // All components initialized successfully
        m_initialized = true;
        m_logger->Info("SonicR PropFirm EA v3.0 initialized successfully");
        
        return true;
    }
    
    // Process tick event
    void ProcessTick() {
        // Skip if not initialized
        if (!m_initialized) return;
        
        // Skip processing if paused except for dashboard updates
        if (m_isPaused) {
            if (m_dashboard != NULL) {
                m_dashboard->Update();
            }
            return;
        }
        
        // Optimize trade management (not every tick)
        static datetime lastManageTime = 0;
        datetime currentTime = TimeCurrent();
        
        // Only manage trades every 15 seconds or on new bar
        if (currentTime - lastManageTime >= 15) {
            if (m_tradeManager != NULL) {
                m_tradeManager->ManageOpenTrades();
            }
            lastManageTime = currentTime;
        }
        
        // Update dashboard if enabled
        if (m_dashboard != NULL) {
            m_dashboard->Update();
        }
    }
    
    // Process new bar event
    void ProcessNewBar() {
        // Skip if not initialized
        if (!m_initialized) return;
        
        // Skip processing if paused
        if (m_isPaused) return;
        
        // Log new bar
        if (m_logger != NULL) {
            m_logger->Debug("Processing new bar: " + TimeToString(iTime(m_symbol, m_timeframe, 0)));
        }
        
        // Update SR Manager
        if (m_srManager != NULL) {
            if (!m_srManager->Update()) {
                if (m_logger != NULL) {
                    m_logger->Error("Failed to update SR Manager, skipping this bar");
                }
                return;
            }
        }
        
        // Update indicators
        if (m_indicators != NULL) {
            if (!m_indicators->Update()) {
                if (m_logger != NULL) {
                    m_logger->Error("Failed to update indicators, skipping this bar");
                }
                return;
            }
            
            // Check for new entry signals
            m_indicators->CheckEntrySignals();
        }
        
        // Update risk metrics
        if (m_riskManager != NULL) {
            m_riskManager->UpdateMetrics();
        }
        
        // Process signals if any
        ProcessSignals();
        
        // Reset emergency mode if conditions are favorable
        if (m_isEmergencyMode && m_riskManager != NULL && m_riskManager->CanResetEmergencyMode()) {
            m_isEmergencyMode = false;
            if (m_logger != NULL) {
                m_logger->Info("Emergency mode deactivated, normal trading resumed");
            }
        }
    }
    
    // Process timer event (called every second)
    void ProcessTimer() {
        // Update risk metrics frequently for accurate drawdown monitoring
        if (m_riskManager != NULL) {
            m_riskManager->UpdateMetrics();
            
            // Check for emergency mode trigger after updating metrics
            if (!m_isEmergencyMode && m_riskManager->IsTotalDrawdownExceeded()) {
                ActivateEmergencyMode();
            }
            // Optionally, add logic to auto-deactivate emergency mode if conditions improve
            else if (m_isEmergencyMode && m_riskManager->CanResetEmergencyMode()) {
                // DeactivateEmergencyMode(); // Decide if this should be automatic
            }
        }
        
        // Update dashboard periodically
        if (m_dashboard != NULL && m_enableDashboard) {
            m_dashboard->Update();
        }
        
        // Perform other less frequent periodic tasks (e.g., every minute)
        static datetime lastMinuteCheck = 0;
        datetime currentTime = TimeCurrent();
        
        if (currentTime - lastMinuteCheck >= 60) {
            // Update filter data (e.g., news)
            if (m_filterManager != NULL) {
                m_filterManager->Update();
            }
            
            // Reset daily metrics if needed
            if (m_riskManager != NULL && m_riskManager->ShouldResetDailyMetrics()) {
                m_riskManager->ResetDailyMetrics();
                if (m_logger != NULL) {
                    m_logger->SaveDailyReport(); // Save report at day reset
                }
            }
            
            lastMinuteCheck = currentTime;
        }
    }
    
    // Process chart event
    bool ProcessChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam) {
        // Skip if not initialized
        if (!m_initialized) return false;
        
        // Process dashboard events if enabled
        if (m_dashboard != NULL && id == CHARTEVENT_OBJECT_CLICK) {
            return m_dashboard->ProcessEvents(id, lparam, dparam, sparam);
        }
        
        return false;
    }
    
    // Deinitialize EA - enhanced to perform more cleanup
    void Deinitialize() {
        // Skip if not initialized
        if (!m_initialized) return;
        
        // Save final reports if enabled
        if (m_saveDailyReports && m_logger != NULL) {
            m_logger->SaveDailyReport();
        }
        
        // Log termination
        if (m_logger != NULL) {
            m_logger->Info("SonicR PropFirm EA v3.0 terminated");
        }
        
        // Reset initialization flag
        m_initialized = false;
    }
    
    //--- Setter methods for configurations
    
    // Set magic number
    void SetMagicNumber(int magicNumber) {
        m_magicNumber = magicNumber;
    }
    
    // Configure PropFirm settings
    void SetPropFirmSettings(ENUM_PROP_FIRM_TYPE type, ENUM_CHALLENGE_PHASE phase) {
        m_propFirmType = type;
        m_challengePhase = phase;
    }
    
    // Configure risk parameters
    void SetRiskParameters(
        double riskPercent,
        double maxDailyDrawdown,
        double maxTotalDrawdown,
        int maxDailyTrades,
        int maxConcurrentTrades,
        double portfolioMaxRisk,
        double maxCorrelationThreshold
    ) {
        m_riskPercent = riskPercent;
        m_maxDailyDrawdown = maxDailyDrawdown;
        m_maxTotalDrawdown = maxTotalDrawdown;
        m_maxDailyTrades = maxDailyTrades;
        m_maxConcurrentTrades = maxConcurrentTrades;
        m_portfolioMaxRisk = portfolioMaxRisk;
        m_maxCorrelationThreshold = maxCorrelationThreshold;
    }
    
    // Configure order parameters
    void SetOrderParameters(
        double partialClosePercent,
        double breakEvenLevel,
        double trailingActivationR,
        double takeProfitMultiplier1,
        int maxRetryAttempts,
        int retryDelayMs
    ) {
        m_partialClosePercent = partialClosePercent;
        m_breakEvenLevel = breakEvenLevel;
        m_trailingActivationR = trailingActivationR;
        m_takeProfitMultiplier1 = takeProfitMultiplier1;
        m_maxRetryAttempts = maxRetryAttempts;
        m_retryDelayMs = retryDelayMs;
    }
    
    // Configure SuperTrend parameters
    void SetSuperTrendParameters(int period, double multiplier) {
        m_superTrendPeriod = period;
        m_superTrendMultiplier = multiplier;
    }
    
    // Configure strategy parameters
    void SetStrategyParameters(
        int ema34Period,
        int ema89Period,
        int ema200Period,
        int adxPeriod,
        int macdFastPeriod,
        int macdSlowPeriod,
        int macdSignalPeriod,
        int atrPeriod,
        int requiredConfluenceScore
    ) {
        m_ema34Period = ema34Period;
        m_ema89Period = ema89Period;
        m_ema200Period = ema200Period;
        m_adxPeriod = adxPeriod;
        m_macdFastPeriod = macdFastPeriod;
        m_macdSlowPeriod = macdSlowPeriod;
        m_macdSignalPeriod = macdSignalPeriod;
        m_atrPeriod = atrPeriod;
        m_requiredConfluenceScore = requiredConfluenceScore;
    }
    
    // Configure market filters
    void SetMarketFilters(
        bool useNewsFilter,
        int newsBefore,
        int newsAfter,
        bool useSessionFilter,
        int gmtOffset,
        bool useADXFilter,
        double adxThreshold,
        bool usePropFirmHoursFilter
    ) {
        m_useNewsFilter = useNewsFilter;
        m_newsBefore = newsBefore;
        m_newsAfter = newsAfter;
        m_useSessionFilter = useSessionFilter;
        m_gmtOffset = gmtOffset;
        m_useADXFilter = useADXFilter;
        m_adxThreshold = adxThreshold;
        m_usePropFirmHoursFilter = usePropFirmHoursFilter;
    }
    
    // Configure UI parameters
    void SetUIParameters(
        bool enableDashboard,
        int dashboardX,
        int dashboardY,
        color bullishColor,
        color bearishColor,
        color neutralColor
    ) {
        m_enableDashboard = enableDashboard;
        m_dashboardX = dashboardX;
        m_dashboardY = dashboardY;
        m_bullishColor = bullishColor;
        m_bearishColor = bearishColor;
        m_neutralColor = neutralColor;
    }
    
    // Configure logging parameters
    void SetLoggingParameters(
        bool enableDetailedLogging,
        bool saveDailyReports,
        bool enableEmailAlerts,
        bool enablePushNotifications,
        int logLevel
    ) {
        m_enableDetailedLogging = enableDetailedLogging;
        m_saveDailyReports = saveDailyReports;
        m_enableEmailAlerts = enableEmailAlerts;
        m_enablePushNotifications = enablePushNotifications;
        m_logLevel = logLevel;
    }
    
    //--- Control methods
    
    // Pause EA
    void Pause() {
        if (!m_isPaused) {
            m_isPaused = true;
            if (m_logger != NULL) {
                m_logger->Info("EA paused");
            }
        }
    }
    
    // Resume EA
    void Resume() {
        if (m_isPaused) {
            m_isPaused = false;
            if (m_logger != NULL) {
                m_logger->Info("EA resumed");
            }
        }
    }
    
    // Toggle pause state
    void TogglePause() {
        m_isPaused = !m_isPaused;
        if (m_logger != NULL) {
            m_logger->Info(m_isPaused ? "EA paused" : "EA resumed");
        }
    }
    
    // Activate emergency mode
    void ActivateEmergencyMode() {
        if (!m_isEmergencyMode) {
            m_isEmergencyMode = true;
            if (m_logger != NULL) {
                m_logger->Warning("Emergency mode activated");
            }
        }
    }
    
    // Deactivate emergency mode
    void DeactivateEmergencyMode() {
        if (m_isEmergencyMode) {
            m_isEmergencyMode = false;
            if (m_logger != NULL) {
                m_logger->Info("Emergency mode deactivated");
            }
        }
    }
    
    //--- State getters
    
    // Get pause state
    bool IsPaused() const {
        return m_isPaused;
    }
    
    // Get emergency mode state
    bool IsEmergencyMode() const {
        return m_isEmergencyMode;
    }
    
    // Get current profit
    double GetCurrentProfit() const {
        return m_riskManager != NULL ? m_riskManager->GetCurrentProfit() : 0.0;
    }
    
    // Get current drawdown
    double GetCurrentDrawdown() const {
        return m_riskManager != NULL ? m_riskManager->GetCurrentDrawdown() : 0.0;
    }
    
    // Get open positions count
    int GetOpenPositionsCount() const {
        return m_tradeManager != NULL ? m_tradeManager->GetOpenTradesCount() : 0;
    }
    
    // Get EA status summary
    string GetStatusSummary() const {
        string status = "";
        
        // Add basic EA info
        status += "Symbol: " + m_symbol + "\n";
        status += "Timeframe: " + EnumToString(m_timeframe) + "\n";
        status += "State: " + (m_isPaused ? "Paused" : "Active") + 
                 (m_isEmergencyMode ? " (Emergency Mode)" : "") + "\n";
        
        // Add risk metrics if available
        if (m_riskManager != NULL) {
            status += "Current DD: " + DoubleToString(m_riskManager->GetCurrentDrawdown(), 2) + "%\n";
            status += "Daily DD: " + DoubleToString(m_riskManager->GetDailyDrawdown(), 2) + "%\n";
            status += "Open Trades: " + IntegerToString(GetOpenPositionsCount()) + "\n";
            status += "Daily Trades: " + IntegerToString(m_riskManager->GetDailyTradesCount()) + "\n";
        }
        
        // Add market state if available
        if (m_indicators != NULL) {
            MarketState market = m_indicators->GetMarketState();
            status += "Trend: " + (m_indicators->IsBullishTrend() ? "Bullish" : 
                                  (m_indicators->IsBearishTrend() ? "Bearish" : "Neutral")) + "\n";
            status += "ADX: " + DoubleToString(m_indicators->GetADXValue(), 1) + "\n";
        }
        
        return status;
    }
};