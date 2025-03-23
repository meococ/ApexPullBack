//+------------------------------------------------------------------+
//|                                                SonicR_PVSRA.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm"
#property link      "https://sonicr.com"
#property version   "1.00"
#property indicator_separate_window
#property indicator_buffers 5
#property indicator_plots   5

// Volume histogram properties
#property indicator_label1  "Normal Volume"
#property indicator_type1   DRAW_HISTOGRAM
#property indicator_width1  2
#property indicator_style1  STYLE_SOLID

#property indicator_label2  "Climax Bull Volume"
#property indicator_type2   DRAW_HISTOGRAM
#property indicator_width2  2
#property indicator_style2  STYLE_SOLID

#property indicator_label3  "Climax Bear Volume"
#property indicator_type3   DRAW_HISTOGRAM
#property indicator_width3  2
#property indicator_style3  STYLE_SOLID

#property indicator_label4  "Rising Bull Volume"
#property indicator_type4   DRAW_HISTOGRAM
#property indicator_width4  2
#property indicator_style4  STYLE_SOLID

#property indicator_label5  "Rising Bear Volume"
#property indicator_type5   DRAW_HISTOGRAM
#property indicator_width5  2
#property indicator_style5  STYLE_SOLID

// Input parameters
input int VolumePeriod = 10;           // Volume averaging period
input double ClimaxThreshold = 2.0;    // Climax volume threshold (200%)
input double RisingThreshold = 1.5;    // Rising volume threshold (150%)

// Color settings for volume
input color NormalVolumeColor = C'113,131,149';   // Normal volume
input color RisingBullVolumeColor = C'045,081,206';  // Rising bull volume
input color RisingBearVolumeColor = C'154,038,232';  // Rising bear volume
input color ClimaxBullVolumeColor = C'000,166,100';  // Climax bull volume
input color ClimaxBearVolumeColor = C'214,012,083';  // Climax bear volume

// Buffers
double VolumeBuffer[];       // Main volume
double ClimaxBullBuffer[];   // Climax bull volume
double ClimaxBearBuffer[];   // Climax bear volume
double RisingBullBuffer[];   // Rising bull volume
double RisingBearBuffer[];   // Rising bear volume

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set indicator properties
   IndicatorSetString(INDICATOR_SHORTNAME, "SonicR PVSRA");
   
   // Set buffer mappings for volume histogram
   SetIndexBuffer(0, VolumeBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, ClimaxBullBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, ClimaxBearBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, RisingBullBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, RisingBearBuffer, INDICATOR_DATA);
   
   // Set colors for each plot
   PlotIndexSetInteger(0, PLOT_LINE_COLOR, NormalVolumeColor);
   PlotIndexSetInteger(1, PLOT_LINE_COLOR, ClimaxBullVolumeColor);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, ClimaxBearVolumeColor);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, RisingBullVolumeColor);
   PlotIndexSetInteger(4, PLOT_LINE_COLOR, RisingBearVolumeColor);
   
   return(INIT_SUCCEEDED);
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
   if(rates_total < VolumePeriod + 1) {
      return(0);
   }
   
   // Calculate starting bar
   int start;
   if(prev_calculated == 0) {
      start = VolumePeriod;
      
      // Initialize buffers
      ArrayInitialize(VolumeBuffer, 0);
      ArrayInitialize(ClimaxBullBuffer, 0);
      ArrayInitialize(ClimaxBearBuffer, 0);
      ArrayInitialize(RisingBullBuffer, 0);
      ArrayInitialize(RisingBearBuffer, 0);
   } else {
      start = MathMax(prev_calculated - 1, VolumePeriod);
   }
   
   // Main calculation loop
   for(int i = start; i < rates_total; i++) {
      // Calculate average volume
      double avgVolume = 0;
      for(int j = 1; j <= VolumePeriod; j++) {
         avgVolume += (double)tick_volume[i-j]; // Convert long to double explicitly
      }
      avgVolume /= VolumePeriod;
      
      // Check if candle is bullish or bearish
      bool isBullish = close[i] >= open[i];
      
      // Check for climax volume
      bool isClimaxVolume = ((double)tick_volume[i] >= avgVolume * ClimaxThreshold);
      
      // Check for rising volume
      bool isRisingVolume = ((double)tick_volume[i] >= avgVolume * RisingThreshold) && !isClimaxVolume;
      
      // Calculate candle spread (high-low)
      double candleSpread = high[i] - low[i];
      
      // Calculate "Climax" by spread*volume
      double spreadVolume = candleSpread * (double)tick_volume[i];
      
      // Find max spread*volume in VolumePeriod
      double maxSpreadVolume = 0;
      for(int j = 1; j <= VolumePeriod; j++) {
         if(i-j >= 0) {
            double sv = (high[i-j] - low[i-j]) * (double)tick_volume[i-j];
            if(sv > maxSpreadVolume) maxSpreadVolume = sv;
         }
      }
      
      // Additional climax check: spread*volume >= highest in period
      bool isSpreadVolumeClimax = (spreadVolume >= maxSpreadVolume) && (maxSpreadVolume > 0);
      
      // Combine both climax conditions
      isClimaxVolume = isClimaxVolume || isSpreadVolumeClimax;
      
      // Set buffers based on volume conditions
      if(isClimaxVolume) {
         // Climax volume
         VolumeBuffer[i] = 0;
         ClimaxBullBuffer[i] = isBullish ? (double)tick_volume[i] : 0;
         ClimaxBearBuffer[i] = isBullish ? 0 : (double)tick_volume[i];
         RisingBullBuffer[i] = 0;
         RisingBearBuffer[i] = 0;
      }
      else if(isRisingVolume) {
         // Rising volume
         VolumeBuffer[i] = 0;
         ClimaxBullBuffer[i] = 0;
         ClimaxBearBuffer[i] = 0;
         RisingBullBuffer[i] = isBullish ? (double)tick_volume[i] : 0;
         RisingBearBuffer[i] = isBullish ? 0 : (double)tick_volume[i];
      }
      else {
         // Normal volume
         VolumeBuffer[i] = (double)tick_volume[i];
         ClimaxBullBuffer[i] = 0;
         ClimaxBearBuffer[i] = 0;
         RisingBullBuffer[i] = 0;
         RisingBearBuffer[i] = 0;
      }
   }
   
   // Apply specific candle coloring using ChartEvent functionality
   ChartRedraw(); // Ensure chart is redrawn with new data
   
   return(rates_total);
}