//+------------------------------------------------------------------+
//|                                               SonicR_Dragon.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm"
#property link      "https://sonicr.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   4

// Buffers for Dragon (EMA34 applied to High, Low, Close) and Trend (EMA89)
#property indicator_label1  "Dragon Mid"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "Dragon High"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrRoyalBlue 
#property indicator_style2  STYLE_DOT
#property indicator_width2  1

#property indicator_label3  "Dragon Low"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrRoyalBlue
#property indicator_style3  STYLE_DOT
#property indicator_width3  1

#property indicator_label4  "Trend"
#property indicator_type4   DRAW_LINE
#property indicator_color4  clrMagenta
#property indicator_style4  STYLE_SOLID
#property indicator_width4  2

// Input parameters
input int DragonPeriod = 34;   // Dragon Period (EMA34)
input int TrendPeriod = 89;    // Trend Period (EMA89)
input bool FillDragon = true;  // Fill area between Dragon High and Low
input color FillColor = C'221,238,255';  // Fill color

// Indicator buffers
double DragonMidBuffer[];
double DragonHighBuffer[];
double DragonLowBuffer[];
double TrendBuffer[];

// Global variables
int fillObjectId = 0;
string fillObjectName = "";

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
{
   // Mapping indicator buffers
   SetIndexBuffer(0, DragonMidBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, DragonHighBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, DragonLowBuffer, INDICATOR_DATA);
   SetIndexBuffer(3, TrendBuffer, INDICATOR_DATA);
   
   // Setting indicator properties
   PlotIndexSetString(0, PLOT_LABEL, "Dragon Mid (EMA" + IntegerToString(DragonPeriod) + " Close)");
   PlotIndexSetString(1, PLOT_LABEL, "Dragon High (EMA" + IntegerToString(DragonPeriod) + " High)");
   PlotIndexSetString(2, PLOT_LABEL, "Dragon Low (EMA" + IntegerToString(DragonPeriod) + " Low)");
   PlotIndexSetString(3, PLOT_LABEL, "Trend (EMA" + IntegerToString(TrendPeriod) + " Close)");
   
   // Setting indicator names for DataWindow
   IndicatorSetString(INDICATOR_SHORTNAME, "SonicR Dragon (" + IntegerToString(DragonPeriod) + "," + IntegerToString(TrendPeriod) + ")");
   
   // Initialize fill object
   if(FillDragon) {
      fillObjectName = "SonicR_Dragon_Fill_" + _Symbol + "_" + IntegerToString(ChartID());
      if(ObjectFind(0, fillObjectName) < 0) {
         ObjectCreate(0, fillObjectName, OBJ_RECTANGLE, 0, 0, 0, 0, 0);
      }
      ObjectSetInteger(0, fillObjectName, OBJPROP_COLOR, FillColor);
      ObjectSetInteger(0, fillObjectName, OBJPROP_BACK, true);
      ObjectSetInteger(0, fillObjectName, OBJPROP_FILL, true);
      ObjectSetInteger(0, fillObjectName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, fillObjectName, OBJPROP_SELECTABLE, false);
   }
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // Delete the fill object
   if(FillDragon) {
      ObjectDelete(0, fillObjectName);
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
   // Check for minimum bars
   if(rates_total < MathMax(DragonPeriod, TrendPeriod) + 1) {
      return(0);
   }
   
   // Calculate starting bar
   int start;
   if(prev_calculated == 0) {
      start = MathMax(DragonPeriod, TrendPeriod);
      
      // Initialize buffers
      ArrayInitialize(DragonMidBuffer, 0);
      ArrayInitialize(DragonHighBuffer, 0);
      ArrayInitialize(DragonLowBuffer, 0);
      ArrayInitialize(TrendBuffer, 0);
   } else {
      start = prev_calculated - 1;
   }
   
   // Calculate EMAs for each bar
   for(int i = start; i < rates_total; i++) {
      // Dragon Mid (EMA on Close)
      DragonMidBuffer[i] = CalculateEMA(close, i, DragonPeriod);
      
      // Dragon High (EMA on High)
      DragonHighBuffer[i] = CalculateEMA(high, i, DragonPeriod);
      
      // Dragon Low (EMA on Low)
      DragonLowBuffer[i] = CalculateEMA(low, i, DragonPeriod);
      
      // Trend (EMA on Close)
      TrendBuffer[i] = CalculateEMA(close, i, TrendPeriod);
   }
   
   // Update fill object if enabled
   if(FillDragon && rates_total > 0) {
      UpdateFillObject(time, rates_total);
   }
   
   return(rates_total);
}

//+------------------------------------------------------------------+
//| Calculate EMA value                                              |
//+------------------------------------------------------------------+
double CalculateEMA(const double &price[], int index, int period)
{
   if(index < period) {
      return price[index]; // Not enough data for EMA calculation
   }
   
   double alpha = 2.0 / (period + 1.0);
   
   if(index == period) {
      // Initial EMA value is SMA
      double sum = 0;
      for(int i = 0; i < period; i++) {
         sum += price[index - i];
      }
      return sum / period;
   }
   
   // Subsequent EMA values
   return alpha * price[index] + (1 - alpha) * CalculateEMA(price, index - 1, period);
}

//+------------------------------------------------------------------+
//| Update the fill object between Dragon High and Low               |
//+------------------------------------------------------------------+
void UpdateFillObject(const datetime &time[], int rates_total)
{
   // Get visible chart range
   long first_visible_bar = ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
   long bars_in_window = ChartGetInteger(0, CHART_VISIBLE_BARS);
   long last_bar = first_visible_bar - bars_in_window;
   
   // Ensure last_bar is valid
   if(last_bar < 0) last_bar = 0;
   if(first_visible_bar >= rates_total) first_visible_bar = rates_total - 1;
   
   // Update fill object coordinates
   datetime time1 = time[(int)MathMin(first_visible_bar, rates_total-1)];
   datetime time2 = time[(int)MathMax(0, last_bar)];
   
   // Set object coordinates
   ObjectSetInteger(0, fillObjectName, OBJPROP_TIME, 0, time1);
   ObjectSetInteger(0, fillObjectName, OBJPROP_TIME, 1, time2);
   ObjectSetDouble(0, fillObjectName, OBJPROP_PRICE, 0, DragonHighBuffer[(int)MathMin(first_visible_bar, rates_total-1)]);
   ObjectSetDouble(0, fillObjectName, OBJPROP_PRICE, 1, DragonLowBuffer[(int)MathMax(0, last_bar)]);
}