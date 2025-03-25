//+------------------------------------------------------------------+
//|                                            SonicR_SimplePVSRA.mq5 |
//|                        SonicR PropFirm EA - Simple PVSRA Indicator |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_plots   5

// Enumeration for volume patterns
enum ENUM_VOLUME_PATTERN {
    VP_NONE = 0,        // No specific pattern
    VP_CLIMAX_UP = 1,   // Climax volume on up move
    VP_CLIMAX_DOWN = 2, // Climax volume on down move
    VP_CHURN = 3,       // Churn volume (high volume, little price movement)
    VP_EFFORT_UP = 4,   // Effort to rise succeeding
    VP_EFFORT_DOWN = 5, // Effort to fall succeeding
    VP_NO_DEMAND = 6,   // No demand (up bar, low volume)
    VP_NO_SUPPLY = 7,   // No supply (down bar, low volume)
    VP_STOPPING = 8     // Stopping volume
};

// Indicator buffers
double g_volumeRatio[];     // Volume ratio compared to average
double g_bullishBuffer[];   // Bullish volume signals
double g_bearishBuffer[];   // Bearish volume signals
double g_neutralBuffer[];   // Neutral volume signals
double g_climaxBuffer[];    // Climax volume signals

// Additional buffers for calculations
double g_volumeAvg[];       // Average volume
double g_spreadRatio[];     // Spread ratio
double g_bodyRatio[];       // Candle body ratio
double g_patternType[];     // Pattern type (for identification)

// Input parameters
input int VolumePeriod = 20;            // Volume averaging period
input double HighVolumeThreshold = 1.5;  // High volume threshold
input double LowVolumeThreshold = 0.7;   // Low volume threshold
input double ClimaxVolumeThreshold = 2.0; // Climax volume threshold
input int MinimumTrend = 3;              // Minimum trend length for validation

// Global variables
int g_volumeHandle;                     // Handle for volume indicator

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
    // Set indicator buffers
    SetIndexBuffer(0, g_volumeRatio, INDICATOR_DATA);
    SetIndexBuffer(1, g_bullishBuffer, INDICATOR_DATA);
    SetIndexBuffer(2, g_bearishBuffer, INDICATOR_DATA);
    SetIndexBuffer(3, g_neutralBuffer, INDICATOR_DATA);
    SetIndexBuffer(4, g_climaxBuffer, INDICATOR_DATA);
    
    // Set calculation buffers
    SetIndexBuffer(5, g_volumeAvg, INDICATOR_CALCULATIONS);
    SetIndexBuffer(6, g_spreadRatio, INDICATOR_CALCULATIONS);
    SetIndexBuffer(7, g_bodyRatio, INDICATOR_CALCULATIONS);
    SetIndexBuffer(8, g_patternType, INDICATOR_CALCULATIONS);
    
    // Set buffer attributes
    PlotIndexSetString(0, PLOT_LABEL, "Volume Ratio");
    PlotIndexSetString(1, PLOT_LABEL, "Bullish Signal");
    PlotIndexSetString(2, PLOT_LABEL, "Bearish Signal");
    PlotIndexSetString(3, PLOT_LABEL, "Neutral Signal");
    PlotIndexSetString(4, PLOT_LABEL, "Climax Signal");
    
    // Apply plot styles
    PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(1, PLOT_ARROW, 233);
    PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrLime);
    PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 2);
    
    PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(2, PLOT_ARROW, 234);
    PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrRed);
    PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 2);
    
    PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(3, PLOT_ARROW, 251);
    PlotIndexSetInteger(3, PLOT_LINE_COLOR, clrYellow);
    PlotIndexSetInteger(3, PLOT_LINE_WIDTH, 1);
    
    PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_ARROW);
    PlotIndexSetInteger(4, PLOT_ARROW, 176);
    PlotIndexSetInteger(4, PLOT_LINE_COLOR, clrMagenta);
    PlotIndexSetInteger(4, PLOT_LINE_WIDTH, 2);
    
    // Create volume indicator handle
    g_volumeHandle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);
    if(g_volumeHandle == INVALID_HANDLE) {
        Print("Failed to create volumes indicator handle");
        return INIT_FAILED;
    }
    
    // Set indicator name, digits
    IndicatorSetString(INDICATOR_SHORTNAME, "SonicR Simple PVSRA");
    
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handle
    if(g_volumeHandle != INVALID_HANDLE) {
        IndicatorRelease(g_volumeHandle);
        g_volumeHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
    // Check for minimum required bars
    if(rates_total < VolumePeriod + 10) {
        return 0;
    }
    
    // Check indicator handle
    if(g_volumeHandle == INVALID_HANDLE) {
        Print("Invalid volume indicator handle");
        return 0;
    }
    
    // Determine starting bar
    int start;
    
    // If first call or insufficient previous bars
    if(prev_calculated <= 0 || prev_calculated > rates_total) {
        start = VolumePeriod;
        
        // Initialize buffers
        ArrayInitialize(g_volumeRatio, 0.0);
        ArrayInitialize(g_bullishBuffer, 0.0);
        ArrayInitialize(g_bearishBuffer, 0.0);
        ArrayInitialize(g_neutralBuffer, 0.0);
        ArrayInitialize(g_climaxBuffer, 0.0);
        ArrayInitialize(g_volumeAvg, 0.0);
        ArrayInitialize(g_spreadRatio, 0.0);
        ArrayInitialize(g_bodyRatio, 0.0);
        ArrayInitialize(g_patternType, 0.0);
    }
    else {
        start = prev_calculated - 1;
    }
    
    // Get volume data
    double volume_buffer[];
    if(!CopyBuffer(g_volumeHandle, 0, 0, rates_total, volume_buffer)) {
        Print("Failed to copy volume data");
        return 0;
    }
    
    // Calculate indicators
    for(int i = start; i < rates_total; i++) {
        // Calculate average volume over period
        double avg_volume = 0;
        for(int j = i - VolumePeriod; j < i; j++) {
            avg_volume += volume_buffer[j];
        }
        avg_volume /= VolumePeriod;
        g_volumeAvg[i] = avg_volume;
        
        // Calculate volume ratio
        double volume_ratio = 0;
        if(avg_volume > 0) {
            volume_ratio = volume_buffer[i] / avg_volume;
        }
        g_volumeRatio[i] = volume_ratio;
        
        // Rest of calculation code
        // ...
    }
    
    return(rates_total);
}