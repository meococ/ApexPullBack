//+------------------------------------------------------------------+
//|                                             SonicR_Filters.mqh |
//|                SonicR PropFirm EA - Market Filters Component   |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"
#include "SonicR_Core.mqh"

//+------------------------------------------------------------------+
//| Session filter class for trading hours management                |
//+------------------------------------------------------------------+
class CSessionFilter
{
private:
    // Logger
    CLogger* m_logger;
    
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
    
    // Quality threshold
    double m_qualityThreshold;        // Session quality threshold (0-100)
    
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
                  bool allowFriday = true);
    
    // Destructor
    ~CSessionFilter();
    
    // Main methods
    bool IsTradingAllowed() const;
    double GetSessionQuality() const;
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
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
    
    void SetQualityThreshold(double threshold) {
        m_qualityThreshold = threshold;
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
//| News filter class to avoid trading during news events            |
//+------------------------------------------------------------------+
class CNewsFilter
{
private:
    // Logger
    CLogger* m_logger;
    
    // News event structure
    struct NewsEvent {
        datetime time;           // Event time
        string currency;         // Currency affected
        string title;            // Event title
        int impact;              // Impact level (1=low, 2=medium, 3=high)
        bool isPending;          // Is event pending
    };
    
    // Settings
    bool m_useFilter;           // Enable news filter
    int m_minutesBefore;        // Minutes before news
    int m_minutesAfter;         // Minutes after news
    bool m_highImpactOnly;      // Filter high impact only
    
    // News data
    NewsEvent m_upcomingEvents[20];  // Upcoming events
    int m_eventCount;                // Number of events
    datetime m_lastUpdate;           // Last update time
    
    // Helper methods
    void UpdateNewsData();
    bool DoesEventAffectSymbol(const NewsEvent &event, string symbol);
    string GetCurrenciesFromSymbol(string symbol);
    bool IsCurrencyInSymbol(string currency, string symbol);
    
public:
    // Constructor
    CNewsFilter(bool useFilter = true, 
               int minutesBefore = 30, 
               int minutesAfter = 15, 
               bool highImpactOnly = true);
    
    // Destructor
    ~CNewsFilter();
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Main methods
    bool IsNewsTime();
    int GetMinutesUntilNextNews();
    NewsEvent GetNextNewsEvent();
    
    // Settings
    void EnableFilter(bool enable) { m_useFilter = enable; }
    void SetTimeWindow(int minutesBefore, int minutesAfter) {
        m_minutesBefore = minutesBefore;
        m_minutesAfter = minutesAfter;
    }
    void SetHighImpactOnly(bool highImpactOnly) { m_highImpactOnly = highImpactOnly; }
    
    // News info
    string GetUpcomingNewsInfo();
    bool HasHighImpactNews();
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Market regime filter to detect market conditions                 |
//+------------------------------------------------------------------+
class CMarketRegimeFilter
{
private:
    // Logger
    CLogger* m_logger;
    
    // Market regime types
    enum ENUM_MARKET_REGIME
    {
        REGIME_BULLISH,          // Bullish trending
        REGIME_BEARISH,          // Bearish trending
        REGIME_RANGING,          // Range-bound
        REGIME_VOLATILE          // Volatile/choppy
    };
    
    // Settings
    bool m_useFilter;            // Use market regime filter
    bool m_tradeBullish;         // Trade in bullish regime
    bool m_tradeBearish;         // Trade in bearish regime
    bool m_tradeRanging;         // Trade in ranging regime
    bool m_tradeVolatile;        // Trade in volatile regime
    
    // Current regime
    ENUM_MARKET_REGIME m_currentRegime;
    
    // Analytics
    double m_adxThreshold;        // ADX threshold for trend detection
    double m_volatilityThreshold; // Volatility threshold for regime detection
    
    // Helper methods
    double CalculateVolatilityRatio();
    double CalculateADXStrength();
    bool IsInUptrend(CSonicRCore* core);
    bool IsInDowntrend(CSonicRCore* core);
    
public:
    // Constructor
    CMarketRegimeFilter();
    
    // Destructor
    ~CMarketRegimeFilter();
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Configuration
    void Configure(bool useFilter, bool bullish, bool bearish, bool ranging, bool volatile_market);
    
    // Main methods
    void Update(CSonicRCore* core);
    bool IsRegimeFavorable() const;
    
    // Getters
    ENUM_MARKET_REGIME GetCurrentRegime() const { return m_currentRegime; }
    string GetCurrentRegimeAsString() const;
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor for Session Filter                                   |
//+------------------------------------------------------------------+
CSessionFilter::CSessionFilter(bool enableLondon,
                             bool enableNewYork,
                             bool enableOverlap,
                             bool enableAsian,
                             int fridayEndHour,
                             bool allowMonday,
                             bool allowFriday)
{
    m_logger = NULL;
    
    // Initialize session settings
    m_enableLondon = enableLondon;
    m_enableNewYork = enableNewYork;
    m_enableOverlap = enableOverlap;
    m_enableAsian = enableAsian;
    m_fridayEndHour = fridayEndHour;
    
    // Initialize day settings
    m_allowMonday = allowMonday;
    m_allowFriday = allowFriday;
    
    // Initialize custom hours (disabled by default)
    m_enableCustomHours = false;
    m_customStartHour = 8;
    m_customEndHour = 17;
    
    // Initialize session quality threshold
    m_qualityThreshold = 60.0;
    
    // Determine broker GMT offset
    m_brokerGMTOffset = 0; // Default GMT
    
    // Calculate GMT offset from broker server time
    datetime serverTime = TimeTradeServer();
    datetime gmtTime = TimeGMT();
    
    // Calculate difference in hours
    m_brokerGMTOffset = (int)((serverTime - gmtTime) / 3600);
}

//+------------------------------------------------------------------+
//| Destructor for Session Filter                                    |
//+------------------------------------------------------------------+
CSessionFilter::~CSessionFilter()
{
    // Nothing to clean up
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
        if(m_logger) m_logger.Debug("Trading not allowed: Monday trading disabled");
        return false;
    }
    
    if(dayOfWeek == 5 && !m_allowFriday) {
        if(m_logger) m_logger.Debug("Trading not allowed: Friday trading disabled");
        return false;
    }
    
    // Check Friday end hour
    if(dayOfWeek == 5 && currentHour >= m_fridayEndHour) {
        if(m_logger) m_logger.Debug("Trading not allowed: After Friday end hour (" + 
                                   IntegerToString(m_fridayEndHour) + ":00)");
        return false;
    }
    
    // Check session quality
    double quality = GetSessionQuality();
    if(quality < m_qualityThreshold) {
        if(m_logger) m_logger.Debug("Trading not allowed: Session quality (" + 
                                   DoubleToString(quality, 1) + "%) below threshold (" + 
                                   DoubleToString(m_qualityThreshold, 1) + "%)");
        return false;
    }
    
    // Check if custom hours are enabled
    if(m_enableCustomHours) {
        if(!IsCustomSession(currentHour)) {
            if(m_logger) m_logger.Debug("Trading not allowed: Outside custom hours (" + 
                                       IntegerToString(m_customStartHour) + ":00-" + 
                                       IntegerToString(m_customEndHour) + ":00)");
            return false;
        }
        return true;
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
    
    if(m_logger) m_logger.Debug("Trading not allowed: Outside enabled sessions");
    return false;
}

//+------------------------------------------------------------------+
//| Get session quality (0-100 points)                               |
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

//+------------------------------------------------------------------+
//| Constructor for News Filter                                      |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter(bool useFilter, 
                       int minutesBefore, 
                       int minutesAfter, 
                       bool highImpactOnly)
{
    m_logger = NULL;
    
    // Initialize settings
    m_useFilter = useFilter;
    m_minutesBefore = minutesBefore;
    m_minutesAfter = minutesAfter;
    m_highImpactOnly = highImpactOnly;
    
    // Initialize news data
    m_eventCount = 0;
    m_lastUpdate = 0;
    
    // Update news data
    UpdateNewsData();
}

//+------------------------------------------------------------------+
//| Destructor for News Filter                                       |
//+------------------------------------------------------------------+
CNewsFilter::~CNewsFilter()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Update news data                                                 |
//+------------------------------------------------------------------+
void CNewsFilter::UpdateNewsData()
{
    // Reset event count
    m_eventCount = 0;
    
    // Store current time
    datetime currentTime = TimeCurrent();
    
    // Check if update is needed (every 30 minutes)
    if(currentTime - m_lastUpdate < 1800 && m_lastUpdate > 0) {
        return;
    }
    
    if(m_logger) m_logger.Debug("Updating news data");
    
    // In a real implementation, this would fetch data from a news API
    // or parse a local XML/CSV file with news events
    
    // For this example, we'll add some hardcoded events
    datetime today = currentTime;
    
    // Add a simulated upcoming high impact event
    if(m_eventCount < ArraySize(m_upcomingEvents)) {
        m_upcomingEvents[m_eventCount].time = today + 3600; // 1 hour from now
        m_upcomingEvents[m_eventCount].currency = "USD";
        m_upcomingEvents[m_eventCount].title = "US Non-Farm Payrolls";
        m_upcomingEvents[m_eventCount].impact = 3; // High impact
        m_upcomingEvents[m_eventCount].isPending = true;
        m_eventCount++;
    }
    
    // Add another simulated medium impact event
    if(m_eventCount < ArraySize(m_upcomingEvents)) {
        m_upcomingEvents[m_eventCount].time = today + 7200; // 2 hours from now
        m_upcomingEvents[m_eventCount].currency = "EUR";
        m_upcomingEvents[m_eventCount].title = "ECB President Speech";
        m_upcomingEvents[m_eventCount].impact = 2; // Medium impact
        m_upcomingEvents[m_eventCount].isPending = true;
        m_eventCount++;
    }
    
    // Add another simulated low impact event
    if(m_eventCount < ArraySize(m_upcomingEvents)) {
        m_upcomingEvents[m_eventCount].time = today + 10800; // 3 hours from now
        m_upcomingEvents[m_eventCount].currency = "GBP";
        m_upcomingEvents[m_eventCount].title = "UK Manufacturing PMI";
        m_upcomingEvents[m_eventCount].impact = 1; // Low impact
        m_upcomingEvents[m_eventCount].isPending = true;
        m_eventCount++;
    }
    
    // Update last update time
    m_lastUpdate = currentTime;
    
    if(m_logger) m_logger.Debug("Found " + IntegerToString(m_eventCount) + " upcoming news events");
}

//+------------------------------------------------------------------+
//| Check if current time is near news event                         |
//+------------------------------------------------------------------+
bool CNewsFilter::IsNewsTime()
{
    // If filter is disabled, always allow trading
    if(!m_useFilter) {
        return false;
    }
    
    // Update news data if needed
    UpdateNewsData();
    
    // Get current time
    datetime currentTime = TimeCurrent();
    
    // Check all upcoming events
    for(int i = 0; i < m_eventCount; i++) {
        // Skip low/medium impact if only high impact is selected
        if(m_highImpactOnly && m_upcomingEvents[i].impact < 3) {
            continue;
        }
        
        // Check if event is for current symbol
        if(!DoesEventAffectSymbol(m_upcomingEvents[i], _Symbol)) {
            continue;
        }
        
        // Calculate time difference in seconds
        long timeDiff = (long)(m_upcomingEvents[i].time - currentTime);
        
        // Check if within time window
        if(timeDiff >= -m_minutesAfter * 60 && timeDiff <= m_minutesBefore * 60) {
            if(m_logger) {
                if(timeDiff > 0) {
                    m_logger.Debug("News event coming: " + m_upcomingEvents[i].title + 
                                  " in " + IntegerToString(timeDiff / 60) + " minutes");
                } else {
                    m_logger.Debug("News event active: " + m_upcomingEvents[i].title + 
                                  " " + IntegerToString(MathAbs(timeDiff) / 60) + " minutes ago");
                }
            }
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get minutes until next news event                                |
//+------------------------------------------------------------------+
int CNewsFilter::GetMinutesUntilNextNews()
{
    // Update news data if needed
    UpdateNewsData();
    
    // Get current time
    datetime currentTime = TimeCurrent();
    
    // Initialize to a large value
    int minMinutes = 99999;
    
    // Check all upcoming events
    for(int i = 0; i < m_eventCount; i++) {
        // Skip low/medium impact if only high impact is selected
        if(m_highImpactOnly && m_upcomingEvents[i].impact < 3) {
            continue;
        }
        
        // Check if event is for current symbol
        if(!DoesEventAffectSymbol(m_upcomingEvents[i], _Symbol)) {
            continue;
        }
        
        // Calculate time difference in minutes
        int timeDiff = (int)((m_upcomingEvents[i].time - currentTime) / 60);
        
        // Check if this is the closest event
        if(timeDiff > 0 && timeDiff < minMinutes) {
            minMinutes = timeDiff;
        }
    }
    
    return (minMinutes == 99999) ? 0 : minMinutes;
}

//+------------------------------------------------------------------+
//| Get next news event                                              |
//+------------------------------------------------------------------+
CNewsFilter::NewsEvent CNewsFilter::GetNextNewsEvent()
{
    // Update news data if needed
    UpdateNewsData();
    
    // Get current time
    datetime currentTime = TimeCurrent();
    
    // Initialize event time to a large value
    datetime nextEventTime = D'2099.12.31 23:59:59';
    int nextEventIndex = -1;
    
    // Find the closest upcoming event
    for(int i = 0; i < m_eventCount; i++) {
        // Skip low/medium impact if only high impact is selected
        if(m_highImpactOnly && m_upcomingEvents[i].impact < 3) {
            continue;
        }
        
        // Check if event is for current symbol
        if(!DoesEventAffectSymbol(m_upcomingEvents[i], _Symbol)) {
            continue;
        }
        
        // Check if this is the closest event
        if(m_upcomingEvents[i].time > currentTime && m_upcomingEvents[i].time < nextEventTime) {
            nextEventTime = m_upcomingEvents[i].time;
            nextEventIndex = i;
        }
    }
    
    // Return empty event if none found
    NewsEvent emptyEvent;
    emptyEvent.time = 0;
    emptyEvent.currency = "";
    emptyEvent.title = "";
    emptyEvent.impact = 0;
    emptyEvent.isPending = false;
    
    return (nextEventIndex >= 0) ? m_upcomingEvents[nextEventIndex] : emptyEvent;
}

//+------------------------------------------------------------------+
//| Check if event affects symbol                                    |
//+------------------------------------------------------------------+
bool CNewsFilter::DoesEventAffectSymbol(const NewsEvent &event, string symbol)
{
    // Get currencies in symbol
    string currencies = GetCurrenciesFromSymbol(symbol);
    
    // Check if event currency is in symbol
    return IsCurrencyInSymbol(event.currency, symbol);
}

//+------------------------------------------------------------------+
//| Extract currencies from symbol name                              |
//+------------------------------------------------------------------+
string CNewsFilter::GetCurrenciesFromSymbol(string symbol)
{
    // Remove any non-currency parts of the symbol (like broker prefixes)
    string cleanSymbol = symbol;
    
    // Common forex pair format is XXXYYY
    if(StringLen(cleanSymbol) >= 6) {
        string baseCurrency = StringSubstr(cleanSymbol, 0, 3);
        string quoteCurrency = StringSubstr(cleanSymbol, 3, 3);
        
        return baseCurrency + "," + quoteCurrency;
    }
    
    return "";
}

//+------------------------------------------------------------------+
//| Check if currency is in symbol                                   |
//+------------------------------------------------------------------+
bool CNewsFilter::IsCurrencyInSymbol(string currency, string symbol)
{
    // Check for currency in symbol
    return (StringFind(symbol, currency) >= 0);
}

//+------------------------------------------------------------------+
//| Get information about upcoming news                              |
//+------------------------------------------------------------------+
string CNewsFilter::GetUpcomingNewsInfo()
{
    // Update news data if needed
    UpdateNewsData();
    
    string info = "Upcoming News Events:\n";
    
    // Get current time
    datetime currentTime = TimeCurrent();
    
    // Counter for events shown
    int eventsShown = 0;
    
    // Check all upcoming events
    for(int i = 0; i < m_eventCount; i++) {
        // Skip past events
        if(m_upcomingEvents[i].time < currentTime) {
            continue;
        }
        
        // Skip low/medium impact if only high impact is selected
        if(m_highImpactOnly && m_upcomingEvents[i].impact < 3) {
            continue;
        }
        
        // Add event info
        string impactStr = "";
        switch(m_upcomingEvents[i].impact) {
            case 1: impactStr = "Low"; break;
            case 2: impactStr = "Medium"; break;
            case 3: impactStr = "High"; break;
        }
        
        info += TimeToString(m_upcomingEvents[i].time, TIME_MINUTES) + " - " +
               m_upcomingEvents[i].currency + " - " +
               m_upcomingEvents[i].title + " (" + impactStr + ")\n";
        
        eventsShown++;
        
        // Limit to 5 events
        if(eventsShown >= 5) {
            break;
        }
    }
    
    if(eventsShown == 0) {
        info += "No upcoming events";
    }
    
    return info;
}

//+------------------------------------------------------------------+
//| Check if there are high impact news upcoming                     |
//+------------------------------------------------------------------+
bool CNewsFilter::HasHighImpactNews()
{
    // Update news data if needed
    UpdateNewsData();
    
    // Get current time
    datetime currentTime = TimeCurrent();
    
    // Check upcoming events
    for(int i = 0; i < m_eventCount; i++) {
        // Skip past events
        if(m_upcomingEvents[i].time < currentTime) {
            continue;
        }
        
        // Check if high impact
        if(m_upcomingEvents[i].impact == 3) {
            // Check if event is for current symbol
            if(DoesEventAffectSymbol(m_upcomingEvents[i], _Symbol)) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CNewsFilter::GetStatusText() const
{
    string status = "News Filter Status:\n";
    
    // Filter settings
    status += "Filter Enabled: " + (m_useFilter ? "Yes" : "No") + "\n";
    status += "Time Window: " + IntegerToString(m_minutesBefore) + " min before, " +
             IntegerToString(m_minutesAfter) + " min after\n";
    status += "High Impact Only: " + (m_highImpactOnly ? "Yes" : "No") + "\n";
    
    // Current state
    CNewsFilter* self = (CNewsFilter*)GetPointer(this);
    status += "Currently in News Time: " + (self.IsNewsTime() ? "YES" : "No") + "\n";
    
    // Upcoming events
    int minutesUntilNext = self.GetMinutesUntilNextNews();
    
    if(minutesUntilNext > 0) {
        status += "Next News: " + IntegerToString(minutesUntilNext) + " minutes\n";
        
        NewsEvent nextEvent = self.GetNextNewsEvent();
        if(nextEvent.time > 0) {
            string impactStr = "";
            switch(nextEvent.impact) {
                case 1: impactStr = "Low"; break;
                case 2: impactStr = "Medium"; break;
                case 3: impactStr = "High"; break;
            }
            
            status += "Next Event: " + TimeToString(nextEvent.time, TIME_MINUTES) + " - " +
                     nextEvent.currency + " - " + nextEvent.title + " (" + impactStr + ")\n";
        }
    } else {
        status += "No upcoming events detected\n";
    }
    
    return status;
}

//+------------------------------------------------------------------+
//| Constructor for Market Regime Filter                             |
//+------------------------------------------------------------------+
CMarketRegimeFilter::CMarketRegimeFilter()
{
    m_logger = NULL;
    
    // Initialize settings
    m_useFilter = true;
    m_tradeBullish = true;
    m_tradeBearish = true;
    m_tradeRanging = true;
    m_tradeVolatile = false;
    
    // Initialize regime
    m_currentRegime = REGIME_RANGING;
    
    // Initialize analytics
    m_adxThreshold = 25.0;
    m_volatilityThreshold = 1.5;
}

//+------------------------------------------------------------------+
//| Destructor for Market Regime Filter                              |
//+------------------------------------------------------------------+
CMarketRegimeFilter::~CMarketRegimeFilter()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Configure filter settings                                        |
//+------------------------------------------------------------------+
void CMarketRegimeFilter::Configure(bool useFilter, 
                                  bool bullish, 
                                  bool bearish, 
                                  bool ranging, 
                                  bool volatile_market)
{
    m_useFilter = useFilter;
    m_tradeBullish = bullish;
    m_tradeBearish = bearish;
    m_tradeRanging = ranging;
    m_tradeVolatile = volatile_market;
    
    if(m_logger) {
        m_logger.Info("Market Regime Filter configured - Trading in: " + 
                     (m_tradeBullish ? "Bullish, " : "") + 
                     (m_tradeBearish ? "Bearish, " : "") + 
                     (m_tradeRanging ? "Ranging, " : "") + 
                     (m_tradeVolatile ? "Volatile" : ""));
    }
}

//+------------------------------------------------------------------+
//| Update market regime detection                                   |
//+------------------------------------------------------------------+
void CMarketRegimeFilter::Update(CSonicRCore* core)
{
    // Store previous regime
    ENUM_MARKET_REGIME prevRegime = m_currentRegime;
    
    // Calculate ADX strength (trend strength)
    double adxStrength = CalculateADXStrength();
    
    // Calculate volatility ratio
    double volatilityRatio = CalculateVolatilityRatio();
    
    // Get trend direction from core
    bool isUptrend = IsInUptrend(core);
    bool isDowntrend = IsInDowntrend(core);
    
    // Determine current regime
    if(adxStrength > m_adxThreshold) {
        // Strong trend
        if(isUptrend) {
            m_currentRegime = REGIME_BULLISH;
        } else if(isDowntrend) {
            m_currentRegime = REGIME_BEARISH;
        } else {
            // ADX is high but trend direction unclear
            m_currentRegime = REGIME_VOLATILE;
        }
    } else {
        // Weak trend
        if(volatilityRatio > m_volatilityThreshold) {
            m_currentRegime = REGIME_VOLATILE;
        } else {
            m_currentRegime = REGIME_RANGING;
        }
    }
    
    // Log regime change
    if(prevRegime != m_currentRegime && m_logger) {
        m_logger.Info("Market regime changed from " + GetRegimeName(prevRegime) + 
                     " to " + GetRegimeName(m_currentRegime));
    }
}

//+------------------------------------------------------------------+
//| Check if current regime is favorable for trading                 |
//+------------------------------------------------------------------+
bool CMarketRegimeFilter::IsRegimeFavorable() const
{
    if(!m_useFilter) {
        return true;
    }
    
    switch(m_currentRegime) {
        case REGIME_BULLISH:
            return m_tradeBullish;
        case REGIME_BEARISH:
            return m_tradeBearish;
        case REGIME_RANGING:
            return m_tradeRanging;
        case REGIME_VOLATILE:
            return m_tradeVolatile;
        default:
            return false;
    }
}

//+------------------------------------------------------------------+
//| Calculate ADX strength                                           |
//+------------------------------------------------------------------+
double CMarketRegimeFilter::CalculateADXStrength()
{
    int adxHandle = iADX(_Symbol, PERIOD_H4, 14);
    if(adxHandle == INVALID_HANDLE) {
        if(m_logger) m_logger.Warning("Failed to create ADX handle");
        return 0.0;
    }
    
    double adxBuffer[];
    ArraySetAsSeries(adxBuffer, true);
    
    if(CopyBuffer(adxHandle, 0, 0, 1, adxBuffer) <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy ADX buffer");
        IndicatorRelease(adxHandle);
        return 0.0;
    }
    
    double adxValue = adxBuffer[0];
    
    IndicatorRelease(adxHandle);
    
    return adxValue;
}

//+------------------------------------------------------------------+
//| Calculate volatility ratio                                       |
//+------------------------------------------------------------------+
double CMarketRegimeFilter::CalculateVolatilityRatio()
{
    // Get ATR values
    int atrHandle = iATR(_Symbol, PERIOD_H4, 14);
    if(atrHandle == INVALID_HANDLE) {
        if(m_logger) m_logger.Warning("Failed to create ATR handle");
        return 1.0;
    }
    
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if(CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy ATR buffer");
        IndicatorRelease(atrHandle);
        return 1.0;
    }
    
    // Calculate current ATR
    double currentATR = atrBuffer[0];
    
    // Calculate average ATR for the last 20 periods
    double avgATR = 0.0;
    for(int i = 1; i < 20; i++) {
        avgATR += atrBuffer[i];
    }
    avgATR /= 19.0;
    
    IndicatorRelease(atrHandle);
    
    // Calculate volatility ratio
    double ratio = avgATR > 0 ? currentATR / avgATR : 1.0;
    
    return ratio;
}

//+------------------------------------------------------------------+
//| Check if market is in uptrend                                    |
//+------------------------------------------------------------------+
bool CMarketRegimeFilter::IsInUptrend(CSonicRCore* core)
{
    if(core == NULL) {
        return false;
    }
    
    // Check multi-timeframe trend from Core
    int h4Trend = core.GetH4Trend();
    int d1Trend = core.GetDailyTrend();
    
    // Require at least one timeframe to be in uptrend
    return (h4Trend > 0 || d1Trend > 0);
}

//+------------------------------------------------------------------+
//| Check if market is in downtrend                                  |
//+------------------------------------------------------------------+
bool CMarketRegimeFilter::IsInDowntrend(CSonicRCore* core)
{
    if(core == NULL) {
        return false;
    }
    
    // Check multi-timeframe trend from Core
    int h4Trend = core.GetH4Trend();
    int d1Trend = core.GetDailyTrend();
    
    // Require at least one timeframe to be in downtrend
    return (h4Trend < 0 || d1Trend < 0);
}

//+------------------------------------------------------------------+
//| Get current regime as string                                     |
//+------------------------------------------------------------------+
string CMarketRegimeFilter::GetCurrentRegimeAsString() const
{
    return GetRegimeName(m_currentRegime);
}

//+------------------------------------------------------------------+
//| Helper to get regime name                                        |
//+------------------------------------------------------------------+
string GetRegimeName(CMarketRegimeFilter::ENUM_MARKET_REGIME regime)
{
    switch(regime) {
        case CMarketRegimeFilter::REGIME_BULLISH:
            return "Bullish";
        case CMarketRegimeFilter::REGIME_BEARISH:
            return "Bearish";
        case CMarketRegimeFilter::REGIME_RANGING:
            return "Ranging";
        case CMarketRegimeFilter::REGIME_VOLATILE:
            return "Volatile";
        default:
            return "Unknown";
    }
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CMarketRegimeFilter::GetStatusText() const
{
    string status = "Market Regime Filter Status:\n";
    
    // Filter settings
    status += "Filter Enabled: " + (m_useFilter ? "Yes" : "No") + "\n";
    status += "Current Regime: " + GetCurrentRegimeAsString() + "\n";
    
    // Trading settings
    status += "Trading Allowed In:\n";
    status += "  Bullish: " + (m_tradeBullish ? "Yes" : "No") + "\n";
    status += "  Bearish: " + (m_tradeBearish ? "Yes" : "No") + "\n";
    status += "  Ranging: " + (m_tradeRanging ? "Yes" : "No") + "\n";
    status += "  Volatile: " + (m_tradeVolatile ? "Yes" : "No") + "\n";
    
    // Current state
    status += "Trading Allowed: " + (IsRegimeFavorable() ? "Yes" : "NO") + "\n";
    
    return status;
}