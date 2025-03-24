//+------------------------------------------------------------------+
//|                                      SonicR_TradingLogic.mqh      |
//|                SonicR PropFirm EA - Trading Logic Module          |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Các include tiêu chuẩn
#include <Trade\Trade.mqh>

// Forward declarations cho các phụ thuộc bên ngoài
class CLogger;
class CRiskManager;
class CStateMachine;
class CSessionFilter;
class CNewsFilter;
class CMarketRegimeFilter;
class CAdaptiveFilters;
class CPVSRA;

// Các thành phần gốc (được giữ trong file gốc)
#include "../SonicR_Core.mqh"
#include "../SonicR_SR.mqh"
#include "../SonicR_EntryManager.mqh"
#include "../SonicR_ExitManager.mqh"

//+------------------------------------------------------------------+
//| Lớp gom nhóm cho logic giao dịch                                 |
//+------------------------------------------------------------------+
class CTradingLogic
{
private:
    // Các thành phần chính
    CSonicRCore*      m_core;
    CSonicRSR*        m_srSystem;
    CEntryManager*    m_entryManager;
    CExitManager*     m_exitManager;
    CTrade*           m_trade;
    
    // Các phụ thuộc bên ngoài
    CLogger*          m_logger;
    CRiskManager*     m_riskManager;
    CStateMachine*    m_stateMachine;
    CSessionFilter*   m_sessionFilter;
    CNewsFilter*      m_newsFilter;
    CMarketRegimeFilter* m_marketRegimeFilter;
    CAdaptiveFilters* m_adaptiveFilters;
    CPVSRA*           m_pvsra;
    
    // Cấu hình
    int               m_magicNumber;
    int               m_maxRetryAttempts;
    int               m_retryDelayMs;
    bool              m_useVirtualSL;
    double            m_minRR;
    double            m_minSignalQuality;
    bool              m_useScoutEntries;
    int               m_slippagePoints;
    
    // Dữ liệu giao dịch đa cặp tiền
    string            m_symbols[];
    datetime          m_lastBarTimes[];
    
    // Trạng thái
    int               m_currentSignal;
    int               m_successfulTrades;
    int               m_failedTrades;
    
public:
    // Constructor/Destructor
    CTradingLogic();
    ~CTradingLogic();
    
    // Khởi tạo và thiết lập
    bool Initialize(int magicNumber, int slippagePoints, bool useVirtualSL);
    void SetRetrySettings(int maxRetries, int retryDelayMs) { m_maxRetryAttempts = maxRetries; m_retryDelayMs = retryDelayMs; }
    void SetSignalQualityParams(double minRR, double minSignalQuality, bool useScoutEntries);
    void SetMultiSymbolMode(string &symbols[]);
    
    // Thiết lập các phụ thuộc
    void SetLogger(CLogger* logger);
    void SetRiskManager(CRiskManager* riskManager);
    void SetStateMachine(CStateMachine* stateMachine);
    void SetFilters(CSessionFilter* sessionFilter, CNewsFilter* newsFilter, CMarketRegimeFilter* marketRegimeFilter);
    void SetAdaptiveFilters(CAdaptiveFilters* adaptiveFilters);
    void SetPVSRA(CPVSRA* pvsra);
    
    // Phương thức chính cho EA
    void UpdateOnNewBar(string symbol);
    void UpdateOnTick(string symbol);
    
    // Kiểm tra và xử lý tín hiệu
    int CheckForSignal(string symbol = NULL);
    bool PrepareEntry(int signal, string symbol = NULL);
    bool ExecuteTrade(string symbol = NULL);
    
    // Quản lý vị thế mở
    void ManageExits();
    void CloseAllPositions();
    
    // Kiểm tra tín hiệu SR và PVSRA
    bool IsSignalConfirmedBySR(int signal, string symbol = NULL);
    bool IsSignalConfirmedByPVSRA(int signal, string symbol = NULL);
    
    // Phương thức truy cập
    CSonicRCore* GetCore() { return m_core; }
    CSonicRSR* GetSR() { return m_srSystem; }
    CEntryManager* GetEntryManager() { return m_entryManager; }
    CExitManager* GetExitManager() { return m_exitManager; }
    
    // Phương thức truy cập trạng thái
    int GetCurrentSignal() { return m_currentSignal; }
    int GetSuccessfulTrades() { return m_successfulTrades; }
    int GetFailedTrades() { return m_failedTrades; }
    double GetSignalQuality(string symbol = NULL);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradingLogic::CTradingLogic()
{
    m_core = NULL;
    m_srSystem = NULL;
    m_entryManager = NULL;
    m_exitManager = NULL;
    m_trade = NULL;
    
    m_logger = NULL;
    m_riskManager = NULL;
    m_stateMachine = NULL;
    m_sessionFilter = NULL;
    m_newsFilter = NULL;
    m_marketRegimeFilter = NULL;
    m_adaptiveFilters = NULL;
    m_pvsra = NULL;
    
    m_magicNumber = 0;
    m_maxRetryAttempts = 3;
    m_retryDelayMs = 200;
    m_useVirtualSL = true;
    m_minRR = 1.5;
    m_minSignalQuality = 70.0;
    m_useScoutEntries = false;
    m_slippagePoints = 5;
    
    m_currentSignal = 0;
    m_successfulTrades = 0;
    m_failedTrades = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradingLogic::~CTradingLogic()
{
    // Giải phóng bộ nhớ - chỉ xóa các đối tượng được tạo trong lớp này
    // Đối tượng phụ thuộc được quản lý bởi EA chính
    if(m_core != NULL) delete m_core;
    if(m_srSystem != NULL) delete m_srSystem;
    if(m_entryManager != NULL) delete m_entryManager;
    if(m_exitManager != NULL) delete m_exitManager;
    if(m_trade != NULL) delete m_trade;
}

//+------------------------------------------------------------------+
//| Khởi tạo tất cả các thành phần trading logic                     |
//+------------------------------------------------------------------+
bool CTradingLogic::Initialize(int magicNumber, int slippagePoints, bool useVirtualSL)
{
    m_magicNumber = magicNumber;
    m_slippagePoints = slippagePoints;
    m_useVirtualSL = useVirtualSL;
    
    // Khởi tạo đối tượng Trade
    m_trade = new CTrade();
    if(m_trade == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize Trade object");
        return false;
    }
    
    m_trade.SetExpertMagicNumber(magicNumber);
    m_trade.SetDeviationInPoints(slippagePoints);
    m_trade.LogLevel(LOG_LEVEL_ERRORS); // Only log errors from trade object
    
    // Khởi tạo SR system
    m_srSystem = new CSonicRSR();
    if(m_srSystem == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize SR system");
        return false;
    }
    
    if(!m_srSystem.Initialize()) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize SR system indicators");
        return false;
    }
    
    // Khởi tạo core strategy
    m_core = new CSonicRCore();
    if(m_core == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize SonicCore");
        return false;
    }
    
    if(!m_core.Initialize()) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize SonicCore indicators");
        return false;
    }
    
    // Khởi tạo entry manager
    m_entryManager = new CEntryManager(m_core, m_riskManager, m_trade);
    if(m_entryManager == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize EntryManager");
        return false;
    }
    
    m_entryManager.SetMinRR(m_minRR);
    m_entryManager.SetMinSignalQuality(m_minSignalQuality);
    m_entryManager.SetUseScoutEntries(m_useScoutEntries);
    m_entryManager.SetRetrySettings(m_maxRetryAttempts, m_retryDelayMs);
    
    // Thiết lập SR system cho entry manager
    m_entryManager.SetSRSystem(m_srSystem);
    
    // Khởi tạo exit manager
    m_exitManager = new CExitManager();
    if(m_exitManager == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize ExitManager");
        return false;
    }
    
    m_exitManager.SetMagicNumber(magicNumber);
    m_exitManager.SetSlippage(slippagePoints);
    m_exitManager.SetUseVirtualSL(useVirtualSL);
    
    if(m_logger != NULL) {
        m_logger.Info("Trading Logic module initialized successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập logger                                                |
//+------------------------------------------------------------------+
void CTradingLogic::SetLogger(CLogger* logger)
{
    m_logger = logger;
    
    // Chuyển tiếp logger cho các thành phần con
    if(m_core != NULL) m_core.SetLogger(logger);
    if(m_srSystem != NULL) m_srSystem.SetLogger(logger);
    if(m_entryManager != NULL) m_entryManager.SetLogger(logger);
    if(m_exitManager != NULL) m_exitManager.SetLogger(logger);
}

//+------------------------------------------------------------------+
//| Thiết lập risk manager                                           |
//+------------------------------------------------------------------+
void CTradingLogic::SetRiskManager(CRiskManager* riskManager)
{
    m_riskManager = riskManager;
    
    // Cập nhật entryManager nếu đã được khởi tạo
    if(m_entryManager != NULL) {
        m_entryManager.SetRiskManager(riskManager);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập state machine                                          |
//+------------------------------------------------------------------+
void CTradingLogic::SetStateMachine(CStateMachine* stateMachine)
{
    m_stateMachine = stateMachine;
}

//+------------------------------------------------------------------+
//| Thiết lập bộ lọc                                                |
//+------------------------------------------------------------------+
void CTradingLogic::SetFilters(CSessionFilter* sessionFilter, CNewsFilter* newsFilter, CMarketRegimeFilter* marketRegimeFilter)
{
    m_sessionFilter = sessionFilter;
    m_newsFilter = newsFilter;
    m_marketRegimeFilter = marketRegimeFilter;
}

//+------------------------------------------------------------------+
//| Thiết lập adaptive filters                                       |
//+------------------------------------------------------------------+
void CTradingLogic::SetAdaptiveFilters(CAdaptiveFilters* adaptiveFilters)
{
    m_adaptiveFilters = adaptiveFilters;
}

//+------------------------------------------------------------------+
//| Thiết lập PVSRA                                                 |
//+------------------------------------------------------------------+
void CTradingLogic::SetPVSRA(CPVSRA* pvsra)
{
    m_pvsra = pvsra;
}

//+------------------------------------------------------------------+
//| Thiết lập tham số chất lượng tín hiệu                            |
//+------------------------------------------------------------------+
void CTradingLogic::SetSignalQualityParams(double minRR, double minSignalQuality, bool useScoutEntries)
{
    m_minRR = minRR;
    m_minSignalQuality = minSignalQuality;
    m_useScoutEntries = useScoutEntries;
    
    // Cập nhật entry manager nếu đã được khởi tạo
    if(m_entryManager != NULL) {
        m_entryManager.SetMinRR(minRR);
        m_entryManager.SetMinSignalQuality(minSignalQuality);
        m_entryManager.SetUseScoutEntries(useScoutEntries);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập chế độ đa cặp tiền                                     |
//+------------------------------------------------------------------+
void CTradingLogic::SetMultiSymbolMode(string &symbols[])
{
    int count = ArraySize(symbols);
    ArrayResize(m_symbols, count);
    ArrayResize(m_lastBarTimes, count);
    
    for(int i = 0; i < count; i++) {
        m_symbols[i] = symbols[i];
        m_lastBarTimes[i] = 0;
    }
}

//+------------------------------------------------------------------+
//| Cập nhật khi có bar mới                                          |
//+------------------------------------------------------------------+
void CTradingLogic::UpdateOnNewBar(string symbol)
{
    if(m_logger != NULL) m_logger.Debug("New bar for " + symbol);
    
    // Cập nhật core
    if(m_core != NULL) {
        if(symbol == _Symbol) {
            m_core.UpdateFull();
        } else {
            // TODO: Xử lý cập nhật cho cặp tiền khác
        }
    }
    
    // Cập nhật SR system
    if(m_srSystem != NULL) {
        if(symbol == _Symbol) {
            m_srSystem.Update();
        } else {
            // TODO: Xử lý cập nhật cho cặp tiền khác
        }
    }
    
    // Cập nhật PVSRA nếu có
    if(m_pvsra != NULL) {
        if(symbol == _Symbol) {
            m_pvsra.Update();
        } else {
            // TODO: Xử lý cập nhật cho cặp tiền khác
        }
    }
}

//+------------------------------------------------------------------+
//| Cập nhật mỗi tick                                                |
//+------------------------------------------------------------------+
void CTradingLogic::UpdateOnTick(string symbol)
{
    // Cập nhật core (nhẹ)
    if(m_core != NULL && symbol == _Symbol) {
        m_core.UpdateLight();
    }
    
    // Quản lý các vị thế đang mở
    ManageExits();
}

//+------------------------------------------------------------------+
//| Kiểm tra tín hiệu mới                                           |
//+------------------------------------------------------------------+
int CTradingLogic::CheckForSignal(string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_entryManager != NULL) {
        m_currentSignal = m_entryManager.CheckForSignal();
        return m_currentSignal;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Chuẩn bị vào lệnh                                               |
//+------------------------------------------------------------------+
bool CTradingLogic::PrepareEntry(int signal, string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_entryManager != NULL) {
        return m_entryManager.PrepareEntry(signal);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Thực hiện lệnh giao dịch                                        |
//+------------------------------------------------------------------+
bool CTradingLogic::ExecuteTrade(string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_entryManager != NULL) {
        bool result = m_entryManager.ExecuteTrade();
        
        if(result) {
            m_successfulTrades++;
        } else {
            m_failedTrades++;
        }
        
        return result;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Quản lý thoát lệnh                                              |
//+------------------------------------------------------------------+
void CTradingLogic::ManageExits()
{
    if(m_exitManager != NULL) {
        m_exitManager.ManageExits();
    }
}

//+------------------------------------------------------------------+
//| Đóng tất cả các vị thế                                          |
//+------------------------------------------------------------------+
void CTradingLogic::CloseAllPositions()
{
    if(m_exitManager != NULL) {
        m_exitManager.CloseAllPositions();
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra tín hiệu bằng SR                                       |
//+------------------------------------------------------------------+
bool CTradingLogic::IsSignalConfirmedBySR(int signal, string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_srSystem != NULL) {
        return m_srSystem.ConfirmSignal(signal);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra tín hiệu bằng PVSRA                                    |
//+------------------------------------------------------------------+
bool CTradingLogic::IsSignalConfirmedByPVSRA(int signal, string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_pvsra != NULL && m_core != NULL) {
        return m_core.IsPVSRAConfirming(signal);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Lấy chất lượng tín hiệu                                         |
//+------------------------------------------------------------------+
double CTradingLogic::GetSignalQuality(string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_entryManager != NULL) {
        return m_entryManager.GetSignalQuality();
    }
    
    return 0.0;
} 