//+------------------------------------------------------------------+
//|   APEX PULLBACK EA v14.1 - Professional Edition                  |
//|   Chiến lược EMA Pullback được tối ưu hóa với Market Profile     |
//|   Module hóa xuất sắc - Quản lý rủi ro đa tầng - EA chuẩn Prop   |
//|   Copyright 2025, APEX Forex - Mèo Cọc                           |
//+------------------------------------------------------------------+
//| APEX PULLBACK EA v14.0                                          |
//| Copyright 2023, Forex Robot Easy Team                            |
//| https://www.forexroboteasy.com                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Forex Robot Easy Team"
#property link      "https://www.forexroboteasy.com"
#property version   "14.0"
#property strict

// Khai báo các thư viện cơ bản MQL5
#include <Trade/Trade.mqh>          // Thư viện giao dịch
#include <Trade/PositionInfo.mqh>   // Thư viện quản lý vị thế
#include <Trade/SymbolInfo.mqh>     // Thư viện thông tin symbol
#include <Trade/AccountInfo.mqh>    // Thư viện thông tin tài khoản
#include <Arrays/ArrayObj.mqh>      // Thư viện mảng đối tượng
#include <Charts/Chart.mqh>         // Thư viện biểu đồ

//+------------------------------------------------------------------+
//| Includes & Modules                                               |
//+------------------------------------------------------------------+

// 1. Các file định nghĩa cơ bản
#include "Enums.mqh"                       // Các enum
#include "CommonStructs.mqh"               // Các cấu trúc dữ liệu
#include "Inputs.mqh"                      // Các tham số đầu vào

// Forward declarations cho các class trong namespace ApexPullback
namespace ApexPullback {
    class CLogger;
    class CMarketProfile;
    class CAssetProfileManager;
    class CAssetProfiler;
    class CPatternDetector;
    class CSwingPointDetector;
    class CSwingDetector;
    class CPositionManager;
    class CTradeManager;
    class CRiskManager;
    class CPerformanceTracker;
    class CSessionManager;
    class CDashboard;
    class CNewsFilter;
    class CRiskOptimizer;
    class CIndicatorUtils;
}

// Bắt đầu implementation EA

// Sử dụng cách này thay vì using namespace để tránh xung đột
// Định nghĩa các enum cần thiết cho EA
enum ENUM_SESSION_TYPE {
    SESSION_ASIAN,       // Phiên Á (Tokyo)
    SESSION_EUROPEAN,    // Phiên Âu (London)
    SESSION_AMERICAN     // Phiên Mỹ (New York)
};

// Helper functions for finding highest and lowest prices
double FindHighest(int count) {
    double highest = DBL_MIN;
    for (int i = 0; i < count; i++) {
        double high = iHigh(Symbol(), Period(), i);
        if (high > highest) highest = high;
    }
    return highest;
}

double FindLowest(int count) {
    double lowest = DBL_MAX;
    for (int i = 0; i < count; i++) {
        double low = iLow(Symbol(), Period(), i);
        if (low < lowest) lowest = low;
    }
    return lowest;
}

ENUM_SESSION_TYPE DetermineSession(datetime time) {
    // Xác định phiên giao dịch dựa vào thời gian
    MqlDateTime dt;
    TimeToStruct(time, dt);
    int hour = dt.hour;
    
    if (hour >= 0 && hour < 8) {
        return SESSION_ASIAN;
    } else if (hour >= 8 && hour < 16) {
        return SESSION_EUROPEAN;
    } else {
        return SESSION_AMERICAN;
    }
}

// 2. Các module cơ bản
#include "Logger.mqh"                      // Bộ ghi log
#include "IndicatorUtils.mqh"              // Tiện ích indicator
#include "NewsFilter.mqh"                  // Bộ lọc tin tức

// 3. Các module phân tích thị trường
#include "MarketProfile.mqh"               // Phân tích Market Profile
#include "SwingPointDetector.mqh"          // Phát hiện Swing
#include "PatternDetector.mqh"             // Phát hiện mẫu hình

// 4. Các module quản lý giao dịch
#include "RiskManager.mqh"                 // Quản lý rủi ro
#include "PositionManager.mqh"             // Quản lý vị thế
#include "TradeManager.mqh"                // Quản lý giao dịch
#include "RiskOptimizer.mqh"               // Tối ưu hóa rủi ro

// 5. Các module bổ sung
#include "Dashboard.mqh"                   // Bảng thông tin
#include "PerformanceTracker.mqh"          // Theo dõi hiệu suất
#include "SessionManager.mqh"              // Quản lý phiên giao dịch
#include "AssetProfileManager.mqh"         // Quản lý hồ sơ tài sản
#include "AssetProfiler.mqh"               // Hồ sơ tài sản

// 5. Include file inputs ở đây để các biến input được khai báo sau các module
#include "Inputs.mqh"                      // Các tham số đầu vào

// Forward declarations for classes to fix "expected a type specifier" errors
namespace ApexPullback {
    class CLogger;
    class CMarketProfile;
    class CAssetProfileManager;
    class CPatternDetector;
    class CSwingPointDetector;
    class CPositionManager;
    class CTradeManager;
    class CRiskManager;
    class CPerformanceTracker;
    class CSessionManager;
    class CDashboard;
    class CNewsFilter;
}

// Khai báo các biến toàn cục cho các đối tượng

// --- Khai báo biến toàn cục tham chiếu đến các input ---
// Các biến từ "THÔNG TIN CHUNG"
extern string EAName;             // Tên EA
extern string EAVersion;          // Phiên bản
extern int MagicNumber;           // Magic Number
extern string OrderComment;       // Ghi chú lệnh
extern bool AllowNewTrades;       // Cho phép vào lệnh mới

// Các biến từ "HIỂN THỊ & THÔNG BÁO"
extern bool EnableDetailedLogs;   // Bật log chi tiết
extern bool EnableCsvLog;         // Ghi log vào file CSV
extern string CsvLogFilename;     // Tên file CSV log
extern bool DisplayDashboard;     // Hiển thị dashboard
extern ENUM_DASHBOARD_THEME DashboardTheme; // Chủ đề Dashboard
extern bool AlertsEnabled;        // Bật cảnh báo
extern bool SendNotifications;    // Gửi thông báo đẩy
extern bool SendEmailAlerts;      // Gửi email
extern bool EnableTelegramNotify; // Bật thông báo Telegram
extern string TelegramBotToken;   // Token Bot Telegram
extern string TelegramChatID;     // ID Chat Telegram
extern bool TelegramImportantOnly; // Chỉ gửi thông báo quan trọng
extern bool DisableDashboardInBacktest; // Tắt dashboard trong backtest

// Các biến từ "CHIẾN LƯỢC CỐT LÕI"
extern ENUM_TIMEFRAMES MainTimeframe; // Khung thời gian chính
extern int EMA_Fast;              // EMA nhanh
extern int EMA_Medium;            // EMA trung bình
extern int EMA_Slow;              // EMA chậm
extern bool UseMultiTimeframe;    // Sử dụng đa khung thời gian
extern ENUM_TIMEFRAMES HigherTimeframe; // Khung thời gian cao hơn
extern ENUM_TREND_TYPE TrendDirection; // Hướng xu hướng giao dịch

// Các biến từ "ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO"
extern bool EnablePriceAction;    // Kích hoạt xác nhận Price Action
extern bool EnableSwingLevels;    // Sử dụng Swing Levels
extern double MinPullbackPercent; // % Pullback tối thiểu
extern double MaxPullbackPercent; // % Pullback tối đa
extern bool RequirePriceActionConfirmation; // Yêu cầu xác nhận Price Action
extern bool RequireMomentumConfirmation; // Yêu cầu xác nhận Momentum
extern bool RequireVolumeConfirmation; // Yêu cầu xác nhận Volume

// Các biến từ "BỘ LỌC THỊ TRƯỜNG"
extern bool EnableMarketRegimeFilter; // Bật lọc Market Regime
extern bool EnableVolatilityFilter; // Lọc biến động bất thường
extern bool EnableAdxFilter;      // Lọc ADX
extern double MinAdxValue;        // Giá trị ADX tối thiểu
extern double MaxAdxValue;        // Giá trị ADX tối đa
extern double VolatilityThreshold; // Ngưỡng biến động (xATR)
extern ENUM_MARKET_PRESET MarketPreset; // Preset thị trường
extern double MaxSpreadPoints;    // Spread tối đa (points)

// Các biến từ "QUẢN LÝ RỦI RO"
extern double RiskPercent;        // Risk % mỗi lệnh
extern double SL_ATR;             // Hệ số ATR cho Stop Loss
extern double TP_RR;              // Tỷ lệ R:R cho Take Profit
extern bool PropFirmMode;         // Chế độ Prop Firm
extern double DailyLossLimit;     // Giới hạn lỗ ngày (%)
extern double MaxDrawdown;        // Drawdown tối đa (%)
extern int MaxTradesPerDay;       // Số lệnh tối đa/ngày
extern int MaxConsecutiveLosses;  // Số lần thua liên tiếp tối đa
extern int MaxPositions;          // Số vị thế tối đa

// Các biến từ "ĐIỀU CHỈNH RISK THEO DRAWDOWN"
extern double DrawdownReduceThreshold; // Ngưỡng DD để giảm risk (%)
extern bool EnableTaperedRisk;    // Giảm risk từ từ (không đột ngột)
extern double MinRiskMultiplier;  // Hệ số risk tối thiểu khi DD cao

// Các biến từ "QUẢN LÝ VỊ THẾ"
extern ENUM_ENTRY_MODE EntryMode; // Chế độ vào lệnh
extern bool UsePartialClose;      // Sử dụng đóng từng phần
extern double PartialCloseR1;     // R-multiple cho đóng phần 1
extern double PartialCloseR2;     // R-multiple cho đóng phần 2
extern double PartialClosePercent1; // % đóng ở mức R1
extern double PartialClosePercent2; // % đóng ở mức R2

// Các biến từ "TRAILING STOP"
extern bool UseAdaptiveTrailing;  // Trailing thích ứng theo regime
extern ENUM_TRAILING_MODE TrailingMode; // Chế độ trailing mặc định
extern double TrailingAtrMultiplier; // Hệ số ATR cho trailing
extern double BreakEvenAfterR;   // Chuyển BE sau (R-multiple)
extern double BreakEvenBuffer;    // Buffer cho breakeven (points)

// Các biến từ "CHANDELIER EXIT"
extern bool UseChandelierExit;    // Kích hoạt Chandelier Exit
extern int ChandelierPeriod;      // Số nến lookback Chandelier
extern double ChandelierMultiplier; // Hệ số ATR Chandelier

// Các biến từ "SCALING (NHỒI LỆNH)"
extern bool EnableScaling;        // Cho phép nhồi lệnh
extern int MaxScalingCount;       // Số lần nhồi tối đa
extern double ScalingRiskPercent; // % risk cho lệnh nhồi (so với ban đầu)
extern bool RequireBreakEvenForScaling; // Yêu cầu BE trước khi nhồi

// Các biến từ "LỌC PHIÊN"
extern bool FilterBySession;      // Kích hoạt lọc theo phiên
extern ENUM_SESSION_FILTER SessionFilter; // Phiên giao dịch
extern bool UseGmtOffset;         // Sử dụng điều chỉnh GMT
extern int GmtOffset;             // Điều chỉnh GMT (giờ)
extern bool TradeLondonOpen;      // Giao dịch mở cửa London
extern bool TradeNewYorkOpen;     // Giao dịch mở cửa New York

// Các biến từ "LỌC TIN TỨC"
extern ENUM_NEWS_FILTER NewsFilter; // Mức lọc tin tức
extern string NewsDataFile;       // File dữ liệu tin tức
extern int NewsImportance;        // Độ quan trọng tin (1-3)
extern int MinutesBeforeNews;    // Phút trước tin tức
extern int MinutesAfterNews;     // Phút sau tin tức

// Các biến từ "TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC"
extern bool EnableAutoPause;      // Bật tự động tạm dừng
extern double VolatilityPauseThreshold; // Ngưỡng biến động để tạm dừng (xATR)
extern double DrawdownPauseThreshold; // Ngưỡng DD để tạm dừng (%)
extern bool EnableAutoResume;     // Bật tự động khôi phục
extern int PauseDurationMinutes;  // Thời gian tạm dừng (phút)
extern bool ResumeOnLondonOpen;   // Tự động khôi phục vào London Open

// Các biến từ "ASSETPROFILER - MODULE MỚI"
extern bool UseAssetProfiler;     // Kích hoạt AssetProfiler
extern int AssetProfileDays;      // Số ngày phân tích tài sản
extern bool AdaptRiskByAsset;     // Tự động điều chỉnh risk theo tài sản
extern bool AdaptSLByAsset;       // Tự động điều chỉnh SL theo tài sản
extern bool AdaptSpreadFilterByAsset; // Tự động lọc spread theo tài sản

// Thêm các biến thiếu và cần dùng trong code
int UpdateFrequencySeconds = 5;   // Tần suất cập nhật trong giây
bool SaveStatistics = true;       // Lưu số liệu thống kê
bool IsNewBar = false;            // Kiểm tra nến mới
bool StrictPriceAction = true;    // Yêu cầu PA nghiêm ngặt
bool RequireSwingStructure = true; // Yêu cầu cấu trúc swing
bool SkipVolatilityCheck = false; // Bỏ qua kiểm tra biến động
bool EnableAssetProfile = true;   // Kích hoạt hồ sơ tài sản
bool EnableRiskEventNotify = true; // Thông báo sự kiện rủi ro
bool EnableIndicatorCache = true;  // Bật cache chỉ báo

// Thêm các biến toàn cục quan trọng
double g_MinPullbackPct = 0.3;     // % tối thiểu cho pullback
double g_MaxPullbackPct = 0.7;     // % tối đa cho pullback
int LookbackBars = 100;           // Số nền nhìn lại

// Định nghĩa các enum cần thiết
// Sử dụng ENUM_SESSION đã có trong SessionManager.mqh nhưng thêm alias ENUM_SESSION_TYPE để tương thích
typedef ENUM_SESSION ENUM_SESSION_TYPE;

// Tương thích giữa các enum
#define MARKET_TREND_UNKNOWN TREND_NONE
#define MARKET_TREND_UP TREND_UP
#define MARKET_TREND_DOWN TREND_DOWN
#define MARKET_TREND_RANGING TREND_SIDEWAY
#define MARKET_TREND_SIDEWAYS TREND_SIDEWAY

// Các module chính của EA - Chỉ khai báo một lần ở phần sau

// Các tham số cho EA
bool UseMarketProfile = true;                      // Sử dụng Market Profile
bool EnableDetailedLogs = false;                   // Bật log chi tiết
double EnvF = 2.0;                                 // Hệ số môi trường
double SL_ATR = 1.5;                               // Hệ số ATR cho SL
double TP_RR = 1.5;                                // Tỷ lệ R:R cho TP
double MaxSpreadPoints = 5.0;     // Spread tối đa cho phép

// Các đối tượng toàn cục
bool g_Initialized = false;       // Đánh dấu đã khởi tạo EA
bool g_IsBacktestMode = false;    // Đánh dấu đang backtest
int g_ConsecutiveLosses = 0;      // Số lần thua liên tiếp
datetime g_PauseEndTime = 0;      // Thời gian kết thúc tạm dừng
double g_RegimeTransitionScore = 0.0; // Điểm chuyển đổi chế độ
int g_ConsecutiveRegimeConfirm = 0;  // Số lần xác nhận chế độ liên tiếp
ENUM_EA_STATE g_CurrentState = STATE_INIT; // Trạng thái hiện tại của EA

// Modules và thành phần - sử dụng namespace để tham chiếu các lớp
// Chỉ sử dụng các biến g_* với namespace ApexPullback
// Tất cả các global class pointers đều sử dụng namespace ApexPullback để tránh xung đột
ApexPullback::CLogger* g_Logger = NULL;                         // Logger để ghi log
ApexPullback::CAssetProfileManager* g_AssetProfileManager = NULL; // Quản lý hồ sơ tài sản
MarketProfileData g_CurrentProfile;     // Profile hiện tại
double g_VolatilityThreshold = 2.0;    // Ngưỡng biến động

//+------------------------------------------------------------------+
//| Sử dụng các enum từ Enums.mqh                                  |
//+------------------------------------------------------------------+

// Các enum đã được định nghĩa trong Enums.mqh, không cần định nghĩa lại ở đây
// Sử dụng MarketProfileData từ CommonStructs.mqh

// Enum trạng thái EA được định nghĩa đầy đủ trong Enums.mqh
// Đây là tham chiếu:
// enum ENUM_EA_STATE {
//     STATE_INIT,       // Khởi tạo
//     STATE_TRADING,    // Đang giao dịch
//     STATE_MONITORING, // Đang giám sát
//     STATE_PAUSED,     // Tạm dừng
//     STATE_STOPPED     // Đã dừng
// };

// Sử dụng enum ENUM_TREND_TYPE từ file Enums.mqh, không định nghĩa lại ở đây

//+------------------------------------------------------------------+
//| Sử dụng cấu trúc dữ liệu từ CommonStructs.mqh                  |
//+------------------------------------------------------------------+
// Các enum và struct đã được định nghĩa trong các file include
// ENUM_SESSION_TYPE, MarketProfileData...

// Enum cho hướng tín hiệu
enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_NONE = 0,        // Không có tín hiệu
    SIGNAL_BUY = 1,          // Tín hiệu mua
    SIGNAL_SELL = -1,        // Tín hiệu bán
    SIGNAL_EXIT              // Tín hiệu thoát
};

// Cấu trúc kết quả phân tích mẫu hình
struct PatternAnalysisResult {
    bool patternDetected;    // Phát hiện mẫu hình
    string patternName;      // Tên mẫu hình
    double patternStrength;   // Độ mạnh của mẫu hình
    double expectedMove;      // Dự đoán biên độ di chuyển
    ENUM_SIGNAL_DIRECTION direction; // Hướng của mẫu hình
};

// Enum cho các loại môi trường thị trường
enum ENUM_MARKET_PRESET {
    PRESET_UNKNOWN,         // Unknown market condition
    PRESET_TRENDING,        // Trending market
    PRESET_RANGING,         // Ranging/Sideways market
    PRESET_VOLATILE,        // Volatile market
    PRESET_BREAKOUT,        // Breakout market
    PRESET_REVERSAL,        // Reversal market
    PRESET_MOMENTUM,        // Momentum-driven market
    PRESET_COUNTER_TREND    // Counter-trend market
};

//+------------------------------------------------------------------+
//| Khai báo biến và đối tượng toàn cục                              |
//+------------------------------------------------------------------+
// Modules và thành phần
ApexPullback::CLogger *g_Logger = NULL;               // Module ghi log
ApexPullback::CMarketProfile *g_MarketProfile = NULL; // Phân tích thị trường
ApexPullback::CSwingPointDetector *g_SwingDetector = NULL; // Phát hiện swing
ApexPullback::CSessionManager *g_SessionManager = NULL; // Quản lý phiên
ApexPullback::CPatternDetector *g_PatternDetector = NULL; // Phát hiện mẫu hình
ApexPullback::CRiskManager *g_RiskManager = NULL;     // Quản lý rủi ro
ApexPullback::CTradeManager *g_TradeManager = NULL;   // Quản lý giao dịch
ApexPullback::CPositionManager *g_PositionManager = NULL; // Quản lý vị thế
ApexPullback::CRiskOptimizer *g_RiskOptimizer = NULL; // Tối ưu hóa rủi ro
ApexPullback::CDashboard *g_Dashboard = NULL;        // Dashboard hiển thị
ApexPullback::CPerformanceTracker *g_PerformanceTracker = NULL; // Theo dõi hiệu suất
ApexPullback::CAssetProfiler *g_AssetProfiler = NULL; // Quản lý hồ sơ tài sản
ApexPullback::CNewsFilter *g_NewsFilter = NULL;       // Bộ lọc tin tức
ApexPullback::CSessionManager *g_SessionManager = NULL; // Quản lý phiên giao dịch
// Already declared above // Quản lý hồ sơ tài sản
// Biến trạng thái EA
bool                 g_Initialized = false;            // Đã khởi tạo xong chưa
bool                 g_IsTradeAllowed = false;        // Có được phép giao dịch không
datetime             g_lastProfileTime = 0;           // Thời gian cập nhật Market Profile gần nhất
bool                 g_NewBar = false;                // Có nến mới không
ENUM_EA_STATE        g_CurrentState = STATE_INIT;      // Trạng thái hiện tại của EA
bool                 EnableAdaptiveThresholds = true;  // Bật tính năng tự động điều chỉnh ngưỡng
bool                 EnableMomentumConfirmation = true; // Bật xác nhận theo momentum
int                  MinimumTradesForProfile = 100;   // Số giao dịch tối thiểu để xây dựng profile
double               ProfileAdaptPercent = 30.0;      // Phần trăm điều chỉnh profile

// Biến cho RSI và các chỉ báo
double               rsiBuffer[];                     // Mảng lưu trữ giá trị RSI
int                  rsiHandle = INVALID_HANDLE;       // Handle cho chỉ báo RSI
bool                 hasHigherHighs = false;          // Có đỉnh cao hơn không
bool                 hasHigherLows = false;           // Có đáy cao hơn không

// Dữ liệu và cấu trúc
MarketProfileData    g_CurrentProfile;                // Profile hiện tạiị trường hiện tại
datetime             g_LastUpdateTime = 0;             // Thời gian cập nhật cuối
datetime             g_LastTradeTime = 0;              // Thời gian giao dịch cuối
datetime             g_PauseEndTime = 0;               // Thời gian kết thúc tạm dừng
int                  g_CurrentDay = 0;                 // Ngày hiện tại
int                  g_DayTrades = 0;                  // Số lệnh trong ngày
double               g_DayStartEquity = 0.0;           // Equity đầu ngày
double               g_AverageATR = 0.0;               // ATR trung bình theo ngày
double               g_CurrentRisk = 0.0;              // Risk % hiện tại
int                  g_ConsecutiveLosses = 0;          // Số lần thua liên tiếp
bool                 g_IsBacktestMode = false;         // Đang chạy backtest?
double               g_RegimeTransitionScore = 0.0;    // Điểm chuyển tiếp chế độ
int                  g_ConsecutiveRegimeConfirm = 0;   // Số lần xác nhận chế độ liên tiếp
double               g_SpreadHistory[10];              // Lịch sử spread gần đây
double               g_AverageSpread = 0.0;            // [NEW] Spread trung bình
int                  g_IndicatorCache[10];             // [NEW] Cache cho handles chỉ báo
bool                 g_RequirePriceActionConfirm = true; // [NEW] Yêu cầu PA xác nhận

//+------------------------------------------------------------------+
//| Khai báo thêm các biến toàn cục                                 |
//+------------------------------------------------------------------+
// Các biến bổ sung có thể được thêm vào đây nếu cần
// Các biến input đã được khai báo trong file Inputs.mqh

// Lưu ý: Không khai báo lại các tham số input ở đây 
// Tất cả tham số đã được khai báo trong file Inputs.mqh

// Các biến toàn cục bổ sung
double g_MinPullbackPct = 0.3;     // Tỷ lệ pullback tối thiểu (phần trăm)
double g_MaxPullbackPct = 0.7;     // Tỷ lệ pullback tối đa (phần trăm)
int LookbackBars = 50;            // Số nến nhìn lại
int MaxSpreadPoints = 50;         // Spread tối đa cho phép (theo điểm)
double EnvF = 0.05;               // Hệ số mở rộng mội trường
double SL_ATR = 1.5;              // Hệ số ATR cho StopLoss
double TP_RR = 2.0;               // Risk Reward cho TakeProfit
double g_VolatilityThreshold = 1.5; // Ngưỡng biến động cao
bool EnableDetailedLogs = false;   // Bật ghi log chi tiết

// Ghi chú: các biến trạng thái đã được khai báo ở phần trên
input double   PartialClosePercent1 = 35.0;           // % đóng ở mức R1
input double   PartialClosePercent2 = 35.0;           // % đóng ở mức R2

// Tham số trailing stop
input string g_TrailingStopGroup = "=== TRAILING STOP ==="; // Nhóm Trailing Stop
input bool     UseAdaptiveTrailing = true;            // Trailing thích ứng theo regime
input ENUM_TRAILING_MODE TrailingMode = TRAILING_ATR; // Chế độ trailing mặc định
input double   TrailingAtrMultiplier = 2.0;           // Hệ số ATR cho trailing
input double   BreakEvenAfterR = 1.0;                 // Chuyển BE sau (R-multiple)
input double   BreakEvenBuffer = 5.0;                 // Buffer cho breakeven (points)

// Tham số cho Chandelier Exit
input string g_ChandelierExitGroup = "=== CHANDELIER EXIT ==="; // Nhóm Chandelier Exit
input bool     UseChandelierExit = true;              // Kích hoạt Chandelier Exit
input int      ChandelierPeriod = 20;                 // Số nến lookback Chandelier
input double   ChandelierMultiplier = 3.0;            // Hệ số ATR Chandelier

// Tham số scaling (nhồi lệnh)
input string g_ScalingGroup = "=== SCALING (NHỒI LỆNH) ==="; // Nhóm Scaling
input bool     EnableScaling = false;                 // [UPDATED] Cho phép nhồi lệnh (tắt mặc định)
input int      MaxScalingCount = 1;                   // Số lần nhồi tối đa
input double   ScalingRiskPercent = 0.3;              // % risk cho lệnh nhồi (so với ban đầu)
input bool     RequireBreakEvenForScaling = true;     // Yêu cầu BE trước khi nhồi
input double   MinAdxForScaling = 25.0;               // [NEW] ADX tối thiểu cho scaling
input bool     RequireConfirmedTrend = true;          // [NEW] Yêu cầu xu hướng xác nhận để scaling

// Tham số lọc theo phiên
input string g_SessionFilterGroup = "=== LỌC PHIÊN ==="; // Nhóm Lọc Phiên
input bool     FilterBySession = false;               // Kích hoạt lọc theo phiên
//| Khai báo các hàm chính                                           |
//+------------------------------------------------------------------+
// Khởi tạo và dọn dẹp
bool        InitializeModules();
void        CleanupModules();
bool        LoadConfiguration();
void        SaveConfiguration();

// Quản lý EA và thông báo
void        UpdateEAState();
void        ManageEAState();
void        LogMessage(string message, bool important = false);
void        SendAlert(string message, bool isImportant = false);
string      GetStateDescription(ENUM_EA_STATE state);

// Phân tích thị trường
bool        UpdateMarketData();
MarketProfileData AnalyzeMarketProfile();
bool        IsMarketConditionSuitable();
bool        IsPullbackValid(bool isLong);
bool        IsPriceActionConfirmed(bool isLong);
double      CalculateSignalQuality(SignalInfo &signal);

// [NEW] Thêm kiểm tra momentum và cấu trúc swing
bool        IsMomentumConfirmed(bool isLong);
double      GetRSISlope(int period = 14);
double      GetMACDHistogramSlope();
bool        HasValidSwingStructure(bool isLong);

// Xử lý vào lệnh
void        CheckNewTradeOpportunities();
SignalInfo  DetectPullbackSignal();
bool        ValidateTradeConditions(SignalInfo &signal);
double      CalculateAdaptiveRiskPercent();
double      CalculateLotSize(double riskPercent, double slPoints);

// Quản lý vị thế
void        ManageOpenPositions();
double      CalculateDynamicTrailingStop(ulong ticket, double entryPrice, double currentPrice, bool isLong);
double      CalculateChandelierExit(bool isLong, int period, double multiplier);
double      CalculateSwingBasedTrailingStop(bool isLong);
bool        CheckPartialCloseConditions(ulong ticket, double entryPrice, double currentPrice, bool isLong);
bool        ShouldScaleInPosition(ulong ticket);

// Quản lý rủi ro và bảo vệ
bool        IsSpreadAcceptable();
bool        IsVolatilityAcceptable();
bool        IsNewsTimeFilter();
bool        IsSessionActive();
void        UpdateDailyStats();
void        CheckDrawdownProtection();
double      GetAverageATR();
void        UpdateAtrHistory();
double      GetAdaptiveMaxSpread();
void        UpdateSpreadHistory();
double      GetAdaptiveVolatilityThreshold();   // [NEW] Thích ứng ngưỡng biến động

// Hiển thị và tiện ích
void        UpdateDashboard();
void        DrawValueZones();
string      TimeframeToString(ENUM_TIMEFRAMES tf);
string      GetDeinitReasonText(const int reason);

// Asset Profile (tự học)
void        UpdateAssetProfile(bool win, double profit, string scenario);
bool        AdjustSignalByAssetProfile(SignalInfo &signal);

// [NEW] Tối ưu hóa hiệu suất
void        InitializeIndicatorCache();
void        ClearIndicatorCache();
int         GetIndicatorHandle(int indicatorType, string symbol, ENUM_TIMEFRAMES timeframe);
bool        ShouldUpdateCalculations(datetime currentTime);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("APEX Pullback EA v15.0 - Đang khởi tạo trên ", _Symbol);
    
    // Kiểm tra nếu đang ở chế độ backtest
    g_IsBacktestMode = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION));
    
    // Khởi tạo trạng thái EA
    g_CurrentState = STATE_INIT;
    
    // Khởi tạo Logger - module quan trọng nhất, phải khởi tạo đầu tiên
    g_Logger = new ApexPullback::CLogger();
    if (g_Logger == NULL) {
        Print("LỖI: Không thể tạo Logger - bộ nhớ không đủ");
        return INIT_FAILED;
    }
    
    if (!g_Logger.Initialize("ApexPullbackV15", EnableDetailedLogs, EnableCsvLog, CsvLogFilename, 
                           EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
        Print("LỖI: Không thể khởi tạo Logger");
        return INIT_FAILED;
    }
    
    // Ghi log bắt đầu quá trình khởi tạo
    LogMessage("APEX Pullback EA v15.0 - Bắt đầu khởi tạo trên " + _Symbol, true);
    
    // Lấy ngày hiện tại và equity ban đầu
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    g_CurrentDay = time.day;
    g_DayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_CurrentRisk = RiskPercent; // Risk ban đầu
    
    // Khởi tạo mảng lưu trữ spread
    for (int i = 0; i < 10; i++) {
        g_SpreadHistory[i] = 0;
    }
    
    // [NEW] Khởi tạo cache chỉ báo
    InitializeIndicatorCache();
    
    // Khởi tạo các module chính
    if (!InitializeModules()) {
        LogMessage("LỖI: Không thể khởi tạo các module chính", true);
        CleanupModules(); // Dọn dẹp nếu khởi tạo thất bại
        return INIT_FAILED;
    }
    
    // Nạp cấu hình
    if (!LoadConfiguration()) {
        LogMessage("CẢNH BÁO: Không thể nạp cấu hình, sử dụng giá trị mặc định", true);
    }
    
    // Cập nhật ATR trung bình và dữ liệu thị trường
    UpdateAtrHistory();
    if (!UpdateMarketData()) {
        LogMessage("CẢNH BÁO: Cập nhật dữ liệu thị trường không thành công", true);
    }
    
    // Cập nhật spread trung bình
    UpdateSpreadHistory();
    
    // Tạo Dashboard nếu được bật
    if (DisplayDashboard && (!g_IsBacktestMode || !DisableDashboardInBacktest)) {
        LogMessage("Tạo Dashboard hiển thị...");
        g_Dashboard = new ApexPullback::CDashboard();
        if (g_Dashboard != NULL) {
            g_Dashboard.Initialize(_Symbol, OrderComment);
            g_Dashboard.Update(g_CurrentProfile);
        } else {
            LogMessage("CẢNH BÁO: Không thể tạo Dashboard", true);
        }
    }
    
    // Thiết lập timer cho xử lý nền
    if (!g_IsBacktestMode) {
        EventSetTimer(60); // Cập nhật mỗi 60 giây
        LogMessage("Đã thiết lập timer cho xử lý nền");
    }
    
    // Cập nhật trạng thái EA
    g_CurrentState = STATE_RUNNING;
    g_Initialized = true;
    
    // Lưu thời gian khởi tạo
    g_LastUpdateTime = TimeCurrent();
    
    // Cập nhật lần cuối
    UpdateEAState();
    UpdateDashboard();
    
    LogMessage("APEX Pullback EA v15.0 đã khởi tạo thành công", true);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Lưu thống kê nếu được cấu hình
    if (g_Initialized && SaveStatistics) {
        SaveConfiguration();
    }
    
    // Ghi log lý do kết thúc
    LogMessage("Dừng EA - Lý do: " + GetDeinitReasonText(reason), true);
    
    // Hủy timer
    EventKillTimer();
    
    // [NEW] Xóa cache chỉ báo
    ClearIndicatorCache();
    
    // Xóa dashboard nếu có
    if (g_Dashboard != NULL) {
        g_Dashboard.Clear();
    }
    
    // Dọn dẹp các đối tượng
    CleanupModules();
    
    // Đặt trạng thái đã kết thúc
    g_Initialized = false;
    
    Print("APEX Pullback EA v15.0 đã kết thúc");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Kiểm tra EA đã khởi tạo chưa
    if (!g_Initialized) return;
    
    // Kiểm tra tần suất xử lý (không xử lý quá nhiều)
    static uint lastBarTime = 0;
    uint currentBarTime = (uint)iTime(_Symbol, MainTimeframe, 0);
    
    // Kiểm tra nến mới
    bool isNewBar = false;
    if (currentBarTime != lastBarTime) {
        isNewBar = true;
        lastBarTime = currentBarTime;
    }
    
    if (!g_IsBacktestMode && !isNewBar) {
        // Giới hạn tần suất xử lý trong thởi gian thực
        static datetime lastProcessTime = 0;
        datetime currentTime = TimeCurrent();
        
        // [UPDATED] Sử dụng tham số tần suất cập nhật
        if (currentTime - lastProcessTime < UpdateFrequencySeconds)
            return;
        
        lastProcessTime = currentTime;
    }
    lastBarTime = currentBarTime;
    
    // Cập nhật thống kê ngày
    UpdateDailyStats();
    
    // Quản lý trạng thái EA
    UpdateEAState();
    ManageEAState();
    
    // Nếu đang tạm dừng, skip xử lý chính
    if (g_CurrentState == STATE_PAUSED) {
        // Kiểm tra nếu đã hết thởi gian tạm dừng
        if (TimeCurrent() >= g_PauseEndTime) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục hoạt động sau thởi gian tạm dừng", true);
            UpdateEAState();
        } else {
            // Vẫn đang trong thởi gian tạm dừng
            return;
        }
    }
    
    // Kiểm tra các điều kiện thị trường
    if (!IsSpreadAcceptable()) {
        LogMessage("Spread hiện tại không phù hợp: " + 
                 DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 1) + " điểm");
        return;
    }
    
    if (FilterBySession && !IsSessionActive()) {
        LogMessage("Không phải phiên giao dịch đã cấu hình");
        return;
    }
    
    if (NewsFilter != NEWS_NONE && IsNewsTimeFilter()) {
        LogMessage("Có tin tức quan trọng sắp diễn ra");
        return;
    }
    
    // Cập nhật dữ liệu thị trường nhẹ nhàng
    static datetime lastMarketUpdateTime = 0;
    datetime currentTime = TimeCurrent();
    // Sử dụng namespace để tránh lỗi ambiguous
    bool isNewBar = ApexPullback::IsNewBar();
    
    // [UPDATED] Sử dụng ShouldUpdateCalculations để giảm tính toán
    if (isNewBar || ShouldUpdateCalculations(lastMarketUpdateTime)) {
        if (UpdateMarketData()) {
            lastMarketUpdateTime = currentTime;
        }
    }
    
    // Quản lý vị thế đang mở
    ManageOpenPositions();
    
    // Kiểm tra điều kiện vào lệnh mới
    int positions = g_TradeManager.CountPositions();
    if (AllowNewTrades && positions < MaxPositions) {
        if (g_DayTrades < MaxTradesPerDay || !PropFirmMode) {
            CheckNewTradeOpportunities();
        } else {
            LogMessage("Đã đạt giới hạn lệnh trong ngày: " + IntegerToString(g_DayTrades) + 
                     "/" + IntegerToString(MaxTradesPerDay));
        }
    }
    
    // Cập nhật Dashboard nếu có
    if (g_Dashboard != NULL && DisplayDashboard) {
        static datetime lastDashboardUpdate = 0;
        if (currentTime - lastDashboardUpdate > 2) { // Cập nhật mỗi 2 giây
            g_Dashboard.Update(g_CurrentProfile);
            lastDashboardUpdate = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    // Trong chế độ backtest, không cần xử lý timer
    if (g_IsBacktestMode) return;
    
    // Xử lý cập nhật nền ít tốn tài nguyên
    static datetime lastTimerUpdate = 0;
    datetime currentTime = TimeCurrent();
    
    // Chỉ xử lý mỗi 60 giây
    if (currentTime - lastTimerUpdate < 60)
        return;
    
    lastTimerUpdate = currentTime;
    
    // Cập nhật dữ liệu thị trường nếu cần
    if (ShouldUpdateCalculations(g_LastUpdateTime)) {
        UpdateMarketData();
        g_LastUpdateTime = currentTime;
    }
    
    // Cập nhật ATR trung bình nếu là thứ 2 đầu tuần
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    static int lastUpdateDay = -1;
    if (dt.day_of_week == 1 && dt.day != lastUpdateDay) {
        UpdateAtrHistory();
        UpdateSpreadHistory();
        lastUpdateDay = dt.day;
    }
    
    // Cập nhật tin tức nếu sử dụng bộ lọc tin
    if (::NewsFilter != NEWS_NONE && g_NewsFilter != NULL) {
        g_NewsFilter.UpdateNews();
    }
    
    // Kiểm tra bảo vệ DD
    CheckDrawdownProtection();
    
    // Cập nhật Dashboard
    if (g_Dashboard != NULL && DisplayDashboard) {
        g_Dashboard.Update(g_CurrentProfile);
    }
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
    // Cho TradeManager xử lý giao dịch
    if (g_TradeManager != NULL) {
        g_TradeManager.ProcessTransaction(trans, request, result);
    }
    
    // Xử lý khi có lệnh đóng
    if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal > 0) {
        // Chỉ xử lý giao dịch thuộc EA này
        if (HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == MagicNumber && 
            HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            
            // Lấy thông tin lệnh
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            bool isWin = (profit > 0);
            
            // Xử lý comment để lấy scenario
            string dealComment = HistoryDealGetString(trans.deal, DEAL_COMMENT);
            string scenario = ""; 
            
            // Cố gắng trích xuất scenario từ comment
            if (StringFind(dealComment, "SCENARIO=") >= 0) {
                int startPos = StringFind(dealComment, "SCENARIO=") + 9;
                int endPos = StringFind(dealComment, ";", startPos);
                if (endPos < 0) endPos = StringLen(dealComment);
                
                scenario = StringSubstr(dealComment, startPos, endPos - startPos);
            } else {
                scenario = "PULLBACK"; // Mặc định
            }
            
            // Cập nhật thống kê
            if (isWin) {
                g_ConsecutiveLosses = 0;
                LogMessage("Lệnh đóng lãi: " + DoubleToString(profit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY), true);
                
                // Cập nhật Asset Profile nếu bật
                if (EnableAssetProfile && g_AssetProfiler != NULL) {
                    UpdateAssetProfile(true, profit, scenario);
                }
            } else {
                g_ConsecutiveLosses++;
                LogMessage("Lệnh đóng lỗ: " + DoubleToString(profit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + 
                         ", Thua liên tiếp: " + IntegerToString(g_ConsecutiveLosses), true);
                
                // Cập nhật Asset Profile nếu bật
                if (EnableAssetProfile && g_AssetProfiler != NULL) {
                    UpdateAssetProfile(false, profit, scenario);
                }
                
                // Kiểm tra điều kiện tạm dừng do chuỗi thua
                if (EnableAutoPause && g_ConsecutiveLosses >= MaxConsecutiveLosses) {
                    g_CurrentState = STATE_PAUSED;
                    g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
                    LogMessage("EA tạm dừng do đạt giới hạn thua liên tiếp: " + IntegerToString(g_ConsecutiveLosses) + 
                             " lệnh. Tiếp tục sau: " + TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES), true);
                    
                    // Gửi thông báo
                    if (AlertsEnabled) {
                        SendAlert("EA tạm dừng do thua " + IntegerToString(g_ConsecutiveLosses) + " lệnh liên tiếp", true);
                        
                        // Gửi thông báo riêng cho sự kiện rủi ro
                        if (EnableRiskEventNotify && EnableTelegramNotify && g_Logger != NULL) {
                            string riskMsg = "⚠️ CẢNH BÁO RỦI RO: Thua " + IntegerToString(g_ConsecutiveLosses) + 
                                          " lệnh liên tiếp! EA tạm dừng đến " + 
                                          TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES);
                            g_Logger.SendTelegramMessage(riskMsg);
                        }
                    }
                    
                    UpdateEAState();
                }
            }
            
            // Cập nhật Dashboard nếu có
            if (g_Dashboard != NULL && DisplayDashboard) {
                g_Dashboard.Update(g_CurrentProfile);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Khởi tạo các module chính                                        |
//+------------------------------------------------------------------+
bool InitializeModules() {
    // Đã khởi tạo Logger ở OnInit, kiểm tra lại
    if (g_Logger == NULL) {
        Print("LỖI: Logger chưa được khởi tạo");
        return false;
    }
    
    // Khởi tạo SessionManager
    g_SessionManager = new ApexPullback::CSessionManager();
    if (g_SessionManager == NULL) {
        LogMessage("LỖI: Không thể tạo Session Manager", true);
        return false;
    }
    
    if (!g_SessionManager.Initialize(FilterBySession, GmtOffset, (int)SessionFilter, 
                                  TradeLondonOpen, TradeNewYorkOpen)) {
        LogMessage("LỖI: Không thể khởi tạo Session Manager", true);
        return false;
    }
    
    // Khởi tạo MarketProfile
    g_MarketProfile = new ApexPullback::CMarketProfile();
    if (g_MarketProfile == NULL) {
        LogMessage("LỖI: Không thể tạo Market Profile", true);
        return false;
    }
    
    if (!g_MarketProfile.Initialize(_Symbol, MainTimeframe, EMA_Fast, EMA_Medium, EMA_Slow,
                                UseMultiTimeframe, HigherTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Market Profile", true);
        return false;
    }
    
    // Thiết lập tham số thêm
    g_MarketProfile.SetParameters(MinAdxValue, MaxAdxValue, GetAdaptiveVolatilityThreshold(), MarketPreset);
    
    // Khởi tạo SwingDetector
    g_SwingDetector = new ApexPullback::CSwingDetector();
    if (g_SwingDetector == NULL) {
        LogMessage("LỖI: Không thể tạo Swing Detector", true);
        return false;
    }
    
    if (!g_SwingDetector.Initialize(_Symbol, MainTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Swing Detector", true);
        return false;
    }
    g_SwingDetector.SetParameters(EnableSwingLevels);
    
    // Khởi tạo PatternDetector
    g_PatternDetector = new ApexPullback::CPatternDetector();
    if (g_PatternDetector == NULL) {
        LogMessage("LỖI: Không thể tạo Pattern Detector", true);
        return false;
    }
    
    if (!g_PatternDetector.Initialize(_Symbol, MainTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Pattern Detector", true);
        return false;
    }
    
    // Khởi tạo RiskManager
    g_RiskManager = new ApexPullback::CRiskManager();
    if (g_RiskManager == NULL) {
        LogMessage("LỖI: Không thể tạo Risk Manager", true);
        return false;
    }
    
    if (!g_RiskManager.Initialize(RiskPercent, PropFirmMode, DailyLossLimit, MaxDrawdown,
                               MaxTradesPerDay, MaxConsecutiveLosses, DrawdownReduceThreshold, 
                               g_DayStartEquity, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Risk Manager", true);
        return false;
    }
    
    // Thiết lập tham số thêm
    g_RiskManager.SetTaperedRisk(EnableTaperedRisk, MinRiskMultiplier);
    
    // Khởi tạo TradeManager
    g_TradeManager = new ApexPullback::CTradeManager();
    if (g_TradeManager == NULL) {
        LogMessage("LỖI: Không thể tạo Trade Manager", true);
        return false;
    }
    
    if (!g_TradeManager.Initialize(_Symbol, MagicNumber, OrderComment, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Trade Manager", true);
        return false;
    }
    
    // Thiết lập tham số
    g_TradeManager.SetEntryMode(EntryMode);
    g_TradeManager.SetTrailingParameters(UseAdaptiveTrailing, TrailingMode, TrailingAtrMultiplier,
                                      BreakEvenAfterR, BreakEvenBuffer);
    
    // Khởi tạo PositionManager
    g_PositionManager = new ApexPullback::CPositionManager();
    if (g_PositionManager == NULL) {
        LogMessage("LỖI: Không thể tạo Position Manager", true);
        return false;
    }
    
    if (!g_PositionManager.Initialize(_Symbol, MagicNumber, g_TradeManager, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Position Manager", true);
        return false;
    }
    
    // Thiết lập tham số
    g_PositionManager.SetPartialCloseParameters(UsePartialClose, PartialCloseR1, PartialCloseR2, 
                                             PartialClosePercent1, PartialClosePercent2);
    g_PositionManager.SetScalingParameters(EnableScaling, MaxScalingCount, ScalingRiskPercent, 
                                        RequireBreakEvenForScaling);
    g_PositionManager.EnableChandelierExit(UseChandelierExit, ChandelierPeriod, ChandelierMultiplier);
    
    // Khởi tạo NewsFilter
    if (NewsFilter != NEWS_NONE) {
        g_NewsFilter = new ApexPullback::CNewsFilter();
        if (g_NewsFilter == NULL) {
            LogMessage("LỖI: Không thể tạo News Filter", true);
            return false;
        }
        
        if (!g_NewsFilter.Initialize(_Symbol, (int)NewsFilter, NewsImportance, 
                                  MinutesBeforeNews, MinutesAfterNews, NewsDataFile, g_Logger)) {
            LogMessage("CẢNH BÁO: Không thể khởi tạo News Filter. Bộ lọc tin tức có thể không hoạt động chính xác", true);
        }
    }
    
    // Khởi tạo Asset Profiler nếu được bật
    if (EnableAssetProfile) {
        g_AssetProfiler = new ApexPullback::CAssetProfiler();
        if (g_AssetProfiler == NULL) {
            LogMessage("LỖI: Không thể tạo Asset Profiler", true);
            return false;
        }
        
        if (!g_AssetProfiler.Initialize(_Symbol, MinimumTradesForProfile, ProfileAdaptPercent, g_Logger)) {
            LogMessage("CẢNH BÁO: Không thể khởi tạo Asset Profiler. Tính năng tự học có thể không hoạt động chính xác", true);
        } else {
            // Phân tích hồ sơ tài sản
            if (g_AssetProfiler.AnalyzeAsset(AssetProfileDays)) {
                LogMessage("Asset Profile được tạo thành công cho " + _Symbol);
            } else {
                LogMessage("CẢNH BÁO: Không thể tạo Asset Profile đầy đủ", true);
            }
        }
    }
    
    LogMessage("Đã khởi tạo tất cả các module thành công");
    return true;
}

//+------------------------------------------------------------------+
//| Dọn dẹp module khi kết thúc                                      |
//+------------------------------------------------------------------+
void CleanupModules() {
    // Dọn dẹp theo thứ tự ngược lại với khởi tạo
    
    // Dashboard
    if (g_Dashboard != NULL) {
        delete g_Dashboard;
        g_Dashboard = NULL;
    }
    
    // Asset Profiler
    if (g_AssetProfiler != NULL) {
        delete g_AssetProfiler;
        g_AssetProfiler = NULL;
    }
    
    // NewsFilter
    if (g_NewsFilter != NULL) {
        delete g_NewsFilter;
        g_NewsFilter = NULL;
    }
    
    // PositionManager
    if (g_PositionManager != NULL) {
        delete g_PositionManager;
        g_PositionManager = NULL;
    }
    
    // TradeManager
    if (g_TradeManager != NULL) {
        delete g_TradeManager;
        g_TradeManager = NULL;
    }
    
    // RiskManager
    if (g_RiskManager != NULL) {
        delete g_RiskManager;
        g_RiskManager = NULL;
    }
    
    // PatternDetector
    if (g_PatternDetector != NULL) {
        delete g_PatternDetector;
        g_PatternDetector = NULL;
    }
    
    // SwingDetector
    if (g_SwingDetector != NULL) {
        delete g_SwingDetector;
        g_SwingDetector = NULL;
    }
    
    // MarketProfile
    if (g_MarketProfile != NULL) {
        delete g_MarketProfile;
        g_MarketProfile = NULL;
    }
    
    // SessionManager
    if (g_SessionManager != NULL) {
        delete g_SessionManager;
        g_SessionManager = NULL;
    }
    
    // Logger - xóa cuối cùng
    if (g_Logger != NULL) {
        delete g_Logger;
        g_Logger = NULL;
    }
}

//+------------------------------------------------------------------+
//| Cập nhật trạng thái EA                                           |
//+------------------------------------------------------------------+
void UpdateEAState() {
    // Lưu trạng thái trước đó để kiểm tra thay đổi
    ENUM_EA_STATE previousState = g_CurrentState;
    
    // Kiểm tra điều kiện tạm dừng
    
    // 1. Kiểm tra tạm dừng do Drawdown
    if (g_CurrentState == STATE_RUNNING && g_RiskManager != NULL) {
        double currentDD = g_RiskManager.GetCurrentDrawdown();
        
        if (currentDD >= MaxDrawdown) {
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
            LogMessage("EA tạm dừng do vượt ngưỡng Drawdown: " + DoubleToString(currentDD, 2) + 
                     "% > " + DoubleToString(MaxDrawdown, 2) + "%", true);
            
            // Gửi thông báo riêng cho sự kiện rủi ro
            if (EnableRiskEventNotify && EnableTelegramNotify && g_Logger != NULL) {
                string riskMsg = "⚠️ CẢNH BÁO RỦI RO: Drawdown " + DoubleToString(currentDD, 2) + 
                              "% vượt ngưỡng " + DoubleToString(MaxDrawdown, 2) + 
                              "%! EA tạm dừng đến " + TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES);
                g_Logger.SendTelegramMessage(riskMsg);
            }
        }
        else if (currentDD >= DrawdownReduceThreshold && EnableTaperedRisk) {
            g_CurrentState = STATE_REDUCED_RISK;
            LogMessage("EA chuyển sang chế độ giảm risk do DD: " + DoubleToString(currentDD, 2) + "%", true);
        }
    }
    
    // 2. Kiểm tra tạm dừng do volatility
    if (g_CurrentState == STATE_RUNNING && EnableVolatilityFilter && g_MarketProfile != NULL && !SkipVolatilityCheck) {
        double volatilityRatio = g_CurrentProfile.atrRatio;
        double adaptiveThreshold = GetAdaptiveVolatilityThreshold();
        
        if (volatilityRatio > adaptiveThreshold) {
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
            LogMessage("EA tạm dừng do biến động quá cao: " + DoubleToString(volatilityRatio, 2) + 
                     "x > " + DoubleToString(adaptiveThreshold, 2) + "x ATR trung bình", true);
        }
    }
    
    // 3. Kiểm tra tạm dừng do spread cao
    if (g_CurrentState == STATE_RUNNING && !IsSpreadAcceptable()) {
        static datetime lastSpreadPause = 0;
        datetime currentTime = TimeCurrent();
        
        // Chỉ tạm dừng mỗi 5 phút do spread cao để tránh quá nhiều log
        if (currentTime - lastSpreadPause > 300) {
            // Sử dụng spread max thích ứng
            double maxSpread = EnableAdaptiveThresholds ? GetAdaptiveMaxSpread() : MaxSpreadPoints;
            
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = currentTime + 300; // Tạm dừng 5 phút
            LogMessage("EA tạm dừng do spread cao: " + 
                     DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 1) + 
                     " > " + DoubleToString(maxSpread, 1) + " điểm", true);
            lastSpreadPause = currentTime;
        }
    }
    
    // 4. Kiểm tra điều kiện tự động resume
    if (g_CurrentState == STATE_PAUSED && EnableAutoResume) {
        datetime currentTime = TimeCurrent();
        
        // Hết thởi gian tạm dừng
        if (currentTime >= g_PauseEndTime) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục hoạt động sau thởi gian tạm dừng", true);
        }
        
        // Kiểm tra phiên London Open
        if (ResumeOnLondonOpen && g_SessionManager != NULL && g_SessionManager.IsLondonOpening()) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục vào phiên mở cửa London", true);
        }
    }
    
    // Ghi log khi có thay đổi trạng thái
    if (previousState != g_CurrentState) {
        LogMessage("Trạng thái EA thay đổi: " + GetStateDescription(previousState) + 
                 " -> " + GetStateDescription(g_CurrentState), true);
        
        // Cập nhật Dashboard
        if (g_Dashboard != NULL && DisplayDashboard) {
            g_Dashboard.Update(g_CurrentProfile);
        }
    }
}

//+------------------------------------------------------------------+
//| Quản lý trạng thái EA                                           |
//+------------------------------------------------------------------+
void ManageEAState() {
    // Xử lý theo trạng thái hiện tại
    switch (g_CurrentState) {
        case STATE_RUNNING:
            // Trạng thái bình thường, sử dụng risk bình thường
            g_CurrentRisk = RiskPercent;
            break;
            
        case STATE_REDUCED_RISK:
            // Giảm risk theo drawdown
            g_CurrentRisk = CalculateAdaptiveRiskPercent();
            break;
            
        case STATE_PAUSED:
            // Tạm dừng, không làm gì
            break;
            
        default:
            // Các trạng thái khác
            break;
    }
}

//+------------------------------------------------------------------+
//| Lấy mô tả trạng thái EA                                         |
//+------------------------------------------------------------------+
string GetStateDescription(ENUM_EA_STATE state) {
    switch (state) {
        case STATE_INIT:       return "Đang khởi tạo";
        case STATE_RUNNING:    return "Đang hoạt động";
        case STATE_PAUSED:     return "Tạm dừng";
        case STATE_REDUCED_RISK: return "Giảm risk";
        case STATE_ERROR:      return "Lỗi";
        default:               return "Không xác định";
    }
}

//+------------------------------------------------------------------+
//| Cập nhật dữ liệu thị trường                                      |
//+------------------------------------------------------------------+
bool UpdateMarketData() {
    if (g_MarketProfile == NULL || g_SwingDetector == NULL)
        return false;
    
    // Cập nhật MarketProfile
    if (!g_MarketProfile.Update()) {
        LogMessage("Không thể cập nhật Market Profile", true);
        return false;
    }
    
    // Cập nhật SwingDetector
    if (!g_SwingDetector.Update()) {
        LogMessage("Không thể cập nhật Swing Detector", true);
        return false;
    }
    
    // Phân tích profile thị trường
    g_CurrentProfile = AnalyzeMarketProfile();
    
    // Log thông tin thị trường
    if (EnableDetailedLogs) {
        string profileInfo = StringFormat("Market Profile: POC: %.5f, VAH: %.5f, VAL: %.5f", 
                                        g_CurrentProfile.pointOfControl, 
                                        g_CurrentProfile.valueAreaHigh, g_CurrentProfile.valueAreaLow);
        LogMessage(profileInfo);
    }
    
    // Log thông tin thị trường (chỉ khi log chi tiết)
    if (EnableDetailedLogs) {
        string profileDesc = StringFormat(
            "Market Profile: Trend=%s, Session=%s, ATR=%.5f (%.1f%%), ADX=%.1f, Volatility=%s, Transitioning=%s",
            EnumToString((ENUM_TREND_TYPE)g_CurrentProfile.trend),
            EnumToString(g_CurrentProfile.currentSession),
            g_CurrentProfile.atrCurrent,
            g_CurrentProfile.volatilityRatio * 100,
            g_CurrentProfile.adxValue,
            (g_CurrentProfile.isVolatile ? "High" : "Normal"),
            (g_CurrentProfile.isTransitioning ? "Yes" : "No"));
    }
}

//+------------------------------------------------------------------+
//| Phân tích profile thị trường                                     |
//+------------------------------------------------------------------+
MarketProfileData AnalyzeMarketProfile()
{
    MarketProfileData profile;
    
    // Khai báo các biến cần thiết
    double rsiValue = 50.0;
    double rsiSlope = 0.0;
    double macdValue = 0.0;
    double macdSignal = 0.0;
    double macdHist = 0.0;
    double macdHistSlope = 0.0;
    double atrValue = 0.0;
    
    // Lấy giá trị RSI từ indicator
    int handleRSI = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    if (handleRSI != INVALID_HANDLE) {
        double rsiBuffer[];
        ArraySetAsSeries(rsiBuffer, true);
        if (CopyBuffer(handleRSI, 0, 0, 3, rsiBuffer) > 0) {
            rsiValue = rsiBuffer[0];
            // Tính RSI slope (chênh lệch giữa giá trị hiện tại và trước)
            rsiSlope = rsiBuffer[0] - rsiBuffer[1];
        }
        IndicatorRelease(handleRSI);
    }
    
    // Lấy giá trị MACD
    int handleMACD = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
    if (handleMACD != INVALID_HANDLE) {
        double macdMainBuffer[];
        double macdSignalBuffer[];
        ArraySetAsSeries(macdMainBuffer, true);
        ArraySetAsSeries(macdSignalBuffer, true);
        
        if (CopyBuffer(handleMACD, 0, 0, 3, macdMainBuffer) > 0 &&
            CopyBuffer(handleMACD, 1, 0, 3, macdSignalBuffer) > 0) {
            macdValue = macdMainBuffer[0];
            macdSignal = macdSignalBuffer[0];
            macdHist = macdValue - macdSignal;
            macdHistSlope = (macdMainBuffer[0] - macdSignalBuffer[0]) - 
                           (macdMainBuffer[1] - macdSignalBuffer[1]);
        }
        IndicatorRelease(handleMACD);
    }
    
    // Lấy giá trị ATR
    int handleATR = iATR(_Symbol, PERIOD_CURRENT, 14);
    if (handleATR != INVALID_HANDLE) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        if (CopyBuffer(handleATR, 0, 0, 1, atrBuffer) > 0) {
            atrValue = atrBuffer[0];
        }
        IndicatorRelease(handleATR);
    }
    
    // Thiết lập các giá trị cơ bản cho profile
    profile.rsiValue = rsiValue;
    profile.rsiSlope = rsiSlope;
    profile.macdValue = macdValue;
    profile.macdSignal = macdSignal;
    profile.macdHistogram = macdHist;
    profile.macdHistogramSlope = macdHistSlope;
    profile.atrValue = atrValue;
    
    // Trước tiên, kiểm tra nếu module MarketProfile đã được khởi tạo
    if (g_MarketProfile != NULL) { 
        if (g_lastProfileTime != iTime(_Symbol, PERIOD_CURRENT, 0)) {
            g_lastProfileTime = iTime(_Symbol, PERIOD_CURRENT, 0);
            // Tạm thời sử dụng các giá trị từ indicator, sẽ cập nhật profile sau khi biết chính xác tên các method
            // Cần phải xem lại MarketProfile.mqh để biết cách truy cập đúng
            g_CurrentProfile.pointOfControl = iClose(_Symbol, PERIOD_CURRENT, 0); // Tạm dùng giá đóng của
            // Dùng ATR để tính ValueArea
            double atr = iATR(_Symbol, PERIOD_CURRENT, 14);
            g_CurrentProfile.valueAreaHigh = g_CurrentProfile.pointOfControl + atr;
            g_CurrentProfile.valueAreaLow = g_CurrentProfile.pointOfControl - atr;
            
            // Đảm bảo các giá trị indicator đả được cập nhật
            profile.rsiValue = rsiValue;
            profile.rsiSlope = rsiSlope;
            profile.macdValue = macdValue;
            profile.macdSignal = macdSignal;
            profile.macdHistogram = macdHist;
            profile.macdHistogramSlope = macdHistSlope;
            profile.atrValue = atrValue;
            
            // Tính tỷ lệ ATR hiện tại so với trung bình
            if (g_AssetProfileManager != NULL) {
                // Tạm thởi sử dụng giá trị mặc định cho averageATR
                double avgATR = atrValue * 1.2; // Giả sử giá trị trung bình là 120% giá trị hiện tại
                profile.atrRatio = (atrValue > 0 && avgATR > 0) 
                               ? atrValue / avgATR 
                                : 1.0;
            }
        } else {
            if (g_Logger != NULL) {
                g_Logger->LogError("Lỗi khi cập nhật Market Profile");
            }
            // Mặc định cho profile nếu có lỗi
            profile.regime = REGIME_RANGING_STABLE;
            profile.trend = MARKET_TREND_RANGING;
            
            // Tìm swing high/low nếu không có MarketProfile
            double high[], low[];
            ArraySetAsSeries(high, true);
            ArraySetAsSeries(low, true);
            CopyHigh(_Symbol, PERIOD_CURRENT, 0, 50, high);
            CopyLow(_Symbol, PERIOD_CURRENT, 0, 50, low);
            
            // Tìm đỉnh và đáy gần nhất
            for (int i = 5; i < 45; i++) { // 50-5 = 45
                // Đỉnh - cao hơn 5 cây nến trước và 5 cây nến sau
                bool isHigh = true;
                for (int j = i-5; j <= i+5; j++) {
                    if (j != i && j >= 0 && j < 50 && high[j] > high[i]) {
                        isHigh = false;
                        break;
                    }
                }
                if (isHigh) {
                    profile.recentSwingHigh = high[i];
                    break;
                }
            }
            
            for (int i = 5; i < 45; i++) { // 50-5 = 45
                // Đáy - thấp hơn 5 cây nến trước và 5 cây nến sau
                bool isLow = true;
                for (int j = i-5; j <= i+5; j++) {
                    if (j != i && j >= 0 && j < 50 && low[j] < low[i]) {
                        isLow = false;
                        break;
                    }
                }
                if (isLow) {
                    profile.recentSwingLow = low[i];
                    break;
                }
            }
        }
    }
    
    // Lấy giá trị RSI
    profile.rsiValue = 50.0; // Giá trị mặc định
    int rsiHandle = iRSI(_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    if (rsiHandle != INVALID_HANDLE) {
        double rsiBuffer[1];
        if (CopyBuffer(rsiHandle, 0, 0, 1, rsiBuffer) > 0) {
            profile.rsiValue = rsiBuffer[0];
        }
    }
    
    // Xác định xu hướng dựa trên MA
    double ma20 = 0, ma50 = 0;
    int ma20Handle = iMA(_Symbol, PERIOD_CURRENT, 20, 0, MODE_EMA, PRICE_CLOSE);
    int ma50Handle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
    
    if (ma20Handle != INVALID_HANDLE && ma50Handle != INVALID_HANDLE) {
        double ma20Buffer[1], ma50Buffer[1];
        if (CopyBuffer(ma20Handle, 0, 0, 1, ma20Buffer) > 0) ma20 = ma20Buffer[0];
        if (CopyBuffer(ma50Handle, 0, 0, 1, ma50Buffer) > 0) ma50 = ma50Buffer[0];
        
        if (ma20 > ma50 && profile.rsiValue > 50)
            profile.trend = MARKET_TREND_UP;
        else if (ma20 < ma50 && profile.rsiValue < 50)
            profile.trend = MARKET_TREND_DOWN;
        else if (MathAbs(ma20 - ma50) < 0.0001 * ma50)
            profile.trend = MARKET_TREND_RANGING;
        else
            profile.trend = MARKET_TREND_UNKNOWN;
    }
    
    // Tính toán tỷ lệ biến động
    double atrBaseline = 0;
    int atrHandle14D = iATR(_Symbol, PERIOD_D1, 14);
    if (atrHandle14D != INVALID_HANDLE) {
        double atrBuffer[1];
        if (CopyBuffer(atrHandle14D, 0, 0, 1, atrBuffer) > 0) atrBaseline = atrBuffer[0];
    }
    
    if (atrBaseline > 0)
        profile.volatilityRatio = profile.atrValue / atrBaseline;
    else
        profile.volatilityRatio = 1.0;
    
    // Xác định trạng thái biến động
    profile.isVolatile = (profile.volatilityRatio > g_VolatilityThreshold);
    
    // Lấy thông tin phiên giao dịch hiện tại
    profile.currentSession = DetermineSession(TimeCurrent());
    
    // Không cần chuyển đổi vì ENUM_SESSION_TYPE và ENUM_SESSION đã được đồng bộ
    
    // Lấy dữ liệu ADX và RSI bằng cách sử dụng indicator của MQL5
    int adxHandle = iADX(Symbol(), Period(), 14);
    int rsiHandle = iRSI(Symbol(), Period(), 14, PRICE_CLOSE);
    
    // Khai báo mảng để lưu trữ dữ liệu
    double adxValues[1], rsiValues[1];
    
    // Lấy giá trị từ các indicator
    if(CopyBuffer(adxHandle, 0, 0, 1, adxValues) > 0 && 
       CopyBuffer(rsiHandle, 0, 0, 1, rsiValues) > 0) {
        profile.adxValue = adxValues[0];
        profile.rsiValue = rsiValues[0];
    }
    
    // Sử dụng giá trị mặc định cho POC và VA dựa trên một số logic đơn giản
    double high = iHigh(Symbol(), Period(), 0);
    double low = iLow(Symbol(), Period(), 0);
    double close = iClose(Symbol(), Period(), 0);
    
    // Gán giá trị vào profile
    profile.pointOfControl = (high + low + close) / 3.0; // POC đơn giản dựa trên giá OHLC
    profile.valueAreaHigh = high;
    profile.valueAreaLow = low;
    
    // Lấy giá trị swing points
    profile.recentSwingHigh = FindHighest(20); // Chỉ cần 1 tham số
    profile.recentSwingLow = FindLowest(20);   // Chỉ cần 1 tham số
    
    return profile;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận momentum                                       |
//+------------------------------------------------------------------+
bool IsMomentumConfirmed(bool isLong) {
    // Lấy giá trị slope của RSI và MACD Histogram
    double rsiSlope = g_CurrentProfile.rsiSlope;
    double macdHistSlope = g_CurrentProfile.macdHistogramSlope;
    double rsiValue = g_CurrentProfile.rsiValue;
    double macdHist = g_CurrentProfile.macdHistogram;
    
    bool momentumConfirmed = false;
    
    if (isLong) {
        // Xu hướng tăng - RSI vuột xuống dưới 40 và đang tăng trở lại
        // + MACD Histogram tăng hoặc vuột trên 0
        bool rsiConfirm = (rsiValue < 60 && rsiValue > 30 && rsiSlope > 0);
        bool macdConfirm = (macdHist > 0 || macdHistSlope > 0) || 
                          (macdHist < 0 && macdHistSlope > 0.1); // Đang tăng từ âm sang
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    } else {
        // Cho xu hướng giảm, cần RSI slope < -0.25 hoặc MACD Histogram đảo chiều giảm
        bool rsiConfirm = (rsiValue < 55.0 && rsiSlope < -0.25);
        bool macdConfirm = (macdHist < 0 && macdHistSlope < 0) || 
                          (macdHist > 0 && macdHistSlope < -0.1); // Đang giảm từ dương xuống
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    }
    
    if (momentumConfirmed) {
        if (isLong) {
            LogMessage("Xác nhận momentum: RSI slope=" + DoubleToString(rsiSlope, 2) + 
                     ", MACD Hist slope=" + DoubleToString(macdHistSlope, 2));
        } else {
            LogMessage("Xác nhận momentum: RSI slope=" + DoubleToString(rsiSlope, 2) + 
                     ", MACD Hist slope=" + DoubleToString(macdHistSlope, 2));
        }
    }
    
    return momentumConfirmed;
}

//+------------------------------------------------------------------+
//| Ghi log message                                                  |
//+------------------------------------------------------------------+
void LogMessage(string message, bool isError = false) {
    if (g_Logger != NULL) {
        if (isError)
            g_Logger.LogError(message);
        else
            g_Logger.LogInfo(message);
    } else {
        Print(message);
    }
}

//+------------------------------------------------------------------+
//| Gửi cảnh báo/thông báo                                         |
//+------------------------------------------------------------------+
void SendAlert(string message, bool isImportant) {
    // Ghi log luôn
    LogMessage(message, isImportant);
    
    // Nếu cảnh báo bị tắt, return
    if (!AlertsEnabled) return;
    
    // Alert trong terminal
    if (isImportant) {
        Alert("APEX: " + message);
    }
    
    // Push notification
    if (SendNotifications && isImportant) {
        SendNotification("APEX: " + message);
    }
    
    // Email
    if (SendEmailAlerts && isImportant) {
        SendMail("APEX Pullback EA v15.0 - " + _Symbol, message);
    }
    
    // Telegram
    if (EnableTelegramNotify && g_Logger != NULL && 
       (!TelegramImportantOnly || isImportant)) {
        g_Logger.SendTelegramMessage(message);
    }
}

// Kiểm tra nến mới đã được định nghĩa ở trên
// Xóa định nghĩa trùng để tránh lỗi

//+------------------------------------------------------------------+
//| Cập nhật Dashboard                                              |
//+------------------------------------------------------------------+
void UpdateDashboard() {
    if (g_Dashboard == NULL || !DisplayDashboard) return;
    
    // Cập nhật dashboard
    g_Dashboard.Update(g_CurrentProfile);
}

//+------------------------------------------------------------------+
//| Chuyển đổi timeframe sang chuỗi                                 |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf) {
    switch (tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN";
        default:         return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Lấy mô tả lý do kết thúc                                        |
//+------------------------------------------------------------------+
string GetDeinitReasonText(const int reason) {
    switch (reason) {
        case REASON_PROGRAM:     return "EA tự kết thúc";
        case REASON_REMOVE:      return "EA bị xóa khỏi biểu đồ";
        case REASON_RECOMPILE:   return "EA được biên dịch lại";
        case REASON_CHARTCHANGE: return "Symbol hoặc khung thời gian đã thay đổi";
        case REASON_CHARTCLOSE:  return "Biểu đồ đã đóng";
        case REASON_PARAMETERS:  return "Tham số input đã thay đổi";
        case REASON_ACCOUNT:     return "Tài khoản thay đổi hoặc kết nối lại";
        case REASON_TEMPLATE:    return "Áp dụng template mới";
        case REASON_INITFAILED:  return "OnInit() thất bại";
        case REASON_CLOSE:       return "Terminal đã đóng";
        default:                 return "Lý do không xác định (" + IntegerToString(reason) + ")";
    }
}

//+------------------------------------------------------------------+
//| [NEW] Kiểm tra thời gian cập nhật tính toán                     |
//+------------------------------------------------------------------+
bool ShouldUpdateCalculations(datetime lastUpdateTime) {
    datetime currentTime = TimeCurrent();
    return currentTime - lastUpdateTime > 300; // 5 phút
}

//+------------------------------------------------------------------+
//| [NEW] Khởi tạo cache chỉ báo                                    |
//+------------------------------------------------------------------+
void InitializeIndicatorCache() {
    if (!EnableIndicatorCache) return;
    
    for (int i = 0; i < 10; i++) {
        g_IndicatorCache[i] = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| [NEW] Xóa cache chỉ báo                                         |
//+------------------------------------------------------------------+
void ClearIndicatorCache() {
    if (!EnableIndicatorCache) return;
    
    for (int i = 0; i < 10; i++) {
        if (g_IndicatorCache[i] != INVALID_HANDLE) {
            IndicatorRelease(g_IndicatorCache[i]);
            g_IndicatorCache[i] = INVALID_HANDLE;
        }
    }
}

//+------------------------------------------------------------------+
//| [NEW] Lấy handle chỉ báo từ cache                               |
//+------------------------------------------------------------------+
int GetIndicatorHandle(int indicatorType, string symbol, ENUM_TIMEFRAMES timeframe) {
    if (!EnableIndicatorCache) {
        // Không sử dụng cache, tạo mới mỗi lần
        switch (indicatorType) {
            case 0: // RSI
                return iRSI(symbol, timeframe, 14, PRICE_CLOSE);
            case 1: // MACD
                return iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE);
            case 2: // ATR
                return iATR(symbol, timeframe, 14);
            default:
                return INVALID_HANDLE;
        }
    }
    
    // Sử dụng cache
    if (g_IndicatorCache[indicatorType] == INVALID_HANDLE) {
        switch (indicatorType) {
            case 0: // RSI
                g_IndicatorCache[indicatorType] = iRSI(symbol, timeframe, 14, PRICE_CLOSE);
                break;
            case 1: // MACD
                g_IndicatorCache[indicatorType] = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE);
                break;
            case 2: // ATR
                g_IndicatorCache[indicatorType] = iATR(symbol, timeframe, 14);
                break;
            default:
                return INVALID_HANDLE;
        }
    }
    
    return g_IndicatorCache[indicatorType];
}

//+------------------------------------------------------------------+
//| Nạp cấu hình                                                    |
//+------------------------------------------------------------------+
bool LoadConfiguration() {
    string filename = "ApexPullback_" + _Symbol + ".conf";
    
    if (!FileIsExist(filename, FILE_COMMON)) {
        LogMessage("Không tìm thấy file cấu hình: " + filename);
        return false;
    }
    
    int fileHandle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogMessage("Không thể mở file cấu hình: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Đọc từng dòng cấu hình
    while (!FileIsEnding(fileHandle)) {
        string line = FileReadString(fileHandle);
        
        // Bỏ qua dòng trống hoặc comment
        if (StringLen(line) == 0 || StringGetCharacter(line, 0) == '#') {
            continue;
        }
        
        // Tách key=value
        string parts[];
        if (StringSplit(line, '=', parts) == 2) {
            // Sử dụng biến trung gian để tránh lỗi l-value
            string tempKey = StringTrimLeft(parts[0]);
            string key = StringTrimRight(tempKey);
            
            string tempValue = StringTrimLeft(parts[1]);
            string value = StringTrimRight(tempValue);
            
            // Xử lý các tham số
            if (key == "RiskPercent") {
                RiskPercent = StringToDouble(value);
            }
            else if (key == "MaxDrawdown") {
                MaxDrawdown = StringToDouble(value);
            }
            else if (key == "DailyLossLimit") {
                DailyLossLimit = StringToDouble(value);
            }
            else if (key == "SL_ATR") {
                SL_ATR = StringToDouble(value);
            }
            else if (key == "TP_RR") {
                TP_RR = StringToDouble(value);
            }
            else if (key == "MinAdxValue") {
                MinAdxValue = StringToDouble(value);
            }
            else if (key == "StrictPriceAction") {
                StrictPriceAction = (StringCompare(value, "true") == 0 || StringToInteger(value) == 1);
            }
            else if (key == "RequireSwingStructure") {
                RequireSwingStructure = (StringCompare(value, "true") == 0 || StringToInteger(value) == 1);
            }
            // Thêm các tham số khác nếu cần
        }
    }
    
    FileClose(fileHandle);
    LogMessage("Đã nạp cấu hình từ file: " + filename);
    return true;
}

//+------------------------------------------------------------------+
//| Lưu cấu hình                                                    |
//+------------------------------------------------------------------+
void SaveConfiguration() {
    string filename = "ApexPullback_" + _Symbol + ".conf";
    
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogMessage("Không thể tạo file cấu hình: " + IntegerToString(GetLastError()), true);
        return;
    }
    
    // Thông tin file
    FileWriteString(fileHandle, "# APEX Pullback EA v15.0 Configuration\n");
    FileWriteString(fileHandle, "# Last Updated: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n");
    
    // Lưu các tham số
    FileWriteString(fileHandle, "RiskPercent=" + DoubleToString(RiskPercent, 2) + "\n");
    FileWriteString(fileHandle, "MaxDrawdown=" + DoubleToString(MaxDrawdown, 2) + "\n");
    FileWriteString(fileHandle, "DailyLossLimit=" + DoubleToString(DailyLossLimit, 2) + "\n");
    FileWriteString(fileHandle, "SL_ATR=" + DoubleToString(SL_ATR, 2) + "\n");
    FileWriteString(fileHandle, "TP_RR=" + DoubleToString(TP_RR, 2) + "\n");
    FileWriteString(fileHandle, "StrictPriceAction=" + (StrictPriceAction ? "true" : "false") + "\n");
    FileWriteString(fileHandle, "RequireSwingStructure=" + (RequireSwingStructure ? "true" : "false") + "\n");
    
    // Thống kê
    if (SaveStatistics) {
        FileWriteString(fileHandle, "\n# Statistics\n");
        FileWriteString(fileHandle, "TotalTrades=" + IntegerToString(g_DayTrades) + "\n");
        FileWriteString(fileHandle, "ConsecutiveLosses=" + IntegerToString(g_ConsecutiveLosses) + "\n");
        
        // Thêm thông tin Asset Profile nếu có
        if (EnableAssetProfile && g_AssetProfiler != NULL) {
            string profileStats = g_AssetProfiler.GetProfileStats();
            FileWriteString(fileHandle, "\n# Asset Profile\n");
            FileWriteString(fileHandle, profileStats);
        }
    }
    
    FileClose(fileHandle);
    LogMessage("Đã lưu cấu hình vào file: " + filename);
}

//+------------------------------------------------------------------+
//| End of APEX Pullback EA v15.0                                    |
//+------------------------------------------------------------------+

// End of EA code