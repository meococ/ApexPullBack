//+------------------------------------------------------------------+
//|                                               PropSettings.mqh |
//|                            SonicR PropFirm EA - PropFirm Config |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef PROP_SETTINGS_MQH
#define PROP_SETTINGS_MQH

// PropFirm type enumeration
enum ENUM_PROP_FIRM
{
    PROP_FIRM_FTMO,        // FTMO
    PROP_FIRM_THE5ERS,     // The5ers
    PROP_FIRM_E8,          // E8 Funding
    PROP_FIRM_MYFOREX,     // MyForexFunds
    PROP_FIRM_CUSTOM       // Custom Settings
};

// Challenge phase enumeration
enum ENUM_CHALLENGE_PHASE
{
    PHASE_CHALLENGE,       // Challenge Phase
    PHASE_VERIFICATION,    // Verification Phase
    PHASE_FUNDED           // Funded Account
};

// PropFirm settings class
class CPropSettings
{
private:
    // PropFirm settings
    ENUM_PROP_FIRM m_propFirm;
    ENUM_CHALLENGE_PHASE m_challengePhase;
    
    // Challenge parameters
    double m_targetProfit;          // Target profit (%)
    int m_challengeDuration;        // Challenge duration (days)
    double m_maxDrawdown;           // Max drawdown (%)
    double m_maxDailyDrawdown;      // Max daily drawdown (%)
    int m_minTradingDays;           // Minimum trading days
    
    // Progress tracking
    datetime m_challengeStartDate;
    datetime m_challengeEndDate;
    double m_startingBalance;
    double m_currentBalance;
    double m_highestBalance;
    double m_lowestBalance;
    double m_currentProfit;
    double m_maxReachedDrawdown;
    
    // Helper methods
    void LoadPropFirmSettings();
    void LoadAccountInfo();
    void UpdateProgress();
    
public:
    // Constructor
    CPropSettings(ENUM_PROP_FIRM propFirm = PROP_FIRM_FTMO, 
                 ENUM_CHALLENGE_PHASE phase = PHASE_CHALLENGE);
    
    // Main methods
    void Update();
    ENUM_CHALLENGE_PHASE AutoDetectPhase();
    double GetChallengeProgress() const;
    int GetRemainingDays() const;
    bool IsOnTrackToPass() const;
    
    // Setting methods
    void SetPropFirm(ENUM_PROP_FIRM firm);
    void SetPhase(ENUM_CHALLENGE_PHASE phase);
    
    // Getters
    ENUM_PROP_FIRM GetPropFirm() const { return m_propFirm; }
    ENUM_CHALLENGE_PHASE GetPhase() const { return m_challengePhase; }
    double GetTargetProfit() const { return m_targetProfit; }
    double GetMaxDrawdown() const { return m_maxDrawdown; }
    double GetMaxDailyDrawdown() const { return m_maxDailyDrawdown; }
    int GetMinTradingDays() const { return m_minTradingDays; }
    int GetChallengeDuration() const { return m_challengeDuration; }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPropSettings::CPropSettings(ENUM_PROP_FIRM propFirm = PROP_FIRM_FTMO, 
                           ENUM_CHALLENGE_PHASE phase = PHASE_CHALLENGE)
{
    // Initialize settings
    m_propFirm = propFirm;
    m_challengePhase = phase;
    
    // Load settings for selected PropFirm
    LoadPropFirmSettings();
    
    // Load account info
    LoadAccountInfo();
    
    // Update progress
    UpdateProgress();
}

//+------------------------------------------------------------------+
//| Load settings for the selected PropFirm                          |
//+------------------------------------------------------------------+
void CPropSettings::LoadPropFirmSettings()
{
    // Default values
    m_targetProfit = 10.0;
    m_challengeDuration = 30;
    m_maxDrawdown = 10.0;
    m_maxDailyDrawdown = 5.0;
    m_minTradingDays = 10;
    
    // Adjust based on PropFirm
    switch(m_propFirm) {
        case PROP_FIRM_FTMO:
            // Standard FTMO Challenge settings
            if(m_challengePhase == PHASE_CHALLENGE) {
                m_targetProfit = 10.0;
                m_challengeDuration = 30;
                m_maxDrawdown = 10.0;
                m_maxDailyDrawdown = 5.0;
                m_minTradingDays = 10;
            }
            // FTMO Verification settings
            else if(m_challengePhase == PHASE_VERIFICATION) {
                m_targetProfit = 5.0;
                m_challengeDuration = 60;
                m_maxDrawdown = 10.0;
                m_maxDailyDrawdown = 5.0;
                m_minTradingDays = 10;
            }
            // FTMO Funded settings
            else {
                m_targetProfit = 0.0; // No target
                m_challengeDuration = 0; // No duration
                m_maxDrawdown = 10.0;
                m_maxDailyDrawdown = 5.0;
                m_minTradingDays = 0;
            }
            break;
            
        case PROP_FIRM_THE5ERS:
            // The5ers Phase 1 settings
            if(m_challengePhase == PHASE_CHALLENGE) {
                m_targetProfit = 8.0;
                m_challengeDuration = 0; // No time limit
                m_maxDrawdown = 4.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 0;
            }
            // The5ers Phase 2 settings
            else if(m_challengePhase == PHASE_VERIFICATION) {
                m_targetProfit = 5.0;
                m_challengeDuration = 0; // No time limit
                m_maxDrawdown = 4.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 0;
            }
            // The5ers Funded settings
            else {
                m_targetProfit = 0.0; // No target
                m_challengeDuration = 0; // No duration
                m_maxDrawdown = 5.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 0;
            }
            break;
            
        case PROP_FIRM_E8:
            // E8 Evaluation settings
            if(m_challengePhase == PHASE_CHALLENGE) {
                m_targetProfit = 8.0;
                m_challengeDuration = 0; // No strict time limit
                m_maxDrawdown = 8.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 5;
            }
            // E8 Verification settings
            else if(m_challengePhase == PHASE_VERIFICATION) {
                m_targetProfit = 5.0;
                m_challengeDuration = 0; // No strict time limit
                m_maxDrawdown = 8.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 5;
            }
            // E8 Funded settings
            else {
                m_targetProfit = 0.0; // No target
                m_challengeDuration = 0; // No duration
                m_maxDrawdown = 8.0;
                m_maxDailyDrawdown = 4.0;
                m_minTradingDays = 0;
            }
            break;
            
        case PROP_FIRM_MYFOREX:
            // MyForexFunds Evaluation settings
            if(m_challengePhase == PHASE_CHALLENGE) {
                m_targetProfit = 10.0;
                m_challengeDuration = 30;
                m_maxDrawdown = 12.0;
                m_maxDailyDrawdown = 6.0;
                m_minTradingDays = 0;
            }
            // MyForexFunds Verification settings
            else if(m_challengePhase == PHASE_VERIFICATION) {
                m_targetProfit = 5.0;
                m_challengeDuration = 60;
                m_maxDrawdown = 12.0;
                m_maxDailyDrawdown = 6.0;
                m_minTradingDays = 0;
            }
            // MyForexFunds Funded settings
            else {
                m_targetProfit = 0.0; // No target
                m_challengeDuration = 0; // No duration
                m_maxDrawdown = 12.0;
                m_maxDailyDrawdown = 6.0;
                m_minTradingDays = 0;
            }
            break;
            
        case PROP_FIRM_CUSTOM:
            // Keep default values or they can be set manually
            break;
    }
}

//+------------------------------------------------------------------+
//| Load account information                                         |
//+------------------------------------------------------------------+
void CPropSettings::LoadAccountInfo()
{
    // Get account info
    m_currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    m_startingBalance = m_currentBalance; // Estimate starting balance
    m_highestBalance = m_currentBalance;
    m_lowestBalance = m_currentBalance;
    
    // Estimate challenge dates
    m_challengeStartDate = TimeCurrent();
    
    if(m_challengeDuration > 0) {
        m_challengeEndDate = m_challengeStartDate + m_challengeDuration * 86400; // days to seconds
    } else {
        m_challengeEndDate = 0; // No end date
    }
}

//+------------------------------------------------------------------+
//| Update progress tracking                                         |
//+------------------------------------------------------------------+
void CPropSettings::UpdateProgress()
{
    // Get current account info
    m_currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Update highest/lowest balance
    if(m_currentBalance > m_highestBalance) {
        m_highestBalance = m_currentBalance;
    }
    
    if(m_currentBalance < m_lowestBalance) {
        m_lowestBalance = m_currentBalance;
    }
    
    // Calculate current profit
    m_currentProfit = (m_currentBalance - m_startingBalance) / m_startingBalance * 100.0;
    
    // Calculate max drawdown reached
    m_maxReachedDrawdown = (m_highestBalance - m_lowestBalance) / m_highestBalance * 100.0;
}

//+------------------------------------------------------------------+
//| Update PropFirm settings                                         |
//+------------------------------------------------------------------+
void CPropSettings::Update()
{
    // Update progress tracking
    UpdateProgress();
}

//+------------------------------------------------------------------+
//| Try to auto-detect challenge phase based on account              |
//+------------------------------------------------------------------+
ENUM_CHALLENGE_PHASE CPropSettings::AutoDetectPhase()
{
    // This is a simplified detection logic and might not work for all accounts
    // In a real implementation, this would use account characteristics, comments,
    // or naming conventions specific to each PropFirm
    
    // Get account info
    string accountName = AccountInfoString(ACCOUNT_NAME);
    string accountCompany = AccountInfoString(ACCOUNT_COMPANY);
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Check FTMO pattern
    if(StringFind(accountName, "FTMO") >= 0 || StringFind(accountCompany, "FTMO") >= 0) {
        if(StringFind(accountName, "Challenge") >= 0) {
            return PHASE_CHALLENGE;
        } else if(StringFind(accountName, "Verification") >= 0) {
            return PHASE_VERIFICATION;
        } else {
            return PHASE_FUNDED;
        }
    }
    
    // Check The5ers pattern
    if(StringFind(accountName, "5ers") >= 0 || StringFind(accountCompany, "5ers") >= 0) {
        if(StringFind(accountName, "Stage 1") >= 0) {
            return PHASE_CHALLENGE;
        } else if(StringFind(accountName, "Stage 2") >= 0) {
            return PHASE_VERIFICATION;
        } else {
            return PHASE_FUNDED;
        }
    }
    
    // Generic detection based on account age
    // Get account creation time (this is not reliable in MT5, just an example)
    datetime accountCreation = TimeCurrent() - (30 * 86400); // Placeholder
    int accountAgeInDays = (int)((TimeCurrent() - accountCreation) / 86400);
    
    if(accountAgeInDays < 30) {
        return PHASE_CHALLENGE;
    } else if(accountAgeInDays < 90) {
        return PHASE_VERIFICATION;
    } else {
        return PHASE_FUNDED;
    }
}

//+------------------------------------------------------------------+
//| Get challenge progress (0-100%)                                  |
//+------------------------------------------------------------------+
double CPropSettings::GetChallengeProgress() const
{
    // If no target profit, return current profit percentage
    if(m_targetProfit <= 0) {
        return 100.0;
    }
    
    // Calculate progress towards target
    double progress = (m_currentProfit / m_targetProfit) * 100.0;
    
    // Cap progress at 100%
    return MathMin(100.0, MathMax(0.0, progress));
}

//+------------------------------------------------------------------+
//| Get remaining days in challenge                                  |
//+------------------------------------------------------------------+
int CPropSettings::GetRemainingDays() const
{
    // If no end date, return 0
    if(m_challengeEndDate == 0) {
        return 0;
    }
    
    // Calculate remaining days
    int remainingDays = (int)((m_challengeEndDate - TimeCurrent()) / 86400);
    
    // Ensure non-negative
    return MathMax(0, remainingDays);
}

//+------------------------------------------------------------------+
//| Check if challenge is on track to pass                           |
//+------------------------------------------------------------------+
bool CPropSettings::IsOnTrackToPass() const
{
    // Check if profit target is met
    if(m_currentProfit >= m_targetProfit) {
        return true;
    }
    
    // Check if trending towards target
    int remainingDays = GetRemainingDays();
    
    if(remainingDays > 0 && m_challengeDuration > 0) {
        // Calculate daily profit needed
        double elapsedDays = m_challengeDuration - remainingDays;
        
        if(elapsedDays > 0) {
            double dailyProfitRate = m_currentProfit / elapsedDays;
            double projectedProfit = dailyProfitRate * m_challengeDuration;
            
            return projectedProfit >= m_targetProfit;
        }
    }
    
    // Not enough data to determine
    return false;
}

//+------------------------------------------------------------------+
//| Set PropFirm type                                                |
//+------------------------------------------------------------------+
void CPropSettings::SetPropFirm(ENUM_PROP_FIRM firm)
{
    // Set new PropFirm
    m_propFirm = firm;
    
    // Reload settings
    LoadPropFirmSettings();
}

//+------------------------------------------------------------------+
//| Set challenge phase                                              |
//+------------------------------------------------------------------+
void CPropSettings::SetPhase(ENUM_CHALLENGE_PHASE phase)
{
    // Set new phase
    m_challengePhase = phase;
    
    // Reload settings
    LoadPropFirmSettings();
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CPropSettings::GetStatusText() const
{
    string status = "PropFirm Settings:\n";
    
    // PropFirm and phase
    status += "PropFirm: ";
    switch(m_propFirm) {
        case PROP_FIRM_FTMO: status += "FTMO"; break;
        case PROP_FIRM_THE5ERS: status += "The5ers"; break;
        case PROP_FIRM_E8: status += "E8 Funding"; break;
        case PROP_FIRM_MYFOREX: status += "MyForexFunds"; break;
        case PROP_FIRM_CUSTOM: status += "Custom Settings"; break;
    }
    status += "\n";
    
    status += "Phase: ";
    switch(m_challengePhase) {
        case PHASE_CHALLENGE: status += "Challenge"; break;
        case PHASE_VERIFICATION: status += "Verification"; break;
        case PHASE_FUNDED: status += "Funded"; break;
    }
    status += "\n";
    
    // Challenge parameters
    status += "Target Profit: " + DoubleToString(m_targetProfit, 1) + "%\n";
    status += "Max Drawdown: " + DoubleToString(m_maxDrawdown, 1) + "%\n";
    status += "Max Daily DD: " + DoubleToString(m_maxDailyDrawdown, 1) + "%\n";
    
    if(m_challengeDuration > 0) {
        status += "Duration: " + IntegerToString(m_challengeDuration) + " days\n";
        status += "Remaining: " + IntegerToString(GetRemainingDays()) + " days\n";
    } else {
        status += "Duration: No time limit\n";
    }
    
    if(m_minTradingDays > 0) {
        status += "Min Trading Days: " + IntegerToString(m_minTradingDays) + "\n";
    }
    
    // Progress
    status += "Current Profit: " + DoubleToString(m_currentProfit, 2) + "%\n";
    status += "Progress: " + DoubleToString(GetChallengeProgress(), 1) + "%\n";
    status += "Max DD Reached: " + DoubleToString(m_maxReachedDrawdown, 2) + "%\n";
    status += "On Track: " + (IsOnTrackToPass() ? "Yes" : "No") + "\n";
    
    return status;
}

#endif // PROP_SETTINGS_MQH