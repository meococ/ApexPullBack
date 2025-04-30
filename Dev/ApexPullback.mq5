//+------------------------------------------------------------------+
//|   ApexPullback MASTER EA v10.5 - Professional Edition            |
//|   Advanced Multi-Market EMA 34/89 Strategy System               |
//|                                                                 |
//|   Core Features:                                                |
//|   - Multi-timeframe trend analysis (H4/H1/M15)                  |
//|   - Advanced Price Action recognition & pullback detection      |
//|   - Adaptive position sizing & multi-stage trailing stops       |
//|   - Smart multi-target profit taking w/ dynamic resistance      |
//|   - Complete risk management suite for professional traders     |
//+------------------------------------------------------------------+

// Include necessary header files
#include <Trade\Trade.mqh>
#include "CommonStructs.mqh"
#include "TradeManager.mqh"
#include "RiskManager.mqh"
#include "MarketMonitor.mqh"
#include "Logger.mqh"

//--- Global variables
int      g_CurrentDay = 0;          // Current day for tracking day changes
double   g_DayStartEquity = 0.0;    // Starting equity for daily tracking
datetime g_LastActionTime = 0;      // Time of last action
datetime g_PauseUntil = 0;          // Time until EA resumes trading
int      g_DayTrades = 0;           // Number of trades today
bool     g_IsInitialized = false;   // Flag indicating EA initialization
CLogger* g_Logger = NULL;           // Global logger object

// Core module objects
CMarketMonitor* Market = NULL;      // Market monitor module
CTradeManager*  TradeMan = NULL;    // Trade management module
CRiskManager*   RiskMan = NULL;     // Risk management module

// News event storage
NewsEvent g_UpcomingNews[];         // Array of upcoming news events

// Dynamic lot sizing globals
bool      g_UseDynamicLotSize = false;   // Use dynamic lot size based on volatility
double    g_MinLotMultiplier = 0.5;      // Minimum multiplier for lot size reduction
double    g_MaxVolatilityFactor = 2.0;   // Maximum volatility factor
double    g_StopLoss = 0.0;              // Stop loss value

// Forward declarations
void    LogMessage(string message, bool important);
string  GetDeinitReasonText(const int reason);
bool    InitializeModules();
void    UpdateDailyStats();
bool    CheckProcessingTime();
bool    IsAllowedTradingSession();
bool    IsNewsImpactPeriod();
bool    CreateDashboard();
void    DeleteDashboard();
void    SavePerformanceStats();
string  TimeframeToString(int tf);
bool    LoadNewsData();
void    UpdateDashboard();
bool    OpenTrade(bool isLong, double entryPrice, double stopLoss, double takeProfit, 
                 double riskAmount, string comment = "");
string  GetScenarioName(ENUM_ENTRY_SCENARIO scenario);
void    AdjustParametersByPreset();
void    ManageAlerts(string message, bool isImportant);
void    CheckNewTradeOpportunities();

//+------------------------------------------------------------------+
//| Return timeframe as string description                           |
//+------------------------------------------------------------------+
string TimeframeToString(int tf)
{
   switch(tf) {
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      case PERIOD_MN1: return "MN";
      default: return IntegerToString(tf);
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("ApexPullback EA v10.5 - Initializing on ", _Symbol);

   // Set initial daily metrics
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   g_CurrentDay = time.day;
   g_DayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   // Initialize core modules
   if (!InitializeModules()) {
      Print("ERROR: Could not initialize core modules. EA cannot run.");
      return INIT_FAILED;
   }

   // Initialize advanced logger
   g_Logger = new CLogger("ApexPullback");
   if (g_Logger == NULL) {
      Print("ERROR: Failed to create logger object");
      return INIT_FAILED;
   }
   
   g_Logger.Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
                      EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly);

   // Adjust parameters according to market preset
   AdjustParametersByPreset();

   // Create dashboard if enabled
   if (DisplayDashboard) {
      if(!CreateDashboard()) {
         LogMessage("Warning: Could not create dashboard.", false);
         // Continue initialization even if dashboard creation fails
      }
   }

   // Load news data if needed
   if (NewsFilter == NEWS_FILE) {
      LoadNewsData();
   }

   // Log successful initialization
   string initMsg = StringFormat("ApexPullback EA v10.5 initialized successfully on %s, Timeframe: %s",
                              _Symbol, TimeframeToString((int)EntryTimeframe));
   LogMessage(initMsg, true);

   g_IsInitialized = true;
   g_UseDynamicLotSize = UseDynamicLotSize;  // Store external parameter
   g_MinLotMultiplier = MinLotMultiplier;    // Store external parameter
   g_MaxVolatilityFactor = MaxVolatilityFactor;  // Store external parameter
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Log deinitialization reason
   LogMessage("ApexPullback EA v10.5 shutting down. Reason: " + GetDeinitReasonText(reason), true);

   // Clean up dashboard objects
   if (DisplayDashboard) {
      DeleteDashboard();
   }

   // Save final performance statistics if enabled
   if (SaveTradeStatistics) {
      SavePerformanceStats();
   }

   // Free memory used by modules
   if (Market != NULL) {
      delete Market;
      Market = NULL;
      LogMessage("Market Monitor released.", false);
   }
   
   if (TradeMan != NULL) {
      delete TradeMan;
      TradeMan = NULL;
      LogMessage("Trade Manager released.", false);
   }
   
   if (RiskMan != NULL) {
      delete RiskMan;
      RiskMan = NULL;
      LogMessage("Risk Manager released.", false);
   }
   
   if (g_Logger != NULL) {
      delete g_Logger;
      g_Logger = NULL;
      Print("Logger released.");
   }

   g_IsInitialized = false;
   Print("ApexPullback EA v10.5 shutdown complete.");
}

//+------------------------------------------------------------------+
//| Expert tick function (Main EA Loop)                              |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Initial Checks
   if (!g_IsInitialized) return;   // Ensure EA is initialized
   if (!CheckProcessingTime()) return;  // Limit processing frequency
   
   // 2. Check Pause Status
   if (EnableAutoPause && TimeCurrent() < g_PauseUntil) {
      // Log pause status periodically
      if (EnableDetailedLogs && (TimeCurrent() % 60) == 0)
         LogMessage("EA paused until " + TimeToString(g_PauseUntil), false);
      return;
   }

   // 3. Update Daily Statistics
   UpdateDailyStats();  // Process day changes and reset counters/equity

   // 4. Check Risk Limits (Prop Firm Mode)
   if (PropMode && g_DayTrades >= MaxDayTrades) {
      if ((TimeCurrent() % 300) == 0)  // Log periodically
         LogMessage("Daily trade limit reached: " + IntegerToString(g_DayTrades) + "/" + IntegerToString(MaxDayTrades), false);
      return;
   }
   
   if (RiskMan == NULL) { 
      LogMessage("ERROR: Risk Manager is NULL in OnTick!", true); 
      return; 
   }
   
   if (RiskMan.IsMaxLossReached()) {
      if ((TimeCurrent() % 300) == 0)  // Log periodically
         LogMessage("Maximum loss limit reached. Trading paused for today.", true);
      return;
   }

   // 5. Update Market Data & Analysis
   if (Market == NULL) { 
      LogMessage("ERROR: Market Monitor is NULL in OnTick!", true); 
      return; 
   }
   
   // Only perform deep market analysis on new bars or significant price changes
   static datetime lastAnalysisTime = 0;
   static double lastAnalysisPrice = 0;
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool newBar = (iTime(_Symbol, EntryTimeframe, 0) > lastAnalysisTime);
   bool significantMove = (MathAbs(currentPrice - lastAnalysisPrice) > Market.GetATR() * 0.2);
   
   bool updateNeeded = newBar || significantMove;
   
   if (updateNeeded) {
      if (!Market.Update()) {
         LogMessage("Error updating market data and analysis.", true);
         return;  // Skip this tick if market update fails
      }
      
      lastAnalysisTime = iTime(_Symbol, EntryTimeframe, 0);
      lastAnalysisPrice = currentPrice;
   } else {
      // Perform light update without heavy indicator recalculations
      Market.LightUpdate();
   }

   // 6. Manage Open Positions
   if (TradeMan == NULL) { 
      LogMessage("ERROR: Trade Manager is NULL in OnTick!", true); 
      return; 
   }
   
   TradeMan.ManageOpenPositions(Market.GetMarketState());  // Pass market state for adaptive trailing

   // 7. Check for New Trade Opportunities
   // Only check if there are no positions for this symbol/magic
   if (!TradeMan.HasOpenPosition(_Symbol)) {
      CheckNewTradeOpportunities();
   }

   // 8. Update Dashboard (Periodically)
   if (DisplayDashboard && (TimeCurrent() % 2) == 0) {
      UpdateDashboard();
   }

   // Update last action time
   g_LastActionTime = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                       const MqlTradeRequest& request,
                       const MqlTradeResult& result)
{
   if (TradeMan == NULL || RiskMan == NULL) return;  // Safety check

   // Let the Trade Manager process the transaction first (e.g., update internal state)
   TradeMan.ProcessTradeTransaction(trans, request, result);

   // Check if the transaction resulted in a deal close for this EA
   if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal > 0)
   {
      if (HistoryDealSelect(trans.deal))
      {
         if (HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == TradeMan.GetMagicNumber() &&
             HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT)
         {
            // Update risk management statistics based on closing deal
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            RiskMan.UpdateStatsOnDealClose(profit > 0, profit);  // Pass win/loss status and profit

            // Check for consecutive losses pause trigger
            int consecutiveLosses = RiskMan.GetConsecutiveLosses();
            if (EnableAutoPause && consecutiveLosses >= MaxConsecutiveLosses)
            {
               g_PauseUntil = TimeCurrent() + PauseMinutes * 60;
               TradeMan.CloseAllPendingOrders();  // Close any pending orders during pause
               string pauseMsg = StringFormat("Maximum consecutive losses (%d) reached. Paused until: %s",
                                           MaxConsecutiveLosses, TimeToString(g_PauseUntil, TIME_DATE|TIME_MINUTES));
               ManageAlerts(pauseMsg, true);
               LogMessage(pauseMsg, true);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Initialize core modules                                          |
//+------------------------------------------------------------------+
bool InitializeModules()
{
   bool success = true;

   // --- Initialize Market Monitor ---
   Market = new CMarketMonitor();
   if (Market == NULL) {
      Print("ERROR: Could not allocate memory for Market Monitor.");
      return false;
   }
   
   if (!Market.Initialize(_Symbol, EntryTimeframe, EMAf, EMAt,
                        UseMultiTimeframe, HigherTimeframe,
                        UseNestedTimeframe, NestedTimeframe,
                        EnableMarketRegimeFilter)) {
      Print("ERROR: Could not initialize Market Monitor parameters.");
      delete Market; Market = NULL;  // Cleanup on failure
      success = false;
   } else {
      LogMessage("Market Monitor initialized.", false);
   }
   
   // Initialize logger settings for MarketMonitor
   if (Market != NULL && Market.GetLogger() != NULL) {
      if (!Market.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize MarketMonitor logger settings.");
      }
   }

   // --- Initialize Trade Manager ---
   TradeMan = new CTradeManager();
   if (TradeMan == NULL) {
      Print("ERROR: Could not allocate memory for Trade Manager.");
      if (Market != NULL) delete Market; Market = NULL;  // Cleanup previous
      return false;
   }
   
   // Pass necessary parameters
   if (!TradeMan.Initialize(_Symbol, Comment_Prefix, (int)StringToInteger(_Symbol),
                          Market,
                          TrailingMode, TrailingAtrMultiplier, UseAdaptiveTrailing,
                          BreakEven_R, UseMultipleTargets, TP1_Percent, TP2_Percent, TP3_Percent)) {
      Print("ERROR: Could not initialize Trade Manager parameters.");
      if (Market != NULL) delete Market; Market = NULL;
      delete TradeMan; TradeMan = NULL;
      success = false;
   } else {
      LogMessage("Trade Manager initialized.", false);
   }
   
   // Initialize logger settings for TradeManager
   if (TradeMan != NULL && TradeMan.GetLogger() != NULL) {
      if (!TradeMan.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize TradeManager logger settings.");
      }
   }

   // --- Initialize Risk Manager ---
   RiskMan = new CRiskManager();
   if (RiskMan == NULL) {
      Print("ERROR: Could not allocate memory for Risk Manager.");
      if (Market != NULL) delete Market; Market = NULL;
      if (TradeMan != NULL) delete TradeMan; TradeMan = NULL;
      return false;
   }
   
   // Pass necessary parameters
   if (!RiskMan.Initialize(_Symbol, RiskPercent, PropMode, DailyLoss, MaxDD,
                         MaxDayTrades, MaxConsecutiveLosses, g_DayStartEquity)) {
      Print("ERROR: Could not initialize Risk Manager parameters.");
      if (Market != NULL) delete Market; Market = NULL;
      if (TradeMan != NULL) delete TradeMan; TradeMan = NULL;
      delete RiskMan; RiskMan = NULL;
      success = false;
   } else {
      LogMessage("Risk Manager initialized.", false);
   }
   
   // Initialize logger settings for RiskManager
   if (RiskMan != NULL && RiskMan.GetLogger() != NULL) {
      if (!RiskMan.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize RiskManager logger settings.");
      }
   }

   return success;
}

//+------------------------------------------------------------------+
//| Check processing time interval                                   |
//+------------------------------------------------------------------+
bool CheckProcessingTime()
{
   static datetime lastCheckTime = 0;
   datetime currentTime = TimeCurrent();
   
   // Avoid excessive tick processing - process no more than once each 50ms
   uint processingInterval = 50;  // Milliseconds minimum interval
   
   if (currentTime == lastCheckTime || (GetTickCount() - GetTickCount(lastCheckTime)) < processingInterval)
   {
      return false;  // Skip if called too frequently
   }

   lastCheckTime = currentTime;
   return true;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                          |
//+------------------------------------------------------------------+
void UpdateDailyStats()
{
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);

   if (time.day != g_CurrentDay)
   {
      g_CurrentDay = time.day;
      g_DayTrades = 0;
      g_DayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);

      // Reset daily metrics in Risk Manager module
      if (RiskMan != NULL) {
         RiskMan.ResetDailyStats(g_DayStartEquity);  // RiskManager handles daily stats reset
      } else {
         LogMessage("Warning: Risk Manager not initialized when trying to reset daily stats.", true);
      }

      LogMessage("New trading day detected. Daily stats reset.", true);
   }
}

//+------------------------------------------------------------------+
//| Check for new trade opportunities                                |
//+------------------------------------------------------------------+
void CheckNewTradeOpportunities()
{
   // Preliminary checks before analyzing potential trades
   
   // 1. Check if already at max positions
   if (PositionsTotal() >= MaxPositions) {
      LogMessage("Max open positions limit reached: " + IntegerToString(MaxPositions), false);
      return;
   }
   
   // 2. Check if new trades are disabled
   if (!AllowNewTrades) {
      LogMessage("New trades disabled. AllowNewTrades = false", false);
      return;
   }
   
   // 3. Check if EA is in pause state
   if (g_PauseUntil > TimeCurrent()) {
      LogMessage("EA paused. Resuming after: " + TimeToString(g_PauseUntil), false);
      return;
   }
   
   // 4. Check daily trade limits if in Prop Firm mode
   if (PropMode && g_DayTrades >= MaxDayTrades) {
      LogMessage("Daily trade limit reached: " + IntegerToString(MaxDayTrades), true);
      return;
   }
   
   // 5. Check drawdown limits if in Prop Firm mode
   if (PropMode && RiskMan.IsMaxDrawdownExceeded(MaxDD)) {
      LogMessage("Maximum drawdown limit reached: " + DoubleToString(MaxDD, 2) + "%", true);
      // Trigger auto-pause if enabled
      if (EnableAutoPause) {
         g_PauseUntil = TimeCurrent() + PauseMinutes * 60;
         LogMessage("EA paused for " + IntegerToString(PauseMinutes) + " minutes due to max DD", true);
      }
      return;
   }
   
   // 6. Check consecutive losses limit if in Prop Firm mode
   if (PropMode && RiskMan.GetConsecutiveLosses() >= MaxConsecutiveLosses) {
      LogMessage("Maximum consecutive losses reached: " + IntegerToString(MaxConsecutiveLosses), true);
      // Trigger auto-pause if enabled
      if (EnableAutoPause) {
         g_PauseUntil = TimeCurrent() + PauseMinutes * 60;
         LogMessage("EA paused for " + IntegerToString(PauseMinutes) + " minutes due to consecutive losses", true);
      }
      return;
   }
   
   // 7. Check trading session if filter is enabled
   if (!IsAllowedTradingSession()) {
      return;  // Silently exit if outside trading session
   }
   
   // 8. Check news impact if filter is enabled
   if (NewsFilter != NEWS_NONE && IsNewsImpactPeriod()) {
      if (EnableDetailedLogs) 
         LogMessage("Trade opportunity skipped due to upcoming news event", false);
      return;
   }
   
   // 9. Check spread conditions
   double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double maxAllowedSpread = MaxSpreadPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   
   if (currentSpread > maxAllowedSpread) {
      if ((TimeCurrent() % 300) == 0)  // Log every 5 minutes to avoid spam
         LogMessage("Current spread (" + DoubleToString(currentSpread/_Point, 1) + 
                   " points) exceeds maximum allowed (" + IntegerToString(MaxSpreadPoints) + 
                   " points)", false);
      return;
   }

   // Get trade signal from Market Monitor
   SignalInfo signal;
   if (!Market.CheckEntrySignal(signal)) {
      return;  // No valid entry signal found
   }

   // Log detected signal
   string signalDesc = GetScenarioName(signal.scenario);
   string signalMsg = StringFormat("%s signal detected: %s. Entry: %.5f, SL: %.5f", 
                                signal.isLong ? "BUY" : "SELL",
                                signalDesc, signal.entryPrice, signal.stopLoss);
   
   LogMessage(signalMsg, false);

   // Calculate lot size through Risk Manager
   double stopLossPoints = MathAbs(signal.entryPrice - signal.stopLoss) / _Point;
   double lotSize = RiskMan.CalculateLotSize(stopLossPoints, signal.quality);

   // Apply dynamic lot sizing if enabled
   if (g_UseDynamicLotSize) {
      double volatilityFactor = Market.GetVolatilityFactor();
      if (volatilityFactor > 1.0) {
         // Adjust lot size based on volatility (higher volatility = smaller position)
         double adjustedLotSize = lotSize;
         
         // Use square root of volatility factor for smoother reduction
         if (volatilityFactor > g_MaxVolatilityFactor)
            volatilityFactor = g_MaxVolatilityFactor; // Cap at maximum
            
         adjustedLotSize = lotSize * MathMax(g_MinLotMultiplier, 1.0/MathSqrt(volatilityFactor));
         
         LogMessage("Adjusting lot size due to high volatility: " + 
                  DoubleToString(lotSize, 2) + " -> " + 
                  DoubleToString(adjustedLotSize, 2) + 
                  " (Volatility: " + DoubleToString(volatilityFactor, 1) + "x)", false);
         
         lotSize = adjustedLotSize;
      }
   }

   // Validate lot size result
   if (lotSize <= 0) {
      string rejectionReason = "Risk management (Lot size: " + DoubleToString(lotSize, 2) + ")";
      LogMessage("Trade rejected by " + rejectionReason, false);
      
      // Provide feedback to Market Monitor about rejected signal
      if (TradeMan != NULL) {
         TradeMan.FeedbackSignalResult(signal, false, 0, rejectionReason);
      }
      return;
   }

   // Execute trade through Trade Manager
   ulong ticket = 0;
   string scenarioName = GetScenarioName(signal.scenario);

   // Choose execution method based on EntryMode
   if (EntryMode == MODE_MARKET) {
      // Market order execution
      if (signal.isLong) {
         ticket = TradeMan.ExecuteBuyOrder(lotSize, signal.stopLoss, 0, signal.scenario);
      } else {
         ticket = TradeMan.ExecuteSellOrder(lotSize, signal.stopLoss, 0, signal.scenario);
      }
   } 
   else if (EntryMode == MODE_LIMIT) {
      // Limit order execution
      if (signal.isLong) {
         // Buy limit slightly below current price
         double limitPrice = NormalizeDouble(signal.entryPrice * 0.9998, _Digits);
         ticket = TradeMan.PlaceBuyLimit(lotSize, limitPrice, signal.stopLoss, 0, signal.scenario);
      } else {
         // Sell limit slightly above current price
         double limitPrice = NormalizeDouble(signal.entryPrice * 1.0002, _Digits);
         ticket = TradeMan.PlaceSellLimit(lotSize, limitPrice, signal.stopLoss, 0, signal.scenario);
      }
   }
   else { // MODE_SMART
      // Smart execution based on signal quality and market conditions
      if (signal.quality >= 0.8) {
         // High quality signal - use market order
         if (signal.isLong) {
            ticket = TradeMan.ExecuteBuyOrder(lotSize, signal.stopLoss, 0, signal.scenario);
         } else {
            ticket = TradeMan.ExecuteSellOrder(lotSize, signal.stopLoss, 0, signal.scenario);
         }
      } else {
         // Medium quality signal - use limit order with better price
         double priceImprovement = _Point * 5; // Better price by 5 points
         
         if (signal.isLong) {
            double limitPrice = MathMax(signal.entryPrice - priceImprovement, 
                                     SymbolInfoDouble(_Symbol, SYMBOL_BID));
            ticket = TradeMan.PlaceBuyLimit(lotSize, limitPrice, signal.stopLoss, 0, signal.scenario);
         } else {
            double limitPrice = MathMin(signal.entryPrice + priceImprovement,
                                     SymbolInfoDouble(_Symbol, SYMBOL_ASK));
            ticket = TradeMan.PlaceSellLimit(lotSize, limitPrice, signal.stopLoss, 0, signal.scenario);
         }
      }
   }

   // Process execution result
   if (ticket > 0) {
      // Trade placed successfully
      g_DayTrades++; // Increment daily trade counter
      string tradeMsg = StringFormat("%s order placed (#%d) for %s. Entry: %s, SL: %s, Lot: %s, Scenario: %s, Quality: %.2f",
                                  signal.isLong ? "BUY" : "SELL",
                                  ticket,
                                  _Symbol,
                                  DoubleToString(signal.entryPrice, _Digits),
                                  DoubleToString(signal.stopLoss, _Digits),
                                  DoubleToString(lotSize, 2),
                                  scenarioName,
                                  signal.quality);
      LogMessage(tradeMsg, true);
      ManageAlerts(tradeMsg, false);
      
      // Send positive feedback to Market Monitor
      if (TradeMan != NULL) {
         TradeMan.FeedbackSignalResult(signal, true, ticket);
      }
   } else {
      // Trade execution failed
      string failReason = "Error code: " + IntegerToString(GetLastError());
      LogMessage("Failed to execute " + (signal.isLong ? "BUY" : "SELL") + " order. " + failReason, true);
      
      // Send negative feedback to Market Monitor
      if (TradeMan != NULL) {
         TradeMan.FeedbackSignalResult(signal, false, 0, failReason);
      }
   }
}

//+------------------------------------------------------------------+
//| Check if current time is within allowed trading session          |
//+------------------------------------------------------------------+
bool IsAllowedTradingSession()
{
   // If session filtering is disabled, always return true
   if (!FilterBySession)
      return true;
      
   // Get current time in GMT
   datetime timeGMT = TimeCurrent() + GMT_Offset * 3600;
   MqlDateTime dt;
   TimeToStruct(timeGMT, dt);
   
   int hour = dt.hour;
   int minute = dt.min;
   
   // Check if current time is within the specified trading window
   if (SessionStartHour < SessionEndHour) {
      // Normal session (doesn't cross midnight)
      if (hour > SessionStartHour || (hour == SessionStartHour && minute >= SessionStartMinute)) {
         if (hour < SessionEndHour || (hour == SessionEndHour && minute <= SessionEndMinute)) {
            return true;
         }
      }
   } else if (SessionStartHour > SessionEndHour) {
      // Session crosses midnight
      if (hour > SessionStartHour || (hour == SessionStartHour && minute >= SessionStartMinute) || 
          hour < SessionEndHour || (hour == SessionEndHour && minute <= SessionEndMinute)) {
         return true;
      }
   } else {
      // Start and end hours are the same, check minutes
      if (hour == SessionStartHour) {
         if (SessionStartMinute <= SessionEndMinute) {
            // Same hour, normal session
            if (minute >= SessionStartMinute && minute <= SessionEndMinute) {
               return true;
            }
         } else {
            // Same hour, session crosses to next hour
            if (minute >= SessionStartMinute || minute <= SessionEndMinute) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if current time is within news impact period               |
//+------------------------------------------------------------------+
bool IsNewsImpactPeriod()
{
   // If news filtering is disabled, always return false (no impact)
   if (NewsFilter == NEWS_NONE)
      return false;
      
   // Get current time
   datetime currentTime = TimeCurrent();
   
   // Check upcoming news events
   for(int i = 0; i < ArraySize(g_UpcomingNews); i++)
   {
      // If news is impactful enough and within time window to avoid
      if (g_UpcomingNews[i].impact >= NewsImpactLevel && 
          g_UpcomingNews[i].AffectsSymbol(_Symbol) &&
          g_UpcomingNews[i].IsInWindow(currentTime, NewsWindowBefore, NewsWindowAfter))
      {
         // Log the news event
         LogMessage("News impact detected: " + g_UpcomingNews[i].ToString(), true);
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Load news data                                                   |
//+------------------------------------------------------------------+
bool LoadNewsData()
{
   // Only load data if news filtering is set to NEWS_FILE
   if (NewsFilter != NEWS_FILE)
      return false;
      
   string filename = NEWS_FILE;
   int fileHandle = FileOpen(filename, FILE_READ|FILE_CSV|FILE_ANSI);

   if (fileHandle == INVALID_HANDLE)
   {
      LogMessage("Error: Cannot open news file '" + filename + "'. Error code: " + IntegerToString(GetLastError()), true);
      return false;
   }
   
   // Clear old news array
   ArrayFree(g_UpcomingNews);
   
   // Read data from file and add to news array
   while(!FileIsEnding(fileHandle))
   {
      // News file format: Date,Time,Currency,Event,Impact
      string dateStr = FileReadString(fileHandle);
      string timeStr = FileReadString(fileHandle);
      string currency = FileReadString(fileHandle);
      string eventName = FileReadString(fileHandle);
      string impactStr = FileReadString(fileHandle);
      
      // Skip header row or empty rows
      if (dateStr == "Date" || dateStr == "")
         continue;
         
      // Convert strings to values
      datetime eventTime = StringToTime(dateStr + " " + timeStr);
      int impact = 1; // Default to low impact
      
      if (impactStr == "Medium") impact = 2;
      else if (impactStr == "High") impact = 3;
      
      // Add event to news array
      int index = ArraySize(g_UpcomingNews);
      ArrayResize(g_UpcomingNews, index + 1);
      
      g_UpcomingNews[index].title = eventName;
      g_UpcomingNews[index].time = eventTime;
      g_UpcomingNews[index].currency = currency;
      g_UpcomingNews[index].impact = impact;
   }
   
   FileClose(fileHandle);
   
   LogMessage("Loaded " + IntegerToString(ArraySize(g_UpcomingNews)) + " news events.", false);
   return true;
}

//+------------------------------------------------------------------+
//| Manage alerts                                                    |
//+------------------------------------------------------------------+
void ManageAlerts(string message, bool isImportant)
{
   // Log the message first
   LogMessage(message, isImportant);
   
   // If alerts are disabled, exit
   if (!Alert_Enabled) return;
   
   // MT5 Terminal alert
   if (isImportant) {
      Alert(message);
   }
   
   // Push notification if enabled
   if (Alert_PushNotification && isImportant) {
      SendNotification("ApexPullback: " + message);
   }
   
   // Email if enabled
   if (Alert_Email && isImportant) {
      SendMail("ApexPullback: " + _Symbol, message);
   }
   
   // Telegram notification
   if (EnableTelegramNotify && (!TelegramImportantOnly || isImportant)) {
      // Send Telegram notification via g_Logger
      if (g_Logger != NULL) {
         g_Logger.SendTelegramMessage(message);
      }
   }
}

//+------------------------------------------------------------------+
//| Log message with timestamp                                       |
//+------------------------------------------------------------------+
void LogMessage(string message, bool important)
{
   if (g_Logger != NULL) {
      if (important)
         g_Logger.LogInfo(message);
      else
         g_Logger.LogDebug(message);
   } else {
      // Fallback if logger not initialized
      string logEntry = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + _Symbol + "] " + message;
      if (important || EnableDetailedLogs)
         Print(logEntry);
   }
}

//+------------------------------------------------------------------+
//| Convert deinit reason to text                                    |
//+------------------------------------------------------------------+
string GetDeinitReasonText(const int reason)
{
   switch(reason)
   {
      case REASON_PROGRAM:     return "Program stopped by itself";
      case REASON_REMOVE:      return "EA removed from chart";
      case REASON_RECOMPILE:   return "EA recompiled";
      case REASON_CHARTCHANGE: return "Symbol or timeframe changed";
      case REASON_CHARTCLOSE:  return "Chart closed";
      case REASON_PARAMETERS:  return "Input parameters changed";
      case REASON_ACCOUNT:     return "Account changed or reconnected";
      case REASON_TEMPLATE:    return "Template applied";
      case REASON_INITFAILED:  return "OnInit() failed";
      case REASON_CLOSE:       return "Terminal closed";
      default:                return "Unknown reason (" + IntegerToString(reason) + ")";
   }
}

//+------------------------------------------------------------------+
//| Convert entry scenario to string                                 |
//+------------------------------------------------------------------+
string GetScenarioName(ENUM_ENTRY_SCENARIO scenario)
{
   switch(scenario) {
      case SCENARIO_NONE: return "Undefined";
      case SCENARIO_STRONG_PULLBACK: return "Strong Pullback";
      case SCENARIO_EMA_BOUNCE: return "EMA Bounce";
      case SCENARIO_DUAL_EMA_SUPPORT: return "Dual EMA Support";
      case SCENARIO_FIBONACCI_PULLBACK: return "Fibonacci Pullback";
      case SCENARIO_HARMONIC_PATTERN: return "Harmonic Pattern";
      case SCENARIO_MOMENTUM_SHIFT: return "Momentum Shift";
      case SCENARIO_LIQUIDITY_GRAB: return "Liquidity Grab";
      case SCENARIO_BREAKOUT_FAILURE: return "Breakout Failure";
      case SCENARIO_REVERSAL_CONFIRMATION: return "Reversal Confirmation";
      default: return "Undefined";
   }
}

//+------------------------------------------------------------------+
//| Create dashboard components on chart                             |
//+------------------------------------------------------------------+
bool CreateDashboard()
{
   if (!DisplayDashboard) return true;

   // Define dashboard size and position
   int x = 20, y = 20;
   int width = 300, height = 300;
   color bgColor = clrWhite;
   color borderColor = clrSteelBlue;
   color textColor = clrNavy;
   int fontSize = 9;
   
   // Create background
   if(!ObjectCreate(0, "Apex_DB_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      LogMessage("Error creating dashboard background", true);
      return false;
   }
   
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_YSIZE, height);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_COLOR, borderColor);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_HIDDEN, true);
   
   // Create title
   CreateLabel("Apex_DB_Title", "ApexPullback v10.5", x + 10, y + 10, fontSize + 2, clrNavy, true);
   
   // Create info labels with placeholder values - will be updated in UpdateDashboard()
   string items[] = {
      "Status", "Mode", "Market Regime", "Current Day Trades",
      "Account Balance", "Equity", "Win Rate", "Profit Factor", 
      "Daily P/L", "Total Trades", "Consec. Wins", "Consec. Losses",
      "Last Signal", "Current Trend", "ATR"
   };
   
   for(int i = 0; i < ArraySize(items); i++) {
      string name = "Apex_DB_" + items[i];
      CreateLabel(name + "_Label", items[i] + ":", x + 10, y + 40 + i*18, fontSize, textColor, false);
      CreateLabel(name + "_Value", "---", x + 130, y + 40 + i*18, fontSize, textColor, false);
   }
   
   ChartRedraw();
   return true;
}

//+------------------------------------------------------------------+
//| Helper function to create text label                             |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, int fontSize, color textColor, bool isBold)
{
   if(ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0)) {
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      if(isBold) ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   }
}

//+------------------------------------------------------------------+
//| Update dashboard information                                     |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if (!DisplayDashboard) return;
   
   // EA Status
   string status = (TimeCurrent() < g_PauseUntil) ? 
                 "PAUSED until " + TimeToString(g_PauseUntil, TIME_MINUTES) : "ACTIVE";
   ObjectSetString(0, "Apex_DB_Status_Value", OBJPROP_TEXT, status);
   
   // Mode
   ObjectSetString(0, "Apex_DB_Mode_Value", OBJPROP_TEXT, PropMode ? "Prop Firm" : "Standard");
   
   // Market regime
   string regime = "Undefined";
   if(Market != NULL) {
      int marketState = Market.GetMarketState();
      switch(marketState) {
         case REGIME_STRONG_TREND: regime = "Strong Trend"; break;
         case REGIME_WEAK_TREND: regime = "Weak Trend"; break;
         case REGIME_RANGING: regime = "Ranging"; break;
         case REGIME_VOLATILE: regime = "Volatile"; break;
      }
   }
   ObjectSetString(0, "Apex_DB_Market Regime_Value", OBJPROP_TEXT, regime);
   
   // Day trades
   ObjectSetString(0, "Apex_DB_Current Day Trades_Value", OBJPROP_TEXT, 
                 IntegerToString(g_DayTrades) + "/" + IntegerToString(MaxDayTrades));
   
   // Account info
   ObjectSetString(0, "Apex_DB_Account Balance_Value", OBJPROP_TEXT, 
                 DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   ObjectSetString(0, "Apex_DB_Equity_Value", OBJPROP_TEXT, 
                 DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
   
   // Performance metrics
   if(RiskMan != NULL) {
      PerformanceMetrics metrics;
      if(RiskMan.GetPerformanceMetrics(metrics)) {
         ObjectSetString(0, "Apex_DB_Win Rate_Value", OBJPROP_TEXT, 
                       DoubleToString(metrics.winRate * 100, 1) + "%");
         ObjectSetString(0, "Apex_DB_Profit Factor_Value", OBJPROP_TEXT, 
                       DoubleToString(metrics.profitFactor, 2));
         ObjectSetString(0, "Apex_DB_Total Trades_Value", OBJPROP_TEXT, 
                       IntegerToString(metrics.totalTrades));
         ObjectSetString(0, "Apex_DB_Consec. Wins_Value", OBJPROP_TEXT, 
                       IntegerToString(metrics.consecutiveWins) + 
                       " (Max: " + IntegerToString(metrics.maxConsecutiveWins) + ")");
         ObjectSetString(0, "Apex_DB_Consec. Losses_Value", OBJPROP_TEXT, 
                       IntegerToString(metrics.consecutiveLosses) + 
                       " (Max: " + IntegerToString(metrics.maxConsecutiveLosses) + ")");
      }
   }
   
   // Daily P/L
   double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - g_DayStartEquity;
   string plColor = dailyPL >= 0 ? "00AA00" : "DD0000";
   ObjectSetString(0, "Apex_DB_Daily P/L_Value", OBJPROP_TEXT, 
                 DoubleToString(dailyPL, 2) + " (" + 
                 DoubleToString(dailyPL/g_DayStartEquity*100, 2) + "%)");
   ObjectSetInteger(0, "Apex_DB_Daily P/L_Value", OBJPROP_COLOR, StringToColor(plColor));
   
   // Market data
   if(Market != NULL) {
      ObjectSetString(0, "Apex_DB_Current Trend_Value", OBJPROP_TEXT, 
                    Market.IsTrendUp() ? "UP" : (Market.IsTrendDown() ? "DOWN" : "NEUTRAL"));
      ObjectSetString(0, "Apex_DB_ATR_Value", OBJPROP_TEXT, 
                    DoubleToString(Market.GetATR(), _Digits));
      
      // Last signal info
      SignalInfo lastSignal;
      if(Market.GetLastSignal(lastSignal)) {
         string signalDesc = (lastSignal.isLong ? "BUY" : "SELL") + " (" + 
                         GetScenarioName(lastSignal.scenario) + ")";
         ObjectSetString(0, "Apex_DB_Last Signal_Value", OBJPROP_TEXT, signalDesc);
      }
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Delete dashboard components from chart                           |
//+------------------------------------------------------------------+
void DeleteDashboard()
{
   if (!DisplayDashboard) return;
   
   // Delete all objects with prefix
   ObjectsDeleteAll(0, "Apex_DB_");
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| Save performance stats to file                                   |
//+------------------------------------------------------------------+
void SavePerformanceStats()
{
   if (!SaveTradeStatistics || RiskMan == NULL)
      return;

   LogMessage("Saving performance stats...", false);
   
   // 1) Get performance metrics from RiskManager
   PerformanceMetrics metrics;
   if (!RiskMan.GetPerformanceMetrics(metrics))
   {
      LogMessage("Could not retrieve performance metrics for saving", true);
      return;
   }

   // 2) Format timestamp for filename
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   string stamp = StringFormat("%04d%02d%02d_%02d%02d",
                             dt.year, dt.mon, dt.day, dt.hour, dt.min);

   string filename = "ApexPullback_Stats_" + _Symbol + "_" + stamp + ".csv";
   int fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_ANSI);

   if (fileHandle == INVALID_HANDLE)
   {
      LogMessage("Failed to create stats file. Error: " + IntegerToString(GetLastError()), true);
      return;
   }

   // 3) Write header and general info
   FileWrite(fileHandle, "Metric", "Value");
   FileWrite(fileHandle, "Symbol", _Symbol);
   FileWrite(fileHandle, "Timeframe", TimeframeToString(EntryTimeframe));
   FileWrite(fileHandle, "Fast EMA", IntegerToString(EMAf));
   FileWrite(fileHandle, "Trend EMA", IntegerToString(EMAt));
   FileWrite(fileHandle, "Preset", EnumToString(Preset));
   FileWrite(fileHandle, "Report Date", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));

   // 4) Write key performance metrics
   FileWrite(fileHandle, "Total Trades", metrics.totalTrades);
   FileWrite(fileHandle, "Win Rate (%)", DoubleToString(metrics.winRate * 100.0, 2));
   FileWrite(fileHandle, "Profit Factor", DoubleToString(metrics.profitFactor, 2));
   FileWrite(fileHandle, "Expected Payoff", DoubleToString(metrics.expectedPayoff, 2));
   FileWrite(fileHandle, "Average Win", DoubleToString(metrics.averageWin, 2));
   FileWrite(fileHandle, "Average Loss", DoubleToString(metrics.averageLoss, 2));
   FileWrite(fileHandle, "Max Consecutive Wins", metrics.maxConsecutiveWins);
   FileWrite(fileHandle, "Max Consecutive Losses", metrics.maxConsecutiveLosses);
   FileWrite(fileHandle, "Max Equity DD (%)", DoubleToString(metrics.maxEquityDD * 100.0, 2));
   FileWrite(fileHandle, "Max Relative DD (%)", DoubleToString(metrics.maxRelativeDD * 100.0, 2));

   // 5) Write performance by scenario (if available)
   FileWrite(fileHandle, "", "");
   FileWrite(fileHandle, "Scenario", "Trades", "Wins", "Win %", "Net Profit");

   ScenarioStats scenStats[];
   if (RiskMan.GetScenarioStats(scenStats))
   {
      for (int i = 0; i < ArraySize(scenStats); i++)
      {
         // Only write scenario data if there are trades for that scenario
         if (scenStats[i].totalTrades > 0) {
            double winRate = scenStats[i].totalTrades > 0 ? 
                           (double)scenStats[i].winTrades / scenStats[i].totalTrades * 100.0 : 0;
                           
            FileWrite(fileHandle,
                     GetScenarioName((ENUM_ENTRY_SCENARIO)scenStats[i].scenario),
                     scenStats[i].totalTrades,
                     scenStats[i].winTrades,
                     DoubleToString(winRate, 2),
                     DoubleToString(scenStats[i].netProfit, 2)
            );
         }
      }
   }

   FileClose(fileHandle);
   LogMessage("Performance stats saved to " + filename, true);
}

//+------------------------------------------------------------------+
//| Adjust parameters based on selected market preset                |
//+------------------------------------------------------------------+
void AdjustParametersByPreset()
{
   ENUM_MARKET_PRESET currentPreset = Preset;
   
   // Auto-determine preset if needed
   if(currentPreset == PRESET_AUTO) {
      string symbol = _Symbol;
      
      // Determine market group based on pair
      if(StringFind(symbol, "XAU") >= 0 || StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "XAUUSD") >= 0)
         currentPreset = PRESET_GOLD;
      else if(StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0)
         currentPreset = PRESET_CRYPTO;
      else
         currentPreset = PRESET_FX_MAJOR; // Default to major forex
   }
   
   double envMultiplier = 1.0;
   double slAtrMultiplier = 1.0;
   double tpRrMultiplier = 1.0;
   
   // Adjust multipliers based on preset
   switch(currentPreset) {
      case PRESET_FX_MAJOR:
      case PRESET_FX_MINOR:
         envMultiplier = FX_EnvF_Multiplier;
         slAtrMultiplier = FX_SL_ATR_Multiplier;
         tpRrMultiplier = FX_TP_RR_Multiplier;
         LogMessage("Applying Forex preset", false);
         break;
         
      case PRESET_GOLD:
         envMultiplier = GOLD_EnvF_Multiplier;
         slAtrMultiplier = GOLD_SL_ATR_Multiplier;
         tpRrMultiplier = GOLD_TP_RR_Multiplier;
         LogMessage("Applying Gold preset", false);
         break;
         
      case PRESET_CRYPTO:
         envMultiplier = CRYPTO_EnvF_Multiplier;
         slAtrMultiplier = CRYPTO_SL_ATR_Multiplier;
         tpRrMultiplier = CRYPTO_TP_RR_Multiplier;
         LogMessage("Applying Crypto preset", false);
         break;
         
      default:
         LogMessage("No preset adjustments applied", false);
         break;
   }
   
   // Apply adjustment multipliers
   double adjustedEnvF = EnvF * envMultiplier;
   double adjustedSL_ATR = SL_ATR * slAtrMultiplier;
   double adjustedTP_RR = TP_RR * tpRrMultiplier;
   
   // Update parameters for modules
   if(Market != NULL) {
      Market.SetEnvelopeDeviation(adjustedEnvF);
   }
   
   if(TradeMan != NULL) {
      TradeMan.SetStopLossAtrMultiplier(adjustedSL_ATR);
      TradeMan.SetTakeProfitRrRatio(adjustedTP_RR);
   }
   
   LogMessage(StringFormat("Parameters adjusted - EnvF: %.2f, SL_ATR: %.2f, TP_RR: %.2f", 
                         adjustedEnvF, adjustedSL_ATR, adjustedTP_RR), false);
}

//+------------------------------------------------------------------+
//| Open trade function                                              |
//+------------------------------------------------------------------+
bool OpenTrade(bool isLong, double entryPrice, double stopLoss, double takeProfit, double riskAmount, string comment = "")
{
   // Add comment prefix
   string tradeComment = Comment_Prefix;
   if (comment != "") tradeComment += ": " + comment;
   
   // Open position through TradeManager
   bool result = TradeMan.OpenPosition(isLong, entryPrice, stopLoss, takeProfit, riskAmount, tradeComment);
   
   // If position opened successfully, update daily trades count
   if (result) {
      g_DayTrades++;
   }
   
   return result;
}

// --- Logging and notification settings
input string LoggingSection = "=== Logging & Notification Settings ==="; // Logging section
input bool   EnableDetailedLogs = false;      // Enable detailed logs
input bool   EnableCsvLog = false;            // Save logs to CSV file  
input string CsvLogFilename = "ApexPullback_log.csv"; // CSV log filename
input bool   EnableTelegramNotify = false;    // Send notifications via Telegram
input string TelegramBotToken = "";           // Telegram Bot Token
input string TelegramChatID = "";             // Telegram Chat ID
input bool   TelegramImportantOnly = true;    // Only send important notifications

// --- News and alert settings
input string NewsSection = "=== News Filter Settings ==="; // News section
input ENUM_NEWS_FILTER NewsFilter = NEWS_NONE; // News filtering method
input int    NewsImpactMinutes = 30;           // Minutes before news (avoid trading)
input int    NewsImpactLevel = 2;              // News impact level (1=Low, 2=Medium, 3=High)
input int    NewsWindowBefore = 30;            // Minutes before news (avoid trading)
input int    NewsWindowAfter = 15;             // Minutes after news (avoid trading)
input string NEWS_FILE = "news_calendar.csv";  // News calendar filename
input bool   Alert_Enabled = true;             // Enable alerts
input bool   Alert_Email = false;              // Send email alerts
input bool   Alert_PushNotification = false;   // Send push notifications

// --- Entry mode settings
input string EntryModeSection = "=== Entry Mode Settings ==="; // Entry section
input ENUM_ENTRY_MODE EntryMode = MODE_MARKET; // Entry mode

// --- Display and interface settings
input string DisplaySection = "=== Display & Interface Settings ==="; // Display section
input bool   DisplayDashboard = true;         // Display dashboard
input int    DisplayMode = 1;                 // Display mode (0=Minimal, 1=Standard, 2=Detailed)
input int    TrendMode = 1;                   // Trend mode (0=None, 1=Lines, 2=Zone)
input bool   SaveTradeStatistics = true;      // Save trade statistics

// --- Pause settings
input string PauseSection = "=== Pause Settings ==="; // Pause section
input bool   EnableAutoPause = true;          // Auto-pause when DD limit reached
input int    PauseMinutes = 240;              // Minutes to pause after limit reached

// --- Advanced trailing stop settings
input string TrailingStopSection = "=== Advanced Trailing Stop Settings ==="; // Trailing section
input bool   UseAdaptiveTrailing = true;      // Use adaptive trailing stop (based on ADX)
input double AdxThreshold = 20.0;             // ADX threshold (medium trend)
input double AdxStrongThreshold = 30.0;       // ADX threshold (strong trend)

// --- Strategy and timeframe settings
input string StrategySection = "=== Strategy & Timeframe Settings ==="; // Strategy section
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_H1;   // Main entry timeframe
input int    EMAf = 34;                       // Fast EMA period
input int    EMAt = 89;                       // Trend EMA period
input double EnvF = 0.001;                    // Envelope deviation (default 0.1%)
input bool   UseMultiTimeframe = true;        // Use multi-timeframe analysis
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H4; // Higher timeframe
input bool   UseNestedTimeframe = true;       // Use nested timeframe
input ENUM_TIMEFRAMES NestedTimeframe = PERIOD_M15; // Nested timeframe
input bool   EnableMarketRegimeFilter = true; // Enable market regime filter
input ENUM_MARKET_PRESET Preset = PRESET_AUTO; // Auto-detect market type

// --- Trading and position management settings
input string TradingSection = "=== Trading & Position Management Settings ==="; // Trading section
input int    MaxPositions = 5;                // Maximum number of open positions
input string Comment_Prefix = "ApexPB";       // Comment prefix for trades
input bool   AllowNewTrades = true;           // Allow opening new trades
input double RiskPercent = 1.0;               // Risk percentage (% of capital)
input double MaxSpreadPoints = 50;            // Maximum allowed spread (points)
input int    g_MinPullbackPct = 20;           // Minimum pullback percentage
input int    g_MaxPullbackPct = 60;           // Maximum pullback percentage
input int    LookbackBars = 20;               // Bars to look back for analysis
input double SL_ATR = 1.2;                    // SL ATR multiplier
input double TP_RR = 1.5;                     // TP/SL ratio (Risk:Reward)
input bool   UseDynamicLotSize = true;        // Use dynamic lot sizing based on volatility 
input double MinLotMultiplier = 0.5;          // Minimum lot size multiplier
input double MaxVolatilityFactor = 2.0;       // Maximum volatility factor

// --- Breakeven and take profit settings
input string TPSection = "=== Breakeven & Take Profit Settings ==="; // TP section
input ENUM_TRAILING_MODE TrailingMode = TRAILING_MODE_ATR; // Trailing Stop Mode
input double TrailingAtrMultiplier = 2.0;     // ATR multiplier for Trailing Stop
input double BreakEven_R = 1.0;               // R level to activate breakeven
input bool   UseMultipleTargets = true;       // Use multiple take profit targets
input int    TP1_Percent = 30;                // Percentage to close at TP1
input int    TP2_Percent = 30;                // Percentage to close at TP2
input int    TP3_Percent = 40;                // Percentage to close at TP3

// --- Session filter settings
input string SessionSection = "=== Session Filter Settings ==="; // Session section
input bool   FilterBySession = false;         // Filter trades by session
input int    SessionStartHour = 7;            // Session start hour (GMT)
input int    SessionStartMinute = 0;          // Session start minute
input int    SessionEndHour = 17;             // Session end hour (GMT)
input int    SessionEndMinute = 0;            // Session end minute
input int    GMT_Offset = 0;                  // GMT offset hours

// --- Market-specific multiplier settings
input string MarketFactorsSection = "=== Market Multiplier Settings ==="; // Market factors section
input double FX_EnvF_Multiplier = 1.0;        // Envelope multiplier for Forex
input double FX_SL_ATR_Multiplier = 1.0;      // SL ATR multiplier for Forex
input double FX_TP_RR_Multiplier = 1.0;       // TP/SL multiplier for Forex
input double GOLD_EnvF_Multiplier = 1.5;      // Envelope multiplier for Gold
input double GOLD_SL_ATR_Multiplier = 1.5;    // SL ATR multiplier for Gold
input double GOLD_TP_RR_Multiplier = 1.3;     // TP/SL multiplier for Gold
input double CRYPTO_EnvF_Multiplier = 2.0;    // Envelope multiplier for Crypto 
input double CRYPTO_SL_ATR_Multiplier = 2.0;  // SL ATR multiplier for Crypto
input double CRYPTO_TP_RR_Multiplier = 1.5;   // TP/SL multiplier for Crypto