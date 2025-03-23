//+------------------------------------------------------------------+
//|                                                 NewsFilter.mqh |
//|                            SonicR PropFirm EA - News Filtering |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef NEWS_FILTER_MQH
#define NEWS_FILTER_MQH

// News event structure
struct SNewsEvent {
    datetime time;         // Event time
    string currency;       // Currency affected
    string title;          // Event title
    int impact;            // Impact level (1=low, 2=medium, 3=high)
    bool isPending;        // Is event pending
};

// News filter class
class CNewsFilter
{
private:
    // Settings
    bool m_useFilter;           // Enable news filter
    int m_minutesBefore;        // Minutes before news
    int m_minutesAfter;         // Minutes after news
    bool m_highImpactOnly;      // Filter high impact only
    
    // News data
    SNewsEvent m_upcomingEvents[20];  // Upcoming events
    int m_eventCount;                 // Number of events
    datetime m_lastUpdate;            // Last update time
    
    // Helper methods
    void UpdateNewsData();
    bool DoesEventAffectSymbol(const SNewsEvent &event, string symbol);
    string GetCurrenciesFromSymbol(string symbol);
    bool IsCurrencyInSymbol(string currency, string symbol);
    
public:
    // Constructor
    CNewsFilter(bool useFilter = true, 
               int minutesBefore = 30, 
               int minutesAfter = 15, 
               bool highImpactOnly = true);
    
    // Main methods
    bool IsNewsTime();
    int GetMinutesUntilNextNews();
    SNewsEvent GetNextNewsEvent();
    
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
//| Constructor                                                      |
//+------------------------------------------------------------------+
CNewsFilter::CNewsFilter(bool useFilter = true, 
                       int minutesBefore = 30, 
                       int minutesAfter = 15, 
                       bool highImpactOnly = true)
{
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
        long timeDiff = m_upcomingEvents[i].time - currentTime;
        
        // Check if within time window
        if(timeDiff >= -m_minutesAfter * 60 && timeDiff <= m_minutesBefore * 60) {
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
SNewsEvent CNewsFilter::GetNextNewsEvent()
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
    SNewsEvent emptyEvent;
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
bool CNewsFilter::DoesEventAffectSymbol(const SNewsEvent &event, string symbol)
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
        
        SNewsEvent nextEvent = self.GetNextNewsEvent();
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

#endif // NEWS_FILTER_MQH