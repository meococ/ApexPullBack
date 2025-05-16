//+------------------------------------------------------------------+
//|                                       TradeManager.mqh (v13.5)    |
//|                                  Copyright 2023, ApexPullback EA |
//|                                      https://www.apexpullback.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, ApexPullback EA"
#property link      "https://www.apexpullback.com"
#property version   "13.5"
#property strict

// Khai báo thư viện chuẩn
#include <Trade\Trade.mqh>
#include <Arrays\ArrayObj.mqh>

// Nạp các file cấu trúc và module liên quan
#include "CommonStructs.mqh"
#include "Logger.mqh"
#include "MarketProfile.mqh"
#include "RiskOptimizer.mqh"
#include "RiskManager.mqh"

// --- CẤU TRÚC THÔNG TIN THỐNG KÊ MỚI ---
struct StrategyPerformance {
    int     totalTrades;            // Tổng số lệnh
    int     winTrades;              // Số lệnh thắng
    int     lossTrades;             // Số lệnh thua
    double  grossProfit;            // Tổng lợi nhuận các lệnh thắng
    double  grossLoss;              // Tổng lỗ các lệnh thua
    double  netProfit;              // Lợi nhuận ròng
    double  profitFactor;           // Hệ số lợi nhuận
    double  winRate;                // Tỷ lệ thắng
    double  expectancy;             // Kỳ vọng toán học
    double  averageWin;             // Lợi nhuận trung bình mỗi lệnh thắng
    double  averageLoss;            // Lỗ trung bình mỗi lệnh thua
    int     consecutiveWins;        // Số lần thắng liên tiếp hiện tại
    int     consecutiveLosses;      // Số lần thua liên tiếp hiện tại
    int     maxConsecutiveWins;     // Số lần thắng liên tiếp lớn nhất
    int     maxConsecutiveLosses;   // Số lần thua liên tiếp lớn nhất
    
    // Thông tin theo từng Cluster
    double  clusterWinRate[5];      // Tỷ lệ thắng theo từng cluster
    int     clusterTrades[5];       // Số lệnh theo từng cluster
    double  clusterProfit[5];       // Lợi nhuận theo từng cluster
    
    // Thông tin theo phiên
    double  sessionWinRate[5];      // Tỷ lệ thắng theo từng phiên
    int     sessionTrades[5];       // Số lệnh theo từng phiên
    double  sessionProfit[5];       // Lợi nhuận theo từng phiên
    
    // Thông tin theo khung thời gian
    double  timeframeWinRate[8];    // Tỷ lệ thắng theo từng timeframe
    
    // Khởi tạo giá trị mặc định
    StrategyPerformance() {
        totalTrades = 0;
        winTrades = 0;
        lossTrades = 0;
        grossProfit = 0;
        grossLoss = 0;
        netProfit = 0;
        profitFactor = 0;
        winRate = 0;
        expectancy = 0;
        averageWin = 0;
        averageLoss = 0;
        consecutiveWins = 0;
        consecutiveLosses = 0;
        maxConsecutiveWins = 0;
        maxConsecutiveLosses = 0;
        
        ArrayInitialize(clusterWinRate, 0);
        ArrayInitialize(clusterTrades, 0);
        ArrayInitialize(clusterProfit, 0);
        ArrayInitialize(sessionWinRate, 0);
        ArrayInitialize(sessionTrades, 0);
        ArrayInitialize(sessionProfit, 0);
        ArrayInitialize(timeframeWinRate, 0);
    }
};

// --- CẤU TRÚC CẢNH BÁO NÂNG CAO ---
struct AlertInfo {
    bool     active;                // Trạng thái cảnh báo
    datetime alertTime;             // Thời gian cảnh báo
    string   message;               // Nội dung cảnh báo
    int      severity;              // Mức độ nghiêm trọng (1-5)
    bool     notified;              // Đã thông báo chưa
    
    AlertInfo() {
        active = false;
        alertTime = 0;
        message = "";
        severity = 1;
        notified = false;
    }
};

// --- CẤU TRÚC ĐA TAKE PROFIT ---
struct MultiTakeProfitLevel {
    double price;                  // Giá take profit
    double volumePercent;          // Phần trăm khối lượng đóng
    bool   triggered;              // Đã kích hoạt chưa
    double rMultiple;              // Tương ứng với bao nhiêu R
    
    MultiTakeProfitLevel() {
        price = 0;
        volumePercent = 0;
        triggered = false;
        rMultiple = 0;
    }
};

// --- ENUM CÁC LOẠI LỖI GIAO DỊCH ---
enum ENUM_TRADE_ERROR_HANDLING {
    ERROR_HANDLING_NONE,           // Không xử lý đặc biệt
    ERROR_HANDLING_RETRY,          // Thử lại đặt lệnh
    ERROR_HANDLING_MODIFY,         // Điều chỉnh tham số và thử lại
    ERROR_HANDLING_ABORT           // Hủy bỏ đặt lệnh
};

// --- ENUM TRẠNG THÁI CỦA QUẢN LÝ RỦI RO ---
enum ENUM_RISK_STATE {
    RISK_STATE_NORMAL,             // Rủi ro bình thường
    RISK_STATE_CAUTION,            // Cảnh báo - cần chú ý
    RISK_STATE_WARNING,            // Cảnh báo - đang tiếp cận giới hạn
    RISK_STATE_CRITICAL,           // Nguy hiểm - gần đạt giới hạn
    RISK_STATE_EMERGENCY,          // Khẩn cấp - đã đạt/vượt giới hạn
    RISK_STATE_SHUTDOWN            // Đóng toàn bộ hoạt động
};

//+------------------------------------------------------------------+
//| CTradeManager - Quản lý giao dịch và vòng đời lệnh              |
//+------------------------------------------------------------------+
class CTradeManager {
private:
    // Các đối tượng chính
    CTrade           m_trade;           // Đối tượng giao dịch chuẩn
    CLogger         *m_logger;          // Logger để ghi log
    CRiskOptimizer  *m_riskOptimizer;   // Tối ưu hóa rủi ro
    CRiskManager    *m_riskManager;     // Quản lý rủi ro
    
    // Tham số cơ bản
    string           m_Symbol;          // Symbol hiện tại
    int              m_MagicNumber;     // Mã số nhận diện EA
    int              m_Digits;          // Số chữ số thập phân của symbol
    double           m_Point;           // Giá trị 1 point của symbol
    
    // Tham số cho break-even và trailing
    double           m_BreakEven_R;     // Điểm R-multiple để đặt break-even
    bool             m_UseAdaptiveTrailing; // Sử dụng trailing thích ứng
    ENUM_TRAILING_MODE m_TrailingMode;  // Chế độ trailing
    double           m_TrailingATRMultiplier; // Hệ số ATR cho trailing
    
    // Tham số cho đóng lệnh một phần
    double           m_PartialCloseR1;  // R-multiple cho đóng một phần 1
    double           m_PartialCloseR2;  // R-multiple cho đóng một phần 2
    double           m_PartialClosePercent1; // % đóng ở mục tiêu 1
    double           m_PartialClosePercent2; // % đóng ở mục tiêu 2
    
    // Tham số cho scaling
    int              m_ScalingCount;    // Số lần scaling đã thực hiện
    int              m_MaxScalingCount; // Số lần scaling tối đa
    
    // Cấu hình Chandelier Exit
    bool             m_UseChandelierExit;    // Kích hoạt Chandelier Exit
    int              m_ChandelierLookback;   // Số nến lookback Chandelier
    double           m_ChandelierATRMultiplier; // Hệ số ATR Chandelier
    
    // Cờ bật/tắt các tính năng
    bool             m_EnableDetailedLogs;   // Bật log chi tiết
    
    // Dữ liệu cache
    PositionInfo     m_CurrentPosition;      // Thông tin vị thế hiện tại
    SwingPoint       m_RecentSwings[20];     // Cache các đỉnh/đáy gần đây
    double           m_AverageATR;           // ATR trung bình
    datetime         m_LastATRUpdateTime;    // Thời gian cập nhật ATR cuối
    
    // Indicator handles
    int              m_handleATR;       // Handle indicator ATR
    int              m_handleEMA;       // Handle indicator EMA
    int              m_handlePSAR;      // Handle indicator Parabolic SAR
    int              m_handleADX;       // Handle indicator ADX
    int              m_handleRSI;       // Handle indicator RSI
    
    // --- BIẾN MỚI CHO CÁC TÍNH NĂNG NÂNG CAO ---
    
    // Các tham số xử lý lỗi đặt lệnh
    int              m_MaxRetryAttempts;     // Số lần thử lại tối đa
    int              m_RetryDelayMs;         // Độ trễ giữa các lần thử (ms)
    bool             m_EnableErrorHandling;  // Bật xử lý lỗi
    
    // Các tham số quản lý rủi ro nâng cao
    double           m_MaxDailyLossPercent;  // % lỗ tối đa trong ngày
    double           m_MaxWeeklyLossPercent; // % lỗ tối đa trong tuần
    double           m_MaxMonthlyLossPercent;// % lỗ tối đa trong tháng
    double           m_MaxDrawdownPercent;   // % DD tối đa
    double           m_DailyProfitTarget;    // Mục tiêu lợi nhuận ngày
    double           m_WeeklyProfitTarget;   // Mục tiêu lợi nhuận tuần
    double           m_MonthlyProfitTarget;  // Mục tiêu lợi nhuận tháng
    
    // Trạng thái giới hạn rủi ro hiện tại
    ENUM_RISK_STATE  m_CurrentRiskState;     // Trạng thái rủi ro hiện tại
    
    // Adaptive trailing và chốt lời đa tầng
    MultiTakeProfitLevel m_TakeProfitLevels[5]; // Tối đa 5 mức chốt lời
    int              m_TakeProfitLevelCount;    // Số mức chốt lời đang sử dụng
    
    // Thông tin hiệu suất
    StrategyPerformance m_Performance;    // Thông tin hiệu suất
    
    // Cảnh báo và thông báo
    AlertInfo       m_CurrentAlert;       // Cảnh báo hiện tại
    
    // Theo dõi thời gian 
    datetime        m_CurrentDay;         // Ngày hiện tại
    datetime        m_CurrentWeek;        // Tuần hiện tại
    datetime        m_CurrentMonth;       // Tháng hiện tại
    double          m_DayStartBalance;    // Số dư đầu ngày
    double          m_WeekStartBalance;   // Số dư đầu tuần
    double          m_MonthStartBalance;  // Số dư đầu tháng
    
    // --- CÁC HÀM XỬ LÝ MỚI ---
    
    // Hàm xử lý lỗi đặt lệnh
    ENUM_TRADE_ERROR_HANDLING ClassifyTradeError(int errorCode);
    bool RetryOrderRequest(const MqlTradeRequest &request, MqlTradeResult &result, int maxAttempts = 3);
    double RecalculatePrice(ENUM_ORDER_TYPE orderType, double originalPrice, int requoteAttempt);
    bool ModifyOrderParametersForRetry(ENUM_ORDER_TYPE orderType, double &price, double &sl, double &tp);
    
    // Hàm quản lý rủi ro nâng cao
    ENUM_RISK_STATE CheckAccountRiskState();
    void UpdateTimeBasedStats();
    double CalculateDailyPnL();
    double CalculateWeeklyPnL();
    double CalculateMonthlyPnL();
    void TakeActionBasedOnRiskState(ENUM_RISK_STATE state);
    
    // Hàm quản lý đa mức Take Profit
    bool SetupMultipleTargets(ulong ticket, double entryPrice, double stopLoss, bool isLong);
    bool ManageMultipleTargets(ulong ticket);
    double CalculateOptimalTakeProfitRatio(double riskPoints, ENUM_MARKET_REGIME regime);
    
    // Hàm nâng cao cho mã hóa MagicNumber 
    int EncodeMagicNumber(int baseNumber, ENUM_TIMEFRAMES timeframe, ENUM_ENTRY_SCENARIO scenario);
    void DecodeMagicNumber(int magic, int &baseNumber, ENUM_TIMEFRAMES &timeframe, ENUM_ENTRY_SCENARIO &scenario);
    string GenerateDetailedComment(bool isLong, ENUM_ENTRY_SCENARIO scenario, string additionalInfo = "");
    
    // Hàm thống kê hiệu suất
    void UpdatePerformanceStats(bool isWin, double profit, ENUM_ENTRY_SCENARIO scenario, ENUM_SESSION session);
    void LogPerformanceStats();
    void SavePerformanceToFile(string filename = "performance_stats.csv");
    
    // Các hàm tiện ích
    double GetValidATR();
    datetime GetStartOfDay(datetime time);
    datetime GetStartOfWeek(datetime time);
    datetime GetStartOfMonth(datetime time);
    
    // Hàm xử lý thời gian thực
    bool IsHighVolatilityTime();
    bool IsNewsTime();
    bool IsThinMarketCondition();
    
    // Hàm nội bộ để quản lý giao dịch
    double GetCurrentRR(ulong ticket);
    double CalculateTrailingStopATR(double currentPrice, bool isLong, double atr);
    double CalculateTrailingStopEMA(bool isLong);
    double CalculateTrailingStopPSAR(bool isLong);
    double CalculateTrailingStopMAX(double currentPrice, bool isLong);
    bool SafeModifyStopLoss(ulong ticket, double newSL);
    bool SafeClosePartial(ulong ticket, double partialLots, string partialComment);
    void UpdatePositionMetadata(ulong ticket);
    
    // Hàm Chandelier Exit nâng cao
    double CalculateChandelierExit(bool isLong, double openPrice, double currentPrice);
    double DynamicChandelierExit(bool isLong, double openPrice, double currentPrice, ENUM_MARKET_REGIME regime);
    
    // Các hàm hỗ trợ quản lý lệnh mới
    void MoveAllStopsToBreakEven();
    void CloseAllPositions(string reason = "Emergency Exit");
    bool DetectVolumeDump();
    bool DetectEMASlopeChange(bool isLong);
    void HandleTrendingTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    void HandleSidewayTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    void HandleVolatileTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    ENUM_SESSION DetermineCurrentSession();
    double AdjustTrailingStopBySession(double baseTrailingStop, ENUM_SESSION session, bool isLong);
    bool CheckAndExecuteScaling(const MarketProfile &profile);
    
public:
    CTradeManager();
    ~CTradeManager();
    
    // Khởi tạo và thiết lập
    bool Initialize(string symbol, int magic, CLogger* logger, CRiskOptimizer* riskOpt, 
                   CRiskManager* riskMgr, double breakEvenR, bool useAdaptiveTrail, 
                   ENUM_TRAILING_MODE trailingMode);
    
    // --- PHƯƠNG THỨC THIẾT LẬP MỚI ---
    
    // Thiết lập xử lý lỗi
    void SetErrorHandlingParams(bool enable, int maxRetries = 3, int delayMs = 500) {
        m_EnableErrorHandling = enable;
        m_MaxRetryAttempts = maxRetries;
        m_RetryDelayMs = delayMs;
    }
    
    // Thiết lập quản lý rủi ro nâng cao
    void SetAdvancedRiskParams(double maxDailyLoss, double maxWeeklyLoss, double maxMonthlyLoss, double maxDD) {
        m_MaxDailyLossPercent = maxDailyLoss;
        m_MaxWeeklyLossPercent = maxWeeklyLoss;
        m_MaxMonthlyLossPercent = maxMonthlyLoss;
        m_MaxDrawdownPercent = maxDD;
    }
    
    // Thiết lập mục tiêu lợi nhuận
    void SetProfitTargets(double dailyTarget, double weeklyTarget, double monthlyTarget) {
        m_DailyProfitTarget = dailyTarget;
        m_WeeklyProfitTarget = weeklyTarget;
        m_MonthlyProfitTarget = monthlyTarget;
    }
    
    // Thiết lập đa tầng take profit
    void ConfigureMultipleTargets(double[] tpRatios, double[] volumePercents, int count) {
        m_TakeProfitLevelCount = MathMin(count, 5);
        for (int i = 0; i < m_TakeProfitLevelCount; i++) {
            m_TakeProfitLevels[i].rMultiple = tpRatios[i];
            m_TakeProfitLevels[i].volumePercent = volumePercents[i];
            m_TakeProfitLevels[i].triggered = false;
        }
    }
    
    // --- CÁC PHƯƠNG THỨC CƠ BẢN ---
    
    // Cài đặt tham số
    void SetTrailingATRMultiplier(double multiplier) { m_TrailingATRMultiplier = multiplier; }
    void SetMaxScalingCount(int count) { m_MaxScalingCount = count; }
    void SetPartialCloseParams(double r1, double r2, double percent1, double percent2);
    void EnableChandelierExit(bool enable, int lookback, double multiplier);
    void SetAverageATR(double averageATR) { m_AverageATR = averageATR; }
    
    // Thực thi lệnh nâng cao với xử lý lỗi
    ulong ExecuteBuyOrder(double lotSize, double stopLoss, double takeProfit, 
                         ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    ulong ExecuteSellOrder(double lotSize, double stopLoss, double takeProfit, 
                          ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    ulong PlaceBuyLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                       ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    ulong PlaceBuyStop(double lotSize, double stopPrice, double stopLoss, double takeProfit, 
                      ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    ulong PlaceSellLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                        ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    ulong PlaceSellStop(double lotSize, double stopPrice, double stopLoss, double takeProfit, 
                       ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE);
    
    // Quản lý lệnh
    void ManageOpenPositions(const MarketProfile &profile);
    void ManageTrailingStop(ulong ticket, ENUM_MARKET_REGIME regime);
    void ManagePartialClose(ulong ticket, double currentRR);
    
    // Hàm xử lý sự kiện
    void ProcessTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result);
    
    // Hàm kiểm tra thông tin
    int GetMagicNumber() const { return m_MagicNumber; }
    bool HasOpenPosition(string symbol = "");
    
    // Xử lý tín hiệu
    bool FeedbackSignalResult(const SignalInfo &signal, bool isSuccess, ulong ticket, string rejectionReason = "");
    bool ShouldEmergencyExit(ulong ticket, const MarketProfile &profile);
    
    // Quản lý lệnh mở rộng
    void UpdateTrailingStops();
    void CloseAllPendingOrders();
    
    // --- PHƯƠNG THỨC QUẢN LÝ QUỸ MỚI --- 
    
    // Trạng thái tài khoản hiện tại
    ENUM_RISK_STATE GetCurrentRiskState() { return m_CurrentRiskState; }
    string GetRiskStateDescription();
    double GetCurrentDrawdown();
    
    // Kiểm tra giới hạn
    bool IsDailyLossLimitReached() { return CalculateDailyPnL() <= -m_MaxDailyLossPercent; }
    bool IsWeeklyLossLimitReached() { return CalculateWeeklyPnL() <= -m_MaxWeeklyLossPercent; }
    bool IsMonthlyLossLimitReached() { return CalculateMonthlyPnL() <= -m_MaxMonthlyLossPercent; }
    bool IsDailyProfitTargetReached() { return CalculateDailyPnL() >= m_DailyProfitTarget; }
    
    // Thông kê hiệu suất
    StrategyPerformance* GetPerformanceStats() { return &m_Performance; }
    void ResetPerformanceStats(bool resetDaily = true, bool resetWeekly = false, bool resetMonthly = false);
    
    // Cảnh báo và thông báo
    void SetAlert(string message, int severity);
    void ClearAlert();
    bool HasActiveAlert() { return m_CurrentAlert.active; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
    m_MagicNumber = 0;
    m_Symbol = "";
    m_logger = NULL;
    m_riskOptimizer = NULL;
    m_riskManager = NULL;
    m_BreakEven_R = 1.0;
    m_UseAdaptiveTrailing = true;
    m_TrailingMode = TRAILING_ATR;
    m_TrailingATRMultiplier = 2.0;
    m_ScalingCount = 0;
    m_MaxScalingCount = 2;
    m_PartialCloseR1 = 1.5;
    m_PartialCloseR2 = 2.5;
    m_PartialClosePercent1 = 0.3;
    m_PartialClosePercent2 = 0.5;
    m_EnableDetailedLogs = false;
    m_Digits = 5;
    m_Point = 0.00001;
    
    m_AverageATR = 0;
    m_LastATRUpdateTime = 0;
    
    // Khởi tạo các cài đặt Chandelier Exit
    m_UseChandelierExit = false;
    m_ChandelierLookback = 20;
    m_ChandelierATRMultiplier = 3.0;
    
    // Khởi tạo handles
    m_handleATR = INVALID_HANDLE;
    m_handleEMA = INVALID_HANDLE;
    m_handlePSAR = INVALID_HANDLE;
    m_handleADX = INVALID_HANDLE;
    m_handleRSI = INVALID_HANDLE;
    
    // Khởi tạo các tham số xử lý lỗi mới
    m_MaxRetryAttempts = 3;
    m_RetryDelayMs = 500;
    m_EnableErrorHandling = true;
    
    // Khởi tạo các tham số quản lý rủi ro nâng cao
    m_MaxDailyLossPercent = 2.0;      // Mặc định: 2% lỗ tối đa/ngày
    m_MaxWeeklyLossPercent = 5.0;     // Mặc định: 5% lỗ tối đa/tuần
    m_MaxMonthlyLossPercent = 10.0;   // Mặc định: 10% lỗ tối đa/tháng
    m_MaxDrawdownPercent = 20.0;      // Mặc định: 20% drawdown tối đa
    m_DailyProfitTarget = 3.0;        // Mặc định: 3% lợi nhuận mục tiêu/ngày
    m_WeeklyProfitTarget = 10.0;      // Mặc định: 10% lợi nhuận mục tiêu/tuần
    m_MonthlyProfitTarget = 25.0;     // Mặc định: 25% lợi nhuận mục tiêu/tháng
    
    // Khởi tạo trạng thái rủi ro
    m_CurrentRiskState = RISK_STATE_NORMAL;
    
    // Khởi tạo thông tin Take Profit đa tầng
    m_TakeProfitLevelCount = 3;        // Mặc định: 3 mức TP
    
    // TP1 - 50% khối lượng tại 1.5R
    m_TakeProfitLevels[0].rMultiple = 1.5;
    m_TakeProfitLevels[0].volumePercent = 50;
    m_TakeProfitLevels[0].triggered = false;
    
    // TP2 - 30% khối lượng tại 2.5R
    m_TakeProfitLevels[1].rMultiple = 2.5;
    m_TakeProfitLevels[1].volumePercent = 30;
    m_TakeProfitLevels[1].triggered = false;
    
    // TP3 - 20% khối lượng tại 4R
    m_TakeProfitLevels[2].rMultiple = 4.0;
    m_TakeProfitLevels[2].volumePercent = 20;
    m_TakeProfitLevels[2].triggered = false;
    
    // Khởi tạo dữ liệu theo dõi thời gian
    m_CurrentDay = 0;
    m_CurrentWeek = 0;
    m_CurrentMonth = 0;
    m_DayStartBalance = 0;
    m_WeekStartBalance = 0;
    m_MonthStartBalance = 0;
    
    // Khởi tạo cảnh báo
    m_CurrentAlert.active = false;
    
    ZeroMemory(m_CurrentPosition);
    ArrayInitialize(m_RecentSwings, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
    // Giải phóng tài nguyên indicator
    if (m_handleATR != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR);
        m_handleATR = INVALID_HANDLE;
    }
    
    if (m_handleEMA != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA);
        m_handleEMA = INVALID_HANDLE;
    }
    
    if (m_handlePSAR != INVALID_HANDLE) {
        IndicatorRelease(m_handlePSAR);
        m_handlePSAR = INVALID_HANDLE;
    }
    
    if (m_handleADX != INVALID_HANDLE) {
        IndicatorRelease(m_handleADX);
        m_handleADX = INVALID_HANDLE;
    }
    
    if (m_handleRSI != INVALID_HANDLE) {
        IndicatorRelease(m_handleRSI);
        m_handleRSI = INVALID_HANDLE;
    }
    
    // Lưu thông kê hiệu suất trước khi đóng
    if (m_Performance.totalTrades > 0) {
        SavePerformanceToFile();
    }
    
    // Reset con trỏ từ bên ngoài
    m_logger = NULL;
    m_riskOptimizer = NULL;
    m_riskManager = NULL;
}

//+------------------------------------------------------------------+
//| Initialize TradeManager                                          |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(string symbol, int magic, CLogger* logger, CRiskOptimizer* riskOpt, 
                             CRiskManager* riskMgr, double breakEvenR, bool useAdaptiveTrail, 
                             ENUM_TRAILING_MODE trailingMode)
{
    if(symbol == "" || magic <= 0) {
        if(logger) logger.LogError("TradeManager::Initialize - Tham số không hợp lệ");
        return false;
    }
    
    m_Symbol = symbol;
    m_MagicNumber = magic;
    m_logger = logger;
    m_riskOptimizer = riskOpt;
    m_riskManager = riskMgr;
    m_BreakEven_R = MathMax(0.1, breakEvenR);
    m_UseAdaptiveTrailing = useAdaptiveTrail;
    m_TrailingMode = trailingMode;
    m_Digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    m_Point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    m_trade.SetExpertMagicNumber(magic);
    m_trade.SetMarginMode();
    m_trade.SetTypeFillingBySymbol(m_Symbol);
    m_trade.SetDeviationInPoints(10);
    
    // Khởi tạo handle indicators
    m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
    if(m_handleATR == INVALID_HANDLE) {
        if(m_logger) m_logger.LogError("TradeManager - Không thể tạo ATR handle");
        return false;
    }
    
    m_handleADX = iADX(m_Symbol, PERIOD_CURRENT, 14);
    if(m_handleADX == INVALID_HANDLE) {
        if(m_logger) m_logger.LogError("TradeManager - Không thể tạo ADX handle");
        return false;
    }
    
    m_handleRSI = iRSI(m_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    if(m_handleRSI == INVALID_HANDLE) {
        if(m_logger) m_logger.LogError("TradeManager - Không thể tạo RSI handle");
        return false;
    }
    
    if (m_TrailingMode == TRAILING_MODE_EMA) {
        m_handleEMA = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
        if(m_handleEMA == INVALID_HANDLE) {
            if(m_logger) m_logger.LogError("TradeManager - Không thể tạo EMA handle");
            return false;
        }
    }
    
    if (m_TrailingMode == TRAILING_MODE_PSAR) {
        m_handlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2);
        if(m_handlePSAR == INVALID_HANDLE) {
            if(m_logger) m_logger.LogError("TradeManager - Không thể tạo PSAR handle");
            return false;
        }
    }
    
    // Cập nhật trạng thái theo thời gian và khởi tạo giá trị ban đầu
    m_ScalingCount = 0;
    UpdateTimeBasedStats();
    UpdateAverageATR();
    
    if (m_logger) {
        m_logger.LogInfo("TradeManager khởi tạo thành công cho " + symbol + " với magic " + IntegerToString(magic));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdateTimeBasedStats - Cập nhật chỉ số theo thời gian           |
//+------------------------------------------------------------------+
void CTradeManager::UpdateTimeBasedStats()
{
    datetime current = TimeCurrent();
    datetime currentDayStart = GetStartOfDay(current);
    datetime currentWeekStart = GetStartOfWeek(current);
    datetime currentMonthStart = GetStartOfMonth(current);
    
    // Kiểm tra và cập nhật ngày
    if (m_CurrentDay != currentDayStart) {
        // Nếu đã từng có ngày trước đó, ghi log
        if (m_CurrentDay != 0 && m_logger) {
            double dailyPnL = (AccountInfoDouble(ACCOUNT_BALANCE) - m_DayStartBalance) * 100.0 / m_DayStartBalance;
            m_logger.LogInfo(StringFormat("Kết thúc ngày giao dịch (PnL: %.2f%%)", dailyPnL));
        }
        
        // Cập nhật ngày mới
        m_CurrentDay = currentDayStart;
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        if (m_logger) {
            m_logger.LogInfo("Bắt đầu ngày giao dịch mới: " + TimeToString(m_CurrentDay, TIME_DATE));
        }
    }
    
    // Kiểm tra và cập nhật tuần
    if (m_CurrentWeek != currentWeekStart) {
        // Nếu đã từng có tuần trước đó, ghi log
        if (m_CurrentWeek != 0 && m_logger) {
            double weeklyPnL = (AccountInfoDouble(ACCOUNT_BALANCE) - m_WeekStartBalance) * 100.0 / m_WeekStartBalance;
            m_logger.LogInfo(StringFormat("Kết thúc tuần giao dịch (PnL: %.2f%%)", weeklyPnL));
        }
        
        // Cập nhật tuần mới
        m_CurrentWeek = currentWeekStart;
        m_WeekStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        if (m_logger) {
            m_logger.LogInfo("Bắt đầu tuần giao dịch mới: " + TimeToString(m_CurrentWeek, TIME_DATE));
        }
    }
    
    // Kiểm tra và cập nhật tháng
    if (m_CurrentMonth != currentMonthStart) {
        // Nếu đã từng có tháng trước đó, ghi log
        if (m_CurrentMonth != 0 && m_logger) {
            double monthlyPnL = (AccountInfoDouble(ACCOUNT_BALANCE) - m_MonthStartBalance) * 100.0 / m_MonthStartBalance;
            m_logger.LogInfo(StringFormat("Kết thúc tháng giao dịch (PnL: %.2f%%)", monthlyPnL));
            
            // Ghi thống kê hiệu suất cuối tháng
            LogPerformanceStats();
        }
        
        // Cập nhật tháng mới
        m_CurrentMonth = currentMonthStart;
        m_MonthStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        if (m_logger) {
            m_logger.LogInfo("Bắt đầu tháng giao dịch mới: " + TimeToString(m_CurrentMonth, TIME_DATE));
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateDailyPnL - Tính lợi nhuận theo phần trăm trong ngày    |
//+------------------------------------------------------------------+
double CTradeManager::CalculateDailyPnL()
{
    if (m_DayStartBalance <= 0) return 0;
    
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Tỷ lệ phần trăm thay đổi
    double pnlPercent = (currentEquity - m_DayStartBalance) * 100.0 / m_DayStartBalance;
    
    return pnlPercent;
}

//+------------------------------------------------------------------+
//| CalculateWeeklyPnL - Tính lợi nhuận theo phần trăm trong tuần   |
//+------------------------------------------------------------------+
double CTradeManager::CalculateWeeklyPnL()
{
    if (m_WeekStartBalance <= 0) return 0;
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Tỷ lệ phần trăm thay đổi
    double pnlPercent = (currentEquity - m_WeekStartBalance) * 100.0 / m_WeekStartBalance;
    
    return pnlPercent;
}

//+------------------------------------------------------------------+
//| CalculateMonthlyPnL - Tính lợi nhuận theo phần trăm trong tháng |
//+------------------------------------------------------------------+
double CTradeManager::CalculateMonthlyPnL()
{
    if (m_MonthStartBalance <= 0) return 0;
    
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Tỷ lệ phần trăm thay đổi
    double pnlPercent = (currentEquity - m_MonthStartBalance) * 100.0 / m_MonthStartBalance;
    
    return pnlPercent;
}

//+------------------------------------------------------------------+
//| CheckAccountRiskState - Kiểm tra trạng thái rủi ro của tài khoản|
//+------------------------------------------------------------------+
ENUM_RISK_STATE CTradeManager::CheckAccountRiskState()
{
    // Cập nhật dữ liệu theo thời gian nếu cần
    UpdateTimeBasedStats();
    
    // Tính các chỉ số hiện tại
    double dailyPnL = CalculateDailyPnL();
    double weeklyPnL = CalculateWeeklyPnL();
    double monthlyPnL = CalculateMonthlyPnL();
    double currentDrawdown = GetCurrentDrawdown();
    
    // Kiểm tra các điều kiện khẩn cấp - cần dừng mọi hoạt động
    if (dailyPnL <= -m_MaxDailyLossPercent) {
        return RISK_STATE_EMERGENCY;
    }
    
    if (weeklyPnL <= -m_MaxWeeklyLossPercent) {
        return RISK_STATE_EMERGENCY;
    }
    
    if (monthlyPnL <= -m_MaxMonthlyLossPercent) {
        return RISK_STATE_EMERGENCY;
    }
    
    if (currentDrawdown >= m_MaxDrawdownPercent) {
        return RISK_STATE_EMERGENCY;
    }
    
    // Kiểm tra các cảnh báo nghiêm trọng
    if (dailyPnL <= -m_MaxDailyLossPercent * 0.9 || 
        weeklyPnL <= -m_MaxWeeklyLossPercent * 0.9 ||
        monthlyPnL <= -m_MaxMonthlyLossPercent * 0.9 ||
        currentDrawdown >= m_MaxDrawdownPercent * 0.9) {
        return RISK_STATE_CRITICAL;
    }
    
    // Kiểm tra các cảnh báo
    if (dailyPnL <= -m_MaxDailyLossPercent * 0.75 || 
        weeklyPnL <= -m_MaxWeeklyLossPercent * 0.75 ||
        monthlyPnL <= -m_MaxMonthlyLossPercent * 0.75 ||
        currentDrawdown >= m_MaxDrawdownPercent * 0.75) {
        return RISK_STATE_WARNING;
    }
    
    // Kiểm tra cảnh báo chú ý
    if (dailyPnL <= -m_MaxDailyLossPercent * 0.5 || 
        weeklyPnL <= -m_MaxWeeklyLossPercent * 0.5 ||
        monthlyPnL <= -m_MaxMonthlyLossPercent * 0.5 ||
        currentDrawdown >= m_MaxDrawdownPercent * 0.5) {
        return RISK_STATE_CAUTION;
    }
    
    // Kiểm tra đạt mục tiêu lợi nhuận
    if (dailyPnL >= m_DailyProfitTarget ||
        weeklyPnL >= m_WeeklyProfitTarget ||
        monthlyPnL >= m_MonthlyProfitTarget) {
        // Vẫn xem như bình thường, nhưng có thể log để thông báo
        if (m_logger && m_EnableDetailedLogs) {
            m_logger.LogInfo(StringFormat("Đã đạt mục tiêu lợi nhuận (Ngày: %.2f%%, Tuần: %.2f%%, Tháng: %.2f%%)",
                                       dailyPnL, weeklyPnL, monthlyPnL));
        }
    }
    
    // Trạng thái bình thường
    return RISK_STATE_NORMAL;
}

//+------------------------------------------------------------------+
//| TakeActionBasedOnRiskState - Thực hiện hành động dựa trên trạng  |
//| thái rủi ro                                                      |
//+------------------------------------------------------------------+
void CTradeManager::TakeActionBasedOnRiskState(ENUM_RISK_STATE state)
{
    // Lưu trạng thái hiện tại
    m_CurrentRiskState = state;
    
    // Thực hiện hành động dựa trên trạng thái
    switch (state) {
        case RISK_STATE_EMERGENCY:
            // Đóng tất cả lệnh và dừng giao dịch
            if (m_logger) {
                m_logger.LogError("TRẠNG THÁI KHẨN CẤP! Đóng tất cả lệnh và dừng giao dịch");
            }
            
            CloseAllPositions("Risk limit reached - Emergency shutdown");
            CloseAllPendingOrders();
            
            // Tạo cảnh báo
            SetAlert("TRẠNG THÁI KHẨN CẤP - Đã vượt quá giới hạn rủi ro.", 5);
            break;
            
        case RISK_STATE_CRITICAL:
            // Giảm kích thước lệnh và đặt các lệnh đang mở về breakeven
            if (m_logger) {
                m_logger.LogWarning("TRẠNG THÁI NGUY HIỂM! Giảm kích thước lệnh và bảo vệ các lệnh đang mở");
            }
            
            MoveAllStopsToBreakEven();
            
            // Tạo cảnh báo
            SetAlert("TRẠNG THÁI NGUY HIỂM - Đang tiếp cận giới hạn rủi ro.", 4);
            break;
            
        case RISK_STATE_WARNING:
            // Giảm kích thước lệnh, thận trọng hơn với entry mới
            if (m_logger) {
                m_logger.LogWarning("TRẠNG THÁI CẢNH BÁO! Giảm kích thước lệnh, thận trọng với entry mới");
            }
            
            // Tạo cảnh báo
            SetAlert("TRẠNG THÁI CẢNH BÁO - Lỗ đang tiếp cận giới hạn cho phép.", 3);
            break;
            
        case RISK_STATE_CAUTION:
            // Thận trọng, giảm nhẹ kích thước lệnh
            if (m_logger && m_EnableDetailedLogs) {
                m_logger.LogInfo("TRẠNG THÁI CHÚ Ý! Thận trọng, giảm nhẹ kích thước lệnh");
            }
            
            break;
            
        case RISK_STATE_NORMAL:
            // Trạng thái bình thường, không cần hành động đặc biệt
            // Xóa cảnh báo nếu có
            ClearAlert();
            break;
            
        default:
            break;
    }
}

//+------------------------------------------------------------------+
//| GetCurrentDrawdown - Lấy drawdown hiện tại theo phần trăm       |
//+------------------------------------------------------------------+
double CTradeManager::GetCurrentDrawdown()
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double peakBalance = m_MonthStartBalance; // Sử dụng balance đầu tháng làm tham chiếu
    
    // Điều chỉnh peakBalance nếu balance hiện tại cao hơn
    if (balance > peakBalance) {
        peakBalance = balance;
    }
    
    // Tính drawdown theo phần trăm
    double drawdownPercent = 0;
    if (peakBalance > 0) {
        drawdownPercent = (peakBalance - equity) * 100.0 / peakBalance;
    }
    
    return drawdownPercent;
}

//+------------------------------------------------------------------+
//| GetRiskStateDescription - Lấy mô tả trạng thái rủi ro           |
//+------------------------------------------------------------------+
string CTradeManager::GetRiskStateDescription()
{
    string description = "";
    
    switch (m_CurrentRiskState) {
        case RISK_STATE_NORMAL:
            description = "BÌNH THƯỜNG - Giao dịch bình thường, không có cảnh báo.";
            break;
            
        case RISK_STATE_CAUTION:
            description = "CHÚ Ý - Hãy thận trọng, lỗ đang tăng.";
            break;
            
        case RISK_STATE_WARNING:
            description = "CẢNH BÁO - Lỗ đáng kể, cần thận trọng.";
            break;
            
        case RISK_STATE_CRITICAL:
            description = "NGUY HIỂM - Đang tiếp cận giới hạn rủi ro.";
            break;
            
        case RISK_STATE_EMERGENCY:
            description = "KHẨN CẤP - Đã vượt quá giới hạn rủi ro.";
            break;
            
        case RISK_STATE_SHUTDOWN:
            description = "ĐÓNG CỬA - Hệ thống đã dừng giao dịch.";
            break;
            
        default:
            description = "KHÔNG XÁC ĐỊNH";
            break;
    }
    
    return description;
}

//+------------------------------------------------------------------+
//| ENUM_TRADE_ERROR_HANDLING ClassifyTradeError - Phân loại lỗi    |
//| giao dịch và xác định cách xử lý                               |
//+------------------------------------------------------------------+
ENUM_TRADE_ERROR_HANDLING CTradeManager::ClassifyTradeError(int errorCode)
{
    // Các lỗi cần thử lại
    switch (errorCode) {
        // Lỗi kết nối/mạng
        case ERR_NO_CONNECTION:              // 2 - No connection
        case ERR_COMMON_ERROR:               // 2 - Common error
        case ERR_SOCKET_TIMEOUT:             // 144 - Timeout
        case ERR_ACCOUNT_DISABLED:           // 64 - Account disabled
            return ERROR_HANDLING_RETRY;
        
        // Lỗi server bận
        case ERR_SERVER_BUSY:                // 4 - Busu server
        case ERR_NO_RESULT:                  // 1 - No result
        case ERR_TOO_FREQUENT_REQUESTS:      // 8 - Too frequent requests
        case ERR_TRADE_CONTEXT_BUSY:         // 146 - Trade context busy
        case ERR_TRADE_TIMEOUT:              // 128 - Trade timeout
            return ERROR_HANDLING_RETRY;
        
        // Lỗi cần điều chỉnh tham số
        case ERR_INVALID_PRICE:              // 129 - Invalid price
        case ERR_PRICE_CHANGED:              // 135 - Price changed
        case ERR_OFF_QUOTES:                 // 136 - Off quotes
        case ERR_INVALID_STOPS:              // 130 - Invalid stops
        case ERR_REQUOTE:                    // 138 - Requote
            return ERROR_HANDLING_MODIFY;
        
        // Lỗi không thể khắc phục - cần hủy bỏ
        case ERR_NOT_ENOUGH_MONEY:           // 134 - Not enough money
        case ERR_MARKET_CLOSED:              // 132 - Market closed
        case ERR_TRADE_DISABLED:             // 133 - Trade disabled
        case ERR_TRADE_TOO_MANY_ORDERS:      // 148 - Too many orders
        case ERR_INVALID_TRADE_VOLUME:       // 131 - Invalid volume
        case ERR_INVALID_TRADE_PARAMETERS:   // 3 - Invalid parameters
            return ERROR_HANDLING_ABORT;
        
        // Mặc định - không xử lý đặc biệt
        default:
            return ERROR_HANDLING_NONE;
    }
}

//+------------------------------------------------------------------+
//| RetryOrderRequest - Thử lại yêu cầu đặt lệnh nhiều lần          |
//+------------------------------------------------------------------+
bool CTradeManager::RetryOrderRequest(const MqlTradeRequest &request, MqlTradeResult &result, int maxAttempts)
{
    if (!m_EnableErrorHandling) {
        // Nếu không bật xử lý lỗi, chỉ thực hiện một lần
        return OrderSend(request, result);
    }
    
    // Số lần thử tối đa
    int attemptsLeft = maxAttempts;
    bool success = false;
    
    // Vòng lặp thử đặt lệnh
    while (attemptsLeft > 0 && !success) {
        // Reset kết quả
        ZeroMemory(result);
        
        // Thử gửi lệnh
        if (OrderSend(request, result)) {
            success = true;
            break;
        }
        
        // Xử lý lỗi
        int errorCode = result.retcode;
        ENUM_TRADE_ERROR_HANDLING errorHandling = ClassifyTradeError(errorCode);
        
        if (m_logger && m_EnableDetailedLogs) {
            m_logger.LogWarning(StringFormat(
                "Lỗi đặt lệnh (%d): %s. Xử lý: %s. Còn lại %d lần thử.",
                errorCode, ErrorDescription(errorCode), 
                EnumToString(errorHandling), attemptsLeft - 1
            ));
        }
        
        // Xử lý theo loại lỗi
        switch (errorHandling) {
            case ERROR_HANDLING_RETRY:
                // Đợi một khoảng thời gian trước khi thử lại
                Sleep(m_RetryDelayMs);
                attemptsLeft--;
                break;
                
            case ERROR_HANDLING_MODIFY:
                // Cố gắng điều chỉnh tham số và thử lại
                MqlTradeRequest modifiedRequest = request;
                
                // Điều chỉnh giá nếu cần
                if (errorCode == ERR_INVALID_PRICE || errorCode == ERR_PRICE_CHANGED || 
                    errorCode == ERR_REQUOTE || errorCode == ERR_OFF_QUOTES) {
                    
                    // Cập nhật giá dựa trên loại lệnh
                    ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)request.type;
                    double newPrice = RecalculatePrice(orderType, request.price, maxAttempts - attemptsLeft + 1);
                    
                    if (newPrice > 0) {
                        modifiedRequest.price = newPrice;
                        
                        if (m_logger) {
                            m_logger.LogInfo(StringFormat(
                                "Điều chỉnh giá từ %.5f thành %.5f và thử lại.",
                                request.price, newPrice
                            ));
                        }
                    }
                }
                
                // Điều chỉnh SL/TP nếu cần
                if (errorCode == ERR_INVALID_STOPS) {
                    double newSL = request.sl;
                    double newTP = request.tp;
                    
                    if (ModifyOrderParametersForRetry((ENUM_ORDER_TYPE)request.type, modifiedRequest.price, newSL, newTP)) {
                        modifiedRequest.sl = newSL;
                        modifiedRequest.tp = newTP;
                        
                        if (m_logger) {
                            m_logger.LogInfo(StringFormat(
                                "Điều chỉnh SL/TP từ %.5f/%.5f thành %.5f/%.5f và thử lại.",
                                request.sl, request.tp, newSL, newTP
                            ));
                        }
                    }
                }
                
                // Thử lại với tham số mới
                if (OrderSend(modifiedRequest, result)) {
                    success = true;
                    break;
                }
                
                // Giảm số lần thử
                attemptsLeft--;
                break;
                
            case ERROR_HANDLING_ABORT:
            case ERROR_HANDLING_NONE:
            default:
                // Dừng thử và báo lỗi
                if (m_logger) {
                    m_logger.LogError(StringFormat(
                        "Lỗi đặt lệnh không thể khắc phục (%d): %s. Đã hủy đặt lệnh.",
                        errorCode, ErrorDescription(errorCode)
                    ));
                }
                return false;
        }
    }
    
    // Kiểm tra kết quả cuối cùng
    if (!success && m_logger) {
        m_logger.LogError(StringFormat(
            "Đã thử %d lần nhưng không thể đặt lệnh. Lỗi cuối: %d",
            maxAttempts, result.retcode
        ));
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| RecalculatePrice - Tính toán lại giá để thử lại đặt lệnh        |
//+------------------------------------------------------------------+
double CTradeManager::RecalculatePrice(ENUM_ORDER_TYPE orderType, double originalPrice, int requoteAttempt)
{
    // Cập nhật giá mới dựa trên loại lệnh
    double newPrice = 0;
    
    // Lấy giá thị trường hiện tại
    double currentAsk = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double currentBid = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    
    // Điều chỉnh theo số lần thử (càng thử nhiều lần, càng điều chỉnh nhiều)
    double adjustFactor = 1.0 + (0.01 * requoteAttempt); // Tăng 1% mỗi lần thử
    
    switch (orderType) {
        case ORDER_TYPE_BUY:
            newPrice = currentAsk; // Dùng giá Ask hiện tại
            break;
            
        case ORDER_TYPE_SELL:
            newPrice = currentBid; // Dùng giá Bid hiện tại
            break;
            
        case ORDER_TYPE_BUY_LIMIT:
            // Buy Limit: mua với giá thấp hơn thị trường
            // Khi requote, điều chỉnh giá thấp hơn một chút
            newPrice = MathMin(originalPrice, currentAsk * (1.0 - 0.001 * requoteAttempt));
            break;
            
        case ORDER_TYPE_SELL_LIMIT:
            // Sell Limit: bán với giá cao hơn thị trường
            // Khi requote, điều chỉnh giá cao hơn một chút
            newPrice = MathMax(originalPrice, currentBid * (1.0 + 0.001 * requoteAttempt));
            break;
            
        case ORDER_TYPE_BUY_STOP:
            // Buy Stop: mua với giá cao hơn thị trường
            // Khi requote, điều chỉnh giá cao hơn một chút
            newPrice = MathMax(originalPrice, currentAsk * (1.0 + 0.001 * requoteAttempt));
            break;
            
        case ORDER_TYPE_SELL_STOP:
            // Sell Stop: bán với giá thấp hơn thị trường
            // Khi requote, điều chỉnh giá thấp hơn một chút
            newPrice = MathMin(originalPrice, currentBid * (1.0 - 0.001 * requoteAttempt));
            break;
            
        default:
            newPrice = 0;
            break;
    }
    
    return NormalizeDouble(newPrice, m_Digits);
}

//+------------------------------------------------------------------+
//| ModifyOrderParametersForRetry - Điều chỉnh tham số SL/TP để     |
//| thử lại đặt lệnh                                                |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyOrderParametersForRetry(ENUM_ORDER_TYPE orderType, double price, double &sl, double &tp)
{
    if (price <= 0) return false;
    
    // Lấy thông tin về khoảng cách tối thiểu
    double stopLevel = SymbolInfoInteger(m_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * m_Point;
    double freezeLevel = SymbolInfoInteger(m_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * m_Point;
    double minDistance = MathMax(stopLevel, freezeLevel);
    
    // Thêm chút buffer để đảm bảo
    minDistance = minDistance * 1.1; // Thêm 10% buffer
    
    bool isLong = false;
    bool isOpenPrice = false;
    
    // Xác định loại lệnh
    switch (orderType) {
        case ORDER_TYPE_BUY:
        case ORDER_TYPE_BUY_LIMIT:
        case ORDER_TYPE_BUY_STOP:
            isLong = true;
            break;
            
        case ORDER_TYPE_SELL:
        case ORDER_TYPE_SELL_LIMIT:
        case ORDER_TYPE_SELL_STOP:
            isLong = false;
            break;
    }
    
    switch (orderType) {
        case ORDER_TYPE_BUY:
        case ORDER_TYPE_SELL:
            isOpenPrice = true;
            break;
    }
    
    // Điều chỉnh SL
    if (sl != 0) {
        if (isLong) {
            // Đối với lệnh mua, SL phải thấp hơn giá entry đủ xa
            double minSL = price - minDistance;
            if (sl > minSL || MathAbs(price - sl) < minDistance) {
                sl = minSL;
            }
        } else {
            // Đối với lệnh bán, SL phải cao hơn giá entry đủ xa
            double minSL = price + minDistance;
            if (sl < minSL || MathAbs(price - sl) < minDistance) {
                sl = minSL;
            }
        }
    }
    
    // Điều chỉnh TP
    if (tp != 0) {
        if (isLong) {
            // Đối với lệnh mua, TP phải cao hơn giá entry đủ xa
            double minTP = price + minDistance;
            if (tp < minTP || MathAbs(price - tp) < minDistance) {
                tp = minTP;
            }
        } else {
            // Đối với lệnh bán, TP phải thấp hơn giá entry đủ xa
            double minTP = price - minDistance;
            if (tp > minTP || MathAbs(price - tp) < minDistance) {
                tp = minTP;
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| SetupMultipleTargets - Thiết lập nhiều mục tiêu TP cho một lệnh |
//+------------------------------------------------------------------+
bool CTradeManager::SetupMultipleTargets(ulong ticket, double entryPrice, double stopLoss, bool isLong)
{
    if (m_TakeProfitLevelCount <= 0) return false;
    if (!PositionSelectByTicket(ticket)) return false;
    
    double riskPoints = MathAbs(entryPrice - stopLoss) / m_Point;
    if (riskPoints <= 0) return false;
    
    // Tính toán giá TP cho từng mức
    for (int i = 0; i < m_TakeProfitLevelCount; i++) {
        double rMultiple = m_TakeProfitLevels[i].rMultiple;
        
        // Tính giá TP dựa trên R-multiple
        if (isLong) {
            m_TakeProfitLevels[i].price = entryPrice + (rMultiple * riskPoints * m_Point);
        } else {
            m_TakeProfitLevels[i].price = entryPrice - (rMultiple * riskPoints * m_Point);
        }
        
        m_TakeProfitLevels[i].triggered = false;
    }
    
    // Nếu chỉ có 1 mức TP, đặt trực tiếp vào lệnh
    if (m_TakeProfitLevelCount == 1) {
        return m_trade.PositionModify(ticket, stopLoss, m_TakeProfitLevels[0].price);
    }
    
    // Nếu có nhiều mức TP, đặt mức TP cuối cùng (xa nhất) vào lệnh
    int lastTP = m_TakeProfitLevelCount - 1;
    return m_trade.PositionModify(ticket, stopLoss, m_TakeProfitLevels[lastTP].price);
}

//+------------------------------------------------------------------+
//| ManageMultipleTargets - Quản lý nhiều mục tiêu TP cho một lệnh  |
//+------------------------------------------------------------------+
bool CTradeManager::ManageMultipleTargets(ulong ticket)
{
    if (m_TakeProfitLevelCount <= 1) return false; // Không cần quản lý nếu chỉ có 1 mục tiêu
    if (!PositionSelectByTicket(ticket)) return false;
    
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    
    // Kiểm tra các mục tiêu theo thứ tự (từ TP1 đến TPn)
    for (int i = 0; i < m_TakeProfitLevelCount - 1; i++) { // Bỏ qua TP cuối cùng (đã đặt vào lệnh)
        if (m_TakeProfitLevels[i].triggered) continue; // Bỏ qua nếu đã kích hoạt
        
        bool targetReached = false;
        
        // Kiểm tra xem giá hiện tại đã chạm mục tiêu chưa
        if (isLong) {
            targetReached = currentPrice >= m_TakeProfitLevels[i].price;
        } else {
            targetReached = currentPrice <= m_TakeProfitLevels[i].price;
        }
        
        // Nếu đã chạm mục tiêu, đóng một phần lệnh
        if (targetReached) {
            double closeVolume = currentVolume * m_TakeProfitLevels[i].volumePercent / 100.0;
            string comment = StringFormat("TP%d (%.1fR)", i+1, m_TakeProfitLevels[i].rMultiple);
            
            if (SafeClosePartial(ticket, closeVolume, comment)) {
                m_TakeProfitLevels[i].triggered = true;
                
                if (m_logger) {
                    m_logger.LogInfo(StringFormat(
                        "TP%d (%.1fR) đã kích hoạt: Đóng %.2f lots tại %.5f",
                        i+1, m_TakeProfitLevels[i].rMultiple, closeVolume, m_TakeProfitLevels[i].price
                    ));
                }
                
                // Cập nhật currentVolume sau khi đóng một phần
                if (!PositionSelectByTicket(ticket)) return true; // Vị thế đã đóng hoàn toàn
                currentVolume = PositionGetDouble(POSITION_VOLUME);
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CalculateOptimalTakeProfitRatio - Tính toán tỷ lệ TP tối ưu     |
//| dựa trên chế độ thị trường                                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateOptimalTakeProfitRatio(double riskPoints, ENUM_MARKET_REGIME regime)
{
    // Tỷ lệ R:R cơ bản
    double baseRatio = 2.0;
    
    // Điều chỉnh theo chế độ thị trường
    switch (regime) {
        case REGIME_TRENDING:
            // Thị trường đang có xu hướng mạnh, sử dụng tỷ lệ R:R lớn hơn
            baseRatio = 3.0; // 1:3
            break;
            
        case REGIME_SIDEWAY:
            // Thị trường đi ngang, sử dụng tỷ lệ R:R nhỏ hơn
            baseRatio = 1.5; // 1:1.5
            break;
            
        case REGIME_VOLATILE:
            // Thị trường biến động mạnh, sử dụng tỷ lệ R:R trung bình
            baseRatio = 2.0; // 1:2
            break;
            
        default:
            baseRatio = 2.0; // Mặc định 1:2
            break;
    }
    
    // Kiểm tra thời gian giao dịch
    if (IsHighVolatilityTime()) {
        // Thời gian biến động cao (đầu phiên London/New York, etc.)
        baseRatio *= 1.2; // Tăng 20% target
    }
    
    if (IsNewsTime()) {
        // Gần thời gian tin tức
        baseRatio *= 0.8; // Giảm 20% target, chốt lời sớm
    }
    
    if (IsThinMarketCondition()) {
        // Điều kiện thị trường mỏng (ít thanh khoản)
        baseRatio *= 0.7; // Giảm 30% target, chốt lời sớm
    }
    
    return baseRatio;
}

//+------------------------------------------------------------------+
//| IsHighVolatilityTime - Kiểm tra thời gian biến động cao         |
//+------------------------------------------------------------------+
bool CTradeManager::IsHighVolatilityTime()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    int hour = dt.hour;
    
    // Các khoảng thời gian biến động cao
    bool londonOpen = (hour >= 7 && hour <= 8);     // 7-8 GMT
    bool newYorkOpen = (hour >= 13 && hour <= 14);  // 13-14 GMT
    bool asiaOpen = (hour >= 0 && hour <= 2);       // 0-2 GMT
    
    return londonOpen || newYorkOpen || asiaOpen;
}

//+------------------------------------------------------------------+
//| IsNewsTime - Kiểm tra gần thời gian tin tức quan trọng          |
//+------------------------------------------------------------------+
bool CTradeManager::IsNewsTime()
{
    // Trong thực tế, bạn cần có hệ thống lịch kinh tế hoặc tích hợp
    // với dịch vụ cung cấp dữ liệu tin tức.
    // Đây chỉ là ví dụ đơn giản dựa trên các khoảng thời gian cố định
    
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Các thời điểm tin tức quan trọng thường xuyên 
    // (NFP, FOMC, CPI, v.v.)
    
    // NFP - Thứ 6 đầu tiên của tháng, 8:30 ET (12:30 GMT)
    bool isFirstFriday = (dt.day <= 7 && dt.day_of_week == 5);
    bool isNFPTime = isFirstFriday && (dt.hour == 12 && dt.min >= 0 && dt.min <= 59);
    
    // FOMC - Thường vào Thứ 4, 2:00 PM ET (18:00 GMT)
    bool isFOMCDay = (dt.day_of_week == 3);
    bool isFOMCTime = isFOMCDay && (dt.hour == 18 && dt.min >= 0 && dt.min <= 59);
    
    return isNFPTime || isFOMCTime;
}

//+------------------------------------------------------------------+
//| IsThinMarketCondition - Kiểm tra thị trường thanh khoản thấp    |
//+------------------------------------------------------------------+
bool CTradeManager::IsThinMarketCondition()
{
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    int hour = dt.hour;
    bool isWeekend = (dt.day_of_week == 0 || dt.day_of_week == 6);
    
    // Điều kiện thị trường mỏng
    bool lateFridaySession = (dt.day_of_week == 5 && hour >= 20);  // Cuối phiên thứ 6
    bool earlyAsiaSession = (hour >= 22 || hour <= 3);             // Đầu phiên Á, thanh khoản thấp
    bool holidayPeriod = false;  // Cần thêm logic kiểm tra ngày lễ 
    
    return isWeekend || lateFridaySession || earlyAsiaSession || holidayPeriod;
}

//+------------------------------------------------------------------+
//| EncodeMagicNumber - Mã hóa thông tin vào MagicNumber            |
//+------------------------------------------------------------------+
int CTradeManager::EncodeMagicNumber(int baseNumber, ENUM_TIMEFRAMES timeframe, ENUM_ENTRY_SCENARIO scenario)
{
    // Đảm bảo baseNumber nằm trong khoảng hợp lệ (1-999)
    baseNumber = MathMax(1, MathMin(999, baseNumber));
    
    // Mã hóa timeframe (0-7 => 1-8)
    int tfCode = 0;
    switch (timeframe) {
        case PERIOD_M1:  tfCode = 1; break;
        case PERIOD_M5:  tfCode = 2; break;
        case PERIOD_M15: tfCode = 3; break;
        case PERIOD_M30: tfCode = 4; break;
        case PERIOD_H1:  tfCode = 5; break;
        case PERIOD_H4:  tfCode = 6; break;
        case PERIOD_D1:  tfCode = 7; break;
        case PERIOD_W1:  tfCode = 8; break;
        default:         tfCode = 0; break;
    }
    
    // Mã hóa kịch bản (0-10)
    int scenarioCode = (int)scenario;
    
    // Magic = BaseNumber(3) + TimeframeCode(1) + ScenarioCode(2)
    return baseNumber * 1000 + tfCode * 100 + scenarioCode;
}

//+------------------------------------------------------------------+
//| DecodeMagicNumber - Giải mã thông tin từ MagicNumber            |
//+------------------------------------------------------------------+
void CTradeManager::DecodeMagicNumber(int magic, int &baseNumber, ENUM_TIMEFRAMES &timeframe, ENUM_ENTRY_SCENARIO &scenario)
{
    // Giải mã BaseNumber (3 chữ số đầu tiên)
    baseNumber = magic / 1000;
    
    // Giải mã TimeframeCode (chữ số thứ 4)
    int tfCode = (magic % 1000) / 100;
    
    // Giải mã ScenarioCode (2 chữ số cuối)
    int scenarioCode = magic % 100;
    
    // Chuyển đổi TimeframeCode thành ENUM_TIMEFRAMES
    switch (tfCode) {
        case 1: timeframe = PERIOD_M1; break;
        case 2: timeframe = PERIOD_M5; break;
        case 3: timeframe = PERIOD_M15; break;
        case 4: timeframe = PERIOD_M30; break;
        case 5: timeframe = PERIOD_H1; break;
        case 6: timeframe = PERIOD_H4; break;
        case 7: timeframe = PERIOD_D1; break;
        case 8: timeframe = PERIOD_W1; break;
        default: timeframe = PERIOD_CURRENT; break;
    }
    
    // Chuyển đổi ScenarioCode thành ENUM_ENTRY_SCENARIO
    scenario = (ENUM_ENTRY_SCENARIO)scenarioCode;
}

//+------------------------------------------------------------------+
//| GenerateDetailedComment - Tạo comment chi tiết cho lệnh          |
//+------------------------------------------------------------------+
string CTradeManager::GenerateDetailedComment(bool isLong, ENUM_ENTRY_SCENARIO scenario, string additionalInfo)
{
    // Xác định mã khung thời gian hiện tại
    string tfCode = "";
    ENUM_TIMEFRAMES currentTF = (ENUM_TIMEFRAMES)Period();
    
    switch (currentTF) {
        case PERIOD_M1:  tfCode = "M1"; break;
        case PERIOD_M5:  tfCode = "M5"; break;
        case PERIOD_M15: tfCode = "M15"; break;
        case PERIOD_M30: tfCode = "M30"; break;
        case PERIOD_H1:  tfCode = "H1"; break;
        case PERIOD_H4:  tfCode = "H4"; break;
        case PERIOD_D1:  tfCode = "D1"; break;
        case PERIOD_W1:  tfCode = "W1"; break;
        default:         tfCode = "??"; break;
    }
    
    // Xác định phiên giao dịch hiện tại
    string sessionCode = "";
    ENUM_SESSION currentSession = DetermineCurrentSession();
    
    switch (currentSession) {
        case SESSION_ASIAN:             sessionCode = "AS"; break;
        case SESSION_EUROPEAN:          sessionCode = "EU"; break;
        case SESSION_AMERICAN:          sessionCode = "US"; break;
        case SESSION_EUROPEAN_AMERICAN: sessionCode = "EUUS"; break;
        case SESSION_CLOSING:           sessionCode = "CL"; break;
        default:                        sessionCode = "??"; break;
    }
    
    // Xác định mã kịch bản
    string scenarioCode = "";
    
    switch (scenario) {
        case SCENARIO_NONE:               scenarioCode = "NONE"; break;
        case SCENARIO_BULLISH_PULLBACK:   scenarioCode = "BULL"; break;
        case SCENARIO_BEARISH_PULLBACK:   scenarioCode = "BEAR"; break;
        case SCENARIO_FIBONACCI_PULLBACK: scenarioCode = "FIB"; break;
        case SCENARIO_STRONG_PULLBACK:    scenarioCode = "STRG"; break;
        case SCENARIO_LIQUIDITY_GRAB:     scenarioCode = "LIQ"; break;
        case SCENARIO_MOMENTUM_SHIFT:     scenarioCode = "MOM"; break;
        case SCENARIO_HARMONIC_PATTERN:   scenarioCode = "HARM"; break;
        case SCENARIO_SCALING:            scenarioCode = "SCALE"; break;
        default:                          scenarioCode = "??"; break;
    }
    
    // Tạo comment theo format: BUY/SELL|SCENARIO|TF|SESSION|ADDITIONALINFO
    string direction = isLong ? "BUY" : "SELL";
    string comment = StringFormat("%s|%s|%s|%s", direction, scenarioCode, tfCode, sessionCode);
    
    // Thêm thông tin bổ sung nếu có
    if (additionalInfo != "") {
        comment += "|" + additionalInfo;
    }
    
    return comment;
}

//+------------------------------------------------------------------+
//| UpdatePerformanceStats - Cập nhật thống kê hiệu suất            |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePerformanceStats(bool isWin, double profit, ENUM_ENTRY_SCENARIO scenario, ENUM_SESSION session)
{
    // Cập nhật thống kê tổng thể
    m_Performance.totalTrades++;
    
    if (isWin) {
        m_Performance.winTrades++;
        m_Performance.grossProfit += profit;
        m_Performance.consecutiveWins++;
        m_Performance.consecutiveLosses = 0;
        
        if (m_Performance.consecutiveWins > m_Performance.maxConsecutiveWins) {
            m_Performance.maxConsecutiveWins = m_Performance.consecutiveWins;
        }
    } else {
        m_Performance.lossTrades++;
        m_Performance.grossLoss += MathAbs(profit); // Đảm bảo luôn dương
        m_Performance.consecutiveLosses++;
        m_Performance.consecutiveWins = 0;
        
        if (m_Performance.consecutiveLosses > m_Performance.maxConsecutiveLosses) {
            m_Performance.maxConsecutiveLosses = m_Performance.consecutiveLosses;
        }
    }
    
    // Cập nhật chỉ số tổng hợp
    m_Performance.netProfit = m_Performance.grossProfit - m_Performance.grossLoss;
    
    if (m_Performance.grossLoss > 0) {
        m_Performance.profitFactor = m_Performance.grossProfit / m_Performance.grossLoss;
    } else {
        m_Performance.profitFactor = m_Performance.grossProfit > 0 ? 100.0 : 0.0;
    }
    
    if (m_Performance.totalTrades > 0) {
        m_Performance.winRate = 100.0 * m_Performance.winTrades / m_Performance.totalTrades;
    }
    
    if (m_Performance.winTrades > 0) {
        m_Performance.averageWin = m_Performance.grossProfit / m_Performance.winTrades;
    }
    
    if (m_Performance.lossTrades > 0) {
        m_Performance.averageLoss = m_Performance.grossLoss / m_Performance.lossTrades;
    }
    
    if (m_Performance.totalTrades > 0) {
        m_Performance.expectancy = m_Performance.netProfit / m_Performance.totalTrades;
    }
    
    // Cập nhật thống kê theo cluster/scenario
    int scenarioIndex = (int)scenario;
    if (scenarioIndex >= 0 && scenarioIndex < ArraySize(m_Performance.clusterTrades)) {
        m_Performance.clusterTrades[scenarioIndex]++;
        
        if (isWin) {
            m_Performance.clusterProfit[scenarioIndex] += profit;
        } else {
            m_Performance.clusterProfit[scenarioIndex] -= MathAbs(profit);
        }
        
        if (m_Performance.clusterTrades[scenarioIndex] > 0) {
            int clusterWins = (int)(m_Performance.clusterTrades[scenarioIndex] * m_Performance.clusterWinRate[scenarioIndex] / 100.0);
            
            if (isWin) {
                clusterWins++;
            }
            
            m_Performance.clusterWinRate[scenarioIndex] = 100.0 * clusterWins / m_Performance.clusterTrades[scenarioIndex];
        }
    }
    
    // Cập nhật thống kê theo phiên
    int sessionIndex = (int)session;
    if (sessionIndex >= 0 && sessionIndex < ArraySize(m_Performance.sessionTrades)) {
        m_Performance.sessionTrades[sessionIndex]++;
        
        if (isWin) {
            m_Performance.sessionProfit[sessionIndex] += profit;
        } else {
            m_Performance.sessionProfit[sessionIndex] -= MathAbs(profit);
        }
        
        if (m_Performance.sessionTrades[sessionIndex] > 0) {
            int sessionWins = (int)(m_Performance.sessionTrades[sessionIndex] * m_Performance.sessionWinRate[sessionIndex] / 100.0);
            
            if (isWin) {
                sessionWins++;
            }
            
            m_Performance.sessionWinRate[sessionIndex] = 100.0 * sessionWins / m_Performance.sessionTrades[sessionIndex];
        }
    }
    
    // Cập nhật thống kê theo timeframe
    ENUM_TIMEFRAMES currentTF = (ENUM_TIMEFRAMES)Period();
    int tfIndex = 0;
    
    switch (currentTF) {
        case PERIOD_M1:  tfIndex = 0; break;
        case PERIOD_M5:  tfIndex = 1; break;
        case PERIOD_M15: tfIndex = 2; break;
        case PERIOD_M30: tfIndex = 3; break;
        case PERIOD_H1:  tfIndex = 4; break;
        case PERIOD_H4:  tfIndex = 5; break;
        case PERIOD_D1:  tfIndex = 6; break;
        case PERIOD_W1:  tfIndex = 7; break;
        default:         tfIndex = 0; break;
    }
    
    if (tfIndex >= 0 && tfIndex < ArraySize(m_Performance.timeframeWinRate)) {
        // Tương tự cập nhật như trên cho timeframe
        // ...
    }
}

//+------------------------------------------------------------------+
//| LogPerformanceStats - Ghi log thống kê hiệu suất               |
//+------------------------------------------------------------------+
void CTradeManager::LogPerformanceStats()
{
    if (m_Performance.totalTrades <= 0 || m_logger == NULL) return;
    
    string report = "===== THỐNG KÊ HIỆU SUẤT =====\n";
    report += StringFormat("Tổng số lệnh: %d (Thắng: %d, Thua: %d)\n", 
                         m_Performance.totalTrades, m_Performance.winTrades, m_Performance.lossTrades);
    report += StringFormat("Tỷ lệ thắng: %.2f%%\n", m_Performance.winRate);
    report += StringFormat("Profit Factor: %.2f\n", m_Performance.profitFactor);
    report += StringFormat("Lợi nhuận ròng: %.2f\n", m_Performance.netProfit);
    report += StringFormat("Kỳ vọng toán học: %.2f\n", m_Performance.expectancy);
    report += StringFormat("Thắng liên tiếp lớn nhất: %d\n", m_Performance.maxConsecutiveWins);
    report += StringFormat("Thua liên tiếp lớn nhất: %d\n", m_Performance.maxConsecutiveLosses);
    
    report += "\n--- Theo Kịch bản ---\n";
    string scenarioNames[] = {"Không", "Bullish", "Bearish", "Fibonacci", "Strong", "Liquidity", "Momentum", "Harmonic", "Scaling", "Custom"};
    
    for (int i = 0; i < ArraySize(m_Performance.clusterTrades); i++) {
        if (m_Performance.clusterTrades[i] > 0) {
            string name = (i < ArraySize(scenarioNames)) ? scenarioNames[i] : "Khác";
            report += StringFormat("%s: %d lệnh, Win rate: %.2f%%, P/L: %.2f\n", 
                                name, m_Performance.clusterTrades[i], 
                                m_Performance.clusterWinRate[i], m_Performance.clusterProfit[i]);
        }
    }
    
    report += "\n--- Theo Phiên ---\n";
    string sessionNames[] = {"Á", "Âu", "Mỹ", "Âu-Mỹ", "Đóng cửa"};
    
    for (int i = 0; i < ArraySize(m_Performance.sessionTrades); i++) {
        if (m_Performance.sessionTrades[i] > 0) {
            string name = (i < ArraySize(sessionNames)) ? sessionNames[i] : "Khác";
            report += StringFormat("Phiên %s: %d lệnh, Win rate: %.2f%%, P/L: %.2f\n", 
                                name, m_Performance.sessionTrades[i], 
                                m_Performance.sessionWinRate[i], m_Performance.sessionProfit[i]);
        }
    }
    
    m_logger.LogInfo(report);
}

//+------------------------------------------------------------------+
//| SavePerformanceToFile - Lưu thống kê hiệu suất vào file         |
//+------------------------------------------------------------------+
void CTradeManager::SavePerformanceToFile(string filename)
{
    if (m_Performance.totalTrades <= 0) return;
    
    // Tạo đường dẫn file
    string filePath = "Data\\" + filename;
    
    // Tạo thư mục nếu chưa tồn tại
    if (!FolderCreate("Data")) {
        if (m_logger) {
            m_logger.LogError("Không thể tạo thư mục Data");
        }
        return;
    }
    
    // Mở file để ghi
    int fileHandle = FileOpen(filePath, FILE_WRITE | FILE_CSV | FILE_ANSI);
    if (fileHandle == INVALID_HANDLE) {
        if (m_logger) {
            m_logger.LogError("Không thể mở file " + filePath + " để ghi. Lỗi: " + IntegerToString(GetLastError()));
        }
        return;
    }
    
    // Ghi header
    FileWrite(fileHandle, "Thông số", "Giá trị");
    
    // Ghi thông tin chung
    FileWrite(fileHandle, "Symbol", m_Symbol);
    FileWrite(fileHandle, "MagicNumber", IntegerToString(m_MagicNumber));
    FileWrite(fileHandle, "Ngày xuất", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));
    FileWrite(fileHandle, "", "");
    
    // Ghi thông tin hiệu suất
    FileWrite(fileHandle, "Tổng số lệnh", IntegerToString(m_Performance.totalTrades));
    FileWrite(fileHandle, "Lệnh thắng", IntegerToString(m_Performance.winTrades));
    FileWrite(fileHandle, "Lệnh thua", IntegerToString(m_Performance.lossTrades));
    FileWrite(fileHandle, "Tỷ lệ thắng (%)", DoubleToString(m_Performance.winRate, 2));
    FileWrite(fileHandle, "Profit Factor", DoubleToString(m_Performance.profitFactor, 2));
    FileWrite(fileHandle, "Lợi nhuận ròng", DoubleToString(m_Performance.netProfit, 2));
    FileWrite(fileHandle, "Kỳ vọng toán học", DoubleToString(m_Performance.expectancy, 2));
    FileWrite(fileHandle, "Thắng liên tiếp lớn nhất", IntegerToString(m_Performance.maxConsecutiveWins));
    FileWrite(fileHandle, "Thua liên tiếp lớn nhất", IntegerToString(m_Performance.maxConsecutiveLosses));
    FileWrite(fileHandle, "Thắng trung bình", DoubleToString(m_Performance.averageWin, 2));
    FileWrite(fileHandle, "Thua trung bình", DoubleToString(m_Performance.averageLoss, 2));
    FileWrite(fileHandle, "", "");
    
    // Ghi thông tin theo kịch bản
    FileWrite(fileHandle, "--- Theo Kịch bản ---", "");
    string scenarioNames[] = {"Không", "Bullish", "Bearish", "Fibonacci", "Strong", "Liquidity", "Momentum", "Harmonic", "Scaling", "Custom"};
    
    for (int i = 0; i < ArraySize(m_Performance.clusterTrades); i++) {
        if (m_Performance.clusterTrades[i] > 0) {
            string name = (i < ArraySize(scenarioNames)) ? scenarioNames[i] : "Khác";
            FileWrite(fileHandle, name + " - Số lệnh", IntegerToString(m_Performance.clusterTrades[i]));
            FileWrite(fileHandle, name + " - Win rate (%)", DoubleToString(m_Performance.clusterWinRate[i], 2));
            FileWrite(fileHandle, name + " - P/L", DoubleToString(m_Performance.clusterProfit[i], 2));
        }
    }
    FileWrite(fileHandle, "", "");
    
    // Ghi thông tin theo phiên
    FileWrite(fileHandle, "--- Theo Phiên ---", "");
    string sessionNames[] = {"Á", "Âu", "Mỹ", "Âu-Mỹ", "Đóng cửa"};
    
    for (int i = 0; i < ArraySize(m_Performance.sessionTrades); i++) {
        if (m_Performance.sessionTrades[i] > 0) {
            string name = (i < ArraySize(sessionNames)) ? sessionNames[i] : "Khác";
            FileWrite(fileHandle, "Phiên " + name + " - Số lệnh", IntegerToString(m_Performance.sessionTrades[i]));
            FileWrite(fileHandle, "Phiên " + name + " - Win rate (%)", DoubleToString(m_Performance.sessionWinRate[i], 2));
            FileWrite(fileHandle, "Phiên " + name + " - P/L", DoubleToString(m_Performance.sessionProfit[i], 2));
        }
    }
    
    // Đóng file
    FileClose(fileHandle);
    
    if (m_logger) {
        m_logger.LogInfo("Đã lưu thống kê hiệu suất vào file " + filePath);
    }
}

//+------------------------------------------------------------------+
//| ResetPerformanceStats - Reset thống kê hiệu suất                |
//+------------------------------------------------------------------+
void CTradeManager::ResetPerformanceStats(bool resetDaily, bool resetWeekly, bool resetMonthly)
{
    // Ghi lại thống kê trước khi reset
    LogPerformanceStats();
    SavePerformanceToFile();
    
    // Reset theo ngày nếu được yêu cầu
    if (resetDaily) {
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        if (m_logger) {
            m_logger.LogInfo("Đặt lại thống kê ngày. Balance mới: " + DoubleToString(m_DayStartBalance, 2));
        }
    }
    
    // Reset theo tuần nếu được yêu cầu
    if (resetWeekly) {
        m_WeekStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        if (m_logger) {
            m_logger.LogInfo("Đặt lại thống kê tuần. Balance mới: " + DoubleToString(m_WeekStartBalance, 2));
        }
    }
    
    // Reset theo tháng nếu được yêu cầu
    if (resetMonthly) {
        m_MonthStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        if (m_logger) {
            m_logger.LogInfo("Đặt lại thống kê tháng. Balance mới: " + DoubleToString(m_MonthStartBalance, 2));
        }
        
        // Reset toàn bộ thống kê hiệu suất
        m_Performance = StrategyPerformance(); // Tạo mới
    }
}

//+------------------------------------------------------------------+
//| SetAlert - Đặt cảnh báo mới                                     |
//+------------------------------------------------------------------+
void CTradeManager::SetAlert(string message, int severity)
{
    m_CurrentAlert.active = true;
    m_CurrentAlert.alertTime = TimeCurrent();
    m_CurrentAlert.message = message;
    m_CurrentAlert.severity = severity;
    m_CurrentAlert.notified = false;
    
    if (m_logger) {
        string severityText = "";
        switch (severity) {
            case 1: severityText = "Thấp"; break;
            case 2: severityText = "Vừa"; break;
            case 3: severityText = "Cao"; break;
            case 4: severityText = "Nghiêm trọng"; break;
            case 5: severityText = "Khẩn cấp"; break;
            default: severityText = "Không xác định"; break;
        }
        
        m_logger.LogWarning(StringFormat("CẢNH BÁO [%s]: %s", severityText, message));
    }
}

//+------------------------------------------------------------------+
//| ClearAlert - Xóa cảnh báo hiện tại                              |
//+------------------------------------------------------------------+
void CTradeManager::ClearAlert()
{
    if (m_CurrentAlert.active && m_logger) {
        m_logger.LogInfo("Đã xóa cảnh báo: " + m_CurrentAlert.message);
    }
    
    m_CurrentAlert.active = false;
    m_CurrentAlert.alertTime = 0;
    m_CurrentAlert.message = "";
    m_CurrentAlert.severity = 0;
    m_CurrentAlert.notified = false;
}

//+------------------------------------------------------------------+
//| GetStartOfDay - Lấy thời gian bắt đầu của ngày                  |
//+------------------------------------------------------------------+
datetime CTradeManager::GetStartOfDay(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    // Đặt giờ, phút, giây về 0 để lấy thời gian bắt đầu ngày
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    
    return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| GetStartOfWeek - Lấy thời gian bắt đầu của tuần                 |
//+------------------------------------------------------------------+
datetime CTradeManager::GetStartOfWeek(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    // Đặt giờ, phút, giây về 0
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    
    // Trở về Chủ nhật (bắt đầu tuần mới)
    // day_of_week: 0-Chủ nhật, 1-Thứ 2, ..., 6-Thứ 7
    int daysToSubtract = dt.day_of_week;
    
    // Tính ngày bắt đầu tuần
    datetime result = StructToTime(dt) - daysToSubtract * 86400; // 86400 = số giây trong 1 ngày
    
    return result;
}

//+------------------------------------------------------------------+
//| GetStartOfMonth - Lấy thời gian bắt đầu của tháng                |
//+------------------------------------------------------------------+
datetime CTradeManager::GetStartOfMonth(datetime time)
{
    MqlDateTime dt;
    TimeToStruct(time, dt);
    
    // Đặt ngày về 1, giờ, phút, giây về 0
    dt.day = 1;
    dt.hour = 0;
    dt.min = 0;
    dt.sec = 0;
    
    return StructToTime(dt);
}