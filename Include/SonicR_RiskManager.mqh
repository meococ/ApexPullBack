//+------------------------------------------------------------------+
//|                                          SonicR_RiskManager.mqh |
//|             SonicR PropFirm EA - Risk Management Component      |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Include required files
#include "SonicR_Logger.mqh"

// Risk management class optimized for PropFirm challenges
class CRiskManager
{
private:
    // Logger
    CLogger* m_logger;
    
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
    
    // Trade history tracking
    int m_consecutiveWins;           // Consecutive winning trades
    int m_consecutiveLosses;         // Consecutive losing trades
    int m_totalTrades;               // Total trades
    int m_winTrades;                 // Winning trades
    int m_lossTrades;                // Losing trades
    
    // Recovery settings
    bool m_useRecoveryMode;          // Use recovery mode
    double m_recoveryReduceFactor;   // Factor to reduce size in recovery mode
    
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
    
    // Destructor
    ~CRiskManager();
    
    // Main methods
    void Update();
    bool IsTradeAllowed() const;
    double CalculateLotSize(double stopLossDistance, string symbol = NULL);
    double GetLotSizeByRisk(double riskAmount, double stopLossDistance, string symbol = NULL);
    
    // Update trade results
    void UpdateTradeResult(bool isWin);
    
    // Risk state getters
    double GetCurrentDailyDD() const { return m_currentDailyDD; }
    double GetCurrentTotalDD() const { return m_currentTotalDD; }
    double GetRiskPercent() const { return m_baseRiskPercent * m_riskMultiplier; }
    int GetRemainingTrades() const { return MathMax(0, m_maxTradesPerDay - m_todayTrades); }
    bool IsDailyDrawdownExceeded() const { return m_currentDailyDD >= m_maxDailyDD; }
    bool IsTotalDrawdownExceeded() const { return m_currentTotalDD >= m_maxTotalDD; }
    bool IsInEmergencyMode() const { return m_emergencyMode; }
    bool IsInRecoveryMode() const { return m_recoveryMode; }
    
    // Trade history getters
    int GetConsecutiveWins() const { return m_consecutiveWins; }
    int GetConsecutiveLosses() const { return m_consecutiveLosses; }
    int GetTotalTrades() const { return m_totalTrades; }
    double GetWinRate() const { return m_totalTrades > 0 ? (double)m_winTrades / m_totalTrades * 100.0 : 0.0; }
    
    // Settings
    void SetBaseRiskPercent(double value) { m_baseRiskPercent = value; }
    void SetMaxDailyDD(double value) { m_maxDailyDD = value; }
    void SetMaxTotalDD(double value) { m_maxTotalDD = value; }
    void SetMaxTradesPerDay(int value) { m_maxTradesPerDay = value; }
    void SetRiskMultiplier(double value) { m_riskMultiplier = value; }
    
    // Recovery mode settings
    void SetRecoveryMode(bool use, double factor) { 
        m_useRecoveryMode = use; 
        m_recoveryReduceFactor = factor; 
    }
    
    // Set logger
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
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
    m_logger = NULL;
    
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
    
    // Initialize trade history
    m_consecutiveWins = 0;
    m_consecutiveLosses = 0;
    m_totalTrades = 0;
    m_winTrades = 0;
    m_lossTrades = 0;
    
    // Initialize recovery settings
    m_useRecoveryMode = true;
    m_recoveryReduceFactor = 0.5;
    
    // Initialize flags
    m_emergencyMode = false;
    m_recoveryMode = false;
    
    // Perform initial update
    Update();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskManager::~CRiskManager()
{
    // Nothing to clean up
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
        if(m_logger) m_logger.Info("New trading day detected, resetting daily statistics");
        
        // Reset daily counters
        m_startDailyEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        m_todayTrades = 0;
        m_currentDailyDD = 0;
        
        // Store current day
        m_lastDayChecked = todayStart;
        
        // Reset emergency mode if equity is recovering
        if(m_emergencyMode && AccountInfoDouble(ACCOUNT_EQUITY) > m_peakEquity * 0.95) {
            m_emergencyMode = false;
            if(m_logger) m_logger.Info("Emergency mode deactivated, equity recovery detected");
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
        
        // Ensure non-negative
        m_currentDailyDD = MathMax(0, m_currentDailyDD);
    }
    
    // Calculate current total drawdown
    if(m_peakEquity > 0) {
        m_currentTotalDD = (m_peakEquity - currentEquity) / m_peakEquity * 100.0;
        
        // Ensure non-negative
        m_currentTotalDD = MathMax(0, m_currentTotalDD);
    }
    
    // Check for emergency mode
    if(m_currentDailyDD >= m_maxDailyDD * 0.8 || m_currentTotalDD >= m_maxTotalDD * 0.8) {
        if(!m_emergencyMode && m_logger) {
            m_logger.Warning("Emergency mode activated: DD approaching limits (Daily: " + 
                           DoubleToString(m_currentDailyDD, 2) + "%, Total: " + 
                           DoubleToString(m_currentTotalDD, 2) + "%)");
        }
        m_emergencyMode = true;
    }
    
    // Check for recovery mode
    bool prevRecoveryMode = m_recoveryMode;
    
    if(m_currentDailyDD >= m_maxDailyDD * 0.5 || m_currentTotalDD >= m_maxTotalDD * 0.5 || 
       m_consecutiveLosses >= 3) {
        m_recoveryMode = true;
    } else if(m_currentDailyDD < m_maxDailyDD * 0.3 && m_currentTotalDD < m_maxTotalDD * 0.3 && 
             m_consecutiveLosses < 2) {
        m_recoveryMode = false;
    }
    
    // Log recovery mode changes
    if(prevRecoveryMode != m_recoveryMode && m_logger) {
        if(m_recoveryMode) {
            m_logger.Warning("Recovery mode activated: Reducing position sizes");
        } else {
            m_logger.Info("Recovery mode deactivated: Returning to normal position sizes");
        }
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
    if(m_recoveryMode && m_useRecoveryMode) {
        m_riskMultiplier = m_recoveryReduceFactor;
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
    
    // Additional adjustment based on consecutive losses
    if(m_consecutiveLosses >= 2) {
        m_riskMultiplier *= (1.0 - MathMin(0.5, 0.15 * m_consecutiveLosses));
    }
    
    // Additional adjustment based on win rate
    double winRate = GetWinRate();
    if(m_totalTrades >= 10 && winRate < 40) {
        m_riskMultiplier *= 0.8; // Reduce risk if win rate is low
    }
    
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
        if(m_logger) m_logger.Debug("Trading not allowed: Emergency mode active");
        return false;
    }
    
    // Don't trade if daily drawdown exceeded
    if(m_currentDailyDD >= m_maxDailyDD) {
        if(m_logger) m_logger.Debug("Trading not allowed: Daily drawdown limit reached (" + 
                                   DoubleToString(m_currentDailyDD, 2) + "% >= " + 
                                   DoubleToString(m_maxDailyDD, 2) + "%)");
        return false;
    }
    
    // Don't trade if total drawdown exceeded
    if(m_currentTotalDD >= m_maxTotalDD) {
        if(m_logger) m_logger.Debug("Trading not allowed: Total drawdown limit reached (" + 
                                   DoubleToString(m_currentTotalDD, 2) + "% >= " + 
                                   DoubleToString(m_maxTotalDD, 2) + "%)");
        return false;
    }
    
    // Don't trade if max trades per day reached
    if(m_todayTrades >= m_maxTradesPerDay) {
        if(m_logger) m_logger.Debug("Trading not allowed: Max daily trades reached (" + 
                                   IntegerToString(m_todayTrades) + " >= " + 
                                   IntegerToString(m_maxTradesPerDay) + ")");
        return false;
    }
    
    // Don't trade if consecutive losses are too high and not in recovery mode
    if(m_consecutiveLosses >= 5 && !m_recoveryMode) {
        if(m_logger) m_logger.Debug("Trading not allowed: Too many consecutive losses (" + 
                                   IntegerToString(m_consecutiveLosses) + ")");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CRiskManager::CalculateLotSize(double stopLossDistance, string symbol = NULL)
{
    // Use adjusted risk percent
    double riskPercent = GetRiskPercent();
    
    // Default to current symbol if not specified
    if(symbol == NULL || symbol == "") {
        symbol = _Symbol;
    }
    
    // Calculate risk amount in account currency
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double riskAmount = equity * (riskPercent / 100.0);
    
    // Get lot size based on risk amount
    return GetLotSizeByRisk(riskAmount, stopLossDistance, symbol);
}

//+------------------------------------------------------------------+
//| Get lot size based on risk amount and stop loss distance         |
//+------------------------------------------------------------------+
double CRiskManager::GetLotSizeByRisk(double riskAmount, double stopLossDistance, string symbol = NULL)
{
    // Default to current symbol if not specified
    if(symbol == NULL || symbol == "") {
        symbol = _Symbol;
    }
    
    // Safety check for valid inputs
    if(stopLossDistance <= 0) {
        if(m_logger) m_logger.Warning("Invalid stop loss distance: " + DoubleToString(stopLossDistance, _Digits));
        return 0.01; // Minimum lot size as fallback
    }
    
    // Get contract specification values
    double tickSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    double pointValue = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Calculate stop loss in points
    double stopLossPoints = stopLossDistance / pointValue;
    
    // Calculate lot size
    double lotSize = 0;
    if(stopLossPoints > 0 && tickValue > 0) {
        lotSize = riskAmount / (stopLossPoints * tickValue / tickSize);
    }
    
    // Round to standard lot size
    double minLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double lotStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
    
    // Round down to nearest lot step
    lotSize = MathFloor(lotSize / lotStep) * lotStep;
    
    // Ensure lot size is within allowed range
    lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
    
    // Log the calculated lot size
    if(m_logger) {
        m_logger.Debug("Lot size calculation: Risk=" + DoubleToString(riskAmount, 2) + 
                      ", SL=" + DoubleToString(stopLossDistance, _Digits) + 
                      " (" + DoubleToString(stopLossPoints, 1) + " pts), Lot=" + 
                      DoubleToString(lotSize, 2));
    }
    
    // Increment trade counter
    m_todayTrades++;
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Update trade result (win/loss)                                   |
//+------------------------------------------------------------------+
void CRiskManager::UpdateTradeResult(bool isWin)
{
    m_totalTrades++;
    
    if(isWin) {
        m_winTrades++;
        m_consecutiveWins++;
        m_consecutiveLosses = 0;
        
        if(m_logger) {
            m_logger.Info("Trade result: WIN, Consecutive wins: " + IntegerToString(m_consecutiveWins) + 
                         ", Win rate: " + DoubleToString(GetWinRate(), 1) + "%");
        }
    } else {
        m_lossTrades++;
        m_consecutiveLosses++;
        m_consecutiveWins = 0;
        
        if(m_logger) {
            m_logger.Info("Trade result: LOSS, Consecutive losses: " + IntegerToString(m_consecutiveLosses) + 
                         ", Win rate: " + DoubleToString(GetWinRate(), 1) + "%");
        }
    }
    
    // Update risk settings after trade result
    Update();
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
    
    // Performance stats
    status += "Total Trades: " + IntegerToString(m_totalTrades) + ", Win Rate: " + DoubleToString(GetWinRate(), 1) + "%\n";
    status += "Consecutive: " + IntegerToString(m_consecutiveWins) + " wins, " + IntegerToString(m_consecutiveLosses) + " losses\n";
    
    // Mode flags
    status += "Emergency Mode: " + (m_emergencyMode ? "YES" : "No") + "\n";
    status += "Recovery Mode: " + (m_recoveryMode ? "YES" : "No") + "\n";
    
    // Trading allowed
    status += "Trading Allowed: " + (IsTradeAllowed() ? "Yes" : "NO") + "\n";
    
    return status;
}