//+------------------------------------------------------------------+
//|                                               MarketMonitor.mqh   |
//|                  Copyright 2023-2025, ApexTrading Systems        |
//|                         https://www.apextradingsystems.com       |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "12.0"

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
   ENUM_TIMEFRAMES      m_Timeframe;             // Khung thởi gian chính
   CLogger*             m_Logger;                // Đối tượng logger
   bool                 m_IsInitialized;         // Cờ theo dõi trạng thái khởi tạo
   
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
      
      // Dữ liệu thởi gian
      MqlDateTime time;          // Thời gian nến hiện tại
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
   
   // Market Context Memory (lưu trữ ngắn hạn thông tin thị trường)
   struct MarketContextHistory {
      ENUM_MARKET_PROFILE_TYPE profiles[10];  // Profile 10 nến gần nhất
      bool trendUp[10];                       // Trend 10 nến gần nhất
      bool trendDown[10];                     // Trend 10 nến gần nhất
      double atrRatio[10];                    // ATR ratio 10 nến gần nhất
      bool volumeSpike[10];                   // Volume spike 10 nến gần nhất
      int currentIndex;                       // Vị trí ghi hiện tại (circular buffer)
   };
   
   MarketContextHistory m_MarketHistory;      // Lưu trữ lịch sử thị trường
   
   // Biến cache và theo dõi cập nhật
   CachedData           m_Cache;                 // Cache dữ liệu indicator
   datetime             m_LastUpdateTime;        // Thời gian cập nhật gần nhất
   bool                 m_IsNewBar;              // Cờ đánh dấu nến mới
   
   // Biến trạng thái thị trường
   ENUM_MARKET_PROFILE_TYPE m_MarketProfile;     // Loại hình thái thị trường hiện tại
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
   bool                 Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
   
   // Cập nhật dữ liệu thị trường
   bool                 Update();
   void                 LightUpdate();  // Cập nhật nhẹ cho hiệu suất cao
   
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
   
   // Cài đặt tham số
   void                 SetADXThresholds(double weakThreshold, double strongThreshold);
   void                 SetVolatilityThreshold(double threshold);
   void                 SetRangeThreshold(double threshold);
   void                 SetVolumeRatioThreshold(double threshold);
   void                 SetDefaultATRLookback(int lookback);
   void                 SetPrioritizeTrendOverVolatility(bool prioritize);
   void                 SetUseRelativeEMASlope(bool useRelative);
   CLogger*             GetLogger() const { return m_Logger; }
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
   
   // Khởi tạo trạng thái thị trường
   m_MarketProfile = MARKET_PROFILE_UNKNOWN;
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
   
   // Khởi tạo cấu hình nâng cao
   m_PrioritizeTrendOverVolatility = true;  // Mặc định ưu tiên xu hướng mạnh hơn biến động
   m_UseRelativeEMASlope = true;            // Mặc định sử dụng độ dốc tương đối (%)
   m_DefaultATRLookback = 5;                // Lookback mặc định cho ATR là 5 nến
   
   // Khởi tạo swing points
   m_SwingCount = 0;
   
   // Khởi tạo cache EMA
   m_EmaCacheBars = 0;
   ArrayInitialize(m_EmaCache34, 0);
   ArrayInitialize(m_EmaCache89, 0);
   ArrayInitialize(m_EmaCache200, 0);
   
   // Khởi tạo đối tượng logger
   m_Logger = new CLogger("MarketMonitor");
   
   // Reset cấu trúc dữ liệu cache
   ZeroMemory(m_Cache);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketMonitor::~CMarketMonitor(void)
{
   // Giải phóng handle của các indicator
   ReleaseIndicators();
   
   // Giải phóng đối tượng logger
   if (m_Logger != NULL) {
      delete m_Logger;
      m_Logger = NULL;
   }
}

//+------------------------------------------------------------------+
//| Khởi tạo MarketMonitor với symbol và timeframe                   |
//+------------------------------------------------------------------+
bool CMarketMonitor::Initialize(string symbol, ENUM_TIMEFRAMES timeframe)
{
   // Lưu thông tin cơ bản
   m_Symbol = symbol;
   m_Timeframe = timeframe;
   
   // Kiểm tra logger và khởi tạo nếu cần
   if (m_Logger == NULL) {
      m_Logger = new CLogger("MarketMonitor");
      if (m_Logger == NULL) {
         Print("ERROR: Không thể tạo đối tượng Logger cho MarketMonitor");
         return false;
      }
   }
   
   // Khởi tạo các indicator
   if (!InitializeIndicators()) {
      m_Logger.LogError("Không thể khởi tạo các indicator");
      return false;
   }
   
   // Cập nhật dữ liệu ban đầu
   if (!UpdateIndicatorData()) {
      m_Logger.LogWarning("Cập nhật dữ liệu thị trường ban đầu thất bại - sẽ thử lại ở tick tiếp theo");
      // Tiếp tục khởi tạo ngay cả khi cập nhật đầu tiên thất bại
   }
   
   // Đánh dấu đã khởi tạo thành công
   m_IsInitialized = true;
   
   // Ghi log thông tin khởi tạo
   m_Logger.LogInfo(StringFormat(
      "MarketMonitor đã khởi tạo cho %s trên khung %s", 
      m_Symbol, 
      EnumToString(m_Timeframe)
   ));
   
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
      m_Logger.LogError("Không thể khởi tạo EMA 34: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA89 = iMA(m_Symbol, m_Timeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA89 == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo EMA 89: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA200 = iMA(m_Symbol, m_Timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA200 == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo EMA 200: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo RSI
   m_HandleRSI = iRSI(m_Symbol, m_Timeframe, m_RSI_Period, PRICE_CLOSE);
   if (m_HandleRSI == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo RSI: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo MACD
   m_HandleMACD = iMACD(m_Symbol, m_Timeframe, 12, 26, 9, PRICE_CLOSE);
   if (m_HandleMACD == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo MACD: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo Bollinger Bands
   m_HandleBB = iBands(m_Symbol, m_Timeframe, 20, 0, 2, PRICE_CLOSE);
   if (m_HandleBB == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo Bollinger Bands: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo ADX
   m_HandleADX = iADX(m_Symbol, m_Timeframe, m_ADX_Period);
   if (m_HandleADX == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo ADX: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Khởi tạo ATR
   m_HandleATR = iATR(m_Symbol, m_Timeframe, m_ATR_Period);
   if (m_HandleATR == INVALID_HANDLE) {
      m_Logger.LogError("Không thể khởi tạo ATR: " + IntegerToString(GetLastError()));
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
      m_Logger.LogError("Không thể sao chép dữ liệu giá: " + IntegerToString(GetLastError()));
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
      m_Logger.LogWarning("Không thể sao chép dữ liệu volume: " + IntegerToString(GetLastError()));
      // Không return false ở đây để vẫn đọc được các chỉ báo khác
   }
   
   // Cập nhật thởi gian
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), m_Cache.time);
   
   // Cập nhật các chỉ báo từ handle
   double buffer[];
   ArraySetAsSeries(buffer, true);
   
   // EMA 34
   if (SafeCopyBuffer(m_HandleEMA34, 0, 0, 1, buffer)) {
      m_Cache.ema34 = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật EMA 34: " + IntegerToString(GetLastError()));
   }
   
   // EMA 89
   if (SafeCopyBuffer(m_HandleEMA89, 0, 0, 1, buffer)) {
      m_Cache.ema89 = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật EMA 89: " + IntegerToString(GetLastError()));
   }
   
   // EMA 200
   if (SafeCopyBuffer(m_HandleEMA200, 0, 0, 1, buffer)) {
      m_Cache.ema200 = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật EMA 200: " + IntegerToString(GetLastError()));
   }
   
   // RSI
   if (SafeCopyBuffer(m_HandleRSI, 0, 0, 1, buffer)) {
      m_Cache.rsi = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật RSI: " + IntegerToString(GetLastError()));
   }
   
   // MACD (Main line)
   if (SafeCopyBuffer(m_HandleMACD, 0, 0, 1, buffer)) {
      m_Cache.macd = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật MACD (Main): " + IntegerToString(GetLastError()));
   }
   
   // MACD (Signal line)
   if (SafeCopyBuffer(m_HandleMACD, 1, 0, 1, buffer)) {
      m_Cache.macd_signal = buffer[0];
   } else {
      m_Logger.LogWarning("Không thể cập nhật MACD (Signal): " + IntegerToString(GetLastError()));
   }
   
   // ADX (Main line)
   if (SafeCopyBuffer(m_HandleADX, 0, 0, 1, buffer)) {
      m_Cache.adx = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật ADX: " + IntegerToString(GetLastError()));
   }
   
   // ADX (+DI line)
   if (SafeCopyBuffer(m_HandleADX, 1, 0, 1, buffer)) {
      m_Cache.adx_plus_di = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật ADX +DI: " + IntegerToString(GetLastError()));
   }
   
   // ADX (-DI line)
   if (SafeCopyBuffer(m_HandleADX, 2, 0, 1, buffer)) {
      m_Cache.adx_minus_di = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật ADX -DI: " + IntegerToString(GetLastError()));
   }
   
   // ATR
   if (SafeCopyBuffer(m_HandleATR, 0, 0, 20, buffer)) {
      m_Cache.atr = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật ATR: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Upper)
   if (SafeCopyBuffer(m_HandleBB, 1, 0, 1, buffer)) {
      m_Cache.bb_upper = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật Bollinger Upper: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Middle)
   if (SafeCopyBuffer(m_HandleBB, 0, 0, 1, buffer)) {
      m_Cache.bb_middle = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật Bollinger Middle: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Lower)
   if (SafeCopyBuffer(m_HandleBB, 2, 0, 1, buffer)) {
      m_Cache.bb_lower = buffer[0];
   } else {
      m_Logger.LogError("Không thể cập nhật Bollinger Lower: " + IntegerToString(GetLastError()));
   }
   
   // Cập nhật thởi gian lần đọc cuối cùng
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
      m_Logger.LogError("MarketMonitor chưa được khởi tạo");
      return false;
   }
   
   // Cập nhật dữ liệu indicator
   if (!UpdateIndicatorData()) {
      m_Logger.LogWarning("Không thể cập nhật dữ liệu indicator");
      return false;
   }
   
   // Cập nhật cache EMA
   UpdateEMACaches();
   
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
      
      // Cập nhật lịch sử thị trường
      UpdateMarketHistory();
      
      // Ghi log trạng thái thị trường nếu được bật debug
      if (m_Logger.IsDebugEnabled()) {
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
         
         m_Logger.LogDebug(StringFormat("[%s] Trạng thái thị trường: %s, Xu hướng: %s, ATR: %.5f, RSI: %.1f, ADX: %.1f", 
                                     m_Symbol, profileDesc, trend, m_Cache.atr, m_Cache.rsi, m_Cache.adx));
      }
   }
   
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
   // Lưu ý: Điều này có thể tốn thởi gian xử lý, chỉ sử dụng nếu cần thiết
   /*
   long currentVolume = 0;
   if (SymbolInfoInteger(m_Symbol, SYMBOL_VOLUME, currentVolume)) {
       m_Cache.volume = currentVolume;
   }
   */
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
            m_Logger.LogDebug("EMA caches được cập nhật thành công");
            return;
         }
      }
   }
   
   // Nếu không thể copy đủ 100 nến, thử với ít nến hơn
   if (SafeCopyBuffer(m_HandleEMA34, 0, 0, 50, m_EmaCache34)) {
      if (SafeCopyBuffer(m_HandleEMA89, 0, 0, 50, m_EmaCache89)) {
         if (SafeCopyBuffer(m_HandleEMA200, 0, 0, 50, m_EmaCache200)) {
            m_EmaCacheBars = 50;
            m_Logger.LogDebug("EMA caches được cập nhật thành công (50 nến)");
            return;
         }
      }
   }
   
   m_EmaCacheBars = 0;
   m_Logger.LogWarning("Không thể cập nhật EMA caches");
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
         // Giá trên EMA89 nhưng dướ
//+------------------------------------------------------------------+
//| Cập nhật lịch sử thị trường                                     |
//+------------------------------------------------------------------+
void CMarketMonitor::UpdateMarketHistory()
{
   // Chỉ cập nhật khi có nến mới
   if (!m_IsNewBar) return;
   
   // Lưu vị trí hiện tại
   int idx = m_MarketHistory.currentIndex;
   
   // Lưu thông tin thị trường hiện tại
   m_MarketHistory.profiles[idx] = m_MarketProfile;
   m_MarketHistory.trendUp[idx] = m_IsTrendUp;
   m_MarketHistory.trendDown[idx] = m_IsTrendDown;
   m_MarketHistory.atrRatio[idx] = CalculateATRRatio();
   m_MarketHistory.volumeSpike[idx] = IsVolumeSpikeUp() || IsVolumeSpikeDown();
   
   // Cập nhật vị trí cho lần sau (circular buffer)
   m_MarketHistory.currentIndex = (idx + 1) % 10;
}

//+------------------------------------------------------------------+
//| Phân tích nếu thị trường đang chuyển pha từ sideway sang trend   |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTransitioningToTrend()
{
   // Kiểm tra thị trường hiện tại đã là trending chưa
   if (m_MarketProfile == MARKET_PROFILE_STRONG_TREND || 
       m_MarketProfile == MARKET_PROFILE_WEAK_TREND)
   {
      // Đếm số nến gần đây là sideway
      int rangingCount = 0;
      int idx = m_MarketHistory.currentIndex;
      
      // Kiểm tra 5 nến gần nhất (trừ nến hiện tại)
      for (int i = 1; i <= 5; i++) {
         int pastIdx = (idx - i + 10) % 10;  // Quay ngược lại, tránh số âm
         
         if (m_MarketHistory.profiles[pastIdx] == MARKET_PROFILE_RANGING ||
             m_MarketHistory.profiles[pastIdx] == MARKET_PROFILE_ACCUMULATION ||
             m_MarketHistory.profiles[pastIdx] == MARKET_PROFILE_DISTRIBUTION)
         {
            rangingCount++;
         }
      }
      
      // Đang chuyển pha nếu có ít nhất 3/5 nến trước là sideway
      return (rangingCount >= 3);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Phân tích nếu thị trường đang chuyển pha từ trend sang sideway    |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsTransitioningToRanging()
{
   // Kiểm tra thị trường hiện tại đã là ranging chưa
   if (m_MarketProfile == MARKET_PROFILE_RANGING || 
       m_MarketProfile == MARKET_PROFILE_ACCUMULATION ||
       m_MarketProfile == MARKET_PROFILE_DISTRIBUTION)
   {
      // Đếm số nến gần đây là trend
      int trendCount = 0;
      int idx = m_MarketHistory.currentIndex;
      
      // Kiểm tra 5 nến gần nhất (trừ nến hiện tại)
      for (int i = 1; i <= 5; i++) {
         int pastIdx = (idx - i + 10) % 10;  // Quay ngược lại, tránh số âm
         
         if (m_MarketHistory.profiles[pastIdx] == MARKET_PROFILE_STRONG_TREND ||
             m_MarketHistory.profiles[pastIdx] == MARKET_PROFILE_WEAK_TREND)
         {
            trendCount++;
         }
      }
      
      // Đang chuyển pha nếu có ít nhất 3/5 nến trước là trend
      return (trendCount >= 3);
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu biến động thị trường đang tăng dần                  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolatilityIncreasing()
{
   // Kiểm tra chuỗi các giá trị ATR ratio
   int increasingCount = 0;
   int idx = m_MarketHistory.currentIndex;
   
   // Kiểm tra 5 nến gần nhất
   for (int i = 1; i < 5; i++) {
      int currentIdx = (idx - i + 10) % 10;
      int prevIdx = (idx - i - 1 + 10) % 10;
      
      if (m_MarketHistory.atrRatio[currentIdx] > m_MarketHistory.atrRatio[prevIdx]) {
         increasingCount++;
      }
   }
   
   // Biến động tăng nếu có ít nhất 3/4 lần so sánh cho thấy tăng
   return (increasingCount >= 3);
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu biến động thị trường đang giảm dần                  |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsVolatilityDecreasing()
{
   // Kiểm tra chuỗi các giá trị ATR ratio
   int decreasingCount = 0;
   int idx = m_MarketHistory.currentIndex;
   
   // Kiểm tra 5 nến gần nhất
   for (int i = 1; i < 5; i++) {
      int currentIdx = (idx - i + 10) % 10;
      int prevIdx = (idx - i - 1 + 10) % 10;
      
      if (m_MarketHistory.atrRatio[currentIdx] < m_MarketHistory.atrRatio[prevIdx]) {
         decreasingCount++;
      }
   }
   
   // Biến động giảm nếu có ít nhất 3/4 lần so sánh cho thấy giảm
   return (decreasingCount >= 3);
}