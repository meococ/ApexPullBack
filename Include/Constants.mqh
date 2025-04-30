//+------------------------------------------------------------------+
//| Constants.mqh - Global constants for SonicR PropFirm EA           |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

//--- EA version information
#define SONICR_VERSION              "3.0"
#define SONICR_VERSION_DATE         "2025.03.29"
#define SONICR_COPYRIGHT            "SonicR Trading Systems"

//--- Default settings
#define DEFAULT_MAGIC_NUMBER        7754321
#define DEFAULT_RISK_PERCENT        1.0
#define DEFAULT_MAX_DAILY_DD        5.0
#define DEFAULT_MAX_TOTAL_DD        10.0
#define DEFAULT_MAX_DAILY_TRADES    3
#define DEFAULT_MAX_CONCURRENT      2

//--- Order management
#define DEFAULT_PARTIAL_CLOSE       0.6
#define DEFAULT_BE_LEVEL            0.8
#define DEFAULT_TRAILING_LEVEL      1.2
#define DEFAULT_TP1_MULTIPLIER      1.2
#define DEFAULT_MAX_RETRY           3
#define DEFAULT_RETRY_DELAY         500

//--- Indicator parameters
#define DEFAULT_EMA34_PERIOD        34
#define DEFAULT_EMA89_PERIOD        89
#define DEFAULT_EMA200_PERIOD       200
#define DEFAULT_ADX_PERIOD          14
#define DEFAULT_ADX_THRESHOLD       22.0
#define DEFAULT_MACD_FAST           12
#define DEFAULT_MACD_SLOW           26
#define DEFAULT_MACD_SIGNAL         9
#define DEFAULT_ATR_PERIOD          14
#define DEFAULT_SUPERTREND_PERIOD   10
#define DEFAULT_SUPERTREND_MULT     3.0

//--- Filter settings
#define DEFAULT_NEWS_BEFORE         60
#define DEFAULT_NEWS_AFTER          30
#define DEFAULT_GMT_OFFSET          2

//--- Risk thresholds based on PropFirm type
// FTMO
#define FTMO_DAILY_DD_CHALLENGE     5.0
#define FTMO_TOTAL_DD_CHALLENGE     10.0
#define FTMO_DAILY_DD_VERIFICATION  5.0
#define FTMO_TOTAL_DD_VERIFICATION  10.0
#define FTMO_DAILY_DD_FUNDED        5.0
#define FTMO_TOTAL_DD_FUNDED        10.0

// The5ers
#define THE5ERS_DAILY_DD_CHALLENGE  4.0
#define THE5ERS_TOTAL_DD_CHALLENGE  8.0
#define THE5ERS_DAILY_DD_FUNDED     4.0
#define THE5ERS_TOTAL_DD_FUNDED     8.0

// MyForexFunds
#define MFF_DAILY_DD_CHALLENGE      5.0
#define MFF_TOTAL_DD_CHALLENGE      12.0
#define MFF_DAILY_DD_VERIFICATION   5.0
#define MFF_TOTAL_DD_VERIFICATION   12.0
#define MFF_DAILY_DD_FUNDED         5.0
#define MFF_TOTAL_DD_FUNDED         12.0

// TheFundedTrader
#define TFT_DAILY_DD_CHALLENGE      5.0
#define TFT_TOTAL_DD_CHALLENGE      10.0
#define TFT_DAILY_DD_VERIFICATION   5.0
#define TFT_TOTAL_DD_VERIFICATION   10.0
#define TFT_DAILY_DD_FUNDED         5.0
#define TFT_TOTAL_DD_FUNDED         10.0

//--- Internal EA settings
#define MAX_SR_LEVELS               50      // Maximum number of S/R levels to track
#define MAX_TRADES_HISTORY          100     // Maximum number of trades to keep in history
#define MAX_CORRELATION_LOOKBACK    100     // Default lookback period for correlation calculation
#define CORRELATION_PAIRS_COUNT     10      // Number of major pairs to check correlation with

//--- Dashboard settings
#define DASHBOARD_WIDTH             300
#define DASHBOARD_HEIGHT            400
#define DASHBOARD_PADDING           10
#define DASHBOARD_FONT              "Arial"
#define DASHBOARD_FONT_SIZE         9

//--- File paths
#define LOG_DIRECTORY               "Files\\SonicR\\Logs\\"
#define REPORTS_DIRECTORY           "Files\\SonicR\\Reports\\"
#define SETTINGS_DIRECTORY          "Files\\SonicR\\Settings\\"

//--- Miscellaneous
#define DBL_EPSILON                 0.000001
#define MAX_RETRIES                 5
#define RETRY_DELAY_MS              1000