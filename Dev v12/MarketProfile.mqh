//+------------------------------------------------------------------+
//| MarketProfile.mqh                                              |
//| Mô tả: Phân tích profile thị trường cho EA ApexPullback        |
//| Copyright 2023-2025, ApexTrading Systems                        |
//+------------------------------------------------------------------+
#pragma once

#include <Trade\Trade.mqh>  // Để lấy thông tin giá, spread
#include "CommonStructs.mqh" // Lấy enum và struct dùng chung
#include "Logger.mqh"       // Hệ thống log

// Enum phiên giao dịch nếu chưa có trong CommonStructs.mqh
#ifndef ENUM_SESSION_TYPE_DEFINED
#define ENUM_SESSION_TYPE_DEFINED
enum ENUM_SESSION_TYPE {
   SESSION_UNKNOWN,           // Không xác định
   SESSION_ASIAN,             // Phiên Á (00:00-08:00 GMT)
   SESSION_EUROPEAN,          // Phiên Âu (08:00-16:00 GMT)
   SESSION_AMERICAN,          // Phiên Mỹ (13:00-21:00 GMT)
   SESSION_EUROPEAN_AMERICAN, // Phiên giao thoa Âu-Mỹ (13:00-16:00 GMT)
   SESSION_CLOSING            // Phiên đóng cửa
};
#endif

// Enum pha thị trường nếu chưa có trong CommonStructs.mqh
#ifndef ENUM_MARKET_PHASE_DEFINED
#define ENUM_MARKET_PHASE_DEFINED
enum ENUM_MARKET_PHASE {
   PHASE_ACCUMULATION,    // Tích lũy
   PHASE_IMPULSE,         // Sóng đẩy mạnh
   PHASE_CORRECTION,      // Điều chỉnh
   PHASE_DISTRIBUTION,    // Phân phối
   PHASE_EXHAUSTION,      // Cạn kiệt
   PHASE_DOWN_ACCUMULATION // Tích lũy xuống
};
#endif

//+------------------------------------------------------------------+
//| Class CMarketProfile                                            |
//| Phân tích bối cảnh thị trường cho ApexPullback EA               |
//+------------------------------------------------------------------+
class CMarketProfile
{
private:
   // Thông tin cơ bản
   string            m_symbol;             // Symbol đang phân tích
   ENUM_TIMEFRAMES   m_timeframe;          // Timeframe chính để phân tích
   CLogger*          m_logger;             // Hệ thống log
   
   // Thông tin thời gian
   int               m_GMT_Offset;         // Độ lệch múi giờ
   datetime          m_lastUpdateTime;     // Thời gian cập nhật cuối cùng
   
   // Trạng thái khởi tạo
   bool              m_isInitialized;      // Trạng thái khởi tạo
   bool              m_isDataReliable;     // Trạng thái dữ liệu có đáng tin cậy không
   int               m_failedUpdatesCount; // Số lần cập nhật thất bại liên tiếp
   int               m_maxConsecutiveFailedUpdates; // Số lần thất bại tối đa trước khi đánh dấu dữ liệu không đáng tin cậy
   
   // Handles chỉ báo
   int               m_handleADX_H1;       // Handle ADX H1
   int               m_handleADX_H4;       // Handle ADX H4
   int               m_handleATR_H1;       // Handle ATR H1
   int               m_handleEMA34_H1;     // Handle EMA34 H1
   int               m_handleEMA89_H1;     // Handle EMA89 H1
   int               m_handleEMA200_H1;    // Handle EMA200 H1
   int               m_handleRSI_H1;       // Handle RSI H1
   int               m_handleMACD_H1;      // Handle MACD H1
   
   // Dữ liệu chỉ báo
   double            m_adxH1;              // Giá trị ADX H1
   double            m_adxPrev;            // Giá trị ADX H1 trước đó
   double            m_adxH4;              // Giá trị ADX H4
   double            m_atrH1;              // Giá trị ATR H1
   double            m_atrRatio;           // Tỷ lệ ATR hiện tại/trung bình
   double            m_slopeEMA34H1;       // Độ dốc EMA34 H1
   double            m_emaSlope_prev;      // Độ dốc EMA34 trước đó
   double            m_distanceEMA89_200_H1; // Khoảng cách giữa EMA89 và EMA200
   double            m_recentSwingHigh;    // Giá trị swing high gần đây
   double            m_recentSwingLow;     // Giá trị swing low gần đây
   double            m_rsiH1;              // Giá trị RSI H1
   double            m_rsiOverboughtThreshold; // Ngưỡng quá mua RSI
   double            m_rsiOversoldThreshold;   // Ngưỡng quá bán RSI
   double            m_macdMain;           // Đường MACD chính
   double            m_macdSignal;         // Đường tín hiệu MACD
   double            m_macdHistogram;      // Histogram MACD
   double            m_macdHistogramPrev;  // Histogram MACD trước đó
   
   // Thông tin volume
   double            m_volumeCurrent;      // Volume hiện tại
   double            m_volumeSMA20;        // Volume trung bình 20 nến
   bool              m_hasVolumeSpike;     // Đánh dấu có đột biến volume
   
   // Phân tích thống kê
   double            m_avgEMASlope;        // Trung bình độ dốc EMA
   double            m_emaSlopeStdDev;     // Độ lệch chuẩn độ dốc EMA
   double            m_emaSlopeAvg;        // Trung bình độ dốc (dùng cho thống kê)
   
   // Ngưỡng và tham số (có thể tham số hóa)
   int               m_EMASlopePeriodsH1;  // Số nến dùng để tính độ dốc
   double            m_strongTrendThreshold; // Ngưỡng xu hướng mạnh
   double            m_weakTrendThreshold;   // Ngưỡng xu hướng yếu
   double            m_volatilityThreshold;  // Ngưỡng biến động
   double            m_volumeSpikeThreshold; // Ngưỡng đột biến volume
   
   // Ngưỡng động (được tính toán dựa trên dữ liệu thị trường)
   double            m_dynamicAccumulationThreshold;   // Ngưỡng động cho pha tích lũy
   double            m_dynamicImpulseThreshold;        // Ngưỡng động cho pha xung lực
   double            m_dynamicCorrectionThreshold;     // Ngưỡng động cho pha điều chỉnh
   double            m_dynamicDistributionThreshold;   // Ngưỡng động cho pha phân phối
   double            m_dynamicExhaustionThreshold;     // Ngưỡng động cho pha cạn kiệt
   
   // Trạng thái thị trường
   bool              m_isTrending;         // Thị trường đang có xu hướng
   bool              m_isWeakTrend;        // Thị trường đang có xu hướng yếu
   bool              m_isSideway;          // Thị trường đang sideway
   bool              m_isVolatile;         // Thị trường đang biến động mạnh
   bool              m_isRangebound;       // Thị trường đang dao động trong biên độ
   
   // Phiên và pha thị trường
   ENUM_SESSION_TYPE m_currentSession;     // Phiên giao dịch hiện tại
   ENUM_MARKET_PHASE m_marketPhase;        // Pha thị trường hiện tại
   
   // Biến theo dõi
   bool              m_isOverbought;       // Thị trường quá mua
   bool              m_isOversold;         // Thị trường quá bán
   
private:
   // Phương thức khởi tạo và giải phóng chỉ báo
   bool              InitializeIndicators();
   void              ReleaseIndicators();
   
   // Phương thức cập nhật dữ liệu chỉ báo
   bool              UpdateIndicatorData();
   
   // Phương thức phân tích thị trường
   void              AnalyzeMarketConditions();
   
   // Các phương thức trợ giúp
   double            CalculateSlopeEMA34();
   double            CalculateDistanceEMA89_200();
   ENUM_SESSION_TYPE DetermineCurrentSession();
   ENUM_MARKET_PHASE DetermineMarketPhase();
   bool              DetectVolumeSpike();
   bool              DetectVolatility();
   bool              DetectWeakTrend();
   bool              DetectSideway();
   bool              DetectRangebound();
   
   // Phương thức đọc dữ liệu chỉ báo an toàn
   bool              SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[]);
   bool              SafeCopyVolume(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, long &array[]);
   
   // Phương thức tính toán thống kê độ dốc EMA
   void              CalculateEMASlopeStatistics();
   
   // Phương thức cập nhật ngưỡng động
   void              UpdateDynamicThresholds();
   
   // Phương thức kiểm tra trạng thái quá mua/quá bán từ RSI
   bool              IsOverbought() const;
   bool              IsOversold() const;
   
   // Phương thức kiểm tra xu hướng tăng/giảm từ MACD
   bool              IsMACDUptrend() const;
   bool              IsMACDDowntrend() const;
   
   // Phương thức kiểm tra MACD đang phân kỳ
   bool              IsMACDDiverging() const;
   
   // Phương thức cập nhật điểm swing cao/thấp gần đây
   void              UpdateSwingPoints();
   
public:
   // Constructor/destructor
                     CMarketProfile();
                    ~CMarketProfile();
   
   // Phương thức khởi tạo
   bool              Initialize(string symbol, ENUM_TIMEFRAMES timeframe = PERIOD_H1, int gmt_offset = 0);
   
   // Phương thức thiết lập tham số
   void              SetVolatilityThreshold(double threshold) { m_volatilityThreshold = (threshold > 0) ? threshold : 1.5; }
   void              SetVolumeSpikeThreshold(double threshold) { m_volumeSpikeThreshold = (threshold > 0) ? threshold : 2.0; }
   void              SetWeakTrendThreshold(double threshold) { m_weakTrendThreshold = (threshold > 0) ? threshold : 20.0; }
   void              SetStrongTrendThreshold(double threshold) { m_strongTrendThreshold = (threshold > 0) ? threshold : 25.0; }
   void              SetOverboughtThreshold(double threshold) { m_rsiOverboughtThreshold = (threshold > 50) ? threshold : 70.0; }
   void              SetOversoldThreshold(double threshold) { m_rsiOversoldThreshold = (threshold < 50) ? threshold : 30.0; }
   void              SetMaxConsecutiveFailedUpdates(int count) { m_maxConsecutiveFailedUpdates = (count > 0) ? count : 3; }
   void              SetEMASlopePeriodsH1(int periods) { m_EMASlopePeriodsH1 = (periods > 0) ? periods : 5; }
   void              SetGMTOffset(int offset) { m_GMT_Offset = offset; }
   
   // Phương thức thiết lập tất cả tham số
   void              SetParameters(double volatilityThreshold, double volumeSpikeThreshold, 
                                 double weakTrendThreshold, double strongTrendThreshold,
                                 double overboughtThreshold, double oversoldThreshold,
                                 int maxConsecutiveFailedUpdates, int emaSlopePeriods,
                                 int gmtOffset);
   
   // Phương thức cập nhật
   bool              Update();
   bool              LightUpdate(); // Cập nhật nhẹ không tính toán lại tất cả
   
   // Getters cho trạng thái thị trường
   bool              IsTrending() const { return m_isTrending; }
   bool              IsSideway() const { return m_isSideway; }
   bool              IsVolatile() const { return m_isVolatile; }
   bool              IsWeakTrend() const { return m_isWeakTrend; }
   bool              IsRangebound() const { return m_isRangebound; }
   bool              HasVolumeSpike() const { return m_hasVolumeSpike; }
   
   // Getters cho các chỉ báo và giá trị phân tích
   double            GetADXH1() const { return m_adxH1; }
   double            GetADXH4() const { return m_adxH4; }
   double            GetATRH1() const { return m_atrH1; }
   double            GetVolumeCurrent() const { return m_volumeCurrent; }
   double            GetVolumeSMA20() const { return m_volumeSMA20; }
   double            GetSlopeEMA34() const { return m_slopeEMA34H1; }
   double            GetDistanceEMA() const { return m_distanceEMA89_200_H1; }
   double            GetATRRatio() const { return m_atrRatio; }
   ENUM_SESSION_TYPE GetCurrentSession() const { return m_currentSession; }
   ENUM_MARKET_PHASE GetMarketPhase() const { return m_marketPhase; }
   
   // Phương thức trợ giúp
   void              LogMarketProfile();
   string            GetMarketProfileSummary();
   ENUM_MARKET_REGIME GetMarketRegimeBasedOnProfile();
   
   // Getter cho điểm swing cao/thấp gần đây
   double            GetRecentSwingHigh() const;
   double            GetRecentSwingLow() const;
   
   // Getter cho trạng thái đáng tin cậy của dữ liệu
   bool              IsDataReliable() const;
   
   // Kiểm tra nếu giá gần mức hỗ trợ/kháng cự quan trọng
   bool              IsNearKeyLevel() const;
   
   // Kiểm tra phân kỳ tăng
   bool              HasBullishDivergence() const;
   
   // Kiểm tra phân kỳ giảm
   bool              HasBearishDivergence() const;
   
   // Kiểm tra momentum dương
   bool              HasPositiveMomentum(bool isLong) const;
   
   // Kiểm tra giá gần EMA
   bool              IsPriceNearEma(bool isLong) const;
   
   // Kiểm tra hỗ trợ quan trọng
   bool              HasKeySupport() const;
   
   // Kiểm tra kháng cự quan trọng
   bool              HasKeyResistance() const;
   
   // Kiểm tra xu hướng tăng
   bool              IsTrendUp() const;
   
   // Kiểm tra xu hướng giảm
   bool              IsTrendDown() const;
   
   // Kiểm tra xu hướng mạnh
   bool              IsStrongTrend() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketProfile::CMarketProfile()
{
   // Khởi tạo biến thành viên với giá trị mặc định
   m_symbol = Symbol();
   m_timeframe = PERIOD_H1;
   m_logger = NULL;
   
   // Khởi tạo handle chỉ báo với INVALID_HANDLE
   m_handleADX_H1 = INVALID_HANDLE;
   m_handleADX_H4 = INVALID_HANDLE;
   m_handleATR_H1 = INVALID_HANDLE;
   m_handleEMA34_H1 = INVALID_HANDLE;
   m_handleEMA89_H1 = INVALID_HANDLE;
   m_handleEMA200_H1 = INVALID_HANDLE;
   m_handleRSI_H1 = INVALID_HANDLE;
   m_handleMACD_H1 = INVALID_HANDLE;
   
   // Khởi tạo dữ liệu thị trường
   m_adxH1 = 0.0;
   m_adxPrev = 0.0;
   m_adxH4 = 0.0;
   m_atrH1 = 0.0;
   m_atrRatio = 1.0;
   m_slopeEMA34H1 = 0.0;
   m_emaSlope_prev = 0.0;
   m_distanceEMA89_200_H1 = 0.0;
   m_recentSwingHigh = 0.0;
   m_recentSwingLow = 0.0;
   m_rsiH1 = 50.0;
   m_rsiOverboughtThreshold = 70.0;
   m_rsiOversoldThreshold = 30.0;
   m_macdMain = 0.0;
   m_macdSignal = 0.0;
   m_macdHistogram = 0.0;
   m_macdHistogramPrev = 0.0;
   m_avgEMASlope = 0.0;
   m_emaSlopeStdDev = 0.1;
   
   // Khởi tạo ngưỡng động
   m_dynamicAccumulationThreshold = 0.1;
   m_dynamicImpulseThreshold = 0.3;
   m_dynamicCorrectionThreshold = 0.2;
   m_dynamicDistributionThreshold = -0.1;
   m_dynamicExhaustionThreshold = 0.5;
   
   // Thiết lập tham số mặc định
   m_EMASlopePeriodsH1 = 10;
   m_volatilityThreshold = 1.5;
   m_volumeSpikeThreshold = 1.5;
   m_GMT_Offset = 0;
   m_strongTrendThreshold = 25.0;
   m_weakTrendThreshold = 18.0;
   m_maxConsecutiveFailedUpdates = 3; // Cho phép tối đa 3 lần cập nhật thất bại liên tiếp
   
   // Tạo logger
   m_logger = new CLogger("MarketProfile");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketProfile::~CMarketProfile()
{
   // Giải phóng chỉ báo
   ReleaseIndicators();
   
   // Giải phóng logger
   if (m_logger != NULL) {
      delete m_logger;
      m_logger = NULL;
   }
}

//+------------------------------------------------------------------+
//| Khởi tạo MarketProfile                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int gmt_offset)
{
   // Lưu thông tin cơ bản
   m_symbol = symbol;
   m_timeframe = timeframe;
   m_GMT_Offset = gmt_offset;
   
   // Kiểm tra symbol
   if (m_symbol == "") {
      if (m_logger != NULL) {
         m_logger.LogError("Không thể khởi tạo MarketProfile: Symbol không hợp lệ");
      }
      return false;
   }
   
   // Khởi tạo logger nếu chưa được tạo
   if (m_logger == NULL) {
      m_logger = new CLogger("MarketProfile");
      if (m_logger == NULL) {
         Print("ERROR: Không thể tạo logger cho MarketProfile");
         return false;
      }
   }
   
   // Khởi tạo các chỉ báo
   if (!InitializeIndicators()) {
      m_logger.LogError("Không thể khởi tạo các chỉ báo");
      return false;
   }
   
   // Cập nhật dữ liệu lần đầu
   if (!UpdateIndicatorData()) {
      m_logger.LogWarning("Cập nhật dữ liệu lần đầu không thành công");
      // Vẫn tiếp tục vì có thể thành công trong lần cập nhật sau
   }
   
   m_isInitialized = true;
   m_logger.LogInfo(StringFormat(
      "MarketProfile đã khởi tạo thành công cho %s trên timeframe %s", 
      m_symbol, 
      EnumToString(m_timeframe)
   ));
   
   return true;
}

//+------------------------------------------------------------------+
//| Thiết lập các ngưỡng xu hướng                                    |
//+------------------------------------------------------------------+
void CMarketProfile::SetTrendThresholds(double strongThreshold, double weakThreshold)
{
   // Đảm bảo ngưỡng xu hướng mạnh > ngưỡng xu hướng yếu
   m_strongTrendThreshold = MathMax(strongThreshold, weakThreshold + 5.0);
   m_weakTrendThreshold = weakThreshold;
   
   if (m_logger != NULL) {
      m_logger.LogInfo(StringFormat(
         "Thiết lập ngưỡng xu hướng: Mạnh=%.1f, Yếu=%.1f", 
         m_strongTrendThreshold, m_weakTrendThreshold
      ));
   }
}

//+------------------------------------------------------------------+
//| Thiết lập tất cả tham số cùng lúc                                |
//+------------------------------------------------------------------+
void CMarketProfile::SetParameters(double volatilityThreshold, double volumeSpikeThreshold, 
                                 double weakTrendThreshold, double strongTrendThreshold,
                                 double overboughtThreshold, double oversoldThreshold,
                                 int maxConsecutiveFailedUpdates, int emaSlopePeriods,
                                 int gmtOffset)
{
   // Thiết lập các ngưỡng cơ bản
   SetVolatilityThreshold(volatilityThreshold);
   SetVolumeSpikeThreshold(volumeSpikeThreshold);
   SetWeakTrendThreshold(weakTrendThreshold);
   SetStrongTrendThreshold(strongTrendThreshold);
   SetOverboughtThreshold(overboughtThreshold);
   SetOversoldThreshold(oversoldThreshold);
   
   // Thiết lập các tham số khác
   SetMaxConsecutiveFailedUpdates(maxConsecutiveFailedUpdates);
   SetEMASlopePeriodsH1(emaSlopePeriods);
   SetGMTOffset(gmtOffset);
   
   // Log thông tin tham số
   if (m_logger != NULL) {
      m_logger.LogInfo(StringFormat("Cập nhật tham số MarketProfile: Vol=%.2f, VolSpike=%.2f, ADX(W/S)=%.1f/%.1f, RSI(O/S)=%.1f/%.1f", 
                    m_volatilityThreshold, m_volumeSpikeThreshold, 
                    m_weakTrendThreshold, m_strongTrendThreshold,
                    m_rsiOverboughtThreshold, m_rsiOversoldThreshold));
   }
   
   // Khởi tạo các ngưỡng động với giá trị mặc định
   // Các giá trị này sẽ được cập nhật động sau khi có đủ dữ liệu
   m_dynamicAccumulationThreshold = 0.1;
   m_dynamicImpulseThreshold = 0.3;
   m_dynamicCorrectionThreshold = 0.2;
   m_dynamicDistributionThreshold = -0.1;
   m_dynamicExhaustionThreshold = 0.5;
}

//+------------------------------------------------------------------+
//| Khởi tạo các chỉ báo                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::InitializeIndicators()
{
   // Giải phóng chỉ báo cũ nếu có
   ReleaseIndicators();
   
   // Khởi tạo ADX H1
   m_handleADX_H1 = iADX(m_symbol, PERIOD_H1, 14);
   if (m_handleADX_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo ADX H1");
      return false;
   }
   
   // Khởi tạo ADX H4
   m_handleADX_H4 = iADX(m_symbol, PERIOD_H4, 14);
   if (m_handleADX_H4 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo ADX H4");
      return false;
   }
   
   // Khởi tạo ATR H1
   m_handleATR_H1 = iATR(m_symbol, PERIOD_H1, 14);
   if (m_handleATR_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo ATR H1");
      return false;
   }
   
   // Khởi tạo EMA H1
   m_handleEMA34_H1 = iMA(m_symbol, PERIOD_H1, 34, 0, MODE_EMA, PRICE_CLOSE);
   if (m_handleEMA34_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo EMA 34 H1");
      return false;
   }
   
   m_handleEMA89_H1 = iMA(m_symbol, PERIOD_H1, 89, 0, MODE_EMA, PRICE_CLOSE);
   if (m_handleEMA89_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo EMA 89 H1");
      return false;
   }
   
   m_handleEMA200_H1 = iMA(m_symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
   if (m_handleEMA200_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo EMA 200 H1");
      return false;
   }
   
   // Khởi tạo RSI H1
   m_handleRSI_H1 = iRSI(m_symbol, PERIOD_H1, 14, PRICE_CLOSE);
   if (m_handleRSI_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo RSI H1");
      return false;
   }
   
   // Khởi tạo MACD H1
   m_handleMACD_H1 = iMACD(m_symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
   if (m_handleMACD_H1 == INVALID_HANDLE) {
      m_logger.LogError("Không thể khởi tạo MACD H1");
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Giải phóng chỉ báo                                               |
//+------------------------------------------------------------------+
void CMarketProfile::ReleaseIndicators()
{
   // Giải phóng chỉ báo H1
   if (m_handleADX_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleADX_H1);
      m_handleADX_H1 = INVALID_HANDLE;
   }
   
   if (m_handleATR_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleATR_H1);
      m_handleATR_H1 = INVALID_HANDLE;
   }
   
   if (m_handleEMA34_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleEMA34_H1);
      m_handleEMA34_H1 = INVALID_HANDLE;
   }
   
   if (m_handleEMA89_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleEMA89_H1);
      m_handleEMA89_H1 = INVALID_HANDLE;
   }
   
   if (m_handleEMA200_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleEMA200_H1);
      m_handleEMA200_H1 = INVALID_HANDLE;
   }
   
   // Giải phóng chỉ báo bổ sung
   if (m_handleRSI_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleRSI_H1);
      m_handleRSI_H1 = INVALID_HANDLE;
   }
   
   if (m_handleMACD_H1 != INVALID_HANDLE) {
      IndicatorRelease(m_handleMACD_H1);
      m_handleMACD_H1 = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Sao chép buffer chỉ báo an toàn                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[])
{
   // Kiểm tra handle hợp lệ
   if (handle == INVALID_HANDLE) {
      m_logger.LogError("SafeCopyBuffer: Handle không hợp lệ");
      return false;
   }
   
   // Khởi tạo mảng
   if (ArraySize(array) < count) {
      if (ArrayResize(array, count) == -1) {
         m_logger.LogError("SafeCopyBuffer: Không thể thay đổi kích thước mảng");
         return false;
      }
   }
   
   // Thử copy dữ liệu
   int copied = CopyBuffer(handle, buffer, startPos, count, array);
   
   // Kiểm tra kết quả
   if (copied != count) {
      m_logger.LogError("SafeCopyBuffer: Sao chép thất bại, yêu cầu " + 
                       IntegerToString(count) + ", đã copy " + IntegerToString(copied));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Sao chép dữ liệu volume an toàn                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::SafeCopyVolume(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, long &array[])
{
   // Kiểm tra tham số
   if (symbol == "" || timeframe == 0) {
      m_logger.LogError("SafeCopyVolume: Tham số không hợp lệ");
      return false;
   }
   
   // Khởi tạo mảng
   if (ArraySize(array) < count) {
      if (ArrayResize(array, count) == -1) {
         m_logger.LogError("SafeCopyVolume: Không thể thay đổi kích thước mảng");
         return false;
      }
   }
   
   // Thử copy dữ liệu
   int copied = CopyTickVolume(symbol, timeframe, startPos, count, array);
   
   // Kiểm tra kết quả
   if (copied != count) {
      m_logger.LogError("SafeCopyVolume: Sao chép thất bại, yêu cầu " + 
                       IntegerToString(count) + ", đã copy " + IntegerToString(copied));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Cập nhật dữ liệu chỉ báo                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::UpdateIndicatorData()
{
   // Kiểm tra khởi tạo
   if (!m_isInitialized) {
      m_logger.LogError("Không thể cập nhật: MarketProfile chưa được khởi tạo");
      return false;
   }
   
   bool updateSuccessful = true; // Biến theo dõi thành công tổng thể
   bool criticalError = false;   // Biến theo dõi lỗi nghiêm trọng
   
   // Cập nhật ADX H1
   double adxBuffer[];
   ArraySetAsSeries(adxBuffer, true);
   if (!SafeCopyBuffer(m_handleADX_H1, 0, 0, 1, adxBuffer)) {
      m_logger.LogError("Không thể cập nhật ADX H1 - chỉ báo quan trọng");
      criticalError = true;
      updateSuccessful = false;
   } else {
      m_adxH1 = adxBuffer[0];
   }
   
   // Cập nhật ADX H4
   if (!SafeCopyBuffer(m_handleADX_H4, 0, 0, 1, adxBuffer)) {
      m_logger.LogError("Không thể cập nhật ADX H4 - chỉ báo quan trọng");
      criticalError = true;
      updateSuccessful = false;
   } else {
      m_adxH4 = adxBuffer[0];
   }
   
   // Cập nhật ATR H1
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 1, atrBuffer)) {
      m_logger.LogError("Không thể cập nhật ATR H1 - chỉ báo quan trọng");
      criticalError = true;
      updateSuccessful = false;
   } else {
      m_atrH1 = atrBuffer[0];
   }
   
   // Cập nhật EMA34 H1
   double ema34Buffer[];
   ArraySetAsSeries(ema34Buffer, true);
   if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, m_EMASlopePeriodsH1 + 1, ema34Buffer)) {
      m_logger.LogWarning("Không thể cập nhật EMA34 H1");
      updateSuccessful = false;
   } else {
      // Tính độ dốc EMA34
      m_slopeEMA34H1 = CalculateSlopeEMA34();
   }
   
   // Cập nhật EMA89 và EMA200 H1 để tính khoảng cách
   double ema89Buffer[], ema200Buffer[];
   ArraySetAsSeries(ema89Buffer, true);
   ArraySetAsSeries(ema200Buffer, true);
   bool emaUpdated = SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89Buffer) && 
                    SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200Buffer);
   
   if (!emaUpdated) {
      m_logger.LogWarning("Không thể cập nhật EMA89/EMA200 H1");
      updateSuccessful = false;
   } else {
      // Tính khoảng cách EMA89-EMA200
      m_distanceEMA89_200_H1 = (ema89Buffer[0] - ema200Buffer[0]) / m_atrH1;
   }
   
   // Cập nhật RSI
   double rsiBuffer[];
   ArraySetAsSeries(rsiBuffer, true);
   if (!SafeCopyBuffer(m_handleRSI_H1, 0, 0, 1, rsiBuffer)) {
      m_logger.LogWarning("Không thể cập nhật RSI H1");
      updateSuccessful = false;
   } else {
      m_rsiH1 = rsiBuffer[0];
   }
   
   // Cập nhật MACD
   double macdMainBuffer[], macdSignalBuffer[], macdHistogramBuffer[];
   ArraySetAsSeries(macdMainBuffer, true);
   ArraySetAsSeries(macdSignalBuffer, true);
   
   bool macdUpdated = SafeCopyBuffer(m_handleMACD_H1, 0, 0, 1, macdMainBuffer) &&
                     SafeCopyBuffer(m_handleMACD_H1, 1, 0, 1, macdSignalBuffer);
   
   if (!macdUpdated) {
      m_logger.LogWarning("Không thể cập nhật MACD H1");
      updateSuccessful = false;
   } else {
      m_macdMain = macdMainBuffer[0];
      m_macdSignal = macdSignalBuffer[0];
      m_macdHistogram = m_macdMain - m_macdSignal;
   }
   
   // Cập nhật volume
   long volumeBuffer[];
   ArraySetAsSeries(volumeBuffer, true);
   if (!SafeCopyVolume(m_symbol, PERIOD_H1, 0, 21, volumeBuffer)) {
      m_logger.LogWarning("Không thể cập nhật Volume");
      updateSuccessful = false;
   } else {
      m_volumeCurrent = (double)volumeBuffer[0];
      
      // Tính trung bình volume 20 nến
      double sumVolume = 0;
      for (int i = 1; i <= 20; i++) {
         sumVolume += (double)volumeBuffer[i];
      }
      m_volumeSMA20 = sumVolume / 20.0;
      
      // Kiểm tra volume spike
      m_hasVolumeSpike = DetectVolumeSpike();
   }
   
   // Cập nhật tỷ lệ ATR
   if (m_atrH1 > 0) {
      // Lấy dữ liệu ATR cho 20 nến
      double atrHistoryBuffer[];
      ArraySetAsSeries(atrHistoryBuffer, true);
      if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 21, atrHistoryBuffer)) {
         m_logger.LogWarning("Không thể cập nhật lịch sử ATR");
         updateSuccessful = false;
      } else {
         // Tính trung bình ATR 20 nến
         double sumATR = 0;
         for (int i = 1; i <= 20; i++) {
            sumATR += atrHistoryBuffer[i];
         }
         double avgATR = sumATR / 20.0;
         
         // Tính tỷ lệ ATR hiện tại/trung bình
         if (avgATR > 0) {
            m_atrRatio = m_atrH1 / avgATR;
         }
      }
   }
   
   // Cập nhật độ dốc EMA trung bình và độ lệch chuẩn
   CalculateEMASlopeStatistics();
   
   // Cập nhật các ngưỡng động
   UpdateDynamicThresholds();
   
   // Cập nhật swing high/low gần đây
   UpdateSwingPoints();
   
   // Xử lý kết quả cập nhật
   if (criticalError) {
      m_failedUpdatesCount++;
      m_logger.LogError("Lỗi nghiêm trọng khi cập nhật dữ liệu. Lần thất bại thứ " + 
                      IntegerToString(m_failedUpdatesCount) + "/" + 
                      IntegerToString(m_maxConsecutiveFailedUpdates));
      
      // Đánh dấu dữ liệu không đáng tin cậy sau nhiều lần cập nhật thất bại
      if (m_failedUpdatesCount >= m_maxConsecutiveFailedUpdates) {
         m_isDataReliable = false;
         m_logger.LogError("Dữ liệu thị trường không đáng tin cậy sau " + 
                         IntegerToString(m_failedUpdatesCount) + " lần cập nhật thất bại!");
      }
      
      return false;
   }
   
   // Nếu cập nhật thành công, reset biến đếm lỗi
   if (updateSuccessful) {
      if (m_failedUpdatesCount > 0) {
         m_logger.LogInfo("Cập nhật thành công sau " + IntegerToString(m_failedUpdatesCount) + " lần thất bại");
      }
      m_failedUpdatesCount = 0;
      m_isDataReliable = true;
   }
   
   // Cập nhật phiên giao dịch hiện tại
   m_currentSession = DetermineCurrentSession();
   
   // Phân tích trạng thái thị trường
   AnalyzeMarketConditions();
   
   // Xác định pha thị trường
   m_marketPhase = DetermineMarketPhase();
   
   // Cập nhật thời gian
   m_lastUpdateTime = TimeCurrent();
   
   return updateSuccessful;
}

//+------------------------------------------------------------------+
//| Tính toán thống kê về độ dốc EMA                                 |
//+------------------------------------------------------------------+
void CMarketProfile::CalculateEMASlopeStatistics()
{
   // Lấy dữ liệu EMA34 cho 50 nến để tính thống kê
   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   
   if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, 50, emaBuffer)) {
      m_logger.LogWarning("Không thể lấy dữ liệu lịch sử EMA34 H1 cho thống kê");
      return;
   }
   
   // Tính độ dốc cho từng cặp nến
   double slopes[49]; // 50 điểm dữ liệu đưa ra 49 độ dốc
   for (int i = 0; i < 49; i++) {
      // Độ dốc đơn giản = (EMA[i] - EMA[i+1])
      slopes[i] = (emaBuffer[i] - emaBuffer[i+1]);
      
      // Chuẩn hóa theo ATR
      if (m_atrH1 > 0) {
         slopes[i] = slopes[i] / m_atrH1;
      }
   }
   
   // Tính trung bình
   double sum = 0;
   for (int i = 0; i < 49; i++) {
      sum += slopes[i];
   }
   m_avgEMASlope = sum / 49.0;
   
   // Tính độ lệch chuẩn
   double sumSquaredDiff = 0;
   for (int i = 0; i < 49; i++) {
      double diff = slopes[i] - m_avgEMASlope;
      sumSquaredDiff += diff * diff;
   }
   
   m_emaSlopeStdDev = MathSqrt(sumSquaredDiff / 49.0);
   
   // Nếu độ lệch chuẩn quá nhỏ, đặt giá trị tối thiểu
   if (m_emaSlopeStdDev < 0.01) {
      m_emaSlopeStdDev = 0.01;
   }
}

//+------------------------------------------------------------------+
//| Cập nhật các ngưỡng động dựa trên dữ liệu lịch sử                |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateDynamicThresholds()
{
   // Sử dụng m_avgEMASlope và m_emaSlopeStdDev để thiết lập ngưỡng
   
   // Pha tích lũy: Biến động thấp, sử dụng 1 lần độ lệch chuẩn
   m_dynamicAccumulationThreshold = m_emaSlopeStdDev;
   
   // Pha xung lực: Biến động cao, sử dụng 3 lần độ lệch chuẩn
   m_dynamicImpulseThreshold = 3.0 * m_emaSlopeStdDev;
   
   // Pha điều chỉnh: Biến động trung bình, sử dụng 2 lần độ lệch chuẩn
   m_dynamicCorrectionThreshold = 2.0 * m_emaSlopeStdDev;
   
   // Pha phân phối: Tương tự tích lũy nhưng với hướng ngược lại
   m_dynamicDistributionThreshold = -m_emaSlopeStdDev;
   
   // Pha cạn kiệt: Biến động rất cao, sử dụng 4 lần độ lệch chuẩn
   m_dynamicExhaustionThreshold = 4.0 * m_emaSlopeStdDev;
   
   // Giới hạn ngưỡng để tránh giá trị cực đoan
   double maxThreshold = 0.5;
   
   m_dynamicAccumulationThreshold = MathMin(m_dynamicAccumulationThreshold, maxThreshold);
   m_dynamicImpulseThreshold = MathMin(m_dynamicImpulseThreshold, maxThreshold * 3.0);
   m_dynamicCorrectionThreshold = MathMin(m_dynamicCorrectionThreshold, maxThreshold * 2.0);
   m_dynamicDistributionThreshold = MathMax(m_dynamicDistributionThreshold, -maxThreshold);
   m_dynamicExhaustionThreshold = MathMin(m_dynamicExhaustionThreshold, maxThreshold * 4.0);
}

//+------------------------------------------------------------------+
//| Kiểm tra trạng thái quá mua/quá bán từ RSI                      |
//+------------------------------------------------------------------+
bool CMarketProfile::IsOverbought() const
{
   return m_rsiH1 > m_rsiOverboughtThreshold;
}

//+------------------------------------------------------------------+
//| Kiểm tra trạng thái quá bán từ RSI                              |
//+------------------------------------------------------------------+
bool CMarketProfile::IsOversold() const
{
   return m_rsiH1 < m_rsiOversoldThreshold;
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng tăng từ MACD                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::IsMACDUptrend() const
{
   return m_macdMain > m_macdSignal && m_macdHistogram > 0;
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng giảm từ MACD                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::IsMACDDowntrend() const
{
   return m_macdMain < m_macdSignal && m_macdHistogram < 0;
}

//+------------------------------------------------------------------+
//| Kiểm tra MACD đang phân kỳ                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::IsMACDDiverging() const
{
   // Divergence đơn giản: MACD bắt đầu đi ngược với giá
   return (m_macdHistogram > 0 && m_slopeEMA34H1 < 0) || 
          (m_macdHistogram < 0 && m_slopeEMA34H1 > 0);
}

//+------------------------------------------------------------------+
//| Xác định pha thị trường hiện tại                                 |
//+------------------------------------------------------------------+
ENUM_MARKET_PHASE CMarketProfile::DetermineMarketPhase()
{
   // Kiểm tra dữ liệu có đáng tin cậy không
   if (!m_isDataReliable) {
      m_logger.LogWarning("Xác định pha thị trường với dữ liệu không đáng tin cậy");
      return PHASE_ACCUMULATION; // Pha mặc định an toàn
   }
   
   // Lấy các chỉ báo đã được cập nhật
   double emaSlope = m_slopeEMA34H1;
   double adx = m_adxH1;
   double rsi = m_rsiH1;
   bool volumeSpike = m_hasVolumeSpike;
   bool macdUptrend = IsMACDUptrend();
   bool macdDowntrend = IsMACDDowntrend();
   bool macdDiverging = IsMACDDiverging();
   
   // === CHIẾN LƯỢC XÁC ĐỊNH PHA THỊ TRƯỜNG NÂNG CAO ===
   // Kết hợp tất cả: ADX, độ dốc EMA, RSI, MACD, volume và ngưỡng động
   
   // PHASE_ACCUMULATION: Thị trường đi ngang, tích lũy
   // - ADX thấp: Không có xu hướng rõ ràng
   // - EMA đi ngang hoặc độ dốc nhỏ (trong phạm vi ngưỡng động)
   // - RSI trong vùng trung tính
   // - MACD gần đường tín hiệu, histogram nhỏ
   if ((MathAbs(emaSlope) < m_dynamicAccumulationThreshold && adx < m_weakTrendThreshold) || 
       (adx < 15 && rsi > 40 && rsi < 60 && MathAbs(m_macdHistogram) < 0.0002)) {
      m_logger.LogDebug("Pha thị trường: ACCUMULATION (Tích lũy)");
      return PHASE_ACCUMULATION;
   }
   
   // PHASE_DOWN_ACCUMULATION: Tích lũy sau xu hướng giảm
   // - ADX giảm từ mức vừa phải
   // - EMA có độ dốc âm nhẹ hoặc bắt đầu đi ngang
   // - RSI đã thoát khỏi vùng quá bán nhưng vẫn còn thấp
   // - MACD histogram chuyển dần từ âm sang dương
   if (MathAbs(emaSlope) < m_dynamicAccumulationThreshold && 
       adx < 20 && m_adxPrev > adx &&
       rsi < 45 && rsi > 30 && 
       m_macdHistogram > m_macdHistogramPrev) {
      m_logger.LogDebug("Pha thị trường: DOWN_ACCUMULATION (Tích lũy xuống)");
      return PHASE_DOWN_ACCUMULATION;
   }
   
   // PHASE_IMPULSE: Thị trường bùng nổ, chuyển động mạnh
   // - ADX cao: Xu hướng rõ ràng và mạnh
   // - EMA có độ dốc lớn (vượt ngưỡng động)
   // - RSI chưa vào vùng quá mua/bán hoặc mới vừa vào
   // - MACD tiếp tục mở rộng theo hướng của xu hướng
   // - Volume có thể tăng đột biến
   if (adx > 25 && 
       ((emaSlope > m_dynamicImpulseThreshold && rsi < 80 && macdUptrend) ||
        (emaSlope < -m_dynamicImpulseThreshold && rsi > 20 && macdDowntrend))) {
      m_logger.LogDebug("Pha thị trường: IMPULSE (Bùng nổ)");
      return PHASE_IMPULSE;
   }
   
   // PHASE_CORRECTION: Sự điều chỉnh trong xu hướng
   // - ADX bắt đầu giảm từ mức cao
   // - EMA có độ dốc giảm hoặc đảo chiều nhẹ
   // - RSI thoát khỏi vùng quá mua/bán hoặc đang di chuyển về vùng trung tính
   // - MACD cắt đường tín hiệu hoặc bắt đầu hội tụ
   if (((emaSlope < m_dynamicCorrectionThreshold && m_emaSlope_prev > 0) ||
       (emaSlope > -m_dynamicCorrectionThreshold && m_emaSlope_prev < 0)) && 
       (adx < m_adxPrev) && 
       ((m_macdHistogram > 0 && m_macdHistogramPrev < 0) || 
        (m_macdHistogram < 0 && m_macdHistogramPrev > 0))) {
      m_logger.LogDebug("Pha thị trường: CORRECTION (Điều chỉnh)");
      return PHASE_CORRECTION;
   }
   
   // PHASE_DISTRIBUTION: Thị trường phân phối, kết thúc xu hướng
   // - ADX vẫn cao nhưng bắt đầu giảm
   // - EMA bắt đầu giảm tốc độ tăng/giảm
   // - RSI ở vùng quá mua/bán và bắt đầu phân kỳ với giá
   // - MACD bắt đầu phân kỳ với giá
   // - Volume có thể tăng đột biến khi người chơi lớn rút lui
   if ((adx > 20 && adx < m_adxPrev) && 
       ((emaSlope > 0 && emaSlope < m_emaSlope_prev && IsOverbought()) ||
        (emaSlope < 0 && emaSlope > m_emaSlope_prev && IsOversold()) ||
        macdDiverging) && 
       volumeSpike) {
      m_logger.LogDebug("Pha thị trường: DISTRIBUTION (Phân phối)");
      return PHASE_DISTRIBUTION;
   }
   
   // PHASE_EXHAUSTION: Thị trường kiệt sức, sắp đảo chiều
   // - ADX rất cao nhưng bắt đầu đảo chiều
   // - EMA có độ dốc cực lớn
   // - RSI ở vùng cực kỳ quá mua/bán (>85 hoặc <15)
   // - MACD phân kỳ mạnh với giá
   // - Volume thường tăng đột biến (climax volume)
   if (MathAbs(emaSlope) > m_dynamicExhaustionThreshold && 
       adx > 35 && adx < m_adxPrev && 
       (rsi > 85 || rsi < 15) && 
       macdDiverging && 
       volumeSpike) {
      m_logger.LogDebug("Pha thị trường: EXHAUSTION (Kiệt sức)");
      return PHASE_EXHAUSTION;
   }
   
   // === NẾU KHÔNG RÕ RÀNG, ÁP DỤNG QUY TẮC ƯU TIÊN ===
   
   // 1. Nếu MACD đang phân kỳ mạnh với giá
   if (macdDiverging) {
      if (IsOverbought() || IsOversold()) {
         if (adx > 30) return PHASE_EXHAUSTION;
         return PHASE_DISTRIBUTION;
      }
   }
   
   // 2. Nếu ADX vẫn cao và EMA vẫn dốc theo cùng hướng
   if (adx > 25 && MathAbs(emaSlope) > 0.15) {
      if ((emaSlope > 0 && macdUptrend) || (emaSlope < 0 && macdDowntrend)) {
         return PHASE_IMPULSE;
      }
   }
   
   // 3. Nếu RSI ở vùng quá mua/bán
   if (IsOverbought() || IsOversold()) {
      if (adx > 25) return PHASE_DISTRIBUTION;
   }
   
   // 4. Nếu ADX thấp
   if (adx < 15) {
      if (rsi > 45 && rsi < 55) return PHASE_ACCUMULATION;
      if (rsi < 45) return PHASE_DOWN_ACCUMULATION;
   }
   
   // 5. Nếu có dấu hiệu điều chỉnh
   if ((emaSlope * m_emaSlope_prev < 0) || // Dấu đổi dấu độ dốc
       (MathAbs(emaSlope) < MathAbs(m_emaSlope_prev) * 0.7)) { // Độ dốc giảm >30%
      return PHASE_CORRECTION;
   }
   
   // Mặc định: Nếu vẫn không rõ ràng, trả về ACCUMULATION như trạng thái an toàn nhất
   m_logger.LogDebug("Pha thị trường mặc định: ACCUMULATION");
   return PHASE_ACCUMULATION;
}

//+------------------------------------------------------------------+
//| Cập nhật điểm swing cao/thấp gần đây                            |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateSwingPoints()
{
   double high[], low[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if (CopyHigh(m_symbol, PERIOD_CURRENT, 0, 20, high) <= 0 ||
       CopyLow(m_symbol, PERIOD_CURRENT, 0, 20, low) <= 0) {
      m_logger.LogWarning("Không thể cập nhật điểm swing");
      return;
   }
   
   // Tìm điểm cao nhất trong 20 nến
   m_recentSwingHigh = high[ArrayMaximum(high, 0, 20)];
   
   // Tìm điểm thấp nhất trong 20 nến
   m_recentSwingLow = low[ArrayMinimum(low, 0, 20)];
}

//+------------------------------------------------------------------+
//| Phân tích điều kiện thị trường                                   |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeMarketConditions()
{
   // Kiểm tra dữ liệu có đáng tin cậy không
   if (!m_isDataReliable) {
      m_logger.LogWarning("Phân tích thị trường với dữ liệu không đáng tin cậy");
      // Có thể sử dụng giá trị mặc định an toàn
      m_isTrending = false;
      m_isWeakTrend = false;
      m_isSideway = true;
      m_isVolatile = false;
      m_isRangebound = true;
      return;
   }
   
   // Kiểm tra xu hướng
   if (m_adxH1 >= m_strongTrendThreshold) {
      m_isTrending = true;
      m_isWeakTrend = false;
      m_isSideway = false;
   } else if (m_adxH1 >= m_weakTrendThreshold) {
      m_isTrending = true;
      m_isWeakTrend = true;
      m_isSideway = false;
   } else {
      m_isTrending = false;
      m_isWeakTrend = false;
      m_isSideway = DetectSideway();
   }
   
   // Kiểm tra biến động
   m_isVolatile = DetectVolatility();
   
   // Kiểm tra thị trường dao động trong biên độ
   m_isRangebound = DetectRangebound();
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA34                                                |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateSlopeEMA34()
{
   // Kiểm tra số lượng nến đủ để tính
   int periods = m_EMASlopePeriodsH1;
   if (periods < 2) periods = 2;
   
   // Lấy giá trị EMA34 cho nhiều nến
   double emaBuffer[];
   ArraySetAsSeries(emaBuffer, true);
   
   if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, periods + 1, emaBuffer)) {
      m_logger.LogError("Không thể lấy dữ liệu EMA34 để tính độ dốc");
      return 0.0;
   }
   
   // Tính độ dốc qua linear regression
   double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
   
   for (int i = 0; i < periods; i++) {
      sumX += i;
      sumY += emaBuffer[i];
      sumXY += i * emaBuffer[i];
      sumX2 += i * i;
   }
   
   double slope = 0;
   double divisor = (periods * sumX2 - sumX * sumX);
   
   if (divisor != 0) {
      slope = (periods * sumXY - sumX * sumY) / divisor;
   }
   
   // Chuẩn hóa độ dốc theo ATR
   if (m_atrH1 > 0) {
      slope = slope / m_atrH1;
   }
   
   return slope;
}

//+------------------------------------------------------------------+
//| Tính khoảng cách giữa EMA89 và EMA200                            |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateDistanceEMA89_200()
{
   // Lấy giá trị EMA89 và EMA200
   double ema89Buffer[], ema200Buffer[];
   ArraySetAsSeries(ema89Buffer, true);
   ArraySetAsSeries(ema200Buffer, true);
   
   if (!SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89Buffer) ||
       !SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200Buffer)) {
      return 0.0;
   }
   
   // Tính khoảng cách
   double distance = ema89Buffer[0] - ema200Buffer[0];
   
   // Chuẩn hóa theo ATR
   if (m_atrH1 > 0) {
      distance = distance / m_atrH1;
   }
   
   return distance;
}

//+------------------------------------------------------------------+
//| Xác định phiên giao dịch hiện tại                                |
//+------------------------------------------------------------------+
ENUM_SESSION_TYPE CMarketProfile::DetermineCurrentSession()
{
   // Lấy giờ GMT
   datetime timeGMT = TimeGMT() + m_GMT_Offset * 3600; // Điều chỉnh theo độ lệch
   MqlDateTime dt;
   TimeToStruct(timeGMT, dt);
   int hour = dt.hour;
   
   // Phiên Á: 00:00 - 08:00 GMT
   if (hour >= 0 && hour < 8) {
      return SESSION_ASIAN;
   }
   // Phiên Âu: 08:00 - 16:00 GMT
   else if (hour >= 8 && hour < 16) {
      // Phiên Âu-Mỹ: 13:00 - 16:00 GMT
      if (hour >= 13) {
         return SESSION_EUROPEAN_AMERICAN;
      }
      return SESSION_EUROPEAN;
   }
   // Phiên Mỹ: 13:00 - 21:00 GMT
   else if (hour >= 13 && hour < 21) {
      return SESSION_AMERICAN;
   }
   // Phiên đóng cửa
   else {
      return SESSION_CLOSING;
   }
}

//+------------------------------------------------------------------+
//| Phát hiện đột biến volume                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectVolumeSpike()
{
   // Kiểm tra volume hiện tại so với SMA
   if (m_volumeSMA20 <= 0) return false;
   
   double volumeRatio = m_volumeCurrent / m_volumeSMA20;
   
   // Volume spike là khi volume hiện tại lớn hơn SMA20 một ngưỡng nhất định
   return (volumeRatio > m_volumeSpikeThreshold);
}

//+------------------------------------------------------------------+
//| Phát hiện biến động lớn                                          |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectVolatility()
{
   // Kiểm tra tỷ lệ ATR
   return (m_atrRatio > m_volatilityThreshold);
}

//+------------------------------------------------------------------+
//| Phát hiện xu hướng yếu                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectWeakTrend()
{
   // Xu hướng yếu: ADX trong khoảng 15-25
   return (m_adxH1 >= 15 && m_adxH1 < 25);
}

//+------------------------------------------------------------------+
//| Phát hiện thị trường sideway                                     |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectSideway()
{
   // Sideway: ADX thấp và EMA gần như ngang
   return (m_adxH1 < m_weakTrendThreshold && MathAbs(m_slopeEMA34H1) < 0.15);
}

//+------------------------------------------------------------------+
//| Phát hiện thị trường dao động trong biên độ                      |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectRangebound()
{
   // Dao động trong biên độ: ADX thấp và biên độ nhỏ
   return (m_adxH1 < 15 && m_atrRatio < 0.8);
}

//+------------------------------------------------------------------+
//| Cập nhật thông tin thị trường                                    |
//+------------------------------------------------------------------+
bool CMarketProfile::Update()
{
   if (!m_isInitialized) {
      m_logger.LogError("MarketProfile chưa được khởi tạo");
      return false;
   }
   
   // Cập nhật dữ liệu chỉ báo
   if (!UpdateIndicatorData()) {
      m_logger.LogWarning("Cập nhật dữ liệu chỉ báo không thành công");
      return false;
   }
   
   // Log thông tin thị trường nếu cần thiết
   if (m_logger != NULL && m_logger.IsDebugEnabled()) {
      LogMarketProfile();
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Cập nhật nhẹ không tính toán lại tất cả                          |
//+------------------------------------------------------------------+
bool CMarketProfile::LightUpdate()
{
   if (!m_isInitialized) {
      return false;
   }
   
   // Chỉ cập nhật giá
   double close[], high[], low[];
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   
   if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0 ||
       CopyHigh(m_symbol, PERIOD_CURRENT, 0, 1, high) <= 0 ||
       CopyLow(m_symbol, PERIOD_CURRENT, 0, 1, low) <= 0) {
      return false;
   }
   
   // Kiểm tra thay đổi lớn từ lần cập nhật cuối
   bool significantChange = false;
   static double lastPrice = 0;
   
   if (lastPrice > 0 && m_atrH1 > 0) {
      double priceChange = MathAbs(close[0] - lastPrice) / m_atrH1;
      if (priceChange > 0.3) { // Nếu giá thay đổi > 30% ATR
         significantChange = true;
      }
   }
   
   lastPrice = close[0];
   
   // Nếu có thay đổi lớn, cập nhật đầy đủ
   if (significantChange) {
      return Update();
   }
   
   // Không có thay đổi lớn, giữ nguyên trạng thái
   return true;
}

//+------------------------------------------------------------------+
//| Log thông tin chi tiết về market profile                         |
//+------------------------------------------------------------------+
void CMarketProfile::LogMarketProfile()
{
   if (m_logger == NULL) return;
   
   string logMsg = StringFormat(
      "[%s] Market Profile: ADX_H1=%.1f, ADX_H4=%.1f, ATR_Ratio=%.2f, RSI=%.1f, Session=%s, Phase=%s", 
      m_symbol,
      m_adxH1,
      m_adxH4,
      m_atrRatio,
      m_rsiH1,
      EnumToString(m_currentSession),
      EnumToString(m_marketPhase)
   );
   
   string stateMsg = "";
   if (m_isTrending) stateMsg += "Trending ";
   if (m_isWeakTrend) stateMsg += "WeakTrend ";
   if (m_isSideway) stateMsg += "Sideway ";
   if (m_isVolatile) stateMsg += "Volatile ";
   if (m_isRangebound) stateMsg += "Rangebound ";
   if (m_hasVolumeSpike) stateMsg += "VolSpike ";
   
   if (stateMsg != "") {
      logMsg += ", State: " + stateMsg;
   }
   
   string macdInfo = StringFormat(", MACD(%.5f/%.5f)", m_macdMain, m_macdSignal);
   logMsg += macdInfo;
   
   m_logger.LogDebug(logMsg);
}

//+------------------------------------------------------------------+
//| Lấy tóm tắt thông tin market profile                             |
//+------------------------------------------------------------------+
string CMarketProfile::GetMarketProfileSummary()
{
   string summary = "--- Market Profile Summary ---\n";
   
   summary += "Symbol: " + m_symbol + "\n";
   summary += "Session: " + EnumToString(m_currentSession) + "\n";
   summary += "Market Phase: " + EnumToString(m_marketPhase) + "\n";
   
   summary += "Market State: ";
   if (m_isTrending) summary += "Trending ";
   if (m_isWeakTrend) summary += "(Weak) ";
   if (m_isSideway) summary += "Sideway ";
   if (m_isVolatile) summary += "Volatile ";
   if (m_isRangebound) summary += "Rangebound ";
   summary += "\n";
   
   summary += StringFormat("Indicators: ADX_H1=%.1f, ADX_H4=%.1f, ATR_Ratio=%.2f, RSI=%.1f\n",
                         m_adxH1, m_adxH4, m_atrRatio, m_rsiH1);
                         
   summary += StringFormat("Volume: Current=%.0f, SMA20=%.0f, Spike=%s\n",
                         m_volumeCurrent, m_volumeSMA20, m_hasVolumeSpike ? "Yes" : "No");
                         
   summary += StringFormat("EMA Analysis: Slope=%.4f, Distance=%.4f\n",
                         m_slopeEMA34H1, m_distanceEMA89_200_H1);
   
   summary += StringFormat("MACD Analysis: Main=%.5f, Signal=%.5f, Histogram=%.5f\n",
                         m_macdMain, m_macdSignal, m_macdHistogram);
   
   summary += StringFormat("Dynamic Thresholds: Accumulation=%.4f, Impulse=%.4f, Correction=%.4f\n",
                         m_dynamicAccumulationThreshold, m_dynamicImpulseThreshold, m_dynamicCorrectionThreshold);
   
   return summary;
}

//+------------------------------------------------------------------+
//| Lấy market regime dựa trên profile                               |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketProfile::GetMarketRegimeBasedOnProfile()
{
   if (m_isTrending) {
      if (m_adxH1 >= m_strongTrendThreshold && !m_isWeakTrend) {
         return REGIME_STRONG_TREND;
      } else {
         return REGIME_WEAK_TREND;
      }
   } else if (m_isVolatile) {
      return REGIME_VOLATILE;
   } else {
      return REGIME_RANGING;
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giá gần mức hỗ trợ/kháng cự quan trọng             |
//+------------------------------------------------------------------+
bool CMarketProfile::IsNearKeyLevel() const
{
   // Lấy giá hiện tại
   double currentClose = 0;
   double closeBuffer[1];
   ArraySetAsSeries(closeBuffer, true);
   
   if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, closeBuffer) <= 0) {
      return false;
   }
   
   currentClose = closeBuffer[0];
   
   // Khoảng cách tối đa cho "gần" mức hỗ trợ/kháng cự (ví dụ: 0.5 ATR)
   double maxDistance = m_atrH1 * 0.5;
   
   // Thực hiện các phép kiểm tra đơn giản với mức hỗ trợ/kháng cự tính toán
   // Trong một EA thực tế, đây có thể là tính toán phức tạp hơn dựa trên Fibonacci, 
   // mức tâm lý, vùng tích lũy trước đó, v.v.
   
   // Ví dụ kiểm tra gần mức tròn
   double priceScale = 1.0;
   if (m_symbol.Contains("JPY")) {
      priceScale = 0.01; // JPY pairs thường có 2 chữ số thập phân
   } else {
      priceScale = 0.0001; // Các cặp tiền tệ khác thường có 4 chữ số thập phân
   }
   
   // Tìm mức tròn gần nhất
   double roundLevel = MathRound(currentClose / priceScale) * priceScale;
   double distanceToRound = MathAbs(currentClose - roundLevel);
   
   // Kiểm tra EMA200 như mức hỗ trợ/kháng cự
   double ema200 = 0;
   double emaBuffer[1];
   ArraySetAsSeries(emaBuffer, true);
   
   if (SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, emaBuffer)) {
      ema200 = emaBuffer[0];
      double distanceToEMA200 = MathAbs(currentClose - ema200);
      
      if (distanceToEMA200 < maxDistance) {
         return true;
      }
   }
   
   // Kiểm tra khoảng cách đến mức tròn
   if (distanceToRound < maxDistance) {
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra phân kỳ tăng                                            |
//+------------------------------------------------------------------+
bool CMarketProfile::HasBullishDivergence() const
{
   // Phân kỳ tăng đơn giản - giá tạo đáy thấp hơn nhưng chỉ báo tạo đáy cao hơn
   // Trong một EA thực tế, cần triển khai logic phức tạp hơn
   return (m_macdHistogram > 0 && m_slopeEMA34H1 < 0 && m_rsiH1 < 45 && m_rsiH1 > 30);
}

//+------------------------------------------------------------------+
//| Kiểm tra phân kỳ giảm                                            |
//+------------------------------------------------------------------+
bool CMarketProfile::HasBearishDivergence() const
{
   // Phân kỳ giảm đơn giản - giá tạo đỉnh cao hơn nhưng chỉ báo tạo đỉnh thấp hơn
   // Trong một EA thực tế, cần triển khai logic phức tạp hơn
   return (m_macdHistogram < 0 && m_slopeEMA34H1 > 0 && m_rsiH1 > 55 && m_rsiH1 < 70);
}

//+------------------------------------------------------------------+
//| Kiểm tra momentum dương                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::HasPositiveMomentum(bool isLong) const
{
   if (isLong) {
      return m_slopeEMA34H1 > 0 && m_macdHistogram > 0;
   } else {
      return m_slopeEMA34H1 < 0 && m_macdHistogram < 0;
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra giá gần EMA                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::IsPriceNearEma(bool isLong) const
{
   double close[1];
   ArraySetAsSeries(close, true);
   
   if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
      return false;
   }
   
   double ema34[1];
   ArraySetAsSeries(ema34, true);
   
   if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, 1, ema34)) {
      return false;
   }
   
   double distance = MathAbs(close[0] - ema34[0]);
   double maxDistance = m_atrH1 * 0.5; // Nửa ATR
   
   if (isLong) {
      return close[0] > ema34[0] && distance < maxDistance;
   } else {
      return close[0] < ema34[0] && distance < maxDistance;
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra hỗ trợ quan trọng                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::HasKeySupport() const
{
   double close[1];
   ArraySetAsSeries(close, true);
   
   if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
      return false;
   }
   
   // Kiểm tra nếu giá gần mức hỗ trợ quan trọng (ví dụ: EMA200) và có xu hướng tăng
   double ema200[1];
   ArraySetAsSeries(ema200, true);
   
   if (!SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200)) {
      return false;
   }
   
   double distance = close[0] - ema200[0];
   
   return (distance > -m_atrH1 * 0.7 && distance < 0 && m_rsiH1 < 40);
}

//+------------------------------------------------------------------+
//| Kiểm tra kháng cự quan trọng                                      |
//+------------------------------------------------------------------+
bool CMarketProfile::HasKeyResistance() const
{
   double close[1];
   ArraySetAsSeries(close, true);
   
   if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
      return false;
   }
   
   // Kiểm tra nếu giá gần mức kháng cự quan trọng (ví dụ: EMA200) và có xu hướng giảm
   double ema200[1];
   ArraySetAsSeries(ema200, true);
   
   if (!SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200)) {
      return false;
   }
   
   double distance = close[0] - ema200[0];
   
   return (distance < m_atrH1 * 0.7 && distance > 0 && m_rsiH1 > 60);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng tăng                                          |
//+------------------------------------------------------------------+
bool CMarketProfile::IsTrendUp() const
{
   return (m_isTrending && m_slopeEMA34H1 > 0);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng giảm                                          |
//+------------------------------------------------------------------+
bool CMarketProfile::IsTrendDown() const
{
   return (m_isTrending && m_slopeEMA34H1 < 0);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng mạnh                                          |
//+------------------------------------------------------------------+
bool CMarketProfile::IsStrongTrend() const
{
   return (m_isTrending && !m_isWeakTrend && m_adxH1 > m_strongTrendThreshold);
}

//+------------------------------------------------------------------+
//| Getter cho điểm swing cao gần đây                                |
//+------------------------------------------------------------------+
double CMarketProfile::GetRecentSwingHigh() const
{
   return m_recentSwingHigh;
}

//+------------------------------------------------------------------+
//| Getter cho điểm swing thấp gần đây                               |
//+------------------------------------------------------------------+
double CMarketProfile::GetRecentSwingLow() const
{
   return m_recentSwingLow;
}

//+------------------------------------------------------------------+
//| Getter cho trạng thái đáng tin cậy của dữ liệu                   |
//+------------------------------------------------------------------+
bool CMarketProfile::IsDataReliable() const
{
   return m_isDataReliable;
}