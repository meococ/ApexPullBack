//+------------------------------------------------------------------+ 
//|            CommonStructs.mqh - APEX Pullback EA v14.0            | 
//+------------------------------------------------------------------+ 

#ifndef COMMONSTRUCTS_MQH_ 
#define COMMONSTRUCTS_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "Enums.mqh"            // TẤT CẢ các enum
#include "Inputs.mqh"           // Unified constants and input parameters

// === INCLUDES CỤ THỂ (NẾU CẦN) ===
#include "JSONParser.mqh"       // Cần cho TradeProposal struct
#include "FunctionStack.mqh"      // Cần cho EAContext struct

namespace ApexPullback {

// --- FORWARD DECLARATIONS (ĐẶT SAU INCLUDE, TRƯỚC KHI SỬ DỤNG) --- 
class CAssetDNA;
class CChartObjectWrapper;

class CDashboard;
class CIndicatorUtils;
class CLogger;
class CMarketProfile;
class CNewsFilter;
class CPatternDetector;
class CPerformanceTracker;
class CPortfolioManager;
class CPositionManager;
class CPresetManager;
class CNewsDownloader;
class CTradeHistoryOptimizer;
class CRiskManager;
class CRiskOptimizer;
class CSafeDataProvider;
class CSessionManager;
class CSwingPointDetector;
class CTradeManager;
class CFileCommunication;
class CStrategyOptimizer;
class CCircuitBreaker;
class CRecoveryManager;
class CPerformanceDashboard;
class CParameterStabilityAnalyzer;
class CBrokerHealthMonitor;
// --- END FORWARD DECLARATIONS ---

    // --- CÁC STRUCT DỮ LIỆU CƠ BẢN --- 

    //+------------------------------------------------------------------+
    //| SwingPoint Structure                                             |
    //+------------------------------------------------------------------+
    struct SwingPoint {
        datetime time;            // Time of the swing point
        double price;           // Price of the swing point
        ENUM_SWING_POINT_TYPE type; // Type (High or Low)
        int strength;           // Strength of the swing
        // Add other relevant members if any
        
        SwingPoint() {
            time = 0;
            price = 0.0;
            type = SWING_UNKNOWN;
            strength = 0;
        }
    };

    //+------------------------------------------------------------------+
    //| AssetProfileData Structure                                       |
    //+------------------------------------------------------------------+
    struct AssetProfileData {
        double volatility;          // Asset volatility measure
        double averageSpread;       // Average spread for this asset
        double averageVolume;       // Average volume
        double riskFactor;          // Risk factor for this asset
        double correlationFactor;   // Correlation with other assets
        datetime lastUpdate;        // Last update time
        
        AssetProfileData() {
            volatility = 0.0;
            averageSpread = 0.0;
            averageVolume = 0.0;
            riskFactor = 1.0;
            correlationFactor = 0.0;
            lastUpdate = 0;
        }
    };

    //+------------------------------------------------------------------+
    //| StrategyConfiguration Structure                                  |
    //+------------------------------------------------------------------+
    struct StrategyConfiguration {
        ENUM_TRADING_STRATEGY strategyType;    // Type of strategy
        
        // Entry Parameters
        double entryThreshold;              // Entry signal threshold
        double confirmationThreshold;       // Confirmation signal threshold
        int minCandlesForEntry;             // Minimum candles for entry validation
        
        // Risk Management Parameters
        double maxRiskPerTrade;             // Maximum risk per trade (%)
        double stopLossMultiplier;          // Stop loss multiplier (ATR based)
        double takeProfitMultiplier;        // Take profit multiplier (ATR based)
        double trailingStopMultiplier;      // Trailing stop multiplier
        
        // Market Condition Parameters
        double minVolatility;               // Minimum volatility required
        double maxVolatility;               // Maximum volatility allowed
        double minTrendStrength;            // Minimum trend strength
        double maxSpreadMultiplier;         // Maximum spread multiplier
        
        // Time-based Parameters
        int sessionStartHour;               // Session start hour
        int sessionEndHour;                 // Session end hour
        bool avoidNews;                     // Avoid trading during news
        int newsAvoidanceMinutes;           // Minutes to avoid before/after news
        
        // Strategy-specific Parameters
        double pullbackDepth;               // For pullback strategies
        double momentumThreshold;           // For momentum strategies
        double meanReversionLevel;          // For mean reversion strategies
        double rangeBreakoutLevel;          // For range breakout strategies
        
        // Performance Optimization
        double winRateWeight;               // Weight for win rate in scoring
        double profitFactorWeight;          // Weight for profit factor in scoring
        double expectancyWeight;            // Weight for expectancy in scoring
        double stabilityWeight;             // Weight for stability in scoring
        
        // Adaptive Parameters
        bool enableAdaptiveRisk;            // Enable adaptive risk management
        bool enableAdaptiveEntry;           // Enable adaptive entry conditions
        double adaptationSpeed;             // Speed of parameter adaptation (0.0-1.0)
        int lookbackPeriod;                 // Lookback period for adaptation
        
        // Quality Control
        double minQualityScore;             // Minimum quality score for trade
        int maxConsecutiveLosses;           // Max consecutive losses before pause
        double maxDrawdownPercent;          // Max drawdown before strategy pause
        
        StrategyConfiguration() {
            strategyType = STRATEGY_PULLBACK_TREND;
            
            // Entry Parameters
            entryThreshold = 0.7;
            confirmationThreshold = 0.6;
            minCandlesForEntry = 3;
            
            // Risk Management Parameters
            maxRiskPerTrade = 2.0;
            stopLossMultiplier = 2.0;
            takeProfitMultiplier = 3.0;
            trailingStopMultiplier = 1.5;
            
            // Market Condition Parameters
            minVolatility = 0.0001;
            maxVolatility = 0.01;
            minTrendStrength = 0.3;
            maxSpreadMultiplier = 2.0;
            
            // Time-based Parameters
            sessionStartHour = 8;
            sessionEndHour = 17;
            avoidNews = true;
            newsAvoidanceMinutes = 30;
            
            // Strategy-specific Parameters
            pullbackDepth = 0.382;          // 38.2% Fibonacci level
            momentumThreshold = 0.6;
            meanReversionLevel = 0.8;
            rangeBreakoutLevel = 0.7;
            
            // Performance Optimization
            winRateWeight = 0.3;
            profitFactorWeight = 0.3;
            expectancyWeight = 0.25;
            stabilityWeight = 0.15;
            
            // Adaptive Parameters
            enableAdaptiveRisk = true;
            enableAdaptiveEntry = true;
            adaptationSpeed = 0.1;
            lookbackPeriod = 100;
            
            // Quality Control
            minQualityScore = 0.6;
            maxConsecutiveLosses = 3;
            maxDrawdownPercent = 5.0;
        }
        
        // Method to validate configuration
        bool IsValid() {
            if (maxRiskPerTrade <= 0 || maxRiskPerTrade > 10) return false;
            if (stopLossMultiplier <= 0 || takeProfitMultiplier <= 0) return false;
            if (minVolatility < 0 || maxVolatility <= minVolatility) return false;
            if (minTrendStrength < 0 || minTrendStrength > 1) return false;
            if (sessionStartHour < 0 || sessionStartHour > 23) return false;
            if (sessionEndHour < 0 || sessionEndHour > 23) return false;
            if (adaptationSpeed < 0 || adaptationSpeed > 1) return false;
            if (lookbackPeriod < 10) return false;
            if (minQualityScore < 0 || minQualityScore > 1) return false;
            return true;
        }
        
        // Method to adapt configuration based on performance
        void AdaptToPerformance(double winRate, double profitFactor, double expectancy) {
            if (!enableAdaptiveRisk && !enableAdaptiveEntry) return;
            
            // Adapt risk based on performance
            if (enableAdaptiveRisk) {
                if (winRate > 0.6 && profitFactor > 1.5) {
                    maxRiskPerTrade = MathMin(maxRiskPerTrade * (1 + adaptationSpeed * 0.1), 5.0);
                } else if (winRate < 0.4 || profitFactor < 1.2) {
                    maxRiskPerTrade = MathMax(maxRiskPerTrade * (1 - adaptationSpeed * 0.1), 0.5);
                }
            }
            
            // Adapt entry conditions based on performance
            if (enableAdaptiveEntry) {
                if (winRate > 0.65) {
                    entryThreshold = MathMax(entryThreshold - adaptationSpeed * 0.05, 0.5);
                } else if (winRate < 0.45) {
                    entryThreshold = MathMin(entryThreshold + adaptationSpeed * 0.05, 0.9);
                }
            }
        }
    };

    //+------------------------------------------------------------------+
    //| MarketProfileData Structure                                      |
    //+------------------------------------------------------------------+
    struct MarketProfileData {
        double poc;             // Point of Control
        double vah;             // Value Area High
        double val;             // Value Area Low
        double openPrice;
        double highPrice;
        double lowPrice;
        double closePrice;
        long volume;
        datetime startTime;
        datetime endTime;
        double atr;             // Average True Range
        double trendScore;      // Trend score calculated by MarketProfile module
        double momentumScore;   // Momentum score calculated by MarketProfile module
        // Add other relevant members if any

        MarketProfileData() {
            poc = 0.0;
            vah = 0.0;
            val = 0.0;
            openPrice = 0.0;
            highPrice = 0.0;
            lowPrice = 0.0;
            closePrice = 0.0;
            volume = 0;
            startTime = 0;
            endTime = 0;
            atr = 0.0;
            trendScore = 0.0;
            momentumScore = 0.0;
        }
    };

    // (Giữ nguyên các struct hiện có của bạn như MarketProfileData, SwingPoint, etc.) 

    //+------------------------------------------------------------------+
    //| IndicatorHandles Structure                                       |
    //+------------------------------------------------------------------+
    struct IndicatorHandles {
        int atrHandle;
        int maHandle; // Can be an array if multiple MAs are needed directly here
        int rsiHandle;
        int stochHandle;
        int bollingerHandle;
        int adxHandle;
        int macdHandle;
        int volumeHandle;
        int ichimokuHandle;
        // Add any other specific indicator handles your EA uses

        // Constructor to initialize handles
        IndicatorHandles() {
            atrHandle = INVALID_HANDLE;
            maHandle = INVALID_HANDLE;
            rsiHandle = INVALID_HANDLE;
            stochHandle = INVALID_HANDLE;
            bollingerHandle = INVALID_HANDLE;
            adxHandle = INVALID_HANDLE;
            macdHandle = INVALID_HANDLE;
            volumeHandle = INVALID_HANDLE;
            ichimokuHandle = INVALID_HANDLE;
        }
    };

    //+------------------------------------------------------------------+
    //| TradeProposal Structure - For Master-Slave Communication         |
    //+------------------------------------------------------------------+
    struct TradeProposal {
        string symbol;              // Symbol (e.g., "EURUSD")
        ENUM_ORDER_TYPE orderType;  // Order type (ORDER_TYPE_BUY, ORDER_TYPE_SELL)
        double entryPrice;          // Proposed entry price
        double stopLoss;            // Proposed stop loss price
        double takeProfit;          // Proposed take profit price
        double qualityScore;        // Quality score of the trade setup (0.0 to 1.0)
        long   magicNumber;         // Magic number for the trade
        string strategyUsed;        // Name of the strategy that generated the proposal
        datetime expirationTime;    // Optional: Expiration time for pending orders

        // Constructor
        TradeProposal() {
            symbol = "";
            orderType = WRONG_VALUE; // Or some default invalid ENUM_ORDER_TYPE
            entryPrice = 0.0;
            stopLoss = 0.0;
            takeProfit = 0.0;
            qualityScore = 0.0;
            magicNumber = 0;
            strategyUsed = "";
            expirationTime = 0;
        }

        // Convert struct to JSON format using enhanced parser
        string ToString() {
            ApexPullback::CJSONParser parser;
            string json = "{";
            json += parser.BuildJSONString("symbol", symbol) + ",";
            json += parser.BuildJSONString("orderType", EnumToString(orderType)) + ",";
            json += parser.BuildJSONNumber("entryPrice", entryPrice, _Digits) + ",";
            json += parser.BuildJSONNumber("stopLoss", stopLoss, _Digits) + ",";
            json += parser.BuildJSONNumber("takeProfit", takeProfit, _Digits) + ",";
            json += parser.BuildJSONNumber("qualityScore", qualityScore, 2) + ",";
            json += parser.BuildJSONNumber("magicNumber", (double)magicNumber, 0) + ",";
            json += parser.BuildJSONString("strategyUsed", strategyUsed) + ",";
            json += parser.BuildJSONDateTime("expirationTime", expirationTime);
            json += "}";
            return json;
        }

        // Populate struct from JSON string using enhanced parser
        bool FromString(string jsonString) {
            ApexPullback::CJSONParser parser(true); // Strict mode
            
            // Validate JSON structure first
            if (!parser.ValidateJSON(jsonString)) {
                return false;
            }
            
            // Parse required fields
            if (!parser.ParseString(jsonString, "symbol", symbol)) {
                return false;
            }
            
            string orderTypeStr;
            if (!parser.ParseString(jsonString, "orderType", orderTypeStr)) {
                return false;
            }
            
            // Convert order type string to enum
            if (orderTypeStr == "ORDER_TYPE_BUY") orderType = ORDER_TYPE_BUY;
            else if (orderTypeStr == "ORDER_TYPE_SELL") orderType = ORDER_TYPE_SELL;
            else if (orderTypeStr == "ORDER_TYPE_BUY_LIMIT") orderType = ORDER_TYPE_BUY_LIMIT;
            else if (orderTypeStr == "ORDER_TYPE_SELL_LIMIT") orderType = ORDER_TYPE_SELL_LIMIT;
            else if (orderTypeStr == "ORDER_TYPE_BUY_STOP") orderType = ORDER_TYPE_BUY_STOP;
            else if (orderTypeStr == "ORDER_TYPE_SELL_STOP") orderType = ORDER_TYPE_SELL_STOP;
            else orderType = WRONG_VALUE;
            
            // Parse numeric fields with validation
            if (!parser.ParseDouble(jsonString, "entryPrice", entryPrice)) entryPrice = 0.0;
            if (!parser.ParseDouble(jsonString, "stopLoss", stopLoss)) stopLoss = 0.0;
            if (!parser.ParseDouble(jsonString, "takeProfit", takeProfit)) takeProfit = 0.0;
            if (!parser.ParseDouble(jsonString, "qualityScore", qualityScore)) qualityScore = 0.0;
            
            double magicDouble;
            if (parser.ParseDouble(jsonString, "magicNumber", magicDouble)) {
                magicNumber = (long)magicDouble;
            } else {
                magicNumber = 0;
            }
            
            // Parse optional fields
            parser.ParseString(jsonString, "strategyUsed", strategyUsed);
            parser.ParseDateTime(jsonString, "expirationTime", expirationTime);
            
            return true;
        }
    };


    //+------------------------------------------------------------------+
    //| EAContext Structure - The Single Source of Truth                 |
    //+------------------------------------------------------------------+
    class EAContext {
    public:
        // --- Con trỏ đến các Module Chính ---
        CLogger* Logger;
        CFunctionStack* FunctionStack;
        CMarketProfile* MarketProfile;
        CSwingPointDetector* SwingDetector;
        CTradeManager* TradeManager;
        CPositionManager* PositionManager;
        CRiskManager* RiskManager;
        CAssetDNA* AssetDNA;
        CDashboard* Dashboard;
        CIndicatorUtils* IndicatorUtils;
        CPortfolioManager* PortfolioManager;
        CPerformanceTracker* PerformanceTracker;
        CNewsFilter* NewsFilter;
        CSessionManager* SessionManager;
        CPatternDetector* PatternDetector;
        CRiskOptimizer* RiskOptimizer;
        CSafeDataProvider* SafeDataProvider;
        CChartObjectWrapper* ChartObjectWrapper;
        CPresetManager* PresetManager;
        CNewsDownloader* NewsDownloader;
        CTradeHistoryOptimizer* TradeHistoryOptimizer;
        CFileCommunication* FileCommunication;
        CStrategyOptimizer* StrategyOptimizer;
        CCircuitBreaker* CircuitBreaker;
        CRecoveryManager* RecoveryManager;
        CPerformanceDashboard* PerformanceDashboard;
        CParameterStabilityAnalyzer* ParameterStabilityAnalyzer;
        CBrokerHealthMonitor* BrokerHealthMonitor;

        // --- Tham số Input --- 
        // Strings
        string EAName;
        string EAVersion;
        string OrderComment;
        string CsvLogFilename;
        string TelegramBotToken;
        string TelegramChatID;
        string NewsDataFile;

        // Integers
        int MagicNumber;
        int EMA_Fast;
        int EMA_Medium;
        int EMA_Slow;
        int ADXPeriod;
        int TrendDirection;
        int ChandelierPeriod;
        int GmtOffset;
        ENUM_NEWS_FILTER_MODE NewsFilterMode; // Renamed from NewsFilterSetting and type changed
        ENUM_NEWS_FILTER_LEVEL NewsImportance;
        int MinutesBeforeNews;
        int MinutesAfterNews;
        int PauseDurationMinutes;
        int AssetProfileDays;
        ENUM_DASHBOARD_THEME DashboardTheme;
        ENUM_TIMEFRAMES MainTimeframe;
        ENUM_TIMEFRAMES HigherTimeframe;
        ENUM_ENTRY_MODE EntryMode;
        ENUM_TRAILING_MODE TrailingMode;
        ENUM_SESSION_FILTER SessionFilter;
        ENUM_ADAPTIVE_MODE AdaptiveMode;
        ENUM_TP_MODE TakeProfitMode;
        int MarketPreset;
        int UpdateFrequencySeconds;

        // Booleans
        bool AllowNewTrades;
        bool IsSlaveEA;
        bool EnableDetailedLogs;
        bool EnableCsvLog;
        bool DisplayDashboard;
        bool AlertsEnabled;
        bool SendNotifications;
        bool SendEmailAlerts;
        bool EnableTelegramNotify;
        bool TelegramImportantOnly;
        bool DisableDashboardInBacktest;
        bool UseMultiTimeframe;
        bool EnablePriceAction;
        bool EnableSwingLevels;
        bool RequirePriceActionConfirmation;
        bool RequireMomentumConfirmation;
        bool RequireVolumeConfirmation;
        bool EnableMarketRegimeFilter;
        bool EnableVolatilityFilter;
        bool EnableAdxFilter;
        bool PropFirmMode;
        bool EnableTaperedRisk;
        bool UsePartialClose;
        bool UseAdaptiveTrailing;
        bool UseChandelierExit;
        bool FilterBySession;
        bool UseGmtOffset;
        bool TradeLondonOpen;
        bool TradeNewYorkOpen;
        bool EnableAutoPause;
        bool EnableAutoResume;
        bool ResumeOnLondonOpen;
        bool UseAssetProfiler;
        bool AdaptRiskByAsset;
        bool AdaptSLByAsset;
        bool AdaptSpreadFilterByAsset;
        bool IsMasterPortfolioManager;
        bool SaveStatistics;
        bool EnableIndicatorCache;

        // Doubles
        double MinPullbackPercent;
        double MaxPullbackPercent;
        double MinAdxValue;
        double MaxAdxValue;
        double VolatilityThreshold;
        double MaxSpreadPoints;
        double RiskPercent;
        double StopLoss_ATR;
        double TakeProfit_RR;
        double DailyLossLimit;
        double MaxDrawdown;
        double DrawdownReduceThreshold;
        double MinRiskMultiplier;
        double PartialCloseR1;
        double PartialCloseR2;
        double PartialClosePercent1;
        double PartialClosePercent2;
        double TrailingAtrMultiplier;
        double BreakEvenAfterR;
        double BreakEvenBuffer;
        double ChandelierMultiplier;
        double VolatilityPauseThreshold;
        double DrawdownPauseThreshold;
        double StopLossBufferATR_Ratio;
        double StopLossATR_Multiplier;
        double TakeProfitStructureBufferATR_Ratio;
        double ADXThresholdForVolatilityTP;
        double VolatilityTP_ATR_Multiplier_High;
        double VolatilityTP_ATR_Multiplier_Low;

        // --- Biến Trạng thái Động --- 
        bool IsInitialized;
        bool IsShuttingDown;
        bool EmergencyStop;
        long TickCounter;
        long ErrorCounter;
        datetime LastTickTime;
        datetime LastBarTime;
        
        // --- Trạng thái Chia sẻ giữa các Module (Decoupling Interface) ---
        // Market Data States
        double CurrentATR;
        double ATRRatio;
        ENUM_MARKET_REGIME CurrentMarketRegime;
        double LastSwingHigh;
        double LastSwingLow;
        bool HasValidSwingPoints;
        
        // Risk Management States
        double CurrentDrawdownPercent;
        bool IsDrawdownExceeded;
        bool IsMaxDrawdownReached;
        bool IsDailyLossLimitReached;
        bool ShouldPauseTradingRisk;
        
        // News Filter States
        bool HasUpcomingNews;
        bool HasCurrentNewsEvent;
        bool ShouldPauseTradingNews;
        
        // Market Profile States
        MarketProfileData CurrentMarketProfile;
        bool IsMarketProfileValid;
        
        // Asset Profiler States
        AssetProfileData CurrentAssetProfile;
        bool IsAssetProfileValid;
        
        // Trading States
        bool AllowNewPositions;
        bool ShouldCloseAllPositions;
        int CurrentBuyPositions;
        int CurrentSellPositions;
        bool IsMaxPositionsReached;
        
        // Risk Optimizer States
        double OptimalLotSize;
        double RecommendedRiskPercent;
        bool IsRiskOptimizerActive;
        
        // Circuit Breaker States
        bool IsCircuitBreakerTriggered;
        bool IsEmergencyStopActive;
        double CurrentSpreadRatio;
        double CurrentVolatilityRatio;
        datetime LastCircuitBreakerCheck;
        string CircuitBreakerReason;
        
        // Strategy Optimizer States
        bool IsWalkForwardActive;
        bool IsParameterOptimizationRunning;
        double CurrentParameterStability;
        datetime LastOptimizationRun;
        bool HasOptimalParameters;
        
        // Recovery Manager States
        bool IsRecoveryModeActive;
        int RecoveredPositionsCount;
        bool HasRecoveryErrors;
        datetime LastRecoveryTime;
        
        // Portfolio Communication States
        bool IsPortfolioModeEnabled;
        string PortfolioId;
        int ConnectedEAsCount;
        datetime LastHeartbeat;
        bool HasPortfolioMessages;
        
        // --- Broker Performance Monitoring States ---
        double AverageSlippagePips;           // Trung bình slippage theo pips
        double AverageExecutionMs;            // Thời gian thực thi trung bình (ms)
        bool IsBrokerPerformanceDegraded;     // Chất lượng broker có bị suy giảm
        double MaxAcceptableSlippage;         // Ngưỡng slippage tối đa chấp nhận được
        double MaxAcceptableLatency;          // Ngưỡng độ trễ tối đa chấp nhận được
        double CurrentRiskMultiplier;         // Hệ số điều chỉnh rủi ro hiện tại
        int SlippageDataPoints;               // Số điểm dữ liệu slippage đã thu thập
        int LatencyDataPoints;                // Số điểm dữ liệu độ trễ đã thu thập
        datetime LastBrokerHealthCheck;      // Lần kiểm tra sức khỏe broker cuối cùng
        
        // --- Parameter Stability Monitoring States ---
        double CurrentParameterInstabilityIndex;  // Chỉ số bất ổn tham số hiện tại
        bool IsParameterStabilityDegraded;        // Tính ổn định tham số có bị suy giảm
        double MinAcceptableStabilityIndex;       // Ngưỡng ổn định tối thiểu chấp nhận được
        int WalkForwardCycles;                     // Số chu kỳ Walk-Forward đã thực hiện
        datetime LastStabilityCheck;              // Lần kiểm tra ổn định cuối cùng
        
        // V14.0: Enhanced Parameter Stability Analysis
        double ParameterStabilityIndex;           // Chỉ số ổn định tham số (0.0 - 1.0)
        bool IsStrategyUnstable;                  // Chiến lược có bất ổn không

        //+--------------------------------------------------------------+
        //| Constructor - Để khởi tạo giá trị mặc định cho các con trỏ    |
        //+--------------------------------------------------------------+
        public:
            // Vô hiệu hóa copy constructor và copy assignment
            EAContext(const EAContext&) = delete;
            void operator=(const EAContext&) = delete;

        EAContext() {
            // Khởi tạo tất cả các con trỏ thành NULL để tránh lỗi truy cập không hợp lệ
            Logger = NULL;
            RiskManager = NULL;
            TradeManager = NULL;
            PositionManager = NULL;
            MarketProfile = NULL;
            SwingDetector = NULL;
            PatternDetector = NULL;
            SessionManager = NULL;
            Dashboard = NULL;
            PresetManager = NULL;
            NewsFilter = NULL;
            IndicatorUtils = NULL;
            SafeDataProvider = NULL;
            AssetDNA = NULL;
            PortfolioManager = NULL;
            FunctionStack = NULL;
            ChartObjectWrapper = NULL;
            NewsDownloader = NULL;
            TradeHistoryOptimizer = NULL;
            StrategyOptimizer = NULL;
            CircuitBreaker = NULL;
            RecoveryManager = NULL;
            PerformanceDashboard = NULL;
            ParameterStabilityAnalyzer = NULL;
            FunctionStack = NULL;
            BrokerHealthMonitor = NULL;

            // Các con trỏ cũ hơn có thể vẫn cần thiết cho khả năng tương thích ngược
            // hoặc các phần chưa được nâng cấp của mã.
            PerformanceTracker = NULL;
            RiskOptimizer = NULL;
            FileCommunication = NULL;

            // Khởi tạo các biến trạng thái 
            IsInitialized = false;
            IsShuttingDown = false;
            EmergencyStop = false;
            TickCounter = 0;
            ErrorCounter = 0;
            LastTickTime = 0;
            LastBarTime = 0;
            
            // Khởi tạo trạng thái chia sẻ
            CurrentATR = 0.0;
            ATRRatio = 0.0;
            CurrentMarketRegime = REGIME_UNKNOWN;
            LastSwingHigh = 0.0;
            LastSwingLow = 0.0;
            HasValidSwingPoints = false;
            
            CurrentDrawdownPercent = 0.0;
            IsDrawdownExceeded = false;
            IsMaxDrawdownReached = false;
            IsDailyLossLimitReached = false;
            ShouldPauseTradingRisk = false;
            
            HasUpcomingNews = false;
            HasCurrentNewsEvent = false;
            ShouldPauseTradingNews = false;
            
            IsMarketProfileValid = false;
            IsAssetProfileValid = false;
            
            AllowNewPositions = true;
            ShouldCloseAllPositions = false;
            CurrentBuyPositions = 0;
            CurrentSellPositions = 0;
            IsMaxPositionsReached = false;
            
            OptimalLotSize = 0.0;
            RecommendedRiskPercent = 0.0;
            IsRiskOptimizerActive = false;
            
            // Circuit Breaker States
            IsCircuitBreakerTriggered = false;
            IsEmergencyStopActive = false;
            CurrentSpreadRatio = 0.0;
            CurrentVolatilityRatio = 0.0;
            LastCircuitBreakerCheck = 0;
            CircuitBreakerReason = "";
            
            // Strategy Optimizer States
            IsWalkForwardActive = false;
            IsParameterOptimizationRunning = false;
            CurrentParameterStability = 0.0;
            LastOptimizationRun = 0;
            HasOptimalParameters = false;
            
            // Recovery Manager States
            IsRecoveryModeActive = false;
            RecoveredPositionsCount = 0;
            HasRecoveryErrors = false;
            LastRecoveryTime = 0;
            
            // Portfolio Communication States
            IsPortfolioModeEnabled = false;
            PortfolioId = "";
            ConnectedEAsCount = 0;
            LastHeartbeat = 0;
            HasPortfolioMessages = false;
            
            // Broker Performance Monitoring States
            AverageSlippagePips = 0.0;
            AverageExecutionMs = 0.0;
            IsBrokerPerformanceDegraded = false;
            MaxAcceptableSlippage = 2.0;  // 2 pips mặc định
            MaxAcceptableLatency = 500.0;  // 500ms mặc định
            CurrentRiskMultiplier = 1.0;
            SlippageDataPoints = 0;
            LatencyDataPoints = 0;
            LastBrokerHealthCheck = 0;
            
            // Parameter Stability Monitoring States
            CurrentParameterInstabilityIndex = 0.0;
            IsParameterStabilityDegraded = false;
            MinAcceptableStabilityIndex = 0.3;  // Ngưỡng ổn định tối thiểu
            WalkForwardCycles = 0;
            LastStabilityCheck = 0;
            
            // V14.0: Enhanced Parameter Stability Analysis
            ParameterStabilityIndex = 1.0;       // Bắt đầu với ổn định hoàn toàn
            IsStrategyUnstable = false;           // Chiến lược ban đầu ổn định

            // Initialize input parameters to default values
            EAName = "APEX Pullback EA";
            EAVersion = "14.0";
            OrderComment = "APEX_PB";
            CsvLogFilename = "APEX_Trades.csv";
            TelegramBotToken = "";
            TelegramChatID = "";
            NewsDataFile = "NewsData.xml";
            // Added new integer parameters
            UpdateFrequencySeconds = 60; // Default value, can be adjusted in Inputs.mqh

            MagicNumber = 12345;
            EMA_Fast = 12;
            EMA_Medium = 26;
            EMA_Slow = 50;
            TrendDirection = 0; // 0 for auto, 1 for long, 2 for short
            ChandelierPeriod = 22;
            GmtOffset = 0;
            NewsFilterMode = ENUM_NEWS_FILTER_MODE::NEWS_FILTER_OFF; // Default to OFF
            NewsImportance = ENUM_NEWS_FILTER_LEVEL::NEWS_FILTER_HIGH; // Default to HIGH
            MinutesBeforeNews = 60;
            MinutesAfterNews = 30;
            PauseDurationMinutes = 120;
            AssetProfileDays = 90;
            DashboardTheme = ENUM_DASHBOARD_THEME::THEME_DARK; 
            MainTimeframe = PERIOD_CURRENT;
            HigherTimeframe = PERIOD_H4;
            EntryMode = ENUM_ENTRY_MODE::ENTRY_MODE_PULLBACK;
            TrailingMode = ENUM_TRAILING_MODE::TRAILING_MODE_ATR;
            SessionFilter = FILTER_ALL_SESSIONS;
            AdaptiveMode = MODE_MANUAL;
            TakeProfitMode = ENUM_TP_MODE::TP_MODE_RR;
            MarketPreset = 0; // PRESET_AUTO

            AllowNewTrades = true;
            IsSlaveEA = false;
            EnableDetailedLogs = true;
            EnableCsvLog = false;
            // Added new boolean parameters
            SaveStatistics = true;         // Default value, can be adjusted in Inputs.mqh
            EnableIndicatorCache = true;   // Default value, can be adjusted in Inputs.mqh
            DisplayDashboard = true;
            AlertsEnabled = true;
            SendNotifications = false;
            SendEmailAlerts = false;
            EnableTelegramNotify = false;
            TelegramImportantOnly = true;
            DisableDashboardInBacktest = false;
            UseMultiTimeframe = true;
            EnablePriceAction = true;
            EnableSwingLevels = true;
            RequirePriceActionConfirmation = true;
            RequireMomentumConfirmation = false;
            RequireVolumeConfirmation = false;
            EnableMarketRegimeFilter = true;
            EnableVolatilityFilter = true;
            EnableAdxFilter = true;
            PropFirmMode = false;
            EnableTaperedRisk = false;
            UsePartialClose = true;
            UseAdaptiveTrailing = true;
            UseChandelierExit = true;
            FilterBySession = true;
            UseGmtOffset = false;
            TradeLondonOpen = true;
            TradeNewYorkOpen = true;
            EnableAutoPause = true;
            EnableAutoResume = true;
            ResumeOnLondonOpen = true;
            UseAssetProfiler = true;
            AdaptRiskByAsset = true;
            AdaptSLByAsset = true;
            AdaptSpreadFilterByAsset = true;
            IsMasterPortfolioManager = false;

            MinPullbackPercent = 0.2;
            MaxPullbackPercent = 0.8;
            MinAdxValue = 20.0;
            MaxAdxValue = 70.0;
            VolatilityThreshold = 1.5;
            MaxSpreadPoints = 50; // 5 points for 5-digit broker
            RiskPercent = 1.0;
            StopLoss_ATR = 2.0;
            TakeProfit_RR = 1.5;
            DailyLossLimit = 5.0;
            MaxDrawdown = 20.0;
            DrawdownReduceThreshold = 10.0;
            MinRiskMultiplier = 0.5;
            PartialCloseR1 = 1.0;
            PartialCloseR2 = 2.0;
            PartialClosePercent1 = 0.5;
            PartialClosePercent2 = 0.3;
            TrailingAtrMultiplier = 1.5;
            BreakEvenAfterR = 0.8;
            BreakEvenBuffer = 10; // points
            ChandelierMultiplier = 3.0;
            VolatilityPauseThreshold = 3.0;
            DrawdownPauseThreshold = 15.0;
            StopLossBufferATR_Ratio = 0.1;
            StopLossATR_Multiplier = 1.0;
            TakeProfitStructureBufferATR_Ratio = 0.1;
            ADXThresholdForVolatilityTP = 25.0;
            VolatilityTP_ATR_Multiplier_High = 2.0;
            VolatilityTP_ATR_Multiplier_Low = 1.0;
        }
    };

    //+------------------------------------------------------------------+
    //| DetectedPattern Structure - For Pattern Detection Results        |
    //+------------------------------------------------------------------+
    struct DetectedPattern {
        ENUM_PATTERN_TYPE patternType;     // Loại mẫu hình được phát hiện
        double confidence;                 // Độ tin cậy (0.0 - 1.0)
        double entryPrice;                // Giá vào lệnh đề xuất
        double stopLoss;                  // Stop loss đề xuất
        double takeProfit;                // Take profit đề xuất
        datetime detectionTime;           // Thời gian phát hiện
        string description;               // Mô tả mẫu hình
        bool isValid;                     // Mẫu hình có hợp lệ không
        
        // Constructor
        DetectedPattern() {
            patternType = PATTERN_NONE;
            confidence = 0.0;
            entryPrice = 0.0;
            stopLoss = 0.0;
            takeProfit = 0.0;
            detectionTime = 0;
            description = "";
            isValid = false;
        }
    };

    //+------------------------------------------------------------------+
    //| SignalInfo Structure - For Trading Signal Information            |
    //+------------------------------------------------------------------+
    struct SignalInfo {
        ENUM_ORDER_TYPE signalType;       // Loại tín hiệu (BUY/SELL)
        double strength;                  // Độ mạnh tín hiệu (0.0 - 1.0)
        double entryPrice;               // Giá vào lệnh
        double stopLoss;                 // Stop loss
        double takeProfit;               // Take profit
        datetime signalTime;             // Thời gian tín hiệu
        string reason;                   // Lý do tạo tín hiệu
        bool isValid;                    // Tín hiệu có hợp lệ không
        double riskReward;               // Tỷ lệ risk/reward
        
        // Constructor
        SignalInfo() {
            signalType = WRONG_VALUE;
            strength = 0.0;
            entryPrice = 0.0;
            stopLoss = 0.0;
            takeProfit = 0.0;
            signalTime = 0;
            reason = "";
            isValid = false;
            riskReward = 0.0;
        }
    };

    //+------------------------------------------------------------------+
    //| News Event Structure                                             |
    //+------------------------------------------------------------------+
    struct NewsEvent {
        datetime time;          // Thời gian tin tức
        string currency;        // Đồng tiền liên quan
        string name;           // Tên tin tức
        int impact;            // Mức độ tác động (1-3)
        bool isProcessed;      // Đã xử lý chưa
        
        NewsEvent() {
            time = 0;
            currency = "";
            name = "";
            impact = 0;
            isProcessed = false;
        }
    };

    //+------------------------------------------------------------------+
    //| Risk Management Statistics Structures                            |
    //+------------------------------------------------------------------+
    struct ClusterStats {
        int totalTrades;
        int wins;
        int losses;
        double totalProfit;
        double totalLoss;
        double winRate;
        double profitFactor;
        
        ClusterStats() {
            totalTrades = 0;
            wins = 0;
            losses = 0;
            totalProfit = 0.0;
            totalLoss = 0.0;
            winRate = 0.0;
            profitFactor = 0.0;
        }
    };

    struct SessionStats {
        int totalTrades;
        int wins;
        int losses;
        double totalProfit;
        double totalLoss;
        double winRate;
        double profitFactor;
        
        SessionStats() {
            totalTrades = 0;
            wins = 0;
            losses = 0;
            totalProfit = 0.0;
            totalLoss = 0.0;
            winRate = 0.0;
            profitFactor = 0.0;
        }
    };

    struct ATRStats {
        int totalTrades;
        int wins;
        int losses;
        double totalProfit;
        double totalLoss;
        double winRate;
        double profitFactor;
        
        ATRStats() {
            totalTrades = 0;
            wins = 0;
            losses = 0;
            totalProfit = 0.0;
            totalLoss = 0.0;
            winRate = 0.0;
            profitFactor = 0.0;
        }
    };

    struct RegimeStats {
        int totalTrades;
        int wins;
        int losses;
        double totalProfit;
        double totalLoss;
        double winRate;
        double profitFactor;
        
        RegimeStats() {
            totalTrades = 0;
            wins = 0;
            losses = 0;
            totalProfit = 0.0;
            totalLoss = 0.0;
            winRate = 0.0;
            profitFactor = 0.0;
        }
    };

    //+------------------------------------------------------------------+
    //| PortfolioStatus Structure                                        |
    //+------------------------------------------------------------------+
    struct PortfolioStatus {
        int totalPositions;         // Total number of open positions
        int buyPositions;           // Number of buy positions
        int sellPositions;          // Number of sell positions
        double totalRiskAmount;     // Total risk in account currency
        double totalRiskPercent;    // Total risk as a percentage of account balance
        double totalUnrealizedPnL;  // Total unrealized profit/loss
        double totalUnrealizedPnLPercent; // Total unrealized PnL as a percentage
        double averageR;            // Average R-multiple of open positions
        double weightedAverageR;    // Weighted average R-multiple
        double successRate;         // Historical success rate
        double profitFactor;        // Historical profit factor

        // Constructor to initialize members
        PortfolioStatus() {
            Clear();
        }

        // Method to reset all values
        void Clear() {
            totalPositions = 0;
            buyPositions = 0;
            sellPositions = 0;
            totalRiskAmount = 0.0;
            totalRiskPercent = 0.0;
            totalUnrealizedPnL = 0.0;
            totalUnrealizedPnLPercent = 0.0;
            averageR = 0.0;
            weightedAverageR = 0.0;
            successRate = 0.0;
            profitFactor = 0.0;
        }
    };



} // End namespace ApexPullback

#endif // COMMONSTRUCTS_MQH_
