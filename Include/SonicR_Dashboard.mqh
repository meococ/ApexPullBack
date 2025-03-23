//+------------------------------------------------------------------+
//|                                        SonicR_Dashboard.mqh      |
//|                 SonicR PropFirm EA - Dashboard UI Component      |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include "SonicR_Logger.mqh"
#include "SonicR_Core.mqh"
#include "SonicR_StateMachine.mqh"
#include "SonicR_PropSettings.mqh"
#include "SonicR_RiskManager.mqh"
#include "SonicR_AdaptiveFilters.mqh"

// Dashboard class for on-chart visualization
class CDashboard
{
private:
    // Dependencies
    CLogger* m_logger;
    CSonicRCore* m_core;
    CRiskManager* m_riskManager;
    CStateMachine* m_stateMachine;
    CPropSettings* m_propSettings;
    CAdaptiveFilters* m_adaptiveFilters;
    
    // Dashboard settings
    int m_x;                   // X position
    int m_y;                   // Y position
    int m_width;               // Width
    int m_height;              // Height
    color m_bgColor;           // Background color
    color m_textColor;         // Text color
    color m_headerColor;       // Header text color
    color m_borderColor;       // Border color
    int m_fontSize;            // Font size
    string m_fontName;         // Font name
    
    // Object names
    string m_panelName;        // Main panel object name
    string m_titleName;        // Title object name
    string m_prefixName;       // Prefix for all dashboard objects
    
    // Last update time
    datetime m_lastUpdateTime;
    
    // Helper methods
    void CreatePanel();
    void CreateHeader();
    void CreatePropFirmSection();
    void CreateStrategySection();
    void CreateStatsSection();
    void CreateSignalsSection();
    
    void CreateLabel(string name, string text, int x, int y, 
                    color clr, int size = 0, string font = "");
    void UpdateLabel(string name, string text);
    void CreateRect(string name, int x, int y, int width, int height, 
                   color bgColor, color borderColor);
    
    // Clean up objects with prefix
    void DeleteAllObjects();
    
public:
    // Constructor
    CDashboard();
    
    // Destructor
    ~CDashboard();
    
    // Main methods
    bool Create();
    void Update();
    void Remove();
    
    // Set dependencies
    void SetDependencies(CSonicRCore* core, CRiskManager* riskManager, CStateMachine* stateMachine, CPropSettings* propSettings);
    void SetLogger(CLogger* logger) { m_logger = logger; }
    void SetAdaptiveFilters(CAdaptiveFilters* adaptiveFilters) { m_adaptiveFilters = adaptiveFilters; }
    
    // Settings
    void SetPosition(int x, int y) { m_x = x; m_y = y; }
    void SetSize(int width, int height) { m_width = width; m_height = height; }
    void SetColors(color bg, color text, color header, color border);
    void SetFont(string name, int size);
    
    // Event handler
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    
    // New method
    void Draw();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
    m_logger = NULL;
    m_core = NULL;
    m_riskManager = NULL;
    m_stateMachine = NULL;
    m_propSettings = NULL;
    m_adaptiveFilters = NULL;
    
    // Set default dashboard settings
    m_x = 20;
    m_y = 20;
    m_width = 300;
    m_height = 400;
    m_bgColor = C'25,25,25';  // Dark background
    m_textColor = clrWhite;
    m_headerColor = clrLightBlue;
    m_borderColor = clrSlateGray;
    m_fontSize = 9;
    m_fontName = "Arial";
    
    // Set object prefix and names
    m_prefixName = "SonicR_Dashboard_";
    m_panelName = m_prefixName + "Panel";
    m_titleName = m_prefixName + "Title";
    
    // Last update time
    m_lastUpdateTime = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
    // Clean up objects
    Remove();
}

//+------------------------------------------------------------------+
//| Set dependencies                                                 |
//+------------------------------------------------------------------+
void CDashboard::SetDependencies(CSonicRCore* core, CRiskManager* riskManager, CStateMachine* stateMachine, CPropSettings* propSettings)
{
    m_core = core;
    m_riskManager = riskManager;
    m_stateMachine = stateMachine;
    m_propSettings = propSettings;
}

//+------------------------------------------------------------------+
//| Set dashboard colors                                             |
//+------------------------------------------------------------------+
void CDashboard::SetColors(color bg, color text, color header, color border)
{
    m_bgColor = bg;
    m_textColor = text;
    m_headerColor = header;
    m_borderColor = border;
}

//+------------------------------------------------------------------+
//| Set dashboard font                                               |
//+------------------------------------------------------------------+
void CDashboard::SetFont(string name, int size)
{
    m_fontName = name;
    m_fontSize = size;
}

//+------------------------------------------------------------------+
//| Create the dashboard                                             |
//+------------------------------------------------------------------+
bool CDashboard::Create()
{
    // Check if dependencies are set
    if(!m_core || !m_stateMachine || !m_propSettings) {
        if(m_logger) m_logger.Error("Cannot create dashboard: dependencies not set");
        return false;
    }
    
    // Clean up existing objects
    DeleteAllObjects();
    
    // Create the main panel and sections
    CreatePanel();
    CreateHeader();
    CreatePropFirmSection();
    CreateStrategySection();
    CreateStatsSection();
    CreateSignalsSection();
    
    // Force immediate update
    Update();
    
    if(m_logger) m_logger.Info("Dashboard created");
    return true;
}

//+------------------------------------------------------------------+
//| Update the dashboard                                             |
//+------------------------------------------------------------------+
void CDashboard::Update()
{
    // Check if dependencies are set
    if(!m_core || !m_stateMachine || !m_propSettings) {
        return;
    }
    
    // Limit update frequency (once per second)
    datetime currentTime = TimeCurrent();
    if(currentTime - m_lastUpdateTime < 1) {
        return;
    }
    m_lastUpdateTime = currentTime;
    
    // Update PropFirm section
    string propFirmText = EnumToString(m_propSettings.GetPropFirm()) + " - " + 
                        EnumToString(m_propSettings.GetPhase());
    UpdateLabel(m_prefixName + "PropFirm_Value", propFirmText);
    
    string profitText = DoubleToString(m_propSettings.GetCurrentProfit(), 2) + "% / " + 
                       DoubleToString(m_propSettings.GetTargetProfit(), 2) + "%";
    UpdateLabel(m_prefixName + "Profit_Value", profitText);
    
    string drawdownText = DoubleToString(m_propSettings.GetMaxDrawdownReached(), 2) + "% / " + 
                        DoubleToString(m_propSettings.GetMaxDrawdown(), 2) + "%";
    UpdateLabel(m_prefixName + "Drawdown_Value", drawdownText);
    
    string daysText = IntegerToString(m_propSettings.GetRemainingDays()) + " days remaining";
    UpdateLabel(m_prefixName + "Days_Value", daysText);
    
    // Update state in Strategy section
    string stateText = "State: " + m_stateMachine.GetStatusText();
    UpdateLabel(m_prefixName + "State_Value", stateText);
    
    // Get multi-timeframe trend info
    bool bullishPullback, bearishPullback;
    m_core.GetPullbackInfo(bullishPullback, bearishPullback);
    
    string trendD1 = m_core.GetDailyTrend() > 0 ? "Up" : (m_core.GetDailyTrend() < 0 ? "Down" : "Neutral");
    string trendH4 = m_core.GetH4Trend() > 0 ? "Up" : (m_core.GetH4Trend() < 0 ? "Down" : "Neutral");
    string trendH1 = m_core.GetH1Trend() > 0 ? "Up" : (m_core.GetH1Trend() < 0 ? "Down" : "Neutral");
    
    string trendsText = "D1: " + trendD1 + " | H4: " + trendH4 + " | H1: " + trendH1;
    UpdateLabel(m_prefixName + "Trends_Value", trendsText);
    
    string pullbackText = "Pullbacks: " + 
                        (bullishPullback ? "BUY " : "") + 
                        (bearishPullback ? "SELL" : "");
    if(!bullishPullback && !bearishPullback) pullbackText += "None";
    UpdateLabel(m_prefixName + "Pullback_Value", pullbackText);
    
    // Update signals section
    string patternsText = "";
    int patternCount = m_core.GetPatternCount();
    
    for(int i = 0; i < MathMin(3, patternCount); i++) {
        CPricePattern* pattern = m_core.GetPattern(i);
        if(pattern != NULL) {
            patternsText += pattern.GetName() + " (" + 
                          (pattern.GetDirection() > 0 ? "BUY" : "SELL") + ") - " + 
                          DoubleToString(pattern.GetQuality(), 1) + "%\n";
        }
    }
    
    if(patternsText == "") patternsText = "No recent patterns";
    UpdateLabel(m_prefixName + "Patterns_Value", patternsText);
    
    // Force chart redraw
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Remove the dashboard                                             |
//+------------------------------------------------------------------+
void CDashboard::Remove()
{
    DeleteAllObjects();
    
    if(m_logger) m_logger.Info("Dashboard removed");
}

//+------------------------------------------------------------------+
//| Handle chart events                                              |
//+------------------------------------------------------------------+
void CDashboard::OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
    // Handle CHARTEVENT_OBJECT_CLICK
    if(id == CHARTEVENT_OBJECT_CLICK) {
        // Check if clicked object belongs to dashboard
        if(StringFind(sparam, m_prefixName) >= 0) {
            // Handle specific buttons
            if(sparam == m_prefixName + "Reset_Button") {
                // Reset challenge
                if(m_propSettings) {
                    m_propSettings.Reset();
                    if(m_logger) m_logger.Info("Challenge reset requested via dashboard");
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Create main panel                                                |
//+------------------------------------------------------------------+
void CDashboard::CreatePanel()
{
    CreateRect(m_panelName, m_x, m_y, m_width, m_height, m_bgColor, m_borderColor);
}

//+------------------------------------------------------------------+
//| Create dashboard header                                          |
//+------------------------------------------------------------------+
void CDashboard::CreateHeader()
{
    int headerHeight = 30;
    
    // Create header background
    CreateRect(m_prefixName + "Header", m_x, m_y, m_width, headerHeight, 
              C'40,40,40', m_borderColor);
    
    // Create title
    string title = "SonicR PropFirm EA";
    CreateLabel(m_titleName, title, m_x + 10, m_y + 15, m_headerColor, m_fontSize + 2, m_fontName + " Bold");
}

//+------------------------------------------------------------------+
//| Create PropFirm section                                          |
//+------------------------------------------------------------------+
void CDashboard::CreatePropFirmSection()
{
    int yPos = m_y + 40;
    
    // Section header
    CreateLabel(m_prefixName + "PropFirm_Header", "PROPFIRM CHALLENGE", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // PropFirm info
    CreateLabel(m_prefixName + "PropFirm_Label", "PropFirm:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "PropFirm_Value", "---", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Profit info
    CreateLabel(m_prefixName + "Profit_Label", "Profit:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Profit_Value", "0.00% / 0.00%", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Drawdown info
    CreateLabel(m_prefixName + "Drawdown_Label", "Drawdown:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Drawdown_Value", "0.00% / 0.00%", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Days info
    CreateLabel(m_prefixName + "Days_Label", "Time:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Days_Value", "0 days remaining", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Divider
    CreateRect(m_prefixName + "Divider1", m_x + 10, yPos, m_width - 20, 1, m_borderColor, m_borderColor);
}

//+------------------------------------------------------------------+
//| Create strategy section                                          |
//+------------------------------------------------------------------+
void CDashboard::CreateStrategySection()
{
    int yPos = m_y + 160;
    
    // Section header
    CreateLabel(m_prefixName + "Strategy_Header", "STRATEGY STATUS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // State info
    CreateLabel(m_prefixName + "State_Label", "State:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "State_Value", "Initializing", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Trend info
    CreateLabel(m_prefixName + "Trends_Label", "Trends:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Trends_Value", "D1: --- | H4: --- | H1: ---", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Pullback info
    CreateLabel(m_prefixName + "Pullback_Label", "Pullbacks:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Pullback_Value", "None", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Divider
    CreateRect(m_prefixName + "Divider2", m_x + 10, yPos, m_width - 20, 1, m_borderColor, m_borderColor);
}

//+------------------------------------------------------------------+
//| Create stats section                                             |
//+------------------------------------------------------------------+
void CDashboard::CreateStatsSection()
{
    int yPos = m_y + 260;
    
    // Section header
    CreateLabel(m_prefixName + "Stats_Header", "TRADING STATISTICS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Win rate info
    CreateLabel(m_prefixName + "WinRate_Label", "Win Rate:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "WinRate_Value", "0.0%", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Trades info
    CreateLabel(m_prefixName + "Trades_Label", "Trades:", m_x + 10, yPos, m_textColor);
    CreateLabel(m_prefixName + "Trades_Value", "W: 0 | L: 0 | T: 0", m_x + 100, yPos, m_textColor);
    yPos += 20;
    
    // Divider
    CreateRect(m_prefixName + "Divider3", m_x + 10, yPos, m_width - 20, 1, m_borderColor, m_borderColor);
}

//+------------------------------------------------------------------+
//| Create signals section                                           |
//+------------------------------------------------------------------+
void CDashboard::CreateSignalsSection()
{
    int yPos = m_y + 340;
    
    // Section header
    CreateLabel(m_prefixName + "Signals_Header", "RECENT PATTERNS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Patterns info
    CreateLabel(m_prefixName + "Patterns_Value", "No recent patterns", m_x + 10, yPos, m_textColor);
}

//+------------------------------------------------------------------+
//| Create a text label object                                       |
//+------------------------------------------------------------------+
void CDashboard::CreateLabel(string name, string text, int x, int y, 
                           color clr, int size = 0, string font = "")
{
    if(size == 0) size = m_fontSize;
    if(font == "") font = m_fontName;
    
    // Create label object
    ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    
    // Set properties
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetString(0, name, OBJPROP_FONT, font);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

//+------------------------------------------------------------------+
//| Update label text                                                |
//+------------------------------------------------------------------+
void CDashboard::UpdateLabel(string name, string text)
{
    if(ObjectFind(0, name) >= 0) {
        ObjectSetString(0, name, OBJPROP_TEXT, text);
    }
}

//+------------------------------------------------------------------+
//| Create a rectangle object                                        |
//+------------------------------------------------------------------+
void CDashboard::CreateRect(string name, int x, int y, int width, int height, 
                          color bgColor, color borderColor)
{
    // Create rectangle object
    ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    
    // Set properties
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_COLOR, borderColor);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Delete all dashboard objects                                     |
//+------------------------------------------------------------------+
void CDashboard::DeleteAllObjects()
{
    // Delete all objects with prefix
    int totalObj = ObjectsTotal(0);
    
    for(int i = totalObj - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        
        if(StringFind(objName, m_prefixName) == 0) {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Draw dashboard                                                   |
//+------------------------------------------------------------------+
void CDashboard::Draw()
{
    // ... existing drawing code ...
    
    // Draw Performance section
    // ... existing code ...
    
    // Draw Market Info section
    // ... existing code ...
    
    // Draw Adaptive Filters section (new)
    if(m_adaptiveFilters != NULL) {
        int y = 220; // Adjust based on your layout
        
        // Section header
        DrawLabel("SonicR_Dash_AdaptiveHeader", "ADAPTIVE FILTERS", 10, y, clrWhite, 9, "Arial Bold");
        y += 20;
        
        // Market regime info
        DrawLabel("SonicR_Dash_Regime", "Regime: " + m_adaptiveFilters.GetCurrentRegimeAsString(), 
                 15, y, clrYellow, 8, "Arial");
        y += 15;
        
        // Trend info
        string trendDir = "";
        int direction = m_adaptiveFilters.GetTrendDirection();
        if(direction > 0) trendDir = "Up";
        else if(direction < 0) trendDir = "Down";
        else trendDir = "Sideways";
        
        DrawLabel("SonicR_Dash_Trend", "Trend: " + trendDir + " (" + 
                 DoubleToString(m_adaptiveFilters.GetTrendStrength(), 1) + ")", 
                 15, y, clrYellow, 8, "Arial");
        y += 15;
        
        // Volatility 
        DrawLabel("SonicR_Dash_Vol", "Volatility: " + 
                 DoubleToString(m_adaptiveFilters.GetVolatilityRatio(), 2), 
                 15, y, clrYellow, 8, "Arial");
        y += 15;
        
        // Parameters
        DrawLabel("SonicR_Dash_Risk", "Risk %: " + 
                 DoubleToString(m_adaptiveFilters.GetBaseRiskPercent(_Symbol), 2), 
                 15, y, clrAqua, 8, "Arial");
        y += 15;
        
        DrawLabel("SonicR_Dash_RR", "Min R:R: " + 
                 DoubleToString(m_adaptiveFilters.GetMinRR(), 1), 
                 15, y, clrAqua, 8, "Arial");
        y += 15;
        
        DrawLabel("SonicR_Dash_MaxTrades", "Max Trades: " + 
                 IntegerToString(m_adaptiveFilters.GetMaxTradesForRegime()), 
                 15, y, clrAqua, 8, "Arial");
        y += 15;
        
        DrawLabel("SonicR_Dash_Scout", "Scout Entries: " + 
                 (m_adaptiveFilters.ShouldUseScoutEntries() ? "Yes" : "No"), 
                 15, y, clrAqua, 8, "Arial");
    }
}