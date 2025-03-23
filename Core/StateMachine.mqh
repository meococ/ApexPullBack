//+------------------------------------------------------------------+
//|                                               StateMachine.mqh |
//|                          SonicR PropFirm EA - State Management |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef STATE_MACHINE_MQH
#define STATE_MACHINE_MQH

// EA state enumeration
enum ENUM_EA_STATE
{
    STATE_INITIALIZING,    // EA is initializing
    STATE_SCANNING,        // Scanning for new signals
    STATE_WAITING,         // Signal detected, waiting for entry conditions
    STATE_EXECUTING,       // Executing trade
    STATE_MONITORING,      // Monitoring open positions
    STATE_STOPPED          // EA is stopped (emergency, error, etc.)
};

// Class for managing EA state transitions
class CStateMachine
{
private:
    // Current state
    ENUM_EA_STATE m_currentState;
    datetime m_stateStartTime;
    string m_stateReason;
    
    // State timeouts (in seconds)
    int m_waitingTimeout;
    int m_executingTimeout;
    
    // State history
    struct StateTransition {
        ENUM_EA_STATE fromState;
        ENUM_EA_STATE toState;
        datetime time;
        string reason;
    };
    
    StateTransition m_stateHistory[20];
    int m_historyCount;
    
    // Helper methods
    void AddToHistory(ENUM_EA_STATE fromState, ENUM_EA_STATE toState, string reason);
    bool IsStateTimedOut();
    bool IsValidTransition(ENUM_EA_STATE fromState, ENUM_EA_STATE toState);
    
public:
    // Constructor
    CStateMachine(int waitingTimeout = 300, int executingTimeout = 60);
    
    // State management
    void Update();
    void TransitionTo(ENUM_EA_STATE newState, string reason);
    
    // Getters
    ENUM_EA_STATE GetCurrentState() const { return m_currentState; }
    datetime GetStateStartTime() const { return m_stateStartTime; }
    string GetStateReason() const { return m_stateReason; }
    int GetStateTimeElapsed() const { return (int)(TimeCurrent() - m_stateStartTime); }
    
    // State string
    string StateToString(ENUM_EA_STATE state) const;
    
    // Status text
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CStateMachine::CStateMachine(int waitingTimeout = 300, int executingTimeout = 60)
{
    // Initialize state
    m_currentState = STATE_INITIALIZING;
    m_stateStartTime = TimeCurrent();
    m_stateReason = "EA starting";
    
    // Initialize timeouts
    m_waitingTimeout = waitingTimeout;
    m_executingTimeout = executingTimeout;
    
    // Initialize history
    m_historyCount = 0;
    
    // Add initial state to history
    AddToHistory(STATE_INITIALIZING, STATE_INITIALIZING, "Initial state");
}

//+------------------------------------------------------------------+
//| Update state machine                                             |
//+------------------------------------------------------------------+
void CStateMachine::Update()
{
    // Check for state timeout
    if(IsStateTimedOut()) {
        switch(m_currentState) {
            case STATE_WAITING:
                TransitionTo(STATE_SCANNING, "Waiting timeout");
                break;
                
            case STATE_EXECUTING:
                TransitionTo(STATE_SCANNING, "Execution timeout");
                break;
        }
    }
}

//+------------------------------------------------------------------+
//| Transition to a new state                                        |
//+------------------------------------------------------------------+
void CStateMachine::TransitionTo(ENUM_EA_STATE newState, string reason)
{
    // Check if transition is valid
    if(!IsValidTransition(m_currentState, newState)) {
        Print("WARNING: Invalid state transition from ", StateToString(m_currentState), 
              " to ", StateToString(newState), ". Reason: ", reason);
        return;
    }
    
    // Save previous state
    ENUM_EA_STATE oldState = m_currentState;
    
    // Update state
    m_currentState = newState;
    m_stateStartTime = TimeCurrent();
    m_stateReason = reason;
    
    // Add to history
    AddToHistory(oldState, newState, reason);
    
    // Log state transition
    Print("State transition: ", StateToString(oldState), " -> ", StateToString(newState), 
          ". Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Add state transition to history                                  |
//+------------------------------------------------------------------+
void CStateMachine::AddToHistory(ENUM_EA_STATE fromState, ENUM_EA_STATE toState, string reason)
{
    // Shift history if full
    if(m_historyCount >= ArraySize(m_stateHistory)) {
        for(int i = 0; i < ArraySize(m_stateHistory) - 1; i++) {
            m_stateHistory[i] = m_stateHistory[i+1];
        }
        m_historyCount = ArraySize(m_stateHistory) - 1;
    }
    
    // Add new transition
    m_stateHistory[m_historyCount].fromState = fromState;
    m_stateHistory[m_historyCount].toState = toState;
    m_stateHistory[m_historyCount].time = TimeCurrent();
    m_stateHistory[m_historyCount].reason = reason;
    
    // Increment count
    m_historyCount++;
}

//+------------------------------------------------------------------+
//| Check if current state has timed out                             |
//+------------------------------------------------------------------+
bool CStateMachine::IsStateTimedOut()
{
    // Get time in current state
    int timeInState = GetStateTimeElapsed();
    
    // Check timeout based on state
    switch(m_currentState) {
        case STATE_WAITING:
            return timeInState > m_waitingTimeout;
            
        case STATE_EXECUTING:
            return timeInState > m_executingTimeout;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if state transition is valid                               |
//+------------------------------------------------------------------+
bool CStateMachine::IsValidTransition(ENUM_EA_STATE fromState, ENUM_EA_STATE toState)
{
    // Valid transitions:
    // INITIALIZING -> SCANNING
    // SCANNING -> WAITING, STOPPED
    // WAITING -> EXECUTING, SCANNING, STOPPED
    // EXECUTING -> MONITORING, SCANNING, STOPPED
    // MONITORING -> SCANNING, WAITING, STOPPED
    // STOPPED -> SCANNING
    
    switch(fromState) {
        case STATE_INITIALIZING:
            return toState == STATE_SCANNING;
            
        case STATE_SCANNING:
            return toState == STATE_WAITING || toState == STATE_STOPPED;
            
        case STATE_WAITING:
            return toState == STATE_EXECUTING || toState == STATE_SCANNING || toState == STATE_STOPPED;
            
        case STATE_EXECUTING:
            return toState == STATE_MONITORING || toState == STATE_SCANNING || toState == STATE_STOPPED;
            
        case STATE_MONITORING:
            return toState == STATE_SCANNING || toState == STATE_WAITING || toState == STATE_STOPPED;
            
        case STATE_STOPPED:
            return toState == STATE_SCANNING;
    }
    
    return false;
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
    
    // Current state
    status += "Current State: " + StateToString(m_currentState) + "\n";
    status += "Reason: " + m_stateReason + "\n";
    status += "Time in State: " + IntegerToString(GetStateTimeElapsed()) + " seconds\n";
    
    // Recent history
    status += "Recent Transitions:\n";
    int historyToShow = MathMin(3, m_historyCount);
    for(int i = m_historyCount - historyToShow; i < m_historyCount; i++) {
        MqlDateTime transitionTime;
        TimeToStruct(m_stateHistory[i].time, transitionTime);
        
        status += "  " + TimeToString(m_stateHistory[i].time, TIME_MINUTES) + ": ";
        status += StateToString(m_stateHistory[i].fromState) + " -> ";
        status += StateToString(m_stateHistory[i].toState) + " (" + m_stateHistory[i].reason + ")\n";
    }
    
    return status;
}

#endif // STATE_MACHINE_MQH