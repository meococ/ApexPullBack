//+------------------------------------------------------------------+
//|                   Risk Optimizer Module v14.0                    |
//|                   (for ApexPullback EA v14.0)                    |
//+------------------------------------------------------------------+
#property strict

// Include các module cần thiết
#include "CommonStructs.mqh"
#include "MarketProfile.mqh"
#include "Logger.mqh"
#include "RiskManager.mqh"
#include "SwingPointDetector.mqh"
#include "AssetProfiler.mqh"  // Module mới v14.0
#include "NewsFilter.mqh"     // Module mới v14.0

//====================================================
// Struct Config cho Risk Optimizer v14.0
//====================================================
struct SRiskOptimizerConfig {
    // Cấu hình cơ bản
    double RiskPercent;                  // Risk % gốc
    double SL_ATR_Multiplier;            // Hệ số SL theo ATR
    double TP_RR_Ratio;                  // Tỷ lệ Risk:Reward cho TP
    double MaxAllowedDrawdown;           // Drawdown tối đa cho phép (%)
    
    // Cấu hình pullback chất lượng cao (v14.0)
    double MinPullbackPercent;           // % Pullback tối thiểu (20%)
    double MaxPullbackPercent;           // % Pullback tối đa (70%)
    bool   RequirePriceAction;           // Yêu cầu xác nhận Price Action
    bool   RequireMomentum;              // Yêu cầu xác nhận Momentum  
    bool   RequireVolume;                // Yêu cầu xác nhận Volume
    
    // Cấu hình giảm risk theo drawdown
    double DrawdownReduceThreshold;      // Ngưỡng DD bắt đầu giảm risk
    bool   EnableTaperedRisk;            // Chế độ giảm risk từ từ
    double MinRiskMultiplier;            // Hệ số risk tối thiểu khi DD cao
    
    // Giới hạn risk tối đa
    bool   UseFixedMaxRiskUSD;           // Dùng giới hạn USD cố định
    double MaxRiskUSD;                   // Giới hạn risk tối đa mỗi lệnh ($)
    double MaxRiskPercent;               // Giới hạn risk tối đa (% tài khoản)
    
    // Cấu hình Scaling (nhồi lệnh) - v14.0 cải tiến
    bool   EnableScaling;                // Cho phép scaling (nhồi lệnh)
    int    MaxScalingCount;              // Số lần scaling tối đa (giảm từ 2 xuống 1)
    double ScalingRiskPercent;           // % risk cho scaling (giảm từ 0.4 xuống 0.3)
    bool   RequireBreakEvenForScaling;   // Yêu cầu BE trước khi scaling
    bool   ScalingRequiresClearTrend;    // Yêu cầu xu hướng rõ ràng để scaling
    double MinRMultipleForScaling;       // R-multiple tối thiểu để scaling (1.0R)
    
    // Cấu hình Chandelier Exit
    bool   UseChandelierExit;            // Kích hoạt Chandelier Exit
    int    ChandelierLookback;           // Số nến lookback
    double ChandelierATRMultiplier;      // Hệ số ATR cho chandelier
    
    // Hệ số điều chỉnh trailing
    double TrailingFactorTrend;          // Hệ số trailing trong xu hướng
    double TrailingFactorRanging;        // Hệ số trailing trong sideway
    double TrailingFactorVolatile;       // Hệ số trailing khi biến động cao
    
    // Cấu hình Partial Close - v14.0 cải tiến
    struct PartialCloseConfig {
        bool   UsePartialClose;           // Sử dụng đóng từng phần
        double FirstRMultiple;            // R-multiple cho đóng phần 1 (1.0R)
        double SecondRMultiple;           // R-multiple cho đóng phần 2 (2.0R)
        double FirstClosePercent;         // % đóng ở mức R1 (35%)
        double SecondClosePercent;        // % đóng ở mức R2 (35%)
        bool   MoveToBreakEven;           // Chuyển SL về BE sau khi đóng phần đầu
        double BreakEvenBuffer;           // Buffer cho breakeven (points)
    };
    
    PartialCloseConfig PartialClose;
    
    // Cấu hình News Filter - v14.0
    struct NewsFilterConfig {
        bool   EnableNewsFilter;          // Bật lọc tin tức
        int    HighImpactMinutesBefore;   // Phút trước tin tức tác động cao (30)
        int    HighImpactMinutesAfter;    // Phút sau tin tức tác động cao (15)
        int    MediumImpactMinutesBefore; // Phút trước tin tức tác động trung bình (15)
        int    MediumImpactMinutesAfter;  // Phút sau tin tức tác động trung bình (10)
        string NewsDataFile;              // File dữ liệu tin tức (CSV)
        int    UpdateIntervalHours;       // Thời gian cập nhật tin tức (giờ)
    };
    
    NewsFilterConfig NewsFilter;
    
    // Cấu hình cache
    int    CacheTimeSeconds;             // Thời gian cache theo giây
    bool   UseBartimeCache;              // Sử dụng bar time để cache
    
    // Smart trailing
    struct TrailingConfig {
        bool   EnableSmartTrailing;      // Kích hoạt SmartTrailing
        bool   EnableRMultipleTrailing;  // Kích hoạt trailing theo R-multiple
        double BreakEvenRMultiple;       // R-multiple để đặt BE (1.0R)
        double FirstLockRMultiple;       // R-multiple để khóa lần đầu (1.5R)
        double SecondLockRMultiple;      // R-multiple để khóa lần hai (2.5R)
        double ThirdLockRMultiple;       // R-multiple để khóa lần ba (3.5R)
        double LockPercentageFirst;      // % khóa lần đầu (thường 33%)
        double LockPercentageSecond;     // % khóa lần hai (thường 50%)
        double LockPercentageThird;      // % khóa lần ba (thường 75%)
        double TrailingSensitivity;      // Độ nhạy của trailing (1.0 = tiêu chuẩn)
    };
    
    TrailingConfig Trailing;
    
    // AutoPause - v14.0 cải tiến
    struct AutoPauseConfig {
        bool   EnableAutoPause;           // Kích hoạt tự động dừng
        bool   EnableAutoResume;          // Kích hoạt tự động tiếp tục
        int    ConsecutiveLossesLimit;    // Số lỗ liên tiếp tối đa trước khi dừng
        double DailyLossPercentLimit;     // % lỗ trong ngày tối đa trước khi dừng
        double VolatilitySpikeFactor;     // Hệ số tăng đột biến để pause (3.0 = 300%)
        int    PauseMinutes;              // Số phút dừng
        bool   SkipTradeOnExtremeVolatility; // Bỏ qua trade khi volatility quá cao
        bool   ResumeOnSessionChange;     // Tiếp tục khi chuyển phiên
        bool   ResumeOnNewDay;            // Tiếp tục khi sang ngày mới
    };
    
    AutoPauseConfig AutoPause;
    
    // Cấu hình chu kỳ risk
    bool   EnableWeeklyCycle;            // Bật chu kỳ tuần
    bool   EnableMonthlyCycle;           // Bật chu kỳ tháng
    double WeeklyLossReduceFactor;       // Hệ số giảm risk nếu tuần lỗ
    double MonthlyProfitBoostFactor;     // Hệ số tăng risk nếu tháng lời
    int    ConsecutiveProfitDaysBoost;   // Số ngày lời liên tiếp để tăng
    double MaxCycleRiskBoost;            // Giới hạn tăng risk tối đa
    double MaxCycleRiskReduction;        // Giới hạn giảm risk tối đa
    
    // Cấu hình thêm v14.0
    bool   PropFirmMode;                 // Chế độ Prop Firm (bảo thủ hơn)
    bool   ApplyVolatilityAdjustment;    // Áp dụng điều chỉnh theo biến động
    double SpreadFactorLimit;            // Giới hạn spread (hệ số so với trung bình)
    
    // Constructor với giá trị mặc định
    SRiskOptimizerConfig() {
        RiskPercent = 1.0;
        SL_ATR_Multiplier = 1.5;
        TP_RR_Ratio = 2.0;
        MaxAllowedDrawdown = 10.0;
        
        // Cấu hình pullback mới (v14.0)
        MinPullbackPercent = 20.0;
        MaxPullbackPercent = 70.0;
        RequirePriceAction = true;
        RequireMomentum = false;  // Không bắt buộc, chỉ cần 1 trong 2
        RequireVolume = false;    // Không bắt buộc, chỉ cần 1 trong 2
        
        DrawdownReduceThreshold = 5.0;
        EnableTaperedRisk = true;
        MinRiskMultiplier = 0.3;
        
        UseFixedMaxRiskUSD = false;
        MaxRiskUSD = 500.0;
        MaxRiskPercent = 2.0;
        
        // Cấu hình scaling v14.0
        EnableScaling = true;
        MaxScalingCount = 1;             // Giảm từ 2 xuống 1
        ScalingRiskPercent = 0.3;        // Giảm từ 0.4 xuống 0.3
        RequireBreakEvenForScaling = true;
        ScalingRequiresClearTrend = true; // Thêm mới v14.0
        MinRMultipleForScaling = 1.0;     // Thêm mới v14.0
        
        UseChandelierExit = true;
        ChandelierLookback = 20;
        ChandelierATRMultiplier = 3.0;
        
        TrailingFactorTrend = 1.2;
        TrailingFactorRanging = 0.8;
        TrailingFactorVolatile = 1.5;
        
        CacheTimeSeconds = 10;
        UseBartimeCache = true;
        
        // Cấu hình đóng từng phần v14.0
        PartialClose.UsePartialClose = true;
        PartialClose.FirstRMultiple = 1.0;
        PartialClose.SecondRMultiple = 2.0;
        PartialClose.FirstClosePercent = 35.0;
        PartialClose.SecondClosePercent = 35.0;
        PartialClose.MoveToBreakEven = true;
        PartialClose.BreakEvenBuffer = 5.0;
        
        // Cấu hình lọc tin tức v14.0
        NewsFilter.EnableNewsFilter = true;
        NewsFilter.HighImpactMinutesBefore = 30;
        NewsFilter.HighImpactMinutesAfter = 15;
        NewsFilter.MediumImpactMinutesBefore = 15;
        NewsFilter.MediumImpactMinutesAfter = 10;
        NewsFilter.NewsDataFile = "news_calendar.csv";
        NewsFilter.UpdateIntervalHours = 12;
        
        // Smart trailing mặc định
        Trailing.EnableSmartTrailing = true;
        Trailing.EnableRMultipleTrailing = true;
        Trailing.BreakEvenRMultiple = 1.0;
        Trailing.FirstLockRMultiple = 1.5;
        Trailing.SecondLockRMultiple = 2.5;
        Trailing.ThirdLockRMultiple = 3.5;
        Trailing.LockPercentageFirst = 33.0;
        Trailing.LockPercentageSecond = 50.0;
        Trailing.LockPercentageThird = 75.0;
        Trailing.TrailingSensitivity = 1.0;
        
        // AutoPause mặc định
        AutoPause.EnableAutoPause = true;
        AutoPause.EnableAutoResume = true;
        AutoPause.ConsecutiveLossesLimit = 4;
        AutoPause.DailyLossPercentLimit = 3.0;
        AutoPause.VolatilitySpikeFactor = 3.0;
        AutoPause.PauseMinutes = 120;
        AutoPause.SkipTradeOnExtremeVolatility = true;
        AutoPause.ResumeOnSessionChange = true;
        AutoPause.ResumeOnNewDay = true;
        
        // Chu kỳ risk mặc định
        EnableWeeklyCycle = true;
        EnableMonthlyCycle = true;
        WeeklyLossReduceFactor = 0.8;    // Giảm 20% nếu tuần lỗ
        MonthlyProfitBoostFactor = 1.1;  // Tăng 10% nếu tháng lời
        ConsecutiveProfitDaysBoost = 3;  // Sau 3 ngày lời liên tiếp
        MaxCycleRiskBoost = 1.3;         // Tối đa tăng 30%
        MaxCycleRiskReduction = 0.6;     // Tối thiểu còn 60%
        
        // Cấu hình mới v14.0
        PropFirmMode = false;            // Mặc định tắt
        ApplyVolatilityAdjustment = true;
        SpreadFactorLimit = 2.0;         // Giới hạn spread gấp 2 lần trung bình
    }
};

// Enum cho giai đoạn trailing
enum ENUM_TRAILING_PHASE {
    TRAILING_NONE,            // Chưa trailing
    TRAILING_BREAKEVEN,       // Đã đạt breakeven
    TRAILING_FIRST_LOCK,      // Đã khóa lần đầu
    TRAILING_SECOND_LOCK,     // Đã khóa lần hai
    TRAILING_THIRD_LOCK,      // Đã khóa lần ba
    TRAILING_FULL_TRAILING    // Trailing đầy đủ
};

// Enum cho nguyên nhân pause
enum ENUM_PAUSE_REASON {
    PAUSE_NONE,                // Không pause
    PAUSE_CONSECUTIVE_LOSSES,  // Lỗ liên tiếp
    PAUSE_DAILY_LOSS_LIMIT,    // Lỗ trong ngày
    PAUSE_VOLATILITY_SPIKE,    // Biến động cao
    PAUSE_NEWS_FILTER,         // Tin tức quan trọng (v14.0)
    PAUSE_MANUAL               // Dừng thủ công
};

// Enum cho các chiến lược giao dịch
enum ENUM_TRADING_STRATEGY {
    STRATEGY_BREAKOUT,           // Breakout - khi xu hướng mạnh
    STRATEGY_PULLBACK,           // Pullback - khi xu hướng ổn định
    STRATEGY_MEAN_REVERSION,     // Mean reversion - khi sideway
    STRATEGY_VOLATILITY_BREAKOUT, // Volatility breakout - khi biến động thấp chuẩn bị bùng nổ
    STRATEGY_PRESERVATION        // Preservation - khi thị trường bất ổn
};

// Struct cho trạng thái pause
struct PauseState {
    bool       ShouldPause;             // Có nên pause không
    ENUM_PAUSE_REASON Reason;           // Lý do pause
    int        PauseMinutes;            // Số phút pause
    string     Message;                 // Thông báo
};

// Cập nhật cấu trúc TrailingAction để lưu thông tin trailing
struct TrailingAction {
    bool   ShouldTrail;       // Có nên trailing không
    double NewStopLoss;       // Mức SL mới nếu trailing
    double LockPercentage;    // % lợi nhuận cần khóa
    double RMultiple;         // R-multiple hiện tại
    ENUM_TRAILING_PHASE Phase; // Giai đoạn trailing
};

// Struct cho thông tin tín hiệu và phát hiện pullback chất lượng cao
struct PullbackSignal {
    bool   IsValid;           // Tín hiệu hợp lệ
    bool   IsLong;            // Hướng lệnh (true = mua)
    double EntryPrice;        // Giá vào lệnh
    double StopLoss;          // StopLoss đề xuất
    double TakeProfit;        // TakeProfit đề xuất
    double QualityScore;      // Điểm chất lượng (0.0-1.0)
    bool   HasPriceAction;    // Có xác nhận Price Action
    bool   HasMomentum;       // Có xác nhận Momentum
    bool   HasVolume;         // Có xác nhận Volume
    double PullbackPercent;   // % pullback hiện tại
    string Reason;            // Lý do chi tiết (thành công/thất bại)
};

//====================================================
// SafeDataProvider - Class xử lý dữ liệu an toàn
//====================================================
class CSafeDataProvider {
private:
    string m_Symbol;
    ENUM_TIMEFRAMES m_Timeframe;
    CLogger* m_Logger;
    
    // Cấu trúc cache indicator
    struct CachedIndicator {
        double Value;           // Giá trị
        datetime LastUpdate;    // Thời gian cập nhật
        datetime BarTime;       // Thời gian bar
        bool IsValid;           // Có hợp lệ không
    };
    
    CachedIndicator m_ATRCache;
    CachedIndicator m_ADXCache;
    CachedIndicator m_RSICache;
    
public:
    // Constructor
    CSafeDataProvider(string symbol, ENUM_TIMEFRAMES timeframe, CLogger* logger);
    
    // Hàm lấy dữ liệu an toàn
    double GetSafeATR(CMarketProfile* profile, ENUM_TIMEFRAMES timeframe, int period = 14, bool forceUpdate = false);
    double GetSafeADX(CMarketProfile* profile, ENUM_TIMEFRAMES timeframe, int period = 14, bool forceUpdate = false);
    double GetSafeVolatilityRatio(CMarketProfile* profile, double averageATR);
    ENUM_SESSION GetSafeCurrentSession(CMarketProfile* profile);
    datetime GetCurrentBarTime(ENUM_TIMEFRAMES timeframe);
    bool DetectVolatilitySpike(double threshold = 1.5);
    
    // Thêm mới v14.0: Hàm lấy dữ liệu đặc trưng tài sản
    double GetSafeSymbolATRPoints(string symbol);
    double GetSafeSymbolSpreadAverage(string symbol);
    double GetSafeSymbolMinStopLevel(string symbol);
    
    // Thêm mới v14.0: Phát hiện phiên đặc biệt
    bool IsLondonOpen();
    bool IsNewYorkOpen();
    bool IsAsianOpen();
};

//====================================================
// Class: CRiskOptimizer v14.0
//====================================================
class CRiskOptimizer {
private:
    CMarketProfile*      m_Profile;          // pointer tới MarketProfile
    CSwingPointDetector* m_SwingDetector;    // pointer tới SwingPointDetector
    CLogger*             m_Logger;           // pointer tới Logger
    CSafeDataProvider*   m_SafeData;         // Safe Data Provider
    CAssetProfiler*      m_AssetProfiler;    // Asset Profiler (mới v14.0)
    CNewsFilter*         m_NewsFilter;       // News Filter (mới v14.0)
    
    string   m_Symbol;               // Symbol đang giao dịch
    ENUM_TIMEFRAMES m_MainTimeframe; // Timeframe chính
    
    // Cấu hình Risk Optimizer
    SRiskOptimizerConfig m_Config;
    
    // Biến cho tính toán
    double   m_AverageATR;           // ATR trung bình (20 ngày), dùng để đánh giá biến động
    
    // Cache và theo dõi thời gian
    double   m_LastATR;              // ATR hiện tại đã tính toán
    double   m_LastVolatilityRatio;  // Tỷ lệ biến động hiện tại
    datetime m_LastCalculationTime;  // Thời gian lần tính toán trước
    datetime m_LastBarTime;          // Thời gian bar gần nhất
    
    // Biến chu kỳ tuần/tháng
    double   m_WeeklyProfit;            // Lợi nhuận tuần này
    double   m_MonthlyProfit;           // Lợi nhuận tháng này
    int      m_ConsecutiveProfitDays;   // Số ngày lời liên tiếp
    datetime m_LastWeekMonday;          // Thứ 2 của tuần hiện tại
    int      m_CurrentMonth;            // Tháng hiện tại đang theo dõi
    
    // Biến trạng thái pause
    bool       m_IsPaused;                  // EA đang pause
    datetime   m_PauseUntil;                // Thời gian dừng đến khi nào
    ENUM_SESSION m_LastSession;             // Phiên giao dịch cuối
    int        m_LastTradeDay;              // Ngày giao dịch cuối
    double     m_DayStartBalance;           // Số dư đầu ngày
    double     m_CurrentDailyLoss;          // Lỗ hiện tại trong ngày
    
    // Biến theo dõi trailing
    double    m_LastTrailingStop;           // SL trailing gần nhất
    ENUM_TRAILING_PHASE m_CurrentTrailingPhase; // Giai đoạn trailing hiện tại
    
    // Cache trading strategy
    ENUM_TRADING_STRATEGY m_CurrentStrategy; // Chiến lược hiện tại
    datetime m_LastStrategyUpdateTime;      // Thời gian cập nhật chiến lược
    
    // Thêm mới v14.0: Các biến theo dõi nâng cao
    int      m_ConsecutiveLosses;           // Số lần thua liên tiếp
    int      m_TotalTradesDay;              // Tổng số lệnh trong ngày
    double   m_SpreadHistory[10];           // Lịch sử spread gần đây
    bool     m_IsNewBar;                    // Đánh dấu bar mới
    int      m_ScalingCount;                // Số lần đã scaling
    
    // Hàm xử lý nội bộ
    double NormalizeLotSize(double lotSize);
    double GetVolatilityAdjustmentFactor();
    double GetValidATR();
    double CalculateQualityBasedRiskMultiplier(double signalQuality);
    double GetSLMultiplierForCluster(ENUM_CLUSTER_TYPE cluster);
    double GetTPMultiplierForCluster(ENUM_CLUSTER_TYPE cluster);
    double GetTrailingFactorForRegime(ENUM_MARKET_REGIME regime);
    double CalculateSessionRiskAdjustment(ENUM_SESSION session);
    bool   NeedToUpdateCache();
    bool   IsOptimalTradingTime();
    bool   DetectSuddenVolatilitySpike();
    void   ReleaseHandles();
    
    // Thêm mới v14.0: Hàm xử lý Pullback Chất Lượng Cao
    bool ValidatePullbackZone(double currentPrice, bool isLong, const MarketProfileData &profile);
    bool ValidatePriceAction(bool isLong);
    bool ValidateMomentum(bool isLong, const MarketProfileData &profile);
    bool ValidateVolume(bool isLong);
    double CalculatePullbackPercent(double currentPrice, bool isLong, const MarketProfileData &profile);
    
public:
    // ===== Khởi tạo và cập nhật =====
    CRiskOptimizer();
    ~CRiskOptimizer();
    
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, double riskPercent, double atrMultSL, double atrMultTP);
    bool SetSwingPointDetector(CSwingPointDetector* swingDetector);
    void UpdateMarketProfile(CMarketProfile* profile);
    void SetLogger(CLogger* logger) { m_Logger = logger; }
    CLogger* GetLogger() const { return m_Logger; }
    
    // Thêm mới v14.0: Thiết lập AssetProfiler và NewsFilter
    bool SetAssetProfiler(CAssetProfiler* assetProfiler);
    bool SetNewsFilter(CNewsFilter* newsFilter);
    
    // ===== Thiết lập cấu hình =====
    void SetConfig(const SRiskOptimizerConfig &config) { m_Config = config; }
    SRiskOptimizerConfig GetConfig() const { return m_Config; }
    void SetDrawdownParameters(double threshold, bool enableTapered, double minRiskMultiplier);
    void SetChandelierExit(bool useChande, int lookback, double atrMult);
    void SetAverageATR(double avgATR) { m_AverageATR = avgATR; }
    void SetRiskLimits(bool useFixedUSD, double maxUSD, double maxPercent);
    
    // Thêm mới v14.0: Cấu hình nâng cao
    void SetScalingParameters(bool enable, int maxCount, double riskPercent, 
                             bool requireBE, bool requireTrend, double minRMultiple);
    void SetPartialCloseParameters(bool enable, double r1, double r2, 
                                  double percent1, double percent2, bool moveToBE);
    void SetNewsFilterParameters(bool enable, int highBefore, int highAfter, 
                                int mediumBefore, int mediumAfter, string dataFile);
    void EnablePropFirmMode(bool enable);
    
    // ===== Tính khối lượng và SL/TP =====
    double CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                           double signalQuality = 1.0, double riskPercentOverride = 0.0);
    double CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                  bool applyVolatilityAdjustment, double maxVolFactor, 
                                  double minLotMultiplier, double signalQuality = 1.0);
    
    bool CalculateSLTP(double entryPrice, bool isLong, double& stopLoss, double& takeProfit, 
                      ENUM_CLUSTER_TYPE cluster);
    
    // ===== Phát hiện Pullback Chất Lượng Cao (v14.0) =====
    PullbackSignal DetectQualityPullback(const MarketProfileData &profile);
    double CalculateSignalQuality(const PullbackSignal &signal);
    bool IsValidPullbackSetup(bool isLong, const MarketProfileData &profile);
    
    // ===== Dynamic Adjustment =====
    void AdjustSLTPBasedOnVolatility(double& stopLoss, double& takeProfit, bool isLong);
    void AdjustSLTPBasedOnCluster(double& stopLoss, double& takeProfit, bool isLong, ENUM_CLUSTER_TYPE cluster);
    void AdjustSLTPBasedOnSession(double& stopLoss, double& takeProfit, bool isLong, ENUM_SESSION session);
    void AdjustSLTPByStrategy(double& stopLoss, double& takeProfit, bool isLong, ENUM_TRADING_STRATEGY strategy);
    double AdjustRiskPercentByMarketRegime(ENUM_MARKET_REGIME regime, double baseRiskPercent);
    double AdjustRiskPercentByDrawdown(double currentDrawdown, double baseRiskPercent);
    
    // ===== Quản lý trailing stop =====
    double CalculateTrailingStop(double currentPrice, double openPrice, double atr, bool isLong, 
                               ENUM_MARKET_REGIME regime);
    double CalculateChandelierExit(bool isLong, double openPrice, double currentPrice);
    TrailingAction CalculateSmartTrailing(double entryPrice, double currentPrice, 
                                        double stopLoss, bool isLong, 
                                        ENUM_MARKET_REGIME regime);
    
    // ===== Quản lý đóng lệnh một phần (v14.0) =====
    bool ShouldPartialClose(ulong ticket, double entryPrice, double currentPrice, 
                          double stopLoss, bool isLong, int& closePhase, double& closePercent);
    bool ShouldMoveToBreakEven(double entryPrice, double currentPrice, double stopLoss, bool isLong);
    
    // ===== Quản lý Scaling (v14.0) =====
    bool ShouldScalePosition(ulong ticket, double currentPrice, double entryPrice, double stopLoss, 
                           bool isLong, const MarketProfileData &profile);
    double CalculateScalingLotSize(ulong ticket, double baseRiskPercent, double entryPrice, 
                                 double stopLoss, bool isLong);
    
    // ===== Structure-based SL/TP =====
    bool FindSwingPoints(bool isLong, int lookbackBars, double &swingLevel, int &swingBar);
    bool CalculateSLTPByStructure(double entryPrice, bool isLong, double &stopLoss, double &takeProfit);
    bool CalculateHybridSLTP(double entryPrice, bool isLong, double &stopLoss, double &takeProfit, 
                           ENUM_CLUSTER_TYPE cluster);
    
    // ===== Lọc tin tức (v14.0) =====
    bool ShouldAvoidTradingDueToNews(ENUM_SESSION currentSession);
    bool IsHighImpactNewsTime();
    bool IsMediumImpactNewsTime();
    
    // ===== Smart Risk Management =====
    double ApplySmartRisk(double baseRiskPercent, int consecutiveLosses, double winRate, 
                        ENUM_CLUSTER_TYPE cluster, ENUM_MARKET_REGIME regime);
    double ApplyCyclicalRisk(double baseRiskPercent);
    
    // ===== Chu kỳ thời gian và cập nhật trạng thái =====
    void UpdateTimeCycles();
    void UpdateTradingResult(bool isWin, double profit);
    void UpdateDailyState();
    void UpdateDailyLoss();
    void SetConsecutiveLosses(int losses) { m_ConsecutiveLosses = losses; }
    
    // ===== Thông tin tài sản (v14.0) =====
    bool IsSpreadAcceptable();
    bool IsVolatilityAcceptable();
    double GetAverageSpread();
    double GetSymbolRiskAdjustment();
    
    // ===== AutoPause/AutoResume =====
    PauseState CheckPauseCondition(int consecutiveLosses, double dailyLoss);
    void SetPauseState(PauseState &state);
    bool CheckResumeCondition();
    bool IsPaused() const { return m_IsPaused; }
    datetime GetPauseUntil() const { return m_PauseUntil; }
    
    // ===== Market Regime Switching =====
    ENUM_TRADING_STRATEGY DetermineOptimalStrategy(ENUM_MARKET_REGIME regime, 
                                                  double volatilityRatio,
                                                  double regimeConfidence);
    
    // ===== Set/Get Methods =====
    void SetRiskPercent(double riskPercent) { m_Config.RiskPercent = riskPercent; }
    double GetRiskPercent() const { return m_Config.RiskPercent; }
    double GetVolatilityRatio() { return m_LastVolatilityRatio > 0 ? m_LastVolatilityRatio : GetVolatilityAdjustmentFactor(); }
    
    void SetSLATRMultiplier(double multiplier) { m_Config.SL_ATR_Multiplier = multiplier; }
    double GetSLATRMultiplier() const { return m_Config.SL_ATR_Multiplier; }
    
    void SetTPRRRatio(double multiplier) { m_Config.TP_RR_Ratio = multiplier; }
    double GetTPRRRatio() const { return m_Config.TP_RR_Ratio; }
    
    void SetTrailingMultiplier(double multiplier) { 
        m_Config.TrailingFactorTrend = multiplier; 
        m_Config.TrailingFactorRanging = multiplier * 0.7;
        m_Config.TrailingFactorVolatile = multiplier * 1.3;
    }
    
    // ===== Công cụ hỗ trợ =====
    double CalculateDynamicSL(bool isLong, double atr, double entryPrice, ENUM_MARKET_REGIME regime);
    double CalculateDynamicTP(bool isLong, double atr, double entryPrice, ENUM_MARKET_REGIME regime);
    double CalculateRMultiple(double entryPrice, double currentPrice, double stopLoss, bool isLong);
    void ExportPerformanceStats(string filename = "");
    bool IsNewBar() { return m_IsNewBar; }
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo với thông số mặc định nâng cao            |
//+------------------------------------------------------------------+
CRiskOptimizer::CRiskOptimizer() : 
    m_Profile(NULL),
    m_SwingDetector(NULL),
    m_Logger(NULL),
    m_SafeData(NULL),
    m_AssetProfiler(NULL),   // Mới v14.0
    m_NewsFilter(NULL),      // Mới v14.0
    m_Symbol(""),
    m_MainTimeframe(PERIOD_H4),
    m_AverageATR(0.0),
    m_LastATR(0.0),
    m_LastVolatilityRatio(1.0),
    m_LastCalculationTime(0),
    m_LastBarTime(0),
    m_WeeklyProfit(0.0),
    m_MonthlyProfit(0.0),
    m_ConsecutiveProfitDays(0),
    m_LastWeekMonday(0),
    m_CurrentMonth(0),
    m_IsPaused(false),
    m_PauseUntil(0),
    m_LastSession(SESSION_UNKNOWN),
    m_LastTradeDay(0),
    m_DayStartBalance(0.0),
    m_CurrentDailyLoss(0.0),
    m_LastTrailingStop(0.0),
    m_CurrentTrailingPhase(TRAILING_NONE),
    m_CurrentStrategy(STRATEGY_PULLBACK),
    m_LastStrategyUpdateTime(0),
    m_ConsecutiveLosses(0),
    m_TotalTradesDay(0),
    m_IsNewBar(false),
    m_ScalingCount(0)
{
    // Khởi tạo config với giá trị mặc định
    m_Config = SRiskOptimizerConfig();
    
    // Khởi tạo mảng lưu trữ spread
    for (int i = 0; i < 10; i++) {
        m_SpreadHistory[i] = 0;
    }
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskOptimizer::~CRiskOptimizer()
{
    // Giải phóng các handles trước khi xóa đối tượng
    ReleaseHandles();
    
    // Giải phóng bộ nhớ SafeDataProvider
    if (m_SafeData != NULL) {
        delete m_SafeData;
        m_SafeData = NULL;
    }
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo RiskOptimizer                              |
//+------------------------------------------------------------------+
bool CRiskOptimizer::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, double riskPercent, double atrMultSL, double atrMultTP)
{
    m_Symbol = symbol;
    m_MainTimeframe = timeframe;
    m_Config.RiskPercent = riskPercent;
    m_Config.SL_ATR_Multiplier = atrMultSL;
    m_Config.TP_RR_Ratio = atrMultTP;
    
    // Nếu logger chưa được khởi tạo, tạo logger mới
    if (m_Logger == NULL) {
        m_Logger = new CLogger("RiskOptimizer");
        if (m_Logger == NULL) {
            Print("ERROR: Không thể tạo Logger");
            return false;
        }
    }
    
    // Khởi tạo SafeDataProvider
    m_SafeData = new CSafeDataProvider(symbol, timeframe, m_Logger);
    if (m_SafeData == NULL) {
        if (m_Logger != NULL) {
            m_Logger.LogError("Không thể khởi tạo SafeDataProvider");
        }
        return false;
    }
    
    // Khởi tạo các biến trạng thái
    m_IsPaused = false;
    m_PauseUntil = 0;
    m_LastSession = SESSION_UNKNOWN;
    m_LastTradeDay = 0;
    m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_CurrentDailyLoss = 0.0;
    m_ConsecutiveLosses = 0;
    m_TotalTradesDay = 0;
    m_ScalingCount = 0;
    
    // Cập nhật trạng thái ngày
    UpdateDailyState();
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "RiskOptimizer v14.0 khởi tạo: %s, Risk=%.2f%%, SL ATR=%.2f, TP RR=%.2f", 
            m_Symbol, m_Config.RiskPercent, m_Config.SL_ATR_Multiplier, m_Config.TP_RR_Ratio
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| SetSwingPointDetector - Thiết lập Swing Point Detector           |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetSwingPointDetector(CSwingPointDetector* swingDetector)
{
    if (swingDetector == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập SwingPointDetector (NULL)");
        return false;
    }
    
    m_SwingDetector = swingDetector;
    return true;
}

//+------------------------------------------------------------------+
//| SetAssetProfiler - Thiết lập Asset Profiler (mới v14.0)          |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetAssetProfiler(CAssetProfiler* assetProfiler)
{
    if (assetProfiler == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập AssetProfiler (NULL)");
        return false;
    }
    
    m_AssetProfiler = assetProfiler;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("AssetProfiler được thiết lập thành công");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| SetNewsFilter - Thiết lập News Filter (mới v14.0)                |
//+------------------------------------------------------------------+
bool CRiskOptimizer::SetNewsFilter(CNewsFilter* newsFilter)
{
    if (newsFilter == NULL) {
        if (m_Logger != NULL) m_Logger.LogError("Không thể thiết lập NewsFilter (NULL)");
        return false;
    }
    
    m_NewsFilter = newsFilter;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("NewsFilter được thiết lập thành công");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdateMarketProfile - Cập nhật liên kết tới Market Profile       |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateMarketProfile(CMarketProfile* profile)
{
    m_Profile = profile;
    
    // Kiểm tra bar mới khi cập nhật profile
    static datetime lastBarTime = 0;
    datetime currentBarTime = 0;
    
    if (m_SafeData != NULL) {
        currentBarTime = m_SafeData.GetCurrentBarTime(m_MainTimeframe);
        if (currentBarTime > 0 && currentBarTime != lastBarTime) {
            m_IsNewBar = true;
            lastBarTime = currentBarTime;
        } else {
            m_IsNewBar = false;
        }
    }
    
    // Tính toán tỷ lệ biến động (Volatility Ratio) mới
    if (m_IsNewBar || m_LastVolatilityRatio <= 0) {
        m_LastVolatilityRatio = GetVolatilityAdjustmentFactor();
    }
}

//+------------------------------------------------------------------+
//| SetDrawdownParameters - Thiết lập các tham số điều chỉnh risk DD |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetDrawdownParameters(double threshold, bool enableTapered, double minRiskMultiplier)
{
    m_Config.DrawdownReduceThreshold = threshold;
    m_Config.EnableTaperedRisk = enableTapered;
    m_Config.MinRiskMultiplier = minRiskMultiplier;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập DrawdownParameters: Threshold=%.2f%%, Tapered=%s, MinMultiplier=%.2f", 
            m_Config.DrawdownReduceThreshold, m_Config.EnableTaperedRisk ? "true" : "false", m_Config.MinRiskMultiplier
        ));
    }
}

//+------------------------------------------------------------------+
//| SetChandelierExit - Thiết lập thông số Chandelier Exit           |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetChandelierExit(bool useChande, int lookback, double atrMult)
{
    m_Config.UseChandelierExit = useChande;
    m_Config.ChandelierLookback = lookback;
    m_Config.ChandelierATRMultiplier = atrMult;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Chandelier Exit: Enabled=%s, Lookback=%d, AtrMultiplier=%.2f", 
            m_Config.UseChandelierExit ? "true" : "false", m_Config.ChandelierLookback, m_Config.ChandelierATRMultiplier
        ));
    }
}

//+------------------------------------------------------------------+
//| SetRiskLimits - Thiết lập giới hạn risk                          |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetRiskLimits(bool useFixedUSD, double maxUSD, double maxPercent)
{
    m_Config.UseFixedMaxRiskUSD = useFixedUSD;
    m_Config.MaxRiskUSD = maxUSD;
    m_Config.MaxRiskPercent = maxPercent;
    
    if (m_Logger != NULL) {
        string limitType = useFixedUSD ? "USD cố định" : "% Balance";
        string limitValue = useFixedUSD ? "$" + DoubleToString(maxUSD, 2) : DoubleToString(maxPercent, 2) + "%";
        
        m_Logger.LogInfo(StringFormat(
            "Thiết lập giới hạn risk: Loại=%s, Giá trị=%s", 
            limitType, limitValue
        ));
    }
}

//+------------------------------------------------------------------+
//| SetScalingParameters - Thiết lập tham số nhồi lệnh (v14.0)       |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetScalingParameters(bool enable, int maxCount, double riskPercent, 
                                        bool requireBE, bool requireTrend, double minRMultiple)
{
    // Thiết lập các tham số scaling
    m_Config.EnableScaling = enable;
    m_Config.MaxScalingCount = maxCount;
    m_Config.ScalingRiskPercent = riskPercent;
    m_Config.RequireBreakEvenForScaling = requireBE;
    m_Config.ScalingRequiresClearTrend = requireTrend;
    m_Config.MinRMultipleForScaling = minRMultiple;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Scaling: Enable=%s, MaxCount=%d, Risk=%.2f%%, RequireBE=%s, RequireTrend=%s, MinRMultiple=%.1f",
            enable ? "true" : "false", maxCount, riskPercent, 
            requireBE ? "true" : "false", requireTrend ? "true" : "false", minRMultiple
        ));
    }
}

//+------------------------------------------------------------------+
//| SetPartialCloseParameters - Thiết lập đóng từng phần (v14.0)     |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetPartialCloseParameters(bool enable, double r1, double r2, 
                                             double percent1, double percent2, bool moveToBE)
{
    // Thiết lập tham số đóng từng phần
    m_Config.PartialClose.UsePartialClose = enable;
    m_Config.PartialClose.FirstRMultiple = r1;
    m_Config.PartialClose.SecondRMultiple = r2;
    m_Config.PartialClose.FirstClosePercent = percent1;
    m_Config.PartialClose.SecondClosePercent = percent2;
    m_Config.PartialClose.MoveToBreakEven = moveToBE;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập Partial Close: Enable=%s, R1=%.1f, R2=%.1f, %%1=%.1f, %%2=%.1f, MoveBE=%s",
            enable ? "true" : "false", r1, r2, percent1, percent2, moveToBE ? "true" : "false"
        ));
    }
}

//+------------------------------------------------------------------+
//| SetNewsFilterParameters - Thiết lập lọc tin tức (v14.0)          |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetNewsFilterParameters(bool enable, int highBefore, int highAfter, 
                                           int mediumBefore, int mediumAfter, string dataFile)
{
    // Thiết lập tham số lọc tin tức
    m_Config.NewsFilter.EnableNewsFilter = enable;
    m_Config.NewsFilter.HighImpactMinutesBefore = highBefore;
    m_Config.NewsFilter.HighImpactMinutesAfter = highAfter;
    m_Config.NewsFilter.MediumImpactMinutesBefore = mediumBefore;
    m_Config.NewsFilter.MediumImpactMinutesAfter = mediumAfter;
    m_Config.NewsFilter.NewsDataFile = dataFile;
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Thiết lập News Filter: Enable=%s, HighBefore=%d, HighAfter=%d, MediumBefore=%d, MediumAfter=%d, File=%s",
            enable ? "true" : "false", highBefore, highAfter, mediumBefore, mediumAfter, dataFile
        ));
    }
    
    // Áp dụng cấu hình vào NewsFilter object nếu có
    if (m_NewsFilter != NULL && enable) {
        m_NewsFilter.Configure(highBefore, highAfter, mediumBefore, mediumAfter);
    }
}

//+------------------------------------------------------------------+
//| EnablePropFirmMode - Bật/tắt chế độ Prop Firm (v14.0)            |
//+------------------------------------------------------------------+
void CRiskOptimizer::EnablePropFirmMode(bool enable)
{
    m_Config.PropFirmMode = enable;
    
    // Điều chỉnh các tham số khác để phù hợp với Prop Firm mode
    if (enable) {
        // Chế độ Prop Firm: Bảo thủ hơn, bảo vệ vốn là ưu tiên hàng đầu
        m_Config.MaxRiskPercent = MathMin(m_Config.MaxRiskPercent, 1.5);  // Giới hạn tối đa 1.5%
        m_Config.DrawdownReduceThreshold = MathMin(m_Config.DrawdownReduceThreshold, 5.0); // Bắt đầu giảm risk sớm hơn
        m_Config.MaxAllowedDrawdown = MathMin(m_Config.MaxAllowedDrawdown, 8.0); // DD tối đa thấp hơn
        m_Config.AutoPause.DailyLossPercentLimit = MathMin(m_Config.AutoPause.DailyLossPercentLimit, 3.0); // Giới hạn lỗ ngày thấp hơn
        m_Config.ScalingRiskPercent = 0.25; // Giảm risk khi scaling nhiều hơn
        m_Config.EnableWeeklyCycle = true;  // Bật chu kỳ weekly
        m_Config.WeeklyLossReduceFactor = 0.7; // Giảm risk mạnh hơn khi tuần lỗ
    }
    
    if (m_Logger != NULL) {
        if (enable) {
            m_Logger.LogInfo("Đã bật chế độ Prop Firm - Tăng cường bảo vệ vốn");
        } else {
            m_Logger.LogInfo("Đã tắt chế độ Prop Firm");
        }
    }
}

//+------------------------------------------------------------------+
//| Giải phóng các handles tài nguyên                                |
//+------------------------------------------------------------------+
void CRiskOptimizer::ReleaseHandles() {
    // Giải phóng tất cả indicator handles nếu có
    if (m_Logger != NULL) {
        m_Logger.LogDebug("Giải phóng indicator handles trong RiskOptimizer");
    }
}

//+------------------------------------------------------------------+
//| Get valid ATR value with fallback                                |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetValidATR()
{
    // Kiểm tra xem có cần cập nhật cache không
    if (!NeedToUpdateCache() && m_LastATR > 0) {
        return m_LastATR; // Sử dụng cache
    }
    
    // Ưu tiên lấy ATR từ AssetProfiler (nếu có)
    if (m_AssetProfiler != NULL) {
        double assetATR = m_AssetProfiler.GetAssetATR(m_Symbol, m_MainTimeframe);
        if (assetATR > 0) {
            // Cập nhật cache và trả về giá trị
            m_LastATR = assetATR;
            m_LastCalculationTime = TimeCurrent();
            return assetATR;
        }
    }
    
    // Dùng SafeDataProvider để lấy ATR an toàn
    double atr = 0;
    if (m_SafeData != NULL) {
        atr = m_SafeData.GetSafeATR(m_Profile, m_MainTimeframe);
    } else {
        // Fallback nếu SafeDataProvider chưa được khởi tạo
        
        // Kiểm tra xem Market Profile có hợp lệ không
        if (m_Profile != NULL) {
            atr = m_Profile.GetATRH4();
        }
        
        // Nếu không có giá trị hợp lệ, thử lấy giá trị từ thời gian hiện tại
        if (atr <= 0) {
            int handle = iATR(m_Symbol, m_MainTimeframe, 14);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    atr = buffer[0];
                }
                IndicatorRelease(handle);
            }
            
            if (atr <= 0) {
                // Fallback cuối cùng
                atr = SymbolInfoDouble(m_Symbol, SYMBOL_POINT) * 100;
                if (m_Logger != NULL) m_Logger.LogWarning("Sử dụng giá trị ATR dự phòng");
            }
        }
    }
    
    // Cập nhật giá trị cache
    m_LastATR = atr;
    m_LastCalculationTime = TimeCurrent();
    
    return atr;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có cần cập nhật cache                               |
//+------------------------------------------------------------------+
bool CRiskOptimizer::NeedToUpdateCache()
{
    datetime currentTime = TimeCurrent();
    
    // Đánh dấu các bar mới - phương pháp hiệu quả nhất
    datetime currentBarTime = 0;
    
    if (m_SafeData != NULL) {
        currentBarTime = m_SafeData.GetCurrentBarTime(m_MainTimeframe);
        
        // Nếu bar mới, luôn cập nhật cache
        if (currentBarTime > 0 && currentBarTime != m_LastBarTime) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug("Cập nhật cache do bar mới");
            }
            m_LastBarTime = currentBarTime;
            return true;
        }
    }
    
    // Kiểm tra theo thời gian cache
    if (m_LastCalculationTime == 0 || 
        (currentTime - m_LastCalculationTime) >= m_Config.CacheTimeSeconds) {
        return true;
    }
    
    // Phát hiện biến động mạnh bất thường (cần cập nhật cache gấp)
    if (DetectSuddenVolatilitySpike()) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Cập nhật cache do phát hiện biến động đột biến");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện biến động đột biến để cập nhật cache                   |
//+------------------------------------------------------------------+
bool CRiskOptimizer::DetectSuddenVolatilitySpike()
{
    // Tính tỷ lệ biến động mới 
    double currentATR = 0;
    
    int atrHandle = iATR(m_Symbol, m_MainTimeframe, 14);
    if (atrHandle == INVALID_HANDLE) {
        return false;
    }
    
    double buffer[];
    ArraySetAsSeries(buffer, true);
    
    if (CopyBuffer(atrHandle, 0, 0, 1, buffer) <= 0) {
        IndicatorRelease(atrHandle);
        return false;
    }
    
    currentATR = buffer[0];
    IndicatorRelease(atrHandle);
    
    if (currentATR > 0 && m_LastATR > 0) {
        // Nếu ATR tăng hơn 50% trong thời gian ngắn - dấu hiệu biến động đột biến
        if (currentATR > m_LastATR * 1.5) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get volatility adjustment factor with improved handling          |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetVolatilityAdjustmentFactor()
{
    // Kiểm tra cache
    if (!NeedToUpdateCache() && m_LastVolatilityRatio > 0) {
        return m_LastVolatilityRatio;
    }
    
    // Ưu tiên lấy volatility ratio từ AssetProfiler
    if (m_AssetProfiler != NULL) {
        double assetVolatilityRatio = m_AssetProfiler.GetVolatilityRatio(m_Symbol);
        if (assetVolatilityRatio > 0) {
            m_LastVolatilityRatio = assetVolatilityRatio;
            return assetVolatilityRatio;
        }
    }
    
    // Lấy volatility ratio từ SafeDataProvider nếu có
    double volatilityRatio = 1.0;
    if (m_SafeData != NULL) {
        volatilityRatio = m_SafeData.GetSafeVolatilityRatio(m_Profile, m_AverageATR);
    } else if (m_Profile != NULL) {
        // Thử lấy từ profile
        volatilityRatio = m_Profile.GetVolatilityRatio();
        
        // Nếu không lấy được, tính thủ công
        if (volatilityRatio <= 0 && m_AverageATR > 0) {
            double currentATR = GetValidATR();
            if (currentATR > 0) {
                volatilityRatio = currentATR / m_AverageATR;
            }
        }
    }
    
    // Nếu vẫn không có tỷ lệ biến động hợp lệ, trả về 1.0 (không điều chỉnh)
    if (volatilityRatio <= 0) return 1.0;
    
    // Phát hiện và xử lý biến động bất thường
    if (volatilityRatio > 3.0) {
        if (m_Logger != NULL) {
            m_Logger.LogWarning(StringFormat(
                "Phát hiện biến động bất thường: %.2f lần so với bình thường. Áp dụng giới hạn.",
                volatilityRatio
            ));
        }
        
        // Giới hạn lại tỷ lệ biến động
        volatilityRatio = 3.0;
    }
    
    // Tính hệ số điều chỉnh:
    // - Biến động thấp (< 0.8): tăng nhẹ (lên tới 1.2)
    // - Biến động vừa (0.8-1.2): giữ nguyên
    // - Biến động cao (> 1.2): giảm dần (xuống tới 0.7)
    // - Biến động rất cao (> 2.0): giới hạn ở 0.5
    double adjustmentFactor = 1.0;
    
    if (volatilityRatio < 0.8) {
        // Biến động thấp: tăng SL/TP nhưng không quá 1.2
        adjustmentFactor = 1.0 + (0.8 - volatilityRatio) * 0.5;
        adjustmentFactor = MathMin(adjustmentFactor, 1.2);
    }
    else if (volatilityRatio > 1.2) {
        // Biến động cao: giảm SL/TP
        if (volatilityRatio < 2.0) {
            // Áp dụng công thức bậc hai để giảm dần
            adjustmentFactor = 1.0 - (volatilityRatio - 1.2) * 0.25;
        } else {
            // Với biến động rất cao, giới hạn dưới 0.5
            adjustmentFactor = 0.5;
        }
    }
    
    // Cập nhật cache
    m_LastVolatilityRatio = volatilityRatio;
    
    return adjustmentFactor;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk management rules                |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                       double signalQuality, double riskPercentOverride)
{
    if (stopLossPoints <= 0 || entryPrice <= 0) {
        if (m_Logger != NULL) {
            m_Logger.LogError(StringFormat(
                "Giá trị entryPrice (%.5f) hoặc stopLossPoints (%.1f) không hợp lệ trong CalculateLotSize", 
                entryPrice, stopLossPoints
            ));
        }
        return 0.01; // Trả về khối lượng tối thiểu làm giá trị dự phòng
    }
    
    // Ưu tiên lấy lot size từ AssetProfiler nếu có
    if (m_AssetProfiler != NULL && riskPercentOverride <= 0) {
        double assetLotSize = m_AssetProfiler.CalculateLotSize(
            symbol, stopLossPoints, m_Config.RiskPercent, signalQuality
        );
        
        if (assetLotSize > 0) {
            return assetLotSize;
        }
    }
    
    // Lấy thông tin tài khoản
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (balance <= 0) {
        if (m_Logger != NULL) m_Logger.LogWarning("Số dư tài khoản không hợp lệ, sử dụng vốn thay thế");
        balance = AccountInfoDouble(ACCOUNT_EQUITY);
    }
    
    // Sử dụng risk percent override nếu được cung cấp
    double risk = (riskPercentOverride > 0) ? riskPercentOverride : m_Config.RiskPercent;
    
    // Điều chỉnh risk dựa trên chất lượng tín hiệu (0.5 - 1.5)
    double qualityMultiplier = CalculateQualityBasedRiskMultiplier(signalQuality);
    risk *= qualityMultiplier;
    
    // Điều chỉnh risk dựa trên đặc tính symbol
    if (m_AssetProfiler != NULL) {
        double symbolRiskFactor = m_AssetProfiler.GetSymbolRiskFactor(symbol);
        if (symbolRiskFactor > 0) {
            risk *= symbolRiskFactor;
        }
    }
    
    // Tính toán số tiền rủi ro
    double riskAmount = balance * (risk / 100.0);
    
    // Kiểm tra giới hạn risk
    if (m_Config.UseFixedMaxRiskUSD) {
        // Giới hạn cố định USD
        if (riskAmount > m_Config.MaxRiskUSD) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Giới hạn rủi ro từ $%.2f xuống $%.2f (giới hạn tối đa/lệnh)",
                    riskAmount, m_Config.MaxRiskUSD
                ));
            }
            riskAmount = m_Config.MaxRiskUSD;
        }
    } else {
        // Giới hạn % theo balance
        double maxRiskAmount = balance * (m_Config.MaxRiskPercent / 100.0);
        if (riskAmount > maxRiskAmount) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Giới hạn rủi ro từ $%.2f xuống $%.2f (%.2f%% tối đa)",
                    riskAmount, maxRiskAmount, m_Config.MaxRiskPercent
                ));
            }
            riskAmount = maxRiskAmount;
        }
    }
    
    // Lấy giá trị tick
    double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
    if (tickValue <= 0) {
        if (m_Logger != NULL) m_Logger.LogError("Giá trị tick không hợp lệ");
        return 0.01;
    }
    
    // Tính toán khối lượng
    double lotSize = riskAmount / (stopLossPoints * tickValue);
    
    // Chuẩn hóa lot size theo quy tắc của sàn
    lotSize = NormalizeLotSize(lotSize);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Tính khối lượng: Risk=%.2f%% (QualityMultiplier=%.2f), Số tiền=%.2f, SL Points=%.1f, Kết quả=%.2f lots",
            risk, qualityMultiplier, riskAmount, stopLossPoints, lotSize
        ));
    }
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic Lot Size with volatility adjustment            |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                              bool applyVolatilityAdjustment, double maxVolFactor, 
                                              double minLotMultiplier, double signalQuality)
{
    // Tính lot size ban đầu
    double baseLotSize = CalculateLotSize(symbol, stopLossPoints, entryPrice, signalQuality);
    
    // Nếu không áp dụng điều chỉnh biến động, trả về lot size cơ bản
    if (!applyVolatilityAdjustment) {
        return baseLotSize;
    }
    
    // Lấy tỷ lệ biến động từ cache hoặc tính mới
    double volatilityRatio = GetVolatilityRatio();
    
    // Điều chỉnh dựa trên tỷ lệ biến động
    double adjustedLotSize = baseLotSize;
    double reductionFactor = 1.0;
    
    // Biến động cực cao - có thể skip trade
    if (volatilityRatio > 3.0) {
        if (m_Config.AutoPause.SkipTradeOnExtremeVolatility) {
            if (m_Logger != NULL) {
                m_Logger.LogWarning(StringFormat(
                    "EXTREME VOLATILITY DETECTED (%.2fx) - SKIPPING TRADE", volatilityRatio));
            }
            return 0.0; // Trả về 0 để EA bỏ qua giao dịch này
        }
        
        // Hard limit cho volatility cao
        volatilityRatio = 3.0;
        if (m_Logger != NULL) {
            m_Logger.LogWarning(StringFormat(
                "Volatility (%.2fx) exceeds limit - capped at 3.0x", volatilityRatio));
        }
    }
    
    // Phát hiện biến động bất thường
    if (volatilityRatio > maxVolFactor) {
        // Biến động quá cao, giảm lot - với hard minimum
        reductionFactor = MathMax(minLotMultiplier, 1.0 / (1.0 + (volatilityRatio - 1.0)));
        
        // Hoặc dùng công thức dạng mũ để giảm lot dần dần
        // reductionFactor = MathMax(minLotMultiplier, MathPow(maxVolFactor/volatilityRatio, 1.5));
        
        adjustedLotSize = baseLotSize * reductionFactor;
        
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "Biến động cao (%.2fx): Giảm lot từ %.2f xuống %.2f (factor=%.2f)",
                volatilityRatio, baseLotSize, adjustedLotSize, reductionFactor
            ));
        }
    }
    else if (volatilityRatio < 0.7) {
        // Biến động thấp, có thể tăng nhẹ lot nhưng an toàn
        double increaseFactor = MathMin(1.2, 1.0 / MathMax(0.5, volatilityRatio));
        adjustedLotSize = baseLotSize * increaseFactor;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Biến động thấp (%.2fx): Tăng lot từ %.2f lên %.2f",
                volatilityRatio, baseLotSize, adjustedLotSize
            ));
        }
    }
    
    // Giới hạn thay đổi lot tối đa so với ban đầu
    double maxChange = 0.5; // Không thay đổi quá 50%
    if (adjustedLotSize < baseLotSize * (1.0 - maxChange)) {
        adjustedLotSize = baseLotSize * (1.0 - maxChange);
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Giới hạn giảm lot tối đa 50%");
        }
    }
    
    // PropFirm mode: giới hạn thêm nếu cần
    if (m_Config.PropFirmMode) {
        double maxPropLot = baseLotSize * 0.8; // Giảm tối đa 20% so với cơ bản trong PropFirm mode
        adjustedLotSize = MathMin(adjustedLotSize, maxPropLot);
    }
    
    // Chuẩn hóa lại lot size
    adjustedLotSize = NormalizeLotSize(adjustedLotSize);
    
    return adjustedLotSize;
}

//+------------------------------------------------------------------+
//| Normalize lot size according to broker's rules                  |
//+------------------------------------------------------------------+
double CRiskOptimizer::NormalizeLotSize(double lotSize)
{
    if (m_Symbol == "") return lotSize;
    
    // Lấy thông tin về khối lượng tối thiểu, tối đa và bước
    double minLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP);
    
    // Đảm bảo các giá trị hợp lệ
    if (minLot <= 0) minLot = 0.01;
    if (maxLot <= 0) maxLot = 100.0;
    if (stepLot <= 0) stepLot = 0.01;
    
    // Xác định số chữ số thập phân cho lot
    int lotDigits = 0;
    double tempStep = stepLot;
    while (tempStep < 1.0 && lotDigits < 10) {
        tempStep *= 10.0;
        lotDigits++;
    }
    
    // Làm tròn xuống theo bước
    lotSize = MathFloor(lotSize / stepLot) * stepLot;
    
    // Đảm bảo lot size nằm trong giới hạn min/max
    lotSize = MathMax(minLot, MathMin(lotSize, maxLot));
    
    // Chuẩn hóa số chữ số thập phân
    lotSize = NormalizeDouble(lotSize, lotDigits);
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate quality-based risk multiplier (0.5 - 1.5)              |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateQualityBasedRiskMultiplier(double signalQuality)
{
    // Nếu chất lượng không được xác định, sử dụng mặc định 1.0
    if (signalQuality <= 0) return 1.0;
    
    // Giới hạn chất lượng từ 0.0 đến 1.0
    signalQuality = MathMax(0.0, MathMin(1.0, signalQuality));
    
    // Công thức: 0.5 + 1.0 * signalQuality
    // Cho ra multiplier từ 0.5 đến 1.5
    double multiplier = 0.5 + (1.0 * signalQuality);
    
    // PropFirm mode: giới hạn thêm
    if (m_Config.PropFirmMode) {
        // Trong chế độ PropFirm, giảm range xuống (0.7 - 1.2)
        multiplier = 0.7 + (0.5 * signalQuality);
    }
    
    return multiplier;
}

//+------------------------------------------------------------------+
//| Calculate stop loss and take profit based on ATR                 |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CalculateSLTP(double entryPrice, bool isLong, double& stopLoss, double& takeProfit, 
                                  ENUM_CLUSTER_TYPE cluster)
{
    if (entryPrice <= 0) {
        if (m_Logger != NULL) m_Logger.LogError("Giá entry không hợp lệ trong CalculateSLTP");
        return false;
    }
    
    // Ưu tiên lấy SL/TP từ AssetProfiler
    if (m_AssetProfiler != NULL) {
        if (m_AssetProfiler.CalculateSLTP(m_Symbol, entryPrice, isLong, stopLoss, takeProfit, 
                                        m_Config.SL_ATR_Multiplier, m_Config.TP_RR_Ratio)) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Sử dụng SL/TP từ AssetProfiler: SL=%.5f, TP=%.5f",
                    stopLoss, takeProfit
                ));
            }
            return true;
        }
    }
    
    // Lấy ATR từ Market Profile hoặc giá trị dự phòng
    double atr = GetValidATR();
    if (atr <= 0) {
        if (m_Logger != NULL) m_Logger.LogError("Giá trị ATR không hợp lệ trong CalculateSLTP");
        return false;
    }
    
    // Lấy hệ số SL và TP dựa trên cluster
    double slMultiplier = GetSLMultiplierForCluster(cluster);
    double tpMultiplier = GetTPMultiplierForCluster(cluster);
    
    // Điều chỉnh thêm dựa trên volatility
    if (m_LastVolatilityRatio > 1.5) {
        // Biến động cao, mở rộng SL
        slMultiplier *= MathMin(1.3, m_LastVolatilityRatio / 1.5);
        
        // Mở rộng TP nếu là trend following, thu hẹp nếu là counter trend
        if (cluster == CLUSTER_1_TREND_FOLLOWING) {
            tpMultiplier *= MathMin(1.5, m_LastVolatilityRatio / 1.2);
        } else if (cluster == CLUSTER_2_COUNTERTREND) {
            tpMultiplier *= 0.9; // Thu hẹp TP để đảm bảo an toàn hơn
        }
    } else if (m_LastVolatilityRatio < 0.7) {
        // Biến động thấp, thu hẹp SL
        slMultiplier *= MathMax(0.8, m_LastVolatilityRatio / 0.7);
        
        // Thu hẹp TP khi biến động thấp
        tpMultiplier *= MathMax(0.9, m_LastVolatilityRatio / 0.7);
    }
    
    // Tính khoảng cách SL và TP
    double slDistance = slMultiplier * atr;
    double tpDistance = slDistance * tpMultiplier; // R:R tỷ lệ
    
    // Tính toán mức SL và TP
    if (isLong) {
        stopLoss = entryPrice - slDistance;
        takeProfit = entryPrice + tpDistance;
    }
    else {
        stopLoss = entryPrice + slDistance;
        takeProfit = entryPrice - tpDistance;
    }
    
    // Chuẩn hóa giá trị
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string dirStr = isLong ? "MUA" : "BÁN";
        m_Logger.LogDebug(StringFormat(
            "%s: Entry=%.5f, SL=%.5f (%.1f ATR), TP=%.5f (%.1f ATR), Cluster=%d",
            dirStr, entryPrice, stopLoss, slMultiplier, takeProfit, tpMultiplier, cluster
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Phát hiện Pullback Chất Lượng Cao (v14.0)                        |
//+------------------------------------------------------------------+
PullbackSignal CRiskOptimizer::DetectQualityPullback(const MarketProfileData &profile)
{
    PullbackSignal signal;
    signal.IsValid = false;
    signal.HasPriceAction = false;
    signal.HasMomentum = false;
    signal.HasVolume = false;
    
    // Xác định TREND từ profile
    bool isLong = (profile.trend == TREND_UP || profile.trend == TREND_UP_STRONG || 
                 profile.trend == TREND_UP_PULLBACK);
    
    signal.IsLong = isLong;
    
    // Lấy giá hiện tại
    double currentPrice = SymbolInfoDouble(m_Symbol, isLong ? SYMBOL_ASK : SYMBOL_BID);
    signal.EntryPrice = currentPrice;
    
    // 1. KIỂM TRA VÙNG PULLBACK HỢP LỆ
    bool isValidZone = ValidatePullbackZone(currentPrice, isLong, profile);
    if (!isValidZone) {
        signal.Reason = "Giá không nằm trong vùng pullback hợp lệ";
        return signal;
    }
    
    // 2. KIỂM TRA PRICE ACTION (nếu được yêu cầu)
    if (m_Config.RequirePriceAction) {
        signal.HasPriceAction = ValidatePriceAction(isLong);
        if (!signal.HasPriceAction && m_Config.RequirePriceAction) {
            signal.Reason = "Không có xác nhận Price Action";
            return signal;
        }
    } else {
        signal.HasPriceAction = true; // Không bắt buộc
    }
    
    // 3. KIỂM TRA MOMENTUM (nếu được yêu cầu)
    signal.HasMomentum = ValidateMomentum(isLong, profile);
    
    // 4. KIỂM TRA VOLUME (nếu được yêu cầu)
    signal.HasVolume = ValidateVolume(isLong);
    
    // CẦN CÓ ÍT NHẤT 1 XÁC NHẬN (MOMENTUM HOẶC VOLUME) nếu đã bật
    bool needsConfirmation = m_Config.RequireMomentum || m_Config.RequireVolume;
    bool hasConfirmation = signal.HasMomentum || signal.HasVolume;
    
    if (needsConfirmation && !hasConfirmation) {
        signal.Reason = "Không có xác nhận Momentum hoặc Volume";
        return signal;
    }
    
    // Tính phần trăm pullback
    signal.PullbackPercent = CalculatePullbackPercent(currentPrice, isLong, profile);
    
    // Tính SL/TP mặc định
    double stopLoss = 0, takeProfit = 0;
    if (!CalculateSLTP(currentPrice, isLong, stopLoss, takeProfit, CLUSTER_1_TREND_FOLLOWING)) {
        signal.Reason = "Không thể tính SL/TP";
        return signal;
    }
    
    // Cập nhật SL/TP vào tín hiệu
    signal.StopLoss = stopLoss;
    signal.TakeProfit = takeProfit;
    
    // Đánh giá chất lượng tín hiệu
    signal.QualityScore = CalculateSignalQuality(signal);
    
    // Tín hiệu hợp lệ
    signal.IsValid = true;
    signal.Reason = StringFormat(
        "Pullback chất lượng cao - %.2f%%, Price Action: %s, Momentum: %s, Volume: %s", 
        signal.PullbackPercent,
        signal.HasPriceAction ? "Có" : "Không",
        signal.HasMomentum ? "Có" : "Không",
        signal.HasVolume ? "Có" : "Không"
    );
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Phát hiện Pullback chất lượng cao: %s, Quality=%.2f, %s",
            isLong ? "Long" : "Short", signal.QualityScore, signal.Reason
        ));
    }
    
    return signal;
}

//+------------------------------------------------------------------+
//| Tính điểm chất lượng tín hiệu                                    |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateSignalQuality(const PullbackSignal &signal)
{
    double quality = 0.7; // Điểm cơ bản
    
    // 1. Tăng điểm nếu có Price Action rõ ràng
    if (signal.HasPriceAction) {
        quality += 0.15;
    }
    
    // 2. Tăng điểm nếu có Momentum
    if (signal.HasMomentum) {
        quality += 0.1;
    }
    
    // 3. Tăng điểm nếu có Volume
    if (signal.HasVolume) {
        quality += 0.05;
    }
    
    // 4. Điều chỉnh dựa trên % pullback
    if (signal.PullbackPercent >= 30 && signal.PullbackPercent <= 60) {
        // Pullback nằm trong vùng lý tưởng (30-60%)
        quality += 0.1;
    } else if (signal.PullbackPercent < 25 || signal.PullbackPercent > 65) {
        // Pullback quá nông hoặc quá sâu
        quality -= 0.1;
    }
    
    // 5. Điểm cộng nếu có đủ 3 xác nhận
    if (signal.HasPriceAction && signal.HasMomentum && signal.HasVolume) {
        quality += 0.1;
    }
    
    // Đảm bảo điểm trong khoảng 0.0-1.0
    quality = MathMax(0.0, MathMin(1.0, quality));
    
    return quality;
}

//+------------------------------------------------------------------+
//| Kiểm tra vùng pullback có hợp lệ không                          |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ValidatePullbackZone(double currentPrice, bool isLong, const MarketProfileData &profile)
{
    if (currentPrice <= 0) return false;
    
    bool isValidZone = false;
    
    // Kiểm tra EMA alignment trước
    bool emaAligned = false;
    
    if (isLong) {
        emaAligned = (profile.ema34 > profile.ema89 && profile.ema89 > profile.ema200);
    } else {
        emaAligned = (profile.ema34 < profile.ema89 && profile.ema89 < profile.ema200);
    }
    
    if (!emaAligned) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Pullback không hợp lệ: EMA không xếp hàng theo trend");
        }
        return false;
    }
    
    // Kiểm tra vùng pullback
    if (isLong) {
        // PULLBACK TRONG XU HƯỚNG TĂNG:
        
        // 1. Giá nằm giữa hoặc dưới EMA34 một chút
        bool nearEma34 = (currentPrice <= profile.ema34 * 1.001);
        
        // 2. Không vượt quá EMA89 quá nhiều
        bool aboveEma89 = (currentPrice >= profile.ema89 * 0.995);
        
        // 3. KHÔNG BAO GIỜ dưới EMA200
        bool aboveEma200 = (currentPrice > profile.ema200);
        
        isValidZone = nearEma34 && aboveEma89 && aboveEma200;
    } else {
        // PULLBACK TRONG XU HƯỚNG GIẢM:
        
        // 1. Giá nằm giữa hoặc trên EMA34 một chút
        bool nearEma34 = (currentPrice >= profile.ema34 * 0.999);
        
        // 2. Không vượt quá EMA89 quá nhiều
        bool belowEma89 = (currentPrice <= profile.ema89 * 1.005);
        
        // 3. KHÔNG BAO GIỜ trên EMA200
        bool belowEma200 = (currentPrice < profile.ema200);
        
        isValidZone = nearEma34 && belowEma89 && belowEma200;
    }
    
    // Kiểm tra % pullback
    double pullbackPercent = CalculatePullbackPercent(currentPrice, isLong, profile);
    bool validPullbackPercent = (pullbackPercent >= m_Config.MinPullbackPercent && 
                               pullbackPercent <= m_Config.MaxPullbackPercent);
    
    if (!validPullbackPercent) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Pullback không hợp lệ: Phần trăm pullback %.2f%% nằm ngoài khoảng %.2f%%-%.2f%%",
                pullbackPercent, m_Config.MinPullbackPercent, m_Config.MaxPullbackPercent
            ));
        }
        return false;
    }
    
    return isValidZone && validPullbackPercent;
}

//+------------------------------------------------------------------+
//| Tính phần trăm pullback                                          |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculatePullbackPercent(double currentPrice, bool isLong, const MarketProfileData &profile)
{
    double pullbackPercent = 0.0;
    
    if (m_SwingDetector != NULL) {
        // Lấy swing point gần nhất
        double swingPoint = isLong ? 
            m_SwingDetector.GetLastSwingHigh() : 
            m_SwingDetector.GetLastSwingLow();
        
        if (swingPoint > 0) {
            // Tính % pullback từ swing point đến giá hiện tại
            if (isLong) {
                // Trong xu hướng tăng, tính % pullback từ swing high
                pullbackPercent = (swingPoint - currentPrice) / (swingPoint - profile.ema34) * 100.0;
            } else {
                // Trong xu hướng giảm, tính % pullback từ swing low
                pullbackPercent = (currentPrice - swingPoint) / (profile.ema34 - swingPoint) * 100.0;
            }
        }
    }
    
    // Nếu không tìm thấy swing point hoặc pullbackPercent không hợp lệ,
    // tính theo ATR
    if (pullbackPercent <= 0) {
        double atr = GetValidATR();
        if (atr > 0) {
            pullbackPercent = isLong ? 
                (profile.ema34 - currentPrice) / atr * 20.0 : 
                (currentPrice - profile.ema34) / atr * 20.0;
        }
    }
    
    // Đảm bảo giá trị không âm
    pullbackPercent = MathMax(0.0, pullbackPercent);
    
    return pullbackPercent;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận Price Action                                   |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ValidatePriceAction(bool isLong)
{
    // Phần này cần được triển khai chi tiết trong EA chính
    // Dưới đây là bản mô phỏng đơn giản dựa trên một số mẫu hình nến cơ bản
    
    // Dữ liệu giá
    double open0 = iOpen(m_Symbol, m_MainTimeframe, 0);
    double close0 = iClose(m_Symbol, m_MainTimeframe, 0);
    double high0 = iHigh(m_Symbol, m_MainTimeframe, 0);
    double low0 = iLow(m_Symbol, m_MainTimeframe, 0);
    
    double open1 = iOpen(m_Symbol, m_MainTimeframe, 1);
    double close1 = iClose(m_Symbol, m_MainTimeframe, 1);
    double high1 = iHigh(m_Symbol, m_MainTimeframe, 1);
    double low1 = iLow(m_Symbol, m_MainTimeframe, 1);
    
    // Kiểm tra các mẫu hình Price Action
    bool foundPattern = false;
    string patternName = "";
    
    if (isLong) {
        // 1. Bullish Engulfing
        if (close0 > open0 && open0 <= close1 && close0 >= open1 && close0 - open0 > open1 - close1) {
            foundPattern = true;
            patternName = "Bullish Engulfing";
        }
        
        // 2. Bullish Pinbar (nến búa)
        if (!foundPattern) {
            double bodySize = MathAbs(close0 - open0);
            double totalSize = high0 - low0;
            double lowerWick = MathMin(open0, close0) - low0;
            
            if (bodySize / totalSize < 0.3 && lowerWick / totalSize > 0.6) {
                foundPattern = true;
                patternName = "Bullish Pinbar";
            }
        }
        
        // 3. Morning Star (đơn giản hóa)
        if (!foundPattern && open1 > close1 && close0 > open0) {
            foundPattern = true;
            patternName = "Morning Star";
        }
    } else {
        // 1. Bearish Engulfing
        if (close0 < open0 && open0 >= close1 && close0 <= open1 && open0 - close0 > close1 - open1) {
            foundPattern = true;
            patternName = "Bearish Engulfing";
        }
        
        // 2. Bearish Pinbar
        if (!foundPattern) {
            double bodySize = MathAbs(close0 - open0);
            double totalSize = high0 - low0;
            double upperWick = high0 - MathMax(open0, close0);
            
            if (bodySize / totalSize < 0.3 && upperWick / totalSize > 0.6) {
                foundPattern = true;
                patternName = "Bearish Pinbar";
            }
        }
        
        // 3. Evening Star (đơn giản hóa)
        if (!foundPattern && open1 < close1 && close0 < open0) {
            foundPattern = true;
            patternName = "Evening Star";
        }
    }
    
    if (foundPattern && m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug("Xác nhận Price Action: " + patternName);
    }
    
    return foundPattern;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận Momentum                                       |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ValidateMomentum(bool isLong, const MarketProfileData &profile)
{
    // Lấy giá trị indicators từ profile (nếu có)
    double rsiValue = profile.rsiValue;
    double rsiSlope = profile.rsiSlope;
    double macdHistogram = profile.macdHistogram;
    double macdHistogramSlope = profile.macdHistogramSlope;
    
    // Nếu không có trong profile, tính toán
    if (rsiValue == 0 || macdHistogram == 0) {
        // Handle RSI
        int rsiHandle = iRSI(m_Symbol, m_MainTimeframe, 14, PRICE_CLOSE);
        if (rsiHandle != INVALID_HANDLE) {
            double rsiBuffer[];
            ArraySetAsSeries(rsiBuffer, true);
            if (CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) > 0) {
                rsiValue = rsiBuffer[0];
                rsiSlope = rsiBuffer[0] - rsiBuffer[1];
            }
            IndicatorRelease(rsiHandle);
        }
        
        // Handle MACD
        int macdHandle = iMACD(m_Symbol, m_MainTimeframe, 12, 26, 9, PRICE_CLOSE);
        if (macdHandle != INVALID_HANDLE) {
            double macdBuffer[];
            ArraySetAsSeries(macdBuffer, true);
            if (CopyBuffer(macdHandle, 1, 0, 3, macdBuffer) > 0) {
                macdHistogram = macdBuffer[0];
                macdHistogramSlope = macdBuffer[0] - macdBuffer[1];
            }
            IndicatorRelease(macdHandle);
        }
    }
    
    // Xác nhận momentum
    bool momentumConfirmed = false;
    
    if (isLong) {
        // Xu hướng tăng cần RSI tăng và/hoặc MACD Histogram tăng
        bool rsiConfirm = (rsiValue > 45.0 && rsiSlope > 0.25);
        bool macdConfirm = (macdHistogram > 0 && macdHistogramSlope > 0);
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    } else {
        // Xu hướng giảm cần RSI giảm và/hoặc MACD Histogram giảm
        bool rsiConfirm = (rsiValue < 55.0 && rsiSlope < -0.25);
        bool macdConfirm = (macdHistogram < 0 && macdHistogramSlope < 0);
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    }
    
    if (momentumConfirmed && m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Xác nhận Momentum: RSI=%.1f, RSI Slope=%.2f, MACD Histogram=%.5f, MACD Slope=%.5f",
            rsiValue, rsiSlope, macdHistogram, macdHistogramSlope
        ));
    }
    
    return momentumConfirmed;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận Volume                                         |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ValidateVolume(bool isLong)
{
    // Lấy dữ liệu volume
    long volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    
    if (CopyTickVolume(m_Symbol, m_MainTimeframe, 0, 21, volumeBuffer) <= 0) {
        return false;
    }
    
    // Tính volume trung bình 20 nến
    double avgVolume = 0;
    for (int i = 1; i <= 20; i++) {
        avgVolume += volumeBuffer[i];
    }
    avgVolume /= 20;
    
    // Volume hiện tại
    long currentVolume = volumeBuffer[0];
    
    // Xác nhận volume tăng
    bool volumeConfirmed = false;
    
    // Volume cần cao hơn trung bình ít nhất 10%
    if (currentVolume > avgVolume * 1.1) {
        volumeConfirmed = true;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Xác nhận Volume: Current=%d, Avg=%d (%.2f%%)",
                currentVolume, (int)avgVolume, currentVolume * 100.0 / avgVolume
            ));
        }
    }
    
    return volumeConfirmed;
}

//+------------------------------------------------------------------+
//| Get SL Multiplier for specific cluster type                      |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetSLMultiplierForCluster(ENUM_CLUSTER_TYPE cluster)
{
    double baseMultiplier = m_Config.SL_ATR_Multiplier;
    
    // Điều chỉnh nếu có AssetProfiler
    if (m_AssetProfiler != NULL) {
        double assetFactor = m_AssetProfiler.GetSymbolSLTPFactor(m_Symbol);
        if (assetFactor > 0) {
            baseMultiplier *= assetFactor;
        }
    }
    
    switch (cluster) {
        case CLUSTER_1_TREND_FOLLOWING:
            // Trend following: SL rộng hơn
            return baseMultiplier * 1.2;
            
        case CLUSTER_2_COUNTERTREND:
            // Counter-trend: SL chặt hơn
            return baseMultiplier * 0.9;
            
        case CLUSTER_3_SCALING:
            // Scaling: Trung bình
            return baseMultiplier * 1.1;
            
        default:
            return baseMultiplier;
    }
}

//+------------------------------------------------------------------+
//| Get TP Multiplier for specific cluster type                      |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetTPMultiplierForCluster(ENUM_CLUSTER_TYPE cluster)
{
    double baseMultiplier = m_Config.TP_RR_Ratio;
    
    // Điều chỉnh nếu có AssetProfiler
    if (m_AssetProfiler != NULL) {
        double assetFactor = m_AssetProfiler.GetSymbolTPRRFactor(m_Symbol);
        if (assetFactor > 0) {
            baseMultiplier *= assetFactor;
        }
    }
    
    switch (cluster) {
        case CLUSTER_1_TREND_FOLLOWING:
            // Trend following: TP xa hơn
            return baseMultiplier * 1.3;
            
        case CLUSTER_2_COUNTERTREND:
            // Counter-trend: TP gần hơn để đảm bảo hit target
            return baseMultiplier * 0.8;
            
        case CLUSTER_3_SCALING:
            // Scaling: Trung bình
            return baseMultiplier * 1.1;
            
        default:
            return baseMultiplier;
    }
}

//+------------------------------------------------------------------+
//| Adjust SL/TP based on session                                    |
//+------------------------------------------------------------------+
void CRiskOptimizer::AdjustSLTPBasedOnSession(double& stopLoss, double& takeProfit, bool isLong, ENUM_SESSION session)
{
    double atr = GetValidATR();
    if (atr <= 0) return;
    
    double adjustFactor = 1.0;
    
    switch(session) {
        case SESSION_ASIAN:
            // Phiên Á: Biến động nhỏ, thu hẹp SL/TP
            adjustFactor = 0.8;
            break;
            
        case SESSION_EUROPEAN:
            // Phiên Âu: Biến động trung bình
            adjustFactor = 1.0;
            break;
            
        case SESSION_AMERICAN:
            // Phiên Mỹ: Biến động lớn hơn
            adjustFactor = 1.1;
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            // Phiên Overlap: Biến động mạnh nhất
            adjustFactor = 1.2;
            break;
            
        case SESSION_CLOSING:
            // Phiên đóng cửa: Biến động không ổn định
            adjustFactor = 0.9;
            break;
            
        default:
            adjustFactor = 1.0;
    }
    
    // Điều chỉnh thêm từ AssetProfiler
    if (m_AssetProfiler != NULL) {
        double sessionAdjust = m_AssetProfiler.GetSessionFactor(m_Symbol, session);
        if (sessionAdjust > 0) {
            adjustFactor *= sessionAdjust;
        }
    }
    
    // Tính khoảng cách điều chỉnh
    double slAdjustment = atr * (adjustFactor - 1.0);
    double tpAdjustment = atr * (adjustFactor - 1.0) * 2.0; // TP điều chỉnh nhiều hơn
    
    // Áp dụng điều chỉnh
    if (isLong) {
        stopLoss = stopLoss - slAdjustment; // Điều chỉnh SL xuống
        takeProfit = takeProfit + tpAdjustment; // Điều chỉnh TP lên
    } else {
        stopLoss = stopLoss + slAdjustment; // Điều chỉnh SL lên
        takeProfit = takeProfit - tpAdjustment; // Điều chỉnh TP xuống
    }
    
    // Chuẩn hóa giá trị
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string sessionName = "";
        switch(session) {
            case SESSION_ASIAN: sessionName = "Asian"; break;
            case SESSION_EUROPEAN: sessionName = "European"; break;
            case SESSION_AMERICAN: sessionName = "American"; break;
            case SESSION_EUROPEAN_AMERICAN: sessionName = "EU-US Overlap"; break;
            case SESSION_CLOSING: sessionName = "Closing"; break;
        }
        
        m_Logger.LogDebug(StringFormat(
            "Điều chỉnh SL/TP theo phiên %s (x%.2f): SL=%.5f, TP=%.5f",
            sessionName, adjustFactor, stopLoss, takeProfit
        ));
    }
}

//+------------------------------------------------------------------+
//| Adjust SL/TP based on volatility                                |
//+------------------------------------------------------------------+
void CRiskOptimizer::AdjustSLTPBasedOnVolatility(double &stopLoss, double &takeProfit, bool isLong)
{
    double currentATR = GetValidATR();
    
    if (currentATR <= 0 || m_AverageATR <= 0) return;
    
    // Tính tỷ lệ biến động hiện tại so với trung bình
    double volatilityRatio = currentATR / m_AverageATR;
    
    // Nếu biến động tăng 20% so với trung bình, mở rộng SL/TP
    if (volatilityRatio > 1.2) {
        double adjustFactor = MathMin(volatilityRatio, 2.0); // Giới hạn tối đa 2x
        
        if (isLong) {
            stopLoss = NormalizeDouble(stopLoss - (currentATR * (adjustFactor - 1.0)), _Digits);
            takeProfit = NormalizeDouble(takeProfit + (currentATR * (adjustFactor - 1.0) * 1.5), _Digits); // TP điều chỉnh nhiều hơn
        } else {
            stopLoss = NormalizeDouble(stopLoss + (currentATR * (adjustFactor - 1.0)), _Digits);
            takeProfit = NormalizeDouble(takeProfit - (currentATR * (adjustFactor - 1.0) * 1.5), _Digits); // TP điều chỉnh nhiều hơn
        }
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Điều chỉnh SL/TP cho biến động cao (%.1f%%): SL=%.5f, TP=%.5f", 
                (volatilityRatio - 1.0) * 100, stopLoss, takeProfit
            ));
        }
    }
    // Nếu biến động thấp, thu hẹp SL/TP
    else if (volatilityRatio < 0.8) {
        double adjustFactor = MathMax(0.6, volatilityRatio); // Không giảm quá 40%
        double adjustAmount = currentATR * (1.0 - adjustFactor);
        
        if (isLong) {
            stopLoss = NormalizeDouble(stopLoss + adjustAmount, _Digits); // SL gần hơn
            takeProfit = NormalizeDouble(takeProfit - adjustAmount, _Digits); // TP gần hơn
        } else {
            stopLoss = NormalizeDouble(stopLoss - adjustAmount, _Digits); // SL gần hơn
            takeProfit = NormalizeDouble(takeProfit + adjustAmount, _Digits); // TP gần hơn
        }
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Điều chỉnh SL/TP cho biến động thấp (%.1f%%): SL=%.5f, TP=%.5f", 
                (volatilityRatio - 1.0) * 100, stopLoss, takeProfit
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| AdjustSLTPBasedOnCluster - Điều chỉnh SL/TP theo cluster        |
//+------------------------------------------------------------------+
void CRiskOptimizer::AdjustSLTPBasedOnCluster(double& stopLoss, double& takeProfit, bool isLong, ENUM_CLUSTER_TYPE cluster)
{
    double atr = GetValidATR();
    if (atr <= 0) return;
    
    double slAdjustFactor = 1.0;
    double tpAdjustFactor = 1.0;
    
    switch(cluster) {
        case CLUSTER_1_TREND_FOLLOWING:
            // Trend following: SL rộng hơn, TP xa hơn
            slAdjustFactor = 1.2;
            tpAdjustFactor = 1.3;
            break;
            
        case CLUSTER_2_COUNTERTREND:
            // Counter-trend: SL chặt hơn, TP gần hơn
            slAdjustFactor = 0.9;
            tpAdjustFactor = 0.8;
            break;
            
        case CLUSTER_3_SCALING:
            // Scaling: Trung bình
            slAdjustFactor = 1.1;
            tpAdjustFactor = 1.1;
            break;
            
        default:
            // Không điều chỉnh
            return;
    }
    
    // Áp dụng điều chỉnh
    double slAdjustment = atr * (slAdjustFactor - 1.0);
    double tpAdjustment = atr * (tpAdjustFactor - 1.0) * 2.0; // TP điều chỉnh nhiều hơn
    
    if (isLong) {
        stopLoss = NormalizeDouble(stopLoss - slAdjustment, _Digits); // Điều chỉnh SL
        takeProfit = NormalizeDouble(takeProfit + tpAdjustment, _Digits); // Điều chỉnh TP
    } else {
        stopLoss = NormalizeDouble(stopLoss + slAdjustment, _Digits); // Điều chỉnh SL
        takeProfit = NormalizeDouble(takeProfit - tpAdjustment, _Digits); // Điều chỉnh TP
    }
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string clusterNames[] = {"Trend Following", "Countertrend", "Scaling"};
        
        m_Logger.LogDebug(StringFormat(
            "Điều chỉnh SL/TP theo cluster %s: SL x%.2f, TP x%.2f -> SL=%.5f, TP=%.5f",
            clusterNames[cluster], slAdjustFactor, tpAdjustFactor, stopLoss, takeProfit
        ));
    }
}

//+------------------------------------------------------------------+
//| Adjust SL/TP based on trading strategy                           |
//+------------------------------------------------------------------+
void CRiskOptimizer::AdjustSLTPByStrategy(double &stopLoss, double &takeProfit, 
                                         bool isLong, ENUM_TRADING_STRATEGY strategy)
{
    double atr = GetValidATR();
    if (atr <= 0) return;
    
    // Điều chỉnh SL/TP dựa trên chiến lược
    switch(strategy) {
        case STRATEGY_BREAKOUT:
            // Breakout: SL rộng hơn, TP xa hơn để nắm bắt xu hướng
            if (isLong) {
                stopLoss -= atr * 0.5;    // SL thêm 0.5 ATR 
                takeProfit += atr * 1.0;  // TP thêm 1.0 ATR
            } else {
                stopLoss += atr * 0.5;
                takeProfit -= atr * 1.0;
            }
            break;
            
        case STRATEGY_PULLBACK:
            // Pullback: SL/TP tiêu chuẩn, không điều chỉnh
            break;
            
        case STRATEGY_MEAN_REVERSION:
            // Mean Reversion: TP gần hơn, SL cũng rộng hơn
            if (isLong) {
                stopLoss -= atr * 0.3;    // SL thêm 0.3 ATR
                takeProfit -= atr * 0.5;  // TP gần hơn 0.5 ATR
            } else {
                stopLoss += atr * 0.3;
                takeProfit += atr * 0.5;
            }
            break;
            
        case STRATEGY_VOLATILITY_BREAKOUT:
            // Volatility Breakout: SL chặt hơn, TP xa hơn
            if (isLong) {
                stopLoss += atr * 0.2;    // SL gần hơn 0.2 ATR
                takeProfit += atr * 1.5;  // TP xa hơn 1.5 ATR
            } else {
                stopLoss -= atr * 0.2;
                takeProfit -= atr * 1.5;
            }
            break;
            
        case STRATEGY_PRESERVATION:
            // Preservation: SL rất chặt, TP gần để bảo toàn vốn
            if (isLong) {
                stopLoss += atr * 0.3;    // SL gần hơn 0.3 ATR
                takeProfit -= atr * 0.7;  // TP gần hơn 0.7 ATR
            } else {
                stopLoss -= atr * 0.3;
                takeProfit += atr * 0.7;
            }
            break;
    }
    
    // Chuẩn hóa giá trị
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    if (m_Logger != NULL) {
        string strategyNames[] = {"Breakout", "Pullback", "Mean Reversion", "Volatility Breakout", "Preservation"};
        
        m_Logger.LogInfo(StringFormat(
            "Điều chỉnh SL/TP theo chiến lược %s: SL=%.5f, TP=%.5f",
            strategyNames[strategy], stopLoss, takeProfit
        ));
    }
}

//+------------------------------------------------------------------+
//| Adjust risk percent based on market regime                       |
//+------------------------------------------------------------------+
double CRiskOptimizer::AdjustRiskPercentByMarketRegime(ENUM_MARKET_REGIME regime, double baseRiskPercent)
{
    double adjustedRisk = baseRiskPercent;
    
    switch(regime) {
        case REGIME_TRENDING:
            // Thị trường xu hướng rõ ràng - có thể giữ nguyên risk
            adjustedRisk = baseRiskPercent;
            break;
            
        case REGIME_RANGING:
            // Thị trường sideway - giảm risk
            adjustedRisk = baseRiskPercent * 0.7;
            break;
            
        case REGIME_VOLATILE:
            // Thị trường biến động cao - giảm risk nhiều hơn
            adjustedRisk = baseRiskPercent * 0.5;
            break;
            
        default:
            // Unknown regime - use base risk
            adjustedRisk = baseRiskPercent;
    }
    
    // Prop firm mode - giới hạn thêm
    if (m_Config.PropFirmMode) {
        adjustedRisk = MathMin(adjustedRisk, baseRiskPercent * 0.8);
    }
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string regimeNames[] = {"Trending", "Ranging", "Volatile", "Unknown"};
        int regimeIndex = (int)regime;
        
        m_Logger.LogDebug(StringFormat(
            "Điều chỉnh risk theo regime %s: %.2f%% -> %.2f%%",
            regimeNames[regimeIndex], baseRiskPercent, adjustedRisk
        ));
    }
    
    return adjustedRisk;
}

//+------------------------------------------------------------------+
//| Adjust risk percent based on drawdown                           |
//+------------------------------------------------------------------+
double CRiskOptimizer::AdjustRiskPercentByDrawdown(double currentDrawdown, double baseRiskPercent)
{
    double adjustedRisk = baseRiskPercent;
    
    // Nếu DD dưới ngưỡng, giữ nguyên risk
    if (currentDrawdown < m_Config.DrawdownReduceThreshold) {
        return baseRiskPercent;
    }
    
    // Nếu không bật chế độ tapered risk, giảm risk đột ngột theo ngưỡng
    if (!m_Config.EnableTaperedRisk) {
        if (currentDrawdown >= m_Config.DrawdownReduceThreshold && 
            currentDrawdown < m_Config.MaxAllowedDrawdown) {
            adjustedRisk = baseRiskPercent * m_Config.MinRiskMultiplier;
        }
        else if (currentDrawdown >= m_Config.MaxAllowedDrawdown) {
            adjustedRisk = 0; // Dừng giao dịch
        }
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Điều chỉnh risk theo DD (step): DD=%.2f%%, Risk: %.2f%% -> %.2f%%",
                currentDrawdown, baseRiskPercent, adjustedRisk
            ));
        }
        
        return adjustedRisk;
    }
    
    // Chế độ tapered risk - Giảm risk tuyến tính từ DrawdownReduceThreshold đến MaxDrawdown
    if (currentDrawdown >= m_Config.DrawdownReduceThreshold && 
        currentDrawdown < m_Config.MaxAllowedDrawdown) {
        double riskReductionRange = m_Config.MaxAllowedDrawdown - m_Config.DrawdownReduceThreshold;
        double ddInRange = currentDrawdown - m_Config.DrawdownReduceThreshold;
        double reducePercent = ddInRange / riskReductionRange;
        
        // Tỷ lệ giảm từ risk cơ sở xuống minRisk
        double minRisk = baseRiskPercent * m_Config.MinRiskMultiplier;
        adjustedRisk = baseRiskPercent - (baseRiskPercent - minRisk) * reducePercent;
    }
    // Nếu DD vượt MaxDrawdown, đặt risk = 0 (không giao dịch)
    else if (currentDrawdown >= m_Config.MaxAllowedDrawdown) {
        adjustedRisk = 0;
    }
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Điều chỉnh risk theo DD (tapered): DD=%.2f%%, Risk: %.2f%% -> %.2f%%",
            currentDrawdown, baseRiskPercent, adjustedRisk
        ));
    }
    
    return adjustedRisk;
}

//+------------------------------------------------------------------+
//| Calculate R-multiple                                             |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateRMultiple(double entryPrice, double currentPrice, 
                                        double stopLoss, bool isLong)
{
    if (entryPrice <= 0 || stopLoss <= 0 || currentPrice <= 0) {
        return 0.0;
    }
    
    // Tính khoảng cách từ entry tới SL ban đầu = 1R
    double riskDistance = MathAbs(entryPrice - stopLoss);
    if (riskDistance == 0) {
        return 0.0;
    }
    
    // Tính khoảng cách từ entry tới giá hiện tại
    double currentDistance = isLong ? (currentPrice - entryPrice) : (entryPrice - currentPrice);
    
    // Trả về R-multiple
    return currentDistance / riskDistance;
}

//+------------------------------------------------------------------+
//| Calculate trailing stop based on market regime                   |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateTrailingStop(double currentPrice, double openPrice, 
                                           double atr, bool isLong, 
                                           ENUM_MARKET_REGIME regime)
{
    if (atr <= 0) {
        atr = GetValidATR();
        if (atr <= 0) return 0;
    }
    
    // Lấy trailing factor dựa trên regime
    double trailingFactor = GetTrailingFactorForRegime(regime);
    
    // Tính trailing stop dựa trên ATR
    double trailingDistance = atr * trailingFactor;
    double trailingStop = 0;
    
    if (isLong) {
        trailingStop = currentPrice - trailingDistance;
    } else {
        trailingStop = currentPrice + trailingDistance;
    }
    
    // Chuẩn hóa
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    trailingStop = NormalizeDouble(trailingStop, digits);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string regimeNames[] = {"Trending", "Ranging", "Volatile", "Unknown"};
        m_Logger.LogDebug(StringFormat(
            "Trailing stop (%s): Giá=%.5f, ATR=%.5f, Factor=%.2f, Stop=%.5f",
            regimeNames[(int)regime], currentPrice, atr, trailingFactor, trailingStop
        ));
    }
    
    return trailingStop;
}

//+------------------------------------------------------------------+
//| Get trailing stop factor based on market regime                  |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetTrailingFactorForRegime(ENUM_MARKET_REGIME regime)
{
    switch(regime) {
        case REGIME_TRENDING:
            return m_Config.TrailingFactorTrend;
            
        case REGIME_RANGING:
            return m_Config.TrailingFactorRanging;
            
        case REGIME_VOLATILE:
            return m_Config.TrailingFactorVolatile;
            
        default:
            return m_Config.TrailingFactorTrend; // Fallback
    }
}

//+------------------------------------------------------------------+
//| Calculate Chandelier Exit                                        |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateChandelierExit(bool isLong, double openPrice, double currentPrice)
{
    // Nếu không dùng Chandelier Exit, trả về 0
    if (!m_Config.UseChandelierExit) return 0;
    
    // Lấy các thông số
    int lookbackPeriod = m_Config.ChandelierLookback; 
    double multiplier = m_Config.ChandelierATRMultiplier;
    double atr = GetValidATR();
    
    if (lookbackPeriod <= 0) lookbackPeriod = 20;
    if (multiplier <= 0) multiplier = 3.0;
    if (atr <= 0) return 0;
    
    // Khởi tạo arrays
    double highArray[];
    double lowArray[];
    ArrayResize(highArray, lookbackPeriod);
    ArrayResize(lowArray, lookbackPeriod);
    
    // Copy dữ liệu
    CopyHigh(m_Symbol, m_MainTimeframe, 0, lookbackPeriod, highArray);
    CopyLow(m_Symbol, m_MainTimeframe, 0, lookbackPeriod, lowArray);
    
    // Tìm high/low cao nhất/thấp nhất trong lookback
    double highestHigh = highArray[ArrayMaximum(highArray, 0, lookbackPeriod)];
    double lowestLow = lowArray[ArrayMinimum(lowArray, 0, lookbackPeriod)];
    
    double chandelierExit = 0;
    
    // Tính Chandelier Exit
    if (isLong) {
        chandelierExit = highestHigh - (atr * multiplier);
    } else {
        chandelierExit = lowestLow + (atr * multiplier);
    }
    
    // Chuẩn hóa
    chandelierExit = NormalizeDouble(chandelierExit, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Chandelier Exit (%s): HighestHigh=%.5f, LowestLow=%.5f, ATR=%.5f, Exit=%.5f",
            isLong ? "Long" : "Short", highestHigh, lowestLow, atr, chandelierExit
        ));
    }
    
    return chandelierExit;
}

//+------------------------------------------------------------------+
//| Calculate Smart Trailing action                                  |
//+------------------------------------------------------------------+
TrailingAction CRiskOptimizer::CalculateSmartTrailing(double entryPrice, double currentPrice, 
                                                    double stopLoss, bool isLong, 
                                                    ENUM_MARKET_REGIME regime)
{
    TrailingAction action;
    action.ShouldTrail = false;
    action.NewStopLoss = stopLoss;
    action.LockPercentage = 0;
    action.Phase = TRAILING_NONE;
    
    // Kiểm tra xem Smart Trailing có được bật không
    if (!m_Config.Trailing.EnableSmartTrailing) return action;
    
    // Tính R-multiple hiện tại
    double rMultiple = CalculateRMultiple(entryPrice, currentPrice, stopLoss, isLong);
    action.RMultiple = rMultiple;
    
    // Nếu lệnh không có lãi, không trailing
    if (rMultiple <= 0.5) return action;
    
    // Lấy ATR
    double atr = GetValidATR();
    if (atr <= 0) return action;
    
    // Đặt phase trailing dựa trên R-multiple
    if (rMultiple >= m_Config.Trailing.ThirdLockRMultiple) {
        action.Phase = TRAILING_THIRD_LOCK;
        action.LockPercentage = m_Config.Trailing.LockPercentageThird;
    }
    else if (rMultiple >= m_Config.Trailing.SecondLockRMultiple) {
        action.Phase = TRAILING_SECOND_LOCK;
        action.LockPercentage = m_Config.Trailing.LockPercentageSecond;
    }
    else if (rMultiple >= m_Config.Trailing.FirstLockRMultiple) {
        action.Phase = TRAILING_FIRST_LOCK;
        action.LockPercentage = m_Config.Trailing.LockPercentageFirst;
    }
    else if (rMultiple >= m_Config.Trailing.BreakEvenRMultiple) {
        action.Phase = TRAILING_BREAKEVEN;
        action.LockPercentage = 0;
    }
    else {
        action.Phase = TRAILING_NONE;
        return action;
    }
    
    // Nếu chưa đạt phase trailing mới, không thay đổi
    if (action.Phase <= m_CurrentTrailingPhase) {
        if (m_LastTrailingStop > 0) {
            action.NewStopLoss = m_LastTrailingStop;
        }
        return action;
    }
    
    // Tính mức trailing stop mới
    double newStopLoss = 0;
    
    // Tính dựa trên loại phase
    switch(action.Phase) {
        case TRAILING_BREAKEVEN:
            // Đặt stop ở mức breakeven + buffer
            newStopLoss = isLong ? 
                entryPrice + m_Config.PartialClose.BreakEvenBuffer * _Point : 
                entryPrice - m_Config.PartialClose.BreakEvenBuffer * _Point;
            break;
            
        case TRAILING_FIRST_LOCK:
        case TRAILING_SECOND_LOCK:
        case TRAILING_THIRD_LOCK:
            // Tính mức trailing theo từng giai đoạn
            if (m_Config.UseChandelierExit) {
                // Dùng Chandelier Exit
                newStopLoss = CalculateChandelierExit(isLong, entryPrice, currentPrice);
                
                // Nếu không thể tính, dùng ATR trailing
                if (newStopLoss <= 0) {
                    newStopLoss = CalculateTrailingStop(currentPrice, entryPrice, atr, isLong, regime);
                }
            } else {
                // Dùng trailing ATR
                newStopLoss = CalculateTrailingStop(currentPrice, entryPrice, atr, isLong, regime);
            }
            break;
            
        default:
            newStopLoss = stopLoss;
    }
    
    // Đảm bảo trailing stop mới không lùi so với cũ
    if (isLong) {
        newStopLoss = MathMax(newStopLoss, stopLoss);
    } else {
        newStopLoss = MathMin(newStopLoss, stopLoss);
    }
    
    // Chuẩn hóa
    newStopLoss = NormalizeDouble(newStopLoss, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
    
    // Kiểm tra nếu stop đã thay đổi đáng kể
    bool significantChange = false;
    double minChange = 5 * _Point; // Tối thiểu 5 điểm
    
    if (isLong) {
        significantChange = (newStopLoss > stopLoss + minChange);
    } else {
        significantChange = (newStopLoss < stopLoss - minChange);
    }
    
    if (significantChange) {
        // Cập nhật trailing action
        action.ShouldTrail = true;
        action.NewStopLoss = newStopLoss;
        
        // Cập nhật trạng thái trailing
        m_CurrentTrailingPhase = action.Phase;
        m_LastTrailingStop = newStopLoss;
        
        if (m_Logger != NULL) {
            string phaseNames[] = {"None", "Breakeven", "First Lock", "Second Lock", "Third Lock", "Full"};
            
            m_Logger.LogInfo(StringFormat(
                "Smart Trailing R=%.2f, Phase=%s, Locked=%.0f%%: SL từ %.5f => %.5f",
                rMultiple, phaseNames[action.Phase], action.LockPercentage, stopLoss, newStopLoss
            ));
        }
    }
    
    return action;
}

//+------------------------------------------------------------------+
//| Should Partial Close                                            |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ShouldPartialClose(ulong ticket, double entryPrice, double currentPrice, 
                                     double stopLoss, bool isLong, int& closePhase, 
                                     double& closePercent)
{
    closePhase = 0;
    closePercent = 0;
    
    // Kiểm tra nếu đóng từng phần đã được bật
    if (!m_Config.PartialClose.UsePartialClose) return false;
    
    // Tính toán R-multiple hiện tại
    double rMultiple = CalculateRMultiple(entryPrice, currentPrice, stopLoss, isLong);
    
    // Xác định phase đóng
    // Phase 1: First target (R1)
    // Phase 2: Second target (R2)
    
    // Kiểm tra Phase 2 trước (higher priority)
    if (rMultiple >= m_Config.PartialClose.SecondRMultiple) {
        closePhase = 2;
        closePercent = m_Config.PartialClose.SecondClosePercent;
        return true;
    }
    // Kiểm tra Phase 1
    else if (rMultiple >= m_Config.PartialClose.FirstRMultiple) {
        closePhase = 1;
        closePercent = m_Config.PartialClose.FirstClosePercent;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Should Move To BreakEven                                       |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ShouldMoveToBreakEven(double entryPrice, double currentPrice, 
                                         double stopLoss, bool isLong)
{
    // Nếu chưa bật tính năng chuyển BE
    if (!m_Config.PartialClose.MoveToBreakEven) return false;
    
    // Tính R-multiple hiện tại
    double rMultiple = CalculateRMultiple(entryPrice, currentPrice, stopLoss, isLong);
    
    // Check if first R-multiple target reached
    if (rMultiple >= m_Config.PartialClose.FirstRMultiple) {
        // Kiểm tra nếu SL đã ở breakeven chưa
        bool isAtBreakeven = false;
        
        if (isLong) {
            isAtBreakeven = (stopLoss >= entryPrice);
        } else {
            isAtBreakeven = (stopLoss <= entryPrice);
        }
        
        return !isAtBreakeven;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if should scale position                                  |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ShouldScalePosition(ulong ticket, double currentPrice, double entryPrice, 
                                        double stopLoss, bool isLong, 
                                        const MarketProfileData &profile)
{
    // NGUYÊN TẮC: Chỉ scaling khi có lý do cực kỳ thuyết phục
    
    // --- ĐIỀU KIỆN TIÊN QUYẾT ---
    
    // 0. Kiểm tra tham số cấu hình (có thể tắt scaling hoàn toàn)
    if (!m_Config.EnableScaling) {
        return false;
    }
    
    // 1. Kiểm tra số lần scaling
    if (m_ScalingCount >= m_Config.MaxScalingCount) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Scaling rejected: Đã đạt giới hạn scaling (" + 
                           IntegerToString(m_ScalingCount) + "/" + 
                           IntegerToString(m_Config.MaxScalingCount) + ")");
        }
        return false;
    }
    
    // 2. Điều kiện không thể thương lượng: SL phải ở Breakeven+
    bool isBreakeven = false;
    
    if (isLong) {
        isBreakeven = (stopLoss >= entryPrice);
    } else {
        isBreakeven = (stopLoss <= entryPrice);
    }
    
    if (m_Config.RequireBreakEvenForScaling && !isBreakeven) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Scaling rejected: Stop loss not at breakeven yet");
        }
        return false;
    }
    
    // 3. Lệnh gốc phải đang có lãi đủ lớn
    double rMultiple = CalculateRMultiple(entryPrice, currentPrice, stopLoss, isLong);
    if (rMultiple < m_Config.MinRMultipleForScaling) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Scaling rejected: Original position profit < " + 
                           DoubleToString(m_Config.MinRMultipleForScaling, 1) + "R");
        }
        return false;
    }
    
    // --- ĐIỀU KIỆN THỊ TRƯỜNG ---
    
    // 4. Xu hướng phải rõ ràng nếu cấu hình yêu cầu
    if (m_Config.ScalingRequiresClearTrend) {
        bool isTrendClear = false;
        
        if (isLong) {
            isTrendClear = (profile.ema34 > profile.ema89 && profile.ema89 > profile.ema200);
        } else {
            isTrendClear = (profile.ema34 < profile.ema89 && profile.ema89 < profile.ema200);
        }
        
        if (!isTrendClear) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug("Scaling rejected: Trend not clear enough");
            }
            return false;
        }
    }
    
    // 5. Kiểm tra không có tin tức sắp diễn ra
    if (m_Config.NewsFilter.EnableNewsFilter && m_NewsFilter != NULL && ShouldAvoidTradingDueToNews(profile.currentSession)) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Scaling rejected: Upcoming news events");
        }
        return false;
    }
    
    // 6. Kiểm tra volatility
    if (m_Config.ApplyVolatilityAdjustment && profile.atrRatio > 2.0) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Scaling rejected: Volatility too high (x" + 
                           DoubleToString(profile.atrRatio, 1) + ")");
        }
        return false;
    }
    
    // --- ĐẠT TẤT CẢ ĐIỀU KIỆN ---
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Scaling conditions met for ticket %d, R=%.1f, IsLong=%s", 
            ticket, rMultiple, isLong ? "true" : "false"
        ));
    }
    
    // Tăng bộ đếm scaling
    m_ScalingCount++;
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate scaling lot size                                       |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateScalingLotSize(ulong ticket, double baseRiskPercent, 
                                             double entryPrice, double stopLoss, bool isLong)
{
    // Lấy ATR
    double atr = GetValidATR();
    if (atr <= 0) return 0;
    
    // 1. Xác định % risk cho lệnh scaling
    double scalingRiskPercent = baseRiskPercent * m_Config.ScalingRiskPercent;
    
    // 2. Tính khoảng cách SL
    double stopLossPoints = MathAbs(entryPrice - stopLoss) / _Point;
    
    // 3. Điều chỉnh theo biến động thị trường
    if (m_Config.ApplyVolatilityAdjustment) {
        double volFactor = GetVolatilityAdjustmentFactor();
        scalingRiskPercent *= volFactor;
    }
    
    // 4. Tính lot size
    double lotSize = CalculateLotSize(m_Symbol, stopLossPoints, entryPrice, 1.0, scalingRiskPercent);
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Scaling lot size: Risk=%.2f%%, SL Points=%.1f, Result=%.2f lots",
            scalingRiskPercent, stopLossPoints, lotSize
        ));
    }
    
    return lotSize;
}

//+------------------------------------------------------------------+
//| Check if should avoid trading due to news                        |
//+------------------------------------------------------------------+
bool CRiskOptimizer::ShouldAvoidTradingDueToNews(ENUM_SESSION currentSession)
{
    // Nếu không bật lọc tin hoặc không có NewsFilter, return false
    if (!m_Config.NewsFilter.EnableNewsFilter || m_NewsFilter == NULL) return false;
    
    // Kiểm tra tin tức tác động cao
    if (IsHighImpactNewsTime()) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Avoid trading: High impact news event nearby");
        }
        return true;
    }
    
    // Kiểm tra tin tức tác động trung bình
    if (IsMediumImpactNewsTime()) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo("Avoid trading: Medium impact news event nearby");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check for high impact news                                       |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsHighImpactNewsTime()
{
    if (m_NewsFilter == NULL) return false;
    
    return m_NewsFilter.HasNewsEvent(
        m_Config.NewsFilter.HighImpactMinutesBefore,
        m_Config.NewsFilter.HighImpactMinutesAfter,
        3  // Impact level 3 = High
    );
}

//+------------------------------------------------------------------+
//| Check for medium impact news                                     |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsMediumImpactNewsTime()
{
    if (m_NewsFilter == NULL) return false;
    
    return m_NewsFilter.HasNewsEvent(
        m_Config.NewsFilter.MediumImpactMinutesBefore,
        m_Config.NewsFilter.MediumImpactMinutesAfter,
        2  // Impact level 2 = Medium
    );
}

//+------------------------------------------------------------------+
//| Check spread acceptability                                       |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsSpreadAcceptable()
{
    // Lấy spread hiện tại (điểm)
    long currentSpreadPoints = SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD);
    double currentSpread = NormalizeDouble(currentSpreadPoints * _Point, _Digits);
    
    // Cập nhật lịch sử spread
    for (int i = 9; i > 0; i--) {
        m_SpreadHistory[i] = m_SpreadHistory[i-1];
    }
    m_SpreadHistory[0] = currentSpreadPoints;
    
    // Ưu tiên lấy giá trị từ AssetProfiler
    if (m_AssetProfiler != NULL) {
        double maxSpread = m_AssetProfiler.GetMaxAcceptableSpread(m_Symbol);
        if (maxSpread > 0 && currentSpreadPoints > maxSpread) {
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Spread không chấp nhận được: %.1f điểm > %.1f điểm (giới hạn)",
                    (double)currentSpreadPoints, maxSpread
                ));
            }
            return false;
        }
    }
    
    // Tính spread trung bình
    double avgSpread = GetAverageSpread();
    
    // Kiểm tra với giới hạn SpreadFactorLimit
    if (avgSpread > 0 && currentSpreadPoints > avgSpread * m_Config.SpreadFactorLimit) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "Spread quá cao: %.1f điểm > %.1f x %.1f điểm (trung bình)",
                (double)currentSpreadPoints, m_Config.SpreadFactorLimit, avgSpread
            ));
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Get average spread                                              |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetAverageSpread()
{
    // Nếu có trong AssetProfiler, ưu tiên lấy từ đó
    if (m_AssetProfiler != NULL) {
        double avgSpread = m_AssetProfiler.GetAverageSpread(m_Symbol);
        if (avgSpread > 0) {
            return avgSpread;
        }
    }
    
    // Tính từ lịch sử đã lưu
    double totalSpread = 0;
    int count = 0;
    
    for (int i = 0; i < 10; i++) {
        if (m_SpreadHistory[i] > 0) {
            totalSpread += m_SpreadHistory[i];
            count++;
        }
    }
    
    // Nếu không đủ dữ liệu, lấy spread hiện tại
    if (count == 0) {
        return (double)SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD);
    }
    
    return NormalizeDouble(totalSpread / count, 1);
}

//+------------------------------------------------------------------+
//| Check volatility acceptability                                   |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsVolatilityAcceptable()
{
    // Lấy tỷ lệ volatility
    double volatilityRatio = GetVolatilityRatio();
    
    // Nếu quá cao, từ chối
    if (volatilityRatio > m_Config.AutoPause.VolatilitySpikeFactor) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "Volatility quá cao: %.2fx > %.2fx (giới hạn)",
                volatilityRatio, m_Config.AutoPause.VolatilitySpikeFactor
            ));
        }
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Determine optimal trading strategy                              |
//+------------------------------------------------------------------+
ENUM_TRADING_STRATEGY CRiskOptimizer::DetermineOptimalStrategy(ENUM_MARKET_REGIME regime, 
                                                             double volatilityRatio,
                                                             double regimeConfidence)
{
    ENUM_TRADING_STRATEGY strategy = STRATEGY_PULLBACK; // Default strategy
    
    // Chỉ tính toán lại chiến lược nếu:
    // 1. Chưa từng tính
    // 2. Bar mới
    // 3. Đã qua đủ thời gian
    datetime currentTime = TimeCurrent();
    
    if (m_LastStrategyUpdateTime > 0 && 
        currentTime - m_LastStrategyUpdateTime < 3600 && // 1 hour
        !m_IsNewBar) {
        return m_CurrentStrategy;
    }
    
    // 1. Xác định chiến lược dựa trên regime
    switch(regime) {
        case REGIME_TRENDING:
            // Xu hướng mạnh? Dùng Breakout. Không thì Pullback
            if (regimeConfidence > 0.8) {
                strategy = STRATEGY_BREAKOUT;
            } else {
                strategy = STRATEGY_PULLBACK;
            }
            break;
            
        case REGIME_RANGING:
            // Sideway: Dùng Mean Reversion
            strategy = STRATEGY_MEAN_REVERSION;
            break;
            
        case REGIME_VOLATILE:
            // Biến động cao, cẩn thận
            if (volatilityRatio > 2.0) {
                // Trong quá trình bùng nổ, dùng Volatility Breakout
                strategy = STRATEGY_VOLATILITY_BREAKOUT;
            } else {
                // Biến động cao nhưng không quá đáng, bảo thủ
                strategy = STRATEGY_PRESERVATION;
            }
            break;
            
        default:
            // Không xác định được, dùng Pullback (an toàn nhất)
            strategy = STRATEGY_PULLBACK;
    }
    
    // 2. Có thể điều chỉnh thêm dựa trên biến động
    if (volatilityRatio < 0.7 && strategy == STRATEGY_PULLBACK) {
        // Biến động thấp trong xu hướng, cân nhắc Mean Reversion
        strategy = STRATEGY_MEAN_REVERSION;
    }
    else if (volatilityRatio > 2.5) {
        // Biến động quá cao, chọn chiến lược bảo thủ nhất
        strategy = STRATEGY_PRESERVATION;
    }
    
    // 3. Nếu chế độ PropFirm, giới hạn các chiến lược rủi ro cao
    if (m_Config.PropFirmMode) {
        if (strategy == STRATEGY_BREAKOUT || strategy == STRATEGY_VOLATILITY_BREAKOUT) {
            // Chuyển sang Pullback an toàn hơn
            strategy = STRATEGY_PULLBACK;
        }
    }
    
    // Cập nhật strategy hiện tại và thời gian
    if (m_CurrentStrategy != strategy) {
        if (m_Logger != NULL) {
            string strategyNames[] = {"Breakout", "Pullback", "Mean Reversion", "Volatility Breakout", "Preservation"};
            
            m_Logger.LogInfo(StringFormat(
                "Thay đổi chiến lược: %s -> %s",
                strategyNames[m_CurrentStrategy], strategyNames[strategy]
            ));
        }
        
        m_CurrentStrategy = strategy;
    }
    
    m_LastStrategyUpdateTime = currentTime;
    
    return strategy;
}

//+------------------------------------------------------------------+
//| Check pause condition                                           |
//+------------------------------------------------------------------+
PauseState CRiskOptimizer::CheckPauseCondition(int consecutiveLosses, double dailyLoss)
{
    PauseState state;
    state.ShouldPause = false;
    state.Reason = PAUSE_NONE;
    state.PauseMinutes = 0;
    state.Message = "";
    
    // Nếu không bật AutoPause, không pause
    if (!m_Config.AutoPause.EnableAutoPause) return state;
    
    // 1. Kiểm tra số lần thua liên tiếp
    if (consecutiveLosses >= m_Config.AutoPause.ConsecutiveLossesLimit) {
        state.ShouldPause = true;
        state.Reason = PAUSE_CONSECUTIVE_LOSSES;
        state.PauseMinutes = m_Config.AutoPause.PauseMinutes;
        state.Message = StringFormat(
            "Pause triggered: %d consecutive losses (limit: %d)",
            consecutiveLosses, m_Config.AutoPause.ConsecutiveLossesLimit
        );
        
        return state;
    }
    
    // 2. Kiểm tra lỗ trong ngày
    if (dailyLoss >= m_Config.AutoPause.DailyLossPercentLimit) {
        state.ShouldPause = true;
        state.Reason = PAUSE_DAILY_LOSS_LIMIT;
        state.PauseMinutes = m_Config.AutoPause.PauseMinutes;
        state.Message = StringFormat(
            "Pause triggered: %.2f%% daily loss (limit: %.2f%%)",
            dailyLoss, m_Config.AutoPause.DailyLossPercentLimit
        );
        
        return state;
    }
    
    // 3. Kiểm tra biến động cao bất thường
    double volatilityRatio = GetVolatilityRatio();
    
    if (volatilityRatio > m_Config.AutoPause.VolatilitySpikeFactor) {
        state.ShouldPause = true;
        state.Reason = PAUSE_VOLATILITY_SPIKE;
        state.PauseMinutes = 30; // Shorter period for volatility spike
        state.Message = StringFormat(
            "Pause triggered: Volatility spike %.2fx (limit: %.2fx)",
            volatilityRatio, m_Config.AutoPause.VolatilitySpikeFactor
        );
        
        return state;
    }
    
    // 4. Kiểm tra tin tức quan trọng
    if (m_Config.NewsFilter.EnableNewsFilter && m_NewsFilter != NULL && IsHighImpactNewsTime()) {
        state.ShouldPause = true;
        state.Reason = PAUSE_NEWS_FILTER;
        state.PauseMinutes = m_Config.NewsFilter.HighImpactMinutesBefore + 
                           m_Config.NewsFilter.HighImpactMinutesAfter;
        state.Message = "Pause triggered: High impact news event";
        
        return state;
    }
    
    return state;
}

//+------------------------------------------------------------------+
//| Set pause state                                                 |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetPauseState(PauseState &state)
{
    if (!state.ShouldPause) {
        // Reset pause state
        m_IsPaused = false;
        m_PauseUntil = 0;
        return;
    }
    
    // Set pause state
    m_IsPaused = true;
    m_PauseUntil = TimeCurrent() + state.PauseMinutes * 60; // Convert to seconds
    
    if (m_Logger != NULL) {
        string reasonNames[] = {"None", "Consecutive Losses", "Daily Loss", "Volatility Spike", "News Filter", "Manual"};
        
        m_Logger.LogInfo(StringFormat(
            "EA paused: %s. Resume after: %s",
            reasonNames[state.Reason], TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES)
        ));
    }
}

//+------------------------------------------------------------------+
//| Check if can resume trading                                      |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CheckResumeCondition()
{
    if (!m_IsPaused) return false;
    if (!m_Config.AutoPause.EnableAutoResume) return false;
    
    datetime currentTime = TimeCurrent();
    
    // 1. Nếu đã hết thời gian pause
    if (currentTime >= m_PauseUntil) {
        if (m_Logger != NULL) {
            m_Logger.LogInfo("EA resumed: Pause time expired");
        }
        return true;
    }
    
    // 2. Nếu bật resume khi đổi phiên
    if (m_Config.AutoPause.ResumeOnSessionChange) {
        ENUM_SESSION currentSession = SESSION_UNKNOWN;
        
        if (m_SafeData != NULL) {
            currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
        } else if (m_Profile != NULL) {
            currentSession = m_Profile.GetCurrentSession();
        }
        
        // Nếu phiên đã thay đổi
        if (currentSession != SESSION_UNKNOWN && 
            currentSession != m_LastSession && 
            m_LastSession != SESSION_UNKNOWN) {
            
            if (m_Logger != NULL) {
                string sessionNames[] = {"Unknown", "Asian", "European", "American", "EU-US Overlap", "Closing"};
                
                m_Logger.LogInfo(StringFormat(
                    "EA resumed: Session changed from %s to %s",
                    sessionNames[m_LastSession], sessionNames[currentSession]
                ));
            }
            
            return true;
        }
    }
    
    // 3. Nếu bật resume khi sang ngày mới
    if (m_Config.AutoPause.ResumeOnNewDay) {
        MqlDateTime dt;
        TimeToStruct(currentTime, dt);
        
        if (dt.day != m_LastTradeDay && m_LastTradeDay > 0) {
            if (m_Logger != NULL) {
                m_Logger.LogInfo(StringFormat(
                    "EA resumed: New trading day %d (previous: %d)",
                    dt.day, m_LastTradeDay
                ));
            }
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update daily statistics                                          |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateDailyState()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Nếu ngày mới
    if (dt.day != m_LastTradeDay) {
        // Reset thống kê ngày
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_CurrentDailyLoss = 0.0;
        m_TotalTradesDay = 0;
        m_LastTradeDay = dt.day;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "New trading day: %04d-%02d-%02d, Balance: %.2f",
                dt.year, dt.mon, dt.day, m_DayStartBalance
            ));
        }
    }
    
    // Reset m_ScalingCount nếu cần
    static datetime lastResetTime = 0;
    if (TimeCurrent() - lastResetTime > 4*3600) { // 4 giờ
        m_ScalingCount = 0;
        lastResetTime = TimeCurrent();
    }
}

//+------------------------------------------------------------------+
//| Update daily loss                                                |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateDailyLoss()
{
    double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Nếu balance giảm so với đầu ngày
    if (currentBalance < m_DayStartBalance) {
        m_CurrentDailyLoss = (m_DayStartBalance - currentBalance) / m_DayStartBalance * 100.0;
    } else {
        m_CurrentDailyLoss = 0.0;
    }
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Current daily loss: %.2f%% (Start: %.2f, Current: %.2f)",
            m_CurrentDailyLoss, m_DayStartBalance, currentBalance
        ));
    }
}

//+------------------------------------------------------------------+
//| Update time cycles (weekly, monthly)                             |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateTimeCycles()
{
    if (!m_Config.EnableWeeklyCycle && !m_Config.EnableMonthlyCycle) return;
    
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Check for new week (Monday)
    if (m_Config.EnableWeeklyCycle && dt.day_of_week == 1) {
        // Calculate Monday date
        datetime monday = TimeCurrent() - (dt.hour * 3600 + dt.min * 60 + dt.sec);
        
        // If new week
        if (monday != m_LastWeekMonday) {
            // Reset weekly profit
            m_WeeklyProfit = 0.0;
            m_LastWeekMonday = monday;
            
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug("New trading week started, reset weekly profit");
            }
        }
    }
    
    // Check for new month
    if (m_Config.EnableMonthlyCycle && dt.mon != m_CurrentMonth) {
        // Reset monthly profit
        m_MonthlyProfit = 0.0;
        m_CurrentMonth = dt.mon;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("New trading month started, reset monthly profit");
        }
    }
}

//+------------------------------------------------------------------+
//| Update trading result                                            |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateTradingResult(bool isWin, double profit)
{
    // Update consecutive win/loss counts
    if (isWin) {
        m_ConsecutiveLosses = 0;
        m_ConsecutiveProfitDays++;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Win registered: $%.2f, Consecutive profit days: %d",
                profit, m_ConsecutiveProfitDays
            ));
        }
    } else {
        m_ConsecutiveLosses++;
        m_ConsecutiveProfitDays = 0;
        
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "Loss registered: $%.2f, Consecutive losses: %d",
                profit, m_ConsecutiveLosses
            ));
        }
    }
    
    // Update weekly/monthly profit
    if (m_Config.EnableWeeklyCycle) {
        m_WeeklyProfit += profit;
    }
    
    if (m_Config.EnableMonthlyCycle) {
        m_MonthlyProfit += profit;
    }
    
    // Increment daily trade count
    m_TotalTradesDay++;
}

//+------------------------------------------------------------------+
//| Apply smart risk based on performance                            |
//+------------------------------------------------------------------+
double CRiskOptimizer::ApplySmartRisk(double baseRiskPercent, int consecutiveLosses, 
                                    double winRate, ENUM_CLUSTER_TYPE cluster, 
                                    ENUM_MARKET_REGIME regime)
{
    double smartRisk = baseRiskPercent;
    
    // 1. Adjust based on consecutive losses
    if (consecutiveLosses > 0) {
        double lossAdjust = 1.0 - (consecutiveLosses * 0.1);
        lossAdjust = MathMax(lossAdjust, 0.5); // Not less than 50%
        smartRisk *= lossAdjust;
    }
    
    // 2. Adjust based on win rate
    if (winRate > 0) {
        double winAdjust = 1.0;
        
        if (winRate > 0.6) {
            // High win rate - increase risk slightly
            winAdjust = 1.0 + ((winRate - 0.6) / 0.4) * 0.2; // Max +20%
        } else if (winRate < 0.4) {
            // Low win rate - decrease risk
            winAdjust = 1.0 - ((0.4 - winRate) / 0.4) * 0.3; // Max -30%
        }
        
        smartRisk *= winAdjust;
    }
    
    // 3. Adjust based on cluster type
    switch(cluster) {
        case CLUSTER_1_TREND_FOLLOWING:
            // Trend following - slightly higher risk
            smartRisk *= 1.1;
            break;
        case CLUSTER_2_COUNTERTREND:
            // Counter trend - lower risk
            smartRisk *= 0.9;
            break;
        case CLUSTER_3_SCALING:
            // Scaling - depends on other factors
            break;
    }
    
    // 4. Adjust based on market regime
    switch(regime) {
        case REGIME_TRENDING:
            // Trending - no change
            break;
        case REGIME_RANGING:
            // Ranging - reduce risk
            smartRisk *= 0.9;
            break;
        case REGIME_VOLATILE:
            // Volatile - reduce risk significantly
            smartRisk *= 0.7;
            break;
    }
    
    // 5. Apply PropFirm mode limits if enabled
    if (m_Config.PropFirmMode) {
        smartRisk = MathMin(smartRisk, baseRiskPercent);
    }
    
    // Ensure risk doesn't exceed maximum
    smartRisk = MathMin(smartRisk, m_Config.MaxRiskPercent);
    
    // Ensure there's always some minimal risk
    smartRisk = MathMax(smartRisk, m_Config.RiskPercent * 0.3);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Smart Risk: %.2f%% -> %.2f%% (WinRate=%.1f%%, Losses=%d, Cluster=%d, Regime=%d)",
            baseRiskPercent, smartRisk, winRate * 100, consecutiveLosses, cluster, regime
        ));
    }
    
    return NormalizeDouble(smartRisk, 2);
}

//+------------------------------------------------------------------+
//| Apply cyclical risk adjustments                                 |
//+------------------------------------------------------------------+
double CRiskOptimizer::ApplyCyclicalRisk(double baseRiskPercent)
{
    if (!m_Config.EnableWeeklyCycle && !m_Config.EnableMonthlyCycle) {
        return baseRiskPercent;
    }
    
    double cyclicalRisk = baseRiskPercent;
    double adjustFactor = 1.0;
    
    // 1. Apply weekly cycle adjustment
    if (m_Config.EnableWeeklyCycle) {
        if (m_WeeklyProfit < 0) {
            // Weekly loss - reduce risk
            adjustFactor *= m_Config.WeeklyLossReduceFactor;
        }
    }
    
    // 2. Apply monthly cycle adjustment
    if (m_Config.EnableMonthlyCycle) {
        if (m_MonthlyProfit > 0) {
            // Monthly profit - boost risk
            adjustFactor *= m_Config.MonthlyProfitBoostFactor;
        }
    }
    
    // 3. Apply consecutive profit days boost
    if (m_ConsecutiveProfitDays >= m_Config.ConsecutiveProfitDaysBoost) {
        // Boost after consecutive profitable days
        double profitBoost = 1.0 + (m_ConsecutiveProfitDays - m_Config.ConsecutiveProfitDaysBoost + 1) * 0.05;
        profitBoost = MathMin(profitBoost, 1.2); // Max +20%
        adjustFactor *= profitBoost;
    }
    
    // Apply overall factor with limits
    if (adjustFactor > 1.0) {
        // Boost limited by MaxCycleRiskBoost
        adjustFactor = MathMin(adjustFactor, m_Config.MaxCycleRiskBoost);
    } else {
        // Reduction limited by MaxCycleRiskReduction
        adjustFactor = MathMax(adjustFactor, m_Config.MaxCycleRiskReduction);
    }
    
    cyclicalRisk = baseRiskPercent * adjustFactor;
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Cyclical Risk: %.2f%% -> %.2f%% (Factor=%.2f, Weekly=$%.2f, Monthly=$%.2f, Streak=%d)",
            baseRiskPercent, cyclicalRisk, adjustFactor, m_WeeklyProfit, m_MonthlyProfit, m_ConsecutiveProfitDays
        ));
    }
    
    return NormalizeDouble(cyclicalRisk, 2);
}

//+------------------------------------------------------------------+
//| Get symbol-specific risk adjustment                              |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetSymbolRiskAdjustment()
{
    // Ưu tiên lấy từ AssetProfiler nếu có
    if (m_AssetProfiler != NULL) {
        double symbolRiskFactor = m_AssetProfiler.GetSymbolRiskFactor(m_Symbol);
        if (symbolRiskFactor > 0) {
            return symbolRiskFactor;
        }
    }
    
    // Mặc định: phân loại theo loại tài sản
    string symbolUpper = StringToUpper(m_Symbol);
    
    // Forex Majors - 100% risk
    if (StringFind(symbolUpper, "EURUSD") >= 0 || 
        StringFind(symbolUpper, "GBPUSD") >= 0 || 
        StringFind(symbolUpper, "USDJPY") >= 0 || 
        StringFind(symbolUpper, "AUDUSD") >= 0) {
        return 1.0;
    }
    
    // Forex minor/exotic - 80% risk
    if (StringFind(symbolUpper, "USD") >= 0 || 
        StringFind(symbolUpper, "EUR") >= 0 || 
        StringFind(symbolUpper, "GBP") >= 0 || 
        StringFind(symbolUpper, "JPY") >= 0 || 
        StringFind(symbolUpper, "CAD") >= 0) {
        return 0.8;
    }
    
    // Metals - 70% risk
    if (StringFind(symbolUpper, "GOLD") >= 0 || 
        StringFind(symbolUpper, "XAUUSD") >= 0 || 
        StringFind(symbolUpper, "SILVER") >= 0 || 
        StringFind(symbolUpper, "XAGUSD") >= 0) {
        return 0.7;
    }
    
    // Indices - 60% risk
    if (StringFind(symbolUpper, "S&P") >= 0 || 
        StringFind(symbolUpper, "SPX") >= 0 || 
        StringFind(symbolUpper, "NAS") >= 0 || 
        StringFind(symbolUpper, "DJ") >= 0 || 
        StringFind(symbolUpper, "DAX") >= 0) {
        return 0.6;
    }
    
    // Crypto (high volatility) - 40% risk
    if (StringFind(symbolUpper, "BTC") >= 0 || 
        StringFind(symbolUpper, "ETH") >= 0) {
        return 0.4;
    }
    
    // Default - 50% risk (unknown/other)
    return 0.5;
}

//+------------------------------------------------------------------+
//| Export performance statistics                                    |
//+------------------------------------------------------------------+
void CRiskOptimizer::ExportPerformanceStats(string filename)
{
    if (filename == "") {
        filename = "RiskOptimizer_Stats_" + m_Symbol + ".csv";
    }
    
    int handle = FileOpen(filename, FILE_WRITE|FILE_CSV, ",");
    if (handle == INVALID_HANDLE) {
        if (m_Logger != NULL) {
            m_Logger.LogError("Failed to open file for writing statistics: " + IntegerToString(GetLastError()));
        }
        return;
    }
    
    // Write header
    FileWrite(handle, "Date", "Symbol", "Consecutive Losses", "Daily Trades", 
              "Risk%", "Daily Loss%", "Weekly P/L", "Monthly P/L", 
              "Scaling Count", "Pause Status", "Strategy");
    
    // Write data
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    string dateStr = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);
    
    string strategyNames[] = {"Breakout", "Pullback", "Mean Reversion", "Volatility Breakout", "Preservation"};
    
    FileWrite(handle, 
              dateStr,
              m_Symbol,
              IntegerToString(m_ConsecutiveLosses),
              IntegerToString(m_TotalTradesDay),
              DoubleToString(m_Config.RiskPercent, 2),
              DoubleToString(m_CurrentDailyLoss, 2),
              DoubleToString(m_WeeklyProfit, 2),
              DoubleToString(m_MonthlyProfit, 2),
              IntegerToString(m_ScalingCount),
              m_IsPaused ? "Paused" : "Active",
              strategyNames[m_CurrentStrategy]
    );
    
    FileClose(handle);
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo("Performance statistics exported to: " + filename);
    }
}

//+------------------------------------------------------------------+
//| Hybrid SL/TP calculation combining structure and ATR             |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CalculateHybridSLTP(double entryPrice, bool isLong, double &stopLoss,
                                        double &takeProfit, ENUM_CLUSTER_TYPE cluster)
{
    // 1. Get ATR
    double atr = GetValidATR();
    if (atr <= 0) return false;
    
    // 2. Get SL/TP multipliers for cluster
    double slMultiplier = GetSLMultiplierForCluster(cluster);
    double tpMultiplier = GetTPMultiplierForCluster(cluster);
    
    // 3. Calculate ATR-based SL/TP
    double atrSL = 0, atrTP = 0;
    
    if (isLong) {
        atrSL = entryPrice - (atr * slMultiplier);
        atrTP = entryPrice + (atr * slMultiplier * tpMultiplier);
    } else {
        atrSL = entryPrice + (atr * slMultiplier);
        atrTP = entryPrice - (atr * slMultiplier * tpMultiplier);
    }
    
    // 4. Try to find structure-based levels
    double structSL = 0, structTP = 0;
    bool foundStructLevels = false;
    
    if (m_SwingDetector != NULL) {
        double swingLevel = 0;
        int swingBar = 0;
        
        // Look for swing points for SL
        if (FindSwingPoints(isLong, 50, swingLevel, swingBar)) {
            // Add small buffer to swing level
            double buffer = atr * 0.2;
            
            structSL = isLong ? swingLevel - buffer : swingLevel + buffer;
            foundStructLevels = true;
            
            // Calculate TP based on R:R
            double slDistance = MathAbs(entryPrice - structSL);
            structTP = isLong ? entryPrice + (slDistance * tpMultiplier) : 
                              entryPrice - (slDistance * tpMultiplier);
        }
    }
    
    // 5. Choose the best SL/TP combination
    if (foundStructLevels) {
        // Validate structure-based SL isn't too far/close
        double structSLDistance = MathAbs(entryPrice - structSL);
        double maxSLDistance = atr * slMultiplier * 2.0; // Max 2x ATR-based SL
        
        if (structSLDistance <= maxSLDistance && structSLDistance >= atr * 0.5) {
            // Use structure-based SL/TP if valid
            stopLoss = structSL;
            takeProfit = structTP;
            
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Using structure-based SL/TP: SL=%.5f, TP=%.5f",
                    stopLoss, takeProfit
                ));
            }
        } else {
            // Fallback to ATR-based if structure SL invalid
            stopLoss = atrSL;
            takeProfit = atrTP;
            
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Structure SL invalid (%.5f), using ATR-based: SL=%.5f, TP=%.5f",
                    structSL, stopLoss, takeProfit
                ));
            }
        }
    } else {
        // No structure found, use ATR-based
        stopLoss = atrSL;
        takeProfit = atrTP;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "No structure found, using ATR-based: SL=%.5f, TP=%.5f",
                stopLoss, takeProfit
            ));
        }
    }
    
    // 6. Normalize values
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    return true;
}

//+------------------------------------------------------------------+
//| Find swing points for SL placement                               |
//+------------------------------------------------------------------+
bool CRiskOptimizer::FindSwingPoints(bool isLong, int lookbackBars, double &swingLevel, int &swingBar)
{
    if (m_SwingDetector == NULL) return false;
    
    swingLevel = 0;
    swingBar = 0;
    
    // For long trades, find recent swing low
    // For short trades, find recent swing high
    if (isLong) {
        swingLevel = m_SwingDetector.GetLastSwingLow();
    } else {
        swingLevel = m_SwingDetector.GetLastSwingHigh();
    }
    
    if (swingLevel <= 0) return false;
    
    // Swing point found
    return true;
}

//+------------------------------------------------------------------+
//| Check if the pullback setup is valid                             |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsValidPullbackSetup(bool isLong, const MarketProfileData &profile)
{
    // Similar to ValidatePullbackZone but with more detailed checks
    double currentPrice = SymbolInfoDouble(m_Symbol, isLong ? SYMBOL_ASK : SYMBOL_BID);
    
    // 1. Check EMA alignment
    bool emaAligned = false;
    if (isLong) {
        // Long: EMA34 > EMA89 > EMA200
        emaAligned = (profile.ema34 > profile.ema89 && profile.ema89 > profile.ema200);
    } else {
        // Short: EMA34 < EMA89 < EMA200
        emaAligned = (profile.ema34 < profile.ema89 && profile.ema89 < profile.ema200);
    }
    
    if (!emaAligned) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Pullback setup invalid: EMA not aligned with trend");
        }
        return false;
    }
    
    // 2. Check for adequate ADX
    if (profile.adxValue < m_Config.MinPullbackPercent) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Pullback setup invalid: ADX too low (%.1f < %.1f)",
                profile.adxValue, m_Config.MinPullbackPercent
            ));
        }
        return false;
    }
    
    // 3. Check price in pullback zone
    bool inPullbackZone = false;
    
    if (isLong) {
        // Long setup: Price should be near/below EMA34 but not too far below EMA89
        inPullbackZone = (currentPrice <= profile.ema34 * 1.002) && 
                        (currentPrice >= profile.ema89 * 0.995) &&
                        (currentPrice > profile.ema200);  // Never below EMA200
    } else {
        // Short setup: Price should be near/above EMA34 but not too far above EMA89
        inPullbackZone = (currentPrice >= profile.ema34 * 0.998) && 
                        (currentPrice <= profile.ema89 * 1.005) &&
                        (currentPrice < profile.ema200);  // Never above EMA200
    }
    
    if (!inPullbackZone) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Pullback setup invalid: Price not in pullback zone");
        }
        return false;
    }
    
    // 4. Check pullback percentage
    double pullbackPercent = CalculatePullbackPercent(currentPrice, isLong, profile);
    if (pullbackPercent < m_Config.MinPullbackPercent || 
        pullbackPercent > m_Config.MaxPullbackPercent) {
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Pullback setup invalid: Pullback percentage %.1f%% outside range %.1f-%.1f%%",
                pullbackPercent, m_Config.MinPullbackPercent, m_Config.MaxPullbackPercent
            ));
        }
        return false;
    }
    
    // 5. Check if volatility is acceptable
    if (profile.isVolatile && profile.atrRatio > 2.0) {
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Pullback setup invalid: Volatility too high (%.1fx)",
                profile.atrRatio
            ));
        }
        return false;
    }
    
    // All checks passed
    return true;
}

//+------------------------------------------------------------------+
//| Calculate session-based risk adjustment                          |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateSessionRiskAdjustment(ENUM_SESSION session)
{
    // Adjust risk based on session
    switch(session) {
        case SESSION_ASIAN:
            // Asian session - lower volatility, reduce risk
            return 0.8;
            
        case SESSION_EUROPEAN:
            // European session - normal risk
            return 1.0;
            
        case SESSION_AMERICAN:
            // American session - normal risk
            return 1.0;
            
        case SESSION_EUROPEAN_AMERICAN:
            // Overlap - higher volatility, potentially good opportunity
            return 1.1;
            
        case SESSION_CLOSING:
            // Closing session - reduce risk due to potential gaps
            return 0.7;
            
        default:
            return 1.0;
    }
}

//+------------------------------------------------------------------+
//| Check if it's an optimal trading time                            |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsOptimalTradingTime()
{
    // Get current session
    ENUM_SESSION currentSession = SESSION_UNKNOWN;
    
    if (m_SafeData != NULL) {
        currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
    } else if (m_Profile != NULL) {
        currentSession = m_Profile.currentSession;
    }
    
    // London/New York opens are typically more volatile
    bool isLondonOpen = false;
    bool isNewYorkOpen = false;
    
    if (m_SafeData != NULL) {
        isLondonOpen = m_SafeData.IsLondonOpen();
        isNewYorkOpen = m_SafeData.IsNewYorkOpen();
    }
    
    // Check for optimal times
    if (isLondonOpen && m_Symbol == "EURUSD") {
        return true;
    }
    
    if (isNewYorkOpen && (m_Symbol == "GBPUSD" || m_Symbol == "EURUSD")) {
        return true;
    }
    
    // European/American overlap is generally good for forex
    if (currentSession == SESSION_EUROPEAN_AMERICAN) {
        return true;
    }
    
    // Default - not an optimal time
    return false;
}