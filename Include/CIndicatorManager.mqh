//+------------------------------------------------------------------+
//| CIndicatorManager.mqh - Manages all technical indicators and signals|
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
class CSRManager;

//+------------------------------------------------------------------+
//| CIndicatorManager Class - Manages all indicators and signals      |
//+------------------------------------------------------------------+
class CIndicatorManager {
private:
    // Basic properties
    string m_symbol;                   // Symbol
    ENUM_TIMEFRAMES m_timeframe;       // Timeframe
    
    // Indicator settings
    int m_ema34Period;                 // EMA 34 period
    int m_ema89Period;                 // EMA 89 period
    int m_ema200Period;                // EMA 200 period
    int m_adxPeriod;                   // ADX period
    int m_macdFastPeriod;              // MACD fast EMA period
    int m_macdSlowPeriod;              // MACD slow EMA period
    int m_macdSignalPeriod;            // MACD signal period
    int m_atrPeriod;                   // ATR period
    int m_requiredConfluenceScore;     // Required confluence score for signals
    
    // Indicator handles
    int m_ema34Handle;                 // EMA 34 handle
    int m_ema89Handle;                 // EMA 89 handle
    int m_ema200Handle;                // EMA 200 handle
    int m_adxHandle;                   // ADX handle
    int m_macdHandle;                  // MACD handle
    int m_atrHandle;                   // ATR handle
    
    // Indicator values
    double m_ema34Buffer[];            // EMA 34 values buffer
    double m_ema89Buffer[];            // EMA 89 values buffer
    double m_ema200Buffer[];           // EMA 200 values buffer
    double m_adxBuffer[];              // ADX main values buffer
    double m_macdMainBuffer[];         // MACD main line buffer
    double m_macdSignalBuffer[];       // MACD signal line buffer
    double m_macdHistogramBuffer[];    // MACD histogram buffer
    double m_atrBuffer[];              // ATR values buffer
    
    // State variables
    bool m_isBullishTrend;             // Whether current trend is bullish
    bool m_isBearishTrend;             // Whether current trend is bearish
    bool m_buySignalActive;            // Buy signal currently active
    bool m_sellSignalActive;           // Sell signal currently active
    ENUM_TREND_STRENGTH m_trendStrength; // Current trend strength
    MarketState m_marketState;         // Current market state
    
    // Signal information
    SignalInfo m_currentSignal;        // Current signal details
    
    // Price action patterns
    PriceActionPattern m_detectedPatterns[]; // Detected PA patterns
    
    // Divergence
    DivergenceInfo m_divergence;       // Current divergence info
    
    // Other components
    CSRManager* m_srManager;           // Pointer to SR Manager
    
    //--- Private methods
    
    // Analyzes the current trend based on EMAs
    void AnalyzeTrend() {
        // Reset trend flags
        m_isBullishTrend = false;
        m_isBearishTrend = false;
        m_trendStrength = TREND_STRENGTH_NONE;
        
        // Get latest values
        double ema34 = m_ema34Buffer[0];
        double ema89 = m_ema89Buffer[0];
        double ema200 = m_ema200Buffer[0];
        double close = iClose(m_symbol, m_timeframe, 0);
        
        // Check EMA slopes (10 bars back)
        double ema89_prev = m_ema89Buffer[10]; 
        double ema89_slope = ema89 - ema89_prev;
        
        // Check ADX for trend strength
        double adx = m_adxBuffer[0];
        
        // Determine trend strength based on ADX
        if (adx < 15.0) {
            m_trendStrength = TREND_STRENGTH_NONE;
        } else if (adx < 25.0) {
            m_trendStrength = TREND_STRENGTH_WEAK;
        } else if (adx < 45.0) {
            m_trendStrength = TREND_STRENGTH_MEDIUM;
        } else {
            m_trendStrength = TREND_STRENGTH_STRONG;
        }
        
        // Identify bullish trend
        if ((ema34 > ema89) && 
            (close > ema89) && 
            (ema89_slope > 0) &&   // EMA89 has positive slope
            (close > ema200))      // Price above EMA200 (long-term trend)
        {
            m_isBullishTrend = true;
        }
        // Identify bearish trend
        else if ((ema34 < ema89) && 
                (close < ema89) && 
                (ema89_slope < 0) &&   // EMA89 has negative slope
                (close < ema200))      // Price below EMA200 (long-term trend)
        {
            m_isBearishTrend = true;
        }
        
        // Update market state
        m_marketState.isBullishTrend = m_isBullishTrend;
        m_marketState.isBearishTrend = m_isBearishTrend;
        m_marketState.trendStrength = m_trendStrength;
        m_marketState.ema34 = ema34;
        m_marketState.ema89 = ema89;
        m_marketState.ema200 = ema200;
        m_marketState.adxValue = adx;
    }
    
    // Detects pullback to EMA34 in bullish trend
    bool DetectBullishPullback() {
        if (!m_isBullishTrend) return false;
        
        // Get latest values
        double close = iClose(m_symbol, m_timeframe, 0);
        double low = iLow(m_symbol, m_timeframe, 0);
        double ema34 = m_ema34Buffer[0];
        double atr = m_atrBuffer[0];
        
        // Pullback: price tests EMA34 (Dragon Line) from above
        bool pullback = (low <= ema34 + atr*0.1) && 
                        (low >= ema34 - atr*0.5) &&
                        (close > ema34);  // Close above Dragon
                        
        return pullback;
    }
    
    // Detects pullback to EMA34 in bearish trend
    bool DetectBearishPullback() {
        if (!m_isBearishTrend) return false;
        
        // Get latest values
        double close = iClose(m_symbol, m_timeframe, 0);
        double high = iHigh(m_symbol, m_timeframe, 0);
        double ema34 = m_ema34Buffer[0];
        double atr = m_atrBuffer[0];
        
        // Pullback: price tests EMA34 (Dragon Line) from below
        bool pullback = (high >= ema34 - atr*0.1) && 
                        (high <= ema34 + atr*0.5) &&
                        (close < ema34);  // Close below Dragon
                        
        return pullback;
    }
    
    // Checks for bullish candlestick patterns
    bool IsBullishCandlePattern() {
        // Reset patterns array
        ArrayResize(m_detectedPatterns, 0);
        
        // Get candle data for current bar
        double open = iOpen(m_symbol, m_timeframe, 0);
        double high = iHigh(m_symbol, m_timeframe, 0);
        double low = iLow(m_symbol, m_timeframe, 0);
        double close = iClose(m_symbol, m_timeframe, 0);
        
        // Get candle data for previous bar
        double prevOpen = iOpen(m_symbol, m_timeframe, 1);
        double prevHigh = iHigh(m_symbol, m_timeframe, 1);
        double prevLow = iLow(m_symbol, m_timeframe, 1);
        double prevClose = iClose(m_symbol, m_timeframe, 1);
        
        // Get ATR for reference
        double atr = m_atrBuffer[0];
        
        // Variables to store pattern detection results
        bool patternDetected = false;
        PriceActionPattern newPattern;
        
        // Check for bullish pin bar (hammer)
        double bodySize = MathAbs(open - close);
        double totalSize = high - low;
        double lowerWick = MathMin(open, close) - low;
        double upperWick = high - MathMax(open, close);
        
        if (close > open &&                    // Bullish candle
            totalSize > atr * 0.5 &&           // Significant size
            lowerWick > bodySize * 2 &&        // Lower wick at least 2x body
            lowerWick > upperWick * 3 &&       // Lower wick at least 3x upper wick
            bodySize > 0)                      // Avoid doji-like candles
        {
            newPattern.type = PA_PATTERN_PIN_BAR;
            newPattern.significance = MathMin(lowerWick / bodySize / 3, 1.0); // Normalize to 0-1
            newPattern.time = iTime(m_symbol, m_timeframe, 0);
            newPattern.barIndex = 0;
            newPattern.isBullish = true;
            newPattern.isBearish = false;
            
            ArrayResize(m_detectedPatterns, ArraySize(m_detectedPatterns) + 1);
            m_detectedPatterns[ArraySize(m_detectedPatterns) - 1] = newPattern;
            patternDetected = true;
        }
        
        // Check for bullish engulfing
        if (prevClose < prevOpen &&           // Previous candle bearish
            close > open &&                   // Current candle bullish
            close > prevOpen &&               // Current close above previous open
            open < prevClose &&               // Current open below previous close
            totalSize > atr * 0.5)            // Significant size
        {
            newPattern.type = PA_PATTERN_ENGULFING;
            newPattern.significance = MathMin((close - open) / (prevOpen - prevClose), 1.0); // Normalize
            newPattern.time = iTime(m_symbol, m_timeframe, 0);
            newPattern.barIndex = 0;
            newPattern.isBullish = true;
            newPattern.isBearish = false;
            
            ArrayResize(m_detectedPatterns, ArraySize(m_detectedPatterns) + 1);
            m_detectedPatterns[ArraySize(m_detectedPatterns) - 1] = newPattern;
            patternDetected = true;
        }
        
        // Additional patterns can be added here...
        
        return patternDetected;
    }
    
    // Checks for bearish candlestick patterns
    bool IsBearishCandlePattern() {
        // Similar to IsBullishCandlePattern but for bearish patterns
        // Reset patterns array
        ArrayResize(m_detectedPatterns, 0);
        
        // Get candle data for current bar
        double open = iOpen(m_symbol, m_timeframe, 0);
        double high = iHigh(m_symbol, m_timeframe, 0);
        double low = iLow(m_symbol, m_timeframe, 0);
        double close = iClose(m_symbol, m_timeframe, 0);
        
        // Get candle data for previous bar
        double prevOpen = iOpen(m_symbol, m_timeframe, 1);
        double prevHigh = iHigh(m_symbol, m_timeframe, 1);
        double prevLow = iLow(m_symbol, m_timeframe, 1);
        double prevClose = iClose(m_symbol, m_timeframe, 1);
        
        // Get ATR for reference
        double atr = m_atrBuffer[0];
        
        // Variables to store pattern detection results
        bool patternDetected = false;
        PriceActionPattern newPattern;
        
        // Check for bearish pin bar (shooting star)
        double bodySize = MathAbs(open - close);
        double totalSize = high - low;
        double lowerWick = MathMin(open, close) - low;
        double upperWick = high - MathMax(open, close);
        
        if (close < open &&                    // Bearish candle
            totalSize > atr * 0.5 &&           // Significant size
            upperWick > bodySize * 2 &&        // Upper wick at least 2x body
            upperWick > lowerWick * 3 &&       // Upper wick at least 3x lower wick
            bodySize > 0)                      // Avoid doji-like candles
        {
            newPattern.type = PA_PATTERN_PIN_BAR;
            newPattern.significance = MathMin(upperWick / bodySize / 3, 1.0); // Normalize to 0-1
            newPattern.time = iTime(m_symbol, m_timeframe, 0);
            newPattern.barIndex = 0;
            newPattern.isBullish = false;
            newPattern.isBearish = true;
            
            ArrayResize(m_detectedPatterns, ArraySize(m_detectedPatterns) + 1);
            m_detectedPatterns[ArraySize(m_detectedPatterns) - 1] = newPattern;
            patternDetected = true;
        }
        
        // Check for bearish engulfing
        if (prevClose > prevOpen &&           // Previous candle bullish
            close < open &&                   // Current candle bearish
            close < prevOpen &&               // Current close below previous open
            open > prevClose &&               // Current open above previous close
            totalSize > atr * 0.5)            // Significant size
        {
            newPattern.type = PA_PATTERN_ENGULFING;
            newPattern.significance = MathMin((open - close) / (prevClose - prevOpen), 1.0); // Normalize
            newPattern.time = iTime(m_symbol, m_timeframe, 0);
            newPattern.barIndex = 0;
            newPattern.isBullish = false;
            newPattern.isBearish = true;
            
            ArrayResize(m_detectedPatterns, ArraySize(m_detectedPatterns) + 1);
            m_detectedPatterns[ArraySize(m_detectedPatterns) - 1] = newPattern;
            patternDetected = true;
        }
        
        // Additional patterns can be added here...
        
        return patternDetected;
    }
    
    // Checks for bullish momentum confirmation
    bool IsBullishMomentum() {
        // Get MACD values
        double macdMain = m_macdMainBuffer[0];
        double macdSignal = m_macdSignalBuffer[0];
        double macdHist = m_macdHistogramBuffer[0];
        
        // Simple momentum check (can be enhanced)
        bool basicMomentum = (macdMain > 0 && macdMain > macdSignal && macdHist > 0);
        
        // Check for hidden bullish divergence (in uptrend)
        bool hiddenDivergence = DetectHiddenBullishDivergence();
        
        // Update market state
        m_marketState.momentum = basicMomentum || hiddenDivergence ? 
                                MOMENTUM_STATE_BULLISH : MOMENTUM_STATE_NONE;
        
        m_marketState.macdMain = macdMain;
        m_marketState.macdSignal = macdSignal;
        m_marketState.macdHistogram = macdHist;
        
        return (basicMomentum || hiddenDivergence);
    }
    
    // Checks for bearish momentum confirmation
    bool IsBearishMomentum() {
        // Get MACD values
        double macdMain = m_macdMainBuffer[0];
        double macdSignal = m_macdSignalBuffer[0];
        double macdHist = m_macdHistogramBuffer[0];
        
        // Simple momentum check (can be enhanced)
        bool basicMomentum = (macdMain < 0 && macdMain < macdSignal && macdHist < 0);
        
        // Check for hidden bearish divergence (in downtrend)
        bool hiddenDivergence = DetectHiddenBearishDivergence();
        
        // Update market state
        m_marketState.momentum = basicMomentum || hiddenDivergence ? 
                                MOMENTUM_STATE_BEARISH : MOMENTUM_STATE_NONE;
        
        return (basicMomentum || hiddenDivergence);
    }
    
    // Detect hidden bullish divergence
    bool DetectHiddenBullishDivergence() {
        // Reset divergence info
        m_divergence = DivergenceInfo();
        
        // Looking for hidden bullish divergence:
        // Price: higher low, Indicator: lower low
        
        // Scan last several bars to find two significant lows
        int scan_depth = 20;
        int low1_idx = -1, low2_idx = -1;
        
        // Find first recent low (between 1-10 bars back)
        for (int i = 1; i <= 10; i++) {
            if (IsLocalLow(i)) {
                low1_idx = i;
                break;
            }
        }
        
        // Find second older low (between low1+3 and scan_depth)
        if (low1_idx > 0) {
            for (int i = low1_idx + 3; i <= scan_depth; i++) {
                if (IsLocalLow(i)) {
                    low2_idx = i;
                    break;
                }
            }
        }
        
        // If we found two lows, check for divergence
        if (low1_idx > 0 && low2_idx > 0) {
            double price_low1 = iLow(m_symbol, m_timeframe, low1_idx);
            double price_low2 = iLow(m_symbol, m_timeframe, low2_idx);
            
            double macd_low1 = m_macdMainBuffer[low1_idx];
            double macd_low2 = m_macdMainBuffer[low2_idx];
            
            // Hidden bullish divergence: price makes higher low but MACD makes lower low
            if (price_low1 > price_low2 && macd_low1 < macd_low2) {
                // Set divergence info
                m_divergence.isHidden = true;
                m_divergence.isBullish = true;
                m_divergence.startBar = low2_idx;
                m_divergence.endBar = low1_idx;
                m_divergence.priceStart = price_low2;
                m_divergence.priceEnd = price_low1;
                m_divergence.indicatorStart = macd_low2;
                m_divergence.indicatorEnd = macd_low1;
                m_divergence.indicator = "MACD";
                
                return true;
            }
        }
        
        return false;
    }
    
    // Detect hidden bearish divergence
    bool DetectHiddenBearishDivergence() {
        // Reset divergence info
        m_divergence = DivergenceInfo();
        
        // Looking for hidden bearish divergence:
        // Price: lower high, Indicator: higher high
        
        // Scan last several bars to find two significant highs
        int scan_depth = 20;
        int high1_idx = -1, high2_idx = -1;
        
        // Find first recent high (between 1-10 bars back)
        for (int i = 1; i <= 10; i++) {
            if (IsLocalHigh(i)) {
                high1_idx = i;
                break;
            }
        }
        
        // Find second older high (between high1+3 and scan_depth)
        if (high1_idx > 0) {
            for (int i = high1_idx + 3; i <= scan_depth; i++) {
                if (IsLocalHigh(i)) {
                    high2_idx = i;
                    break;
                }
            }
        }
        
        // If we found two highs, check for divergence
        if (high1_idx > 0 && high2_idx > 0) {
            double price_high1 = iHigh(m_symbol, m_timeframe, high1_idx);
            double price_high2 = iHigh(m_symbol, m_timeframe, high2_idx);
            
            double macd_high1 = m_macdMainBuffer[high1_idx];
            double macd_high2 = m_macdMainBuffer[high2_idx];
            
            // Hidden bearish divergence: price makes lower high but MACD makes higher high
            if (price_high1 < price_high2 && macd_high1 > macd_high2) {
                // Set divergence info
                m_divergence.isHidden = true;
                m_divergence.isBearish = true;
                m_divergence.startBar = high2_idx;
                m_divergence.endBar = high1_idx;
                m_divergence.priceStart = price_high2;
                m_divergence.priceEnd = price_high1;
                m_divergence.indicatorStart = macd_high2;
                m_divergence.indicatorEnd = macd_high1;
                m_divergence.indicator = "MACD";
                
                return true;
            }
        }
        
        return false;
    }
    
    // Helper: Check if bar at index is a local low
    bool IsLocalLow(int index) {
        if (index <= 0 || index >= iBars(m_symbol, m_timeframe) - 2) return false;
        
        double currentLow = iLow(m_symbol, m_timeframe, index);
        double prevLow = iLow(m_symbol, m_timeframe, index - 1);
        double nextLow = iLow(m_symbol, m_timeframe, index + 1);
        
        return (currentLow < prevLow && currentLow < nextLow);
    }
    
    // Helper: Check if bar at index is a local high
    bool IsLocalHigh(int index) {
        if (index <= 0 || index >= iBars(m_symbol, m_timeframe) - 2) return false;
        
        double currentHigh = iHigh(m_symbol, m_timeframe, index);
        double prevHigh = iHigh(m_symbol, m_timeframe, index - 1);
        double nextHigh = iHigh(m_symbol, m_timeframe, index + 1);
        
        return (currentHigh > prevHigh && currentHigh > nextHigh);
    }
    
    // Checks if the price is near a strong S/R level
    bool IsPriceNearSRLevel() {
        if (m_srManager == NULL) return false;
        
        double currentPrice = iClose(m_symbol, m_timeframe, 0);
        double atr = m_atrBuffer[0];
        
        // Delegate to SR Manager to check if price is near a strong level
        return m_srManager.IsPriceNearStrongLevel(currentPrice, atr);
    }
    
public:
    // Constructor
    CIndicatorManager(string symbol, ENUM_TIMEFRAMES timeframe) {
        m_symbol = symbol;
        m_timeframe = timeframe;
        
        // Initialize with default values
        m_ema34Period = DEFAULT_EMA34_PERIOD;
        m_ema89Period = DEFAULT_EMA89_PERIOD;
        m_ema200Period = DEFAULT_EMA200_PERIOD;
        m_adxPeriod = DEFAULT_ADX_PERIOD;
        m_macdFastPeriod = DEFAULT_MACD_FAST;
        m_macdSlowPeriod = DEFAULT_MACD_SLOW;
        m_macdSignalPeriod = DEFAULT_MACD_SIGNAL;
        m_atrPeriod = DEFAULT_ATR_PERIOD;
        m_requiredConfluenceScore = 2; // Default: require 2 out of 3 confirmations
        
        // Initialize handles
        m_ema34Handle = INVALID_HANDLE;
        m_ema89Handle = INVALID_HANDLE;
        m_ema200Handle = INVALID_HANDLE;
        m_adxHandle = INVALID_HANDLE;
        m_macdHandle = INVALID_HANDLE;
        m_atrHandle = INVALID_HANDLE;
        
        // Initialize state
        m_isBullishTrend = false;
        m_isBearishTrend = false;
        m_buySignalActive = false;
        m_sellSignalActive = false;
        m_trendStrength = TREND_STRENGTH_NONE;
        
        // Initialize market state
        m_marketState = MarketState();
        
        // Initialize signal
        m_currentSignal = SignalInfo();
        
        // Initialize other pointers
        m_srManager = NULL;
    }
    
    // Destructor
    ~CIndicatorManager() {
        // Release all indicator handles
        ReleaseIndicators();
    }
    
    // Initialize all indicators
    bool Initialize() {
        // Create EMA 34 indicator
        m_ema34Handle = iMA(m_symbol, m_timeframe, m_ema34Period, 0, MODE_EMA, PRICE_CLOSE);
        if (m_ema34Handle == INVALID_HANDLE) {
            Print("Failed to create EMA 34 indicator handle");
            return false;
        }
        
        // Create EMA 89 indicator
        m_ema89Handle = iMA(m_symbol, m_timeframe, m_ema89Period, 0, MODE_EMA, PRICE_CLOSE);
        if (m_ema89Handle == INVALID_HANDLE) {
            Print("Failed to create EMA 89 indicator handle");
            return false;
        }
        
        // Create EMA 200 indicator
        m_ema200Handle = iMA(m_symbol, m_timeframe, m_ema200Period, 0, MODE_EMA, PRICE_CLOSE);
        if (m_ema200Handle == INVALID_HANDLE) {
            Print("Failed to create EMA 200 indicator handle");
            return false;
        }
        
        // Create ADX indicator
        m_adxHandle = iADX(m_symbol, m_timeframe, m_adxPeriod);
        if (m_adxHandle == INVALID_HANDLE) {
            Print("Failed to create ADX indicator handle");
            return false;
        }
        
        // Create MACD indicator
        m_macdHandle = iMACD(m_symbol, m_timeframe, m_macdFastPeriod, m_macdSlowPeriod, 
                            m_macdSignalPeriod, PRICE_CLOSE);
        if (m_macdHandle == INVALID_HANDLE) {
            Print("Failed to create MACD indicator handle");
            return false;
        }
        
        // Create ATR indicator
        m_atrHandle = iATR(m_symbol, m_timeframe, m_atrPeriod);
        if (m_atrHandle == INVALID_HANDLE) {
            Print("Failed to create ATR indicator handle");
            return false;
        }
        
        // Initialize buffers
        ArraySetAsSeries(m_ema34Buffer, true);
        ArraySetAsSeries(m_ema89Buffer, true);
        ArraySetAsSeries(m_ema200Buffer, true);
        ArraySetAsSeries(m_adxBuffer, true);
        ArraySetAsSeries(m_macdMainBuffer, true);
        ArraySetAsSeries(m_macdSignalBuffer, true);
        ArraySetAsSeries(m_macdHistogramBuffer, true);
        ArraySetAsSeries(m_atrBuffer, true);
        
        // Initial update
        if (!Update()) {
            Print("Failed to update indicators during initialization");
            return false;
        }
        
        return true;
    }
    
    // Update all indicators
    bool Update() {
        // Copy EMA 34 data
        if (CopyBuffer(m_ema34Handle, 0, 0, 20, m_ema34Buffer) <= 0) {
            Print("Failed to copy EMA 34 data");
            return false;
        }
        
        // Copy EMA 89 data
        if (CopyBuffer(m_ema89Handle, 0, 0, 20, m_ema89Buffer) <= 0) {
            Print("Failed to copy EMA 89 data");
            return false;
        }
        
        // Copy EMA 200 data
        if (CopyBuffer(m_ema200Handle, 0, 0, 20, m_ema200Buffer) <= 0) {
            Print("Failed to copy EMA 200 data");
            return false;
        }
        
        // Copy ADX data (main line)
        if (CopyBuffer(m_adxHandle, 0, 0, 20, m_adxBuffer) <= 0) {
            Print("Failed to copy ADX data");
            return false;
        }
        
        // Copy MACD data
        if (CopyBuffer(m_macdHandle, 0, 0, 20, m_macdMainBuffer) <= 0 ||
            CopyBuffer(m_macdHandle, 1, 0, 20, m_macdSignalBuffer) <= 0 ||
            CopyBuffer(m_macdHandle, 2, 0, 20, m_macdHistogramBuffer) <= 0) {
            Print("Failed to copy MACD data");
            return false;
        }
        
        // Copy ATR data
        if (CopyBuffer(m_atrHandle, 0, 0, 20, m_atrBuffer) <= 0) {
            Print("Failed to copy ATR data");
            return false;
        }
        
        // Analyze current state
        AnalyzeTrend();
        
        // Update market state ATR
        m_marketState.atrValue = m_atrBuffer[0];
        
        return true;
    }
    
    // Check for entry signals
    void CheckEntrySignals() {
        // Reset current signals
        m_buySignalActive = false;
        m_sellSignalActive = false;
        m_currentSignal = SignalInfo();
        
        // Skip if no trend is identified
        if (!m_isBullishTrend && !m_isBearishTrend) return;
        
        // 1. Check for pullbacks
        bool bullishPullback = DetectBullishPullback();
        bool bearishPullback = DetectBearishPullback();
        
        if (!bullishPullback && !bearishPullback) return;
        
        // 2. Check for candlestick patterns
        bool bullishCandle = IsBullishCandlePattern();
        bool bearishCandle = IsBearishCandlePattern();
        
        // 3. Check for momentum confirmation
        bool bullishMomentum = IsBullishMomentum();
        bool bearishMomentum = IsBearishMomentum();
        
        // 4. Check for S/R confirmation
        bool srConfirmation = IsPriceNearSRLevel();
        
        // 5. Calculate confluence scores
        int bullishScore = (bullishPullback ? 1 : 0) + 
                          (bullishCandle ? 1 : 0) + 
                          (bullishMomentum ? 1 : 0) +
                          (srConfirmation ? 1 : 0);
                           
        int bearishScore = (bearishPullback ? 1 : 0) + 
                          (bearishCandle ? 1 : 0) + 
                          (bearishMomentum ? 1 : 0) +
                          (srConfirmation ? 1 : 0);
        
        // 6. Activate signals if score meets threshold
        if (bullishScore >= m_requiredConfluenceScore && m_isBullishTrend) {
            m_buySignalActive = true;
            
            // Set up signal info
            m_currentSignal.type = SIGNAL_BUY;
            m_currentSignal.time = TimeCurrent();
            m_currentSignal.price = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
            m_currentSignal.strength = bullishScore >= 3 ? SIGNAL_STRONG : 
                                      (bullishScore >= 2 ? SIGNAL_MEDIUM : SIGNAL_WEAK);
            m_currentSignal.stopLoss = CalculateBuyStopLoss();
            m_currentSignal.takeProfit = CalculateBuyTakeProfit(m_currentSignal.stopLoss);
            m_currentSignal.confirmed = true;
            m_currentSignal.patternDetected = bullishCandle && ArraySize(m_detectedPatterns) > 0 ? 
                                             m_detectedPatterns[0].type : PA_PATTERN_NONE;
            m_currentSignal.srConfirmation = srConfirmation;
            m_currentSignal.momentumConfirmation = bullishMomentum;
            
            // Calculate R:R
            double riskPips = (m_currentSignal.price - m_currentSignal.stopLoss) / _Point;
            double rewardPips = (m_currentSignal.takeProfit - m_currentSignal.price) / _Point;
            m_currentSignal.riskRewardRatio = riskPips > 0 ? rewardPips / riskPips : 0;
            
            // Add reasons for signal
            int reasonIndex = 0;
            if (bullishPullback) m_currentSignal.reasons[reasonIndex++] = "Bullish Pullback to EMA34";
            if (bullishCandle) m_currentSignal.reasons[reasonIndex++] = "Bullish Candlestick Pattern";
            if (bullishMomentum) m_currentSignal.reasons[reasonIndex++] = "Bullish Momentum Confirmation";
            if (srConfirmation) m_currentSignal.reasons[reasonIndex++] = "Support Level Confirmation";
        }
        
        if (bearishScore >= m_requiredConfluenceScore && m_isBearishTrend) {
            m_sellSignalActive = true;
            
            // Set up signal info
            m_currentSignal.type = SIGNAL_SELL;
            m_currentSignal.time = TimeCurrent();
            m_currentSignal.price = SymbolInfoDouble(m_symbol, SYMBOL_BID);
            m_currentSignal.strength = bearishScore >= 3 ? SIGNAL_STRONG : 
                                      (bearishScore >= 2 ? SIGNAL_MEDIUM : SIGNAL_WEAK);
            m_currentSignal.stopLoss = CalculateSellStopLoss();
            m_currentSignal.takeProfit = CalculateSellTakeProfit(m_currentSignal.stopLoss);
            m_currentSignal.confirmed = true;
            m_currentSignal.patternDetected = bearishCandle && ArraySize(m_detectedPatterns) > 0 ? 
                                             m_detectedPatterns[0].type : PA_PATTERN_NONE;
            m_currentSignal.srConfirmation = srConfirmation;
            m_currentSignal.momentumConfirmation = bearishMomentum;
            
            // Calculate R:R
            double riskPips = (m_currentSignal.stopLoss - m_currentSignal.price) / _Point;
            double rewardPips = (m_currentSignal.price - m_currentSignal.takeProfit) / _Point;
            m_currentSignal.riskRewardRatio = riskPips > 0 ? rewardPips / riskPips : 0;
            
            // Add reasons for signal
            int reasonIndex = 0;
            if (bearishPullback) m_currentSignal.reasons[reasonIndex++] = "Bearish Pullback to EMA34";
            if (bearishCandle) m_currentSignal.reasons[reasonIndex++] = "Bearish Candlestick Pattern";
            if (bearishMomentum) m_currentSignal.reasons[reasonIndex++] = "Bearish Momentum Confirmation";
            if (srConfirmation) m_currentSignal.reasons[reasonIndex++] = "Resistance Level Confirmation";
        }
    }
    
    // Calculate stop loss for a buy position
    double CalculateBuyStopLoss() {
        double atr = m_atrBuffer[0];
        double currentLow = iLow(m_symbol, m_timeframe, 0);
        double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        
        // Check if SR Manager exists and can provide a level
        if (m_srManager != NULL) {
            double srStopLevel = m_srManager.GetNearestSupportLevel(currentLow - atr);
            if (srStopLevel > 0) {
                // Add a buffer below SR level
                return srStopLevel - atr * 0.3;
            }
        }
        
        // Fallback: use recent swing low
        double swingLow = currentLow;
        for (int i = 1; i <= 5; i++) {
            if (IsLocalLow(i)) {
                swingLow = iLow(m_symbol, m_timeframe, i);
                break;
            }
        }
        
        // If no swing low found, use current low minus ATR as buffer
        double stopLoss = swingLow - atr * 0.3;
        
        // Ensure minimum distance from entry
        double minStopDistance = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
        if (entryPrice - stopLoss < minStopDistance) {
            stopLoss = entryPrice - minStopDistance - atr * 0.3;
        }
        
        return NormalizeDouble(stopLoss, _Digits);
    }
    
    // Calculate stop loss for a sell position
    double CalculateSellStopLoss() {
        double atr = m_atrBuffer[0];
        double currentHigh = iHigh(m_symbol, m_timeframe, 0);
        double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        
        // Check if SR Manager exists and can provide a level
        if (m_srManager != NULL) {
            double srStopLevel = m_srManager.GetNearestResistanceLevel(currentHigh + atr);
            if (srStopLevel > 0) {
                // Add a buffer above SR level
                return srStopLevel + atr * 0.3;
            }
        }
        
        // Fallback: use recent swing high
        double swingHigh = currentHigh;
        for (int i = 1; i <= 5; i++) {
            if (IsLocalHigh(i)) {
                swingHigh = iHigh(m_symbol, m_timeframe, i);
                break;
            }
        }
        
        // If no swing high found, use current high plus ATR as buffer
        double stopLoss = swingHigh + atr * 0.3;
        
        // Ensure minimum distance from entry
        double minStopDistance = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
        if (stopLoss - entryPrice < minStopDistance) {
            stopLoss = entryPrice + minStopDistance + atr * 0.3;
        }
        
        return NormalizeDouble(stopLoss, _Digits);
    }
    
    // Calculate take profit for a buy position
    double CalculateBuyTakeProfit(double stopLoss) {
        double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        double riskPips = entryPrice - stopLoss;
        double takeProfitMultiplier = DEFAULT_TP1_MULTIPLIER;
        
        // Calculate take profit as R multiple
        double takeProfit = entryPrice + (riskPips * takeProfitMultiplier);
        
        // Ensure minimum distance from entry
        double minTpDistance = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
        if (takeProfit - entryPrice < minTpDistance) {
            takeProfit = entryPrice + minTpDistance + riskPips * 0.2;
        }
        
        return NormalizeDouble(takeProfit, _Digits);
    }
    
    // Calculate take profit for a sell position
    double CalculateSellTakeProfit(double stopLoss) {
        double entryPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double riskPips = stopLoss - entryPrice;
        double takeProfitMultiplier = DEFAULT_TP1_MULTIPLIER;
        
        // Calculate take profit as R multiple
        double takeProfit = entryPrice - (riskPips * takeProfitMultiplier);
        
        // Ensure minimum distance from entry
        double minTpDistance = SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
        if (entryPrice - takeProfit < minTpDistance) {
            takeProfit = entryPrice - minTpDistance - riskPips * 0.2;
        }
        
        return NormalizeDouble(takeProfit, _Digits);
    }
    
    // Release all indicator handles
    void ReleaseIndicators() {
        // Release EMA indicators
        if (m_ema34Handle != INVALID_HANDLE) {
            IndicatorRelease(m_ema34Handle);
            m_ema34Handle = INVALID_HANDLE;
        }
        
        if (m_ema89Handle != INVALID_HANDLE) {
            IndicatorRelease(m_ema89Handle);
            m_ema89Handle = INVALID_HANDLE;
        }
        
        if (m_ema200Handle != INVALID_HANDLE) {
            IndicatorRelease(m_ema200Handle);
            m_ema200Handle = INVALID_HANDLE;
        }
        
        // Release ADX indicator
        if (m_adxHandle != INVALID_HANDLE) {
            IndicatorRelease(m_adxHandle);
            m_adxHandle = INVALID_HANDLE;
        }
        
        // Release MACD indicator
        if (m_macdHandle != INVALID_HANDLE) {
            IndicatorRelease(m_macdHandle);
            m_macdHandle = INVALID_HANDLE;
        }
        
        // Release ATR indicator
        if (m_atrHandle != INVALID_HANDLE) {
            IndicatorRelease(m_atrHandle);
            m_atrHandle = INVALID_HANDLE;
        }
    }
    
    //--- Setters
    
    // Set EMA periods
    void SetEMAPeriods(int ema34, int ema89, int ema200) {
        m_ema34Period = ema34;
        m_ema89Period = ema89;
        m_ema200Period = ema200;
    }
    
    // Set ADX period
    void SetADXPeriod(int period) {
        m_adxPeriod = period;
    }
    
    // Set MACD parameters
    void SetMACDParameters(int fastPeriod, int slowPeriod, int signalPeriod) {
        m_macdFastPeriod = fastPeriod;
        m_macdSlowPeriod = slowPeriod;
        m_macdSignalPeriod = signalPeriod;
    }
    
    // Set ATR period
    void SetATRPeriod(int period) {
        m_atrPeriod = period;
    }
    
    // Set required confluence score
    void SetRequiredConfluenceScore(int score) {
        m_requiredConfluenceScore = score > 0 ? score : 2;
    }
    
    // Set SR Manager reference
    void SetSRManager(CSRManager* srManager) {
        m_srManager = srManager;
    }
    
    //--- Getters
    
    // Get trend state (bullish)
    bool IsBullishTrend() const {
        return m_isBullishTrend;
    }
    
    // Get trend state (bearish)
    bool IsBearishTrend() const {
        return m_isBearishTrend;
    }
    
    // Get active buy signal
    bool IsBuySignalActive() const {
        return m_buySignalActive;
    }
    
    // Get active sell signal
    bool IsSellSignalActive() const {
        return m_sellSignalActive;
    }
    
    // Get current ADX value
    double GetADXValue() const {
        return m_adxBuffer[0];
    }
    
    // Get current ATR value
    double GetATRValue() const {
        return m_atrBuffer[0];
    }
    
    // Get current trend strength
    ENUM_TREND_STRENGTH GetTrendStrength() const {
        return m_trendStrength;
    }
    
    // Get current market state
    MarketState GetMarketState() const {
        return m_marketState;
    }
    
    // Get current signal info
    SignalInfo GetCurrentSignal() const {
        return m_currentSignal;
    }
    
    // Get detected price action patterns
    void GetDetectedPatterns(PriceActionPattern& patterns[]) {
        int size = ArraySize(m_detectedPatterns);
        ArrayResize(patterns, size);
        for (int i = 0; i < size; i++) {
            patterns[i] = m_detectedPatterns[i];
        }
    }
    
    // Get divergence info
    DivergenceInfo GetDivergenceInfo() const {
        return m_divergence;
    }
};