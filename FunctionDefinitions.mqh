//+------------------------------------------------------------------+
//|   Function Definitions for APEX PULLBACK EA v14.0                |
//|   Định nghĩa các hàm cần thiết để giải quyết lỗi biên dịch       |
//+------------------------------------------------------------------+

#ifndef _FUNCTION_DEFINITIONS_MQH_
#define _FUNCTION_DEFINITIONS_MQH_

// Import namespace definitions để sử dụng các hằng số chung
#include "Namespace.mqh"
#include "CommonStructs.mqh"  // Sử dụng các struct từ CommonStructs.mqh
#include "Constants.mqh"      // Sử dụng các hằng số đã được định nghĩa

// Định nghĩa hằng số log level (không trùng với Constants.mqh)
#define LOG_INFO     1
#define LOG_WARNING  2
#define LOG_ERROR    3
#define LOG_DEBUG    4

// Các biến global (sẽ được chuyển vào EAContext hoặc các manager)
// bool g_EnableDetailedLogs = false; // Đã chuyển vào Logger hoặc EAContext

// Khai báo forward cho các biến toàn cục (sẽ được định nghĩa đầy đủ trong EA chính)
// double g_AverageATR = 0; // Sẽ được quản lý bởi CIndicatorUtils hoặc MarketProfile thông qua g_EAContext
// double g_CurrentDrawdownPct = 0; // Sẽ được quản lý bởi PerformanceTracker hoặc RiskManager thông qua g_EAContext

// Forward declaration cho MarketProfile và dữ liệu của nó
// CMarketProfile* g_MarketProfile = NULL; // Sẽ được truy cập qua g_EAContext.MarketProfile
// ApexPullback::MarketProfileData g_MarketProfileData; // Sẽ được quản lý trong MarketProfile hoặc EAContext
// ApexPullback::MarketProfileData g_CurrentProfileData; // Sẽ được quản lý trong EAContext.CurrentProfileData

// Indicator parameters - khai báo biến extern không khởi tạo giá trị (theo quy tắc MQL5)
extern int EMA_Fast;          // Fast EMA period
extern int EMA_Medium;      // Medium EMA period
extern int EMA_Slow;        // Slow EMA period
extern int EMA_200;        // EMA 200 period
extern int ATR_Period;      // ATR period for volatility measurement
extern double RiskPercent; // Default risk percent per trade
extern double StopLossMultiplier; // Default SL multiplier
extern double TakeProfitMultiplier; // Default TP multiplier

// Trading settings
extern double MinPullbackPercent;  // Minimum pullback percent
extern double MaxPullbackPercent;  // Maximum pullback percent
extern double StopLoss_ATR;        // ATR multiplier for stop loss
extern double TakeProfit_RR;       // Risk:Reward ratio for take profit
extern int MaxTradesPerDay;         // Maximum trades per day
extern int MaxPositions;            // Maximum positions
extern int TrailingMode;            // Trailing mode

// Khởi tạo giá trị mặc định cho các biến extern
void InitializeDefaultValues() {
    EMA_Fast = 8;
    EMA_Medium = 21;
    EMA_Slow = 50;
    EMA_200 = 200;
    ATR_Period = 14;
    RiskPercent = 1.0;
    StopLossMultiplier = 1.0;
    TakeProfitMultiplier = 2.0;
    
    MinPullbackPercent = 30.0;
    MaxPullbackPercent = 70.0;
    StopLoss_ATR = 1.5;
    TakeProfit_RR = 2.0;
    MaxTradesPerDay = 5;
    MaxPositions = 1;
    TrailingMode = 0;
}

// Định nghĩa lớp CException để xử lý ngoại lệ
class CException {
private:
    string m_Description;

public:
    // Constructor
    CException(string description) {
        m_Description = description;
    }
    
    // Destructor
    ~CException() {
    }
    
    // Trả về mô tả lỗi
    string Description() const {
        return m_Description;
    }
    
    // Phương thức Delete để giải phóng bộ nhớ khi catch
    void Delete() {
        // Không cần làm gì vì C++ tự động giải phóng bộ nhớ
        // Phương thức này chỉ để tương thích với cách sử dụng
    }
};

// Định nghĩa class cho logging
class CLogger {
private:
    bool m_enableDebugLogs;
    bool m_enableInfoLogs;
    bool m_enableWarningLogs;
    bool m_enableErrorLogs;
    string m_logFilePath;
    int m_fileHandle;

public:
    // Constructor
    CLogger(bool enableDebug = true, bool enableInfo = true, bool enableWarning = true, bool enableError = true) {
        m_enableDebugLogs = enableDebug;
        m_enableInfoLogs = enableInfo;
        m_enableWarningLogs = enableWarning;
        m_enableErrorLogs = enableError;
        m_logFilePath = "Logs\\ApexPullback_" + Symbol() + "_" + (string)TimeTradeServer() + ".log";
        m_fileHandle = INVALID_HANDLE;
    }
    
    // Destructor
    ~CLogger() {
        if(m_fileHandle != INVALID_HANDLE) {
            FileClose(m_fileHandle);
        }
    }
    
    void LogDebug(string message) {
        if(m_enableDebugLogs) {
            string logMsg;
            string timeStr = TimeToString(TimeTradeServer(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
            logMsg = timeStr + " [DEBUG] ";
            logMsg = logMsg + message;
            Print(logMsg);
            WriteToLogFile(logMsg);
        }
    }
    
    void LogInfo(string message) {
        if(m_enableInfoLogs) {
            string logMsg;
            string timeStr = TimeToString(TimeTradeServer(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
            logMsg = timeStr + " [INFO] ";
            logMsg = logMsg + message;
            Print(logMsg);
            WriteToLogFile(logMsg);
        }
    }
    
    void LogWarning(string message) {
        if(m_enableWarningLogs) {
            string logMsg;
            string timeStr = TimeToString(TimeTradeServer(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
            logMsg = timeStr + " [WARNING] ";
            logMsg = logMsg + message;
            Print(logMsg);
            WriteToLogFile(logMsg);
        }
    }
    
    void LogError(string message) {
        if(m_enableErrorLogs) {
            string logMsg;
            string timeStr = TimeToString(TimeTradeServer(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
            logMsg = timeStr + " [ERROR] ";
            logMsg = logMsg + message;
            Print(logMsg);
            WriteToLogFile(logMsg);
        }
    }
    
    private:
    void WriteToLogFile(string message) {
        if(m_fileHandle == INVALID_HANDLE) {
            m_fileHandle = FileOpen(m_logFilePath, FILE_WRITE|FILE_ANSI|FILE_TXT);
            if(m_fileHandle == INVALID_HANDLE) return;
        }
        // Tránh dùng phép nối chuỗi trong FileWriteString
        string lineEnd = "\n";
        string fullMessage = message;
        fullMessage = fullMessage + lineEnd;
        FileWriteString(m_fileHandle, fullMessage);
        FileFlush(m_fileHandle);
    }
};

// Global Logger instance (sẽ được khởi tạo trong OnInit và truy cập qua g_EAContext.Logger)
// CLogger* g_Logger = NULL;

void GlobalLogError(string message) {
    if (ApexPullback::g_EAContext.Logger != NULL) {
        ApexPullback::g_EAContext.Logger.LogError(message);
    } else {
        Print("ERROR: " + message); // Fallback nếu logger chưa khởi tạo
    }
}

void GlobalLogWarning(string message) {
    if (ApexPullback::g_EAContext.Logger != NULL) {
        ApexPullback::g_EAContext.Logger.LogWarning(message);
    } else {
        Print("WARNING: " + message); // Fallback nếu logger chưa khởi tạo
    }
}

void GlobalLogDebug(string message) {
    if (ApexPullback::g_EAContext.Logger != NULL && ApexPullback::g_EAContext.Logger.IsVerboseLogging()) {
        ApexPullback::g_EAContext.Logger.LogDebug(message);
    } else {
        // Print("DEBUG: " + message); // Debug logs thường không cần fallback ra Print
    }
}

void GlobalLogInfo(string message) {
    if (ApexPullback::g_EAContext.Logger != NULL) {
        ApexPullback::g_EAContext.Logger.LogInfo(message);
    } else {
        Print("INFO: " + message); // Fallback nếu logger chưa khởi tạo
    }
}

// Các hàm được định nghĩa trong namespace của EA
namespace ApexPullback {
    
    // Hàm gửi cảnh báo
    void SendAlert(string message, int alertLevel = 1) { // Sử dụng 1 cho ALERT_LEVEL_NORMAL
        if (alertLevel == 2 || alertLevel == 3) { // 2 = IMPORTANT, 3 = CRITICAL
            Alert(message);
        }
    }
    
    // Hàm kiểm tra nến mới
    bool IsNewCandle() {
        static datetime lastTime = 0;
        datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
        if (lastTime == 0) {
            lastTime = currentTime;
            return false;
        }
        
        if (currentTime > lastTime) {
            lastTime = currentTime;
            return true;
        }
        return false;
    }

    // Định nghĩa các preset cho tham số EA - Phải đặt ở đầu file
    #define PRESET_TRENDING 0       // Preset cho thị trường xu hướng
    #define PRESET_RANGING 1        // Preset cho thị trường sideway
    #define PRESET_VOLATILE 2       // Preset cho thị trường biến động
    #define PRESET_CONSERVATIVE 3   // Preset bảo toàn vốn
    
    // Hàm kiểm tra phiên giao dịch
    bool IsAllowedTradingSession() {
        // Thực hiện kiểm tra phiên giao dịch
        // Logic mặc định: cho phép giao dịch trong giờ châu Âu và Mỹ
        datetime currentTime = TimeCurrent();
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        int hour = dt.hour;
        return (hour >= 7 && hour <= 20); // Thời gian GMT
    }
    
    // Hàm kiểm tra thời gian tin tức
    bool IsNewsImpactPeriod() {
        // Mặc định không có ảnh hưởng tin tức
        return false;
    }
    
    // Hàm quản lý cảnh báo
    void ManageAlerts() {
        // Mã đơn giản cho quản lý cảnh báo
    }
    
    // Hàm cập nhật dashboard
    void UpdateDashboard() {
        // Mã đơn giản để cập nhật dashboard
    }
    
    // Hàm tính toán ATR
    double GetATR(int period = 14, int shift = 0) {
        // Sử dụng indicator ATR
        double atrBuffer[];
        int handle = iATR(_Symbol, PERIOD_CURRENT, period);
        if (handle == INVALID_HANDLE) {
            return 0.0;
        }
        
        // Copy dữ liệu
        int copied = CopyBuffer(handle, 0, shift, 1, atrBuffer);
        
        // Đóng handle indicator
        IndicatorRelease(handle);
        
        if (copied <= 0) {
            return 0.0;
        }
        
        return atrBuffer[0];
    }
    
    // Hàm tính toán R-multiple tối ưu
    double GetOptimalRMultiple(double riskAmount) {
        // Mặc định trả về R-multiple 2.0
        return 2.0;
    }
    
    // Hàm lấy mức drawdown tối đa
    double GetMaximumDrawdown() {
        // Mặc định trả về 10%
        return 10.0;
    }
    
    // Hàm kiểm tra có tin tức quan trọng
    bool HasHighImpactNews(int lookAheadMinutes = 60) {
        // Mặc định trả về false
        return false;
    }
    
    // Hàm kiểm tra biến động cao bất thường
    bool IsExtremeVolatility() {
        // Mặc định trả về false
        return false;
    }
    
    // Hàm lưu cấu hình
    bool SaveConfiguration() {
        // Mã lưu cấu hình
        string configFile = "ApexPullback_" + _Symbol + ".cfg";
        int fileHandle = FileOpen(configFile, FILE_WRITE|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            string errMsg = "Không thể mở file cấu hình để ghi: ";
            errMsg = errMsg + configFile;
            GlobalLogError(errMsg); // Sử dụng hàm global
            return false;
        }
        
        // Sử dụng các biến toàn cục từ namespace hoặc input parameters
        int emaFast = EMA_Fast;
        int emaMedium = EMA_Medium;
        int emaSlow = EMA_Slow;
        int atrPeriod = ATR_Period;
        
        double minPullback = MinPullbackPercent;
        double maxPullback = MaxPullbackPercent;
        double riskPct = RiskPercent;
        double slAtr = StopLoss_ATR;
        double tpRR = TakeProfit_RR;
        
        int maxTrades = MaxTradesPerDay;
        int maxPos = MaxPositions;
        int trailMode = TrailingMode;
        
        // Ghi các thông số cấu hình
        FileWriteInteger(fileHandle, emaFast);
        FileWriteInteger(fileHandle, emaMedium);
        FileWriteInteger(fileHandle, emaSlow);
        FileWriteInteger(fileHandle, atrPeriod);
        
        FileWriteDouble(fileHandle, minPullback);
        FileWriteDouble(fileHandle, maxPullback);
        FileWriteDouble(fileHandle, riskPct);
        FileWriteDouble(fileHandle, slAtr);
        FileWriteDouble(fileHandle, tpRR);
        
        FileWriteInteger(fileHandle, maxTrades);
        FileWriteInteger(fileHandle, maxPos);
        FileWriteInteger(fileHandle, trailMode);
        
        FileClose(fileHandle);
        string infoMsg = "Đã lưu cấu hình vào file: ";
        infoMsg = infoMsg + configFile;
        GlobalLogInfo(infoMsg); // Sử dụng hàm global
        return true;
    }
    
    // Hàm nạp cấu hình
    bool LoadConfiguration() {
        string configFile = "ApexPullback_" + _Symbol + ".cfg";
        if (!FileIsExist(configFile, FILE_COMMON)) {
            // Tạo message riêng biệt tránh dùng phép nối chuỗi trong call hàm
            string warningMsg;
            warningMsg = "File cấu hình không tồn tại: ";
            warningMsg = warningMsg + configFile;
            
            // Sử dụng GlobalLogWarning thay vì gọi trực tiếp đến g_Logger để tránh lỗi
            GlobalLogWarning(warningMsg);
            return false;
        }
        
        int fileHandle = FileOpen(configFile, FILE_READ|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            string errMsg = "Không thể mở file cấu hình để đọc: ";
            errMsg = errMsg + configFile;
            GlobalLogError(errMsg); // Sử dụng hàm global
            return false;
        }
        
        // Đọc vào các biến tạm
        int emaFast = FileReadInteger(fileHandle);
        int emaMedium = FileReadInteger(fileHandle);
        int emaSlow = FileReadInteger(fileHandle);
        int atrPeriod = FileReadInteger(fileHandle);
        
        double minPullback = FileReadDouble(fileHandle);
        double maxPullback = FileReadDouble(fileHandle);
        double riskPct = FileReadDouble(fileHandle);
        double slAtr = FileReadDouble(fileHandle);
        double tpRR = FileReadDouble(fileHandle);
        
        int maxTrades = FileReadInteger(fileHandle);
        int maxPos = FileReadInteger(fileHandle);
        int trailMode = FileReadInteger(fileHandle);
        
        // Cập nhật các biến toàn cục
        if(emaFast > 0) EMA_Fast = emaFast;
        if(emaMedium > 0) EMA_Medium = emaMedium;
        if(emaSlow > 0) EMA_Slow = emaSlow;
        if(atrPeriod > 0) ATR_Period = atrPeriod;
        
        if(minPullback > 0) MinPullbackPercent = minPullback;
        if(maxPullback > 0) MaxPullbackPercent = maxPullback;
        if(riskPct > 0) RiskPercent = riskPct;
        if(slAtr > 0) StopLoss_ATR = slAtr;
        if(tpRR > 0) TakeProfit_RR = tpRR;
        
        if(maxTrades > 0) MaxTradesPerDay = maxTrades;
        if(maxPos > 0) MaxPositions = maxPos;
        TrailingMode = trailMode;
        
        FileClose(fileHandle);
        string infoMsg = "Đã nạp cấu hình từ file: ";
        infoMsg = infoMsg + configFile;
        GlobalLogInfo(infoMsg); // Sử dụng hàm global
        return true;
    }
    
    // Hàm ClearIndicatorCache() đã được loại bỏ.
    // Logic xóa cache indicator đã được chuyển vào CIndicatorUtils::Deinitialize() hoặc CIndicatorUtils::InitializeGlobalIndicatorCache(true).

    // Hàm ReleaseIndicatorHandles() đã được loại bỏ.
    // Logic giải phóng indicator handles đã được chuyển vào CIndicatorUtils::Deinitialize().
    
    // Hàm cập nhật dữ liệu thị trường
    bool UpdateMarketData() {
        // Cập nhật dữ liệu thị trường từ MarketProfile
        bool result = false;
        
// Logic cập nhật MarketProfile sẽ được thực hiện thông qua g_EAContext.MarketProfile
    // if(ApexPullback::g_EAContext.MarketProfile != NULL) {
    //     result = ApexPullback::g_EAContext.MarketProfile.Update();
    //     if(result) {
    //         // ApexPullback::g_EAContext.CurrentProfileData.CopyFrom(ApexPullback::g_EAContext.MarketProfile.GetLastProfile());
    //     }
    // } else {
    //     GlobalLogWarning("UpdateMarketData: MarketProfile chưa được khởi tạo.");
    // }
    result = true; // Tạm thời để true, cần logic thực tế
        return false;
    }
    
    // Hàm lấy mô tả lý do deinit
    string GetDeinitReasonText(int reason) {
        string text = "";
        switch(reason) {
            case REASON_PROGRAM: text = "Expert removed from chart"; break;
            case REASON_REMOVE: text = "Program removed from chart"; break;
            case REASON_RECOMPILE: text = "Program recompiled"; break;
            case REASON_CHARTCHANGE: text = "Symbol or timeframe changed"; break;
            case REASON_CHARTCLOSE: text = "Chart closed"; break;
            case REASON_PARAMETERS: text = "Input parameters changed"; break;
            case REASON_ACCOUNT: text = "Another account activated"; break;
            default: text = "Unknown reason " + string(reason);
        }
        return text;
    }
    
    // Hàm điều chỉnh tham số theo preset
    bool AdjustParametersByPreset(int preset) {
        switch(preset) {
            case PRESET_TRENDING:
                // Điều chỉnh tham số cho thị trường xu hướng
                GlobalLogInfo("Điều chỉnh tham số cho thị trường xu hướng");
                MinPullbackPercent = 30.0;
                MaxPullbackPercent = 61.8;
                StopLoss_ATR = 1.5;
                TakeProfit_RR = 2.0;
                TrailingMode = TRAILING_ATR;
                return true;
                
            case PRESET_RANGING:
                // Điều chỉnh tham số cho thị trường sideway
                GlobalLogInfo("Điều chỉnh tham số cho thị trường sideway");
                MinPullbackPercent = 40.0;
                MaxPullbackPercent = 80.0;
                StopLoss_ATR = 1.2;
                TakeProfit_RR = 1.5;
                TrailingMode = TRAILING_SWING_POINTS;
                return true;
                
            case PRESET_VOLATILE:
                // Điều chỉnh tham số cho thị trường biến động
                GlobalLogInfo("Điều chỉnh tham số cho thị trường biến động");
                MinPullbackPercent = 20.0;
                MaxPullbackPercent = 50.0;
                StopLoss_ATR = 2.0;
                TakeProfit_RR = 2.5;
                TrailingMode = TRAILING_ADAPTIVE;
                return true;
                
            case PRESET_CONSERVATIVE:
                // Điều chỉnh tham số cho giao dịch bảo thủ
                GlobalLogInfo("Điều chỉnh tham số cho giao dịch bảo thủ");
                MinPullbackPercent = 40.0;
                MaxPullbackPercent = 61.8;
                StopLoss_ATR = 1.2;
                TakeProfit_RR = 2.0;
                TrailingMode = TRAILING_ATR;
                RiskPercent = 0.5;
                return true;
                
            default:
                {
                    string warningMsg = "Preset không hợp lệ hoặc không được hỗ trợ: ";
                    warningMsg = warningMsg + IntegerToString(preset);
                    GlobalLogWarning(warningMsg);
                    return false;
                }
        }
    }
} // kết thúc namespace ApexPullback

#endif // _FUNCTION_DEFINITIONS_MQH_
