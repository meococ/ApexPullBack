//+------------------------------------------------------------------+
//|                                    SonicR_StateMachine.mqh       |
//|              SonicR PropFirm EA - State Machine Component        |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"

// State machine for EA operation flow control
class CStateMachine
{
private:
    // Logger
    CLogger* m_logger;
    
    // State definition
    enum ENUM_EA_STATE
    {
        STATE_INITIALIZING,    // Initializing
        STATE_SCANNING,        // Scanning for signals
        STATE_WAITING,         // Waiting for entry conditions
        STATE_EXECUTING,       // Executing trade
        STATE_MONITORING,      // Monitoring open positions
        STATE_STOPPED          // EA stopped (emergency, error, etc.)
    };
    
    // State management
    ENUM_EA_STATE m_currentState;      // Current state
    ENUM_EA_STATE m_previousState;     // Previous state
    datetime m_stateEntryTime;         // Time when current state was entered
    datetime m_stateTimeout;           // Timeout for current state
    string m_stateReason;              // Reason for current state
    
    // Timeout settings
    int m_waitingTimeout;              // Timeout for waiting state (seconds)
    int m_executingTimeout;            // Timeout for executing state (seconds)
    
    // Helper methods
    string StateToString(ENUM_EA_STATE state) const;
    bool IsStateTimedOut() const;
    void HandleTimeout();
    
public:
    // Constructor
    CStateMachine();
    
    // Destructor
    ~CStateMachine();
    
    // Main methods
    void Update();
    void TransitionTo(ENUM_EA_STATE newState, string reason);
    bool IsInState(ENUM_EA_STATE state) const;
    
    // Getters
    ENUM_EA_STATE GetCurrentState() const { return m_currentState; }
    ENUM_EA_STATE GetPreviousState() const { return m_previousState; }
    datetime GetStateEntryTime() const { return m_stateEntryTime; }
    int GetTimeInState() const;
    string GetStateReason() const { return m_stateReason; }
    
    // Timeout settings
    void SetTimeout(ENUM_EA_STATE state, int seconds);
    void ClearTimeout();
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStateMachine::CStateMachine()
{
    m_logger = NULL;
    
    // Initialize state
    m_currentState = STATE_INITIALIZING;
    m_previousState = STATE_INITIALIZING;
    m_stateEntryTime = TimeCurrent();
    m_stateTimeout = 0;
    m_stateReason = "Initial state";
    
    // Set default timeouts
    m_waitingTimeout = 300;     // 5 minutes
    m_executingTimeout = 60;    // 1 minute
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CStateMachine::~CStateMachine()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Update state machine                                             |
//+------------------------------------------------------------------+
void CStateMachine::Update()
{
    // Check for state timeout
    if(IsStateTimedOut()) {
        HandleTimeout();
    }
}

//+------------------------------------------------------------------+
//| Transition to a new state                                        |
//+------------------------------------------------------------------+
void CStateMachine::TransitionTo(ENUM_EA_STATE newState, string reason)
{
    // Skip if same state
    if(newState == m_currentState) {
        return;
    }
    
    // Store previous state
    m_previousState = m_currentState;
    
    // Update current state
    m_currentState = newState;
    m_stateEntryTime = TimeCurrent();
    m_stateReason = reason;
    
    // Set timeout based on state
    switch(newState) {
        case STATE_WAITING:
            m_stateTimeout = TimeCurrent() + m_waitingTimeout;
            break;
            
        case STATE_EXECUTING:
            m_stateTimeout = TimeCurrent() + m_executingTimeout;
            break;
            
        default:
            m_stateTimeout = 0; // No timeout
            break;
    }
    
    // Log transition
    if(m_logger) {
        m_logger.Info("State transition: " + StateToString(m_previousState) + 
                    " -> " + StateToString(m_currentState) + 
                    " (" + reason + ")");
    }
}

//+------------------------------------------------------------------+
//| Check if current state matches specified state                   |
//+------------------------------------------------------------------+
bool CStateMachine::IsInState(ENUM_EA_STATE state) const
{
    return m_currentState == state;
}

//+------------------------------------------------------------------+
//| Get time spent in current state (seconds)                        |
//+------------------------------------------------------------------+
int CStateMachine::GetTimeInState() const
{
    return (int)(TimeCurrent() - m_stateEntryTime);
}

//+------------------------------------------------------------------+
//| Set timeout for a specific state                                 |
//+------------------------------------------------------------------+
void CStateMachine::SetTimeout(ENUM_EA_STATE state, int seconds)
{
    switch(state) {
        case STATE_WAITING:
            m_waitingTimeout = seconds;
            break;
            
        case STATE_EXECUTING:
            m_executingTimeout = seconds;
            break;
            
        default:
            // Other states don't have default timeouts
            break;
    }
    
    // Update current timeout if in this state
    if(m_currentState == state && seconds > 0) {
        m_stateTimeout = TimeCurrent() + seconds;
    }
}

//+------------------------------------------------------------------+
//| Clear timeout for current state                                  |
//+------------------------------------------------------------------+
void CStateMachine::ClearTimeout()
{
    m_stateTimeout = 0;
}

//+------------------------------------------------------------------+
//| Check if current state is timed out                              |
//+------------------------------------------------------------------+
bool CStateMachine::IsStateTimedOut() const
{
    return m_stateTimeout > 0 && TimeCurrent() >= m_stateTimeout;
}

//+------------------------------------------------------------------+
//| Handle state timeout                                             |
//+------------------------------------------------------------------+
void CStateMachine::HandleTimeout()
{
    if(m_logger) {
        m_logger.Warning("State timeout: " + StateToString(m_currentState) + 
                        " (" + IntegerToString(GetTimeInState()) + " seconds)");
    }
    
    // Default timeout handling based on state
    switch(m_currentState) {
        case STATE_WAITING:
            // Return to scanning if waiting times out
            TransitionTo(STATE_SCANNING, "Waiting timeout");
            break;
            
        case STATE_EXECUTING:
            // Go to scanning if execution times out
            TransitionTo(STATE_SCANNING, "Execution timeout");
            break;
            
        default:
            // Other states don't have default timeout handling
            break;
    }
}

//+------------------------------------------------------------------+
//| Convert state to string representation                           |
//+------------------------------------------------------------------+
string CStateMachine::StateToString(ENUM_EA_STATE state) const
{
    switch(state) {
        case STATE_INITIALIZING: return "Initializing";
        case STATE_SCANNING:     return "Scanning";
        case STATE_WAITING:      return "Waiting";
        case STATE_EXECUTING:    return "Executing";
        case STATE_MONITORING:   return "Monitoring";
        case STATE_STOPPED:      return "Stopped";
        default:                 return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CStateMachine::GetStatusText() const
{
    string status = "State Machine Status:\n";
    
    status += "Current State: " + StateToString(m_currentState) + "\n";
    status += "Previous State: " + StateToString(m_previousState) + "\n";
    status += "Time in State: " + IntegerToString(GetTimeInState()) + " seconds\n";
    status += "State Reason: " + m_stateReason + "\n";
    
    if(m_stateTimeout > 0) {
        int timeRemaining = (int)(m_stateTimeout - TimeCurrent());
        status += "Timeout in: " + IntegerToString(timeRemaining) + " seconds\n";
    }
    
    return status;
}