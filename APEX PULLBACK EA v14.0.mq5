//+------------------------------------------------------------------+
//|   APEX PULLBACK EA v14.1 - Professional Edition                  |
//|   Chiến lược EMA Pullback được tối ưu hóa với Market Profile     |
//|   Module hóa xuất sắc - Quản lý rủi ro đa tầng - EA chuẩn Prop   |
//|   Copyright 2025, APEX Forex - Mèo Cọc                           |
//+------------------------------------------------------------------+

#property copyright "APEX Pullback EA v15.0"
#property link      "https://www.apexpullback.com"
#property version   "15.0"
#property description "EA giao dịch tự động dựa trên chiến lược Pullback chất lượng cao"
#property description "Phiên bản v15.0 - Nâng cấp toàn diện với Pullback Detector cải tiến"
#property strict

// Include các file định nghĩa enum, struct và hằng số ở phạm vi toàn cục
#include "Enums.mqh"                        // Định nghĩa enums
#include "CommonStructs.mqh"                // Định nghĩa structs
#include "Constants.mqh"                    // Định nghĩa constants

//--- Khai báo các include
#include <Trade/Trade.mqh>
#include "Logger.mqh"                       // Hệ thống log và thông báo
#include "MarketProfile.mqh"                // Phân tích profile thị trường
#include "AssetProfiler.mqh"                // Asset Profiler
#include "SwingPointDetector.mqh"           // Phát hiện điểm swing
#include "PatternDetector.mqh"              // Phát hiện mẫu hình giá
#include "RiskManager.mqh"                  // Quản lý rủi ro
#include "TradeManager.mqh"                 // Quản lý lệnh
#include "PositionManager.mqh"              // Quản lý vị thế
#include "NewsFilter.mqh"                   // Bộ lọc tin tức
#include "Dashboard.mqh"                    // Dashboard hiển thị
#include "SessionManager.mqh"               // Quản lý phiên giao dịch
#include "AssetProfileManager.mqh"          // Asset Profile Manager
#include "IndicatorUtils.mqh"               //
#include "Inputs.mqh"                       //
#include "MathHelper.mqh"                   //
#include "PerformanceTracker.mqh"           //
#include "RiskOptimizer.mqh"                //

//+------------------------------------------------------------------+
//| Khai báo biến và đối tượng toàn cục                              |
//+------------------------------------------------------------------+

// Đối tượng chính của các module
CLogger*             g_Logger = NULL;                  // Quản lý log
CMarketProfile*      g_MarketProfile = NULL;           // Phân tích thị trường
CSwingDetector*      g_SwingDetector = NULL;           // Phát hiện swing point
CPatternDetector*    g_PatternDetector = NULL;         // Phát hiện mẫu hình
CRiskManager*        g_RiskManager = NULL;             // Quản lý rủi ro
CTradeManager*       g_TradeManager = NULL;            // Quản lý giao dịch
CPositionManager*    g_PositionManager = NULL;         // Quản lý vị thế
CNewsFilter*         g_NewsFilter = NULL;              // Bộ lọc tin tức
CDashboard*          g_Dashboard = NULL;               // Dashboard hiển thị
CSessionManager*     g_SessionManager = NULL;          // Quản lý phiên
CAssetProfiler*      g_AssetProfiler = NULL;           // [NEW] Asset Profiler

// Biến trạng thái EA
bool                 g_Initialized = false;            // Đã khởi tạo xong chưa
ENUM_EA_STATE        g_CurrentState = STATE_INIT;      // Trạng thái hiện tại của EA
MarketProfileData    g_CurrentProfile;                 // Profile thị trường hiện tại
datetime             g_LastUpdateTime = 0;             // Thời gian cập nhật cuối
datetime             g_LastTradeTime = 0;              // Thời gian giao dịch cuối
datetime             g_PauseEndTime = 0;               // Thời gian kết thúc tạm dừng
int                  g_CurrentDay = 0;                 // Ngày hiện tại
int                  g_DayTrades = 0;                  // Số lệnh trong ngày
double               g_DayStartEquity = 0.0;           // Equity đầu ngày
double               g_AverageATR = 0.0;               // ATR trung bình theo ngày
double               g_CurrentRisk = 0.0;              // Risk % hiện tại
int                  g_ConsecutiveLosses = 0;          // Số lần thua liên tiếp
bool                 g_IsBacktestMode = false;         // Đang chạy backtest?
double               g_RegimeTransitionScore = 0.0;    // Điểm chuyển tiếp chế độ
int                  g_ConsecutiveRegimeConfirm = 0;   // Số lần xác nhận chế độ liên tiếp
double               g_SpreadHistory[10];              // Lịch sử spread gần đây
double               g_AverageSpread = 0.0;            // [NEW] Spread trung bình
int                  g_IndicatorCache[10];             // [NEW] Cache cho handles chỉ báo
bool                 g_RequirePriceActionConfirm = true; // [NEW] Yêu cầu PA xác nhận

//+------------------------------------------------------------------+
//| Input Parameters - Tham số đầu vào                               |
//+------------------------------------------------------------------+
// Tham số hiển thị và thông báo
input group "=== HIỂN THỊ & THÔNG BÁO ==="
input bool     EnableDetailedLogs = false;            // Bật log chi tiết
input bool     EnableCsvLog = false;                  // Ghi log vào file CSV
input string   CsvLogFilename = "ApexPullback_Log.csv"; // Tên file CSV log
input bool     DisplayDashboard = true;               // Hiển thị dashboard
input bool     AlertsEnabled = true;                  // Bật cảnh báo
input bool     SendNotifications = false;             // Gửi thông báo đẩy
input bool     SendEmailAlerts = false;               // Gửi email
input bool     EnableTelegramNotify = false;          // Bật thông báo Telegram
input string   TelegramBotToken = "";                 // Token Bot Telegram
input string   TelegramChatID = "";                   // ID Chat Telegram
input bool     TelegramImportantOnly = true;          // Chỉ gửi thông báo quan trọng
input bool     EnableRiskEventNotify = true;          // [NEW] Thông báo sự kiện rủi ro (thua liên tiếp, DD)

// Tham số chiến lược
input group "=== CHIẾN LƯỢC CỐT LÕI ==="
input ENUM_TIMEFRAMES MainTimeframe = PERIOD_H1;      // Khung thời gian chính
input int      EMA_Fast = 34;                         // EMA nhanh (EMA 34)
input int      EMA_Medium = 89;                       // EMA trung bình (EMA 89) 
input int      EMA_Slow = 200;                        // EMA chậm (EMA 200)
input bool     UseMultiTimeframe = true;              // Sử dụng đa khung thời gian
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H4;    // Khung thời gian cao hơn 
input bool     EnablePriceAction = true;              // Kích hoạt xác nhận Price Action
input bool     StrictPriceAction = true;              // [NEW] Yêu cầu mẫu hình PA mạnh
input bool     EnableSwingLevels = true;              // Sử dụng Swing Levels
input bool     RequireSwingStructure = true;          // [NEW] Yêu cầu cấu trúc Swing rõ ràng
input double   MinPullbackPercent = 20.0;             // % Pullback tối thiểu
input double   MaxPullbackPercent = 70.0;             // % Pullback tối đa
input bool     EnableMomentumConfirmation = true;     // [NEW] Xác nhận Momentum (RSI slope + MACD)

// Tham số bộ lọc
input group "=== BỘ LỌC THỊ TRƯỜNG ==="
input bool     EnableMarketRegimeFilter = true;       // Bật lọc Market Regime
input bool     EnableVolatilityFilter = true;         // Lọc biến động bất thường
input bool     EnableAdxFilter = true;                // Lọc ADX
input double   MinAdxValue = 18.0;                    // Giá trị ADX tối thiểu
input double   MaxAdxValue = 45.0;                    // Giá trị ADX tối đa
input double   VolatilityThreshold = 2.0;             // Ngưỡng biến động (xATR)
input ENUM_MARKET_PRESET MarketPreset = PRESET_AUTO;  // Preset thị trường
input bool     EnableAdaptiveThresholds = true;       // [NEW] Sử dụng ngưỡng thích ứng (ATR/Spread)

// Tham số quản lý rủi ro
input group "=== QUẢN LÝ RỦI RO ==="
input double   RiskPercent = 1.0;                     // Risk % mỗi lệnh
input double   SL_ATR = 1.5;                          // Hệ số ATR cho Stop Loss
input double   TP_RR = 2.0;                           // Tỷ lệ R:R cho Take Profit
input bool     PropFirmMode = false;                  // Chế độ Prop Firm
input double   DailyLossLimit = 3.0;                  // Giới hạn lỗ ngày (%)
input double   MaxDrawdown = 10.0;                    // Drawdown tối đa (%)
input int      MaxTradesPerDay = 5;                   // Số lệnh tối đa/ngày
input int      MaxConsecutiveLosses = 5;              // Số lần thua liên tiếp tối đa
input double   MaxSpreadPoints = 10.0;                // Spread tối đa (points)

// Tham số điều chỉnh risk theo drawdown
input group "=== ĐIỀU CHỈNH RISK THEO DRAWDOWN ==="
input double   DrawdownReduceThreshold = 5.0;         // Ngưỡng DD để giảm risk (%)
input bool     EnableTaperedRisk = true;              // Giảm risk từ từ (không đột ngột)
input double   MinRiskMultiplier = 0.3;               // Hệ số risk tối thiểu khi DD cao

// Tham số quản lý vị thế
input group "=== QUẢN LÝ VỊ THẾ ==="
input ENUM_ENTRY_MODE EntryMode = MODE_SMART;         // Chế độ vào lệnh
input bool     AllowNewTrades = true;                 // Cho phép lệnh mới
input int      MaxPositions = 2;                      // Số vị thế tối đa
input string   OrderComment = "ApexPullback v15";     // Comment cho lệnh
input int      MagicNumber = 15000;                   // Magic number
input bool     UsePartialClose = true;                // Sử dụng đóng từng phần
input double   PartialCloseR1 = 1.0;                  // R-multiple cho đóng phần 1
input double   PartialCloseR2 = 2.0;                  // R-multiple cho đóng phần 2
input double   PartialClosePercent1 = 35.0;           // % đóng ở mức R1
input double   PartialClosePercent2 = 35.0;           // % đóng ở mức R2

// Tham số trailing stop
input group "=== TRAILING STOP ==="
input bool     UseAdaptiveTrailing = true;            // Trailing thích ứng theo regime
input ENUM_TRAILING_MODE TrailingMode = TRAILING_ATR; // Chế độ trailing mặc định
input double   TrailingAtrMultiplier = 2.0;           // Hệ số ATR cho trailing
input double   BreakEvenAfterR = 1.0;                 // Chuyển BE sau (R-multiple)
input double   BreakEvenBuffer = 5.0;                 // Buffer cho breakeven (points)

// Tham số cho Chandelier Exit
input group "=== CHANDELIER EXIT ==="
input bool     UseChandelierExit = true;              // Kích hoạt Chandelier Exit
input int      ChandelierPeriod = 20;                 // Số nến lookback Chandelier
input double   ChandelierMultiplier = 3.0;            // Hệ số ATR Chandelier

// Tham số scaling (nhồi lệnh)
input group "=== SCALING (NHỒI LỆNH) ==="
input bool     EnableScaling = false;                 // [UPDATED] Cho phép nhồi lệnh (tắt mặc định)
input int      MaxScalingCount = 1;                   // Số lần nhồi tối đa
input double   ScalingRiskPercent = 0.3;              // % risk cho lệnh nhồi (so với ban đầu)
input bool     RequireBreakEvenForScaling = true;     // Yêu cầu BE trước khi nhồi
input double   MinAdxForScaling = 25.0;               // [NEW] ADX tối thiểu cho scaling
input bool     RequireConfirmedTrend = true;          // [NEW] Yêu cầu xu hướng xác nhận để scaling

// Tham số lọc theo phiên
input group "=== LỌC PHIÊN ==="
input bool     FilterBySession = false;               // Kích hoạt lọc theo phiên
input ENUM_SESSION_FILTER SessionFilter = SESSION_ALL; // Phiên giao dịch
input bool     UseGmtOffset = true;                   // Sử dụng điều chỉnh GMT
input int      GmtOffset = 0;                         // Điều chỉnh GMT (giờ)
input bool     TradeLondonOpen = true;                // Giao dịch mở cửa London
input bool     TradeNewYorkOpen = true;               // Giao dịch mở cửa New York

// Tham số lọc tin tức
input group "=== LỌC TIN TỨC ==="
input ENUM_NEWS_FILTER NewsFilter = NEWS_MEDIUM;      // Mức lọc tin tức
input string   NewsDataFile = "news_calendar.csv";    // File dữ liệu tin tức
input int      NewsImportance = 2;                    // Độ quan trọng tin (1-3)
input int      MinutesBeforeNews = 30;                // Phút trước tin tức
input int      MinutesAfterNews = 15;                 // Phút sau tin tức

// Tham số tự động tạm dừng & khôi phục
input group "=== TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC ==="
input bool     EnableAutoPause = true;                // Bật tự động tạm dừng
input double   VolatilityPauseThreshold = 2.5;        // Ngưỡng biến động để tạm dừng (xATR)
input double   DrawdownPauseThreshold = 7.0;          // Ngưỡng DD để tạm dừng (%)
input bool     EnableAutoResume = true;               // Bật tự động khôi phục
input int      PauseDurationMinutes = 120;            // Thời gian tạm dừng (phút)
input bool     ResumeOnLondonOpen = true;             // Tự động khôi phục vào London Open

// Tham số Asset Profile (tự học)
input group "=== ASSET PROFILE (TỰ HỌC) ==="
input bool     EnableAssetProfile = false;            // Bật Asset Profile (tự học)
input int      MinimumTradesForProfile = 20;          // Số lệnh tối thiểu để học
input double   ProfileAdaptPercent = 20.0;            // % ảnh hưởng Profile lên quyết định
input int      AssetProfileDays = 60;                 // [NEW] Số ngày lịch sử để phân tích

// Tham số tối ưu hóa hiệu suất
input group "=== TỐI ƯU HÓA HIỆU SUẤT ==="
input bool     EnableIndicatorCache = true;           // [NEW] Bật cache cho chỉ báo
input int      UpdateFrequencySeconds = 3;            // [NEW] Tần suất cập nhật (giây) 
input bool     SkipVolatilityCheck = false;           // [NEW] Bỏ qua kiểm tra volatility

// Tham số tích hợp nâng cao
input group "=== TÍCH HỢP NÂNG CAO ==="
input bool     SaveStatistics = true;                 // Lưu thống kê
input bool     DisableDashboardInBacktest = true;     // Tắt dashboard trong backtest

//+------------------------------------------------------------------+
//| Khai báo các hàm chính                                           |
//+------------------------------------------------------------------+
// Khởi tạo và dọn dẹp
bool        InitializeModules();
void        CleanupModules();
bool        LoadConfiguration();
void        SaveConfiguration();

// Quản lý EA và thông báo
void        UpdateEAState();
void        ManageEAState();
void        LogMessage(string message, bool important = false);
void        SendAlert(string message, bool isImportant = false);
string      GetStateDescription(ENUM_EA_STATE state);

// Phân tích thị trường
bool        UpdateMarketData();
MarketProfileData AnalyzeMarketProfile();
bool        IsMarketConditionSuitable();
bool        IsPullbackValid(bool isLong);
bool        IsPriceActionConfirmed(bool isLong);
double      CalculateSignalQuality(SignalInfo &signal);

// [NEW] Thêm kiểm tra momentum và cấu trúc swing
bool        IsMomentumConfirmed(bool isLong);
double      GetRSISlope(int period = 14);
double      GetMACDHistogramSlope();
bool        HasValidSwingStructure(bool isLong);

// Xử lý vào lệnh
void        CheckNewTradeOpportunities();
SignalInfo  DetectPullbackSignal();
bool        ValidateTradeConditions(SignalInfo &signal);
double      CalculateAdaptiveRiskPercent();
double      CalculateLotSize(double riskPercent, double slPoints);

// Quản lý vị thế
void        ManageOpenPositions();
double      CalculateDynamicTrailingStop(ulong ticket, double entryPrice, double currentPrice, bool isLong);
double      CalculateChandelierExit(bool isLong, int period, double multiplier);
double      CalculateSwingBasedTrailingStop(bool isLong);
bool        CheckPartialCloseConditions(ulong ticket, double entryPrice, double currentPrice, bool isLong);
bool        ShouldScaleInPosition(ulong ticket);

// Quản lý rủi ro và bảo vệ
bool        IsSpreadAcceptable();
bool        IsVolatilityAcceptable();
bool        IsNewsTimeFilter();
bool        IsSessionActive();
void        UpdateDailyStats();
void        CheckDrawdownProtection();
double      GetAverageATR();
void        UpdateAtrHistory();
double      GetAdaptiveMaxSpread();
void        UpdateSpreadHistory();
double      GetAdaptiveVolatilityThreshold();   // [NEW] Thích ứng ngưỡng biến động

// Hiển thị và tiện ích
void        UpdateDashboard();
void        DrawValueZones();
string      TimeframeToString(ENUM_TIMEFRAMES tf);
string      GetDeinitReasonText(const int reason);

// Asset Profile (tự học)
void        UpdateAssetProfile(bool win, double profit, string scenario);
bool        AdjustSignalByAssetProfile(SignalInfo &signal);

// [NEW] Tối ưu hóa hiệu suất
void        InitializeIndicatorCache();
void        ClearIndicatorCache();
int         GetIndicatorHandle(int indicatorType, string symbol, ENUM_TIMEFRAMES timeframe);
bool        ShouldUpdateCalculations(datetime currentTime);

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
    Print("APEX Pullback EA v15.0 - Đang khởi tạo trên ", _Symbol);
    
    // Kiểm tra nếu đang ở chế độ backtest
    g_IsBacktestMode = (MQLInfoInteger(MQL_TESTER) || MQLInfoInteger(MQL_OPTIMIZATION));
    
    // Khởi tạo trạng thái EA
    g_CurrentState = STATE_INIT;
    
    // Khởi tạo Logger - module quan trọng nhất, phải khởi tạo đầu tiên
    g_Logger = new CLogger();
    if (g_Logger == NULL) {
        Print("LỖI: Không thể tạo Logger - bộ nhớ không đủ");
        return INIT_FAILED;
    }
    
    if (!g_Logger.Initialize("ApexPullbackV15", EnableDetailedLogs, EnableCsvLog, CsvLogFilename, 
                           EnableTelegramNotify, TelegramBotToken, TelegramChatID, TelegramImportantOnly)) {
        Print("LỖI: Không thể khởi tạo Logger");
        return INIT_FAILED;
    }
    
    // Ghi log bắt đầu quá trình khởi tạo
    LogMessage("APEX Pullback EA v15.0 - Bắt đầu khởi tạo trên " + _Symbol, true);
    
    // Lấy ngày hiện tại và equity ban đầu
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    g_CurrentDay = time.day;
    g_DayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
    g_CurrentRisk = RiskPercent; // Risk ban đầu
    
    // Khởi tạo mảng lưu trữ spread
    for (int i = 0; i < 10; i++) {
        g_SpreadHistory[i] = 0;
    }
    
    // [NEW] Khởi tạo cache chỉ báo
    InitializeIndicatorCache();
    
    // Khởi tạo các module chính
    if (!InitializeModules()) {
        LogMessage("LỖI: Không thể khởi tạo các module chính", true);
        CleanupModules(); // Dọn dẹp nếu khởi tạo thất bại
        return INIT_FAILED;
    }
    
    // Nạp cấu hình
    if (!LoadConfiguration()) {
        LogMessage("CẢNH BÁO: Không thể nạp cấu hình, sử dụng giá trị mặc định", true);
    }
    
    // Cập nhật ATR trung bình và dữ liệu thị trường
    UpdateAtrHistory();
    if (!UpdateMarketData()) {
        LogMessage("CẢNH BÁO: Cập nhật dữ liệu thị trường không thành công", true);
    }
    
    // Cập nhật spread trung bình
    UpdateSpreadHistory();
    
    // Tạo Dashboard nếu được bật
    if (DisplayDashboard && (!g_IsBacktestMode || !DisableDashboardInBacktest)) {
        LogMessage("Tạo Dashboard hiển thị...");
        g_Dashboard = new CDashboard();
        if (g_Dashboard != NULL) {
            g_Dashboard.Initialize(_Symbol, OrderComment);
            g_Dashboard.Update(g_CurrentProfile);
        } else {
            LogMessage("CẢNH BÁO: Không thể tạo Dashboard", true);
        }
    }
    
    // Thiết lập timer cho xử lý nền
    if (!g_IsBacktestMode) {
        EventSetTimer(60); // Cập nhật mỗi 60 giây
        LogMessage("Đã thiết lập timer cho xử lý nền");
    }
    
    // Cập nhật trạng thái EA
    g_CurrentState = STATE_RUNNING;
    g_Initialized = true;
    
    // Lưu thời gian khởi tạo
    g_LastUpdateTime = TimeCurrent();
    
    // Cập nhật lần cuối
    UpdateEAState();
    UpdateDashboard();
    
    LogMessage("APEX Pullback EA v15.0 đã khởi tạo thành công", true);
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
    // Lưu thống kê nếu được cấu hình
    if (g_Initialized && SaveStatistics) {
        SaveConfiguration();
    }
    
    // Ghi log lý do kết thúc
    LogMessage("Dừng EA - Lý do: " + GetDeinitReasonText(reason), true);
    
    // Hủy timer
    EventKillTimer();
    
    // [NEW] Xóa cache chỉ báo
    ClearIndicatorCache();
    
    // Xóa dashboard nếu có
    if (g_Dashboard != NULL) {
        g_Dashboard.Clear();
    }
    
    // Dọn dẹp các đối tượng
    CleanupModules();
    
    // Đặt trạng thái đã kết thúc
    g_Initialized = false;
    
    Print("APEX Pullback EA v15.0 đã kết thúc");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
    // Kiểm tra EA đã khởi tạo chưa
    if (!g_Initialized) return;
    
    // Kiểm tra tần suất xử lý (không xử lý quá nhiều)
    static uint lastBarTime = 0;
    uint currentBarTime = (uint)iTime(_Symbol, MainTimeframe, 0);
    if (!g_IsBacktestMode && currentBarTime == lastBarTime && !IsNewBar()) {
        // Giới hạn tần suất xử lý trong thời gian thực
        static datetime lastProcessTime = 0;
        datetime currentTime = TimeCurrent();
        
        // [UPDATED] Sử dụng tham số tần suất cập nhật
        if (currentTime - lastProcessTime < UpdateFrequencySeconds)
            return;
        
        lastProcessTime = currentTime;
    }
    lastBarTime = currentBarTime;
    
    // Cập nhật thống kê ngày
    UpdateDailyStats();
    
    // Quản lý trạng thái EA
    UpdateEAState();
    ManageEAState();
    
    // Nếu đang tạm dừng, skip xử lý chính
    if (g_CurrentState == STATE_PAUSED) {
        // Kiểm tra nếu đã hết thời gian tạm dừng
        if (TimeCurrent() >= g_PauseEndTime) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục hoạt động sau thời gian tạm dừng", true);
            UpdateEAState();
        } else {
            // Vẫn đang trong thời gian tạm dừng
            return;
        }
    }
    
    // Kiểm tra các điều kiện thị trường
    if (!IsSpreadAcceptable()) {
        LogMessage("Spread hiện tại không phù hợp: " + 
                 DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 1) + " điểm");
        return;
    }
    
    if (FilterBySession && !IsSessionActive()) {
        LogMessage("Không phải phiên giao dịch đã cấu hình");
        return;
    }
    
    if (NewsFilter != NEWS_NONE && IsNewsTimeFilter()) {
        LogMessage("Có tin tức quan trọng sắp diễn ra");
        return;
    }
    
    // Cập nhật dữ liệu thị trường nhẹ nhàng
    static datetime lastMarketUpdateTime = 0;
    datetime currentTime = TimeCurrent();
    bool isNewBar = IsNewBar();
    
    // [UPDATED] Sử dụng ShouldUpdateCalculations để giảm tính toán
    if (isNewBar || ShouldUpdateCalculations(lastMarketUpdateTime)) {
        if (UpdateMarketData()) {
            lastMarketUpdateTime = currentTime;
        }
    }
    
    // Quản lý vị thế đang mở
    ManageOpenPositions();
    
    // Kiểm tra điều kiện vào lệnh mới
    int positions = g_TradeManager.CountPositions();
    if (AllowNewTrades && positions < MaxPositions) {
        if (g_DayTrades < MaxTradesPerDay || !PropFirmMode) {
            CheckNewTradeOpportunities();
        } else {
            LogMessage("Đã đạt giới hạn lệnh trong ngày: " + IntegerToString(g_DayTrades) + 
                     "/" + IntegerToString(MaxTradesPerDay));
        }
    }
    
    // Cập nhật Dashboard nếu có
    if (g_Dashboard != NULL && DisplayDashboard) {
        static datetime lastDashboardUpdate = 0;
        if (currentTime - lastDashboardUpdate > 2) { // Cập nhật mỗi 2 giây
            g_Dashboard.Update(g_CurrentProfile);
            lastDashboardUpdate = currentTime;
        }
    }
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {
    // Trong chế độ backtest, không cần xử lý timer
    if (g_IsBacktestMode) return;
    
    // Xử lý cập nhật nền ít tốn tài nguyên
    static datetime lastTimerUpdate = 0;
    datetime currentTime = TimeCurrent();
    
    // Chỉ xử lý mỗi 60 giây
    if (currentTime - lastTimerUpdate < 60)
        return;
    
    lastTimerUpdate = currentTime;
    
    // Cập nhật dữ liệu thị trường nếu cần
    if (ShouldUpdateCalculations(g_LastUpdateTime)) {
        UpdateMarketData();
        g_LastUpdateTime = currentTime;
    }
    
    // Cập nhật ATR trung bình nếu là thứ 2 đầu tuần
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    static int lastUpdateDay = -1;
    if (dt.day_of_week == 1 && dt.day != lastUpdateDay) {
        UpdateAtrHistory();
        UpdateSpreadHistory();
        lastUpdateDay = dt.day;
    }
    
    // Cập nhật tin tức nếu sử dụng bộ lọc tin
    if (::NewsFilter != NEWS_NONE && g_NewsFilter != NULL) {
        g_NewsFilter.UpdateNews();
    }
    
    // Kiểm tra bảo vệ DD
    CheckDrawdownProtection();
    
    // Cập nhật Dashboard
    if (g_Dashboard != NULL && DisplayDashboard) {
        g_Dashboard.Update(g_CurrentProfile);
    }
}

//+------------------------------------------------------------------+
//| Trade transaction function                                       |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result) {
    // Cho TradeManager xử lý giao dịch
    if (g_TradeManager != NULL) {
        g_TradeManager.ProcessTransaction(trans, request, result);
    }
    
    // Xử lý khi có lệnh đóng
    if (trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal > 0) {
        // Chỉ xử lý giao dịch thuộc EA này
        if (HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == MagicNumber && 
            HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
            
            // Lấy thông tin lệnh
            double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
            bool isWin = (profit > 0);
            
            // Xử lý comment để lấy scenario
            string dealComment = HistoryDealGetString(trans.deal, DEAL_COMMENT);
            string scenario = ""; 
            
            // Cố gắng trích xuất scenario từ comment
            if (StringFind(dealComment, "SCENARIO=") >= 0) {
                int startPos = StringFind(dealComment, "SCENARIO=") + 9;
                int endPos = StringFind(dealComment, ";", startPos);
                if (endPos < 0) endPos = StringLen(dealComment);
                
                scenario = StringSubstr(dealComment, startPos, endPos - startPos);
            } else {
                scenario = "PULLBACK"; // Mặc định
            }
            
            // Cập nhật thống kê
            if (isWin) {
                g_ConsecutiveLosses = 0;
                LogMessage("Lệnh đóng lãi: " + DoubleToString(profit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY), true);
                
                // Cập nhật Asset Profile nếu bật
                if (EnableAssetProfile && g_AssetProfiler != NULL) {
                    UpdateAssetProfile(true, profit, scenario);
                }
            } else {
                g_ConsecutiveLosses++;
                LogMessage("Lệnh đóng lỗ: " + DoubleToString(profit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) + 
                         ", Thua liên tiếp: " + IntegerToString(g_ConsecutiveLosses), true);
                
                // Cập nhật Asset Profile nếu bật
                if (EnableAssetProfile && g_AssetProfiler != NULL) {
                    UpdateAssetProfile(false, profit, scenario);
                }
                
                // Kiểm tra điều kiện tạm dừng do chuỗi thua
                if (EnableAutoPause && g_ConsecutiveLosses >= MaxConsecutiveLosses) {
                    g_CurrentState = STATE_PAUSED;
                    g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
                    LogMessage("EA tạm dừng do đạt giới hạn thua liên tiếp: " + IntegerToString(g_ConsecutiveLosses) + 
                             " lệnh. Tiếp tục sau: " + TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES), true);
                    
                    // Gửi thông báo
                    if (AlertsEnabled) {
                        SendAlert("EA tạm dừng do thua " + IntegerToString(g_ConsecutiveLosses) + " lệnh liên tiếp", true);
                        
                        // Gửi thông báo riêng cho sự kiện rủi ro
                        if (EnableRiskEventNotify && EnableTelegramNotify && g_Logger != NULL) {
                            string riskMsg = "⚠️ CẢNH BÁO RỦI RO: Thua " + IntegerToString(g_ConsecutiveLosses) + 
                                          " lệnh liên tiếp! EA tạm dừng đến " + 
                                          TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES);
                            g_Logger.SendTelegramMessage(riskMsg);
                        }
                    }
                    
                    UpdateEAState();
                }
            }
            
            // Cập nhật Dashboard nếu có
            if (g_Dashboard != NULL && DisplayDashboard) {
                g_Dashboard.Update(g_CurrentProfile);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Khởi tạo các module chính                                        |
//+------------------------------------------------------------------+
bool InitializeModules() {
    // Đã khởi tạo Logger ở OnInit, kiểm tra lại
    if (g_Logger == NULL) {
        Print("LỖI: Logger chưa được khởi tạo");
        return false;
    }
    
    // Khởi tạo SessionManager
    g_SessionManager = new CSessionManager();
    if (g_SessionManager == NULL) {
        LogMessage("LỖI: Không thể tạo Session Manager", true);
        return false;
    }
    
    if (!g_SessionManager.Initialize(FilterBySession, GmtOffset, (int)SessionFilter, 
                                  TradeLondonOpen, TradeNewYorkOpen)) {
        LogMessage("LỖI: Không thể khởi tạo Session Manager", true);
        return false;
    }
    
    // Khởi tạo MarketProfile
    g_MarketProfile = new CMarketProfile();
    if (g_MarketProfile == NULL) {
        LogMessage("LỖI: Không thể tạo Market Profile", true);
        return false;
    }
    
    if (!g_MarketProfile.Initialize(_Symbol, MainTimeframe, EMA_Fast, EMA_Medium, EMA_Slow,
                                UseMultiTimeframe, HigherTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Market Profile", true);
        return false;
    }
    
    // Thiết lập tham số thêm
    g_MarketProfile.SetParameters(MinAdxValue, MaxAdxValue, GetAdaptiveVolatilityThreshold(), MarketPreset);
    
    // Khởi tạo SwingDetector
    g_SwingDetector = new CSwingDetector();
    if (g_SwingDetector == NULL) {
        LogMessage("LỖI: Không thể tạo Swing Detector", true);
        return false;
    }
    
    if (!g_SwingDetector.Initialize(_Symbol, MainTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Swing Detector", true);
        return false;
    }
    g_SwingDetector.SetParameters(EnableSwingLevels);
    
    // Khởi tạo PatternDetector
    g_PatternDetector = new CPatternDetector();
    if (g_PatternDetector == NULL) {
        LogMessage("LỖI: Không thể tạo Pattern Detector", true);
        return false;
    }
    
    if (!g_PatternDetector.Initialize(_Symbol, MainTimeframe, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Pattern Detector", true);
        return false;
    }
    
    // Khởi tạo RiskManager
    g_RiskManager = new CRiskManager();
    if (g_RiskManager == NULL) {
        LogMessage("LỖI: Không thể tạo Risk Manager", true);
        return false;
    }
    
    if (!g_RiskManager.Initialize(RiskPercent, PropFirmMode, DailyLossLimit, MaxDrawdown,
                               MaxTradesPerDay, MaxConsecutiveLosses, DrawdownReduceThreshold, 
                               g_DayStartEquity, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Risk Manager", true);
        return false;
    }
    
    // Thiết lập tham số thêm
    g_RiskManager.SetTaperedRisk(EnableTaperedRisk, MinRiskMultiplier);
    
    // Khởi tạo TradeManager
    g_TradeManager = new CTradeManager();
    if (g_TradeManager == NULL) {
        LogMessage("LỖI: Không thể tạo Trade Manager", true);
        return false;
    }
    
    if (!g_TradeManager.Initialize(_Symbol, MagicNumber, OrderComment, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Trade Manager", true);
        return false;
    }
    
    // Thiết lập tham số
    g_TradeManager.SetEntryMode(EntryMode);
    g_TradeManager.SetTrailingParameters(UseAdaptiveTrailing, TrailingMode, TrailingAtrMultiplier,
                                      BreakEvenAfterR, BreakEvenBuffer);
    
    // Khởi tạo PositionManager
    g_PositionManager = new CPositionManager();
    if (g_PositionManager == NULL) {
        LogMessage("LỖI: Không thể tạo Position Manager", true);
        return false;
    }
    
    if (!g_PositionManager.Initialize(_Symbol, MagicNumber, g_TradeManager, g_Logger)) {
        LogMessage("LỖI: Không thể khởi tạo Position Manager", true);
        return false;
    }
    
    // Thiết lập tham số
    g_PositionManager.SetPartialCloseParameters(UsePartialClose, PartialCloseR1, PartialCloseR2, 
                                             PartialClosePercent1, PartialClosePercent2);
    g_PositionManager.SetScalingParameters(EnableScaling, MaxScalingCount, ScalingRiskPercent, 
                                        RequireBreakEvenForScaling);
    g_PositionManager.EnableChandelierExit(UseChandelierExit, ChandelierPeriod, ChandelierMultiplier);
    
    // Khởi tạo NewsFilter
    if (NewsFilter != NEWS_NONE) {
        g_NewsFilter = new CNewsFilter();
        if (g_NewsFilter == NULL) {
            LogMessage("LỖI: Không thể tạo News Filter", true);
            return false;
        }
        
        if (!g_NewsFilter.Initialize(_Symbol, (int)NewsFilter, NewsImportance, 
                                  MinutesBeforeNews, MinutesAfterNews, NewsDataFile, g_Logger)) {
            LogMessage("CẢNH BÁO: Không thể khởi tạo News Filter. Bộ lọc tin tức có thể không hoạt động chính xác", true);
        }
    }
    
    // Khởi tạo Asset Profiler nếu được bật
    if (EnableAssetProfile) {
        g_AssetProfiler = new CAssetProfiler();
        if (g_AssetProfiler == NULL) {
            LogMessage("LỖI: Không thể tạo Asset Profiler", true);
            return false;
        }
        
        if (!g_AssetProfiler.Initialize(_Symbol, MinimumTradesForProfile, ProfileAdaptPercent, g_Logger)) {
            LogMessage("CẢNH BÁO: Không thể khởi tạo Asset Profiler. Tính năng tự học có thể không hoạt động chính xác", true);
        } else {
            // Phân tích hồ sơ tài sản
            if (g_AssetProfiler.AnalyzeAsset(AssetProfileDays)) {
                LogMessage("Asset Profile được tạo thành công cho " + _Symbol);
            } else {
                LogMessage("CẢNH BÁO: Không thể tạo Asset Profile đầy đủ", true);
            }
        }
    }
    
    LogMessage("Đã khởi tạo tất cả các module thành công");
    return true;
}

//+------------------------------------------------------------------+
//| Dọn dẹp module khi kết thúc                                      |
//+------------------------------------------------------------------+
void CleanupModules() {
    // Dọn dẹp theo thứ tự ngược lại với khởi tạo
    
    // Dashboard
    if (g_Dashboard != NULL) {
        delete g_Dashboard;
        g_Dashboard = NULL;
    }
    
    // Asset Profiler
    if (g_AssetProfiler != NULL) {
        delete g_AssetProfiler;
        g_AssetProfiler = NULL;
    }
    
    // NewsFilter
    if (g_NewsFilter != NULL) {
        delete g_NewsFilter;
        g_NewsFilter = NULL;
    }
    
    // PositionManager
    if (g_PositionManager != NULL) {
        delete g_PositionManager;
        g_PositionManager = NULL;
    }
    
    // TradeManager
    if (g_TradeManager != NULL) {
        delete g_TradeManager;
        g_TradeManager = NULL;
    }
    
    // RiskManager
    if (g_RiskManager != NULL) {
        delete g_RiskManager;
        g_RiskManager = NULL;
    }
    
    // PatternDetector
    if (g_PatternDetector != NULL) {
        delete g_PatternDetector;
        g_PatternDetector = NULL;
    }
    
    // SwingDetector
    if (g_SwingDetector != NULL) {
        delete g_SwingDetector;
        g_SwingDetector = NULL;
    }
    
    // MarketProfile
    if (g_MarketProfile != NULL) {
        delete g_MarketProfile;
        g_MarketProfile = NULL;
    }
    
    // SessionManager
    if (g_SessionManager != NULL) {
        delete g_SessionManager;
        g_SessionManager = NULL;
    }
    
    // Logger - xóa cuối cùng
    if (g_Logger != NULL) {
        delete g_Logger;
        g_Logger = NULL;
    }
}

//+------------------------------------------------------------------+
//| Cập nhật trạng thái EA                                           |
//+------------------------------------------------------------------+
void UpdateEAState() {
    // Lưu trạng thái trước đó để kiểm tra thay đổi
    ENUM_EA_STATE previousState = g_CurrentState;
    
    // Kiểm tra điều kiện tạm dừng
    
    // 1. Kiểm tra tạm dừng do Drawdown
    if (g_CurrentState == STATE_RUNNING && g_RiskManager != NULL) {
        double currentDD = g_RiskManager.GetCurrentDrawdown();
        
        if (currentDD >= MaxDrawdown) {
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
            LogMessage("EA tạm dừng do vượt ngưỡng Drawdown: " + DoubleToString(currentDD, 2) + 
                     "% > " + DoubleToString(MaxDrawdown, 2) + "%", true);
            
            // Gửi thông báo riêng cho sự kiện rủi ro
            if (EnableRiskEventNotify && EnableTelegramNotify && g_Logger != NULL) {
                string riskMsg = "⚠️ CẢNH BÁO RỦI RO: Drawdown " + DoubleToString(currentDD, 2) + 
                              "% vượt ngưỡng " + DoubleToString(MaxDrawdown, 2) + 
                              "%! EA tạm dừng đến " + TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES);
                g_Logger.SendTelegramMessage(riskMsg);
            }
        }
        else if (currentDD >= DrawdownReduceThreshold && EnableTaperedRisk) {
            g_CurrentState = STATE_REDUCED_RISK;
            LogMessage("EA chuyển sang chế độ giảm risk do DD: " + DoubleToString(currentDD, 2) + "%", true);
        }
    }
    
    // 2. Kiểm tra tạm dừng do volatility
    if (g_CurrentState == STATE_RUNNING && EnableVolatilityFilter && g_MarketProfile != NULL && !SkipVolatilityCheck) {
        double volatilityRatio = g_CurrentProfile.atrRatio;
        double adaptiveThreshold = GetAdaptiveVolatilityThreshold();
        
        if (volatilityRatio > adaptiveThreshold) {
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
            LogMessage("EA tạm dừng do biến động quá cao: " + DoubleToString(volatilityRatio, 2) + 
                     "x > " + DoubleToString(adaptiveThreshold, 2) + "x ATR trung bình", true);
        }
    }
    
    // 3. Kiểm tra tạm dừng do spread cao
    if (g_CurrentState == STATE_RUNNING && !IsSpreadAcceptable()) {
        static datetime lastSpreadPause = 0;
        datetime currentTime = TimeCurrent();
        
        // Chỉ tạm dừng mỗi 5 phút do spread cao để tránh quá nhiều log
        if (currentTime - lastSpreadPause > 300) {
            // Sử dụng spread max thích ứng
            double maxSpread = EnableAdaptiveThresholds ? GetAdaptiveMaxSpread() : MaxSpreadPoints;
            
            g_CurrentState = STATE_PAUSED;
            g_PauseEndTime = currentTime + 300; // Tạm dừng 5 phút
            LogMessage("EA tạm dừng do spread cao: " + 
                     DoubleToString(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD), 1) + 
                     " > " + DoubleToString(maxSpread, 1) + " điểm", true);
            lastSpreadPause = currentTime;
        }
    }
    
    // 4. Kiểm tra điều kiện tự động resume
    if (g_CurrentState == STATE_PAUSED && EnableAutoResume) {
        datetime currentTime = TimeCurrent();
        
        // Hết thời gian tạm dừng
        if (currentTime >= g_PauseEndTime) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục hoạt động sau thời gian tạm dừng", true);
        }
        
        // Kiểm tra phiên London Open
        if (ResumeOnLondonOpen && g_SessionManager != NULL && g_SessionManager.IsLondonOpening()) {
            g_CurrentState = STATE_RUNNING;
            LogMessage("EA tự động tiếp tục vào phiên mở cửa London", true);
        }
    }
    
    // Ghi log khi có thay đổi trạng thái
    if (previousState != g_CurrentState) {
        LogMessage("Trạng thái EA thay đổi: " + GetStateDescription(previousState) + 
                 " -> " + GetStateDescription(g_CurrentState), true);
        
        // Cập nhật Dashboard
        if (g_Dashboard != NULL && DisplayDashboard) {
            g_Dashboard.Update(g_CurrentProfile);
        }
    }
}

//+------------------------------------------------------------------+
//| Quản lý trạng thái EA                                           |
//+------------------------------------------------------------------+
void ManageEAState() {
    // Xử lý theo trạng thái hiện tại
    switch (g_CurrentState) {
        case STATE_RUNNING:
            // Trạng thái bình thường, sử dụng risk bình thường
            g_CurrentRisk = RiskPercent;
            break;
            
        case STATE_REDUCED_RISK:
            // Giảm risk theo drawdown
            g_CurrentRisk = CalculateAdaptiveRiskPercent();
            break;
            
        case STATE_PAUSED:
            // Tạm dừng, không làm gì
            break;
            
        default:
            // Các trạng thái khác
            break;
    }
}

//+------------------------------------------------------------------+
//| Lấy mô tả trạng thái EA                                         |
//+------------------------------------------------------------------+
string GetStateDescription(ENUM_EA_STATE state) {
    switch (state) {
        case STATE_INIT:       return "Đang khởi tạo";
        case STATE_RUNNING:    return "Đang hoạt động";
        case STATE_PAUSED:     return "Tạm dừng";
        case STATE_REDUCED_RISK: return "Giảm risk";
        case STATE_ERROR:      return "Lỗi";
        default:               return "Không xác định";
    }
}

//+------------------------------------------------------------------+
//| Cập nhật dữ liệu thị trường                                      |
//+------------------------------------------------------------------+
bool UpdateMarketData() {
    if (g_MarketProfile == NULL || g_SwingDetector == NULL)
        return false;
    
    // Cập nhật MarketProfile
    if (!g_MarketProfile.Update()) {
        LogMessage("Không thể cập nhật Market Profile", true);
        return false;
    }
    
    // Cập nhật SwingDetector
    if (!g_SwingDetector.Update()) {
        LogMessage("Không thể cập nhật Swing Detector", true);
        return false;
    }
    
    // Phân tích profile thị trường
    g_CurrentProfile = AnalyzeMarketProfile();
    
    // Log thông tin thị trường (chỉ khi log chi tiết)
    if (EnableDetailedLogs) {
        string profileDesc = StringFormat(
            "Market Profile: Trend=%s, Session=%s, ATR=%.5f (%.1f%%), ADX=%.1f, Volatility=%s, Transitioning=%s",
            EnumToString(g_CurrentProfile.trend),
            EnumToString(g_CurrentProfile.currentSession),
            g_CurrentProfile.atrCurrent,
            g_CurrentProfile.atrRatio * 100,
            g_CurrentProfile.adxValue,
            g_CurrentProfile.isVolatile ? "Cao" : "Bình thường",
            g_CurrentProfile.isTransitioning ? "Đúng" : "Không"
        );
        LogMessage(profileDesc);
    }
    
    return true;
//| Phân tích profile thị trường                                     |
//+------------------------------------------------------------------+
MarketProfileData AnalyzeMarketProfile() {
    MarketProfileData profile;
    ZeroMemory(profile); // Đảm bảo tất cả các trường được khởi tạo với giá trị 0
    
    // Kiểm tra MarketProfile có khởi tạo đúng chưa
    if (g_MarketProfile == NULL) {
        LogMessage("Lỗi: MarketProfile chưa được khởi tạo", true);
        return profile; // Trả về profile rỗng nhưng đã khởi tạo an toàn
    }
    
    // Lấy dữ liệu từ MarketProfile với kiểm tra lỗi chi tiết
    try {
        // Thông tin cơ bản về xu hướng và chế độ
        profile.trend = g_MarketProfile.GetTrend();
        profile.regime = g_MarketProfile.GetRegime();
        profile.atrCurrent = g_MarketProfile.GetATR();
        profile.adxValue = g_MarketProfile.GetADX();
        
        // Đảm bảo giá trị hợp lệ trước khi sử dụng
        if (profile.atrCurrent <= 0) {
            LogMessage("Cảnh báo: Giá trị ATR không hợp lệ", false);
            profile.atrCurrent = _Point * 10; // Giá trị mặc định an toàn
        }
        
        // Tính toán các thuộc tính phụ thuộc
        profile.isTrending = (profile.adxValue > MinAdxValue);
        profile.isVolatile = (profile.atrCurrent > g_AverageATR * GetAdaptiveVolatilityThreshold());
        
        // Đảm bảo không chia cho 0
        if (g_AverageATR > 0) {
            profile.atrRatio = profile.atrCurrent / g_AverageATR;
        } else {
            profile.atrRatio = 1.0;
            LogMessage("Cảnh báo: g_AverageATR = 0, sử dụng giá trị mặc định cho atrRatio", false);
        }
        
        // Lấy thông tin EMA với kiểm tra hợp lệ
        profile.ema34 = g_MarketProfile.GetEMA(EMA_Fast, 0);
        profile.ema89 = g_MarketProfile.GetEMA(EMA_Medium, 0);
        profile.ema200 = g_MarketProfile.GetEMA(EMA_Slow, 0);
        
        // Kiểm tra giá trị EMA hợp lệ
        if (profile.ema34 <= 0 || profile.ema89 <= 0 || profile.ema200 <= 0) {
            LogMessage("Cảnh báo: Giá trị EMA không hợp lệ", false);
        }
        
        // Lấy thông tin EMA từ timeframe cao hơn
        if (UseMultiTimeframe) {
            profile.ema34H4 = g_MarketProfile.GetHigherTimeframeEMA(EMA_Fast, 0);
            profile.ema89H4 = g_MarketProfile.GetHigherTimeframeEMA(EMA_Medium, 0);
            profile.ema200H4 = g_MarketProfile.GetHigherTimeframeEMA(EMA_Slow, 0);
            
            // Kiểm tra giá trị EMA H4 hợp lệ
            if (profile.ema34H4 <= 0 || profile.ema89H4 <= 0 || profile.ema200H4 <= 0) {
                LogMessage("Cảnh báo: Giá trị EMA H4 không hợp lệ", false);
            }
        }
        
        // Thêm thông tin RSI và MACD
        profile.rsiValue = g_MarketProfile.GetRSI();
        profile.rsiSlope = GetRSISlope();
        profile.macdHistogram = g_MarketProfile.GetMACDHistogram();
        profile.macdHistogramSlope = GetMACDHistogramSlope();
        
        // Kiểm tra sự chuyển tiếp chế độ thị trường
        profile.regimeConfidence = g_MarketProfile.GetRegimeConfidence();
        profile.isTransitioning = (profile.regimeConfidence < 0.6);
        
        // Cập nhật điểm chuyển tiếp regime và số lần xác nhận liên tiếp
        if (profile.isTransitioning) {
            g_RegimeTransitionScore = 1.0 - profile.regimeConfidence;
            g_ConsecutiveRegimeConfirm = 0;
        } else {
            g_RegimeTransitionScore = 0.0;
            g_ConsecutiveRegimeConfirm++;
        }
    } catch (Exception e) {
        LogMessage("Lỗi khi phân tích profile thị trường: " + e.Message, true);
        return profile; // Trả về profile rỗng nhưng đã khởi tạo an toàn
    }
    
    // Lấy thông tin swing points
    if (g_SwingDetector != NULL) {
        try {
            profile.recentSwingHigh = g_SwingDetector.GetLastSwingHigh();
            profile.recentSwingLow = g_SwingDetector.GetLastSwingLow();
        } catch (Exception e) {
            LogMessage("Lỗi khi lấy thông tin swing points: " + e.Message, true);
            profile.recentSwingHigh = 0;
            profile.recentSwingLow = 0;
        }
    }
    
    // Xác định phiên giao dịch
    if (g_SessionManager != NULL) {
        try {
            profile.currentSession = g_SessionManager.GetCurrentSession();
        } catch (Exception e) {
            LogMessage("Lỗi khi xác định phiên giao dịch: " + e.Message, true);
            profile.currentSession = SESSION_UNKNOWN;
        }
    } else {
        // Mặc định nếu không có SessionManager
        MqlDateTime dt;
        TimeToStruct(TimeGMT() + GmtOffset * 3600, dt);
        
        if (dt.hour >= 8 && dt.hour < 12) profile.currentSession = SESSION_LONDON;
        else if (dt.hour >= 12 && dt.hour < 17) profile.currentSession = SESSION_NEWYORK;
        else if (dt.hour >= 0 && dt.hour < 8) profile.currentSession = SESSION_ASIAN;
        else profile.currentSession = SESSION_CLOSING;
    }
    
    return profile;
}
        LogMessage("Pullback bị từ chối: Không có xu hướng H4 rõ ràng");
        return false;
    }
    
    // Điều kiện 2: Kiểm tra vùng pullback (khoảng EMA 34-89)
    bool validPullbackZone = false;
    double priceToEma34Percent = 0;
    
    if (isLong) {
        // Tính % pullback
        if (g_CurrentProfile.recentSwingHigh > g_CurrentProfile.ema34) {
            priceToEma34Percent = (g_CurrentProfile.recentSwingHigh - currentPrice) / 
                                (g_CurrentProfile.recentSwingHigh - g_CurrentProfile.ema34) * 100;
        }
        
        // Pullback hợp lệ: Giá dưới/gần EMA34 nhưng không vượt quá EMA89 quá nhiều
        validPullbackZone = (currentPrice <= g_CurrentProfile.ema34 * 1.001) && 
                          (currentPrice >= g_CurrentProfile.ema89 * 0.995) &&
                          (currentPrice > g_CurrentProfile.ema200); // Luôn trên EMA200
        
        // Kiểm tra thêm % pullback
        if (priceToEma34Percent < MinPullbackPercent || priceToEma34Percent > MaxPullbackPercent) {
            validPullbackZone = false;
        }
    } else {
        // Tính % pullback
        if (g_CurrentProfile.recentSwingLow < g_CurrentProfile.ema34) {
            priceToEma34Percent = (currentPrice - g_CurrentProfile.recentSwingLow) / 
                                (g_CurrentProfile.ema34 - g_CurrentProfile.recentSwingLow) * 100;
        }
        
        // Pullback hợp lệ: Giá trên/gần EMA34 nhưng không vượt quá EMA89 quá nhiều
        validPullbackZone = (currentPrice >= g_CurrentProfile.ema34 * 0.999) && 
                          (currentPrice <= g_CurrentProfile.ema89 * 1.005) &&
                          (currentPrice < g_CurrentProfile.ema200); // Luôn dưới EMA200
        
        // Kiểm tra thêm % pullback
        if (priceToEma34Percent < MinPullbackPercent || priceToEma34Percent > MaxPullbackPercent) {
            validPullbackZone = false;
        }
    }
    
    if (!validPullbackZone) {
        LogMessage("Pullback bị từ chối: Giá không trong vùng pullback hợp lệ (% pullback: " + 
                 DoubleToString(priceToEma34Percent, 1) + "%)");
        return false;
    }
    
    // Điều kiện 3: Kiểm tra xác nhận momentum
    if (EnableMomentumConfirmation && !IsMomentumConfirmed(isLong)) {
        LogMessage("Pullback bị từ chối: Không có xác nhận momentum");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận momentum                                       |
//+------------------------------------------------------------------+
bool IsMomentumConfirmed(bool isLong) {
    // Lấy giá trị slope của RSI và MACD Histogram
    double rsiSlope = g_CurrentProfile.rsiSlope;
    double macdHistSlope = g_CurrentProfile.macdHistogramSlope;
    double rsiValue = g_CurrentProfile.rsiValue;
    double macdHist = g_CurrentProfile.macdHistogram;
    
    bool momentumConfirmed = false;
    
    if (isLong) {
        // Cho xu hướng tăng, cần RSI slope > 0.25 hoặc MACD Histogram đảo chiều tăng
        bool rsiConfirm = (rsiValue > 45.0 && rsiSlope > 0.25);
        bool macdConfirm = (macdHist > 0 && macdHistSlope > 0) || 
                          (macdHist < 0 && macdHistSlope > 0.1); // Đang tăng từ âm sang
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    } else {
        // Cho xu hướng giảm, cần RSI slope < -0.25 hoặc MACD Histogram đảo chiều giảm
        bool rsiConfirm = (rsiValue < 55.0 && rsiSlope < -0.25);
        bool macdConfirm = (macdHist < 0 && macdHistSlope < 0) || 
                          (macdHist > 0 && macdHistSlope < -0.1); // Đang giảm từ dương xuống
        
        momentumConfirmed = rsiConfirm || macdConfirm;
    }
    
    if (momentumConfirmed) {
        if (isLong) {
            LogMessage("Xác nhận momentum: RSI slope=" + DoubleToString(rsiSlope, 2) + 
                     ", MACD Hist slope=" + DoubleToString(macdHistSlope, 2));
        } else {
            LogMessage("Xác nhận momentum: RSI slope=" + DoubleToString(rsiSlope, 2) + 
                     ", MACD Hist slope=" + DoubleToString(macdHistSlope, 2));
        }
    }
    
    return momentumConfirmed;
}

//+------------------------------------------------------------------+
//| Tính độ dốc RSI                                                  |
//+------------------------------------------------------------------+
double GetRSISlope(int period) {
    // [NEW] Sử dụng cache nếu được bật
    int rsiHandle;
    if (EnableIndicatorCache) {
        rsiHandle = GetIndicatorHandle(0, _Symbol, MainTimeframe); // 0 = RSI
    } else {
        rsiHandle = iRSI(_Symbol, MainTimeframe, period, PRICE_CLOSE);
    }
    
    if (rsiHandle == INVALID_HANDLE) {
        return 0;
    }
    
    double rsiBuffer[];
    ArraySetAsSeries(rsiBuffer, true);
    
    if (CopyBuffer(rsiHandle, 0, 0, 3, rsiBuffer) < 3) {
        if (!EnableIndicatorCache) {
            IndicatorRelease(rsiHandle);
        }
        return 0;
    }
    
    // Tính độ dốc (3 nến gần nhất)
    double slope = (rsiBuffer[0] - rsiBuffer[2]) / 2.0;
    
    if (!EnableIndicatorCache) {
        IndicatorRelease(rsiHandle);
    }
    return slope;
}

//+------------------------------------------------------------------+
//| Tính độ dốc MACD Histogram                                       |
//+------------------------------------------------------------------+
double GetMACDHistogramSlope() {
    // [NEW] Sử dụng cache nếu được bật
    int macdHandle;
    if (EnableIndicatorCache) {
        macdHandle = GetIndicatorHandle(1, _Symbol, MainTimeframe); // 1 = MACD
    } else {
        macdHandle = iMACD(_Symbol, MainTimeframe, 12, 26, 9, PRICE_CLOSE);
    }
    
    if (macdHandle == INVALID_HANDLE) {
        return 0;
    }
    
    double macdBuffer[];
    ArraySetAsSeries(macdBuffer, true);
    
    if (CopyBuffer(macdHandle, 1, 0, 3, macdBuffer) < 3) { // Histogram là buffer thứ 2 (index 1)
        if (!EnableIndicatorCache) {
            IndicatorRelease(macdHandle);
        }
        return 0;
    }
    
    // Tính độ dốc (3 nến gần nhất)
    double slope = (macdBuffer[0] - macdBuffer[2]) / 2.0;
    
    if (!EnableIndicatorCache) {
        IndicatorRelease(macdHandle);
    }
    return slope;
}

//+------------------------------------------------------------------+
//| Kiểm tra xác nhận Price Action                                   |
//+------------------------------------------------------------------+
bool IsPriceActionConfirmed(bool isLong) {
    if (g_PatternDetector == NULL || !EnablePriceAction) return true;
    
    bool priceActionConfirmed = false;
    
    // Kiểm tra các mẫu hình price action
    if (isLong) {
        if (StrictPriceAction) {
            // [UPDATED] Yêu cầu mẫu hình mạnh hơn nếu StrictPriceAction được bật
            priceActionConfirmed = g_PatternDetector.IsBullishEngulfing(1) || 
                                 g_PatternDetector.IsMorningStar(1);
        } else {
            // Xác nhận price action xu hướng tăng bình thường
            priceActionConfirmed = g_PatternDetector.IsBullishEngulfing(1) ||
                                 g_PatternDetector.IsBullishPinbar(1) ||
                                 g_PatternDetector.IsMorningStar(1) ||
                                 g_PatternDetector.IsOutsideBarUp(1);
        }
        
        if (priceActionConfirmed) {
            LogMessage("Xác nhận Price Action: Mẫu hình tăng giá được phát hiện");
        } else {
            LogMessage("Pullback bị từ chối: Không có xác nhận Price Action xu hướng tăng");
        }
    } else {
        if (StrictPriceAction) {
            // [UPDATED] Yêu cầu mẫu hình mạnh hơn nếu StrictPriceAction được bật
            priceActionConfirmed = g_PatternDetector.IsBearishEngulfing(1) ||
                                 g_PatternDetector.IsEveningStar(1);
        } else {
            // Xác nhận price action xu hướng giảm bình thường
            priceActionConfirmed = g_PatternDetector.IsBearishEngulfing(1) ||
                                 g_PatternDetector.IsBearishPinbar(1) ||
                                 g_PatternDetector.IsEveningStar(1) ||
                                 g_PatternDetector.IsOutsideBarDown(1);
        }
        
        if (priceActionConfirmed) {
            LogMessage("Xác nhận Price Action: Mẫu hình giảm giá được phát hiện");
        } else {
            LogMessage("Pullback bị từ chối: Không có xác nhận Price Action xu hướng giảm");
        }
            
            // Ghi log thông tin
            if (EnableDetailedLogs) {
                LogMessage("Kiểm tra cấu trúc swing tăng: Higher Highs = " + (hasHigherHighs ? "true" : "false") + 
                         ", Higher Lows = " + (hasHigherLows ? "true" : "false"));
            }
            
            return hasHigherHighs && hasHigherLows;
        } else {
            // Kiểm tra cấu trúc xu hướng giảm (Lower Highs, Lower Lows)
            bool hasLowerHighs = g_SwingDetector.HasLowerHighs();
            bool hasLowerLows = g_SwingDetector.HasLowerLows();
            
            // Ghi log thông tin
            if (EnableDetailedLogs) {
                LogMessage("Kiểm tra cấu trúc swing giảm: Lower Highs = " + (hasLowerHighs ? "true" : "false") + 
                         ", Lower Lows = " + (hasLowerLows ? "true" : "false"));
            }
            
            return hasLowerHighs && hasLowerLows;
        }
    } catch (Exception e) {
        LogMessage("Lỗi khi kiểm tra cấu trúc swing: " + e.message, true);
        return false; // An toàn khi có lỗi
    }
}
        trailingStop = swingHigh + bufferPoints;
    }
    
    return NormalizeDouble(trailingStop, _Digits);
}

//+------------------------------------------------------------------+
//| Kiểm tra spread chấp nhận được                                  |
//+------------------------------------------------------------------+
bool IsSpreadAcceptable() {
    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    
    // Cập nhật lịch sử spread
    UpdateSpreadHistory();
    
    // Sử dụng ngưỡng spread thích ứng nếu được bật
    double maxSpread = EnableAdaptiveThresholds ? GetAdaptiveMaxSpread() : MaxSpreadPoints;
    
    // Kiểm tra spread hiện tại
    if (currentSpread > maxSpread) {
        LogMessage("Spread hiện tại vượt ngưỡng: " + DoubleToString(currentSpread, 1) + " > " + 
                 DoubleToString(maxSpread, 1) + " điểm");
        return false;
    }
    
    // Kiểm tra spread bất thường (cao hơn 3 lần trung bình)
    if (g_AverageSpread > 0 && currentSpread > g_AverageSpread * 3) {
        LogMessage("Spread bất thường: " + DoubleToString(currentSpread, 1) + " > " + 
                 DoubleToString(g_AverageSpread, 1) + " x 3");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Cập nhật lịch sử spread                                          |
//+------------------------------------------------------------------+
void UpdateSpreadHistory() {
    double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    
    // Cập nhật lịch sử spread
    for (int i = 9; i > 0; i--) {
        g_SpreadHistory[i] = g_SpreadHistory[i-1];
    }
    g_SpreadHistory[0] = currentSpread;
    
    // Tính spread trung bình
    double totalSpread = 0;
    int count = 0;
    for (int i = 0; i < 10; i++) {
        if (g_SpreadHistory[i] > 0) {
            totalSpread += g_SpreadHistory[i];
            count++;
        }
    }
    
    if (count > 0) {
        g_AverageSpread = totalSpread / count;
    }
}

//+------------------------------------------------------------------+
//| Tính ngưỡng spread tối đa thích ứng                              |
//+------------------------------------------------------------------+
double GetAdaptiveMaxSpread() {
    if (g_AverageSpread <= 0) {
        return MaxSpreadPoints; // Fallback nếu không có dữ liệu
    }
    
    // Tính ngưỡng spread thích ứng
    double adaptiveMaxSpread = g_AverageSpread * 2.0; // Mặc định 2 lần trung bình
    
    // Điều chỉnh theo ATR nếu có
    if (g_AverageATR > 0 && g_CurrentProfile.atrCurrent > 0) {
        double atrRatio = g_CurrentProfile.atrCurrent / g_AverageATR;
        
        // Cho phép spread cao hơn khi biến động cao hơn
        if (atrRatio > 1.0) {
            adaptiveMaxSpread *= MathMin(1.5, atrRatio);
        }
    }
    
    // Giới hạn ngưỡng thích ứng
    adaptiveMaxSpread = MathMin(adaptiveMaxSpread, MaxSpreadPoints * 1.5);
    adaptiveMaxSpread = MathMax(adaptiveMaxSpread, MaxSpreadPoints * 0.5);
    
    return NormalizeDouble(adaptiveMaxSpread, 1);
}

//+------------------------------------------------------------------+
//| [NEW] Tính ngưỡng volatility thích ứng                          |
//+------------------------------------------------------------------+
double GetAdaptiveVolatilityThreshold() {
    // Base threshold from input
    double threshold = VolatilityThreshold;
    
    // Adjust based on market regime
    if (g_CurrentProfile.regime == REGIME_VOLATILE) {
        // Allow higher volatility in volatile markets
        threshold *= 1.5;
    } else if (g_CurrentProfile.regime == REGIME_RANGING) {
        // Be more sensitive to volatility in ranging markets
        threshold *= 0.8;
    }
    
    // Adjust based on session
    if (g_CurrentProfile.currentSession == SESSION_ASIAN) {
        // Asian session typically has lower volatility
        threshold *= 0.9;
    } else if (g_CurrentProfile.currentSession == SESSION_LONDON || 
              g_CurrentProfile.currentSession == SESSION_NEWYORK) {
        // Major sessions can handle more volatility
        threshold *= 1.2;
    }
    
    return threshold;
}

//+------------------------------------------------------------------+
//| Kiểm tra biến động chấp nhận được                               |
//+------------------------------------------------------------------+
bool IsVolatilityAcceptable() {
    if (g_MarketProfile == NULL || g_AverageATR <= 0 || SkipVolatilityCheck) return true;
    
    double currentATR = g_MarketProfile.GetATR();
    double volatilityThreshold = GetAdaptiveVolatilityThreshold();
    double volatilityRatio = currentATR / g_AverageATR;
    
    if (volatilityRatio > volatilityThreshold) {
        LogMessage("Biến động quá cao: " + DoubleToString(volatilityRatio, 2) + 
                 "x > " + DoubleToString(volatilityThreshold, 2) + "x ATR trung bình");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra thời gian tin tức                                      |
//+------------------------------------------------------------------+
bool IsNewsTimeFilter() {
    if (NewsFilter == NEWS_NONE || g_NewsFilter == NULL) return false;
    
    return g_NewsFilter.IsInNewsWindow();
}

//+------------------------------------------------------------------+
//| Kiểm tra phiên giao dịch                                        |
//+------------------------------------------------------------------+
bool IsSessionActive() {
    if (!FilterBySession || g_SessionManager == NULL) return true;
    
    return g_SessionManager.IsSessionActive();
}

//+------------------------------------------------------------------+
//| Cập nhật thống kê hàng ngày                                     |
//+------------------------------------------------------------------+
void UpdateDailyStats() {
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    // Kiểm tra nếu ngày mới
    if (time.day != g_CurrentDay) {
        // Lưu thông tin ngày mới
        g_CurrentDay = time.day;
        g_DayStartEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        g_DayTrades = 0;
        
        // Reset các thống kê hàng ngày
        if (g_RiskManager != NULL) {
            g_RiskManager.ResetDailyStats();
        }
        
// [NEW] Cập nhật lại spread và ATR history mỗi ngày
        UpdateAtrHistory();
        UpdateSpreadHistory();
        
        LogMessage("Phát hiện ngày mới, đặt lại thống kê hàng ngày", true);
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra bảo vệ drawdown                                        |
//+------------------------------------------------------------------+
void CheckDrawdownProtection() {
    if (!EnableAutoPause || g_RiskManager == NULL) return;
    
    double currentDD = g_RiskManager.GetCurrentDrawdown();
    
    if (currentDD >= DrawdownPauseThreshold) {
        g_CurrentState = STATE_PAUSED;
        g_PauseEndTime = TimeCurrent() + PauseDurationMinutes * 60;
        
        string ddMsg = StringFormat("EA tự động tạm dừng do Drawdown: %.2f%% vượt ngưỡng %.2f%%. Tiếp tục sau: %s",
                                currentDD, DrawdownPauseThreshold, 
                                TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES));
        
        LogMessage(ddMsg, true);
        SendAlert(ddMsg, true);
        
        // Gửi thông báo Telegram riêng cho rủi ro nếu được bật
        if (EnableRiskEventNotify && EnableTelegramNotify && g_Logger != NULL) {
            string riskMsg = "⚠️ CẢNH BÁO DRAWDOWN: " + DoubleToString(currentDD, 2) + 
                          "% vượt ngưỡng " + DoubleToString(DrawdownPauseThreshold, 2) + 
                          "%! EA tạm dừng đến " + TimeToString(g_PauseEndTime, TIME_DATE|TIME_MINUTES);
            g_Logger.SendTelegramMessage(riskMsg);
        }
        
        UpdateEAState();
    }
}

//+------------------------------------------------------------------+
//| Lấy giá trị ATR trung bình                                      |
//+------------------------------------------------------------------+
double GetAverageATR() {
    if (g_AverageATR > 0) return g_AverageATR;
    
    // Tính ATR trung bình từ dữ liệu
    int atrHandle;
    if (EnableIndicatorCache) {
        atrHandle = GetIndicatorHandle(2, _Symbol, PERIOD_D1); // 2 = ATR
    } else {
        atrHandle = iATR(_Symbol, PERIOD_D1, 14);
    }
    
    if (atrHandle == INVALID_HANDLE) {
        return 0;
    }
    
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if (CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) <= 0) {
        if (!EnableIndicatorCache) {
            IndicatorRelease(atrHandle);
        }
        return 0;
    }
    
    // Tính trung bình
    double avgATR = 0;
    for (int i = 0; i < 20; i++) {
        avgATR += atrBuffer[i];
    }
    avgATR /= 20;
    
    if (!EnableIndicatorCache) {
        IndicatorRelease(atrHandle);
    }
    return avgATR;
}

//+------------------------------------------------------------------+
//| Cập nhật lịch sử ATR                                            |
//+------------------------------------------------------------------+
void UpdateAtrHistory() {
    // Tính ATR trung bình mới
    double newAverageATR = GetAverageATR();
    
    if (newAverageATR > 0) {
        // Cập nhật giá trị mới
        g_AverageATR = newAverageATR;
        LogMessage("Cập nhật ATR trung bình: " + DoubleToString(g_AverageATR, _Digits));
    }
}

//+------------------------------------------------------------------+
//| Ghi log message                                                  |
//+------------------------------------------------------------------+
void LogMessage(string message, bool important) {
    if (g_Logger != NULL) {
        if (important) {
            g_Logger.LogInfo(message);
        } else {
            if (EnableDetailedLogs) {
                g_Logger.LogDebug(message);
            }
        }
    } else {
        // Fallback nếu logger chưa khởi tạo
        if (important || EnableDetailedLogs) {
            Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [APEX] " + message);
        }
    }
}

//+------------------------------------------------------------------+
//| Gửi cảnh báo/thông báo                                         |
//+------------------------------------------------------------------+
void SendAlert(string message, bool isImportant) {
    // Ghi log luôn
    LogMessage(message, isImportant);
    
    // Nếu cảnh báo bị tắt, return
    if (!AlertsEnabled) return;
    
    // Alert trong terminal
    if (isImportant) {
        Alert("APEX: " + message);
    }
    
    // Push notification
    if (SendNotifications && isImportant) {
        SendNotification("APEX: " + message);
    }
    
    // Email
    if (SendEmailAlerts && isImportant) {
        SendMail("APEX Pullback EA v15.0 - " + _Symbol, message);
    }
    
    // Telegram
    if (EnableTelegramNotify && g_Logger != NULL && 
       (!TelegramImportantOnly || isImportant)) {
        g_Logger.SendTelegramMessage(message);
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra nến mới                                               |
//+------------------------------------------------------------------+
bool IsNewBar() {
    static datetime last_time = 0;
    datetime current_time = iTime(_Symbol, MainTimeframe, 0);
    
    if (last_time == 0) {
        last_time = current_time;
        return false;
    }
    
    if (current_time != last_time) {
        last_time = current_time;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cập nhật Dashboard                                              |
//+------------------------------------------------------------------+
void UpdateDashboard() {
    if (g_Dashboard == NULL || !DisplayDashboard) return;
    
    // Cập nhật dashboard
    g_Dashboard.Update(g_CurrentProfile);
}

//+------------------------------------------------------------------+
//| Chuyển đổi timeframe sang chuỗi                                 |
//+------------------------------------------------------------------+
string TimeframeToString(ENUM_TIMEFRAMES tf) {
    switch (tf) {
        case PERIOD_M1:  return "M1";
        case PERIOD_M5:  return "M5";
        case PERIOD_M15: return "M15";
        case PERIOD_M30: return "M30";
        case PERIOD_H1:  return "H1";
        case PERIOD_H4:  return "H4";
        case PERIOD_D1:  return "D1";
        case PERIOD_W1:  return "W1";
        case PERIOD_MN1: return "MN";
        default:         return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Lấy mô tả lý do kết thúc                                        |
//+------------------------------------------------------------------+
string GetDeinitReasonText(const int reason) {
    switch (reason) {
        case REASON_PROGRAM:     return "EA tự kết thúc";
        case REASON_REMOVE:      return "EA bị xóa khỏi biểu đồ";
        case REASON_RECOMPILE:   return "EA được biên dịch lại";
        case REASON_CHARTCHANGE: return "Symbol hoặc khung thời gian đã thay đổi";
        case REASON_CHARTCLOSE:  return "Biểu đồ đã đóng";
        case REASON_PARAMETERS:  return "Tham số input đã thay đổi";
        case REASON_ACCOUNT:     return "Tài khoản thay đổi hoặc kết nối lại";
        case REASON_TEMPLATE:    return "Áp dụng template mới";
        case REASON_INITFAILED:  return "OnInit() thất bại";
        case REASON_CLOSE:       return "Terminal đã đóng";
        default:                 return "Lý do không xác định (" + IntegerToString(reason) + ")";
    }
}

//+------------------------------------------------------------------+
//| [NEW] Kiểm tra thời gian cập nhật tính toán                     |
//+------------------------------------------------------------------+
bool ShouldUpdateCalculations(datetime lastUpdateTime) {
    datetime currentTime = TimeCurrent();
    return currentTime - lastUpdateTime > 300; // 5 phút
}

//+------------------------------------------------------------------+
//| [NEW] Khởi tạo cache chỉ báo                                    |
//+------------------------------------------------------------------+
void InitializeIndicatorCache() {
    if (!EnableIndicatorCache) return;
    
    for (int i = 0; i < 10; i++) {
        g_IndicatorCache[i] = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| [NEW] Xóa cache chỉ báo                                         |
//+------------------------------------------------------------------+
void ClearIndicatorCache() {
    if (!EnableIndicatorCache) return;
    
    for (int i = 0; i < 10; i++) {
        if (g_IndicatorCache[i] != INVALID_HANDLE) {
            IndicatorRelease(g_IndicatorCache[i]);
            g_IndicatorCache[i] = INVALID_HANDLE;
        }
    }
}

//+------------------------------------------------------------------+
//| [NEW] Lấy handle chỉ báo từ cache                               |
//+------------------------------------------------------------------+
int GetIndicatorHandle(int indicatorType, string symbol, ENUM_TIMEFRAMES timeframe) {
    if (!EnableIndicatorCache) {
        // Không sử dụng cache, tạo mới mỗi lần
        switch (indicatorType) {
            case 0: // RSI
                return iRSI(symbol, timeframe, 14, PRICE_CLOSE);
            case 1: // MACD
                return iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE);
            case 2: // ATR
                return iATR(symbol, timeframe, 14);
            default:
                return INVALID_HANDLE;
        }
    }
    
    // Sử dụng cache
    if (g_IndicatorCache[indicatorType] == INVALID_HANDLE) {
        switch (indicatorType) {
            case 0: // RSI
                g_IndicatorCache[indicatorType] = iRSI(symbol, timeframe, 14, PRICE_CLOSE);
                break;
            case 1: // MACD
                g_IndicatorCache[indicatorType] = iMACD(symbol, timeframe, 12, 26, 9, PRICE_CLOSE);
                break;
            case 2: // ATR
                g_IndicatorCache[indicatorType] = iATR(symbol, timeframe, 14);
                break;
            default:
                return INVALID_HANDLE;
        }
    }
    
    return g_IndicatorCache[indicatorType];
}

//+------------------------------------------------------------------+
//| Nạp cấu hình                                                    |
//+------------------------------------------------------------------+
bool LoadConfiguration() {
    string filename = "ApexPullback_" + _Symbol + ".conf";
    
    if (!FileIsExist(filename, FILE_COMMON)) {
        LogMessage("Không tìm thấy file cấu hình: " + filename);
        return false;
    }
    
    int fileHandle = FileOpen(filename, FILE_READ|FILE_TXT|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogMessage("Không thể mở file cấu hình: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Đọc từng dòng cấu hình
    while (!FileIsEnding(fileHandle)) {
        string line = FileReadString(fileHandle);
        
        // Bỏ qua dòng trống hoặc comment
        if (StringLen(line) == 0 || StringGetCharacter(line, 0) == '#') {
            continue;
        }
        
        // Tách key=value
        string parts[];
        if (StringSplit(line, '=', parts) == 2) {
            string key = StringTrimRight(StringTrimLeft(parts[0]));
            string value = StringTrimRight(StringTrimLeft(parts[1]));
            
            // Xử lý các tham số
            if (key == "RiskPercent") {
                RiskPercent = StringToDouble(value);
            }
            else if (key == "MaxDrawdown") {
                MaxDrawdown = StringToDouble(value);
            }
            else if (key == "DailyLossLimit") {
                DailyLossLimit = StringToDouble(value);
            }
            else if (key == "SL_ATR") {
                SL_ATR = StringToDouble(value);
            }
            else if (key == "TP_RR") {
                TP_RR = StringToDouble(value);
            }
            else if (key == "MinAdxValue") {
                MinAdxValue = StringToDouble(value);
            }
            else if (key == "StrictPriceAction") {
                StrictPriceAction = (StringCompare(value, "true") == 0 || StringToInteger(value) == 1);
            }
            else if (key == "RequireSwingStructure") {
                RequireSwingStructure = (StringCompare(value, "true") == 0 || StringToInteger(value) == 1);
            }
            // Thêm các tham số khác nếu cần
        }
    }
    
    FileClose(fileHandle);
    LogMessage("Đã nạp cấu hình từ file: " + filename);
    return true;
}

//+------------------------------------------------------------------+
//| Lưu cấu hình                                                    |
//+------------------------------------------------------------------+
void SaveConfiguration() {
    string filename = "ApexPullback_" + _Symbol + ".conf";
    
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_TXT|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogMessage("Không thể tạo file cấu hình: " + IntegerToString(GetLastError()), true);
        return;
    }
    
    // Thông tin file
    FileWriteString(fileHandle, "# APEX Pullback EA v15.0 Configuration\n");
    FileWriteString(fileHandle, "# Last Updated: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "\n\n");
    
    // Lưu các tham số
    FileWriteString(fileHandle, "RiskPercent=" + DoubleToString(RiskPercent, 2) + "\n");
    FileWriteString(fileHandle, "MaxDrawdown=" + DoubleToString(MaxDrawdown, 2) + "\n");
    FileWriteString(fileHandle, "DailyLossLimit=" + DoubleToString(DailyLossLimit, 2) + "\n");
    FileWriteString(fileHandle, "SL_ATR=" + DoubleToString(SL_ATR, 2) + "\n");
    FileWriteString(fileHandle, "TP_RR=" + DoubleToString(TP_RR, 2) + "\n");
    FileWriteString(fileHandle, "StrictPriceAction=" + (StrictPriceAction ? "true" : "false") + "\n");
    FileWriteString(fileHandle, "RequireSwingStructure=" + (RequireSwingStructure ? "true" : "false") + "\n");
    
    // Thống kê
    if (SaveStatistics) {
        FileWriteString(fileHandle, "\n# Statistics\n");
        FileWriteString(fileHandle, "TotalTrades=" + IntegerToString(g_DayTrades) + "\n");
        FileWriteString(fileHandle, "ConsecutiveLosses=" + IntegerToString(g_ConsecutiveLosses) + "\n");
        
        // Thêm thông tin Asset Profile nếu có
        if (EnableAssetProfile && g_AssetProfiler != NULL) {
            string profileStats = g_AssetProfiler.GetProfileStats();
            FileWriteString(fileHandle, "\n# Asset Profile\n");
            FileWriteString(fileHandle, profileStats);
        }
    }
    
    FileClose(fileHandle);
    LogMessage("Đã lưu cấu hình vào file: " + filename);
}

//+------------------------------------------------------------------+
//| End of APEX Pullback EA v15.0                                    |
//+------------------------------------------------------------------+

 // Kết thúc namespace ApexPullback