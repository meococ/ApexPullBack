//+------------------------------------------------------------------+
//|   ApexPullback MASTER EA v10.6 - Professional Edition            |
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

// Core module objects - Chuyển từ con trỏ sang stack để tối ưu hóa
CMarketMonitor Market;              // Market monitor module
CTradeManager  TradeMan;            // Trade management module
CRiskManager   RiskMan;             // Risk management module

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
void    SaveBacktestResultsToCSV(double winRate, double profitFactor, 
                                double maxDrawdown, double netProfit, 
                                double totalTrades, double customScore);

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
   Print("ApexPullback EA v10.6 - Initializing on ", _Symbol);

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
   if ((int)NewsFilter == (int)NEWS_FILE) {
      LoadNewsData();
   }

   // Log successful initialization
   string initMsg = StringFormat("ApexPullback EA v10.6 initialized successfully on %s, Timeframe: %s",
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
   LogMessage("ApexPullback EA v10.6 shutting down. Reason: " + GetDeinitReasonText(reason), true);

   // Clean up dashboard objects
   if (DisplayDashboard) {
      DeleteDashboard();
   }

   // Save final performance statistics if enabled
   if (SaveTradeStatistics) {
      SavePerformanceStats();
   }

   // Module objects are now on stack, so no need to delete them
   
   // Clean up logger
   if (g_Logger != NULL) {
      delete g_Logger;
      g_Logger = NULL;
      Print("Logger released.");
   }

   g_IsInitialized = false;
   Print("ApexPullback EA v10.6 shutdown complete.");
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
   if (PropMode && g_DayTrades >= MaxTradesPerDay) {
      if ((TimeCurrent() % 300) == 0)  // Log periodically
         LogMessage("Daily trade limit reached: " + IntegerToString(g_DayTrades) + "/" + IntegerToString(MaxTradesPerDay), false);
      return;
   }
   
   if (RiskMan.IsMaxLossReached()) {
      if ((TimeCurrent() % 300) == 0)  // Log periodically
         LogMessage("Maximum loss limit reached. Trading paused for today.", true);
      return;
   }

   // 5. Update Market Data & Analysis
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
                                           MaxConsecutiveLosses, TimeToString(g_PauseUntil));
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
   if (!Market.Initialize(_Symbol, EntryTimeframe, EMAf, EMAt,
                       UseMultiTimeframe, HigherTimeframe,
                       UseNestedTimeframe, NestedTimeframe,
                       EnableMarketRegimeFilter)) {
      Print("ERROR: Could not initialize Market Monitor parameters.");
      success = false;
   } else {
      LogMessage("Market Monitor initialized.", false);
   }
   
   // Initialize logger settings for MarketMonitor
   if (Market.GetLogger() != NULL) {
      if (!Market.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize MarketMonitor logger settings.");
      }
   }

   // --- Initialize Trade Manager ---
   if (!TradeMan.Initialize(_Symbol, Comment_Prefix, (int)StringToInteger(_Symbol),
                         &Market,
                         TrailingMode, TrailingAtrMultiplier, UseAdaptiveTrailing,
                         BreakEven_R, UseMultipleTargets, TP1_Percent, TP2_Percent, TP3_Percent)) {
      Print("ERROR: Could not initialize Trade Manager parameters.");
      success = false;
   } else {
      LogMessage("Trade Manager initialized.", false);
   }
   
   // Initialize logger settings for TradeManager
   if (TradeMan.GetLogger() != NULL) {
      if (!TradeMan.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize TradeManager logger settings.");
      }
   }

   // --- Initialize Risk Manager ---
   if (!RiskMan.Initialize(_Symbol, RiskPercent, PropMode, DailyLoss, MaxDD,
                        MaxTradesPerDay, MaxConsecutiveLosses, g_DayStartEquity)) {
      Print("ERROR: Could not initialize Risk Manager parameters.");
      success = false;
   } else {
      LogMessage("Risk Manager initialized.", false);
   }
   
   // Initialize logger settings for RiskManager
   if (RiskMan.GetLogger() != NULL) {
      if (!RiskMan.GetLogger().Initialize(EnableDetailedLogs, EnableCsvLog, CsvLogFilename,
             EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
         Print("Warning: Could not initialize RiskManager logger settings.");
      }
   }

   return success;
}

//+------------------------------------------------------------------+
//| Check processing time interval - FIXED                           |
//+------------------------------------------------------------------+
bool CheckProcessingTime()
{
   static ulong lastMillis = 0;
   ulong currentMillis = GetTickCount();
   
   // Avoid excessive tick processing - process no more than once each 50ms
   uint processingInterval = 50;  // Milliseconds minimum interval
   
   if (currentMillis - lastMillis < processingInterval) {
      return false;  // Skip if called too frequently
   }
   
   lastMillis = currentMillis;
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
      RiskMan.ResetDailyStats(g_DayStartEquity);  // RiskManager handles daily stats reset

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
   if (PropMode && g_DayTrades >= MaxTradesPerDay) {
      LogMessage("Daily trade limit reached: " + IntegerToString(MaxTradesPerDay), true);
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
      if ((int)(TimeCurrent() % 300) == 0)  // Log every 5 minutes to avoid spam
         LogMessage("Current spread (" + DoubleToString(currentSpread/_Point, 1) + 
                   " points) exceeds maximum allowed (" + IntegerToString((int)MaxSpreadPoints) + 
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
   double lotSize = RiskMan.CalculateLotSize(_Symbol, stopLossPoints, signal.entryPrice, signal.quality);

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
      TradeMan.FeedbackSignalResult(signal, false, 0, rejectionReason);
      return;
   }

   // Execute trade through Trade Manager
   ulong ticket = 0;
   string scenarioName = GetScenarioName(signal.scenario);

   // Choose execution method based on EntryMode
   if (EntryMode == MODE_MARKET) {
      // Market order execution
      if (signal.isLong) {
         ticket = TradeMan.SafeBuy(lotSize, signal.stopLoss, 0, signal.scenario);
      } else {
         ticket = TradeMan.SafeSell(lotSize, signal.stopLoss, 0, signal.scenario);
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
            ticket = TradeMan.SafeBuy(lotSize, signal.stopLoss, 0, signal.scenario);
         } else {
            ticket = TradeMan.SafeSell(lotSize, signal.stopLoss, 0, signal.scenario);
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
      TradeMan.FeedbackSignalResult(signal, true, ticket);
   } else {
      // Trade execution failed
      string failReason = "Error code: " + IntegerToString(GetLastError());
      LogMessage("Failed to execute " + (signal.isLong ? "BUY" : "SELL") + " order. " + failReason, true);
      
      // Send negative feedback to Market Monitor
      TradeMan.FeedbackSignalResult(signal, false, 0, failReason);
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
   if ((int)NewsFilter == (int)NEWS_NONE)
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
   if ((int)NewsFilter != (int)NEWS_FILE)
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
      case SCENARIO_BULLISH_PULLBACK: return "Bullish Pullback";
      case SCENARIO_BEARISH_PULLBACK: return "Bearish Pullback";
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
   int width = 450, height = 220; // Kích thước lớn hơn để hiển thị đẹp hơn
   
   // Gradient màu nền hiện đại
   color bgColor = C'240,245,250';
   color borderColor = C'70,130,180'; // Steel Blue
   color headerColor = C'25,25,112';  // Dark Blue
   color titleColor = clrWhite;
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
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_WIDTH, 2); // Viền dày hơn
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "Apex_DB_BG", OBJPROP_HIDDEN, true);
   
   // Tạo header
   if(!ObjectCreate(0, "Apex_DB_Header", OBJ_RECTANGLE_LABEL, 0, 0, 0)) {
      LogMessage("Error creating dashboard header", true);
      return false;
   }
   
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_XSIZE, width);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_YSIZE, 30);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_BGCOLOR, headerColor);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_COLOR, headerColor);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_WIDTH, 0);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_BACK, false);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_SELECTED, false);
   ObjectSetInteger(0, "Apex_DB_Header", OBJPROP_HIDDEN, true);
   
   // Create title với thiết kế hiện đại
   CreateLabel("Apex_DB_Title", "ApexPullback v10.6", x + width/2 - 70, y + 8, fontSize + 2, titleColor, true);
   
   // Create info labels with placeholder values - will be updated in UpdateDashboard()
   string items[] = {
      "Status", "Mode", "Market Regime", "Current Day Trades",
      "Account Balance", "Equity", "Win Rate", "Profit Factor", 
      "Daily P/L", "Total Trades", "Consec. Wins", "Consec. Losses",
      "Last Signal", "Current Trend", "ATR"
   };
   
   // Phân chia thành 2 cột để hiển thị rõ ràng hơn
   int items_per_column = (ArraySize(items) + 1) / 2; // Chia đều các mục thông tin cho 2 cột
   int col_width = 180; // Khoảng cách giữa 2 cột
   
   for(int i = 0; i < ArraySize(items); i++) {
      string name = "Apex_DB_" + items[i];
      
      // Tính toán vị trí x, y cho mỗi mục dựa trên chỉ số
      int col = i / items_per_column; // 0 = cột trái, 1 = cột phải
      int row = i % items_per_column; // Vị trí hàng trong cột
      
      int item_x = x + 10 + col * col_width;
      int item_y = y + 40 + row * 18;
      
      // Tạo nhãn và giá trị tương ứng
      CreateLabel(name + "_Label", items[i] + ":", item_x, item_y, fontSize, clrNavy, false);
      CreateLabel(name + "_Value", "---", item_x + 120, item_y, fontSize, clrNavy, false);
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
//| Update dashboard information - IMPROVED                          |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if (!DisplayDashboard) return;
   
   // Theo dõi thởi gian cập nhật
   static datetime lastUpdateTime = 0;
   datetime currentTime = TimeCurrent();
   
   // Tính khoảng thởi gian cập nhật dựa trên DisplayMode và tải CPU
   int updateInterval = 2; // Mặc định 2 giây
   
   // Điều chỉnh dựa trên DisplayMode
   if (DisplayMode == 0) { // Minimal
      updateInterval = 10; // Mỗi 10 giây
   } else if (DisplayMode == 1) { // Standard
      updateInterval = 5;  // Mỗi 5 giây
   } 
   // DisplayMode == 2 (Detailed) giữ mặc định 2 giây
   
   // Điều chỉnh thêm dựa trên tải CPU nếu quá cao
   double cpuUsage = 50.0; // Giá trị cố định thay vì đọc từ TERMINAL_CPU_USAGE
   
   // Điều chỉnh thêm dựa trên mức sử dụng bộ nhớ nếu quá cao
   double memoryUsage = (double)TerminalInfoInteger(TERMINAL_MEMORY_USED) / TerminalInfoInteger(TERMINAL_MEMORY_TOTAL);
   if (memoryUsage > 0.6) { // Nếu sử dụng hơn 60% bộ nhớ có sẵn
      updateInterval *= 2; // Tăng gấp đôi khoảng cập nhật
   }
   
   // Chỉ cập nhật nếu đã qua đủ thởi gian
   if (currentTime - lastUpdateTime < updateInterval) return;
   
   // Ghi nhớ thởi gian cập nhật
   lastUpdateTime = currentTime;

   // EA Status với màu sắc thông minh
   string status = (TimeCurrent() < g_PauseUntil) ? 
                  "PAUSED until " + TimeToString(g_PauseUntil, TIME_MINUTES) : "ACTIVE";
   color statusColor = (TimeCurrent() < g_PauseUntil) ? C'180,180,180' : C'0,128,0'; // Grey khi Paused, Green khi Active
   ObjectSetString(0, "Apex_DB_Status_Value", OBJPROP_TEXT, status);
   ObjectSetInteger(0, "Apex_DB_Status_Value", OBJPROP_COLOR, statusColor);
   
   // Mode với font đậm hơn
   string modeText = PropMode ? "Prop Firm" : "Standard";
   ObjectSetString(0, "Apex_DB_Mode_Value", OBJPROP_TEXT, modeText);
   ObjectSetInteger(0, "Apex_DB_Mode_Value", OBJPROP_FONTSIZE, 9);
   
   // Market Regime với màu sắc đặc trưng
   string regimeText = "";
   color regimeColor = clrBlack;
   switch(Market.GetMarketState()) {
      case REGIME_STRONG_TREND: 
         regimeText = "Strong Trend"; 
         regimeColor = C'0,0,139'; // Dark Blue - xu hướng mạnh
         break;
      case REGIME_WEAK_TREND: 
         regimeText = "Weak Trend"; 
         regimeColor = C'65,105,225'; // Royal Blue - xu hướng yếu
         break;
      case REGIME_RANGING: 
         regimeText = "Ranging"; 
         regimeColor = C'128,128,128'; // Grey - sideway
         break;
      case REGIME_VOLATILE: 
         regimeText = "Volatile"; 
         regimeColor = C'178,34,34'; // Firebrick - biến động mạnh
         break;
   }
   ObjectSetString(0, "Apex_DB_Market Regime_Value", OBJPROP_TEXT, regimeText);
   ObjectSetInteger(0, "Apex_DB_Market Regime_Value", OBJPROP_COLOR, regimeColor);
   
   // Current Day Trades với màu sắc dựa trên tỷ lệ so với giới hạn
   int dayTrades = g_DayTrades;
   color tradesColor = (dayTrades > MaxTradesPerDay*0.7) ? C'139,0,0' : 
                     (dayTrades > MaxTradesPerDay*0.3) ? C'205,133,63' : C'0,100,0';
   ObjectSetString(0, "Apex_DB_Current Day Trades_Value", OBJPROP_TEXT, IntegerToString(dayTrades));
   ObjectSetInteger(0, "Apex_DB_Current Day Trades_Value", OBJPROP_COLOR, tradesColor);
   
   // Account Balance (không thay đổi màu)
   ObjectSetString(0, "Apex_DB_Account Balance_Value", OBJPROP_TEXT, DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
   
   // Equity với màu dựa trên tăng/giảm so với balance
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   color equityColor = (equity > balance) ? C'0,100,0' : (equity < balance) ? C'139,0,0' : clrBlack;
   ObjectSetString(0, "Apex_DB_Equity_Value", OBJPROP_TEXT, DoubleToString(equity, 2));
   ObjectSetInteger(0, "Apex_DB_Equity_Value", OBJPROP_COLOR, equityColor);
   
   // Performance metrics
   static PerformanceMetrics metrics;
   if (RiskMan.GetPerformanceMetrics(metrics)) {
      // Win Rate với màu sắc theo mức
      double winRate = metrics.winRate;
      color winRateColor = (winRate >= 60) ? C'0,100,0' : (winRate >= 45) ? C'205,133,63' : C'139,0,0';
      ObjectSetString(0, "Apex_DB_Win Rate_Value", OBJPROP_TEXT, DoubleToString(winRate, 1) + "%");
      ObjectSetInteger(0, "Apex_DB_Win Rate_Value", OBJPROP_COLOR, winRateColor);
      
      // Profit Factor với màu sắc theo mức
      double profitFactor = metrics.profitFactor;
      color pfColor = (profitFactor >= 1.5) ? C'0,100,0' : (profitFactor >= 1.0) ? C'205,133,63' : C'139,0,0';
      ObjectSetString(0, "Apex_DB_Profit Factor_Value", OBJPROP_TEXT, DoubleToString(profitFactor, 2));
      ObjectSetInteger(0, "Apex_DB_Profit Factor_Value", OBJPROP_COLOR, pfColor);
      
      // Daily P/L
      double dailyPL = AccountInfoDouble(ACCOUNT_EQUITY) - g_DayStartEquity;
      color plColor = (dailyPL > 0) ? C'0,100,0' : (dailyPL < 0) ? C'139,0,0' : clrBlack;
      ObjectSetString(0, "Apex_DB_Daily P/L_Value", OBJPROP_TEXT, DoubleToString(dailyPL, 2));
      ObjectSetInteger(0, "Apex_DB_Daily P/L_Value", OBJPROP_COLOR, plColor);
      
      // Total Trades
      ObjectSetString(0, "Apex_DB_Total Trades_Value", OBJPROP_TEXT, IntegerToString(metrics.totalTrades));
      
      // Consecutive stats
      int consWins = metrics.maxConsecutiveWins;
      int consLosses = metrics.maxConsecutiveLosses;
      
      // Hiển thị consecutive wins với màu xanh khi > 2
      color consWinsColor = (consWins >= 3) ? C'0,100,0' : clrBlack;
      ObjectSetString(0, "Apex_DB_Consec. Wins_Value", OBJPROP_TEXT, IntegerToString(consWins));
      ObjectSetInteger(0, "Apex_DB_Consec. Wins_Value", OBJPROP_COLOR, consWinsColor);
      
      // Hiển thị consecutive losses với màu đỏ khi > 2
      color consLossesColor = (consLosses >= 3) ? C'139,0,0' : clrBlack;
      ObjectSetString(0, "Apex_DB_Consec. Losses_Value", OBJPROP_TEXT, IntegerToString(consLosses));
      ObjectSetInteger(0, "Apex_DB_Consec. Losses_Value", OBJPROP_COLOR, consLossesColor);
   }
   
   // Trend info với màu sắc tương ứng
   string trendText = Market.IsTrendUp() ? "UP" : (Market.IsTrendDown() ? "DOWN" : "NEUTRAL");
   color trendColor = Market.IsTrendUp() ? C'0,100,0' : (Market.IsTrendDown() ? C'139,0,0' : C'128,128,128');
   ObjectSetString(0, "Apex_DB_Current Trend_Value", OBJPROP_TEXT, trendText);
   ObjectSetInteger(0, "Apex_DB_Current Trend_Value", OBJPROP_COLOR, trendColor);
   
   // ATR với màu dựa trên độ biến động
   double atr = Market.GetATR();
   double normalATR = 0;
   // Ước tính ATR bình thường dựa trên giá trị trung bình
   if(Market.GetAverageATR() > 0) {
      normalATR = Market.GetAverageATR();
   } else {
      normalATR = atr; // Nếu không có giá trị trung bình, sử dụng ATR hiện tại
   }
   
   double atrRatio = 1.0; 
   if(normalATR > 0) atrRatio = atr / normalATR;
   
   color atrColor = (atrRatio >= 1.5) ? clrDarkRed : (atrRatio >= 1.2) ? clrDarkOrange : clrDarkBlue;
   ObjectSetString(0, "Apex_DB_ATR_Value", OBJPROP_TEXT, DoubleToString(atr, _Digits));
   ObjectSetInteger(0, "Apex_DB_ATR_Value", OBJPROP_COLOR, atrColor);
   
   // Last Signal với màu tương ứng
   SignalInfo lastSignal;
   if (Market.GetLastSignal(lastSignal)) {
      string signalText = StringFormat("%s: %s", 
                                    lastSignal.isLong ? "BUY" : "SELL",
                                    GetScenarioName(lastSignal.scenario));
      color signalColor = lastSignal.isLong ? C'0,100,0' : C'139,0,0';
      ObjectSetString(0, "Apex_DB_Last Signal_Value", OBJPROP_TEXT, signalText);
      ObjectSetInteger(0, "Apex_DB_Last Signal_Value", OBJPROP_COLOR, signalColor);
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
   if (!SaveTradeStatistics)
      return;

   LogMessage("Saving performance stats...", false);
   
   // 1) Get performance metrics from RiskManager
   static PerformanceMetrics metrics;
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
   Market.SetEnvelopeDeviation(adjustedEnvF);
   TradeMan.SetStopLossAtrMultiplier(adjustedSL_ATR);
   TradeMan.SetTakeProfitRrRatio(adjustedTP_RR);
   
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

//+------------------------------------------------------------------+
//| Tester function - IMPROVED                                      |
//+------------------------------------------------------------------+
double OnTester()
{
   // Tính toán phần trăm thắng
   double winRate = 0.0;
   double profitFactor = 0.0;
   double maxDrawdown = 0.0;
   
   // Lấy thống kê từ RiskManager
   static PerformanceMetrics metrics;
   if (RiskMan.GetPerformanceMetrics(metrics)) {
      winRate = metrics.winRate;
      profitFactor = metrics.profitFactor;
      maxDrawdown = metrics.maxEquityDD;
   }
   
   // Tính toán điểm tester tùy chỉnh
   double customScore = 0.0;
   
   // Nếu có thống kê
   if (winRate > 0 && profitFactor > 0) {
      // Tính điểm dựa trên kết hợp lợi nhuận và rủi ro
      // Ví dụ: Sharpe ratio đơn giản
      double totalTrades = TesterStatistics(STAT_TRADES);
      double grossProfit = TesterStatistics(STAT_GROSS_PROFIT);
      double grossLoss = TesterStatistics(STAT_GROSS_LOSS);
      double netProfit = grossProfit + grossLoss; // grossLoss là số âm
      
      // Tính Modified Sortino Ratio (đề cao drawdown thấp)
      if (maxDrawdown > 0 && netProfit > 0) {
         customScore = netProfit / (maxDrawdown * 2);
      }
      
      // Nhân với Profit Factor và Win Rate để tạo điểm tổng hợp
      customScore *= profitFactor * (winRate / 100.0);
      
      // Phạt nếu quá ít giao dịch
      if (totalTrades < 20) {
         customScore *= (totalTrades / 20.0);
      }
      
      // Lưu thông tin vào file CSV
      SaveBacktestResultsToCSV(
         winRate, 
         profitFactor, 
         maxDrawdown, 
         netProfit, 
         totalTrades, 
         customScore
      );
   }
   
   return customScore;
}

//+------------------------------------------------------------------+
//| Lưu kết quả backtest vào CSV                                     |
//+------------------------------------------------------------------+
void SaveBacktestResultsToCSV(
   double winRate, 
   double profitFactor, 
   double maxDrawdown, 
   double netProfit, 
   double totalTrades, 
   double customScore)
{
   string filename = "ApexPullback_Backtest_Results.csv";
   int fileHandle;
   
   // Kiểm tra file đã tồn tại chưa
   if(FileIsExist(filename, FILE_COMMON)) {
      // Mở file để thêm dữ liệu
      fileHandle = FileOpen(filename, FILE_WRITE|FILE_READ|FILE_CSV|FILE_COMMON);
      if(fileHandle == INVALID_HANDLE) {
         Print("Log open fail: ", GetLastError());
         return;
      }
      
      // Di chuyển con trỏ đến cuối file
      FileSeek(fileHandle, 0, SEEK_END);
   } else {
      // Tạo file mới và thêm header
      fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON);
      if(fileHandle == INVALID_HANDLE) {
         Print("Log open fail: ", GetLastError());
         return;
      }
      
      // Viết header
      FileWrite(fileHandle, 
         "Date", "Symbol", "Timeframe", "EMA Fast", "EMA Trend", 
         "Win Rate", "Profit Factor", "Max Drawdown", "Net Profit", 
         "Total Trades", "Custom Score"
      );
   }
   
   // Ghi kết quả
   FileWrite(fileHandle, 
      TimeToString(TimeCurrent(), TIME_DATE), 
      _Symbol, 
      EnumToString((ENUM_TIMEFRAMES)Period()), 
      IntegerToString(EMAf), 
      IntegerToString(EMAt), 
      DoubleToString(winRate, 2), 
      DoubleToString(profitFactor, 2), 
      DoubleToString(maxDrawdown, 2), 
      DoubleToString(netProfit, 2), 
      DoubleToString(totalTrades, 0), 
      DoubleToString(customScore, 4)
   );
   
   FileClose(fileHandle);
}

//--- Input parameters được nhóm gọn gàng 

// === LOGGING & THÔNG BÁO ===
sinput string LoggingSection = "=== Logging & Notification Settings ==="; // === THIẾT LẬP LOGGING & THÔNG BÁO ===
input bool   EnableDetailedLogs = false;      // Bật logs chi tiết
input bool   EnableCsvLog = false;            // Lưu logs vào file CSV
input string CsvLogFilename = "ApexPullback_log.csv"; // Tên file CSV log
input bool   EnableTelegramNotify = false;    // Gửi thông báo qua Telegram
input string TelegramBotToken = "";           // Telegram Bot Token
input string TelegramChatID = "";             // Telegram Chat ID
input bool   TelegramImportantOnly = true;    // Chỉ gửi thông báo quan trọng

// === LỌC TIN TỨC & CẢNH BÁO ===
sinput string NewsSection = "=== News Filter Settings ==="; // === THIẾT LẬP LỌC TIN TỨC ===
input ENUM_NEWS_FILTER NewsFilter = NEWS_NONE; // Phương pháp lọc tin tức
input int    NewsImpactLevel = 2;              // Mức độ ảnh hưởng (1=Thấp, 2=Trung bình, 3=Cao)
input int    NewsWindowBefore = 30;            // Phút trước tin (tránh giao dịch)
input int    NewsWindowAfter = 15;             // Phút sau tin (tránh giao dịch)
input string NEWS_FILE = "news_calendar.csv";  // Tên file lịch tin tức
input bool   Alert_Enabled = true;             // Bật thông báo
input bool   Alert_Email = false;              // Gửi email thông báo
input bool   Alert_PushNotification = false;   // Gửi thông báo push

// === CHIẾN LƯỢC & KHUNG THỜI GIAN ===
sinput string StrategySection = "=== Strategy & Timeframe Settings ==="; // === THIẾT LẬP CHIẾN LƯỢC & KHUNG THỜI GIAN ===
input ENUM_ENTRY_MODE EntryMode = MODE_MARKET; // Phương thức vào lệnh
input ENUM_TIMEFRAMES EntryTimeframe = PERIOD_H1; // Khung thởi gian vào lệnh chính
input int    EMAf = 34;                       // EMA nhanh (kỳ)
input int    EMAt = 89;                       // EMA xu hướng (kỳ)
input double EnvF = 0.001;                    // Độ lệch biên (mặc định 0.1%)
input bool   UseMultiTimeframe = true;        // Sử dụng phân tích đa khung
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H4; // Khung thởi gian cao hơn
input bool   UseNestedTimeframe = true;       // Sử dụng khung thởi gian lồng ghép
input ENUM_TIMEFRAMES NestedTimeframe = PERIOD_M15; // Khung thởi gian lồng ghép
input bool   EnableMarketRegimeFilter = true; // Bật lọc trạng thái thị trường
input ENUM_MARKET_PRESET Preset = PRESET_AUTO; // Tự động phát hiện loại thị trường

// === QUẢN LÝ GIAO DỊCH & VỊ THẾ ===
sinput string TradingSection = "=== Trading & Position Management Settings ==="; // === THIẾT LẬP QUẢN LÝ GIAO DỊCH & VỊ THẾ ===
input int    MaxPositions = 5;                // Số vị thế tối đa
input string Comment_Prefix = "ApexPB";       // Tiền tố comment giao dịch
input bool   AllowNewTrades = true;           // Cho phép mở lệnh mới
input double RiskPercent = 1.0;               // Tỷ lệ rủi ro (% vốn)
input double MaxSpreadPoints = 50;            // Spread tối đa cho phép (điểm)
input int    g_MinPullbackPct = 20;           // Tỷ lệ pullback tối thiểu
input int    g_MaxPullbackPct = 60;           // Tỷ lệ pullback tối đa
input int    LookbackBars = 20;               // Số nến nhìn lại để phân tích
input double SL_ATR = 1.2;                    // Hệ số ATR cho SL
input double TP_RR = 1.5;                     // Tỷ lệ TP/SL (R:R)
input bool   UseDynamicLotSize = true;        // Sử dụng lot size động theo biến động
input double MinLotMultiplier = 0.5;          // Hệ số lot size tối thiểu
input double MaxVolatilityFactor = 2.0;       // Hệ số biến động tối đa

// === HÒA VỐN & CHỐT LỜI ===
sinput string TPSection = "=== Breakeven & Take Profit Settings ==="; // === THIẾT LẬP HÒA VỐN & CHỐT LỜI ===
input ENUM_TRAILING_MODE TrailingMode = TRAILING_MODE_ATR; // Phương thức Trailing Stop
input double TrailingAtrMultiplier = 2.0;     // Hệ số ATR cho Trailing Stop
input double BreakEven_R = 1.0;               // Mức R để kích hoạt breakeven
input bool   UseMultipleTargets = true;       // Sử dụng nhiều mục tiêu TP
input int    TP1_Percent = 30;                // Phần trăm đóng tại TP1
input int    TP2_Percent = 30;                // Phần trăm đóng tại TP2
input int    TP3_Percent = 40;                // Phần trăm đóng tại TP3

// === TRAILING STOP NÂNG CAO ===
sinput string TrailingStopSection = "=== Advanced Trailing Stop Settings ==="; // === THIẾT LẬP TRAILING STOP NÂNG CAO ===
input bool   UseAdaptiveTrailing = true;      // Sử dụng trailing stop thích ứng (dựa trên ADX)
input double AdxThreshold = 20.0;             // Ngưỡng ADX (xu hướng trung bình)
input double AdxStrongThreshold = 30.0;       // Ngưỡng ADX (xu hướng mạnh)

// === HIỂN THỊ & GIAO DIỆN ===
sinput string DisplaySection = "=== Display & Interface Settings ==="; // === THIẾT LẬP HIỂN THỊ & GIAO DIỆN ===
input bool   DisplayDashboard = true;         // Hiển thị bảng điều khiển
input int    DisplayMode = 1;                 // Chế độ hiển thị (0=Tối thiểu, 1=Tiêu chuẩn, 2=Chi tiết)
input int    TrendMode = 1;                   // Chế độ xu hướng (0=Không, 1=Đường, 2=Vùng)
input bool   SaveTradeStatistics = true;      // Lưu thống kê giao dịch

// === LỌC PHIÊN GIAO DỊCH ===
sinput string SessionSection = "=== Session Filter Settings ==="; // === THIẾT LẬP LỌC PHIÊN GIAO DỊCH ===
input bool   FilterBySession = false;         // Lọc giao dịch theo phiên
input int    SessionStartHour = 7;            // Giờ bắt đầu phiên (GMT)
input int    SessionStartMinute = 0;          // Phút bắt đầu phiên
input int    SessionEndHour = 17;             // Giờ kết thúc phiên (GMT)
input int    SessionEndMinute = 0;            // Phút kết thúc phiên
input int    GMT_Offset = 0;                  // Độ lệch GMT

// === THIẾT LẬP TÙNG THỊ TRƯỜNG ===
sinput string MarketFactorsSection = "=== Market Multiplier Settings ==="; // === THIẾT LẬP HỆ SỐ THỊ TRƯỜNG ===
input double FX_EnvF_Multiplier = 1.0;        // Hệ số Envelope cho Forex
input double FX_SL_ATR_Multiplier = 1.0;      // Hệ số SL ATR cho Forex
input double FX_TP_RR_Multiplier = 1.0;       // Hệ số TP/SL cho Forex
input double GOLD_EnvF_Multiplier = 1.5;      // Hệ số Envelope cho Vàng
input double GOLD_SL_ATR_Multiplier = 1.5;    // Hệ số SL ATR cho Vàng
input double GOLD_TP_RR_Multiplier = 1.3;     // Hệ số TP/SL cho Vàng
input double CRYPTO_EnvF_Multiplier = 2.0;    // Hệ số Envelope cho Crypto
input double CRYPTO_SL_ATR_Multiplier = 2.0;  // Hệ số SL ATR cho Crypto
input double CRYPTO_TP_RR_Multiplier = 1.5;   // Hệ số TP/SL cho Crypto

// === QUẢN LÝ RỦI RO ===
sinput string RiskManagementSection = "=== Risk Management Settings ==="; // === THIẾT LẬP QUẢN LÝ RỦI RO ===
input bool   PropMode = false;                // Chế độ Prop Firm (giới hạn giao dịch hàng ngày)
input int    MaxTradesPerDay = 5;                // Số giao dịch tối đa mỗi ngày
input double DailyLoss = 0.0;                 // Giới hạn lỗ hàng ngày (% vốn)
input double MaxDD = 0.0;                     // Giới hạn drawdown tối đa (% vốn)
input int    MaxConsecutiveLosses = 3;        // Số lần thua liên tiếp tối đa
input bool   EnableAutoPause = true;          // Tự động tạm dừng khi đạt giới hạn DD
input int    PauseMinutes = 240;              // Số phút tạm dừng sau khi đạt giới hạn