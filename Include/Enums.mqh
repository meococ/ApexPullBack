//+------------------------------------------------------------------+
//| Enums.mqh - Enumeration types for SonicR PropFirm EA              |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

//--- PropFirm Types
enum ENUM_PROP_FIRM_TYPE {
    PROP_FIRM_FTMO,       // FTMO
    PROP_FIRM_THE5ERS,    // The5ers
    PROP_FIRM_MFF,        // MyForexFunds
    PROP_FIRM_TFT,        // TheFundedTrader
    PROP_FIRM_CUSTOM      // Custom (User defined)
};

//--- Challenge Phases
enum ENUM_CHALLENGE_PHASE {
    PHASE_CHALLENGE,      // Challenge Phase
    PHASE_VERIFICATION,   // Verification Phase
    PHASE_FUNDED          // Funded Account
};

//--- Trading session types
enum ENUM_TRADING_SESSION {
    SESSION_ASIAN,        // Asian session
    SESSION_LONDON,       // London session
    SESSION_NEWYORK,      // New York session
    SESSION_OVERLAP,      // London-NY overlap
    SESSION_OFF_HOURS     // Off-hours (no major session active)
};

//--- Log levels
enum ENUM_LOG_LEVEL {
    LOG_ERROR,            // Only errors
    LOG_WARNING,          // Errors and warnings
    LOG_INFO,             // Errors, warnings, and information
    LOG_DEBUG             // All messages including debug
};

//--- Trade status types
enum ENUM_TRADE_STATUS {
    TRADE_STATUS_NEW,             // New trade
    TRADE_STATUS_BREAKEVEN_SET,   // Breakeven level set
    TRADE_STATUS_PARTIAL_CLOSED,  // Partial position closed
    TRADE_STATUS_TRAILING_ACTIVE, // Trailing stop active
    TRADE_STATUS_CLOSED           // Trade closed
};

//--- Trade exit reasons
enum ENUM_EXIT_REASON {
    EXIT_REASON_SL,               // Stopped out
    EXIT_REASON_TP,               // Take profit hit
    EXIT_REASON_BE,               // Breakeven stop hit
    EXIT_REASON_TRAILING,         // Trailing stop hit
    EXIT_REASON_MANUAL,           // Manually closed
    EXIT_REASON_OPPOSITE_SIGNAL,  // Closed due to opposite signal
    EXIT_REASON_TIME_LIMIT,       // Time-based exit
    EXIT_REASON_FILTER_CHANGE,    // Market filter triggered exit
    EXIT_REASON_SESSION_END       // End of trading session
};

//--- Trade signal types
enum ENUM_SIGNAL_TYPE {
    SIGNAL_NONE,                  // No signal
    SIGNAL_BUY,                   // Buy signal
    SIGNAL_SELL,                  // Sell signal
    SIGNAL_CLOSE_BUY,             // Close buy signal
    SIGNAL_CLOSE_SELL,            // Close sell signal
    SIGNAL_CLOSE_ALL              // Close all positions signal
};

//--- Signal strength
enum ENUM_SIGNAL_STRENGTH {
    SIGNAL_WEAK,                  // Weak signal (minimum confluence)
    SIGNAL_MEDIUM,                // Medium signal
    SIGNAL_STRONG                 // Strong signal (maximum confluence)
};

//--- Support/Resistance levels source
enum ENUM_SR_SOURCE {
    SR_SOURCE_SWING,              // Swing highs/lows
    SR_SOURCE_ROUND_NUMBERS,      // Round numbers
    SR_SOURCE_EMA200,             // EMA 200
    SR_SOURCE_PIVOT,              // Pivot points
    SR_SOURCE_FIBONACCI           // Fibonacci levels
};

//--- SR level type
enum ENUM_SR_LEVEL_TYPE {
    SR_TYPE_SUPPORT,              // Support level
    SR_TYPE_RESISTANCE,           // Resistance level
    SR_TYPE_BOTH                  // Both support and resistance
};

//--- SR level strength
enum ENUM_SR_STRENGTH {
    SR_STRENGTH_WEAK,             // Weak level (less tested)
    SR_STRENGTH_MEDIUM,           // Medium level
    SR_STRENGTH_STRONG            // Strong level (well tested)
};

//--- Price action pattern types
enum ENUM_PA_PATTERN {
    PA_PATTERN_NONE,              // No pattern
    PA_PATTERN_PIN_BAR,           // Pin Bar
    PA_PATTERN_ENGULFING,         // Engulfing
    PA_PATTERN_INSIDE_BAR,        // Inside Bar
    PA_PATTERN_OUTSIDE_BAR,       // Outside Bar
    PA_PATTERN_DOJI               // Doji
};

//--- Momentum state
enum ENUM_MOMENTUM_STATE {
    MOMENTUM_STATE_NONE,          // No clear momentum
    MOMENTUM_STATE_BULLISH,       // Bullish momentum
    MOMENTUM_STATE_BEARISH,       // Bearish momentum
    MOMENTUM_STATE_BULL_WEAKENING,// Bullish but weakening
    MOMENTUM_STATE_BEAR_WEAKENING // Bearish but weakening
};

//--- News impact
enum ENUM_NEWS_IMPACT {
    NEWS_IMPACT_NONE,             // No impact
    NEWS_IMPACT_LOW,              // Low impact news
    NEWS_IMPACT_MEDIUM,           // Medium impact news
    NEWS_IMPACT_HIGH              // High impact news
};

//--- Trend strength
enum ENUM_TREND_STRENGTH {
    TREND_STRENGTH_NONE,          // No trend (sideways)
    TREND_STRENGTH_WEAK,          // Weak trend
    TREND_STRENGTH_MEDIUM,        // Medium trend
    TREND_STRENGTH_STRONG         // Strong trend
};

//--- Dashboard elements
enum ENUM_DASHBOARD_ELEMENT {
    DASHBOARD_HEADER,             // Dashboard header
    DASHBOARD_STRATEGY_INFO,      // Strategy information
    DASHBOARD_TREND_STATUS,       // Current trend status
    DASHBOARD_SIGNAL_STATUS,      // Current signal status
    DASHBOARD_OPEN_TRADES,        // Open trades info
    DASHBOARD_PERFORMANCE,        // Performance statistics
    DASHBOARD_RISK_STATUS,        // Risk status
    DASHBOARD_FILTER_STATUS,      // Filter status
    DASHBOARD_CONTROLS            // Control buttons
};

//--- Dashboard button IDs
enum ENUM_DASHBOARD_BUTTON {
    DASHBOARD_BUTTON_PAUSE,       // Pause/Resume button
    DASHBOARD_BUTTON_EMERGENCY,   // Emergency mode toggle
    DASHBOARD_BUTTON_CLOSE_ALL,   // Close all positions
    DASHBOARD_BUTTON_SETTINGS     // Settings panel toggle
};