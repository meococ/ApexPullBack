//+------------------------------------------------------------------+
//|                                               SessionFilter.mqh |
//|                          SonicR PropFirm EA - Session Filtering |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef SESSION_FILTER_MQH
#define SESSION_FILTER_MQH

// Trading session filter class
class CSessionFilter
{
private:
    // Session settings
    bool m_enableLondon;              // Enable London session
    bool m_enableNewYork;             // Enable New York session
    bool m_enableOverlap;             // Enable London-NY overlap
    bool m_enableAsian;               // Enable Asian session
    int m_fridayEndHour;              // Hour to end trading on Friday (GMT)
    
    bool m_enableCustomHours;         // Enable custom trading hours
    int m_customStartHour;            // Custom start hour (GMT)
    int m_customEndHour;              // Custom end hour (GMT)
    
    // Day of week settings
    bool m_allowMonday;               // Allow trading on Monday
    bool m_allowFriday;               // Allow trading on Friday
    
    // GMT offset
    int m_brokerGMTOffset;            // Broker's GMT offset
    
    // Helper methods
    bool IsLondonSession(int hour) const;
    bool IsNewYorkSession(int hour) const;
    bool IsAsianSession(int hour) const;
    bool IsOverlapSession(int hour) const;
    bool IsCustomSession(int hour) const;
    int GetGMTHour() const;
    int GetCurrentHour() const;
    int GetCurrentDayOfWeek() const;
    
public:
    // Constructor
    CSessionFilter(bool enableLondon = true,
                  bool enableNewYork = true,
                  bool enableOverlap = true,
                  bool enableAsian = false,
                  int fridayEndHour = 16,
                  bool allowMonday = true,
                  bool allowFriday = true,
                  bool enableCustomHours = false,
                  int customStartHour = 8,
                  int customEndHour = 17);
    
    // Main methods
    bool IsTradingAllowed() const;
    double GetSessionQuality() const;
    
    // Setters
    void SetSessionSettings(bool london, bool newYork, bool overlap, bool asian) {
        m_enableLondon = london;
        m_enableNewYork = newYork;
        m_enableOverlap = overlap;
        m_enableAsian = asian;
    }
    
    void SetFridaySettings(bool allowFriday, int endHour) {
        m_allowFriday = allowFriday;
        m_fridayEndHour = endHour;
    }
    
    void SetCustomHours(bool enable, int startHour, int endHour) {
        m_enableCustomHours = enable;
        m_customStartHour = startHour;
        m_customEndHour = endHour;
    }
    
    // Getters
    string GetCurrentSessionName() const;
    bool IsInLondonSession() const { return IsLondonSession(GetCurrentHour()); }
    bool IsInNewYorkSession() const { return IsNewYorkSession(GetCurrentHour()); }
    bool IsInAsianSession() const { return IsAsianSession(GetCurrentHour()); }
    bool IsInOverlapSession() const { return IsOverlapSession(GetCurrentHour()); }
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CSessionFilter::CSessionFilter(bool enableLondon = true,
                             bool enableNewYork = true,
                             bool enableOverlap = true,
                             bool enableAsian = false,
                             int fridayEndHour = 16,
                             bool allowMonday = true,
                             bool allowFriday = true,
                             bool enableCustomHours = false,
                             int customStartHour = 8,
                             int customEndHour = 17)
{
    // Initialize session settings
    m_enableLondon = enableLondon;
    m_enableNewYork = enableNewYork;
    m_enableOverlap = enableOverlap;
    m_enableAsian = enableAsian;
    m_fridayEndHour = fridayEndHour;
    
    // Initialize day settings
    m_allowMonday = allowMonday;
    m_allowFriday = allowFriday;
    
    // Initialize custom hours
    m_enableCustomHours = enableCustomHours;
    m_customStartHour = customStartHour;
    m_customEndHour = customEndHour;
    
    // Determine broker GMT offset
    m_brokerGMTOffset = 0; // Default GMT
    
    // Calculate GMT offset from broker server time
    datetime serverTime = TimeTradeServer();
    datetime gmtTime = TimeGMT();
    
    // Calculate difference in hours
    m_brokerGMTOffset = (int)((serverTime - gmtTime) / 3600);
}

//+------------------------------------------------------------------+
//| Check if trading is allowed in current session                   |
//+------------------------------------------------------------------+
bool CSessionFilter::IsTradingAllowed() const
{
    // Get current time info
    int currentHour = GetCurrentHour();
    int dayOfWeek = GetCurrentDayOfWeek();
    
    // Check day of week restrictions
    if(dayOfWeek == 1 && !m_allowMonday) {
        return false;
    }
    
    if(dayOfWeek == 5 && !m_allowFriday) {
        return false;
    }
    
    // Check Friday end hour
    if(dayOfWeek == 5 && currentHour >= m_fridayEndHour) {
        return false;
    }
    
    // Check if custom hours are enabled
    if(m_enableCustomHours) {
        return IsCustomSession(currentHour);
    }
    
    // Check regular sessions
    if(m_enableLondon && IsLondonSession(currentHour)) {
        return true;
    }
    
    if(m_enableNewYork && IsNewYorkSession(currentHour)) {
        return true;
    }
    
    if(m_enableOverlap && IsOverlapSession(currentHour)) {
        return true;
    }
    
    if(m_enableAsian && IsAsianSession(currentHour)) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get session quality (0-100)                                      |
//+------------------------------------------------------------------+
double CSessionFilter::GetSessionQuality() const
{
    // Get current time info
    int currentHour = GetCurrentHour();
    int dayOfWeek = GetCurrentDayOfWeek();
    
    // Base quality is 50
    double quality = 50.0;
    
    // Adjust for day of week
    if(dayOfWeek == 1) { // Monday
        quality -= 10.0; // Lower quality for Monday
    } else if(dayOfWeek == 3) { // Wednesday
        quality += 10.0; // Higher quality for middle of week
    } else if(dayOfWeek == 5) { // Friday
        quality -= 15.0; // Lower quality for Friday
        
        // Extra penalty for late Friday
        if(currentHour >= m_fridayEndHour - 2) {
            quality -= 20.0;
        }
    }
    
    // Adjust for session
    if(IsOverlapSession(currentHour)) {
        quality += 30.0; // Highest quality for overlap
    } else if(IsLondonSession(currentHour)) {
        quality += 20.0; // High quality for London
    } else if(IsNewYorkSession(currentHour)) {
        quality += 15.0; // Good quality for NY
    } else if(IsAsianSession(currentHour)) {
        quality -= 5.0; // Lower quality for Asian
    } else {
        quality -= 20.0; // Lowest quality for off-hours
    }
    
    // Cap quality between 0 and 100
    return MathMax(0.0, MathMin(100.0, quality));
}

//+------------------------------------------------------------------+
//| Check if current hour is in London session                       |
//+------------------------------------------------------------------+
bool CSessionFilter::IsLondonSession(int hour) const
{
    // London hours: 8:00-16:00 GMT
    return (hour >= 8 && hour < 16);
}

//+------------------------------------------------------------------+
//| Check if current hour is in New York session                     |
//+------------------------------------------------------------------+
bool CSessionFilter::IsNewYorkSession(int hour) const
{
    // New York hours: 13:00-21:00 GMT
    return (hour >= 13 && hour < 21);
}

//+------------------------------------------------------------------+
//| Check if current hour is in Asian session                        |
//+------------------------------------------------------------------+
bool CSessionFilter::IsAsianSession(int hour) const
{
    // Asian hours: 0:00-8:00 GMT
    return (hour >= 0 && hour < 8);
}

//+------------------------------------------------------------------+
//| Check if current hour is in London-NY overlap                    |
//+------------------------------------------------------------------+
bool CSessionFilter::IsOverlapSession(int hour) const
{
    // Overlap hours: 13:00-16:00 GMT
    return (hour >= 13 && hour < 16);
}

//+------------------------------------------------------------------+
//| Check if current hour is in custom session                       |
//+------------------------------------------------------------------+
bool CSessionFilter::IsCustomSession(int hour) const
{
    // Handle case where end hour is less than start hour (session spans midnight)
    if(m_customEndHour < m_customStartHour) {
        return (hour >= m_customStartHour || hour < m_customEndHour);
    }
    
    // Normal case
    return (hour >= m_customStartHour && hour < m_customEndHour);
}

//+------------------------------------------------------------------+
//| Get current GMT hour                                            |
//+------------------------------------------------------------------+
int CSessionFilter::GetGMTHour() const
{
    MqlDateTime gmtTime;
    TimeToStruct(TimeGMT(), gmtTime);
    
    return gmtTime.hour;
}

//+------------------------------------------------------------------+
//| Get current hour (broker time)                                   |
//+------------------------------------------------------------------+
int CSessionFilter::GetCurrentHour() const
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    return time.hour;
}

//+------------------------------------------------------------------+
//| Get current day of week (1-7, Monday=1)                          |
//+------------------------------------------------------------------+
int CSessionFilter::GetCurrentDayOfWeek() const
{
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    return time.day_of_week;
}

//+------------------------------------------------------------------+
//| Get name of current session                                      |
//+------------------------------------------------------------------+
string CSessionFilter::GetCurrentSessionName() const
{
    int currentHour = GetCurrentHour();
    
    if(IsOverlapSession(currentHour)) {
        return "London-NY Overlap";
    } else if(IsLondonSession(currentHour)) {
        return "London";
    } else if(IsNewYorkSession(currentHour)) {
        return "New York";
    } else if(IsAsianSession(currentHour)) {
        return "Asian";
    } else {
        return "Off Hours";
    }
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CSessionFilter::GetStatusText() const
{
    string status = "Session Filter Status:\n";
    
    // Current time info
    MqlDateTime time;
    TimeToStruct(TimeCurrent(), time);
    
    status += "Current Time: " + TimeToString(TimeCurrent(), TIME_MINUTES) + " (" + 
             IntegerToString(time.hour) + ":" + IntegerToString(time.min) + ")\n";
    
    status += "Day of Week: ";
    switch(time.day_of_week) {
        case 0: status += "Sunday"; break;
        case 1: status += "Monday"; break;
        case 2: status += "Tuesday"; break;
        case 3: status += "Wednesday"; break;
        case 4: status += "Thursday"; break;
        case 5: status += "Friday"; break;
        case 6: status += "Saturday"; break;
    }
    status += "\n";
    
    // Current session
    status += "Current Session: " + GetCurrentSessionName() + "\n";
    
    // Session quality
    status += "Session Quality: " + DoubleToString(GetSessionQuality(), 1) + "%\n";
    
    // Trading allowed
    status += "Trading Allowed: " + (IsTradingAllowed() ? "Yes" : "NO") + "\n";
    
    // Enabled sessions
    status += "Enabled Sessions: ";
    if(m_enableCustomHours) {
        status += "Custom Hours (" + IntegerToString(m_customStartHour) + 
                 "-" + IntegerToString(m_customEndHour) + " GMT)";
    } else {
        if(m_enableLondon) status += "London ";
        if(m_enableNewYork) status += "New York ";
        if(m_enableOverlap) status += "Overlap ";
        if(m_enableAsian) status += "Asian ";
    }
    status += "\n";
    
    // Day restrictions
    status += "Day Restrictions: ";
    if(!m_allowMonday) status += "No Monday ";
    if(!m_allowFriday) status += "No Friday ";
    if(m_allowFriday && m_fridayEndHour < 21) {
        status += "Friday until " + IntegerToString(m_fridayEndHour) + ":00";
    }
    if(m_allowMonday && m_allowFriday && m_fridayEndHour >= 21) {
        status += "None";
    }
    status += "\n";
    
    return status;
}

#endif // SESSION_FILTER_MQH