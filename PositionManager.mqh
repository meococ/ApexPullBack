//+------------------------------------------------------------------+
//|                                     PositionManager.mqh (v14.0)   |
//|                                Copyright 2023-2024, ApexPullback EA |
//|                                    https://www.apexpullback.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2024, ApexPullback EA"
#property link      "https://www.apexpullback.com"
#property version   "14.0"
#property strict

// Nạp các file cấu trúc và module liên quan
#include "CommonStructs.mqh"
#include "Logger.mqh"
#include "MarketProfile.mqh"
#include "RiskManager.mqh"
#include "AssetProfiler.mqh"
#include "NewsFilter.mqh"
#include "Enums.mqh"

// --- ĐỊNH NGHĨA TRẠNG THÁI VỊ THẾ ---
enum ENUM_POSITION_STATE {
    POSITION_STATE_NORMAL,        // Trạng thái bình thường
    POSITION_STATE_BREAKEVEN,     // Đã đạt breakeven
    POSITION_STATE_PARTIAL1,      // Đã đóng một phần lần 1
    POSITION_STATE_PARTIAL2,      // Đã đóng một phần lần 2
    POSITION_STATE_SCALING,       // Đã nhồi lệnh
    POSITION_STATE_TRAILING,      // Đang trailing
    POSITION_STATE_WARNING        // Cảnh báo (ví dụ: thời gian giữ quá lâu)
};

// --- CẤU TRÚC THÔNG TIN VỊ THẾ CHI TIẾT ---
struct PositionInfo {
    ulong           ticket;            // Ticket của vị thế
    ENUM_POSITION_TYPE type;           // Loại vị thế (BUY/SELL)
    double          entryPrice;        // Giá vào lệnh
    double          currentPrice;      // Giá hiện tại
    double          initialSL;         // Stop Loss ban đầu
    double          currentSL;         // Stop Loss hiện tại
    double          initialTP;         // Take Profit ban đầu
    double          currentTP;         // Take Profit hiện tại
    double          initialLots;       // Khối lượng ban đầu
    double          currentLots;       // Khối lượng hiện tại
    datetime        openTime;          // Thời gian mở lệnh
    datetime        lastUpdateTime;    // Thời gian cập nhật cuối
    
    ENUM_ENTRY_SCENARIO scenario;      // Kịch bản vào lệnh
    ENUM_POSITION_STATE state;         // Trạng thái hiện tại của vị thế
    
    double          riskAmount;        // Số tiền rủi ro (theo SL ban đầu)
    double          riskPercent;       // Phần trăm rủi ro
    double          currentR;          // R-multiple hiện tại (lợi nhuận/rủi ro)
    double          unrealizedPnL;     // Lợi nhuận chưa thực hiện
    double          unrealizedPnLPercent; // Lợi nhuận chưa thực hiện (%)
    
    int             holdingBars;       // Số nến đã giữ
    int             partialCloseCount; // Số lần đã đóng một phần
    int             scalingCount;      // Số lần nhồi lệnh
    
    bool            isBreakevenHit;    // Đã đạt breakeven
    bool            isPartial1Done;    // Đã đóng một phần lần 1
    bool            isPartial2Done;    // Đã đóng một phần lần 2
    bool            needsTrailing;     // Cần áp dụng trailing stop
    
    // Thông tin thêm cho đánh giá
    double          qualityScore;      // Điểm chất lượng vị thế (0.0-1.0)
    double          targetR;           // R-multiple mục tiêu
    double          maxR;              // R-multiple cao nhất đã đạt được
    
    PositionInfo() {
        ticket = 0;
        type = POSITION_TYPE_BUY;
        entryPrice = 0;
        currentPrice = 0;
        initialSL = 0;
        currentSL = 0;
        initialTP = 0;
        currentTP = 0;
        initialLots = 0;
        currentLots = 0;
        openTime = 0;
        lastUpdateTime = 0;
        
        scenario = SCENARIO_NONE;
        state = POSITION_STATE_NORMAL;
        
        riskAmount = 0;
        riskPercent = 0;
        currentR = 0;
        unrealizedPnL = 0;
        unrealizedPnLPercent = 0;
        
        holdingBars = 0;
        partialCloseCount = 0;
        scalingCount = 0;
        
        isBreakevenHit = false;
        isPartial1Done = false;
        isPartial2Done = false;
        needsTrailing = false;
        
        qualityScore = 0;
        targetR = 0;
        maxR = 0;
    }
};

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
    double  maxDrawdown;           // Drawdown lớn nhất
    double  successRate;           // Tỷ lệ thành công
    double  profitFactor;          // Profit factor
    ENUM_PORTFOLIO_HEALTH health;  // Sức khỏe danh mục
    
    PortfolioStatus() {
        totalPositions = 0;
        buyPositions = 0;
        sellPositions = 0;
        totalRiskAmount = 0;
        totalRiskPercent = 0;
        totalUnrealizedPnL = 0;
        totalUnrealizedPnLPercent = 0;
        averageR = 0;
        weightedAverageR = 0;
        maxDrawdown = 0;
        successRate = 0;
        profitFactor = 0;
        health = PORTFOLIO_HEALTH_UNKNOWN;
    }
};

// --- ENUM ĐÁNH GIÁ SỨC KHỎE DANH MỤC ---
enum ENUM_PORTFOLIO_HEALTH {
    PORTFOLIO_HEALTH_UNKNOWN,     // Chưa xác định
    PORTFOLIO_HEALTH_EXCELLENT,   // Xuất sắc
    PORTFOLIO_HEALTH_GOOD,        // Tốt
    PORTFOLIO_HEALTH_AVERAGE,     // Trung bình
    PORTFOLIO_HEALTH_WARNING,     // Cảnh báo
    PORTFOLIO_HEALTH_DANGER       // Nguy hiểm
};

//+------------------------------------------------------------------+
//| CPositionManager - Quản lý vị thế ở mức cao                      |
//+------------------------------------------------------------------+
class CPositionManager {
private:
    // Các đối tượng chính
    CLogger*              m_logger;           // Logger để ghi log
    CMarketProfile*       m_marketProfile;    // Thông tin thị trường
    CRiskManager*         m_riskManager;      // Quản lý rủi ro
    CAssetProfiler*       m_assetProfiler;    // Asset Profiler
    CNewsFilter*          m_newsFilter;       // Bộ lọc tin tức
    
    // Thông tin cơ bản
    string                m_symbol;           // Symbol hiện tại
    int                   m_magicNumber;      // Magic number
    int                   m_digits;           // Số chữ số thập phân
    double                m_point;            // Giá trị 1 point
    bool                  m_enableDetailedLogs; // Ghi log chi tiết
    
    // Mảng lưu trữ thông tin vị thế
    CArrayObj             m_positionsInfo;    // Mảng PositionInfo
    
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
    void UpdatePositionInfo(PositionInfo &posInfo);
    
    // Tính toán các giá trị R hiện tại
    double CalculateCurrentR(PositionInfo &posInfo);
    
    // Tính toán lợi nhuận chưa thực hiện
    double CalculateUnrealizedPnL(const PositionInfo &posInfo);
    
    // Cập nhật trạng thái vị thế
    void UpdatePositionState(PositionInfo &posInfo);
    
    // Đánh giá sức khỏe danh mục
    void EvaluatePortfolio();
    
    // Đánh giá từng vị thế
    void EvaluatePosition(PositionInfo &posInfo);
    
    // Kiểm tra nếu vị thế cần được đóng
    bool ShouldClosePosition(const PositionInfo &posInfo);
    
    // Kiểm tra nếu vị thế cần đóng một phần
    bool ShouldPartialClosePosition(const PositionInfo &posInfo, double &percentToClose);
    
    // Kiểm tra nếu vị thế cần BE
    bool ShouldMoveToBreakeven(const PositionInfo &posInfo);
    
    // Đánh giá chất lượng vị thế
    double EvaluatePositionQuality(const PositionInfo &posInfo);
    
    // Tìm vị thế theo ticket
    PositionInfo* FindPositionByTicket(ulong ticket);
    
    // Loại bỏ vị thế đã đóng
    void RemoveClosedPositions();
    
    // Xóa toàn bộ vị thế
    void ClearAllPositions();
    
    // --- HÀM NỘI BỘ: QUẢN LÝ DANH MỤC ---
    
    // Tính toán tổng rủi ro hiện tại
    void CalculateTotalRisk();
    
    // Tính toán R trung bình
    void CalculateAverageR();
    
    // Kiểm tra nếu có quá nhiều vị thế cùng chiều
    bool HasTooManyOneDirectionPositions();
    
    // Kiểm tra nếu có quá nhiều rủi ro từ 1 kịch bản
    bool HasTooMuchRiskFromOneScenario();
    
    // Đánh giá tỷ lệ thắng/thua và profit factor
    void CalculateSuccessRateAndProfitFactor();
    
    // Kiểm tra thời gian giữ vị thế
    void CheckHoldingTime();
    
    // Kiểm tra mối tương quan giữa các vị thế
    void AnalyzePositionCorrelation();
    
    // Đánh giá hiệu quả các vị thế đã đóng gần đây
    void AnalyzeRecentClosedPositions();
    
    // Kiểm tra nếu nên đóng tất cả vị thế
    bool ShouldCloseAllPositions();
    
public:
    // Constructor và Destructor
    CPositionManager();
    ~CPositionManager();
    
    // --- KHỞI TẠO VÀ THIẾT LẬP ---
    
    // Khởi tạo với các module cần thiết
    bool Initialize(string symbol, int magicNumber, CLogger* logger, 
                   CMarketProfile* marketProfile, CRiskManager* riskManager,
                   CAssetProfiler* assetProfiler = NULL, CNewsFilter* newsFilter = NULL);
    
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
    
    // Thêm vị thế mới
    bool AddPosition(ulong ticket, double entryPrice, double stopLoss, 
                   double takeProfit, double lotSize, bool isLong, 
                   ENUM_ENTRY_SCENARIO scenario);
    
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
    bool GetPositionInfo(ulong ticket, PositionInfo &posInfo);
    
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
    
    // Kiểm tra nếu nên đóng tất cả
    bool ShouldCloseAll(string &reason);
    
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
    m_logger = NULL;
    m_marketProfile = NULL;
    m_riskManager = NULL;
    m_assetProfiler = NULL;
    m_newsFilter = NULL;
    
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
    m_logger = NULL;
    m_marketProfile = NULL;
    m_riskManager = NULL;
    m_assetProfiler = NULL;
    m_newsFilter = NULL;
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo PositionManager                           |
//+------------------------------------------------------------------+
bool CPositionManager::Initialize(string symbol, int magicNumber, CLogger* logger, 
                                CMarketProfile* marketProfile, CRiskManager* riskManager,
                                CAssetProfiler* assetProfiler, CNewsFilter* newsFilter)
{
    // Kiểm tra tham số bắt buộc
    if (symbol == "" || magicNumber <= 0 || logger == NULL || 
        marketProfile == NULL || riskManager == NULL) {
        if (logger) {
            logger.LogError("PositionManager::Initialize - Thiếu tham số bắt buộc");
        }
        return false;
    }
    
    // Lưu các tham số và con trỏ
    m_symbol = symbol;
    m_magicNumber = magicNumber;
    m_logger = logger;
    m_marketProfile = marketProfile;
    m_riskManager = riskManager;
    m_assetProfiler = assetProfiler;
    m_newsFilter = newsFilter;
    
    // Lấy thông tin symbol
    m_digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    m_point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Xóa dữ liệu cũ
    ClearAllPositions();
    
    // Log thông tin
    m_logger.LogInfo("PositionManager khởi tạo thành công cho " + symbol + 
                     " với magic " + IntegerToString(magicNumber));
    
    // Cập nhật lần đầu
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
    if (m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo(StringFormat(
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
    if (m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo(StringFormat(
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
    // Cập nhật thời gian
    m_lastUpdateTime = TimeCurrent();
    m_totalUpdates++;
    
    // Đếm số vị thế của symbol và magic number hiện tại
    int totalOpenPositions = 0;
    ulong openTickets[];
    
    // Lấy danh sách các vị thế đang mở
    int total = PositionsTotal();
    
    // Lặp qua từng vị thế
    for (int i = 0; i < total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;
        
        // Kiểm tra symbol và magic number
        if (PositionGetString(POSITION_SYMBOL) == m_symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_magicNumber) {
            
            // Thêm vào danh sách
            totalOpenPositions++;
            ArrayResize(openTickets, totalOpenPositions);
            openTickets[totalOpenPositions - 1] = ticket;
            
            // Kiểm tra nếu vị thế đã có trong danh sách
            PositionInfo* existingPos = FindPositionByTicket(ticket);
            
            if (existingPos == NULL) {
                // Vị thế mới, thêm vào danh sách
                PositionInfo* newPos = new PositionInfo();
                if (newPos == NULL) {
                    m_logger.LogError("PositionManager: Không thể tạo vị thế mới - Lỗi bộ nhớ");
                    continue;
                }
                
                // Lấy thông tin vị thế
                newPos.ticket = ticket;
                newPos.type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                newPos.entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
                newPos.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                newPos.initialSL = PositionGetDouble(POSITION_SL);
                newPos.currentSL = newPos.initialSL;
                newPos.initialTP = PositionGetDouble(POSITION_TP);
                newPos.currentTP = newPos.initialTP;
                newPos.initialLots = PositionGetDouble(POSITION_VOLUME);
                newPos.currentLots = newPos.initialLots;
                newPos.openTime = (datetime)PositionGetInteger(POSITION_TIME);
                newPos.lastUpdateTime = m_lastUpdateTime;
                
                // Lấy thông tin comment để xác định scenario
                string comment = PositionGetString(POSITION_COMMENT);
                newPos.scenario = SCENARIO_NONE;
                
                // Phân tích comment để xác định scenario
                if (StringFind(comment, "PB") >= 0) newPos.scenario = SCENARIO_PULLBACK;
                else if (StringFind(comment, "BO") >= 0) newPos.scenario = SCENARIO_BREAKOUT;
                else if (StringFind(comment, "REV") >= 0) newPos.scenario = SCENARIO_REVERSAL;
                else if (StringFind(comment, "SCALE") >= 0) newPos.scenario = SCENARIO_SCALING;
                
                // Tính toán thông tin thêm
                UpdatePositionInfo(*newPos);
                
                // Thêm vào danh sách
                m_positionsInfo.Add(newPos);
                
                if (m_logger && m_enableDetailedLogs) {
                    m_logger.LogInfo(StringFormat(
                        "PositionManager: Thêm vị thế mới #%d - %s, Entry: %.5f, SL: %.5f, TP: %.5f, Lots: %.2f",
                        newPos.ticket,
                        newPos.type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                        newPos.entryPrice,
                        newPos.initialSL,
                        newPos.initialTP,
                        newPos.initialLots
                    ));
                }
            } else {
                // Vị thế đã có, cập nhật thông tin
                existingPos.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
                existingPos.currentSL = PositionGetDouble(POSITION_SL);
                existingPos.currentTP = PositionGetDouble(POSITION_TP);
                existingPos.currentLots = PositionGetDouble(POSITION_VOLUME);
                existingPos.lastUpdateTime = m_lastUpdateTime;
                
                // Cập nhật thông tin thêm
                UpdatePositionInfo(*existingPos);
            }
        }
    }
    
    // Loại bỏ vị thế đã đóng
    RemoveClosedPositions();
    
    // Cập nhật thông tin danh mục
    m_portfolioStatus.totalPositions = m_positionsInfo.Total();
    m_portfolioStatus.buyPositions = 0;
    m_portfolioStatus.sellPositions = 0;
    
    // Đếm số vị thế mua/bán
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos != NULL) {
            if (pos.type == POSITION_TYPE_BUY) {
                m_portfolioStatus.buyPositions++;
            } else {
                m_portfolioStatus.sellPositions++;
            }
        }
    }
    
    // Tính toán các thông tin tổng hợp
    CalculateTotalRisk();
    CalculateAverageR();
    
    // Đánh giá danh mục
    EvaluatePortfolio();
    
    if (m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo(StringFormat(
            "PositionManager: Cập nhật %d vị thế - Long: %d, Short: %d, Risk: %.2f%%, Avg R: %.2f",
            m_portfolioStatus.totalPositions,
            m_portfolioStatus.buyPositions,
            m_portfolioStatus.sellPositions,
            m_portfolioStatus.totalRiskPercent,
            m_portfolioStatus.averageR
        ));
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionInfo - Cập nhật thông tin chi tiết của vị thế      |
//+------------------------------------------------------------------+
void CPositionManager::UpdatePositionInfo(PositionInfo &posInfo)
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
        if (m_assetProfiler != NULL) {
            double assetTargetR = m_assetProfiler.GetOptimalRMultiple();
            if (assetTargetR > 0) {
                posInfo.targetR = assetTargetR;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateCurrentR - Tính R-multiple hiện tại                     |
//+------------------------------------------------------------------+
double CPositionManager::CalculateCurrentR(PositionInfo &posInfo)
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
//| CalculateUnrealizedPnL - Tính lợi nhuận chưa thực hiện           |
//+------------------------------------------------------------------+
double CPositionManager::CalculateUnrealizedPnL(const PositionInfo &posInfo)
{
    // Lấy thông tin symbol
    double tickValue = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    double tickSize = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    double pointValue = tickValue * (m_point / tickSize);
    
    // Tính lợi nhuận
    double pnl = 0;
    
    if (posInfo.type == POSITION_TYPE_BUY) {
        // Lệnh buy: PnL = (CurrentPrice - EntryPrice) * PointValue * Lots
        pnl = (posInfo.currentPrice - posInfo.entryPrice) / m_point * pointValue * posInfo.currentLots;
    } else {
        // Lệnh sell: PnL = (EntryPrice - CurrentPrice) * PointValue * Lots
        pnl = (posInfo.entryPrice - posInfo.currentPrice) / m_point * pointValue * posInfo.currentLots;
    }
    
    return pnl;
}

//+------------------------------------------------------------------+
//| UpdatePositionState - Cập nhật trạng thái vị thế                 |
//+------------------------------------------------------------------+
void CPositionManager::UpdatePositionState(PositionInfo &posInfo)
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
                
                if (m_logger && m_enableDetailedLogs) {
                    m_logger.LogInfo(StringFormat(
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
            
            if (m_logger && m_enableDetailedLogs) {
                m_logger.LogInfo(StringFormat(
                    "PositionManager: Vị thế #%d đã đóng một phần lần 1 - R: %.2f",
                    posInfo.ticket, posInfo.currentR
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
            
            if (m_logger && m_enableDetailedLogs) {
                m_logger.LogInfo(StringFormat(
                    "PositionManager: Vị thế #%d đã đóng một phần lần 2 - R: %.2f",
                    posInfo.ticket, posInfo.currentR
                ));
            }
        }
    }
    
    // Kiểm tra cần trailing
    double atr = 0;
    if (m_marketProfile != NULL) {
        atr = m_marketProfile.GetATR();
    } else if (m_assetProfiler != NULL) {
        atr = m_assetProfiler.GetATR();
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
        
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Vị thế #%d đã giữ quá lâu - %d nến > %d nến",
                posInfo.ticket, posInfo.holdingBars, m_maxHoldingTime
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| EvaluatePositionQuality - Đánh giá chất lượng vị thế             |
//+------------------------------------------------------------------+
double CPositionManager::EvaluatePositionQuality(const PositionInfo &posInfo)
{
    // Điểm cơ bản: 50/100
    double score = 50.0;
    
    // Đánh giá dựa trên R hiện tại
    if (posInfo.currentR >= 2.0) score += 20.0;
    else if (posInfo.currentR >= 1.0) score += 10.0;
    else if (posInfo.currentR <= -0.5) score -= 20.0;
    
    // Đánh giá dựa trên thời gian giữ
    if (posInfo.holdingBars > m_maxHoldingTime) {
        score -= 15.0;
    } else if (posInfo.holdingBars > m_maxHoldingTime * 0.7) {
        score -= 5.0;
    }
    
    // Đánh giá dựa trên breakeven
    if (posInfo.isBreakevenHit) {
        score += 10.0;
    }
    
    // Đánh giá dựa trên đóng một phần
    if (posInfo.isPartial1Done) {
        score += 5.0;
    }
    
    if (posInfo.isPartial2Done) {
        score += 5.0;
    }
    
    // Đánh giá dựa trên regime (nếu có)
    if (m_marketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        
        // Kiểm tra sự phù hợp giữa regime và loại vị thế
        if (posInfo.type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BULL) {
            score += 10.0;
        } else if (posInfo.type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BEAR) {
            score += 10.0;
        } else if (regime == REGIME_VOLATILE) {
            score -= 5.0;
        }
    }
    
    // Đảm bảo điểm trong khoảng 0-100
    score = MathMax(0.0, MathMin(100.0, score));
    
    // Chuyển sang khoảng 0.0-1.0
    return score / 100.0;
}

//+------------------------------------------------------------------+
//| FindPositionByTicket - Tìm vị thế theo ticket                    |
//+------------------------------------------------------------------+
PositionInfo* CPositionManager::FindPositionByTicket(ulong ticket)
{
    // Tìm vị thế trong danh sách
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos != NULL && pos.ticket == ticket) {
            return pos;
        }
    }
    
    return NULL;
}

//+------------------------------------------------------------------+
//| RemoveClosedPositions - Loại bỏ vị thế đã đóng                  |
//+------------------------------------------------------------------+
void CPositionManager::RemoveClosedPositions()
{
    // Kiểm tra từng vị thế
    for (int i = m_positionsInfo.Total() - 1; i >= 0; i--) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Kiểm tra vị thế có còn tồn tại
        bool stillExists = false;
        
        if (PositionSelectByTicket(pos.ticket)) {
            stillExists = true;
        }
        
        if (!stillExists) {
            // Vị thế đã đóng, loại bỏ khỏi danh sách
            if (m_logger && m_enableDetailedLogs) {
                m_logger.LogInfo(StringFormat(
                    "PositionManager: Loại bỏ vị thế đã đóng #%d",
                    pos.ticket
                ));
            }
            
            // Cập nhật thống kê
            m_closedPositions++;
            
            // Tính lợi nhuận
            double profit = CalculateUnrealizedPnL(*pos);
            
            if (profit > 0) {
                m_winPositions++;
                m_totalProfit += profit;
            } else if (profit < 0) {
                m_losePositions++;
                m_totalLoss += MathAbs(profit);
            }
            
            // Xóa khỏi danh sách
            m_positionsInfo.Delete(i);
        }
    }
}

//+------------------------------------------------------------------+
//| ClearAllPositions - Xóa toàn bộ vị thế                          |
//+------------------------------------------------------------------+
void CPositionManager::ClearAllPositions()
{
    // Xóa tất cả vị thế
    for (int i = m_positionsInfo.Total() - 1; i >= 0; i--) {
        m_positionsInfo.Delete(i);
    }
    
    m_positionsInfo.Clear();
    
    if (m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo("PositionManager: Đã xóa tất cả thông tin vị thế");
    }
}

//+------------------------------------------------------------------+
//| CalculateTotalRisk - Tính tổng rủi ro hiện tại                   |
//+------------------------------------------------------------------+
void CPositionManager::CalculateTotalRisk()
{
    // Reset giá trị
    m_portfolioStatus.totalRiskAmount = 0;
    m_portfolioStatus.totalRiskPercent = 0;
    m_portfolioStatus.totalUnrealizedPnL = 0;
    m_portfolioStatus.totalUnrealizedPnLPercent = 0;
    
    // Tính tổng từng vị thế
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Cộng vào tổng
        m_portfolioStatus.totalRiskAmount += pos.riskAmount;
        m_portfolioStatus.totalRiskPercent += pos.riskPercent;
        m_portfolioStatus.totalUnrealizedPnL += pos.unrealizedPnL;
        
        // Kiểm tra BEP
        if (pos.isBreakevenHit) {
            // Nếu đã đạt BE, rủi ro giảm về 0
            m_portfolioStatus.totalRiskAmount -= pos.riskAmount;
            m_portfolioStatus.totalRiskPercent -= pos.riskPercent;
        }
        // Kiểm tra đóng một phần
        else if (pos.isPartial1Done) {
            // Giảm rủi ro theo phần đã đóng
            double partialFactor = pos.currentLots / pos.initialLots;
            m_portfolioStatus.totalRiskAmount -= pos.riskAmount * (1 - partialFactor);
            m_portfolioStatus.totalRiskPercent -= pos.riskPercent * (1 - partialFactor);
        }
    }
    
    // Tính % lợi nhuận
    double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
    if (accountBalance > 0) {
        m_portfolioStatus.totalUnrealizedPnLPercent = m_portfolioStatus.totalUnrealizedPnL / accountBalance * 100.0;
    }
}

//+------------------------------------------------------------------+
//| CalculateAverageR - Tính R trung bình                            |
//+------------------------------------------------------------------+
void CPositionManager::CalculateAverageR()
{
    // Reset giá trị
    m_portfolioStatus.averageR = 0;
    m_portfolioStatus.weightedAverageR = 0;
    
    // Kiểm tra nếu không có vị thế
    if (m_positionsInfo.Total() == 0) {
        return;
    }
    
    // Tính tổng R và tổng trọng số
    double totalR = 0;
    double totalWeightedR = 0;
    double totalWeight = 0;
    
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Cộng vào tổng
        totalR += pos.currentR;
        
        // Tính trọng số (dựa trên rủi ro)
        double weight = pos.riskPercent;
        totalWeightedR += pos.currentR * weight;
        totalWeight += weight;
    }
    
    // Tính trung bình
    m_portfolioStatus.averageR = totalR / m_positionsInfo.Total();
    
    // Tính trung bình có trọng số
    if (totalWeight > 0) {
        m_portfolioStatus.weightedAverageR = totalWeightedR / totalWeight;
    }
}

//+------------------------------------------------------------------+
//| HasTooManyOneDirectionPositions - Kiểm tra quá nhiều vị thế cùng chiều |
//+------------------------------------------------------------------+
bool CPositionManager::HasTooManyOneDirectionPositions()
{
    // Kiểm tra số vị thế buy
    if (m_portfolioStatus.buyPositions > m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều vị thế BUY - %d > %d",
                m_portfolioStatus.buyPositions, m_maxPositionsPerDirection
            ));
        }
        return true;
    }
    
    // Kiểm tra số vị thế sell
    if (m_portfolioStatus.sellPositions > m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều vị thế SELL - %d > %d",
                m_portfolioStatus.sellPositions, m_maxPositionsPerDirection
            ));
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| HasTooMuchRiskFromOneScenario - Kiểm tra quá nhiều rủi ro từ 1 kịch bản |
//+------------------------------------------------------------------+
bool CPositionManager::HasTooMuchRiskFromOneScenario()
{
    // Tính rủi ro theo từng kịch bản
    double riskPullback = 0;
    double riskBreakout = 0;
    double riskReversal = 0;
    double riskScaling = 0;
    
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Tính rủi ro hiệu chỉnh
        double adjustedRisk = pos.riskPercent;
        
        // Nếu đạt BE hoặc TP1, giảm rủi ro
        if (pos.isBreakevenHit) {
            adjustedRisk = 0;
        } else if (pos.isPartial1Done) {
            adjustedRisk *= pos.currentLots / pos.initialLots;
        }
        
        // Cộng vào tổng theo kịch bản
        switch (pos.scenario) {
            case SCENARIO_PULLBACK: riskPullback += adjustedRisk; break;
            case SCENARIO_BREAKOUT: riskBreakout += adjustedRisk; break;
            case SCENARIO_REVERSAL: riskReversal += adjustedRisk; break;
            case SCENARIO_SCALING: riskScaling += adjustedRisk; break;
            default: break;
        }
    }
    
    // Kiểm tra ngưỡng tối đa cho mỗi kịch bản (50% tổng rủi ro tối đa)
    double maxScenarioRisk = m_maxTotalRisk * 0.5;
    
    if (riskPullback > maxScenarioRisk) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều rủi ro từ Pullback - %.2f%% > %.2f%%",
                riskPullback, maxScenarioRisk
            ));
        }
        return true;
    }
    
    if (riskBreakout > maxScenarioRisk) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều rủi ro từ Breakout - %.2f%% > %.2f%%",
                riskBreakout, maxScenarioRisk
            ));
        }
        return true;
    }
    
    if (riskReversal > maxScenarioRisk) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều rủi ro từ Reversal - %.2f%% > %.2f%%",
                riskReversal, maxScenarioRisk
            ));
        }
        return true;
    }
    
    if (riskScaling > maxScenarioRisk) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều rủi ro từ Scaling - %.2f%% > %.2f%%",
                riskScaling, maxScenarioRisk
            ));
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| CalculateSuccessRateAndProfitFactor - Tính tỷ lệ thắng và PF     |
//+------------------------------------------------------------------+
void CPositionManager::CalculateSuccessRateAndProfitFactor()
{
    // Tính tỷ lệ thành công
    if (m_closedPositions > 0) {
        m_portfolioStatus.successRate = (double)m_winPositions / m_closedPositions * 100.0;
    } else {
        m_portfolioStatus.successRate = 0;
    }
    
    // Tính profit factor
    if (m_totalLoss > 0) {
        m_portfolioStatus.profitFactor = m_totalProfit / m_totalLoss;
    } else if (m_totalProfit > 0) {
        m_portfolioStatus.profitFactor = 100; // Giá trị lớn nếu không có lỗ
    } else {
        m_portfolioStatus.profitFactor = 0;
    }
}

//+------------------------------------------------------------------+
//| CheckHoldingTime - Kiểm tra thời gian giữ vị thế                 |
//+------------------------------------------------------------------+
void CPositionManager::CheckHoldingTime()
{
    // Kiểm tra từng vị thế
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Kiểm tra thời gian giữ
        if (pos.holdingBars > m_maxHoldingTime) {
            if (m_logger) {
                m_logger.LogWarning(StringFormat(
                    "PositionManager: Vị thế #%d đã giữ quá lâu - %d nến > %d nến",
                    pos.ticket, pos.holdingBars, m_maxHoldingTime
                ));
            }
            
            // Đánh dấu cần xem xét
            pos.state = POSITION_STATE_WARNING;
        }
    }
}

//+------------------------------------------------------------------+
//| AnalyzePositionCorrelation - Phân tích tương quan giữa các vị thế |
//+------------------------------------------------------------------+
void CPositionManager::AnalyzePositionCorrelation()
{
    // Phân tích tương quan dựa trên loại vị thế và kịch bản
    int buyPullback = 0, buyBreakout = 0, buyReversal = 0, buyScaling = 0;
    int sellPullback = 0, sellBreakout = 0, sellReversal = 0, sellScaling = 0;
    
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos == NULL) continue;
        
        // Đếm theo loại và kịch bản
        if (pos.type == POSITION_TYPE_BUY) {
            switch (pos.scenario) {
                case SCENARIO_PULLBACK: buyPullback++; break;
                case SCENARIO_BREAKOUT: buyBreakout++; break;
                case SCENARIO_REVERSAL: buyReversal++; break;
                case SCENARIO_SCALING: buyScaling++; break;
                default: break;
            }
        } else {
            switch (pos.scenario) {
                case SCENARIO_PULLBACK: sellPullback++; break;
                case SCENARIO_BREAKOUT: sellBreakout++; break;
                case SCENARIO_REVERSAL: sellReversal++; break;
                case SCENARIO_SCALING: sellScaling++; break;
                default: break;
            }
        }
    }
    
    // Kiểm tra nếu có quá nhiều vị thế cùng loại và kịch bản
    if (buyPullback >= 2 || sellPullback >= 2) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Nhiều vị thế Pullback - Buy: %d, Sell: %d",
                buyPullback, sellPullback
            ));
        }
    }
    
    if (buyBreakout >= 2 || sellBreakout >= 2) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Nhiều vị thế Breakout - Buy: %d, Sell: %d",
                buyBreakout, sellBreakout
            ));
        }
    }
    
    if (buyScaling >= 2 || sellScaling >= 2) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Nhiều vị thế Scaling - Buy: %d, Sell: %d",
                buyScaling, sellScaling
            ));
        }
    }
    
    // Kiểm tra nếu có quá nhiều vị thế của cùng một chiều
    if (m_portfolioStatus.buyPositions > m_maxPositionsPerDirection ||
        m_portfolioStatus.sellPositions > m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Quá nhiều vị thế cùng chiều - Buy: %d, Sell: %d, Tối đa: %d",
                m_portfolioStatus.buyPositions, m_portfolioStatus.sellPositions, m_maxPositionsPerDirection
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| AnalyzeRecentClosedPositions - Phân tích hiệu suất gần đây       |
//+------------------------------------------------------------------+
void CPositionManager::AnalyzeRecentClosedPositions()
{
    // Tính tỷ lệ thắng và profit factor
    CalculateSuccessRateAndProfitFactor();
    
    // Cảnh báo nếu tỷ lệ thành công quá thấp
    if (m_closedPositions >= 10 && m_portfolioStatus.successRate < 40.0) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Tỷ lệ thành công thấp - %.1f%% (Win: %d, Lose: %d)",
                m_portfolioStatus.successRate, m_winPositions, m_losePositions
            ));
        }
    }
    
    // Cảnh báo nếu profit factor quá thấp
    if (m_closedPositions >= 10 && m_portfolioStatus.profitFactor < 1.0) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Profit Factor thấp - %.2f",
                m_portfolioStatus.profitFactor
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| ShouldCloseAllPositions - Kiểm tra nếu nên đóng tất cả vị thế    |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldCloseAllPositions()
{
    // Kiểm tra drawdown
    double maxDrawDown = 0;
    
    if (m_riskManager != NULL) {
        maxDrawDown = m_riskManager.GetMaximumDrawdown();
    } else {
        // Nếu không có RiskManager, tính thủ công
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        
        if (balance > 0) {
            maxDrawDown = (balance - equity) / balance * 100.0;
        }
    }
    
    // Kiểm tra nếu drawdown vượt ngưỡng
    if (maxDrawDown > m_maxDrawdown) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Drawdown vượt ngưỡng - %.2f%% > %.2f%%",
                maxDrawDown, m_maxDrawdown
            ));
        }
        return true;
    }
    
    // Kiểm tra tổng lỗ
    double unrealizedPnL = m_portfolioStatus.totalUnrealizedPnL;
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    if (unrealizedPnL < 0 && MathAbs(unrealizedPnL) / equity * 100.0 > m_maxLossPercent) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Tổng lỗ vượt ngưỡng - %.2f%% > %.2f%%",
                MathAbs(unrealizedPnL) / equity * 100.0, m_maxLossPercent
            ));
        }
        return true;
    }
    
    // Kiểm tra tin tức
    if (m_newsFilter != NULL && m_newsFilter.HasHighImpactNews()) {
        if (m_logger) {
            m_logger.LogWarning("PositionManager: Có tin tức quan trọng sắp diễn ra");
        }
        return true;
    }
    
    // Kiểm tra thị trường bất thường
    if (m_marketProfile != NULL && m_marketProfile.IsExtremeVolatility()) {
        if (m_logger) {
            m_logger.LogWarning("PositionManager: Thị trường biến động cực kỳ cao");
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| EvaluatePortfolio - Đánh giá sức khỏe danh mục                   |
//+------------------------------------------------------------------+
void CPositionManager::EvaluatePortfolio()
{
    // Đánh giá từng vị thế
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos != NULL) {
            EvaluatePosition(*pos);
        }
    }
    
    // Phân tích tương quan
    AnalyzePositionCorrelation();
    
    // Kiểm tra thời gian giữ
    CheckHoldingTime();
    
    // Phân tích hiệu suất gần đây
    AnalyzeRecentClosedPositions();
    
    // Đánh giá sức khỏe tổng thể
    m_portfolioStatus.health = PORTFOLIO_HEALTH_GOOD; // Mặc định
    
    // Kiểm tra các điều kiện mức "Excellent"
    if (m_portfolioStatus.averageR > 1.0 && 
        m_portfolioStatus.successRate >= 60.0 && 
        m_portfolioStatus.profitFactor >= 2.0) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_EXCELLENT;
    }
    // Kiểm tra các điều kiện mức "Warning"
    else if (m_portfolioStatus.averageR < 0 || 
             m_portfolioStatus.totalUnrealizedPnL < 0 || 
             m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.8) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_WARNING;
    }
    // Kiểm tra các điều kiện mức "Danger"
    else if (m_portfolioStatus.averageR < -0.5 || 
             m_portfolioStatus.totalUnrealizedPnLPercent < -3.0 || 
             m_portfolioStatus.totalRiskPercent > m_maxTotalRisk) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_DANGER;
    }
    // Các trường hợp còn lại: Average hoặc Good
    else if (m_portfolioStatus.averageR > 0.5 && m_portfolioStatus.profitFactor >= 1.5) {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_GOOD;
    } else {
        m_portfolioStatus.health = PORTFOLIO_HEALTH_AVERAGE;
    }
    
    // Log thông tin
    if (m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo(StringFormat(
            "PositionManager: Đánh giá danh mục - Sức khỏe: %s, Avg R: %.2f, PnL: %.2f%%, Risk: %.2f%%",
            EnumToString(m_portfolioStatus.health),
            m_portfolioStatus.averageR,
            m_portfolioStatus.totalUnrealizedPnLPercent,
            m_portfolioStatus.totalRiskPercent
        ));
    }
}

//+------------------------------------------------------------------+
//| EvaluatePosition - Đánh giá từng vị thế                          |
//+------------------------------------------------------------------+
void CPositionManager::EvaluatePosition(PositionInfo &posInfo)
{
    // Kiểm tra các điều kiện đóng lệnh
    bool shouldClose = ShouldClosePosition(posInfo);
    
    if (shouldClose && m_enableAutoClose) {
        string reason = "";
        
        if (posInfo.currentR <= -0.8) {
            reason = "Stop Loss gần chạm";
        } else if (posInfo.holdingBars > m_maxHoldingTime * 1.5) {
            reason = "Giữ quá lâu";
        } else if (posInfo.currentR >= posInfo.targetR) {
            reason = "Đạt mục tiêu";
        }
        
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Đề xuất đóng vị thế #%d - %s",
                posInfo.ticket, reason
            ));
        }
    }
    
    // Kiểm tra nếu cần đóng một phần
    double percentToClose = 0;
    bool shouldPartialClose = ShouldPartialClosePosition(posInfo, percentToClose);
    
    if (shouldPartialClose) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Đề xuất đóng một phần vị thế #%d - %.1f%%",
                posInfo.ticket, percentToClose
            ));
        }
    }
    
    // Kiểm tra nếu cần đưa về breakeven
    bool shouldMoveToBreakeven = ShouldMoveToBreakeven(posInfo);
    
    if (shouldMoveToBreakeven) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Đề xuất đưa vị thế #%d về breakeven",
                posInfo.ticket
            ));
        }
    }
}

//+------------------------------------------------------------------+
//| ShouldClosePosition - Kiểm tra nếu vị thế cần được đóng          |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldClosePosition(const PositionInfo &posInfo)
{
    // Kiểm tra R âm lớn
    if (posInfo.currentR <= -0.8) {
        return true;
    }
    
    // Kiểm tra thời gian giữ quá lâu
    if (posInfo.holdingBars > m_maxHoldingTime * 1.5) {
        return true;
    }
    
    // Kiểm tra đạt mục tiêu
    if (posInfo.currentR >= posInfo.targetR) {
        return true;
    }
    
    // Kiểm tra Market Regime không phù hợp (nếu có MarketProfile)
    if (m_marketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        
        // Kiểm tra xung đột giữa regime và vị thế
        if ((posInfo.type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BEAR) ||
            (posInfo.type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BULL)) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ShouldPartialClosePosition - Kiểm tra nếu vị thế cần đóng một phần |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldPartialClosePosition(const PositionInfo &posInfo, double &percentToClose)
{
    // Mặc định
    percentToClose = 0;
    
    // Kiểm tra lần đóng 1
    if (!posInfo.isPartial1Done && posInfo.currentR >= m_partialCloseR1) {
        percentToClose = m_partialClosePercent1;
        return true;
    }
    
    // Kiểm tra lần đóng 2
    if (posInfo.isPartial1Done && !posInfo.isPartial2Done && posInfo.currentR >= m_partialCloseR2) {
        percentToClose = m_partialClosePercent2;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ShouldMoveToBreakeven - Kiểm tra nếu vị thế cần BE               |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldMoveToBreakeven(const PositionInfo &posInfo)
{
    // Kiểm tra nếu đã đạt BE
    if (posInfo.isBreakevenHit) {
        return false;
    }
    
    // Kiểm tra điều kiện BE
    if (posInfo.currentR >= m_breakEvenAfterR) {
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| AddPosition - Thêm vị thế mới                                    |
//+------------------------------------------------------------------+
bool CPositionManager::AddPosition(ulong ticket, double entryPrice, double stopLoss, 
                                 double takeProfit, double lotSize, bool isLong, 
                                 ENUM_ENTRY_SCENARIO scenario)
{
    // Kiểm tra nếu vị thế đã tồn tại
    if (FindPositionByTicket(ticket) != NULL) {
        if (m_logger && m_enableDetailedLogs) {
            m_logger.LogInfo(StringFormat(
                "PositionManager: Vị thế #%d đã tồn tại",
                ticket
            ));
        }
        return false;
    }
    
    // Tạo vị thế mới
    PositionInfo* newPos = new PositionInfo();
    if (newPos == NULL) {
        m_logger.LogError("PositionManager: Không thể tạo vị thế mới - Lỗi bộ nhớ");
        return false;
    }
    
    // Lấy thông tin vị thế
    newPos.ticket = ticket;
    newPos.type = isLong ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
    newPos.entryPrice = entryPrice;
    newPos.currentPrice = entryPrice;
    newPos.initialSL = stopLoss;
    newPos.currentSL = stopLoss;
    newPos.initialTP = takeProfit;
    newPos.currentTP = takeProfit;
    newPos.initialLots = lotSize;
    newPos.currentLots = lotSize;
    newPos.openTime = TimeCurrent();
    newPos.lastUpdateTime = newPos.openTime;
    newPos.scenario = scenario;
    
    // Cập nhật thông tin thêm
    UpdatePositionInfo(*newPos);
    
    // Thêm vào danh sách
    m_positionsInfo.Add(newPos);
    
    // Cập nhật thông tin danh mục
    UpdateAllPositions();
    
    if (m_logger) {
        m_logger.LogInfo(StringFormat(
            "PositionManager: Thêm vị thế mới #%d - %s, Entry: %.5f, SL: %.5f, TP: %.5f, Lots: %.2f",
            newPos.ticket,
            newPos.type == POSITION_TYPE_BUY ? "BUY" : "SELL",
            newPos.entryPrice,
            newPos.initialSL,
            newPos.initialTP,
            newPos.initialLots
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdatePosition - Cập nhật thông tin vị thế có sẵn                |
//+------------------------------------------------------------------+
bool CPositionManager::UpdatePosition(ulong ticket, double newSL, double newTP)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Không tìm thấy vị thế #%d",
                ticket
            ));
        }
        return false;
    }
    
    // Cập nhật thông tin
    bool updated = false;
    
    // Cập nhật SL nếu cần
    if (newSL > 0 && newSL != pos.currentSL) {
        pos.currentSL = newSL;
        updated = true;
    }
    
    // Cập nhật TP nếu cần
    if (newTP > 0 && newTP != pos.currentTP) {
        pos.currentTP = newTP;
        updated = true;
    }
    
    // Kiểm tra vị thế trên sàn
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Cập nhật thông tin khác
    pos.currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    pos.currentLots = PositionGetDouble(POSITION_VOLUME);
    pos.lastUpdateTime = TimeCurrent();
    
    // Cập nhật thông tin thêm
    UpdatePositionInfo(*pos);
    
    if (updated && m_logger && m_enableDetailedLogs) {
        m_logger.LogInfo(StringFormat(
            "PositionManager: Cập nhật vị thế #%d - SL: %.5f, TP: %.5f",
            ticket, pos.currentSL, pos.currentTP
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| RemovePosition - Xóa vị thế (khi đã đóng)                        |
//+------------------------------------------------------------------+
bool CPositionManager::RemovePosition(ulong ticket)
{
    // Tìm vị thế
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos != NULL && pos.ticket == ticket) {
            // Cập nhật thống kê
            m_closedPositions++;
            
            // Tính lợi nhuận
            double profit = CalculateUnrealizedPnL(*pos);
            
            if (profit > 0) {
                m_winPositions++;
                m_totalProfit += profit;
            } else if (profit < 0) {
                m_losePositions++;
                m_totalLoss += MathAbs(profit);
            }
            
            // Xóa khỏi danh sách
            m_positionsInfo.Delete(i);
            
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "PositionManager: Xóa vị thế #%d",
                    ticket
                ));
            }
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| EvaluateAllPositions - Đánh giá toàn bộ danh mục                 |
//+------------------------------------------------------------------+
void CPositionManager::EvaluateAllPositions()
{
    // Cập nhật thông tin
    UpdateAllPositions();
    
    // Đánh giá danh mục
    EvaluatePortfolio();
}

//+------------------------------------------------------------------+
//| GetAllPositions - Lấy danh sách tất cả vị thế                    |
//+------------------------------------------------------------------+
int CPositionManager::GetAllPositions(ulong &tickets[])
{
    // Xóa mảng cũ
    ArrayFree(tickets);
    
    // Kiểm tra nếu không có vị thế
    if (m_positionsInfo.Total() == 0) {
        return 0;
    }
    
    // Tạo mảng mới
    ArrayResize(tickets, m_positionsInfo.Total());
    
    // Lưu các ticket
    for (int i = 0; i < m_positionsInfo.Total(); i++) {
        PositionInfo* pos = m_positionsInfo.At(i);
        if (pos != NULL) {
            tickets[i] = pos.ticket;
        }
    }
    
    return m_positionsInfo.Total();
}

//+------------------------------------------------------------------+
//| GetPositionInfo - Lấy thông tin của một vị thế                   |
//+------------------------------------------------------------------+
bool CPositionManager::GetPositionInfo(ulong ticket, PositionInfo &posInfo)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        return false;
    }
    
    // Sao chép thông tin
    posInfo = *pos;
    
    return true;
}

//+------------------------------------------------------------------+
//| CanOpenNewPosition - Kiểm tra nếu có thể mở vị thế mới           |
//+------------------------------------------------------------------+
bool CPositionManager::CanOpenNewPosition(ENUM_POSITION_TYPE type)
{
    // Kiểm tra số lượng vị thế
    if (m_portfolioStatus.totalPositions >= m_maxPositions) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Đã đạt giới hạn số vị thế - %d >= %d",
                m_portfolioStatus.totalPositions, m_maxPositions
            ));
        }
        return false;
    }
    
    // Kiểm tra số lượng vị thế theo chiều
    if (type == POSITION_TYPE_BUY && m_portfolioStatus.buyPositions >= m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Đã đạt giới hạn số vị thế BUY - %d >= %d",
                m_portfolioStatus.buyPositions, m_maxPositionsPerDirection
            ));
        }
        return false;
    }
    
    if (type == POSITION_TYPE_SELL && m_portfolioStatus.sellPositions >= m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Đã đạt giới hạn số vị thế SELL - %d >= %d",
                m_portfolioStatus.sellPositions, m_maxPositionsPerDirection
            ));
        }
        return false;
    }
    
    // Kiểm tra tổng rủi ro
    if (m_portfolioStatus.totalRiskPercent >= m_maxTotalRisk) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Đã đạt giới hạn tổng rủi ro - %.2f%% >= %.2f%%",
                m_portfolioStatus.totalRiskPercent, m_maxTotalRisk
            ));
        }
        return false;
    }
    
    // Kiểm tra nếu nên đóng tất cả
    string reason = "";
    if (ShouldCloseAll(reason)) {
        if (m_logger) {
            m_logger.LogWarning(StringFormat(
                "PositionManager: Không mở vị thế mới - %s",
                reason
            ));
        }
        return false;
    }
    
    // Kiểm tra thị trường (nếu có MarketProfile)
    if (m_marketProfile != NULL) {
        // Kiểm tra biến động cực cao
        if (m_marketProfile.IsExtremeVolatility()) {
            if (m_logger) {
                m_logger.LogWarning("PositionManager: Không mở vị thế mới - Biến động cực cao");
            }
            return false;
        }
        
        // Kiểm tra thị trường sideway
        if (m_marketProfile.IsSidewaysMarket()) {
            if (m_logger) {
                m_logger.LogWarning("PositionManager: Không mở vị thế mới - Thị trường sideway");
            }
            return false;
        }
        
        // Kiểm tra xung đột với xu hướng
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        if ((type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BEAR) ||
            (type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BULL)) {
            if (m_logger) {
                m_logger.LogWarning("PositionManager: Không mở vị thế mới - Xung đột với xu hướng");
            }
            return false;
        }
    }
    
    // Kiểm tra tin tức (nếu có NewsFilter)
    if (m_newsFilter != NULL) {
        if (m_newsFilter.HasUpcomingNews()) {
            if (m_logger) {
                m_logger.LogWarning("PositionManager: Không mở vị thế mới - Có tin tức sắp diễn ra");
            }
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| IsScalingAllowed - Kiểm tra nếu có thể nhồi lệnh                 |
//+------------------------------------------------------------------+
bool CPositionManager::IsScalingAllowed(ulong ticket)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        return false;
    }
    
    // Kiểm tra nếu đã đạt breakeven
    if (!pos.isBreakevenHit) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Chưa đạt breakeven");
        }
        return false;
    }
    
    // Kiểm tra nếu đã đóng TP1
    if (!pos.isPartial1Done) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Chưa đóng một phần lần 1");
        }
        return false;
    }
    
    // Kiểm tra số lượng vị thế
    if (m_portfolioStatus.totalPositions >= m_maxPositions) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Đã đạt giới hạn số vị thế");
        }
        return false;
    }
    
    // Kiểm tra số lượng vị thế theo chiều
    if (pos.type == POSITION_TYPE_BUY && m_portfolioStatus.buyPositions >= m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Đã đạt giới hạn số vị thế BUY");
        }
        return false;
    }
    
    if (pos.type == POSITION_TYPE_SELL && m_portfolioStatus.sellPositions >= m_maxPositionsPerDirection) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Đã đạt giới hạn số vị thế SELL");
        }
        return false;
    }
    
    // Kiểm tra rủi ro
    if (m_portfolioStatus.totalRiskPercent > m_maxTotalRisk * 0.8) {
        if (m_logger) {
            m_logger.LogInfo("PositionManager: Không nhồi lệnh - Rủi ro gần ngưỡng tối đa");
        }
        return false;
    }
    
    // Kiểm tra Market Regime phù hợp (nếu có MarketProfile)
    if (m_marketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        
        // Chỉ nhồi lệnh trong xu hướng mạnh
        if (regime != REGIME_TRENDING_BULL && regime != REGIME_TRENDING_BEAR) {
            if (m_logger) {
                m_logger.LogInfo("PositionManager: Không nhồi lệnh - Không phải xu hướng mạnh");
            }
            return false;
        }
        
        // Kiểm tra xung đột với xu hướng
        if ((pos.type == POSITION_TYPE_BUY && regime == REGIME_TRENDING_BEAR) ||
            (pos.type == POSITION_TYPE_SELL && regime == REGIME_TRENDING_BULL)) {
            if (m_logger) {
                m_logger.LogInfo("PositionManager: Không nhồi lệnh - Xung đột với xu hướng");
            }
            return false;
        }
    }
    
    // Kiểm tra tin tức (nếu có NewsFilter)
    if (m_newsFilter != NULL) {
        if (m_newsFilter.HasUpcomingNews()) {
            if (m_logger) {
                m_logger.LogInfo("PositionManager: Không nhồi lệnh - Có tin tức sắp diễn ra");
            }
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ShouldPartialClose - Kiểm tra nếu nên đóng một phần              |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldPartialClose(ulong ticket, double &percentToClose)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        return false;
    }
    
    // Kiểm tra nếu nên đóng một phần
    return ShouldPartialClosePosition(*pos, percentToClose);
}

//+------------------------------------------------------------------+
//| ShouldMoveToBreakeven - Kiểm tra nếu đạt điều kiện breakeven    |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldMoveToBreakeven(ulong ticket)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        return false;
    }
    
    // Kiểm tra nếu nên BE
    return ShouldMoveToBreakeven(*pos);
}

//+------------------------------------------------------------------+
//| ShouldClose - Kiểm tra nếu nên đóng lệnh                         |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldClose(ulong ticket, string &reason)
{
    // Tìm vị thế
    PositionInfo* pos = FindPositionByTicket(ticket);
    if (pos == NULL) {
        return false;
    }
    
    // Kiểm tra điều kiện đóng lệnh
    bool shouldClose = ShouldClosePosition(*pos);
    
    if (shouldClose) {
        // Xác định lý do
        if (pos.currentR <= -0.8) {
            reason = "Stop Loss gần chạm";
        } else if (pos.holdingBars > m_maxHoldingTime * 1.5) {
            reason = "Giữ quá lâu";
        } else if (pos.currentR >= pos.targetR) {
            reason = "Đạt mục tiêu";
        } else {
            reason = "Có vấn đề với vị thế";
        }
    }
    
    return shouldClose;
}

//+------------------------------------------------------------------+
//| ShouldCloseAll - Kiểm tra nếu nên đóng tất cả                   |
//+------------------------------------------------------------------+
bool CPositionManager::ShouldCloseAll(string &reason)
{
    // Kiểm tra điều kiện đóng tất cả
    bool shouldCloseAll = ShouldCloseAllPositions();
    
    if (shouldCloseAll) {
        // Xác định lý do
        double maxDrawDown = 0;
        
        if (m_riskManager != NULL) {
            maxDrawDown = m_riskManager.GetMaximumDrawdown();
        } else {
            // Nếu không có RiskManager, tính thủ công
            double equity = AccountInfoDouble(ACCOUNT_EQUITY);
            double balance = AccountInfoDouble(ACCOUNT_BALANCE);
            
            if (balance > 0) {
                maxDrawDown = (balance - equity) / balance * 100.0;
            }
        }
        
        if (maxDrawDown > m_maxDrawdown) {
            reason = "Drawdown vượt ngưỡng (" + DoubleToString(maxDrawDown, 2) + "%)";
        } else if (m_portfolioStatus.totalUnrealizedPnL < 0) {
            double lossPercent = MathAbs(m_portfolioStatus.totalUnrealizedPnL) / AccountInfoDouble(ACCOUNT_EQUITY) * 100.0;
            reason = "Tổng lỗ vượt ngưỡng (" + DoubleToString(lossPercent, 2) + "%)";
        } else if (m_newsFilter != NULL && m_newsFilter.HasHighImpactNews()) {
            reason = "Có tin tức quan trọng sắp diễn ra";
        } else if (m_marketProfile != NULL && m_marketProfile.IsExtremeVolatility()) {
            reason = "Thị trường biến động cực kỳ cao";
        } else {
            reason = "Có vấn đề với danh mục";
        }
    }
    
    return shouldCloseAll;
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
    if (m_marketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        
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
    if (m_closedPositions >= 10) {
        if (m_portfolioStatus.successRate < 40.0) {
            // Hiệu suất kém - TP gần hơn
            targetR *= 0.8;
        } else if (m_portfolioStatus.successRate > 60.0) {
            // Hiệu suất tốt - TP xa hơn
            targetR *= 1.1;
        }
    }
    
    // 4. Dựa trên AssetProfiler
    if (m_assetProfiler != NULL) {
        double assetTargetR = m_assetProfiler.GetOptimalRMultiple();
        if (assetTargetR > 0) {
            // Kết hợp cả 2 giá trị
            targetR = (targetR + assetTargetR) / 2.0;
        }
    }
    
    // Giới hạn trong khoảng hợp lý
    targetR = MathMax(1.0, MathMin(4.0, targetR));
    
    return targetR;
}

//+------------------------------------------------------------------+
//| GetRecommendedRiskPercent - Lấy đề xuất risk %                    |
//+------------------------------------------------------------------+
double CPositionManager::GetRecommendedRiskPercent()
{
    // Mặc định
    double riskPercent = m_maxRiskPerTrade;
    
    // Điều chỉnh dựa trên tình hình hiện tại
    
    // 1. Dựa trên tổng rủi ro hiện tại
    double riskLeft = m_maxTotalRisk - m_portfolioStatus.totalRiskPercent;
    if (riskLeft < riskPercent) {
        // Còn ít rủi ro
        riskPercent = MathMax(0.2, riskLeft);
    }
    
    // 2. Dựa trên Market Regime
    if (m_marketProfile != NULL) {
        ENUM_MARKET_REGIME regime = m_marketProfile.GetRegime();
        
        switch (regime) {
            case REGIME_TRENDING_BULL:
            case REGIME_TRENDING_BEAR:
                // Xu hướng mạnh - rủi ro cao hơn
                riskPercent *= 1.1;
                break;
                
            case REGIME_RANGING_STABLE:
                // Sideway ổn định - rủi ro trung bình
                riskPercent *= 0.9;
                break;
                
            case REGIME_RANGING_VOLATILE:
            case REGIME_VOLATILE_EXPANSION:
            case REGIME_VOLATILE_CONTRACTION:
                // Biến động cao - rủi ro thấp
                riskPercent *= 0.7;
                break;
                
            default:
                break;
        }
    }
    
    // 3. Dựa trên hiệu suất gần đây
    if (m_closedPositions >= 10) {
        if (m_portfolioStatus.successRate < 40.0 || m_portfolioStatus.profitFactor < 1.0) {
            // Hiệu suất kém - rủi ro thấp
            riskPercent *= 0.7;
        } else if (m_portfolioStatus.successRate > 60.0 && m_portfolioStatus.profitFactor > 2.0) {
            // Hiệu suất tốt - rủi ro cao
            riskPercent *= 1.2;
        }
    }
    
    // 4. Dựa trên AssetProfiler
    if (m_assetProfiler != NULL) {
        double volatilityFactor = m_assetProfiler.GetVolatilityFactor();
        if (volatilityFactor > 0) {
            // Điều chỉnh theo volatility
            riskPercent /= volatilityFactor;
        }
    }
    
    // Giới hạn trong khoảng hợp lý
    riskPercent = MathMax(0.2, MathMin(m_maxRiskPerTrade, riskPercent));
    
    return NormalizeDouble(riskPercent, 2);
}

//+------------------------------------------------------------------+
//| LogStatus - Ghi log trạng thái                                   |
//+------------------------------------------------------------------+
void CPositionManager::LogStatus()
{
    // Log thông tin tổng quan
    string statusMsg = StringFormat(
        "PositionManager: Tổng quan - Vị thế: %d (Long: %d, Short: %d), Risk: %.2f%%, Avg R: %.2f, PnL: %.2f%%, Sức khỏe: %s",
        m_portfolioStatus.totalPositions,
        m_portfolioStatus.buyPositions,
        m_portfolioStatus.sellPositions,
        m_portfolioStatus.totalRiskPercent,
        m_portfolioStatus.averageR,
        m_portfolioStatus.totalUnrealizedPnLPercent,
        EnumToString(m_portfolioStatus.health)
    );
    
    m_logger.LogInfo(statusMsg);
    
    // Log thông tin từng vị thế
    if (m_positionsInfo.Total() > 0 && m_enableDetailedLogs) {
        for (int i = 0; i < m_positionsInfo.Total(); i++) {
            PositionInfo* pos = m_positionsInfo.At(i);
            if (pos == NULL) continue;
            
            string posMsg = StringFormat(
                "  Vị thế #%d - %s, R: %.2f, PnL: %.2f%%, Giữ: %d nến, Trạng thái: %s",
                pos.ticket,
                pos.type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                pos.currentR,
                pos.unrealizedPnLPercent,
                pos.holdingBars,
                EnumToString(pos.state)
            );
            
            m_logger.LogInfo(posMsg);
        }
    }
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
            PositionInfo* pos = m_positionsInfo.At(i);
            if (pos == NULL) continue;
            
            report += StringFormat("#%d - %s (%.2f lot)\n", 
                                 pos.ticket, 
                                 pos.type == POSITION_TYPE_BUY ? "BUY" : "SELL",
                                 pos.currentLots);
            report += StringFormat("  Entry: %.5f, SL: %.5f, TP: %.5f\n", 
                                 pos.entryPrice, pos.currentSL, pos.currentTP);
            report += StringFormat("  R hiện tại: %.2f, PnL: %.2f đ (%.2f%%)\n", 
                                 pos.currentR, pos.unrealizedPnL, pos.unrealizedPnLPercent);
            report += StringFormat("  Giữ: %d nến, Trạng thái: %s\n", 
                                 pos.holdingBars, EnumToString(pos.state));
            report += StringFormat("  Scenario: %s, BE: %s, TP1: %s, TP2: %s\n\n", 
                                 EnumToString(pos.scenario),
                                 pos.isBreakevenHit ? "Đạt" : "Chưa",
                                 pos.isPartial1Done ? "Đạt" : "Chưa",
                                 pos.isPartial2Done ? "Đạt" : "Chưa");
        }
    } else {
        report += "Không có vị thế đang mở.\n\n";
    }
    
    // Khuyến nghị
    report += "KHUYẾN NGHỊ:\n";
    
    // Khuyến nghị dựa trên tình hình hiện tại
    switch (m_portfolioStatus.health) {
        case PORTFOLIO_HEALTH_EXCELLENT:
            report += "- Danh mục xuất sắc, có thể tăng risk.\n";
            break;
            
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
    if (ShouldCloseAll(reason)) {
        report += "- Nên đóng tất cả vị thế: " + reason + "\n";
    }
    
    return report;
}

//+------------------------------------------------------------------+
//| SendAlert - Gửi cảnh báo khi có vấn đề                          |
//+------------------------------------------------------------------+
void CPositionManager::SendAlert(const string &message, bool isImportant)
{
    // Ghi log
    if (isImportant) {
        m_logger.LogWarning(message);
    } else {
        m_logger.LogInfo(message);
    }
    
    // Gửi cảnh báo nếu cần
    if (isImportant) {
        Alert("PositionManager: " + message);
    }
}