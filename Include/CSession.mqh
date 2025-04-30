//+------------------------------------------------------------------+
//| CSession.mqh - Manages trading sessions and optimal trading times |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

// Forward declaration
class CLogger;

//+------------------------------------------------------------------+
//| CSession Class - Manages trading sessions and optimal times       |
//+------------------------------------------------------------------+
class CSession {
private:
    // Session settings
    int m_gmtOffset;                   // GMT offset for broker server time
    bool m_useSessionFilter;           // Whether to use session filter
    
    // Session time definitions
    int m_asianStart;                  // Asian session start hour (GMT)
    int m_asianEnd;                    // Asian session end hour (GMT)
    int m_londonStart;                 // London session start hour (GMT)
    int m_londonEnd;                   // London session end hour (GMT)
    int m_nyStart;                     // NY session start hour (GMT)
    int m_nyEnd;                       // NY session end hour (GMT)
    
    // Symbol session preferences
    bool m_asianPreferredPairs[28];    // Symbols that trade best in Asian session
    bool m_londonPreferredPairs[28];   // Symbols that trade best in London session
    bool m_nyPreferredPairs[28];       // Symbols that trade best in NY session
    string m_monitoredSymbols[28];     // List of all monitored symbols
    
    // Logger
    CLogger* m_logger;                 // Logger reference
    
    //--- Private methods
    
    // Initialize symbol preferences
    void InitializeSymbolPreferences() {
        // List of major and minor pairs we monitor
        string symbols[] = {
            "EURUSD", "GBPUSD", "USDJPY", "USDCHF", "AUDUSD", "USDCAD", "NZDUSD",
            "EURJPY", "GBPJPY", "AUDJPY", "NZDJPY", "CHFJPY", "CADJPY", 
            "EURGBP", "EURAUD", "EURCHF", "EURCAD", "EURNZD",
            "GBPAUD", "GBPCAD", "GBPCHF", "GBPNZD",
            "AUDCAD", "AUDCHF", "AUDNZD", 
            "CADCHF", "NZDCAD", "NZDCHF"
        };
        
        // Copy to monitored symbols
        int count = ArraySize(symbols);
        ArrayResize(m_monitoredSymbols, count);
        
        for (int i = 0; i < count; i++) {
            m_monitoredSymbols[i] = symbols[i];
            
            // Initialize all preferences to false
            m_asianPreferredPairs[i] = false;
            m_londonPreferredPairs[i] = false;
            m_nyPreferredPairs[i] = false;
        }
        
        // Set Asian session preferred pairs
        SetAsianPreferred("USDJPY", true);
        SetAsianPreferred("EURJPY", true);
        SetAsianPreferred("GBPJPY", true);
        SetAsianPreferred("AUDJPY", true);
        SetAsianPreferred("NZDJPY", true);
        SetAsianPreferred("CHFJPY", true);
        SetAsianPreferred("CADJPY", true);
        SetAsianPreferred("AUDUSD", true);
        SetAsianPreferred("NZDUSD", true);
        SetAsianPreferred("AUDNZD", true);
        
        // Set London session preferred pairs
        SetLondonPreferred("EURGBP", true);
        SetLondonPreferred("GBPUSD", true);
        SetLondonPreferred("EURUSD", true);
        SetLondonPreferred("USDCHF", true);
        SetLondonPreferred("GBPCHF", true);
        SetLondonPreferred("EURCHF", true);
        SetLondonPreferred("EURJPY", true);
        SetLondonPreferred("GBPJPY", true);
        SetLondonPreferred("GBPAUD", true);
        SetLondonPreferred("GBPCAD", true);
        SetLondonPreferred("GBPNZD", true);
        
        // Set NY session preferred pairs
        SetNYPreferred("EURUSD", true);
        SetNYPreferred("GBPUSD", true);
        SetNYPreferred("USDCAD", true);
        SetNYPreferred("AUDUSD", true);
        SetNYPreferred("NZDUSD", true);
        SetNYPreferred("EURCAD", true);
        SetNYPreferred("GBPCAD", true);
        SetNYPreferred("AUDCAD", true);
        SetNYPreferred("NZDCAD", true);
    }
    
    // Set a pair as preferred for Asian session
    void SetAsianPreferred(string symbol, bool preferred) {
        for (int i = 0; i < ArraySize(m_monitoredSymbols); i++) {
            if (m_monitoredSymbols[i] == symbol) {
                m_asianPreferredPairs[i] = preferred;
                return;
            }
        }
    }
    
    // Set a pair as preferred for London session
    void SetLondonPreferred(string symbol, bool preferred) {
        for (int i = 0; i < ArraySize(m_monitoredSymbols); i++) {
            if (m_monitoredSymbols[i] == symbol) {
                m_londonPreferredPairs[i] = preferred;
                return;
            }
        }
    }
    
    // Set a pair as preferred for NY session
    void SetNYPreferred(string symbol, bool preferred) {
        for (int i = 0; i < ArraySize(m_monitoredSymbols); i++) {
            if (m_monitoredSymbols[i] == symbol) {
                m_nyPreferredPairs[i] = preferred;
                return;
            }
        }
    }
    
    // Check if a symbol is preferred for a given session
    bool IsPreferredForSession(string symbol, ENUM_TRADING_SESSION session) {
        for (int i = 0; i < ArraySize(m_monitoredSymbols); i++) {
            if (m_monitoredSymbols[i] == symbol) {
                switch (session) {
                    case SESSION_ASIAN:
                        return m_asianPreferredPairs[i];
                    case SESSION_LONDON:
                        return m_londonPreferredPairs[i];
                    case SESSION_NEWYORK:
                        return m_nyPreferredPairs[i];
                    case SESSION_OVERLAP:
                        // Overlap is good for all
                        return true;
                    default:
                        return false;
                }
            }
        }
        
        // If symbol not found in monitored list, just return true
        return true;
    }
    
    // Check if current hour is in Asian session
    bool IsAsianSession(int gmtHour) const {
        return (gmtHour >= m_asianStart && gmtHour < m_asianEnd);
    }
    
    // Check if current hour is in London session
    bool IsLondonSession(int gmtHour) const {
        return (gmtHour >= m_londonStart && gmtHour < m_londonEnd);
    }
    
    // Check if current hour is in NY session
    bool IsNYSession(int gmtHour) const {
        return (gmtHour >= m_nyStart && gmtHour < m_nyEnd);
    }
    
    // Check if current hour is in London-NY overlap
    bool IsOverlapSession(int gmtHour) const {
        return (gmtHour >= m_londonStart && gmtHour < m_londonEnd && 
                gmtHour >= m_nyStart && gmtHour < m_nyEnd);
    }
    
    // Get current session
    ENUM_TRADING_SESSION GetCurrentSession() const {
        // Get current GMT hour
        datetime serverTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(serverTime, timeStruct);
        int serverHour = timeStruct.hour;
        
        // Convert to GMT
        int gmtHour = (serverHour - m_gmtOffset) % 24;
        if (gmtHour < 0) gmtHour += 24;
        
        // Check sessions in priority order
        if (IsOverlapSession(gmtHour)) return SESSION_OVERLAP;
        if (IsLondonSession(gmtHour)) return SESSION_LONDON;
        if (IsNYSession(gmtHour)) return SESSION_NEWYORK;
        if (IsAsianSession(gmtHour)) return SESSION_ASIAN;
        
        return SESSION_OFF_HOURS;
    }
    
public:
    // Constructor
    CSession(int gmtOffset = DEFAULT_GMT_OFFSET) {
        // Set GMT offset
        m_gmtOffset = gmtOffset;
        
        // Set session filter flag
        m_useSessionFilter = true;
        
        // Set default session times (GMT)
        m_asianStart = 0;      // 00:00 GMT
        m_asianEnd = 9;        // 09:00 GMT
        m_londonStart = 8;     // 08:00 GMT
        m_londonEnd = 16;      // 16:00 GMT
        m_nyStart = 13;        // 13:00 GMT
        m_nyEnd = 21;          // 21:00 GMT
        
        // Initialize symbol preferences
        InitializeSymbolPreferences();
        
        // Set logger to NULL initially
        m_logger = NULL;
    }
    
    // Set GMT offset
    void SetGMTOffset(int offset) {
        m_gmtOffset = offset;
    }
    
    // Set session filter usage
    void SetUseSessionFilter(bool use) {
        m_useSessionFilter = use;
    }
    
    // Set Asian session hours
    void SetAsianSession(int start, int end) {
        m_asianStart = start;
        m_asianEnd = end;
    }
    
    // Set London session hours
    void SetLondonSession(int start, int end) {
        m_londonStart = start;
        m_londonEnd = end;
    }
    
    // Set NY session hours
    void SetNYSession(int start, int end) {
        m_nyStart = start;
        m_nyEnd = end;
    }
    
    // Set logger reference
    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }
    
    // Check if current time is optimal for trading
    bool IsOptimalTradingTime(string symbol) const {
        // Skip check if filter disabled
        if (!m_useSessionFilter) return true;
        
        // Get current session
        ENUM_TRADING_SESSION currentSession = GetCurrentSession();
        
        // Check if in off-hours
        if (currentSession == SESSION_OFF_HOURS) {
            if (m_logger != NULL) {
                m_logger.Debug("Current time is outside main trading sessions");
            }
            return false;
        }
        
        // Check if symbol is preferred for current session
        bool isPreferred = const_cast<CSession*>(this).IsPreferredForSession(symbol, currentSession);
        
        // Overlap session is good for all pairs
        if (currentSession == SESSION_OVERLAP) {
            return true;
        }
        
        // Log session status
        if (m_logger != NULL && !isPreferred) {
            string sessionName;
            switch (currentSession) {
                case SESSION_ASIAN: sessionName = "Asian"; break;
                case SESSION_LONDON: sessionName = "London"; break;
                case SESSION_NEWYORK: sessionName = "New York"; break;
                default: sessionName = "Unknown"; break;
            }
            
            m_logger.Debug(symbol + " is not optimal for current " + sessionName + " session");
        }
        
        return isPreferred;
    }
    
    // Check if current time is high risk (e.g., end of week)
    bool IsHighRiskTime() const {
        // Get current time
        datetime serverTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(serverTime, timeStruct);
        
        // Check for Friday after 20:00 GMT
        if (timeStruct.day_of_week == 5) { // Friday
            int serverHour = timeStruct.hour;
            int gmtHour = (serverHour - m_gmtOffset) % 24;
            if (gmtHour < 0) gmtHour += 24;
            
            if (gmtHour >= 20) {
                if (m_logger != NULL) {
                    m_logger.Warning("High risk time: Friday after 20:00 GMT");
                }
                return true;
            }
        }
        
        // Check for Sunday/Monday first few hours
        if (timeStruct.day_of_week == 0 || // Sunday
            (timeStruct.day_of_week == 1 && timeStruct.hour < 3)) { // Monday early hours
            if (m_logger != NULL) {
                m_logger.Warning("High risk time: Market opening hours");
            }
            return true;
        }
        
        return false;
    }
    
    // Get the current trading session
    string GetCurrentSessionName() const {
        ENUM_TRADING_SESSION session = GetCurrentSession();
        
        switch (session) {
            case SESSION_ASIAN:
                return "Asian";
            case SESSION_LONDON:
                return "London";
            case SESSION_NEWYORK:
                return "New York";
            case SESSION_OVERLAP:
                return "London-NY Overlap";
            default:
                return "Off Hours";
        }
    }
};