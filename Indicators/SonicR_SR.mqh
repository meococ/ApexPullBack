//+------------------------------------------------------------------+
//|                                                  SonicR_SR.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm"
#property link      "https://sonicr.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

// Need at least one plot for MQL5 indicator
#property indicator_type1   DRAW_NONE
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_color1  clrNONE

// Input parameters
input bool ShowWholeNumbers = true;     // Show whole numbers (1.2000)
input bool ShowHalfNumbers = true;      // Show half numbers (1.2050)
input bool ShowQuarterNumbers = false;  // Show quarter numbers (1.2025/1.2075)
input bool ShowSwingPoints = true;      // Show swing high/low points
input int SwingLookback = 20;           // Lookback for swing points
input int SwingThreshold = 5;           // Number of bars for swing confirmation
input bool ShowLabels = true;           // Show price labels
input color WholeNumberColor = clrDarkSlateGray;      // Whole number color
input color HalfNumberColor = clrDarkGreen;           // Half number color
input color QuarterNumberColor = clrGray;             // Quarter number color
input color SwingHighColor = clrFireBrick;            // Swing high color
input color SwingLowColor = clrRoyalBlue;             // Swing low color
input int LineWidth = 1;                // Line width
input ENUM_LINE_STYLE LineStyle = STYLE_DOT;  // Line style
input int NumberOfLevels = 10;          // Number of levels above/below current price

// Buffer for the indicator (required by MQL5)
double DummyBuffer[];

// Global variables
double CurrentPrice = 0;
string IndicatorName = "SonicR_SR";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Set up a dummy buffer (required by MQL5 for indicators)
   SetIndexBuffer(0, DummyBuffer, INDICATOR_DATA);
   
   // Set indicator name
   IndicatorSetString(INDICATOR_SHORTNAME, "SonicR Support & Resistance");
   
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
   // Update only on new bar or first calculation
   if(prev_calculated > 0 && rates_total == prev_calculated) {
      return(rates_total);
   }
   
   // Get current price
   if(rates_total > 0) {
      CurrentPrice = close[rates_total-1];
   
      // Remove old lines and labels
      RemoveAllObjects();
      
      // Draw SR levels
      DrawSRLevels(time, high, low);
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Draw all support and resistance levels                           |
//+------------------------------------------------------------------+
void DrawSRLevels(const datetime &time[], const double &high[], const double &low[])
{
   // Find the nearest whole number
   double baseWholeNumber = MathFloor(CurrentPrice);
   
   // Draw whole, half, and quarter numbers
   if(ShowWholeNumbers || ShowHalfNumbers || ShowQuarterNumbers) {
      for(int i = -NumberOfLevels; i <= NumberOfLevels; i++) {
         double currentWholeNumber = baseWholeNumber + i;
         
         // Draw whole number
         if(ShowWholeNumbers) {
            DrawLevel(currentWholeNumber, "W" + DoubleToString(currentWholeNumber, 0), WholeNumberColor);
         }
         
         // Draw half number
         if(ShowHalfNumbers) {
            double halfNumber = currentWholeNumber + 0.5;
            DrawLevel(halfNumber, "H" + DoubleToString(halfNumber, 1), HalfNumberColor);
         }
         
         // Draw quarter numbers
         if(ShowQuarterNumbers) {
            double quarterNumber1 = currentWholeNumber + 0.25;
            double quarterNumber2 = currentWholeNumber + 0.75;
            DrawLevel(quarterNumber1, "Q" + DoubleToString(quarterNumber1, 2), QuarterNumberColor);
            DrawLevel(quarterNumber2, "Q" + DoubleToString(quarterNumber2, 2), QuarterNumberColor);
         }
      }
   }
   
   // Find and draw swing points
   if(ShowSwingPoints) {
      FindAndDrawSwingPoints(time, high, low);
   }
}

//+------------------------------------------------------------------+
//| Draw a single horizontal level                                   |
//+------------------------------------------------------------------+
void DrawLevel(double price, string name, color clr)
{
   // Create unique name
   string objName = IndicatorName + "_Line_" + name;
   
   // Draw horizontal line
   ObjectCreate(0, objName, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, LineStyle);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, LineWidth);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   
   // Draw label if enabled
   if(ShowLabels) {
      string labelName = IndicatorName + "_Label_" + name;
      ObjectCreate(0, labelName, OBJ_TEXT, 0, TimeCurrent(), price);
      ObjectSetString(0, labelName, OBJPROP_TEXT, DoubleToString(price, _Digits));
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
   }
}

//+------------------------------------------------------------------+
//| Find and draw swing high and low points                          |
//+------------------------------------------------------------------+
void FindAndDrawSwingPoints(const datetime &time[], const double &high[], const double &low[])
{
   int count = ArraySize(high);
   if(count < SwingLookback + SwingThreshold) return;
   
   // Find swing highs and lows
   for(int i = SwingThreshold; i < count - SwingThreshold; i++) {
      // Check for swing high
      bool isSwingHigh = true;
      for(int j = 1; j <= SwingThreshold; j++) {
         if(high[i] <= high[i-j] || high[i] <= high[i+j]) {
            isSwingHigh = false;
            break;
         }
      }
      
      // Draw swing high
      if(isSwingHigh) {
         string name = "SwingHigh_" + TimeToString(time[i]);
         DrawLevel(high[i], name, SwingHighColor);
      }
      
      // Check for swing low
      bool isSwingLow = true;
      for(int j = 1; j <= SwingThreshold; j++) {
         if(low[i] >= low[i-j] || low[i] >= low[i+j]) {
            isSwingLow = false;
            break;
         }
      }
      
      // Draw swing low
      if(isSwingLow) {
         string name = "SwingLow_" + TimeToString(time[i]);
         DrawLevel(low[i], name, SwingLowColor);
      }
   }
}

//+------------------------------------------------------------------+
//| Remove all objects created by this indicator                     |
//+------------------------------------------------------------------+
void RemoveAllObjects()
{
   ObjectsDeleteAll(0, IndicatorName + "_Line_");
   ObjectsDeleteAll(0, IndicatorName + "_Label_");
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Remove all objects
   RemoveAllObjects();
}