//+------------------------------------------------------------------+
//|                                     PositionManager.mqh (v14.2)   |
//|                                Copyright 2023-2024, ApexPullback EA |
//|                                    https://www.apexpullback.com  |
//|                Refactored: 2025-06-10 10:30:00 - Hợp nhất logic   |
//+------------------------------------------------------------------+
// #property copyright "Copyright 2024, MetaQuotes Ltd." // Nên đặt trong file .mq5 chính
// #property link      "https://www.metaquotes.net"   // Nên đặt trong file .mq5 chính

#ifndef POSITIONMANAGER_MQH_
#define POSITIONMANAGER_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "Inputs.mqh"           // Unified constants and input parameters
#include "Enums.mqh"            // Core enumerations

// === INCLUDES CỤ THỂ (NẾU CẦN) ===
#include "PositionInfoExt.mqh"  // For PositionInfoExt struct
#include "CommonStructs.mqh"    // Cho EAContext và các cấu trúc chung khác

// Định nghĩa các hằng số và biến toàn cục (NẾU CẦN RIÊNG CHO FILE NÀY)
// #define TP_NONE 0 // Đã có thể được định nghĩa trong Constants.mqh hoặc Enums.mqh
// #define MAX_HISTORY_DAYS 30  // Đã được định nghĩa trong Constants.mqh

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

// Forward declarations
class CAssetProfiler;

// --- CẤU TRÚC THÔNG TIN PORTFOLIO ---
struct PortfolioStatus {
    int     totalPositions;        // Tổng số vị thế đang mở
    int     buyPositions;          // Số vị thế mua
    int     sellPositions;         // Số vị thế bán
    double  totalRiskAmount;       // Tổng số tiền rủi ro
    double  totalRiskPercent;      // Tổng phần trăm rủi ro
    double  totalUnrealizedPnL;    // Tổng lợi nhuận chưa thực hiện
    double  totalUnrealizedPnLPercent; // Tổng lợi nhuận chưa thực hiện (%)
    double  averageR;              // R-multiple trung bình
    double  weightedAverageR;      // R-multiple trung bình có trọng số
    double  currentDrawdown;       // Drawdown hiện tại của danh mục
    double  successRate;           // Tỷ lệ thành công
    double  profitFactor;          // Profit factor
    ENUM_PORTFOLIO_HEALTH health;  // Sức khỏe danh mục

    // Hàm reset
    void Clear() {
        totalPositions = 0;
        buyPositions = 0;
        sellPositions = 0;
        totalRiskAmount = 0;
        totalRiskPercent = 0;
        totalUnrealizedPnL = 0;
        totalUnrealizedPnLPercent = 0;
        averageR = 0;
        weightedAverageR = 0;
        currentDrawdown = 0;
        successRate = 0;
        profitFactor = 0;
        health = PORTFOLIO_HEALTH_UNKNOWN;
    }
};

//+------------------------------------------------------------------+
//| CPositionManager - Quản lý vị thế ở mức cao                      |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    // Con trỏ Context trung tâm
    EAContext*            m_context;          // Con trỏ đến context của EA
    
    // Thông tin cơ bản
    string                m_symbol;           // Symbol hiện tại
    int                   m_magicNumber;      // Magic number
    int                   m_digits;           // Số chữ số thập phân
    double                m_point;            // Giá trị 1 point
    bool                  m_enableDetailedLogs; // Ghi log chi tiết
    
    // Mảng lưu trữ thông tin vị thế
    CArrayObj             m_positionsInfo;    // Mảng PositionInfoExt
    
    // Thông tin trạng thái danh mục
    PortfolioStatus       m_portfolioStatus;  // Trạng thái danh mục hiện tại
    
    // Tham số đánh giá và quản lý vị thế
    double                m_breakEvenAfterR;  // R-multiple để đạt breakeven
    double                m_breakEvenBuffer;  // Buffer cho breakeven
    double                m_partialCloseR1;   // R-multiple để đóng một phần 1
    double                m_partialCloseR2;   // R-multiple để đóng một phần 2
    double                m_partialClosePercent1; // % đóng ở mục tiêu 1
    double                m_partialClosePercent2; // % đóng ở mục tiêu 2
    double                m_maxRiskPerTrade;  // Risk % tối đa mỗi lệnh
    double                m_maxTotalRisk;     // Risk % tối đa cho toàn bộ
    int                   m_maxPositions;     // Số vị thế tối đa
    int                   m_maxPositionsPerDirection; // Số vị thế tối đa mỗi chiều
    int                   m_maxHoldingTime;   // Thời gian giữ tối đa (bars)
    double                m_maxDrawdown;      // Drawdown tối đa chấp nhận
    double                m_targetRMultiple;  // R-multiple mục tiêu
    double                m_maxLossPercent;   // % lỗ tối đa chấp nhận (từ equity)
    bool                  m_enableAutoClose;  // Tự động đóng khi đạt điều kiện
    
    // Dữ liệu lịch sử và thống kê
    datetime              m_lastUpdateTime;   // Thời gian cập nhật cuối
    int                   m_totalUpdates;     // Tổng số lần cập nhật
    int                   m_closedPositions;  // Số vị thế đã đóng
    int                   m_winPositions;     // Số vị thế thắng
    int                   m_losePositions;    // Số vị thế thua
    double                m_totalProfit;      // Tổng lợi nhuận
    double                m_totalLoss;        // Tổng lỗ
    
    // --- HÀM NỘI BỘ: QUẢN LÝ VỊ THẾ ---
    
    // Cập nhật thông tin vị thế hiện có
    void UpdatePositionInfo(PositionInfoExt &posInfo);
    
    // Tính toán các giá trị R hiện tại
    double CalculateCurrentR(PositionInfoExt &posInfo);
    
    // Tính toán lợi nhuận chưa thực hiện
    double CalculateUnrealizedPnL(const PositionInfoExt &posInfo);
    
    // Cập nhật trạng thái vị thế
    void UpdatePositionState(PositionInfoExt &posInfo);
    
    // Đánh giá sức khỏe danh mục (hàm chính, hợp nhất)
    void EvaluatePortfolio();

    // Đánh giá chất lượng của một vị thế cụ thể
    double EvaluatePositionQuality(const PositionInfoExt &posInfo);

    // Tìm vị thế theo ticket - trả về con trỏ, NULL nếu không tìm thấy
    PositionInfoExt* FindPositionByTicket(ulong ticket);

    // Loại bỏ các vị thế đã đóng khỏi danh sách quản lý
    void RemoveClosedPositions();

    // Xóa tất cả các vị thế khỏi danh sách quản lý
    void ClearAllPositions();

    // --- HÀM NỘI BỘ: KIỂM TRA ĐIỀU KIỆN DANH MỤC ---

    // Kiểm tra nếu có quá nhiều vị thế cùng chiều
    bool HasTooManyOneDirectionPositions();

    // Kiểm tra các điều kiện khẩn cấp để đóng tất cả vị thế
    bool ShouldCloseAllPositions(string &reason);
    
public:
    // Constructor và Destructor
    CPositionManager();
    ~CPositionManager();
    
    // --- KHỞI TẠO VÀ THIẾT LẬP ---
    
    // Khởi tạo với EAContext
    bool Initialize(EAContext* context);
    
    // Thiết lập tham số breakeven và đóng một phần
    void SetPartialCloseParameters(double breakEvenR, double buffer,
                                  double r1, double r2,
                                  double percent1, double percent2);
    
    // Thiết lập tham số quản lý danh mục
    void SetPortfolioParameters(double maxRiskPerTrade, double maxTotalRisk,
                                int maxPositions, int maxPositionsPerDirection,
                                double maxDrawdown, bool enableAutoClose = true);
    
    // Thiết lập thời gian giữ tối đa
    void SetMaxHoldingTime(int maxBars) { m_maxHoldingTime = maxBars; }
    
    // Bật/tắt ghi log chi tiết
    void SetDetailedLogging(bool enable) { m_enableDetailedLogs = enable; }
    
    // --- QUẢN LÝ VỊ THẾ ---
    
    // Cập nhật thông tin tất cả vị thế
    void UpdateAllPositions();
    
    // Thêm vị thế mới vào hệ thống quản lý
    bool AddPosition(PositionInfoExt* newPosition);
    
    // Cập nhật thông tin vị thế có sẵn
    bool UpdatePosition(ulong ticket, double newSL = 0, double newTP = 0);
    
    // Xóa vị thế (khi đã đóng)
    bool RemovePosition(ulong ticket);
    
    // Đánh giá toàn bộ danh mục
    void EvaluateAllPositions();
    
    // --- TRUY VẤN THÔNG TIN ---
    
    // Lấy danh sách tất cả vị thế
    int GetAllPositions(ulong &tickets[]);
    
    // Lấy thông tin của một vị thế
    bool GetPositionInfo(ulong ticket, PositionInfoExt &posInfo);
    
    // Lấy trạng thái danh mục
    PortfolioStatus GetPortfolioStatus() const { return m_portfolioStatus; }
    
    // Lấy số lượng vị thế
    int GetTotalPositions() const { return m_portfolioStatus.totalPositions; }
    
    // Lấy tổng rủi ro
    double GetTotalRiskPercent() const { return m_portfolioStatus.totalRiskPercent; }
    
    // Lấy tổng lợi nhuận chưa thực hiện
    double GetTotalUnrealizedPnL() const { return m_portfolioStatus.totalUnrealizedPnL; }
    
    // Lấy R trung bình
    double GetAverageR() const { return m_portfolioStatus.averageR; }
    
    // Lấy R trung bình có trọng số
    double GetWeightedAverageR() const { return m_portfolioStatus.weightedAverageR; }
    
    // --- ĐÁNH GIÁ VÀ ĐỀ XUẤT ---
    
    // Kiểm tra nếu có thể mở vị thế mới
    bool CanOpenNewPosition(ENUM_POSITION_TYPE type = POSITION_TYPE_BUY);
    
    // Kiểm tra nếu có thể nhồi lệnh
    bool IsScalingAllowed(ulong ticket);
    
    // Kiểm tra nếu nên đóng một phần
    bool ShouldPartialClose(ulong ticket, double &percentToClose);
    
    // Kiểm tra nếu đạt điều kiện breakeven
    bool ShouldMoveToBreakeven(ulong ticket);
    
    // Kiểm tra nếu nên đóng lệnh
    bool ShouldClose(ulong ticket, string &reason);
    
    // Kiểm tra nếu nên đóng tất cả (Hàm chính, gọi từ bên ngoài)
    bool ShouldCloseAllPositions(string &reason);
    
    // Kiểm tra sức khỏe danh mục
    ENUM_PORTFOLIO_HEALTH GetPortfolioHealth() const { return m_portfolioStatus.health; }
    
    // Lấy đề xuất R-multiple mục tiêu dựa trên tình hình hiện tại
    double GetRecommendedTargetR();
    
    // Lấy đề xuất risk % dựa trên tình hình hiện tại
    double GetRecommendedRiskPercent();
    
    // --- GHI LOG VÀ BÁO CÁO ---
    
    // Ghi log trạng thái
    void LogStatus();
    
    // Tạo báo cáo chi tiết
    string CreateDetailedReport();
    
    // Gửi cảnh báo khi có vấn đề
    void SendAlert(const string &message, bool isImportant = false);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CPositionManager::CPositionManager()
{
    // Khởi tạo giá trị mặc định
    m_symbol = "";
    m_magicNumber = 0;
    m_digits = 5;
    m_point = 0.00001;
    m_enableDetailedLogs = false;
    
    // Khởi tạo con trỏ
    m_context = NULL;
    
    // Khởi tạo tham số
    m_breakEvenAfterR = 1.0;
    m_breakEvenBuffer = 5.0;
    m_partialCloseR1 = 1.0;
    m_partialCloseR2 = 2.0;
    m_partialClosePercent1 = 35.0;
    m_partialClosePercent2 = 35.0;
    m_maxRiskPerTrade = 1.0;
    m_maxTotalRisk = 3.0;
    m_maxPositions = 5;
    m_maxPositionsPerDirection = 3;
    m_maxHoldingTime = 100;
    m_maxDrawdown = 10.0;
    m_targetRMultiple = 2.0;
    m_maxLossPercent = 5.0;
    m_enableAutoClose = true;
    
    // Khởi tạo dữ liệu thống kê
    m_lastUpdateTime = 0;
    m_totalUpdates = 0;
    m_closedPositions = 0;
    m_winPositions = 0;
    m_losePositions = 0;
    m_totalProfit = 0;
    m_totalLoss = 0;
    
    // Khởi tạo mảng vị thế
    m_positionsInfo.Clear();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CPositionManager::~CPositionManager()
{
    // Xóa tất cả vị thế
    ClearAllPositions();
    
    // Reset con trỏ từ bên ngoài
    m_context = NULL;
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo PositionManager                           |
//+------------------------------------------------------------------+
bool CPositionManager::Initialize(EAContext* context)
{
    if (context == NULL || context->Logger == NULL) {
        printf("CPositionManager::Initialize - Lỗi nghiêm trọng: EAContext hoặc Logger không hợp lệ.");
        return false;
    }
    m_context = context;

    m_symbol = m_context->Symbol;
    m_magicNumber = m_context->MagicNumber;
    m_enableDetailedLogs = m_context->EnableDetailedLogs;

    m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);

    // Đảm bảo mảng được thiết lập để quản lý các đối tượng con trỏ
    m_positionsInfo.SetFreeObjects(true);

    ClearAllPositions();

    m_context->Logger->LogInfo("PositionManager khởi tạo thành công cho " + m_symbol +
                         " với magic " + IntegerToString(m_magicNumber));

    UpdateAllPositions();

    return true;
}

//+------------------------------------------------------------------+
//| SetPartialCloseParameters - Thiết lập tham số đóng một phần      |
//+------------------------------------------------------------------+
void CPositionManager::SetPartialCloseParameters(double breakEvenR, double buffer,
                                               double r1, double r2,
                                               double percent1, double percent2)
{
    // Thiết lập tham số breakeven
    m_breakEvenAfterR = MathMax(0.1, breakEvenR);
    m_breakEvenBuffer = MathMax(0.0, buffer);
    
    // Thiết lập tham số đóng một phần
    m_partialCloseR1 = MathMax(0.1, r1);
    m_partialCloseR2 = MathMax(m_partialCloseR1, r2);
    m_partialClosePercent1 = MathMax(0.0, MathMin(99.0, percent1));
    m_partialClosePercent2 = MathMax(0.0, MathMin(99.0, percent2));
    
    // Log thông tin
    if (m_context != NULL && m_context->Logger != NULL && m_enableDetailedLogs) {
        m_context->Logger->LogInfo(StringFormat(
            "PositionManager: Thiết lập đóng một phần - BE: %.2fR, Buffer: %.1f, " +
            "TP1: %.2fR (%.1f%%), TP2: %.2fR (%.1f%%)",
            m_breakEvenAfterR, m_breakEvenBuffer,
            m_partialCloseR1, m_partialClosePercent1,
            m_partialCloseR2, m_partialClosePercent2
        ));
    }
}

//+------------------------------------------------------------------+
//| SetPortfolioParameters - Thiết lập tham số quản lý danh mục      |
//+------------------------------------------------------------------+
void CPositionManager::SetPortfolioParameters(double maxRiskPerTrade, double maxTotalRisk,
                                             int maxPositions, int maxPositionsPerDirection,
                                             double maxDrawdown, bool enableAutoClose)
{
    // Thiết lập tham số quản lý danh mục
    m_maxRiskPerTrade = MathMax(0.1, maxRiskPerTrade);
    m_maxTotalRisk = MathMax(m_maxRiskPerTrade, maxTotalRisk);
    m_maxPositions = MathMax(1, maxPositions);
    m_maxPositionsPerDirection = MathMax(1, MathMin(m_maxPositions, maxPositionsPerDirection));
    m_maxDrawdown = MathMax(1.0, maxDrawdown);
    m_enableAutoClose = enableAutoClose;
    
    // Log thông tin
    if (m_context != NULL && m_context->Logger != NULL && m_enableDetailedLogs) {
        m_context->Logger->LogInfo(StringFormat(
            "PositionManager: Thiết lập danh mục - MaxRisk/Lệnh: %.2f%%, MaxRisk: %.2f%%, " +
            "MaxVị thế: %d, MaxVị thế/Chiều: %d, MaxDD: %.2f%%, AutoClose: %s",
            m_maxRiskPerTrade, m_maxTotalRisk,
            m_maxPositions, m_maxPositionsPerDirection,
            m_maxDrawdown, enableAutoClose ? "Bật" : "Tắt"
        ));
    }
}

//+------------------------------------------------------------------+
//| UpdateAllPositions - Cập nhật thông tin tất cả vị thế            |
//+------------------------------------------------------------------+
void CPositionManager::UpdateAllPositions()
{
    m_lastUpdateTime = TimeCurrent();
    m_totalUpdates++;

    if (m_context == NULL || m_context->Logger == NULL) {
        printf("PositionManager: Context hoặc Logger không hợp lệ trong UpdateAllPositions.");
        return;
    }

    // Đánh dấu tất cả các vị thế trong danh sách quản lý là chưa được kiểm tra
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
        if (pos != NULL) {
            pos->isFoundInTerminal = false;
        }
    }

    // Lặp qua các vị thế đang mở trong terminal
    for (int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;

        // Chỉ xử lý các vị thế thuộc về EA này
        if (PositionGetString(POSITION_SYMBOL) != m_symbol || PositionGetInteger(POSITION_MAGIC) != m_magicNumber) {
            continue;
        }

        int posIndex = FindPositionByTicket(ticket);

        PositionInfoExt* pos = FindPositionByTicket(ticket);

        if (pos != NULL) {
            // Vị thế đã tồn tại -> Cập nhật nó
            UpdatePositionInfo(*pos);
            pos->isFoundInTerminal = true;
        } else {
            // Vị thế mới -> Tạo và thêm vào danh sách
            PositionInfoExt* newPos = new PositionInfoExt();
            if(newPos != NULL) {
                newPos->ticket = ticket;
                // Lấy thông tin cơ bản từ terminal
                newPos->symbol = PositionGetString(POSITION_SYMBOL);
                newPos->openTime = (datetime)PositionGetInteger(POSITION_TIME);
                newPos->type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                newPos->initialLots = PositionGetDouble(POSITION_VOLUME);
                newPos->currentLots = newPos->initialLots;
                newPos->entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                newPos->initialSL = PositionGetDouble(POSITION_SL);
                newPos->currentSL = newPos->initialSL;
                newPos->initialTP = PositionGetDouble(POSITION_TP);
                newPos->currentTP = newPos->initialTP;
                newPos->magic = (int)PositionGetInteger(POSITION_MAGIC);
                newPos->isFoundInTerminal = true;
                
                // Cần một cơ chế để lấy kịch bản và context lúc vào lệnh
                // Tạm thời để UNKNOWN
                newPos->scenario = TRADE_SCENARIO_UNKNOWN;

                // Cập nhật các thông tin tính toán
                UpdatePositionInfo(*newPos);

                // Thêm vào danh sách quản lý
                if (!AddPosition(newPos)) {
                    delete newPos; // Nếu thêm thất bại, giải phóng bộ nhớ
                }
            }
        }
    }

    // Loại bỏ các vị thế không còn trong terminal (đã đóng)
    RemoveClosedPositions();

    // Cập nhật trạng thái tổng thể của danh mục
    EvaluatePortfolio();

    if (m_enableDetailedLogs) {
        LogStatus();
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionInfo - Cập nhật thông tin chi tiết của vị thế      |
//+------------------------------------------------------------------+
void CPositionManager::UpdatePositionInfo(PositionInfoExt &posInfo)
{
    // Cập nhật giá hiện tại nếu cần
    if (posInfo.currentPrice <= 0) {
        if (posInfo.type == POSITION_TYPE_BUY) {
            posInfo.currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_BID);
        } else {
            posInfo.currentPrice = SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        }
    }
    
    // Tính khoảng cách rủi ro (entry - SL)
    double riskDistance = MathAbs(posInfo.entryPrice - posInfo.initialSL);
    
    // Tính số tiền rủi ro
    double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (m_point / tickSize);
    
    double riskPoints = riskDistance / m_point;
    posInfo.riskAmount = riskPoints * pointValue * posInfo.initialLots;
    
    // Tính phần trăm rủi ro
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (accountBalance > 0) {
        posInfo.riskPercent = posInfo.riskAmount / accountBalance * 100.0;
    }
    
    // Tính R-multiple hiện tại
    posInfo.currentR = CalculateCurrentR(posInfo);
    
    // Cập nhật maxR nếu cần
    if (posInfo.currentR > posInfo.maxR) {
        posInfo.maxR = posInfo.currentR;
    }
    
    // Tính lợi nhuận chưa thực hiện
    posInfo.unrealizedPnL = CalculateUnrealizedPnL(posInfo);
    
    // Tính lợi nhuận chưa thực hiện (%)
    if (accountBalance > 0) {
        posInfo.unrealizedPnLPercent = posInfo.unrealizedPnL / accountBalance * 100.0;
    }
    
    // Tính số nến đã giữ
    int barsHeld = 0;
    datetime currentTime = TimeCurrent();
    MqlDateTime openTimeStruct, currentTimeStruct;
    
    TimeToStruct(posInfo.openTime, openTimeStruct);
    TimeToStruct(currentTime, currentTimeStruct);
    
    // Kiểm tra timeframe hiện tại để tính số nến
    ENUM_TIMEFRAMES currentTimeframe = Period();
    datetime barTime[];
    
    ArraySetAsSeries(barTime, true);
    CopyTime(m_symbol, currentTimeframe, 0, 1000, barTime);
    
    // Tìm vị trí nến mở lệnh
    int openBarIndex = -1;
    for (int i = 0; i < ArraySize(barTime); i++) {
        if (barTime[i] <= posInfo.openTime) {
            openBarIndex = i;
            break;
        }
    }
    
    if (openBarIndex >= 0) {
        posInfo.holdingBars = openBarIndex;
    }
    
    // Cập nhật trạng thái vị thế
    UpdatePositionState(posInfo);
    
    // Đánh giá chất lượng vị thế
    posInfo.qualityScore = EvaluatePositionQuality(posInfo);
    
    // Thiết lập mục tiêu R-multiple
    if (posInfo.targetR <= 0) {
        // Mặc định là giá trị được cấu hình
        posInfo.targetR = m_targetRMultiple;
        
        // Điều chỉnh dựa trên AssetProfiler nếu có
        if (m_context->AssetProfiler != NULL) {
            // Lấy R-multiple tối ưu cho asset
            double assetTargetR = m_context->AssetProfiler->GetOptimalTargetR(posInfo.symbol, posInfo.scenario);
            
            if (assetTargetR > 0) {
                posInfo.targetR = assetTargetR;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateUnrealizedPnL - Tính lợi nhuận chưa thực hiện           |
//+------------------------------------------------------------------+
double CPositionManager::CalculateUnrealizedPnL(const ApexPullback::PositionInfoExt &posInfo)
{
    double pnl = 0.0;
    double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (m_point / tickSize);
    
    // Tính lợi nhuận dựa trên loại lệnh và chênh lệch giá
    if (posInfo.type == POSITION_TYPE_BUY) {
        // Lệnh mua: PnL = (Giá hiện tại - Giá vào) * Khối lượng * Giá trị một điểm
        pnl = (posInfo.currentPrice - posInfo.entryPrice) * posInfo.currentLots * pointValue / m_point;
    } else {
        // Lệnh bán: PnL = (Giá vào - Giá hiện tại) * Khối lượng * Giá trị một điểm
        pnl = (posInfo.entryPrice - posInfo.currentPrice) * posInfo.currentLots * pointValue / m_point;
    }
    
    return NormalizeDouble(pnl, 2);
}

//+------------------------------------------------------------------+
//| CalculateCurrentR - Tính R-multiple hiện tại                     |
//+------------------------------------------------------------------+
double CPositionManager::CalculateCurrentR(ApexPullback::PositionInfoExt &posInfo)
{
    // Tính khoảng cách rủi ro ban đầu
    double riskDistance = MathAbs(posInfo.entryPrice - posInfo.initialSL);
    
    // Kiểm tra riskDistance
    if (riskDistance <= 0) return 0;
    
    // Tính R-multiple hiện tại
    double currentR = 0;
    
    if (posInfo.type == POSITION_TYPE_BUY) {
        // Lệnh buy: R = (CurrentPrice - EntryPrice) / RiskDistance
        currentR = (posInfo.currentPrice - posInfo.entryPrice) / riskDistance;
    } else {
        // Lệnh sell: R = (EntryPrice - CurrentPrice) / RiskDistance
        currentR = (posInfo.entryPrice - posInfo.currentPrice) / riskDistance;
    }
    
    return currentR;
}

//+------------------------------------------------------------------+
//| UpdatePositionState - Cập nhật trạng thái vị thế                 |
//+------------------------------------------------------------------+
void CPositionManager::UpdatePositionState(ApexPullback::PositionInfoExt &posInfo)
{
    // Kiểm tra và cập nhật trạng thái
    
    // Kiểm tra breakeven
    if (!posInfo.isBreakevenHit) {
        // Kiểm tra nếu đã đạt breakeven
        if (posInfo.currentR >= m_breakEvenAfterR) {
            // Kiểm tra nếu SL đã ở breakeven
            bool isAtBreakeven = false;
            
            if (posInfo.type == POSITION_TYPE_BUY) {
                isAtBreakeven = (posInfo.currentSL >= posInfo.entryPrice);
            } else {
                isAtBreakeven = (posInfo.currentSL <= posInfo.entryPrice);
            }
            
            if (isAtBreakeven) {
                posInfo.isBreakevenHit = true;
                posInfo.state = POSITION_STATE_BREAKEVEN;
                
                if (m_context->Logger != NULL) {
                    m_context->Logger->LogInfo(StringFormat(
                        "PositionManager: Vị thế #%d đạt breakeven - R: %.2f",
                        posInfo.ticket, posInfo.currentR
                    ));
                }
            }
        }
    }
    
    // Kiểm tra đã đóng một phần lần 1
    if (!posInfo.isPartial1Done) {
        if (posInfo.currentR >= m_partialCloseR1 && posInfo.currentLots < posInfo.initialLots) {
            posInfo.isPartial1Done = true;
            posInfo.partialCloseCount++;
            posInfo.state = POSITION_STATE_PARTIAL1;
            
            if (m_context->Logger != NULL && m_enableDetailedLogs) {
                m_context->Logger->LogInfo(StringFormat(
                    "PositionManager: Đã đóng một phần vị thế #%d - %.2f%% - R: %.2f",
                    posInfo.ticket, 50.0, posInfo.currentR
                ));
            }
        }
    }
    
    // Kiểm tra đã đóng một phần lần 2
    if (posInfo.isPartial1Done && !posInfo.isPartial2Done) {
        if (posInfo.currentR >= m_partialCloseR2 && 
            posInfo.currentLots < posInfo.initialLots * (1 - m_partialClosePercent1/100)) {
            posInfo.isPartial2Done = true;
            posInfo.partialCloseCount++;
            posInfo.state = POSITION_STATE_PARTIAL2;
            
            if (m_context->Logger != NULL && m_enableDetailedLogs) {
                m_context->Logger->LogInfo(StringFormat(
                    "PositionManager: Vị thế #%d đã đóng một phần lần 2 - R: %.2f",
                    posInfo.ticket, posInfo.currentR
                ));
            }
        }
    }
    
    // Kiểm tra cần trailing
    double atr = 0;
    // Lấy ATR từ context (đã được cập nhật bởi MarketProfile hoặc AssetProfiler)
    if (m_context->MarketProfile != NULL) {
        atr = m_context->MarketProfile->GetATR();
    }
    
    if (atr > 0) {
        double trailingDistance = 0;
        
        if (posInfo.type == POSITION_TYPE_BUY) {
            trailingDistance = posInfo.currentPrice - posInfo.currentSL;
            
            // Nếu khoảng cách quá lớn, cần trailing
            if (trailingDistance > atr * 2.0) {
                posInfo.needsTrailing = true;
                posInfo.state = POSITION_STATE_TRAILING;
            } else {
                posInfo.needsTrailing = false;
            }
        } else {
            trailingDistance = posInfo.currentSL - posInfo.currentPrice;
            
            // Nếu khoảng cách quá lớn, cần trailing
            if (trailingDistance > atr * 2.0) {
                posInfo.needsTrailing = true;
                posInfo.state = POSITION_STATE_TRAILING;
            } else {
                posInfo.needsTrailing = false;
            }
        }
    }
    
    // Kiểm tra cảnh báo
    if (posInfo.holdingBars > m_maxHoldingTime) {
        posInfo.state = POSITION_STATE_WARNING;
        
        if (m_context->Logger != NULL) {
            m_context->Logger->LogInfo(StringFormat(
                "PositionManager: Vị thế #%d đã giữ quá lâu - %d nến vượt quá %d nến",
                posInfo.ticket, posInfo.holdingBars, m_maxHoldingTime
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| EvaluatePositionQuality - Đánh giá chất lượng vị thế             |
//+------------------------------------------------------------------+
double CPositionManager::EvaluatePositionQuality(const PositionInfoExt &posInfo)
{
    if (m_context == NULL) return 0.5; // Trả về giá trị trung bình nếu không có context

    double score = 50.0;

    // Đánh giá dựa trên R hiện tại
    if (posInfo.currentR >= 2.0) score += 20.0;
    else if (posInfo.currentR >= 1.0) score += 10.0;
    else if (posInfo.currentR <= -0.5) score -= 20.0;

    // Đánh giá dựa trên thời gian giữ
    if (posInfo.holdingBars > m_maxHoldingTime) score -= 15.0;
    else if (posInfo.holdingBars > m_maxHoldingTime * 0.7) score -= 5.0;

    // Đánh giá dựa trên trạng thái quản lý
    if (posInfo.isBreakevenHit) score += 10.0;
    if (posInfo.isPartial1Done) score += 5.0;
    if (posInfo.isPartial2Done) score += 5.0;

    // Đánh giá dựa trên sự phù hợp với Market Regime từ context
    if (m_context->MarketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_context->CurrentMarketRegime;
        if ((posInfo.type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BULL) ||
            (posInfo.type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BEAR)) {
            score += 15.0; // Thưởng lớn cho sự đồng thuận
        } else if ((posInfo.type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BEAR) ||
                   (posInfo.type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BULL)) {
            score -= 20.0; // Phạt nặng cho sự xung đột
        } else if (regime == REGIME_RANGING_VOLATILE || regime == REGIME_VOLATILE_EXPANSION) {
            score -= 10.0; // Phạt cho sự biến động không rõ ràng
        }
    }

    score = MathMax(0.0, MathMin(100.0, score));
    return score / 100.0;
}

//+------------------------------------------------------------------+
//| Đánh giá chất lượng thị trường hiện tại                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| RemoveClosedPositions - Loại bỏ vị thế đã đóng                  |
//+------------------------------------------------------------------+
void CPositionManager::RemoveClosedPositions()
{
    if (m_context == NULL || m_context->Logger == NULL) return;

    for (int i = m_positionsInfo.Total() - 1; i >= 0; i--) {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
        if (pos != NULL && !pos->isFoundInTerminal) {
            if (m_enableDetailedLogs) {
                m_context->Logger->LogInfo(StringFormat("PositionManager: Vị thế #%d đã đóng, loại bỏ khỏi danh sách quản lý.", pos->ticket));
            }

            // TODO: Cần một cơ chế chính xác hơn để lấy PnL cuối cùng từ lịch sử giao dịch.
            // Tạm thời, chúng ta giả định PnL cuối cùng là unrealizedPnL ngay trước khi đóng.
            double finalPnL = pos->unrealizedPnL;

            // Cập nhật thống kê
            m_closedPositions++;
            if (finalPnL > 0) {
                m_winPositions++;
                m_totalProfit += finalPnL;
            } else {
                m_losePositions++;
                m_totalLoss += finalPnL;
            }

            // Xóa khỏi mảng. CArrayObj với SetFreeObjects(true) sẽ tự động giải phóng bộ nhớ.
            m_positionsInfo.Delete(i);
        }
    }
}

//+------------------------------------------------------------------+
//| ClearAllPositions - Xóa toàn bộ vị thế                          |
//+------------------------------------------------------------------+
void CPositionManager::ClearAllPositions()
{
    if (m_context != NULL && m_context->Logger != NULL && m_enableDetailedLogs) {
        m_context->Logger->LogInfo("PositionManager: Đang xóa tất cả vị thế khỏi theo dõi nội bộ...");
    }

    m_positionsInfo.Clear();

    m_portfolioStatus.Clear();

    m_lastUpdateTime = 0;
    m_totalUpdates = 0;
    m_closedPositions = 0;
    m_winPositions = 0;
    m_losePositions = 0;
    m_totalProfit = 0.0;
    m_totalLoss = 0.0;

    if (m_context != NULL && m_context->Logger != NULL && m_enableDetailedLogs) {
        m_context->Logger->LogInfo("PositionManager: Đã xóa tất cả thông tin vị thế và reset trạng thái.");
    }
}

//+------------------------------------------------------------------+
//| EvaluatePortfolio - Đánh giá toàn diện sức khỏe danh mục (Hợp nhất) |
//+------------------------------------------------------------------+
void CPositionManager::EvaluatePortfolio()
{
    if (m_context == NULL) return;

    // 1. Reset trạng thái và tính toán lại từ các vị thế đang mở
    m_portfolioStatus.Clear();
    double totalR = 0;
    double totalWeightedR = 0;
    double totalWeight = 0;

    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
        if (pos == NULL) continue;

        m_portfolioStatus.totalPositions++;
        if (pos->type == POSITION_TYPE_BUY) m_portfolioStatus.buyPositions++;
        else m_portfolioStatus.sellPositions++;

        // Tính rủi ro đã điều chỉnh (về 0 nếu đã BE)
        double adjustedRisk = pos->isBreakevenHit ? 0 : pos->riskAmount;
        m_portfolioStatus.totalRiskAmount += adjustedRisk;
        m_portfolioStatus.totalUnrealizedPnL += pos->unrealizedPnL;

        totalR += pos->currentR;
        double weight = pos->riskPercent > 0 ? pos->riskPercent : 1.0;
        totalWeightedR += pos->currentR * weight;
        totalWeight += weight;
    }

    // 2. Tính toán các chỉ số tổng hợp
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (accountBalance > 0) {
        m_portfolioStatus.totalRiskPercent = (m_portfolioStatus.totalRiskAmount / accountBalance) * 100.0;
        m_portfolioStatus.totalUnrealizedPnLPercent = (m_portfolioStatus.totalUnrealizedPnL / accountBalance) * 100.0;
    }

    if (m_portfolioStatus.totalPositions > 0) {
        m_portfolioStatus.averageR = totalR / m_portfolioStatus.totalPositions;
    }
    if (totalWeight > 0) {
        m_portfolioStatus.weightedAverageR = totalWeightedR / totalWeight;
    }

    // 3. Tính toán các chỉ số hiệu suất từ các vị thế đã đóng
    if (m_closedPositions > 0) {
        m_portfolioStatus.successRate = (double)m_winPositions / m_closedPositions * 100.0;
    } else {
        m_portfolioStatus.successRate = -1; // -1 để chỉ ra chưa có dữ liệu
    }

    if (MathAbs(m_totalLoss) > 0) {
        m_portfolioStatus.profitFactor = m_totalProfit / MathAbs(m_totalLoss);
    } else if (m_totalProfit > 0) {
        m_portfolioStatus.profitFactor = 999.0; // Giá trị lớn nếu không có lỗ
    } else {
        m_portfolioStatus.profitFactor = -1; // -1 để chỉ ra chưa có dữ liệu
    }

    // 4. Đánh giá sức khỏe tổng thể của danh mục
    m_portfolioStatus.health = PORTFOLIO_HEALTH_AVERAGE;
    if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk || m_context->CurrentDrawdownPercent > m_maxDrawdown) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_DANGER;
    } else if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.75 || m_portfolioStatus.averageR < -0.2) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_WARNING;
    } else if (m_portfolioStatus.averageR > 0.8 && m_portfolioStatus.profitFactor > 1.5) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_GOOD;
    }

    // 5. Cảnh báo về hiệu suất gần đây
    if (m_closedPositions >= 10 && m_context->Logger != NULL) {
        if (m_portfolioStatus.successRate != -1 && m_portfolioStatus.successRate < 40.0) {
            m_context->Logger->LogWarning(StringFormat("Cảnh báo hiệu suất: Tỷ lệ thắng thấp (%.1f%%) sau %d lệnh.", m_portfolioStatus.successRate, m_closedPositions));
        }
        if (m_portfolioStatus.profitFactor != -1 && m_portfolioStatus.profitFactor < 1.2) {
            m_context->Logger->LogWarning(StringFormat("Cảnh báo hiệu suất: Profit Factor thấp (%.2f) sau %d lệnh.", m_portfolioStatus.profitFactor, m_closedPositions));
        }
    }
}

//+------------------------------------------------------------------+
//| HasTooManyOneDirectionPositions - Kiểm tra quá nhiều vị thế cùng chiều |
//+------------------------------------------------------------------+
bool CPositionManager::HasTooManyOneDirectionPositions()
{
    if (m_portfolioStatus.buyPositions >= m_maxPositionsPerDirection) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning(StringFormat("PositionManager: Đã đạt giới hạn vị thế BUY (%d)", m_maxPositionsPerDirection));
        }
        return true;
    }

    if (m_portfolioStatus.sellPositions >= m_maxPositionsPerDirection) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning(StringFormat("PositionManager: Đã đạt giới hạn vị thế SELL (%d)", m_maxPositionsPerDirection));
        }
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| LogStatus - Ghi log trạng thái hiện tại của danh mục            |
//+------------------------------------------------------------------+
void CPositionManager::LogStatus()
{
    if (m_context->Logger == NULL) return;

    string statusMsg = StringFormat(
        "--- Portfolio Status [Cập nhật: %s] ---\n" +
        "Tổng vị thế: %d (Buy: %d, Sell: %d) | Vị thế đã đóng: %d\n" +
        "Tổng PnL chưa thực hiện: %s (%.2f%%) | Tổng rủi ro: %s (%.2f%%)\n" +
        "R-multiple: TB %.2f, TB có trọng số %.2f\n" +
        "Tỷ lệ thắng: %.2f%% | Profit Factor: %.2f",
        TimeToString(m_lastUpdateTime, TIME_SECONDS),
        m_portfolioStatus.totalPositions, m_portfolioStatus.buyPositions, m_portfolioStatus.sellPositions, m_closedPositions,
        DoubleToString(m_portfolioStatus.totalUnrealizedPnL, 2),
        m_portfolioStatus.totalUnrealizedPnLPercent,
        DoubleToString(m_portfolioStatus.totalRiskAmount, 2),
        m_portfolioStatus.totalRiskPercent,
        m_portfolioStatus.averageR,
        m_portfolioStatus.weightedAverageR,
        m_portfolioStatus.successRate,
        m_portfolioStatus.profitFactor
    );
    m_context->Logger->LogInfo(statusMsg);

    // Log chi tiết từng vị thế nếu được bật
    if (m_enableDetailedLogs && m_positionsInfo.Total() > 0) {
        m_context->Logger->LogInfo("--- Chi tiết các vị thế đang mở ---");
        for (int i = 0; i < m_positionsInfo.Total(); i++) {
            PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
            if (pos == NULL) continue;
            string posMsg = StringFormat(
                "#%d: %s %s, %.2f lots, Entry: %.5f, SL: %.5f, TP: %.5f, PnL: %s, R: %.2f, State: %s",
                pos->ticket,
                pos->symbol,
                (pos->type == POSITION_TYPE_BUY ? "BUY" : "SELL"),
                pos->currentLots,
                pos->entryPrice,
                pos->currentSL,
                pos->currentTP,
                DoubleToString(pos->unrealizedPnL, 2),
                pos->currentR,
                EnumToString(pos->state)
            );
            m_context->Logger->LogInfo(posMsg);
        }
    }
}



//+------------------------------------------------------------------+
//| ShouldCloseAllPositions - Kiểm tra nếu nên đóng tất cả vị thế    |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldCloseAllPositions(string &reason)
{
    if (m_context == NULL) return false;

    // Lấy drawdown từ context (đã được cập nhật bởi RiskManager)
    double maxDrawDown = m_context->CurrentDrawdownPercent;

    // Kiểm tra nếu drawdown vượt ngưỡng
    if (maxDrawDown > m_maxDrawdown) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning(StringFormat("PositionManager: Drawdown vượt ngưỡng - %.2f%% > %.2f%%", maxDrawDown, m_maxDrawdown));
        }
        reason = "Drawdown vượt ngưỡng";
        return true;
    }

    // Kiểm tra tổng lỗ
    double unrealizedPnL = m_portfolioStatus.totalUnrealizedPnL;
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double lossPercent = (equity > 0) ? (MathAbs(unrealizedPnL) / equity * 100.0) : 0;

    if (unrealizedPnL < 0 && lossPercent > m_maxLossPercent) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning(StringFormat("PositionManager: Tổng lỗ vượt ngưỡng - %.2f%% > %.2f%%", lossPercent, m_maxLossPercent));
        }
        reason = "Tổng lỗ vượt ngưỡng";
        return true;
    }

    // Kiểm tra tin tức từ context (đã được cập nhật bởi NewsFilter)
    if (m_context->HasCurrentNewsEvent) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning("PositionManager: Có tin tức quan trọng sắp diễn ra, đóng vị thế phòng ngừa.");
        }
        reason = "Sự kiện tin tức quan trọng";
        return true;
    }

    // Kiểm tra thị trường bất thường từ context
    if (m_context->ATRRatio > 2.5) {
        if (m_context->Logger != NULL) {
            m_context->Logger->LogWarning(StringFormat("PositionManager: Thị trường biến động cực kỳ cao (ATR Ratio: %.2f), đóng vị thế.", m_context->ATRRatio));
        }
        reason = "Thị trường biến động cao";
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| IsScalingAllowed - Kiểm tra nếu có thể nhồi lệnh                 |
//+------------------------------------------------------------------+
bool CPositionManager::IsScalingAllowed(ulong ticket)
{
    if (m_context == NULL || m_context->Logger == NULL) return false;

    PositionInfoExt* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        m_context->Logger->LogWarning(StringFormat("PositionManager: Không tìm thấy vị thế #%d để kiểm tra nhồi lệnh.", ticket));
        return false;
    }

    // Điều kiện 1: Vị thế phải có lãi và an toàn (đã BE)
    if (!pos->isBreakevenHit) {
        if (m_enableDetailedLogs) m_context->Logger->LogInfo(StringFormat("Scaling Check #%d: Thất bại - Chưa đạt breakeven.", ticket));
        return false;
    }

    // Điều kiện 2: Đã chốt lời một phần để giảm rủi ro
    if (!pos->isPartial1Done) {
        if (m_enableDetailedLogs) m_context->Logger->LogInfo(StringFormat("Scaling Check #%d: Thất bại - Chưa chốt lời lần 1.", ticket));
        return false;
    }

    // Điều kiện 3: Giới hạn số lượng vị thế
    if (m_portfolioStatus.totalPositions >= m_maxPositions ||
        (pos->type == POSITION_TYPE_BUY && m_portfolioStatus.buyPositions >= m_maxPositionsPerDirection) ||
        (pos->type == POSITION_TYPE_SELL && m_portfolioStatus.sellPositions >= m_maxPositionsPerDirection)) {
        m_context->Logger->LogWarning("Scaling Check: Thất bại - Đã đạt giới hạn số lượng vị thế.");
        return false;
    }

    // Điều kiện 4: Rủi ro danh mục phải trong tầm kiểm soát
    if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.8) {
        if (m_enableDetailedLogs) m_context->Logger->LogInfo(StringFormat("Scaling Check: Thất bại - Rủi ro danh mục (%.2f%%) quá cao.", m_portfolioStatus.totalRiskPercent));
        return false;
    }

    // Điều kiện 5: Thị trường phải có xu hướng rõ ràng và đồng thuận
    ENUM_MARKET_REGIME regime = m_context->CurrentMarketRegime;
    if ((pos->type == POSITION_TYPE_BUY && regime != REGIME_TRENDING_BULL) ||
        (pos->type == POSITION_TYPE_SELL && regime != REGIME_TRENDING_BEAR)) {
        if (m_enableDetailedLogs) m_context->Logger->LogInfo(StringFormat("Scaling Check #%d: Thất bại - Hướng vị thế (%s) không phù hợp với Market Regime (%s).", ticket, EnumToString(pos->type), EnumToString(regime)));
        return false;
    }

    // Điều kiện 6: Không có sự kiện tin tức lớn sắp diễn ra
    if (m_context->HasUpcomingNews) {
        m_context->Logger->LogWarning("Scaling Check: Thất bại - Có tin tức quan trọng sắp diễn ra.");
        return false;
    }

    m_context->Logger->LogInfo(StringFormat("Scaling Check #%d: OK - Có thể nhồi lệnh.", ticket));
    return true;
}



//+------------------------------------------------------------------+
//| GetRecommendedTargetR - Lấy đề xuất R-multiple mục tiêu          |
//+------------------------------------------------------------------+
double CPositionManager::GetRecommendedTargetR()
{
    // Mặc định
    double targetR = m_targetRMultiple;
    
    // Điều chỉnh dựa trên các yếu tố
    
    // 1. Dựa trên Market Regime
    if (m_context->IsMarketProfileValid) {
        ENUM_MARKET_REGIME regime = m_context->CurrentMarketRegime;
        
        switch (regime) {
            case REGIME_TRENDING_BULL:
            case REGIME_TRENDING_BEAR:
                // Xu hướng mạnh - TP xa hơn
                targetR *= 1.2;
                break;
                
            case REGIME_RANGING_STABLE:
            case REGIME_RANGING_VOLATILE:
                // Sideway - TP gần hơn
                targetR *= 0.8;
                break;
                
            case REGIME_VOLATILE_EXPANSION:
            case REGIME_VOLATILE_CONTRACTION:
                // Biến động cao - TP gần hơn
                targetR *= 0.7;
                break;
                
            default:
                break;
        }
    }
    
    // 2. Dựa trên tổng rủi ro
    if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.7) {
        // Rủi ro cao - TP gần hơn
        targetR *= 0.9;
    }
    
    // 3. Dựa trên hiệu suất gần đây
    // Giới hạn trong khoảng hợp lý
    targetR = MathMax(1.0, MathMin(4.0, targetR));
    
    return targetR;
}

//+------------------------------------------------------------------+
//| GetRecommendedRiskPercent - Lấy đề xuất risk %                    |
//+------------------------------------------------------------------+
double CPositionManager::GetRecommendedRiskPercent()
{
    if (m_context == NULL) return m_maxRiskPerTrade;

    double riskPercent = m_maxRiskPerTrade;

    // 1. Điều chỉnh dựa trên tổng rủi ro hiện tại
    double riskLeft = m_maxTotalRisk - m_portfolioStatus.totalRiskPercent;
    riskPercent = MathMin(riskPercent, riskLeft);

    // 2. Điều chỉnh dựa trên Market Regime
    if (m_context->MarketProfile != NULL && m_context->IsMarketProfileValid) {
        ENUM_MARKET_REGIME regime = m_context->CurrentMarketRegime;
        switch (regime) {
            case REGIME_TRENDING_BULL:
            case REGIME_TRENDING_BEAR: riskPercent *= 1.1; break; // Tăng nhẹ trong xu hướng
            case REGIME_RANGING_STABLE: riskPercent *= 0.9; break; // Giảm nhẹ khi sideway
            case REGIME_RANGING_VOLATILE:
            case REGIME_VOLATILE_EXPANSION:
            case REGIME_VOLATILE_CONTRACTION: riskPercent *= 0.7; break; // Giảm mạnh khi biến động cao
        }
    }

    // 3. Điều chỉnh dựa trên hiệu suất gần đây (chỉ khi có đủ dữ liệu)
    if (m_closedPositions >= 10) {
        if (m_portfolioStatus.successRate > 0 && m_portfolioStatus.profitFactor > 0) {
            if (m_portfolioStatus.successRate < 40.0 || m_portfolioStatus.profitFactor < 1.2) {
                riskPercent *= 0.75; // Giảm rủi ro khi hiệu suất kém
            } else if (m_portfolioStatus.successRate > 60.0 && m_portfolioStatus.profitFactor > 1.8) {
                riskPercent *= 1.2; // Tăng rủi ro khi hiệu suất tốt
            }
        }
    }

    // 4. Điều chỉnh dựa trên AssetProfiler (nếu có)
    if (m_context->AssetProfiler != NULL) {
        double volatilityFactor = m_context->AssetProfiler->GetVolatilityFactor(m_symbol);
        if (volatilityFactor > 1.2) {
            riskPercent /= (volatilityFactor - 0.2); // Giảm rủi ro nếu biến động cao hơn bình thường
        }
    }

    // 5. Giới hạn trong khoảng an toàn
    riskPercent = MathMax(0.1, MathMin(m_maxRiskPerTrade, riskPercent));

    return NormalizeDouble(riskPercent, 2);
}

//+------------------------------------------------------------------+
//| AddPosition - Thêm vị thế mới vào hệ thống quản lý             |
//+------------------------------------------------------------------+
bool CPositionManager::AddPosition(PositionInfoExt* newPosition)
{
    if (newPosition == NULL || m_context == NULL || m_context->Logger == NULL) return false;

    if (FindPositionByTicket(newPosition->ticket) != NULL) {
        m_context->Logger->LogWarning(StringFormat("PositionManager: Vị thế #%d đã tồn tại, không thêm mới.", newPosition->ticket));
        return false;
    }

    if (m_positionsInfo.Add(newPosition)) {
        if (m_enableDetailedLogs) {
            m_context->Logger->LogInfo(StringFormat("PositionManager: Đã thêm vị thế mới #%d vào quản lý.", newPosition->ticket));
        }
        // Cập nhật lại danh mục ngay sau khi thêm
        EvaluatePortfolio();
        return true;
    }

    m_context->Logger->LogError(StringFormat("PositionManager: Không thể thêm vị thế #%d vào mảng quản lý.", newPosition->ticket));
    return false;
}

//+------------------------------------------------------------------+
//| FindPositionByTicket - Tìm vị thế theo ticket (trả về con trỏ)  |
//+------------------------------------------------------------------+
PositionInfoExt* CPositionManager::FindPositionByTicket(ulong ticket)
{
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
        if (pos != NULL && pos->ticket == ticket) {
            return pos;
        }
    }
    return NULL;
}

//+------------------------------------------------------------------+
//| CreateDetailedReport - Tạo báo cáo chi tiết                      |
//+------------------------------------------------------------------+
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
    
    if (m_positionsInfo.Total() > 0) {
        for (int i = 0; i < m_positionsInfo.Total(); i++) {
            PositionInfoExt* pos = (PositionInfoExt*)m_positionsInfo.At(i);
            if(pos == NULL) continue;
            
            report += StringFormat("#%d - %s (%.2f lot)\n", 
                                 pos->ticket, 
                                 pos->type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                 pos->currentLots);
            report += StringFormat("  Entry: %.5f, SL: %.5f, TP: %.5f\n", 
                                 pos->entryPrice, pos->currentSL, pos->currentTP);
            report += StringFormat("  R hiện tại: %.2f, PnL: %.2f đ (%.2f%%)\n", 
                                 pos->currentR, pos->unrealizedPnL, pos->unrealizedPnLPercent);
            report += StringFormat("  Giữ: %d nến, Trạng thái: %s\n", 
                                 pos->holdingBars, EnumToString(pos->state));
            report += StringFormat("  Scenario: %s, BE: %s, TP1: %s, TP2: %s\n\n", 
                                 EnumToString(pos->scenario),
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