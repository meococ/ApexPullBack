//+------------------------------------------------------------------+
//|                                             SonicR_SR.mqh        |
//|              SonicR PropFirm EA - Support/Resistance Component   |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"

// Support/Resistance class for advanced S/R detection
class CSonicRSR
{
private:
    // Logger
    CLogger* m_logger;
    
    // Structure to store S/R levels
    struct SRLevel {
        double price;           // Price level
        double strength;        // Level strength (0-100)
        string type;            // Level type (pivot, swing, round, ema, etc.)
        datetime timeFrom;      // Start time of the level
        datetime timeTo;        // End time of the level (0 = still active)
        int hits;               // Number of times price reacted at this level
        color levelColor;       // Visual color
    };
    
    // Arrays to store different types of levels
    SRLevel m_dailyLevels[];    // Daily S/R levels
    SRLevel m_h4Levels[];       // H4 S/R levels
    SRLevel m_emaDynamicLevels[]; // EMA dynamic levels
    SRLevel m_roundNumberLevels[]; // Round number levels
    SRLevel m_pivotLevels[];    // Pivot levels
    
    // Combined array of all active levels
    SRLevel m_allLevels[];      // All active levels combined
    
    // Settings
    bool m_useSwingPoints;      // Use swing high/low points
    bool m_usePivotPoints;      // Use pivot points
    bool m_useRoundNumbers;     // Use round numbers
    bool m_useEMALevels;        // Use EMA levels as dynamic S/R
    
    int m_lookbackPeriod;       // Lookback period for historical levels
    double m_levelMergeDistance; // Distance to merge close levels
    double m_reactionDistance;  // Distance to consider a price reaction
    
    // Market-specific parameters
    double m_pointValue;        // Point value for current symbol
    int m_digits;               // Digits for current symbol
    
    // EMA handles
    int m_ema50Handle;          // EMA50 handle
    int m_ema100Handle;         // EMA100 handle
    int m_ema200Handle;         // EMA200 handle
    
    // Helper methods
    void DetectSwingPoints();
    void CalculatePivotPoints();
    void IdentifyRoundNumbers();
    void UpdateEMALevels();
    void MergeLevels();
    void SortLevels();
    void CleanupOldLevels();
    double CalculateReactionStrength(double price, double level, int direction);
    bool IsPriceReacting(double price, double level, int direction);
    
    // For visualization
    void DrawLevels();
    
public:
    // Constructor
    CSonicRSR();
    
    // Destructor
    ~CSonicRSR();
    
    // Initialization and cleanup
    bool Initialize();
    void Cleanup();
    
    // Update S/R levels
    void Update();
    
    // Main methods
    bool ConfirmSignal(int signal);
    double FindNearestSR(double price, int direction);
    int CountNearbyLevels(double price, double maxDistance);
    bool IsPriceAtSR(double price, int direction);
    
    // EMA dynamic S/R methods
    bool IsPriceAtEMA(double price, int direction);
    bool HasEMAReaction(int direction);
    
    // Settings
    void SetUseSwingPoints(bool use) { m_useSwingPoints = use; }
    void SetUsePivotPoints(bool use) { m_usePivotPoints = use; }
    void SetUseRoundNumbers(bool use) { m_useRoundNumbers = use; }
    void SetUseEMALevels(bool use) { m_useEMALevels = use; }
    
    void SetLookbackPeriod(int period) { m_lookbackPeriod = period; }
    void SetLevelMergeDistance(double distance) { m_levelMergeDistance = distance; }
    void SetReactionDistance(double distance) { m_reactionDistance = distance; }
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSonicRSR::CSonicRSR()
{
    m_logger = NULL;
    
    // Default settings
    m_useSwingPoints = true;
    m_usePivotPoints = true;
    m_useRoundNumbers = true;
    m_useEMALevels = true;
    
    m_lookbackPeriod = 50;
    m_levelMergeDistance = 0.0;  // Will be set in Initialize
    m_reactionDistance = 0.0;    // Will be set in Initialize
    
    // Initialize handles
    m_ema50Handle = INVALID_HANDLE;
    m_ema100Handle = INVALID_HANDLE;
    m_ema200Handle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSonicRSR::~CSonicRSR()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CSonicRSR::Initialize()
{
    // Get symbol info
    m_pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    m_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    
    // Set distances based on point value and digits
    if(m_digits == 5 || m_digits == 3) {
        // Forex 5 digit broker or 3 digit JPY pairs
        m_levelMergeDistance = 20 * m_pointValue;  // 2 pips
        m_reactionDistance = 10 * m_pointValue;    // 1 pip
    }
    else if(m_digits == 2) {
        // Indices or stocks with 2 digits
        m_levelMergeDistance = 2 * m_pointValue;
        m_reactionDistance = 1 * m_pointValue;
    }
    else if(m_digits == 1) {
        // Some commodities or indices
        m_levelMergeDistance = 0.2 * m_pointValue;
        m_reactionDistance = 0.1 * m_pointValue;
    }
    else {
        // Default (4 digits for Forex)
        m_levelMergeDistance = 10 * m_pointValue;  // 1 pip
        m_reactionDistance = 5 * m_pointValue;     // 0.5 pip
    }
    
    // Create EMA indicators
    if(m_useEMALevels) {
        m_ema50Handle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
        m_ema100Handle = iMA(_Symbol, PERIOD_CURRENT, 100, 0, MODE_EMA, PRICE_CLOSE);
        m_ema200Handle = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
        
        if(m_ema50Handle == INVALID_HANDLE || 
           m_ema100Handle == INVALID_HANDLE || 
           m_ema200Handle == INVALID_HANDLE) {
            if(m_logger) m_logger.Error("Failed to create EMA indicators");
            return false;
        }
    }
    
    // Initial detection
    Update();
    
    if(m_logger) m_logger.Info("SonicR SR module initialized");
    return true;
}

//+------------------------------------------------------------------+
//| Cleanup                                                          |
//+------------------------------------------------------------------+
void CSonicRSR::Cleanup()
{
    // Release indicator handles
    if(m_ema50Handle != INVALID_HANDLE) {
        IndicatorRelease(m_ema50Handle);
        m_ema50Handle = INVALID_HANDLE;
    }
    
    if(m_ema100Handle != INVALID_HANDLE) {
        IndicatorRelease(m_ema100Handle);
        m_ema100Handle = INVALID_HANDLE;
    }
    
    if(m_ema200Handle != INVALID_HANDLE) {
        IndicatorRelease(m_ema200Handle);
        m_ema200Handle = INVALID_HANDLE;
    }
    
    // Remove visual objects
    for(int i = ObjectsTotal(0, 0, OBJ_HLINE) - 1; i >= 0; i--) {
        string name = ObjectName(0, i, 0, OBJ_HLINE);
        if(StringFind(name, "SonicR_SR_") >= 0) {
            ObjectDelete(0, name);
        }
    }
}

//+------------------------------------------------------------------+
//| Update S/R levels                                                |
//+------------------------------------------------------------------+
void CSonicRSR::Update()
{
    // Update each type of S/R levels
    if(m_useSwingPoints) DetectSwingPoints();
    if(m_usePivotPoints) CalculatePivotPoints();
    if(m_useRoundNumbers) IdentifyRoundNumbers();
    if(m_useEMALevels) UpdateEMALevels();
    
    // Process levels
    MergeLevels();
    SortLevels();
    CleanupOldLevels();
    
    // Draw levels if in visual mode
    DrawLevels();
}

//+------------------------------------------------------------------+
//| Detect swing points                                              |
//+------------------------------------------------------------------+
void CSonicRSR::DetectSwingPoints()
{
    // Clear current swing levels
    ArrayResize(m_dailyLevels, 0);
    ArrayResize(m_h4Levels, 0);
    
    // Get price data
    MqlRates dailyRates[];
    MqlRates h4Rates[];
    
    ArraySetAsSeries(dailyRates, true);
    ArraySetAsSeries(h4Rates, true);
    
    int copied = CopyRates(_Symbol, PERIOD_D1, 0, m_lookbackPeriod, dailyRates);
    if(copied <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy daily rates for SR detection");
        return;
    }
    
    copied = CopyRates(_Symbol, PERIOD_H4, 0, m_lookbackPeriod * 6, h4Rates);
    if(copied <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy H4 rates for SR detection");
        return;
    }
    
    // Find swing highs/lows on daily chart
    for(int i = 2; i < m_lookbackPeriod - 2; i++) {
        // Swing high
        if(dailyRates[i].high > dailyRates[i+1].high && 
           dailyRates[i].high > dailyRates[i+2].high &&
           dailyRates[i].high > dailyRates[i-1].high && 
           dailyRates[i].high > dailyRates[i-2].high) {
            
            SRLevel level;
            level.price = dailyRates[i].high;
            level.strength = 80.0;  // Base strength
            level.type = "swing_high_d1";
            level.timeFrom = dailyRates[i].time;
            level.timeTo = 0;  // Still active
            level.hits = 1;
            level.levelColor = clrRed;
            
            int size = ArraySize(m_dailyLevels);
            ArrayResize(m_dailyLevels, size + 1);
            m_dailyLevels[size] = level;
        }
        
        // Swing low
        if(dailyRates[i].low < dailyRates[i+1].low && 
           dailyRates[i].low < dailyRates[i+2].low &&
           dailyRates[i].low < dailyRates[i-1].low && 
           dailyRates[i].low < dailyRates[i-2].low) {
            
            SRLevel level;
            level.price = dailyRates[i].low;
            level.strength = 80.0;  // Base strength
            level.type = "swing_low_d1";
            level.timeFrom = dailyRates[i].time;
            level.timeTo = 0;  // Still active
            level.hits = 1;
            level.levelColor = clrGreen;
            
            int size = ArraySize(m_dailyLevels);
            ArrayResize(m_dailyLevels, size + 1);
            m_dailyLevels[size] = level;
        }
    }
    
    // Find swing highs/lows on H4 chart
    for(int i = 2; i < ArraySize(h4Rates) - 2; i++) {
        // Swing high
        if(h4Rates[i].high > h4Rates[i+1].high && 
           h4Rates[i].high > h4Rates[i+2].high &&
           h4Rates[i].high > h4Rates[i-1].high && 
           h4Rates[i].high > h4Rates[i-2].high) {
            
            SRLevel level;
            level.price = h4Rates[i].high;
            level.strength = 60.0;  // Base strength (lower than daily)
            level.type = "swing_high_h4";
            level.timeFrom = h4Rates[i].time;
            level.timeTo = 0;  // Still active
            level.hits = 1;
            level.levelColor = clrCoral;
            
            int size = ArraySize(m_h4Levels);
            ArrayResize(m_h4Levels, size + 1);
            m_h4Levels[size] = level;
        }
        
        // Swing low
        if(h4Rates[i].low < h4Rates[i+1].low && 
           h4Rates[i].low < h4Rates[i+2].low &&
           h4Rates[i].low < h4Rates[i-1].low && 
           h4Rates[i].low < h4Rates[i-2].low) {
            
            SRLevel level;
            level.price = h4Rates[i].low;
            level.strength = 60.0;  // Base strength (lower than daily)
            level.type = "swing_low_h4";
            level.timeFrom = h4Rates[i].time;
            level.timeTo = 0;  // Still active
            level.hits = 1;
            level.levelColor = clrLimeGreen;
            
            int size = ArraySize(m_h4Levels);
            ArrayResize(m_h4Levels, size + 1);
            m_h4Levels[size] = level;
        }
    }
    
    if(m_logger) {
        m_logger.Debug("Detected " + IntegerToString(ArraySize(m_dailyLevels)) + 
                     " Daily swing levels and " + IntegerToString(ArraySize(m_h4Levels)) + 
                     " H4 swing levels");
    }
}

//+------------------------------------------------------------------+
//| Calculate Pivot Points                                           |
//+------------------------------------------------------------------+
void CSonicRSR::CalculatePivotPoints()
{
    // Clear current pivot levels
    ArrayResize(m_pivotLevels, 0);
    
    // Calculate weekly pivot points
    MqlRates weeklyRates[];
    ArraySetAsSeries(weeklyRates, true);
    
    int copied = CopyRates(_Symbol, PERIOD_W1, 0, 2, weeklyRates);
    if(copied <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy weekly rates for pivot calculation");
        return;
    }
    
    // Previous week's data
    double prevHigh = weeklyRates[1].high;
    double prevLow = weeklyRates[1].low;
    double prevClose = weeklyRates[1].close;
    
    // Calculate classic pivot points
    double pp = (prevHigh + prevLow + prevClose) / 3.0;  // Pivot Point
    
    double r1 = (2.0 * pp) - prevLow;  // Resistance 1
    double s1 = (2.0 * pp) - prevHigh; // Support 1
    
    double r2 = pp + (prevHigh - prevLow); // Resistance 2
    double s2 = pp - (prevHigh - prevLow); // Support 2
    
    double r3 = prevHigh + 2.0 * (pp - prevLow); // Resistance 3
    double s3 = prevLow - 2.0 * (prevHigh - pp); // Support 3
    
    // Calculate Fibonacci pivot points
    double fib_r1 = pp + 0.382 * (prevHigh - prevLow);
    double fib_r2 = pp + 0.618 * (prevHigh - prevLow);
    double fib_r3 = pp + 1.000 * (prevHigh - prevLow);
    
    double fib_s1 = pp - 0.382 * (prevHigh - prevLow);
    double fib_s2 = pp - 0.618 * (prevHigh - prevLow);
    double fib_s3 = pp - 1.000 * (prevHigh - prevLow);
    
    // Add pivot points to levels array
    int size;
    
    // Pivot Point
    SRLevel ppLevel;
    ppLevel.price = pp;
    ppLevel.strength = 90.0;  // Strong level
    ppLevel.type = "pivot_pp";
    ppLevel.timeFrom = TimeCurrent();
    ppLevel.timeTo = 0;
    ppLevel.hits = 0;
    ppLevel.levelColor = clrYellow;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = ppLevel;
    
    // R1, R2, R3
    SRLevel r1Level;
    r1Level.price = r1;
    r1Level.strength = 80.0;
    r1Level.type = "pivot_r1";
    r1Level.timeFrom = TimeCurrent();
    r1Level.timeTo = 0;
    r1Level.hits = 0;
    r1Level.levelColor = clrRed;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = r1Level;
    
    SRLevel r2Level;
    r2Level.price = r2;
    r2Level.strength = 75.0;
    r2Level.type = "pivot_r2";
    r2Level.timeFrom = TimeCurrent();
    r2Level.timeTo = 0;
    r2Level.hits = 0;
    r2Level.levelColor = clrRed;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = r2Level;
    
    SRLevel r3Level;
    r3Level.price = r3;
    r3Level.strength = 70.0;
    r3Level.type = "pivot_r3";
    r3Level.timeFrom = TimeCurrent();
    r3Level.timeTo = 0;
    r3Level.hits = 0;
    r3Level.levelColor = clrRed;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = r3Level;
    
    // S1, S2, S3
    SRLevel s1Level;
    s1Level.price = s1;
    s1Level.strength = 80.0;
    s1Level.type = "pivot_s1";
    s1Level.timeFrom = TimeCurrent();
    s1Level.timeTo = 0;
    s1Level.hits = 0;
    s1Level.levelColor = clrGreen;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = s1Level;
    
    SRLevel s2Level;
    s2Level.price = s2;
    s2Level.strength = 75.0;
    s2Level.type = "pivot_s2";
    s2Level.timeFrom = TimeCurrent();
    s2Level.timeTo = 0;
    s2Level.hits = 0;
    s2Level.levelColor = clrGreen;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = s2Level;
    
    SRLevel s3Level;
    s3Level.price = s3;
    s3Level.strength = 70.0;
    s3Level.type = "pivot_s3";
    s3Level.timeFrom = TimeCurrent();
    s3Level.timeTo = 0;
    s3Level.hits = 0;
    s3Level.levelColor = clrGreen;
    
    size = ArraySize(m_pivotLevels);
    ArrayResize(m_pivotLevels, size + 1);
    m_pivotLevels[size] = s3Level;
    
    // Add Fibonacci levels
    // (Code for adding Fibonacci pivot levels would be similar)
    
    if(m_logger) {
        m_logger.Debug("Calculated " + IntegerToString(ArraySize(m_pivotLevels)) + 
                     " pivot levels");
    }
}

//+------------------------------------------------------------------+
//| Identify Round Numbers                                           |
//+------------------------------------------------------------------+
void CSonicRSR::IdentifyRoundNumbers()
{
    // Clear current round number levels
    ArrayResize(m_roundNumberLevels, 0);
    
    // Get current price range
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double rangeTop = currentPrice * 1.05;  // 5% above current price
    double rangeBottom = currentPrice * 0.95;  // 5% below current price
    
    // Round to nearest whole number
    double baseValue = 1.0;
    if(m_digits == 5) {  // 5 digit broker (e.g., EURUSD 1.12345)
        baseValue = 0.1;  // For major whole numbers (1.1000, 1.2000)
    }
    else if(m_digits == 3) {  // 3 digit broker (e.g., USDJPY 123.45)
        baseValue = 1.0;  // For major whole numbers (110.00, 120.00)
    }
    else if(m_digits == 2) {  // 2 digit prices
        baseValue = 1.0;
    }
    else if(m_digits == 1) {
        baseValue = 10.0;
    }
    else {  // Default (4 digits)
        baseValue = 0.1;
    }
    
    // Step for half and quarter rounds
    double halfStep = baseValue / 2.0;
    double quarterStep = baseValue / 4.0;
    
    // Get the range bottom rounded to nearest base value
    double start = MathFloor(rangeBottom / baseValue) * baseValue;
    
    // Generate round number levels
    for(double price = start; price <= rangeTop; price += quarterStep) {
        bool isWholeNumber = MathAbs(MathMod(price, baseValue)) < 0.0000001;
        bool isHalfNumber = MathAbs(MathMod(price, halfStep)) < 0.0000001 && !isWholeNumber;
        bool isQuarterNumber = !isWholeNumber && !isHalfNumber;
        
        SRLevel level;
        level.price = price;
        level.timeFrom = TimeCurrent();
        level.timeTo = 0;
        level.hits = 0;
        
        if(isWholeNumber) {
            level.strength = 85.0;  // Strongest round numbers
            level.type = "round_whole";
            level.levelColor = clrDarkOrange;
        }
        else if(isHalfNumber) {
            level.strength = 75.0;  // Half numbers
            level.type = "round_half";
            level.levelColor = clrOrange;
        }
        else {
            level.strength = 65.0;  // Quarter numbers
            level.type = "round_quarter";
            level.levelColor = clrGold;
        }
        
        int size = ArraySize(m_roundNumberLevels);
        ArrayResize(m_roundNumberLevels, size + 1);
        m_roundNumberLevels[size] = level;
    }
    
    if(m_logger) {
        m_logger.Debug("Identified " + IntegerToString(ArraySize(m_roundNumberLevels)) + 
                     " round number levels");
    }
}

//+------------------------------------------------------------------+
//| Update EMA Levels                                                |
//+------------------------------------------------------------------+
void CSonicRSR::UpdateEMALevels()
{
    // Clear current EMA levels
    ArrayResize(m_emaDynamicLevels, 0);
    
    if(!m_useEMALevels) return;
    
    // Get EMA values
    double ema50[], ema100[], ema200[];
    ArraySetAsSeries(ema50, true);
    ArraySetAsSeries(ema100, true);
    ArraySetAsSeries(ema200, true);
    
    if(CopyBuffer(m_ema50Handle, 0, 0, 1, ema50) <= 0 ||
       CopyBuffer(m_ema100Handle, 0, 0, 1, ema100) <= 0 ||
       CopyBuffer(m_ema200Handle, 0, 0, 1, ema200) <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy EMA values");
        return;
    }
    
    // Add EMA50 level
    SRLevel ema50Level;
    ema50Level.price = ema50[0];
    ema50Level.strength = 70.0;
    ema50Level.type = "ema_50";
    ema50Level.timeFrom = TimeCurrent();
    ema50Level.timeTo = 0;
    ema50Level.hits = 0;
    ema50Level.levelColor = clrMagenta;
    
    int size = ArraySize(m_emaDynamicLevels);
    ArrayResize(m_emaDynamicLevels, size + 1);
    m_emaDynamicLevels[size] = ema50Level;
    
    // Add EMA100 level
    SRLevel ema100Level;
    ema100Level.price = ema100[0];
    ema100Level.strength = 80.0;
    ema100Level.type = "ema_100";
    ema100Level.timeFrom = TimeCurrent();
    ema100Level.timeTo = 0;
    ema100Level.hits = 0;
    ema100Level.levelColor = clrBlue;
    
    size = ArraySize(m_emaDynamicLevels);
    ArrayResize(m_emaDynamicLevels, size + 1);
    m_emaDynamicLevels[size] = ema100Level;
    
    // Add EMA200 level
    SRLevel ema200Level;
    ema200Level.price = ema200[0];
    ema200Level.strength = 90.0;  // EMA200 is strongest
    ema200Level.type = "ema_200";
    ema200Level.timeFrom = TimeCurrent();
    ema200Level.timeTo = 0;
    ema200Level.hits = 0;
    ema200Level.levelColor = clrDarkBlue;
    
    size = ArraySize(m_emaDynamicLevels);
    ArrayResize(m_emaDynamicLevels, size + 1);
    m_emaDynamicLevels[size] = ema200Level;
    
    if(m_logger) {
        m_logger.Debug("Updated " + IntegerToString(ArraySize(m_emaDynamicLevels)) + 
                     " EMA dynamic levels");
    }
}

//+------------------------------------------------------------------+
//| Merge close levels                                               |
//+------------------------------------------------------------------+
void CSonicRSR::MergeLevels()
{
    // Combine all levels into one array
    int totalLevels = ArraySize(m_dailyLevels) + 
                     ArraySize(m_h4Levels) + 
                     ArraySize(m_pivotLevels) + 
                     ArraySize(m_roundNumberLevels) + 
                     ArraySize(m_emaDynamicLevels);
    
    ArrayResize(m_allLevels, totalLevels);
    
    int index = 0;
    
    // Copy daily levels
    for(int i = 0; i < ArraySize(m_dailyLevels); i++) {
        m_allLevels[index++] = m_dailyLevels[i];
    }
    
    // Copy H4 levels
    for(int i = 0; i < ArraySize(m_h4Levels); i++) {
        m_allLevels[index++] = m_h4Levels[i];
    }
    
    // Copy pivot levels
    for(int i = 0; i < ArraySize(m_pivotLevels); i++) {
        m_allLevels[index++] = m_pivotLevels[i];
    }
    
    // Copy round number levels
    for(int i = 0; i < ArraySize(m_roundNumberLevels); i++) {
        m_allLevels[index++] = m_roundNumberLevels[i];
    }
    
    // Copy EMA dynamic levels
    for(int i = 0; i < ArraySize(m_emaDynamicLevels); i++) {
        m_allLevels[index++] = m_emaDynamicLevels[i];
    }
    
    // Sort by price for easier merging
    SortLevels();
    
    // Merge levels that are close to each other
    for(int i = 0; i < ArraySize(m_allLevels) - 1; i++) {
        if(m_allLevels[i].price == 0) continue;  // Skip already merged levels
        
        for(int j = i + 1; j < ArraySize(m_allLevels); j++) {
            if(m_allLevels[j].price == 0) continue;  // Skip already merged levels
            
            // Check if levels are close enough to merge
            if(MathAbs(m_allLevels[i].price - m_allLevels[j].price) <= m_levelMergeDistance) {
                // Combine strength (use stronger level as base)
                if(m_allLevels[i].strength <= m_allLevels[j].strength) {
                    // j is stronger or equal, use j's price
                    m_allLevels[i].price = m_allLevels[j].price;
                    m_allLevels[i].strength = MathMax(m_allLevels[i].strength, m_allLevels[j].strength) + 5.0;
                    m_allLevels[i].type += "+" + m_allLevels[j].type;  // Combined type
                    m_allLevels[i].hits += m_allLevels[j].hits;
                }
                else {
                    // i is stronger, keep i's price
                    m_allLevels[i].strength = MathMax(m_allLevels[i].strength, m_allLevels[j].strength) + 5.0;
                    m_allLevels[i].type += "+" + m_allLevels[j].type;  // Combined type
                    m_allLevels[i].hits += m_allLevels[j].hits;
                }
                
                // Mark j as merged (to skip later)
                m_allLevels[j].price = 0;
            }
        }
    }
    
    // Remove merged levels
    int validLevels = 0;
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        if(m_allLevels[i].price > 0) {
            validLevels++;
        }
    }
    
    SRLevel tempLevels[];
    ArrayResize(tempLevels, validLevels);
    
    int validIndex = 0;
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        if(m_allLevels[i].price > 0) {
            tempLevels[validIndex++] = m_allLevels[i];
        }
    }
    
    // Replace all levels with merged levels
    ArrayFree(m_allLevels);
    ArrayResize(m_allLevels, validLevels);
    
    for(int i = 0; i < validLevels; i++) {
        m_allLevels[i] = tempLevels[i];
    }
    
    if(m_logger) {
        m_logger.Debug("Merged levels: Total=" + IntegerToString(totalLevels) + 
                     ", After merge=" + IntegerToString(validLevels));
    }
}

//+------------------------------------------------------------------+
//| Sort levels by price                                             |
//+------------------------------------------------------------------+
void CSonicRSR::SortLevels()
{
    int size = ArraySize(m_allLevels);
    
    // Simple bubble sort by price
    for(int i = 0; i < size - 1; i++) {
        for(int j = 0; j < size - i - 1; j++) {
            if(m_allLevels[j].price > m_allLevels[j + 1].price) {
                // Swap
                SRLevel temp = m_allLevels[j];
                m_allLevels[j] = m_allLevels[j + 1];
                m_allLevels[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Clean up old levels                                              |
//+------------------------------------------------------------------+
void CSonicRSR::CleanupOldLevels()
{
    // Clean up is not necessary for most S/R levels as they're recalculated
    // But we could remove old swing points that are no longer relevant
}

//+------------------------------------------------------------------+
//| Draw levels on chart                                             |
//+------------------------------------------------------------------+
void CSonicRSR::DrawLevels()
{
    // Delete old lines
    for(int i = ObjectsTotal(0, 0, OBJ_HLINE) - 1; i >= 0; i--) {
        string name = ObjectName(0, i, 0, OBJ_HLINE);
        if(StringFind(name, "SonicR_SR_") >= 0) {
            ObjectDelete(0, name);
        }
    }
    
    // Draw all active levels
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        string name = "SonicR_SR_" + IntegerToString(i) + "_" + m_allLevels[i].type;
        ObjectCreate(0, name, OBJ_HLINE, 0, 0, m_allLevels[i].price);
        ObjectSetInteger(0, name, OBJPROP_COLOR, m_allLevels[i].levelColor);
        ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
        ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, name, OBJPROP_BACK, true);
        
        // Add label showing strength
        string labelName = "SonicR_SR_Label_" + IntegerToString(i);
        ObjectCreate(0, labelName, OBJ_TEXT, 0, TimeCurrent(), m_allLevels[i].price);
        ObjectSetString(0, labelName, OBJPROP_TEXT, 
                       StringSubstr(m_allLevels[i].type, 0, 10) + " (" + 
                       DoubleToString(m_allLevels[i].strength, 0) + ")");
        ObjectSetInteger(0, labelName, OBJPROP_COLOR, m_allLevels[i].levelColor);
        ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
    }
}

//+------------------------------------------------------------------+
//| Confirm if signal is valid based on SR levels                     |
//+------------------------------------------------------------------+
bool CSonicRSR::ConfirmSignal(int signal)
{
    if(signal == 0) return false;
    
    // Lấy giá hiện tại
    double currentPrice = signal > 0 ? 
                        SymbolInfoDouble(_Symbol, SYMBOL_ASK) : 
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    // Kiểm tra giá có ở gần S/R hay không
    bool atSR = IsPriceAtSR(currentPrice, signal);
    
    // Kiểm tra giá có ở gần EMA
    bool atEMA = IsPriceAtEMA(currentPrice, signal);
    
    // Kiểm tra phản ứng giá tại EMA
    bool emaReaction = HasEMAReaction(signal);
    
    // Xác nhận nếu thỏa mãn một trong các điều kiện
    bool isConfirmed = atSR || atEMA || emaReaction;
    
    if(m_logger) {
        if(isConfirmed) {
            m_logger.Info("Tín hiệu được xác nhận bởi S/R: " + 
                        (atSR ? "Tại S/R" : "") + 
                        (atEMA ? " Tại EMA" : "") + 
                        (emaReaction ? " Phản ứng tại EMA" : ""));
        }
        else {
            m_logger.Debug("Tín hiệu không được xác nhận bởi S/R");
        }
    }
    
    return isConfirmed;
}

//+------------------------------------------------------------------+
//| Find nearest S/R level to price                                  |
//+------------------------------------------------------------------+
double CSonicRSR::FindNearestSR(double price, int direction)
{
    double nearestLevel = 0;
    double minDistance = DBL_MAX;
    
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        // For buy signals, look for support below current price
        if(direction > 0 && m_allLevels[i].price < price) {
            double distance = price - m_allLevels[i].price;
            if(distance < minDistance) {
                minDistance = distance;
                nearestLevel = m_allLevels[i].price;
            }
        }
        // For sell signals, look for resistance above current price
        else if(direction < 0 && m_allLevels[i].price > price) {
            double distance = m_allLevels[i].price - price;
            if(distance < minDistance) {
                minDistance = distance;
                nearestLevel = m_allLevels[i].price;
            }
        }
    }
    
    return nearestLevel;
}

//+------------------------------------------------------------------+
//| Count nearby S/R levels                                          |
//+------------------------------------------------------------------+
int CSonicRSR::CountNearbyLevels(double price, double maxDistance)
{
    int count = 0;
    
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        if(MathAbs(m_allLevels[i].price - price) <= maxDistance) {
            count++;
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| Check if price is at a significant S/R level                     |
//+------------------------------------------------------------------+
bool CSonicRSR::IsPriceAtSR(double price, int direction)
{
    double minStrength = 70.0;  // Minimum strength to consider
    
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        if(m_allLevels[i].strength < minStrength) continue;
        
        // Check if price is within reaction distance of the level
        if(MathAbs(price - m_allLevels[i].price) <= m_reactionDistance) {
            // For buy signals, price should be at support
            if(direction > 0 && price > m_allLevels[i].price) {
                return true;
            }
            // For sell signals, price should be at resistance
            else if(direction < 0 && price < m_allLevels[i].price) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price is near an EMA level                              |
//+------------------------------------------------------------------+
bool CSonicRSR::IsPriceAtEMA(double price, int direction)
{
    if(!m_useEMALevels) return false;
    
    // Lấy giá trị EMA200 trên M15
    double ema200M15[];
    ArraySetAsSeries(ema200M15, true);
    
    int ema200M15Handle = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);
    if(ema200M15Handle == INVALID_HANDLE) return false;
    
    if(CopyBuffer(ema200M15Handle, 0, 0, 1, ema200M15) <= 0) {
        IndicatorRelease(ema200M15Handle);
        return false;
    }
    
    IndicatorRelease(ema200M15Handle);
    
    // Kiểm tra nếu giá gần EMA200
    if(MathAbs(price - ema200M15[0]) <= m_reactionDistance * 2) {
        // Buy signal: giá phải ở trên EMA200
        if(direction > 0 && price > ema200M15[0]) {
            return true;
        }
        // Sell signal: giá phải ở dưới EMA200
        else if(direction < 0 && price < ema200M15[0]) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if price has recently reacted at an EMA level              |
//+------------------------------------------------------------------+
bool CSonicRSR::HasEMAReaction(int direction)
{
    // Lấy dữ liệu giá gần đây
    double close[], low[], high[], open[];
    
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(open, true);
    
    if(CopyClose(_Symbol, PERIOD_M15, 0, 10, close) <= 0 ||
       CopyLow(_Symbol, PERIOD_M15, 0, 10, low) <= 0 ||
       CopyHigh(_Symbol, PERIOD_M15, 0, 10, high) <= 0 ||
       CopyOpen(_Symbol, PERIOD_M15, 0, 10, open) <= 0) {
        return false;
    }
    
    // Lấy giá trị EMA200 M15
    double ema200M15[];
    ArraySetAsSeries(ema200M15, true);
    
    int ema200M15Handle = iMA(_Symbol, PERIOD_M15, 200, 0, MODE_EMA, PRICE_CLOSE);
    if(ema200M15Handle == INVALID_HANDLE) return false;
    
    if(CopyBuffer(ema200M15Handle, 0, 0, 10, ema200M15) <= 0) {
        IndicatorRelease(ema200M15Handle);
        return false;
    }
    
    IndicatorRelease(ema200M15Handle);
    
    // Kiểm tra phản ứng tại EMA200
    for(int i = 0; i < 5; i++) {
        if(direction > 0) {  // Buy signal
            // Kiểm tra nếu low chạm EMA200 và sau đó giá đóng cửa trên EMA200
            if(MathAbs(low[i] - ema200M15[i]) <= m_reactionDistance * 3 &&
               close[i] > ema200M15[i] && close[i] > open[i]) {
                return true;
            }
        }
        else {  // Sell signal
            // Kiểm tra nếu high chạm EMA200 và sau đó giá đóng cửa dưới EMA200
            if(MathAbs(high[i] - ema200M15[i]) <= m_reactionDistance * 3 &&
               close[i] < ema200M15[i] && close[i] < open[i]) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CSonicRSR::GetStatusText() const
{
    string status = "Support/Resistance Status:\n";
    
    double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    
    status += "Total Levels: " + IntegerToString(ArraySize(m_allLevels)) + "\n";
    status += "Daily Levels: " + IntegerToString(ArraySize(m_dailyLevels)) + "\n";
    status += "H4 Levels: " + IntegerToString(ArraySize(m_h4Levels)) + "\n";
    status += "Pivot Levels: " + IntegerToString(ArraySize(m_pivotLevels)) + "\n";
    status += "Round Number Levels: " + IntegerToString(ArraySize(m_roundNumberLevels)) + "\n";
    status += "EMA Levels: " + IntegerToString(ArraySize(m_emaDynamicLevels)) + "\n";
    
    int nearbyLevels = CountNearbyLevels(currentPrice, m_reactionDistance * 5);
    status += "Nearby Levels: " + IntegerToString(nearbyLevels) + "\n";
    
    // Find nearest levels
    double nearestAbove = 0, nearestBelow = 0;
    double distanceAbove = DBL_MAX, distanceBelow = DBL_MAX;
    
    for(int i = 0; i < ArraySize(m_allLevels); i++) {
        // Find level above
        if(m_allLevels[i].price > currentPrice) {
            double distance = m_allLevels[i].price - currentPrice;
            if(distance < distanceAbove) {
                distanceAbove = distance;
                nearestAbove = m_allLevels[i].price;
            }
        }
        // Find level below
        else if(m_allLevels[i].price < currentPrice) {
            double distance = currentPrice - m_allLevels[i].price;
            if(distance < distanceBelow) {
                distanceBelow = distance;
                nearestBelow = m_allLevels[i].price;
            }
        }
    }
    
    status += "Nearest Above: " + DoubleToString(nearestAbove, _Digits) + 
             " (" + DoubleToString(distanceAbove / _Point, 1) + " pts)\n";
             
    status += "Nearest Below: " + DoubleToString(nearestBelow, _Digits) + 
             " (" + DoubleToString(distanceBelow / _Point, 1) + " pts)\n";
    
    return status;
}