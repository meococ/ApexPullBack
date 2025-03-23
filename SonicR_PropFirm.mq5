//+------------------------------------------------------------------+
//|                                             SonicR_PropFirm.mq5 |
//|                         SonicR PropFirm EA - Tối ưu cho PropFirm |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"
#property version   "1.61"
#property strict
#property description "SonicR PropFirm EA - Hệ thống giao dịch SonicR được tối ưu hóa cho các thử thách PropFirm"

// Đã cập nhật version 1.61 - Ngày: 28/11/2023
// Định nghĩa các enum trước khi include
enum ENUM_PROP_FIRM
{
    PROP_FIRM_FTMO,        // FTMO
    PROP_FIRM_THE5ERS,     // The5ers
    PROP_FIRM_E8,          // E8 Funding
    PROP_FIRM_MYFOREX,     // MyForexFunds
    PROP_FIRM_CUSTOM       // Tùy chỉnh
};

enum ENUM_CHALLENGE_PHASE
{
    PHASE_CHALLENGE,       // Giai đoạn Challenge
    PHASE_VERIFICATION,    // Giai đoạn Verification
    PHASE_FUNDED           // Tài khoản Funded
};

enum ENUM_EA_STATE
{
    STATE_INITIALIZING,    // Đang khởi tạo
    STATE_SCANNING,        // Đang quét tín hiệu
    STATE_WAITING,         // Phát hiện tín hiệu, đang chờ điều kiện vào lệnh
    STATE_EXECUTING,       // Đang thực thi lệnh
    STATE_MONITORING,      // Đang giám sát vị thế mở
    STATE_STOPPED          // EA đã dừng (khẩn cấp, lỗi, v.v.)
};

// Trading library mặc định của MT5
#include <Trade\Trade.mqh>

// Forward declarations của các class - Giúp tránh lỗi khi include
class CSonicCore;
class CRiskManager;
class CEntryManager;
class CExitManager;
class CStateMachine;
class CSessionFilter;
class CNewsFilter;
class CMarketRegimeFilter;
class CLogger;
class CDashboard;
class CPropSettings;

// Tham số đầu vào
// --- Cài đặt chung ---
input string GeneralSettings = "===== Cài đặt chung =====";
input string EAName = "SonicR PropFirm";
input int MagicNumber = 234567;
input bool UseVirtualSL = true;                // Sử dụng SL ảo
input bool DisplayDashboard = true;            // Hiển thị dashboard
input int MaxRetryAttempts = 3;                // Số lần thử lại tối đa
input int RetryDelayMs = 200;                  // Độ trễ giữa các lần thử (ms)
input bool EnableDetailedLogging = true;       // Ghi log chi tiết

// --- Cài đặt PropFirm ---
input string PropFirmSettings = "===== Cài đặt PropFirm =====";
input ENUM_PROP_FIRM PropFirmType = PROP_FIRM_FTMO;
input ENUM_CHALLENGE_PHASE ChallengePhase = PHASE_CHALLENGE;
input bool AutoDetectPhase = true;             // Tự động phát hiện giai đoạn
input double CustomTargetProfit = 10.0;        // Mục tiêu lợi nhuận tùy chỉnh (%)
input double CustomMaxDrawdown = 10.0;         // Drawdown tối đa tùy chỉnh (%)
input double CustomDailyDrawdown = 5.0;        // Daily drawdown tùy chỉnh (%)

// --- Cài đặt quản lý rủi ro ---
input string RiskSettings = "===== Quản lý rủi ro =====";
input double RiskPercent = 0.5;                // Phần trăm rủi ro
input double MaxDailyDD = 3.0;                 // Drawdown tối đa trong ngày
input double MaxTotalDD = 5.0;                 // Drawdown tối đa tổng thể
input int MaxTradesPerDay = 3;                 // Số lệnh tối đa mỗi ngày
input int SlippagePoints = 5;                  // Slippage (điểm)

// --- Bộ lọc phiên ---
input string SessionSettings = "===== Bộ lọc phiên giao dịch =====";
input bool EnableLondonSession = true;         // Cho phép phiên London
input bool EnableNewYorkSession = true;        // Cho phép phiên New York
input bool EnableLondonNYOverlap = true;       // Cho phép phiên chồng London-NY
input bool EnableAsianSession = false;         // Cho phép phiên Á
input int FridayEndHour = 16;                  // Giờ kết thúc thứ 6 (GMT)
input bool AllowMondayTrading = true;          // Cho phép giao dịch thứ 2
input bool AllowFridayTrading = true;          // Cho phép giao dịch thứ 6
input double SessionQualityThreshold = 60.0;   // Ngưỡng chất lượng phiên (0-100)

// --- Cài đặt thoát lệnh ---
input string ExitSettings = "===== Quản lý thoát lệnh =====";
input bool UsePartialClose = true;             // Sử dụng đóng một phần
input double TP1Percent = 50.0;                // Phần trăm đóng tại TP1
input double TP1Distance = 1.5;                // Khoảng cách TP1 (x SL)
input double TP2Distance = 2.5;                // Khoảng cách TP2 (x SL)
input bool UseBreakEven = true;                // Sử dụng break-even
input double BreakEvenTrigger = 0.7;           // Điểm kích hoạt break-even (x SL)
input double BreakEvenOffset = 5.0;            // Offset break-even (điểm)
input bool UseTrailing = true;                 // Sử dụng trailing stop
input double TrailingStart = 1.5;              // Điểm bắt đầu trailing (x SL)
input double TrailingStep = 15.0;              // Bước trailing (điểm)
input bool UseAdaptiveTrailing = true;         // Sử dụng thuật toán trailing thích ứng

// --- Cài đặt tín hiệu ---
input string SignalSettings = "===== Cài đặt tín hiệu giao dịch =====";
input double MinRR = 1.5;                      // R:R tối thiểu
input double MinSignalQuality = 70.0;          // Chất lượng tín hiệu tối thiểu

// --- Bộ lọc tin tức ---
input string NewsSettings = "===== Bộ lọc tin tức =====";
input bool UseNewsFilter = true;               // Sử dụng bộ lọc tin tức
input int NewsMinutesBefore = 30;              // Phút trước tin tức
input int NewsMinutesAfter = 15;               // Phút sau tin tức
input bool HighImpactOnly = true;              // Chỉ lọc tin tức tác động cao

// --- Bộ lọc chế độ thị trường ---
input string MarketRegimeSettings = "===== Bộ lọc chế độ thị trường =====";
input bool UseMarketRegimeFilter = true;       // Sử dụng bộ lọc chế độ thị trường
input bool TradeBullishRegime = true;          // Giao dịch trong xu hướng tăng
input bool TradeBearishRegime = true;          // Giao dịch trong xu hướng giảm
input bool TradeRangingRegime = true;          // Giao dịch trong thị trường tích lũy
input bool TradeVolatileRegime = false;        // Giao dịch trong thị trường biến động

// Triển khai class cơ bản (để tránh lỗi compile trước khi tất cả các file được tích hợp)
// Logger class
class CLogger {
public:
    CLogger(string name, int magic, bool detailed = false) {}
    void Info(string message) { Print("INFO: ", message); }
    void Warning(string message) { Print("WARNING: ", message); }
    void Error(string message) { Print("ERROR: ", message); }
};

// SonicCore class
class CSonicCore {
public:
    CSonicCore() {}
    bool Initialize() { return true; }
    void Update() {}
    bool AreHandlesValid() { return true; }
    int DetectClassicSetup() { return 0; }
    int DetectScoutSetup() { return 0; }
    bool IsPVSRAConfirming(int direction) { return true; }
    bool IsPullbackValid(int direction) { return true; }
};

// RiskManager class
class CRiskManager {
public:
    CRiskManager(double risk, double dailyDD, double totalDD, int maxTrades) {}
    void Update() {}
    bool IsTradeAllowed() { return true; }
    bool IsInEmergencyMode() { return false; }
    double GetRiskPercent() { return 0.5; }
};

// EntryManager class
class CEntryManager {
public:
    CEntryManager(CSonicCore* core, CRiskManager* risk, CTrade* trade) {}
    void SetMinRR(double value) {}
    void SetMinSignalQuality(double value) {}
    void SetRetrySettings(int attempts, int delay) {}
    int CheckForSignal() { return 0; }
    bool PrepareEntry(int signal) { return false; }
    bool ExecuteTrade() { return false; }
    int GetCurrentSignal() { return 0; }
    double GetSignalQuality() { return 0.0; }
};

// ExitManager class
class CExitManager {
public:
    CExitManager(bool partialClose, double tp1Percent, double tp1Dist, double tp2Dist,
                bool useBreakEven, double beTrigger, double beOffset,
                bool useTrailing, double trailingStart, double trailingStep, bool adaptive) {}
    void SetMagicNumber(int magic) {}
    void SetSlippage(int points) {}
    void SetUseVirtualSL(bool virtual_sl) {}
    void Update() {}
    void ManageExits() {}
};

// StateMachine class
class CStateMachine {
public:
    CStateMachine() {}
    void Update() {}
    void TransitionTo(ENUM_EA_STATE state, string reason) {}
    ENUM_EA_STATE GetCurrentState() { return STATE_INITIALIZING; }
};

// SessionFilter class
class CSessionFilter {
public:
    CSessionFilter(bool london, bool newyork, bool overlap, bool asian,
                  int fridayEnd, bool monday, bool friday) {}
    void SetQualityThreshold(double threshold) {}
    bool IsTradingAllowed() { return true; }
};

// NewsFilter class
class CNewsFilter {
public:
    CNewsFilter(bool use, int before, int after, bool highImpact) {}
    bool IsNewsTime() { return false; }
};

// MarketRegimeFilter class
class CMarketRegimeFilter {
public:
    CMarketRegimeFilter() {}
    void Configure(bool use, bool bull, bool bear, bool ranging, bool volatile_market) {}
    void Update(CSonicCore* core) {}
    bool IsRegimeFavorable() { return true; }
    string GetCurrentRegimeAsString() { return "Bullish"; }
};

// Dashboard class
class CDashboard {
public:
    CDashboard() {}
    void SetDependencies(CSonicCore* core, CRiskManager* risk, CStateMachine* state, CPropSettings* prop) {}
    void Create() {}
    void Update() {}
    void Remove() {}
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam) {}
};

// PropSettings class
class CPropSettings {
public:
    CPropSettings(ENUM_PROP_FIRM firm, ENUM_CHALLENGE_PHASE phase) {}
    void SetCustomValues(double target, double maxDD, double dailyDD) {}
    void Update() {}
    ENUM_CHALLENGE_PHASE AutoDetectPhase() { return PHASE_CHALLENGE; }
    void SetPhase(ENUM_CHALLENGE_PHASE phase) {}
    ENUM_CHALLENGE_PHASE GetPhase() { return PHASE_CHALLENGE; }
    ENUM_PROP_FIRM GetPropFirm() { return PROP_FIRM_FTMO; }
};

// Biến toàn cục
CLogger* g_logger = NULL;
CSonicCore* g_sonicCore = NULL;
CRiskManager* g_riskManager = NULL;
CEntryManager* g_entryManager = NULL;
CExitManager* g_exitManager = NULL;
CStateMachine* g_stateMachine = NULL;
CSessionFilter* g_sessionFilter = NULL;
CNewsFilter* g_newsFilter = NULL;
CMarketRegimeFilter* g_marketRegimeFilter = NULL;
CDashboard* g_dashboard = NULL;
CPropSettings* g_propSettings = NULL;
CTrade* g_trade = NULL;

// Biến trạng thái
bool g_shutdownRequested = false;
bool g_initialized = false;
datetime g_lastMarketRegimeCheck = 0;
int g_successfulTrades = 0;
int g_failedTrades = 0;
double g_totalProfit = 0.0;
double g_totalLoss = 0.0;
double g_backtestScore = 0.0;  // Tổng số điểm đánh giá backtest

// SafeDelete - sửa lỗi với template function
void SafeDelete(CLogger* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CSonicCore* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CRiskManager* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CEntryManager* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CExitManager* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CStateMachine* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CSessionFilter* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CNewsFilter* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CMarketRegimeFilter* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CDashboard* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CPropSettings* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

void SafeDelete(CTrade* &pointer) {
    if(pointer != NULL) {
        delete pointer;
        pointer = NULL;
    }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                  |
//+------------------------------------------------------------------+
int OnInit()
{
    // Validation của input parameters
    if(RiskPercent <= 0 || RiskPercent > 5) {
        Print("ERROR: RiskPercent không hợp lệ (", RiskPercent, "). Phải > 0 và <= 5.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(MaxDailyDD <= 0 || MaxDailyDD > 10) {
        Print("ERROR: MaxDailyDD không hợp lệ (", MaxDailyDD, "). Phải > 0 và <= 10.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    if(MaxTotalDD <= 0 || MaxTotalDD > 20) {
        Print("ERROR: MaxTotalDD không hợp lệ (", MaxTotalDD, "). Phải > 0 và <= 20.");
        return INIT_PARAMETERS_INCORRECT;
    }
    
    // Khởi tạo logger
    g_logger = new CLogger(EAName, MagicNumber, EnableDetailedLogging);
    if(g_logger == NULL) {
        Print("ERROR: Không thể khởi tạo Logger. Không đủ bộ nhớ?");
        return INIT_FAILED;
    }
    
    g_logger.Info("Đang khởi tạo SonicR PropFirm EA v1.61...");
    
    // Khởi tạo đối tượng giao dịch
    g_trade = new CTrade();
    if(g_trade == NULL) {
        g_logger.Error("Không thể khởi tạo Trade object");
        return INIT_FAILED;
    }
    
    g_trade.SetExpertMagicNumber(MagicNumber);
    g_trade.SetDeviationInPoints(SlippagePoints);
    
    // Khởi tạo SonicCore
    g_sonicCore = new CSonicCore();
    if(g_sonicCore == NULL) {
        g_logger.Error("Không thể khởi tạo SonicCore");
        return INIT_FAILED;
    }
    
    if(!g_sonicCore.Initialize()) {
        g_logger.Error("Không thể khởi tạo SonicCore indicators");
        return INIT_FAILED;
    }
    
    // Khởi tạo các thành phần chính với kiểm tra lỗi
    g_riskManager = new CRiskManager(RiskPercent, MaxDailyDD, MaxTotalDD, MaxTradesPerDay);
    if(g_riskManager == NULL) {
        g_logger.Error("Không thể khởi tạo RiskManager");
        return INIT_FAILED;
    }
    
    g_stateMachine = new CStateMachine();
    if(g_stateMachine == NULL) {
        g_logger.Error("Không thể khởi tạo StateMachine");
        return INIT_FAILED;
    }
    
    g_propSettings = new CPropSettings(PropFirmType, ChallengePhase);
    if(g_propSettings == NULL) {
        g_logger.Error("Không thể khởi tạo PropSettings");
        return INIT_FAILED;
    }
    
    if(PropFirmType == PROP_FIRM_CUSTOM) {
        g_propSettings.SetCustomValues(CustomTargetProfit, CustomMaxDrawdown, CustomDailyDrawdown);
    }
    
    // Khởi tạo EntryManager
    g_entryManager = new CEntryManager(g_sonicCore, g_riskManager, g_trade);
    if(g_entryManager == NULL) {
        g_logger.Error("Không thể khởi tạo EntryManager");
        return INIT_FAILED;
    }
    
    g_entryManager.SetMinRR(MinRR);
    g_entryManager.SetMinSignalQuality(MinSignalQuality);
    g_entryManager.SetRetrySettings(MaxRetryAttempts, RetryDelayMs);
    
    // Khởi tạo ExitManager
    g_exitManager = new CExitManager(
        UsePartialClose, TP1Percent, TP1Distance, TP2Distance, 
        UseBreakEven, BreakEvenTrigger, BreakEvenOffset, 
        UseTrailing, TrailingStart, TrailingStep, UseAdaptiveTrailing
    );
    
    if(g_exitManager == NULL) {
        g_logger.Error("Không thể khởi tạo ExitManager");
        return INIT_FAILED;
    }
    
    g_exitManager.SetMagicNumber(MagicNumber);
    g_exitManager.SetSlippage(SlippagePoints);
    g_exitManager.SetUseVirtualSL(UseVirtualSL);
    
    // Khởi tạo bộ lọc
    g_sessionFilter = new CSessionFilter(
        EnableLondonSession, EnableNewYorkSession, 
        EnableLondonNYOverlap, EnableAsianSession,
        FridayEndHour, AllowMondayTrading, AllowFridayTrading
    );
    
    if(g_sessionFilter == NULL) {
        g_logger.Error("Không thể khởi tạo SessionFilter");
        return INIT_FAILED;
    }
    
    g_sessionFilter.SetQualityThreshold(SessionQualityThreshold);
    
    g_newsFilter = new CNewsFilter(UseNewsFilter, NewsMinutesBefore, NewsMinutesAfter, HighImpactOnly);
    if(g_newsFilter == NULL) {
        g_logger.Error("Không thể khởi tạo NewsFilter");
        return INIT_FAILED;
    }
    
    g_marketRegimeFilter = new CMarketRegimeFilter();
    if(g_marketRegimeFilter == NULL) {
        g_logger.Error("Không thể khởi tạo MarketRegimeFilter");
        return INIT_FAILED;
    }
    
    g_marketRegimeFilter.Configure(
        UseMarketRegimeFilter, 
        TradeBullishRegime, TradeBearishRegime, 
        TradeRangingRegime, TradeVolatileRegime
    );
    
    // Khởi tạo Dashboard nếu cần
    if(DisplayDashboard) {
        g_dashboard = new CDashboard();
        if(g_dashboard == NULL) {
            g_logger.Warning("Không thể khởi tạo Dashboard. Tiếp tục mà không có Dashboard.");
        }
        else {
            g_dashboard.SetDependencies(g_sonicCore, g_riskManager, g_stateMachine, g_propSettings);
            g_dashboard.Create();
        }
    }
    
    // Áp dụng cài đặt PropFirm
    g_propSettings.Update();
    
    // Tự động phát hiện giai đoạn nếu được yêu cầu
    if(AutoDetectPhase) {
        ENUM_CHALLENGE_PHASE detectedPhase = g_propSettings.AutoDetectPhase();
        if(detectedPhase != ChallengePhase) {
            g_logger.Warning("Giai đoạn tự động phát hiện " + EnumToString(detectedPhase) + 
                           " khác với tham số đầu vào " + EnumToString(ChallengePhase));
            g_propSettings.SetPhase(detectedPhase);
        }
    }
    
    // Ghi log hoàn thành khởi tạo
    g_logger.Info("Khởi tạo hoàn tất. Đang chạy ở giai đoạn " + EnumToString(g_propSettings.GetPhase()) + 
                " cho " + EnumToString(g_propSettings.GetPropFirm()));
    
    g_initialized = true;
    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Ghi log dừng
    if(g_logger != NULL) {
        g_logger.Info("Đang dừng SonicR PropFirm EA. Lý do: " + IntegerToString(reason));
    }
    
    // Xóa dashboard nếu tồn tại
    if(g_dashboard != NULL) {
        g_dashboard.Remove();
    }
    
    // Giải phóng tài nguyên sử dụng SafeDelete functions riêng
    SafeDelete(g_dashboard);
    SafeDelete(g_marketRegimeFilter);
    SafeDelete(g_newsFilter);
    SafeDelete(g_sessionFilter);
    SafeDelete(g_exitManager);
    SafeDelete(g_entryManager);
    SafeDelete(g_propSettings);
    SafeDelete(g_stateMachine);
    SafeDelete(g_riskManager);
    SafeDelete(g_sonicCore);
    SafeDelete(g_trade);
    SafeDelete(g_logger);
    
    // Xóa đối tượng chart
    ObjectsDeleteAll(0, "SonicR_");
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    // Kiểm tra yêu cầu dừng
    if(g_shutdownRequested || !g_initialized) {
        return;
    }
    
    // Kiểm tra nếu nến mới đã mở
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != lastBarTime);
    
    if(isNewBar) {
        lastBarTime = currentBarTime;
        // Ghi log nến mới cho debug
        g_logger.Info("Nến mới mở tại " + TimeToString(currentBarTime));
        
        // Cập nhật bộ lọc chế độ thị trường theo nến
        if(TimeCurrent() - g_lastMarketRegimeCheck >= 3600) { // Cập nhật mỗi giờ
            g_marketRegimeFilter.Update(g_sonicCore);
            g_lastMarketRegimeCheck = TimeCurrent();
            
            // Ghi log chế độ thị trường hiện tại
            g_logger.Info("Chế độ thị trường hiện tại: " + g_marketRegimeFilter.GetCurrentRegimeAsString());
        }
    }
    
    // Cập nhật tất cả các thành phần
    g_sonicCore.Update();
    g_riskManager.Update();
    g_propSettings.Update();
    g_exitManager.Update();
    
    // Xử lý dựa trên state machine
    ProcessStateMachine(isNewBar);
    
    // Cập nhật dashboard nếu hoạt động
    if(g_dashboard != NULL) {
        g_dashboard.Update();
    }
}

//+------------------------------------------------------------------+
//| Process based on current state                                  |
//+------------------------------------------------------------------+
void ProcessStateMachine(bool isNewBar)
{
    // Lấy trạng thái hiện tại
    ENUM_EA_STATE currentState = g_stateMachine.GetCurrentState();
    
    // Xử lý dựa trên trạng thái
    switch(currentState) {
        case STATE_INITIALIZING:
            // Chuyển sang quét
            g_stateMachine.TransitionTo(STATE_SCANNING, "Khởi tạo hoàn tất");
            break;
            
        case STATE_SCANNING: {
            // Chỉ quét tín hiệu trên nến mới
            if(isNewBar) {
                // Kiểm tra nếu giao dịch được phép bởi các bộ lọc
                if(IsTradingAllowed()) {
                    // Kiểm tra tín hiệu mới
                    int signal = g_entryManager.CheckForSignal();
                    
                    if(signal != 0) {
                        g_logger.Info("Phát hiện tín hiệu: " + (signal > 0 ? "MUA" : "BÁN") + 
                                    " với chất lượng " + DoubleToString(g_entryManager.GetSignalQuality(), 2));
                        g_stateMachine.TransitionTo(STATE_WAITING, "Phát hiện tín hiệu");
                    }
                }
            }
            
            // Luôn quản lý các vị thế mở
            g_exitManager.ManageExits();
            break;
        }
            
        case STATE_WAITING: {
            // Kiểm tra nếu điều kiện giao dịch vẫn hợp lệ
            if(IsTradingAllowed()) {
                // Chuẩn bị vào lệnh
                if(g_entryManager.PrepareEntry(g_entryManager.GetCurrentSignal())) {
                    g_stateMachine.TransitionTo(STATE_EXECUTING, "Điều kiện vào lệnh đã sẵn sàng");
                }
            } else {
                // Giao dịch không được phép, quay lại quét
                g_stateMachine.TransitionTo(STATE_SCANNING, "Điều kiện giao dịch không đáp ứng");
            }
            
            // Luôn quản lý các vị thế mở
            g_exitManager.ManageExits();
            break;
        }
            
        case STATE_EXECUTING: {
            // Khai báo biến trước switch-case
            int retryCount = 0;
            bool executionSuccess = false;
            
            while(retryCount < MaxRetryAttempts && !executionSuccess) {
                executionSuccess = g_entryManager.ExecuteTrade();
                
                if(executionSuccess) {
                    g_logger.Info("Lệnh đã được thực thi thành công ở lần thử " + IntegerToString(retryCount + 1));
                    g_stateMachine.TransitionTo(STATE_MONITORING, "Lệnh đã thực thi");
                    
                    // Cập nhật thống kê giao dịch
                    g_successfulTrades++;
                    break;
                } else {
                    retryCount++;
                    if(retryCount < MaxRetryAttempts) {
                        g_logger.Warning("Thực thi lệnh thất bại, đang thử lại lần " + IntegerToString(retryCount + 1));
                        Sleep(RetryDelayMs);
                    }
                }
            }
            
            // Nếu tất cả các lần thử đều thất bại
            if(!executionSuccess) {
                g_logger.Error("Không thể thực thi lệnh sau " + IntegerToString(MaxRetryAttempts) + " lần thử");
                g_stateMachine.TransitionTo(STATE_SCANNING, "Thực thi lệnh thất bại");
                
                // Cập nhật thống kê giao dịch
                g_failedTrades++;
            }
            break;
        }
            
        case STATE_MONITORING: {
            // Kiểm tra tín hiệu mới trong khi quản lý vị thế mở
            g_exitManager.ManageExits();
            
            // Kiểm tra nếu không có vị thế mở
            if(PositionsTotal() == 0) {
                g_stateMachine.TransitionTo(STATE_SCANNING, "Không có vị thế mở");
            }
            
            // Kiểm tra tín hiệu mới trên nến mới
            if(isNewBar && IsTradingAllowed()) {
                int signal = g_entryManager.CheckForSignal();
                
                if(signal != 0) {
                    g_logger.Info("Phát hiện tín hiệu mới trong khi giám sát");
                    g_stateMachine.TransitionTo(STATE_WAITING, "Phát hiện tín hiệu mới");
                }
            }
            break;
        }
            
        case STATE_STOPPED: {
            // Kiểm tra nếu có thể tiếp tục
            if(g_riskManager.IsTradeAllowed() && !g_riskManager.IsInEmergencyMode()) {
                g_logger.Info("Tiếp tục giao dịch sau khi dừng");
                g_stateMachine.TransitionTo(STATE_SCANNING, "Tiếp tục sau khi dừng");
            }
            break;
        }
    }
    
    // Cập nhật timeout của state machine
    g_stateMachine.Update();
}

//+------------------------------------------------------------------+
//| Kiểm tra nếu giao dịch được phép bởi tất cả các bộ lọc           |
//+------------------------------------------------------------------+
bool IsTradingAllowed()
{
    // Kiểm tra risk manager trước
    if(!g_riskManager.IsTradeAllowed()) {
        g_logger.Info("Giao dịch không được phép: Đã đạt giới hạn rủi ro");
        return false;
    }
    
    // Kiểm tra bộ lọc phiên
    if(!g_sessionFilter.IsTradingAllowed()) {
        g_logger.Info("Giao dịch không được phép: Ngoài phiên cho phép");
        return false;
    }
    
    // Kiểm tra bộ lọc tin tức
    if(g_newsFilter.IsNewsTime()) {
        g_logger.Info("Giao dịch không được phép: Tin tức sắp diễn ra");
        return false;
    }
    
    // Kiểm tra bộ lọc chế độ thị trường
    if(!g_marketRegimeFilter.IsRegimeFavorable()) {
        g_logger.Info("Giao dịch không được phép: Chế độ thị trường không thuận lợi");
        return false;
    }
    
    // Tất cả kiểm tra đã qua
    return true;
}

//+------------------------------------------------------------------+
//| Expert custom event handler                                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Chuyển sự kiện chart đến dashboard nếu hoạt động
    if(g_dashboard != NULL) {
        g_dashboard.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Expert tester function                                          |
//+------------------------------------------------------------------+
double OnTester()
{
    // Tính toán điểm số cho tối ưu hóa
    double balanceDD = TesterStatistics(STAT_BALANCE_DD);
    if(balanceDD <= 0) balanceDD = 0.01; // Tránh chia cho 0
    
    double profitFactor = TesterStatistics(STAT_PROFIT_FACTOR);
    if(profitFactor <= 0) profitFactor = 0.01;
    
    double recovery = TesterStatistics(STAT_RECOVERY_FACTOR);
    double profit = TesterStatistics(STAT_PROFIT);
    double sharpe = TesterStatistics(STAT_SHARPE_RATIO);
    double trades = TesterStatistics(STAT_TRADES);
    
    // Đảm bảo giá trị hợp lệ
    if(sharpe < 0) sharpe = 0;
    if(trades < 10) return 0; // Quá ít giao dịch
    
    // Tính điểm tùy chỉnh cho PropFirm
    g_backtestScore = (profit / balanceDD) * profitFactor * recovery * (1 + sharpe/10);
    
    // Ghi log hoàn thành backtest
    if(g_logger != NULL) {
        g_logger.Info("Backtest đã hoàn thành");
        g_logger.Info("Thống kê: Profit = " + DoubleToString(profit, 2) + 
                     ", DD = " + DoubleToString(balanceDD, 2) + 
                     ", PF = " + DoubleToString(profitFactor, 2) + 
                     ", Score = " + DoubleToString(g_backtestScore, 2));
    }
    
    return g_backtestScore;
}

//+------------------------------------------------------------------+
//| OnTradeTransaction event handler                                 |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
    // Xử lý giao dịch nếu cần
    if(g_logger != NULL && trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        double dealProfit = 0.0;
        
        // Lấy thông tin deal bằng API
        if(!HistoryDealSelect(trans.deal)) {
            g_logger.Warning("Không thể chọn deal " + IntegerToString(trans.deal));
            return;
        }
        
        dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
        
        g_logger.Info("Giao dịch mới: " + IntegerToString(trans.deal) + ", Lệnh: " + 
                    IntegerToString(trans.order) + ", Khối lượng: " + DoubleToString(trans.volume, 2) + 
                    ", Lợi nhuận: " + DoubleToString(dealProfit, 2));
        
        // Cập nhật thống kê P/L
        if(dealProfit > 0) {
            g_totalProfit += dealProfit;
        } else if(dealProfit < 0) {
            g_totalLoss += MathAbs(dealProfit);
        }
    }
}