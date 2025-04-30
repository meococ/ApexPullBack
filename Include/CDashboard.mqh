//+------------------------------------------------------------------+
//| CDashboard.mqh - Visual dashboard for EA status and controls      |
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
class CTradeManager;
class CRiskManager;
class CFilterManager;
class CLogger;

//+------------------------------------------------------------------+
//| CDashboard Class - Provides visual dashboard for EA               |
//+------------------------------------------------------------------+
class CDashboard {
private:
    // Dashboard settings
    int m_x;                           // X position on chart
    int m_y;                           // Y position on chart
    int m_width;                       // Dashboard width
    int m_height;                      // Dashboard height
    int m_padding;                     // Padding inside dashboard
    color m_backgroundColor;           // Background color
    color m_borderColor;               // Border color
    color m_textColor;                 // Text color
    color m_bullishColor;              // Color for bullish indicators
    color m_bearishColor;              // Color for bearish indicators
    color m_neutralColor;              // Color for neutral indicators
    string m_fontName;                 // Font name
    int m_fontSize;                    // Font size
    
    // Internal state
    bool m_isVisible;                  // Whether dashboard is visible
    bool m_isExpanded;                 // Whether details panel is expanded
    bool m_settingsVisible;            // Whether settings panel is visible
    
    // Dashboard objects
    string m_bgName;                   // Background rectangle name
    string m_headerName;               // Header text name
    string m_statusName;               // Status text name
    string m_infoSectionNames[];       // Section text names
    string m_buttonNames[];            // Button names
    string m_logDisplayName;           // Log display text name
    
    // Component references
    CIndicatorManager* m_indicators;   // Indicator manager reference
    CTradeManager* m_tradeManager;     // Trade manager reference
    CRiskManager* m_riskManager;       // Risk manager reference
    CFilterManager* m_filterManager;   // Filter manager reference
    CLogger* m_logger;                 // Logger reference
    
    //--- Private methods
    
    // Create dashboard objects
    void CreateDashboardObjects() {
        // Generate unique object names based on chart ID
        long chartId = ChartID();
        m_bgName = "SonicR_BG_" + IntegerToString(chartId);
        m_headerName = "SonicR_Header_" + IntegerToString(chartId);
        m_statusName = "SonicR_Status_" + IntegerToString(chartId);
        m_logDisplayName = "SonicR_Log_" + IntegerToString(chartId);
        
        // Create background rectangle
        ObjectCreate(0, m_bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, m_bgName, OBJPROP_XDISTANCE, m_x);
        ObjectSetInteger(0, m_bgName, OBJPROP_YDISTANCE, m_y);
        ObjectSetInteger(0, m_bgName, OBJPROP_XSIZE, m_width);
        ObjectSetInteger(0, m_bgName, OBJPROP_YSIZE, m_height);
        ObjectSetInteger(0, m_bgName, OBJPROP_BGCOLOR, m_backgroundColor);
        ObjectSetInteger(0, m_bgName, OBJPROP_BORDER_TYPE, BORDER_RAISED);
        ObjectSetInteger(0, m_bgName, OBJPROP_COLOR, m_borderColor);
        ObjectSetInteger(0, m_bgName, OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, m_bgName, OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, m_bgName, OBJPROP_BACK, false);
        ObjectSetInteger(0, m_bgName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, m_bgName, OBJPROP_SELECTED, false);
        ObjectSetInteger(0, m_bgName, OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, m_bgName, OBJPROP_ZORDER, 0);
        
        // Create header text
        ObjectCreate(0, m_headerName, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, m_headerName, OBJPROP_XDISTANCE, m_x + m_padding);
        ObjectSetInteger(0, m_headerName, OBJPROP_YDISTANCE, m_y + m_padding);
        ObjectSetInteger(0, m_headerName, OBJPROP_COLOR, m_textColor);
        ObjectSetInteger(0, m_headerName, OBJPROP_FONTSIZE, m_fontSize);
        ObjectSetString(0, m_headerName, OBJPROP_FONT, m_fontName);
        ObjectSetString(0, m_headerName, OBJPROP_TEXT, "SonicR PropFirm EA v3.0");
        ObjectSetInteger(0, m_headerName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, m_headerName, OBJPROP_HIDDEN, true);
        
        // Create status text
        ObjectCreate(0, m_statusName, OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, m_statusName, OBJPROP_XDISTANCE, m_x + m_padding);
        ObjectSetInteger(0, m_statusName, OBJPROP_YDISTANCE, m_y + m_padding + 25);
        ObjectSetInteger(0, m_statusName, OBJPROP_COLOR, m_textColor);
        ObjectSetInteger(0, m_statusName, OBJPROP_FONTSIZE, m_fontSize - 1);
        ObjectSetString(0, m_statusName, OBJPROP_FONT, m_fontName);
        ObjectSetString(0, m_statusName, OBJPROP_TEXT, "Status: Initializing...");
        ObjectSetInteger(0, m_statusName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, m_statusName, OBJPROP_HIDDEN, true);
        
        // Create log display
        ObjectCreate(0, m_logDisplayName, OBJ_EDIT, 0, 0, 0);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_XDISTANCE, m_x + m_padding);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_YDISTANCE, m_y + m_height - 80);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_XSIZE, m_width - (2 * m_padding));
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_YSIZE, 60);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_COLOR, m_textColor);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_BGCOLOR, m_backgroundColor);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_BORDER_COLOR, m_borderColor);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_FONTSIZE, m_fontSize - 2);
        ObjectSetString(0, m_logDisplayName, OBJPROP_FONT, m_fontName);
        ObjectSetString(0, m_logDisplayName, OBJPROP_TEXT, "Initializing log...");
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_READONLY, true);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_HIDDEN, true);
        
        // Create sections
        string sectionNames[] = {
            "Strategy", "Market", "Risk", "Trades"
        };
        
        ArrayResize(m_infoSectionNames, ArraySize(sectionNames));
        
        for (int i = 0; i < ArraySize(sectionNames); i++) {
            string name = "SonicR_" + sectionNames[i] + "_" + IntegerToString(chartId);
            m_infoSectionNames[i] = name;
            
            ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
            ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x + m_padding);
            ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y + m_padding + 50 + (i * 30));
            ObjectSetInteger(0, name, OBJPROP_COLOR, m_textColor);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, m_fontSize - 1);
            ObjectSetString(0, name, OBJPROP_FONT, m_fontName);
            ObjectSetString(0, name, OBJPROP_TEXT, sectionNames[i] + ": Loading...");
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
        
        // Create buttons
        string buttonLabels[] = {
            "Pause/Resume", "Emergency Mode", "Close All"
        };
        
        ArrayResize(m_buttonNames, ArraySize(buttonLabels));
        
        for (int i = 0; i < ArraySize(buttonLabels); i++) {
            string name = "SonicR_Button_" + IntegerToString(i) + "_" + IntegerToString(chartId);
            m_buttonNames[i] = name;
            
            ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
            ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_x + m_padding + (i * 100));
            ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_y + m_height - 10 - m_padding);
            ObjectSetInteger(0, name, OBJPROP_XSIZE, 95);
            ObjectSetInteger(0, name, OBJPROP_YSIZE, 20);
            ObjectSetInteger(0, name, OBJPROP_COLOR, m_textColor);
            ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_backgroundColor);
            ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, m_borderColor);
            ObjectSetInteger(0, name, OBJPROP_FONTSIZE, m_fontSize - 2);
            ObjectSetString(0, name, OBJPROP_FONT, m_fontName);
            ObjectSetString(0, name, OBJPROP_TEXT, buttonLabels[i]);
            ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
        }
    }
    
    // Update dashboard content
    void UpdateContent() {
        // Skip if dashboard not visible
        if (!m_isVisible) return;
        
        // Update status
        string statusText = "Status: ";
        
        if (m_riskManager != NULL) {
            RiskMetrics metrics = m_riskManager.GetRiskMetrics();
            
            statusText += "DD: " + DoubleToString(metrics.totalDrawdown, 2) + "%, ";
            statusText += "Trades: " + IntegerToString(metrics.openTradesCount) + 
                          "/" + IntegerToString(metrics.dailyTradesCount) + " (open/today)";
        } else {
            statusText += "Initializing...";
        }
        
        ObjectSetString(0, m_statusName, OBJPROP_TEXT, statusText);
        
        // Update strategy section
        if (m_indicators != NULL) {
            MarketState market = m_indicators.GetMarketState();
            string trendText = "Trend: ";
            
            if (market.isBullishTrend) {
                trendText += "Bullish";
                ObjectSetInteger(0, m_infoSectionNames[0], OBJPROP_COLOR, m_bullishColor);
            } else if (market.isBearishTrend) {
                trendText += "Bearish";
                ObjectSetInteger(0, m_infoSectionNames[0], OBJPROP_COLOR, m_bearishColor);
            } else {
                trendText += "Neutral";
                ObjectSetInteger(0, m_infoSectionNames[0], OBJPROP_COLOR, m_neutralColor);
            }
            
            trendText += " | Signal: ";
            
            if (m_indicators.IsBuySignalActive()) {
                trendText += "BUY";
                ObjectSetInteger(0, m_infoSectionNames[0], OBJPROP_COLOR, m_bullishColor);
            } else if (m_indicators.IsSellSignalActive()) {
                trendText += "SELL";
                ObjectSetInteger(0, m_infoSectionNames[0], OBJPROP_COLOR, m_bearishColor);
            } else {
                trendText += "None";
            }
            
            ObjectSetString(0, m_infoSectionNames[0], OBJPROP_TEXT, trendText);
        }
        
        // Update market section
        if (m_indicators != NULL) {
            MarketState market = m_indicators.GetMarketState();
            string marketText = "Market: ADX=" + DoubleToString(market.adxValue, 1);
            marketText += " | ATR=" + DoubleToString(market.atrValue, _Digits);
            
            if (m_filterManager != NULL) {
                string sessionName = "Unknown";
                if (m_filterManager != NULL) {
                    marketText += " | News: " + (m_filterManager.IsNewsFilterActive() ? "ACTIVE" : "Clear");
                }
            }
            
            ObjectSetString(0, m_infoSectionNames[1], OBJPROP_TEXT, marketText);
        }
        
        // Update risk section
        if (m_riskManager != NULL) {
            RiskMetrics metrics = m_riskManager.GetRiskMetrics();
            string riskText = "Risk: Daily DD=" + DoubleToString(metrics.dailyDrawdown, 2) + 
                             "% | Total DD=" + DoubleToString(metrics.totalDrawdown, 2) + "%";
            
            // Set color based on drawdown levels
            if (metrics.totalDrawdown > metrics.totalDrawdownLimit * 0.7) {
                ObjectSetInteger(0, m_infoSectionNames[2], OBJPROP_COLOR, m_bearishColor);
            } else if (metrics.totalDrawdown > metrics.totalDrawdownLimit * 0.5) {
                ObjectSetInteger(0, m_infoSectionNames[2], OBJPROP_COLOR, m_neutralColor);
            } else {
                ObjectSetInteger(0, m_infoSectionNames[2], OBJPROP_COLOR, m_textColor);
            }
            
            ObjectSetString(0, m_infoSectionNames[2], OBJPROP_TEXT, riskText);
        }
        
        // Update trades section
        if (m_tradeManager != NULL) {
            string tradesText = "Trades: ";
            tradesText += IntegerToString(m_tradeManager.GetOpenTradesCount()) + " open | ";
            tradesText += "Profit: " + DoubleToString(m_tradeManager.GetTotalProfit(), 2);
            
            // Set color based on profit
            double profit = m_tradeManager.GetTotalProfit();
            if (profit > 0) {
                ObjectSetInteger(0, m_infoSectionNames[3], OBJPROP_COLOR, m_bullishColor);
            } else if (profit < 0) {
                ObjectSetInteger(0, m_infoSectionNames[3], OBJPROP_COLOR, m_bearishColor);
            } else {
                ObjectSetInteger(0, m_infoSectionNames[3], OBJPROP_COLOR, m_textColor);
            }
            
            ObjectSetString(0, m_infoSectionNames[3], OBJPROP_TEXT, tradesText);
        }
        
        // Update log display
        if (m_logger != NULL) {
            string logEntries[];
            m_logger.GetRecentLogs(logEntries, 3);
            
            string logText = "";
            for (int i = 0; i < ArraySize(logEntries); i++) {
                logText += logEntries[i] + "\n";
            }
            
            ObjectSetString(0, m_logDisplayName, OBJPROP_TEXT, logText);
        }
    }
    
    // Delete all dashboard objects
    void DeleteDashboardObjects() {
        // Delete background
        ObjectDelete(0, m_bgName);
        
        // Delete header and status
        ObjectDelete(0, m_headerName);
        ObjectDelete(0, m_statusName);
        
        // Delete sections
        for (int i = 0; i < ArraySize(m_infoSectionNames); i++) {
            ObjectDelete(0, m_infoSectionNames[i]);
        }
        
        // Delete buttons
        for (int i = 0; i < ArraySize(m_buttonNames); i++) {
            ObjectDelete(0, m_buttonNames[i]);
        }
        
        // Delete log display
        ObjectDelete(0, m_logDisplayName);
    }
    
public:
    // Constructor
    CDashboard() {
        // Set default values
        m_x = DASHBOARD_X;
        m_y = DASHBOARD_Y;
        m_width = DASHBOARD_WIDTH;
        m_height = DASHBOARD_HEIGHT;
        m_padding = DASHBOARD_PADDING;
        m_backgroundColor = C'32,32,32';
        m_borderColor = C'64,64,64';
        m_textColor = clrWhite;
        m_bullishColor = clrLime;
        m_bearishColor = clrRed;
        m_neutralColor = clrGray;
        m_fontName = "Arial";
        m_fontSize = 10;
        
        // Initialize state
        m_isVisible = false;
        m_isExpanded = false;
        m_settingsVisible = false;
        
        // Initialize component references
        m_indicators = NULL;
        m_tradeManager = NULL;
        m_riskManager = NULL;
        m_filterManager = NULL;
        m_logger = NULL;
    }
    
    // Destructor
    ~CDashboard() {
        // Clean up objects
        DeleteDashboardObjects();
    }
    
    // Initialize dashboard
    bool Initialize() {
        // Create dashboard objects
        CreateDashboardObjects();
        
        // Set dashboard visible
        m_isVisible = true;
        
        return true;
    }
    
    // Update dashboard
    void Update() {
        UpdateContent();
    }
    
    // Process dashboard events
    bool ProcessEvents(int id, long& lparam, double& dparam, string& sparam) {
        // Skip if not a click event
        if (id != CHARTEVENT_OBJECT_CLICK) return false;
        
        // Check if button was clicked
        for (int i = 0; i < ArraySize(m_buttonNames); i++) {
            if (sparam == m_buttonNames[i]) {
                switch (i) {
                    case 0: // Pause/Resume
                        OnPauseButtonClick();
                        return true;
                    case 1: // Emergency Mode
                        OnEmergencyButtonClick();
                        return true;
                    case 2: // Close All
                        OnCloseAllButtonClick();
                        return true;
                }
            }
        }
        
        return false;
    }
    
    // Show dashboard
    void Show() {
        if (m_isVisible) return;
        
        // Show all objects
        ObjectSetInteger(0, m_bgName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, m_headerName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, m_statusName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        
        for (int i = 0; i < ArraySize(m_infoSectionNames); i++) {
            ObjectSetInteger(0, m_infoSectionNames[i], OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        }
        
        for (int i = 0; i < ArraySize(m_buttonNames); i++) {
            ObjectSetInteger(0, m_buttonNames[i], OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        }
        
        m_isVisible = true;
        
        // Update content
        UpdateContent();
        
        // Redraw chart
        ChartRedraw(0);
    }
    
    // Hide dashboard
    void Hide() {
        if (!m_isVisible) return;
        
        // Hide all objects
        ObjectSetInteger(0, m_bgName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, m_headerName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, m_statusName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        ObjectSetInteger(0, m_logDisplayName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        
        for (int i = 0; i < ArraySize(m_infoSectionNames); i++) {
            ObjectSetInteger(0, m_infoSectionNames[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
        
        for (int i = 0; i < ArraySize(m_buttonNames); i++) {
            ObjectSetInteger(0, m_buttonNames[i], OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
        }
        
        m_isVisible = false;
        
        // Redraw chart
        ChartRedraw(0);
    }
    
    // Toggle dashboard visibility
    void Toggle() {
        if (m_isVisible) {
            Hide();
        } else {
            Show();
        }
    }
    
    // Set dashboard position
    void SetPosition(int x, int y) {
        m_x = x;
        m_y = y;
        
        // Update object positions if visible
        if (m_isVisible) {
            // Update all object positions
            ObjectSetInteger(0, m_bgName, OBJPROP_XDISTANCE, m_x);
            ObjectSetInteger(0, m_bgName, OBJPROP_YDISTANCE, m_y);
            
            ObjectSetInteger(0, m_headerName, OBJPROP_XDISTANCE, m_x + m_padding);
            ObjectSetInteger(0, m_headerName, OBJPROP_YDISTANCE, m_y + m_padding);
            
            ObjectSetInteger(0, m_statusName, OBJPROP_XDISTANCE, m_x + m_padding);
            ObjectSetInteger(0, m_statusName, OBJPROP_YDISTANCE, m_y + m_padding + 25);
            
            ObjectSetInteger(0, m_logDisplayName, OBJPROP_XDISTANCE, m_x + m_padding);
            ObjectSetInteger(0, m_logDisplayName, OBJPROP_YDISTANCE, m_y + m_height - 80);
            
            // Update sections
            for (int i = 0; i < ArraySize(m_infoSectionNames); i++) {
                ObjectSetInteger(0, m_infoSectionNames[i], OBJPROP_XDISTANCE, m_x + m_padding);
                ObjectSetInteger(0, m_infoSectionNames[i], OBJPROP_YDISTANCE, m_y + m_padding + 50 + (i * 30));
            }
            
            // Update buttons
            for (int i = 0; i < ArraySize(m_buttonNames); i++) {
                ObjectSetInteger(0, m_buttonNames[i], OBJPROP_XDISTANCE, m_x + m_padding + (i * 100));
                ObjectSetInteger(0, m_buttonNames[i], OBJPROP_YDISTANCE, m_y + m_height - 10 - m_padding);
            }
            
            // Redraw chart
            ChartRedraw(0);
        }
    }
    
    // Set dashboard colors
    void SetColors(color bullish, color bearish, color neutral) {
        m_bullishColor = bullish;
        m_bearishColor = bearish;
        m_neutralColor = neutral;
    }
    
    // Handle pause button click
    void OnPauseButtonClick() {
        // Check if we have valid manager
        extern CSonicREAManager* g_manager; // External reference to main manager
        
        if (g_manager != NULL) {
            g_manager.TogglePause();
            
            // Update button text based on state
            string buttonText = g_manager.IsPaused() ? "Resume" : "Pause";
            ObjectSetString(0, m_buttonNames[0], OBJPROP_TEXT, buttonText);
            
            // Log action
            if (m_logger != NULL) {
                m_logger.Info("User action: " + buttonText + " EA");
            }
        }
    }
    
    // Handle emergency button click
    void OnEmergencyButtonClick() {
        // Check if we have valid manager
        extern CSonicREAManager* g_manager; // External reference to main manager
        
        if (g_manager != NULL) {
            // Toggle emergency mode
            if (g_manager.IsEmergencyMode()) {
                g_manager.DeactivateEmergencyMode();
                ObjectSetString(0, m_buttonNames[1], OBJPROP_TEXT, "Emergency Mode");
            } else {
                g_manager.ActivateEmergencyMode();
                ObjectSetString(0, m_buttonNames[1], OBJPROP_TEXT, "Normal Mode");
            }
            
            // Log action
            if (m_logger != NULL) {
                m_logger.Info("User action: " + (g_manager.IsEmergencyMode() ? 
                              "Activated" : "Deactivated") + " Emergency Mode");
            }
        }
    }
    
    // Handle close all button click
    void OnCloseAllButtonClick() {
        // Check if we have valid trade manager
        if (m_tradeManager != NULL) {
            // Ask for confirmation
            if (MessageBox("Close all open positions?", "Confirmation", MB_YESNO) == IDYES) {
                bool success = m_tradeManager.CloseAllPositions();
                
                // Log action
                if (m_logger != NULL) {
                    m_logger.Info("User action: Close All Positions - " + 
                                 (success ? "Success" : "Partial/Failed"));
                }
            }
        }
    }
    
    //--- Setters
    
    // Set indicator manager reference
    void SetIndicatorManager(CIndicatorManager* indicators) {
        m_indicators = indicators;
    }
    
    // Set trade manager reference
    void SetTradeManager(CTradeManager* tradeManager) {
        m_tradeManager = tradeManager;
    }
    
    // Set risk manager reference
    void SetRiskManager(CRiskManager* riskManager) {
        m_riskManager = riskManager;
    }
    
    // Set filter manager reference
    void SetFilterManager(CFilterManager* filterManager) {
        m_filterManager = filterManager;
    }
    
    // Set logger reference
    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }
};