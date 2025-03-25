//+------------------------------------------------------------------+
//|                                      SonicR_EntryManager.mqh     |
//|             SonicR PropFirm EA - Trade Entry Management Component|
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Thư viện MT5 tiêu chuẩn
#include <Trade/Trade.mqh>

// Forward declarations
class CLogger;
class CSonicRCore;
class CRiskManager;
class CSonicRSR;

// Include dependencies
#include "SonicR_Logger.mqh"
#include "SonicR_Core.mqh"
#include "SonicR_RiskManager.mqh"

// Entry manager class for trade entry decisions and execution
class CEntryManager
{
private:
    // Dependencies
    CLogger* m_logger;
    CSonicRCore* m_core;
    CRiskManager* m_riskManager;
    CTrade* m_trade;
    CSonicRSR* m_srSystem;
    
    // Signal properties
    int m_currentSignal;           // Current signal (1=Buy, -1=Sell, 0=None)
    double m_signalQuality;        // Quality of current signal (0-100)
    datetime m_signalTime;         // Time when signal was detected
    
    // Entry settings
    double m_minRR;                // Minimum risk/reward ratio
    double m_minSignalQuality;     // Minimum signal quality to consider
    bool m_useScoutEntries;        // Use early (scout) entries
    
    // Execution settings
    int m_maxRetryAttempts;        // Maximum retry attempts for trade execution
    int m_retryDelayMs;            // Delay between retry attempts (milliseconds)
    
    // Entry points
    double m_entryPrice;           // Calculated entry price
    double m_stopLoss;             // Calculated stop loss
    double m_takeProfit;           // Calculated take profit
    
    // Helper methods
    bool ValidateSignal(int signal);
    double CalculateRiskRewardRatio(double entry, double sl, double tp);
    bool IsSpreadAcceptable();
    double GetMaxAllowedSpread();
    
public:
    // Constructor
    CEntryManager(CSonicRCore* core = NULL, 
                 CRiskManager* riskManager = NULL, 
                 CTrade* trade = NULL);
    
    // Destructor
    ~CEntryManager();
    
    // Main methods
    int CheckForSignal();
    bool PrepareEntry(int signal);
    bool ExecuteTrade();
    
    // Signal info
    int GetCurrentSignal() const { return m_currentSignal; }
    double GetSignalQuality() const { return m_signalQuality; }
    datetime GetSignalTime() const { return m_signalTime; }
    
    // Entry points
    double GetEntryPrice() const { return m_entryPrice; }
    double GetStopLoss() const { return m_stopLoss; }
    double GetTakeProfit() const { return m_takeProfit; }
    
    // Settings
    void SetMinRR(double minRR) { m_minRR = minRR; }
    void SetMinSignalQuality(double minQuality) { m_minSignalQuality = minQuality; }
    void SetUseScoutEntries(bool useScout) { m_useScoutEntries = useScout; }
    void SetRetrySettings(int maxAttempts, int delayMs) {
        m_maxRetryAttempts = maxAttempts; 
        m_retryDelayMs = delayMs;
    }
    
    // Set dependencies
    void SetCore(CSonicRCore* core) { m_core = core; }
    void SetRiskManager(CRiskManager* riskManager) { m_riskManager = riskManager; }
    void SetTrade(CTrade* trade) { m_trade = trade; }
    void SetLogger(CLogger* logger) { m_logger = logger; }
    void SetSRSystem(CSonicRSR* srSystem) { m_srSystem = srSystem; }
    
    // Utility
    string GetStatusText() const;
    string GetSignalDescription() const;
    double CalculateRiskRewardRatio() const;
    bool IsSpreadAcceptable();
    
    // For unit testing
    void SetEntryPoints(double entry, double sl, double tp) {
        m_entryPrice = entry;
        m_stopLoss = sl;
        m_takeProfit = tp;
    }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CEntryManager::CEntryManager(CSonicRCore* core, 
                           CRiskManager* riskManager, 
                           CTrade* trade)
{
    m_logger = NULL;
    m_core = core;
    m_riskManager = riskManager;
    m_trade = trade;
    m_srSystem = NULL;  // Khởi tạo giá trị mặc định
    
    // Initialize signal properties
    m_currentSignal = 0;
    m_signalQuality = 0.0;
    m_signalTime = 0;
    
    // Initialize entry settings
    m_minRR = 1.5;
    m_minSignalQuality = 70.0;
    m_useScoutEntries = false;
    
    // Initialize execution settings
    m_maxRetryAttempts = 3;
    m_retryDelayMs = 200;
    
    // Initialize entry points
    m_entryPrice = 0.0;
    m_stopLoss = 0.0;
    m_takeProfit = 0.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CEntryManager::~CEntryManager()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Check for trading signal                                         |
//+------------------------------------------------------------------+
int CEntryManager::CheckForSignal()
{
    // Check if dependencies are set
    if(!m_core) {
        if(m_logger) m_logger.Error("Cannot check signal: Core not set");
        return 0;
    }
    
    // Reset signal first
    m_currentSignal = 0;
    m_signalQuality = 0.0;
    
    // Check for classic setup (main strategy)
    int signal = m_core.DetectClassicSetup();
    double quality = 80.0;  // Base quality for classic setup
    
    // If no classic setup and scout entries are enabled, check for scout setup
    if(signal == 0 && m_useScoutEntries) {
        signal = m_core.DetectScoutSetup();
        quality = 70.0;  // Lower base quality for scout setup
    }
    
    // If signal found, validate it
    if(signal != 0) {
        if(ValidateSignal(signal)) {
            m_currentSignal = signal;
            m_signalQuality = quality;
            m_signalTime = TimeCurrent();
            
            if(m_logger) {
                m_logger.Info("Signal detected: " + (signal > 0 ? "BUY" : "SELL") + 
                            " with quality " + DoubleToString(m_signalQuality, 1));
            }
        }
        else {
            if(m_logger) {
                m_logger.Debug("Signal found but validation failed: " + (signal > 0 ? "BUY" : "SELL"));
            }
        }
    }
    
    return m_currentSignal;
}

//+------------------------------------------------------------------+
//| Validate signal with additional checks                           |
//+------------------------------------------------------------------+
bool CEntryManager::ValidateSignal(int signal)
{
    // Check for alignment with multi-timeframe trend
    int h4Trend = m_core.GetH4Trend();
    int d1Trend = m_core.GetDailyTrend();
    
    // For BUY signal, at least one higher timeframe should be bullish
    if(signal > 0 && h4Trend <= 0 && d1Trend <= 0) {
        if(m_logger) m_logger.Debug("BUY signal rejected: No higher timeframe bullish trend");
        return false;
    }
    
    // For SELL signal, at least one higher timeframe should be bearish
    if(signal < 0 && h4Trend >= 0 && d1Trend >= 0) {
        if(m_logger) m_logger.Debug("SELL signal rejected: No higher timeframe bearish trend");
        return false;
    }
    
    // Confirm pullback is valid
    if(!m_core.IsPullbackValid(signal)) {
        if(m_logger) m_logger.Debug("Signal rejected: No valid pullback detected");
        return false;
    }
    
    // Dragon-Trend alignment check
    if(signal > 0 && !m_core.IsAlignedBullish()) {
        if(m_logger) m_logger.Debug("BUY signal rejected: Dragon-Trend not aligned bullish");
        return false;
    }
    
    if(signal < 0 && !m_core.IsAlignedBearish()) {
        if(m_logger) m_logger.Debug("SELL signal rejected: Dragon-Trend not aligned bearish");
        return false;
    }
    
    // Kiểm tra NULL trước khi sử dụng
    if(m_core == NULL) {
        if(m_logger) m_logger.Error("Cannot check PVSRA: Core is NULL");
        return false;
    }
    
    // PVSRA confirmation check (optional)
    if(!m_core.IsPVSRAConfirming(signal)) {
        // Lower quality rather than reject completely
        m_signalQuality -= 10.0;
        if(m_logger) m_logger.Debug("Signal quality reduced: PVSRA not confirming");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Prepare entry with price, SL and TP calculations                 |
//+------------------------------------------------------------------+
bool CEntryManager::PrepareEntry(int signal)
{
    // Check if dependencies are set
    if(!m_core) {
        if(m_logger) m_logger.Error("Cannot prepare entry: Core not set");
        return false;
    }
    
    // Reset entry points
    m_entryPrice = 0.0;
    m_stopLoss = 0.0;
    m_takeProfit = 0.0;
    
    // Skip if no signal or different signal
    if(signal == 0 || signal != m_currentSignal) {
        if(m_logger) m_logger.Warning("Cannot prepare entry: Signal mismatch");
        return false;
    }
    
    // Get current market conditions
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    
    // Check if spread is acceptable
    if(!IsSpreadAcceptable()) {
        if(m_logger) {
            m_logger.Warning("Spread too high for entry: " + 
                           DoubleToString(spread/Point(), 1) + " pts");
        }
        return false;
    }
    
    // Calculate entry, SL and TP
    if(!m_core.CalculateTradeLevels(signal, m_entryPrice, m_stopLoss, m_takeProfit)) {
        if(m_logger) m_logger.Error("Failed to calculate trade levels");
        return false;
    }
    
    // Calculate R:R ratio
    double rr = CalculateRiskRewardRatio(m_entryPrice, m_stopLoss, m_takeProfit);
    
    // Check if R:R is acceptable
    if(rr < m_minRR) {
        if(m_logger) {
            m_logger.Warning("R:R ratio too low: " + DoubleToString(rr, 2) + 
                           " (min: " + DoubleToString(m_minRR, 2) + ")");
        }
        return false;
    }
    
    if(m_logger) {
        m_logger.Info("Entry prepared: " + (signal > 0 ? "BUY" : "SELL") + 
                    " Entry: " + DoubleToString(m_entryPrice, _Digits) + 
                    " SL: " + DoubleToString(m_stopLoss, _Digits) + 
                    " TP: " + DoubleToString(m_takeProfit, _Digits) + 
                    " R:R: " + DoubleToString(rr, 2));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Execute trade based on prepared entry                            |
//+------------------------------------------------------------------+
bool CEntryManager::ExecuteTrade()
{
    // Check if dependencies are set
    if(!m_core || !m_riskManager || !m_trade) {
        if(m_logger) m_logger.Error("Cannot execute trade: Dependencies not set");
        return false;
    }
    
    // Check if entry is prepared
    if(m_entryPrice == 0.0 || m_stopLoss == 0.0 || m_takeProfit == 0.0) {
        if(m_logger) m_logger.Error("Cannot execute trade: Entry not prepared");
        return false;
    }
    
    // Calculate stop loss distance
    double slDistance = MathAbs(m_entryPrice - m_stopLoss);
    
    // Calculate lot size based on risk
    double lotSize = m_riskManager.CalculateLotSize(slDistance);
    
    if(lotSize <= 0.0) {
        if(m_logger) m_logger.Error("Cannot execute trade: Invalid lot size");
        return false;
    }
    
    // Prepare trade request
    m_trade.SetExpertMagicNumber(MagicNumber); // Make sure magic number is set
    
    bool result = false;
    
    if(m_currentSignal > 0) {
        // Buy order
        result = m_trade.Buy(lotSize, _Symbol, 0.0, m_stopLoss, m_takeProfit, "SonicR PropFirm EA");
    }
    else if(m_currentSignal < 0) {
        // Sell order
        result = m_trade.Sell(lotSize, _Symbol, 0.0, m_stopLoss, m_takeProfit, "SonicR PropFirm EA");
    }
    
    // Check result
    if(result) {
        if(m_logger) {
            m_logger.Info("Trade executed: " + (m_currentSignal > 0 ? "BUY" : "SELL") + 
                        " " + DoubleToString(lotSize, 2) + " lots at market");
        }
        
        // Reset signal after successful execution
        m_currentSignal = 0;
        m_signalQuality = 0.0;
        
        return true;
    }
    else {
        if(m_logger) {
            int errorCode = m_trade.ResultRetcode();
            string errorDesc = m_trade.ResultRetcodeDescription();
            
            m_logger.Error("Trade execution failed: " + IntegerToString(errorCode) + 
                         " (" + errorDesc + ")");
        }
        
        return false;
    }
}

//+------------------------------------------------------------------+
//| Calculate risk/reward ratio                                      |
//+------------------------------------------------------------------+
double CEntryManager::CalculateRiskRewardRatio(double entry, double sl, double tp)
{
    if(entry <= 0.0 || sl <= 0.0 || tp <= 0.0) return 0.0;
    if(MathAbs(entry - sl) <= 0.0) return 0.0;
    
    // Calculate distances
    double risk = MathAbs(entry - sl);
    double reward = MathAbs(entry - tp);
    
    // Calculate R:R
    return reward / risk;
}

//+------------------------------------------------------------------+
//| Check if spread is acceptable for trade entry                    |
//+------------------------------------------------------------------+
bool CEntryManager::IsSpreadAcceptable()
{
    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double maxAllowedSpread;
    
    // Điều chỉnh theo cặp tiền
    if(_Symbol == "EURUSD" || _Symbol == "GBPUSD")
        maxAllowedSpread = 10.0;  // 1.0 pip với broker 5 chữ số
    else if(_Symbol == "USDJPY" || _Symbol == "USDCAD")
        maxAllowedSpread = 12.0;  // 1.2 pip
    else if(_Symbol == "XAUUSD") // Gold
        maxAllowedSpread = 50.0;  // 5.0 pip
    else
        maxAllowedSpread = 20.0;  // Mặc định
        
    // Điều chỉnh thêm theo thời điểm trong ngày
    int hour = TimeHour(TimeCurrent());
    if(hour >= 0 && hour < 6)  // Asian session thường spread cao hơn
        maxAllowedSpread *= 1.5;
    else if(hour == 12 || hour == 13)  // London-NY overlap có thể spread thấp hơn
        maxAllowedSpread *= 0.8;
    
    // Lấy ngày trong tuần (0=CN, 1=T2, ..., 5=T6)
    int dayOfWeek = TimeDayOfWeek(TimeCurrent());
    if(dayOfWeek == 5 && hour >= 19)  // Thứ 6 cuối ngày
        maxAllowedSpread *= 1.5;  // Cho phép spread cao hơn
    
    bool isAcceptable = (currentSpread <= maxAllowedSpread);
    
    if(!isAcceptable && m_logger) {
        m_logger.Warning("Spread quá cao: " + IntegerToString((int)currentSpread) + 
                       " điểm (tối đa: " + IntegerToString((int)maxAllowedSpread) + ")");
    }
    
    return isAcceptable;
}

//+------------------------------------------------------------------+
//| Get maximum allowed spread based on symbol                       |
//+------------------------------------------------------------------+
double CEntryManager::GetMaxAllowedSpread()
{
    // Default max spread (in points)
    double maxSpread = 10.0 * Point();
    
    // Adjust based on symbol
    string symbol = _Symbol;
    
    if(symbol == "EURUSD" || symbol == "GBPUSD") {
        maxSpread = 1.0 * Point();
    }
    else if(symbol == "USDJPY" || symbol == "USDCAD" || symbol == "USDCHF") {
        maxSpread = 1.2 * Point();
    }
    else if(symbol == "AUDUSD" || symbol == "NZDUSD") {
        maxSpread = 1.5 * Point();
    }
    else if(symbol == "GBPJPY" || symbol == "EURJPY") {
        maxSpread = 2.0 * Point();
    }
    else if(symbol == "XAUUSD") {
        maxSpread = 35.0 * Point();  // Gold typically has wider spread
    }
    
    return maxSpread;
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CEntryManager::GetStatusText() const
{
    string status = "Entry Manager Status:\n";
    
    // Signal info
    status += "Current Signal: " + (m_currentSignal > 0 ? "BUY" : 
                                 (m_currentSignal < 0 ? "SELL" : "NONE")) + "\n";
    
    if(m_currentSignal != 0) {
        status += "Signal Quality: " + DoubleToString(m_signalQuality, 1) + "\n";
        status += "Signal Time: " + TimeToString(m_signalTime) + "\n";
        
        // Entry points if prepared
        if(m_entryPrice > 0) {
            status += "Entry: " + DoubleToString(m_entryPrice, _Digits) + "\n";
            status += "SL: " + DoubleToString(m_stopLoss, _Digits) + "\n";
            status += "TP: " + DoubleToString(m_takeProfit, _Digits) + "\n";
            
            double rr = CalculateRiskRewardRatio(m_entryPrice, m_stopLoss, m_takeProfit);
            status += "R:R Ratio: " + DoubleToString(rr, 2) + "\n";
        }
    }
    
    // Settings
    status += "Min R:R: " + DoubleToString(m_minRR, 1) + "\n";
    status += "Min Quality: " + DoubleToString(m_minSignalQuality, 1) + "\n";
    status += "Scout Entries: " + (m_useScoutEntries ? "Enabled" : "Disabled") + "\n";
    
    // Market conditions
    double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    status += "Current Spread: " + DoubleToString(spread/Point(), 1) + " pts\n";
    status += "Max Allowed: " + DoubleToString(GetMaxAllowedSpread()/Point(), 1) + " pts\n";
    
    return status;
}