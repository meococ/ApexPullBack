//+------------------------------------------------------------------+
//|                                     PositionManager.mqh (v14.3)   |
//|                                Copyright 2023-2024, ApexPullback EA |
//|                                    https://www.apexpullback.com  |
//|                Refactored: 2025-06-11 - Cleaned and Fixed         |
//+------------------------------------------------------------------+

#ifndef POSITION_MANAGER_MQH_
#define POSITION_MANAGER_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback 
{

//+------------------------------------------------------------------+
//| STRUCT MỞ RỘNG CHO QUẢN LÝ VỊ THẾ                                |
//+------------------------------------------------------------------+
#include <Trade/PositionInfo.mqh> // Cần include thư viện chuẩn

struct PositionInfoExt : public CPositionInfo {
    string               strategyID;
    ENUM_TRADE_SCENARIO  tradeScenario;
    bool                 isFoundInTerminal; // Dùng để đánh dấu các vị thế đã được kiểm tra

    // Constructor
    PositionInfoExt() {
        strategyID = "";
        tradeScenario = TRADE_SCENARIO_UNKNOWN;
        isFoundInTerminal = false;
    }

    // Reset method
    void Reset() {
        strategyID = "";
        tradeScenario = TRADE_SCENARIO_UNKNOWN;
        isFoundInTerminal = false;
        // Note: We don't reset the base class members here, 
        // as they will be overwritten by CPositionInfo::SelectByTicket
    }
};

// --- CẤU TRÚC THÔNG TIN PORTFOLIO ---
struct PortfolioStatus 
{
    int     totalPositions;       
    int     buyPositions;         
    int     sellPositions;        
    double  totalRiskAmount;      
    double  totalRiskPercent;     
    double  totalUnrealizedPnL;   
    double  currentDrawdown;      
    ENUM_PORTFOLIO_HEALTH health; 

    void Clear() 
    {
        totalPositions = 0;
        buyPositions = 0;
        sellPositions = 0;
        totalRiskAmount = 0;
        totalRiskPercent = 0;
        totalUnrealizedPnL = 0;
        currentDrawdown = 0;
        health = PORTFOLIO_HEALTH_UNKNOWN;
    }
};

//+------------------------------------------------------------------+
//| CPositionManager - Quản lý vị thế ở mức cao                      |
//+------------------------------------------------------------------+
class CPositionManager 
{
private:
    EAContext*      m_context;         
    string          m_symbol;          
    int             m_magicNumber;     
    CArrayObj*      m_positionsInfo;   
    PortfolioStatus m_portfolioStatus; 

    // Parameters
    double          m_maxRiskPerTrade; 
    double          m_maxTotalRisk;    
    int             m_maxPositions;    

    // --- Private Methods ---
    void EvaluatePortfolio();
    PositionInfoExt* FindPositionByTicket(ulong ticket);
    void RemoveClosedPositions();
    bool UpdateSinglePositionInfo(PositionInfoExt* posInfo);
    PositionInfoExt* CreatePositionInfo(ulong ticket, const string strategyID, ENUM_TRADE_SCENARIO scenario);

public:
    CPositionManager(EAContext* context);
    ~CPositionManager();

    bool Initialize();
    void UpdateAllPositions();
    bool AddPosition(ulong ticket, const string strategyID, ENUM_TRADE_SCENARIO scenario);
    bool CanOpenNewPosition(double newRisk);

    // --- Getters ---
    int GetTotalPositions() const { return m_portfolioStatus.totalPositions; }
    double GetTotalRiskPercent() const { return m_portfolioStatus.totalRiskPercent; }
    const PortfolioStatus* GetPortfolioStatus() const { return &m_portfolioStatus; }
    PositionInfoExt* GetPositionByTicket(ulong ticket) { return FindPositionByTicket(ticket); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager(EAContext* context) : m_context(context), m_magicNumber(0), m_maxRiskPerTrade(0), m_maxTotalRisk(0), m_maxPositions(0)
{
    m_positionsInfo = new CArrayObj();
    if(m_positionsInfo) m_positionsInfo->SetFreeObjects(true);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPositionManager::~CPositionManager()
{
    if(m_positionsInfo != NULL)
    {
        delete m_positionsInfo;
        m_positionsInfo = NULL;
    }
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CPositionManager::Initialize()
{
    m_symbol = m_context.pSymbolInfo->Symbol();
    m_magicNumber = m_context.Inputs.MagicNumber;
    
    // Load parameters from the centralized parameter store
    m_maxRiskPerTrade = m_context.Inputs.RiskManagement.MaxRiskPerTrade;
    m_maxTotalRisk = m_context.Inputs.RiskManagement.MaxTotalRisk;
    m_maxPositions = m_context.Inputs.RiskManagement.MaxPositions;

    UpdateAllPositions();
    if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "PositionManager initialized for " + m_symbol);
    return true;
}

//+------------------------------------------------------------------+
//| UpdateAllPositions                                               |
//+------------------------------------------------------------------+
void CPositionManager::UpdateAllPositions()
{
    if(!m_positionsInfo || !m_context) return;

    for (int i = 0; i < m_positionsInfo->Total(); i++)
    {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo->At(i);
        if (pos) pos->isFoundInTerminal = false;
    }

    for (int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionGetString(POSITION_SYMBOL) == m_symbol && (int)PositionGetInteger(POSITION_MAGIC) == m_magicNumber)
        {
            PositionInfoExt* pos = FindPositionByTicket(ticket);
            if (pos)
            {
                UpdateSinglePositionInfo(pos);
                pos->isFoundInTerminal = true;
            }
            // Note: We are not auto-adding positions found in terminal but not in our list.
            // They must be added explicitly via AddPosition().
        }
    }

    RemoveClosedPositions();
    EvaluatePortfolio();
}

//+------------------------------------------------------------------+
//| AddPosition                                                      |
//+------------------------------------------------------------------+
bool CPositionManager::AddPosition(ulong ticket, const string strategyID, ENUM_TRADE_SCENARIO scenario)
{
    if (!m_positionsInfo || !m_context) return false;
    if (FindPositionByTicket(ticket) != NULL) 
    {
        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_WARNING, StringFormat("Attempted to re-add existing position #%d", ticket));
        return false;
    }

    PositionInfoExt* newPos = CreatePositionInfo(ticket, strategyID, scenario);
    if (!newPos) 
    {
        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_ERROR, StringFormat("Failed to create info for position #%d", ticket));
        return false;
    }

    if (!m_positionsInfo->Add(newPos)) 
    {
        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_ERROR, StringFormat("Failed to add position #%d to tracking array", ticket));
        delete newPos;
        return false;
    }
    
    if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, StringFormat("Added new position #%d to manager.", ticket));
    EvaluatePortfolio();
    return true;
}

//+------------------------------------------------------------------+
//| CanOpenNewPosition                                               |
//+------------------------------------------------------------------+
bool CPositionManager::CanOpenNewPosition(double newRisk)
{
    if (m_portfolioStatus.totalPositions >= m_maxPositions) 
    {
        // Optional: Log reason
        return false;
    }
    if ((m_portfolioStatus.totalRiskPercent + newRisk) > m_maxTotalRisk)
    {
        // Optional: Log reason
        return false;
    }
    return true;
}


//+------------------------------------------------------------------+
//| FindPositionByTicket (Internal)                                  |
//+------------------------------------------------------------------+
PositionInfoExt* CPositionManager::FindPositionByTicket(ulong ticket)
{
    if(!m_positionsInfo) return NULL;
    for(int i = 0; i < m_positionsInfo->Total(); i++)
    {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo->At(i);
        if(pos && pos->Ticket() == ticket)
        {
            return pos;
        }
    }
    return NULL;
}

//+------------------------------------------------------------------+
//| RemoveClosedPositions (Internal)                                 |
//+------------------------------------------------------------------+
void CPositionManager::RemoveClosedPositions()
{
    if(!m_positionsInfo) return;
    for(int i = m_positionsInfo->Total() - 1; i >= 0; i--)
    {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo->At(i);
        if(pos && !pos->isFoundInTerminal)
        {
            m_context->Logger->LogInfo(StringFormat("Position #%d closed. Removing from manager.", pos->Ticket()));
            m_positionsInfo->Delete(i);
        }
    }
}

//+------------------------------------------------------------------+
//| UpdateSinglePositionInfo (Internal)                              |
//+------------------------------------------------------------------+
bool CPositionManager::UpdateSinglePositionInfo(PositionInfoExt* posInfo)
{
    if (!posInfo) return false;
    // This just re-selects the position to update its dynamic properties
    // like profit, swap, etc.
    return posInfo->Select();
}

//+------------------------------------------------------------------+
//| CreatePositionInfo (Internal)                                    |
//+------------------------------------------------------------------+
PositionInfoExt* CPositionManager::CreatePositionInfo(ulong ticket, const string strategyID, ENUM_TRADE_SCENARIO scenario)
{
    PositionInfoExt* newPos = new PositionInfoExt();
    if (!newPos->SelectByTicket(ticket)) 
    {
        delete newPos;
        return NULL;
    }
    newPos->strategyID = strategyID;
    newPos->tradeScenario = scenario;
    newPos->isFoundInTerminal = true;
    // Calculate initial risk, etc.
    // newPos->initialRiskInMoney = ...
    // newPos->initialRiskInPercent = ...
    return newPos;
}

//+------------------------------------------------------------------+
//| EvaluatePortfolio (Internal)                                     |
//+------------------------------------------------------------------+
void CPositionManager::EvaluatePortfolio()
{
    m_portfolioStatus.Clear();
    if(!m_positionsInfo || !m_context) return;

    m_portfolioStatus.totalPositions = m_positionsInfo->Total();
    double totalAccountBalance = m_context->SafeDataProvider->GetAccountBalance();

    for (int i = 0; i < m_positionsInfo->Total(); i++)
    {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo->At(i);
        if (!pos) continue;

        if (pos->PositionType() == POSITION_TYPE_BUY) m_portfolioStatus.buyPositions++;
        else m_portfolioStatus.sellPositions++;

        // Note: Risk calculation needs to be implemented properly
        // This is a placeholder
        double positionRiskPercent = 1.0; // Placeholder
        m_portfolioStatus.totalRiskPercent += positionRiskPercent;
        m_portfolioStatus.totalUnrealizedPnL += pos->Profit();
    }

    // Further health evaluation can be added here
    if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.75)
    {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_WARNING;
    }
    else
    {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_NORMAL;
    }
}

string CPositionManager::CreateDetailedReport()
{
    string report = "=== BÁO CÁO PORTFOLIO (" + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + ") ===\n\n";
    
    // Thông tin tổng quan
    report += "TỔNG QUAN:\n";
    report += StringFormat("Tổng vị thế: %d (Long: %d, Short: %d)\n", 
                         m_portfolioStatus.totalPositions,
                         m_portfolioStatus.buyPositions,
                         m_portfolioStatus.sellPositions);
    report += StringFormat("Tổng rủi ro: %.2f%%\n", m_portfolioStatus.totalRiskPercent);
    report += StringFormat("R trung bình: %.2f\n", m_portfolioStatus.averageR);
    report += StringFormat("Lợi nhuận chưa thực hiện: %.2f đ (%.2f%%)\n", 
                         m_portfolioStatus.totalUnrealizedPnL,
                         m_portfolioStatus.totalUnrealizedPnLPercent);
    report += StringFormat("Trạng thái danh mục: %s\n\n", EnumToString(m_portfolioStatus.health));
    
    // Thông tin thống kê
    report += "THỐNG KÊ:\n";
    report += StringFormat("Vị thế đã đóng: %d (Thắng: %d, Thua: %d)\n", 
                         m_closedPositions, m_winPositions, m_losePositions);
    report += StringFormat("Tỷ lệ thành công: %.1f%%\n", m_portfolioStatus.successRate);
    report += StringFormat("Profit Factor: %.2f\n\n", m_portfolioStatus.profitFactor);
    
    // Thông tin từng vị thế
    report += "CHI TIẾT VỊ THẾ:\n";
    
    if (m_positionsInfo->Total() > 0) {
        for (int i = 0; i < m_positionsInfo->Total(); i++) {
            PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo->At(i);
            if(pos == NULL) continue;
            
            report += StringFormat("#%d - %s (%.2f lot)\n", 
                                 pos->Ticket(), 
                                 pos->PositionType() == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                 pos->Volume());
            report += StringFormat("  Entry: %.5f, SL: %.5f, TP: %.5f\n", 
                                 pos->PriceOpen(), pos->StopLoss(), pos->TakeProfit());
            report += StringFormat("  R hiện tại: %.2f, PnL: %.2f đ (%.2f%%)\n", 
                                 pos->currentR, pos->Profit(), pos->unrealizedPnLPercent);
            report += StringFormat("  Giữ: %d nến, Trạng thái: %s\n", 
                                 pos->holdingBars, EnumToString(pos->state));
            report += StringFormat("  Scenario: %s, BE: %s, TP1: %s, TP2: %s\n\n", 
                                 EnumToString(pos->tradeScenario),
                                 pos->isBreakevenHit ? "Đạt" : "Chưa",
                                 pos->isPartial1Done ? "Đạt" : "Chưa",
                                 pos->isPartial2Done ? "Đạt" : "Chưa");
        }
    } else {
        report += "Không có vị thế đang mở.\n\n";
    }
    
    // Khuyến nghị
    report += "KHUYẾN NGHỊ:\n";
    
    // Khuyến nghị dựa trên tình hình hiện tại
    switch (m_portfolioStatus.health) {
        case PORTFOLIO_HEALTH_GOOD:
            report += "- Danh mục tốt, duy trì risk hiện tại.\n";
            break;
            
        case PORTFOLIO_HEALTH_AVERAGE:
            report += "- Danh mục trung bình, cẩn trọng với các vị thế mới.\n";
            break;
            
        case PORTFOLIO_HEALTH_WARNING:
            report += "- Danh mục cảnh báo, giảm risk và đánh giá lại chiến lược.\n";
            break;
            
        case PORTFOLIO_HEALTH_DANGER:
            report += "- Danh mục nguy hiểm, nên đóng các vị thế lỗ và tạm dừng giao dịch.\n";
            break;
            
        default:
            break;
    }
    
    // Khuyến nghị rủi ro
    report += StringFormat("- Risk khuyến nghị cho lệnh tiếp theo: %.2f%%\n", GetRecommendedRiskPercent());
    report += StringFormat("- Target R khuyến nghị: %.2f\n", GetRecommendedTargetR());
    
    // Kiểm tra nếu nên đóng tất cả
    string reason = "";
    if (ShouldCloseAllPositions(reason)) {
        report += "- NÊN ĐÓNG TẤT CẢ VỊ THẾ: " + reason + "\n";
    }
    
    return report;
}

} // namespace ApexPullback

#endif // POSITIONMANAGER_MQH_