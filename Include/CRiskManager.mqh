//+------------------------------------------------------------------+
//| CRiskManager.mqh - Risk calculation and management component      |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

// Forward declaration
class CLogger;

//+------------------------------------------------------------------+
//| CRiskManager Class - Handles all risk calculations and monitoring |
//+------------------------------------------------------------------+
class CRiskManager {
private:
    // Risk settings
    double m_riskPercent;               // Risk per trade (percentage of account)
    double m_maxDailyDrawdown;          // Maximum daily drawdown percentage
    double m_maxTotalDrawdown;          // Maximum total drawdown percentage
    int m_maxDailyTrades;               // Maximum trades per day
    int m_maxConcurrentTrades;          // Maximum concurrent open trades
    double m_portfolioMaxRisk;          // Maximum portfolio risk percentage
    double m_maxCorrelationThreshold;   // Maximum correlation threshold
    
    // PropFirm settings
    ENUM_PROP_FIRM_TYPE m_propFirmType; // PropFirm type
    ENUM_CHALLENGE_PHASE m_challengePhase; // Challenge phase
    PropFirmRules m_propFirmRules;      // PropFirm rules configuration
    
    // State variables
    double m_currentEquity;             // Current account equity
    double m_startDayEquity;            // Starting equity for the day
    double m_startWeekEquity;           // Starting equity for the week
    double m_startMonthEquity;          // Starting equity for the month
    double m_highWaterMark;             // Highest equity point reached
    double m_dailyDrawdown;             // Current daily drawdown percentage
    double m_totalDrawdown;             // Current total drawdown percentage
    int m_dailyTradesCount;             // Number of trades taken today
    double m_portfolioRisk;             // Current portfolio risk
    int m_consecutiveLosses;            // Current consecutive losses
    
    // Date tracking
    datetime m_lastDayChecked;          // Last day checked for reset
    datetime m_lastWeekChecked;         // Last week checked for reset
    datetime m_lastMonthChecked;        // Last month checked for reset
    datetime m_lastUpdateTime;          // Last time metrics were updated
    
    // Symbol correlations
    CorrelationInfo m_correlations[];   // Array of correlation info
    int m_maxCorrelationCache;          // Maximum size of correlation cache
    
    // Logger
    CLogger* m_logger;                  // Logger reference
    
    //--- Private methods
    
    // Configure PropFirm rules based on type and phase
    void ConfigurePropFirmRules() {
        // Reset to defaults
        m_propFirmRules = PropFirmRules();
        
        // Set firm name
        switch(m_propFirmType) {
            case PROP_FIRM_FTMO:
                m_propFirmRules.firmName = "FTMO";
                
                // Set rules based on phase
                switch(m_challengePhase) {
                    case PHASE_CHALLENGE:
                        m_propFirmRules.dailyDrawdownLimit = FTMO_DAILY_DD_CHALLENGE;
                        m_propFirmRules.totalDrawdownLimit = FTMO_TOTAL_DD_CHALLENGE;
                        m_propFirmRules.maxTradingDays = 30;
                        m_propFirmRules.profitTarget = 10.0;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                        
                    case PHASE_VERIFICATION:
                        m_propFirmRules.dailyDrawdownLimit = FTMO_DAILY_DD_VERIFICATION;
                        m_propFirmRules.totalDrawdownLimit = FTMO_TOTAL_DD_VERIFICATION;
                        m_propFirmRules.maxTradingDays = 60;
                        m_propFirmRules.profitTarget = 5.0;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                        
                    case PHASE_FUNDED:
                        m_propFirmRules.dailyDrawdownLimit = FTMO_DAILY_DD_FUNDED;
                        m_propFirmRules.totalDrawdownLimit = FTMO_TOTAL_DD_FUNDED;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                }
                break;
                
            case PROP_FIRM_THE5ERS:
                m_propFirmRules.firmName = "The5ers";
                
                // Set rules based on phase
                switch(m_challengePhase) {
                    case PHASE_CHALLENGE:
                        m_propFirmRules.dailyDrawdownLimit = THE5ERS_DAILY_DD_CHALLENGE;
                        m_propFirmRules.totalDrawdownLimit = THE5ERS_TOTAL_DD_CHALLENGE;
                        m_propFirmRules.maxTradingDays = 0; // No time limit
                        m_propFirmRules.profitTarget = 6.0;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                        
                    case PHASE_VERIFICATION:
                        // The5ers doesn't have verification phase, treat as Challenge
                        m_propFirmRules.dailyDrawdownLimit = THE5ERS_DAILY_DD_CHALLENGE;
                        m_propFirmRules.totalDrawdownLimit = THE5ERS_TOTAL_DD_CHALLENGE;
                        m_propFirmRules.maxTradingDays = 0; // No time limit
                        m_propFirmRules.profitTarget = 6.0;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                        
                    case PHASE_FUNDED:
                        m_propFirmRules.dailyDrawdownLimit = THE5ERS_DAILY_DD_FUNDED;
                        m_propFirmRules.totalDrawdownLimit = THE5ERS_TOTAL_DD_FUNDED;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                }
                break;
                
            case PROP_FIRM_MFF:
                m_propFirmRules.firmName = "My Forex Funds";
                
                // Set rules based on phase
                switch(m_challengePhase) {
                    case PHASE_CHALLENGE:
                        m_propFirmRules.dailyDrawdownLimit = MFF_DAILY_DD_CHALLENGE;
                        m_propFirmRules.totalDrawdownLimit = MFF_TOTAL_DD_CHALLENGE;
                        m_propFirmRules.maxTradingDays = 30;
                        m_propFirmRules.profitTarget = 8.0;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                        
                    case PHASE_VERIFICATION:
                        m_propFirmRules.dailyDrawdownLimit = MFF_DAILY_DD_VERIFICATION;
                        m_propFirmRules.totalDrawdownLimit = MFF_TOTAL_DD_VERIFICATION;
                        m_propFirmRules.maxTradingDays = 60;
                        m_propFirmRules.profitTarget = 5.0;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                        
                    case PHASE_FUNDED:
                        m_propFirmRules.dailyDrawdownLimit = MFF_DAILY_DD_FUNDED;
                        m_propFirmRules.totalDrawdownLimit = MFF_TOTAL_DD_FUNDED;
                        m_propFirmRules.weekendHoldingAllowed = false;
                        m_propFirmRules.hasTrailingStopOut = true;
                        break;
                }
                break;
                
            case PROP_FIRM_TFT:
                m_propFirmRules.firmName = "The Funded Trader";
                
                // Set rules based on phase
                switch(m_challengePhase) {
                    case PHASE_CHALLENGE:
                        m_propFirmRules.dailyDrawdownLimit = TFT_DAILY_DD_CHALLENGE;
                        m_propFirmRules.totalDrawdownLimit = TFT_TOTAL_DD_CHALLENGE;
                        m_propFirmRules.maxTradingDays = 0; // No time limit
                        m_propFirmRules.profitTarget = 8.0;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                        
                    case PHASE_VERIFICATION:
                        m_propFirmRules.dailyDrawdownLimit = TFT_DAILY_DD_VERIFICATION;
                        m_propFirmRules.totalDrawdownLimit = TFT_TOTAL_DD_VERIFICATION;
                        m_propFirmRules.maxTradingDays = 0; // No time limit
                        m_propFirmRules.profitTarget = 5.0;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                        
                    case PHASE_FUNDED:
                        m_propFirmRules.dailyDrawdownLimit = TFT_DAILY_DD_FUNDED;
                        m_propFirmRules.totalDrawdownLimit = TFT_TOTAL_DD_FUNDED;
                        m_propFirmRules.weekendHoldingAllowed = true;
                        m_propFirmRules.hasTrailingStopOut = false;
                        break;
                }
                break;
                
            case PROP_FIRM_CUSTOM:
                // Custom settings already set by the user
                m_propFirmRules.firmName = "Custom";
                
                // Use the input values directly
                m_propFirmRules.dailyDrawdownLimit = m_maxDailyDrawdown;
                m_propFirmRules.totalDrawdownLimit = m_maxTotalDrawdown;
                break;
        }
        
        // Apply safety buffer to drawdown limits (except for custom)
        if (m_propFirmType != PROP_FIRM_CUSTOM) {
            // Apply 70%-80% of the actual limit for safety
            double safetyFactor = 0.8; // 80% of the limit
            
            // Challenge phase is more careful
            if (m_challengePhase == PHASE_CHALLENGE) {
                safetyFactor = 0.7; // 70% of the limit
            }
            
            // Apply safety factor
            m_maxDailyDrawdown = m_propFirmRules.dailyDrawdownLimit * safetyFactor;
            m_maxTotalDrawdown = m_propFirmRules.totalDrawdownLimit * safetyFactor;
        }
        
        // Log the configuration
        if (m_logger != NULL) {
            m_logger.Info("PropFirm configured: " + m_propFirmRules.firmName + 
                         " in " + EnumToString(m_challengePhase) + " phase");
            m_logger.Info("Daily DD limit: " + DoubleToString(m_propFirmRules.dailyDrawdownLimit, 1) + 
                         "%, using " + DoubleToString(m_maxDailyDrawdown, 1) + "% internally");
            m_logger.Info("Total DD limit: " + DoubleToString(m_propFirmRules.totalDrawdownLimit, 1) + 
                         "%, using " + DoubleToString(m_maxTotalDrawdown, 1) + "% internally");
        }
    }
    
    // Check if day changed
    bool IsDayChanged() {
        datetime currentTime = TimeCurrent();
        
        if (m_lastDayChecked == 0) {
            m_lastDayChecked = currentTime;
            return false;
        }
        
        // Extract date components
        MqlDateTime lastDate, currentDate;
        TimeToStruct(m_lastDayChecked, lastDate);
        TimeToStruct(currentTime, currentDate);
        
        // Check if day changed
        if (lastDate.day != currentDate.day || 
            lastDate.mon != currentDate.mon || 
            lastDate.year != currentDate.year) {
            m_lastDayChecked = currentTime;
            return true;
        }
        
        return false;
    }
    
    // Check if week changed - IMPROVED VERSION
    bool IsWeekChanged() {
        datetime currentTime = TimeCurrent();
        
        if (m_lastWeekChecked == 0) {
            m_lastWeekChecked = currentTime;
            return false;
        }
        
        // Extract date components
        MqlDateTime lastDate, currentDate;
        TimeToStruct(m_lastWeekChecked, lastDate);
        TimeToStruct(currentTime, currentDate);
        
        // Get day of week (1 = Monday, 7 = Sunday)
        int lastDOW = lastDate.day_of_week == 0 ? 7 : lastDate.day_of_week;
        int currentDOW = currentDate.day_of_week == 0 ? 7 : currentDate.day_of_week;
        
        // Calculate week number based on ISO week definition
        // Monday is the first day of the week
        bool isNewWeek = false;
        
        // New week starts on Monday
        if (currentDOW == 1 && lastDOW != 1) {
            isNewWeek = true;
        }
        // Or when month changes
        else if (lastDate.mon != currentDate.mon) {
            isNewWeek = true;
        }
        // Or when year changes
        else if (lastDate.year != currentDate.year) {
            isNewWeek = true;
        }
        
        if (isNewWeek) {
            m_lastWeekChecked = currentTime;
            return true;
        }
        
        return false;
    }
    
    // Check if month changed
    bool IsMonthChanged() {
        datetime currentTime = TimeCurrent();
        
        if (m_lastMonthChecked == 0) {
            m_lastMonthChecked = currentTime;
            return false;
        }
        
        // Extract date components
        MqlDateTime lastDate, currentDate;
        TimeToStruct(m_lastMonthChecked, lastDate);
        TimeToStruct(currentTime, currentDate);
        
        // Check if month changed
        if (lastDate.mon != currentDate.mon || 
            lastDate.year != currentDate.year) {
            m_lastMonthChecked = currentTime;
            return true;
        }
        
        return false;
    }
    
    // Calculate correlation between two symbols
    double GetCorrelation(string symbol1, string symbol2, int period = 100) {
        // Check if we already have calculated this correlation recently
        for (int i = 0; i < ArraySize(m_correlations); i++) {
            if ((m_correlations[i].symbol1 == symbol1 && m_correlations[i].symbol2 == symbol2) ||
                (m_correlations[i].symbol1 == symbol2 && m_correlations[i].symbol2 == symbol1)) {
                
                // Check if calculation is recent (last 1 hour)
                if (TimeCurrent() - m_correlations[i].calculationTime < 3600) {
                    return m_correlations[i].correlation;
                }
            }
        }
        
        // Get price data for both symbols
        double prices1[], prices2[];
        ArrayResize(prices1, period);
        ArrayResize(prices2, period);
        
        // Fill arrays with closing prices
        for (int i = 0; i < period; i++) {
            prices1[i] = iClose(symbol1, PERIOD_H1, i);
            prices2[i] = iClose(symbol2, PERIOD_H1, i);
            
            // Check for errors
            if (prices1[i] == 0 || prices2[i] == 0) {
                if (m_logger != NULL) {
                    m_logger.Warning("Failed to get prices for correlation calculation");
                }
                return 0;
            }
        }
        
        // Calculate means
        double mean1 = 0, mean2 = 0;
        for (int i = 0; i < period; i++) {
            mean1 += prices1[i];
            mean2 += prices2[i];
        }
        mean1 /= period;
        mean2 /= period;
        
        // Calculate correlation coefficient
        double sum_xy = 0, sum_x2 = 0, sum_y2 = 0;
        for (int i = 0; i < period; i++) {
            double x = prices1[i] - mean1;
            double y = prices2[i] - mean2;
            sum_xy += x * y;
            sum_x2 += x * x;
            sum_y2 += y * y;
        }
        
        // Avoid division by zero
        if (sum_x2 <= 0 || sum_y2 <= 0) return 0;
        
        // Calculate correlation coefficient
        double correlation = sum_xy / MathSqrt(sum_x2 * sum_y2);
        
        // Manage correlation cache size
        if (ArraySize(m_correlations) >= m_maxCorrelationCache) {
            // Find oldest correlation entry and replace it
            int oldestIndex = 0;
            datetime oldestTime = TimeCurrent();
            
            for (int i = 0; i < ArraySize(m_correlations); i++) {
                if (m_correlations[i].calculationTime < oldestTime) {
                    oldestTime = m_correlations[i].calculationTime;
                    oldestIndex = i;
                }
            }
            
            // Replace oldest entry
            m_correlations[oldestIndex].symbol1 = symbol1;
            m_correlations[oldestIndex].symbol2 = symbol2;
            m_correlations[oldestIndex].correlation = correlation;
            m_correlations[oldestIndex].period = period;
            m_correlations[oldestIndex].calculationTime = TimeCurrent();
        }
        else {
            // Add new entry
            int size = ArraySize(m_correlations);
            ArrayResize(m_correlations, size + 1);
            m_correlations[size].symbol1 = symbol1;
            m_correlations[size].symbol2 = symbol2;
            m_correlations[size].correlation = correlation;
            m_correlations[size].period = period;
            m_correlations[size].calculationTime = TimeCurrent();
        }
        
        return correlation;
    }
    
    // Adjust risk based on current situation
    double AdjustRiskBasedOnMarketConditions(double baseRisk) {
        double adjustedRisk = baseRisk;
        
        // 1. Adjust based on challenge phase
        switch (m_challengePhase) {
            case PHASE_CHALLENGE:
                adjustedRisk *= 0.8; // More cautious in challenge
                break;
                
            case PHASE_VERIFICATION:
                adjustedRisk *= 0.7; // Even more cautious in verification
                break;
                
            case PHASE_FUNDED:
                // Full risk in funded account
                break;
        }
        
        // 2. Adjust based on consecutive losses
        if (m_consecutiveLosses > 0) {
            double lossFactor = MathMax(0.5, 1.0 - m_consecutiveLosses * 0.1); // Reduce by 10% per loss, min 50%
            adjustedRisk *= lossFactor;
            
            if (m_logger != NULL) {
                m_logger.Info("Risk reduced to " + DoubleToString(lossFactor * 100, 0) + 
                             "% after " + IntegerToString(m_consecutiveLosses) + " consecutive losses");
            }
        }
        
        // 3. Adjust based on drawdown proximity
        if (m_totalDrawdown > 0) {
            double ddRatio = m_totalDrawdown / m_maxTotalDrawdown;
            if (ddRatio > 0.5) { // If using more than 50% of allowed drawdown
                double ddFactor = 1.0 - (ddRatio - 0.5); // Linear reduction starting at 50% of max DD
                ddFactor = MathMax(0.3, ddFactor); // Don't go below 30%
                adjustedRisk *= ddFactor;
                
                if (m_logger != NULL) {
                    m_logger.Info("Risk reduced to " + DoubleToString(ddFactor * 100, 0) + 
                                 "% due to drawdown at " + DoubleToString(m_totalDrawdown, 2) + "%");
                }
            }
        }
        
        // 4. Adjust based on portfolio risk
        double portfolioRiskRatio = m_portfolioRisk / m_portfolioMaxRisk;
        if (portfolioRiskRatio > 0.7) { // If using more than 70% of allowed portfolio risk
            double prFactor = 1.0 - (portfolioRiskRatio - 0.7) * 2.0; // Steeper reduction
            prFactor = MathMax(0.2, prFactor); // Don't go below 20%
            adjustedRisk *= prFactor;
            
            if (m_logger != NULL) {
                m_logger.Info("Risk reduced to " + DoubleToString(prFactor * 100, 0) + 
                             "% due to high portfolio risk");
            }
        }
        
        return adjustedRisk;
    }
    
    // Clean up old correlation data to prevent memory leaks
    void CleanCorrelationCache() {
        // If cache is smaller than max size, no cleaning needed
        if (ArraySize(m_correlations) < m_maxCorrelationCache) {
            return;
        }
        
        // Find entries older than 24 hours
        datetime currentTime = TimeCurrent();
        datetime oldThreshold = currentTime - 24*3600; // 24 hours ago
        
        // Count valid entries
        int validCount = 0;
        for (int i = 0; i < ArraySize(m_correlations); i++) {
            if (m_correlations[i].calculationTime >= oldThreshold) {
                validCount++;
            }
        }
        
        // If all entries are recent, no cleaning needed
        if (validCount == ArraySize(m_correlations)) {
            return;
        }
        
        // Create a new array with only recent entries
        CorrelationInfo tempArray[];
        ArrayResize(tempArray, validCount);
        
        int index = 0;
        for (int i = 0; i < ArraySize(m_correlations); i++) {
            if (m_correlations[i].calculationTime >= oldThreshold) {
                tempArray[index++] = m_correlations[i];
            }
        }
        
        // Replace old array with new one
        ArrayFree(m_correlations);
        ArrayResize(m_correlations, validCount);
        for (int i = 0; i < validCount; i++) {
            m_correlations[i] = tempArray[i];
        }
        
        if (m_logger != NULL) {
            m_logger.Debug("Cleaned correlation cache: removed " + 
                          IntegerToString(ArraySize(m_correlations) - validCount) + 
                          " old entries");
        }
    }
    
public:
    // Constructor
    CRiskManager() {
        // Initialize with default values
        m_riskPercent = DEFAULT_RISK_PERCENT;
        m_maxDailyDrawdown = DEFAULT_MAX_DAILY_DD;
        m_maxTotalDrawdown = DEFAULT_MAX_TOTAL_DD;
        m_maxDailyTrades = DEFAULT_MAX_DAILY_TRADES;
        m_maxConcurrentTrades = DEFAULT_MAX_CONCURRENT;
        m_portfolioMaxRisk = 5.0; // Default 5% portfolio risk
        m_maxCorrelationThreshold = 0.7; // Default correlation threshold
        
        // PropFirm settings
        m_propFirmType = PROP_FIRM_FTMO;
        m_challengePhase = PHASE_CHALLENGE;
        
        // Initialize state variables
        m_currentEquity = 0;
        m_startDayEquity = 0;
        m_startWeekEquity = 0;
        m_startMonthEquity = 0;
        m_highWaterMark = 0;
        m_dailyDrawdown = 0;
        m_totalDrawdown = 0;
        m_dailyTradesCount = 0;
        m_portfolioRisk = 0;
        m_consecutiveLosses = 0;
        
        // Initialize date tracking
        m_lastDayChecked = 0;
        m_lastWeekChecked = 0;
        m_lastMonthChecked = 0;
        m_lastUpdateTime = 0;
        
        // Set correlation cache limit
        m_maxCorrelationCache = 100;
        
        // Logger
        m_logger = NULL;
    }
    
    // Initialize
    bool Initialize() {
        // Get account equity
        m_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        // Set initial values
        if (m_startDayEquity == 0) m_startDayEquity = m_currentEquity;
        if (m_startWeekEquity == 0) m_startWeekEquity = m_currentEquity;
        if (m_startMonthEquity == 0) m_startMonthEquity = m_currentEquity;
        if (m_highWaterMark == 0) m_highWaterMark = m_currentEquity;
        
        // Configure PropFirm rules
        ConfigurePropFirmRules();
        
        // Set last update time
        m_lastUpdateTime = TimeCurrent();
        
        // Log initialization
        if (m_logger != NULL) {
            m_logger.Info("RiskManager initialized with " + 
                         DoubleToString(m_riskPercent, 2) + "% risk per trade");
            m_logger.Info("Max Daily DD: " + DoubleToString(m_maxDailyDrawdown, 2) + 
                         "%, Max Total DD: " + DoubleToString(m_maxTotalDrawdown, 2) + "%");
            m_logger.Info("Max Daily Trades: " + IntegerToString(m_maxDailyTrades) + 
                         ", Max Concurrent: " + IntegerToString(m_maxConcurrentTrades));
            m_logger.Info("Portfolio Max Risk: " + DoubleToString(m_portfolioMaxRisk, 2) + "%");
        }
        
        return true;
    }
    
    // Calculate position size based on risk parameters
    double CalculateLotSize(double entryPrice, double stopLoss) {
        // Validate inputs
        if (entryPrice <= 0 || stopLoss <= 0 || MathAbs(entryPrice - stopLoss) <= DBL_EPSILON) {
            if (m_logger != NULL) {
                m_logger.Error("Invalid price inputs for lot size calculation");
            }
            return 0;
        }
        
        // Get account equity
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        // Determine risk amount
        double baseRiskPercent = m_riskPercent;
        double adjustedRiskPercent = AdjustRiskBasedOnMarketConditions(baseRiskPercent);
        double riskAmount = equity * (adjustedRiskPercent / 100.0);
        
        // Calculate price difference in points
        double priceDiff = MathAbs(entryPrice - stopLoss);
        double points = priceDiff / _Point;
        
        // Get tick value in account currency
        double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
        
        // Calculate lot size
        double lotSize = 0;
        if (points > 0 && tickValue > 0) {
            lotSize = riskAmount / (points * tickValue / SymbolInfoDouble(_Symbol, SYMBOL_POINT));
        }
        
        // Apply lot size constraints
        double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
        double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
        
        // Round to nearest valid lot size
        lotSize = MathFloor(lotSize / lotStep) * lotStep;
        
        // Apply min/max constraints
        lotSize = MathMax(minLot, MathMin(maxLot, lotSize));
        
        // Log calculation
        if (m_logger != NULL) {
            m_logger.Info("Lot size calculation: " + DoubleToString(lotSize, 2) + 
                         " lots based on " + DoubleToString(adjustedRiskPercent, 2) + 
                         "% risk, " + DoubleToString(points, 1) + " points SL distance");
        }
        
        return lotSize;
    }
    
    // Update risk metrics - ENHANCED FOR MORE FREQUENT CALLS
    void UpdateMetrics() {
        // Get current time
        datetime currentTime = TimeCurrent();
        
        // Skip if update is too frequent (limit to once per second)
        if (currentTime - m_lastUpdateTime < 1) {
            return;
        }
        
        // Update last update time
        m_lastUpdateTime = currentTime;
        
        // Get current equity
        m_currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        
        // Update high water mark if needed
        if (m_currentEquity > m_highWaterMark) {
            m_highWaterMark = m_currentEquity;
        }
        
        // Calculate drawdowns
        if (m_startDayEquity > 0) {
            m_dailyDrawdown = ((m_startDayEquity - m_currentEquity) / m_startDayEquity) * 100.0;
        }
        
        if (m_highWaterMark > 0) {
            m_totalDrawdown = ((m_highWaterMark - m_currentEquity) / m_highWaterMark) * 100.0;
        }
        
        // Check for date changes
        if (IsDayChanged()) {
            // Reset daily metrics
            ResetDailyMetrics();
        }
        
        if (IsWeekChanged()) {
            // Reset weekly metrics
            m_startWeekEquity = m_currentEquity;
            
            if (m_logger != NULL) {
                m_logger.Info("Weekly metrics reset. New start equity: " + 
                             DoubleToString(m_startWeekEquity, 2));
            }
        }
        
        if (IsMonthChanged()) {
            // Reset monthly metrics
            m_startMonthEquity = m_currentEquity;
            
            if (m_logger != NULL) {
                m_logger.Info("Monthly metrics reset. New start equity: " + 
                             DoubleToString(m_startMonthEquity, 2));
            }
        }
        
        // Check for emergency conditions
        CheckEmergencyConditions();
        
        // Clean correlation cache periodically (once per hour)
        static datetime lastCacheCleanTime = 0;
        if (currentTime - lastCacheCleanTime > 3600) {
            CleanCorrelationCache();
            lastCacheCleanTime = currentTime;
        }
    }
    
    // Check for emergency conditions
    void CheckEmergencyConditions() {
        bool emergencyDetected = false;
        
        // Check daily drawdown approaching limit
        if (m_dailyDrawdown > m_maxDailyDrawdown * 0.85) {
            emergencyDetected = true;
            if (m_logger != NULL) {
                m_logger.Warning("EMERGENCY ALERT: Daily drawdown (" + 
                               DoubleToString(m_dailyDrawdown, 2) + 
                               "%) approaching limit (" + 
                               DoubleToString(m_maxDailyDrawdown, 2) + "%)");
            }
        }
        
        // Check total drawdown approaching limit
        if (m_totalDrawdown > m_maxTotalDrawdown * 0.85) {
            emergencyDetected = true;
            if (m_logger != NULL) {
                m_logger.Warning("EMERGENCY ALERT: Total drawdown (" + 
                               DoubleToString(m_totalDrawdown, 2) + 
                               "%) approaching limit (" + 
                               DoubleToString(m_maxTotalDrawdown, 2) + "%)");
            }
        }
        
        if (emergencyDetected) {
            // Notify CSonicREAManager to activate Emergency Mode
            extern CSonicREAManager* g_manager; // External reference to main manager
            if (g_manager != NULL) {
                g_manager.ActivateEmergencyMode();
            }
        }
    }
    
    // Check if new day started - for external calls
    bool ShouldResetDailyMetrics() {
        return IsDayChanged();
    }
    
    // Reset daily metrics
    void ResetDailyMetrics() {
        // Reset daily equity
        m_startDayEquity = m_currentEquity;
        m_dailyDrawdown = 0;
        m_dailyTradesCount = 0;
        
        // Log reset
        if (m_logger != NULL) {
            m_logger.Info("Daily metrics reset. New start equity: " + 
                         DoubleToString(m_startDayEquity, 2));
        }
    }
    
    // Check if max daily drawdown is exceeded
    bool IsDailyDrawdownExceeded() {
        // Ensure metrics are current
        UpdateMetrics();
        
        return m_dailyDrawdown >= m_maxDailyDrawdown;
    }
    
    // Check if max total drawdown is exceeded
    bool IsTotalDrawdownExceeded() {
        // Ensure metrics are current
        UpdateMetrics();
        
        return m_totalDrawdown >= m_maxTotalDrawdown;
    }
    
    // Check if max daily trades is exceeded
    bool IsDailyTradesLimitExceeded() {
        return m_maxDailyTrades > 0 && m_dailyTradesCount >= m_maxDailyTrades;
    }
    
    // Check correlation with existing positions
    bool CheckCorrelationWithOpenTrades(string currentSymbol, const TradeRecord &trades[]) {
        for (int i = 0; i < ArraySize(trades); i++) {
            // Skip invalid or closed trades
            if (!trades[i].isValid) continue;
            
            // Skip if same symbol
            if (trades[i].symbol == currentSymbol) continue;
            
            // Calculate correlation
            double correlation = MathAbs(GetCorrelation(currentSymbol, trades[i].symbol));
            
            // Check if correlation exceeds threshold
            if (correlation > m_maxCorrelationThreshold) {
                // Log high correlation
                if (m_logger != NULL) {
                    m_logger.Warning("High correlation (" + DoubleToString(correlation, 2) + 
                                    ") between " + currentSymbol + " and " + trades[i].symbol);
                }
                return false;
            }
        }
        
        // No high correlations found
        return true;
    }
    
    // Check if we can open a new trade based on all risk constraints
    bool CanOpenNewTrade() {
        // Ensure metrics are current
        UpdateMetrics();
        
        // 1. Check drawdown limits
        if (IsDailyDrawdownExceeded()) {
            if (m_logger != NULL) {
                m_logger.Warning("Daily drawdown limit exceeded: " + 
                               DoubleToString(m_dailyDrawdown, 2) + "% > " + 
                               DoubleToString(m_maxDailyDrawdown, 2) + "%");
            }
            return false;
        }
        
        if (IsTotalDrawdownExceeded()) {
            if (m_logger != NULL) {
                m_logger.Warning("Total drawdown limit exceeded: " + 
                               DoubleToString(m_totalDrawdown, 2) + "% > " + 
                               DoubleToString(m_maxTotalDrawdown, 2) + "%");
            }
            return false;
        }
        
        // 2. Check trade count limits
        if (IsDailyTradesLimitExceeded()) {
            if (m_logger != NULL) {
                m_logger.Warning("Daily trades limit exceeded: " + 
                               IntegerToString(m_dailyTradesCount) + " >= " + 
                               IntegerToString(m_maxDailyTrades));
            }
            return false;
        }
        
        // 3. Check concurrent positions limit
        int openPositions = PositionsTotal();
        if (m_maxConcurrentTrades > 0 && openPositions >= m_maxConcurrentTrades) {
            if (m_logger != NULL) {
                m_logger.Warning("Concurrent positions limit exceeded: " + 
                               IntegerToString(openPositions) + " >= " + 
                               IntegerToString(m_maxConcurrentTrades));
            }
            return false;
        }
        
        // 4. Check portfolio risk
        if (m_portfolioRisk >= m_portfolioMaxRisk) {
            if (m_logger != NULL) {
                m_logger.Warning("Portfolio risk limit exceeded: " + 
                               DoubleToString(m_portfolioRisk, 2) + "% >= " + 
                               DoubleToString(m_portfolioMaxRisk, 2) + "%");
            }
            return false;
        }
        
        // All checks passed
        return true;
    }
    
    // Track new trade for risk management
    void TrackNewTrade() {
        m_dailyTradesCount++;
        
        if (m_logger != NULL) {
            m_logger.Info("New trade added to daily count: " + 
                         IntegerToString(m_dailyTradesCount) + "/" + 
                         IntegerToString(m_maxDailyTrades));
        }
    }
    
    // Update portfolio risk - NEW METHOD
    void UpdatePortfolioRisk(double riskChange) {
        // Update portfolio risk
        m_portfolioRisk += riskChange;
        
        // Ensure it doesn't go below zero
        if (m_portfolioRisk < 0) {
            m_portfolioRisk = 0;
        }
        
        if (m_logger != NULL) {
            m_logger.Info("Portfolio risk updated: " + DoubleToString(m_portfolioRisk, 2) + 
                        "% (" + (riskChange >= 0 ? "+" : "") + DoubleToString(riskChange, 2) + "%)");
        }
        
        // Check if approaching limit
        if (m_portfolioRisk >= m_portfolioMaxRisk * 0.8) {
            if (m_logger != NULL) {
                m_logger.Warning("Portfolio risk approaching limit: " + 
                              DoubleToString(m_portfolioRisk, 2) + "% of " + 
                              DoubleToString(m_portfolioMaxRisk, 2) + "%");
            }
        }
    }
    
    // Reset portfolio risk - for testing or emergency reset
    void ResetPortfolioRisk() {
        double oldRisk = m_portfolioRisk;
        m_portfolioRisk = 0;
        
        if (m_logger != NULL) {
            m_logger.Warning("Portfolio risk reset from " + DoubleToString(oldRisk, 2) + "% to 0%");
        }
    }
    
    // Track trade result
    void TrackTradeResult(bool isWin) {
        if (isWin) {
            // Reset consecutive losses on win
            m_consecutiveLosses = 0;
        }
        else {
            // Increment consecutive losses
            m_consecutiveLosses++;
            
            if (m_logger != NULL && m_consecutiveLosses > 1) {
                m_logger.Warning("Consecutive losses: " + IntegerToString(m_consecutiveLosses));
            }
        }
    }
    
    // Check if emergency mode can be reset
    bool CanResetEmergencyMode() {
        // Ensure metrics are current
        UpdateMetrics();
        
        // If drawdown has reduced significantly
        if (m_totalDrawdown < m_maxTotalDrawdown * 0.5 &&
            m_dailyDrawdown < m_maxDailyDrawdown * 0.5) {
            return true;
        }
        
        return false;
    }
    
    //--- Setters
    
    // Set risk percent per trade
    void SetRiskPercent(double risk) {
        m_riskPercent = MathMax(0.1, MathMin(10.0, risk));
    }
    
    // Set max daily drawdown
    void SetMaxDailyDrawdown(double dd) {
        m_maxDailyDrawdown = MathMax(0.5, dd);
    }
    
    // Set max total drawdown
    void SetMaxTotalDrawdown(double dd) {
        m_maxTotalDrawdown = MathMax(1.0, dd);
    }
    
    // Set max daily trades
    void SetMaxDailyTrades(int trades) {
        m_maxDailyTrades = MathMax(0, trades);
    }
    
    // Set max concurrent trades
    void SetMaxConcurrentTrades(int trades) {
        m_maxConcurrentTrades = MathMax(0, trades);
    }
    
    // Set portfolio max risk
    void SetPortfolioMaxRisk(double risk) {
        m_portfolioMaxRisk = MathMax(1.0, risk);
    }
    
    // Set max correlation threshold
    void SetMaxCorrelationThreshold(double threshold) {
        m_maxCorrelationThreshold = MathMax(0.1, MathMin(0.9, threshold));
    }
    
    // Set PropFirm settings
    void SetPropFirmSettings(ENUM_PROP_FIRM_TYPE type, ENUM_CHALLENGE_PHASE phase) {
        m_propFirmType = type;
        m_challengePhase = phase;
        
        // Reconfigure rules
        ConfigurePropFirmRules();
    }
    
    // Set correlation cache size
    void SetCorrelationCacheSize(int size) {
        m_maxCorrelationCache = MathMax(10, size);
    }
    
    // Set logger reference
    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }
    
    // Set consecutive losses (for testing)
    void SetConsecutiveLosses(int losses) {
        m_consecutiveLosses = MathMax(0, losses);
    }
    
    //--- Getters
    
    // Get current drawdown percentage
    double GetCurrentDrawdown() const {
        return m_totalDrawdown;
    }
    
    // Get daily drawdown percentage
    double GetDailyDrawdown() const {
        return m_dailyDrawdown;
    }
    
    // Get current profit/loss
    double GetCurrentProfit() const {
        return m_currentEquity - m_startDayEquity;
    }
    
    // Get daily trades count
    int GetDailyTradesCount() const {
        return m_dailyTradesCount;
    }
    
    // Get current portfolio risk
    double GetPortfolioRisk() const {
        return m_portfolioRisk;
    }
    
    // Get consecutive losses
    int GetConsecutiveLosses() const {
        return m_consecutiveLosses;
    }
    
    // Get PropFirm rules
    PropFirmRules GetPropFirmRules() const {
        return m_propFirmRules;
    }
    
    // Get risk metrics
    RiskMetrics GetRiskMetrics() const {
        RiskMetrics metrics;
        
        metrics.currentEquity = m_currentEquity;
        metrics.startDayEquity = m_startDayEquity;
        metrics.startWeekEquity = m_startWeekEquity;
        metrics.startMonthEquity = m_startMonthEquity;
        metrics.highWaterMark = m_highWaterMark;
        metrics.dailyDrawdown = m_dailyDrawdown;
        metrics.totalDrawdown = m_totalDrawdown;
        metrics.dailyDrawdownLimit = m_maxDailyDrawdown;
        metrics.totalDrawdownLimit = m_maxTotalDrawdown;
        metrics.dailyTradesCount = m_dailyTradesCount;
        metrics.dailyTradesLimit = m_maxDailyTrades;
        metrics.openTradesCount = PositionsTotal();
        metrics.concurrentTradesLimit = m_maxConcurrentTrades;
        metrics.portfolioRisk = m_portfolioRisk;
        metrics.portfolioRiskLimit = m_portfolioMaxRisk;
        
        return metrics;
    }
};