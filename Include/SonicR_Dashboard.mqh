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
#include "SonicR_PVSRA.mqh"

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
    CPVSRA* m_pvsra;
    
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
    
    // Custom colors for v2.0
    color m_bullishColor;      // Bullish color
    color m_bearishColor;      // Bearish color
    color m_neutralColor;      // Neutral color
    bool m_showDetailedStats;  // Show detailed statistics
    
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
    void CreateSignalSection();
    void CreateRiskSection();
    void CreateAdaptiveFilterSection();
    void CreatePVSRASection();
    void CreateMarketRegimeSection();
    void CreateTradeStatsSection();
    
    // Helper methods for drawing
    void DrawText(const string name, const string text, const int x, const int y, 
                 const color textColor, const int fontSize = 0);
    void DrawLabel(const string name, const string text, const int x, const int y, 
                  const color textColor, const int fontSize = 0);
    void DrawColoredLabel(const string name, const string text, const int x, const int y, 
                         const color textColor, const color valueColor, const int fontSize = 0);
    void DrawProgressBar(const string name, const double value, const double maxValue, 
                        const int x, const int y, const int width, const int height, 
                        const color fillColor, const color bgColor);
    
    // Helper methods for object management
    void CreateRect(const string name, const int x, const int y, const int width, const int height, 
                   const color bgColor, const color borderColor);
    void CreateLabel(const string name, const string text, const int x, const int y, 
                    const color textColor, const int fontSize = 0, const string fontFace = "");
    void UpdateLabel(const string name, const string text);
    void DeleteAllObjects();
    
public:
    // Constructor
    CDashboard();
    
    // Destructor
    ~CDashboard();
    
    // Initialization
    bool Init(CAdaptiveFilters *adaptiveFilters, CPVSRA *pvsra, const string dashboardTitle);
    
    // Main methods
    void Create();
    void Update();
    void Remove();
    void Draw();
    
    // Handle chart events
    void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam);
    
    // Set dependencies
    void SetLogger(CLogger* logger) { m_logger = logger; }
    void SetDependencies(CSonicRCore* core, CRiskManager* riskManager, 
                       CStateMachine* stateMachine, CPropSettings* propSettings);
    void SetAdaptiveFilters(CAdaptiveFilters* adaptiveFilters) { m_adaptiveFilters = adaptiveFilters; }
    void SetPVSRA(CPVSRA* pvsra) { m_pvsra = pvsra; }
    
    // Configure appearance
    void SetPosition(const int x, const int y) { m_x = x; m_y = y; }
    void SetSize(const int width, const int height) { m_width = width; m_height = height; }
    void SetColors(const color bullishColor, const color bearishColor, 
                  const color neutralColor, const color textColor, const color bgColor);
    void SetFontSize(const int fontSize) { m_fontSize = fontSize; }
    void SetFontName(const string fontName) { m_fontName = fontName; }
    void SetShowDetailedStats(const bool showDetailedStats) { m_showDetailedStats = showDetailedStats; }
};

//+------------------------------------------------------------------+
//| Constructor                                                       |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
    // Initialize dependencies
    m_logger = NULL;
    m_core = NULL;
    m_riskManager = NULL;
    m_stateMachine = NULL;
    m_propSettings = NULL;
    m_adaptiveFilters = NULL;
    m_pvsra = NULL;
    
    // Set default settings
    m_x = 20;
    m_y = 20;
    m_width = 300;
    m_height = 500;
    m_bgColor = C'33,33,33';
    m_textColor = clrWhite;
    m_headerColor = clrGold;
    m_borderColor = clrDimGray;
    m_fontSize = 8;
    m_fontName = "Tahoma";
    
    // Default colors for v2.0
    m_bullishColor = clrForestGreen;
    m_bearishColor = clrFireBrick;
    m_neutralColor = clrDarkGray;
    m_showDetailedStats = true;
    
    // Set object names
    m_prefixName = "SonicR_Dashboard_";
    m_panelName = m_prefixName + "Panel";
    m_titleName = m_prefixName + "Title";
    
    // Initialize last update time
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
void CDashboard::SetColors(const color bullishColor, const color bearishColor, 
                          const color neutralColor, const color textColor, const color bgColor)
{
    m_bullishColor = bullishColor;
    m_bearishColor = bearishColor;
    m_neutralColor = neutralColor;
    m_textColor = textColor;
    m_bgColor = bgColor;
}

//+------------------------------------------------------------------+
//| Create the dashboard                                             |
//+------------------------------------------------------------------+
void CDashboard::Create()
{
    // Check if dependencies are set
    if(!m_core || !m_stateMachine || !m_propSettings) {
        if(m_logger) m_logger.Error("Cannot create dashboard: dependencies not set");
        return;
    }
    
    // Clean up existing objects
    DeleteAllObjects();
    
    // Create the main panel and sections
    CreatePanel();
    CreateHeader();
    CreatePropFirmSection();
    CreateSignalSection();
    CreateRiskSection();
    CreateAdaptiveFilterSection();
    CreatePVSRASection();
    CreateMarketRegimeSection();
    CreateTradeStatsSection();
    
    // Force immediate update
    Update();
    
    if(m_logger) m_logger.Info("Dashboard created");
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
//| Initialize the dashboard                                         |
//+------------------------------------------------------------------+
bool CDashboard::Init(CAdaptiveFilters *adaptiveFilters, CPVSRA *pvsra, const string dashboardTitle)
{
    // Set dependencies
    m_adaptiveFilters = adaptiveFilters;
    m_pvsra = pvsra;
    
    // Set dashboard title
    m_titleName = dashboardTitle;
    
    // Check if dependencies are properly set
    if(m_adaptiveFilters == NULL || m_pvsra == NULL) {
        if(m_logger) m_logger.Error("Dashboard initialization failed: dependencies not set");
        return false;
    }
    
    if(m_logger) m_logger.Info("Dashboard initialized successfully");
    return true;
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
//| Create signal section                                             |
//+------------------------------------------------------------------+
void CDashboard::CreateSignalSection()
{
    int yPos = m_y + 160;
    
    // Section header
    CreateLabel(m_prefixName + "Signal_Header", "RECENT PATTERNS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Patterns info
    CreateLabel(m_prefixName + "Patterns_Value", "No recent patterns", m_x + 10, yPos, m_textColor);
}

//+------------------------------------------------------------------+
//| Create risk section                                              |
//+------------------------------------------------------------------+
void CDashboard::CreateRiskSection()
{
    int yPos = m_y + 260;
    
    // Section header
    CreateLabel(m_prefixName + "Risk_Header", "TRADING RISK", 
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
    CreateRect(m_prefixName + "Divider2", m_x + 10, yPos, m_width - 20, 1, m_borderColor, m_borderColor);
}

//+------------------------------------------------------------------+
//| Create adaptive filter section                                    |
//+------------------------------------------------------------------+
void CDashboard::CreateAdaptiveFilterSection()
{
    int yPos = m_y + 340;
    
    // Section header
    CreateLabel(m_prefixName + "AdaptiveFilter_Header", "ADAPTIVE FILTERS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Market regime info
    DrawColoredLabel("SonicR_Dash_Regime", "Regime: " + m_adaptiveFilters.GetCurrentRegimeAsString(), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetCurrentRegime() == 1 ? m_bullishColor : 
                    (m_adaptiveFilters.GetCurrentRegime() == -1 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Trend info
    string trendDir = "";
    int direction = m_adaptiveFilters.GetTrendDirection();
    if(direction > 0) trendDir = "Up";
    else if(direction < 0) trendDir = "Down";
    else trendDir = "Sideways";
    
    DrawColoredLabel("SonicR_Dash_Trend", "Trend: " + trendDir + " (" + 
                     DoubleToString(m_adaptiveFilters.GetTrendStrength(), 1) + ")", 
                    15, yPos, m_textColor, m_adaptiveFilters.GetTrendDirection() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetTrendDirection() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Volatility 
    DrawColoredLabel("SonicR_Dash_Vol", "Volatility: " + 
                     DoubleToString(m_adaptiveFilters.GetVolatilityRatio(), 2), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetVolatilityRatio() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetVolatilityRatio() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Parameters
    DrawColoredLabel("SonicR_Dash_Risk", "Risk %: " + 
                     DoubleToString(m_adaptiveFilters.GetBaseRiskPercent(_Symbol), 2), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetBaseRiskPercent(_Symbol) > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetBaseRiskPercent(_Symbol) < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_RR", "Min R:R: " + 
                     DoubleToString(m_adaptiveFilters.GetMinRR(), 1), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetMinRR() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetMinRR() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_MaxTrades", "Max Trades: " + 
                     IntegerToString(m_adaptiveFilters.GetMaxTradesForRegime()), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetMaxTradesForRegime() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetMaxTradesForRegime() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_Scout", "Scout Entries: " + 
                     (m_adaptiveFilters.ShouldUseScoutEntries() ? "Yes" : "No"), 
                    15, yPos, m_textColor, m_adaptiveFilters.ShouldUseScoutEntries() ? m_bullishColor : m_neutralColor, 8);
}

//+------------------------------------------------------------------+
//| Create PVSRA section                                             |
//+------------------------------------------------------------------+
void CDashboard::CreatePVSRASection()
{
    int yPos = m_y + 420;
    
    // Section header
    CreateLabel(m_prefixName + "PVSRA_Header", "PVSRA ANALYSIS", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Current bar type
    string barType = "Neutral";
    int currentType = m_pvsra.GetBarType(0);
    if(currentType > 0) barType = "Bullish";
    else if(currentType < 0) barType = "Bearish";
    
    DrawColoredLabel("SonicR_Dash_BarType", "Bar Type: " + barType, 
                    15, yPos, m_textColor, m_adaptiveFilters.GetCurrentRegime() == 1 ? m_bullishColor : 
                    (m_adaptiveFilters.GetCurrentRegime() == -1 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Power values
    string bullPower = DoubleToString(m_pvsra.GetBullPower(0), 1);
    string bearPower = DoubleToString(m_pvsra.GetBearPower(0), 1);
    
    DrawColoredLabel("SonicR_Dash_Power", "Power: Bull=" + bullPower + " / Bear=" + bearPower, 
                    15, yPos, m_textColor, m_adaptiveFilters.GetCurrentRegime() == 1 ? m_bullishColor : 
                    (m_adaptiveFilters.GetCurrentRegime() == -1 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Confirmation status
    DrawColoredLabel("SonicR_Dash_BullConfirm", "Bull Confirm: " + 
                     (m_pvsra.IsBullishConfirmation() ? "YES" : "NO"), 
                    15, yPos, m_pvsra.IsBullishConfirmation() ? m_bullishColor : m_neutralColor, 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_BearConfirm", "Bear Confirm: " + 
                     (m_pvsra.IsBearishConfirmation() ? "YES" : "NO"), 
                    15, yPos, m_pvsra.IsBearishConfirmation() ? m_bearishColor : m_neutralColor, 8);
    yPos += 15;
    
    // Divergence
    DrawColoredLabel("SonicR_Dash_Divergence", "Divergence: " + 
                     (m_pvsra.IsBullishDivergence() ? "Bullish" : 
                     (m_pvsra.IsBearishDivergence() ? "Bearish" : "None")), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetCurrentRegime() == 1 ? m_bullishColor : 
                    (m_adaptiveFilters.GetCurrentRegime() == -1 ? m_bearishColor : m_neutralColor), 8);
}

//+------------------------------------------------------------------+
//| Create market regime section                                     |
//+------------------------------------------------------------------+
void CDashboard::CreateMarketRegimeSection()
{
    int yPos = m_y + 500;
    
    // Section header
    CreateLabel(m_prefixName + "MarketRegime_Header", "MARKET REGIME", 
               m_x + 10, yPos, m_headerColor, m_fontSize, m_fontName + " Bold");
    yPos += 20;
    
    // Market regime info
    DrawColoredLabel("SonicR_Dash_MarketRegime", "Regime: " + m_adaptiveFilters.GetCurrentRegimeAsString(), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetCurrentRegime() == 1 ? m_bullishColor : 
                    (m_adaptiveFilters.GetCurrentRegime() == -1 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Trend info
    string trendDir = "";
    int direction = m_adaptiveFilters.GetTrendDirection();
    if(direction > 0) trendDir = "Up";
    else if(direction < 0) trendDir = "Down";
    else trendDir = "Sideways";
    
    DrawColoredLabel("SonicR_Dash_MarketTrend", "Trend: " + trendDir + " (" + 
                     DoubleToString(m_adaptiveFilters.GetTrendStrength(), 1) + ")", 
                    15, yPos, m_textColor, m_adaptiveFilters.GetTrendDirection() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetTrendDirection() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Volatility 
    DrawColoredLabel("SonicR_Dash_MarketVol", "Volatility: " + 
                     DoubleToString(m_adaptiveFilters.GetVolatilityRatio(), 2), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetVolatilityRatio() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetVolatilityRatio() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    // Parameters
    DrawColoredLabel("SonicR_Dash_MarketRisk", "Risk %: " + 
                     DoubleToString(m_adaptiveFilters.GetBaseRiskPercent(_Symbol), 2), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetBaseRiskPercent(_Symbol) > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetBaseRiskPercent(_Symbol) < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_MarketRR", "Min R:R: " + 
                     DoubleToString(m_adaptiveFilters.GetMinRR(), 1), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetMinRR() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetMinRR() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_MarketMaxTrades", "Max Trades: " + 
                     IntegerToString(m_adaptiveFilters.GetMaxTradesForRegime()), 
                    15, yPos, m_textColor, m_adaptiveFilters.GetMaxTradesForRegime() > 0 ? m_bullishColor : 
                    (m_adaptiveFilters.GetMaxTradesForRegime() < 0 ? m_bearishColor : m_neutralColor), 8);
    yPos += 15;
    
    DrawColoredLabel("SonicR_Dash_MarketScout", "Scout Entries: " + 
                     (m_adaptiveFilters.ShouldUseScoutEntries() ? "Yes" : "No"), 
                    15, yPos, m_textColor, m_adaptiveFilters.ShouldUseScoutEntries() ? m_bullishColor : m_neutralColor, 8);
}

//+------------------------------------------------------------------+
//| Create trade stats section                                        |
//+------------------------------------------------------------------+
void CDashboard::CreateTradeStatsSection()
{
    int yPos = m_y + 580;
    
    // Section header
    CreateLabel(m_prefixName + "TradeStats_Header", "TRADE STATISTICS", 
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
//| DrawText method                                                 |
//+------------------------------------------------------------------+
void CDashboard::DrawText(const string name, const string text, const int x, const int y, 
                        const color textColor, const int fontSize = 0)
{
    int size = (fontSize > 0) ? fontSize : m_fontSize;
    
    // Create or update text object
    if(ObjectFind(0, name) < 0) {
        // Create new object
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    }
    
    // Set properties
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
    ObjectSetString(0, name, OBJPROP_FONT, m_fontName);
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
}

//+------------------------------------------------------------------+
//| DrawLabel method                                                |
//+------------------------------------------------------------------+
void CDashboard::DrawLabel(const string name, const string text, const int x, const int y, 
                          const color textColor, const int fontSize = 0)
{
    DrawText(name, text, x, y, textColor, fontSize);
}

//+------------------------------------------------------------------+
//| DrawColoredLabel method                                         |
//+------------------------------------------------------------------+
void CDashboard::DrawColoredLabel(const string name, const string text, const int x, const int y, 
                                 const color textColor, const color valueColor, const int fontSize = 0)
{
    DrawText(name, text, x, y, valueColor, fontSize);
}

//+------------------------------------------------------------------+
//| DrawProgressBar method                                          |
//+------------------------------------------------------------------+
void CDashboard::DrawProgressBar(const string name, const double value, const double maxValue, 
                               const int x, const int y, const int width, const int height, 
                               const color fillColor, const color bgColor)
{
    // Create background rectangle
    string bgName = name + "_BG";
    if(ObjectFind(0, bgName) < 0) {
        ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    }
    
    ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, bgName, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, bgName, OBJPROP_COLOR, clrNONE);
    ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bgColor);
    ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, bgName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
    ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, bgName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);
    
    // Create fill rectangle
    string fillName = name + "_Fill";
    if(ObjectFind(0, fillName) < 0) {
        ObjectCreate(0, fillName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, fillName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    }
    
    // Calculate fill width based on value and maxValue
    int fillWidth = (int)MathRound(width * MathMin(1.0, value / maxValue));
    
    ObjectSetInteger(0, fillName, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, fillName, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, fillName, OBJPROP_XSIZE, fillWidth);
    ObjectSetInteger(0, fillName, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, fillName, OBJPROP_COLOR, clrNONE);
    ObjectSetInteger(0, fillName, OBJPROP_BGCOLOR, fillColor);
    ObjectSetInteger(0, fillName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, fillName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, fillName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, fillName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, fillName, OBJPROP_BACK, false);
    ObjectSetInteger(0, fillName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, fillName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, fillName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, fillName, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Delete all dashboard objects                                      |
//+------------------------------------------------------------------+
void CDashboard::DeleteAllObjects()
{
    ObjectsDeleteAll(0, m_prefixName);
}

//+------------------------------------------------------------------+
//| Create a rectangle object                                         |
//+------------------------------------------------------------------+
void CDashboard::CreateRect(const string name, const int x, const int y, const int width, const int height, 
                           const color bgColor, const color borderColor)
{
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    }
    
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
    ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
    ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
    ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, borderColor);
    ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Create a text label                                               |
//+------------------------------------------------------------------+
void CDashboard::CreateLabel(const string name, const string text, const int x, const int y, 
                            const color textColor, const int fontSize = 0, const string fontFace = "")
{
    if(ObjectFind(0, name) < 0) {
        ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
    }
    
    ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
    
    int actualFontSize = (fontSize > 0) ? fontSize : m_fontSize;
    string actualFontFace = (fontFace != "") ? fontFace : m_fontName;
    
    ObjectSetInteger(0, name, OBJPROP_FONTSIZE, actualFontSize);
    ObjectSetString(0, name, OBJPROP_FONT, actualFontFace);
    ObjectSetString(0, name, OBJPROP_TEXT, text);
    ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
    ObjectSetInteger(0, name, OBJPROP_BACK, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
}

//+------------------------------------------------------------------+
//| Update an existing text label                                     |
//+------------------------------------------------------------------+
void CDashboard::UpdateLabel(const string name, const string text)
{
    if(ObjectFind(0, name) >= 0) {
        ObjectSetString(0, name, OBJPROP_TEXT, text);
    }
}

//+------------------------------------------------------------------+
//| Draw the dashboard                                               |
//+------------------------------------------------------------------+
void CDashboard::Draw()
{
    // Check if dependencies are set
    if(m_adaptiveFilters == NULL || m_pvsra == NULL) {
        if(m_logger) m_logger.Error("Cannot draw dashboard: dependencies not set");
        return;
    }
    
    // Clean up existing objects
    DeleteAllObjects();
    
    // Create the main panel and sections
    CreatePanel();
    CreateHeader();
    CreatePropFirmSection();
    CreateSignalSection();
    CreateRiskSection();
    CreateAdaptiveFilterSection();
    CreatePVSRASection();
    CreateMarketRegimeSection();
    CreateTradeStatsSection();
    
    // Force immediate update
    Update();
    
    if(m_logger) m_logger.Info("Dashboard drawn");
}