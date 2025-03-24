//+------------------------------------------------------------------+
//|                                         SonicR_System.mqh        |
//|                SonicR PropFirm EA - System Infrastructure Module |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Các thành phần gốc (được giữ trong file gốc)
#include "../SonicR_StateMachine.mqh"
#include "../SonicR_Logger.mqh"
#include "../SonicR_PropSettings.mqh"

//+------------------------------------------------------------------+
//| Lớp gom nhóm cho cơ sở hạ tầng hệ thống                          |
//+------------------------------------------------------------------+
class CSystem
{
private:
    // Các thành phần chính
    CStateMachine*  m_stateMachine;
    CLogger*        m_logger;
    CPropSettings*  m_propSettings;
    
    // Cấu hình
    string          m_eaName;
    int             m_magicNumber;
    bool            m_enableDetailedLogging;
    bool            m_saveLogsToFile;
    ENUM_PROP_FIRM  m_propFirmType;
    ENUM_CHALLENGE_PHASE m_challengePhase;
    bool            m_autoDetectPhase;
    double          m_customTargetProfit;
    double          m_customMaxDrawdown;
    double          m_customDailyDrawdown;
    datetime        m_challengeStartDate;
    int             m_challengeDaysTotal;
    
    // Trạng thái
    bool            m_shutdownRequested;
    
public:
    // Constructor/Destructor
    CSystem();
    ~CSystem();
    
    // Khởi tạo và thiết lập
    bool Initialize(const string eaName, int magicNumber, bool enableDetailedLogging, bool saveLogsToFile);
    void SetPropFirmSettings(ENUM_PROP_FIRM propFirmType, ENUM_CHALLENGE_PHASE challengePhase, bool autoDetectPhase);
    void SetCustomPropFirmValues(double targetProfit, double maxDrawdown, double dailyDrawdown);
    void SetChallengeTimeframe(datetime startDate, int daysTotal);
    
    // Quản lý trạng thái
    void TransitionTo(ENUM_EA_STATE newState, string reason);
    ENUM_EA_STATE GetCurrentState();
    void Update();
    
    // Quản lý hệ thống
    void RequestShutdown();
    bool IsShutdownRequested() { return m_shutdownRequested; }
    
    // Logging
    void LogInfo(string message);
    void LogWarning(string message);
    void LogError(string message);
    void LogDebug(string message);
    
    // Thông tin PropFirm
    double GetProgressPercent();
    bool IsTargetReached();
    string GetPropFirmName();
    string GetPhaseAsString();
    double GetCurrentProfit();
    double GetCurrentDrawdown();
    double GetDailyDrawdown();
    int GetRemainingDays();
    double GetTargetProfit();
    double GetMaxAllowedDrawdown();
    
    // Phương thức truy cập
    CStateMachine* GetStateMachine() { return m_stateMachine; }
    CLogger* GetLogger() { return m_logger; }
    CPropSettings* GetPropSettings() { return m_propSettings; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSystem::CSystem()
{
    m_stateMachine = NULL;
    m_logger = NULL;
    m_propSettings = NULL;
    
    m_eaName = "SonicR PropFirm";
    m_magicNumber = 234567;
    m_enableDetailedLogging = true;
    m_saveLogsToFile = true;
    m_propFirmType = PROP_FIRM_FTMO;
    m_challengePhase = PHASE_CHALLENGE;
    m_autoDetectPhase = true;
    m_customTargetProfit = 10.0;
    m_customMaxDrawdown = 10.0;
    m_customDailyDrawdown = 5.0;
    m_challengeStartDate = 0;
    m_challengeDaysTotal = 30;
    
    m_shutdownRequested = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CSystem::~CSystem()
{
    // Giải phóng bộ nhớ - chỉ xóa các đối tượng được tạo trong lớp này
    if(m_stateMachine != NULL) delete m_stateMachine;
    if(m_logger != NULL) delete m_logger;
    if(m_propSettings != NULL) delete m_propSettings;
}

//+------------------------------------------------------------------+
//| Khởi tạo các thành phần hệ thống                                 |
//+------------------------------------------------------------------+
bool CSystem::Initialize(const string eaName, int magicNumber, bool enableDetailedLogging, bool saveLogsToFile)
{
    m_eaName = eaName;
    m_magicNumber = magicNumber;
    m_enableDetailedLogging = enableDetailedLogging;
    m_saveLogsToFile = saveLogsToFile;
    
    // Khởi tạo logger trước để ghi log quá trình khởi tạo
    m_logger = new CLogger(eaName, magicNumber, enableDetailedLogging, saveLogsToFile);
    if(m_logger == NULL) {
        Print("ERROR: Failed to initialize Logger. Out of memory?");
        return false;
    }
    
    m_logger.Info("Initializing System module...");
    
    // Khởi tạo state machine
    m_stateMachine = new CStateMachine();
    if(m_stateMachine == NULL) {
        m_logger.Error("Failed to initialize StateMachine");
        return false;
    }
    
    // Khởi tạo PropFirm settings
    m_propSettings = new CPropSettings(m_propFirmType, m_challengePhase);
    if(m_propSettings == NULL) {
        m_logger.Error("Failed to initialize PropSettings");
        return false;
    }
    
    // Thiết lập phụ thuộc
    m_propSettings.SetLogger(m_logger);
    m_stateMachine.SetLogger(m_logger);
    
    // Set custom values if PropFirm type is CUSTOM
    if(m_propFirmType == PROP_FIRM_CUSTOM) {
        m_propSettings.SetCustomValues(m_customTargetProfit, m_customMaxDrawdown, m_customDailyDrawdown);
    }
    
    // Auto-detect phase if requested
    if(m_autoDetectPhase) {
        ENUM_CHALLENGE_PHASE detectedPhase = m_propSettings.AutoDetectPhase();
        if(detectedPhase != m_challengePhase) {
            m_logger.Warning("Auto-detected phase " + EnumToString(detectedPhase) + 
                            " differs from input parameter " + EnumToString(m_challengePhase));
            m_propSettings.SetPhase(detectedPhase);
        }
    }
    
    m_logger.Info("System module initialized successfully");
    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập cài đặt PropFirm                                       |
//+------------------------------------------------------------------+
void CSystem::SetPropFirmSettings(ENUM_PROP_FIRM propFirmType, ENUM_CHALLENGE_PHASE challengePhase, bool autoDetectPhase)
{
    m_propFirmType = propFirmType;
    m_challengePhase = challengePhase;
    m_autoDetectPhase = autoDetectPhase;
    
    if(m_propSettings != NULL) {
        m_propSettings.SetPropFirm(propFirmType);
        m_propSettings.SetPhase(challengePhase);
        
        // Set custom values if PropFirm type is CUSTOM
        if(propFirmType == PROP_FIRM_CUSTOM) {
            m_propSettings.SetCustomValues(m_customTargetProfit, m_customMaxDrawdown, m_customDailyDrawdown);
        }
        
        // Auto-detect phase if requested
        if(autoDetectPhase) {
            ENUM_CHALLENGE_PHASE detectedPhase = m_propSettings.AutoDetectPhase();
            if(detectedPhase != challengePhase) {
                if(m_logger != NULL) {
                    m_logger.Warning("Auto-detected phase " + EnumToString(detectedPhase) + 
                                    " differs from input parameter " + EnumToString(challengePhase));
                }
                m_propSettings.SetPhase(detectedPhase);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Thiết lập giá trị tuỳ chỉnh cho PropFirm                         |
//+------------------------------------------------------------------+
void CSystem::SetCustomPropFirmValues(double targetProfit, double maxDrawdown, double dailyDrawdown)
{
    m_customTargetProfit = targetProfit;
    m_customMaxDrawdown = maxDrawdown;
    m_customDailyDrawdown = dailyDrawdown;
    
    if(m_propSettings != NULL && m_propFirmType == PROP_FIRM_CUSTOM) {
        m_propSettings.SetCustomValues(targetProfit, maxDrawdown, dailyDrawdown);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập khung thời gian challenge                              |
//+------------------------------------------------------------------+
void CSystem::SetChallengeTimeframe(datetime startDate, int daysTotal)
{
    m_challengeStartDate = startDate;
    m_challengeDaysTotal = daysTotal;
    
    if(m_propSettings != NULL) {
        m_propSettings.SetChallengeTimeframe(startDate, daysTotal);
    }
}

//+------------------------------------------------------------------+
//| Chuyển trạng thái EA                                             |
//+------------------------------------------------------------------+
void CSystem::TransitionTo(ENUM_EA_STATE newState, string reason)
{
    if(m_stateMachine != NULL) {
        m_stateMachine.TransitionTo(newState, reason);
    }
}

//+------------------------------------------------------------------+
//| Lấy trạng thái hiện tại                                          |
//+------------------------------------------------------------------+
ENUM_EA_STATE CSystem::GetCurrentState()
{
    if(m_stateMachine != NULL) {
        return m_stateMachine.GetCurrentState();
    }
    
    return STATE_INITIALIZING; // Default nếu chưa khởi tạo
}

//+------------------------------------------------------------------+
//| Cập nhật các thành phần hệ thống                                 |
//+------------------------------------------------------------------+
void CSystem::Update()
{
    // Cập nhật state machine
    if(m_stateMachine != NULL) {
        m_stateMachine.Update();
    }
    
    // Cập nhật PropFirm settings
    if(m_propSettings != NULL) {
        m_propSettings.Update();
    }
}

//+------------------------------------------------------------------+
//| Yêu cầu shutdown EA                                              |
//+------------------------------------------------------------------+
void CSystem::RequestShutdown()
{
    m_shutdownRequested = true;
    
    if(m_logger != NULL) {
        m_logger.Warning("EA shutdown requested");
    }
}

//+------------------------------------------------------------------+
//| Ghi log thông tin                                                |
//+------------------------------------------------------------------+
void CSystem::LogInfo(string message)
{
    if(m_logger != NULL) {
        m_logger.Info(message);
    }
}

//+------------------------------------------------------------------+
//| Ghi log cảnh báo                                                 |
//+------------------------------------------------------------------+
void CSystem::LogWarning(string message)
{
    if(m_logger != NULL) {
        m_logger.Warning(message);
    }
}

//+------------------------------------------------------------------+
//| Ghi log lỗi                                                      |
//+------------------------------------------------------------------+
void CSystem::LogError(string message)
{
    if(m_logger != NULL) {
        m_logger.Error(message);
    }
}

//+------------------------------------------------------------------+
//| Ghi log debug                                                    |
//+------------------------------------------------------------------+
void CSystem::LogDebug(string message)
{
    if(m_logger != NULL) {
        m_logger.Debug(message);
    }
}

//+------------------------------------------------------------------+
//| Lấy phần trăm tiến độ                                            |
//+------------------------------------------------------------------+
double CSystem::GetProgressPercent()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetProgressPercent();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem đã đạt mục tiêu chưa                                |
//+------------------------------------------------------------------+
bool CSystem::IsTargetReached()
{
    if(m_propSettings != NULL) {
        return m_propSettings.IsTargetReached();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Lấy tên Prop Firm                                                |
//+------------------------------------------------------------------+
string CSystem::GetPropFirmName()
{
    if(m_propSettings != NULL) {
        return EnumToString(m_propSettings.GetPropFirm());
    }
    
    return "Unknown";
}

//+------------------------------------------------------------------+
//| Lấy tên giai đoạn                                                |
//+------------------------------------------------------------------+
string CSystem::GetPhaseAsString()
{
    if(m_propSettings != NULL) {
        return EnumToString(m_propSettings.GetPhase());
    }
    
    return "Unknown";
}

//+------------------------------------------------------------------+
//| Lấy lợi nhuận hiện tại                                           |
//+------------------------------------------------------------------+
double CSystem::GetCurrentProfit()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetCurrentProfit();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy drawdown hiện tại                                            |
//+------------------------------------------------------------------+
double CSystem::GetCurrentDrawdown()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetCurrentDrawdown();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy drawdown hàng ngày                                           |
//+------------------------------------------------------------------+
double CSystem::GetDailyDrawdown()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetDailyDrawdown();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy số ngày còn lại                                              |
//+------------------------------------------------------------------+
int CSystem::GetRemainingDays()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetRemainingDays();
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Lấy mục tiêu lợi nhuận                                           |
//+------------------------------------------------------------------+
double CSystem::GetTargetProfit()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetTargetProfit();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Lấy mức drawdown tối đa cho phép                                 |
//+------------------------------------------------------------------+
double CSystem::GetMaxAllowedDrawdown()
{
    if(m_propSettings != NULL) {
        return m_propSettings.GetMaxAllowedDrawdown();
    }
    
    return 0.0;
} 