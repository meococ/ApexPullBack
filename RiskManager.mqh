//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                       Module Quản lý Rủi ro và Vốn Nâng cao      |
//|                              Version 14.0 - ApexPullback EA      |
//+------------------------------------------------------------------+
//-- #property copyright "ApexPullback"
//-- #property link      "https://www.apexpullback.com"
//-- #property version   "14.0"
//-- #property strict

#ifndef RISK_MANAGER_MQH_
#define RISK_MANAGER_MQH_

#include <Trade/AccountInfo.mqh> // Sử dụng AccountInfo cho kiểm tra balance/equity
#include <Trade/SymbolInfo.mqh>  // Sử dụng SymbolInfo cho thuộc tính của symbol
#include <Files/FileTxt.mqh>     // Thư viện file I/O cho các thao tác với file
#include <Files/FileBin.mqh>     // Thư viện file I/O binary
#include "Enums.mqh"             // Các enum cho các chế độ thị trường, mặt hàng
#include "CommonStructs.mqh"     // Enums và structs chung
#include "Constants.mqh"         // Các hằng số
#include "Logger.mqh"            // Tiện ích ghi log
#include "AssetDNA.mqh"          // Module phân tích DNA tài sản (thay thế AssetProfiler)
#include "PerformanceTracker.mqh" // Module theo dõi hiệu suất giao dịch

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Class CRiskManager                                               |
//| Quản lý rủi ro: risk adaptation, position sizing, bảo vệ tài     |
//| khoản, theo dõi hiệu suất, và nhận thức danh mục đầu tư          |
//| Phiên bản 14.0: Thêm tích hợp AssetProfiler, cải tiến adaptive   |
//| risk, bảo vệ drawdown, và tối ưu hóa quản lý lệnh                |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    EAContext*          m_Context;             // Con trỏ đến EAContext
    // --- Thông tin cài đặt (sẽ được lấy từ m_Context) ---
    string              m_Symbol;               // Symbol chính EA đang chạy
    double              m_RiskPerTrade;         // Risk mỗi giao dịch theo phần trăm balance
    double              m_MaxDailyLossPercent;  // Giới hạn lỗ tối đa trong ngày (% của start equity)
    double              m_MaxDrawdownPercent;   // Giới hạn drawdown tối đa (% của balance/equity)
    int                 m_MaxDailyTrades;       // Số lệnh tối đa mỗi ngày
    int                 m_MaxConsecutiveLosses; // Số lần thua liên tiếp tối đa trước khi tạm dừng
    bool                m_PropFirmMode;         // Chế độ Prop firm (quản lý rủi ro nghiêm ngặt hơn)
    ENUM_DRAWDOWN_TYPE  m_DrawdownType;         // Loại drawdown (Balance-based hoặc Equity-based)
    double              m_DrawdownReduceThreshold; // Ngưỡng DD để bắt đầu giảm risk
    double              m_MinRiskMultiplier;    // Hệ số giảm risk tối thiểu (VD: 0.3 = 30%)
    bool                m_EnableTaperedRisk;    // Bật chế độ giảm risk từ từ (không đột ngột)
    double              m_MaxRisk;              // Risk tối đa cho phép (%)
    double              m_MinRisk;              // Risk tối thiểu cho phép (%)

    // --- Theo dõi trạng thái trong ngày ---
    double              m_DayStartEquity;       // Equity ban đầu của ngày giao dịch hiện tại
    int                 m_DailyTradeCount;      // Số lệnh đã thực hiện trong ngày
    int                 m_ConsecutiveLosses;    // Số lần thua liên tiếp hiện tại
    int                 m_ConsecutiveWins;      // Số lần thắng liên tiếp hiện tại
    double              m_PeakEquity;           // Equity cao nhất đạt được
    
    // --- Theo dõi hiệu suất ---
    CPerformanceTracker *m_PerformanceTracker;     // Module theo dõi hiệu suất
    double              m_MaxDrawdownRecorded;  // Drawdown tối đa đã ghi nhận (%)
    datetime            m_PauseUntil;           // Thời gian tạm dừng đến khi
    datetime            m_LastStatsUpdate;      // Thời gian cập nhật thống kê cuối
    double              m_DailyLoss;            // Tổng lỗ trong ngày hiện tại (tính bằng tiền)
    double              m_WeeklyLoss;           // Tổng lỗ trong tuần hiện tại (tính bằng tiền)
    int                 m_CurrentDay;           // Ngày hiện tại để theo dõi reset

    // --- Performance Tracker ---
    int                 m_TotalTrades;          // Tổng số giao dịch
    int                 m_Wins;                 // Số lần thắng
    int                 m_Losses;               // Số lần thua
    double              m_ProfitSum;            // Tổng lợi nhuận
    double              m_LossSum;              // Tổng lỗ
    double              m_MaxProfitTrade;       // Giao dịch lãi lớn nhất
    double              m_MaxLossTrade;         // Giao dịch lỗ lớn nhất (giá trị dương)
    int                 m_MaxConsecutiveWins;   // Số lần thắng liên tiếp lớn nhất
    int                 m_HistoricalMaxConsecutiveLosses; // Số lần thua liên tiếp lớn nhất

    // --- Thông tin thị trường bổ sung ---
    double              m_ATRHistory[];          // Lịch sử giá trị ATR
    double              m_AverageATR;            // Giá trị ATR trung bình
    double              m_MarketProfile;         // Hồ sơ thị trường
    double              m_TrendTradeRatio;       // Tỷ lệ giao dịch theo xu hướng
    double              m_CounterTradeRatio;     // Tỷ lệ giao dịch ngược xu hướng
    double              m_PriceActionThreshold;  // Ngưỡng hành động giá
    ENUM_ENTRY_SCENARIO m_PreferredScenario;     // Kịch bản giao dịch ưa thích
    bool                m_DetailedLogging;       // Bật/tắt logging chi tiết

    // --- Thông tin market regime ---
    bool                m_IsTransitioningMarket; // Thị trường đang trong giai đoạn chuyển tiếp
    double              m_MarketRegimeConfidence; // Độ tin cậy của chế độ thị trường (0-1)
    double              m_ATRRatio;              // Tỉ lệ ATR hiện tại so với ATR trung bình
    double              m_SpreadRatio;           // Tỉ lệ spread hiện tại so với trung bình
    ENUM_MARKET_REGIME  m_CurrentRegime;         // Chế độ thị trường hiện tại
    ENUM_SESSION        m_CurrentSession;        // Phiên giao dịch hiện tại
    
    // --- Logger ---
    CLogger*  m_Logger;          // Con trỏ đến đối tượng logger
    
    // --- Thống kê theo loại giao dịch ---
    struct ClusterStats {
        int trades;         // Số giao dịch
        int wins;           // Số lần thắng
        double profit;      // Tổng lợi nhuận
        double loss;        // Tổng lỗ
    };
    
    ClusterStats        m_ClusterStats[3];     // Thống kê cho 3 cluster
    
    struct SessionStats {
        int trades;         // Số giao dịch
        int wins;           // Số lần thắng
        double profit;      // Tổng lợi nhuận
        double loss;        // Tổng lỗ
    };
    
    SessionStats        m_SessionStats[5];     // Thống kê cho các phiên giao dịch
    
    struct ATRStats {
        double atrLevel;    // Mức ATR
        int trades;         // Số giao dịch
        int wins;           // Số lần thắng
        double profit;      // Tổng lợi nhuận
        double loss;        // Tổng lỗ
    };
    
    ATRStats            m_ATRStats[5];         // Thống kê cho các mức ATR khác nhau
    
    struct MarketRegimeStats {
        bool isTransitioning; // Đang chuyển tiếp không
        int trades;         // Số giao dịch
        int wins;           // Số lần thắng
        double profit;      // Tổng lợi nhuận
        double loss;        // Tổng lỗ
    };
    
    MarketRegimeStats   m_RegimeStats[2];     // Thống kê cho regime (0=stable, 1=transition)

    // --- AssetProfile theo dõi ---
    struct AssetHistoryData {
        double avgATR;           // ATR trung bình của tài sản (14 ngày)
        double avgSpread;        // Spread trung bình (điểm)
        double minStopDistance;  // Khoảng cách SL tối thiểu hợp lý (điểm)
        double priceVolatility;  // Độ biến động giá (%)
        double bestTimePerformance[24]; // Hiệu suất theo giờ (24 giờ)
        double bestRRRatio;      // Tỷ lệ R:R tối ưu cho tài sản này
    };
    
    AssetHistoryData    m_AssetProfile;       // Profile tài sản hiện tại
    
    ENUM_ADAPTIVE_MODE  m_AdaptiveMode;         // Chế độ thích nghi (Manual, Log Only, Hybrid)

    // --- Cấu hình cụ thể cho tài sản ---
    struct AssetConfig {
        double riskMultiplier;   // Hệ số risk cho tài sản này (0.5-1.5)
        double slAtrMultiplier;  // Hệ số ATR cho SL
        double tpRrRatio;        // Tỷ lệ R:R cho TP
        double maxSpreadPoints;  // Số điểm spread tối đa chấp nhận được
        double volatilityFactor; // Hệ số biến động cho tài sản
        bool   hasCriticalLevel; // Có mức quan trọng (S/R quan trọng) không
        double criticalLevel;    // Giá trị mức quan trọng
    };
    
    AssetConfig         m_AssetConfig;        // Cấu hình cho tài sản hiện tại

    // --- Công cụ hỗ trợ ---
    CAccountInfo        m_AccountInfo;         // Đối tượng thông tin tài khoản
    CSymbolInfo         m_SymbolInfo;          // Đối tượng thông tin symbol
    CAssetProfiler*     m_AssetProfiler;       // Con trỏ đến asset profiler (v14.0)

public:
    // --- Constructor/Destructor ---
    CRiskManager(EAContext* context);
    ~CRiskManager();

    // --- Hàm Khởi tạo ---
    bool Initialize();
    
    // Khởi tạo m_DayStartEquity cho tính toán drawdown dựa trên balance
    void InitializeDayStartEquity() {
        if (m_DrawdownType == DRAWDOWN_BALANCE_BASED) {
            m_DayStartEquity = m_AccountInfo.Balance();
        } else {
            m_DayStartEquity = m_AccountInfo.Equity();
        }
    }
                  
    // Thiết lập các module liên quan
    void SetLogger(CLogger *logger) { m_Logger = logger; }
    void SetAssetProfiler(CAssetProfiler* profiler) { m_AssetProfiler = profiler; }
    void SetAdaptiveMode(ENUM_ADAPTIVE_MODE mode) { m_AdaptiveMode = mode; }
    
    // --- Thiết lập các tham số nâng cao ---
    void SetDrawdownProtectionParams(double drawdownReduceThreshold, double minRiskMultiplier = 0.3, 
                                  bool enableTaperedRisk = true);
    void SetMarketRegimeInfo(ENUM_MARKET_REGIME regime, bool isTransitioning, double regimeConfidence, 
                           double atrRatio, ENUM_SESSION session);
    void SetRiskLimits(double maxRisk, double minRisk);
    
    // --- V14.0: AssetProfiler tích hợp ---
    bool LoadAssetProfile(string symbol = "");
    bool SaveAssetProfile(string symbol = "");
    void UpdateAssetProfile(double currentATR, double currentSpread);
    void SetAssetConfig(double riskMultiplier, double slAtrMultiplier, double tpRrRatio, 
                       double maxSpreadPoints, double volatilityFactor = 1.0);
    
    // --- V14.0: Cải tiến quản lý risk ---
    double CalculateAdaptiveRiskPercent(double baseRiskPercent = -1.0, string &adjustmentReasonOut = ""); // Added default for adjustmentReasonOut
    double GetRegimeFactor(ENUM_MARKET_REGIME regime, bool isTransitioning = false); // Added isTransitioning with default
    double GetSessionFactor(ENUM_SESSION session, string symbol = ""); // Added symbol with default
    double GetSymbolRiskFactor(string symbol = ""); // Added symbol with default
    double IsApproachingDailyLossLimit();
    
    // --- Quản lý trạng thái ---
    bool CheckPauseCondition();
    bool CheckAutoResume();
    void PauseTrading(int minutes, string reason = "");
    void ResumeTrading(string reason = "");
    bool IsMaxLossReached();
    bool ShouldPauseTrading();
    void ResetDailyStats(double newStartEquity = 0.0);
    void UpdateMaxDrawdown();
    datetime GetPauseUntil() const { return m_PauseUntil; }
    bool IsPaused() const { return (m_PauseUntil > TimeCurrent()); }
    void UpdateDailyVars();
    void UpdatePauseStatus();
    
    // --- Quản lý rủi ro chính ---
    bool CanOpenNewPosition(double volume, bool isBuy);
    bool CanScalePosition(double additionalVolume, bool isLong);
    void RegisterNewPosition(ulong ticket, double volume, double riskPercent);
    void UpdatePositionPartial(ulong ticket, double partialVolume);
    void UpdateStatsOnDealClose(bool isWin, double profit, int clusterType = 0, int sessionType = 0, double atrRatio = 1.0);

    // --- Tính toán kích thước lệnh ---
    double CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                          double qualityFactor = 1.0, double riskPercent = 0.0);
    double CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                double atrRatio, double maxVolatilityFactor, 
                                double minLotMultiplier, double qualityFactor = 1.0);
    double CalculateOptimalLotSize(double riskPercent, double slDistancePoints);
    
    // --- Tính toán SL/TP ---
    double CalculateOptimalStopLoss(double entryPrice, bool isLong);
    double CalculateOptimalTakeProfit(double entryPrice, double stopLoss, bool isLong);
    
    // --- V14.0: Kiểm tra điều kiện thị trường ---
    bool IsSpreadAcceptable(double currentSpread = 0.0);
    bool IsVolatilityAcceptable(double currentATRratio = 0.0);
    bool IsMarketSuitableForTrading();
    
    // --- Getter ---
    double GetCurrentDrawdownPercent();
    double GetDailyLossPercent();
    double GetWinRate() const;
    double GetProfitFactor() const;
    double GetExpectancy() const;
    double GetMaxDrawdown() const { return m_MaxDrawdownRecorded; }
    int GetConsecutiveLosses() const { return m_ConsecutiveLosses; }
    int GetConsecutiveWins() const { return m_ConsecutiveWins; }
    int GetDailyTradeCount() const { return m_DailyTradeCount; }
    double GetBaseRiskPercent() const { return m_RiskPerTrade; }
    double GetAdaptiveRisk() { return CalculateAdaptiveRiskPercent(); }
    double GetDailyLoss() const { return m_DailyLoss; }
    double GetMaxDailyLoss() const { return m_MaxDailyLossPercent; }
    double GetAcceptableSpreadThreshold();
    
    // --- Thông tin AssetProfile ---
    double GetAverageATR() const { return m_AssetProfile.avgATR; }
    double GetAverageSpread() const { return m_AssetProfile.avgSpread; }
    double GetMinStopDistance() const { return m_AssetProfile.minStopDistance; }
    double GetOptimalRRRatio() const { return m_AssetProfile.bestRRRatio; }
    double GetAssetVolatilityFactor() const { return m_AssetConfig.volatilityFactor; }
    
    // --- Thống kê theo cluster ---
    double GetClusterWinRate(int clusterIndex) const;
    double GetClusterProfitFactor(int clusterIndex) const;
    int GetClusterTrades(int clusterIndex) const { return m_ClusterStats[clusterIndex].trades; }
    
    // --- Thống kê theo phiên giao dịch ---
    double GetSessionWinRate(int sessionIndex) const;
    double GetSessionProfitFactor(int sessionIndex) const;
    int GetSessionTrades(int sessionIndex) const { return m_SessionStats[sessionIndex].trades; }
    
    // --- Thống kê theo ATR ---
    double GetATRWinRate(int atrIndex) const;
    double GetATRProfitFactor(int atrIndex) const;
    int GetATRTrades(int atrIndex) const { return m_ATRStats[atrIndex].trades; }
    
    // --- Thống kê theo Market Regime ---
    double GetRegimeWinRate(bool isTransitioning) const;
    double GetRegimeProfitFactor(bool isTransitioning) const;
    int GetRegimeTrades(bool isTransitioning) const { return m_RegimeStats[isTransitioning ? 1 : 0].trades; }
    
    // --- Báo cáo hiệu suất ---
    string GeneratePerformanceReport();
    string GenerateRegimeAnalysisReport();
    bool SaveStatsToFile(string filename);
    bool LoadStatsFromFile(string filename);

    // --- Hàm mới thêm vào cho v14 ---
    double CalculateMarketRiskIndex();
    bool IsSafeMarketCondition();
    void LogRiskStatus(bool forceLog = false);
    void DrawRiskDashboard();

    //+------------------------------------------------------------------+
    //| V14.0: Thích ứng thông minh với điều kiện thị trường dài hạn     |
    //+------------------------------------------------------------------+
    bool AdaptToMarketCycle();

    //+------------------------------------------------------------------+
    //| Tính toán biến động dài hạn                                      |
    //+------------------------------------------------------------------+
    double CalculateLongTermVolatility();

    //+------------------------------------------------------------------+
    //| Tính toán tốc độ thay đổi biến động                              |
    //+------------------------------------------------------------------+
    double CalculateVolatilityChangeRate();

    // Phương thức kiểm tra và điều chỉnh rủi ro
    double GetAdjustedRiskPercent();
    bool IsDrawdownExceeded();
    bool IsDailyLossExceeded();
    void SetDetailedLogging(bool enable);
    bool IsMarketConditionSafe();

private:
    // --- Helper functions ---
    int GetCurrentDayOfYear();
    int GetCurrentDayOfWeek();
    double GetPortfolioHeatValue(double volume, bool isBuy);
    double GetCorrelationAdjustment(bool isBuy);
    double CalculateATRBasedLotSizeAdjustment(double atrRatio);
    void LogMessage(string message, bool isImportant = false);
    double NormalizeEntryLots(double calculatedLots);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(EAContext* context)
{
    m_Context = context;
    if (m_Context != NULL)
    {
        m_Logger = m_Context->Logger;
        m_AssetProfiler = m_Context->AssetProfiler;
        m_PerformanceTracker = m_Context->PerformanceTracker;
        // m_DetailedLogging sẽ được lấy từ m_Context->Logger->IsDetailedMode() hoặc tương tự
        // m_PropFirmMode sẽ được lấy từ m_Context->PropFirmMode
    }
    else
    {
        // Xử lý trường hợp context là NULL nếu cần, ví dụ: ghi log lỗi hoặc ném ngoại lệ
        // Hoặc gán giá trị mặc định an toàn cho các con trỏ
        m_Logger = NULL;
        m_AssetProfiler = NULL;
        m_PerformanceTracker = NULL;
    }

    // Giá trị mặc định (có thể được ghi đè bởi Initialize hoặc lấy từ context)
    m_Symbol = ""; // Sẽ được lấy từ context trong Initialize
    m_RiskPerTrade = 1.0; // Sẽ được lấy từ context trong Initialize
    m_MaxDailyLossPercent = 5.0; // Sẽ được lấy từ context trong Initialize
    m_MaxDrawdownPercent = 10.0; // Sẽ được lấy từ context trong Initialize
    m_MaxDailyTrades = 10; // Sẽ được lấy từ context trong Initialize
    m_MaxConsecutiveLosses = 3; // Sẽ được lấy từ context trong Initialize
    m_DrawdownReduceThreshold = 5.0; // Sẽ được lấy từ context trong Initialize
    m_MinRiskMultiplier = 0.3; // Sẽ được lấy từ context trong Initialize
    m_EnableTaperedRisk = true; // Sẽ được lấy từ context trong Initialize
    m_MaxRisk = 2.0; // Sẽ được lấy từ context trong Initialize
    m_MinRisk = 0.25; // Sẽ được lấy từ context trong Initialize
    m_DrawdownType = DRAWDOWN_EQUITY_BASED;  // Sẽ được lấy từ context trong Initialize

    m_DayStartEquity = 0;
    m_DailyTradeCount = 0;
    m_ConsecutiveLosses = 0;
    m_ConsecutiveWins = 0;
    m_PeakEquity = 0;
    m_MaxDrawdownRecorded = 0;
    m_PauseUntil = 0;
    m_LastStatsUpdate = 0;
    m_DailyLoss = 0;
    m_WeeklyLoss = 0;
    m_CurrentDay = 0;

    m_TotalTrades = 0;
    m_Wins = 0;
    m_Losses = 0;
    m_ProfitSum = 0;
    m_LossSum = 0;
    m_MaxProfitTrade = 0;
    m_MaxLossTrade = 0;
    m_MaxConsecutiveWins = 0;
    
    m_IsTransitioningMarket = false;
    m_MarketRegimeConfidence = 1.0;
    m_ATRRatio = 1.0;
    m_SpreadRatio = 1.0;
    m_CurrentRegime = REGIME_TRENDING_BULL;
    m_CurrentSession = SESSION_AMERICAN;
    m_PreferredScenario = SCENARIO_PULLBACK;   // Kịch bản giao dịch mặc định là pullback

    // Khởi tạo asset profile
    m_AssetProfile.avgATR = 0;
    m_AssetProfile.avgSpread = 0;
    m_AssetProfile.minStopDistance = 10;  // Mặc định 10 points
    m_AssetProfile.priceVolatility = 1.0;
    m_AssetProfile.bestRRRatio = 2.0;
    
    for(int i=0; i<24; i++) {
        m_AssetProfile.bestTimePerformance[i] = 0;
    }
    
    // Khởi tạo asset config
    m_AssetConfig.riskMultiplier = 1.0;
    m_AssetConfig.slAtrMultiplier = 1.5;
    m_AssetConfig.tpRrRatio = 2.0;
    m_AssetConfig.maxSpreadPoints = 20;
    m_AssetConfig.volatilityFactor = 1.0;
    m_AssetConfig.hasCriticalLevel = false;
    m_AssetConfig.criticalLevel = 0;

    // Khởi tạo các mảng thống kê
    for (int i = 0; i < 3; i++) {
        m_ClusterStats[i].trades = 0;
        m_ClusterStats[i].wins = 0;
        m_ClusterStats[i].profit = 0;
        m_ClusterStats[i].loss = 0;
    }
    
    for (int i = 0; i < 5; i++) {
        m_SessionStats[i].trades = 0;
        m_SessionStats[i].wins = 0;
        m_SessionStats[i].profit = 0;
        m_SessionStats[i].loss = 0;
        
        m_ATRStats[i].atrLevel = 0;
        m_ATRStats[i].trades = 0;
        m_ATRStats[i].wins = 0;
        m_ATRStats[i].profit = 0;
        m_ATRStats[i].loss = 0;
    }
    
    for (int i = 0; i < 2; i++) {
        m_RegimeStats[i].isTransitioning = (i == 1);
        m_RegimeStats[i].trades = 0;
        m_RegimeStats[i].wins = 0;
        m_RegimeStats[i].profit = 0;
        m_RegimeStats[i].loss = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
    // m_Logger là đối tượng nên không cần gán NULL
    // Chỉ cần giải phóng con trỏ
    m_AssetProfiler = NULL;
}

//+------------------------------------------------------------------+
//| Khởi tạo với các tham số từ EAContext                            |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize()
{
    if (m_Context == NULL)
    {
        // Không thể khởi tạo nếu không có context
        // Ghi log lỗi nếu m_Logger đã được khởi tạo (mặc dù không nên ở đây)
        // Hoặc xem xét việc ném một ngoại lệ hoặc trả về false sớm
        printf("CRiskManager::Initialize - Lỗi: EAContext là NULL.");
        return false;
    }

    // Gán các con trỏ tiện ích từ context (đã làm trong constructor, nhưng kiểm tra lại cho chắc)
    m_Logger = m_Context->Logger;
    m_AssetProfiler = m_Context->AssetProfiler;
    m_PerformanceTracker = m_Context->PerformanceTracker;

    // Lấy thông tin từ EAContext
    m_Symbol = m_Context->Symbol;
    m_RiskPerTrade = m_Context->RiskPercent;         // Ví dụ: InputRiskPercent
    m_MaxDailyLossPercent = m_Context->MaxDailyLoss;   // Ví dụ: InputMaxDailyLoss
    m_MaxDrawdownPercent = m_Context->MaxDrawdown;    // Ví dụ: InputMaxDrawdown
    m_PropFirmMode = m_Context->PropFirmMode;       // Ví dụ: InputPropFirmMode
    m_DrawdownType = m_Context->DrawdownType;       // Ví dụ: InputDrawdownType
    m_MaxDailyTrades = m_Context->MaxDailyTrades;     // Ví dụ: InputMaxDailyTrades
    m_MaxConsecutiveLosses = m_Context->MaxConsecutiveLosses; // Ví dụ: InputMaxConsecutiveLosses
    
    // Các tham số khác có thể được lấy từ m_Context nếu chúng được thêm vào EAContext
    m_DrawdownReduceThreshold = m_Context->DrawdownReduceThreshold; // Ví dụ
    m_MinRiskMultiplier = m_Context->MinRiskMultiplier;       // Ví dụ
    m_EnableTaperedRisk = m_Context->EnableTaperedRisk;       // Ví dụ
    m_MaxRisk = m_Context->MaxRiskAllowed;                // Ví dụ
    m_MinRisk = m_Context->MinRiskAllowed;                // Ví dụ

    // Thiết lập thống kê ban đầu
    // Cần đảm bảo m_AccountInfo được cập nhật trước khi gọi Equity()
    // Hoặc lấy DayStartEquity từ context nếu nó được tính ở nơi khác
    m_AccountInfo.Refresh(); // Cập nhật thông tin tài khoản
    m_DayStartEquity = m_AccountInfo.Equity(); // Hoặc m_Context->InitialBalance nếu có
    m_DailyTradeCount = 0;
    m_DailyLoss = 0;
    m_WeeklyLoss = 0;
    
    // Lưu ngày hiện tại
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    m_CurrentDay = time.day;
    
    // Khởi tạo PeakEquity ban đầu và DayStartEquity
    InitializeDayStartEquity(); // Hàm này có thể cần cập nhật để sử dụng m_Context nếu cần
    m_PeakEquity = m_AccountInfo.Equity();
    
    // Khởi tạo symbol info
    m_SymbolInfo.Name(m_Symbol);
    
    // Áp dụng cài đặt đặc biệt cho Prop Firm Mode
    if (m_PropFirmMode) {
        if (m_RiskPerTrade > m_Context->PropFirmMaxRiskPerTrade) { // Ví dụ: PropFirmMaxRiskPerTrade = 1.0
            LogMessage("PROP FIRM MODE: Giảm risk từ " + DoubleToString(m_RiskPerTrade, 2) + 
                      "% xuống " + DoubleToString(m_Context->PropFirmMaxRiskPerTrade, 2) + "% (giới hạn an toàn)", true);
            m_RiskPerTrade = m_Context->PropFirmMaxRiskPerTrade;
        }
        
        if (m_MaxDrawdownPercent > m_Context->PropFirmMaxDrawdown) { // Ví dụ: PropFirmMaxDrawdown = 5.0
            LogMessage("PROP FIRM MODE: Giảm max drawdown từ " + DoubleToString(m_MaxDrawdownPercent, 2) + 
                      "% xuống " + DoubleToString(m_Context->PropFirmMaxDrawdown, 2) + "% (giới hạn an toàn)", true);
            m_MaxDrawdownPercent = m_Context->PropFirmMaxDrawdown;
        }
        
        if (m_MaxDailyLossPercent > m_Context->PropFirmMaxDailyLoss) { // Ví dụ: PropFirmMaxDailyLoss = 3.0
            LogMessage("PROP FIRM MODE: Giảm giới hạn lỗ ngày từ " + DoubleToString(m_MaxDailyLossPercent, 2) + 
                      "% xuống " + DoubleToString(m_Context->PropFirmMaxDailyLoss, 2) + "% (giới hạn an toàn)", true);
            m_MaxDailyLossPercent = m_Context->PropFirmMaxDailyLoss;
        }
    }

    LogMessage("Risk Manager khởi tạo: Symbol=" + m_Symbol +
                    ", Risk=" + DoubleToString(m_RiskPerTrade, 2) + "%, " +
                    "Daily Loss=" + DoubleToString(m_MaxDailyLossPercent, 2) + "%, " +
                    "Max DD=" + DoubleToString(m_MaxDrawdownPercent, 2) + "%, " +
                    "Max Trades=" + IntegerToString(m_MaxDailyTrades) + ", " +
                    "Max Losses=" + IntegerToString(m_MaxConsecutiveLosses) + ", " +
                    "PropMode=" + (m_PropFirmMode ? "true" : "false") + ", " +
                    "DrawdownType=" + EnumToString(m_DrawdownType), true);
    
    // Tải thống kê trước đó nếu có
    // Cân nhắc việc có nên truyền tên file từ context hoặc xây dựng nó ở đây
    string statsFilename = "ApexPullback_" + m_Symbol + "_Stats.bin";
    if (m_Context->EnableStatsSavingLoading) { // Ví dụ: một cờ trong context
        LoadStatsFromFile(statsFilename);
    }
    
    // Tải Asset Profile nếu có
    // Tương tự, tên file hoặc logic tải có thể phụ thuộc vào context
    if (m_Context->EnableAssetProfile) { // Ví dụ
        LoadAssetProfile(m_Symbol);
    }

    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập giới hạn risk tối đa/tối thiểu                         |
//+------------------------------------------------------------------+
void CRiskManager::SetRiskLimits(double maxRisk, double minRisk)
{
    m_MaxRisk = maxRisk;
    m_MinRisk = minRisk;
    
    LogMessage("Đã thiết lập giới hạn risk: Min=" + DoubleToString(m_MinRisk, 2) + 
              "%, Max=" + DoubleToString(m_MaxRisk, 2) + "%", false);
}

//+------------------------------------------------------------------+
//| Thiết lập các tham số bảo vệ drawdown                            |
//+------------------------------------------------------------------+
void CRiskManager::SetDrawdownProtectionParams(double drawdownReduceThreshold, double minRiskMultiplier = 0.3, 
                                            bool enableTaperedRisk = true)
{
    m_DrawdownReduceThreshold = drawdownReduceThreshold;
    m_MinRiskMultiplier = minRiskMultiplier;
    m_EnableTaperedRisk = enableTaperedRisk;
    
    LogMessage("Risk Protection Settings: DD Threshold=" + DoubleToString(m_DrawdownReduceThreshold, 2) + 
              "%, Min Risk Multiplier=" + DoubleToString(m_MinRiskMultiplier, 2) + 
              ", Tapered Risk=" + (m_EnableTaperedRisk ? "Enabled" : "Disabled"), false);
}

//+------------------------------------------------------------------+
//| Thiết lập thông tin market regime                                |
//+------------------------------------------------------------------+
void CRiskManager::SetMarketRegimeInfo(ENUM_MARKET_REGIME regime, bool isTransitioning, 
                                     double regimeConfidence, double atrRatio, ENUM_SESSION session)
{
    m_CurrentRegime = regime;
    m_IsTransitioningMarket = isTransitioning;
    m_MarketRegimeConfidence = regimeConfidence; 
    m_ATRRatio = atrRatio;
    m_CurrentSession = session;
    
    // Log chi tiết trạng thái thị trường
    // Quy tắc #1: Sử dụng -> cho g_EAContext
    // Quy tắc #3: Truy cập Logger qua g_EAContext
    if (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL) {
        string regimeStr;
        switch(regime) {
            case REGIME_TRENDING_BULL: regimeStr = "TRENDING_BULL"; break;
            case REGIME_TRENDING_BEAR: regimeStr = "TRENDING_BEAR"; break;
            case REGIME_RANGING_STABLE: regimeStr = "RANGING_STABLE"; break;
            case REGIME_RANGING_VOLATILE: regimeStr = "RANGING_VOLATILE"; break;
            case REGIME_VOLATILE_EXPANSION: regimeStr = "VOLATILE_EXPANSION"; break;
            case REGIME_VOLATILE_CONTRACTION: regimeStr = "VOLATILE_CONTRACTION"; break;
            default: regimeStr = "UNKNOWN";
        }
        
        string sessionStr;
        switch(session) {
            case SESSION_ASIAN: sessionStr = "ASIAN"; break;
            case SESSION_EUROPEAN: sessionStr = "EUROPEAN"; break;
            case SESSION_AMERICAN: sessionStr = "AMERICAN"; break;
            case SESSION_EUROPEAN_AMERICAN: sessionStr = "EU-US OVERLAP"; break;
            case SESSION_CLOSING: sessionStr = "CLOSING"; break;
            default: sessionStr = "UNKNOWN";
        }
        
        // Sử dụng LogMessage của class, vốn đã truy cập m_Logger (đã được gán từ g_EAContext->Logger)
        LogMessage(StringFormat("Market Info: Regime=%s, Transitioning=%s, Confidence=%.2f, ATR=%.2fx, Session=%s",
                             regimeStr, isTransitioning ? "Yes" : "No", regimeConfidence, atrRatio, sessionStr));
    }
}

//+------------------------------------------------------------------+
//| V14.0: Tải Asset Profile từ file                                 |
//+------------------------------------------------------------------+
bool CRiskManager::LoadAssetProfile(string symbol = "")
{
    if (symbol == "") symbol = m_Symbol;
    
    string filename = "AssetProfile_" + symbol + ".bin";
    
    // Nếu có AssetProfiler và đã được khởi tạo, ưu tiên sử dụng
    if (m_AssetProfiler != NULL) {
        // Lấy thông tin cho m_AssetProfile
        // Sử dụng phương thức và trường đã định nghĩa
        
        // Khởi tạo giá trị ATR
        m_AssetProfile.avgATR = 0.001; // Giá trị mặc định cho ATR
        
        // Lấy giá trị spread từ symbol
        double spread = 0.0;
        long spread_points = SymbolInfoInteger(symbol, SYMBOL_SPREAD);
        m_AssetProfile.avgSpread = (double)spread_points;
        
        // Lấy khoảng cách stop level từ symbol
        long stop_level = SymbolInfoInteger(symbol, SYMBOL_TRADE_STOPS_LEVEL);
        m_AssetProfile.minStopDistance = (double)stop_level;
        
        // Cập nhật dữ liệu cho cấu hình tài sản
        {
            // Thiết lập các cấu hình tối ưu cho tài sản dựa trên các giá trị mặc định
            m_AssetConfig.slAtrMultiplier = 1.5; // Hệ số ATR mặc định cho SL
            m_AssetConfig.tpRrRatio = 2.0;       // Tỷ lệ R:R mặc định
            m_AssetConfig.maxSpreadPoints = 20;  // Giới hạn spread mặc định
            m_AssetConfig.volatilityFactor = 1.0; // Hệ số biến động mặc định
            
            // Sử dụng m_Logger nếu có
            if (m_Logger != NULL) m_Logger->LogInfo("Đã tải Asset Profile từ AssetProfiler: " + symbol + 
                      ", ATR=" + DoubleToString(m_AssetProfile.avgATR, _Digits) + 
                      ", Spread=" + DoubleToString(m_AssetProfile.avgSpread, 1) + " pts");
            else Print("Đã tải Asset Profile từ AssetProfiler: " + symbol + 
                      ", ATR=" + DoubleToString(m_AssetProfile.avgATR, _Digits) + 
                      ", Spread=" + DoubleToString(m_AssetProfile.avgSpread, 1) + " pts");
            return true;
        }
        return false;
    }
    
    // Nếu không có AssetProfiler, load từ file
    if (FileIsExist(filename, FILE_COMMON)) {
        int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
        if (fileHandle != INVALID_HANDLE) {
            // Đọc dữ liệu asset profile
            m_AssetProfile.avgATR = FileReadDouble(fileHandle);
            m_AssetProfile.avgSpread = FileReadDouble(fileHandle);
            m_AssetProfile.minStopDistance = FileReadDouble(fileHandle);
            m_AssetProfile.priceVolatility = FileReadDouble(fileHandle);
            m_AssetProfile.bestRRRatio = FileReadDouble(fileHandle);
            
            // Đọc bestTimePerformance
            for(int i=0; i<24; i++) {
                m_AssetProfile.bestTimePerformance[i] = FileReadDouble(fileHandle);
            }
            
            // Đọc AssetConfig
            m_AssetConfig.riskMultiplier = FileReadDouble(fileHandle);
            m_AssetConfig.slAtrMultiplier = FileReadDouble(fileHandle);
            m_AssetConfig.tpRrRatio = FileReadDouble(fileHandle);
            m_AssetConfig.maxSpreadPoints = FileReadDouble(fileHandle);
            m_AssetConfig.volatilityFactor = FileReadDouble(fileHandle);
            m_AssetConfig.hasCriticalLevel = FileReadBool(fileHandle);
            m_AssetConfig.criticalLevel = FileReadDouble(fileHandle);
            
            FileClose(fileHandle);
            
            // Sử dụng m_Logger nếu có
            if (m_Logger != NULL) m_Logger->LogInfo("Đã tải Asset Profile từ file: " + filename);
            else Print("Đã tải Asset Profile từ file: " + filename);
            return true;
        }
    }
    
    // Nếu không có sẵn, thiết lập giá trị mặc định cho từng loại tài sản
    if (StringSubstr(symbol, 0, 6) == "XAUUSD" || StringSubstr(symbol, 0, 4) == "GOLD") {
        // Gold có đặc tính khác biệt
        m_AssetProfile.avgATR = 200;  // ~2 USD trên Gold
        m_AssetProfile.avgSpread = 35; // 35 điểm trung bình
        m_AssetProfile.minStopDistance = 100; // 1 USD tối thiểu
        m_AssetProfile.priceVolatility = 1.2;
        m_AssetProfile.bestRRRatio = 1.5;
        
        m_AssetConfig.riskMultiplier = 0.8;  // Risk thấp hơn 
        m_AssetConfig.slAtrMultiplier = 1.0; // SL nhỏ hơn
        m_AssetConfig.tpRrRatio = 1.5;       // R:R thấp hơn
        m_AssetConfig.maxSpreadPoints = 50;  // Spread tối đa cao hơn
        m_AssetConfig.volatilityFactor = 1.2;
    }
    else if (StringSubstr(symbol, 0, 6) == "BTCUSD" || StringSubstr(symbol, 0, 3) == "BTC") {
        // Bitcoin
        m_AssetProfile.avgATR = 500;  // Bitcoin volatile
        m_AssetProfile.avgSpread = 100; // Spread rộng
        m_AssetProfile.minStopDistance = 300;
        m_AssetProfile.priceVolatility = 1.8;
        m_AssetProfile.bestRRRatio = 2.0;
        
        m_AssetConfig.riskMultiplier = 0.6;  // Risk thấp hơn nhiều
        m_AssetConfig.slAtrMultiplier = 1.5; // SL lớn hơn
        m_AssetConfig.tpRrRatio = 2.0;
        m_AssetConfig.maxSpreadPoints = 200;
        m_AssetConfig.volatilityFactor = 1.8;
    }
    else if (StringLen(symbol) >= 6) {
        // Forex major
        if (StringSubstr(symbol, 0, 3) == "EUR" || StringSubstr(symbol, 0, 3) == "USD" || 
            StringSubstr(symbol, 0, 3) == "GBP" || StringSubstr(symbol, 0, 3) == "JPY" || 
            StringSubstr(symbol, 3, 3) == "EUR" || StringSubstr(symbol, 3, 3) == "USD" || 
            StringSubstr(symbol, 3, 3) == "GBP" || StringSubstr(symbol, 3, 3) == "JPY") {
            // Major pairs
            m_AssetProfile.avgATR = 80;  // ~8 pips
            m_AssetProfile.avgSpread = 10; // ~1 pip
            m_AssetProfile.minStopDistance = 50;
            m_AssetProfile.priceVolatility = 1.0;
            m_AssetProfile.bestRRRatio = 2.0;
            
            m_AssetConfig.riskMultiplier = 1.0;
            m_AssetConfig.slAtrMultiplier = 1.5;
            m_AssetConfig.tpRrRatio = 2.0;
            m_AssetConfig.maxSpreadPoints = 20;
            m_AssetConfig.volatilityFactor = 1.0;
        } 
        else {
            // Minor/exotic pairs
            m_AssetProfile.avgATR = 120;  // ~12 pips
            m_AssetProfile.avgSpread = 25; // ~2.5 pips
            m_AssetProfile.minStopDistance = 80;
            m_AssetProfile.priceVolatility = 1.2;
            m_AssetProfile.bestRRRatio = 2.0;
            
            m_AssetConfig.riskMultiplier = 0.8;
            m_AssetConfig.slAtrMultiplier = 2.0;
            m_AssetConfig.tpRrRatio = 2.0;
            m_AssetConfig.maxSpreadPoints = 35;
            m_AssetConfig.volatilityFactor = 1.2;
        }
    }
    else {
        // Mặc định cho các trường hợp khác
        m_AssetProfile.avgATR = 100;
        m_AssetProfile.avgSpread = 20;
        m_AssetProfile.minStopDistance = 50;
        m_AssetProfile.priceVolatility = 1.0;
        m_AssetProfile.bestRRRatio = 2.0;
        
        m_AssetConfig.riskMultiplier = 1.0;
        m_AssetConfig.slAtrMultiplier = 1.5;
        m_AssetConfig.tpRrRatio = 2.0;
        m_AssetConfig.maxSpreadPoints = 30;
        m_AssetConfig.volatilityFactor = 1.0;
    }
    
    // Sử dụng m_Logger nếu có
    if (m_Logger != NULL) m_Logger->LogInfo("Thiết lập Asset Profile mặc định cho: " + symbol);
    else Print("Thiết lập Asset Profile mặc định cho: " + symbol);
    return false;
}

//+------------------------------------------------------------------+
//| V14.0: Lưu Asset Profile                                         |
//+------------------------------------------------------------------+
bool CRiskManager::SaveAssetProfile(string symbol = "")
{
    if (symbol == "") symbol = m_Symbol;
    
    string filename = "AssetProfile_" + symbol + ".bin";
    
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
    if (fileHandle != INVALID_HANDLE) {
        // Ghi dữ liệu asset profile
        FileWriteDouble(fileHandle, m_AssetProfile.avgATR);
        FileWriteDouble(fileHandle, m_AssetProfile.avgSpread);
        FileWriteDouble(fileHandle, m_AssetProfile.minStopDistance);
        FileWriteDouble(fileHandle, m_AssetProfile.priceVolatility);
        FileWriteDouble(fileHandle, m_AssetProfile.bestRRRatio);
        
        // Ghi bestTimePerformance
        for(int i=0; i<24; i++) {
            FileWriteDouble(fileHandle, m_AssetProfile.bestTimePerformance[i]);
        }
        
        // Ghi AssetConfig
        FileWriteDouble(fileHandle, m_AssetConfig.riskMultiplier);
        FileWriteDouble(fileHandle, m_AssetConfig.slAtrMultiplier);
        FileWriteDouble(fileHandle, m_AssetConfig.tpRrRatio);
        FileWriteDouble(fileHandle, m_AssetConfig.maxSpreadPoints);
        FileWriteDouble(fileHandle, m_AssetConfig.volatilityFactor);
        FileWriteInteger(fileHandle, m_AssetConfig.hasCriticalLevel ? 1 : 0);
        FileWriteDouble(fileHandle, m_AssetConfig.criticalLevel);
        
        FileClose(fileHandle);
        
        // Sử dụng m_Logger nếu có
        if (m_Logger != NULL) m_Logger->LogInfo("Đã lưu Asset Profile vào file: " + filename);
        else Print("Đã lưu Asset Profile vào file: " + filename);
        return true;
    }
    
    // Sử dụng m_Logger nếu có
    if (m_Logger != NULL) m_Logger->LogError("Không thể mở file để lưu Asset Profile: " + filename);
    else Print("LỖI: Không thể mở file để lưu Asset Profile: " + filename);
    return false;
}

//+------------------------------------------------------------------+
//| V14.0: Cập nhật Asset Profile với dữ liệu hiện tại               |
//+------------------------------------------------------------------+
void CRiskManager::UpdateAssetProfile(double currentATR, double currentSpread)
{
    // Cập nhật kết hợp với dữ liệu cũ (trung bình động)
    if (m_AssetProfile.avgATR > 0) {
        // Trọng số: 95% dữ liệu cũ + 5% dữ liệu mới
        m_AssetProfile.avgATR = 0.95 * m_AssetProfile.avgATR + 0.05 * currentATR;
    } else {
        m_AssetProfile.avgATR = currentATR;
    }
    
    if (m_AssetProfile.avgSpread > 0) {
        m_AssetProfile.avgSpread = 0.95 * m_AssetProfile.avgSpread + 0.05 * currentSpread;
    } else {
        m_AssetProfile.avgSpread = currentSpread;
    }
    
    // Cập nhật SpreadRatio
    if (m_AssetProfile.avgSpread > 0) {
        m_SpreadRatio = currentSpread / m_AssetProfile.avgSpread;
    } else {
        m_SpreadRatio = 1.0;
    }
    
    // Nếu có AssetProfiler, cập nhật dữ liệu nếu có phương thức phù hợp
    if (m_AssetProfiler != NULL) {
        // Cập nhật dữ liệu với AssetProfiler
        // Lưu ý: CAssetProfiler không có phương thức UpdateStats
        // Cập nhật dữ liệu thị trường nội bộ
        m_ATRRatio = currentATR / m_AssetProfile.avgATR;
        m_SpreadRatio = currentSpread / m_AssetProfile.avgSpread;
        
        // Cập nhật thời gian làm mới
        m_LastStatsUpdate = TimeCurrent();
    }
    
    // Lưu lại sau mỗi phiên giao dịch hoặc khi kết thúc ngày
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    static int lastSaveHour = -1;
    if (time.hour != lastSaveHour && (time.hour == 0 || time.hour == 8 || time.hour == 16)) {
        SaveAssetProfile();
        lastSaveHour = time.hour;
    }
}

//+------------------------------------------------------------------+
//| V14.0: Thiết lập cấu hình tài sản                                |
//+------------------------------------------------------------------+
void CRiskManager::SetAssetConfig(double riskMultiplier, double slAtrMultiplier, double tpRrRatio, 
                                double maxSpreadPoints, double volatilityFactor = 1.0)
{
    m_AssetConfig.riskMultiplier = riskMultiplier;
    m_AssetConfig.slAtrMultiplier = slAtrMultiplier;
    m_AssetConfig.tpRrRatio = tpRrRatio;
    m_AssetConfig.maxSpreadPoints = maxSpreadPoints;
    m_AssetConfig.volatilityFactor = volatilityFactor;
    
    // Sử dụng m_Logger nếu có
    string msg = StringFormat("Đã thiết lập cấu hình tài sản: Risk=%.2f, SL ATR=%.2f, TP RR=%.2f, MaxSpread=%.1f, Volatility=%.2f",
                         riskMultiplier, slAtrMultiplier, tpRrRatio, maxSpreadPoints, volatilityFactor);
    if (m_Logger != NULL) m_Logger->LogInfo(msg);
    else Print(msg);
}

//+------------------------------------------------------------------+
//| Lấy ngày trong năm hiện tại để theo dõi giới hạn hàng ngày       |
//+------------------------------------------------------------------+
int CRiskManager::GetCurrentDayOfYear()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    return time.day_of_year;
}

//+------------------------------------------------------------------+
//| Lấy ngày trong tuần hiện tại (1=CN, 2=Thứ 2..., 7=Thứ 7)         |
//+------------------------------------------------------------------+
int CRiskManager::GetCurrentDayOfWeek()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    return time.day_of_week + 1;  // MQL5: 0=CN, 1=Thứ 2...
}

//+------------------------------------------------------------------+
//| Cập nhật biến hàng ngày                                          |
//| Gọi từ EA mỗi OnTick() để cập nhật khi ngày mới                  |
//+------------------------------------------------------------------+
void CRiskManager::UpdateDailyVars()
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    // Kiểm tra nếu ngày mới
    if (time.day != m_CurrentDay) {
        // Reset các biến hàng ngày
        m_DayStartEquity = m_AccountInfo.Equity();
        m_DailyTradeCount = 0;
        m_DailyLoss = 0;
        m_CurrentDay = time.day;
        
        // Reset weekly vars vào Thứ 2
        if (time.day_of_week == 1) { // 1 = Thứ 2 trong MQL5
            m_WeeklyLoss = 0;
        }
        
        // Sử dụng m_Logger nếu có
        string msg = "Cập nhật biến hàng ngày, Start equity: " + DoubleToString(m_DayStartEquity, 2);
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
    }
}

//+------------------------------------------------------------------+
//| Reset thống kê giao dịch hàng ngày                               |
//| Nên được gọi bởi EA chính vào đầu ngày mới.                      |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyStats(double newStartEquity = 0.0)
{
    m_DailyTradeCount = 0;
    m_DailyLoss = 0;
    
    // Khởi tạo m_DayStartEquity dựa trên loại drawdown
    if (m_DrawdownType == DRAWDOWN_BALANCE_BASED) {
        m_DayStartEquity = (newStartEquity > 0) ? newStartEquity : m_AccountInfo.Balance();
    } else {
        m_DayStartEquity = (newStartEquity > 0) ? newStartEquity : m_AccountInfo.Equity();
    }
    
    // Cập nhật PeakEquity nếu tài khoản đang tăng
    if (m_DayStartEquity > m_PeakEquity) {
        m_PeakEquity = m_DayStartEquity;
    }
    
    // Sử dụng m_Logger nếu có
    string msg = "Thống kê hàng ngày đã reset. Start Equity: " + DoubleToString(m_DayStartEquity, 2) + 
               ", Drawdown Type: " + (m_DrawdownType == DRAWDOWN_BALANCE_BASED ? "Balance Based" : "Equity Based");
    if (m_Logger != NULL) m_Logger->LogInfo(msg);
    else Print(msg);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có thể mở vị thế mới không                          |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenNewPosition(double volume, bool isBuy)
{
    // 1. Kiểm tra xem có đang tạm dừng không
    if (TimeCurrent() < m_PauseUntil) {
        string msg = "Không thể mở vị thế mới: EA đang tạm dừng đến " + TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES);
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }

    // 2. Kiểm tra giới hạn lỗ
    if (IsMaxLossReached()) {
        string msg = "Không thể mở vị thế mới: Đã đạt giới hạn lỗ tối đa";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 3. Kiểm tra giới hạn giao dịch hàng ngày
    if (m_PropFirmMode && m_DailyTradeCount >= m_MaxDailyTrades) {
        string msg = "Không thể mở vị thế mới: Đã đạt số lượng giao dịch tối đa trong ngày (" + IntegerToString(m_MaxDailyTrades) + ")";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 4. Kiểm tra số lần thua liên tiếp
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        string msg = "Không thể mở vị thế mới: Đã đạt số lần thua liên tiếp tối đa (" + IntegerToString(m_MaxConsecutiveLosses) + ")";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 5. Kiểm tra margin
    if (!m_AccountInfo.FreeMarginCheck(m_Symbol, isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, 
                                     m_SymbolInfo.Ask())) {
        string msg = "Không thể mở vị thế mới: Không đủ margin tự do";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return false;
    }
    
    // 6. Kiểm tra thị trường đang chuyển tiếp với mức tin cậy thấp
    if (m_IsTransitioningMarket && m_MarketRegimeConfidence < 0.4) {
        string msg = "Không thể mở vị thế mới: Thị trường đang chuyển tiếp với mức tin cậy thấp (" + DoubleToString(m_MarketRegimeConfidence, 2) + ")";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 7. Kiểm tra biến động quá cao 
    double volatilityThreshold = 2.5 - 1.0 * m_MarketRegimeConfidence; // Phụ thuộc vào confidence
    if (m_ATRRatio > volatilityThreshold) {
        string msg = "Không thể mở vị thế mới: Biến động quá cao (ATR Ratio: " + DoubleToString(m_ATRRatio, 2) + "x > " + DoubleToString(volatilityThreshold, 2) + "x)";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 8. Kiểm tra spread bất thường
    if (!IsSpreadAcceptable()) {
        // Thông báo đã được xử lý trong hàm IsSpreadAcceptable
        return false;
    }
    
    // 9. Kiểm tra heat portfolio
    double heatValue = GetPortfolioHeatValue(volume, isBuy);
    if (heatValue > 2.5) {  // Ngưỡng heat quá cao
        string msg = "Không thể mở vị thế mới: Portfolio heat quá cao (" + DoubleToString(heatValue, 2) + ")";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 10. Kiểm tra tiếp cận giới hạn lỗ hàng ngày
    if (IsApproachingDailyLossLimit()) {
        string msg = "Không thể mở vị thế mới: Đang tiếp cận giới hạn lỗ hàng ngày (" + DoubleToString(m_DailyLoss, 2) + " / " + DoubleToString(m_DayStartEquity * m_MaxDailyLossPercent / 100.0, 2) + ")";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 11. V14: Kiểm tra điều kiện thị trường tổng hợp
    if (!IsMarketSuitableForTrading()) {
        // Thông báo chi tiết đã được xử lý trong hàm IsMarketSuitableForTrading
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có thể thêm vào vị thế hiện tại không               |
//+------------------------------------------------------------------+
bool CRiskManager::CanScalePosition(double additionalVolume, bool isLong)
{
    // 1. Kiểm tra giới hạn lỗ
    if (IsMaxLossReached()) {
        string msg = "Không thể thêm vào vị thế: Đã đạt giới hạn lỗ tối đa";
        if (m_Logger != NULL) m_Logger->LogWarning(msg);
        else Print("CẢNH BÁO: " + msg);
        return false;
    }
    
    // 2. Kiểm tra margin
    if (!m_AccountInfo.FreeMarginCheck(m_Symbol, isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, 
                                     additionalVolume, m_SymbolInfo.Ask())) {
        string msg = "Không thể thêm vào vị thế: Không đủ margin tự do";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return false;
    }
    
    // 3. Kiểm tra drawdown hiện tại
    double currentDD = GetCurrentDrawdownPercent();
    if (currentDD > m_DrawdownReduceThreshold) {
        string msg = "Không thể thêm vào vị thế: Drawdown hiện tại (" + DoubleToString(currentDD, 2) + "%) vượt quá ngưỡng (" + DoubleToString(m_DrawdownReduceThreshold, 2) + "%)";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 4. Kiểm tra thị trường đang chuyển tiếp
    if (m_IsTransitioningMarket) {
        string msg = "Không thể thêm vào vị thế: Thị trường đang trong giai đoạn chuyển tiếp";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 5. Kiểm tra spread
    if (!IsSpreadAcceptable()) {
        return false;
    }
    
    // 6. Kiểm tra tiếp cận giới hạn lỗ ngày
    if (IsApproachingDailyLossLimit()) {
        string msg = "Không thể thêm vào vị thế: Đang tiếp cận giới hạn lỗ hàng ngày";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 7. Kiểm tra số lần thua liên tiếp
    if (m_ConsecutiveLosses > 1) {
        string msg = "Không thể thêm vào vị thế: Đang có chuỗi thua (" + IntegerToString(m_ConsecutiveLosses) + " lần)";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    // 8. V14: Kiểm tra biến động thị trường
    if (m_ATRRatio > 1.5) {
        string msg = "Không thể thêm vào vị thế: Biến động thị trường cao (" + DoubleToString(m_ATRRatio, 2) + "x)";
        if (m_Logger != NULL) m_Logger->LogInfo(msg);
        else Print(msg);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Đăng ký vị thế mới                                               |
//+------------------------------------------------------------------+
void CRiskManager::RegisterNewPosition(ulong ticket, double volume, double riskPercent)
{
    m_DailyTradeCount++;
    
    string msg = "Đã đăng ký vị thế mới #" + IntegerToString(ticket) + ", Volume: " + DoubleToString(volume, 2) + ", Risk: " + DoubleToString(riskPercent, 2) + "%";
    if (m_Logger != NULL) m_Logger->LogInfo(msg);
    else Print(msg);
    
    // Lưu trạng thái thống kê mỗi khi có lệnh mới (để tiện theo dõi)
    m_LastStatsUpdate = TimeCurrent();
    LogRiskStatus(true);
}

//+------------------------------------------------------------------+
//| Cập nhật vị thế một phần                                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdatePositionPartial(ulong ticket, double partialVolume)
{
    string msg = "Đã đóng một phần vị thế #" + IntegerToString(ticket) + ", Volume đóng: " + DoubleToString(partialVolume, 2);
    if (m_Logger != NULL) m_Logger->LogInfo(msg);
    else Print(msg);
}

//+------------------------------------------------------------------+
//| Cập nhật thống kê khi đóng giao dịch                             |
//+------------------------------------------------------------------+
void CRiskManager::UpdateStatsOnDealClose(bool isWin, double profit, int clusterType = 0, int sessionType = 0, double atrRatio = 1.0)
{
    m_TotalTrades++;
    
    // Cập nhật thống kê lợi nhuận/lỗ hàng ngày
    if (profit < 0) {
        m_DailyLoss += MathAbs(profit);
        m_WeeklyLoss += MathAbs(profit);
    }
    
    if (isWin) {
        m_Wins++;
        m_ProfitSum += profit;
        m_ConsecutiveWins++;
        m_ConsecutiveLosses = 0;  // Reset số lần thua liên tiếp
        
        if (m_ConsecutiveWins > m_MaxConsecutiveWins) {
            m_MaxConsecutiveWins = m_ConsecutiveWins;
        }
        
        if (profit > m_MaxProfitTrade) {
            m_MaxProfitTrade = profit;
        }
    } else {
        m_Losses++;
        m_LossSum += MathAbs(profit);
        m_ConsecutiveLosses++;
        m_ConsecutiveWins = 0;  // Reset số lần thắng liên tiếp
        
        if (m_ConsecutiveLosses > m_MaxConsecutiveLosses) {
            m_MaxConsecutiveLosses = m_ConsecutiveLosses;
        }
        
        if (MathAbs(profit) > m_MaxLossTrade) {
            m_MaxLossTrade = MathAbs(profit);
        }
    }
    
    // Cập nhật thống kê theo cluster
    if (clusterType >= 0 && clusterType < 3) {
        m_ClusterStats[clusterType].trades++;
        if (isWin) {
            m_ClusterStats[clusterType].wins++;
            m_ClusterStats[clusterType].profit += profit;
        } else {
            m_ClusterStats[clusterType].loss += MathAbs(profit);
        }
    }
    
    // Cập nhật thống kê theo phiên
    if (sessionType >= 0 && sessionType < 5) {
        m_SessionStats[sessionType].trades++;
        if (isWin) {
            m_SessionStats[sessionType].wins++;
            m_SessionStats[sessionType].profit += profit;
        } else {
            m_SessionStats[sessionType].loss += MathAbs(profit);
        }
    }
    
    // Cập nhật thống kê ATR
    int atrIndex = 0;
    if (atrRatio < 0.8) atrIndex = 0;      // ATR thấp
    else if (atrRatio < 1.0) atrIndex = 1; // ATR dưới trung bình
    else if (atrRatio < 1.2) atrIndex = 2; // ATR trung bình
    else if (atrRatio < 1.5) atrIndex = 3; // ATR cao
    else atrIndex = 4;                     // ATR rất cao
    
    if (atrIndex >= 0 && atrIndex < 5) {
        m_ATRStats[atrIndex].atrLevel = atrRatio;
        m_ATRStats[atrIndex].trades++;
        if (isWin) {
            m_ATRStats[atrIndex].wins++;
            m_ATRStats[atrIndex].profit += profit;
        } else {
            m_ATRStats[atrIndex].loss += MathAbs(profit);
        }
    }
    
    // Cập nhật thống kê theo regime
    int regimeIndex = m_IsTransitioningMarket ? 1 : 0;
    m_RegimeStats[regimeIndex].trades++;
    if (isWin) {
        m_RegimeStats[regimeIndex].wins++;
        m_RegimeStats[regimeIndex].profit += profit;
    } else {
        m_RegimeStats[regimeIndex].loss += MathAbs(profit);
    }
    
    // Log nếu là giao dịch đáng chú ý
    if (isWin && profit > 50.0) {
        LogMessage(StringFormat("Giao dịch thắng lớn: $%.2f, Cluster=%d, Session=%d, ATR=%.2f, Regime=%s", 
                             profit, clusterType, sessionType, atrRatio, 
                             m_IsTransitioningMarket ? "Transitioning" : "Stable"), true);
    }
    
    if (!isWin && MathAbs(profit) > 30.0) {
        LogMessage(StringFormat("Giao dịch thua lớn: $%.2f, Cluster=%d, Session=%d, ATR=%.2f, Regime=%s", 
                             MathAbs(profit), clusterType, sessionType, atrRatio,
                             m_IsTransitioningMarket ? "Transitioning" : "Stable"), true);
    }
    
    // Cập nhật Drawdown và kiểm tra điều kiện tạm dừng
    UpdateMaxDrawdown();
    
    // Kiểm tra cơ chế tạm dừng
    UpdatePauseStatus();
    
    // Lưu thống kê định kỳ
    if (m_TotalTrades % 10 == 0) {
        SaveStatsToFile("ApexPullback_" + m_Symbol + "_Stats.bin");
    }
    
    // Cập nhật thời gian cập nhật thống kê
    m_LastStatsUpdate = TimeCurrent();
    LogRiskStatus();
}

//+------------------------------------------------------------------+
//| Tính toán vị thế mới - phiên bản cơ bản                          |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                   double qualityFactor = 1.0, double riskPercent = 0.0)
{
    // Nếu không cung cấp riskPercent, sử dụng giá trị mặc định
    if (riskPercent <= 0) riskPercent = m_RiskPerTrade;
    
    // Áp dụng risk thích ứng dựa trên drawdown, regime và session
    riskPercent = CalculateAdaptiveRiskPercent();
    
    // Điều chỉnh risk dựa trên qualityFactor (0.1-1.0)
    qualityFactor = MathMax(0.1, MathMin(qualityFactor, 1.0));
    riskPercent = riskPercent * qualityFactor;
    
    // Áp dụng hệ số risk theo tài sản
    riskPercent *= m_AssetConfig.riskMultiplier;
    
    // Giới hạn rủi ro tối đa
    riskPercent = MathMin(riskPercent, m_MaxRisk);
    
    // Tính lot size
    if (stopLossPoints <= 0) {
        LogMessage("LỖI: Không thể tính lot size với stop loss points = " + 
                 DoubleToString(stopLossPoints, 2), true);
        return 0.01; // Trả về giá trị nhỏ để tránh lỗi
    }
    
    // Lấy thông tin symbol
    if (symbol == "") symbol = m_Symbol;
    
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    
    // Tính số tiền rủi ro
    double accountBalance = m_AccountInfo.Balance();
    double riskAmount = accountBalance * riskPercent / 100.0;
    
    // Tính risk trên mỗi pip/point
    double valuePerPoint = tickValue / tickSize * point;
    
    // Tính lot size dựa trên risk và stop loss
    double lotSize = riskAmount / (stopLossPoints * valuePerPoint);
    
    // Chuẩn hóa lot size 
    lotSize = NormalizeEntryLots(lotSize);
    
    // Giảm lot size trong chế độ prop firm nếu > 0.5
    if (m_PropFirmMode && lotSize > 0.5) {
        double adjustedLot = MathMin(lotSize, 0.5);
        LogMessage("PROP FIRM MODE: Giảm lot size từ " + DoubleToString(lotSize, 2) + " xuống " + 
                  DoubleToString(adjustedLot, 2) + " (an toàn)", false);
        lotSize = adjustedLot;
    }
    
    // Log thông tin tính toán
    string msg_calc = "Risk calculation: Balance=$" + DoubleToString(accountBalance, 2) + ", Risk=" + DoubleToString(riskPercent, 2) + "%, SL=" + DoubleToString(stopLossPoints, 1) + " points, Lot=" + DoubleToString(lotSize, 2);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_calc);
    else Print(msg_calc);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Tính toán vị thế mới - phiên bản thích ứng theo ATR              |
//+------------------------------------------------------------------+
double CRiskManager::CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                          double atrRatio, double maxVolatilityFactor, 
                                          double minLotMultiplier, double qualityFactor = 1.0)
{
    // Tính lot size cơ bản
    double baseLotSize = CalculateLotSize(symbol, stopLossPoints, entryPrice, qualityFactor);
    
    // Điều chỉnh dựa trên tỷ lệ ATR
    double adjustment = CalculateATRBasedLotSizeAdjustment(atrRatio);
    
    // Áp dụng giới hạn
    if (adjustment < minLotMultiplier) adjustment = minLotMultiplier;
    if (atrRatio > maxVolatilityFactor) {
        adjustment = minLotMultiplier;
    }
    
    // Áp dụng điều chỉnh
    double dynamicLotSize = baseLotSize * adjustment;
    
    // Chuẩn hóa lot size
    dynamicLotSize = NormalizeEntryLots(dynamicLotSize);
    
    // Log thông tin
    string msg_dyn_calc = "Dynamic lot calculation: Base=" + DoubleToString(baseLotSize, 2) + ", ATR ratio=" + DoubleToString(atrRatio, 2) + "x, Adjustment=" + DoubleToString(adjustment, 2) + ", Final lot=" + DoubleToString(dynamicLotSize, 2);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_dyn_calc);
    else Print(msg_dyn_calc);
    
    return dynamicLotSize;
}

//+------------------------------------------------------------------+
//| V14.0: Tính toán lot size tối ưu                                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateOptimalLotSize(double riskPercentInput, double slDistancePoints)
{
    if (slDistancePoints <= 0) 
    {
        string msg = "CalculateOptimalLotSize: Invalid slDistancePoints <= 0. Returning 0.01.";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0.01; // Giá trị an toàn mặc định
    }
    
    double riskPercent = (riskPercentInput > 0) ? riskPercentInput : m_RiskPerTrade; // Sử dụng riskPercent từ input nếu có, nếu không thì dùng m_RiskPerTrade

    // Lấy risk multiplier từ CurrentAssetProfile (thông qua m_AssetConfig)
    double assetRiskMultiplier = m_AssetConfig.riskMultiplier; 
    riskPercent *= assetRiskMultiplier;
    string msg1 = StringFormat("CalculateOptimalLotSize: Initial risk=%.2f%%, AssetRiskMultiplier=%.2f, Risk after asset multiplier=%.2f%%", 
                         (riskPercentInput > 0) ? riskPercentInput : m_RiskPerTrade, assetRiskMultiplier, riskPercent);
    if (m_Logger != NULL) m_Logger->LogInfo(msg1);
    else Print(msg1);

    // Áp dụng risk thích ứng (có thể đã bao gồm các yếu tố từ AssetProfile)
    riskPercent = CalculateAdaptiveRiskPercent(riskPercent); // Truyền risk đã nhân với asset multiplier
    string msg2 = StringFormat("CalculateOptimalLotSize: Risk after adaptive adjustment=%.2f%%", riskPercent);
    if (m_Logger != NULL) m_Logger->LogInfo(msg2);
    else Print(msg2);
        
    // Kiểm tra giới hạn risk tổng thể của EA
    riskPercent = MathMin(riskPercent, m_MaxRisk); // Giới hạn trên
    riskPercent = MathMax(riskPercent, m_MinRisk); // Giới hạn dưới
    string msg3 = StringFormat("CalculateOptimalLotSize: Risk after EA limits (Min:%.2f%%, Max:%.2f%%) = %.2f%%", m_MinRisk, m_MaxRisk, riskPercent);
    if (m_Logger != NULL) m_Logger->LogInfo(msg3);
    else Print(msg3);
    
    // Tính lệnh thực tế
    double accountBalance = m_AccountInfo.Balance();
    if (accountBalance <= 0)
    {
        string msg = "CalculateOptimalLotSize: Invalid accountBalance <= 0. Returning 0.01.";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0.01;
    }
    double riskAmount = accountBalance * riskPercent / 100.0;
    
    double tickSize = SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_TICK_VALUE);
    double point = SymbolInfoDouble(m_Symbol, SYMBOL_POINT);

    if (tickSize == 0 || point == 0) // tickValue có thể là 0 cho một số symbol đặc biệt, nhưng tickSize và point không nên
    {
        string msg = StringFormat("CalculateOptimalLotSize: Invalid symbol info for %s. TickSize=%.5f, Point=%.5f. Returning 0.01.", m_Symbol, tickSize, point);
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0.01;
    }
    double valuePerPoint = tickValue / tickSize * point;
    if (valuePerPoint <= 0) // slDistancePoints * valuePerPoint không thể âm hoặc bằng 0
    {
        string msg = StringFormat("CalculateOptimalLotSize: Invalid valuePerPoint <= 0 for %s (TickValue=%.5f, TickSize=%.5f, Point=%.5f). Returning 0.01.", m_Symbol, tickValue, tickSize, point);
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0.01;
    }
        
    double lotSize = riskAmount / (slDistancePoints * valuePerPoint);
    
    // Chuẩn hóa lot size
    lotSize = NormalizeEntryLots(lotSize);
    
    string msg_final_lot = StringFormat("Optimal lot size calculated: FinalRisk=%.2f%%, SLPoints=%.1f, AccountBalance=%.2f, RiskAmount=%.2f, ValuePerPoint=%.5f, CalculatedLot=%.2f", 
                         riskPercent, slDistancePoints, accountBalance, riskAmount, valuePerPoint, lotSize);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_final_lot);
    else Print(msg_final_lot);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| V14.0: Tính toán Stop Loss tối ưu                                |
//+------------------------------------------------------------------+
double CRiskManager::CalculateOptimalStopLoss(double entryPrice, bool isLong)
{
    if (entryPrice <= 0) 
    {
        string msg = "CalculateOptimalStopLoss: Invalid entryPrice <= 0. Returning 0.";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0;
    }
    
    double currentAtr = atrValue; // Sử dụng ATR được truyền vào nếu có

    // Nếu atrValue không được cung cấp (hoặc bằng 0), thử lấy từ AssetProfile hoặc tính toán
    if (currentAtr <= 0) 
    {
        if (m_AssetProfile.avgATR > 0) 
        {
            currentAtr = m_AssetProfile.avgATR; 
            string msg_atr_profile = StringFormat("CalculateOptimalStopLoss: Using avgATR from AssetProfile: %.5f", currentAtr);
            if (m_Logger != NULL) m_Logger->LogInfo(msg_atr_profile);
            else Print(msg_atr_profile);
        }
        else 
        {
            // Tính toán ATR trực tiếp nếu không có trong AssetProfile
            int atrHandle = iATR(m_Symbol, PERIOD_CURRENT, m_AssetConfig.atrPeriod > 0 ? m_AssetConfig.atrPeriod : 14); // Sử dụng atrPeriod từ config nếu có
            if (atrHandle != INVALID_HANDLE) 
            {
                double atrBuffer[];
                ArraySetAsSeries(atrBuffer, true);
                if (CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0) 
                {
                    currentAtr = atrBuffer[0];
                    string msg_atr_calc = StringFormat("CalculateOptimalStopLoss: Calculated ATR(%d) directly: %.5f", m_AssetConfig.atrPeriod > 0 ? m_AssetConfig.atrPeriod : 14, currentAtr);
                    if (m_Logger != NULL) m_Logger->LogInfo(msg_atr_calc);
                    else Print(msg_atr_calc);
                }
                IndicatorRelease(atrHandle);
            }
        }
    }
    
    // Nếu vẫn không thể tính ATR, sử dụng % giá như một phương án dự phòng cuối cùng
    if (currentAtr <= 0) 
    {        
        currentAtr = entryPrice * (m_AssetConfig.fallbackSlPercent > 0 ? m_AssetConfig.fallbackSlPercent / 100.0 : 0.01); // Sử dụng fallbackSlPercent từ config hoặc 1%
        string msg_fallback = StringFormat("CalculateOptimalStopLoss: ATR is zero or invalid. Using fallback SL: %.2f%% of entry price = %.5f", 
                                (m_AssetConfig.fallbackSlPercent > 0 ? m_AssetConfig.fallbackSlPercent : 1.0), currentAtr);
        if (m_Logger != NULL) m_Logger->LogWarning(msg_fallback); // Changed to LogWarning as it's a fallback scenario
        else Print("CẢNH BÁO: " + msg_fallback);
    }
    
    // Lấy slMultiplier từ CurrentAssetProfile (thông qua m_AssetConfig)
    double slMultiplier = m_AssetConfig.slAtrMultiplier;
    string msg_sl_multi = StringFormat("CalculateOptimalStopLoss: Using slAtrMultiplier from AssetConfig: %.2f", slMultiplier);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_sl_multi);
    else Print(msg_sl_multi);

    // Tính khoảng cách StopLoss bằng ATR * slMultiplier
    double stopLossDistance = currentAtr * slMultiplier;
    
    double stopLossPrice = 0;
    if (isLong) {
        stopLossPrice = entryPrice - stopLossDistance;
    } else {
        stopLossPrice = entryPrice + stopLossDistance;
    }
    string msg_tent_sl = StringFormat("CalculateOptimalStopLoss: Entry=%.5f, ATR=%.5f, SLMultiplier=%.2f, SLDistance=%.5f, TentativeSL=%.5f", 
                         entryPrice, currentAtr, slMultiplier, stopLossDistance, stopLossPrice);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_tent_sl);
    else Print(msg_tent_sl);
    
    // Đảm bảo SL cách xa đủ so với giá vào lệnh, dựa trên minStopDistance từ AssetProfile
    double minStopPoints = m_AssetProfile.minStopDistance; // Đây là số điểm, không phải giá trị tiền tệ
    double minDistanceValue = minStopPoints * SymbolInfoDouble(m_Symbol, SYMBOL_POINT);
    string msg_min_dist = StringFormat("CalculateOptimalStopLoss: MinStopDistancePoints from AssetProfile: %.1f, MinDistanceValue: %.5f", minStopPoints, minDistanceValue);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_min_dist);
    else Print(msg_min_dist);

    if (isLong) {
        if ((entryPrice - stopLossPrice) < minDistanceValue) {
            stopLossPrice = entryPrice - minDistanceValue;
            string msg_adj_long = StringFormat("CalculateOptimalStopLoss: Adjusted SL for LONG to meet MinDistance. New SL=%.5f", stopLossPrice);
            if (m_Logger != NULL) m_Logger->LogInfo(msg_adj_long);
            else Print(msg_adj_long);
        }
    } else { // Short
        if ((stopLossPrice - entryPrice) < minDistanceValue) {
            stopLossPrice = entryPrice + minDistanceValue;
            string msg_adj_short = StringFormat("CalculateOptimalStopLoss: Adjusted SL for SHORT to meet MinDistance. New SL=%.5f", stopLossPrice);
            if (m_Logger != NULL) m_Logger->LogInfo(msg_adj_short);
            else Print(msg_adj_short);
        }
    }
    
    return NormalizeDouble(stopLossPrice, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| V14.0: Tính toán Take Profit tối ưu                              |
//+------------------------------------------------------------------+
double CRiskManager::CalculateOptimalTakeProfit(double entryPrice, double stopLossPrice, bool isLong)
{
    if (entryPrice <= 0 || stopLossPrice <= 0) 
    {
        string msg = "CalculateOptimalTakeProfit: Invalid entryPrice or stopLossPrice <= 0. Returning 0.";
        if (m_Logger != NULL) m_Logger->LogError(msg);
        else Print("LỖI: " + msg);
        return 0;
    }
    
    // Tính khoảng cách SL (tuyệt đối)
    double slDistance = MathAbs(entryPrice - stopLossPrice);
    if (slDistance == 0)
    {
        string msg_sl_zero = "CalculateOptimalTakeProfit: slDistance is zero. Cannot calculate TP. Returning 0.";
        if (m_Logger != NULL) m_Logger->LogError(msg_sl_zero);
        else Print("LỖI: " + msg_sl_zero);
        return 0; // Tránh chia cho 0 hoặc TP trùng entry
    }
    string msg_sl_dist = StringFormat("CalculateOptimalTakeProfit: Entry=%.5f, SL=%.5f, SLDistance=%.5f", entryPrice, stopLossPrice, slDistance);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_sl_dist);
    else Print(msg_sl_dist);

    // Lấy tỷ lệ R:R tối ưu từ CurrentAssetProfile (thông qua m_AssetConfig)
    double rrRatio = m_AssetConfig.tpRrRatio;
    string msg_rr_ratio = StringFormat("CalculateOptimalTakeProfit: Using tpRrRatio from AssetConfig: %.2f", rrRatio);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_rr_ratio);
    else Print(msg_rr_ratio);

    // (Tùy chọn) Logic điều chỉnh rrRatio dựa trên các yếu tố khác từ AssetProfile có thể được thêm ở đây nếu cần
    // Ví dụ: if (m_AssetProfile.marketState == SOME_STATE) rrRatio *= m_AssetProfile.rrModifierForThatState;
    // Hiện tại, chúng ta sẽ giữ nguyên rrRatio từ AssetConfig theo yêu cầu ban đầu.

    if (rrRatio <= 0) // Đảm bảo rrRatio hợp lệ
    {
        string msg_invalid_rr = StringFormat("CalculateOptimalTakeProfit: Invalid rrRatio <= 0 (%.2f). Using default 1.0.", rrRatio);
        if (m_Logger != NULL) m_Logger->LogWarning(msg_invalid_rr); // Changed to LogWarning
        else Print("CẢNH BÁO: " + msg_invalid_rr);
        rrRatio = 1.0; 
    }

    double takeProfitDistance = slDistance * rrRatio;
    double takeProfitPrice = 0;
    
    if (isLong) {
        takeProfitPrice = entryPrice + takeProfitDistance;
    } else {
        takeProfitPrice = entryPrice - takeProfitDistance;
    }
    string msg_tp_calc = StringFormat("CalculateOptimalTakeProfit: RRRatio=%.2f, TPDistance=%.5f, CalculatedTP=%.5f", 
                         rrRatio, takeProfitDistance, takeProfitPrice);
    if (m_Logger != NULL) m_Logger->LogInfo(msg_tp_calc);
    else Print(msg_tp_calc);
    
    return NormalizeDouble(takeProfitPrice, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Tính toán Điều chỉnh Lot Size dựa trên ATR ratio                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateATRBasedLotSizeAdjustment(double atrRatio)
{
    // Nếu ATR thấp hơn trung bình (< 1.0), có thể tăng lot size
    if (atrRatio < 0.7) {
        return 1.2; // 120% lot
    }
    // Nếu ATR gần với trung bình (0.7-1.2), giữ nguyên lot size
    else if (atrRatio <= 1.2) {
        return 1.0; // 100% lot
    }
    // Nếu ATR cao hơn trung bình (1.2-1.5), giảm nhẹ lot size
    else if (atrRatio <= 1.5) {
        return 0.8; // 80% lot
    }
    // Nếu ATR cao gấp 1.5-2x, giảm mạnh lot size
    else if (atrRatio <= 2.0) {
        return 0.6; // 60% lot
    }
    // Nếu ATR cực cao (>2x), sử dụng lot size tối thiểu
    else {
        return 0.4; // 40% lot
    }
}

//+------------------------------------------------------------------+
//| Tính toán % risk thích ứng dựa trên drawdown, regime, session    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateAdaptiveRiskPercent(double baseRiskPercent = -1.0, string &adjustmentReasonOut = "")
{
    // Nếu baseRiskPercent không được cung cấp hoặc < 0, sử dụng m_RiskPerTrade làm cơ sở
    double initialRisk = (baseRiskPercent < 0) ? m_RiskPerTrade : baseRiskPercent;
    string reason = "Base risk for adaptation: " + DoubleToString(initialRisk, 2) + "%";
    double finalRisk = initialRisk; // Bắt đầu với initialRisk đã được xác định ở trên
    // reason đã được khởi tạo ở trên.

    // Logic lấy đề xuất từ AssetProfiler (nếu có và được kích hoạt) đã được chuyển vào CalculateOptimalLotSize
    // hoặc có thể được tích hợp ở đây nếu CalculateAdaptiveRiskPercent được gọi độc lập và cần thông tin này.
    // Hiện tại, chúng ta giả định initialRisk đã bao gồm ảnh hưởng từ m_AssetConfig.riskMultiplier nếu CalculateOptimalLotSize gọi hàm này.
    // Nếu CalculateAdaptiveRiskPercent được gọi từ nơi khác, cần đảm bảo initialRisk là phù hợp.

    double profilerSuggestedRisk = initialRisk; // Khởi tạo với giá trị mặc định
    // Lấy đề xuất từ AssetProfiler nếu có
    if (m_AssetProfiler != NULL && m_AdaptiveMode != MODE_MANUAL) {
        // Giả sử AssetProfiler có hàm GetSuggestedRiskForSymbol trả về % risk
        // double suggestedByProfiler = m_AssetProfiler.GetSuggestedRiskForSymbol(m_Symbol, m_CurrentRegime, m_CurrentSession, m_ATRRatio);
        // if (suggestedByProfiler > 0) { // Nếu có đề xuất hợp lệ
        //     profilerSuggestedRisk = suggestedByProfiler;
        // }
        // Tạm thời comment out vì GetSuggestedRiskForSymbol chưa được implement đầy đủ trong CAssetProfiler
        // if (m_Logger != NULL && m_DetailedLogging) 
        //     m_Logger->LogFormat(LOG_LEVEL_DEBUG, "AssetProfiler profile available for %s, but GetSuggestedRiskForSymbol() not yet implemented. Using base risk for profiler suggestion.", m_Symbol);
    }

    // Xử lý dựa trên AdaptiveMode
    double baseRiskFromInput = initialRisk; // Lưu lại giá trị risk ban đầu từ input (hoặc m_RiskPerTrade)
    switch (m_AdaptiveMode)
    {
        case MODE_MANUAL:
            // finalRisk đã là baseRiskFromInput (initialRisk)
            reason += "; Mode: Manual";
            break;

        case MODE_LOG_ONLY:
            // Vẫn sử dụng finalRisk = baseRiskFromInput (initialRisk)
            if (m_Logger != NULL && profilerSuggestedRisk != baseRiskFromInput)
            {
                m_Logger->LogFormat(LOG_LEVEL_INFO, 
                    "AdaptiveMode_LogOnly: AssetProfiler suggests RiskPercent=%.2f%%, but using user input of %.2f%% for %s.",
                    profilerSuggestedRisk, baseRiskFromInput, m_Symbol);
            }
            reason += "; Mode: Log Only (Using Input Risk)";
            break;

        case MODE_HYBRID:
            // finalRisk được tính dựa trên baseRiskFromInput và profilerSuggestedRisk
            // Đảm bảo finalRisk được cập nhật ở đây nếu logic này được giữ lại
            // Ví dụ: initialRisk = (baseRiskFromInput * 0.7) + (profilerSuggestedRisk * 0.3);
            // reason += "; Mode: Hybrid (Input: " + DoubleToString(baseRiskFromInput,2) + "%% * 0.7 + Profiler: " + DoubleToString(profilerSuggestedRisk,2) + "%% * 0.3 = " + DoubleToString(initialRisk,2) + "%%)";
            // if (m_Logger != NULL)
            // {
            //      m_Logger->LogFormat(LOG_LEVEL_INFO, 
            //         "AdaptiveMode_Hybrid: Calculated Risk=%.2f%% (Input %.2f%%, Profiler %.2f%%) for %s.",
            //         initialRisk, baseRiskFromInput, profilerSuggestedRisk, m_Symbol);
            // }
            // Hiện tại, logic hybrid sẽ được xử lý sau khi các yếu tố khác được áp dụng, hoặc initialRisk đã bao gồm nó.
            reason += "; Mode: Hybrid (logic to be refined)";
            break;
    }

    // Ghi log lý do ban đầu
    if(m_Logger != NULL && m_DetailedLogging)
        m_Logger->LogFormat(LOG_LEVEL_DEBUG, "AdaptiveRiskCalculation (Pre-Adjustments): %s", reason);

    // Khối switch đã được đóng ở trên, tiếp tục với adjustedRisk
    double adjustedRisk = finalRisk; // finalRisk đã được xác định bởi logic trong switch(m_AdaptiveMode)
    adjustmentReasonOut = reason; // Tiếp tục xây dựng reason string

    // --- 1. Điều chỉnh theo Drawdown ---
    double currentDD = GetCurrentDrawdownPercent(m_AccountInfo.Equity(), m_PeakEquity, m_DrawdownType);
    double ddFactor = 1.0;

    if (!m_EnableTaperedRisk) {
        if (currentDD >= m_DrawdownReduceThreshold && currentDD < m_MaxDrawdownPercent) {
            ddFactor = m_MinRiskMultiplier;
        }
        else if (currentDD >= m_MaxDrawdownPercent) {
            ddFactor = 0;
        }
    }
    else {
        if (currentDD <= m_DrawdownReduceThreshold) {
            ddFactor = 1.0;
        } else if (currentDD <= m_MaxDrawdownPercent) {
            double riskReductionRange = m_MaxDrawdownPercent - m_DrawdownReduceThreshold;
            if (riskReductionRange <= 0) riskReductionRange = 1; // Tránh chia cho 0
            double ddInRange = currentDD - m_DrawdownReduceThreshold;
            double reducePercent = ddInRange / riskReductionRange;
            double minRiskFactor = m_MinRiskMultiplier;
            ddFactor = 1.0 - (1.0 - minRiskFactor) * reducePercent;
            ddFactor = MathMax(0, ddFactor); // Đảm bảo ddFactor không âm
        } else {
            ddFactor = 0.0;
        }
    }
    adjustedRisk *= ddFactor;
    adjustmentReasonOut += "; DDReductionFactor: " + DoubleToString(ddFactor, 2);

    // Ghi log các điều chỉnh drawdown
    if(m_Logger != NULL && m_DetailedLogging)
        m_Logger->LogFormat(LOG_LEVEL_DEBUG, "RiskAfterDrawdownAdjustment: %s, AdjustedRisk: %.2f%%", adjustmentReasonOut, adjustedRisk);

    // --- 2. Điều chỉnh theo Market Regime ---
    double regimeFactor = this.GetRegimeFactor(m_CurrentRegime, m_IsTransitioningMarket);
    adjustedRisk *= regimeFactor;
    adjustmentReasonOut += "; RegimeFactor(" + EnumToString(m_CurrentRegime) + ",Trans:" + (m_IsTransitioningMarket ? "T" : "F") + "): " + DoubleToString(regimeFactor, 2);

    // --- 3. Điều chỉnh theo phiên ---
    double sessionFactor = this.GetSessionFactor(m_CurrentSession, m_Symbol);
    adjustedRisk *= sessionFactor;
    adjustmentReasonOut += "; SessionFactor(" + EnumToString(m_CurrentSession) + "): " + DoubleToString(sessionFactor, 2);

    // --- 4. Điều chỉnh theo tài sản ---
    double symbolFactor = this.GetSymbolRiskFactor(m_Symbol);
    adjustedRisk *= symbolFactor;
    adjustmentReasonOut += "; SymbolFactor(" + m_Symbol + "): " + DoubleToString(symbolFactor, 2);

    // --- 5. Điều chỉnh theo hiệu suất gần đây ---
    double performanceFactor = 1.0;

    if (m_ConsecutiveWins >= 3) {
        performanceFactor = 1.0 + MathMin(0.1, 0.02 * m_ConsecutiveWins);
    }
    else if (m_ConsecutiveLosses >= 2) {
        performanceFactor = 1.0 - MathMin(0.5, 0.1 * m_ConsecutiveLosses);
    }
    adjustedRisk *= performanceFactor;
    adjustmentReasonOut += "; PerfFactor(W:" + IntegerToString(m_ConsecutiveWins) + ",L:" + IntegerToString(m_ConsecutiveLosses) + "): " + DoubleToString(performanceFactor, 2);

    // --- Giới hạn risk trong khoảng min/max đã định ---
    if (m_MaxRisk > 0 && m_MinRisk >= 0 && m_MaxRisk >= m_MinRisk) {
        adjustedRisk = MathMax(m_MinRisk, MathMin(m_MaxRisk, adjustedRisk));
        adjustmentReasonOut += "; ClampedToRange[" + DoubleToString(m_MinRisk,2) + "-" + DoubleToString(m_MaxRisk,2) + "]: " + DoubleToString(adjustedRisk,2) + "%";
    }

    if(m_Logger != NULL && m_DetailedLogging)
        m_Logger->LogFormat(LOG_LEVEL_DEBUG, "FinalAdaptiveRiskCalculation: %s, FinalAdjustedRisk: %.2f%%", adjustmentReasonOut, adjustedRisk);

    return adjustedRisk;
}
// Các hàm GetRegimeFactor, GetSessionFactor, GetSymbolRiskFactor cần được định nghĩa ở đây hoặc trong file khác và include vào.
// Nếu chúng không được định nghĩa, sẽ gây lỗi biên dịch.
// Hiện tại, chúng ta giả định chúng sẽ được cung cấp sau.

// --- END OF CalculateAdaptiveRiskPercent ---
    // --- Giới hạn risk trong khoảng min/max đã định ---
    // Đảm bảo m_MinRisk và m_MaxRisk được khai báo và khởi tạo trong class CRiskManager
    // Chuyển đổi sang double nếu chúng là kiểu khác (ví dụ: int)
    double minRisk = (double)m_MinRisk; // Giả sử m_MinRisk là thành viên của class
    double maxRisk = (double)m_MaxRisk; // Giả sử m_MaxRisk là thành viên của class

    if (maxRisk > 0 && minRisk >= 0 && maxRisk >= minRisk) { // Chỉ áp dụng nếu các giá trị hợp lệ
        adjustedRisk = MathMax(minRisk, MathMin(maxRisk, adjustedRisk));
        adjustmentReasonOut += "; ClampedToRange[" + DoubleToString(minRisk,2) + "-" + DoubleToString(maxRisk,2) + "]: " + DoubleToString(adjustedRisk,2) + "%";
    }

    if(m_Logger != NULL && m_DetailedLogging)
        m_Logger->LogFormat(LOG_LEVEL_DEBUG, "FinalAdaptiveRiskCalculation: %s, FinalAdjustedRisk: %.2f%%", adjustmentReasonOut, adjustedRisk);

    return adjustedRisk;
}



//+------------------------------------------------------------------+
//| V14.0: Kiểm tra tiếp cận giới hạn lỗ hàng ngày                   |
//+------------------------------------------------------------------+
double CRiskManager::IsApproachingDailyLossLimit()
{
    double maxDailyLoss = m_DayStartEquity * m_MaxDailyLossPercent / 100.0;
    double currentDailyLoss = m_DailyLoss;
    
    // Nếu đã mất 80% của giới hạn lỗ ngày, trả về true
    return (currentDailyLoss > maxDailyLoss * 0.8);
}

//+------------------------------------------------------------------+
//| Kiểm tra điều kiện tạm dừng                                      |
//+------------------------------------------------------------------+
bool CRiskManager::CheckPauseCondition()
{
    if (GetCurrentDrawdownPercent() >= m_MaxDrawdownPercent) {
        string msg_dd = "Điều kiện tạm dừng: Drawdown vượt ngưỡng tối đa " + DoubleToString(m_MaxDrawdownPercent, 2) + "%";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_dd); // Changed to LogWarning
        else Print("CẢNH BÁO: " + msg_dd);
        return true;
    }
    
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        string msg_cl = "Điều kiện tạm dừng: Đạt số lần thua liên tiếp tối đa " + IntegerToString(m_MaxConsecutiveLosses);
        if (m_Logger != NULL) m_Logger->LogWarning(msg_cl); // Changed to LogWarning
        else Print("CẢNH BÁO: " + msg_cl);
        return true;
    }
    
    if (GetDailyLossPercent() >= m_MaxDailyLossPercent) {
        string msg_dl = "Điều kiện tạm dừng: Đạt giới hạn lỗ hàng ngày " + DoubleToString(m_MaxDailyLossPercent, 2) + "%";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_dl); // Changed to LogWarning
        else Print("CẢNH BÁO: " + msg_dl);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra điều kiện tự động tiếp tục                              |
//+------------------------------------------------------------------+
bool CRiskManager::CheckAutoResume()
{
    bool canResume = false;
    
    // Nếu không còn lỗ liên tiếp, có thể tiếp tục
    if (m_ConsecutiveLosses == 0) {
        canResume = true;
    }
    
    // Kiểm tra thêm điều kiện thị trường
    if (m_IsTransitioningMarket == false && m_MarketRegimeConfidence > 0.7 && m_ATRRatio < 1.2) {
        // Thị trường ổn định và có tin cậy cao
        canResume = true;
    }
    
    // Nhưng vẫn phải kiểm tra điều kiện DD
    if (GetCurrentDrawdownPercent() >= m_MaxDrawdownPercent) {
        canResume = false;
    }
    
    return canResume;
}

//+------------------------------------------------------------------+
//| Tạm dừng giao dịch trong một khoảng thời gian                    |
//+------------------------------------------------------------------+
void CRiskManager::PauseTrading(int minutes, string reason = "")
{
    m_PauseUntil = TimeCurrent() + minutes * 60;
    
    string pauseMsg = "EA tạm dừng " + (reason != "" ? "vì " + reason : "") + 
                    " đến " + TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES);
    if (m_Logger != NULL) m_Logger->LogWarning(pauseMsg); // Changed to LogWarning
    else Print("CẢNH BÁO: " + pauseMsg);
}

//+------------------------------------------------------------------+
//| Tiếp tục giao dịch                                               |
//+------------------------------------------------------------------+
void CRiskManager::ResumeTrading(string reason = "")
{
    m_PauseUntil = 0;
    
    string resumeMsg = "EA tiếp tục hoạt động" + (reason != "" ? " vì " + reason : "");
    if (m_Logger != NULL) m_Logger->LogInfo(resumeMsg);
    else Print(resumeMsg);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem đã đạt giới hạn lỗ tối đa chưa                      |
//+------------------------------------------------------------------+
bool CRiskManager::IsMaxLossReached()
{
    // Kiểm tra drawdown
    double currentDD = GetCurrentDrawdownPercent();
    if (currentDD >= m_MaxDrawdownPercent) {
        string msg_dd_max = "Đã đạt giới hạn drawdown tối đa: " + DoubleToString(currentDD, 2) + "%";
        if (m_Logger != NULL) m_Logger->LogCritical(msg_dd_max); // Changed to LogCritical
        else Print("NGHIÊM TRỌNG: " + msg_dd_max);
        return true;
    }
    
    // Kiểm tra lỗ hàng ngày
    double dailyLossPercent = GetDailyLossPercent();
    if (dailyLossPercent >= m_MaxDailyLossPercent) {
        string msg_dl_max = "Đã đạt giới hạn lỗ hàng ngày: " + DoubleToString(dailyLossPercent, 2) + "%";
        if (m_Logger != NULL) m_Logger->LogCritical(msg_dl_max); // Changed to LogCritical
        else Print("NGHIÊM TRỌNG: " + msg_dl_max);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem nên tạm dừng giao dịch không                        |
//+------------------------------------------------------------------+
bool CRiskManager::ShouldPauseTrading()
{
    // Kiểm tra đã đạt giới hạn lỗ
    if (IsMaxLossReached()) return true;
    
    // Kiểm tra số lần thua liên tiếp
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        string msg_cl = "Nên tạm dừng giao dịch: Đã thua liên tiếp " + IntegerToString(m_ConsecutiveLosses) + " lần";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_cl);
        else Print("CẢNH BÁO: " + msg_cl);
        return true;
    }
    
    // Kiểm tra thị trường cực kỳ biến động
    if (m_ATRRatio > 2.5) {
        string msg_atr = "Nên tạm dừng giao dịch: Biến động cực cao (ATR ratio = " + DoubleToString(m_ATRRatio, 2) + "x)";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_atr);
        else Print("CẢNH BÁO: " + msg_atr);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| V14.0: Cập nhật trạng thái tạm dừng                              |
//+------------------------------------------------------------------+
void CRiskManager::UpdatePauseStatus()
{
    // Tạm dừng nếu DD quá lớn
    if (GetCurrentDrawdownPercent() > m_MaxDrawdownPercent) {
        m_PauseUntil = TimeCurrent() + 12*3600; // Dừng 12 giờ
        string msg_dd_pause = "Tạm dừng EA do drawdown vượt mức, tiếp tục sau 12 giờ";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_dd_pause);
        else Print("CẢNH BÁO: " + msg_dd_pause);
        return;
    }
    
    // Tạm dừng nếu thua liên tiếp
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        m_PauseUntil = TimeCurrent() + 8*3600; // Dừng 8 giờ
        string msg_cl_pause = "Tạm dừng EA do thua " + IntegerToString(m_ConsecutiveLosses) + " lần liên tiếp, tiếp tục sau 8 giờ";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_cl_pause);
        else Print("CẢNH BÁO: " + msg_cl_pause);
        return;
    }
    
    // Tạm dừng nếu tới giới hạn lỗ hàng ngày
    if (GetDailyLossPercent() > m_MaxDailyLossPercent) {
        // Dừng đến đầu phiên giao dịch ngày tiếp theo
        datetime tomorrow = TimeCurrent() + 24*3600;
        MqlDateTime tomorrowStruct;
        TimeToStruct(tomorrow, tomorrowStruct);
        
        // Reset về 00:00:00
        tomorrowStruct.hour = 0;
        tomorrowStruct.min = 0;
        tomorrowStruct.sec = 0;
        
        datetime pauseUntil = StructToTime(tomorrowStruct);
        m_PauseUntil = pauseUntil;
        
        string msg_dl_pause = "Tạm dừng EA do đạt giới hạn lỗ ngày, tiếp tục vào ngày mai";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_dl_pause);
        else Print("CẢNH BÁO: " + msg_dl_pause);
        return;
    }
    
    // Kiểm tra thị trường nhiễu hoặc biến động cực cao
    if (m_IsTransitioningMarket && m_MarketRegimeConfidence < 0.3 && m_ATRRatio > 2.0) {
        m_PauseUntil = TimeCurrent() + 4*3600; // Dừng 4 giờ
        string msg_market_pause = "Tạm dừng EA do thị trường nhiễu và biến động cao";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_market_pause);
        else Print("CẢNH BÁO: " + msg_market_pause);
        return;
    }
}

//+------------------------------------------------------------------+
//| Cập nhật drawdown tối đa                                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdateMaxDrawdown()
{
    double currentEquity = m_AccountInfo.Equity();
    double baseValue;
    
    if (m_DrawdownType == DRAWDOWN_EQUITY_BASED) {
        // Cập nhật peak equity nếu cao hơn
        if (currentEquity > m_PeakEquity) {
            m_PeakEquity = currentEquity;
            return; // Không có drawdown
        }
        baseValue = m_PeakEquity;
    } else { // DRAWDOWN_BALANCE_BASED
        baseValue = m_DayStartEquity;
    }
    
    if (baseValue > 0) { // Tránh chia cho 0
        // Tính drawdown hiện tại
        double currentDD = (baseValue - currentEquity) / baseValue * 100.0;
        
        // Cập nhật max drawdown nếu lớn hơn
        if (currentDD > m_MaxDrawdownRecorded) {
            m_MaxDrawdownRecorded = currentDD;
            string ddType = (m_DrawdownType == DRAWDOWN_EQUITY_BASED) ? "Equity" : "Balance";
            string msg_max_dd = "Cập nhật Max Drawdown mới (" + ddType + "-based): " + DoubleToString(m_MaxDrawdownRecorded, 2) + "%";
            if (m_Logger != NULL) m_Logger->LogInfo(msg_max_dd);
            else Print(msg_max_dd);
        }
    }
}

//+------------------------------------------------------------------+
//| Tính Drawdown hiện tại                                           |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdownPercent()
{
    double currentEquity = m_AccountInfo.Equity();
    double baseValue;
    
    if (m_DrawdownType == DRAWDOWN_EQUITY_BASED) {
        // Cập nhật peak equity nếu cao hơn
        if (currentEquity > m_PeakEquity) {
            m_PeakEquity = currentEquity;
            return 0.0; // Không có drawdown
        }
        baseValue = m_PeakEquity;
    } else { // DRAWDOWN_BALANCE_BASED
        // Sử dụng balance đầu ngày làm cơ sở
        baseValue = m_DayStartEquity;
        if (baseValue <= 0) { // Nếu chưa được khởi tạo
            InitializeDayStartEquity(); // Assuming this method exists and sets m_DayStartEquity
            baseValue = m_DayStartEquity;
        }
    }
    
    // Tính toán drawdown
    if (baseValue > 0) { // Tránh chia cho 0
        return ((baseValue - currentEquity) / baseValue) * 100.0;
    }
    
    return 0.0; // Trả về 0 nếu không thể tính toán
}

//+------------------------------------------------------------------+
//| Tính % lỗ hàng ngày                                              |
//+------------------------------------------------------------------+
double CRiskManager::GetDailyLossPercent()
{
    double currentEquity = m_AccountInfo.Equity();
    
    // Nếu equity cao hơn mức bắt đầu, không có lỗ
    if (currentEquity >= m_DayStartEquity) {
        return 0.0;
    }
    
    // Tính và trả về % lỗ
    return (m_DayStartEquity - currentEquity) / m_DayStartEquity * 100.0;
}

//+------------------------------------------------------------------+
//| V14.0: Kiểm tra spread chấp nhận được                            |
//+------------------------------------------------------------------+
bool CRiskManager::IsSpreadAcceptable(double currentSpread = 0.0)
{
    // Nếu không cung cấp currentSpread, lấy từ Symbol
    if (currentSpread <= 0) {
        currentSpread = (double)SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD);
    }
    
    // 1. Ngưỡng cứng từ AssetConfig
    double maxSpreadPoints = m_AssetConfig.maxSpreadPoints;
    
    // Kiểm tra ngưỡng cứng
    if (currentSpread > maxSpreadPoints) {
        string msg_spread_high = "Spread quá cao: " + DoubleToString(currentSpread, 1) + " > " + DoubleToString(maxSpreadPoints, 1) + " (max)";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_spread_high);
        else Print("CẢNH BÁO: " + msg_spread_high);
        return false;
    }
    
    // 2. Kiểm tra spread theo tỉ lệ trung bình
    if (m_AssetProfile.avgSpread > 0) {
        double spreadRatio = currentSpread / m_AssetProfile.avgSpread;
        
        // Cập nhật SpreadRatio để sử dụng sau này
        m_SpreadRatio = spreadRatio;
        
        // Nếu spread cao hơn 3x trung bình
        if (spreadRatio > 3.0) {
            string msg_spread_unusual = "Spread bất thường: " + DoubleToString(currentSpread, 1) + " điểm" + ", " + DoubleToString(spreadRatio, 1) + "x trung bình";
            if (m_Logger != NULL) m_Logger->LogWarning(msg_spread_unusual);
            else Print("CẢNH BÁO: " + msg_spread_unusual);
            return false;
        }
        
        // Nếu spread cao 2-3x & trong chế độ Prop Firm, kiểm tra chặt hơn
        if (m_PropFirmMode && spreadRatio > 2.0) {
            string msg_prop_spread_high = "Prop Mode: Spread khá cao: " + DoubleToString(currentSpread, 1) + " điểm" + ", " + DoubleToString(spreadRatio, 1) + "x trung bình";
            if (m_Logger != NULL) m_Logger->LogWarning(msg_prop_spread_high);
            else Print("CẢNH BÁO: " + msg_prop_spread_high);
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| V14.0: Kiểm tra biến động chấp nhận được                         |
//+------------------------------------------------------------------+
bool CRiskManager::IsVolatilityAcceptable(double currentATRratio = 0.0)
{
    // Nếu không cung cấp, sử dụng giá trị đã lưu trong MarketProfile
    if (currentATRratio <= 0) {
        currentATRratio = m_ATRRatio;
    }
    
    // Biến động quá cao
    if (currentATRratio > 2.5) {
        string msg_vol_extreme = "Biến động cực kỳ cao: " + DoubleToString(currentATRratio, 2) + "x > 2.5x trung bình";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_vol_extreme);
        else Print("CẢNH BÁO: " + msg_vol_extreme);
        return false;
    }
    
    // Biến động cao và đang trong chế độ chuyển tiếp
    if (currentATRratio > 2.0 && m_IsTransitioningMarket) {
        string msg_vol_transition = "Biến động cao và thị trường đang chuyển tiếp: " + DoubleToString(currentATRratio, 2) + "x";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_vol_transition);
        else Print("CẢNH BÁO: " + msg_vol_transition);
        return false;
    }
    
    // Biến động cao trong chế độ Prop Firm
    if (m_PropFirmMode && currentATRratio > 1.8) {
        string msg_prop_vol_high = "Prop Mode: Biến động cao: " + DoubleToString(currentATRratio, 2) + "x > 1.8x";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_prop_vol_high);
        else Print("CẢNH BÁO: " + msg_prop_vol_high);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| V14.0: Kiểm tra điều kiện thị trường thích hợp tổng hợp           |
//+------------------------------------------------------------------+
bool CRiskManager::IsMarketSuitableForTrading()
{
    // Tính risk index - giá trị tổng hợp (0-100%)
    double riskIndex = CalculateMarketRiskIndex();
    
    // Ngưỡng rủi ro chấp nhận được
    double acceptableRiskThreshold = 70.0; // 70% là ngưỡng cảnh báo
    
    // Nếu risk quá cao, thị trường không thích hợp
    if (riskIndex > acceptableRiskThreshold) {
        string msg_risk_too_high = StringFormat("Thị trường không thích hợp: Rủi ro quá cao (%.1f%%)", riskIndex);
        if (m_Logger != NULL) m_Logger->LogWarning(msg_risk_too_high);
        else Print("CẢNH BÁO: " + msg_risk_too_high);
        return false;
    }
    
    // Kiểm tra thêm các điều kiện cụ thể
    
    // 1. Spread chấp nhận được?
    if (!IsSpreadAcceptable()) {
        return false;
    }
    
    // 2. Biến động chấp nhận được?
    if (!IsVolatilityAcceptable()) {
        return false;
    }
    
    // 3. Regime chuyển tiếp với độ tin cậy thấp?
    if (m_IsTransitioningMarket && m_MarketRegimeConfidence < 0.4) {
        string msg_transition_low_conf = "Thị trường không thích hợp: Đang chuyển tiếp với độ tin cậy thấp (" + DoubleToString(m_MarketRegimeConfidence, 2) + ")";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_transition_low_conf);
        else Print("CẢNH BÁO: " + msg_transition_low_conf);
        return false;
    }
    
    // 4. Chế độ thị trường cực biến động?
    if (m_CurrentRegime == REGIME_VOLATILE_EXPANSION && m_ATRRatio > 1.5) {
        string msg_volatile_expansion = "Thị trường không thích hợp: Đang mở rộng biến động cao";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_volatile_expansion);
        else Print("CẢNH BÁO: " + msg_volatile_expansion);
        return false;
    }
    
    // 5. Xác suất thống kê thấp với chế độ thị trường hiện tại?
    // Kiểm tra Win Rate và Profit Factor theo regime
    if (m_RegimeStats[m_IsTransitioningMarket ? 1 : 0].trades >= 10) {
        double winRate = GetRegimeWinRate(m_IsTransitioningMarket);
        double profitFactor = GetRegimeProfitFactor(m_IsTransitioningMarket);
        
        if (winRate < 35.0 && profitFactor < 0.7) {
            string msg_poor_performance = StringFormat("Thị trường không thích hợp: Hiệu suất kém trong chế độ hiện tại (Win rate: %.1f%%, PF: %.2f)", winRate, profitFactor);
            if (m_Logger != NULL) m_Logger->LogWarning(msg_poor_performance);
            else Print("CẢNH BÁO: " + msg_poor_performance);
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| V14.0: Lấy ngưỡng spread chấp nhận được                          |
//+------------------------------------------------------------------+
double CRiskManager::GetAcceptableSpreadThreshold()
{
    return m_AssetConfig.maxSpreadPoints;
}

//+------------------------------------------------------------------+
//| Tính Win Rate                                                     |
//+------------------------------------------------------------------+
double CRiskManager::GetWinRate() const
{
    if (m_TotalTrades == 0) return 0.0;
    return (double)m_Wins / m_TotalTrades * 100.0;
}

//+------------------------------------------------------------------+
//| Tính Profit Factor                                                |
//+------------------------------------------------------------------+
double CRiskManager::GetProfitFactor() const
{
    if (m_LossSum == 0.0) return 0.0;
    return m_ProfitSum / m_LossSum;
}

//+------------------------------------------------------------------+
//| Tính Expectancy                                                   |
//+------------------------------------------------------------------+
double CRiskManager::GetExpectancy() const
{
    if (m_TotalTrades == 0) return 0.0;
    return (m_ProfitSum - m_LossSum) / m_TotalTrades;
}

//+------------------------------------------------------------------+
//| Tính Win Rate theo Cluster                                        |
//+------------------------------------------------------------------+
double CRiskManager::GetClusterWinRate(int clusterIndex) const
{
    if (clusterIndex < 0 || clusterIndex >= 3 || m_ClusterStats[clusterIndex].trades == 0) {
        return 0.0;
    }
    
    return (double)m_ClusterStats[clusterIndex].wins / m_ClusterStats[clusterIndex].trades * 100.0;
}

//+------------------------------------------------------------------+
//| Tính Profit Factor theo Cluster                                   |
//+------------------------------------------------------------------+
double CRiskManager::GetClusterProfitFactor(int clusterIndex) const
{
    if (clusterIndex < 0 || clusterIndex >= 3 || m_ClusterStats[clusterIndex].loss == 0.0) {
        return 0.0;
    }
    
    return m_ClusterStats[clusterIndex].profit / m_ClusterStats[clusterIndex].loss;
}

//+------------------------------------------------------------------+
//| Tính Win Rate theo Phiên                                          |
//+------------------------------------------------------------------+
double CRiskManager::GetSessionWinRate(int sessionIndex) const
{
    if (sessionIndex < 0 || sessionIndex >= 5 || m_SessionStats[sessionIndex].trades == 0) {
        return 0.0;
    }
    
    return (double)m_SessionStats[sessionIndex].wins / m_SessionStats[sessionIndex].trades * 100.0;
}

//+------------------------------------------------------------------+
//| Tính Profit Factor theo Phiên                                     |
//+------------------------------------------------------------------+
double CRiskManager::GetSessionProfitFactor(int sessionIndex) const
{
    if (sessionIndex < 0 || sessionIndex >= 5 || m_SessionStats[sessionIndex].loss == 0.0) {
        return 0.0;
    }
    
    return m_SessionStats[sessionIndex].profit / m_SessionStats[sessionIndex].loss;
}

//+------------------------------------------------------------------+
//| Tính Win Rate theo ATR                                            |
//+------------------------------------------------------------------+
double CRiskManager::GetATRWinRate(int atrIndex) const
{
    if (atrIndex < 0 || atrIndex >= 5 || m_ATRStats[atrIndex].trades == 0) {
        return 0.0;
    }
    
    return (double)m_ATRStats[atrIndex].wins / m_ATRStats[atrIndex].trades * 100.0;
}

//+------------------------------------------------------------------+
//| Tính Profit Factor theo ATR                                       |
//+------------------------------------------------------------------+
double CRiskManager::GetATRProfitFactor(int atrIndex) const
{
    if (atrIndex < 0 || atrIndex >= 5 || m_ATRStats[atrIndex].loss == 0.0) {
        return 0.0;
    }
    
    return m_ATRStats[atrIndex].profit / m_ATRStats[atrIndex].loss;
}

//+------------------------------------------------------------------+
//| Tính Win Rate theo Market Regime                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetRegimeWinRate(bool isTransitioning) const
{
    int idx = isTransitioning ? 1 : 0;
    if (m_RegimeStats[idx].trades == 0) {
        return 0.0;
    }
    
    return (double)m_RegimeStats[idx].wins / m_RegimeStats[idx].trades * 100.0;
}

//+------------------------------------------------------------------+
//| Tính Profit Factor theo Market Regime                             |
//+------------------------------------------------------------------+
double CRiskManager::GetRegimeProfitFactor(bool isTransitioning) const
{
    int idx = isTransitioning ? 1 : 0;
    if (m_RegimeStats[idx].loss == 0.0) {
        return 0.0;
    }
    
    return m_RegimeStats[idx].profit / m_RegimeStats[idx].loss;
}

//+------------------------------------------------------------------+
//| Tạo báo cáo hiệu suất tổng thể                                   |
//+------------------------------------------------------------------+
string CRiskManager::GeneratePerformanceReport()
{
    string report = "===== PERFORMANCE REPORT =====\n";
    report += "Total Trades: " + IntegerToString(m_TotalTrades) + "\n";
    report += "Win Rate: " + DoubleToString(GetWinRate(), 2) + "%\n";
    report += "Profit Factor: " + DoubleToString(GetProfitFactor(), 2) + "\n";
    report += "Expectancy: $" + DoubleToString(GetExpectancy(), 2) + "\n";
    report += "Max Drawdown: " + DoubleToString(m_MaxDrawdownRecorded, 2) + "%\n";
    report += "Max Consecutive Wins: " + IntegerToString(m_MaxConsecutiveWins) + "\n";
    report += "Max Consecutive Losses: " + IntegerToString(m_MaxConsecutiveLosses) + "\n";
    
    report += "\n=== CLUSTER PERFORMANCE ===\n";
    string clusterNames[] = {"Trend Following", "Countertrend", "Scaling"};
    
    for (int i = 0; i < 3; i++) {
        if (m_ClusterStats[i].trades == 0) continue;
        
        double winRate = GetClusterWinRate(i);
        double profitFactor = GetClusterProfitFactor(i);
        
        report += clusterNames[i] + ":\n";
        report += "  Trades: " + IntegerToString(m_ClusterStats[i].trades) + "\n";
        report += "  Win Rate: " + DoubleToString(winRate, 2) + "%\n";
        report += "  Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
        report += "  Net Profit: $" + DoubleToString(m_ClusterStats[i].profit - m_ClusterStats[i].loss, 2) + "\n";
    }
    
    report += "\n=== SESSION PERFORMANCE ===\n";
    string sessionNames[] = {"Asian", "European", "American", "Overlap EU-US", "Closing"};
    
    for (int i = 0; i < 5; i++) {
        if (m_SessionStats[i].trades == 0) continue;
        
        double winRate = GetSessionWinRate(i);
        double profitFactor = GetSessionProfitFactor(i);
        
        report += sessionNames[i] + " Session:\n";
        report += "  Trades: " + IntegerToString(m_SessionStats[i].trades) + "\n";
        report += "  Win Rate: " + DoubleToString(winRate, 2) + "%\n";
        report += "  Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
        report += "  Net Profit: $" + DoubleToString(m_SessionStats[i].profit - m_SessionStats[i].loss, 2) + "\n";
    }
    
    report += "\n=== ATR RATIO PERFORMANCE ===\n";
    string atrLevels[] = {"Low ATR (<0.8)", "Below Avg (0.8-1.0)", 
                         "Average (1.0-1.2)", "High (1.2-1.5)", "Very High (>1.5)"};
    
    for (int i = 0; i < 5; i++) {
        if (m_ATRStats[i].trades == 0) continue;
        
        double winRate = GetATRWinRate(i);
        double profitFactor = GetATRProfitFactor(i);
        
        report += atrLevels[i] + ":\n";
        report += "  Trades: " + IntegerToString(m_ATRStats[i].trades) + "\n";
        report += "  Win Rate: " + DoubleToString(winRate, 2) + "%\n";
        report += "  Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
        report += "  Net Profit: $" + DoubleToString(m_ATRStats[i].profit - m_ATRStats[i].loss, 2) + "\n";
    }
    
    report += "\n=== MARKET REGIME PERFORMANCE ===\n";
    string regimeNames[] = {"Stable Market", "Transitioning Market"};
    
    for (int i = 0; i < 2; i++) {
        if (m_RegimeStats[i].trades == 0) continue;
        
        double winRate = GetRegimeWinRate(i == 1);
        double profitFactor = GetRegimeProfitFactor(i == 1);
        
        report += regimeNames[i] + ":\n";
        report += "  Trades: " + IntegerToString(m_RegimeStats[i].trades) + "\n";
        report += "  Win Rate: " + DoubleToString(winRate, 2) + "%\n";
        report += "  Profit Factor: " + DoubleToString(profitFactor, 2) + "\n";
        report += "  Net Profit: $" + DoubleToString(m_RegimeStats[i].profit - m_RegimeStats[i].loss, 2) + "\n";
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| Tạo báo cáo phân tích theo Market Regime                         |
//+------------------------------------------------------------------+
string CRiskManager::GenerateRegimeAnalysisReport()
{
    string report = "===== MARKET REGIME ANALYSIS =====\n";
    
    // So sánh hiệu suất giữa các chế độ thị trường
    double stableWinRate = GetRegimeWinRate(false);
    double transitionWinRate = GetRegimeWinRate(true);
    
    double stablePF = GetRegimeProfitFactor(false);
    double transitionPF = GetRegimeProfitFactor(true);
    
    report += "Stable Market Stats:\n";
    report += "  Trades: " + IntegerToString(m_RegimeStats[0].trades) + "\n";
    report += "  Win Rate: " + DoubleToString(stableWinRate, 2) + "%\n";
    report += "  Profit Factor: " + DoubleToString(stablePF, 2) + "\n";
    
    report += "\nTransitioning Market Stats:\n";
    report += "  Trades: " + IntegerToString(m_RegimeStats[1].trades) + "\n";
    report += "  Win Rate: " + DoubleToString(transitionWinRate, 2) + "%\n";
    report += "  Profit Factor: " + DoubleToString(transitionPF, 2) + "\n";
    
    // Phân tích sâu hơn về các chế độ ATR khác nhau
    report += "\n=== ATR RATIO DETAILED ANALYSIS ===\n";
    
    string atrLevels[] = {"Low ATR (<0.8)", "Below Avg (0.8-1.0)", 
                         "Average (1.0-1.2)", "High (1.2-1.5)", "Very High (>1.5)"};
    
    // Tìm mức ATR hiệu quả nhất
    int bestATRIndex = -1;
    double bestPF = 0.0;
    
    for (int i = 0; i < 5; i++) {
        if (m_ATRStats[i].trades >= 5) { // Chỉ xét nếu có đủ dữ liệu
            double pfValue = GetATRProfitFactor(i);
            if (pfValue > bestPF) {
                bestPF = pfValue;
                bestATRIndex = i;
            }
        }
    }
    
    // Hiển thị phân tích ATR
    for (int i = 0; i < 5; i++) {
        if (m_ATRStats[i].trades == 0) continue;
        
        report += atrLevels[i] + ":\n";
        report += "  Trades: " + IntegerToString(m_ATRStats[i].trades) + "\n";
        report += "  Win Rate: " + DoubleToString(GetATRWinRate(i), 2) + "%\n";
        report += "  Profit Factor: " + DoubleToString(GetATRProfitFactor(i), 2) + "\n";
        report += "  Avg. Profit: $" + DoubleToString(m_ATRStats[i].profit / MathMax(1, m_ATRStats[i].wins), 2) + "\n";
        report += "  Avg. Loss: $" + DoubleToString(m_ATRStats[i].loss / MathMax(1, m_ATRStats[i].trades - m_ATRStats[i].wins), 2) + "\n";
    }
    
    // Phân tích kết luận
    report += "\n=== CONCLUSION ===\n";
    
    if (bestATRIndex >= 0) {
        report += "Best performance in ATR condition: " + atrLevels[bestATRIndex] + 
                  " (PF: " + DoubleToString(bestPF, 2) + ")\n";
    }
    
    if (m_RegimeStats[0].trades > 0 && m_RegimeStats[1].trades > 0) {
        report += "Comparison: Stable market " + 
                  (stablePF > transitionPF ? "outperforms" : "underperforms") + 
                  " transitioning market.\n";
    }
    
 // Khuyến nghị
    report += "\n=== RECOMMENDATIONS ===\n";
    
    // Dựa vào hiệu suất các chế độ thị trường
    if (stablePF > transitionPF * 1.5) {
        report += "- Cần hạn chế hoặc TRÁNH giao dịch trong thị trường chuyển tiếp\n";
        report += "- Tập trung vào chế độ thị trường ổn định\n";
    } else if (transitionPF > stablePF * 1.5) {
        report += "- Có thể xét TĂNG size cho giao dịch trong thị trường chuyển tiếp\n";
        report += "- Điều chỉnh tham số để nắm bắt cơ hội trong chuyển tiếp\n";
    } else {
        report += "- Duy trì cách tiếp cận hiện tại với cả hai loại thị trường\n";
    }
    
    // Khuyến nghị dựa vào ATR
    if (bestATRIndex >= 0) {
        // Đề xuất điều chỉnh dựa vào mức ATR hiệu quả nhất
        switch(bestATRIndex) {
            case 0: // Low ATR
                report += "- Xét TĂNG size khi ATR thấp (< 0.8x trung bình)\n";
                report += "- Có thể thu hẹp SL trong điều kiện này\n";
                break;
            case 1: // Below Avg ATR
                report += "- Điều kiện ATR thấp hơn trung bình hoạt động tốt\n";
                report += "- Có thể tối ưu bộ lọc để tìm kiếm setup trong điều kiện này\n";
                break;
            case 2: // Average ATR
                report += "- Điều kiện ATR trung bình cung cấp kết quả ổn định\n";
                report += "- Duy trì cài đặt hiện tại\n";
                break;
            case 3: // High ATR
                report += "- ATR cao cung cấp kết quả tốt - tối ưu cho điều kiện này\n";
                report += "- Xét điều chỉnh Trailing Stop để tận dụng biến động\n";
                break;
            case 4: // Very High ATR
                report += "- Biến động cực cao tạo kết quả tốt nhất\n";
                report += "- Cân nhắc chiến lược đặc biệt cho thị trường biến động cao\n";
                report += "- THẬN TRỌNG: Mẫu có thể nhỏ, xác nhận kết quả\n";
                break;
        }
    }
    
    // Khuyến nghị chung
    report += "\n- Drawdown hiện tại: " + DoubleToString(GetCurrentDrawdownPercent(), 2) + "%\n";
    
    return report;
}

//+------------------------------------------------------------------+
//| Lưu thống kê vào tệp                                            |
//+------------------------------------------------------------------+
bool CRiskManager::SaveStatsToFile(string filename)
{
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        string msg_save_error = "Không thể mở file để lưu thống kê: " + filename;
        if (m_Logger != NULL) m_Logger->LogError(msg_save_error);
        else Print("LỖI: " + msg_save_error);
        return false;
    }
    
    // Lưu thông tin tổng quát
    FileWriteInteger(fileHandle, m_TotalTrades);
    FileWriteInteger(fileHandle, m_Wins);
    FileWriteInteger(fileHandle, m_Losses);
    FileWriteDouble(fileHandle, m_ProfitSum);
    FileWriteDouble(fileHandle, m_LossSum);
    FileWriteDouble(fileHandle, m_MaxProfitTrade);
    FileWriteDouble(fileHandle, m_MaxLossTrade);
    FileWriteInteger(fileHandle, m_MaxConsecutiveWins);
    FileWriteInteger(fileHandle, m_MaxConsecutiveLosses);
    FileWriteDouble(fileHandle, m_PeakEquity);
    FileWriteDouble(fileHandle, m_MaxDrawdownRecorded);
    
    // Lưu thông tin trạng thái hiện tại
    FileWriteInteger(fileHandle, m_ConsecutiveWins);
    FileWriteInteger(fileHandle, m_ConsecutiveLosses);
    FileWriteDouble(fileHandle, m_DailyLoss);
    FileWriteDouble(fileHandle, m_WeeklyLoss);
    
    // Lưu Cluster Stats
    for (int i = 0; i < 3; i++) {
        FileWriteInteger(fileHandle, m_ClusterStats[i].trades);
        FileWriteInteger(fileHandle, m_ClusterStats[i].wins);
        FileWriteDouble(fileHandle, m_ClusterStats[i].profit);
        FileWriteDouble(fileHandle, m_ClusterStats[i].loss);
    }
    
    // Lưu Session Stats
    for (int i = 0; i < 5; i++) {
        FileWriteInteger(fileHandle, m_SessionStats[i].trades);
        FileWriteInteger(fileHandle, m_SessionStats[i].wins);
        FileWriteDouble(fileHandle, m_SessionStats[i].profit);
        FileWriteDouble(fileHandle, m_SessionStats[i].loss);
    }
    
    // Lưu ATR Stats
    for (int i = 0; i < 5; i++) {
        FileWriteDouble(fileHandle, m_ATRStats[i].atrLevel);
        FileWriteInteger(fileHandle, m_ATRStats[i].trades);
        FileWriteInteger(fileHandle, m_ATRStats[i].wins);
        FileWriteDouble(fileHandle, m_ATRStats[i].profit);
        FileWriteDouble(fileHandle, m_ATRStats[i].loss);
    }
    
    // Lưu Regime Stats
    for (int i = 0; i < 2; i++) {
        FileWriteInteger(fileHandle, (int)m_RegimeStats[i].isTransitioning);
        FileWriteInteger(fileHandle, m_RegimeStats[i].trades);
        FileWriteInteger(fileHandle, m_RegimeStats[i].wins);
        FileWriteDouble(fileHandle, m_RegimeStats[i].profit);
        FileWriteDouble(fileHandle, m_RegimeStats[i].loss);
    }
    
    FileClose(fileHandle);
    
    string msg_save_success = "Đã lưu thống kê vào file: " + filename;
    if (m_Logger != NULL) m_Logger->LogInfo(msg_save_success);
    else Print(msg_save_success);
    return true;
}

//+------------------------------------------------------------------+
//| Nạp thống kê từ tệp                                              |
//+------------------------------------------------------------------+
bool CRiskManager::LoadStatsFromFile(string filename)
{
    if (!FileIsExist(filename, FILE_COMMON)) {
        string msg_file_not_exist = "File thống kê không tồn tại: " + filename;
        if (m_Logger != NULL) m_Logger->LogWarning(msg_file_not_exist);
        else Print("CẢNH BÁO: " + msg_file_not_exist);
        return false;
    }
    
    int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        string msg_load_error = "Không thể mở file để đọc thống kê: " + filename;
        if (m_Logger != NULL) m_Logger->LogError(msg_load_error);
        else Print("LỖI: " + msg_load_error);
        return false;
    }
    
    // Đọc thông tin tổng quát
    m_TotalTrades = FileReadInteger(fileHandle);
    m_Wins = FileReadInteger(fileHandle);
    m_Losses = FileReadInteger(fileHandle);
    m_ProfitSum = FileReadDouble(fileHandle);
    m_LossSum = FileReadDouble(fileHandle);
    m_MaxProfitTrade = FileReadDouble(fileHandle);
    m_MaxLossTrade = FileReadDouble(fileHandle);
    m_MaxConsecutiveWins = FileReadInteger(fileHandle);
    m_MaxConsecutiveLosses = FileReadInteger(fileHandle);
    m_PeakEquity = FileReadDouble(fileHandle);
    m_MaxDrawdownRecorded = FileReadDouble(fileHandle);
    
    // Đọc thông tin trạng thái hiện tại
    m_ConsecutiveWins = FileReadInteger(fileHandle);
    m_ConsecutiveLosses = FileReadInteger(fileHandle);
    m_DailyLoss = FileReadDouble(fileHandle);
    m_WeeklyLoss = FileReadDouble(fileHandle);
    
    // Đọc Cluster Stats
    for (int i = 0; i < 3; i++) {
        m_ClusterStats[i].trades = FileReadInteger(fileHandle);
        m_ClusterStats[i].wins = FileReadInteger(fileHandle);
        m_ClusterStats[i].profit = FileReadDouble(fileHandle);
        m_ClusterStats[i].loss = FileReadDouble(fileHandle);
    }
    
    // Đọc Session Stats
    for (int i = 0; i < 5; i++) {
        m_SessionStats[i].trades = FileReadInteger(fileHandle);
        m_SessionStats[i].wins = FileReadInteger(fileHandle);
        m_SessionStats[i].profit = FileReadDouble(fileHandle);
        m_SessionStats[i].loss = FileReadDouble(fileHandle);
    }
    
    // Đọc ATR Stats
    for (int i = 0; i < 5; i++) {
        m_ATRStats[i].atrLevel = FileReadDouble(fileHandle);
        m_ATRStats[i].trades = FileReadInteger(fileHandle);
        m_ATRStats[i].wins = FileReadInteger(fileHandle);
        m_ATRStats[i].profit = FileReadDouble(fileHandle);
        m_ATRStats[i].loss = FileReadDouble(fileHandle);
    }
    
    // Đọc Regime Stats
    for (int i = 0; i < 2; i++) {
        m_RegimeStats[i].isTransitioning = (bool)FileReadInteger(fileHandle);
        m_RegimeStats[i].trades = FileReadInteger(fileHandle);
        m_RegimeStats[i].wins = FileReadInteger(fileHandle);
        m_RegimeStats[i].profit = FileReadDouble(fileHandle);
        m_RegimeStats[i].loss = FileReadDouble(fileHandle);
    }
    
    FileClose(fileHandle);
    
    string msg_load_success = "Đã tải thống kê từ file: " + filename;
    if (m_Logger != NULL) m_Logger->LogInfo(msg_load_success);
    else Print(msg_load_success);
    return true;
}

//+------------------------------------------------------------------+
//| V14.0: Tính chỉ số rủi ro thị trường tổng hợp                    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateMarketRiskIndex()
{
    double riskIndex = 0.0;
    double weights[8] = {0};  // Trọng số cho các thành phần
    double values[8] = {0};   // Giá trị từng thành phần
    
    // --- 1. Yếu tố Market Regime --- (trọng số: 25%)
    weights[0] = 25.0;
    // Chế độ thị trường ổn định ít rủi ro hơn
    if (m_CurrentRegime == REGIME_TRENDING_BULL || m_CurrentRegime == REGIME_TRENDING_BEAR) {
        values[0] = 30.0;  // Trend rõ, rủi ro trung bình
    } else if (m_CurrentRegime == REGIME_RANGING_STABLE) {
        values[0] = 50.0;  // Sideway ổn định, rủi ro cao hơn
    } else if (m_CurrentRegime == REGIME_RANGING_VOLATILE) {
        values[0] = 70.0;  // Sideway biến động, rủi ro cao
    } else if (m_CurrentRegime == REGIME_VOLATILE_EXPANSION || m_CurrentRegime == REGIME_VOLATILE_CONTRACTION) {
        values[0] = 85.0;  // Biến động cao, rủi ro rất cao
    }
    
    // Điều chỉnh theo độ tin cậy (regime tin cậy thấp = rủi ro cao hơn)
    values[0] += (1.0 - m_MarketRegimeConfidence) * 30.0;
    
    // --- 2. Yếu tố chuyển tiếp thị trường --- (trọng số: 15%)
    weights[1] = 15.0;
    values[1] = m_IsTransitioningMarket ? 90.0 : 10.0;
    
    // --- 3. Yếu tố biến động (ATR ratio) --- (trọng số: 20%)
    weights[2] = 20.0;
    if (m_ATRRatio < 0.7) values[2] = 30.0;       // Biến động thấp
    else if (m_ATRRatio < 1.0) values[2] = 20.0;  // Biến động dưới trung bình
    else if (m_ATRRatio < 1.2) values[2] = 30.0;  // Biến động trung bình
    else if (m_ATRRatio < 1.5) values[2] = 50.0;  // Biến động cao
    else if (m_ATRRatio < 2.0) values[2] = 75.0;  // Biến động rất cao
    else values[2] = 90.0;                        // Biến động cực cao
    
    // --- 4. Yếu tố Spread --- (trọng số: 10%)
    weights[3] = 10.0;
    if (m_SpreadRatio < 1.0) values[3] = 10.0;      // Spread thấp
    else if (m_SpreadRatio < 1.5) values[3] = 30.0; // Spread trung bình
    else if (m_SpreadRatio < 2.0) values[3] = 60.0; // Spread cao
    else values[3] = 90.0;                          // Spread rất cao
    
    // --- 5. Yếu tố Sessions --- (trọng số: 5%)
    weights[4] = 5.0;
    switch (m_CurrentSession) {
        case SESSION_EUROPEAN:
        case SESSION_AMERICAN:
        case SESSION_EUROPEAN_AMERICAN:
            values[4] = 20.0;  // Phiên chính, rủi ro thấp
            break;
        case SESSION_ASIAN:
            values[4] = 40.0;  // Phiên Á, rủi ro trung bình
            break;
        case SESSION_CLOSING:
            values[4] = 60.0;  // Phiên đóng cửa, rủi ro cao
            break;
        default:
            values[4] = 50.0;
    }
    
    // --- 6. Yếu tố chuỗi thắng/thua --- (trọng số: 5%)
    weights[5] = 5.0;
    if (m_ConsecutiveLosses > 2) {
        values[5] = 70.0 + (m_ConsecutiveLosses - 2) * 10.0; // Tăng rủi ro với mỗi lần thua
        values[5] = MathMin(values[5], 100.0);               // Giới hạn tối đa
    } else if (m_ConsecutiveWins > 2) {
        values[5] = 30.0 - (m_ConsecutiveWins - 2) * 5.0;    // Giảm rủi ro với mỗi lần thắng
        values[5] = MathMax(values[5], 10.0);                // Giới hạn tối thiểu
    } else {
        values[5] = 50.0; // Trung tính
    }
    
    // --- 7. Yếu tố Drawdown --- (trọng số: 15%)
    weights[6] = 15.0;
    double currentDD = GetCurrentDrawdownPercent();
    if (currentDD < 2.0) values[6] = 10.0;             // DD rất thấp
    else if (currentDD < m_DrawdownReduceThreshold) values[6] = 30.0 + (currentDD / m_DrawdownReduceThreshold) * 40.0; // DD dưới ngưỡng
    else values[6] = 70.0 + ((currentDD - m_DrawdownReduceThreshold) / (m_MaxDrawdownPercent - m_DrawdownReduceThreshold)) * 30.0; // DD trên ngưỡng
    
    // --- 8. Yếu tố tương quan thống kê --- (trọng số: 5%)
    weights[7] = 5.0;
    if (m_RegimeStats[m_IsTransitioningMarket ? 1 : 0].trades >= 10) {
        double winRate = GetRegimeWinRate(m_IsTransitioningMarket);
        double pf = GetRegimeProfitFactor(m_IsTransitioningMarket);
        
        if (winRate < 40.0 || pf < 0.8) {
            values[7] = 80.0; // Điều kiện hiệu suất kém
        } else if (winRate > 60.0 && pf > 1.5) {
            values[7] = 20.0; // Điều kiện hiệu suất tốt
        } else {
            values[7] = 50.0; // Trung bình
        }
    } else {
        values[7] = 50.0; // Không đủ dữ liệu
    }
    
    // Tính chỉ số rủi ro tổng hợp (trung bình có trọng số)
    double totalWeight = 0.0;
    double weightedSum = 0.0;
    
    for (int i = 0; i < 8; i++) {
        weightedSum += weights[i] * values[i];
        totalWeight += weights[i];
    }
    
    riskIndex = weightedSum / totalWeight;
    
    // Log chi tiết
    if (m_Logger != NULL) {
        string riskDetails = "Risk Index Components:\n";
        string componentNames[] = {"Market Regime", "Transitioning", "ATR Ratio", "Spread", 
                                "Session", "Win/Loss Streak", "Drawdown", "Performance"};
        
        for (int i = 0; i < 8; i++) {
            riskDetails += StringFormat("  %s: %.1f (weight: %.1f%%)\n", 
                                     componentNames[i], values[i], weights[i]);
        }
        
        riskDetails += "FINAL RISK INDEX: " + DoubleToString(riskIndex, 1) + "%";
        m_Logger->LogInfo(riskDetails);
    }
    
    return riskIndex;
}

//+------------------------------------------------------------------+
//| V14.0: Kiểm tra điều kiện thị trường an toàn                     |
//+------------------------------------------------------------------+
bool CRiskManager::IsSafeMarketCondition()
{
    // Tính chỉ số rủi ro
    double riskIndex = CalculateMarketRiskIndex();
    
    // Các ngưỡng rủi ro
    double safeThreshold = 40.0;    // Dưới ngưỡng này là an toàn
    double warningThreshold = 60.0; // Trên ngưỡng này là cảnh báo
    double dangerThreshold = 80.0;  // Trên ngưỡng này là nguy hiểm
    
    // Chế độ Prop Firm sử dụng ngưỡng nghiêm ngặt hơn
    if (m_PropFirmMode) {
        safeThreshold = 30.0;
        warningThreshold = 50.0;
        dangerThreshold = 70.0;
    }
    
    // Xét các điều kiện
    if (riskIndex <= safeThreshold) {
        // Điều kiện an toàn
        return true;
    } else if (riskIndex > dangerThreshold) {
        // Điều kiện nguy hiểm
        string msg_danger = "Điều kiện thị trường nguy hiểm (Risk: " + DoubleToString(riskIndex, 1) + "%)";
        if (m_Logger != NULL) m_Logger->LogCritical(msg_danger);
        else Print("NGHIÊM TRỌNG: " + msg_danger);
        return false;
    } else if (riskIndex > warningThreshold) {
        // Điều kiện cảnh báo - tùy thuộc vào các yếu tố khác
        
        // Nếu đang có lợi nhuận trong ngày, có thể chấp nhận rủi ro cao hơn
        double dailyPL = m_AccountInfo.Equity() - m_DayStartEquity;
        if (dailyPL > 0) {
            string msg_warning_profit = "Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%), nhưng có lợi nhuận trong ngày";
            if (m_Logger != NULL) m_Logger->LogWarning(msg_warning_profit);
            else Print("CẢNH BÁO: " + msg_warning_profit);
            return true;
        }
        
        // Nếu chuỗi thắng, có thể chấp nhận rủi ro cao hơn
        if (m_ConsecutiveWins >= 3) {
            string msg_warning_streak = "Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%), nhưng có chuỗi thắng " + IntegerToString(m_ConsecutiveWins);
            if (m_Logger != NULL) m_Logger->LogWarning(msg_warning_streak);
            else Print("CẢNH BÁO: " + msg_warning_streak);
            return true;
        }
        
        // Mặc định cảnh báo là không an toàn
        string msg_warning = "Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%)";
        if (m_Logger != NULL) m_Logger->LogWarning(msg_warning);
        else Print("CẢNH BÁO: " + msg_warning);
        return false;
    } else {
        // Điều kiện trung bình - vẫn an toàn
        return true;
    }
}

//+------------------------------------------------------------------+
//| V14.0: Ghi log trạng thái quản lý rủi ro                         |
//+------------------------------------------------------------------+
void CRiskManager::LogRiskStatus(bool forceLog = false)
{
    static datetime lastLogTime = 0;
    datetime currentTime = TimeCurrent();
    
    // Chỉ log mỗi 10 phút hoặc khi được yêu cầu
    if (!forceLog && currentTime - lastLogTime < 600) {
        return;
    }
    
    lastLogTime = currentTime;
    
    double currentDD = GetCurrentDrawdownPercent();
    double dailyLossPercent = GetDailyLossPercent();
    double adaptiveRisk = CalculateAdaptiveRiskPercent();
    
    string riskStatus = "=== RISK STATUS ===\n";
    riskStatus += "Time: " + TimeToString(currentTime, TIME_DATE|TIME_MINUTES) + "\n";
    riskStatus += "Symbol: " + m_Symbol + "\n";
    riskStatus += "Current DD: " + DoubleToString(currentDD, 2) + "% (Max: " + 
                 DoubleToString(m_MaxDrawdownRecorded, 2) + "%)\n";
    riskStatus += "Daily Loss: " + DoubleToString(dailyLossPercent, 2) + "% of " + 
                 DoubleToString(m_DayStartEquity, 2) + " (Max: " + 
                 DoubleToString(m_MaxDailyLossPercent, 2) + "%)\n";
    riskStatus += "Base Risk: " + DoubleToString(m_RiskPerTrade, 2) + 
                 "%, Adaptive Risk: " + DoubleToString(adaptiveRisk, 2) + "%\n";
    riskStatus += "Daily Trades: " + IntegerToString(m_DailyTradeCount) + "/" + 
                 IntegerToString(m_MaxDailyTrades) + "\n";
    riskStatus += "Consecutive Wins/Losses: +" + IntegerToString(m_ConsecutiveWins) + 
                 "/-" + IntegerToString(m_ConsecutiveLosses) + "\n";
    
    if (m_PauseUntil > TimeCurrent()) {
        riskStatus += "Status: PAUSED until " + TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES) + "\n";
    }
    
    // Hiệu suất
    if (m_TotalTrades > 0) {
        riskStatus += "Performance: " + IntegerToString(m_TotalTrades) + " trades, " + 
                     DoubleToString(GetWinRate(), 1) + "% WR, PF " + 
                     DoubleToString(GetProfitFactor(), 2) + "\n";
    }
    
    // Thông tin chế độ thị trường
    string regimeNames[] = {"Trend Bull", "Trend Bear", "Range Stable", "Range Volatile", 
                         "Volatile Expansion", "Volatile Contraction"};
    
    riskStatus += "Market: " + regimeNames[m_CurrentRegime] + 
                 (m_IsTransitioningMarket ? " (TRANSITIONING)" : " (STABLE)") + "\n";
    riskStatus += "ATR Ratio: " + DoubleToString(m_ATRRatio, 2) + "x, " + 
                 "Spread Ratio: " + DoubleToString(m_SpreadRatio, 2) + "x\n";
    
    // Chỉ số rủi ro
    double riskIndex = CalculateMarketRiskIndex();
    riskStatus += "Risk Index: " + DoubleToString(riskIndex, 1) + "% - " + 
                 (riskIndex < 50 ? "LOW" : (riskIndex < 75 ? "MEDIUM" : "HIGH")) + "\n";
    
    LogMessage(riskStatus, forceLog);
}

//+------------------------------------------------------------------+
//| V14.0: Vẽ dashboard rủi ro trên biểu đồ                          |
//+------------------------------------------------------------------+
void CRiskManager::DrawRiskDashboard()
{
    // Xóa các đối tượng dashboard cũ
    ObjectsDeleteAll(0, "RM_Dash_");
    
    // Định vị dashboard
    int x = 20;
    int y = 20;
    int width = 250;
    int height = 180;
    int lineHeight = 20;
    
    // Vẽ background
    ObjectCreate(0, "RM_Dash_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_XSIZE, width);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_YSIZE, height);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_BGCOLOR, clrWhiteSmoke);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_COLOR, clrDarkGray);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_BG", OBJPROP_ZORDER, 0);
    
    // Tiêu đề
    ObjectCreate(0, "RM_Dash_Title", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_YDISTANCE, y + 10);
    ObjectSetString(0, "RM_Dash_Title", OBJPROP_TEXT, "RISK MONITOR");
    ObjectSetString(0, "RM_Dash_Title", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_FONTSIZE, 10);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_COLOR, clrNavy);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_Title", OBJPROP_ZORDER, 1);
    
    // Drawdown
    double currentDD = GetCurrentDrawdownPercent();
    color ddColor = (currentDD < m_DrawdownReduceThreshold) ? clrDarkGreen : 
                   (currentDD < m_MaxDrawdownPercent) ? clrDarkOrange : clrDarkRed;
    
    ObjectCreate(0, "RM_Dash_DD", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_YDISTANCE, y + 35);
    ObjectSetString(0, "RM_Dash_DD", OBJPROP_TEXT, "Drawdown: " + DoubleToString(currentDD, 2) + "%");
    ObjectSetString(0, "RM_Dash_DD", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_COLOR, ddColor);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_DD", OBJPROP_ZORDER, 1);
    
    // Risk thích ứng
    double adaptiveRisk = CalculateAdaptiveRiskPercent();
    
    ObjectCreate(0, "RM_Dash_Risk", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_YDISTANCE, y + 55);
    ObjectSetString(0, "RM_Dash_Risk", OBJPROP_TEXT, "Risk: " + DoubleToString(adaptiveRisk, 2) + "%");
    ObjectSetString(0, "RM_Dash_Risk", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_Risk", OBJPROP_ZORDER, 1);
    
    // Trades
    ObjectCreate(0, "RM_Dash_Trades", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_YDISTANCE, y + 75);
    ObjectSetString(0, "RM_Dash_Trades", OBJPROP_TEXT, "Trades: " + IntegerToString(m_DailyTradeCount) + 
                  "/" + IntegerToString(m_MaxDailyTrades));
    ObjectSetString(0, "RM_Dash_Trades", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_COLOR, clrBlack);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_Trades", OBJPROP_ZORDER, 1);
    
    // Chuỗi thắng/thua
    string streakText = "Streak: ";
    if (m_ConsecutiveWins > 0) {
        streakText += "+" + IntegerToString(m_ConsecutiveWins) + " wins";
    } else if (m_ConsecutiveLosses > 0) {
        streakText += "-" + IntegerToString(m_ConsecutiveLosses) + " losses";
    } else {
        streakText += "neutral";
    }
    
    color streakColor = (m_ConsecutiveWins > 0) ? clrDarkGreen : 
                       (m_ConsecutiveLosses > 0) ? clrDarkRed : clrBlack;
    
    ObjectCreate(0, "RM_Dash_Streak", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_YDISTANCE, y + 95);
    ObjectSetString(0, "RM_Dash_Streak", OBJPROP_TEXT, streakText);
    ObjectSetString(0, "RM_Dash_Streak", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_COLOR, streakColor);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_Streak", OBJPROP_ZORDER, 1);
    
    // Chỉ số rủi ro
    double riskIndex = CalculateMarketRiskIndex();
    string riskLabel = "Risk Index: " + DoubleToString(riskIndex, 1) + "% - ";
    
    if (riskIndex < 50) riskLabel += "LOW";
    else if (riskIndex < 75) riskLabel += "MEDIUM";
    else riskLabel += "HIGH";
    
    color riskIndexColor = (riskIndex < 50) ? clrDarkGreen : 
                          (riskIndex < 75) ? clrDarkOrange : clrDarkRed;
    
    ObjectCreate(0, "RM_Dash_RiskIndex", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_YDISTANCE, y + 115);
    ObjectSetString(0, "RM_Dash_RiskIndex", OBJPROP_TEXT, riskLabel);
    ObjectSetString(0, "RM_Dash_RiskIndex", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_COLOR, riskIndexColor);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_RiskIndex", OBJPROP_ZORDER, 1);
    
    // Trạng thái EA
    string statusText = "Status: ";
    color statusColor = clrBlack;
    
    if (m_PauseUntil > TimeCurrent()) {
        statusText += "PAUSED until " + TimeToString(m_PauseUntil, TIME_MINUTES);
        statusColor = clrDarkRed;
    } else if (IsSafeMarketCondition()) {
        statusText += "ACTIVE - SAFE";
        statusColor = clrDarkGreen;
    } else {
        statusText += "ACTIVE - CAUTION";
        statusColor = clrDarkOrange;
    }
    
    ObjectCreate(0, "RM_Dash_Status", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_XDISTANCE, x + 10);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_YDISTANCE, y + 135);
    ObjectSetString(0, "RM_Dash_Status", OBJPROP_TEXT, statusText);
    ObjectSetString(0, "RM_Dash_Status", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_COLOR, statusColor);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_BACK, false);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, "RM_Dash_Status", OBJPROP_ZORDER, 1);
    
    // Làm mới biểu đồ
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Tính giá trị heat của portfolio                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetPortfolioHeatValue(double volume, bool isBuy)
{
    // Đơn giản hóa - heat dựa trên số lượng vị thế đang mở và volume mới
    double currentHeat = 0.0;
    
    // Kiểm tra các vị thế hiện tại
    for (int i = 0; i < PositionsTotal(); i++) {
        ulong posTicket = PositionGetTicket(i);
        if (posTicket <= 0) continue;
        
        // Chỉ xét vị thế trên symbol hiện tại
        if (PositionGetString(POSITION_SYMBOL) != m_Symbol) continue;
        
        // Xét direction
        long posType = PositionGetInteger(POSITION_TYPE);
        bool isLong = (posType == POSITION_TYPE_BUY);
        
        // Lấy volume
        double posVolume = PositionGetDouble(POSITION_VOLUME);
        
        // Tính contribution to heat
        if (isLong == isBuy) {
            // Same direction - heat tăng
            currentHeat += posVolume;
        } else {
            // Opposite direction - hedging, heat giảm
            currentHeat -= posVolume * 0.5; // Giảm 50% khi hedge
        }
    }
    
    // Thêm volume của lệnh mới
    currentHeat += volume;
    
    // Điều chỉnh theo tương quan
    currentHeat *= GetCorrelationAdjustment(isBuy);
    
    return currentHeat;
}

//+------------------------------------------------------------------+
//| Tính điều chỉnh theo tương quan                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetCorrelationAdjustment(bool isBuy)
{
    // Đơn giản hóa - giả sử mối tương quan cố định với thị trường
    // Trong thực tế, cần một hệ thống phức tạp hơn để tính tương quan 
    
    // Kiểm tra chế độ thị trường và direction
    if (isBuy) {
        if (m_CurrentRegime == REGIME_TRENDING_BULL) {
            return 0.8;  // Mua trong thị trường tăng - ít rủi ro hơn
        } else if (m_CurrentRegime == REGIME_TRENDING_BEAR) {
            return 1.3;  // Mua trong thị trường giảm - rủi ro cao hơn
        }
    } else { // Sell
        if (m_CurrentRegime == REGIME_TRENDING_BEAR) {
            return 0.8;  // Bán trong thị trường giảm - ít rủi ro hơn
        } else if (m_CurrentRegime == REGIME_TRENDING_BULL) {
            return 1.3;  // Bán trong thị trường tăng - rủi ro cao hơn
        }
    }
    
    // Mặc định
    return 1.0;
}

//+------------------------------------------------------------------+
//| Chuẩn hóa lot size theo quy tắc của sàn                          |
//+------------------------------------------------------------------+
double CRiskManager::NormalizeEntryLots(double calculatedLots)
{
    // Lấy thông tin symbol
    double minLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP);
    
    // Đảm bảo không dưới min lot
    calculatedLots = MathMax(calculatedLots, minLot);
    
    // Đảm bảo không quá max lot
    calculatedLots = MathMin(calculatedLots, maxLot);
    
    // Làm tròn theo lot step
    calculatedLots = MathFloor(calculatedLots / lotStep) * lotStep;
    
    // Chế độ propfirm - giới hạn thêm
    if (m_PropFirmMode) {
        // Giới hạn tối đa cho propfirm, thường 0.5-1.0 lot tùy tài khoản
        double propMaxLot = 1.0;
        
        // Tài khoản nhỏ (< $20,000) - giới hạn hơn
        if (m_AccountInfo.Balance() < 20000) {
            propMaxLot = 0.5;
        } else if (m_AccountInfo.Balance() < 50000) {
            propMaxLot = 1.0;
        } else if (m_AccountInfo.Balance() < 100000) {
            propMaxLot = 2.0;
        } else {
            propMaxLot = 5.0;
        }
        
        calculatedLots = MathMin(calculatedLots, propMaxLot);
    }
    
    return NormalizeDouble(calculatedLots, 2);
}

//+------------------------------------------------------------------+
//| Ghi log message                                                  |
//+------------------------------------------------------------------+
void CRiskManager::LogMessage(string message, bool isImportant = false)
{
    // Sử dụng logger thông qua con trỏ, kiểm tra NULL trước khi sử dụng
    if (m_Logger != NULL) {
        if (isImportant) {
            m_Logger.LogWarning(StringFormat("RiskManager: %s", message));
        } else {
            m_Logger.LogInfo(StringFormat("RiskManager: %s", message));
        }
    }
}

//+------------------------------------------------------------------+
//| V14.0: Thích ứng thông minh với điều kiện thị trường dài hạn     |
//+------------------------------------------------------------------+
bool CRiskManager::AdaptToMarketCycle()
{
    if (m_MarketProfile == NULL) {
        LogMessage("Không thể thích ứng chu kỳ thị trường: MarketProfile chưa được khởi tạo", true);
        return false;
    }
    
    // Phân tích chu kỳ dài hạn
    bool isBullMarket = false;
    bool isBearMarket = false;
    bool isChoppyMarket = false;
    
    // Phân tích EMA
    double ema50 = 0, ema100 = 0, ema200 = 0;
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    
    int ema50Handle = iMA(m_Symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);
    int ema100Handle = iMA(m_Symbol, PERIOD_D1, 100, 0, MODE_EMA, PRICE_CLOSE);
    int ema200Handle = iMA(m_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    if (ema50Handle != INVALID_HANDLE && ema100Handle != INVALID_HANDLE && ema200Handle != INVALID_HANDLE) {
        double ema50Buffer[], ema100Buffer[], ema200Buffer[];
        
        bool hasEma50 = CopyBuffer(ema50Handle, 0, 0, 1, ema50Buffer) > 0;
        bool hasEma100 = CopyBuffer(ema100Handle, 0, 0, 1, ema100Buffer) > 0;
        bool hasEma200 = CopyBuffer(ema200Handle, 0, 0, 1, ema200Buffer) > 0;
        
        IndicatorRelease(ema50Handle);
        IndicatorRelease(ema100Handle);
        IndicatorRelease(ema200Handle);
        
        if (hasEma50 && hasEma100 && hasEma200) {
            ema50 = ema50Buffer[0];
            ema100 = ema100Buffer[0];
            ema200 = ema200Buffer[0];
            
            // Xác định kiểu thị trường dựa trên sự sắp xếp của EMA
            if (ema50 > ema100 && ema100 > ema200 && currentPrice > ema50) {
                isBullMarket = true;
            } else if (ema50 < ema100 && ema100 < ema200 && currentPrice < ema50) {
                isBearMarket = true;
            } else if (MathAbs(ema50 - ema100) < 0.0001 * currentPrice && 
                      MathAbs(ema100 - ema200) < 0.0001 * currentPrice) {
                isChoppyMarket = true;
            }
        }
    }
    
    // Thay đổi tham số dựa trên phân tích thị trường
    if (isBullMarket) {
        m_TrendTradeRatio = 0.7;  // 70% lệnh theo xu hướng
        m_CounterTradeRatio = 0.3; // 30% lệnh đảo chiều
        m_PriceActionThreshold = 0.6; // Ngưỡng Price Action
        m_PreferredScenario = SCENARIO_PULLBACK;
        
        LogMessage("Điều chỉnh theo Bull Market: 70% theo trend, 30% counter-trend", false);
        return true;
    } 
    else if (isBearMarket) {
        m_TrendTradeRatio = 0.7;  // 70% lệnh theo xu hướng
        m_CounterTradeRatio = 0.3; // 30% lệnh đảo chiều
        m_PriceActionThreshold = 0.6; // Ngưỡng Price Action
        m_PreferredScenario = SCENARIO_PULLBACK;
        
        LogMessage("Điều chỉnh theo Bear Market: 70% theo trend, 30% counter-trend", false);
        return true;
    } 
    else if (isChoppyMarket) {
        m_TrendTradeRatio = 0.3;  // 30% lệnh theo xu hướng
        m_CounterTradeRatio = 0.7; // 70% lệnh đảo chiều
        m_PriceActionThreshold = 0.8; // Ngưỡng Price Action cao hơn
        m_PreferredScenario = SCENARIO_REVERSAL;
        
        LogMessage("Điều chỉnh theo Choppy Market: 30% theo trend, 70% counter-trend", false);
        return true;
    } 
    else {
        m_TrendTradeRatio = 0.5;  // Cân bằng
        m_CounterTradeRatio = 0.5; // Cân bằng
        m_PriceActionThreshold = 0.7; // Ngưỡng Price Action trung bình
        m_PreferredScenario = SCENARIO_NONE;
        
        LogMessage("Điều chỉnh theo thị trường không xác định: Cân bằng 50/50", false);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Tính toán biến động dài hạn                                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLongTermVolatility()
{
    // Biến động dài hạn = ATR hiện tại / ATR trung bình 30 ngày
    int atrHistorySize = ArraySize(m_ATRHistory);
    if (atrHistorySize < 30) {
        return 1.0; // Mặc định nếu không đủ dữ liệu
    }
    
    double sum = 0.0;
    for (int i = 0; i < 30 && i < atrHistorySize; i++) {
        sum += m_ATRHistory[i];
    }
    
    double avgATR = sum / 30.0;
    if (avgATR <= 0) return 1.0;
    
    return m_AverageATR / avgATR;
}

//+------------------------------------------------------------------+
//| Tính toán tốc độ thay đổi biến động                              |
//+------------------------------------------------------------------+
double CRiskManager::CalculateVolatilityChangeRate()
{
    // Tính tốc độ thay đổi biến động trong 7 ngày gần đây
    int atrHistorySize = ArraySize(m_ATRHistory);
    if (atrHistorySize < 7) {
        return 0.0; // Mặc định nếu không đủ dữ liệu
    }
    
    double recentATR = 0.0;
    double olderATR = 0.0;
    
    // ATR trung bình 3 ngày gần đây
    for (int i = 0; i < 3 && i < atrHistorySize; i++) {
        recentATR += m_ATRHistory[i];
    }
    recentATR /= 3.0;
    
    // ATR trung bình 3 ngày trước đó
    for (int i = 4; i < 7 && i < atrHistorySize; i++) {
        olderATR += m_ATRHistory[i];
    }
    olderATR /= 3.0;
    
    if (olderATR <= 0) return 0.0;
    
    // Tốc độ thay đổi
    return (recentATR - olderATR) / olderATR;
}



bool CRiskManager::IsDrawdownExceeded()
{
    double currentDD = GetCurrentDrawdownPercent();
    return currentDD > m_MaxDrawdownPercent;
}

bool CRiskManager::IsDailyLossExceeded()
{
    double dailyLossPercent = GetDailyLossPercent();
    return dailyLossPercent > m_MaxDailyLossPercent;
}

void CRiskManager::SetDetailedLogging(bool enable)
{
    m_DetailedLogging = enable;
    
    if (m_Logger != NULL) {
        LogMessage("Detailed logging " + (enable ? "enabled" : "disabled"), false);
    }
}

bool CRiskManager::IsMarketConditionSafe()
{
    double riskIndex = CalculateMarketRiskIndex();
    double safeThreshold = 40.0;
    double warningThreshold = 60.0;
    double dangerThreshold = 80.0;
    
    if (m_PropFirmMode) {
        safeThreshold = 30.0;
        warningThreshold = 50.0;
        dangerThreshold = 70.0;
    }
    
    if (riskIndex <= safeThreshold) {
        return true;
    } else if (riskIndex > dangerThreshold) {
        LogMessage("Điều kiện thị trường nguy hiểm (Risk: " + DoubleToString(riskIndex, 1) + "%)", true);
        return false;
    } else if (riskIndex > warningThreshold) {
        double dailyPL = m_AccountInfo.Equity() - m_DayStartEquity;
        if (dailyPL > 0) {
            LogMessage("Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%), nhưng có lợi nhuận trong ngày", false);
            return true;
        }
        
        if (m_ConsecutiveWins >= 3) {
            LogMessage("Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%), nhưng có chuỗi thắng " + IntegerToString(m_ConsecutiveWins), false);
            return true;
        }
        
        LogMessage("Điều kiện thị trường cảnh báo (Risk: " + DoubleToString(riskIndex, 1) + "%)", false);
        return false;
    } else {
        return true;
    }
}

// Các hàm GetRegimeFactor, GetSessionFactor, GetSymbolRiskFactor cần được định nghĩa ở đây
// hoặc trong một file khác và được include.
// Ví dụ mẫu (cần thay thế bằng logic thực tế):
double CRiskManager::GetRegimeFactor(ENUM_MARKET_REGIME regime, bool isTransitioning)
{
    // TODO: Implement actual logic based on regime and transition status
    if (isTransitioning) return 0.75; // Giảm risk khi thị trường chuyển tiếp
    switch(regime)
    {
        case REGIME_TRENDING_BULL:
        case REGIME_TRENDING_BEAR: return 1.0; // Risk bình thường trong trend
        case REGIME_RANGING_TIGHT:
        case REGIME_RANGING_WIDE: return 0.8; // Giảm risk khi ranging
        case REGIME_VOLATILE_BREAKOUT: return 1.2; // Có thể tăng nhẹ risk khi breakout
        default: return 1.0;
    }
}

double CRiskManager::GetSessionFactor(ENUM_SESSION session, string symbol)
{
    // TODO: Implement actual logic based on session and symbol
    // Ví dụ: Giảm risk ngoài phiên chính
    if (session == SESSION_LONDON || session == SESSION_NEWYORK) return 1.0;
    return 0.7;
}

double CRiskManager::GetSymbolRiskFactor(string symbol)
{
    // TODO: Implement actual logic based on symbol characteristics
    // Ví dụ: Giảm risk cho các cặp tiền tệ chéo hoặc exotic
    if (StringFind(symbol, "JPY") != -1 && StringFind(symbol, "USD") == -1 && StringFind(symbol, "EUR") == -1)
        return 0.8; // Giảm risk cho các cặp JPY chéo
    return 1.0;
}

} // namespace ApexPullback

#endif // RISK_MANAGER_MQH_