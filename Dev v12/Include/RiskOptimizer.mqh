//+------------------------------------------------------------------+
//|                   Risk Optimizer Module v13.0                    |
//|                   (for ApexPullback EA v13.0)                    |
//+------------------------------------------------------------------+
#property strict

#include "CommonStructs.mqh"
#include "MarketProfile.mqh"
#include "Logger.mqh"
#include "RiskManager.mqh"
#include "SwingPointDetector.mqh"

//====================================================
// Struct Config cho Risk Optimizer
//====================================================
struct SRiskOptimizerConfig {
    // Cấu hình cơ bản
    double RiskPercent;                  // Risk % gốc
    double SL_ATR_Multiplier;            // Hệ số SL theo ATR
    double TP_RR_Ratio;                  // Tỷ lệ Risk:Reward cho TP
    double MaxAllowedDrawdown;           // Drawdown tối đa cho phép (%)
    
    // Cấu hình giảm risk theo drawdown
    double DrawdownReduceThreshold;      // Ngưỡng DD bắt đầu giảm risk
    bool   EnableTaperedRisk;            // Chế độ giảm risk từ từ
    double MinRiskMultiplier;            // Hệ số risk tối thiểu khi DD cao
    
    // Giới hạn risk tối đa
    bool   UseFixedMaxRiskUSD;           // Dùng giới hạn USD cố định
    double MaxRiskUSD;                   // Giới hạn risk tối đa mỗi lệnh ($)
    double MaxRiskPercent;               // Giới hạn risk tối đa (% tài khoản)
    
    // Cấu hình Chandelier Exit
    bool   UseChandelierExit;            // Kích hoạt Chandelier Exit
    int    ChandelierLookback;           // Số nến lookback
    double ChandelierATRMultiplier;      // Hệ số ATR cho chandelier
    
    // Hệ số điều chỉnh trailing
    double TrailingFactorTrend;          // Hệ số trailing trong xu hướng
    double TrailingFactorRanging;        // Hệ số trailing trong sideway
    double TrailingFactorVolatile;       // Hệ số trailing khi biến động cao
    
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
    
    // AutoPause
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
    
    // Constructor với giá trị mặc định
    SRiskOptimizerConfig() {
        RiskPercent = 1.0;
        SL_ATR_Multiplier = 1.5;
        TP_RR_Ratio = 2.0;
        MaxAllowedDrawdown = 10.0;
        
        DrawdownReduceThreshold = 5.0;
        EnableTaperedRisk = true;
        MinRiskMultiplier = 0.3;
        
        UseFixedMaxRiskUSD = false;
        MaxRiskUSD = 500.0;
        MaxRiskPercent = 2.0;
        
        UseChandelierExit = true;
        ChandelierLookback = 20;
        ChandelierATRMultiplier = 3.0;
        
        TrailingFactorTrend = 1.2;
        TrailingFactorRanging = 0.8;
        TrailingFactorVolatile = 1.5;
        
        CacheTimeSeconds = 10;
        UseBartimeCache = true;
        
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
    CSafeDataProvider(string symbol, ENUM_TIMEFRAMES timeframe, CLogger* logger) : 
        m_Symbol(symbol), m_Timeframe(timeframe), m_Logger(logger) {
        
        // Khởi tạo các cache
        m_ATRCache.Value = 0;
        m_ATRCache.LastUpdate = 0;
        m_ATRCache.BarTime = 0;
        m_ATRCache.IsValid = false;
        
        m_ADXCache.Value = 0;
        m_ADXCache.LastUpdate = 0;
        m_ADXCache.BarTime = 0;
        m_ADXCache.IsValid = false;
        
        m_RSICache.Value = 0;
        m_RSICache.LastUpdate = 0;
        m_RSICache.BarTime = 0;
        m_RSICache.IsValid = false;
    }
    
    // Lấy ATR an toàn với nhiều lớp fallback
    double GetSafeATR(CMarketProfile* profile, ENUM_TIMEFRAMES timeframe, int period = 14, bool forceUpdate = false) {
        // Kiểm tra bar mới
        datetime currentBarTime = GetCurrentBarTime(timeframe);
        
        // Nếu cache hợp lệ và không phải bar mới, dùng cache
        if (!forceUpdate && m_ATRCache.IsValid && currentBarTime > 0 && 
            currentBarTime == m_ATRCache.BarTime && 
            TimeCurrent() - m_ATRCache.LastUpdate < 10) {
            return m_ATRCache.Value;
        }
        
        // Nếu đến đây, cần tính ATR mới
        double atr = 0.0;
        
        // Thử lấy từ Market Profile
        if (profile != NULL) {
            double profileATR = profile.GetATRH4();
            if (profileATR > 0) atr = profileATR;
        }
        
        // Nếu chưa có giá trị, tính trực tiếp từ timeframe
        if (atr <= 0) {
            int handle = iATR(m_Symbol, timeframe, period);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    atr = buffer[0];
                }
                IndicatorRelease(handle);
            }
        }
        
        // Fallback 1: Thử tính từ H4 (nếu khác H4)
        if (atr <= 0 && timeframe != PERIOD_H4) {
            int handle = iATR(m_Symbol, PERIOD_H4, period);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    atr = buffer[0];
                }
                IndicatorRelease(handle);
                
                if (m_Logger != NULL) m_Logger.LogDebug("Dùng ATR H4 fallback");
            }
        }
        
        // Fallback 2: Thử tính từ D1
        if (atr <= 0) {
            int handle = iATR(m_Symbol, PERIOD_D1, period);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    atr = buffer[0];
                }
                IndicatorRelease(handle);
                
                if (m_Logger != NULL) m_Logger.LogDebug("Dùng ATR D1 fallback");
            }
        }
        
        // Fallback cuối cùng: Ước tính từ point
        if (atr <= 0) {
            atr = SymbolInfoDouble(m_Symbol, SYMBOL_POINT) * 100;
            if (m_Logger != NULL) m_Logger.LogWarning("Dùng ATR estimated fallback: " + DoubleToString(atr, 5));
        }
        
        // Cập nhật cache
        m_ATRCache.Value = atr;
        m_ATRCache.LastUpdate = TimeCurrent();
        m_ATRCache.BarTime = currentBarTime;
        m_ATRCache.IsValid = (atr > 0);
        
        return atr;
    }
    
    // Lấy ADX an toàn
    double GetSafeADX(CMarketProfile* profile, ENUM_TIMEFRAMES timeframe, int period = 14, bool forceUpdate = false) {
        // Kiểm tra bar mới
        datetime currentBarTime = GetCurrentBarTime(timeframe);
        
        // Nếu cache hợp lệ và không phải bar mới, dùng cache
        if (!forceUpdate && m_ADXCache.IsValid && currentBarTime > 0 && 
            currentBarTime == m_ADXCache.BarTime && 
            TimeCurrent() - m_ADXCache.LastUpdate < 10) {
            return m_ADXCache.Value;
        }
        
        // Nếu đến đây, cần tính ADX mới
        double adx = 0.0;
        
        // Thử lấy từ Market Profile
        if (profile != NULL) {
            adx = profile.GetADXH4();
        }
        
        // Nếu chưa có giá trị, tính trực tiếp từ indicator
        if (adx <= 0) {
            int handle = iADX(m_Symbol, timeframe, period);
            if (handle != INVALID_HANDLE) {
                double buffer[];
                ArraySetAsSeries(buffer, true);
                if (CopyBuffer(handle, 0, 0, 1, buffer) > 0) {
                    adx = buffer[0];
                }
                IndicatorRelease(handle);
            }
        }
        
        // Cập nhật cache
        m_ADXCache.Value = adx;
        m_ADXCache.LastUpdate = TimeCurrent();
        m_ADXCache.BarTime = currentBarTime;
        m_ADXCache.IsValid = (adx > 0);
        
        return adx;
    }
    
    // Lấy volatility ratio an toàn
    double GetSafeVolatilityRatio(CMarketProfile* profile, double averageATR) {
        // Thử lấy từ Market Profile
        if (profile != NULL) {
            double ratio = profile.GetVolatilityRatio();
            if (ratio > 0) return ratio;
        }
        
        // Tính thủ công nếu có ATR trung bình
        if (averageATR > 0) {
            double currentATR = GetSafeATR(profile, m_Timeframe);
            if (currentATR > 0) {
                return currentATR / averageATR;
            }
        }
        
        // Fallback: Giá trị mặc định
        return 1.0;
    }
    
    // Lấy phiên giao dịch an toàn
    ENUM_SESSION GetSafeCurrentSession(CMarketProfile* profile) {
        // Thử lấy từ Market Profile
        if (profile != NULL) {
            ENUM_SESSION session = profile.GetCurrentSession();
            if (session != SESSION_UNKNOWN) return session;
        }
        
        // Tính dựa trên giờ GMT
        MqlDateTime dt;
        TimeToStruct(TimeGMT(), dt);
        int hour = dt.hour;
        
        // Phiên Á: 00:00 - 08:00 GMT
        if (hour >= 0 && hour < 8) {
            return SESSION_ASIAN;
        }
        // Phiên Âu: 08:00 - 16:00 GMT
        else if (hour >= 8 && hour < 13) {
            return SESSION_EUROPEAN;
        }
        // Phiên Overlap Âu-Mỹ: 13:00 - 16:00 GMT
        else if (hour >= 13 && hour < 16) {
            return SESSION_EUROPEAN_AMERICAN;
        }
        // Phiên Mỹ: 16:00 - 21:00 GMT
        else if (hour >= 16 && hour < 21) {
            return SESSION_AMERICAN;
        }
        // Phiên đóng cửa
        else {
            return SESSION_CLOSING;
        }
    }
    
    // Lấy thời gian bar hiện tại
    datetime GetCurrentBarTime(ENUM_TIMEFRAMES timeframe) {
        datetime barTime[1];
        if (CopyTime(m_Symbol, timeframe, 0, 1, barTime) > 0) {
            return barTime[0];
        }
        return 0;
    }
    
    // Phát hiện biến động đột biến
    bool DetectVolatilitySpike(double threshold = 1.5) {
        // Lấy ATR hiện tại và ATR trung bình của 5 nến trước
        double atrCurrent = 0.0;
        double atrPrev = 0.0;
        
        int atrHandle = iATR(m_Symbol, m_Timeframe, 14);
        if (atrHandle != INVALID_HANDLE) {
            double buffer[];
            ArraySetAsSeries(buffer, true);
            if (CopyBuffer(atrHandle, 0, 0, 6, buffer) > 0) {
                atrCurrent = buffer[0];
                
                // Tính ATR trung bình của 5 nến trước
                atrPrev = 0;
                for (int i = 1; i <= 5; i++) {
                    atrPrev += buffer[i];
                }
                atrPrev /= 5;
            }
            IndicatorRelease(atrHandle);
        }
        
        if (atrCurrent > 0 && atrPrev > 0) {
            // Tỷ lệ biến động hiện tại so với trung bình
            double spikeRatio = atrCurrent / atrPrev;
            
            // Nếu tăng vượt ngưỡng, báo hiệu spike
            if (spikeRatio >= threshold) {
                if (m_Logger != NULL) {
                    m_Logger.LogWarning("Phát hiện Volatility Spike: " + DoubleToString(spikeRatio, 2) + "x");
                }
                return true;
            }
        }
        
        return false;
    }
};

//====================================================
// Class: CRiskOptimizer
//====================================================
class CRiskOptimizer {
private:
    CMarketProfile*      m_Profile;          // pointer tới MarketProfile
    CSwingPointDetector* m_SwingDetector;    // pointer tới SwingPointDetector
    CLogger*             m_Logger;           // pointer tới Logger
    CSafeDataProvider*   m_SafeData;         // Safe Data Provider
    
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
    
public:
    // ===== Khởi tạo và cập nhật =====
    CRiskOptimizer();
    ~CRiskOptimizer();
    
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, double riskPercent, double atrMultSL, double atrMultTP);
    bool SetSwingPointDetector(CSwingPointDetector* swingDetector);
    void UpdateMarketProfile(CMarketProfile* profile);
    void SetLogger(CLogger* logger) { m_Logger = logger; }
    CLogger* GetLogger() const { return m_Logger; }
    
    // ===== Thiết lập cấu hình =====
    void SetConfig(const SRiskOptimizerConfig &config) { m_Config = config; }
    SRiskOptimizerConfig GetConfig() const { return m_Config; }
    void SetDrawdownParameters(double threshold, bool enableTapered, double minRiskMultiplier);
    void SetChandelierExit(bool useChande, int lookback, double atrMult);
    void SetAverageATR(double avgATR) { m_AverageATR = avgATR; }
    void SetRiskLimits(bool useFixedUSD, double maxUSD, double maxPercent);
    
    // ===== Tính khối lượng và SL/TP =====
    double CalculateLotSize(string symbol, double stopLossPoints, double entryPrice, 
                           double signalQuality = 1.0, double riskPercentOverride = 0.0);
    double CalculateDynamicLotSize(string symbol, double stopLossPoints, double entryPrice, 
                                  bool applyVolatilityAdjustment, double maxVolFactor, 
                                  double minLotMultiplier, double signalQuality = 1.0);
    
    bool CalculateSLTP(double entryPrice, bool isLong, double& stopLoss, double& takeProfit, 
                      ENUM_CLUSTER_TYPE cluster);
    
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
    
    // ===== Structure-based SL/TP =====
    bool FindSwingPoints(bool isLong, int lookbackBars, double &swingLevel, int &swingBar);
    bool CalculateSLTPByStructure(double entryPrice, bool isLong, double &stopLoss, double &takeProfit);
    bool CalculateHybridSLTP(double entryPrice, bool isLong, double &stopLoss, double &takeProfit, 
                           ENUM_CLUSTER_TYPE cluster);
    
    // ===== Smart Risk Management =====
    double ApplySmartRisk(double baseRiskPercent, int consecutiveLosses, double winRate, 
                        ENUM_CLUSTER_TYPE cluster, ENUM_MARKET_REGIME regime);
    double ApplyCyclicalRisk(double baseRiskPercent);
    
    // ===== Chu kỳ thời gian và cập nhật trạng thái =====
    void UpdateTimeCycles();
    void UpdateTradingResult(bool isWin, double profit);
    void UpdateDailyState();
    void UpdateDailyLoss();
    
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
    void UpdatePerformanceStats(ENUM_SESSION session, ENUM_MARKET_REGIME regime, 
                               ENUM_TRADING_STRATEGY strategy, double volatilityRatio,
                               double atr, double rMultiple, ENUM_TRAILING_PHASE trailingPhase,
                               double riskPercent);
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo với thông số mặc định nâng cao            |
//+------------------------------------------------------------------+
CRiskOptimizer::CRiskOptimizer() : 
    m_Profile(NULL),
    m_SwingDetector(NULL),
    m_Logger(NULL),
    m_SafeData(NULL),
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
    m_LastStrategyUpdateTime(0)
{
    // Khởi tạo config với giá trị mặc định
    m_Config = SRiskOptimizerConfig();
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
    m_DayStartBalance = 0.0;
    m_CurrentDailyLoss = 0.0;
    
    // Cập nhật trạng thái ngày
    UpdateDailyState();
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "RiskOptimizer v13 khởi tạo: Risk=%.2f%%, SL ATR=%.2f, TP RR=%.2f", 
            m_Config.RiskPercent, m_Config.SL_ATR_Multiplier, m_Config.TP_RR_Ratio
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
//| UpdateMarketProfile - Cập nhật liên kết tới Market Profile       |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateMarketProfile(CMarketProfile* profile)
{
    m_Profile = profile;
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
//| Giải phóng các handles tài nguyên                                |
//+------------------------------------------------------------------+
void CRiskOptimizer::ReleaseHandles() {
    // Giải phóng tất cả indicator handles nếu có
    if (m_Logger != NULL) {
        m_Logger.LogDebug("Giải phóng indicator handles trong RiskOptimizer");
    }
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
//| Get valid ATR value with fallback                                |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetValidATR()
{
    // Kiểm tra xem có cần cập nhật cache không
    if (!NeedToUpdateCache() && m_LastATR > 0) {
        return m_LastATR; // Sử dụng cache
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
//| Get volatility adjustment factor with improved handling          |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetVolatilityAdjustmentFactor()
{
    // Kiểm tra cache
    if (!NeedToUpdateCache() && m_LastVolatilityRatio > 0) {
        return m_LastVolatilityRatio;
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
//| Get SL Multiplier for specific cluster type                      |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetSLMultiplierForCluster(ENUM_CLUSTER_TYPE cluster)
{
    double baseMultiplier = m_Config.SL_ATR_Multiplier;
    
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
            // Thị trường sideway - giảm risk 20%
            adjustedRisk = baseRiskPercent * 0.8;
            break;
            
        case REGIME_VOLATILE:
            // Thị trường biến động mạnh - giảm risk 40%
            adjustedRisk = baseRiskPercent * 0.6;
            break;
            
        case REGIME_TRANSITIONING:
            // Thị trường đang chuyển tiếp - giảm risk 30%
            adjustedRisk = baseRiskPercent * 0.7;
            break;
            
        default:
            adjustedRisk = baseRiskPercent;
    }
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        string regimeName = "";
        switch(regime) {
            case REGIME_TRENDING: regimeName = "Trending"; break;
            case REGIME_RANGING: regimeName = "Ranging"; break;
            case REGIME_VOLATILE: regimeName = "Volatile"; break;
            case REGIME_TRANSITIONING: regimeName = "Transitioning"; break;
        }
        
        m_Logger.LogDebug(StringFormat(
            "Điều chỉnh risk theo regime %s: %.2f%% -> %.2f%%",
            regimeName, baseRiskPercent, adjustedRisk
        ));
    }
    
    return adjustedRisk;
}

//+------------------------------------------------------------------+
//| Adjust risk percent based on drawdown level                      |
//+------------------------------------------------------------------+
double CRiskOptimizer::AdjustRiskPercentByDrawdown(double currentDrawdown, double baseRiskPercent)
{
    double adjustedRisk = baseRiskPercent;
    
    // Nếu DD dưới ngưỡng, giữ nguyên risk
    if (currentDrawdown < m_Config.DrawdownReduceThreshold) {
        return baseRiskPercent;
    }
    
    // Xử lý tapered (giảm dần theo bậc thang)
    if (m_Config.EnableTaperedRisk) {
        // Xác định ngưỡng DD tối đa từ config thay vì hardcode
        double maxDD = m_Config.MaxAllowedDrawdown;
        
        // Tính phần trăm giữa ngưỡng và max
        double ddRange = maxDD - m_Config.DrawdownReduceThreshold;
        if (ddRange <= 0) ddRange = 5.0; // Ngăn chia cho 0
        
        double ddInRange = currentDrawdown - m_Config.DrawdownReduceThreshold;
        double reductionPercent = MathMin(1.0, ddInRange / ddRange); // 0.0 - 1.0
        
        // Tính risk giảm dần dựa trên bậc thang
        double minRisk = baseRiskPercent * m_Config.MinRiskMultiplier;
        
        // Tính theo công thức mũ giảm dần (thay vì tuyến tính)
        double powerFactor = 1.5; // > 1.0 = giảm nhanh hơn ở giai đoạn đầu
        adjustedRisk = baseRiskPercent - (baseRiskPercent - minRisk) * MathPow(reductionPercent, powerFactor);
    } 
    else {
        // Giảm đột ngột khi vượt ngưỡng
        adjustedRisk = baseRiskPercent * m_Config.MinRiskMultiplier;
    }
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Điều chỉnh risk theo DD (%.2f%%): %.2f%% -> %.2f%% (tapered=%s, powerFactor=%.1f)",
            currentDrawdown, baseRiskPercent, adjustedRisk, 
            m_Config.EnableTaperedRisk ? "true" : "false",
            m_Config.EnableTaperedRisk ? 1.5 : 0.0
        ));
    }
    
    return MathMax(0.1, adjustedRisk); // Đảm bảo không giảm dưới 0.1%
}

//+------------------------------------------------------------------+
//| Calculate trailing stop based on market regime                   |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateTrailingStop(double currentPrice, double openPrice, double atr, 
                                            bool isLong, ENUM_MARKET_REGIME regime)
{
    // Xác định hệ số trailing dựa trên chế độ thị trường
    double trailingFactor = GetTrailingFactorForRegime(regime);
    
    // Tính khoảng cách trailing
    double trailingDistance = atr * trailingFactor;
    
    // Mặc định sử dụng ATR-based trailing
    double trailingStop = 0.0;
    
    if (isLong) {
        trailingStop = currentPrice - trailingDistance;
        
        // Đảm bảo trailing stop không thấp hơn giá mở lệnh (nếu đang lời)
        if (currentPrice > openPrice && trailingStop < openPrice) {
            trailingStop = openPrice; // Breakeven
        }
    } else {
        trailingStop = currentPrice + trailingDistance;
        
        // Đảm bảo trailing stop không cao hơn giá mở lệnh (nếu đang lời)
        if (currentPrice < openPrice && trailingStop > openPrice) {
            trailingStop = openPrice; // Breakeven
        }
    }
    
    // Nếu sử dụng Chandelier Exit và có SwingPointDetector
    if (m_Config.UseChandelierExit && m_SwingDetector != NULL) {
        double chandelierExit = CalculateChandelierExit(isLong, openPrice, currentPrice);
        
        // Sử dụng giá trị tốt nhất giữa chandelier và trailing thông thường
        if (isLong) {
            trailingStop = MathMax(trailingStop, chandelierExit); // Giá trị cao hơn -> bảo vệ tốt hơn
        } else {
            trailingStop = MathMin(trailingStop, chandelierExit); // Giá trị thấp hơn -> bảo vệ tốt hơn
        }
    }
    
    return NormalizeDouble(trailingStop, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Calculate Chandelier Exit (for v13)                              |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateChandelierExit(bool isLong, double openPrice, double currentPrice)
{
    if (!m_Config.UseChandelierExit) return 0;
    
    // Lấy ATR
    double atr = GetValidATR();
    if (atr <= 0) return 0;
    
    double trailingStop = 0;
    
    if (isLong) {
        // Lấy giá thấp nhất trong n nến
        double lowestLow = DBL_MAX;
        for (int i = 1; i <= m_Config.ChandelierLookback; i++) {
            double low = iLow(m_Symbol, m_MainTimeframe, i);
            if (low < lowestLow) lowestLow = low;
        }
        
        // Chandelier exit = Lowest Low trong n nến - ATR * multiplier
        trailingStop = lowestLow - (atr * m_Config.ChandelierATRMultiplier);
        
        // Đảm bảo trailing stop không thấp hơn giá mở lệnh nếu đang lời
        if (currentPrice > openPrice && trailingStop < openPrice) {
            trailingStop = openPrice;
        }
    } else {
        // Lấy giá cao nhất trong n nến
        double highestHigh = 0;
        for (int i = 1; i <= m_Config.ChandelierLookback; i++) {
            double high = iHigh(m_Symbol, m_MainTimeframe, i);
            if (high > highestHigh) highestHigh = high;
        }
        
        // Chandelier exit = Highest High trong n nến + ATR * multiplier
        trailingStop = highestHigh + (atr * m_Config.ChandelierATRMultiplier);
        
        // Đảm bảo trailing stop không cao hơn giá mở lệnh nếu đang lời
        if (currentPrice < openPrice && trailingStop > openPrice) {
            trailingStop = openPrice;
        }
    }
    
    return NormalizeDouble(trailingStop, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Get trailing factor based on market regime                       |
//+------------------------------------------------------------------+
double CRiskOptimizer::GetTrailingFactorForRegime(ENUM_MARKET_REGIME regime)
{
    switch(regime) {
        case REGIME_TRENDING:
            return m_Config.TrailingFactorTrend; // Trailing rộng hơn trong xu hướng
            
        case REGIME_RANGING:
            return m_Config.TrailingFactorRanging; // Trailing chặt hơn trong sideway
            
        case REGIME_VOLATILE:
            return m_Config.TrailingFactorVolatile; // Trailing rất rộng trong biến động cao
            
        case REGIME_TRANSITIONING:
            return 1.0; // Mặc định trong chuyển tiếp
            
        default:
            return 1.0;
    }
}

//+------------------------------------------------------------------+
//| Find Swing Points for structure-based SL/TP                      |
//+------------------------------------------------------------------+
bool CRiskOptimizer::FindSwingPoints(bool isLong, int lookbackBars, double &swingLevel, int &swingBar)
{
    if (m_SwingDetector == NULL) {
        if (m_Logger != NULL) m_Logger.LogWarning("SwingPointDetector chưa được khởi tạo trong FindSwingPoints");
        return false;
    }
    
    return m_SwingDetector.FindRecentSwing(isLong, lookbackBars, swingLevel, swingBar);
}

//+------------------------------------------------------------------+
//| Calculate SL/TP based on market structure (swing points)         |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CalculateSLTPByStructure(double entryPrice, bool isLong, double &stopLoss, double &takeProfit)
{
    if (m_SwingDetector == NULL) return false;
    
    // Lấy ATR để sử dụng cho buffer
    double atr = GetValidATR();
    if (atr <= 0) return false;
    
    // Tìm swing point gần nhất cho SL
    double swingLevel = 0;
    int swingBar = 0;
    bool foundSwing = false;
    
    // Tìm swing high/low cho stop loss
    foundSwing = FindSwingPoints(!isLong, 20, swingLevel, swingBar);
    
    if (!foundSwing) {
        // Nếu không tìm thấy swing point, sử dụng SL dựa trên ATR
        if (isLong) {
            stopLoss = entryPrice - (atr * m_Config.SL_ATR_Multiplier);
        } else {
            stopLoss = entryPrice + (atr * m_Config.SL_ATR_Multiplier);
        }
    } else {
        // Sử dụng swing point + buffer ATR cho SL
        double buffer = atr * 0.3; // Buffer nhỏ 30% ATR
        
        if (isLong) {
            stopLoss = swingLevel - buffer;
        } else {
            stopLoss = swingLevel + buffer;
        }
    }
    
    // Tính TP dựa trên R:R từ SL
    double riskDistance = MathAbs(entryPrice - stopLoss);
    
    if (isLong) {
        takeProfit = entryPrice + (riskDistance * m_Config.TP_RR_Ratio);
    } else {
        takeProfit = entryPrice - (riskDistance * m_Config.TP_RR_Ratio);
    }
    
    // Chuẩn hóa giá trị
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    return true;
}

//+------------------------------------------------------------------+
//| Calculate hybrid SL/TP (combines ATR and structure)              |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CalculateHybridSLTP(double entryPrice, bool isLong, double &stopLoss, double &takeProfit, 
                                        ENUM_CLUSTER_TYPE cluster)
{
    // Tính SL/TP dựa trên ATR
    double atrSL = 0, atrTP = 0;
    if (!CalculateSLTP(entryPrice, isLong, atrSL, atrTP, cluster)) {
        return false;
    }
    
    // Tính SL/TP dựa trên cấu trúc thị trường
    double structSL = 0, structTP = 0;
    bool hasStructure = CalculateSLTPByStructure(entryPrice, isLong, structSL, structTP);
    
    // Nếu không có cấu trúc thị trường, sử dụng ATR
    if (!hasStructure) {
        stopLoss = atrSL;
        takeProfit = atrTP;
        return true;
    }
    
    // Hybrid approach - chọn SL tốt nhất (bảo vệ tốt nhất)
    if (isLong) {
        // Với lệnh long, SL cao hơn là tốt hơn (gần giá hơn)
        stopLoss = MathMax(atrSL, structSL);
    } else {
        // Với lệnh short, SL thấp hơn là tốt hơn (gần giá hơn)
        stopLoss = MathMin(atrSL, structSL);
    }
    
    // Tính lại TP dựa trên R:R từ SL đã chọn
    double riskDistance = MathAbs(entryPrice - stopLoss);
    double rewardMultiplier = GetTPMultiplierForCluster(cluster);
    
    if (isLong) {
        takeProfit = entryPrice + (riskDistance * rewardMultiplier);
    } else {
        takeProfit = entryPrice - (riskDistance * rewardMultiplier);
    }
    
    // Chuẩn hóa giá trị
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    stopLoss = NormalizeDouble(stopLoss, digits);
    takeProfit = NormalizeDouble(takeProfit, digits);
    
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "HybridSLTP - ATR(SL: %.5f, TP: %.5f), Struct(SL: %.5f, TP: %.5f), Final(SL: %.5f, TP: %.5f)",
            atrSL, atrTP, structSL, structTP, stopLoss, takeProfit
        ));
    }
    
    // Xác định chế độ thị trường
    ENUM_MARKET_REGIME regime = REGIME_TRENDING; // Mặc định
    double regimeConfidence = 0.8; // Mặc định cao
    
    if (m_Profile != NULL) {
        regime = m_Profile.GetMarketRegime();
        regimeConfidence = m_Profile.GetRegimeConfidence();
    }
    
    // Lấy tỷ lệ biến động
    double volatilityRatio = GetVolatilityRatio();
    
    // Xác định chiến lược tối ưu dựa trên chế độ thị trường
    ENUM_TRADING_STRATEGY strategy = DetermineOptimalStrategy(regime, volatilityRatio, regimeConfidence);
    
    // Điều chỉnh SL/TP theo chiến lược
    AdjustSLTPByStrategy(stopLoss, takeProfit, isLong, strategy);
    
    return true;
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
//| Apply smart risk based on various factors                        |
//+------------------------------------------------------------------+
double CRiskOptimizer::ApplySmartRisk(double baseRiskPercent, int consecutiveLosses, double winRate, 
                                     ENUM_CLUSTER_TYPE cluster, ENUM_MARKET_REGIME regime)
{
    double adjustedRisk = baseRiskPercent;
    
    // 1. Điều chỉnh dựa trên chuỗi thua liên tiếp
    if (consecutiveLosses > 0) {
        // Giảm risk sau mỗi lần thua
        double lossAdjustFactor = MathMax(0.5, 1.0 - (0.1 * consecutiveLosses)); // Giảm 10% risk sau mỗi lần thua, tối đa 50%
        adjustedRisk *= lossAdjustFactor;
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug(StringFormat(
                "Điều chỉnh risk sau %d lần thua liên tiếp: %.2f%% -> %.2f%%",
                consecutiveLosses, baseRiskPercent, adjustedRisk
            ));
        }
    }
    
    // 2. Điều chỉnh dựa trên cluster
    double clusterFactor = 1.0;
    switch(cluster) {
        case CLUSTER_1_TREND_FOLLOWING:
            clusterFactor = 1.0; // Giữ nguyên cho trend following
            break;
            
        case CLUSTER_2_COUNTERTREND:
            clusterFactor = 0.8; // Giảm 20% cho counter trend
            break;
            
        case CLUSTER_3_SCALING:
            clusterFactor = 0.9; // Giảm 10% cho scaling
            break;
            
        default:
            clusterFactor = 1.0;
    }
    
    adjustedRisk *= clusterFactor;
    
    // 3. Điều chỉnh dựa trên chế độ thị trường
    adjustedRisk = AdjustRiskPercentByMarketRegime(regime, adjustedRisk);
    
    // 4. Điều chỉnh dựa trên win rate
    if (winRate > 0) {
        // Tăng risk nếu win rate cao, giảm nếu win rate thấp
        if (winRate >= 65.0) { 
            adjustedRisk *= 1.1; // Tăng 10% nếu win rate ≥ 65%
        } else if (winRate <= 45.0) {
            adjustedRisk *= 0.8; // Giảm 20% nếu win rate ≤ 45%
        }
    }
    
    // 5. Điều chỉnh theo phiên giao dịch nếu có market profile
    ENUM_SESSION currentSession = SESSION_UNKNOWN;
    if (m_SafeData != NULL) {
        currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
    } else if (m_Profile != NULL) {
        currentSession = m_Profile.GetCurrentSession();
    }
    
    if (currentSession != SESSION_UNKNOWN) {
        double sessionAdjustment = CalculateSessionRiskAdjustment(currentSession);
        adjustedRisk *= sessionAdjustment;
    }
    
    // Thêm: Điều chỉnh theo thời điểm tối ưu trong phiên
    if (IsOptimalTradingTime()) {
        adjustedRisk *= 1.1;  // Tăng 10% risk nếu là thời điểm tốt
        
        if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
            m_Logger.LogDebug("Thời điểm giao dịch tối ưu: tăng risk thêm 10%");
        }
    }
    
    // Áp dụng chu kỳ tuần/tháng nếu được kích hoạt
    adjustedRisk = ApplyCyclicalRisk(adjustedRisk);
    
    // Đảm bảo risk không quá thấp hoặc cao
    adjustedRisk = MathMax(0.2, MathMin(adjustedRisk, baseRiskPercent * 1.2));
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "SmartRisk: Từ %.2f%% thành %.2f%% (Losses=%d, Cluster=%d, Regime=%d, WinRate=%.1f%%)",
            baseRiskPercent, adjustedRisk, consecutiveLosses, cluster, regime, winRate
        ));
    }
    
    return adjustedRisk;
}

//+------------------------------------------------------------------+
//| Calculate R-multiple based on current price                      |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateRMultiple(double entryPrice, double currentPrice, double stopLoss, bool isLong)
{
    // Kiểm tra dữ liệu đầu vào
    if (MathAbs(entryPrice - stopLoss) < _Point) return 0;
    
    // Tính khoảng cách risk
    double riskDistance = MathAbs(entryPrice - stopLoss);
    
    // Tính khoảng cách reward hiện tại
    double currentReward = 0;
    if (isLong) {
        currentReward = currentPrice - entryPrice;
    } else {
        currentReward = entryPrice - currentPrice;
    }
    
    // Tính R-multiple
    double rMultiple = currentReward / riskDistance;
    
    return rMultiple;
}

//+------------------------------------------------------------------+
//| Calculate Dynamic SL based on market conditions                  |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateDynamicSL(bool isLong, double atr, double entryPrice, ENUM_MARKET_REGIME regime)
{
    if (atr <= 0) return 0;
    
    // Điều chỉnh hệ số SL dựa trên regime
    double slMultiplier = m_Config.SL_ATR_Multiplier;
    
    switch(regime) {
        case REGIME_TRENDING:
            // Xu hướng mạnh có thể mở rộng SL
            slMultiplier *= 1.2;
            break;
            
        case REGIME_RANGING:
            // Sideway nên thu hẹp SL
            slMultiplier *= 0.8;
            break;
            
        case REGIME_VOLATILE:
            // Biến động cao, mở rộng SL để tránh stopout sớm
            slMultiplier *= 1.5;
            break;
            
        case REGIME_TRANSITIONING:
            // Chuyển tiếp, SL trung bình
            slMultiplier *= 1.0;
            break;
    }
    
    // Tính SL
    double stopLoss = 0;
    if (isLong) {
        stopLoss = entryPrice - (atr * slMultiplier);
    } else {
        stopLoss = entryPrice + (atr * slMultiplier);
    }
    
    return NormalizeDouble(stopLoss, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Calculate Dynamic TP based on market conditions                  |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateDynamicTP(bool isLong, double atr, double entryPrice, ENUM_MARKET_REGIME regime)
{
    if (atr <= 0) return 0;
    
    // Base TP múltiplier
    double tpMultiplier = m_Config.TP_RR_Ratio;
    
    // Điều chỉnh dựa trên regime
    switch(regime) {
        case REGIME_TRENDING:
            // Trong trend mạnh, TP xa hơn để nắm bắt xu hướng tốt
            tpMultiplier *= 1.5;
            break;
            
        case REGIME_RANGING:
            // Trong sideway, TP gần hơn để đảm bảo hit target
            tpMultiplier *= 0.7;
            break;
            
        case REGIME_VOLATILE:
            // Biến động cao, TP xa hơn để bù cho SL cũng xa
            tpMultiplier *= 1.2;
            break;
            
        case REGIME_TRANSITIONING:
            // Chuyển tiếp, TP trung bình
            tpMultiplier *= 1.0;
            break;
    }
    
    // Tính TP
    double takeProfit = 0;
    if (isLong) {
        takeProfit = entryPrice + (atr * m_Config.SL_ATR_Multiplier * tpMultiplier);
    } else {
        takeProfit = entryPrice - (atr * m_Config.SL_ATR_Multiplier * tpMultiplier);
    }
    
    return NormalizeDouble(takeProfit, (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS));
}

//+------------------------------------------------------------------+
//| Calculate session-based risk adjustment                          |
//+------------------------------------------------------------------+
double CRiskOptimizer::CalculateSessionRiskAdjustment(ENUM_SESSION session)
{
    // Lấy giờ hiện tại để phân tích chi tiết hơn
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int currentHour = dt.hour;
    int currentMinute = dt.min;
    
    // Phát hiện thời điểm đặc biệt trong phiên
    bool isSessionOpen = (currentMinute < 20);    // 20 phút đầu phiên
    bool isSessionClose = (currentMinute > 45);   // 15 phút cuối phiên
    
    switch(session) {
        case SESSION_ASIAN:
            if (isSessionOpen) return 0.7;  // Đầu phiên Á - giảm risk nhiều hơn (30%)
            if (isSessionClose) return 0.7; // Cuối phiên Á - cũng giảm
            return 0.8;                     // Giữa phiên Á - giảm 20% risk
            
        case SESSION_EUROPEAN:
            if (isSessionOpen && currentHour == 8) return 1.1;  // Mở phiên London - tăng 10% risk
            if (isSessionClose && currentHour == 15) return 0.9; // Gần hết phiên Âu - giảm 10%
            return 1.0;                                         // Trong phiên Âu - risk bình thường
            
        case SESSION_AMERICAN:
            if (isSessionOpen && currentHour == 13) return 1.1; // Mở phiên NY - tăng 10%
            if (currentHour >= 19) return 0.8;                 // Cuối phiên Mỹ - giảm 20%
            return 1.0;                                        // Trong phiên Mỹ - risk bình thường
            
        case SESSION_EUROPEAN_AMERICAN:
            // Phiên chồng chéo Âu-Mỹ là thời điểm biến động mạnh nhất
            if (currentHour >= 13 && currentHour < 15) return 1.2; // Tăng 20% risk - thời điểm vàng
            return 1.1;                                           // Tăng 10% risk trong các khung giờ khác
            
        case SESSION_CLOSING:
            return 0.7;  // Giảm 30% risk trong phiên đóng cửa (không an toàn)
            
        default:
            return 1.0;
    }
}

//+------------------------------------------------------------------+
//| Phát hiện thời điểm quan trọng trong phiên                       |
//+------------------------------------------------------------------+
bool CRiskOptimizer::IsOptimalTradingTime()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int hour = dt.hour;
    int minute = dt.min;
    
    // Lấy phiên hiện tại
    ENUM_SESSION currentSession = SESSION_UNKNOWN;
    if (m_SafeData != NULL) {
        currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
    } else if (m_Profile != NULL) {
        currentSession = m_Profile.GetCurrentSession();
    }
    
    // Xác định "sweet spots" - các khung giờ thích hợp
    switch(currentSession) {
        case SESSION_ASIAN:
            // Trong phiên Á, thời điểm tốt là giữa phiên khi Sydney/Tokyo đã ổn định
            if (hour >= 3 && hour <= 6) return true;  // 03:00-06:00 GMT
            break;
            
        case SESSION_EUROPEAN:
            // Trong phiên Âu, thời điểm tốt là sau khi London mở 1h và trước NY mở
            if ((hour >= 9 && hour < 12) && minute >= 15) return true;  // 09:15-12:00 GMT
            break;
            
        case SESSION_AMERICAN:
            // Trong phiên Mỹ, thời điểm tốt là sau khi NY mở 30m
            if (hour == 13 && minute >= 30) return true;  // 13:30-14:00 GMT
            if (hour == 14 && minute <= 30) return true;  // 14:00-14:30 GMT
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            // Thời điểm vàng là phiên overlap Âu-Mỹ, đặc biệt sau khi có data Mỹ
            if (hour == 14 && minute >= 15) return true;  // 14:15-15:00 GMT 
            if (hour == 15 && minute <= 30) return true;  // 15:00-15:30 GMT
            break;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Determine optimal trading strategy based on market conditions     |
//+------------------------------------------------------------------+
ENUM_TRADING_STRATEGY CRiskOptimizer::DetermineOptimalStrategy(ENUM_MARKET_REGIME regime, 
                                                              double volatilityRatio,
                                                              double regimeConfidence)
{
    // Kiểm tra nếu chiến lược hiện tại còn cache hợp lệ
    if (m_LastStrategyUpdateTime > 0 && TimeCurrent() - m_LastStrategyUpdateTime < 300) {
        return m_CurrentStrategy; // Sử dụng cache chiến lược trong 5 phút
    }
    
    // Độ tin cậy cao -> sử dụng chiến lược rõ ràng
    // Độ tin cậy thấp -> bảo thủ hơn
    bool isHighConfidence = (regimeConfidence >= 0.7);
    
    // Xác định chiến lược dựa trên regime
    ENUM_TRADING_STRATEGY strategy = STRATEGY_PULLBACK; // Mặc định
    
    switch(regime) {
        case REGIME_TRENDING:
            if (volatilityRatio > 1.5 && isHighConfidence) {
                strategy = STRATEGY_BREAKOUT;         // Xu hướng + biến động cao = Breakout
            } else {
                strategy = STRATEGY_PULLBACK;         // Xu hướng bình thường = Pullback
            }
            break;
            
        case REGIME_RANGING:
            if (volatilityRatio < 0.8) {
                strategy = STRATEGY_VOLATILITY_BREAKOUT; // Sideway + biến động thấp = chờ bùng nổ
            } else {
                strategy = STRATEGY_MEAN_REVERSION;      // Sideway bình thường = Mean reversion
            }
            break;
            
        case REGIME_VOLATILE:
            strategy = STRATEGY_PRESERVATION;         // Biến động cao không xác định = bảo toàn
            break;
            
        case REGIME_TRANSITIONING:
            if (isHighConfidence) {
                strategy = STRATEGY_MEAN_REVERSION;   // Chuyển tiếp tin cậy = Mean reversion
            } else {
                strategy = STRATEGY_PRESERVATION;     // Chuyển tiếp không rõ = bảo toàn
            }
            break;
            
        default:
            strategy = STRATEGY_PULLBACK;             // Mặc định là pullback
            break;
    }
    
    // Cập nhật cache
    m_CurrentStrategy = strategy;
    m_LastStrategyUpdateTime = TimeCurrent();
    
    if (m_Logger != NULL) {
        string regimeNames[] = {"Trending", "Ranging", "Volatile", "Transitioning"};
        string strategyNames[] = {"Breakout", "Pullback", "Mean Reversion", "Volatility Breakout", "Preservation"};
        
        m_Logger.LogInfo(StringFormat(
            "Xác định chiến lược tối ưu: %s cho chế độ %s (Confidence=%.2f, Volatility=%.2fx)",
            strategyNames[strategy], regimeNames[regime], regimeConfidence, volatilityRatio
        ));
    }
    
    return strategy;
}

//+------------------------------------------------------------------+
//| Calculate SmartTrailing based on R-multiple                      |
//+------------------------------------------------------------------+
TrailingAction CRiskOptimizer::CalculateSmartTrailing(double entryPrice, double currentPrice, 
                                                    double stopLoss, bool isLong, 
                                                    ENUM_MARKET_REGIME regime)
{
    TrailingAction action;
    action.ShouldTrail = false;
    action.NewStopLoss = stopLoss;
    action.LockPercentage = 0.0;
    action.RMultiple = 0.0;
    action.Phase = TRAILING_NONE;
    
    // Nếu không kích hoạt smart trailing, trả về không xử lý
    if (!m_Config.Trailing.EnableSmartTrailing) return action;
    
    // Tính R-multiple hiện tại
    double riskDistance = MathAbs(entryPrice - stopLoss);
    if (riskDistance <= 0) return action;
    
    double rewardDistance = 0.0;
    if (isLong) {
        rewardDistance = currentPrice - entryPrice;
    } else {
        rewardDistance = entryPrice - currentPrice;
    }
    
    // Tính R-multiple
    double rMultiple = rewardDistance / riskDistance;
    action.RMultiple = rMultiple;
    
    // Nếu chưa đạt BE, kiểm tra
    if (rMultiple >= m_Config.Trailing.BreakEvenRMultiple) {
        // Đạt BE
        double newSL = entryPrice;
        action.ShouldTrail = true;
        action.NewStopLoss = newSL;
        action.Phase = TRAILING_BREAKEVEN;
        
        // Kiểm tra các mức khóa tiếp theo
        if (rMultiple >= m_Config.Trailing.FirstLockRMultiple) {
            // Khóa lần đầu
            double lockPct = m_Config.Trailing.LockPercentageFirst / 100.0;
            action.LockPercentage = lockPct * 100.0;
            action.Phase = TRAILING_FIRST_LOCK;
            
            // Tính toán vị trí SL mới để khóa % lợi nhuận
            if (isLong) {
                newSL = entryPrice + (rewardDistance * lockPct);
            } else {
                newSL = entryPrice - (rewardDistance * lockPct);
            }
            
            action.NewStopLoss = newSL;
            
            // Kiểm tra các mức khóa cao hơn
            if (rMultiple >= m_Config.Trailing.SecondLockRMultiple) {
                // Khóa lần hai
                lockPct = m_Config.Trailing.LockPercentageSecond / 100.0;
                action.LockPercentage = lockPct * 100.0;
                action.Phase = TRAILING_SECOND_LOCK;
                
                if (isLong) {
                    newSL = entryPrice + (rewardDistance * lockPct);
                } else {
                    newSL = entryPrice - (rewardDistance * lockPct);
                }
                
                action.NewStopLoss = newSL;
                
                // Kiểm tra khóa lần ba
                if (rMultiple >= m_Config.Trailing.ThirdLockRMultiple) {
                    // Khóa lần ba
                    lockPct = m_Config.Trailing.LockPercentageThird / 100.0;
                    action.LockPercentage = lockPct * 100.0;
                    action.Phase = TRAILING_THIRD_LOCK;
                    
                    if (isLong) {
                        newSL = entryPrice + (rewardDistance * lockPct);
                    } else {
                        newSL = entryPrice - (rewardDistance * lockPct);
                    }
                    
                    action.NewStopLoss = newSL;
                    
                    // Khi đạt R-multiple cực cao, chuyển sang trailing đầy đủ
                    if (rMultiple >= m_Config.Trailing.ThirdLockRMultiple * 1.5) {
                        action.Phase = TRAILING_FULL_TRAILING;
                        // Sử dụng Chandelier Exit cho trailing đầy đủ
                        if (m_Config.UseChandelierExit) {
                            double chandelierExit = CalculateChandelierExit(isLong, entryPrice, currentPrice);
                            
                            // Lấy SL tốt nhất giữa % lock và chandelier
                            if (isLong) {
                                action.NewStopLoss = MathMax(newSL, chandelierExit);
                            } else {
                                action.NewStopLoss = MathMin(newSL, chandelierExit);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Chuẩn hóa giá trị SL
    int digits = (int)SymbolInfoInteger(m_Symbol, SYMBOL_DIGITS);
    action.NewStopLoss = NormalizeDouble(action.NewStopLoss, digits);
    
    // Điều chỉnh SL thêm dựa trên chế độ thị trường
    if (action.ShouldTrail) {
        // Trong xu hướng mạnh, trailing rộng hơn một chút
        if (regime == REGIME_TRENDING) {
            double atr = GetValidATR();
            if (atr > 0) {
                double adjustment = atr * 0.1; // 10% ATR
                
                if (isLong) {
                    action.NewStopLoss = NormalizeDouble(action.NewStopLoss - adjustment, digits);
                } else {
                    action.NewStopLoss = NormalizeDouble(action.NewStopLoss + adjustment, digits);
                }
            }
        }
    }
    
    if (m_Logger != NULL && action.ShouldTrail) {
        string phaseNames[] = {"None", "Breakeven", "First Lock", "Second Lock", "Third Lock", "Full Trailing"};
        
        m_Logger.LogInfo(StringFormat(
            "SmartTrailing: R=%.2f, Giai đoạn=%s, Khóa %.1f%%, SL mới=%.5f",
            action.RMultiple, phaseNames[action.Phase], action.LockPercentage, action.NewStopLoss
        ));
    }
    
    return action;
}

//+------------------------------------------------------------------+
//| Update TimeCycles - Cập nhật chu kỳ thời gian                    |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateTimeCycles()
{
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    
    // Kiểm tra chuyển tuần mới
    datetime currentMonday = TimeCurrent() - (dt.day_of_week - 1) * 86400;
    if (m_LastWeekMonday == 0 || currentMonday > m_LastWeekMonday) {
        if (m_LastWeekMonday > 0) {
            // Lưu kết quả tuần trước và reset
            if (m_Logger != NULL) {
                m_Logger.LogInfo(StringFormat(
                    "Kết thúc tuần: P/L=%.2f, Reset chu kỳ tuần", m_WeeklyProfit
                ));
            }
        }
        
        m_LastWeekMonday = currentMonday;
        m_WeeklyProfit = 0.0; // Reset profit tuần mới
    }
    
    // Kiểm tra chuyển tháng mới
    if (dt.mon != m_CurrentMonth) {
        if (m_CurrentMonth > 0) {
            // Lưu kết quả tháng trước và reset
            if (m_Logger != NULL) {
                m_Logger.LogInfo(StringFormat(
                    "Kết thúc tháng: P/L=%.2f, Reset chu kỳ tháng", m_MonthlyProfit
                ));
            }
        }
        
        m_CurrentMonth = dt.mon;
        m_MonthlyProfit = 0.0; // Reset profit tháng mới
    }
    
    // Kiểm tra ngày mới
    static int lastDay = 0;
    if (lastDay != dt.day) {
        lastDay = dt.day;
        
        // Reset số ngày lời liên tiếp nếu ngày thay đổi
        if (AccountInfoDouble(ACCOUNT_BALANCE) > m_DayStartBalance) {
            // Lợi nhuận trong ngày
            m_ConsecutiveProfitDays++;
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Ngày lời thứ %d liên tiếp (%.2f)", 
                    m_ConsecutiveProfitDays, AccountInfoDouble(ACCOUNT_BALANCE) - m_DayStartBalance
                ));
            }
        } else {
            // Lỗ trong ngày, reset
            m_ConsecutiveProfitDays = 0;
        }
        
        // Cập nhật số dư đầu ngày mới
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    }
}

//+------------------------------------------------------------------+
//| UpdateTradingResult - Cập nhật kết quả giao dịch                 |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateTradingResult(bool isWin, double profit)
{
    // Cập nhật profit/loss cho chu kỳ tuần/tháng
    if (isWin) {
        m_WeeklyProfit += profit;
        m_MonthlyProfit += profit;
    } else {
        m_WeeklyProfit -= MathAbs(profit);
        m_MonthlyProfit -= MathAbs(profit);
    }
    
    // Cập nhật lợi nhuận ngày
    m_CurrentDailyLoss = 0.0; // Reset và sẽ được tính lại trong UpdateDailyLoss()
    
    // Phân tích thời gian giao dịch
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Cập nhật session nếu cần
    ENUM_SESSION currentSession = SESSION_UNKNOWN;
    if (m_SafeData != NULL) {
        currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
        m_LastSession = currentSession;
    }
    
    if (m_Logger != NULL) {
        string resultStr = isWin ? "Thắng" : "Thua";
        string profitStr = StringFormat("%.2f", isWin ? profit : -MathAbs(profit));
        
        m_Logger.LogInfo(StringFormat(
            "Cập nhật kết quả: %s, P/L=%s, Tuần=%.2f, Tháng=%.2f", 
            resultStr, profitStr, m_WeeklyProfit, m_MonthlyProfit
        ));
    }
    
    // Cập nhật chu kỳ thời gian
    UpdateTimeCycles();
}

//+------------------------------------------------------------------+
//| UpdateDailyState - Cập nhật trạng thái theo ngày                 |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateDailyState()
{
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    // Kiểm tra nếu ngày đã thay đổi
    if (m_LastTradeDay != dt.day) {
        // Ngày mới, reset các giá trị ngày
        if (m_LastTradeDay > 0) {
            // Log thông tin ngày cũ kết thúc
            if (m_Logger != NULL) {
                m_Logger.LogInfo(StringFormat(
                    "Kết thúc ngày giao dịch %d. Reset Daily State.", m_LastTradeDay
                ));
            }
        }
        
        // Cập nhật ngày giao dịch mới
        m_LastTradeDay = dt.day;
        
        // Lưu balance đầu ngày
        m_DayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        // Reset lỗ trong ngày
        m_CurrentDailyLoss = 0.0;
        
        // Kiểm tra nếu ngày mới là thứ 2, cập nhật ATR trung bình nếu cần
        if (dt.day_of_week == 1) {
            // Cập nhật ATR trung bình mới cho tuần
            // Hàm này thực tế sẽ nằm ở EA chính, nhưng chúng ta vẫn thông báo
            if (m_Logger != NULL) {
                m_Logger.LogInfo("Ngày thứ Hai: Đề xuất cập nhật ATR trung bình tuần mới");
            }
        }
        
        // Kiểm tra nếu EA đang pause và AutoResume vào ngày mới
        if (m_IsPaused && m_Config.AutoPause.ResumeOnNewDay) {
            m_IsPaused = false;
            m_PauseUntil = 0;
            
            if (m_Logger != NULL) {
                m_Logger.LogInfo("Auto Resume EA vào ngày giao dịch mới");
            }
        }
    }
}

//+------------------------------------------------------------------+
//| UpdateDailyLoss - Cập nhật lỗ trong ngày                         |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdateDailyLoss()
{
    // Tính lỗ hiện tại trong ngày dựa trên equity
    double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (currentEquity < m_DayStartBalance) {
        // Đang lỗ trong ngày
        m_CurrentDailyLoss = (m_DayStartBalance - currentEquity) / m_DayStartBalance * 100.0;
    } else {
        // Đang lời hoặc hòa trong ngày
        m_CurrentDailyLoss = 0.0;
    }
    
    // Thực hiện AutoPause nếu lỗ vượt ngưỡng
    if (m_Config.AutoPause.EnableAutoPause && 
        m_CurrentDailyLoss >= m_Config.AutoPause.DailyLossPercentLimit) {
        
        // Tạo trạng thái pause
        PauseState pauseState;
        pauseState.ShouldPause = true;
        pauseState.Reason = PAUSE_DAILY_LOSS_LIMIT;
        pauseState.PauseMinutes = m_Config.AutoPause.PauseMinutes;
        pauseState.Message = StringFormat(
            "Auto Pause EA do lỗ trong ngày đạt %.2f%% (vượt ngưỡng %.2f%%)",
            m_CurrentDailyLoss, m_Config.AutoPause.DailyLossPercentLimit
        );
        
        // Apply pause state
        SetPauseState(pauseState);
    }
}

//+------------------------------------------------------------------+
//| CheckPauseCondition - Kiểm tra điều kiện dừng EA                 |
//+------------------------------------------------------------------+
PauseState CRiskOptimizer::CheckPauseCondition(int consecutiveLosses, double dailyLoss)
{
    // Khởi tạo PauseState với giá trị mặc định
    PauseState pauseState;
    pauseState.ShouldPause = false;
    pauseState.Reason = PAUSE_NONE;
    pauseState.PauseMinutes = m_Config.AutoPause.PauseMinutes;
    pauseState.Message = "";
    
    // Kiểm tra nếu không bật AutoPause
    if (!m_Config.AutoPause.EnableAutoPause)
        return pauseState;
    
    // Kiểm tra lỗ liên tiếp
    if (consecutiveLosses >= m_Config.AutoPause.ConsecutiveLossesLimit) {
        pauseState.ShouldPause = true;
        pauseState.Reason = PAUSE_CONSECUTIVE_LOSSES;
        pauseState.Message = StringFormat(
            "Auto Pause: %d lỗ liên tiếp (vượt ngưỡng %d)",
            consecutiveLosses, m_Config.AutoPause.ConsecutiveLossesLimit
        );
        
        return pauseState;
    }
    
    // Kiểm tra lỗ trong ngày
    if (dailyLoss >= m_Config.AutoPause.DailyLossPercentLimit) {
        pauseState.ShouldPause = true;
        pauseState.Reason = PAUSE_DAILY_LOSS_LIMIT;
        pauseState.Message = StringFormat(
            "Auto Pause: Lỗ trong ngày %.2f%% (vượt ngưỡng %.2f%%)",
            dailyLoss, m_Config.AutoPause.DailyLossPercentLimit
        );
        
        return pauseState;
    }
    
    // Kiểm tra biến động bất thường
    if (m_SafeData != NULL && m_Config.AutoPause.SkipTradeOnExtremeVolatility) {
        // Phát hiện biến động đột biến
        bool hasVolatilitySpike = m_SafeData.DetectVolatilitySpike(m_Config.AutoPause.VolatilitySpikeFactor);
        
        if (hasVolatilitySpike) {
            pauseState.ShouldPause = true;
            pauseState.Reason = PAUSE_VOLATILITY_SPIKE;
            pauseState.PauseMinutes = 30; // Thường pause ngắn hơn cho biến động đột biến
            pauseState.Message = StringFormat(
                "Auto Pause: Phát hiện biến động đột biến (>%.1fx)",
                m_Config.AutoPause.VolatilitySpikeFactor
            );
            
            return pauseState;
        }
    }
    
    return pauseState;
}

//+------------------------------------------------------------------+
//| SetPauseState - Thiết lập trạng thái pause                       |
//+------------------------------------------------------------------+
void CRiskOptimizer::SetPauseState(PauseState &state)
{
    if (!state.ShouldPause) return;
    
    // Thiết lập trạng thái pause
    m_IsPaused = true;
    m_PauseUntil = TimeCurrent() + state.PauseMinutes * 60;
    
    // Log thông báo về việc pause
    if (m_Logger != NULL) {
        string reasonStr = "";
        switch (state.Reason) {
            case PAUSE_CONSECUTIVE_LOSSES: reasonStr = "Lỗ liên tiếp"; break;
            case PAUSE_DAILY_LOSS_LIMIT: reasonStr = "Lỗ trong ngày"; break;
            case PAUSE_VOLATILITY_SPIKE: reasonStr = "Biến động bất thường"; break;
            case PAUSE_MANUAL: reasonStr = "Thủ công"; break;
            default: reasonStr = "Unknown";
        }
        
        m_Logger.LogInfo(StringFormat(
            "RiskOptimizer Pause: %s - %s. Tiếp tục vào: %s",
            reasonStr, state.Message, TimeToString(m_PauseUntil, TIME_DATE|TIME_MINUTES)
        ));
    }
}

//+------------------------------------------------------------------+
//| CheckResumeCondition - Kiểm tra điều kiện tiếp tục               |
//+------------------------------------------------------------------+
bool CRiskOptimizer::CheckResumeCondition()
{
    if (!m_IsPaused) return false;
    
    bool shouldResume = false;
    string resumeReason = "";
    
    // Kiểm tra thời gian pause đã hết
    datetime currentTime = TimeCurrent();
    if (currentTime >= m_PauseUntil) {
        shouldResume = true;
        resumeReason = "Hết thời gian pause";
    }
    
    // Kiểm tra chuyển session
    if (m_Config.AutoPause.ResumeOnSessionChange && m_SafeData != NULL) {
        ENUM_SESSION currentSession = m_SafeData.GetSafeCurrentSession(m_Profile);
        if (currentSession != m_LastSession && currentSession != SESSION_UNKNOWN) {
            shouldResume = true;
            resumeReason = StringFormat(
                "Chuyển phiên giao dịch (%d -> %d)", 
                (int)m_LastSession, (int)currentSession
            );
            m_LastSession = currentSession;
        }
    }
    
    // Kiểm tra mở phiên London nếu được kích hoạt
    if (m_Config.AutoPause.ResumeOnSessionChange) {
        MqlDateTime dt;
        TimeToStruct(TimeGMT(), dt);
        
        // Phiên London mở lúc 8:00 GMT
        if (dt.hour == 8 && dt.min < 15) {
            shouldResume = true;
            resumeReason = "Phiên London mở";
        }
    }
    
    // Nếu điều kiện resume thỏa mãn
    if (shouldResume) {
        m_IsPaused = false;
        m_PauseUntil = 0;
        
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "RiskOptimizer Resume: %s", resumeReason
            ));
        }
        
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ExportPerformanceStats - Xuất thống kê hiệu suất                 |
//+------------------------------------------------------------------+
void CRiskOptimizer::ExportPerformanceStats(string filename)
{
    // Nếu không có tên file, tạo tên file mặc định
    if (filename == "") {
        filename = StringFormat(
            "RiskOptimizer_Stats_%s_%s.csv",
            _Symbol,
            TimeToString(TimeCurrent(), TIME_DATE)
        );
    }
    
    // Mở file để ghi
    int handle = FileOpen(filename, FILE_WRITE|FILE_CSV);
    if (handle == INVALID_HANDLE) {
        if (m_Logger != NULL) {
            m_Logger.LogError(StringFormat(
                "Không thể mở file %s để ghi. Lỗi: %d",
                filename, GetLastError()
            ));
        }
        return;
    }
    
    // Ghi header
    FileWrite(handle, 
              "DateTime",
              "Symbol",
              "WeeklyProfit",
              "MonthlyProfit",
              "ConsecutiveProfitDays",
              "CurrentVolatilityRatio",
              "AverageATR",
              "CurrentATR",
              "LastSession"
    );
    
    // Ghi dữ liệu
    FileWrite(handle,
              TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
              m_Symbol,
              DoubleToString(m_WeeklyProfit, 2),
              DoubleToString(m_MonthlyProfit, 2),
              IntegerToString(m_ConsecutiveProfitDays),
              DoubleToString(m_LastVolatilityRatio, 2),
              DoubleToString(m_AverageATR, 5),
              DoubleToString(GetValidATR(), 5),
              IntegerToString((int)m_LastSession)
    );
    
    // Đóng file
    FileClose(handle);
    
    if (m_Logger != NULL) {
        m_Logger.LogInfo(StringFormat(
            "Đã xuất thống kê hiệu suất vào file %s",
            filename
        ));
    }
}

//+------------------------------------------------------------------+
//| UpdatePerformanceStats - Cập nhật thống kê hiệu suất             |
//+------------------------------------------------------------------+
void CRiskOptimizer::UpdatePerformanceStats(ENUM_SESSION session, ENUM_MARKET_REGIME regime, 
                                          ENUM_TRADING_STRATEGY strategy, double volatilityRatio,
                                          double atr, double rMultiple, ENUM_TRAILING_PHASE trailingPhase,
                                          double riskPercent)
{
    // Thông tin cơ bản
    string sessionName = "";
    switch(session) {
        case SESSION_ASIAN: sessionName = "Asian"; break;
        case SESSION_EUROPEAN: sessionName = "European"; break;
        case SESSION_AMERICAN: sessionName = "American"; break;
        case SESSION_EUROPEAN_AMERICAN: sessionName = "EU-US Overlap"; break;
        case SESSION_CLOSING: sessionName = "Closing"; break;
        default: sessionName = "Unknown";
    }
    
    string regimeName = "";
    switch(regime) {
        case REGIME_TRENDING: regimeName = "Trending"; break;
        case REGIME_RANGING: regimeName = "Ranging"; break;
        case REGIME_VOLATILE: regimeName = "Volatile"; break;
        case REGIME_TRANSITIONING: regimeName = "Transitioning"; break;
        default: regimeName = "Unknown";
    }
    
    string strategyName = "";
    switch(strategy) {
        case STRATEGY_BREAKOUT: strategyName = "Breakout"; break;
        case STRATEGY_PULLBACK: strategyName = "Pullback"; break;
        case STRATEGY_MEAN_REVERSION: strategyName = "Mean Reversion"; break;
        case STRATEGY_VOLATILITY_BREAKOUT: strategyName = "Volatility Breakout"; break;
        case STRATEGY_PRESERVATION: strategyName = "Preservation"; break;
        default: strategyName = "Unknown";
    }
    
    string trailingPhaseName = "";
    switch(trailingPhase) {
        case TRAILING_NONE: trailingPhaseName = "None"; break;
        case TRAILING_BREAKEVEN: trailingPhaseName = "Breakeven"; break;
        case TRAILING_FIRST_LOCK: trailingPhaseName = "First Lock"; break;
        case TRAILING_SECOND_LOCK: trailingPhaseName = "Second Lock"; break;
        case TRAILING_THIRD_LOCK: trailingPhaseName = "Third Lock"; break;
        case TRAILING_FULL_TRAILING: trailingPhaseName = "Full Trailing"; break;
        default: trailingPhaseName = "Unknown";
    }
    
    // Log thông tin performance
    if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
        m_Logger.LogDebug(StringFormat(
            "Performance Stats: Session=%s, Regime=%s, Strategy=%s, VolRatio=%.2f, ATR=%.5f, R=%.2f, TrailingPhase=%s, Risk=%.2f%%",
            sessionName, regimeName, strategyName, volatilityRatio, atr, rMultiple, trailingPhaseName, riskPercent
        ));
    }
    
    // Có thể lưu trữ thông tin này vào Database hoặc file CSV theo thời gian thực
    // Code thêm ở đây nếu cần
}

//+------------------------------------------------------------------+
//| Apply Cyclical Risk - Tính risk theo chu kỳ thời gian            |
//+------------------------------------------------------------------+
double CRiskOptimizer::ApplyCyclicalRisk(double baseRiskPercent)
{
    // Nếu không bật tính năng chu kỳ, trả về risk cơ sở
    if (!m_Config.EnableWeeklyCycle && !m_Config.EnableMonthlyCycle) {
        return baseRiskPercent;
    }
    
    double cyclicalRisk = baseRiskPercent;
    
    // Điều chỉnh theo chu kỳ tuần nếu được bật
    if (m_Config.EnableWeeklyCycle) {
        // Nếu tuần này đang lỗ, giảm risk
        if (m_WeeklyProfit < 0) {
            cyclicalRisk *= m_Config.WeeklyLossReduceFactor;
            
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Giảm risk do tuần lỗ: %.2f%% -> %.2f%% (Weekly P/L: %.2f)",
                    baseRiskPercent, cyclicalRisk, m_WeeklyProfit
                ));
            }
        }
    }
    
    // Điều chỉnh theo chu kỳ tháng nếu được bật
    if (m_Config.EnableMonthlyCycle) {
        // Nếu tháng này đang lời, tăng risk
        if (m_MonthlyProfit > 0) {
            cyclicalRisk *= m_Config.MonthlyProfitBoostFactor;
            
            if (m_Logger != NULL && m_Logger.IsDebugEnabled()) {
                m_Logger.LogDebug(StringFormat(
                    "Tăng risk do tháng lời: %.2f%% -> %.2f%% (Monthly P/L: %.2f)",
                    baseRiskPercent, cyclicalRisk, m_MonthlyProfit
                ));
            }
        }
    }
    
    // Điều chỉnh theo số ngày lời liên tiếp
    if (m_ConsecutiveProfitDays >= m_Config.ConsecutiveProfitDaysBoost) {
        // Tăng risk khi có chuỗi ngày lời
        double boostFactor = 1.0 + MathMin(0.2, (m_ConsecutiveProfitDays - m_Config.ConsecutiveProfitDaysBoost + 1) * 0.05);
        cyclicalRisk *= boostFactor;
        
        if (m_Logger != NULL) {
            m_Logger.LogInfo(StringFormat(
                "Tăng risk do %d ngày lời liên tiếp: %.2f%% -> %.2f%% (x%.2f)",
                m_ConsecutiveProfitDays, baseRiskPercent, cyclicalRisk, boostFactor
            ));
        }
    }
    
    // Đảm bảo giới hạn tăng/giảm
    double minRisk = baseRiskPercent * m_Config.MaxCycleRiskReduction;
    double maxRisk = baseRiskPercent * m_Config.MaxCycleRiskBoost;
    
    cyclicalRisk = MathMax(minRisk, MathMin(cyclicalRisk, maxRisk));
    
    return cyclicalRisk;
}