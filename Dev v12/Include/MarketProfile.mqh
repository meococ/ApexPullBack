//+------------------------------------------------------------------+
//| MarketProfile.mqh - ApexPullback EA v13.5                       |
//| Enhanced Market Context Analysis with Institutional Perspective  |
//| Copyright 2023-2025, ApexTrading Systems                        |
//+------------------------------------------------------------------+
#ifndef MARKET_PROFILE_MQH
#define MARKET_PROFILE_MQH

#include <Trade\Trade.mqh>       // For price, spread information
#include "CommonStructs.mqh"     // Common enums and structs
#include "Logger.mqh"            // Logging system

//+------------------------------------------------------------------+
//| Multi-Timeframe Weights Configuration                            |
//| Adjusts the importance of different timeframes for analysis      |
//+------------------------------------------------------------------+
struct MTFWeights {
    double m15Weight;            // Weight for M15 timeframe
    double h1Weight;             // Weight for H1 timeframe
    double h4Weight;             // Weight for H4 timeframe
    double d1Weight;             // Weight for D1 timeframe
    
    // Constructor with default balanced weights
    MTFWeights() {
        m15Weight = 0.15;
        h1Weight = 0.35;
        h4Weight = 0.35;
        d1Weight = 0.15;
    }
    
    // Constructor with custom weights
    MTFWeights(double m15, double h1, double h4, double d1) {
        // Normalize weights to ensure they sum to 1.0
        double sum = m15 + h1 + h4 + d1;
        if(sum <= 0) {
            // Default if invalid weights
            m15Weight = 0.15;
            h1Weight = 0.35;
            h4Weight = 0.35;
            d1Weight = 0.15;
        } else {
            m15Weight = m15 / sum;
            h1Weight = h1 / sum;
            h4Weight = h4 / sum;
            d1Weight = d1 / sum;
        }
    }
};

//+------------------------------------------------------------------+
//| Volume Profile Node                                              |
//| Used for tracking price-volume distribution                      |
//+------------------------------------------------------------------+
struct VolumeNode {
    double price;                // Price level
    double volume;               // Volume at this price
    bool isVAH;                  // Value Area High flag
    bool isVAL;                  // Value Area Low flag
    bool isPOC;                  // Point of Control flag
    
    // Constructor
    VolumeNode() {
        price = 0.0;
        volume = 0.0;
        isVAH = false;
        isVAL = false;
        isPOC = false;
    }
};

//+------------------------------------------------------------------+
//| Liquidity Level                                                  |
//| Represents institutional liquidity concentration points          |
//+------------------------------------------------------------------+
struct LiquidityLevel {
    double price;                // Price level
    double strength;             // Strength of the level (0.0-1.0)
    datetime time;               // When this level was formed
    int sweepCount;              // How many times liquidity was tested
    bool isSwept;                // Has this level been swept recently
    ENUM_LIQUIDITY_TYPE type;    // Buy or Sell liquidity
    
    // Constructor
    LiquidityLevel() {
        price = 0.0;
        strength = 0.0;
        time = 0;
        sweepCount = 0;
        isSwept = false;
        type = LIQUIDITY_UNDEFINED;
    }
};

//+------------------------------------------------------------------+
//| Enhanced Market Profile Structure                                |
//| Comprehensive market context data for v13.5                      |
//+------------------------------------------------------------------+
struct MarketProfile {
    // Basic Information
    datetime timeCreated;        // When profile was created
    
    // Volatility Metrics
    double atrCurrent;           // Current ATR
    double atrRatio;             // ATR ratio to 20-day average
    double atrSlope;             // ATR slope
    double atrAcceleration;      // NEW: ATR acceleration (2nd derivative)
    double impliedVolatility;    // NEW: Estimated implied volatility
    double volatilityRegimeScore;// NEW: 0-1 score of current vol regime
    
    // Trend Metrics
    double adxH4;                // ADX on H4
    double adxSlope;             // ADX slope
    double adxDI_Plus;           // DI+ of ADX
    double adxDI_Minus;          // DI- of ADX
    double trendStrength;        // NEW: 0-1 composite trend strength score
    double trendAge;             // NEW: Approximate age of trend in bars
    double trendPersistence;     // NEW: Likelihood of trend continuation
    
    // EMA Metrics
    double emaSlope;             // EMA slope
    double emaAlignment;         // EMA alignment
    double emaMomentumIndex;     // NEW: Momentum based on EMA
    
    // RSI & MACD Metrics
    double rsiValue;             // RSI value
    double macdMain;             // MACD main line
    double macdSignal;           // MACD signal line
    double macdHistogram;        // MACD histogram
    double rsiSlope;             // NEW: RSI slope
    bool hasBullishDivergence;   // NEW: Has bullish divergence
    bool hasBearishDivergence;   // NEW: Has bearish divergence
    
    // Volume Metrics
    double volumeCurrent;        // Current volume
    double volumeSMA20;          // 20-bar volume SMA
    bool volumeSpike;            // Volume spike flag
    bool volumeDeclining;        // Volume declining flag
    double volumeForce;          // NEW: Volume strength in direction
    double buyingPressure;       // NEW: Buy volume estimation
    double sellingPressure;      // NEW: Sell volume estimation
    
    // Session Information
    ENUM_SESSION currentSession; // Current trading session
    bool isSessionStart;         // NEW: Near session start
    bool isSessionEnd;           // NEW: Near session end
    
    // Market Phase
    ENUM_MARKET_PHASE marketPhase; // Current market phase
    double phaseCompletion;      // NEW: 0-1 estimate of phase completion
    
    // Market Characteristics
    bool isTrending;             // Is trending flag
    bool isSideway;              // Is sideway flag
    bool isVolatile;             // Is volatile flag
    bool isRangebound;           // Is range-bound flag
    bool isOverbought;           // Is overbought flag
    bool isOversold;             // Is oversold flag
    bool isInBreakout;           // NEW: Is in breakout state
    bool isInPullback;           // NEW: Is in pullback state
    bool isInFakeout;            // NEW: Is in fakeout state
    
    // Regime Transition Data
    bool isTransitioning;        // Is transitioning flag
    double regimeConfidence;     // Regime confidence (0-1)
    double transitionProgress;   // Transition progress (0-1)
    int regimeAge;               // Age of current regime in bars
    ENUM_MARKET_REGIME regime;   // NEW: Explicitly defined regime type
    
    // Key Price Levels
    double recentSwingHigh;      // Recent swing high
    double recentSwingLow;       // Recent swing low
    double keyResistance;        // Key resistance
    double keySupport;           // Key support
    double valueAreaHigh;        // NEW: Volume profile VAH
    double valueAreaLow;         // NEW: Volume profile VAL
    double pointOfControl;       // NEW: Volume profile POC
    
    // Institutional Metrics
    double smartMoneyIndex;      // NEW: Smart money index (0-1)
    double liquidityAbove;       // NEW: Estimated liquidity above
    double liquidityBelow;       // NEW: Estimated liquidity below
    double cumulativeDelta;      // NEW: Cumulative delta
    
    // Market Internals
    double marketBreadth;        // NEW: Market breadth
    double marketSentiment;      // NEW: Market sentiment score (-1 to 1)
    double correlationIndex;     // NEW: Correlation with related markets
    double marketEfficiency;     // NEW: Market efficiency ratio (0-1)
    
    // Multi-Timeframe Consensus 
    double mtfTrendScore;        // NEW: Multi-timeframe trend score (-1 to 1)
    double mtfVolatilityScore;   // NEW: Multi-timeframe volatility score (0-1)
    double mtfMomentumScore;     // NEW: Multi-timeframe momentum score (-1 to 1)
    
    // Entry Quality Assessment
    double trendFollowQuality;   // NEW: Quality score for trend-following (0-1)
    double counterTrendQuality;  // NEW: Quality score for counter-trend (0-1) 
    double rangeTradingQuality;  // NEW: Quality score for range trading (0-1)
    double breakoutQuality;      // NEW: Quality score for breakout trades (0-1)
    
    // Constructor with default values
    MarketProfile() {
        // Initialize all fields with default values
        timeCreated = 0;
        
        atrCurrent = 0;
        atrRatio = 1.0;
        atrSlope = 0;
        atrAcceleration = 0;
        impliedVolatility = 0;
        volatilityRegimeScore = 0.5;
        
        adxH4 = 0;
        adxSlope = 0;
        adxDI_Plus = 0;
        adxDI_Minus = 0;
        trendStrength = 0;
        trendAge = 0;
        trendPersistence = 0.5;
        
        emaSlope = 0;
        emaAlignment = 0;
        emaMomentumIndex = 0;
        
        rsiValue = 50;
        macdMain = 0;
        macdSignal = 0;
        macdHistogram = 0;
        rsiSlope = 0;
        hasBullishDivergence = false;
        hasBearishDivergence = false;
        
        volumeCurrent = 0;
        volumeSMA20 = 0;
        volumeSpike = false;
        volumeDeclining = false;
        volumeForce = 0;
        buyingPressure = 0;
        sellingPressure = 0;
        
        currentSession = SESSION_UNKNOWN;
        isSessionStart = false;
        isSessionEnd = false;
        
        marketPhase = PHASE_ACCUMULATION;
        phaseCompletion = 0;
        
        isTrending = false;
        isSideway = false;
        isVolatile = false;
        isRangebound = false;
        isOverbought = false;
        isOversold = false;
        isInBreakout = false;
        isInPullback = false;
        isInFakeout = false;
        
        isTransitioning = false;
        regimeConfidence = 0;
        transitionProgress = 0;
        regimeAge = 0;
        regime = REGIME_UNDEFINED;
        
        recentSwingHigh = 0;
        recentSwingLow = 0;
        keyResistance = 0;
        keySupport = 0;
        valueAreaHigh = 0;
        valueAreaLow = 0;
        pointOfControl = 0;
        
        smartMoneyIndex = 0.5;
        liquidityAbove = 0;
        liquidityBelow = 0;
        cumulativeDelta = 0;
        
        marketBreadth = 0;
        marketSentiment = 0;
        correlationIndex = 0;
        marketEfficiency = 0.5;
        
        mtfTrendScore = 0;
        mtfVolatilityScore = 0.5;
        mtfMomentumScore = 0;
        
        trendFollowQuality = 0.5;
        counterTrendQuality = 0.5;
        rangeTradingQuality = 0.5;
        breakoutQuality = 0.5;
    }
}
;

//+------------------------------------------------------------------+
//| CMarketProfile Class                                             |
//| Enhanced market analysis for ApexPullback EA v13.5               |
//+------------------------------------------------------------------+
class CMarketProfile
{
private:
    // Core Info
    string            m_symbol;                 // Symbol being analyzed
    ENUM_TIMEFRAMES   m_timeframe;              // Primary timeframe for analysis
    
    // Logger & Context
    CLogger*          m_logger;                 // Logger instance pointer
    int               m_GMT_Offset;             // GMT offset
    datetime          m_lastUpdateTime;         // Last update time
    datetime          m_lastFullUpdateTime;     // Last full update time
    
    // Initialization State
    bool              m_isInitialized;          // Initialization state
    bool              m_isDataReliable;         // Data reliability flag
    int               m_failedUpdatesCount;     // Consecutive failed updates
    int               m_maxConsecutiveFailedUpdates; // Max allowed failed updates
    
    // Indicator Handles - M15
    int               m_handleADX_M15;          // ADX handle (M15)
    int               m_handleATR_M15;          // NEW: ATR handle (M15)
    int               m_handleRSI_M15;          // NEW: RSI handle (M15)
    int               m_handleMACD_M15;         // NEW: MACD handle (M15)
    int               m_handleEMA21_M15;        // NEW: EMA21 handle (M15)
    int               m_handleEMA50_M15;        // NEW: EMA50 handle (M15)
    
    // Indicator Handles - H1
    int               m_handleADX_H1;           // ADX handle (H1)
    int               m_handleATR_H1;           // ATR handle (H1)
    int               m_handleEMA34_H1;         // EMA34 handle (H1)
    int               m_handleEMA89_H1;         // EMA89 handle (H1)
    int               m_handleEMA200_H1;        // EMA200 handle (H1)
    int               m_handleRSI_H1;           // RSI handle (H1)
    int               m_handleMACD_H1;          // MACD handle (H1)
    int               m_handleStochastic_H1;    // NEW: Stochastic handle (H1)
    
    // Indicator Handles - H4
    int               m_handleADX_H4;           // ADX handle (H4)
    int               m_handleATR_H4;           // ATR handle (H4)
    int               m_handleEMA34_H4;         // NEW: EMA34 handle (H4)
    int               m_handleEMA89_H4;         // NEW: EMA89 handle (H4)
    int               m_handleEMA200_H4;        // NEW: EMA200 handle (H4)
    int               m_handleRSI_H4;           // NEW: RSI handle (H4)
    int               m_handleMACD_H4;          // NEW: MACD handle (H4)
    
    // Indicator Handles - D1
    int               m_handleATR_D1;           // NEW: ATR handle (D1)
    int               m_handleEMA21_D1;         // NEW: EMA21 handle (D1)
    int               m_handleEMA50_D1;         // NEW: EMA50 handle (D1)
    int               m_handleEMA200_D1;        // NEW: EMA200 handle (D1)
    
    // Indicator Data - M15
    double            m_adxM15;                 // ADX value (M15)
    double            m_di_plus_m15;            // NEW: DI+ (M15) 
    double            m_di_minus_m15;           // NEW: DI- (M15)
    double            m_atrM15;                 // NEW: ATR (M15)
    double            m_rsiM15;                 // NEW: RSI (M15) 
    double            m_macdHistogram_M15;      // NEW: MACD histogram (M15)
    
    // Indicator Data - H1
    double            m_adxH1;                  // ADX value (H1)
    double            m_adxPrev;                // Previous ADX value
    double            m_di_plus_h1;             // DI+ value (H1)
    double            m_di_minus_h1;            // DI- value (H1)
    double            m_atrH1;                  // ATR value (H1)
    double            m_slopeEMA34H1;           // EMA34 slope (H1)
    double            m_emaSlope_prev;          // Previous EMA slope
    double            m_distanceEMA89_200_H1;   // Distance EMA89-200 (H1)
    double            m_emaAlignment;           // EMA alignment
    double            m_rsiH1;                  // RSI value (H1)
    double            m_macdMain;               // MACD main line
    double            m_macdSignal;             // MACD signal line
    double            m_macdHistogram;          // MACD histogram
    double            m_macdHistogramPrev;      // Previous MACD histogram
    double            m_stochMain;              // NEW: Stochastic main line
    double            m_stochSignal;            // NEW: Stochastic signal line
    
    // Indicator Data - H4
    double            m_adxH4;                  // ADX value (H4)
    double            m_atrH4;                  // ATR value (H4)
    double            m_rsiH4;                  // NEW: RSI value (H4)
    double            m_macdHistogram_H4;       // NEW: MACD histogram (H4)
    double            m_di_plus_h4;             // NEW: DI+ value (H4)
    double            m_di_minus_h4;            // NEW: DI- value (H4)
    
    // Indicator Data - D1
    double            m_atrD1;                  // NEW: ATR value (D1)
    
    // Volume Analysis
    double            m_volumeCurrent;          // Current volume
    double            m_volumeSMA20;            // Volume SMA20
    bool              m_hasVolumeSpike;         // Volume spike flag
    
    // Statistical Analysis
    double            m_avgEMASlope;            // Average EMA slope
    double            m_emaSlopeStdDev;         // EMA slope standard deviation
    double            m_emaSlopeAvg;            // EMA slope average
    
    // Volume Profile
    VolumeNode        m_volumeProfile[100];     // NEW: Volume profile array
    int               m_volumeProfileSize;      // NEW: Volume profile size
    double            m_valueAreaHigh;          // NEW: Volume profile VAH
    double            m_valueAreaLow;           // NEW: Volume profile VAL
    double            m_pointOfControl;         // NEW: Volume profile POC
    
    // Liquidity Analysis
    LiquidityLevel    m_buyLiquidityLevels[10]; // NEW: Buy-side liquidity levels
    LiquidityLevel    m_sellLiquidityLevels[10];// NEW: Sell-side liquidity levels
    int               m_buyLiquidityCount;      // NEW: Number of buy liquidity levels
    int               m_sellLiquidityCount;     // NEW: Number of sell liquidity levels
    
    // Multi-timeframe Analysis
    MTFWeights        m_mtfWeights;             // NEW: Multi-timeframe weights
    double            m_mtfTrendScore;          // NEW: Multi-timeframe trend score
    double            m_mtfMomentumScore;       // NEW: Multi-timeframe momentum score
    double            m_mtfVolatilityScore;     // NEW: Multi-timeframe volatility score
    
    // Threshold Parameters
    int               m_EMASlopePeriodsH1;      // EMA slope periods (H1)
    double            m_strongTrendThreshold;   // Strong trend threshold
    double            m_weakTrendThreshold;     // Weak trend threshold
    double            m_volatilityThreshold;    // Volatility threshold
    double            m_volumeSpikeThreshold;   // Volume spike threshold
    double            m_rsiOverboughtThreshold; // RSI overbought threshold
    double            m_rsiOversoldThreshold;   // RSI oversold threshold
    
    // Dynamic Thresholds
    double            m_dynamicAccumulationThreshold;   // Dynamic accumulation threshold
    double            m_dynamicImpulseThreshold;        // Dynamic impulse threshold
    double            m_dynamicCorrectionThreshold;     // Dynamic correction threshold
    double            m_dynamicDistributionThreshold;   // Dynamic distribution threshold
    double            m_dynamicExhaustionThreshold;     // Dynamic exhaustion threshold
    
    // Regime Analysis
    double            m_regimeConfidence;       // Regime confidence
    double            m_regimeTransitionScore;  // Regime transition score
    int               m_regimeAge;              // Regime age
    bool              m_isTransitioning;        // Transitioning flag
    
    // Market State
    bool              m_isTrending;             // Trending flag
    bool              m_isWeakTrend;            // Weak trend flag
    bool              m_isSideway;              // Sideway flag
    bool              m_isVolatile;             // Volatile flag
    bool              m_isRangebound;           // Range-bound flag
    bool              m_isInPullback;           // NEW: In pullback state
    bool              m_isInBreakout;           // NEW: In breakout state
    bool              m_isInFakeout;            // NEW: In fakeout state
    
    // Session & Phase
    ENUM_SESSION      m_currentSession;         // Current session
    ENUM_MARKET_PHASE m_marketPhase;            // Market phase
    
    // Market Conditions
    bool              m_isOverbought;           // Overbought flag
    bool              m_isOversold;             // Oversold flag
    
    // Key Price Levels
    double            m_recentSwingHigh;        // Recent swing high
    double            m_recentSwingLow;         // Recent swing low
    double            m_keyResistanceLevel;     // Key resistance level
    double            m_keySupportLevel;        // Key support level
    
    // Candlestick Pattern Recognition
    bool              m_hasEngulfing;           // NEW: Engulfing pattern
    bool              m_hasDoji;                // NEW: Doji pattern
    bool              m_hasPinbar;              // NEW: Pinbar pattern
    bool              m_hasInsideBar;           // NEW: Inside bar pattern
    bool              m_hasThreeLineStrike;     // NEW: Three-line strike pattern
    
    // For Order Block Detection
    datetime          m_lastBullishOBTime;      // NEW: Last bullish OB time 
    datetime          m_lastBearishOBTime;      // NEW: Last bearish OB time
    double            m_bullishOBHigh;          // NEW: Bullish OB high
    double            m_bullishOBLow;           // NEW: Bullish OB low
    double            m_bearishOBHigh;          // NEW: Bearish OB high
    double            m_bearishOBLow;           // NEW: Bearish OB low
    
    // Smart Money Concepts
    double            m_fairValueGap[5][3];     // NEW: Fair value gaps [index][high,low,age]
    int               m_fvgCount;               // NEW: FVG count
    double            m_liquidityGrabLevel;     // NEW: Liquidity grab level
    bool              m_hasBreakOfStructure;    // NEW: Break of structure flag
    bool              m_hasChangeOfCharacter;   // NEW: Change of character flag
    
    // Market Internals
    double            m_cumulativeDelta;        // NEW: Cumulative delta
    double            m_marketEfficiencyRatio;  // NEW: Market efficiency ratio (MER)
    double            m_correlationIndex;       // NEW: Correlation index
    
    // Performance Metrics for Trading Styles
    double            m_trendFollowingQuality;  // NEW: Trend-following quality
    double            m_counterTrendQuality;    // NEW: Counter-trend quality
    double            m_breakoutQuality;        // NEW: Breakout quality
    double            m_rangeQuality;           // NEW: Range trading quality
    
    // Cache for Performance Optimization
    double            m_cachedATRMultipliers[5];// NEW: Cached ATR multipliers
    double            m_cachedKeyLevels[10];    // NEW: Cached key levels
    datetime          m_keyLevelCacheTime;      // NEW: Key level cache time
    datetime          m_lastVolumeProfileTime;  // NEW: Last volume profile time
    
private:
    //--- Indicator Initialization and Release ---
    
    // Initialize all indicator handles
    bool              InitializeIndicators();
    
    // Release all indicator handles
    void              ReleaseIndicators();
    
    // Initialize secondary indicators (less critical)
    bool              InitializeSecondaryIndicators();
    
    //--- Data Update Methods ---
    
    // Primary indicator data update
    bool              UpdateIndicatorData();
    
    // Update multi-timeframe indicators
    bool              UpdateMTFIndicators();
    
    // Update volume profile data
    bool              UpdateVolumeProfile();
    
    // Update key price levels
    void              UpdateKeyLevels();
    
    // Update liquidity levels
    void              UpdateLiquidityLevels();
    
    // Update market patterns
    void              UpdateMarketPatterns();
    
    //--- Market Analysis Methods ---
    
    // Core market condition analysis
    void              AnalyzeMarketConditions();
    
    // Enhanced soft regime analysis
    void              AnalyzeMarketRegimeSoft();
    
    // Session-specific analysis
    void              AnalyzeSessionCharacteristics();
    
    // Analyze institutional activity
    void              AnalyzeInstitutionalActivity();
    
    // Analyze candlestick patterns
    void              AnalyzeCandlestickPatterns();
    
    // Analyze multi-timeframe confluence
    void              AnalyzeMTFConfluence();
    
    // Analyze market efficiency
    void              AnalyzeMarketEfficiency();
    
    // Detect order blocks and liquidity grabs
    void              DetectOrderBlocks();
    
    // Detect price action patterns
    bool              DetectPriceActionPatterns();
    
    //--- Calculation Methods ---
    
    // Calculate ATR slope
    double            CalculateATRSlope();
    
    // NEW: Calculate ATR acceleration (2nd derivative)
    double            CalculateATRAcceleration();
    
    // Calculate EMA slope
    double            CalculateSlopeEMA34();
    
    // Calculate distance between EMAs
    double            CalculateDistanceEMA89_200();
    
    // Calculate EMA alignment
    double            CalculateEMAAlignment();
    
    // NEW: Calculate multi-timeframe trend score
    double            CalculateMTFTrendScore();
    
    // NEW: Calculate multi-timeframe volatility score
    double            CalculateMTFVolatilityScore();
    
    // NEW: Calculate multi-timeframe momentum score
    double            CalculateMTFMomentumScore();
    
    // Calculate EMA slope statistics
    void              CalculateEMASlopeStatistics();
    
    // Calculate market efficiency ratio
    double            CalculateMarketEfficiencyRatio();
    
    // Calculate cumulative delta
    double            CalculateCumulativeDelta();
    
    // Calculate institutional activity score
    double            CalculateInstitutionalActivity();
    
    //--- Threshold Management ---
    
    // Update dynamic thresholds
    void              UpdateDynamicThresholds();
    
    // NEW: Adaptive threshold calculation based on market volatility
    double            CalculateAdaptiveThreshold(double baseThreshold, double volatilityFactor);
    
    //--- Market State Detection ---
    
    // Detect volume spike
    bool              DetectVolumeSpike();
    
    // Detect declining volume
    bool              DetectVolumeDeclining();
    
    // Detect high volatility
    bool              DetectVolatility();
    
    // Detect weak trend
    bool              DetectWeakTrend();
    
    // Detect sideways market
    bool              DetectSideway();
    
    // Detect range-bound market
    bool              DetectRangebound();
    
    // NEW: Detect breakout
    bool              DetectBreakout();
    
    // NEW: Detect pullback
    bool              DetectPullback();
    
    // NEW: Detect fakeout
    bool              DetectFakeout();
    
    // Determine current trading session
    ENUM_SESSION      DetermineCurrentSession();
    
    // Determine market phase
    ENUM_MARKET_PHASE DetermineMarketPhase();
    
    // NEW: Detect fair value gaps
    void              DetectFairValueGaps();
    
    // NEW: Detect break of structure 
    bool              DetectBreakOfStructure();
    
    // NEW: Detect change of character
    bool              DetectChangeOfCharacter();
    
    //--- Advanced Technical Analysis ---
    
    // Check if RSI is overbought
    bool              IsOverbought() const;
    
    // Check if RSI is oversold
    bool              IsOversold() const;
    
    // Check if MACD indicates uptrend
    bool              IsMACDUptrend() const;
    
    // Check if MACD indicates downtrend
    bool              IsMACDDowntrend() const;
    
    // Check if MACD is diverging from price
    bool              IsMACDDiverging() const;
    
    // NEW: Detect bullish divergence
    bool              DetectBullishDivergence();
    
    // NEW: Detect bearish divergence
    bool              DetectBearishDivergence();
    
    // NEW: Detect engulfing pattern
    bool              DetectEngulfingPattern();
    
    // NEW: Detect three inside up/down pattern
    bool              DetectThreeInsidePattern();
    
    // NEW: Detect morning/evening star pattern
    bool              DetectStarPattern();
    
    //--- Swing Point Analysis ---
    
    // Update swing points
    void              UpdateSwingPoints();
    
    // NEW: Identify higher highs and higher lows
    bool              IdentifyHHHL();
    
    // NEW: Identify lower highs and lower lows
    bool              IdentifyLHLL();
    
    //--- Price Level Analysis ---
    
    // Find key support/resistance levels
    void              FindKeyLevels();
    
    // NEW: Calculate dynamic support/resistance
    void              CalculateDynamicSR();
    
    // NEW: Identify value area high/low/POC
    void              IdentifyValueArea();
    
    //--- Safe Data Access ---
    
    // Safe copying of indicator buffer
    bool              SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[]);
    
    // Safe copying of volume data
    bool              SafeCopyVolume(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, long &array[]);
    
    //--- Trading Quality Assessment ---
    
    // NEW: Update quality scores for different trading styles
    void              UpdateTradingQualityScores();
    
    // NEW: Assess trend-following conditions
    double            AssessTrendFollowingConditions();
    
    // NEW: Assess counter-trend conditions
    double            AssessCounterTrendConditions();
    
    // NEW: Assess breakout conditions
    double            AssessBreakoutConditions();
    
    // NEW: Assess range trading conditions
    double            AssessRangeTradingConditions();

public:
    //--- Constructor/Destructor ---
    
    // Constructor
                      CMarketProfile();
    
    // Destructor
                     ~CMarketProfile();
    
    //--- Initialization ---
    
    // Initialize the market profile
    bool              Initialize(string symbol, ENUM_TIMEFRAMES timeframe = PERIOD_H1, int gmt_offset = 0);
    
    // Set logger instance
    void              SetLogger(CLogger* logger) { m_logger = logger; }
    
    //--- Parameter Settings ---
    
    // Set volatility threshold
    void              SetVolatilityThreshold(double threshold) { m_volatilityThreshold = (threshold > 0) ? threshold : 1.5; }
    
    // Set volume spike threshold
    void              SetVolumeSpikeThreshold(double threshold) { m_volumeSpikeThreshold = (threshold > 0) ? threshold : 2.0; }
    
    // Set weak trend threshold
    void              SetWeakTrendThreshold(double threshold) { m_weakTrendThreshold = (threshold > 0) ? threshold : 20.0; }
    
    // Set strong trend threshold
    void              SetStrongTrendThreshold(double threshold) { m_strongTrendThreshold = (threshold > 0) ? threshold : 25.0; }
    
    // Set RSI overbought threshold
    void              SetOverboughtThreshold(double threshold) { m_rsiOverboughtThreshold = (threshold > 50) ? threshold : 70.0; }
    
    // Set RSI oversold threshold
    void              SetOversoldThreshold(double threshold) { m_rsiOversoldThreshold = (threshold < 50) ? threshold : 30.0; }
    
    // Set max consecutive failed updates
    void              SetMaxConsecutiveFailedUpdates(int count) { m_maxConsecutiveFailedUpdates = (count > 0) ? count : 3; }
    
    // Set EMA slope periods
    void              SetEMASlopePeriodsH1(int periods) { m_EMASlopePeriodsH1 = (periods > 0) ? periods : 5; }
    
    // Set GMT offset
    void              SetGMTOffset(int offset) { m_GMT_Offset = offset; }
    
    // Set trend thresholds
    void              SetTrendThresholds(double strongThreshold, double weakThreshold);
    
    // NEW: Set multi-timeframe weights
    void              SetMTFWeights(double m15Weight, double h1Weight, double h4Weight, double d1Weight);
    
    // Set all parameters at once
    void              SetParameters(double volatilityThreshold, double volumeSpikeThreshold, 
                                  double weakTrendThreshold, double strongTrendThreshold,
                                  double overboughtThreshold, double oversoldThreshold,
                                  int maxConsecutiveFailedUpdates, int emaSlopePeriods,
                                  int gmtOffset);
    
    //--- Update Methods ---
    
    // Full update of market profile
    bool              Update();
    
    // Light update (minimal recalculation)
    bool              LightUpdate();
    
    //--- Core State Getters ---
    
    // Check if market is trending
    bool              IsTrending() const { return m_isTrending; }
    
    // Check if market is sideways
    bool              IsSideway() const { return m_isSideway; }
    
    // Check if market is volatile
    bool              IsVolatile() const { return m_isVolatile; }
    
    // Check if market has weak trend
    bool              IsWeakTrend() const { return m_isWeakTrend; }
    
    // Check if market is range-bound
    bool              IsRangebound() const { return m_isRangebound; }
    
    // Check if volume is spiking
    bool              HasVolumeSpike() const { return m_hasVolumeSpike; }
    
    //--- Enhanced State Getters ---
    
    // Check if market is transitioning between regimes
    bool              IsTransitioning() const { return m_isTransitioning; }
    
    // Get regime confidence
    double            GetRegimeConfidence() const { return m_regimeConfidence; }
    
    // Get regime age
    int               GetRegimeAge() const { return m_regimeAge; }
    
    // Get transition score
    double            GetTransitionScore() const { return m_regimeTransitionScore; }
    
    // Check if market is overextended
    bool              IsOverextended() const { return (m_isOverbought || m_isOversold); }
    
    // Get RSI overbought threshold
    double            GetOverboughtThreshold() const { return m_rsiOverboughtThreshold; }
    
    // Get RSI oversold threshold
    double            GetOversoldThreshold() const { return m_rsiOversoldThreshold; }
    
    // NEW: Check if in pullback
    bool              IsInPullback() const { return m_isInPullback; }
    
    // NEW: Check if in breakout 
    bool              IsInBreakout() const { return m_isInBreakout; }
    
    // NEW: Check if in fakeout
    bool              IsInFakeout() const { return m_isInFakeout; }
    
    // NEW: Check for engulfing pattern
    bool              HasEngulfingPattern() const { return m_hasEngulfing; }
    
    // NEW: Check for doji pattern
    bool              HasDojiPattern() const { return m_hasDoji; }
    
    // NEW: Check for pinbar pattern 
    bool              HasPinbarPattern() const { return m_hasPinbar; }
    
    // NEW: Check for bullish divergence
    bool              HasBullishDivergence() const;
    
    // NEW: Check for bearish divergence
    bool              HasBearishDivergence() const;
    
    // NEW: Check for break of structure
    bool              HasBreakOfStructure() const { return m_hasBreakOfStructure; }
    
    // NEW: Check for change of character
    bool              HasChangeOfCharacter() const { return m_hasChangeOfCharacter; }
    
    //--- Indicator Data Getters ---
    
    // Get ADX M15
    double            GetADXM15() const { return m_adxM15; }
    
    // Get ADX H1
    double            GetADXH1() const { return m_adxH1; }
    
    // Get ADX H4
    double            GetADXH4() const { return m_adxH4; }
    
    // Get DI+
    double            GetDIPlus() const { return m_di_plus_h1; }
    
    // Get DI-
    double            GetDIMinus() const { return m_di_minus_h1; }
    
    // Get ATR H1
    double            GetATRH1() const { return m_atrH1; }
    
    // Get ATR H4
    double            GetATRH4() const { return m_atrH4; }
    
    // Get ATR slope
    double            GetATRSlope() const { return m_atrSlope; }
    
    // Get current volume
    double            GetVolumeCurrent() const { return m_volumeCurrent; }
    
    // Get volume SMA20
    double            GetVolumeSMA20() const { return m_volumeSMA20; }
    
    // Get EMA34 slope
    double            GetSlopeEMA34() const { return m_slopeEMA34H1; }
    
    // Get EMA alignment
    double            GetEMAAlignment() const { return m_emaAlignment; }
    
    // Get EMA distance
    double            GetDistanceEMA() const { return m_distanceEMA89_200_H1; }
    
    // Get ATR ratio
    double            GetATRRatio() const { return m_atrRatio; }
    
    // Get RSI
    double            GetRSI() const { return m_rsiH1; }
    
    // Get MACD main line
    double            GetMACDMain() const { return m_macdMain; }
    
    // Get MACD signal line
    double            GetMACDSignal() const { return m_macdSignal; }
    
    // Get MACD histogram
    double            GetMACDHistogram() const { return m_macdHistogram; }
    
    //--- New Indicator Data Getters ---
    
    // NEW: Get cumulative delta
    double            GetCumulativeDelta() const { return m_cumulativeDelta; }
    
    // NEW: Get market efficiency ratio
    double            GetMarketEfficiencyRatio() const { return m_marketEfficiencyRatio; }
    
    // NEW: Get ATR acceleration
    double            GetATRAcceleration() const;
    
    // NEW: Get multi-timeframe trend score
    double            GetMTFTrendScore() const { return m_mtfTrendScore; }
    
    // NEW: Get multi-timeframe volatility score
    double            GetMTFVolatilityScore() const { return m_mtfVolatilityScore; }
    
    // NEW: Get multi-timeframe momentum score
    double            GetMTFMomentumScore() const { return m_mtfMomentumScore; }
    
    // NEW: Get value area high
    double            GetValueAreaHigh() const { return m_valueAreaHigh; }
    
    // NEW: Get value area low
    double            GetValueAreaLow() const { return m_valueAreaLow; }
    
    // NEW: Get point of control
    double            GetPointOfControl() const { return m_pointOfControl; }
    
    // NEW: Get bullish order block high
    double            GetBullishOBHigh() const { return m_bullishOBHigh; }
    
    // NEW: Get bullish order block low
    double            GetBullishOBLow() const { return m_bullishOBLow; }
    
    // NEW: Get bearish order block high
    double            GetBearishOBHigh() const { return m_bearishOBHigh; }
    
    // NEW: Get bearish order block low
    double            GetBearishOBLow() const { return m_bearishOBLow; }
    
    //--- Session & Phase Getters ---
    
    // Get current session
    ENUM_SESSION      GetCurrentSession() const { return m_currentSession; }
    
    // Get market phase
    ENUM_MARKET_PHASE GetMarketPhase() const { return m_marketPhase; }
    
    //--- Price Level Getters ---
    
    // Get key resistance
    double            GetKeyResistance() const { return m_keyResistanceLevel; }
    
    // Get key support
    double            GetKeySupport() const { return m_keySupportLevel; }
    
    // Get recent swing high
    double            GetRecentSwingHigh() const { return m_recentSwingHigh; }
    
    // Get recent swing low
    double            GetRecentSwingLow() const { return m_recentSwingLow; }
    
    //--- Status Getters ---
    
    // Check if data is reliable
    bool              IsDataReliable() const { return m_isDataReliable; }
    
    //--- Advanced Analysis Methods ---
    
    // Check if price is near key level
    bool              IsNearKeyLevel(double price = 0);
    
    // Check for positive momentum
    bool              HasPositiveMomentum(bool isLong) const;
    
    // Check if price is near EMA
    bool              IsPriceNearEma(int emaPeriod, bool isLong, double maxDistance = 0);
    
    // Check for key support
    bool              HasKeySupport();
    
    // Check for key resistance
    bool              HasKeyResistance();
    
    // Check for uptrend
    bool              IsTrendUp() const;
    
    // Check for downtrend
    bool              IsTrendDown() const;
    
    // Check for strong trend
    bool              IsStrongTrend() const;
    
    //--- Trading Quality Assessment ---
    
    // Get trend-following quality
    double            GetTrendFollowingQuality() const { return m_trendFollowingQuality; }
    
    // Get counter-trend quality
    double            GetCounterTrendQuality() const { return m_counterTrendQuality; }
    
    // Get breakout quality
    double            GetBreakoutQuality() const { return m_breakoutQuality; }
    
    // Get range trading quality
    double            GetRangeTradingQuality() const { return m_rangeQuality; }
    
    //--- Prediction & Evaluation Methods ---
    
    // Predict trend continuation probability
    double            PredictTrendContinuationProbability();
    
    // Evaluate setup quality
    double            EvaluateSetupQuality(bool isLong, ENUM_ENTRY_SCENARIO scenario);
    
    // Evaluate market for trend trading
    double            EvaluateMarketForTrend();
    
    // Evaluate market for counter-trend trading
    double            EvaluateMarketForCountertrend();
    
    // Evaluate market for scaling
    double            EvaluateMarketForScaling();
    
    // NEW: Evaluate market for breakout trading
    double            EvaluateMarketForBreakout();
    
    // NEW: Evaluate market for pullback trading
    double            EvaluateMarketForPullback();
    
    // NEW: Evaluate market for range trading
    double            EvaluateMarketForRange();
    
    //--- Output Methods ---
    
    // Log market profile details
    void              LogMarketProfile();
    
    // Get market profile summary
    string            GetMarketProfileSummary();
    
    // Infer market regime from profile
    ENUM_MARKET_REGIME GetMarketRegimeBasedOnProfile();
    
    // Create complete market profile struct
    MarketProfile     CreateMarketProfile();
    
    // NEW: Export key levels to string
    string            ExportKeyLevelsToString();
    
    // NEW: Create visual representation of market profile
    string            CreateVisualProfile();
    
    // NEW: Export market profile to JSON
    string            ExportMarketProfileToJSON();
    
    // NEW: Get detailed liquidity analysis
    string            GetLiquidityAnalysis();
    
    // NEW: Get institutional activity report
    string            GetInstitutionalReport();
    
    // NEW: Create comprehensive session analysis
    string            CreateSessionAnalysis(bool includeStats);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketProfile::CMarketProfile()
{
    // Initialize core variables
    m_symbol = Symbol();
    m_timeframe = PERIOD_H1;
    m_logger = NULL;
    
    // Initialize all handles to INVALID_HANDLE
    m_handleADX_M15 = INVALID_HANDLE;
    m_handleATR_M15 = INVALID_HANDLE;
    m_handleRSI_M15 = INVALID_HANDLE;
    m_handleMACD_M15 = INVALID_HANDLE;
    m_handleEMA21_M15 = INVALID_HANDLE;
    m_handleEMA50_M15 = INVALID_HANDLE;
    
    m_handleADX_H1 = INVALID_HANDLE;
    m_handleATR_H1 = INVALID_HANDLE;
    m_handleEMA34_H1 = INVALID_HANDLE;
    m_handleEMA89_H1 = INVALID_HANDLE;
    m_handleEMA200_H1 = INVALID_HANDLE;
    m_handleRSI_H1 = INVALID_HANDLE;
    m_handleMACD_H1 = INVALID_HANDLE;
    m_handleStochastic_H1 = INVALID_HANDLE;
    
    m_handleADX_H4 = INVALID_HANDLE;
    m_handleATR_H4 = INVALID_HANDLE;
    m_handleEMA34_H4 = INVALID_HANDLE;
    m_handleEMA89_H4 = INVALID_HANDLE;
    m_handleEMA200_H4 = INVALID_HANDLE;
    m_handleRSI_H4 = INVALID_HANDLE;
    m_handleMACD_H4 = INVALID_HANDLE;
    
    m_handleATR_D1 = INVALID_HANDLE;
    m_handleEMA21_D1 = INVALID_HANDLE;
    m_handleEMA50_D1 = INVALID_HANDLE;
    m_handleEMA200_D1 = INVALID_HANDLE;
    
    // Initialize indicator values
    m_adxM15 = 0.0;
    m_di_plus_m15 = 0.0;
    m_di_minus_m15 = 0.0;
    m_atrM15 = 0.0;
    m_rsiM15 = 50.0;
    m_macdHistogram_M15 = 0.0;
    
    m_adxH1 = 0.0;
    m_adxPrev = 0.0;
    m_di_plus_h1 = 0.0;
    m_di_minus_h1 = 0.0;
    m_atrH1 = 0.0;
    m_slopeEMA34H1 = 0.0;
    m_emaSlope_prev = 0.0;
    m_distanceEMA89_200_H1 = 0.0;
    m_emaAlignment = 0.0;
    m_rsiH1 = 50.0;
    m_macdMain = 0.0;
    m_macdSignal = 0.0;
    m_macdHistogram = 0.0;
    m_macdHistogramPrev = 0.0;
    m_stochMain = 50.0;
    m_stochSignal = 50.0;
    
    m_adxH4 = 0.0;
    m_atrH4 = 0.0;
    m_rsiH4 = 50.0;
    m_macdHistogram_H4 = 0.0;
    m_di_plus_h4 = 0.0;
    m_di_minus_h4 = 0.0;
    
    m_atrD1 = 0.0;
    
    // Initialize volume data
    m_volumeCurrent = 0.0;
    m_volumeSMA20 = 0.0;
    m_hasVolumeSpike = false;
    
    // Initialize statistical data
    m_avgEMASlope = 0.0;
    m_emaSlopeStdDev = 0.1;
    
    // Initialize volume profile data
    m_volumeProfileSize = 0;
    m_valueAreaHigh = 0.0;
    m_valueAreaLow = 0.0;
    m_pointOfControl = 0.0;
    
    // Initialize liquidity data
    m_buyLiquidityCount = 0;
    m_sellLiquidityCount = 0;
    
    // Initialize MTF analysis data
    m_mtfTrendScore = 0.0;
    m_mtfMomentumScore = 0.0;
    m_mtfVolatilityScore = 0.5;
    
    // Initialize thresholds
    m_EMASlopePeriodsH1 = 10;
    m_volatilityThreshold = 1.5;
    m_volumeSpikeThreshold = 1.5;
    m_GMT_Offset = 0;
    m_strongTrendThreshold = 25.0;
    m_weakTrendThreshold = 18.0;
    m_rsiOverboughtThreshold = 70.0;
    m_rsiOversoldThreshold = 30.0;
    m_maxConsecutiveFailedUpdates = 3;
    
    // Initialize dynamic thresholds
    m_dynamicAccumulationThreshold = 0.1;
    m_dynamicImpulseThreshold = 0.3;
    m_dynamicCorrectionThreshold = 0.2;
    m_dynamicDistributionThreshold = -0.1;
    m_dynamicExhaustionThreshold = 0.5;
    
    // Initialize regime analysis data
    m_regimeConfidence = 0.0;
    m_regimeTransitionScore = 0.0;
    m_regimeAge = 0;
    m_isTransitioning = false;
    
    // Initialize market state flags
    m_isInitialized = false;
    m_isDataReliable = true;
    m_failedUpdatesCount = 0;
    m_isTrending = false;
    m_isWeakTrend = false;
    m_isSideway = false;
    m_isVolatile = false;
    m_isRangebound = false;
    m_isInPullback = false;
    m_isInBreakout = false;
    m_isInFakeout = false;
    
    // Initialize session and phase
    m_currentSession = SESSION_UNKNOWN;
    m_marketPhase = PHASE_ACCUMULATION;
    
    // Initialize market condition flags
    m_isOverbought = false;
    m_isOversold = false;
    
    // Initialize price levels
    m_recentSwingHigh = 0.0;
    m_recentSwingLow = 0.0;
    m_keyResistanceLevel = 0.0;
    m_keySupportLevel = 0.0;
    
    // Initialize pattern recognition flags
    m_hasEngulfing = false;
    m_hasDoji = false;
    m_hasPinbar = false;
    m_hasInsideBar = false;
    m_hasThreeLineStrike = false;
    
    // Initialize order block data
    m_lastBullishOBTime = 0;
    m_lastBearishOBTime = 0;
    m_bullishOBHigh = 0.0;
    m_bullishOBLow = 0.0;
    m_bearishOBHigh = 0.0;
    m_bearishOBLow = 0.0;
    
    // Initialize smart money concept flags
    m_fvgCount = 0;
    m_liquidityGrabLevel = 0.0;
    m_hasBreakOfStructure = false;
    m_hasChangeOfCharacter = false;
    
    // Initialize market internals
    m_cumulativeDelta = 0.0;
    m_marketEfficiencyRatio = 0.5;
    m_correlationIndex = 0.0;
    
    // Initialize trading quality metrics
    m_trendFollowingQuality = 0.5;
    m_counterTrendQuality = 0.5;
    m_breakoutQuality = 0.5;
    m_rangeQuality = 0.5;
    
    // Initialize cache timestamps
    m_keyLevelCacheTime = 0;
    m_lastVolumeProfileTime = 0;
    
    // Initialize multi-timeframe weights
    m_mtfWeights = MTFWeights(); // Use default weights
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketProfile::~CMarketProfile()
{
    // Release all indicator handles
    ReleaseIndicators();
    
    // Don't release logger as it's owned externally
    m_logger = NULL;
}

//+------------------------------------------------------------------+
//| Initialize the Market Profile                                    |
//+------------------------------------------------------------------+
bool CMarketProfile::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, int gmt_offset)
{
    // Store basic parameters
    m_symbol = symbol;
    m_timeframe = timeframe;
    m_GMT_Offset = gmt_offset;
    
    // Validate symbol
    if (m_symbol == "") {
        if (m_logger) m_logger.LogError("MarketProfile::Initialize - Invalid symbol");
        return false;
    }
    
    // Initialize indicators
    if (!InitializeIndicators()) {
        if (m_logger) m_logger.LogError("MarketProfile::Initialize - Failed to initialize indicators");
        return false;
    }
    
    // Initialize volume profile array
    ArrayResize(m_volumeProfile, 100);
    m_volumeProfileSize = 0;
    
    // Initialize secondary indicators (non-critical)
    InitializeSecondaryIndicators();
    
    // Perform initial data update
    if (!UpdateIndicatorData()) {
        if (m_logger) m_logger.LogWarning("MarketProfile::Initialize - Initial data update failed, will retry");
        // Continue anyway, might succeed on subsequent updates
    }
    
    m_isInitialized = true;
    if (m_logger) m_logger.LogInfo(StringFormat(
        "MarketProfile initialized for %s on %s timeframe", 
        m_symbol, 
        EnumToString(m_timeframe)
    ));
    
    return true;
}

//+------------------------------------------------------------------+
//| Set trend thresholds                                             |
//+------------------------------------------------------------------+
void CMarketProfile::SetTrendThresholds(double strongThreshold, double weakThreshold)
{
    // Ensure strong threshold is higher than weak threshold
    m_strongTrendThreshold = MathMax(strongThreshold, weakThreshold + 5.0);
    m_weakTrendThreshold = weakThreshold;
    
    if (m_logger) m_logger.LogInfo(StringFormat(
        "Trend thresholds set: Strong=%.1f, Weak=%.1f", 
        m_strongTrendThreshold, m_weakTrendThreshold
    ));
}

//+------------------------------------------------------------------+
//| Set multi-timeframe weights                                      |
//+------------------------------------------------------------------+
void CMarketProfile::SetMTFWeights(double m15Weight, double h1Weight, double h4Weight, double d1Weight)
{
    m_mtfWeights = MTFWeights(m15Weight, h1Weight, h4Weight, d1Weight);
    
    if (m_logger) m_logger.LogInfo(StringFormat(
        "MTF weights set: M15=%.2f, H1=%.2f, H4=%.2f, D1=%.2f", 
        m_mtfWeights.m15Weight, m_mtfWeights.h1Weight,
        m_mtfWeights.h4Weight, m_mtfWeights.d1Weight
    ));
}

//+------------------------------------------------------------------+
//| Set all parameters at once                                       |
//+------------------------------------------------------------------+
void CMarketProfile::SetParameters(double volatilityThreshold, double volumeSpikeThreshold, 
                                double weakTrendThreshold, double strongTrendThreshold,
                                double overboughtThreshold, double oversoldThreshold,
                                int maxConsecutiveFailedUpdates, int emaSlopePeriods,
                                int gmtOffset)
{
    // Set individual thresholds
    SetVolatilityThreshold(volatilityThreshold);
    SetVolumeSpikeThreshold(volumeSpikeThreshold);
    SetWeakTrendThreshold(weakTrendThreshold);
    SetStrongTrendThreshold(strongThreshold);
    SetOverboughtThreshold(overboughtThreshold);
    SetOversoldThreshold(oversoldThreshold);
    
    // Set other parameters
    SetMaxConsecutiveFailedUpdates(maxConsecutiveFailedUpdates);
    SetEMASlopePeriodsH1(emaSlopePeriods);
    SetGMTOffset(gmtOffset);
    
    // Log parameters
    if (m_logger) m_logger.LogInfo(StringFormat(
        "MarketProfile parameters set: Vol=%.2f, VolSpike=%.2f, ADX(W/S)=%.1f/%.1f, RSI(O/S)=%.1f/%.1f", 
        volatilityThreshold, volumeSpikeThreshold, 
        weakTrendThreshold, strongTrendThreshold,
        overboughtThreshold, oversoldThreshold
    ));
    
    // Initialize dynamic thresholds with default values
    // They will be updated automatically based on market data
    m_dynamicAccumulationThreshold = 0.1;
    m_dynamicImpulseThreshold = 0.3;
    m_dynamicCorrectionThreshold = 0.2;
    m_dynamicDistributionThreshold = -0.1;
    m_dynamicExhaustionThreshold = 0.5;
}

//+------------------------------------------------------------------+
//| Initialize all indicators                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::InitializeIndicators()
{
    // Release any existing handles first
    ReleaseIndicators();
    
    // Initialize core indicators (required for basic functionality)
    
    // === M15 Timeframe Indicators ===
    m_handleADX_M15 = iADX(m_symbol, PERIOD_M15, 14);
    // ATR M15 will be initialized in secondary indicators
    
    // === H1 Timeframe Indicators (primary) ===
    m_handleADX_H1 = iADX(m_symbol, PERIOD_H1, 14);
    if (m_handleADX_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize ADX H1");
        return false;
    }
    
    m_handleATR_H1 = iATR(m_symbol, PERIOD_H1, 14);
    if (m_handleATR_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize ATR H1");
        return false;
    }
    
    m_handleEMA34_H1 = iMA(m_symbol, PERIOD_H1, 34, 0, MODE_EMA, PRICE_CLOSE);
    if (m_handleEMA34_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize EMA34 H1");
        return false;
    }
    
    m_handleEMA89_H1 = iMA(m_symbol, PERIOD_H1, 89, 0, MODE_EMA, PRICE_CLOSE);
    if (m_handleEMA89_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize EMA89 H1");
        return false;
    }
    
    m_handleEMA200_H1 = iMA(m_symbol, PERIOD_H1, 200, 0, MODE_EMA, PRICE_CLOSE);
    if (m_handleEMA200_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize EMA200 H1");
        return false;
    }
    
    m_handleRSI_H1 = iRSI(m_symbol, PERIOD_H1, 14, PRICE_CLOSE);
    if (m_handleRSI_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize RSI H1");
        return false;
    }
    
    m_handleMACD_H1 = iMACD(m_symbol, PERIOD_H1, 12, 26, 9, PRICE_CLOSE);
    if (m_handleMACD_H1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize MACD H1");
        return false;
    }
    
    // === H4 Timeframe Indicators ===
    m_handleADX_H4 = iADX(m_symbol, PERIOD_H4, 14);
    if (m_handleADX_H4 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize ADX H4");
        return false;
    }
    
    m_handleATR_H4 = iATR(m_symbol, PERIOD_H4, 14);
    if (m_handleATR_H4 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("Failed to initialize ATR H4");
        return false;
    }
    
    // === D1 Timeframe Indicators ===
    m_handleATR_D1 = iATR(m_symbol, PERIOD_D1, 14);
    if (m_handleATR_D1 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogWarning("Failed to initialize ATR D1");
        // Non-critical, continue
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Initialize secondary (non-critical) indicators                   |
//+------------------------------------------------------------------+
bool CMarketProfile::InitializeSecondaryIndicators()
{
    bool allSuccessful = true;
    
    // === M15 Timeframe Secondary Indicators ===
    if (m_handleATR_M15 == INVALID_HANDLE)
        m_handleATR_M15 = iATR(m_symbol, PERIOD_M15, 14);
    
    if (m_handleRSI_M15 == INVALID_HANDLE)
        m_handleRSI_M15 = iRSI(m_symbol, PERIOD_M15, 14, PRICE_CLOSE);
    
    if (m_handleMACD_M15 == INVALID_HANDLE)
        m_handleMACD_M15 = iMACD(m_symbol, PERIOD_M15, 12, 26, 9, PRICE_CLOSE);
    
    if (m_handleEMA21_M15 == INVALID_HANDLE)
        m_handleEMA21_M15 = iMA(m_symbol, PERIOD_M15, 21, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleEMA50_M15 == INVALID_HANDLE)
        m_handleEMA50_M15 = iMA(m_symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
    
    // === H1 Timeframe Secondary Indicators ===
    if (m_handleStochastic_H1 == INVALID_HANDLE)
        m_handleStochastic_H1 = iStochastic(m_symbol, PERIOD_H1, 14, 3, 3, MODE_SMA, STO_LOWHIGH);
    
    // === H4 Timeframe Secondary Indicators ===
    if (m_handleEMA34_H4 == INVALID_HANDLE)
        m_handleEMA34_H4 = iMA(m_symbol, PERIOD_H4, 34, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleEMA89_H4 == INVALID_HANDLE)
        m_handleEMA89_H4 = iMA(m_symbol, PERIOD_H4, 89, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleEMA200_H4 == INVALID_HANDLE)
        m_handleEMA200_H4 = iMA(m_symbol, PERIOD_H4, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleRSI_H4 == INVALID_HANDLE)
        m_handleRSI_H4 = iRSI(m_symbol, PERIOD_H4, 14, PRICE_CLOSE);
    
    if (m_handleMACD_H4 == INVALID_HANDLE)
        m_handleMACD_H4 = iMACD(m_symbol, PERIOD_H4, 12, 26, 9, PRICE_CLOSE);
    
    // === D1 Timeframe Secondary Indicators ===
    if (m_handleEMA21_D1 == INVALID_HANDLE)
        m_handleEMA21_D1 = iMA(m_symbol, PERIOD_D1, 21, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleEMA50_D1 == INVALID_HANDLE)
        m_handleEMA50_D1 = iMA(m_symbol, PERIOD_D1, 50, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_handleEMA200_D1 == INVALID_HANDLE)
        m_handleEMA200_D1 = iMA(m_symbol, PERIOD_D1, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    // Log any failures but don't abort initialization
    if (m_handleATR_M15 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogWarning("Secondary indicator ATR M15 failed to initialize");
        allSuccessful = false;
    }
    
    if (m_handleRSI_M15 == INVALID_HANDLE) {
        if (m_logger) m_logger.LogWarning("Secondary indicator RSI M15 failed to initialize");
        allSuccessful = false;
    }
    
    // Add more checks for other indicators as needed
    
    if (!allSuccessful && m_logger)
        m_logger.LogInfo("Some secondary indicators failed to initialize - non-critical");
    
    return true; // Always return true as these are non-critical
}

//+------------------------------------------------------------------+
//| Release all indicator handles                                    |
//+------------------------------------------------------------------+
void CMarketProfile::ReleaseIndicators()
{
    // === Release M15 Indicators ===
    if (m_handleADX_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleADX_M15);
        m_handleADX_M15 = INVALID_HANDLE;
    }
    
    if (m_handleATR_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR_M15);
        m_handleATR_M15 = INVALID_HANDLE;
    }
    
    if (m_handleRSI_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleRSI_M15);
        m_handleRSI_M15 = INVALID_HANDLE;
    }
    
    if (m_handleMACD_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleMACD_M15);
        m_handleMACD_M15 = INVALID_HANDLE;
    }
    
    if (m_handleEMA21_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA21_M15);
        m_handleEMA21_M15 = INVALID_HANDLE;
    }
    
    if (m_handleEMA50_M15 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA50_M15);
        m_handleEMA50_M15 = INVALID_HANDLE;
    }
    
    // === Release H1 Indicators ===
    if (m_handleADX_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleADX_H1);
        m_handleADX_H1 = INVALID_HANDLE;
    }
    
    if (m_handleATR_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR_H1);
        m_handleATR_H1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA34_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA34_H1);
        m_handleEMA34_H1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA89_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA89_H1);
        m_handleEMA89_H1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA200_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA200_H1);
        m_handleEMA200_H1 = INVALID_HANDLE;
    }
    
    if (m_handleRSI_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleRSI_H1);
        m_handleRSI_H1 = INVALID_HANDLE;
    }
    
    if (m_handleMACD_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleMACD_H1);
        m_handleMACD_H1 = INVALID_HANDLE;
    }
    
    if (m_handleStochastic_H1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleStochastic_H1);
        m_handleStochastic_H1 = INVALID_HANDLE;
    }
    
    // === Release H4 Indicators ===
    if (m_handleADX_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleADX_H4);
        m_handleADX_H4 = INVALID_HANDLE;
    }
    
    if (m_handleATR_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR_H4);
        m_handleATR_H4 = INVALID_HANDLE;
    }
    
    if (m_handleEMA34_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA34_H4);
        m_handleEMA34_H4 = INVALID_HANDLE;
    }
    
    if (m_handleEMA89_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA89_H4);
        m_handleEMA89_H4 = INVALID_HANDLE;
    }
    
    if (m_handleEMA200_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA200_H4);
        m_handleEMA200_H4 = INVALID_HANDLE;
    }
    
    if (m_handleRSI_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleRSI_H4);
        m_handleRSI_H4 = INVALID_HANDLE;
    }
    
    if (m_handleMACD_H4 != INVALID_HANDLE) {
        IndicatorRelease(m_handleMACD_H4);
        m_handleMACD_H4 = INVALID_HANDLE;
    }
    
    // === Release D1 Indicators ===
    if (m_handleATR_D1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR_D1);
        m_handleATR_D1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA21_D1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA21_D1);
        m_handleEMA21_D1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA50_D1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA50_D1);
        m_handleEMA50_D1 = INVALID_HANDLE;
    }
    
    if (m_handleEMA200_D1 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA200_D1);
        m_handleEMA200_D1 = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Safe copy of indicator buffer                                    |
//+------------------------------------------------------------------+
bool CMarketProfile::SafeCopyBuffer(int handle, int buffer, int startPos, int count, double &array[])
{
    // Check for valid handle
    if (handle == INVALID_HANDLE) {
        if (m_logger) m_logger.LogError("SafeCopyBuffer: Invalid handle");
        return false;
    }
    
    // Resize array if needed
    if (ArraySize(array) < count) {
        if (ArrayResize(array, count) == -1) {
            if (m_logger) m_logger.LogError("SafeCopyBuffer: Failed to resize array");
            return false;
        }
    }
    
    // Copy buffer data
    int copied = CopyBuffer(handle, buffer, startPos, count, array);
    
    // Verify copy was successful
    if (copied != count) {
        if (m_logger) m_logger.LogError(StringFormat(
            "SafeCopyBuffer: Copy failed, requested %d, got %d", 
            count, copied
        ));
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Safe copy of volume data                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::SafeCopyVolume(string symbol, ENUM_TIMEFRAMES timeframe, int startPos, int count, long &array[])
{
    // Check parameters
    if (symbol == "" || timeframe == 0) {
        if (m_logger) m_logger.LogError("SafeCopyVolume: Invalid parameters");
        return false;
    }
    
    // Resize array if needed
    if (ArraySize(array) < count) {
        if (ArrayResize(array, count) == -1) {
            if (m_logger) m_logger.LogError("SafeCopyVolume: Failed to resize array");
            return false;
        }
    }
    
    // Copy volume data
    int copied = CopyTickVolume(symbol, timeframe, startPos, count, array);
    
    // Verify copy was successful
    if (copied != count) {
        if (m_logger) m_logger.LogError(StringFormat(
            "SafeCopyVolume: Copy failed, requested %d, got %d", 
            count, copied
        ));
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update indicator data                                            |
//+------------------------------------------------------------------+
bool CMarketProfile::UpdateIndicatorData()
{
    if (!m_isInitialized) {
        if (m_logger) m_logger.LogError("UpdateIndicatorData: MarketProfile not initialized");
        return false;
    }
    
    bool updateSuccessful = true;   // Track overall success
    bool criticalError = false;     // Track critical errors
    
    //--- Update M15 Indicators ---
    
    // Update ADX M15
    if (m_handleADX_M15 != INVALID_HANDLE) {
        double adxBuffer[], diPlusBuffer[], diMinusBuffer[];
        ArraySetAsSeries(adxBuffer, true);
        ArraySetAsSeries(diPlusBuffer, true);
        ArraySetAsSeries(diMinusBuffer, true);
        
        if (SafeCopyBuffer(m_handleADX_M15, 0, 0, 1, adxBuffer)) {
            m_adxM15 = adxBuffer[0];
            
            // Also copy DI+ and DI- values
            if (SafeCopyBuffer(m_handleADX_M15, 1, 0, 1, diPlusBuffer) &&
                SafeCopyBuffer(m_handleADX_M15, 2, 0, 1, diMinusBuffer)) {
                m_di_plus_m15 = diPlusBuffer[0];
                m_di_minus_m15 = diMinusBuffer[0];
            }
        }
        else {
            updateSuccessful = false;
            // Not critical for M15 timeframe
        }
    }
    
    // Update ATR M15
    if (m_handleATR_M15 != INVALID_HANDLE) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if (SafeCopyBuffer(m_handleATR_M15, 0, 0, 1, atrBuffer)) {
            m_atrM15 = atrBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical for M15 timeframe
        }
    }
    
    // Update RSI M15
    if (m_handleRSI_M15 != INVALID_HANDLE) {
        double rsiBuffer[];
        ArraySetAsSeries(rsiBuffer, true);
        
        if (SafeCopyBuffer(m_handleRSI_M15, 0, 0, 1, rsiBuffer)) {
            m_rsiM15 = rsiBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical for M15 timeframe
        }
    }
    
    // Update MACD M15
    if (m_handleMACD_M15 != INVALID_HANDLE) {
        double macdMainBuffer[], macdSignalBuffer[];
        ArraySetAsSeries(macdMainBuffer, true);
        ArraySetAsSeries(macdSignalBuffer, true);
        
        if (SafeCopyBuffer(m_handleMACD_M15, 0, 0, 1, macdMainBuffer) &&
            SafeCopyBuffer(m_handleMACD_M15, 1, 0, 1, macdSignalBuffer)) {
            m_macdHistogram_M15 = macdMainBuffer[0] - macdSignalBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical for M15 timeframe
        }
    }
    
    //--- Update H1 Indicators (Primary) ---
    
    // Update ADX H1
    double adxBuffer[], diPlusBuffer[], diMinusBuffer[];
    ArraySetAsSeries(adxBuffer, true);
    ArraySetAsSeries(diPlusBuffer, true);
    ArraySetAsSeries(diMinusBuffer, true);
    
    if (!SafeCopyBuffer(m_handleADX_H1, 0, 0, 1, adxBuffer)) {
        if (m_logger) m_logger.LogError("UpdateIndicatorData: Failed to update ADX H1 - critical indicator");
        criticalError = true;
        updateSuccessful = false;
    }
    else {
        // Store previous ADX value before updating
        m_adxPrev = m_adxH1;
        m_adxH1 = adxBuffer[0];
        
        // Update DI+ and DI- values
        if (SafeCopyBuffer(m_handleADX_H1, 1, 0, 1, diPlusBuffer) &&
            SafeCopyBuffer(m_handleADX_H1, 2, 0, 1, diMinusBuffer)) {
            m_di_plus_h1 = diPlusBuffer[0];
            m_di_minus_h1 = diMinusBuffer[0];
        }
    }
    
    // Update ATR H1
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 1, atrBuffer)) {
        if (m_logger) m_logger.LogError("UpdateIndicatorData: Failed to update ATR H1 - critical indicator");
        criticalError = true;
        updateSuccessful = false;
    }
    else {
        m_atrH1 = atrBuffer[0];
    }
    
    // Update EMA34 H1
    double ema34Buffer[];
    ArraySetAsSeries(ema34Buffer, true);
    
    if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, m_EMASlopePeriodsH1 + 1, ema34Buffer)) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update EMA34 H1");
        updateSuccessful = false;
    }
    else {
        // Store previous EMA slope before updating
        m_emaSlope_prev = m_slopeEMA34H1;
        
        // Calculate EMA slope
        m_slopeEMA34H1 = CalculateSlopeEMA34();
    }
    
    // Update EMA89 and EMA200 H1
    double ema89Buffer[], ema200Buffer[];
    ArraySetAsSeries(ema89Buffer, true);
    ArraySetAsSeries(ema200Buffer, true);
    
    bool emaUpdated = SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89Buffer) && 
                     SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200Buffer);
    
    if (!emaUpdated) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update EMA89/EMA200 H1");
        updateSuccessful = false;
    }
    else {
        // Calculate EMA distance
        m_distanceEMA89_200_H1 = (ema89Buffer[0] - ema200Buffer[0]) / m_atrH1;
        
        // Calculate EMA alignment
        m_emaAlignment = CalculateEMAAlignment();
    }
    
    // Update RSI H1
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    
    if (!SafeCopyBuffer(m_handleRSI_H1, 0, 0, 1, rsiBuffer)) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update RSI H1");
        updateSuccessful = false;
    }
    else {
        m_rsiH1 = rsiBuffer[0];
        
        // Update overbought/oversold flags
        m_isOverbought = (m_rsiH1 > m_rsiOverboughtThreshold);
        m_isOversold = (m_rsiH1 < m_rsiOversoldThreshold);
    }
    
    // Update MACD H1
    double macdMainBuffer[], macdSignalBuffer[];
    ArraySetAsSeries(macdMainBuffer, true);
    ArraySetAsSeries(macdSignalBuffer, true);
    
    bool macdUpdated = SafeCopyBuffer(m_handleMACD_H1, 0, 0, 1, macdMainBuffer) &&
                      SafeCopyBuffer(m_handleMACD_H1, 1, 0, 1, macdSignalBuffer);
    
    if (!macdUpdated) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update MACD H1");
        updateSuccessful = false;
    }
    else {
        // Store previous MACD histogram
        m_macdHistogramPrev = m_macdHistogram;
        
        // Update MACD values
        m_macdMain = macdMainBuffer[0];
        m_macdSignal = macdSignalBuffer[0];
        m_macdHistogram = m_macdMain - m_macdSignal;
    }
    
    // Update Stochastic H1 (if available)
    if (m_handleStochastic_H1 != INVALID_HANDLE) {
        double stochMainBuffer[], stochSignalBuffer[];
        ArraySetAsSeries(stochMainBuffer, true);
        ArraySetAsSeries(stochSignalBuffer, true);
        
        if (SafeCopyBuffer(m_handleStochastic_H1, 0, 0, 1, stochMainBuffer) &&
            SafeCopyBuffer(m_handleStochastic_H1, 1, 0, 1, stochSignalBuffer)) {
            m_stochMain = stochMainBuffer[0];
            m_stochSignal = stochSignalBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical
        }
    }
    
    //--- Update H4 Indicators ---
    
    // Update ADX H4
    if (!SafeCopyBuffer(m_handleADX_H4, 0, 0, 1, adxBuffer)) {
        if (m_logger) m_logger.LogError("UpdateIndicatorData: Failed to update ADX H4 - critical indicator");
        criticalError = true;
        updateSuccessful = false;
    }
    else {
        m_adxH4 = adxBuffer[0];
        
        // Update H4 DI+ and DI- values if available
        if (SafeCopyBuffer(m_handleADX_H4, 1, 0, 1, diPlusBuffer) &&
            SafeCopyBuffer(m_handleADX_H4, 2, 0, 1, diMinusBuffer)) {
            m_di_plus_h4 = diPlusBuffer[0];
            m_di_minus_h4 = diMinusBuffer[0];
        }
    }
    
    // Update ATR H4
    if (!SafeCopyBuffer(m_handleATR_H4, 0, 0, 1, atrBuffer)) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update ATR H4");
        updateSuccessful = false;
    }
    else {
        m_atrH4 = atrBuffer[0];
    }
    
    // Update RSI H4 (if available)
    if (m_handleRSI_H4 != INVALID_HANDLE) {
        if (SafeCopyBuffer(m_handleRSI_H4, 0, 0, 1, rsiBuffer)) {
            m_rsiH4 = rsiBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical
        }
    }
    
    // Update MACD H4 (if available)
    if (m_handleMACD_H4 != INVALID_HANDLE) {
        if (SafeCopyBuffer(m_handleMACD_H4, 0, 0, 1, macdMainBuffer) &&
            SafeCopyBuffer(m_handleMACD_H4, 1, 0, 1, macdSignalBuffer)) {
            m_macdHistogram_H4 = macdMainBuffer[0] - macdSignalBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical
        }
    }
    
    //--- Update D1 Indicators ---
    
    // Update ATR D1 (if available)
    if (m_handleATR_D1 != INVALID_HANDLE) {
        if (SafeCopyBuffer(m_handleATR_D1, 0, 0, 1, atrBuffer)) {
            m_atrD1 = atrBuffer[0];
        }
        else {
            updateSuccessful = false;
            // Not critical
        }
    }
    
    //--- Update Volume Data ---
    
    // Get volume data
    long volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    
    if (!SafeCopyVolume(m_symbol, PERIOD_H1, 0, 21, volumeBuffer)) {
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update Volume data");
        updateSuccessful = false;
    }
    else {
        // Update current volume
        m_volumeCurrent = (double)volumeBuffer[0];
        
        // Calculate volume SMA20
        double sumVolume = 0;
        for (int i = 1; i <= 20; i++) {
            sumVolume += (double)volumeBuffer[i];
        }
        m_volumeSMA20 = sumVolume / 20.0;
        
        // Check for volume spike
        m_hasVolumeSpike = DetectVolumeSpike();
    }
    
    //--- Update ATR Ratio ---
    
    if (m_atrH1 > 0) {
        // Get ATR history for 20 bars
        double atrHistoryBuffer[];
        ArraySetAsSeries(atrHistoryBuffer, true);
        
        if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 21, atrHistoryBuffer)) {
            if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Failed to update ATR history");
            updateSuccessful = false;
        }
        else {
            // Calculate ATR average for 20 bars
            double sumATR = 0;
            for (int i = 1; i <= 20; i++) {
                sumATR += atrHistoryBuffer[i];
            }
            double avgATR = sumATR / 20.0;
            
            // Calculate ATR ratio
            if (avgATR > 0) {
                m_atrRatio = m_atrH1 / avgATR;
            }
            
            // Calculate ATR slope
            m_atrSlope = CalculateATRSlope();
        }
    }
    
    //--- Update EMA Statistics ---
    
    // Calculate EMA slope statistics
    CalculateEMASlopeStatistics();
    
    //--- Update Dynamic Thresholds ---
    
    // Update dynamic thresholds based on market conditions
    UpdateDynamicThresholds();
    
    //--- Update Swing Points ---
    
    // Update swing high/low points
    UpdateSwingPoints();
    
    //--- Update Key Levels ---
    
    // Update key support/resistance levels
    FindKeyLevels();
    
    //--- Update Extended Indicators ---
    
    // Update multi-timeframe indicators
    UpdateMTFIndicators();
    
    // Update volume profile
    datetime currentTime = TimeCurrent();
    if (m_lastVolumeProfileTime == 0 || (currentTime - m_lastVolumeProfileTime) > 300) {
        // Update volume profile every 5 minutes (300 seconds)
        UpdateVolumeProfile();
        m_lastVolumeProfileTime = currentTime;
    }
    
    // Update market patterns
    UpdateMarketPatterns();
    
    // Update liquidity levels
    UpdateLiquidityLevels();
    
    // Update order blocks
    DetectOrderBlocks();
    
    // Update fair value gaps
    DetectFairValueGaps();
    
    // Update market efficiency ratio
    m_marketEfficiencyRatio = CalculateMarketEfficiencyRatio();
    
    // Update cumulative delta
    m_cumulativeDelta = CalculateCumulativeDelta();
    
    // Update trading quality scores
    UpdateTradingQualityScores();
    
    //--- Handle update result ---
    
    if (criticalError) {
        // Increment failed updates counter
        m_failedUpdatesCount++;
        
        if (m_logger) m_logger.LogError(StringFormat(
            "UpdateIndicatorData: Critical error on update %d/%d", 
            m_failedUpdatesCount, m_maxConsecutiveFailedUpdates
        ));
        
        // Mark data as unreliable after exceeding max failed updates
        if (m_failedUpdatesCount >= m_maxConsecutiveFailedUpdates) {
            m_isDataReliable = false;
            if (m_logger) m_logger.LogError("UpdateIndicatorData: Data marked as unreliable");
        }
        
        return false;
    }
    else if (!updateSuccessful) {
        // Non-critical errors occurred
        if (m_logger) m_logger.LogWarning("UpdateIndicatorData: Non-critical errors occurred during update");
    }
    else {
        // Reset failed updates counter on success
        if (m_failedUpdatesCount > 0) {
            if (m_logger) m_logger.LogInfo(StringFormat(
                "UpdateIndicatorData: Successful update after %d failures", 
                m_failedUpdatesCount
            ));
        }
        m_failedUpdatesCount = 0;
        m_isDataReliable = true;
    }
    
    //--- Analyze Market Conditions ---
    
    // Update current session
    m_currentSession = DetermineCurrentSession();
    
    // Analyze market conditions
    AnalyzeMarketConditions();
    
    // Analyze market regime with soft transition
    AnalyzeMarketRegimeSoft();
    
    // Analyze session characteristics
    AnalyzeSessionCharacteristics();
    
    // Determine market phase
    m_marketPhase = DetermineMarketPhase();
    
    // MTF confluence analysis
    AnalyzeMTFConfluence();
    
    // Analyze market efficiency
    AnalyzeMarketEfficiency();
    
    // Analyze institutional activity
    AnalyzeInstitutionalActivity();
    
    // Update last update time
    m_lastUpdateTime = TimeCurrent();
    m_lastFullUpdateTime = m_lastUpdateTime;
    
    return true;
}

//+------------------------------------------------------------------+
//| Update multi-timeframe indicators                                |
//+------------------------------------------------------------------+
bool CMarketProfile::UpdateMTFIndicators()
{
    // Calculate multi-timeframe trend score
    m_mtfTrendScore = CalculateMTFTrendScore();
    
    // Calculate multi-timeframe volatility score
    m_mtfVolatilityScore = CalculateMTFVolatilityScore();
    
    // Calculate multi-timeframe momentum score
    m_mtfMomentumScore = CalculateMTFMomentumScore();
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate multi-timeframe trend score                            |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateMTFTrendScore()
{
    double score = 0.0;
    
    // M15 Timeframe Contribution
    double m15Score = 0.0;
    if (m_adxM15 > 25) {
        // Strong trend on M15
        m15Score = (m_di_plus_m15 > m_di_minus_m15) ? 1.0 : -1.0;
    }
    else if (m_adxM15 > 20) {
        // Moderate trend on M15
        m15Score = (m_di_plus_m15 > m_di_minus_m15) ? 0.5 : -0.5;
    }
    else {
        // Weak or no trend on M15
        m15Score = 0.0;
    }
    
    // H1 Timeframe Contribution
    double h1Score = 0.0;
    if (m_adxH1 > 25) {
        // Strong trend on H1
        h1Score = (m_di_plus_h1 > m_di_minus_h1) ? 1.0 : -1.0;
    }
    else if (m_adxH1 > 20) {
        // Moderate trend on H1
        h1Score = (m_di_plus_h1 > m_di_minus_h1) ? 0.5 : -0.5;
    }
    else {
        // Weak or no trend on H1
        h1Score = 0.0;
    }
    
    // H4 Timeframe Contribution
    double h4Score = 0.0;
    if (m_adxH4 > 25) {
        // Strong trend on H4
        h4Score = (m_di_plus_h4 > m_di_minus_h4) ? 1.0 : -1.0;
    }
    else if (m_adxH4 > 20) {
        // Moderate trend on H4
        h4Score = (m_di_plus_h4 > m_di_minus_h4) ? 0.5 : -0.5;
    }
    else {
        // Weak or no trend on H4
        h4Score = 0.0;
    }
    
    // D1 Timeframe Contribution
    // For D1, use the EMA alignment as trend indicator
    double d1Score = 0.0;
    
    // Check if EMA21 and EMA50 handles are available
    if (m_handleEMA21_D1 != INVALID_HANDLE && m_handleEMA50_D1 != INVALID_HANDLE) {
        double ema21Buffer[], ema50Buffer[];
        ArraySetAsSeries(ema21Buffer, true);
        ArraySetAsSeries(ema50Buffer, true);
        
        if (SafeCopyBuffer(m_handleEMA21_D1, 0, 0, 1, ema21Buffer) &&
            SafeCopyBuffer(m_handleEMA50_D1, 0, 0, 1, ema50Buffer)) {
            
            if (ema21Buffer[0] > ema50Buffer[0]) {
                // Potential uptrend on D1
                d1Score = 1.0;
            }
            else if (ema21Buffer[0] < ema50Buffer[0]) {
                // Potential downtrend on D1
                d1Score = -1.0;
            }
        }
    }
    
    // Calculate weighted score using MTF weights
    score = m15Score * m_mtfWeights.m15Weight + 
            h1Score * m_mtfWeights.h1Weight + 
            h4Score * m_mtfWeights.h4Weight + 
            d1Score * m_mtfWeights.d1Weight;
    
    // Ensure score is within [-1, 1] range
    score = MathMax(MathMin(score, 1.0), -1.0);
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate multi-timeframe volatility score                       |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateMTFVolatilityScore()
{
    double score = 0.5; // Default neutral volatility
    
    // M15 Timeframe Contribution
    double m15Score = 0.5;
    if (m_handleATR_M15 != INVALID_HANDLE) {
        double atrM15Ratio = 0.0;
        
        // Calculate ATR ratio for M15
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if (SafeCopyBuffer(m_handleATR_M15, 0, 0, 21, atrBuffer)) {
            double currentATR = atrBuffer[0];
            
            // Calculate average ATR for last 20 bars
            double sumATR = 0.0;
            for (int i = 1; i <= 20; i++) {
                sumATR += atrBuffer[i];
            }
            double avgATR = sumATR / 20.0;
            
            // Calculate ATR ratio
            if (avgATR > 0) {
                atrM15Ratio = currentATR / avgATR;
                
                // Convert ratio to score
                if (atrM15Ratio > 1.5) {
                    m15Score = 1.0; // High volatility
                }
                else if (atrM15Ratio > 1.2) {
                    m15Score = 0.75; // Above average volatility
                }
                else if (atrM15Ratio < 0.8) {
                    m15Score = 0.25; // Below average volatility
                }
                else if (atrM15Ratio < 0.5) {
                    m15Score = 0.0; // Very low volatility
                }
                else {
                    m15Score = 0.5; // Average volatility
                }
            }
        }
    }
    
    // H1 Timeframe Contribution
    double h1Score = m_atrRatio > 1.5 ? 1.0 : 
                    (m_atrRatio > 1.2 ? 0.75 : 
                    (m_atrRatio < 0.8 ? 0.25 : 
                    (m_atrRatio < 0.5 ? 0.0 : 0.5)));
    
    // H4 Timeframe Contribution
    double h4Score = 0.5;
    if (m_handleATR_H4 != INVALID_HANDLE) {
        double atrH4Ratio = 0.0;
        
        // Calculate ATR ratio for H4
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if (SafeCopyBuffer(m_handleATR_H4, 0, 0, 21, atrBuffer)) {
            double currentATR = atrBuffer[0];
            
            // Calculate average ATR for last 20 bars
            double sumATR = 0.0;
            for (int i = 1; i <= 20; i++) {
                sumATR += atrBuffer[i];
            }
            double avgATR = sumATR / 20.0;
            
            // Calculate ATR ratio
            if (avgATR > 0) {
                atrH4Ratio = currentATR / avgATR;
                
                // Convert ratio to score
                if (atrH4Ratio > 1.5) {
                    h4Score = 1.0; // High volatility
                }
                else if (atrH4Ratio > 1.2) {
                    h4Score = 0.75; // Above average volatility
                }
                else if (atrH4Ratio < 0.8) {
                    h4Score = 0.25; // Below average volatility
                }
                else if (atrH4Ratio < 0.5) {
                    h4Score = 0.0; // Very low volatility
                }
                else {
                    h4Score = 0.5; // Average volatility
                }
            }
        }
    }
    
    // D1 Timeframe Contribution
    double d1Score = 0.5;
    if (m_handleATR_D1 != INVALID_HANDLE) {
        double atrD1Ratio = 0.0;
        
        // Calculate ATR ratio for D1
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if (SafeCopyBuffer(m_handleATR_D1, 0, 0, 21, atrBuffer)) {
            double currentATR = atrBuffer[0];
            
            // Calculate average ATR for last 20 bars
            double sumATR = 0.0;
            for (int i = 1; i <= 20; i++) {
                sumATR += atrBuffer[i];
            }
            double avgATR = sumATR / 20.0;
            
            // Calculate ATR ratio
            if (avgATR > 0) {
                atrD1Ratio = currentATR / avgATR;
                
                // Convert ratio to score
                if (atrD1Ratio > 1.5) {
                    d1Score = 1.0; // High volatility
                }
                else if (atrD1Ratio > 1.2) {
                    d1Score = 0.75; // Above average volatility
                }
                else if (atrD1Ratio < 0.8) {
                    d1Score = 0.25; // Below average volatility
                }
                else if (atrD1Ratio < 0.5) {
                    d1Score = 0.0; // Very low volatility
                }
                else {
                    d1Score = 0.5; // Average volatility
                }
            }
        }
    }
    
    // Calculate weighted score using MTF weights
    score = m15Score * m_mtfWeights.m15Weight + 
            h1Score * m_mtfWeights.h1Weight + 
            h4Score * m_mtfWeights.h4Weight + 
            d1Score * m_mtfWeights.d1Weight;
    
    // Ensure score is within [0, 1] range
    score = MathMax(MathMin(score, 1.0), 0.0);
    
    return score;
}

//+------------------------------------------------------------------+
//| Calculate multi-timeframe momentum score                         |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateMTFMomentumScore()
{
    double score = 0.0;
    
    // M15 Timeframe Momentum Contribution
    double m15Score = 0.0;
    if (m_handleRSI_M15 != INVALID_HANDLE && m_handleMACD_M15 != INVALID_HANDLE) {
        // RSI component
        double rsiComponent = (m_rsiM15 - 50.0) / 50.0; // Scale to [-1, 1]
        
        // MACD component
        double macdComponent = m_macdHistogram_M15 > 0 ? 1.0 : -1.0;
        
        // Combined score
        m15Score = (rsiComponent + macdComponent) / 2.0;
    }
    
    // H1 Timeframe Momentum Contribution
    double h1Score = 0.0;
    // RSI component
    double rsiComponent = (m_rsiH1 - 50.0) / 50.0; // Scale to [-1, 1]
    
    // MACD component
    double macdComponent = m_macdHistogram > 0 ? 1.0 : -1.0;
    
    // Combined score
    h1Score = (rsiComponent + macdComponent) / 2.0;
    
    // H4 Timeframe Momentum Contribution
    double h4Score = 0.0;
    if (m_handleRSI_H4 != INVALID_HANDLE && m_handleMACD_H4 != INVALID_HANDLE) {
        // RSI component
        double rsiH4Component = (m_rsiH4 - 50.0) / 50.0; // Scale to [-1, 1]
        
        // MACD component
        double macdH4Component = m_macdHistogram_H4 > 0 ? 1.0 : -1.0;
        
        // Combined score
        h4Score = (rsiH4Component + macdH4Component) / 2.0;
    }
    
    // D1 Timeframe Momentum Contribution
    // For D1, use the EMA alignment as momentum indicator
    double d1Score = 0.0;
    if (m_handleEMA21_D1 != INVALID_HANDLE && m_handleEMA50_D1 != INVALID_HANDLE) {
        double ema21Buffer[], ema50Buffer[];
        ArraySetAsSeries(ema21Buffer, true);
        ArraySetAsSeries(ema50Buffer, true);
        
        if (SafeCopyBuffer(m_handleEMA21_D1, 0, 0, 1, ema21Buffer) &&
            SafeCopyBuffer(m_handleEMA50_D1, 0, 0, 1, ema50Buffer)) {
            
            // Calculate distance between EMAs normalized by D1 ATR
            double ema21_50_dist = 0.0;
            if (m_atrD1 > 0) {
                ema21_50_dist = (ema21Buffer[0] - ema50Buffer[0]) / m_atrD1;
            }
            
            // Score based on normalized distance
            if (MathAbs(ema21_50_dist) < 0.5) {
                // EMAs close together - neutral momentum
                d1Score = 0.0;
            }
            else {
                // Score between -1 and 1 based on direction and magnitude
                d1Score = MathMax(MathMin(ema21_50_dist, 1.0), -1.0);
            }
        }
    }
    
    // Calculate weighted score using MTF weights
    score = m15Score * m_mtfWeights.m15Weight + 
            h1Score * m_mtfWeights.h1Weight + 
            h4Score * m_mtfWeights.h4Weight + 
            d1Score * m_mtfWeights.d1Weight;
    
    // Ensure score is within [-1, 1] range
    score = MathMax(MathMin(score, 1.0), -1.0);
    
    return score;
}

//+------------------------------------------------------------------+
//| Update volume profile                                            |
//+------------------------------------------------------------------+
bool CMarketProfile::UpdateVolumeProfile()
{
    // Get price and volume data
    int barsToAnalyze = 50; // Analyze recent bars for volume profile
    
    double high[], low[], close[];
    long volume[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(volume, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, barsToAnalyze, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, barsToAnalyze, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, barsToAnalyze, close) <= 0 ||
        CopyTickVolume(m_symbol, PERIOD_H1, 0, barsToAnalyze, volume) <= 0) {
        
        if (m_logger) m_logger.LogWarning("UpdateVolumeProfile: Failed to copy price/volume data");
        return false;
    }
    
    // Determine price range
    double highestPrice = high[ArrayMaximum(high, 0, barsToAnalyze)];
    double lowestPrice = low[ArrayMinimum(low, 0, barsToAnalyze)];
    
    // Initialize volume profile array
    m_volumeProfileSize = 0;
    double priceStep = (highestPrice - lowestPrice) / 99.0; // Divide into 100 levels
    
    // Skip profile calculation if price range is too small
    if (priceStep <= 0 || priceStep < SymbolInfoDouble(m_symbol, SYMBOL_POINT) * 10) {
        if (m_logger) m_logger.LogWarning("UpdateVolumeProfile: Price range too small for meaningful profile");
        return false;
    }
    
    // Initialize profile nodes
    for (int i = 0; i < 100; i++) {
        m_volumeProfile[i].price = lowestPrice + i * priceStep;
        m_volumeProfile[i].volume = 0;
        m_volumeProfile[i].isPOC = false;
        m_volumeProfile[i].isVAH = false;
        m_volumeProfile[i].isVAL = false;
    }
    m_volumeProfileSize = 100;
    
    // Populate volume profile
    for (int bar = 0; bar < barsToAnalyze; bar++) {
        // Distribute volume across price range for this bar
        double barVolume = (double)volume[bar];
        
        // Skip bars with zero volume
        if (barVolume <= 0) continue;
        
        // Simple volume distribution - spread volume evenly across bar range
        int lowIndex = (int)((low[bar] - lowestPrice) / priceStep);
        int highIndex = (int)((high[bar] - lowestPrice) / priceStep);
        
        // Ensure indices are within bounds
        lowIndex = MathMax(0, MathMin(lowIndex, 99));
        highIndex = MathMax(0, MathMin(highIndex, 99));
        
        int pointsInBar = highIndex - lowIndex + 1;
        if (pointsInBar <= 0) pointsInBar = 1;
        
        double volumePerPoint = barVolume / pointsInBar;
        
        // Distribute volume across price points
        for (int i = lowIndex; i <= highIndex; i++) {
            m_volumeProfile[i].volume += volumePerPoint;
        }
    }
    
    // Find Point of Control (POC) - price level with highest volume
    double maxVolume = 0;
    int pocIndex = 0;
    for (int i = 0; i < m_volumeProfileSize; i++) {
        if (m_volumeProfile[i].volume > maxVolume) {
            maxVolume = m_volumeProfile[i].volume;
            pocIndex = i;
        }
    }
    
    // Set POC
    if (maxVolume > 0) {
        m_volumeProfile[pocIndex].isPOC = true;
        m_pointOfControl = m_volumeProfile[pocIndex].price;
    }
    
    // Calculate Value Area (70% of volume)
    double totalVolume = 0;
    for (int i = 0; i < m_volumeProfileSize; i++) {
        totalVolume += m_volumeProfile[i].volume;
    }
    
    double valueAreaVolume = totalVolume * 0.7; // 70% of total volume
    double currentVolume = m_volumeProfile[pocIndex].volume;
    
    // Start from POC and expand both ways until 70% of volume is covered
    int upperIndex = pocIndex;
    int lowerIndex = pocIndex;
    
    while (currentVolume < valueAreaVolume && 
           (upperIndex + 1 < m_volumeProfileSize || lowerIndex - 1 >= 0)) {
        
        // Check which side has more volume
        double upperVolume = (upperIndex + 1 < m_volumeProfileSize) ? 
                           m_volumeProfile[upperIndex + 1].volume : 0;
        
        double lowerVolume = (lowerIndex - 1 >= 0) ? 
                           m_volumeProfile[lowerIndex - 1].volume : 0;
        
        // Choose the side with more volume
        if (upperVolume >= lowerVolume) {
            if (upperIndex + 1 < m_volumeProfileSize) {
                upperIndex++;
                currentVolume += m_volumeProfile[upperIndex].volume;
            }
        }
        else {
            if (lowerIndex - 1 >= 0) {
                lowerIndex--;
                currentVolume += m_volumeProfile[lowerIndex].volume;
            }
        }
    }
    
    // Set Value Area High (VAH) and Value Area Low (VAL)
    if (upperIndex >= 0 && upperIndex < m_volumeProfileSize) {
        m_volumeProfile[upperIndex].isVAH = true;
        m_valueAreaHigh = m_volumeProfile[upperIndex].price;
    }
    
    if (lowerIndex >= 0 && lowerIndex < m_volumeProfileSize) {
        m_volumeProfile[lowerIndex].isVAL = true;
        m_valueAreaLow = m_volumeProfile[lowerIndex].price;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Update key levels                                                |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateKeyLevels()
{
    // Check if cache is still valid (within 5 minutes)
    datetime currentTime = TimeCurrent();
    if (m_keyLevelCacheTime > 0 && 
        (currentTime - m_keyLevelCacheTime) < 300 &&
        m_keyResistanceLevel > 0 && 
        m_keySupportLevel > 0) {
        // Use cached values
        return;
    }
    
    // Continue with key levels calculation
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return;
    }
    
    double currentPrice = close[0];
    
    // Reset key levels
    m_keyResistanceLevel = 0;
    m_keySupportLevel = 0;
    
    //--- Find Key Levels - Main Algorithm ---
    
    // 1. EMA-Based Levels
    double ema89Buffer[], ema200Buffer[];
    ArraySetAsSeries(ema89Buffer, true);
    ArraySetAsSeries(ema200Buffer, true);
    
    if (SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89Buffer) &&
        SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200Buffer)) {
        
        // Check if price is between EMAs
        if (currentPrice < ema89Buffer[0] && ema89Buffer[0] < ema200Buffer[0]) {
            // Bullish EMA alignment, EMA89 is resistance
            m_keyResistanceLevel = ema89Buffer[0];
        }
        else if (currentPrice > ema89Buffer[0] && ema89Buffer[0] > ema200Buffer[0]) {
            // Bullish EMA alignment, EMA89 is support
            m_keySupportLevel = ema89Buffer[0];
        }
        else if (currentPrice > ema89Buffer[0] && ema89Buffer[0] < ema200Buffer[0]) {
            // Bearish EMA alignment, EMA89 is support
            m_keySupportLevel = ema89Buffer[0];
        }
        else if (currentPrice < ema89Buffer[0] && ema89Buffer[0] > ema200Buffer[0]) {
            // Bearish EMA alignment, EMA89 is resistance
            m_keyResistanceLevel = ema89Buffer[0];
        }
    }
    
    // 2. Swing High/Low Based Levels
    if (m_recentSwingHigh > 0 && m_recentSwingLow > 0) {
        // Use swing points if price is near them
        double swingHighDistance = MathAbs(currentPrice - m_recentSwingHigh) / m_atrH1;
        double swingLowDistance = MathAbs(currentPrice - m_recentSwingLow) / m_atrH1;
        
        if (swingHighDistance < 3.0 && (m_keyResistanceLevel == 0 || m_recentSwingHigh < m_keyResistanceLevel)) {
            m_keyResistanceLevel = m_recentSwingHigh;
        }
        
        if (swingLowDistance < 3.0 && (m_keySupportLevel == 0 || m_recentSwingLow > m_keySupportLevel)) {
            m_keySupportLevel = m_recentSwingLow;
        }
    }
    
    // 3. Volume Profile Based Levels
    if (m_valueAreaHigh > 0 && m_valueAreaLow > 0) {
        // If current price is between VAH and VAL
        if (currentPrice < m_valueAreaHigh && currentPrice > m_valueAreaLow) {
            // VAH as resistance, VAL as support
            if (m_keyResistanceLevel == 0 || m_valueAreaHigh < m_keyResistanceLevel) {
                m_keyResistanceLevel = m_valueAreaHigh;
            }
            
            if (m_keySupportLevel == 0 || m_valueAreaLow > m_keySupportLevel) {
                m_keySupportLevel = m_valueAreaLow;
            }
        }
        // If current price is above VAH
        else if (currentPrice > m_valueAreaHigh) {
            // POC or VAH as support
            if (m_keySupportLevel == 0 || m_valueAreaHigh > m_keySupportLevel) {
                m_keySupportLevel = m_valueAreaHigh;
            }
        }
        // If current price is below VAL
        else if (currentPrice < m_valueAreaLow) {
            // POC or VAL as resistance
            if (m_keyResistanceLevel == 0 || m_valueAreaLow < m_keyResistanceLevel) {
                m_keyResistanceLevel = m_valueAreaLow;
            }
        }
    }
    
    // 4. Round Numbers (Psychological Levels)
    int digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    double pointSize = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    
    // Calculate multiplier based on digits
    double roundMultiplier = 1.0;
    if (digits == 2 || digits == 3) {
        // Stocks, indices - round to 1.0
        roundMultiplier = 1.0;
    }
    else if (digits == 4 || digits == 5) {
        // Forex - round to 0.01 or 0.001
        roundMultiplier = 0.01;
    }
    
    // Find nearest round number above and below
    double roundAbove = MathCeil(currentPrice / roundMultiplier) * roundMultiplier;
    double roundBelow = MathFloor(currentPrice / roundMultiplier) * roundMultiplier;
    
    // If round numbers are within 1 ATR, consider them as key levels
    if (MathAbs(roundAbove - currentPrice) < m_atrH1) {
        if (m_keyResistanceLevel == 0 || roundAbove < m_keyResistanceLevel) {
            m_keyResistanceLevel = roundAbove;
        }
    }
    
    if (MathAbs(roundBelow - currentPrice) < m_atrH1) {
        if (m_keySupportLevel == 0 || roundBelow > m_keySupportLevel) {
            m_keySupportLevel = roundBelow;
        }
    }
    
    // Ensure we have at least some key levels
    if (m_keyResistanceLevel == 0) {
        m_keyResistanceLevel = currentPrice + 2.0 * m_atrH1;
    }
    
    if (m_keySupportLevel == 0) {
        m_keySupportLevel = currentPrice - 2.0 * m_atrH1;
    }
    
    // Update cache timestamp
    m_keyLevelCacheTime = currentTime;
}

//+------------------------------------------------------------------+
//| Update liquidity levels                                          |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateLiquidityLevels()
{
    // Reset buy/sell liquidity counts
    m_buyLiquidityCount = 0;
    m_sellLiquidityCount = 0;
    
    // Analyze recent price action for liquidity levels
    double high[], low[], open[], close[];
    long volume[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(volume, true);
    
    int bars = 200; // Look back for liquidity analysis
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, bars, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, bars, low) <= 0 ||
        CopyOpen(m_symbol, PERIOD_H1, 0, bars, open) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, bars, close) <= 0 ||
        CopyTickVolume(m_symbol, PERIOD_H1, 0, bars, volume) <= 0) {
        
        if (m_logger) m_logger.LogWarning("UpdateLiquidityLevels: Failed to copy price data");
        return;
    }
    
    // Find swing high/low points with significant volume
    for (int i = 10; i < bars - 10; i++) {
        // Check for potential swing high
        if (high[i] > high[i+1] && high[i] > high[i+2] && 
            high[i] > high[i-1] && high[i] > high[i-2]) {
            
            // Check if this is a high volume node
            bool isHighVolume = volume[i] > volume[i+1] && 
                               volume[i] > volume[i+2] && 
                               volume[i] > volume[i-1] && 
                               volume[i] > volume[i-2];
            
            // Check if price moved away from this level
            bool movedAway = false;
            double maxMove = 0;
            for (int j = i-1; j >= MathMax(0, i-10); j--) {
                double move = (high[i] - low[j]) / m_atrH1;
                if (move > maxMove) maxMove = move;
                
                if (move > 1.0) {
                    movedAway = true;
                    break;
                }
            }
            
            // If high volume and price moved away, consider as sell liquidity
            if (isHighVolume && movedAway && maxMove > 1.5) {
                // Check if not too close to existing level
                bool tooClose = false;
                for (int j = 0; j < m_sellLiquidityCount; j++) {
                    if (MathAbs(m_sellLiquidityLevels[j].price - high[i]) < m_atrH1 * 0.3) {
                        tooClose = true;
                        
                        // If this has more volume, replace the existing level
                        if (volume[i] > volume[(int)m_sellLiquidityLevels[j].time]) {
                            m_sellLiquidityLevels[j].price = high[i];
                            m_sellLiquidityLevels[j].time = i;
                            m_sellLiquidityLevels[j].strength = MathMin(1.0, maxMove / 3.0);
                        }
                        break;
                    }
                }
                
                // Add new sell liquidity level if not too close to existing one
                if (!tooClose && m_sellLiquidityCount < 10) {
                    m_sellLiquidityLevels[m_sellLiquidityCount].price = high[i];
                    m_sellLiquidityLevels[m_sellLiquidityCount].time = i;
                    m_sellLiquidityLevels[m_sellLiquidityCount].type = LIQUIDITY_SELL;
                    m_sellLiquidityLevels[m_sellLiquidityCount].strength = MathMin(1.0, maxMove / 3.0);
                    m_sellLiquidityCount++;
                }
            }
        }
        
        // Check for potential swing low
        if (low[i] < low[i+1] && low[i] < low[i+2] && 
            low[i] < low[i-1] && low[i] < low[i-2]) {
            
            // Check if this is a high volume node
            bool isHighVolume = volume[i] > volume[i+1] && 
                               volume[i] > volume[i+2] && 
                               volume[i] > volume[i-1] && 
                               volume[i] > volume[i-2];
            
            // Check if price moved away from this level
            bool movedAway = false;
            double maxMove = 0;
            for (int j = i-1; j >= MathMax(0, i-10); j--) {
                double move = (high[j] - low[i]) / m_atrH1;
                if (move > maxMove) maxMove = move;
                
                if (move > 1.0) {
                    movedAway = true;
                    break;
                }
            }
            
            // If high volume and price moved away, consider as buy liquidity
            if (isHighVolume && movedAway && maxMove > 1.5) {
                // Check if not too close to existing level
                bool tooClose = false;
                for (int j = 0; j < m_buyLiquidityCount; j++) {
                    if (MathAbs(m_buyLiquidityLevels[j].price - low[i]) < m_atrH1 * 0.3) {
                        tooClose = true;
                        
                        // If this has more volume, replace the existing level
                        if (volume[i] > volume[(int)m_buyLiquidityLevels[j].time]) {
                            m_buyLiquidityLevels[j].price = low[i];
                            m_buyLiquidityLevels[j].time = i;
                            m_buyLiquidityLevels[j].strength = MathMin(1.0, maxMove / 3.0);
                        }
                        break;
                    }
                }
                
                // Add new buy liquidity level if not too close to existing one
                if (!tooClose && m_buyLiquidityCount < 10) {
                    m_buyLiquidityLevels[m_buyLiquidityCount].price = low[i];
                    m_buyLiquidityLevels[m_buyLiquidityCount].time = i;
                    m_buyLiquidityLevels[m_buyLiquidityCount].type = LIQUIDITY_BUY;
                    m_buyLiquidityLevels[m_buyLiquidityCount].strength = MathMin(1.0, maxMove / 3.0);
                    m_buyLiquidityCount++;
                }
            }
        }
    }
    
    // Check if any liquidity has been swept recently
    double currentHigh[], currentLow[];
    ArraySetAsSeries(currentHigh, true);
    ArraySetAsSeries(currentLow, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 5, currentHigh) > 0 &&
        CopyLow(m_symbol, PERIOD_H1, 0, 5, currentLow) > 0) {
        
        // Check sell liquidity levels
        for (int i = 0; i < m_sellLiquidityCount; i++) {
            // Check if price has swept this level recently
            for (int j = 0; j < 5; j++) {
                if (currentHigh[j] > m_sellLiquidityLevels[i].price) {
                    m_sellLiquidityLevels[i].isSwept = true;
                    m_sellLiquidityLevels[i].sweepCount++;
                    break;
                }
            }
        }
        
        // Check buy liquidity levels
        for (int i = 0; i < m_buyLiquidityCount; i++) {
            // Check if price has swept this level recently
            for (int j = 0; j < 5; j++) {
                if (currentLow[j] < m_buyLiquidityLevels[i].price) {
                    m_buyLiquidityLevels[i].isSwept = true;
                    m_buyLiquidityLevels[i].sweepCount++;
                    break;
                }
            }
        }
    }
    
    // Calculate liquidity above and below
    m_liquidityAbove = 0;
    m_liquidityBelow = 0;
    
    double currentPrice = close[0];
    
    for (int i = 0; i < m_sellLiquidityCount; i++) {
        if (m_sellLiquidityLevels[i].price > currentPrice && !m_sellLiquidityLevels[i].isSwept) {
            m_liquidityAbove += m_sellLiquidityLevels[i].strength;
        }
    }
    
    for (int i = 0; i < m_buyLiquidityCount; i++) {
        if (m_buyLiquidityLevels[i].price < currentPrice && !m_buyLiquidityLevels[i].isSwept) {
            m_liquidityBelow += m_buyLiquidityLevels[i].strength;
        }
    }
}

//+------------------------------------------------------------------+
//| Update market patterns                                           |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateMarketPatterns()
{
    // Reset pattern flags
    m_hasEngulfing = false;
    m_hasDoji = false;
    m_hasPinbar = false;
    m_hasInsideBar = false;
    m_hasThreeLineStrike = false;
    m_hasBullishDivergence = false;
    m_hasBearishDivergence = false;
    
    // Get recent price data
    double open[], high[], low[], close[];
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 10, open) <= 0 ||
        CopyHigh(m_symbol, PERIOD_H1, 0, 10, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 10, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 10, close) <= 0) {
        
        if (m_logger) m_logger.LogWarning("UpdateMarketPatterns: Failed to copy price data");
        return;
    }
    
    // Check for engulfing pattern
    m_hasEngulfing = DetectEngulfingPattern();
    
    // Check for doji
    double bodySize = MathAbs(close[1] - open[1]);
    double fullRange = high[1] - low[1];
    
    if (fullRange > 0 && bodySize / fullRange < 0.2) {
        m_hasDoji = true;
    }
    
    // Check for pinbar
    double upperWick = high[1] - MathMax(open[1], close[1]);
    double lowerWick = MathMin(open[1], close[1]) - low[1];
    double body = MathAbs(open[1] - close[1]);
    
    // Bullish pinbar
    if (lowerWick > 2 * body && lowerWick > upperWick * 2 && body > 0) {
        m_hasPinbar = true;
    }
    // Bearish pinbar
    else if (upperWick > 2 * body && upperWick > lowerWick * 2 && body > 0) {
        m_hasPinbar = true;
    }
    
    // Check for inside bar
    if (high[1] < high[2] && low[1] > low[2]) {
        m_hasInsideBar = true;
    }
    
    // Check for three line strike
    // Bullish three line strike
    if (close[4] < open[4] && close[3] < open[3] && close[2] < open[2] &&  // Three bearish candles
        close[1] > open[1] && close[1] > open[4] && open[1] < close[2]) {  // Strong bullish candle
        m_hasThreeLineStrike = true;
    }
    // Bearish three line strike
    else if (close[4] > open[4] && close[3] > open[3] && close[2] > open[2] &&  // Three bullish candles
             close[1] < open[1] && close[1] < open[4] && open[1] > close[2]) {  // Strong bearish candle
        m_hasThreeLineStrike = true;
    }
    
    // Check for divergences
    m_hasBullishDivergence = DetectBullishDivergence();
    m_hasBearishDivergence = DetectBearishDivergence();
}

//+------------------------------------------------------------------+
//| Detect order blocks                                              |
//+------------------------------------------------------------------+
void CMarketProfile::DetectOrderBlocks()
{
    // Get recent price data
    double open[], high[], low[], close[];
    long volume[];
    
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(volume, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 50, open) <= 0 ||
        CopyHigh(m_symbol, PERIOD_H1, 0, 50, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 50, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 50, close) <= 0 ||
        CopyTickVolume(m_symbol, PERIOD_H1, 0, 50, volume) <= 0) {
        
        if (m_logger) m_logger.LogWarning("DetectOrderBlocks: Failed to copy price data");
        return;
    }
    
    // Get current price
    double currentPrice = close[0];
    
    // Look for bullish order blocks
    for (int i = 5; i < 40; i++) {
        // Check for strong bearish candle followed by strong bullish move
        if (close[i] < open[i] && volume[i] > volume[i+1]) {
            // Check if price moved up significantly after this candle
            bool strongMove = false;
            int moveLength = 0;
            
            for (int j = 1; j <= 5; j++) {
                if (i-j < 0) break;
                
                // Check for consecutive bullish candles or strong single move
                if (close[i-j] > open[i-j] || (j == 1 && close[i-j] > high[i])) {
                    moveLength++;
                    
                    // If price moved significantly above the bear candle
                    if (high[i-j] > high[i] + m_atrH1 * 0.5) {
                        strongMove = true;
                    }
                }
                else {
                    break; // Break on bearish candle
                }
            }
            
            // If strong bullish move found after bearish candle
            if (strongMove && moveLength >= 1) {
                // This candle might be a bullish order block
                m_lastBullishOBTime = i;
                m_bullishOBHigh = high[i];
                m_bullishOBLow = low[i];
                break;
            }
        }
    }
    
    // Look for bearish order blocks
    for (int i = 5; i < 40; i++) {
        // Check for strong bullish candle followed by strong bearish move
        if (close[i] > open[i] && volume[i] > volume[i+1]) {
            // Check if price moved down significantly after this candle
            bool strongMove = false;
            int moveLength = 0;
            
            for (int j = 1; j <= 5; j++) {
                if (i-j < 0) break;
                
                // Check for consecutive bearish candles or strong single move
                if (close[i-j] < open[i-j] || (j == 1 && close[i-j] < low[i])) {
                    moveLength++;
                    
                    // If price moved significantly below the bull candle
                    if (low[i-j] < low[i] - m_atrH1 * 0.5) {
                        strongMove = true;
                    }
                }
                else {
                    break; // Break on bullish candle
                }
            }
            
            // If strong bearish move found after bullish candle
            if (strongMove && moveLength >= 1) {
                // This candle might be a bearish order block
                m_lastBearishOBTime = i;
                m_bearishOBHigh = high[i];
                m_bearishOBLow = low[i];
                break;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Detect fair value gaps                                           |
//+------------------------------------------------------------------+
void CMarketProfile::DetectFairValueGaps()
{
    // Reset FVG count
    m_fvgCount = 0;
    
    // Get recent price data
    double high[], low[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 50, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 50, low) <= 0) {
        
        if (m_logger) m_logger.LogWarning("DetectFairValueGaps: Failed to copy price data");
        return;
    }
    
    // Detect bullish fair value gaps (low[i] > high[i+2])
    for (int i = 0; i < 47; i++) {
        if (low[i] > high[i+2]) {
            // Found a bullish FVG
            if (m_fvgCount < 5) {
                m_fairValueGap[m_fvgCount][0] = low[i]; // High of the gap
                m_fairValueGap[m_fvgCount][1] = high[i+2]; // Low of the gap
                m_fairValueGap[m_fvgCount][2] = i; // Age (bars ago)
                m_fvgCount++;
            }
        }
    }
    
    // Detect bearish fair value gaps (high[i] < low[i+2])
    for (int i = 0; i < 47; i++) {
        if (high[i] < low[i+2]) {
            // Found a bearish FVG
            if (m_fvgCount < 5) {
                m_fairValueGap[m_fvgCount][0] = low[i+2]; // High of the gap
                m_fairValueGap[m_fvgCount][1] = high[i]; // Low of the gap
                m_fairValueGap[m_fvgCount][2] = i; // Age (bars ago)
                m_fvgCount++;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Calculate market efficiency ratio                                |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateMarketEfficiencyRatio()
{
    // Get recent price data
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_H1, 0, 30, close) <= 0) {
        if (m_logger) m_logger.LogWarning("CalculateMarketEfficiencyRatio: Failed to copy price data");
        return 0.5; // Return neutral value on failure
    }
    
    // Calculate directional movement
    double dirMovement = MathAbs(close[0] - close[29]);
    
    // Calculate total movement (sum of bar-to-bar moves)
    double totalMovement = 0;
    for (int i = 0; i < 29; i++) {
        totalMovement += MathAbs(close[i] - close[i+1]);
    }
    
    // Calculate MER
    double mer = 0.5; // Default neutral value
    
    if (totalMovement > 0) {
        mer = dirMovement / totalMovement;
    }
    
    // MER close to 1.0 means efficient market (trending)
    // MER close to 0.0 means inefficient market (ranging)
    
    return mer;
}

//+------------------------------------------------------------------+
//| Calculate cumulative delta                                       |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateCumulativeDelta()
{
    // In MQL5, direct access to tick-by-tick buy/sell volume is limited
    // This is a simplified estimation based on price action
    
    double open[], high[], low[], close[];
    long volume[];
    
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(volume, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 20, open) <= 0 ||
        CopyHigh(m_symbol, PERIOD_H1, 0, 20, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 20, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 20, close) <= 0 ||
        CopyTickVolume(m_symbol, PERIOD_H1, 0, 20, volume) <= 0) {
        
        if (m_logger) m_logger.LogWarning("CalculateCumulativeDelta: Failed to copy price data");
        return 0.0;
    }
    
    // Calculate an approximation of delta based on candle position and volume
    double cumulativeDelta = 0;
    
    for (int i = 0; i < 20; i++) {
        double range = high[i] - low[i];
        if (range <= 0) continue;
        
        double bodySize = MathAbs(close[i] - open[i]);
        double bodyPosition = (close[i] - low[i]) / range; // 0 = bottom, 1 = top
        
        // Calculate rough delta estimation
        double barDelta;
        
        if (close[i] > open[i]) {
            // Bullish bar - estimate more buying
            barDelta = volume[i] * (0.5 + bodyPosition / 2.0) * (bodySize / range);
        }
        else {
            // Bearish bar - estimate more selling
            barDelta = -volume[i] * (1.0 - bodyPosition / 2.0) * (bodySize / range);
        }
        
        cumulativeDelta += barDelta;
    }
    
    return cumulativeDelta;
}

//+------------------------------------------------------------------+
//| Update trading quality scores                                    |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateTradingQualityScores()
{
    // Assess quality for different trading styles
    m_trendFollowingQuality = AssessTrendFollowingConditions();
    m_counterTrendQuality = AssessCounterTrendConditions();
    m_breakoutQuality = AssessBreakoutConditions();
    m_rangeQuality = AssessRangeTradingConditions();
}

//+------------------------------------------------------------------+
//| Assess trend-following conditions                                |
//+------------------------------------------------------------------+
double CMarketProfile::AssessTrendFollowingConditions()
{
    double score = 0.5; // Default neutral score
    
    // Assess ADX and trend alignment
    if (m_adxH4 > 25) {
        score += 0.2; // Strong trend on H4
        
        // Check trend direction alignment between timeframes
        bool h4Bullish = m_di_plus_h4 > m_di_minus_h4;
        bool h1Bullish = m_di_plus_h1 > m_di_minus_h1;
        
        if ((h4Bullish && h1Bullish) || (!h4Bullish && !h1Bullish)) {
            score += 0.1; // Aligned trends
        }
        else {
            score -= 0.1; // Misaligned trends
        }
    }
    else if (m_adxH4 > 20) {
        score += 0.1; // Moderate trend on H4
    }
    else {
        score -= 0.2; // Weak trend
    }
    
    // Assess EMA alignment
    if (m_emaAlignment > 0.7) {
        score += 0.2; // Strong EMA alignment
    }
    else if (m_emaAlignment > 0.3) {
        score += 0.1; // Moderate EMA alignment
    }
    
    // Assess MACD
    if ((m_macdHistogram > 0 && m_macdHistogram > m_macdHistogramPrev) ||
        (m_macdHistogram < 0 && m_macdHistogram < m_macdHistogramPrev)) {
        score += 0.1; // MACD momentum in trend direction
    }
    
    // Assess market efficiency
    if (m_marketEfficiencyRatio > 0.7) {
        score += 0.1; // Efficient market, good for trend following
    }
    else if (m_marketEfficiencyRatio < 0.3) {
        score -= 0.2; // Inefficient market, bad for trend following
    }
    
    // Assess volatility
    if (m_atrRatio > 1.5) {
        score -= 0.1; // Too volatile
    }
    else if (m_atrRatio < 0.7) {
        score -= 0.1; // Too quiet
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Assess counter-trend conditions                                  |
//+------------------------------------------------------------------+
double CMarketProfile::AssessCounterTrendConditions()
{
    double score = 0.5; // Default neutral score
    
    // Assess ADX and trend exhaustion
    if (m_adxH4 > 25 && m_adxSlope < -0.2) {
        score += 0.2; // Strong trend that might be exhausting
    }
    else if (m_adxH4 < 15) {
        score += 0.1; // Weak trend, potential for reversal
    }
    
    // Assess overbought/oversold conditions
    if (m_isOverbought || m_isOversold) {
        score += 0.2; // Market is overextended
    }
    
    // Assess divergences
    if (m_hasBullishDivergence || m_hasBearishDivergence) {
        score += 0.3; // Divergence present
    }
    
    // Assess volatility
    if (m_atrRatio > 1.5 && m_atrSlope < 0) {
        score += 0.1; // High volatility decreasing
    }
    
    // Assess market efficiency
    if (m_marketEfficiencyRatio < 0.3) {
        score += 0.1; // Inefficient market, potential for reversals
    }
    
    // Assess pattern presence
    if (m_hasEngulfing || m_hasPinbar || m_hasThreeLineStrike) {
        score += 0.1; // Reversal pattern present
    }
    
    // Assess market phase
    if (m_marketPhase == PHASE_EXHAUSTION || m_marketPhase == PHASE_DISTRIBUTION) {
        score += 0.2; // Market phase suitable for counter-trend
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Assess breakout conditions                                       |
//+------------------------------------------------------------------+
double CMarketProfile::AssessBreakoutConditions()
{
    double score = 0.5; // Default neutral score
    
    // Assess volatility expansion
    if (m_atrRatio > 1.5 && m_atrSlope > 0.2) {
        score += 0.2; // Expanding volatility
    }
    else if (m_atrRatio < 0.7 && m_atrSlope > 0.3) {
        score += 0.3; // Volatility expansion from low levels
    }
    
    // Assess price compression
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 10, high) > 0 &&
        CopyLow(m_symbol, PERIOD_H1, 0, 10, low) > 0) {
        
        // Calculate average range for the last 5 bars compared to previous 5
        double rangeRecent = 0, rangePrevious = 0;
        
        for (int i = 0; i < 5; i++) {
            rangeRecent += (high[i] - low[i]) / m_atrH1;
        }
        
        for (int i = 5; i < 10; i++) {
            rangePrevious += (high[i] - low[i]) / m_atrH1;
        }
        
        rangeRecent /= 5;
        rangePrevious /= 5;
        
        if (rangeRecent < rangePrevious * 0.7) {
            score += 0.2; // Price compression (narrowing range)
        }
    }
    
    // Assess volume
    if (m_volumeCurrent > m_volumeSMA20 * 1.5) {
        score += 0.1; // Higher volume
    }
    
    // Assess key level proximity
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_H1, 0, 1, close) > 0) {
        double distToResistance = MathAbs(close[0] - m_keyResistanceLevel) / m_atrH1;
        double distToSupport = MathAbs(close[0] - m_keySupportLevel) / m_atrH1;
        
        if (distToResistance < 0.5 || distToSupport < 0.5) {
            score += 0.2; // Close to key level
        }
    }
    
    // Assess market phase
    if (m_marketPhase == PHASE_ACCUMULATION) {
        score += 0.1; // Accumulation phase often leads to breakouts
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Assess range trading conditions                                  |
//+------------------------------------------------------------------+
double CMarketProfile::AssessRangeTradingConditions()
{
    double score = 0.5; // Default neutral score
    
    // Assess ADX
    if (m_adxH4 < 20) {
        score += 0.3; // Weak trend, good for range trading
    }
    else if (m_adxH4 > 25) {
        score -= 0.3; // Strong trend, bad for range trading
    }
    
    // Assess market efficiency
    if (m_marketEfficiencyRatio < 0.3) {
        score += 0.2; // Inefficient market, good for range trading
    }
    else if (m_marketEfficiencyRatio > 0.7) {
        score -= 0.2; // Efficient market, bad for range trading
    }
    
    // Assess volatility
    if (m_atrRatio < 0.8) {
        score += 0.1; // Low volatility
    }
    else if (m_atrRatio > 1.3) {
        score -= 0.2; // High volatility
    }
    
    // Assess clear support/resistance
    if (m_keyResistanceLevel > 0 && m_keySupportLevel > 0) {
        double rangeSize = (m_keyResistanceLevel - m_keySupportLevel) / m_atrH1;
        
        if (rangeSize > 1.0 && rangeSize < 5.0) {
            score += 0.2; // Well-defined range of reasonable size
        }
    }
    
    // Assess session
    if (m_currentSession == SESSION_ASIAN) {
        score += 0.1; // Asian session often has ranging conditions
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Detect bullish divergence                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectBullishDivergence()
{
    // For bullish divergence:
    // Price makes lower lows, but RSI makes higher lows
    
    // Get price data
    double low[], close[];
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyLow(m_symbol, PERIOD_H1, 0, 30, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 30, close) <= 0) {
        return false;
    }
    
    // Get RSI data
    double rsi[];
    ArraySetAsSeries(rsi, true);
    
    if (!SafeCopyBuffer(m_handleRSI_H1, 0, 0, 30, rsi)) {
        return false;
    }
    
    // Find recent lows in price
    int low1Index = -1, low2Index = -1;
    
    // Find the first low (most recent)
    for (int i = 5; i < 15; i++) {
        if (low[i] < low[i-1] && low[i] < low[i-2] && 
            low[i] < low[i+1] && low[i] < low[i+2]) {
            low1Index = i;
            break;
        }
    }
    
    // Find the second low (older)
    if (low1Index > 0) {
        for (int i = low1Index + 5; i < 28; i++) {
            if (low[i] < low[i-1] && low[i] < low[i-2] && 
                low[i] < low[i+1] && low[i] < low[i+2]) {
                low2Index = i;
                break;
            }
        }
    }
    
    // Check if we found two price lows
    if (low1Index < 0 || low2Index < 0) {
        return false;
    }
    
    // Check for bullish divergence
    if (low[low1Index] < low[low2Index] && rsi[low1Index] > rsi[low2Index]) {
        return true; // Bullish divergence found
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect bearish divergence                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectBearishDivergence()
{
    // For bearish divergence:
    // Price makes higher highs, but RSI makes lower highs
    
    // Get price data
    double high[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(close, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 30, high) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 30, close) <= 0) {
        return false;
    }
    
    // Get RSI data
    double rsi[];
    ArraySetAsSeries(rsi, true);
    
    if (!SafeCopyBuffer(m_handleRSI_H1, 0, 0, 30, rsi)) {
        return false;
    }
    
    // Find recent highs in price
    int high1Index = -1, high2Index = -1;
    
    // Find the first high (most recent)
    for (int i = 5; i < 15; i++) {
        if (high[i] > high[i-1] && high[i] > high[i-2] && 
            high[i] > high[i+1] && high[i] > high[i+2]) {
            high1Index = i;
            break;
        }
    }
    
    // Find the second high (older)
    if (high1Index > 0) {
        for (int i = high1Index + 5; i < 28; i++) {
            if (high[i] > high[i-1] && high[i] > high[i-2] && 
                high[i] > high[i+1] && high[i] > high[i+2]) {
                high2Index = i;
                break;
            }
        }
    }
    
    // Check if we found two price highs
    if (high1Index < 0 || high2Index < 0) {
        return false;
    }
    
    // Check for bearish divergence
    if (high[high1Index] > high[high2Index] && rsi[high1Index] < rsi[high2Index]) {
        return true; // Bearish divergence found
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect engulfing pattern                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectEngulfingPattern()
{
    // Get recent price data
    double open[], close[];
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(close, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 3, open) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 3, close) <= 0) {
        return false;
    }
    
    // Bullish engulfing
    if (close[1] > open[1] && open[2] > close[2] && 
        open[1] <= close[2] && close[1] >= open[2]) {
        return true;
    }
    
    // Bearish engulfing
    if (close[1] < open[1] && open[2] < close[2] && 
        open[1] >= close[2] && close[1] <= open[2]) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect break of structure                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectBreakOfStructure()
{
    // Get recent price data
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 30, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 30, low) <= 0) {
        return false;
    }
    
    // Find recent swing points
    int swingHighIndex1 = -1, swingHighIndex2 = -1;
    int swingLowIndex1 = -1, swingLowIndex2 = -1;
    
    // Find two most recent swing highs
    for (int i = 3; i < 27; i++) {
        if (high[i] > high[i-1] && high[i] > high[i-2] && 
            high[i] > high[i+1] && high[i] > high[i+2]) {
            
            if (swingHighIndex1 == -1) {
                swingHighIndex1 = i;
            }
            else {
                swingHighIndex2 = i;
                break;
            }
        }
    }
    
    // Find two most recent swing lows
    for (int i = 3; i < 27; i++) {
        if (low[i] < low[i-1] && low[i] < low[i-2] && 
            low[i] < low[i+1] && low[i] < low[i+2]) {
            
            if (swingLowIndex1 == -1) {
                swingLowIndex1 = i;
            }
            else {
                swingLowIndex2 = i;
                break;
            }
        }
    }
    
    // Check for break of structure
    if (swingHighIndex1 != -1 && swingHighIndex2 != -1) {
        // Bullish break of structure (higher highs)
        if (high[swingHighIndex1] > high[swingHighIndex2]) {
            return true;
        }
    }
    
    if (swingLowIndex1 != -1 && swingLowIndex2 != -1) {
        // Bearish break of structure (lower lows)
        if (low[swingLowIndex1] < low[swingLowIndex2]) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect change of character                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectChangeOfCharacter()
{
    // Get price and volume data
    double high[], low[], close[];
    long volume[];
    
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    ArraySetAsSeries(volume, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 20, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 20, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 20, close) <= 0 ||
        CopyTickVolume(m_symbol, PERIOD_H1, 0, 20, volume) <= 0) {
        return false;
    }
    
    // Calculate average range and volume for past 10 bars
    double avgRange10 = 0;
    double avgVolume10 = 0;
    
    for (int i = 10; i < 20; i++) {
        avgRange10 += (high[i] - low[i]);
        avgVolume10 += volume[i];
    }
    
    avgRange10 /= 10;
    avgVolume10 /= 10;
    
    // Calculate average range and volume for recent 5 bars
    double avgRange5 = 0;
    double avgVolume5 = 0;
    
    for (int i = 0; i < 5; i++) {
        avgRange5 += (high[i] - low[i]);
        avgVolume5 += volume[i];
    }
    
    avgRange5 /= 5;
    avgVolume5 /= 5;
    
    // Check for significant change in market character
    if (avgRange5 > avgRange10 * 1.5 && avgVolume5 > avgVolume10 * 1.3) {
        // Significant increase in both range and volume
        return true;
    }
    
    if (avgRange5 < avgRange10 * 0.6 && avgVolume5 < avgVolume10 * 0.7) {
        // Significant decrease in both range and volume
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Analyze market conditions                                        |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeMarketConditions()
{
    // Update market state flags
    m_isTrending = m_adxH4 > m_strongTrendThreshold;
    m_isWeakTrend = m_adxH4 > m_weakTrendThreshold && m_adxH4 <= m_strongTrendThreshold;
    m_isSideway = m_adxH4 < m_weakTrendThreshold;
    m_isVolatile = DetectVolatility();
    m_isRangebound = DetectRangebound();
    m_isInPullback = DetectPullback();
    m_isInBreakout = DetectBreakout();
    m_isInFakeout = DetectFakeout();
    
    // Market phase determination
    m_marketPhase = DetermineMarketPhase();
    
    // Check RSI conditions
    m_isOverbought = IsOverbought();
    m_isOversold = IsOversold();
}

//+------------------------------------------------------------------+
//| Analyze market regime with soft transition                       |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeMarketRegimeSoft()
{
    // Previous state
    bool wasTrending = m_isTrending;
    bool wasSideway = m_isSideway;
    
    // Current ADX slope
    double adxChange = m_adxH4 - m_adxPrev;
    
    // Regime confidence calculation
    if (m_isTrending) {
        // In trending regime
        m_regimeConfidence = MathMin(1.0, (m_adxH4 - m_weakTrendThreshold) / 15.0);
        
        // Update regime age
        if (!wasTrending) {
            m_regimeAge = 1; // Just transitioned
        }
        else {
            m_regimeAge++;
        }
        
        // Check for transition
        if (adxChange < -0.3) {
            m_isTransitioning = true;
            m_regimeTransitionScore = MathMin(1.0, MathAbs(adxChange) / 2.0);
        }
        else {
            m_isTransitioning = false;
            m_regimeTransitionScore = 0;
        }
    }
    else if (m_isSideway) {
        // In sideways regime
        m_regimeConfidence = MathMin(1.0, (m_weakTrendThreshold - m_adxH4) / 10.0);
        
        // Update regime age
        if (!wasSideway) {
            m_regimeAge = 1; // Just transitioned
        }
        else {
            m_regimeAge++;
        }
        
        // Check for transition
        if (adxChange > 0.3) {
            m_isTransitioning = true;
            m_regimeTransitionScore = MathMin(1.0, MathAbs(adxChange) / 2.0);
        }
        else {
            m_isTransitioning = false;
            m_regimeTransitionScore = 0;
        }
    }
    else {
        // Weak trend - transitional state
        m_regimeConfidence = 0.5; // Moderate confidence
        m_isTransitioning = true;
        m_regimeTransitionScore = 0.5;
        m_regimeAge++;
    }
}

//+------------------------------------------------------------------+
//| Analyze session characteristics                                  |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeSessionCharacteristics()
{
    // Get current hour (in broker time)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int currentHour = dt.hour;
    
    // Adjust for GMT offset
    currentHour = (currentHour + m_GMT_Offset) % 24;
    if (currentHour < 0) currentHour += 24;
    
    // Determine session start/end flags
    switch (m_currentSession) {
        case SESSION_ASIAN:
            // Asian session: 00:00-08:00 GMT
            m_isSessionStart = (currentHour >= 0 && currentHour <= 1);
            m_isSessionEnd = (currentHour >= 6 && currentHour <= 7);
            break;
            
        case SESSION_EUROPEAN:
            // European session: 08:00-16:00 GMT
            m_isSessionStart = (currentHour >= 8 && currentHour <= 9);
            m_isSessionEnd = (currentHour >= 14 && currentHour <= 15);
            break;
            
        case SESSION_AMERICAN:
            // American session: 13:00-21:00 GMT
            m_isSessionStart = (currentHour >= 13 && currentHour <= 14);
            m_isSessionEnd = (currentHour >= 19 && currentHour <= 20);
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            // European-American overlap: 13:00-16:00 GMT
            m_isSessionStart = (currentHour == 13);
            m_isSessionEnd = (currentHour == 15);
            break;
            
        case SESSION_CLOSING:
            // Closing session: 21:00-00:00 GMT
            m_isSessionStart = (currentHour == 21);
            m_isSessionEnd = (currentHour == 23);
            break;
            
        default:
            m_isSessionStart = false;
            m_isSessionEnd = false;
            break;
    }
}

//+------------------------------------------------------------------+
//| Analyze institutional activity                                   |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeInstitutionalActivity()
{
    // Calculate smart money index based on available data
    double smiScore = 0.5; // Default neutral value
    
    // Use liquidity levels
    if (m_liquidityAbove > 0 || m_liquidityBelow > 0) {
        // Higher score if more liquidity on one side
        double liquidityRatio = 0.5;
        if (m_liquidityAbove + m_liquidityBelow > 0) {
            liquidityRatio = m_liquidityAbove / (m_liquidityAbove + m_liquidityBelow);
        }
        
        // If liquidity imbalance, suggest potential smart money interest
        if (liquidityRatio > 0.7 || liquidityRatio < 0.3) {
            smiScore += 0.1;
        }
    }
    
    // Consider order blocks
    if (m_bullishOBHigh > 0 || m_bearishOBLow > 0) {
        smiScore += 0.1; // Order blocks suggest institutional activity
    }
    
    // Fair value gaps
    if (m_fvgCount > 0) {
        smiScore += 0.1; // FVGs suggest institutional activity
    }
    
    // Volume analysis
    if (m_volumeCurrent > m_volumeSMA20 * 1.5) {
        smiScore += 0.1; // High volume can indicate institutional participation
    }
    
    // Market efficiency
    if (m_marketEfficiencyRatio > 0.7) {
        smiScore += 0.1; // Efficient markets often driven by smart money
    }
    
    // Change of character
    if (m_hasChangeOfCharacter) {
        smiScore += 0.1; // Sudden change may indicate institutional involvement
    }
    
    // Break of structure
    if (m_hasBreakOfStructure) {
        smiScore += 0.1; // Structure breaks often driven by smart money
    }
    
    // Ensure score is within [0, 1] range
    m_smartMoneyIndex = MathMax(0.0, MathMin(1.0, smiScore));
}

//+------------------------------------------------------------------+
//| Analyze multi-timeframe confluence                               |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeMTFConfluence()
{
    // Already calculated in Update() via:
    // - CalculateMTFTrendScore()
    // - CalculateMTFVolatilityScore()
    // - CalculateMTFMomentumScore()
    
    // Additional MTF analysis can be added here if needed
}

//+------------------------------------------------------------------+
//| Analyze market efficiency                                        |
//+------------------------------------------------------------------+
void CMarketProfile::AnalyzeMarketEfficiency()
{
    // Market efficiency ratio already calculated in Update()
    // via CalculateMarketEfficiencyRatio()
    
    // Determine market regime based on efficiency and other metrics
    if (m_marketEfficiencyRatio > 0.7) {
        if (m_isTrending) {
            // Efficient trending market
            m_regime = REGIME_TRENDING;
        }
        else {
            // Efficient but not trending - likely directional mean reversion
            m_regime = REGIME_TRENDING_WITH_PULLBACK;
        }
    }
    else if (m_marketEfficiencyRatio > 0.4) {
        if (m_isVolatile) {
            // Moderate efficiency with high volatility
            m_regime = REGIME_VOLATILE_BALANCED;
        }
        else {
            // Moderate efficiency, normal volatility
            m_regime = REGIME_BALANCED;
        }
    }
    else {
        if (m_isRangebound) {
            // Inefficient, rangebound market
            m_regime = REGIME_RANGING;
        }
        else if (m_isVolatile) {
            // Inefficient, volatile market
            m_regime = REGIME_CHOPPY;
        }
        else {
            // Inefficient, not rangebound, not volatile
            m_regime = REGIME_TRANSITIONING;
        }
    }
}

//+------------------------------------------------------------------+
//| Determine current trading session                                |
//+------------------------------------------------------------------+
ENUM_SESSION CMarketProfile::DetermineCurrentSession()
{
    // Get current hour (in broker time)
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;
    
    // Adjust for GMT offset
    hour = (hour + m_GMT_Offset) % 24;
    if (hour < 0) hour += 24;
    
    // Asian session: 00:00-08:00 GMT
    if (hour >= 0 && hour < 8) {
        return SESSION_ASIAN;
    }
    // European session: 08:00-16:00 GMT
    else if (hour >= 8 && hour < 13) {
        return SESSION_EUROPEAN;
    }
    // European-American overlap: 13:00-16:00 GMT
    else if (hour >= 13 && hour < 16) {
        return SESSION_EUROPEAN_AMERICAN;
    }
    // American session: 16:00-21:00 GMT
    else if (hour >= 16 && hour < 21) {
        return SESSION_AMERICAN;
    }
    // Closing session: 21:00-00:00 GMT
    else {
        return SESSION_CLOSING;
    }
}

//+------------------------------------------------------------------+
//| Determine market phase                                           |
//+------------------------------------------------------------------+
ENUM_MARKET_PHASE CMarketProfile::DetermineMarketPhase()
{
    // Get EMA and ADX dynamics
    double emaSlope = m_slopeEMA34H1;
    double emaSlopeChange = m_slopeEMA34H1 - m_emaSlope_prev;
    double adxSlope = m_adxH4 - m_adxPrev;
    
    // Phase determination with dynamic thresholds
    
    // Accumulation Phase
    if (m_isSideway && !m_isVolatile && emaSlope > -m_dynamicAccumulationThreshold &&
        emaSlope < m_dynamicAccumulationThreshold) {
        
        return PHASE_ACCUMULATION;
    }
    
    // Impulse Phase (trending with momentum)
    if (m_isTrending && emaSlope > m_dynamicImpulseThreshold && adxSlope >= 0) {
        return PHASE_IMPULSE;
    }
    
    // Correction Phase (pullback within trend)
    if ((m_isTrending || m_isWeakTrend) && 
        ((emaSlope > 0 && emaSlopeChange < -m_dynamicCorrectionThreshold) || 
         (emaSlope < 0 && emaSlopeChange > m_dynamicCorrectionThreshold))) {
        
        return PHASE_CORRECTION;
    }
    
    // Distribution Phase (trend weakening)
    if ((m_isTrending || m_isWeakTrend) && 
        emaSlope < m_dynamicDistributionThreshold && adxSlope < 0) {
        
        return PHASE_DISTRIBUTION;
    }
    
    // Exhaustion Phase (extreme moves)
    if (m_isVolatile && 
        ((m_isOverbought && emaSlope > m_dynamicExhaustionThreshold) || 
         (m_isOversold && emaSlope < -m_dynamicExhaustionThreshold))) {
        
        return PHASE_EXHAUSTION;
    }
    
    // Default to current phase if none matched
    // Use previous phase persistence
    return m_marketPhase;
}

//+------------------------------------------------------------------+
//| Update dynamic thresholds                                        |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateDynamicThresholds()
{
    // Adapt thresholds based on market conditions
    double volatilityFactor = m_atrRatio;
    
    // Dynamically adjust phase detection thresholds
    m_dynamicAccumulationThreshold = CalculateAdaptiveThreshold(0.1, volatilityFactor);
    m_dynamicImpulseThreshold = CalculateAdaptiveThreshold(0.3, volatilityFactor);
    m_dynamicCorrectionThreshold = CalculateAdaptiveThreshold(0.2, volatilityFactor);
    m_dynamicDistributionThreshold = CalculateAdaptiveThreshold(0.1, volatilityFactor);
    m_dynamicExhaustionThreshold = CalculateAdaptiveThreshold(0.5, volatilityFactor);
}

//+------------------------------------------------------------------+
//| Calculate adaptive threshold based on volatility                  |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateAdaptiveThreshold(double baseThreshold, double volatilityFactor)
{
    // Adjust threshold based on current market volatility
    double adjustmentFactor;
    
    if (volatilityFactor > 1.5) {
        // High volatility - increase thresholds
        adjustmentFactor = MathMin(2.0, volatilityFactor / 1.5);
    }
    else if (volatilityFactor < 0.7) {
        // Low volatility - decrease thresholds
        adjustmentFactor = MathMax(0.5, volatilityFactor / 0.7);
    }
    else {
        // Normal volatility - neutral adjustment
        adjustmentFactor = 1.0;
    }
    
    return baseThreshold * adjustmentFactor;
}

//+------------------------------------------------------------------+
//| Update swing points                                              |
//+------------------------------------------------------------------+
void CMarketProfile::UpdateSwingPoints()
{
    // Get recent high/low data
    double high[], low[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 30, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 30, low) <= 0) {
        return;
    }
    
    // Find recent swing high
    for (int i = 5; i < 25; i++) {
        if (high[i] > high[i-1] && high[i] > high[i-2] && 
            high[i] > high[i+1] && high[i] > high[i+2]) {
            
            m_recentSwingHigh = high[i];
            break;
        }
    }
    
    // Find recent swing low
    for (int i = 5; i < 25; i++) {
        if (low[i] < low[i-1] && low[i] < low[i-2] && 
            low[i] < low[i+1] && low[i] < low[i+2]) {
            
            m_recentSwingLow = low[i];
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Detect volume spike                                              |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectVolumeSpike()
{
    if (m_volumeSMA20 <= 0) return false;
    
    return (m_volumeCurrent > m_volumeSMA20 * m_volumeSpikeThreshold);
}

//+------------------------------------------------------------------+
//| Detect declining volume                                          |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectVolumeDeclining()
{
    // Get volume data
    long volume[];
    ArraySetAsSeries(volume, true);
    
    if (CopyTickVolume(m_symbol, PERIOD_H1, 0, 11, volume) <= 0) {
        return false;
    }
    
    // Check if volume is declining over the last 5 bars
    int decliningCount = 0;
    
    for (int i = 0; i < 5; i++) {
        if (volume[i] < volume[i+1]) {
            decliningCount++;
        }
    }
    
    // Consider volume declining if 4 out of 5 bars show declining volume
    return (decliningCount >= 4);
}

//+------------------------------------------------------------------+
//| Detect high volatility                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectVolatility()
{
    return (m_atrRatio > m_volatilityThreshold);
}

//+------------------------------------------------------------------+
//| Detect weak trend                                                |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectWeakTrend()
{
    return (m_adxH4 > m_weakTrendThreshold && m_adxH4 <= m_strongTrendThreshold);
}

//+------------------------------------------------------------------+
//| Detect sideways market                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectSideway()
{
    return (m_adxH4 < m_weakTrendThreshold);
}

//+------------------------------------------------------------------+
//| Detect range-bound market                                        |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectRangebound()
{
    // Get price data
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 30, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 30, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 1, close) <= 0) {
        return false;
    }
    
    // Find highest high and lowest low
    double highestHigh = high[ArrayMaximum(high, 0, 20)];
    double lowestLow = low[ArrayMinimum(low, 0, 20)];
    
    // Calculate range size relative to ATR
    double rangeSize = (highestHigh - lowestLow) / m_atrH1;
    
    // Calculate relative position within range
    double relativePosition = 0;
    if (highestHigh > lowestLow) {
        relativePosition = (close[0] - lowestLow) / (highestHigh - lowestLow);
    }
    
    // Market is range-bound if:
    // 1. Range size is not too large (2-6 ATRs)
    // 2. Current price is not too close to range bounds
    // 3. ADX is low (already checked via m_isSideway)
    
    bool goodRangeSize = (rangeSize >= 2.0 && rangeSize <= 6.0);
    bool notNearBounds = (relativePosition >= 0.1 && relativePosition <= 0.9);
    
    return (m_isSideway && goodRangeSize && notNearBounds);
}

//+------------------------------------------------------------------+
//| Detect breakout                                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectBreakout()
{
    // Get price data
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 30, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 30, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 5, close) <= 0) {
        return false;
    }
    
    // Find recent range (excluding last few bars)
    double highestHigh = high[ArrayMaximum(high, 5, 25)];
    double lowestLow = low[ArrayMinimum(low, 5, 25)];
    
    // Check if current price has broken out of the range
    if (close[0] > highestHigh + m_atrH1 * 0.3) {
        // Potential bullish breakout
        
        // Check for increased momentum
        if (close[0] > close[1] && close[1] > close[2] && 
            m_macdHistogram > 0 && m_macdHistogram > m_macdHistogramPrev) {
            return true;
        }
    }
    else if (close[0] < lowestLow - m_atrH1 * 0.3) {
        // Potential bearish breakout
        
        // Check for increased momentum
        if (close[0] < close[1] && close[1] < close[2] && 
            m_macdHistogram < 0 && m_macdHistogram < m_macdHistogramPrev) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect pullback                                                  |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectPullback()
{
    // Get price data
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyHigh(m_symbol, PERIOD_H1, 0, 20, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 20, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 20, close) <= 0) {
        return false;
    }
    
    // Check if we're in a trend
    if (!m_isTrending && !m_isWeakTrend) {
        return false;
    }
    
    // Determine trend direction
    bool uptrend = IsTrendUp();
    
    if (uptrend) {
        // Check for pullback in uptrend
        // Price has moved lower over last 1-3 bars but is still above recent swing low
        
        // Find recent swing low (excluding the most recent bars)
        double swingLow = 999999;
        for (int i = 5; i < 15; i++) {
            if (low[i] < low[i-1] && low[i] < low[i+1]) {
                swingLow = low[i];
                break;
            }
        }
        
        if (swingLow < 999999) {
            // Check if price pulled back but is still above swing low
            if (close[0] < close[3] && close[0] > swingLow) {
                // Calculate pullback size
                double pullbackSize = (high[3] - close[0]) / m_atrH1;
                
                // Pullback should be significant but not too large
                if (pullbackSize > 0.5 && pullbackSize < 2.0) {
                    return true;
                }
            }
        }
    }
    else {
        // Check for pullback in downtrend
        // Price has moved higher over last 1-3 bars but is still below recent swing high
        
        // Find recent swing high (excluding the most recent bars)
        double swingHigh = -999999;
        for (int i = 5; i < 15; i++) {
            if (high[i] > high[i-1] && high[i] > high[i+1]) {
                swingHigh = high[i];
                break;
            }
        }
        
        if (swingHigh > -999999) {
            // Check if price pulled back but is still below swing high
            if (close[0] > close[3] && close[0] < swingHigh) {
                // Calculate pullback size
                double pullbackSize = (close[0] - low[3]) / m_atrH1;
                
                // Pullback should be significant but not too large
                if (pullbackSize > 0.5 && pullbackSize < 2.0) {
                    return true;
                }
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Detect fakeout                                                   |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectFakeout()
{
    // Get price data
    double open[], high[], low[], close[];
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 10, open) <= 0 ||
        CopyHigh(m_symbol, PERIOD_H1, 0, 10, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 10, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 10, close) <= 0) {
        return false;
    }
    
    // Find recent range high/low (excluding the last 2 bars)
    double rangeHigh = high[ArrayMaximum(high, 2, 8)];
    double rangeLow = low[ArrayMinimum(low, 2, 8)];
    
    // Check for bullish fakeout
    if (high[1] > rangeHigh && close[1] < rangeHigh && close[0] < close[1]) {
        // Price broke above range high but failed to close above it
        // and continued lower on the next bar
        return true;
    }
    
    // Check for bearish fakeout
    if (low[1] < rangeLow && close[1] > rangeLow && close[0] > close[1]) {
        // Price broke below range low but failed to close below it
        // and continued higher on the next bar
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if RSI is overbought                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::IsOverbought() const
{
    return (m_rsiH1 > m_rsiOverboughtThreshold);
}

//+------------------------------------------------------------------+
//| Check if RSI is oversold                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::IsOversold() const
{
    return (m_rsiH1 < m_rsiOversoldThreshold);
}

//+------------------------------------------------------------------+
//| Check for positive momentum                                      |
//+------------------------------------------------------------------+
bool CMarketProfile::HasPositiveMomentum(bool isLong) const
{
    if (isLong) {
        // For long position, check for positive momentum
        return (m_macdHistogram > 0 && m_macdHistogram > m_macdHistogramPrev);
    }
    else {
        // For short position, check for negative momentum
        return (m_macdHistogram < 0 && m_macdHistogram < m_macdHistogramPrev);
    }
}

//+------------------------------------------------------------------+
//| Check if price is near key level                                 |
//+------------------------------------------------------------------+
bool CMarketProfile::IsNearKeyLevel(double price)
{
    // If price is not provided, use current price
    if (price <= 0) {
        double close[];
        ArraySetAsSeries(close, true);
        
        if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
            return false;
        }
        
        price = close[0];
    }
    
    // Check if price is near key resistance
    if (m_keyResistanceLevel > 0) {
        double distToResistance = MathAbs(price - m_keyResistanceLevel) / m_atrH1;
        if (distToResistance < 0.5) {
            return true;
        }
    }
    
    // Check if price is near key support
    if (m_keySupportLevel > 0) {
        double distToSupport = MathAbs(price - m_keySupportLevel) / m_atrH1;
        if (distToSupport < 0.5) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for key support                                            |
//+------------------------------------------------------------------+
bool CMarketProfile::HasKeySupport()
{
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return false;
    }
    
    double price = close[0];
    
    // Check if price is near key support
    if (m_keySupportLevel > 0 && price > m_keySupportLevel) {
        double distToSupport = (price - m_keySupportLevel) / m_atrH1;
        return (distToSupport < 1.0);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for key resistance                                         |
//+------------------------------------------------------------------+
bool CMarketProfile::HasKeyResistance()
{
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return false;
    }
    
    double price = close[0];
    
    // Check if price is near key resistance
    if (m_keyResistanceLevel > 0 && price < m_keyResistanceLevel) {
        double distToResistance = (m_keyResistanceLevel - price) / m_atrH1;
        return (distToResistance < 1.0);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for uptrend                                                |
//+------------------------------------------------------------------+
bool CMarketProfile::IsTrendUp() const
{
    return (m_di_plus_h4 > m_di_minus_h4 && m_emaAlignment > 0);
}

//+------------------------------------------------------------------+
//| Check for downtrend                                              |
//+------------------------------------------------------------------+
bool CMarketProfile::IsTrendDown() const
{
    return (m_di_minus_h4 > m_di_plus_h4 && m_emaAlignment < 0);
}

//+------------------------------------------------------------------+
//| Check for strong trend                                           |
//+------------------------------------------------------------------+
bool CMarketProfile::IsStrongTrend() const
{
    return (m_adxH4 > m_strongTrendThreshold);
}

//+------------------------------------------------------------------+
//| Full update of market profile                                    |
//+------------------------------------------------------------------+
bool CMarketProfile::Update()
{
    if (!m_isInitialized) {
        if (m_logger) m_logger.LogError("Update: MarketProfile not initialized");
        return false;
    }
    
    bool result = UpdateIndicatorData();
    
    if (m_logger && result) {
        m_logger.LogInfo(StringFormat(
            "MarketProfile updated: ADX=%.1f, ATR=%.5f, ATRratio=%.2f, EMAslopeH1=%.4f", 
            m_adxH4, m_atrH1, m_atrRatio, m_slopeEMA34H1
        ));
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Light update (minimal recalculation)                             |
//+------------------------------------------------------------------+
bool CMarketProfile::LightUpdate()
{
    if (!m_isInitialized) {
        if (m_logger) m_logger.LogError("LightUpdate: MarketProfile not initialized");
        return false;
    }
    
    // Check if full update needed
    datetime currentTime = TimeCurrent();
    
    // If no full update has been performed yet or if it's been too long
    if (m_lastFullUpdateTime == 0 || (currentTime - m_lastFullUpdateTime) > 900) { // 15 minutes
        return Update(); // Perform full update
    }
    
    // Get current price (minimal update)
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        if (m_logger) m_logger.LogWarning("LightUpdate: Failed to copy current price");
        return false;
    }
    
    // Check proximity to key levels
    double price = close[0];
    
    // Update last update time
    m_lastUpdateTime = currentTime;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate EMA slope                                              |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateSlopeEMA34()
{
    double ema34[];
    ArraySetAsSeries(ema34, true);
    
    if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, m_EMASlopePeriodsH1 + 1, ema34)) {
        return 0;
    }
    
    // Calculate linear regression slope
    double sumX = 0;
    double sumY = 0;
    double sumXX = 0;
    double sumXY = 0;
    int n = m_EMASlopePeriodsH1;
    
    for (int i = 0; i < n; i++) {
        sumX += i;
        sumY += ema34[i];
        sumXX += i * i;
        sumXY += i * ema34[i];
    }
    
    double slope = 0;
    double divisor = (n * sumXX - sumX * sumX);
    
    if (divisor != 0) {
        slope = (n * sumXY - sumX * sumY) / divisor;
    }
    
    // Normalize slope by ATR
    if (m_atrH1 > 0) {
        slope = slope / m_atrH1;
    }
    
    return slope;
}

//+------------------------------------------------------------------+
//| Calculate distance between EMA89 and EMA200                       |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateDistanceEMA89_200()
{
    double ema89[], ema200[];
    ArraySetAsSeries(ema89, true);
    ArraySetAsSeries(ema200, true);
    
    if (!SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89) ||
        !SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200)) {
        return 0;
    }
    
    // Calculate normalized distance
    double distance = ema89[0] - ema200[0];
    
    // Normalize by ATR
    if (m_atrH1 > 0) {
        distance = distance / m_atrH1;
    }
    
    return distance;
}

//+------------------------------------------------------------------+
//| Calculate EMA alignment                                          |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateEMAAlignment()
{
    double ema34[], ema89[], ema200[];
    ArraySetAsSeries(ema34, true);
    ArraySetAsSeries(ema89, true);
    ArraySetAsSeries(ema200, true);
    
    if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, 1, ema34) ||
        !SafeCopyBuffer(m_handleEMA89_H1, 0, 0, 1, ema89) ||
        !SafeCopyBuffer(m_handleEMA200_H1, 0, 0, 1, ema200)) {
        return 0;
    }
    
    // Perfect alignment:
    // - Up trend: ema34 > ema89 > ema200
    // - Down trend: ema34 < ema89 < ema200
    
    double alignment = 0;
    
    if (ema34[0] > ema89[0] && ema89[0] > ema200[0]) {
        // Bullish alignment
        alignment = 1.0;
    }
    else if (ema34[0] < ema89[0] && ema89[0] < ema200[0]) {
        // Bearish alignment
        alignment = -1.0;
    }
    else if ((ema34[0] > ema89[0] && ema89[0] < ema200[0]) ||
             (ema34[0] < ema89[0] && ema89[0] > ema200[0])) {
        // Mixed alignment
        alignment = 0.0;
    }
    else if (ema34[0] > ema200[0]) {
        // Partial bullish alignment
        alignment = 0.5;
    }
    else if (ema34[0] < ema200[0]) {
        // Partial bearish alignment
        alignment = -0.5;
    }
    
    return alignment;
}

//+------------------------------------------------------------------+
//| Calculate ATR slope                                              |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateATRSlope()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    
    if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 5, atr)) {
        return 0;
    }
    
    // Calculate basic slope
    double slope = (atr[0] - atr[4]) / 4;
    
    // Normalize by ATR
    if (atr[0] > 0) {
        slope = slope / atr[0];
    }
    
    return slope;
}

//+------------------------------------------------------------------+
//| Calculate ATR acceleration                                       |
//+------------------------------------------------------------------+
double CMarketProfile::CalculateATRAcceleration()
{
    double atr[];
    ArraySetAsSeries(atr, true);
    
    if (!SafeCopyBuffer(m_handleATR_H1, 0, 0, 10, atr)) {
        return 0;
    }
    
    // Calculate first derivatives (slopes)
    double slopes[5];
    for (int i = 0; i < 5; i++) {
        slopes[i] = atr[i] - atr[i+1];
    }
    
    // Calculate second derivative (acceleration)
    double acceleration = 0;
    for (int i = 0; i < 4; i++) {
        acceleration += (slopes[i] - slopes[i+1]);
    }
    acceleration /= 4;
    
    // Normalize by ATR
    if (atr[0] > 0) {
        acceleration = acceleration / atr[0];
    }
    
    return acceleration;
}

//+------------------------------------------------------------------+
//| Calculate EMA slope statistics                                   |
//+------------------------------------------------------------------+
void CMarketProfile::CalculateEMASlopeStatistics()
{
    double ema34[];
    ArraySetAsSeries(ema34, true);
    
    if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, 20, ema34)) {
        return;
    }
    
    // Calculate slopes for the last 15 periods
    double slopes[15];
    for (int i = 0; i < 15; i++) {
        slopes[i] = ema34[i] - ema34[i+1];
        
        // Normalize by ATR
        if (m_atrH1 > 0) {
            slopes[i] = slopes[i] / m_atrH1;
        }
    }
    
    // Calculate average slope
    double sum = 0;
    for (int i = 0; i < 15; i++) {
        sum += slopes[i];
    }
    m_emaSlopeAvg = sum / 15;
    
    // Calculate standard deviation
    double sumSq = 0;
    for (int i = 0; i < 15; i++) {
        sumSq += (slopes[i] - m_emaSlopeAvg) * (slopes[i] - m_emaSlopeAvg);
    }
    m_emaSlopeStdDev = MathSqrt(sumSq / 15);
}

//+------------------------------------------------------------------+
//| Predict trend continuation probability                            |
//+------------------------------------------------------------------+
double CMarketProfile::PredictTrendContinuationProbability()
{
    // Base probability
    double probability = 0.5; // Neutral starting point
    
    // Adjust based on ADX strength
    if (m_adxH4 > 30) {
        probability += 0.15; // Strong trend
    }
    else if (m_adxH4 > 25) {
        probability += 0.1; // Moderate trend
    }
    else if (m_adxH4 < 15) {
        probability -= 0.15; // Very weak trend
    }
    
    // Adjust based on ADX slope
    double adxSlope = m_adxH4 - m_adxPrev;
    if (adxSlope > 0.5) {
        probability += 0.1; // Strengthening trend
    }
    else if (adxSlope < -0.5) {
        probability -= 0.1; // Weakening trend
    }
    
    // Adjust based on EMA alignment
    if (MathAbs(m_emaAlignment) > 0.8) {
        probability += 0.1; // Strong alignment
    }
    else if (MathAbs(m_emaAlignment) < 0.2) {
        probability -= 0.1; // Weak alignment
    }
    
    // Adjust based on MACD
    if ((m_macdHistogram > 0 && m_macdHistogram > m_macdHistogramPrev) ||
        (m_macdHistogram < 0 && m_macdHistogram < m_macdHistogramPrev)) {
        probability += 0.1; // Momentum in trend direction
    }
    else if ((m_macdHistogram > 0 && m_macdHistogram < m_macdHistogramPrev) ||
             (m_macdHistogram < 0 && m_macdHistogram > m_macdHistogramPrev)) {
        probability -= 0.1; // Momentum against trend direction
    }
    
    // Adjust based on regime age
    if (m_regimeAge > 20) {
        probability -= 0.05; // Older trend, higher chance of reversal
    }
    else if (m_regimeAge < 5) {
        probability += 0.05; // Newer trend, higher chance of continuation
    }
    
    // Ensure probability is between 0 and 1
    probability = MathMax(0.0, MathMin(1.0, probability));
    
    return probability;
}

//+------------------------------------------------------------------+
//| Evaluate setup quality                                           |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateSetupQuality(bool isLong, ENUM_ENTRY_SCENARIO scenario)
{
    // Base quality score
    double quality = 0.5; // Neutral starting point
    
    // Evaluate based on scenario
    switch (scenario) {
        case ENTRY_TREND_FOLLOW:
            if (isLong && IsTrendUp()) {
                quality += 0.2; // Long in uptrend
            }
            else if (!isLong && IsTrendDown()) {
                quality += 0.2; // Short in downtrend
            }
            else {
                quality -= 0.3; // Counter-trend entry
            }
            
            // Trend strength
            if (m_adxH4 > 30) {
                quality += 0.1; // Strong trend
            }
            else if (m_adxH4 < 20) {
                quality -= 0.1; // Weak trend
            }
            
            // EMA alignment
            if (MathAbs(m_emaAlignment) > 0.8) {
                quality += 0.1; // Strong alignment
            }
            break;
            
        case ENTRY_PULLBACK:
            if (isLong && IsTrendUp() && m_isInPullback) {
                quality += 0.2; // Long pullback in uptrend
            }
            else if (!isLong && IsTrendDown() && m_isInPullback) {
                quality += 0.2; // Short pullback in downtrend
            }
            else {
                quality -= 0.2; // Not a valid pullback scenario
            }
            
            // RSI conditions
            if (isLong && m_rsiH1 < 40 && m_rsiH1 > 30) {
                quality += 0.1; // Long pullback with oversold condition
            }
            else if (!isLong && m_rsiH1 > 60 && m_rsiH1 < 70) {
                quality += 0.1; // Short pullback with overbought condition
            }
            break;
            
        case ENTRY_BREAKOUT:
            if (m_isInBreakout) {
                quality += 0.2; // Confirmed breakout
            }
            else {
                quality -= 0.3; // Not a confirmed breakout
            }
            
            // Volume confirmation
            if (m_hasVolumeSpike) {
                quality += 0.1; // Volume spike with breakout
            }
            
            // Market efficiency
            if (m_marketEfficiencyRatio > 0.7) {
                quality += 0.1; // Efficient market, good for breakouts
            }
            break;
            
        case ENTRY_REVERSAL:
            if (isLong && IsTrendDown() && (m_isOversold || m_hasBullishDivergence)) {
                quality += 0.2; // Potential bullish reversal
            }
            else if (!isLong && IsTrendUp() && (m_isOverbought || m_hasBearishDivergence)) {
                quality += 0.2; // Potential bearish reversal
            }
            else {
                quality -= 0.3; // Not a valid reversal scenario
            }
            
            // Divergence
            if (isLong && m_hasBullishDivergence) {
                quality += 0.2; // Bullish divergence
            }
            else if (!isLong && m_hasBearishDivergence) {
                quality += 0.2; // Bearish divergence
            }
            
            // Candlestick patterns
            if (m_hasEngulfing || m_hasPinbar) {
                quality += 0.1; // Reversal pattern
            }
            break;
            
        case ENTRY_RANGE:
            if (m_isRangebound) {
                quality += 0.2; // Confirmed range
            }
            else {
                quality -= 0.3; // Not a confirmed range
            }
            
            // Market efficiency
            if (m_marketEfficiencyRatio < 0.3) {
                quality += 0.1; // Inefficient market, good for range trading
            }
            break;
            
        default:
            // No specific scenario, evaluate general conditions
            if (isLong && m_mtfTrendScore > 0.3) {
                quality += 0.1; // Positive MTF trend for long
            }
            else if (!isLong && m_mtfTrendScore < -0.3) {
                quality += 0.1; // Negative MTF trend for short
            }
            
            // Volatility
            if (m_mtfVolatilityScore > 0.7) {
                quality -= 0.1; // High volatility, risky
            }
            else if (m_mtfVolatilityScore < 0.3) {
                quality += 0.1; // Low volatility, more predictable
            }
            break;
    }
    
    // Common quality factors
    
    // Market regime
    if (m_regimeConfidence < 0.5) {
        quality -= 0.1; // Uncertain regime
    }
    
    // Near key levels
    if (isLong && HasKeySupport()) {
        quality += 0.1; // Support for long entry
    }
    else if (!isLong && HasKeyResistance()) {
        quality += 0.1; // Resistance for short entry
    }
    
    // Ensure quality is between 0 and 1
    quality = MathMax(0.0, MathMin(1.0, quality));
    
    return quality;
}

//+------------------------------------------------------------------+
//| Evaluate market for trend trading                                |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForTrend()
{
    // This is already calculated and cached in m_trendFollowingQuality
    return m_trendFollowingQuality;
}

//+------------------------------------------------------------------+
//| Evaluate market for counter-trend trading                         |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForCountertrend()
{
    // This is already calculated and cached in m_counterTrendQuality
    return m_counterTrendQuality;
}

//+------------------------------------------------------------------+
//| Evaluate market for scaling                                      |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForScaling()
{
    double score = 0.5; // Default neutral score
    
    // Assess trend strength
    if (m_adxH4 > 30 && m_adxSlope > 0) {
        score += 0.2; // Strong, increasing trend - good for scaling
    }
    else if (m_adxH4 < 20) {
        score -= 0.3; // Weak trend - bad for scaling
    }
    
    // Assess market efficiency
    if (m_marketEfficiencyRatio > 0.7) {
        score += 0.2; // Efficient market, good for scaling
    }
    else if (m_marketEfficiencyRatio < 0.4) {
        score -= 0.2; // Inefficient market, bad for scaling
    }
    
    // Assess volatility
    if (m_atrRatio > 1.8) {
        score -= 0.1; // Too volatile for scaling
    }
    else if (m_atrRatio < 0.7) {
        score -= 0.1; // Too quiet for scaling
    }
    
    // Assess momentum
    if (MathAbs(m_mtfMomentumScore) > 0.7) {
        score += 0.1; // Strong momentum
    }
    
    // Assess market phase
    if (m_marketPhase == PHASE_IMPULSE) {
        score += 0.2; // Impulse phase ideal for scaling
    }
    else if (m_marketPhase == PHASE_DISTRIBUTION || m_marketPhase == PHASE_EXHAUSTION) {
        score -= 0.3; // Bad phases for scaling
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Evaluate market for breakout trading                              |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForBreakout()
{
    // This is already calculated and cached in m_breakoutQuality
    return m_breakoutQuality;
}

//+------------------------------------------------------------------+
//| Evaluate market for pullback trading                              |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForPullback()
{
    double score = 0.5; // Default neutral score
    
    // Assess trend strength
    if (m_adxH4 > 25) {
        score += 0.2; // Strong trend, good for pullback
    }
    else if (m_adxH4 < 15) {
        score -= 0.2; // Weak trend, bad for pullback
    }
    
    // Assess pullback detection
    if (m_isInPullback) {
        score += 0.3; // Pullback detected
    }
    else {
        score -= 0.2; // No pullback detected
    }
    
    // Assess RSI conditions
    bool uptrend = IsTrendUp();
    if (uptrend && m_rsiH1 < 40 && m_rsiH1 > 30) {
        score += 0.1; // Uptrend with pullback (RSI showing some oversold)
    }
    else if (!uptrend && m_rsiH1 > 60 && m_rsiH1 < 70) {
        score += 0.1; // Downtrend with pullback (RSI showing some overbought)
    }
    
    // Assess market phase
    if (m_marketPhase == PHASE_CORRECTION) {
        score += 0.2; // Correction phase ideal for pullback
    }
    
    // Assess key levels
    if ((uptrend && HasKeySupport()) || (!uptrend && HasKeyResistance())) {
        score += 0.1; // Pullback to key level
    }
    
    // Ensure score is within [0, 1] range
    score = MathMax(0.0, MathMin(1.0, score));
    
    return score;
}

//+------------------------------------------------------------------+
//| Evaluate market for range trading                                 |
//+------------------------------------------------------------------+
double CMarketProfile::EvaluateMarketForRange()
{
    // This is already calculated and cached in m_rangeQuality
    return m_rangeQuality;
}

//+------------------------------------------------------------------+
//| Log market profile details                                       |
//+------------------------------------------------------------------+
void CMarketProfile::LogMarketProfile()
{
    if (!m_logger) return;
    
    string profile = GetMarketProfileSummary();
    m_logger.LogInfo(profile);
}

//+------------------------------------------------------------------+
//| Get market profile summary                                       |
//+------------------------------------------------------------------+
string CMarketProfile::GetMarketProfileSummary()
{
    string summary = "=== MARKET PROFILE SUMMARY ===\n";
    
    // Market Regime
    summary += "Market Regime: " + EnumToString(GetMarketRegimeBasedOnProfile()) + 
              " (Confidence: " + DoubleToString(m_regimeConfidence, 2) + ")\n";
    
    // Current Session
    summary += "Session: " + EnumToString(m_currentSession) + 
              (m_isSessionStart ? " (Start)" : "") + 
              (m_isSessionEnd ? " (End)" : "") + "\n";
    
    // Market Phase
    summary += "Market Phase: " + EnumToString(m_marketPhase) + 
              " (Completion: " + DoubleToString(m_phaseCompletion, 2) + ")\n";
    
    // Trend/Momentum
    summary += "Trend: ADX=" + DoubleToString(m_adxH4, 1) + 
              ", MTF Score=" + DoubleToString(m_mtfTrendScore, 2) + 
              (m_isTrending ? " (Trending)" : "") + 
              (m_isSideway ? " (Sideways)" : "") + "\n";
    
    // Volatility
    summary += "Volatility: ATR Ratio=" + DoubleToString(m_atrRatio, 2) + 
              ", MTF Score=" + DoubleToString(m_mtfVolatilityScore, 2) + 
              (m_isVolatile ? " (Volatile)" : "") + "\n";
    
    // Key Levels
    summary += "Key Levels: Support=" + DoubleToString(m_keySupportLevel, _Digits) + 
              ", Resistance=" + DoubleToString(m_keyResistanceLevel, _Digits) + "\n";
    
    // Current Market State
    summary += "Current State:";
    if (m_isInBreakout) summary += " Breakout";
    if (m_isInPullback) summary += " Pullback";
    if (m_isInFakeout) summary += " Fakeout";
    if (m_isOverbought) summary += " Overbought";
    if (m_isOversold) summary += " Oversold";
    if (m_isRangebound) summary += " Rangebound";
    summary += "\n";
    
    // Trade Quality Scores
    summary += "Trade Quality: Trend=" + DoubleToString(m_trendFollowingQuality, 2) + 
              ", Counter=" + DoubleToString(m_counterTrendQuality, 2) + 
              ", Breakout=" + DoubleToString(m_breakoutQuality, 2) + 
              ", Range=" + DoubleToString(m_rangeQuality, 2) + "\n";
    
    return summary;
}

//+------------------------------------------------------------------+
//| Infer market regime from profile                                 |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME CMarketProfile::GetMarketRegimeBasedOnProfile()
{
    // Return already determined regime
    return m_regime;
}

//+------------------------------------------------------------------+
//| Create complete market profile struct                            |
//+------------------------------------------------------------------+
MarketProfile CMarketProfile::CreateMarketProfile()
{
    MarketProfile profile;
    
    // Initialize with current time
    profile.timeCreated = TimeCurrent();
    
    // Volatility Metrics
    profile.atrCurrent = m_atrH1;
    profile.atrRatio = m_atrRatio;
    profile.atrSlope = m_atrSlope;
    profile.atrAcceleration = CalculateATRAcceleration();
    profile.impliedVolatility = m_atrRatio; // Simple estimation
    profile.volatilityRegimeScore = m_mtfVolatilityScore;
    
    // Trend Metrics
    profile.adxH4 = m_adxH4;
    profile.adxSlope = m_adxH4 - m_adxPrev;
    profile.adxDI_Plus = m_di_plus_h4;
    profile.adxDI_Minus = m_di_minus_h4;
    profile.trendStrength = (m_isTrending ? 1.0 : (m_isWeakTrend ? 0.5 : 0.0));
    profile.trendAge = m_regimeAge;
    profile.trendPersistence = PredictTrendContinuationProbability();
    
    // EMA Metrics
    profile.emaSlope = m_slopeEMA34H1;
    profile.emaAlignment = m_emaAlignment;
    profile.emaMomentumIndex = m_slopeEMA34H1 / m_emaSlopeStdDev; // Normalized momentum
    
    // RSI & MACD Metrics
    profile.rsiValue = m_rsiH1;
    profile.macdMain = m_macdMain;
    profile.macdSignal = m_macdSignal;
    profile.macdHistogram = m_macdHistogram;
    profile.rsiSlope = m_rsiH1 - 50.0; // Simple slope estimation
    profile.hasBullishDivergence = m_hasBullishDivergence;
    profile.hasBearishDivergence = m_hasBearishDivergence;
    
    // Volume Metrics
    profile.volumeCurrent = m_volumeCurrent;
    profile.volumeSMA20 = m_volumeSMA20;
    profile.volumeSpike = m_hasVolumeSpike;
    profile.volumeDeclining = DetectVolumeDeclining();
    profile.volumeForce = (IsTrendUp() ? 1.0 : -1.0) * (m_volumeCurrent / m_volumeSMA20);
    profile.buyingPressure = (m_di_plus_h1 / (m_di_plus_h1 + m_di_minus_h1)) * (m_volumeCurrent / m_volumeSMA20);
    profile.sellingPressure = (m_di_minus_h1 / (m_di_plus_h1 + m_di_minus_h1)) * (m_volumeCurrent / m_volumeSMA20);
    
    // Session Information
    profile.currentSession = m_currentSession;
    profile.isSessionStart = m_isSessionStart;
    profile.isSessionEnd = m_isSessionEnd;
    
    // Market Phase
    profile.marketPhase = m_marketPhase;
    profile.phaseCompletion = 0.5; // Default moderate completion
    
    // Market Characteristics
    profile.isTrending = m_isTrending;
    profile.isSideway = m_isSideway;
    profile.isVolatile = m_isVolatile;
    profile.isRangebound = m_isRangebound;
    profile.isOverbought = m_isOverbought;
    profile.isOversold = m_isOversold;
    profile.isInBreakout = m_isInBreakout;
    profile.isInPullback = m_isInPullback;
    profile.isInFakeout = m_isInFakeout;
    
    // Regime Transition Data
    profile.isTransitioning = m_isTransitioning;
    profile.regimeConfidence = m_regimeConfidence;
    profile.transitionProgress = m_regimeTransitionScore;
    profile.regimeAge = m_regimeAge;
    profile.regime = m_regime;
    
    // Key Price Levels
    profile.recentSwingHigh = m_recentSwingHigh;
    profile.recentSwingLow = m_recentSwingLow;
    profile.keyResistance = m_keyResistanceLevel;
    profile.keySupport = m_keySupportLevel;
    profile.valueAreaHigh = m_valueAreaHigh;
    profile.valueAreaLow = m_valueAreaLow;
    profile.pointOfControl = m_pointOfControl;
    
    // Institutional Metrics
    profile.smartMoneyIndex = m_smartMoneyIndex;
    profile.liquidityAbove = m_liquidityAbove;
    profile.liquidityBelow = m_liquidityBelow;
    profile.cumulativeDelta = m_cumulativeDelta;
    
    // Market Internals
    profile.marketBreadth = 0.5; // Default neutral value
    profile.marketSentiment = (m_rsiH1 - 50.0) / 50.0; // Simple sentiment based on RSI
    profile.correlationIndex = m_correlationIndex;
    profile.marketEfficiency = m_marketEfficiencyRatio;
    
    // Multi-Timeframe Consensus 
    profile.mtfTrendScore = m_mtfTrendScore;
    profile.mtfVolatilityScore = m_mtfVolatilityScore;
    profile.mtfMomentumScore = m_mtfMomentumScore;
    
    // Entry Quality Assessment
    profile.trendFollowQuality = m_trendFollowingQuality;
    profile.counterTrendQuality = m_counterTrendQuality;
    profile.rangeTradingQuality = m_rangeQuality;
    profile.breakoutQuality = m_breakoutQuality;
    
    return profile;
}

//+------------------------------------------------------------------+
//| Export key levels to string                                      |
//+------------------------------------------------------------------+
string CMarketProfile::ExportKeyLevelsToString()
{
    string result = "=== KEY PRICE LEVELS ===\n";
    
    // Basic Support/Resistance
    result += "Support: " + DoubleToString(m_keySupportLevel, _Digits) + "\n";
    result += "Resistance: " + DoubleToString(m_keyResistanceLevel, _Digits) + "\n";
    
    // Swing Points
    result += "Swing High: " + DoubleToString(m_recentSwingHigh, _Digits) + "\n";
    result += "Swing Low: " + DoubleToString(m_recentSwingLow, _Digits) + "\n";
    
    // Volume Profile
    if (m_valueAreaHigh > 0 && m_valueAreaLow > 0) {
        result += "Value Area High: " + DoubleToString(m_valueAreaHigh, _Digits) + "\n";
        result += "Point of Control: " + DoubleToString(m_pointOfControl, _Digits) + "\n";
        result += "Value Area Low: " + DoubleToString(m_valueAreaLow, _Digits) + "\n";
    }
    
    // Order Blocks
    if (m_bullishOBHigh > 0 && m_bullishOBLow > 0) {
        result += "Bullish Order Block: " + DoubleToString(m_bullishOBLow, _Digits) + 
                 " - " + DoubleToString(m_bullishOBHigh, _Digits) + "\n";
    }
    
    if (m_bearishOBHigh > 0 && m_bearishOBLow > 0) {
        result += "Bearish Order Block: " + DoubleToString(m_bearishOBLow, _Digits) + 
                 " - " + DoubleToString(m_bearishOBHigh, _Digits) + "\n";
    }
    
    // Liquidity Levels
    if (m_buyLiquidityCount > 0) {
        result += "Buy Liquidity Levels (" + IntegerToString(m_buyLiquidityCount) + "):\n";
        for (int i = 0; i < m_buyLiquidityCount; i++) {
            result += "  " + DoubleToString(m_buyLiquidityLevels[i].price, _Digits) + 
                     " (Strength: " + DoubleToString(m_buyLiquidityLevels[i].strength, 2) + ")\n";
        }
    }
    
    if (m_sellLiquidityCount > 0) {
        result += "Sell Liquidity Levels (" + IntegerToString(m_sellLiquidityCount) + "):\n";
        for (int i = 0; i < m_sellLiquidityCount; i++) {
            result += "  " + DoubleToString(m_sellLiquidityLevels[i].price, _Digits) + 
                     " (Strength: " + DoubleToString(m_sellLiquidityLevels[i].strength, 2) + ")\n";
        }
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Create visual representation of market profile                   |
//+------------------------------------------------------------------+
string CMarketProfile::CreateVisualProfile()
{
    string visual = "=== VISUAL MARKET PROFILE ===\n";
    
    // Check if volume profile data is available
    if (m_volumeProfileSize <= 0) {
        visual += "Volume profile data not available\n";
        return visual;
    }
    
    // Find maximum volume for scaling
    double maxVolume = 0;
    for (int i = 0; i < m_volumeProfileSize; i++) {
        if (m_volumeProfile[i].volume > maxVolume) {
            maxVolume = m_volumeProfile[i].volume;
        }
    }
    
    if (maxVolume <= 0) {
        visual += "No significant volume data\n";
        return visual;
    }
    
    // Get current price
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return visual + "Error getting current price\n";
    }
    
    double currentPrice = close[0];
    
    // Create visual representation
    for (int i = 0; i < m_volumeProfileSize; i += 5) { // Skip some levels for brevity
        if (m_volumeProfile[i].volume <= 0) continue;
        
        // Calculate bar width
        int barWidth = (int)MathRound(m_volumeProfile[i].volume / maxVolume * 20.0);
        
        string bar = "";
        
        // Add price level
        bar += DoubleToString(m_volumeProfile[i].price, _Digits) + " ";
        
        // Add markers for POC, VAH, VAL
        if (m_volumeProfile[i].isPOC) {
            bar += "[POC] ";
        }
        else if (m_volumeProfile[i].isVAH) {
            bar += "[VAH] ";
        }
        else if (m_volumeProfile[i].isVAL) {
            bar += "[VAL] ";
        }
        else {
            bar += "      ";
        }
        
        // Add current price marker
        if (MathAbs(m_volumeProfile[i].price - currentPrice) < (m_atrH1 * 0.2)) {
            bar += ">> ";
        }
        else {
            bar += "   ";
        }
        
        // Draw volume bar
        for (int j = 0; j < barWidth; j++) {
            bar += "#";
        }
        
        // Add newline
        bar += "\n";
        
        // Add to visual
        visual += bar;
    }
    
    return visual;
}

//+------------------------------------------------------------------+
//| Get detailed liquidity analysis                                  |
//+------------------------------------------------------------------+
string CMarketProfile::GetLiquidityAnalysis()
{
    string analysis = "=== LIQUIDITY ANALYSIS ===\n";
    
    // Get current price
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return analysis + "Error getting current price\n";
    }
    
    double currentPrice = close[0];
    
    // Overall liquidity assessment
    analysis += "Liquidity Above: " + DoubleToString(m_liquidityAbove, 2) + "\n";
    analysis += "Liquidity Below: " + DoubleToString(m_liquidityBelow, 2) + "\n";
    
    // Liquidity imbalance
    double totalLiquidity = m_liquidityAbove + m_liquidityBelow;
    if (totalLiquidity > 0) {
        double imbalanceRatio = m_liquidityAbove / totalLiquidity;
        
        analysis += "Liquidity Imbalance: ";
        if (imbalanceRatio > 0.7) {
            analysis += "Strong upside imbalance (" + DoubleToString(imbalanceRatio * 100, 1) + "% above)\n";
        }
        else if (imbalanceRatio < 0.3) {
            analysis += "Strong downside imbalance (" + DoubleToString((1.0 - imbalanceRatio) * 100, 1) + "% below)\n";
        }
        else {
            analysis += "Balanced liquidity distribution\n";
        }
    }
    
    // Buy-side liquidity details
    if (m_buyLiquidityCount > 0) {
        analysis += "\nBuy-Side Liquidity Levels:\n";
        
        for (int i = 0; i < m_buyLiquidityCount; i++) {
            double distance = (currentPrice - m_buyLiquidityLevels[i].price) / m_atrH1;
            string status = m_buyLiquidityLevels[i].isSwept ? "SWEPT" : "ACTIVE";
            
            analysis += DoubleToString(m_buyLiquidityLevels[i].price, _Digits) + 
                       " (Strength: " + DoubleToString(m_buyLiquidityLevels[i].strength, 2) + 
                       ", Distance: " + DoubleToString(MathAbs(distance), 1) + " ATR, Status: " + status + ")\n";
        }
    }
    
    // Sell-side liquidity details
    if (m_sellLiquidityCount > 0) {
        analysis += "\nSell-Side Liquidity Levels:\n";
        
        for (int i = 0; i < m_sellLiquidityCount; i++) {
            double distance = (m_sellLiquidityLevels[i].price - currentPrice) / m_atrH1;
            string status = m_sellLiquidityLevels[i].isSwept ? "SWEPT" : "ACTIVE";
            
            analysis += DoubleToString(m_sellLiquidityLevels[i].price, _Digits) + 
                       " (Strength: " + DoubleToString(m_sellLiquidityLevels[i].strength, 2) + 
                       ", Distance: " + DoubleToString(MathAbs(distance), 1) + " ATR, Status: " + status + ")\n";
        }
    }
    
    // Smart money assessment
    analysis += "\nSmart Money Index: " + DoubleToString(m_smartMoneyIndex, 2) + "\n";
    
    // Order blocks
    if (m_bullishOBHigh > 0 && m_bullishOBLow > 0) {
        double distanceToOB = (currentPrice - m_bullishOBHigh) / m_atrH1;
        analysis += "Bullish Order Block: " + DoubleToString(m_bullishOBLow, _Digits) + 
                   " - " + DoubleToString(m_bullishOBHigh, _Digits) + 
                   " (Distance: " + DoubleToString(MathAbs(distanceToOB), 1) + " ATR)\n";
    }
    
    if (m_bearishOBHigh > 0 && m_bearishOBLow > 0) {
        double distanceToOB = (m_bearishOBLow - currentPrice) / m_atrH1;
        analysis += "Bearish Order Block: " + DoubleToString(m_bearishOBLow, _Digits) + 
                   " - " + DoubleToString(m_bearishOBHigh, _Digits) + 
                   " (Distance: " + DoubleToString(MathAbs(distanceToOB), 1) + " ATR)\n";
    }
    
    // Volume profile assessment
    if (m_valueAreaHigh > 0 && m_valueAreaLow > 0) {
        analysis += "\nVolume Profile Analysis:\n";
        analysis += "Value Area: " + DoubleToString(m_valueAreaLow, _Digits) + 
                   " - " + DoubleToString(m_valueAreaHigh, _Digits) + "\n";
        
        if (currentPrice > m_valueAreaHigh) {
            analysis += "Price is above Value Area (potential resistance zone)\n";
        }
        else if (currentPrice < m_valueAreaLow) {
            analysis += "Price is below Value Area (potential support zone)\n";
        }
        else {
            analysis += "Price is within Value Area (balanced zone)\n";
        }
    }
    
    // Market efficiency
    analysis += "\nMarket Efficiency Ratio: " + DoubleToString(m_marketEfficiencyRatio, 2) + 
               (m_marketEfficiencyRatio > 0.7 ? " (Efficient market)" : 
                (m_marketEfficiencyRatio < 0.3 ? " (Inefficient market)" : " (Balanced efficiency)")) + "\n";
    
    return analysis;
}

//+------------------------------------------------------------------+
//| Get institutional activity report                                |
//+------------------------------------------------------------------+
string CMarketProfile::GetInstitutionalReport()
{
    string report = "=== INSTITUTIONAL ACTIVITY REPORT ===\n";
    
    // Smart money index
    report += "Smart Money Index: " + DoubleToString(m_smartMoneyIndex, 2) + 
             (m_smartMoneyIndex > 0.7 ? " (High institutional activity)" : 
              (m_smartMoneyIndex < 0.3 ? " (Low institutional activity)" : " (Moderate institutional activity)")) + "\n";
    
    // Order blocks
    report += "\nOrder Blocks:\n";
    
    if (m_bullishOBHigh > 0 && m_bullishOBLow > 0) {
        report += "Bullish OB: " + DoubleToString(m_bullishOBLow, _Digits) + 
                " - " + DoubleToString(m_bullishOBHigh, _Digits) + "\n";
    }
    else {
        report += "No recent bullish order blocks detected\n";
    }
    
    if (m_bearishOBHigh > 0 && m_bearishOBLow > 0) {
        report += "Bearish OB: " + DoubleToString(m_bearishOBLow, _Digits) + 
                " - " + DoubleToString(m_bearishOBHigh, _Digits) + "\n";
    }
    else {
        report += "No recent bearish order blocks detected\n";
    }
    
    // Fair value gaps
    report += "\nFair Value Gaps:\n";
    
    if (m_fvgCount > 0) {
        for (int i = 0; i < m_fvgCount; i++) {
            report += "FVG #" + IntegerToString(i+1) + ": " + 
                     DoubleToString(m_fairValueGap[i][1], _Digits) + " - " + 
                     DoubleToString(m_fairValueGap[i][0], _Digits) + 
                     " (Age: " + IntegerToString((int)m_fairValueGap[i][2]) + " bars)\n";
        }
    }
    else {
        report += "No fair value gaps detected\n";
    }
    
    // Structure breaks
    report += "\nStructure Analysis:\n";
    
    if (m_hasBreakOfStructure) {
        report += "Break of structure detected - potential institutional interest\n";
    }
    
    if (m_hasChangeOfCharacter) {
        report += "Change of character detected - potential shift in institutional positioning\n";
    }
    
    // Liquidity analysis
    report += "\nLiquidity Analysis:\n";
    report += "Liquidity Above: " + DoubleToString(m_liquidityAbove, 2) + "\n";
    report += "Liquidity Below: " + DoubleToString(m_liquidityBelow, 2) + "\n";
    
    // Institutional patterns
    report += "\nInstitutional Patterns:\n";
    
    if (m_isInBreakout) {
        report += "Breakout pattern detected\n";
    }
    
    if (m_isInFakeout) {
        report += "Fakeout pattern detected - potential stop hunting\n";
    }
    
    if (m_isInPullback) {
        report += "Pullback pattern detected - potential accumulation/distribution\n";
    }
    
    // Cumulative delta
    report += "\nCumulative Delta: " + DoubleToString(m_cumulativeDelta, 2) + 
             (m_cumulativeDelta > 500 ? " (Strong buying pressure)" : 
              (m_cumulativeDelta < -500 ? " (Strong selling pressure)" : " (Balanced flow)")) + "\n";
    
    return report;
}

//+------------------------------------------------------------------+
//| Create comprehensive session analysis                            |
//+------------------------------------------------------------------+
string CMarketProfile::CreateSessionAnalysis(bool includeStats = false)
{
    string analysis = "=== SESSION ANALYSIS ===\n";
    
    // Current session
    analysis += "Current Session: " + EnumToString(m_currentSession) + 
               (m_isSessionStart ? " (Start)" : "") + 
               (m_isSessionEnd ? " (End)" : "") + "\n";
    
    // Session characteristics
    analysis += "\nSession Characteristics:\n";
    
    switch (m_currentSession) {
        case SESSION_ASIAN:
            analysis += "Asian Session: Typically lower volatility, ranging conditions.\n";
            analysis += "Key currencies: JPY, AUD, NZD.\n";
            
            if (m_isVolatile) {
                analysis += "Current session has unusually high volatility.\n";
            }
            
            if (m_isTrending) {
                analysis += "Current session has unusually strong trend.\n";
            }
            break;
            
        case SESSION_EUROPEAN:
            analysis += "European Session: Increasing volatility, trending potential.\n";
            analysis += "Key currencies: EUR, GBP, CHF.\n";
            
            if (!m_isVolatile && !m_isTrending) {
                analysis += "Current session has unusually low activity.\n";
            }
            break;
            
        case SESSION_AMERICAN:
            analysis += "American Session: Often high volatility, strong directional moves.\n";
            analysis += "Key currencies: USD, CAD.\n";
            
            if (!m_isVolatile && !m_isTrending) {
                analysis += "Current session has unusually low activity.\n";
            }
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            analysis += "European-American Overlap: Highest liquidity, potential for breakouts.\n";
            analysis += "All major currencies active.\n";
            
            if (!m_isVolatile) {
                analysis += "Current overlap has unusually low volatility.\n";
            }
            break;
            
        case SESSION_CLOSING:
            analysis += "Closing Session: Decreasing volatility, potential for reversals.\n";
            analysis += "Often sees position squaring and profit-taking.\n";
            
            if (m_isVolatile) {
                analysis += "Current closing session has unusually high volatility.\n";
            }
            break;
            
        default:
            analysis += "Unknown session type.\n";
            break;
    }
    
    // Market conditions in this session
    analysis += "\nCurrent Market Conditions:\n";
    analysis += "ATR Ratio: " + DoubleToString(m_atrRatio, 2) + 
               (m_atrRatio > 1.5 ? " (High volatility)" : 
                (m_atrRatio < 0.7 ? " (Low volatility)" : " (Normal volatility)")) + "\n";
    
    analysis += "ADX (H4): " + DoubleToString(m_adxH4, 1) + 
               (m_adxH4 > 25 ? " (Strong trend)" : 
                (m_adxH4 < 15 ? " (Weak/no trend)" : " (Moderate trend)")) + "\n";
    
    if (m_isInBreakout) {
        analysis += "Breakout detected during this session.\n";
    }
    
    if (m_hasVolumeSpike) {
        analysis += "Volume spike detected during this session.\n";
    }
    
    // Trading recommendations for this session
    analysis += "\nTrading Considerations for Current Session:\n";
    
    // Ideal trade setups for each session
    switch (m_currentSession) {
        case SESSION_ASIAN:
            if (m_isRangebound) {
                analysis += "- Range trading setups favorable\n";
                analysis += "- Consider fade trades at range extremes\n";
            }
            else if (m_isTrending) {
                analysis += "- Unusual trending conditions - consider trend following with tight stops\n";
            }
            
            if (m_isSessionEnd) {
                analysis += "- Consider positioning for European session momentum\n";
            }
            break;
            
        case SESSION_EUROPEAN:
            if (m_isTrending) {
                analysis += "- Trend following setups favorable\n";
                analysis += "- Watch for breakouts from Asian ranges\n";
            }
            else if (m_isRangebound) {
                analysis += "- Unusual ranging conditions - consider range trading with wider stops\n";
            }
            
            if (m_isSessionEnd) {
                analysis += "- Prepare for potential volatility increase during EU-US overlap\n";
            }
            break;
            
        case SESSION_AMERICAN:
            if (m_isTrending) {
                analysis += "- Trend following and momentum setups favorable\n";
                analysis += "- Watch for continuation of European session trends\n";
            }
            
            if (m_isSessionEnd) {
                analysis += "- Be cautious of potential reversals during closing hours\n";
            }
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            analysis += "- Highest liquidity period - ideal for executing planned trades\n";
            analysis += "- Watch for breakouts and strong momentum moves\n";
            
            if (m_isVolatile) {
                analysis += "- Consider reducing position size due to high volatility\n";
            }
            break;
            
        case SESSION_CLOSING:
            analysis += "- Reduced liquidity - wider spreads possible\n";
            analysis += "- Consider profit-taking on intraday positions\n";
            
            if (m_isTrending) {
                analysis += "- Unusual trend strength for closing session - potential continuation\n";
            }
            break;
    }
    
    // Include additional statistics if requested
    if (includeStats) {
        analysis += "\n=== ADDITIONAL SESSION STATISTICS ===\n";
        
        // Volume comparison
        analysis += "Volume: Current=" + DoubleToString(m_volumeCurrent, 0) + 
                   ", Average=" + DoubleToString(m_volumeSMA20, 0) + 
                   " (" + DoubleToString(m_volumeCurrent/m_volumeSMA20*100, 1) + "% of avg)\n";
        
        // Volatility comparison
        analysis += "Volatility (ATR): Current=" + DoubleToString(m_atrH1, _Digits) + 
                   ", Daily=" + DoubleToString(m_atrD1, _Digits) + 
                   " (" + DoubleToString(m_atrH1/m_atrD1*100, 1) + "% of daily)\n";
        
        // Momentum comparison
        analysis += "Momentum (MACD): " + DoubleToString(m_macdHistogram, 6) + 
                   (m_macdHistogram > 0 ? " (Positive)" : " (Negative)") + 
                   (m_macdHistogram > m_macdHistogramPrev ? " (Increasing)" : " (Decreasing)") + "\n";
        
        // Session patterns
        analysis += "\nTypical Patterns for " + EnumToString(m_currentSession) + ":\n";
        
        switch (m_currentSession) {
            case SESSION_ASIAN:
                analysis += "- Often consolidates European/American moves\n";
                analysis += "- Range typically 30-50% of daily range\n";
                analysis += "- Key reversal zone: 03:00-04:00 GMT\n";
                break;
                
            case SESSION_EUROPEAN:
                analysis += "- Often sets daily direction\n";
                analysis += "- Range typically 60-80% of daily range\n";
                analysis += "- Key volatility time: 08:30 GMT (economic releases)\n";
                break;
                
            case SESSION_AMERICAN:
                analysis += "- Often extends or reverses European moves\n";
                analysis += "- Range typically 70-90% of daily range\n";
                analysis += "- Key volatility times: 13:30, 15:00 GMT (economic releases)\n";
                break;
                
            case SESSION_EUROPEAN_AMERICAN:
                analysis += "- Highest liquidity period of day\n";
                analysis += "- Often sees largest price moves\n";
                analysis += "- Institutional activity most pronounced\n";
                break;
                
            case SESSION_CLOSING:
                analysis += "- Often consolidates or partially reverses day's move\n";
                analysis += "- Range typically 20-40% of daily range\n";
                analysis += "- Position squaring common\n";
                break;
        }
    }
    
    return analysis;
}

//+------------------------------------------------------------------+
//| Export market profile to JSON                                    |
//+------------------------------------------------------------------+
string CMarketProfile::ExportMarketProfileToJSON()
{
    string json = "{\n";
    
    // Basic info
    json += "  \"symbol\": \"" + m_symbol + "\",\n";
    json += "  \"timeframe\": \"" + EnumToString(m_timeframe) + "\",\n";
    json += "  \"timestamp\": " + IntegerToString((int)TimeCurrent()) + ",\n";
    
    // Market regime info
    json += "  \"regime\": {\n";
    json += "    \"type\": \"" + EnumToString(m_regime) + "\",\n";
    json += "    \"confidence\": " + DoubleToString(m_regimeConfidence, 2) + ",\n";
    json += "    \"age\": " + IntegerToString(m_regimeAge) + ",\n";
    json += "    \"isTransitioning\": " + (m_isTransitioning ? "true" : "false") + "\n";
    json += "  },\n";
    
    // Market state info
    json += "  \"marketState\": {\n";
    json += "    \"isTrending\": " + (m_isTrending ? "true" : "false") + ",\n";
    json += "    \"isSideway\": " + (m_isSideway ? "true" : "false") + ",\n";
    json += "    \"isVolatile\": " + (m_isVolatile ? "true" : "false") + ",\n";
    json += "    \"isRangebound\": " + (m_isRangebound ? "true" : "false") + ",\n";
    json += "    \"isInBreakout\": " + (m_isInBreakout ? "true" : "false") + ",\n";
    json += "    \"isInPullback\": " + (m_isInPullback ? "true" : "false") + ",\n";
    json += "    \"isInFakeout\": " + (m_isInFakeout ? "true" : "false") + ",\n";
    json += "    \"isOverbought\": " + (m_isOverbought ? "true" : "false") + ",\n";
    json += "    \"isOversold\": " + (m_isOversold ? "true" : "false") + "\n";
    json += "  },\n";
    
    // Indicator values
    json += "  \"indicators\": {\n";
    json += "    \"adxH4\": " + DoubleToString(m_adxH4, 1) + ",\n";
    json += "    \"atrRatio\": " + DoubleToString(m_atrRatio, 2) + ",\n";
    json += "    \"emaAlignment\": " + DoubleToString(m_emaAlignment, 2) + ",\n";
    json += "    \"rsi\": " + DoubleToString(m_rsiH1, 1) + ",\n";
    json += "    \"macdHistogram\": " + DoubleToString(m_macdHistogram, 6) + ",\n";
    json += "    \"marketEfficiencyRatio\": " + DoubleToString(m_marketEfficiencyRatio, 2) + "\n";
    json += "  },\n";
    
    // Session info
    json += "  \"session\": {\n";
    json += "    \"current\": \"" + EnumToString(m_currentSession) + "\",\n";
    json += "    \"isStart\": " + (m_isSessionStart ? "true" : "false") + ",\n";
    json += "    \"isEnd\": " + (m_isSessionEnd ? "true" : "false") + "\n";
    json += "  },\n";
    
    // Key levels
    json += "  \"keyLevels\": {\n";
    json += "    \"support\": " + DoubleToString(m_keySupportLevel, _Digits) + ",\n";
    json += "    \"resistance\": " + DoubleToString(m_keyResistanceLevel, _Digits) + ",\n";
    json += "    \"swingHigh\": " + DoubleToString(m_recentSwingHigh, _Digits) + ",\n";
    json += "    \"swingLow\": " + DoubleToString(m_recentSwingLow, _Digits) + ",\n";
    json += "    \"valueAreaHigh\": " + DoubleToString(m_valueAreaHigh, _Digits) + ",\n";
    json += "    \"valueAreaLow\": " + DoubleToString(m_valueAreaLow, _Digits) + ",\n";
    json += "    \"pointOfControl\": " + DoubleToString(m_pointOfControl, _Digits) + "\n";
    json += "  },\n";
    
    // Trading quality scores
    json += "  \"tradingQuality\": {\n";
    json += "    \"trendFollowing\": " + DoubleToString(m_trendFollowingQuality, 2) + ",\n";
    json += "    \"counterTrend\": " + DoubleToString(m_counterTrendQuality, 2) + ",\n";
    json += "    \"breakout\": " + DoubleToString(m_breakoutQuality, 2) + ",\n";
    json += "    \"range\": " + DoubleToString(m_rangeQuality, 2) + "\n";
    json += "  },\n";
    
    // Multi-timeframe scores
    json += "  \"mtfScores\": {\n";
    json += "    \"trend\": " + DoubleToString(m_mtfTrendScore, 2) + ",\n";
    json += "    \"momentum\": " + DoubleToString(m_mtfMomentumScore, 2) + ",\n";
    json += "    \"volatility\": " + DoubleToString(m_mtfVolatilityScore, 2) + "\n";
    json += "  },\n";
    
    // Institutional metrics
    json += "  \"institutional\": {\n";
    json += "    \"smartMoneyIndex\": " + DoubleToString(m_smartMoneyIndex, 2) + ",\n";
    json += "    \"liquidityAbove\": " + DoubleToString(m_liquidityAbove, 2) + ",\n";
    json += "    \"liquidityBelow\": " + DoubleToString(m_liquidityBelow, 2) + ",\n";
    json += "    \"cumulativeDelta\": " + DoubleToString(m_cumulativeDelta, 2) + ",\n";
    json += "    \"hasBreakOfStructure\": " + (m_hasBreakOfStructure ? "true" : "false") + ",\n";
    json += "    \"hasChangeOfCharacter\": " + (m_hasChangeOfCharacter ? "true" : "false") + "\n";
    json += "  }\n";
    
    json += "}";
    
    return json;
}

//+------------------------------------------------------------------+
//| Check for bullish divergence                                     |
//+------------------------------------------------------------------+
bool CMarketProfile::HasBullishDivergence() const
{
    return m_hasBullishDivergence;
}

//+------------------------------------------------------------------+
//| Check for bearish divergence                                     |
//+------------------------------------------------------------------+
bool CMarketProfile::HasBearishDivergence() const
{
    return m_hasBearishDivergence;
}

//+------------------------------------------------------------------+
//| Get ATR acceleration                                             |
//+------------------------------------------------------------------+
double CMarketProfile::GetATRAcceleration() const
{
    // Calculate ATR acceleration if needed
    if (m_atrSlope > 0) {
        return CalculateATRAcceleration();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Check if price is near EMA                                       |
//+------------------------------------------------------------------+
bool CMarketProfile::IsPriceNearEma(int emaPeriod, bool isLong, double maxDistance)
{
    // Get current price
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        return false;
    }
    
    double currentPrice = close[0];
    
    // Determine which EMA handle to use
    int emaHandle = INVALID_HANDLE;
    
    switch (emaPeriod) {
        case 34:
            emaHandle = m_handleEMA34_H1;
            break;
        case 89:
            emaHandle = m_handleEMA89_H1;
            break;
        case 200:
            emaHandle = m_handleEMA200_H1;
            break;
        default:
            // Unsupported period
            return false;
    }
    
    // Get EMA value
    double emaBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    
    if (!SafeCopyBuffer(emaHandle, 0, 0, 1, emaBuffer)) {
        return false;
    }
    
    // Calculate distance to EMA
    double emaValue = emaBuffer[0];
    double distance = (currentPrice - emaValue) / m_atrH1;
    
    // If maxDistance not specified, use default value
    if (maxDistance <= 0) {
        maxDistance = 0.5; // Default maximum distance is 0.5 ATR
    }
    
    // Check if price is near EMA
    if (isLong) {
        // For long entries, price should be above EMA but not too far
        return (distance > 0 && distance <= maxDistance);
    }
    else {
        // For short entries, price should be below EMA but not too far
        return (distance < 0 && MathAbs(distance) <= maxDistance);
    }
}

//+------------------------------------------------------------------+
//| Light update of market profile                                   |
//+------------------------------------------------------------------+
bool CMarketProfile::LightUpdate()
{
    if (!m_isInitialized) {
        if (m_logger) m_logger.LogError("LightUpdate: MarketProfile not initialized");
        return false;
    }
    
    // Check if full update needed
    datetime currentTime = TimeCurrent();
    
    // If no full update has been performed yet or if it's been too long
    if (m_lastFullUpdateTime == 0 || (currentTime - m_lastFullUpdateTime) > 900) { // 15 minutes
        return Update(); // Perform full update
    }
    
    // Get current price 
    double close[];
    ArraySetAsSeries(close, true);
    
    if (CopyClose(m_symbol, PERIOD_CURRENT, 0, 1, close) <= 0) {
        if (m_logger) m_logger.LogWarning("LightUpdate: Failed to copy current price");
        return false;
    }
    
    // Update proximity to key levels
    double currentPrice = close[0];
    
    // Check if we're in a breakout/pullback situation
    if (m_keyResistanceLevel > 0 && currentPrice > m_keyResistanceLevel) {
        m_isInBreakout = true;
    }
    else if (m_keySupportLevel > 0 && currentPrice < m_keySupportLevel) {
        m_isInBreakout = true;
    }
    else {
        m_isInBreakout = false;
    }
    
    // Update last update time
    m_lastUpdateTime = currentTime;
    
    return true;
}

//+------------------------------------------------------------------+
//| Detect price action patterns                                     |
//+------------------------------------------------------------------+
bool CMarketProfile::DetectPriceActionPatterns()
{
    // Reset pattern flags
    m_hasEngulfing = false;
    m_hasDoji = false;
    m_hasPinbar = false;
    m_hasInsideBar = false;
    
    // Get OHLC data
    double open[], high[], low[], close[];
    ArraySetAsSeries(open, true);
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if (CopyOpen(m_symbol, PERIOD_H1, 0, 3, open) <= 0 ||
        CopyHigh(m_symbol, PERIOD_H1, 0, 3, high) <= 0 ||
        CopyLow(m_symbol, PERIOD_H1, 0, 3, low) <= 0 ||
        CopyClose(m_symbol, PERIOD_H1, 0, 3, close) <= 0) {
        return false;
    }
    
    // Calculate bar sizes
    double bodySize1 = MathAbs(close[1] - open[1]);
    double bodySize2 = MathAbs(close[2] - open[2]);
    double highLow1 = high[1] - low[1];
    double highLow2 = high[2] - low[2];
    
    // Detect engulfing pattern
    if (bodySize1 > bodySize2) {
        // Bullish engulfing
        if (close[1] > open[1] && close[2] < open[2] &&
            open[1] < close[2] && close[1] > open[2]) {
            m_hasEngulfing = true;
        }
        // Bearish engulfing
        else if (close[1] < open[1] && close[2] > open[2] &&
                open[1] > close[2] && close[1] < open[2]) {
            m_hasEngulfing = true;
        }
    }
    
    // Detect doji
    if (bodySize1 < highLow1 * 0.1) {
        m_hasDoji = true;
    }
    
    // Detect pinbar
    double upperWick = high[1] - MathMax(open[1], close[1]);
    double lowerWick = MathMin(open[1], close[1]) - low[1];
    
    // Bullish pinbar (lower wick at least 2x body size and 2x upper wick)
    if (lowerWick > bodySize1 * 2 && lowerWick > upperWick * 2) {
        m_hasPinbar = true;
    }
    // Bearish pinbar (upper wick at least 2x body size and 2x lower wick)
    else if (upperWick > bodySize1 * 2 && upperWick > lowerWick * 2) {
        m_hasPinbar = true;
    }
    
    // Detect inside bar
    if (high[1] < high[2] && low[1] > low[2]) {
        m_hasInsideBar = true;
    }
    
    return (m_hasEngulfing || m_hasDoji || m_hasPinbar || m_hasInsideBar);
}

//+------------------------------------------------------------------+
//| Calculate EMA slope statistics                                    |
//+------------------------------------------------------------------+
void CMarketProfile::CalculateEMASlopeStatistics()
{
    double ema34[];
    ArraySetAsSeries(ema34, true);
    
    if (!SafeCopyBuffer(m_handleEMA34_H1, 0, 0, 20, ema34)) {
        return;
    }
    
    // Calculate slopes for the last 15 periods
    double slopes[15];
    for (int i = 0; i < 15; i++) {
        slopes[i] = ema34[i] - ema34[i+1];
        
        // Normalize by ATR
        if (m_atrH1 > 0) {
            slopes[i] = slopes[i] / m_atrH1;
        }
    }
    
    // Calculate average slope
    double sum = 0;
    for (int i = 0; i < 15; i++) {
        sum += slopes[i];
    }
    m_emaSlopeAvg = sum / 15;
    
    // Calculate standard deviation
    double sumSq = 0;
    for (int i = 0; i < 15; i++) {
        sumSq += (slopes[i] - m_emaSlopeAvg) * (slopes[i] - m_emaSlopeAvg);
    }
    m_emaSlopeStdDev = MathSqrt(sumSq / 15);
}

//+------------------------------------------------------------------+
//| END OF CLASS IMPLEMENTATION                                      |
//+------------------------------------------------------------------+
#endif // MARKET_PROFILE_MQH