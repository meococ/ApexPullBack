//+------------------------------------------------------------------+
//|                                               MarketMonitor.mqh  |
//|          Dev v13-MarketMonitor top 5% EA thế giới làm được       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "13.0"

// Bao gồm các thư viện cần thiết
#include <Arrays/ArrayObj.mqh>
#include "Logger.mqh"
#include "CommonStructs.mqh"

// Định nghĩa enum phân loại thị trường
enum ENUM_MARKET_PROFILE_TYPE
{
   MARKET_PROFILE_UNKNOWN,      // Chưa xác định
   MARKET_PROFILE_STRONG_TREND, // Xu hướng mạnh
   MARKET_PROFILE_WEAK_TREND,   // Xu hướng yếu
   MARKET_PROFILE_RANGING,      // Sideway rõ ràng
   MARKET_PROFILE_VOLATILE,     // Biến động mạnh
   MARKET_PROFILE_ACCUMULATION, // Tích lũy
   MARKET_PROFILE_DISTRIBUTION  // Phân phối
};

// Định nghĩa enum cho loại divergence
enum ENUM_DIVERGENCE_TYPE
{
   DIVERGENCE_NONE,             // Không có divergence
   DIVERGENCE_REGULAR_BULLISH,  // Divergence thông thường - Xu hướng tăng
   DIVERGENCE_REGULAR_BEARISH,  // Divergence thông thường - Xu hướng giảm
   DIVERGENCE_HIDDEN_BULLISH,   // Divergence ẩn - Xu hướng tăng
   DIVERGENCE_HIDDEN_BEARISH    // Divergence ẩn - Xu hướng giảm
};

// Định nghĩa enum cho các phiên giao dịch
enum ENUM_TRADING_SESSION
{
   SESSION_UNKNOWN,           // Không xác định
   SESSION_ASIAN,             // Phiên Á (00:00-08:00 GMT)
   SESSION_EUROPEAN,          // Phiên Âu (08:00-16:00 GMT)
   SESSION_AMERICAN,          // Phiên Mỹ (13:00-21:00 GMT)
   SESSION_EUROPEAN_AMERICAN, // Phiên Overlap Âu-Mỹ (13:00-16:00 GMT)
   SESSION_CLOSING            // Phiên đóng cửa (21:00-00:00 GMT)
};

// Định nghĩa cấu trúc cho Spike Bar
struct SpikeBarInfo
{
   datetime time;             // Thời gian của nến
   double   high;             // Giá cao nhất
   double   low;              // Giá thấp nhất
   double   bodySize;         // Kích thước thân nến
   double   totalRange;       // Tổng biên độ nến
   long     volume;           // Khối lượng giao dịch
   double   volumeRatio;      // Tỷ lệ so với volume trung bình
   bool     isBullish;        // Nến tăng hay giảm
};

//+------------------------------------------------------------------+
//| Market Monitor Class                                             |
//| Chịu trách nhiệm đọc và phân tích các chỉ báo thị trường        |
//| Cung cấp dữ liệu cho MarketProfile và TradeDecision              |
//+------------------------------------------------------------------+
class CMarketMonitor
{
private:
   // Thuộc tính cơ bản
   string               m_Symbol;                // Symbol để phân tích
   ENUM_TIMEFRAMES      m_Timeframe;             // Khung thời gian chính
   CLogger*             m_Logger;                // Đối tượng logger
   bool                 m_IsInitialized;         // Cờ theo dõi trạng thái khởi tạo
   
   // Cấu hình đa khung thời gian
   bool                 m_UseMultiTimeframe;     // Sử dụng đa khung thời gian
   ENUM_TIMEFRAMES      m_HigherTimeframe;       // Khung thời gian cao hơn
   bool                 m_UseNestedTimeframe;    // Sử dụng khung thời gian lồng nhau
   ENUM_TIMEFRAMES      m_NestedTimeframe;       // Khung thời gian lồng

   // Handle của các indicator
   int                  m_HandleEMA34;           // Handle EMA 34
   int                  m_HandleEMA89;           // Handle EMA 89
   int                  m_HandleEMA200;          // Handle EMA 200
   int                  m_HandleRSI;             // Handle RSI
   int                  m_HandleMACD;            // Handle MACD
   int                  m_HandleBB;              // Handle Bollinger Bands
   int                  m_HandleADX;             // Handle ADX
   int                  m_HandleATR;             // Handle ATR
   
   // Thông số cấu hình indicator
   int                  m_RSI_Period;            // Chu kỳ RSI (mặc định 14)
   int                  m_ADX_Period;            // Chu kỳ ADX (mặc định 14)
   int                  m_ATR_Period;            // Chu kỳ ATR (mặc định 14)
   
   // Thông số cấu hình phụ
   double               m_EnvelopeDeviation;     // Độ lệch Envelope (%)
   bool                 m_EnableMarketRegimeFilter; // Bật/tắt lọc chế độ thị trường
   
   // Biến trạng thái phân tích
   ENUM_MARKET_STATE    m_MarketState;           // Trạng thái thị trường hiện tại
   ENUM_MARKET_PROFILE_TYPE m_MarketProfile;     // Loại hình thái thị trường hiện tại
   
   // Session Detection - TÍNH NĂNG MỚI
   ENUM_TRADING_SESSION m_CurrentSession;        // Phiên giao dịch hiện tại
   datetime             m_LastSessionCheckTime;  // Thời gian kiểm tra phiên gần nhất
   int                  m_GMTOffset;             // Độ lệch múi giờ GMT
   
   // Cấu trúc lưu trữ dữ liệu indicator đã tính toán
   struct CachedData
   {
      // Dữ liệu EMA
      double ema34;              // Giá trị EMA 34
      double ema89;              // Giá trị EMA 89
      double ema200;             // Giá trị EMA 200
      
      // Dữ liệu chỉ báo
      double rsi;                // Giá trị RSI
      double rsi_prev;           // Giá trị RSI trước đó
      double macd;               // Đường MACD chính
      double macd_signal;        // Đường tín hiệu MACD
      double adx;                // Giá trị ADX
      double adx_plus_di;        // Đường +DI của ADX
      double adx_minus_di;       // Đường -DI của ADX
      double atr;                // Giá trị ATR
      double bb_upper;           // Bollinger band trên
      double bb_middle;          // Bollinger band giữa
      double bb_lower;           // Bollinger band dướ
      // Dữ liệu giá
      double close;              // Giá đóng cửa hiện tại
      double open;               // Giá mở cửa hiện tại
      double high;               // Giá cao nhất hiện tại
      double low;                // Giá thấp nhất hiện tại
      double prev_close;         // Giá đóng cửa trước đó
      long   volume;             // Khối lượng giao dịch hiện tại
      long   avg_volume;         // Khối lượng giao dịch trung bình
      
      // Dữ liệu thời gian
      MqlDateTime time;          // Thời gian nến hiện tại
      
      // TÍNH NĂNG MỚI: Lưu trữ trạng thái divergence
      ENUM_DIVERGENCE_TYPE rsiDivergence;    // Trạng thái divergence của RSI
      ENUM_DIVERGENCE_TYPE macdDivergence;   // Trạng thái divergence của MACD
   };
   
   // Cấu trúc lưu trữ swing point
   struct SwingPoint {
      double price;              // Giá tại swing point
      datetime time;             // Thời gian tại swing point
      int barIndex;              // Vị trí nến của swing point
      bool isHigh;               // True = đỉnh, False = đáy
      long volume;               // Khối lượng tại swing point
   };
   
   // Cache các swing point gần đây
   SwingPoint m_RecentSwings[10];// Lưu trữ 10 swing point gần nhất
   int m_SwingCount;             // Số lượng swing point đã tìm được
   
   // TÍNH NĂNG MỚI: Lưu trữ thông tin Spike Bar
   SpikeBarInfo m_RecentSpikeBars[5];  // Lưu trữ 5 spike bars gần nhất
   int m_SpikeBarCount;                // Số lượng spike bar đã tìm được
   
   // Market Context Memory (lưu trữ ngắn hạn thông tin thị trường)
   struct MarketContextHistory {
      ENUM_MARKET_PROFILE_TYPE profiles[10];  // Profile 10 nến gần nhất
      bool trendUp[10];                       // Trend 10 nến gần nhất
      bool trendDown[10];                     // Trend 10 nến gần nhất
      double atrRatio[10];                    // ATR ratio 10 nến gần nhất
      bool volumeSpike[10];                   // Volume spike 10 nến gần nhất
      ENUM_TRADING_SESSION sessions[10];      // Session 10 nến gần nhất (MỚI)
      int currentIndex;                       // Vị trí ghi hiện tại (circular buffer)
   };
   
   MarketContextHistory m_MarketHistory;      // Lưu trữ lịch sử thị trường
   
   // Signal Info lưu trữ
   SignalInfo           m_LastSignal;          // Tín hiệu gần nhất được phát hiện
   
   // Biến cache và theo dõi cập nhật
   CachedData           m_Cache;                 // Cache dữ liệu indicator
   datetime             m_LastUpdateTime;        // Thời gian cập nhật gần nhất
   bool                 m_IsNewBar;              // Cờ đánh dấu nến mới
   
   // TÍNH NĂNG MỚI: Lazy Update cho multi-symbol backtest
   datetime             m_LastFullUpdateTime;    // Thời gian cập nhật đầy đủ cuối cùng
   bool                 m_UseLazyUpdate;         // Sử dụng lazy update
   int                  m_LazyUpdateInterval;    // Interval cho lazy update (số nến)
   
   // Biến trạng thái thị trường
   bool                 m_IsTrendUp;             // Cờ đánh dấu xu hướng tăng
   bool                 m_IsTrendDown;           // Cờ đánh dấu xu hướng giảm
   bool                 m_IsRangebound;          // Cờ đánh dấu thị trường sideway
   bool                 m_IsVolatile;            // Cờ đánh dấu thị trường biến động mạnh
   bool                 m_CurrentVolumeSpikeUp;   // Cờ đánh dấu volume tăng đột biến
   bool                 m_CurrentVolumeSpikeDown; // Cờ đánh dấu volume giảm đột biến
   bool                 m_IsVolumeWeakening;      // Cờ đánh dấu volume suy yếu
   
   // Ngưỡng phân tích
   double               m_VolatilityThreshold;   // Ngưỡng biến động cao
   double               m_RangeThreshold;        // Ngưỡng sideway
   double               m_ADX_StrongThreshold;   // Ngưỡng ADX cho xu hướng mạnh
   double               m_ADX_WeakThreshold;     // Ngưỡng ADX cho xu hướng yếu
   double               m_VolumeRatioThreshold;  // Ngưỡng tỷ lệ khối lượng
   
   // Ngưỡng phân tích Spike Bar (MỚI)
   double               m_SpikeBarBodyThreshold;    // Ngưỡng thân nến (so với ATR)
   double               m_SpikeBarVolumeThreshold;  // Ngưỡng volume (so với trung bình)
   int                  m_SpikeBarLookback;         // Số nến nhìn lại để tìm Spike Bar
   
   // Cấu hình phân tích nâng cao
   bool                 m_PrioritizeTrendOverVolatility; // Ưu tiên Trend hơn Volatility khi cả hai cùng có
   bool                 m_UseRelativeEMASlope;   // Sử dụng EMA slope dựa trên % thay vì khoảng cách tuyệt đối
   int                  m_DefaultATRLookback;    // Lookback mặc định cho phân tích ATR
   
   // EMA cache arrays cho tính toán hiệu suất cao
   double               m_EmaCache34[100];     // Lưu trữ giá trị EMA34 cho 100 nến
   double               m_EmaCache89[100];     // Lưu trữ giá trị EMA89 cho 100 nến
   double               m_EmaCache200[100];    // Lưu trữ giá trị EMA200 cho 100 nến
   int                  m_EmaCacheBars;        // Số nến thực tế đã cache
   
   //--- Phương thức private ---
   
   // Khởi tạo và quản lý indicator
   bool                 InitializeIndicators();
   void                 ReleaseIndicators();
   
   // Cập nhật dữ liệu
   bool                 UpdateIndicatorData();
   bool                 IsNewBar();
   void                 UpdateEMACaches();
   
   // Phân tích thị trường
   void                 AnalyzeMarketProfile();
   void                 AnalyzeTrendDirection();
   void                 AnalyzeVolatility();
   void                 AnalyzeVolume();
   void                 UpdateSwingPoints();
   
   // TÍNH NĂNG MỚI: Phân tích phiên giao dịch
   ENUM_TRADING_SESSION DetermineCurrentSession();
   void                 UpdateSessionParameters();
   string               GetSessionName(ENUM_TRADING_SESSION session);
   
   // TÍNH NĂNG MỚI: Phân tích Divergence
   void                 AnalyzeDivergence();
   bool                 DetectRegularBullishDivergence(int start, int depth);
   bool                 DetectRegularBearishDivergence(int start, int depth);
   bool                 DetectHiddenBullishDivergence(int start, int depth);
   bool                 DetectHiddenBearishDivergence(int start, int depth);
   
   // TÍNH NĂNG MỚI: Phát hiện Spike Bar
   void                 DetectSpikeBars();
   bool                 IsBarSpike(int barIndex, double &bodySize, double &volumeRatio);
   void                 AddSpikeBar(int barIndex, double bodySize, double volumeRatio, bool isBullish);
   
   // Phương thức truy cập indicator an toàn
   bool                 SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[]);
   bool                 SafeCopyRates(int startPos, int count, double &open[], double &high[], 
                                     double &low[], double &close[]);
   bool                 SafeCopyVolume(int startPos, int count, long &volume[]);
   
   // Phương thức phân tích swing points
   bool                 IsLocalTop(const double &high[], int index, int lookback = 2);
   bool                 IsLocalBottom(const double &low[], int index, int lookback = 2);
   bool                 BaseLocalTopCheck(const double &high[], int index, int lookback);
   bool                 BaseLocalBottomCheck(const double &low[], int index, int lookback);
   double               FindNearestLow(int startIndex, int lookbackBars);
   double               FindNearestHigh(int startIndex, int lookbackBars);
   
   // Phân tích nâng cao
   double               CalculateRelativeEMASlope(int emaPeriod, int bars);
   double               CalculateAbsoluteEMASlope(int emaPeriod, int bars);
   double               OriginalCalculateAbsoluteEMASlope(int emaPeriod, int bars);
   double               GetLatestSwingPointVolume(bool lookForHigh);
   
   // Phương thức thêm swing point mới đảm bảo đúng thứ tự và số lượng
   void                 AddSwingPoint(SwingPoint &newPoint);
   
   // Các methods phân tích lịch sử thị trường
   void                 UpdateMarketHistory();
   bool                 IsTransitioningToTrend();             // Đang chuyển từ sideway sang trend?
   bool                 IsTransitioningToRanging();           // Đang chuyển từ trend sang sideway?
   bool                 IsVolatilityIncreasing();             // Biến động đang tăng dần?
   bool                 IsVolatilityDecreasing();             // Biến động đang giảm dần?
   
public:
                        CMarketMonitor(void);
                       ~CMarketMonitor(void);
   
   // Khởi tạo
   bool                 Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int emaFast=34, int emaTrend=89,
                               bool useMultiTimeframe=false, ENUM_TIMEFRAMES higherTimeframe=PERIOD_H4,
                               bool useNestedTimeframe=false, ENUM_TIMEFRAMES nestedTimeframe=PERIOD_M15,
                               bool enableMarketRegimeFilter=true);
   
   // Cập nhật dữ liệu thị trường
   bool                 Update();
   void                 LightUpdate();  // Cập nhật nhẹ cho hiệu suất cao
   
   // TÍNH NĂNG MỚI: Lazy Update cho backtesting multi-symbol
   void                 EnableLazyUpdate(bool enable, int updateInterval=5);
   bool                 LazyUpdate();   // Cập nhật định kỳ cho khối lượng dữ liệu lớn
   
   // Getter cho các chỉ báo
   double               GetATR() const { return m_Cache.atr; }
   double               GetRSI() const { return m_Cache.rsi; }
   double               GetADX() const { return m_Cache.adx; }
   double               GetEma34() const { return m_Cache.ema34; }
   double               GetEma89() const { return m_Cache.ema89; }
   double               GetEma200() const { return m_Cache.ema200; }
   long                 GetVolume() const { return m_Cache.volume; }
   long                 GetAverageVolume() const { return m_Cache.avg_volume; }
   double               GetPlusDI() const { return m_Cache.adx_plus_di; }
   double               GetMinusDI() const { return m_Cache.adx_minus_di; }
   
   // Getter cho tình trạng thị trường
   ENUM_MARKET_PROFILE_TYPE GetMarketProfile() const { return m_MarketProfile; }
   ENUM_MARKET_STATE    GetMarketState() const { return m_MarketState; }
   bool                 IsTrendUp() const { return m_IsTrendUp; }
   bool                 IsTrendDown() const { return m_IsTrendDown; }
   bool                 IsRangebound() const { return m_IsRangebound; }
   bool                 IsVolatile() const { return m_IsVolatile; }
   
   // Getter cho volume spike và điều kiện
   bool                 IsVolumeSpikeUp() const;
   bool                 IsVolumeSpikeDown() const;
   bool                 IsVolumeWeakening() const;
   bool                 IsVolumeNearSwingHigh() const;  // Volume gần swing high
   bool                 IsVolumeNearSwingLow() const;   // Volume gần swing low
   
   // Getter cho phiên giao dịch
   ENUM_TRADING_SESSION GetCurrentSession() const { return m_CurrentSession; }
   string               GetCurrentSessionName() const;
   bool                 IsAsianSession() const { return m_CurrentSession == SESSION_ASIAN; }
   bool                 IsEuropeanSession() const { return m_CurrentSession == SESSION_EUROPEAN; }
   bool                 IsAmericanSession() const { return m_CurrentSession == SESSION_AMERICAN; }
   bool                 IsOverlapSession() const { return m_CurrentSession == SESSION_EUROPEAN_AMERICAN; }
   
   // Getter cho Divergence
   ENUM_DIVERGENCE_TYPE GetRSIDivergence() const { return m_Cache.rsiDivergence; }
   ENUM_DIVERGENCE_TYPE GetMACDDivergence() const { return m_Cache.macdDivergence; }
   bool                 HasBullishDivergence() const;
   bool                 HasBearishDivergence() const;
   string               GetDivergenceDescription(ENUM_DIVERGENCE_TYPE type);
   
   // Getter cho Spike Bars
   int                  GetSpikeBarCount() const { return m_SpikeBarCount; }
   bool                 GetLatestSpikeBar(SpikeBarInfo &info);
   bool                 HasRecentSpikeBar(int barsLookback) const;
   bool                 HasRecentBullishSpikeBar(int barsLookback) const;
   bool                 HasRecentBearishSpikeBar(int barsLookback) const;
   
   // Getter cho giá
   double               GetClose() const { return m_Cache.close; }
   double               GetOpen() const { return m_Cache.open; }
   double               GetHigh() const { return m_Cache.high; }
   double               GetLow() const { return m_Cache.low; }
   
   // Phân tích bổ sung
   double               CalculateEMASlope(int emaPeriod, int bars);
   double               CalculateATRRatio();
   bool                 IsATRExpanding(int lookback = 0);
   bool                 IsATRContracting(int lookback = 0);
   
   // Phân tích swing points
   SwingPoint           GetLatestSwingHigh();
   SwingPoint           GetLatestSwingLow();
   double               GetDistanceToSwingPoint(bool high);
   
   // Kiểm tra tín hiệu vào lệnh
   bool                 CheckEntrySignal(SignalInfo &signal);
   bool                 GetLastSignal(SignalInfo &signal);
   
   // Cài đặt tham số
   void                 SetADXThresholds(double weakThreshold, double strongThreshold);
   void                 SetVolatilityThreshold(double threshold);
   void                 SetRangeThreshold(double threshold);
   void                 SetVolumeRatioThreshold(double threshold);
   void                 SetDefaultATRLookback(int lookback);
   void                 SetPrioritizeTrendOverVolatility(bool prioritize);
   void                 SetUseRelativeEMASlope(bool useRelative);
   void                 SetEnvelopeDeviation(double deviation) { m_EnvelopeDeviation = deviation; }
   void                 SetGMTOffset(int offset) { m_GMTOffset = offset; }
   
   // TÍNH NĂNG MỚI: Cài đặt tham số cho Spike Bar Detection
   void                 SetSpikeBarParameters(double bodyThreshold, double volumeThreshold, int lookback);
   
   // Logger
   void                 SetLogger(CLogger* logger) { m_Logger = logger; }
   CLogger*             GetLogger() const { return m_Logger; }
   
   // TÍNH NĂNG MỚI V13: Multi-timeframe trend confirmation
   bool                 IsTrendUpHigher() const;
   bool                 IsTrendDownHigher() const;
   bool                 IsTrendUpNested() const;
   bool                 IsTrendDownNested() const;
   double               GetEMASlope() const { return CalculateEMASlope(34, 5); }
   
   // TÍNH NĂNG MỚI V13: Regime transition tracking
   double               GetRegimeTransitionScore();
   int                  GetConsecutiveRegimeConfirmations();
   bool                 IsRegimeTransitioning();
   
   // TÍNH NĂNG MỚI V13: Chandeliers Exit support
   double               CalculateChandelierExitLevel(bool isLong, int lookback, double atrMultiplier);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketMonitor::CMarketMonitor(void)
{
   // Khởi tạo các thuộc tính với giá trị mặc định
   m_Symbol = "";
   m_Timeframe = PERIOD_H1;
   m_IsInitialized = false;
   
   // Khởi tạo handle của các indicator
   m_HandleEMA34 = INVALID_HANDLE;
   m_HandleEMA89 = INVALID_HANDLE;
   m_HandleEMA200 = INVALID_HANDLE;
   m_HandleRSI = INVALID_HANDLE;
   m_HandleMACD = INVALID_HANDLE;
   m_HandleBB = INVALID_HANDLE;
   m_HandleADX = INVALID_HANDLE;
   m_HandleATR = INVALID_HANDLE;
   
   // Khởi tạo đa khung thời gian
   m_UseMultiTimeframe = false;
   m_HigherTimeframe = PERIOD_H4;
   m_UseNestedTimeframe = false;
   m_NestedTimeframe = PERIOD_M15;
   
   // Khởi tạo chu kỳ chỉ báo mặc định
   m_RSI_Period = 14;
   m_ADX_Period = 14;
   m_ATR_Period = 14;
   
   // Khởi tạo các ngưỡng phân tích
   m_VolatilityThreshold = 1.5;      // Ngưỡng biến động cao (150% so với thông thường)
   m_RangeThreshold = 0.3;           // Ngưỡng sideway (30% của trung bình)
   m_ADX_StrongThreshold = 30.0;     // Ngưỡng ADX cho xu hướng mạnh
   m_ADX_WeakThreshold = 20.0;       // Ngưỡng ADX cho xu hướng yếu
   m_VolumeRatioThreshold = 1.5;     // Khối lượng lớn hơn 150% trung bình
   
   // Khởi tạo các tham số SpikeBar
   m_SpikeBarBodyThreshold = 2.0;    // Thân nến lớn hơn 2x ATR
   m_SpikeBarVolumeThreshold = 2.0;  // Volume lớn hơn 2x trung bình
   m_SpikeBarLookback = 20;          // Nhìn lại 20 nến để tìm spike bar
   m_SpikeBarCount = 0;              // Số lượng spike bar đã tìm được
   
   // Khởi tạo trạng thái thị trường
   m_MarketProfile = MARKET_PROFILE_UNKNOWN;
   m_MarketState = MARKET_STATE_UNKNOWN;
   m_IsTrendUp = false;
   m_IsTrendDown = false;
   m_IsRangebound = false;
   m_IsVolatile = false;
   m_CurrentVolumeSpikeUp = false;
   m_CurrentVolumeSpikeDown = false;
   m_IsVolumeWeakening = false;
   
   // Khởi tạo biến theo dõi cập nhật
   m_LastUpdateTime = 0;
   m_IsNewBar = false;
   
   // Khởi tạo Lazy Update
   m_UseLazyUpdate = false;
   m_LazyUpdateInterval = 5;
   m_LastFullUpdateTime = 0;
   
   // Khởi tạo cấu hình nâng cao
   m_PrioritizeTrendOverVolatility = true;  // Mặc định ưu tiên xu hướng mạnh hơn biến động
   m_UseRelativeEMASlope = true;            // Mặc định sử dụng độ dốc tương đối (%)
   m_DefaultATRLookback = 5;                // Lookback mặc định cho ATR là 5 nến
   
   // Khởi tạo thông số envelope
   m_EnvelopeDeviation = 0.1;              // Envelope deviation mặc định 0.1%
   m_EnableMarketRegimeFilter = true;       // Bật lọc chế độ thị trường mặc định
   
   // Khởi tạo phiên giao dịch
   m_CurrentSession = SESSION_UNKNOWN;
   m_LastSessionCheckTime = 0;
   m_GMTOffset = 3;                        // Múi giờ GMT+3 mặc định (điều chỉnh theo môi trường)
   
   // Khởi tạo swing points
   m_SwingCount = 0;
   
   // Khởi tạo cache EMA
   m_EmaCacheBars = 0;
   ArrayInitialize(m_EmaCache34, 0);
   ArrayInitialize(m_EmaCache89, 0);
   ArrayInitialize(m_EmaCache200, 0);
   
   // Khởi tạo đối tượng logger
   m_Logger = NULL;
   
   // Khởi tạo circular buffer cho lịch sử thị trường
   m_MarketHistory.currentIndex = 0;
   
   // Reset cấu trúc dữ liệu cache
   ZeroMemory(m_Cache);
   
   // Reset thông tin tín hiệu mới nhất
   ZeroMemory(m_LastSignal);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketMonitor::~CMarketMonitor(void)
{
   // Giải phóng handle của các indicator
   ReleaseIndicators();
}

//+------------------------------------------------------------------+
//| Khởi tạo MarketMonitor với symbol và timeframe                   |
//+------------------------------------------------------------------+
bool CMarketMonitor::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int emaFast, int emaTrend,
                            bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe,
                            bool useNestedTimeframe, ENUM_TIMEFRAMES nestedTimeframe,
                            bool enableMarketRegimeFilter)
{
   // Lưu thông tin cơ bản
   m_Symbol = symbol;
   m_Timeframe = timeframe;
   
   // Lưu cấu hình đa khung thời gian
   m_UseMultiTimeframe = useMultiTimeframe;
   m_HigherTimeframe = higherTimeframe;
   m_UseNestedTimeframe = useNestedTimeframe;
   m_NestedTimeframe = nestedTimeframe;
   
   // Bật/tắt lọc chế độ thị trường
   m_EnableMarketRegimeFilter = enableMarketRegimeFilter;
   
   // Khởi tạo các indicator
   if (!InitializeIndicators()) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo các indicator");
      return false;
   }
   
   // Cập nhật dữ liệu ban đầu
   if (!UpdateIndicatorData()) {
      if(m_Logger) m_Logger.LogWarning("Cập nhật dữ liệu thị trường ban đầu thất bại - sẽ thử lại ở tick tiếp theo");
      // Tiếp tục khởi tạo ngay cả khi cập nhật đầu tiên thất bại
   }
   
   // Xác định phiên giao dịch hiện tại
   m_CurrentSession = DetermineCurrentSession();
   
   // Đánh dấu đã khởi tạo thành công
   m_IsInitialized = true;
   
   // Ghi log thông tin khởi tạo
   if(m_Logger) {
      m_Logger.LogInfo(StringFormat(
         "MarketMonitor đã khởi tạo cho %s trên khung %s", 
         m_Symbol, 
         EnumToString(m_Timeframe)
      ));
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Khởi tạo tất cả các indicator cần thiết                          |
//+------------------------------------------------------------------+
bool CMarketMonitor::InitializeIndicators()
{
   // Giải phóng handle cũ nếu có
   ReleaseIndicators();
   
   // Khởi tạo các chỉ báo EMA
   m_HandleEMA34 = iMA(m_Symbol, m_Timeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA34 == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo EMA 34: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA89 = iMA(m_Symbol, m_Timeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA89 == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo EMA 89: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA200 = iMA(m_Symbol, m_Timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA200 == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo EMA 200: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo RSI
   m_HandleRSI = iRSI(m_Symbol, m_Timeframe, m_RSI_Period, PRICE_CLOSE);
   if (m_HandleRSI == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo RSI: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo MACD
   m_HandleMACD = iMACD(m_Symbol, m_Timeframe, 12, 26, 9, PRICE_CLOSE);
   if (m_HandleMACD == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo MACD: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo Bollinger Bands
   m_HandleBB = iBands(m_Symbol, m_Timeframe, 20, 0, 2, PRICE_CLOSE);
   if (m_HandleBB == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo Bollinger Bands: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo ADX
   m_HandleADX = iADX(m_Symbol, m_Timeframe, m_ADX_Period);
   if (m_HandleADX == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo ADX: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo ATR
   m_HandleATR = iATR(m_Symbol, m_Timeframe, m_ATR_Period);
   if (m_HandleATR == INVALID_HANDLE) {
      if(m_Logger) m_Logger.LogError("Không thể khởi tạo ATR: " + IntegerToString(GetLastError()));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Giải phóng tất cả handle indicator                              |
//+------------------------------------------------------------------+
void CMarketMonitor::ReleaseIndicators()
{
   // Giải phóng các handle EMA
   if (m_HandleEMA34 != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA34);
      m_HandleEMA34 = INVALID_HANDLE;
   }
   
   if (m_HandleEMA89 != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA89);
      m_HandleEMA89 = INVALID_HANDLE;
   }
   
   if (m_HandleEMA200 != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA200);
      m_HandleEMA200 = INVALID_HANDLE;
   }
   
   // Giải phóng RSI
   if (m_HandleRSI != INVALID_HANDLE) {
      IndicatorRelease(m_HandleRSI);
      m_HandleRSI = INVALID_HANDLE;
   }
   
   // Giải phóng MACD
   if (m_HandleMACD != INVALID_HANDLE) {
      IndicatorRelease(m_HandleMACD);
      m_HandleMACD = INVALID_HANDLE;
   }
   
   // Giải phóng Bollinger Bands
   if (m_HandleBB != INVALID_HANDLE) {
      IndicatorRelease(m_HandleBB);
      m_HandleBB = INVALID_HANDLE;
   }
   
   // Giải phóng ADX
   if (m_HandleADX != INVALID_HANDLE) {
      IndicatorRelease(m_HandleADX);
      m_HandleADX = INVALID_HANDLE;
   }
   
   // Giải phóng ATR
   if (m_HandleATR != INVALID_HANDLE) {
      IndicatorRelease(m_HandleATR);
      m_HandleATR = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu một nến mới đã hình thành                          |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(m_Symbol, m_Timeframe, 0);
   
   if (currentBarTime > lastBarTime) {
      lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Cập nhật dữ liệu indicator an toàn                              |
//+------------------------------------------------------------------+
bool CMarketMonitor::UpdateIndicatorData()
{
   // Chỉ cập nhật khi có nến mới hoặc lần gọi đầu tiên
   m_IsNewBar = IsNewBar() || m_LastUpdateTime == 0;
   
   if (!m_IsNewBar && m_LastUpdateTime > 0) {
      // Không cần cập nhật ở mỗi tick, sử dụng giá trị đã lưu trong cache
      return true;
   }
   
   // Lưu giá trị RSI trước khi cập nhật để sử dụng so sánh sau này
   m_Cache.rsi_prev = m_Cache.rsi;
   
   // Cập nhật dữ liệu giá
   double open[], high[], low[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if (!SafeCopyRates(0, 100, open, high, low, close)) {
      if(m_Logger) m_Logger.LogError("Không thể sao chép dữ liệu giá: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Cập nhật cache giá
   m_Cache.close = close[0];
   m_Cache.open = open[0];
   m_Cache.high = high[0];
   m_Cache.low = low[0];
   m_Cache.prev_close = close[1];
   
   // Cập nhật dữ liệu volume
   long volume[];
   ArraySetAsSeries(volume, true);
   
   if (SafeCopyVolume(0, 100, volume)) {
      m_Cache.volume = volume[0];
      
      // Tính toán volume trung bình 20 nến
      long volSum = 0;
      int validBars = 0;
      
      for (int i = 0; i < 20 && i < ArraySize(volume); i++) {
         if (volume[i] > 0) {
            volSum += volume[i];
            validBars++;
         }
      }
      
      m_Cache.avg_volume = (validBars > 0) ? (volSum / validBars) : 1;
      
      // Cập nhật swing points cho phân tích volume nâng cao
      if (m_IsNewBar) {
         // Tìm kiếm các swing points từ dữ liệu giá
         for (int i = 5; i < 50; i++) {
            if (IsLocalTop(high, i, 3) && m_SwingCount < 10) {
               // Lưu thông tin swing high
               m_RecentSwings[m_SwingCount].price = high[i];
               m_RecentSwings[m_SwingCount].barIndex = i;
               m_RecentSwings[m_SwingCount].isHigh = true;
               m_RecentSwings[m_SwingCount].volume = volume[i];
               m_RecentSwings[m_SwingCount].time = iTime(m_Symbol, m_Timeframe, i);
               m_SwingCount++;
            }
            else if (IsLocalBottom(low, i, 3) && m_SwingCount < 10) {
               // Lưu thông tin swing low
               m_RecentSwings[m_SwingCount].price = low[i];
               m_RecentSwings[m_SwingCount].barIndex = i;
               m_RecentSwings[m_SwingCount].isHigh = false;
               m_RecentSwings[m_SwingCount].volume = volume[i];
               m_RecentSwings[m_SwingCount].time = iTime(m_Symbol, m_Timeframe, i);
               m_SwingCount++;
            }
            
            // Dừng nếu đã tìm đủ 10 swing points
            if (m_SwingCount >= 10) break;
         }
      }
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể sao chép dữ liệu volume: " + IntegerToString(GetLastError()));
      // Không return false ở đây để vẫn đọc được các chỉ báo khác
   }
   
   // Cập nhật thời gian
   TimeToStruct(TimeCurrent(), m_Cache.time);
   
   // Cập nhật các chỉ báo từ handle
   double buffer[];
   ArraySetAsSeries(buffer, true);
   
   // EMA 34
   if (SafeCopyBuffer(m_HandleEMA34, 0, 0, 1, buffer)) {
      m_Cache.ema34 = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật EMA 34: " + IntegerToString(GetLastError()));
   }
   
   // EMA 89
   if (SafeCopyBuffer(m_HandleEMA89, 0, 0, 1, buffer)) {
      m_Cache.ema89 = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật EMA 89: " + IntegerToString(GetLastError()));
   }
   
   // EMA 200
   if (SafeCopyBuffer(m_HandleEMA200, 0, 0, 1, buffer)) {
      m_Cache.ema200 = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật EMA 200: " + IntegerToString(GetLastError()));
   }
   
   // RSI
   if (SafeCopyBuffer(m_HandleRSI, 0, 0, 1, buffer)) {
      m_Cache.rsi = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật RSI: " + IntegerToString(GetLastError()));
   }
   
   // MACD (Main line)
   if (SafeCopyBuffer(m_HandleMACD, 0, 0, 1, buffer)) {
      m_Cache.macd = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật MACD (Main): " + IntegerToString(GetLastError()));
   }
   
   // MACD (Signal line)
   if (SafeCopyBuffer(m_HandleMACD, 1, 0, 1, buffer)) {
      m_Cache.macd_signal = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật MACD (Signal): " + IntegerToString(GetLastError()));
   }
   
   // ADX (Main line)
   if (SafeCopyBuffer(m_HandleADX, 0, 0, 1, buffer)) {
      m_Cache.adx = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật ADX: " + IntegerToString(GetLastError()));
   }
   
   // ADX (+DI line)
   if (SafeCopyBuffer(m_HandleADX, 1, 0, 1, buffer)) {
      m_Cache.adx_plus_di = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật ADX +DI: " + IntegerToString(GetLastError()));
   }
   
   // ADX (-DI line)
   if (SafeCopyBuffer(m_HandleADX, 2, 0, 1, buffer)) {
      m_Cache.adx_minus_di = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật ADX -DI: " + IntegerToString(GetLastError()));
   }
   
   // ATR
   if (SafeCopyBuffer(m_HandleATR, 0, 0, 20, buffer)) {
      m_Cache.atr = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật ATR: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Upper)
   if (SafeCopyBuffer(m_HandleBB, 1, 0, 1, buffer)) {
      m_Cache.bb_upper = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật Bollinger Upper: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Middle)
   if (SafeCopyBuffer(m_HandleBB, 0, 0, 1, buffer)) {
      m_Cache.bb_middle = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật Bollinger Middle: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Lower)
   if (SafeCopyBuffer(m_HandleBB, 2, 0, 1, buffer)) {
      m_Cache.bb_lower = buffer[0];
   } else {
      if(m_Logger) m_Logger.LogError("Không thể cập nhật Bollinger Lower: " + IntegerToString(GetLastError()));
   }
   
   // Cập nhật thời gian lần đọc cuối cùng
   m_LastUpdateTime = TimeCurrent();
   
   return true;
}

//+------------------------------------------------------------------+
//| Sao chép an toàn dữ liệu từ buffer indicator                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[])
{
   // Kiểm tra handle có hợp lệ không
   if (handle == INVALID_HANDLE) {
      return false;
   }
   
   // Điều chỉnh kích thước mảng để tránh tràn bộ đệm
   ArrayResize(array, count);
   
   // Thử sao chép với một lần thử lại nếu thất bại
   int copied = CopyBuffer(handle, buffer, startPos, count, array);
   if (copied <= 0) {
      // Lần thử đầu tiên thất bại, reset lỗi và thử lại
      ResetLastError();
      Sleep(5);  // Trì hoãn nhỏ
      copied = CopyBuffer(handle, buffer, startPos, count, array);
   }
   
   return (copied == count);
}

//+------------------------------------------------------------------+
//| Sao chép an toàn dữ liệu giá                                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyRates(int startPos, int count, double &open[], double &high[], 
                                 double &low[], double &close[])
{
   // Điều chỉnh kích thước các mảng để tránh tràn bộ đệm
   ArrayResize(open, count);
   ArrayResize(high, count);
   ArrayResize(low, count);
   ArrayResize(close, count);
   
   // Thử sao chép dữ liệu giá với một lần thử lại
   int copied = 0;
   
   copied = CopyOpen(m_Symbol, m_Timeframe, startPos, count, open);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyOpen(m_Symbol, m_Timeframe, startPos, count, open);
      if (copied <= 0) return false;
   }
   
   copied = CopyHigh(m_Symbol, m_Timeframe, startPos, count, high);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyHigh(m_Symbol, m_Timeframe, startPos, count, high);
      if (copied <= 0) return false;
   }
   
   copied = CopyLow(m_Symbol, m_Timeframe, startPos, count, low);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyLow(m_Symbol, m_Timeframe, startPos, count, low);
      if (copied <= 0) return false;
   }
   
   copied = CopyClose(m_Symbol, m_Timeframe, startPos, count, close);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyClose(m_Symbol, m_Timeframe, startPos, count, close);
      if (copied <= 0) return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Sao chép an toàn dữ liệu volume                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyVolume(int startPos, int count, long &volume[])
{
   // Điều chỉnh kích thước mảng để tránh tràn bộ đệm
   ArrayResize(volume, count);
   
   // Thử sao chép dữ liệu volume với một lần thử lại
   int copied = CopyTickVolume(m_Symbol, m_Timeframe, startPos, count, volume);
   if (copied <= 0) {
      // Lần thử đầu tiên thất bại, reset lỗi và thử lại
      ResetLastError();
      Sleep(5);  // Trì hoãn nhỏ
      copied = CopyTickVolume(m_Symbol, m_Timeframe, startPos, count, volume);
   }
   
   return (copied == count);
}

//+------------------------------------------------------------------+
//| Phương thức cập nhật chính - cập nhật tất cả dữ liệu và phân tích|
//+------------------------------------------------------------------+
bool CMarketMonitor::Update()
{
   if (!m_IsInitialized) {
      if(m_Logger) m_Logger.LogError("MarketMonitor chưa được khởi tạo");
      return false;
   }
   
   // Cập nhật dữ liệu indicator
   if (!UpdateIndicatorData()) {
      if(m_Logger) m_Logger.LogWarning("Không thể cập nhật dữ liệu indicator");
      return false;
   }
   
   // Cập nhật cache EMA
   UpdateEMACaches();
   
   // Xác định phiên giao dịch hiện tại
   m_CurrentSession = DetermineCurrentSession();
   
   // Chỉ phân tích thị trường khi có nến mới hoặc lần gọi đầu tiên
   if (m_IsNewBar || m_MarketProfile == MARKET_PROFILE_UNKNOWN) {
      // Phân tích profile thị trường
      AnalyzeMarketProfile();
      
      // Phân tích hướng xu hướng
      AnalyzeTrendDirection();
      
      // Phân tích biến động
      AnalyzeVolatility();
      
      // Phân tích khối lượng
      AnalyzeVolume();
      
      // Cập nhật Swing Points
      UpdateSwingPoints();
      
      // TÍNH NĂNG MỚI: Phân tích Divergence
      AnalyzeDivergence();
      
      // TÍNH NĂNG MỚI: Phát hiện Spike Bar
      DetectSpikeBars();
      
      // Cập nhật lịch sử thị trường
      UpdateMarketHistory();
      
      // Ghi log trạng thái thị trường nếu được bật debug
      if (m_Logger && m_Logger.IsDebugEnabled()) {
         string profileDesc = "";
         switch(m_MarketProfile) {
            case MARKET_PROFILE_STRONG_TREND: profileDesc = "Xu hướng mạnh"; break;
            case MARKET_PROFILE_WEAK_TREND:   profileDesc = "Xu hướng yếu";   break;
            case MARKET_PROFILE_RANGING:      profileDesc = "Sideway";      break;
            case MARKET_PROFILE_VOLATILE:     profileDesc = "Biến động mạnh";     break;
            case MARKET_PROFILE_ACCUMULATION: profileDesc = "Tích lũy"; break;
            case MARKET_PROFILE_DISTRIBUTION: profileDesc = "Phân phối"; break;
            default: profileDesc = "Không xác định";
         }
         
         string trend = m_IsTrendUp ? "Lên" : (m_IsTrendDown ? "Xuống" : "Đi ngang");
         string sessionName = GetSessionName(m_CurrentSession);
         
         // Thêm thông tin về phiên giao dịch vào log
         m_Logger.LogDebug(StringFormat("[%s] Trạng thái thị trường: %s, Xu hướng: %s, ATR: %.5f, RSI: %.1f, ADX: %.1f, Phiên: %s", 
                                     m_Symbol, profileDesc, trend, m_Cache.atr, m_Cache.rsi, m_Cache.adx, sessionName));
                                     
         // Thêm thông tin Divergence nếu có
         if (m_Cache.rsiDivergence != DIVERGENCE_NONE || m_Cache.macdDivergence != DIVERGENCE_NONE) {
            m_Logger.LogDebug(StringFormat("Divergence: RSI: %s, MACD: %s", 
                                       GetDivergenceDescription(m_Cache.rsiDivergence),
                                       GetDivergenceDescription(m_Cache.macdDivergence)));
         }
      }
   }
   
   // Cập nhật các tham số phụ thuộc vào phiên
   UpdateSessionParameters();
   
   return true;
}

//+------------------------------------------------------------------+
//| Cập nhật nhẹ cho hiệu suất cao                                  |
//+------------------------------------------------------------------+
void CMarketMonitor::LightUpdate()
{
   // Cập nhật nhanh giá mới nhất mà không recalculate các indicator
   double bid = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
   
   // Cập nhật cache giá hiện tại
   m_Cache.close = bid;  // Sử dụng giá bid cho giá đóng cửa hiện tại
   
   // Cập nhật giá cao/thấp hiện tại nếu vượt qua giá đã lưu
   if (ask > m_Cache.high) m_Cache.high = ask;
   if (bid < m_Cache.low) m_Cache.low = bid;
   
   // Cập nhật volume hiện tại (tùy chọn)
   // Lưu ý: Điều này có thể tốn thời gian xử lý, chỉ sử dụng nếu cần thiết
   /*
   long currentVolume = 0;
   if (SymbolInfoInteger(m_Symbol, SYMBOL_VOLUME, currentVolume)) {
       m_Cache.volume = currentVolume;
   }
   */
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lazy Update cho backtesting multi-symbol         |
//+------------------------------------------------------------------+
void CMarketMonitor::EnableLazyUpdate(bool enable, int updateInterval)
{
   m_UseLazyUpdate = enable;
   m_LazyUpdateInterval = MathMax(1, updateInterval);
   
   if(m_Logger) {
      m_Logger.LogInfo(StringFormat("Lazy Update %s, interval: %d nến", 
                               enable ? "bật" : "tắt", 
                               m_LazyUpdateInterval));
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lazy Update cho backtesting multi-symbol         |
//+------------------------------------------------------------------+
bool CMarketMonitor::LazyUpdate()
{
   // Nếu Lazy Update không được bật, sử dụng cập nhật thông thường
   if (!m_UseLazyUpdate) {
      return Update();
   }
   
   // Kiểm tra nếu có nến mới
   if (!IsNewBar()) {
      // Chỉ cập nhật giá hiện tại
      LightUpdate();
      return true;
   }
   
   // Đếm số nến kể từ lần cập nhật đầy đủ cuối cùng
   int barsSinceLastUpdate = 0;
   if (m_LastFullUpdateTime > 0) {
      datetime currentBarTime = iTime(m_Symbol, m_Timeframe, 0);
      datetime lastUpdateBarTime = m_LastFullUpdateTime;
      
      // Tìm vị trí của nến cũ
      for (int i = 1; i < 1000; i++) {
         datetime barTime = iTime(m_Symbol, m_Timeframe, i);
         if (barTime <= lastUpdateBarTime) {
            barsSinceLastUpdate = i;
            break;
         }
         if (barTime == 0) break; // Không đủ dữ liệu
      }
   }
   
   // Nếu số nến vượt quá interval hoặc đây là lần cập nhật đầu tiên
   if (m_LastFullUpdateTime == 0 || barsSinceLastUpdate >= m_LazyUpdateInterval) {
      // Cập nhật đầy đủ
      bool result = Update();
      if (result) {
         m_LastFullUpdateTime = iTime(m_Symbol, m_Timeframe, 0);
      }
      return result;
   }
   
   // Cập nhật nhẹ
   LightUpdate();
   return true;
}

//+------------------------------------------------------------------+
//| Cập nhật cache EMA Arrays                                        |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateEMACaches()
{
   // Chỉ cập nhật khi có nến mới
   if (!m_IsNewBar) return;
   
   // Đảm bảo mảng đủ lớn
   ArrayResize(m_EmaCache34, 100);
   ArrayResize(m_EmaCache89, 100);
   ArrayResize(m_EmaCache200, 100);
   
   // Thiết lập chuỗi giảm dần
   ArraySetAsSeries(m_EmaCache34, true);
   ArraySetAsSeries(m_EmaCache89, true);
   ArraySetAsSeries(m_EmaCache200, true);
   
   // Copy dữ liệu EMA vào cache
   if (SafeCopyBuffer(m_HandleEMA34, 0, 0, 100, m_EmaCache34)) {
      if (SafeCopyBuffer(m_HandleEMA89, 0, 0, 100, m_EmaCache89)) {
         if (SafeCopyBuffer(m_HandleEMA200, 0, 0, 100, m_EmaCache200)) {
            m_EmaCacheBars = 100;
            if(m_Logger && m_Logger.IsDebugEnabled()) {
               m_Logger.LogDebug("EMA caches được cập nhật thành công");
            }
            return;
         }
      }
   }
   
   // Nếu không thể copy đủ 100 nến, thử với ít nến hơn
   if (SafeCopyBuffer(m_HandleEMA34, 0, 0, 50, m_EmaCache34)) {
      if (SafeCopyBuffer(m_HandleEMA89, 0, 0, 50, m_EmaCache89)) {
         if (SafeCopyBuffer(m_HandleEMA200, 0, 0, 50, m_EmaCache200)) {
            m_EmaCacheBars = 50;
            if(m_Logger && m_Logger.IsDebugEnabled()) {
               m_Logger.LogDebug("EMA caches được cập nhật thành công (50 nến)");
            }
            return;
         }
      }
   }
   
   m_EmaCacheBars = 0;
   if(m_Logger) m_Logger.LogWarning("Không thể cập nhật EMA caches");
}

//+------------------------------------------------------------------+
//| Phân tích profile thị trường                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeMarketProfile()
{
   // Mặc định là không xác định
   m_MarketProfile = MARKET_PROFILE_UNKNOWN;
   
   // Lấy các giá trị để phân tích
   double adx = m_Cache.adx;
   double atr = m_Cache.atr;
   double ema34 = m_Cache.ema34;
   double ema89 = m_Cache.ema89;
   double ema200 = m_Cache.ema200;
   double rsi = m_Cache.rsi;
   
   // Tính độ rộng Bollinger Band để đánh giá biến động
   double bbWidth = (m_Cache.bb_upper - m_Cache.bb_lower) / m_Cache.bb_middle;
   
   // Tính độ dốc của EMA34
   double emaSlope = m_UseRelativeEMASlope ? 
                     CalculateRelativeEMASlope(34, 5) : 
                     CalculateAbsoluteEMASlope(34, 5);
   
   // Phát hiện điều kiện xu hướng mạnh
   bool hasStrongTrend = (adx > m_ADX_StrongThreshold) && 
                         ((m_Cache.adx_plus_di > m_Cache.adx_minus_di && m_Cache.close > ema34) || 
                          (m_Cache.adx_minus_di > m_Cache.adx_plus_di && m_Cache.close < ema34));
   
   // Phát hiện điều kiện biến động cao
   bool hasHighVolatility = (bbWidth > m_VolatilityThreshold) || IsATRExpanding();
   
   // TÍNH NĂNG MỚI: Điều chỉnh phân tích theo phiên giao dịch
   if (m_CurrentSession == SESSION_ASIAN) {
      // Phiên Á thường có biến động thấp, nâng ngưỡng sideway
      m_RangeThreshold *= 1.2; 
      // Giảm ngưỡng xu hướng do khối lượng thấp
      m_ADX_StrongThreshold = 32.0;
      m_ADX_WeakThreshold = 22.0;
   } 
   else if (m_CurrentSession == SESSION_EUROPEAN || m_CurrentSession == SESSION_AMERICAN) {
      // Phiên Âu/Mỹ thường có xu hướng rõ rệt, giảm ngưỡng xu hướng
      m_ADX_StrongThreshold = 28.0;
      m_ADX_WeakThreshold = 19.0;
   } 
   else if (m_CurrentSession == SESSION_EUROPEAN_AMERICAN) {
      // Phiên overlap thường biến động mạnh, giảm ngưỡng volatility
      m_VolatilityThreshold *= 0.9;
      // Giảm ngưỡng xu hướng do khối lượng cao
      m_ADX_StrongThreshold = 26.0;
      m_ADX_WeakThreshold = 18.0;
   }
   
   // Cải tiến: Xác định ưu tiên xu hướng mạnh hơn biến động cao nếu được cấu hình
   if (hasStrongTrend && hasHighVolatility) {
      if (m_PrioritizeTrendOverVolatility) {
         m_MarketProfile = MARKET_PROFILE_STRONG_TREND;
      } else {
         m_MarketProfile = MARKET_PROFILE_VOLATILE;
      }
   }
   else if (hasStrongTrend) {
      m_MarketProfile = MARKET_PROFILE_STRONG_TREND;
   }
   else if (adx > m_ADX_WeakThreshold) {
      // Xu hướng yếu
      m_MarketProfile = MARKET_PROFILE_WEAK_TREND;
   }
   else if (hasHighVolatility) {
      m_MarketProfile = MARKET_PROFILE_VOLATILE;
   }
   // Kiểm tra thị trường sideway
   else if (bbWidth < m_RangeThreshold || IsATRContracting()) {
      // Kiểm tra thêm các điều kiện sideway
      bool isEmaFlat = MathAbs(emaSlope) < 0.0001; // EMA gần như đi ngang
      
      if (isEmaFlat || (adx < m_ADX_WeakThreshold)) {
         // Kiểm tra nếu là tích lũy hay phân phối
         if (rsi < 40 && m_Cache.volume > m_Cache.avg_volume) {
            m_MarketProfile = MARKET_PROFILE_ACCUMULATION; // Tích lũy
         }
         else if (rsi > 60 && m_Cache.volume > m_Cache.avg_volume) {
            m_MarketProfile = MARKET_PROFILE_DISTRIBUTION; // Phân phối
         }
         else {
            m_MarketProfile = MARKET_PROFILE_RANGING; // Sideway thông thường
         }
      }
   }
   
   // Nếu vẫn chưa xác định được, đặt mặc định là Ranging
   if (m_MarketProfile == MARKET_PROFILE_UNKNOWN) {
      m_MarketProfile = MARKET_PROFILE_RANGING;
   }
   
   // Khôi phục lại các ngưỡng ban đầu sau khi điều chỉnh theo phiên
   m_RangeThreshold = 0.3;
   m_ADX_StrongThreshold = 30.0;
   m_ADX_WeakThreshold = 20.0;
   m_VolatilityThreshold = 1.5;
}

//+------------------------------------------------------------------+
//| Phân tích hướng xu hướng thị trường                             |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeTrendDirection()
{
   // Đọc giá trị EMA từ cache
   double ema34 = m_Cache.ema34;
   double ema89 = m_Cache.ema89;
   double ema200 = m_Cache.ema200;
   double currentClose = m_Cache.close;
   
   // Reset các cờ xu hướng
   m_IsTrendUp = false;
   m_IsTrendDown = false;
   
   // Tiêu chí xác định xu hướng tăng
   if (ema34 > ema89 && ema89 > ema200) {
      // Kiểm tra thêm vị trí giá so với EMA
      if (currentClose > ema34) {
         m_IsTrendUp = true;
      }
      else if (currentClose > ema89) {
         // Giá trên EMA89 nhưng dưới EMA34 - xu hướng tăng nhưng đang pullback
         m_IsTrendUp = true;
      }
   }
   
   // Tiêu chí xác định xu hướng giảm
   if (ema34 < ema89 && ema89 < ema200) {
      // Kiểm tra thêm vị trí giá so với EMA
      if (currentClose < ema34) {
         m_IsTrendDown = true;
      }
      else if (currentClose < ema89) {
         // Giá dưới EMA89 nhưng trên EMA34 - xu hướng giảm nhưng đang pullback
         m_IsTrendDown = true;
      }
   }
   
   // Kiểm tra các dấu hiệu xu hướng bổ sung
   double plusDI = m_Cache.adx_plus_di;
   double minusDI = m_Cache.adx_minus_di;
   
   // Nếu +DI và -DI có khác biệt rõ rệt, xác nhận xu hướng
   if (plusDI > minusDI * 1.5) {
      m_IsTrendUp = true;
   }
   else if (minusDI > plusDI * 1.5) {
      m_IsTrendDown = true;
   }
   
   // Kiểm tra độ dốc EMA
   double emaSlope = CalculateEMASlope(34, 5);
   if (emaSlope > 0.001) {
      m_IsTrendUp = true;
   }
   else if (emaSlope < -0.001) {
      m_IsTrendDown = true;
   }
   
   // TÍNH NĂNG MỚI: Sử dụng Divergence để xác nhận hoặc cảnh báo đảo chiều
   if (m_Cache.rsiDivergence == DIVERGENCE_REGULAR_BULLISH || 
       m_Cache.macdDivergence == DIVERGENCE_REGULAR_BULLISH) {
      
      // Bearish trend có thể sắp kết thúc
      if (m_IsTrendDown) {
         // Nếu phát hiện divergence ngược với xu hướng, giảm độ tin cậy của xu hướng
         m_IsTrendDown = m_Cache.adx > m_ADX_StrongThreshold && minusDI > plusDI * 1.8;
      }
   }
   else if (m_Cache.rsiDivergence == DIVERGENCE_REGULAR_BEARISH || 
            m_Cache.macdDivergence == DIVERGENCE_REGULAR_BEARISH) {
            
      // Bullish trend có thể sắp kết thúc
      if (m_IsTrendUp) {
         // Nếu phát hiện divergence ngược với xu hướng, giảm độ tin cậy của xu hướng
         m_IsTrendUp = m_Cache.adx > m_ADX_StrongThreshold && plusDI > minusDI * 1.8;
      }
   }
}

//+------------------------------------------------------------------+
//| Phân tích biến động thị trường                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeVolatility()
{
   // Đặt lại cờ biến động
   m_IsVolatile = false;
   
   // Lấy dữ liệu ATR
   double atr = m_Cache.atr;
   
   // Tính tỷ lệ ATR so với trung bình
   double atrRatio = CalculateATRRatio();
   
   // TÍNH NĂNG MỚI: Điều chỉnh ngưỡng biến động theo phiên giao dịch
   double volatilityThreshold = m_VolatilityThreshold;
   
   switch (m_CurrentSession) {
      case SESSION_ASIAN:
         // Phiên Á thường có biến động thấp
         volatilityThreshold *= 1.2; // Ngưỡng cao hơn vì bình thường ít biến động
         break;
      case SESSION_EUROPEAN:
         // Phiên Âu biến động trung bình
         volatilityThreshold *= 1.0; // Giữ nguyên
         break;
      case SESSION_AMERICAN:
         // Phiên Mỹ biến động cao
         volatilityThreshold *= 0.9; // Giảm ngưỡng do biến động cao
         break;
      case SESSION_EUROPEAN_AMERICAN:
         // Phiên overlap biến động rất cao
         volatilityThreshold *= 0.8; // Giảm ngưỡng nhiều do biến động rất cao
         break;
      default:
         // Giữ nguyên
         break;
   }
   
   // Thị trường biến động cao nếu ATR cao hơn ngưỡng đã điều chỉnh
   if (atrRatio > volatilityThreshold) {
      m_IsVolatile = true;
   }
   
   // Phát hiện mức biến động đột biến
   if (IsATRExpanding()) {
      m_IsVolatile = true;
   }
   
   // Kiểm tra dải Bollinger
   double bbWidth = (m_Cache.bb_upper - m_Cache.bb_lower) / m_Cache.bb_middle;
   if (bbWidth > volatilityThreshold) {
      m_IsVolatile = true;
   }
   
   // TÍNH NĂNG MỚI: Phát hiện Spike Bar gần đây như một dấu hiệu của biến động cao
   if (HasRecentSpikeBar(3)) {
      m_IsVolatile = true;
   }
}

//+------------------------------------------------------------------+
//| Phân tích volume                                                 |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeVolume()
{
   // Đặt lại các cờ liên quan đến volume
   m_CurrentVolumeSpikeUp = false;
   m_CurrentVolumeSpikeDown = false;
   m_IsVolumeWeakening = false;
   
   // Lấy volume hiện tại và volume trung bình
   long currentVolume = m_Cache.volume;
   long avgVolume = m_Cache.avg_volume;
   
   // TÍNH NĂNG MỚI: Điều chỉnh ngưỡng volume spike theo phiên giao dịch
   double volumeRatioThreshold = m_VolumeRatioThreshold;
   
   switch (m_CurrentSession) {
      case SESSION_ASIAN:
         // Phiên Á thường có volume thấp, dễ xảy ra spike giả
         volumeRatioThreshold *= 1.3; // Tăng ngưỡng để tránh false positive
         break;
      case SESSION_EUROPEAN:
         // Phiên Âu volume trung bình
         volumeRatioThreshold *= 1.0; // Giữ nguyên
         break;
      case SESSION_AMERICAN:
         // Phiên Mỹ volume cao
         volumeRatioThreshold *= 0.9; // Giảm ngưỡng một chút
         break;
      case SESSION_EUROPEAN_AMERICAN:
         // Phiên overlap volume rất cao
         volumeRatioThreshold *= 0.85; // Giảm ngưỡng nhiều
         break;
      default:
         // Giữ nguyên
         break;
   }
   
   // Phát hiện volume spike
   if (currentVolume > avgVolume * volumeRatioThreshold) {
      // Phân biệt volume tăng khi giá tăng và giảm
      if (m_Cache.close > m_Cache.open) {
         m_CurrentVolumeSpikeUp = true;
      } else if (m_Cache.close < m_Cache.open) {
         m_CurrentVolumeSpikeDown = true;
      }
   }
   
   // Kiểm tra volume đang yếu dần
   long volume[];
   ArraySetAsSeries(volume, true);
   if (SafeCopyVolume(0, 5, volume)) {
      if (volume[0] < volume[1] && volume[1] < volume[2] && volume[2] < volume[3]) {
         m_IsVolumeWeakening = true;
      }
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Xác định phiên giao dịch hiện tại                 |
//+------------------------------------------------------------------+
ENUM_TRADING_SESSION CMarketMonitor::DetermineCurrentSession()
{
   // Chỉ cập nhật mỗi 15 phút để tránh tính toán quá nhiều
   datetime currentTime = TimeCurrent();
   if (currentTime - m_LastSessionCheckTime < 15 * 60 && m_CurrentSession != SESSION_UNKNOWN) {
      return m_CurrentSession;
   }
   
   // Lấy giờ GMT với offset
   MqlDateTime dt;
   TimeToStruct(TimeGMT() + m_GMTOffset * 3600, dt);
   int hour = dt.hour;
   
   // Phiên Á: 00:00 - 08:00 GMT
   if (hour >= 0 && hour < 8) {
      m_CurrentSession = SESSION_ASIAN;
   }
   // Phiên Âu: 08:00 - 13:00 GMT
   else if (hour >= 8 && hour < 13) {
      m_CurrentSession = SESSION_EUROPEAN;
   }
   // Phiên Overlap Âu-Mỹ: 13:00 - 16:00 GMT
   else if (hour >= 13 && hour < 16) {
      m_CurrentSession = SESSION_EUROPEAN_AMERICAN;
   }
   // Phiên Mỹ: 16:00 - 21:00 GMT
   else if (hour >= 16 && hour < 21) {
      m_CurrentSession = SESSION_AMERICAN;
   }
   // Phiên đóng cửa: 21:00 - 00:00 GMT
   else {
      m_CurrentSession = SESSION_CLOSING;
   }
   
   m_LastSessionCheckTime = currentTime;
   
   return m_CurrentSession;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lấy tên phiên giao dịch                          |
//+------------------------------------------------------------------+
string CMarketMonitor::GetSessionName(ENUM_TRADING_SESSION session)
{
   switch(session) {
      case SESSION_ASIAN: return "Á";
      case SESSION_EUROPEAN: return "Âu";
      case SESSION_AMERICAN: return "Mỹ";
      case SESSION_EUROPEAN_AMERICAN: return "Âu-Mỹ";
      case SESSION_CLOSING: return "Đóng cửa";
      default: return "Không xác định";
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Cập nhật tham số dựa trên phiên giao dịch        |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateSessionParameters()
{
   // Điều chỉnh các tham số phân tích dựa trên phiên giao dịch
   switch(m_CurrentSession) {
      case SESSION_ASIAN:
         // Phiên Á: Volume thấp, biến động thấp, sideway nhiều
         m_SpikeBarVolumeThreshold = 2.2;  // Tăng ngưỡng để tránh false positive
         break;
         
      case SESSION_EUROPEAN:
         // Phiên Âu: Volume trung bình, biến động trung bình, xu hướng rõ rệt
         m_SpikeBarVolumeThreshold = 2.0;  // Ngưỡng mặc định
         break;
         
      case SESSION_AMERICAN:
         // Phiên Mỹ: Volume cao, biến động cao, xu hướng mạnh
         m_SpikeBarVolumeThreshold = 1.9;  // Giảm nhẹ ngưỡng
         break;
         
      case SESSION_EUROPEAN_AMERICAN:
         // Phiên overlap: Volume rất cao, biến động rất cao
         m_SpikeBarVolumeThreshold = 1.8;  // Giảm nhiều ngưỡng
         break;
         
      case SESSION_CLOSING:
         // Phiên đóng cửa: Volume giảm, biến động giảm
         m_SpikeBarVolumeThreshold = 2.1;  // Tăng nhẹ ngưỡng
         break;
         
      default:
         // Giữ nguyên giá trị
         break;
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lấy tên phiên giao dịch hiện tại                 |
//+------------------------------------------------------------------+
string CMarketMonitor::GetCurrentSessionName() const
{
   return GetSessionName(m_CurrentSession);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phân tích Divergence                             |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeDivergence()
{
   // Reset các giá trị divergence
   m_Cache.rsiDivergence = DIVERGENCE_NONE;
   m_Cache.macdDivergence = DIVERGENCE_NONE;
   
   int lookbackDepth = 50; // Số nến nhìn lại để tìm divergence
   
   // Phát hiện các loại divergence khác nhau
   // 1. Regular Bullish Divergence (Giá thấp hơn, oscillator cao hơn)
   if (DetectRegularBullishDivergence(0, lookbackDepth)) {
      m_Cache.rsiDivergence = DIVERGENCE_REGULAR_BULLISH;
      
      if(m_Logger && m_Logger.IsDebugEnabled()) {
         m_Logger.LogDebug("Phát hiện RSI Regular Bullish Divergence");
      }
   }
   
   // 2. Regular Bearish Divergence (Giá cao hơn, oscillator thấp hơn)
   if (DetectRegularBearishDivergence(0, lookbackDepth)) {
      m_Cache.rsiDivergence = DIVERGENCE_REGULAR_BEARISH;
      
      if(m_Logger && m_Logger.IsDebugEnabled()) {
         m_Logger.LogDebug("Phát hiện RSI Regular Bearish Divergence");
      }
   }
   
   // 3. Hidden Bullish Divergence (Giá cao hơn, oscillator thấp hơn)
   if (DetectHiddenBullishDivergence(0, lookbackDepth)) {
      m_Cache.rsiDivergence = DIVERGENCE_HIDDEN_BULLISH;
      
      if(m_Logger && m_Logger.IsDebugEnabled()) {
         m_Logger.LogDebug("Phát hiện RSI Hidden Bullish Divergence");
      }
   }
   
   // 4. Hidden Bearish Divergence (Giá thấp hơn, oscillator cao hơn)
   if (DetectHiddenBearishDivergence(0, lookbackDepth)) {
      m_Cache.rsiDivergence = DIVERGENCE_HIDDEN_BEARISH;
      
      if(m_Logger && m_Logger.IsDebugEnabled()) {
         m_Logger.LogDebug("Phát hiện RSI Hidden Bearish Divergence");
      }
   }
   
   // Tương tự cho MACD
   // Lưu ý: Phân tích MACD Divergence tương tự như RSI nhưng cần đọc line MACD thay vì RSI
   // Do có nhiều chi tiết phức tạp, phần này có thể triển khai sau
   m_Cache.macdDivergence = DIVERGENCE_NONE;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phát hiện Regular Bullish Divergence             |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectRegularBullishDivergence(int start, int depth)
{
   // RSI đọc từ indicator
   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   
   // Giá đọc từ chart
   double lowBuffer[];
   ArraySetAsSeries(lowBuffer, true);
   
   // Copy dữ liệu
   if (!SafeCopyBuffer(m_HandleRSI, 0, start, depth, rsiBuffer) ||
       !CopyLow(m_Symbol, m_Timeframe, start, depth, lowBuffer)) {
      return false;
   }
   
   // Tìm 2 đáy gần nhất của giá
   int low1Index = -1, low2Index = -1;
   double low1 = 0, low2 = 0;
   
   // Tìm đáy đầu tiên
   for (int i = 20; i < depth - 3; i++) {
      if (IsLocalBottom(lowBuffer, i, 2)) {
         low1Index = i;
         low1 = lowBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đáy đầu tiên, không thể có divergence
   if (low1Index <= 0) return false;
   
   // Tìm đáy thứ hai (nằm giữa đáy đầu tiên và hiện tại)
   for (int i = 3; i < low1Index - 5; i++) {
      if (IsLocalBottom(lowBuffer, i, 2)) {
         low2Index = i;
         low2 = lowBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đáy thứ hai, không thể có divergence
   if (low2Index <= 0) return false;
   
   // Kiểm tra điều kiện divergence
   bool priceMakesLowerLow = low2 < low1;
   bool rsiMakesHigherLow = rsiBuffer[low2Index] > rsiBuffer[low1Index];
   
   // Regular Bullish Divergence: Giá tạo đáy thấp hơn, nhưng RSI tạo đáy cao hơn
   return priceMakesLowerLow && rsiMakesHigherLow;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phát hiện Regular Bearish Divergence             |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectRegularBearishDivergence(int start, int depth)
{
   // RSI đọc từ indicator
   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   
   // Giá đọc từ chart
   double highBuffer[];
   ArraySetAsSeries(highBuffer, true);
   
   // Copy dữ liệu
   if (!SafeCopyBuffer(m_HandleRSI, 0, start, depth, rsiBuffer) ||
       !CopyHigh(m_Symbol, m_Timeframe, start, depth, highBuffer)) {
      return false;
   }
   
   // Tìm 2 đỉnh gần nhất của giá
   int high1Index = -1, high2Index = -1;
   double high1 = 0, high2 = 0;
   
   // Tìm đỉnh đầu tiên
   for (int i = 20; i < depth - 3; i++) {
      if (IsLocalTop(highBuffer, i, 2)) {
         high1Index = i;
         high1 = highBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đỉnh đầu tiên, không thể có divergence
   if (high1Index <= 0) return false;
   
   // Tìm đỉnh thứ hai (nằm giữa đỉnh đầu tiên và hiện tại)
   for (int i = 3; i < high1Index - 5; i++) {
      if (IsLocalTop(highBuffer, i, 2)) {
         high2Index = i;
         high2 = highBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đỉnh thứ hai, không thể có divergence
   if (high2Index <= 0) return false;
   
   // Kiểm tra điều kiện divergence
   bool priceMakesHigherHigh = high2 > high1;
   bool rsiMakesLowerHigh = rsiBuffer[high2Index] < rsiBuffer[high1Index];
   
   // Regular Bearish Divergence: Giá tạo đỉnh cao hơn, nhưng RSI tạo đỉnh thấp hơn
   return priceMakesHigherHigh && rsiMakesLowerHigh;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phát hiện Hidden Bullish Divergence              |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectHiddenBullishDivergence(int start, int depth)
{
   // RSI đọc từ indicator
   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   
   // Giá đọc từ chart
   double lowBuffer[];
   ArraySetAsSeries(lowBuffer, true);
   
   // Copy dữ liệu
   if (!SafeCopyBuffer(m_HandleRSI, 0, start, depth, rsiBuffer) ||
       !CopyLow(m_Symbol, m_Timeframe, start, depth, lowBuffer)) {
      return false;
   }
   
   // Tìm 2 đáy gần nhất của giá
   int low1Index = -1, low2Index = -1;
   double low1 = 0, low2 = 0;
   
   // Tìm đáy đầu tiên
   for (int i = 20; i < depth - 3; i++) {
      if (IsLocalBottom(lowBuffer, i, 2)) {
         low1Index = i;
         low1 = lowBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đáy đầu tiên, không thể có divergence
   if (low1Index <= 0) return false;
   
   // Tìm đáy thứ hai (nằm giữa đáy đầu tiên và hiện tại)
   for (int i = 3; i < low1Index - 5; i++) {
      if (IsLocalBottom(lowBuffer, i, 2)) {
         low2Index = i;
         low2 = lowBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đáy thứ hai, không thể có divergence
   if (low2Index <= 0) return false;
   
   // Kiểm tra điều kiện divergence
   bool priceMakesHigherLow = low2 > low1;
   bool rsiMakesLowerLow = rsiBuffer[low2Index] < rsiBuffer[low1Index];
   
   // Hidden Bullish Divergence: Giá tạo đáy cao hơn, nhưng RSI tạo đáy thấp hơn
   return priceMakesHigherLow && rsiMakesLowerLow;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phát hiện Hidden Bearish Divergence              |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectHiddenBearishDivergence(int start, int depth)
{
   // RSI đọc từ indicator
   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   
   // Giá đọc từ chart
   double highBuffer[];
   ArraySetAsSeries(highBuffer, true);
   
   // Copy dữ liệu
   if (!SafeCopyBuffer(m_HandleRSI, 0, start, depth, rsiBuffer) ||
       !CopyHigh(m_Symbol, m_Timeframe, start, depth, highBuffer)) {
      return false;
   }
   
   // Tìm 2 đỉnh gần nhất của giá
   int high1Index = -1, high2Index = -1;
   double high1 = 0, high2 = 0;
   
   // Tìm đỉnh đầu tiên
   for (int i = 20; i < depth - 3; i++) {
      if (IsLocalTop(highBuffer, i, 2)) {
         high1Index = i;
         high1 = highBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đỉnh đầu tiên, không thể có divergence
   if (high1Index <= 0) return false;
   
   // Tìm đỉnh thứ hai (nằm giữa đỉnh đầu tiên và hiện tại)
   for (int i = 3; i < high1Index - 5; i++) {
      if (IsLocalTop(highBuffer, i, 2)) {
         high2Index = i;
         high2 = highBuffer[i];
         break;
      }
   }
   
   // Nếu không tìm thấy đỉnh thứ hai, không thể có divergence
   if (high2Index <= 0) return false;
   
   // Kiểm tra điều kiện divergence
   bool priceMakesLowerHigh = high2 < high1;
   bool rsiMakesHigherHigh = rsiBuffer[high2Index] > rsiBuffer[high1Index];
   
   // Hidden Bearish Divergence: Giá tạo đỉnh thấp hơn, nhưng RSI tạo đỉnh cao hơn
   return priceMakesLowerHigh && rsiMakesHigherHigh;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lấy mô tả Divergence                             |
//+------------------------------------------------------------------+
string CMarketMonitor::GetDivergenceDescription(ENUM_DIVERGENCE_TYPE type)
{
   switch(type) {
      case DIVERGENCE_REGULAR_BULLISH: return "Regular Bullish";
      case DIVERGENCE_REGULAR_BEARISH: return "Regular Bearish";
      case DIVERGENCE_HIDDEN_BULLISH: return "Hidden Bullish";
      case DIVERGENCE_HIDDEN_BEARISH: return "Hidden Bearish";
      default: return "Không có";
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Kiểm tra Bullish Divergence                      |
//+------------------------------------------------------------------+
bool CMarketMonitor::HasBullishDivergence() const
{
   return (m_Cache.rsiDivergence == DIVERGENCE_REGULAR_BULLISH || 
           m_Cache.rsiDivergence == DIVERGENCE_HIDDEN_BULLISH || 
           m_Cache.macdDivergence == DIVERGENCE_REGULAR_BULLISH || 
           m_Cache.macdDivergence == DIVERGENCE_HIDDEN_BULLISH);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Kiểm tra Bearish Divergence                      |
//+------------------------------------------------------------------+
bool CMarketMonitor::HasBearishDivergence() const
{
   return (m_Cache.rsiDivergence == DIVERGENCE_REGULAR_BEARISH || 
           m_Cache.rsiDivergence == DIVERGENCE_HIDDEN_BEARISH || 
           m_Cache.macdDivergence == DIVERGENCE_REGULAR_BEARISH || 
           m_Cache.macdDivergence == DIVERGENCE_HIDDEN_BEARISH);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Phát hiện Spike Bar                              |
//+------------------------------------------------------------------+
void CMarketMonitor::DetectSpikeBars()
{
   // Không cần phát hiện nếu không phải nến mới
   if(!m_IsNewBar && m_SpikeBarCount > 0) return;
   
   // Đọc dữ liệu giá và khối lượng
   double open[], high[], low[], close[];
   long volume[];
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(volume, true);
   
   if (!SafeCopyRates(0, m_SpikeBarLookback + 1, open, high, low, close) || 
       !SafeCopyVolume(0, m_SpikeBarLookback + 1, volume)) {
      return;
   }
   
   // Reset danh sách Spike Bar
   m_SpikeBarCount = 0;
   
   // Duyệt qua các nến để tìm Spike Bar
   for (int i = 0; i < m_SpikeBarLookback; i++) {
      double bodySize = 0;
      double volumeRatio = 0;
      
      // Kiểm tra nếu nến là Spike Bar
      if (IsBarSpike(i, bodySize, volumeRatio)) {
         bool isBullish = close[i] > open[i];
         AddSpikeBar(i, bodySize, volumeRatio, isBullish);
      }
      
      // Nếu đã tìm đủ 5 Spike Bar, dừng lại
      if (m_SpikeBarCount >= 5) break;
   }
   
   // Log số lượng Spike Bar tìm được
   if (m_Logger && m_Logger.IsDebugEnabled() && m_SpikeBarCount > 0) {
      m_Logger.LogDebug("Tìm thấy " + IntegerToString(m_SpikeBarCount) + " Spike Bar");
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Kiểm tra nến có phải Spike Bar hay không         |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsBarSpike(int barIndex, double &bodySize, double &volumeRatio)
{
   // Đọc dữ liệu giá và khối lượng
   double open[], high[], low[], close[];
   long volume[];
   
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(volume, true);
   
   if (!CopyOpen(m_Symbol, m_Timeframe, 0, barIndex + 5, open) || 
       !CopyHigh(m_Symbol, m_Timeframe, 0, barIndex + 5, high) ||
       !CopyLow(m_Symbol, m_Timeframe, 0, barIndex + 5, low) ||
       !CopyClose(m_Symbol, m_Timeframe, 0, barIndex + 5, close) ||
       !CopyTickVolume(m_Symbol, m_Timeframe, 0, barIndex + 10, volume)) {
      return false;
   }
   
   // Tính kích thước thân nến
   bodySize = MathAbs(close[barIndex] - open[barIndex]);
   double totalRange = high[barIndex] - low[barIndex];
   
   // Tính ATR
   double atr = m_Cache.atr;
   if (atr <= 0) return false;
   
   // Tính tỷ lệ bodySize/ATR
   double bodySizeRatio = bodySize / atr;
   
   // Tính tỷ lệ volume so với trung bình
   long avgVolume = 0;
   int validBars = 0;
   
   // Tính volume trung bình của 10 nến gần nhất (trừ nến hiện tại)
   for (int i = barIndex + 1; i < barIndex + 10; i++) {
      if (i < ArraySize(volume)) {
         avgVolume += volume[i];
         validBars++;
      }
   }
   
   avgVolume = (validBars > 0) ? (avgVolume / validBars) : 1;
   volumeRatio = (double)volume[barIndex] / (double)avgVolume;
   
   // Kiểm tra điều kiện Spike Bar:
   // 1. Thân nến lớn hơn m_SpikeBarBodyThreshold lần ATR
   // 2. Volume lớn hơn m_SpikeBarVolumeThreshold lần trung bình
   // 3. Thân nến chiếm ít nhất 60% tổng biên độ nến
   bool isSpike = (bodySizeRatio >= m_SpikeBarBodyThreshold) && 
                 (volumeRatio >= m_SpikeBarVolumeThreshold) &&
                 (totalRange > 0 && bodySize / totalRange >= 0.6);
                 
   return isSpike;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Thêm Spike Bar vào danh sách                      |
//+------------------------------------------------------------------+
void CMarketMonitor::AddSpikeBar(int barIndex, double bodySize, double volumeRatio, bool isBullish)
{
   // Đảm bảo không vượt quá giới hạn mảng
   if (m_SpikeBarCount >= 5) return;
   
   // Đọc dữ liệu giá và khối lượng
   double high[], low[];
   long volume[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(volume, true);
   
   if (!CopyHigh(m_Symbol, m_Timeframe, 0, barIndex + 1, high) ||
       !CopyLow(m_Symbol, m_Timeframe, 0, barIndex + 1, low) ||
       !CopyTickVolume(m_Symbol, m_Timeframe, 0, barIndex + 1, volume)) {
      return;
   }
   
   // Tạo thông tin Spike Bar
   m_RecentSpikeBars[m_SpikeBarCount].time = iTime(m_Symbol, m_Timeframe, barIndex);
   m_RecentSpikeBars[m_SpikeBarCount].high = high[barIndex];
   m_RecentSpikeBars[m_SpikeBarCount].low = low[barIndex];
   m_RecentSpikeBars[m_SpikeBarCount].bodySize = bodySize;
   m_RecentSpikeBars[m_SpikeBarCount].totalRange = high[barIndex] - low[barIndex];
   m_RecentSpikeBars[m_SpikeBarCount].volume = volume[barIndex];
   m_RecentSpikeBars[m_SpikeBarCount].volumeRatio = volumeRatio;
   m_RecentSpikeBars[m_SpikeBarCount].isBullish = isBullish;
   
   // Tăng số lượng Spike Bar
   m_SpikeBarCount++;
   
   // Log thông tin
   if (m_Logger && m_Logger.IsDebugEnabled()) {
      m_Logger.LogDebug(StringFormat(
         "Spike Bar #%d: Thời gian=%s, BodySize=%.5f, VolumeRatio=%.2f, %s",
         m_SpikeBarCount,
         TimeToString(m_RecentSpikeBars[m_SpikeBarCount - 1].time),
         bodySize,
         volumeRatio,
         isBullish ? "Bullish" : "Bearish"
      ));
   }
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Lấy thông tin Spike Bar gần nhất                  |
//+------------------------------------------------------------------+
bool CMarketMonitor::GetLatestSpikeBar(SpikeBarInfo &info)
{
   if (m_SpikeBarCount <= 0) return false;
   
   // Copy thông tin từ spike bar gần nhất
   info = m_RecentSpikeBars[0];
   return true;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Kiểm tra có Spike Bar gần đây không               |
//+------------------------------------------------------------------+
bool CMarketMonitor::HasRecentSpikeBar(int barsLookback) const
{
   if (m_SpikeBarCount <= 0) return false;
   
   // Lấy thời gian của nến hiện tại và nến barsLookback trước
   datetime currentTime = iTime(m_Symbol, m_Timeframe, 0);
   datetime lookbackTime = iTime(m_Symbol, m_Timeframe, barsLookback);
   
   // Kiểm tra xem có spike bar nào nằm trong khoảng từ lookbackTime đến currentTime không
   for (int i = 0; i < m_SpikeBarCount; i++) {
      if (m_RecentSpikeBars[i].time >= lookbackTime && m_RecentSpikeBars[i].time <= currentTime) {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI: Kiểm tra Bearish Spike Bar gần đây không          |
//+------------------------------------------------------------------+
bool CMarketMonitor::HasRecentBearishSpikeBar(int barsLookback) const
{
   if (m_SpikeBarCount <= 0) return false;
   
   // Lấy thời gian của nến hiện tại và nến barsLookback trước
   datetime currentTime = iTime(m_Symbol, m_Timeframe, 0);
   datetime lookbackTime = iTime(m_Symbol, m_Timeframe, barsLookback);
   
   // Kiểm tra xem có bearish spike bar nào nằm trong khoảng từ lookbackTime đến currentTime không
   for (int i = 0; i < m_SpikeBarCount; i++) {
      if (m_RecentSpikeBars[i].time >= lookbackTime && 
          m_RecentSpikeBars[i].time <= currentTime &&
          !m_RecentSpikeBars[i].isBullish) {
         return true;
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Cập nhật lịch sử thị trường                                      |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateMarketHistory()
{
   // Lưu thông tin hiện tại vào vị trí mới nhất của bộ đệm vòng
   int idx = m_MarketHistory.currentIndex;
   
   // Lưu thông tin profile
   m_MarketHistory.profiles[idx] = m_MarketProfile;
   m_MarketHistory.trendUp[idx] = m_IsTrendUp;
   m_MarketHistory.trendDown[idx] = m_IsTrendDown;
   m_MarketHistory.atrRatio[idx] = m_Cache.atr / (g_AverageATR > 0 ? g_AverageATR : 1);
   m_MarketHistory.volumeSpike[idx] = m_CurrentVolumeSpikeUp || m_CurrentVolumeSpikeDown;
   m_MarketHistory.sessions[idx] = m_CurrentSession;
   
   // Cập nhật vị trí cho lần ghi tiếp theo trong bộ đệm vòng
   m_MarketHistory.currentIndex = (idx + 1) % 10;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem thị trường có đang chuyển từ sideway sang trend    |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTransitioningToTrend()
{
   // Cần ít nhất 5 cập nhật để có thể phân tích xu hướng
   int historyCount = 10;
   
   // Đếm số lần sideway gần đây
   int recentSidewayCount = 0;
   int olderSidewayCount = 0;
   
   // Đếm số lần trending gần đây
   int recentTrendCount = 0;
   int olderTrendCount = 0;
   
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Đếm trạng thái trong 5 cập nhật gần nhất
   for (int i = 0; i < 5; i++) {
      int idx = (currentIdx - 1 - i + 10) % 10; // Lùi về cập nhật trước
      if (idx < 0) idx += 10; // Đảm bảo index không âm
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_RANGING ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_ACCUMULATION ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_DISTRIBUTION) {
         recentSidewayCount++;
      }
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_STRONG_TREND ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_WEAK_TREND) {
         recentTrendCount++;
      }
   }
   
   // Đếm trạng thái trong 5 cập nhật cũ hơn
   for (int i = 5; i < 10; i++) {
      int idx = (currentIdx - 1 - i + 10) % 10; // Lùi về cập nhật trước
      if (idx < 0) idx += 10; // Đảm bảo index không âm
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_RANGING ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_ACCUMULATION ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_DISTRIBUTION) {
         olderSidewayCount++;
      }
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_STRONG_TREND ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_WEAK_TREND) {
         olderTrendCount++;
      }
   }
   
   // Nếu phần lớn cập nhật cũ là sideway, và gần đây xuất hiện xu hướng
   return (olderSidewayCount >= 3 && recentTrendCount >= 3);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem thị trường có đang chuyển từ trend sang sideway     |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTransitioningToRanging()
{
   // Cần ít nhất 5 cập nhật để có thể phân tích xu hướng
   int historyCount = 10;
   
   // Đếm số lần sideway gần đây
   int recentSidewayCount = 0;
   int olderSidewayCount = 0;
   
   // Đếm số lần trending gần đây
   int recentTrendCount = 0;
   int olderTrendCount = 0;
   
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Tương tự như IsTransitioningToTrend, nhưng kiểm tra điều kiện ngược lại
   // Đếm trạng thái trong 5 cập nhật gần nhất
   for (int i = 0; i < 5; i++) {
      int idx = (currentIdx - 1 - i + 10) % 10; // Lùi về cập nhật trước
      if (idx < 0) idx += 10; // Đảm bảo index không âm
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_RANGING ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_ACCUMULATION ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_DISTRIBUTION) {
         recentSidewayCount++;
      }
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_STRONG_TREND ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_WEAK_TREND) {
         recentTrendCount++;
      }
   }
   
   // Đếm trạng thái trong 5 cập nhật cũ hơn
   for (int i = 5; i < 10; i++) {
      int idx = (currentIdx - 1 - i + 10) % 10; // Lùi về cập nhật trước
      if (idx < 0) idx += 10; // Đảm bảo index không âm
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_RANGING ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_ACCUMULATION ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_DISTRIBUTION) {
         olderSidewayCount++;
      }
      
      if (m_MarketHistory.profiles[idx] == MARKET_PROFILE_STRONG_TREND ||
          m_MarketHistory.profiles[idx] == MARKET_PROFILE_WEAK_TREND) {
         olderTrendCount++;
      }
   }
   
   // Nếu phần lớn cập nhật cũ là xu hướng, và gần đây xuất hiện sideway
   return (olderTrendCount >= 3 && recentSidewayCount >= 3);
}

//+------------------------------------------------------------------+
//| Kiểm tra biến động có đang tăng không                           |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolatilityIncreasing()
{
   // Cần ít nhất 3 cập nhật để có thể phân tích
   
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Lấy 3 giá trị ATR gần nhất
   double atr1 = m_MarketHistory.atrRatio[(currentIdx - 1 + 10) % 10];
   double atr2 = m_MarketHistory.atrRatio[(currentIdx - 2 + 10) % 10];
   double atr3 = m_MarketHistory.atrRatio[(currentIdx - 3 + 10) % 10];
   
   // Biến động tăng nếu ATR hiện tại > ATR trước > ATR trước nữa
   return (atr1 > atr2 && atr2 > atr3);
}

//+------------------------------------------------------------------+
//| Kiểm tra biến động có đang giảm không                           |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolatilityDecreasing()
{
   // Cần ít nhất 3 cập nhật để có thể phân tích
   
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Lấy 3 giá trị ATR gần nhất
   double atr1 = m_MarketHistory.atrRatio[(currentIdx - 1 + 10) % 10];
   double atr2 = m_MarketHistory.atrRatio[(currentIdx - 2 + 10) % 10];
   double atr3 = m_MarketHistory.atrRatio[(currentIdx - 3 + 10) % 10];
   
   // Biến động giảm nếu ATR hiện tại < ATR trước < ATR trước nữa
   return (atr1 < atr2 && atr2 < atr3);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Multi-timeframe trend confirmation            |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTrendUpHigher() const
{
   if (!m_UseMultiTimeframe) return false;
   
   // Kiểm tra xu hướng trên khung thời gian cao hơn
   int emaHandle34 = iMA(m_Symbol, m_HigherTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle89 = iMA(m_Symbol, m_HigherTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle200 = iMA(m_Symbol, m_HigherTimeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   
   if (emaHandle34 == INVALID_HANDLE || emaHandle89 == INVALID_HANDLE || emaHandle200 == INVALID_HANDLE) {
      return false;
   }
   
   double ema34[], ema89[], ema200[], close[];
   ArraySetAsSeries(ema34, true);
   ArraySetAsSeries(ema89, true);
   ArraySetAsSeries(ema200, true);
   ArraySetAsSeries(close, true);
   
   bool success = CopyBuffer(emaHandle34, 0, 0, 1, ema34) > 0 &&
                 CopyBuffer(emaHandle89, 0, 0, 1, ema89) > 0 &&
                 CopyBuffer(emaHandle200, 0, 0, 1, ema200) > 0 &&
                 CopyClose(m_Symbol, m_HigherTimeframe, 0, 1, close) > 0;
   
   IndicatorRelease(emaHandle34);
   IndicatorRelease(emaHandle89);
   IndicatorRelease(emaHandle200);
   
   if (!success) return false;
   
   // Trend Up: EMA34 > EMA89 > EMA200 && Giá > EMA34
   return (ema34[0] > ema89[0] && ema89[0] > ema200[0] && close[0] > ema34[0]);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Multi-timeframe trend confirmation            |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTrendDownHigher() const
{
   if (!m_UseMultiTimeframe) return false;
   
   // Kiểm tra xu hướng giảm trên khung thời gian cao hơn
   int emaHandle34 = iMA(m_Symbol, m_HigherTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle89 = iMA(m_Symbol, m_HigherTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle200 = iMA(m_Symbol, m_HigherTimeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   
   if (emaHandle34 == INVALID_HANDLE || emaHandle89 == INVALID_HANDLE || emaHandle200 == INVALID_HANDLE) {
      return false;
   }
   
   double ema34[], ema89[], ema200[], close[];
   ArraySetAsSeries(ema34, true);
   ArraySetAsSeries(ema89, true);
   ArraySetAsSeries(ema200, true);
   ArraySetAsSeries(close, true);
   
   bool success = CopyBuffer(emaHandle34, 0, 0, 1, ema34) > 0 &&
                 CopyBuffer(emaHandle89, 0, 0, 1, ema89) > 0 &&
                 CopyBuffer(emaHandle200, 0, 0, 1, ema200) > 0 &&
                 CopyClose(m_Symbol, m_HigherTimeframe, 0, 1, close) > 0;
   
   IndicatorRelease(emaHandle34);
   IndicatorRelease(emaHandle89);
   IndicatorRelease(emaHandle200);
   
   if (!success) return false;
   
   // Trend Down: EMA34 < EMA89 < EMA200 && Giá < EMA34
   return (ema34[0] < ema89[0] && ema89[0] < ema200[0] && close[0] < ema34[0]);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Trend confirmation trên khung thời gian nhỏ  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTrendUpNested() const
{
   if (!m_UseNestedTimeframe) return false;
   
   // Kiểm tra xu hướng trên khung thời gian nhỏ hơn/lồng ghép
   int emaHandle34 = iMA(m_Symbol, m_NestedTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle89 = iMA(m_Symbol, m_NestedTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   
   if (emaHandle34 == INVALID_HANDLE || emaHandle89 == INVALID_HANDLE) {
      return false;
   }
   
   double ema34[], ema89[], close[];
   ArraySetAsSeries(ema34, true);
   ArraySetAsSeries(ema89, true);
   ArraySetAsSeries(close, true);
   
   bool success = CopyBuffer(emaHandle34, 0, 0, 1, ema34) > 0 &&
                 CopyBuffer(emaHandle89, 0, 0, 1, ema89) > 0 &&
                 CopyClose(m_Symbol, m_NestedTimeframe, 0, 1, close) > 0;
   
   IndicatorRelease(emaHandle34);
   IndicatorRelease(emaHandle89);
   
   if (!success) return false;
   
   // Trend Up trên khung nhỏ: EMA34 > EMA89 && Giá > EMA34
   return (ema34[0] > ema89[0] && close[0] > ema34[0]);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Trend confirmation trên khung thời gian nhỏ  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTrendDownNested() const
{
   if (!m_UseNestedTimeframe) return false;
   
   // Kiểm tra xu hướng giảm trên khung thời gian nhỏ hơn/lồng ghép
   int emaHandle34 = iMA(m_Symbol, m_NestedTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
   int emaHandle89 = iMA(m_Symbol, m_NestedTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   
   if (emaHandle34 == INVALID_HANDLE || emaHandle89 == INVALID_HANDLE) {
      return false;
   }
   
   double ema34[], ema89[], close[];
   ArraySetAsSeries(ema34, true);
   ArraySetAsSeries(ema89, true);
   ArraySetAsSeries(close, true);
   
   bool success = CopyBuffer(emaHandle34, 0, 0, 1, ema34) > 0 &&
                 CopyBuffer(emaHandle89, 0, 0, 1, ema89) > 0 &&
                 CopyClose(m_Symbol, m_NestedTimeframe, 0, 1, close) > 0;
   
   IndicatorRelease(emaHandle34);
   IndicatorRelease(emaHandle89);
   
   if (!success) return false;
   
   // Trend Down trên khung nhỏ: EMA34 < EMA89 && Giá < EMA34
   return (ema34[0] < ema89[0] && close[0] < ema34[0]);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Tính điểm số chuyển tiếp giữa các chế độ     |
//+------------------------------------------------------------------+
double CMarketMonitor::GetRegimeTransitionScore()
{
   // Cần ít nhất 5 cập nhật để có thể phân tích
   
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Đếm số lần thay đổi regime trong 5 cập nhật gần nhất
   int regimeChanges = 0;
   ENUM_MARKET_PROFILE_TYPE lastProfile = m_MarketHistory.profiles[(currentIdx - 1 + 10) % 10];
   
   for (int i = 2; i <= 5; i++) {
      int idx = (currentIdx - i + 10) % 10;
      ENUM_MARKET_PROFILE_TYPE currentProfile = m_MarketHistory.profiles[idx];
      
      // Nếu có sự thay đổi từ trending sang ranging hoặc ngược lại
      bool wasTrending = (lastProfile == MARKET_PROFILE_STRONG_TREND || 
                        lastProfile == MARKET_PROFILE_WEAK_TREND);
      
      bool wasRanging = (lastProfile == MARKET_PROFILE_RANGING || 
                       lastProfile == MARKET_PROFILE_ACCUMULATION || 
                       lastProfile == MARKET_PROFILE_DISTRIBUTION);
      
      bool isTrending = (currentProfile == MARKET_PROFILE_STRONG_TREND || 
                       currentProfile == MARKET_PROFILE_WEAK_TREND);
      
      bool isRanging = (currentProfile == MARKET_PROFILE_RANGING || 
                      currentProfile == MARKET_PROFILE_ACCUMULATION || 
                      currentProfile == MARKET_PROFILE_DISTRIBUTION);
      
      if ((wasTrending && isRanging) || (wasRanging && isTrending)) {
         regimeChanges++;
      }
      
      lastProfile = currentProfile;
   }
   
   // Điểm số chuyển tiếp từ 0.0 đến 1.0, với 1.0 là mức cao nhất
   return MathMin(regimeChanges / 3.0, 1.0);
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Đếm số lần xác nhận chế độ liên tiếp         |
//+------------------------------------------------------------------+
int CMarketMonitor::GetConsecutiveRegimeConfirmations()
{
   // Vị trí hiện tại trong bộ đệm vòng
   int currentIdx = m_MarketHistory.currentIndex;
   
   // Lấy profile gần nhất
   ENUM_MARKET_PROFILE_TYPE lastProfile = m_MarketHistory.profiles[(currentIdx - 1 + 10) % 10];
   
   // Đếm số lần xác nhận liên tiếp
   int confirmations = 1; // Bắt đầu từ 1 cho profile hiện tại
   
   for (int i = 2; i <= 10; i++) {
      int idx = (currentIdx - i + 10) % 10;
      ENUM_MARKET_PROFILE_TYPE currentProfile = m_MarketHistory.profiles[idx];
      
      // Nếu profile không khớp với cái gần nhất, dừng đếm
      if (currentProfile != lastProfile || currentProfile == MARKET_PROFILE_UNKNOWN) {
         break;
      }
      
      confirmations++;
   }
   
   return confirmations;
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Kiểm tra chế độ thị trường đang chuyển tiếp  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsRegimeTransitioning()
{
   double transitionScore = GetRegimeTransitionScore();
   return (transitionScore > 0.5); // Ngưỡng 0.5 cho việc chuyển tiếp
}

//+------------------------------------------------------------------+
//| TÍNH NĂNG MỚI V13: Hỗ trợ Chandelier Exit                        |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateChandelierExitLevel(bool isLong, int lookback, double atrMultiplier)
{
   // Lấy ATR hiện tại
   double atr = m_Cache.atr;
   if (atr <= 0) return 0;
   
   // Lấy dữ liệu giá
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if (CopyHigh(m_Symbol, m_Timeframe, 0, lookback + 1, high) <= 0 ||
       CopyLow(m_Symbol, m_Timeframe, 0, lookback + 1, low) <= 0) {
      return 0;
   }
   
   double exitLevel = 0;
   
   if (isLong) {
      // Tìm giá cao nhất trong khoảng lookback
      double highestPrice = high[ArrayMaximum(high, 0, lookback)];
      
      // Chandelier Exit cho lệnh Long = Giá cao nhất - ATR * hệ số
      exitLevel = highestPrice - (atr * atrMultiplier);
   }
   else {
      // Tìm giá thấp nhất trong khoảng lookback
      double lowestPrice = low[ArrayMinimum(low, 0, lookback)];
      
      // Chandelier Exit cho lệnh Short = Giá thấp nhất + ATR * hệ số
      exitLevel = lowestPrice + (atr * atrMultiplier);
   }
   
   return NormalizeDouble(exitLevel, _Digits);
}

//+------------------------------------------------------------------+
//| Phương thức kiểm tra cơ bản cho local top/bottom                |
//+------------------------------------------------------------------+
bool CMarketMonitor::BaseLocalTopCheck(const double &high[], int index, int lookback)
{
   if (lookback <= 0) lookback = 1;
   
   // Kiểm tra nếu giá cao hơn các nến lân cận
   bool isTop = true;
   
   // Kiểm tra với các nến trước đó
   for (int i = 1; i <= lookback; i++) {
      if (index - i >= 0 && high[index] <= high[index - i]) {
         isTop = false;
         break;
      }
   }
   
   // Nếu vẫn còn là đỉnh, kiểm tra với các nến sau đó
   if (isTop) {
      for (int i = 1; i <= lookback; i++) {
         if (index + i < ArraySize(high) && high[index] <= high[index + i]) {
            isTop = false;
            break;
         }
      }
   }
   
   return isTop;
}

//+------------------------------------------------------------------+
//| Phương thức kiểm tra cơ bản cho local bottom                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::BaseLocalBottomCheck(const double &low[], int index, int lookback)
{
   if (lookback <= 0) lookback = 1;
   
   // Kiểm tra nếu giá thấp hơn các nến lân cận
   bool isBottom = true;
   
   // Kiểm tra với các nến trước đó
   for (int i = 1; i <= lookback; i++) {
      if (index - i >= 0 && low[index] >= low[index - i]) {
         isBottom = false;
         break;
      }
   }
   
   // Nếu vẫn còn là đáy, kiểm tra với các nến sau đó
   if (isBottom) {
      for (int i = 1; i <= lookback; i++) {
         if (index + i < ArraySize(low) && low[index] >= low[index + i]) {
            isBottom = false;
            break;
         }
      }
   }
   
   return isBottom;
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu nến là đỉnh cục bộ                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsLocalTop(const double &high[], int index, int lookback) 
{
   // Kiểm tra cơ bản
   if (!BaseLocalTopCheck(high, index, lookback)) {
      return false;
   }
   
   // Thêm logic để lọc nhiễu (ví dụ: kiểm tra size của nến, volume...)
   
   return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu nến là đáy cục bộ                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsLocalBottom(const double &low[], int index, int lookback) 
{
   // Kiểm tra cơ bản
   if (!BaseLocalBottomCheck(low, index, lookback)) {
      return false;
   }
   
   // Thêm logic để lọc nhiễu
   
   return true;
}

//+------------------------------------------------------------------+
//| Tìm mức thấp gần nhất từ nến bắt đầu                            |
//+------------------------------------------------------------------+
double CMarketMonitor::FindNearestLow(int startIndex, int lookbackBars)
{
   double low[];
   ArraySetAsSeries(low, true);
   
   if (CopyLow(m_Symbol, m_Timeframe, 0, startIndex + lookbackBars + 1, low) <= 0) {
      return 0;
   }
   
   double lowestValue = low[startIndex];
   int lowestIndex = startIndex;
   
   for (int i = startIndex + 1; i <= startIndex + lookbackBars; i++) {
      if (i < ArraySize(low) && low[i] < lowestValue) {
         lowestValue = low[i];
         lowestIndex = i;
      }
   }
   
   return lowestValue;
}

//+------------------------------------------------------------------+
//| Tìm mức cao gần nhất từ nến bắt đầu                             |
//+------------------------------------------------------------------+
double CMarketMonitor::FindNearestHigh(int startIndex, int lookbackBars)
{
   double high[];
   ArraySetAsSeries(high, true);
   
   if (CopyHigh(m_Symbol, m_Timeframe, 0, startIndex + lookbackBars + 1, high) <= 0) {
      return 0;
   }
   
   double highestValue = high[startIndex];
   int highestIndex = startIndex;
   
   for (int i = startIndex + 1; i <= startIndex + lookbackBars; i++) {
      if (i < ArraySize(high) && high[i] > highestValue) {
         highestValue = high[i];
         highestIndex = i;
      }
   }
   
   return highestValue;
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA tương đối (%)                                   |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateRelativeEMASlope(int emaPeriod, int bars)
{
   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   
   if (m_EmaCacheBars >= bars) {
      // Sử dụng dữ liệu cache sẵn có
      if (emaPeriod == 34) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache34[i];
         }
      }
      else if (emaPeriod == 89) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache89[i];
         }
      }
      else if (emaPeriod == 200) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache200[i];
         }
      }
      else {
         // Nếu không phải 3 chu kỳ chính, tính lại
         int emaHandle = iMA(m_Symbol, m_Timeframe, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
         if (emaHandle == INVALID_HANDLE) return 0;
         
         if (CopyBuffer(emaHandle, 0, 0, bars, emaBuffer) <= 0) {
            IndicatorRelease(emaHandle);
            return 0;
         }
         
         IndicatorRelease(emaHandle);
      }
   }
   else {
      // Nếu không có cache, tính lại
      int emaHandle = iMA(m_Symbol, m_Timeframe, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (emaHandle == INVALID_HANDLE) return 0;
      
      if (CopyBuffer(emaHandle, 0, 0, bars, emaBuffer) <= 0) {
         IndicatorRelease(emaHandle);
         return 0;
      }
      
      IndicatorRelease(emaHandle);
   }
   
   // Tính độ dốc dựa trên % thay đổi
   if (emaBuffer[bars-1] == 0) return 0;
   double slopePercent = (emaBuffer[0] - emaBuffer[bars-1]) / emaBuffer[bars-1] * 100.0;
   
   return slopePercent;
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA tuyệt đối                                       |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateAbsoluteEMASlope(int emaPeriod, int bars)
{
   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   
   if (m_EmaCacheBars >= bars) {
      // Sử dụng dữ liệu cache sẵn có
      if (emaPeriod == 34) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache34[i];
         }
      }
      else if (emaPeriod == 89) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache89[i];
         }
      }
      else if (emaPeriod == 200) {
         for (int i = 0; i < bars; i++) {
            emaBuffer[i] = m_EmaCache200[i];
         }
      }
      else {
         // Nếu không phải 3 chu kỳ chính, tính lại
         int emaHandle = iMA(m_Symbol, m_Timeframe, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
         if (emaHandle == INVALID_HANDLE) return 0;
         
         if (CopyBuffer(emaHandle, 0, 0, bars, emaBuffer) <= 0) {
            IndicatorRelease(emaHandle);
            return 0;
         }
         
         IndicatorRelease(emaHandle);
      }
   }
   else {
      // Nếu không có cache, tính lại
      int emaHandle = iMA(m_Symbol, m_Timeframe, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (emaHandle == INVALID_HANDLE) return 0;
      
      if (CopyBuffer(emaHandle, 0, 0, bars, emaBuffer) <= 0) {
         IndicatorRelease(emaHandle);
         return 0;
      }
      
      IndicatorRelease(emaHandle);
   }
   
   // Tính độ dốc hồi quy tuyến tính
   double sum_x = 0, sum_y = 0, sum_xy = 0, sum_xx = 0;
   for (int i = 0; i < bars; i++) {
      sum_x += i;
      sum_y += emaBuffer[i];
      sum_xy += i * emaBuffer[i];
      sum_xx += i * i;
   }
   
   double slope = 0;
   double n = (double)bars;
   double denominator = n * sum_xx - sum_x * sum_x;
   
   if (denominator != 0) {
      slope = (n * sum_xy - sum_x * sum_y) / denominator;
   }
   
   return slope;
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA tuyệt đối (phương pháp gốc để so sánh)          |
//+------------------------------------------------------------------+
double CMarketMonitor::OriginalCalculateAbsoluteEMASlope(int emaPeriod, int bars)
{
   int emaHandle = iMA(m_Symbol, m_Timeframe, emaPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if (emaHandle == INVALID_HANDLE) return 0;
   
   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   
   if (CopyBuffer(emaHandle, 0, 0, bars + 1, emaBuffer) <= 0) {
      IndicatorRelease(emaHandle);
      return 0;
   }
   
   // Tính độ dốc cơ bản: (EMA[0] - EMA[bars]) / bars
   double slope = (emaBuffer[0] - emaBuffer[bars]) / bars;
   
   IndicatorRelease(emaHandle);
   return slope;
}

//+------------------------------------------------------------------+
//| Lấy volume tại swing point gần nhất (high hoặc low)             |
//+------------------------------------------------------------------+
double CMarketMonitor::GetLatestSwingPointVolume(bool lookForHigh)
{
   // Duyệt qua mảng swing point gần đây
   for (int i = 0; i < m_SwingCount; i++) {
      // Nếu là đúng loại swing point cần tìm
      if (m_RecentSwings[i].isHigh == lookForHigh) {
         // Trả về volume tại swing point này
         return (double)m_RecentSwings[i].volume;
      }
   }
   
   return 0; // Không tìm thấy
}

//+------------------------------------------------------------------+
//| Thêm swing point mới vào mảng                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::AddSwingPoint(SwingPoint &newPoint)
{
   // Kiểm tra xem swing point này đã tồn tại chưa
   for (int i = 0; i < m_SwingCount; i++) {
      if (m_RecentSwings[i].time == newPoint.time && 
          m_RecentSwings[i].price == newPoint.price) {
         return; // Đã tồn tại, không thêm nữa
      }
   }
   
   // Nếu danh sách đã đầy, dịch chuyển tất cả lên
   if (m_SwingCount >= 10) {
      for (int i = 0; i < 9; i++) {
         m_RecentSwings[i] = m_RecentSwings[i+1];
      }
      m_SwingCount = 9;
   }
   
   // Thêm swing point mới
   m_RecentSwings[m_SwingCount] = newPoint;
   m_SwingCount++;
}

//+------------------------------------------------------------------+
//| Tính toán tỷ lệ ATR hiện tại so với trung bình                  |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateATRRatio()
{
   // Lấy ATR hiện tại
   double currentATR = m_Cache.atr;
   
   // Kiểm tra biến toàn cục g_AverageATR có tồn tại không
   if (currentATR <= 0) return 1.0;
   
   extern double g_AverageATR;
   
   // Tính tỷ lệ
   double averageATR = g_AverageATR;
   if (averageATR <= 0) {
      // Nếu chưa có ATR trung bình, tính
      double atrBuffer[];
      ArraySetAsSeries(atrBuffer, true);
      
      int atrHandle = iATR(m_Symbol, PERIOD_D1, 14);
      if (atrHandle != INVALID_HANDLE) {
         if (CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) == 20) {
            // Tính ATR trung bình 20 ngày
            double avgATR = 0;
            for (int i = 0; i < 20; i++) {
               avgATR += atrBuffer[i];
            }
            avgATR /= 20;
            
            averageATR = avgATR;
         }
         IndicatorRelease(atrHandle);
      }
   }
   
   // Nếu vẫn không có ATR trung bình, trả về 1.0
   if (averageATR <= 0) return 1.0;
   
   return currentATR / averageATR;
}

//+------------------------------------------------------------------+
//| Kiểm tra ATR đang mở rộng (tăng)                                |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsATRExpanding(int lookback)
{
   if (lookback <= 0) lookback = m_DefaultATRLookback;
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   int atrHandle = iATR(m_Symbol, m_Timeframe, 14);
   if (atrHandle == INVALID_HANDLE) return false;
   
   if (CopyBuffer(atrHandle, 0, 0, lookback + 1, atrBuffer) <= 0) {
      IndicatorRelease(atrHandle);
      return false;
   }
   
   IndicatorRelease(atrHandle);
   
   // ATR đang mở rộng nếu giá trị hiện tại lớn hơn các giá trị trước đó
   return (atrBuffer[0] > atrBuffer[1] && atrBuffer[1] > atrBuffer[2]);
}

//+------------------------------------------------------------------+
//| Kiểm tra ATR đang co lại (giảm)                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsATRContracting(int lookback)
{
   if (lookback <= 0) lookback = m_DefaultATRLookback;
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   int atrHandle = iATR(m_Symbol, m_Timeframe, 14);
   if (atrHandle == INVALID_HANDLE) return false;
   
   if (CopyBuffer(atrHandle, 0, 0, lookback + 1, atrBuffer) <= 0) {
      IndicatorRelease(atrHandle);
      return false;
   }
   
   IndicatorRelease(atrHandle);
   
   // ATR đang co lại nếu giá trị hiện tại nhỏ hơn các giá trị trước đó
   return (atrBuffer[0] < atrBuffer[1] && atrBuffer[1] < atrBuffer[2]);
}

//+------------------------------------------------------------------+
//| Lấy Swing High gần nhất                                         |
//+------------------------------------------------------------------+
SwingPoint CMarketMonitor::GetLatestSwingHigh()
{
   SwingPoint emptyPoint = {0};
   
   // Duyệt qua các swing point đã lưu
   for (int i = 0; i < m_SwingCount; i++) {
      if (m_RecentSwings[i].isHigh) {
         return m_RecentSwings[i];
      }
   }
   
   return emptyPoint;
}

//+------------------------------------------------------------------+
//| Lấy Swing Low gần nhất                                          |
//+------------------------------------------------------------------+
SwingPoint CMarketMonitor::GetLatestSwingLow()
{
   SwingPoint emptyPoint = {0};
   
   // Duyệt qua các swing point đã lưu
   for (int i = 0; i < m_SwingCount; i++) {
      if (!m_RecentSwings[i].isHigh) {
         return m_RecentSwings[i];
      }
   }
   
   return emptyPoint;
}

//+------------------------------------------------------------------+
//| Tính khoảng cách đến Swing Point                                |
//+------------------------------------------------------------------+
double CMarketMonitor::GetDistanceToSwingPoint(bool high)
{
   double currentPrice = m_Cache.close;
   
   if (high) {
      SwingPoint swingHigh = GetLatestSwingHigh();
      if (swingHigh.price > 0) {
         return MathAbs(currentPrice - swingHigh.price);
      }
   }
   else {
      SwingPoint swingLow = GetLatestSwingLow();
      if (swingLow.price > 0) {
         return MathAbs(currentPrice - swingLow.price);
      }
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| Cập nhật Swing Points                                           |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateSwingPoints()
{
   // Nếu đây không phải là nến mới, bỏ qua
   if (!m_IsNewBar) return;
   
   // Lấy dữ liệu giá
   double high[], low[];
   long volume[];
   datetime time[];
   
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(volume, true);
   ArraySetAsSeries(time, true);
   
   if (CopyHigh(m_Symbol, m_Timeframe, 0, 50, high) <= 0 ||
       CopyLow(m_Symbol, m_Timeframe, 0, 50, low) <= 0 ||
       CopyTickVolume(m_Symbol, m_Timeframe, 0, 50, volume) <= 0 ||
       CopyTime(m_Symbol, m_Timeframe, 0, 50, time) <= 0) {
      return;
   }
   
   // Reset mảng swing points
   m_SwingCount = 0;
   
   // Tìm các swing points
   for (int i = 5; i < 30; i++) {
      // Tìm swing high
      if (IsLocalTop(high, i, 2)) {
         SwingPoint newPoint;
         newPoint.price = high[i];
         newPoint.time = time[i];
         newPoint.isHigh = true;
         newPoint.barIndex = i;
         newPoint.volume = volume[i];
         
         AddSwingPoint(newPoint);
      }
      
      // Tìm swing low
      if (IsLocalBottom(low, i, 2)) {
         SwingPoint newPoint;
         newPoint.price = low[i];
         newPoint.time = time[i];
         newPoint.isHigh = false;
         newPoint.barIndex = i;
         newPoint.volume = volume[i];
         
         AddSwingPoint(newPoint);
      }
      
      // Nếu đã tìm đủ 10 swing points, dừng lại
      if (m_SwingCount >= 10) break;
   }
   
   // Log thông tin nếu được bật
   if (m_Logger && m_Logger.IsDebugEnabled() && m_SwingCount > 0) {
      m_Logger.LogDebug(StringFormat("Đã tìm thấy %d swing points", m_SwingCount));
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra tín hiệu vào lệnh                                      |
//+------------------------------------------------------------------+
bool CMarketMonitor::CheckEntrySignal(SignalInfo &signal)
{
   // Reset thông tin tín hiệu
   ZeroMemory(signal);
   
   // Thiết lập thông tin cơ bản
   signal.symbol = m_Symbol;
   signal.signalTime = TimeCurrent();
   
   // Phân tích thị trường hiện tại
   ENUM_MARKET_PROFILE_TYPE marketProfile = m_MarketProfile;
   
   // Kiểm tra điều kiện vào lệnh dựa trên profile thị trường
   switch(marketProfile) {
      // Xu hướng mạnh
      case MARKET_PROFILE_STRONG_TREND:
         if (m_IsTrendUp) {
            // Tín hiệu BUY trong xu hướng tăng mạnh
            if (CheckBuySignalInStrongTrend(signal)) {
               return true;
            }
         }
         else if (m_IsTrendDown) {
            // Tín hiệu SELL trong xu hướng giảm mạnh
            if (CheckSellSignalInStrongTrend(signal)) {
               return true;
            }
         }
         break;
      
      // Xu hướng yếu
      case MARKET_PROFILE_WEAK_TREND:
         if (m_IsTrendUp) {
            // Tín hiệu BUY trong xu hướng tăng yếu
            if (CheckBuySignalInWeakTrend(signal)) {
               return true;
            }
         }
         else if (m_IsTrendDown) {
            // Tín hiệu SELL trong xu hướng giảm yếu
            if (CheckSellSignalInWeakTrend(signal)) {
               return true;
            }
         }
         break;
      
      // Thị trường sideway
      case MARKET_PROFILE_RANGING:
         // Tín hiệu BUY trong sideway
         if (CheckBuySignalInRangebound(signal)) {
            return true;
         }
         // Tín hiệu SELL trong sideway
         else if (CheckSellSignalInRangebound(signal)) {
            return true;
         }
         break;
      
      // Thị trường biến động mạnh
      case MARKET_PROFILE_VOLATILE:
         // Thị trường biến động cao, chỉ giao dịch với điều kiện nghiêm ngặt
         if (m_IsTrendUp && m_Cache.adx > 30) {
            // Tín hiệu BUY khi biến động cao nhưng xu hướng tăng mạnh
            if (CheckBuySignalInVolatileMarket(signal)) {
               return true;
            }
         }
         else if (m_IsTrendDown && m_Cache.adx > 30) {
            // Tín hiệu SELL khi biến động cao nhưng xu hướng giảm mạnh
            if (CheckSellSignalInVolatileMarket(signal)) {
               return true;
            }
         }
         break;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Lấy tín hiệu gần nhất                                          |
//+------------------------------------------------------------------+
bool CMarketMonitor::GetLastSignal(SignalInfo &signal)
{
   signal = m_LastSignal;
   return (m_LastSignal.signalTime > 0);
}

//+------------------------------------------------------------------+
//| Thiết lập ngưỡng ADX                                            |
//+------------------------------------------------------------------+
void CMarketMonitor::SetADXThresholds(double weakThreshold, double strongThreshold)
{
   m_ADX_WeakThreshold = weakThreshold;
   m_ADX_StrongThreshold = strongThreshold;
}

//+------------------------------------------------------------------+
//| Thiết lập ngưỡng volatility                                     |
//+------------------------------------------------------------------+
void CMarketMonitor::SetVolatilityThreshold(double threshold)
{
   m_VolatilityThreshold = threshold;
}

//+------------------------------------------------------------------+
//| Thiết lập ngưỡng range                                          |
//+------------------------------------------------------------------+
void CMarketMonitor::SetRangeThreshold(double threshold)
{
   m_RangeThreshold = threshold;
}

//+------------------------------------------------------------------+
//| Thiết lập ngưỡng volume ratio                                   |
//+------------------------------------------------------------------+
void CMarketMonitor::SetVolumeRatioThreshold(double threshold)
{
   m_VolumeRatioThreshold = threshold;
}

//+------------------------------------------------------------------+
//| Thiết lập lookback mặc định cho ATR                             |
//+------------------------------------------------------------------+
void CMarketMonitor::SetDefaultATRLookback(int lookback)
{
   m_DefaultATRLookback = lookback;
}

//+------------------------------------------------------------------+
//| Thiết lập ưu tiên xu hướng hơn biến động                         |
//+------------------------------------------------------------------+
void CMarketMonitor::SetPrioritizeTrendOverVolatility(bool prioritize)
{
   m_PrioritizeTrendOverVolatility = prioritize;
}

//+------------------------------------------------------------------+
//| Thiết lập sử dụng EMA Slope tương đối                           |
//+------------------------------------------------------------------+
void CMarketMonitor::SetUseRelativeEMASlope(bool useRelative)
{
   m_UseRelativeEMASlope = useRelative;
}

//+------------------------------------------------------------------+
//| Thiết lập tham số cho Spike Bar Detection                        |
//+------------------------------------------------------------------+
void CMarketMonitor::SetSpikeBarParameters(double bodyThreshold, double volumeThreshold, int lookback)
{
   m_SpikeBarBodyThreshold = bodyThreshold;
   m_SpikeBarVolumeThreshold = volumeThreshold;
   m_SpikeBarLookback = lookback;
}

//+------------------------------------------------------------------+
//| Kiểm tra Volume Spike tăng                                       |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolumeSpikeUp() const
{
   return m_CurrentVolumeSpikeUp;
}

//+------------------------------------------------------------------+
//| Kiểm tra Volume Spike giảm                                       |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolumeSpikeDown() const
{
   return m_CurrentVolumeSpikeDown;
}

//+------------------------------------------------------------------+
//| Kiểm tra Volume đang suy yếu                                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolumeWeakening() const
{
   return m_IsVolumeWeakening;
}

//+------------------------------------------------------------------+
//| Kiểm tra Volume gần Swing High                                  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolumeNearSwingHigh() const
{
   // Duyệt qua các swing high gần đây
   for (int i = 0; i < m_SwingCount; i++) {
      if (m_RecentSwings[i].isHigh) {
         // Kiểm tra thời gian của swing point này có gần không
         datetime currentTime = TimeCurrent();
         if (currentTime - m_RecentSwings[i].time < 12 * 3600) { // Trong vòng 12 giờ
            // Kiểm tra volume tại swing point này có cao không
            if (m_RecentSwings[i].volume > m_Cache.avg_volume * 1.5) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra Volume gần Swing Low                                   |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolumeNearSwingLow() const
{
   // Tương tự IsVolumeNearSwingHigh, nhưng dành cho swing low
   for (int i = 0; i < m_SwingCount; i++) {
      if (!m_RecentSwings[i].isHigh) {
         datetime currentTime = TimeCurrent();
         if (currentTime - m_RecentSwings[i].time < 12 * 3600) {
            if (m_RecentSwings[i].volume > m_Cache.avg_volume * 1.5) {
               return true;
            }
         }
      }
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA                                                 |
//+------------------------------------------------------------------+
double CMarketMonitor::CalculateEMASlope(int emaPeriod, int bars)
{
   // Sử dụng phương pháp thích hợp dựa trên cấu hình
   if (m_UseRelativeEMASlope) {
      return CalculateRelativeEMASlope(emaPeriod, bars);
   } else {
      return CalculateAbsoluteEMASlope(emaPeriod, bars);
   }
}

// Các phương thức kiểm tra tín hiệu buy/sell trong từng loại thị trường
// Đây chỉ là các hàm giả định, cần được cài đặt theo chiến lược riêng

bool CMarketMonitor::CheckBuySignalInStrongTrend(SignalInfo &signal) {
   // Chỉ cho ví dụ, cần thay thế bằng logic thực tế
   signal.isLong = true;
   signal.scenario = SCENARIO_STRONG_PULLBACK;
   signal.quality = 0.85;
   return false; // Trả về false vì đây chỉ là mẫu
}

bool CMarketMonitor::CheckSellSignalInStrongTrend(SignalInfo &signal) {
   signal.isLong = false;
   signal.scenario = SCENARIO_STRONG_PULLBACK;
   signal.quality = 0.85;
   return false;
}

bool CMarketMonitor::CheckBuySignalInWeakTrend(SignalInfo &signal) {
   signal.isLong = true;
   signal.scenario = SCENARIO_BULLISH_PULLBACK;
   signal.quality = 0.7;
   return false;
}

bool CMarketMonitor::CheckSellSignalInWeakTrend(SignalInfo &signal) {
   signal.isLong = false;
   signal.scenario = SCENARIO_BEARISH_PULLBACK;
   signal.quality = 0.7;
   return false;
}

bool CMarketMonitor::CheckBuySignalInRangebound(SignalInfo &signal) {
   signal.isLong = true;
   signal.scenario = SCENARIO_BULLISH_REVERSAL;
   signal.quality = 0.6;
   return false;
}

bool CMarketMonitor::CheckSellSignalInRangebound(SignalInfo &signal) {
   signal.isLong = false;
   signal.scenario = SCENARIO_BEARISH_REVERSAL;
   signal.quality = 0.6;
   return false;
}

bool CMarketMonitor::CheckBuySignalInVolatileMarket(SignalInfo &signal) {
   signal.isLong = true;
   signal.scenario = SCENARIO_LIQUIDITY_GRAB;
   signal.quality = 0.5;
   return false;
}

bool CMarketMonitor::CheckSellSignalInVolatileMarket(SignalInfo &signal) {
   signal.isLong = false;
   signal.scenario = SCENARIO_LIQUIDITY_GRAB;
   signal.quality = 0.5;
   return false;
}