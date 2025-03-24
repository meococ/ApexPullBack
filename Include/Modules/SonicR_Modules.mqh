//+------------------------------------------------------------------+
//|                                       SonicR_Modules.mqh         |
//|                SonicR PropFirm EA - Master Module Include File   |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Include các module đã gom nhóm
#include "SonicR_TradingLogic.mqh"
#include "SonicR_RiskModule.mqh"
#include "SonicR_MarketAnalysis.mqh"
#include "SonicR_System.mqh"

// Include Dashboard riêng vì không gom nhóm
#include "../SonicR_Dashboard.mqh"

//+------------------------------------------------------------------+
//| Class làm điểm truy cập tập trung cho toàn bộ EA                 |
//+------------------------------------------------------------------+
class CSonicRModules
{
private:
    // Các module chính
    CTradingLogic*    m_tradingLogic;
    CRiskModule*      m_riskModule;
    CMarketAnalysis*  m_marketAnalysis;
    CSystem*          m_system;
    CDashboard*       m_dashboard;
    
    // Trạng thái
    bool              m_initialized;
    bool              m_displayDashboard;
    
public:
    // Constructor/Destructor
    CSonicRModules();
    ~CSonicRModules();
    
    // Khởi tạo và thiết lập
    bool Initialize(
        // EA info
        const string eaName, 
        int magicNumber, 
        bool enableDetailedLogging,
        bool saveLogsToFile,
        bool displayDashboard,
        
        // Risk
        double riskPercent,
        double maxDailyDD,
        double maxTotalDD,
        int maxTradesPerDay,
        bool useRecoveryMode,
        double recoveryReduceFactor,
        
        // PropFirm
        ENUM_PROP_FIRM propFirmType,
        ENUM_CHALLENGE_PHASE challengePhase,
        bool autoDetectPhase,
        double customTargetProfit,
        double customMaxDrawdown,
        double customDailyDrawdown,
        
        // Challenge timelines
        int challengeDaysTotal,
        int challengeDaysRemaining,
        double emergencyProgressThreshold,
        double conservativeProgressThreshold,
        
        // Trading
        bool useVirtualSL,
        int slippagePoints,
        double minRR,
        double minSignalQuality,
        bool useScoutEntries,
        int maxRetryAttempts,
        int retryDelayMs,
        
        // Exit parameters
        bool usePartialClose,
        double tp1Percent,
        double tp1Distance,
        double tp2Distance,
        bool useBreakEven,
        double breakEvenTrigger,
        double breakEvenOffset,
        bool useTrailing,
        double trailingStart,
        double trailingStep,
        bool useAdaptiveTrailing,
        
        // Sessions
        bool enableLondonSession,
        bool enableNewYorkSession,
        bool enableLondonNYOverlap,
        bool enableAsianSession,
        int fridayEndHour,
        bool allowMondayTrading,
        bool allowFridayTrading,
        double sessionQualityThreshold,
        
        // News
        bool useNewsFilter,
        int newsMinutesBefore,
        int newsMinutesAfter,
        bool highImpactOnly,
        
        // Market Regime
        bool useMarketRegimeFilter,
        bool tradeBullishRegime,
        bool tradeBearishRegime,
        bool tradeRangingRegime,
        bool tradeVolatileRegime,
        
        // PVSRA
        bool usePVSRA,
        int volumeAvgPeriod,
        int spreadAvgPeriod,
        int confirmationBars,
        double volumeThreshold,
        double spreadThreshold,
        
        // SR
        bool useSRFilter,
        bool useMultiTimeframeSR,
        int srLookbackPeriod,
        double srQualityThreshold,
        
        // Multi-Symbol Trading
        bool enableMultiSymbolTrading,
        double totalRiskLimit,
        int maxActiveSymbols,
        bool syncEntries,
        string enabledSymbols[]
    );
    
    // Main processing
    void OnTick();
    void OnNewBar();
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    double OnTester();
    void OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result);
    
    // Cleanup
    void Cleanup();
    
    // Module access
    CTradingLogic* GetTradingLogic() { return m_tradingLogic; }
    CRiskModule* GetRiskModule() { return m_riskModule; }
    CMarketAnalysis* GetMarketAnalysis() { return m_marketAnalysis; }
    CSystem* GetSystem() { return m_system; }
    CDashboard* GetDashboard() { return m_dashboard; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSonicRModules::CSonicRModules()
{
    m_tradingLogic = NULL;
    m_riskModule = NULL;
    m_marketAnalysis = NULL;
    m_system = NULL;
    m_dashboard = NULL;
    
    m_initialized = false;
    m_displayDashboard = true;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSonicRModules::~CSonicRModules()
{
    Cleanup();
}

//+------------------------------------------------------------------+
//| Khởi tạo tất cả các module                                       |
//+------------------------------------------------------------------+
bool CSonicRModules::Initialize(
    // EA info
    const string eaName, 
    int magicNumber, 
    bool enableDetailedLogging,
    bool saveLogsToFile,
    bool displayDashboard,
    
    // Risk
    double riskPercent,
    double maxDailyDD,
    double maxTotalDD,
    int maxTradesPerDay,
    bool useRecoveryMode,
    double recoveryReduceFactor,
    
    // PropFirm
    ENUM_PROP_FIRM propFirmType,
    ENUM_CHALLENGE_PHASE challengePhase,
    bool autoDetectPhase,
    double customTargetProfit,
    double customMaxDrawdown,
    double customDailyDrawdown,
    
    // Challenge timelines
    int challengeDaysTotal,
    int challengeDaysRemaining,
    double emergencyProgressThreshold,
    double conservativeProgressThreshold,
    
    // Trading
    bool useVirtualSL,
    int slippagePoints,
    double minRR,
    double minSignalQuality,
    bool useScoutEntries,
    int maxRetryAttempts,
    int retryDelayMs,
    
    // Exit parameters
    bool usePartialClose,
    double tp1Percent,
    double tp1Distance,
    double tp2Distance,
    bool useBreakEven,
    double breakEvenTrigger,
    double breakEvenOffset,
    bool useTrailing,
    double trailingStart,
    double trailingStep,
    bool useAdaptiveTrailing,
    
    // Sessions
    bool enableLondonSession,
    bool enableNewYorkSession,
    bool enableLondonNYOverlap,
    bool enableAsianSession,
    int fridayEndHour,
    bool allowMondayTrading,
    bool allowFridayTrading,
    double sessionQualityThreshold,
    
    // News
    bool useNewsFilter,
    int newsMinutesBefore,
    int newsMinutesAfter,
    bool highImpactOnly,
    
    // Market Regime
    bool useMarketRegimeFilter,
    bool tradeBullishRegime,
    bool tradeBearishRegime,
    bool tradeRangingRegime,
    bool tradeVolatileRegime,
    
    // PVSRA
    bool usePVSRA,
    int volumeAvgPeriod,
    int spreadAvgPeriod,
    int confirmationBars,
    double volumeThreshold,
    double spreadThreshold,
    
    // SR
    bool useSRFilter,
    bool useMultiTimeframeSR,
    int srLookbackPeriod,
    double srQualityThreshold,
    
    // Multi-Symbol Trading
    bool enableMultiSymbolTrading,
    double totalRiskLimit,
    int maxActiveSymbols,
    bool syncEntries,
    string enabledSymbols[]
)
{
    m_displayDashboard = displayDashboard;
    
    // Khởi tạo System module trước vì nó chứa logger
    m_system = new CSystem();
    if(m_system == NULL) {
        Print("ERROR: Failed to initialize System module");
        return false;
    }
    
    if(!m_system.Initialize(eaName, magicNumber, enableDetailedLogging, saveLogsToFile)) {
        Print("ERROR: System module initialization failed");
        return false;
    }
    
    // Thiết lập cài đặt PropFirm
    m_system.SetPropFirmSettings(propFirmType, challengePhase, autoDetectPhase);
    if(propFirmType == PROP_FIRM_CUSTOM) {
        m_system.SetCustomPropFirmValues(customTargetProfit, customMaxDrawdown, customDailyDrawdown);
    }
    
    // Thiết lập khung thời gian challenge
    datetime startDate = TimeCurrent() - (challengeDaysTotal - challengeDaysRemaining) * 86400; // 86400 seconds = 1 day
    m_system.SetChallengeTimeframe(startDate, challengeDaysTotal);
    
    // Lấy logger từ System module để sử dụng trong các module khác
    CLogger* logger = m_system.GetLogger();
    
    // Khởi tạo Risk module
    m_riskModule = new CRiskModule();
    if(m_riskModule == NULL) {
        m_system.LogError("Failed to initialize Risk module");
        return false;
    }
    
    m_riskModule.SetLogger(logger);
    if(!m_riskModule.Initialize(riskPercent, maxDailyDD, maxTotalDD, maxTradesPerDay)) {
        m_system.LogError("Risk module initialization failed");
        return false;
    }
    
    // Thiết lập các tham số cho Risk module
    m_riskModule.SetRecoveryMode(useRecoveryMode, recoveryReduceFactor);
    m_riskModule.SetChallengeParams(challengeDaysTotal, challengeDaysRemaining, 
                                   emergencyProgressThreshold, conservativeProgressThreshold);
    m_riskModule.SetMultiSymbolParams(totalRiskLimit, maxActiveSymbols);
    
    // Khởi tạo Market Analysis module
    m_marketAnalysis = new CMarketAnalysis();
    if(m_marketAnalysis == NULL) {
        m_system.LogError("Failed to initialize Market Analysis module");
        return false;
    }
    
    m_marketAnalysis.SetLogger(logger);
    if(!m_marketAnalysis.Initialize()) {
        m_system.LogError("Market Analysis module initialization failed");
        return false;
    }
    
    // Thiết lập các tham số cho Market Analysis module
    m_marketAnalysis.SetSessionFilterParams(
        enableLondonSession, enableNewYorkSession, enableLondonNYOverlap, enableAsianSession,
        fridayEndHour, allowMondayTrading, allowFridayTrading, sessionQualityThreshold
    );
    
    m_marketAnalysis.SetNewsFilterParams(useNewsFilter, newsMinutesBefore, newsMinutesAfter, highImpactOnly);
    m_marketAnalysis.SetMarketRegimeFilterParams(
        useMarketRegimeFilter, tradeBullishRegime, tradeBearishRegime, tradeRangingRegime, tradeVolatileRegime
    );
    m_marketAnalysis.SetPVSRAParams(
        usePVSRA, volumeAvgPeriod, spreadAvgPeriod, confirmationBars, volumeThreshold, spreadThreshold
    );
    
    // Khởi tạo Trading Logic module
    m_tradingLogic = new CTradingLogic();
    if(m_tradingLogic == NULL) {
        m_system.LogError("Failed to initialize Trading Logic module");
        return false;
    }
    
    m_tradingLogic.SetLogger(logger);
    if(!m_tradingLogic.Initialize(magicNumber, slippagePoints, useVirtualSL)) {
        m_system.LogError("Trading Logic module initialization failed");
        return false;
    }
    
    // Thiết lập các tham số cho Trading Logic module
    m_tradingLogic.SetRetrySettings(maxRetryAttempts, retryDelayMs);
    m_tradingLogic.SetSignalQualityParams(minRR, minSignalQuality, useScoutEntries);
    
    // Thiết lập exit parameters
    CExitManager* exitManager = m_tradingLogic.GetExitManager();
    if(exitManager != NULL) {
        exitManager.Configure(
            usePartialClose, tp1Percent, tp1Distance, tp2Distance,
            useBreakEven, breakEvenTrigger, breakEvenOffset,
            useTrailing, trailingStart, trailingStep, useAdaptiveTrailing
        );
    }
    
    // Thiết lập SR system parameters
    CSonicRSR* srSystem = m_tradingLogic.GetSR();
    if(srSystem != NULL) {
        srSystem.SetParameters(srLookbackPeriod, srQualityThreshold, useMultiTimeframeSR);
    }
    
    // Thiết lập multi-symbol mode nếu được bật
    if(enableMultiSymbolTrading) {
        m_tradingLogic.SetMultiSymbolMode(enabledSymbols);
    }
    
    // Thiết lập các kết nối giữa các module
    m_tradingLogic.SetRiskManager(m_riskModule.GetRiskManager());
    m_tradingLogic.SetStateMachine(m_system.GetStateMachine());
    m_tradingLogic.SetFilters(
        m_marketAnalysis.GetSessionFilter(),
        m_marketAnalysis.GetNewsFilter(),
        m_marketAnalysis.GetMarketRegimeFilter()
    );
    m_tradingLogic.SetAdaptiveFilters(m_riskModule.GetAdaptiveFilters());
    m_tradingLogic.SetPVSRA(m_marketAnalysis.GetPVSRA());
    
    m_riskModule.SetCore(m_tradingLogic.GetCore());
    m_marketAnalysis.SetCore(m_tradingLogic.GetCore());
    
    // Khởi tạo Dashboard nếu cần
    if(m_displayDashboard) {
        m_dashboard = new CDashboard();
        if(m_dashboard == NULL) {
            m_system.LogWarning("Failed to initialize Dashboard. Continuing without dashboard.");
        }
        else {
            m_dashboard.SetLogger(logger);
            m_dashboard.SetDependencies(
                m_tradingLogic.GetCore(),
                m_riskModule.GetRiskManager(), 
                m_system.GetStateMachine(), 
                m_system.GetPropSettings()
            );
            m_dashboard.SetAdaptiveFilters(m_riskModule.GetAdaptiveFilters());
            m_dashboard.SetPVSRA(m_marketAnalysis.GetPVSRA());
            m_dashboard.Create();
        }
    }
    
    m_system.LogInfo("SonicR Modules initialized successfully");
    m_initialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Xử lý OnTick event                                               |
//+------------------------------------------------------------------+
void CSonicRModules::OnTick()
{
    if(!m_initialized || (m_system != NULL && m_system.IsShutdownRequested())) {
        return;
    }
    
    // Kiểm tra bar mới
    static datetime lastBarTime = 0;
    datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
    bool isNewBar = (currentBarTime != lastBarTime);
    
    if(isNewBar) {
        lastBarTime = currentBarTime;
        OnNewBar();
    }
    
    // Cập nhật các module
    if(m_system != NULL) m_system.Update();
    if(m_riskModule != NULL) m_riskModule.Update();
    
    // Cập nhật trading logic
    if(m_tradingLogic != NULL) {
        if(isNewBar) {
            m_tradingLogic.UpdateOnNewBar(_Symbol);
        } else {
            m_tradingLogic.UpdateOnTick(_Symbol);
        }
    }
    
    // Xử lý state machine
    ProcessStateMachine(isNewBar);
    
    // Cập nhật dashboard
    if(m_dashboard != NULL) {
        m_dashboard.Update();
    }
}

//+------------------------------------------------------------------+
//| Xử lý khi có bar mới                                             |
//+------------------------------------------------------------------+
void CSonicRModules::OnNewBar()
{
    if(m_system != NULL) m_system.LogDebug("New bar opened");
    
    // Cập nhật market analysis khi có bar mới
    if(m_marketAnalysis != NULL) {
        m_marketAnalysis.Update();
    }
}

//+------------------------------------------------------------------+
//| Xử lý state machine                                              |
//+------------------------------------------------------------------+
void CSonicRModules::ProcessStateMachine(bool isNewBar)
{
    if(m_system == NULL || m_tradingLogic == NULL || m_marketAnalysis == NULL || m_riskModule == NULL) {
        return;
    }
    
    // Lấy state machine từ system module
    CStateMachine* stateMachine = m_system.GetStateMachine();
    if(stateMachine == NULL) return;
    
    // Lấy trạng thái hiện tại
    ENUM_EA_STATE currentState = stateMachine.GetCurrentState();
    
    // Xử lý theo trạng thái
    switch(currentState) {
        case STATE_INITIALIZING:
            // Chuyển sang trạng thái scanning
            stateMachine.TransitionTo(STATE_SCANNING, "Initialization complete");
            break;
            
        case STATE_SCANNING: {
            // Chỉ tìm tín hiệu mới trên bar mới
            if(isNewBar) {
                // Kiểm tra điều kiện giao dịch
                if(m_marketAnalysis.IsTradingAllowed() && m_riskModule.IsTradeAllowed()) {
                    // Kiểm tra tín hiệu mới
                    int signal = m_tradingLogic.CheckForSignal();
                    
                    if(signal != 0) {
                        m_system.LogInfo("Signal detected: " + (signal > 0 ? "BUY" : "SELL") + 
                                     " with quality " + DoubleToString(m_tradingLogic.GetSignalQuality(), 2));
                        
                        // Xác nhận tín hiệu với SR và PVSRA
                        bool srConfirmed = m_tradingLogic.IsSignalConfirmedBySR(signal);
                        bool pvsraConfirmed = m_tradingLogic.IsSignalConfirmedByPVSRA(signal);
                        
                        if(srConfirmed && pvsraConfirmed) {
                            m_system.LogInfo("Signal confirmed by confirmation systems");
                            stateMachine.TransitionTo(STATE_WAITING, "Signal detected and confirmed");
                        } else {
                            m_system.LogInfo("Signal rejected by confirmation systems");
                        }
                    }
                }
            }
            
            // Luôn quản lý các vị thế mở
            m_tradingLogic.ManageExits();
            break;
        }
            
        case STATE_WAITING: {
            // Kiểm tra điều kiện giao dịch
            if(m_marketAnalysis.IsTradingAllowed() && m_riskModule.IsTradeAllowed()) {
                // Chuẩn bị vào lệnh
                int currentSignal = m_tradingLogic.GetCurrentSignal();
                if(m_tradingLogic.PrepareEntry(currentSignal)) {
                    stateMachine.TransitionTo(STATE_EXECUTING, "Entry conditions met");
                }
            } else {
                // Điều kiện không còn phù hợp, quay lại trạng thái scanning
                stateMachine.TransitionTo(STATE_SCANNING, "Trading conditions no longer valid");
            }
            
            // Luôn quản lý các vị thế mở
            m_tradingLogic.ManageExits();
            break;
        }
            
        case STATE_EXECUTING: {
            // Thử thực thi lệnh với số lần thử lại được cấu hình
            if(m_tradingLogic.ExecuteTrade()) {
                m_system.LogInfo("Trade executed successfully");
                stateMachine.TransitionTo(STATE_MONITORING, "Trade executed");
            } else {
                m_system.LogError("Failed to execute trade");
                stateMachine.TransitionTo(STATE_SCANNING, "Trade execution failed");
            }
            break;
        }
            
        case STATE_MONITORING: {
            // Quản lý các vị thế mở
            m_tradingLogic.ManageExits();
            
            // Kiểm tra nếu không còn vị thế mở
            if(PositionsTotal() == 0) {
                stateMachine.TransitionTo(STATE_SCANNING, "No open positions");
            }
            
            // Kiểm tra tín hiệu mới trên bar mới
            if(isNewBar && m_marketAnalysis.IsTradingAllowed() && m_riskModule.IsTradeAllowed()) {
                int signal = m_tradingLogic.CheckForSignal();
                
                if(signal != 0) {
                    m_system.LogInfo("New signal detected while monitoring");
                    stateMachine.TransitionTo(STATE_WAITING, "New signal detected");
                }
            }
            break;
        }
            
        case STATE_STOPPED: {
            // Kiểm tra nếu có thể tiếp tục giao dịch
            if(m_riskModule.IsTradeAllowed() && !m_riskModule.IsEmergencyMode()) {
                m_system.LogInfo("Resuming trading after stop");
                stateMachine.TransitionTo(STATE_SCANNING, "Resumed after stop");
            }
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Xử lý chart event                                                |
//+------------------------------------------------------------------+
void CSonicRModules::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Forward chart event tới dashboard
    if(m_dashboard != NULL) {
        m_dashboard.OnChartEvent(id, lparam, dparam, sparam);
    }
}

//+------------------------------------------------------------------+
//| Xử lý tester event                                                |
//+------------------------------------------------------------------+
double CSonicRModules::OnTester()
{
    // Tính toán độ tốt cho tối ưu hoá
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
    
    // Tính toán điểm tối ưu
    double backtestScore = (profit / balanceDD) * profitFactor * recovery * (1 + sharpe/10);
    
    // Log kết quả backtest
    if(m_system != NULL && m_system.GetLogger() != NULL) {
        m_system.LogInfo("Backtest completed");
        m_system.LogInfo("Statistics: Profit = " + DoubleToString(profit, 2) + 
                     ", DD = " + DoubleToString(balanceDD, 2) + 
                     ", PF = " + DoubleToString(profitFactor, 2) + 
                     ", Score = " + DoubleToString(backtestScore, 2));
    }
    
    return backtestScore;
}

//+------------------------------------------------------------------+
//| Xử lý trade transaction                                          |
//+------------------------------------------------------------------+
void CSonicRModules::OnTradeTransaction(const MqlTradeTransaction& trans, const MqlTradeRequest& request, const MqlTradeResult& result)
{
    // Xử lý trade transaction nếu cần
    if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
        double dealProfit = 0.0;
        
        // Lấy thông tin deal
        if(!HistoryDealSelect(trans.deal)) {
            if(m_system != NULL) m_system.LogWarning("Cannot select deal " + IntegerToString(trans.deal));
            return;
        }
        
        dealProfit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
        
        if(m_system != NULL) {
            m_system.LogInfo("New deal: " + IntegerToString(trans.deal) + ", Order: " + 
                         IntegerToString(trans.order) + ", Volume: " + DoubleToString(trans.volume, 2) + 
                         ", Profit: " + DoubleToString(dealProfit, 2));
        }
        
        // Cập nhật adaptive filters dựa trên kết quả giao dịch
        if(m_riskModule != NULL && m_riskModule.GetAdaptiveFilters() != NULL) {
            m_riskModule.GetAdaptiveFilters().UpdateBasedOnResults(dealProfit > 0, _Symbol);
        }
    }
}

//+------------------------------------------------------------------+
//| Dọn dẹp tài nguyên                                               |
//+------------------------------------------------------------------+
void CSonicRModules::Cleanup()
{
    // Xóa dashboard trước
    if(m_dashboard != NULL) {
        m_dashboard.Remove();
    }
    
    // Giải phóng các module theo thứ tự ngược lại với khởi tạo
    if(m_dashboard != NULL) delete m_dashboard;
    if(m_tradingLogic != NULL) delete m_tradingLogic;
    if(m_marketAnalysis != NULL) delete m_marketAnalysis;
    if(m_riskModule != NULL) delete m_riskModule;
    if(m_system != NULL) delete m_system;
    
    // Reset pointers
    m_dashboard = NULL;
    m_tradingLogic = NULL;
    m_marketAnalysis = NULL;
    m_riskModule = NULL;
    m_system = NULL;
    
    // Xóa các đối tượng trên biểu đồ
    ObjectsDeleteAll(0, "SonicR_");
} 