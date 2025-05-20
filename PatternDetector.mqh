//+------------------------------------------------------------------+
//| PatternDetector.mqh                                             |
//| Copyright 2025, ApexPullback Team                               |
//| Phát hiện mẫu hình giá thông minh cho EA                        |
//+------------------------------------------------------------------+
#property strict

#include "CommonStructs.mqh"
#include "Logger.mqh"
#include "Enums.mqh"

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
    
    // Constructor để khởi tạo giá trị mặc định
    DetectedPattern() {
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
    // Thành viên dữ liệu cơ bản
    string m_symbol;                  // Cặp tiền tệ
    ENUM_TIMEFRAMES m_timeframe;      // Khung thời gian
    CLogger* m_logger;                // Con trỏ đến logger
    bool m_isInitialized;             // Trạng thái khởi tạo
    
    // Tham số cấu hình
    int m_minBarsForPattern;          // Số nến tối thiểu cho mẫu hình
    int m_maxBarsForPattern;          // Số nến tối đa cho mẫu hình
    double m_fibTolerance;            // Dung sai cho tỷ lệ Fibonacci (±%)
    double m_minPullbackPct;          // % pullback tối thiểu
    double m_maxPullbackPct;          // % pullback tối đa
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
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPatternDetector::CPatternDetector() {
    m_isInitialized = false;
    m_logger = NULL;
    m_atrHandle = INVALID_HANDLE;
    
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
    
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_logger = logger;
    
    // Tạo handle cho indicator ATR
    m_atrHandle = iATR(m_symbol, m_timeframe, 14);
    if (m_atrHandle == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Không thể tạo handle ATR trong PatternDetector");
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
    m_logger = logger;
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
    if (CopyHigh(m_symbol, m_timeframe, 0, bars, m_high) != bars) {
        if (m_logger) m_logger.LogError("Không thể copy dữ liệu giá high");
        return false;
    }
    
    if (CopyLow(m_symbol, m_timeframe, 0, bars, m_low) != bars) {
        if (m_logger) m_logger.LogError("Không thể copy dữ liệu giá low");
        return false;
    }
    
    if (CopyClose(m_symbol, m_timeframe, 0, bars, m_close) != bars) {
        if (m_logger) m_logger.LogError("Không thể copy dữ liệu giá close");
        return false;
    }
    
    if (CopyOpen(m_symbol, m_timeframe, 0, bars, m_open) != bars) {
        if (m_logger) m_logger.LogError("Không thể copy dữ liệu giá open");
        return false;
    }
    
    // Copy dữ liệu khối lượng nếu cần
    if (m_useVolume) {
        if (CopyTickVolume(m_symbol, m_timeframe, 0, bars, m_volume) != bars) {
            if (m_logger) m_logger.LogDebug("Volume không khả dụng cho " + m_symbol);
            m_useVolume = false;  // Tắt sử dụng volume nếu không có dữ liệu
        }
    }
    
    // Copy dữ liệu ATR
    if (m_atrHandle != INVALID_HANDLE) {
        if (CopyBuffer(m_atrHandle, 0, 0, bars, m_atrBuffer) != bars) {
            if (m_logger) m_logger.LogWarning("Không thể copy dữ liệu ATR");
        }
        else {
            // Cập nhật ATR hiện tại
            m_atr = m_atrBuffer[0];
        }
    }
    
    // Copy dữ liệu thời gian
    if (CopyTime(m_symbol, m_timeframe, 0, bars, m_time) != bars) {
        if (m_logger) m_logger.LogError("Không thể copy dữ liệu thời gian");
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

//+------------------------------------------------------------------+
//| Phát hiện mẫu hình và trả về thông tin                           |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectPattern(ENUM_PATTERN_TYPE& scenario, double& strength) {
    if (!m_isInitialized || m_atr <= 0) {
        if (m_logger) m_logger.LogError("PatternDetector chưa được khởi tạo đúng cách hoặc ATR không hợp lệ");
        scenario = SCENARIO_NONE;
        strength = 0.0;
        return false;
    }
    
    // Làm mới dữ liệu mới nhất
    if (!RefreshData()) {
        scenario = SCENARIO_NONE;
        strength = 0.0;
        return false;
    }
    
    // Phát hiện các loại mẫu hình
    bool foundPullback = DetectPullbackPatterns();
    bool foundReversal = DetectReversalPatterns();
    bool foundHarmonic = DetectHarmonicPatterns();
    
    // Chọn mẫu hình mạnh nhất
    DetectedPattern strongestPattern;
    strongestPattern.strength = 0.0;
    
    if (foundPullback && m_detectedPullback.strength > strongestPattern.strength) {
        strongestPattern = m_detectedPullback;
    }
    
    if (foundReversal && m_detectedReversal.strength > strongestPattern.strength) {
        strongestPattern = m_detectedReversal;
    }
    
    if (foundHarmonic && m_detectedHarmonic.strength > strongestPattern.strength) {
        strongestPattern = m_detectedHarmonic;
    }
    
    // Lưu lại mẫu hình được phát hiện gần nhất
    m_lastDetectedPattern = strongestPattern;
    
    // Trả về kết quả
    if (strongestPattern.strength > 0.0 && strongestPattern.isValid) {
        scenario = strongestPattern.type;
        strength = strongestPattern.strength;
        
        if (m_logger) {
            m_logger.LogDebug("Phát hiện mẫu hình: " + 
                           EnumToString(strongestPattern.type) + 
                           ", Strength: " + DoubleToString(strength, 2) + 
                           ", " + (strongestPattern.isBullish ? "Bullish" : "Bearish") + 
                           ", " + strongestPattern.description);
        }
        return true;
    }
    
    scenario = SCENARIO_NONE;
    strength = 0.0;
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình pullback                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectPullbackPatterns() {
    // Reset mẫu hình pullback đã phát hiện
    m_detectedPullback = DetectedPattern();
    
    // Kiểm tra các loại pullback khác nhau
    DetectedPattern strongPullbackBull, strongPullbackBear;
    DetectedPattern bullishPullback, bearishPullback;
    DetectedPattern fibPullbackBull, fibPullbackBear;
    
    bool foundStrongBull = CheckStrongPullback(true, strongPullbackBull);
    bool foundStrongBear = CheckStrongPullback(false, strongPullbackBear);
    bool foundBullish = CheckBullishPullback(bullishPullback);
    bool foundBearish = CheckBearishPullback(bearishPullback);
    bool foundFibBull = CheckFibonacciPullback(true, fibPullbackBull);
    bool foundFibBear = CheckFibonacciPullback(false, fibPullbackBear);
    
    // Xác định mẫu pullback mạnh nhất
    DetectedPattern strongestPullback;
    strongestPullback.strength = 0.0;
    
    if (foundStrongBull && strongPullbackBull.strength > strongestPullback.strength) {
        strongestPullback = strongPullbackBull;
    }
    
    if (foundStrongBear && strongPullbackBear.strength > strongestPullback.strength) {
        strongestPullback = strongPullbackBear;
    }
    
    if (foundBullish && bullishPullback.strength > strongestPullback.strength) {
        strongestPullback = bullishPullback;
    }
    
    if (foundBearish && bearishPullback.strength > strongestPullback.strength) {
        strongestPullback = bearishPullback;
    }
    
    if (foundFibBull && fibPullbackBull.strength > strongestPullback.strength) {
        strongestPullback = fibPullbackBull;
    }
    
    if (foundFibBear && fibPullbackBear.strength > strongestPullback.strength) {
        strongestPullback = fibPullbackBear;
    }
    
    // Lưu kết quả nếu tìm thấy
    if (strongestPullback.strength > 0.0) {
        m_detectedPullback = strongestPullback;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình đảo chiều                                 |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectReversalPatterns() {
    // Reset mẫu hình reversal đã phát hiện
    m_detectedReversal = DetectedPattern();
    
    // Kiểm tra các loại mẫu hình đảo chiều
    DetectedPattern engulfingBull, engulfingBear;
    
    bool foundEngulfingBull = CheckEngulfingPattern(true, engulfingBull);
    bool foundEngulfingBear = CheckEngulfingPattern(false, engulfingBear);
    
    // Xác định mẫu hình đảo chiều mạnh nhất
    DetectedPattern strongestReversal;
    strongestReversal.strength = 0.0;
    
    if (foundEngulfingBull && engulfingBull.strength > strongestReversal.strength) {
        strongestReversal = engulfingBull;
    }
    
    if (foundEngulfingBear && engulfingBear.strength > strongestReversal.strength) {
        strongestReversal = engulfingBear;
    }
    
    // Lưu kết quả nếu tìm thấy
    if (strongestReversal.strength > 0.0) {
        m_detectedReversal = strongestReversal;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện các mẫu hình harmonic                                  |
//+------------------------------------------------------------------+
bool CPatternDetector::DetectHarmonicPatterns() {
    // Reset mẫu hình harmonic đã phát hiện
    m_detectedHarmonic = DetectedPattern();
    
    // Kiểm tra các loại mẫu hình harmonic
    DetectedPattern gartleyBull, gartleyBear;
    DetectedPattern butterflyBull, butterflyBear;
    DetectedPattern batBull, batBear;
    DetectedPattern crabBull, crabBear;
    
    bool foundGartleyBull = CheckGartleyPattern(true, gartleyBull);
    bool foundGartleyBear = CheckGartleyPattern(false, gartleyBear);
    bool foundButterflyBull = CheckButterflyPattern(true, butterflyBull);
    bool foundButterflyBear = CheckButterflyPattern(false, butterflyBear);
    bool foundBatBull = CheckBatPattern(true, batBull);
    bool foundBatBear = CheckBatPattern(false, batBear);
    bool foundCrabBull = CheckCrabPattern(true, crabBull);
    bool foundCrabBear = CheckCrabPattern(false, crabBear);
    
    // Xác định mẫu hình harmonic mạnh nhất
    DetectedPattern strongestHarmonic;
    strongestHarmonic.strength = 0.0;
    
    if (foundGartleyBull && gartleyBull.strength > strongestHarmonic.strength) {
        strongestHarmonic = gartleyBull;
    }
    
    if (foundGartleyBear && gartleyBear.strength > strongestHarmonic.strength) {
        strongestHarmonic = gartleyBear;
    }
    
    if (foundButterflyBull && butterflyBull.strength > strongestHarmonic.strength) {
        strongestHarmonic = butterflyBull;
    }
    
    if (foundButterflyBear && butterflyBear.strength > strongestHarmonic.strength) {
        strongestHarmonic = butterflyBear;
    }
    
    if (foundBatBull && batBull.strength > strongestHarmonic.strength) {
        strongestHarmonic = batBull;
    }
    
    if (foundBatBear && batBear.strength > strongestHarmonic.strength) {
        strongestHarmonic = batBear;
    }
    
    if (foundCrabBull && crabBull.strength > strongestHarmonic.strength) {
        strongestHarmonic = crabBull;
    }
    
    if (foundCrabBear && crabBear.strength > strongestHarmonic.strength) {
        strongestHarmonic = crabBear;
    }
    
    // Lưu kết quả nếu tìm thấy
    if (strongestHarmonic.strength > 0.0) {
        m_detectedHarmonic = strongestHarmonic;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra pullback Fibonacci                                      |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckFibonacciPullback(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_FIBONACCI_PULLBACK;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Tìm điểm swing gần đây
    int swingBar = 0;
    double swingPrice = 0.0;
    bool foundSwing = (isBullish) ? 
                     FindSwingPoint(false, 3, 15, swingPrice) > 0 : 
                     FindSwingPoint(true, 3, 15, swingPrice) > 0;
    
    if (!foundSwing) {
        LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), false, "Không tìm thấy điểm swing gần đây");
        return false;
    }
    
    // Tìm điểm swing đối diện
    int oppositeSwingBar = 0;
    double oppositeSwingPrice = 0.0;
    bool foundOppositeSwing = (isBullish) ? 
                              FindSwingPoint(true, swingBar + 1, 20, oppositeSwingPrice) > 0 : 
                              FindSwingPoint(false, swingBar + 1, 20, oppositeSwingPrice) > 0;
    
    if (!foundOppositeSwing) {
        LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), false, "Không tìm thấy điểm swing đối diện");
        return false;
    }
    
    // Tính toán tỷ lệ pullback
    double range = MathAbs(oppositeSwingPrice - swingPrice);
    double currentPrice = isBullish ? m_close[0] : m_close[0];
    double pullbackRatio = 0.0;
    
    if (isBullish) {
        pullbackRatio = (oppositeSwingPrice - currentPrice) / range;
    } else {
        pullbackRatio = (currentPrice - oppositeSwingPrice) / range;
    }
    
    // Kiểm tra tỷ lệ Fibonacci
    bool isFibLevel = false;
    string fibLevel = "";
    
    if (IsValidFibonacciRatio(pullbackRatio, FIB_0_382)) {
        isFibLevel = true;
        fibLevel = "38.2%";
    } else if (IsValidFibonacciRatio(pullbackRatio, FIB_0_5)) {
        isFibLevel = true;
        fibLevel = "50.0%";
    } else if (IsValidFibonacciRatio(pullbackRatio, FIB_0_618)) {
        isFibLevel = true;
        fibLevel = "61.8%";
    } else if (IsValidFibonacciRatio(pullbackRatio, FIB_0_786)) {
        isFibLevel = true;
        fibLevel = "78.6%";
    }
    
    if (!isFibLevel) {
        LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), false, 
                 "Không nằm tại mức Fibonacci (" + DoubleToString(pullbackRatio * 100, 1) + "%)");
        return false;
    }
    
    // Kiểm tra xu hướng
    bool isCorrectTrend = isBullish ? IsUptrend(20, 5) : IsDowntrend(20, 5);
    
    if (!isCorrectTrend) {
        LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), false, 
                 "Không phát hiện xu hướng " + (isBullish ? "tăng" : "giảm") + " rõ ràng");
        return false;
    }
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = currentPrice;
    pattern.stopLoss = isBullish ? 
                      swingPrice - m_atr * 0.5 : 
                      swingPrice + m_atr * 0.5;
    pattern.takeProfit = isBullish ? 
                        oppositeSwingPrice + m_atr : 
                        oppositeSwingPrice - m_atr;
    pattern.startBar = MathMax(swingBar, oppositeSwingBar);
    pattern.endBar = 0;
    pattern.description = "Fibonacci Pullback " + fibLevel + " " + (isBullish ? "Bullish" : "Bearish");
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = CalculatePatternStrength(pattern);
    
    LogPattern("FibonacciPullback " + (isBullish ? "Bull" : "Bear"), true, 
             "Tại mức Fibonacci " + fibLevel + ", Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Bullish Pullback                                        |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckBullishPullback(DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_BULLISH_PULLBACK;
    pattern.isBullish = true;
    
    if (m_atr <= 0) {
        LogPattern("BullishPullback", false, "ATR không hợp lệ");
        return false;
    }
    
    // Tìm điểm swing low gần đây
    double swingLowPrice = 0.0;
    int swingLowBar = FindSwingPoint(false, 1, 10, swingLowPrice);
    
    if (swingLowBar <= 0) {
        LogPattern("BullishPullback", false, "Không tìm thấy swing low");
        return false;
    }
    
    // Tìm điểm swing high gần đây
    double swingHighPrice = 0.0;
    int swingHighBar = FindSwingPoint(true, swingLowBar + 1, 15, swingHighPrice);
    
    if (swingHighBar <= 0) {
        LogPattern("BullishPullback", false, "Không tìm thấy swing high");
        return false;
    }
    
    // Kiểm tra điều kiện pullback
    double pullbackDepth = 0.0;
    if (!IsValidPullbackDepth(swingHighPrice, swingLowPrice, pullbackDepth)) {
        LogPattern("BullishPullback", false, "Độ sâu pullback không hợp lệ: " + DoubleToString(pullbackDepth * 100, 1) + "%");
        return false;
    }
    
    // Kiểm tra xu hướng tăng
    if (!IsUptrend(20, 5)) {
        LogPattern("BullishPullback", false, "Không phát hiện xu hướng tăng");
        return false;
    }
    
    // Kiểm tra giá hiện tại cao hơn swing low
    if (m_close[0] <= swingLowPrice) {
        LogPattern("BullishPullback", false, "Giá hiện tại không cao hơn swing low");
        return false;
    }
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    pattern.stopLoss = swingLowPrice - m_atr * 0.3;
    pattern.takeProfit = swingHighPrice + m_atr;
    pattern.startBar = swingHighBar;
    pattern.endBar = 0;
    pattern.description = "Bullish Pullback (" + DoubleToString(pullbackDepth * 100, 1) + "%)";
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = CalculatePatternStrength(pattern);
    
    LogPattern("BullishPullback", true, 
             "Pullback: " + DoubleToString(pullbackDepth * 100, 1) + "%, Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Bearish Pullback                                        |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckBearishPullback(DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_BEARISH_PULLBACK;
    pattern.isBullish = false;
    
    if (m_atr <= 0) {
        LogPattern("BearishPullback", false, "ATR không hợp lệ");
        return false;
    }
    
    // Tìm điểm swing high gần đây
    double swingHighPrice = 0.0;
    int swingHighBar = FindSwingPoint(true, 1, 10, swingHighPrice);
    
    if (swingHighBar <= 0) {
        LogPattern("BearishPullback", false, "Không tìm thấy swing high");
        return false;
    }
    
    // Tìm điểm swing low gần đây
    double swingLowPrice = 0.0;
    int swingLowBar = FindSwingPoint(false, swingHighBar + 1, 15, swingLowPrice);
    
    if (swingLowBar <= 0) {
        LogPattern("BearishPullback", false, "Không tìm thấy swing low");
        return false;
    }
    
    // Kiểm tra điều kiện pullback
    double pullbackDepth = 0.0;
    if (!IsValidPullbackDepth(swingLowPrice, swingHighPrice, pullbackDepth)) {
        LogPattern("BearishPullback", false, "Độ sâu pullback không hợp lệ: " + DoubleToString(pullbackDepth * 100, 1) + "%");
        return false;
    }
    
    // Kiểm tra xu hướng giảm
    if (!IsDowntrend(20, 5)) {
        LogPattern("BearishPullback", false, "Không phát hiện xu hướng giảm");
        return false;
    }
    
    // Kiểm tra giá hiện tại thấp hơn swing high
    if (m_close[0] >= swingHighPrice) {
        LogPattern("BearishPullback", false, "Giá hiện tại không thấp hơn swing high");
        return false;
    }
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    pattern.stopLoss = swingHighPrice + m_atr * 0.3;
    pattern.takeProfit = swingLowPrice - m_atr;
    pattern.startBar = swingLowBar;
    pattern.endBar = 0;
    pattern.description = "Bearish Pullback (" + DoubleToString(pullbackDepth * 100, 1) + "%)";
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = CalculatePatternStrength(pattern);
    
    LogPattern("BearishPullback", true, 
             "Pullback: " + DoubleToString(pullbackDepth * 100, 1) + "%, Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Strong Pullback                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckStrongPullback(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_STRONG_PULLBACK;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("StrongPullback " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Kiểm tra xu hướng
    bool isCorrectTrend = isBullish ? IsUptrend(20, 5) : IsDowntrend(20, 5);
    
    if (!isCorrectTrend) {
        LogPattern("StrongPullback " + (isBullish ? "Bull" : "Bear"), false, 
                 "Không phát hiện xu hướng " + (isBullish ? "tăng" : "giảm") + " rõ ràng");
        return false;
    }
    
    // Kiểm tra nếu có volume tăng mạnh (nếu có dữ liệu volume)
    bool hasVolumeSpike = false;
    if (m_useVolume) {
        long avgVolume = 0;
        for (int i = 1; i < 5; i++) {
            avgVolume += m_volume[i];
        }
        avgVolume /= 4;
        
        hasVolumeSpike = (m_volume[0] > avgVolume * 1.5);
    }
    
    // Tìm điểm swing và điều kiện pullback
    double swingPoint1 = 0.0, swingPoint2 = 0.0;
    int swingBar1 = 0, swingBar2 = 0;
    
    if (isBullish) {
        swingBar1 = FindSwingPoint(true, 5, 15, swingPoint1);  // Swing high
        swingBar2 = FindSwingPoint(false, 1, 8, swingPoint2);  // Swing low
    } else {
        swingBar1 = FindSwingPoint(false, 5, 15, swingPoint1); // Swing low
        swingBar2 = FindSwingPoint(true, 1, 8, swingPoint2);   // Swing high
    }
    
    if (swingBar1 <= 0 || swingBar2 <= 0) {
        LogPattern("StrongPullback " + (isBullish ? "Bull" : "Bear"), false, "Không tìm thấy đủ điểm swing");
        return false;
    }
    
    // Kiểm tra độ sâu pullback
    double pullbackDepth = 0.0;
    if (isBullish) {
        pullbackDepth = (swingPoint1 - swingPoint2) / swingPoint1;
    } else {
        pullbackDepth = (swingPoint2 - swingPoint1) / swingPoint1;
    }
    
    if (pullbackDepth < m_minPullbackPct / 100.0 || pullbackDepth > m_maxPullbackPct / 100.0) {
        LogPattern("StrongPullback " + (isBullish ? "Bull" : "Bear"), false, 
                 "Độ sâu pullback không hợp lệ: " + DoubleToString(pullbackDepth * 100, 1) + "%");
        return false;
    }
    
    // Kiểm tra hành động giá hiện tại
    if (isBullish) {
        // Cho bullish: giá hiện tại phải cao hơn swing low và đang bật lên
        if (m_close[0] <= swingPoint2 || m_close[0] <= m_open[0]) {
            LogPattern("StrongPullback Bull", false, "Giá hiện tại không phù hợp");
            return false;
        }
    } else {
        // Cho bearish: giá hiện tại phải thấp hơn swing high và đang giảm
        if (m_close[0] >= swingPoint2 || m_close[0] >= m_open[0]) {
            LogPattern("StrongPullback Bear", false, "Giá hiện tại không phù hợp");
            return false;
        }
    }
    
    // Kiểm tra động lượng mạnh
    double momentum = MathAbs(m_close[0] - m_open[0]) / m_atr;
    bool hasStrongMomentum = (momentum > 0.3);
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    
    if (isBullish) {
        pattern.stopLoss = swingPoint2 - m_atr * 0.5;
        pattern.takeProfit = swingPoint1 + m_atr;
    } else {
        pattern.stopLoss = swingPoint2 + m_atr * 0.5;
        pattern.takeProfit = swingPoint1 - m_atr;
    }
    
    pattern.startBar = MathMax(swingBar1, swingBar2);
    pattern.endBar = 0;
    pattern.description = "Strong " + (isBullish ? "Bullish" : "Bearish") + " Pullback (" + 
                       DoubleToString(pullbackDepth * 100, 1) + "%)";
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = CalculatePatternStrength(pattern);
    
    // Tăng độ mạnh nếu có thêm điều kiện
    if (hasVolumeSpike) pattern.strength *= 1.2;
    if (hasStrongMomentum) pattern.strength *= 1.1;
    
    // Giới hạn độ mạnh tối đa là 1.0
    pattern.strength = MathMin(pattern.strength, 1.0);
    
    LogPattern("StrongPullback " + (isBullish ? "Bull" : "Bear"), true, 
             "Pullback: " + DoubleToString(pullbackDepth * 100, 1) + "%, Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Engulfing Pattern                                       |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckEngulfingPattern(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_MOMENTUM_SHIFT;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("Engulfing " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Kiểm tra xu hướng trước mẫu hình
    bool isCorrectTrend = isBullish ? IsDowntrend(10, 3) : IsUptrend(10, 3);
    
    if (!isCorrectTrend) {
        LogPattern("Engulfing " + (isBullish ? "Bull" : "Bear"), false, 
                 "Không phát hiện xu hướng " + (isBullish ? "giảm" : "tăng") + " trước mẫu hình");
        return false;
    }
    
    // Kiểm tra điều kiện engulfing
    bool isEngulfing = false;
    
    if (isBullish) {
        // Bullish engulfing: nến trước giảm, nến hiện tại tăng và "nuốt" nến trước
        isEngulfing = (m_close[1] < m_open[1]) &&  // Nến trước giảm
                      (m_close[0] > m_open[0]) &&  // Nến hiện tại tăng
                      (m_close[0] > m_open[1]) &&  // Đóng cửa hiện tại cao hơn mở cửa trước
                      (m_open[0] < m_close[1]);    // Mở cửa hiện tại thấp hơn đóng cửa trước
    } else {
        // Bearish engulfing: nến trước tăng, nến hiện tại giảm và "nuốt" nến trước
        isEngulfing = (m_close[1] > m_open[1]) &&  // Nến trước tăng
                      (m_close[0] < m_open[0]) &&  // Nến hiện tại giảm
                      (m_close[0] < m_open[1]) &&  // Đóng cửa hiện tại thấp hơn mở cửa trước
                      (m_open[0] > m_close[1]);    // Mở cửa hiện tại cao hơn đóng cửa trước
    }
    
    if (!isEngulfing) {
        LogPattern("Engulfing " + (isBullish ? "Bull" : "Bear"), false, "Không phát hiện mẫu hình engulfing");
        return false;
    }
    
    // Kiểm tra kích thước nến
    double candleSize = MathAbs(m_close[0] - m_open[0]);
    if (candleSize < m_atr * 0.5) {
        LogPattern("Engulfing " + (isBullish ? "Bull" : "Bear"), false, "Kích thước nến quá nhỏ");
        return false;
    }
    
    // Kiểm tra nếu có volume tăng mạnh (nếu có dữ liệu volume)
    bool hasVolumeConfirmation = false;
    if (m_useVolume) {
        hasVolumeConfirmation = (m_volume[0] > m_volume[1] * 1.2);
    }
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    
    if (isBullish) {
        pattern.stopLoss = MathMin(m_low[0], m_low[1]) - m_atr * 0.3;
        pattern.takeProfit = m_close[0] + (m_close[0] - pattern.stopLoss) * 2;
    } else {
        pattern.stopLoss = MathMax(m_high[0], m_high[1]) + m_atr * 0.3;
        pattern.takeProfit = m_close[0] - (pattern.stopLoss - m_close[0]) * 2;
    }
    
    pattern.startBar = 1;
    pattern.endBar = 0;
    pattern.description = "Engulfing " + (isBullish ? "Bullish" : "Bearish") + 
                       (hasVolumeConfirmation ? " (Volume Confirmation)" : "");
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = 0.65;  // Giá trị cơ sở
    
    // Điều chỉnh độ mạnh
    if (candleSize > m_atr * 0.8) pattern.strength += 0.1;
    if (hasVolumeConfirmation) pattern.strength += 0.1;
    
    LogPattern("Engulfing " + (isBullish ? "Bull" : "Bear"), true, 
             "Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Gartley Pattern                                         |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckGartleyPattern(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("Gartley " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Tìm các điểm swing cho mẫu hình Gartley (cần 5 điểm: X, A, B, C, D)
    double pointX = 0.0, pointA = 0.0, pointB = 0.0, pointC = 0.0, pointD = 0.0;
    int barX = 0, barA = 0, barB = 0, barC = 0, barD = 0;
    
    // Đây là logic đơn giản hóa cho việc tìm các điểm swing
    // Trong thực tế, cần logic phức tạp hơn để tìm chính xác các điểm này
    
    if (isBullish) {
        // Tìm các điểm cho Bullish Gartley
        barX = FindSwingPoint(false, 30, 50, pointX);
        barA = FindSwingPoint(true, barX - 5, 20, pointA);
        barB = FindSwingPoint(false, barA - 5, 15, pointB);
        barC = FindSwingPoint(true, barB - 5, 10, pointC);
        barD = 0;  // Điểm D là hiện tại
        pointD = m_close[0];
    } else {
        // Tìm các điểm cho Bearish Gartley
        barX = FindSwingPoint(true, 30, 50, pointX);
        barA = FindSwingPoint(false, barX - 5, 20, pointA);
        barB = FindSwingPoint(true, barA - 5, 15, pointB);
        barC = FindSwingPoint(false, barB - 5, 10, pointC);
        barD = 0;  // Điểm D là hiện tại
        pointD = m_close[0];
    }
    
    // Kiểm tra nếu tìm thấy đủ các điểm
    if (barX <= 0 || barA <= 0 || barB <= 0 || barC <= 0) {
        LogPattern("Gartley " + (isBullish ? "Bull" : "Bear"), false, "Không tìm thấy đủ điểm swing");
        return false;
    }
    
    // Tính toán các tỷ lệ Fibonacci
    double retracementXA_B = 0.0;
    double retracementAB_C = 0.0;
    double retracementXA_D = 0.0;
    
    if (isBullish) {
        retracementXA_B = (pointA - pointB) / (pointA - pointX);
        retracementAB_C = (pointB - pointC) / (pointA - pointB);
        retracementXA_D = (pointA - pointD) / (pointA - pointX);
    } else {
        retracementXA_B = (pointB - pointA) / (pointX - pointA);
        retracementAB_C = (pointC - pointB) / (pointB - pointA);
        retracementXA_D = (pointD - pointA) / (pointX - pointA);
    }
    
    // Kiểm tra các tỷ lệ Fibonacci của Gartley
    bool isGartley = IsValidFibonacciRatio(retracementXA_B, GARTLEY_B) &&
                   IsValidFibonacciRatio(retracementAB_C, GARTLEY_C) &&
                   IsValidFibonacciRatio(retracementXA_D, GARTLEY_D);
    
    if (!isGartley) {
        LogPattern("Gartley " + (isBullish ? "Bull" : "Bear"), false, "Tỷ lệ Fibonacci không phù hợp");
        return false;
    }
    
    // Thiết lập thông tin cho pattern hợp lệ
    pattern.isValid = true;
    pattern.entryLevel = pointD;
    
    if (isBullish) {
        pattern.stopLoss = pointD - m_atr * 0.8;
        pattern.takeProfit = pointC + (pointC - pointD) * 0.618;
    } else {
        pattern.stopLoss = pointD + m_atr * 0.8;
        pattern.takeProfit = pointC - (pointD - pointC) * 0.618;
    }
    
    pattern.startBar = barX;
    pattern.endBar = 0;
    pattern.description = "Gartley " + (isBullish ? "Bullish" : "Bearish");
    
    // Tính toán độ mạnh của mẫu hình
    pattern.strength = 0.75;  // Giá trị cơ sở cho Harmonic Patterns
    
    // Điều chỉnh độ mạnh dựa trên sự chính xác của các tỷ lệ
    double fibAccuracy = (
        (1.0 - MathAbs(retracementXA_B - GARTLEY_B) / GARTLEY_B) +
        (1.0 - MathAbs(retracementAB_C - GARTLEY_C) / GARTLEY_C) +
        (1.0 - MathAbs(retracementXA_D - GARTLEY_D) / GARTLEY_D)
    ) / 3.0;
    
    pattern.strength *= fibAccuracy;
    
    LogPattern("Gartley " + (isBullish ? "Bull" : "Bear"), true, 
             "Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Butterfly Pattern                                       |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckButterflyPattern(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("Butterfly " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Logic tương tự như CheckGartleyPattern nhưng với các tỷ lệ của Butterfly
    // Đây là phiên bản đơn giản hóa, trong thực tế cần logic phức tạp hơn
    
    // Giả định đã tìm thấy các điểm và kiểm tra tỷ lệ
    bool isButterfly = false;  // Cần thực hiện kiểm tra thực tế
    
    if (!isButterfly) {
        LogPattern("Butterfly " + (isBullish ? "Bull" : "Bear"), false, "Tỷ lệ không phù hợp");
        return false;
    }
    
    // Thiết lập thông tin cho pattern giả định
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    pattern.stopLoss = isBullish ? m_close[0] - m_atr : m_close[0] + m_atr;
    pattern.takeProfit = isBullish ? m_close[0] + m_atr * 2 : m_close[0] - m_atr * 2;
    pattern.startBar = 30;  // Giá trị giả định
    pattern.endBar = 0;
    pattern.description = "Butterfly " + (isBullish ? "Bullish" : "Bearish");
    pattern.strength = 0.7;  // Giá trị giả định
    
    LogPattern("Butterfly " + (isBullish ? "Bull" : "Bear"), true, 
             "Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Bat Pattern                                             |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckBatPattern(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("Bat " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Logic tương tự như CheckGartleyPattern nhưng với các tỷ lệ của Bat
    // Đây là phiên bản đơn giản hóa, trong thực tế cần logic phức tạp hơn
    
    // Giả định đã tìm thấy các điểm và kiểm tra tỷ lệ
    bool isBat = false;  // Cần thực hiện kiểm tra thực tế
    
    if (!isBat) {
        LogPattern("Bat " + (isBullish ? "Bull" : "Bear"), false, "Tỷ lệ không phù hợp");
        return false;
    }
    
    // Thiết lập thông tin cho pattern giả định
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    pattern.stopLoss = isBullish ? m_close[0] - m_atr : m_close[0] + m_atr;
    pattern.takeProfit = isBullish ? m_close[0] + m_atr * 2 : m_close[0] - m_atr * 2;
    pattern.startBar = 25;  // Giá trị giả định
    pattern.endBar = 0;
    pattern.description = "Bat " + (isBullish ? "Bullish" : "Bearish");
    pattern.strength = 0.72;  // Giá trị giả định
    
    LogPattern("Bat " + (isBullish ? "Bull" : "Bear"), true, 
             "Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra Crab Pattern                                            |
//+------------------------------------------------------------------+
bool CPatternDetector::CheckCrabPattern(bool isBullish, DetectedPattern& pattern) {
    // Reset pattern
    pattern = DetectedPattern();
    pattern.type = SCENARIO_HARMONIC_PATTERN;
    pattern.isBullish = isBullish;
    
    if (m_atr <= 0) {
        LogPattern("Crab " + (isBullish ? "Bull" : "Bear"), false, "ATR không hợp lệ");
        return false;
    }
    
    // Logic tương tự như CheckGartleyPattern nhưng với các tỷ lệ của Crab
    // Đây là phiên bản đơn giản hóa, trong thực tế cần logic phức tạp hơn
    
    // Giả định đã tìm thấy các điểm và kiểm tra tỷ lệ
    bool isCrab = false;  // Cần thực hiện kiểm tra thực tế
    
    if (!isCrab) {
        LogPattern("Crab " + (isBullish ? "Bull" : "Bear"), false, "Tỷ lệ không phù hợp");
        return false;
    }
    
    // Thiết lập thông tin cho pattern giả định
    pattern.isValid = true;
    pattern.entryLevel = m_close[0];
    pattern.stopLoss = isBullish ? m_close[0] - m_atr : m_close[0] + m_atr;
    pattern.takeProfit = isBullish ? m_close[0] + m_atr * 2 : m_close[0] - m_atr * 2;
    pattern.startBar = 35;  // Giá trị giả định
    pattern.endBar = 0;
    pattern.description = "Crab " + (isBullish ? "Bullish" : "Bearish");
    pattern.strength = 0.75;  // Giá trị giả định
    
    LogPattern("Crab " + (isBullish ? "Bull" : "Bear"), true, 
             "Strength: " + DoubleToString(pattern.strength, 2));
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm wrapper cho phát hiện Pullback                               |
//+------------------------------------------------------------------+
bool CPatternDetector::IsPullback(bool isBullish, double& strength) {
    DetectedPattern pattern;
    
    if (isBullish) {
        // Kiểm tra các loại pullback bullish
        bool foundStrong = CheckStrongPullback(true, pattern);
        if (!foundStrong) foundStrong = CheckBullishPullback(pattern);
        if (!foundStrong) foundStrong = CheckFibonacciPullback(true, pattern);
        
        if (foundStrong) {
            strength = pattern.strength;
            return true;
        }
    } else {
        // Kiểm tra các loại pullback bearish
        bool foundStrong = CheckStrongPullback(false, pattern);
        if (!foundStrong) foundStrong = CheckBearishPullback(pattern);
        if (!foundStrong) foundStrong = CheckFibonacciPullback(false, pattern);
        
        if (foundStrong) {
            strength = pattern.strength;
            return true;
        }
    }
    
    strength = 0.0;
    return false;
}

//+------------------------------------------------------------------+
//| Hàm wrapper cho phát hiện Reversal                               |
//+------------------------------------------------------------------+
bool CPatternDetector::IsReversal(bool isBullish, double& strength) {
    DetectedPattern pattern;
    
    bool found = CheckEngulfingPattern(isBullish, pattern);
    
    if (found) {
        strength = pattern.strength;
        return true;
    }
    
    strength = 0.0;
    return false;
}

//+------------------------------------------------------------------+
//| Hàm wrapper cho phát hiện Harmonic                               |
//+------------------------------------------------------------------+
bool CPatternDetector::IsHarmonic(bool isBullish, double& strength) {
    DetectedPattern pattern;
    
    bool found = CheckGartleyPattern(isBullish, pattern);
    if (!found) found = CheckButterflyPattern(isBullish, pattern);
    if (!found) found = CheckBatPattern(isBullish, pattern);
    if (!found) found = CheckCrabPattern(isBullish, pattern);
    
    if (found) {
        strength = pattern.strength;
        return true;
    }
    
    strength = 0.0;
    return false;
}

//+------------------------------------------------------------------+
//| Lấy thông tin chi tiết về mẫu hình đã phát hiện                  |
//+------------------------------------------------------------------+
bool CPatternDetector::GetPatternDetails(DetectedPattern& pattern) {
    if (m_lastDetectedPattern.isValid) {
        pattern = m_lastDetectedPattern;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem một độ sâu pullback có hợp lệ không                 |
//+------------------------------------------------------------------+
bool CPatternDetector::IsValidPullbackDepth(double highPrice, double lowPrice, double& ratio) {
    if (highPrice <= 0 || lowPrice <= 0) return false;
    
    ratio = MathAbs(highPrice - lowPrice) / highPrice;
    
    // Kiểm tra nếu độ sâu pullback nằm trong khoảng cho phép
    return (ratio >= m_minPullbackPct / 100.0 && ratio <= m_maxPullbackPct / 100.0);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem một tỷ lệ có thỏa mãn tỷ lệ Fibonacci cho trước    |
//+------------------------------------------------------------------+
bool CPatternDetector::IsValidFibonacciRatio(double ratio, double targetRatio) {
    double tolerance = m_fibTolerance;
    return (MathAbs(ratio - targetRatio) <= tolerance);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng tăng trong một khoảng nến nhất định            |
//+------------------------------------------------------------------+
bool CPatternDetector::IsUptrend(int startBar, int endBar) {
    if (startBar < endBar || startBar >= ArraySize(m_close) || endBar < 0) {
        return false;
    }
    
    // Tính giá trung bình cho phân đoạn đầu và cuối
    double earlyAvg = 0.0, lateAvg = 0.0;
    int earlyBars = MathMin(5, startBar - endBar);
    int lateBars = MathMin(5, startBar);
    
    for (int i = 0; i < earlyBars; i++) {
        earlyAvg += m_close[startBar - i];
    }
    
    for (int i = 0; i < lateBars; i++) {
        lateAvg += m_close[endBar + i];
    }
    
    earlyAvg /= earlyBars;
    lateAvg /= lateBars;
    
    // Kiểm tra xu hướng tăng: phần đầu phải thấp hơn phần cuối
    return (earlyAvg < lateAvg * 0.98);
}

//+------------------------------------------------------------------+
//| Kiểm tra xu hướng giảm trong một khoảng nến nhất định            |
//+------------------------------------------------------------------+
bool CPatternDetector::IsDowntrend(int startBar, int endBar) {
    if (startBar < endBar || startBar >= ArraySize(m_close) || endBar < 0) {
        return false;
    }
    
    // Tính giá trung bình cho phân đoạn đầu và cuối
    double earlyAvg = 0.0, lateAvg = 0.0;
    int earlyBars = MathMin(5, startBar - endBar);
    int lateBars = MathMin(5, startBar);
    
    for (int i = 0; i < earlyBars; i++) {
        earlyAvg += m_close[startBar - i];
    }
    
    for (int i = 0; i < lateBars; i++) {
        lateAvg += m_close[endBar + i];
    }
    
    earlyAvg /= earlyBars;
    lateAvg /= lateBars;
    
    // Kiểm tra xu hướng giảm: phần đầu phải cao hơn phần cuối
    return (earlyAvg > lateAvg * 1.02);
}

//+------------------------------------------------------------------+
//| Ghi Log thông tin mẫu hình                                       |
//+------------------------------------------------------------------+
void CPatternDetector::LogPattern(string patternName, bool isValid, string description = "") {
    if (m_logger == NULL) return;
    
    if (isValid) {
        m_logger.LogDebug("Pattern: " + patternName + " hợp lệ. " + description);
    } else if (description != "") {
        m_logger.LogDebug("Pattern: " + patternName + " không hợp lệ. " + description);
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