//+------------------------------------------------------------------+
//| CFilterManager.mqh - Manages market filters for trading conditions|
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

// Forward declarations
class CIndicatorManager;
class CSession;
class CLogger;

//+------------------------------------------------------------------+
//| CFilterManager Class - Manages all market condition filters       |
//+------------------------------------------------------------------+
class CFilterManager {
private:
    // Filter settings
    bool m_useNewsFilter;              // Whether to use news filter
    int m_newsBefore;                  // Minutes before news to avoid trading
    int m_newsAfter;                   // Minutes after news to avoid trading
    bool m_useADXFilter;               // Whether to use ADX filter
    double m_adxThreshold;             // ADX threshold for trend strength
    bool m_usePropFirmHoursFilter;     // Whether to enforce PropFirm active hours

    // PropFirm settings
    ENUM_PROP_FIRM_TYPE m_propFirmType; // PropFirm type
    ENUM_CHALLENGE_PHASE m_challengePhase; // Challenge phase
    
    // Symbol info
    string m_symbol;                   // Current symbol
    
    // Component references
    CIndicatorManager* m_indicators;   // Indicator manager reference
    CSession* m_session;               // Session manager reference
    CLogger* m_logger;                 // Logger reference
    
    // News events
    NewsEvent m_pendingNews[];         // Array of pending news events
    datetime m_lastNewsCheck;          // Last time news was checked
    
    //--- Private methods
    
    // Check if there is high-impact news currently active
    bool IsNewsActive() {
        // Skip if news filter disabled
        if (!m_useNewsFilter) return false;
        
        // Current time
        datetime currentTime = TimeCurrent();
        
        // If last check was more than 15 minutes ago, update news
        if (m_lastNewsCheck == 0 || currentTime - m_lastNewsCheck > 900) {
            UpdateNewsEvents();
            m_lastNewsCheck = currentTime;
        }
        
        // Check all pending news events
        for (int i = 0; i < ArraySize(m_pendingNews); i++) {
            // Skip inactive news
            if (!m_pendingNews[i].isActive) continue;
            
            // Check if news is for our currency
            if (StringFind(m_symbol, m_pendingNews[i].currency) >= 0) {
                // Check if current time is within news impact window
                int secondsBefore = m_newsBefore * 60;
                int secondsAfter = m_newsAfter * 60;
                
                if (currentTime >= m_pendingNews[i].time - secondsBefore && 
                    currentTime <= m_pendingNews[i].time + secondsAfter) {
                    
                    // Log news filter activation
                    if (m_logger != NULL) {
                        m_logger.Info("News filter active for " + m_pendingNews[i].currency + 
                                     ": " + m_pendingNews[i].title + 
                                     " at " + TimeToString(m_pendingNews[i].time, TIME_DATE|TIME_MINUTES));
                    }
                    
                    return true;
                }
            }
        }
        
        return false;
    }
    
    // Update news events from external source
    void UpdateNewsEvents() {
        // This is a placeholder for actual news fetching implementation
        // In a real implementation, this would connect to a news API or service
        
        // Clear existing news events
        ArrayFree(m_pendingNews);
        
        // For now, we'll create some dummy news events for testing
        // In a real implementation, this would be replaced with actual news data
        datetime currentTime = TimeCurrent();
        MqlDateTime timeStruct;
        TimeToStruct(currentTime, timeStruct);
        
        // Create a test news event for USD if it's within trading hours
        if (timeStruct.hour >= 8 && timeStruct.hour < 17) {
            int newsCount = ArraySize(m_pendingNews);
            ArrayResize(m_pendingNews, newsCount + 1);
            
            m_pendingNews[newsCount].time = StringToTime(
                TimeToString(currentTime, TIME_DATE) + " 14:30:00"); // Fixed time for testing
            m_pendingNews[newsCount].title = "US Economic News";
            m_pendingNews[newsCount].currency = "USD";
            m_pendingNews[newsCount].impact = NEWS_IMPACT_HIGH;
            m_pendingNews[newsCount].isActive = true;
        }
        
        // Log news update
        if (m_logger != NULL) {
            m_logger.Debug("Updated news events: " + IntegerToString(ArraySize(m_pendingNews)) + " events");
        }
    }
    
    // Check if ADX indicates a strong trend
    bool IsADXFavorable() {
        // Skip if ADX filter disabled
        if (!m_useADXFilter) return true;
        
        // Check if indicator manager is available
        if (m_indicators == NULL) return true;
        
        // Get current ADX value
        double adxValue = m_indicators.GetADXValue();
        
        // Check if ADX is above threshold
        bool isFavorable = adxValue >= m_adxThreshold;
        
        // Log ADX check
        if (m_logger != NULL && !isFavorable) {
            m_logger.Debug("ADX filter: " + DoubleToString(adxValue, 1) + 
                          " below threshold " + DoubleToString(m_adxThreshold, 1));
        }
        
        return isFavorable;
    }
    
    // Check if current time is within PropFirm allowed trading hours
    bool IsPropFirmTimeAllowed() {
        // Skip if PropFirm hours filter disabled
        if (!m_usePropFirmHoursFilter) return true;
        
        // Get current time
        MqlDateTime timeStruct;
        TimeCurrent(timeStruct);
        
        // Check for weekend - never trade on weekends for PropFirms
        if (timeStruct.day_of_week == 0 || timeStruct.day_of_week == 6) {
            if (m_logger != NULL) {
                m_logger.Warning("Weekend trading not allowed for PropFirm accounts");
            }
            return false;
        }
        
        // Check specific PropFirm hours restrictions
        switch (m_propFirmType) {
            case PROP_FIRM_FTMO:
                // Most PropFirms don't allow trading around daily roll-over
                if (timeStruct.hour == 23 || timeStruct.hour == 0) {
                    if (m_logger != NULL) {
                        m_logger.Warning("Trading around daily roll-over not recommended for PropFirm accounts");
                    }
                    return false;
                }
                
                // No trading on Friday after 21:00 for FTMO
                if (timeStruct.day_of_week == 5 && timeStruct.hour >= 21) {
                    if (m_logger != NULL) {
                        m_logger.Warning("Trading on Friday after 21:00 not allowed for FTMO");
                    }
                    return false;
                }
                break;
                
            case PROP_FIRM_THE5ERS:
                // The5ers is generally more flexible
                // But still avoid trading during roll-over periods
                if (timeStruct.hour == 23 && timeStruct.min >= 45) {
                    if (m_logger != NULL) {
                        m_logger.Warning("Trading during roll-over period not recommended");
                    }
                    return false;
                }
                break;
                
            // Add other PropFirm specific rules as needed
            default:
                // Use general safety rules for other firms
                if (timeStruct.day_of_week == 5 && timeStruct.hour >= 22) {
                    if (m_logger != NULL) {
                        m_logger.Warning("Trading late on Friday not recommended for PropFirm accounts");
                    }
                    return false;
                }
                break;
        }
        
        return true;
    }
    
    // Check if the session filter allows trading now
    bool IsSessionAllowed() {
        // Check if session manager is available
        if (m_session == NULL) return true;
        
        // Delegate to session manager
        return m_session.IsOptimalTradingTime(m_symbol);
    }
    
    // Check if volatility is suitable for trading
    bool IsVolatilitySuitable() {
        // Check if indicator manager is available
        if (m_indicators == NULL) return true;
        
        // Get current ATR value
        double atrValue = m_indicators.GetATRValue();
        
        // Get average daily range
        double adr = CalculateADR(20); // 20-day ADR
        
        // If ATR is less than 30% of ADR, volatility is too low
        if (atrValue < adr * 0.3) {
            if (m_logger != NULL) {
                m_logger.Debug("Volatility too low: ATR " + DoubleToString(atrValue, _Digits) + 
                              " < 30% of ADR " + DoubleToString(adr, _Digits));
            }
            return false;
        }
        
        // If ATR is more than 200% of ADR, volatility is too high
        if (atrValue > adr * 2.0) {
            if (m_logger != NULL) {
                m_logger.Warning("Volatility too high: ATR " + DoubleToString(atrValue, _Digits) + 
                               " > 200% of ADR " + DoubleToString(adr, _Digits));
            }
            return false;
        }
        
        return true;
    }
    
    // Calculate Average Daily Range
    double CalculateADR(int days) {
        double sum = 0;
        
        for (int i = 1; i <= days; i++) {
            double highPrice = iHigh(m_symbol, PERIOD_D1, i);
            double lowPrice = iLow(m_symbol, PERIOD_D1, i);
            
            if (highPrice > 0 && lowPrice > 0) {
                sum += (highPrice - lowPrice);
            }
        }
        
        return sum / days;
    }
    
public:
    // Constructor
    CFilterManager() {
        // Initialize with default values
        m_useNewsFilter = true;
        m_newsBefore = DEFAULT_NEWS_BEFORE;
        m_newsAfter = DEFAULT_NEWS_AFTER;
        m_useADXFilter = true;
        m_adxThreshold = DEFAULT_ADX_THRESHOLD;
        m_usePropFirmHoursFilter = true;
        
        // PropFirm settings
        m_propFirmType = PROP_FIRM_FTMO;
        m_challengePhase = PHASE_CHALLENGE;
        
        // Symbol
        m_symbol = _Symbol;
        
        // Component references
        m_indicators = NULL;
        m_session = NULL;
        m_logger = NULL;
        
        // News tracking
        m_lastNewsCheck = 0;
    }
    
    // Initialize the filter manager
    bool Initialize() {
        // Initialize news events
        UpdateNewsEvents();
        
        // Log initialization
        if (m_logger != NULL) {
            m_logger.Info("FilterManager initialized for " + m_symbol);
            m_logger.Info("News filter: " + (m_useNewsFilter ? "ON" : "OFF") + 
                         ", ADX filter: " + (m_useADXFilter ? "ON" : "OFF") + 
                         " (threshold: " + DoubleToString(m_adxThreshold, 1) + ")");
        }
        
        return true;
    }
    
    // Update filter data
    void Update() {
        // Update news events periodically
        datetime currentTime = TimeCurrent();
        
        // If last check was more than 15 minutes ago, update news
        if (m_lastNewsCheck == 0 || currentTime - m_lastNewsCheck > 900) {
            UpdateNewsEvents();
            m_lastNewsCheck = currentTime;
        }
    }
    
    // Check if all market conditions are favorable
    bool IsMarketConditionFavorable() {
        // Build a list of active filters for logging
        string activeFilters = "";
        bool isAllowed = true;
        
        // 1. Check news filter
        if (IsNewsActive()) {
            activeFilters += "News,";
            isAllowed = false;
        }
        
        // 2. Check ADX filter
        if (!IsADXFavorable()) {
            activeFilters += "ADX,";
            isAllowed = false;
        }
        
        // 3. Check PropFirm hours
        if (!IsPropFirmTimeAllowed()) {
            activeFilters += "PropFirmHours,";
            isAllowed = false;
        }
        
        // 4. Check session filter
        if (!IsSessionAllowed()) {
            activeFilters += "Session,";
            isAllowed = false;
        }
        
        // 5. Check volatility
        if (!IsVolatilitySuitable()) {
            activeFilters += "Volatility,";
            isAllowed = false;
        }
        
        // Log filter status if any blocked
        if (!isAllowed && m_logger != NULL) {
            // Remove trailing comma
            if (StringLen(activeFilters) > 0) {
                activeFilters = StringSubstr(activeFilters, 0, StringLen(activeFilters) - 1);
            }
            
            m_logger.Info("Trading conditions not favorable. Active filters: " + activeFilters);
        }
        
        return isAllowed;
    }
    
    //--- Setters
    
    // Set news filter parameters
    void SetNewsFilter(bool useFilter, int before, int after) {
        m_useNewsFilter = useFilter;
        m_newsBefore = before;
        m_newsAfter = after;
    }
    
    // Set ADX filter parameters
    void SetADXFilter(bool useFilter, double threshold) {
        m_useADXFilter = useFilter;
        m_adxThreshold = threshold;
    }
    
    // Set PropFirm hours filter
    void SetPropFirmHoursFilter(bool useFilter) {
        m_usePropFirmHoursFilter = useFilter;
    }
    
    // Set symbol
    void SetSymbol(string symbol) {
        m_symbol = symbol;
    }
    
    // Set PropFirm settings
    void SetPropFirmSettings(ENUM_PROP_FIRM_TYPE type, ENUM_CHALLENGE_PHASE phase) {
        m_propFirmType = type;
        m_challengePhase = phase;
    }
    
    // Set indicator manager reference
    void SetIndicatorManager(CIndicatorManager* indicators) {
        m_indicators = indicators;
    }
    
    // Set session manager reference
    void SetSession(CSession* session) {
        m_session = session;
    }
    
    // Set logger reference
    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }
    
    //--- Getters
    
    // Check if news filter is active
    bool IsNewsFilterActive() {
        return m_useNewsFilter && IsNewsActive();
    }
    
    // Check if ADX filter is active
    bool IsADXFilterActive() {
        return m_useADXFilter && !IsADXFavorable();
    }
    
    // Get pending news events
    void GetPendingNews(NewsEvent &news[]) {
        int size = ArraySize(m_pendingNews);
        ArrayResize(news, size);
        
        for (int i = 0; i < size; i++) {
            news[i] = m_pendingNews[i];
        }
    }
    
    // Check if there is high-impact news coming soon
    bool IsHighImpactNewsSoon(int lookAheadMinutes = 60) {
        if (!m_useNewsFilter) return false;
        
        datetime currentTime = TimeCurrent();
        datetime lookAheadTime = currentTime + lookAheadMinutes * 60;
        
        for (int i = 0; i < ArraySize(m_pendingNews); i++) {
            if (m_pendingNews[i].isActive && 
                m_pendingNews[i].impact == NEWS_IMPACT_HIGH && 
                StringFind(m_symbol, m_pendingNews[i].currency) >= 0 && 
                m_pendingNews[i].time > currentTime && 
                m_pendingNews[i].time <= lookAheadTime) {
                
                return true;
            }
        }
        
        return false;
    }
};