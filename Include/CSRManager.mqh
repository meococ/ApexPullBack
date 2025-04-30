//+------------------------------------------------------------------+
//| CSRManager.mqh - Support/Resistance levels management              |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

//+------------------------------------------------------------------+
//| CSRManager Class - Manages support/resistance levels              |
//+------------------------------------------------------------------+
class CSRManager {
private:
    // Basic properties
    string m_symbol;                   // Symbol
    ENUM_TIMEFRAMES m_timeframe;       // Main timeframe
    ENUM_TIMEFRAMES m_srTimeframe;     // Timeframe for SR detection (higher)
    
    // SR Levels
    SRLevel m_levels[];                // Array of S/R levels
    int m_lastUpdateBar;               // Bar index of last update
    datetime m_lastUpdateTime;         // Time of last update
    
    // Settings
    double m_mergeThreshold;           // Distance threshold for merging nearby levels (ATR multiple)
    double m_expirationBars;           // Number of bars after which a level expires if not touched
    int m_maxLevels;                   // Maximum number of levels to track
    double m_minTouchStrength;         // Minimum strength for a level to be considered valid
    
    // Buffers for ZigZag calculations
    double m_zigzagBuffer[];           // ZigZag values for swing detection
    int m_zigzagHighs[];               // Bar indices of ZigZag highs
    int m_zigzagLows[];                // Bar indices of ZigZag lows
    datetime m_zigzagHighTimes[];      // Times of ZigZag highs
    datetime m_zigzagLowTimes[];       // Times of ZigZag lows
    
    // Indicator handles
    int m_emaHandle;                   // EMA handle for longterm level
    int m_atrHandle;                   // ATR handle for level width/merging
    
    // Buffer for indicator values
    double m_emaBuffer[];              // EMA values buffer
    double m_atrBuffer[];              // ATR values buffer
    
    //--- Private methods
    
    // Calculate ZigZag values for swing detection
    void CalculateZigZag(int depth = 12, int deviation = 5, int backstep = 3) {
        // Clear existing arrays
        ArrayFree(m_zigzagBuffer);
        ArrayFree(m_zigzagHighs);
        ArrayFree(m_zigzagLows);
        ArrayFree(m_zigzagHighTimes);
        ArrayFree(m_zigzagLowTimes);
        
        // Set up arrays
        int bars = iBars(m_symbol, m_srTimeframe);
        int lookback = MathMin(bars - 1, 200); // Limit lookback period
        
        ArrayResize(m_zigzagBuffer, lookback);
        ArraySetAsSeries(m_zigzagBuffer, true);
        
        // Variables to track highs and lows
        double curHigh = 0, curLow = 0;
        int countHighs = 0, countLows = 0;
        
        // Temporary arrays for high/low points
        int tempHighs[], tempLows[];
        datetime tempHighTimes[], tempLowTimes[];
        ArrayResize(tempHighs, lookback);
        ArrayResize(tempLows, lookback);
        ArrayResize(tempHighTimes, lookback);
        ArrayResize(tempLowTimes, lookback);
        
        // Find ZigZag points using peak detection algorithm
        for (int i = lookback - depth - 1; i >= 1; i--) {
            bool isHigh = true;
            bool isLow = true;
            
            double currentHigh = iHigh(m_symbol, m_srTimeframe, i);
            double currentLow = iLow(m_symbol, m_srTimeframe, i);
            
            // Check if this is a high point
            for (int j = 1; j <= depth; j++) {
                if (i + j < lookback && iHigh(m_symbol, m_srTimeframe, i + j) > currentHigh) {
                    isHigh = false;
                }
                if (i - j >= 0 && iHigh(m_symbol, m_srTimeframe, i - j) > currentHigh) {
                    isHigh = false;
                }
            }
            
            // Check if this is a low point
            for (int j = 1; j <= depth; j++) {
                if (i + j < lookback && iLow(m_symbol, m_srTimeframe, i + j) < currentLow) {
                    isLow = false;
                }
                if (i - j >= 0 && iLow(m_symbol, m_srTimeframe, i - j) < currentLow) {
                    isLow = false;
                }
            }
            
            // If this is a significant high or low
            if (isHigh && MathAbs(currentHigh - curLow) > deviation * _Point) {
                curHigh = currentHigh;
                m_zigzagBuffer[i] = curHigh;
                
                // Store high point
                tempHighs[countHighs] = i;
                tempHighTimes[countHighs] = iTime(m_symbol, m_srTimeframe, i);
                countHighs++;
                
                // Add to SR levels
                SRLevel level;
                level.price = curHigh;
                level.time = iTime(m_symbol, m_srTimeframe, i);
                level.type = SR_TYPE_RESISTANCE;
                level.source = SR_SOURCE_SWING;
                level.strength = SR_STRENGTH_MEDIUM;
                level.touchCount = 1;
                level.width = m_atrBuffer[0] * 0.2;
                level.active = true;
                level.lastTouchTime = level.time;
                
                AddLevel(level);
            }
            
            if (isLow && MathAbs(curHigh - currentLow) > deviation * _Point) {
                curLow = currentLow;
                m_zigzagBuffer[i] = curLow;
                
                // Store low point
                tempLows[countLows] = i;
                tempLowTimes[countLows] = iTime(m_symbol, m_srTimeframe, i);
                countLows++;
                
                // Add to SR levels
                SRLevel level;
                level.price = curLow;
                level.time = iTime(m_symbol, m_srTimeframe, i);
                level.type = SR_TYPE_SUPPORT;
                level.source = SR_SOURCE_SWING;
                level.strength = SR_STRENGTH_MEDIUM;
                level.touchCount = 1;
                level.width = m_atrBuffer[0] * 0.2;
                level.active = true;
                level.lastTouchTime = level.time;
                
                AddLevel(level);
            }
        }
        
        // Resize final arrays to actual count
        ArrayResize(m_zigzagHighs, countHighs);
        ArrayResize(m_zigzagLows, countLows);
        ArrayResize(m_zigzagHighTimes, countHighs);
        ArrayResize(m_zigzagLowTimes, countLows);
        
        // Copy data to final arrays
        for (int i = 0; i < countHighs; i++) {
            m_zigzagHighs[i] = tempHighs[i];
            m_zigzagHighTimes[i] = tempHighTimes[i];
        }
        
        for (int i = 0; i < countLows; i++) {
            m_zigzagLows[i] = tempLows[i];
            m_zigzagLowTimes[i] = tempLowTimes[i];
        }
    }
    
    // Detect round number levels
    void DetectRoundNumbers() {
        // Get symbol info
        double point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
        int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
        
        // Get price range
        double currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        double range = 500 * point; // Consider levels within this range
        
        // Determine round number step based on digits
        double step;
        if (digits == 5 || digits == 3) { // Forex pairs typically
            // For 5 digit brokers, round to 0.00000, 0.00500, 0.01000, etc.
            step = 0.00500;
        } else if (digits == 4 || digits == 2) {
            // For 4 digit brokers, round to 0.0000, 0.0050, 0.0100, etc.
            step = 0.0050;
        } else if (digits <= 1) { // Indices, etc.
            step = 1.0;
        } else { // Other instruments
            step = MathPow(10, -digits + 1);
        }
        
        // Calculate nearest step
        double lower = MathFloor(currentPrice / step) * step;
        
        // Create levels around current price
        for (int i = -5; i <= 5; i++) {
            double levelPrice = lower + i * step;
            
            if (MathAbs(levelPrice - currentPrice) <= range) {
                SRLevel level;
                level.price = levelPrice;
                level.time = TimeCurrent();
                level.type = SR_TYPE_BOTH; // Round numbers can act as both
                level.source = SR_SOURCE_ROUND_NUMBERS;
                level.strength = SR_STRENGTH_WEAK; // Initially weak until proven
                level.touchCount = 0;
                level.width = m_atrBuffer[0] * 0.2;
                level.active = true;
                level.lastTouchTime = 0;
                
                AddLevel(level);
            }
        }
    }
    
    // Add EMAs as SR levels
    void AddEMALevels() {
        // Get EMA200 value
        double ema200 = m_emaBuffer[0];
        
        // Create EMA level
        SRLevel level;
        level.price = ema200;
        level.time = TimeCurrent();
        level.type = SR_TYPE_BOTH; // EMA can act as both support and resistance
        level.source = SR_SOURCE_EMA200;
        level.strength = SR_STRENGTH_MEDIUM;
        level.touchCount = 0;
        level.width = m_atrBuffer[0] * 0.4; // Wider zone for EMA
        level.active = true;
        level.lastTouchTime = 0;
        
        // Add level
        AddLevel(level);
    }
    
    // Add pivot points as SR levels
    void AddPivotLevels() {
        // Get OHLC data for previous day
        double prevHigh = iHigh(m_symbol, PERIOD_D1, 1);
        double prevLow = iLow(m_symbol, PERIOD_D1, 1);
        double prevClose = iClose(m_symbol, PERIOD_D1, 1);
        
        // Calculate pivot levels
        double pivot = (prevHigh + prevLow + prevClose) / 3;
        
        // Calculate support and resistance levels
        double s1 = (2 * pivot) - prevHigh;
        double s2 = pivot - (prevHigh - prevLow);
        double r1 = (2 * pivot) - prevLow;
        double r2 = pivot + (prevHigh - prevLow);
        
        // Add pivot point
        SRLevel pivotLevel;
        pivotLevel.price = pivot;
        pivotLevel.time = TimeCurrent();
        pivotLevel.type = SR_TYPE_BOTH;
        pivotLevel.source = SR_SOURCE_PIVOT;
        pivotLevel.strength = SR_STRENGTH_MEDIUM;
        pivotLevel.touchCount = 0;
        pivotLevel.width = m_atrBuffer[0] * 0.2;
        pivotLevel.active = true;
        pivotLevel.lastTouchTime = 0;
        
        // Add S1
        SRLevel s1Level;
        s1Level.price = s1;
        s1Level.time = TimeCurrent();
        s1Level.type = SR_TYPE_SUPPORT;
        s1Level.source = SR_SOURCE_PIVOT;
        s1Level.strength = SR_STRENGTH_MEDIUM;
        s1Level.touchCount = 0;
        s1Level.width = m_atrBuffer[0] * 0.2;
        s1Level.active = true;
        s1Level.lastTouchTime = 0;
        
        // Add S2
        SRLevel s2Level;
        s2Level.price = s2;
        s2Level.time = TimeCurrent();
        s2Level.type = SR_TYPE_SUPPORT;
        s2Level.source = SR_SOURCE_PIVOT;
        s2Level.strength = SR_STRENGTH_WEAK;
        s2Level.touchCount = 0;
        s2Level.width = m_atrBuffer[0] * 0.2;
        s2Level.active = true;
        s2Level.lastTouchTime = 0;
        
        // Add R1
        SRLevel r1Level;
        r1Level.price = r1;
        r1Level.time = TimeCurrent();
        r1Level.type = SR_TYPE_RESISTANCE;
        r1Level.source = SR_SOURCE_PIVOT;
        r1Level.strength = SR_STRENGTH_MEDIUM;
        r1Level.touchCount = 0;
        r1Level.width = m_atrBuffer[0] * 0.2;
        r1Level.active = true;
        r1Level.lastTouchTime = 0;
        
        // Add R2
        SRLevel r2Level;
        r2Level.price = r2;
        r2Level.time = TimeCurrent();
        r2Level.type = SR_TYPE_RESISTANCE;
        r2Level.source = SR_SOURCE_PIVOT;
        r2Level.strength = SR_STRENGTH_WEAK;
        r2Level.touchCount = 0;
        r2Level.width = m_atrBuffer[0] * 0.2;
        r2Level.active = true;
        r2Level.lastTouchTime = 0;
        
        // Add all pivot levels
        AddLevel(pivotLevel);
        AddLevel(s1Level);
        AddLevel(s2Level);
        AddLevel(r1Level);
        AddLevel(r2Level);
    }
    
    // Add a new S/R level to the array
    void AddLevel(SRLevel &level) {
        // Check if level already exists or should be merged
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Check if levels are close enough to merge
            if (MathAbs(m_levels[i].price - level.price) <= m_mergeThreshold * m_atrBuffer[0]) {
                // Update existing level
                m_levels[i].touchCount++;
                
                // Use the most recent time
                if (level.time > m_levels[i].time) {
                    m_levels[i].lastTouchTime = level.time;
                }
                
                // Increase strength based on touch count
                if (m_levels[i].touchCount >= 3) {
                    m_levels[i].strength = SR_STRENGTH_STRONG;
                } else if (m_levels[i].touchCount == 2) {
                    m_levels[i].strength = SR_STRENGTH_MEDIUM;
                }
                
                // Combine level types (support, resistance, or both)
                if (m_levels[i].type != level.type && level.type != SR_TYPE_BOTH) {
                    m_levels[i].type = SR_TYPE_BOTH;
                }
                
                // Reactivate if expired
                m_levels[i].active = true;
                
                // If level from more reliable source, update the source
                if (level.source == SR_SOURCE_SWING && m_levels[i].source != SR_SOURCE_SWING) {
                    m_levels[i].source = level.source;
                }
                
                return; // Level merged, no need to add a new one
            }
        }
        
        // If we didn't merge with an existing level, add as new
        int size = ArraySize(m_levels);
        ArrayResize(m_levels, size + 1);
        m_levels[size] = level;
        
        // Keep levels sorted by price
        ArraySort(m_levels);
        
        // If exceeding max levels, remove the weakest one
        if (ArraySize(m_levels) > m_maxLevels) {
            RemoveWeakestLevel();
        }
    }
    
    // Remove the weakest level
    void RemoveWeakestLevel() {
        if (ArraySize(m_levels) == 0) return;
        
        int weakestIdx = 0;
        ENUM_SR_STRENGTH weakestStrength = SR_STRENGTH_STRONG;
        int minTouches = INT_MAX;
        
        // Find the weakest level
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Check strength first
            if (m_levels[i].strength < weakestStrength) {
                weakestIdx = i;
                weakestStrength = m_levels[i].strength;
                minTouches = m_levels[i].touchCount;
            }
            // If same strength, check touch count
            else if (m_levels[i].strength == weakestStrength && m_levels[i].touchCount < minTouches) {
                weakestIdx = i;
                minTouches = m_levels[i].touchCount;
            }
        }
        
        // Remove the weakest level
        for (int i = weakestIdx; i < ArraySize(m_levels) - 1; i++) {
            m_levels[i] = m_levels[i + 1];
        }
        
        ArrayResize(m_levels, ArraySize(m_levels) - 1);
    }
    
    // Clean expired levels and update active status
    void CleanExpiredLevels() {
        datetime currentTime = TimeCurrent();
        int barsTotal = iBars(m_symbol, m_timeframe);
        
        for (int i = ArraySize(m_levels) - 1; i >= 0; i--) {
            // Get time difference in bars
            datetime levelTime = m_levels[i].lastTouchTime > 0 ? 
                                 m_levels[i].lastTouchTime : m_levels[i].time;
                                 
            datetime barTime = iTime(m_symbol, m_timeframe, 0);
            int barsDiff = (int)((barTime - levelTime) / PeriodSeconds(m_timeframe));
            
            // If level is old and not touched, expire it
            if (barsDiff > m_expirationBars && m_levels[i].touchCount <= 1) {
                // Remove this level
                for (int j = i; j < ArraySize(m_levels) - 1; j++) {
                    m_levels[j] = m_levels[j + 1];
                }
                
                ArrayResize(m_levels, ArraySize(m_levels) - 1);
            }
        }
    }
    
    // Check if price has touched a level
    void CheckLevelTouches() {
        // Get recent price data
        double high = iHigh(m_symbol, m_timeframe, 0);
        double low = iLow(m_symbol, m_timeframe, 0);
        double close = iClose(m_symbol, m_timeframe, 0);
        
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Check if price has touched this level
            double upperBound = m_levels[i].price + m_levels[i].width / 2;
            double lowerBound = m_levels[i].price - m_levels[i].width / 2;
            
            // Price has crossed the level
            if ((low <= upperBound && high >= lowerBound) || 
                (close <= upperBound && close >= lowerBound)) {
                // Update level
                m_levels[i].touchCount++;
                m_levels[i].lastTouchTime = TimeCurrent();
                
                // Adjust strength based on touches
                if (m_levels[i].touchCount >= 3) {
                    m_levels[i].strength = SR_STRENGTH_STRONG;
                } else if (m_levels[i].touchCount == 2) {
                    m_levels[i].strength = SR_STRENGTH_MEDIUM;
                }
            }
        }
    }
    
public:
    // Constructor
    CSRManager(string symbol, ENUM_TIMEFRAMES timeframe) {
        m_symbol = symbol;
        m_timeframe = timeframe;
        m_srTimeframe = timeframe; // Default to same timeframe, can be changed
        
        // Set default values
        m_mergeThreshold = 0.5; // Merge levels within 0.5 * ATR
        m_expirationBars = 200; // Expire levels after 200 bars
        m_maxLevels = MAX_SR_LEVELS;
        m_minTouchStrength = 2;
        
        // Initialize data
        m_lastUpdateBar = -1;
        m_lastUpdateTime = 0;
        
        // Initialize indicator handles
        m_emaHandle = INVALID_HANDLE;
        m_atrHandle = INVALID_HANDLE;
    }
    
    // Destructor
    ~CSRManager() {
        // Release indicator handles
        if (m_emaHandle != INVALID_HANDLE) {
            IndicatorRelease(m_emaHandle);
        }
        
        if (m_atrHandle != INVALID_HANDLE) {
            IndicatorRelease(m_atrHandle);
        }
    }
    
    // Initialize SR Manager
    bool Initialize() {
        // Create EMA indicator (EMA 200)
        m_emaHandle = iMA(m_symbol, m_timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
        if (m_emaHandle == INVALID_HANDLE) {
            Print("Failed to create EMA indicator for SR Manager");
            return false;
        }
        
        // Create ATR indicator
        m_atrHandle = iATR(m_symbol, m_timeframe, 14);
        if (m_atrHandle == INVALID_HANDLE) {
            Print("Failed to create ATR indicator for SR Manager");
            return false;
        }
        
        // Initialize buffers
        ArraySetAsSeries(m_emaBuffer, true);
        ArraySetAsSeries(m_atrBuffer, true);
        
        // Update SR levels initially
        if (!Update()) {
            Print("Failed to update SR levels during initialization");
            return false;
        }
        
        return true;
    }
    
    // Update SR levels
    bool Update() {
        // Get current bar index
        int currentBar = iBars(m_symbol, m_timeframe) - 1;
        
        // Skip if already updated this bar
        if (currentBar == m_lastUpdateBar) {
            return true;
        }
        
        // Copy indicator data
        if (CopyBuffer(m_emaHandle, 0, 0, 20, m_emaBuffer) <= 0) {
            Print("Failed to copy EMA data in SR Manager");
            return false;
        }
        
        if (CopyBuffer(m_atrHandle, 0, 0, 20, m_atrBuffer) <= 0) {
            Print("Failed to copy ATR data in SR Manager");
            return false;
        }
        
        // Only do a full recalculation periodically (every 10 bars)
        if (m_lastUpdateBar < 0 || currentBar - m_lastUpdateBar >= 10) {
            // Calculate zigzag for swing points
            CalculateZigZag();
            
            // Detect round number levels
            DetectRoundNumbers();
            
            // Add EMA as a level
            AddEMALevels();
            
            // Add pivot points
            AddPivotLevels();
        }
        
        // Check if price touched any levels
        CheckLevelTouches();
        
        // Clean expired levels
        CleanExpiredLevels();
        
        // Update last update time
        m_lastUpdateBar = currentBar;
        m_lastUpdateTime = TimeCurrent();
        
        return true;
    }
    
    // Set SR detection timeframe
    void SetSRTimeframe(ENUM_TIMEFRAMES timeframe) {
        m_srTimeframe = timeframe;
    }
    
    // Set level merge threshold
    void SetMergeThreshold(double threshold) {
        m_mergeThreshold = threshold;
    }
    
    // Set level expiration in bars
    void SetExpirationBars(double bars) {
        m_expirationBars = bars;
    }
    
    // Set maximum levels to track
    void SetMaxLevels(int max) {
        m_maxLevels = max;
    }
    
    // Get all SR levels
    int GetAllLevels(SRLevel &levels[]) {
        int size = ArraySize(m_levels);
        ArrayResize(levels, size);
        
        // Copy all levels
        for (int i = 0; i < size; i++) {
            levels[i] = m_levels[i];
        }
        
        return size;
    }
    
    // Get active SR levels
    int GetActiveLevels(SRLevel &levels[]) {
        int activeCount = 0;
        
        // Count active levels
        for (int i = 0; i < ArraySize(m_levels); i++) {
            if (m_levels[i].active && m_levels[i].touchCount >= m_minTouchStrength) {
                activeCount++;
            }
        }
        
        // Resize target array
        ArrayResize(levels, activeCount);
        
        // Copy active levels
        int idx = 0;
        for (int i = 0; i < ArraySize(m_levels); i++) {
            if (m_levels[i].active && m_levels[i].touchCount >= m_minTouchStrength) {
                levels[idx++] = m_levels[i];
            }
        }
        
        return activeCount;
    }
    
    // Check if price is near a strong SR level
    bool IsPriceNearStrongLevel(double price, double atrValue) {
        double threshold = atrValue * 0.5; // Check within 0.5 * ATR
        
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Only consider strong levels
            if (m_levels[i].strength == SR_STRENGTH_STRONG && m_levels[i].active) {
                // Check if price is within threshold
                if (MathAbs(price - m_levels[i].price) <= threshold) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    // Get nearest support level below a price
    double GetNearestSupportLevel(double price) {
        double nearest = 0;
        double minDistance = DBL_MAX;
        
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Only consider support or both types
            if ((m_levels[i].type == SR_TYPE_SUPPORT || m_levels[i].type == SR_TYPE_BOTH) && 
                m_levels[i].active) {
                // Level must be below price
                if (m_levels[i].price < price) {
                    double distance = price - m_levels[i].price;
                    if (distance < minDistance) {
                        minDistance = distance;
                        nearest = m_levels[i].price;
                    }
                }
            }
        }
        
        return nearest;
    }
    
    // Get nearest resistance level above a price
    double GetNearestResistanceLevel(double price) {
        double nearest = 0;
        double minDistance = DBL_MAX;
        
        for (int i = 0; i < ArraySize(m_levels); i++) {
            // Only consider resistance or both types
            if ((m_levels[i].type == SR_TYPE_RESISTANCE || m_levels[i].type == SR_TYPE_BOTH) && 
                m_levels[i].active) {
                // Level must be above price
                if (m_levels[i].price > price) {
                    double distance = m_levels[i].price - price;
                    if (distance < minDistance) {
                        minDistance = distance;
                        nearest = m_levels[i].price;
                    }
                }
            }
        }
        
        return nearest;
    }
};