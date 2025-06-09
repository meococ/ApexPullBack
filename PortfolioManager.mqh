//+------------------------------------------------------------------+
//|                                          PortfolioManager.mqh |
//|                      APEX PULLBACK EA v14.0 - Professional Edition|
//|               Copyright 2023-2024, APEX Trading Systems           |
//+------------------------------------------------------------------+

#ifndef PORTFOLIO_MANAGER_MQH
#define PORTFOLIO_MANAGER_MQH

#include "Logger.mqh"
#include "CommonStructs.mqh" // Sẽ cần cho TradeProposal và các cấu trúc khác
#include "NewsFilter.mqh"
#include "Enums.mqh"
#include "PositionManager.mqh" // Thêm PositionManager
#include "RiskManager.mqh"     // Thêm RiskManager
// Thêm các include cần thiết khác sau này

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Class CPortfolioManager                                          |
//| Quản lý danh mục đầu tư tổng thể, ra quyết định giao dịch        |
//+------------------------------------------------------------------+
class CPortfolioManager
{
private:
    CLogger* m_Logger;
    CNewsFilter* m_NewsFilter; // Để kiểm tra sự kiện vĩ mô
    CPositionManager* m_PositionManager; // Để truy cập thông tin vị thế đang mở
    CRiskManager* m_RiskManager;         // Để truy cập thông tin rủi ro tổng thể
    CArrayObj m_TradeProposals;          // Dùng CArrayObj để lưu các đề xuất
    double m_CorrelationMatrix[28][28]; // Ma trận tương quan (ví dụ cho 28 cặp tiền chính)
    string m_SymbolIndexMap[28];        // Ánh xạ từ tên symbol sang chỉ số của ma trận
    // Thêm các thành viên khác sau này

    // Cấu hình
    double m_MaxTotalRisk; // % rủi ro tối đa cho toàn bộ danh mục
    double m_MaxCorrelationAllowed; // Ngưỡng tương quan tối đa cho phép
    // ... các cấu hình khác

    // Phương thức nội bộ
    void LoadProposals(); // Tải các đề xuất giao dịch (từ Global Variables hoặc file)
    void AnalyzeProposals(); // Phân tích các đề xuất
    ENUM_PORTFOLIO_DECISION DecideOnProposal(const TradeProposal &proposal); // Ra quyết định cho một đề xuất

public:
    CPortfolioManager(CLogger* logger, CNewsFilter* newsFilter, CPositionManager* posManager, CRiskManager* riskManager);
    ~CPortfolioManager();

    bool Initialize(double maxTotalRisk, double maxCorrelation);
    void Deinitialize();

    void ProcessTradeProposals(); // Hàm chính để xử lý các đề xuất giao dịch

    // Các hàm getter/setter cho cấu hình nếu cần
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPortfolioManager::CPortfolioManager(CLogger* logger, CNewsFilter* newsFilter, CPositionManager* posManager, CRiskManager* riskManager)
{
    m_Logger = logger;
    m_NewsFilter = newsFilter;
    m_PositionManager = posManager;
    m_RiskManager = riskManager;
    m_TradeProposals.FreeMode(true); // Quan trọng: Cho phép CArrayObj tự xóa các con trỏ khi dọn dẹp
    m_MaxTotalRisk = 0.05; // Mặc định 5% tổng rủi ro
    m_MaxCorrelationAllowed = 0.7; // Mặc định tương quan 70%
    InitializeCorrelationMatrix(); // Khởi tạo ma trận tương quan
    if(m_Logger != NULL) m_Logger.LogInfo("CPortfolioManager: Instance created.");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPortfolioManager::~CPortfolioManager()
{
    if(m_Logger != NULL) m_Logger.LogInfo("CPortfolioManager: Instance destroyed.");
}

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
bool CPortfolioManager::Initialize(double maxTotalRisk, double maxCorrelation)
{
    m_MaxTotalRisk = maxTotalRisk;
    m_MaxCorrelationAllowed = maxCorrelation;

    if(m_Logger == NULL)
    {
        // Không thể ghi log nếu logger là NULL, nhưng đây là một kiểm tra quan trọng
        printf("CPortfolioManager Error: Logger is NULL during initialization.");
        return false;
    }
    if(m_NewsFilter == NULL)
    {
        m_Logger.LogError("CPortfolioManager: NewsFilter is NULL during initialization.");
        return false;
    }
    if(m_PositionManager == NULL)
    {
        m_Logger.LogError("CPortfolioManager: PositionManager is NULL during initialization.");
        return false;
    }
    if(m_RiskManager == NULL)
    {
        m_Logger.LogError("CPortfolioManager: RiskManager is NULL during initialization.");
        return false;
    }

    m_Logger.LogInfo("CPortfolioManager: Initialized successfully.");
    return true;
}

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void CPortfolioManager::Deinitialize()
{
    // Dọn dẹp tài nguyên nếu có
    m_TradeProposals.Clear(); // Xóa tất cả các đối tượng trong mảng và giải phóng bộ nhớ nếu cần
    if(m_Logger != NULL) m_Logger.LogInfo("CPortfolioManager: Deinitialized.");
}

//+------------------------------------------------------------------+
//| LoadProposals                                                    |
//+------------------------------------------------------------------+
void CPortfolioManager::LoadProposals()
{
    if(m_Logger != NULL) m_Logger.LogInfo("CPortfolioManager: Attempting to load proposals via Global Variables."); // Added log
    if(m_Logger != NULL) m_Logger.LogDebug("CPortfolioManager: Loading trade proposals...");
    m_TradeProposals.Clear(); // Xóa các proposal cũ trước khi tải mới

    // Danh sách các cặp tiền cần theo dõi (có thể được cấu hình sau này)
    string monitoredSymbols[] = {"EURUSD", "GBPUSD", "USDJPY", "AUDUSD", "USDCAD"};
    // TODO: Lấy danh sách này từ một nguồn cấu hình linh hoạt hơn

    for(int i = 0; i < ArraySize(monitoredSymbols); i++)
    {
        string symbolName = monitoredSymbols[i];
        string gvName = "GV_Proposal_" + symbolName;

        if(GlobalVariableCheck(gvName))
        {
            string gvValue = GlobalVariableGet(gvName);
            if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Found GV '%s' with value '%s'", gvName, gvValue);

            // Phân tách chuỗi: "BUY;0.75;1.0" (Direction;SignalQuality;RiskPercent)
            string parts[];
            int count = StringSplit(gvValue, ';', parts);

            if(count == 3)
            {
                TradeProposal* proposal = new TradeProposal();
                proposal.Symbol = symbolName;
                
                // Parse Direction
                if(StringCompare(parts[0], "BUY", false) == 0) proposal.OrderType = ORDER_TYPE_BUY;
                else if(StringCompare(parts[0], "SELL", false) == 0) proposal.OrderType = ORDER_TYPE_SELL;
                else 
                {
                    if(m_Logger != NULL) m_Logger.LogWarningFormat("CPortfolioManager: Invalid direction '%s' in GV '%s'. Skipping.", parts[0], gvName);
                    delete proposal;
                    GlobalVariableDel(gvName); // Xóa GV để tránh xử lý lại
                    continue;
                }

                // Parse SignalQuality
                proposal.SignalQuality = StringToDouble(parts[1]);
                // Parse RiskPercent
                proposal.RiskPercent = StringToDouble(parts[2]);
                
                // TODO: Thêm các thông tin khác nếu cần (Entry, SL, TP) từ GV hoặc cấu trúc phức tạp hơn
                proposal.ProposalTime = TimeCurrent();

                if(m_TradeProposals.Add(proposal))
                {
                    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Added proposal for %s: %s, Quality %.2f, Risk %.2f%%", 
                        proposal.Symbol, EnumToString(proposal.OrderType), proposal.SignalQuality, proposal.RiskPercent * 100);
                }
                else
                {
                    if(m_Logger != NULL) m_Logger.LogErrorFormat("CPortfolioManager: Failed to add proposal for %s to array.", symbolName);
                    delete proposal; // Quan trọng: giải phóng bộ nhớ nếu không thêm được vào mảng
                }
            }
            else
            {
                if(m_Logger != NULL) m_Logger.LogWarningFormat("CPortfolioManager: Invalid format in GV '%s'. Expected 3 parts, got %d. Value: '%s'", gvName, count, gvValue);
            }
            
            // Xóa Global Variable sau khi xử lý
            if(GlobalVariableDel(gvName))
            {
                if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Deleted GV '%s' after processing.", gvName);
            }
            else
            {
                if(m_Logger != NULL) m_Logger.LogWarningFormat("CPortfolioManager: Failed to delete GV '%s'.", gvName);
            }
        }
    }
    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Finished loading. Found %d trade proposals.", m_TradeProposals.Total()); // Changed log level and message
}

//+------------------------------------------------------------------+
//| InitializeCorrelationMatrix (Helper)                             |
//+------------------------------------------------------------------+
void CPortfolioManager::InitializeCorrelationMatrix()
{
    // Đây là ví dụ đơn giản, bạn cần điền ma trận này với dữ liệu thực tế
    // hoặc có một cơ chế để cập nhật nó.
    // Chỉ khởi tạo một vài giá trị tượng trưng.
    // EURUSD vs GBPUSD: tương quan dương mạnh
    // USDJPY vs EURUSD: có thể tương quan âm
    // ... và các cặp khác

    // Khởi tạo m_SymbolIndexMap
    // Đây là ví dụ, bạn cần đảm bảo danh sách này khớp với các cặp tiền bạn giao dịch
    // và thứ tự của chúng trong ma trận tương quan.
    m_SymbolIndexMap[0] = "EURUSD"; m_SymbolIndexMap[1] = "GBPUSD"; m_SymbolIndexMap[2] = "USDJPY";
    m_SymbolIndexMap[3] = "AUDUSD"; m_SymbolIndexMap[4] = "USDCAD"; m_SymbolIndexMap[5] = "NZDUSD";
    m_SymbolIndexMap[6] = "USDCHF"; m_SymbolIndexMap[7] = "EURGBP"; m_SymbolIndexMap[8] = "EURJPY";
    // ... thêm các cặp tiền khác cho đủ 28 hoặc theo nhu cầu

    for(int i=0; i<28; i++) {
        for(int j=0; j<28; j++) {
            if(i == j) m_CorrelationMatrix[i][j] = 1.0; // Tự tương quan là 1
            else m_CorrelationMatrix[i][j] = 0.0; // Mặc định không tương quan
        }
    }
    // Ví dụ điền một vài giá trị:
    int eur_idx = GetSymbolIndex("EURUSD");
    int gbp_idx = GetSymbolIndex("GBPUSD");
    int jpy_idx = GetSymbolIndex("USDJPY");

    if(eur_idx != -1 && gbp_idx != -1) {
        m_CorrelationMatrix[eur_idx][gbp_idx] = 0.85; // EURUSD vs GBPUSD
        m_CorrelationMatrix[gbp_idx][eur_idx] = 0.85; // Đối xứng
    }
    if(eur_idx != -1 && jpy_idx != -1) {
        m_CorrelationMatrix[eur_idx][jpy_idx] = -0.40; // EURUSD vs USDJPY (ví dụ)
        m_CorrelationMatrix[jpy_idx][eur_idx] = -0.40; // Đối xứng
    }
    // ... thêm các giá trị khác
    if(m_Logger != NULL) m_Logger.LogDebug("CPortfolioManager: Correlation matrix initialized (placeholder values).");
}

//+------------------------------------------------------------------+
//| GetSymbolIndex (Helper)                                          |
//+------------------------------------------------------------------+
int CPortfolioManager::GetSymbolIndex(const string symbol_name)
{
    for(int i=0; i < ArraySize(m_SymbolIndexMap); i++)
    {
        if(m_SymbolIndexMap[i] == symbol_name) return i;
    }
    return -1; // Không tìm thấy
}

//+------------------------------------------------------------------+
//| AnalyzeProposals                                                 |
//+------------------------------------------------------------------+
void CPortfolioManager::AnalyzeProposals()
{
    if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Analyzing %d proposals...", m_TradeProposals.Total());
    // Logic phân tích tổng thể có thể được thêm ở đây nếu cần trước khi duyệt từng proposal
    // Ví dụ: tính toán rủi ro tổng thể hiện tại một lần
    // double currentTotalRisk = m_RiskManager != NULL ? m_RiskManager.GetTotalRiskPercent() : 0.0;
    // if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Current total portfolio risk: %.2f%%", currentTotalRisk * 100);
}

//+------------------------------------------------------------------+
//| DecideOnProposal                                                 |
//+------------------------------------------------------------------+
ENUM_PORTFOLIO_DECISION CPortfolioManager::DecideOnProposal(TradeProposal &proposal) // Nhận bằng tham chiếu để có thể cập nhật
{
    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: ==> Entering DecideOnProposal for %s %s...", proposal.Symbol, EnumToString(proposal.OrderType)); // Added log
    if(m_Logger == NULL || m_NewsFilter == NULL || m_RiskManager == NULL || m_PositionManager == NULL)
    {
        if(m_Logger != NULL) m_Logger.LogError("CPortfolioManager: Critical module (Logger, NewsFilter, RiskManager, or PositionManager) is NULL in DecideOnProposal.");
        return DECISION_REJECT; // Không thể ra quyết định nếu thiếu module quan trọng
    }

    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Deciding on proposal for %s %s, Quality: %.2f, Risk: %.2f%%", 
                                                proposal.Symbol, EnumToString(proposal.OrderType), proposal.SignalQuality, proposal.RiskPercent * 100);

    // 1. Kiểm tra Sự kiện Vĩ mô
    // TODO: Cần xác định time frame cho IsInNewsWindow (ví dụ: trong 30 phút tới)
    datetime checkTime = TimeCurrent() + 30 * 60; // Kiểm tra tin trong 30 phút tới
    if(m_NewsFilter.IsInNewsWindow(proposal.Symbol, checkTime, checkTime)) // Giả sử IsInNewsWindow kiểm tra một khoảng thời gian
    {
        if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Proposal for %s REJECTED/POSTPONED due to upcoming news.", proposal.Symbol);
        // return DECISION_POSTPONE; // Hoặc REJECT tùy chiến lược
        return DECISION_REJECT;
    }

    // 2. Kiểm tra Rủi ro Tổng thể
    double currentTotalRisk = m_RiskManager.GetTotalOpenRiskPercent(); // Hàm này cần được implement trong CRiskManager
    if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Current total open risk: %.2f%%. Proposal risk: %.2f%%. Max total risk: %.2f%%", 
                                                currentTotalRisk * 100, proposal.RiskPercent * 100, m_MaxTotalRisk * 100);
    if((currentTotalRisk + proposal.RiskPercent) > m_MaxTotalRisk)
    {
        if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Proposal for %s REJECTED due to exceeding max total risk (%.2f%% + %.2f%% > %.2f%%).", 
                                                    proposal.Symbol, currentTotalRisk*100, proposal.RiskPercent*100, m_MaxTotalRisk*100);
        // TODO: Có thể xem xét DECISION_ADJUST_LOT ở đây nếu rủi ro vượt không quá nhiều
        return DECISION_REJECT;
    }

    // 3. Kiểm tra Tương quan (Correlation)
    int proposalSymbolIndex = GetSymbolIndex(proposal.Symbol);
    if(proposalSymbolIndex != -1)
    {
        for(int i = 0; i < m_PositionManager.GetOpenPositionsCount(); i++) // Hàm GetOpenPositionsCount() cần có trong CPositionManager
        {
            string openPositionSymbol = m_PositionManager.GetOpenPositionSymbol(i); // Hàm GetOpenPositionSymbol(index) cần có
            ENUM_POSITION_TYPE openPositionDirection = m_PositionManager.GetOpenPositionDirection(i); // Hàm GetOpenPositionDirection(index) cần có
            int openSymbolIndex = GetSymbolIndex(openPositionSymbol);

            if(openSymbolIndex != -1)
            {
                double correlation = m_CorrelationMatrix[proposalSymbolIndex][openSymbolIndex];
                // Chỉ xem xét nếu cả hai cùng hướng (BUY-BUY hoặc SELL-SELL) hoặc ngược hướng (BUY-SELL) tùy vào dấu của correlation
                // Ví dụ đơn giản: nếu tương quan dương mạnh và cùng hướng, hoặc tương quan âm mạnh và ngược hướng -> có thể tăng rủi ro
                bool sameDirection = (proposal.OrderType == ORDER_TYPE_BUY && openPositionDirection == POSITION_TYPE_BUY) || 
                                     (proposal.OrderType == ORDER_TYPE_SELL && openPositionDirection == POSITION_TYPE_SELL);
                
                if(m_Logger != NULL) m_Logger.LogDebugFormat("CPortfolioManager: Checking correlation for %s vs open %s. Corr: %.2f. Same direction: %s", 
                                                            proposal.Symbol, openPositionSymbol, correlation, sameDirection ? "true" : "false");

                // Nếu tương quan dương mạnh và cùng hướng
                if(correlation > m_MaxCorrelationAllowed && sameDirection)
                {
                    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Proposal for %s REJECTED due to high positive correlation (%.2f > %.2f) with open %s (same direction).", 
                                                                proposal.Symbol, correlation, m_MaxCorrelationAllowed, openPositionSymbol);
                    return DECISION_REJECT;
                }
                // Nếu tương quan âm mạnh và ngược hướng (ví dụ: Mua EURUSD, Bán USDCHF, corr(EURUSD,USDCHF) ~ -0.9)
                // Điều này cũng làm tăng rủi ro theo một hướng (ví dụ: Long USD exposure)
                // Logic này cần được xem xét cẩn thận hơn dựa trên ma trận tương quan và cách nó được xây dựng.
                // Ví dụ: nếu corr(A,B) = -0.8, Mua A và Bán B -> cùng chiều rủi ro.
                // if(correlation < -m_MaxCorrelationAllowed && !sameDirection) // Logic này cần kiểm tra kỹ
                // {
                //     if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Proposal for %s REJECTED due to high negative correlation (%.2f < %.2f) with open %s (opposite direction, implies same underlying risk direction).", 
                //                                                 proposal.Symbol, correlation, -m_MaxCorrelationAllowed, openPositionSymbol);
                //     return DECISION_REJECT;
                // }
            }
        }
    }
    else
    {
        if(m_Logger != NULL) m_Logger.LogWarningFormat("CPortfolioManager: Symbol %s not found in correlation matrix map. Skipping correlation check.", proposal.Symbol);
    }

    // 4. Kiểm tra Tập trung Rủi ro (Risk Concentration) - Placeholder
    // TODO: Implement Risk Concentration logic
    // Ví dụ: Tính tổng rủi ro cho mỗi đồng tiền (USD, EUR, JPY, ...)
    // Nếu rủi ro của đồng tiền liên quan đến proposal (ví dụ USD trong EURUSD) vượt ngưỡng sau khi thêm proposal này, thì REJECT.
    // double riskConcentrationLimit = 0.60; // 60% tổng rủi ro cho một đồng tiền
    // if (IsRiskConcentrated(proposal, riskConcentrationLimit)) return DECISION_REJECT;
    if(m_Logger != NULL) m_Logger.LogDebug("CPortfolioManager: Risk concentration check (placeholder) - PASSED.");


    // 5. Ra quyết định Cuối cùng
    if(m_Logger != NULL) m_Logger.LogInfoFormat("CPortfolioManager: Proposal for %s %s APPROVED.", proposal.Symbol, EnumToString(proposal.OrderType));
    return DECISION_APPROVE;
}

//+------------------------------------------------------------------+
//| ProcessTradeProposals                                            |
//+------------------------------------------------------------------+
void CPortfolioManager::ProcessTradeProposals()
{
    if(m_Logger == NULL) {
        printf("CPortfolioManager Error: Logger is NULL in ProcessTradeProposals.");
        return;
    }
    m_Logger.LogInfo("CPortfolioManager: Starting to process trade proposals.");

    LoadProposals();    // Tải các đề xuất mới
    AnalyzeProposals(); // Phân tích chung (nếu có)

    for(int i = 0; i < m_TradeProposals.Total(); i++)
    {
        TradeProposal* proposal = m_TradeProposals.At(i);
        if(proposal == NULL) continue;

        ENUM_PORTFOLIO_DECISION decision = DecideOnProposal(*proposal); // Ra quyết định cho từng proposal
        proposal.Decision = decision; // Lưu quyết định vào proposal (nếu cần theo dõi)
        
        // Giao tiếp Quyết định Trở lại
        string decisionGvName = "GV_Decision_" + proposal.Symbol;
        string decisionGvValue;
        double adjustedLotFactor = 1.0; // Mặc định giữ nguyên lot

        switch(decision)
        {
            case DECISION_APPROVE:
                decisionGvValue = "APPROVE;" + DoubleToString(adjustedLotFactor, 2);
                break;
            case DECISION_REJECT:
                decisionGvValue = "REJECT;0.0";
                break;
            case DECISION_ADJUST_LOT:
                // TODO: Logic điều chỉnh lot ở đây, ví dụ giảm 50%
                adjustedLotFactor = 0.5; 
                decisionGvValue = "ADJUST_LOT;" + DoubleToString(adjustedLotFactor, 2);
                break;
            case DECISION_POSTPONE:
                decisionGvValue = "POSTPONE;0.0";
                break;
            default:
                decisionGvValue = "UNKNOWN;0.0";
                break;
        }
        
        if(GlobalVariableSet(decisionGvName, decisionGvValue))
        {
            m_Logger.LogInfoFormat("CPortfolioManager: ==> Decision for %s (%s) written to GV '%s': %s", 
                                   proposal.Symbol, EnumToString(proposal.OrderType), decisionGvName, decisionGvValue); // Added arrow for emphasis
        }
        else
        {
            m_Logger.LogErrorFormat("CPortfolioManager: ==> FAILED to write decision for %s to GV '%s'.", proposal.Symbol, decisionGvName); // Added arrow for emphasis
        }
        else
        {
            m_Logger.LogErrorFormat("CPortfolioManager: Failed to write decision for %s to GV '%s'.", proposal.Symbol, decisionGvName);
        }
    }

    m_Logger.LogInfo("CPortfolioManager: Finished processing trade proposals.");
}

} // namespace ApexPullback

#endif // PORTFOLIO_MANAGER_MQH