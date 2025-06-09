//+------------------------------------------------------------------+
//|   APEX PULLBACK EA v14.0 - Professional Edition                  |
//|   Module hóa xuất sắc - Quản lý rủi ro - EA chuẩn Prop   |
//|   Copyright 2025, APEX Forex - Mèo Cọc                           |
//+------------------------------------------------------------------+

// =====================================================================================================================
// Khai báo thư viện MQL
// =====================================================================================================================
// --- Standard MQL5 Libraries ---
#include <Trade/Trade.mqh>                // CTrade class for trading operations
#include <Trade/PositionInfo.mqh>         // CPositionInfo for position data
#include <Trade/SymbolInfo.mqh>           // CSymbolInfo for symbol properties
#include <Trade/AccountInfo.mqh>          // CAccountInfo for account details
#include <Arrays/ArrayObj.mqh>            // CArrayObj for collections of objects
#include <Arrays/ArrayDouble.mqh>         // For dynamic arrays of doubles
#include <Arrays/ArrayString.mqh>         // For dynamic arrays of strings
#include <Arrays/ArrayInt.mqh>            // For dynamic arrays of integers
#include <Object.mqh>                     // Base class for chart objects
#include <Charts/Chart.mqh>               // CChart class for chart operations
#include <ChartObjects/ChartObject.mqh>   // CChartObject base class
#include <ChartObjects/ChartObjectsLines.mqh> // Line objects
#include <ChartObjects/ChartObjectsShapes.mqh>// Shape objects
#include <Math/Stat/Math.mqh>             // Mathematical functions
#include <Math/Stat/Stat.mqh>             // Statistical functions
#include <Files/FileTxt.mqh>              // For text file operations (e.g., CSV logging)

// --- Custom EA Core Includes ---
// QUAN TRỌNG: Các tệp này định nghĩa các thành phần cốt lõi và nên được include trước các module cụ thể.
// Namespace.mqh nên được include trước khi khai báo namespace.
#include "Namespace.mqh"                // Defines namespaces (e.g., ApexPullback) and related macros
#include "CommonDefinitions.mqh"        // General definitions, possibly macros like TREND_NONE, SIGNAL_NONE
#include "Constants.mqh"                // EA-specific constants
#include "Enums.mqh"                    // Enumerations (e.g., ENUM_EA_STATE, ENUM_TRAILING_MODE)
#include "CommonStructs.mqh"            // Common data structures (e.g., MarketProfileData, PositionMetadata)
#include "FunctionDefinitions.mqh"      // Global utility functions (if any are used by this module)
#include "MathHelper.mqh"               // Math utility functions (if any are used by this module)

// Forward declarations to resolve class dependencies
namespace ApexPullback {
    class CLogger;
    class CDashboard;
    class CRiskManager;
    class CSessionManager;
    class CNewsFilter;
    class CAssetProfileManager;
    struct AssetProfile;
    struct MarketProfileData;
    class CMarketProfile;
    class CSwingPointDetector;
    class CPositionManager;
    class CTradeManager;
    class CPatternDetector;
    class CPerformanceTracker;
    class CPortfolioManager; // Forward declaration for PortfolioManager
    struct IndicatorHandles;
}

//+------------------------------------------------------------------+
//| EA Context Structure                                             |
//+------------------------------------------------------------------+
namespace ApexPullback {
struct EAContext {
    CLogger*             Logger;
    CTradeManager*       TradeManager;
    CPositionManager*    PositionManager;
    CRiskManager*        RiskManager;
    CDashboard*          Dashboard;
    CSwingPointDetector* SwingDetector;
    CMarketProfile*      MarketProfile;
    CPerformanceTracker* PerformanceTracker;
    CAssetProfileManager* AssetProfileManager;
    CNewsFilter*         NewsFilter;
    CSessionManager*     SessionManager;
    CPatternDetector*    PatternDetector;
    CIndicatorUtils*     IndicatorUtils;
    CAssetProfiler*      AssetProfiler; // Added AssetProfiler
    CPortfolioManager*   PortfolioManager; // Added PortfolioManager

    // Key state variables
    MarketProfileData    CurrentProfileData;
    datetime             LastMarketDataUpdate;
    datetime             LastTickTime;
    datetime             LastHeartbeatTime;
    datetime             LastPerformanceUpdate;
    datetime             SpreadCacheTime;
    double               CachedSpread;
    datetime             LastDashboardUpdateTime; // For UpdateDashboardIfNeeded
    int                  DashboardErrorCount;   // For UpdateDashboardIfNeeded

    bool                 IsInitialized;
    bool                 IsShuttingDown;
    bool                 EmergencyStop;
    bool                 AllowNewTrades; // Renamed from g_AllowNewTrades
    bool                 DisplayDashboard; // Moved from global g_DisplayDashboard

    long                 TickCounter;
    int                  ErrorCounter;
    int                  SuccessfulTrades;
    int                  FailedTrades;
    int                  DayTrades;
    double               CurrentDrawdownPct;
    datetime             LastAdaptationTime;        // Thời gian thích ứng thị trường cuối cùng
    datetime             LastAssetProfileUpdateTime;// Thời gian cập nhật hồ sơ tài sản cuối cùng

    // Constructor to initialize pointers to NULL and default values
    EAContext() : Logger(NULL), TradeManager(NULL), PositionManager(NULL), RiskManager(NULL),
                  Dashboard(NULL), SwingDetector(NULL), MarketProfile(NULL), PerformanceTracker(NULL),
                  AssetProfileManager(NULL), NewsFilter(NULL), SessionManager(NULL), PatternDetector(NULL),
                  IndicatorUtils(NULL), AssetProfiler(NULL), PortfolioManager(NULL),
                  LastMarketDataUpdate(0), LastTickTime(0), LastHeartbeatTime(0),
                  LastPerformanceUpdate(0), SpreadCacheTime(0), CachedSpread(0.0),
                  LastDashboardUpdateTime(0), DashboardErrorCount(0),
                  IsInitialized(false), IsShuttingDown(false), EmergencyStop(false), AllowNewTrades(true),
                  DisplayDashboard(true), // Initialize DisplayDashboard
                  TickCounter(0), ErrorCounter(0), SuccessfulTrades(0), FailedTrades(0), DayTrades(0),
                  CurrentDrawdownPct(0.0),
                  LastAdaptationTime(0), LastAssetProfileUpdateTime(0) { // Initialize new members
        // CurrentProfileData will be default initialized
    }
};

EAContext* g_EAContext = NULL; // Global EA context pointer
} // End namespace ApexPullback


// Include các module chính theo thứ tự phụ thuộc
#include "Logger.mqh"
#include "Dashboard.mqh"
#include "RiskManager.mqh"
#include "SessionManager.mqh"
#include "NewsFilter.mqh"
#include "AssetProfileManager.mqh"
#include "MarketProfile.mqh"
#include "SwingPointDetector.mqh"
#include "PositionManager.mqh"
#include "TradeManager.mqh"
#include "PatternDetector.mqh"
#include "PerformanceTracker.mqh"
#include "IndicatorUtils.mqh"       // Module quản lý và khởi tạo indicator
#include "PortfolioManager.mqh"     // Module quản lý danh mục đầu tư

// Khai báo các tham số đầu vào
input string  EAName              = "APEX Pullback EA v14.0"; // Tên EA
input string  EAVersion           = "14.0";                    // Phiên bản
input int     MagicNumber         = 1234567;                  // Magic Number
input string  OrderComment        = "APEX_v14";               // Ghi chú lệnh
input bool    InpAllowNewTrades      = true;                     // Cho phép vào lệnh mới (sẽ được gán cho g_EAContext.AllowNewTrades)
input bool    InpEnableDetailedLogs  = false;                    // Bật log chi tiết (sẽ được dùng để cấu hình Logger)
input bool    EnableCsvLog        = false;                    // Ghi log vào file CSV
input string  CsvLogFilename      = "ApexPullback_Log.csv";   // Tên file CSV log
// input bool   InpDisplayDashboard = true;                // Hiển thị dashboard (Đã có trong EAContext, sẽ lấy từ input khác nếu cần)
input int     DashboardTheme      = 0;                        // Chủ đề Dashboard
input bool    AlertsEnabled       = true;                     // Bật cảnh báo
input bool    SendNotifications   = false;                    // Gửi thông báo đẩy
input bool    SendEmailAlerts     = false;                    // Gửi email
input bool    EnableTelegramNotify = false;                   // Bật thông báo Telegram
input string  TelegramBotToken    = "";                       // Token Bot Telegram
input string  TelegramChatID      = "";                       // ID Chat Telegram
input bool    TelegramImportantOnly = true;                   // Chỉ gửi thông báo quan trọng
input bool    DisableDashboardInBacktest = false;             // Tắt dashboard trong backtest
input int     MainTimeframe       = PERIOD_CURRENT;           // Khung thời gian chính
input int     EMA_Fast            = 34;                       // EMA nhanh
input int     EMA_Medium          = 89;                       // EMA trung bình
input int     EMA_Slow            = 200;                      // EMA chậm
input int     ATR_Period          = 14;                       // Giai đoạn ATR
input bool    UseMultiTimeframe   = true;                     // Sử dụng đa khung thời gian
input int     HigherTimeframe     = PERIOD_H4;                // Khung thời gian cao hơn
input int     TrendDirection      = 0;                        // Hướng xu hướng giao dịch
input bool    EnablePriceAction   = true;                     // Kích hoạt xác nhận Price Action
input bool    EnableSwingLevels   = true;                     // Sử dụng Swing Levels

//+------------------------------------------------------------------+
//| Các hàm khởi tạo indicator và cache - nằm trong namespace        |
//+------------------------------------------------------------------+
namespace ApexPullback {

// Session types - định nghĩa trong namespace
enum ENUM_SESSION_TYPE {
    SESSION_TYPE_NONE = 0,
    SESSION_TYPE_ASIAN = 1,
    SESSION_TYPE_LONDON = 2,
    SESSION_TYPE_NEWYORK = 3,
    SESSION_TYPE_OVERLAP = 4
};

//+------------------------------------------------------------------+
//| Kiểm tra xem thời gian hiện tại có cho phép giao dịch                   |
//+------------------------------------------------------------------+
bool IsAllowedTradingSession() {
    if (ApexPullback::g_EAContext == NULL || ApexPullback::g_EAContext.SessionManager == NULL) {
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogWarning("SessionManager is not initialized in IsAllowedTradingSession. Defaulting to true.");
        } else {
            Print("Warning: SessionManager is not initialized in IsAllowedTradingSession. Defaulting to true.");
        }
        return true; // Default to true to avoid blocking trades if not properly set up
    }
    return ApexPullback::g_EAContext.SessionManager.IsSessionActive();
}

//+------------------------------------------------------------------+
//| Kiểm tra xem thời gian hiện tại có ảnh hưởng tin tức kinh tế       |
//+------------------------------------------------------------------+
bool IsNewsImpactPeriod() {
    if (ApexPullback::g_EAContext == NULL || ApexPullback::g_EAContext.NewsFilter == NULL) {
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogWarning("NewsFilter is not initialized in IsNewsImpactPeriod. Defaulting to false.");
        } else {
            Print("Warning: NewsFilter is not initialized in IsNewsImpactPeriod. Defaulting to false.");
        }
        return false; // Default to false if not properly set up
    }
    return ApexPullback::g_EAContext.NewsFilter.IsInNewsWindow();
}

// GlobalInitializeIndicatorCache đã được định nghĩa trong IndicatorUtils.mqh

// InitializeIndicators đã được định nghĩa trong IndicatorUtils.mqh


} // Kết thúc namespace ApexPullback
input double  MinPullbackPercent  = 30.0;                     // % Pullback tối thiểu
input double  MaxPullbackPercent  = 70.0;                     // % Pullback tối đa
input bool    RequirePriceActionConfirmation = true;          // Yêu cầu xác nhận Price Action
input bool    RequireMomentumConfirmation = true;             // Yêu cầu xác nhận Momentum
input bool    RequireVolumeConfirmation = false;              // Yêu cầu xác nhận Volume
input bool    EnableMarketRegimeFilter = true;                // Bật lọc Market Regime
input bool    EnableVolatilityFilter = true;                  // Lọc biến động bất thường
input bool    EnableAdxFilter = false;                        // Lọc ADX
input int     MarketPreset = 0;                               // Preset cấu hình thị trường
input double  MinAdxValue = 20.0;                             // Giá trị ADX tối thiểu
input double  MaxAdxValue = 50.0;                             // Giá trị ADX tối đa
input double  VolatilityThreshold = 2.0;                      // Ngưỡng biến động (xATR)
input double  MaxSpreadPoints = 50.0;                         // Spread tối đa (points)
input double  RiskPercent = 1.0;                              // Risk % mỗi lệnh
input double  StopLoss_ATR = 1.5;                             // Hệ số ATR cho Stop Loss
input double  TakeProfit_RR = 2.0;                            // Tỷ lệ R:R cho Take Profit
input bool    PropFirmMode = false;                          // Chế độ Prop Firm
input double  DailyLossLimit = 5.0;                          // Giới hạn lỗ ngày (%)
input double  MaxDrawdown = 10.0;                             // Drawdown tối đa (%)
input int     MaxTradesPerDay = 5;                           // Số lệnh tối đa/ngày
input int     MaxConsecutiveLosses = 3;                      // Số lần thua liên tiếp tối đa
input int     MaxPositions = 1;                              // Số vị thế tối đa
input double  DrawdownReduceThreshold = 5.0;                 // Ngưỡng DD để giảm risk (%)
input bool    EnableTaperedRisk = true;                      // Giảm risk từ từ (không đột ngột)
input double  MinRiskMultiplier = 0.3;                       // Hệ số risk tối thiểu khi DD cao
input int     EntryMode = 0;                                 // Chế độ vào lệnh
input bool    UsePartialClose = false;                       // Sử dụng đóng từng phần
input double  PartialCloseR1 = 1.0;                          // R-multiple cho đóng phần 1
input double  PartialCloseR2 = 2.0;                          // R-multiple cho đóng phần 2
input double  PartialClosePercent1 = 50.0;                   // % đóng ở mức R1
input double  PartialClosePercent2 = 50.0;                   // % đóng ở mức R2
input bool    UseAdaptiveTrailing = true;                    // Trailing thích ứng theo regime
input int     TrailingMode = 0;                              // Chế độ trailing mặc định
input double  TrailingAtrMultiplier = 2.0;                   // Hệ số ATR cho trailing
input double  BreakEvenAfterR = 0.5;                         // Chuyển BE sau (R-multiple)
input double  BreakEvenBuffer = 5.0;                         // Buffer cho breakeven (points)
input bool    UseAssetProfiler = true;                       // Sử dụng Asset Profiler
input int     UpdateFrequencySeconds = 5;                    // Tần suất cập nhật Dashboard (giây)
input bool    SaveStatistics = true;                         // Lưu thống kê khi kết thúc
input bool    EnableIndicatorCache = true;                   // Bật cache indicator

// Định nghĩa namespace variables trong namespace ApexPullback
namespace ApexPullback {
    // Global variables have been moved to EAContext.
    // Access them via g_EAContext.variableName (since g_EAContext is a pointer, it would be g_EAContext->variableName, but the struct itself is often passed by value or reference in functions)
    // Indicator handles are now managed by CIndicatorUtils within g_EAContext

    // Các hàm inline hỗ trợ đã được chuyển sang sử dụng g_EAContext hoặc loại bỏ nếu không cần thiết
    // Example: inline bool IsAlertsEnabled() { return g_EAContext != NULL && g_EAContext.AlertsEnabled; }
    // Direct access like ApexPullback::g_EAContext.AlertsEnabled is preferred.

    // Placeholder for any remaining essential global-like accessors or definitions within this namespace
    // that are not directly tied to the removed EA state variables.
}







// =====================================================================================================================
// Định nghĩa các enum cần thiết và hằng số
// =====================================================================================================================

// Sử dụng các hằng số cho Log Level và Alert
#ifndef ALERT_LEVEL_CRITICAL
#define ALERT_LEVEL_CRITICAL 3
#endif

// Định nghĩa các hằng số đơn giản hóa cho TREND và REGIME để tránh lỗi biên dịch
#define TREND_BULLISH      ENUM_MARKET_TREND::TREND_UP_STRONG
#define TREND_BEARISH      ENUM_MARKET_TREND::TREND_DOWN_STRONG
#define TREND_NEUTRAL      ENUM_MARKET_TREND::TREND_SIDEWAY
#define REGIME_TRENDING    ENUM_MARKET_REGIME::REGIME_TRENDING
#define REGIME_RANGING     ENUM_MARKET_REGIME::REGIME_RANGING
#define REGIME_TRANSITIONING ENUM_MARKET_REGIME::REGIME_VOLATILE_EXPANSION

// Log level constants are now defined as enums in Logger.mqh
// Removed conflicting #define statements

// ENUM_MARKET_PRESET đã được định nghĩa trong Enums.mqh

// Định nghĩa enum ENUM_ALERT_LEVEL đã được thay thế bằng các hằng số để tránh xung đột

// Forward declarations cho các lớp và structs từ namespace ApexPullback

// Không khai báo lại các biến đã có trong namespace ApexPullback cho các module và đối tượng
// Khai báo các biến global từ namespace ApexPullback

namespace ApexPullback {
    

    
} // End namespace ApexPullback

// GlobalSendAlert đã được định nghĩa ở phần sau





// Khai báo biến toàn cục cho EA
// bool g_EnableDetailedLogs = false;             // Bật logs chi tiết

// Các hàm inline trong namespace ApexPullback
namespace ApexPullback {
    // Indicator handles have been removed and are managed by CIndicatorUtils in EAContext.

    // Loại bỏ các khai báo trùng lặp
    // bool   g_AlertsEnabled = true;                   // Bật cảnh báo
    // bool   g_SendNotifications = true;               // Gửi thông báo
    // bool   g_SendEmailAlerts = false;                // Gửi email
    // bool   g_EnableTelegramNotify = false;           // Gửi Telegram
    // bool   g_TelegramImportantOnly = true;           // Chỉ gửi Telegram quan trọng
    // bool   g_DisplayDashboard = true;                // Hiển thị dashboard
    // bool   g_EnableIndicatorCache = true;            // Bật cache indicator

    // Các hàm inline hỗ trợ đã được định nghĩa ở phần trước
    // Không định nghĩa lại
    // inline bool IsAlertsEnabled() { return g_AlertsEnabled; }
    // inline bool IsSendNotificationsEnabled() { return g_SendNotifications; }
    // inline bool IsSendEmailAlertsEnabled() { return g_SendEmailAlerts; }
    // inline bool IsTelegramNotifyEnabled() { return g_EnableTelegramNotify; }
    // inline bool IsTelegramImportantOnly() { return g_TelegramImportantOnly; }
    // inline bool IsDashboardEnabled() { return g_DisplayDashboard; }
} // Đóng namespace ApexPullback

//+------------------------------------------------------------------+
//| Hàm kiểm tra tính hợp lệ của các tham số đầu vào (Cải tiến)    |
//+------------------------------------------------------------------+
bool ValidateInputParameters() {
    bool isValid = true;
    string errorMsg = "";
    
    // Kiểm tra Magic Number với phạm vi hợp lý
    if (MagicNumber <= 0 || MagicNumber > 2147483647) {
        errorMsg += "Magic Number phải trong khoảng 1-2147483647. ";
        isValid = false;
    }
    
    // Kiểm tra các tham số EMA với giới hạn thực tế
    if (EMA_Fast <= 0 || EMA_Fast > 1000) {
        errorMsg += "EMA_Fast phải trong khoảng 1-1000. ";
        isValid = false;
    }
    if (EMA_Medium <= 0 || EMA_Medium > 1000) {
        errorMsg += "EMA_Medium phải trong khoảng 1-1000. ";
        isValid = false;
    }
    if (EMA_Slow <= 0 || EMA_Slow > 1000) {
        errorMsg += "EMA_Slow phải trong khoảng 1-1000. ";
        isValid = false;
    }
    
    if (EMA_Fast >= EMA_Medium || EMA_Medium >= EMA_Slow) {
        errorMsg += "Thứ tự EMA phải: EMA_Fast < EMA_Medium < EMA_Slow. ";
        isValid = false;
    }
    
    // Kiểm tra ATR Period với phạm vi hợp lý
    if (ATR_Period <= 0 || ATR_Period > 200) {
        errorMsg += "ATR Period phải trong khoảng 1-200. ";
        isValid = false;
    }
    
    // Kiểm tra các tham số Risk Management
    if (RiskPercent <= 0 || RiskPercent > 10) {
        errorMsg += "Risk Percent phải trong khoảng 0.1-10%. ";
        isValid = false;
    }
    
    if (StopLoss_ATR <= 0 || StopLoss_ATR > 10) {
        errorMsg += "StopLoss ATR multiplier phải trong khoảng 0.1-10. ";
        isValid = false;
    }
    
    if (TakeProfit_RR <= 0 || TakeProfit_RR > 20) {
        errorMsg += "TakeProfit R:R phải trong khoảng 0.1-20. ";
        isValid = false;
    }
    
    // Kiểm tra các giới hạn giao dịch
    if (MaxTradesPerDay <= 0 || MaxTradesPerDay > 100) {
        errorMsg += "Max Trades Per Day phải trong khoảng 1-100. ";
        isValid = false;
    }
    
    if (MaxPositions <= 0 || MaxPositions > 10) {
        errorMsg += "Max Positions phải trong khoảng 1-10. ";
        isValid = false;
    }
    
    // Kiểm tra Telegram settings nếu được bật
    if (EnableTelegramNotify) {
        if (StringLen(TelegramBotToken) < 10) {
            errorMsg += "Telegram Bot Token quá ngắn (tối thiểu 10 ký tự). ";
            isValid = false;
        }
        if (StringLen(TelegramChatID) == 0) {
            errorMsg += "Telegram Chat ID không được để trống. ";
            isValid = false;
        }
    }
    
    // Kiểm tra CSV log filename nếu được bật
    if (EnableCsvLog) {
        if (StringLen(CsvLogFilename) == 0) {
            errorMsg += "Tên file CSV log không được để trống. ";
            isValid = false;
        }
        if (StringFind(CsvLogFilename, ".csv") == -1) {
            errorMsg += "File CSV log phải có đuôi .csv. ";
            isValid = false;
        }
    }
    
    // Kiểm tra tính hợp lý của Pullback parameters
    if (MinPullbackPercent <= 0 || MinPullbackPercent >= 100) {
        errorMsg += "Min Pullback Percent phải trong khoảng 1-99%. ";
        isValid = false;
    }
    
    if (MaxPullbackPercent <= MinPullbackPercent || MaxPullbackPercent >= 100) {
        errorMsg += "Max Pullback Percent phải lớn hơn Min và nhỏ hơn 100%. ";
        isValid = false;
    }
    
    // Log lỗi nếu có
    if (!isValid) {
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogError("Lỗi tham số đầu vào: " + errorMsg);
        } else {
            Print("[LỖI NGHIÊM TRỌNG] Tham số đầu vào không hợp lệ: " + errorMsg);
        }
    } else {
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogInfo("Tất cả tham số đầu vào đã được xác thực thành công.");
        } else {
             Print("Tất cả tham số đầu vào đã được xác thực thành công (Logger không khả dụng).");
        }
    }
    
    return isValid;
}

//+------------------------------------------------------------------+
//| Hàm dọn dẹp khi khởi tạo thất bại                              |
//+------------------------------------------------------------------+
void CleanupPartialInit() {
    CLogger* loggerToUse = NULL;
    if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
        loggerToUse = ApexPullback::g_EAContext.Logger;
    } else {
        // loggerToUse remains NULL, subsequent checks will handle Print
    }

    if (loggerToUse != NULL) {
        loggerToUse.LogInfo("Bắt đầu dọn dẹp do khởi tạo thất bại...");
    } else {
        Print("Bắt đầu dọn dẹp do khởi tạo thất bại (Logger không khả dụng)...");
    }
    
    if (ApexPullback::g_EAContext != NULL) {
        // Dọn dẹp theo thứ tự ngược lại với khởi tạo, using context members
        if (ApexPullback::g_EAContext.Dashboard != NULL) { delete ApexPullback::g_EAContext.Dashboard; ApexPullback::g_EAContext.Dashboard = NULL; }
        if (ApexPullback::g_EAContext.AssetProfileManager != NULL) { delete ApexPullback::g_EAContext.AssetProfileManager; ApexPullback::g_EAContext.AssetProfileManager = NULL; }
        if (ApexPullback::g_EAContext.NewsFilter != NULL) { delete ApexPullback::g_EAContext.NewsFilter; ApexPullback::g_EAContext.NewsFilter = NULL; }
        if (ApexPullback::g_EAContext.SessionManager != NULL) { delete ApexPullback::g_EAContext.SessionManager; ApexPullback::g_EAContext.SessionManager = NULL; }
        if (ApexPullback::g_EAContext.RiskManager != NULL) { delete ApexPullback::g_EAContext.RiskManager; ApexPullback::g_EAContext.RiskManager = NULL; }
        if (ApexPullback::g_EAContext.TradeManager != NULL) { delete ApexPullback::g_EAContext.TradeManager; ApexPullback::g_EAContext.TradeManager = NULL; }
        if (ApexPullback::g_EAContext.PositionManager != NULL) { delete ApexPullback::g_EAContext.PositionManager; ApexPullback::g_EAContext.PositionManager = NULL; }
        if (ApexPullback::g_EAContext.SwingDetector != NULL) { delete ApexPullback::g_EAContext.SwingDetector; ApexPullback::g_EAContext.SwingDetector = NULL; }
        if (ApexPullback::g_EAContext.MarketProfile != NULL) { delete ApexPullback::g_EAContext.MarketProfile; ApexPullback::g_EAContext.MarketProfile = NULL; }
        if (ApexPullback::g_EAContext.PatternDetector != NULL) { delete ApexPullback::g_EAContext.PatternDetector; ApexPullback::g_EAContext.PatternDetector = NULL; }
        if (ApexPullback::g_EAContext.PerformanceTracker != NULL) { delete ApexPullback::g_EAContext.PerformanceTracker; ApexPullback::g_EAContext.PerformanceTracker = NULL; }
        if (ApexPullback::g_EAContext.PortfolioManager != NULL) { delete ApexPullback::g_EAContext.PortfolioManager; ApexPullback::g_EAContext.PortfolioManager = NULL; }
        if (ApexPullback::g_EAContext.IndicatorUtils != NULL) { 
            // IndicatorUtils might handle its own indicator handle releases in its destructor
            // Or call a specific cleanup method if needed before deleting IndicatorUtils
            // ApexPullback::g_EAContext.IndicatorUtils.ReleaseAllIndicators(); // Example
            delete ApexPullback::g_EAContext.IndicatorUtils; ApexPullback::g_EAContext.IndicatorUtils = NULL; 
        }
        // Note: Global indicator handles like g_hMA_Fast are now ideally managed by IndicatorUtils.
        // If not, they need separate handling or to be added to EAContext for cleanup.
        // ReleaseIndicatorHandles(); // This global function will need to be updated or its logic moved.

        // Logger (part of context) is deleted when g_EAContext is deleted
        if (ApexPullback::g_EAContext.Logger != NULL) {
            // Log final cleanup message with the context's logger before it's deleted with the context
            // No need to delete ApexPullback::g_EAContext.Logger separately if g_EAContext itself is deleted.
        }
        delete ApexPullback::g_EAContext;
        ApexPullback::g_EAContext = NULL;
    } else {
        // Fallback to old global variable cleanup if g_EAContext was never initialized or already cleaned up - This block should ideally not be reached.
        Print("CleanupPartialInit: EAContext was NULL. Global fallbacks for Dashboard, AssetProfileManager, Logger are removed.");
    }
    // Global indicator handles are now managed by CIndicatorUtils within g_EAContext.

    if (loggerToUse != NULL) { 
        loggerToUse.LogInfo("Hoàn tất dọn dẹp do khởi tạo thất bại.");
    } else {
        Print("Hoàn tất dọn dẹp do khởi tạo thất bại (Logger không khả dụng).");
    }
}

//+------------------------------------------------------------------+
//| Hàm khởi tạo EA                                                |
//+------------------------------------------------------------------+
int OnInit() {
    int result = INIT_SUCCEEDED;

    // Initialize EA Context first
    ApexPullback::g_EAContext = new ApexPullback::EAContext();
    if (ApexPullback::g_EAContext == NULL) {
        Print("[LỖI NGHIÊM TRỌNG] Không thể khởi tạo EAContext. EA không thể khởi động.");
        return INIT_FAILED;
    }
    
    // --- Bước 0: Kiểm tra tính hợp lệ của tham số đầu vào ---
    // Logger for ValidateInputParameters might not be initialized yet if it's part of context
    // So ValidateInputParameters should handle potential null logger or use Print for critical errors.
    if (!ValidateInputParameters()) { // This function needs to be aware g_Logger might be null or use g_EAContext.Logger if available
        Print("[LỖI NGHIÊM TRỌNG] Tham số đầu vào không hợp lệ. EA không thể khởi động.");
        delete ApexPullback::g_EAContext; ApexPullback::g_EAContext = NULL;
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // --- Bước 1: Khởi tạo Logger với kiểm tra bộ nhớ ---
    // Logger phải được khởi tạo đầu tiên để ghi lại toàn bộ quá trình khởi tạo.
    
    // Kiểm tra bộ nhớ khả dụng trước khi khởi tạo
    if (!CheckMemoryAvailable()) {
        Print("[LỖI NGHIÊM TRỌNG] Không đủ bộ nhớ để khởi tạo EA.");
        delete ApexPullback::g_EAContext; ApexPullback::g_EAContext = NULL;
        return INIT_FAILED;
    }
    
    ApexPullback::g_EAContext.Logger = new CLogger();
    if (ApexPullback::g_EAContext.Logger == NULL) {
        Print("[LỖI NGHIÊM TRỌNG] Không thể khởi tạo Logger trong EAContext. EA không thể tiếp tục.");
        CleanupPartialInit(); // CleanupPartialInit will handle g_EAContext deletion
        return INIT_FAILED;
    }
    
    // Khởi tạo Logger với các tham số đầu vào
    if (!ApexPullback::g_EAContext.Logger.Initialize(
        EAName,                  // Prefix
        EnableDetailedLogs,      // Enable detailed logs
        EnableCsvLog,            // Enable CSV log
        CsvLogFilename,          // CSV log filename
        EnableTelegramNotify,    // Enable Telegram notifications
        TelegramBotToken,        // Telegram bot token
        TelegramChatID,          // Telegram chat ID
        TelegramImportantOnly    // Only important Telegram notifications
    )) {
        Print("[LỖI NGHIÊM TRỌNG] Không thể khởi tạo Logger với các tham số. EA không thể tiếp tục.");
        CleanupPartialInit();
        return INIT_FAILED;
    }
    ApexPullback::g_EAContext.Logger.LogInfo("Bắt đầu khởi tạo APEX Pullback EA v14.0...");

    // --- Bước 2: Thiết lập các biến trong EAContext từ tham số đầu vào ---    
    ApexPullback::g_EAContext.Logger.LogDebug("Thiết lập các biến context từ tham số đầu vào...");
    // Many of these g_ variables will now be members of g_EAContext or specific managers
    // g_EAContext.Logger.SetVerboseLogging(InpEnableDetailedLogs); // Logger should handle this in its constructor or an init method
    // ApexPullback::g_AlertsEnabled = AlertsEnabled; // To be part of a notification manager or context
    // ApexPullback::g_SendNotifications = SendNotifications; // To be part of a notification manager or context
    // ApexPullback::g_SendEmailAlerts = SendEmailAlerts; // To be part of a notification manager or context
    // ApexPullback::g_EnableTelegramNotify = EnableTelegramNotify; // Handled by Logger init
    // ApexPullback::g_TelegramImportantOnly = TelegramImportantOnly; // Handled by Logger init
    // g_EAContext.DisplayDashboard = InpDisplayDashboard; // This is now part of EAContext and set via input parameter directly if needed or managed by Dashboard module
    // ApexPullback::g_EnableIndicatorCache = EnableIndicatorCache; // Input for IndicatorUtils
    ApexPullback::g_EAContext.MaxDrawdown = MaxDrawdown;
    ApexPullback::g_EAContext.MaxSpreadPoints = MaxSpreadPoints;
    ApexPullback::g_EAContext.MaxTradesPerDay = MaxTradesPerDay;
    ApexPullback::g_EAContext.AllowNewTrades = InpAllowNewTrades;
    ApexPullback::g_EAContext.VolatilityThreshold = VolatilityThreshold;
    ApexPullback::g_EAContext.MinPullbackPct = MinPullbackPercent;
    ApexPullback::g_EAContext.MaxPullbackPct = MaxPullbackPercent;
    
    // Khởi tạo các cấu trúc dữ liệu
    // ApexPullback::g_CurrentProfileData will be part of MarketProfile or context
    ApexPullback::g_EAContext.Logger.LogDebug("Đã thiết lập các biến context.");

    // --- Bước 3: Khởi tạo IndicatorUtils (bao gồm Cache nếu bật) và các Indicators Kỹ thuật ---
    ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo IndicatorUtils và các Indicators kỹ thuật...");
    ApexPullback::g_EAContext.IndicatorUtils = new ApexPullback::CIndicatorUtils(ApexPullback::g_EAContext.Logger, MainTimeframe, EnableIndicatorCache); // Pass EnableIndicatorCache here
    if (ApexPullback::g_EAContext.IndicatorUtils == NULL) {
        ApexPullback::g_EAContext.Logger.LogError("LỖI: Không thể khởi tạo IndicatorUtils.");
        CleanupPartialInit();
        return INIT_FAILED;
    }
    // CIndicatorUtils::Initialize now handles the initialization of all indicators, including the logic previously in GlobalInitializeIndicatorCache and the old InitializeIndicators function.
    // We pass `true` for `forceRefreshCache` to ensure handles are fresh on EA initialization.
    if (!ApexPullback::g_EAContext.IndicatorUtils.Initialize(_Symbol, MainTimeframe, InpHigherTimeframe, EnableIndicatorCache, EnableDetailedLogs, true)) { 
        ApexPullback::g_EAContext.Logger.LogError("LỖI: Không thể khởi tạo CIndicatorUtils (bao gồm các indicators kỹ thuật).");
        CleanupPartialInit();
        return INIT_FAILED;
    }
    ApexPullback::g_EAContext.Logger.LogDebug("CIndicatorUtils (bao gồm các indicators kỹ thuật) đã được khởi tạo thành công.");
    // Note: The global ApexPullback::InitializeIndicators() and g_IndicatorHandles have been refactored and are now managed by CIndicatorUtils.
        
    // --- Bước 4: Khởi tạo các Module Chính của EA ---
    // Sử dụng try-catch để bắt các ngoại lệ trong quá trình khởi tạo module.
    try {
        ApexPullback::g_EAContext.Logger.LogInfo("Bắt đầu khởi tạo các module chính...");

        // Module MarketProfile
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module MarketProfile...");
        ApexPullback::g_EAContext.MarketProfile = new CMarketProfile(ApexPullback::g_EAContext.Logger, _Symbol, MainTimeframe);
        if (ApexPullback::g_EAContext.MarketProfile == NULL) {
            throw new CException("Không thể khởi tạo Module MarketProfile.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module MarketProfile đã được khởi tạo.");
        
        // Module SwingDetector
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module SwingDetector...");
        ApexPullback::g_EAContext.SwingDetector = new CSwingPointDetector(ApexPullback::g_EAContext.Logger, _Symbol, MainTimeframe);
        if (ApexPullback::g_EAContext.SwingDetector == NULL) {
            throw new CException("Không thể khởi tạo Module SwingDetector.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module SwingDetector đã được khởi tạo.");
        
        // Module PositionManager
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module PositionManager...");
        ApexPullback::g_EAContext.PositionManager = new CPositionManager(ApexPullback::g_EAContext.Logger, MagicNumber, OrderComment);
        if (ApexPullback::g_EAContext.PositionManager == NULL) {
            throw new CException("Không thể khởi tạo Module PositionManager.");
        }
        // ApexPullback::g_EAContext.PositionManager.SetDetailedLogging(InpEnableDetailedLogs); // Logger now passed in constructor, verbose logging is set on the logger instance
        ApexPullback::g_EAContext.Logger.LogDebug("Module PositionManager đã được khởi tạo.");
        
        // Module RiskManager (Initialize before TradeManager if TradeManager depends on it)
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module RiskManager...");
        ApexPullback::g_EAContext.RiskManager = new CRiskManager(ApexPullback::g_EAContext.Logger, RiskPercent, StopLoss_ATR, TakeProfit_RR, DailyLossLimit, MaxDrawdown, MaxTradesPerDay, MaxConsecutiveLosses, MaxPositions, PropFirmMode);
        if (ApexPullback::g_EAContext.RiskManager == NULL) {
            throw new CException("Không thể khởi tạo Module RiskManager.");
        }
        // ApexPullback::g_EAContext.RiskManager.SetDetailedLogging(InpEnableDetailedLogs); // Logger now passed in constructor
        ApexPullback::g_EAContext.Logger.LogDebug("Module RiskManager đã được khởi tạo.");

        // Module TradeManager
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module TradeManager...");
        ApexPullback::g_EAContext.TradeManager = new CTradeManager(ApexPullback::g_EAContext.Logger, MagicNumber, OrderComment, ApexPullback::g_EAContext.PositionManager, ApexPullback::g_EAContext.RiskManager);
        if (ApexPullback::g_EAContext.TradeManager == NULL) {
            throw new CException("Không thể khởi tạo Module TradeManager.");
        }
        // ApexPullback::g_EAContext.TradeManager.SetDetailedLogging(InpEnableDetailedLogs); // Logger now passed in constructor
        ApexPullback::g_EAContext.Logger.LogDebug("Module TradeManager đã được khởi tạo.");
        
        // Module SessionManager
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module SessionManager...");
        ApexPullback::g_EAContext.SessionManager = new CSessionManager(ApexPullback::g_EAContext.Logger);
        if (ApexPullback::g_EAContext.SessionManager == NULL) {
            throw new CException("Không thể khởi tạo Module SessionManager.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module SessionManager đã được khởi tạo.");

        // Module NewsFilter
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module NewsFilter...");
        ApexPullback::g_EAContext.NewsFilter = new CNewsFilter(ApexPullback::g_EAContext.Logger);
        if (ApexPullback::g_EAContext.NewsFilter == NULL) {
            throw new CException("Không thể khởi tạo Module NewsFilter.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module NewsFilter đã được khởi tạo.");
        
        // Module Dashboard (Tùy chọn)
        if (DisplayDashboard && (!::MQLInfoInteger(MQL_TESTER) || !DisableDashboardInBacktest)) {
            ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module Dashboard...");
            ApexPullback::g_EAContext.Dashboard = new CDashboard(ApexPullback::g_EAContext.Logger, EAName, EAVersion, DashboardTheme);
            if (ApexPullback::g_EAContext.Dashboard == NULL) {
                ApexPullback::g_EAContext.Logger.LogWarning("LƯU Ý: Không thể khởi tạo Module Dashboard. Tiếp tục mà không có Dashboard.");
            } else {
                ApexPullback::g_EAContext.Logger.LogDebug("Module Dashboard đã được khởi tạo.");
            }
        } else {
            ApexPullback::g_EAContext.Logger.LogInfo("Module Dashboard không được kích hoạt hoặc đang trong backtest.");
        }
        
        // Module AssetProfileManager (Tùy chọn)
        if (UseAssetProfiler) { // Assuming UseAssetProfiler is an input parameter
            ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module AssetProfileManager...");
            ApexPullback::g_EAContext.AssetProfileManager = new CAssetProfileManager(ApexPullback::g_EAContext.Logger);
            if (ApexPullback::g_EAContext.AssetProfileManager == NULL) {
                ApexPullback::g_EAContext.Logger.LogWarning("LƯU Ý: Không thể khởi tạo Module AssetProfileManager. Tiếp tục mà không có AssetProfiler.");
            } else {
                ApexPullback::g_EAContext.Logger.LogDebug("Module AssetProfileManager đã được khởi tạo.");
            }
        } else {
            ApexPullback::g_EAContext.Logger.LogInfo("Module AssetProfileManager không được kích hoạt.");
        }

        // Initialize Performance Tracker
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module PerformanceTracker...");
        ApexPullback::g_EAContext.PerformanceTracker = new CPerformanceTracker(ApexPullback::g_EAContext.Logger);
        if (ApexPullback::g_EAContext.PerformanceTracker == NULL) {
            throw new CException("Không thể khởi tạo Module PerformanceTracker.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module PerformanceTracker đã được khởi tạo.");

        // Initialize Pattern Detector
        ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module PatternDetector...");
        ApexPullback::g_EAContext.PatternDetector = new CPatternDetector(ApexPullback::g_EAContext.Logger);
        if (ApexPullback::g_EAContext.PatternDetector == NULL) {
            throw new CException("Không thể khởi tạo Module PatternDetector.");
        }
        ApexPullback::g_EAContext.Logger.LogDebug("Module PatternDetector đã được khởi tạo.");

        // Initialize PortfolioManager (only for the Master EA instance)
        // TODO: Add input parameter to designate this EA as Master Portfolio Manager
        // For now, let's assume an input 'IsMasterPortfolioManager' exists or a specific symbol is used.
        input bool IsMasterPortfolioManager = false; // Placeholder for actual input parameter
        if(IsMasterPortfolioManager) { // Replace with actual input check
            ApexPullback::g_EAContext.Logger.LogDebug("Khởi tạo Module PortfolioManager...");
            // Ensure dependent modules are initialized before PortfolioManager
            if (ApexPullback::g_EAContext.NewsFilter == NULL || ApexPullback::g_EAContext.PositionManager == NULL || ApexPullback::g_EAContext.RiskManager == NULL) {
                ApexPullback::g_EAContext.Logger.LogError("LỖI: Các module phụ thuộc (NewsFilter, PositionManager, RiskManager) chưa được khởi tạo trước PortfolioManager.");
                CleanupPartialInit();
                return INIT_FAILED;
            }
            ApexPullback::g_EAContext.PortfolioManager = new CPortfolioManager(
                ApexPullback::g_EAContext.Logger,
                ApexPullback::g_EAContext.NewsFilter,
                ApexPullback::g_EAContext.PositionManager,
                ApexPullback::g_EAContext.RiskManager
            );
            // TODO: Pass actual configuration for MaxTotalRisk and MaxCorrelationAllowed from inputs
            input double PortfolioMaxTotalRisk = 0.1; // Placeholder
            input double PortfolioMaxCorrelation = 0.75; // Placeholder
            if(!ApexPullback::g_EAContext.PortfolioManager.Initialize(PortfolioMaxTotalRisk, PortfolioMaxCorrelation)) { 
                ApexPullback::g_EAContext.Logger.LogError("LỖI: Không thể khởi tạo Module PortfolioManager.");
                CleanupPartialInit();
                return INIT_FAILED;
            }
            ApexPullback::g_EAContext.Logger.LogDebug("Module PortfolioManager đã được khởi tạo cho Master EA.");
        } else {
            ApexPullback::g_EAContext.PortfolioManager = NULL; 
            ApexPullback::g_EAContext.Logger.LogInfo("Module PortfolioManager không được khởi tạo (không phải Master EA hoặc chưa được kích hoạt).");
        }

        // Initialize Asset Profiler (if different from AssetProfileManager or a sub-component)
        // This seems to be covered by AssetProfileManager logic above if UseAssetProfiler is the controlling input
        // If CAssetProfiler is a distinct class, initialize it here if needed.
        // if (UseSomeOtherProfiler) { ... }

        ApexPullback::g_EAContext.Logger.LogInfo("Hoàn tất khởi tạo các module chính.");

        // --- Bước 5: Cập nhật dữ liệu và cấu hình ban đầu ---
        ApexPullback::g_Logger.LogDebug("Cập nhật dữ liệu thị trường ban đầu...");
        if (!UpdateMarketData()) {
            ApexPullback::g_Logger.LogWarning("Không thể cập nhật dữ liệu thị trường ban đầu. Tiếp tục với dữ liệu mặc định.");
        }
        ApexPullback::g_Logger.LogDebug("Dữ liệu thị trường ban đầu đã được cập nhật.");
        
        if (ApexPullback::MarketPreset != ENUM_MARKET_PRESET::PRESET_AUTO) { 
            ApexPullback::g_Logger.LogDebug("Áp dụng preset thị trường: " + EnumToString(ApexPullback::MarketPreset) + "...");
            if (!ApexPullback::AdjustParametersByPreset(ApexPullback::MarketPreset)) {
                ApexPullback::g_Logger.LogWarning("Không thể áp dụng đầy đủ preset thị trường.");
            }
            ApexPullback::g_Logger.LogDebug("Preset thị trường đã được áp dụng.");
        }
        
        ApexPullback::g_Logger.LogDebug("Nạp cấu hình từ file (nếu có)...");
        if (!ApexPullback::LoadConfiguration()) {
            ApexPullback::g_Logger.LogWarning("Không thể nạp cấu hình từ file. Sử dụng cấu hình mặc định.");
        }
        ApexPullback::g_Logger.LogDebug("Cấu hình đã được nạp.");
        
        ApexPullback::g_Logger.LogDebug("Thiết lập các biến toàn cục của Terminal...");
        GlobalVariableSet("EMA_Fast", ApexPullback::EMA_Fast);
        GlobalVariableSet("EMA_Medium", ApexPullback::EMA_Medium);
        GlobalVariableSet("EMA_Slow", ApexPullback::EMA_Slow);
        ApexPullback::g_Logger.LogDebug("Các biến toàn cục của Terminal đã được thiết lập.");
        
        // Đánh dấu EA đã được khởi tạo thành công
        ApexPullback::g_EAContext.IsInitialized = true;
        
        string initSuccessMessage = "APEX Pullback EA v14.0 đã khởi động thành công!";
        initSuccessMessage += " | Ticks: 0 | Errors: 0 | Memory: " + DoubleToString(GetMemoryUsage(), 2) + "MB"; // GetMemoryUsage might need context if it uses logger
        
        ApexPullback::g_EAContext.Logger.LogInfo(initSuccessMessage);
        if (EnableTelegramNotify) { // Use input param directly or context field if set
             ApexPullback::g_EAContext.Logger.SendTelegramMessage(initSuccessMessage, true); // Gửi thông báo quan trọng qua Telegram
        }
        
        // Log thông tin hệ thống
        LogSystemInfo(); // This function will need to be updated to use g_EAContext.Logger
        
        return INIT_SUCCEEDED;
    } catch (const CException* e) {
        string error_message = "LỖI NGOẠI LỆ trong OnInit: " + e.Description();
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogError(error_message);
        } else {
            Print(error_message);
        }
        e.Delete();
        CleanupPartialInit();
        return INIT_FAILED;
    } catch (...) {
        string error_message = "LỖI NGOẠI LỆ KHÔNG XÁC ĐỊNH trong OnInit.";
        if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) {
            ApexPullback::g_EAContext.Logger.LogError(error_message);
        } else {
            Print(error_message);
        }
        CleanupPartialInit();
        return INIT_FAILED;
    }
}

//+------------------------------------------------------------------+
//| Hàm xử lý mỗi tick                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function - MT5 entry point                           |
//+------------------------------------------------------------------+
void OnTick() {
    // The global OnTick() now directly calls the namespaced OnTickLogic with the context.
    if (ApexPullback::g_EAContext != NULL) {
        ApexPullback::OnTickLogic(ApexPullback::g_EAContext);
    } else {
        // Minimal logging if context is not available, to avoid spamming Print
        static ulong error_print_counter = 0;
        error_print_counter++;
        if (error_print_counter % 1000 == 0) { // Print every 1000th uninitialized tick
            Print("APEX Pullback EA Error: EAContext is NULL in OnTick. Initialization might have failed.");
        }
    }
}

//+------------------------------------------------------------------+
//| Implementation của các hàm bổ sung                               |
//+------------------------------------------------------------------+

namespace ApexPullback {

// Hàm logic chính của OnTick, nhận EAContext làm tham số
void OnTickLogic(EAContext* context) {
    if (context == NULL) {
        // This case should ideally be caught by the caller, but as a safeguard:
        static ulong internal_error_counter = 0;
        internal_error_counter++;
        if (internal_error_counter % 1000 == 0) {
             Print("APEX Pullback EA Error: EAContext is NULL inside OnTickLogic.");
        }
        return;
    }

    // Kiểm tra trạng thái khẩn cấp và khởi tạo
    if (context.EmergencyStop || context.IsShuttingDown || !context.IsInitialized) {
        return;
    }
    
    // Kiểm tra xem các module quan trọng đã được khởi tạo chưa
    if (context.Logger == NULL || context.TradeManager == NULL || context.PositionManager == NULL) {
        context.ErrorCounter++;
        if (context.ErrorCounter % 100 == 0) { // Chỉ log mỗi 100 lần để tránh spam
            Print("LỖI: Các module chính (Logger, TradeManager, PositionManager) chưa được khởi tạo trong EAContext. OnTick bị bỏ qua. (Lần thứ " + IntegerToString(context.ErrorCounter) + ")");
        }
        return;
    }

    // Sử dụng try-catch để bắt lỗi trong OnTick
    try {
        datetime currentTime = TimeCurrent();
        datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
        bool isNewBar = (currentBarTime != context.LastBarTime);
        
        context.TickCounter++;
        context.LastTickTime = currentTime;
        
        // Kiểm tra tần suất tick quá cao (có thể là lỗi)
        static datetime lastTickCheck = 0;
        static int ticksInSecond = 0;
        
        if (currentTime != lastTickCheck) {
            if (ticksInSecond > 1000) { // Quá 1000 ticks/giây
                context.Logger.LogWarning("Phát hiện tần suất tick bất thường: " + IntegerToString(ticksInSecond) + " ticks/giây");
            }
            ticksInSecond = 0;
            lastTickCheck = currentTime;
        } else {
            ticksInSecond++;
        }
        
        // Ghi log debug có điều kiện và thông minh hơn
        if (context.EnableDetailedLogs) {
            if (isNewBar || (context.TickCounter % 500 == 0)) {
                context.Logger.LogDebug("OnTick #" + IntegerToString(context.TickCounter) + 
                                " - Bar: " + TimeToString(currentBarTime) + 
                                " - Spread: " + DoubleToString(GetCachedSpread(context), 1)); // GetCachedSpread now takes context
            }
        }

        // Kiểm tra điều kiện giao dịch cơ bản
        if (!context.AllowNewTrades) {
            if (context.EnableDetailedLogs && isNewBar) {
                context.Logger.LogDebug("Giao dịch mới hiện đang bị vô hiệu hóa.");
            }
            ManageExistingPositions(context);
            UpdateDashboardIfNeeded(currentTime, context);
            return;
        }

        // Xử lý nến mới với logic tối ưu
        if (isNewBar) {
            context.LastBarTime = currentBarTime;
            ProcessNewBar(currentTime, currentBarTime, context); // This call is already correct, ensuring it stays this way.
        }

        // Kiểm tra các điều kiện giao dịch với cache
        if (!CheckTradingConditionsOptimized(currentTime, context)) {
            ManageExistingPositions(context);
            UpdateDashboardIfNeeded(currentTime, context);
            return;
        }

        // Xử lý tín hiệu giao dịch với bảo vệ lỗi
        ProcessTradeSignalsWithProtection(context);

        // Quản lý các vị thế đang mở
        ManageExistingPositions(context);

        // Cập nhật dashboard và hiệu suất định kỳ
        UpdateDashboardIfNeeded(currentTime, context);
        UpdatePerformanceMetrics(currentTime, context); // This call is already correct
        
        // Reset error counter khi thành công
        if (context.ErrorCounter > 0) {
            context.ErrorCounter = 0;
        }
        
    } catch (const CException* e) {
        context.ErrorCounter++;
        context.Logger.LogError("Lỗi ngoại lệ trong OnTick #" + IntegerToString(context.TickCounter) + ": " + e.Description());
        } // Keep original catch blocks for CException and generic exception
    
        e.Delete();
        
        // Kích hoạt emergency stop nếu quá nhiều lỗi
        if (g_ErrorCounter > 1000) {
            g_EmergencyStop = true;
            g_Logger.LogError("EMERGENCY STOP: Quá nhiều lỗi liên tiếp (" + IntegerToString(g_ErrorCounter) + ")");
        }
    } catch (...) {
        g_ErrorCounter++;
        if (g_Logger != NULL) {
            g_Logger.LogError("Lỗi không xác định trong OnTick #" + IntegerToString(g_TickCounter));
        }
        
        // Kích hoạt emergency stop nếu quá nhiều lỗi
        if (g_ErrorCounter > 1000) {
            g_EmergencyStop = true;
            if (g_Logger != NULL) {
                g_Logger.LogError("EMERGENCY STOP: Quá nhiều lỗi không xác định (" + IntegerToString(g_ErrorCounter) + ")");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra các điều kiện giao dịch với tối ưu hóa cache      |
//+------------------------------------------------------------------+
bool ApexPullback::CheckTradingConditionsOptimized(datetime currentTime, CLogger* logger, CRiskManager* riskManager) {
    // Cache kết quả kiểm tra để tránh tính toán lặp lại
    static bool lastSessionCheck = true;
    static bool lastNewsCheck = false;
    static datetime lastSessionCheckTime = 0;
    static datetime lastNewsCheckTime = 0;
    
    // Kiểm tra phiên giao dịch (cache 60 giây)
    if (currentTime - lastSessionCheckTime > 60) {
        lastSessionCheck = IsAllowedTradingSession();
        lastSessionCheckTime = currentTime;
    }
    
    if (!lastSessionCheck) {
        if (g_EAContext.Logger != NULL && g_EAContext.Logger.IsVerboseLogging() && currentTime - lastSessionCheckTime < 5) {
            g_Logger.LogDebug("Ngoài phiên giao dịch cho phép.");
        }
        return false;
    }

    // Kiểm tra ảnh hưởng tin tức (cache 30 giây)
    if (currentTime - lastNewsCheckTime > 30) {
        lastNewsCheck = IsNewsImpactPeriod();
        lastNewsCheckTime = currentTime;
    }
    
    if (lastNewsCheck) {
        if (g_EAContext.Logger != NULL && g_EAContext.Logger.IsVerboseLogging() && currentTime - lastNewsCheckTime < 5) {
            g_Logger.LogDebug("Hiện đang trong thời gian ảnh hưởng tin tức. Giao dịch tạm dừng.");
        }
        return false;
    }

    // Kiểm tra spread với cache thông minh
    double currentSpread = GetCachedSpread(context); // Pass context
    double maxSpreadValue = context.MaxSpreadPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    if (currentSpread > maxSpreadValue) {
        if (context.EnableDetailedLogs && context.Logger != NULL) {
            context.Logger.LogDebug("Spread hiện tại (" + DoubleToString(currentSpread, 2) + 
                             ") vượt quá ngưỡng tối đa (" + DoubleToString(maxSpreadValue, 2) + ")");
        }
        return false;
    }
    
    // Kiểm tra drawdown hiện tại
    if (context.RiskManager != NULL && context.RiskManager.GetCurrentDrawdownPercent() > context.MaxDrawdown * 0.8) { // Cảnh báo khi gần đạt max drawdown
        if (context.Logger != NULL && context.EnableDetailedLogs) {
            context.Logger.LogWarning("Drawdown hiện tại (" + DoubleToString(context.RiskManager.GetCurrentDrawdownPercent(), 2) +
                              "%) gần đạt giới hạn tối đa (" + DoubleToString(context.MaxDrawdown, 2) + "%)");
        }
        return false;
    }
    
    // Kiểm tra số lệnh trong ngày
    if (context.DayTrades >= context.MaxTradesPerDay) {
        if (context.EnableDetailedLogs && context.Logger != NULL) {
            context.Logger.LogDebug("Đã đạt số lệnh tối đa trong ngày: " + IntegerToString(context.DayTrades));
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Hàm lấy spread với cache để tối ưu hiệu suất                   |
//+------------------------------------------------------------------+
double GetCachedSpread(EAContext* context) { // Accept context
    if (context == NULL) return SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT); // Fallback if context is null

    datetime currentTime = TimeCurrent();
    
    // Cache spread trong 2 giây
    if (currentTime - context.SpreadCacheTime > 2) {
        context.CachedSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
        context.SpreadCacheTime = currentTime;
    }
    
    return context.CachedSpread;
}

//+------------------------------------------------------------------+
//| Hàm quản lý các vị thế đang mở                                  |
//+------------------------------------------------------------------+
void ApexPullback::ManageExistingPositions(EAContext* context) { // Accept context
    if (context == NULL || context.PositionManager == NULL) return;

    try {
        context.PositionManager.UpdateOpenPositions();
    } catch (...) {
        if (context.Logger != NULL) {
            context.Logger.LogError("Lỗi khi cập nhật vị thế đang mở");
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm cập nhật dashboard có điều kiện và tối ưu                  |
//+------------------------------------------------------------------+
void ApexPullback::UpdateDashboardIfNeeded(datetime currentTime, EAContext* context) { // Accept context
    if (context == NULL || context.Dashboard == NULL || !context.DisplayDashboard) return;
    
    // Cập nhật dashboard mỗi 5 giây để tránh lag (tăng từ 3 giây)
    if (currentTime - context.LastDashboardUpdateTime >= 5) {
        try {
            context.Dashboard.Update();
            context.LastDashboardUpdateTime = currentTime;
            
            // Reset error count khi thành công
            if (context.DashboardErrorCount > 0) {
                context.DashboardErrorCount = 0;
            }
        } catch (...) {
            context.DashboardErrorCount++;
            if (context.Logger != NULL && context.DashboardErrorCount < 10) { // Chỉ log 10 lỗi đầu tiên
                context.Logger.LogError("Lỗi khi cập nhật dashboard (lần thứ " + IntegerToString(context.DashboardErrorCount) + ")");
            }
            
            // Vô hiệu hóa dashboard nếu quá nhiều lỗi
            if (context.DashboardErrorCount > 50) {
                context.DisplayDashboard = false; // Update context's display flag
                if (context.Logger != NULL) {
                    context.Logger.LogError("Vô hiệu hóa dashboard do quá nhiều lỗi liên tiếp");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm xử lý nến mới với logic tối ưu                             |
//+------------------------------------------------------------------+
void ApexPullback::ProcessNewBar(datetime currentTime, datetime currentBarTime, EAContext* context) {
    if (context == NULL) return;

    if (context.Logger != NULL) {
        context.Logger.LogInfo("Nến mới được phát hiện tại " + TimeToString(currentBarTime));
    }
    
    // Cập nhật dữ liệu thị trường với xử lý lỗi
    if (!UpdateMarketDataOptimized(currentTime, context)) { // Call with context
        if (context.Logger != NULL) {
            context.Logger.LogWarning("Không thể cập nhật dữ liệu thị trường.");
        }
        return;
    }
    
    // Cập nhật các điểm swing nếu cần
    if (context.SwingDetector != NULL) {
        try {
            context.SwingDetector.Update();
        } catch (...) {
            if (context.Logger != NULL) {
                context.Logger.LogError("Lỗi khi cập nhật SwingDetector");
            }
        }
    }
    
    // Phân tích và tìm tín hiệu với xử lý lỗi
    ProcessNewBarSignals(context); // Call with context
    
    // Thích ứng với điều kiện thị trường dài hạn (mỗi 4 giờ thay vì 24 giờ)
    if (currentTime - context.LastAdaptationTime > 14400) { // 14400 giây = 4 giờ
        if (context.RiskManager != NULL) {
            try {
                if (context.RiskManager.AdaptToMarketCycle()) {
                    context.LastAdaptationTime = currentTime;
                    if (context.Logger != NULL) {
                        context.Logger.LogInfo("Đã thích ứng với chu kỳ thị trường.");
                    }
                }
            } catch (...) {
                if (context.Logger != NULL) {
                    context.Logger.LogError("Lỗi khi thích ứng chu kỳ thị trường");
                }
            }
        }
    }
    
    // Reset daily trade counter vào đầu ngày mới
    static int lastDay = -1;
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    if (dt.day != lastDay) {
        context.DayTrades = 0; // Use context.DayTrades
        lastDay = dt.day;
        if (context.Logger != NULL) {
            context.Logger.LogInfo("Reset bộ đếm giao dịch ngày mới: " + TimeToString(currentTime));
        }
    }
}"Lỗi khi thích ứng chu kỳ thị trường");
                }
            }
        }
    }
    
    // Reset daily trade counter vào đầu ngày mới
    static int lastDay = -1;
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    if (dt.day != lastDay) {
        g_DayTrades = 0;
        lastDay = dt.day;
        if (logger != NULL) {
            logger.LogInfo("Reset bộ đếm giao dịch ngày mới: " + TimeToString(currentTime));
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm cập nhật dữ liệu thị trường với tối ưu hóa                 |
//+------------------------------------------------------------------+
bool ApexPullback::UpdateMarketDataOptimized(datetime currentTime, EAContext* context) {
    if (context == NULL) return false;

    // Chỉ cập nhật nếu đã qua 30 giây từ lần cập nhật cuối
    if (currentTime - context.LastMarketDataUpdate < 30) {
        return true; // Sử dụng dữ liệu cache
    }
    
    try {
        // UpdateMarketData will need to be refactored to use context or be context-aware
        bool result = UpdateMarketData(); // Assuming UpdateMarketData will be refactored or is context-aware
        if (result) {
            context.LastMarketDataUpdate = currentTime;
        }
        return result;
    } catch (...) {
        if (context.Logger != NULL) {
            context.Logger.LogError("Lỗi trong UpdateMarketDataOptimized");
        }
        return false;
    }
}

//+------------------------------------------------------------------+
//| Hàm xử lý tín hiệu giao dịch với bảo vệ lỗi nâng cao           |
//+------------------------------------------------------------------+
void ApexPullback::ProcessTradeSignalsWithProtection(EAContext* context) {
    static int signalErrorCount = 0;
    static datetime lastSignalError = 0;
    
    try {
        ProcessTradeSignals(context);
        
        // Reset error count khi thành công
        if (signalErrorCount > 0) {
            signalErrorCount = 0;
        }
    } catch (...) {
        signalErrorCount++;
        datetime currentTime = TimeCurrent();
        
        if (context.Logger != NULL && (currentTime - lastSignalError > 60)) { // Chỉ log mỗi phút
            context.Logger.LogError("Lỗi khi xử lý tín hiệu giao dịch (lần thứ " + IntegerToString(signalErrorCount) + ")");
            lastSignalError = currentTime;
        }
        
        // Tạm dừng xử lý tín hiệu nếu quá nhiều lỗi
        if (signalErrorCount > 20) {
            context.AllowNewTrades = false;
            if (context.Logger != NULL) {
                context.Logger.LogError("Tạm dừng giao dịch mới do quá nhiều lỗi xử lý tín hiệu");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm cập nhật các chỉ số hiệu suất                              |
//+------------------------------------------------------------------+
void ApexPullback::UpdatePerformanceMetrics(datetime currentTime, EAContext* context) {
    // Cập nhật mỗi 5 phút
    if (currentTime - context.LastPerformanceUpdate < 300) {
        return;
    }
    
    try {
        if (context.PerformanceTracker != NULL) {
            context.PerformanceTracker.UpdateMetrics();
        }
        
        // Cập nhật drawdown hiện tại
        if (context.RiskManager != NULL) {
            context.CurrentDrawdownPct = context.RiskManager.GetCurrentDrawdownPercent();
        }
        
        context.LastPerformanceUpdate = currentTime;
    } catch (...) {
        if (context.Logger != NULL) {
            context.Logger.LogError("Lỗi khi cập nhật chỉ số hiệu suất");
        }
    }
}

//+------------------------------------------------------------------+
//| Hàm xử lý tín hiệu trên nến mới                                 |
//+------------------------------------------------------------------+
void ApexPullback::ProcessNewBarSignals(EAContext* context) {
    if (context == NULL) return;
    try {
        // Tìm kiếm tín hiệu giao dịch
        FindTradeSignals(context); // Call with context
    } catch (...) {
        if (context.Logger != NULL) {
            context.Logger.LogError("Lỗi khi tìm kiếm tín hiệu giao dịch");
        }
    }
}

// Hàm tìm kiếm tín hiệu giao dịch
bool ApexPullback::FindTradeSignals(EAContext* context) {
    if (context == NULL || context.Logger == NULL || context.MarketProfile == NULL || context.SwingDetector == NULL) {
        if (context != NULL && context.Logger != NULL) {
            context.Logger.LogError("Không thể tìm tín hiệu giao dịch: Module thiếu trong context.");
        }
        return false;
    }

    // Cài đặt cờ tín hiệu
    bool signalFound = false;
    
    // Thực hiện tìm kiếm tín hiệu
    try {
        // Phân tích thị trường hiện tại
        ENUM_MARKET_TREND currentTrend = context.CurrentProfileData.trend;
        ENUM_MARKET_REGIME currentRegime = context.CurrentProfileData.regime;
        
        // Tìm kiếm tín hiệu pullback dựa trên xu hướng
        if (currentTrend == TREND_UP_STRONG || currentTrend == TREND_UP_NORMAL) {
            if (context.EnableDetailedLogs && context.Logger != NULL) {
            context.Logger.LogDebug("Đang tìm kiếm tín hiệu pullback trong xu hướng tăng...");
            }
            
            // Logic phát hiện pullback ở đây
            // ...
            
        } else if (currentTrend == TREND_DOWN_STRONG || currentTrend == TREND_DOWN_NORMAL) {
            if (context.EnableDetailedLogs && context.Logger != NULL) {
                context.Logger.LogDebug("Đang tìm kiếm tín hiệu pullback trong xu hướng giảm...");
            }
            
            // Logic phát hiện pullback ở đây
            // ...
            
        } else {
            if (context.EnableDetailedLogs && context.Logger != NULL) {
                context.Logger.LogDebug("Không có xu hướng rõ ràng. Bỏ qua tìm kiếm tín hiệu.");
            }
        }
        
        return signalFound;
    } catch (...) {
        if (context.Logger != NULL) {
            context.Logger.LogError("Lỗi không xác định trong FindTradeSignals()");
        }
        return false;
    }
}

// Hàm xử lý tín hiệu giao dịch
void ApexPullback::ProcessTradeSignals(EAContext* context) {
    if (context == NULL || context.Logger == NULL || context.TradeManager == NULL || context.RiskManager == NULL || context.PositionManager == NULL) {
        if (context != NULL && context.Logger != NULL) {
            context.Logger.LogError("Không thể xử lý tín hiệu giao dịch: Module thiếu trong context.");
        }
        return;
    }
    
    // Kiểm tra số lệnh tối đa trong ngày
    if (context.DayTrades >= context.MaxTradesPerDay) {
        if (context.Logger != NULL && context.EnableDetailedLogs) {
            context.Logger.LogDebug("Đã đạt số lệnh tối đa trong ngày (" + IntegerToString(context.MaxTradesPerDay) + ")");
        }
        return;
    }
    
    // Kiểm tra các vị thế đang mở
    int openPositions = 0;
    if (context.PositionManager != NULL) {
        openPositions = context.PositionManager.GetOpenPositionsCount();
    }
    
    if (openPositions >= context.MaxPositions) {
        if (context.Logger != NULL && context.EnableDetailedLogs) {
            context.Logger.LogDebug("Đã đạt số vị thế tối đa (" + IntegerToString(context.MaxPositions) + ")");
        }
        return;
    }
    
    // Logic xử lý tín hiệu giao dịch
    // ...
}

} // End namespace ApexPullback

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//--- handle click on a graphical object
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      // Call the OnClick event handler in CDashboard
      if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Dashboard != NULL)
        {
         ApexPullback::g_EAContext.Dashboard.OnClick(sparam);
        }
      // Fallback to g_Dashboard removed, g_EAContext.Dashboard should be used and checked before this point.
     }
  }

// GetDeinitReasonText đã được định nghĩa trong FunctionDefinitions.mqh

// SaveConfiguration đã được định nghĩa trong FunctionDefinitions.mqh

// Định nghĩa OnDeinit
void OnDeinit(const int reason) {
    if (ApexPullback::g_EAContext != NULL) {
        ApexPullback::g_EAContext.IsShuttingDown = true;
    } else {
        // Fallback if context is somehow null, though this shouldn't happen if OnInit was successful
        ApexPullback::g_IsShuttingDown = true; 
    }
    
    string deinit_reason_text = ApexPullback::GetDeinitReasonText(reason);
    string deinitMessage = "APEX Pullback EA v14.0 đang kết thúc. Lý do: " + deinit_reason_text;
    
    // Thêm thống kê tổng quan (sử dụng context nếu có, fallback to globals if not)
    long tickCounter = (ApexPullback::g_EAContext != NULL) ? ApexPullback::g_EAContext.TickCounter : ApexPullback::g_TickCounter;
    long errorCounter = (ApexPullback::g_EAContext != NULL) ? ApexPullback::g_EAContext.ErrorCounter : ApexPullback::g_ErrorCounter;
    int successfulTrades = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.PerformanceTracker != NULL) ? ApexPullback::g_EAContext.PerformanceTracker.GetSuccessfulTrades() : ApexPullback::g_SuccessfulTrades;
    int failedTrades = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.PerformanceTracker != NULL) ? ApexPullback::g_EAContext.PerformanceTracker.GetFailedTrades() : ApexPullback::g_FailedTrades;

    deinitMessage += " | Tổng Ticks: " + IntegerToString(tickCounter);
    deinitMessage += " | Tổng Lỗi: " + IntegerToString(errorCounter);
    deinitMessage += " | Giao dịch thành công: " + IntegerToString(successfulTrades);
    deinitMessage += " | Giao dịch thất bại: " + IntegerToString(failedTrades);

    CLogger* logger = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) ? ApexPullback::g_EAContext.Logger : NULL;

    if (logger != NULL) {
        logger.LogInfo(deinitMessage);
    } else {
        Print(deinitMessage);
    }

    // Lưu cấu hình và thống kê nếu cần
    try {
        if (SaveStatistics && ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.PerformanceTracker != NULL) {
            if (logger != NULL) logger.LogInfo("Đang lưu thống kê hiệu suất...");
            if (!ApexPullback::g_EAContext.PerformanceTracker.SavePerformanceData("PerformanceStats.csv")) {
                if (logger != NULL) logger.LogWarning("Không thể lưu thống kê hiệu suất.");
            } else {
                if (logger != NULL) logger.LogInfo("Thống kê hiệu suất đã được lưu thành công.");
            }
        }
        
        // Lưu cấu hình hiện tại (SaveConfiguration might need access to g_EAContext or its logger)
        if (ApexPullback::SaveConfiguration(ApexPullback::g_EAContext)) { // Pass context if needed
            if (logger != NULL) logger.LogInfo("Cấu hình EA đã được lưu thành công.");
        } else {
            if (logger != NULL) logger.LogWarning("Không thể lưu cấuHình EA.");
        }
    } catch(...) {
        if (logger != NULL) logger.LogError("Lỗi khi lưu cấu hình và thống kê.");
        else Print("Lỗi khi lưu cấu hình và thống kê.");
    }

    // Giải phóng các module thông qua EAContext
    try {
        if (ApexPullback::g_EAContext != NULL) {
            if (ApexPullback::g_EAContext.Dashboard != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng Dashboard..."); delete ApexPullback::g_EAContext.Dashboard; ApexPullback::g_EAContext.Dashboard = NULL; }
            if (ApexPullback::g_EAContext.TradeManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng TradeManager..."); delete ApexPullback::g_EAContext.TradeManager; ApexPullback::g_EAContext.TradeManager = NULL; }
            if (ApexPullback::g_EAContext.PositionManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng PositionManager..."); delete ApexPullback::g_EAContext.PositionManager; ApexPullback::g_EAContext.PositionManager = NULL; }
            if (ApexPullback::g_EAContext.RiskManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng RiskManager..."); delete ApexPullback::g_EAContext.RiskManager; ApexPullback::g_EAContext.RiskManager = NULL; }
            if (ApexPullback::g_EAContext.PatternDetector != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng PatternDetector..."); delete ApexPullback::g_EAContext.PatternDetector; ApexPullback::g_EAContext.PatternDetector = NULL; }
            if (ApexPullback::g_EAContext.SwingDetector != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng SwingDetector..."); delete ApexPullback::g_EAContext.SwingDetector; ApexPullback::g_EAContext.SwingDetector = NULL; }
            if (ApexPullback::g_EAContext.MarketProfile != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng MarketProfile..."); delete ApexPullback::g_EAContext.MarketProfile; ApexPullback::g_EAContext.MarketProfile = NULL; }
            // if (ApexPullback::g_EAContext.AssetProfiler != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng AssetProfiler..."); delete ApexPullback::g_EAContext.AssetProfiler; ApexPullback::g_EAContext.AssetProfiler = NULL; } // Assuming AssetProfiler is part of AssetProfileManager or distinct
            if (ApexPullback::g_EAContext.NewsFilter != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng NewsFilter..."); delete ApexPullback::g_EAContext.NewsFilter; ApexPullback::g_EAContext.NewsFilter = NULL; }
            if (ApexPullback::g_EAContext.SessionManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng SessionManager..."); delete ApexPullback::g_EAContext.SessionManager; ApexPullback::g_EAContext.SessionManager = NULL; }
            if (ApexPullback::g_EAContext.AssetProfileManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng AssetProfileManager..."); delete ApexPullback::g_EAContext.AssetProfileManager; ApexPullback::g_EAContext.AssetProfileManager = NULL; }
            if (ApexPullback::g_EAContext.PerformanceTracker != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng PerformanceTracker..."); delete ApexPullback::g_EAContext.PerformanceTracker; ApexPullback::g_EAContext.PerformanceTracker = NULL; }
            if (ApexPullback::g_EAContext.PortfolioManager != NULL) { if (logger != NULL) logger.LogDebug("Giải phóng PortfolioManager..."); delete ApexPullback::g_EAContext.PortfolioManager; ApexPullback::g_EAContext.PortfolioManager = NULL; }
            if (ApexPullback::g_EAContext.IndicatorUtils != NULL) { 
                if (logger != NULL) logger.LogDebug("Giải phóng IndicatorUtils...");
                // IndicatorUtils destructor should handle releasing its own indicators
                delete ApexPullback::g_EAContext.IndicatorUtils; ApexPullback::g_EAContext.IndicatorUtils = NULL; 
            }
        } else { // Fallback to old global deallocation if context is null - This block should ideally not be reached.
             Print("OnDeinit: EAContext was NULL. Global fallbacks for Dashboard and other managers are removed.");
        }

        // Global indicator handles and cache are now managed by CIndicatorUtils within g_EAContext.
        // Calls to ApexPullback::ReleaseIndicatorHandles() and ApexPullback::ClearIndicatorCache() are removed.

    } catch(...) {
        if (logger != NULL) logger.LogError("Lỗi trong quá trình giải phóng các module.");
        else Print("Lỗi trong quá trình giải phóng các module.");
    }

    if (logger != NULL) {
        logger.LogInfo("APEX Pullback EA v14.0 đã giải phóng tất cả các module.");
        bool enableTelegram = (ApexPullback::g_EAContext != NULL) ? ApexPullback::g_EAContext.Logger.IsTelegramEnabled() : ApexPullback::g_EnableTelegramNotify;
        if (enableTelegram) {
             logger.SendTelegramMessage("APEX Pullback EA v14.0 đã kết thúc. Lý do: " + deinit_reason_text, true);
        }
    }

    // Giải phóng Logger LÀ BƯỚC CUỐI CÙNG, if it's the one in context, it will be deleted with the context.
    // If it was the old global g_Logger and context was null, delete it here.
    try {
        if (ApexPullback::g_EAContext != NULL) {
            if (ApexPullback::g_EAContext.Logger != NULL) {
                ApexPullback::g_EAContext.Logger.Deinitialize();
                // Logger will be deleted when g_EAContext is deleted
            }
            delete ApexPullback::g_EAContext;
            ApexPullback::g_EAContext = NULL;
        } else { // If context was null and its logger was null, or old global logger was already handled/null
            Print("OnDeinit: EAContext was NULL and no fallback global logger to deinitialize.");
        }
    } catch(...) {
        Print("APEX Pullback EA v14.0 - Lỗi khi giải phóng Logger hoặc EAContext.");
    }
    
    ObjectsDeleteAll(0, -1, -1);
    ChartRedraw();
    
    Print("APEX Pullback EA v14.0 đã kết thúc hoàn toàn.");
}

//+------------------------------------------------------------------+
//| Hàm kiểm tra bộ nhớ khả dụng                                   |
//+------------------------------------------------------------------+
bool CheckMemoryAvailable() {
    // Kiểm tra bộ nhớ khả dụng (ít nhất 50MB)
    double memoryUsage = GetMemoryUsage();
    if (memoryUsage > 500.0) { // Hơn 500MB có thể có vấn đề
        Print("CẢNH BÁO: Sử dụng bộ nhớ cao: " + DoubleToString(memoryUsage, 2) + "MB");
        return false;
    }
    return true;
}

//+------------------------------------------------------------------+
//| Hàm lấy thông tin sử dụng bộ nhớ                               |
//+------------------------------------------------------------------+
double GetMemoryUsage() {
    double estimatedMemory = 0.0;
    if (ApexPullback::g_EAContext != NULL) {
        if (ApexPullback::g_EAContext.Logger != NULL) estimatedMemory += 2.0;
        if (ApexPullback::g_EAContext.Dashboard != NULL) estimatedMemory += 5.0;
        if (ApexPullback::g_EAContext.TradeManager != NULL) estimatedMemory += 3.0;
        if (ApexPullback::g_EAContext.PositionManager != NULL) estimatedMemory += 2.0;
        if (ApexPullback::g_EAContext.RiskManager != NULL) estimatedMemory += 2.0;
        if (ApexPullback::g_EAContext.MarketProfile != NULL) estimatedMemory += 4.0;
        if (ApexPullback::g_EAContext.SwingDetector != NULL) estimatedMemory += 3.0;
        if (ApexPullback::g_EAContext.IndicatorUtils != NULL) {
            // Estimate memory for IndicatorUtils, including its managed indicators
            // This is a rough estimate; IndicatorUtils could provide a more accurate GetMemoryUsage method.
            estimatedMemory += 2.0 + ApexPullback::g_EAContext.IndicatorUtils.GetManagedIndicatorCount() * 1.0; 
        }
    } else {
        // Fallback to old global estimates if context is null - This should not happen in normal operation.
        Print("GetMemoryUsage: EAContext is NULL. Cannot estimate memory accurately.");
        // Globals like g_Logger, g_Dashboard are removed, so no direct estimation here.
        // g_IndicatorCount is no longer used, CIndicatorUtils manages its own indicator counts/memory.
    }
    return estimatedMemory;
}

//+------------------------------------------------------------------+
//| Hàm log thông tin hệ thống                                     |
//+------------------------------------------------------------------+
void LogSystemInfo() {
    CLogger* logger = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext.Logger != NULL) ? ApexPullback::g_EAContext.Logger : NULL;
    if (logger == NULL) {
        Print("LogSystemInfo: Logger not available.");
        return;
    }
    
    string systemInfo = "Thông tin hệ thống: ";
    systemInfo += "Symbol: " + _Symbol;
    systemInfo += " | Timeframe: " + EnumToString(PERIOD_CURRENT);
    systemInfo += " | Digits: " + IntegerToString(_Digits);
    systemInfo += " | Point: " + DoubleToString(_Point, _Digits);
    systemInfo += " | Spread: " + DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 1);
    systemInfo += " | Server: " + AccountInfoString(ACCOUNT_SERVER);
    systemInfo += " | Build: " + IntegerToString(TerminalInfoInteger(TERMINAL_BUILD));
    
    logger.LogInfo(systemInfo);
}

} // End namespace ApexPullback


