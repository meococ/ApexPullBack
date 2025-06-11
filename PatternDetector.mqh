//+------------------------------------------------------------------+
//| PatternDetector.mqh                                             |
//| Phát hiện mẫu hình giá thông minh cho EA                        |
//+------------------------------------------------------------------+

#ifndef PATTERN_DETECTOR_MQH_
#define PATTERN_DETECTOR_MQH_

#include "CommonStructs.mqh"
#include "Enums.mqh"
#include "Logger.mqh"         // Thêm include Logger.mqh để tránh lỗi forward declaration
#include "SwingPointDetector.mqh" // Thêm include SwingPointDetector

namespace ApexPullback {

// Định nghĩa các tỷ lệ Fibonacci phổ biến
#define FIB_0_236 0.236
#define FIB_0_382 0.382
#define FIB_0_5   0.500
#define FIB_0_618 0.618
#define FIB_0_786 0.786
#define FIB_0_886 0.886

// Định nghĩa các tỷ lệ Harmonic
#define GARTLEY_B  0.618    // Điểm B của mẫu Gartley
#define GARTLEY_C  0.382    // Điểm C của mẫu Gartley
#define GARTLEY_D  0.786    // Điểm D của mẫu Gartley

#define BUTTERFLY_B 0.786   // Điểm B của mẫu Butterfly
#define BUTTERFLY_C 0.382   // Điểm C của mẫu Butterfly
#define BUTTERFLY_D 1.618   // Điểm D của mẫu Butterfly

#define BAT_B 0.382        // Điểm B của mẫu Bat
#define BAT_C 0.382        // Điểm C của mẫu Bat
#define BAT_D 0.886        // Điểm D của mẫu Bat

#define CRAB_B 0.382       // Điểm B của mẫu Crab
#define CRAB_C 0.618       // Điểm C của mẫu Crab
#define CRAB_D 1.618       // Điểm D của mẫu Crab

// Khai báo struct để lưu trữ mẫu hình đã phát hiện
struct DetectedPattern {
    ENUM_PATTERN_TYPE type;     // Loại mẫu hình
    bool isValid;                 // Mẫu hình có hợp lệ không
    bool isBullish;               // Xu hướng tăng hay giảm
    double strength;              // Độ mạnh (0.0 - 1.0)
    double entryLevel;            // Mức giá vào lệnh đề xuất
    double stopLoss;              // Mức stop loss đề xuất
    double takeProfit;            // Mức take profit đề xuất
    int startBar;                 // Nến bắt đầu mẫu hình
    int endBar;                   // Nến kết thúc mẫu hình
    string description;           // Mô tả mẫu hình
    
    // Phương thức khởi tạo giá trị mặc định
    void Initialize() {
        type = PATTERN_NONE;
        isValid = false;
        isBullish = false;
        strength = 0.0;
        entryLevel = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        startBar = 0;
        endBar = 0;
        description = "";
    }
};

//+------------------------------------------------------------------+
//| Class CPatternDetector - Phát hiện mẫu hình giá                  |
//+------------------------------------------------------------------+
class CPatternDetector {
private:
    string m_Symbol;
    ENUM_TIMEFRAMES m_Timeframe;
    CLogger* m_Logger;
    CMarketProfile* m_MarketProfile;
    CSwingPointDetector* m_SwingPointDetector; // Thêm con trỏ tới SwingPointDetector
    double m_slBufferMultiplier; // Hệ số nhân ATR cho vùng đệm SL
    double m_minRR; // Tỷ lệ R:R tối thiểu
    double m_defaultRR; // Tỷ lệ R:R mặc định khi không có mục tiêu cấu trúc rõ ràng
    
    // Cấu hình
    double m_MinPullbackPercent;      // % pullback tối thiểu
    double m_MaxPullbackPercent;      // % pullback tối đa
    double m_PriceActionQualityThreshold; // Ngưỡng chất lượng price action
    double m_MomentumThreshold;       // Ngưỡng momentum
    double m_VolumeThreshold;         // Ngưỡng volume
    
    // Bộ lọc nâng cao 
    double m_AdxThreshold;            // Ngưỡng ADX
    double m_VolatilityThreshold;     // Ngưỡng biến động
    bool m_RequirePriceActionConfirmation; // Yêu cầu xác nhận price action
    bool m_RequireMomentumConfirmation;    // Yêu cầu xác nhận momentum
    bool m_RequireVolumeConfirmation;      // Yêu cầu xác nhận volume
    bool m_EnableMarketRegimeFilter;       // Bật lọc market regime
    
    // Bộ lọc pullback chặt chẽ
    bool m_StrictPullbackFilter;      // Bật bộ lọc pullback chặt chẽ
    int m_MinConfirmationBars;        // Số nến xác nhận tối thiểu
    int m_MaxRejectionCount;          // Số lần từ chối tối đa
    
    // Biến hỗ trợ phân tích
    double m_LastPatternQuality;      // Chất lượng mẫu hình cuối cùng
    ENUM_PATTERN_TYPE m_LastPatternType; // Loại mẫu hình cuối cùng
    datetime m_LastDetectionTime;     // Thời gian phát hiện cuối cùng
    
    // Thành viên dữ liệu cơ bản
    bool m_isInitialized;             // Trạng thái khởi tạo
    
    // Tham số cấu hình
    int m_minBarsForPattern;          // Số nến tối thiểu cho mẫu hình
    int m_maxBarsForPattern;          // Số nến tối đa cho mẫu hình
    double m_fibTolerance;            // Dung sai cho tỷ lệ Fibonacci (±%)
    double m_atr;                     // Giá trị ATR hiện tại
    bool m_useVolume;                 // Có xét đến volume hay không
    
    // Buffer lưu trữ
    double m_high[];                  // Buffer giá cao
    double m_low[];                   // Buffer giá thấp
    double m_close[];                 // Buffer giá đóng cửa
    double m_open[];                  // Buffer giá mở cửa
    long m_volume[];                  // Buffer khối lượng
    double m_atrBuffer[];             // Buffer ATR
    datetime m_time[];                // Buffer thời gian
    
    // Bộ nhớ đệm mẫu hình đã phát hiện
    DetectedPattern m_lastDetectedPattern;        // Mẫu hình được phát hiện gần nhất
    DetectedPattern m_detectedPullback;           // Mẫu hình pullback
    DetectedPattern m_detectedReversal;           // Mẫu hình đảo chiều
    DetectedPattern m_detectedHarmonic;           // Mẫu hình harmonic
    
    // Các tay cầm indicator
    int m_atrHandle;                  // Handle chỉ báo ATR
    
public:
    // Constructor và Destructor
    CPatternDetector();
    ~CPatternDetector();
    
    // Hàm khởi tạo và kết thúc
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe);
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, CLogger* logger);
    void SetLogger(CLogger* logger);
    void SetSwingPointDetector(CSwingPointDetector* detector) { m_SwingPointDetector = detector; }
    void SetSLBufferMultiplier(double val) { m_slBufferMultiplier = val; }
    void SetMinRR(double val) { m_minRR = val; }
    void SetDefaultRR(double val) { m_defaultRR = val; }
    void Release();
    
    // Hàm cập nhật dữ liệu và làm mới
    bool RefreshData(int bars = 100);
    void SetATR(double atr);
    
    // Hàm thiết lập tham số cấu hình
    void SetFibTolerance(double tolerance) { m_fibTolerance = tolerance; }
    void SetMinPullbackPct(double minPct) { m_minPullbackPct = minPct; }
    void SetMaxPullbackPct(double maxPct) { m_maxPullbackPct = maxPct; }
    void SetBarsRange(int minBars, int maxBars) {
        m_minBarsForPattern = minBars;
        m_maxBarsForPattern = maxBars;
    }
    
    // Hàm chính để phát hiện mẫu hình
    bool DetectPattern(ENUM_PATTERN_TYPE& scenario, double& strength);
    
    // Hàm phát hiện các loại mẫu hình cụ thể
    bool IsPullback(bool isBullish, double& strength);
    bool IsReversal(bool isBullish, double& strength);
    bool IsHarmonic(bool isBullish, double& strength);
    
    // Hàm lấy thông tin chi tiết về mẫu hình đã phát hiện
    bool GetPatternDetails(DetectedPattern& pattern);
    
    // Hàm kiểm tra các mẫu hình cụ thể
    bool CheckFibonacciPullback(bool isBullish, DetectedPattern& pattern);
    bool CheckBullishPullback(DetectedPattern& pattern);
    bool CheckBearishPullback(DetectedPattern& pattern);
    bool CheckStrongPullback(bool isBullish, DetectedPattern& pattern);
    bool CheckEngulfingPattern(bool isBullish, DetectedPattern& pattern);
    bool CheckGartleyPattern(bool isBullish, DetectedPattern& pattern);
    bool CheckButterflyPattern(bool isBullish, DetectedPattern& pattern);
    bool CheckBatPattern(bool isBullish, DetectedPattern& pattern);
    bool CheckCrabPattern(bool isBullish, DetectedPattern& pattern);

    // Cài đặt bộ lọc pullback chặt chẽ
    void SetStrictPullbackFilter(bool enable, int minConfirmationBars = 2, int maxRejectionCount = 1);

private:
    // Hàm phụ trợ nội bộ
    bool DetectPullbackPatterns();
    bool DetectReversalPatterns();
    bool DetectHarmonicPatterns();
    
    bool IsValidPullbackDepth(double highPrice, double lowPrice, double& ratio);
    bool IsValidFibonacciRatio(double ratio, double targetRatio);
    bool IsUptrend(int startBar, int endBar);
    bool IsDowntrend(int startBar, int endBar);
    
    void LogPattern(string patternName, bool isValid, string description = "");
    double CalculatePatternStrength(DetectedPattern& pattern);
    
    // Hàm xử lý các điểm swing
    int FindLastSwingHigh(int startBar, int lookback);
    int FindLastSwingLow(int startBar, int lookback);
    int FindSwingPoint(bool findHigh, int startBar, int lookback, double& price);
    double CalculateFibonacciRetracementLevel(double startPrice, double endPrice, double retracementRatio, bool isBullish);

    bool DetectPullbackPattern(bool isBullish, DetectedPattern& pattern);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector() {
    m_isInitialized = false;
    m_Logger = NULL;
    m_SwingPointDetector = NULL; // Khởi tạo SwingPointDetector là NULL
    m_atrHandle = INVALID_HANDLE;
    m_slBufferMultiplier = 0.2; // Giá trị mặc định, có thể cấu hình
    m_minRR = 1.0; // Giá trị mặc định
    m_defaultRR = 2.0; // Giá trị mặc định
    
    // Thiết lập các giá trị mặc định
    m_minBarsForPattern = 5;
    m_maxBarsForPattern = 20;
    m_fibTolerance = 0.03;  // Dung sai 3%
    m_minPullbackPct = 20.0;
    m_maxPullbackPct = 70.0;
    m_atr = 0.0;
    m_useVolume = true;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPatternDetector::~CPatternDetector() {
    Release();
}

//+------------------------------------------------------------------+
//| Khởi tạo với symbol và timeframe                                 |
//+------------------------------------------------------------------+
bool CPatternDetector::Initialize(string symbol, ENUM_TIMEFRAMES timeframe) {
    return Initialize(symbol, timeframe, NULL);
}

//+------------------------------------------------------------------+
//| Khởi tạo với symbol, timeframe và logger                         |
//+------------------------------------------------------------------+
bool CPatternDetector::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, CLogger* logger) {
    // Giải phóng tài nguyên nếu đã khởi tạo trước đó
    if (m_isInitialized) {
        Release();
    }
    
    m_Symbol = symbol;
    m_Timeframe = timeframe;
    m_Logger = logger;
    
    // Tạo handle cho indicator ATR
    m_atrHandle = iATR(m_Symbol, m_Timeframe, 14);
    if (m_atrHandle == INVALID_HANDLE) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể tạo handle ATR trong PatternDetector");
        return false;
    }
    
    // Cấp phát bộ nhớ cho các buffer
    ArrayResize(m_high, m_maxBarsForPattern * 2);
    ArrayResize(m_low, m_maxBarsForPattern * 2);
    ArrayResize(m_close, m_maxBarsForPattern * 2);
    ArrayResize(m_open, m_maxBarsForPattern * 2);
    ArrayResize(m_volume, m_maxBarsForPattern * 2);
    ArrayResize(m_atrBuffer, m_maxBarsForPattern * 2);
    ArrayResize(m_time, m_maxBarsForPattern * 2);
    
    // Thiết lập các mảng là mảng series (index 0 là nến mới nhất)
    ArraySetAsSeries(m_high, true);
    ArraySetAsSeries(m_low, true);
    ArraySetAsSeries(m_close, true);
    ArraySetAsSeries(m_open, true);
    ArraySetAsSeries(m_volume, true);
    ArraySetAsSeries(m_atrBuffer, true);
    ArraySetAsSeries(m_time, true);
    
    // Làm mới dữ liệu
    bool refreshOk = RefreshData();
    
    m_isInitialized = refreshOk;
    return refreshOk;
}

//+------------------------------------------------------------------+
//| Thiết lập logger                                                 |
//+------------------------------------------------------------------+
void CPatternDetector::SetLogger(CLogger* logger) {
    m_Logger = logger;
}

//+------------------------------------------------------------------+
//| Giải phóng tài nguyên                                            |
//+------------------------------------------------------------------+
void CPatternDetector::Release() {
    if (m_atrHandle != INVALID_HANDLE) {
        IndicatorRelease(m_atrHandle);
        m_atrHandle = INVALID_HANDLE;
    }
    
    m_isInitialized = false;
}

//+------------------------------------------------------------------+
//| Làm mới dữ liệu từ thị trường                                    |
//+------------------------------------------------------------------+
bool CPatternDetector::RefreshData(int bars = 100) {
    if (bars < m_maxBarsForPattern) {
        bars = m_maxBarsForPattern * 2;  // Đảm bảo lấy đủ dữ liệu
    }
    
    // Đảm bảo kích thước mảng phù hợp
    ArrayResize(m_high, bars);
    ArrayResize(m_low, bars);
    ArrayResize(m_close, bars);
    ArrayResize(m_open, bars);
    ArrayResize(m_volume, bars);
    ArrayResize(m_atrBuffer, bars);
    ArrayResize(m_time, bars);
    
    // Copy dữ liệu giá
    if (CopyHigh(m_Symbol, m_Timeframe, 0, bars, m_high) != bars) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể copy dữ liệu giá high");
        return false;
    }
    
    if (CopyLow(m_Symbol, m_Timeframe, 0, bars, m_low) != bars) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể copy dữ liệu giá low");
        return false;
    }
    
    if (CopyClose(m_Symbol, m_Timeframe, 0, bars, m_close) != bars) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể copy dữ liệu giá close");
        return false;
    }
    
    if (CopyOpen(m_Symbol, m_Timeframe, 0, bars, m_open) != bars) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể copy dữ liệu giá open");
        return false;
    }
    
    // Copy dữ liệu khối lượng nếu cần
    if (m_useVolume) {
        if (CopyTickVolume(m_Symbol, m_Timeframe, 0, bars, m_volume) != bars) {
            if (m_Logger != NULL) {
                m_Logger.LogDebug("Volume không khả dụng cho " + m_Symbol);
                m_useVolume = false;  // Tắt sử dụng volume nếu không có dữ liệu
            }
        }
    }
    
    // Copy dữ liệu ATR
    if (m_atrHandle != INVALID_HANDLE) {
        if (CopyBuffer(m_atrHandle, 0, 0, bars, m_atrBuffer) != bars) {
            if (m_Logger != NULL) m_Logger.LogWarning("Không thể copy dữ liệu ATR");
        }
        else {
            // Cập nhật ATR hiện tại
            m_atr = m_atrBuffer[0];
        }
    }
    
    // Copy dữ liệu thởi gian
    if (CopyTime(m_Symbol, m_Timeframe, 0, bars, m_time) != bars) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể copy dữ liệu thời gian");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập giá trị ATR từ bên ngoài                               |
//+------------------------------------------------------------------+
void CPatternDetector::SetATR(double atr) {
    m_atr = atr;
}

//| Phát hiện mẫu hình và trả về thông tin                           |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectPattern(ENUM_PATTERN_TYPE& scenario, double& strength) {
    if (!m_isInitialized || m_atr <= 0) {
        if (m_Logger != NULL) m_Logger.LogError("PatternDetector chưa được khởi tạo đúng cách hoặc ATR không hợp lệ");
        scenario = PATTERN_NONE;
        strength = 0.0;
        return false;
    }
    
    // Phát hiện các loại mẫu hình
    bool foundPattern = false;
    
    // Khởi tạo các giá trị mặc định
    scenario = PATTERN_NONE;
    strength = 0.0;
    
    // Kiểm tra mẫu hình Pullback
    if (DetectPullbackPatterns()) {
        scenario = m_detectedPullback.type;
        strength = m_detectedPullback.strength;
        m_lastDetectedPattern = m_detectedPullback;
        foundPattern = true;
    }
    // Kiểm tra mẫu hình Reversal nếu không tìm thấy Pullback
    else if (DetectReversalPatterns()) {
        scenario = m_detectedReversal.type;
        strength = m_detectedReversal.strength;
        m_lastDetectedPattern = m_detectedReversal;
        foundPattern = true;
    }
    // Kiểm tra mẫu hình Harmonic nếu không tìm thấy cả hai
    else if (DetectHarmonicPatterns()) {
        scenario = m_detectedHarmonic.type;
        strength = m_detectedHarmonic.strength;
        m_lastDetectedPattern = m_detectedHarmonic;
        foundPattern = true;
    }
    
    return foundPattern;
}

//+------------------------------------------------------------------+
//| Ghi Log thông tin mẫu hình                                       |
//+------------------------------------------------------------------+
void CPatternDetector::LogPattern(string patternName, bool isValid, string description = "") {
    if (m_Logger != NULL) {
        if (isValid) {
            m_Logger.LogDebug("Phát hiện mẫu hình: " + patternName + ", " + description);
        } else {
            m_Logger.LogDebug("Kiểm tra mẫu hình không hợp lệ: " + patternName);
        }
    }
}

//+------------------------------------------------------------------+
//| Tính toán độ mạnh của mẫu hình dựa trên nhiều yếu tố             |
//+------------------------------------------------------------------+
double CPatternDetector::CalculatePatternStrength(DetectedPattern& pattern) {
    // Giá trị cơ sở cho độ mạnh
    double strength = 0.5;
    
    // Điều chỉnh dựa trên loại mẫu hình
    switch (pattern.type) {
        case SCENARIO_STRONG_PULLBACK:
            strength = 0.8;
            break;
        case SCENARIO_FIBONACCI_PULLBACK:
            strength = 0.75;
            break;
        case SCENARIO_BULLISH_PULLBACK:
        case SCENARIO_BEARISH_PULLBACK:
            strength = 0.7;
            break;
        case SCENARIO_HARMONIC_PATTERN:
            strength = 0.75;
            break;
        case SCENARIO_MOMENTUM_SHIFT:
            strength = 0.65;
            break;
        default:
            strength = 0.5;
            break;
    }
    
    // Điều chỉnh dựa trên Risk:Reward
    double riskReward = MathAbs(pattern.takeProfit - pattern.entryLevel) / 
                      MathAbs(pattern.stopLoss - pattern.entryLevel);
    
    if (riskReward > 3.0) strength *= 1.2;
    else if (riskReward > 2.0) strength *= 1.1;
    else if (riskReward < 1.0) strength *= 0.8;
    
    // Điều chỉnh dựa trên số nến trong mẫu hình
    int patternLength = pattern.startBar - pattern.endBar;
    if (patternLength > 15) strength *= 0.9;
    else if (patternLength < 5) strength *= 0.95;
    
    // Giới hạn độ mạnh trong khoảng [0.0, 1.0]
    return MathMin(MathMax(strength, 0.0), 1.0);
}

//+------------------------------------------------------------------+
//| Tìm điểm swing high gần nhất                                     |
//+------------------------------------------------------------------+
int CPatternDetector::FindLastSwingHigh(int startBar, int lookback) {
    double highestHigh = -DBL_MAX;
    int highestBar = -1;
    
    if (startBar + lookback >= ArraySize(m_high) || startBar < 0) {
        lookback = MathMin(lookback, ArraySize(m_high) - startBar - 1);
    }
    
    // Tìm đỉnh cao nhất
    for (int i = startBar; i <= startBar + lookback; i++) {
        if (m_high[i] > highestHigh) {
            highestHigh = m_high[i];
            highestBar = i;
        }
    }
    
    return highestBar;
}

//+------------------------------------------------------------------+
//| Tìm điểm swing low gần nhất                                      |
//+------------------------------------------------------------------+
int CPatternDetector::FindLastSwingLow(int startBar, int lookback) {
    double lowestLow = DBL_MAX;
    int lowestBar = -1;
    
    if (startBar + lookback >= ArraySize(m_low) || startBar < 0) {
        lookback = MathMin(lookback, ArraySize(m_low) - startBar - 1);
    }
    
    // Tìm đáy thấp nhất
    for (int i = startBar; i <= startBar + lookback; i++) {
        if (m_low[i] < lowestLow) {
            lowestLow = m_low[i];
            lowestBar = i;
        }
    }
    
    return lowestBar;
}

//+------------------------------------------------------------------+
//| Tìm điểm swing (high hoặc low) và trả về vị trí nến              |
//+------------------------------------------------------------------+
int CPatternDetector::FindSwingPoint(bool findHigh, int startBar, int lookback, double& price) {
    if (findHigh) {
        int bar = FindLastSwingHigh(startBar, lookback);
        if (bar >= 0) {
            price = m_high[bar];
            return bar;
        }
    } else {
        int bar = FindLastSwingLow(startBar, lookback);
        if (bar >= 0) {
            price = m_low[bar];
            return bar;
        }
    }
    
    return -1;
}

//+------------------------------------------------------------------+
//| Tính toán mức Fibonacci Retracement                              |
//+------------------------------------------------------------------+
double CPatternDetector::CalculateFibonacciRetracementLevel(double startPrice, double endPrice, double retracementRatio, bool isBullish) {
    if (isBullish) {
        // Trong xu hướng tăng: Từ low đến high
        return endPrice - (endPrice - startPrice) * retracementRatio;
    } else {
        // Trong xu hướng giảm: Từ high đến low
        return startPrice - (startPrice - endPrice) * retracementRatio;
    }
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình pullback                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectPullbackPatterns() {
    // Khởi tạo mẫu hình với các giá trị mặc định
    m_detectedPullback.Initialize();
    
    // Kiểm tra các loại mẫu hình pullback
    if (DetectPullbackPattern(true, m_detectedPullback)) {
        return true;
    }
    else if (DetectPullbackPattern(false, m_detectedPullback)) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình đảo chiều                                 |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectReversalPatterns() {
    // Khởi tạo mẫu hình với các giá trị mặc định
    m_detectedReversal.Initialize();
    
    // Kiểm tra các mẫu hình đảo chiều
    if (CheckEngulfingPattern(true, m_detectedReversal)) {
        return true;
    }
    else if (CheckEngulfingPattern(false, m_detectedReversal)) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình harmonic                                   |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectHarmonicPatterns() {
    // Khởi tạo mẫu hình với các giá trị mặc định
    m_detectedHarmonic.Initialize();
    
    // Kiểm tra các loại mẫu hình harmonic
    if (CheckGartleyPattern(true, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckGartleyPattern(false, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckButterflyPattern(true, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckButterflyPattern(false, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckBatPattern(true, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckBatPattern(false, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckCrabPattern(true, m_detectedHarmonic)) {
        return true;
    }
    else if (CheckCrabPattern(false, m_detectedHarmonic)) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem tỷ lệ pullback có hợp lệ không                        |
//+------------------------------------------------------------------+
bool CPatternDetector::IsValidPullbackDepth(double highPrice, double lowPrice, double& ratio) {
    double range = MathAbs(highPrice - lowPrice);
    if (range <= 0) {
        return false;
    }
    
    ratio = 100.0 * range / ((highPrice + lowPrice) / 2.0);
    
    return (ratio >= m_minPullbackPct && ratio <= m_maxPullbackPct);
}

//+------------------------------------------------------------------+
//| Kiểm tra tỷ lệ Fibonacci có nằm trong khoảng dung sai              |
//+------------------------------------------------------------------+
bool CPatternDetector::IsValidFibonacciRatio(double ratio, double targetRatio) {
    return (MathAbs(ratio - targetRatio) <= m_fibTolerance);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng tăng                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::IsUptrend(int startBar, int endBar) {
    if (startBar < 0 || endBar < 0 || startBar >= ArraySize(m_close) || endBar >= ArraySize(m_close)) {
        return false;
    }
    
    // Xu hướng tăng đơn giản là giá đóng cửa cuối kỳ > giá đóng cửa đầu kỳ
    // Có thể thêm nhiều điều kiện phức tạp hơn ở đây
    return (m_close[endBar] > m_close[startBar]);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng giảm                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::IsDowntrend(int startBar, int endBar) {
    if (startBar < 0 || endBar < 0 || startBar >= ArraySize(m_close) || endBar >= ArraySize(m_close)) {
        return false;
    }
    
    // Xu hướng giảm đơn giản là giá đóng cửa cuối kỳ < giá đóng cửa đầu kỳ
    // Có thể thêm nhiều điều kiện phức tạp hơn ở đây
    return (m_close[endBar] < m_close[startBar]);
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình pullback mạnh (Strong Pullback)                 |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckStrongPullback(bool isBullish, DetectedPattern& pattern) {
    // Khởi tạo mẫu hình
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_STRONG_PULLBACK;
    pattern.description = isBullish ? "Strong Bullish Pullback" : "Strong Bearish Pullback";
    
    // Khởi tạo các biến
    int lookbackBars = 20;
    
    // Kích thước tối thiểu phù hợp với tầm nhìn giao dịch
    if (ArraySize(m_high) < lookbackBars + 5) {
        LogPattern(pattern.description, false, "Không đủ dữ liệu");
        return false;
    }
    
    // Định vị swing points
    double swingPrice = 0.0;
    int swingBar = -1;
    
    // Tìm swing high/low quan trọng
    if (isBullish) {
        // Tìm swing low trước khi tăng
        swingBar = FindLastSwingLow(0, lookbackBars);
        if (swingBar < 0) {
            LogPattern(pattern.description, false, "Không tìm thấy swing low phù hợp");
            return false;
        }
        swingPrice = m_low[swingBar];
    } else {
        // Tìm swing high trước khi giảm
        swingBar = FindLastSwingHigh(0, lookbackBars);
        if (swingBar < 0) {
            LogPattern(pattern.description, false, "Không tìm thấy swing high phù hợp");
            return false;
        }
        swingPrice = m_high[swingBar];
    }
    
    // Kiểm tra xu hướng chính
    bool isMainTrend = isBullish ? IsUptrend(swingBar, 0) : IsDowntrend(swingBar, 0);
    if (!isMainTrend) {
        LogPattern(pattern.description, false, "Không có xu hướng chính rõ ràng");
        return false;
    }
    
    // Tìm điểm bắt đầu và kết thúc pullback
    int pullbackStartBar = -1;
    int pullbackEndBar = -1;
    double pullbackStartPrice = 0.0;
    double pullbackEndPrice = 0.0;
    
    if (isBullish) {
        // Sau swing low, tìm mức cao gần đây (điểm bắt đầu pullback)
        pullbackStartBar = FindLastSwingHigh(0, swingBar);
        if (pullbackStartBar < 0 || pullbackStartBar >= swingBar) {
            LogPattern(pattern.description, false, "Không tìm thấy điểm bắt đầu pullback");
            return false;
        }
        pullbackStartPrice = m_high[pullbackStartBar];
        
        // Tìm mức thấp kể từ điểm bắt đầu pullback (điểm kết thúc pullback)
        pullbackEndBar = FindLastSwingLow(0, pullbackStartBar);
        if (pullbackEndBar < 0 || pullbackEndBar >= pullbackStartBar) {
            LogPattern(pattern.description, false, "Không tìm thấy điểm kết thúc pullback");
            return false;
        }
        pullbackEndPrice = m_low[pullbackEndBar];
        
        // Kiểm tra mức pullback hợp lệ (không quá sâu, không quá nông)
        double retracementRatio = (pullbackStartPrice - pullbackEndPrice) / (pullbackStartPrice - swingPrice);
        if (retracementRatio < 0.3 || retracementRatio > 0.7) {
            LogPattern(pattern.description, false, "Mức pullback không hợp lệ: " + DoubleToString(retracementRatio, 2));
            return false;
        }
        
        // Kiểm tra momentum
        bool hasMomentumSupport = false;
        // Lấy dữ liệu RSI để kiểm tra (giả định đã có giá trị RSI)
        double rsiValue = 50.0; // Cần lấy giá trị thực từ indicator
        
        // RSI đang tăng từ vùng oversold
        if (rsiValue > 40 && rsiValue < 60) {
            hasMomentumSupport = true;
        }
        
        if (!hasMomentumSupport) {
            LogPattern(pattern.description, false, "Không có xác nhận momentum");
            return false;
        }
        
        // Kiểm tra khối lượng (nếu có dữ liệu)
        bool hasVolumeConfirmation = true;
        if (m_useVolume) {
            // Khối lượng giảm trong pullback, tăng khi xác nhận xu hướng
            double avgVolume = (m_volume[1] + m_volume[2] + m_volume[3]) / 3.0;
            double pullbackVolume = (m_volume[pullbackEndBar] + m_volume[pullbackEndBar + 1]) / 2.0;
            
            if (pullbackVolume > avgVolume) {
                hasVolumeConfirmation = false;
                LogPattern(pattern.description, false, "Volume không xác nhận (quá cao trong pullback)");
                return false;
            }
        }
        
        // Kiểm tra nến xác nhận
        bool hasConfirmationCandle = false;
        
        // Nến gần nhất phải có thân dài và đóng cửa gần mức cao
        double bodySize = MathAbs(m_close[0] - m_open[0]);
        double candleRange = m_high[0] - m_low[0];
        
        if (bodySize > 0.6 * candleRange && m_close[0] > m_open[0]) {
            hasConfirmationCandle = true;
        }
        
        if (!hasConfirmationCandle) {
            LogPattern(pattern.description, false, "Không có nến xác nhận");
            return false;
        }
        
        // Thiết lập giá trị mẫu hình
        pattern.startBar = swingBar;
        pattern.endBar = 0;
        pattern.entryLevel = m_close[0];
        pattern.stopLoss = pullbackEndPrice - m_atr * 0.5; // SL dưới mức pullback với buffer ATR
        pattern.takeProfit = pullbackStartPrice + (pullbackStartPrice - swingPrice) * 0.5; // TP tối thiểu 1.5R
        pattern.isValid = true;
        
    } else {
        // Sau swing high, tìm mức thấp gần đây (điểm bắt đầu pullback)
        pullbackStartBar = FindLastSwingLow(0, swingBar);
        if (pullbackStartBar < 0 || pullbackStartBar >= swingBar) {
            LogPattern(pattern.description, false, "Không tìm thấy điểm bắt đầu pullback");
            return false;
        }
        pullbackStartPrice = m_low[pullbackStartBar];
        
        // Tìm mức cao kể từ điểm bắt đầu pullback (điểm kết thúc pullback)
        pullbackEndBar = FindLastSwingHigh(0, pullbackStartBar);
        if (pullbackEndBar < 0 || pullbackEndBar >= pullbackStartBar) {
            LogPattern(pattern.description, false, "Không tìm thấy điểm kết thúc pullback");
            return false;
        }
        pullbackEndPrice = m_high[pullbackEndBar];
        
        // Kiểm tra mức pullback hợp lệ (không quá sâu, không quá nông)
        double retracementRatio = (pullbackEndPrice - pullbackStartPrice) / (swingPrice - pullbackStartPrice);
        if (retracementRatio < 0.3 || retracementRatio > 0.7) {
            LogPattern(pattern.description, false, "Mức pullback không hợp lệ: " + DoubleToString(retracementRatio, 2));
            return false;
        }
        
        // Kiểm tra momentum
        bool hasMomentumSupport = false;
        // Lấy dữ liệu RSI để kiểm tra (giả định đã có giá trị RSI)
        double rsiValue = 50.0; // Cần lấy giá trị thực từ indicator
        
        // RSI đang giảm từ vùng overbought
        if (rsiValue > 40 && rsiValue < 60) {
            hasMomentumSupport = true;
        }
        
        if (!hasMomentumSupport) {
            LogPattern(pattern.description, false, "Không có xác nhận momentum");
            return false;
        }
        
        // Kiểm tra khối lượng (nếu có dữ liệu)
        bool hasVolumeConfirmation = true;
        if (m_useVolume) {
            // Khối lượng giảm trong pullback, tăng khi xác nhận xu hướng
            double avgVolume = (m_volume[1] + m_volume[2] + m_volume[3]) / 3.0;
            double pullbackVolume = (m_volume[pullbackEndBar] + m_volume[pullbackEndBar + 1]) / 2.0;
            
            if (pullbackVolume > avgVolume) {
                hasVolumeConfirmation = false;
                LogPattern(pattern.description, false, "Volume không xác nhận (quá cao trong pullback)");
                return false;
            }
        }
        
        // Kiểm tra nến xác nhận
        bool hasConfirmationCandle = false;
        
        // Nến gần nhất phải có thân dài và đóng cửa gần mức thấp
        double bodySize = MathAbs(m_close[0] - m_open[0]);
        double candleRange = m_high[0] - m_low[0];
        
        if (bodySize > 0.6 * candleRange && m_close[0] < m_open[0]) {
            hasConfirmationCandle = true;
        }
        
        if (!hasConfirmationCandle) {
            LogPattern(pattern.description, false, "Không có nến xác nhận");
            return false;
        }
        
        // Thiết lập giá trị mẫu hình
        pattern.startBar = swingBar;
        pattern.endBar = 0;
        pattern.entryLevel = m_close[0];
        pattern.stopLoss = pullbackEndPrice + m_atr * 0.5; // SL trên mức pullback với buffer ATR
        pattern.takeProfit = pullbackStartPrice - (swingPrice - pullbackStartPrice) * 0.5; // TP tối thiểu 1.5R
        pattern.isValid = true;
    }
    
    // Tính độ mạnh mẫu hình
    if (pattern.isValid) {
        // Yếu tố tăng cường độ mạnh
        pattern.strength = 0.7; // Giá trị cơ sở
        
        // Tăng độ mạnh nếu khối lượng xác nhận
        if (m_useVolume) {
            double currentVolume = m_volume[0];
            double avgVolume = (m_volume[1] + m_volume[2] + m_volume[3]) / 3.0;
            
            if (currentVolume > avgVolume * 1.5) {
                pattern.strength += 0.1;
            }
        }
        
        // Tăng độ mạnh nếu ATR hợp lý (không quá biến động)
        if (m_atr > 0 && m_atr < m_atrBuffer[10] * 1.5) {
            pattern.strength += 0.1;
        }
        
        // Giới hạn độ mạnh trong khoảng [0, 1]
        pattern.strength = MathMin(1.0, pattern.strength);
        
        LogPattern(pattern.description, true, "Độ mạnh: " + DoubleToString(pattern.strength, 2));
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình Engulfing (nuốt chừng)                          |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckEngulfingPattern(bool isBullish, DetectedPattern& pattern) {
    // Triển khai mã để kiểm tra mẫu hình Engulfing
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_CUSTOM;
    pattern.description = isBullish ? "Bullish Engulfing" : "Bearish Engulfing";
    
    // Cần triển khai logic để kiểm tra mẫu hình Engulfing
    // Giả định mẫu hình này chưa được hỗ trợ đầy đủ
    pattern.isValid = false;
    
    if (pattern.isValid) {
        // Tính toán độ mạnh của mẫu hình
        pattern.strength = CalculatePatternStrength(pattern);
        
        // Ghi log
        LogPattern(pattern.description, true);
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình Gartley                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckGartleyPattern(bool isBullish, DetectedPattern& pattern) {
    // Triển khai mã để kiểm tra mẫu hình Gartley
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.description = isBullish ? "Bullish Gartley" : "Bearish Gartley";
    
    // Cần triển khai logic để kiểm tra mẫu hình Gartley
    // Giả định mẫu hình này chưa được hỗ trợ đầy đủ
    pattern.isValid = false;
    
    if (pattern.isValid) {
        // Tính toán độ mạnh của mẫu hình
        pattern.strength = CalculatePatternStrength(pattern);
        
        // Ghi log
        LogPattern(pattern.description, true);
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình Butterfly                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckButterflyPattern(bool isBullish, DetectedPattern& pattern) {
    // Triển khai mã để kiểm tra mẫu hình Butterfly
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.description = isBullish ? "Bullish Butterfly" : "Bearish Butterfly";
    
    // Cần triển khai logic để kiểm tra mẫu hình Butterfly
    // Giả định mẫu hình này chưa được hỗ trợ đầy đủ
    pattern.isValid = false;
    
    if (pattern.isValid) {
        // Tính toán độ mạnh của mẫu hình
        pattern.strength = CalculatePatternStrength(pattern);
        
        // Ghi log
        LogPattern(pattern.description, true);
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình Bat                                            |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckBatPattern(bool isBullish, DetectedPattern& pattern) {
    // Triển khai mã để kiểm tra mẫu hình Bat
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.description = isBullish ? "Bullish Bat" : "Bearish Bat";
    
    // Cần triển khai logic để kiểm tra mẫu hình Bat
    // Giả định mẫu hình này chưa được hỗ trợ đầy đủ
    pattern.isValid = false;
    
    if (pattern.isValid) {
        // Tính toán độ mạnh của mẫu hình
        pattern.strength = CalculatePatternStrength(pattern);
        
        // Ghi log
        LogPattern(pattern.description, true);
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Kiểm tra mẫu hình Crab                                           |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckCrabPattern(bool isBullish, DetectedPattern& pattern) {
    // Triển khai mã để kiểm tra mẫu hình Crab
    pattern.Initialize();
    pattern.isBullish = isBullish;
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.description = isBullish ? "Bullish Crab" : "Bearish Crab";
    
    // Cần triển khai logic để kiểm tra mẫu hình Crab
    // Giả định mẫu hình này chưa được hỗ trợ đầy đủ
    pattern.isValid = false;
    
    if (pattern.isValid) {
        // Tính toán độ mạnh của mẫu hình
        pattern.strength = CalculatePatternStrength(pattern);
        
        // Ghi log
        LogPattern(pattern.description, true);
    }
    
    return pattern.isValid;
}

//+------------------------------------------------------------------+
//| Cài đặt bộ lọc pullback chặt chẽ                                   |
//+------------------------------------------------------------------+
void CPatternDetector::SetStrictPullbackFilter(bool enable, int minConfirmationBars = 2, int maxRejectionCount = 1) {
    m_StrictPullbackFilter = enable;
    m_MinConfirmationBars = minConfirmationBars;
    m_MaxRejectionCount = maxRejectionCount;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("PatternDetector: " + (enable ? "Bật" : "Tắt") + " bộ lọc pullback chặt chẽ");
    }
}

bool CPatternDetector::DetectPullbackPattern(bool isBullish, DetectedPattern& pattern) {
    pattern.Initialize(); // Khởi tạo pattern
    pattern.isBullish = isBullish;
    pattern.type = isBullish ? SCENARIO_BULLISH_PULLBACK : SCENARIO_BEARISH_PULLBACK;

    // Kiểm tra đủ dữ liệu
    int requiredBars = m_maxBarsForPattern;
    if (m_high.Size() < requiredBars || m_low.Size() < requiredBars || m_close.Size() < requiredBars) {
        LogPattern("Pullback", false, "Không đủ dữ liệu");
        return false;
    }

    // Điều kiện 1: Kiểm tra cấu trúc thị trường từ SwingPointDetector
    if (m_SwingPointDetector == NULL) {
        LogPattern("Pullback", false, "SwingPointDetector chưa được thiết lập");
        return false;
    }

    MarketRegimeInfo regimeInfo = m_SwingPointDetector.GetMarketRegimeInfo(); // Lấy thông tin Market Regime
    int hhCount = 0;
    int hlCount = 0;
    int lhCount = 0;
    int llCount = 0;

    SwingPoint swings[10]; // Mảng để lưu trữ các swing points
    int numSwings = m_SwingPointDetector.GetSwingPoints(swings, 10); // Lấy tối đa 10 swing gần nhất

    if (numSwings < 4) { // Cần ít nhất 2 high và 2 low để xác định xu hướng (2 HH và 2 HL hoặc 2 LH và 2 LL)
        LogPattern("Pullback", false, "Không đủ swing points để xác định xu hướng (< 4)");
        return false;
    }

    // Logic đếm HH, HL, LH, LL
    // Giả định mảng swings được trả về theo thứ tự thời gian giảm dần (mới nhất ở index 0)
    double lastHighPrice = 0, prevHighPrice = 0;
    double lastLowPrice = 0, prevLowPrice = 0;
    int highSwingsFound = 0;
    int lowSwingsFound = 0;

    for (int i = 0; i < numSwings; i++) {
        if (swings[i].type == SWING_HIGH) {
            highSwingsFound++;
            if (highSwingsFound == 1) {
                lastHighPrice = swings[i].price;
            } else if (highSwingsFound == 2) {
                prevHighPrice = lastHighPrice;
                lastHighPrice = swings[i].price;
                if (lastHighPrice > prevHighPrice) hhCount++;
                else if (lastHighPrice < prevHighPrice) lhCount++;
            } else if (highSwingsFound > 2) {
                 prevHighPrice = lastHighPrice;
                 lastHighPrice = swings[i].price;
                 if (lastHighPrice > prevHighPrice) hhCount++;
                 else if (lastHighPrice < prevHighPrice) lhCount++;
            }
        }
        if (swings[i].type == SWING_LOW) {
            lowSwingsFound++;
            if (lowSwingsFound == 1) {
                lastLowPrice = swings[i].price;
            } else if (lowSwingsFound == 2) {
                prevLowPrice = lastLowPrice;
                lastLowPrice = swings[i].price;
                if (lastLowPrice > prevLowPrice) hlCount++;
                else if (lastLowPrice < prevLowPrice) llCount++;
            } else if (lowSwingsFound > 2) {
                prevLowPrice = lastLowPrice;
                lastLowPrice = swings[i].price;
                if (lastLowPrice > prevLowPrice) hlCount++;
                else if (lastLowPrice < prevLowPrice) llCount++;
            }
        }
    }

    bool isConfirmedUptrend = (isBullish && hhCount >= 2 && hlCount >= 2);
    bool isConfirmedDowntrend = (!isBullish && lhCount >= 2 && llCount >= 2);

    if (!isConfirmedUptrend && !isConfirmedDowntrend) {
        LogPattern("Pullback", false, StringFormat("Không có xu hướng được xác nhận. Bullish: %s (HH:%d, HL:%d). Bearish: %s (LH:%d, LL:%d)", 
                                                isBullish ? "true" : "false", hhCount, hlCount, 
                                                !isBullish ? "true" : "false", lhCount, llCount));
        return false;
    }

    // Lấy Swing High/Low gần nhất cho sóng đẩy
    SwingPoint impulseWaveStartSwing, impulseWaveEndSwing;
    bool foundImpulseWaveStart = false;
    bool foundImpulseWaveEnd = false;

    if (isBullish) { // Xu hướng tăng, sóng đẩy từ Swing Low -> Swing High
        // Tìm Swing Low gần nhất làm điểm bắt đầu sóng đẩy (impulseWaveStartSwing)
        for (int i = 0; i < numSwings; i++) {
            if (swings[i].type == SWING_LOW) {
                impulseWaveStartSwing = swings[i];
                foundImpulseWaveStart = true;
                break; 
            }
        }
        // Tìm Swing High gần nhất (sau impulseWaveStartSwing) làm điểm kết thúc sóng đẩy (impulseWaveEndSwing)
        // Hoặc nếu chưa có Swing High rõ ràng sau đó, có thể là giá cao nhất hiện tại
        for (int i = 0; i < numSwings; i++) {
            if (swings[i].type == SWING_HIGH && swings[i].time > impulseWaveStartSwing.time) {
                impulseWaveEndSwing = swings[i];
                foundImpulseWaveEnd = true;
                break;
            }
        }
        if (!foundImpulseWaveEnd) { // Nếu không có swing high nào sau swing low, tìm giá cao nhất kể từ sau impulseWaveStartSwing
            double tempHighestPrice = impulseWaveStartSwing.price;
            datetime tempHighestTime = impulseWaveStartSwing.time;
            int tempHighestBarIndex = impulseWaveStartSwing.barIndex;
            bool potentialEndFound = false;
            // Duyệt ngược từ nến ngay trước nến hiện tại (index 1) đến nến sau impulseWaveStartSwing
            for (int k = 1; k < Bars(m_Symbol,m_Timeframe) - impulseWaveStartSwing.barIndex && k < 200; k++) { 
                int checkBar = impulseWaveStartSwing.barIndex - k; // barIndex giảm dần khi đi về quá khứ
                if (checkBar < 0) break; // Không đi quá xa
                if (m_time[checkBar] <= impulseWaveStartSwing.time) continue; 

                if (m_high[checkBar] > tempHighestPrice) {
                    tempHighestPrice = m_high[checkBar];
                    tempHighestTime = m_time[checkBar];
                    tempHighestBarIndex = checkBar;
                    potentialEndFound = true;
                }
                 // Nếu giá bắt đầu giảm sau khi tạo đỉnh thì có thể đó là SH
                if (potentialEndFound && m_high[checkBar] < tempHighestPrice && (tempHighestPrice - m_high[checkBar] > m_atr * 0.5) ) break; 
            }
            if (potentialEndFound && tempHighestPrice > impulseWaveStartSwing.price) {
                impulseWaveEndSwing.price = tempHighestPrice;
                impulseWaveEndSwing.time = tempHighestTime;
                impulseWaveEndSwing.barIndex = tempHighestBarIndex;
                impulseWaveEndSwing.type = SWING_HIGH; // Gán type
                foundImpulseWaveEnd = true;
            }
        }

    } else { // Xu hướng giảm, sóng đẩy từ Swing High -> Swing Low
        // Tìm Swing High gần nhất làm điểm bắt đầu sóng đẩy (impulseWaveStartSwing)
        for (int i = 0; i < numSwings; i++) {
            if (swings[i].type == SWING_HIGH) {
                impulseWaveStartSwing = swings[i];
                foundImpulseWaveStart = true;
                break; 
            }
        }
        // Tìm Swing Low gần nhất (sau impulseWaveStartSwing) làm điểm kết thúc sóng đẩy (impulseWaveEndSwing)
        for (int i = 0; i < numSwings; i++) {
            if (swings[i].type == SWING_LOW && swings[i].time > impulseWaveStartSwing.time) {
                impulseWaveEndSwing = swings[i];
                foundImpulseWaveEnd = true;
                break;
            }
        }
         if (!foundImpulseWaveEnd) { // Nếu không có swing low nào sau swing high, tìm giá thấp nhất kể từ sau impulseWaveStartSwing
            double tempLowestPrice = impulseWaveStartSwing.price;
            datetime tempLowestTime = impulseWaveStartSwing.time;
            int tempLowestBarIndex = impulseWaveStartSwing.barIndex;
            bool potentialEndFound = false;
            for (int k = 1; k < Bars(m_Symbol,m_Timeframe) - impulseWaveStartSwing.barIndex && k < 200; k++) {
                int checkBar = impulseWaveStartSwing.barIndex - k;
                if (checkBar < 0) break;
                if (m_time[checkBar] <= impulseWaveStartSwing.time) continue;

                if (m_low[checkBar] < tempLowestPrice) {
                    tempLowestPrice = m_low[checkBar];
                    tempLowestTime = m_time[checkBar];
                    tempLowestBarIndex = checkBar;
                    potentialEndFound = true;
                }
                if(potentialEndFound && m_low[checkBar] > tempLowestPrice && (m_low[checkBar] - tempLowestPrice > m_atr * 0.5) ) break;
            }
            if (potentialEndFound && tempLowestPrice < impulseWaveStartSwing.price) {
                impulseWaveEndSwing.price = tempLowestPrice;
                impulseWaveEndSwing.time = tempLowestTime;
                impulseWaveEndSwing.barIndex = tempLowestBarIndex;
                impulseWaveEndSwing.type = SWING_LOW; // Gán type
                foundImpulseWaveEnd = true;
            }
        }
    }

    if (!foundImpulseWaveStart || !foundImpulseWaveEnd) {
        LogPattern("Pullback", false, "Không tìm thấy đủ Swing Points cho sóng đẩy");
        return false;
    }
    // Đảm bảo sóng đẩy hợp lệ (start trước end)
    if (impulseWaveStartSwing.time >= impulseWaveEndSwing.time) {
        LogPattern("Pullback", false, "Sóng đẩy không hợp lệ (start time >= end time)");
        return false;
    }
    // Đảm bảo giá của sóng đẩy hợp lý
    if (isBullish && impulseWaveStartSwing.price >= impulseWaveEndSwing.price) {
        LogPattern("Pullback", false, "Sóng đẩy tăng không hợp lệ (start price >= end price)");
        return false;
    }
    if (!isBullish && impulseWaveStartSwing.price <= impulseWaveEndSwing.price) {
        LogPattern("Pullback", false, "Sóng đẩy giảm không hợp lệ (start price <= end price)");
        return false;
    }

    // Điều kiện 2: Giá hiện tại hồi về vùng giá trị (EMA 34/89 hoặc Fibonacci)
    // Tính EMA 34 và 89
    double ema34 = iMA(m_Symbol, m_Timeframe, 34, 0, MODE_EMA, PRICE_CLOSE, 0);
    double ema89 = iMA(m_Symbol, m_Timeframe, 89, 0, MODE_EMA, PRICE_CLOSE, 0);

    bool inEMAValueZone = false;
    if (isBullish) {
        inEMAValueZone = (m_low[0] <= MathMax(ema34, ema89) && m_high[0] >= MathMin(ema34, ema89));
    } else {
        inEMAValueZone = (m_high[0] >= MathMin(ema34, ema89) && m_low[0] <= MathMax(ema34, ema89));
    }

    // Tính Fibonacci Retracement của sóng đẩy gần nhất (từ impulseWaveStartSwing đến impulseWaveEndSwing)
    double fibLevel50 = 0.0;
    double fibLevel618 = 0.0;
    bool inFibZone = false;

    double impulseWaveRange = MathAbs(impulseWaveEndSwing.price - impulseWaveStartSwing.price);
    if (impulseWaveRange > 0) {
        if (isBullish) { // Sóng đẩy tăng từ impulseWaveStartSwing (Low) -> impulseWaveEndSwing (High)
            fibLevel50 = impulseWaveEndSwing.price - impulseWaveRange * 0.5;
            fibLevel618 = impulseWaveEndSwing.price - impulseWaveRange * 0.618;
            // Giá hiện tại (low của nến) phải chạm hoặc vượt qua fib 0.5 và không vượt quá fib 0.618 (tính từ trên xuống)
            inFibZone = (m_low[0] <= fibLevel50 && m_low[0] >= fibLevel618);
        } else { // Sóng đẩy giảm từ impulseWaveStartSwing (High) -> impulseWaveEndSwing (Low)
            fibLevel50 = impulseWaveEndSwing.price + impulseWaveRange * 0.5;
            fibLevel618 = impulseWaveEndSwing.price + impulseWaveRange * 0.618;
            // Giá hiện tại (high của nến) phải chạm hoặc vượt qua fib 0.5 và không vượt quá fib 0.618 (tính từ dưới lên)
            inFibZone = (m_high[0] >= fibLevel50 && m_high[0] <= fibLevel618);
        }
    }

    if (!inEMAValueZone && !inFibZone) {
        LogPattern("Pullback", false, "Giá không hồi về vùng giá trị (EMA hoặc Fibonacci)");
        return false;
    }

    // Điều kiện 3: Nến xác nhận
    bool confirmationCandle = false;
    if (isBullish) {
        // Bullish Engulfing hoặc Pinbar tăng
        // Bullish Engulfing: m_open[0] < m_close[1] && m_close[0] > m_open[1] && m_close[0] > m_open[0] && (m_close[0]-m_open[0]) > (m_open[1]-m_close[1])*0.8
        bool isBullishEngulfing = m_open[0] < m_close[1] && m_close[0] > m_open[1] && m_close[0] > m_open[0] && (m_close[0]-m_open[0]) > MathAbs(m_open[1]-m_close[1])*0.8;
        // Bullish Pinbar: (m_low[0] < m_open[0] && m_low[0] < m_close[0]) && (MathMin(m_open[0], m_close[0]) - m_low[0]) > 2 * MathAbs(m_open[0]-m_close[0]) && (m_high[0] - MathMax(m_open[0], m_close[0])) < MathAbs(m_open[0]-m_close[0])
        double body = MathAbs(m_open[0] - m_close[0]);
        double lowerWick = (m_open[0] < m_close[0]) ? (m_open[0] - m_low[0]) : (m_close[0] - m_low[0]);
        double upperWick = (m_open[0] < m_close[0]) ? (m_high[0] - m_close[0]) : (m_high[0] - m_open[0]);
        bool isBullishPinbar = lowerWick > 2 * body && upperWick < body && m_close[0] > m_open[0];
        confirmationCandle = isBullishEngulfing || isBullishPinbar;
    } else {
        // Bearish Engulfing hoặc Pinbar giảm
        // Bearish Engulfing: m_open[0] > m_close[1] && m_close[0] < m_open[1] && m_close[0] < m_open[0] && (m_open[0]-m_close[0]) > (m_close[1]-m_open[1])*0.8
        bool isBearishEngulfing = m_open[0] > m_close[1] && m_close[0] < m_open[1] && m_close[0] < m_open[0] && (m_open[0]-m_close[0]) > MathAbs(m_close[1]-m_open[1])*0.8;
        // Bearish Pinbar: (m_high[0] > m_open[0] && m_high[0] > m_close[0]) && (m_high[0] - MathMax(m_open[0], m_close[0])) > 2 * MathAbs(m_open[0]-m_close[0]) && (MathMin(m_open[0], m_close[0]) - m_low[0]) < MathAbs(m_open[0]-m_close[0])
        double body = MathAbs(m_open[0] - m_close[0]);
        double lowerWick = (m_open[0] < m_close[0]) ? (m_open[0] - m_low[0]) : (m_close[0] - m_low[0]);
        double upperWick = (m_open[0] < m_close[0]) ? (m_high[0] - m_close[0]) : (m_high[0] - m_open[0]);
        bool isBearishPinbar = upperWick > 2 * body && lowerWick < body && m_close[0] < m_open[0];
        confirmationCandle = isBearishEngulfing || isBearishPinbar;
    }

    if (!confirmationCandle) {
        LogPattern("Pullback", false, "Không có nến xác nhận");
        return false;
    }

    // Nếu tất cả điều kiện được thỏa mãn
    pattern.isValid = true;
    pattern.strength = 0.75; // Độ mạnh tạm thời, có thể tính toán chi tiết hơn
    pattern.description = StringFormat("Pullback %s (Structural) confirmed. EMA Zone: %s, Fib Zone: %s. Impulse: %.5f (bar %d) to %.5f (bar %d)", 
                                    isBullish ? "Bullish" : "Bearish", 
                                    inEMAValueZone ? "Yes" : "No", 
                                    inFibZone ? "Yes" : "No",
                                    impulseWaveStartSwing.price, impulseWaveStartSwing.barIndex,
                                    impulseWaveEndSwing.price, impulseWaveEndSwing.barIndex);
    pattern.startBar = impulseWaveStartSwing.barIndex; 
    pattern.endBar = 0; // Nến hiện tại là nến xác nhận, kết thúc của pullback phase

    // Tính toán SL/TP dựa trên cấu trúc
    if (isBullish) {
        pattern.entryLevel = m_close[0]; 
        pattern.stopLoss = impulseWaveStartSwing.price - m_atr * m_slBufferMultiplier; 
        
        if (foundImpulseWaveEnd && impulseWaveEndSwing.price > pattern.entryLevel) {
            pattern.takeProfit = impulseWaveEndSwing.price; 
            // Đảm bảo R:R tối thiểu nếu TP quá gần hoặc không hợp lệ
            if ((pattern.takeProfit - pattern.entryLevel) < (pattern.entryLevel - pattern.stopLoss) * m_minRR || pattern.takeProfit <= pattern.entryLevel) {
                 pattern.takeProfit = pattern.entryLevel + (pattern.entryLevel - pattern.stopLoss) * m_defaultRR; 
            }
        } else { 
            pattern.takeProfit = pattern.entryLevel + (pattern.entryLevel - pattern.stopLoss) * m_defaultRR; 
        }
    } else { // Bearish
        pattern.entryLevel = m_close[0];
        pattern.stopLoss = impulseWaveStartSwing.price + m_atr * m_slBufferMultiplier; 
        
        if (foundImpulseWaveEnd && impulseWaveEndSwing.price < pattern.entryLevel) {
            pattern.takeProfit = impulseWaveEndSwing.price;
            if ((pattern.entryLevel - pattern.takeProfit) < (pattern.stopLoss - pattern.entryLevel) * m_minRR || pattern.takeProfit >= pattern.entryLevel) {
                pattern.takeProfit = pattern.entryLevel - (pattern.stopLoss - pattern.entryLevel) * m_defaultRR;
            }
        } else { 
            pattern.takeProfit = pattern.entryLevel - (pattern.stopLoss - pattern.entryLevel) * m_defaultRR;
        }
    }
    // Kiểm tra lại SL và TP để đảm bảo hợp lệ (SL khác Entry, TP khác Entry và SL < Entry < TP cho Buy, SL > Entry > TP cho Sell)
    if (isBullish) {
        if (pattern.stopLoss >= pattern.entryLevel) {
            LogPattern("Pullback", false, StringFormat("SL >= Entry (%.5f >= %.5f). Điều chỉnh SL.", pattern.stopLoss, pattern.entryLevel));
            pattern.stopLoss = pattern.entryLevel - m_atr * MathMax(m_slBufferMultiplier, 0.1); // Đảm bảo SL < Entry
        }
        if (pattern.takeProfit <= pattern.entryLevel) {
            LogPattern("Pullback", false, StringFormat("TP <= Entry (%.5f <= %.5f). Điều chỉnh TP.", pattern.takeProfit, pattern.entryLevel));
            pattern.takeProfit = pattern.entryLevel + (pattern.entryLevel - pattern.stopLoss) * m_defaultRR;
        }
    } else { // Bearish
        if (pattern.stopLoss <= pattern.entryLevel) {
            LogPattern("Pullback", false, StringFormat("SL <= Entry (%.5f <= %.5f). Điều chỉnh SL.", pattern.stopLoss, pattern.entryLevel));
            pattern.stopLoss = pattern.entryLevel + m_atr * MathMax(m_slBufferMultiplier, 0.1); // Đảm bảo SL > Entry
        }
        if (pattern.takeProfit >= pattern.entryLevel) {
            LogPattern("Pullback", false, StringFormat("TP >= Entry (%.5f >= %.5f). Điều chỉnh TP.", pattern.takeProfit, pattern.entryLevel));
            pattern.takeProfit = pattern.entryLevel - (pattern.stopLoss - pattern.entryLevel) * m_defaultRR;
        }
    }
    // Đảm bảo SL và TP không quá gần nhau
    if(MathAbs(pattern.takeProfit - pattern.entryLevel) < m_atr * 0.5) { // Nếu TP quá gần entry
        LogPattern("Pullback", false, "TP quá gần Entry. Điều chỉnh TP theo default RR.");
        if(isBullish) pattern.takeProfit = pattern.entryLevel + (pattern.entryLevel - pattern.stopLoss) * m_defaultRR;
        else pattern.takeProfit = pattern.entryLevel - (pattern.stopLoss - pattern.entryLevel) * m_defaultRR;
    }

    LogPattern(pattern.description, true);
    return true;

    /* Phần code cũ bị comment lại
    // Tìm điểm pullback gần đây
    int pullbackStart = 0;
    int pullbackEnd = 0;
    bool hasPullback = false;
    double pullbackPercent = 0.0;
    
    if (isBullish) {
        // Tìm pullback trong xu hướng tăng (giảm giá sau khi tăng)
        double highest = m_high[1];
        int highestBar = 1;
        
        // Tìm giá cao nhất
        for (int i = 1; i < 20; i++) {
            if (m_high[i] > highest) {
                highest = m_high[i];
                highestBar = i;
            }
        }
        
        // Tìm pullback sau giá cao nhất
        double lowest = m_low[1];
        int lowestBar = 1;
        
        for (int i = 1; i < highestBar + 5 && i < 20; i++) {
            if (m_low[i] < lowest) {
                lowest = m_low[i];
                lowestBar = i;
            }
        }
        
        // Kiểm tra pullback hợp lệ
        if (highestBar < lowestBar && highest > lowest) {
            double priceRange = highest - m_close[trendStartBar]; // trendStartBar từ logic cũ
            if (priceRange <= 0) return false;
            
            pullbackPercent = ((highest - lowest) / priceRange) * 100.0;
            
            if (pullbackPercent >= m_minPullbackPct && pullbackPercent <= m_maxPullbackPct) {
                hasPullback = true;
                pullbackStart = highestBar;
                pullbackEnd = lowestBar;
            }
        }
    } else {
        // Tìm pullback trong xu hướng giảm (tăng giá sau khi giảm)
        double lowest = m_low[1];
        int lowestBar = 1;
        
        // Tìm giá thấp nhất
        for (int i = 1; i < 20; i++) {
            if (m_low[i] < lowest) {
                lowest = m_low[i];
                lowestBar = i;
            }
        }
        
        // Tìm pullback sau giá thấp nhất
        double highest = m_high[1];
        int highestBar = 1;
        
        for (int i = 1; i < lowestBar + 5 && i < 20; i++) {
            if (m_high[i] > highest) {
                highest = m_high[i];
                highestBar = i;
            }
        }
        
        // Kiểm tra pullback hợp lệ
        if (lowestBar < highestBar && lowest < highest) {
            double priceRange = m_close[trendStartBar] - lowest; // trendStartBar từ logic cũ
            if (priceRange <= 0) return false;
            
            pullbackPercent = ((highest - lowest) / priceRange) * 100.0;
            
            if (pullbackPercent >= m_minPullbackPct && pullbackPercent <= m_maxPullbackPct) {
                hasPullback = true;
                pullbackStart = lowestBar;
                pullbackEnd = highestBar;
            }
        }
    }
    
    if (!hasPullback) {
        LogPattern("Pullback", false, "Không tìm thấy pullback hợp lệ (logic cũ)");
        return false;
    }
    
    // Bộ lọc chặt chẽ nếu được bật
    if (m_StrictPullbackFilter) {
        // Đếm số nến xác nhận sau pullback
        int confirmationBars = 0;
        int rejectionCount = 0;
        
        if (isBullish) {
            // Đếm nến xác nhận cho xu hướng tăng
            for (int i = 0; i < pullbackEnd && i < 5; i++) {
                if (m_close[i] > m_close[i+1] && m_low[i] > m_low[pullbackEnd] * 0.9995) {
                    confirmationBars++;
                } else if (m_low[i] < m_low[pullbackEnd]) {
                    rejectionCount++;
                }
            }
        } else {
            // Đếm nến xác nhận cho xu hướng giảm
            for (int i = 0; i < pullbackEnd && i < 5; i++) {
                if (m_close[i] < m_close[i+1] && m_high[i] < m_high[pullbackEnd] * 1.0005) {
                    confirmationBars++;
                } else if (m_high[i] > m_high[pullbackEnd]) {
                    rejectionCount++;
                }
            }
        }
        
        // Kiểm tra số nến xác nhận và từ chối
        if (confirmationBars < m_MinConfirmationBars || rejectionCount > m_MaxRejectionCount) {
            LogPattern("Pullback", false, "Không đủ xác nhận: " + IntegerToString(confirmationBars) + 
                       " nến, " + IntegerToString(rejectionCount) + " từ chối");
            return false;
        }
    }
    
    // Tính toán chất lượng mẫu hình
    double quality = 0.60; // Giá trị cơ sở
    
    // Cộng thêm dựa trên độ sâu pullback
    if (pullbackPercent >= 30.0 && pullbackPercent <= 60.0) quality += 0.15;
    
    // Kiểm tra xác nhận Price Action
    bool hasPriceActionConfirmation = false;
    
    if (isBullish) {
        // Kiểm tra nến bullish sau pullback
        if (m_close[0] > m_open[0] && m_close[0] > m_close[1] && 
            m_low[0] > m_low[1] * 0.9995) {
            hasPriceActionConfirmation = true;
            quality += 0.10;
        }
    } else {
        // Kiểm tra nến bearish sau pullback
        if (m_close[0] < m_open[0] && m_close[0] < m_close[1] && 
            m_high[0] < m_high[1] * 1.0005) {
            hasPriceActionConfirmation = true;
            quality += 0.10;
        }
    }
    
    // Kiểm tra xác nhận volume nếu được kích hoạt
    bool hasVolumeConfirmation = false;
    if (m_useVolume && m_RequireVolumeConfirmation) {
        double avgVolume = 0;
        for (int i = 1; i < 10; i++) {
            avgVolume += m_volume[i];
        }
        avgVolume /= 9.0;
        
        if (m_volume[0] > avgVolume * m_VolumeThreshold) {
            hasVolumeConfirmation = true;
            quality += 0.05;
        }
    }
    
    // Lưu kết quả
    pattern.patternType = isBullish ? SCENARIO_BULLISH_PULLBACK : SCENARIO_BEARISH_PULLBACK;
    pattern.isValid = true;
    pattern.strength = quality;
    pattern.startBar = pullbackStart;
    pattern.endBar = pullbackEnd;
    pattern.description = StringFormat(
        "Pullback %s %.1f%%, Quality: %.2f (logic cũ)", 
        isBullish ? "Bullish" : "Bearish", 
        pullbackPercent, 
        quality
    );
    
    // Lưu thông tin bổ sung
    pattern.extraData.hasPriceActionConfirmation = hasPriceActionConfirmation;
    pattern.extraData.hasVolumeConfirmation = hasVolumeConfirmation;
    pattern.extraData.pullbackPercent = pullbackPercent;
    
    // Cập nhật biến cho lần phát hiện cuối cùng
    m_LastPatternQuality = quality;
    m_LastPatternType = pattern.patternType;
    m_LastDetectionTime = TimeCurrent();
    
    LogPattern(isBullish ? "Bullish Pullback" : "Bearish Pullback", true, pattern.description);
    return true;
    */
}
    
    // Tìm điểm pullback gần đây
    int pullbackStart = 0;
    int pullbackEnd = 0;
    bool hasPullback = false;
    double pullbackPercent = 0.0;
    
    if (isBullish) {
        // Tìm pullback trong xu hướng tăng (giảm giá sau khi tăng)
        double highest = m_high[1];
        int highestBar = 1;
        
        // Tìm giá cao nhất
        for (int i = 1; i < 20; i++) {
            if (m_high[i] > highest) {
                highest = m_high[i];
                highestBar = i;
            }
        }
        
        // Tìm pullback sau giá cao nhất
        double lowest = m_low[1];
        int lowestBar = 1;
        
        for (int i = 1; i < highestBar + 5 && i < 20; i++) {
            if (m_low[i] < lowest) {
                lowest = m_low[i];
                lowestBar = i;
            }
        }
        
        // Kiểm tra pullback hợp lệ
        if (highestBar < lowestBar && highest > lowest) {
            double priceRange = highest - m_close[trendStartBar];
            if (priceRange <= 0) return false;
            
            pullbackPercent = ((highest - lowest) / priceRange) * 100.0;
            
            if (pullbackPercent >= m_minPullbackPct && pullbackPercent <= m_maxPullbackPct) {
                hasPullback = true;
                pullbackStart = highestBar;
                pullbackEnd = lowestBar;
            }
        }
    } else {
        // Tìm pullback trong xu hướng giảm (tăng giá sau khi giảm)
        double lowest = m_low[1];
        int lowestBar = 1;
        
        // Tìm giá thấp nhất
        for (int i = 1; i < 20; i++) {
            if (m_low[i] < lowest) {
                lowest = m_low[i];
                lowestBar = i;
            }
        }
        
        // Tìm pullback sau giá thấp nhất
        double highest = m_high[1];
        int highestBar = 1;
        
        for (int i = 1; i < lowestBar + 5 && i < 20; i++) {
            if (m_high[i] > highest) {
                highest = m_high[i];
                highestBar = i;
            }
        }
        
        // Kiểm tra pullback hợp lệ
        if (lowestBar < highestBar && lowest < highest) {
            double priceRange = m_close[trendStartBar] - lowest;
            if (priceRange <= 0) return false;
            
            pullbackPercent = ((highest - lowest) / priceRange) * 100.0;
            
            if (pullbackPercent >= m_minPullbackPct && pullbackPercent <= m_maxPullbackPct) {
                hasPullback = true;
                pullbackStart = lowestBar;
                pullbackEnd = highestBar;
            }
        }
    }
    
    if (!hasPullback) {
        LogPattern("Pullback", false, "Không tìm thấy pullback hợp lệ");
        return false;
    }
    
    // Bộ lọc chặt chẽ nếu được bật
    if (m_StrictPullbackFilter) {
        // Đếm số nến xác nhận sau pullback
        int confirmationBars = 0;
        int rejectionCount = 0;
        
        if (isBullish) {
            // Đếm nến xác nhận cho xu hướng tăng
            for (int i = 0; i < pullbackEnd && i < 5; i++) {
                if (m_close[i] > m_close[i+1] && m_low[i] > m_low[pullbackEnd] * 0.9995) {
                    confirmationBars++;
                } else if (m_low[i] < m_low[pullbackEnd]) {
                    rejectionCount++;
                }
            }
        } else {
            // Đếm nến xác nhận cho xu hướng giảm
            for (int i = 0; i < pullbackEnd && i < 5; i++) {
                if (m_close[i] < m_close[i+1] && m_high[i] < m_high[pullbackEnd] * 1.0005) {
                    confirmationBars++;
                } else if (m_high[i] > m_high[pullbackEnd]) {
                    rejectionCount++;
                }
            }
        }
        
        // Kiểm tra số nến xác nhận và từ chối
        if (confirmationBars < m_MinConfirmationBars || rejectionCount > m_MaxRejectionCount) {
            LogPattern("Pullback", false, "Không đủ xác nhận: " + IntegerToString(confirmationBars) + 
                       " nến, " + IntegerToString(rejectionCount) + " từ chối");
            return false;
        }
    }
    
    // Tính toán chất lượng mẫu hình
    double quality = 0.60; // Giá trị cơ sở
    
    // Cộng thêm dựa trên độ sâu pullback
    if (pullbackPercent >= 30.0 && pullbackPercent <= 60.0) quality += 0.15;
    
    // Kiểm tra xác nhận Price Action
    bool hasPriceActionConfirmation = false;
    
    if (isBullish) {
        // Kiểm tra nến bullish sau pullback
        if (m_close[0] > m_open[0] && m_close[0] > m_close[1] && 
            m_low[0] > m_low[1] * 0.9995) {
            hasPriceActionConfirmation = true;
            quality += 0.10;
        }
    } else {
        // Kiểm tra nến bearish sau pullback
        if (m_close[0] < m_open[0] && m_close[0] < m_close[1] && 
            m_high[0] < m_high[1] * 1.0005) {
            hasPriceActionConfirmation = true;
            quality += 0.10;
        }
    }
    
    // Kiểm tra xác nhận volume nếu được kích hoạt
    bool hasVolumeConfirmation = false;
    if (m_useVolume && m_RequireVolumeConfirmation) {
        double avgVolume = 0;
        for (int i = 1; i < 10; i++) {
            avgVolume += m_volume[i];
        }
        avgVolume /= 9.0;
        
        if (m_volume[0] > avgVolume * m_VolumeThreshold) {
            hasVolumeConfirmation = true;
            quality += 0.05;
        }
    }
    
    // Lưu kết quả
    pattern.patternType = isBullish ? SCENARIO_BULLISH_PULLBACK : SCENARIO_BEARISH_PULLBACK;
    pattern.isValid = true;
    pattern.strength = quality;
    pattern.startBar = pullbackStart;
    pattern.endBar = pullbackEnd;
    pattern.description = StringFormat(
        "Pullback %s %.1f%%, Quality: %.2f", 
        isBullish ? "Bullish" : "Bearish", 
        pullbackPercent, 
        quality
    );
    
    // Lưu thông tin bổ sung
    pattern.extraData.hasPriceActionConfirmation = hasPriceActionConfirmation;
    pattern.extraData.hasVolumeConfirmation = hasVolumeConfirmation;
    pattern.extraData.pullbackPercent = pullbackPercent;
    
    // Cập nhật biến cho lần phát hiện cuối cùng
    m_LastPatternQuality = quality;
    m_LastPatternType = pattern.patternType;
    m_LastDetectionTime = TimeCurrent();
    
    LogPattern(isBullish ? "Bullish Pullback" : "Bearish Pullback", true, pattern.description);
    return true;
}

} // end namespace ApexPullback

#endif // PATTERN_DETECTOR_MQH_