//+------------------------------------------------------------------+
//|                                                 RiskManager.mqh |
//|                           SonicR PropFirm EA - Risk Management |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef RISK_MANAGER_MQH
#define RISK_MANAGER_MQH

// Risk management class optimized for PropFirm challenges
class CRiskManager
{
private:
    // Risk settings
    double m_baseRiskPercent;        // Base risk percent per trade
    double m_riskMultiplier;         // Risk multiplier (adjusts risk based on conditions)
    double m_maxDailyDD;             // Maximum daily drawdown allowed
    double m_maxTotalDD;             // Maximum total drawdown allowed
    int m_maxTradesPerDay;           // Maximum trades per day
    
    // Risk tracking
    double m_startDailyEquity;       // Starting equity for the day
    double m_peakEquity;             // Peak equity reached
    double m_lowestEquity;           // Lowest equity reached
    double m_currentDailyDD;         // Current daily drawdown
    double m_currentTotalDD;         // Current total drawdown
    int m_todayTrades;               // Number of trades taken today
    datetime m_lastDayChecked;       // Last day checked for reset
    
    // Emergency flags
    bool m_emergencyMode;            // Emergency mode (high drawdown)
    bool m_recoveryMode;             // Recovery mode (after drawdown)
    
    // Helper methods
    void UpdateEquityStats();
    void CheckNewDay();
    void AdjustRiskMultiplier();
    double CalculateEquityPercent(double moneyAmount) const;
    double CalculateMoneyAmount(double equityPercent) const;
    double CalculateAccountRelativeRisk() const;
    
public:
    // Constructor
    CRiskManager(double baseRiskPercent = 0.5, 
                double maxDailyDD = 3.0, 
                double maxTotalDD = 5.0, 
                int maxTradesPerDay = 3);
    
    // Main methods
    void Update();
    bool IsTradeAllowed() const;
    double CalculateLotSize(double riskPercent, double entryPrice, double stopLoss);
    
    // Risk state getters
    double GetCurrentDailyDD() const { return m_currentDailyDD; }
    double GetCurrentTotalDD() const { return m_currentTotalDD; }
    double GetRiskPercent() const { return m_baseRiskPercent * m_riskMultiplier; }
    int GetRemainingTrades() const { return MathMax(0, m_maxTradesPerDay - m_todayTrades); }
    bool IsDailyDrawdownExceeded() const { return m_currentDailyDD >= m_maxDailyDD; }
    bool IsTotalDrawdownExceeded() const { return m_currentTotalDD >= m_maxTotalDD; }
    bool IsInEmergencyMode() const { return m_emergencyMode; }
    bool IsInRecoveryMode() const { return m_recoveryMode; }
    
    // Settings
    void SetBaseRiskPercent(double value) { m_baseRiskPercent = value; }
    void SetMaxDailyDD(double value) { m_maxDailyDD = value; }
    void SetMaxTotalDD(double value) { m_maxTotalDD = value; }
    void SetMaxTradesPerDay(int value) { m_maxTradesPerDay = value; }
    void SetRiskMultiplier(double value) { m_riskMultiplier = value; }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskManager::CRiskManager(double baseRiskPercent = 0.5, 
                         double maxDailyDD = 3.0, 
                         double maxTotalDD = 5.0, 
                         int maxTradesPerDay = 3)
{
    // Initialize settings
    m_baseRiskPercent = baseRiskPercent;
    m_riskMultiplier = 1.0;
    m_maxDailyDD = maxDailyDD;
    m_maxTotalDD = maxTotalDD;
    m_maxTradesPerDay = maxTradesPerDay;
    
    // Initialize tracking variables
    m_startDailyEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    m_peakEquity = m_startDailyEquity;
    m_lowestEquity = m_startDailyEquity;
    m_currentDailyDD = 0;
    m_currentTotalDD = 0;
    m_todayTrades = 0;
    m_lastDayChecked = 0;
    
    // Initialize flags
    m_emergencyMode = false;
    m_recoveryMode = false;
    
    // Perform initial update
    Update();
}

//+------------------------------------------------------------------+
//| Update risk statistics                                           |
//+------------------------------------------------------------------+
void CRiskManager::Update()
{
    // Check for new day
    CheckNewDay();
    
    // Update equity statistics
    UpdateEquityStats();
    
    // Adjust risk multiplier based on current conditions
    AdjustRiskMultiplier();
}

//+------------------------------------------------------------------+
//| Check for a new trading day                                      |
//+------------------------------------------------------------------+
void CRiskManager::CheckNewDay()
{
    MqlDateTime now;
    TimeToStruct(TimeCurrent(), now);
    
    // Create a datetime for current day at 00:00
    MqlDateTime today;
    today.year = now.year;
    today.mon = now.mon;
    today.day = now.day;
    today.hour = 0;
    today.min = 0;
    today.sec = 0;
    
    datetime todayStart = StructToTime(today);
    
    // Check if we've moved to a new day
    if(todayStart != m_lastDayChecked) {
        // Reset daily counters
        m_startDailyEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        m_todayTrades = 0;
        m_currentDailyDD = 0;
        
        // Store current day
        m_lastDayChecked = todayStart;
        
        // Reset emergency mode if equity is recovering
        if(m_emergencyMode && AccountInfoDouble(ACCOUNT_EQUITY) > m_peakEquity * 0.95) {
            m_emergencyMode = false;
        }
    }
}

//+------------------------------------------------------------------+
//| Update equity statistics                                         |
//+------------------------------------------------------------------+
void CRiskManager::UpdateEquityStats()
{
    // Get current equity
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // Update peak equity if current equity is higher
    if(currentEquity > m_peakEquity) {
        m_peakEquity = currentEquity;
    }
    
    // Update lowest equity if current equity is lower
    if(currentEquity < m_lowestEquity) {
        m_lowestEquity = currentEquity;
    }
    
    // Calculate current daily drawdown
    if(m_startDailyEquity > 0) {
        m_currentDailyDD = (m_startDailyEquity - currentEquity) / m_startDailyEquity * 100.0;
    }
    
    // Calculate current total drawdown
    if(m_peakEquity > 0) {
        m_currentTotalDD = (m_peakEquity - currentEquity) / m_peakEquity * 100.0;
    }
    
    // Check for emergency mode
    if(m_currentDailyDD >= m_maxDailyDD * 0.8 || m_currentTotalDD >= m_maxTotalDD * 0.8) {
        m_emergencyMode = true;
    }
    
    // Check for recovery mode
    if(m_currentDailyDD >= m_maxDailyDD * 0.5 || m_currentTotalDD >= m_maxTotalDD * 0.5) {
        m_recoveryMode = true;
    } else if(m_currentDailyDD < m_maxDailyDD * 0.3 && m_currentTotalDD < m_maxTotalDD * 0.3) {
        m_recoveryMode = false;
    }
}

//+------------------------------------------------------------------+
//| Adjust risk multiplier based on account conditions               |
//+------------------------------------------------------------------+
void CRiskManager::AdjustRiskMultiplier()
{
    // Default multiplier
    m_riskMultiplier = 1.0;
    
    // Reduce risk when in recovery mode
    if(m_recoveryMode) {
        m_riskMultiplier = 0.5;
    }
    
    // Reduce risk when approaching max trades per day
    if(m_todayTrades >= m_maxTradesPerDay - 1) {
        m_riskMultiplier *= 0.75;
    }
    
    // Reduce risk when approaching max daily drawdown
    double ddRatio = m_currentDailyDD / m_maxDailyDD;
    if(ddRatio > 0.5) {
        m_riskMultiplier *= (1.0 - ddRatio * 0.5);
    }
    
    // Reduce risk when approaching max total drawdown
    double totalDDRatio = m_currentTotalDD / m_maxTotalDD;
    if(totalDDRatio > 0.5) {
        m_riskMultiplier *= (1.0 - totalDDRatio * 0.5);
    }
    
    // Apply additional risk adjustment based on account size variance
    m_riskMultiplier *= CalculateAccountRelativeRisk();
    
    // Ensure multiplier doesn't go below 0.25 or above 1.2
    m_riskMultiplier = MathMax(0.25, MathMin(1.2, m_riskMultiplier));
}

//+------------------------------------------------------------------+
//| Calculate risk adjustment based on account size                  |
//+------------------------------------------------------------------+
double CRiskManager::CalculateAccountRelativeRisk() const
{
    // Get account balance
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Base this on common PropFirm account sizes
    if(balance < 10000) {
        return 0.9; // Slightly lower risk for small accounts
    } else if(balance > 100000) {
        return 1.1; // Slightly higher risk allowed for large accounts
    }
    
    return 1.0; // Normal risk for typical account size
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool CRiskManager::IsTradeAllowed() const
{
    // Don't trade if in emergency mode
    if(m_emergencyMode) {
        return false;
    }
    
    // Don't trade if daily drawdown exceeded
    if(m_currentDailyDD >= m_maxDailyDD) {
        return false;
    }
    
    // Don't trade if total drawdown exceeded
    if(m_currentTotalDD >= m_maxTotalDD) {
        return false;
    }
    
    // Don't trade if max trades per day reached
    if(m_todayTrades >= m_maxTradesPerDay) {
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double riskPercent, double entryPrice, double stopLoss)
{
    // Safety check for valid inputs
    if(entryPrice <= 0 || stopLoss <= 0 || MathAbs(entryPrice - stopLoss) < _Point) {
        return 0.01; // Minimum lot size as fallback
    }
    
    // Calculate risk amount in account currency
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double riskAmount = equity * (riskPercent / 100.0);
    
    // Get tick size and value
    double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
    
    // Calculate stop loss distance in price points
    double stopLossDistance = MathAbs(entryPrice - stopLoss);
    double points = stopLossDistance / tickSize;
    
    // Calculate lot size
    double lotSize = 0;
    if(points > 0 && tickValue > 0) {
        lotSize = riskAmount / (points * tickValue);
    }
    
    // Round to standard lot size
    double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Round down to nearest lot step
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    // Ensure lot size is within allowed range
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    // In emergency mode, use half the calculated lot size
    if(m_emergencyMode) {
        lotSize *= 0.5;
    }
    
    // In recovery mode, adjust lot size
    if(m_recoveryMode) {
        lotSize *= 0.75;
    }
    
    // Increment trade counter
    m_todayTrades++;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate equity percentage from money amount                    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateEquityPercent(double moneyAmount) const
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    if(equity <= 0) return 0;
    
    return (moneyAmount / equity) * 100.0;
}

//+------------------------------------------------------------------+
//| Calculate money amount from equity percentage                    |
//+------------------------------------------------------------------+
double CRiskManager::CalculateMoneyAmount(double equityPercent) const
{
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    return equity * (equityPercent / 100.0);
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CRiskManager::GetStatusText() const
{
    string status = "Risk Manager Status:\n";
    
    // Risk settings
    status += "Base Risk: " + DoubleToString(m_baseRiskPercent, 2) + "%\n";
    status += "Current Risk: " + DoubleToString(GetRiskPercent(), 2) + "%\n";
    status += "Risk Multiplier: " + DoubleToString(m_riskMultiplier, 2) + "\n";
    
    // Drawdown status
    status += "Daily DD: " + DoubleToString(m_currentDailyDD, 2) + "% (Max: " + DoubleToString(m_maxDailyDD, 2) + "%)\n";
    status += "Total DD: " + DoubleToString(m_currentTotalDD, 2) + "% (Max: " + DoubleToString(m_maxTotalDD, 2) + "%)\n";
    
    // Trade counts
    status += "Trades Today: " + IntegerToString(m_todayTrades) + " (Max: " + IntegerToString(m_maxTradesPerDay) + ")\n";
    status += "Remaining Trades: " + IntegerToString(GetRemainingTrades()) + "\n";
    
    // Mode flags
    status += "Emergency Mode: " + (m_emergencyMode ? "YES" : "No") + "\n";
    status += "Recovery Mode: " + (m_recoveryMode ? "YES" : "No") + "\n";
    
    // Trading allowed
    status += "Trading Allowed: " + (IsTradeAllowed() ? "Yes" : "NO") + "\n";
    
    return status;
}

#endif // RISK_MANAGER_MQH