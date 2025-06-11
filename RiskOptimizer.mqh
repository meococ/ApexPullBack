//+------------------------------------------------------------------+
//| RiskOptimizer.mqh                                             |
//| Module for risk and money management optimization              |
//+------------------------------------------------------------------+

#ifndef _RISK_OPTIMIZER_MQH_
#define _RISK_OPTIMIZER_MQH_

// --- Standard MQL5 Libraries ---
// #include <Trade/Trade.mqh>       // Uncomment if CTrade or related trade functions are used directly
// #include <Trade/SymbolInfo.mqh>  // Uncomment if symbol properties are directly accessed
// #include <Trade/AccountInfo.mqh> // Uncomment if account information is directly accessed
// #include <Arrays/ArrayObj.mqh>   // Uncomment if CArrayObj or other array classes are used
// #include <Math/Stat/Math.mqh>    // Uncomment if advanced math/stat functions are used

// --- Custom EA Core Includes ---
#include "Namespace.mqh"          // Defines namespaces (e.g., ApexPullback) and related macros
#include "CommonDefinitions.mqh"  // General definitions, possibly macros like TREND_NONE, SIGNAL_NONE
#include "Constants.mqh"          // EA-specific constants
#include "Enums.mqh"              // Enumerations (e.g., ENUM_TRAILING_PHASE, ENUM_MARKET_STRATEGY)
#include "CommonStructs.mqh"      // Common data structures (e.g., SRiskOptimizerConfig, MarketProfileData)
#include "FunctionDefinitions.mqh"// Global utility functions (if any are used by this module)
#include "MathHelper.mqh"         // Math utility functions (if any are used by this module)

// --- Custom EA Module Includes ---
#include "Logger.mqh"             // Logging facility
#include "SafeDataProvider.mqh"   // Safe data provider for indicator data
#include "MarketProfile.mqh"      // Market analysis module
#include "SwingPointDetector.mqh" // Swing point detection module
#include "AssetDNA.mqh"           // Module phân tích DNA tài sản (thay thế AssetProfiler và AssetProfileManager)
#include "NewsFilter.mqh"         // News filtering module
#include "PerformanceTracker.mqh"   // Performance tracking module

#ifndef RISK_OPTIMIZER_INCLUDED
#define RISK_OPTIMIZER_INCLUDED
// This guard is usually for the file itself, but here it seems to guard PerformanceTracker.mqh inclusion.
// If PerformanceTracker.mqh has its own include guards, this might be redundant or misplaced.
// For now, keeping the structure as is, but this is a point for potential cleanup.
#endif

// Đảm bảo các constant được xác định
#ifndef CLUSTER_2_COUNTERTREND
#define CLUSTER_2_COUNTERTREND CLUSTER_TYPE_COUNTER
#endif

// Bắt đầu namespace ApexPullback - chứa tất cả các lớp và cấu trúc của EA
namespace ApexPullback {

class CMarketProfile;
class CSwingPointDetector;
class CLogger;
class CAssetProfiler;
class CNewsFilter;
class CSafeDataProvider;

// Định nghĩa ENUM_TRAILING_PHASE
enum ENUM_TRAILING_PHASE {
    TRAILING_NONE,         // Chưa đến ngưỡng trailing
    TRAILING_BREAKEVEN,    // Đã đến ngưỡng hòa vốn
    TRAILING_FIRST_LOCK,   // Đã đến ngưỡng khóa lần 1
    TRAILING_SECOND_LOCK,  // Đã đến ngưỡng khóa lần 2
    TRAILING_THIRD_LOCK    // Đã đến ngưỡng khóa lần 3
};

// Định nghĩa ENUM_MARKET_STRATEGY
enum ENUM_MARKET_STRATEGY {
    STRATEGY_DEFAULT,       // Chiến lược mặc định
    STRATEGY_AGGRESSIVE,    // Chiến lược tích cực
    STRATEGY_CONSERVATIVE,  // Chiến lược bảo thủ
    STRATEGY_ADAPTIVE,      // Chiến lược thích ứng
    STRATEGY_SCALPING,      // Chiến lược scalping
    STRATEGY_SWING,         // Chiến lược swing
    STRATEGY_COUNTER_TREND  // Chiến lược đảo chiều xu hướng
};

// Các hằng số cho giai đoạn trailing
#define TRAILING_PHASE_1 TRAILING_FIRST_LOCK
#define TRAILING_PHASE_2 TRAILING_SECOND_LOCK
#define TRAILING_PHASE_3 TRAILING_THIRD_LOCK
#define TRAILING_LOCKED TRAILING_FIRST_LOCK  // Tương thích với đã khóa lợi nhuận

//====================================================
// Struct Config cho Risk Optimizer v14.0
//====================================================
struct SRiskOptimizerConfig {
    // Cấu hình cơ bản
    double RiskPercent;                  // Risk % gốc
    double SL_ATR_Multiplier;            // Hệ số SL theo ATR
    double TP_RR_Ratio;                  // Tỷ lệ Risk:Reward cho TP
    double MaxAllowedDrawdown;           // Drawdown tối đa cho phép (%)
    
    // Cấu hình pullback chất lượng cao (v14.0)
    double MinPullbackPercent;           // % Pullback tối thiểu (20%)
    double MaxPullbackPercent;           // % Pullback tối đa (70%)
    bool   RequirePriceAction;           // Yêu cầu xác nhận Price Action
    bool   RequireMomentum;              // Yêu cầu xác nhận Momentum  
    bool   RequireVolume;                // Yêu cầu xác nhận Volume
    
    // Cấu hình giảm risk theo drawdown
    double DrawdownReduceThreshold;      // Ngưỡng DD bắt đầu giảm risk
    bool   EnableTaperedRisk;            // Chế độ giảm risk từ từ
    double MinRiskMultiplier;            // Hệ số risk tối thiểu khi DD cao
    
    // Giới hạn risk tối đa
    bool   UseFixedMaxRiskUSD;           // Dùng giới hạn USD cố định
    double MaxRiskUSD;                   // Giới hạn risk tối đa mỗi lệnh ($)
    double MaxRiskPercent;               // Giới hạn risk tối đa (% tài khoản)
    
    // Cấu hình Scaling (nhồi lệnh) - v14.0 cải tiến
    bool   EnableScaling;                // Cho phép scaling (nhồi lệnh)
    int    MaxScalingCount;              // Số lần scaling tối đa (giảm từ 2 xuống 1)
    double ScalingRiskPercent;           // % risk cho scaling (giảm từ 0.4 xuống 0.3)
    bool   RequireBreakEvenForScaling;   // Yêu cầu BE trước khi scaling
    bool   ScalingRequiresClearTrend;    // Yêu cầu xu hướng rõ ràng để scaling
    double MinRMultipleForScaling;       // R-multiple tối thiểu để scaling (1.0R)
    
    // Cấu hình Chandelier Exit
    bool   UseChandelierExit;            // Kích hoạt Chandelier Exit
    int    ChandelierLookback;           // Số nến lookback
    double ChandelierATRMultiplier;      // Hệ số ATR cho chandelier
    
    // Hệ số điều chỉnh trailing
    double TrailingFactorTrend;          // Hệ số trailing trong xu hướng
    double TrailingFactorRanging;        // Hệ số trailing trong sideway
    double TrailingFactorVolatile;       // Hệ số trailing khi biến động cao
    
    // Cấu hình Partial Close - v14.0 cải tiến
    struct PartialCloseConfig {
        bool   UsePartialClose;           // Sử dụng đóng từng phần
        double FirstRMultiple;            // R-multiple cho đóng phần 1 (1.0R)
        double SecondRMultiple;           // R-multiple cho đóng phần 2 (2.0R)
        double FirstClosePercent;         // % đóng ở mức R1 (35%)
        double SecondClosePercent;        // % đóng ở mức R2 (35%)
        bool   MoveToBreakEven;           // Chuyển SL về BE sau khi đóng phần đầu
        double BreakEvenBuffer;           // Buffer cho breakeven (points)
    };
    
    PartialCloseConfig PartialClose;
    
    // Cấu hình News Filter - v14.0
    struct NewsFilterConfig {
        bool   EnableNewsFilter;          // Bật lọc tin tức
        int    HighImpactMinutesBefore;   // Phút trước tin tức tác động cao (30)
        int    HighImpactMinutesAfter;    // Phút sau tin tức tác động cao (15)
        int    MediumImpactMinutesBefore; // Phút trước tin tức tác động trung bình (15)
        int    MediumImpactMinutesAfter;  // Phút sau tin tức tác động trung bình (10)
        string NewsDataFile;              // File dữ liệu tin tức (CSV)
        int    UpdateIntervalHours;       // Thời gian cập nhật tin tức (giờ)
    };
    
    NewsFilterConfig NewsFilter;
    
    // Cấu hình cache
    int    CacheTimeSeconds;             // Thời gian cache theo giây
    bool   UseBartimeCache;              // Sử dụng bar time để cache
    
    // Smart trailing
    struct TrailingConfig {
        bool   EnableSmartTrailing;      // Kích hoạt SmartTrailing
        bool   EnableRMultipleTrailing;  // Kích hoạt trailing theo R-multiple
        double BreakEvenRMultiple;       // R-multiple để đặt BE (1.0R)
        double FirstLockRMultiple;       // R-multiple để khóa lần đầu (1.5R)
        double SecondLockRMultiple;      // R-multiple để khóa lần hai (2.5R)
        double ThirdLockRMultiple;       // R-multiple để khóa lần ba (3.5R)
        double LockPercentageFirst;      // % khóa lần đầu (thường 33%)
        double LockPercentageSecond;     // % khóa lần hai (thường 50%)
        double LockPercentageThird;      // % khóa lần ba (thường 75%)
        double TrailingSensitivity;      // Độ nhạy của trailing (1.0 = tiêu chuẩn)
    };
    
    TrailingConfig Trailing;
    
    // AutoPause - v14.0 cải tiến
    struct AutoPauseConfig {
        bool   EnableAutoPause;           // Kích hoạt tự động dừng
        bool   EnableAutoResume;          // Kích hoạt tự động tiếp tục
        int    ConsecutiveLossesLimit;    // Số lỗ liên tiếp tối đa trước khi dừng
        double DailyLossPercentLimit;     // % lỗ trong ngày tối đa trước khi dừng
        double VolatilitySpikeFactor;     // Hệ số tăng đột biến để pause (3.0 = 300%)
        int    PauseMinutes;              // Số phút dừng
        bool   SkipTradeOnExtremeVolatility; // Bỏ qua trade khi volatility quá cao
        bool   ResumeOnSessionChange;     // Tiếp tục khi chuyển phiên
        bool   ResumeOnNewDay;            // Tiếp tục khi sang ngày mới
    };
    
    AutoPauseConfig AutoPause;
    
    // Tham số ngôn ngữ và log
    bool   EnableDetailedLogs;
    
    // Tham số bảo vệ drawdown và biến động
    bool   EnableDrawdownProtection;    // Bật bảo vệ drawdown
    bool   EnableVolatilityFiltering;   // Bật lọc theo biến động
    
    // Cấu hình chu kỳ risk
    bool   EnableWeeklyCycle;            // Bật chu kỳ tuần
    bool   EnableMonthlyCycle;           // Bật chu kỳ tháng
    double WeeklyLossReduceFactor;       // Hệ số giảm risk nếu tuần lỗ
    double MonthlyProfitBoostFactor;     // Hệ số tăng risk nếu tháng lời
    int    ConsecutiveProfitDaysBoost;   // Số ngày lời liên tiếp để tăng
    double MaxCycleRiskBoost;            // Giới hạn tăng risk tối đa
    double MaxCycleRiskReduction;        // Giới hạn giảm risk tối đa
    
    // Cấu hình thêm v14.0
    bool   PropFirmMode;                 // Chế độ Prop Firm (bảo thủ hơn)
    bool   ApplyVolatilityAdjustment;    // Áp dụng điều chỉnh theo biến động
    double SpreadFactorLimit;            // Giới hạn spread (hệ số so với trung bình)
    
    // Constructor với giá trị mặc định
    SRiskOptimizerConfig() {
        RiskPercent = 1.0;
        SL_ATR_Multiplier = 1.5;
        TP_RR_Ratio = 2.0;
        MaxAllowedDrawdown = 10.0;
        
        // Cấu hình pullback mới (v14.0)
        MinPullbackPercent = 20.0;
        MaxPullbackPercent = 70.0;
        RequirePriceAction = true;
        RequireMomentum = false;  // Không bắt buộc, chỉ cần 1 trong 2
        RequireVolume = false;    // Không bắt buộc, chỉ cần 1 trong 2
        
        DrawdownReduceThreshold = 5.0;
        EnableTaperedRisk = true;
        MinRiskMultiplier = 0.3;
        
        UseFixedMaxRiskUSD = false;
        MaxRiskUSD = 500.0;
        MaxRiskPercent = 2.0;
        
        // Cấu hình scaling v14.0
        EnableScaling = true;
        MaxScalingCount = 1;             // Giảm từ 2 xuống 1
        ScalingRiskPercent = 0.3;        // Giảm từ 0.4 xuống 0.3
        RequireBreakEvenForScaling = true;
        ScalingRequiresClearTrend = true; // Thêm mới v14.0
        MinRMultipleForScaling = 1.0;     // Thêm mới v14.0
        
        UseChandelierExit = true;
        ChandelierLookback = 20;
        ChandelierATRMultiplier = 3.0;
        
        TrailingFactorTrend = 1.2;
        TrailingFactorRanging = 0.8;
        TrailingFactorVolatile = 1.5;
        
        CacheTimeSeconds = 10;
        UseBartimeCache = true;
        
        // Cấu hình đóng từng phần v14.0
        PartialClose.UsePartialClose = true;
        PartialClose.FirstRMultiple = 1.0;
        PartialClose.SecondRMultiple = 2.0;
        PartialClose.FirstClosePercent = 35.0;
        PartialClose.SecondClosePercent = 35.0;
        PartialClose.MoveToBreakEven = true;
        PartialClose.BreakEvenBuffer = 5.0;
        
        // Cấu hình lọc tin tức v14.0
        NewsFilter.EnableNewsFilter = true;
        NewsFilter.HighImpactMinutesBefore = 30;
        NewsFilter.HighImpactMinutesAfter = 15;
        NewsFilter.MediumImpactMinutesBefore = 15;
        NewsFilter.MediumImpactMinutesAfter = 10;
        NewsFilter.NewsDataFile = "news_calendar.csv";
        NewsFilter.UpdateIntervalHours = 12;
        
        // Smart trailing mặc định
        Trailing.EnableSmartTrailing = true;
        Trailing.EnableRMultipleTrailing = true;
        Trailing.BreakEvenRMultiple = 1.0;
        Trailing.FirstLockRMultiple = 1.5;
        Trailing.SecondLockRMultiple = 2.5;
        Trailing.ThirdLockRMultiple = 3.5;
        Trailing.LockPercentageFirst = 33.0;
        Trailing.LockPercentageSecond = 50.0;
        Trailing.LockPercentageThird = 75.0;
        Trailing.TrailingSensitivity = 1.0;
        
        // AutoPause mặc định
        AutoPause.EnableAutoPause = true;
        AutoPause.EnableAutoResume = true;
        AutoPause.ConsecutiveLossesLimit = 4;
        AutoPause.DailyLossPercentLimit = 3.0;
        AutoPause.VolatilitySpikeFactor = 3.0;
        AutoPause.PauseMinutes = 120;
        AutoPause.SkipTradeOnExtremeVolatility = true;
        AutoPause.ResumeOnSessionChange = true;
        AutoPause.ResumeOnNewDay = true;
        
        // Chu kỳ risk mặc định
        EnableWeeklyCycle = true;
        EnableMonthlyCycle = true;
        WeeklyLossReduceFactor = 0.8;    // Giảm 20% nếu tuần lỗ
        MonthlyProfitBoostFactor = 1.1;  // Tăng 10% nếu tháng lời
        ConsecutiveProfitDaysBoost = 3;  // Sau 3 ngày lời liên tiếp
        MaxCycleRiskBoost = 1.3;         // Tối đa tăng 30%
        MaxCycleRiskReduction = 0.6;     // Tối thiểu còn 60%
        
        // Cấu hình mới v14.0
        PropFirmMode = false;            // Mặc định tắt
        ApplyVolatilityAdjustment = true;
        SpreadFactorLimit = 2.0;         // Giới hạn spread gấp 2 lần trung bình
        
        // Thiết lập log mặc định
        EnableDetailedLogs = false;      // Mặc định tắt log chi tiết
    }
};

// Enum cho nguyên nhân pause
enum ENUM_PAUSE_REASON {
    PAUSE_NONE,                // Không pause
    PAUSE_CONSECUTIVE_LOSSES,  // Lỗ liên tiếp
    PAUSE_DAILY_LOSS_LIMIT,    // Lỗ trong ngày
    PAUSE_VOLATILITY_SPIKE,    // Biến động cao
    PAUSE_NEWS_FILTER,         // Tin tức quan trọng (v14.0)
    PAUSE_MANUAL               // Dừng thủ công
};

// Enum cho các chiến lược giao dịch
enum ENUM_TRADING_STRATEGY {
    STRATEGY_BREAKOUT,           // Breakout - khi xu hướng mạnh
    STRATEGY_PULLBACK,           // Pullback - khi xu hướng ổn định
    STRATEGY_MEAN_REVERSION,     // Mean reversion - khi sideway
    STRATEGY_VOLATILITY_BREAKOUT, // Volatility breakout - khi biến động thấp chuẩn bị bùng nổ
    STRATEGY_PRESERVATION        // Preservation - khi thị trường bất ổn
};

// Struct cho trạng thái pause
struct PauseState {
    bool       ShouldPause;             // Có nên pause không
    ENUM_PAUSE_REASON Reason;           // Lý do pause
    int        PauseMinutes;            // Số phút pause
    string     Message;                 // Thông báo
};

// Cập nhật cấu trúc TrailingAction để lưu thông tin trailing
struct TrailingAction {
    bool   ShouldTrail;       // Có nên trailing không
    double NewStopLoss;       // Mức SL mới nếu trailing
    double LockPercentage;    // % lợi nhuận cần khóa
    double RMultiple;         // R-multiple hiện tại
    ENUM_TRAILING_PHASE Phase; // Giai đoạn trailing
};

// Helper class cho CSafeDataProvider trong namespace ApexPullback
class CRiskDataProvider {
private:
    CMarketProfile* m_MarketProfile;
    CSwingPointDetector* m_SwingDetector;
    CLogger* m_Logger;
                
public:
    // Constructor
    CRiskDataProvider(CMarketProfile* marketProfile, CSwingPointDetector* swingDetector, CLogger* logger) :
        m_MarketProfile(marketProfile),
        m_SwingDetector(swingDetector),
        m_Logger(logger) {}
                    
    // Calculate risk multiplier based on signal quality
    double CalculateQualityBasedRiskMultiplier(double signalQuality) {
        // Ensure signal quality is in valid range
        signalQuality = MathMax(0.0, MathMin(1.0, signalQuality));
                    
        // Scale risk based on quality - higher quality means higher risk allowed
        // Quality 0.0-0.3: 0.5x risk
        // Quality 0.3-0.7: linear scaling from 0.5x to 1.0x
        // Quality 0.7-1.0: linear scaling from 1.0x to 1.2x
        if (signalQuality < 0.3) return 0.5;
        if (signalQuality < 0.7) return 0.5 + (signalQuality - 0.3) * (0.5 / 0.4);
        return 1.0 + (signalQuality - 0.7) * (0.2 / 0.3);
    }
        
    // Safe current session getter
    ENUM_SESSION GetSafeCurrentSession(string symbol) {
        if (m_MarketProfile == NULL) {
            if (m_Logger != NULL)
                m_Logger.LogError("SafeDataProvider: MarketProfile chưa được khởi tạo!");
            return SESSION_UNKNOWN;
        }

        return m_MarketProfile.GetCurrentSession();
    }
};

//====================================================
//+------------------------------------------------------------------+
//| CRiskOptimizer - Module xử lý tối ưu hóa quản lý rủi ro                |
//+------------------------------------------------------------------+
class CRiskOptimizer {
private:
    string m_Symbol;
    ENUM_TIMEFRAMES m_MainTimeframe;
    
    // Các module liên kết - không cần tiền tố vì đã ở trong namespace ApexPullback
    CMarketProfile* m_Profile;
    CSwingPointDetector* m_SwingDetector;
    CLogger* m_Logger;
    CSafeDataProvider* m_SafeData;
    CAssetProfiler* m_AssetProfiler;   // Mới v14.0
    CNewsFilter* m_NewsFilter;      // Mới v14.0
    
    // Các biến trạng thái
    SRiskOptimizerConfig m_Config;
    
    // Biến cache indicator
    double m_AverageATR;
    double m_LastATR;
    double m_LastVolatilityRatio;
    datetime m_LastCalculationTime;
    datetime m_LastBarTime;
    
    // Biến theo dõi lợi nhuận và chu kỳ
    double m_WeeklyProfit;
    double m_MonthlyProfit;
    int m_ConsecutiveProfitDays;
    datetime m_LastWeekMonday;
    int m_CurrentMonth;
    
    // Trạng thái tạm dừng
    bool m_IsPaused;
    datetime m_PauseUntil;
    ENUM_SESSION m_LastSession;
    
    // Trạng thái giao dịch
    int m_LastTradeDay;
    double m_DayStartBalance;
    double m_CurrentDailyLoss;
    double m_LastTrailingStop;
    ENUM_TRAILING_PHASE m_CurrentTrailingPhase;
    ENUM_MARKET_STRATEGY m_CurrentStrategy;
    datetime m_LastStrategyUpdateTime;
    int m_ConsecutiveLosses;
    int m_TotalTradesDay;
    bool m_IsNewBar;
    int m_ScalingCount;
    
    // Lịch sử spread
    double m_SpreadHistory[20];
    
    // Phương thức private hỗ trợ
    bool ValidateMomentumAlternative(bool isLong); // Phương pháp thay thế khi không có profile
    double GetSLMultiplierForCluster(ENUM_CLUSTER_TYPE cluster); // Hệ số SL dựa trên loại cluster
    double GetTPMultiplierForCluster(ENUM_CLUSTER_TYPE cluster); // Hệ số TP dựa trên loại cluster
    double GetTrailingFactorForRegime(ENUM_MARKET_REGIME regime); // Hệ số trailing stop theo regime
    
public:
//| Constructor - Khởi tạo với thông số mặc định nâng cao            |
//+------------------------------------------------------------------+
CRiskOptimizer() : 
    m_Profile(NULL),
    m_SwingDetector(NULL),
    m_Logger(NULL),
    m_SafeData(NULL),
    m_AssetProfiler(NULL),   // Mới v14.0
    m_NewsFilter(NULL),      // Mới v14.0
    m_Symbol(""),
    m_MainTimeframe(PERIOD_H4),
    m_AverageATR(0.0),
    m_LastATR(0.0),
    m_LastVolatilityRatio(1.0),
    m_LastCalculationTime(0),
    m_LastBarTime(0),
    m_WeeklyProfit(0.0),
    m_MonthlyProfit(0.0),
    m_ConsecutiveProfitDays(0),
    m_LastWeekMonday(0),
    m_CurrentMonth(0),
    m_IsPaused(false),
    m_PauseUntil(0),
    m_LastSession(SESSION_CLOSING),
    m_LastTradeDay(0),
    m_DayStartBalance(0.0),
    m_CurrentDailyLoss(0.0),
    m_LastTrailingStop(0.0),
    m_CurrentTrailingPhase(TRAILING_NONE),
    m_CurrentStrategy(STRATEGY_AGGRESSIVE),
    m_LastStrategyUpdateTime(0),
    m_ConsecutiveLosses(0),
    m_TotalTradesDay(0),
    m_IsNewBar(false),
    m_ScalingCount(0)
{
    // Khởi tạo config với giá trị mặc định
    m_Config = SRiskOptimizerConfig();
    
    // Khởi tạo mảng lưu trữ spread
    for (int i = 0; i < 10; i++) {
        m_SpreadHistory[i] = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskOptimizer::~CRiskOptimizer()
{
    // Giải phóng các handles trước khi xóa đối tượng
    ReleaseHandles();
    
    // Giải phóng bộ nhớ SafeDataProvider
    if (m_SafeData != NULL) {
        delete m_SafeData;
        m_SafeData = NULL;
    }
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo RiskOptimizer                              |
//+------------------------------------------------------------------+
bool CRiskOptimizer::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, double riskPercent, double atrMultSL, double atrMultTP)
{
    m_Symbol = symbol;
    m_MainTimeframe = timeframe;
    m_Config.RiskPercent = riskPercent;
    m_Config.SL_ATR_Multiplier = atrMultSL;
    m_Config.TP_RR_Ratio = atrMultTP;
    
    // Nếu logger chưa được khởi tạo, tạo logger mới
    if (m_Logger == NULL) {
        m_Logger = new CLogger();
        if (m_Logger == NULL) {
            Print("ERROR: Không thể tạo Logger");
            return false;
        }
        m_Logger.Initialize("RiskOptimizer", false, false);
    }
    
    // Khởi tạo SafeDataProvider
    m_SafeData = new CSafeDataProvider();
    if (m_SafeData == NULL) {
        if (m_Logger != NULL)
            m_Logger.LogError("Không thể khởi tạo SafeDataProvider");
        return false;
    }
    
    // Initialize với các tham số cần thiết
    if (!m_SafeData.Initialize(symbol, timeframe, m_Logger)) {
        if (m_Logger != NULL)
            m_Logger.LogError("Không thể initialize SafeDataProvider");
        return false;
    }
    
    // Khởi tạo các biến trạng thái
    m_IsPaused = false;
    m_PauseUntil = 0;
    m_LastSession = SESSION_CLOSING;
    m_LastTradeDay = 0;
    m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_CurrentDailyLoss = 0.0;
    m_ConsecutiveLosses = 0;
    m_TotalTradesDay = 0;
    m_ScalingCount = 0;
    
    // Cập nhật trạng thái ngày
    UpdateDailyState();
    
    if (m_Logger != NULL) {
        m_Logger-.LogInfo(StringFormat(
            "RiskOptimizer v14.0 khởi tạo: %s, Risk=%.2f%%, SL ATR=%.2f, TP RR=%.2f", 
            m_Symbol, m_Config.RiskPercent, m_Config.SL_ATR_Multiplier, m_Config.TP_RR_Ratio
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdateDailyState - Cập nhật trạng thái hàng ngày                  |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateDailyState()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Cập nhật giá trị ngày
    int currentDay = dt.day;
    
    // Nếu là ngày mới, reset các biến ngày
    if (currentDay != m_LastTradeDay && m_LastTradeDay > 0) {
        // Lưu số dư đầu ngày
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_CurrentDailyLoss = 0;
        m_TotalTradesDay = 0;
        
        // Reset các biến khác nếu cần
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Ngày mới - Reset trạng thái giao dịch hàng ngày");
        }
    }
    
    // Cập nhật ngày hiện tại
    m_LastTradeDay = currentDay;
}

//+------------------------------------------------------------------+
//| SetSwingPointDetector - Thiết lập Swing Point Detector           |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetSwingPointDetector(CSwingPointDetector* swingDetector)
{
    if (swingDetector == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập SwingPointDetector (NULL)");
        return false;
    }
    
    m_SwingDetector = swingDetector;
    return true;
}

//+------------------------------------------------------------------+
//| SetAssetProfiler - Thiết lập Asset Profiler (mới v14.0)          |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetAssetProfiler(CAssetProfiler* assetProfiler)
{
    if (assetProfiler == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập AssetProfiler (NULL)");
        return false;
    }
    
    m_AssetProfiler = assetProfiler;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("AssetProfiler được thiết lập thành công");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| SetNewsFilter - Thiết lập News Filter (mới v14.0)                |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetNewsFilter(CNewsFilter* newsFilter)
{
    if (newsFilter == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập NewsFilter (NULL)");
        return false;
    }
    
    m_NewsFilter = newsFilter;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("NewsFilter được thiết lập thành công");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdateMarketProfile - Cập nhật liên kết tới Market Profile       |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateMarketProfile(CMarketProfile* profile)
{
    m_Profile = profile;
    
    // Kiểm tra bar mới khi cập nhật profile
    static datetime lastBarTime = 0;
    datetime currentBarTime = 0;
    
    if (m_SafeData != NULL) {
        currentBarTime = m_SafeData.GetCurrentBarTime(m_MainTimeframe);
        if (currentBarTime > 0 && currentBarTime != lastBarTime) {
            m_IsNewBar = true;
            lastBarTime = currentBarTime;
        } else {
            m_IsNewBar = false;
        }
    }
    
    // Tính toán tỷ lệ biến động (Volatility Ratio) mới
    if (m_IsNewBar || m_LastVolatilityRatio <= 0) {
        m_LastVolatilityRatio = GetVolatilityAdjustmentFactor();
    }
}

//+------------------------------------------------------------------+
//| GetVolatilityRatio - Tính tỷ lệ biến động hiện tại so với trung bình |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetVolatilityRatio()
{
    // Nếu đã có cache thì trả về
    if (!NeedToUpdateCache() && m_LastVolatilityRatio > 0) {
        return m_LastVolatilityRatio;
    }
    
    // Tính toán mới
    m_LastVolatilityRatio = GetVolatilityAdjustmentFactor();
    return m_LastVolatilityRatio;
}

//+------------------------------------------------------------------+
//| GetVolatilityAdjustmentFactor - Tính hệ số điều chỉnh biến động   |
//+------------------------------------------------------------------+
//| GetVolatilityAdjustmentFactor - Tính hệ số điều chỉnh biến động   |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetVolatilityAdjustmentFactor()
{
    // Hàm này được đơn giản hóa để tránh trùng lắp với phiên bản đầy đủ ở sau
    // Phiên bản đầy đủ đã được định nghĩa ở phần sau của file
    return 1.0; // Giá trị mặc định
}


//+------------------------------------------------------------------+
//| CalculateAverageATR - Tính ATR trung bình trong period ngày      |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateAverageATR(int period)
{
    if (period <= 0) return 0;
    
    // Lấy giá trị ATR cho nhiều ngày
    double atrArray[];
    ArrayResize(atrArray, period);
    
    // Handle ATR indicator
    int atrHandle = iATR(m_Symbol, m_MainTimeframe, 14);
    if (atrHandle == INVALID_HANDLE) {
        if (m_Logger != NULL) {
            m_Logger.LogError("Không thể tạo ATR handle trong CalculateAverageATR");
        }
        return 0;
    }
    
    // Sao chép giá trị
    int copied = CopyBuffer(atrHandle, 0, 0, period, atrArray);
    IndicatorRelease(atrHandle);
    
    if (copied != period) {
        if (m_Logger != NULL) {
            m_Logger.LogWarning(StringFormat("Chỉ sao chép được %d/%d giá trị ATR", copied, period));
        }
        if (copied <= 0) return 0;
    }
    
    // Tính trung bình
    double sum = 0;
    for (int i = 0; i < copied; i++) {
        sum += atrArray[i];
    }
    
    return sum / copied;
}

//+------------------------------------------------------------------+
//| SetDrawdownParameters - Thiết lập các tham số điều chỉnh risk DD |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetDrawdownParameters(double threshold, bool enableTapered, double minRiskMultiplier)
{
    m_Config.DrawdownReduceThreshold = threshold;
    m_Config.EnableTaperedRisk = enableTapered;
    m_Config.MinRiskMultiplier = minRiskMultiplier;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập DrawdownParameters: Threshold=%.2f%%, Tapered=%s, MinMultiplier=%.2f", 
            m_Config.DrawdownReduceThreshold, m_Config.EnableTaperedRisk ? "true" : "false", m_Config.MinRiskMultiplier
        ));
    }
}

//+------------------------------------------------------------------+
//| SetChandelierExit - Thiết lập thông số Chandelier Exit           |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetChandelierExit(bool useChande, int lookback, double atrMult)
{
    m_Config.UseChandelierExit = useChande;
    m_Config.ChandelierLookback = lookback;
    m_Config.ChandelierATRMultiplier = atrMult;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Chandelier Exit: Enabled=%s, Lookback=%d, AtrMultiplier=%.2f", 
            m_Config.UseChandelierExit ? "true" : "false", m_Config.ChandelierLookback, m_Config.ChandelierATRMultiplier
        ));
    }
}

//+------------------------------------------------------------------+
//| SetDetailedLogging - Thiết lập chi tiết logging                  |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetDetailedLogging(bool enable)
{
    m_Config.EnableDetailedLogs = enable;
    
    if (m_Logger != NULL) m_Logger.LogDebug(StringFormat("RiskOptimizer: Detailed logging %s", enable ? "enabled" : "disabled"));
}

//+------------------------------------------------------------------+
//| SetRiskLimits - Thiết lập giới hạn risk                          |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetRiskLimits(bool useFixedUSD, double maxUSD, double maxPercent)
{
    m_Config.UseFixedMaxRiskUSD = useFixedUSD;
    m_Config.MaxRiskUSD = maxUSD;
    m_Config.MaxRiskPercent = maxPercent;
    
    if (m_Logger != NULL) {
        string limitType = useFixedUSD ? "USD cố định" : "% Balance";
        string limitValue = useFixedUSD ? "$" + DoubleToString(maxUSD, 2) : DoubleToString(maxPercent, 2) + "%";
        
        m_Logger.LogInfo(StringFormat(
            "Thiết lập giới hạn risk: Loại=%s, Giá trị=%s", 
            limitType, limitValue
        ));
    }
}

//+------------------------------------------------------------------+
//| SetScalingParameters - Thiết lập tham số nhồi lệnh (v14.0)       |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetScalingParameters(bool enable, int maxCount, double riskPercent, 
                                        bool requireBE, bool requireTrend, double minRMultiple)
{
    // Thiết lập các tham số scaling
    m_Config.EnableScaling = enable;
    m_Config.MaxScalingCount = maxCount;
    m_Config.ScalingRiskPercent = riskPercent;
    m_Config.RequireBreakEvenForScaling = requireBE;
    m_Config.ScalingRequiresClearTrend = requireTrend;
    m_Config.MinRMultipleForScaling = minRMultiple;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Scaling: Enable=%s, MaxCount=%d, Risk=%.2f%%, RequireBE=%s, RequireTrend=%s, MinRMultiple=%.1f",
            enable ? "true" : "false", maxCount, riskPercent, 
            requireBE ? "true" : "false", requireTrend ? "true" : "false", minRMultiple
        ));
    }
}

//+------------------------------------------------------------------+
//| SetPartialCloseParameters - Thiết lập đóng từng phần (v14.0)     |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetPartialCloseParameters(bool enable, double r1, double r2, 
                                             double percent1, double percent2, bool moveToBE)
{
    // Thiết lập tham số đóng từng phần
    m_Config.PartialClose.UsePartialClose = enable;
    m_Config.PartialClose.FirstRMultiple = r1;
    m_Config.PartialClose.SecondRMultiple = r2;
    m_Config.PartialClose.FirstClosePercent = percent1;
    m_Config.PartialClose.SecondClosePercent = percent2;
    m_Config.PartialClose.MoveToBreakEven = moveToBE;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Partial Close: Enable=%s, R1=%.1f, R2=%.1f, %%1=%.1f, %%2=%.1f, MoveBE=%s",
            enable ? "true" : "false", r1, r2, percent1, percent2, moveToBE ? "true" : "false"
        ));
    }
}

//+------------------------------------------------------------------+
//| SetNewsFilterParameters - Thiết lập lọc tin tức (v14.0)          |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetNewsFilterParameters(bool enable, int highBefore, int highAfter, 
                                           int mediumBefore, int mediumAfter, string dataFile)
{
    // Thiết lập tham số lọc tin tức
    m_Config.NewsFilter.EnableNewsFilter = enable;
    m_Config.NewsFilter.HighImpactMinutesBefore = highBefore;
    m_Config.NewsFilter.HighImpactMinutesAfter = highAfter;
    m_Config.NewsFilter.MediumImpactMinutesBefore = mediumBefore;
    m_Config.NewsFilter.MediumImpactMinutesAfter = mediumAfter;
    m_Config.NewsFilter.NewsDataFile = dataFile;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập News Filter: Enable=%s, HighBefore=%d, HighAfter=%d, MediumBefore=%d, MediumAfter=%d, File=%s",
            enable ? "true" : "false", highBefore, highAfter, mediumBefore, mediumAfter, dataFile
        ));
    }
    
    // Áp dụng cấu hình vào NewsFilter object nếu có
    if (m_NewsFilter != NULL && enable) {
        m_NewsFilter.Configure(highBefore, highAfter, mediumBefore, mediumAfter);
    }
}

//+------------------------------------------------------------------+
//| EnablePropFirmMode - Bật/tắt chế độ Prop Firm (v14.0)            |
//+------------------------------------------------------------------+
void CRiskOptimizer::EnablePropFirmMode(bool enable)
{
    m_Config.PropFirmMode = enable;
    
    // Điều chỉnh các tham số khác để phù hợp với Prop Firm mode
    if (enable) {
        // Chế độ Prop Firm: Bảo thủ hơn, bảo vệ vốn là ưu tiên hàng đầu
        m_Config.MaxRiskPercent = MathMin(m_Config.MaxRiskPercent, 1.5);  // Giới hạn tối đa 1.5%
        m_Config.DrawdownReduceThreshold = MathMin(m_Config.DrawdownReduceThreshold, 5.0); // Bắt đầu giảm risk sớm hơn
        m_Config.MaxAllowedDrawdown = MathMin(m_Config.MaxAllowedDrawdown, 8.0); // DD tối đa thấp hơn
        m_Config.AutoPause.DailyLossPercentLimit = MathMin(m_Config.AutoPause.DailyLossPercentLimit, 3.0); // Giới hạn lỗ ngày thấp hơn
        m_Config.ScalingRiskPercent = 0.25; // Giảm risk khi scaling nhiều hơn
        m_Config.EnableWeeklyCycle = true;  // Bật chu kỳ weekly
        m_Config.WeeklyLossReduceFactor = 0.7; // Giảm risk mạnh hơn khi tuần lỗ
    }
    
    if (m_Logger != NULL) {
        if (enable) {
            m_Logger.LogInfo("Đã bật chế độ Prop Firm - Tăng cường bảo vệ vốn");
        } else {
            m_Logger.LogInfo("Đã tắt chế độ Prop Firm");
        }
    }
}

//+------------------------------------------------------------------+
//| Giải phóng các handles tài nguyên                                |
//+------------------------------------------------------------------+
void CRiskOptimizer::ReleaseHandles() {
    // Giải phóng tất cả indicator handles nếu có
    if (m_Logger != NULL) {
        m_Logger.LogDebug("Giải phóng indicator handles trong RiskOptimizer");
    }
}

//+------------------------------------------------------------------+
//| Get valid ATR value with fallback                                |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetValidATR()
{
    // Kiểm tra xem có cần cập nhật cache không
    if (!NeedToUpdateCache() && m_LastATR > 0) {
        return m_LastATR; // Sử dụng cache
    }
    
    // Ưu tiên lấy ATR từ AssetProfiler (nếu có)
    if (m_AssetProfiler != NULL) {
        double assetATR = m_AssetProfiler.GetAssetATR(m_Symbol, m_MainTimeframe);
        if (assetATR > 0) {
            // Cập nhật cache và trả về giá trị
            m_LastATR = assetATR;
            m_LastCalculationTime = TimeCurrent();
            return assetATR;
        }
    }
    
    // Dùng SafeDataProvider để lấy ATR an toàn
    double atr = 0;
    if (m_SafeData != NULL) {
        atr = m_SafeData.GetSafeATR(m_Profile, m_MainTimeframe);
    } else {
        // Fallback nếu SafeDataProvider chưa được khởi tạo
        
        // Kết nối với MarketProfile nếu có
        if (m_Profile != NULL) {
            double currentATR = m_Profile.GetATRH4();
            if (currentATR > 0) {
                atr = currentATR;
            }
        }
        
        // Nếu không có giá trị hợp lệ, thử lấy giá trị từ thời gian hiện tại
        if (atr <= 0) {
            int handle = iATR(m_Symbol, m_MainTimeframe, 14);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    atr = buffer[0];
                }
                IndicatorRelease(handle);
            }
            
            if (atr <= 0) {
                // Fallback cuối cùng
                atr = SymbolInfoDouble(m_Symbol, SYMBOL_POINT) * 100;
                if (m_Logger != NULL) m_Logger.LogWarning("Sử dụng giá trị ATR dự phòng");
            }
        }
    }
    
    // Cập nhật giá trị cache
    m_LastATR = atr;
    m_LastCalculationTime = TimeCurrent();
    
    return atr;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có cần cập nhật cache                               |
//+------------------------------------------------------------------+
bool CRiskOptimizer::NeedToUpdateCache()
{
    datetime currentTime = TimeCurrent();
    
    // Đánh dấu các bar mới - phương pháp hiệu quả nhất
    datetime currentBarTime = 0;
    
    if (m_SafeData != NULL) {
        currentBarTime = m_SafeData.GetCurrentBarTime(m_MainTimeframe);
        
        // Nếu bar mới, luôn cập nhật cache
        if (currentBarTime > 0 && currentBarTime != m_LastBarTime) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug("Cập nhật cache do bar mới");
            }
            m_LastBarTime = currentBarTime;
            return true;
        }
    }
    
    // Kiểm tra theo thởi gian cache
    if (m_LastCalculationTime == 0 || 
        (currentTime - m_LastCalculationTime) >= m_Config.CacheTimeSeconds) {
        return true;
    }
    
    // Phát hiện biến động mạnh bất thường (cần cập nhật cache gấp)
    if (DetectSuddenVolatilitySpike()) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Cập nhật cache do phát hiện biến động đột biến");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện biến động đột biến để cập nhật cache                   |
//+------------------------------------------------------------------+
bool CRiskOptimizer::DetectSuddenVolatilitySpike()
{
    // Tính tỷ lệ biến động mới 
    double currentATR = 0;
    
    int atrHandle = iATR(m_Symbol, m_MainTimeframe, 14);
    if (atrHandle == INVALID_HANDLE) {
        return false;
    }
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if (CopyBuffer(atrHandle, 0, 0, 1, buffer) <= 0) {
        IndicatorRelease(atrHandle);
        return false;
    }
    
    currentATR = buffer[0];
    IndicatorRelease(atrHandle);
    
    if (currentATR > 0 && m_LastATR > 0) {
        // Nếu ATR tăng hơn 50% trong thởi gian ngắn - dấu hiệu biến động đột biến
        if (currentATR > m_LastATR * 1.5) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get volatility adjustment factor with improved handling          |
//+------------------------------------------------------------------+
// Hàm được đổi tên để tránh xung đột với hàm GetVolatilityAdjustmentFactor đã định nghĩa trước đó
double CRiskOptimizer::GetVolatilityAdjustmentFactorDetailed()
{
    // Kiểm tra cache
    if (!NeedToUpdateCache() && m_LastVolatilityRatio > 0) {
        return m_LastVolatilityRatio;
    }
    
    // Ưu tiên lấy volatility ratio từ AssetProfiler
    if (m_AssetProfiler != NULL) {
        double assetVolatilityRatio = m_AssetProfiler.GetVolatilityRatio(m_Symbol);
        if (assetVolatilityRatio > 0) {
            m_LastVolatilityRatio = assetVolatilityRatio;
            return assetVolatilityRatio;
        }
    }
    
    // Lấy volatility ratio từ SafeDataProvider nếu có
    double volatilityRatio = 1.0;
    if (m_SafeData != NULL) {
        volatilityRatio = m_SafeData.GetSafeVolatilityRatio();
    } else if (m_Profile != NULL) {
        // Thử lấy từ profile
        volatilityRatio = m_Profile.GetVolatilityRatio();
        
        // Nếu không lấy được, tính thủ công
        if (volatilityRatio <= 0 && m_AverageATR > 0) {
            double currentATR = GetValidATR();
            if (currentATR > 0) {
                volatilityRatio = currentATR / m_AverageATR;
            }
        }
    }
    
    // Nếu vẫn không có tỷ lệ biến động hợp lệ, trả về 1.0 (không điều chỉnh)
    if (volatilityRatio <= 0) return 1.0;
    
    // Phát hiện và xử lý biến động bất thường
    if (volatilityRatio > 3.0) {
        if (m_Logger != NULL) {
            m_Logger.LogWarning(StringFormat(
                "Phát hiện biến động bất thường: %.2f lần so với bình thường. Áp dụng giới hạn.",
                volatilityRatio
            ));
        }
        
        // Giới hạn lại tỷ lệ biến động
        volatilityRatio = 3.0;
    }
    
    // Tính hệ số điều chỉnh:
    // - Biến động thấp (< 0.8): tăng nhẹ (lên tới 1.2)
    // - Biến động vừa (0.8-1.2): giữ nguyên
    // - Biến động cao (> 1.2): giảm dần (xuống tới 0.7)
    // - Biến động rất cao (> 2.0): giới hạn ở 0.5
    double adjustmentFactor = 1.0;
    
    if (volatilityRatio < 0.8) {
        // Biến động thấp: tăng SL/TP nhưng không quá 1.2
        adjustmentFactor = 1.0 + (0.8 - volatilityRatio) * 0.5;
        adjustmentFactor = MathMin(adjustmentFactor, 1.2);
    }
    else if (volatilityRatio > 1.2) {
        // Biến động cao: giảm SL/TP
        if (volatilityRatio < 2.0) {
            // Áp dụng công thức bậc hai để giảm dần
            adjustmentFactor = 1.0 - (volatilityRatio - 1.2) * 0.25;
        } else {
            // Biến động rất cao (> 2.0): giảm xuống mức tối thiểu
            adjustmentFactor = 0.5;
        }
    }
    
    return adjustmentFactor;
}

//+------------------------------------------------------------------+
//| Tính toán khối lượng giao dịch dựa trên risk percent và SL points |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateLotSizeByRisk(string symbol, double stopLossPoints, double riskPercent) {
    if (stopLossPoints <= 0) {
        if (m_Logger != NULL) {
            m_Logger.LogError(StringFormat(
                "Giá trị stopLossPoints (%.1f) không hợp lệ trong CalculateLotSizeByRisk", 
                stopLossPoints));
        }
        return 0.01; // Giá trị mặc định an toàn
    }
    
    // Lấy số dư tài khoản
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    if (accountBalance <= 0) {
        if (m_Logger != NULL) m_Logger.LogWarning("Số dư tài khoản không hợp lệ");
        return 0.01;
    }
    
    // Tính số tiền được phép risk (theo % hoặc giá trị tối đa cố định)
    double riskAmount = (accountBalance * riskPercent / 100.0);
    
    // Tính tick value (giá trị của 1 tick)
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = (tickValue * _Point) / tickSize;
    
    // Tính toán lot size tối ưu
    double lotSize = riskAmount / (stopLossPoints * pointValue);
    
    // Chuẩn hóa lot size theo quy định của sàn
    lotSize = NormalizeLotSize(symbol, lotSize);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Chuẩn hóa khối lượng giao dịch theo tiêu chuẩn sàn             |
//+------------------------------------------------------------------+
double CRiskOptimizer::NormalizeLotSize(string symbol, double lotSize) {
    if (lotSize <= 0) return 0.01; // Giá trị mặc định an toàn
    
    // Lấy thông tin về khối lượng tối thiểu, tối đa và bước
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // Đảm bảo khối lượng nằm trong giới hạn
    lotSize = MathMax(lotSize, minLot);
    lotSize = MathMin(lotSize, maxLot);
    
    // Làm tròn theo bước khối lượng
    if (stepLot > 0) {
        lotSize = MathFloor(lotSize / stepLot) * stepLot;
    }
    
    // Trả về giá trị đã chuẩn hóa
    return MathMax(lotSize, minLot);
}

} // đóng class CRiskOptimizer

// Đóng namespace ApexPullback
} // end namespace ApexPullback

#endif // _RISK_OPTIMIZER_MQH_