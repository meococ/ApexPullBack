//+------------------------------------------------------------------------------------------+
//|                                               CommonStructs.mqh                          |
//|    Common Enumerations and Structures for ApexPullback EA v13.0- EA top 5% thế giới     |
//+------------------------------------------------------------------------------------------+
#property copyright "Mèo Cọc"
#property version   "13.0"
#property strict
#include <Object.mqh>    // Cần để sử dụng CObject cho CArrayObj

// Include standard libraries
#include <Arrays/ArrayObj.mqh>

//+------------------------------------------------------------------+
//| Global Constants                                                 |
//+------------------------------------------------------------------+

// Version information
#define EA_VERSION         "13.0"
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

// Market Phase Detection Parameters
#define MarketPhase_EMA_Period     34     // EMA period for phase detection
#define MarketPhase_ATR_Period     14     // ATR period for phase detection
#define MarketPhase_Volume_Period  20     // Volume period for phase detection
#define MarketPhase_EMASlope_Up    0.5    // EMA slope threshold for uptrend
#define MarketPhase_EMASlope_Down  -0.2   // EMA slope threshold for downtrend
#define MarketPhase_ATRRatio_High  1.3    // ATR ratio threshold for high volatility
#define MarketPhase_ATRRatio_Low   0.7    // ATR ratio threshold for low volatility
#define MarketPhase_VolumeSpike    1.5    // Volume spike threshold

// Swing Point Detection Parameters
#define SwingLookbackBars       50       // Number of bars to look back for swing points
#define SwingRequiredBars       3        // Minimum number of bars for swing confirmation
#define SwingConfirmationBars   2        // Number of bars for swing point confirmation
#define SwingATR_Factor         1.5      // ATR factor for swing point significance
#define SwingATR_Period         14       // ATR period for swing point detection
#define UseSwingFractals        true     // Use fractals for swing point detection
#define UseHigherTimeframe      true     // Use higher timeframe for swing detection

// Risk Management Constants
#define MAX_RISK_MULTIPLIER     2.0      // Maximum risk multiplier
#define MIN_RISK_MULTIPLIER     0.3      // Minimum risk multiplier
#define DRAWDOWN_RISK_THRESHOLD 5.0      // Drawdown threshold to reduce risk
#define DRAWDOWN_PAUSE_THRESHOLD 10.0    // Drawdown threshold to pause trading

//+------------------------------------------------------------------+
//| Common Enumerations                                              |
//+------------------------------------------------------------------+

//--- EA State - New for v13.0 - Trạng thái hoạt động của EA ---
enum ENUM_EA_STATE {
    STATE_RUNNING = 0,            // EA đang hoạt động bình thường
    STATE_PAUSED_DRAWDOWN,        // Tạm dừng do drawdown cao
    STATE_PAUSED_LOSS_STREAK,     // Tạm dừng do chuỗi thua liên tiếp
    STATE_PAUSED_NEWS,            // Tạm dừng do có tin tức quan trọng
    STATE_PAUSED_VOLATILITY,      // Tạm dừng do biến động cao
    STATE_REDUCED_RISK,           // Giảm rủi ro (vẫn giao dịch)
    STATE_READY_TO_RESUME         // Sẵn sàng tiếp tục sau khi tạm dừng
};

//--- Market Preset - Loại thị trường và thiết lập tương ứng ---
enum ENUM_MARKET_PRESET {
   PRESET_AUTO     = 0,  // Tự động dựa vào Symbol
   PRESET_FX_MAJOR = 1,  // Forex chính
   PRESET_FX_MINOR = 2,  // Forex phụ
   PRESET_GOLD     = 3,  // Vàng & Bạc
   PRESET_CRYPTO   = 4,  // Tiền điện tử
   PRESET_INDICES  = 5,  // Chỉ số
   PRESET_CUSTOM   = 6   // Tùy chỉnh
};

//--- Cluster Types - Phân loại chiến lược giao dịch ---
enum ENUM_CLUSTER_TYPE {
    CLUSTER_NONE = 0,                // Không xác định
    CLUSTER_1_TREND_FOLLOWING = 1,   // Trend following
    CLUSTER_2_COUNTERTREND = 2,      // Countertrend
    CLUSTER_3_SCALING = 3,           // Scaling (tăng vị thế)
    CLUSTER_4_RANGE = 4              // Range bound
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
   SCENARIO_BULLISH_PULLBACK,          // Bullish pullback pattern
   SCENARIO_BEARISH_PULLBACK,          // Bearish pullback pattern
   SCENARIO_PULLBACK,                  // Pullback vào trend
   SCENARIO_FIBONACCI,                 // Fibonacci retracement
   SCENARIO_MOMENTUM,                  // Momentum breakout
   SCENARIO_REVERSAL,                  // Reversal pattern
   SCENARIO_SCALING                    // Scaling in (tăng vị thế)
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
   REGIME_UNKNOWN = 0,        // Unknown market regime
   REGIME_TRENDING = 1,       // Trending market - từ TradeManager.mqh
   REGIME_WEAK_TREND = 2,     // Weak trending market - caution needed
   REGIME_SIDEWAY = 3,        // Sideway market - từ TradeManager.mqh
   REGIME_VOLATILE = 4,       // Highly volatile market - wider stops required
   REGIME_TRANSITIONING = 5   // Thị trường đang chuyển tiếp giữa các trạng thái - Mới v13
};

//--- Market Phase - Defines the current phase of the market cycle ---
enum ENUM_MARKET_PHASE {
   PHASE_ACCUMULATION,        // Tích lũy
   PHASE_IMPULSE,             // Sóng đẩy mạnh
   PHASE_CORRECTION,          // Điều chỉnh
   PHASE_DISTRIBUTION,        // Phân phối
   PHASE_EXHAUSTION,          // Cạn kiệt
   PHASE_DOWN_ACCUMULATION    // Tích lũy xuống (chỉ có trong MarketProfile.mqh)
};

//--- Trailing Mode - Định nghĩa các phương pháp trailing stop ---
enum ENUM_TRAILING_MODE {
   TRAILING_ATR = 1,          // Trailing stop dựa trên ATR (fix từ TRAILING_MODE_ATR)
   TRAILING_SWING = 2,        // Trailing stop dựa trên swing levels (fix từ TRAILING_MODE_SWING)
   TRAILING_EMA = 3,          // Trailing stop dựa trên EMA (fix từ TRAILING_MODE_EMA)
   TRAILING_PSAR = 4,         // Trailing stop dựa trên Parabolic SAR (fix từ TRAILING_MODE_PSAR)
   TRAILING_ADAPTIVE = 5,     // Trailing thông minh thích ứng theo thị trường (fix từ TRAILING_MODE_ADAPTIVE)
   TRAILING_CHANDELIER = 6,   // Trailing dựa trên Chandelier Exit - Mới v13
   TRAILING_SUPERTREND = 7    // Trailing stop dựa trên SuperTrend indicator (fix từ TRAILING_MODE_SUPERTREND)
};

//--- Log Level - Controls the verbosity of logging ---
enum ENUM_LOG_LEVEL {
   LOG_LEVEL_ERROR = 0,        // Log only errors
   LOG_LEVEL_WARNING = 1,      // Log errors and warnings
   LOG_LEVEL_INFO = 2,         // Log errors, warnings, and info (recommended default)
   LOG_LEVEL_DEBUG = 3,        // Log all details (useful for troubleshooting)
   LOG_LEVEL_TRACE = 4         // Log everything including trace calls
};

//--- Trading Session - Defines different trading sessions ---
enum ENUM_SESSION {
   SESSION_UNKNOWN = 0,         // Không xác định
   SESSION_ASIAN,               // Phiên Á (00:00-08:00 GMT)
   SESSION_EUROPEAN,            // Phiên Âu (08:00-16:00 GMT)
   SESSION_AMERICAN,            // Phiên Mỹ (13:00-21:00 GMT)
   SESSION_EUROPEAN_AMERICAN,   // Phiên giao thoa Âu-Mỹ (13:00-16:00 GMT)
   SESSION_CLOSING              // Phiên đóng cửa
};

//--- Time-based Trade Filter - Controls when trading is permitted ---
enum ENUM_TIME_FILTER {
   TIME_FILTER_NONE = 0,        // Không sử dụng bộ lọc thời gian
   TIME_FILTER_SESSION,         // Chỉ giao dịch trong phiên
   TIME_FILTER_TIME_OF_DAY      // Chỉ giao dịch vào thời điểm cụ thể trong ngày
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

//--- Market Profile - Cấu trúc lưu trữ thông tin profile thị trường ---
struct MarketProfile {
    // Thông số biến động
    double atrCurrent;       // ATR hiện tại
    double atrRatio;         // Tỷ lệ so với trung bình 20 ngày
    double atrSlope;         // Độ dốc của ATR (tăng/giảm)
    
    // Thông số xu hướng
    double adxH4;            // ADX trên H4
    double adxSlope;         // Độ dốc của ADX (tăng/giảm)
    double emaSlope;         // Độ dốc của EMA (mới v13)
    
    // Thông số volume
    bool volumeSpike;        // Volume tăng đột biến
    bool volumeDeclining;    // Volume đang suy giảm
    
    // Phiên giao dịch
    ENUM_SESSION currentSession; // Phiên Á, Âu, Mỹ, giao thoa
    
    // Đặc tính thị trường
    bool isTrending;         // Đang có xu hướng
    bool isSideway;          // Đang sideway
    bool isVolatile;         // Biến động cao
    bool isRangebound;       // Dao động trong biên độ
    
    // Mới v13 - Hỗ trợ phát hiện chuyển tiếp (soft transition)
    bool isTransitioning;    // Thị trường đang chuyển tiếp giữa các chế độ
    double regimeConfidence; // Mức độ tin cậy của chế độ thị trường (0.0-1.0)
    
    // Constructor
    void MarketProfile() {
        Reset();
    }
    
    // Reset to defaults
    void Reset() {
        atrCurrent = 0;
        atrRatio = 1.0;
        atrSlope = 0;
        adxH4 = 0;
        adxSlope = 0;
        emaSlope = 0;
        volumeSpike = false;
        volumeDeclining = false;
        currentSession = SESSION_UNKNOWN;
        isTrending = false;
        isSideway = false;
        isVolatile = false;
        isRangebound = false;
        isTransitioning = false;
        regimeConfidence = 0.0;
    }
    
    // Get a descriptive string of the current profile
    string ToString() const {
        string description = "";
        
        // Add session info
        switch(currentSession) {
            case SESSION_ASIAN: description += "Asian"; break;
            case SESSION_EUROPEAN: description += "European"; break;
            case SESSION_AMERICAN: description += "American"; break;
            case SESSION_EUROPEAN_AMERICAN: description += "EU-US Overlap"; break;
            case SESSION_CLOSING: description += "Closing"; break;
            default: description += "Unknown";
        }
        
        description += " session, ";
        
        // Add market characteristics
        if(isTransitioning) description += "Transitioning, ";
        else if(isTrending) description += "Trending, ";
        else if(isSideway) description += "Sideway, ";
        
        if(isVolatile) description += "Volatile, ";
        if(isRangebound) description += "Range-bound, ";
        
        // Add ATR info
        description += "ATR: " + DoubleToString(atrCurrent, 5) + 
                      " (" + DoubleToString(atrRatio * 100, 1) + "% avg), ";
        
        // Add ADX info
        description += "ADX: " + DoubleToString(adxH4, 1) + 
                      " (slope: " + DoubleToString(adxSlope, 2) + ")";
        
        return description;
    }
};

//--- News Event - Cấu trúc lưu trữ sự kiện tin tức - Mới v13 ---
struct NewsEvent {
    datetime time;             // Thời gian tin tức
    string currency;           // Tiền tệ ảnh hưởng
    int impact;                // Mức độ ảnh hưởng (1-3)
    string title;              // Tiêu đề tin tức
    
    // Hàm so sánh cho việc sắp xếp
    int Compare(const NewsEvent &other) const {
        if(time < other.time) return -1;
        if(time > other.time) return 1;
        return 0;
    }
    
    // Constructor
    void NewsEvent() {
        Reset();
    }
    
    // Reset to defaults
    void Reset() {
        time = 0;
        currency = "";
        impact = 0;
        title = "";
    }
};

//--- Swing Point - Cấu trúc lưu trữ điểm swing - Mới v13 ---
struct SwingPoint {
    datetime time;         // Thời gian
    double price;          // Giá
    bool isHigh;           // True = đỉnh, False = đáy
    int strength;          // Độ mạnh (1-10)
    
    // Constructor
    void SwingPoint() {
        Reset();
    }
    
    // Reset to defaults
    void Reset() {
        time = 0;
        price = 0;
        isHigh = false;
        strength = 0;
    }
};

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
   
   // Constructor
   void SignalInfo() {
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
         case SCENARIO_BULLISH_PULLBACK: return "Bullish Pullback";
         case SCENARIO_BEARISH_PULLBACK: return "Bearish Pullback";
         case SCENARIO_PULLBACK: return "Pullback";
         case SCENARIO_FIBONACCI: return "Fibonacci";
         case SCENARIO_MOMENTUM: return "Momentum";
         case SCENARIO_REVERSAL: return "Reversal";
         case SCENARIO_SCALING: return "Scaling";
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
   
   // Mới v13 - Thêm các indicator mới
   double supertrend;          // SuperTrend indicator
   double psar;                // Parabolic SAR
   double bollinger_upper;     // Bollinger Band upper
   double bollinger_lower;     // Bollinger Band lower
   double bollinger_middle;    // Bollinger Band middle
   
   // Constructor
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
      
      // Reset new indicators
      supertrend = 0.0;
      psar = 0.0;
      bollinger_upper = 0.0;
      bollinger_lower = 0.0;
      bollinger_middle = 0.0;
   }
};

//--- Candle Pattern - Represents a detected candlestick pattern ---
struct CandlePattern {
   bool is_valid;              // Is this a valid pattern?
   int pattern_type;           // Type of pattern (1=Pin Bar, 2=Engulfing, 3=Inside Bar, etc.)
   int direction;              // Direction (1=bullish, -1=bearish, 0=neutral)
   double entry_price;         // Suggested entry price
   double stop_loss;           // Suggested stop loss level
   double risk_reward;         // Calculated risk/reward ratio
   int strength;               // Pattern strength (1-10)
   
   // Constructor
   void CandlePattern() {
      Reset();
   }
   
   // Reset all values to defaults
   void Reset() {
      is_valid = false;
      pattern_type = 0;
      direction = 0;
      entry_price = 0.0;
      stop_loss = 0.0;
      risk_reward = 0.0;
      strength = 0;
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
   
   // Mới v13 - Chandelier Exit tracking
   double chandelier_exit;      // Chandelier Exit level
   bool use_chandelier;         // Flag to use Chandelier Exit
   
   // Constructor
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
      chandelier_exit = 0.0;
      use_chandelier = false;
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
   double largestWin;            // Largest winning trade
   double largestLoss;           // Largest losing trade
   double averageWin;            // Average winning trade
   double averageLoss;           // Average losing trade
   double winRate;               // Win rate percentage
   double profitFactor;          // Profit factor
   double expectedPayoff;        // Expected payoff per trade
   int maxConsecutiveWins;       // Maximum consecutive wins
   int maxConsecutiveLosses;     // Maximum consecutive losses
   int currentConsecutiveWins;   // Current consecutive wins
   int currentConsecutiveLosses; // Current consecutive losses
   
   // Mới v13 - Tracking theo session và regime
   double sessionProfit[5];      // Profit by session (Asian, European, American, etc.)
   int sessionTrades[5];         // Trades by session
   double regimeProfit[6];       // Profit by market regime
   int regimeTrades[6];          // Trades by market regime
   
   // Constructor
   void TradeStatistics() {
      Reset();
   }
   
   // Reset to defaults
   void Reset() {
      totalTrades = 0;
      winningTrades = 0;
      losingTrades = 0;
      totalProfit = 0.0;
      totalLoss = 0.0;
      largestWin = 0.0;
      largestLoss = 0.0;
      averageWin = 0.0;
      averageLoss = 0.0;
      winRate = 0.0;
      profitFactor = 0.0;
      expectedPayoff = 0.0;
      maxConsecutiveWins = 0;
      maxConsecutiveLosses = 0;
      currentConsecutiveWins = 0;
      currentConsecutiveLosses = 0;
      
      // Reset session and regime tracking
      ArrayInitialize(sessionProfit, 0.0);
      ArrayInitialize(sessionTrades, 0);
      ArrayInitialize(regimeProfit, 0.0);
      ArrayInitialize(regimeTrades, 0);
   }
};

//--- Session Info - Tracks trading session information ---
struct SessionInfo {
   bool isAsianSession;         // Is current time in Asian session?
   bool isLondonSession;        // Is current time in London session?
   bool isNYSession;            // Is current time in New York session?
   bool isOverlapSession;       // Is current time in session overlap?
   int sessionType;             // Session type code (0=none, 1=Asian, 2=London, 3=NY, 4=overlap)
   string sessionName;          // Name of current session
   datetime asianOpen;          // Asian session open time
   datetime asianClose;         // Asian session close time
   datetime londonOpen;         // London session open time
   datetime londonClose;        // London session close time
   datetime nyOpen;             // NY session open time
   datetime nyClose;            // NY session close time
   
   // Constructor
   void SessionInfo() {
      Reset();
   }
   
   // Reset all values to defaults
   void Reset() {
      isAsianSession = false;
      isLondonSession = false;
      isNYSession = false;
      isOverlapSession = false;
      sessionType = 0;
      sessionName = "None";
      asianOpen = 0;
      asianClose = 0;
      londonOpen = 0;
      londonClose = 0;
      nyOpen = 0;
      nyClose = 0;
   }
};

//--- Performance Metrics - Contains trading performance statistics ---
struct PerformanceMetrics {
   int    totalTrades;           // Tổng số lệnh
   double winRate;               // Tỷ lệ thắng (%)
   double profitFactor;          // Hệ số lợi nhuận
   double expectedPayoff;        // Kỳ vọng lợi nhuận trung bình mỗi lệnh
   double sharpeRatio;           // Tỷ lệ Sharpe (đánh giá hiệu suất trên rủi ro)
   double maxDrawdown;           // Drawdown tối đa (%)
   double profitToDrawdown;      // Tỷ lệ lợi nhuận trên drawdown
   double avgRR;                 // Tỷ lệ Risk/Reward trung bình
   
   // Mới v13 - Thông tin theo phiên
   double asianSessionWinRate;   // Tỷ lệ thắng phiên Á
   double euroSessionWinRate;    // Tỷ lệ thắng phiên Âu
   double nySessionWinRate;      // Tỷ lệ thắng phiên Mỹ
   double overlapSessionWinRate; // Tỷ lệ thắng phiên giao thoa
   
   // Constructor
   void PerformanceMetrics() {
      Reset();
   }
   
   // Reset về giá trị mặc định
   void Reset() {
      totalTrades = 0;
      winRate = 0.0;
      profitFactor = 0.0;
      expectedPayoff = 0.0;
      sharpeRatio = 0.0;
      maxDrawdown = 0.0;
      profitToDrawdown = 0.0;
      avgRR = 0.0;
      
      asianSessionWinRate = 0.0;
      euroSessionWinRate = 0.0;
      nySessionWinRate = 0.0;
      overlapSessionWinRate = 0.0;
   }
};

//--- Scenario Statistics - Track performance of each entry scenario ---
struct ScenarioStats {
    int total;           // Tổng số giao dịch theo scenario này
    int wins;            // Số lần thắng
    double winRate;      // Tỷ lệ thắng
    double avgProfit;    // Lợi nhuận trung bình
    double avgLoss;      // Lỗ trung bình
    double profitFactor; // Hệ số lợi nhuận
    
    // Constructor
    void ScenarioStats() {
        Reset();
    }
    
    // Reset to defaults
    void Reset() {
        total = 0;
        wins = 0;
        winRate = 0.0;
        avgProfit = 0.0;
        avgLoss = 0.0;
        profitFactor = 0.0;
    }
};

//--- Risk Management Info - Mới v13, thông tin quản lý rủi ro ---
struct RiskManagementInfo {
    double accountBalance;        // Số dư tài khoản
    double accountEquity;         // Equity tài khoản
    double dayStartEquity;        // Equity đầu ngày
    double currentDrawdown;       // Drawdown hiện tại (%)
    double dailyProfitLoss;       // Lãi/lỗ trong ngày
    double baseRiskPercent;       // % risk cơ sở
    double currentRiskPercent;    // % risk hiện tại (có thể đã điều chỉnh)
    int consecutiveLosses;        // Số lần thua liên tiếp hiện tại
    int dayTrades;                // Số lệnh trong ngày
    datetime pauseUntil;          // Thời gian tạm dừng đến khi nào
    bool isPaused;                // EA có đang tạm dừng không
    
    // Constructor
    void RiskManagementInfo() {
        Reset();
    }
    
    // Reset all values to defaults
    void Reset() {
        accountBalance = 0.0;
        accountEquity = 0.0;
        dayStartEquity = 0.0;
        currentDrawdown = 0.0;
        dailyProfitLoss = 0.0;
        baseRiskPercent = 1.0;
        currentRiskPercent = 1.0;
        consecutiveLosses = 0;
        dayTrades = 0;
        pauseUntil = 0;
        isPaused = false;
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
      case SCENARIO_BULLISH_PULLBACK: return "Bullish Pullback";
      case SCENARIO_BEARISH_PULLBACK: return "Bearish Pullback";
      case SCENARIO_PULLBACK: return "Pullback";
      case SCENARIO_FIBONACCI: return "Fibonacci";
      case SCENARIO_MOMENTUM: return "Momentum";
      case SCENARIO_REVERSAL: return "Reversal";
      case SCENARIO_SCALING: return "Scaling";
      default: return "Unknown Scenario";
   }
}

// Convert market regime to string
string RegimeToString(ENUM_MARKET_REGIME regime) {
   switch(regime) {
      case REGIME_UNKNOWN: return "Unknown";
      case REGIME_TRENDING: return "Trending"; 
      case REGIME_WEAK_TREND: return "Weak Trend";
      case REGIME_SIDEWAY: return "Sideway"; 
      case REGIME_VOLATILE: return "Volatile";
      case REGIME_TRANSITIONING: return "Transitioning"; // Mới v13
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

// Convert EA state to string - Mới v13
string EAStateToString(ENUM_EA_STATE state) {
   switch(state) {
      case STATE_RUNNING: return "Running";
      case STATE_PAUSED_DRAWDOWN: return "Paused (Drawdown)";
      case STATE_PAUSED_LOSS_STREAK: return "Paused (Loss Streak)";
      case STATE_PAUSED_NEWS: return "Paused (News)";
      case STATE_PAUSED_VOLATILITY: return "Paused (Volatility)";
      case STATE_REDUCED_RISK: return "Reduced Risk";
      case STATE_READY_TO_RESUME: return "Ready to Resume";
      default: return "Unknown State";
   }
}

// Convert session to string - Mới v13
string SessionToString(ENUM_SESSION session) {
   switch(session) {
      case SESSION_ASIAN: return "Asian";
      case SESSION_EUROPEAN: return "European";
      case SESSION_AMERICAN: return "American";
      case SESSION_EUROPEAN_AMERICAN: return "EU-US Overlap";
      case SESSION_CLOSING: return "Closing";
      default: return "Unknown Session";
   }
}

// Tính biên độ dao động ATR theo tỷ lệ - Mới v13
double CalculateATRBasedSize(double baseATR, double atrRatio, double atrMultiplier) {
   // Tính toán mức ATR điều chỉnh dựa trên tỷ lệ ATR hiện tại so với trung bình
   double adjustedMultiplier = atrMultiplier;
   
   // Nếu thị trường đang biến động cao
   if(atrRatio > 1.5) {
      // Giảm hệ số để tránh SL/TP quá rộng
      adjustedMultiplier *= 0.8;
   }
   // Nếu thị trường đang biến động thấp
   else if(atrRatio < 0.7) {
      // Tăng hệ số để tránh SL/TP quá hẹp
      adjustedMultiplier *= 1.2;
   }
   
   return baseATR * adjustedMultiplier;
}

// Tính toán độ dốc EMA - Mới v13
double CalculateEMASlope(double currentEMA, double previousEMA) {
   return (currentEMA - previousEMA) / previousEMA * 100.0;
}

// Xác định phiên giao dịch hiện tại - Mới v13
ENUM_SESSION DetermineCurrentSession() {
   // Lấy giờ GMT
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   int hour = dt.hour;
   
   // Phiên Á: 00:00 - 08:00 GMT
   if(hour >= 0 && hour < 8) {
      return SESSION_ASIAN;
   }
   // Phiên Âu: 08:00 - 16:00 GMT
   else if(hour >= 8 && hour < 13) {
      return SESSION_EUROPEAN;
   }
   // Phiên Overlap Âu-Mỹ: 13:00 - 16:00 GMT
   else if(hour >= 13 && hour < 16) {
      return SESSION_EUROPEAN_AMERICAN;
   }
   // Phiên Mỹ: 16:00 - 21:00 GMT
   else if(hour >= 16 && hour < 21) {
      return SESSION_AMERICAN;
   }
   // Phiên đóng cửa
   else {
      return SESSION_CLOSING;
   }
}