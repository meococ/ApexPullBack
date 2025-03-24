//+------------------------------------------------------------------+
//|                                      SonicR_RiskModule.mqh        |
//|                SonicR PropFirm EA - Risk Management Module        |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Forward declarations cho các phụ thuộc bên ngoài
class CLogger;
class CSonicRCore;

// Các thành phần gốc (được giữ trong file gốc)
#include "../SonicR_RiskManager.mqh"
#include "../SonicR_AdaptiveFilters.mqh"

//+------------------------------------------------------------------+
//| Lớp gom nhóm cho quản lý rủi ro                                  |
//+------------------------------------------------------------------+
class CRiskModule
{
private:
    // Các thành phần chính
    CRiskManager*     m_riskManager;
    CAdaptiveFilters* m_adaptiveFilters;
    
    // Các phụ thuộc bên ngoài
    CLogger*          m_logger;
    CSonicRCore*      m_core;
    
    // Cấu hình
    double            m_accountBalance;
    double            m_maxRiskPercent;
    double            m_maxDailyDD;
    double            m_maxTotalDD;
    double            m_totalRiskLimit;
    int               m_maxActiveSymbols;
    int               m_challengeDaysTotal;
    int               m_challengeDaysRemaining;
    
    // Trạng thái đa cặp tiền
    string            m_symbols[];
    double            m_symbolRiskUsed[];
    double            m_totalRiskUsed;
    
public:
    // Constructor/Destructor
    CRiskModule();
    ~CRiskModule();
    
    // Khởi tạo và thiết lập
    bool Initialize(double riskPercent, double maxDailyDD, double maxTotalDD, int maxTradesPerDay);
    void SetChallengeParams(int daysTotal, int daysRemaining, double emergencyThreshold, double conservativeThreshold);
    void SetMultiSymbolParams(double totalRiskLimit, int maxActiveSymbols);
    void SetRecoveryMode(bool useRecoveryMode, double recoveryFactor);
    
    // Thiết lập các phụ thuộc
    void SetLogger(CLogger* logger);
    void SetCore(CSonicRCore* core);
    
    // Quản lý rủi ro
    bool IsTradeAllowed(string symbol = NULL);
    bool IsEmergencyMode();
    void Update();
    void UpdateGlobalRisk();
    void AdjustForMarketRegime();
    
    // Symbol-specific risk
    double CalculateLotSize(double stopLossPips, string symbol = NULL);
    double GetSymbolRiskMultiplier(string symbol);
    
    // Trạng thái
    double GetAccountBalance() { return m_accountBalance; }
    double GetEquity();
    double GetDailyDrawdown();
    double GetTotalDrawdown();
    int GetTradesToday();
    
    // Phương thức truy cập
    CRiskManager* GetRiskManager() { return m_riskManager; }
    CAdaptiveFilters* GetAdaptiveFilters() { return m_adaptiveFilters; }
    
    // Các phương thức get/set
    double GetBaseRiskPercent(string symbol = NULL);
    void SetRiskPercent(double riskPercent);
    void SetMaxTradesPerDay(int maxTrades);
    double GetMinRR();
    double GetTotalRiskUsed() { return m_totalRiskUsed; }
    bool ShouldUseScoutEntries();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CRiskModule::CRiskModule()
{
    m_riskManager = NULL;
    m_adaptiveFilters = NULL;
    m_logger = NULL;
    m_core = NULL;
    
    m_accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_maxRiskPercent = 0.5;
    m_maxDailyDD = 3.0;
    m_maxTotalDD = 5.0;
    m_totalRiskLimit = 5.0;
    m_maxActiveSymbols = 3;
    m_challengeDaysTotal = 30;
    m_challengeDaysRemaining = 30;
    
    m_totalRiskUsed = 0.0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CRiskModule::~CRiskModule()
{
    // Giải phóng bộ nhớ - chỉ xóa các đối tượng được tạo trong lớp này
    if(m_riskManager != NULL) delete m_riskManager;
    if(m_adaptiveFilters != NULL) delete m_adaptiveFilters;
}

//+------------------------------------------------------------------+
//| Khởi tạo các thành phần quản lý rủi ro                           |
//+------------------------------------------------------------------+
bool CRiskModule::Initialize(double riskPercent, double maxDailyDD, double maxTotalDD, int maxTradesPerDay)
{
    m_maxRiskPercent = riskPercent;
    m_maxDailyDD = maxDailyDD;
    m_maxTotalDD = maxTotalDD;
    
    // Khởi tạo RiskManager
    m_riskManager = new CRiskManager(riskPercent, maxDailyDD, maxTotalDD, maxTradesPerDay);
    if(m_riskManager == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize RiskManager");
        return false;
    }
    
    // Khởi tạo AdaptiveFilters
    m_adaptiveFilters = new CAdaptiveFilters();
    if(m_adaptiveFilters == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize AdaptiveFilters");
        return false;
    }
    
    if(m_logger != NULL) {
        m_logger.Info("Risk Module initialized successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập Logger                                                 |
//+------------------------------------------------------------------+
void CRiskModule::SetLogger(CLogger* logger)
{
    m_logger = logger;
    
    // Chuyển tiếp logger cho các thành phần con
    if(m_riskManager != NULL) m_riskManager.SetLogger(logger);
    if(m_adaptiveFilters != NULL) m_adaptiveFilters.SetLogger(logger);
}

//+------------------------------------------------------------------+
//| Thiết lập Core                                                   |
//+------------------------------------------------------------------+
void CRiskModule::SetCore(CSonicRCore* core)
{
    m_core = core;
}

//+------------------------------------------------------------------+
//| Thiết lập tham số challenge                                      |
//+------------------------------------------------------------------+
void CRiskModule::SetChallengeParams(int daysTotal, int daysRemaining, double emergencyThreshold, double conservativeThreshold)
{
    m_challengeDaysTotal = daysTotal;
    m_challengeDaysRemaining = daysRemaining;
    
    // Cập nhật adaptive filters
    if(m_adaptiveFilters != NULL) {
        m_adaptiveFilters.AdjustForChallengeProgress(daysRemaining, daysTotal);
        m_adaptiveFilters.SetProgressThresholds(emergencyThreshold, conservativeThreshold);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập tham số đa cặp tiền                                    |
//+------------------------------------------------------------------+
void CRiskModule::SetMultiSymbolParams(double totalRiskLimit, int maxActiveSymbols)
{
    m_totalRiskLimit = totalRiskLimit;
    m_maxActiveSymbols = maxActiveSymbols;
}

//+------------------------------------------------------------------+
//| Thiết lập chế độ phục hồi                                        |
//+------------------------------------------------------------------+
void CRiskModule::SetRecoveryMode(bool useRecoveryMode, double recoveryFactor)
{
    if(m_riskManager != NULL) {
        m_riskManager.SetRecoveryMode(useRecoveryMode, recoveryFactor);
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra xem giao dịch có được phép không                        |
//+------------------------------------------------------------------+
bool CRiskModule::IsTradeAllowed(string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    // Kiểm tra giới hạn rủi ro cơ bản
    if(m_riskManager != NULL && !m_riskManager.IsTradeAllowed()) {
        if(m_logger != NULL) m_logger.Debug("Trade not allowed for " + symbol + ": Risk limits reached");
        return false;
    }
    
    // Kiểm tra giới hạn rủi ro tổng
    double symbolRiskMultiplier = GetSymbolRiskMultiplier(symbol);
    double riskForSymbol = m_maxRiskPercent * symbolRiskMultiplier;
    
    if(m_totalRiskUsed + riskForSymbol > m_totalRiskLimit) {
        if(m_logger != NULL) {
            m_logger.Debug("Trade not allowed for " + symbol + ": Total risk limit reached (" + 
                         DoubleToString(m_totalRiskUsed, 2) + "% + " + DoubleToString(riskForSymbol, 2) + 
                         "% > " + DoubleToString(m_totalRiskLimit, 2) + "%)");
        }
        return false;
    }
    
    // Kiểm tra các tham số riêng của symbol nếu có
    if(m_adaptiveFilters != NULL) {
        SymbolParams* symbolParams = m_adaptiveFilters.GetSymbolParams(symbol);
        if(symbolParams != NULL && !symbolParams.isEnabled) {
            if(m_logger != NULL) m_logger.Debug("Trade not allowed for " + symbol + ": Symbol disabled in parameters");
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có đang ở chế độ khẩn cấp không                     |
//+------------------------------------------------------------------+
bool CRiskModule::IsEmergencyMode()
{
    if(m_riskManager != NULL) {
        return m_riskManager.IsInEmergencyMode();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cập nhật trạng thái rủi ro                                       |
//+------------------------------------------------------------------+
void CRiskModule::Update()
{
    // Cập nhật risk manager
    if(m_riskManager != NULL) {
        m_riskManager.Update();
    }
    
    // Cập nhật adaptive filters
    if(m_adaptiveFilters != NULL && m_core != NULL) {
        m_adaptiveFilters.Update(m_core);
        
        // Điều chỉnh tham số RiskManager từ AdaptiveFilters
        double riskPercent = m_adaptiveFilters.GetBaseRiskPercent(_Symbol);
        int maxTrades = m_adaptiveFilters.GetMaxTradesForRegime();
        
        if(m_riskManager != NULL) {
            m_riskManager.SetRiskPercent(riskPercent);
            m_riskManager.SetMaxTradesPerDay(maxTrades);
        }
    }
    
    // Cập nhật rủi ro tổng
    UpdateGlobalRisk();
}

//+------------------------------------------------------------------+
//| Cập nhật rủi ro tổng                                             |
//+------------------------------------------------------------------+
void CRiskModule::UpdateGlobalRisk()
{
    // Reset risk used
    m_totalRiskUsed = 0.0;
    
    int count = ArraySize(m_symbols);
    ArrayResize(m_symbolRiskUsed, count);
    
    // Tính toán rủi ro từ các lệnh đang chờ
    for(int i = 0; i < OrdersTotal(); i++) {
        if(OrderSelect(OrderGetTicket(i))) {
            string orderSymbol = OrderGetString(ORDER_SYMBOL);
            
            // Tìm kiếm vị trí của symbol trong mảng
            int symbolIndex = -1;
            for(int j = 0; j < count; j++) {
                if(m_symbols[j] == orderSymbol) {
                    symbolIndex = j;
                    break;
                }
            }
            
            if(symbolIndex >= 0) {
                // Lấy tham số riêng cho symbol
                double riskMultiplier = GetSymbolRiskMultiplier(orderSymbol);
                
                // Cộng dồn rủi ro
                m_symbolRiskUsed[symbolIndex] += m_maxRiskPercent * riskMultiplier;
                m_totalRiskUsed += m_maxRiskPercent * riskMultiplier;
            }
        }
    }
    
    // Cộng thêm rủi ro từ vị thế mở
    for(int i = 0; i < PositionsTotal(); i++) {
        if(PositionSelect(PositionGetTicket(i))) {
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            
            int symbolIndex = -1;
            for(int j = 0; j < count; j++) {
                if(m_symbols[j] == posSymbol) {
                    symbolIndex = j;
                    break;
                }
            }
            
            if(symbolIndex >= 0) {
                double riskMultiplier = GetSymbolRiskMultiplier(posSymbol);
                
                m_symbolRiskUsed[symbolIndex] += m_maxRiskPercent * riskMultiplier;
                m_totalRiskUsed += m_maxRiskPercent * riskMultiplier;
            }
        }
    }
    
    // Log cảnh báo nếu tổng rủi ro quá cao
    if(m_totalRiskUsed > m_totalRiskLimit) {
        static datetime lastRiskWarning = 0;
        if(TimeCurrent() - lastRiskWarning >= 600) { // Log mỗi 10 phút
            if(m_logger != NULL) {
                m_logger.Warning("Total risk used (" + DoubleToString(m_totalRiskUsed, 2) + 
                               "%) exceeds limit (" + DoubleToString(m_totalRiskLimit, 2) + "%)");
            }
            lastRiskWarning = TimeCurrent();
        }
    }
}

//+------------------------------------------------------------------+
//| Điều chỉnh theo chế độ thị trường                                |
//+------------------------------------------------------------------+
void CRiskModule::AdjustForMarketRegime()
{
    if(m_adaptiveFilters != NULL && m_core != NULL) {
        m_adaptiveFilters.Update(m_core);
    }
}

//+------------------------------------------------------------------+
//| Tính toán kích thước lệnh dựa trên rủi ro cho phép               |
//+------------------------------------------------------------------+
double CRiskModule::CalculateLotSize(double stopLossPips, string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_riskManager != NULL) {
        double riskPercent = GetBaseRiskPercent(symbol);
        return m_riskManager.CalculateLotSize(stopLossPips, riskPercent);
    }
    
    return 0.01; // Default mini lot
}

//+------------------------------------------------------------------+
//| Lấy hệ số rủi ro cho symbol                                      |
//+------------------------------------------------------------------+
double CRiskModule::GetSymbolRiskMultiplier(string symbol)
{
    if(m_adaptiveFilters != NULL) {
        SymbolParams* symbolParams = m_adaptiveFilters.GetSymbolParams(symbol);
        if(symbolParams != NULL) {
            return symbolParams.riskMultiplier;
        }
    }
    
    return 1.0; // Default multiplier
}

//+------------------------------------------------------------------+
//| Lấy phần trăm rủi ro cơ bản cho symbol                           |
//+------------------------------------------------------------------+
double CRiskModule::GetBaseRiskPercent(string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(m_adaptiveFilters != NULL) {
        return m_adaptiveFilters.GetBaseRiskPercent(symbol);
    }
    
    return m_maxRiskPercent;
}

//+------------------------------------------------------------------+
//| Thiết lập phần trăm rủi ro                                       |
//+------------------------------------------------------------------+
void CRiskModule::SetRiskPercent(double riskPercent)
{
    m_maxRiskPercent = riskPercent;
    
    if(m_riskManager != NULL) {
        m_riskManager.SetRiskPercent(riskPercent);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập số lệnh tối đa mỗi ngày                                 |
//+------------------------------------------------------------------+
void CRiskModule::SetMaxTradesPerDay(int maxTrades)
{
    if(m_riskManager != NULL) {
        m_riskManager.SetMaxTradesPerDay(maxTrades);
    }
}

//+------------------------------------------------------------------+
//| Lấy tỉ lệ R:R tối thiểu                                         |
//+------------------------------------------------------------------+
double CRiskModule::GetMinRR()
{
    if(m_adaptiveFilters != NULL) {
        return m_adaptiveFilters.GetMinRR();
    }
    
    return 1.5; // Default minimum R:R
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có nên dùng scout entries không                     |
//+------------------------------------------------------------------+
bool CRiskModule::ShouldUseScoutEntries()
{
    if(m_adaptiveFilters != NULL) {
        return m_adaptiveFilters.ShouldUseScoutEntries();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Lấy số dư tài khoản                                             |
//+------------------------------------------------------------------+
double CRiskModule::GetEquity()
{
    return AccountInfoDouble(ACCOUNT_EQUITY);
}

//+------------------------------------------------------------------+
//| Lấy drawdown hàng ngày                                          |
//+------------------------------------------------------------------+
double CRiskModule::GetDailyDrawdown()
{
    if(m_riskManager != NULL) {
        return m_riskManager.GetDailyDrawdown();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy tổng drawdown                                               |
//+------------------------------------------------------------------+
double CRiskModule::GetTotalDrawdown()
{
    if(m_riskManager != NULL) {
        return m_riskManager.GetTotalDrawdown();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy số lệnh giao dịch hôm nay                                    |
//+------------------------------------------------------------------+
int CRiskModule::GetTradesToday()
{
    if(m_riskManager != NULL) {
        return m_riskManager.GetTradesToday();
    }
    
    return 0;
} 