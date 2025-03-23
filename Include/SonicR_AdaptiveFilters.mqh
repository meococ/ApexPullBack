//+------------------------------------------------------------------+
//|                                      SonicR_AdaptiveFilters.mqh |
//|                SonicR PropFirm EA - Adaptive Filters Component  |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"
#include "SonicR_Core.mqh"

//+------------------------------------------------------------------+
//| Enhanced Adaptive Filters for dynamic market adaptation          |
//+------------------------------------------------------------------+
class CAdaptiveFilters
{
private:
    // Logger
    CLogger* m_logger;
    
    // Market regimes - defined values for easier reference
    enum ENUM_MARKET_REGIME
    {
        REGIME_STRONG_TREND,    // Strong trending market
        REGIME_MODERATE_TREND,  // Moderate trending market
        REGIME_WEAK_TREND,      // Weak trending market
        REGIME_RANGE_TIGHT,     // Tight range-bound market
        REGIME_RANGE_WIDE,      // Wide range-bound market
        REGIME_VOLATILE,        // Volatile/choppy market
        REGIME_UNDEFINED        // Undefined/initial state
    };
    
    // Current market state
    ENUM_MARKET_REGIME m_currentRegime;
    int m_trendDirection;    // 1 = up, -1 = down, 0 = sideways
    double m_volatilityRatio; // Current volatility ratio
    double m_trendStrength;   // Current trend strength
    
    // Adaptive parameters
    struct AdaptiveParams {
        double adxThreshold;      // ADX threshold
        double volatilityMin;     // Minimum volatility
        double volatilityMax;     // Maximum volatility
        double minRR;             // Minimum risk-reward ratio
        int maxTradesPerDay;      // Maximum trades per day
        double baseRiskPercent;   // Risk percent per trade
        bool useScoutEntries;     // Use scout entries
    };
    
    // Parameter sets for different regimes
    AdaptiveParams m_paramsStrongTrend;
    AdaptiveParams m_paramsModTrend;
    AdaptiveParams m_paramsWeakTrend;
    AdaptiveParams m_paramsRangeTight;
    AdaptiveParams m_paramsRangeWide;
    AdaptiveParams m_paramsVolatile;
    
    // Current parameters
    AdaptiveParams m_currentParams;
    
    // Challenge progress adaptation
    int m_remainingDays;
    double m_challengeProgress;  // 0-100%
    double m_emergencyThreshold; // Emergency threshold (default 30%)
    double m_conservativeThreshold; // Conservative threshold (default 80%)
    
    // Symbol-specific parameters
    struct SymbolParams {
        string symbol;
        double adxMultiplier;    // Multiplier for ADX threshold
        double volMultiplier;    // Multiplier for volatility
        double riskMultiplier;   // Multiplier for risk
    };
    
    SymbolParams m_symbolParams[];
    
    // Helper methods
    void InitializeDefaultParams();
    void DetectMarketRegime(CSonicRCore* core);
    void AdjustParamsForRegime();
    void AdjustParamsForSymbol(string symbol);
    void AdjustParamsForProgress();
    double GetSymbolMultiplier(string symbol, string paramType);
    
public:
    // Constructor
    CAdaptiveFilters();
    
    // Destructor
    ~CAdaptiveFilters();
    
    // Main methods
    void Update(CSonicRCore* core);
    void AdjustForChallengeProgress(int daysRemaining, int totalDays);
    void UpdateBasedOnResults(bool isWin, string symbol);
    
    // Get adapted parameters for filters
    double GetADXThreshold(string symbol);
    bool CheckVolatility(double volatilityRatio, string symbol);
    int GetMaxTradesForRegime();
    double GetBaseRiskPercent(string symbol);
    double GetMinRR();
    bool ShouldUseScoutEntries();
    
    // Market regime info
    string GetCurrentRegimeAsString() const;
    double GetTrendStrength() const { return m_trendStrength; }
    double GetVolatilityRatio() const { return m_volatilityRatio; }
    int GetTrendDirection() const { return m_trendDirection; }
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Utility
    string GetStatusText() const;
    
    // Set thresholds for progress adaptation
    void SetProgressThresholds(double emergencyThreshold, double conservativeThreshold) {
        m_emergencyThreshold = emergencyThreshold;
        m_conservativeThreshold = conservativeThreshold;
    }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAdaptiveFilters::CAdaptiveFilters()
{
    m_logger = NULL;
    
    // Initialize default state
    m_currentRegime = REGIME_UNDEFINED;
    m_trendDirection = 0;
    m_volatilityRatio = 1.0;
    m_trendStrength = 0.0;
    
    // Initialize default parameters
    InitializeDefaultParams();
    
    // Initialize symbol parameters
    ArrayResize(m_symbolParams, 10);
    
    // Major Forex pairs
    m_symbolParams[0].symbol = "EURUSD";
    m_symbolParams[0].adxMultiplier = 1.0;
    m_symbolParams[0].volMultiplier = 1.0;
    m_symbolParams[0].riskMultiplier = 1.0;
    
    m_symbolParams[1].symbol = "GBPUSD";
    m_symbolParams[1].adxMultiplier = 1.0;
    m_symbolParams[1].volMultiplier = 1.1;
    m_symbolParams[1].riskMultiplier = 0.9;
    
    m_symbolParams[2].symbol = "USDJPY";
    m_symbolParams[2].adxMultiplier = 1.1;
    m_symbolParams[2].volMultiplier = 1.0;
    m_symbolParams[2].riskMultiplier = 0.9;
    
    m_symbolParams[3].symbol = "AUDUSD";
    m_symbolParams[3].adxMultiplier = 1.0;
    m_symbolParams[3].volMultiplier = 1.2;
    m_symbolParams[3].riskMultiplier = 0.9;
    
    m_symbolParams[4].symbol = "USDCAD";
    m_symbolParams[4].adxMultiplier = 1.1;
    m_symbolParams[4].volMultiplier = 1.0;
    m_symbolParams[4].riskMultiplier = 0.9;
    
    // Cross pairs
    m_symbolParams[5].symbol = "EURJPY";
    m_symbolParams[5].adxMultiplier = 1.2;
    m_symbolParams[5].volMultiplier = 1.2;
    m_symbolParams[5].riskMultiplier = 0.8;
    
    m_symbolParams[6].symbol = "GBPJPY";
    m_symbolParams[6].adxMultiplier = 1.3;
    m_symbolParams[6].volMultiplier = 1.3;
    m_symbolParams[6].riskMultiplier = 0.7;
    
    // Metals
    m_symbolParams[7].symbol = "XAUUSD";
    m_symbolParams[7].adxMultiplier = 1.2;
    m_symbolParams[7].volMultiplier = 1.3;
    m_symbolParams[7].riskMultiplier = 0.7;
    
    // Indices
    m_symbolParams[8].symbol = "US30";
    m_symbolParams[8].adxMultiplier = 1.1;
    m_symbolParams[8].volMultiplier = 1.2;
    m_symbolParams[8].riskMultiplier = 0.8;
    
    // Default for all others
    m_symbolParams[9].symbol = "DEFAULT";
    m_symbolParams[9].adxMultiplier = 1.0;
    m_symbolParams[9].volMultiplier = 1.0;
    m_symbolParams[9].riskMultiplier = 0.8;
    
    // Challenge progress
    m_remainingDays = 30;
    m_challengeProgress = 0.0;
    m_emergencyThreshold = 30.0; // Default 30%
    m_conservativeThreshold = 80.0; // Default 80%
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAdaptiveFilters::~CAdaptiveFilters()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Initialize default parameters for different market regimes        |
//+------------------------------------------------------------------+
void CAdaptiveFilters::InitializeDefaultParams()
{
    // Strong trend
    m_paramsStrongTrend.adxThreshold = 25.0;
    m_paramsStrongTrend.volatilityMin = 0.8;
    m_paramsStrongTrend.volatilityMax = 1.5;
    m_paramsStrongTrend.minRR = 1.2;
    m_paramsStrongTrend.maxTradesPerDay = 5;
    m_paramsStrongTrend.baseRiskPercent = 0.7;
    m_paramsStrongTrend.useScoutEntries = true;
    
    // Moderate trend
    m_paramsModTrend.adxThreshold = 20.0;
    m_paramsModTrend.volatilityMin = 0.7;
    m_paramsModTrend.volatilityMax = 1.4;
    m_paramsModTrend.minRR = 1.5;
    m_paramsModTrend.maxTradesPerDay = 4;
    m_paramsModTrend.baseRiskPercent = 0.6;
    m_paramsModTrend.useScoutEntries = true;
    
    // Weak trend
    m_paramsWeakTrend.adxThreshold = 15.0;
    m_paramsWeakTrend.volatilityMin = 0.7;
    m_paramsWeakTrend.volatilityMax = 1.3;
    m_paramsWeakTrend.minRR = 1.8;
    m_paramsWeakTrend.maxTradesPerDay = 3;
    m_paramsWeakTrend.baseRiskPercent = 0.5;
    m_paramsWeakTrend.useScoutEntries = false;
    
    // Tight range
    m_paramsRangeTight.adxThreshold = 15.0;
    m_paramsRangeTight.volatilityMin = 0.6;
    m_paramsRangeTight.volatilityMax = 1.2;
    m_paramsRangeTight.minRR = 2.0;
    m_paramsRangeTight.maxTradesPerDay = 2;
    m_paramsRangeTight.baseRiskPercent = 0.4;
    m_paramsRangeTight.useScoutEntries = false;
    
    // Wide range
    m_paramsRangeWide.adxThreshold = 12.0;
    m_paramsRangeWide.volatilityMin = 0.8;
    m_paramsRangeWide.volatilityMax = 1.4;
    m_paramsRangeWide.minRR = 1.8;
    m_paramsRangeWide.maxTradesPerDay = 3;
    m_paramsRangeWide.baseRiskPercent = 0.5;
    m_paramsRangeWide.useScoutEntries = false;
    
    // Volatile market
    m_paramsVolatile.adxThreshold = 20.0;
    m_paramsVolatile.volatilityMin = 1.2;
    m_paramsVolatile.volatilityMax = 2.0;
    m_paramsVolatile.minRR = 2.5;
    m_paramsVolatile.maxTradesPerDay = 1;
    m_paramsVolatile.baseRiskPercent = 0.3;
    m_paramsVolatile.useScoutEntries = false;
    
    // Set current parameters to default moderate trend
    m_currentParams = m_paramsModTrend;
}

//+------------------------------------------------------------------+
//| Update and detect market regime                                  |
//+------------------------------------------------------------------+
void CAdaptiveFilters::Update(CSonicRCore* core)
{
    // Detect market regime
    DetectMarketRegime(core);
    
    // Adjust parameters based on regime
    AdjustParamsForRegime();
    
    // Adjust parameters for specific symbol
    AdjustParamsForSymbol(_Symbol);
    
    // Adjust parameters based on challenge progress
    AdjustParamsForProgress();
    
    // Log current regime
    if(m_logger) {
        static ENUM_MARKET_REGIME lastLoggedRegime = REGIME_UNDEFINED;
        
        if(m_currentRegime != lastLoggedRegime) {
            m_logger.Info("Market regime changed to: " + GetCurrentRegimeAsString());
            lastLoggedRegime = m_currentRegime;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect market regime based on indicators                         |
//+------------------------------------------------------------------+
void CAdaptiveFilters::DetectMarketRegime(CSonicRCore* core)
{
    if(!core) return;
    
    // Store previous regime for comparison
    ENUM_MARKET_REGIME prevRegime = m_currentRegime;
    
    // Get trend direction from core
    m_trendDirection = 0;
    
    int d1Trend = core.GetDailyTrend();
    int h4Trend = core.GetH4Trend();
    int h1Trend = core.GetH1Trend();
    
    // Determine overall trend direction (weighted)
    double trendDirection = d1Trend * 0.5 + h4Trend * 0.3 + h1Trend * 0.2;
    
    if(trendDirection > 0.3) m_trendDirection = 1;  // Bullish
    else if(trendDirection < -0.3) m_trendDirection = -1;  // Bearish
    
    // Get ADX for trend strength
    int adxHandle = iADX(_Symbol, PERIOD_H4, 14);
    if(adxHandle != INVALID_HANDLE) {
        double adxBuffer[];
        ArraySetAsSeries(adxBuffer, true);
        
        if(CopyBuffer(adxHandle, 0, 0, 1, adxBuffer) > 0) {
            m_trendStrength = adxBuffer[0];
        }
        
        IndicatorRelease(adxHandle);
    }
    
    // Get volatility ratio
    int atrHandle = iATR(_Symbol, PERIOD_H4, 14);
    if(atrHandle != INVALID_HANDLE) {
        double atrBuffer[];
        double atrHistory[];
        ArraySetAsSeries(atrBuffer, true);
        ArraySetAsSeries(atrHistory, true);
        
        if(CopyBuffer(atrHandle, 0, 0, 1, atrBuffer) > 0 &&
           CopyBuffer(atrHandle, 0, 1, 20, atrHistory) > 0) {
            double avgATR = 0;
            for(int i = 0; i < 20; i++) {
                avgATR += atrHistory[i];
            }
            avgATR /= 20;
            
            m_volatilityRatio = atrBuffer[0] / avgATR;
        }
        
        IndicatorRelease(atrHandle);
    }
    
    // Determine regime based on trend strength and volatility
    if(m_trendStrength >= 30) {
        // Strong trend
        m_currentRegime = REGIME_STRONG_TREND;
    }
    else if(m_trendStrength >= 20) {
        // Moderate trend
        m_currentRegime = REGIME_MODERATE_TREND;
    }
    else if(m_trendStrength >= 15) {
        // Weak trend
        m_currentRegime = REGIME_WEAK_TREND;
    }
    else {
        // Range or volatile
        if(m_volatilityRatio > 1.4) {
            // Volatile market
            m_currentRegime = REGIME_VOLATILE;
        }
        else if(m_volatilityRatio > 1.2) {
            // Wide range
            m_currentRegime = REGIME_RANGE_WIDE;
        }
        else {
            // Tight range
            m_currentRegime = REGIME_RANGE_TIGHT;
        }
    }
    
    // Log regime change if needed
    if(prevRegime != m_currentRegime && m_logger) {
        m_logger.Info("Market regime changed from " + 
                     EnumToString(prevRegime) + " to " + 
                     EnumToString(m_currentRegime) + 
                     " (ADX: " + DoubleToString(m_trendStrength, 1) + 
                     ", Vol: " + DoubleToString(m_volatilityRatio, 2) + ")");
    }
}

//+------------------------------------------------------------------+
//| Adjust parameters based on detected regime                       |
//+------------------------------------------------------------------+
void CAdaptiveFilters::AdjustParamsForRegime()
{
    // Set parameters based on current regime
    switch(m_currentRegime) {
        case REGIME_STRONG_TREND:
            m_currentParams = m_paramsStrongTrend;
            break;
            
        case REGIME_MODERATE_TREND:
            m_currentParams = m_paramsModTrend;
            break;
            
        case REGIME_WEAK_TREND:
            m_currentParams = m_paramsWeakTrend;
            break;
            
        case REGIME_RANGE_TIGHT:
            m_currentParams = m_paramsRangeTight;
            break;
            
        case REGIME_RANGE_WIDE:
            m_currentParams = m_paramsRangeWide;
            break;
            
        case REGIME_VOLATILE:
            m_currentParams = m_paramsVolatile;
            break;
            
        default:
            // Use moderate trend as default
            m_currentParams = m_paramsModTrend;
            break;
    }
}

//+------------------------------------------------------------------+
//| Adjust parameters for specific symbol                            |
//+------------------------------------------------------------------+
void CAdaptiveFilters::AdjustParamsForSymbol(string symbol)
{
    // Get multipliers for this symbol
    double adxMult = GetSymbolMultiplier(symbol, "adx");
    double volMult = GetSymbolMultiplier(symbol, "vol");
    double riskMult = GetSymbolMultiplier(symbol, "risk");
    
    // Apply multipliers
    m_currentParams.adxThreshold *= adxMult;
    m_currentParams.volatilityMin *= volMult;
    m_currentParams.volatilityMax *= volMult;
    m_currentParams.baseRiskPercent *= riskMult;
}

//+------------------------------------------------------------------+
//| Adjust parameters based on challenge progress                    |
//+------------------------------------------------------------------+
void CAdaptiveFilters::AdjustParamsForProgress()
{
    // No need to adjust if progress is low or unknown
    if(m_challengeProgress <= 0.0) return;
    
    // If close to completing challenge (>conservativeThreshold), be more conservative
    if(m_challengeProgress > m_conservativeThreshold) {
        m_currentParams.baseRiskPercent *= 0.8;  // Reduce risk
        m_currentParams.maxTradesPerDay = MathMax(1, m_currentParams.maxTradesPerDay - 1);  // Reduce max trades
        m_currentParams.minRR *= 1.2;  // Increase required R:R
        
        if(m_logger) {
            m_logger.Info("Progress at " + DoubleToString(m_challengeProgress, 1) + 
                         "% - Adjusting to conservative parameters");
        }
    }
    // If close to deadline but not progressing fast enough, be slightly more aggressive
    else if(m_challengeProgress < 50.0 && m_remainingDays < 10) {
        m_currentParams.baseRiskPercent *= 1.1;  // Increase risk slightly
        m_currentParams.maxTradesPerDay += 1;  // Allow one more trade
        m_currentParams.adxThreshold *= 0.9;  // Lower ADX threshold slightly
    }
    
    // Additional emergency adjustments if challenge is at risk
    if(m_challengeProgress < m_emergencyThreshold && m_remainingDays < 5) {
        // Emergency mode - significantly more aggressive
        m_currentParams.baseRiskPercent *= 1.2;
        m_currentParams.maxTradesPerDay += 2;
        m_currentParams.adxThreshold *= 0.8;
        m_currentParams.minRR *= 0.8;
        
        if(m_logger) {
            m_logger.Warning("Emergency challenge mode activated - parameters adjusted for aggressive trading");
        }
    }
}

//+------------------------------------------------------------------+
//| Get multiplier for symbol parameter                              |
//+------------------------------------------------------------------+
double CAdaptiveFilters::GetSymbolMultiplier(string symbol, string paramType)
{
    // Find the symbol in the array
    for(int i = 0; i < ArraySize(m_symbolParams); i++) {
        if(m_symbolParams[i].symbol == symbol) {
            if(paramType == "adx") return m_symbolParams[i].adxMultiplier;
            if(paramType == "vol") return m_symbolParams[i].volMultiplier;
            if(paramType == "risk") return m_symbolParams[i].riskMultiplier;
            break;
        }
    }
    
    // Return default multiplier if symbol not found
    return 1.0;
}

//+------------------------------------------------------------------+
//| Update adaptive parameters for challenge progress                |
//+------------------------------------------------------------------+
void CAdaptiveFilters::AdjustForChallengeProgress(int daysRemaining, int totalDays)
{
    m_remainingDays = daysRemaining;
    
    // Calculate progress percentage
    if(totalDays > 0) {
        m_challengeProgress = 100.0 * (totalDays - daysRemaining) / totalDays;
    } else {
        m_challengeProgress = 0.0;
    }
    
    if(m_logger) {
        m_logger.Info("Challenge progress: " + DoubleToString(m_challengeProgress, 1) + 
                     "%, Days remaining: " + IntegerToString(m_remainingDays));
    }
}

//+------------------------------------------------------------------+
//| Update adaptive parameters based on trade results                |
//+------------------------------------------------------------------+
void CAdaptiveFilters::UpdateBasedOnResults(bool isWin, string symbol)
{
    // Static variables to track consecutive wins/losses by symbol
    static int consecutiveWins = 0;
    static int consecutiveLosses = 0;
    
    // Update consecutive counters
    if(isWin) {
        consecutiveWins++;
        consecutiveLosses = 0;
    } else {
        consecutiveLosses++;
        consecutiveWins = 0;
    }
    
    // Adjust parameters based on results
    if(consecutiveLosses >= 3) {
        // Multiple consecutive losses - become more conservative
        m_currentParams.baseRiskPercent *= 0.7;  // Reduce risk
        m_currentParams.maxTradesPerDay = MathMax(1, m_currentParams.maxTradesPerDay - 1);
        m_currentParams.minRR *= 1.3;  // Increase required R:R
        m_currentParams.useScoutEntries = false;  // Disable scout entries
        
        if(m_logger) {
            m_logger.Warning("Detected " + IntegerToString(consecutiveLosses) + 
                           " consecutive losses - parameters adjusted to be more conservative");
        }
    }
    else if(consecutiveWins >= 3) {
        // Multiple consecutive wins - can be slightly more aggressive
        m_currentParams.baseRiskPercent *= 1.1;  // Increase risk slightly
        m_currentParams.maxTradesPerDay++;  // Allow one more trade
        
        if(m_logger) {
            m_logger.Info("Detected " + IntegerToString(consecutiveWins) + 
                         " consecutive wins - parameters adjusted to be slightly more aggressive");
        }
    }
    
    // Cap parameters to reasonable limits
    m_currentParams.baseRiskPercent = MathMin(1.0, m_currentParams.baseRiskPercent);
    m_currentParams.baseRiskPercent = MathMax(0.3, m_currentParams.baseRiskPercent);
    m_currentParams.maxTradesPerDay = MathMin(6, m_currentParams.maxTradesPerDay);
}

//+------------------------------------------------------------------+
//| Get ADX threshold with adaptations                               |
//+------------------------------------------------------------------+
double CAdaptiveFilters::GetADXThreshold(string symbol)
{
    return m_currentParams.adxThreshold;
}

//+------------------------------------------------------------------+
//| Check if volatility is within acceptable range                   |
//+------------------------------------------------------------------+
bool CAdaptiveFilters::CheckVolatility(double volatilityRatio, string symbol)
{
    return (volatilityRatio >= m_currentParams.volatilityMin && 
            volatilityRatio <= m_currentParams.volatilityMax);
}

//+------------------------------------------------------------------+
//| Get maximum trades allowed for current regime                    |
//+------------------------------------------------------------------+
int CAdaptiveFilters::GetMaxTradesForRegime()
{
    return m_currentParams.maxTradesPerDay;
}

//+------------------------------------------------------------------+
//| Get risk percent adjusted for current conditions                 |
//+------------------------------------------------------------------+
double CAdaptiveFilters::GetBaseRiskPercent(string symbol)
{
    return m_currentParams.baseRiskPercent;
}

//+------------------------------------------------------------------+
//| Get minimum risk-reward ratio for current conditions             |
//+------------------------------------------------------------------+
double CAdaptiveFilters::GetMinRR()
{
    return m_currentParams.minRR;
}

//+------------------------------------------------------------------+
//| Check if scout entries should be used                            |
//+------------------------------------------------------------------+
bool CAdaptiveFilters::ShouldUseScoutEntries()
{
    return m_currentParams.useScoutEntries;
}

//+------------------------------------------------------------------+
//| Get string representation of current regime                      |
//+------------------------------------------------------------------+
string CAdaptiveFilters::GetCurrentRegimeAsString() const
{
    switch(m_currentRegime) {
        case REGIME_STRONG_TREND: return "Strong Trend";
        case REGIME_MODERATE_TREND: return "Moderate Trend";
        case REGIME_WEAK_TREND: return "Weak Trend";
        case REGIME_RANGE_TIGHT: return "Tight Range";
        case REGIME_RANGE_WIDE: return "Wide Range";
        case REGIME_VOLATILE: return "Volatile";
        default: return "Undefined";
    }
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CAdaptiveFilters::GetStatusText() const
{
    string status = "Adaptive Filters Status:\n";
    
    status += "Market Regime: " + GetCurrentRegimeAsString() + "\n";
    status += "Trend Direction: " + (m_trendDirection > 0 ? "Up" : 
                                   (m_trendDirection < 0 ? "Down" : "Sideways")) + "\n";
    status += "Trend Strength (ADX): " + DoubleToString(m_trendStrength, 1) + "\n";
    status += "Volatility Ratio: " + DoubleToString(m_volatilityRatio, 2) + "\n";
    
    status += "Challenge Progress: " + DoubleToString(m_challengeProgress, 1) + 
             "%, Days Left: " + IntegerToString(m_remainingDays) + "\n";
    
    status += "Current Parameters:\n";
    status += "  ADX Threshold: " + DoubleToString(m_currentParams.adxThreshold, 1) + "\n";
    status += "  Volatility Range: " + DoubleToString(m_currentParams.volatilityMin, 1) + 
             " - " + DoubleToString(m_currentParams.volatilityMax, 1) + "\n";
    status += "  Min R:R: " + DoubleToString(m_currentParams.minRR, 1) + "\n";
    status += "  Max Trades: " + IntegerToString(m_currentParams.maxTradesPerDay) + "\n";
    status += "  Risk %: " + DoubleToString(m_currentParams.baseRiskPercent, 2) + "\n";
    status += "  Scout Entries: " + (m_currentParams.useScoutEntries ? "YES" : "NO") + "\n";
    
    return status;
} 