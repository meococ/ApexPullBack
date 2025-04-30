//+------------------------------------------------------------------+
//| Trade Manager Class                                              |
//| Responsible for position management, trailing stops, and         |
//| trade execution across multiple strategies                       |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
   // Core properties
   string               m_Symbol;                // Symbol to trade
   string               m_CommentPrefix;         // Prefix for trade comments
   int                  m_MagicNumber;           // EA identifier
   int                  m_Digits;                // Price decimal places
   CLogger              m_Logger;                // Logging facility
   ENUM_TIMEFRAMES      m_Timeframe;            // Main timeframe
   
   // Market Data Reference
   CMarketMonitor*      m_MarketMonitor;        // Pointer to market monitor module
   
   // Trade & Position Management
   CTrade               m_Trade;                 // Trade execution object
   CPositionInfo        m_Position;              // Position information
   
   // Target tracking
   CArrayObj            m_Targets;               // Array of target information objects
   
   // ATR and SL parameters
   double               m_ATR;                   // Current ATR value
   double               m_SL_ATR;                // ATR multiplier for stop loss
   datetime             m_LastCachedATRTime;     // Time of last ATR cache update
   double               m_CachedATR;             // Cached ATR value

   // Trailing stop settings
   ENUM_TRAILING_MODE   m_TrailingMode;          // Current trailing stop mode
   double               m_TrailingAtrMultiplier; // ATR multiplier for trailing
   bool                 m_UseAdaptiveTrailing;   // Whether to use adaptive trailing
   double               m_AdxThreshold;          // ADX threshold for medium trend
   double               m_AdxStrongThreshold;    // ADX threshold for strong trend
   double               m_BreakEven_R;           // R-multiple for breakeven activation
   
   // Partial close settings
   bool                 m_UseMultipleTargets;    // Use multiple take profit levels
   int                  m_TP1_Percent;           // Percentage to close at TP1
   int                  m_TP2_Percent;           // Percentage to close at TP2
   int                  m_TP3_Percent;           // Percentage to close at TP3
   
   // Trade statistics
   int                  m_TotalTrades;           // Total trades executed
   int                  m_WinningTrades;         // Number of winning trades
   int                  m_LosingTrades;          // Number of losing trades
   double               m_TotalProfit;           // Total profit
   double               m_TotalLoss;             // Total loss
   double               m_LargestWin;            // Largest winning trade
   double               m_LargestLoss;           // Largest losing trade
   int                  m_ConsecutiveWins;       // Current consecutive wins
   int                  m_ConsecutiveLosses;     // Current consecutive losses
   int                  m_MaxConsecutiveWins;    // Maximum consecutive wins
   int                  m_MaxConsecutiveLosses;  // Maximum consecutive losses
   
   // Indicator handles
   int                  m_HandlePSAR;            // Parabolic SAR handle
   int                  m_HandleSuperTrend;      // SuperTrend handle (if used)
   int                  m_HandleATR;             // ATR handle for immediate access
   
   // Hedging parameters
   bool                 m_UseHedging;            // Enable automatic hedging
   double               m_HedgingFibLevel;       // Fibonacci level for hedge trigger
   double               m_HedgingVolume;         // Hedge volume ratio
   
   // Emergency exit parameters
   bool                 m_UseEmergencyExit;      // Enable emergency exit
   double               m_EmergencyRsiLevel;     // RSI threshold for emergency exit
   ENUM_TIMEFRAMES      m_RsiTimeframe;          // Timeframe for RSI
   int                  m_RsiPeriod;             // RSI period
   int                  m_HandleRSI;             // RSI indicator handle

   //--- Private methods ---
   
   // Initialization and cleanup
   void                 InitializeTrailingIndicators();
   void                 ReleaseIndicators();
   
   // Position management methods
   bool                 ManageBreakeven(int targetIndex, double currentPrice, bool isLong);
   void                 ManagePartialClose(int targetIndex, double currentPrice, bool isLong);
   
   // Trailing stop calculation methods
   double               CalculateAtrTrailingStop(bool isLong, double currentPrice, double atr);
   double               CalculateSwingTrailingStop(bool isLong, double atr);
   double               CalculateSuperTrendTrailingStop(bool isLong, double currentPrice);
   double               CalculatePsarTrailingStop(bool isLong);
   double               CalculateEmaTrailingStop(bool isLong);
   
   // Adaptive trailing methods by market regime
   void                 ManageStrongTrendTrailing(ulong ticket, bool isLong, double currentPrice, 
                                                double entryPrice, double currentSL);
   void                 ManageWeakTrendTrailing(ulong ticket, bool isLong, double currentPrice, 
                                              double stopLoss);
   void                 ManageVolatileTrailing(ulong ticket, bool isLong, double currentPrice, 
                                             double entryPrice, double stopLoss);
   void                 ManageRangingTrailing(ulong ticket, bool isLong, double currentPrice, 
                                            double entryPrice, double stopLoss);
   
   // Target management
   int                  FindTargetInfoByTicket(ulong ticket);
   void                 RemoveTargetInfo(int index);
   
   // Data access helpers
   double               GetValidATR();
   double               GetValidEMAFast();
   double               GetValidEMATrend();
   double               FindRecentSwingLevel(bool isLong);
   int                  GetVolumeDigits();
   
   // Advanced features
   bool                 AdjustAdaptiveTrailingStop(ulong ticket, bool isLong, double currentPrice, double stopLoss);
   bool                 CheckEmergencyExit(ulong ticket);

public:
                        CTradeManager(void);
                       ~CTradeManager(void);
   
   // Initialization
   bool                 Initialize(string symbol, string commentPrefix, int magicNumber, 
                                  CMarketMonitor *marketMonitor,
                                  ENUM_TRAILING_MODE trailingMode, 
                                  double trailingAtrMultiplier,
                                  bool useAdaptiveTrailing, 
                                  double breakEvenR,
                                  bool useMultipleTargets, 
                                  int tp1Percent, 
                                  int tp2Percent, 
                                  int tp3Percent);
   
   // Additional initialization for advanced features
   void                 SetHedgingParameters(bool useHedging, double hedgingFibLevel, double hedgingVolume);
   void                 SetEmergencyExitParameters(bool useEmergencyExit, double emergencyRsiLevel, 
                                                 ENUM_TIMEFRAMES rsiTimeframe, int rsiPeriod);
   void                 SetStopLossAtrMultiplier(double slAtrMultiplier) { m_SL_ATR = slAtrMultiplier; }
   void                 SetTakeProfitRrRatio(double tpRrRatio);
   
   // Main functionality methods
   void                 ManageOpenPositions(ENUM_MARKET_REGIME marketRegime);
   ulong                ExecuteBuyOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);
   ulong                ExecuteSellOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);
   ulong                PlaceBuyLimit(double lotSize, double price, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);
   ulong                PlaceSellLimit(double lotSize, double price, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);
   bool                 PositionClose(ulong ticket);
   bool                 PositionClosePartial(ulong ticket, double volume);
   void                 ProcessTradeTransaction(const MqlTradeTransaction& trans,
                                              const MqlTradeRequest& request,
                                              const MqlTradeResult& result);
   bool                 CloseAllPendingOrders();
   bool                 HasOpenPosition(string symbol);
   
   // Target and stop management
   void                 SetSmartTakeProfits(ulong ticket, bool isLong, double entryPrice,
                                          double stopLoss, ENUM_ENTRY_SCENARIO scenario);
   bool                 SetBreakEvenStop(ulong ticket, int offsetPoints);
   
   // Hedging related methods
   void                 CheckAndApplyHedging();
   double               CalculateFibRetracement(double startPrice, double endPrice, double fibLevel);
   bool                 OpenHedgePosition(ENUM_ORDER_TYPE posType, double volume, string originalTicket);
   
   // Signal feedback
   void                 FeedbackSignalResult(SignalInfo &signal, bool success, ulong ticket, string failReason = "");
   
   // Accessors
   int                  GetTotalTrades() const { return m_TotalTrades; }
   int                  GetWinningTrades() const { return m_WinningTrades; }
   int                  GetLosingTrades() const { return m_LosingTrades; }
   double               GetWinRate() const { return m_TotalTrades > 0 ? (double)m_WinningTrades / m_TotalTrades : 0; }
   double               GetTotalProfit() const { return m_TotalProfit; }
   double               GetTotalLoss() const { return m_TotalLoss; }
   double               GetNetProfit() const { return m_TotalProfit - m_TotalLoss; }
   double               GetProfitFactor() const { return m_TotalLoss > 0 ? m_TotalProfit / m_TotalLoss : (m_TotalProfit > 0 ? 999.0 : 0); }
   int                  GetMagicNumber() const { return m_MagicNumber; }
   int                  GetConsecutiveLosses() const { return m_ConsecutiveLosses; }
   CLogger*             GetLogger() const { return &m_Logger; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager(void)
{
   // Initialize member variables with default values
   m_Symbol = "";
   m_CommentPrefix = "ApexPB_";
   m_MagicNumber = 0;
   m_Digits = 5;  // Will be updated on initialization

   // Set default trading parameters
   m_TrailingMode = TRAILING_ATR;
   m_TrailingAtrMultiplier = 3.0;
   m_UseAdaptiveTrailing = true;
   m_AdxThreshold = 20.0;
   m_AdxStrongThreshold = 30.0;
   m_BreakEven_R = 1.0;

   // Set default take profit parameters
   m_UseMultipleTargets = true;
   m_TP1_Percent = 40;
   m_TP2_Percent = 40;
   m_TP3_Percent = 20;

   // Initialize trade statistics
   m_TotalTrades = 0;
   m_WinningTrades = 0;
   m_LosingTrades = 0;
   m_TotalProfit = 0.0;
   m_TotalLoss = 0.0;
   m_LargestWin = 0.0;
   m_LargestLoss = 0.0;
   m_ConsecutiveWins = 0;
   m_ConsecutiveLosses = 0;
   m_MaxConsecutiveWins = 0;
   m_MaxConsecutiveLosses = 0;

   // Initialize indicator handles
   m_HandleSuperTrend = INVALID_HANDLE;
   m_HandlePSAR = INVALID_HANDLE;
   m_HandleATR = INVALID_HANDLE;
   m_HandleRSI = INVALID_HANDLE;

   // Initialize advanced features
   m_UseHedging = false;
   m_HedgingFibLevel = 0.618;
   m_HedgingVolume = 0.5;

   m_UseEmergencyExit = false;
   m_EmergencyRsiLevel = 70.0;
   m_RsiTimeframe = PERIOD_H1;
   m_RsiPeriod = 14;

   // Initialize ATR caching
   m_LastCachedATRTime = 0;
   m_CachedATR = 0;

   // Initialize logger
   m_MarketMonitor = NULL;
   
   // Initialize the targets array
   m_Targets.Clear();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager(void)
{
   // Release indicator handles
   ReleaseIndicators();

   // Clear targets array
   m_Targets.Clear();

   // Delete logger
   // m_Logger đã được chuyển thành đối tượng nên không cần delete
   // if (m_Logger != NULL) {
   //    delete m_Logger;
   //    m_Logger = NULL;
   // }
   
   // Note: MarketMonitor is not deleted here as it's owned by the EA
}

//+------------------------------------------------------------------+
//| Initialize the TradeManager                                      |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(string symbol, string commentPrefix, int magicNumber, 
                              CMarketMonitor *marketMonitor,
                              ENUM_TRAILING_MODE trailingMode, double trailingAtrMultiplier,
                              bool useAdaptiveTrailing, double breakEvenR,
                              bool useMultipleTargets, int tp1Percent, int tp2Percent, int tp3Percent)
{
   // Store basic parameters
   m_Symbol = symbol;
   m_CommentPrefix = commentPrefix;
   m_MagicNumber = magicNumber;
   m_MarketMonitor = marketMonitor;
   m_Digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);

   // Validate MarketMonitor pointer
   if (m_MarketMonitor == NULL) {
      m_Logger.LogError("MarketMonitor pointer is NULL during initialization!");
      return false;
   }

   // Store trailing stop parameters
   m_TrailingMode = trailingMode;
   m_TrailingAtrMultiplier = trailingAtrMultiplier;
   m_UseAdaptiveTrailing = useAdaptiveTrailing;
   m_BreakEven_R = breakEvenR;

   // Store take profit parameters
   m_UseMultipleTargets = useMultipleTargets;
   m_TP1_Percent = tp1Percent;
   m_TP2_Percent = tp2Percent;
   m_TP3_Percent = tp3Percent;

   // Verify take profit percentages sum to 100
   if (m_UseMultipleTargets && (m_TP1_Percent + m_TP2_Percent + m_TP3_Percent != 100)) {
      m_Logger.LogWarning("Take profit percentages do not sum to 100%. Normalizing values.");
      // Normalize percentages to sum to 100
      double total = (double)(m_TP1_Percent + m_TP2_Percent + m_TP3_Percent);
      if (total > 0) {
         m_TP1_Percent = (int)MathRound(m_TP1_Percent * 100.0 / total);
         m_TP2_Percent = (int)MathRound(m_TP2_Percent * 100.0 / total);
         m_TP3_Percent = 100 - m_TP1_Percent - m_TP2_Percent;
      } else {
         // Default values if sum is zero
         m_TP1_Percent = 40;
         m_TP2_Percent = 30;
         m_TP3_Percent = 30;
      }
   }

   // Configure the trade execution object
   m_Trade.SetExpertMagicNumber(m_MagicNumber);
   m_Trade.SetMarginMode();
   m_Trade.SetTypeFillingBySymbol(m_Symbol);
   m_Trade.SetDeviationInPoints(10);  // Default slippage allowance
   
   // Initialize specific trailing indicators based on the selected mode
   InitializeTrailingIndicators();
   
   m_Logger.LogInfo("Trade Manager initialized successfully for " + m_Symbol);
   return true;
}

//+------------------------------------------------------------------+
//| Set hedging parameters                                           |
//+------------------------------------------------------------------+
void CTradeManager::SetHedgingParameters(bool useHedging, double hedgingFibLevel, double hedgingVolume)
{
   m_UseHedging = useHedging;
   m_HedgingFibLevel = MathMax(0.1, MathMin(hedgingFibLevel, 1.0)); // Limit between 0.1 and 1.0
   m_HedgingVolume = MathMax(0.1, MathMin(hedgingVolume, 1.0));     // Limit between 0.1 and 1.0
   
   if (m_UseHedging) {
      m_Logger.LogInfo(StringFormat(
         "Hedging enabled: Fib level=%.2f, Volume ratio=%.2f", 
         m_HedgingFibLevel, m_HedgingVolume
      ));
   }
}

//+------------------------------------------------------------------+
//| Set emergency exit parameters                                    |
//+------------------------------------------------------------------+
void CTradeManager::SetEmergencyExitParameters(bool useEmergencyExit, double emergencyRsiLevel, 
                                              ENUM_TIMEFRAMES rsiTimeframe, int rsiPeriod)
{
   // Store parameters
   m_UseEmergencyExit = useEmergencyExit;
   m_EmergencyRsiLevel = MathMax(50.0, MathMin(emergencyRsiLevel, 100.0)); // Limit between 50-100
   m_RsiTimeframe = rsiTimeframe;
   m_RsiPeriod = MathMax(2, rsiPeriod); // Minimum RSI period of 2
   
   // Initialize RSI indicator if emergency exit is enabled
   if (m_UseEmergencyExit) {
      // Release existing handle if any
      if (m_HandleRSI != INVALID_HANDLE) {
         IndicatorRelease(m_HandleRSI);
      }
      
      // Create new RSI indicator
      m_HandleRSI = iRSI(m_Symbol, m_RsiTimeframe, m_RsiPeriod, PRICE_CLOSE);
      if (m_HandleRSI == INVALID_HANDLE) {
         m_Logger.LogWarning("Failed to create RSI indicator for emergency exit. Error: " + 
                           IntegerToString(GetLastError()));
      } else {
         m_Logger.LogInfo(StringFormat(
            "Emergency exit enabled: RSI level=%.1f, Timeframe=%s, Period=%d", 
            m_EmergencyRsiLevel, EnumToString(m_RsiTimeframe), m_RsiPeriod
         ));
      }
   }
}

//+------------------------------------------------------------------+
//| Initialize trailing indicators                                   |
//+------------------------------------------------------------------+
void CTradeManager::InitializeTrailingIndicators()
{
   // Release any existing indicator handles first
   ReleaseIndicators();
   
   // Create ATR indicator for direct access
   m_HandleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
   if (m_HandleATR == INVALID_HANDLE) {
      m_Logger.LogWarning("Failed to initialize ATR indicator: " + IntegerToString(GetLastError()));
   }
   
   // Create indicators based on the selected trailing mode
   switch (m_TrailingMode) {
      case TRAILING_ATR:
         m_HandlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2);
         if (m_HandlePSAR == INVALID_HANDLE) {
            m_Logger.LogWarning("Failed to initialize PSAR indicator: " + IntegerToString(GetLastError()));
         }
         break;
         
      case TRAILING_SUPERTREND:
         // SuperTrend requires custom indicator implementation
         // m_HandleSuperTrend = iCustom(m_Symbol, PERIOD_CURRENT, "SuperTrend", 10, 3.0);
         m_Logger.LogInfo("SuperTrend mode selected but no custom indicator available. Using ATR fallback.");
         break;
         
      default:
         // Other trailing modes will use indicators from MarketMonitor or calculate as needed
         break;
   }
   
   // If adaptive trailing is enabled, we may need additional indicators
   if (m_UseAdaptiveTrailing) {
      // PSAR is commonly used for adaptive trailing in strong trends
      if (m_HandlePSAR == INVALID_HANDLE) {
         m_HandlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2);
      }
   }
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void CTradeManager::ReleaseIndicators()
{
   if (m_HandleSuperTrend != INVALID_HANDLE) {
      IndicatorRelease(m_HandleSuperTrend);
      m_HandleSuperTrend = INVALID_HANDLE;
   }
   
   if (m_HandlePSAR != INVALID_HANDLE) {
      IndicatorRelease(m_HandlePSAR);
      m_HandlePSAR = INVALID_HANDLE;
   }
   
   if (m_HandleATR != INVALID_HANDLE) {
      IndicatorRelease(m_HandleATR);
      m_HandleATR = INVALID_HANDLE;
   }
   
   if (m_HandleRSI != INVALID_HANDLE) {
      IndicatorRelease(m_HandleRSI);
      m_HandleRSI = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Manage all open positions                                        |
//+------------------------------------------------------------------+
void CTradeManager::ManageOpenPositions(ENUM_MARKET_REGIME marketRegime)
{
   if (m_MarketMonitor == NULL) {
      m_Logger.LogError("MarketMonitor is NULL in ManageOpenPositions!");
      return;
   }

   // Loop through all open positions from newest to oldest
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      // Select position by index
      if (!m_Position.SelectByIndex(i)) continue;
      
      // Only manage positions for our symbol and EA
      if (m_Position.Symbol() != m_Symbol || m_Position.Magic() != m_MagicNumber) continue;

      // Get position details
      ulong ticket = m_Position.Ticket();
      double currentPrice = m_Position.PriceCurrent();
      double entryPrice = m_Position.PriceOpen();
      double stopLoss = m_Position.StopLoss();
      bool isLong = (m_Position.PositionType() == POSITION_TYPE_BUY);

      // Find target info for this position
      int targetIndex = FindTargetInfoByTicket(ticket);
      if (targetIndex < 0) {
         // No target info found - could be a manually added position or hedge
         // Create basic target info for tracking
         TargetInfo* target = new TargetInfo();
         target.ticket = ticket;
         target.entry_price = entryPrice;
         target.risk_points = isLong ? 
                           (entryPrice - stopLoss) / _Point : 
                           (stopLoss - entryPrice) / _Point;
         
         // If risk_points is 0 or negative, set a default based on ATR
         if (target.risk_points <= 0) {
            double atr = GetValidATR();
            if (atr > 0) {
               target.risk_points = (int)(atr * 3.0 / _Point);
            } else {
               target.risk_points = 50; // Default fallback
            }
         }
         
         m_Targets.Add(target);
         targetIndex = m_Targets.Total() - 1;
      }

      // 1. Check for emergency exit if enabled
      if (m_UseEmergencyExit && CheckEmergencyExit(ticket)) {
         // Position was closed by emergency exit
         if (targetIndex >= 0) {
            RemoveTargetInfo(targetIndex);
         }
         continue;
      }

      // 2. Manage breakeven stop
      if (targetIndex >= 0) {
         ManageBreakeven(targetIndex, currentPrice, isLong);
      }

      // 3. Manage trailing stop - first get updated stopLoss in case it changed
      if (!m_Position.SelectByTicket(ticket)) continue; // Re-select position
      stopLoss = m_Position.StopLoss();

      if (m_UseAdaptiveTrailing) {
         // Apply adaptive trailing stop based on market regime
         switch (marketRegime) {
            case REGIME_STRONG_TREND:
               ManageStrongTrendTrailing(ticket, isLong, currentPrice, entryPrice, stopLoss);
               break;
            case REGIME_WEAK_TREND:
               ManageWeakTrendTrailing(ticket, isLong, currentPrice, stopLoss);
               break;
            case REGIME_VOLATILE:
               ManageVolatileTrailing(ticket, isLong, currentPrice, entryPrice, stopLoss);
               break;
            case REGIME_RANGING:
               ManageRangingTrailing(ticket, isLong, currentPrice, entryPrice, stopLoss);
               break;
         }
      } else {
         // Use the selected standard trailing method
         double newStopLoss = 0;
         double atr = GetValidATR();
         
         if (atr <= 0) {
            // Can't trail without valid ATR for most methods
            continue;
         }

         switch (m_TrailingMode) {
            case TRAILING_ATR:
               newStopLoss = CalculateAtrTrailingStop(isLong, currentPrice, atr);
               break;
            case TRAILING_SWING:
               newStopLoss = CalculateSwingTrailingStop(isLong, atr);
               break;
            case TRAILING_SUPERTREND:
               newStopLoss = CalculateSuperTrendTrailingStop(isLong, currentPrice);
               break;
            case TRAILING_PSAR:
               newStopLoss = CalculatePsarTrailingStop(isLong);
               break;
            case TRAILING_EMA:
               newStopLoss = CalculateEmaTrailingStop(isLong);
               break;
         }

         // Apply the calculated trailing stop if valid and better than current stop
         if (newStopLoss > 0) {
            bool shouldUpdate = false;
            
            if (isLong) {
               // For long positions, new stop must be higher and below current price
               shouldUpdate = newStopLoss > stopLoss && newStopLoss < currentPrice;
            } else {
               // For short positions, new stop must be lower (or first stop for zero SL) 
               // and above current price
               shouldUpdate = (stopLoss == 0 || newStopLoss < stopLoss) && newStopLoss > currentPrice;
            }
            
            if (shouldUpdate) {
               double currentTakeProfit = m_Position.TakeProfit();
               
               // Apply normalized stop with proper precision
               newStopLoss = NormalizeDouble(newStopLoss, m_Digits);
               
               if (m_Trade.PositionModify(ticket, newStopLoss, currentTakeProfit)) {
                  m_Logger.LogInfo(StringFormat(
                     "Updated trailing stop (#%d): %.5f", 
                     ticket, newStopLoss
                  ));
               } else {
                  m_Logger.LogWarning(StringFormat(
                     "Failed to update trailing stop (#%d): Error %d", 
                     ticket, GetLastError()
                  ));
               }
            }
         }
      }

      // 4. Manage partial close (if position still exists)
      if (m_Position.SelectByTicket(ticket) && m_UseMultipleTargets) {
         ManagePartialClose(targetIndex, currentPrice, isLong);
      } else if (targetIndex >= 0 && !m_Position.SelectByTicket(ticket)) {
         // Position may have been closed by trailing stop
         RemoveTargetInfo(targetIndex);
      }
   }
   
   // 5. Check for hedging opportunities if enabled
   if (m_UseHedging) {
      CheckAndApplyHedging();
   }
}

//+------------------------------------------------------------------+
//| Manage breakeven stop                                           |
//+------------------------------------------------------------------+
bool CTradeManager::ManageBreakeven(int targetIndex, double currentPrice, bool isLong)
{
   if (targetIndex < 0 || targetIndex >= m_Targets.Total()) return false;

   TargetInfo* target = m_Targets.At(targetIndex);
   if (target == NULL || target.move_breakeven || target.risk_points <= 0) return false;

   // Calculate current profit in points
   double currentProfitPoints = isLong ? 
                             (currentPrice - target.entry_price) / _Point :
                             (target.entry_price - currentPrice) / _Point;

   // Check if profit reaches the breakeven R level
   if (currentProfitPoints >= target.risk_points * m_BreakEven_R) {
      if (SetBreakEvenStop(target.ticket, 5)) { // Default 5 points buffer
         target.move_breakeven = true;
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Manage partial close at multiple targets                         |
//+------------------------------------------------------------------+
void CTradeManager::ManagePartialClose(int targetIndex, double currentPrice, bool isLong)
{
   if (targetIndex < 0 || targetIndex >= m_Targets.Total()) return;

   TargetInfo* target = m_Targets.At(targetIndex);
   if (target == NULL) return;

   ulong ticket = target.ticket;
   
   // Ensure position still exists
   if (!m_Position.SelectByTicket(ticket)) return;
   
   double currentVolume = m_Position.Volume();
   if (currentVolume <= 0) return;

   // Get minimum volume for the symbol
   double minVolume = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
   
   // Check TP1
   if (!target.tp1_hit && target.tp1 > 0 && 
       ((isLong && currentPrice >= target.tp1) || (!isLong && currentPrice <= target.tp1)))
   {
      // Mark TP1 as hit
      target.tp1_hit = true;
      
      // Calculate volume to close
      double closeVolume = NormalizeDouble(currentVolume * target.tp1_percent / 100.0, GetVolumeDigits());
      
      // Ensure close volume is valid
      if (closeVolume >= minVolume && closeVolume < currentVolume)
      {
         // Partially close position
         if (PositionClosePartial(ticket, closeVolume))
         {
            m_Logger.LogInfo(StringFormat(
               "TP1 Hit (#%d): Closed %.2f lots (%.1f%%)", 
               ticket, closeVolume, (double)target.tp1_percent
            ));
            
            // Move SL to breakeven after TP1
            SetBreakEvenStop(ticket, 5);
         } 
         else {
            // Failed to close - reset hit flag
            target.tp1_hit = false;
         }
      }
      else if (closeVolume >= currentVolume) {
         // Close full position if partial would be >= current volume
         if (PositionClose(ticket)) {
            m_Logger.LogInfo(StringFormat(
               "TP1 Hit (#%d): Closed full position %.2f lots", 
               ticket, currentVolume
            ));
            RemoveTargetInfo(targetIndex);
            return;
         } else {
            target.tp1_hit = false;
         }
      }
   }

   // Check TP2 - Ensure position still exists after potential TP1 closure
   if (!m_Position.SelectByTicket(ticket)) return;
   currentVolume = m_Position.Volume();
   
   if (target.tp1_hit && !target.tp2_hit && target.tp2 > 0 && 
       ((isLong && currentPrice >= target.tp2) || (!isLong && currentPrice <= target.tp2)))
   {
      target.tp2_hit = true;
      
      // Calculate remaining percentage after TP1
      double remainingPercent = 100.0 - target.tp1_percent;
      if (remainingPercent <= 0) remainingPercent = 100.0;
      
      // Calculate volume to close
      double closeVolume = NormalizeDouble(currentVolume * target.tp2_percent / remainingPercent, GetVolumeDigits());
      
      if (closeVolume >= minVolume && closeVolume < currentVolume)
      {
         if (PositionClosePartial(ticket, closeVolume))
         {
            m_Logger.LogInfo(StringFormat(
               "TP2 Hit (#%d): Closed %.2f lots (%.1f%%)", 
               ticket, closeVolume, (double)target.tp2_percent
            ));
            
            // Tighten SL further after TP2
            double atr = GetValidATR();
            if (atr > 0 && m_Position.SelectByTicket(ticket)) {
               double newSL = isLong ? currentPrice - atr * 0.8 : currentPrice + atr * 0.8;
               newSL = NormalizeDouble(newSL, m_Digits);
               double currentTP = m_Position.TakeProfit();
               m_Trade.PositionModify(ticket, newSL, currentTP);
            }
         } else {
            target.tp2_hit = false;
         }
      }
      else if (closeVolume >= currentVolume) {
         if (PositionClose(ticket)) {
            m_Logger.LogInfo(StringFormat(
               "TP2 Hit (#%d): Closed full position %.2f lots", 
               ticket, currentVolume
            ));
            RemoveTargetInfo(targetIndex);
            return;
         } else {
            target.tp2_hit = false;
         }
      }
   }

   // Check TP3 - Ensure position still exists after potential TP2 closure
   if (!m_Position.SelectByTicket(ticket)) return;
   
   if (target.tp1_hit && target.tp2_hit && !target.tp3_hit && target.tp3 > 0 && 
       ((isLong && currentPrice >= target.tp3) || (!isLong && currentPrice <= target.tp3)))
   {
      target.tp3_hit = true;
      
      // Close remaining position at TP3
      if (PositionClose(ticket))
      {
         m_Logger.LogInfo(StringFormat(
            "TP3 Hit (#%d): Closed remaining position", 
            ticket
         ));
         RemoveTargetInfo(targetIndex);
      } else {
         target.tp3_hit = false;
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate ATR-based trailing stop                                |
//+------------------------------------------------------------------+
double CTradeManager::CalculateAtrTrailingStop(bool isLong, double currentPrice, double atr)
{
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR (<=0) in CalculateAtrTrailingStop");
      return 0;
   }
   
   // Calculate stop distance based on ATR and multiplier
   double atrDistance = atr * m_TrailingAtrMultiplier;
   
   // Calculate stop level based on position direction
   double stopLevel = isLong ? 
                     (currentPrice - atrDistance) : 
                     (currentPrice + atrDistance);
   
   return NormalizeDouble(stopLevel, m_Digits);
}

//+------------------------------------------------------------------+
//| Calculate swing-based trailing stop                              |
//+------------------------------------------------------------------+
double CTradeManager::CalculateSwingTrailingStop(bool isLong, double atr)
{
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR (<=0) in CalculateSwingTrailingStop");
      return 0;
   }
   
   // Find recent swing level
   double swingLevel = FindRecentSwingLevel(isLong);
   if (swingLevel <= 0) return 0;
   
   // Apply buffer based on ATR
   double swingBuffer = atr * 0.3;
   double stopLevel = isLong ? 
                     (swingLevel - swingBuffer) : 
                     (swingLevel + swingBuffer);
   
   return NormalizeDouble(stopLevel, m_Digits);
}

//+------------------------------------------------------------------+
//| Calculate SuperTrend-based trailing stop                         |
//+------------------------------------------------------------------+
double CTradeManager::CalculateSuperTrendTrailingStop(bool isLong, double currentPrice)
{
   // This is a placeholder for SuperTrend calculation
   // Proper implementation requires either:
   // 1. Using a custom SuperTrend indicator
   // 2. Calculating SuperTrend values directly
   
   // SuperTrend calculation basics:
   // 1. Calculate ATR
   // 2. Calculate basic upper/lower bands: (High+Low)/2 ± Factor*ATR
   // 3. Calculate final upper/lower bands based on previous values
   // 4. Determine SuperTrend line based on trend direction
   
   // Fall back to ATR trailing if SuperTrend isn't available
   double atr = GetValidATR();
   if (atr <= 0) return 0;
   
   return CalculateAtrTrailingStop(isLong, currentPrice, atr);
}

//+------------------------------------------------------------------+
//| Calculate PSAR-based trailing stop                               |
//+------------------------------------------------------------------+
double CTradeManager::CalculatePsarTrailingStop(bool isLong)
{
   if (m_HandlePSAR == INVALID_HANDLE) {
      m_Logger.LogWarning("PSAR handle is invalid");
      return 0;
   }

   // Get PSAR values
   double psarBuffer[];
   ArraySetAsSeries(psarBuffer, true);
   
   // Try to get PSAR value with error handling
   if (CopyBuffer(m_HandlePSAR, 0, 0, 1, psarBuffer) <= 0) {
      int error = GetLastError();
      m_Logger.LogWarning(StringFormat(
         "Failed to copy PSAR buffer: Error %d", 
         error
      ));
      
      // Try once more after resetting error
      ResetLastError();
      if (CopyBuffer(m_HandlePSAR, 0, 0, 1, psarBuffer) <= 0) {
         return 0;
      }
   }
   
   // For long positions, only use PSAR if it's below price
   // For short positions, only use PSAR if it's above price
   double currentPrice = isLong ? 
                       SymbolInfoDouble(m_Symbol, SYMBOL_BID) : 
                       SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
   
   if ((isLong && psarBuffer[0] >= currentPrice) || 
       (!isLong && psarBuffer[0] <= currentPrice)) {
      return 0; // PSAR has switched sides, don't use it for trailing
   }
   
   return NormalizeDouble(psarBuffer[0], m_Digits);
}

//+------------------------------------------------------------------+
//| Calculate EMA-based trailing stop                                |
//+------------------------------------------------------------------+
double CTradeManager::CalculateEmaTrailingStop(bool isLong)
{
   if (m_MarketMonitor == NULL) {
      m_Logger.LogWarning("MarketMonitor is NULL in CalculateEmaTrailingStop");
      return 0;
   }

   // Get fast EMA value
   double emaFast = m_MarketMonitor.GetEMAFast();
   if (emaFast <= 0) {
      m_Logger.LogWarning("Invalid EMA value for trailing stop");
      return 0;
   }

   // Apply a buffer based on ATR
   double atr = GetValidATR();
   if (atr <= 0) return 0;

   double buffer = atr * 0.2;
   double stopLevel = isLong ? (emaFast - buffer) : (emaFast + buffer);

   return NormalizeDouble(stopLevel, m_Digits);
}

//+------------------------------------------------------------------+
//| Manage trailing stop in strong trend regime                      |
//+------------------------------------------------------------------+
void CTradeManager::ManageStrongTrendTrailing(ulong ticket, bool isLong, double currentPrice, 
                                             double entryPrice, double currentSL)
{
   // Get ATR value
   double atr = GetValidATR();
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR for strong trend trailing");
      return;
   }
   
   // Get ADX value from MarketMonitor (or calculate if needed)
   double adx = 0;
   if (m_MarketMonitor != NULL) {
      // Use trend EMA as an approximation for ADX strength
      adx = m_MarketMonitor.GetEMATrend();
   }
   
   // Adjust ATR multiplier based on trend strength
   double baseMul = m_TrailingAtrMultiplier;
   double adjustedMul = baseMul;
   
   if (adx > m_AdxStrongThreshold) {
      adjustedMul = baseMul * 1.5;  // Wider stop for very strong trend
   } else if (adx > m_AdxThreshold) {
      adjustedMul = baseMul * 1.2;  // Slightly wider stop for moderate trend
   }
   
   // Calculate new stop loss
   double desiredSL = isLong ?
                     currentPrice - adjustedMul * atr :
                     currentPrice + adjustedMul * atr;
   
   // Only update if new stop is better than current and protects profit
   bool shouldUpdate = false;
   
   if (isLong) {
      shouldUpdate = (desiredSL > currentSL) && (desiredSL < currentPrice) && (desiredSL > entryPrice);
   } else {
      shouldUpdate = (currentSL == 0 || desiredSL < currentSL) && (desiredSL > currentPrice) && (desiredSL < entryPrice);
   }
   
   if (shouldUpdate) {
      // Apply new stop loss
      if (m_Position.SelectByTicket(ticket)) {
         double currentTP = m_Position.TakeProfit();
         desiredSL = NormalizeDouble(desiredSL, m_Digits);
         
         if (m_Trade.PositionModify(ticket, desiredSL, currentTP)) {
            m_Logger.LogInfo(StringFormat(
               "Strong trend trailing: Updated SL for #%d to %.5f (ATR: %.5f, Mult: %.1f)",
               ticket, desiredSL, atr, adjustedMul
            ));
         } else {
            m_Logger.LogWarning(StringFormat(
               "Failed to update SL in strong trend: Error %d",
               GetLastError()
            ));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage trailing stop in weak trend regime                        |
//+------------------------------------------------------------------+
void CTradeManager::ManageWeakTrendTrailing(ulong ticket, bool isLong, double currentPrice, double stopLoss)
{
   // In weak trends, use a combination of swing and ATR for trailing
   double atr = GetValidATR();
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR for weak trend trailing");
      return;
   }
   
   // Try swing-based stop first
   double swingStop = CalculateSwingTrailingStop(isLong, atr);
   
   // Use standard ATR trailing as fallback
   double atrStop = CalculateAtrTrailingStop(isLong, currentPrice, atr);
   
   // Choose the better stop between swing and ATR
   double newStopLoss = 0;
   string methodUsed = "ATR";
   
   if (swingStop > 0) {
      // Use swing stop by default if available
      newStopLoss = swingStop;
      methodUsed = "Swing";
      
      // But check if ATR stop offers better protection
      if (isLong && atrStop > swingStop) {
         newStopLoss = atrStop;
         methodUsed = "ATR";
      } else if (!isLong && atrStop < swingStop) {
         newStopLoss = atrStop;
         methodUsed = "ATR";
      }
   } else {
      // Fall back to ATR if swing detection failed
      newStopLoss = atrStop;
   }
   
   // Apply update if better than current stop
   bool shouldUpdate = false;
   
   if (isLong) {
      shouldUpdate = (newStopLoss > stopLoss) && (newStopLoss < currentPrice);
   } else {
      shouldUpdate = (stopLoss == 0 || newStopLoss < stopLoss) && (newStopLoss > currentPrice);
   }
   
   if (shouldUpdate) {
      // Apply new stop loss
      if (m_Position.SelectByTicket(ticket)) {
         double currentTP = m_Position.TakeProfit();
         newStopLoss = NormalizeDouble(newStopLoss, m_Digits);
         
         if (m_Trade.PositionModify(ticket, newStopLoss, currentTP)) {
            m_Logger.LogInfo(StringFormat(
               "Weak trend trailing (%s): Updated SL for #%d to %.5f",
               methodUsed, ticket, newStopLoss
            ));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage trailing stop in volatile market regime                   |
//+------------------------------------------------------------------+
void CTradeManager::ManageVolatileTrailing(ulong ticket, bool isLong, double currentPrice, 
                                          double entryPrice, double stopLoss)
{
   // In volatile markets, use wider trailing stops to avoid premature exits
   double atr = GetValidATR();
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR for volatile market trailing");
      return;
   }

   // Use wider ATR multiplier to account for volatility
   double atrMultiplier = m_TrailingAtrMultiplier * 1.3;
   double atrTrailDistance = atr * atrMultiplier;
   
   // Calculate new stop loss
   double newStopLoss = isLong ?
                       currentPrice - atrTrailDistance :
                       currentPrice + atrTrailDistance;
                       
   // Check if we should set breakeven instead
   int idx = FindTargetInfoByTicket(ticket);
   if (idx >= 0) {
      TargetInfo* target = m_Targets.At(idx);
      if (target != NULL && target.risk_points > 0) {
         double currentProfitPoints = isLong ?
                                    (currentPrice - entryPrice) / _Point :
                                    (entryPrice - currentPrice) / _Point;
                                    
         // Use a higher threshold (1.5R) for volatile markets before setting breakeven
         if (currentProfitPoints >= target.risk_points * 1.5) {
            // Check if breakeven hasn't been set yet
            if ((isLong && stopLoss < entryPrice) || (!isLong && (stopLoss > entryPrice || stopLoss == 0))) {
               if (SetBreakEvenStop(ticket, 10)) { // Use wider buffer in volatile conditions
                  m_Logger.LogInfo(StringFormat(
                     "Set breakeven+10 in volatile market for #%d (%.1f R profit)",
                     ticket, currentProfitPoints / target.risk_points
                  ));
                  return;
               }
            }
         }
      }
   }
   
   // Apply update if new stop is better than current
   bool shouldUpdate = false;
   
   if (isLong) {
      shouldUpdate = (newStopLoss > stopLoss) && (newStopLoss < currentPrice);
   } else {
      shouldUpdate = (stopLoss == 0 || newStopLoss < stopLoss) && (newStopLoss > currentPrice);
   }
   
   if (shouldUpdate) {
      // Apply new stop loss
      if (m_Position.SelectByTicket(ticket)) {
         double currentTP = m_Position.TakeProfit();
         newStopLoss = NormalizeDouble(newStopLoss, m_Digits);
         
         if (m_Trade.PositionModify(ticket, newStopLoss, currentTP)) {
            m_Logger.LogInfo(StringFormat(
               "Volatile market trailing: Updated SL for #%d to %.5f (ATR: %.5f, Mult: %.1f)",
               ticket, newStopLoss, atr, atrMultiplier
            ));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Manage trailing stop in ranging market regime                    |
//+------------------------------------------------------------------+
void CTradeManager::ManageRangingTrailing(ulong ticket, bool isLong, double currentPrice, 
                                         double entryPrice, double stopLoss)
{
   // In ranging markets, use tighter trailing to protect profits
   double atr = GetValidATR();
   if (atr <= 0) {
      m_Logger.LogWarning("Invalid ATR for ranging market trailing");
      return;
   }

   // Check if we should move to breakeven first
   int idx = FindTargetInfoByTicket(ticket);
   if (idx >= 0) {
      TargetInfo* target = m_Targets.At(idx);
      if (target != NULL && target.risk_points > 0) {
         double currentProfitPoints = isLong ?
                                    (currentPrice - entryPrice) / _Point :
                                    (entryPrice - currentPrice) / _Point;
                                    
         // Use a lower threshold (0.7R) for ranging markets before setting breakeven
         if (currentProfitPoints >= target.risk_points * 0.7) {
            // Check if breakeven hasn't been set yet
            if ((isLong && stopLoss < entryPrice) || (!isLong && (stopLoss > entryPrice || stopLoss == 0))) {
               if (SetBreakEvenStop(ticket, 2)) { // Use tight buffer in ranging conditions
                  m_Logger.LogInfo(StringFormat(
                     "Set breakeven+2 in ranging market for #%d (%.1f R profit)",
                     ticket, currentProfitPoints / target.risk_points
                  ));
                  return;
               }
            }
         }
      }
   }
   
   // If we have some profit, use very tight trailing
   double atrMultiplier = 0.7; // Tight trailing multiplier
   double atrTrailDistance = atr * atrMultiplier;
   
   // Calculate new stop loss
   double newStopLoss = isLong ?
                       currentPrice - atrTrailDistance :
                       currentPrice + atrTrailDistance;
                       
   // Apply update if new stop is better than current
   bool shouldUpdate = false;
   
   if (isLong) {
      shouldUpdate = (newStopLoss > stopLoss) && (newStopLoss < currentPrice);
   } else {
      shouldUpdate = (stopLoss == 0 || newStopLoss < stopLoss) && (newStopLoss > currentPrice);
   }
   
   if (shouldUpdate) {
      // Apply new stop loss
      if (m_Position.SelectByTicket(ticket)) {
         double currentTP = m_Position.TakeProfit();
         newStopLoss = NormalizeDouble(newStopLoss, m_Digits);
         
         if (m_Trade.PositionModify(ticket, newStopLoss, currentTP)) {
            m_Logger.LogInfo(StringFormat(
               "Ranging market trailing: Updated SL for #%d to %.5f (ATR: %.5f, Mult: %.1f)",
               ticket, newStopLoss, atr, atrMultiplier
            ));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Find target info by ticket number                                |
//+------------------------------------------------------------------+
int CTradeManager::FindTargetInfoByTicket(ulong ticket)
{
   for (int i = 0; i < m_Targets.Total(); i++) {
      TargetInfo* target = m_Targets.At(i);
      if (target != NULL && target.ticket == ticket) {
         return i;
      }
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Remove target info from array                                    |
//+------------------------------------------------------------------+
void CTradeManager::RemoveTargetInfo(int index)
{
   if (index >= 0 && index < m_Targets.Total()) {
      // Get pointer to delete properly
      TargetInfo* target = m_Targets.At(index);
      if (target != NULL) {
         delete target;
      }
      
      // Remove from array
      m_Targets.Delete(index);
   }
}

//+------------------------------------------------------------------+
//| Get ATR value with caching for performance                       |
//+------------------------------------------------------------------+
double CTradeManager::GetValidATR()
{
   // Check if we have a valid cached ATR
   datetime currentTime = TimeCurrent();
   if (m_LastCachedATRTime > 0 && currentTime - m_LastCachedATRTime < 30) {
      // Use cached value if less than 30 seconds old
      return m_CachedATR;
   }
   
   // Try to get ATR from MarketMonitor first
   if (m_MarketMonitor != NULL) {
      double atr = m_MarketMonitor.GetATR();
      if (atr > 0) {
         // Cache the value
         m_CachedATR = atr;
         m_LastCachedATRTime = currentTime;
         return atr;
      }
   }
   
   // Fall back to our own ATR indicator if needed
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   if (m_HandleATR != INVALID_HANDLE) {
      if (CopyBuffer(m_HandleATR, 0, 0, 1, atrBuffer) > 0) {
         // Cache the value
         m_CachedATR = atrBuffer[0];
         m_LastCachedATRTime = currentTime;
         return atrBuffer[0];
      }
      
      // Try again after resetting error
      ResetLastError();
      if (CopyBuffer(m_HandleATR, 0, 0, 1, atrBuffer) > 0) {
         m_CachedATR = atrBuffer[0];
         m_LastCachedATRTime = currentTime;
         return atrBuffer[0];
      }
   }
   
   // Last resort - calculate manually
   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if (CopyHigh(m_Symbol, PERIOD_CURRENT, 0, 15, high) > 0 &&
       CopyLow(m_Symbol, PERIOD_CURRENT, 0, 15, low) > 0 &&
       CopyClose(m_Symbol, PERIOD_CURRENT, 0, 15, close) > 0) {
      
      // Simple ATR calculation over last 14 bars
      double sum = 0;
      for (int i = 1; i < 15; i++) {
         double trueRange = MathMax(high[i], close[i+1]) - MathMin(low[i], close[i+1]);
         sum += trueRange;
      }
      
      double calculatedATR = sum / 14.0;
      
      // Cache the calculated value
      m_CachedATR = calculatedATR;
      m_LastCachedATRTime = currentTime;
      return calculatedATR;
   }
   
   // If all methods fail, return last known ATR or default
   if (m_CachedATR > 0) {
      return m_CachedATR;
   }
   
   // Final fallback - use point-based approximation
   int digits = m_Digits;
   if (digits == 3 || digits == 5) {  // Forex pairs typically
      return 0.0010;  // ~10 pips default
   } else {
      return 1.0;     // For other instruments
   }
}

//+------------------------------------------------------------------+
//| Get valid EMA Fast value from MarketMonitor                      |
//+------------------------------------------------------------------+
double CTradeManager::GetValidEMAFast()
{
   if (m_MarketMonitor == NULL) return 0;
   
   double ema = m_MarketMonitor.GetEMAFast();
   if (ema <= 0) {
      m_Logger.LogWarning("Invalid EMA Fast value from MarketMonitor");
   }
   
   return ema;
}

//+------------------------------------------------------------------+
//| Get valid EMA Trend value from MarketMonitor                     |
//+------------------------------------------------------------------+
double CTradeManager::GetValidEMATrend()
{
   if (m_MarketMonitor == NULL) return 0;
   
   double ema = m_MarketMonitor.GetEMATrend();
   if (ema <= 0) {
      m_Logger.LogWarning("Invalid EMA Trend value from MarketMonitor");
   }
   
   return ema;
}

//+------------------------------------------------------------------+
//| Find a recent swing high/low level                               |
//+------------------------------------------------------------------+
double CTradeManager::FindRecentSwingLevel(bool isLong)
{
   // Get price data
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   // Try to get sufficient data for swing detection
   if (CopyHigh(m_Symbol, PERIOD_CURRENT, 0, 30, high) < 30 ||
       CopyLow(m_Symbol, PERIOD_CURRENT, 0, 30, low) < 30) {
      return 0;
   }

   int checkRange = 2;  // Number of bars to check on each side
   
   if (isLong) {
      // Look for a recent swing low (for long positions)
      for (int i = checkRange; i < 25; i++) {
         bool isTrough = true;
         
         // Check if this is a valid swing low
         for (int k = 1; k <= checkRange; k++) {
            if (low[i] >= low[i-k] || low[i] >= low[i+k]) {
               isTrough = false;
               break;
            }
         }
         
         if (isTrough) {
            return low[i];  // Return the first valid swing low
         }
      }
   } else {
      // Look for a recent swing high (for short positions)
      for (int i = checkRange; i < 25; i++) {
         bool isPeak = true;
         
         // Check if this is a valid swing high
         for (int k = 1; k <= checkRange; k++) {
            if (high[i] <= high[i-k] || high[i] <= high[i+k]) {
               isPeak = false;
               break;
            }
         }
         
         if (isPeak) {
            return high[i];  // Return the first valid swing high
         }
      }
   }
   
   return 0;  // No valid swing found
}

//+------------------------------------------------------------------+
//| Get volume precision based on volume step                         |
//+------------------------------------------------------------------+
int CTradeManager::GetVolumeDigits()
{
   double step = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP);
   if (step <= 0) step = 0.01;  // Default to 0.01 if unable to get step
   
   int digits = 0;
   while (step < 1.0 && digits < 10) {
      step *= 10.0;
      digits++;
   }
   
   return digits;
}

//+------------------------------------------------------------------+
//| Set the breakeven stop with optional offset                      |
//+------------------------------------------------------------------+
bool CTradeManager::SetBreakEvenStop(ulong ticket, int offsetPoints)
{
   if (!m_Position.SelectByTicket(ticket)) {
      m_Logger.LogError(StringFormat(
         "Cannot set breakeven - position #%d not found", 
         ticket
      ));
      return false;
   }
   
   bool isLong = (m_Position.PositionType() == POSITION_TYPE_BUY);
   double entry = m_Position.PriceOpen();
   double currentTP = m_Position.TakeProfit();
   
   // Calculate breakeven level with offset
   double newSL = isLong ? 
                 (entry + offsetPoints * _Point) : 
                 (entry - offsetPoints * _Point);
   
   // Normalize and apply
   newSL = NormalizeDouble(newSL, m_Digits);
   
   if (m_Trade.PositionModify(ticket, newSL, currentTP)) {
      m_Logger.LogInfo(StringFormat(
         "Set breakeven stop for #%d at %.5f (offset: %d points)",
         ticket, newSL, offsetPoints
      ));
      
      // Update target info
      int idx = FindTargetInfoByTicket(ticket);
      if (idx >= 0) {
         TargetInfo* target = m_Targets.At(idx);
         if (target) target.move_breakeven = true;
      }
      
      return true;
   } else {
      m_Logger.LogWarning(StringFormat(
         "Failed to set breakeven for #%d: Error %d",
         ticket, GetLastError()
      ));
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if there is an open position for this symbol                |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenPosition(string symbol)
{
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (m_Position.SelectByIndex(i)) {
         if (m_Position.Symbol() == symbol && m_Position.Magic() == m_MagicNumber) {
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Calculate Fibonacci retracement level                            |
//+------------------------------------------------------------------+
double CTradeManager::CalculateFibRetracement(double startPrice, double endPrice, double fibLevel)
{
   // Calculate distance between start and end prices
   double distance = MathAbs(endPrice - startPrice);
   
   // Calculate retracement level based on price direction
   if (endPrice > startPrice) {
      // Price has moved up from start to end
      // Retracement will be a drop from the end price
      return endPrice - (distance * fibLevel);
   } else {
      // Price has moved down from start to end
      // Retracement will be a rise from the end price
      return endPrice + (distance * fibLevel);
   }
}

//+------------------------------------------------------------------+
//| Open hedge position                                              |
//+------------------------------------------------------------------+
bool CTradeManager::OpenHedgePosition(ENUM_ORDER_TYPE posType, double volume, string originalTicket)
{
   double price = 0;
   double sl = 0;
   double tp = 0;
   
   // Get current ATR for stop loss calculation
   double atr = GetValidATR();
   if (atr <= 0) atr = 10 * _Point;  // Fallback if ATR is invalid
   
   // Determine entry price and levels
   if (posType == ORDER_TYPE_BUY) {
      price = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
      sl = price - atr * m_SL_ATR;  // Use ATR for SL
      tp = price + atr * m_SL_ATR;  // 1:1 risk-reward ratio
   } else {
      price = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
      sl = price + atr * m_SL_ATR;
      tp = price - atr * m_SL_ATR;
   }
   
   // Normalize price levels
   sl = NormalizeDouble(sl, m_Digits);
   tp = NormalizeDouble(tp, m_Digits);
   
   // Create comment for the hedge position
   string comment = StringFormat("HEDGE_FOR_%s", originalTicket);
   
   // Open the position
   if (!m_Trade.PositionOpen(m_Symbol, posType, volume, price, sl, tp, comment)) {
      m_Logger.LogError(StringFormat(
         "Failed to open hedge %s position: Error %d", 
         (posType == ORDER_TYPE_BUY) ? "BUY" : "SELL",
         GetLastError()
      ));
      return false;
   }
   
   // Log success
   m_Logger.LogInfo(StringFormat(
      "Opened hedge %s position: %.2f lots at %.5f, SL: %.5f, TP: %.5f, For: #%s",
      (posType == ORDER_TYPE_BUY) ? "BUY" : "SELL",
      volume, price, sl, tp, originalTicket
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Check for opportunities to apply hedging                         |
//+------------------------------------------------------------------+
void CTradeManager::CheckAndApplyHedging()
{
   // Skip if hedging is disabled
   if (!m_UseHedging) return;
   
   // Loop through all open positions
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      if (!m_Position.SelectByIndex(i)) continue;
      
      // Only consider our positions on the managed symbol
      if (m_Position.Symbol() != m_Symbol || m_Position.Magic() != m_MagicNumber) continue;
      
      // Skip positions that are already hedges
      if (StringFind(m_Position.Comment(), "HEDGE") >= 0) continue;
      
      ulong ticket = m_Position.Ticket();
      double entryPrice = m_Position.PriceOpen();
      double volume = m_Position.Volume();
      bool isLong = (m_Position.PositionType() == POSITION_TYPE_BUY);
      double currentPrice = m_Position.PriceCurrent();
      double profit = m_Position.Profit();
      
      // Only consider profitable positions for hedging
      if (profit <= 0) continue;
      
      // Determine extreme price reached since entry
      double extremePrice = entryPrice;
      
      if (isLong) {
         // For long positions, find the highest high reached
         if (m_MarketMonitor != NULL) {
            double highestHigh = m_MarketMonitor.GetHighestHighSinceBar(0);
            if (highestHigh > entryPrice) {
               extremePrice = highestHigh;
            }
         }
         
         // Calculate Fibonacci retracement level
         double fibLevel = CalculateFibRetracement(entryPrice, extremePrice, m_HedgingFibLevel);
         
         // If price has retraced to the Fib level, open a hedge
         if (currentPrice < fibLevel) {
            m_Logger.LogInfo(StringFormat(
               "Hedge trigger for BUY #%d: Price %.5f < Fib %.5f (%.1f%%)",
               ticket, currentPrice, fibLevel, m_HedgingFibLevel * 100
            ));
            
            double hedgeVolume = volume * m_HedgingVolume;
            OpenHedgePosition(ORDER_TYPE_SELL, hedgeVolume, IntegerToString(ticket));
         }
      } else {
         // For short positions, find the lowest low reached
         if (m_MarketMonitor != NULL) {
            double lowestLow = m_MarketMonitor.GetLowestLowSinceBar(0);
            if (lowestLow < entryPrice) {
               extremePrice = lowestLow;
            }
         }
         
         // Calculate Fibonacci retracement level
         double fibLevel = CalculateFibRetracement(entryPrice, extremePrice, m_HedgingFibLevel);
         
         // If price has retraced to the Fib level, open a hedge
         if (currentPrice > fibLevel) {
            m_Logger.LogInfo(StringFormat(
               "Hedge trigger for SELL #%d: Price %.5f > Fib %.5f (%.1f%%)",
               ticket, currentPrice, fibLevel, m_HedgingFibLevel * 100
            ));
            
            double hedgeVolume = volume * m_HedgingVolume;
            OpenHedgePosition(ORDER_TYPE_BUY, hedgeVolume, IntegerToString(ticket));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Apply adaptive trailing stop                                     |
//+------------------------------------------------------------------+
bool CTradeManager::AdjustAdaptiveTrailingStop(ulong ticket, bool isLong, double currentPrice, double stopLoss)
{
   // Get ADX value to assess trend strength
   double adxValue = 0;
   
   // Try to get ADX from MarketMonitor first
   if (m_MarketMonitor != NULL) {
      adxValue = m_MarketMonitor.GetEMATrend(); // Approximate ADX with trend EMA
   } else {
      // Fall back to direct ADX calculation if needed
      int handleADX = iADX(m_Symbol, PERIOD_CURRENT, 14);
      if (handleADX != INVALID_HANDLE) {
         double ADXBuffer[];
         ArraySetAsSeries(ADXBuffer, true);
         if (CopyBuffer(handleADX, 0, 0, 2, ADXBuffer) > 0) {
            adxValue = ADXBuffer[0];
         }
         IndicatorRelease(handleADX);
      }
   }
   
   // Get ATR for trailing stop calculation
   double atrValue = GetValidATR();
   if (atrValue <= 0) return false;
   
   // Adjust ATR multiplier based on trend strength
   double trailingAtrMultiplier = adxValue > m_AdxStrongThreshold ? 4.0 :
                                adxValue > m_AdxThreshold ? 3.0 : 2.5;
   
   // Select position to check for profitability
   if (!m_Position.SelectByTicket(ticket)) return false;
   
   double profit = m_Position.Profit();
   if (profit <= 0) return false; // Only trail profitable positions
   
   // Calculate new stop loss based on adjusted ATR
   double newStopLoss = isLong ?
                       currentPrice - (atrValue * trailingAtrMultiplier) :
                       currentPrice + (atrValue * trailingAtrMultiplier);
   
   // Only update if new stop is better than current
   bool shouldUpdate = false;
   
   if (isLong) {
      shouldUpdate = (newStopLoss > stopLoss) && (newStopLoss < currentPrice);
   } else {
      shouldUpdate = (stopLoss == 0 || newStopLoss < stopLoss) && (newStopLoss > currentPrice);
   }
   
   if (shouldUpdate) {
      // Apply new stop loss
      double takeProfit = m_Position.TakeProfit();
      newStopLoss = NormalizeDouble(newStopLoss, m_Digits);
      
      if (m_Trade.PositionModify(ticket, newStopLoss, takeProfit)) {
         m_Logger.LogInfo(StringFormat(
            "Adaptive trailing stop: Updated SL for #%d to %.5f (ADX: %.1f, Mult: %.1f)",
            ticket, newStopLoss, adxValue, trailingAtrMultiplier
         ));
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Check for emergency exit conditions                              |
//+------------------------------------------------------------------+
bool CTradeManager::CheckEmergencyExit(ulong ticket)
{
   // Skip if emergency exit is disabled
   if (!m_UseEmergencyExit) return false;
   
   // Get RSI value
   double rsiValue = 0;
   bool rsiValid = false;
   
   // Use RSI handle if available
   if (m_HandleRSI != INVALID_HANDLE) {
      double RSIBuffer[];
      ArraySetAsSeries(RSIBuffer, true);
      if (CopyBuffer(m_HandleRSI, 0, 0, 2, RSIBuffer) > 0) {
         rsiValue = RSIBuffer[0];
         rsiValid = true;
      } else {
         // Try again after resetting error
         ResetLastError();
         if (CopyBuffer(m_HandleRSI, 0, 0, 2, RSIBuffer) > 0) {
            rsiValue = RSIBuffer[0];
            rsiValid = true;
         }
      }
   }
   
   // If RSI couldn't be read, create a temporary handle
   if (!rsiValid) {
      int tempRSI = iRSI(m_Symbol, m_RsiTimeframe, m_RsiPeriod, PRICE_CLOSE);
      if (tempRSI != INVALID_HANDLE) {
         double RSIBuffer[];
         ArraySetAsSeries(RSIBuffer, true);
         if (CopyBuffer(tempRSI, 0, 0, 2, RSIBuffer) > 0) {
            rsiValue = RSIBuffer[0];
            rsiValid = true;
         }
         IndicatorRelease(tempRSI);
      }
   }
   
   // Can't evaluate emergency exit without valid RSI
   if (!rsiValid) return false;
   
   // Check position
   if (!m_Position.SelectByTicket(ticket)) return false;
   
   bool isLong = (m_Position.PositionType() == POSITION_TYPE_BUY);
   double profit = m_Position.Profit();
   
   // Only apply to profitable positions
   if (profit <= 0) return false;
   
   // Check RSI conditions
   bool exitCondition = false;
   
   if (isLong && rsiValue > m_EmergencyRsiLevel) {
      // Long position and RSI in extreme overbought
      exitCondition = true;
   } else if (!isLong && rsiValue < (100.0 - m_EmergencyRsiLevel)) {
      // Short position and RSI in extreme oversold
      exitCondition = true;
   }
   
   // Exit position if condition is met
   if (exitCondition) {
      if (PositionClose(ticket)) {
         m_Logger.LogInfo(StringFormat(
            "EMERGENCY EXIT triggered for #%d - RSI: %.1f %s", 
            ticket, rsiValue,
            isLong ? "(extreme overbought)" : "(extreme oversold)"
         ));
         return true;
      } else {
         m_Logger.LogError(StringFormat(
            "Failed to execute emergency exit for #%d. Error: %d",
            ticket, GetLastError()
         ));
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Execute a buy order                                              |
//+------------------------------------------------------------------+
ulong CTradeManager::ExecuteBuyOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
   // Validate inputs
   if (lotSize <= 0) {
      m_Logger.LogError("Invalid lot size for buy order: " + DoubleToString(lotSize, 2));
      return 0;
   }
   
   // Format scenario name for comment
   string scenarioName = "";
   switch (scenario) {
      case SCENARIO_BULLISH_PULLBACK:
         scenarioName = "PULL_BULL";
         break;
      case SCENARIO_FIBONACCI_PULLBACK:
         scenarioName = "FIB_BULL";
         break;
      case SCENARIO_HARMONIC_PATTERN:
         scenarioName = "HARM_BULL";
         break;
      case SCENARIO_MOMENTUM_SHIFT:
         scenarioName = "MOM_BULL";
         break;
      case SCENARIO_LIQUIDITY_GRAB:
         scenarioName = "LIQ_BULL";
         break;
      case SCENARIO_BREAKOUT_FAILURE:
         scenarioName = "BRK_BULL";
         break;
      default:
         scenarioName = "BUY";
         break;
   }
   
   // Create trade comment with prefix
   string comment = m_CommentPrefix + "_" + scenarioName;
   
   // Get current Ask price
   double price = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
   
   // If stop loss wasn't provided, calculate based on ATR
   if (stopLoss <= 0) {
      double atr = GetValidATR();
      if (atr > 0) {
         stopLoss = price - (atr * m_SL_ATR);
      } else {
         // Fallback - use 1% as stop
         stopLoss = price * 0.99;
      }
   }
   
   // Normalize stop loss
   stopLoss = NormalizeDouble(stopLoss, m_Digits);
   
   // If take profit wasn't provided, calculate based on stop
   if (takeProfit <= 0) {
      double riskPoints = price - stopLoss;
      // Use 2:1 reward-to-risk ratio by default
      takeProfit = price + (riskPoints * 2.0);
   }
   
   // Normalize take profit
   takeProfit = NormalizeDouble(takeProfit, m_Digits);
   
   // Execute the order
   if (!m_Trade.Buy(lotSize, m_Symbol, 0, stopLoss, takeProfit, comment)) {
      // Xử lý lỗi chi tiết
      int errorCode = m_Trade.ResultRetcode();
      string errorDesc = m_Trade.ResultRetcodeDescription();
      
      // Log lỗi cụ thể
      string errorMessage = StringFormat(
         "Failed to execute buy order: Error %d (%s)", 
         errorCode, errorDesc
      );
      m_Logger.LogError(errorMessage);
      
      // Xử lý một số lỗi phổ biến
      switch(errorCode) {
         case TRADE_RETCODE_REQUOTE:
            m_Logger.LogWarning("Buy order requoted - consider increasing deviation or retry");
            break;
            
         case TRADE_RETCODE_MARKET_CLOSED:
            m_Logger.LogError("Market closed - cannot place buy order");
            break;
            
         case TRADE_RETCODE_INVALID_STOPS:
            m_Logger.LogError(StringFormat(
               "Invalid stop levels: SL=%.5f, TP=%.5f, Current=%.5f", 
               stopLoss, takeProfit, price
            ));
            break;
            
         case TRADE_RETCODE_INVALID_VOLUME:
            m_Logger.LogError(StringFormat(
               "Invalid volume: %.2f (Min=%.2f, Max=%.2f, Step=%.2f)", 
               lotSize, 
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN),
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MAX),
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP)
            ));
            break;
            
         case TRADE_RETCODE_NOT_ENOUGH_MONEY:
            m_Logger.LogError("Not enough money to execute buy order");
            break;
            
         default:
            // Lỗi khác đã được log ở trên
            break;
      }
      
      return 0;
   }
   
   // Get the ticket number
   ulong ticket = m_Trade.ResultOrder();
   
   // Log the trade
   m_Logger.LogInfo(StringFormat(
      "BUY order executed (#%d): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
      ticket, lotSize, price, stopLoss, takeProfit, scenarioName
   ));
   
   // Create target info
   if (ticket > 0) {
      TargetInfo* target = new TargetInfo();
      target.ticket = ticket;
      target.entry_price = price;
      target.risk_points = (int)((price - stopLoss) / _Point);
      
      // Set take profit levels if multiple targets are enabled
      if (m_UseMultipleTargets) {
         // Calculate take profit levels based on risk
         double risk = price - stopLoss;
         
         // Distribute according to percentages
         target.tp1_percent = m_TP1_Percent;
         target.tp2_percent = m_TP2_Percent;
         target.tp3_percent = m_TP3_Percent;
         
         // Set TP levels at different risk multiples
         target.tp1 = price + risk * 1.0;  // 1R
         target.tp2 = price + risk * 2.0;  // 2R
         target.tp3 = price + risk * 3.0;  // 3R
         
         // For strong patterns, consider setting more aggressive targets
         if (scenario == SCENARIO_HARMONIC_PATTERN || scenario == SCENARIO_FIBONACCI_PULLBACK) {
            target.tp3 = price + risk * 3.5;  // 3.5R for high-quality patterns
         }
      }
      
      m_Targets.Add(target);
   }
   
   return ticket;
}

//+------------------------------------------------------------------+
//| Execute a sell order                                             |
//+------------------------------------------------------------------+
ulong CTradeManager::ExecuteSellOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
   // Validate inputs
   if (lotSize <= 0) {
      m_Logger.LogError("Invalid lot size for sell order: " + DoubleToString(lotSize, 2));
      return 0;
   }
   
   // Format scenario name for comment
   string scenarioName = "";
   switch (scenario) {
      case SCENARIO_BEARISH_PULLBACK:
         scenarioName = "PULL_BEAR";
         break;
      case SCENARIO_FIBONACCI_PULLBACK:
         scenarioName = "FIB_BEAR";
         break;
      case SCENARIO_HARMONIC_PATTERN:
         scenarioName = "HARM_BEAR";
         break;
      case SCENARIO_MOMENTUM_SHIFT:
         scenarioName = "MOM_BEAR";
         break;
      case SCENARIO_LIQUIDITY_GRAB:
         scenarioName = "LIQ_BEAR";
         break;
      case SCENARIO_BREAKOUT_FAILURE:
         scenarioName = "BRK_BEAR";
         break;
      default:
         scenarioName = "SELL";
         break;
   }
   
   // Create trade comment with prefix
   string comment = m_CommentPrefix + "_" + scenarioName;
   
   // Get current Bid price
   double price = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
   
   // If stop loss wasn't provided, calculate based on ATR
   if (stopLoss <= 0) {
      double atr = GetValidATR();
      if (atr > 0) {
         stopLoss = price + (atr * m_SL_ATR);
      } else {
         // Fallback - use 1% as stop
         stopLoss = price * 1.01;
      }
   }
   
   // Normalize stop loss
   stopLoss = NormalizeDouble(stopLoss, m_Digits);
   
   // If take profit wasn't provided, calculate based on stop
   if (takeProfit <= 0) {
      double riskPoints = stopLoss - price;
      // Use 2:1 reward-to-risk ratio by default
      takeProfit = price - (riskPoints * 2.0);
   }
   
   // Normalize take profit
   takeProfit = NormalizeDouble(takeProfit, m_Digits);
   
   // Execute the order
   if (!m_Trade.Sell(lotSize, m_Symbol, 0, stopLoss, takeProfit, comment)) {
      // Xử lý lỗi chi tiết
      int errorCode = m_Trade.ResultRetcode();
      string errorDesc = m_Trade.ResultRetcodeDescription();
      
      // Log lỗi cụ thể
      string errorMessage = StringFormat(
         "Failed to execute sell order: Error %d (%s)", 
         errorCode, errorDesc
      );
      m_Logger.LogError(errorMessage);
      
      // Xử lý một số lỗi phổ biến
      switch(errorCode) {
         case TRADE_RETCODE_REQUOTE:
            m_Logger.LogWarning("Sell order requoted - consider increasing deviation or retry");
            break;
            
         case TRADE_RETCODE_MARKET_CLOSED:
            m_Logger.LogError("Market closed - cannot place sell order");
            break;
            
         case TRADE_RETCODE_INVALID_STOPS:
            m_Logger.LogError(StringFormat(
               "Invalid stop levels: SL=%.5f, TP=%.5f, Current=%.5f", 
               stopLoss, takeProfit, price
            ));
            break;
            
         case TRADE_RETCODE_INVALID_VOLUME:
            m_Logger.LogError(StringFormat(
               "Invalid volume: %.2f (Min=%.2f, Max=%.2f, Step=%.2f)", 
               lotSize, 
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN),
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MAX),
               SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP)
            ));
            break;
            
         case TRADE_RETCODE_NOT_ENOUGH_MONEY:
            m_Logger.LogError("Not enough money to execute sell order");
            break;
            
         default:
            // Lỗi khác đã được log ở trên
            break;
      }
      
      return 0;
   }
   // Get the ticket number
   ulong ticket = m_Trade.ResultOrder();
   
   // Log the trade
   m_Logger.LogInfo(StringFormat(
      "SELL order executed (#%d): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
      ticket, lotSize, price, stopLoss, takeProfit, scenarioName
   ));
   
   // Create target info
   if (ticket > 0) {
      TargetInfo* target = new TargetInfo();
      target.ticket = ticket;
      target.entry_price = price;
      target.risk_points = (int)((stopLoss - price) / _Point);
      
      // Set take profit levels if multiple targets are enabled
      if (m_UseMultipleTargets) {
         // Calculate take profit levels based on risk
         double risk = stopLoss - price;
         
         // Distribute according to percentages
         target.tp1_percent = m_TP1_Percent;
         target.tp2_percent = m_TP2_Percent;
         target.tp3_percent = m_TP3_Percent;
         
         // Set TP levels at different risk multiples
         target.tp1 = price - risk * 1.0;  // 1R
         target.tp2 = price - risk * 2.0;  // 2R
         target.tp3 = price - risk * 3.0;  // 3R
         
         // For strong patterns, consider setting more aggressive targets
         if (scenario == SCENARIO_HARMONIC_PATTERN || scenario == SCENARIO_FIBONACCI_PULLBACK) {
            target.tp3 = price - risk * 3.5;  // 3.5R for high-quality patterns
         }
      }
      
      m_Targets.Add(target);
   }
   
   return ticket;
}

//+------------------------------------------------------------------+
//| Place a buy limit order                                          |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceBuyLimit(double lotSize, double price, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
   // Validate inputs
   if (lotSize <= 0) {
      m_Logger.LogError("Invalid lot size for buy limit: " + DoubleToString(lotSize, 2));
      return 0;
   }
   
   // Format scenario name for comment
   string scenarioName = "LIMIT_" + IntegerToString((int)scenario);
   
   // Create trade comment with prefix
   string comment = m_CommentPrefix + "_" + scenarioName;
   
   // Normalize price
   price = NormalizeDouble(price, m_Digits);
   
   // If stop loss wasn't provided, calculate based on ATR
   if (stopLoss <= 0) {
      double atr = GetValidATR();
      if (atr > 0) {
         stopLoss = price - (atr * m_SL_ATR);
      } else {
         // Fallback - use 1% as stop
         stopLoss = price * 0.99;
      }
   }
   
   // Normalize stop loss
   stopLoss = NormalizeDouble(stopLoss, m_Digits);
   
   // If take profit wasn't provided, calculate based on stop
   if (takeProfit <= 0) {
      double riskPoints = price - stopLoss;
      // Use 2:1 reward-to-risk ratio by default
      takeProfit = price + (riskPoints * 2.0);
   }
   
   // Normalize take profit
   takeProfit = NormalizeDouble(takeProfit, m_Digits);
   
   // Place the limit order
   if (!m_Trade.BuyLimit(lotSize, price, m_Symbol, stopLoss, takeProfit, 0, 0, comment)) {
      m_Logger.LogError(StringFormat(
         "Failed to place buy limit: Error %d (%s)",
         m_Trade.ResultRetcode(), m_Trade.ResultRetcodeDescription()
      ));
      return 0;
   }
   
   // Get the ticket number
   ulong ticket = m_Trade.ResultOrder();
   
   // Log the trade
   m_Logger.LogInfo(StringFormat(
      "BUY LIMIT placed (#%d): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
      ticket, lotSize, price, stopLoss, takeProfit, scenarioName
   ));
   
   return ticket;
}

//+------------------------------------------------------------------+
//| Place a sell limit order                                         |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceSellLimit(double lotSize, double price, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
   // Validate inputs
   if (lotSize <= 0) {
      m_Logger.LogError("Invalid lot size for sell limit: " + DoubleToString(lotSize, 2));
      return 0;
   }
   
   // Format scenario name for comment
   string scenarioName = "LIMIT_" + IntegerToString((int)scenario);
   
   // Create trade comment with prefix
   string comment = m_CommentPrefix + "_" + scenarioName;
   
   // Normalize price
   price = NormalizeDouble(price, m_Digits);
   
   // If stop loss wasn't provided, calculate based on ATR
   if (stopLoss <= 0) {
      double atr = GetValidATR();
      if (atr > 0) {
         stopLoss = price + (atr * m_SL_ATR);
      } else {
         // Fallback - use 1% as stop
         stopLoss = price * 1.01;
      }
   }
   
   // Normalize stop loss
   stopLoss = NormalizeDouble(stopLoss, m_Digits);
   
   // If take profit wasn't provided, calculate based on stop
   if (takeProfit <= 0) {
      double riskPoints = stopLoss - price;
      // Use 2:1 reward-to-risk ratio by default
      takeProfit = price - (riskPoints * 2.0);
   }
   
   // Normalize take profit
   takeProfit = NormalizeDouble(takeProfit, m_Digits);
   
   // Place the limit order
   if (!m_Trade.SellLimit(lotSize, price, m_Symbol, stopLoss, takeProfit, 0, 0, comment)) {
      m_Logger.LogError(StringFormat(
         "Failed to place sell limit: Error %d (%s)",
         m_Trade.ResultRetcode(), m_Trade.ResultRetcodeDescription()
      ));
      return 0;
   }
   
   // Get the ticket number
   ulong ticket = m_Trade.ResultOrder();
   
   // Log the trade
   m_Logger.LogInfo(StringFormat(
      "SELL LIMIT placed (#%d): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
      ticket, lotSize, price, stopLoss, takeProfit, scenarioName
   ));
   
   return ticket;
}

//+------------------------------------------------------------------+
//| Accessors                                                        |
//+------------------------------------------------------------------+
int CTradeManager::GetTotalTrades() const { return m_TotalTrades; }
int CTradeManager::GetWinningTrades() const { return m_WinningTrades; }
int CTradeManager::GetLosingTrades() const { return m_LosingTrades; }
double CTradeManager::GetWinRate() const { return m_TotalTrades > 0 ? (double)m_WinningTrades / m_TotalTrades : 0; }
double CTradeManager::GetTotalProfit() const { return m_TotalProfit; }
double CTradeManager::GetTotalLoss() const { return m_TotalLoss; }
double CTradeManager::GetNetProfit() const { return m_TotalProfit - m_TotalLoss; }
double CTradeManager::GetProfitFactor() const { return m_TotalLoss > 0 ? m_TotalProfit / m_TotalLoss : (m_TotalProfit > 0 ? 999.0 : 0); }
int CTradeManager::GetMagicNumber() const { return m_MagicNumber; }
int CTradeManager::GetConsecutiveLosses() const { return m_ConsecutiveLosses; }
CLogger* CTradeManager::GetLogger() const { return &m_Logger; }