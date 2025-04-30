//+------------------------------------------------------------------+
//|                                            MarketMonitor.mqh |
//|                              Copyright 2023, MetaQuotes Ltd. |
//|                                         https://www.mql5.com |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Indicators/Trend.mqh>        // Cho các chỉ báo xu hướng
#include <Indicators/Oscillators.mqh>  // Cho các chỉ báo dao động
#include "Logger.mqh"
#include "CommonStructs.mqh"

// Forward declarations
class CLogger;

// Cấu trúc cache dữ liệu thị trường
struct MarketCache {
    // Giá trị các đường EMA
    double ema_fast_entry;     // EMA nhanh (H1)
    double ema_slow_entry;     // EMA chậm (H1)
    double ema_fast_trend;     // EMA nhanh (H4)
    double ema_slow_trend;     // EMA chậm (H4)
    
    // Giá trị ATR
    double atr_entry;          // ATR của khung thời gian vào lệnh
    double atr_trend;          // ATR của khung thời gian xác định xu hướng
    
    // Các giá trị chỉ báo dao động
    double rsi_value;          // Giá trị RSI hiện tại
    double rsi_prev;           // Giá trị RSI trước đó
    double macd_main;          // Đường MACD chính
    double macd_signal;        // Đường MACD tín hiệu
    double stoch_main;         // Stochastic Main
    double stoch_signal;       // Stochastic Signal
    
    // Giá trị khác
    double adr;                // Biên độ dao động hàng ngày trung bình
    double spread;             // Spread hiện tại (tính bằng pip)
    double volatility_index;   // Chỉ số biến động
    double market_noise;       // Noise ratio
    
    // Flags và điểm đánh dấu
    ENUM_MARKET_REGIME market_regime;  // Chế độ thị trường (xu hướng, dao động...)
    bool trend_aligned;        // Các xu hướng có thống nhất không
    int last_update_time;      // Thời gian cập nhật dữ liệu cuối cùng
};

//+------------------------------------------------------------------+
//| Market Monitor Class                                              |
//+------------------------------------------------------------------+
class CMarketMonitor
{
private:
    string            m_Symbol;          // Symbol để phân tích
    ENUM_TIMEFRAMES   m_EntryTimeframe;  // Khung thời gian vào lệnh
    ENUM_TIMEFRAMES   m_TrendTimeframe;  // Khung thời gian xác định xu hướng
    ENUM_TIMEFRAMES   m_NestedTimeframe; // Khung thời gian lồng nhau (thấp hơn)
    int               m_FastPeriod;      // Chu kỳ EMA nhanh
    int               m_SlowPeriod;      // Chu kỳ EMA chậm
    int               m_AtrPeriod;       // Chu kỳ ATR
    bool              m_UseNestedTimeframe; // Có sử dụng khung thời gian lồng nhau không
    
    // Handles cho các chỉ báo
    int               m_HandleEmaFastEntry;  // Handle cho EMA nhanh (entry)
    int               m_HandleEmaSlowEntry;  // Handle cho EMA chậm (entry)
    int               m_HandleEmaFastTrend;  // Handle cho EMA nhanh (trend)
    int               m_HandleEmaSlowTrend;  // Handle cho EMA chậm (trend)
    int               m_HandleAtrEntry;      // Handle cho ATR (entry)
    int               m_HandleAtrTrend;      // Handle cho ATR (trend)
    int               m_HandleRsi;           // Handle cho RSI
    int               m_HandleMacd;          // Handle cho MACD
    int               m_HandleStoch;         // Handle cho Stochastic
    
    // Dữ liệu cache
    MarketCache       m_Cache;           // Cache dữ liệu thị trường
    
    // Logger
    CLogger*          m_Logger;          // Logger cho ghi log
    
    // Private methods
    void              InitializeIndicators();
    void              ReleaseIndicators();
    void              UpdateIndicatorData();
    ENUM_MARKET_REGIME DetermineMarketRegime();
    bool              CheckPriceAlignment();
    double            CalculateVolatilityFactor();
    double            CalculateMarketNoiseRatio();

public:
                      CMarketMonitor();
                     ~CMarketMonitor();
                     
    // Initialization
    bool              Initialize(string symbol, 
                                ENUM_TIMEFRAMES entryTimeframe, 
                                ENUM_TIMEFRAMES trendTimeframe,
                                int fastPeriod, 
                                int slowPeriod,
                                int atrPeriod,
                                bool useNestedTf,
                                ENUM_TIMEFRAMES nestedTimeframe);
                                
    // Core analysis methods
    void              Update();
    ENUM_TRADE_SIGNAL GenerateSignals(double &entryPrice, double &stopLoss, double &takeProfit, ENUM_ENTRY_SCENARIO &scenario);
    
    // Specific pattern detection methods
    bool              AnalyzePullback(bool isUptrend, double &depth, double &speed, double &strength,
                                    double &entryPrice, double &stopLevel, string &description);
    bool              DetectFibonacciPullback(bool isUptrend, double &entryLevels[], double &qualityScore);
    bool              DetectHarmonicPattern(bool isUptrend, double &entryLevel, double &stopLevel, double &qualityScore, string &patternName);
    bool              DetectMomentumShift(bool isUptrend, double &entryPrice, double &stopLevel, double &quality, string &description);
    bool              DetectLiquiditySweep(bool isUptrend, double &entryPrice, double &stopLevel, double &quality, string &description);
    bool              DetectFakeBreakout(bool isUptrend, double &entryPrice, double &stopLevel, double &quality, string &description);
    
    // Support methods
    bool              DetectRangeFormation(int &startBar, int &endBar, double &upperBound, double &lowerBound);
    bool              IsStrongTrend(bool isUptrend);
    double            GetVolatilityFactor() { return m_Cache.volatility_index; }
    ENUM_MARKET_REGIME GetMarketRegime() { return m_Cache.market_regime; }
    
    // Logger setter
    void              SetLogger(CLogger* logger) { m_Logger = logger; }
    
    // Helper functions to get indicators
    double            GetEmaValue(bool isFast, bool isEntryTf);
    double            GetAtrValue(bool isEntryTf);
    double            GetRsiValue();
};

//+------------------------------------------------------------------+
//| Phân tích pullback trong xu hướng                                |
//+------------------------------------------------------------------+
bool CMarketMonitor::AnalyzePullback(bool isUptrend, double &depth, double &speed, double &strength,
                                   double &entryPrice, double &stopLevel, string &description)
{
   // Khởi tạo giá trị mặc định
   depth = 0; speed = 0; strength = 0;
   entryPrice = 0; stopLevel = 0; 
   description = "";
   
   // Khai báo và thiết lập tham số cho phương pháp (Nên chuyển thành input parameters)
   double MIN_PULLBACK_DEPTH = 0.2;  // Độ sâu pullback tối thiểu tính bằng ATR
   double MAX_PULLBACK_DEPTH = 0.8;  // Độ sâu pullback tối đa tính bằng ATR
   double MIN_BOUNCE_STRENGTH = 0.2; // Sức mạnh hồi phục tối thiểu
   double MAX_BOUNCE_STRENGTH = 0.9; // Sức mạnh hồi phục tối đa
   double SL_ATR_BUFFER = 0.3;       // Buffer cho SL tính bằng ATR
   int MAX_LOOKBACK = 50;            // Số nến tối đa để tìm sóng đẩy và pullback
   
   // Lấy dữ liệu giá lịch sử
   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, high) <= 0 ||
       CopyLow(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, low) <= 0 ||
       CopyClose(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, close) <= 0 ||
       CopyOpen(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, open) <= 0) {
      m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích pullback");
      return false;
   }
   
   // BƯỚC 1: Tìm swing (điểm đảo chiều) gần nhất trên pullback
   int swingBar = 0;
   double swingPrice = 0;
   
   if (isUptrend) {
      // Trong xu hướng tăng, tìm đáy gần nhất (local minimum)
      for (int i = 3; i < MAX_LOOKBACK - 3; i++) {
         // Đáy khi low[i] thấp hơn cả 2 nến trước và 2 nến sau
         if (low[i] < low[i-1] && low[i] < low[i-2] && 
             low[i] < low[i+1] && low[i] < low[i+2]) {
            swingBar = i;
            swingPrice = low[i];
            break;
         }
      }
   } else {
      // Trong xu hướng giảm, tìm đỉnh gần nhất (local maximum)
      for (int i = 3; i < MAX_LOOKBACK - 3; i++) {
         // Đỉnh khi high[i] cao hơn cả 2 nến trước và 2 nến sau
         if (high[i] > high[i-1] && high[i] > high[i-2] && 
             high[i] > high[i+1] && high[i] > high[i+2]) {
            swingBar = i;
            swingPrice = high[i];
            break;
         }
      }
   }
   
   // Kiểm tra nếu không tìm thấy swing
   if (swingBar <= 0 || swingPrice <= 0) {
      m_Logger.LogDebug("Không tìm thấy swing rõ ràng cho pullback");
      return false;
   }
   
   // BƯỚC 2: Tìm đỉnh/đáy của sóng trước pullback (điểm bắt đầu sóng)
   int impulseStartBar = 0;
   double impulseStartPrice = 0;
   
   if (isUptrend) {
      // Tìm đỉnh trước đáy (swing low) - đây là điểm BẮT ĐẦU của pullback
      for (int i = swingBar + 1; i < MAX_LOOKBACK - 2; i++) {
         if (high[i] > high[i-1] && high[i] > high[i+1]) {
            impulseStartBar = i;
            impulseStartPrice = high[i];
            break;
         }
      }
   } else {
      // Tìm đáy trước đỉnh (swing high) - đây là điểm BẮT ĐẦU của pullback
      for (int i = swingBar + 1; i < MAX_LOOKBACK - 2; i++) {
         if (low[i] < low[i-1] && low[i] < low[i+1]) {
            impulseStartBar = i;
            impulseStartPrice = low[i];
            break;
         }
      }
   }
   
   // Kiểm tra nếu không tìm thấy điểm bắt đầu
   if (impulseStartBar <= 0 || impulseStartPrice <= 0) {
      m_Logger.LogDebug("Không tìm thấy điểm bắt đầu sóng trước pullback");
      return false;
   }
   
   // BƯỚC 3: Tính các thông số của pullback
   
   // Tính độ sâu pullback - tỷ lệ pullback so với sóng đẩy ban đầu
   double impulseRange = MathAbs(impulseStartPrice - swingPrice);
   double atr = m_Cache.atr_entry;
   
   if (atr <= 0) {
      m_Logger.LogError("ATR không hợp lệ cho phân tích pullback");
      return false;
   }
   
   // Độ sâu pullback: Tương quan với ATR (bao nhiêu lần ATR)
   depth = impulseRange / atr;
   
   // Tốc độ: Dựa trên số lượng nến hình thành pullback
   speed = 1.0 / (swingBar + 1);  // Càng ít nến, tốc độ càng cao
   
   // Sức mạnh hồi phục: Tính từ đáy/đỉnh pullback đến giá hiện tại
   double currentPrice = close[0];
   double bounceRange = MathAbs(currentPrice - swingPrice);
   strength = bounceRange / impulseRange;  // Tỷ lệ phục hồi (0-1+)
   
   // BƯỚC 4: Kiểm tra các điều kiện pullback chất lượng
   
   // Kiểm tra nếu pullback có độ sâu hợp lý
   if (depth < MIN_PULLBACK_DEPTH || depth > MAX_PULLBACK_DEPTH) {
      m_Logger.LogDebug(StringFormat("Độ sâu pullback không phù hợp: %.2f ATR", depth));
      return false;
   }
   
   // Kiểm tra nếu đã có hồi phục từ pullback (để tránh vào lệnh quá sớm)
   if (strength < MIN_BOUNCE_STRENGTH || strength > MAX_BOUNCE_STRENGTH) {
      m_Logger.LogDebug(StringFormat("Sức mạnh hồi phục không phù hợp: %.2f", strength));
      return false;
   }
   
   // BƯỚC 5: Kiểm tra pullback có nằm trong vùng EMA không
   bool nearEMA = false;
   double emaDistance = 0;
   
   if (isUptrend) {
      emaDistance = MathAbs(swingPrice - m_Cache.ema_fast_entry) / atr;
      nearEMA = (emaDistance < 0.5);  // Đáy pullback gần với EMA nhanh
   } else {
      emaDistance = MathAbs(swingPrice - m_Cache.ema_fast_entry) / atr;
      nearEMA = (emaDistance < 0.5);  // Đỉnh pullback gần với EMA nhanh
   }
   
   // BƯỚC 6: Thiết lập thông tin cho giao dịch
   entryPrice = close[0];  // Vào lệnh tại giá hiện tại
   
   // Đặt stop loss dựa trên swing point với buffer ATR
   if (isUptrend) {
      stopLevel = swingPrice - (atr * SL_ATR_BUFFER);
   } else {
      stopLevel = swingPrice + (atr * SL_ATR_BUFFER);
   }
   
   // Tạo mô tả chi tiết
   string emaInfo = nearEMA ? " gần EMA" : "";
   string trendDir = isUptrend ? "Tăng" : "Giảm";
   description = StringFormat("Pullback %s: Độ sâu %.1f ATR, Hồi phục %.0f%%%s", 
                            trendDir, depth, strength * 100, emaInfo);
   
   m_Logger.LogInfo("Phát hiện pullback chất lượng: " + description);
   
   return true;
}
