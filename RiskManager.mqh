#ifndef RISKMANAGER_MQH_
#define RISKMANAGER_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback {

class CRiskManager {
private:
    EAContext* m_context; // Context is now a pointer
    string m_symbol;
    long m_magic_number;

    // Stats variables
    double m_DayStartEquity;
    double m_PeakEquity;
    double m_MaxDrawdownRecorded; // in percentage
    double m_DailyLoss;
    double m_WeeklyLoss;
    int m_ConsecutiveLosses;
    int m_ConsecutiveWins;
    int m_MaxConsecutiveWins;
    int m_HistoricalMaxConsecutiveLosses;
    int m_TotalTrades;
    int m_DailyTradeCount;
    int m_Wins;
    int m_Losses;
    double m_ProfitSum;
    double m_LossSum;
    double m_MaxProfitTrade;
    double m_MaxLossTrade;

    // State variables
    datetime m_PauseUntil;
    int m_CurrentDay;
    bool m_IsTransitioningMarket; // Should be updated by MarketProfile

public:
    CRiskManager(EAContext* context) : m_context(context), m_symbol(""), m_magic_number(0) {
        ResetAllStats();
    }

    ~CRiskManager() {}

    void ResetAllStats() {
        m_DayStartEquity = 0;
        m_PeakEquity = 0;
        m_MaxDrawdownRecorded = 0;
        m_DailyLoss = 0;
        m_WeeklyLoss = 0;
        m_ConsecutiveLosses = 0;
        m_ConsecutiveWins = 0;
        m_MaxConsecutiveWins = 0;
        m_HistoricalMaxConsecutiveLosses = 0;
        m_TotalTrades = 0;
        m_DailyTradeCount = 0;
        m_Wins = 0;
        m_Losses = 0;
        m_ProfitSum = 0;
        m_LossSum = 0;
        m_MaxProfitTrade = 0;
        m_MaxLossTrade = 0;
        m_PauseUntil = 0;
        m_CurrentDay = 0;
        m_IsTransitioningMarket = false;
    }

    void ResetDailyStats(double starting_equity) {
        m_DayStartEquity = starting_equity;
        m_PeakEquity = starting_equity;
        m_DailyLoss = 0;
        m_DailyTradeCount = 0;
    }

    bool Initialize() {
        // m_context is already set by the constructor
        m_symbol = m_context.pSymbolInfo->Symbol();
        m_magic_number = m_context.Inputs.MagicNumber;
        
        ResetDailyStats(AccountInfoDouble(ACCOUNT_EQUITY));
        m_CurrentDay = GetCurrentDayOfYear();

        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "RiskManager initialized.");
        return true;
    }

    // Main risk calculation method
    double CalculatePositionSize(double stop_loss_pips) {
        if (stop_loss_pips <= 0) {
            if(m_context.pLogger) m_context.pLogger->LogWarning("Invalid parameters for CalculatePositionSize: stop_loss_pips <= 0");
            return 0.0;
        }

        const SRiskManagement& risk_config = m_context.Inputs.RiskManagement;

        double position_size = 0.0;
        double base_risk_percent = risk_config.RiskPercent;
        
        // Apply adaptive risk if enabled
        string adjustmentReason = "";
        if (risk_config.UseAdaptiveRisk) {
            base_risk_percent = CalculateAdaptiveRiskPercent(adjustmentReason, base_risk_percent);
        }

        switch (risk_config.LotSizeMode) {
            case LOT_SIZE_FIXED:
                position_size = risk_config.FixedLotSize;
                break;
            case LOT_SIZE_PERCENT_BALANCE:
                position_size = CalculateRiskPercentSize(base_risk_percent, stop_loss_pips, false);
                break;
            case LOT_SIZE_PERCENT_EQUITY:
                position_size = CalculateRiskPercentSize(base_risk_percent, stop_loss_pips, true);
                break;
        }

        if(m_context.pLogger && risk_config.UseAdaptiveRisk) {
            m_context.pLogger->Log(ALERT_LEVEL_INFO, "Final Position Size: " + DoubleToString(position_size,2) + ". " + adjustmentReason);
        }

        return NormalizeLotSize(position_size);
    }

    bool CanOpenNewPosition() {
        if (IsPaused()) {
            if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "Cannot open new position: Trading is paused until " + TimeToString(m_PauseUntil));
            return false;
        }

        if (IsDailyLossExceeded()) {
            if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_WARNING, "Cannot open new position: Daily loss limit has been reached.");
            return false;
        }

        if (m_context.Inputs.RiskManagement.MaxDailyTrades > 0 && m_DailyTradeCount >= m_context.Inputs.RiskManagement.MaxDailyTrades) {
            if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "Cannot open new position: Maximum daily trades limit reached (" + (string)m_DailyTradeCount + ").");
            return false;
        }

        if (m_context.Inputs.RiskManagement.MaxConsecutiveLosses > 0 && m_ConsecutiveLosses >= m_context.Inputs.RiskManagement.MaxConsecutiveLosses) {
            if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_WARNING, "Cannot open new position: Max consecutive losses reached (" + (string)m_ConsecutiveLosses + "). Pausing trading.");
            PauseTrading(m_context.Inputs.RiskManagement.PauseAfterLossesMinutes, "Max consecutive losses reached");
            return false;
        }

        if (IsDrawdownExceeded()) {
            if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_ERROR, "Cannot open new position: Maximum drawdown limit has been reached.");
            return false;
        }
        
        if (!IsSpreadAcceptable()) {
             if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_WARNING, "Cannot open new position: Spread is too high.");
             return false;
        }

        return true; 
    }

    void UpdateStatsOnDealClose(bool isWin, double profit) {
        m_TotalTrades++;
        m_DailyTradeCount++;

        if (isWin) {
            m_Wins++;
            m_ProfitSum += profit;
            m_ConsecutiveWins++;
            m_ConsecutiveLosses = 0;
            if (m_ConsecutiveWins > m_MaxConsecutiveWins) m_MaxConsecutiveWins = m_ConsecutiveWins;
            if (profit > m_MaxProfitTrade) m_MaxProfitTrade = profit;
        } else {
            m_Losses++;
            m_LossSum += profit; // profit is negative
            m_ConsecutiveLosses++;
            m_ConsecutiveWins = 0;
            if (m_ConsecutiveLosses > m_HistoricalMaxConsecutiveLosses) m_HistoricalMaxConsecutiveLosses = m_ConsecutiveLosses;
            if (profit < m_MaxLossTrade) m_MaxLossTrade = profit;
        }

        UpdateMaxDrawdown();

        if(m_context.pLogger)
            m_context.pLogger->Log(ALERT_LEVEL_INFO, "Stats updated on deal close. Win: " + (string)isWin + ", Profit: " + DoubleToString(profit, 2) + ". Total Trades: " + (string)m_TotalTrades);
    }

    void OnTick() {
        UpdateDailyVars();
        UpdatePauseStatus();
        UpdateMaxDrawdown();
    }

private:
    double CalculateRiskPercentSize(double risk_percent, double stop_loss_pips, bool use_equity = false) {
        if (risk_percent <= 0 || stop_loss_pips <= 0) return 0.0;

        double account_balance = use_equity ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE);
        double risk_amount = account_balance * (risk_percent / 100.0);

        double sl_in_money = 0;
        if(!OrderCalcProfit(ORDER_TYPE_BUY, m_symbol, 1.0, SymbolInfoDouble(m_symbol, SYMBOL_ASK), SymbolInfoDouble(m_symbol, SYMBOL_ASK) - stop_loss_pips * SymbolInfoDouble(m_symbol, SYMBOL_POINT), sl_in_money)) {
             if(m_context.pLogger) m_context.pLogger->LogWarning("Could not calculate profit for SL.");
             return 0.0;
        }
        sl_in_money = MathAbs(sl_in_money);

        if (sl_in_money <= 0) {
            if(m_context && m_context->Logger) m_context->Logger->LogWarning("RiskManager", "Stop loss value in money is zero or negative.");
            return 0.0;
        }

        return risk_amount / sl_in_money;
    }

    double NormalizeLotSize(double lot_size) {
        double volume_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double volume_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
        double volume_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);

        lot_size = floor(lot_size / volume_step) * volume_step;

        if (lot_size < volume_min) lot_size = volume_min;
        if (lot_size > volume_max) lot_size = volume_max;

        return lot_size;
    }

    double CalculateAdaptiveRiskPercent(string &adjustmentReasonOut, double baseRiskPercent) {
        if (!m_context) return 0.0;

        double finalRisk = baseRiskPercent;
        adjustmentReasonOut = "Base Risk: " + DoubleToString(finalRisk, 2) + "%";

        double regimeFactor = GetRegimeFactor(m_context->CurrentMarketRegime, m_IsTransitioningMarket);
        if (MathAbs(regimeFactor - 1.0) > 0.01) {
            finalRisk *= regimeFactor;
            adjustmentReasonOut += "; Regime Factor: " + DoubleToString(regimeFactor, 2);
        }

        double sessionFactor = GetSessionFactor(m_context->CurrentSession, m_context->Symbol);
        if (MathAbs(sessionFactor - 1.0) > 0.01) {
            finalRisk *= sessionFactor;
            adjustmentReasonOut += "; Session Factor: " + DoubleToString(sessionFactor, 2);
        }

        double perfFactor = CalculatePerformanceBasedRiskFactor();
        if (MathAbs(perfFactor - 1.0) > 0.01) {
            finalRisk *= perfFactor;
            adjustmentReasonOut += "; Perf. Factor: " + DoubleToString(perfFactor, 2);
        }
        
        double volFactor = CalculateVolatilityBasedRiskFactor();
        if (MathAbs(volFactor - 1.0) > 0.01) {
            finalRisk *= volFactor;
            adjustmentReasonOut += "; Vol. Factor: " + DoubleToString(volFactor, 2);
        }

        double lossLimitFactor = IsApproachingDailyLossLimit();
        if (lossLimitFactor < 1.0) {
            finalRisk *= lossLimitFactor;
            adjustmentReasonOut += "; Daily Loss Limit Factor: " + DoubleToString(lossLimitFactor, 2);
        }

        finalRisk = fmax(finalRisk, m_context->Inputs.RiskManagement.MinRiskPercent);
        finalRisk = fmin(finalRisk, m_context->Inputs.RiskManagement.MaxRiskPercent);

        return finalRisk;
    }

    double GetRegimeFactor(ENUM_MARKET_REGIME regime, bool isTransitioning) {
        if (isTransitioning) return 0.75;
        switch(regime) {
            case REGIME_TRENDING: return 1.0;
            case REGIME_RANGING:  return 0.8;
            default:              return 0.5;
        }
    }

    double GetSessionFactor(ENUM_SESSION_TYPE session, string symbol) {
        switch(session) {
            case SESSION_LONDON:  return 1.0;
            case SESSION_NEWYORK: return 1.0;
            case SESSION_ASIAN:   return 0.7;
            default:              return 0.8;
        }
    }

    double IsApproachingDailyLossLimit() {
        if (!m_context || m_context->Inputs.RiskManagement.MaxDailyLossPercent <= 0) return 1.0;

        double lossToday = m_DayStartEquity - AccountInfoDouble(ACCOUNT_EQUITY);
        if (lossToday <= 0) return 1.0;

        double lossPercent = (lossToday / m_DayStartEquity) * 100.0;

        if (lossPercent >= m_context->Inputs.RiskManagement.MaxDailyLossPercent) return 0.0; 
        if (lossPercent >= m_context->Inputs.RiskManagement.MaxDailyLossPercent * 0.75) return 0.5;

        return 1.0;
    }

    double CalculatePerformanceBasedRiskFactor() {
        if (m_context->Inputs.RiskManagement.MaxConsecutiveLosses > 0 && m_ConsecutiveLosses >= m_context->Inputs.RiskManagement.MaxConsecutiveLosses) return 0.5;
        if (m_ConsecutiveWins >= 3) return 1.2;
        return 1.0;
    }

    double CalculateVolatilityBasedRiskFactor() {
        if (!m_context || !m_context->MarketData) return 1.0;

        double longTermATR = m_context->MarketData->GetATR(100, 0);
        double shortTermATR = m_context->MarketData->GetATR(20, 0);

        if (longTermATR <= 0) return 1.0;

        double atrRatio = shortTermATR / longTermATR;

        if (atrRatio > 1.5) return 0.75;
        if (atrRatio < 0.6) return 0.8;

        return 1.0;
    }

    void UpdateMaxDrawdown() {
        if (!m_context) return;

        double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

        if (currentEquity > m_PeakEquity) {
            m_PeakEquity = currentEquity;
        } else {
            double currentDrawdown = ((m_PeakEquity - currentEquity) / m_PeakEquity) * 100.0;
            if (currentDrawdown > m_MaxDrawdownRecorded) {
                m_MaxDrawdownRecorded = currentDrawdown;
                if(m_context->Logger) m_context->Logger->LogWarning("RiskManager", "New max drawdown recorded: " + DoubleToString(m_MaxDrawdownRecorded, 2) + "%");
            }
        }

        double dailyLoss = m_DayStartEquity - currentEquity;
        if (dailyLoss > 0) {
            m_DailyLoss = dailyLoss;
        }
    }

    bool IsPaused() const {
        return TimeCurrent() < m_PauseUntil;
    }

    bool IsDailyLossExceeded() const {
        if (!m_context || m_context->Inputs.RiskManagement.MaxDailyLossPercent <= 0 || m_DayStartEquity <= 0) return false;
        double lossPercent = (m_DailyLoss / m_DayStartEquity) * 100.0;
        return lossPercent >= m_context->Inputs.RiskManagement.MaxDailyLossPercent;
    }

    bool IsDrawdownExceeded() const {
        if (!m_context || m_context->Inputs.RiskManagement.MaxDrawdownPercent <= 0) return false;
        return m_MaxDrawdownRecorded >= m_context->Inputs.RiskManagement.MaxDrawdownPercent;
    }

    bool IsSpreadAcceptable() const {
        if (!m_context || m_context->Inputs.RiskManagement.MaxSpreadPoints <= 0) return true;
        double currentSpread = SymbolInfoInteger(m_symbol, SYMBOL_SPREAD);
        return currentSpread <= m_context->Inputs.RiskManagement.MaxSpreadPoints;
    }

    void PauseTrading(int minutes, string reason) {
        if (!m_context || !m_context->Logger) return;
        m_PauseUntil = TimeCurrent() + (minutes * 60);
        m_context->Logger->LogWarning("RiskManager", "Trading paused for " + (string)minutes + " minutes. Reason: " + reason + ". Resumes at: " + TimeToString(m_PauseUntil));
    }

    void UpdateDailyVars() {
        if (!m_context || !m_context->Logger) return;
        int currentDay = GetCurrentDayOfYear();
        if (currentDay != m_CurrentDay) {
            m_context->Logger->LogInfo("RiskManager", "New day detected. Resetting daily statistics.");
            ResetDailyStats(AccountInfoDouble(ACCOUNT_EQUITY));
            m_CurrentDay = currentDay;

            if (TimeDayOfWeek(TimeCurrent()) == 1) { // Monday
                m_WeeklyLoss = 0.0;
                m_context->Logger->LogInfo("RiskManager", "New week detected. Resetting weekly statistics.");
            }
        }
    }

    void UpdatePauseStatus() {
        if (m_PauseUntil > 0 && TimeCurrent() >= m_PauseUntil) {
            ResumeTrading("Auto-resumed after pause period expired.");
        }
    }

    void ResumeTrading(string reason) {
        if (!m_context || !m_context->Logger) return;
        if (m_PauseUntil > 0) {
            m_PauseUntil = 0;
            m_context->Logger->LogInfo("RiskManager", "Trading has been resumed. Reason: " + reason);
        }
    }

    int GetCurrentDayOfYear() {
        MqlDateTime dt;
        TimeToStruct(TimeCurrent(), dt);
        return dt.day_of_year;
    }
};

} // namespace ApexPullback

#endif // RISKMANAGER_MQH_