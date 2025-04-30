//+------------------------------------------------------------------+
//| Structs.mqh - Data structures for SonicR PropFirm EA              |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include enums needed for these structs
#include "Enums.mqh"

//+------------------------------------------------------------------+
//| TradeRecord - Structure to track trade information                |
//+------------------------------------------------------------------+
struct TradeRecord {
    ulong         ticket;             // Trade ticket
    datetime      openTime;           // Open time
    datetime      closeTime;          // Close time (if closed)
    string        symbol;             // Symbol
    int           magicNumber;        // Magic number
    double        lots;               // Lot size
    double        openPrice;          // Open price
    double        closePrice;         // Close price (if closed)
    double        stopLoss;           // Current SL
    double        takeProfit;         // Current TP
    double        initialStopLoss;    // Initial SL
    double        initialTakeProfit;  // Initial TP
    double        commission;         // Commission paid
    double        swap;               // Swap charges
    double        profit;             // Current profit
    double        riskMoney;          // Amount risked
    double        riskPercent;        // Percent of account risked
    double        initialRisk;        // Initial risk in price units
    ENUM_POSITION_TYPE positionType;  // Position type (buy/sell)
    ENUM_TRADE_STATUS status;         // Trade status
    bool          breakEvenSet;       // Whether breakeven was set
    bool          partialClosed;      // Whether partial close was done
    bool          trailingActive;     // Whether trailing stop is active
    double        initialLots;        // Initial lots before partial close
    bool          isValid;            // Flag for array management

    // Constructor
    TradeRecord() {
        ticket = 0;
        openTime = 0;
        closeTime = 0;
        symbol = "";
        magicNumber = 0;
        lots = 0.0;
        openPrice = 0.0;
        closePrice = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        initialStopLoss = 0.0;
        initialTakeProfit = 0.0;
        commission = 0.0;
        swap = 0.0;
        profit = 0.0;
        riskMoney = 0.0;
        riskPercent = 0.0;
        initialRisk = 0.0;
        positionType = POSITION_TYPE_BUY;
        status = TRADE_STATUS_NEW;
        breakEvenSet = false;
        partialClosed = false;
        trailingActive = false;
        initialLots = 0.0;
        isValid = false;
    }
};

//+------------------------------------------------------------------+
//| TradeCloseRecord - Structure to track closed trade information    |
//+------------------------------------------------------------------+
struct TradeCloseRecord {
    ulong         ticket;             // Original trade ticket
    datetime      openTime;           // Open time
    datetime      closeTime;          // Close time
    string        symbol;             // Symbol
    int           magicNumber;        // Magic number
    double        lots;               // Lot size
    double        openPrice;          // Open price
    double        closePrice;         // Close price
    double        stopLoss;           // Final SL
    double        takeProfit;         // Final TP
    double        riskMoney;          // Amount risked
    double        profit;             // P/L including commission and swap
    double        commission;         // Commission paid
    double        swap;               // Swap charges
    double        pips;               // Profit in pips
    double        rMultiple;          // Profit as R multiple
    ENUM_POSITION_TYPE positionType;  // Position type (buy/sell)
    ENUM_EXIT_REASON exitReason;      // Reason for exit
    int           holdTimeBars;       // Hold time in bars
    double        maxAdverseExcursion;// Maximum adverse excursion (MAE)
    double        maxFavorableExcursion;// Maximum favorable excursion (MFE)
};

//+------------------------------------------------------------------+
//| SRLevel - Structure to store support/resistance level information |
//+------------------------------------------------------------------+
struct SRLevel {
    double        price;              // Level price
    datetime      time;               // When level was formed/identified
    ENUM_SR_LEVEL_TYPE type;          // Support, resistance or both
    ENUM_SR_SOURCE source;            // Source of level
    ENUM_SR_STRENGTH strength;        // Level strength
    int           touchCount;         // Number of times price touched this level
    double        width;              // Width/thickness of the level (in pips)
    bool          active;             // Whether the level is still active
    datetime      lastTouchTime;      // Last time price touched this level
    
    // Constructor
    SRLevel() {
        price = 0.0;
        time = 0;
        type = SR_TYPE_BOTH;
        source = SR_SOURCE_SWING;
        strength = SR_STRENGTH_MEDIUM;
        touchCount = 0;
        width = 0.0;
        active = false;
        lastTouchTime = 0;
    }
    
    // Equality comparison operator
    bool operator==(const SRLevel& other) const {
        return (price == other.price && 
                type == other.type && 
                source == other.source);
    }
    
    // Less than operator for sorting
    bool operator<(const SRLevel& other) const {
        return price < other.price;
    }
};

//+------------------------------------------------------------------+
//| SignalInfo - Structure to store signal information                |
//+------------------------------------------------------------------+
struct SignalInfo {
    ENUM_SIGNAL_TYPE type;            // Signal type
    datetime time;                    // Signal time
    double price;                     // Signal price
    ENUM_SIGNAL_STRENGTH strength;    // Signal strength
    double stopLoss;                  // Suggested stop loss
    double takeProfit;                // Suggested take profit
    string reasons[3];                // Reasons for the signal (confluence factors)
    double riskRewardRatio;           // Risk-reward ratio
    bool confirmed;                   // Whether signal is confirmed
    ENUM_PA_PATTERN patternDetected;  // Price action pattern detected
    bool srConfirmation;              // Whether S/R confirms the signal
    bool momentumConfirmation;        // Whether momentum confirms the signal
    
    // Constructor
    SignalInfo() {
        type = SIGNAL_NONE;
        time = 0;
        price = 0.0;
        strength = SIGNAL_MEDIUM;
        stopLoss = 0.0;
        takeProfit = 0.0;
        for(int i=0; i<3; i++) reasons[i] = "";
        riskRewardRatio = 0.0;
        confirmed = false;
        patternDetected = PA_PATTERN_NONE;
        srConfirmation = false;
        momentumConfirmation = false;
    }
};

//+------------------------------------------------------------------+
//| MarketState - Structure to store current market conditions        |
//+------------------------------------------------------------------+
struct MarketState {
    bool isBullishTrend;              // Bullish trend present
    bool isBearishTrend;              // Bearish trend present
    ENUM_TREND_STRENGTH trendStrength;// Strength of the trend
    double ema34;                     // Current EMA 34 value
    double ema89;                     // Current EMA 89 value
    double ema200;                    // Current EMA 200 value
    double adxValue;                  // Current ADX value
    double atrValue;                  // Current ATR value
    ENUM_MOMENTUM_STATE momentum;     // Current momentum state
    double macdMain;                  // Current MACD main line
    double macdSignal;                // Current MACD signal line
    double macdHistogram;             // Current MACD histogram
    ENUM_TRADING_SESSION currentSession;// Current trading session
    int barsSinceSignal;              // Bars since last signal
    bool isVolatilityHigh;            // Whether volatility is high
    ENUM_NEWS_IMPACT pendingNewsImpact;// Impact of any upcoming news
    
    // Constructor
    MarketState() {
        isBullishTrend = false;
        isBearishTrend = false;
        trendStrength = TREND_STRENGTH_NONE;
        ema34 = 0.0;
        ema89 = 0.0;
        ema200 = 0.0;
        adxValue = 0.0;
        atrValue = 0.0;
        momentum = MOMENTUM_STATE_NONE;
        macdMain = 0.0;
        macdSignal = 0.0;
        macdHistogram = 0.0;
        currentSession = SESSION_OFF_HOURS;
        barsSinceSignal = 0;
        isVolatilityHigh = false;
        pendingNewsImpact = NEWS_IMPACT_NONE;
    }
};

//+------------------------------------------------------------------+
//| PerformanceStats - Structure to store EA performance statistics   |
//+------------------------------------------------------------------+
struct PerformanceStats {
    int totalTrades;                  // Total trades taken
    int winningTrades;                // Number of winning trades
    int losingTrades;                 // Number of losing trades
    int breakEvenTrades;              // Number of breakeven trades
    double winRate;                   // Win rate percentage
    double profitFactor;              // Profit factor
    double totalProfit;               // Total profit in account currency
    double totalLoss;                 // Total loss in account currency
    double maxDrawdown;               // Maximum drawdown
    double maxDrawdownPercent;        // Maximum drawdown as percentage
    double avgWin;                    // Average winning trade
    double avgLoss;                   // Average losing trade
    double largestWin;                // Largest winning trade
    double largestLoss;               // Largest losing trade
    double avgRReward;                // Average R reward
    double avgRRiskRatio;             // Average risk-reward ratio
    int maxConsecutiveWins;           // Maximum consecutive wins
    int maxConsecutiveLosses;         // Maximum consecutive losses
    int currentConsecutiveWins;       // Current consecutive wins
    int currentConsecutiveLosses;     // Current consecutive losses
    double averageHoldTimeMinutes;    // Average hold time in minutes
    double expectancy;                // Expectancy per trade
    
    // Constructor
    PerformanceStats() {
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        breakEvenTrades = 0;
        winRate = 0.0;
        profitFactor = 0.0;
        totalProfit = 0.0;
        totalLoss = 0.0;
        maxDrawdown = 0.0;
        maxDrawdownPercent = 0.0;
        avgWin = 0.0;
        avgLoss = 0.0;
        largestWin = 0.0;
        largestLoss = 0.0;
        avgRReward = 0.0;
        avgRRiskRatio = 0.0;
        maxConsecutiveWins = 0;
        maxConsecutiveLosses = 0;
        currentConsecutiveWins = 0;
        currentConsecutiveLosses = 0;
        averageHoldTimeMinutes = 0.0;
        expectancy = 0.0;
    }
};

//+------------------------------------------------------------------+
//| RiskMetrics - Structure to store risk-related metrics             |
//+------------------------------------------------------------------+
struct RiskMetrics {
    double currentEquity;             // Current equity
    double startDayEquity;            // Equity at start of day
    double startWeekEquity;           // Equity at start of week
    double startMonthEquity;          // Equity at start of month
    double highWaterMark;             // High water mark
    double dailyDrawdown;             // Current daily drawdown
    double totalDrawdown;             // Current total drawdown
    double dailyDrawdownLimit;        // Daily drawdown limit
    double totalDrawdownLimit;        // Total drawdown limit
    int dailyTradesCount;             // Number of trades today
    int dailyTradesLimit;             // Daily trades limit
    int openTradesCount;              // Current open trades
    int concurrentTradesLimit;        // Concurrent trades limit
    double portfolioRisk;             // Current portfolio risk
    double portfolioRiskLimit;        // Portfolio risk limit
    
    // Constructor
    RiskMetrics() {
        currentEquity = 0.0;
        startDayEquity = 0.0;
        startWeekEquity = 0.0;
        startMonthEquity = 0.0;
        highWaterMark = 0.0;
        dailyDrawdown = 0.0;
        totalDrawdown = 0.0;
        dailyDrawdownLimit = 0.0;
        totalDrawdownLimit = 0.0;
        dailyTradesCount = 0;
        dailyTradesLimit = 0;
        openTradesCount = 0;
        concurrentTradesLimit = 0;
        portfolioRisk = 0.0;
        portfolioRiskLimit = 0.0;
    }
};

//+------------------------------------------------------------------+
//| NewsEvent - Structure to store economic news event information    |
//+------------------------------------------------------------------+
struct NewsEvent {
    datetime time;                    // Event time
    string title;                     // Event title
    string currency;                  // Affected currency
    ENUM_NEWS_IMPACT impact;          // Impact level
    string previous;                  // Previous value
    string forecast;                  // Forecasted value
    string actual;                    // Actual value (if released)
    bool isActive;                    // Whether this event is still active
    
    // Constructor
    NewsEvent() {
        time = 0;
        title = "";
        currency = "";
        impact = NEWS_IMPACT_NONE;
        previous = "";
        forecast = "";
        actual = "";
        isActive = false;
    }
};

//+------------------------------------------------------------------+
//| SuperTrendValues - Structure to store SuperTrend indicator values |
//+------------------------------------------------------------------+
struct SuperTrendValues {
    double upperBand;                 // Upper band value
    double lowerBand;                 // Lower band value
    double superTrend;                // Current SuperTrend value
    bool isUpTrend;                   // Whether in uptrend
    
    // Constructor
    SuperTrendValues() {
        upperBand = 0.0;
        lowerBand = 0.0;
        superTrend = 0.0;
        isUpTrend = false;
    }
};

//+------------------------------------------------------------------+
//| PriceActionPattern - Structure to store price action pattern info |
//+------------------------------------------------------------------+
struct PriceActionPattern {
    ENUM_PA_PATTERN type;             // Pattern type
    double significance;              // Significance/strength of pattern (0-1)
    datetime time;                    // When pattern formed
    int barIndex;                     // Bar index of pattern
    bool isBullish;                   // Whether pattern is bullish
    bool isBearish;                   // Whether pattern is bearish
    
    // Constructor
    PriceActionPattern() {
        type = PA_PATTERN_NONE;
        significance = 0.0;
        time = 0;
        barIndex = 0;
        isBullish = false;
        isBearish = false;
    }
};

//+------------------------------------------------------------------+
//| PropFirmRules - Structure to store rules for PropFirm trading     |
//+------------------------------------------------------------------+
struct PropFirmRules {
    string firmName;                  // PropFirm name
    double dailyDrawdownLimit;        // Daily drawdown limit
    double totalDrawdownLimit;        // Total drawdown limit
    int minTradingDays;               // Minimum trading days required
    int maxTradingDays;               // Maximum trading days allowed
    double profitTarget;              // Profit target percentage
    bool weekendHoldingAllowed;       // Whether weekend holding is allowed
    bool hasTrailingStopOut;          // Whether trailing stop-out is implemented
    int minTradesPerWeek;             // Minimum trades per week
    int maxTradesPerDay;              // Maximum trades per day
    
    // Constructor
    PropFirmRules() {
        firmName = "";
        dailyDrawdownLimit = 0.0;
        totalDrawdownLimit = 0.0;
        minTradingDays = 0;
        maxTradingDays = 0;
        profitTarget = 0.0;
        weekendHoldingAllowed = false;
        hasTrailingStopOut = false;
        minTradesPerWeek = 0;
        maxTradesPerDay = 0;
    }
};

//+------------------------------------------------------------------+
//| DivergenceInfo - Structure to store divergence information        |
//+------------------------------------------------------------------+
struct DivergenceInfo {
    bool isRegular;                   // Whether it's regular divergence
    bool isHidden;                    // Whether it's hidden divergence
    bool isBullish;                   // Whether divergence is bullish
    bool isBearish;                   // Whether divergence is bearish
    int startBar;                     // Start bar index
    int endBar;                       // End bar index
    double priceStart;                // Price at start point
    double priceEnd;                  // Price at end point
    double indicatorStart;            // Indicator value at start point
    double indicatorEnd;              // Indicator value at end point
    string indicator;                 // Indicator name (MACD, RSI, etc.)
    
    // Constructor
    DivergenceInfo() {
        isRegular = false;
        isHidden = false;
        isBullish = false;
        isBearish = false;
        startBar = 0;
        endBar = 0;
        priceStart = 0.0;
        priceEnd = 0.0;
        indicatorStart = 0.0;
        indicatorEnd = 0.0;
        indicator = "";
    }
};

//+------------------------------------------------------------------+
//| CorrelationInfo - Structure to store correlation information      |
//+------------------------------------------------------------------+
struct CorrelationInfo {
    string symbol1;                   // First symbol
    string symbol2;                   // Second symbol
    double correlation;               // Correlation coefficient (-1 to 1)
    int period;                       // Period used for calculation
    datetime calculationTime;         // When calculated
    
    // Constructor
    CorrelationInfo() {
        symbol1 = "";
        symbol2 = "";
        correlation = 0.0;
        period = 0;
        calculationTime = 0;
    }
};