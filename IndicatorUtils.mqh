//+------------------------------------------------------------------+
//| File: IndicatorUtils.mqh                                         |
//| Purpose: Chuẩn hóa toàn bộ phép tính chỉ báo cho Apex Pullback EA |
//| Version: 14.0                                                     |
//+------------------------------------------------------------------+

#ifndef INDICATORUTILS_MQH_
#define INDICATORUTILS_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "CommonStructs.mqh"      // Core structures, enums, and inputs
#include "Enums.mqh"            // TẤT CẢ các enum


// === INCLUDES CỤ THỂ (NẾU CẦN) ===
#include "Logger.mqh"          // For logging within the class
// #include "MathHelper.mqh"

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

// Forward declaration for EAContext if CIndicatorUtils needs it directly
// struct EAContext; // Likely not needed if EAContext is passed via methods or constructor


class CIndicatorUtils {
private:
    // === Các thuộc tính cơ bản ===
    string m_Symbol;                // Symbol hiện tại
    ENUM_TIMEFRAMES m_Timeframe;    // Timeframe chính
    ENUM_TIMEFRAMES m_HigherTF;     // Timeframe cao hơn (thường H4)
    bool m_IsInitialized;           // Trạng thái khởi tạo
    bool m_VerboseLogging;          // Bật log chi tiết

    IndicatorHandles m_IndicatorHandles[1]; // Di chuyển vào đây, kích thước 1 vì logic cũ dùng g_IndicatorHandles[0]
    
        // === Các Handle chỉ báo - Timeframe chính ===
    long m_MA_Handles[10];          // Lưu handle của các MA (EMA chủ yếu)
    long m_ADX_Handle;              // ADX
    long m_RSI_Handle;              // RSI
    long m_ATR_Handle;              // ATR
    long m_Volume_Handle;           // Volume
    long m_MACD_Handle;             // MACD
    long m_BB_Handle;               // Bollinger Bands
    
    // === Các Handle chỉ báo - Timeframe cao hơn (H4) ===
    long m_HTF_MA_Handles[10];      // EMA trên H4
    long m_HTF_ADX_Handle;          // ADX trên H4
    long m_HTF_RSI_Handle;          // RSI trên H4
    long m_HTF_ATR_Handle;          // ATR trên H4
    
    // === Bộ đệm cache cho tối ưu hóa ===
    bool m_UseCache;                // Bật/tắt cache
    datetime m_LastUpdateTime;      // Thời gian cập nhật cache cuối
    double m_CachedValues[30];      // Cache các giá trị cho tick hiện tại
    
    // === Lưu trữ chu kỳ cho các MA ===
    int m_MAPeriods[10];            // Lưu chu kỳ cho các MA
    int m_MACount;                  // Số lượng MA đã khởi tạo
    
    // Log lỗi và thông báo
    void LogMessage(string message);
    
        // Mảng lưu giá High/Low/Close/Volume cho tính toán
    double m_PriceBuffer[];
    double m_HighBuffer[];
    double m_LowBuffer[];
    double m_CloseBuffer[];
    double m_VolumeBuffer[];
    
    // Hàm Cache và quản lý bộ đệm
    bool UpdatePriceBuffers(int bars);
    int GetCacheIndex(string indicator, int period = 0);
    bool InitializeGlobalIndicatorCache(bool forceRefresh=false); // Chuyển GlobalInitializeIndicatorCache thành phương thức riêng
    
public:
    // Constructor và Destructor
    CIndicatorUtils();
    ~CIndicatorUtils();
    
    // === Khởi tạo và giải phóng ===
    bool Initialize(string symbol, ENUM_TIMEFRAMES mainTimeframe, 
                   ENUM_TIMEFRAMES higherTimeframe = PERIOD_H4, 
                   bool useCache = true, bool verboseLogging = false, bool forceRefreshCache = false);
    void Deinitialize();
    
    // === Đăng ký Moving Averages (EMA) ===
    bool RegisterMA(int period, ENUM_MA_METHOD maMethod = MODE_EMA, 
                   ENUM_APPLIED_PRICE appliedPrice = PRICE_CLOSE);
    
    // === Đọc giá trị Moving Averages ===
    double GetMA(int period, int shift = 0);
    double GetMAOnHigherTF(int period, int shift = 0);
    double CheckHTF_MASlope(int period1, int period2, int period3, int period4);
    IndicatorHandles GetGlobalHandles() { return m_IndicatorHandles[0]; } // Hàm truy cập m_IndicatorHandles
    
    // === ADX và các thành phần ===
    double GetADX(int shift = 0);
    double GetADXPlus(int shift = 0);
    double GetADXMinus(int shift = 0);
    double GetADXOnHigherTF(int shift = 0);
    
    // === RSI và các dẫn xuất ===
    double GetRSI(int shift = 0);
    double GetRSIOnHigherTF(int shift = 0);
    
    // === ATR và các dẫn xuất ===
    double GetATR(int shift = 0);
    double GetATROnHigherTF(int shift = 0);
    double GetATRRatio(int lookbackPeriods = 10);
    
    // === MACD ===
    double GetMACDMain(int shift = 0);
    double GetMACDSignal(int shift = 0);
    double GetMACDHistogram(int shift = 0);
    double GetMACDHistogramSlope(int periods = 3);
    
    // === Bollinger Bands ===
    double GetBBUpper(int shift = 0);
    double GetBBMiddle(int shift = 0);
    double GetBBLower(int shift = 0);
    double GetBBWidth(int shift = 0);
    
    // === Volume ===
    double GetVolume(int shift = 0);
    double GetAverageVolume(int periods = 20);
    double GetVolumeRatio();
    
    // === Spread ===
    double GetCurrentSpread();
    double GetAverageSpread(int periods = 20);
    
    // === Hàm tiện ích phân tích ===
    bool IsCrossUp(int indicator1, int indicator2, int shift = 1);
    bool IsCrossDown(int indicator1, int indicator2, int shift = 1);
    bool IsPriceAboveMA(int period, int shift = 0);
    bool IsPriceBelowMA(int period, int shift = 0);
    
    // === Đánh giá mức độ biến động thị trường ===
    bool IsVolatilityHigh(double threshold = 1.5);
    bool IsVolatilityLow(double threshold = 0.7);
    bool IsMarketRangebound(int lookback = 20);
    
    // === Phân tích Price Action ===
    bool IsBullishCandle(int shift = 0);
    bool IsBearishCandle(int shift = 0);
    bool IsBullishEngulfing(int shift = 0);
    bool IsBearishEngulfing(int shift = 0);
    bool IsBullishPinbar(int shift = 0);
    bool IsBearishPinbar(int shift = 0);
    bool IsDoji(int shift = 0);
};

//+------------------------------------------------------------------+
//| Khởi tạo bộ nhớ đệm indicator cache (giờ là phương thức của lớp) |
//+------------------------------------------------------------------+
bool CIndicatorUtils::InitializeGlobalIndicatorCache(bool forceRefresh=false) {
    LogMessage("Khởi tạo bộ nhớ đệm indicator cache..."); // Sử dụng LogMessage của lớp
    
    // Kích thước m_IndicatorHandles đã cố định là 1 trong khai báo lớp

    // Khởi tạo các indicator handle trong struct IndicatorHandles
    if (m_IndicatorHandles[0].atrHandle == INVALID_HANDLE || forceRefresh) {
        m_IndicatorHandles[0].atrHandle = iATR(m_Symbol, m_Timeframe, 14); // Sử dụng m_Symbol, m_Timeframe
    }
    
    if (m_IndicatorHandles[0].maHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].maHandle = iMA(m_Symbol, m_Timeframe, 50, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    if (m_IndicatorHandles[0].rsiHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].rsiHandle = iRSI(m_Symbol, m_Timeframe, 14, PRICE_CLOSE);
    }
    
    if (m_IndicatorHandles[0].stochHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].stochHandle = iStochastic(m_Symbol, m_Timeframe, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    }
    
    if (m_IndicatorHandles[0].bollingerHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].bollingerHandle = iBands(m_Symbol, m_Timeframe, 20, 2, 0, PRICE_CLOSE);
    }
    
    if (m_IndicatorHandles[0].adxHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].adxHandle = iADX(m_Symbol, m_Timeframe, 14);
    }
    
    if (m_IndicatorHandles[0].macdHandle == INVALID_HANDLE || forceRefresh) { 
        m_IndicatorHandles[0].macdHandle = iMACD(m_Symbol, m_Timeframe, 12, 26, 9, PRICE_CLOSE);
    }

    // Kiểm tra tất cả các handle đã được khởi tạo thành công chưa
    if (m_IndicatorHandles[0].atrHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].maHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].rsiHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].stochHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].bollingerHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].adxHandle == INVALID_HANDLE ||
        m_IndicatorHandles[0].macdHandle == INVALID_HANDLE) {
        LogMessage("Lỗi: Không thể khởi tạo một hoặc nhiều indicator handles trong InitializeGlobalIndicatorCache.");
        return false;
    }
    
    LogMessage("Bộ nhớ đệm indicator cache đã được khởi tạo thành công.");
    return true;
}

// Commented out InitializeIndicators function removed as its logic is integrated into CIndicatorUtils.

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CIndicatorUtils::CIndicatorUtils() 
{
    m_IsInitialized = false;
    m_UseCache = true;
    m_VerboseLogging = false;
    m_LastUpdateTime = 0;
    m_MACount = 0;
    
    // Khởi tạo mảng handle với giá trị INVALID_HANDLE
    for(int i = 0; i < 10; i++) {
        m_MA_Handles[i] = INVALID_HANDLE;
        m_HTF_MA_Handles[i] = INVALID_HANDLE;
        m_MAPeriods[i] = 0;
    }
    
    m_ADX_Handle = INVALID_HANDLE;
    m_RSI_Handle = INVALID_HANDLE;
    m_ATR_Handle = INVALID_HANDLE;
    m_Volume_Handle = INVALID_HANDLE;
    m_MACD_Handle = INVALID_HANDLE;
    m_BB_Handle = INVALID_HANDLE;
    
    m_HTF_ADX_Handle = INVALID_HANDLE;
    m_HTF_RSI_Handle = INVALID_HANDLE;
    m_HTF_ATR_Handle = INVALID_HANDLE;
    
    // Reset cache
    ArrayInitialize(m_CachedValues, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CIndicatorUtils::~CIndicatorUtils() 
{
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Khởi tạo tất cả các indicator                                    |
//+------------------------------------------------------------------+
bool CIndicatorUtils::Initialize(
    string symbol,
    ENUM_TIMEFRAMES mainTimeframe, 
    ENUM_TIMEFRAMES higherTimeframe=PERIOD_H4, 
    bool useCache=true,
    bool verboseLogging=false,
    bool forceRefreshCache=false // Thêm tham số mới
) {
    // Lưu thông số
    m_Symbol = symbol;
    m_Timeframe = mainTimeframe;
    m_HigherTF = higherTimeframe;
    m_UseCache = useCache;
    m_VerboseLogging = verboseLogging;
    m_IsInitialized = false;
    
    // Reset trạng thái
    m_MACount = 0;
    
    // Khởi tạo các chỉ báo cơ bản
    m_ADX_Handle = iADX(m_Symbol, m_Timeframe, 14);
    m_RSI_Handle = iRSI(m_Symbol, m_Timeframe, 14, PRICE_CLOSE);
    m_ATR_Handle = iATR(m_Symbol, m_Timeframe, 14);
    m_Volume_Handle = iVolume(m_Symbol, m_Timeframe, 0);
    m_MACD_Handle = iMACD(m_Symbol, m_Timeframe, 12, 26, 9, PRICE_CLOSE);
    m_BB_Handle = iBands(m_Symbol, m_Timeframe, 20, 2.0, 0, PRICE_CLOSE);
    
    // Khởi tạo chỉ báo cho timeframe cao hơn
    m_HTF_ADX_Handle = iADX(m_Symbol, m_HigherTF, 14);
    m_HTF_RSI_Handle = iRSI(m_Symbol, m_HigherTF, 14, PRICE_CLOSE);
    m_HTF_ATR_Handle = iATR(m_Symbol, m_HigherTF, 14);
    
    // Kiểm tra xem tất cả các handle có hợp lệ không
    bool allHandlesValid = (m_ADX_Handle != INVALID_HANDLE && 
                          m_RSI_Handle != INVALID_HANDLE && 
                          m_ATR_Handle != INVALID_HANDLE && 
                          m_Volume_Handle != INVALID_HANDLE &&
                          m_MACD_Handle != INVALID_HANDLE &&
                          m_BB_Handle != INVALID_HANDLE &&
                          m_HTF_ADX_Handle != INVALID_HANDLE &&
                          m_HTF_RSI_Handle != INVALID_HANDLE &&
                          m_HTF_ATR_Handle != INVALID_HANDLE);
    
    if (!allHandlesValid) {
        LogMessage("LỖI: Không thể khởi tạo tất cả các handle chỉ báo");
        Deinitialize(); // Dọn dẹp các handle đã tạo
        return false;
    }
    
    // Thiết lập trạng thái đã khởi tạo
    m_IsInitialized = true;
    LogMessage("Đã khởi tạo thành công tất cả các chỉ báo cơ bản");
    
    // Cập nhật buffer ban đầu
    UpdatePriceBuffers(100);

    // Khởi tạo global indicator cache nếu cần
    if (!InitializeGlobalIndicatorCache(forceRefreshCache)) {
        LogMessage("LỖI: Không thể khởi tạo global indicator cache trong CIndicatorUtils::Initialize");
        Deinitialize(); // Dọn dẹp
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Giải phóng tất cả các handle                                     |
//+------------------------------------------------------------------+
void CIndicatorUtils::Deinitialize() 
{
    if (!m_IsInitialized) return;
    
    // Giải phóng handle MA
    for(int i = 0; i < m_MACount; i++) {
        if (m_MA_Handles[i] != INVALID_HANDLE) {
            IndicatorRelease((int)m_MA_Handles[i]);
            m_MA_Handles[i] = INVALID_HANDLE;
        }
        
        if (m_HTF_MA_Handles[i] != INVALID_HANDLE) {
            IndicatorRelease((int)m_HTF_MA_Handles[i]);
            m_HTF_MA_Handles[i] = INVALID_HANDLE;
        }
    }
    
    // Giải phóng các handle khác
    if (m_ADX_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_ADX_Handle);
        m_ADX_Handle = INVALID_HANDLE;
    }
    
    if (m_RSI_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_RSI_Handle);
        m_RSI_Handle = INVALID_HANDLE;
    }
    
    if (m_ATR_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_ATR_Handle);
        m_ATR_Handle = INVALID_HANDLE;
    }
    
    if (m_Volume_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_Volume_Handle);
        m_Volume_Handle = INVALID_HANDLE;
    }
    
    if (m_MACD_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_MACD_Handle);
        m_MACD_Handle = INVALID_HANDLE;
    }
    
    if (m_BB_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_BB_Handle);
        m_BB_Handle = INVALID_HANDLE;
    }
    
    // Giải phóng handle timeframe cao hơn
    if (m_HTF_ADX_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_HTF_ADX_Handle);
        m_HTF_ADX_Handle = INVALID_HANDLE;
    }
    
    if (m_HTF_RSI_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_HTF_RSI_Handle);
        m_HTF_RSI_Handle = INVALID_HANDLE;
    }
    
    if (m_HTF_ATR_Handle != INVALID_HANDLE) {
        IndicatorRelease((int)m_HTF_ATR_Handle);
        m_HTF_ATR_Handle = INVALID_HANDLE;
    }

    // Giải phóng các handles trong m_IndicatorHandles (thường được khởi tạo bởi InitializeGlobalIndicatorCache)
    if (m_IndicatorHandles[0].atrHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].atrHandle); m_IndicatorHandles[0].atrHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].maHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].maHandle); m_IndicatorHandles[0].maHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].rsiHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].rsiHandle); m_IndicatorHandles[0].rsiHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].stochHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].stochHandle); m_IndicatorHandles[0].stochHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].bollingerHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].bollingerHandle); m_IndicatorHandles[0].bollingerHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].adxHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].adxHandle); m_IndicatorHandles[0].adxHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].macdHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].macdHandle); m_IndicatorHandles[0].macdHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].volumeHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].volumeHandle); m_IndicatorHandles[0].volumeHandle = INVALID_HANDLE; }
    if (m_IndicatorHandles[0].ichimokuHandle != INVALID_HANDLE) { IndicatorRelease(m_IndicatorHandles[0].ichimokuHandle); m_IndicatorHandles[0].ichimokuHandle = INVALID_HANDLE; }
    
    m_IsInitialized = false;
    LogMessage("Đã giải phóng tất cả các handle chỉ báo");
}

//+------------------------------------------------------------------+
//| Đăng ký một MA mới (thường là EMA)                               |
//+------------------------------------------------------------------+
bool CIndicatorUtils::RegisterMA(int period, ENUM_MA_METHOD maMethod, ENUM_APPLIED_PRICE appliedPrice) {
    // Kiểm tra xem đã khởi tạo chưa
    if (!m_IsInitialized) {
        LogMessage("LỖI: Không thể đăng ký MA - chưa khởi tạo");
        return false;
    }
    
    // Kiểm tra xem đã đầy chưa
    if (m_MACount >= 10) {
        LogMessage("LỖI: Không thể đăng ký thêm MA - đã đạt giới hạn 10");
        return false;
    }
    
    // Kiểm tra xem MA này đã được đăng ký chưa
    for(int i = 0; i < m_MACount; i++) {
        if (m_MAPeriods[i] == period) {
            LogMessage("CẢNH BÁO: MA chu kỳ " + IntegerToString(period) + " đã được đăng ký trước đó");
            return true; // Đã đăng ký rồi
        }
    }
    
    // Khởi tạo MA mới
    long maHandle = iMA(m_Symbol, m_Timeframe, period, 0, maMethod, appliedPrice);
    long htfMaHandle = iMA(m_Symbol, m_HigherTF, period, 0, maMethod, appliedPrice);
    
    if (maHandle == INVALID_HANDLE || htfMaHandle == INVALID_HANDLE) {
        LogMessage("LỖI: Không thể khởi tạo MA chu kỳ " + IntegerToString(period));
        
        // Giải phóng handle nếu một trong hai thành công nhưng cái còn lại thất bại
        if (maHandle != INVALID_HANDLE) IndicatorRelease((int)maHandle);
        if (htfMaHandle != INVALID_HANDLE) IndicatorRelease((int)htfMaHandle);
        
        return false;
    }
    
    // Lưu thông tin
    m_MAPeriods[m_MACount] = period;
    m_MA_Handles[m_MACount] = maHandle;
    m_HTF_MA_Handles[m_MACount] = htfMaHandle;
    m_MACount++;
    
    LogMessage("Đã đăng ký thành công MA chu kỳ " + IntegerToString(period));
    return true;
}

//+------------------------------------------------------------------+
//| Cập nhật buffer giá                                              |
//+------------------------------------------------------------------+
bool CIndicatorUtils::UpdatePriceBuffers(int bars=100) {
    // Set up các mảng dữ liệu
    ArraySetAsSeries(m_HighBuffer, true);
    ArraySetAsSeries(m_LowBuffer, true);
    ArraySetAsSeries(m_CloseBuffer, true);
    ArraySetAsSeries(m_VolumeBuffer, true);
    
    // Copy dữ liệu giá
    bool success = true;
    
    if (CopyHigh(m_Symbol, m_Timeframe, 0, bars, m_HighBuffer) < bars) {
        LogMessage("LỖI: Không thể copy dữ liệu High");
        success = false;
    }
    
    if (CopyLow(m_Symbol, m_Timeframe, 0, bars, m_LowBuffer) < bars) {
        LogMessage("LỖI: Không thể copy dữ liệu Low");
        success = false;
    }
    
    if (CopyClose(m_Symbol, m_Timeframe, 0, bars, m_CloseBuffer) < bars) {
        LogMessage("LỖI: Không thể copy dữ liệu Close");
        success = false;
    }
    
    // Volume có thể không tồn tại cho một số cặp tiền
    long volumeData[];
    CopyTickVolume(m_Symbol, m_Timeframe, 0, bars, volumeData);
    
    // Chuyển đổi từ long[] sang double[]
    ArrayResize(m_VolumeBuffer, ArraySize(volumeData));
    for(int i = 0; i < ArraySize(volumeData); i++) {
        m_VolumeBuffer[i] = (double)volumeData[i];
    }
    
    // Cập nhật thời gian
    m_LastUpdateTime = TimeCurrent();
    
    return success;
}

//+------------------------------------------------------------------+
//| Lấy giá trị MA                                                   |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetMA(int period, int shift=0) {
    // Kiểm tra xem đã khởi tạo chưa
    if (!m_IsInitialized) {
        LogMessage("LỖI: Không thể lấy giá trị MA - chưa khởi tạo");
        return EMPTY_VALUE;
    }
    
    // Tìm MA trong danh sách đã đăng ký
    int indexFound = -1;
    for(int i = 0; i < m_MACount; i++) {
        if (m_MAPeriods[i] == period) {
            indexFound = i;
            break;
        }
    }
    
    if (indexFound == -1) {
        LogMessage("LỖI: Không tìm thấy MA chu kỳ " + IntegerToString(period) + " - cần đăng ký trước");
        return EMPTY_VALUE;
    }
    
    // Lấy giá trị từ handle
    double value[];
    if (CopyBuffer((int)m_MA_Handles[indexFound], 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu từ handle MA " + IntegerToString(period));
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị MA trên timeframe cao hơn                            |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetMAOnHigherTF(int period, int shift=0) {
    // Kiểm tra xem đã khởi tạo chưa
    if (!m_IsInitialized) {
        LogMessage("LỖI: Không thể lấy giá trị MA HTF - chưa khởi tạo");
        return EMPTY_VALUE;
    }
    
    // Tìm MA trong danh sách đã đăng ký
    int indexFound = -1;
    for(int i = 0; i < m_MACount; i++) {
        if (m_MAPeriods[i] == period) {
            indexFound = i;
            break;
        }
    }
    
    if (indexFound == -1) {
        LogMessage("LỖI: Không tìm thấy MA HTF chu kỳ " + IntegerToString(period) + " - cần đăng ký trước");
        return EMPTY_VALUE;
    }
    
    // Lấy giá trị từ handle
    double value[];
    if (CopyBuffer((int)m_HTF_MA_Handles[indexFound], 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu từ handle MA HTF " + IntegerToString(period));
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị ADX                                                  |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetADX(int shift=0) {
    if (!m_IsInitialized || m_ADX_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_ADX_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu ADX");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị +DI                                                  |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetADXPlus(int shift=0) {
    if (!m_IsInitialized || m_ADX_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_ADX_Handle, 1, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu +DI");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị -DI                                                  |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetADXMinus(int shift=0) {
    if (!m_IsInitialized || m_ADX_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_ADX_Handle, 2, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu -DI");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị ADX trên timeframe cao hơn                           |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetADXOnHigherTF(int shift=0) {
    if (!m_IsInitialized || m_HTF_ADX_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_HTF_ADX_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu từ handle ADX HTF");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị RSI                                                  |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetRSI(int shift=0) {
    if (!m_IsInitialized || m_RSI_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_RSI_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu RSI");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị RSI trên timeframe cao hơn                           |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetRSIOnHigherTF(int shift=0) {
    if (!m_IsInitialized || m_HTF_RSI_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_HTF_RSI_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu từ handle RSI HTF");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị ATR                                                  |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetATR(int shift=0) {
    if (!m_IsInitialized || m_ATR_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_ATR_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu ATR");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị ATR trên timeframe cao hơn                           |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetATROnHigherTF(int shift=0) {
    if (!m_IsInitialized || m_HTF_ATR_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_HTF_ATR_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu từ handle ATR HTF");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy tỷ lệ ATR hiện tại so với trung bình                        |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetATRRatio(int lookbackPeriods=10) {
    double currentATR = GetATR(0);
    if (currentATR == EMPTY_VALUE) return EMPTY_VALUE;
    
    // Tính trung bình ATR
    double sumATR = 0.0;
    int validCount = 0;
    
    for (int i = 1; i <= lookbackPeriods; i++) {
        double atr = GetATR(i);
        if (atr != EMPTY_VALUE) {
            sumATR += atr;
            validCount++;
        }
    }
    
    if (validCount == 0 || sumATR == 0) return EMPTY_VALUE;
    double avgATR = sumATR / validCount;
    
    return currentATR / avgATR;
}

//+------------------------------------------------------------------+
//| Lấy giá trị MACD Signal                                         |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetMACDSignal(int shift=0) {
    if (!m_IsInitialized || m_MACD_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_MACD_Handle, 1, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu MACD Signal");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị MACD Histogram                                      |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetMACDHistogram(int shift=0) {
    if (!m_IsInitialized || m_MACD_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    // MACD Histogram = MACD Main - MACD Signal
    double macdMain = GetMACDMain(shift);
    double macdSignal = GetMACDSignal(shift);
    
    if (macdMain == EMPTY_VALUE || macdSignal == EMPTY_VALUE) {
        return EMPTY_VALUE;
    }
    
    return macdMain - macdSignal;
}

//+------------------------------------------------------------------+
//| Lấy giá trị Bollinger Band Upper                                |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetBBUpper(int shift=0) {
    if (!m_IsInitialized || m_BB_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_BB_Handle, 1, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu BB Upper");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị Bollinger Band Middle                               |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetBBMiddle(int shift=0) {
    if (!m_IsInitialized || m_BB_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_BB_Handle, 0, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu BB Middle");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy giá trị Bollinger Band Lower                                |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetBBLower(int shift=0) {
    if (!m_IsInitialized || m_BB_Handle == INVALID_HANDLE) return EMPTY_VALUE;
    
    double value[];
    if (CopyBuffer((int)m_BB_Handle, 2, shift, 1, value) <= 0) {
        LogMessage("LỖI: Không thể copy dữ liệu BB Lower");
        return EMPTY_VALUE;
    }
    
    return value[0];
}

//+------------------------------------------------------------------+
//| Lấy độ rộng của Bollinger Bands                                 |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetBBWidth(int shift=0) {
    double upper = GetBBUpper(shift);
    double lower = GetBBLower(shift);
    double middle = GetBBMiddle(shift);
    
    if (upper == EMPTY_VALUE || lower == EMPTY_VALUE || middle == EMPTY_VALUE || middle == 0) {
        return EMPTY_VALUE;
    }
    
    return (upper - lower) / middle;
}

//+------------------------------------------------------------------+
//| Lấy độ dốc của MA trên TF cao hơn                                |
//+------------------------------------------------------------------+
double CIndicatorUtils::CheckHTF_MASlope(int period1, int period2, int period3, int period4) 
{
    double ma1 = GetMAOnHigherTF(period1, 0);
    double ma2 = GetMAOnHigherTF(period2, 0);
    double ma3 = GetMAOnHigherTF(period3, 0);
    double ma4 = GetMAOnHigherTF(period4, 0);
    
    if (ma1 == EMPTY_VALUE || ma2 == EMPTY_VALUE || ma3 == EMPTY_VALUE || ma4 == EMPTY_VALUE) {
        return EMPTY_VALUE;
    }
    
    return (ma4 - ma1) / (period4 - period1);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem giá hiện tại có nằm trên MA không                  |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsPriceAboveMA(int period, int shift) 
{
    if (!m_IsInitialized) return false;
    
    double ma = GetMA(period, shift);
    if (ma == EMPTY_VALUE) return false;
    
    double close = m_CloseBuffer[shift];
    return close > ma;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem giá hiện tại có nằm dưới MA không                  |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsPriceBelowMA(int period, int shift) 
{
    if (!m_IsInitialized) return false;
    
    double ma = GetMA(period, shift);
    if (ma == EMPTY_VALUE) return false;
    
    double close = m_CloseBuffer[shift];
    return close < ma;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem biến động có cao không                             |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsVolatilityHigh(double threshold) 
{
    double atrRatio = GetATRRatio(10); // Sử dụng lookback mặc định 10 chu kỳ
    if (atrRatio == EMPTY_VALUE) return false;
    
    return atrRatio > threshold;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem biến động có thấp không                            |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsVolatilityLow(double threshold) 
{
    double atrRatio = GetATRRatio(10); // Sử dụng lookback mặc định 10 chu kỳ
    if (atrRatio == EMPTY_VALUE) return false;
    
    return atrRatio < threshold;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem thị trường có đi ngang không                       |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsMarketRangebound(int lookback) 
{
    // Kiểm tra bằng BB Width
    double bbWidth = GetBBWidth(0);
    
    // Tính trung bình BB Width thay vì dùng GetAverageBBWidth
    double sumBBWidth = 0.0;
    int validCount = 0;
    
    for (int i = 1; i <= lookback; i++) {
        double bbw = GetBBWidth(i);
        if (bbw != EMPTY_VALUE) {
            sumBBWidth += bbw;
            validCount++;
        }
    }
    
    double avgBBWidth = (validCount > 0) ? sumBBWidth / validCount : EMPTY_VALUE;
    
    if (bbWidth == EMPTY_VALUE || avgBBWidth == EMPTY_VALUE) return false;
    
    // Nếu BB width nhỏ hơn 80% trung bình => thị trường đi ngang
    return bbWidth < (avgBBWidth * 0.8);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem nến có tăng không                                  |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBullishCandle(int shift) 
{
    if (!m_IsInitialized) return false;
    
    if (shift >= ArraySize(m_CloseBuffer) || shift >= ArraySize(m_HighBuffer) || 
        shift >= ArraySize(m_LowBuffer)) {
        return false;
    }
    
    // Lấy open từ close trước đó
    double open = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double close = m_CloseBuffer[shift];
    
    return close > open;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem nến có giảm không                                  |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBearishCandle(int shift) 
{
    if (!m_IsInitialized) return false;
    
    if (shift >= ArraySize(m_CloseBuffer) || shift >= ArraySize(m_HighBuffer) || 
        shift >= ArraySize(m_LowBuffer)) {
        return false;
    }
    
    // Lấy open từ close trước đó
    double open = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double close = m_CloseBuffer[shift];
    
    return close < open;
}

//+------------------------------------------------------------------+
//| Kiểm tra mô hình nến Bullish Engulfing                           |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBullishEngulfing(int shift) 
{
    if (!m_IsInitialized || ArraySize(m_CloseBuffer) <= shift + 1) return false;
    
    double currOpen = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double currClose = m_CloseBuffer[shift];
    double prevOpen = (shift + 1 < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 2] : 0;
    double prevClose = m_CloseBuffer[shift + 1];
    
    // Điều kiện Bullish Engulfing:
    // 1. Nến hiện tại tăng (close > open)
    // 2. Nến trước đó giảm (close < open)
    // 3. Nến hiện tại bao trùm nến trước đó (open <= prevClose AND close >= prevOpen)
    
    bool currBullish = currClose > currOpen;
    bool prevBearish = prevClose < prevOpen;
    bool isEngulfing = currOpen <= prevClose && currClose >= prevOpen;
    
    return currBullish && prevBearish && isEngulfing;
}

//+------------------------------------------------------------------+
//| Kiểm tra mô hình nến Bearish Engulfing                           |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBearishEngulfing(int shift) 
{
    if (!m_IsInitialized || ArraySize(m_CloseBuffer) <= shift + 1) return false;
    
    double currOpen = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double currClose = m_CloseBuffer[shift];
    double prevOpen = (shift + 1 < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 2] : 0;
    double prevClose = m_CloseBuffer[shift + 1];
    
    // Điều kiện Bearish Engulfing:
    // 1. Nến hiện tại giảm (close < open)
    // 2. Nến trước đó tăng (close > open)
    // 3. Nến hiện tại bao trùm nến trước đó (open >= prevClose AND close <= prevOpen)
    
    bool currBearish = currClose < currOpen;
    bool prevBullish = prevClose > prevOpen;
    bool isEngulfing = currOpen >= prevClose && currClose <= prevOpen;
    
    return currBearish && prevBullish && isEngulfing;
}

//+------------------------------------------------------------------+
//| Kiểm tra mô hình nến Bullish Pinbar                             |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBullishPinbar(int shift) 
{
    if (!m_IsInitialized) return false;
    
    if (shift >= ArraySize(m_CloseBuffer) || shift >= ArraySize(m_HighBuffer) || 
        shift >= ArraySize(m_LowBuffer)) {
        return false;
    }
    
    // Lấy dữ liệu
    double open = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double close = m_CloseBuffer[shift];
    double high = m_HighBuffer[shift];
    double low = m_LowBuffer[shift];
    
    // Tính toán thân nến và đuôi
    double body = MathAbs(close - open);
    double upperWick = high - MathMax(close, open);
    double lowerWick = MathMin(close, open) - low;
    double totalLength = high - low;
    
    // Điều kiện Bullish Pinbar:
    // 1. Đuôi dưới dài (ít nhất 2/3 tổng chiều dài)
    // 2. Thân nến nhỏ (không quá 1/3 tổng chiều dài)
    // 3. Đuôi trên ngắn
    
    if (totalLength == 0) return false; // Tránh chia cho 0
    
    bool hasLongLowerWick = lowerWick > 0.66 * totalLength;
    bool hasShortBody = body < 0.33 * totalLength;
    bool hasShortUpperWick = upperWick < 0.25 * totalLength;
    
    return hasLongLowerWick && hasShortBody && hasShortUpperWick;
}

//+------------------------------------------------------------------+
//| Kiểm tra mô hình nến Bearish Pinbar                             |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsBearishPinbar(int shift) 
{
    if (!m_IsInitialized) return false;
    
    if (shift >= ArraySize(m_CloseBuffer) || shift >= ArraySize(m_HighBuffer) || 
        shift >= ArraySize(m_LowBuffer)) {
        return false;
    }
    
    // Lấy dữ liệu
    double open = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double close = m_CloseBuffer[shift];
    double high = m_HighBuffer[shift];
    double low = m_LowBuffer[shift];
    
    // Tính toán thân nến và đuôi
    double body = MathAbs(close - open);
    double upperWick = high - MathMax(close, open);
    double lowerWick = MathMin(close, open) - low;
    double totalLength = high - low;
    
    // Điều kiện Bearish Pinbar:
    // 1. Đuôi trên dài (ít nhất 2/3 tổng chiều dài)
    // 2. Thân nến nhỏ (không quá 1/3 tổng chiều dài)
    // 3. Đuôi dưới ngắn
    
    if (totalLength == 0) return false; // Tránh chia cho 0
    
    bool hasLongUpperWick = upperWick > 0.66 * totalLength;
    bool hasShortBody = body < 0.33 * totalLength;
    bool hasShortLowerWick = lowerWick < 0.25 * totalLength;
    
    return hasLongUpperWick && hasShortBody && hasShortLowerWick;
}

//+------------------------------------------------------------------+
//| Kiểm tra mô hình nến Doji                                        |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsDoji(int shift) 
{
    if (!m_IsInitialized) return false;
    
    if (shift >= ArraySize(m_CloseBuffer) || shift >= ArraySize(m_HighBuffer) || 
        shift >= ArraySize(m_LowBuffer)) {
        return false;
    }
    
    // Lấy dữ liệu
    double open = (shift < ArraySize(m_CloseBuffer) - 1) ? m_CloseBuffer[shift + 1] : 0;
    double close = m_CloseBuffer[shift];
    double high = m_HighBuffer[shift];
    double low = m_LowBuffer[shift];
    
    // Tính toán thân nến và tổng chiều dài
    double body = MathAbs(close - open);
    double totalLength = high - low;
    
    // Điều kiện Doji:
    // Thân nến rất nhỏ (không quá 5% tổng chiều dài)
    
    if (totalLength == 0) return false; // Tránh chia cho 0
    
    return body <= 0.05 * totalLength;
}

//+------------------------------------------------------------------+
//| Ghi log message                                                  |
//+------------------------------------------------------------------+
void CIndicatorUtils::LogMessage(string message) 
{
    if (!m_VerboseLogging) return;
    
    Print("[IndicatorUtils] " + message);
}

//+------------------------------------------------------------------+
//| Lấy giá trị Volume                                              |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetVolume(int shift=0) {
    if (!m_IsInitialized) return EMPTY_VALUE;
    
    // Cố gắng lấy từ buffer internal trước
    if (shift < ArraySize(m_VolumeBuffer)) {
        return m_VolumeBuffer[shift];
    }
    
    // Nếu không có trong buffer hoặc handle không hợp lệ, lấy trực tiếp
    long volume = 0;
    if (!HistorySelect(TimeCurrent() - shift * PeriodSeconds(m_Timeframe), TimeCurrent())) {
        return EMPTY_VALUE;
    }
    
    volume = HistoryDealsTotal();
    return (double)volume;
}

//+------------------------------------------------------------------+
//| Lấy Volume trung bình                                           |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetAverageVolume(int periods) 
{
    if (!m_IsInitialized) return EMPTY_VALUE;
    
    double sum = 0;
    int count = 0;
    
    for (int i = 0; i < periods; i++) {
        double vol = GetVolume(i);
        if (vol != EMPTY_VALUE && vol > 0) {
            sum += vol;
            count++;
        }
    }
    
    if (count == 0) return EMPTY_VALUE;
    
    return sum / count;
}

//+------------------------------------------------------------------+
//| Lấy tỷ lệ Volume hiện tại so với trung bình                     |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetVolumeRatio() 
{
    double currentVolume = GetVolume(0);
    double avgVolume = GetAverageVolume(20);
    
    if (currentVolume == EMPTY_VALUE || avgVolume == EMPTY_VALUE || avgVolume == 0) {
        return EMPTY_VALUE;
    }
    
    return currentVolume / avgVolume;
}

//+------------------------------------------------------------------+
//| Lấy Spread hiện tại                                             |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetCurrentSpread() 
{
    return SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(m_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Lấy Spread trung bình                                           |
//+------------------------------------------------------------------+
double CIndicatorUtils::GetAverageSpread(int periods) 
{
    // Không có handle riêng cho spread, phải tính theo cách khác
    double sum = 0;
    for (int i = 0; i < periods; i++) {
        sum += (double)SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD);
    }
    
    return (sum / periods) * SymbolInfoDouble(m_Symbol, SYMBOL_POINT);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem indicator1 có cắt lên trên indicator2 không        |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsCrossUp(int indicator1, int indicator2, int shift) 
{
    // Lấy giá trị cho shift hiện tại và trước đó
    double ind1Current = GetMA(indicator1, shift);
    double ind2Current = GetMA(indicator2, shift);
    double ind1Previous = GetMA(indicator1, shift + 1);
    double ind2Previous = GetMA(indicator2, shift + 1);
    
    // Kiểm tra giá trị hợp lệ
    if (ind1Current == EMPTY_VALUE || ind2Current == EMPTY_VALUE || 
        ind1Previous == EMPTY_VALUE || ind2Previous == EMPTY_VALUE) {
        return false;
    }
    
    // Kiểm tra cắt lên
    return (ind1Previous < ind2Previous) && (ind1Current >= ind2Current);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem indicator1 có cắt xuống dưới indicator2 không      |
//+------------------------------------------------------------------+
bool CIndicatorUtils::IsCrossDown(int indicator1, int indicator2, int shift) 
{
    // Lấy giá trị cho shift hiện tại và trước đó
    double ind1Current = GetMA(indicator1, shift);
    double ind2Current = GetMA(indicator2, shift);
    double ind1Previous = GetMA(indicator1, shift + 1);
    double ind2Previous = GetMA(indicator2, shift + 1);
    
    // Kiểm tra giá trị hợp lệ
    if (ind1Current == EMPTY_VALUE || ind2Current == EMPTY_VALUE || 
        ind1Previous == EMPTY_VALUE || ind2Previous == EMPTY_VALUE) {
        return false;
    }
    
    // Kiểm tra cắt xuống
    return (ind1Previous > ind2Previous) && (ind1Current <= ind2Current);
}

} // Kết thúc namespace

#endif // INDICATORUTILS_MQH_