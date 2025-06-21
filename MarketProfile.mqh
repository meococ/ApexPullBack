//+------------------------------------------------------------------+
//|                                         MarketProfile.mqh         |
//|                      APEX PULLBACK EA v14.0 - Professional Edition|
//|               Copyright 2023-2024, APEX Trading Systems           |
//+------------------------------------------------------------------+

#ifndef MARKETPROFILE_MQH_
#define MARKETPROFILE_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "CommonStructs.mqh"      // Core structures, enums, and inputs
#include "Enums.mqh"            // TẤT CẢ các enum


// === INCLUDES CỤ THỂ (NẾU CẦN) ===
// #include "Logger.mqh" // Logger is accessed via EAContext
// #include "IndicatorUtils.mqh" // IndicatorUtils is accessed via EAContext

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

//+------------------------------------------------------------------+
//| Class MarketProfile - Quản lý profile thị trường                  |
//+------------------------------------------------------------------+
class CMarketProfile
{
private:
    ApexPullback::EAContext* m_Context; // Con trỏ tới EAContext
    // Thông tin cơ bản
    string m_Symbol;                   // Symbol đang giao dịch
    ENUM_TIMEFRAMES m_MainTimeframe;   // Khung thời gian chính (H1)
    ENUM_TIMEFRAMES m_HigherTimeframe; // Khung thời gian cao hơn (H4)
    // CLogger* m_Logger; // Logger is now accessed via m_Context->Logger
    bool m_Initialized;                // Trạng thái khởi tạo
    bool m_UseMultiTimeframe;          // Sử dụng đa khung thời gian
    
    // Tham số cài đặt - will be accessed from m_Context->InputManager or m_Context directly
    // int m_EmaFast;                     // Chu kỳ EMA nhanh (34)
    // int m_EmaMedium;                   // Chu kỳ EMA trung bình (89)
    // int m_EmaSlow;                     // Chu kỳ EMA chậm (200)
    // int m_AtrPeriod;                   // Chu kỳ ATR (14)
    // int m_AdxPeriod;                   // Chu kỳ ADX (14)
    // int m_RsiPeriod;                   // Chu kỳ RSI (14)
    // int m_MacdFast;                    // Chu kỳ MACD nhanh (12)
    // int m_MacdSlow;                    // Chu kỳ MACD chậm (26)
    // int m_MacdSignal;                  // Chu kỳ đường tín hiệu MACD (9)
    // int m_BBWPeriod;                   // Chu kỳ Bollinger Bands Width (20)
    // double m_MinAdxValue;              // Giá trị ADX tối thiểu
    
    // Handle của các chỉ báo - Khung H1
    int m_HandleEmaFast;               // Handle EMA nhanh
    int m_HandleEmaMedium;             // Handle EMA trung bình
    int m_HandleEmaSlow;               // Handle EMA chậm
    int m_HandleAtr;                   // Handle ATR
    int m_HandleAdx;                   // Handle ADX
    int m_HandleRsi;                   // Handle RSI
    int m_HandleMacd;                  // Handle MACD
    int m_HandleBBW;                   // Handle Bollinger Bands (for Width)
    
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
    double m_BBWBuffer[];              // Buffer Bollinger Bands Width
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
    ApexPullback::MarketProfileData m_CurrentProfile; // Profile hiện tại
    double m_MomentumScore; // Điểm động lượng tổng hợp
    ApexPullback::MarketProfileData m_PreviousProfile; // Profile trước đó
    datetime m_LastUpdateTime;         // Thời gian cập nhật cuối
    
    // Dữ liệu lịch sử ATR
    double m_AverageDailyAtr;          // ATR trung bình hàng ngày
    double m_AtrHistory[];             // Lịch sử ATR 20 ngày
    double m_SpreadBuffer[];           // Buffer lưu lịch sử spread
    // Đã khai báo m_BBWBuffer[] ở trên - không khai báo lại để tránh lỗi duplicate
    int m_SpreadCount;                 // Số lượng spread đã lưu
    
    // Tham số lọc pullback - will be accessed from m_Context->InputManager or m_Context directly
    // double m_MinPullbackPercent;       // % Pullback tối thiểu
    // double m_MaxPullbackPercent;       // % Pullback tối đa
    
    // Tham số bổ sung - will be accessed from m_Context->InputManager or m_Context directly
    // bool m_EnableVolatilityFilter;     // Bật lọc volatility
    // bool m_EnableAdxFilter;            // Bật lọc ADX
    // double m_VolatilityThreshold;      // Ngưỡng volatility
    
    // ----- Các hàm private -----
    

    
    // Hàm tính toán độ dốc
    double CalculateSlope(const double &buffer[], int periods = 5);
    
    // Hàm phân tích xu hướng
    ApexPullback::ENUM_MARKET_TREND DetermineTrend();
    
    // Hàm phân tích chế độ thị trường
    ApexPullback::ENUM_MARKET_REGIME DetermineRegime();
    
    // Hàm xác định phiên giao dịch
    ApexPullback::ENUM_SESSION DetermineCurrentSession();
    
    // Hàm kiểm tra sự phân kỳ
    bool IsMultiTimeframeAligned();
    
    // Hàm tính điểm mạnh của xu hướng
    double CalculateTrendStrength();

    // Hàm tính điểm động lượng
    double CalculateMomentumScore();
    
    // Hàm tính khoảng cách giữa các EMA
    double CalculateEmaSpread(bool useHigherTimeframe = false);
    
    // Hàm cập nhật lịch sử ATR
    void UpdateAtrHistory();
    
    // Hàm cập nhật lịch sử spread
    void UpdateSpreadHistory();
    
    // [IsSidewayMarket đã được xóa để tránh trùng lập]
    
    // Hàm kiểm tra thị trường choppy
    bool IsChoppyMarket() const;
    
    // Hàm kiểm tra động lượng thấp
    bool CheckLowMomentum();
    
    // Hàm kiểm tra thị trường biến động cao
    bool CheckHighVolatility();
    
    // Hàm kiểm tra giá trong vùng pullback
    bool IsPriceInPullbackZone(bool isLong);
    
    // Hàm giải phóng handle chỉ báo ReleaseIndicatorHandles() đã được loại bỏ.
    // Logic giải phóng indicator handles được quản lý bởi CIndicatorUtils.
    double CalculateSidewaysScore(); // Private method to calculate the score
    
    // Hàm tính % pullback dựa trên swing và EMA
    double CalculatePullbackPercent(bool isLong);
    
    // Hàm kiểm tra nến mới
    bool IsNewBar() const;
    
    // Hàm khởi tạo các chỉ báo
    bool InitializeAllIndicators(bool isHigherTimeframe);
    
public:
    // Constructor và destructor
    CMarketProfile(ApexPullback::EAContext &context); // Constructor nhận reference EAContext
    ~CMarketProfile();
    
    // Initialization is now part of the constructor
    // bool Initialize(string symbol, ENUM_TIMEFRAMES mainTimeframe, int emaFast, int emaMedium, int emaSlow,
    //               bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe, ApexPullback::CLogger &logger);
    
    // Parameters are now set via EAContext or InputManager
    // void SetParameters(double minAdxValue, double maxAdxValue, double volatilityThreshold, ENUM_MARKET_PRESET preset);
    
    // Pullback parameters are now set via EAContext or InputManager
    // void SetPullbackParameters(double minPullbackPercent, double maxPullbackPercent);
    
    // Hàm cập nhật dữ liệu thị trường - gọi trong OnTimer()
    bool Update();
    
    // Hàm phát hiện Pullback chất lượng cao
    bool IsPullbackDetected_HighQuality(ApexPullback::SignalInfo &signal, const ApexPullback::MarketProfileData &profile);
    
    // Hàm xác nhận pattern price action
    bool ValidatePriceAction(bool isLong);
    
    // Hàm xác nhận momentum
    bool ValidateMomentum(bool isLong);
    
    // Hàm xác nhận volume
    bool ValidateVolume();
    
    // Hàm kiểm tra rejection tại key level
    bool IsRejectionAtKeyLevel(bool isLong);
    
    // Lấy profile thị trường hiện tại - gọi trong OnTick()
    ApexPullback::MarketProfileData GetLastProfile() const;
    
    // Hàm kiểm tra xu hướng đủ mạnh
    bool IsTrendStrongEnough() const;
    
    // ----- Các hàm getter -----
    
    // Lấy giá trị ATR trên khung H1 (mặc định) - buffer trực tiếp
    double GetATRFromBuffer() const { return m_AtrBuffer[0]; }
    
    // Lấy giá trị ATR trên khung H4 - được định nghĩa đầy đủ bên dưới
    double GetATRH4() const;
    
    // Lấy tỷ lệ biến động hiện tại so với trung bình
    double GetVolatilityRatio() const;
    
    // Lấy xu hướng hiện tại
    ApexPullback::ENUM_MARKET_TREND GetTrend() const { return m_CurrentProfile.trend; }
    
    // Lấy chế độ thị trường hiện tại
    ApexPullback::ENUM_MARKET_REGIME GetRegime() const { return m_CurrentProfile.regime; }
    
    // Lấy phiên giao dịch hiện tại
    ApexPullback::ENUM_SESSION GetCurrentSession() const { return m_CurrentProfile.currentSession; }
    
    // Lấy giá trị ATR hiện tại từ profile
    double GetATR() const { return m_CurrentProfile.atrCurrent; }
    
    // Lấy tỷ lệ ATR (so với trung bình)
    double GetATRRatio() const { return m_CurrentProfile.atrRatio; }
    
    // Lấy giá trị ADX
    double GetADX() const { return m_CurrentProfile.adxValue; }
    
    // Lấy độ dốc ADX
    double GetADXSlope() const { return m_CurrentProfile.adxSlope; }
    double GetBBW(int index = 0) const { return (index < ArraySize(m_BBWBuffer)) ? m_BBWBuffer[index] : 0; }

    // Sideways market detection
    bool IsSidewaysMarket();
    
    // Kiểm tra thị trường sideway hoặc choppy
    bool IsSidewaysOrChoppyMarket() const { return m_CurrentProfile.isSidewaysOrChoppy; }
    
    // Lấy giá trị EMA
    double GetEMA(int period, int shift = 0);
    
    // Lấy giá trị EMA từ timeframe cao hơn
    double GetHigherTimeframeEMA(int period, int shift = 0);
    
    // Lấy độ tin cậy của regime hiện tại
    double GetRegimeConfidence() const { return m_CurrentProfile.regimeConfidence; }
    
    // ----- Các hàm kiểm tra trạng thái thị trường -----
    
    // Kiểm tra thị trường sideway hoặc choppy
    bool IsSidewaysOrChoppy() const { return m_CurrentProfile.isSidewaysOrChoppy; }
    
    // Kiểm tra thị trường sideway
    bool IsSidewayMarket()
    {
        // Kiểm tra điều kiện sideway
        return (m_CurrentProfile.regime == ApexPullback::REGIME_RANGING && 
                m_CurrentProfile.isSidewaysOrChoppy && 
                m_CurrentProfile.atrRatio < m_Context->VolatilityThreshold);
    }
    
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
    bool IsVolatilityExtreme() const { return m_CurrentProfile.atrRatio > m_Context->VolatilityThreshold * 1.5; }

    // Lấy điểm sức mạnh động lượng
    double GetMomentumStrength() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketProfile::CMarketProfile(ApexPullback::EAContext &context) : m_Context(&context)
{
    // Khởi tạo các biến thành viên từ context
    m_Symbol = m_Context->Symbol;
    m_MainTimeframe = m_Context->MainTimeframe;
    m_HigherTimeframe = m_Context->HigherTimeframe;
    m_Initialized = false;
    m_UseMultiTimeframe = m_Context->UseMultiTimeframe;
    
    // Giá trị mặc định cho các handle chỉ báo
    m_HandleEmaFast = INVALID_HANDLE;
    m_HandleEmaMedium = INVALID_HANDLE;
    m_HandleEmaSlow = INVALID_HANDLE;
    m_HandleAtr = INVALID_HANDLE;
    m_HandleAdx = INVALID_HANDLE;
    m_HandleRsi = INVALID_HANDLE;
    m_HandleMacd = INVALID_HANDLE;
    m_HandleBBW = INVALID_HANDLE; // Initialize BBW handle
    
    m_HandleEmaFastH4 = INVALID_HANDLE;
    m_HandleEmaMediumH4 = INVALID_HANDLE;
    m_HandleEmaSlowH4 = INVALID_HANDLE;
    m_HandleAtrH4 = INVALID_HANDLE;
    m_HandleAdxH4 = INVALID_HANDLE;
    
    // Khởi tạo các giá trị mặc định khác
    m_LastUpdateTime = 0;
    m_AverageDailyAtr = 0;
    m_SpreadCount = 0;
    
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
    ArrayResize(m_BBWBuffer, 200); // Initialize BBW buffer size
    
    ArrayResize(m_EmaFastBufferH4, 50);
    ArrayResize(m_EmaMediumBufferH4, 50);
    ArrayResize(m_EmaSlowBufferH4, 50);
    ArrayResize(m_AtrBufferH4, 50);
    ArrayResize(m_AdxBufferH4, 50);
    
    ArrayResize(m_AtrHistory, 20);
    ArrayResize(m_SpreadBuffer, 50);

    // Log thông tin khởi tạo
    if (m_Context != NULL && m_Context->Logger != NULL) {
        string logMessage = StringFormat("MarketProfile: Initializing for %s, Timeframe: %s, EMAs: %d/%d/%d", 
                                      m_Symbol, 
                                      EnumToString(m_MainTimeframe), 
                                      m_Context->EMA_Fast, m_Context->EMA_Medium, m_Context->EMA_Slow);
        m_Context->Logger->LogInfo(logMessage);
    }  
    // Khởi tạo các chỉ báo
    if (!this->InitializeAllIndicators(false)) // Sử dụng InitializeAllIndicators cho khung thời gian chính
    {
        if (m_Context != NULL && m_Context->Logger != NULL) {
            m_Context->Logger->LogError("MarketProfile: Failed to initialize indicators");
        }
        // Constructor doesn't return bool, handle error appropriately
        // Consider throwing an exception or setting an error flag
        m_Initialized = false; // Set initialized to false on failure
        return; 
    }
    
    // Khởi tạo các chỉ báo trên khung H4
    if (m_UseMultiTimeframe)
    {
        if (!this->InitializeAllIndicators(true)) // Sử dụng InitializeAllIndicators với tham số true cho khung thời gian cao hơn
        {
            if (m_Context != NULL && m_Context->Logger != NULL) {
                m_Context->Logger->LogError("MarketProfile: Failed to initialize higher timeframe indicators");
            }
            // Constructor doesn't return bool, handle error appropriately
            // Consider throwing an exception or setting an error flag
            m_Initialized = false; // Set initialized to false on failure
            return; 
        }
    }
    
    // Khởi tạo lịch sử ATR
    this->UpdateAtrHistory();
    
    m_Initialized = true;
    
    if (m_Context != NULL && m_Context->Logger != NULL) {
        m_Context->Logger->LogInfo("MarketProfile: Initialized successfully");
    } 

}

//+------------------------------------------------------------------+
//| Lấy điểm sức mạnh động lượng                                     |
//+------------------------------------------------------------------+
double CMarketProfile::GetMomentumStrength() const
{
    return m_CurrentProfile.momentumScore;
}

//+------------------------------------------------------------------+
//| Tính toán điểm động lượng tổng hợp                               |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateMomentumScore()
{
    // --- Trọng số cho các thành phần ---
    const double w_rsi = 0.30;      // Trọng số cho RSI (vị trí & độ dốc)
    const double w_macd = 0.40;     // Trọng số cho MACD Histogram (giá trị & độ dốc)
    const double w_adx = 0.15;      // Trọng số cho ADX (sức mạnh xu hướng)
    const double w_price_ema = 0.15; // Trọng số cho vị trí giá so với EMA nhanh

    // --- 1. Đánh giá RSI ---
    double rsi_score = 0;
    double rsi_value = m_CurrentProfile.rsiValue;
    double rsi_slope = m_CurrentProfile.rsiSlope;
    if (rsi_value > 55) rsi_score += 0.5; // Vùng tăng giá
    if (rsi_value < 45) rsi_score -= 0.5; // Vùng giảm giá
    if (rsi_slope > 0) rsi_score += 0.5;  // Đang dốc lên
    if (rsi_slope < 0) rsi_score -= 0.5;  // Đang dốc xuống
    rsi_score = fmax(-1.0, fmin(1.0, rsi_score)); // Chuẩn hóa trong [-1, 1]

    // --- 2. Đánh giá MACD Histogram ---
    double macd_score = 0;
    double macd_hist = m_CurrentProfile.macdHistogram;
    double macd_hist_slope = m_CurrentProfile.macdHistogramSlope;
    // Sử dụng giá trị ATR để chuẩn hóa histogram
    double normalized_hist = (m_CurrentProfile.atrCurrent > 0) ? macd_hist / m_CurrentProfile.atrCurrent : 0;
    if (normalized_hist > 0.05) macd_score += 0.5; // Tăng giá rõ rệt
    if (normalized_hist < -0.05) macd_score -= 0.5; // Giảm giá rõ rệt
    if (macd_hist_slope > 0) macd_score += 0.5; // Động lượng tăng
    if (macd_hist_slope < 0) macd_score -= 0.5; // Động lượng giảm
    macd_score = fmax(-1.0, fmin(1.0, macd_score)); // Chuẩn hóa

    // --- 3. Đánh giá ADX ---
    double adx_score = 0;
    if (m_CurrentProfile.adxValue > 25) {
        if (m_CurrentProfile.diPlus > m_CurrentProfile.diMinus) adx_score = 1.0; // Xu hướng tăng mạnh
        else adx_score = -1.0; // Xu hướng giảm mạnh
    }

    // --- 4. Đánh giá vị trí giá so với EMA nhanh ---
    double price_ema_score = 0;
    if (m_CurrentProfile.currentPrice > m_CurrentProfile.emaFast) price_ema_score = 1.0;
    else if (m_CurrentProfile.currentPrice < m_CurrentProfile.emaFast) price_ema_score = -1.0;

    // --- 5. Tính điểm tổng hợp ---
    double total_score = (rsi_score * w_rsi) +
                         (macd_score * w_macd) +
                         (adx_score * w_adx) +
                         (price_ema_score * w_price_ema);

    // Chuẩn hóa điểm cuối cùng về thang điểm từ -1.0 (rất yếu) đến +1.0 (rất mạnh)
    return fmax(-1.0, fmin(1.0, total_score));
}


//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketProfile::~CMarketProfile()
{
    // Giải phóng tất cả handle chỉ báo
    // Logic giải phóng indicator handles được quản lý bởi CIndicatorUtils.
}

// Initialize, SetParameters, and SetPullbackParameters are now part of the constructor or use EAContext directly.

//+------------------------------------------------------------------+
//| Hàm cập nhật dữ liệu thị trường - gọi trong OnTimer()           |
//+------------------------------------------------------------------+
bool CMarketProfile::Update()
{
    // Kiểm tra xem đã đến lúc cập nhật chưa (60s một lần)
    datetime currentTime = TimeCurrent();
    if (m_LastUpdateTime > 0 && currentTime - m_LastUpdateTime < m_Context->UpdateFrequencySeconds && !this->IsNewBar())
    {
        // Chưa đến lúc cập nhật, trả về true nhưng không làm gì
        return true;
    }
    
    // Lưu profile hiện tại vào profile trước đó
    m_PreviousProfile = m_CurrentProfile;
    
    // Khởi tạo profile mới
    m_CurrentProfile = ApexPullback::MarketProfileData();
    
    // ----- Cập nhật dữ liệu giá và các chỉ báo -----
    if (m_Context == NULL) {
        Print("Error: EAContext is NULL in CMarketProfile::Update. Cannot update market data.");
        return false;
    }

    if (m_Context->Logger == NULL) {
        Print("Warning: Logger is NULL in CMarketProfile::Update.");
    }

    // Cập nhật dữ liệu giá cơ bản
    MqlRates rates[];
    int rates_total = CopyRates(m_Symbol, m_MainTimeframe, 0, 2, rates); // Lấy 2 nến gần nhất
    if(rates_total < 2) {
        if(m_Context != NULL && m_Context->Logger != NULL) m_Context->Logger->LogWarning("MarketProfile: Not enough bars to update market data.");
        return false;
    }
    m_CurrentProfile.currentPrice = rates[0].close;
    m_CurrentProfile.currentHigh = rates[0].high;
    m_CurrentProfile.currentLow = rates[0].low;
    m_CurrentProfile.currentOpen = rates[0].open;
    m_CurrentProfile.previousPrice = rates[1].close;

    // Cập nhật Spread
    MqlTick last_tick;
    if(SymbolInfoTick(m_Symbol, last_tick)) {
        m_CurrentProfile.currentSpread = (last_tick.ask - last_tick.bid) / SymbolInfoDouble(m_Symbol, SYMBOL_POINT);
    } else {
        if(m_Context != NULL && m_Context->Logger != NULL) m_Context->Logger->LogWarning("MarketProfile: Failed to get current tick for spread.");
        m_CurrentProfile.currentSpread = -1; // Giá trị không hợp lệ
    }
    this->UpdateSpreadHistory(); // Cập nhật lịch sử spread

    // Cập nhật ATR
    double atr_values[];
    if(CopyBuffer(m_HandleAtr, 0, 0, 1, atr_values) > 0) {
        m_CurrentProfile.atrCurrent = atr_values[0];
    } else {
        if(m_Context != NULL && m_Context->Logger != NULL) m_Context->Logger->LogWarning("MarketProfile: Failed to copy ATR buffer.");
        m_CurrentProfile.atrCurrent = 0;
    }
    this->UpdateAtrHistory(); // Cập nhật lịch sử ATR và ATR trung bình
    m_CurrentProfile.averageDailyAtr = m_AverageDailyAtr;
    if (m_AverageDailyAtr > 0) {
        m_CurrentProfile.atrRatio = m_CurrentProfile.atrCurrent / m_AverageDailyAtr;
    } else {
        m_CurrentProfile.atrRatio = 1.0; // Tránh chia cho 0
    }

    // Cập nhật ADX
    double adx_main[];
    double adx_plus[];
    double adx_minus[];
    if(CopyBuffer(m_HandleAdx, 0, 0, 2, adx_main) > 0 && 
       CopyBuffer(m_HandleAdx, 1, 0, 1, adx_plus) > 0 && 
       CopyBuffer(m_HandleAdx, 2, 0, 1, adx_minus) > 0) {
        m_CurrentProfile.adxValue = adx_main[0];
        m_CurrentProfile.adxSlope = adx_main[0] - adx_main[1];
        m_CurrentProfile.diPlus = adx_plus[0];
        m_CurrentProfile.diMinus = adx_minus[0];
    } else {
        if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy ADX buffers.");
        m_CurrentProfile.adxValue = 0;
        m_CurrentProfile.adxSlope = 0;
        m_CurrentProfile.diPlus = 0;
        m_CurrentProfile.diMinus = 0;
    }

    // Cập nhật RSI
    double rsi_values[];
    if(CopyBuffer(m_HandleRsi, 0, 0, 1, rsi_values) > 0) {
        m_CurrentProfile.rsiValue = rsi_values[0];
    } else {
        if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy RSI buffer.");
        m_CurrentProfile.rsiValue = 50; // Giá trị trung tính
    }

    // Cập nhật MACD
    double macd_main[];
    double macd_signal[];
    if(CopyBuffer(m_HandleMacd, 0, 0, 1, macd_main) > 0 && CopyBuffer(m_HandleMacd, 1, 0, 1, macd_signal) > 0) {
        m_CurrentProfile.macdValue = macd_main[0];
        m_CurrentProfile.macdSignal = macd_signal[0];
        m_CurrentProfile.macdHistogram = m_CurrentProfile.macdValue - m_CurrentProfile.macdSignal;
    } else {
        if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy MACD buffers.");
        m_CurrentProfile.macdValue = 0;
        m_CurrentProfile.macdSignal = 0;
        m_CurrentProfile.macdHistogram = 0;
    }

    // Cập nhật Bollinger Bands Width (BBW)
    double bbw_values[];
    if(CopyBuffer(m_HandleBBW, 0, 0, 1, bbw_values) > 0) {
        m_CurrentProfile.bbWidth = bbw_values[0];
    } else {
        if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy BBW buffer.");
        m_CurrentProfile.bbWidth = 0;
    }

    // Cập nhật EMA values
    double ema_fast[], ema_medium[], ema_slow[];
    if (CopyBuffer(m_HandleEmaFast, 0, 0, 1, ema_fast) > 0) m_CurrentProfile.emaFast = ema_fast[0];
    else if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy EMA Fast buffer.");

    if (CopyBuffer(m_HandleEmaMedium, 0, 0, 1, ema_medium) > 0) m_CurrentProfile.emaMedium = ema_medium[0];
    else if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy EMA Medium buffer.");

    if (CopyBuffer(m_HandleEmaSlow, 0, 0, 1, ema_slow) > 0) m_CurrentProfile.emaSlow = ema_slow[0];
    else if(m_Context->Logger) m_Context->Logger->LogWarning("MarketProfile: Failed to copy EMA Slow buffer.");

    // Cập nhật các thông tin khác nếu cần
    m_CurrentProfile.timestamp = currentTime;
    m_CurrentProfile.symbol = m_Symbol;
    m_CurrentProfile.timeframe = m_MainTimeframe;

    // Xác định Trend, Regime, Session
    m_CurrentProfile.trend = this->DetermineTrend();
    m_CurrentProfile.regime = this->DetermineRegime();
    m_CurrentProfile.currentSession = this->DetermineCurrentSession();

    // Tính toán các chỉ số tổng hợp
    m_CurrentProfile.isTrending = (m_CurrentProfile.regime == ApexPullback::REGIME_TRENDING);
    m_CurrentProfile.isSidewaysOrChoppy = this->IsSidewaysOrChoppyMarket(); // Sử dụng hàm đã có
    m_CurrentProfile.isLowMomentum = this->CheckLowMomentum();
    m_CurrentProfile.isVolatile = this->CheckHighVolatility();
    m_CurrentProfile.isMultiTimeframeAligned = this->IsMultiTimeframeAligned();
    m_CurrentProfile.trendStrength = this->CalculateTrendStrength();
    m_CurrentProfile.momentumScore = this->CalculateMomentumScore();
    m_CurrentProfile.emaSpread = this->CalculateEmaSpread(false);
    if (m_UseMultiTimeframe) {
        m_CurrentProfile.emaSpreadH4 = this->CalculateEmaSpread(true);
    }
    m_CurrentProfile.regimeConfidence = this->CalculateSidewaysScore(); // Hoặc một hàm tính độ tin cậy regime khác

    if(m_Context->Logger) m_Context->Logger->LogDebug(StringFormat("MarketProfile Updated: %s, Price: %.5f, Trend: %s, Regime: %s", 
                                        m_Symbol, m_CurrentProfile.currentPrice, 
                                        EnumToString(m_CurrentProfile.trend), EnumToString(m_CurrentProfile.regime)));

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
        if (m_Context != NULL && m_Context->Logger != NULL) {
            m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy price data - Error %d", GetLastError()));
        }
        
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
        if (m_Context != NULL && m_Context->Logger != NULL) {
            m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy EMA data - Error %d", GetLastError()));
        }
        
        return false;
    }
    
    // Copy dữ liệu ATR
    if (CopyBuffer(m_HandleAtr, 0, 0, 100, m_AtrBuffer) <= 0)
    {
        if (m_Context != NULL && m_Context->Logger != NULL) {
            m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy ATR data - Error %d", GetLastError()));
        }
        
        return false;
    }
    
    // Copy dữ liệu ADX
    if (CopyBuffer(m_HandleAdx, 0, 0, 100, m_AdxBuffer) <= 0 ||
        CopyBuffer(m_HandleAdx, 1, 0, 100, m_AdxPlusBuffer) <= 0 ||
        CopyBuffer(m_HandleAdx, 2, 0, 100, m_AdxMinusBuffer) <= 0)
    {
        if (m_Context != NULL && m_Context->Logger != NULL) {
            m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy ADX data - Error %d", GetLastError()));
        }
        
        return false;
    }
    
    // Copy dữ liệu RSI
    if (CopyBuffer(m_HandleRsi, 0, 0, 100, m_RsiBuffer) <= 0)
    {
        if (m_Context != NULL && m_Context->Logger != NULL) {
            string logMessage = StringFormat("MarketProfile: Failed to copy RSI data - Error %d", GetLastError());
            m_Context->Logger->LogError(logMessage);
        }
        
        return false;
    }
    
    // Copy dữ liệu MACD
    if (CopyBuffer(m_HandleMacd, 0, 0, 100, m_MacdBuffer) <= 0 ||
        CopyBuffer(m_HandleMacd, 1, 0, 100, m_MacdSignalBuffer) <= 0)
    {
        if (m_Context != NULL && m_Context->Logger != NULL) {
            string logMessage = StringFormat("MarketProfile: Failed to copy MACD data - Error %d", GetLastError());
            m_Context->Logger->LogError(logMessage);
        }
        
        return false;
    }

    // Copy Bollinger Bands data and calculate BBW
    // iBands: buffer 0 = Middle, 1 = Upper, 2 = Lower
    // Chuyển từ mảng cấp phát tĩnh sang mảng cấp phát động để có thể dùng ArraySetAsSeries
    double upperBand[];
    double lowerBand[];
    double middleBand[];
    
    // Cấp phát động cho các mảng
    ArrayResize(upperBand, 100);
    ArrayResize(lowerBand, 100);
    ArrayResize(middleBand, 100);
    
    // Đảm bảo m_BBWBuffer cũng được cấp phát đủ kích thước
    ArrayResize(m_BBWBuffer, MathMax(ArraySize(m_BBWBuffer), 100));
    
    // Cấu hình mảng
    ArraySetAsSeries(upperBand, true);
    ArraySetAsSeries(lowerBand, true);
    ArraySetAsSeries(middleBand, true);
    ArraySetAsSeries(m_BBWBuffer, true);

    if (m_HandleBBW != INVALID_HANDLE && 
        (CopyBuffer(m_HandleBBW, 0, 0, 100, middleBand) <= 0 ||
         CopyBuffer(m_HandleBBW, 1, 0, 100, upperBand) <= 0 ||
         CopyBuffer(m_HandleBBW, 2, 0, 100, lowerBand) <= 0))
    {
        if (m_Context->Logger != NULL) {
            m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy Bollinger Bands data - Error %d", GetLastError()));
        }
        // Decide if this is a fatal error or if we can proceed without BBW
        // For now, let's log and continue, BBW score will be 0 if data is missing.
        // return false; 
    }
    else if (m_HandleBBW != INVALID_HANDLE)
    {
        for(int i = 0; i < 100; i++)
        {
            // Sử dụng 0 hoặc EMPTY_VALUE thay thế INVALID_VALUE để tránh lỗi
            // EMPTY_VALUE là hằng số có sẵn trong MQL5
            if(middleBand[i] != 0 && MathIsValidNumber(middleBand[i]) && MathIsValidNumber(upperBand[i]) && MathIsValidNumber(lowerBand[i])) 
                m_BBWBuffer[i] = (upperBand[i] - lowerBand[i]) / middleBand[i]; 
            else if (MathIsValidNumber(upperBand[i]) && MathIsValidNumber(lowerBand[i])) // Fallback if middle is zero or invalid
                 m_BBWBuffer[i] = upperBand[i] - lowerBand[i]; // Simplified: Upper - Lower
            else
                m_BBWBuffer[i] = 0;
        }
    }
    else
    {
        // HandleBBW is invalid, fill BBWBuffer with 0s
        for(int i = 0; i < 100; i++) m_BBWBuffer[i] = 0;
        if (m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled()) {
             m_Context->Logger->LogDebug("MarketProfile: m_HandleBBW is INVALID_HANDLE. BBW data will be zero.");
        }
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
            if (m_Context != NULL && m_Context->Logger != NULL) {
                m_Context->Logger->LogError(StringFormat("MarketProfile: Failed to copy H4 EMA data - Error %d", GetLastError()));
            }
            
            return false;
        }
        
        // Copy dữ liệu ATR H4
        if (CopyBuffer(m_HandleAtrH4, 0, 0, 50, m_AtrBufferH4) <= 0)
        {
            if (m_Context != NULL && m_Context->Logger != NULL) {
                string logMessage = StringFormat("MarketProfile: Failed to copy H4 ATR data - Error %d", GetLastError());
                m_Context->Logger->LogError(logMessage);
            }
            
            return false;
        }
        
        // Copy dữ liệu ADX H4
        if (CopyBuffer(m_HandleAdxH4, 0, 0, 50, m_AdxBufferH4) <= 0)
        {
            if (m_Context != NULL && m_Context->Logger != NULL) {
                string logMessage = StringFormat("MarketProfile: Failed to copy H4 ADX data - Error %d", GetLastError());
                m_Context->Logger->LogError(logMessage);
            }
            
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
    m_CurrentProfile.adxSlope = this->CalculateSlope(m_AdxBuffer, 5);
    m_CurrentProfile.minAdxValue = m_Context->MinAdxValue; // Store Min ADX from context
    
    // Cập nhật giá trị RSI và Slope
    m_CurrentProfile.rsiValue = m_RsiBuffer[0];
    m_CurrentProfile.rsiSlope = this->CalculateSlope(m_RsiBuffer, 5);
    
    // Cập nhật giá trị MACD
    m_CurrentProfile.macdHistogram = m_MacdHistBuffer[0];
    m_CurrentProfile.macdHistogramSlope = this->CalculateSlope(m_MacdHistBuffer, 5);
    
    // ----- Phân tích thị trường -----
    
    // Xác định xu hướng
    m_CurrentProfile.trend = this->DetermineTrend();
    
    // Xác định chế độ thị trường
    m_CurrentProfile.regime = this->DetermineRegime();
    
    // Xác định phiên giao dịch
    m_CurrentProfile.currentSession = this->DetermineCurrentSession();
    
    // Kiểm tra sự phân kỳ giữa các timeframe
    m_CurrentProfile.mtfAlignment = this->IsMultiTimeframeAligned() ? 
        (m_CurrentProfile.trend == ApexPullback::TREND_UP_NORMAL || m_CurrentProfile.trend == ApexPullback::TREND_UP_STRONG ? 
         ApexPullback::MTF_ALIGNMENT_BULLISH : (m_CurrentProfile.trend == ApexPullback::TREND_DOWN_NORMAL || m_CurrentProfile.trend == ApexPullback::TREND_DOWN_STRONG ? ApexPullback::MTF_ALIGNMENT_BEARISH : ApexPullback::MTF_ALIGNMENT_NEUTRAL)) : 
        ApexPullback::MTF_ALIGNMENT_CONFLICTING;
    
    // Tính điểm mạnh của xu hướng
    m_CurrentProfile.trendScore = this->CalculateTrendStrength();
    
    // Kiểm tra thị trường đang trending
    m_CurrentProfile.isTrending = (m_CurrentProfile.adxValue > m_Context->MinAdxValue);
    
    // Kiểm tra các cờ đặc biệt
    m_CurrentProfile.isSidewaysOrChoppy = this->IsSidewayMarket() || this->IsChoppyMarket();
    m_CurrentProfile.isLowMomentum = this->CheckLowMomentum();
    m_CurrentProfile.isVolatile = this->CheckHighVolatility();
    
    // Kiểm tra thị trường đang chuyển đổi chế độ
    double regimeConfidence = 0.0;
    
    // Tính độ tin cậy của regime dựa trên ADX, EMA alignment, và trendScore
    if (m_CurrentProfile.adxValue > 30)
        regimeConfidence += 0.4;  // ADX cao -> độ tin cậy cao
    else if (m_CurrentProfile.adxValue > 20)
        regimeConfidence += 0.3;
    else if (m_CurrentProfile.adxValue > m_Context->MinAdxValue)
        regimeConfidence += 0.2;
    else
        regimeConfidence += 0.1;
    
    // EMA alignment
    double emaSpreadH1 = this->CalculateEmaSpread(false);
    double emaSpreadH4 = this->CalculateEmaSpread(true);
    
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
    this->UpdateSpreadHistory();
    
    // Cập nhật thời gian
    m_LastUpdateTime = currentTime;
    
    // Ghi log chi tiết nếu cần
    if (m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled())
    {
        string profileInfo = StringFormat(
            "Market Profile [%s]: Trend=%s, Regime=%s, Session=%s, ADX=%.1f (Min: %.1f), ATR=%.5f (%.1fx), RSI=%.1f",
            m_Symbol,
            EnumToString(m_CurrentProfile.trend),
            EnumToString(m_CurrentProfile.regime),
            EnumToString(m_CurrentProfile.currentSession),
            m_CurrentProfile.adxValue,
            m_CurrentProfile.minAdxValue, // Log Min ADX
            m_CurrentProfile.atrCurrent,
            m_CurrentProfile.atrRatio,
            m_CurrentProfile.rsiValue
        );
        
        m_Context->Logger->LogDebug(profileInfo);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm xác định xu hướng thị trường                                |
//+------------------------------------------------------------------+
ApexPullback::ENUM_MARKET_TREND CMarketProfile::DetermineTrend()
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
    // Truy cập MinAdxValue qua con trỏ m_Context
    bool moderateADX = (adx > m_Context->MinAdxValue && adx <= 25); 
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
            return ApexPullback::TREND_UP_PULLBACK;
        else
            return ApexPullback::TREND_UP_NORMAL;
    }
    
    // Xu hướng giảm
    if (emaDownAligned && (moderateADX || diMinusStronger))
    {
        // Kiểm tra pullback
        double close = m_CloseBuffer[0];
        if (close > ema34)
            return ApexPullback::TREND_DOWN_PULLBACK;
        else
            return ApexPullback::TREND_DOWN_NORMAL;
    }
    
    // Không có xu hướng rõ ràng
    return ApexPullback::TREND_SIDEWAY;
}

//+------------------------------------------------------------------+
//| Hàm xác định chế độ thị trường                                  |
//+------------------------------------------------------------------+
ApexPullback::ENUM_MARKET_REGIME CMarketProfile::DetermineRegime()
{
    // Lấy các giá trị hiện tại
    double adx = m_AdxBuffer[0];
    double currentAtrRatio = m_CurrentProfile.atrRatio; // Đổi tên biến để tránh xung đột nếu có
    ApexPullback::ENUM_MARKET_TREND currentTrend = m_CurrentProfile.trend;

    // ----- Xác định chế độ thị trường -----
    
    // Thị trường đang trending
    if (adx > 25)
    {
        if (currentTrend == ApexPullback::TREND_UP_NORMAL || currentTrend == ApexPullback::TREND_UP_STRONG)
            return ApexPullback::REGIME_TRENDING_BULL;
        else if (currentTrend == ApexPullback::TREND_DOWN_NORMAL || currentTrend == ApexPullback::TREND_DOWN_STRONG)
            return ApexPullback::REGIME_TRENDING_BEAR;
    }
    
    // Thị trường biến động cao
    // Truy cập VolatilityThreshold qua con trỏ m_Context
    if (currentAtrRatio > m_Context->VolatilityThreshold) 
    {
        // Truy cập MinAdxValue qua con trỏ m_Context
        if (adx > m_Context->MinAdxValue) 
            return ApexPullback::REGIME_VOLATILE_EXPANSION;  // Biến động cao + có xu hướng
        else
            return ApexPullback::REGIME_RANGING_VOLATILE;   // Biến động cao không xu hướng
    }
    
    // Thị trường sideway có tổ chức
    if (IsSidewayMarket()) // Gọi hàm thành viên trực tiếp
    {
        if (currentAtrRatio < 0.8)
            return ApexPullback::REGIME_RANGING_STABLE;      // Sideway ổn định
        else
            return ApexPullback::REGIME_RANGING_VOLATILE;    // Sideway biến động
    }
    
    // Thị trường có xu hướng yếu
    // Truy cập MinAdxValue qua con trỏ m_Context
    if (adx > m_Context->MinAdxValue && adx <= 25) 
    {
        if (currentTrend == ApexPullback::TREND_UP_NORMAL || currentTrend == ApexPullback::TREND_UP_PULLBACK)
            return ApexPullback::REGIME_TRENDING_BULL;
        else if (currentTrend == ApexPullback::TREND_DOWN_NORMAL || currentTrend == ApexPullback::TREND_DOWN_PULLBACK)
            return ApexPullback::REGIME_TRENDING_BEAR;
        else
            return ApexPullback::REGIME_RANGING_VOLATILE;
    }
    
    // Thị trường đang co hẹp biến động
    if (currentAtrRatio < 0.7)
        return ApexPullback::REGIME_VOLATILE_CONTRACTION;
    
    // Mặc định: ranging stable
    return ApexPullback::REGIME_RANGING_STABLE;
}

//+------------------------------------------------------------------+
//| Hàm xác định phiên giao dịch hiện tại                           |
//+------------------------------------------------------------------+
ApexPullback::ENUM_SESSION CMarketProfile::DetermineCurrentSession()
{
    // Lấy thời gian hiện tại (GMT)
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    
    int hour = dt.hour;
    
    // Xác định phiên giao dịch dựa trên giờ GMT
    if (hour >= 0 && hour < 7)
        return ApexPullback::SESSION_ASIAN;         // Phiên Á
    else if (hour >= 7 && hour < 12)
        return ApexPullback::SESSION_EUROPEAN;        // Phiên Âu (London)
    else if (hour >= 12 && hour < 16)
        return ApexPullback::SESSION_EUROPEAN_AMERICAN; // Phiên giao thoa Âu-Mỹ
    else if (hour >= 16 && hour < 20)
        return ApexPullback::SESSION_AMERICAN;       // Phiên Mỹ (New York)
    else
        return ApexPullback::SESSION_CLOSING;       // Phiên đóng cửa
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra sự phân kỳ giữa các timeframe                      |
//+------------------------------------------------------------------+
bool CMarketProfile::IsMultiTimeframeAligned()
{
    if (!m_UseMultiTimeframe)
        return true;  // Nếu không sử dụng đa timeframe, luôn coi là đồng thuận
    
    ApexPullback::ENUM_MARKET_TREND currentTrend = m_CurrentProfile.trend;
    // Kiểm tra khi trend tăng
    if (currentTrend == ApexPullback::TREND_UP_NORMAL || currentTrend == ApexPullback::TREND_UP_STRONG || 
        currentTrend == ApexPullback::TREND_UP_PULLBACK)
    {
        // H4 phải cùng xu hướng tăng
        return (m_CurrentProfile.ema34H4 > m_CurrentProfile.ema89H4);
    }
    
    // Kiểm tra khi trend giảm
    if (currentTrend == ApexPullback::TREND_DOWN_NORMAL || currentTrend == ApexPullback::TREND_DOWN_STRONG || 
        currentTrend == ApexPullback::TREND_DOWN_PULLBACK)
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
    
    double adxValue = m_CurrentProfile.adxValue;
    // 1. ADX - đóng góp 40%
    if (adxValue > 40)
        score += 0.4;
    else if (adxValue > 30)
        score += 0.3;
    else if (adxValue > 25)
        score += 0.25;
    else if (adxValue > 20)
        score += 0.2;
    // Truy cập MinAdxValue qua con trỏ m_Context
    else if (adxValue > m_Context->MinAdxValue) 
        score += 0.1;
    
    // 2. EMA Alignment - đóng góp 30%
    double emaSpread = CalculateEmaSpread(false);  // H1 // Gọi hàm thành viên trực tiếp
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
        ApexPullback::ENUM_MTF_ALIGNMENT mtfAlignment = m_CurrentProfile.mtfAlignment;
        if (mtfAlignment != ApexPullback::MTF_ALIGNMENT_CONFLICTING)
        {
            double emaSpreadH4 = CalculateEmaSpread(true);  // H4 // Gọi hàm thành viên trực tiếp
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
        atr = (ArraySize(m_AtrBufferH4) > 0) ? m_AtrBufferH4[0] : 0.0; // Kiểm tra kích thước mảng trước khi truy cập
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
    
    int handleAtrDaily = iATR(m_Symbol, PERIOD_D1, 14); // Using standard ATR period
    if (handleAtrDaily == INVALID_HANDLE)
    {
        // Truy cập Logger qua con trỏ m_Context
    if (m_Context != NULL && m_Context->Logger != NULL) { 
        m_Context->Logger->LogError("MarketProfile: Failed to create daily ATR handle");
    }
        
        return;
    }
    
    if (CopyBuffer(handleAtrDaily, 0, 0, 20, atrDailyBuffer) <= 0)
    {
        // Truy cập Logger qua con trỏ m_Context
    if (m_Context != NULL && m_Context->Logger != NULL) { 
        m_Context->Logger->LogError("MarketProfile: Failed to copy daily ATR data");
    }
        
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
    
    // Truy cập Logger qua con trỏ m_Context
    if (m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled()) 
    {
        m_Context->Logger->LogDebug("MarketProfile: Updated ATR history - Average Daily ATR: " + 
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
// [IsSidewayMarket đã được định nghĩa ở dòng 250]

// [IsSidewayMarket đã được di chuyển vào trong lớp CMarketProfile]

//+------------------------------------------------------------------+
//| Hàm kiểm tra thị trường choppy                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::IsChoppyMarket() const
{
    double adxValue = m_CurrentProfile.adxValue;
    double atrRatio = m_CurrentProfile.atrRatio;
    // Kiểm tra ADX thấp
    // Truy cập MinAdxValue qua con trỏ m_Context
    if (adxValue < m_Context->MinAdxValue) 
    {
        // Kiểm tra thêm độ biến động
        if (atrRatio < 0.8 || atrRatio > 1.5)
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
    double atrRatio = m_CurrentProfile.atrRatio;
    // Kiểm tra tỷ lệ ATR
    // Truy cập VolatilityThreshold qua con trỏ m_Context
    if (atrRatio > m_Context->VolatilityThreshold) 
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

    // Lấy giá trị EMA từ m_CurrentProfile
    double ema34 = m_CurrentProfile.ema34;
    double ema89 = m_CurrentProfile.ema89;
    double ema200 = m_CurrentProfile.ema200;
    double atrCurrent = m_CurrentProfile.atrCurrent;
    double recentSwingHigh = m_CurrentProfile.recentSwingHigh;
    // Giả sử recentSwingLow cũng cần thiết cho trường hợp short, nếu không có thì cần thêm vào MarketProfileData
    // double recentSwingLow = m_CurrentProfile.recentSwingLow; 
    
    // Các hằng số quan trọng
    double MAX_PULLBACK_DEPTH = 1.5; // Khoảng cách tối đa tính theo ATR
    
    if (isLong)
    {
        // Vùng pullback trong xu hướng tăng:
        // 1. Giá đã pullback xuống gần/chạm EMA34
        // 2. Không vượt quá EMA89 quá nhiều
        // 3. KHÔNG BAO GIỜ phá EMA200
        
        isPullbackZone = (currentPrice <= ema34 * 1.001) && // Gần hoặc dưới EMA34 một chút
                        (currentPrice >= ema89 * 0.995) &&  // Không quá sâu dưới EMA89
                        (currentPrice > ema200);            // Luôn trên EMA200
        
        // Kiểm tra thêm khoảng cách hợp lý (không pullback quá sâu)
        if (atrCurrent > 0) { // Tránh chia cho 0
            double pullbackDepth = (recentSwingHigh - currentPrice) / atrCurrent;
            if (pullbackDepth > MAX_PULLBACK_DEPTH) {
                isPullbackZone = false; // Pullback quá sâu -> không vào lệnh
            }
        } else {
            isPullbackZone = false; // Nếu ATR không hợp lệ, không coi là pullback zone
        }
    }
    else // Short
    {
        // Vùng pullback trong xu hướng giảm - logic tương tự nhưng ngược lại
        isPullbackZone = (currentPrice >= ema34 * 0.999) && // Gần hoặc trên EMA34 một chút
                        (currentPrice <= ema89 * 1.005) &&  // Không quá cao trên EMA89
                        (currentPrice < ema200);            // Luôn dưới EMA200
        
        // Kiểm tra thêm khoảng cách hợp lý (không pullback quá sâu)
        // Cần m_CurrentProfile.recentSwingLow cho trường hợp này
        // Ví dụ: double pullbackDepth = (currentPrice - recentSwingLow) / atrCurrent;
        // if (pullbackDepth > MAX_PULLBACK_DEPTH) {
        //     isPullbackZone = false; 
        // }
    }
    
    // Kiểm tra thêm nếu price action đang dao động trong khoảng hẹp
    double range = (m_HighBuffer[0] - m_LowBuffer[0]) / m_AtrBuffer[0];
    if (range < 0.5) { // Biên độ thấp hơn 50% ATR
        double rangeAvg = 0;
        for (int i = 0; i < 5; i++) {
            rangeAvg += (m_HighBuffer[i] - m_LowBuffer[i]);
        }
        rangeAvg /= (5 * m_AtrBuffer[0]);
        
        if (rangeAvg < 0.7) { // Biên độ trung bình thấp
            // Truy cập Logger qua con trỏ m_Context
        if (m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled()) { 
            m_Context->Logger->LogDebug("Thị trường đang sideway dựa trên price action. Range/ATR: " + 
                     DoubleToString(range, 2));
        }
            // Không nên return true ở đây nếu chỉ vì price action hẹp, 
            // isPullbackZone nên tập trung vào việc giá có nằm trong vùng pullback hợp lệ hay không.
            // Việc xác định sideway nên để cho IsSidewayMarket() hoặc các logic khác.
            // return true; 
        }
    }
    
    return isPullbackZone; // Trả về trạng thái pullback đã xác định ở trên
}

//+------------------------------------------------------------------+
//| Tính toán điểm số Sideways                                       |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateSidewaysScore()
{
    // Đảm bảo dữ liệu đã được cập nhật và đủ nến
    if (ArraySize(m_AtrBuffer) < 1 || ArraySize(m_AdxBuffer) < 1 || 
        ArraySize(m_EmaFastBuffer) < 1 || ArraySize(m_EmaMediumBuffer) < 1 ||
        ArraySize(m_BBWBuffer) < 20) // Chỉ cần kiểm tra 20 nến thay vì 100 để tránh lỗi
    {
        if(m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled())
        m_Context->Logger->LogDebug("CalculateSidewaysScore: Not enough data in buffers for calculation.");
    return -1.0; // Return -1.0 to indicate insufficient data
    }

    double adx_score = 0.0;
    double ema_score = 0.0;
    double bbw_score = 0.0;

    // 1. ADX Score
    // ADX(14) < 22 -> adx_score = 40
    if (m_AdxBuffer[0] < 22.0)
    {
        adx_score = 40.0;
    }

    // 2. EMA Score
    // EMA(34), EMA(89). ema_distance_atr = MathAbs(ema34 - ema89) / ATR(14).
    // ema_distance_atr < 0.5 -> ema_score = 30
    double ema34 = m_EmaFastBuffer[0]; // Assuming m_EmaFast is 34
    double ema89 = m_EmaMediumBuffer[0]; // Assuming m_EmaMedium is 89
    double atr_current = m_AtrBuffer[0]; // ATR(14)
    if (atr_current > Point() * 10) // Avoid division by zero or very small ATR (e.g. 1 pip for 5-digit broker)
    {
        double ema_distance_atr = MathAbs(ema34 - ema89) / atr_current;
        if (ema_distance_atr < 0.5)
        {
            ema_score = 30.0;
        }
    }

    // 3. BBW Score
    // BBW(20). If current BBW is in the lowest 20% of the last 100 candles -> bbw_score = 30
    // m_BBWBuffer contains (Upper - Lower) / Middle
    double current_bbw = GetBBW(0);
    
    // Đánh giá BBW
    if (MathIsValidNumber(current_bbw) && current_bbw > 0.0001)
    {
        // Tạo biến để lưu BBW thấp nhất trong 100 thanh gần đây
        double lowest_bbw_100_bars = 999999;
        double lowestBBW = 999999;  // Khai báo biến lowestBBW ở đây
        int valid_bbw_values_count = 0;
        
        // Tìm BBW thấp nhất
        for (int i = 0; i < MathMin(ArraySize(m_BBWBuffer), 20); i++)
        {
            if (m_BBWBuffer[i] > Point() * 0.1) // Consider only valid, positive BBW values
            {
                lowest_bbw_100_bars = MathMin(lowest_bbw_100_bars, m_BBWBuffer[i]);
                lowestBBW = lowest_bbw_100_bars; // Cập nhật biến lowestBBW cùng lúc
                valid_bbw_values_count++;
            }
        }
        
        // Only proceed if we have a reasonable number of valid BBW values to compare against
        if (valid_bbw_values_count >= 20) // Heuristic: need at least 20 valid past BBW values for a stable low
        {
            // Check if current BBW is in the lowest 20% range relative to its recent low.
            // This means current_bbw <= lowest_bbw_100_bars * 1.20 (20% above the absolute minimum of recent 100 bars)
            if (current_bbw <= lowest_bbw_100_bars * 1.20) 
            {
                bbw_score = 30.0;
            }
        }
    }

    double final_score = adx_score + ema_score + bbw_score;
    double calculated_lowest_bbw = (ArraySize(m_BBWBuffer) > 0 && valid_bbw_values_count >=20 && lowest_bbw_100_bars != 999999) ? lowest_bbw_100_bars : 0.0;
    if(m_Context != NULL && m_Context->Logger != NULL && m_Context->Logger->IsDebugEnabled()) 
        m_Context->Logger->LogDebug(StringFormat("Sideways Score: %.0f (ADX:%.0f, EMA:%.0f, BBW:%.0f). ADX:%.2f, EMA_Dist/ATR:%.2f, Curr BBW:%.5f, Low BBW_Recent:%.5f", 
                                                    final_score, adx_score, ema_score, bbw_score, 
                                                    m_AdxBuffer[0], 
                                                    (atr_current > Point()*10 ? MathAbs(ema34 - ema89) / atr_current : 0.0),
                                                    current_bbw,
                                                    calculated_lowest_bbw ));
    
    return final_score;
}

//+------------------------------------------------------------------+
//| Kiểm tra thị trường có đang Sideways không                       |
//+------------------------------------------------------------------+
bool CMarketProfile::IsSidewaysMarket()
{
    double score = CalculateSidewaysScore();
    // If score is -1 (not enough data), conservatively assume not sideways.
    if (score < 0.0) return false; 
    return score >= 70.0;
}

//+------------------------------------------------------------------+
//| Lấy giá trị ATR trên khung H4                                |
//+------------------------------------------------------------------+
double CMarketProfile::GetATRH4() const {
    // Đảm bảo đã cập nhật dữ liệu mới nhất
    if (ArraySize(m_AtrBufferH4) > 0) {
        return m_AtrBufferH4[0];
    }
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy tỷ lệ biến động hiện tại so với trung bình          |
//+------------------------------------------------------------------+
double CMarketProfile::GetVolatilityRatio() const {
    return m_CurrentProfile.atrRatio;
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng đủ mạnh                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::IsTrendStrongEnough() const {
    double adxValue = m_CurrentProfile.adxValue;
    // Kiểm tra ADX đủ mạnh
    // Truy cập MinAdxValue qua con trỏ m_Context
    if (adxValue < m_Context->MinAdxValue) { 
        return false;
    }
    
    // Kiểm tra trend score
    if (m_CurrentProfile.trendScore < 0.6) {
        return false;
    }
    
    // Kiểm tra EMA alignment
    bool emaAligned = false;
    ApexPullback::ENUM_MARKET_TREND currentTrend = m_CurrentProfile.trend;
    double ema34 = m_CurrentProfile.ema34;
    double ema89 = m_CurrentProfile.ema89;
    double ema200 = m_CurrentProfile.ema200;

    switch(currentTrend) {
        case ApexPullback::TREND_UP_NORMAL:
        case ApexPullback::TREND_UP_STRONG:
        case ApexPullback::TREND_UP_PULLBACK:
            emaAligned = (ema34 > ema89) && 
                        (ema89 > ema200);
            break;
            
        case ApexPullback::TREND_DOWN_NORMAL:
        case ApexPullback::TREND_DOWN_STRONG:
        case ApexPullback::TREND_DOWN_PULLBACK:
            emaAligned = (ema34 < ema89) && 
                        (ema89 < ema200);
            break;
            
        default:
            return false; // Sideway
    }
    
    return emaAligned;
}

// [CheckLowMomentum đã được định nghĩa ở dòng 1312]

// [IsChoppyMarket đã được định nghĩa ở dòng 1274]

//+------------------------------------------------------------------+
//| Khởi tạo các chỉ báo                                      |
//+------------------------------------------------------------------+
bool CMarketProfile::InitializeAllIndicators(bool isHigherTimeframe)
{
    // Xác định khung thời gian cần khởi tạo
    ENUM_TIMEFRAMES timeframe = isHigherTimeframe ? m_HigherTimeframe : m_MainTimeframe;
    
    if (m_Context != NULL && m_Context->Logger != NULL) {
        string logMessage = StringFormat("MarketProfile: Initializing indicators for %s timeframe %s", 
                               m_Symbol, 
                               EnumToString(timeframe));
        m_Context->Logger->LogInfo(logMessage);
    }
    
    // Khởi tạo các handle chỉ báo khác nhau dựa vào isHigherTimeframe
    if (isHigherTimeframe) {
        // Khởi tạo các chỉ báo cho khung thời gian cao hơn (H4)
        m_HandleEmaFastH4 = iMA(m_Symbol, timeframe, m_Context->EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaMediumH4 = iMA(m_Symbol, timeframe, m_Context->EMA_Medium, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaSlowH4 = iMA(m_Symbol, timeframe, m_Context->EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleAtrH4 = iATR(m_Symbol, timeframe, 14); // Using standard ATR period
        m_HandleAdxH4 = iADX(m_Symbol, timeframe, 14); // Using standard ADX period
        
        // Kiểm tra nếu có lỗi khởi tạo
        if (m_HandleEmaFastH4 == INVALID_HANDLE ||
            m_HandleEmaMediumH4 == INVALID_HANDLE ||
            m_HandleEmaSlowH4 == INVALID_HANDLE ||
            m_HandleAtrH4 == INVALID_HANDLE ||
            m_HandleAdxH4 == INVALID_HANDLE) {
                
            if (m_Context != NULL && m_Context->Logger != NULL) {
                m_Context->Logger->LogError("MarketProfile: Failed to initialize higher timeframe indicators");
            }
            
            return false;
        }
    } else {
        // Khởi tạo các chỉ báo cho khung thời gian chính (H1)
        m_HandleEmaFast = iMA(m_Symbol, timeframe, m_Context->EMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaMedium = iMA(m_Symbol, timeframe, m_Context->EMA_Medium, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleEmaSlow = iMA(m_Symbol, timeframe, m_Context->EMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
        m_HandleAtr = iATR(m_Symbol, timeframe, 14); // Using standard ATR period
        m_HandleAdx = iADX(m_Symbol, timeframe, 14); // Using standard ADX period
        m_HandleRsi = iRSI(m_Symbol, timeframe, 14, PRICE_CLOSE); // Using standard RSI period
        m_HandleMacd = iMACD(m_Symbol, timeframe, 12, 26, 9, PRICE_CLOSE); // Using standard MACD settings
        m_HandleBBW = iBands(m_Symbol, timeframe, 20, 0, 2, PRICE_CLOSE); // Using standard Bollinger Bands settings
        
        // Kiểm tra nếu có lỗi khởi tạo
        if (m_HandleEmaFast == INVALID_HANDLE ||
            m_HandleEmaMedium == INVALID_HANDLE ||
            m_HandleEmaSlow == INVALID_HANDLE ||
            m_HandleAtr == INVALID_HANDLE ||
            m_HandleAdx == INVALID_HANDLE ||
            m_HandleRsi == INVALID_HANDLE ||
            m_HandleMacd == INVALID_HANDLE ||
            m_HandleBBW == INVALID_HANDLE) {
                
            if (m_Context != NULL && m_Context->Logger != NULL) {
                m_Context->Logger->LogError("MarketProfile: Failed to initialize indicators");
            }
            
            return false;
        }
    }
    
    if (m_Context != NULL && m_Context->Logger != NULL) {
        m_Context->Logger->LogInfo(StringFormat("MarketProfile: Successfully initialized %s timeframe indicators", 
                                EnumToString(timeframe)));
    }
    
    return true;
}

} // end of namespace ApexPullback

#endif // MARKETPROFILE_MQH_