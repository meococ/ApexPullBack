#ifndef RISKMANAGER_MQH_
#define RISKMANAGER_MQH_

//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh |
//|                         Copyright 2023-2024, ApexPullback EA |
//|                                     https://www.apexpullback.com |
//+------------------------------------------------------------------+

//--- Standard Library Includes
#include <Trade/AccountInfo.mqh> // Standard MQL5 AccountInfo class
#include <Trade/SymbolInfo.mqh>  // Standard MQL5 SymbolInfo class

//--- Core Project Includes
#include "Inputs.mqh" // Unified constants and input parameters
#include "Enums.mqh"
#include "CommonStructs.mqh" // For EAContext and other common structures

//+------------------------------------------------------------------+
//| Namespace: ApexPullback                                          |
//| Purpose: Encapsulates all custom code for the EA.                |
//+------------------------------------------------------------------+
namespace ApexPullback {

//+------------------------------------------------------------------+
//| Class CRiskManager - Quản lý rủi ro toàn diện                    |
//+------------------------------------------------------------------+
class CRiskManager
{
private:
    ApexPullback::EAContext* m_context; // Con trỏ tới EAContext
    
    // Thông tin tài khoản và symbol
    double m_DayStartEquity;
    int m_DailyTradeCount;
    int m_ConsecutiveLosses;
    int m_ConsecutiveWins;
    double m_PeakEquity;
    double m_MaxDrawdownRecorded;
    datetime m_PauseUntil;
    datetime m_LastStatsUpdate;
    double m_DailyLoss;
    double m_WeeklyLoss;
    int m_CurrentDay;
    
    // Thống kê giao dịch
    int m_TotalTrades;
    int m_Wins;
    int m_Losses;
    double m_ProfitSum;
    double m_LossSum;
    double m_MaxProfitTrade;
    double m_MaxLossTrade;
    int m_MaxConsecutiveWins;
    int m_HistoricalMaxConsecutiveLosses;
    double m_AverageATR;
    double m_MarketProfile;
    double m_TrendTradeRatio;
    
    // Thông tin thị trường
    bool m_IsTransitioningMarket;
    double m_MarketRegimeConfidence;
    double m_ATRRatio;
    double m_SpreadRatio;
    
    // Thông tin chiến lược và thị trường
    ApexPullback::ENUM_TRADING_STRATEGY m_CurrentStrategy;
    ApexPullback::ENUM_MARKET_REGIME m_CurrentRegime;
    ApexPullback::ENUM_SESSION m_CurrentSession;
    ApexPullback::ENUM_PATTERN_TYPE m_PreferredScenario;
    
    // Thống kê theo cluster, session, ATR, regime
    ClusterStats m_ClusterStats[3];
    SessionStats m_SessionStats[5];
    ATRStats m_ATRStats[5];
    RegimeStats m_RegimeStats[2];
    
    // Công cụ hỗ trợ
    CAccountInfo m_AccountInfo;
    CSymbolInfo m_SymbolInfo;

public:
    // Constructor nhận reference EAContext
    CRiskManager(ApexPullback::EAContext &context);
    
    // Destructor
    ~CRiskManager();
    
    // Hàm Khởi tạo
    bool Initialize();
    void InitializeDayStartEquity();
    
    // Thiết lập các tham số nâng cao
    void SetDrawdownProtectionParams(double drawdownReduceThreshold, double minRiskMultiplier = 0.3, 
                                  bool enableTaperedRisk = true);
    void SetMarketRegimeInfo(ENUM_MARKET_REGIME regime, bool isTransitioning = false, double regimeConfidence = 0.0, 
                           double atrRatio = 1.0, ENUM_SESSION session = SESSION_UNKNOWN);
    void SetRiskLimits(double maxRisk, double minRisk);
    
    // V14.0: AssetProfiler tích hợp
    bool LoadAssetProfile(string symbol = "");
    bool SaveAssetProfile(string symbol = "");
    void UpdateAssetProfile(double currentATR, double currentSpread);
    void SetAssetConfig(double riskMultiplier, double slAtrMultiplier, double tpRrRatio, 
                       double maxSpreadPoints, double volatilityFactor = 1.0);
    
    // V14.0: Cải tiến quản lý risk
    double CalculateAdaptiveRiskPercent(ApexPullback::ENUM_TRADING_STRATEGY strategy, 
                                      ApexPullback::ENUM_MARKET_REGIME regime, 
                                      double atrRatio = 1.0, ApexPullback::ENUM_SESSION session = ApexPullback::SESSION_UNKNOWN);
    double CalculateAdaptiveRiskPercent(string &adjustmentReasonOut, double baseRiskPercent = -1.0);
    double GetRegimeFactor(ApexPullback::ENUM_MARKET_REGIME regime, bool isTransitioning = false);
    double GetSessionFactor(ApexPullback::ENUM_SESSION session, string symbol = "");
    double GetSymbolRiskFactor(string symbol = "");
    double IsApproachingDailyLossLimit();
    
    // V14.0: Enhanced Risk Management với Anti-Overfitting
    double CalculatePerformanceBasedRiskFactor();
    double CalculateVolatilityBasedRiskFactor();
    double CalculateMarketStressFactor() { return 1.0; }
    double CalculateRecentWinRate(int lookbackTrades = 30) { return 0.5; }
    double CalculateEnhancedPositionSize(double riskPercent, double stopLossPoints, 
                                        double qualityFactor, ENUM_TRADING_STRATEGY strategy) { return 0.01; }
    double GetStrategyRiskFactor(ENUM_TRADING_STRATEGY strategy) { return 1.0; }
    double CalculateCorrelationAdjustment() { return 1.0; }
    double CalculatePortfolioHeatFactor() { return 1.0; }
    
    // V14.0: Broker Performance Adjustment - Điều chỉnh rủi ro dựa trên chất lượng broker
    void AdjustForBrokerPerformance();
    double CalculateBrokerQualityFactor();
    void UpdateBrokerPerformanceMetrics(double slippagePips, double executionTimeMs);
    bool ShouldReduceRiskDueToBroker();
    
    // Quản lý trạng thái
    bool CheckPauseCondition() const { return false; }
    bool CheckAutoResume() const { return true; }
    void PauseTrading(int minutes, string reason = "") {}
    void ResumeTrading(string reason = "") {}
    bool IsMaxLossReached() const { return false; }
    bool ShouldPauseTrading() const { return false; }
    void ResetDailyStats(double newStartEquity = 0.0) {}
    void UpdateMaxDrawdown();
    datetime GetPauseUntil() const { return 0; }
    bool IsPaused() const { return false; }
    void UpdateDailyVars() {}
    void UpdatePauseStatus() {}
    
    // Quản lý rủi ro chính
    bool CanOpenNewPosition(double volume, bool isBuy) { return true; }
    bool CanScalePosition(double additionalVolume, bool isLong) { return true; }
    void RegisterNewPosition(ulong ticket, double volume, double riskPercent) {}
    void UpdatePositionPartial(ulong ticket, double partialVolume) {}
    void UpdateStatsOnDealClose(bool isWin, double profit, int clusterType = 0, int sessionType = 0, double atrRatio = 1.0);

    // Tính toán kích thước lệnh
    double CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                          double qualityFactor = 1.0, double riskPercent = 0.0);

    double CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                double atrRatio, double maxVolatilityFactor, 
                                double minLotMultiplier, double qualityFactor = 1.0) { return 0.01; }
    double CalculateOptimalLotSize(double riskPercent, double slDistancePoints) { return 0.01; }
    
    // Tính toán SL/TP
    double CalculateOptimalStopLoss(double entryPrice, bool isLong) { return entryPrice; }
    double CalculateOptimalTakeProfit(double entryPrice, double stopLoss, bool isLong) { return entryPrice; }
    double CalculateATRBasedLotSizeAdjustment(double atrRatio) { return 1.0; }
    
    // Kiểm tra điều kiện thị trường
    bool IsSpreadAcceptable(double currentSpread = 0.0) const { return true; }
    bool IsVolatilityAcceptable(double currentATRratio = 0.0) const { return true; }
    bool IsMarketSuitableForTrading() const { return true; }
    double GetAcceptableSpreadThreshold() const { return 10.0; }
    
    // Thống kê và báo cáo
    double GetWinRate() const { return 0.5; }
    double GetProfitFactor() const { return 1.0; }
    double GetExpectancy() const { return 0.0; }
    double GetClusterWinRate(int clusterIndex) const { return 0.5; }
    double GetClusterProfitFactor(int clusterIndex) const { return 1.0; }
    double GetSessionWinRate(int sessionIndex) const { return 0.5; }
    double GetSessionProfitFactor(int sessionIndex) const { return 1.0; }
    double GetATRWinRate(int atrIndex) const { return 0.5; }
    double GetATRProfitFactor(int atrIndex) const { return 1.0; }
    double GetRegimeWinRate(bool isTransitioning) const { return 0.5; }
    double GetRegimeProfitFactor(bool isTransitioning) const { return 1.0; }
    string GeneratePerformanceReport() const { return "Performance Report"; }
    string GenerateRegimeAnalysisReport() const { return "Regime Analysis"; }
    bool SaveStatsToFile(string filename) { return true; }
    bool LoadStatsFromFile(string filename) { return true; }
    
    // Đánh giá rủi ro thị trường
    double CalculateMarketRiskIndex() const { return 0.5; }
    bool IsSafeMarketCondition() const { return true; }
    void LogRiskStatus(bool forceLog = false) {}
    void DrawRiskDashboard() {}
    
    // Quản lý portfolio
    double GetPortfolioHeatValue(double volume, bool isBuy) const { return 0.0; }
    double GetCorrelationAdjustment(bool isBuy) const { return 1.0; }
    double NormalizeEntryLots(double calculatedLots) const { return calculatedLots; }
    
    // Utility functions
    void LogMessage(string message, bool isImportant = false) {}
    bool AdaptToMarketCycle() { return true; }
    double CalculateLongTermVolatility() const { return 1.0; }
    double CalculateVolatilityChangeRate() const { return 0.0; }
    bool IsDrawdownExceeded() const { return false; }
    bool IsDailyLossExceeded() const { return false; }
    void SetDetailedLogging(bool enable) {}
    bool IsMarketConditionSafe() const { return true; }
    double GetCurrentDrawdownPercent() const { return 0.0; }
    double GetDailyLossPercent() const { return 0.0; }
    bool CheckCorrelationRisk(ENUM_ORDER_TYPE orderType) const { return false; }
    int GetCurrentDayOfYear() const { 
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.day_of_year;
    }
    int GetCurrentDayOfWeek() const {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.day_of_week;
    }
}; // End of class CRiskManager

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(ApexPullback::EAContext &context) : m_context(&context) {
    // Initialize all member variables to a default state
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
    m_CurrentDay = -1;
    m_TotalTrades = 0;
    m_Wins = 0;
    m_Losses = 0;
    m_ProfitSum = 0;
    m_LossSum = 0;
    m_MaxProfitTrade = 0;
    m_MaxLossTrade = 0;
    m_MaxConsecutiveWins = 0;
    m_HistoricalMaxConsecutiveLosses = 0;
    m_AverageATR = 0;
    m_MarketProfile = 0;
    m_TrendTradeRatio = 0;
    m_IsTransitioningMarket = false;
    m_MarketRegimeConfidence = 0;
    m_ATRRatio = 0;
    m_SpreadRatio = 0;
    m_CurrentStrategy = STRATEGY_UNKNOWN;
    m_CurrentRegime = REGIME_UNKNOWN;
    m_CurrentSession = SESSION_UNKNOWN;
    m_PreferredScenario = PATTERN_NONE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CRiskManager::Initialize()
{
    if (!m_context || !m_context->Logger)
    {
        printf("CRiskManager::Initialize - Critical error: EAContext or Logger is null.");
        return false;
    }

    if (!m_AccountInfo.SelectAccount())
    {
        m_context->Logger->LogError("CRiskManager::Initialize - Failed to select account.");
        return false;
    }

    if (!m_SymbolInfo.Name(m_context->Symbol))
    {
        m_context->Logger->LogError("CRiskManager::Initialize - Failed to select symbol: " + m_context->Symbol);
        return false;
    }

    InitializeDayStartEquity();
    ResetDailyStats(m_AccountInfo.Equity());

    m_context->Logger->LogInfo("RiskManager initialized successfully.");
    return true;
}

//+------------------------------------------------------------------+
//| InitializeDayStartEquity                                         |
//+------------------------------------------------------------------+
void CRiskManager::InitializeDayStartEquity()
{
    m_AccountInfo.Refresh();
    m_DayStartEquity = m_AccountInfo.Equity();
    m_PeakEquity = m_DayStartEquity;
    m_context->Logger->LogInfo("Day start equity initialized to: " + DoubleToString(m_DayStartEquity, 2));
}

//+------------------------------------------------------------------+
//| ResetDailyStats                                                  |
//+------------------------------------------------------------------+
void CRiskManager::ResetDailyStats(double newStartEquity)
{
    m_DailyTradeCount = 0;
    m_ConsecutiveLosses = 0;
    m_ConsecutiveWins = 0;
    m_DailyLoss = 0.0;
    if(newStartEquity > 0)
    {
        m_DayStartEquity = newStartEquity;
        m_PeakEquity = newStartEquity;
    }
    m_context->Logger->LogInfo("Daily stats have been reset.");
}

//+------------------------------------------------------------------+
//| SetDrawdownProtectionParams                                      |
//+------------------------------------------------------------------+
void CRiskManager::SetDrawdownProtectionParams(double drawdownReduceThreshold, double minRiskMultiplier, bool enableTaperedRisk)
{
    // Implementation to be added
    m_context->Logger->LogInfo("Drawdown protection parameters set.");
}

//+------------------------------------------------------------------+
//| SetMarketRegimeInfo                                              |
//+------------------------------------------------------------------+
void CRiskManager::SetMarketRegimeInfo(ENUM_MARKET_REGIME regime, bool isTransitioning, double regimeConfidence, double atrRatio, ENUM_SESSION session)
{
    m_CurrentRegime = regime;
    m_IsTransitioningMarket = isTransitioning;
    m_MarketRegimeConfidence = regimeConfidence;
    m_ATRRatio = atrRatio;
    m_CurrentSession = session;
}

//+------------------------------------------------------------------+
//| SetRiskLimits                                                    |
//+------------------------------------------------------------------+
void CRiskManager::SetRiskLimits(double maxRisk, double minRisk)
{
    // Implementation to be added
    m_context->Logger->LogInfo("Risk limits set.");
}


//+------------------------------------------------------------------+
//| CalculateLotSize                                                 |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, double qualityFactor, double riskPercent)
{
    if (!m_context || stopLossPoints <= 0)
    {
        if(m_context && m_context->Logger) m_context->Logger->LogError("CalculateLotSize: Invalid parameters or null context.");
        return 0.0;
    }

    // 1. Lấy thông tin tài khoản và symbol
    m_AccountInfo.Refresh();
    if (!m_SymbolInfo.Name(symbol))
    {
        m_context->Logger->LogError("CalculateLotSize: Failed to select symbol: " + symbol);
        return 0.0;
    }
    m_SymbolInfo.Refresh();

    // 2. Xác định phần trăm rủi ro
    double riskPerc = (riskPercent > 0) ? riskPercent : m_context->inpRiskPercent;
    
    // Áp dụng các yếu tố điều chỉnh rủi ro
    string adjustmentReason = "";
    riskPerc = CalculateAdaptiveRiskPercent(adjustmentReason, riskPerc);

    // 3. Tính toán số tiền rủi ro
    double accountBalance = m_AccountInfo.Balance();
    double riskAmount = accountBalance * (riskPerc / 100.0);

    // 4. Tính toán giá trị mỗi tick và kích thước lot
    double tickValue = m_SymbolInfo.TickValue();
    double tickSize = m_SymbolInfo.TickSize();
    if (tickValue <= 0 || tickSize <= 0)
    {
        m_context->Logger->LogError("CalculateLotSize: Invalid tick value or tick size for " + symbol);
        return 0.0;
    }

    double slInMoney = stopLossPoints * tickValue / tickSize;
    if (slInMoney <= 0)
    {
        m_context->Logger->LogError("CalculateLotSize: Stop loss value in money is zero or negative.");
        return 0.0;
    }

    // 5. Tính toán lot size thô
    double lotSize = riskAmount / slInMoney;

    // 6. Chuẩn hóa lot size
    double lotStep = m_SymbolInfo.LotsStep();
    double minLot = m_SymbolInfo.LotsMin();
    double maxLot = m_SymbolInfo.LotsMax();

    lotSize = floor(lotSize / lotStep) * lotStep;

    // 7. Kiểm tra giới hạn lot
    if (lotSize < minLot)
    {
        lotSize = minLot;
        m_context->Logger->LogWarning("Calculated lot size (" + DoubleToString(lotSize, 2) + ") is less than min lot. Using min lot: " + DoubleToString(minLot, 2));
    }
    if (lotSize > maxLot)
    {
        lotSize = maxLot;
        m_context->Logger->LogWarning("Calculated lot size (" + DoubleToString(lotSize, 2) + ") is greater than max lot. Using max lot: " + DoubleToString(maxLot, 2));
    }

    m_context->Logger->LogInfo("Calculated Lot Size: " + DoubleToString(lotSize, 2) + 
                               " for symbol " + symbol + 
                               " with Risk %: " + DoubleToString(riskPerc, 2) + 
                               " and SL (points): " + DoubleToString(stopLossPoints, 1));

    return lotSize;
}

//+------------------------------------------------------------------+
//| CalculateAdaptiveRiskPercent                                     |
//+------------------------------------------------------------------+
double CRiskManager::CalculateAdaptiveRiskPercent(string &adjustmentReasonOut, double baseRiskPercent)
{
    if (!m_context) return 0.0;

    double finalRisk = (baseRiskPercent > 0) ? baseRiskPercent : m_context->inpRiskPercent;
    adjustmentReasonOut = "Base Risk: " + DoubleToString(finalRisk, 2) + "%";

    // Lấy thông tin thị trường hiện tại từ context
    ENUM_MARKET_REGIME currentRegime = m_context->CurrentMarketRegime;
    ENUM_SESSION currentSession = m_context->CurrentSession;

    // 1. Điều chỉnh dựa trên chế độ thị trường (Market Regime)
    double regimeFactor = GetRegimeFactor(currentRegime, m_IsTransitioningMarket);
    if (MathAbs(regimeFactor - 1.0) > 0.01)
    {
        finalRisk *= regimeFactor;
        adjustmentReasonOut += "; Regime Factor: " + DoubleToString(regimeFactor, 2);
    }

    // 2. Điều chỉnh dựa trên phiên giao dịch (Session)
    double sessionFactor = GetSessionFactor(currentSession, m_context->Symbol);
    if (MathAbs(sessionFactor - 1.0) > 0.01)
    {
        finalRisk *= sessionFactor;
        adjustmentReasonOut += "; Session Factor: " + DoubleToString(sessionFactor, 2);
    }

    // 3. Điều chỉnh dựa trên hiệu suất gần đây (Performance)
    double perfFactor = CalculatePerformanceBasedRiskFactor();
    if (MathAbs(perfFactor - 1.0) > 0.01)
    {
        finalRisk *= perfFactor;
        adjustmentReasonOut += "; Perf. Factor: " + DoubleToString(perfFactor, 2);
    }
    
    // 4. Điều chỉnh dựa trên biến động (Volatility)
    double volFactor = CalculateVolatilityBasedRiskFactor();
    if (MathAbs(volFactor - 1.0) > 0.01)
    {
        finalRisk *= volFactor;
        adjustmentReasonOut += "; Vol. Factor: " + DoubleToString(volFactor, 2);
    }

    // 5. Kiểm tra giới hạn thua lỗ trong ngày
    double lossLimitFactor = IsApproachingDailyLossLimit();
    if (lossLimitFactor < 1.0)
    {
        finalRisk *= lossLimitFactor;
        adjustmentReasonOut += "; Daily Loss Limit Factor: " + DoubleToString(lossLimitFactor, 2);
    }

    // Giới hạn rủi ro trong khoảng min/max
    finalRisk = fmax(finalRisk, m_context->inpMinRiskPercent);
    finalRisk = fmin(finalRisk, m_context->inpMaxRiskPercent);

    if(m_context->Logger)
        m_context->Logger->LogInfo("Adaptive Risk Calculation: " + adjustmentReasonOut + ". Final Risk: " + DoubleToString(finalRisk, 2) + "%");

    return finalRisk;
}

//+------------------------------------------------------------------+
//| GetRegimeFactor                                                  |
//+------------------------------------------------------------------+
double CRiskManager::GetRegimeFactor(ApexPullback::ENUM_MARKET_REGIME regime, bool isTransitioning)
{
    if (isTransitioning) return 0.75; // Giảm rủi ro trong thị trường chuyển tiếp

    switch(regime)
    {
        case REGIME_TRENDING:
            return 1.0; // Rủi ro cơ bản trong thị trường có xu hướng
        case REGIME_RANGING:
            return 0.8; // Giảm rủi ro trong thị trường đi ngang
        default:
            return 0.5; // Rủi ro thấp cho các chế độ không xác định
    }
}

//+------------------------------------------------------------------+
//| GetSessionFactor                                                 |
//+------------------------------------------------------------------+
double CRiskManager::GetSessionFactor(ApexPullback::ENUM_SESSION session, string symbol)
{
    // Logic này có thể được mở rộng để tùy chỉnh cho từng cặp tiền tệ
    switch(session)
    {
        case SESSION_LONDON:
        case SESSION_NEWYORK:
            return 1.0; // Rủi ro cơ bản cho các phiên chính
        case SESSION_ASIAN:
            return 0.7; // Giảm rủi ro cho phiên Á
        default:
            return 0.8; // Rủi ro vừa phải cho các phiên khác
    }
}

//+------------------------------------------------------------------+
//| IsApproachingDailyLossLimit                                      |
//+------------------------------------------------------------------+
double CRiskManager::IsApproachingDailyLossLimit()
{
    if (!m_context || m_context->inpMaxDailyLossPercent <= 0) return 1.0;

    m_AccountInfo.Refresh();
    double currentEquity = m_AccountInfo.Equity();
    double lossToday = m_DayStartEquity - currentEquity;
    double lossPercent = (lossToday / m_DayStartEquity) * 100.0;

    if (lossPercent >= m_context->inpMaxDailyLossPercent)
    {
        return 0.0; // Đã đạt đến giới hạn, không giao dịch nữa
    }
    else if (lossPercent >= m_context->inpMaxDailyLossPercent * 0.75)
    {
        return 0.5; // Gần đến giới hạn, giảm một nửa rủi ro
    }

    return 1.0; // Chưa đến gần giới hạn
}

//+------------------------------------------------------------------+
//| CalculatePerformanceBasedRiskFactor                              |
//+------------------------------------------------------------------+
double CRiskManager::CalculatePerformanceBasedRiskFactor()
{
    if (m_ConsecutiveLosses >= m_context->inpMaxConsecutiveLosses)
    {
        return 0.5; // Giảm mạnh rủi ro sau chuỗi thua
    }
    else if (m_ConsecutiveWins >= 3)
    {
        return 1.2; // Tăng nhẹ rủi ro sau chuỗi thắng
    }
    return 1.0;
}

//+------------------------------------------------------------------+
//| CalculateVolatilityBasedRiskFactor                               |
//+------------------------------------------------------------------+
double CRiskManager::CalculateVolatilityBasedRiskFactor()
{
    if (!m_context || !m_context->MarketProfile || m_context->MarketProfile->GetAverageATR(20) <= 0)
    {
        return 1.0;
    }

    double longTermATR = m_context->MarketProfile->GetAverageATR(100);
    double shortTermATR = m_context->MarketProfile->GetAverageATR(20);

    if (longTermATR <= 0) return 1.0;

    double atrRatio = shortTermATR / longTermATR;

    if (atrRatio > 1.5) // Biến động tăng mạnh
    {
        return 0.75;
    }
    else if (atrRatio < 0.6) // Biến động rất thấp
    {
        return 0.8;
    }

    return 1.0;
}

//+------------------------------------------------------------------+
//| UpdateStatsOnDealClose                                           |
//+------------------------------------------------------------------+
void CRiskManager::UpdateStatsOnDealClose(bool isWin, double profit, int clusterType, int sessionType, double atrRatio)
{
    m_TotalTrades++;
    m_DailyTradeCount++;

    if (isWin)
    {
        m_Wins++;
        m_ProfitSum += profit;
        m_ConsecutiveWins++;
        m_ConsecutiveLosses = 0;
        if (m_ConsecutiveWins > m_MaxConsecutiveWins)
        {
            m_MaxConsecutiveWins = m_ConsecutiveWins;
        }
        if (profit > m_MaxProfitTrade)
        {
            m_MaxProfitTrade = profit;
        }
    }
    else
    {
        m_Losses++;
        m_LossSum += profit; // profit is negative for losses
        m_ConsecutiveLosses++;
        m_ConsecutiveWins = 0;
        if (m_ConsecutiveLosses > m_HistoricalMaxConsecutiveLosses)
        {
            m_HistoricalMaxConsecutiveLosses = m_ConsecutiveLosses;
        }
        if (profit < m_MaxLossTrade)
        {
            m_MaxLossTrade = profit;
        }
    }

    // Update equity and drawdown
    UpdateMaxDrawdown();

    if(m_context && m_context->Logger)
        m_context->Logger->LogInfo("Stats updated on deal close. Win: " + (string)isWin + ", Profit: " + DoubleToString(profit, 2) + ". Total Trades: " + (string)m_TotalTrades);
}

//+------------------------------------------------------------------+
//| UpdateMaxDrawdown                                                |
//+------------------------------------------------------------------+
void CRiskManager::UpdateMaxDrawdown()
{
    if (!m_context) return;

    m_AccountInfo.Refresh();
    double currentEquity = m_AccountInfo.Equity();

    // Cập nhật vốn chủ sở hữu đỉnh nếu cần
    if (currentEquity > m_PeakEquity)
    {
        m_PeakEquity = currentEquity;
    }
    else
    {
        // Tính toán drawdown hiện tại
        double currentDrawdown = ((m_PeakEquity - currentEquity) / m_PeakEquity) * 100.0;

        // Cập nhật drawdown tối đa nếu cần
        if (currentDrawdown > m_MaxDrawdownRecorded)
        {
            m_MaxDrawdownRecorded = currentDrawdown;
            if(m_context->Logger)
                m_context->Logger->LogWarning("New max drawdown recorded: " + DoubleToString(m_MaxDrawdownRecorded, 2) + "%");
        }

        // Cập nhật thua lỗ trong ngày
        double dailyLoss = m_DayStartEquity - currentEquity;
        if (dailyLoss > 0)
        {
            m_DailyLoss = dailyLoss;
            if (m_DailyLoss >= m_context->inpMaxDailyLossPercent * m_DayStartEquity / 100.0)
            {
                if(m_context->Logger)
                    m_context->Logger->LogError("Daily loss limit reached: " + DoubleToString(m_DailyLoss, 2));
            }
        }
    }
}

} // End of namespace ApexPullback

#endif // RISKMANAGER_MQH_