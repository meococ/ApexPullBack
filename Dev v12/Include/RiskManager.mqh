//+------------------------------------------------------------------+
//|                                                  RiskManager.mqh |
//|                       Module Quản lý Rủi ro và Vốn Nâng cao      |
//|                              Version 13.0 - ApexPullback EA      |
//+------------------------------------------------------------------+
#property copyright "ApexPullback"
#property version   "13.0"
#property strict

#include <Trade/AccountInfo.mqh> // Sử dụng AccountInfo cho kiểm tra balance/equity
#include <Trade/SymbolInfo.mqh>  // Sử dụng SymbolInfo cho thuộc tính của symbol
#include "CommonStructs.mqh"     // Enums và structs chung
#include "Logger.mqh"            // Tiện ích ghi log

//+------------------------------------------------------------------+
//| Class CRiskManager                                               |
//| Quản lý rủi ro: risk adaptation, position sizing, bảo vệ tài     |
//| khoản, theo dõi hiệu suất, và nhận thức danh mục đầu tư          |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    // --- Thông tin cài đặt ---
    string              m_Symbol;               // Symbol chính EA đang chạy
    double              m_RiskPerTrade;         // Risk mỗi giao dịch theo phần trăm balance
    double              m_MaxDailyLossPercent;  // Giới hạn lỗ tối đa trong ngày (% của start equity)
    double              m_MaxDrawdownPercent;   // Giới hạn drawdown tối đa (% của balance/equity)
    int                 m_MaxDailyTrades;       // Số lệnh tối đa mỗi ngày
    int                 m_MaxConsecutiveLosses; // Số lần thua liên tiếp tối đa trước khi tạm dừng
    bool                m_PropFirmMode;         // Chế độ Prop firm (quản lý rủi ro nghiêm ngặt hơn)
    double              m_DrawdownReduceThreshold; // Ngưỡng DD để bắt đầu giảm risk
    double              m_MinRiskMultiplier;    // Hệ số giảm risk tối thiểu (VD: 0.3 = 30%)
    bool                m_EnableTaperedRisk;    // Bật chế độ giảm risk từ từ (không đột ngột)

    // --- Theo dõi trạng thái trong ngày ---
    double              m_DayStartEquity;       // Equity ban đầu của ngày giao dịch hiện tại
    int                 m_DailyTradeCount;      // Số lệnh đã thực hiện trong ngày
    int                 m_ConsecutiveLosses;    // Số lần thua liên tiếp hiện tại
    int                 m_ConsecutiveWins;      // Số lần thắng liên tiếp hiện tại
    double              m_PeakEquity;           // Equity cao nhất đạt được
    double              m_MaxDrawdownRecorded;  // Drawdown tối đa đã ghi nhận (%)
    datetime            m_PauseUntil;           // Thời gian tạm dừng đến khi
    datetime            m_LastStatsUpdate;      // Thời gian cập nhật thống kê cuối

    // --- Performance Tracker ---
    int                 m_TotalTrades;          // Tổng số giao dịch
    int                 m_Wins;                 // Số lần thắng
    int                 m_Losses;               // Số lần thua
    double              m_ProfitSum;            // Tổng lợi nhuận
    double              m_LossSum;              // Tổng lỗ
    double              m_MaxProfitTrade;       // Giao dịch lãi lớn nhất
    double              m_MaxLossTrade;         // Giao dịch lỗ lớn nhất (giá trị dương)
    int                 m_MaxConsecutiveWins;   // Số lần thắng liên tiếp lớn nhất
    int                 m_MaxConsecutiveLosses; // Số lần thua liên tiếp lớn nhất
    
    // --- Thông tin market regime ---
    bool                m_IsTransitioningMarket; // Thị trường đang trong giai đoạn chuyển tiếp
    double              m_MarketRegimeConfidence; // Độ tin cậy của chế độ thị trường (0-1)
    double              m_ATRRatio;              // Tỉ lệ ATR hiện tại so với ATR trung bình
    
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

    // --- Công cụ hỗ trợ ---
    CAccountInfo        m_AccountInfo;         // Đối tượng thông tin tài khoản
    CSymbolInfo         m_SymbolInfo;          // Đối tượng thông tin symbol
    CLogger*            m_Logger;              // Con trỏ đến logger (không sở hữu)

public:
    // --- Constructor/Destructor ---
    CRiskManager();
    ~CRiskManager();

    // --- Hàm Khởi tạo ---
    bool Initialize(string symbol, double riskPercent, bool propMode, double maxDailyLoss, 
                  double maxDrawdown, int maxDailyTrades, int maxConsecutiveLosses, 
                  double dayStartEquity, double drawdownReduceThreshold = 5.0);

    // Thiết lập logger
    void SetLogger(CLogger* logger) { m_Logger = logger; }
    
    // --- Thiết lập các tham số nâng cao ---
    void SetDrawdownProtectionParams(double drawdownReduceThreshold, double minRiskMultiplier = 0.3, 
                                  bool enableTaperedRisk = true);
    void SetMarketRegimeInfo(bool isTransitioning, double regimeConfidence, double atrRatio);
    
    // --- Tính toán mức risk động ---
    double CalculateAdaptiveRiskPercent();
    
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

    // --- Hàm mới thêm vào cho v13 ---
    double CalculateMarketRiskIndex();
    bool IsSafeMarketCondition();
    void LogRiskStatus(bool forceLog = false);

private:
    // --- Helper functions ---
    int GetCurrentDayOfYear();
    double GetPortfolioHeatValue(double volume, bool isBuy);
    double GetCorrelationAdjustment(bool isBuy);
    double CalculateATRBasedLotSizeAdjustment(double atrRatio);
    void LogMessage(string message, bool isImportant = false);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager()
{
    // Giá trị mặc định (có thể được ghi đè bởi Initialize)
    m_Symbol = "";
    m_RiskPerTrade = 1.0;
    m_MaxDailyLossPercent = 5.0;
    m_MaxDrawdownPercent = 10.0;
    m_MaxDailyTrades = 10;
    m_MaxConsecutiveLosses = 3;
    m_PropFirmMode = false;
    m_DrawdownReduceThreshold = 5.0;
    m_MinRiskMultiplier = 0.3;
    m_EnableTaperedRisk = true;

    m_DayStartEquity = 0;
    m_DailyTradeCount = 0;
    m_ConsecutiveLosses = 0;
    m_ConsecutiveWins = 0;
    m_PeakEquity = 0;
    m_MaxDrawdownRecorded = 0;
    m_PauseUntil = 0;
    m_LastStatsUpdate = 0;

    m_TotalTrades = 0;
    m_Wins = 0;
    m_Losses = 0;
    m_ProfitSum = 0;
    m_LossSum = 0;
    m_MaxProfitTrade = 0;
    m_MaxLossTrade = 0;
    m_MaxConsecutiveWins = 0;
    m_MaxConsecutiveLosses = 0;
    
    m_IsTransitioningMarket = false;
    m_MarketRegimeConfidence = 1.0;
    m_ATRRatio = 1.0;
    
    m_Logger = NULL;

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
    // Không cần phải giải phóng m_Logger vì nó chỉ là con trỏ tham chiếu
    m_Logger = NULL;
}

//+------------------------------------------------------------------+
//| Khởi tạo với các tham số                                         |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize(string symbol, double riskPercent, bool propMode, double maxDailyLoss, 
                            double maxDrawdown, int maxDailyTrades, int maxConsecutiveLosses, 
                            double dayStartEquity, double drawdownReduceThreshold = 5.0)
{
    m_Symbol = symbol;
    m_RiskPerTrade = riskPercent;
    m_MaxDailyLossPercent = maxDailyLoss;
    m_MaxDrawdownPercent = maxDrawdown;
    m_MaxDailyTrades = maxDailyTrades;
    m_MaxConsecutiveLosses = maxConsecutiveLosses;
    m_PropFirmMode = propMode;
    m_DrawdownReduceThreshold = drawdownReduceThreshold;

    // Thiết lập thống kê ban đầu
    m_DayStartEquity = (dayStartEquity > 0) ? dayStartEquity : m_AccountInfo.Equity();
    m_DailyTradeCount = 0;
    
    // Khởi tạo PeakEquity ban đầu
    m_PeakEquity = m_AccountInfo.Equity();
    
    // Khởi tạo symbol info
    m_SymbolInfo.Name(m_Symbol);
    
    // Áp dụng cài đặt đặc biệt cho Prop Firm Mode
    if (m_PropFirmMode) {
        // Giảm risk nếu > 1.0% trong chế độ prop firm
        if (m_RiskPerTrade > 1.0) {
            LogMessage("PROP FIRM MODE: Giảm risk từ " + DoubleToString(m_RiskPerTrade, 2) + 
                      "% xuống 1.0% (giới hạn an toàn)", true);
            m_RiskPerTrade = 1.0;
        }
        
        // Giảm max drawdown nếu > 5.0% trong chế độ prop firm
        if (m_MaxDrawdownPercent > 5.0) {
            LogMessage("PROP FIRM MODE: Giảm max drawdown từ " + DoubleToString(m_MaxDrawdownPercent, 2) + 
                      "% xuống 5.0% (giới hạn an toàn)", true);
            m_MaxDrawdownPercent = 5.0;
        }
    }

    LogMessage("Risk Manager khởi tạo: Risk=" + DoubleToString(m_RiskPerTrade, 2) + "%, " +
                    "Daily Loss=" + DoubleToString(m_MaxDailyLossPercent, 2) + "%, " +
                    "Max DD=" + DoubleToString(m_MaxDrawdownPercent, 2) + "%, " +
                    "Max Trades=" + IntegerToString(m_MaxDailyTrades) + ", " +
                    "Max Losses=" + IntegerToString(m_MaxConsecutiveLosses) + ", " +
                    "PropMode=" + (propMode ? "true" : "false"), true);
    
    // Tải thống kê trước đó nếu có
    LoadStatsFromFile("ApexPullback_" + symbol + "_Stats.bin");

    return true;
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
void CRiskManager::SetMarketRegimeInfo(bool isTransitioning, double regimeConfidence, double atrRatio)
{
    m_IsTransitioningMarket = isTransitioning;
    m_MarketRegimeConfidence = regimeConfidence; 
    m_ATRRatio = atrRatio;
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
//| Reset thống kê giao dịch hàng ngày                               |
//| Nên được gọi bởi EA chính vào đầu ngày mới.                      |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyStats(double newStartEquity = 0.0)
{
    m_DailyTradeCount = 0;
    m_DayStartEquity = (newStartEquity > 0) ? newStartEquity : m_AccountInfo.Equity();
    
    // Cập nhật PeakEquity nếu tài khoản đang tăng
    if (m_DayStartEquity > m_PeakEquity) {
        m_PeakEquity = m_DayStartEquity;
    }
    
    LogMessage("Thống kê hàng ngày đã reset. Start Equity: " + DoubleToString(m_DayStartEquity, 2), true);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có thể mở vị thế mới không                          |
//+------------------------------------------------------------------+
bool CRiskManager::CanOpenNewPosition(double volume, bool isBuy)
{
    // 1. Kiểm tra xem có đang tạm dừng không
    if (TimeCurrent() < m_PauseUntil) {
        LogMessage("Không thể mở vị thế mới: EA đang tạm dừng đến " + 
                  TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES), false);
        return false;
    }

    // 2. Kiểm tra giới hạn lỗ
    if (IsMaxLossReached()) {
        LogMessage("Không thể mở vị thế mới: Đã đạt giới hạn lỗ tối đa", true);
        return false;
    }
    
    // 3. Kiểm tra giới hạn giao dịch hàng ngày
    if (m_PropFirmMode && m_DailyTradeCount >= m_MaxDailyTrades) {
        LogMessage("Không thể mở vị thế mới: Đã đạt số lượng giao dịch tối đa trong ngày (" 
                   + IntegerToString(m_MaxDailyTrades) + ")", true);
        return false;
    }
    
    // 4. Kiểm tra số lần thua liên tiếp
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        LogMessage("Không thể mở vị thế mới: Đã đạt số lần thua liên tiếp tối đa (" 
                   + IntegerToString(m_MaxConsecutiveLosses) + ")", true);
        return false;
    }
    
    // 5. Kiểm tra margin
    if (!m_AccountInfo.FreeMarginCheck(m_Symbol, isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, volume, 
                                     m_SymbolInfo.Ask())) {
        LogMessage("Không thể mở vị thế mới: Không đủ margin tự do", true);
        return false;
    }
    
    // 6. Kiểm tra thị trường đang chuyển tiếp với mức tin cậy thấp
    if (m_IsTransitioningMarket && m_MarketRegimeConfidence < 0.4) {
        LogMessage("Không thể mở vị thế mới: Thị trường đang chuyển tiếp với mức tin cậy thấp (" + 
                  DoubleToString(m_MarketRegimeConfidence, 2) + ")", false);
        return false;
    }
    
    // 7. Kiểm tra biến động quá cao (kết hợp thêm m_IsTransitioningMarket)
    if (m_ATRRatio > A + B * m_MarketRegimeConfidence) {
        // A=2.5, B=-1.0 nghĩa là với m_MarketRegimeConfidence=1.0, ngưỡng là 1.5x ATR
        // Với m_MarketRegimeConfidence=0.5, ngưỡng là 2.0x ATR
        // Với m_MarketRegimeConfidence=0, ngưỡng là 2.5x ATR
        double volatilityThreshold = 2.5 - 1.0 * m_MarketRegimeConfidence;
        if (m_ATRRatio > volatilityThreshold) {
            LogMessage("Không thể mở vị thế mới: Biến động quá cao (ATR Ratio: " + 
                      DoubleToString(m_ATRRatio, 2) + "x > " + 
                      DoubleToString(volatilityThreshold, 2) + "x)", true);
            return false;
        }
    }
    
    // 8. Kiểm tra heat portfolio
    double heatValue = GetPortfolioHeatValue(volume, isBuy);
    if (heatValue > 2.5) {  // Ngưỡng heat quá cao
        LogMessage("Không thể mở vị thế mới: Portfolio heat quá cao (" 
                   + DoubleToString(heatValue, 2) + ")", false);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có thể thêm vào vị thế hiện tại không               |
//+------------------------------------------------------------------+
bool CRiskManager::CanScalePosition(double additionalVolume, bool isLong)
{
    // Kiểm tra giới hạn lỗ
    if (IsMaxLossReached()) {
        LogMessage("Không thể thêm vào vị thế: Đã đạt giới hạn lỗ tối đa", true);
        return false;
    }
    
    // Kiểm tra margin
    if (!m_AccountInfo.FreeMarginCheck(m_Symbol, isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, 
                                     additionalVolume, m_SymbolInfo.Ask())) {
        LogMessage("Không thể thêm vào vị thế: Không đủ margin tự do", true);
        return false;
    }
    
    // Kiểm tra drawdown hiện tại
    double currentDD = GetCurrentDrawdownPercent();
    if (currentDD > m_DrawdownReduceThreshold) {
        LogMessage("Không thể thêm vào vị thế: Drawdown hiện tại (" + 
                  DoubleToString(currentDD, 2) + "%) vượt quá ngưỡng (" + 
                  DoubleToString(m_DrawdownReduceThreshold, 2) + "%)", false);
        return false;
    }
    
    // Kiểm tra thị trường đang chuyển tiếp
    if (m_IsTransitioningMarket) {
        LogMessage("Không thể thêm vào vị thế: Thị trường đang trong giai đoạn chuyển tiếp", false);
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
    
    LogMessage("Đã đăng ký vị thế mới #" + IntegerToString(ticket) + 
                    ", Volume: " + DoubleToString(volume, 2) + 
                    ", Risk: " + DoubleToString(riskPercent, 2) + "%", false);
    
    // Lưu trạng thái thống kê mỗi khi có lệnh mới (để tiện theo dõi)
    m_LastStatsUpdate = TimeCurrent();
    LogRiskStatus(true);
}

//+------------------------------------------------------------------+
//| Cập nhật vị thế một phần                                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdatePositionPartial(ulong ticket, double partialVolume)
{
    LogMessage("Đã đóng một phần vị thế #" + IntegerToString(ticket) + 
                    ", Volume đóng: " + DoubleToString(partialVolume, 2), false);
}

//+------------------------------------------------------------------+
//| Cập nhật thống kê khi đóng giao dịch                             |
//+------------------------------------------------------------------+
void CRiskManager::UpdateStatsOnDealClose(bool isWin, double profit, int clusterType = 0, int sessionType = 0, double atrRatio = 1.0)
{
    m_TotalTrades++;
    
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
    
    // Điều chỉnh risk dựa trên qualityFactor (0.1-1.0)
    qualityFactor = MathMax(0.1, MathMin(qualityFactor, 1.0));
    riskPercent = riskPercent * qualityFactor;
    
    // Điều chỉnh risk dựa trên thị trường chuyển tiếp
    if (m_IsTransitioningMarket) {
        // Giảm risk thêm khi thị trường đang chuyển tiếp
        riskPercent *= (0.7 + 0.3 * m_MarketRegimeConfidence);
    }
    
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
    
    // Chuẩn hóa lot size theo lot step
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    // Đảm bảo lot size trong giới hạn cho phép
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    // Giảm lot size trong chế độ prop firm nếu > 0.5
    if (m_PropFirmMode && lotSize > 0.5) {
        double adjustedLot = MathMin(lotSize, 0.5);
        LogMessage("PROP FIRM MODE: Giảm lot size từ " + DoubleToString(lotSize, 2) + " xuống " + 
                  DoubleToString(adjustedLot, 2) + " (an toàn)", false);
        lotSize = adjustedLot;
    }
    
    // Log thông tin tính toán
    LogMessage("Risk calculation: Balance=$" + DoubleToString(accountBalance, 2) + 
             ", Risk=" + DoubleToString(riskPercent, 2) + "%, SL=" + 
             DoubleToString(stopLossPoints, 1) + " points, Lot=" + 
             DoubleToString(lotSize, 2), false);
    
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
    
    // Log thông tin
    LogMessage("Dynamic lot calculation: Base=" + DoubleToString(baseLotSize, 2) + 
             ", ATR ratio=" + DoubleToString(atrRatio, 2) + "x, Adjustment=" + 
             DoubleToString(adjustment, 2) + ", Final lot=" + 
             DoubleToString(dynamicLotSize, 2), false);
    
    return dynamicLotSize;
}

//+------------------------------------------------------------------+
//| Tính toán Điều chỉnh Lot Size dựa trên ATR ratio                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateATRBasedLotSizeAdjustment(double atrRatio)
{
    // Nếu ATR thấp hơn trung bình (< 1.0), có thể tăng lot size
    if (atrRatio < 0.8) {
        return 1.2; // 120% lot
    }
    // Nếu ATR gần với trung bình (0.8-1.2), giữ nguyên lot size
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
        return 0.5; // 50% lot
    }
}

//+------------------------------------------------------------------+
//| Tính toán % risk thích ứng dựa trên drawdown                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateAdaptiveRiskPercent()
{
    double currentDD = GetCurrentDrawdownPercent();
    double adaptiveRisk = m_RiskPerTrade;
    
    // Nếu không bật chế độ tapered risk, giảm risk đột ngột theo ngưỡng
    if (!m_EnableTaperedRisk) {
        if (currentDD >= m_DrawdownReduceThreshold && currentDD < m_MaxDrawdownPercent) {
            adaptiveRisk = m_RiskPerTrade * m_MinRiskMultiplier;
        }
        else if (currentDD >= m_MaxDrawdownPercent) {
            adaptiveRisk = 0;
        }
        return NormalizeDouble(adaptiveRisk, 2);
    }
    
    // Chế độ tapered risk - Giảm risk tuyến tính từ DrawdownReduceThreshold đến MaxDD
    if (currentDD >= m_DrawdownReduceThreshold && currentDD < m_MaxDrawdownPercent) {
        double riskReductionRange = m_MaxDrawdownPercent - m_DrawdownReduceThreshold;
        double ddInRange = currentDD - m_DrawdownReduceThreshold;
        double reducePercent = ddInRange / riskReductionRange;
        
        // Tỷ lệ giảm từ risk cơ sở xuống minRisk
        double minRisk = m_RiskPerTrade * m_MinRiskMultiplier;
        adaptiveRisk = m_RiskPerTrade - (m_RiskPerTrade - minRisk) * reducePercent;
    }
    // Nếu DD vượt MaxDD, đặt risk = 0 (không giao dịch)
    else if (currentDD >= m_MaxDrawdownPercent) {
        adaptiveRisk = 0;
    }
    
    // Ghi log nếu risk điều chỉnh khác risk cơ sở
    if (adaptiveRisk != m_RiskPerTrade) {
        LogMessage("Đã điều chỉnh risk theo DD: " + DoubleToString(currentDD, 2) + "% → " + 
                 DoubleToString(adaptiveRisk, 2) + "% (cơ sở: " + 
                 DoubleToString(m_RiskPerTrade, 2) + "%)", false);
    }
    
    return NormalizeDouble(adaptiveRisk, 2);
}

//+------------------------------------------------------------------+
//| Kiểm tra điều kiện tạm dừng                                      |
//+------------------------------------------------------------------+
bool CRiskManager::CheckPauseCondition()
{
    if (GetCurrentDrawdownPercent() >= m_MaxDrawdownPercent) {
        LogMessage("Điều kiện tạm dừng: Drawdown vượt ngưỡng tối đa " + 
                 DoubleToString(m_MaxDrawdownPercent, 2) + "%", true);
        return true;
    }
    
    if (m_ConsecutiveLosses >= m_MaxConsecutiveLosses) {
        LogMessage("Điều kiện tạm dừng: Đạt số lần thua liên tiếp tối đa " + 
                 IntegerToString(m_MaxConsecutiveLosses), true);
        return true;
    }
    
    if (GetDailyLossPercent() >= m_MaxDailyLossPercent) {
        LogMessage("Điều kiện tạm dừng: Đạt giới hạn lỗ hàng ngày " + 
                 DoubleToString(m_MaxDailyLossPercent, 2) + "%", true);
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
    LogMessage(pauseMsg, true);
}

//+------------------------------------------------------------------+
//| Tiếp tục giao dịch                                               |
//+------------------------------------------------------------------+
void CRiskManager::ResumeTrading(string reason = "")
{
    m_PauseUntil = 0;
    
    string resumeMsg = "EA tiếp tục hoạt động" + (reason != "" ? " vì " + reason : "");
    LogMessage(resumeMsg, true);
}

//+------------------------------------------------------------------+
//| Kiểm tra xem đã đạt giới hạn lỗ tối đa chưa                      |
//+------------------------------------------------------------------+
bool CRiskManager::IsMaxLossReached()
{
    // Kiểm tra drawdown
    double currentDD = GetCurrentDrawdownPercent();
    if (currentDD >= m_MaxDrawdownPercent) {
        LogMessage("Đã đạt giới hạn drawdown tối đa: " + DoubleToString(currentDD, 2) + "%", true);
        return true;
    }
    
    // Kiểm tra lỗ hàng ngày
    double dailyLossPercent = GetDailyLossPercent();
    if (dailyLossPercent >= m_MaxDailyLossPercent) {
        LogMessage("Đã đạt giới hạn lỗ hàng ngày: " + DoubleToString(dailyLossPercent, 2) + "%", true);
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
        LogMessage("Nên tạm dừng giao dịch: Đã thua liên tiếp " + 
                 IntegerToString(m_ConsecutiveLosses) + " lần", true);
        return true;
    }
    
    // Kiểm tra thị trường cực kỳ biến động
    if (m_ATRRatio > 2.5) {
        LogMessage("Nên tạm dừng giao dịch: Biến động cực cao (ATR ratio = " + 
                 DoubleToString(m_ATRRatio, 2) + "x)", true);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cập nhật drawdown tối đa                                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdateMaxDrawdown()
{
    double currentEquity = m_AccountInfo.Equity();
    
    // Cập nhật peak equity nếu cao hơn
    if (currentEquity > m_PeakEquity) {
        m_PeakEquity = currentEquity;
    }
    else {
        // Tính drawdown hiện tại
        double currentDD = (m_PeakEquity - currentEquity) / m_PeakEquity * 100.0;
        
        // Cập nhật max drawdown nếu lớn hơn
        if (currentDD > m_MaxDrawdownRecorded) {
            m_MaxDrawdownRecorded = currentDD;
            LogMessage("Cập nhật Max Drawdown mới: " + DoubleToString(m_MaxDrawdownRecorded, 2) + "%", true);
        }
    }
}

//+------------------------------------------------------------------+
//| Tính Drawdown hiện tại                                           |
//+------------------------------------------------------------------+
double CRiskManager::GetCurrentDrawdownPercent()
{
    double currentEquity = m_AccountInfo.Equity();
    
    // Cập nhật peak equity nếu cao hơn
    if (currentEquity > m_PeakEquity) {
        m_PeakEquity = currentEquity;
        return 0.0; // Không có drawdown
    }
    
    // Tính và trả về drawdown hiện tại
    return (m_PeakEquity - currentEquity) / m_PeakEquity * 100.0;
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
    
    // Khuyến nghị dựa trên kết quả phân tích
    if (stablePF > transitionPF * 1.5) {
        report += "- Consider AVOIDING transitioning market conditions\n";
    }
    
    if (bestATRIndex == 0 || bestATRIndex == 1) {
        report += "- Consider INCREASING risk in low volatility conditions\n";
    }
    else if (bestATRIndex == 3 || bestATRIndex == 4) {
        report += "- Consider INCREASING risk in high volatility conditions\n";
    }
    
    // Thêm các khuyến nghị khác nếu cần...
    
    return report;
}

//+------------------------------------------------------------------+
//| Lưu thống kê vào file                                            |
//+------------------------------------------------------------------+
bool CRiskManager::SaveStatsToFile(string filename)
{
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN);
    if (fileHandle != INVALID_HANDLE) {
        // Lưu thông tin cơ bản
        FileWriteInteger(fileHandle, m_TotalTrades);
        FileWriteInteger(fileHandle, m_Wins);
        FileWriteInteger(fileHandle, m_Losses);
        FileWriteDouble(fileHandle, m_ProfitSum);
        FileWriteDouble(fileHandle, m_LossSum);
        FileWriteDouble(fileHandle, m_MaxProfitTrade);
        FileWriteDouble(fileHandle, m_MaxLossTrade);
        FileWriteInteger(fileHandle, m_ConsecutiveWins);
        FileWriteInteger(fileHandle, m_ConsecutiveLosses);
        FileWriteInteger(fileHandle, m_MaxConsecutiveWins);
        FileWriteInteger(fileHandle, m_MaxConsecutiveLosses);
        FileWriteDouble(fileHandle, m_PeakEquity);
        FileWriteDouble(fileHandle, m_MaxDrawdownRecorded);
        
        // Lưu thống kê cluster
        for (int i = 0; i < 3; i++) {
            FileWriteInteger(fileHandle, m_ClusterStats[i].trades);
            FileWriteInteger(fileHandle, m_ClusterStats[i].wins);
            FileWriteDouble(fileHandle, m_ClusterStats[i].profit);
            FileWriteDouble(fileHandle, m_ClusterStats[i].loss);
        }
        
        // Lưu thống kê phiên
        for (int i = 0; i < 5; i++) {
            FileWriteInteger(fileHandle, m_SessionStats[i].trades);
            FileWriteInteger(fileHandle, m_SessionStats[i].wins);
            FileWriteDouble(fileHandle, m_SessionStats[i].profit);
            FileWriteDouble(fileHandle, m_SessionStats[i].loss);
        }
        
        // Lưu thống kê ATR
        for (int i = 0; i < 5; i++) {
            FileWriteDouble(fileHandle, m_ATRStats[i].atrLevel);
            FileWriteInteger(fileHandle, m_ATRStats[i].trades);
            FileWriteInteger(fileHandle, m_ATRStats[i].wins);
            FileWriteDouble(fileHandle, m_ATRStats[i].profit);
            FileWriteDouble(fileHandle, m_ATRStats[i].loss);
        }
        
        // Lưu thống kê regime
        for (int i = 0; i < 2; i++) {
            FileWriteInteger(fileHandle, m_RegimeStats[i].trades);
            FileWriteInteger(fileHandle, m_RegimeStats[i].wins);
            FileWriteDouble(fileHandle, m_RegimeStats[i].profit);
            FileWriteDouble(fileHandle, m_RegimeStats[i].loss);
        }
        
        FileClose(fileHandle);
        LogMessage("Đã lưu thống kê vào file " + filename, false);
        return true;
    }
    
    LogMessage("Không thể mở file để lưu thống kê: " + filename, true);
    return false;
}

//+------------------------------------------------------------------+
//| Tải thống kê từ file                                             |
//+------------------------------------------------------------------+
bool CRiskManager::LoadStatsFromFile(string filename)
{
    if (FileIsExist(filename)) {
        int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN);
        if (fileHandle != INVALID_HANDLE) {
            // Đọc thông tin cơ bản
            m_TotalTrades = FileReadInteger(fileHandle);
            m_Wins = FileReadInteger(fileHandle);
            m_Losses = FileReadInteger(fileHandle);
            m_ProfitSum = FileReadDouble(fileHandle);
            m_LossSum = FileReadDouble(fileHandle);
            m_MaxProfitTrade = FileReadDouble(fileHandle);
            m_MaxLossTrade = FileReadDouble(fileHandle);
            m_ConsecutiveWins = FileReadInteger(fileHandle);
            m_ConsecutiveLosses = FileReadInteger(fileHandle);
            m_MaxConsecutiveWins = FileReadInteger(fileHandle);
            m_MaxConsecutiveLosses = FileReadInteger(fileHandle);
            m_PeakEquity = FileReadDouble(fileHandle);
            m_MaxDrawdownRecorded = FileReadDouble(fileHandle);
            
            // Đọc thống kê cluster
            for (int i = 0; i < 3; i++) {
                m_ClusterStats[i].trades = FileReadInteger(fileHandle);
                m_ClusterStats[i].wins = FileReadInteger(fileHandle);
                m_ClusterStats[i].profit = FileReadDouble(fileHandle);
                m_ClusterStats[i].loss = FileReadDouble(fileHandle);
            }
            
            // Đọc thống kê phiên
            for (int i = 0; i < 5; i++) {
                m_SessionStats[i].trades = FileReadInteger(fileHandle);
                m_SessionStats[i].wins = FileReadInteger(fileHandle);
                m_SessionStats[i].profit = FileReadDouble(fileHandle);
                m_SessionStats[i].loss = FileReadDouble(fileHandle);
            }
            
            // Đọc thống kê ATR
            for (int i = 0; i < 5; i++) {
                m_ATRStats[i].atrLevel = FileReadDouble(fileHandle);
                m_ATRStats[i].trades = FileReadInteger(fileHandle);
                m_ATRStats[i].wins = FileReadInteger(fileHandle);
                m_ATRStats[i].profit = FileReadDouble(fileHandle);
                m_ATRStats[i].loss = FileReadDouble(fileHandle);
            }
            
            // Đọc thống kê regime
            for (int i = 0; i < 2; i++) {
                m_RegimeStats[i].trades = FileReadInteger(fileHandle);
                m_RegimeStats[i].wins = FileReadInteger(fileHandle);
                m_RegimeStats[i].profit = FileReadDouble(fileHandle);
                m_RegimeStats[i].loss = FileReadDouble(fileHandle);
            }
            
            FileClose(fileHandle);
            
            LogMessage("Đã tải thống kê từ file " + filename + 
                      ": " + IntegerToString(m_TotalTrades) + " giao dịch, " + 
                      "Win Rate: " + DoubleToString(GetWinRate(), 2) + "%", false);
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cập nhật và log thông tin rủi ro hiện tại                        |
//+------------------------------------------------------------------+
void CRiskManager::LogRiskStatus(bool forceLog = false)
{
    // Chỉ log mỗi 10 phút nếu không bắt buộc
    if (!forceLog && TimeCurrent() - m_LastStatsUpdate < 600) {
        return;
    }
    
    double currentDD = GetCurrentDrawdownPercent();
    double dailyLoss = GetDailyLossPercent();
    double adaptiveRisk = CalculateAdaptiveRiskPercent();
    
    string riskMsg = StringFormat(
        "Risk Status: DD=%.2f%%, Daily Loss=%.2f%%, Adaptive Risk=%.2f%%, " +
        "Con. Losses=%d, Trades Today=%d, Total Trades=%d, Win Rate=%.2f%%",
        currentDD, dailyLoss, adaptiveRisk,
        m_ConsecutiveLosses, m_DailyTradeCount, m_TotalTrades, GetWinRate()
    );
    
    LogMessage(riskMsg, false);
    m_LastStatsUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Tính chỉ số rủi ro thị trường (0-100%)                           |
//+------------------------------------------------------------------+
double CRiskManager::CalculateMarketRiskIndex()
{
    double riskIndex = 0.0;
    
    // 1. Volatility risk (0-40%)
    double volatilityRisk = 0;
    if (m_ATRRatio > 2.0)
        volatilityRisk = 40.0;
    else if (m_ATRRatio > 1.5)
        volatilityRisk = 30.0;
    else if (m_ATRRatio > 1.2)
        volatilityRisk = 20.0;
    else if (m_ATRRatio > 1.0)
        volatilityRisk = 10.0;
    
    // 2. Regime transition risk (0-30%)
    double regimeRisk = 0;
    if (m_IsTransitioningMarket) {
        regimeRisk = 30.0 * (1.0 - m_MarketRegimeConfidence);
    }
    
    // 3. Current DD risk (0-20%)
    double currentDD = GetCurrentDrawdownPercent();
    double ddRisk = 0;
    if (currentDD > m_MaxDrawdownPercent * 0.8)
        ddRisk = 20.0;
    else if (currentDD > m_MaxDrawdownPercent * 0.5)
        ddRisk = 15.0;
    else if (currentDD > m_DrawdownReduceThreshold)
        ddRisk = 10.0;
    
    // 4. Consecutive losses risk (0-10%)
    double lossRisk = MathMin(10.0, (double)m_ConsecutiveLosses / m_MaxConsecutiveLosses * 10.0);
    
    // Tổng hợp
    riskIndex = volatilityRisk + regimeRisk + ddRisk + lossRisk;
    
    // Giới hạn 0-100%
    riskIndex = MathMin(MathMax(riskIndex, 0.0), 100.0);
    
    return riskIndex;
}

//+------------------------------------------------------------------+
//| Kiểm tra điều kiện thị trường an toàn để giao dịch               |
//+------------------------------------------------------------------+
bool CRiskManager::IsSafeMarketCondition()
{
    double riskIndex = CalculateMarketRiskIndex();
    
    // Ngưỡng rủi ro chấp nhận được
    double acceptableRiskThreshold = 70.0; // 70% là ngưỡng cảnh báo
    
    if (riskIndex > acceptableRiskThreshold) {
        LogMessage(StringFormat("Rủi ro thị trường quá cao (%.1f%%) - Không an toàn để giao dịch", riskIndex), true);
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Helper function để log thông điệp                                |
//+------------------------------------------------------------------+
void CRiskManager::LogMessage(string message, bool isImportant = false)
{
    if (m_Logger != NULL) {
        if (isImportant)
            m_Logger.LogInfo(message);
        else
            m_Logger.LogDebug(message);
    }
}

//+------------------------------------------------------------------+