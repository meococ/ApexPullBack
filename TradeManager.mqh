//+------------------------------------------------------------------+
//|                                       TradeManager.mqh (v14.0)    |
//|                                  Copyright 2023-2024, ApexPullback EA |
//|                                      https://www.apexpullback.com |
//+------------------------------------------------------------------+
// Copyright 2023-2024, ApexPullback EA
// Website: https://www.apexpullback.com
// Version: 14.0
// Mode: strict

// Đảm bảo chỉ include file này một lần
#ifndef TRADEMANAGER_MQH_INCLUDED
#define TRADEMANAGER_MQH_INCLUDED

// --- Standard MQL5 Libraries ---
#include <Trade/Trade.mqh>          // For CTrade object
#include <Trade/PositionInfo.mqh>   // For position information functions
#include <Trade/SymbolInfo.mqh>     // For symbol properties
#include <Trade/AccountInfo.mqh>    // For account related information
#include <Arrays/ArrayObj.mqh>      // For CArrayObj (used for m_PositionsMetadata)
// #include <Object.mqh>            // Uncomment if chart objects are directly manipulated
// #include <Charts/Chart.mqh>      // Uncomment if chart functions are directly used
// #include <Math/Stat/Math.mqh>    // Uncomment if advanced math/stat functions are used

// --- Custom EA Core Includes ---
// QUAN TRỌNG: Các tệp này định nghĩa các thành phần cốt lõi và nên được include trước các module cụ thể.
// Namespace.mqh nên được include trước khi khai báo namespace.
#include "Namespace.mqh"          // Defines namespaces (e.g., ApexPullback) and related macros
#include "CommonDefinitions.mqh"  // General definitions, possibly macros like TREND_NONE, SIGNAL_NONE
#include "Constants.mqh"          // EA-specific constants
#include "Enums.mqh"              // Enumerations (e.g., ENUM_EA_STATE, ENUM_TRAILING_MODE)
#include "CommonStructs.mqh"      // Common data structures (e.g., MarketProfileData, PositionMetadata)
#include "FunctionDefinitions.mqh"// Global utility functions (if any are used by this module)
#include "MathHelper.mqh"         // Math utility functions (if any are used by this module)

// --- Custom EA Module Includes ---
// These are specific modules of the EA. Include them after core files.
// They are included outside any namespace block if they define classes that might be forward-declared
// or used by CTradeManager within its own namespace.
#include "Logger.mqh"             // Logging facility
#include "MarketProfile.mqh"      // Market analysis module
#include "RiskManager.mqh"        // Risk management module
#include "RiskOptimizer.mqh"      // Risk optimization module (direct dependency for CRiskOptimizer*)
#include "AssetProfiler.mqh"      // Asset profiling module
#include "NewsFilter.mqh"         // News filtering module
#include "SwingPointDetector.mqh" // Swing point detection module

// Mở namespace ApexPullback
namespace ApexPullback {

// Forward declarations để tránh circular dependency
class CLogger;
class CMarketProfile;
class CRiskOptimizer;
class CRiskManager;
class CAssetProfiler;
class CNewsFilter;
class CSwingDetector;

// --- CẤU TRÚC MULTI LEVEL TAKE PROFIT ---
struct MultiTakeProfitLevel {
    double price;                  // Giá take profit
    double volumePercent;          // Phần trăm khối lượng đóng
    bool   triggered;              // Đã kích hoạt chưa
    double rMultiple;              // Tương ứng với bao nhiêu R
    
    // Phương thức khởi tạo giá trị mặc định
    void Initialize() {
        price = 0;
        volumePercent = 0;
        triggered = false;
        rMultiple = 0;
    }
};

// --- CẤU TRÚC LƯU TRỮ THÔNG TIN VỊ THẾ ---
struct PositionMetadata {
    ulong  ticket;                 // Ticket của vị thế
    double initialSL;              // SL ban đầu
    double initialTP;              // TP ban đầu
    double initialVolume;          // Khối lượng ban đầu
    double entryPrice;             // Giá vào lệnh
    bool   isLong;                 // Lệnh mua hay bán?
    datetime entryTime;            // Thời gian vào lệnh
    ENUM_ENTRY_SCENARIO scenario;  // Kịch bản vào lệnh
    
    bool   isBreakeven;            // Đã đạt breakeven?
    bool   isPartialClosed1;       // Đã đóng một phần 1?
    bool   isPartialClosed2;       // Đã đóng một phần 2?
    int    scalingCount;           // Số lần đã nhồi lệnh
    
    // Thời gian và giá của trailing stop cuối
    datetime lastTrailingTime;     // Thời gian trailing gần nhất
    double   lastTrailingSL;       // Giá trị SL trailing gần nhất
    
    // Phương thức khởi tạo giá trị mặc định
    void Initialize() {
        ticket = 0;
        initialSL = 0;
        initialTP = 0;
        initialVolume = 0;
        entryPrice = 0;
        isLong = true;
        entryTime = 0;
        scenario = SCENARIO_NONE;
        
        isBreakeven = false;
        isPartialClosed1 = false;
        isPartialClosed2 = false;
        scalingCount = 0;
        
        lastTrailingTime = 0;
        lastTrailingSL = 0;
    }
};

//+------------------------------------------------------------------+
//| CTradeManager - Quản lý giao dịch và vòng đời lệnh              |
//+------------------------------------------------------------------+
public:
    // Functions for Dashboard interaction
    void SetTradingPaused(bool paused);
    bool IsTradingPaused() const;
    void CloseAllPositionsByMagic(int magicNumber = 0); // Default magic 0 means all EA positions

// Original public methods (if any) would follow, or this is the start of public section
// We are assuming this is a reasonable place to add public declarations.
// If there's an existing public: section, these should be merged.

// --- HÀM KHỞI TẠO & HỦY --- 
// (Assuming constructor and destructor are public, which is typical)
// CTradeManager(CLogger* logger, ...); // Example existing constructor
// ~CTradeManager();

// --- CÁC HÀM PUBLIC KHÁC --- 
// (Other existing public methods would be here)

// The original content of the class continues below:
class CTradeManager {
private:
    // Các đối tượng chính
    CTrade           m_trade;            // Đối tượng giao dịch chuẩn
    CLogger *m_logger;        // Logger để ghi log
    CMarketProfile  *m_marketProfile;    // Thông tin thị trường
    CRiskOptimizer  *m_riskOptimizer;    // Tối ưu hóa rủi ro
    CRiskManager    *m_riskManager;      // Quản lý rủi ro
    CAssetProfiler  *m_assetProfiler;    // Module mới: Asset Profiler
    CNewsFilter     *m_newsFilter;       // Cải tiến: Bộ lọc tin tức
    CSwingDetector  *m_swingDetector;    // Phát hiện Swing Points
    ApexPullback::MarketProfileData m_currentMarketProfileData; // Thêm biến thành viên để lưu trữ MarketProfileData

    // --- THÔNG SỐ CƠ BẢN ---
    string           m_Symbol;           // Symbol hiện tại
    int              m_MagicNumber;      // Mã số nhận diện EA
    int              m_Digits;           // Số chữ số thập phân của symbol
    double           m_Point;            // Giá trị 1 point của symbol
    string           m_OrderComment;     // Comment cho lệnh mới
    bool             m_EnableDetailedLogs; // Bật log chi tiết
    
    // --- QUẢN LÝ TRẠNG THÁI EA ---
    ENUM_EA_STATE    m_EAState;          // Trạng thái EA hiện tại
    bool             m_isTradingPaused;  // Cờ báo giao dịch đang tạm dừng
    bool             m_IsActive;         // EA có đang hoạt động?
    datetime         m_PauseUntil;       // Thời gian tạm dừng đến
    int              m_ConsecutiveLosses; // Số lần thua liên tiếp
    bool             m_EmergencyMode;    // Chế độ khẩn cấp (đóng tất cả)
    
    // --- THAM SỐ BREAKEVEN & TRAILING ---
    double           m_BreakEvenR;       // R-multiple cho breakeven
    double           m_BreakEvenBuffer;  // Buffer thêm cho breakeven
    bool             m_UseAdaptiveTrailing; // Sử dụng trailing thích ứng
    ENUM_TRAILING_MODE m_TrailingMode;   // Chế độ trailing
    double           m_TrailingATRMultiplier; // Hệ số ATR cho trailing
    int              m_MinTrailingStepPoints; // Số điểm tối thiểu để cập nhật trailing
    
    // --- THAM SỐ ĐÓNG LỆNH MỘT PHẦN ---
    bool             m_UsePartialClose;  // Sử dụng đóng lệnh một phần
    double           m_PartialCloseR1;   // R-multiple cho đóng một phần 1
    double           m_PartialCloseR2;   // R-multiple cho đóng một phần 2
    double           m_PartialClosePercent1; // % đóng ở mục tiêu 1
    double           m_PartialClosePercent2; // % đóng ở mục tiêu 2
    
    // --- THAM SỐ SCALING (NHỒI LỆNH) ---
    bool             m_EnableScaling;    // Cho phép nhồi lệnh
    int              m_MaxScalingCount;  // Số lần scaling tối đa
    double           m_ScalingRiskPercent; // % risk cho lệnh nhồi
    bool             m_RequireBEForScaling; // Yêu cầu BE trước khi nhồi
    
    // --- CHANDELIER EXIT ---
    bool             m_UseChandelierExit;     // Kích hoạt Chandelier Exit
    int              m_ChandelierLookback;    // Số nến lookback Chandelier
    double           m_ChandelierATRMultiplier; // Hệ số ATR Chandelier
    
    // --- QUẢN LÝ VỊ THẾ & METADATA ---
    CArrayObj        m_PositionsMetadata;    // Lưu trữ metadata của các vị thế
    
    // --- MULTI-LEVEL TAKE PROFIT ---
    MultiTakeProfitLevel m_TakeProfitLevels[5]; // Tối đa 5 mức chốt lời
    int              m_TakeProfitLevelCount;    // Số mức chốt lời đang sử dụng
    
    // --- INDICATOR HANDLES ---
    int              m_handleATR;        // Handle indicator ATR
    int              m_handleEMA34;      // Handle EMA 34
    int              m_handleEMA89;      // Handle EMA 89
    int              m_handleEMA200;     // Handle EMA 200
    int              m_handlePSAR;       // Handle PSAR
    
    // --- HÀM NỘI BỘ: XỬ LÝ VỊ THẾ ---
    
    // Quản lý metadata của vị thế
    void SavePositionMetadata(ulong ticket, double entryPrice, double stopLoss, 
                             double takeProfit, double volume, bool isLong, 
                             ENUM_ENTRY_SCENARIO scenario);
    bool UpdatePositionMetadata(ulong ticket, double newSL = 0, double newTP = 0);
    ApexPullback::PositionMetadata GetPositionMetadata(ulong ticket);
    void RemovePositionMetadata(ulong ticket);
    void ClearAllMetadata();
    
    // Helper functions để cập nhật metadata
    void UpdatePositionMetadataPartialClose1(ulong ticket);
    void UpdatePositionMetadataPartialClose2(ulong ticket);
    void UpdatePositionMetadataBreakeven(ulong ticket);
    void UpdatePositionMetadataScaling(ulong ticket);
    
    // Quản lý trailing stop
    double CalculateDynamicTrailingStop(ulong ticket, double currentPrice, bool isLong, ENUM_MARKET_REGIME regime);
    double CalculateTrailingStopATR(double currentPrice, bool isLong, double atr);
    double CalculateTrailingStopSwing(bool isLong);
    double CalculateTrailingStopEMA(bool isLong);
    double CalculateTrailingStopPSAR(bool isLong);
    double CalculateChandelierExit(bool isLong, int period, double multiplier);
    
    // Quản lý đóng lệnh một phần
    bool ManagePartialClose(ulong ticket);
    bool SafeClosePartial(ulong ticket, double partialLots, string partialComment);
    
    // Quản lý nhồi lệnh (scaling)
    bool CheckAndExecuteScaling(ulong ticket);
    bool ShouldScaleInPosition(ulong ticket, double currentPrice, double entryPrice, bool isLong, const MarketProfileData &profile);
    bool ExecuteScalingOrder(ulong ticket, double scalingPrice, bool isLong);
    
    // Quản lý breakeven
    bool CheckAndMoveToBreakeven(ulong ticket);
    
    // --- HÀM NỘI BỘ: TIỆN ÍCH ---
    
    // Lấy tỷ số R hiện tại
    double GetCurrentRR(ulong ticket);
    
    // Kiểm tra nếu giá hiện tại đã đạt một mục tiêu R cụ thể
    bool HasReachedRTarget(ulong ticket, double rTarget);
    
    // Thực hiện thay đổi SL an toàn
    bool SafeModifyStopLoss(ulong ticket, double newSL);
    
    // Quản lý vị thế hiện tại
    bool ModifyPosition(ulong ticket, double newSL = 0, double newTP = 0);
    bool ClosePosition(ulong ticket, string comment = "");
    bool CloseAllPositions(string comment = "");
    bool CancelAllPendingOrders(string comment = "");
    int CountOpenPositions(ENUM_POSITION_TYPE type = POSITION_TYPE_BUY);
    bool HasOpenPosition(ENUM_POSITION_TYPE type = POSITION_TYPE_BUY);
    bool GetOpenTickets(ulong &tickets[]);
    
    // Truy vấn thông tin
    double GetInitialStopLoss(ulong ticket);
    double GetInitialVolume(ulong ticket);
    double GetPositionRRatio(ulong ticket);
    int GetScalingCount(ulong ticket);
    void ProcessTradeTransaction(const MqlTradeTransaction &trans);
    void UpdateEAState(ENUM_EA_STATE newState, datetime pauseUntil = 0);
    bool ShouldAdjustForHighVolatility(const MarketProfileData &profile);
    
    // Cập nhật thông tin trailing stop mới nhất
    void UpdateLastTrailingInfo(ulong ticket, double newSL);
    
    // Tính toán điểm dừng lỗ thích ứng dựa trên AssetProfiler
    double CalculateAdaptiveStopLoss(bool isLong, double entryPrice);
    
    // Tính toán take profit thích ứng dựa trên Regime và R-multiple
    double CalculateAdaptiveTakeProfit(bool isLong, double entryPrice, double stopLoss, ENUM_MARKET_REGIME regime);
    
    // Kiểm tra điều kiện thị trường có phù hợp để nhồi lệnh
    bool IsMarketSuitableForScaling(const MarketProfileData &profile);
    
    // Tạo comment chi tiết cho lệnh
    string GenerateOrderComment(bool isLong, ENUM_ENTRY_SCENARIO scenario, string additionalInfo = "");
    
    // Kiểm tra và đóng tất cả vị thế trong trường hợp khẩn cấp
    void EmergencyCloseAllPositions(string reason);
    
    // Mã hóa thông tin trong MagicNumber
    int EncodeMagicNumber(int baseNumber, ENUM_TIMEFRAMES timeframe, ENUM_ENTRY_SCENARIO scenario);
    
    // Lấy ATR hiện tại
    double GetCurrentATR();
    
    // Lấy atr của AssetProfiler
    double GetProfilerATR();
    
    // Lấy giá trị EMA
    double GetEMAValue(int emaHandle, int shift = 0);
    
    // Lấy thông tin khoảng cách tối thiểu
    double GetMinStopLevel();
    
    // Kiểm tra điều kiện lệnh hợp lệ
    bool ValidateOrderParameters(double &price, double &sl, double &tp, bool isLong);
    
    // Kiểm tra xem phiên hiện tại có thích hợp cho scaling
    bool IsCurrentSessionSuitableForScaling();
    
    // Tính toán mục tiêu TP tối ưu dựa trên R và Regime
    double CalculateOptimalTakeProfitRatio(ENUM_MARKET_REGIME regime);
    
    // Xử lý yêu cầu ModifyPosition
    bool ProcessModifyRequest(ulong ticket, double newSL, double newTP);
    
    // Xử lý sự kiện khi deal được đóng
    void HandleCloseDeal(ulong positionTicket, double closePrice, double profit);
    
public:
    // Constructor và Destructor
    CTradeManager();
    ~CTradeManager();
    
    // Thiết lập log chi tiết
    void SetDetailedLogging(bool enable) { m_EnableDetailedLogs = enable; }
    
    // --- KHỜI TẠO VÀ THIẾT LẬP ---
    bool Initialize(string symbol, int magic, CLogger* logger, 
                   CMarketProfile* marketProfile, CRiskManager* riskMgr, 
                   CRiskOptimizer* riskOpt, CAssetProfiler* assetProfiler = NULL,
                   CNewsFilter* newsFilter = NULL, CSwingDetector* swingDetector = NULL);
    
    // Thiết lập tham số trailing stop
    void SetTrailingParameters(bool useAdaptiveTrail, ENUM_TRAILING_MODE trailingMode, 
                             double atrMultiplier, int minStepPoints);
    
    // Thiết lập tham số breakeven
    void SetBreakevenParameters(double breakEvenR, double buffer = 5);
    
    // Thiết lập tham số đóng một phần
    void SetPartialCloseParameters(bool usePartialClose, double r1, double r2, 
                                 double percent1, double percent2);
    
    // Thiết lập tham số scaling
    void SetScalingParameters(bool enableScaling, int maxCount, double riskPercent, 
                            bool requireBreakeven);
    
    // Thiết lập Chandelier Exit
    void EnableChandelierExit(bool enable, int lookback, double multiplier);
    
    // Thiết lập đa mức Take Profit
    void ConfigureMultipleTargets(double &tpRatios[], double &volumePercents[], int count);
    
    // Thiết lập comment cho lệnh
    void SetOrderComment(string comment) { m_OrderComment = comment; }
    
    // --- THỰC THI LỆNH GIAO DỊCH ---
    
    // Mở lệnh Buy
    ulong OpenBuy(double lotSize, double stopLoss, double takeProfit, 
                 ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // Mở lệnh Sell
    ulong OpenSell(double lotSize, double stopLoss, double takeProfit, 
                  ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // Đặt lệnh Buy Limit
    ulong PlaceBuyLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                       ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // Đặt lệnh Sell Limit
    ulong PlaceSellLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                        ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // Đặt lệnh Buy Stop
    ulong PlaceBuyStop(double lotSize, double stopPrice, double stopLoss, double takeProfit, 
                      ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // Đặt lệnh Sell Stop
    ulong PlaceSellStop(double lotSize, double stopPrice, double stopLoss, double takeProfit,
                        ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "");
    
    // --- HÀM PUBLIC: QUẢN LÝ VỊ THẾ ---
    void ManageExistingPositions(EAContext* context);
};

// ===== BẮT ĐẦU IMPLEMENTATION =====

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
    // Khởi tạo giá trị mặc định
    m_Symbol = "";
    m_MagicNumber = 0;
    m_OrderComment = "Apex Pullback v14";
    m_Digits = 5;
    m_Point = 0.00001;
    m_EnableDetailedLogs = false;
    
    // Khởi tạo con trỏ
    m_logger = NULL;
    m_marketProfile = NULL;
    m_riskOptimizer = NULL;
    m_riskManager = NULL;
    m_assetProfiler = NULL;
    m_newsFilter = NULL;
    m_swingDetector = NULL;
    
    // Khởi tạo trạng thái EA
    m_EAState = STATE_INIT;
    m_IsActive = true;
    m_PauseUntil = 0;
    m_ConsecutiveLosses = 0;
    m_EmergencyMode = false;
    
    // Khởi tạo tham số breakeven & trailing
    m_BreakEvenR = 1.0;
    m_BreakEvenBuffer = 5.0;
    m_UseAdaptiveTrailing = true;
    m_TrailingMode = TRAILING_ADAPTIVE;
    m_TrailingATRMultiplier = 2.0;
    m_MinTrailingStepPoints = 5;
    
    // Khởi tạo tham số đóng một phần
    m_UsePartialClose = true;
    m_PartialCloseR1 = 1.0;
    m_PartialCloseR2 = 2.0;
    m_PartialClosePercent1 = 35.0;
    m_PartialClosePercent2 = 35.0;
    
    // Khởi tạo tham số scaling
    m_EnableScaling = true;
    m_MaxScalingCount = 1;
    m_ScalingRiskPercent = 0.3;
    m_RequireBEForScaling = true;
    
    // Khởi tạo tham số Chandelier Exit
    m_UseChandelierExit = true;
    m_ChandelierLookback = 20;
    m_ChandelierATRMultiplier = 3.0;
    
    // Khởi tạo handle indicators
    m_handleATR = INVALID_HANDLE;
    m_handleEMA34 = INVALID_HANDLE;
    m_handleEMA89 = INVALID_HANDLE;
    m_handleEMA200 = INVALID_HANDLE;
    m_handlePSAR = INVALID_HANDLE;
    
    // Khởi tạo MultiTakeProfit mặc định
    m_TakeProfitLevelCount = 3;
    
    // Mặc định: TP1 35% tại 1R
    m_TakeProfitLevels[0].rMultiple = 1.0;
    m_TakeProfitLevels[0].volumePercent = 35.0;
    m_TakeProfitLevels[0].triggered = false;
    
    // Mặc định: TP2 35% tại 2R
    m_TakeProfitLevels[1].rMultiple = 2.0;
    m_TakeProfitLevels[1].volumePercent = 35.0;
    m_TakeProfitLevels[1].triggered = false;
    
    // Mặc định: TP3 30% tại 3R
    m_TakeProfitLevels[2].rMultiple = 3.0;
    m_TakeProfitLevels[2].volumePercent = 30.0;
    m_TakeProfitLevels[2].triggered = false;
    
    // Khởi tạo mảng lưu trữ metadata của vị thế
    m_PositionsMetadata.Clear();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
    // Giải phóng tài nguyên indicator
    if (m_handleATR != INVALID_HANDLE) {
        IndicatorRelease(m_handleATR);
        m_handleATR = INVALID_HANDLE;
    }
    
    if (m_handleEMA34 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA34);
        m_handleEMA34 = INVALID_HANDLE;
    }
    
    if (m_handleEMA89 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA89);
        m_handleEMA89 = INVALID_HANDLE;
    }
    
    if (m_handleEMA200 != INVALID_HANDLE) {
        IndicatorRelease(m_handleEMA200);
        m_handleEMA200 = INVALID_HANDLE;
    }
    
    if (m_handlePSAR != INVALID_HANDLE) {
        IndicatorRelease(m_handlePSAR);
        m_handlePSAR = INVALID_HANDLE;
    }
    
    // Xóa tất cả metadata
    ClearAllMetadata();
    
    // Reset con trỏ từ bên ngoài
    m_logger = NULL;
    m_marketProfile = NULL;
    m_riskOptimizer = NULL;
    m_riskManager = NULL;
    m_assetProfiler = NULL;
    m_newsFilter = NULL;
    m_swingDetector = NULL;
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo TradeManager                              |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(string symbol, int magic, CLogger* logger, 
                              CMarketProfile* marketProfile, CRiskManager* riskMgr, 
                              CRiskOptimizer* riskOpt, CAssetProfiler* assetProfiler,
                              CNewsFilter* newsFilter, CSwingDetector* swingDetector)
{
    // Kiểm tra tham số bắt buộc
    if (symbol == "" || magic <= 0 || logger == NULL || 
        marketProfile == NULL || riskMgr == NULL) {
        // Logger là đối tượng trực tiếp, không cần kiểm tra
logger->LogError("TradeManager::Initialize - Tham số thiếu hoặc không hợp lệ");
        return false;
    }
    
    // Lưu các tham số và con trỏ
    m_Symbol = symbol;
    m_MagicNumber = magic;
    m_logger = logger;
    m_marketProfile = marketProfile;
    m_riskManager = riskMgr;
    m_riskOptimizer = riskOpt;
    m_assetProfiler = assetProfiler;
    m_newsFilter = newsFilter;
    m_swingDetector = swingDetector;
    
    // Lấy thông tin symbol
    m_Digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    m_Point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Thiết lập đối tượng CTrade
    m_trade.SetExpertMagicNumber(magic);
    m_trade.SetMarginMode();
    m_trade.SetTypeFillingBySymbol(m_Symbol);
    m_trade.SetDeviationInPoints(10);
    
    // Khởi tạo handle indicators
    m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
    if (m_handleATR == INVALID_HANDLE) {
        m_logger->LogWarning("TradeManager - Không thể tạo ATR handle");
    }
    
    // Khởi tạo các indicator khác nếu cần
    m_handleEMA34 = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    m_handleEMA89 = iMA(m_Symbol, PERIOD_CURRENT, 89, 0, MODE_EMA, PRICE_CLOSE);
    m_handleEMA200 = iMA(m_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    if (m_TrailingMode == TRAILING_PSAR) {
        m_handlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2);
        if (m_handlePSAR == INVALID_HANDLE) {
            m_logger->LogWarning("TradeManager - Không thể tạo PSAR handle");
        }
    }
    
    // Xóa metadata cũ
    ClearAllMetadata();
    
    // Đặt trạng thái hoạt động
    m_EAState = STATE_RUNNING;
    m_IsActive = true;
    
    m_logger->LogInfo("TradeManager khởi tạo thành công cho " + symbol + 
                   " với magic " + IntegerToString(magic));
    
    return true;
}

//+------------------------------------------------------------------+
//| SetTrailingParameters - Thiết lập tham số trailing stop         |
//+------------------------------------------------------------------+
void CTradeManager::SetTrailingParameters(bool useAdaptiveTrail, ENUM_TRAILING_MODE trailingMode, 
                                      double atrMultiplier, int minStepPoints)
{
    m_UseAdaptiveTrailing = useAdaptiveTrail;
    m_TrailingMode = trailingMode;
    m_TrailingATRMultiplier = MathMax(0.5, atrMultiplier);
    m_MinTrailingStepPoints = MathMax(1, minStepPoints);
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Trailing parameters set - Adaptive: %s, Mode: %s, ATR Mult: %.2f, Step: %d",
            useAdaptiveTrail ? "Yes" : "No",
            EnumToString(trailingMode),
            m_TrailingATRMultiplier,
            m_MinTrailingStepPoints
        ));
    }
}

//+------------------------------------------------------------------+
//| SetBreakevenParameters - Thiết lập tham số breakeven            |
//+------------------------------------------------------------------+
void CTradeManager::SetBreakevenParameters(double breakEvenR, double buffer)
{
    m_BreakEvenR = MathMax(0.1, breakEvenR);
    m_BreakEvenBuffer = MathMax(0.0, buffer);
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Breakeven parameters set - R: %.2f, Buffer: %.2f points",
            m_BreakEvenR, m_BreakEvenBuffer
        ));
    }
}

//+------------------------------------------------------------------+
//| SetPartialCloseParameters - Thiết lập tham số đóng từng phần    |
//+------------------------------------------------------------------+
void CTradeManager::SetPartialCloseParameters(bool usePartialClose, double r1, double r2, 
                                          double percent1, double percent2)
{
    m_UsePartialClose = usePartialClose;
    m_PartialCloseR1 = MathMax(0.1, r1);
    m_PartialCloseR2 = MathMax(m_PartialCloseR1, r2);
    m_PartialClosePercent1 = MathMax(0.0, MathMin(99.0, percent1));
    m_PartialClosePercent2 = MathMax(0.0, MathMin(99.0, percent2));
    
    // Cập nhật MultiTakeProfit để phù hợp
    m_TakeProfitLevelCount = 3;
    
    // TP1: Đóng phần 1 tại R1
    m_TakeProfitLevels[0].rMultiple = m_PartialCloseR1;
    m_TakeProfitLevels[0].volumePercent = m_PartialClosePercent1;
    
    // TP2: Đóng phần 2 tại R2
    m_TakeProfitLevels[1].rMultiple = m_PartialCloseR2;
    m_TakeProfitLevels[1].volumePercent = m_PartialClosePercent2;
    
    // TP3: Phần còn lại tại R3 = R2*1.5
    m_TakeProfitLevels[2].rMultiple = m_PartialCloseR2 * 1.5;
    m_TakeProfitLevels[2].volumePercent = 100.0 - m_PartialClosePercent1 - m_PartialClosePercent2;
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Partial close set - Enabled: %s, TP1: %.2fR (%.1f%%), TP2: %.2fR (%.1f%%), TP3: %.2fR (%.1f%%)",
            usePartialClose ? "Yes" : "No",
            m_TakeProfitLevels[0].rMultiple, m_TakeProfitLevels[0].volumePercent,
            m_TakeProfitLevels[1].rMultiple, m_TakeProfitLevels[1].volumePercent,
            m_TakeProfitLevels[2].rMultiple, m_TakeProfitLevels[2].volumePercent
        ));
    }
}

//+------------------------------------------------------------------+
//| SetScalingParameters - Thiết lập tham số nhồi lệnh              |
//+------------------------------------------------------------------+
void CTradeManager::SetScalingParameters(bool enableScaling, int maxCount, double riskPercent, 
                                     bool requireBreakeven)
{
    m_EnableScaling = enableScaling;
    m_MaxScalingCount = MathMax(0, maxCount);
    m_ScalingRiskPercent = MathMax(0.1, MathMin(1.0, riskPercent));
    m_RequireBEForScaling = requireBreakeven;
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Scaling parameters set - Enabled: %s, Max Count: %d, Risk: %.2f, Require BE: %s",
            enableScaling ? "Yes" : "No",
            m_MaxScalingCount,
            m_ScalingRiskPercent,
            requireBreakeven ? "Yes" : "No"
        ));
    }
}

//+------------------------------------------------------------------+
//| EnableChandelierExit - Thiết lập tham số Chandelier Exit        |
//+------------------------------------------------------------------+
void CTradeManager::EnableChandelierExit(bool enable, int lookback, double multiplier)
{
    m_UseChandelierExit = enable;
    m_ChandelierLookback = MathMax(5, lookback);
    m_ChandelierATRMultiplier = MathMax(0.5, multiplier);
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Chandelier Exit set - Enabled: %s, Lookback: %d, ATR Mult: %.2f",
            enable ? "Yes" : "No",
            m_ChandelierLookback,
            m_ChandelierATRMultiplier
        ));
    }
}

//+------------------------------------------------------------------+
//| ConfigureMultipleTargets - Thiết lập đa mức Take Profit         |
//+------------------------------------------------------------------+
void CTradeManager::ConfigureMultipleTargets(double &tpRatios[], double &volumePercents[], int count)
{
    m_TakeProfitLevelCount = MathMin(count, 5);
    
    // Khởi tạo các mức TP
    for (int i = 0; i < m_TakeProfitLevelCount; i++) {
        m_TakeProfitLevels[i].rMultiple = tpRatios[i];
        m_TakeProfitLevels[i].volumePercent = volumePercents[i];
        m_TakeProfitLevels[i].triggered = false;
    }
    
    // Đảm bảo tổng phần trăm không vượt quá 100%
    double totalPercent = 0;
    for (int i = 0; i < m_TakeProfitLevelCount; i++) {
        totalPercent += m_TakeProfitLevels[i].volumePercent;
    }
    
    if (totalPercent > 100.0) {
        // Điều chỉnh tỷ lệ
        for (int i = 0; i < m_TakeProfitLevelCount; i++) {
            m_TakeProfitLevels[i].volumePercent = m_TakeProfitLevels[i].volumePercent * 100.0 / totalPercent;
        }
    }
    
    if (m_EnableDetailedLogs) {
        string tpInfo = "TradeManager: MultiTP set - Levels: " + IntegerToString(m_TakeProfitLevelCount);
        for (int i = 0; i < m_TakeProfitLevelCount; i++) {
            tpInfo += StringFormat(", TP%d: %.2fR (%.1f%%)", 
                                i + 1, 
                                m_TakeProfitLevels[i].rMultiple, 
                                m_TakeProfitLevels[i].volumePercent);
        }
        m_logger->LogInfo(tpInfo);
    }
}

//+------------------------------------------------------------------+
//| OpenBuy - Mở lệnh Buy                                           |
//+------------------------------------------------------------------+
ulong CTradeManager::OpenBuy(double lotSize, double stopLoss, double takeProfit, 
                          ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể mở lệnh Buy - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Lấy giá hiện tại
    double entryPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);

    // Logic MỚI cho Stop Loss lệnh MUA (Ưu tiên #1)
    double sl_price_buy;
    if (m_swingDetector != NULL) {
        double pullbackLow = m_swingDetector->GetLastSwingLow();
        if (pullbackLow > 0) {
            double sl_buffer = GetCurrentATR() * StopLossBufferATR_Ratio; // Sử dụng input mới
            sl_price_buy = pullbackLow - sl_buffer;
        } else {
            // Fallback: Nếu không tìm thấy swing, quay lại dùng logic ATR cũ
            sl_price_buy = entryPrice - (GetCurrentATR() * StopLossATR_Multiplier); // Sử dụng input ATR SL
        }
    } else {
        // Fallback nếu m_swingDetector không được khởi tạo
        sl_price_buy = entryPrice - (GetCurrentATR() * StopLossATR_Multiplier);
    }
    stopLoss = sl_price_buy; // Gán SL đã tính toán

    // Logic MỚI cho Take Profit lệnh MUA (Ưu tiên #2)
    double tp_price_buy = 0;
    switch(TakeProfitMode) { // TakeProfitMode từ Inputs.mqh
        case TP_MODE_RR_FIXED:
            if (entryPrice - stopLoss > 0) { // Đảm bảo SL hợp lệ
                tp_price_buy = entryPrice + (entryPrice - stopLoss) * TakeProfit_RR; // TakeProfit_RR từ Inputs.mqh
            }
            break;

        case TP_MODE_STRUCTURE:
            if (m_swingDetector != NULL) {
                double targetHigh = m_swingDetector->GetLastSwingHigh();
                if (targetHigh > entryPrice) {
                    tp_price_buy = targetHigh - (GetCurrentATR() * TakeProfitStructureBufferATR_Ratio); // Sử dụng input mới
                }
            }
            // Fallback nếu không tìm thấy cấu trúc hoặc tp_price_buy không hợp lệ
            if (tp_price_buy <= entryPrice && (entryPrice - stopLoss > 0)) { 
                tp_price_buy = entryPrice + (entryPrice - stopLoss) * TakeProfit_RR;
            }
            break;

        case TP_MODE_VOLATILITY:
            if (m_marketProfile != NULL) {
                double adx_value = m_marketProfile->GetADX();
                double atr_multiplier_tp = (adx_value > ADXThresholdForVolatilityTP) ? VolatilityTP_ATR_Multiplier_High : VolatilityTP_ATR_Multiplier_Low; // Sử dụng input mới
                tp_price_buy = entryPrice + (GetCurrentATR() * atr_multiplier_tp);
            }
            break;
    }
    // Fallback cuối cùng nếu tp_price_buy vẫn chưa được đặt hoặc không hợp lệ
    if (tp_price_buy <= entryPrice && (entryPrice - stopLoss > 0)) {
        tp_price_buy = entryPrice + (entryPrice - stopLoss) * TakeProfit_RR; 
    }
    takeProfit = tp_price_buy; // Gán TP đã tính toán
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(entryPrice, stopLoss, takeProfit, true)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(true, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, price, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.Buy(lotSize, m_Symbol, price, stopLoss, takeProfit, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh BUY - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    // Lưu thông tin metadata
    if (ticket > 0) {
        SavePositionMetadata(ticket, price, stopLoss, takeProfit, lotSize, true, scenario);
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh BUY thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| OpenSell - Mở lệnh Sell                                         |
//+------------------------------------------------------------------+
ulong CTradeManager::OpenSell(double lotSize, double stopLoss, double takeProfit, 
                           ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể mở lệnh Sell - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Lấy giá hiện tại
    double entryPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);

    // Logic MỚI cho Stop Loss lệnh BÁN (Ưu tiên #1)
    double sl_price_sell;
    if (m_swingDetector != NULL) {
        double pullbackHigh = m_swingDetector->GetLastSwingHigh();
        if (pullbackHigh > 0) {
            double sl_buffer = GetCurrentATR() * StopLossBufferATR_Ratio; // Sử dụng input mới
            sl_price_sell = pullbackHigh + sl_buffer;
        } else {
            // Fallback: Nếu không tìm thấy swing, quay lại dùng logic ATR cũ
            sl_price_sell = entryPrice + (GetCurrentATR() * StopLossATR_Multiplier); // Sử dụng input ATR SL
        }
    } else {
         // Fallback nếu m_swingDetector không được khởi tạo
        sl_price_sell = entryPrice + (GetCurrentATR() * StopLossATR_Multiplier);
    }
    stopLoss = sl_price_sell; // Gán SL đã tính toán

    // Logic MỚI cho Take Profit lệnh BÁN (Ưu tiên #2)
    double tp_price_sell = 0;
    switch(TakeProfitMode) { // TakeProfitMode từ Inputs.mqh
        case TP_MODE_RR_FIXED:
            if (stopLoss - entryPrice > 0) { // Đảm bảo SL hợp lệ
                tp_price_sell = entryPrice - (stopLoss - entryPrice) * TakeProfit_RR; // TakeProfit_RR từ Inputs.mqh
            }
            break;

        case TP_MODE_STRUCTURE:
            if (m_swingDetector != NULL) {
                double targetLow = m_swingDetector->GetLastSwingLow();
                if (targetLow < entryPrice && targetLow > 0) {
                    tp_price_sell = targetLow + (GetCurrentATR() * TakeProfitStructureBufferATR_Ratio); // Sử dụng input mới
                }
            }
            // Fallback nếu không tìm thấy cấu trúc hoặc tp_price_sell không hợp lệ
            if ((tp_price_sell >= entryPrice || tp_price_sell == 0) && (stopLoss - entryPrice > 0)) {
                tp_price_sell = entryPrice - (stopLoss - entryPrice) * TakeProfit_RR;
            }
            break;

        case TP_MODE_VOLATILITY:
            if (m_marketProfile != NULL) {
                double adx_value = m_marketProfile->GetADX();
                double atr_multiplier_tp = (adx_value > ADXThresholdForVolatilityTP) ? VolatilityTP_ATR_Multiplier_High : VolatilityTP_ATR_Multiplier_Low; // Sử dụng input mới
                tp_price_sell = entryPrice - (GetCurrentATR() * atr_multiplier_tp);
            }
            break;
    }
    // Fallback cuối cùng nếu tp_price_sell vẫn chưa được đặt hoặc không hợp lệ
    if ((tp_price_sell >= entryPrice || tp_price_sell == 0) && (stopLoss - entryPrice > 0)) {
        tp_price_sell = entryPrice - (stopLoss - entryPrice) * TakeProfit_RR;
    }
    takeProfit = tp_price_sell; // Gán TP đã tính toán
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(entryPrice, stopLoss, takeProfit, false)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(false, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, price, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.Sell(lotSize, m_Symbol, price, stopLoss, takeProfit, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh SELL - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    // Lưu thông tin metadata
    if (ticket > 0) {
        SavePositionMetadata(ticket, price, stopLoss, takeProfit, lotSize, false, scenario);
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| PlaceBuyLimit - Đặt lệnh Buy Limit                              |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceBuyLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                                ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể đặt lệnh Buy Limit - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá limit hợp lệ (phải thấp hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    if (limitPrice >= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Giá Buy Limit không hợp lệ - Limit: %.5f, Ask: %.5f",
                limitPrice, currentPrice
            ));
        }
        return 0;
    }
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(limitPrice, stopLoss, takeProfit, true)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(true, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY LIMIT - Lot: %.2f, Limit: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, limitPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.BuyLimit(lotSize, limitPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh BUY LIMIT - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    if (ticket > 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh BUY LIMIT thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| PlaceSellLimit - Đặt lệnh Sell Limit                            |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceSellLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                                 ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể đặt lệnh Sell Limit - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá limit hợp lệ (phải cao hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    if (limitPrice <= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Giá Sell Limit không hợp lệ - Limit: %.5f, Bid: %.5f",
                limitPrice, currentPrice
            ));
        }
        return 0;
    }
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(limitPrice, stopLoss, takeProfit, false)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(false, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL LIMIT - Lot: %.2f, Limit: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, limitPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.SellLimit(lotSize, limitPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh SELL LIMIT - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    if (ticket > 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL LIMIT thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| PlaceBuyStop - Đặt lệnh Buy Stop                                |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceBuyStop(double lotSize, double stopPrice, double stopLoss, double takeProfit, 
                               ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể đặt lệnh Buy Stop - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá stop hợp lệ (phải cao hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    if (stopPrice <= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Giá Buy Stop không hợp lệ - Stop: %.5f, Ask: %.5f",
                stopPrice, currentPrice
            ));
        }
        return 0;
    }
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(stopPrice, stopLoss, takeProfit, true)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(true, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY STOP - Lot: %.2f, Stop: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, stopPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.BuyStop(lotSize, stopPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh BUY STOP - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    if (ticket > 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh BUY STOP thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| PlaceSellStop - Đặt lệnh Sell Stop                              |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceSellStop(double lotSize, double stopPrice, double stopLoss, double takeProfit, 
                                ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể đặt lệnh Sell Stop - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá stop hợp lệ (phải thấp hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    if (stopPrice >= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Giá Sell Stop không hợp lệ - Stop: %.5f, Bid: %.5f",
                stopPrice, currentPrice
            ));
        }
        return 0;
    }
    
    // Kiểm tra và điều chỉnh SL/TP nếu cần
    if (!ValidateOrderParameters(stopPrice, stopLoss, takeProfit, false)) {
        return 0;
    }
    
    // Tạo comment nếu cần
    if (comment == "") {
        comment = GenerateOrderComment(false, scenario);
    }
    
    // Thực hiện đặt lệnh
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL STOP - Lot: %.2f, Stop: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, stopPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.SellStop(lotSize, stopPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogError(StringFormat(
                "TradeManager: Lỗi đặt lệnh SELL STOP - Lỗi: %d, Mô tả: %s",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket lệnh
    ulong ticket = m_trade.ResultOrder();
    
    if (ticket > 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL STOP thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| ManageExistingPositions - Quản lý tất cả vị thế đang mở         |
//+------------------------------------------------------------------+
void CTradeManager::ManageExistingPositions(EAContext* context)
{
    // Kiểm tra trạng thái EA
    if (context.EAState != STATE_RUNNING && context.EAState != STATE_REDUCED_RISK) { // Assuming EAState is part of EAContext or accessible via it
        return;
    }
    
    // Kiểm tra chế độ khẩn cấp
    if (context.EmergencyMode || ShouldAdjustForHighVolatility(context.CurrentProfileData)) { // Assuming EmergencyMode and CurrentProfileData are in EAContext
        EmergencyCloseAllPositions("Emergency Exit - Market condition"); // Assuming EmergencyCloseAllPositions is accessible or part of context.TradeManager
        return;
    }
    
    // Lấy danh sách vị thế đang mở
    ulong tickets[];
    if (!m_PositionManager.GetOpenTickets(tickets)) { // Assuming GetOpenTickets is part of PositionManager in context
        return;
    }
    
    int count = ArraySize(tickets);
    if (count == 0) {
        return;
    }
    
    // Xử lý từng vị thế
    for (int i = 0; i < count; i++) {
        ulong ticket = tickets[i];
        
        // Kiểm tra nếu vị thế còn tồn tại
        if (!PositionSelectByTicket(ticket)) {
            continue;
        }
        
        // Lấy thông tin vị thế
        bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
        double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        
        // Kiểm tra và di chuyển đến breakeven nếu cần
        CheckAndMoveToBreakeven(ticket); // Assuming this method is part of CTradeManager or accessible
        
        // Quản lý đóng một phần nếu được bật
        if (context.UsePartialClose) { // Assuming UsePartialClose is in EAContext
            ManagePartialClose(ticket); // Assuming this method is part of CTradeManager or accessible
        }
        
        // Quản lý trailing stop và Market Profile Integration
        if (context.UseAdaptiveTrailing) { // Assuming UseAdaptiveTrailing is in EAContext
            MarketProfileData currentMarketProfile = m_marketProfile->GetLastProfile(); // Lấy thông tin MarketProfile hiện tại, sử dụng -> vì m_marketProfile là con trỏ
            ENUM_MARKET_REGIME regime = currentMarketProfile.regime;
            bool isMarketTransitioning = currentMarketProfile.isTransitioning; // Sử dụng isTransitioning

            // Logic điều chỉnh dựa trên MarketProfile
            if (isMarketTransitioning && PositionGetDouble(POSITION_PROFIT) > 0) {
                // Nếu xu hướng thay đổi và lệnh đang có lời, đóng 30% vị thế
                double volumeToClose = PositionGetDouble(POSITION_VOLUME) * 0.3;
                if (volumeToClose > 0) {
                    ClosePartialPosition(ticket, volumeToClose, "Trend changing - partial close");
                    // Ghi log hoặc thông báo nếu cần
                    if(m_logger != NULL) m_logger->LogInfo(StringFormat("TradeManager: Partial close 30%% for ticket #%d due to market transitioning.", ticket));
                }
            }


            // Áp dụng trailing stop dựa trên regime
            double newSL = CalculateDynamicTrailingStop(ticket, currentPrice, isLong, regime);

            // Thắt chặt Trailing Stop nếu thị trường là REGIME_RANGING_VOLATILE và lệnh có lời
            if (regime == REGIME_RANGING_VOLATILE && PositionGetDouble(POSITION_PROFIT) > 0) {
                double tighterSL = 0;
                if (isLong) {
                    tighterSL = currentPrice - (currentPrice - newSL) * 0.5; // Thắt chặt 50%
                } else {
                    tighterSL = currentPrice + (newSL - currentPrice) * 0.5; // Thắt chặt 50%
                }
                // Đảm bảo SL mới không tệ hơn SL cũ
                if ((isLong && tighterSL > newSL) || (!isLong && tighterSL < newSL)) {
                    newSL = tighterSL;
                    if(m_logger != NULL) m_logger->LogInfo(StringFormat("TradeManager: Trailing stop tightened for ticket #%d due to REGIME_RANGING_VOLATILE.", ticket));
                }
            }
            
            // Kiểm tra SL mới có hợp lệ không
            if (newSL > 0) {
                // Lấy SL hiện tại
                double currentSL = PositionGetDouble(POSITION_SL);
                
                // Kiểm tra nếu cần cập nhật SL (tránh gọi server quá nhiều)
                bool shouldUpdate = false;
                
                if (isLong) {
                    shouldUpdate = (newSL > currentSL + m_MinTrailingStepPoints * m_Point);
                } else {
                    shouldUpdate = (newSL < currentSL - m_MinTrailingStepPoints * m_Point);
                }
                
                // Cập nhật SL nếu cần
                if (shouldUpdate) {
                    SafeModifyStopLoss(ticket, newSL);
                }
            }
        }
        
        // Kiểm tra cơ hội scaling (nhồi lệnh) nếu được bật
        if (m_EnableScaling && IsMarketSuitableForScaling(profile)) {
            CheckAndExecuteScaling(ticket);
        }
    }
}

//+------------------------------------------------------------------+
//| ModifyPosition - Thay đổi SL/TP của vị thế                      |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(ulong ticket, double newSL, double newTP)
{
    // Kiểm tra nếu vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể sửa vị thế - Ticket không tồn tại: " + 
                                 IntegerToString(ticket));
        }
        return false;
    }
    
    // Lấy TP hiện tại nếu newTP = 0
    if (newTP <= 0) {
        newTP = PositionGetDouble(POSITION_TP);
    }
    
    return ProcessModifyRequest(ticket, newSL, newTP);
}

//+------------------------------------------------------------------+
//| ProcessModifyRequest - Xử lý yêu cầu sửa vị thế                 |
//+------------------------------------------------------------------+
bool CTradeManager::ProcessModifyRequest(ulong ticket, double newSL, double newTP)
{
    // Thực hiện sửa vị thế
    if (!m_trade.PositionModify(ticket, newSL, newTP)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Lỗi sửa vị thế #%d - Lỗi: %d, Mô tả: %s",
                ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return false;
    }
    
    // Cập nhật metadata
    UpdatePositionMetadata(ticket, newSL, newTP);
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Sửa vị thế #%d thành công - SL: %.5f, TP: %.5f",
            ticket, newSL, newTP
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ClosePosition - Đóng vị thế với comment                          |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(ulong ticket, string comment)
{
    // Kiểm tra nếu vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể đóng vị thế - Ticket không tồn tại: " + 
                                 IntegerToString(ticket));
        }
        return false;
    }
    
    // Đóng vị thế
    if (!m_trade.PositionClose(ticket)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Lỗi đóng vị thế #%d - Lỗi: %d, Mô tả: %s",
                ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return false;
    }
    
    // Xóa metadata
    RemovePositionMetadata(ticket);
    
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        string logMessage = StringFormat("TradeManager: Đóng vị thế #%d thành công", ticket);
        if (comment != "") {
            logMessage += " - " + comment;
        }
        m_logger->LogInfo(logMessage);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CloseAllPositions - Đóng tất cả vị thế                          |
//+------------------------------------------------------------------+
bool CTradeManager::CloseAllPositions(string reason)
{
    ulong tickets[];
    if (!GetOpenTickets(tickets)) {
        return true;  // Không có vị thế nào để đóng
    }
    
    int count = ArraySize(tickets);
    if (count == 0) {
        return true; 
    }
    
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        m_logger->LogInfo("TradeManager: Đóng tất cả vị thế - " + reason);
    }
    
    // Đóng từng vị thế
    for (int i = 0; i < count; i++) {
        ClosePosition(tickets[i], reason);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CancelAllPendingOrders - Đóng tất cả lệnh chờ                   |
//+------------------------------------------------------------------+
bool CTradeManager::CancelAllPendingOrders(string comment)
{
    // Đếm số lệnh chờ
    int totalOrders = OrdersTotal();
    if (totalOrders <= 0) {
        return true; 
    }
    
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        m_logger->LogInfo("TradeManager: Hủy tất cả lệnh chờ");
    }
    
    // Lặp qua từng lệnh chờ
    for (int i = totalOrders - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if (ticket > 0) {
            // Kiểm tra magic number
            if (OrderGetInteger(ORDER_MAGIC) == m_MagicNumber) {
                // Hủy lệnh
                m_trade.OrderDelete(ticket);
                
                if (m_EnableDetailedLogs) {
                    m_logger->LogInfo("TradeManager: Hủy lệnh chờ #" + IntegerToString(ticket));
                }
            }
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CountOpenPositions - Đếm số lệnh đang mở                        |
//+------------------------------------------------------------------+
int CTradeManager::CountOpenPositions(ENUM_POSITION_TYPE type)
{
    int count = 0;
    int total = PositionsTotal();
    
    for (int i = 0; i < total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;
        
        // Kiểm tra symbol và magic number
        if (PositionGetString(POSITION_SYMBOL) == m_Symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            // Kiểm tra loại vị thế
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            // Nếu type == -1 (mặc định), đếm tất cả
            if (type == -1 || type == posType) {
                count++;
            }
        }
    }
    
    return count;
}

//+------------------------------------------------------------------+
//| HasOpenPosition - Kiểm tra nếu có vị thế đang mở                |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenPosition(ENUM_POSITION_TYPE type)
{
    int total = PositionsTotal();
    
    for (int i = 0; i < total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;
        
        // Kiểm tra symbol và magic number
        if (PositionGetString(POSITION_SYMBOL) == m_Symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            // Kiểm tra loại vị thế
            ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            
            // Nếu type == -1 (mặc định) hoặc khớp loại
            if (type == -1 || type == posType) {
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| GetOpenTickets - Lấy danh sách ticket của các vị thế đang mở    |
//+------------------------------------------------------------------+
bool CTradeManager::GetOpenTickets(ulong &tickets[])
{
    // Xóa mảng cũ
    ArrayFree(tickets);
    
    int total = PositionsTotal();
    if (total <= 0) {
        return false;
    }
    
    // Đếm số vị thế của symbol và magic number hiện tại
    int count = 0;
    for (int i = 0; i < total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;
        
        // Kiểm tra symbol và magic number
        if (PositionGetString(POSITION_SYMBOL) == m_Symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            count++;
        }
    }
    
    // Nếu không có vị thế nào
    if (count <= 0) {
        return false;
    }
    
    // Tạo mảng mới
    ArrayResize(tickets, count);
    
    // Lưu các ticket
    count = 0;
    for (int i = 0; i < total; i++) {
        ulong ticket = PositionGetTicket(i);
        if (ticket <= 0) continue;
        
        // Kiểm tra symbol và magic number
        if (PositionGetString(POSITION_SYMBOL) == m_Symbol && 
            PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
            tickets[count++] = ticket;
        }
    }
    
    return (count > 0);
}

//+------------------------------------------------------------------+
//| GetInitialStopLoss - Lấy SL ban đầu của một vị thế              |
//+------------------------------------------------------------------+
double CTradeManager::GetInitialStopLoss(ulong ticket)
{
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket != 0) {
        return metadata.initialSL;
    }
    
    // Nếu không tìm thấy metadata, trả về SL hiện tại
    if (PositionSelectByTicket(ticket)) {
        return PositionGetDouble(POSITION_SL);
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| GetInitialVolume - Lấy khối lượng ban đầu của một vị thế        |
//+------------------------------------------------------------------+
double CTradeManager::GetInitialVolume(ulong ticket)
{
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket != 0) {
        return metadata.initialVolume;
    }
    
    // Nếu không tìm thấy metadata, trả về volume hiện tại
    if (PositionSelectByTicket(ticket)) {
        return PositionGetDouble(POSITION_VOLUME);
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| GetPositionRRatio - Lấy tỷ lệ R hiện tại của vị thế             |
//+------------------------------------------------------------------+
double CTradeManager::GetPositionRRatio(ulong ticket)
{
    return GetCurrentRR(ticket);
}

//+------------------------------------------------------------------+
//| GetScalingCount - Lấy số lần nhồi lệnh đã thực hiện             |
//+------------------------------------------------------------------+
int CTradeManager::GetScalingCount(ulong ticket)
{
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket != 0) {
        return metadata.scalingCount;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| ProcessTradeTransaction - Xử lý sự kiện giao dịch                |
//+------------------------------------------------------------------+
void CTradeManager::ProcessTradeTransaction(const MqlTradeTransaction &trans)
{
    // Chỉ xử lý các giao dịch của EA (cùng magic number)
    if (trans.magic != m_MagicNumber) {
        return;
    }
    
    // Xử lý theo loại giao dịch
    switch (trans.type) {
        // Khi có lệnh mới được thêm vào
        case TRADE_TRANSACTION_ORDER_ADD:
            if (m_EnableDetailedLogs) {
                m_logger->LogInfo(StringFormat(
                    "TradeManager: Lệnh mới #%d được thêm vào - Loại: %s",
                    trans.order, EnumToString((ENUM_ORDER_TYPE)trans.order_type)
                ));
            }
            break;
        
        // Khi có lệnh chờ được kích hoạt
        case TRADE_TRANSACTION_DEAL_ADD:
            // Xử lý giao dịch đóng
            if (trans.deal_type == DEAL_TYPE_SELL && trans.order_type == ORDER_TYPE_CLOSE_BY) {
                HandleCloseDeal(trans.position, trans.price, trans.profit);
            }
            else if (trans.deal_type == DEAL_TYPE_BUY && trans.order_type == ORDER_TYPE_CLOSE_BY) {
                HandleCloseDeal(trans.position, trans.price, trans.profit);
            }
            break;
        
        default:
            break;
    }
}

//+------------------------------------------------------------------+
//| UpdateEAState - Cập nhật trạng thái EA                          |
//+------------------------------------------------------------------+
void CTradeManager::UpdateEAState(ENUM_EA_STATE newState, datetime pauseUntil)
{
    // Cập nhật trạng thái
    m_EAState = newState;
    
    // Cập nhật cờ hoạt động
    m_IsActive = (newState == STATE_RUNNING || newState == STATE_REDUCED_RISK);
    
    // Cập nhật thời gian tạm dừng nếu cần
    if (newState == STATE_PAUSED && pauseUntil > 0) {
        m_PauseUntil = pauseUntil;
    }
    
    // Log thông tin
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        string stateStr = EnumToString(newState);
        
        // Thêm thông tin thời gian tạm dừng nếu có
        if (newState == STATE_PAUSED && pauseUntil > 0) {
            stateStr += " - đến " + TimeToString(pauseUntil, TIME_DATE|TIME_MINUTES);
        }
        
        m_logger->LogInfo("TradeManager: Trạng thái EA đã được cập nhật - " + stateStr);
    }
}

//+------------------------------------------------------------------+
//| ShouldAdjustForHighVolatility - Kiểm tra cần thoát khẩn cấp     |
//+------------------------------------------------------------------+
bool CTradeManager::ShouldAdjustForHighVolatility(const MarketProfileData &profile)
{
    // Đã ở chế độ khẩn cấp
    if (m_EmergencyMode) {
        return true;
    }
    
    // Kiểm tra volatility cực cao
    if (profile.atrRatio > 3.0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Phát hiện volatility cực cao - ATR Ratio: %.2f",
                profile.atrRatio
            ));
        }
        m_EmergencyMode = true;
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| EmergencyCloseAllPositions - Đóng tất cả vị thế khẩn cấp        |
//+------------------------------------------------------------------+
void CTradeManager::EmergencyCloseAllPositions(string reason)
{
    // Đặt cờ khẩn cấp
    m_EmergencyMode = true;
    
    // Đóng tất cả vị thế
    CloseAllPositions("EMERGENCY: " + reason);
    
    // Hủy tất cả lệnh chờ
    CancelAllPendingOrders("EMERGENCY: " + reason);
    
    // Log cảnh báo
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        m_logger->LogWarning("TradeManager: Kích hoạt EMERGENCY EXIT - " + reason);
    }
}

//+------------------------------------------------------------------+
//| SavePositionMetadata - Lưu metadata của vị thế                  |
//+------------------------------------------------------------------+
void CTradeManager::SavePositionMetadata(ulong ticket, double entryPrice, double stopLoss, 
                                      double takeProfit, double volume, bool isLong, 
                                      ENUM_ENTRY_SCENARIO scenario)
{
    // Tạo đối tượng metadata mới 
    ApexPullback::PositionMetadata* metadata = new ApexPullback::PositionMetadata();
    if (metadata == NULL) {
        if (m_EnableDetailedLogs) {
            m_logger->LogError("TradeManager: Không thể tạo metadata cho vị thế #" + 
                           IntegerToString(ticket));
        }
        return;
    }
    
    // Khởi tạo giá trị mặc định
    metadata->Initialize();
    
    // Điền thông tin
    metadata->ticket = ticket;
    metadata->initialSL = stopLoss;
    metadata->initialTP = takeProfit;
    metadata->initialVolume = volume;
    metadata->entryPrice = entryPrice;
    metadata->isLong = isLong;
    metadata->entryTime = TimeCurrent();
    metadata->scenario = scenario;
    
    metadata->isBreakeven = false;
    metadata->isPartialClosed1 = false;
    metadata->isPartialClosed2 = false;
    metadata->scalingCount = 0;
    
    metadata->lastTrailingTime = 0;
    metadata->lastTrailingSL = stopLoss;
    
    // Thêm vào mảng
    m_PositionsMetadata.Add(metadata);
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đã lưu metadata cho vị thế #%d - Entry: %.5f, SL: %.5f, TP: %.5f",
            ticket, entryPrice, stopLoss, takeProfit
        ));
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionMetadata - Cập nhật metadata của vị thế           |
//+------------------------------------------------------------------+
bool CTradeManager::UpdatePositionMetadata(ulong ticket, double newSL, double newTP)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                // Cập nhật SL/TP nếu cần
                if (newSL > 0) {
                    metadata->lastTrailingSL = newSL;
                    metadata->lastTrailingTime = TimeCurrent();
                }
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| GetPositionMetadata - Lấy metadata của vị thế                   |
//+------------------------------------------------------------------+
ApexPullback::PositionMetadata CTradeManager::GetPositionMetadata(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                return *metadata;
            }
        }
    }
    
    // Trả về struct rỗng nếu không tìm thấy
    ApexPullback::PositionMetadata emptyMetadata;
    return emptyMetadata;
}

//+------------------------------------------------------------------+
//| RemovePositionMetadata - Xóa metadata của vị thế                |
//+------------------------------------------------------------------+
void CTradeManager::RemovePositionMetadata(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                m_PositionsMetadata.Delete(i);
                if (m_EnableDetailedLogs) {
                    m_logger->LogInfo("TradeManager: Đã xóa metadata cho vị thế #" + 
                                  IntegerToString(ticket));
                }
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| ClearAllMetadata - Xóa tất cả metadata                          |
//+------------------------------------------------------------------+
void CTradeManager::ClearAllMetadata()
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = total - 1; i >= 0; i--) {
        m_PositionsMetadata.Delete(i);
    }
    
    m_PositionsMetadata.Clear();
    
    if (m_EnableDetailedLogs) {
        m_logger->LogInfo("TradeManager: Đã xóa tất cả metadata");
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionMetadataPartialClose1 - Cập nhật partial close 1  |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionMetadataPartialClose1(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                metadata->isPartialClosed1 = true;
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionMetadataPartialClose2 - Cập nhật partial close 2  |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionMetadataPartialClose2(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                metadata->isPartialClosed2 = true;
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionMetadataBreakeven - Cập nhật breakeven            |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionMetadataBreakeven(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata->ticket == ticket) {
                metadata->isBreakeven = true;
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| UpdatePositionMetadataScaling - Cập nhật scaling count          |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionMetadataScaling(ulong ticket)
{
    int total = m_PositionsMetadata.Total();
    
    for (int i = 0; i < total; i++) {
        ApexPullback::PositionMetadata* metadata = (ApexPullback::PositionMetadata*)m_PositionsMetadata.At(i);
        if (metadata != NULL) {
            if (metadata.ticket == ticket) {
                metadata.scalingCount++;
                return;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateDynamicTrailingStop - Tính trailing stop thích ứng     |
//+------------------------------------------------------------------+
double CTradeManager::CalculateDynamicTrailingStop(ulong ticket, double currentPrice, bool isLong, ENUM_MARKET_REGIME regime)
{
    // Kiểm tra tham số
    if (currentPrice <= 0) {
        return 0;
    }
    
    // Lấy metadata vị thế
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return 0;
    }
    
    // Lấy ATR hiện tại
    double atr = GetCurrentATR();
    if (atr <= 0) {
        return 0;
    }
    
    // Chọn phương pháp trailing dựa trên chế độ và regime
    double trailingStop = 0;
    
    if (m_UseAdaptiveTrailing) {
        // Trailing thích ứng theo regime
        switch (regime) {
            case REGIME_TRENDING:
                // Trong xu hướng mạnh: Dùng Chandelier Exit để vẫn theo được trend dài
                if (m_UseChandelierExit) {
                    trailingStop = CalculateChandelierExit(isLong, m_ChandelierLookback, m_ChandelierATRMultiplier);
                } else {
                    // Trailing với ATR lớn hơn để theo xu hướng dài
                    trailingStop = CalculateTrailingStopATR(currentPrice, isLong, atr * 1.2);
                }
                break;
                
            case REGIME_RANGING:
                // Trong sideway: Kết hợp ATR và Swing Points
                double atrTrail = CalculateTrailingStopATR(currentPrice, isLong, atr);
                double swingTrail = CalculateTrailingStopSwing(isLong);
                
                // Chọn trailing tốt hơn
                if (isLong) {
                    trailingStop = MathMax(atrTrail, swingTrail);
                } else {
                    trailingStop = MathMin(atrTrail, swingTrail);
                }
                break;
                
            case REGIME_VOLATILE:
                // Trong thị trường biến động: ATR chặt chẽ hơn để bảo vệ lợi nhuận
                trailingStop = CalculateTrailingStopATR(currentPrice, isLong, atr * 0.8);
                break;
                
            default:
                // Mặc định: Trailing Stop ATR
                trailingStop = CalculateTrailingStopATR(currentPrice, isLong, atr);
                break;
        }
    } else {
        // Sử dụng trailing stop cố định theo chế độ
        switch (m_TrailingMode) {
            case TRAILING_ATR:
                trailingStop = CalculateTrailingStopATR(currentPrice, isLong, atr);
                break;
                
            case TRAILING_CHANDELIER:
                trailingStop = CalculateChandelierExit(isLong, m_ChandelierLookback, m_ChandelierATRMultiplier);
                break;
                
            case TRAILING_SWING_POINTS:
                trailingStop = CalculateTrailingStopSwing(isLong);
                break;
                
            case TRAILING_EMA:
                trailingStop = CalculateTrailingStopEMA(isLong);
                break;
                
            case TRAILING_PSAR:
                trailingStop = CalculateTrailingStopPSAR(isLong);
                break;
                
            case TRAILING_NONE:
                // Không dùng trailing
                return 0;
                
            default:
                // Mặc định: Trailing Stop ATR
                trailingStop = CalculateTrailingStopATR(currentPrice, isLong, atr);
                break;
        }
    }
    
    // Kiểm tra stopLoss hợp lệ
    if (trailingStop <= 0) {
        return 0;
    }
    
    // Đảm bảo trailing stop không thể lùi
    double currentSL = PositionGetDouble(POSITION_SL);
    if (currentSL > 0) {
        if (isLong && trailingStop < currentSL) {
            trailingStop = currentSL;
        } else if (!isLong && trailingStop > currentSL) {
            trailingStop = currentSL;
        }
    }
    
    // Nếu vị thế đã đạt breakeven, đảm bảo SL không thấp hơn giá vào
    if (metadata.isBreakeven) {
        double entryPrice = metadata.entryPrice;
        
        // Thêm buffer nếu có
        if (m_BreakEvenBuffer > 0) {
            if (isLong) {
                entryPrice += m_BreakEvenBuffer * m_Point;
            } else {
                entryPrice -= m_BreakEvenBuffer * m_Point;
            }
        }
        
        // Đảm bảo SL đã đạt breakeven
        if (isLong && trailingStop < entryPrice) {
            trailingStop = entryPrice;
        } else if (!isLong && trailingStop > entryPrice) {
            trailingStop = entryPrice;
        }
    }
    
    return NormalizeDouble(trailingStop, m_Digits);
}

//+------------------------------------------------------------------+
//| CalculateTrailingStopATR - Tính trailing stop dựa trên ATR      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopATR(double currentPrice, bool isLong, double atr)
{
    if (currentPrice <= 0 || atr <= 0) {
        return 0;
    }
    
    double trailingStop = 0;
    
    if (isLong) {
        trailingStop = currentPrice - atr * m_TrailingATRMultiplier;
    } else {
        trailingStop = currentPrice + atr * m_TrailingATRMultiplier;
    }
    
    return NormalizeDouble(trailingStop, m_Digits);
}

//+------------------------------------------------------------------+
//| CalculateTrailingStopSwing - Tính trailing stop dựa trên Swing  |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopSwing(bool isLong)
{
    if (m_swingDetector == NULL) {
        return 0;
    }
    
    double trailingStop = 0;
    
    if (isLong) {
        // Lấy swing low gần nhất
        double swingLow = m_swingDetector->GetLastSwingLow();
        if (swingLow <= 0) {
            return 0;
        }
        
        // Điều chỉnh buffer
        double buffer = m_Point * 5;
        trailingStop = swingLow - buffer;
    } else {
        // Lấy swing high gần nhất
        double swingHigh = m_swingDetector->GetLastSwingHigh();
        if (swingHigh <= 0) {
            return 0;
        }
        
        // Điều chỉnh buffer
        double buffer = m_Point * 5;
        trailingStop = swingHigh + buffer;
    }
    
    return NormalizeDouble(trailingStop, m_Digits);
}

//+------------------------------------------------------------------+
//| CalculateTrailingStopEMA - Tính trailing stop dựa trên EMA      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopEMA(bool isLong)
{
    // Lấy giá trị EMA34
    double ema34 = GetEMAValue(m_handleEMA34);
    if (ema34 <= 0) {
        return 0;
    }
    
    // Sử dụng EMA làm trailing stop
    double trailingStop = ema34;
    
    return NormalizeDouble(trailingStop, m_Digits);
}

//+------------------------------------------------------------------+
//| CalculateTrailingStopPSAR - Tính trailing stop dựa trên PSAR    |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopPSAR(bool isLong)
{
    if (m_handlePSAR == INVALID_HANDLE) {
        return 0;
    }
    
    // Lấy giá trị PSAR
    double psarBuffer[];
    ArraySetAsSeries(psarBuffer, true);
    
    if (CopyBuffer(m_handlePSAR, 0, 0, 1, psarBuffer) <= 0) {
        return 0;
    }
    
    double psar = psarBuffer[0];
    if (psar <= 0) {
        return 0;
    }
    
    // Kiểm tra PSAR có phù hợp với chiều lệnh không
    double currentPrice = 0;
    if (isLong) {
        currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
        // PSAR phải thấp hơn giá hiện tại
        if (psar >= currentPrice) {
            return 0;
        }
    } else {
        currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
        // PSAR phải cao hơn giá hiện tại
        if (psar <= currentPrice) {
            return 0;
        }
    }
    
    return NormalizeDouble(psar, m_Digits);
}

//+------------------------------------------------------------------+
//| CalculateChandelierExit - Tính Chandelier Exit                  |
//+------------------------------------------------------------------+
double CTradeManager::CalculateChandelierExit(bool isLong, int period, double multiplier)
{
    // Lấy ATR
    double atr = GetCurrentATR();
    if (atr <= 0) {
        return 0;
    }
    
    // Lấy dữ liệu giá
    double highBuffer[];
    double lowBuffer[];
    
    ArraySetAsSeries(highBuffer, true);
    ArraySetAsSeries(lowBuffer, true);
    
    if (CopyHigh(m_Symbol, PERIOD_CURRENT, 0, period, highBuffer) <= 0 ||
        CopyLow(m_Symbol, PERIOD_CURRENT, 0, period, lowBuffer) <= 0) {
        return 0;
    }
    
    // Tìm high/low trong period
    double highestHigh = highBuffer[ArrayMaximum(highBuffer, 0, period)];
    double lowestLow = lowBuffer[ArrayMinimum(lowBuffer, 0, period)];
    
    double chandelierExit = 0;
    
    if (isLong) {
        // Long: Highest High - ATR * multiplier
        chandelierExit = highestHigh - (atr * multiplier);
    } else {
        // Short: Lowest Low + ATR * multiplier
        chandelierExit = lowestLow + (atr * multiplier);
    }
    
    return NormalizeDouble(chandelierExit, m_Digits);
}

//+------------------------------------------------------------------+
//| ManagePartialClose - Quản lý đóng một phần vị thế               |
//+------------------------------------------------------------------+
bool CTradeManager::ManagePartialClose(ulong ticket)
{
    // Kiểm tra nếu đóng một phần được bật
    if (!m_UsePartialClose) {
        return false;
    }
    
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy metadata
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return false;
    }
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    double entryPrice = metadata.entryPrice;
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    double initialVolume = metadata.initialVolume;
    
    // Tính R hiện tại
    double currentR = GetCurrentRR(ticket);
    
    // Kiểm tra đủ khối lượng để đóng một phần
    if (currentVolume < initialVolume * 0.1) {
        return false;
    }
    
    // Kiểm tra TP1
    if (!metadata.isPartialClosed1 && currentR >= m_PartialCloseR1) {
        // Tính khối lượng đóng
        double closeVolume = NormalizeDouble(initialVolume * m_PartialClosePercent1 / 100.0, 2);
        
        // Kiểm tra khối lượng hợp lệ
        if (closeVolume > 0 && closeVolume < currentVolume) {
            // Đóng một phần
            if (SafeClosePartial(ticket, closeVolume, "TP1")) {
                // Cập nhật metadata trực tiếp trong array
                UpdatePositionMetadataPartialClose1(ticket);
                
                // Kiểm tra và đưa SL về breakeven
                if (!metadata.isBreakeven) {
                    double beLevel = entryPrice;
                    if (m_BreakEvenBuffer > 0) {
                        if (isLong) {
                            beLevel += m_BreakEvenBuffer * m_Point;
                        } else {
                            beLevel -= m_BreakEvenBuffer * m_Point;
                        }
                    }
                    
                    if (SafeModifyStopLoss(ticket, beLevel)) {
                        UpdatePositionMetadataBreakeven(ticket);
                    }
                }
                
                return true;
            }
        }
    }
    
    // Kiểm tra TP2
    if (metadata.isPartialClosed1 && !metadata.isPartialClosed2 && currentR >= m_PartialCloseR2) {
        // Tính khối lượng đóng
        double closeVolume = NormalizeDouble(initialVolume * m_PartialClosePercent2 / 100.0, 2);
        
        // Kiểm tra khối lượng hợp lệ
        if (closeVolume > 0 && closeVolume < currentVolume) {
            // Đóng một phần
            if (SafeClosePartial(ticket, closeVolume, "TP2")) {
                // Cập nhật metadata
                UpdatePositionMetadataPartialClose2(ticket);
                
                // Siết chặt trailing stop
                double currentSL = PositionGetDouble(POSITION_SL);
                double atr = GetCurrentATR();
                
                if (atr > 0) {
                    double tightTrailing = 0;
                    if (isLong) {
                        tightTrailing = currentPrice - atr * 1.0;
                        
                        // Đảm bảo SL mới tốt hơn SL hiện tại
                        if (tightTrailing > currentSL) {
                            SafeModifyStopLoss(ticket, tightTrailing);
                        }
                    } else {
                        tightTrailing = currentPrice + atr * 1.0;
                        
                        // Đảm bảo SL mới tốt hơn SL hiện tại
                        if (tightTrailing < currentSL) {
                            SafeModifyStopLoss(ticket, tightTrailing);
                        }
                    }
                }
                
                return true;
            }
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| SafeClosePartial - Đóng một phần vị thế an toàn                 |
//+------------------------------------------------------------------+
bool CTradeManager::SafeClosePartial(ulong ticket, double partialLots, string partialComment)
{
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy thông tin lệnh
    string symbol = PositionGetString(POSITION_SYMBOL);
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    
    // Kiểm tra khối lượng hợp lệ
    if (partialLots <= 0 || partialLots >= currentVolume) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Khối lượng đóng một phần không hợp lệ - Lệnh: #%d, Khối lượng: %.2f, Hiện tại: %.2f",
                ticket, partialLots, currentVolume
            ));
        }
        return false;
    }
    
    // Đóng một phần vị thế
    if (!m_trade.PositionClosePartial(ticket, partialLots)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Lỗi đóng một phần vị thế #%d - Lỗi: %d, Mô tả: %s",
                ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return false;
    }
    
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Đóng một phần vị thế #%d thành công - Khối lượng: %.2f, Lý do: %s",
            ticket, partialLots, partialComment
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| CheckAndExecuteScaling - Kiểm tra và thực hiện nhồi lệnh        |
//+------------------------------------------------------------------+
bool CTradeManager::CheckAndExecuteScaling(ulong ticket)
{
    // Kiểm tra nếu nhồi lệnh được bật
    if (!m_EnableScaling) {
        return false;
    }
    
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy metadata
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return false;
    }
    
    // Kiểm tra số lần nhồi lệnh đã thực hiện
    if (metadata.scalingCount >= m_MaxScalingCount) {
        return false;
    }
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    double entryPrice = metadata.entryPrice;
    
    // Kiểm tra phiên hiện tại có thích hợp cho scaling
    if (!IsCurrentSessionSuitableForScaling()) {
        return false;
    }
    
    // Lấy profile thị trường
    MarketProfileData profile;
    if (m_marketProfile != NULL) {
        profile = m_marketProfile.GetLastProfile();
    }
    
    // Kiểm tra điều kiện nhồi lệnh
    if (ShouldScaleInPosition(ticket, currentPrice, entryPrice, isLong, profile)) {
        // Thực hiện nhồi lệnh
        if (ExecuteScalingOrder(ticket, currentPrice, isLong)) {
            // Cập nhật số lần nhồi lệnh
            UpdatePositionMetadataScaling(ticket);
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| ShouldScaleInPosition - Kiểm tra nếu nên nhồi lệnh              |
//+------------------------------------------------------------------+
bool CTradeManager::ShouldScaleInPosition(ulong ticket, double currentPrice, double entryPrice, bool isLong, const MarketProfileData &profile)
{
    // NGUYÊN TẮC: Chỉ scaling khi có lý do cực kỳ thuyết phục
    
    // Kiểm tra điều kiện cơ bản
    if (!m_EnableScaling || m_MaxScalingCount <= 0) {
        return false;
    }
    
    // Lấy metadata
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return false;
    }
    
    // Kiểm tra số lần nhồi lệnh đã thực hiện
    if (metadata.scalingCount >= m_MaxScalingCount) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug(StringFormat(
                "TradeManager: Scaling bị từ chối - Đã đạt giới hạn nhồi lệnh: %d",
                m_MaxScalingCount
            ));
        }
        return false;
    }
    
    // Kiểm tra nếu SL đã ở breakeven (nếu yêu cầu)
    if (m_RequireBEForScaling && !metadata.isBreakeven) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Scaling bị từ chối - Vị thế chưa đạt breakeven");
        }
        return false;
    }
    
    // Lấy thông tin vị thế hiện tại
    double currentSL = PositionGetDouble(POSITION_SL);
    double initialSL = metadata.initialSL;
    
    // Tính R hiện tại
    double rMultiple = 0;
    if (isLong) {
        rMultiple = (entryPrice - initialSL != 0) ? (currentPrice - entryPrice) / (entryPrice - initialSL) : 0;
    } else {
        rMultiple = (initialSL - entryPrice != 0) ? (entryPrice - currentPrice) / (initialSL - entryPrice) : 0;
    }
    
    // Kiểm tra vị thế đang lời ít nhất 1R
    if (rMultiple < 1.0) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug(StringFormat(
                "TradeManager: Scaling bị từ chối - Vị thế chưa đạt 1R (hiện tại: %.2fR)",
                rMultiple
            ));
        }
        return false;
    }
    
    // Kiểm tra chế độ thị trường thích hợp
    if (profile.regime != REGIME_TRENDING) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Scaling bị từ chối - Thị trường không trong xu hướng");
        }
        return false;
    }
    
    // Kiểm tra pullback hợp lệ
    bool validPullback = false;
    
    // Sử dụng SwingDetector nếu có
    if (m_swingDetector != NULL) {
        double lastSwingPrice = 0;
        
        if (isLong) {
            lastSwingPrice = m_swingDetector.GetLastSwingLow();
            
            // Pullback hợp lệ nếu:
            // 1. Giá hiện tại đã pullback đến gần mức swing low
            // 2. Swing low vẫn cao hơn entry price (tránh pullback quá sâu)
            // 3. Swing low cao hơn SL hiện tại
            
            if (lastSwingPrice > 0 && 
                lastSwingPrice > entryPrice && 
                lastSwingPrice > currentSL &&
                MathAbs(currentPrice - lastSwingPrice) < GetCurrentATR() * 0.3) {
                validPullback = true;
            }
        } else {
            lastSwingPrice = m_swingDetector.GetLastSwingHigh();
            
            // Pullback hợp lệ nếu:
            // 1. Giá hiện tại đã pullback đến gần mức swing high
            // 2. Swing high vẫn thấp hơn entry price (tránh pullback quá cao)
            // 3. Swing high thấp hơn SL hiện tại
            
            if (lastSwingPrice > 0 && 
                lastSwingPrice < entryPrice && 
                lastSwingPrice < currentSL &&
                MathAbs(currentPrice - lastSwingPrice) < GetCurrentATR() * 0.3) {
                validPullback = true;
            }
        }
    } else {
        // Pullback đơn giản dựa trên entry price và SL
        if (isLong) {
            // Pullback ít nhất 30% và không quá 60% lợi nhuận hiện tại
            double profit = currentPrice - entryPrice;
            double pullback = MathMax(0, currentPrice - SymbolInfoDouble(m_Symbol, SYMBOL_ASK));
            
            validPullback = (pullback >= profit * 0.3 && pullback <= profit * 0.6);
        } else {
            // Pullback ít nhất 30% và không quá 60% lợi nhuận hiện tại
            double profit = entryPrice - currentPrice;
            double pullback = MathMax(0, SymbolInfoDouble(m_Symbol, SYMBOL_BID) - currentPrice);
            
            validPullback = (pullback >= profit * 0.3 && pullback <= profit * 0.6);
        }
    }
    
    if (!validPullback) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Scaling bị từ chối - Không có pullback hợp lệ");
        }
        return false;
    }
    
    // Kiểm tra không có tin tức sắp diễn ra
    if (m_newsFilter != NULL && m_newsFilter.HasUpcomingNews()) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Scaling bị từ chối - Có tin tức sắp diễn ra");
        }
        return false;
    }
    
    // Tất cả điều kiện thỏa mãn . cho phép nhồi lệnh
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        m_logger->LogInfo(StringFormat(
            "TradeManager: Điều kiện nhồi lệnh thỏa mãn cho vị thế #%d - R: %.2f, Pullback hợp lệ: %s",
            ticket, rMultiple, validPullback ? "Có" : "Không"
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ExecuteScalingOrder - Thực hiện nhồi lệnh                       |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteScalingOrder(ulong ticket, double scalingPrice, bool isLong)
{
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy thông tin vị thế hiện tại
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    
    // Kiểm tra SL/TP hợp lệ
    if (currentSL <= 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Không thể nhồi lệnh - SL không hợp lệ");
        }
        return false;
    }
    
    // Tính toán risk cho lệnh nhồi
    double slPoints = MathAbs(scalingPrice - currentSL) / m_Point;
    
    // Kiểm tra khoảng cách SL
    if (slPoints < 10) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Không thể nhồi lệnh - Khoảng cách SL quá nhỏ: %.1f điểm",
                slPoints
            ));
        }
        return false;
    }
    
    // Lấy risk % từ RiskManager
    double baseRisk = 1.0;
    if (m_riskManager != NULL) {
        baseRisk = m_riskManager.GetCurrentRiskPercent();
    }
    
    // Sử dụng risk thấp hơn cho lệnh nhồi
    double scalingRisk = baseRisk * m_ScalingRiskPercent;
    
    // Tính lot size cho lệnh nhồi
    double lotSize = 0;
    if (m_riskOptimizer != NULL) {
        lotSize = m_riskOptimizer->CalculateLotSizeByRisk(m_symbol, slPoints, scalingRisk);
    } else {
        // Fallback: sử dụng 50% lot size của lệnh gốc
        lotSize = PositionGetDouble(POSITION_VOLUME) * 0.5;
    }
    
    // Kiểm tra lot size hợp lệ
    if (lotSize <= 0) {
        if (m_EnableDetailedLogs) {
            m_logger->LogWarning("TradeManager: Không thể nhồi lệnh - Lot size không hợp lệ");
        }
        return false;
    }
    
    // Tạo comment cho lệnh nhồi
    string comment = "Scale-in for #" + IntegerToString(ticket);
    
    // Thực hiện lệnh nhồi
    ulong scalingTicket = 0;
    
    if (isLong) {
        scalingTicket = OpenBuy(lotSize, currentSL, currentTP, SCENARIO_SCALING, comment);
    } else {
        scalingTicket = OpenSell(lotSize, currentSL, currentTP, SCENARIO_SCALING, comment);
    }
    
    if (scalingTicket > 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Nhồi lệnh thành công - Ticket: #%d cho vị thế #%d, Lot: %.2f",
                scalingTicket, ticket, lotSize
            ));
        }
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| CheckAndMoveToBreakeven - Kiểm tra và đưa SL về breakeven       |
//+------------------------------------------------------------------+
bool CTradeManager::CheckAndMoveToBreakeven(ulong ticket)
{
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy metadata
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return false;
    }
    
    // Kiểm tra đã đạt breakeven chưa
    if (metadata.isBreakeven) {
        return false;
    }
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    double entryPrice = metadata.entryPrice;
    double initialSL = metadata.initialSL;
    
    // Tính R-multiple hiện tại
    double currentR = 0;
    if (isLong) {
        if (entryPrice > initialSL) {
            currentR = (currentPrice - entryPrice) / (entryPrice - initialSL);
        }
    } else {
        if (initialSL > entryPrice) {
            currentR = (entryPrice - currentPrice) / (initialSL - entryPrice);
        }
    }
    
    // Kiểm tra đã đạt ngưỡng breakeven
    if (currentR >= m_BreakEvenR) {
        // Tính mức breakeven với buffer
        double beLevel = entryPrice;
        
        // Thêm buffer nếu có
        if (m_BreakEvenBuffer > 0) {
            if (isLong) {
                beLevel += m_BreakEvenBuffer * m_Point;
            } else {
                beLevel -= m_BreakEvenBuffer * m_Point;
            }
        }
        
        // Kiểm tra SL hiện tại
        double currentSL = PositionGetDouble(POSITION_SL);
        bool needUpdate = false;
        
        if (isLong) {
            needUpdate = (beLevel > currentSL + m_MinTrailingStepPoints * m_Point);
        } else {
            needUpdate = (beLevel < currentSL - m_MinTrailingStepPoints * m_Point);
        }
        
        if (needUpdate) {
            // Đưa SL về breakeven
            if (SafeModifyStopLoss(ticket, beLevel)) {
                // Cập nhật metadata
                UpdatePositionMetadataBreakeven(ticket);
                
                // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
                    m_logger->LogInfo(StringFormat(
                        "TradeManager: Đã đưa SL về breakeven cho vị thế #%d - Entry: %.5f, BE: %.5f, R: %.2f",
                        ticket, entryPrice, beLevel, currentR
                    ));
                }
                
                return true;
            }
        } else {
            // SL đã ở mức tốt hơn breakeven
            UpdatePositionMetadataBreakeven(ticket);
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| GetCurrentRR - Lấy tỷ số R hiện tại                             |
//+------------------------------------------------------------------+
double CTradeManager::GetCurrentRR(ulong ticket)
{
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return 0;
    }
    
    // Lấy metadata
    PositionMetadata metadata = GetPositionMetadata(ticket);
    if (metadata.ticket == 0) {
        return 0;
    }
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
    double entryPrice = metadata.entryPrice;
    double initialSL = metadata.initialSL;
    
    // Tính R-multiple hiện tại
    double currentR = 0;
    
    // Tính khoảng cách risk ban đầu
    double riskDistance = MathAbs(entryPrice - initialSL);
    
    if (riskDistance > 0) {
        if (isLong) {
            // Lệnh buy: R = (CurrentPrice - EntryPrice) / RiskDistance
            currentR = (currentPrice - entryPrice) / riskDistance;
        } else {
            // Lệnh sell: R = (EntryPrice - CurrentPrice) / RiskDistance
            currentR = (entryPrice - currentPrice) / riskDistance;
        }
    }
    
    return currentR;
}

//+------------------------------------------------------------------+
//| HasReachedRTarget - Kiểm tra nếu vị thế đã đạt mục tiêu R       |
//+------------------------------------------------------------------+
bool CTradeManager::HasReachedRTarget(ulong ticket, double rTarget)
{
    // Lấy R hiện tại
    double currentR = GetCurrentRR(ticket);
    
    // So sánh với mục tiêu
    return (currentR >= rTarget);
}

//+------------------------------------------------------------------+
//| SafeModifyStopLoss - Thực hiện thay đổi SL an toàn              |
//+------------------------------------------------------------------+
bool CTradeManager::SafeModifyStopLoss(ulong ticket, double newSL)
{
    // Kiểm tra vị thế tồn tại
    if (!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Lấy thông tin vị thế
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    
    // Kiểm tra nếu cần thay đổi SL
    bool needUpdate = false;
    if (isLong) {
        needUpdate = (newSL > currentSL + m_MinTrailingStepPoints * m_Point);
    } else {
        needUpdate = (newSL < currentSL - m_MinTrailingStepPoints * m_Point);
    }
    
    if (!needUpdate) {
        return false;
    }
    
    // Thực hiện sửa vị thế
    if (!ProcessModifyRequest(ticket, newSL, currentTP)) {
        return false;
    }
    
    // Cập nhật thông tin trailing stop
    UpdateLastTrailingInfo(ticket, newSL);
    
    return true;
}

//+------------------------------------------------------------------+
//| UpdateLastTrailingInfo - Cập nhật thông tin trailing mới nhất   |
//+------------------------------------------------------------------+
void CTradeManager::UpdateLastTrailingInfo(ulong ticket, double newSL)
{
    // Cập nhật thông tin trailing sử dụng function có sẵn
    UpdatePositionMetadata(ticket, newSL);
}

//+------------------------------------------------------------------+
//| CalculateAdaptiveStopLoss - Tính SL thích ứng với AssetProfiler |
//+------------------------------------------------------------------+
double CTradeManager::CalculateAdaptiveStopLoss(bool isLong, double entryPrice)
{
    // Sử dụng AssetProfiler nếu có
    if (m_assetProfiler != NULL) {
        double atr = m_assetProfiler.GetAverageATR();
        double volatilityFactor = m_assetProfiler.GetVolatilityFactor();
        
        // Điều chỉnh SL dựa trên volatility của asset
        double slDistance = atr * StopLoss_ATR * volatilityFactor;
        
        if (isLong) {
            return NormalizeDouble(entryPrice - slDistance, m_Digits);
        } else {
            return NormalizeDouble(entryPrice + slDistance, m_Digits);
        }
    } else {
        // Fallback: sử dụng ATR thông thường
        double atr = GetCurrentATR();
        if (atr <= 0) {
            // Nếu không có ATR, dùng giá trị mặc định
            double defaultSL = entryPrice * 0.01;
            if (isLong) {
                return NormalizeDouble(entryPrice - defaultSL, m_Digits);
            } else {
                return NormalizeDouble(entryPrice + defaultSL, m_Digits);
            }
        }
        
        if (isLong) {
            return NormalizeDouble(entryPrice - atr * m_TrailingATRMultiplier, m_Digits);
        } else {
            return NormalizeDouble(entryPrice + atr * m_TrailingATRMultiplier, m_Digits);
        }
    }
}

//+------------------------------------------------------------------+
//| CalculateAdaptiveTakeProfit - Tính TP thích ứng với Regime      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateAdaptiveTakeProfit(bool isLong, double entryPrice, double stopLoss, ENUM_MARKET_REGIME regime)
{
    // Tính khoảng cách SL
    double slDistance = MathAbs(entryPrice - stopLoss);
    
    // Lấy tỷ lệ TP:SL tối ưu dựa trên regime
    double tpRatio = CalculateOptimalTakeProfitRatio(regime);
    
    // Tính TP
    if (isLong) {
        return NormalizeDouble(entryPrice + slDistance * tpRatio, m_Digits);
    } else {
        return NormalizeDouble(entryPrice - slDistance * tpRatio, m_Digits);
    }
}

//+------------------------------------------------------------------+
//| IsMarketSuitableForScaling - Kiểm tra thị trường phù hợp scaling|
//+------------------------------------------------------------------+
bool CTradeManager::IsMarketSuitableForScaling(const MarketProfileData &profile)
{
    // Kiểm tra chế độ thị trường
    if (profile.regime != REGIME_TRENDING) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Không nhồi lệnh - Thị trường không trong xu hướng");
        }
        return false;
    }
    
    // Kiểm tra volatility
    if (profile.isVolatile) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Không nhồi lệnh - Thị trường biến động cao");
        }
        return false;
    }
    
    // Kiểm tra phiên giao dịch
    if (!IsCurrentSessionSuitableForScaling()) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Không nhồi lệnh - Phiên giao dịch không phù hợp");
        }
        return false;
    }
    
    // Kiểm tra tin tức
    if (m_newsFilter != NULL && m_newsFilter.HasUpcomingNews()) {
        if (m_EnableDetailedLogs) {
            m_logger->LogDebug("TradeManager: Không nhồi lệnh - Có tin tức sắp diễn ra");
        }
        return false;
    }
    
    // Kiểm tra thêm dữ liệu từ AssetProfiler nếu có
    if (m_assetProfiler != NULL) {
        if (!m_assetProfiler.IsMarketSuitableForTrading()) {
            if (m_EnableDetailedLogs) {
                m_logger->LogDebug("TradeManager: Không nhồi lệnh - Asset không phù hợp theo AssetProfiler");
            }
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| GenerateOrderComment - Tạo comment chi tiết cho lệnh            |
//+------------------------------------------------------------------+
string CTradeManager::GenerateOrderComment(bool isLong, ENUM_ENTRY_SCENARIO scenario, string additionalInfo)
{
    // Chuẩn bị comment cơ bản
    string baseComment = m_OrderComment;
    string scenarioStr = "";
    
    // Thêm thông tin scenario
    switch (scenario) {
        case SCENARIO_PULLBACK: scenarioStr = "PB"; break;
        case SCENARIO_BREAKOUT: scenarioStr = "BO"; break;
        case SCENARIO_REVERSAL: scenarioStr = "REV"; break;
        case SCENARIO_SCALING: scenarioStr = "SCALE"; break;
        default: scenarioStr = ""; break;
    }
    
    // Tạo comment đầy đủ
    string comment = baseComment;
    
    if (scenarioStr != "") {
        comment += " " + scenarioStr;
    }
    
    if (isLong) {
        comment += " BUY";
    } else {
        comment += " SELL";
    }
    
    // Thêm thông tin bổ sung nếu có
    if (additionalInfo != "") {
        comment += " " + additionalInfo;
    }
    
    return comment;
}

//+------------------------------------------------------------------+
//| HandleCloseDeal - Xử lý khi một giao dịch đóng                  |
//+------------------------------------------------------------------+
void CTradeManager::HandleCloseDeal(ulong positionTicket, double closePrice, double profit)
{
    // Kiểm tra vị thế đã có metadata chưa
    PositionMetadata* metadata = GetPositionMetadata(positionTicket);
    if (metadata == NULL) {
        return;
    }
    
    // Xóa metadata
    RemovePositionMetadata(positionTicket);
    
    // Cập nhật thông tin thắng/thua
    if (profit > 0) {
        m_ConsecutiveLosses = 0;
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Vị thế #%d đóng lời: %.2f",
                positionTicket, profit
            ));
        }
    } else if (profit < 0) {
        m_ConsecutiveLosses++;
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogInfo(StringFormat(
                "TradeManager: Vị thế #%d đóng lỗ: %.2f, Thua liên tiếp: %d",
                positionTicket, profit, m_ConsecutiveLosses
            ));
        }
        
        // Kiểm tra số lần thua liên tiếp
        if (m_ConsecutiveLosses >= 3) {
            // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
                m_logger->LogWarning(StringFormat(
                    "TradeManager: Cảnh báo thua liên tiếp %d lần",
                    m_ConsecutiveLosses
                ));
            }
        }
    }
    
    // Cập nhật thông tin thống kê với RiskManager nếu có
    if (m_riskManager != NULL) {
        m_riskManager.UpdateTradingStats(profit > 0, MathAbs(profit));
    }
}

//+------------------------------------------------------------------+
//| GetCurrentATR - Lấy ATR hiện tại                                |
//+------------------------------------------------------------------+
double CTradeManager::GetCurrentATR()
{
    // Nếu đã có MarketProfile, lấy ATR từ đó
    if (m_marketProfile != NULL) {
        return m_marketProfile.GetATR();
    }
    
    // Nếu đã có AssetProfiler, lấy ATR từ đó
    if (m_assetProfiler != NULL) {
        return m_assetProfiler.GetATR();
    }
    
    // Nếu không có module nào, tính ATR trực tiếp
    if (m_handleATR == INVALID_HANDLE) {
        m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
        if (m_handleATR == INVALID_HANDLE) {
            return 0;
        }
    }
    
    // Lấy giá trị ATR
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if (CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) {
        return 0;
    }
    
    return atrBuffer[0];
}

//+------------------------------------------------------------------+
//| GetProfilerATR - Lấy ATR từ AssetProfiler                       |
//+------------------------------------------------------------------+
double CTradeManager::GetProfilerATR()
{
    if (m_assetProfiler != NULL) {
        return m_assetProfiler.GetAverageATR();
    }
    
    return GetCurrentATR();
}

//+------------------------------------------------------------------+
//| GetEMAValue - Lấy giá trị EMA                                   |
//+------------------------------------------------------------------+
double CTradeManager::GetEMAValue(int emaHandle, int shift)
{
    if (emaHandle == INVALID_HANDLE) {
        return 0;
    }
    
    double emaBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    
    if (CopyBuffer(emaHandle, 0, shift, 1, emaBuffer) <= 0) {
        return 0;
    }
    
    return emaBuffer[0];
}

//+------------------------------------------------------------------+
//| GetMinStopLevel - Lấy khoảng cách tối thiểu cho SL/TP          |
//+------------------------------------------------------------------+
double CTradeManager::GetMinStopLevel()
{
    return SymbolInfoInteger(m_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * m_Point;
}

//+------------------------------------------------------------------+
//| ValidateOrderParameters - Kiểm tra điều kiện lệnh hợp lệ        |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateOrderParameters(double &price, double &sl, double &tp, bool isLong)
{
    // Kiểm tra nếu giá hợp lệ
    if (price <= 0) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning("TradeManager: Giá không hợp lệ");
        }
        return false;
    }
    
    // Kiểm tra SL hợp lệ
    if (sl <= 0) {
        // Nếu không có SL, tính SL tự động dựa trên ATR
        sl = CalculateAdaptiveStopLoss(isLong, price);
        
        if (sl <= 0) {
            // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
                m_logger->LogWarning("TradeManager: Không thể tính SL tự động");
            }
            return false;
        }
    }
    
    // Kiểm tra TP hợp lệ
    if (tp <= 0) {
        // Tính TP tự động dựa trên SL và R-ratio
        double slDistance = MathAbs(price - sl);
        double tpDistance = slDistance * TP_RR;
        
        if (isLong) {
            tp = price + tpDistance;
        } else {
            tp = price - tpDistance;
        }
    }
    
    // Kiểm tra khoảng cách SL/TP tối thiểu
    double minStopLevel = GetMinStopLevel();
    double currentSLDistance = MathAbs(price - sl);
    double currentTPDistance = MathAbs(price - tp);
    
    if (currentSLDistance < minStopLevel) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Khoảng cách SL quá nhỏ (%.5f < %.5f). Điều chỉnh SL.",
                currentSLDistance, minStopLevel
            ));
        }
        
        // Điều chỉnh SL
        if (isLong) {
            sl = price - minStopLevel;
        } else {
            sl = price + minStopLevel;
        }
    }
    
    if (currentTPDistance < minStopLevel) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            m_logger->LogWarning(StringFormat(
                "TradeManager: Khoảng cách TP quá nhỏ (%.5f < %.5f). Điều chỉnh TP.",
                currentTPDistance, minStopLevel
            ));
        }
        
        // Điều chỉnh TP
        if (isLong) {
            tp = price + minStopLevel;
        } else {
            tp = price - minStopLevel;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| IsCurrentSessionSuitableForScaling - Kiểm tra phiên phù hợp     |
//+------------------------------------------------------------------+
bool CTradeManager::IsCurrentSessionSuitableForScaling()
{
    // Nếu không có SessionManager, sử dụng kiểm tra đơn giản
    if (m_marketProfile == NULL) {
        // Lấy giờ hiện tại (GMT)
        MqlDateTime dt;
        TimeToStruct(TimeGMT(), dt);
        
        // Chỉ nhồi lệnh trong phiên châu Âu và Mỹ (8-16 GMT)
        return (dt.hour >= 8 && dt.hour < 16);
    }
    
    // Sử dụng MarketProfile để kiểm tra phiên
    ENUM_SESSION currentSession = m_marketProfile.GetCurrentSession();
    
    // Chỉ nhồi lệnh trong phiên London và New York
    return (currentSession == SESSION_EUROPEAN || 
            currentSession == SESSION_AMERICAN || 
            currentSession == SESSION_EUROPEAN_AMERICAN);
}

//+------------------------------------------------------------------+
//| CalculateOptimalTakeProfitRatio - Tính tỷ lệ TP tối ưu          |
//+------------------------------------------------------------------+
double CTradeManager::CalculateOptimalTakeProfitRatio(ENUM_MARKET_REGIME regime)
{
    // Mặc định TP:SL = 2:1
    double tpRatio = TP_RR;
    
    // Điều chỉnh theo regime
    switch (regime) {
        case REGIME_TRENDING:
            // Xu hướng mạnh - kéo dài TP để tận dụng
            tpRatio = 2.5;
            break;
            
        case REGIME_RANGING:
            // Sideway - thu hẹp TP vì biên độ thị trường hạn chế
            tpRatio = 1.5;
            break;
            
        case REGIME_VOLATILE:
            // Biến động cao - TP vừa phải để bảo vệ lợi nhuận
            tpRatio = 1.8;
            break;
            
        default:
            // Giữ mặc định
            break;
    }
    
    // Điều chỉnh thêm dựa trên AssetProfiler nếu có
    if (m_assetProfiler != NULL) {
        double assetFactor = m_assetProfiler.GetTpSlRatio();
        if (assetFactor > 0) {
            tpRatio = tpRatio * 0.7 + assetFactor * 0.3; // Blend giữa cài đặt và đặc tính asset
        }
    }
    
    return tpRatio;
}

//+------------------------------------------------------------------+
//| EncodeMagicNumber - Mã hóa thông tin trong MagicNumber          |
//+------------------------------------------------------------------+
int CTradeManager::EncodeMagicNumber(int baseNumber, ENUM_TIMEFRAMES timeframe, ENUM_ENTRY_SCENARIO scenario)
{
    // Sử dụng 2 số cuối để mã hóa timeframe và scenario
    int tfCode = 0;
    
    // Mã hóa timeframe (0-9)
    switch (timeframe) {
        case PERIOD_M1:  tfCode = 1; break;
        case PERIOD_M5:  tfCode = 2; break;
        case PERIOD_M15: tfCode = 3; break;
        case PERIOD_M30: tfCode = 4; break;
        case PERIOD_H1:  tfCode = 5; break;
        case PERIOD_H4:  tfCode = 6; break;
        case PERIOD_D1:  tfCode = 7; break;
        case PERIOD_W1:  tfCode = 8; break;
        case PERIOD_MN1: tfCode = 9; break;
        default:         tfCode = 0; break;
    }
    
    // Mã hóa scenario (0-9)
    int scCode = (int)scenario;
    if (scCode > 9) scCode = 9;
    
    // Kết hợp theo công thức: baseNumber * 100 + tfCode * 10 + scCode
    return baseNumber * 100 + tfCode * 10 + scCode;
}

} // Kết thúc namespace ApexPullback

//+------------------------------------------------------------------+
//| Đặt trạng thái tạm dừng giao dịch                                |
//+------------------------------------------------------------------+
void CTradeManager::SetTradingPaused(bool paused)
{
    m_isTradingPaused = paused;
    if(m_logger != NULL)
    {
        m_logger.LogInfoFormat("CTradeManager: Trading paused state set to: %s", paused ? "PAUSED" : "ACTIVE");
    }
    // TODO: Có thể cần thêm logic khác ở đây, ví dụ hủy các lệnh chờ nếu tạm dừng
}

//+------------------------------------------------------------------+
//| Kiểm tra trạng thái tạm dừng giao dịch                           |
//+------------------------------------------------------------------+
bool CTradeManager::IsTradingPaused() const
{
    return m_isTradingPaused;
}

//+------------------------------------------------------------------+
//| Đóng tất cả các vị thế theo Magic Number                         |
//+------------------------------------------------------------------+
void CTradeManager::CloseAllPositionsByMagic(int magicNumber)
{
    if(m_logger != NULL)
    {
        m_logger.LogInfoFormat("CTradeManager: Attempting to close all positions with magic number: %d (0 means all EA positions)", magicNumber);
    }

    int totalPositions = PositionsTotal();
    int closedCount = 0;

    for(int i = totalPositions - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket == 0) continue;

        CPositionInfo posInfo;
        if(!posInfo.SelectByTicket(ticket))
        {
            if(m_logger != NULL) m_logger.LogWarningFormat("CTradeManager::CloseAllPositionsByMagic - Failed to select position #%d by ticket %d", i, ticket);
            continue;
        }

        // Kiểm tra symbol và magic number
        if(posInfo.Symbol() == m_Symbol && (magicNumber == 0 || posInfo.Magic() == (ulong)magicNumber) )
        {
            if(m_logger != NULL) m_logger.LogDebugFormat("CTradeManager: Closing position #%d, Ticket: %d, Symbol: %s, Type: %s, Volume: %.2f", 
                                                        i, ticket, posInfo.Symbol(), EnumToString(posInfo.PositionType()), posInfo.Volume());
            
            // Logic đóng lệnh thực tế
            bool closeResult = m_trade.PositionClose(ticket);
            if(closeResult)
            {
                closedCount++;
                if(m_logger != NULL) m_logger.LogInfoFormat("CTradeManager: Successfully closed position ticket %d.", ticket);
            }
            else
            {
                if(m_logger != NULL) m_logger.LogErrorFormat("CTradeManager: Failed to close position ticket %d. Error: %d - %s", ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
            }
        }
    }

    if(m_logger != NULL) m_logger.LogInfoFormat("CTradeManager: Closed %d positions for magic %d.", closedCount, magicNumber);
    // TODO: Có thể cần ChartRedraw() hoặc thông báo cho người dùng
}

#endif // TRADEMANAGER_MQH_INCLUDED
//+------------------------------------------------------------------+
//| End of TradeManager.mqh                                          |
//+------------------------------------------------------------------+