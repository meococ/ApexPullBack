//+------------------------------------------------------------------+
//|                                            SonicR_PVSRA.mqh      |
//|                SonicR PropFirm EA - PVSRA Analysis Component     |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"

//+------------------------------------------------------------------+
//| PVSRA (Price Volume Spread Relationship Analysis) Class          |
//+------------------------------------------------------------------+
class CPVSRA
{
private:
    // Logger
    CLogger* m_logger;
    
    // Settings
    int m_volumeAvgPeriod;       // Period for volume average calculation
    int m_spreadAvgPeriod;       // Period for spread average calculation
    int m_confirmationBars;      // Number of bars for confirmation
    double m_volumeThreshold;    // Threshold for high volume (multiple of average)
    double m_spreadThreshold;    // Threshold for narrow spread (multiple of average)
    
    // Buffers
    double m_avgVolume[];        // Average volume buffer
    double m_avgSpread[];        // Average spread buffer
    double m_bullPower[];        // Bullish power buffer
    double m_bearPower[];        // Bearish power buffer
    int m_volumeType[];          // Volume classification (1=high, 0=normal, -1=low)
    int m_spreadType[];          // Spread classification (1=wide, 0=normal, -1=narrow)
    int m_barType[];             // Bar classification (1=bullish, -1=bearish, 0=neutral)
    
    // Data buffers
    double m_volume[];           // Volume data
    double m_spread[];           // Spread data
    double m_close[];            // Close price
    double m_open[];             // Open price
    double m_high[];             // High price
    double m_low[];              // Low price
    
    // Handles
    int m_volumeHandle;          // Volume indicator handle
    
    // Helper methods
    bool LoadData();
    void CalculateAverages();
    void ClassifyBars();
    void AnalyzePVSR();
    
public:
    // Constructor
    CPVSRA();
    
    // Destructor
    ~CPVSRA();
    
    // Main methods
    bool Initialize();
    void Update();
    void Cleanup();
    
    // Analysis methods
    bool IsBullishConfirmation();
    bool IsBearishConfirmation();
    bool IsBullishDivergence();
    bool IsBearishDivergence();
    int GetBarType(int shift = 0) const;
    double GetBullPower(int shift = 0) const;
    double GetBearPower(int shift = 0) const;
    
    // Settings
    void SetParameters(int volumeAvgPeriod, int spreadAvgPeriod, int confirmationBars);
    void SetThresholds(double volumeThreshold, double spreadThreshold);
    
    // Dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPVSRA::CPVSRA()
{
    m_logger = NULL;
    
    // Default settings
    m_volumeAvgPeriod = 20;
    m_spreadAvgPeriod = 10;
    m_confirmationBars = 3;
    m_volumeThreshold = 1.5;     // 150% of average volume
    m_spreadThreshold = 0.7;     // 70% of average spread (narrow)
    
    // Initialize handles
    m_volumeHandle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPVSRA::~CPVSRA()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Initialize PVSRA                                                 |
//+------------------------------------------------------------------+
bool CPVSRA::Initialize()
{
    // Get volume indicator handle
    m_volumeHandle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    
    if(m_volumeHandle == INVALID_HANDLE) {
        if(m_logger) m_logger.Error("Failed to get Volume indicator handle");
        return false;
    }
    
    // Allocate buffers
    ArrayResize(m_avgVolume, 100);
    ArrayResize(m_avgSpread, 100);
    ArrayResize(m_bullPower, 100);
    ArrayResize(m_bearPower, 100);
    ArrayResize(m_volumeType, 100);
    ArrayResize(m_spreadType, 100);
    ArrayResize(m_barType, 100);
    
    ArrayResize(m_volume, 100);
    ArrayResize(m_spread, 100);
    ArrayResize(m_close, 100);
    ArrayResize(m_open, 100);
    ArrayResize(m_high, 100);
    ArrayResize(m_low, 100);
    
    // Set array as series
    ArraySetAsSeries(m_avgVolume, true);
    ArraySetAsSeries(m_avgSpread, true);
    ArraySetAsSeries(m_bullPower, true);
    ArraySetAsSeries(m_bearPower, true);
    ArraySetAsSeries(m_volumeType, true);
    ArraySetAsSeries(m_spreadType, true);
    ArraySetAsSeries(m_barType, true);
    
    ArraySetAsSeries(m_volume, true);
    ArraySetAsSeries(m_spread, true);
    ArraySetAsSeries(m_close, true);
    ArraySetAsSeries(m_open, true);
    ArraySetAsSeries(m_high, true);
    ArraySetAsSeries(m_low, true);
    
    // Load initial data
    bool result = LoadData();
    
    if(result) {
        // Process initial data
        CalculateAverages();
        ClassifyBars();
        AnalyzePVSR();
        
        if(m_logger) m_logger.Info("PVSRA initialized successfully");
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Update PVSRA data                                                |
//+------------------------------------------------------------------+
void CPVSRA::Update()
{
    // Load latest data
    if(!LoadData()) {
        if(m_logger) m_logger.Error("Failed to load PVSRA data");
        return;
    }
    
    // Process data
    CalculateAverages();
    ClassifyBars();
    AnalyzePVSR();
}

//+------------------------------------------------------------------+
//| Clean up resources                                               |
//+------------------------------------------------------------------+
void CPVSRA::Cleanup()
{
    // Release indicator handle
    if(m_volumeHandle != INVALID_HANDLE) {
        IndicatorRelease(m_volumeHandle);
        m_volumeHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Load necessary data                                              |
//+------------------------------------------------------------------+
bool CPVSRA::LoadData()
{
    // Determine required buffer size
    int requiredBars = MathMax(m_volumeAvgPeriod, m_spreadAvgPeriod) + m_confirmationBars + 10;
    
    // Resize arrays if needed
    if(ArraySize(m_volume) < requiredBars) {
        ArrayResize(m_volume, requiredBars);
        ArrayResize(m_spread, requiredBars);
        ArrayResize(m_close, requiredBars);
        ArrayResize(m_open, requiredBars);
        ArrayResize(m_high, requiredBars);
        ArrayResize(m_low, requiredBars);
        
        ArrayResize(m_avgVolume, requiredBars);
        ArrayResize(m_avgSpread, requiredBars);
        ArrayResize(m_bullPower, requiredBars);
        ArrayResize(m_bearPower, requiredBars);
        ArrayResize(m_volumeType, requiredBars);
        ArrayResize(m_spreadType, requiredBars);
        ArrayResize(m_barType, requiredBars);
    }
    
    // Get volume data
    if(CopyBuffer(m_volumeHandle, 0, 0, requiredBars, m_volume) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy volume data");
        return false;
    }
    
    // Get price data
    if(CopyClose(_Symbol, PERIOD_CURRENT, 0, requiredBars, m_close) <= 0 ||
       CopyOpen(_Symbol, PERIOD_CURRENT, 0, requiredBars, m_open) <= 0 ||
       CopyHigh(_Symbol, PERIOD_CURRENT, 0, requiredBars, m_high) <= 0 ||
       CopyLow(_Symbol, PERIOD_CURRENT, 0, requiredBars, m_low) <= 0) {
        if(m_logger) m_logger.Error("Failed to copy price data");
        return false;
    }
    
    // Calculate spread as high-low difference (in points)
    for(int i = 0; i < requiredBars; i++) {
        m_spread[i] = (m_high[i] - m_low[i]) / _Point;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate moving averages                                        |
//+------------------------------------------------------------------+
void CPVSRA::CalculateAverages()
{
    // Calculate volume moving average
    for(int i = 0; i < ArraySize(m_avgVolume); i++) {
        double sum = 0;
        int count = 0;
        
        for(int j = i; j < i + m_volumeAvgPeriod && j < ArraySize(m_volume); j++) {
            sum += m_volume[j];
            count++;
        }
        
        m_avgVolume[i] = (count > 0) ? sum / count : 0;
    }
    
    // Calculate spread moving average
    for(int i = 0; i < ArraySize(m_avgSpread); i++) {
        double sum = 0;
        int count = 0;
        
        for(int j = i; j < i + m_spreadAvgPeriod && j < ArraySize(m_spread); j++) {
            sum += m_spread[j];
            count++;
        }
        
        m_avgSpread[i] = (count > 0) ? sum / count : 0;
    }
}

//+------------------------------------------------------------------+
//| Classify bars based on volume, spread and price action           |
//+------------------------------------------------------------------+
void CPVSRA::ClassifyBars()
{
    // Classify each bar
    for(int i = 0; i < ArraySize(m_barType) && i < ArraySize(m_volume); i++) {
        // Classify volume
        if(m_volume[i] >= m_avgVolume[i] * m_volumeThreshold) {
            m_volumeType[i] = 1;  // High volume
        }
        else if(m_volume[i] <= m_avgVolume[i] * 0.5) {
            m_volumeType[i] = -1; // Low volume
        }
        else {
            m_volumeType[i] = 0;  // Normal volume
        }
        
        // Classify spread
        if(m_spread[i] >= m_avgSpread[i] * 1.5) {
            m_spreadType[i] = 1;  // Wide spread
        }
        else if(m_spread[i] <= m_avgSpread[i] * m_spreadThreshold) {
            m_spreadType[i] = -1; // Narrow spread
        }
        else {
            m_spreadType[i] = 0;  // Normal spread
        }
        
        // Classify bar direction
        if(m_close[i] > m_open[i]) {
            m_barType[i] = 1;     // Bullish bar
            m_bullPower[i] = (m_high[i] - m_open[i]) / _Point;  // Bull power
            m_bearPower[i] = (m_close[i] - m_low[i]) / _Point;  // Bear power
        }
        else if(m_close[i] < m_open[i]) {
            m_barType[i] = -1;    // Bearish bar
            m_bullPower[i] = (m_high[i] - m_close[i]) / _Point; // Bull power
            m_bearPower[i] = (m_open[i] - m_low[i]) / _Point;   // Bear power
        }
        else {
            m_barType[i] = 0;     // Neutral bar
            m_bullPower[i] = 0;   // Neutral powers
            m_bearPower[i] = 0;
        }
    }
}

//+------------------------------------------------------------------+
//| Analyze Price Volume Spread Relationships                        |
//+------------------------------------------------------------------+
void CPVSRA::AnalyzePVSR()
{
    // Additional PVSRA analysis can be implemented here
    // For now, the basic classification done in ClassifyBars is sufficient
}

//+------------------------------------------------------------------+
//| Check for bullish confirmation based on PVSRA                    |
//+------------------------------------------------------------------+
bool CPVSRA::IsBullishConfirmation()
{
    int confirmedBars = 0;
    
    // Check the last N bars for confirmation
    for(int i = 0; i < m_confirmationBars && i < ArraySize(m_barType); i++) {
        // Bullish bar with high volume and narrow spread is strong confirmation
        if(m_barType[i] > 0 && m_volumeType[i] > 0 && m_spreadType[i] < 0) {
            confirmedBars++;
        }
        // Bullish bar with normal volume is moderate confirmation
        else if(m_barType[i] > 0 && m_volumeType[i] >= 0) {
            confirmedBars += 0.5;
        }
    }
    
    return confirmedBars >= m_confirmationBars * 0.7; // At least 70% confirmation
}

//+------------------------------------------------------------------+
//| Check for bearish confirmation based on PVSRA                    |
//+------------------------------------------------------------------+
bool CPVSRA::IsBearishConfirmation()
{
    int confirmedBars = 0;
    
    // Check the last N bars for confirmation
    for(int i = 0; i < m_confirmationBars && i < ArraySize(m_barType); i++) {
        // Bearish bar with high volume and narrow spread is strong confirmation
        if(m_barType[i] < 0 && m_volumeType[i] > 0 && m_spreadType[i] < 0) {
            confirmedBars++;
        }
        // Bearish bar with normal volume is moderate confirmation
        else if(m_barType[i] < 0 && m_volumeType[i] >= 0) {
            confirmedBars += 0.5;
        }
    }
    
    return confirmedBars >= m_confirmationBars * 0.7; // At least 70% confirmation
}

//+------------------------------------------------------------------+
//| Check for bullish divergence                                     |
//+------------------------------------------------------------------+
bool CPVSRA::IsBullishDivergence()
{
    // Check for price making lower lows but volume decreasing
    // This would indicate potential bullish divergence
    
    // Calculate short term trend
    bool lowerLows = m_low[0] < m_low[1] && m_low[1] < m_low[2];
    
    // Check if volume is decreasing on down moves
    bool volumeDecreasing = m_volumeType[0] < 0 && m_barType[0] < 0;
    
    // Check if current bar has narrow spread (accumulation)
    bool narrowSpread = m_spreadType[0] < 0;
    
    return lowerLows && volumeDecreasing && narrowSpread;
}

//+------------------------------------------------------------------+
//| Check for bearish divergence                                     |
//+------------------------------------------------------------------+
bool CPVSRA::IsBearishDivergence()
{
    // Check for price making higher highs but volume decreasing
    // This would indicate potential bearish divergence
    
    // Calculate short term trend
    bool higherHighs = m_high[0] > m_high[1] && m_high[1] > m_high[2];
    
    // Check if volume is decreasing on up moves
    bool volumeDecreasing = m_volumeType[0] < 0 && m_barType[0] > 0;
    
    // Check if current bar has wide spread (distribution)
    bool wideSpread = m_spreadType[0] > 0;
    
    return higherHighs && volumeDecreasing && wideSpread;
}

//+------------------------------------------------------------------+
//| Get bar type for specific shift                                  |
//+------------------------------------------------------------------+
int CPVSRA::GetBarType(int shift = 0) const
{
    if(shift >= 0 && shift < ArraySize(m_barType)) {
        return m_barType[shift];
    }
    
    return 0; // Neutral if out of range
}

//+------------------------------------------------------------------+
//| Get bull power for specific shift                                |
//+------------------------------------------------------------------+
double CPVSRA::GetBullPower(int shift = 0) const
{
    if(shift >= 0 && shift < ArraySize(m_bullPower)) {
        return m_bullPower[shift];
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Get bear power for specific shift                                |
//+------------------------------------------------------------------+
double CPVSRA::GetBearPower(int shift = 0) const
{
    if(shift >= 0 && shift < ArraySize(m_bearPower)) {
        return m_bearPower[shift];
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Set PVSRA parameters                                             |
//+------------------------------------------------------------------+
void CPVSRA::SetParameters(int volumeAvgPeriod, int spreadAvgPeriod, int confirmationBars)
{
    m_volumeAvgPeriod = volumeAvgPeriod;
    m_spreadAvgPeriod = spreadAvgPeriod;
    m_confirmationBars = confirmationBars;
}

//+------------------------------------------------------------------+
//| Set threshold values                                             |
//+------------------------------------------------------------------+
void CPVSRA::SetThresholds(double volumeThreshold, double spreadThreshold)
{
    m_volumeThreshold = volumeThreshold;
    m_spreadThreshold = spreadThreshold;
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CPVSRA::GetStatusText() const
{
    string status = "PVSRA Status:\n";
    
    // Current settings
    status += "Volume Avg Period: " + IntegerToString(m_volumeAvgPeriod) + "\n";
    status += "Spread Avg Period: " + IntegerToString(m_spreadAvgPeriod) + "\n";
    status += "Confirmation Bars: " + IntegerToString(m_confirmationBars) + "\n";
    status += "Volume Threshold: " + DoubleToString(m_volumeThreshold, 2) + "\n";
    status += "Spread Threshold: " + DoubleToString(m_spreadThreshold, 2) + "\n";
    
    // Current state
    status += "Current Bar Type: " + IntegerToString(GetBarType(0)) + " (1=Bull, -1=Bear)\n";
    status += "Bull Power: " + DoubleToString(GetBullPower(0), 1) + "\n";
    status += "Bear Power: " + DoubleToString(GetBearPower(0), 1) + "\n";
    status += "Bullish Confirmation: " + (IsBullishConfirmation() ? "YES" : "NO") + "\n";
    status += "Bearish Confirmation: " + (IsBearishConfirmation() ? "YES" : "NO") + "\n";
    
    return status;
}