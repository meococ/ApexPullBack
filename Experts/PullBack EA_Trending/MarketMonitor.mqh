//+------------------------------------------------------------------+
//|                                            MarketMonitor.mqh     |
//|                  Copyright 2023-2025, ApexTrading Systems        |
//|                           https://www.apextradingsystems.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "10.5"

// Include required files
#include <Arrays/ArrayObj.mqh>
#include "Logger.mqh"
#include "CommonStructs.mqh"

// Forward declarations
class CTargetInfo;

//+------------------------------------------------------------------+
//| Market Monitor Class                                             |
//| Responsible for market analysis, trend detection and signal      |
//| generation based on multiple strategies                          |
//+------------------------------------------------------------------+
class CMarketMonitor
{
private:
   // Core properties
   string               m_Symbol;                // Symbol to monitor
   ENUM_TIMEFRAMES      m_EntryTimeframe;       // Primary timeframe for entry signals
   int                  m_ATRPeriod;            // ATR period (default 14)
   int                  m_EmaFastPeriod;        // Fast EMA period 
   int                  m_EmaTrendPeriod;       // Trend EMA period
   double               m_EnvelopeDeviation;    // Envelope deviation factor
   CLogger*             m_Logger;               // Logger object
   bool                 m_IsInitialized;        // Flag to track initialization state
   
   // Multi-timeframe properties
   bool                 m_UseMultiTimeframe;    // Whether to use multi-timeframe analysis
   ENUM_TIMEFRAMES      m_HigherTimeframe;      // Higher timeframe for trend confirmation
   bool                 m_UseNestedTimeframe;   // Whether to use nested timeframe for entry refinement
   ENUM_TIMEFRAMES      m_NestedTimeframe;      // Nested timeframe for entry refinement
   
   // Market regime filter
   bool                 m_EnableMarketRegimeFilter; // Whether to filter signals based on market regime
   double               m_VolatilityThreshold;  // Threshold for high volatility market
   double               m_RangeThreshold;       // Threshold for ranging market
   
   // Indicator handles 
   int                  m_HandleATR;            // ATR indicator handle
   int                  m_HandleEMA_Fast;       // Fast EMA indicator handle
   int                  m_HandleEMA_Trend;      // Trend EMA indicator handle
   int                  m_HandleRSI;            // RSI indicator handle
   int                  m_HandleMACD;           // MACD indicator handle
   int                  m_HandleBB;             // Bollinger Bands indicator handle
   int                  m_HandleADX;            // ADX indicator handle
   
   // Higher timeframe indicator handles
   int                  m_HandleATR_Higher;     // Higher timeframe ATR handle
   int                  m_HandleEMA_Fast_Higher;// Higher timeframe fast EMA handle
   int                  m_HandleEMA_Trend_Higher;// Higher timeframe trend EMA handle
   
   // Nested timeframe indicator handles
   int                  m_HandleATR_Nested;     // Nested timeframe ATR handle
   int                  m_HandleEMA_Fast_Nested;// Nested timeframe fast EMA handle
   int                  m_HandleEMA_Trend_Nested;// Nested timeframe trend EMA handle
   
   // Cached indicator data structure
   struct CachedData
   {
      // Entry timeframe data
      double atr_entry;           // ATR value on entry timeframe
      double ema_fast_entry;      // Fast EMA on entry timeframe
      double ema_trend_entry;     // Trend EMA on entry timeframe
      double rsi;                 // RSI value
      double rsi_prev;            // Previous RSI value
      double macd;                // MACD main line
      double macd_signal;         // MACD signal line
      double bb_upper;            // Bollinger upper band
      double bb_lower;            // Bollinger lower band
      double bb_middle;           // Bollinger middle band
      double adx;                 // ADX value
      
      // Higher timeframe data
      double atr_higher;          // ATR on higher timeframe
      double ema_fast_higher;     // Fast EMA on higher timeframe
      double ema_trend_higher;    // Trend EMA on higher timeframe
      
      // Nested timeframe data
      double atr_nested;          // ATR on nested timeframe
      double ema_fast_nested;     // Fast EMA on nested timeframe
      double ema_trend_nested;    // Trend EMA on nested timeframe
      
      // Price data
      double close;               // Current close price
      double open;                // Current open price
      double high;                // Current high price
      double low;                 // Current low price
      double prev_close;          // Previous close price
      MqlDateTime time;           // Current bar time
   };
   
   // Market state variables
   ENUM_MARKET_REGIME   m_MarketRegime;         // Current market regime
   bool                 m_IsTrendUp;            // Flag for uptrend
   bool                 m_IsTrendDown;          // Flag for downtrend
   bool                 m_IsRangebound;         // Flag for ranging market
   bool                 m_IsVolatile;           // Flag for volatile market
   
   // Signal handling
   SignalInfo           m_LastSignal;           // Last generated signal
   CArrayObj            m_RecentSignals;        // Recent signals storage
   datetime             m_LastUpdateTime;       // Time of last update
   bool                 m_IsNewBar;             // Flag for new bar
   
   // Data cache
   CachedData           m_Cache;                // Data cache structure
   
   // Entry strategy parameters
   // Pullback parameters
   double               m_MinPullbackDepth;     // Minimum pullback depth (ATR multiplier)
   double               m_MaxPullbackDepth;     // Maximum pullback depth (ATR multiplier)
   double               m_MinBounceStrength;    // Minimum bounce strength from pullback (0-1)
   double               m_MaxBounceStrength;    // Maximum bounce strength from pullback (0-1)
   
   // Fibonacci parameters
   double               m_FibonacciNearThreshold; // How close price must be to fib level (ATR multiplier)
   double               m_GoldenZoneBonus;      // Quality bonus for golden zone retracement
   double               m_FibMinImpulseSize;    // Minimum size of impulse for fib analysis

   // Harmonic pattern parameters
   double               m_HarmonicTolerance;    // Tolerance for harmonic pattern ratios
   
   // Momentum parameters
   int                  m_MomentumLookback;     // Lookback period for momentum analysis
   
   // Liquidity grab parameters
   double               m_MinWickRatio;         // Minimum wick to body ratio for liquidity grab
   double               m_MinVolumeRatio;       // Minimum volume ratio for liquidity grab
   
   // Breakout parameters
   double               m_MinBreakoutSize;      // Minimum size of breakout (ATR multiplier)
   
   //--- Private methods
   
   // Indicator initialization methods
   bool                 InitializeIndicators();
   void                 ReleaseIndicators();
   
   // Data update methods
   bool                 UpdateIndicatorData();
   bool                 UpdateMarketState();
   bool                 IsNewBar();
   
   // Market analysis methods
   void                 AnalyzeMarketRegime();
   void                 AnalyzeTrendDirection();
   void                 AnalyzeVolatility();
   
   // Helper methods for signal detection
   bool                 IsPriceAboveEMA(ENUM_TIMEFRAMES timeframe, int emaPeriod);
   bool                 IsPriceBelowEMA(ENUM_TIMEFRAMES timeframe, int emaPeriod);
   bool                 IsEMASetupBullish(ENUM_TIMEFRAMES timeframe);
   bool                 IsEMASetupBearish(ENUM_TIMEFRAMES timeframe);
   double               GetSwingHigh(int startBar, int lookback);
   double               GetSwingLow(int startBar, int lookback);
   bool                 IsBullishEngulfing(int barIndex);
   bool                 IsBearishEngulfing(int barIndex);
   bool                 IsBullishPinBar(int barIndex);
   bool                 IsBearishPinBar(int barIndex);
   bool                 HasPositiveDivergence(int lookback);
   bool                 HasNegativeDivergence(int lookback);
   
   // Safe data access methods
   bool                 SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[]);
   bool                 SafeCopyRates(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, 
                                     double &open[], double &high[], double &low[], double &close[]);
   bool                 SafeCopyTime(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, datetime &time[]);
   
   // Signal quality assessment
   double               AssessSignalQuality(ENUM_ENTRY_SCENARIO scenario, bool isLong, 
                                          double entryPrice, double stopLoss);

public:
                        CMarketMonitor(void);
                        ~CMarketMonitor(void);
    
   // Initialization and setup
   bool                 Initialize(string symbol, ENUM_TIMEFRAMES entryTimeframe, 
                                 int emaFastPeriod, int emaTrendPeriod,
                                 bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe,
                                 bool useNestedTimeframe, ENUM_TIMEFRAMES nestedTimeframe,
                                 bool enableMarketRegimeFilter);
   
   void                 SetEnvelopeDeviation(double deviation) { m_EnvelopeDeviation = deviation; }
   void                 SetPullbackParameters(double minDepth, double maxDepth, double minBounce, double maxBounce);
   void                 SetFibonacciParameters(double nearThreshold, double goldenBonus, double minImpulseSize);
   void                 SetHarmonicParameters(double tolerance);
   void                 SetMomentumParameters(int lookback);
   void                 SetLiquidityGrabParameters(double minWickRatio, double minVolumeRatio);
   void                 SetBreakoutParameters(double minSize);
   
   // Main updating method
   bool                 Update();
   
   // Signal generation methods
   bool                 CheckEntrySignal(SignalInfo &signal);
   ENUM_TRADE_SIGNAL    GenerateSignals(double &entryPrice, double &stopLoss, double &takeProfit, 
                                        ENUM_ENTRY_SCENARIO &scenario);
   
   // Entry methods implementation
   bool                 AnalyzePullback(bool isUptrend, double &depth, double &speed, double &strength,
                                      double &entryPrice, double &stopLevel, string &description);
   bool                 DetectFibonacciPullback(bool isUptrend, double &entryLevels[], double &qualityScore);
   bool                 DetectHarmonicPatterns(bool isUptrend, double &entryLevel, double &stopLevel, 
                                            double &qualityScore, string &patternName);
   bool                 DetectMomentumShift(bool isUptrend, double &entryPrice, double &stopLevel,
                                         double &quality, string &description);
   bool                 DetectLiquidityGrab(bool isUptrend, double &entryPrice, double &stopLevel,
                                         double &quality, string &description);
   bool                 DetectBreakoutFailure(bool isUptrend, double &entryPrice, double &stopLevel,
                                          double &quality, string &description);
   
   // Helper methods for identifying structures
   bool                 FindConsolidationZone(const double &high[], const double &low[], 
                                           double &zoneHigh, double &zoneLow, 
                                           int minBars, int maxLookback);
   bool                 IsLocalTop(const double &high[], int index);
   bool                 IsLocalBottom(const double &low[], int index);
   
   // Signal feedback methods
   void                 FeedbackSignalResult(SignalInfo &signal, bool success, ulong ticket, string failReason = "");
   
   // Getters for market state and indicator data
   ENUM_MARKET_REGIME   GetMarketState() const { return m_MarketRegime; }
   bool                 IsTrendUp() const { return m_IsTrendUp; }
   bool                 IsTrendDown() const { return m_IsTrendDown; }
   double               GetATR() const { return m_Cache.atr_entry; }
   double               GetEMAFast() const { return m_Cache.ema_fast_entry; }
   double               GetEMATrend() const { return m_Cache.ema_trend_entry; }
   double               GetVolatilityFactor() const;
   double               GetHighestHighSinceBar(int startBar, int lookback = 20);
   double               GetLowestLowSinceBar(int startBar, int lookback = 20);
   bool                 GetLastSignal(SignalInfo &signal);
   CLogger*             GetLogger() const { return m_Logger; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketMonitor::CMarketMonitor(void)
{
   // Initialize properties
   m_Symbol = "";
   m_EntryTimeframe = PERIOD_H1;
   m_ATRPeriod = 14;
   m_EmaFastPeriod = 34;
   m_EmaTrendPeriod = 89;
   m_EnvelopeDeviation = 0.001; // 0.1%
   
   m_UseMultiTimeframe = false;
   m_HigherTimeframe = PERIOD_H4;
   m_UseNestedTimeframe = false;
   m_NestedTimeframe = PERIOD_M15;
   
   m_EnableMarketRegimeFilter = true;
   m_VolatilityThreshold = 1.5;
   m_RangeThreshold = 0.3;
   
   // Initialize indicator handles
   m_HandleATR = INVALID_HANDLE;
   m_HandleEMA_Fast = INVALID_HANDLE;
   m_HandleEMA_Trend = INVALID_HANDLE;
   m_HandleRSI = INVALID_HANDLE;
   m_HandleMACD = INVALID_HANDLE;
   m_HandleBB = INVALID_HANDLE;
   m_HandleADX = INVALID_HANDLE;
   
   m_HandleATR_Higher = INVALID_HANDLE;
   m_HandleEMA_Fast_Higher = INVALID_HANDLE;
   m_HandleEMA_Trend_Higher = INVALID_HANDLE;
   
   m_HandleATR_Nested = INVALID_HANDLE;
   m_HandleEMA_Fast_Nested = INVALID_HANDLE;
   m_HandleEMA_Trend_Nested = INVALID_HANDLE;
   
   // Initialize market state
   m_MarketRegime = REGIME_RANGING; // Default to ranging
   m_IsTrendUp = false;
   m_IsTrendDown = false;
   m_IsRangebound = true;
   m_IsVolatile = false;
   m_LastUpdateTime = 0;
   m_IsNewBar = false;
   m_IsInitialized = false;
   
   // Initialize entry strategy parameters with sensible defaults
   m_MinPullbackDepth = 0.2;    // 20% of ATR minimum pullback
   m_MaxPullbackDepth = 0.8;    // 80% of ATR maximum pullback
   m_MinBounceStrength = 0.2;   // 20% bounce from pullback low
   m_MaxBounceStrength = 0.9;   // 90% bounce from pullback low
   
   m_FibonacciNearThreshold = 0.25; // Price must be within 0.25 ATR of fib level
   m_GoldenZoneBonus = 0.15;   // Quality bonus for golden zone entries
   m_FibMinImpulseSize = 1.5;  // Impulse must be at least 1.5 ATR
   
   m_HarmonicTolerance = 0.03; // 3% tolerance for harmonic pattern ratios
   
   m_MomentumLookback = 60;    // Lookback for momentum analysis
   
   m_MinWickRatio = 2.0;       // Wick must be 2x body for liquidity grab
   m_MinVolumeRatio = 1.5;     // Volume must be 1.5x average for liquidity grab
   
   m_MinBreakoutSize = 0.3;    // Breakout must be at least 0.3 ATR
   
   // Initialize logger
   m_Logger = new CLogger("MarketMonitor");
   
   ZeroMemory(m_Cache); // Initialize cache to zeros
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketMonitor::~CMarketMonitor(void)
{
   // Release all indicator handles
   ReleaseIndicators();
   
   // Clear recent signals array
   m_RecentSignals.Clear();
   
   // Clean up logger
   if (m_Logger != NULL) {
      delete m_Logger;
      m_Logger = NULL;
   }
}

//+------------------------------------------------------------------+
//| Initialize the Market Monitor                                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::Initialize(string symbol, ENUM_TIMEFRAMES entryTimeframe, 
                             int emaFastPeriod, int emaTrendPeriod,
                             bool useMultiTimeframe, ENUM_TIMEFRAMES higherTimeframe,
                             bool useNestedTimeframe, ENUM_TIMEFRAMES nestedTimeframe,
                             bool enableMarketRegimeFilter)
{
   if (m_IsInitialized) {
      // If already initialized, release existing resources first
      ReleaseIndicators();
   }
   
   // Set core parameters
   m_Symbol = symbol;
   m_EntryTimeframe = entryTimeframe;
   m_EmaFastPeriod = emaFastPeriod;
   m_EmaTrendPeriod = emaTrendPeriod;
   
   // Set multi-timeframe parameters
   m_UseMultiTimeframe = useMultiTimeframe;
   m_HigherTimeframe = higherTimeframe;
   m_UseNestedTimeframe = useNestedTimeframe;
   m_NestedTimeframe = nestedTimeframe;
   
   // Set regime filter
   m_EnableMarketRegimeFilter = enableMarketRegimeFilter;
   
   // Initialize all indicators
   if (!InitializeIndicators()) {
      m_Logger.LogError("Failed to initialize indicators for " + symbol);
      return false;
   }
   
   // Update data initially to populate cache
   if (!UpdateIndicatorData()) {
      m_Logger.LogError("Failed to update indicator data for " + symbol);
      return false;
   }
   
   m_Logger.LogInfo("Market Monitor initialized successfully for " + symbol);
   m_IsInitialized = true;
   return true;
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                        |
//+------------------------------------------------------------------+
bool CMarketMonitor::InitializeIndicators()
{
   // Initialize entry timeframe indicators
   m_HandleATR = iATR(m_Symbol, m_EntryTimeframe, m_ATRPeriod);
   if (m_HandleATR == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize ATR: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA_Fast = iMA(m_Symbol, m_EntryTimeframe, m_EmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA_Fast == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize Fast EMA: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleEMA_Trend = iMA(m_Symbol, m_EntryTimeframe, m_EmaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if (m_HandleEMA_Trend == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize Trend EMA: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleRSI = iRSI(m_Symbol, m_EntryTimeframe, 14, PRICE_CLOSE);
   if (m_HandleRSI == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize RSI: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleMACD = iMACD(m_Symbol, m_EntryTimeframe, 12, 26, 9, PRICE_CLOSE);
   if (m_HandleMACD == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize MACD: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleBB = iBands(m_Symbol, m_EntryTimeframe, 20, 0, 2, PRICE_CLOSE);
   if (m_HandleBB == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize Bollinger Bands: " + IntegerToString(GetLastError()));
      return false;
   }
   
   m_HandleADX = iADX(m_Symbol, m_EntryTimeframe, 14);
   if (m_HandleADX == INVALID_HANDLE) {
      m_Logger.LogError("Failed to initialize ADX: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Initialize higher timeframe indicators if needed
   if (m_UseMultiTimeframe) {
      m_HandleATR_Higher = iATR(m_Symbol, m_HigherTimeframe, m_ATRPeriod);
      if (m_HandleATR_Higher == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Higher ATR: " + IntegerToString(GetLastError()));
         return false;
      }
      
      m_HandleEMA_Fast_Higher = iMA(m_Symbol, m_HigherTimeframe, m_EmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (m_HandleEMA_Fast_Higher == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Higher Fast EMA: " + IntegerToString(GetLastError()));
         return false;
      }
      
      m_HandleEMA_Trend_Higher = iMA(m_Symbol, m_HigherTimeframe, m_EmaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (m_HandleEMA_Trend_Higher == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Higher Trend EMA: " + IntegerToString(GetLastError()));
         return false;
      }
   }
   
   // Initialize nested timeframe indicators if needed
   if (m_UseNestedTimeframe) {
      m_HandleATR_Nested = iATR(m_Symbol, m_NestedTimeframe, m_ATRPeriod);
      if (m_HandleATR_Nested == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Nested ATR: " + IntegerToString(GetLastError()));
         return false;
      }
      
      m_HandleEMA_Fast_Nested = iMA(m_Symbol, m_NestedTimeframe, m_EmaFastPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (m_HandleEMA_Fast_Nested == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Nested Fast EMA: " + IntegerToString(GetLastError()));
         return false;
      }
      
      m_HandleEMA_Trend_Nested = iMA(m_Symbol, m_NestedTimeframe, m_EmaTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if (m_HandleEMA_Trend_Nested == INVALID_HANDLE) {
         m_Logger.LogError("Failed to initialize Nested Trend EMA: " + IntegerToString(GetLastError()));
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::ReleaseIndicators()
{
   // Release entry timeframe indicators
   if (m_HandleATR != INVALID_HANDLE) {
      IndicatorRelease(m_HandleATR);
      m_HandleATR = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Fast != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Fast);
      m_HandleEMA_Fast = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Trend != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Trend);
      m_HandleEMA_Trend = INVALID_HANDLE;
   }
   
   if (m_HandleRSI != INVALID_HANDLE) {
      IndicatorRelease(m_HandleRSI);
      m_HandleRSI = INVALID_HANDLE;
   }
   
   if (m_HandleMACD != INVALID_HANDLE) {
      IndicatorRelease(m_HandleMACD);
      m_HandleMACD = INVALID_HANDLE;
   }
   
   if (m_HandleBB != INVALID_HANDLE) {
      IndicatorRelease(m_HandleBB);
      m_HandleBB = INVALID_HANDLE;
   }
   
   if (m_HandleADX != INVALID_HANDLE) {
      IndicatorRelease(m_HandleADX);
      m_HandleADX = INVALID_HANDLE;
   }
   
   // Release higher timeframe indicators
   if (m_HandleATR_Higher != INVALID_HANDLE) {
      IndicatorRelease(m_HandleATR_Higher);
      m_HandleATR_Higher = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Fast_Higher != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Fast_Higher);
      m_HandleEMA_Fast_Higher = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Trend_Higher != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Trend_Higher);
      m_HandleEMA_Trend_Higher = INVALID_HANDLE;
   }
   
   // Release nested timeframe indicators
   if (m_HandleATR_Nested != INVALID_HANDLE) {
      IndicatorRelease(m_HandleATR_Nested);
      m_HandleATR_Nested = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Fast_Nested != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Fast_Nested);
      m_HandleEMA_Fast_Nested = INVALID_HANDLE;
   }
   
   if (m_HandleEMA_Trend_Nested != INVALID_HANDLE) {
      IndicatorRelease(m_HandleEMA_Trend_Nested);
      m_HandleEMA_Trend_Nested = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Check if a new bar has formed                                    |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(m_Symbol, m_EntryTimeframe, 0);
   
   if (currentBarTime > lastBarTime) {
      lastBarTime = currentBarTime;
      return true;
   }
   
   return false;
}

//+------------------------------------------------------------------+
//| Update all indicator data safely                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::UpdateIndicatorData()
{
   // Only update on new bar or first call
   m_IsNewBar = IsNewBar() || m_LastUpdateTime == 0;
   
   if (!m_IsNewBar && m_LastUpdateTime > 0) {
      // No need to update on every tick, we use cached values
      return true;
   }
   
   // Store previous values before updating
   m_Cache.rsi_prev = m_Cache.rsi;
   
   // Update price data
   double open[], high[], low[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if (!SafeCopyRates(m_Symbol, m_EntryTimeframe, 0, 3, open, high, low, close)) {
      m_Logger.LogError("Failed to copy price data: " + IntegerToString(GetLastError()));
      return false;
   }
   
   // Update price cache
   m_Cache.close = close[0];
   m_Cache.open = open[0];
   m_Cache.high = high[0];
   m_Cache.low = low[0];
   m_Cache.prev_close = close[1];
   
   // Update time
   datetime times[];
   ArraySetAsSeries(times, true);
   if (SafeCopyTime(m_Symbol, m_EntryTimeframe, 0, 1, times)) {
      TimeToStruct(times[0], m_Cache.time);
   }
   
   // Update entry timeframe indicators
   double buffer[];
   ArraySetAsSeries(buffer, true);
   
   // ATR
   if (SafeCopyBuffer(m_HandleATR, 0, 0, 1, buffer)) {
      m_Cache.atr_entry = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update ATR data: " + IntegerToString(GetLastError()));
   }
   
   // EMA Fast
   if (SafeCopyBuffer(m_HandleEMA_Fast, 0, 0, 1, buffer)) {
      m_Cache.ema_fast_entry = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update Fast EMA data: " + IntegerToString(GetLastError()));
   }
   
   // EMA Trend
   if (SafeCopyBuffer(m_HandleEMA_Trend, 0, 0, 1, buffer)) {
      m_Cache.ema_trend_entry = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update Trend EMA data: " + IntegerToString(GetLastError()));
   }
   
   // RSI
   if (SafeCopyBuffer(m_HandleRSI, 0, 0, 1, buffer)) {
      m_Cache.rsi = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update RSI data: " + IntegerToString(GetLastError()));
   }
   
   // MACD (Main line)
   if (SafeCopyBuffer(m_HandleMACD, 0, 0, 1, buffer)) {
      m_Cache.macd = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update MACD Main data: " + IntegerToString(GetLastError()));
   }
   
   // MACD (Signal line)
   if (SafeCopyBuffer(m_HandleMACD, 1, 0, 1, buffer)) {
      m_Cache.macd_signal = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update MACD Signal data: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Upper)
   if (SafeCopyBuffer(m_HandleBB, 1, 0, 1, buffer)) {
      m_Cache.bb_upper = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update BB Upper data: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Middle)
   if (SafeCopyBuffer(m_HandleBB, 0, 0, 1, buffer)) {
      m_Cache.bb_middle = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update BB Middle data: " + IntegerToString(GetLastError()));
   }
   
   // Bollinger Bands (Lower)
   if (SafeCopyBuffer(m_HandleBB, 2, 0, 1, buffer)) {
      m_Cache.bb_lower = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update BB Lower data: " + IntegerToString(GetLastError()));
   }
   
   // ADX
   if (SafeCopyBuffer(m_HandleADX, 0, 0, 1, buffer)) {
      m_Cache.adx = buffer[0];
   } else {
      m_Logger.LogWarning("Failed to update ADX data: " + IntegerToString(GetLastError()));
   }
   
   // Update higher timeframe indicators if enabled
   if (m_UseMultiTimeframe) {
      // Higher ATR
      if (SafeCopyBuffer(m_HandleATR_Higher, 0, 0, 1, buffer)) {
         m_Cache.atr_higher = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Higher ATR data: " + IntegerToString(GetLastError()));
      }
      
      // Higher EMA Fast
      if (SafeCopyBuffer(m_HandleEMA_Fast_Higher, 0, 0, 1, buffer)) {
         m_Cache.ema_fast_higher = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Higher Fast EMA data: " + IntegerToString(GetLastError()));
      }
      
      // Higher EMA Trend
      if (SafeCopyBuffer(m_HandleEMA_Trend_Higher, 0, 0, 1, buffer)) {
         m_Cache.ema_trend_higher = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Higher Trend EMA data: " + IntegerToString(GetLastError()));
      }
   }
   
   // Update nested timeframe indicators if enabled
   if (m_UseNestedTimeframe) {
      // Nested ATR
      if (SafeCopyBuffer(m_HandleATR_Nested, 0, 0, 1, buffer)) {
         m_Cache.atr_nested = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Nested ATR data: " + IntegerToString(GetLastError()));
      }
      
      // Nested EMA Fast
      if (SafeCopyBuffer(m_HandleEMA_Fast_Nested, 0, 0, 1, buffer)) {
         m_Cache.ema_fast_nested = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Nested Fast EMA data: " + IntegerToString(GetLastError()));
      }
      
      // Nested EMA Trend
      if (SafeCopyBuffer(m_HandleEMA_Trend_Nested, 0, 0, 1, buffer)) {
         m_Cache.ema_trend_nested = buffer[0];
      } else {
         m_Logger.LogWarning("Failed to update Nested Trend EMA data: " + IntegerToString(GetLastError()));
      }
   }
   
   m_LastUpdateTime = TimeCurrent();
   return true;
}

//+------------------------------------------------------------------+
//| Safe method to copy indicator buffer with error handling         |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[])
{
   // Ensure handle is valid
   if (handle == INVALID_HANDLE) {
      return false;
   }
   
   // Resize array to avoid buffer overflow
   ArrayResize(array, count);
   
   // Copy buffer with retry once
   int copied = CopyBuffer(handle, buffer, startPos, count, array);
   if (copied <= 0) {
      // First attempt failed, reset error and try once more
      ResetLastError();
      Sleep(5);  // Small delay
      copied = CopyBuffer(handle, buffer, startPos, count, array);
   }
   
   return (copied == count);
}

//+------------------------------------------------------------------+
//| Safe method to copy price data with error handling               |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyRates(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, 
                               double &open[], double &high[], double &low[], double &close[])
{
   // Resize arrays to avoid buffer overflow
   ArrayResize(open, count);
   ArrayResize(high, count);
   ArrayResize(low, count);
   ArrayResize(close, count);
   
   // Copy rates with retry once
   int copied = 0;
   
   copied = CopyOpen(symbol, timeframe, startPos, count, open);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyOpen(symbol, timeframe, startPos, count, open);
      if (copied <= 0) return false;
   }
   
   copied = CopyHigh(symbol, timeframe, startPos, count, high);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyHigh(symbol, timeframe, startPos, count, high);
      if (copied <= 0) return false;
   }
   
   copied = CopyLow(symbol, timeframe, startPos, count, low);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyLow(symbol, timeframe, startPos, count, low);
      if (copied <= 0) return false;
   }
   
   copied = CopyClose(symbol, timeframe, startPos, count, close);
   if (copied <= 0) {
      ResetLastError();
      Sleep(5);
      copied = CopyClose(symbol, timeframe, startPos, count, close);
      if (copied <= 0) return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Safe method to copy time data with error handling                |
//+------------------------------------------------------------------+
bool CMarketMonitor::SafeCopyTime(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, datetime &time[])
{
   // Resize array to avoid buffer overflow
   ArrayResize(time, count);
   
   // Copy time with retry once
   int copied = CopyTime(symbol, timeframe, startPos, count, time);
   if (copied <= 0) {
      // First attempt failed, reset error and try once more
      ResetLastError();
      Sleep(5);  // Small delay
      copied = CopyTime(symbol, timeframe, startPos, count, time);
   }
   
   return (copied == count);
}

//+------------------------------------------------------------------+
//| Main update method - updates all data and analyzes market        |
//+------------------------------------------------------------------+
bool CMarketMonitor::Update()
{
   if (!m_IsInitialized) {
      m_Logger.LogError("Market Monitor not initialized");
      return false;
   }
   
   // Update indicator data
   if (!UpdateIndicatorData()) {
      m_Logger.LogWarning("Failed to update indicator data");
      return false;
   }
   
   // Update market state if it's a new bar
   if (m_IsNewBar) {
      if (!UpdateMarketState()) {
         m_Logger.LogWarning("Failed to update market state");
         return false;
      }
      
      // Log market state on new bar for debugging
      if (m_Logger.IsDebugEnabled()) {
         string regime = "";
         switch(m_MarketRegime) {
            case REGIME_STRONG_TREND: regime = "Strong Trend"; break;
            case REGIME_WEAK_TREND:   regime = "Weak Trend";   break;
            case REGIME_RANGING:      regime = "Ranging";      break;
            case REGIME_VOLATILE:     regime = "Volatile";     break;
         }
         
         string trend = m_IsTrendUp ? "Up" : (m_IsTrendDown ? "Down" : "Neutral");
         
         m_Logger.LogDebug(StringFormat("[%s] Market State: %s, Trend: %s, ATR: %.5f, RSI: %.1f, ADX: %.1f", 
                                     m_Symbol, regime, trend, m_Cache.atr_entry, m_Cache.rsi, m_Cache.adx));
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Update market state (regime and trend)                           |
//+------------------------------------------------------------------+
bool CMarketMonitor::UpdateMarketState()
{
   // Analyze market regime
   AnalyzeMarketRegime();
   
   // Analyze trend direction
   AnalyzeTrendDirection();
   
   // Analyze volatility
   AnalyzeVolatility();
   
   return true;
}

//+------------------------------------------------------------------+
//| Analyze current market regime                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeMarketRegime()
{
   // Default to ranging
   m_MarketRegime = REGIME_RANGING;
   
   // Check ADX for trend strength
   double adx = m_Cache.adx;
   
   // Check Bollinger Band width for volatility/compression
   double bbWidth = (m_Cache.bb_upper - m_Cache.bb_lower) / m_Cache.bb_middle;
   
   // Strong trend
   if (adx > 30) {
      m_MarketRegime = REGIME_STRONG_TREND;
   }
   // Weak trend
   else if (adx > 20) {
      m_MarketRegime = REGIME_WEAK_TREND;
   }
   // Volatile (wide BB bands)
   else if (bbWidth > m_VolatilityThreshold) {
      m_MarketRegime = REGIME_VOLATILE;
   }
   // Ranging (narrow BB bands)
   else if (bbWidth < m_RangeThreshold) {
      m_MarketRegime = REGIME_RANGING;
   }
}

//+------------------------------------------------------------------+
//| Analyze current trend direction                                  |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeTrendDirection()
{
   // Check EMA alignment for trend direction
   double emaFast = m_Cache.ema_fast_entry;
   double emaTrend = m_Cache.ema_trend_entry;
   double currentClose = m_Cache.close;
   
   m_IsTrendUp = false;
   m_IsTrendDown = false;
   
   // Check uptrend conditions
   if (emaFast > emaTrend && currentClose > emaFast) {
      m_IsTrendUp = true;
   }
   // Check downtrend conditions
   else if (emaFast < emaTrend && currentClose < emaFast) {
      m_IsTrendDown = true;
   }
}

//+------------------------------------------------------------------+
//| Analyze market volatility                                        |
//+------------------------------------------------------------------+
void CMarketMonitor::AnalyzeVolatility()
{
   // Calculate volatility indicators
   double bbWidth = (m_Cache.bb_upper - m_Cache.bb_lower) / m_Cache.bb_middle;
   
   // Check for high volatility
   m_IsVolatile = (bbWidth > m_VolatilityThreshold);
   
   // Check for range-bound market
   m_IsRangebound = (bbWidth < m_RangeThreshold);
}

//+------------------------------------------------------------------+
//| Check for entry signals and fill signal info                     |
//+------------------------------------------------------------------+
bool CMarketMonitor::CheckEntrySignal(SignalInfo &signal)
{
   // Reset signal info
   ZeroMemory(signal);
   
   // Determine default signal direction based on trend
   bool tryLong = m_IsTrendUp || (!m_IsTrendDown && m_Cache.ema_fast_entry > m_Cache.ema_trend_entry);
   bool tryShort = m_IsTrendDown || (!m_IsTrendUp && m_Cache.ema_fast_entry < m_Cache.ema_trend_entry);
   
   // Skip signal generation if market regime filter is enabled and we're in ranging market
   if (m_EnableMarketRegimeFilter && m_MarketRegime == REGIME_RANGING) {
      m_Logger.LogDebug("Skipping signal generation due to ranging market");
      return false;
   }
   
   // Variables to track best signal
   double bestQuality = 0;
   bool foundSignal = false;
   
   // Try all signal types and keep the highest quality one
   // This avoids having duplicate code for long/short in each detection method
   
   //--- 1. Try Pullback signals
   if ((tryLong || tryShort) && (m_MarketRegime == REGIME_STRONG_TREND || m_MarketRegime == REGIME_WEAK_TREND)) {
      double depth, speed, strength;
      double entryPrice, stopLevel;
      string description;
      
      // Try long pullback
      if (tryLong && AnalyzePullback(true, depth, speed, strength, entryPrice, stopLevel, description)) {
         double quality = 0.5 + (strength * 0.3) + (speed * 0.2);
         
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice + ((entryPrice - stopLevel) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_BULLISH_PULLBACK;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short pullback
      if (tryShort && AnalyzePullback(false, depth, speed, strength, entryPrice, stopLevel, description)) {
         double quality = 0.5 + (strength * 0.3) + (speed * 0.2);
         
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice - ((stopLevel - entryPrice) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_BEARISH_PULLBACK;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   //--- 2. Try Fibonacci Pullback signals
   if ((tryLong || tryShort) && (m_MarketRegime != REGIME_VOLATILE)) {
      double entryLevels[];
      double quality;
      
      // Try long Fibonacci pullback
      if (tryLong && DetectFibonacciPullback(true, entryLevels, quality)) {
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = m_Cache.close; // Current price
            signal.stopLoss = entryLevels[0] - (m_Cache.atr_entry * 0.5); // Below the lowest fib level
            signal.takeProfit = entryLevels[4] + (m_Cache.atr_entry * 0.5); // Above the highest fib level
            signal.scenario = SCENARIO_FIBONACCI_PULLBACK;
            signal.quality = quality;
            signal.description = "Fibonacci Pullback (Bullish)";
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short Fibonacci pullback
      if (tryShort && DetectFibonacciPullback(false, entryLevels, quality)) {
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = m_Cache.close; // Current price
            signal.stopLoss = entryLevels[0] + (m_Cache.atr_entry * 0.5); // Above the highest fib level
            signal.takeProfit = entryLevels[4] - (m_Cache.atr_entry * 0.5); // Below the lowest fib level
            signal.scenario = SCENARIO_FIBONACCI_PULLBACK;
            signal.quality = quality;
            signal.description = "Fibonacci Pullback (Bearish)";
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   //--- 3. Try Harmonic Pattern signals
   if ((tryLong || tryShort)) {
      double entryLevel, stopLevel, quality;
      string patternName;
      
      // Try long harmonic pattern
      if (tryLong && DetectHarmonicPatterns(true, entryLevel, stopLevel, quality, patternName)) {
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = entryLevel;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryLevel + ((entryLevel - stopLevel) * 2.5); // Generous RR for harmonic
            signal.scenario = SCENARIO_HARMONIC_PATTERN;
            signal.quality = quality;
            signal.description = "Harmonic Pattern: " + patternName + " (Bullish)";
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short harmonic pattern
      if (tryShort && DetectHarmonicPatterns(false, entryLevel, stopLevel, quality, patternName)) {
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = entryLevel;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryLevel - ((stopLevel - entryLevel) * 2.5); // Generous RR for harmonic
            signal.scenario = SCENARIO_HARMONIC_PATTERN;
            signal.quality = quality;
            signal.description = "Harmonic Pattern: " + patternName + " (Bearish)";
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   //--- 4. Try Momentum Shift signals
   if ((tryLong || tryShort)) {
      double entryPrice, stopLevel, quality;
      string description;
      
      // Try long momentum shift
      if (tryLong && DetectMomentumShift(true, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice + ((entryPrice - stopLevel) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_MOMENTUM_SHIFT;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short momentum shift
      if (tryShort && DetectMomentumShift(false, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice - ((stopLevel - entryPrice) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_MOMENTUM_SHIFT;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   //--- 5. Try Liquidity Grab signals
   if ((tryLong || tryShort) && m_MarketRegime != REGIME_RANGING) {
      double entryPrice, stopLevel, quality;
      string description;
      
      // Try long liquidity grab
      if (tryLong && DetectLiquidityGrab(true, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice + ((entryPrice - stopLevel) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_LIQUIDITY_GRAB;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short liquidity grab
      if (tryShort && DetectLiquidityGrab(false, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice - ((stopLevel - entryPrice) * 2); // Simple 1:2 RR for now
            signal.scenario = SCENARIO_LIQUIDITY_GRAB;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   //--- 6. Try Breakout Failure signals
   if ((tryLong || tryShort)) {
      double entryPrice, stopLevel, quality;
      string description;
      
      // Try long breakout failure
      if (tryLong && DetectBreakoutFailure(true, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = true;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice + ((entryPrice - stopLevel) * 1.5); // Conservative RR for failures
            signal.scenario = SCENARIO_BREAKOUT_FAILURE;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
      
      // Try short breakout failure
      if (tryShort && DetectBreakoutFailure(false, entryPrice, stopLevel, quality, description)) {
         if (quality > bestQuality) {
            signal.isLong = false;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLevel;
            signal.takeProfit = entryPrice - ((stopLevel - entryPrice) * 1.5); // Conservative RR for failures
            signal.scenario = SCENARIO_BREAKOUT_FAILURE;
            signal.quality = quality;
            signal.description = description;
            bestQuality = quality;
            foundSignal = true;
         }
      }
   }
   
   // Store the last signal if found
   if (foundSignal) {
      m_LastSignal = signal;
      
      // Log signal detection
      m_Logger.LogInfo(StringFormat("[%s] %s signal detected: %s (Quality: %.2f)", 
                                  m_Symbol,
                                  signal.isLong ? "Long" : "Short",
                                  signal.description,
                                  signal.quality));
   }
   
   return foundSignal;
}

//+------------------------------------------------------------------+
//| Generate trade signals for the EA                                |
//+------------------------------------------------------------------+
ENUM_TRADE_SIGNAL CMarketMonitor::GenerateSignals(double &entryPrice, double &stopLoss, double &takeProfit, 
                                               ENUM_ENTRY_SCENARIO &scenario)
{
   // Reset output parameters
   entryPrice = 0;
   stopLoss = 0;
   takeProfit = 0;
   scenario = SCENARIO_NONE;
   
   // Check for entry signal
   SignalInfo signal;
   if (!CheckEntrySignal(signal)) {
      return TRADE_SIGNAL_NONE;
   }
   
   // Set output parameters from the signal
   entryPrice = signal.entryPrice;
   stopLoss = signal.stopLoss;
   takeProfit = signal.takeProfit;
   scenario = signal.scenario;
   
   // Return appropriate trade signal
   return signal.isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
}

//+------------------------------------------------------------------+
//| Calculate volatility factor for lot size adjustment              |
//+------------------------------------------------------------------+
double CMarketMonitor::GetVolatilityFactor() const
{
   if (m_Cache.atr_entry <= 0) return 1.0; // Safety check
   
   // Get historical ATR for comparison
   double atrArray[];
   ArraySetAsSeries(atrArray, true);
   
   if (CopyBuffer(m_HandleATR, 0, 0, 50, atrArray) <= 0) {
      return 1.0; // Default if can't get data
   }
   
   // Calculate average ATR over last 20 bars
   double avgAtr = 0;
   int count = 0;
   
   for (int i = 10; i < 30 && i < ArraySize(atrArray); i++) {
      if (atrArray[i] > 0) {
         avgAtr += atrArray[i];
         count++;
      }
   }
   
   if (count == 0) return 1.0; // Safety check
   
   avgAtr /= count;
   
   // Calculate volatility factor
   double factor = m_Cache.atr_entry / avgAtr;
   
   // Square root to dampen extreme values
   factor = MathSqrt(factor);
   
   // Limit to reasonable range
   factor = MathMax(0.5, MathMin(factor, 3.5));
   
   return factor;
}

//+------------------------------------------------------------------+
//| Find highest high since a specific bar                          |
//+------------------------------------------------------------------+
double CMarketMonitor::GetHighestHighSinceBar(int startBar, int lookback)
{
   double high[];
   ArraySetAsSeries(high, true);
   
   // Ensure we get enough data
   int bars = startBar + lookback;
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, bars, high) <= 0) {
      return 0; // Return 0 if failed to get data
   }
   
   // Find highest value in the range
   double highestHigh = high[startBar];
   for (int i = startBar; i < startBar + lookback && i < ArraySize(high); i++) {
      if (high[i] > highestHigh) {
         highestHigh = high[i];
      }
   }
   
   return highestHigh;
}

//+------------------------------------------------------------------+
//| Find lowest low since a specific bar                            |
//+------------------------------------------------------------------+
double CMarketMonitor::GetLowestLowSinceBar(int startBar, int lookback)
{
   double low[];
   ArraySetAsSeries(low, true);
   
   // Ensure we get enough data
   int bars = startBar + lookback;
   if (CopyLow(m_Symbol, m_EntryTimeframe, 0, bars, low) <= 0) {
      return 0; // Return 0 if failed to get data
   }
   
   // Find lowest value in the range
   double lowestLow = low[startBar];
   for (int i = startBar; i < startBar + lookback && i < ArraySize(low); i++) {
      if (low[i] < lowestLow) {
         lowestLow = low[i];
      }
   }
   
   return lowestLow;
}

//+------------------------------------------------------------------+
//| Get the last generated signal                                   |
//+------------------------------------------------------------------+
bool CMarketMonitor::GetLastSignal(SignalInfo &signal)
{
   // Check if there is a last signal
   if (m_LastSignal.scenario == SCENARIO_NONE) {
      return false;
   }
   
   // Copy the last signal
   signal = m_LastSignal;
   return true;
}

//+------------------------------------------------------------------+
//| Signal feedback from Trade Manager to Market Monitor             |
//+------------------------------------------------------------------+
void CMarketMonitor::FeedbackSignalResult(SignalInfo &signal, bool success, ulong ticket, string failReason)
{
   // Store signal result for learning and analysis
   if (success) {
      m_Logger.LogInfo(StringFormat("Signal execution successful: Ticket #%d, %s", 
                                 ticket, signal.description));
   } else {
      m_Logger.LogWarning(StringFormat("Signal execution failed: %s, Reason: %s", 
                                     signal.description, failReason));
   }
   
   // Future enhancement: Adapt parameters based on success rate
}

//+------------------------------------------------------------------+
//| Set pullback detection parameters                                |
//+------------------------------------------------------------------+
void CMarketMonitor::SetPullbackParameters(double minDepth, double maxDepth, double minBounce, double maxBounce)
{
   m_MinPullbackDepth = minDepth;
   m_MaxPullbackDepth = maxDepth;
   m_MinBounceStrength = minBounce;
   m_MaxBounceStrength = maxBounce;
}

//+------------------------------------------------------------------+
//| Set Fibonacci detection parameters                               |
//+------------------------------------------------------------------+
void CMarketMonitor::SetFibonacciParameters(double nearThreshold, double goldenBonus, double minImpulseSize)
{
   m_FibonacciNearThreshold = nearThreshold;
   m_GoldenZoneBonus = goldenBonus;
   m_FibMinImpulseSize = minImpulseSize;
}

//+------------------------------------------------------------------+
//| Set harmonic pattern parameters                                  |
//+------------------------------------------------------------------+
void CMarketMonitor::SetHarmonicParameters(double tolerance)
{
   m_HarmonicTolerance = tolerance;
}

//+------------------------------------------------------------------+
//| Set momentum shift parameters                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::SetMomentumParameters(int lookback)
{
   m_MomentumLookback = lookback;
}

//+------------------------------------------------------------------+
//| Set liquidity grab parameters                                    |
//+------------------------------------------------------------------+
void CMarketMonitor::SetLiquidityGrabParameters(double minWickRatio, double minVolumeRatio)
{
   m_MinWickRatio = minWickRatio;
   m_MinVolumeRatio = minVolumeRatio;
}

//+------------------------------------------------------------------+
//| Set breakout failure parameters                                  |
//+------------------------------------------------------------------+
void CMarketMonitor::SetBreakoutParameters(double minSize)
{
   m_MinBreakoutSize = minSize;
}

//+------------------------------------------------------------------+
//| AnalyzePullback Implementation                                   |
//+------------------------------------------------------------------+
bool CMarketMonitor::AnalyzePullback(bool isUptrend, double &depth, double &speed, double &strength,
                                   double &entryPrice, double &stopLevel, string &description)
{
   // Implementation as provided in the original code, but with safety checks
   // and using cached data where possible
   
   // Khởi tạo giá trị mặc định
   depth = 0; speed = 0; strength = 0;
   entryPrice = 0; stopLevel = 0; 
   description = "";
   
   // Verify that we have valid ATR
   double atr = m_Cache.atr_entry;
   if (atr <= 0) {
      m_Logger.LogDebug("ATR không hợp lệ cho phân tích pullback");
      return false;
   }
   
   // Lấy dữ liệu giá lịch sử - với retry an toàn
   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   int MAX_LOOKBACK = 50;  // Số nến tối đa để tìm sóng đẩy và pullback
   
   if (!SafeCopyRates(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, open, high, low, close)) {
      m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích pullback");
      return false;
   }
   
   // BƯỚC 1: Tìm swing (điểm đảo chiều) gần nhất trên pullback
   int swingBar = 0;
   double swingPrice = 0;
   
   if (isUptrend) {
      // Trong xu hướng tăng, tìm đáy gần nhất (local minimum)
      for (int i = 3; i < MAX_LOOKBACK - 3; i++) {
         // Đáy khi low[i] thấp hơn cả 2 nến trước và 2 nến sau
         if (low[i] < low[i-1] && low[i] < low[i-2] && 
             low[i] < low[i+1] && low[i] < low[i+2]) {
            swingBar = i;
            swingPrice = low[i];
            break;
         }
      }
   } else {
      // Trong xu hướng giảm, tìm đỉnh gần nhất (local maximum)
      for (int i = 3; i < MAX_LOOKBACK - 3; i++) {
         // Đỉnh khi high[i] cao hơn cả 2 nến trước và 2 nến sau
         if (high[i] > high[i-1] && high[i] > high[i-2] && 
             high[i] > high[i+1] && high[i] > high[i+2]) {
            swingBar = i;
            swingPrice = high[i];
            break;
         }
      }
   }
   
   // Kiểm tra nếu không tìm thấy swing
   if (swingBar <= 0 || swingPrice <= 0) {
      m_Logger.LogDebug("Không tìm thấy swing rõ ràng cho pullback");
      return false;
   }
   
   // BƯỚC 2: Tìm đỉnh/đáy của sóng trước pullback (điểm bắt đầu sóng)
   int impulseStartBar = 0;
   double impulseStartPrice = 0;
   
   if (isUptrend) {
      // Tìm đỉnh trước đáy (swing low) - đây là điểm BẮT ĐẦU của pullback
      for (int i = swingBar + 1; i < MAX_LOOKBACK - 2; i++) {
         if (high[i] > high[i-1] && high[i] > high[i+1]) {
            impulseStartBar = i;
            impulseStartPrice = high[i];
            break;
         }
      }
   } else {
      // Tìm đáy trước đỉnh (swing high) - đây là điểm BẮT ĐẦU của pullback
      for (int i = swingBar + 1; i < MAX_LOOKBACK - 2; i++) {
         if (low[i] < low[i-1] && low[i] < low[i+1]) {
            impulseStartBar = i;
            impulseStartPrice = low[i];
            break;
         }
      }
   }
   
   // Kiểm tra nếu không tìm thấy điểm bắt đầu
   if (impulseStartBar <= 0 || impulseStartPrice <= 0) {
      m_Logger.LogDebug("Không tìm thấy điểm bắt đầu sóng trước pullback");
      return false;
   }
   
   // BƯỚC 3: Tính các thông số của pullback
   
   // Tính độ sâu pullback - tỷ lệ pullback so với sóng đẩy ban đầu
   double impulseRange = MathAbs(impulseStartPrice - swingPrice);
   
   // Độ sâu pullback: Tương quan với ATR (bao nhiêu lần ATR)
   depth = impulseRange / atr;
   
   // Tốc độ: Dựa trên số lượng nến hình thành pullback
   speed = 1.0 / (swingBar + 1);  // Càng ít nến, tốc độ càng cao
   
   // Sức mạnh hồi phục: Tính từ đáy/đỉnh pullback đến giá hiện tại
   double currentPrice = close[0];
   double bounceRange = MathAbs(currentPrice - swingPrice);
   strength = bounceRange / impulseRange;  // Tỷ lệ phục hồi (0-1+)
   
   // BƯỚC 4: Kiểm tra các điều kiện pullback chất lượng
   
   // Kiểm tra nếu pullback có độ sâu hợp lý
   if (depth < m_MinPullbackDepth || depth > m_MaxPullbackDepth) {
      m_Logger.LogDebug(StringFormat("Độ sâu pullback không phù hợp: %.2f ATR", depth));
      return false;
   }
   
   // Kiểm tra nếu đã có hồi phục từ pullback (để tránh vào lệnh quá sớm)
   if (strength < m_MinBounceStrength || strength > m_MaxBounceStrength) {
      m_Logger.LogDebug(StringFormat("Sức mạnh hồi phục không phù hợp: %.2f", strength));
      return false;
   }
   
   // BƯỚC 5: Kiểm tra pullback có nằm trong vùng EMA không
   bool nearEMA = false;
   double emaDistance = 0;
   
   if (isUptrend) {
      emaDistance = MathAbs(swingPrice - m_Cache.ema_fast_entry) / atr;
      nearEMA = (emaDistance < 0.5);  // Đáy pullback gần với EMA nhanh
   } else {
      emaDistance = MathAbs(swingPrice - m_Cache.ema_fast_entry) / atr;
      nearEMA = (emaDistance < 0.5);  // Đỉnh pullback gần với EMA nhanh
   }
   
   // BƯỚC 6: Thiết lập thông tin cho giao dịch
   entryPrice = close[0];  // Vào lệnh tại giá hiện tại
   
   // Đặt stop loss dựa trên swing point với buffer ATR
   if (isUptrend) {
      stopLevel = swingPrice - (atr * 0.3);
   } else {
      stopLevel = swingPrice + (atr * 0.3);
   }
   
   // Tạo mô tả chi tiết
   string emaInfo = nearEMA ? " gần EMA" : "";
   string trendDir = isUptrend ? "Tăng" : "Giảm";
   description = StringFormat("Pullback %s: Độ sâu %.1f ATR, Hồi phục %.0f%%%s", 
                            trendDir, depth, strength * 100, emaInfo);
   
   m_Logger.LogInfo("Phát hiện pullback chất lượng: " + description);
   
   return true;
}

//+------------------------------------------------------------------+
//| DetectFibonacciPullback Implementation                          |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectFibonacciPullback(bool isUptrend, double &entryLevels[], double &qualityScore)
{
   // Initialize return values
   qualityScore = 0;
   ArrayResize(entryLevels, 5); // 5 potential Fibonacci levels
   ArrayInitialize(entryLevels, 0);
   
   // Get ATR for relative measurements
   double atr = m_Cache.atr_entry;
   if (atr <= 0) {
      m_Logger.LogDebug("Invalid ATR for Fibonacci analysis");
      return false;
   }
   
   // Define Fibonacci levels
   double FIB_LEVELS[] = {0.236, 0.382, 0.5, 0.618, 0.786};
   int FIB_COUNT = ArraySize(FIB_LEVELS);
   
   // Get price data with safety checks
   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   int MAX_LOOKBACK = 100; // Maximum bars to analyze
   
   if (!SafeCopyRates(m_Symbol, m_EntryTimeframe, 0, MAX_LOOKBACK, open, high, low, close)) {
      m_Logger.LogError("Failed to copy price data for Fibonacci analysis");
      return false;
   }
   
   // Find significant swing points using a simple ZigZag-like algorithm
   double swingThreshold = atr * 0.5; // Minimum movement to qualify as a swing
   
   // Arrays to store swing points
   double swingPrices[];
   int swingBars[];
   bool swingTypes[]; // true = high, false = low
   int swingCount = 0;
   
   // Find all swing points (zigzag) within the lookback range
   for (int i = 2; i < MAX_LOOKBACK - 2; i++) {
      // Find local tops
      if (high[i] > high[i-1] && high[i] > high[i-2] && 
          high[i] > high[i+1] && high[i] > high[i+2]) {
         
         // Only accept swing if magnitude is sufficient compared to previous swing
         if (swingCount == 0 || MathAbs(high[i] - swingPrices[swingCount-1]) >= swingThreshold) {
            ArrayResize(swingPrices, swingCount + 1);
            ArrayResize(swingBars, swingCount + 1);
            ArrayResize(swingTypes, swingCount + 1);
            
            swingPrices[swingCount] = high[i];
            swingBars[swingCount] = i;
            swingTypes[swingCount] = true; // high
            swingCount++;
         }
      }
      
      // Find local bottoms
      if (low[i] < low[i-1] && low[i] < low[i-2] && 
          low[i] < low[i+1] && low[i] < low[i+2]) {
         
         // Only accept swing if magnitude is sufficient compared to previous swing
         if (swingCount == 0 || MathAbs(low[i] - swingPrices[swingCount-1]) >= swingThreshold) {
            ArrayResize(swingPrices, swingCount + 1);
            ArrayResize(swingBars, swingCount + 1);
            ArrayResize(swingTypes, swingCount + 1);
            
            swingPrices[swingCount] = low[i];
            swingBars[swingCount] = i;
            swingTypes[swingCount] = false; // low
            swingCount++;
         }
      }
   }
   
   // Check if we found enough swing points
   if (swingCount < 2) {
      m_Logger.LogDebug("Not enough swing points for Fibonacci analysis");
      return false;
   }
   
   // Find suitable swing pair for Fibonacci calculation
   int swingStartIdx = -1; 
   int swingEndIdx = -1;
   
   for (int i = 0; i < swingCount - 1; i++) {
      // For uptrend, need High->Low combo (peak->trough)
      if (isUptrend && swingTypes[i] == true && swingTypes[i+1] == false) {
         swingStartIdx = i;
         swingEndIdx = i+1;
         break;
      }
      // For downtrend, need Low->High combo (trough->peak)
      else if (!isUptrend && swingTypes[i] == false && swingTypes[i+1] == true) {
         swingStartIdx = i;
         swingEndIdx = i+1;
         break;
      }
   }
   
   // Check if we found a suitable swing pair
   if (swingStartIdx < 0 || swingEndIdx < 0) {
      m_Logger.LogDebug("No suitable swing pair found for Fibonacci analysis");
      return false;
   }
   
   // Get values and positions of swing points
   double swingStart = swingPrices[swingStartIdx];
   double swingEnd = swingPrices[swingEndIdx];
   int barStart = swingBars[swingStartIdx];
   int barEnd = swingBars[swingEndIdx];
   
   // Check age of pullback
   if (barEnd > 20) { // MAX_RETRACEMENT_AGE
      m_Logger.LogDebug(StringFormat("Pullback too old: %d bars", barEnd));
      return false;
   }
   
   // Calculate impulse wave size
   double impulseSize = MathAbs(swingStart - swingEnd);
   
   // Check impulse size
   if (impulseSize < atr * m_FibMinImpulseSize) {
      m_Logger.LogDebug(StringFormat("Impulse wave too small: %.2f ATR", impulseSize/atr));
      return false;
   }
   
   // Calculate Fibonacci levels
   for (int i = 0; i < FIB_COUNT; i++) {
      if (isUptrend) {
         // For uptrend: Calculate from peak down to trough, then retracement up
         entryLevels[i] = swingEnd + impulseSize * FIB_LEVELS[i];
      } else {
         // For downtrend: Calculate from trough up to peak, then retracement down
         entryLevels[i] = swingEnd - impulseSize * FIB_LEVELS[i];
      }
   }
   
   // Check if current price is near any Fibonacci level
   double currentPrice = close[0];
   int closestFibIdx = -1;
   double minDistance = 999999;
   
   for (int i = 0; i < FIB_COUNT; i++) {
      double distance = MathAbs(currentPrice - entryLevels[i]);
      if (distance < minDistance) {
         minDistance = distance;
         closestFibIdx = i;
      }
   }
   
   // Convert distance to ATR ratio
   double distanceInATR = minDistance / atr;
   
   // Check if price is not near any Fibonacci level
   if (distanceInATR > m_FibonacciNearThreshold || closestFibIdx < 0) {
      m_Logger.LogDebug(StringFormat("Current price not near any Fibonacci level (%.2f ATR)", distanceInATR));
      return false;
   }
   
   // Analyze Fibonacci trade quality
   
   // Base quality score
   qualityScore = 0.6;
   
   // Bonus for golden zone (0.382-0.618)
   if (closestFibIdx >= 1 && closestFibIdx <= 3) {
      qualityScore += m_GoldenZoneBonus;
   }
   
   // Bonus for precision
   qualityScore += (1.0 - (distanceInATR / m_FibonacciNearThreshold)) * 0.1;
   
   // Bonus if Fib retracement aligns with higher timeframe
   if (m_UseMultiTimeframe) {
      bool higherTFUptrend = (m_Cache.ema_fast_higher > m_Cache.ema_trend_higher);
      if (isUptrend == higherTFUptrend) {
         qualityScore += 0.1; // Alignment bonus
      }
   }
   
   // Check for price action confirmation
   bool hasPriceAction = false;
   
   if (isUptrend) {
      // Check for bullish reversal candle (e.g., hammer, bullish engulfing, etc.)
      double bodySize = MathAbs(close[1] - open[1]);
      double lowerWick = MathMin(close[1], open[1]) - low[1];
      
      // Hammer (lower wick at least 2x body)
      bool isHammer = (lowerWick > bodySize * 2 && close[1] > open[1]);
      
      // Bullish Engulfing
      bool isEngulfing = (close[1] > open[1] && close[2] < open[2] && 
                        open[1] < close[2] && close[1] > open[2]);
      
      // Bullish Pin Bar (lower wick at least 2/3 of total candle length)
      bool isPinBar = (lowerWick > (high[1] - low[1]) * 0.66);
      
      hasPriceAction = isHammer || isEngulfing || isPinBar;
      
      // Check if bouncing up from fib level
      bool isBouncingUp = (close[0] > close[1] && close[1] > close[2]);
      
      if (isBouncingUp) {
         hasPriceAction = true;
         qualityScore += 0.05;
      }
   } else {
      // Check for bearish reversal candle (e.g., shooting star, bearish engulfing, etc.)
      double bodySize = MathAbs(close[1] - open[1]);
      double upperWick = high[1] - MathMax(close[1], open[1]);
      
      // Shooting Star (upper wick at least 2x body)
      bool isShootingStar = (upperWick > bodySize * 2 && close[1] < open[1]);
      
      // Bearish Engulfing
      bool isEngulfing = (close[1] < open[1] && close[2] > open[2] && 
                        open[1] > close[2] && close[1] < open[2]);
      
      // Bearish Pin Bar (upper wick at least 2/3 of total candle length)
      bool isPinBar = (upperWick > (high[1] - low[1]) * 0.66);
      
      hasPriceAction = isShootingStar || isEngulfing || isPinBar;
      
      // Check if bouncing down from fib level
      bool isBouncingDown = (close[0] < close[1] && close[1] < close[2]);
      
      if (isBouncingDown) {
         hasPriceAction = true;
         qualityScore += 0.05;
      }
   }
   
   // Bonus for price action confirmation
   if (hasPriceAction) {
      qualityScore += 0.1;
   }
   
   // Limit quality to [0,1] range
   qualityScore = MathMin(qualityScore, 1.0);
   
   // Log detailed information
   string fibLevel = DoubleToString(FIB_LEVELS[closestFibIdx] * 100, 1) + "%";
   m_Logger.LogInfo(StringFormat("Detected Fibonacci %.1f%% Pullback, Quality: %.2f, PA: %s", 
                              FIB_LEVELS[closestFibIdx] * 100, 
                              qualityScore, 
                              hasPriceAction ? "Yes" : "No"));
   
   return true;
}

// Continue with implementations of other detection methods
// DetectHarmonicPatterns, DetectMomentumShift, DetectLiquidityGrab, DetectBreakoutFailure, etc.
// Implement these following the same pattern as above (proper error handling, using cached data where possible)