//+------------------------------------------------------------------+
//|            CommonStructs.mqh - APEX Pullback EA v14.0            |
//|      Trái tim của hệ thống - Single Source of Truth Context      |
//+------------------------------------------------------------------+

#ifndef COMMON_STRUCTS_MQH_
#define COMMON_STRUCTS_MQH_

// Phụ thuộc hợp lệ DUY NHẤT của tệp này.
#include "Enums.mqh"



// BẮT ĐẦU NAMESPACE
namespace ApexPullback
{

// Khai báo chuyển tiếp cho chính struct context
struct EAContext;

// --- KHAI BÁO CHUYỂN TIẾP CHO TẤT CẢ CÁC CLASS ---
// Đây là bước cực kỳ quan trọng để ngăn chặn các phụ thuộc vòng (circular dependencies).
// Mỗi file .mqh của module sau đó sẽ #include file này.
// Thứ tự được sắp xếp theo nhóm logic.

// Core Infrastructure
class CLogger;
class CErrorHandler;
class CFunctionStack;
class CParameterStore;
class CStateManager;

// Market & Session Analysis
class CTimeManager;
class CSymbolInfo;
class CBrokerHealthMonitor;
class CSlippageMonitor;
class CAssetDNA;

// Trading & Risk Management
class CMarketProfile;
class CPositionManager;
class CRiskManager;
class CTradeManager;
class CSignalEngine;
class CCircuitBreaker;

// Performance & UI
class CPerformanceAnalytics;
class CDashboard;

class CDrawingUtils;

// Utilities
class CIndicatorUtils;
class CMathHelper;
// --- KẾT THÚC KHAI BÁO CHUYỂN TIẾP ---





//+------------------------------------------------------------------+
//| SInputParameters - Struct duy nhất cho tất cả Input từ người dùng |
//+------------------------------------------------------------------+
struct SInputParameters
{
    //--- General Settings ---
    long                  MagicNumber;          // Magic Number
    string                OrderComment;         // Comment cho lệnh

    //--- Logging & Display ---
    ENUM_LOG_LEVEL        LogLevel;             // Cấp độ log
    ENUM_LOG_OUTPUT       LogOutput;            // Nơi xuất log
    bool                  EnableDetailedLogs;   // Bật/tắt log chi tiết
    string                CsvLogFilename;       // Tên file CSV log
    bool                  DisplayDashboard;       // Hiển thị dashboard
    ENUM_DASHBOARD_THEME  DashboardTheme;       // Chủ đề Dashboard
    int                   UpdateFrequencySeconds; // Tần suất cập nhật (giây)
    bool                  DisableDashboardInBacktest; // Tắt dashboard trong backtest

    //--- Alerts & Notifications ---
    bool                  AlertsEnabled;        // Bật cảnh báo chung
    bool                  SendNotifications;    // Gửi thông báo đẩy (Push)
    bool                  SendEmailAlerts;      // Gửi email
    bool                  EnableTelegramNotify; // Bật thông báo Telegram
    string                TelegramBotToken;     // Token Bot Telegram
    string                TelegramChatID;       // ID Chat Telegram
    bool                  TelegramImportantOnly;// Chỉ gửi thông báo quan trọng

    //--- Core Strategy ---
    ENUM_TIMEFRAMES       MainTimeframe;        // Khung thời gian chính
    int                   EMA_Fast;             // EMA nhanh
    int                   EMA_Medium;           // EMA trung bình
    int                   EMA_Slow;             // EMA chậm
    bool                  UseMultiTimeframe;    // Sử dụng đa khung thời gian
    ENUM_TIMEFRAMES       HigherTimeframe;      // Khung thời gian cao hơn
    ENUM_ALLOWED_DIRECTION AllowedDirection;    // Hướng giao dịch cho phép

    //--- Pullback Definition ---
    bool                  EnablePriceAction;    // Kích hoạt xác nhận Price Action
    bool                  EnableSwingLevels;    // Sử dụng Swing Levels
    double                MinPullbackPercent;   // % Pullback tối thiểu
    double                MaxPullbackPercent;   // % Pullback tối đa
    bool                  RequirePriceActionConfirmation; // Yêu cầu xác nhận Price Action
    bool                  RequireMomentumConfirmation;    // Yêu cầu xác nhận Momentum
    bool                  RequireVolumeConfirmation;      // Yêu cầu xác nhận Volume

    //--- Market Filters ---
    int                   ATR_Period;           // Chu kỳ ATR
    int                   InpADX_Period;        // Chu kỳ ADX
    double                MinADX_Threshold;     // Ngưỡng ADX tối thiểu
    bool                  FilterBySession;      // Lọc theo phiên giao dịch
    ENUM_SESSION_FILTER   SessionFilter;        // Loại phiên giao dịch
    bool                  FilterBySpread;       // Lọc theo spread
    double                MaxSpreadPoints;      // Spread tối đa (points)
    bool                  FilterByVolatility;   // Lọc theo độ biến động
    double                MinVolatility;        // Độ biến động tối thiểu
    double                MaxVolatility;        // Độ biến động tối đa

    //--- Risk Management ---
    ENUM_RISK_MODE        RiskMode;             // Chế độ quản lý rủi ro
    double                FixedLotSize;         // Lot size cố định
    double                RiskPercentage;       // % rủi ro mỗi lệnh
    double                MaxDailyRisk;         // Rủi ro tối đa hàng ngày (%)
    double                MaxWeeklyRisk;        // Rủi ro tối đa hàng tuần (%)
    double                MaxMonthlyRisk;       // Rủi ro tối đa hàng tháng (%)
    double                MaxDrawdownPercent;   // Drawdown tối đa (%)
    bool                  UseEquityStopLoss;    // Sử dụng stop loss theo equity
    double                EquityStopLossPercent;// % stop loss theo equity
    bool                  UseTrailingStop;      // Sử dụng trailing stop
    double                TrailingStopDistance; // Khoảng cách trailing stop (points)
    double                TrailingStepSize;     // Bước di chuyển trailing stop (points)

    //--- Position Management ---
    double                StopLossPoints;       // Stop Loss (points)
    double                TakeProfitPoints;     // Take Profit (points)
    bool                  UseBreakEven;         // Sử dụng break even
    double                BreakEvenPoints;      // Điểm break even (points)
    double                BreakEvenProfit;      // Lợi nhuận để kích hoạt break even (points)
    bool                  UsePartialClose;      // Đóng một phần position
    double                PartialClosePercent;  // % đóng một phần
    double                PartialCloseProfitPoints; // Lợi nhuận để đóng một phần (points)
    int                   MaxPositions;         // Số lệnh tối đa cùng lúc
    int                   MaxDailyTrades;       // Số lệnh tối đa trong ngày
    double                MinDistanceBetweenTrades; // Khoảng cách tối thiểu giữa các lệnh (points)

    //--- Advanced Features ---
    bool                  EnableNewsFilter;     // Bật lọc tin tức
    int                   NewsFilterMinutes;    // Phút tránh trước/sau tin tức
    ENUM_NEWS_IMPACT      NewsImpactLevel;      // Mức độ tác động tin tức
    bool                  EnableCorrelationFilter; // Bật lọc tương quan
    double                MaxCorrelationThreshold; // Ngưỡng tương quan tối đa
    bool                  EnableMarketProfile;  // Bật Market Profile
    bool                  EnableVolumeProfile;  // Bật Volume Profile
    bool                  EnableOrderFlow;      // Bật Order Flow analysis

    //--- Performance & Optimization ---
    bool                  EnablePerformanceTracking; // Bật theo dõi hiệu suất
    bool                  EnableParameterOptimization; // Bật tối ưu tham số
    int                   OptimizationPeriodDays; // Chu kỳ tối ưu (ngày)
    bool                  EnableMonteCarlo;     // Bật mô phỏng Monte Carlo
    int                   MonteCarloRuns;       // Số lần chạy Monte Carlo
    bool                  EnableWalkForward;    // Bật Walk Forward Analysis
    int                   WalkForwardPeriodDays; // Chu kỳ Walk Forward (ngày)

    //--- Circuit Breaker ---
    bool                  EnableCircuitBreaker; // Bật Circuit Breaker
    double                MaxLossPercentage;    // % thua lỗ tối đa để kích hoạt
    int                   MaxConsecutiveLosses; // Số lệnh thua liên tiếp tối đa
    int                   CircuitBreakerCooldownMinutes; // Thời gian nghỉ (phút)
    bool                  AutoResumeAfterCooldown; // Tự động tiếp tục sau nghỉ

    //--- Broker & Execution ---
    int                   MaxSlippagePoints;    // Slippage tối đa cho phép (points)
    int                   MaxExecutionDelayMs;  // Độ trễ thực thi tối đa (ms)
    bool                  RequireECNExecution;  // Yêu cầu thực thi ECN
    bool                  EnableLatencyMonitoring; // Bật giám sát độ trễ
    int                   MaxLatencyMs;         // Độ trễ tối đa (ms)
    bool                  EnableSlippageMonitoring; // Bật giám sát slippage
    double                MaxSlippagePercent;   // Slippage tối đa (%)

    //--- Constructor với giá trị mặc định ---
    SInputParameters() :
        MagicNumber(20241201),
        OrderComment("APEX_v14"),
        LogLevel(LOG_LEVEL_INFO),
        LogOutput(LOG_OUTPUT_BOTH),
        EnableDetailedLogs(true),
        CsvLogFilename("APEX_v14_Log.csv"),
        DisplayDashboard(true),
        DashboardTheme(THEME_DARK),
        UpdateFrequencySeconds(5),
        DisableDashboardInBacktest(true),
        AlertsEnabled(true),
        SendNotifications(false),
        SendEmailAlerts(false),
        EnableTelegramNotify(false),
        TelegramBotToken(""),
        TelegramChatID(""),
        TelegramImportantOnly(true),
        MainTimeframe(PERIOD_H1),
        EMA_Fast(8),
        EMA_Medium(21),
        EMA_Slow(55),
        UseMultiTimeframe(true),
        HigherTimeframe(PERIOD_H4),
        AllowedDirection(DIRECTION_BOTH),
        EnablePriceAction(true),
        EnableSwingLevels(true),
        MinPullbackPercent(23.6),
        MaxPullbackPercent(61.8),
        RequirePriceActionConfirmation(true),
        RequireMomentumConfirmation(true),
        RequireVolumeConfirmation(false),
        ATR_Period(14),
        InpADX_Period(14),
        MinADX_Threshold(25.0),
        FilterBySession(false),
        SessionFilter(SESSION_LONDON_NY),
        FilterBySpread(true),
        MaxSpreadPoints(30),
        FilterByVolatility(true),
        MinVolatility(0.0005),
        MaxVolatility(0.005),
        RiskMode(RISK_PERCENTAGE),
        FixedLotSize(0.1),
        RiskPercentage(2.0),
        MaxDailyRisk(6.0),
        MaxWeeklyRisk(15.0),
        MaxMonthlyRisk(25.0),
        MaxDrawdownPercent(20.0),
        UseEquityStopLoss(true),
        EquityStopLossPercent(10.0),
        UseTrailingStop(false),
        TrailingStopDistance(200),
        TrailingStepSize(50),
        StopLossPoints(500),
        TakeProfitPoints(1000),
        UseBreakEven(true),
        BreakEvenPoints(300),
        BreakEvenProfit(300),
        UsePartialClose(false),
        PartialClosePercent(50.0),
        PartialCloseProfitPoints(500),
        MaxPositions(3),
        MaxDailyTrades(5),
        MinDistanceBetweenTrades(100),
        EnableNewsFilter(false),
        NewsFilterMinutes(30),
        NewsImpactLevel(NEWS_IMPACT_HIGH),
        EnableCorrelationFilter(false),
        MaxCorrelationThreshold(0.8),
        EnableMarketProfile(false),
        EnableVolumeProfile(false),
        EnableOrderFlow(false),
        EnablePerformanceTracking(true),
        EnableParameterOptimization(false),
        OptimizationPeriodDays(30),
        EnableMonteCarlo(false),
        MonteCarloRuns(1000),
        EnableWalkForward(false),
        WalkForwardPeriodDays(7),
        EnableCircuitBreaker(true),
        MaxLossPercentage(5.0),
        MaxConsecutiveLosses(3),
        CircuitBreakerCooldownMinutes(60),
        AutoResumeAfterCooldown(false),
        MaxSlippagePoints(30),
        MaxExecutionDelayMs(1000),
        RequireECNExecution(false),
        EnableLatencyMonitoring(true),
        MaxLatencyMs(500),
        EnableSlippageMonitoring(true),
        MaxSlippagePercent(0.1)
    {}
};

//+------------------------------------------------------------------+
//| EAContext - TRÁI TIM CỦA HỆ THỐNG                                |
//| Chứa tất cả trạng thái, tham số và các đối tượng module.         |
//| Được truyền dưới dạng tham chiếu (&) cho tất cả các module.      |
//+------------------------------------------------------------------+
struct EAContext
{
    // --- Trạng thái và Thông tin Core ---
    long                  MagicNumber;          // Magic Number của EA
    string                EAVersion;            // Phiên bản EA
    ENUM_EA_STATE         CurrentState;         // Trạng thái hiện tại của EA
    bool                  IsBacktest;           // Đang chạy trong backtest?
    bool                  IsOptimization;       // Đang chạy trong optimization?
    MqlTick               LastTick;             // Dữ liệu tick cuối cùng
    bool                  IsNewBarEvent;        // Cờ = true nếu tick hiện tại là tick đầu tiên của một nến mới

    // --- Con trỏ tới các Module chính ---
    // Core Infrastructure
    CLogger*              pLogger;
    CErrorHandler*        pErrorHandler;
    CFunctionStack*       pFuncStack;
    CParameterStore*      pParamStore;
    CStateManager*        pStateMgr;

    // Market & Session Analysis
    CTimeManager*         pTimeMgr;
    CSymbolInfo*          pSymbolInfo;
    CBrokerHealthMonitor* pBrokerHealth;
    CSlippageMonitor*     pSlippageMon;
    CAssetDNA*            pAssetDNA;
    CMarketProfile*       pMarketProfile;

    // Trading & Risk Management
    CSignalEngine*        pSignalEngine;
    CRiskManager*         pRiskMgr;
    CTradeManager*        pTradeMgr;
    CPositionManager*     pPosMgr;
    CCircuitBreaker*      pCircuitBreaker;

    // Performance & UI
    CPerformanceAnalytics* pPerfAnalytics;
    CDashboard*           pDashboard;
    CDrawingUtils*        pDrawing;

    // Utilities
    CIndicatorUtils*      pIndicatorUtils;
    CMathHelper*          pMathHelper;

    // --- Struct chứa TẤT CẢ các tham số Input --- 
    SInputParameters      Inputs;

    // Constructor: Khởi tạo giá trị mặc định
    EAContext() : 
        MagicNumber(0),
        EAVersion("14.0"),
        CurrentState(STATE_INIT),
        IsBacktest(false),
        IsOptimization(false),
        IsNewBarEvent(false),
        // Khởi tạo tất cả con trỏ là NULL
        pLogger(NULL),
        pErrorHandler(NULL),
        pFuncStack(NULL),
        pParamStore(NULL),
        pStateMgr(NULL),
        pTimeMgr(NULL),
        pSymbolInfo(NULL),
        pBrokerHealth(NULL),
        pSlippageMon(NULL),
        pAssetDNA(NULL),
        pMarketProfile(NULL),
        pSignalEngine(NULL),
        pRiskMgr(NULL),
        pTradeMgr(NULL),
        pPosMgr(NULL),
        pCircuitBreaker(NULL),
        pPerfAnalytics(NULL),
        pDashboard(NULL),
        pDrawing(NULL),
        pIndicatorUtils(NULL),
        pMathHelper(NULL)
    {
        // Các khởi tạo khác nếu cần
        ZeroMemory(LastTick);
    }
};



} // KẾT THÚC NAMESPACE ApexPullback

#endif // COMMON_STRUCTS_MQH_
