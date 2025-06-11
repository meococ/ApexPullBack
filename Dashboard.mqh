//+------------------------------------------------------------------+
//|                                                   Dashboard.mqh |
//|                      APEX PULLBACK EA v14.0 - Professional Edition|
//|               Copyright 2023-2024, APEX Trading Systems           |
//+------------------------------------------------------------------+

#ifndef _DASHBOARD_MQH_
#define _DASHBOARD_MQH_

#include <Object.mqh>
#include <Canvas\Canvas.mqh>
#include "Logger.mqh"
#include "MarketProfile.mqh"
#include "RiskManager.mqh"
#include "NewsFilter.mqh"
#include "AssetDNA.mqh" // Module phân tích DNA tài sản (thay thế AssetProfiler)
#include "CommonStructs.mqh"
#include "Enums.mqh"

// Sử dụng namespace ApexPullback
namespace ApexPullback {

//+------------------------------------------------------------------+
//| Hàm GetAdaptiveModeString                                        |
//+------------------------------------------------------------------+
// Hàm hỗ trợ để lấy chuỗi ENUM_ADAPTIVE_MODE
string GetAdaptiveModeString(ENUM_ADAPTIVE_MODE mode)
{
    switch(mode)
    {
        case MODE_MANUAL: return "Manual";
        case MODE_CONSERVATIVE: return "Conservative";
        case MODE_BALANCED: return "Balanced";
        case MODE_AGGRESSIVE: return "Aggressive";
        case MODE_LOG_ONLY: return "Log Only";
        case MODE_ADAPTIVE_TRAILING: return "Adaptive Trailing";
        case MODE_DYNAMIC_LOT: return "Dynamic Lot";
        case MODE_HYBRID: return "Hybrid";
        default: return "Unknown";
    }
}





//+------------------------------------------------------------------+
//| Lớp Dashboard                                                     |
//+------------------------------------------------------------------+

class CDashboard
{
private:
    // Tham chiếu đến các module khác - không cần thêm namespace ApexPullback vì đã ở trong namespace này
    CMarketProfile* m_MarketProfile;          // Thông tin thị trường
    CRiskManager*         m_RiskManager;      // Thông tin quản lý rủi ro
    CNewsFilter*          m_NewsFilter;       // Thông tin tin tức
    CAssetProfiler*       m_AssetProfiler;    // Thông tin tài sản

    // Thông số hiển thị
    string   m_Symbol;             // Cặp tiền hiện tại
    string   m_EAVersion;          // Phiên bản EA
    string   m_OrderComment;       // Comment cho lệnh
    
    // Vị trí hiển thị
    int      m_DashX;              // Tọa độ X
    int      m_DashY;              // Tọa độ Y
    int      m_Width;              // Chiều rộng
    int      m_Height;             // Chiều cao
    
    // Cài đặt màu sắc
    color    m_BackgroundColor;    // Màu nền
    color    m_TitleColor;         // Màu tiêu đề
    color    m_TextColor;          // Màu text
    color    m_ValueColor;         // Màu giá trị
    color    m_AlertColor;         // Màu cảnh báo
    color    m_SuccessColor;       // Màu thành công
    color    m_ChartBorderColor;   // Màu viền biểu đồ
    
    // Cài đặt hiển thị
    bool     m_ShowDetailedProfile;  // Hiển thị chi tiết profile
    bool     m_ShowNews;             // Hiển thị tin tức
    bool     m_ShowPerformance;      // Hiển thị hiệu suất
    
    // Dữ liệu hiển thị
    MarketProfileData m_LastProfile;  // Thông tin market profile gần nhất
    
    // ID các đối tượng
    string   m_ObjPrefix;          // Tiền tố cho tên đối tượng

    // ID cho các control tương tác mới
    string   m_btnPauseTradesID;
    string   m_btnCloseAllID;
    string   m_ddRiskModeID;
    string   m_ddRiskModeOptionConservativeID;
    string   m_ddRiskModeOptionBalancedID;
    string   m_ddRiskModeOptionAggressiveID;
    bool     m_isRiskModeDropdownOpen; // Trạng thái dropdown đang mở hay đóng
    
    // Hàm khởi tạo màu sắc
    void InitializeColors()
    {
        m_BackgroundColor = (color)0xF0F0F0;  // Xám nhạt
        m_TitleColor = (color)0x008246;          // Xanh đậm
        m_TextColor = (color)0x323232;           // Xám đậm
        m_ValueColor = clrBlack;                 // Đen
        m_AlertColor = (color)0x3232C8;          // Đỏ
        m_SuccessColor = (color)0x32AA32;        // Xanh lá
        m_ChartBorderColor = (color)0xB4B4B4;    // Xám trung bình
    }
    
    // Tạo các đối tượng hiển thị
    void CreateBackground();
    void CreateHeader();
    void CreateMarketPanel();
    void CreateRiskPanel();
    void CreateNewsPanel();
    void CreatePerformancePanel();
    void CreateValueZoneVisualizer();

    // Hàm tạo các control tương tác mới
    void CreateInteractiveControls(); // Hàm tổng hợp gọi các hàm tạo control bên dưới
    void CreatePauseButton();
    void CreateCloseAllButton();
    void CreateRiskModeDropdown();
    void CreateRiskModeDropdownOptions(); // Hàm tạo các lựa chọn cho dropdown
    void DeleteRiskModeDropdownOptions(); // Hàm xóa các lựa chọn của dropdown
    
    // Vẽ biểu đồ mini
    void DrawMiniChart(string name, int x, int y, int width, int height, double &data[], 
                      double minValue, double maxValue, color lineColor, string title,
                      string subtitle, bool showGrid);
    
    // Xóa đối tượng theo prefix
    void DeleteObjectsByPrefix(string prefix);
    
    // Hỗ trợ hiển thị
    color GetTrendColor(ENUM_MARKET_TREND trend);
    color GetRegimeColor(ENUM_MARKET_REGIME regime);
    string GetTrendString(ENUM_MARKET_TREND trend);
    string GetRegimeString(ENUM_MARKET_REGIME regime);
    string GetSessionString(ENUM_SESSION session);
    
public:
    // Hàm khởi tạo
    CDashboard();
    ~CDashboard();
    
    // Khởi tạo Dashboard
    bool Initialize(string symbol, string eaVersion, string orderComment);
    
    // Thiết lập các module liên kết
    // Các hàm setter không cần dùng namespace ApexPullback:: khi đã ở trong namespace
    void SetMarketProfile(CMarketProfile* marketProfile) { m_MarketProfile = marketProfile; }
    void SetRiskManager(CRiskManager* riskManager) { m_RiskManager = riskManager; }
    void SetNewsFilter(CNewsFilter* newsFilter) { m_NewsFilter = newsFilter; }
    void SetAssetProfiler(CAssetProfiler* assetProfiler) { m_AssetProfiler = assetProfiler; }
    
    // Cập nhật Dashboard
    void Update(MarketProfileData &profile);

    // Xử lý sự kiện click cho các control
    void OnClick(string object_name);
    
    // Hiển thị/ẩn các phần
    void ShowDetailedProfile(bool show) { m_ShowDetailedProfile = show; }
    void ShowNews(bool show) { m_ShowNews = show; }
    void ShowPerformance(bool show) { m_ShowPerformance = show; }
    
    // Cập nhật vị trí và kích thước
    void SetPosition(int x, int y) { m_DashX = x; m_DashY = y; }
    void SetSize(int width, int height) { m_Width = width; m_Height = height; }
    
    // Xóa tất cả đối tượng
    void Clear();
};

//+------------------------------------------------------------------+
//| Hàm khởi tạo mặc định                                            |
//+------------------------------------------------------------------+
CDashboard::CDashboard()
{
    m_DashX = 20;
    m_DashY = 20;
    m_Width = 300;
    m_Height = 500;
    
    m_ObjPrefix = "APEX_DASH_";
    
    m_ShowDetailedProfile = true;
    m_ShowNews = true;
    m_ShowPerformance = true;
    
    InitializeColors();
    
    m_MarketProfile = NULL;
    m_RiskManager = NULL;
    m_NewsFilter = NULL;
    m_AssetProfiler = NULL;
}

//+------------------------------------------------------------------+
//| Hàm hủy                                                           |
//+------------------------------------------------------------------+
CDashboard::~CDashboard()
{
    Clear();
}

//+------------------------------------------------------------------+
//| Khởi tạo Dashboard                                                |
//+------------------------------------------------------------------+
bool CDashboard::Initialize(string symbol, string eaVersion, string orderComment)
{
    m_Symbol = symbol;
    m_EAVersion = eaVersion;
    m_OrderComment = orderComment;
    
    // Xóa các đối tượng cũ nếu có
    Clear();
    
    // Tạo background
    CreateBackground();

    // Tạo các control tương tác
    CreateInteractiveControls();
    
    return true;
}

//+------------------------------------------------------------------+
//| Xóa tất cả đối tượng thuộc Dashboard                              |
//+------------------------------------------------------------------+
void CDashboard::Clear()
{
    DeleteObjectsByPrefix(m_ObjPrefix); // Xóa các đối tượng đồ họa cũ
    // Đảm bảo các ID control mới cũng được thêm vào prefix hoặc xóa riêng ở đây nếu cần
    // Ví dụ, nếu các control mới không dùng m_ObjPrefix chung:
    ObjectDelete(0, m_btnPauseTradesID);
    ObjectDelete(0, m_btnCloseAllID);
    ObjectDelete(0, m_ddRiskModeID);
    DeleteRiskModeDropdownOptions(); // Xóa các option của dropdown
    m_isRiskModeDropdownOpen = false;
}

//+------------------------------------------------------------------+
//| Hàm tạo các control tương tác                                     |
//+------------------------------------------------------------------+
void CDashboard::CreateInteractiveControls()
{
    // Khởi tạo ID cho các control
    m_btnPauseTradesID = m_ObjPrefix + "PauseButton";
    m_btnCloseAllID    = m_ObjPrefix + "CloseAllButton";
    m_ddRiskModeID     = m_ObjPrefix + "RiskModeDD";
    m_ddRiskModeOptionConservativeID = m_ObjPrefix + "RiskModeOptConservative";
    m_ddRiskModeOptionBalancedID     = m_ObjPrefix + "RiskModeOptBalanced";
    m_ddRiskModeOptionAggressiveID   = m_ObjPrefix + "RiskModeOptAggressive";
    m_isRiskModeDropdownOpen = false;

    CreatePauseButton();
    CreateCloseAllButton();
    CreateRiskModeDropdown();
    // Các options của dropdown sẽ được tạo khi click vào dropdown chính
}

//+------------------------------------------------------------------+
//| Tạo nút "PAUSE NEW TRADES"                                       |
//+------------------------------------------------------------------+
void CDashboard::CreatePauseButton()
{
    int buttonX = m_DashX + 10;
    int buttonY = m_DashY + m_Height - 40; // Vị trí gần cuối dashboard
    int buttonWidth = 130;
    int buttonHeight = 25;

    ObjectCreate(0, m_btnPauseTradesID, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_XDISTANCE, buttonX);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_YDISTANCE, buttonY);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_XSIZE, buttonWidth);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_YSIZE, buttonHeight);

    bool isPaused = false;
    if(g_EAContext != NULL && g_EAContext.TradeManager != NULL)
    {
        isPaused = g_EAContext.TradeManager.IsTradingPaused();
    }

    ObjectSetString(0, m_btnPauseTradesID, OBJPROP_TEXT, isPaused ? "RESUME TRADES" : "PAUSE NEW TRADES");
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_BGCOLOR, isPaused ? m_AlertColor : m_SuccessColor); // Initial color based on state
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_BORDER_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, m_btnPauseTradesID, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_STATE, isPaused); // Initial state
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_SELECTED, false);
}

//+------------------------------------------------------------------+
//| Tạo nút "CLOSE ALL POSITIONS"                                    |
//+------------------------------------------------------------------+
void CDashboard::CreateCloseAllButton()
{
    int buttonX = m_DashX + 10 + 130 + 10; // Cách nút Pause 10px
    int buttonY = m_DashY + m_Height - 40;
    int buttonWidth = 130;
    int buttonHeight = 25;

    ObjectCreate(0, m_btnCloseAllID, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_XDISTANCE, buttonX);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_YDISTANCE, buttonY);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_XSIZE, buttonWidth);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_YSIZE, buttonHeight);
    ObjectSetString(0, m_btnCloseAllID, OBJPROP_TEXT, "CLOSE ALL POSITIONS");
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_BGCOLOR, (color)0xFFE0E0); // Màu nền hơi đỏ để cảnh báo
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_BORDER_COLOR, m_AlertColor);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, m_btnCloseAllID, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_STATE, false);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_SELECTED, false);
}

//+------------------------------------------------------------------+
//| Tạo Dropdown "RISK MODE"                                         |
//+------------------------------------------------------------------+
void CDashboard::CreateRiskModeDropdown()
{
    int ddX = m_DashX + 10;
    int ddY = m_DashY + m_Height - 40 - 30; // Phía trên các nút
    int ddWidth = 270; // Chiều rộng bằng tổng 2 nút kia
    int ddHeight = 25;

    ObjectCreate(0, m_ddRiskModeID, OBJ_BUTTON, 0, 0, 0); // Dùng button làm dropdown chính
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_XDISTANCE, ddX);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_YDISTANCE, ddY);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_XSIZE, ddWidth);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_YSIZE, ddHeight);
    
    string currentRiskModeStr = "Unknown";
    if(g_EAContext != NULL && g_EAContext.RiskManager != NULL) 
    {
       currentRiskModeStr = GetAdaptiveModeString(g_EAContext.RiskManager.GetAdaptiveMode());
    }
    else if (m_RiskManager != NULL) // Fallback if g_EAContext is not available yet
    {
        currentRiskModeStr = GetAdaptiveModeString(m_RiskManager.GetAdaptiveMode());
    }

    ObjectSetString(0, m_ddRiskModeID, OBJPROP_TEXT, "RISK MODE: " + currentRiskModeStr + " ▼");
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_BGCOLOR, m_BackgroundColor);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_BORDER_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_FONTSIZE, 8);
    ObjectSetString(0, m_ddRiskModeID, OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_STATE, false);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_SELECTABLE, true);
    ObjectSetInteger(0, m_ddRiskModeID, OBJPROP_SELECTED, false);
}

//+------------------------------------------------------------------+
//| Tạo các lựa chọn cho Risk Mode Dropdown                           |
//+------------------------------------------------------------------+
void CDashboard::CreateRiskModeDropdownOptions()
{
    if(m_isRiskModeDropdownOpen) return; // Đã mở rồi thì không tạo lại

    int optionX = ObjectGetInteger(0, m_ddRiskModeID, OBJPROP_XDISTANCE);
    int optionYBase = ObjectGetInteger(0, m_ddRiskModeID, OBJPROP_YDISTANCE) - 3*25; // Hiện phía trên dropdown chính
    int optionWidth = ObjectGetInteger(0, m_ddRiskModeID, OBJPROP_XSIZE);
    int optionHeight = 25;

    // Conservative
    ObjectCreate(0, m_ddRiskModeOptionConservativeID, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_XDISTANCE, optionX);
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_YDISTANCE, optionYBase + 2*optionHeight); // Adjusted Y for top-down
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_XSIZE, optionWidth);
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_YSIZE, optionHeight);
    ObjectSetString(0, m_ddRiskModeOptionConservativeID, OBJPROP_TEXT, GetAdaptiveModeString(MODE_CONSERVATIVE));
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_BGCOLOR, m_BackgroundColor);
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, m_ddRiskModeOptionConservativeID, OBJPROP_SELECTABLE, true);

    // Balanced
    ObjectCreate(0, m_ddRiskModeOptionBalancedID, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_XDISTANCE, optionX);
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_YDISTANCE, optionYBase + optionHeight); // Adjusted Y
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_XSIZE, optionWidth);
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_YSIZE, optionHeight);
    ObjectSetString(0, m_ddRiskModeOptionBalancedID, OBJPROP_TEXT, GetAdaptiveModeString(MODE_BALANCED));
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_BGCOLOR, m_BackgroundColor);
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, m_ddRiskModeOptionBalancedID, OBJPROP_SELECTABLE, true);

    // Aggressive
    ObjectCreate(0, m_ddRiskModeOptionAggressiveID, OBJ_BUTTON, 0, 0, 0);
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_XDISTANCE, optionX);
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_YDISTANCE, optionYBase); // Adjusted Y (topmost)
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_XSIZE, optionWidth);
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_YSIZE, optionHeight);
    ObjectSetString(0, m_ddRiskModeOptionAggressiveID, OBJPROP_TEXT, GetAdaptiveModeString(MODE_AGGRESSIVE));
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_BGCOLOR, m_BackgroundColor);
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, m_ddRiskModeOptionAggressiveID, OBJPROP_SELECTABLE, true);

    m_isRiskModeDropdownOpen = true;
    ChartRedraw();
}
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Xóa các lựa chọn của Risk Mode Dropdown                           |
//+------------------------------------------------------------------+
void CDashboard::DeleteRiskModeDropdownOptions()
{
    ObjectDelete(0, m_ddRiskModeOptionConservativeID);
    ObjectDelete(0, m_ddRiskModeOptionBalancedID);
    ObjectDelete(0, m_ddRiskModeOptionAggressiveID);
    m_isRiskModeDropdownOpen = false;
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Xử lý sự kiện click cho các control                              |
//+------------------------------------------------------------------+

void CDashboard::OnClick(string object_name)
{
    if(g_EAContext == NULL) 
    {
        Print("CDashboard::OnClick - g_EAContext is NULL!");
        return;
    }

    if(object_name == m_btnPauseTradesID)
    {
        if(g_EAContext.TradeManager != NULL) 
        {
            bool isPaused = g_EAContext.TradeManager.IsTradingPaused();
            g_EAContext.TradeManager.SetTradingPaused(!isPaused);
            isPaused = !isPaused; // Cập nhật trạng thái sau khi thay đổi

            ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_STATE, isPaused);
            ObjectSetString(0, m_btnPauseTradesID, OBJPROP_TEXT, isPaused ? "RESUME TRADES" : "PAUSE NEW TRADES");
            ObjectSetInteger(0, m_btnPauseTradesID, OBJPROP_BGCOLOR, isPaused ? m_AlertColor : m_SuccessColor);
            PrintFormat("Trading paused state: %s", isPaused ? "PAUSED" : "ACTIVE");
        }
    }
    else if(object_name == m_btnCloseAllID)
    {
        if(g_EAContext.TradeManager != NULL) 
        {
            g_EAContext.TradeManager.CloseAllPositionsByMagic(0); // Giả sử magic number là 0 hoặc lấy từ context
            PrintFormat("Close All Positions button clicked. Attempting to close all positions.");
        }
        // Hiệu ứng nhấn nút
        ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_STATE, true);
        ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_BGCOLOR, m_AlertColor); // Đổi màu nền khi nhấn
        ChartRedraw();
        Sleep(200); 
        ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_STATE, false);
        ObjectSetInteger(0, m_btnCloseAllID, OBJPROP_BGCOLOR, (color)0xFFE0E0); // Trả lại màu nền ban đầu

    }
    else if(object_name == m_ddRiskModeID)
    {
        if(m_isRiskModeDropdownOpen)
        {
            DeleteRiskModeDropdownOptions();
            string currentText = ObjectGetString(0, m_ddRiskModeID, OBJPROP_TEXT);
            if(StringFind(currentText, " ▲") >=0) ObjectSetString(0, m_ddRiskModeID, OBJPROP_TEXT, StringSubstr(currentText,0, StringLen(currentText)-2) + " ▼");
        }
        else
        {
            CreateRiskModeDropdownOptions();
            string currentText = ObjectGetString(0, m_ddRiskModeID, OBJPROP_TEXT);
            if(StringFind(currentText, " ▼") >=0) ObjectSetString(0, m_ddRiskModeID, OBJPROP_TEXT, StringSubstr(currentText,0, StringLen(currentText)-2) + " ▲");
        }
    }
    else if(object_name == m_ddRiskModeOptionConservativeID || 
            object_name == m_ddRiskModeOptionBalancedID || 
            object_name == m_ddRiskModeOptionAggressiveID)
    {
        ENUM_ADAPTIVE_MODE newRiskMode = MODE_MANUAL; 

        if(object_name == m_ddRiskModeOptionConservativeID) { newRiskMode = MODE_CONSERVATIVE; }
        else if(object_name == m_ddRiskModeOptionBalancedID) { newRiskMode = MODE_BALANCED; } 
        else if(object_name == m_ddRiskModeOptionAggressiveID) { newRiskMode = MODE_AGGRESSIVE; }

        if(g_EAContext.RiskManager != NULL)
        {
            g_EAContext.RiskManager.SetAdaptiveMode(newRiskMode);
            string selectedModeStr = GetAdaptiveModeString(newRiskMode);
            ObjectSetString(0, m_ddRiskModeID, OBJPROP_TEXT, "RISK MODE: " + selectedModeStr + " ▼");
            PrintFormat("Risk Mode changed to: %s", selectedModeStr);
        }
        DeleteRiskModeDropdownOptions();
    }
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Cập nhật Dashboard với thông tin mới                              |
//+------------------------------------------------------------------+
void CDashboard::Update(MarketProfileData &profile)
{
    // Lưu thông tin profile mới nhất
    m_LastProfile = profile;
    
    // Xóa đối tượng động (giữ lại background)
    DeleteObjectsByPrefix(m_ObjPrefix + "CONTENT_");
    
    // Tạo các panel
    CreateHeader();
    CreateMarketPanel();
    CreateRiskPanel();
    
    if(m_ShowNews && m_NewsFilter != NULL) {
        CreateNewsPanel();
    }
    
    if(m_ShowPerformance) {
        CreatePerformancePanel();
    }
    
    // Hiển thị Value Zone
    CreateValueZoneVisualizer();
    
    // Cập nhật biểu đồ
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| Tạo background cho Dashboard                                      |
//+------------------------------------------------------------------+
void CDashboard::CreateBackground()
{
    string objName = m_ObjPrefix + "BG";
    
    // Tạo rectangle làm nền
    ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, m_DashX);
    ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, m_DashY);
    ObjectSetInteger(0, objName, OBJPROP_XSIZE, m_Width);
    ObjectSetInteger(0, objName, OBJPROP_YSIZE, m_Height);
    ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, m_BackgroundColor);
    ObjectSetInteger(0, objName, OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, objName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, objName, OBJPROP_BACK, false);
    ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, objName, OBJPROP_SELECTED, false);
    ObjectSetInteger(0, objName, OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, objName, OBJPROP_ZORDER, 0);
}

//+------------------------------------------------------------------+
//| Tạo header cho Dashboard                                          |
//+------------------------------------------------------------------+
void CDashboard::CreateHeader()
{
    string prefix = m_ObjPrefix + "CONTENT_HEADER_";
    int headerHeight = 50;
    
    // Tạo thanh title
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, m_DashX);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, m_DashY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, m_Width);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, headerHeight);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);
    
    // Tạo text title
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, m_DashX + 10);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, m_DashY + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, "APEX PULLBACK " + m_EAVersion);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 11);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);
    
    // Tạo text symbol
    ObjectCreate(0, prefix + "SYMBOL", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_XDISTANCE, m_DashX + 10);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_YDISTANCE, m_DashY + 35);
    ObjectSetString(0, prefix + "SYMBOL", OBJPROP_TEXT, m_Symbol + " | " + EnumToString(Period()));
    ObjectSetString(0, prefix + "SYMBOL", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_COLOR, clrWhite);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "SYMBOL", OBJPROP_ZORDER, 2);
    
    // Hiển thị trạng thái EA (Hoạt động/Tạm dừng)
    string statusText = "ĐANG HOẠT ĐỘNG";
    color statusColor = m_SuccessColor;
    
    if(m_RiskManager != NULL && m_RiskManager.IsPaused()) {
        statusText = "TẠM DỪNG";
        statusColor = m_AlertColor;
    }
    
    ObjectCreate(0, prefix + "STATUS", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_XDISTANCE, m_DashX + m_Width - 110);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_YDISTANCE, m_DashY + 25);
    ObjectSetString(0, prefix + "STATUS", OBJPROP_TEXT, statusText);
    ObjectSetString(0, prefix + "STATUS", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_COLOR, statusColor);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_HIDDEN, !m_ShowDashboard);
    ObjectSetInteger(0, prefix + "STATUS", OBJPROP_ZORDER, 2);

    // Hiển thị tên chiến lược
    if(m_EAContext != NULL && m_EAContext.EAInputs.General.StrategyName != "")
    {
        string strategyText = "Strategy: " + m_EAContext.EAInputs.General.StrategyName;
        ObjectCreate(0, prefix + "STRATEGY", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_XDISTANCE, m_DashX + 10);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_YDISTANCE, m_DashY + 50); // Dưới Symbol
        ObjectSetString(0, prefix + "STRATEGY", OBJPROP_TEXT, strategyText);
        ObjectSetString(0, prefix + "STRATEGY", OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_COLOR, clrWhite);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_HIDDEN, !m_ShowDashboard);
        ObjectSetInteger(0, prefix + "STRATEGY", OBJPROP_ZORDER, 2);
    }
}

//+------------------------------------------------------------------+
//| Tạo panel thông tin thị trường                                    |
//+------------------------------------------------------------------+
void CDashboard::CreateMarketPanel()
{
    if(m_MarketProfile == NULL) return;
    
    string prefix = m_ObjPrefix + "CONTENT_MARKET_";
    int panelY = m_DashY + 60;
    int panelHeight = 150;
    
    // Tạo background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, m_DashX + 5);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, panelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, m_Width - 10);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);

    // Tạo tiêu đề
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, panelY + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, "THÔNG TIN THỊ TRƯỜNG");
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin xu hướng
    string trendText = "Xu hướng: " + GetTrendString(m_LastProfile.trend);
    color trendColor = GetTrendColor(m_LastProfile.trend);
    
    ObjectCreate(0, prefix + "TREND", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "TREND", OBJPROP_TEXT, trendText);
    ObjectSetString(0, prefix + "TREND", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_COLOR, trendColor);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TREND", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin Regime
    string regimeText = "Regime: " + GetRegimeString(m_LastProfile.regime);
    color regimeColor = GetRegimeColor(m_LastProfile.regime);
    
    ObjectCreate(0, prefix + "REGIME", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "REGIME", OBJPROP_TEXT, regimeText);
    ObjectSetString(0, prefix + "REGIME", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_COLOR, regimeColor);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "REGIME", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin phiên
    string sessionText = "Phiên: " + GetSessionString(m_LastProfile.currentSession);
    
    ObjectCreate(0, prefix + "SESSION", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "SESSION", OBJPROP_TEXT, sessionText);
    ObjectSetString(0, prefix + "SESSION", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "SESSION", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin biến động
    string atrText = "ATR: " + DoubleToString(m_LastProfile.atrCurrent, 5) + 
                    " (" + DoubleToString(m_LastProfile.atrRatio * 100, 1) + "%)";
    color atrColor = m_TextColor;
    
    if(m_LastProfile.atrRatio > 1.5) atrColor = m_AlertColor;
    else if(m_LastProfile.atrRatio < 0.7) atrColor = clrDarkBlue;
    
    ObjectCreate(0, prefix + "ATR", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "ATR", OBJPROP_TEXT, atrText);
    ObjectSetString(0, prefix + "ATR", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_COLOR, atrColor);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "ATR", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin ADX
    double adxValue = m_LastProfile.adxValue;
    string adxText = "ADX: " + DoubleToString(adxValue, 1);
    color adxColor = m_TextColor;
    
    if(adxValue > 25) adxColor = m_SuccessColor;
    else if(adxValue < 18) adxColor = clrDarkGray;
    
    ObjectCreate(0, prefix + "ADX", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_YDISTANCE, panelY + 80);
    ObjectSetString(0, prefix + "ADX", OBJPROP_TEXT, adxText);
    ObjectSetString(0, prefix + "ADX", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_COLOR, adxColor);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "ADX", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin Spread
    int currentSpread = (int)SymbolInfoInteger(m_Symbol, SYMBOL_SPREAD);
    int normalSpread = 20; // Mặc định
    
    // Sử dụng giá trị mặc định hoặc cầu hình từ symbol
    normalSpread = 10; // Giá trị mặc định
    
    // Nếu có AssetProfiler, có thể thêm các phương thức trực tiếp ở đây
    
    string spreadText = "Spread: " + IntegerToString(currentSpread) + " điểm";
    color spreadColor = m_TextColor;
    
    if(currentSpread > normalSpread * 1.5) spreadColor = m_AlertColor;
    else if(currentSpread < normalSpread * 0.8) spreadColor = m_SuccessColor;
    
    ObjectCreate(0, prefix + "SPREAD", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_YDISTANCE, panelY + 80);
    ObjectSetString(0, prefix + "SPREAD", OBJPROP_TEXT, spreadText);
    ObjectSetString(0, prefix + "SPREAD", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_COLOR, spreadColor);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "SPREAD", OBJPROP_ZORDER, 2);
    
    // Hiển thị thanh trạng thái pullback
    if(m_LastProfile.trend == TREND_UP_PULLBACK || m_LastProfile.trend == TREND_DOWN_PULLBACK) {
        // Tạo text "PULLBACK" nổi bật
        ObjectCreate(0, prefix + "PULLBACK_TEXT", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_XDISTANCE, m_DashX + 15);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_YDISTANCE, panelY + 105);
        ObjectSetString(0, prefix + "PULLBACK_TEXT", OBJPROP_TEXT, "PULLBACK ĐANG XẢY RA!");
        ObjectSetString(0, prefix + "PULLBACK_TEXT", OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_FONTSIZE, 10);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_COLOR, m_SuccessColor);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "PULLBACK_TEXT", OBJPROP_ZORDER, 2);
        
        // Tạo indicator pullback quality
        string qualityText = "Chất lượng: ";
        // Dùng giá trị mặc định vì phương thức GetPullbackQuality không tồn tại
        double pullbackQuality = 0.75; // Giá trị mặc định cho chất lượng pullback
        
        // Vẽ thanh đánh giá chất lượng
        int barWidth = 120;
        int qualityWidth = (int)(barWidth * pullbackQuality);
        
        // Background chất lượng
        ObjectCreate(0, prefix + "QUALITY_BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_XDISTANCE, m_DashX + 120);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_YDISTANCE, panelY + 102);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_XSIZE, barWidth);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_YSIZE, 14);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_BGCOLOR, C'230,230,230');
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_COLOR, m_ChartBorderColor);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_BACK, false);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_SELECTED, false);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "QUALITY_BG", OBJPROP_ZORDER, 2);
        
        // Thanh chất lượng
        color qualityColor = clrOrange;
        if(pullbackQuality >= 0.8) qualityColor = m_SuccessColor;
        else if(pullbackQuality >= 0.5) qualityColor = clrGold;
        
        ObjectCreate(0, prefix + "QUALITY_BAR", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_XDISTANCE, m_DashX + 120);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_YDISTANCE, panelY + 102);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_XSIZE, qualityWidth);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_YSIZE, 14);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_BGCOLOR, qualityColor);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_COLOR, qualityColor);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_BACK, false);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_SELECTED, false);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "QUALITY_BAR", OBJPROP_ZORDER, 3);
        
        // Text chất lượng
        ObjectCreate(0, prefix + "QUALITY_TEXT", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_XDISTANCE, m_DashX + 250);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_YDISTANCE, panelY + 105);
        ObjectSetString(0, prefix + "QUALITY_TEXT", OBJPROP_TEXT, DoubleToString(pullbackQuality * 10, 1) + "/10");
        ObjectSetString(0, prefix + "QUALITY_TEXT", OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_COLOR, qualityColor);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "QUALITY_TEXT", OBJPROP_ZORDER, 2);
    }
    else {
        // Hiển thị thông tin thêm (EMA Alignment) khi không trong pullback
        string emaAlignmentText = "Alignment EMA: ";
        
        bool emaAligned = false;
        // Sử dụng trực tiếp ENUM_MARKET_TREND để tránh chuyển đổi ngầm định
        if(m_LastProfile.trend == TREND_UP_STRONG || m_LastProfile.trend == TREND_UP_NORMAL) {
            emaAligned = (m_LastProfile.ema34 > m_LastProfile.ema89 && 
                       m_LastProfile.ema89 > m_LastProfile.ema200);
            emaAlignmentText += emaAligned ? "Tăng dần ✓" : "Chưa thẳng hàng ✗";
        }
        else if(m_LastProfile.trend == TREND_DOWN_STRONG || m_LastProfile.trend == TREND_DOWN_NORMAL) {
            emaAligned = (m_LastProfile.ema34 < m_LastProfile.ema89 && 
                       m_LastProfile.ema89 < m_LastProfile.ema200);
            emaAlignmentText += emaAligned ? "Giảm dần ✓" : "Chưa thẳng hàng ✗";
        }
        else {
            emaAlignmentText += "Không xác định";
        }
        
        ObjectCreate(0, prefix + "EMA_ALIGNMENT", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_XDISTANCE, m_DashX + 15);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_YDISTANCE, panelY + 105);
        ObjectSetString(0, prefix + "EMA_ALIGNMENT", OBJPROP_TEXT, emaAlignmentText);
        ObjectSetString(0, prefix + "EMA_ALIGNMENT", OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_FONTSIZE, 9);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_COLOR, emaAligned ? m_SuccessColor : m_TextColor);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "EMA_ALIGNMENT", OBJPROP_ZORDER, 2);
    }
    
    // Hiển thị thông tin giá hiện tại (vị trí so với EMA)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    string pricePositionText = "Vị trí giá: ";
    
    if(currentPrice > m_LastProfile.ema34) {
        pricePositionText += "Trên EMA34";
    }
    else if(currentPrice > m_LastProfile.ema89) {
        pricePositionText += "Giữa EMA34-89";
    }
    else if(currentPrice > m_LastProfile.ema200) {
        pricePositionText += "Giữa EMA89-200";
    }
    else {
        pricePositionText += "Dưới EMA200";
    }
    
    ObjectCreate(0, prefix + "PRICE_POSITION", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_YDISTANCE, panelY + 125);
    ObjectSetString(0, prefix + "PRICE_POSITION", OBJPROP_TEXT, pricePositionText);
    ObjectSetString(0, prefix + "PRICE_POSITION", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "PRICE_POSITION", OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Tạo panel thông tin quản lý rủi ro                               |
//+------------------------------------------------------------------+
void CDashboard::CreateRiskPanel()
{
    string prefix = m_ObjPrefix + "CONTENT_RISK_";
    int panelY = m_DashY + 220;
    int panelHeight = 110;
    
    // Tạo background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, m_DashX + 5);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, panelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, m_Width - 10);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);
    
    // Tạo tiêu đề
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, panelY + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, "QUẢN LÝ RỦI RO");
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, !m_ShowDashboard);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);

    // Thêm chỉ báo sức khỏe danh mục
    if(m_RiskManager != NULL && m_EAContext != NULL)
    {
        color healthColor = m_SuccessColor; // Mặc định là tốt
        string healthStatusText = "HEALTH: GOOD";

        // Lấy các giá trị từ RiskManager và EAContext
        double overallDDForHealth = drawdown; // Sử dụng giá trị drawdown hiện có
        double dailyLossPercentForHealth = (dailyProfit < 0) ? MathAbs(dailyProfit) : 0.0; // Chuyển đổi lỗ thành số dương
        int consecLossesForHealth = consecutiveLosses; // Sử dụng giá trị consecutiveLosses hiện có

        // Lấy các ngưỡng từ EAContext
        double maxOverallDDLimit = m_EAContext.EAInputs.RiskManagement.MaxDrawdownOverall;
        double maxDailyDDLimit = m_EAContext.EAInputs.RiskManagement.MaxDrawdownDaily;
        int maxConsecLossesLimit = m_EAContext.EAInputs.RiskManagement.MaxConsecutiveLosses;

        bool isBad = false;
        bool isWarning = false;

        // Kiểm tra điều kiện Xấu
        if (maxOverallDDLimit > 0 && overallDDForHealth >= maxOverallDDLimit) isBad = true;
        if (maxDailyDDLimit > 0 && dailyLossPercentForHealth >= maxDailyDDLimit) isBad = true;
        if (maxConsecLossesLimit > 0 && consecLossesForHealth >= maxConsecLossesLimit) isBad = true;

        // Kiểm tra điều kiện Cảnh báo (nếu không phải Xấu)
        if (!isBad) {
            if (maxOverallDDLimit > 0 && overallDDForHealth >= maxOverallDDLimit * 0.7) isWarning = true;
            if (maxDailyDDLimit > 0 && dailyLossPercentForHealth >= maxDailyDDLimit * 0.7) isWarning = true;
            if (maxConsecLossesLimit > 0 && consecLossesForHealth >= maxConsecLossesLimit * 0.7) isWarning = true;
        }

        if (isBad) {
            healthColor = m_AlertColor;
            healthStatusText = "HEALTH: BAD";
        } else if (isWarning) {
            healthColor = clrOrange;
            healthStatusText = "HEALTH: WARN";
        }

        int indicatorX = m_DashX + m_Width - 100; // Vị trí góc trên phải của panel
        int indicatorY = panelY + 12;
        int iconSize = 10;

        // Tạo icon hình tròn cho trạng thái
        ObjectCreate(0, prefix + "HEALTH_ICON", OBJ_RECTANGLE_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_XDISTANCE, indicatorX);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_YDISTANCE, indicatorY + 2);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_XSIZE, iconSize);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_YSIZE, iconSize);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_BGCOLOR, healthColor);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_COLOR, healthColor);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_CORNER, CORNER_LEFT_UPPER);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_BACK, false);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_HIDDEN, !m_ShowDashboard);
        ObjectSetInteger(0, prefix + "HEALTH_ICON", OBJPROP_ZORDER, 3);

        // Tạo text hiển thị trạng thái
        ObjectCreate(0, prefix + "HEALTH_TEXT", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_XDISTANCE, indicatorX + iconSize + 5);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_YDISTANCE, indicatorY + 1);
        ObjectSetString(0, prefix + "HEALTH_TEXT", OBJPROP_TEXT, healthStatusText);
        ObjectSetString(0, prefix + "HEALTH_TEXT", OBJPROP_FONT, "Arial Bold");
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_COLOR, healthColor);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_HIDDEN, !m_ShowDashboard);
        ObjectSetInteger(0, prefix + "HEALTH_TEXT", OBJPROP_ZORDER, 3);
    }

    double riskPercent = 1.0; // Mặc định
    if(m_RiskManager != NULL) {
        // Sử dụng giá trị mặc định nếu phương thức không tồn tại
        riskPercent = 1.0;
    }
    
    string riskText = "Risk: " + DoubleToString(riskPercent, 2) + "%";
    color riskColor = m_TextColor;
    
    if(riskPercent < 0.5) riskColor = clrDarkBlue;
    else if(riskPercent > 1.5) riskColor = m_AlertColor;
    
    ObjectCreate(0, prefix + "RISK", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "RISK", OBJPROP_TEXT, riskText);
    ObjectSetString(0, prefix + "RISK", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_COLOR, riskColor);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "RISK", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin Drawdown
    double drawdown = 0.0;
    if(m_RiskManager != NULL) {
        // Sử dụng giá trị mặc định vì phương thức không tồn tại
        drawdown = 0.0;
    }
    
    string ddText = "Drawdown: " + DoubleToString(drawdown, 2) + "%";
    color ddColor = m_TextColor;
    
    if(drawdown > 10.0) ddColor = m_AlertColor;
    else if(drawdown > 5.0) ddColor = clrDarkOrange;
    
    ObjectCreate(0, prefix + "DRAWDOWN", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "DRAWDOWN", OBJPROP_TEXT, ddText);
    ObjectSetString(0, prefix + "DRAWDOWN", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_COLOR, ddColor);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "DRAWDOWN", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin lệnh trong ngày
    int dayTrades = 0;
    int maxTrades = 5; // Giá trị mặc định
    if(m_RiskManager != NULL) {
        // Sử dụng giá trị mặc định vì các phương thức không tồn tại
        dayTrades = 0;
    }
    
    string tradeCountText = "Lệnh hôm nay: " + IntegerToString(dayTrades);
    if(maxTrades > 0) {
        tradeCountText += "/" + IntegerToString(maxTrades);
    }
    
    color tradeCountColor = m_TextColor;
    if(maxTrades > 0 && dayTrades >= maxTrades) {
        tradeCountColor = m_AlertColor;
    }
    else if(maxTrades > 0 && dayTrades >= maxTrades * 0.8) {
        tradeCountColor = clrDarkOrange;
    }
    
    ObjectCreate(0, prefix + "TRADE_COUNT", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "TRADE_COUNT", OBJPROP_TEXT, tradeCountText);
    ObjectSetString(0, prefix + "TRADE_COUNT", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_COLOR, tradeCountColor);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TRADE_COUNT", OBJPROP_ZORDER, 2);
    
    // Hiển thị thông tin thua liên tiếp
    int consecutiveLosses = 0;
    int maxConsecutiveLosses = 3; // Giá trị mặc định
    if(m_RiskManager != NULL) {
        // Sử dụng giá trị mặc định vì các phương thức không tồn tại
        consecutiveLosses = 0;
    }
    
    string lossesText = "Thua liên tiếp: " + IntegerToString(consecutiveLosses);
    if(maxConsecutiveLosses > 0) {
        lossesText += "/" + IntegerToString(maxConsecutiveLosses);
    }
    
    color lossesColor = m_TextColor;
    if(maxConsecutiveLosses > 0 && consecutiveLosses >= maxConsecutiveLosses) {
        lossesColor = m_AlertColor;
    }
    else if(maxConsecutiveLosses > 0 && consecutiveLosses >= maxConsecutiveLosses * 0.7) {
        lossesColor = clrDarkOrange;
    }
    
    ObjectCreate(0, prefix + "LOSSES", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "LOSSES", OBJPROP_TEXT, lossesText);
    ObjectSetString(0, prefix + "LOSSES", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_COLOR, lossesColor);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "LOSSES", OBJPROP_ZORDER, 2);
    
    // Thông tin lợi nhuận trong ngày
    double dailyProfit = 0.0;
    double maxDailyLoss = 5.0; // Giá trị mặc định 5%
    if(m_RiskManager != NULL) {
        // Sử dụng giá trị mặc định vì các phương thức không tồn tại
        dailyProfit = 0.0;
    }
    
    string profitText = "Lợi nhuận ngày: ";
    if(dailyProfit >= 0) {
        profitText += "+" + DoubleToString(dailyProfit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
    }
    else {
        profitText += DoubleToString(dailyProfit, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY);
    }
    
    color profitColor = dailyProfit >= 0 ? m_SuccessColor : m_AlertColor;
    
    // Cảnh báo nếu gần tới giới hạn lỗ ngày
    if(maxDailyLoss > 0 && dailyProfit < 0) {
        double lossRatio = MathAbs(dailyProfit) / maxDailyLoss;
        if(lossRatio > 0.8) profitColor = m_AlertColor;
        else if(lossRatio > 0.6) profitColor = clrDarkOrange;
    }
    
    ObjectCreate(0, prefix + "PROFIT", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_YDISTANCE, panelY + 80);
    ObjectSetString(0, prefix + "PROFIT", OBJPROP_TEXT, profitText);
    ObjectSetString(0, prefix + "PROFIT", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_COLOR, profitColor);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "PROFIT", OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Tạo panel thông tin tin tức                                       |
//+------------------------------------------------------------------+
void CDashboard::CreateNewsPanel()
{
    if(m_NewsFilter == NULL) return;
    
    string prefix = m_ObjPrefix + "CONTENT_NEWS_";
    int panelY = m_DashY + 340;
    int panelHeight = 100;
    
    // Tạo background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, m_DashX + 5);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, panelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, m_Width - 10);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);
    
    // Tạo tiêu đề
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, panelY + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, "TIN TỨC SẮP DIỄN RA");
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);
    
    // Lấy thông tin tin tức
    string newsInfo = m_NewsFilter.GetUpcomingNewsInfo();
    
    // Nếu không có tin tức
    if(newsInfo == "") {
        newsInfo = "Không có tin tức quan trọng trong 4 giờ tới.";
    }
    
    // Tạo multi-line text box cho tin tức
    ObjectCreate(0, prefix + "INFO", OBJ_EDIT, 0, 0, 0);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_XDISTANCE, m_DashX + 10);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_YDISTANCE, panelY + 35);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_XSIZE, m_Width - 20);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_YSIZE, 60);
    ObjectSetString(0, prefix + "INFO", OBJPROP_TEXT, newsInfo);
    ObjectSetString(0, prefix + "INFO", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_BORDER_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_READONLY, true);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "INFO", OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Tạo panel hiệu suất                                              |
//+------------------------------------------------------------------+
void CDashboard::CreatePerformancePanel()
{
    string prefix = m_ObjPrefix + "CONTENT_PERF_";
    int panelY = m_DashY + 450;
    int panelHeight = 110;
    
    // Tạo background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, m_DashX + 5);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, panelY);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, m_Width - 10);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, panelHeight);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);
    
    // Tạo tiêu đề
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, panelY + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, "HIỆU SUẤT GIAO DỊCH");
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);
    
    // Thông tin hiệu suất (số liệu giả lập)
    double winRate = 65.5;
    double profitFactor = 1.8;
    double expectancy = 0.45;
    
    // Hiển thị Win Rate
    string winRateText = "Win Rate: " + DoubleToString(winRate, 1) + "%";
    
    ObjectCreate(0, prefix + "WINRATE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "WINRATE", OBJPROP_TEXT, winRateText);
    ObjectSetString(0, prefix + "WINRATE", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_COLOR, winRate >= 50 ? m_SuccessColor : m_TextColor);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "WINRATE", OBJPROP_ZORDER, 2);
    
    // Hiển thị Profit Factor
    string pfText = "Profit Factor: " + DoubleToString(profitFactor, 2);
    
    ObjectCreate(0, prefix + "PF", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_YDISTANCE, panelY + 40);
    ObjectSetString(0, prefix + "PF", OBJPROP_TEXT, pfText);
    ObjectSetString(0, prefix + "PF", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "PF", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_COLOR, profitFactor >= 1.5 ? m_SuccessColor : m_TextColor);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "PF", OBJPROP_ZORDER, 2);
    
    // Hiển thị Expectancy
    string expText = "Expectancy: " + DoubleToString(expectancy, 2) + "R";
    
    ObjectCreate(0, prefix + "EXP", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "EXP", OBJPROP_TEXT, expText);
    ObjectSetString(0, prefix + "EXP", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_COLOR, expectancy >= 0.3 ? m_SuccessColor : m_TextColor);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "EXP", OBJPROP_ZORDER, 2);
    
    // Hiển thị hiệu suất theo session
    string sessionPerfText = "Session tốt nhất: ";
    string bestSession = "London-NY";
    sessionPerfText += bestSession;
    
    ObjectCreate(0, prefix + "SESSION_PERF", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_XDISTANCE, m_DashX + 170);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_YDISTANCE, panelY + 60);
    ObjectSetString(0, prefix + "SESSION_PERF", OBJPROP_TEXT, sessionPerfText);
    ObjectSetString(0, prefix + "SESSION_PERF", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "SESSION_PERF", OBJPROP_ZORDER, 2);
    
    // Hiển thị tổng số lệnh và thời gian hoạt động
    string totalTradesText = "Tổng số lệnh: 120 | Hoạt động: 45 ngày";
    
    ObjectCreate(0, prefix + "TOTAL", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_XDISTANCE, m_DashX + 15);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_YDISTANCE, panelY + 80);
    ObjectSetString(0, prefix + "TOTAL", OBJPROP_TEXT, totalTradesText);
    ObjectSetString(0, prefix + "TOTAL", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_FONTSIZE, 9);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TOTAL", OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Hiển thị vùng giá trị (Value Zone)                               |
//+------------------------------------------------------------------+
void CDashboard::CreateValueZoneVisualizer()
{
    string prefix = m_ObjPrefix + "CONTENT_VALUEZONE_";
    
    // Nếu không có thông tin EMA, không vẽ
    if(m_LastProfile.ema34 == 0 || m_LastProfile.ema89 == 0 || m_LastProfile.ema200 == 0) {
        return;
    }
    
    // Xóa các đối tượng cũ
    DeleteObjectsByPrefix(prefix);
    
    // Vẽ vùng giá trị (Value Zone)
    
    // Vẽ EMA 34
    ObjectCreate(0, prefix + "EMA34", OBJ_HLINE, 0, 0, m_LastProfile.ema34);
    ObjectSetInteger(0, prefix + "EMA34", OBJPROP_COLOR, C'0,128,255');
    ObjectSetInteger(0, prefix + "EMA34", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "EMA34", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, prefix + "EMA34", OBJPROP_BACK, true);
    ObjectSetInteger(0, prefix + "EMA34", OBJPROP_SELECTABLE, false);
    ObjectSetString(0, prefix + "EMA34", OBJPROP_TOOLTIP, "EMA 34: " + DoubleToString(m_LastProfile.ema34, _Digits));
    
    // Vẽ EMA 89
    ObjectCreate(0, prefix + "EMA89", OBJ_HLINE, 0, 0, m_LastProfile.ema89);
    ObjectSetInteger(0, prefix + "EMA89", OBJPROP_COLOR, C'255,128,0');
    ObjectSetInteger(0, prefix + "EMA89", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "EMA89", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, prefix + "EMA89", OBJPROP_BACK, true);
    ObjectSetInteger(0, prefix + "EMA89", OBJPROP_SELECTABLE, false);
    ObjectSetString(0, prefix + "EMA89", OBJPROP_TOOLTIP, "EMA 89: " + DoubleToString(m_LastProfile.ema89, _Digits));
    
    // Vẽ EMA 200
    ObjectCreate(0, prefix + "EMA200", OBJ_HLINE, 0, 0, m_LastProfile.ema200);
    ObjectSetInteger(0, prefix + "EMA200", OBJPROP_COLOR, C'255,0,128');
    ObjectSetInteger(0, prefix + "EMA200", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "EMA200", OBJPROP_WIDTH, 2);
    ObjectSetInteger(0, prefix + "EMA200", OBJPROP_BACK, true);
    ObjectSetInteger(0, prefix + "EMA200", OBJPROP_SELECTABLE, false);
    ObjectSetString(0, prefix + "EMA200", OBJPROP_TOOLTIP, "EMA 200: " + DoubleToString(m_LastProfile.ema200, _Digits));
    
    // Vẽ vùng giá trị nếu là xu hướng rõ ràng
    if(m_LastProfile.trend != TREND_SIDEWAY) {
        // Vẽ Value Zone (vùng giữa EMA 34 và EMA 89)
        ObjectCreate(0, prefix + "VALUE_ZONE", OBJ_RECTANGLE, 0, 0, 0, 0, 0);
        
        // Đặt tọa độ vùng giá trị
        datetime startTime = (datetime)ChartGetInteger(0, CHART_VISIBLE_BARS) - 
                          (datetime)ChartGetInteger(0, CHART_FIRST_VISIBLE_BAR);
        datetime endTime = (datetime)ChartGetInteger(0, CHART_VISIBLE_BARS);
        
        double zoneHigh = MathMax(m_LastProfile.ema34, m_LastProfile.ema89);
        double zoneLow = MathMin(m_LastProfile.ema34, m_LastProfile.ema89);
        
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_COLOR, m_ChartBorderColor);
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_BACK, true);
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_FILL, true);
        // Sử dụng cú pháp đúng cho ObjectSetDouble và ObjectSetInteger
        // Đổi từ OBJPROP_PRICE1/PRICE2 thành các thuộc tính phù hợp
        bool result1 = ObjectSetDouble(0, prefix + "VALUE_ZONE", OBJPROP_PRICE, zoneHigh);
        bool result2 = ObjectSetDouble(0, prefix + "VALUE_ZONE", OBJPROP_PRICE, zoneLow);
        // Thay đổi thuộc tính không hợp lệ
        bool result3 = ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_SELECTED, false);
        bool result4 = ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_WIDTH, 2); // Thay đổi thuộc tính
        ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_SELECTABLE, false);
        
        // Nếu trong pullback, tô màu khác
        if(m_LastProfile.trend == TREND_UP_PULLBACK || m_LastProfile.trend == TREND_DOWN_PULLBACK) {
            ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_BGCOLOR, C'230,255,230'); // Xanh lá nhạt
            ObjectSetString(0, prefix + "VALUE_ZONE", OBJPROP_TOOLTIP, "PULLBACK ZONE");
        }
        else {
            ObjectSetInteger(0, prefix + "VALUE_ZONE", OBJPROP_BGCOLOR, C'240,240,255'); // Xanh dương nhạt
            ObjectSetString(0, prefix + "VALUE_ZONE", OBJPROP_TOOLTIP, "VALUE ZONE");
        }
    }
}

//+------------------------------------------------------------------+
//| Vẽ biểu đồ mini                                                  |
//+------------------------------------------------------------------+
void CDashboard::DrawMiniChart(string name, int x, int y, int width, int height, 
                             double &data[], double minValue, double maxValue, 
                             color lineColor, string title, string subtitle, bool showGrid)
{
    string prefix = m_ObjPrefix + "MINICHART_" + name + "_";
    
    // Tạo background
    ObjectCreate(0, prefix + "BG", OBJ_RECTANGLE_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XDISTANCE, x);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YDISTANCE, y);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_XSIZE, width);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_YSIZE, height);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BGCOLOR, clrWhite);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_COLOR, m_ChartBorderColor);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BORDER_TYPE, BORDER_FLAT);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_WIDTH, 1);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_CORNER, CORNER_LEFT_UPPER);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_STYLE, STYLE_SOLID);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_BACK, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_SELECTED, false);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "BG", OBJPROP_ZORDER, 1);
    
    // Tạo tiêu đề
    ObjectCreate(0, prefix + "TITLE", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_XDISTANCE, x + 5);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_YDISTANCE, y + 15);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_TEXT, title);
    ObjectSetString(0, prefix + "TITLE", OBJPROP_FONT, "Arial Bold");
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_COLOR, m_TitleColor);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "TITLE", OBJPROP_ZORDER, 2);
    
    // Tạo subtitle
    if(subtitle != "") {
        ObjectCreate(0, prefix + "SUBTITLE", OBJ_LABEL, 0, 0, 0);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_XDISTANCE, x + width - StringLen(subtitle) * 5 - 5);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_YDISTANCE, y + 15);
        ObjectSetString(0, prefix + "SUBTITLE", OBJPROP_TEXT, subtitle);
        ObjectSetString(0, prefix + "SUBTITLE", OBJPROP_FONT, "Arial");
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_FONTSIZE, 8);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_COLOR, m_TextColor);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_SELECTABLE, false);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_HIDDEN, true);
        ObjectSetInteger(0, prefix + "SUBTITLE", OBJPROP_ZORDER, 2);
    }
    
    // Vẽ lưới nếu cần
    if(showGrid) {
        // Vẽ đường grid ngang
        for(int i = 1; i < 4; i++) {
            double yPos = y + height - (i * height / 4);
            
            ObjectCreate(0, prefix + "GRID_H_" + IntegerToString(i), OBJ_TREND, 0, 0, 0, 0, 0);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_COLOR, clrLightGray);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_BACK, true);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_SELECTABLE, false);
            
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_RAY, false);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_RAY_RIGHT, false);
            
            // Sử dụng ObjectSetInteger với cú pháp đúng
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_XDISTANCE, (long)x);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_YDISTANCE, (long)yPos);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_WIDTH, (long)width);
            ObjectSetInteger(0, prefix + "GRID_H_" + IntegerToString(i), OBJPROP_COLOR, clrWhiteSmoke);
        }
        
        // Vẽ đường grid dọc
        for(int i = 1; i < 4; i++) {
            double xPos = x + (i * width / 4);
            
            ObjectCreate(0, prefix + "GRID_V_" + IntegerToString(i), OBJ_TREND, 0, 0, 0, 0, 0);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_COLOR, clrLightGray);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_STYLE, STYLE_DOT);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_BACK, true);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_SELECTABLE, false);
            
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_RAY, false);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_RAY_RIGHT, false);
            
            // Sử dụng ObjectSetInteger với cú pháp đúng
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_XDISTANCE, (long)xPos);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_YDISTANCE, (long)(y + 25));
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_WIDTH, 1);
            ObjectSetInteger(0, prefix + "GRID_V_" + IntegerToString(i), OBJPROP_COLOR, clrWhiteSmoke);
        }
    }
    
    // Vẽ đường giá trị
    int dataCount = ArraySize(data);
    if(dataCount < 2) return;
    
    // Xác định tỷ lệ
    double range = maxValue - minValue;
    if(range <= 0) range = 1;
    
    // Vẽ từng đoạn đường
    for(int i = 0; i < dataCount - 1; i++) {
        double value1 = MathMin(MathMax(data[i], minValue), maxValue);
        double value2 = MathMin(MathMax(data[i+1], minValue), maxValue);
        
        double yPos1 = y + height - ((value1 - minValue) / range * (height - 35) + 5);
        double yPos2 = y + height - ((value2 - minValue) / range * (height - 35) + 5);
        
        double xPos1 = x + (i * width / (dataCount - 1));
        double xPos2 = x + ((i + 1) * width / (dataCount - 1));
        
        ObjectCreate(0, prefix + "LINE_" + IntegerToString(i), OBJ_TREND, 0, 0, 0, 0, 0);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_COLOR, lineColor);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_STYLE, STYLE_SOLID);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_WIDTH, 2);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_BACK, false);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_SELECTABLE, false);
        
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_RAY, false);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_RAY_RIGHT, false);
        
        // Sử dụng hàm vẽ đường line với cú pháp đúng
        ObjectCreate(0, prefix + "LINE_" + IntegerToString(i), OBJ_TREND, 0, 0, 0);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_XDISTANCE, (long)xPos1);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_YDISTANCE, (long)yPos1);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_WIDTH, 1);
        ObjectSetInteger(0, prefix + "LINE_" + IntegerToString(i), OBJPROP_COLOR, clrWhite);
    }
    
    // Hiển thị giá trị min và max
    ObjectCreate(0, prefix + "MIN", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_XDISTANCE, (long)(x + 5));
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_YDISTANCE, (long)(y + height - 20));
    ObjectSetString(0, prefix + "MIN", OBJPROP_TEXT, DoubleToString(minValue, 2));
    ObjectSetString(0, prefix + "MIN", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "MIN", OBJPROP_ZORDER, 2);
    
    ObjectCreate(0, prefix + "MAX", OBJ_LABEL, 0, 0, 0);
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_XDISTANCE, (long)(x + 5));
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_YDISTANCE, (long)(y + 25));
    ObjectSetString(0, prefix + "MAX", OBJPROP_TEXT, DoubleToString(maxValue, 2));
    ObjectSetString(0, prefix + "MAX", OBJPROP_FONT, "Arial");
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_FONTSIZE, 8);
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_COLOR, m_TextColor);
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_SELECTABLE, false);
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_HIDDEN, true);
    ObjectSetInteger(0, prefix + "MAX", OBJPROP_ZORDER, 2);
}

//+------------------------------------------------------------------+
//| Xóa tất cả đối tượng theo prefix                                  |
//+------------------------------------------------------------------+
void CDashboard::DeleteObjectsByPrefix(string prefix)
{
    int totalObj = ObjectsTotal(0);
    for(int i = totalObj - 1; i >= 0; i--) {
        string objName = ObjectName(0, i);
        if(StringFind(objName, prefix) == 0) {
            ObjectDelete(0, objName);
        }
    }
}

//+------------------------------------------------------------------+
//| Lấy màu cho xu hướng                                              |
//+------------------------------------------------------------------+
color CDashboard::GetTrendColor(ENUM_MARKET_TREND trend)
{
    switch(trend) {
        case TREND_UP_STRONG:    return clrDarkGreen;
        case TREND_UP_NORMAL:    return clrForestGreen;
        case TREND_UP_PULLBACK:  return (color)0x32B432;  // màu xanh lá
        case TREND_SIDEWAY:      return clrDarkGray;
        case TREND_DOWN_PULLBACK:return (color)0x3232B4;  // màu đỏ
        case TREND_DOWN_NORMAL:  return clrFireBrick;
        case TREND_DOWN_STRONG:  return clrDarkRed;
        default:                 return clrBlack;
    }
}

//+------------------------------------------------------------------+
//| Lấy màu cho regime                                                |
//+------------------------------------------------------------------+
color CDashboard::GetRegimeColor(ENUM_MARKET_REGIME regime)
{
    switch(regime) {
        case REGIME_TRENDING:     return clrRoyalBlue;
        case REGIME_RANGING:      return clrDarkOrange;
        case REGIME_VOLATILE:     return clrPurple;
        default:                  return clrBlack;
    }
}

//+------------------------------------------------------------------+
//| Lấy chuỗi mô tả xu hướng                                          |
//+------------------------------------------------------------------+
string CDashboard::GetTrendString(ENUM_MARKET_TREND trend)
{
    switch(trend) {
        case TREND_UP_STRONG:    return "TĂNG MẠNH";
        case TREND_UP_NORMAL:    return "TĂNG";
        case TREND_UP_PULLBACK:  return "PULLBACK TĂNG";
        case TREND_SIDEWAY:      return "SIDEWAY";
        case TREND_DOWN_PULLBACK:return "PULLBACK GIẢM";
        case TREND_DOWN_NORMAL:  return "GIẢM";
        case TREND_DOWN_STRONG:  return "GIẢM MẠNH";
        default:                 return "KHÔNG XÁC ĐỊNH";
    }
}

//+------------------------------------------------------------------+
//| Lấy chuỗi mô tả regime                                            |
//+------------------------------------------------------------------+
string CDashboard::GetRegimeString(ENUM_MARKET_REGIME regime)
{
    switch(regime) {
        case REGIME_TRENDING:     return "TRENDING";
        case REGIME_RANGING:      return "RANGING";
        case REGIME_VOLATILE:     return "VOLATILE";
        default:                  return "KHÔNG XÁC ĐỊNH";
    }
}

//+------------------------------------------------------------------+
//| Lấy chuỗi mô tả phiên                                             |
//+------------------------------------------------------------------+
string CDashboard::GetSessionString(ENUM_SESSION session)
{
    switch(session) {
        case SESSION_ASIAN:        return "ASIAN";
        case SESSION_EUROPEAN:     return "EUROPEAN";
        case SESSION_AMERICAN:     return "AMERICAN";
        case SESSION_EUROPEAN_AMERICAN: return "EUROPEAN-AMERICAN";
        case SESSION_LONDON_NY:    return "LONDON-NY";
        case SESSION_CLOSING:      return "CLOSING";
        default:                   return "KHÔNG XÁC ĐỊNH";
    }
}

} // đóng namespace ApexPullback

#endif // _DASHBOARD_MQH_