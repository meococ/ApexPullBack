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
   double               m_GoldenZoneBonus;      // Quality bonus for golden zone entries
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

   // Helper methods for identifying structures
   bool                 FindConsolidationZone(const double &high[], const double &low[], 
                                            double &zoneHigh, double &zoneLow, 
                                            int minConsolidationBars, int maxConsolidationBars);
   bool                 IsInRange(double value, double target, double tolerance);
   bool                 FindPivots(const double &high[], const double &low[], int maxBars,
                                  bool isUptrend, double &pivotHigh[], double &pivotLow[],
                                  int &pivotHighBar[], int &pivotLowBar[]);
   
   bool                 IsLocalTop(const double &high[], int index);
   bool                 IsLocalBottom(const double &low[], int index);
   
   // Signal feedback methods
   void                 FeedbackSignalResult(SignalInfo &signal, bool success, ulong ticket, string failReason = "");
   
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
   
   // Public methods for accessing indicator data
   double GetATR() const { return m_Cache.atr_entry; }
   double GetAverageATR() const { return m_Cache.atr_entry; } // Alias for compatibility
   
   // Main updating method
   bool                 Update();
   
   // Signal generation methods
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
   
   // Getters for market state and indicator data
   ENUM_MARKET_REGIME   GetMarketState() const { return m_MarketRegime; }
   bool                 IsTrendUp() const { return m_IsTrendUp; }
   bool                 IsTrendDown() const { return m_IsTrendDown; }
   double               GetEMAFast() const { return m_Cache.ema_fast_entry; }
   double               GetEMATrend() const { return m_Cache.ema_trend_entry; }
   double               GetVolatilityFactor() const;
   double               GetHighestHighSinceBar(int startBar, int lookback = 20);
   double               GetLowestLowSinceBar(int startBar, int lookback = 20);
   bool                 GetLastSignal(SignalInfo &signal);
   CLogger*             GetLogger() const { return m_Logger; }
   
   // Light update method for more frequent updates without heavy calculations
   void                 LightUpdate();
   
   // Check for entry signals and fill signal info
   bool                 CheckEntrySignal(SignalInfo &signal);
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
   // Store parameters
   m_Symbol = symbol;
   m_EntryTimeframe = entryTimeframe;
   m_EmaFastPeriod = emaFastPeriod;
   m_EmaTrendPeriod = emaTrendPeriod;
   m_UseMultiTimeframe = useMultiTimeframe;
   m_HigherTimeframe = higherTimeframe;
   m_UseNestedTimeframe = useNestedTimeframe;
   m_NestedTimeframe = nestedTimeframe;
   m_EnableMarketRegimeFilter = enableMarketRegimeFilter;
   
   // Initialize the logger if not already done
   if (m_Logger == NULL) {
      m_Logger = new CLogger("MarketMonitor");
      if (m_Logger == NULL) {
         Print("ERROR: Failed to create Logger object for MarketMonitor");
         return false;
      }
   }
   
   // Initialize indicators
   if (!InitializeIndicators()) {
      m_Logger.LogError("Failed to initialize indicators");
      return false;
   }
   
   // Set default values for parameters not passed to Initialize
   if (m_ATRPeriod == 0) m_ATRPeriod = 14;
   if (m_EnvelopeDeviation == 0) m_EnvelopeDeviation = 0.2;
   
   // Set default values for pullback parameters if not already set
   if (m_MinPullbackDepth == 0) m_MinPullbackDepth = 1.0;
   if (m_MaxPullbackDepth == 0) m_MaxPullbackDepth = 3.0;
   if (m_MinBounceStrength == 0) m_MinBounceStrength = 0.3;
   if (m_MaxBounceStrength == 0) m_MaxBounceStrength = 0.8;
   
   m_FibonacciNearThreshold = 0.25; // Price must be within 0.25 ATR of fib level
   m_GoldenZoneBonus = 0.15;   // Quality bonus for golden zone entries
   m_FibMinImpulseSize = 1.5;  // Impulse must be at least 1.5 ATR
   
   m_HarmonicTolerance = 0.03; // 3% tolerance for harmonic pattern ratios
   
   m_MomentumLookback = 60;    // Lookback for momentum analysis
   
   m_MinWickRatio = 2.0;       // Wick must be 2x body for liquidity grab
   m_MinVolumeRatio = 1.5;     // Volume must be 1.5x average for liquidity grab
   
   m_MinBreakoutSize = 0.3;    // Breakout must be at least 0.3 ATR
   
   // Log successful initialization
   m_Logger.LogInfo(StringFormat(
      "Market Monitor initialized for %s on %s timeframe (Fast EMA: %d, Trend EMA: %d)", 
      m_Symbol, 
      TimeframeToString(m_EntryTimeframe), 
      m_EmaFastPeriod, 
      m_EmaTrendPeriod
   ));
   
   // Update market data for the first time
   if (!UpdateIndicatorData()) {
      m_Logger.LogWarning("Initial market data update failed");
      // Continue anyway as this might succeed on subsequent calls
   }
   
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
   signal.symbol = m_Symbol;
   signal.signalTime = TimeCurrent();
   
   // Determine default signal direction based on trend
   bool tryLong = m_IsTrendUp || (!m_IsTrendDown && m_Cache.ema_fast_entry > m_Cache.ema_trend_entry);
   bool tryShort = m_IsTrendDown || (!m_IsTrendUp && m_Cache.ema_fast_entry < m_Cache.ema_trend_entry);
   
   // Skip signal generation if market regime filter is enabled and we're in ranging market
   if (m_EnableMarketRegimeFilter && m_MarketRegime == REGIME_RANGING) {
      m_Logger.LogDebug("Skipping signal generation due to ranging market");
      return false;
   }
   
   // Tạm disable pattern detection phức tạp
   // Tập trung vào các signal cơ bản và tin cậy hơn
   
   //--- 1. Try Pullback signals
   if ((tryLong || tryShort) && (m_MarketRegime == REGIME_STRONG_TREND || m_MarketRegime == REGIME_WEAK_TREND)) {
      double depth, speed, strength;
      double entryPrice, stopLevel;
      string description;
      
      // Try long pullback
      if (tryLong && AnalyzePullback(true, depth, speed, strength, entryPrice, stopLevel, description)) {
         signal.isValid = true;
         signal.isLong = true;
         signal.entryPrice = entryPrice;
         signal.stopLoss = stopLevel;
         signal.takeProfit = entryPrice + ((entryPrice - stopLevel) * 2); // Simple 1:2 RR for now
         signal.scenario = SCENARIO_BULLISH_PULLBACK;
         signal.quality = 0.5 + (strength * 0.3) + (speed * 0.2);
         signal.description = description;
         
         m_LastSignal = signal;
         
         m_Logger.LogInfo(StringFormat("[%s] %s signal detected: %s (Quality: %.2f)", 
                                     m_Symbol,
                                     signal.isLong ? "Long" : "Short",
                                     signal.description,
                                     signal.quality));
         return true;
      }
      
      // Try short pullback
      if (tryShort && AnalyzePullback(false, depth, speed, strength, entryPrice, stopLevel, description)) {
         signal.isValid = true;
         signal.isLong = false;
         signal.entryPrice = entryPrice;
         signal.stopLoss = stopLevel;
         signal.takeProfit = entryPrice - ((stopLevel - entryPrice) * 2); // Simple 1:2 RR for now
         signal.scenario = SCENARIO_BEARISH_PULLBACK;
         signal.quality = 0.5 + (strength * 0.3) + (speed * 0.2);
         signal.description = description;
         
         m_LastSignal = signal;
         
         m_Logger.LogInfo(StringFormat("[%s] %s signal detected: %s (Quality: %.2f)", 
                                     m_Symbol,
                                     signal.isLong ? "Long" : "Short",
                                     signal.description,
                                     signal.quality));
         return true;
      }
   }
   
   return false;  // No valid signal found
}

//+------------------------------------------------------------------+
//| Lightweight update to reduce CPU usage                           |
//+------------------------------------------------------------------+
void CMarketMonitor::LightUpdate()
{
   // Chỉ cập nhật dữ liệu giá thiết yếu, không recalculate chỉ báo nặng
   
   // Lấy giá mới nhất
   double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
   
   // Cập nhật cache giá hiện tại
   m_Cache.close = currentPrice;
   m_Cache.open = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
   
   // Không cập nhật các chỉ báo nested timeframe để tiết kiệm hiệu suất
   
   if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
      m_Logger.LogDebug("Light market update performed");
   }
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
   double open[], high[], low[], close[];
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
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

//+------------------------------------------------------------------+
//| DetectHarmonicPatterns Implementation                            |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectHarmonicPatterns(bool isUptrend, double &entryLevel, double &stopLevel, 
                                          double &qualityScore, string &patternName)
{
   // Khởi tạo giá trị
   entryLevel = 0; stopLevel = 0; qualityScore = 0;
   patternName = "";
   
   // Tham số
   double TOLERANCE = m_HarmonicTolerance;  // Dung sai cho tỉ lệ Fibonacci
   double SL_BUFFER = 0.3;                  // Buffer cho stop loss (tính bằng ATR)
   
   // Các tỉ lệ Fibonacci quan trọng
   double FIB_0_382 = 0.382;
   double FIB_0_500 = 0.500;
   double FIB_0_618 = 0.618;
   double FIB_0_786 = 0.786;
   double FIB_0_886 = 0.886;
   double FIB_1_000 = 1.000;
   double FIB_1_272 = 1.272;
   double FIB_1_414 = 1.414;
   double FIB_1_618 = 1.618;
   double FIB_2_000 = 2.000;
   double FIB_2_618 = 2.618;
   double FIB_3_618 = 3.618;
   
   // Lấy dữ liệu giá
   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, 100, high) <= 0 ||
       CopyLow(m_Symbol, m_EntryTimeframe, 0, 100, low) <= 0 ||
       CopyClose(m_Symbol, m_EntryTimeframe, 0, 100, close) <= 0 ||
       CopyOpen(m_Symbol, m_EntryTimeframe, 0, 100, open) <= 0) {
      if (m_Logger != NULL) {
         m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích Harmonic Patterns");
      }
      return false;
   }
   
   // Khai báo mảng để lưu các điểm đảo chiều (pivots)
   double pivotHigh[5], pivotLow[5];
   int pivotHighBar[5], pivotLowBar[5];
   
   // Tìm 5 điểm quan trọng để phân tích mô hình
   if (!FindPivots(high, low, 100, isUptrend, pivotHigh, pivotLow, pivotHighBar, pivotLowBar)) {
      if (m_Logger != NULL) {
         m_Logger.LogDebug("Không tìm đủ các điểm pivot cho phân tích Harmonic Patterns");
      }
      return false;
   }
   
   // Tính các tỉ lệ Fibonacci giữa các điểm
   double ratioAB = 0, ratioBC = 0, ratioCD = 0, ratioXAD = 0;
   
   if (isUptrend) {
      // Tính các tỉ lệ cho mô hình bullish (giảm-tăng-giảm-tăng)
      double rangeXA = MathAbs(pivotHigh[0] - pivotLow[1]);
      double rangeAB = MathAbs(pivotLow[1] - pivotHigh[2]);
      double rangeBC = MathAbs(pivotHigh[2] - pivotLow[3]);
      double rangeCD = MathAbs(pivotLow[3] - pivotHigh[4]);
      double rangeXD = MathAbs(pivotHigh[0] - pivotHigh[4]);
      
      if (rangeXA > 0) ratioAB = rangeAB / rangeXA;
      if (rangeAB > 0) ratioBC = rangeBC / rangeAB;
      if (rangeBC > 0) ratioCD = rangeCD / rangeBC;
      if (rangeXA > 0) ratioXAD = rangeXD / rangeXA;
   } else {
      // Tính các tỉ lệ cho mô hình bearish (tăng-giảm-tăng-giảm)
      double rangeXA = MathAbs(pivotLow[0] - pivotHigh[1]);
      double rangeAB = MathAbs(pivotHigh[1] - pivotLow[2]);
      double rangeBC = MathAbs(pivotLow[2] - pivotHigh[3]);
      double rangeCD = MathAbs(pivotHigh[3] - pivotLow[4]);
      double rangeXD = MathAbs(pivotLow[0] - pivotLow[4]);
      
      if (rangeXA > 0) ratioAB = rangeAB / rangeXA;
      if (rangeAB > 0) ratioBC = rangeBC / rangeAB;
      if (rangeBC > 0) ratioCD = rangeCD / rangeBC;
      if (rangeXA > 0) ratioXAD = rangeXD / rangeXA;
   }
   
   // Kiểm tra và xác định các mô hình
   bool patternFound = false;
   string patternType = "";
   double patternQuality = 0.0;
   
   // Mẫu Gartley
   if (IsInRange(ratioAB, FIB_0_618, TOLERANCE) && 
      IsInRange(ratioBC, FIB_0_382, TOLERANCE) && 
      IsInRange(ratioCD, FIB_1_272, TOLERANCE) && 
      IsInRange(ratioXAD, FIB_0_786, TOLERANCE)) {
      patternFound = true;
      patternType = "Gartley";
      patternQuality = 0.8;
   }
   
   // Mẫu Butterfly
   else if (IsInRange(ratioAB, FIB_0_786, TOLERANCE) && 
           IsInRange(ratioBC, FIB_0_382, TOLERANCE) && 
           IsInRange(ratioCD, FIB_1_618, TOLERANCE) && 
           IsInRange(ratioXAD, FIB_1_272, TOLERANCE)) {
      patternFound = true;
      patternType = "Butterfly";
      patternQuality = 0.85;
   }
   
   // Mẫu Bat
   else if (IsInRange(ratioAB, FIB_0_382, TOLERANCE) && 
           IsInRange(ratioBC, FIB_0_382, TOLERANCE) && 
           IsInRange(ratioCD, FIB_1_618, TOLERANCE) && 
           IsInRange(ratioXAD, FIB_0_886, TOLERANCE)) {
      patternFound = true;
      patternType = "Bat";
      patternQuality = 0.75;
   }
   
   // Mẫu Crab
   else if (IsInRange(ratioAB, FIB_0_382, TOLERANCE) && 
           IsInRange(ratioBC, FIB_0_618, TOLERANCE) && 
           IsInRange(ratioCD, FIB_2_618, TOLERANCE) && 
           IsInRange(ratioXAD, FIB_1_618, TOLERANCE)) {
      patternFound = true;
      patternType = "Crab";
      patternQuality = 0.9;
   }
   
   // Nếu không tìm thấy mẫu nào
   if (!patternFound) {
      if (m_Logger != NULL) {
         m_Logger.LogDebug("Không tìm thấy mô hình Harmonic hợp lệ");
      }
      return false;
   }
   
   // Thiết lập thông tin giao dịch
   if (isUptrend) {
      entryLevel = close[0]; // Hoặc có thể thiết lập tại mức hỗ trợ/kháng cự
      stopLevel = pivotLow[4] - m_Cache.atr_entry * SL_BUFFER; // Stop ở dưới điểm D với buffer
   } else {
      entryLevel = close[0]; // Giá hiện tại
      stopLevel = pivotHigh[4] + m_Cache.atr_entry * SL_BUFFER; // Stop ở trên điểm D với buffer
   }
   
   // Thưởng điểm cho chất lượng mẫu
   if (IsInRange(ratioAB, FIB_0_618, TOLERANCE/2) || 
       IsInRange(ratioAB, FIB_0_786, TOLERANCE/2) || 
       IsInRange(ratioAB, FIB_0_886, TOLERANCE/2)) {
      patternQuality += 0.05;
   }
   
   if (IsInRange(ratioCD, FIB_1_618, TOLERANCE/2) || 
       IsInRange(ratioCD, FIB_2_618, TOLERANCE/2)) {
      patternQuality += 0.05;
   }
   
   // Bonus for precision
   patternQuality += (1.0 - (MathAbs(ratioXAD - FIB_1_000) / TOLERANCE)) * 0.1;
   
   // Bonus if Fib retracement aligns with higher timeframe
   if (m_UseMultiTimeframe) {
      bool higherTFUptrend = (m_Cache.ema_fast_higher > m_Cache.ema_trend_higher);
      if (isUptrend == higherTFUptrend) {
         patternQuality += 0.1; // Alignment bonus
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
         patternQuality += 0.05;
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
         patternQuality += 0.05;
      }
   }
   
   // Bonus for price action confirmation
   if (hasPriceAction) {
      patternQuality += 0.1;
   }
   
   // Limit quality to [0,1] range
   qualityScore = MathMin(patternQuality, 1.0);
   
   // Thiết lập tên mẫu
   patternName = StringFormat("%s %s Pattern", isUptrend ? "Bullish" : "Bearish", patternType);
   
   if (m_Logger != NULL) {
      m_Logger.LogInfo("Phát hiện mô hình Harmonic: " + patternName + " (Quality: " + DoubleToString(qualityScore, 2) + ")");
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| DetectLiquidityGrab Implementation                               |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectLiquidityGrab(bool isUptrend, double &entryPrice, double &stopLevel,
                                        double &quality, string &description)
{
   // Khởi tạo giá trị
   entryPrice = 0.0;
   stopLevel = 0.0;
   quality = 0.0;
   description = "";
   
   // Tham số
   double SL_ATR_BUFFER = 0.3;      // Buffer cho stop loss (tính bằng ATR)
   
   // Lấy dữ liệu giá
   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, 100, high) <= 0 ||
       CopyLow(m_Symbol, m_EntryTimeframe, 0, 100, low) <= 0 ||
       CopyClose(m_Symbol, m_EntryTimeframe, 0, 100, close) <= 0) {
      if (m_Logger != NULL) {
         m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích Liquidity Grab");
      }
      return false;
   }
   
   // Chưa triển khai đầy đủ, sẽ cập nhật sau
   if (m_Logger != NULL) {
      m_Logger.LogDebug("Phương thức DetectLiquidityGrab chưa được triển khai đầy đủ");
   }
   
   return false; // Trả về false vì chưa triển khai
}

//+------------------------------------------------------------------+
//| DetectBreakoutFailure Implementation                             |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectBreakoutFailure(bool isUptrend, double &entryPrice, double &stopLevel,
                                          double &quality, string &description)
{
   // Khởi tạo giá trị
   entryPrice = 0; stopLevel = 0; quality = 0;
   description = "";
   
   // Tham số (nên chuyển thành input parameters)
   double SL_ATR_BUFFER = 0.3;              // Buffer cho SL (tính bằng ATR)
   double MIN_BREAKOUT_ATR = 0.3;           // Kích thước tối thiểu của breakout (tính bằng ATR)
   double MIN_FAILURE_ATR = 0.5;            // Độ sâu tối thiểu của failure (tính bằng ATR)
   int MAX_BREAKOUT_AGE = 15;               // Tuổi tối đa của breakout (số nến)
   
   // Lấy dữ liệu giá
   double high[], low[], close[], open[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(open, true);
   
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, 100, high) <= 0 ||
       CopyLow(m_Symbol, m_EntryTimeframe, 0, 100, low) <= 0 ||
       CopyClose(m_Symbol, m_EntryTimeframe, 0, 100, close) <= 0 ||
       CopyOpen(m_Symbol, m_EntryTimeframe, 0, 100, open) <= 0) {
      if (m_Logger != NULL) {
         m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích Breakout Failure");
      }
      return false;
   }
   
   // BƯỚC 1: Tìm vùng tích lũy (consolidation zone)
   double zoneHigh = 0, zoneLow = 0;
   bool foundZone = FindConsolidationZone(high, low, zoneHigh, zoneLow, 5, 20);
   
   if (!foundZone || zoneHigh <= 0 || zoneLow <= 0 || zoneHigh <= zoneLow) {
      if (m_Logger != NULL) {
         m_Logger.LogDebug("Không tìm thấy vùng tích lũy rõ ràng");
      }
      return false;
   }
   
   // BƯỚC 2: Tìm nến breakout
   int breakoutBar = -1;
   double breakoutLevel = 0;
   bool isBreakoutUp = false;
   
   for (int i = 1; i < 100 - 5; i++) {
      // Kiểm tra breakout lên (close trên zoneHigh)
      if (close[i] > zoneHigh && close[i+1] <= zoneHigh) {
         breakoutBar = i;
         breakoutLevel = zoneHigh;
         isBreakoutUp = true;
         break;
      }
      
// Kiểm tra breakout xuống (close dưới zoneLow)
      if (close[i] < zoneLow && close[i+1] >= zoneLow) {
         breakoutBar = i;
         breakoutLevel = zoneLow;
         isBreakoutUp = false;
         break;
      }
   }
   
   // Kiểm tra nếu không tìm thấy breakout
   if (breakoutBar < 0) {
      m_Logger.LogDebug("Không tìm thấy breakout từ vùng tích lũy");
      return false;
   }
   
   // Kiểm tra nếu breakout quá cũ
   if (breakoutBar > MAX_BREAKOUT_AGE) {
      m_Logger.LogDebug(StringFormat("Breakout quá cũ: %d nến", breakoutBar));
      return false;
   }
   
   // Kiểm tra độ lớn của breakout
   double breakoutSize = 0;
   if (isBreakoutUp) {
      breakoutSize = (close[breakoutBar] - breakoutLevel) / m_Cache.atr_entry;
   } else {
      breakoutSize = (breakoutLevel - close[breakoutBar]) / m_Cache.atr_entry;
   }
   
   if (breakoutSize < MIN_BREAKOUT_ATR) {
      m_Logger.LogDebug(StringFormat("Breakout quá nhỏ: %.2f ATR", breakoutSize));
      return false;
   }
   
   // BƯỚC 3: Tìm sự thất bại của breakout
   int failureBar = -1;
   
   // Chỉ kiểm tra các nến sau breakout
   for (int i = breakoutBar - 1; i >= 0; i--) {
      // Nếu là breakout lên, tìm sự thất bại là giá đóng cửa dưới breakoutLevel
      if (isBreakoutUp && close[i] < breakoutLevel) {
         failureBar = i;
         break;
      }
      // Nếu là breakout xuống, tìm sự thất bại là giá đóng cửa trên breakoutLevel
      else if (!isBreakoutUp && close[i] > breakoutLevel) {
         failureBar = i;
         break;
      }
   }
   
   // Kiểm tra nếu không tìm thấy sự thất bại
   if (failureBar < 0) {
      m_Logger.LogDebug("Không tìm thấy sự thất bại của breakout");
      return false;
   }
   
   // Kiểm tra để đảm bảo sự thất bại đủ mới
   if (failureBar > 5) {
      m_Logger.LogDebug(StringFormat("Sự thất bại quá cũ: %d nến", failureBar));
      return false;
   }
   
   // Kiểm tra độ sâu của sự thất bại
   double failureDepth = 0;
   if (isBreakoutUp) {
      // Đối với breakout lên, độ sâu là khoảng cách từ breakoutLevel đến low[failureBar]
      failureDepth = (breakoutLevel - low[failureBar]) / m_Cache.atr_entry;
   } else {
      // Đối với breakout xuống, độ sâu là khoảng cách từ high[failureBar] đến breakoutLevel
      failureDepth = (high[failureBar] - breakoutLevel) / m_Cache.atr_entry;
   }
   
   if (failureDepth < MIN_FAILURE_ATR) {
      m_Logger.LogDebug(StringFormat("Độ sâu thất bại quá nhỏ: %.2f ATR", failureDepth));
      return false;
   }
   
   // BƯỚC 4: Kiểm tra sự xác nhận xu hướng tiếp theo
   bool hasConfirmation = false;
   double confirmationLevel = 0;
   
   // Gán dấu hiệu xác nhận dựa trên sự di chuyển tiếp theo của giá
   if (isUptrend) {
      // Với xu hướng tăng, cần giá tiếp tục tăng sau failure
      if (close[0] > close[failureBar]) {
         hasConfirmation = true;
         confirmationLevel = close[failureBar];
      }
   } else {
      // Với xu hướng giảm, cần giá tiếp tục giảm sau failure
      if (close[0] < close[failureBar]) {
         hasConfirmation = true;
         confirmationLevel = close[failureBar];
      }
   }
   
   if (!hasConfirmation) {
      m_Logger.LogDebug("Không có xác nhận cho xu hướng sau failure");
      return false;
   }
   
   // BƯỚC 5: Thiết lập thông tin giao dịch
   
   // Điểm vào lệnh là giá hiện tại
   entryPrice = close[0]; // Entry ở giá đóng cửa hiện tại
   
   // Đặt stop loss dựa trên vùng breakout với buffer
   if (isUptrend) {
      stopLevel = breakoutLevel - (m_Cache.atr_entry * SL_ATR_BUFFER);
   } else {
      stopLevel = breakoutLevel + (m_Cache.atr_entry * SL_ATR_BUFFER);
   }
   
   // BƯỚC 6: Tính chất lượng tín hiệu
   
   // Điểm chất lượng cơ bản
   quality = 0.7;
   
   // Thưởng điểm nếu failure xảy ra gần đây
   if (failureBar <= 2) {
      quality += 0.05;
   }
   
   // Thưởng điểm cho độ sâu failure lớn
   if (failureDepth > MIN_FAILURE_ATR * 2) {
      quality += 0.05;
   }
   
   // Thưởng điểm nếu độ lớn của breakout lớn
   if (breakoutSize > MIN_BREAKOUT_ATR * 2) {
      quality += 0.05;
   }
   
   // Thưởng điểm nếu phản ứng sau failure rõ ràng
   if (isUptrend && (close[0] - close[failureBar]) / m_Cache.atr_entry > 0.5) {
      quality += 0.05;
   } else if (!isUptrend && (close[failureBar] - close[0]) / m_Cache.atr_entry > 0.5) {
      quality += 0.05;
   }
   
   // Thưởng điểm nếu khớp với xu hướng của khung cao hơn
   if (m_UseMultiTimeframe) {
      bool higherTFUptrend = (m_Cache.ema_fast_higher > m_Cache.ema_trend_higher);
      if (isUptrend == higherTFUptrend) {
         quality += 0.1; // Alignment bonus
      }
   }
   
   // Giới hạn chất lượng trong phạm vi [0,1]
   quality = MathMin(quality, 1.0);
   
   // BƯỚC 7: Tạo mô tả
   string trendDir = isUptrend ? "Tăng" : "Giảm";
   string breakoutDir = isBreakoutUp ? "Lên" : "Xuống";
   
   description = StringFormat("Breakout Failure %s: Breakout %s thất bại %.1f ATR, Đã xác nhận", 
                            trendDir, breakoutDir, failureDepth);
   
   m_Logger.LogInfo("Phát hiện Breakout Failure: " + description);
   
   return true;
}

//+------------------------------------------------------------------+
//| DetectMomentumShift Implementation                               |
//+------------------------------------------------------------------+
bool CMarketMonitor::DetectMomentumShift(bool isUptrend, double &entryPrice, double &stopLevel,
                                      double &quality, string &description)
{
   // Khởi tạo giá trị
   entryPrice = 0.0;
   stopLevel = 0.0;
   quality = 0.0;
   description = "";
   
   // Tham số
   double SL_ATR_BUFFER = 0.3;      // Buffer cho stop loss (tính bằng ATR)
   
   // Lấy dữ liệu giá
   double high[], low[], close[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   
   if (CopyHigh(m_Symbol, m_EntryTimeframe, 0, 100, high) <= 0 ||
       CopyLow(m_Symbol, m_EntryTimeframe, 0, 100, low) <= 0 ||
       CopyClose(m_Symbol, m_EntryTimeframe, 0, 100, close) <= 0) {
      if (m_Logger != NULL) {
         m_Logger.LogError("Không thể sao chép dữ liệu giá cho phân tích Momentum Shift");
      }
      return false;
   }
   
   // Chưa triển khai đầy đủ, sẽ cập nhật sau
   if (m_Logger != NULL) {
      m_Logger.LogDebug("Phương thức DetectMomentumShift chưa được triển khai đầy đủ");
   }
   
   return false; // Trả về false vì chưa triển khai
}

//+------------------------------------------------------------------+
//| Find a consolidation zone based on price action                  |
//+------------------------------------------------------------------+
bool CMarketMonitor::FindConsolidationZone(const double &high[], const double &low[], 
                                          double &zoneHigh, double &zoneLow, 
                                          int minConsolidationBars, int maxConsolidationBars)
{
   // Initialize output values
   zoneHigh = 0;
   zoneLow = 0;
   
   // Get current ATR for relative measurements
   double atr = m_Cache.atr_entry;
   if (atr <= 0) {
      m_Logger.LogDebug("Invalid ATR for consolidation zone detection");
      return false;
   }
   
   // Look for a consolidation zone within the lookback period
   int consolidationStart = -1;
   int consolidationEnd = -1;
   
   // Maximum height of consolidation zone in ATR terms
   double maxZoneHeightATR = 2.0;
   
   // Start from recent bars and search backwards
   for (int start = 1; start < maxConsolidationBars - minConsolidationBars; start++) {
      // Try to find a potential consolidation zone starting at 'start'
      
      // Find highest high and lowest low in the potential zone
      double tempHigh = high[start];
      double tempLow = low[start];
      
      for (int i = start; i < start + minConsolidationBars && i < maxConsolidationBars; i++) {
         tempHigh = MathMax(tempHigh, high[i]);
         tempLow = MathMin(tempLow, low[i]);
      }
      
      // Calculate zone height
      double zoneHeight = tempHigh - tempLow;
      double zoneHeightATR = zoneHeight / atr;
      
      // Check if zone is valid (not too wide)
      if (zoneHeightATR <= maxZoneHeightATR) {
         // Check if price stayed within this zone for the minimum number of bars
         bool validZone = true;
         int endBar = start + minConsolidationBars;
         
         // Extend zone as far as possible within maxConsolidationBars
         for (int i = start; i < maxConsolidationBars; i++) {
            // If price breaks out of the zone, stop extending
            if (high[i] > tempHigh + (atr * 0.3) || low[i] < tempLow - (atr * 0.3)) {
               endBar = i;
               break;
            }
            endBar = i + 1; // Update end bar if this bar is still in zone
         }
         
         // Ensure minimum length requirement is met
         if (endBar - start >= minConsolidationBars) {
            consolidationStart = start;
            consolidationEnd = endBar;
            zoneHigh = tempHigh;
            zoneLow = tempLow;
            break;
         }
      }
   }
   
   // Check if a valid consolidation zone was found
   if (consolidationStart < 0 || consolidationEnd < 0 || consolidationEnd - consolidationStart < minConsolidationBars) {
      return false;
   }
   
   // Add a small buffer to zone boundaries for cleaner detection
   zoneHigh += atr * 0.05;
   zoneLow -= atr * 0.05;
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if a value is within a tolerance range of a target         |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsInRange(double value, double target, double tolerance)
{
   return (MathAbs(value - target) <= tolerance);
}

//+------------------------------------------------------------------+
//| Find significant pivot points in price data                      |
//+------------------------------------------------------------------+
bool CMarketMonitor::FindPivots(const double &high[], const double &low[], int maxBars,
                                bool isUptrend, double &pivotHigh[], double &pivotLow[],
                                int &pivotHighBar[], int &pivotLowBar[])
{
   // Clear output arrays
   ArrayResize(pivotHigh, 0);
   ArrayResize(pivotLow, 0);
   ArrayResize(pivotHighBar, 0);
   ArrayResize(pivotLowBar, 0);
   
   int highCount = 0;
   int lowCount = 0;
   
   // Look for pivots with 2 bars on each side
   for (int i = 2; i < maxBars - 2; i++) {
      // Check for pivot high
      if (high[i] > high[i-1] && high[i] > high[i-2] && 
          high[i] > high[i+1] && high[i] > high[i+2]) {
         // Add to pivot high array
         ArrayResize(pivotHigh, highCount + 1);
         ArrayResize(pivotHighBar, highCount + 1);
         pivotHigh[highCount] = high[i];
         pivotHighBar[highCount] = i;
         highCount++;
      }
      
      // Check for pivot low
      if (low[i] < low[i-1] && low[i] < low[i-2] && 
          low[i] < low[i+1] && low[i] < low[i+2]) {
         // Add to pivot low array
         ArrayResize(pivotLow, lowCount + 1);
         ArrayResize(pivotLowBar, lowCount + 1);
         pivotLow[lowCount] = low[i];
         pivotLowBar[lowCount] = i;
         lowCount++;
      }
   }
   
   // Return true if we found at least one pivot of each type
   return (highCount > 0 && lowCount > 0);
}

//+------------------------------------------------------------------+
//| Check if a bar forms a local top                                 |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsLocalTop(const double &high[], int index)
{
   // Check if we have enough bars to analyze
   if (index < 2 || index >= ArraySize(high) - 2) 
      return false;
      
   // Check if this bar's high is higher than surrounding bars
   return (high[index] > high[index-1] && high[index] > high[index-2] && 
           high[index] > high[index+1] && high[index] > high[index+2]);
}

//+------------------------------------------------------------------+
//| Check if a bar forms a local bottom                              |
//+------------------------------------------------------------------+
bool CMarketMonitor::IsLocalBottom(const double &low[], int index)
{
   // Check if we have enough bars to analyze
   if (index < 2 || index >= ArraySize(low) - 2) 
      return false;
      
   // Check if this bar's low is lower than surrounding bars
   return (low[index] < low[index-1] && low[index] < low[index-2] && 
           low[index] < low[index+1] && low[index] < low[index+2]);
}