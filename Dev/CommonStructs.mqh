//+------------------------------------------------------------------+
//|                                               CommonStructs.mqh   |
//|          Common Enumerations and Structures for ApexPullback EA  |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      "your-website.com"
#property version   "1.0"
#property strict
#include <Object.mqh>    // Cần để sử dụng CObject cho CArrayObj

// Include standard libraries
#include <Arrays/ArrayObj.mqh>

//+------------------------------------------------------------------+
//| Global Constants                                                 |
//+------------------------------------------------------------------+

// Version information
#define EA_VERSION         "9.0"
#define EA_BUILD           __DATE__

// Default risk parameters
#define DEFAULT_RISK_PERCENT    1.0
#define DEFAULT_MAX_DRAWDOWN    9.0
#define DEFAULT_DAILY_LOSS      4.5

// Fibonacci levels commonly used
#define FIBO_236            0.236
#define FIBO_382            0.382
#define FIBO_50             0.500
#define FIBO_618            0.618
#define FIBO_786            0.786
#define FIBO_886            0.886

// Extension levels
#define FIBO_EXTENSION_1272  1.272
#define FIBO_EXTENSION_1618  1.618
#define FIBO_EXTENSION_2618  2.618

//+------------------------------------------------------------------+
//| Common Enumerations                                              |
//+------------------------------------------------------------------+

//--- Market Preset - Loại thị trường và thiết lập tương ứng ---
enum ENUM_MARKET_PRESET {
   PRESET_AUTO     = 0,  // Tự động dựa vào Symbol
   PRESET_FX_MAJOR = 1,  // Forex chính
   PRESET_FX_MINOR = 2,  // Forex phụ
   PRESET_GOLD     = 3,  // Vàng & Bạc
   PRESET_CRYPTO   = 4,  // Tiền điện tử
   PRESET_INDICES  = 5,  // Chỉ số
   PRESET_CUSTOM   = 99  // Tùy chỉnh hoàn toàn
};

//--- Entry Scenarios - Identifies the specific pattern/condition triggering a trade entry ---
enum ENUM_ENTRY_SCENARIO {
   SCENARIO_NONE = 0,                  // No valid scenario identified
   SCENARIO_STRONG_PULLBACK,           // Strong pullback to EMA after clear trend
   SCENARIO_EMA_BOUNCE,                // Price touches EMA and reverses with clear candle pattern
   SCENARIO_DUAL_EMA_SUPPORT,          // Price supported by both EMA 34 and 89 close together
   SCENARIO_FIBONACCI_PULLBACK,        // Pullback to important Fibonacci level
   SCENARIO_HARMONIC_PATTERN,          // Harmonic pattern (Gartley, Bat, Butterfly)
   SCENARIO_MOMENTUM_SHIFT,            // Momentum shift (combination of RSI, MACD)
   SCENARIO_LIQUIDITY_GRAB,            // Stop hunt/liquidity grab followed by reversal
   SCENARIO_BREAKOUT_FAILURE,          // Failed breakout returning to trend
   SCENARIO_REVERSAL_CONFIRMATION,     // Reversal confirmation after accumulation
   SCENARIO_BULLISH_PULLBACK,          // Bullish pullback pattern (added)
   SCENARIO_BEARISH_PULLBACK           // Bearish pullback pattern (added)
};

//--- Entry Mode - Defines how trade entries are executed ---
enum ENUM_ENTRY_MODE {
   MODE_MARKET,    // Immediate market order execution
   MODE_LIMIT,     // Use limit orders at calculated levels
   MODE_SMART      // Dynamically choose optimal entry method based on conditions
};

//--- News Filter - Defines how to handle trading around news events ---
enum ENUM_NEWS_FILTER {
   NEWS_NONE,      // No news filtering
   NEWS_MANUAL,    // Filter news based on fixed time windows
   NEWS_FILE       // Filter news based on CSV file data
};

//--- Market Regime - Classifies current market conditions ---
enum ENUM_MARKET_REGIME {
   REGIME_STRONG_TREND = 1,    // Strong trending market - optimal for trend following
   REGIME_WEAK_TREND = 2,      // Weak trending market - caution needed
   REGIME_RANGING = 3,         // Sideways/ranging market - trend strategies may underperform
   REGIME_VOLATILE = 4         // Highly volatile market - wider stops required
};

//--- Trailing Mode - Định nghĩa các phương pháp trailing stop ---
enum ENUM_TRAILING_MODE {
   TRAILING_NONE = 0,             // Không sử dụng trailing stop
   TRAILING_MODE_ATR = 1,         // Trailing stop dựa trên ATR
   TRAILING_MODE_SWING = 2,       // Trailing stop dựa trên swing levels
   TRAILING_MODE_EMA = 3,         // Trailing stop dựa trên EMA
   TRAILING_MODE_PSAR = 4,        // Trailing stop dựa trên Parabolic SAR
   TRAILING_MODE_SUPERTREND = 5   // Trailing stop dựa trên SuperTrend indicator
};

//--- Log Level - Controls the verbosity of logging ---
enum ENUM_LOG_LEVEL {
   LOG_LEVEL_ERROR = 0,        // Log only errors
   LOG_LEVEL_WARNING = 1,      // Log errors and warnings
   LOG_LEVEL_INFO = 2,         // Log errors, warnings, and info (recommended default)
   LOG_LEVEL_DEBUG = 3,        // Log all messages including debug (detailed)
   LOG_LEVEL_VERBOSE = 4       // Log everything with extensive detail
};

//--- News Impact - Mức ảnh hưởng của tin tức ---
enum ENUM_NEWS_IMPACT {
   NEWS_NO_IMPACT = 0,    // Không ảnh hưởng
   NEWS_LOW_IMPACT = 1,   // Ảnh hưởng thấp
   NEWS_MEDIUM_IMPACT = 2, // Ảnh hưởng trung bình
   NEWS_HIGH_IMPACT = 3    // Ảnh hưởng cao
};

//--- Trade Signal - Tín hiệu giao dịch ---
enum ENUM_TRADE_SIGNAL {
   TRADE_SIGNAL_NONE = 0,  // Không có tín hiệu
   TRADE_SIGNAL_BUY = 1,   // Tín hiệu mua
   TRADE_SIGNAL_SELL = 2   // Tín hiệu bán
};

//+------------------------------------------------------------------+
//| Common Structures                                                |
//+------------------------------------------------------------------+

//--- Signal Information - Contains complete details about a trading signal ---
struct SignalInfo {
   bool                 isValid;      // Is this a valid signal?
   bool                 isLong;       // Direction of signal (true=Buy, false=Sell)
   string               symbol;       // Symbol of the instrument
   ENUM_ENTRY_SCENARIO  scenario;     // Identified scenario type
   double               entryPrice;   // Suggested entry price
   double               stopLoss;     // Suggested stop loss level
   double               takeProfit;   // Suggested take profit level (optional)
   double               quality;      // Signal quality score (0.0 - 1.0+)
   string               description;  // Brief description of the signal
   datetime             signalTime;   // Time when signal was generated
   
   // Constructor with default initialization
   SignalInfo() {
      Reset();
   }
   
   // Reset all fields to default values
   void Reset() {
      isValid = false;
      isLong = false;
      symbol = "";
      scenario = SCENARIO_NONE;
      entryPrice = 0.0;
      stopLoss = 0.0;
      takeProfit = 0.0;
      quality = 0.0;
      description = "";
      signalTime = 0;
   }
   
   // Format signal as a readable string
   string ToString() const {
      if (!isValid) return "Invalid Signal";
      
      string dir = isLong ? "BUY" : "SELL";
      string scen = GetScenarioName(scenario);
      string qual = DoubleToString(quality * 100, 1) + "%";
      
      return StringFormat("%s signal: %s (Quality: %s) Entry: %s, SL: %s", 
                         dir, scen, qual, 
                         DoubleToString(entryPrice, _Digits), 
                         DoubleToString(stopLoss, _Digits));
   }
   
   // Helper method to get scenario name as string
   string GetScenarioName(ENUM_ENTRY_SCENARIO scen) const {
      switch(scen) {
         case SCENARIO_NONE: return "None";
         case SCENARIO_STRONG_PULLBACK: return "Strong Pullback";
         case SCENARIO_EMA_BOUNCE: return "EMA Bounce";
         case SCENARIO_DUAL_EMA_SUPPORT: return "Dual EMA Support";
         case SCENARIO_FIBONACCI_PULLBACK: return "Fibonacci Pullback";
         case SCENARIO_HARMONIC_PATTERN: return "Harmonic Pattern";
         case SCENARIO_MOMENTUM_SHIFT: return "Momentum Shift";
         case SCENARIO_LIQUIDITY_GRAB: return "Liquidity Grab";
         case SCENARIO_BREAKOUT_FAILURE: return "Breakout Failure";
         case SCENARIO_REVERSAL_CONFIRMATION: return "Reversal Confirmation";
         case SCENARIO_BULLISH_PULLBACK: return "Bullish Pullback"; // Thêm vào
         case SCENARIO_BEARISH_PULLBACK: return "Bearish Pullback"; // Thêm vào
         default: return "Unknown";
      }
   }
};

//--- Indicator Cache - Stores indicator values to avoid recalculating ---
struct IndicatorCache {
   // Main timeframe indicator values
   double ema_fast;            // Fast EMA value
   double ema_trend;           // Trend EMA value
   double atr;                 // ATR value
   double adx;                 // ADX value
   double adx_plus_di;         // +DI value
   double adx_minus_di;        // -DI value
   double rsi;                 // RSI value
   double macd;                // MACD main line
   double macd_signal;         // MACD signal line
   double stoch_main;          // Stochastic main
   double stoch_signal;        // Stochastic signal
   
   // Higher timeframe values if multi-timeframe is enabled
   double ema_fast_higher;
   double ema_trend_higher;
   
   // Lower timeframe values if nested timeframe is enabled
   double ema_fast_nested;
   double ema_trend_nested;
   
   // Constructor with default initialization
   IndicatorCache() {
      Reset();
   }
   
   // Reset all indicator values
   void Reset() {
      ema_fast = 0.0;
      ema_trend = 0.0;
      atr = 0.0;
      adx = 0.0;
      adx_plus_di = 0.0;
      adx_minus_di = 0.0;
      rsi = 0.0;
      macd = 0.0;
      macd_signal = 0.0;
      stoch_main = 0.0;
      stoch_signal = 0.0;
      
      ema_fast_higher = 0.0;
      ema_trend_higher = 0.0;
      
      ema_fast_nested = 0.0;
      ema_trend_nested = 0.0;
   }
};

//--- Candle Pattern - Represents a detected candlestick pattern ---
struct CandlePattern {
   bool is_valid;              // Is this a valid pattern?
   int pattern_type;           // Type of pattern (1=Pin Bar, 2=Engulfing, 3=Inside Bar, etc.)
   int direction;              // Direction (1=bullish, -1=bearish, 0=neutral)
   double entry_price;         // Suggested entry price
   double stop_loss;           // Suggested stop loss level
   double limit_entry_price;   // Suggested limit entry price (if different)
   bool use_limit_entry;       // Whether to use limit entry
   double quality;             // Pattern quality score (0.0-1.0)
   bool has_volume_spike;      // Whether pattern is confirmed by volume spike
   
   // Constructor with default initialization
   CandlePattern() {
      Reset();
   }
   
   // Reset all fields to default values
   void Reset() {
      is_valid = false;
      pattern_type = 0;
      direction = 0;
      entry_price = 0.0;
      stop_loss = 0.0;
      limit_entry_price = 0.0;
      use_limit_entry = false;
      quality = 0.0;
      has_volume_spike = false;
   }
   
   // Get pattern type as readable string
   string GetPatternName() const {
      switch(pattern_type) {
         case 1: return "Pin Bar";
         case 2: return "Engulfing";
         case 3: return "Inside Bar";
         case 4: return "Fakey";
         case 5: return "Doji";
         case 6: return "Hammer/Shooting Star";
         case 7: return "Evening/Morning Star";
         default: return "Unknown";
      }
   }
   
   // Get direction as readable string
   string GetDirection() const {
      if (direction > 0) return "Bullish";
      if (direction < 0) return "Bearish";
      return "Neutral";
   }
};

//--- Target Info - Tracks take profit levels and position information ---
class TargetInfo : public CObject
{
public:
   ulong ticket;                // Position ticket
   double tp1;                  // First take profit level
   double tp2;                  // Second take profit level
   double tp3;                  // Third take profit level
   int tp1_percent;             // Percentage to close at TP1
   int tp2_percent;             // Percentage to close at TP2
   int tp3_percent;             // Percentage to close at TP3
   bool tp1_hit;                // Flag if TP1 was hit
   bool tp2_hit;                // Flag if TP2 was hit
   bool tp3_hit;                // Flag if TP3 was hit
   ENUM_POSITION_TYPE direction; // Position direction
   double entry_price;          // Entry price
   double stop_loss;            // Initial stop loss
   double risk_points;          // Risk in points
   ENUM_ENTRY_SCENARIO scenario; // Entry scenario
   datetime open_time;          // Position open time
   bool move_breakeven;         // Flag if moved to breakeven
   
   // Constructor with default initialization
   TargetInfo() {
      Reset();
   }
   
   // Reset all fields to default values
   void Reset() {
      ticket = 0;
      tp1 = 0.0;
      tp2 = 0.0;
      tp3 = 0.0;
      tp1_percent = 0;
      tp2_percent = 0;
      tp3_percent = 0;
      tp1_hit = false;
      tp2_hit = false;
      tp3_hit = false;
      direction = POSITION_TYPE_BUY;
      entry_price = 0.0;
      stop_loss = 0.0;
      risk_points = 0.0;
      scenario = SCENARIO_NONE;
      open_time = 0;
      move_breakeven = false;
   }
   
   // Calculate R multiple (profit/loss relative to initial risk)
   double CalculateRMultiple(double current_price) const {
      if (risk_points <= 0.0) return 0.0;
      
      double points;
      if (direction == POSITION_TYPE_BUY) {
         points = current_price - entry_price;
      } else {
         points = entry_price - current_price;
      }
      
      return points / risk_points;
   }
};

//--- Trade Statistics - Tracks performance metrics ---
struct TradeStatistics {
   int totalTrades;              // Total trades executed
   int winningTrades;            // Number of winning trades
   int losingTrades;             // Number of losing trades
   double totalProfit;           // Total profit amount
   double totalLoss;             // Total loss amount
   double netProfit;             // Net profit/loss
   double maxProfit;             // Largest winning trade
   double maxLoss;               // Largest losing trade
   double totalR;                // Total R multiple gained/lost
   double maxDrawdown;           // Maximum drawdown experienced
   
   // Per scenario statistics
   int tradesPerScenario[15];    // Number of trades per scenario (tăng lên để đủ cho các kịch bản)
   int winsPerScenario[15];      // Number of wins per scenario
   double profitPerScenario[15]; // Profit per scenario
   
   // Per market type statistics
   int tradesPerMarket[5];       // Number of trades per market type (tăng lên)
   double profitPerMarket[5];    // Profit per market type
   
   // Constructor with default initialization
   TradeStatistics() {
      Reset();
   }
   
   // Reset all statistics
   void Reset() {
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      totalProfit = 0.0;
      totalLoss = 0.0;
      netProfit = 0.0;
      maxProfit = 0.0;
      maxLoss = 0.0;
      totalR = 0.0;
      maxDrawdown = 0.0;
      
      ArrayInitialize(tradesPerScenario, 0);
      ArrayInitialize(winsPerScenario, 0);
      ArrayInitialize(profitPerScenario, 0.0);
      
      ArrayInitialize(tradesPerMarket, 0);
      ArrayInitialize(profitPerMarket, 0.0);
   }
   
   // Calculate win rate as percentage
   double GetWinRate() const {
      if (totalTrades == 0) return 0.0;
      return (double)winningTrades / totalTrades * 100.0;
   }
   
   // Calculate profit factor
   double GetProfitFactor() const {
      if (totalLoss == 0.0) return (totalProfit > 0.0) ? 999.0 : 0.0;
      return totalProfit / totalLoss;
   }
   
   // Calculate average R per trade
   double GetAvgRPerTrade() const {
      if (totalTrades == 0) return 0.0;
      return totalR / totalTrades;
   }
   
   // Format statistics as readable string
   string ToString() const {
      string stats = "=== Trade Statistics ===\n";
      stats += "Total Trades: " + IntegerToString(totalTrades) + "\n";
      stats += "Win Rate: " + DoubleToString(GetWinRate(), 1) + "%\n";
      stats += "Profit Factor: " + DoubleToString(GetProfitFactor(), 2) + "\n";
      stats += "Net Profit: " + DoubleToString(netProfit, 2) + "\n";
      stats += "Average R: " + DoubleToString(GetAvgRPerTrade(), 2) + "\n";
      stats += "Max Drawdown: " + DoubleToString(maxDrawdown, 2) + "%\n";
      return stats;
   }
};

//--- Session Info - Tracks trading session information ---
struct SessionInfo {
   bool isAsianSession;         // Is current time in Asian session?
   bool isLondonSession;        // Is current time in London session?
   bool isNYSession;            // Is current time in New York session?
   bool isOverlapSession;       // Is current time in session overlap?
   int currentHour;             // Current hour (in GMT)
   
   // Historical performance metrics per session
   int tradesInAsian;           // Number of trades in Asian session
   int tradesInLondon;          // Number of trades in London session
   int tradesInNY;              // Number of trades in NY session
   int tradesInOverlap;         // Number of trades in overlap sessions
   double profitInAsian;        // Profit in Asian session
   double profitInLondon;       // Profit in London session
   double profitInNY;           // Profit in New York session
   double profitInOverlap;      // Profit in overlap sessions
   
   double asianWinRate;         // Win rate in Asian session
   double londonWinRate;        // Win rate in London session
   double nyWinRate;            // Win rate in NY session
   double overlapWinRate;       // Win rate in overlap sessions

   // Constructor with default initialization
   SessionInfo() {
      Reset();
   }

   // Reset all fields to default values
   void Reset() {
      isAsianSession = false;
      isLondonSession = false;
      isNYSession = false;
      isOverlapSession = false;
      currentHour = 0;
      
      tradesInAsian = 0;
      tradesInLondon = 0;
      tradesInNY = 0;
      tradesInOverlap = 0;
      profitInAsian = 0.0;
      profitInLondon = 0.0;
      profitInNY = 0.0;
      profitInOverlap = 0.0;
      
      asianWinRate = 0.0;
      londonWinRate = 0.0;
      nyWinRate = 0.0;
      overlapWinRate = 0.0;
   }
   
   // Update session flags based on current time
   void Update(int gmtOffset = 0) {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      // Adjust for GMT offset
      currentHour = (dt.hour + gmtOffset) % 24;
      if (currentHour < 0) currentHour += 24; // Đảm bảo giờ luôn dương
      
      // Asian session: approximately 00:00-09:00 GMT
      isAsianSession = (currentHour >= 0 && currentHour < 9);
      
      // London session: approximately 08:00-17:00 GMT
      isLondonSession = (currentHour >= 8 && currentHour < 17);
      
      // NY session: approximately 13:00-22:00 GMT
      isNYSession = (currentHour >= 13 && currentHour < 22);
      
      // Overlap between London and NY: approximately 13:00-17:00 GMT
      isOverlapSession = (currentHour >= 13 && currentHour < 17);
   }
   
   // Get current session name
   string GetCurrentSession() const {
      if (isOverlapSession) return "London/NY Overlap";
      if (isAsianSession) return "Asian";
      if (isLondonSession) return "London";
      if (isNYSession) return "New York";
      return "Off Hours";
   }
};

//--- News Event - Information about an economic news release ---
struct NewsEvent {
   string      title;          // Title of news event
   datetime    time;           // Time of the news release
   string      currency;       // The affected currency
   int         impact;         // Impact level (1=low, 2=medium, 3=high)
   bool        isPending;      // Whether the news event is pending
   string      name;           // Event name (alias for compatibility)
   
   // Constructor
   NewsEvent() {
      title = "";
      time = 0;
      currency = "";
      impact = 0;
      isPending = false;
      name = "";
   }
   
   // Check if news event affects current symbol
   bool AffectsSymbol(string symbol) const {
      // Check if the currency is part of the symbol
      return (StringFind(symbol, currency) >= 0);
   }
   
   // Check if current time is within window of the news event
   bool IsInWindow(datetime currentTime, int minutesBefore, int minutesAfter) const {
      datetime windowStart = time - minutesBefore * 60;
      datetime windowEnd = time + minutesAfter * 60;
      return (currentTime >= windowStart && currentTime <= windowEnd);
   }
   
   // Format as readable string
   string ToString() const {
      string impactStr = "";
      for(int i = 0; i < impact; i++) impactStr += "!";
      
      return StringFormat("%s [%s] %s (%s)", 
                         TimeToString(time, TIME_DATE|TIME_MINUTES),
                         currency,
                         title != "" ? title : name,
                         impactStr);
   }
};

//--- Performance Metrics - Contains trading performance statistics ---
struct PerformanceMetrics {
   int    totalTrades;           // Tổng số lệnh
   double winRate;               // Tỷ lệ thắng (%)
   double profitFactor;          // Hệ số lợi nhuận
   double expectedPayoff;        // Kỳ vọng lợi nhuận trung bình mỗi lệnh
   double averageWin;            // Lãi trung bình cho mỗi lệnh thắng
   double averageLoss;           // Lỗ trung bình cho mỗi lệnh thua
   int    maxConsecutiveWins;    // Số lệnh thắng liên tiếp tối đa
   int    maxConsecutiveLosses;  // Số lệnh thua liên tiếp tối đa
   double maxEquityDD;           // Mức sụt giảm vốn tối đa trong lịch sử
   double maxRelativeDD;         // Drawdown tương đối lớn nhất
   double currentEquityDrawdown; // Mức sụt giảm vốn hiện tại
   
   // Constructor
   PerformanceMetrics() {
      totalTrades = 0;
      winRate = 0.0;
      profitFactor = 0.0;
      expectedPayoff = 0.0;
      averageWin = 0.0;
      averageLoss = 0.0;
      maxConsecutiveWins = 0;
      maxConsecutiveLosses = 0;
      maxEquityDD = 0.0;
      maxRelativeDD = 0.0;
      currentEquityDrawdown = 0.0;
   }
};

//--- Scenario Statistics - Track performance of each entry scenario ---
struct ScenarioStats {
   ENUM_ENTRY_SCENARIO scenario;     // The entry scenario
   int    totalTrades;               // Total trades for this scenario
   int    winningTrades;             // Number of winning trades
   int    losingTrades;              // Number of losing trades
   double winRate;                   // Win rate (%)
   double averageProfit;             // Average profit per trade
   double totalProfit;               // Total profit from this scenario
   double largestWin;                // Largest winning trade
   double largestLoss;               // Largest losing trade
   double profitFactor;              // Profit factor for this scenario
   
   // For compatibility with existing code
   int    winTrades;                 // Alias for winningTrades
   double netProfit;                 // Alias for totalProfit
   double avgRMultiple;              // Average R multiple
   
   // Constructor
   ScenarioStats() {
      scenario = SCENARIO_NONE;
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      winRate = 0.0;
      averageProfit = 0.0;
      totalProfit = 0.0;
      largestWin = 0.0;
      largestLoss = 0.0;
      profitFactor = 0.0;
      
      // Initialize alias fields
      winTrades = 0;
      netProfit = 0.0;
      avgRMultiple = 0.0;
   }
   
   // Update statistics after a trade
   void Update(bool isWin, double profit) {
      totalTrades++;
      
      if(isWin) {
         winningTrades++;
         winTrades = winningTrades; // Keep alias in sync
         if(profit > largestWin) largestWin = profit;
      } else {
         losingTrades++;
         if(profit < largestLoss) largestLoss = profit;
      }
      
      totalProfit += profit;
      netProfit = totalProfit; // Keep alias in sync
      
      // Recalculate derived statistics
      winRate = totalTrades > 0 ? (double)winningTrades / totalTrades * 100.0 : 0.0;
      averageProfit = totalTrades > 0 ? totalProfit / totalTrades : 0.0;
      
      // Profit factor calculation (avoid division by zero)
      double totalWinAmount = 0.0, totalLossAmount = 0.0;
      
      // Simplified profit factor calculation for stats only
      if(winningTrades > 0) totalWinAmount = largestWin * winningTrades;
      if(losingTrades > 0) totalLossAmount = MathAbs(largestLoss) * losingTrades;
      
      profitFactor = (totalLossAmount > 0) ? totalWinAmount / totalLossAmount : (totalWinAmount > 0 ? 999.0 : 0.0);
   }
};

//+------------------------------------------------------------------+
//| Utility Functions                                                |
//+------------------------------------------------------------------+

// Convert entry scenario to string
string ScenarioToString(ENUM_ENTRY_SCENARIO scenario) {
   switch(scenario) {
      case SCENARIO_NONE: return "None";
      case SCENARIO_STRONG_PULLBACK: return "Strong Pullback";
      case SCENARIO_EMA_BOUNCE: return "EMA Bounce";
      case SCENARIO_DUAL_EMA_SUPPORT: return "Dual EMA Support";
      case SCENARIO_FIBONACCI_PULLBACK: return "Fibonacci Pullback";
      case SCENARIO_HARMONIC_PATTERN: return "Harmonic Pattern";
      case SCENARIO_MOMENTUM_SHIFT: return "Momentum Shift";
      case SCENARIO_LIQUIDITY_GRAB: return "Liquidity Grab";
      case SCENARIO_BREAKOUT_FAILURE: return "Breakout Failure";
      case SCENARIO_REVERSAL_CONFIRMATION: return "Reversal Confirmation";
      case SCENARIO_BULLISH_PULLBACK: return "Bullish Pullback"; // Thêm vào
      case SCENARIO_BEARISH_PULLBACK: return "Bearish Pullback"; // Thêm vào
      default: return "Unknown Scenario";
   }
}

// Convert market regime to string
string RegimeToString(ENUM_MARKET_REGIME regime) {
   switch(regime) {
      case REGIME_STRONG_TREND: return "Strong Trend";
      case REGIME_WEAK_TREND: return "Weak Trend";
      case REGIME_RANGING: return "Ranging";
      case REGIME_VOLATILE: return "Volatile";
      default: return "Unknown Regime";
   }
}

// Convert timeframe to string
string TimeframeToString(ENUM_TIMEFRAMES timeframe) {
   switch(timeframe) {
      case PERIOD_M1: return "M1";
      case PERIOD_M5: return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1: return "H1";
      case PERIOD_H4: return "H4";
      case PERIOD_D1: return "D1";
      case PERIOD_W1: return "W1";
      case PERIOD_MN1: return "MN";
      default: return "Unknown TF";
   }
}