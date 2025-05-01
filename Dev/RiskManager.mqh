//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                       Module Quản lý Rủi ro và Vốn Nâng cao      |
//|                              Version 10.1 - Improved             |
//+------------------------------------------------------------------+
#property copyright "ApexPullback"
#property link      "" // Add your website if applicable
#property version   "10.1"
#property strict

#include <Trade/AccountInfo.mqh> // Use AccountInfo for balance/equity checks
#include <Trade/SymbolInfo.mqh>  // Use SymbolInfo for symbol properties
#include "Logger.mqh"            // Logging utility
#include "CommonStructs.mqh"     // Common enums and structs

//+------------------------------------------------------------------+
//| RiskManager class                                                |
//| Handles risk management: position sizing, account protection,    |
//| performance tracking, and basic portfolio awareness.             |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
   //--- Configuration Parameters ---
   string            m_symbol;                // Symbol chính EA đang chạy (để lấy thông tin mặc định)
   double            m_riskPercent;           // Risk per trade in percentage of balance
   double            m_maxDailyLossPercent;   // Maximum daily loss limit (percentage of start equity)
   double            m_maxDrawdownPercent;    // Maximum drawdown limit (percentage of balance/equity)
   int               m_maxDailyTrades;        // Maximum number of trades per day (if propMode is true)
   int               m_maxConsecutiveLosses;  // Maximum number of consecutive losses before potential pause
   bool              m_propMode;              // Prop firm mode (stricter risk management)

   //--- Current State Tracking ---
   double            m_dayStartEquity;        // Starting equity of the current trading day
   int               m_dayTradesCounter;      // Counter for trades taken today
   int               m_consecutiveLossesCounter; // Current count of consecutive losses
   // Note: Pause logic (m_pauseUntil) is managed by the main EA based on ShouldPauseTrading() result

   //--- Performance Statistics ---
   struct TradeStats
   {
      int            totalTrades;
      int            winningTrades;
      int            losingTrades;
      double         totalProfit;
      double         totalLoss;
      double         maxProfitTrade;        // Largest winning trade amount
      double         maxLossTrade;          // Largest losing trade amount (positive value)
      double         peakEquity;            // Highest equity reached for drawdown calculation
      double         maxEquityDrawdown;     // Max drawdown based on equity peak (%)

      // Placeholder for advanced stats requiring historical returns
      // double       sharpeRatio;
      // double       sortinoRatio;
      // double       averageRMultiple;
      // CArrayDouble   returnsHistory; // Needed for Sharpe/Sortino

      void Reset()
      {
         totalTrades = 0;
         winningTrades = 0;
         losingTrades = 0;
         totalProfit = 0.0;
         totalLoss = 0.0;
         maxProfitTrade = 0.0;
         maxLossTrade = 0.0;
         peakEquity = AccountInfoDouble(ACCOUNT_EQUITY); // Start with current equity
         maxEquityDrawdown = 0.0;
         // returnsHistory.Clear();
      }
   };

   TradeStats        m_stats;                 // Trade statistics instance
   CLogger* m_Logger;                // Logging object

   //--- Helper Objects ---
   CAccountInfo      m_AccountInfo;           // Account information object
   CSymbolInfo       m_SymbolInfo;            // Symbol information object

   //--- Private Helper Functions ---
   int               GetCurrentDayOfYear();   // Use DayOfYear for more robust day change detection
   void              UpdateMaxDrawdown();     // Updates peak equity and max drawdown

public:
                     CRiskManager();
                    ~CRiskManager();

   //--- Initialization ---
   bool              Initialize(string symbol, double riskPercent, bool propMode,
                                double maxDailyLoss, double maxDrawdown,
                                int maxDailyTrades, int maxConsecutiveLosses,
                                double startEquity); // Pass starting equity

   //--- Core Risk Management Functions ---
   double            CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, double qualityFactor = 1.0); // Added symbol and qualityFactor
   double            CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, bool useDynamicLotSize, double maxVolatilityFactor, double minLotMultiplier, double qualityFactor = 1.0);
   bool              IsMaxLossReached();      // Checks daily loss and max drawdown limits
   bool              ShouldPauseTrading();    // Checks if any pause condition is met (consecutive losses, daily trades)
   void              ResetDailyStats(double startEquity); // Resets daily counters and start equity
   CLogger*          GetLogger() const { return m_Logger; } // Thêm getter cho logger

   //--- Trade Result Processing ---
   void              UpdateStatsOnDealClose(bool isWin, double profit); // Renamed for clarity
   int               GetConsecutiveLosses() const { return m_consecutiveLossesCounter; }
   void              ResetConsecutiveLosses() { m_consecutiveLossesCounter = 0; } // Added explicit reset

   //--- Portfolio Risk Functions (Placeholders) ---
   double            CalculatePortfolioHeatValue(string symbol, ENUM_POSITION_TYPE direction); // Placeholder
   double            GetCorrelationAdjustment(string symbol, ENUM_POSITION_TYPE direction); // Placeholder

   //--- Performance Analysis Getters ---
   double            GetWinRate() const;
   double            GetProfitFactor() const;
   double            GetExpectedPayoff() const;
   double            GetCurrentEquityDrawdown() const; // Renamed for clarity
   double            GetMaxEquityDrawdown() const { return m_stats.maxEquityDrawdown; }
   int               GetTotalTrades() const { return m_stats.totalTrades; }
   // Add getters for other stats as needed
   
   //--- Advanced Functions (Added) ---
   bool              GetPerformanceMetrics(PerformanceMetrics &metrics);
   bool              GetScenarioStats(ScenarioStats &stats[]);
   void              SetParameters(double slAtrMultiplier);
   bool              IsMaxDrawdownExceeded(double maxDDPercent);

   //--- Statistics Reporting ---
   void              PrintStats();
   string            GetStatsAsString();
   bool              SaveStatsToFile(string filename); // Returns bool for success/failure
   bool              LoadStatsFromFile(string filename); // Added load function
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
   // Default values (can be overridden by Initialize)
   m_symbol = "";
   m_riskPercent = 1.0;
   m_maxDailyLossPercent = 5.0;
   m_maxDrawdownPercent = 10.0;
   m_maxDailyTrades = 10;
   m_maxConsecutiveLosses = 3;
   m_propMode = false;

   m_dayStartEquity = 0; // Will be set in Initialize or ResetDailyStats
   m_dayTradesCounter = 0;
   m_consecutiveLossesCounter = 0;

   m_stats.Reset();
   m_Logger = new CLogger("RiskManager"); // Assuming CLogger exists
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
   if (m_Logger != NULL) {
      delete m_Logger;
      m_Logger = NULL;
   }
}

//+------------------------------------------------------------------+
//| Initialization with parameters                                   |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(string symbol, double riskPercent, bool propMode,
                              double maxDailyLoss, double maxDrawdown,
                              int maxDailyTrades, int maxConsecutiveLosses,
                              double startEquity)
{
   m_symbol = symbol; // Store the main symbol
   m_riskPercent = riskPercent;
   m_propMode = propMode;
   m_maxDailyLossPercent = maxDailyLoss;
   m_maxDrawdownPercent = maxDrawdown;
   m_maxDailyTrades = maxDailyTrades;
   m_maxConsecutiveLosses = maxConsecutiveLosses;

   // Set initial daily stats
   ResetDailyStats(startEquity);

   // Load previous stats if file exists
   // LoadStatsFromFile("ApexPullback_Stats.bin"); // Example filename

   m_Logger.LogInfo("Risk Manager initialized: Risk=" + DoubleToString(m_riskPercent, 2) + "%, " +
                  "Daily Loss=" + DoubleToString(m_maxDailyLossPercent, 2) + "%, " +
                  "Max DD=" + DoubleToString(m_maxDrawdownPercent, 2) + "%, " +
                  "Max Trades=" + IntegerToString(m_maxDailyTrades) + ", " +
                  "Max Losses=" + IntegerToString(m_maxConsecutiveLosses));
   return true;
}

//+------------------------------------------------------------------+
//| Get current day of the year for tracking daily limits            |
//+------------------------------------------------------------------+
int CRiskManager::GetCurrentDayOfYear()
{
   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   return time.day_of_year;
}

//+------------------------------------------------------------------+
//| Reset daily trading statistics                                   |
//| Should be called by the main EA at the start of a new day.       |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyStats(double startEquity)
{
   m_dayTradesCounter = 0;
   m_dayStartEquity = startEquity; // Use equity passed from main EA
   m_stats.peakEquity = MathMax(m_stats.peakEquity, startEquity); // Update peak equity at day start
   m_Logger.LogInfo("Daily statistics reset. Start Equity: " + DoubleToString(startEquity, 2));
}


//+------------------------------------------------------------------+
//| Calculate position size based on risk parameters                 |
//| Takes symbol explicitly for multi-symbol compatibility.          |
//| Quality factor allows adjusting risk based on signal quality.    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, double qualityFactor = 1.0)
{
   if (stopLossPoints <= 0) {
      m_Logger.LogError("Invalid stop loss points (" + DoubleToString(stopLossPoints, 1) + ") in CalculateLotSize for " + symbol);
      return 0.0; // Return 0 for invalid SL
   }

   // Select the correct symbol for info retrieval
   if (!m_SymbolInfo.Name(symbol)) {
       m_Logger.LogError("Failed to select symbol '" + symbol + "' in CalculateLotSize.");
       return 0.0;
   }
   if (!m_SymbolInfo.RefreshRates()) { // Ensure symbol data is up-to-date
        m_Logger.LogWarning("Failed to refresh rates for symbol '" + symbol + "' in CalculateLotSize.");
        // Continue calculation but data might be slightly stale
   }


   // Determine risk percentage
   double actualRiskPercent = m_propMode ? MathMin(m_riskPercent, 0.5) : m_riskPercent;

   // Adjust risk based on signal quality (0.0 to 1.0+)
   if(qualityFactor > 0) {
       actualRiskPercent *= qualityFactor;
   }

   // Calculate risk amount
   double accountBalance = m_AccountInfo.Balance();
   double riskAmount = accountBalance * actualRiskPercent / 100.0;

   // Get symbol properties
   double tickValue = m_SymbolInfo.TickValue();
   double tickSize = m_SymbolInfo.TickSize();
   double lotStep = m_SymbolInfo.LotsStep();
   double minLot = m_SymbolInfo.LotsMin();
   double maxLot = m_SymbolInfo.LotsMax();
   int digits = (int)m_SymbolInfo.Digits(); // For normalization

   if (tickSize == 0 || lotStep == 0) {
      m_Logger.LogError("Invalid symbol properties (TickSize/LotStep is zero) for " + symbol);
      return 0.0;
   }

   // Calculate value per point
   double valuePerPoint = tickValue / tickSize;
   if (valuePerPoint == 0) {
       m_Logger.LogError("Invalid value per point (zero) for " + symbol);
       return 0.0;
   }

   // Calculate theoretical lot size
   double lotSize = riskAmount / (stopLossPoints * valuePerPoint);

   // Apply portfolio correlation adjustment (Placeholder)
   double heatAdjustment = GetCorrelationAdjustment(symbol, entryPrice > m_SymbolInfo.Bid() ? POSITION_TYPE_BUY : POSITION_TYPE_SELL);
   lotSize *= heatAdjustment; // Reduce lot size based on correlation

   // Normalize lot size to the symbol's lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;
   // Ensure correct rounding for lot volume based on step
   int volumeDigits = 0;
   double tmpStep = lotStep;
   while(tmpStep < 1.0 && volumeDigits < 10) { tmpStep *= 10.0; volumeDigits++; }
   lotSize = NormalizeDouble(lotSize, volumeDigits);


   // Ensure lot size is within the allowed min/max limits
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   m_Logger.LogDebug("Lot Size Calc (" + symbol + "): Risk=" + DoubleToString(actualRiskPercent, 2) +
                    "%, SL Pts=" + DoubleToString(stopLossPoints, 1) +
                    ", Quality=" + DoubleToString(qualityFactor, 2) +
                    ", HeatAdj=" + DoubleToString(heatAdjustment, 2) +
                    ", Lot=" + DoubleToString(lotSize, volumeDigits));

   return lotSize;
}

//+------------------------------------------------------------------+
//| Tính toán kích thước lot động dựa trên biến động thị trường      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, bool useDynamicLotSize, double maxVolatilityFactor, double minLotMultiplier, double qualityFactor = 1.0)
{
    // Nếu không sử dụng tính năng điều chỉnh lot size động, sử dụng cách tính thông thường
    if (!useDynamicLotSize) {
        return CalculateLotSize(symbol, stopLossPoints, entryPrice, qualityFactor);
    }

    // Tính lot size cơ bản
    double baseLotSize = CalculateLotSize(symbol, stopLossPoints, entryPrice, qualityFactor);
    
    // Lấy ATR hiện tại
    double atr = 0;
    int atrHandle = iATR(symbol, PERIOD_CURRENT, 14);
    
    if (atrHandle != INVALID_HANDLE) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        if (CopyBuffer(atrHandle, 0, 0, 3, atrBuffer) > 0) {
            atr = atrBuffer[0];
        }
        IndicatorRelease(atrHandle);
    }
    
    if (atr <= 0) {
        m_Logger.LogWarning("Không thể tính ATR cho điều chỉnh lot size động. Sử dụng lot size cơ bản.");
        return baseLotSize;
    }
    
    // Tính ATR trung bình
    double atrAverage = 0;
    atrHandle = iATR(symbol, PERIOD_CURRENT, 14);
    
    if (atrHandle != INVALID_HANDLE) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        if (CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) > 0) {
            double sum = 0;
            for (int i = 0; i < 20; i++) {
                sum += atrBuffer[i];
            }
            atrAverage = sum / 20;
        }
        IndicatorRelease(atrHandle);
    }
    
    if (atrAverage <= 0) {
        m_Logger.LogWarning("Không thể tính ATR trung bình cho điều chỉnh lot size động. Sử dụng lot size cơ bản.");
        return baseLotSize;
    }
    
    // Tính hệ số biến động và điều chỉnh lot size
    double volatilityFactor = atr / atrAverage;
    
    // Nếu biến động cao (lớn hơn ngưỡng), giảm lot size
    double adjustedLot = baseLotSize;
    
    if (volatilityFactor > 1.0) {
        // Giới hạn hệ số biến động
        volatilityFactor = MathMin(volatilityFactor, maxVolatilityFactor);
        
        // Tính hệ số điều chỉnh (biến động càng cao, lot size càng thấp)
        double adjustmentFactor = 1.0 / volatilityFactor;
        
        // Giới hạn dưới cho hệ số điều chỉnh
        adjustmentFactor = MathMax(adjustmentFactor, minLotMultiplier);
        
        // Áp dụng điều chỉnh
        adjustedLot = baseLotSize * adjustmentFactor;
    }
    
    // Chuẩn hóa lot size theo quy tắc của symbol
    if (!m_SymbolInfo.Name(symbol)) {
        return baseLotSize;
    }
    
    double minLot = m_SymbolInfo.LotsMin();
    double maxLot = m_SymbolInfo.LotsMax();
    double lotStep = m_SymbolInfo.LotsStep();
    
    adjustedLot = MathMax(minLot, MathMin(maxLot, adjustedLot));
    adjustedLot = NormalizeDouble(MathFloor(adjustedLot / lotStep) * lotStep, 2);
    
    m_Logger.LogInfo(StringFormat("Điều chỉnh lot size động: Từ %.2f thành %.2f (Hệ số biến động: %.2f)", 
                     baseLotSize, adjustedLot, volatilityFactor));
    
    return adjustedLot;
}

//+------------------------------------------------------------------+
//| Check if maximum loss thresholds have been reached               |
//+------------------------------------------------------------------+
bool CRiskManager::IsMaxLossReached()
{
   // Update drawdown before checking
   UpdateMaxDrawdown();

   double currentEquity = m_AccountInfo.Equity();

   // 1. Check Daily Loss Limit
   if (m_dayStartEquity > 0) { // Ensure start equity is valid
       double dailyLoss = m_dayStartEquity - currentEquity;
       if (dailyLoss > 0) { // Only check if there's a loss
           double dailyLossPercent = (dailyLoss / m_dayStartEquity) * 100.0;
           if (dailyLossPercent >= m_maxDailyLossPercent) {
              m_Logger.LogWarning("Daily loss limit reached: " + DoubleToString(dailyLossPercent, 2) + "% >= " +
                               DoubleToString(m_maxDailyLossPercent, 2) + "%");
              return true;
           }
       }
   }

   // 2. Check Maximum Drawdown Limit
   if (m_stats.maxEquityDrawdown >= m_maxDrawdownPercent) {
      m_Logger.LogWarning("Maximum drawdown limit reached: " + DoubleToString(m_stats.maxEquityDrawdown, 2) + "% >= " +
                       DoubleToString(m_maxDrawdownPercent, 2) + "%");
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if trading should be paused based on rules                 |
//| Note: This function only CHECKS. The main EA must ACT on the result.|
//+------------------------------------------------------------------+
bool CRiskManager::ShouldPauseTrading()
{
   // 1. Check Max Daily Trades (only in Prop Mode)
   if (m_propMode && m_dayTradesCounter >= m_maxDailyTrades) {
      m_Logger.LogInfo("Pause condition: Max daily trades reached (" + IntegerToString(m_dayTradesCounter) + ").");
      return true;
   }

   // 2. Check Max Consecutive Losses
   if (m_consecutiveLossesCounter >= m_maxConsecutiveLosses) {
      m_Logger.LogInfo("Pause condition: Max consecutive losses reached (" + IntegerToString(m_consecutiveLossesCounter) + ").");
      return true;
   }

   // 3. Check Max Loss Limits (Daily/Total Drawdown)
   if (IsMaxLossReached()) {
       // Reason is logged within IsMaxLossReached()
       return true;
   }

   // 4. Placeholder: Add Time-Based Pauses (e.g., during high volatility news)
   // if (IsHighImpactNewsPeriod()) { // Needs external info
   //    m_Logger.LogInfo("Pause condition: High impact news period.");
   //    return true;
   // }

   return false; // No pause condition met
}


//+------------------------------------------------------------------+
//| Update statistics based on a closed trade result                 |
//+------------------------------------------------------------------+
void CRiskManager::UpdateStatsOnDealClose(bool isWin, double profit)
{
   m_stats.totalTrades++;
   m_dayTradesCounter++; // Increment daily trade counter

   if (isWin) {
      m_stats.winningTrades++;
      m_stats.totalProfit += profit;
      m_consecutiveLossesCounter = 0; // Reset losses on a win
      if (profit > m_stats.maxProfitTrade) {
         m_stats.maxProfitTrade = profit;
      }
   } else {
      m_stats.losingTrades++;
      m_stats.totalLoss += MathAbs(profit);
      m_consecutiveLossesCounter++; // Increment losses
      if (MathAbs(profit) > m_stats.maxLossTrade) {
         m_stats.maxLossTrade = MathAbs(profit);
      }
   }

   // Update drawdown after every trade close
   UpdateMaxDrawdown();

   // Log updated consecutive losses
   if (!isWin) {
       m_Logger.LogDebug("Consecutive losses updated to: " + IntegerToString(m_consecutiveLossesCounter));
   }
}

//+------------------------------------------------------------------+
//| Update peak equity and max drawdown percentage                   |
//+------------------------------------------------------------------+
void CRiskManager::UpdateMaxDrawdown()
{
    double currentEquity = m_AccountInfo.Equity();

    // Update peak equity
    if (currentEquity > m_stats.peakEquity) {
        m_stats.peakEquity = currentEquity;
    }

    // Calculate current drawdown percentage from the peak
    if (m_stats.peakEquity > 0) { // Avoid division by zero
        double currentDrawdown = (m_stats.peakEquity - currentEquity) / m_stats.peakEquity * 100.0;
        // Update max drawdown if current drawdown is larger
        if (currentDrawdown > m_stats.maxEquityDrawdown) {
            m_stats.maxEquityDrawdown = currentDrawdown;
        }
    }
}


//+------------------------------------------------------------------+
//| Calculate portfolio heat (Placeholder)                           |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePortfolioHeatValue(string symbol, ENUM_POSITION_TYPE direction)
{
   // --- Placeholder ---
   // TODO: Implement portfolio heat calculation.
   // Requires tracking all open positions managed by the EA across different symbols.
   // Calculate correlation between the 'symbol' and other open positions.
   // Sum up risk exposure considering correlation and direction.
   // Example steps:
   // 1. Iterate through all open positions (PositionsTotal()).
   // 2. Filter positions belonging to this EA (Magic Number).
   // 3. For each position on a DIFFERENT symbol:
   //    a. Get the correlation coefficient between 'symbol' and the position's symbol.
   //    b. Determine if the new trade ('direction') would increase or decrease overall exposure based on correlation and position direction.
   //    c. Add/subtract weighted risk (e.g., based on lot size or initial risk) to a total heat value.
   // --- End Placeholder ---
   return 1.0; // Default: No heat detected
}

//+------------------------------------------------------------------+
//| Get correlation adjustment factor (Placeholder)                  |
//+------------------------------------------------------------------+
double CRiskManager::GetCorrelationAdjustment(string symbol, ENUM_POSITION_TYPE direction)
{
   // --- Placeholder ---
   // TODO: Implement correlation adjustment based on CalculatePortfolioHeatValue.
   // This function should return a multiplier (e.g., 0.5 to 1.0)
   // to adjust the calculated lot size.
   // Example:
   // double heat = CalculatePortfolioHeatValue(symbol, direction);
   // if (heat > 2.5) return 0.5; // High heat -> reduce lot size significantly
   // if (heat > 1.5) return 0.75;
   // --- End Placeholder ---
   return 1.0; // Default: No adjustment
}

//+------------------------------------------------------------------+
//| Get current win rate                                             |
//+------------------------------------------------------------------+
double CRiskManager::GetWinRate() const
{
   if (m_stats.totalTrades == 0) return 0.0;
   return (double)m_stats.winningTrades / m_stats.totalTrades * 100.0;
}

//+------------------------------------------------------------------+
//| Get profit factor                                                |
//+------------------------------------------------------------------+
double CRiskManager::GetProfitFactor() const
{
   if (m_stats.totalLoss <= 0.0) {
       return (m_stats.totalProfit > 0 ? 999.0 : 0.0); // Handle zero loss case
   }
   return m_stats.totalProfit / m_stats.totalLoss;
}

//+------------------------------------------------------------------+
//| Get expected payoff per trade                                    |
//+------------------------------------------------------------------+
double CRiskManager::GetExpectedPayoff() const
{
   if (m_stats.totalTrades == 0) return 0.0;
   return (m_stats.totalProfit - m_stats.totalLoss) / m_stats.totalTrades;
}

//+------------------------------------------------------------------+
//| Get current equity drawdown percentage                           |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentEquityDrawdown() const
{
   // Use the stored peak equity for calculation
   double currentEquity = m_AccountInfo.Equity();
   if (m_stats.peakEquity <= 0) return 0.0; // Avoid division by zero or invalid peak

   double drawdown = (m_stats.peakEquity - currentEquity) / m_stats.peakEquity * 100.0;
   return MathMax(0, drawdown); // Drawdown cannot be negative
}

//+------------------------------------------------------------------+
//| Get performance metrics                                          |
//+------------------------------------------------------------------+
bool CRiskManager::GetPerformanceMetrics(PerformanceMetrics &metrics)
{
   metrics.winRate = GetWinRate();
   metrics.profitFactor = GetProfitFactor();
   metrics.expectedPayoff = GetExpectedPayoff();
   metrics.maxEquityDD = GetMaxEquityDrawdown();
   metrics.currentEquityDrawdown = GetCurrentEquityDrawdown();
   return true;
}

//+------------------------------------------------------------------+
//| Get scenario statistics                                          |
//+------------------------------------------------------------------+
bool CRiskManager::GetScenarioStats(ScenarioStats &stats[])
{
   // TO DO: Implement scenario statistics retrieval
   return false;
}

//+------------------------------------------------------------------+
//| Set parameters                                                   |
//+------------------------------------------------------------------+
void CRiskManager::SetParameters(double slAtrMultiplier)
{
   // TO DO: Implement parameter setting
}

//+------------------------------------------------------------------+
//| Print statistics to the Experts log                              |
//+------------------------------------------------------------------+
void CRiskManager::PrintStats()
{
   string stats = GetStatsAsString(); // Get formatted string
   Print(stats); // Print to Experts log
}

//+------------------------------------------------------------------+
//| Get statistics as formatted string                               |
//+------------------------------------------------------------------+
string CRiskManager::GetStatsAsString()
{
   string stats = "=== Risk & Performance Stats ===\n";
   stats += StringFormat(" Total Trades: %d (Wins: %d, Losses: %d)\n",
                         m_stats.totalTrades, m_stats.winningTrades, m_stats.losingTrades);
   stats += StringFormat(" Win Rate: %.2f %%\n", GetWinRate());
   stats += StringFormat(" Profit Factor: %.2f\n", GetProfitFactor());
   stats += StringFormat(" Expected Payoff: %.2f\n", GetExpectedPayoff());
   stats += StringFormat(" Max Equity DD: %.2f %%\n", m_stats.maxEquityDrawdown);
   stats += StringFormat(" Current Equity DD: %.2f %%\n", GetCurrentEquityDrawdown());
   stats += StringFormat(" Consecutive Losses: %d / %d\n", m_consecutiveLossesCounter, m_maxConsecutiveLosses);
   stats += "================================";
   return stats;
}

//+------------------------------------------------------------------+
//| Save statistics to file                                          |
//+------------------------------------------------------------------+
bool CRiskManager::SaveStatsToFile(string filename)
{
   // Use binary file for struct saving
   int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN);

   if (fileHandle != INVALID_HANDLE) {
      // Write the TradeStats struct directly
      if(FileWriteStruct(fileHandle, m_stats, sizeof(TradeStats)) == sizeof(TradeStats)) {
          FileClose(fileHandle);
          m_Logger.LogInfo("Performance statistics saved to binary file: " + filename);
          return true;
      } else {
          m_Logger.LogError("Error writing statistics struct to file: " + filename + ", Error: " + IntegerToString(GetLastError()));
          FileClose(fileHandle);
          return false;
      }
   }
   else {
      m_Logger.LogError("Error opening statistics file for writing: " + filename + ", Error: " + IntegerToString(GetLastError()));
      return false;
   }
}

//+------------------------------------------------------------------+
//| Load statistics from file                                        |
//+------------------------------------------------------------------+
bool CRiskManager::LoadStatsFromFile(string filename)
{
    if(!FileIsExist(filename)) {
        m_Logger.LogInfo("Statistics file not found: " + filename + ". Starting fresh stats.");
        return false;
    }

    int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN);
    if(fileHandle != INVALID_HANDLE) {
        if(FileReadStruct(fileHandle, m_stats, sizeof(TradeStats)) == sizeof(TradeStats)) {
            FileClose(fileHandle);
            m_Logger.LogInfo("Performance statistics loaded from file: " + filename);
            // Ensure peak equity is at least the current equity after loading
            m_stats.peakEquity = MathMax(m_stats.peakEquity, AccountInfoDouble(ACCOUNT_EQUITY));
            return true;
        } else {
            m_Logger.LogError("Error reading statistics struct from file: " + filename + ", Error: " + IntegerToString(GetLastError()));
            FileClose(fileHandle);
            // Reset stats if file is corrupted or incorrect format
            m_stats.Reset();
            return false;
        }
    } else {
        m_Logger.LogError("Error opening statistics file for reading: " + filename + ", Error: " + IntegerToString(GetLastError()));
        return false;
    }
}

//+------------------------------------------------------------------+
//| Check if maximum drawdown exceeded                               |
//+------------------------------------------------------------------+
bool CRiskManager::IsMaxDrawdownExceeded(double maxDDPercent)
{
    return m_stats.maxEquityDrawdown >= maxDDPercent;
}
