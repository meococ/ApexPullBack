//+------------------------------------------------------------------+
//|                                         MarketProfile.mqh         |
//|                      APEX PULLBACK EA v14.0 - Professional Edition|
//|               Copyright 2023-2024, APEX Trading Systems           |
//+------------------------------------------------------------------+
// Copyright information moved to main EA file
// #property copyright "APEX Trading Systems"
// #property link      "https://www.apexpullback.com"
// #property version   "14.0"
// #property strict removed - this should only be in the main .mq5 file

// Sử dụng namespace ApexPullback để tránh xung đột
namespace ApexPullback {

// Include các thư viện cần thiết
#include <Trade\Trade.mqh>
#include "Logger.mqh"
#include "Enums.mqh"
#include "CommonStructs.mqh"

//+------------------------------------------------------------------+
//| Hàm chuyển đổi từ ENUM_TREND_TYPE sang ENUM_MARKET_TREND         |
//+------------------------------------------------------------------+
ENUM_MARKET_TREND MP_ConvertToMarketTrend(ENUM_TREND_TYPE trendType)
{
    switch (trendType) {
        case TREND_UP:
            return TREND_UP_NORMAL;  // Ánh xạ TREND_UP sang TREND_UP_NORMAL
        case TREND_DOWN:
            return TREND_DOWN_NORMAL;
        case TREND_NONE:
            return TREND_SIDEWAY;
        default:
            return TREND_SIDEWAY;    // Giá trị mặc định an toàn
    }
}

//+------------------------------------------------------------------+
//| Class MarketProfile - Quản lý profile thị trường                  |
//+------------------------------------------------------------------+
class CMarketProfile
{
private:
    // Thông tin cơ bản
    string m_Symbol;                   // Symbol đang giao dịch
    ENUM_TIMEFRAMES m_MainTimeframe;   // Khung thời gian chính (H1)
    ENUM_TIMEFRAMES m_HigherTimeframe; // Khung thời gian cao hơn (H4)
    CLogger* m_Logger;                 // Logger
    bool m_Initialized;                // Trạng thái khởi tạo
    bool m_UseMultiTimeframe;          // Sử dụng đa khung thời gian
    
    // Tham số cài đặt
    int m_EmaFast;                     // Chu kỳ EMA nhanh (34)
    int m_EmaMedium;                   // Chu kỳ EMA trung bình (89)
    int m_EmaSlow;                     // Chu kỳ EMA chậm (200)
    int m_AtrPeriod;                   // Chu kỳ ATR (14)
    int m_AdxPeriod;                   // Chu kỳ ADX (14)
    int m_RsiPeriod;                   // Chu kỳ RSI (14)
    int m_MacdFast;                    // Chu kỳ MACD nhanh (12)
    int m_MacdSlow;                    // Chu kỳ MACD chậm (26)
    int m_MacdSignal;                  // Chu kỳ đường tín hiệu MACD (9)
    double m_MinAdxValue;              // Giá trị ADX tối thiểu
    
    // Handle của các chỉ báo - Khung H1
    int m_HandleEmaFast;               // Handle EMA nhanh
    int m_HandleEmaMedium;             // Handle EMA trung bình
    int m_HandleEmaSlow;               // Handle EMA chậm
    int m_HandleAtr;                   // Handle ATR
    int m_HandleAdx;                   // Handle ADX
    int m_HandleRsi;                   // Handle RSI
    int m_HandleMacd;                  // Handle MACD
    
    // Handle của các chỉ báo - Khung H4
    int m_HandleEmaFastH4;             // Handle EMA nhanh H4
    int m_HandleEmaMediumH4;           // Handle EMA trung bình H4
    int m_HandleEmaSlowH4;             // Handle EMA chậm H4
    int m_HandleAtrH4;                 // Handle ATR H4
    int m_HandleAdxH4;                 // Handle ADX H4
    
    // Buffer lưu giá (để tính toán)
    double m_CloseBuffer[];            // Buffer giá đóng cửa
    double m_HighBuffer[];             // Buffer giá cao nhất
    double m_LowBuffer[];              // Buffer giá thấp nhất
    datetime m_TimeBuffer[];           // Buffer thời gian
    
    // Buffer lưu giá trị các chỉ báo - khung H1
    double m_EmaFastBuffer[];          // Buffer EMA nhanh
    double m_EmaMediumBuffer[];        // Buffer EMA trung bình
    double m_EmaSlowBuffer[];          // Buffer EMA chậm
    double m_AtrBuffer[];              // Buffer ATR
    double m_AdxBuffer[];              // Buffer ADX
    double m_AdxPlusBuffer[];          // Buffer ADX +DI
    double m_AdxMinusBuffer[];         // Buffer ADX -DI
    double m_RsiBuffer[];              // Buffer RSI
    double m_MacdBuffer[];             // Buffer MACD Main
    double m_MacdSignalBuffer[];       // Buffer MACD Signal
    double m_MacdHistBuffer[];         // Buffer MACD Histogram
    
    // Buffer lưu giá trị các chỉ báo - khung H4
    double m_EmaFastBufferH4[];        // Buffer EMA nhanh H4
    double m_EmaMediumBufferH4[];      // Buffer EMA trung bình H4
    double m_EmaSlowBufferH4[];        // Buffer EMA chậm H4
    double m_AtrBufferH4[];            // Buffer ATR H4
    double m_AdxBufferH4[];            // Buffer ADX H4
    
    // Dữ liệu Market Profile
    MarketProfileData m_CurrentProfile; // Profile hiện tại
    MarketProfileData m_PreviousProfile; // Profile trước đó
    datetime m_LastUpdateTime;         // Thời gian cập nhật cuối
    
    // Dữ liệu lịch sử ATR
    double m_AverageDailyAtr;          // ATR trung bình hàng ngày
    double m_AtrHistory[];             // Lịch sử ATR 20 ngày
    double m_SpreadBuffer[];           // Buffer lưu lịch sử spread
    int m_SpreadCount;                 // Số lượng spread đã lưu
    
    // Tham số lọc pullback
    double m_MinPullbackPercent;       // % Pullback tối thiểu
    double m_MaxPullbackPercent;       // % Pullback tối đa
    
    // Tham số bổ sung
    bool m_EnableVolatilityFilter;     // Bật lọc volatility
    bool m_EnableAdxFilter;            // Bật lọc ADX
    double m_VolatilityThreshold;      // Ngưỡng volatility
    
    // ----- Các hàm private -----
    
    // Hàm khởi tạo chỉ báo
    bool InitializeIndicators();
    
    // Hàm tính toán độ dốc
    double CalculateSlope(const double &buffer[], int periods = 5);
    
    // Hàm phân tích xu hướng
    ENUM_MARKET_TREND DetermineTrend();
    
    // Hàm phân tích chế độ thị trường
    ENUM_MARKET_REGIME DetermineRegime();
    
    // Hàm xác định phiên giao dịch
    ENUM_SESSION DetermineCurrentSession();
    
    // Hàm kiểm tra sự phân kỳ
    bool IsMultiTimeframeAligned();
    
    // Hàm tính điểm mạnh của xu hướng
    double CalculateTrendStrength();
    
    // Hàm tính khoảng cách giữa các EMA
    double CalculateEmaSpread(bool useHigherTimeframe = false);
    
    // Hàm cập nhật lịch sử ATR
    void UpdateAtrHistory();
    
    // Hàm cập nhật lịch sử spread
    void UpdateSpreadHistory();
    
    // Hàm kiểm tra thị trường sideway
    bool IsSidewayMarket();
    
    // Hàm kiểm tra thị trường choppy
    bool IsChoppyMarket() const;
    
    // Hàm kiểm tra động lượng thấp
    bool CheckLowMomentum();
    
    // Hàm kiểm tra thị trường biến động cao
    bool CheckHighVolatility();
    
    // Hàm kiểm tra giá trong vùng pullback
    bool IsPriceInPullbackZone(bool isLong);
    
    // Hàm giải phóng handle chỉ báo
    void ReleaseIndicatorHandles();
    
    // Hàm tính % pullback dựa trên swing và EMA
    double CalculatePullbackPercent(bool isLong);
    
public:
    // Constructor
    CMarketProfile();
    
    // Destructor
    ~CMarketProfile();
    
    // Hàm khởi tạo
    bool Initialize(string symbol, ENUM_TIMEFRAMES mainTimeframe, int emaFast, int emaMedium, int emaSlow,
                  bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe, CLogger* logger);
    
    // Hàm thiết lập các tham số bổ sung
    void SetParameters(double minAdxValue, double maxAdxValue, double volatilityThreshold, ENUM_MARKET_PRESET preset);
    
    // Hàm thiết lập tham số pullback
    void SetPullbackParameters(double minPullbackPercent, double maxPullbackPercent);
    
    // Hàm cập nhật dữ liệu thị trường - gọi trong OnTimer()
    bool Update();
    
    // Hàm phát hiện Pullback chất lượng cao
    bool IsPullbackDetected_HighQuality(SignalInfo &signal, const MarketProfileData &profile);
    
    // Hàm xác nhận pattern price action
    bool ValidatePriceAction(bool isLong);
    
    // Hàm xác nhận momentum
    bool ValidateMomentum(bool isLong);
    
    // Hàm xác nhận volume
    bool ValidateVolume();
    
    // Hàm kiểm tra rejection tại key level
    bool IsRejectionAtKeyLevel(bool isLong);
    
    // Lấy profile thị trường hiện tại - gọi trong OnTick()
    MarketProfileData GetLastProfile() const;
    
    // Hàm kiểm tra xu hướng đủ mạnh
    bool IsTrendStrongEnough() const;
    
    // ----- Các hàm getter -----
    
    // Lấy xu hướng hiện tại
    ENUM_MARKET_TREND GetTrend() const { return m_CurrentProfile.trend; }
    
    // Lấy chế độ thị trường hiện tại
    ENUM_MARKET_REGIME GetRegime() const { return m_CurrentProfile.regime; }
    
    // Lấy phiên giao dịch hiện tại
    ENUM_SESSION GetCurrentSession() const { return m_CurrentProfile.currentSession; }
    
    // Lấy giá trị ATR hiện tại
    double GetATR() const { return m_CurrentProfile.atrCurrent; }
    
    // Lấy tỷ lệ ATR (so với trung bình)
    double GetATRRatio() const { return m_CurrentProfile.atrRatio; }
    
    // Lấy giá trị ADX
    double GetADX() const { return m_CurrentProfile.adxValue; }
    
    // Lấy độ dốc ADX
    double GetADXSlope() const { return m_CurrentProfile.adxSlope; }
    
    // Lấy giá trị EMA
    double GetEMA(int period, int shift = 0);
    
    // Lấy giá trị EMA từ timeframe cao hơn
    double GetHigherTimeframeEMA(int period, int shift = 0);
    
    // Lấy độ tin cậy của regime hiện tại
    double GetRegimeConfidence() const { return m_CurrentProfile.regimeConfidence; }
    
    // ----- Các hàm kiểm tra trạng thái thị trường -----
    
    // Kiểm tra thị trường sideway hoặc choppy
    bool IsSidewaysOrChoppy() const { return m_CurrentProfile.isSidewaysOrChoppy; }
    
    // Kiểm tra động lượng thấp
    bool IsLowMomentum() const { return m_CurrentProfile.isLowMomentum; }
    
    // Kiểm tra thị trường biến động cao
    bool IsVolatile() const { return m_CurrentProfile.isVolatile; }
    
    // Kiểm tra thị trường đang trong xu hướng
    bool IsMarketTrending() const { return m_CurrentProfile.isTrending; }
    
    // Kiểm tra thị trường đang chuyển đổi chế độ
    bool IsMarketTransitioning() const { return m_CurrentProfile.isTransitioning; }
    
    // Kiểm tra thị trường choppy
    bool IsMarketChoppy() const { return IsChoppyMarket(); }
    
    // Kiểm tra thị trường volatility cực đoan
    bool IsVolatilityExtreme() const { return m_CurrentProfile.atrRatio > m_VolatilityThreshold * 1.5; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketProfile::CMarketProfile()
{
    m_Symbol = _Symbol;
    m_MainTimeframe = PERIOD_H1;
    m_HigherTimeframe = PERIOD_H4;
    m_Logger = NULL;
    m_Initialized = false;
    m_UseMultiTimeframe = true;
    
    // Thiết lập mặc định cho các tham số chỉ báo
    m_EmaFast = 34;
    m_EmaMedium = 89;
    m_EmaSlow = 200;
    m_AtrPeriod = 14;
    m_AdxPeriod = 14;
    m_RsiPeriod = 14;
    m_MacdFast = 12;
    m_MacdSlow = 26;
    m_MacdSignal = 9;
    m_MinAdxValue = 18.0;
    
    // Giá trị mặc định cho các handle chỉ báo
    m_HandleEmaFast = INVALID_HANDLE;
    m_HandleEmaMedium = INVALID_HANDLE;
    m_HandleEmaSlow = INVALID_HANDLE;
    m_HandleAtr = INVALID_HANDLE;
    m_HandleAdx = INVALID_HANDLE;
    m_HandleRsi = INVALID_HANDLE;
    m_HandleMacd = INVALID_HANDLE;
    
    m_HandleEmaFastH4 = INVALID_HANDLE;
    m_HandleEmaMediumH4 = INVALID_HANDLE;
    m_HandleEmaSlowH4 = INVALID_HANDLE;
    m_HandleAtrH4 = INVALID_HANDLE;
    m_HandleAdxH4 = INVALID_HANDLE;
    
    // Khởi tạo các giá trị mặc định khác
    m_LastUpdateTime = 0;
    m_AverageDailyAtr = 0;
    m_SpreadCount = 0;
    
    // Thiết lập mặc định các tham số lọc
    m_MinPullbackPercent = 20.0;
    m_MaxPullbackPercent = 70.0;
    m_EnableVolatilityFilter = true;
    m_EnableAdxFilter = true;
    m_VolatilityThreshold = 2.0;
    
    // Phân bổ bộ nhớ ban đầu cho các buffer
    ArrayResize(m_CloseBuffer, 200);
    ArrayResize(m_HighBuffer, 200);
    ArrayResize(m_LowBuffer, 200);
    ArrayResize(m_TimeBuffer, 200);
    
    ArrayResize(m_EmaFastBuffer, 200);
    ArrayResize(m_EmaMediumBuffer, 200);
    ArrayResize(m_EmaSlowBuffer, 200);
    ArrayResize(m_AtrBuffer, 200);
    ArrayResize(m_AdxBuffer, 200);
    ArrayResize(m_AdxPlusBuffer, 200);
    ArrayResize(m_AdxMinusBuffer, 200);
    ArrayResize(m_RsiBuffer, 200);
    ArrayResize(m_MacdBuffer, 200);
    ArrayResize(m_MacdSignalBuffer, 200);
    ArrayResize(m_MacdHistBuffer, 200);
    
    ArrayResize(m_EmaFastBufferH4, 50);
    ArrayResize(m_EmaMediumBufferH4, 50);
    ArrayResize(m_EmaSlowBufferH4, 50);
    ArrayResize(m_AtrBufferH4, 50);
    ArrayResize(m_AdxBufferH4, 50);
    
    ArrayResize(m_AtrHistory, 20);
    ArrayResize(m_SpreadBuffer, 50);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketProfile::~CMarketProfile()
{
    // Giải phóng tất cả handle chỉ báo
    ReleaseIndicatorHandles();
}

//+------------------------------------------------------------------+
//| Hàm khởi tạo MarketProfile                                      |
//+------------------------------------------------------------------+
bool CMarketProfile::Initialize(string symbol, ENUM_TIMEFRAMES mainTimeframe, int emaFast, int emaMedium, int emaSlow,
                             bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe, CLogger* logger)
{
    // Lưu các tham số
    m_Symbol = symbol;
    m_MainTimeframe = mainTimeframe;
    m_HigherTimeframe = higherTimeframe;
    m_Logger = logger;
    m_UseMultiTimeframe = useMultiTimeframe;
    
    // Lưu các tham số chỉ báo
    m_EmaFast = emaFast;
    m_EmaMedium = emaMedium;
    m_EmaSlow = emaSlow;
    
    // Log thông tin khởi tạo
    if (m_Logger != NULL)
    {
        m_Logger.LogInfo("MarketProfileManager: Initializing for " + m_Symbol + 
                      ", Timeframe: " + EnumToString(m_MainTimeframe) + 
                      ", EMAs: " + IntegerToString(m_EmaFast) + "/" + 
                      IntegerToString(m_EmaMedium) + "/" + 
                      IntegerToString(m_EmaSlow));
    }
    
    // Khởi tạo các chỉ báo
    if (!InitializeIndicators())
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to initialize indicators");
        
        return false;
    }
    
    // Cập nhật lần đầu
    if (!Update())
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to perform initial update");
        
        return false;
    }
    
    // Khởi tạo lịch sử ATR
    UpdateAtrHistory();
    
    m_Initialized = true;
    
    if (m_Logger != NULL)
        m_Logger.LogInfo("MarketProfileManager: Initialized successfully");
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm khởi tạo các chỉ báo                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::InitializeIndicators()
{
    // ----- Khởi tạo các chỉ báo trên khung thời gian chính (H1) -----
    
    // EMA
    m_HandleEmaFast = iMA(m_Symbol, m_MainTimeframe, m_EmaFast, 0, MODE_EMA, PRICE_CLOSE);
    m_HandleEmaMedium = iMA(m_Symbol, m_MainTimeframe, m_EmaMedium, 0, MODE_EMA, PRICE_CLOSE);
    m_HandleEmaSlow = iMA(m_Symbol, m_MainTimeframe, m_EmaSlow, 0, MODE_EMA, PRICE_CLOSE);
    
    // ATR
    m_HandleAtr = iATR(m_Symbol, m_MainTimeframe, m_AtrPeriod);
    
    // ADX
    m_HandleAdx = iADX(m_Symbol, m_MainTimeframe, m_AdxPeriod);
    
    // RSI
    m_HandleRsi = iRSI(m_Symbol, m_MainTimeframe, m_RsiPeriod, PRICE_CLOSE);
    
    // MACD
    m_HandleMacd = iMACD(m_Symbol, m_MainTimeframe, m_MacdFast, m_MacdSlow, m_MacdSignal, PRICE_CLOSE);
    
    // ----- Kiểm tra tính hợp lệ của các handle trên khung H1 -----
    if (m_HandleEmaFast == INVALID_HANDLE || 
        m_HandleEmaMedium == INVALID_HANDLE || 
        m_HandleEmaSlow == INVALID_HANDLE || 
        m_HandleAtr == INVALID_HANDLE || 
        m_HandleAdx == INVALID_HANDLE || 
        m_HandleRsi == INVALID_HANDLE || 
        m_HandleMacd == INVALID_HANDLE)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to initialize H1 indicators - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // ----- Khởi tạo các chỉ báo trên khung thời gian cao hơn (H4) nếu cần -----
    if (m_UseMultiTimeframe)
    {
        // EMA
        m_HandleEmaFastH4 = iMA(m_Symbol, m_HigherTimeframe, m_EmaFast, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaMediumH4 = iMA(m_Symbol, m_HigherTimeframe, m_EmaMedium, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaSlowH4 = iMA(m_Symbol, m_HigherTimeframe, m_EmaSlow, 0, MODE_EMA, PRICE_CLOSE);
        
        // ATR
        m_HandleAtrH4 = iATR(m_Symbol, m_HigherTimeframe, m_AtrPeriod);
        
        // ADX
        m_HandleAdxH4 = iADX(m_Symbol, m_HigherTimeframe, m_AdxPeriod);
        
        // ----- Kiểm tra tính hợp lệ của các handle trên khung H4 -----
        if (m_HandleEmaFastH4 == INVALID_HANDLE || 
            m_HandleEmaMediumH4 == INVALID_HANDLE || 
            m_HandleEmaSlowH4 == INVALID_HANDLE || 
            m_HandleAtrH4 == INVALID_HANDLE || 
            m_HandleAdxH4 == INVALID_HANDLE)
        {
            if (m_Logger != NULL)
                m_Logger.LogError("MarketProfileManager: Failed to initialize H4 indicators - Error " + IntegerToString(GetLastError()));
            
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm thiết lập các tham số bổ sung                               |
//+------------------------------------------------------------------+
void CMarketProfile::SetParameters(double minAdxValue, double maxAdxValue, double volatilityThreshold, ENUM_MARKET_PRESET preset)
{
    m_MinAdxValue = minAdxValue;
    m_VolatilityThreshold = volatilityThreshold;
    
    // Thiết lập các thông số theo preset
    switch (preset)
    {
        case 1: // PRESET_CONSERVATIVE (1)
            // Chế độ bảo thủ - ít tín hiệu hơn, chất lượng cao hơn
            m_MinAdxValue = MathMax(minAdxValue, 22.0);  // Yêu cầu ADX cao hơn
            m_MinPullbackPercent = 25.0;                 // Pullback sâu hơn
            m_MaxPullbackPercent = 65.0;                 // Không quá sâu
            break;
            
        case 3: // PRESET_AGGRESSIVE (3)
            // Chế độ tích cực - nhiều tín hiệu hơn
            m_MinAdxValue = MathMax(minAdxValue * 0.9, 15.0);  // Yêu cầu ADX thấp hơn
            m_MinPullbackPercent = 15.0;                        // Chấp nhận pullback nông hơn
            m_MaxPullbackPercent = 80.0;                        // Chấp nhận pullback sâu hơn
            break;
            
        case 2: // PRESET_BALANCED (2)
            // Giữ các giá trị đã thiết lập
            break;
            
        case 0: // PRESET_AUTO (0)
        default:
            // Tự động điều chỉnh theo thị trường (sẽ thay đổi trong quá trình update)
            break;
    }
    
    if (m_Logger != NULL)
    {
        m_Logger.LogInfo("MarketProfileManager: Parameters set - MinADX: " + DoubleToString(m_MinAdxValue, 1) + 
                      ", Volatility Threshold: " + DoubleToString(m_VolatilityThreshold, 1) +
                      ", Preset: " + EnumToString(preset));
    }
}

//+------------------------------------------------------------------+
//| Hàm thiết lập các tham số pullback                             |
//+------------------------------------------------------------------+
void CMarketProfile::SetPullbackParameters(double minPullbackPercent, double maxPullbackPercent)
{
    m_MinPullbackPercent = minPullbackPercent;
    m_MaxPullbackPercent = maxPullbackPercent;
    
    if (m_Logger != NULL)
    {
        m_Logger.LogInfo("MarketProfileManager: Pullback parameters set - Min: " + 
                      DoubleToString(m_MinPullbackPercent, 1) + "%, Max: " + 
                      DoubleToString(m_MaxPullbackPercent, 1) + "%");
    }
}

//+------------------------------------------------------------------+
//| Hàm cập nhật dữ liệu thị trường - gọi trong OnTimer()           |
//+------------------------------------------------------------------+
bool CMarketProfile::Update()
{
    // Kiểm tra xem đã đến lúc cập nhật chưa (60s một lần)
    datetime currentTime = TimeCurrent();
    if (m_LastUpdateTime > 0 && currentTime - m_LastUpdateTime < 60 && !IsNewBar())
    {
        // Chưa đến lúc cập nhật, trả về true nhưng không làm gì
        return true;
    }
    
    // Lưu profile hiện tại vào profile trước đó
    m_PreviousProfile = m_CurrentProfile;
    
    // Khởi tạo profile mới
    m_CurrentProfile = MarketProfileData();
    
    // ----- Cập nhật dữ liệu giá và các chỉ báo -----
    
    // Chuẩn bị các array
    ArraySetAsSeries(m_CloseBuffer, true);
    ArraySetAsSeries(m_HighBuffer, true);
    ArraySetAsSeries(m_LowBuffer, true);
    ArraySetAsSeries(m_TimeBuffer, true);
    
    // Lấy dữ liệu giá
    if (CopyClose(m_Symbol, m_MainTimeframe, 0, 100, m_CloseBuffer) <= 0 ||
        CopyHigh(m_Symbol, m_MainTimeframe, 0, 100, m_HighBuffer) <= 0 ||
        CopyLow(m_Symbol, m_MainTimeframe, 0, 100, m_LowBuffer) <= 0 ||
        CopyTime(m_Symbol, m_MainTimeframe, 0, 100, m_TimeBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy price data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // ----- Lấy dữ liệu chỉ báo - Khung H1 -----
    
    // Chuẩn bị các array
    ArraySetAsSeries(m_EmaFastBuffer, true);
    ArraySetAsSeries(m_EmaMediumBuffer, true);
    ArraySetAsSeries(m_EmaSlowBuffer, true);
    ArraySetAsSeries(m_AtrBuffer, true);
    ArraySetAsSeries(m_AdxBuffer, true);
    ArraySetAsSeries(m_AdxPlusBuffer, true);
    ArraySetAsSeries(m_AdxMinusBuffer, true);
    ArraySetAsSeries(m_RsiBuffer, true);
    ArraySetAsSeries(m_MacdBuffer, true);
    ArraySetAsSeries(m_MacdSignalBuffer, true);
    ArraySetAsSeries(m_MacdHistBuffer, true);
    
    // Copy dữ liệu EMA
    if (CopyBuffer(m_HandleEmaFast, 0, 0, 100, m_EmaFastBuffer) <= 0 ||
        CopyBuffer(m_HandleEmaMedium, 0, 0, 100, m_EmaMediumBuffer) <= 0 ||
        CopyBuffer(m_HandleEmaSlow, 0, 0, 100, m_EmaSlowBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy EMA data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Copy dữ liệu ATR
    if (CopyBuffer(m_HandleAtr, 0, 0, 100, m_AtrBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy ATR data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Copy dữ liệu ADX
    if (CopyBuffer(m_HandleAdx, 0, 0, 100, m_AdxBuffer) <= 0 ||
        CopyBuffer(m_HandleAdx, 1, 0, 100, m_AdxPlusBuffer) <= 0 ||
        CopyBuffer(m_HandleAdx, 2, 0, 100, m_AdxMinusBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy ADX data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Copy dữ liệu RSI
    if (CopyBuffer(m_HandleRsi, 0, 0, 100, m_RsiBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy RSI data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Copy dữ liệu MACD
    if (CopyBuffer(m_HandleMacd, 0, 0, 100, m_MacdBuffer) <= 0 ||
        CopyBuffer(m_HandleMacd, 1, 0, 100, m_MacdSignalBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy MACD data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Tính MACD Histogram
    for (int i = 0; i < 100 && i < ArraySize(m_MacdBuffer) && i < ArraySize(m_MacdSignalBuffer); i++)
    {
        m_MacdHistBuffer[i] = m_MacdBuffer[i] - m_MacdSignalBuffer[i];
    }
    
    // ----- Lấy dữ liệu chỉ báo - Khung H4 (nếu sử dụng) -----
    if (m_UseMultiTimeframe)
    {
        // Chuẩn bị các array
        ArraySetAsSeries(m_EmaFastBufferH4, true);
        ArraySetAsSeries(m_EmaMediumBufferH4, true);
        ArraySetAsSeries(m_EmaSlowBufferH4, true);
        ArraySetAsSeries(m_AtrBufferH4, true);
        ArraySetAsSeries(m_AdxBufferH4, true);
        
        // Copy dữ liệu EMA H4
        if (CopyBuffer(m_HandleEmaFastH4, 0, 0, 50, m_EmaFastBufferH4) <= 0 ||
            CopyBuffer(m_HandleEmaMediumH4, 0, 0, 50, m_EmaMediumBufferH4) <= 0 ||
            CopyBuffer(m_HandleEmaSlowH4, 0, 0, 50, m_EmaSlowBufferH4) <= 0)
        {
            if (m_Logger != NULL)
                m_Logger.LogError("MarketProfileManager: Failed to copy H4 EMA data - Error " + IntegerToString(GetLastError()));
            
            return false;
        }
        
        // Copy dữ liệu ATR H4
        if (CopyBuffer(m_HandleAtrH4, 0, 0, 50, m_AtrBufferH4) <= 0)
        {
            if (m_Logger != NULL)
                m_Logger.LogError("MarketProfileManager: Failed to copy H4 ATR data - Error " + IntegerToString(GetLastError()));
            
            return false;
        }
        
        // Copy dữ liệu ADX H4
        if (CopyBuffer(m_HandleAdxH4, 0, 0, 50, m_AdxBufferH4) <= 0)
        {
            if (m_Logger != NULL)
                m_Logger.LogError("MarketProfileManager: Failed to copy H4 ADX data - Error " + IntegerToString(GetLastError()));
            
            return false;
        }
    }
    
    // ----- Cập nhật thông tin thị trường -----
    
    // Cập nhật giá trị EMA
    m_CurrentProfile.ema34 = m_EmaFastBuffer[0];
    m_CurrentProfile.ema89 = m_EmaMediumBuffer[0];
    m_CurrentProfile.ema200 = m_EmaSlowBuffer[0];
    
    // Cập nhật giá trị EMA H4 nếu sử dụng
    if (m_UseMultiTimeframe)
    {
        m_CurrentProfile.ema34H4 = m_EmaFastBufferH4[0];
        m_CurrentProfile.ema89H4 = m_EmaMediumBufferH4[0];
        m_CurrentProfile.ema200H4 = m_EmaSlowBufferH4[0];
    }
    
    // Cập nhật giá trị ATR và tỉ lệ ATR
    m_CurrentProfile.atrCurrent = m_AtrBuffer[0];
    
    // Cập nhật giá trị ATR ratio nếu có ATR trung bình
    if (m_AverageDailyAtr > 0)
        m_CurrentProfile.atrRatio = m_CurrentProfile.atrCurrent / m_AverageDailyAtr;
    else
        m_CurrentProfile.atrRatio = 1.0; // Mặc định nếu chưa có ATR trung bình
    
    // Cập nhật giá trị ADX và Slope
    m_CurrentProfile.adxValue = m_AdxBuffer[0];
    m_CurrentProfile.adxSlope = CalculateSlope(m_AdxBuffer, 5);
    
    // Cập nhật giá trị RSI và Slope
    m_CurrentProfile.rsiValue = m_RsiBuffer[0];
    m_CurrentProfile.rsiSlope = CalculateSlope(m_RsiBuffer, 5);
    
    // Cập nhật giá trị MACD
    m_CurrentProfile.macdHistogram = m_MacdHistBuffer[0];
    m_CurrentProfile.macdHistogramSlope = CalculateSlope(m_MacdHistBuffer, 5);
    
    // ----- Phân tích thị trường -----
    
    // Xác định xu hướng
    m_CurrentProfile.trend = DetermineTrend();
    
    // Xác định chế độ thị trường
    m_CurrentProfile.regime = DetermineRegime();
    
    // Xác định phiên giao dịch
    m_CurrentProfile.currentSession = DetermineCurrentSession();
    
    // Kiểm tra sự phân kỳ giữa các timeframe
    m_CurrentProfile.mtfAlignment = IsMultiTimeframeAligned() ? 
        (m_CurrentProfile.trend == TREND_UP_NORMAL || m_CurrentProfile.trend == TREND_UP_STRONG ? 
         MTF_ALIGNMENT_BULLISH : MTF_ALIGNMENT_BEARISH) : 
        MTF_ALIGNMENT_CONFLICTING;
    
    // Tính điểm mạnh của xu hướng
    m_CurrentProfile.trendScore = CalculateTrendStrength();
    
    // Kiểm tra thị trường đang trending
    m_CurrentProfile.isTrending = (m_CurrentProfile.adxValue > m_MinAdxValue);
    
    // Kiểm tra các cờ đặc biệt
    m_CurrentProfile.isSidewaysOrChoppy = IsSidewayMarket() || IsChoppyMarket();
    m_CurrentProfile.isLowMomentum = CheckLowMomentum();
    m_CurrentProfile.isVolatile = CheckHighVolatility();
    
    // Kiểm tra thị trường đang chuyển đổi chế độ
    double regimeConfidence = 0.0;
    
    // Tính độ tin cậy của regime dựa trên ADX, EMA alignment, và trendScore
    if (m_CurrentProfile.adxValue > 30)
        regimeConfidence += 0.4;  // ADX cao -> độ tin cậy cao
    else if (m_CurrentProfile.adxValue > 20)
        regimeConfidence += 0.3;
    else if (m_CurrentProfile.adxValue > m_MinAdxValue)
        regimeConfidence += 0.2;
    else
        regimeConfidence += 0.1;
    
    // EMA alignment
    double emaSpreadH1 = CalculateEmaSpread(false);
    double emaSpreadH4 = CalculateEmaSpread(true);
    
    if (emaSpreadH1 > 0.5 && emaSpreadH4 > 0.5)
        regimeConfidence += 0.3;  // EMA xa nhau -> độ tin cậy cao cho trending
    else if (emaSpreadH1 > 0.3 || emaSpreadH4 > 0.3)
        regimeConfidence += 0.2;
    else
        regimeConfidence += 0.1;
    
    // Trend Score
    if (m_CurrentProfile.trendScore > 0.7)
        regimeConfidence += 0.3;
    else if (m_CurrentProfile.trendScore > 0.5)
        regimeConfidence += 0.2;
    else
        regimeConfidence += 0.1;
    
    // Chuẩn hóa
    regimeConfidence = MathMin(regimeConfidence, 1.0);
    m_CurrentProfile.regimeConfidence = regimeConfidence;
    
    // Xác định thị trường đang chuyển đổi chế độ
    m_CurrentProfile.isTransitioning = (regimeConfidence < 0.6);
    
    // Cập nhật lịch sử spread
    UpdateSpreadHistory();
    
    // Cập nhật thời gian
    m_LastUpdateTime = currentTime;
    
    // Ghi log chi tiết nếu cần
    if (m_Logger != NULL && m_Logger.GetLogLevel() == LOG_DEBUG)
    {
        string profileInfo = StringFormat(
            "Market Profile [%s]: Trend=%s, Regime=%s, Session=%s, ADX=%.1f, ATR=%.5f (%.1fx), RSI=%.1f",
            m_Symbol,
            EnumToString(m_CurrentProfile.trend),
            EnumToString(m_CurrentProfile.regime),
            EnumToString(m_CurrentProfile.currentSession),
            m_CurrentProfile.adxValue,
            m_CurrentProfile.atrCurrent,
            m_CurrentProfile.atrRatio,
            m_CurrentProfile.rsiValue
        );
        
        m_Logger.LogDebug(profileInfo);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm xác định xu hướng thị trường                                |
//+------------------------------------------------------------------+
ENUM_MARKET_TREND CMarketProfile::DetermineTrend()
{
    // Lấy các giá trị chỉ báo hiện tại
    double ema34 = m_EmaFastBuffer[0];
    double ema89 = m_EmaMediumBuffer[0];
    double ema200 = m_EmaSlowBuffer[0];
    double adx = m_AdxBuffer[0];
    double diPlus = m_AdxPlusBuffer[0];
    double diMinus = m_AdxMinusBuffer[0];
    
    // Lấy các giá trị từ khung H4 nếu sử dụng
    double ema34H4 = 0, ema89H4 = 0, ema200H4 = 0, adxH4 = 0;
    
    if (m_UseMultiTimeframe)
    {
        ema34H4 = m_EmaFastBufferH4[0];
        ema89H4 = m_EmaMediumBufferH4[0];
        ema200H4 = m_EmaSlowBufferH4[0];
        adxH4 = m_AdxBufferH4[0];
    }
    
    // ----- Phân tích xu hướng -----
    
    // Xác định trạng thái EMA H1
    bool emaUpAligned = (ema34 > ema89) && (ema89 > ema200);
    bool emaDownAligned = (ema34 < ema89) && (ema89 < ema200);
    
    // Xác định trạng thái EMA H4 (nếu sử dụng)
    bool emaUpAlignedH4 = false;
    bool emaDownAlignedH4 = false;
    
    if (m_UseMultiTimeframe)
    {
        emaUpAlignedH4 = (ema34H4 > ema89H4) && (ema89H4 > ema200H4);
        emaDownAlignedH4 = (ema34H4 < ema89H4) && (ema89H4 < ema200H4);
    }
    
    // Xác định trạng thái ADX và DI
    bool strongADX = (adx > 25);
    bool moderateADX = (adx > m_MinAdxValue && adx <= 25);
    bool diPlusStronger = (diPlus > diMinus);
    bool diMinusStronger = (diMinus > diPlus);
    
    // ----- Xác định xu hướng -----
    
    // Xu hướng tăng mạnh
    if (emaUpAligned && strongADX && diPlusStronger)
    {
        if (!m_UseMultiTimeframe || emaUpAlignedH4)
            return TREND_UP_STRONG;
    }
    
    // Xu hướng giảm mạnh
    if (emaDownAligned && strongADX && diMinusStronger)
    {
        if (!m_UseMultiTimeframe || emaDownAlignedH4)
            return TREND_DOWN_STRONG;
    }
    
    // Xu hướng tăng
    if (emaUpAligned && (moderateADX || diPlusStronger))
    {
        // Kiểm tra pullback
        double close = m_CloseBuffer[0];
        if (close < ema34)
            return TREND_UP_PULLBACK;
        else
            return MP_ConvertToMarketTrend(TREND_UP);
    }
    
    // Xu hướng giảm
    if (emaDownAligned && (moderateADX || diMinusStronger))
    {
        // Kiểm tra pullback
        double close = m_CloseBuffer[0];
        if (close > ema34)
            return TREND_DOWN_PULLBACK;
        else
            return MP_ConvertToMarketTrend(TREND_DOWN);
    }
    
    // Không có xu hướng rõ ràng
    return MP_ConvertToMarketTrend(TREND_NONE);
}

//+------------------------------------------------------------------+
//| Hàm xác định chế độ thị trường                                  |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketProfile::DetermineRegime()
{
    // Lấy các giá trị hiện tại
    double adx = m_AdxBuffer[0];
    double atrRatio = m_CurrentProfile.atrRatio;
    
    // ----- Xác định chế độ thị trường -----
    
    // Thị trường đang trending
    if (adx > 25)
    {
        if (m_CurrentProfile.trend == TREND_UP_NORMAL || m_CurrentProfile.trend == TREND_UP_STRONG)
            return REGIME_TRENDING_BULL;
        else if (m_CurrentProfile.trend == TREND_DOWN_NORMAL || m_CurrentProfile.trend == TREND_DOWN_STRONG)
            return REGIME_TRENDING_BEAR;
    }
    
    // Thị trường biến động cao
    if (atrRatio > m_VolatilityThreshold)
    {
        if (adx > m_MinAdxValue)
            return REGIME_VOLATILE_EXPANSION;  // Biến động cao + có xu hướng
        else
            return REGIME_RANGING_VOLATILE;   // Biến động cao không xu hướng
    }
    
    // Thị trường sideway có tổ chức
    if (IsSidewayMarket())
    {
        if (atrRatio < 0.8)
            return REGIME_RANGING_STABLE;      // Sideway ổn định
        else
            return REGIME_RANGING_VOLATILE;    // Sideway biến động
    }
    
    // Thị trường có xu hướng yếu
    if (adx > m_MinAdxValue && adx <= 25)
    {
        if (m_CurrentProfile.trend == TREND_UP_NORMAL || m_CurrentProfile.trend == TREND_UP_PULLBACK)
            return REGIME_TRENDING_BULL;
        else if (m_CurrentProfile.trend == TREND_DOWN_NORMAL || m_CurrentProfile.trend == TREND_DOWN_PULLBACK)
            return REGIME_TRENDING_BEAR;
        else
            return REGIME_RANGING_VOLATILE;
    }
    
    // Thị trường đang co hẹp biến động
    if (atrRatio < 0.7)
        return REGIME_VOLATILE_CONTRACTION;
    
    // Mặc định: ranging stable
    return REGIME_RANGING_STABLE;
}

//+------------------------------------------------------------------+
//| Hàm xác định phiên giao dịch hiện tại                           |
//+------------------------------------------------------------------+
ENUM_SESSION CMarketProfile::DetermineCurrentSession()
{
    // Lấy thời gian hiện tại (GMT)
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    
    int hour = dt.hour;
    
    // Xác định phiên giao dịch dựa trên giờ GMT
    if (hour >= 0 && hour < 7)
        return SESSION_ASIAN;         // Phiên Á
    else if (hour >= 7 && hour < 12)
        return SESSION_LONDON;        // Phiên London
    else if (hour >= 12 && hour < 16)
        return SESSION_EUROPEAN_AMERICAN; // Phiên giao thoa
    else if (hour >= 16 && hour < 20)
        return SESSION_NEWYORK;       // Phiên New York
    else
        return SESSION_CLOSING;       // Phiên đóng cửa
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra sự phân kỳ giữa các timeframe                      |
//+------------------------------------------------------------------+
bool CMarketProfile::IsMultiTimeframeAligned()
{
    if (!m_UseMultiTimeframe)
        return true;  // Nếu không sử dụng đa timeframe, luôn coi là đồng thuận
    
    // Kiểm tra khi trend tăng
    if (m_CurrentProfile.trend == TREND_UP_NORMAL || m_CurrentProfile.trend == TREND_UP_STRONG || 
        m_CurrentProfile.trend == TREND_UP_PULLBACK)
    {
        // H4 phải cùng xu hướng tăng
        return (m_CurrentProfile.ema34H4 > m_CurrentProfile.ema89H4);
    }
    
    // Kiểm tra khi trend giảm
    if (m_CurrentProfile.trend == TREND_DOWN_NORMAL || m_CurrentProfile.trend == TREND_DOWN_STRONG || 
        m_CurrentProfile.trend == TREND_DOWN_PULLBACK)
    {
        // H4 phải cùng xu hướng giảm
        return (m_CurrentProfile.ema34H4 < m_CurrentProfile.ema89H4);
    }
    
    // Mặc định: không có trend rõ ràng
    return false;
}

//+------------------------------------------------------------------+
//| Hàm tính toán độ dốc                                            |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateSlope(const double &buffer[], int periods)
{
    if (periods <= 1 || ArraySize(buffer) < periods)
        return 0;
    
    // Sử dụng Linear Regression
    double sum_x = 0, sum_y = 0, sum_xy = 0, sum_xx = 0;
    
    for (int i = 0; i < periods; i++)
    {
        sum_x += i;
        sum_y += buffer[i];
        sum_xy += i * buffer[i];
        sum_xx += i * i;
    }
    
    double n = (double)periods;
    double slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x);
    
    // Đảo dấu vì buffer là sắp xếp ngược (index 0 là mới nhất)
    return -slope;
}

//+------------------------------------------------------------------+
//| Hàm tính điểm mạnh của xu hướng                                 |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateTrendStrength()
{
    double score = 0.0;
    
    // 1. ADX - đóng góp 40%
    if (m_CurrentProfile.adxValue > 40)
        score += 0.4;
    else if (m_CurrentProfile.adxValue > 30)
        score += 0.3;
    else if (m_CurrentProfile.adxValue > 25)
        score += 0.25;
    else if (m_CurrentProfile.adxValue > 20)
        score += 0.2;
    else if (m_CurrentProfile.adxValue > m_MinAdxValue)
        score += 0.1;
    
    // 2. EMA Alignment - đóng góp 30%
    double emaSpread = CalculateEmaSpread(false);  // H1
    if (emaSpread > 1.0)
        score += 0.3;
    else if (emaSpread > 0.7)
        score += 0.25;
    else if (emaSpread > 0.5)
        score += 0.2;
    else if (emaSpread > 0.3)
        score += 0.1;
    else
        score += 0.05;
    
    // 3. Cũng xu hướng H4 - đóng góp 30%
    if (m_UseMultiTimeframe)
    {
        if (m_CurrentProfile.mtfAlignment != MTF_ALIGNMENT_CONFLICTING)
        {
            double emaSpreadH4 = CalculateEmaSpread(true);  // H4
            if (emaSpreadH4 > 1.0)
                score += 0.3;
            else if (emaSpreadH4 > 0.7)
                score += 0.25;
            else if (emaSpreadH4 > 0.5)
                score += 0.2;
            else if (emaSpreadH4 > 0.3)
                score += 0.1;
            else
                score += 0.05;
        }
    }
    else
    {
        // Nếu không sử dụng đa timeframe, cho điểm tối đa
        score += 0.3;
    }
    
    // Giới hạn trong khoảng 0.0 - 1.0
    return MathMin(score, 1.0);
}

//+------------------------------------------------------------------+
//| Hàm tính khoảng cách giữa các EMA                              |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateEmaSpread(bool useHigherTimeframe)
{
    double ema34, ema89, ema200, atr;
    
    if (useHigherTimeframe)
    {
        if (!m_UseMultiTimeframe)
            return 0.0;
        
        ema34 = m_CurrentProfile.ema34H4;
        ema89 = m_CurrentProfile.ema89H4;
        ema200 = m_CurrentProfile.ema200H4;
        atr = m_AtrBufferH4[0];
    }
    else
    {
        ema34 = m_CurrentProfile.ema34;
        ema89 = m_CurrentProfile.ema89;
        ema200 = m_CurrentProfile.ema200;
        atr = m_CurrentProfile.atrCurrent;
    }
    
    // Nếu ATR = 0, trả về 0 để tránh lỗi chia cho 0
    if (atr == 0)
        return 0.0;
    
    // Tính khoảng cách giữa các EMA, chuẩn hóa theo ATR
    double distance1 = MathAbs(ema34 - ema89) / atr;
    double distance2 = MathAbs(ema89 - ema200) / atr;
    
    // Lấy trung bình của hai khoảng cách
    return (distance1 + distance2) / 2.0;
}

//+------------------------------------------------------------------+
//| Hàm cập nhật lịch sử ATR                                        |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateAtrHistory()
{
    // Copy dữ liệu ATR từ D1
    double atrDailyBuffer[];
    ArraySetAsSeries(atrDailyBuffer, true);
    
    int handleAtrDaily = iATR(m_Symbol, PERIOD_D1, m_AtrPeriod);
    if (handleAtrDaily == INVALID_HANDLE)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to create daily ATR handle");
        
        return;
    }
    
    if (CopyBuffer(handleAtrDaily, 0, 0, 20, atrDailyBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy daily ATR data");
        
        IndicatorRelease(handleAtrDaily);
        return;
    }
    
    // Tính trung bình ATR 20 ngày
    double sumAtr = 0;
    int validCount = 0;
    
    for (int i = 0; i < ArraySize(atrDailyBuffer); i++)
    {
        if (atrDailyBuffer[i] > 0)
        {
            sumAtr += atrDailyBuffer[i];
            validCount++;
        }
    }
    
    if (validCount > 0)
        m_AverageDailyAtr = sumAtr / validCount;
    else
        m_AverageDailyAtr = 0;
    
    // Lưu lại lịch sử ATR
    if (validCount > 0)
        ArrayCopy(m_AtrHistory, atrDailyBuffer, 0, 0, MathMin(20, validCount));
    
    IndicatorRelease(handleAtrDaily);
    
    if (m_Logger != NULL && m_Logger.GetLogLevel() == LOG_DEBUG)
    {
        m_Logger.LogDebug("MarketProfileManager: Updated ATR history - Average Daily ATR: " + 
                       DoubleToString(m_AverageDailyAtr, _Digits));
    }
}

//+------------------------------------------------------------------+
//| Hàm cập nhật lịch sử spread                                     |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateSpreadHistory()
{
    // Lấy spread hiện tại
    double currentSpread = (double)SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(m_Symbol, SYMBOL_POINT);
    
    // Shift mảng
    for (int i = ArraySize(m_SpreadBuffer) - 1; i > 0; i--)
    {
        m_SpreadBuffer[i] = m_SpreadBuffer[i-1];
    }
    
    // Thêm spread mới vào đầu mảng
    m_SpreadBuffer[0] = currentSpread;
    
    // Tăng count nếu chưa đầy
    if (m_SpreadCount < ArraySize(m_SpreadBuffer))
        m_SpreadCount++;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra thị trường sideway                                 |
//+------------------------------------------------------------------+
bool CMarketProfile::IsSidewayMarket()
{
    // Kiểm tra điều kiện sideway dựa trên ADX
    if (m_CurrentProfile.adxValue < m_MinAdxValue)
        return true;
    
    // Kiểm tra bằng khoảng cách giữa các EMA
    double emaSpread = CalculateEmaSpread(false);
    if (emaSpread < 0.3)
        return true;
    
    // EMA tạo thành dải hẹp
    double ema34 = m_CurrentProfile.ema34;
    double ema89 = m_CurrentProfile.ema89;
    double ema200 = m_CurrentProfile.ema200;
    
    bool emaNarrow = (MathAbs(ema34 - ema89) < m_CurrentProfile.atrCurrent * 0.5) && 
                    (MathAbs(ema89 - ema200) < m_CurrentProfile.atrCurrent * 0.7);
    
    if (emaNarrow)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra thị trường choppy                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::IsChoppyMarket() const
{
    // Kiểm tra ADX thấp
    if (m_CurrentProfile.adxValue < m_MinAdxValue)
    {
        // Kiểm tra thêm độ biến động
        if (m_CurrentProfile.atrRatio < 0.8 || m_CurrentProfile.atrRatio > 1.5)
            return true;
        
        // Kiểm tra sự mâu thuẫn giữa các chỉ báo
        double diPlus = m_AdxPlusBuffer[0];
        double diMinus = m_AdxMinusBuffer[0];
        
        // DI+/DI- gần nhau -> không có ưu thế rõ ràng
        if (MathAbs(diPlus - diMinus) < 5)
            return true;
    }
    
    // Kiểm tra EMA cross thường xuyên
    int crossCount = 0;
    for (int i = 1; i < 10; i++)
    {
        if ((m_EmaFastBuffer[i] > m_EmaMediumBuffer[i] && m_EmaFastBuffer[i+1] <= m_EmaMediumBuffer[i+1]) ||
            (m_EmaFastBuffer[i] < m_EmaMediumBuffer[i] && m_EmaFastBuffer[i+1] >= m_EmaMediumBuffer[i+1]))
        {
            crossCount++;
        }
    }
    
    if (crossCount >= 2)  // 2 cross trong 10 nến -> choppy
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra động lượng thấp                                    |
//+------------------------------------------------------------------+
bool CMarketProfile::CheckLowMomentum()
{
    // Kiểm tra RSI ở vùng trung tính
    if (m_CurrentProfile.rsiValue > 45 && m_CurrentProfile.rsiValue < 55)
    {
        // Độ dốc RSI thấp
        if (MathAbs(m_CurrentProfile.rsiSlope) < 0.2)
            return true;
    }
    
    // Kiểm tra MACD Histogram gần 0
    if (MathAbs(m_CurrentProfile.macdHistogram) < 0.0001)
        return true;
    
    // Kiểm tra ADX và độ dốc
    if (m_CurrentProfile.adxValue < 20 && MathAbs(m_CurrentProfile.adxSlope) < 0.1)
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra thị trường biến động cao                          |
//+------------------------------------------------------------------+
bool CMarketProfile::CheckHighVolatility()
{
    // Kiểm tra tỷ lệ ATR
    if (m_CurrentProfile.atrRatio > m_VolatilityThreshold)
        return true;
    
    // Kiểm tra sự thay đổi lớn gần đây
    double maxMove = 0;
    for (int i = 1; i < 5; i++)
    {
        double moveSize = MathAbs(m_HighBuffer[i] - m_LowBuffer[i]) / m_CurrentProfile.atrCurrent;
        if (moveSize > maxMove)
            maxMove = moveSize;
    }
    
    if (maxMove > 1.5)  // Di chuyển > 1.5 ATR trong 1 nến
        return true;
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra giá trong vùng pullback                            |
//+------------------------------------------------------------------+
bool CMarketProfile::IsPriceInPullbackZone(bool isLong)
{
    double currentPrice = m_CloseBuffer[0];
    bool isPullbackZone = false;
    
    // Các hằng số quan trọng
    double MAX_PULLBACK_DEPTH = 1.5; // Khoảng cách tối đa tính theo ATR
    
    if (isLong)
    {
        // Vùng pullback trong xu hướng tăng:
        // 1. Giá đã pullback xuống gần/chạm EMA34
        // 2. Không vượt quá EMA89 quá nhiều
        // 3. KHÔNG BAO GIỜ phá EMA200
        
        isPullbackZone = (currentPrice <= m_CurrentProfile.ema34 * 1.001) && // Gần hoặc dưới EMA34 một chút
                        (currentPrice >= m_CurrentProfile.ema89 * 0.995) &&  // Không quá sâu dưới EMA89
                        (currentPrice > m_CurrentProfile.ema200);            // Luôn trên EMA200
        
        // Kiểm tra thêm khoảng cách hợp lý (không pullback quá sâu)
        double pullbackDepth = (m_CurrentProfile.recentSwingHigh - currentPrice) / m_CurrentProfile.atrCurrent;
        if (pullbackDepth > MAX_PULLBACK_DEPTH) {
            isPullbackZone = false; // Pullback quá sâu -> không vào lệnh
        }
    }
    else
    {
        // Vùng pullback trong xu hướng giảm - logic tương tự nhưng ngược lại
        isPullbackZone = (currentPrice >= m_CurrentProfile.ema34 * 0.999) && // Gần hoặc trên EMA34 một chút
                        (currentPrice <= m_CurrentProfile.ema89 * 1.005) &&  // Không quá cao trên EMA89
                        (currentPrice < m_CurrentProfile.ema200);            // Luôn dưới EMA200
        
        // Kiểm tra khoảng cách
        double pullbackDepth = (currentPrice - m_CurrentProfile.recentSwingLow) / m_CurrentProfile.atrCurrent;
        if (pullbackDepth > MAX_PULLBACK_DEPTH) {
            isPullbackZone = false;
        }
    }
    
    return isPullbackZone;
}

//+------------------------------------------------------------------+
//| Hàm tính % pullback dựa trên swing và EMA                        |
//+------------------------------------------------------------------+
double CMarketProfile::CalculatePullbackPercent(bool isLong)
{
    double currentPrice = m_CloseBuffer[0];
    double pullbackPercent = 0;
    
    if (isLong)
    {
        // Trong xu hướng tăng
        if (m_CurrentProfile.recentSwingHigh > m_CurrentProfile.ema34)
        {
            // Tính % từ swing high về EMA34
            double fullDistance = m_CurrentProfile.recentSwingHigh - m_CurrentProfile.ema34;
            
            // Nếu fullDistance quá nhỏ, tránh chia cho 0
            if (fullDistance > _Point * 10)
            {
                double currentPullback = m_CurrentProfile.recentSwingHigh - currentPrice;
                pullbackPercent = (currentPullback / fullDistance) * 100.0;
            }
        }
    }
    else
    {
        // Trong xu hướng giảm
        if (m_CurrentProfile.recentSwingLow < m_CurrentProfile.ema34)
        {
            // Tính % từ swing low về EMA34
            double fullDistance = m_CurrentProfile.ema34 - m_CurrentProfile.recentSwingLow;
            
            // Nếu fullDistance quá nhỏ, tránh chia cho 0
            if (fullDistance > _Point * 10)
            {
                double currentPullback = currentPrice - m_CurrentProfile.recentSwingLow;
                pullbackPercent = (currentPullback / fullDistance) * 100.0;
            }
        }
    }
    
    return pullbackPercent;
}

//+------------------------------------------------------------------+
//| Hàm phát hiện pullback chất lượng cao                            |
//+------------------------------------------------------------------+
bool CMarketProfile::IsPullbackDetected_HighQuality(SignalInfo &signal, const MarketProfileData &profile)
{
    // Bộ lọc #1: Chỉ xem xét khi thị trường không sideway/choppy/low momentum
    if (profile.isSidewaysOrChoppy || profile.isLowMomentum)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Market conditions unsuitable");
        
        return false;
    }
    
    // Bộ lọc #2: Kiểm tra xu hướng (chỉ quan tâm khi có pullback)
    if (profile.trend != TREND_UP_PULLBACK && profile.trend != TREND_DOWN_PULLBACK)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Not in pullback zone");
        
        return false;
    }
    
    // Xác định chiều xu hướng
    bool isLong = (profile.trend == TREND_UP_PULLBACK);
    
    // Bộ lọc #3: Xác nhận vùng pullback hợp lệ (khoảng cách thích hợp)
    if (!IsPriceInPullbackZone(isLong))
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Price not in valid pullback zone");
        
        return false;
    }
    
    // Tính % pullback
    double pullbackPercent = CalculatePullbackPercent(isLong);
    
    // Kiểm tra % pullback
    if (pullbackPercent < m_MinPullbackPercent || pullbackPercent > m_MaxPullbackPercent)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Pullback % outside acceptable range: " + 
                           DoubleToString(pullbackPercent, 1) + "% [" + 
                           DoubleToString(m_MinPullbackPercent, 1) + "%-" + 
                           DoubleToString(m_MaxPullbackPercent, 1) + "%]");
        
        return false;
    }
    
    // Bộ lọc #4: Xác nhận Price Action - QUAN TRỌNG NHẤT
    bool priceActionConfirmed = ValidatePriceAction(isLong);
    if (!priceActionConfirmed)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Price action not confirmed");
        
        return false;
    }
    
    // Bộ lọc #5: Xác nhận momentum
    bool momentumConfirmed = ValidateMomentum(isLong);
    
    // Bộ lọc #6: Xác nhận volume
    bool volumeConfirmed = ValidateVolume();
    
    // Cần có xác nhận momentum HOẶC volume
    if (!momentumConfirmed && !volumeConfirmed)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: Neither momentum nor volume confirmed");
        
        return false;
    }
    
    // Bộ lọc #7: Xác nhận Khung thời gian cao hơn (H4)
    if (profile.mtfAlignment == MTF_ALIGNMENT_CONFLICTING)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Pullback rejected: MTF alignment conflicting");
        
        return false;
    }
    
    // Điền thông tin tín hiệu
    signal.type = isLong ? SIGNAL_BUY : SIGNAL_SELL;
    signal.entryPrice = m_CloseBuffer[0];
    signal.quality = 0.8; // Điểm cơ bản tốt
    signal.scenario = SCENARIO_PULLBACK;
    signal.momentumConfirmed = momentumConfirmed;
    signal.volumeConfirmed = volumeConfirmed;
    signal.isValid = true;
    
    if (m_Logger != NULL)
    {
        string signalType = isLong ? "BUY" : "SELL";
        m_Logger.LogInfo("High quality pullback detected: " + signalType + 
                      ", Pullback: " + DoubleToString(pullbackPercent, 1) + "%, Quality: 0.8");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm xác nhận price action                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::ValidatePriceAction(bool isLong)
{
    double open1 = iOpen(m_Symbol, m_MainTimeframe, 1);
    double close1 = iClose(m_Symbol, m_MainTimeframe, 1);
    double high1 = iHigh(m_Symbol, m_MainTimeframe, 1);
    double low1 = iLow(m_Symbol, m_MainTimeframe, 1);
    
    double open2 = iOpen(m_Symbol, m_MainTimeframe, 2);
    double close2 = iClose(m_Symbol, m_MainTimeframe, 2);
    double high2 = iHigh(m_Symbol, m_MainTimeframe, 2);
    double low2 = iLow(m_Symbol, m_MainTimeframe, 2);
    
    // Xác nhận PA cho xu hướng tăng
    if (isLong)
    {
        // Kiểm tra Bullish Engulfing
        bool bullishEngulfing = (close1 > open1) &&          // Nến xanh
                              (close1 > open2) &&           // Đóng cửa trên mở cửa nến trước
                              (open1 < close2) &&           // Mở cửa dưới đóng cửa nến trước
                              (close1 - open1 > MathAbs(close2 - open2) * 0.8); // Thân lớn hơn
        
        // Kiểm tra Bullish Pinbar
        bool bullishPinbar = (low1 < low2) &&              // Tạo lower low
                           ((open1 - low1) > (high1 - close1) * 2) && // Bóng dưới dài
                           ((open1 - low1) > (open1 - close1) * 2);   // Bóng dưới > 2x thân
        
        // Kiểm tra Bullish Outside Bar
        bool bullishOutsideBar = (high1 > high2) && (low1 < low2) && (close1 > open1);
        
        if (bullishEngulfing)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bullish Engulfing");
            
            return true;
        }
        
        if (bullishPinbar)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bullish Pinbar");
            
            return true;
        }
        
        if (bullishOutsideBar)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bullish Outside Bar");
            
            return true;
        }
        
        // Kiểm tra rejection tại key level
        if (IsRejectionAtKeyLevel(true))
            return true;
    }
    // Xác nhận PA cho xu hướng giảm
    else
    {
        // Kiểm tra Bearish Engulfing
        bool bearishEngulfing = (close1 < open1) &&          // Nến đỏ
                              (close1 < open2) &&           // Đóng cửa dưới mở cửa nến trước
                              (open1 > close2) &&           // Mở cửa trên đóng cửa nến trước
                              (open1 - close1 > MathAbs(close2 - open2) * 0.8); // Thân lớn hơn
        
        // Kiểm tra Bearish Pinbar
        bool bearishPinbar = (high1 > high2) &&            // Tạo higher high
                           ((high1 - open1) > (close1 - low1) * 2) && // Bóng trên dài
                           ((high1 - open1) > (open1 - close1) * 2);  // Bóng trên > 2x thân
        
        // Kiểm tra Bearish Outside Bar
        bool bearishOutsideBar = (high1 > high2) && (low1 < low2) && (close1 < open1);
        
        if (bearishEngulfing)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bearish Engulfing");
            
            return true;
        }
        
        if (bearishPinbar)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bearish Pinbar");
            
            return true;
        }
        
        if (bearishOutsideBar)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Price action confirmed: Bearish Outside Bar");
            
            return true;
        }
        
        // Kiểm tra rejection tại key level
        if (IsRejectionAtKeyLevel(false))
            return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm xác nhận momentum                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::ValidateMomentum(bool isLong)
{
    // Lấy RSI slope
    double rsiSlope = m_CurrentProfile.rsiSlope;
    
    // Lấy MACD Histogram và slope
    double macdHist = m_CurrentProfile.macdHistogram;
    double macdHistSlope = m_CurrentProfile.macdHistogramSlope;
    
    if (isLong)
    {
        // Xác nhận momentum cho xu hướng tăng
        bool rsiConfirm = (m_CurrentProfile.rsiValue > 40.0) && (rsiSlope > 0.25);
        bool macdConfirm = (macdHist > 0 && macdHistSlope > 0) || (macdHist < 0 && macdHistSlope > 0.2);
        
        if (rsiConfirm || macdConfirm)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Momentum confirmed for bullish pullback");
            
            return true;
        }
    }
    else
    {
        // Xác nhận momentum cho xu hướng giảm
        bool rsiConfirm = (m_CurrentProfile.rsiValue < 60.0) && (rsiSlope < -0.25);
        bool macdConfirm = (macdHist < 0 && macdHistSlope < 0) || (macdHist > 0 && macdHistSlope < -0.2);
        
        if (rsiConfirm || macdConfirm)
        {
            if (m_Logger != NULL)
                m_Logger.LogDebug("Momentum confirmed for bearish pullback");
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm xác nhận volume                                             |
//+------------------------------------------------------------------+
bool CMarketProfile::ValidateVolume()
{
    // Get volume data
    long volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    
    if (CopyTickVolume(m_Symbol, m_MainTimeframe, 0, 30, volumeBuffer) <= 0)
    {
        if (m_Logger != NULL)
            m_Logger.LogError("MarketProfileManager: Failed to copy volume data - Error " + IntegerToString(GetLastError()));
        
        return false;
    }
    
    // Lấy volume hiện tại và nến trước
    long currentVolume = volumeBuffer[1]; // Nến đã hoàn thành
    
    // Tính volume trung bình 20 nến
    long avgVolume = 0;
    int count = 0;
    
    for (int i = 2; i < 22 && i < ArraySize(volumeBuffer); i++)
    {
        avgVolume += volumeBuffer[i];
        count++;
    }
    
    if (count == 0)
        return false;
    
    avgVolume = avgVolume / count;
    
    // Kiểm tra volume cao hơn trung bình 10%
    if (currentVolume > avgVolume * 1.1)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Volume confirmed: " + 
                           DoubleToString((double)currentVolume / (double)avgVolume * 100.0, 1) + 
                           "% of average");
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra rejection tại key level                            |
//+------------------------------------------------------------------+
bool CMarketProfile::IsRejectionAtKeyLevel(bool isLong)
{
    double currentPrice = m_CloseBuffer[0];
    double high1 = m_HighBuffer[1];
    double low1 = m_LowBuffer[1];
    double open1 = iOpen(m_Symbol, m_MainTimeframe, 1);
    double close1 = iClose(m_Symbol, m_MainTimeframe, 1);
    
    // Kiểm tra Pinbar tại key level
    bool isPinbar = false;
    
    if (isLong)
    {
        // Pinbar buy: bóng dưới dài, thân nhỏ ở trên
        double lowerWick = MathMin(open1, close1) - low1;
        double upperWick = high1 - MathMax(open1, close1);
        double body = MathAbs(open1 - close1);
        
        isPinbar = (lowerWick > body * 2) && (lowerWick > upperWick * 2);
    }
    else
    {
        // Pinbar sell: bóng trên dài, thân nhỏ ở dưới
        double lowerWick = MathMin(open1, close1) - low1;
        double upperWick = high1 - MathMax(open1, close1);
        double body = MathAbs(open1 - close1);
        
        isPinbar = (upperWick > body * 2) && (upperWick > lowerWick * 2);
    }
    
    // Không phải Pinbar -> không phải rejection
    if (!isPinbar)
        return false;
    
    // Kiểm tra khoảng cách đến các EMA
    double distanceToEma34 = MathAbs(currentPrice - m_CurrentProfile.ema34) / m_CurrentProfile.atrCurrent;
    double distanceToEma89 = MathAbs(currentPrice - m_CurrentProfile.ema89) / m_CurrentProfile.atrCurrent;
    
    // Pinbar xảy ra gần EMA
    if (distanceToEma34 < 0.3 || distanceToEma89 < 0.3)
    {
        if (m_Logger != NULL)
            m_Logger.LogDebug("Price action confirmed: Rejection at key EMA level");
        
        return true;
    }
    
    return false;

    // Kiểm tra ADX
    if (m_CurrentProfile.adxValue < 20)
        return false;
    
    // Kiểm tra trend score
    if (m_CurrentProfile.trendScore < 0.5)
        return false;
    
    // Kiểm tra MTF alignment
    if (m_CurrentProfile.mtfAlignment == MTF_ALIGNMENT_CONFLICTING)
        return false;
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm lấy giá trị EMA                                             |
//+------------------------------------------------------------------+
double CMarketProfile::GetEMA(int period, int shift)
{
    // Lấy giá trị EMA dựa trên chu kỳ
    if (period == m_EmaFast)
        return m_EmaFastBuffer[shift];
    else if (period == m_EmaMedium)
        return m_EmaMediumBuffer[shift];
    else if (period == m_EmaSlow)
        return m_EmaSlowBuffer[shift];
    
    return 0;
}

//+------------------------------------------------------------------+
//| Hàm lấy giá trị EMA từ timeframe cao hơn                        |
//+------------------------------------------------------------------+
double CMarketProfile::GetHigherTimeframeEMA(int period, int shift)
{
    if (!m_UseMultiTimeframe)
        return 0;
    
    // Lấy giá trị EMA dựa trên chu kỳ
    if (period == m_EmaFast)
        return m_EmaFastBufferH4[shift];
    else if (period == m_EmaMedium)
        return m_EmaMediumBufferH4[shift];
    else if (period == m_EmaSlow)
        return m_EmaSlowBufferH4[shift];
    
    return 0;
}

//+------------------------------------------------------------------+
//| Hàm giải phóng handle chỉ báo                                   |
//+------------------------------------------------------------------+
void CMarketProfile::ReleaseIndicatorHandles()
{
    // Giải phóng handle H1
    if (m_HandleEmaFast != INVALID_HANDLE) IndicatorRelease(m_HandleEmaFast);
    if (m_HandleEmaMedium != INVALID_HANDLE) IndicatorRelease(m_HandleEmaMedium);
    if (m_HandleEmaSlow != INVALID_HANDLE) IndicatorRelease(m_HandleEmaSlow);
    if (m_HandleAtr != INVALID_HANDLE) IndicatorRelease(m_HandleAtr);
    if (m_HandleAdx != INVALID_HANDLE) IndicatorRelease(m_HandleAdx);
    if (m_HandleRsi != INVALID_HANDLE) IndicatorRelease(m_HandleRsi);
    if (m_HandleMacd != INVALID_HANDLE) IndicatorRelease(m_HandleMacd);
    
    // Giải phóng handle H4
    if (m_HandleEmaFastH4 != INVALID_HANDLE) IndicatorRelease(m_HandleEmaFastH4);
    if (m_HandleEmaMediumH4 != INVALID_HANDLE) IndicatorRelease(m_HandleEmaMediumH4);
    if (m_HandleEmaSlowH4 != INVALID_HANDLE) IndicatorRelease(m_HandleEmaSlowH4);
    if (m_HandleAtrH4 != INVALID_HANDLE) IndicatorRelease(m_HandleAtrH4);
    if (m_HandleAdxH4 != INVALID_HANDLE) IndicatorRelease(m_HandleAdxH4);
    
    // Reset handles về INVALID_HANDLE
    m_HandleEmaFast = INVALID_HANDLE;
    m_HandleEmaMedium = INVALID_HANDLE;
    m_HandleEmaSlow = INVALID_HANDLE;
    m_HandleAtr = INVALID_HANDLE;
    m_HandleAdx = INVALID_HANDLE;
    m_HandleRsi = INVALID_HANDLE;
    m_HandleMacd = INVALID_HANDLE;
    
    m_HandleEmaFastH4 = INVALID_HANDLE;
    m_HandleEmaMediumH4 = INVALID_HANDLE;
    m_HandleEmaSlowH4 = INVALID_HANDLE;
    m_HandleAtrH4 = INVALID_HANDLE;
    m_HandleAdxH4 = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Hàm hỗ trợ - kiểm tra nến mới                                   |
//+------------------------------------------------------------------+
bool IsNewBar()
{
    static datetime last_time = 0;
    datetime current_time = iTime(_Symbol, PERIOD_CURRENT, 0);
    
    if (last_time == 0)
    {
        last_time = current_time;
        return false;
    }
    
    if (current_time != last_time)
    {
        last_time = current_time;
        return true;
    }
    
    return false;
}