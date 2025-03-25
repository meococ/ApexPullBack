//+------------------------------------------------------------------+
//|                                               SonicR_Core.mqh |
//|                     SonicR PropFirm EA - Core Strategy Component |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Thư viện MT5 tiêu chuẩn
#include <Arrays/ArrayDouble.mqh>
#include <Arrays/ArrayString.mqh>
#include <Arrays/ArrayInt.mqh>
#include <Arrays/ArrayObj.mqh>

// Forward declarations
class CLogger;
class CPVSRA;

// Include required files
#include "SonicR_Logger.mqh"

// Class to store price patterns
class CPricePattern
{
private:
    string m_name;              // Pattern name
    int m_direction;            // 1 = Bullish, -1 = Bearish, 0 = Neutral
    double m_quality;           // Pattern quality (0-100)
    datetime m_time;            // Time when pattern was found
    int m_startBar;             // Start bar of pattern
    int m_endBar;               // End bar of pattern
    
public:
    // Constructor
    CPricePattern(string name, int direction, double quality, datetime time, int startBar, int endBar) : 
        m_name(name), m_direction(direction), m_quality(quality), m_time(time), m_startBar(startBar), m_endBar(endBar) {}
    
    // Getters
    string GetName() const { return m_name; }
    int GetDirection() const { return m_direction; }
    double GetQuality() const { return m_quality; }
    datetime GetTime() const { return m_time; }
    int GetStartBar() const { return m_startBar; }
    int GetEndBar() const { return m_endBar; }
};

// SonicR Core class for strategy logic
class CSonicRCore
{
private:
    // Logger
    CLogger* m_logger;
    
    // Dragon Line indicators
    int m_dragonMidHandle;      // Dragon Mid (EMA34 on Close)
    int m_dragonHighHandle;     // Dragon High (EMA34 on High)
    int m_dragonLowHandle;      // Dragon Low (EMA34 on Low)
    int m_trendHandle;          // Trend (EMA89 on Close)
    
    // PVSRA indicator handle
    int m_pvsraHandle;
    
    // SR indicator handle
    int m_srHandle;
    
    // ATR handle for volatility
    int m_atrHandle;
    
    // Data buffers
    double m_dragonMidBuffer[];
    double m_dragonHighBuffer[];
    double m_dragonLowBuffer[];
    double m_trendBuffer[];
    double m_atrBuffer[];
    
    // Recent price patterns
    CArrayObj m_recentPatterns;
    
    // Dragon-Trend alignment data
    bool m_isAlignedBullish;    // Dragon above Trend and pointing up
    bool m_isAlignedBearish;    // Dragon below Trend and pointing down
    
    // Multi-timeframe trend data
    int m_d1Trend;              // Daily trend: 1 = Up, -1 = Down, 0 = Sideways
    int m_h4Trend;              // H4 trend
    int m_h1Trend;              // H1 trend
    
    // Detected pullbacks
    bool m_bullishPullback;     // Bullish pullback detected
    bool m_bearishPullback;     // Bearish pullback detected
    
    // Helper methods
    bool CheckDragonTrendAlignment();
    void AnalyzeMultiTimeframeTrend();
    void DetectPullbacks();
    void DetectPricePatterns();
    
    // Buffer management
    void ClearBuffers();
    bool UpdateBuffers();
    
    // Price pattern detection methods
    bool IsDoubleTap(int startBar, int direction, double &quality);
    bool IsQuasimodo(int startBar, int direction, double &quality);
    bool IsBOS(int startBar, int direction, double &quality);  // Break of Structure
    
    // Pullback validation
    bool IsPullbackValid(int startBar, int direction);
    
public:
    // Constructor
    CSonicRCore();
    
    // Destructor
    ~CSonicRCore();
    
    // Init and release
    bool Initialize();
    void Cleanup();
    
    // Update on tick/bar
    void Update();
    void UpdateFull();
    void UpdateLight();
    
    // Signal detection methods
    int DetectClassicSetup();
    int DetectScoutSetup();
    
    // State checks
    bool AreHandlesValid() const;
    bool IsPVSRAConfirming(int direction) const;
    bool IsPullbackValid(int direction) const { return direction > 0 ? m_bullishPullback : m_bearishPullback; }
    
    // Getters for internal state
    int GetDailyTrend() const { return m_d1Trend; }
    int GetH4Trend() const { return m_h4Trend; }
    int GetH1Trend() const { return m_h1Trend; }
    bool IsAlignedBullish() const { return m_isAlignedBullish; }
    bool IsAlignedBearish() const { return m_isAlignedBearish; }
    double GetAverageTrueRange() const { return m_atrBuffer[0]; }
    
    // Tính ATR Multiplier dựa trên biến động thị trường
    double GetAdaptiveATRMultiplier(int direction);
    
    // Calculate entry, SL and TP levels for a given signal
    bool CalculateTradeLevels(int direction, double &entry, double &stopLoss, double &takeProfit);
    
    // Get current pullback info (for dashboard)
    void GetPullbackInfo(bool &bullish, bool &bearish) const {
        bullish = m_bullishPullback;
        bearish = m_bearishPullback;
    }
    
    // Get detected patterns info
    int GetPatternCount() const { return m_recentPatterns.Total(); }
    CPricePattern* GetPattern(int index) const { return index >= 0 && index < m_recentPatterns.Total() ? (CPricePattern*)m_recentPatterns.At(index) : NULL; }
    
    // Set logger
    void SetLogger(CLogger* logger) { m_logger = logger; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSonicRCore::CSonicRCore()
{
    m_logger = NULL;
    
    // Initialize indicator handles to invalid
    m_dragonMidHandle = INVALID_HANDLE;
    m_dragonHighHandle = INVALID_HANDLE;
    m_dragonLowHandle = INVALID_HANDLE;
    m_trendHandle = INVALID_HANDLE;
    m_pvsraHandle = INVALID_HANDLE;
    m_srHandle = INVALID_HANDLE;
    m_atrHandle = INVALID_HANDLE;
    
    // Initialize state
    m_isAlignedBullish = false;
    m_isAlignedBearish = false;
    m_d1Trend = 0;
    m_h4Trend = 0;
    m_h1Trend = 0;
    m_bullishPullback = false;
    m_bearishPullback = false;
    
    // Initialize pattern storage
    m_recentPatterns.Clear();
    m_recentPatterns.FreeMode(true); // Free objects when removed
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSonicRCore::~CSonicRCore()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize the Core                                              |
//+------------------------------------------------------------------+
bool CSonicRCore::Initialize()
{
    // Initialize Dragon indicators
    m_dragonMidHandle = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    m_dragonHighHandle = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_HIGH);
    m_dragonLowHandle = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_LOW);
    m_trendHandle = iMA(_Symbol, PERIOD_CURRENT, 89, 0, MODE_EMA, PRICE_CLOSE);
    
    // Initialize ATR
    m_atrHandle = iATR(_Symbol, PERIOD_CURRENT, 14);
    
    // Check if all handles are valid
    if(!AreHandlesValid()) {
        if(m_logger) m_logger.Error("Failed to initialize one or more indicator handles");
        Cleanup();
        return false;
    }
    
    // Allocate buffers
    ArraySetAsSeries(m_dragonMidBuffer, true);
    ArraySetAsSeries(m_dragonHighBuffer, true);
    ArraySetAsSeries(m_dragonLowBuffer, true);
    ArraySetAsSeries(m_trendBuffer, true);
    ArraySetAsSeries(m_atrBuffer, true);
    
    // Update buffers at initialization
    if(!UpdateBuffers()) {
        if(m_logger) m_logger.Error("Failed to update indicator buffers");
        Cleanup();
        return false;
    }
    
    // Initialize state
    AnalyzeMultiTimeframeTrend();
    DetectPullbacks();
    DetectPricePatterns();
    CheckDragonTrendAlignment();
    
    if(m_logger) m_logger.Info("CSonicRCore initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Clean up resources                                               |
//+------------------------------------------------------------------+
void CSonicRCore::Cleanup()
{
    // Release indicator handles
    if(m_dragonMidHandle != INVALID_HANDLE) {
        IndicatorRelease(m_dragonMidHandle);
        m_dragonMidHandle = INVALID_HANDLE;
    }
    
    if(m_dragonHighHandle != INVALID_HANDLE) {
        IndicatorRelease(m_dragonHighHandle);
        m_dragonHighHandle = INVALID_HANDLE;
    }
    
    if(m_dragonLowHandle != INVALID_HANDLE) {
        IndicatorRelease(m_dragonLowHandle);
        m_dragonLowHandle = INVALID_HANDLE;
    }
    
    if(m_trendHandle != INVALID_HANDLE) {
        IndicatorRelease(m_trendHandle);
        m_trendHandle = INVALID_HANDLE;
    }
    
    if(m_atrHandle != INVALID_HANDLE) {
        IndicatorRelease(m_atrHandle);
        m_atrHandle = INVALID_HANDLE;
    }
    
    if(m_pvsraHandle != INVALID_HANDLE) {
        IndicatorRelease(m_pvsraHandle);
        m_pvsraHandle = INVALID_HANDLE;
    }
    
    if(m_srHandle != INVALID_HANDLE) {
        IndicatorRelease(m_srHandle);
        m_srHandle = INVALID_HANDLE;
    }
    
    // Clear buffers
    ClearBuffers();
    
    // Clear patterns
    m_recentPatterns.Clear();
}

//+------------------------------------------------------------------+
//| Check if all indicator handles are valid                         |
//+------------------------------------------------------------------+
bool CSonicRCore::AreHandlesValid() const
{
    return (m_dragonMidHandle != INVALID_HANDLE &&
            m_dragonHighHandle != INVALID_HANDLE &&
            m_dragonLowHandle != INVALID_HANDLE &&
            m_trendHandle != INVALID_HANDLE &&
            m_atrHandle != INVALID_HANDLE);
}

//+------------------------------------------------------------------+
//| Clear indicator buffers                                          |
//+------------------------------------------------------------------+
void CSonicRCore::ClearBuffers()
{
    ArrayFree(m_dragonMidBuffer);
    ArrayFree(m_dragonHighBuffer);
    ArrayFree(m_dragonLowBuffer);
    ArrayFree(m_trendBuffer);
    ArrayFree(m_atrBuffer);
}

//+------------------------------------------------------------------+
//| Update indicator buffers                                         |
//+------------------------------------------------------------------+
bool CSonicRCore::UpdateBuffers()
{
    // Define required number of bars
    const int requiredBars = 50; // Enough for pattern detection
    
    // Copy Dragon Mid (EMA34 on Close)
    if(CopyBuffer(m_dragonMidHandle, 0, 0, requiredBars, m_dragonMidBuffer) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy Dragon Mid buffer: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Copy Dragon High (EMA34 on High)
    if(CopyBuffer(m_dragonHighHandle, 0, 0, requiredBars, m_dragonHighBuffer) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy Dragon High buffer: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Copy Dragon Low (EMA34 on Low)
    if(CopyBuffer(m_dragonLowHandle, 0, 0, requiredBars, m_dragonLowBuffer) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy Dragon Low buffer: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Copy Trend (EMA89 on Close)
    if(CopyBuffer(m_trendHandle, 0, 0, requiredBars, m_trendBuffer) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy Trend buffer: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Copy ATR
    if(CopyBuffer(m_atrHandle, 0, 0, requiredBars, m_atrBuffer) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy ATR buffer: " + IntegerToString(GetLastError()));
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Dragon-Trend alignment                                     |
//+------------------------------------------------------------------+
bool CSonicRCore::CheckDragonTrendAlignment()
{
    // Ensure we have valid data
    if(ArraySize(m_dragonMidBuffer) < 5 || ArraySize(m_trendBuffer) < 5) {
        return false;
    }
    
    // Previous alignment status
    bool prevBullish = m_isAlignedBullish;
    bool prevBearish = m_isAlignedBearish;
    
    // Reset alignment flags
    m_isAlignedBullish = false;
    m_isAlignedBearish = false;
    
    // Check for bullish alignment
    if(m_dragonMidBuffer[0] > m_trendBuffer[0] && 
       m_dragonMidBuffer[1] > m_trendBuffer[1] &&
       m_dragonMidBuffer[0] > m_dragonMidBuffer[3]) {
        m_isAlignedBullish = true;
    }
    
    // Check for bearish alignment
    if(m_dragonMidBuffer[0] < m_trendBuffer[0] && 
       m_dragonMidBuffer[1] < m_trendBuffer[1] &&
       m_dragonMidBuffer[0] < m_dragonMidBuffer[3]) {
        m_isAlignedBearish = true;
    }
    
    // Log alignment changes
    if(m_logger && (prevBullish != m_isAlignedBullish || prevBearish != m_isAlignedBearish)) {
        if(m_isAlignedBullish) {
            m_logger.Info("Dragon-Trend alignment changed to BULLISH");
        } else if(m_isAlignedBearish) {
            m_logger.Info("Dragon-Trend alignment changed to BEARISH");
        } else {
            m_logger.Info("Dragon-Trend alignment is now NEUTRAL");
        }
    }
    
    return m_isAlignedBullish || m_isAlignedBearish;
}

//+------------------------------------------------------------------+
//| Analyze trend across multiple timeframes                         |
//+------------------------------------------------------------------+
void CSonicRCore::AnalyzeMultiTimeframeTrend()
{
    // Store previous trends
    int prevD1Trend = m_d1Trend;
    int prevH4Trend = m_h4Trend;
    int prevH1Trend = m_h1Trend;
    
    // Analyze D1 trend
    int d1Handle = iMA(_Symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
    double d1EmaBuffer[];
    ArraySetAsSeries(d1EmaBuffer, true);
    
    if(d1Handle != INVALID_HANDLE && CopyBuffer(d1Handle, 0, 0, 3, d1EmaBuffer) > 0) {
        double d1Close[];
        ArraySetAsSeries(d1Close, true);
        
        if(CopyClose(_Symbol, PERIOD_D1, 0, 3, d1Close) > 0) {
            // Price above EMA200 and EMA200 is rising
            if(d1Close[0] > d1EmaBuffer[0] && d1EmaBuffer[0] > d1EmaBuffer[2]) {
                m_d1Trend = 1; // Bullish
            }
            // Price below EMA200 and EMA200 is falling
            else if(d1Close[0] < d1EmaBuffer[0] && d1EmaBuffer[0] < d1EmaBuffer[2]) {
                m_d1Trend = -1; // Bearish
            }
            // Else neutral/sideways
            else {
                m_d1Trend = 0;
            }
        }
        
        IndicatorRelease(d1Handle);
    }
    
    // Analyze H4 trend (similar logic)
    int h4Handle = iMA(_Symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE);
    double h4EmaBuffer[];
    ArraySetAsSeries(h4EmaBuffer, true);
    
    if(h4Handle != INVALID_HANDLE && CopyBuffer(h4Handle, 0, 0, 3, h4EmaBuffer) > 0) {
        double h4Close[];
        ArraySetAsSeries(h4Close, true);
        
        if(CopyClose(_Symbol, PERIOD_H4, 0, 3, h4Close) > 0) {
            if(h4Close[0] > h4EmaBuffer[0] && h4EmaBuffer[0] > h4EmaBuffer[2]) {
                m_h4Trend = 1; // Bullish
            }
            else if(h4Close[0] < h4EmaBuffer[0] && h4EmaBuffer[0] < h4EmaBuffer[2]) {
                m_h4Trend = -1; // Bearish
            }
            else {
                m_h4Trend = 0;
            }
        }
        
        IndicatorRelease(h4Handle);
    }
    
    // Analyze H1 trend using Dragon-Trend alignment
    m_h1Trend = m_isAlignedBullish ? 1 : (m_isAlignedBearish ? -1 : 0);
    
    // Log trend changes
    if(m_logger) {
        if(prevD1Trend != m_d1Trend) {
            m_logger.Info("D1 trend changed: " + TrendToString(prevD1Trend) + " -> " + TrendToString(m_d1Trend));
        }
        
        if(prevH4Trend != m_h4Trend) {
            m_logger.Info("H4 trend changed: " + TrendToString(prevH4Trend) + " -> " + TrendToString(m_h4Trend));
        }
        
        if(prevH1Trend != m_h1Trend) {
            m_logger.Info("H1 trend changed: " + TrendToString(prevH1Trend) + " -> " + TrendToString(m_h1Trend));
        }
    }
}

//+------------------------------------------------------------------+
//| Helper: Convert trend value to string                            |
//+------------------------------------------------------------------+
string TrendToString(int trend)
{
    switch(trend) {
        case 1: return "BULLISH";
        case -1: return "BEARISH";
        default: return "NEUTRAL";
    }
}

//+------------------------------------------------------------------+
//| Detect pullbacks to Dragon Line                                  |
//+------------------------------------------------------------------+
void CSonicRCore::DetectPullbacks()
{
    // Reset pullback flags
    bool prevBullishPB = m_bullishPullback;
    bool prevBearishPB = m_bearishPullback;
    
    m_bullishPullback = false;
    m_bearishPullback = false;
    
    // Make sure we have enough data
    if(ArraySize(m_dragonMidBuffer) < 5) {
        return;
    }
    
    // Get recent price data
    double close[];
    double low[];
    double high[];
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(high, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 10, close) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, 10, low) <= 0 ||
       CopyHigh(_Symbol, PERIOD_CURRENT, 0, 10, high) <= 0) {
        return;
    }
    
    // Check for bullish pullback (in uptrend)
    if(m_h1Trend > 0 || m_h4Trend > 0) {
        // Is price touching/near Dragon Mid/Low?
        bool touchingDragon = false;
        
        for(int i = 0; i < 3; i++) {
            // Check if price is near Dragon Line
            if(low[i] <= m_dragonMidBuffer[i] + _Point * 5 && 
               low[i] >= m_dragonLowBuffer[i] - _Point * 5) {
                touchingDragon = true;
                break;
            }
        }
        
        if(touchingDragon) {
            // Verify it's a pullback (previous candles were higher)
            bool isPullback = true;
            for(int i = 3; i < 7; i++) {
                if(low[i] <= low[0]) {
                    isPullback = false;
                    break;
                }
            }
            
            if(isPullback) {
                m_bullishPullback = true;
                
                // Validate pullback quality using price action
                for(int i = 0; i < 3; i++) {
                    // Check for potential reversal candle (hammer, etc.)
                    if(IsPullbackValid(i, 1)) {
                        if(m_logger && !prevBullishPB) {
                            m_logger.Info("Valid bullish pullback detected");
                        }
                        break;
                    }
                }
            }
        }
    }
    
    // Check for bearish pullback (in downtrend)
    if(m_h1Trend < 0 || m_h4Trend < 0) {
        // Is price touching/near Dragon Mid/High?
        bool touchingDragon = false;
        
        for(int i = 0; i < 3; i++) {
            // Check if price is near Dragon Line
            if(high[i] >= m_dragonMidBuffer[i] - _Point * 5 && 
               high[i] <= m_dragonHighBuffer[i] + _Point * 5) {
                touchingDragon = true;
                break;
            }
        }
        
        if(touchingDragon) {
            // Verify it's a pullback (previous candles were lower)
            bool isPullback = true;
            for(int i = 3; i < 7; i++) {
                if(high[i] >= high[0]) {
                    isPullback = false;
                    break;
                }
            }
            
            if(isPullback) {
                m_bearishPullback = true;
                
                // Validate pullback quality using price action
                for(int i = 0; i < 3; i++) {
                    // Check for potential reversal candle (shooting star, etc.)
                    if(IsPullbackValid(i, -1)) {
                        if(m_logger && !prevBearishPB) {
                            m_logger.Info("Valid bearish pullback detected");
                        }
                        break;
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Validate pullback quality using price action                     |
//+------------------------------------------------------------------+
bool CSonicRCore::IsPullbackValid(int startBar, int direction)
{
    // Get recent price data
    double close[];
    double open[];
    double high[];
    double low[];
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, startBar + 5, close) <= 0 ||
       CopyOpen(_Symbol, PERIOD_CURRENT, 0, startBar + 5, open) <= 0 ||
       CopyHigh(_Symbol, PERIOD_CURRENT, 0, startBar + 5, high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, startBar + 5, low) <= 0) {
        return false;
    }
    
    // Check if bar is in the expected direction
    bool isReversal = false;
    
    if(direction > 0) { // Bullish reversal
        // Check for bullish candle
        if(close[startBar] > open[startBar]) {
            // Check for higher low and higher high
            if(startBar + 1 < ArraySize(low) && low[startBar] > low[startBar + 1]) {
                isReversal = true;
            }
            
            // Check for long lower wick (hammer-like)
            double bodySize = MathAbs(close[startBar] - open[startBar]);
            double lowerWick = MathMin(close[startBar], open[startBar]) - low[startBar];
            
            if(lowerWick > bodySize * 1.5) {
                isReversal = true;
            }
        }
    }
    else if(direction < 0) { // Bearish reversal
        // Check for bearish candle
        if(close[startBar] < open[startBar]) {
            // Check for lower high and lower low
            if(startBar + 1 < ArraySize(high) && high[startBar] < high[startBar + 1]) {
                isReversal = true;
            }
            
            // Check for long upper wick (shooting star-like)
            double bodySize = MathAbs(close[startBar] - open[startBar]);
            double upperWick = high[startBar] - MathMax(close[startBar], open[startBar]);
            
            if(upperWick > bodySize * 1.5) {
                isReversal = true;
            }
        }
    }
    
    return isReversal;
}

//+------------------------------------------------------------------+
//| Detect common price patterns                                     |
//+------------------------------------------------------------------+
void CSonicRCore::DetectPricePatterns()
{
    // Only keep recent patterns (clear older ones)
    while(m_recentPatterns.Total() > 10) {
        m_recentPatterns.Delete(m_recentPatterns.Total() - 1);
    }
    
    // Scan for patterns starting from recent bars
    for(int startBar = 1; startBar < 10; startBar++) {
        // Check for bullish patterns
        double quality = 0;
        
        // Double Tap
        if(IsDoubleTap(startBar, 1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("DoubleTap", 1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bullish Double Tap detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
        
        // Quasimodo
        if(IsQuasimodo(startBar, 1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("Quasimodo", 1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bullish Quasimodo detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
        
        // Break of Structure
        if(IsBOS(startBar, 1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("BOS", 1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bullish Break of Structure detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
        
        // Check for bearish patterns
        quality = 0;
        
        // Double Tap
        if(IsDoubleTap(startBar, -1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("DoubleTap", -1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bearish Double Tap detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
        
        // Quasimodo
        if(IsQuasimodo(startBar, -1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("Quasimodo", -1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bearish Quasimodo detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
        
        // Break of Structure
        if(IsBOS(startBar, -1, quality)) {
            // Add to recent patterns if quality is sufficient
            if(quality >= 70) {
                CPricePattern* pattern = new CPricePattern("BOS", -1, quality, 
                                                         iTime(_Symbol, PERIOD_CURRENT, startBar),
                                                         startBar, startBar);
                m_recentPatterns.Insert(pattern, 0);
                
                if(m_logger) {
                    m_logger.Info("Bearish Break of Structure detected, quality: " + DoubleToString(quality, 1));
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Double Tap pattern detection                                     |
//+------------------------------------------------------------------+
bool CSonicRCore::IsDoubleTap(int startBar, int direction, double &quality)
{
    // Get price data
    double high[];
    double low[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, startBar + 15, high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, startBar + 15, low) <= 0) {
        return false;
    }
    
    // Initialize quality score
    quality = 0;
    
    // Check for Double Tap (double bottom/top)
    if(direction > 0) { // Bullish (double bottom)
        // Find two similar lows
        double firstLow = 0, secondLow = 0;
        int firstLowIndex = -1, secondLowIndex = -1;
        
        // Find first low
        for(int i = startBar; i < startBar + 10; i++) {
            if(i >= ArraySize(low)) break;
            
            bool isLow = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
                if(i+j < ArraySize(low) && low[i] >= low[i+j]) isLow = false;
            }
            
            if(isLow) {
                firstLow = low[i];
                firstLowIndex = i;
                break;
            }
        }
        
        // Find second low
        if(firstLowIndex > 0) {
            for(int i = firstLowIndex + 3; i < firstLowIndex + 10; i++) {
                if(i >= ArraySize(low)) break;
                
                bool isLow = true;
                for(int j = 1; j <= 2; j++) {
                    if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
                    if(i+j < ArraySize(low) && low[i] >= low[i+j]) isLow = false;
                }
                
                if(isLow) {
                    secondLow = low[i];
                    secondLowIndex = i;
                    break;
                }
            }
        }
        
        // Check if we found two lows
        if(firstLowIndex >= 0 && secondLowIndex >= 0) {
            // Check if lows are similar (within 20% of ATR)
            if(MathAbs(firstLow - secondLow) < m_atrBuffer[0] * 0.2) {
                // Calculate pattern quality
                quality = 70 + (1.0 - MathAbs(firstLow - secondLow) / (m_atrBuffer[0] * 0.2)) * 30;
                return true;
            }
        }
    }
    else if(direction < 0) { // Bearish (double top)
        // Find two similar highs
        double firstHigh = 0, secondHigh = 0;
        int firstHighIndex = -1, secondHighIndex = -1;
        
        // Find first high
        for(int i = startBar; i < startBar + 10; i++) {
            if(i >= ArraySize(high)) break;
            
            bool isHigh = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
                if(i+j < ArraySize(high) && high[i] <= high[i+j]) isHigh = false;
            }
            
            if(isHigh) {
                firstHigh = high[i];
                firstHighIndex = i;
                break;
            }
        }
        
        // Find second high
        if(firstHighIndex > 0) {
            for(int i = firstHighIndex + 3; i < firstHighIndex + 10; i++) {
                if(i >= ArraySize(high)) break;
                
                bool isHigh = true;
                for(int j = 1; j <= 2; j++) {
                    if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
                    if(i+j < ArraySize(high) && high[i] <= high[i+j]) isHigh = false;
                }
                
                if(isHigh) {
                    secondHigh = high[i];
                    secondHighIndex = i;
                    break;
                }
            }
        }
        
        // Check if we found two highs
        if(firstHighIndex >= 0 && secondHighIndex >= 0) {
            // Check if highs are similar (within 20% of ATR)
            if(MathAbs(firstHigh - secondHigh) < m_atrBuffer[0] * 0.2) {
                // Calculate pattern quality
                quality = 70 + (1.0 - MathAbs(firstHigh - secondHigh) / (m_atrBuffer[0] * 0.2)) * 30;
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Quasimodo pattern detection                                      |
//+------------------------------------------------------------------+
bool CSonicRCore::IsQuasimodo(int startBar, int direction, double &quality)
{
    // Get price data
    double high[];
    double low[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, startBar + 15, high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, startBar + 15, low) <= 0) {
        return false;
    }
    
    // Initialize quality score
    quality = 0;
    
    // Check for Quasimodo pattern
    if(direction > 0) { // Bullish Quasimodo
        // Look for: Low (1) - High (2) - Lower Low (3) - Lower High (4) - Higher Low (5)
        int idx1 = -1, idx2 = -1, idx3 = -1, idx4 = -1, idx5 = -1;
        
        // Find initial low
        for(int i = startBar + 5; i < startBar + 15; i++) {
            if(i >= ArraySize(low)) break;
            
            bool isLow = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
                if(i+j < ArraySize(low) && low[i] >= low[i+j]) isLow = false;
            }
            
            if(isLow) {
                idx1 = i;
                break;
            }
        }
        
        // Find subsequent points if initial low was found
        if(idx1 >= 0) {
            // Find high after initial low
            for(int i = idx1 - 1; i > idx1 - 5; i--) {
                if(i < 0) break;
                
                bool isHigh = true;
                for(int j = 1; j <= 1; j++) {
                    if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
                    if(i+j < ArraySize(high) && high[i] <= high[i+j]) isHigh = false;
                }
                
                if(isHigh) {
                    idx2 = i;
                    break;
                }
            }
            
            // Find lower low
            if(idx2 >= 0) {
                for(int i = idx2 - 1; i > idx2 - 5; i--) {
                    if(i < 0) break;
                    
                    if(low[i] < low[idx1]) {
                        bool isLow = true;
                        for(int j = 1; j <= 1; j++) {
                            if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
                            if(i+j < ArraySize(low) && low[i] >= low[i+j]) isLow = false;
                        }
                        
                        if(isLow) {
                            idx3 = i;
                            break;
                        }
                    }
                }
            }
            
            // Find lower high
            if(idx3 >= 0) {
                for(int i = idx3 - 1; i > idx3 - 5; i--) {
                    if(i < 0) break;
                    
                    if(high[i] < high[idx2]) {
                        bool isHigh = true;
                        for(int j = 1; j <= 1; j++) {
                            if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
                            if(i+j < ArraySize(high) && high[i] <= high[i+j]) isHigh = false;
                        }
                        
                        if(isHigh) {
                            idx4 = i;
                            break;
                        }
                    }
                }
            }
            
            // Find higher low
            if(idx4 >= 0) {
                for(int i = idx4 - 1; i >= 0; i--) {
                    if(low[i] > low[idx3] && low[i] < high[idx4]) {
                        bool isLow = true;
                        for(int j = 1; j <= 1; j++) {
                            if(i-j >= 0 && low[i] >= low[i-j]) isLow = false;
                            if(i+j < ArraySize(low) && low[i] >= low[i+j]) isLow = false;
                        }
                        
                        if(isLow) {
                            idx5 = i;
                            break;
                        }
                    }
                }
            }
            
            // Check if we found all required points
            if(idx1 >= 0 && idx2 >= 0 && idx3 >= 0 && idx4 >= 0 && idx5 >= 0) {
                // Calculate pattern quality
                quality = 80 + (low[idx5] - low[idx3]) / (high[idx4] - low[idx3]) * 20;
                return true;
            }
        }
    }
    else if(direction < 0) { // Bearish Quasimodo
        // Look for: High (1) - Low (2) - Higher High (3) - Higher Low (4) - Lower High (5)
        int idx1 = -1, idx2 = -1, idx3 = -1, idx4 = -1, idx5 = -1;
        
        // Find initial high
        for(int i = startBar + 5; i < startBar + 15; i++) {
            if(i >= ArraySize(high)) break;
            
            bool isHigh = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && high[i] <= high[i-j]) isHigh = false;
                if(i+j < ArraySize(high) && high[i] <= high[i+j]) isHigh = false;
            }
            
            if(isHigh) {
                idx1 = i;
                break;
            }
        }
        
        // Find subsequent points if initial high was found
        if(idx1 >= 0) {
            // Logic for bearish Quasimodo (mirror of bullish version)
            // ...
            
            // Check if we found all required points
            if(idx1 >= 0 && idx2 >= 0 && idx3 >= 0 && idx4 >= 0 && idx5 >= 0) {
                // Calculate pattern quality
                quality = 80 + (high[idx3] - high[idx5]) / (high[idx3] - low[idx4]) * 20;
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Break of Structure pattern detection                             |
//+------------------------------------------------------------------+
bool CSonicRCore::IsBOS(int startBar, int direction, double &quality)
{
    // Get price data
    double high[];
    double low[];
    double close[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, startBar + 15, high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, startBar + 15, low) <= 0 ||
       CopyClose(_Symbol, PERIOD_CURRENT, 0, startBar + 15, close) <= 0) {
        return false;
    }
    
    // Initialize quality score
    quality = 0;
    
    // Check for Break of Structure
    if(direction > 0) { // Bullish BOS
        // Find series of lower highs and lower lows, followed by a higher high
        bool foundLowerStructure = false;
        int countLowerPoints = 0;
        
        // Look for at least 3 lower points
        for(int i = startBar + 3; i < startBar + 10; i++) {
            if(i+1 >= ArraySize(high)) break;
            
            if(high[i] < high[i+1] && low[i] < low[i+1]) {
                countLowerPoints++;
                if(countLowerPoints >= 3) {
                    foundLowerStructure = true;
                    break;
                }
            }
            else {
                countLowerPoints = 0; // Reset count if structure is broken
            }
        }
        
        // If we found downtrend structure, look for break with higher high
        if(foundLowerStructure) {
            // Check recent bars for higher high
            bool foundBreak = false;
            
            for(int i = startBar; i < startBar + 3; i++) {
                if(i+1 >= ArraySize(high)) break;
                
                if(high[i] > high[i+1] && close[i] > high[i+1]) {
                    foundBreak = true;
                    
                    // Calculate quality based on strength of break
                    quality = 70 + (close[i] - high[i+1]) / (m_atrBuffer[0]) * 30;
                    quality = MathMin(quality, 100);
                    break;
                }
            }
            
            return foundBreak;
        }
    }
    else if(direction < 0) { // Bearish BOS
        // Find series of higher highs and higher lows, followed by a lower low
        bool foundHigherStructure = false;
        int countHigherPoints = 0;
        
        // Look for at least 3 higher points
        for(int i = startBar + 3; i < startBar + 10; i++) {
            if(i+1 >= ArraySize(high)) break;
            
            if(high[i] > high[i+1] && low[i] > low[i+1]) {
                countHigherPoints++;
                if(countHigherPoints >= 3) {
                    foundHigherStructure = true;
                    break;
                }
            }
            else {
                countHigherPoints = 0; // Reset count if structure is broken
            }
        }
        
        // If we found uptrend structure, look for break with lower low
        if(foundHigherStructure) {
            // Check recent bars for lower low
            bool foundBreak = false;
            
            for(int i = startBar; i < startBar + 3; i++) {
                if(i+1 >= ArraySize(low)) break;
                
                if(low[i] < low[i+1] && close[i] < low[i+1]) {
                    foundBreak = true;
                    
                    // Calculate quality based on strength of break
                    quality = 70 + (low[i+1] - close[i]) / (m_atrBuffer[0]) * 30;
                    quality = MathMin(quality, 100);
                    break;
                }
            }
            
            return foundBreak;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update core analysis on tick                                     |
//+------------------------------------------------------------------+
void CSonicRCore::Update()
{
    // Skip if handles aren't valid
    if(!AreHandlesValid()) {
        if(m_logger) m_logger.Error("Cannot update SonicRCore: invalid indicator handles");
        return;
    }
    
    // Update indicator buffers
    if(!UpdateBuffers()) {
        if(m_logger) m_logger.Error("Failed to update indicator buffers");
        return;
    }
    
    // Update analysis
    CheckDragonTrendAlignment();
    AnalyzeMultiTimeframeTrend();
    DetectPullbacks();
    DetectPricePatterns();
}

//+------------------------------------------------------------------+
//| Update full - cập nhật tất cả phân tích (dùng cho bar mới)       |
//+------------------------------------------------------------------+
void CSonicRCore::UpdateFull()
{
    // Skip if handles aren't valid
    if(!AreHandlesValid()) {
        if(m_logger) m_logger.Error("Cannot update SonicRCore: invalid indicator handles");
        return;
    }
    
    // Update indicator buffers
    if(!UpdateBuffers()) {
        if(m_logger) m_logger.Error("Failed to update indicator buffers");
        return;
    }
    
    // Update all analysis (CPU intensive parts)
    CheckDragonTrendAlignment();
    AnalyzeMultiTimeframeTrend();
    DetectPullbacks();
    DetectPricePatterns();  // Phần nặng nhất - chỉ chạy khi có bar mới
    
    if(m_logger) m_logger.Debug("SonicRCore full update completed");
}

//+------------------------------------------------------------------+
//| Update light - chỉ cập nhật phần cần thiết (cho mỗi tick)        |
//+------------------------------------------------------------------+
void CSonicRCore::UpdateLight()
{
    // Skip if handles aren't valid
    if(!AreHandlesValid()) {
        if(m_logger) m_logger.Error("Cannot update SonicRCore: invalid indicator handles");
        return;
    }
    
    // Update indicator buffers
    if(!UpdateBuffers()) {
        if(m_logger) m_logger.Error("Failed to update indicator buffers");
        return;
    }
    
    // Chỉ cập nhật phần cần thiết cho mỗi tick
    CheckDragonTrendAlignment();  // Cập nhật trạng thái căn chỉnh
    
    // Bỏ qua các phân tích nặng khác:
    // - AnalyzeMultiTimeframeTrend()
    // - DetectPullbacks()
    // - DetectPricePatterns()
}

//+------------------------------------------------------------------+
//| Check if PVSRA confirms the signal direction                     |
//+------------------------------------------------------------------+
bool CSonicRCore::IsPVSRAConfirming(int direction) const
{
    // Sử dụng biến toàn cục trực tiếp
    if(g_pvsra == NULL) {
        return false;
    }
    
    // Kiểm tra xác nhận phù hợp với hướng
    if(direction > 0) {
        return g_pvsra.IsBullishConfirmation();
    }
    else if(direction < 0) {
        return g_pvsra.IsBearishConfirmation();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect classic pullback setup                                    |
//+------------------------------------------------------------------+
int CSonicRCore::DetectClassicSetup()
{
    // Check for Dragon-Trend alignment
    if(!m_isAlignedBullish && !m_isAlignedBearish) {
        return 0; // No alignment
    }
    
    // Check for valid pullback
    if(!m_bullishPullback && !m_bearishPullback) {
        return 0; // No pullback
    }
    
    // Need at least two timeframes aligned
    if(m_isAlignedBullish) {
        // Check if H4 and/or D1 are also bullish
        if((m_h4Trend > 0 || m_d1Trend > 0) && m_bullishPullback) {
            return 1; // Bullish setup
        }
    }
    else if(m_isAlignedBearish) {
        // Check if H4 and/or D1 are also bearish
        if((m_h4Trend < 0 || m_d1Trend < 0) && m_bearishPullback) {
            return -1; // Bearish setup
        }
    }
    
    return 0; // No clear setup
}

//+------------------------------------------------------------------+
//| Detect scout entry setup (early entry)                           |
//+------------------------------------------------------------------+
int CSonicRCore::DetectScoutSetup()
{
    // Check if there are recent patterns with high quality
    for(int i = 0; i < m_recentPatterns.Total(); i++) {
        CPricePattern* pattern = GetPattern(i);
        if(pattern == NULL) continue;
        
        // Only consider recent patterns
        if(pattern.GetStartBar() > 5) continue;
        
        // Check pattern quality
        if(pattern.GetQuality() >= 80) {
            // Check if pattern aligns with at least one timeframe trend
            if(pattern.GetDirection() > 0 && (m_h1Trend > 0 || m_h4Trend > 0 || m_d1Trend > 0)) {
                return 1; // Bullish scout setup
            }
            else if(pattern.GetDirection() < 0 && (m_h1Trend < 0 || m_h4Trend < 0 || m_d1Trend < 0)) {
                return -1; // Bearish scout setup
            }
        }
    }
    
    return 0; // No scout setup
}

//+------------------------------------------------------------------+
//| Calculate entry, SL and TP levels for a given signal            |
//+------------------------------------------------------------------+
bool CSonicRCore::CalculateTradeLevels(int direction, double &entry, double &stopLoss, double &takeProfit)
{
    // Get price data
    double close[];
    double high[];
    double low[];
    double open[];
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 10, close) <= 0 ||
       CopyHigh(_Symbol, PERIOD_CURRENT, 0, 10, high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, 10, low) <= 0 ||
       CopyOpen(_Symbol, PERIOD_CURRENT, 0, 10, open) <= 0) {
        return false;
    }
    
    // Sử dụng ATR Multiplier thích ứng thay vì giá trị cố định
    double atrMultiplier = GetAdaptiveATRMultiplier(direction);
    
    if(direction > 0) { // Buy
        // Entry at current Ask
        entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // Stop Loss: Find recent swing low or use ATR
        double swingLow = low[0];
        int swingLowIndex = 0;
        
        // Look for swing low in recent bars
        for(int i = 1; i < 10; i++) {
            if(i >= ArraySize(low)) break;
            
            bool isSwingLow = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && low[i] >= low[i-j]) isSwingLow = false;
                if(i+j < ArraySize(low) && low[i] >= low[i+j]) isSwingLow = false;
            }
            
            if(isSwingLow && low[i] < swingLow) {
                swingLow = low[i];
                swingLowIndex = i;
            }
        }
        
        // If we found a valid swing low, use it with buffer
        if(swingLowIndex > 0) {
            stopLoss = swingLow - _Point * 10; // 10 points buffer
        }
        else {
            // Otherwise use ATR for SL with adaptive multiplier
            stopLoss = entry - m_atrBuffer[0] * atrMultiplier;
        }
        
        // Calculate Take Profit based on R:R ratio (minimum 2:1)
        double slDistance = entry - stopLoss;
        takeProfit = entry + slDistance * 2.0;
    }
    else if(direction < 0) { // Sell
        // Entry at current Bid
        entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        
        // Stop Loss: Find recent swing high or use ATR
        double swingHigh = high[0];
        int swingHighIndex = 0;
        
        // Look for swing high in recent bars
        for(int i = 1; i < 10; i++) {
            if(i >= ArraySize(high)) break;
            
            bool isSwingHigh = true;
            for(int j = 1; j <= 2; j++) {
                if(i-j >= 0 && high[i] <= high[i-j]) isSwingHigh = false;
                if(i+j < ArraySize(high) && high[i] <= high[i+j]) isSwingHigh = false;
            }
            
            if(isSwingHigh && high[i] > swingHigh) {
                swingHigh = high[i];
                swingHighIndex = i;
            }
        }
        
        // If we found a valid swing high, use it with buffer
        if(swingHighIndex > 0) {
            stopLoss = swingHigh + _Point * 10; // 10 points buffer
        }
        else {
            // Otherwise use ATR for SL with adaptive multiplier
            stopLoss = entry + m_atrBuffer[0] * atrMultiplier;
        }
        
        // Calculate Take Profit based on R:R ratio (minimum 2:1)
        double slDistance = stopLoss - entry;
        takeProfit = entry - slDistance * 2.0;
    }
    else {
        return false; // Invalid direction
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Tính ATR Multiplier dựa trên biến động thị trường                |
//+------------------------------------------------------------------+
double CSonicRCore::GetAdaptiveATRMultiplier(int direction)
{
    // Đảm bảo m_atrBuffer có dữ liệu hợp lệ
    if(ArraySize(m_atrBuffer) < 20)
        return 1.5;  // Giá trị mặc định
    
    // Tính toán tỷ lệ biến động
    double currentATR = m_atrBuffer[0];
    double avgATR = 0;
    for(int i = 1; i < 20; i++) {
        avgATR += m_atrBuffer[i];
    }
    avgATR /= 19;
    
    double volatilityRatio = currentATR / avgATR;
    
    // Tính toán ATR multiplier dựa vào biến động
    double baseMultiplier;
    
    if(volatilityRatio > 1.5)
        baseMultiplier = 1.2;  // Biến động cao - SL hẹp hơn
    else if(volatilityRatio < 0.7)
        baseMultiplier = 1.8;  // Biến động thấp - SL rộng hơn
    else
        baseMultiplier = 1.5;  // Mặc định
    
    // Điều chỉnh thêm dựa vào xu hướng
    if(direction > 0) {  // Buy signal
        if(m_h4Trend > 0 && m_d1Trend > 0)
            baseMultiplier *= 0.9;  // Xu hướng mạnh - SL hẹp hơn
    }
    else if(direction < 0) {  // Sell signal
        if(m_h4Trend < 0 && m_d1Trend < 0)
            baseMultiplier *= 0.9;  // Xu hướng mạnh - SL hẹp hơn
    }
    
    // Log thông tin nếu cần
    if(m_logger) {
        m_logger.Debug("ATR Multiplier thích ứng: " + DoubleToString(baseMultiplier, 2) + 
                     " (Volatility: " + DoubleToString(volatilityRatio, 2) + ")");
    }
    
    return baseMultiplier;
}