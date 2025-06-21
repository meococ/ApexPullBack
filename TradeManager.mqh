//+------------------------------------------------------------------+
//|                                               TradeManager.mqh |
//|                         Copyright 2023-2024, ApexPullback EA |
//|                                     https://www.apexpullback.com |
//+------------------------------------------------------------------+

#pragma once

//--- Standard Library Includes
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Trade/AccountInfo.mqh>

//--- Core Project Includes
#include "Inputs.mqh"             // Unified constants and input parameters
#include "Enums.mqh"              // Core enumerations
#include "Logger.mqh"             // For CLogger (via EAContext)
#include "MarketProfile.mqh"      // For CMarketProfile
#include "RiskManager.mqh"        // For CRiskManager
#include "RiskOptimizer.mqh"      // For CRiskOptimizer
#include "AssetDNA.mqh"           // For CAssetDNA
#include "NewsFilter.mqh"         // For CNewsFilter
#include "SwingPointDetector.mqh" // For CSwingPointDetector

//+------------------------------------------------------------------+
//| Namespace: ApexPullback                                          |
//| Purpose: Encapsulates all custom code for the EA.                |
//+------------------------------------------------------------------+
namespace ApexPullback {

// Forward declarations are generally not needed if headers are included above.
// class CMarketProfile;     // Already included
// class CRiskManager;       // Already included
// class CRiskOptimizer;     // Already included
// class CAssetDNA;          // Already included
// class CNewsFilter;        // Already included
// class CSwingPointDetector; // Already included


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
class CTradeManager {
private:
    ApexPullback::EAContext* m_context;      // Con trỏ đến EAContext
    CTrade                   m_trade;        // Đối tượng giao dịch chuẩn
    CRiskOptimizer*          m_riskOptimizer; // Tối ưu hóa rủi ro (Owned object)
    ApexPullback::MarketProfileData m_currentMarketProfileData; // Dữ liệu Market Profile hiện tại

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

public:
    // Constructor & Destructor
CTradeManager::CTradeManager(ApexPullback::EAContext &context) : m_context(&context), 
                                                              m_riskOptimizer(NULL),
                                                              m_Symbol(""),
                                                              m_MagicNumber(0),
                                                              m_Digits(0),
                                                              m_Point(0.0),
                                                              m_OrderComment("ApexPullback EA"),
                                                              m_EnableDetailedLogs(false),
                                                              m_EAState(EA_STATE_IDLE),
                                                              m_isTradingPaused(false),
                                                              m_IsActive(false),
                                                              m_PauseUntil(0),
                                                              m_ConsecutiveLosses(0),
                                                              m_EmergencyMode(false),
                                                              m_BreakEvenR(0.0),
                                                              m_BreakEvenBuffer(0.0),
                                                              m_UseAdaptiveTrailing(false),
                                                              m_TrailingMode(TRAILING_MODE_NONE),
                                                              m_TrailingATRMultiplier(0.0),
                                                              m_MinTrailingStepPoints(0),
                                                              m_UsePartialClose(false),
                                                              m_PartialCloseR1(0.0),
                                                              m_PartialCloseR2(0.0),
                                                              m_PartialClosePercent1(0.0),
                                                              m_PartialClosePercent2(0.0),
                                                              m_EnableScaling(false),
                                                              m_MaxScalingCount(0),
                                                              m_ScalingRiskPercent(0.0),
                                                              m_RequireBEForScaling(false),
                                                              m_UseChandelierExit(false),
                                                              m_ChandelierLookback(0),
                                                              m_ChandelierATRMultiplier(0.0),
                                                              m_TakeProfitLevelCount(0),
                                                              m_handleATR(INVALID_HANDLE),
                                                              m_handleEMA34(INVALID_HANDLE),
                                                              m_handleEMA89(INVALID_HANDLE),
                                                              m_handleEMA200(INVALID_HANDLE),
                                                              m_handlePSAR(INVALID_HANDLE)
{
    // m_PositionsMetadata sẽ được khởi tạo tự động (CArrayObj)
    // m_TakeProfitLevels sẽ được khởi tạo các giá trị mặc định nếu cần trong Initialize
    if (!IsValidTradeContext()) {
        // Không ghi log ở đây vì Logger có thể chưa sẵn sàng
        // Cannot use logger here as it might not be initialized. printf is a fallback.
            printf("CTradeManager::CTradeManager - Critical Error: Invalid EAContext!");
        // Có thể xem xét việc ném một ngoại lệ hoặc đặt một cờ lỗi
    }
}

CTradeManager::~CTradeManager() {
    Deinitialize(); // Đảm bảo giải phóng tài nguyên
}

// Functions for Dashboard interaction
void CTradeManager::SetTradingPaused(bool paused) {
    if (!CheckContextAndLog("SetTradingPaused")) return;
    m_isTradingPaused = paused;
    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("Giao dịch %s.", paused ? "ĐÃ TẠM DỪNG" : "ĐÃ TIẾP TỤC"));
}

bool CTradeManager::IsTradingPaused() const {
    return m_isTradingPaused || (m_PauseUntil > 0 && TimeCurrent() < m_PauseUntil);
}

void CTradeManager::CloseAllPositionsByMagic(int magicNumber) {
    if (!CheckContextAndLog("CloseAllPositionsByMagic")) return;
    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("Đang yêu cầu đóng tất cả các vị thế với magic: %d (0 = magic hiện tại).", magicNumber));

    int currentMagic = (magicNumber == 0) ? m_MagicNumber : magicNumber;
    bool closedAny = false;

    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0) {
            if (PositionSelectByTicket(ticket)) {
                if (PositionGetInteger(POSITION_MAGIC) == (ulong)currentMagic && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                    string posType = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("Đang đóng vị thế #%s %s %s %.2f lot(s) @ %.5f",
                                                                 IntegerToString(ticket),
                                                                 PositionGetString(POSITION_SYMBOL),
                                                                 posType,
                                                                 PositionGetDouble(POSITION_VOLUME),
                                                                 PositionGetDouble(POSITION_PRICE_OPEN)));
                    if (m_trade.PositionClose(ticket)) {
                        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("Vị thế #%s đã đóng thành công.", IntegerToString(ticket)));
                        RemovePositionMetadata(ticket); // Xóa metadata sau khi đóng
                        closedAny = true;
                    } else {
                        if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat("Lỗi khi đóng vị thế #%s: %s", IntegerToString(ticket), m_trade.ResultComment()));
                    }
                }
            }
        }
    }
    if (closedAny && m_context && m_context->Logger) m_context->Logger->LogInfo("Hoàn tất yêu cầu đóng tất cả vị thế.");
   else if (!closedAny && m_context && m_context->Logger) m_context->Logger->LogInfo("Không có vị thế nào được tìm thấy để đóng với magic này.");
}

// --- CÁC HÀM PUBLIC KHÁC --- 
bool CTradeManager::Initialize() {
    if (!IsValidTradeContext()) {
        // Cannot use logger here yet. Fallback to printf.
        printf("CTradeManager::Initialize - Error: Invalid EAContext or required modules missing.");
        return false;
    }
    if (m_context && m_context->Logger) m_context->Logger->LogInfo("CTradeManager::Initialize - Đang khởi tạo TradeManager...");

    m_Symbol = m_context->Symbol;
    m_MagicNumber = m_context->MagicNumber;
    m_OrderComment = m_context->OrderCommentPrefix + " " + m_Symbol;
    m_EnableDetailedLogs = m_context->EnableDetailedLogs;

    // Lấy các tham số từ EAContext
    m_BreakEvenR = m_context->BreakEvenR;
    m_BreakEvenBuffer = m_context->BreakEvenBufferPips * m_Point; // Chuyển pips sang giá trị tuyệt đối
    m_UseAdaptiveTrailing = m_context->UseAdaptiveTrailing;
    m_TrailingMode = m_context->TrailingMode;
    m_TrailingATRMultiplier = m_context->TrailingATRMultiplier;
    m_MinTrailingStepPoints = m_context->MinTrailingStepPoints;

    m_UsePartialClose = m_context->UsePartialClose;
    m_PartialCloseR1 = m_context->PartialCloseR1;
    m_PartialCloseR2 = m_context->PartialCloseR2;
    m_PartialClosePercent1 = m_context->PartialClosePercent1;
    m_PartialClosePercent2 = m_context->PartialClosePercent2;

    m_EnableScaling = m_context->EnableScaling;
    m_MaxScalingCount = m_context->MaxScalingCount;
    m_ScalingRiskPercent = m_context->ScalingRiskPercent;
    m_RequireBEForScaling = m_context->RequireBEForScaling;

    m_UseChandelierExit = m_context->UseChandelierExit;
    m_ChandelierLookback = m_context->ChandelierLookbackPeriod;
    m_ChandelierATRMultiplier = m_context->ChandelierATRMultiplier;

    // Khởi tạo Multi-Level Take Profit từ EAContext
    m_TakeProfitLevelCount = MathMin(ArraySize(m_TakeProfitLevels), m_context->TakeProfitLevelCountInput); 
    for(int i = 0; i < m_TakeProfitLevelCount; i++) {
        m_TakeProfitLevels[i].rMultiple = m_context->TakeProfitRMultiplesInput[i];
        m_TakeProfitLevels[i].volumePercent = m_context->TakeProfitVolumePercentsInput[i];
        m_TakeProfitLevels[i].triggered = false;
        m_TakeProfitLevels[i].price = 0.0;
    }

    RefreshSymbolInfo();
    if (m_Digits == 0 || m_Point == 0.0) { // Kiểm tra sau RefreshSymbolInfo
        if (m_context->Logger) m_context->Logger->LogError("CTradeManager::Initialize - Không thể lấy thông tin symbol hợp lệ.");
        return false;
    }

    m_trade.SetExpertMagicNumber(m_MagicNumber);
    m_trade.SetMarginMode(); // Sử dụng margin mode của tài khoản
    m_trade.SetTypeFillingBySymbol(m_Symbol); // Đặt chế độ khớp lệnh theo symbol
    // m_trade.SetDeviationInPoints(m_context->SlippagePips); // Đặt slippage nếu cần

    InitializeRiskOptimizer();
    InitializeIndicators();
    ClearAllMetadata(); // Xóa metadata cũ khi khởi tạo
    // Load lại metadata của các vị thế đang mở (nếu có)
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                // Giả sử chúng ta không lưu scenario vào comment, nên không thể khôi phục hoàn toàn
                // Chỉ lưu các thông tin cơ bản nhất
                SavePositionMetadata(ticket, 
                                     PositionGetDouble(POSITION_PRICE_OPEN), 
                                     PositionGetDouble(POSITION_SL), 
                                     PositionGetDouble(POSITION_TP), 
                                     PositionGetDouble(POSITION_VOLUME), 
                                     (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY), 
                                     SCENARIO_NONE); // Không thể biết scenario khi load lại
            }
        }
    }


    m_IsActive = true;
    m_EAState = EA_STATE_WAITING_SIGNAL;
    if (m_context->Logger) m_context->Logger->LogInfo("CTradeManager::Initialize - TradeManager đã khởi tạo thành công.");
    return true;
}

void CTradeManager::Deinitialize() {
    if (m_context != NULL && m_context->Logger != NULL) m_context->Logger->LogInfo("CTradeManager::Deinitialize - Đang giải phóng TradeManager...");
    
    DeinitializeIndicators();
    
    if (m_riskOptimizer != NULL) {
        delete m_riskOptimizer;
        m_riskOptimizer = NULL;
    }
    
    // Sử dụng ClearAllMetadata để đảm bảo các đối tượng con trỏ được giải phóng đúng cách
    ClearAllMetadata(); 
    m_IsActive = false;
    m_EAState = EA_STATE_STOPPED;
    if (m_context != NULL && m_context->Logger != NULL) m_context->Logger->LogInfo("CTradeManager::Deinitialize - TradeManager đã giải phóng tài nguyên.");
}

// --- QUẢN LÝ CHANDELIER EXIT ---
void CTradeManager::ManageChandelierExit(PositionInfo* position) {
    if (!IsValidTradeContext("ManageChandelierExit", true) || position == NULL || !m_UseChandelierExit) {
        return;
    }
    if (m_context->IndicatorUtils == NULL) {
        if (m_context->Logger) m_context->Logger->LogWarning("ManageChandelierExit: IndicatorUtils không khả dụng.");
        return;
    }

    double currentChandelierSL = EMPTY_VALUE;
    // Sử dụng handle đã khởi tạo nếu có, hoặc gọi trực tiếp từ IndicatorUtils
    double atrValue = (m_handleATR != INVALID_HANDLE) ? 
                      m_context->IndicatorUtils->GetBufferValue(m_handleATR, 0, 1) : 
                      m_context->IndicatorUtils->GetATR(m_ChandelierLookback, 1); // ATR của nến trước đó

    if (atrValue == EMPTY_VALUE || atrValue <= 0) {
        if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug("ManageChandelierExit: Không thể lấy giá trị ATR hợp lệ.");
        return;
    }

    MqlRates rates[m_ChandelierLookback];
    if (CopyRates(m_Symbol, m_context->Timeframe, 1, m_ChandelierLookback, rates) < m_ChandelierLookback) {
        if (m_context->Logger) m_context->Logger->LogWarning("ManageChandelierExit: Không đủ dữ liệu nến cho Chandelier Exit.");
        return;
    }

    if (position->isLong) {
        double highestHigh = 0;
        for (int i = 0; i < m_ChandelierLookback; i++) {
            if (rates[i].high > highestHigh) highestHigh = rates[i].high;
        }
        currentChandelierSL = highestHigh - m_ChandelierATRMultiplier * atrValue;
        currentChandelierSL = NormalizePrice(currentChandelierSL);

        if (currentChandelierSL > position->currentSL) { // Chỉ di chuyển SL theo hướng có lợi
            if (m_context->Logger && m_EnableDetailedLogs) {
                m_context->Logger->LogDebug(StringFormat("ManageChandelierExit (Long #%s): New SL %.5f (HH:%.5f, ATR:%.5f), Old SL %.5f",
                                            IntegerToString(position->ticket), currentChandelierSL, highestHigh, atrValue, position->currentSL));
            }
            ModifyPosition(position->ticket, currentChandelierSL, position->currentTP, "Chandelier Exit");
        }
    } else { // Short position
        double lowestLow = WRONG_VALUE;
        for (int i = 0; i < m_ChandelierLookback; i++) {
            if (lowestLow == WRONG_VALUE || rates[i].low < lowestLow) lowestLow = rates[i].low;
        }
        currentChandelierSL = lowestLow + m_ChandelierATRMultiplier * atrValue;
        currentChandelierSL = NormalizePrice(currentChandelierSL);

        if (currentChandelierSL < position->currentSL || position->currentSL == 0) { // Chỉ di chuyển SL theo hướng có lợi
            if (m_context->Logger && m_EnableDetailedLogs) {
                m_context->Logger->LogDebug(StringFormat("ManageChandelierExit (Short #%s): New SL %.5f (LL:%.5f, ATR:%.5f), Old SL %.5f",
                                            IntegerToString(position->ticket), currentChandelierSL, lowestLow, atrValue, position->currentSL));
            }
            ModifyPosition(position->ticket, currentChandelierSL, position->currentTP, "Chandelier Exit");
        }
    }
}

// --- CÁC HÀM TIỆN ÍCH KHÁC ---

// Kiểm tra context và logger, ghi log nếu cần
bool CTradeManager::CheckContextAndLog(const string funcName, bool checkLoggerOnly = false) {
    if (m_context == NULL) {
        printf("Lỗi nghiêm trọng trong %s: m_context là NULL.", funcName);
        return false;
    }
    if (m_context->Logger == NULL) { // Logger là ưu tiên hàng đầu
        printf("Lỗi nghiêm trọng trong %s: m_context->Logger là NULL.", funcName);
        return false;
    }
    if (!checkLoggerOnly) { // Kiểm tra các thành phần cốt lõi khác nếu không phải chỉ check logger
        if (m_context->Symbol == "") {
            m_context->Logger->LogError(StringFormat("Lỗi trong %s: Symbol trong context chưa được thiết lập.", funcName));
            return false;
        }
        // Thêm các kiểm tra khác nếu cần, ví dụ: Timeframe, AccountInfo, etc.
    }
    return true;
}

// Cập nhật thông tin symbol hiện tại
void CTradeManager::RefreshSymbolInfo() {
    if (!CheckContextAndLog("RefreshSymbolInfo")) return;

    m_Symbol = m_context->Symbol;
    if (m_Symbol == "") {
        if (m_context->Logger) m_context->Logger->LogError("RefreshSymbolInfo: Symbol không được cung cấp trong EAContext.");
        return;
    }

    CSymbolInfo symbolInfo;
    if (!symbolInfo.Name(m_Symbol)) {
        if (m_context->Logger) m_context->Logger->LogError(StringFormat("RefreshSymbolInfo: Lỗi khi thiết lập symbol '%s' cho CSymbolInfo.", m_Symbol));
        return;
    }
    if (!symbolInfo.RefreshRates()) { 
         if (m_context->Logger) m_context->Logger->LogWarning(StringFormat("RefreshSymbolInfo: Không thể làm mới tỷ giá cho symbol %s. Dữ liệu có thể cũ.", m_Symbol));
    }

    m_Digits = symbolInfo.Digits();
    m_Point = symbolInfo.Point();
    m_MinLot = symbolInfo.LotsMin();
    m_MaxLot = symbolInfo.LotsMax();
    m_LotStep = symbolInfo.LotsStep();
    m_ContractSize = symbolInfo.ContractSize();
    m_TickValue = symbolInfo.TickValue();
    m_TickSize = symbolInfo.TickSize();
    m_Spread = symbolInfo.Spread(); 
    m_SwapLong = symbolInfo.SwapLong();
    m_SwapShort = symbolInfo.SwapShort();
    m_StopsLevel = (int)symbolInfo.StopsLevel();

    if (m_EnableDetailedLogs && m_context->Logger) {
        m_context->Logger->LogDebug(StringFormat("RefreshSymbolInfo: Symbol=%s, Digits=%d, Point=%.*f, MinLot=%.2f, MaxLot=%.2f, LotStep=%.2f, Spread=%d, StopsLevel=%d",
            m_Symbol, m_Digits, m_Digits, m_Point, m_MinLot, m_MaxLot, m_LotStep, m_Spread, m_StopsLevel));
    }
    if (m_Digits == 0 || m_Point == 0.0) {
         if (m_context->Logger) m_context->Logger->LogError(StringFormat("RefreshSymbolInfo: Thông tin symbol %s không hợp lệ sau khi làm mới (Digits: %d, Point: %f). EA có thể không hoạt động chính xác.", m_Symbol, m_Digits, m_Point));
    }
}

// Kiểm tra xem có phải là nến mới không
bool CTradeManager::IsNewBar() {
    if (!CheckContextAndLog("IsNewBar", true)) return false; 

    static datetime lastBarTime = 0;
    MqlRates rates[1];
    if (CopyRates(m_context->Symbol, m_context->Timeframe, 0, 1, rates) < 1) {
        if (m_context->Logger)
            m_context->Logger->LogWarning("IsNewBar: Không thể lấy dữ liệu nến.");
        return false;
    }

    if (lastBarTime != rates[0].time) {
        lastBarTime = rates[0].time;
        if (m_EnableDetailedLogs && m_context->Logger) {
            m_context->Logger->LogDebug(StringFormat("IsNewBar: Nến mới được phát hiện tại %s cho timeframe %s", 
                                        TimeToString(lastBarTime), EnumToString(m_context->Timeframe)));
        }
        return true;
    }
    return false;
}

// Lấy Magic Number
int CTradeManager::GetMagicNumber() const {
    return m_MagicNumber;
}

// Lấy comment cho lệnh
string CTradeManager::GetExpertComment() const {
    return m_OrderComment;
}

// --- CÁC HÀM LIÊN QUAN ĐẾN RISK OPTIMIZER ---
bool CTradeManager::InitializeRiskOptimizer() {
    if (!CheckContextAndLog("InitializeRiskOptimizer")) return false;

    if (m_context->EnableRiskOptimizer) {
        if (m_riskOptimizer == NULL) {
            m_riskOptimizer = new CRiskOptimizer(m_context);
        }
        if (m_riskOptimizer != NULL) {
            if (m_riskOptimizer->Initialize()) {
                // Cập nhật trạng thái RiskOptimizer trong context
                m_context->IsRiskOptimizerActive = true;
                if (m_context->Logger) m_context->Logger->LogInfo("RiskOptimizer đã được khởi tạo thành công.");
                return true;
            }
            // Cập nhật trạng thái thất bại trong context
            m_context->IsRiskOptimizerActive = false;
            if (m_context->Logger) m_context->Logger->LogError("Lỗi khởi tạo RiskOptimizer.");
            delete m_riskOptimizer;
            m_riskOptimizer = NULL;
            return false;
        }
        if (m_context->Logger) m_context->Logger->LogError("Không thể tạo đối tượng RiskOptimizer.");
        return false;
    }
    if (m_context->Logger) m_context->Logger->LogInfo("RiskOptimizer không được kích hoạt trong EAContext.");
    return true; 
}

void CTradeManager::OptimizeRiskParameters() {
    if (!CheckContextAndLog("OptimizeRiskParameters") || m_riskOptimizer == NULL || !m_context->EnableRiskOptimizer) {
        if (m_context != NULL && m_context->Logger != NULL && m_context->EnableRiskOptimizer && m_riskOptimizer == NULL) {
             m_context->Logger->LogWarning("OptimizeRiskParameters: RiskOptimizer chưa được khởi tạo hoặc không được kích hoạt.");
        }
        return;
    }
    if (m_context->Logger) m_context->Logger->LogInfo("OptimizeRiskParameters: Đang thực hiện tối ưu hóa tham số rủi ro (chức năng chưa hoàn thiện).");
    // m_riskOptimizer->AdjustParametersBasedOnPerformance();
}

// --- CÁC HÀM LIÊN QUAN ĐẾN INDICATOR UTILS ---
void CTradeManager::InitializeIndicators() {
    if (!CheckContextAndLog("InitializeIndicators", true)) return;

    DeinitializeIndicators(); // Giải phóng handle cũ trước

    if (m_context->IndicatorUtils) { 
        if (m_UseAdaptiveTrailing || m_UseChandelierExit || m_TrailingMode == TRAILING_MODE_ATR) {
            m_handleATR = m_context->IndicatorUtils->iATR(m_Symbol, m_context->Timeframe, m_context->ATRPeriod_Trailing);
            if (m_handleATR == INVALID_HANDLE && m_context->Logger) {
                m_context->Logger->LogWarning("InitializeIndicators: Không thể khởi tạo ATR handle.");
            }
        }
        if (m_TrailingMode == TRAILING_MODE_PSAR) {
            m_handlePSAR = m_context->IndicatorUtils->iSAR(m_Symbol, m_context->Timeframe, m_context->PSARStep, m_context->PSARMaximum);
            if (m_handlePSAR == INVALID_HANDLE && m_context->Logger) {
                m_context->Logger->LogWarning("InitializeIndicators: Không thể khởi tạo PSAR handle.");
            }
        }
        // Khởi tạo các handle EMA nếu cần thiết cho logic của TradeManager
        // Ví dụ: nếu TradeManager cần kiểm tra EMA cross trực tiếp thay vì nhận tín hiệu
        // m_handleEMA34 = m_context->IndicatorUtils->iMA(m_Symbol, m_context->Timeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
        // m_handleEMA89 = m_context->IndicatorUtils->iMA(m_Symbol, m_context->Timeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
        // m_handleEMA200 = m_context->IndicatorUtils->iMA(m_Symbol, m_context->Timeframe, 200, 0, MODE_EMA, PRICE_CLOSE);

        if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug("InitializeIndicators: Các handle indicator đã được cập nhật/khởi tạo.");
    } else {
        if (m_context->Logger) m_context->Logger->LogWarning("InitializeIndicators: IndicatorUtils không khả dụng trong EAContext. Không thể khởi tạo handles.");
    }
}

void CTradeManager::DeinitializeIndicators() {
    if (m_handleATR != INVALID_HANDLE) { IndicatorRelease(m_handleATR); m_handleATR = INVALID_HANDLE; }
    if (m_handleEMA34 != INVALID_HANDLE) { IndicatorRelease(m_handleEMA34); m_handleEMA34 = INVALID_HANDLE; }
    if (m_handleEMA89 != INVALID_HANDLE) { IndicatorRelease(m_handleEMA89); m_handleEMA89 = INVALID_HANDLE; }
    if (m_handleEMA200 != INVALID_HANDLE) { IndicatorRelease(m_handleEMA200); m_handleEMA200 = INVALID_HANDLE; }
    if (m_handlePSAR != INVALID_HANDLE) { IndicatorRelease(m_handlePSAR); m_handlePSAR = INVALID_HANDLE; }
    if (m_context != NULL && m_context->Logger != NULL && m_EnableDetailedLogs) m_context->Logger->LogDebug("DeinitializeIndicators: Các handle indicator đã được giải phóng.");
}

double CTradeManager::GetIndicatorValue(ENUM_INDICATOR_TYPE indicatorType, int buffer, int shift) {
    if (!CheckContextAndLog("GetIndicatorValue", true) || m_context->IndicatorUtils == NULL) {
        if (m_context != NULL && m_context->Logger != NULL && m_context->IndicatorUtils == NULL) {
             m_context->Logger->LogWarning("GetIndicatorValue: IndicatorUtils chưa được khởi tạo.");
        }
        return EMPTY_VALUE;
    }

    switch(indicatorType) {
        case INDICATOR_ATR:
            if (m_handleATR != INVALID_HANDLE) return m_context->IndicatorUtils->GetBufferValue(m_handleATR, buffer, shift);
            return m_context->IndicatorUtils->GetATR(m_context->ATRPeriod_Trailing, shift); 
        case INDICATOR_PSAR:
            if (m_handlePSAR != INVALID_HANDLE) return m_context->IndicatorUtils->GetBufferValue(m_handlePSAR, buffer, shift);
            return m_context->IndicatorUtils->GetPSAR(m_context->PSARStep, m_context->PSARMaximum, shift);
        // Thêm case cho EMA nếu có handle tương ứng
        // case INDICATOR_EMA:
        //     if (buffer == 34 && m_handleEMA34 != INVALID_HANDLE) return m_context->IndicatorUtils->GetBufferValue(m_handleEMA34, 0, shift);
        //     if (buffer == 89 && m_handleEMA89 != INVALID_HANDLE) return m_context->IndicatorUtils->GetBufferValue(m_handleEMA89, 0, shift);
        //     if (buffer == 200 && m_handleEMA200 != INVALID_HANDLE) return m_context->IndicatorUtils->GetBufferValue(m_handleEMA200, 0, shift);
        //     // Fallback nếu không có handle hoặc buffer không khớp
        //     return m_context->IndicatorUtils->GetMA(buffer, 0, MODE_EMA, PRICE_CLOSE, shift);
        default:
            if (m_context->Logger) m_context->Logger->LogWarning(StringFormat("GetIndicatorValue: Loại indicator %s không được hỗ trợ trực tiếp qua handle.", EnumToString(indicatorType)));
            break;
    }
    return EMPTY_VALUE;
}

// --- CÁC HÀM QUẢN LÝ METADATA VỊ THẾ ---
void CTradeManager::SavePositionMetadata(ulong ticket, double entryPrice, double initialSL, double initialTP, double initialVolume, bool isLong, ENUM_ENTRY_SCENARIO scenario) {
    if (!CheckContextAndLog("SavePositionMetadata", true)) return;

    PositionMetadata* meta = GetPositionMetadata(ticket);
    bool isNew = (meta == NULL);
    if (isNew) {
        meta = new PositionMetadata();
        if (meta == NULL) {
            if (m_context->Logger) m_context->Logger->LogError("SavePositionMetadata: Không thể cấp phát bộ nhớ cho PositionMetadata.");
            return;
        }
        meta->Initialize(); // Khởi tạo giá trị mặc định cho metadata mới
    }

    meta->ticket = ticket;
    meta->entryPrice = entryPrice;
    meta->initialSL = initialSL;
    meta->initialTP = initialTP;
    meta->initialVolume = initialVolume;
    meta->isLong = isLong;
    meta->entryTime = TimeCurrent(); 
    meta->scenario = scenario;
    
    if (isNew) {
        meta->isBreakeven = false;
        meta->isPartialClosed1 = false;
        meta->isPartialClosed2 = false;
        meta->scalingCount = 0;
        meta->lastTrailingTime = 0;
        meta->lastTrailingSL = 0;
    }

    if (isNew) {
        if (!m_PositionsMetadata.Add(meta)) {
            if (m_context->Logger) m_context->Logger->LogError("SavePositionMetadata: Không thể thêm metadata vào ArrayObj.");
            delete meta; 
            return;
        }
    }
    if (m_context->Logger && m_EnableDetailedLogs) {
        m_context->Logger->LogDebug(StringFormat("SavePositionMetadata: %s metadata cho vị thế #%s. SL:%.5f, TP:%.5f, Vol:%.2f, Scenario: %s", 
                                    isNew ? "Đã lưu mới" : "Đã cập nhật",
                                    IntegerToString(ticket), initialSL, initialTP, initialVolume, EnumToString(scenario)));
    }
}

void CTradeManager::RemovePositionMetadata(ulong ticket) {
    if (!CheckContextAndLog("RemovePositionMetadata", true)) return;

    for (int i = m_PositionsMetadata.Total() - 1; i >= 0; i--) {
        PositionMetadata* meta = m_PositionsMetadata.At(i);
        if (meta != NULL && meta->ticket == ticket) {
            if (m_PositionsMetadata.Delete(i)) {
                delete meta; 
                if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("RemovePositionMetadata: Đã xóa metadata cho vị thế #%s.", IntegerToString(ticket)));
            } else {
                if (m_context->Logger) m_context->Logger->LogError(StringFormat("RemovePositionMetadata: Lỗi khi xóa metadata cho vị thế #%s từ ArrayObj.", IntegerToString(ticket)));
            }
            return; 
        }
    }
    if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("RemovePositionMetadata: Không tìm thấy metadata cho vị thế #%s để xóa.", IntegerToString(ticket)));
}

PositionMetadata* CTradeManager::GetPositionMetadata(ulong ticket) {
    for (int i = 0; i < m_PositionsMetadata.Total(); i++) {
        PositionMetadata* meta = m_PositionsMetadata.At(i);
        if (meta != NULL && meta->ticket == ticket) {
            return meta;
        }
    }
    return NULL;
}

void CTradeManager::ClearAllMetadata() {
    if (m_context != NULL && m_context->Logger != NULL && m_EnableDetailedLogs) {
        m_context->Logger->LogDebug(StringFormat("ClearAllMetadata: Đang xóa %d mục metadata vị thế.", m_PositionsMetadata.Total()));
    }
    for (int i = m_PositionsMetadata.Total() - 1; i >= 0; i--) {
        PositionMetadata* meta = m_PositionsMetadata.At(i);
        if (meta != NULL) {
            delete meta;
        }
    }
    m_PositionsMetadata.Clear(); 
    if (m_context != NULL && m_context->Logger != NULL && m_EnableDetailedLogs) {
        m_context->Logger->LogDebug("ClearAllMetadata: Đã xóa tất cả metadata vị thế.");
    }
}

// --- CÁC HÀM QUẢN LÝ LỆNH CHỜ (ĐƠN GIẢN) ---
// Các hàm này có thể được mở rộng sau nếu EA cần quản lý lệnh chờ phức tạp hơn.
// void CTradeManager::AddOrUpdatePendingOrderInfo(...) { /* ... */ }
// void CTradeManager::RemovePendingOrderInfo(...) { /* ... */ }
// void CTradeManager::RefreshPendingOrderList() { /* ... */ }

// --- TRIỂN KHAI CÁC HÀM QUẢN LÝ LỆNH CHỜ ---

// Lưu hoặc cập nhật thông tin lệnh chờ
void CTradeManager::AddOrUpdatePendingOrderInfo(ulong orderTicket, double price, double sl, double tp, double volume, ENUM_ORDER_TYPE_FILLING fillingType, ENUM_ORDER_TYPE orderType, datetime expirationTime) {
    if (!CheckContextAndLog("AddOrUpdatePendingOrderInfo", true)) return;

    PendingOrderInfo* info = GetPendingOrderInfo(orderTicket);
    bool isNew = (info == NULL);
    if (isNew) {
        info = new PendingOrderInfo();
        if (info == NULL) {
            if (m_context->Logger) m_context->Logger->LogError("AddOrUpdatePendingOrderInfo: Không thể cấp phát bộ nhớ cho PendingOrderInfo.");
            return;
        }
        info->Initialize(); // Khởi tạo giá trị mặc định
    }

    info->ticket = orderTicket;
    info->price = price;
    info->sl = sl;
    info->tp = tp;
    info->volume = volume;
    info->fillingType = fillingType;
    info->orderType = orderType;
    info->expirationTime = expirationTime;
    info->placeTime = TimeCurrent();

    if (isNew) {
        if (!m_PendingOrdersInfo.Add(info)) {
            if (m_context->Logger) m_context->Logger->LogError("AddOrUpdatePendingOrderInfo: Không thể thêm thông tin lệnh chờ vào ArrayObj.");
            delete info;
            return;
        }
    }
    if (m_context->Logger && m_EnableDetailedLogs) {
        m_context->Logger->LogDebug(StringFormat("AddOrUpdatePendingOrderInfo: %s thông tin cho lệnh chờ #%s. Price:%.5f, SL:%.5f, TP:%.5f, Vol:%.2f, Type: %s",
                                    isNew ? "Đã lưu mới" : "Đã cập nhật",
                                    IntegerToString(orderTicket), price, sl, tp, volume, EnumToString(orderType)));
    }
}

// Xóa thông tin lệnh chờ
void CTradeManager::RemovePendingOrderInfo(ulong orderTicket) {
    if (!CheckContextAndLog("RemovePendingOrderInfo", true)) return;

    for (int i = m_PendingOrdersInfo.Total() - 1; i >= 0; i--) {
        PendingOrderInfo* info = m_PendingOrdersInfo.At(i);
        if (info != NULL && info->ticket == orderTicket) {
            if (m_PendingOrdersInfo.Delete(i)) {
                delete info;
                if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("RemovePendingOrderInfo: Đã xóa thông tin cho lệnh chờ #%s.", IntegerToString(orderTicket)));
            } else {
                if (m_context->Logger) m_context->Logger->LogError(StringFormat("RemovePendingOrderInfo: Lỗi khi xóa thông tin lệnh chờ #%s từ ArrayObj.", IntegerToString(orderTicket)));
            }
            return;
        }
    }
    if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("RemovePendingOrderInfo: Không tìm thấy thông tin cho lệnh chờ #%s để xóa.", IntegerToString(orderTicket)));
}

// Lấy thông tin lệnh chờ bằng ticket
PendingOrderInfo* CTradeManager::GetPendingOrderInfo(ulong orderTicket) {
    for (int i = 0; i < m_PendingOrdersInfo.Total(); i++) {
        PendingOrderInfo* info = m_PendingOrdersInfo.At(i);
        if (info != NULL && info->ticket == orderTicket) {
            return info;
        }
    }
    return NULL;
}

// Đồng bộ danh sách lệnh chờ với terminal
void CTradeManager::RefreshPendingOrderList() {
    if (!CheckContextAndLog("RefreshPendingOrderList", true)) return;

    // Xóa các lệnh chờ không còn tồn tại trong terminal khỏi danh sách quản lý
    for (int i = m_PendingOrdersInfo.Total() - 1; i >= 0; i--) {
        PendingOrderInfo* info = m_PendingOrdersInfo.At(i);
        if (info != NULL) {
            COrderInfo orderInfo;
            if (!orderInfo.SelectByTicket(info->ticket)) { // Lệnh không còn tồn tại
                RemovePendingOrderInfo(info->ticket);
            }
        }
    }

    // Thêm các lệnh chờ mới từ terminal (nếu có và khớp magic number)
    int totalOrders = OrdersTotal();
    for (int i = 0; i < totalOrders; i++) {
        ulong orderTicket = OrderGetTicket(i);
        if (orderTicket > 0) {
            COrderInfo orderInfo;
            if (orderInfo.SelectByTicket(orderTicket)) {
                if (orderInfo.Symbol() == m_Symbol && orderInfo.Magic() == m_MagicNumber) {
                    if (GetPendingOrderInfo(orderTicket) == NULL) { // Chưa có trong danh sách quản lý
                        AddOrUpdatePendingOrderInfo(orderTicket, orderInfo.PriceOpen(), orderInfo.StopLoss(), orderInfo.TakeProfit(),
                                                  orderInfo.VolumeCurrent(), (ENUM_ORDER_TYPE_FILLING)orderInfo.TypeFilling(),
                                                  (ENUM_ORDER_TYPE)orderInfo.Type(), orderInfo.TimeExpiration());
                    }
                }
            }
        }
    }
    if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug("RefreshPendingOrderList: Danh sách lệnh chờ đã được đồng bộ.");
}

// --- CÁC HÀM KIỂM TRA ĐIỀU KIỆN GIAO DỊCH ---
bool CTradeManager::CanOpenNewPosition(ENUM_TRADE_DIRECTION direction) {
    if (!IsValidTradeContext("CanOpenNewPosition")) return false;

    if (m_MaxOpenPositions > 0 && GetOpenPositionsCount(m_Symbol, -1) >= m_MaxOpenPositions) {
        if (m_context->Logger) m_context->Logger->LogInfo("CanOpenNewPosition: Đã đạt số lượng vị thế mở tối đa.");
        return false;
    }
    if (!IsTradingAllowedByTime()) {
        if (m_context->Logger) m_context->Logger->LogInfo("CanOpenNewPosition: Ngoài thời gian cho phép giao dịch.");
        return false;
    }
    if (!IsSpreadAcceptable()) {
        if (m_context->Logger) m_context->Logger->LogInfo("CanOpenNewPosition: Spread hiện tại quá cao.");
        return false;
    }
    // Thêm các kiểm tra khác nếu cần (ví dụ: equity, margin, tin tức,...)
    return true;
}

bool CTradeManager::IsTradingAllowedByTime() {
    if (!m_EnableTimeFilter) return true; // Nếu không bật filter thời gian thì luôn cho phép
    if (!CheckContextAndLog("IsTradingAllowedByTime", true)) return false;

    MqlDateTime currentTimeStruct;
    TimeCurrent(currentTimeStruct);
    int currentHour = currentTimeStruct.hour;
    int currentMinute = currentTimeStruct.min;
    ENUM_DAY_OF_WEEK currentDay = (ENUM_DAY_OF_WEEK)currentTimeStruct.day_of_week;

    // Kiểm tra ngày cấm giao dịch
    if ((currentDay == SUNDAY && m_RestrictSunday) ||
        (currentDay == MONDAY && m_RestrictMonday) ||
        (currentDay == TUESDAY && m_RestrictTuesday) ||
        (currentDay == WEDNESDAY && m_RestrictWednesday) ||
        (currentDay == THURSDAY && m_RestrictThursday) ||
        (currentDay == FRIDAY && m_RestrictFriday) ||
        (currentDay == SATURDAY && m_RestrictSaturday)) {
        if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("IsTradingAllowedByTime: Hôm nay (%s) là ngày cấm giao dịch.", EnumToString(currentDay)));
        return false;
    }

    // Kiểm tra giờ cấm giao dịch
    int tradingStart = m_TradingStartHour * 100 + m_TradingStartMinute;
    int tradingEnd = m_TradingEndHour * 100 + m_TradingEndMinute;
    int currentTime = currentHour * 100 + currentMinute;

    if (tradingStart <= tradingEnd) { // Giao dịch trong cùng một ngày (ví dụ: 09:00 - 17:00)
        if (currentTime < tradingStart || currentTime >= tradingEnd) {
            if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("IsTradingAllowedByTime: Thời gian hiện tại (%02d:%02d) nằm ngoài khung cho phép (%02d:%02d - %02d:%02d).", currentHour, currentMinute, m_TradingStartHour, m_TradingStartMinute, m_TradingEndHour, m_TradingEndMinute));
            return false;
        }
    } else { // Giao dịch qua đêm (ví dụ: 22:00 - 05:00)
        if (currentTime < tradingStart && currentTime >= tradingEnd) {
             if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("IsTradingAllowedByTime: Thời gian hiện tại (%02d:%02d) nằm ngoài khung cho phép qua đêm (%02d:%02d - %02d:%02d).", currentHour, currentMinute, m_TradingStartHour, m_TradingStartMinute, m_TradingEndHour, m_TradingEndMinute));
            return false;
        }
    }
    return true;
}

bool CTradeManager::IsSpreadAcceptable() const {
    if (m_MaxSpreadPips <= 0) return true; // Nếu không đặt giới hạn spread thì luôn chấp nhận
    if (!CheckContextAndLog("IsSpreadAcceptable")) return false;

    RefreshSymbolInfo(); // Đảm bảo m_Spread và m_Point là mới nhất
    if (m_Point == 0) {
        if (m_context->Logger) m_context->Logger->LogWarning("IsSpreadAcceptable: m_Point có giá trị 0, không thể kiểm tra spread.");
        return false; // Hoặc true tùy theo logic mong muốn khi không lấy được Point
    }
    double currentSpreadInPips = m_Spread * m_Point / (m_Digits == 3 || m_Digits == 5 ? 0.1 * m_Point : m_Point); // Chuyển spread về pips
    currentSpreadInPips = m_Spread; // CSymbolInfo.Spread() đã trả về spread bằng điểm nguyên.

    if (currentSpreadInPips > m_MaxSpreadPips) {
        if (m_context->Logger && m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("IsSpreadAcceptable: Spread hiện tại (%.1f pips) vượt quá giới hạn cho phép (%.1f pips).", (double)m_Spread, (double)m_MaxSpreadPips));
        return false;
    }
    return true;
}

// --- CÁC HÀM LẤY THÔNG TIN TÀI KHOẢN VÀ THỊ TRƯỜNG ---
double CTradeManager::GetAccountEquity() {
    if (!CheckContextAndLog("GetAccountEquity", true)) return 0;
    return AccountInfoDouble(ACCOUNT_EQUITY);
}

double CTradeManager::GetAccountBalance() {
    if (!CheckContextAndLog("GetAccountBalance", true)) return 0;
    return AccountInfoDouble(ACCOUNT_BALANCE);
}

double CTradeManager::GetAccountFreeMargin() {
    if (!CheckContextAndLog("GetAccountFreeMargin", true)) return 0;
    return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
}

datetime CTradeManager::GetServerTime() {
    if (!CheckContextAndLog("GetServerTime", true)) return 0;
    return TimeCurrent();
}

double CTradeManager::GetSymbolTickValue() {
    RefreshSymbolInfo();
    return m_TickValue;
}

double CTradeManager::GetSymbolTickSize() {
    RefreshSymbolInfo();
    return m_TickSize;
}

double CTradeManager::GetSymbolContractSize() {
    RefreshSymbolInfo();
    return m_ContractSize;
}

int CTradeManager::GetSymbolStopsLevel() {
    RefreshSymbolInfo();
    return m_StopsLevel;
}

int CTradeManager::GetSymbolSpread() {
    RefreshSymbolInfo();
    return m_Spread;
}

// Mở rộng IsValidTradeContext
bool CTradeManager::IsValidTradeContext(const string funcName, bool checkSubModules = false) const {
    if (m_context == NULL) {
        printf("Lỗi nghiêm trọng trong %s: m_context là NULL.", funcName);
        return false;
    }
    if (m_context->Logger == NULL) {
        printf("Lỗi nghiêm trọng trong %s: m_context->Logger là NULL.", funcName);
        return false;
    }
    if (m_Symbol == "" || m_context->Symbol == "") {
        m_context->Logger->LogError(StringFormat("Lỗi trong %s: Symbol chưa được thiết lập trong TradeManager hoặc EAContext.", funcName));
        return false;
    }
    if (m_Digits == 0 || m_Point == 0.0) {
        m_context->Logger->LogWarning(StringFormat("Cảnh báo trong %s: Digits (is %d) hoặc Point (is %f) chưa được khởi tạo đúng cách. Gọi RefreshSymbolInfo() sớm hơn.", funcName, m_Digits, m_Point));
        // Có thể return false ở đây nếu đây là điều kiện bắt buộc
    }

    if (checkSubModules) {
        // Kiểm tra các sub-module cần thiết khác nếu được yêu cầu
        if (m_context->RiskManager == NULL && (funcName.Find("OpenPosition") != -1 || funcName.Find("Calculate") != -1) ) { // Ví dụ: RiskManager cần cho việc mở lệnh
            m_context->Logger->LogError(StringFormat("Lỗi trong %s: m_context->RiskManager là NULL.", funcName));
            return false;
        }
        if (m_context->IndicatorUtils == NULL && (funcName.Find("Trailing") != -1 || funcName.Find("Chandelier") != -1 || funcName.Find("Indicator") != -1) ) { // Ví dụ: IndicatorUtils cần cho trailing stop
            m_context->Logger->LogError(StringFormat("Lỗi trong %s: m_context->IndicatorUtils là NULL.", funcName));
            return false;
        }
        // Thêm kiểm tra cho các module khác như AssetDNA, MarketProfile nếu cần
    }
    return true;
}


void CTradeManager::OnTick() {
    if (!m_IsActive || m_isTradingPaused || !IsValidTradeContext()) return;
    if (m_EAState == EA_STATE_STOPPED || m_EAState == EA_STATE_ERROR) return;

    // Kiểm tra các điều kiện chung trước khi xử lý logic chính
    if (!IsMarketOpen()) {
        if (m_EnableDetailedLogs && m_context->Logger) m_context->Logger->LogDebug("CTradeManager::OnTick - Thị trường đóng cửa.");
        return;
    }
    if (IsNewsImpactPeriod()) {
        if (m_EnableDetailedLogs && m_context->Logger) m_context->Logger->LogDebug("CTradeManager::OnTick - Đang trong giai đoạn tin tức quan trọng, tạm dừng giao dịch.");
        // Có thể xem xét đóng các lệnh đang chờ hoặc quản lý vị thế hiện tại
        return;
    }
    if (!IsAllowedTradingSession()) {
        if (m_EnableDetailedLogs && m_context->Logger) m_context->Logger->LogDebug("CTradeManager::OnTick - Ngoài phiên giao dịch cho phép.");
        // Có thể xem xét đóng các lệnh đang chờ hoặc quản lý vị thế hiện tại
        return;
    }

    RefreshSymbolInfo(); // Cập nhật thông tin symbol mỗi tick
    UpdateMarketData();  // Cập nhật dữ liệu thị trường cần thiết (ví dụ: ATR, EMA)

    // Quản lý các vị thế đang mở
    ManageActivePositions();

    // Quản lý các lệnh chờ
    ManagePendingOrders();

    // Kiểm tra tín hiệu vào lệnh mới (logic này sẽ được gọi từ EA chính hoặc AssetDNA)
    // Ví dụ: 
    // if (m_EAState == EA_STATE_WAITING_SIGNAL) {
    //     // CheckForNewSignal(); // Hàm này sẽ gọi các module phân tích
    // }
}

void CTradeManager::OnTrade() {
    if (!IsValidTradeContext() || m_context->Logger == NULL) return;
    // Xử lý các sự kiện giao dịch, ví dụ: cập nhật metadata khi lệnh được khớp hoặc đóng
    // Logic này có thể phức tạp tùy thuộc vào cách EA theo dõi trạng thái lệnh
    // Thông thường, sau một hành động trade (m_trade.OrderSend, PositionOpen, PositionClose, etc.)
    // kết quả sẽ được xử lý ngay lập tức. OnTrade() có thể dùng để đồng bộ hóa
    // hoặc xử lý các thay đổi không mong muốn từ server.

    // Ví dụ: kiểm tra xem có vị thế nào mới được mở hoặc đóng không
    // và cập nhật m_PositionsMetadata cho phù hợp.
    // Điều này quan trọng nếu lệnh được đóng/mở thủ công hoặc bởi một EA khác cùng magic.
    if (m_EnableDetailedLogs) m_context->Logger->LogDebug("CTradeManager::OnTrade - Sự kiện giao dịch được kích hoạt.");

    // Cập nhật lại danh sách metadata nếu cần thiết
    // Quét các vị thế hiện tại và so sánh với metadata
    CArrayObj* currentPositions = new CArrayObj();
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                PositionMetadata* meta = GetPositionMetadataPtr(ticket);
                if (meta == NULL) { // Vị thế mới được mở (có thể bởi EA này hoặc ngoài)
                    if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("OnTrade: Phát hiện vị thế mới #%d chưa có metadata. Đang tạo...", ticket));
                    SavePositionMetadata(ticket, 
                                         PositionGetDouble(POSITION_PRICE_OPEN), 
                                         PositionGetDouble(POSITION_SL), 
                                         PositionGetDouble(POSITION_TP), 
                                         PositionGetDouble(POSITION_VOLUME), 
                                         (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY), 
                                         SCENARIO_NONE); // Không thể biết scenario
                }
                // Thêm ticket vào danh sách để kiểm tra sau
                currentPositions.Add(new CLong(ticket)); 
            }
        }
    }

    // Kiểm tra các metadata không còn vị thế tương ứng (đã bị đóng)
    for(int i = m_PositionsMetadata.Total() - 1; i >= 0; i--) {
        PositionMetadata* meta = (PositionMetadata*)m_PositionsMetadata.At(i);
        if(meta == NULL) continue;
        bool found = false;
        for(int j=0; j < currentPositions.Total(); j++){
            CLong* currentTicketObj = (CLong*)currentPositions.At(j);
            if(currentTicketObj != NULL && meta->ticket == (ulong)currentTicketObj->Value()){
                found = true;
                break;
            }
        }
        if(!found){
            if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("OnTrade: Vị thế #%d trong metadata không còn tồn tại. Đang xóa metadata...", meta->ticket));
            RemovePositionMetadata(meta->ticket);
        }
    }
    delete currentPositions;

    // Gọi hàm cập nhật thống kê của RiskManager nếu có thay đổi
    if (m_context->RiskManager != NULL) {
        // m_context->RiskManager->UpdateStatsOnDealClose(); // Cần truyền thông tin deal cụ thể
    }
}

void CTradeManager::OnTimer() {
    if (!m_IsActive || !IsValidTradeContext()) return;
    if (m_EAState == EA_STATE_STOPPED || m_EAState == EA_STATE_ERROR) return;

    // Các tác vụ định kỳ, ví dụ:
    // - Kiểm tra hết hạn lệnh chờ
    // - Cập nhật trailing stop cho các vị thế không quá thường xuyên (nếu không làm trong OnTick)
    // - Gửi heartbeat hoặc log định kỳ
    if (m_EnableDetailedLogs && m_context->Logger) m_context->Logger->LogDebug("CTradeManager::OnTimer - Timer event.");

    // Ví dụ: Kiểm tra và xóa lệnh chờ hết hạn
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if (OrderSelect(ticket)) {
            if (OrderGetInteger(ORDER_MAGIC) == (ulong)m_MagicNumber && OrderGetString(ORDER_SYMBOL) == m_Symbol) {
                datetime expiration = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);
                if (expiration > 0 && expiration < TimeCurrent()) {
                    if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("Lệnh chờ #%s đã hết hạn. Đang xóa...", IntegerToString(ticket)));
                    if (DeletePendingOrder(ticket)) {
                        if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("Lệnh chờ #%s đã xóa thành công.", IntegerToString(ticket)));
                    } else {
                        if (m_context->Logger) m_context->Logger->LogError(StringFormat("Lỗi khi xóa lệnh chờ #%s hết hạn.", IntegerToString(ticket)));
                    }
                }
            }
        }
    }
    
    // Kiểm tra nếu EA bị tạm dừng do m_PauseUntil
    if (m_PauseUntil > 0 && TimeCurrent() >= m_PauseUntil) {
        m_PauseUntil = 0; // Reset thời gian tạm dừng
        if (m_context->Logger) m_context->Logger->LogInfo("Thời gian tạm dừng giao dịch đã kết thúc. EA tiếp tục hoạt động.");
        // Có thể cần đặt lại EAState nếu nó bị thay đổi trong thời gian tạm dừng
        if(m_EAState == EA_STATE_PAUSED_BY_CONDITION) m_EAState = EA_STATE_WAITING_SIGNAL;
    }
}

// Mở lệnh mới
bool CTradeManager::OpenPosition(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                  double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                                  string comment = "") {
    if (!CheckContextAndLog("OpenPosition")) return false;
    if (m_context->RiskManager == NULL || m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("OpenPosition - Invalid RiskManager or Logger.");
    else printf("CTradeManager::OpenPosition - Invalid RiskManager or Logger.");
        return false;
    }

    if (IsTradingPaused()) {
        m_context->Logger->LogWarning("OpenPosition: Giao dịch đang tạm dừng, không thể mở vị thế mới.");
        return false;
    }

    if (!m_context->RiskManager->CanOpenNewPosition(orderType)) { // Kiểm tra các giới hạn của RiskManager
        // RiskManager sẽ tự log lý do
        return false;
    }

    volume = NormalizeLots(volume);
    if (volume <= 0) {
        m_context->Logger->LogError(StringFormat("OpenPosition: Khối lượng không hợp lệ sau khi chuẩn hóa: %.2f", volume));
        return false;
    }

    // Kiểm tra spread trước khi vào lệnh
    if (m_context->RiskManager != NULL && !m_context->RiskManager->IsSpreadAcceptable()) {
        m_context->Logger->LogWarning(StringFormat("OpenPosition: Spread hiện tại (%.1f pips) vượt ngưỡng cho phép (%.1f pips). Không mở vị thế.", 
            GetCurrentSpreadPips(), m_context->RiskManager->GetAcceptableSpreadThreshold()));
        return false;
    }

    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_DEAL; // Lệnh thị trường
    request.symbol = m_Symbol;
    request.volume = volume;
    request.magic = m_MagicNumber;
    request.comment = (comment == "") ? m_OrderComment + " " + EnumToString(scenario) : comment;
    request.type = orderType;
    request.price = NormalizePrice(price); // Giá vào lệnh (cho lệnh thị trường, MQL5 sẽ tự lấy giá tốt nhất nếu price = 0)
    request.sl = NormalizePrice(sl);
    request.tp = NormalizePrice(tp);
    request.deviation = m_context->SlippagePips; // Slippage cho phép (tính bằng points)
    request.type_filling = FillingMode();
    request.type_time = ORDER_TIME_GTC; // Good Till Cancelled

    string orderTypeStr = (orderType == ORDER_TYPE_BUY) ? "BUY" : "SELL";
    m_context->Logger->LogInfo(StringFormat("Đang thử mở vị thế %s %s %.2f lot(s) @ %.5f, SL: %.5f, TP: %.5f, Scenario: %s", 
                                          orderTypeStr, m_Symbol, volume, request.price, request.sl, request.tp, EnumToString(scenario)));

    m_EAState = EA_STATE_OPENING_POSITION;
    if (!m_trade.OrderSend(request, result)) {
        m_context->Logger->LogError(StringFormat("Lỗi khi gửi lệnh %s: %s (Code: %d)", orderTypeStr, m_trade.ResultComment(), m_trade.ResultRetcode()));
        m_EAState = EA_STATE_WAITING_SIGNAL;
        return false;
    }

    if (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        m_context->Logger->LogInfo(StringFormat("Lệnh %s đã được đặt thành công. Ticket: %s, Order: %s, Position: %s", 
                                              orderTypeStr, 
                                              ULongToString(result.order),
                                              ULongToString(result.deal),
                                              ULongToString(result.position_id)
                                              ));
        
        ulong positionTicket = (result.position_id > 0) ? result.position_id : result.order; // MT5 có thể trả về position_id hoặc order ticket
        if (positionTicket == 0 && result.deal > 0) { // Nếu position_id = 0, thử lấy từ deal
             HistorySelect(0, TimeCurrent());
             uint totalDeals = HistoryDealsTotal();
             for(uint i=0; i<totalDeals; i++){
                 ulong dealTicket = HistoryDealGetTicket(i);
                 if(dealTicket == result.deal){
                     positionTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
                     break;
                 }
             }
        }

        if (positionTicket > 0) {
            // Lấy bối cảnh thị trường hiện tại
            MarketProfileData currentMarketContext;
            if (m_context->MarketProfile != NULL) {
                currentMarketContext = m_context->MarketProfile->GetMarketProfileData();
            } else {
                m_context->Logger->LogWarning("OpenPosition: MarketProfile không khả dụng, không thể lưu bối cảnh thị trường.");
                // Khởi tạo với giá trị mặc định nếu cần
                ZeroMemory(currentMarketContext);
            }

            // Thêm vị thế vào PositionManager với bối cảnh thị trường
            if (m_context->PositionManager != NULL) {
                m_context->PositionManager->AddPosition(positionTicket, currentMarketContext);
            }

            SavePositionMetadata(positionTicket, result.price, result.sl, result.tp, result.volume, (orderType == ORDER_TYPE_BUY), scenario);
            if (m_context->RiskManager != NULL) {
                m_context->RiskManager->UpdateStatsOnDealOpen(positionTicket, scenario, volume, orderType);
            }
        } else {
             m_context->Logger->LogWarning("Không thể lấy được ticket vị thế sau khi mở lệnh. Metadata có thể không được lưu.");
        }

        m_EAState = EA_STATE_POSITION_OPENED;
        // Sau khi mở vị thế, có thể chuyển sang trạng thái quản lý vị thế hoặc chờ tín hiệu mới
        // tùy thuộc vào logic của EA
        // m_EAState = EA_STATE_MANAGING_POSITION; 
        // hoặc
        // m_EAState = EA_STATE_WAITING_SIGNAL;
        return true;
    } else {
        m_context->Logger->LogError(StringFormat("Lỗi khi mở vị thế %s: %s (Retcode: %d)", orderTypeStr, result.comment, result.retcode));
        m_EAState = EA_STATE_WAITING_SIGNAL;
        return false;
    }
}

// Đóng lệnh
bool CTradeManager::ClosePosition(ulong ticket, double volume, string comment = "") {
    if (!CheckContextAndLog("ClosePosition")) return false;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ClosePosition - Logger is invalid.");
    else printf("CTradeManager::ClosePosition - Logger is invalid.");
        return false;
    }

    if (!PositionSelectByTicket(ticket)) {
        m_context->Logger->LogError(StringFormat("ClosePosition: Không thể chọn vị thế với ticket #%s.", ULongToString(ticket)));
        return false;
    }

    if (PositionGetInteger(POSITION_MAGIC) != (ulong)m_MagicNumber || PositionGetString(POSITION_SYMBOL) != m_Symbol) {
        m_context->Logger->LogError(StringFormat("ClosePosition: Ticket #%s không thuộc về EA này hoặc symbol này.", ULongToString(ticket)));
        return false;
    }

    double positionVolume = PositionGetDouble(POSITION_VOLUME);
    volume = NormalizeLots(volume);

    if (volume <= 0 || volume > positionVolume) {
        m_context->Logger->LogWarning(StringFormat("ClosePosition: Khối lượng đóng không hợp lệ (%.2f) cho vị thế #%s (hiện tại %.2f). Sẽ đóng toàn bộ.", volume, ULongToString(ticket), positionVolume));
        volume = positionVolume; // Mặc định đóng toàn bộ nếu khối lượng không hợp lệ
    }

    string posTypeStr = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? "BUY" : "SELL";
    m_context->Logger->LogInfo(StringFormat("Đang thử đóng %.2f lot(s) của vị thế %s #%s...", volume, posTypeStr, ULongToString(ticket)));

    m_EAState = EA_STATE_CLOSING_POSITION;
    bool closeResult = false;
    if (volume == positionVolume) { // Đóng toàn bộ
        closeResult = m_trade.PositionClose(ticket, m_context->SlippagePips);
    } else { // Đóng một phần
        // Để đóng một phần, cần mở một lệnh ngược lại với khối lượng mong muốn
        // MQL5 không có hàm đóng một phần trực tiếp như MT4
        // Đây là một cách tiếp cận, cần kiểm tra kỹ lưỡng
        ENUM_ORDER_TYPE counterOrderType = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        MqlTradeRequest request;
        MqlTradeResult result;
        ZeroMemory(request);
        ZeroMemory(result);

        request.action = TRADE_ACTION_DEAL;
        request.symbol = m_Symbol;
        request.volume = volume;
        request.magic = m_MagicNumber; // Cùng magic để hệ thống netting xử lý
        request.comment = (comment == "") ? "Partial Close " + ULongToString(ticket) : comment;
        request.type = counterOrderType;
        request.position = ticket; // Chỉ định vị thế cần đóng một phần
        request.price = (counterOrderType == ORDER_TYPE_SELL) ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
        request.deviation = m_context->SlippagePips;
        request.type_filling = FillingMode();
        request.type_time = ORDER_TIME_GTC;

        if (m_trade.OrderSend(request, result)) {
            if (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
                closeResult = true;
            } else {
                 m_context->Logger->LogError(StringFormat("Lỗi khi gửi lệnh đóng một phần cho #%s: %s (Code: %d)", ULongToString(ticket), result.comment, result.retcode));
            }
        } else {
            m_context->Logger->LogError(StringFormat("Lỗi OrderSend khi đóng một phần cho #%s: %s (Code: %d)", ULongToString(ticket), m_trade.ResultComment(), m_trade.ResultRetcode()));
        }
    }

    if (closeResult) {
        m_context->Logger->LogInfo(StringFormat("Yêu cầu đóng vị thế #%s (%.2f lot) đã được gửi thành công. Comment: %s", ULongToString(ticket), volume, m_trade.ResultComment()));
        // Metadata sẽ được cập nhật/xóa trong OnTrade hoặc khi deal được xử lý
        // Hoặc có thể cập nhật ngay tại đây nếu là đóng toàn bộ
        if (volume == positionVolume) {
            RemovePositionMetadata(ticket);
        }
        if (m_context->RiskManager != NULL) {
            // Cần thông tin deal để cập nhật chính xác P/L
            // m_context->RiskManager->UpdateStatsOnDealClose(...);
        }
        m_EAState = EA_STATE_WAITING_SIGNAL; // Hoặc trạng thái phù hợp khác
        return true;
    } else {
        m_context->Logger->LogError(StringFormat("Lỗi khi đóng vị thế #%s: %s", ULongToString(ticket), m_trade.ResultComment()));
        m_EAState = EA_STATE_MANAGING_POSITION; // Quay lại quản lý nếu đóng lỗi
        return false;
    }
}

// Sửa lệnh
bool CTradeManager::ModifyPosition(ulong ticket, double sl, double tp) {
    if (!CheckContextAndLog("ModifyPosition")) return false;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ModifyPosition - Logger is invalid.");
    else printf("CTradeManager::ModifyPosition - Logger is invalid.");
        return false;
    }

    if (!PositionSelectByTicket(ticket)) {
        m_context->Logger->LogError(StringFormat("ModifyPosition: Không thể chọn vị thế với ticket #%s.", ULongToString(ticket)));
        return false;
    }

    if (PositionGetInteger(POSITION_MAGIC) != (ulong)m_MagicNumber || PositionGetString(POSITION_SYMBOL) != m_Symbol) {
        m_context->Logger->LogError(StringFormat("ModifyPosition: Ticket #%s không thuộc về EA này hoặc symbol này.", ULongToString(ticket)));
        return false;
    }

    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    sl = NormalizePrice(sl);
    tp = NormalizePrice(tp);

    // Chỉ sửa đổi nếu có sự thay đổi và giá trị mới hợp lệ (khác 0)
    bool changed = false;
    if (sl != 0 && MathAbs(sl - currentSL) > m_Point) changed = true;
    if (tp != 0 && MathAbs(tp - currentTP) > m_Point) changed = true;

    if (!changed) {
        if (m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("ModifyPosition: Không có thay đổi SL/TP cho vị thế #%s.", ULongToString(ticket)));
        return true; // Coi như thành công nếu không có gì để thay đổi
    }
    
    // Nếu một trong hai giá trị mới là 0, giữ nguyên giá trị cũ
    if (sl == 0) sl = currentSL;
    if (tp == 0) tp = currentTP;

    m_context->Logger->LogInfo(StringFormat("Đang thử sửa vị thế #%s: SL từ %.5f -> %.5f, TP từ %.5f -> %.5f", 
                                          ULongToString(ticket), currentSL, sl, currentTP, tp));

    if (!m_trade.PositionModify(ticket, sl, tp)) {
        m_context->Logger->LogError(StringFormat("Lỗi khi sửa vị thế #%s: %s (Code: %d)", ULongToString(ticket), m_trade.ResultComment(), m_trade.ResultRetcode()));
        return false;
    }

    m_context->Logger->LogInfo(StringFormat("Vị thế #%s đã được sửa thành công. SL mới: %.5f, TP mới: %.5f", ULongToString(ticket), sl, tp));
    UpdatePositionMetadataSLTP(ticket, sl, tp);
    return true;
}

// Đặt lệnh chờ
bool CTradeManager::PlacePendingOrder(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                     double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                                     datetime expiration = 0, string comment = "") {
    if (!CheckContextAndLog("PlacePendingOrder")) return false;
    if (m_context->RiskManager == NULL || m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("PlacePendingOrder - Invalid RiskManager or Logger.");
    else printf("CTradeManager::PlacePendingOrder - Invalid RiskManager or Logger.");
        return false;
    }

    if (IsTradingPaused()) {
        m_context->Logger->LogWarning("PlacePendingOrder: Giao dịch đang tạm dừng, không thể đặt lệnh chờ mới.");
        return false;
    }
    
    if (!m_context->RiskManager->CanOpenNewPosition(orderType)) { // Kiểm tra các giới hạn của RiskManager
        // RiskManager sẽ tự log lý do
        return false;
    }

    volume = NormalizeLots(volume);
    if (volume <= 0) {
        m_context->Logger->LogError(StringFormat("PlacePendingOrder: Khối lượng không hợp lệ sau khi chuẩn hóa: %.2f", volume));
        return false;
    }

    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);

    request.action = TRADE_ACTION_PENDING; // Lệnh chờ
    request.symbol = m_Symbol;
    request.volume = volume;
    request.magic = m_MagicNumber;
    request.comment = (comment == "") ? m_OrderComment + " PENDING " + EnumToString(scenario) : comment;
    request.type = orderType; // Ví dụ: ORDER_TYPE_BUY_LIMIT, ORDER_TYPE_SELL_STOP
    request.price = NormalizePrice(price); // Giá đặt lệnh chờ
    request.sl = NormalizePrice(sl);
    request.tp = NormalizePrice(tp);
    request.type_filling = FillingMode();
    request.type_time = (expiration == 0) ? ORDER_TIME_GTC : ORDER_TIME_SPECIFIED;
    request.expiration = expiration;

    string orderTypeStr = EnumToString(orderType);
    m_context->Logger->LogInfo(StringFormat("Đang thử đặt lệnh chờ %s %s %.2f lot(s) @ %.5f, SL: %.5f, TP: %.5f, Exp: %s, Scenario: %s", 
                                          orderTypeStr, m_Symbol, volume, request.price, request.sl, request.tp, TimeToString(expiration, TIME_DATE|TIME_MINUTES), EnumToString(scenario)));

    if (!m_trade.OrderSend(request, result)) {
        m_context->Logger->LogError(StringFormat("Lỗi khi gửi lệnh chờ %s: %s (Code: %d)", orderTypeStr, m_trade.ResultComment(), m_trade.ResultRetcode()));
        return false;
    }

    if (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        m_context->Logger->LogInfo(StringFormat("Lệnh chờ %s đã được đặt thành công. Ticket: %s", orderTypeStr, ULongToString(result.order)));
        // Lưu metadata cho lệnh chờ nếu cần (tương tự như vị thế)
        // SavePendingOrderMetadata(result.order, ...);
        if (m_context->RiskManager != NULL) {
             // m_context->RiskManager->UpdateStatsOnPendingOrderPlaced(...);
        }
        return true;
    } else {
        m_context->Logger->LogError(StringFormat("Lỗi khi đặt lệnh chờ %s: %s (Retcode: %d)", orderTypeStr, result.comment, result.retcode));
        return false;
    }
}

// Sửa lệnh chờ
bool CTradeManager::ModifyPendingOrder(ulong ticket, double price, double sl, double tp, datetime expiration = 0) {
    if (!CheckContextAndLog("ModifyPendingOrder")) return false;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ModifyPendingOrder - Logger is invalid.");
    else printf("CTradeManager::ModifyPendingOrder - Logger is invalid.");
        return false;
    }

    if (!OrderSelect(ticket)) {
        m_context->Logger->LogError(StringFormat("ModifyPendingOrder: Không thể chọn lệnh chờ với ticket #%s.", ULongToString(ticket)));
        return false;
    }

    if (OrderGetInteger(ORDER_MAGIC) != (ulong)m_MagicNumber || OrderGetString(ORDER_SYMBOL) != m_Symbol) {
        m_context->Logger->LogError(StringFormat("ModifyPendingOrder: Ticket #%s không thuộc về EA này hoặc symbol này.", ULongToString(ticket)));
        return false;
    }

    double currentPrice = OrderGetDouble(ORDER_PRICE_OPEN);
    double currentSL = OrderGetDouble(ORDER_SL);
    double currentTP = OrderGetDouble(ORDER_TP);
    datetime currentExpiration = (datetime)OrderGetInteger(ORDER_TIME_EXPIRATION);

    price = NormalizePrice(price);
    sl = NormalizePrice(sl);
    tp = NormalizePrice(tp);

    // Chỉ sửa đổi nếu có sự thay đổi và giá trị mới hợp lệ (khác 0 hoặc khác giá trị cũ)
    bool changed = false;
    if (price != 0 && MathAbs(price - currentPrice) > m_Point) changed = true;
    if (sl != 0 && MathAbs(sl - currentSL) > m_Point) changed = true;
    if (tp != 0 && MathAbs(tp - currentTP) > m_Point) changed = true;
    if (expiration != 0 && expiration != currentExpiration) changed = true;

    if (!changed) {
        if (m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("ModifyPendingOrder: Không có thay đổi cho lệnh chờ #%s.", ULongToString(ticket)));
        return true; // Coi như thành công nếu không có gì để thay đổi
    }

    // Nếu giá trị mới là 0, giữ nguyên giá trị cũ (ngoại trừ expiration, 0 nghĩa là GTC)
    if (price == 0) price = currentPrice;
    if (sl == 0) sl = currentSL;
    if (tp == 0) tp = currentTP;
    // expiration = 0 là hợp lệ (GTC)

    m_context->Logger->LogInfo(StringFormat("Đang thử sửa lệnh chờ #%s: Price %.5f->%.5f, SL %.5f->%.5f, TP %.5f->%.5f, Exp %s->%s", 
                                          ULongToString(ticket), currentPrice, price, currentSL, sl, currentTP, tp, 
                                          TimeToString(currentExpiration, TIME_DATE|TIME_MINUTES), TimeToString(expiration, TIME_DATE|TIME_MINUTES)));

    if (!m_trade.OrderModify(ticket, price, sl, tp, (expiration == 0) ? ORDER_TIME_GTC : ORDER_TIME_SPECIFIED, expiration)) {
        m_context->Logger->LogError(StringFormat("Lỗi khi sửa lệnh chờ #%s: %s (Code: %d)", ULongToString(ticket), m_trade.ResultComment(), m_trade.ResultRetcode()));
        return false;
    }

    m_context->Logger->LogInfo(StringFormat("Lệnh chờ #%s đã được sửa thành công.", ULongToString(ticket)));
    // UpdatePendingOrderMetadata(ticket, ...);
    return true;
}

// Xóa lệnh chờ
bool CTradeManager::DeletePendingOrder(ulong ticket) {
    if (!CheckContextAndLog("DeletePendingOrder")) return false;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("DeletePendingOrder - Logger is invalid.");
    else printf("CTradeManager::DeletePendingOrder - Logger is invalid.");
        return false;
    }

    if (!OrderSelect(ticket)) {
        // Không log lỗi ở đây vì có thể lệnh đã được kích hoạt hoặc xóa trước đó
        if (m_EnableDetailedLogs) m_context->Logger->LogDebug(StringFormat("DeletePendingOrder: Không thể chọn lệnh chờ #%s (có thể đã được xử lý)."), ULongToString(ticket)));
        return false; // Hoặc true nếu coi việc không tìm thấy là đã xóa
    }

    if (OrderGetInteger(ORDER_MAGIC) != (ulong)m_MagicNumber || OrderGetString(ORDER_SYMBOL) != m_Symbol) {
        m_context->Logger->LogError(StringFormat("DeletePendingOrder: Ticket #%s không thuộc về EA này hoặc symbol này.", ULongToString(ticket)));
        return false;
    }

    m_context->Logger->LogInfo(StringFormat("Đang thử xóa lệnh chờ #%s...", ULongToString(ticket)));

    if (!m_trade.OrderDelete(ticket)) {
        m_context->Logger->LogError(StringFormat("Lỗi khi xóa lệnh chờ #%s: %s (Code: %d)", ULongToString(ticket), m_trade.ResultComment(), m_trade.ResultRetcode()));
        return false;
    }

    m_context->Logger->LogInfo(StringFormat("Lệnh chờ #%s đã được xóa thành công.", ULongToString(ticket)));
    // RemovePendingOrderMetadata(ticket);
    return true;
}

// --- CÁC HÀM QUẢN LÝ VÀ TIỆN ÍCH --- 

void CTradeManager::ManageActivePositions() {
    if (!CheckContextAndLog("ManageActivePositions", true)) return;

    for (int i = m_PositionsMetadata.Total() - 1; i >= 0; i--) {
        PositionMetadata* meta = (PositionMetadata*)m_PositionsMetadata.At(i);
        if (meta == NULL || !PositionSelectByTicket(meta->ticket)) {
            if (meta != NULL && m_context->Logger) m_context->Logger->LogWarning(StringFormat("ManageActivePositions: Không thể chọn vị thế #%s từ metadata. Có thể đã bị đóng.", ULongToString(meta->ticket)));
            // Nếu không chọn được, có thể vị thế đã bị đóng, nên xóa metadata
            if(meta != NULL) RemovePositionMetadata(meta->ticket);
            continue;
        }

        // Kiểm tra lại magic và symbol phòng trường hợp hy hữu
        if (PositionGetInteger(POSITION_MAGIC) != (ulong)m_MagicNumber || PositionGetString(POSITION_SYMBOL) != m_Symbol) {
            continue;
        }

        // 1. Quản lý Break-Even
        ManageBreakEven(meta);

        // 2. Quản lý Trailing Stop (nhiều chế độ)
        ManageTrailingStop(meta);

        // 3. Quản lý Partial Close (Multi-Level TP)
        ManagePartialClose(meta);
        
        // 4. Quản lý Chandelier Exit
        ManageChandelierExit(meta);

        // 5. Các logic quản lý khác (ví dụ: scaling out/in - phức tạp hơn, tạm bỏ qua)
    }
}

void CTradeManager::ManagePendingOrders() {
    if (!CheckContextAndLog("ManagePendingOrders", true)) return;

    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if (OrderSelect(ticket)) {
            if (OrderGetInteger(ORDER_MAGIC) == (ulong)m_MagicNumber && OrderGetString(ORDER_SYMBOL) == m_Symbol) {
                // Logic quản lý lệnh chờ, ví dụ:
                // - Điều chỉnh giá nếu thị trường di chuyển quá xa
                // - Hủy lệnh nếu điều kiện không còn phù hợp
                // - Kiểm tra thời gian hết hạn (đã có trong OnTimer)

                ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
                double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
                double currentPrice = (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP) ? SymbolInfoDouble(m_Symbol, SYMBOL_ASK) : SymbolInfoDouble(m_Symbol, SYMBOL_BID);
                double minDistance = m_context->MinStopDistancePips * m_Point; // Khoảng cách tối thiểu từ giá hiện tại

                // Ví dụ: Hủy lệnh chờ nếu giá hiện tại đã vượt qua điểm vào lệnh một khoảng nhất định
                // (chỉ áp dụng cho limit order, stop order sẽ tự khớp)
                if (orderType == ORDER_TYPE_BUY_LIMIT && currentPrice < openPrice - minDistance * 2) {
                    if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("Hủy lệnh BUY LIMIT #%s do giá đã giảm quá xa.", ULongToString(ticket)));
                    DeletePendingOrder(ticket);
                    continue;
                }
                if (orderType == ORDER_TYPE_SELL_LIMIT && currentPrice > openPrice + minDistance * 2) {
                    if (m_context->Logger) m_context->Logger->LogInfo(StringFormat("Hủy lệnh SELL LIMIT #%s do giá đã tăng quá xa.", ULongToString(ticket)));
                    DeletePendingOrder(ticket);
                    continue;
                }
                
                // Ví dụ: Điều chỉnh SL/TP của lệnh chờ nếu cần thiết dựa trên biến động thị trường
                // (Logic này cần cụ thể hóa)
            }
        }
    }
}

// Tính toán giá Stop Loss
double CTradeManager::CalculateStopLossPrice(ENUM_ORDER_TYPE orderType, double entryPrice, double stopDistancePips) {
    if (!CheckContextAndLog("CalculateStopLossPrice", true)) return 0.0;
    if (stopDistancePips <= 0) return 0.0; // SL phải có khoảng cách dương

    double slPrice = 0.0;
    double distance = stopDistancePips * m_Point;

    if (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP) {
        slPrice = entryPrice - distance;
    } else if (orderType == ORDER_TYPE_SELL || orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP) {
        slPrice = entryPrice + distance;
    }
    return NormalizePrice(slPrice);
}

// Tính toán giá Take Profit
double CTradeManager::CalculateTakeProfitPrice(ENUM_ORDER_TYPE orderType, double entryPrice, double takeProfitDistancePips) {
    if (!CheckContextAndLog("CalculateTakeProfitPrice", true)) return 0.0;
    if (takeProfitDistancePips <= 0) return 0.0; // TP phải có khoảng cách dương

    double tpPrice = 0.0;
    double distance = takeProfitDistancePips * m_Point;

    if (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP) {
        tpPrice = entryPrice + distance;
    } else if (orderType == ORDER_TYPE_SELL || orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP) {
        tpPrice = entryPrice - distance;
    }
    return NormalizePrice(tpPrice);
}

// Chuẩn hóa giá theo số chữ số thập phân của symbol
double CTradeManager::NormalizePrice(double price) const {
    if (m_Digits == 0) RefreshSymbolInfo(); // Đảm bảo m_Digits đã được khởi tạo
    if (m_Digits > 0) {
        return NormalizeDouble(price, m_Digits);
    }
    return price; // Trả về giá gốc nếu không có thông tin Digits
}

// Chuẩn hóa khối lượng theo bước khối lượng và min/max volume của symbol
double CTradeManager::NormalizeLots(double lots) const {
    if (!CheckContextAndLog("NormalizeLots", true)) return 0.0;

    double lotStep = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_STEP);
    double minLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
    double maxLot = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MAX);

    if (lotStep <= 0) lotStep = 0.01; // Mặc định nếu không lấy được
    if (minLot <= 0) minLot = lotStep;
    if (maxLot <= 0) maxLot = 1000; // Giới hạn lớn tùy ý

    lots = MathRound(lots / lotStep) * lotStep;
    lots = MathMax(lots, minLot);
    lots = MathMin(lots, maxLot);
    
    return NormalizeDouble(lots, 2); // Thường là 2 chữ số thập phân cho lot
}

// Lấy thông tin slippage thực tế của lệnh cuối cùng
double CTradeManager::GetActualSlippage(ulong orderTicket) {
    if (!CheckContextAndLog("GetActualSlippage", true)) return -1;

    if (!HistoryOrderSelect(orderTicket)) {
        if (m_context->Logger) m_context->Logger->LogWarning(StringFormat("GetActualSlippage: Không thể chọn lệnh lịch sử #%s.", ULongToString(orderTicket)));
        return -1;
    }

    double priceRequested = HistoryOrderGetDouble(orderTicket, ORDER_PRICE_OPEN);
    ulong dealCount = HistoryOrderGetInteger(orderTicket, ORDER_DEALS);
    if (dealCount == 0) {
        if (m_context->Logger) m_context->Logger->LogDebug(StringFormat("GetActualSlippage: Lệnh #%s không có deal nào.", ULongToString(orderTicket)));
        return -1; // Không có deal, không có slippage
    }

    // Lấy deal đầu tiên của lệnh này
    // Cần tìm deal tương ứng với việc mở lệnh
    double priceExecuted = 0;
    bool foundDeal = false;
    HistorySelect(0, TimeCurrent()); // Chọn toàn bộ lịch sử deal
    for (uint i = 0; i < HistoryDealsTotal(); i++) {
        ulong currentDealTicket = HistoryDealGetTicket(i);
        if (HistoryDealGetInteger(currentDealTicket, DEAL_ORDER) == orderTicket) {
            // Kiểm tra xem deal này có phải là deal mở vị thế không
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(currentDealTicket, DEAL_ENTRY);
            if (entry == DEAL_ENTRY_IN || entry == DEAL_ENTRY_OUT_BY) { // DEAL_ENTRY_IN cho mở mới, DEAL_ENTRY_OUT_BY cho đóng bởi lệnh đối ứng (partial close)
                priceExecuted = HistoryDealGetDouble(currentDealTicket, DEAL_PRICE);
                foundDeal = true;
                break;
            }
        }
    }

    if (!foundDeal || priceExecuted == 0) {
        if (m_context->Logger) m_context->Logger->LogDebug(StringFormat("GetActualSlippage: Không tìm thấy deal khớp lệnh mở cho #%s.", ULongToString(orderTicket)));
        return -1;
    }

    double slippagePoints = 0;
    ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)HistoryOrderGetInteger(orderTicket, ORDER_TYPE);

    if (orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP) {
        slippagePoints = (priceExecuted - priceRequested) / m_Point;
    } else if (orderType == ORDER_TYPE_SELL || orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP) {
        slippagePoints = (priceRequested - priceExecuted) / m_Point;
    }
    return slippagePoints;
}

// Lấy kết quả của giao dịch cuối cùng (thắng/thua/hòa)
ENUM_TRADE_RESULT CTradeManager::GetLastTradeResult(ulong& ticketClosed, double& pnl) {
    if (!CheckContextAndLog("GetLastTradeResult", true)) return TRADE_RESULT_NONE;
    ticketClosed = 0;
    pnl = 0.0;

    if (HistoryDealsTotal() == 0) return TRADE_RESULT_NONE;

    // Duyệt ngược lịch sử deal để tìm deal đóng vị thế cuối cùng của EA này
    for (int i = HistoryDealsTotal() - 1; i >= 0; i--) {
        ulong dealTicket = HistoryDealGetTicket(i);
        if (HistoryDealGetInteger(dealTicket, DEAL_MAGIC) == (ulong)m_MagicNumber && 
            HistoryDealGetString(dealTicket, DEAL_SYMBOL) == m_Symbol) {
            
            ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            // Chỉ quan tâm đến deal đóng (DEAL_ENTRY_OUT) hoặc đóng bởi lệnh đối ứng (DEAL_ENTRY_INOUT khi có netting)
            if (entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT) { 
                ticketClosed = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID); // Lấy ticket của vị thế đã đóng
                pnl = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
                if (pnl > 0) return TRADE_RESULT_WIN;
                if (pnl < 0) return TRADE_RESULT_LOSS;
                return TRADE_RESULT_BREAKEVEN;
            }
        }
    }
    return TRADE_RESULT_NONE;
}

// Lấy số lượng vị thế đang mở
int CTradeManager::GetOpenPositionsCount(ENUM_ORDER_TYPE orderTypeFilter) {
    if (!CheckContextAndLog("GetOpenPositionsCount", true)) return -1;
    int count = 0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                if (orderTypeFilter == ORDER_TYPE_NONE) { // Không lọc
                    count++;
                } else {
                    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                    if ((orderTypeFilter == ORDER_TYPE_BUY && posType == POSITION_TYPE_BUY) || 
                        (orderTypeFilter == ORDER_TYPE_SELL && posType == POSITION_TYPE_SELL)) {
                        count++;
                    }
                }
            }
        }
    }
    return count;
}

// Lấy số lượng lệnh chờ
int CTradeManager::GetPendingOrdersCount(ENUM_ORDER_TYPE orderTypeFilter) {
    if (!CheckContextAndLog("GetPendingOrdersCount", true)) return -1;
    int count = 0;
    for (int i = OrdersTotal() - 1; i >= 0; i--) {
        ulong ticket = OrderGetTicket(i);
        if (OrderSelect(ticket)) {
            if (OrderGetInteger(ORDER_MAGIC) == (ulong)m_MagicNumber && OrderGetString(ORDER_SYMBOL) == m_Symbol) {
                if (orderTypeFilter == ORDER_TYPE_NONE) { // Không lọc
                    count++;
                } else {
                    ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
                    if (orderType == orderTypeFilter) {
                        count++;
                    }
                }
            }
        }
    }
    return count;
}

// Lấy tổng khối lượng đang mở
double CTradeManager::GetTotalOpenVolume(ENUM_ORDER_TYPE orderTypeFilter) {
    if (!CheckContextAndLog("GetTotalOpenVolume", true)) return -1.0;
    double totalVolume = 0.0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                if (orderTypeFilter == ORDER_TYPE_NONE) { // Không lọc
                    totalVolume += PositionGetDouble(POSITION_VOLUME);
                } else {
                    ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                    if ((orderTypeFilter == ORDER_TYPE_BUY && posType == POSITION_TYPE_BUY) || 
                        (orderTypeFilter == ORDER_TYPE_SELL && posType == POSITION_TYPE_SELL)) {
                        totalVolume += PositionGetDouble(POSITION_VOLUME);
                    }
                }
            }
        }
    }
    return NormalizeLots(totalVolume);
}

// Lấy tổng lợi nhuận/thua lỗ của các vị thế đang mở cho symbol hiện tại
double CTradeManager::GetNetProfitForSymbol() {
    if (!CheckContextAndLog("GetNetProfitForSymbol", true)) return 0.0;
    double netProfit = 0.0;
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) {
            if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
                netProfit += PositionGetDouble(POSITION_PROFIT);
            }
        }
    }
    return netProfit;
}

// Lấy thông tin vị thế bằng ticket (trả về con trỏ, không sở hữu)
PositionInfo* CTradeManager::GetPositionByTicket(ulong ticket) {
    // Hàm này cần được triển khai nếu bạn muốn lưu trữ PositionInfo đầy đủ
    // Hiện tại, chúng ta dùng PositionSelectByTicket trực tiếp
    // Hoặc có thể trả về một struct tạm thời nếu cần
    if (!CheckContextAndLog("GetPositionByTicket", true)) return NULL;
    
    if (PositionSelectByTicket(ticket)) {
        if (PositionGetInteger(POSITION_MAGIC) == (ulong)m_MagicNumber && PositionGetString(POSITION_SYMBOL) == m_Symbol) {
            // Tạo một đối tượng PositionInfo tạm thời để trả về (người gọi phải tự giải phóng nếu cấp phát động)
            // Hoặc đơn giản là trả về NULL và yêu cầu người gọi tự PositionSelectByTicket
            // Để đơn giản, hàm này sẽ không trả về con trỏ động để tránh quản lý bộ nhớ phức tạp.
            // Người dùng nên dùng PositionSelectByTicket và các hàm PositionGetXXX.
            if (m_context->Logger) m_context->Logger->LogDebug("GetPositionByTicket: Vị thế được chọn. Sử dụng PositionGet... để lấy thông tin.");
            // return &some_statically_or_member_allocated_PositionInfo_object; // Nếu có
            return NULL; // Hoặc báo hiệu rằng người dùng nên tự xử lý
        }
    }
    return NULL;
}

// --- CÁC HÀM QUẢN LÝ VỊ THẾ NÂNG CAO --- 

void CTradeManager::ManageBreakEven(PositionMetadata* meta) {
    if (!CheckContextAndLog("ManageBreakEven", true) || meta == NULL || !m_context->EnableBreakEven)
        return;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ManageBreakEven - Logger is invalid.");
    else printf("CTradeManager::ManageBreakEven - Logger is invalid.");
        return;
    }

    if (!PositionSelectByTicket(meta->ticket)) {
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug(StringFormat("ManageBreakEven: Không thể chọn vị thế #%s.", ULongToString(meta->ticket)));
        return;
    }

    double currentPrice = (meta->isLong) ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double entryPrice = meta->entryPrice;
    double currentSL = PositionGetDouble(POSITION_SL);
    double breakEvenTriggerPips = m_context->BreakEvenTriggerPips;
    double breakEvenSecurePips = m_context->BreakEvenSecurePips;

    if (breakEvenTriggerPips <= 0) return; // BE không được kích hoạt

    double profitInPips = 0;
    if (meta->isLong) {
        profitInPips = (currentPrice - entryPrice) / m_Point;
    } else {
        profitInPips = (entryPrice - currentPrice) / m_Point;
    }

    if (profitInPips >= breakEvenTriggerPips) {
        double newSL = 0;
        if (meta->isLong) {
            newSL = entryPrice + breakEvenSecurePips * m_Point;
        } else {
            newSL = entryPrice - breakEvenSecurePips * m_Point;
        }
        newSL = NormalizePrice(newSL);

        bool shouldModify = false;
        if (meta->isLong) {
            if (newSL > currentSL || currentSL == 0) {
                if (newSL < SymbolInfoDouble(m_Symbol, SYMBOL_ASK) - m_context->MinStopDistancePips * m_Point) {
                    shouldModify = true;
                }
            }
        } else { 
            if (newSL < currentSL || currentSL == 0) {
                if (newSL > SymbolInfoDouble(m_Symbol, SYMBOL_BID) + m_context->MinStopDistancePips * m_Point) {
                    shouldModify = true;
                }
            }
        }
        
        bool alreadyAtSafeBE = false;
        if(meta->isLong && currentSL != 0 && currentSL >= entryPrice + (breakEvenSecurePips - 1) * m_Point) alreadyAtSafeBE = true;
        if(!meta->isLong && currentSL != 0 && currentSL <= entryPrice - (breakEvenSecurePips - 1) * m_Point) alreadyAtSafeBE = true;

        if (shouldModify && !alreadyAtSafeBE) {
            m_context->Logger->LogInfo(StringFormat("ManageBreakEven: Kích hoạt Break-Even cho vị thế #%s. Di chuyển SL đến %.5f.", ULongToString(meta->ticket), newSL));
            ModifyPosition(meta->ticket, newSL, PositionGetDouble(POSITION_TP)); 
        } else {
            if (m_EnableDetailedLogs && !alreadyAtSafeBE)
                m_context->Logger->LogDebug(StringFormat("ManageBreakEven: Điều kiện BE cho #%s không cho phép sửa đổi SL (newSL=%.5f, currentSL=%.5f, ask=%.5f, bid=%.5f).", 
                ULongToString(meta->ticket), newSL, currentSL, SymbolInfoDouble(m_Symbol, SYMBOL_ASK), SymbolInfoDouble(m_Symbol, SYMBOL_BID)));
            else if (m_EnableDetailedLogs && alreadyAtSafeBE)
                m_context->Logger->LogDebug(StringFormat("ManageBreakEven: Vị thế #%s đã ở mức BE an toàn hoặc tốt hơn.", ULongToString(meta->ticket)));
        }
    }
}

void CTradeManager::ManageTrailingStop(PositionMetadata* meta) {
    if (!CheckContextAndLog("ManageTrailingStop", true) || meta == NULL || m_context->TrailingStopType == TRAILING_STOP_NONE)
        return;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ManageTrailingStop - Logger is invalid.");
    else printf("CTradeManager::ManageTrailingStop - Logger is invalid.");
        return;
    }

    if (!PositionSelectByTicket(meta->ticket)) {
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug(StringFormat("ManageTrailingStop: Không thể chọn vị thế #%s.", ULongToString(meta->ticket)));
        return;
    }

    double currentPrice = (meta->isLong) ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double entryPrice = meta->entryPrice;
    double currentSL = PositionGetDouble(POSITION_SL);
    double newSL = currentSL; 

    if (m_context->TrailingStopType == TRAILING_STOP_FIXED_PIPS) {
        double trailingStartPips = m_context->TrailingStartPips;
        double trailingStopPips = m_context->TrailingStopPips;
        double trailingStepPips = m_context->TrailingStepPips; 

        if (trailingStopPips <= 0) return; 

        double profitInPips = 0;
        if (meta->isLong) {
            profitInPips = (currentPrice - entryPrice) / m_Point;
        } else {
            profitInPips = (entryPrice - currentPrice) / m_Point;
        }

        if (profitInPips >= trailingStartPips) {
            double potentialNewSL = 0;
            if (meta->isLong) {
                potentialNewSL = currentPrice - trailingStopPips * m_Point;
            } else {
                potentialNewSL = currentPrice + trailingStopPips * m_Point;
            }
            potentialNewSL = NormalizePrice(potentialNewSL);

            if (meta->isLong) {
                if ((potentialNewSL > currentSL || currentSL == 0) && 
                    (MathAbs(potentialNewSL - currentSL) / m_Point >= trailingStepPips)) {
                    newSL = potentialNewSL;
                }
            } else { 
                if ((potentialNewSL < currentSL || currentSL == 0) && 
                    (MathAbs(potentialNewSL - currentSL) / m_Point >= trailingStepPips)) {
                    newSL = potentialNewSL;
                }
            }
        }
    }
    else if (m_context->TrailingStopType == TRAILING_STOP_ATR) {
        if (m_context->IndicatorUtils == NULL) {
            m_context->Logger->LogWarning("ManageTrailingStop (ATR): IndicatorUtils không khả dụng.");
            return;
        }
        double atrValue = m_context->IndicatorUtils->GetATR(m_context->ATRTrailingPeriod, m_context->ATRTrailingShift);
        if (atrValue <= 0) {
            if (m_EnableDetailedLogs)
                m_context->Logger->LogDebug("ManageTrailingStop (ATR): Giá trị ATR không hợp lệ hoặc bằng 0.");
            return;
        }
        double atrMultiplier = m_context->ATRTrailingMultiplier;
        double trailingDistanceATR = atrValue * atrMultiplier;

        double potentialNewSL_ATR = 0;
        if (meta->isLong) {
            potentialNewSL_ATR = currentPrice - trailingDistanceATR;
        } else {
            potentialNewSL_ATR = currentPrice + trailingDistanceATR;
        }
        potentialNewSL_ATR = NormalizePrice(potentialNewSL_ATR);

        if (meta->isLong) {
            if (potentialNewSL_ATR > currentSL || currentSL == 0) newSL = potentialNewSL_ATR;
        } else {
            if (potentialNewSL_ATR < currentSL || currentSL == 0) newSL = potentialNewSL_ATR;
        }
    }
    else if (m_context->TrailingStopType == TRAILING_STOP_PSAR) {
        if (m_context->IndicatorUtils == NULL) {
            m_context->Logger->LogWarning("ManageTrailingStop (PSAR): IndicatorUtils không khả dụng.");
            return;
        }
        double psarValue = m_context->IndicatorUtils->GetPSAR(m_context->PSARStep, m_context->PSARMax, 1); 
        if (psarValue <= 0) {
            if (m_EnableDetailedLogs)
                m_context->Logger->LogDebug("ManageTrailingStop (PSAR): Giá trị PSAR không hợp lệ hoặc bằng 0.");
            return;
        }
        
        double potentialNewSL_PSAR = NormalizePrice(psarValue);

        if (meta->isLong) {
            if (potentialNewSL_PSAR < currentPrice && (potentialNewSL_PSAR > currentSL || currentSL == 0)) {
                newSL = potentialNewSL_PSAR;
            }
        } else { 
            if (potentialNewSL_PSAR > currentPrice && (potentialNewSL_PSAR < currentSL || currentSL == 0)) {
                newSL = potentialNewSL_PSAR;
            }
        }
    }
    else if (m_context->TrailingStopType == TRAILING_STOP_MA) {
        if (m_context->IndicatorUtils == NULL) {
            m_context->Logger->LogWarning("ManageTrailingStop (MA): IndicatorUtils không khả dụng.");
            return;
        }
        double maValue = m_context->IndicatorUtils->GetMA(m_context->MATrailingPeriod, m_context->MATrailingShift, 
                                                        m_context->MATrailingMethod, m_context->MATrailingAppliedPrice, 1); 
        if (maValue <= 0) {
            if (m_EnableDetailedLogs)
                m_context->Logger->LogDebug("ManageTrailingStop (MA): Giá trị MA không hợp lệ hoặc bằng 0.");
            return;
        }
        double potentialNewSL_MA = NormalizePrice(maValue);

        if (meta->isLong) {
            if (potentialNewSL_MA < currentPrice && (potentialNewSL_MA > currentSL || currentSL == 0)) {
                newSL = potentialNewSL_MA;
            }
        } else { 
            if (potentialNewSL_MA > currentPrice && (potentialNewSL_MA < currentSL || currentSL == 0)) {
                newSL = potentialNewSL_MA;
            }
        }
    }

    if (MathAbs(newSL - currentSL) > m_Point * 0.5) { 
        bool safeToModify = false;
        if (meta->isLong) {
            if (newSL < SymbolInfoDouble(m_Symbol, SYMBOL_ASK) - m_context->MinStopDistancePips * m_Point) {
                safeToModify = true;
            }
        } else { 
            if (newSL > SymbolInfoDouble(m_Symbol, SYMBOL_BID) + m_context->MinStopDistancePips * m_Point) {
                safeToModify = true;
            }
        }

        if (safeToModify) {
            m_context->Logger->LogInfo(StringFormat("ManageTrailingStop (%s): Di chuyển SL cho vị thế #%s từ %.5f đến %.5f.", 
                                                  EnumToString(m_context->TrailingStopType), ULongToString(meta->ticket), currentSL, newSL));
            ModifyPosition(meta->ticket, newSL, PositionGetDouble(POSITION_TP)); 
        } else {
            if (m_EnableDetailedLogs)
                m_context->Logger->LogDebug(StringFormat("ManageTrailingStop (%s): SL mới (%.5f) cho #%s không an toàn (quá gần giá hiện tại Ask:%.5f Bid:%.5f).", 
                EnumToString(m_context->TrailingStopType), newSL, ULongToString(meta->ticket), SymbolInfoDouble(m_Symbol, SYMBOL_ASK), SymbolInfoDouble(m_Symbol, SYMBOL_BID)));
        }
    }
}

void CTradeManager::ManagePartialClose(PositionMetadata* meta) {
    if (!CheckContextAndLog("ManagePartialClose", true) || meta == NULL || !m_context->EnablePartialClose)
        return;
    if (m_context->Logger == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ManagePartialClose - Logger is invalid.");
    else printf("CTradeManager::ManagePartialClose - Logger is invalid.");
        return;
    }

    if (!PositionSelectByTicket(meta->ticket)) {
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug(StringFormat("ManagePartialClose: Không thể chọn vị thế #%s.", ULongToString(meta->ticket)));
        return;
    }

    double currentPrice = (meta->isLong) ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double entryPrice = meta->entryPrice;
    double initialVolume = meta->initialVolume; 
    double currentVolume = PositionGetDouble(POSITION_VOLUME);

    for (int i = 0; i < ArraySize(m_context->PartialTPTargets); i++) {
        if(i >= meta->partialCloseStates.Size()) continue; // Đảm bảo không truy cập ngoài mảng
        PartialTPTarget target = m_context->PartialTPTargets[i];
        if (target.pips <= 0 || target.closePercent <= 0 || target.closePercent > 100) continue;
        if (meta->partialCloseStates.At(i)) continue; 

        double targetPrice = 0;
        if (meta->isLong) {
            targetPrice = entryPrice + target.pips * m_Point;
        } else {
            targetPrice = entryPrice - target.pips * m_Point;
        }

        bool targetReached = false;
        if (meta->isLong && currentPrice >= targetPrice) targetReached = true;
        if (!meta->isLong && currentPrice <= targetPrice) targetReached = true;

        if (targetReached) {
            double volumeToClose = NormalizeLots(initialVolume * (target.closePercent / 100.0));
            volumeToClose = MathMin(volumeToClose, currentVolume);

            if (volumeToClose >= SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN)) {
                m_context->Logger->LogInfo(StringFormat("ManagePartialClose: Đạt TP%d (%.1f pips) cho vị thế #%s. Đóng %.2f lot (%.1f%%).", 
                                                      i + 1, target.pips, ULongToString(meta->ticket), volumeToClose, target.closePercent));
                if (ClosePosition(meta->ticket, volumeToClose, StringFormat("Partial Close TP%d", i+1))) {
                    meta->partialCloseStates.Set(i, true); 
                } else {
                    m_context->Logger->LogError(StringFormat("ManagePartialClose: Lỗi khi đóng một phần cho vị thế #%s tại TP%d.", ULongToString(meta->ticket), i+1));
                }
            } else {
                 if (m_EnableDetailedLogs)
                    m_context->Logger->LogDebug(StringFormat("ManagePartialClose: Khối lượng đóng một phần (%.2f) quá nhỏ cho TP%d, vị thế #%s.", volumeToClose, i+1, ULongToString(meta->ticket)));
            }
        }
    }
}

void CTradeManager::ManageChandelierExit(PositionMetadata* meta) {
    if (!CheckContextAndLog("ManageChandelierExit", true) || meta == NULL || !m_context->EnableChandelierExit)
        return;
    if (m_context->Logger == NULL || m_context->IndicatorUtils == NULL) {
        if(m_context && m_context->Logger) m_context->Logger->LogError("ManageChandelierExit - Invalid Logger or IndicatorUtils.");
    else printf("CTradeManager::ManageChandelierExit - Invalid Logger or IndicatorUtils.");
        return;
    }

    if (!PositionSelectByTicket(meta->ticket)) {
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug(StringFormat("ManageChandelierExit: Không thể chọn vị thế #%s.", ULongToString(meta->ticket)));
        return;
    }

    double atrValue = m_context->IndicatorUtils->GetATR(m_context->ChandelierPeriod, 0); 
    if (atrValue <= 0) {
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug("ManageChandelierExit: Giá trị ATR không hợp lệ hoặc bằng 0.");
        return;
    }

    double chandelierMultiplier = m_context->ChandelierMultiplier;
    double currentSL = PositionGetDouble(POSITION_SL);
    double newSL_Chandelier = 0;

    MqlRates rates[];
    int ratesToCopy = m_context->ChandelierPeriod + 1; 
    if(CopyRates(m_Symbol, Period(), 0, ratesToCopy, rates) < ratesToCopy){
        if (m_EnableDetailedLogs)
            m_context->Logger->LogDebug("ManageChandelierExit: Không đủ dữ liệu nến (cần %d) để tính Chandelier Exit.", ratesToCopy);
        return;
    }

    double highestHigh = rates[1].high;
    double lowestLow = rates[1].low;
    for(int i = 2; i <= m_context->ChandelierPeriod; i++) {
        if(i >= ratesToCopy) break; // Đảm bảo không truy cập ngoài mảng rates
        if(rates[i].high > highestHigh) highestHigh = rates[i].high;
        if(rates[i].low < lowestLow) lowestLow = rates[i].low;
    }

    if (meta->isLong) {
        newSL_Chandelier = highestHigh - atrValue * chandelierMultiplier;
    } else {
        newSL_Chandelier = lowestLow + atrValue * chandelierMultiplier;
    }
    newSL_Chandelier = NormalizePrice(newSL_Chandelier);

    bool shouldModify = false;
    if (meta->isLong) {
        if (newSL_Chandelier < SymbolInfoDouble(m_Symbol, SYMBOL_BID) && (newSL_Chandelier > currentSL || currentSL == 0)) {
            shouldModify = true;
        }
    } else { 
        if (newSL_Chandelier > SymbolInfoDouble(m_Symbol, SYMBOL_ASK) && (newSL_Chandelier < currentSL || currentSL == 0)) {
            shouldModify = true;
        }
    }

    if (shouldModify && MathAbs(newSL_Chandelier - currentSL) > m_Point * 0.5) {
        bool safeToModify = false;
        if (meta->isLong) {
            if (newSL_Chandelier < SymbolInfoDouble(m_Symbol, SYMBOL_ASK) - m_context->MinStopDistancePips * m_Point) {
                safeToModify = true;
            }
        } else { 
            if (newSL_Chandelier > SymbolInfoDouble(m_Symbol, SYMBOL_BID) + m_context->MinStopDistancePips * m_Point) {
                safeToModify = true;
            }
        }

        if(safeToModify){
            m_context->Logger->LogInfo(StringFormat("ManageChandelierExit: Di chuyển SL cho vị thế #%s từ %.5f đến %.5f (ATR:%.5f, HH:%.5f, LL:%.5f).", 
                                                  ULongToString(meta->ticket), currentSL, newSL_Chandelier, atrValue, highestHigh, lowestLow));
            ModifyPosition(meta->ticket, newSL_Chandelier, PositionGetDouble(POSITION_TP)); 
        } else {
            if (m_EnableDetailedLogs)
                m_context->Logger->LogDebug(StringFormat("ManageChandelierExit: SL mới (%.5f) cho #%s không an toàn (quá gần giá hiện tại Ask:%.5f Bid:%.5f).", 
                newSL_Chandelier, ULongToString(meta->ticket), SymbolInfoDouble(m_Symbol, SYMBOL_ASK), SymbolInfoDouble(m_Symbol, SYMBOL_BID)));
        }
    }
}


// Lấy thông tin lệnh chờ bằng ticket (trả về con trỏ, không sở hữu)
OrderInfo* CTradeManager::GetOrderByTicket(ulong ticket) {
    // Tương tự GetPositionByTicket
    if (!CheckContextAndLog("GetOrderByTicket", true)) return NULL;
    if (OrderSelect(ticket)) {
        if (OrderGetInteger(ORDER_MAGIC) == (ulong)m_MagicNumber && OrderGetString(ORDER_SYMBOL) == m_Symbol) {
            if (m_context->Logger) m_context->Logger->LogDebug("GetOrderByTicket: Lệnh chờ được chọn. Sử dụng OrderGet... để lấy thông tin.");
            return NULL;
        }
    }
    return NULL;
}



    // Đóng lệnh
    bool ClosePosition(ulong ticket, string comment = "");
    bool ClosePartialPosition(ulong ticket, double volumeToClose, string comment = "");

    // Sửa đổi lệnh
    bool ModifyPosition(ulong ticket, double newSL, double newTP);
    bool ModifyOrder(ulong ticket, double price, double sl, double tp, datetime expiration = 0);

    // Quản lý lệnh chờ
    bool PlacePendingOrder(ENUM_ORDER_TYPE orderType, double volume, double price, 
                           double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                           datetime expiration = 0, string comment = "");
    bool DeletePendingOrder(ulong ticket);
    
    // ===== CÁC HÀM CẢI TIẾN CHO TRADE EXECUTION =====
    
    // Pre-trade validation và smart execution
    bool ValidateTradeConditions(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                double sl, double tp, ENUM_ENTRY_SCENARIO scenario);
    bool OpenPositionWithRetry(ENUM_ORDER_TYPE orderType, double volume, double price, 
                              double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                              string comment = "", int maxRetries = 3);
    bool ExecuteTradeOrder(ENUM_ORDER_TYPE orderType, double volume, double price, 
                          double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                          string comment, int slippage);
    
    // Market condition analysis
    double CalculateDynamicSpreadThreshold();
    bool IsMarketConditionSuitable(ENUM_ORDER_TYPE orderType);
    bool IsOptimalTradingTime();
    
    // Dynamic slippage và pricing
    int CalculateDynamicSlippage(int retryAttempt);
    double GetOptimalEntryPrice(ENUM_ORDER_TYPE orderType);
    
    // Session và timing utilities
    bool IsLondonSession();
    bool IsNewYorkSession();
    bool IsSessionTransitionTime(const MqlDateTime &timeStruct);
    
    // Helper functions
    ulong GetPositionTicketFromResult(const MqlTradeResult &result);
    double GetAverageATR(int period);

    // Lấy thông tin
    int GetOpenPositionsCount(ENUM_POSITION_TYPE positionType = POSITION_TYPE_BUY, int magic = -1); // -1 for current magic
    double GetTotalOpenVolume(ENUM_POSITION_TYPE positionType = POSITION_TYPE_BUY, int magic = -1);
    bool HasOpenPositions(int magic = -1);
    bool IsPositionOpen(ulong ticket);
    ApexPullback::PositionMetadata GetMetadataForPosition(ulong ticket);
    CArrayObj* GetAllPositionsMetadata(); // Trả về con trỏ tới m_PositionsMetadata

    // Các hàm tiện ích khác
    void UpdateMarketData(); // Cập nhật dữ liệu thị trường cần thiết
    void LogTradeAction(string action, ulong ticket = 0, double price = 0, double volume = 0, string extraInfo = "");
    string GetCurrentSymbol() const { return m_Symbol; }
    int GetMagicNumber() const { return m_MagicNumber; }
    ENUM_EA_STATE GetEAState() const { return m_EAState; }
    void SetEAState(ENUM_EA_STATE state) { m_EAState = state; }

private:
    // Helper function to convert ENUM_ENTRY_SCENARIO to ENUM_STRATEGY_ID
    ENUM_STRATEGY_ID ConvertScenarioToStrategyID(ENUM_ENTRY_SCENARIO scenario) {
        switch(scenario) {
            case SCENARIO_PULLBACK_TREND:
            case SCENARIO_PULLBACK_COUNTER:
            case SCENARIO_PULLBACK_SHALLOW:
                return STRATEGY_ID_PULLBACK;
            case SCENARIO_MEAN_REVERSION_EXTREME:
            case SCENARIO_MEAN_REVERSION_CHANNEL:
                return STRATEGY_ID_MEAN_REVERSION;
            case SCENARIO_BREAKOUT_VOLATILITY:
            case SCENARIO_BREAKOUT_RANGE:
                return STRATEGY_ID_BREAKOUT;
            case SCENARIO_RANGE_TRADING_BOUNDARY:
                return STRATEGY_ID_RANGE_TRADING;
            // TODO: Add mapping for SCENARIO_TREND_FOLLOWING_CONTINUATION if a corresponding STRATEGY_ID exists
            // case SCENARIO_TREND_FOLLOWING_CONTINUATION:
            // return STRATEGY_ID_TREND_FOLLOWING;
            default:
                return STRATEGY_ID_UNDEFINED;
        }
    }

    
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
    
    // --- HÀM NỘI BỘ: PHÂN TÍCH THỊ TRƯỜNG VÀ XÁC NHẬN TÍN HIỆU ---
    
    // Kiểm tra sự đồng thuận giữa MarketProfile và SwingPointDetector
    bool ValidateMarketStructureConsensus(bool isLong) {
        if (m_context == NULL || m_context->MarketProfile == NULL || m_context->SwingDetector == NULL) {
            if (m_context != NULL && m_context->Logger != NULL) m_context->Logger->LogError("ValidateMarketStructureConsensus: m_context hoặc một trong các module MarketProfile, SwingDetector là NULL.");
            return false;
        }

        // Lấy thông tin từ MarketProfile
        // Giả sử GetCurrentProfile() là một phương thức của CMarketProfile và trả về MarketProfileData
        // Cần đảm bảo m_context->MarketProfile được khởi tạo và có thể gọi GetCurrentProfile()
        // MarketProfileData profile = m_context->MarketProfile->GetCurrentProfile(); // Sẽ cần điều chỉnh nếu GetCurrentProfile không tồn tại hoặc có chữ ký khác
        // Tạm thời sử dụng m_currentMarketProfileData nếu nó được cập nhật ở nơi khác
        // Hoặc, nếu MarketProfileData được truyền vào EAContext, truy cập qua m_context
        // Ví dụ: MarketProfileData profile = m_context->CurrentMarketProfile; // Nếu có thành viên này trong EAContext
        // Hiện tại, chúng ta sẽ giả định rằng MarketProfileData được lấy thông qua một hàm của MarketProfile
        // và MarketProfile được truy cập qua m_Context->
        // Để code biên dịch được, chúng ta cần một cách để lấy MarketProfileData.
        // Giả sử có một hàm GetCurrentMarketData() trong CMarketProfile trả về MarketProfileData.
        // Nếu không, logic này cần được xem xét lại dựa trên thiết kế thực tế của CMarketProfile.
        ApexPullback::MarketProfileData profileData; // Khởi tạo mặc định
        if(m_context->MarketProfile->GetMarketData(m_Symbol, PERIOD_CURRENT, profileData)) { // Giả sử hàm này tồn tại
             m_currentMarketProfileData = profileData; // Cập nhật dữ liệu cục bộ nếu cần
        } else {
            if (m_context->Logger) m_context->Logger->LogWarning("ValidateMarketStructureConsensus: Không thể lấy MarketProfileData.");
            return false; // Không thể tiếp tục nếu không có dữ liệu profile
        }

        ENUM_MARKET_TREND trend = m_currentMarketProfileData.trend;
        ENUM_MARKET_REGIME regime = m_currentMarketProfileData.regime;

        // Kiểm tra xu hướng từ SwingPointDetector
        bool swingTrendValid = false;
        if (isLong) {
            swingTrendValid = m_context->SwingDetector->HasHigherHighsAndHigherLows();
        } else {
            swingTrendValid = m_context->SwingDetector->HasLowerHighsAndLowerLows();
        }

        // Kiểm tra cấu trúc thị trường
        bool structureValid = m_context->SwingDetector->HasValidMarketStructure(isLong);

        // Kiểm tra sự đồng thuận
        bool consensusReached = false;
        if (isLong) {
            consensusReached = (trend == TREND_UP_STRONG || trend == TREND_UP_NORMAL) && 
                              swingTrendValid && structureValid;
        } else {
            consensusReached = (trend == TREND_DOWN_STRONG || trend == TREND_DOWN_NORMAL) && 
                              swingTrendValid && structureValid;
        }

        if (m_EnableDetailedLogs && m_context->Logger != NULL) {
            string direction = isLong ? "LONG" : "SHORT";
            m_context->Logger->LogDebug(StringFormat(
                "Market Structure Consensus (%s) - Trend: %s, SwingTrend: %s, Structure: %s => %s",
                direction,
                EnumToString(trend),
                swingTrendValid ? "Valid" : "Invalid",
                structureValid ? "Valid" : "Invalid",
                consensusReached ? "ĐỒNG THUẬN" : "KHÔNG ĐỒNG THUẬN"
            ));
        }

        return consensusReached;
    }

    // --- HÀM NỘI BỘ: XỬ LÝ VỊ THẾ ---

    // Khởi tạo các thành viên và indicator handles
    bool InitializeMembers(); 
    void InitializeIndicators();
    void DeinitializeIndicators();

    // Lấy thông tin symbol
    void RefreshSymbolInfo();

    // Kiểm tra điều kiện vào lệnh
    bool CanOpenNewTrade(ENUM_ORDER_TYPE orderType, double price, double sl, double tp);

    // Quản lý trạng thái giao dịch
    void ManageActivePositions();
    void ManagePendingOrders();

    // Tính toán SL/TP dựa trên R-multiple
    double CalculateStopLossPrice(ENUM_ORDER_TYPE orderType, double entryPrice, double riskAmountInCurrency, double volume);
    double CalculateTakeProfitPrice(ENUM_ORDER_TYPE orderType, double entryPrice, double stopLossPrice, double rrRatio);
    void CalculateMultiLevelTakeProfits(ENUM_ORDER_TYPE orderType, double entryPrice, double stopLossPrice);

    // Các hàm kiểm tra điều kiện thị trường
    bool IsMarketOpen() const;
    bool IsSpreadAcceptable() const;
    bool IsSlippageAcceptable(double requestedPrice, double executedPrice, ENUM_ORDER_TYPE orderType) const;
    bool IsNewsImpactPeriod() const;
    bool IsAllowedTradingSession() const;
    bool IsWithinMaxDailyLossLimit() const;
    bool IsWithinMaxTradesPerDayLimit() const;
    bool IsWithinMaxConsecutiveLossesLimit() const;

    // Các hàm liên quan đến RiskOptimizer
    void InitializeRiskOptimizer();
    double GetOptimizedVolume(double riskPercent, double stopLossPips);

    // Các hàm tiện ích nội bộ
    string GetPositionIdentifier(ulong ticket);
    bool CheckContextAndLog(string functionName, string message = "Context or required module is null.");
    double NormalizePrice(double price) const;
    double NormalizeLots(double lots) const;
    bool IsValidTradeContext() const; // Kiểm tra m_context và các module cần thiết

    
    // Quản lý metadata của vị thế
    void SavePositionMetadata(ulong ticket, double entryPrice, double initialSL, 
                             double initialTP, double initialVolume, bool isLong, 
                             ENUM_ENTRY_SCENARIO scenario);
    bool UpdatePositionMetadata(ulong ticket, double newSL = 0, double newTP = 0, bool isBreakeven = false, bool isPartial1 = false, bool isPartial2 = false, int scalingCount = -1, datetime lastTrailTime = 0, double lastTrailSL = 0);
    ApexPullback::PositionMetadata* GetPositionMetadataPtr(ulong ticket); // Trả về con trỏ để có thể sửa đổi
    void RemovePositionMetadata(ulong ticket);
    void ClearAllMetadata();
    
    // Helper functions để cập nhật metadata
    void UpdatePositionMetadataPartialClose1(ulong ticket, bool status);
    void UpdatePositionMetadataPartialClose2(ulong ticket, bool status);
    void UpdatePositionMetadataBreakeven(ulong ticket, bool status);
    void UpdatePositionMetadataScaling(ulong ticket, int count);
    void UpdatePositionMetadataTrailing(ulong ticket, datetime trailTime, double trailSL);
    
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
    // CTradeManager(); // Original constructor removed
    // ~CTradeManager(); // Destructor is already defined above with the new constructor
    
    // Thiết lập log chi tiết
    void SetDetailedLogging(bool enable) { 
        if(m_context && m_context->Logger) m_context->Logger->SetDetailedLogging(enable);
        m_EnableDetailedLogs = enable; 
    }
    
    // --- KHỜI TẠO VÀ THIẾT LẬP --- (Initialize method removed)
    // bool Initialize(string symbol, int magic, CLogger* logger, 
    //                CMarketProfile* marketProfile, CRiskManager* riskMgr, 
    //                CRiskOptimizer* riskOpt, CAssetProfiler* assetProfiler = NULL,
    //                CNewsFilter* newsFilter = NULL, CSwingDetector* swingDetector = NULL);
    
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
                 ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "",
                 double adjustedLotFactor = 1.0);
    
    // Mở lệnh Sell
    ulong OpenSell(double lotSize, double stopLoss, double takeProfit, 
                  ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE, string comment = "",
                  double adjustedLotFactor = 1.0);
    
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
CTradeManager::CTradeManager(EAContext* context) : m_context(context)
{
    // Khởi tạo giá trị mặc định
    if (m_context && m_context->Logger) m_context->Logger->LogInfo("CTradeManager: Constructor called.");

    m_Symbol = _Symbol;
    m_MagicNumber = 0; // Will be set from context or input parameters later
    m_OrderComment = "Apex Pullback v14";
    m_Digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    m_Point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    m_EnableDetailedLogs = false; // Will be set from context
    
    // Khởi tạo con trỏ (m_context is initialized in the initializer list)
    // m_logger = NULL; // Removed
    // m_marketProfile = NULL; // Removed
    m_riskOptimizer = new CRiskOptimizer(); // Kept as it's an owned object
    // m_riskManager = NULL; // Removed
    // m_assetProfiler = NULL; // Removed
    // m_newsFilter = NULL; // Removed
    // m_swingDetector = NULL; // Removed

    if (m_context)
    {
        m_EnableDetailedLogs = m_context->EnableDetailedLogs;
        // Initialize other members from context if needed
        // Example: m_MagicNumber = m_context->MagicNumberBase; (assuming MagicNumberBase exists in EAContext or Inputs)
        
        // Initialize indicator handles from context if they are managed there
        // or initialize them here if CTradeManager is responsible for them.
        // For now, assuming CTradeManager initializes its own handles as per existing Initialize logic.
        m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14); // Default ATR period
        m_handleEMA34 = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
        m_handleEMA89 = iMA(m_Symbol, PERIOD_CURRENT, 89, 0, MODE_EMA, PRICE_CLOSE);
        m_handleEMA200 = iMA(m_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
        m_handlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2); // Default PSAR params

        if (m_handleATR == INVALID_HANDLE || m_handleEMA34 == INVALID_HANDLE || 
            m_handleEMA89 == INVALID_HANDLE || m_handleEMA200 == INVALID_HANDLE || 
            m_handlePSAR == INVALID_HANDLE) {
            if(m_context->Logger) m_context->Logger->LogError("CTradeManager Error: Failed to initialize one or more indicators in constructor.");
        }
        
        // Set up CTrade object
        m_trade.SetExpertMagicNumber(m_context->MagicNumberBase); // Assuming MagicNumberBase is in context
        m_trade.SetMarginMode();
        m_trade.SetTypeFillingBySymbol(m_Symbol);
        m_trade.SetDeviationInPoints(10); // Or get from context if available

        m_EAState = STATE_RUNNING; // Or STATE_READY, depending on EA logic
        m_IsActive = true;

        if(m_context->Logger) m_context->Logger->LogInfo("CTradeManager constructed and initialized successfully for symbol: " + m_Symbol);

    }
    else
    {
        // This case should ideally not happen if EA is structured correctly.
        printf("CTradeManager CRITICAL: EAContext is NULL in constructor!");
        // Set a state that prevents operation if context is null
        m_EAState = STATE_ERROR;
        m_IsActive = false;
    }
}
    
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
// bool CTradeManager::Initialize(...) // Method removed, initialization logic moved to constructor
// {
//    // ... old implementation removed ...
// }

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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(tpInfo);
    }
}

//+------------------------------------------------------------------+
//| OpenBuy - Mở lệnh Buy                                           |
//+------------------------------------------------------------------+
ulong CTradeManager::OpenBuy(double lotSize, double stopLoss, double takeProfit, 
                           ENUM_ENTRY_SCENARIO scenario, string comment,
                           double adjustedLotFactor)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
        if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể mở lệnh Buy - EA đang " + 
                             EnumToString(m_EAState));
        return 0;
    }
    
    // Lấy giá hiện tại
    double entryPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);

    // Logic MỚI cho Stop Loss lệnh MUA (Ưu tiên #1)
    double sl_price_buy;
    if (m_context && m_context->SwingDetector != NULL) {
        double pullbackLow = m_context->SwingDetector->GetLastSwingLow();
        if (pullbackLow > 0) {
            double sl_buffer = GetCurrentATR() * m_context->StopLossBufferATR_Ratio; // Sử dụng input mới
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
    switch(m_context->TakeProfitMode) { // TakeProfitMode từ Inputs.mqh
        case TP_MODE_RR_FIXED:
            if (entryPrice - stopLoss > 0) { // Đảm bảo SL hợp lệ
                tp_price_buy = entryPrice + (entryPrice - stopLoss) * TakeProfit_RR; // TakeProfit_RR từ Inputs.mqh
            }
            break;

        case TP_MODE_STRUCTURE:
            if (m_context && m_context->SwingDetector != NULL) {
                double targetHigh = m_context->SwingDetector->GetLastSwingHigh();
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
            if (m_context && m_context->MarketProfile != NULL) {
                double adx_value = m_context->MarketProfile->GetADX();
                double atr_multiplier_tp = (adx_value > m_context->ADXThresholdForVolatilityTP) ? m_context->VolatilityTP_ATR_Multiplier_High : m_context->VolatilityTP_ATR_Multiplier_Low; // Sử dụng input mới
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, entryPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
     
     // This duplicated block has been removed as SL/TP logic is handled above and logging is also handled.
    
    double finalLotSize = lotSize * adjustedLotFactor;

    // Encode MagicNumber for the specific strategy
    ENUM_STRATEGY_ID strategyId = ConvertScenarioToStrategyID(scenario);
    int encodedMagic = ::ApexPullback::EncodeMagicNumber(m_MagicNumber, strategyId); 
    int originalMagic = m_trade.ExpertMagicNumber(); 
    m_trade.SetExpertMagicNumber(encodedMagic);

    // Thực hiện lệnh
    bool orderPlaced = m_trade.Buy(finalLotSize, m_Symbol, entryPrice, stopLoss, takeProfit, comment);

    // Restore original magic number
    m_trade.SetExpertMagicNumber(originalMagic);

    if (!orderPlaced) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
        SavePositionMetadata(ticket, entryPrice, stopLoss, takeProfit, finalLotSize, true, scenario);
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh BUY thành công - Ticket: %d, Lot: %.2f",
                ticket, finalLotSize
            ));
        }
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| OpenSell - Mở lệnh Sell                                         |
//+------------------------------------------------------------------+
ulong CTradeManager::OpenSell(double lotSize, double stopLoss, double takeProfit, 
                           ENUM_ENTRY_SCENARIO scenario, string comment,
                           double adjustedLotFactor)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể mở lệnh Sell - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Lấy giá hiện tại
    double entryPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);

    // Logic MỚI cho Stop Loss lệnh BÁN (Ưu tiên #1)
    double sl_price_sell;
    if (m_context && m_context->SwingDetector != NULL) {
        double pullbackHigh = m_context->SwingDetector->GetLastSwingHigh();
        if (pullbackHigh > 0) {
            double sl_buffer = GetCurrentATR() * m_context->StopLossBufferATR_Ratio; // Sử dụng input mới
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
    switch(m_context->TakeProfitMode) { // TakeProfitMode từ Inputs.mqh
        case TP_MODE_RR_FIXED:
            if (stopLoss - entryPrice > 0) { // Đảm bảo SL hợp lệ
                tp_price_sell = entryPrice - (stopLoss - entryPrice) * TakeProfit_RR; // TakeProfit_RR từ Inputs.mqh
            }
            break;

        case TP_MODE_STRUCTURE:
            if (m_context && m_context->SwingDetector != NULL) {
                double targetLow = m_context->SwingDetector->GetLastSwingLow();
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
            if (m_context && m_context->MarketProfile != NULL) {
                double adx_value = m_context->MarketProfile->GetADX();
                double atr_multiplier_tp = (adx_value > m_context->ADXThresholdForVolatilityTP) ? m_context->VolatilityTP_ATR_Multiplier_High : m_context->VolatilityTP_ATR_Multiplier_Low; // Sử dụng input mới
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL - Lot: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, entryPrice, stopLoss, takeProfit, EnumToString(scenario) // Corrected lotSize and price to entryPrice
        ));
    }
     
    // This duplicated block has been removed as SL/TP logic is handled above and logging is also handled.
    
    double finalLotSize = lotSize * adjustedLotFactor;

    // Encode MagicNumber for the specific strategy
    ENUM_STRATEGY_ID strategyId = ConvertScenarioToStrategyID(scenario);
    int encodedMagic = ::ApexPullback::EncodeMagicNumber(m_MagicNumber, strategyId); 
    int originalMagic = m_trade.ExpertMagicNumber();
    m_trade.SetExpertMagicNumber(encodedMagic);

    // Thực hiện lệnh
    bool orderPlaced = m_trade.Sell(finalLotSize, m_Symbol, entryPrice, stopLoss, takeProfit, comment);

    // Restore original magic number
    m_trade.SetExpertMagicNumber(originalMagic);

    if (!orderPlaced) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
        SavePositionMetadata(ticket, entryPrice, stopLoss, takeProfit, finalLotSize, false, scenario);
        
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL thành công - Ticket: %d, Lot: %.2f",
                ticket, finalLotSize
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đặt lệnh Buy Limit - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá limit hợp lệ (phải thấp hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    if (limitPrice >= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY LIMIT - Lot: %.2f, Limit: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, limitPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
     
     // The commented out validation and logging logic has been removed as it's handled earlier or unnecessary.
     
     // Thực hiện lệnh
     if (!m_trade.BuyLimit(lotSize, limitPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
         // Lỗi khi đặt lệnh
         // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
     {
             if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
             if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                 "TradeManager: Đặt lệnh BUY LIMIT thành công - Ticket: %d, Lot: %.2f",
                 ticket, lotSize // Corrected: finalLotSize is not defined here, use lotSize
             ));
         }
     }
     
     return ticket;
}

//+------------------------------------------------------------------+
//| PlaceSellLimit - Đặt lệnh Sell Limit                            |
//+------------------------------------------------------------------+
ulog CTradeManager::PlaceSellLimit(double lotSize, double limitPrice, double stopLoss, double takeProfit, 
                                 ENUM_ENTRY_SCENARIO scenario, string comment)
{
    // Kiểm tra điều kiện
    if (m_EAState != STATE_RUNNING || m_EmergencyMode) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đặt lệnh Sell Limit - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá limit hợp lệ (phải cao hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    if (limitPrice <= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL LIMIT - Lot: %.2f, Limit: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, limitPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.SellLimit(lotSize, limitPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL LIMIT thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize // Corrected: finalLotSize is not defined here, use lotSize
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đặt lệnh Sell Limit - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá limit hợp lệ (phải cao hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    if (limitPrice <= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL LIMIT - Lot: %.2f, Limit: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, limitPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.SellLimit(lotSize, limitPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL LIMIT thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize // Corrected: finalLotSize is not defined here, use lotSize
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đặt lệnh Buy Stop - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá stop hợp lệ (phải cao hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    if (stopPrice <= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh BUY STOP - Lot: %.2f, Stop: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, stopPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.BuyStop(lotSize, stopPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh BUY STOP thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize // Corrected: finalLotSize is not defined here, use lotSize
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đặt lệnh Sell Stop - EA đang " + 
                                 EnumToString(m_EAState));
        }
        return 0;
    }
    
    // Kiểm tra giá stop hợp lệ (phải thấp hơn giá hiện tại)
    double currentPrice = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    if (stopPrice >= currentPrice) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Đặt lệnh SELL STOP - Lot: %.2f, Stop: %.5f, SL: %.5f, TP: %.5f, Scenario: %s",
            lotSize, stopPrice, stopLoss, takeProfit, EnumToString(scenario)
        ));
    }
    
    // Thực hiện lệnh
    if (!m_trade.SellStop(lotSize, stopPrice, m_Symbol, stopLoss, takeProfit, ORDER_TIME_GTC, 0, comment)) {
        // Lỗi khi đặt lệnh
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogError(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
                "TradeManager: Đặt lệnh SELL STOP thành công - Ticket: %d, Lot: %.2f",
                ticket, lotSize // Corrected: finalLotSize is not defined here, use lotSize
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
    if (!m_context->PositionManager->GetOpenTickets(tickets)) { // Assuming GetOpenTickets is part of PositionManager in context
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
            MarketProfileData currentMarketProfile; // Khởi tạo biến
            if(m_context && m_context->MarketProfile) { // Kiểm tra null
                 currentMarketProfile = m_context->MarketProfile->GetLastProfile(); // Lấy thông tin MarketProfile hiện tại, sử dụng -> vì m_marketProfile là con trỏ
            } else {
                // Xử lý trường hợp m_context hoặc m_context->MarketProfile là NULL, ví dụ: ghi log và bỏ qua
                if(m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager::ManageExistingPositions - MarketProfile is NULL.");
                continue; // Hoặc return, tùy theo logic mong muốn
            }
            ENUM_MARKET_REGIME regime = currentMarketProfile.regime;
            bool isMarketTransitioning = currentMarketProfile.isTransitioning; // Sử dụng isTransitioning

            // Logic điều chỉnh dựa trên MarketProfile
            if (isMarketTransitioning && PositionGetDouble(POSITION_PROFIT) > 0) {
                // Nếu xu hướng thay đổi và lệnh đang có lời, đóng 30% vị thế
                double volumeToClose = PositionGetDouble(POSITION_VOLUME) * 0.3;
                if (volumeToClose > 0) {
                    ClosePartialPosition(ticket, volumeToClose, "Trend changing - partial close");
                    // Ghi log hoặc thông báo nếu cần
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("TradeManager: Partial close 30%% for ticket #%d due to market transitioning.", ticket));
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
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("TradeManager: Trailing stop tightened for ticket #%d due to REGIME_RANGING_VOLATILE.", ticket));
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
        if (m_EnableScaling && m_context && m_context->MarketProfile && IsMarketSuitableForScaling(m_context->MarketProfile->GetLastProfile())) { // Sử dụng m_context->MarketProfile->GetLastProfile() thay cho biến profile không xác định
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể sửa vị thế - Ticket không tồn tại: " + 
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
                "TradeManager: Lỗi sửa vị thế #%d - Lỗi: %d, Mô tả: %s",
                ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return false;
    }
    
    // Cập nhật metadata
    UpdatePositionMetadata(ticket, newSL, newTP);
    
    if (m_EnableDetailedLogs) {
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể đóng vị thế - Ticket không tồn tại: " + 
                                 IntegerToString(ticket));
        }
        return false;
    }
    
    // Đóng vị thế
    if (!m_trade.PositionClose(ticket)) {
        // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(logMessage);
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Đóng tất cả vị thế - " + reason);
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Hủy tất cả lệnh chờ");
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
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Hủy lệnh chờ #" + IntegerToString(ticket));
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
                if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
        
        if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Trạng thái EA đã được cập nhật - " + stateStr);
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
        if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Kích hoạt EMERGENCY EXIT - " + reason);
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
            if (m_context && m_context->Logger) m_context->Logger->LogError("TradeManager: Không thể tạo metadata cho vị thế #" + 
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
PositionMetadata CTradeManager::GetPositionMetadata(ulong ticket)
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
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Đã xóa metadata cho vị thế #" + 
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
        if (m_context && m_context->Logger) m_context->Logger->LogInfo("TradeManager: Đã xóa tất cả metadata");
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
        // Lấy swing low từ context (đã được cập nhật bởi SwingDetector)
        if (!m_context->HasValidSwingPoints || m_context->LastSwingLow <= 0) {
            return 0;
        }
        
        // Điều chỉnh buffer
        double buffer = m_Point * 5;
        trailingStop = m_context->LastSwingLow - buffer;
    } else {
        // Lấy swing high từ context (đã được cập nhật bởi SwingDetector)
        if (!m_context->HasValidSwingPoints || m_context->LastSwingHigh <= 0) {
            return 0;
        }
        
        // Điều chỉnh buffer
        double buffer = m_Point * 5;
        trailingStop = m_context->LastSwingHigh + buffer;
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
                "TradeManager: Lỗi đóng một phần vị thế #%d - Lỗi: %d, Mô tả: %s",
                ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return false;
    }
    
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
    if (m_context && m_context->MarketProfile != NULL) {
        profile = m_context->MarketProfile->GetLastProfile();
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
            if (m_context && m_context->Logger) m_context->Logger->LogDebug(StringFormat(
                "TradeManager: Scaling bị từ chối - Đã đạt giới hạn nhồi lệnh: %d",
                m_MaxScalingCount
            ));
        }
        return false;
    }
    
    // Kiểm tra nếu SL đã ở breakeven (nếu yêu cầu)
    if (m_RequireBEForScaling && !metadata.isBreakeven) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Scaling bị từ chối - Vị thế chưa đạt breakeven");
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
            if (m_context && m_context->Logger) m_context->Logger->LogDebug(StringFormat(
                "TradeManager: Scaling bị từ chối - Vị thế chưa đạt 1R (hiện tại: %.2fR)",
                rMultiple
            ));
        }
        return false;
    }
    
    // Kiểm tra chế độ thị trường thích hợp
    if (profile.regime != REGIME_TRENDING) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Scaling bị từ chối - Thị trường không trong xu hướng");
        }
        return false;
    }
    
    // Kiểm tra pullback hợp lệ
    bool validPullback = false;
    
    // Sử dụng SwingDetector nếu có
    if (m_context && m_context->SwingDetector != NULL) {
        double lastSwingPrice = 0;
        
        if (isLong) {
            lastSwingPrice = m_context->SwingDetector->GetLastSwingLow();
            
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
            lastSwingPrice = m_context->SwingDetector->GetLastSwingHigh();
            
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
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Scaling bị từ chối - Không có pullback hợp lệ");
        }
        return false;
    }
    
    // Kiểm tra không có tin tức sắp diễn ra
    if (m_context && m_context->NewsFilter != NULL && m_context->NewsFilter->HasUpcomingNews()) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Scaling bị từ chối - Có tin tức sắp diễn ra");
        }
        return false;
    }
    
    // Tất cả điều kiện thỏa mãn . cho phép nhồi lệnh
    // Kiểm tra logger không cần điều kiện vì logger là biến đối tượng trực tiếp
    {
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
            "TradeManager: Điều kiện nhồi lệnh thỏa mãn cho vị thế #%d - R: %.2f, Pullback hợp lệ: %s",
            ticket, rMultiple, validPullback ? "Có" : "Không"
        ));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| ExecuteScalingOrder - Thực hiện nhồi lệnh                       |
//+------------------------------------------------------------------+
bool CTradeManager::ExecuteScalingOrder(ulong ticket, double scalingPrice, bool isLong, double adjustedLotFactor = 1.0) // Thêm adjustedLotFactor
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
        if (m_context && m_context->Logger) {
            m_context->Logger->LogWarning("TradeManager: Không thể nhồi lệnh - SL không hợp lệ");
        }
        return false;
    }
    
    // Tính toán risk cho lệnh nhồi
    double slPoints = MathAbs(scalingPrice - currentSL) / m_Point;
    
    // Kiểm tra khoảng cách SL
    if (slPoints < 10) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogWarning(StringFormat(
                "TradeManager: Không thể nhồi lệnh - Khoảng cách SL quá nhỏ: %.1f điểm",
                slPoints
            ));
        }
        return false;
    }
    
    // Lấy risk % từ RiskManager
    double baseRisk = 1.0;
    if (m_context && m_context->RiskManager != NULL) {
        baseRisk = m_context->RiskManager->GetCurrentRiskPercent();
    }
    
    // Sử dụng risk thấp hơn cho lệnh nhồi
    double scalingRisk = baseRisk * m_ScalingRiskPercent;
    
    // Tính lot size cho lệnh nhồi
    double lotSize = 0;
    if (m_context->IsRiskOptimizerActive && m_context->OptimalLotSize > 0) {
        // Sử dụng lot size đã được tính toán bởi RiskOptimizer và lưu trong context
        lotSize = m_context->OptimalLotSize * adjustedLotFactor;
    } else {
        // Fallback: sử dụng 50% lot size của lệnh gốc
        lotSize = PositionGetDouble(POSITION_VOLUME) * 0.5 * adjustedLotFactor;
    }
    
    // Kiểm tra lot size hợp lệ
    if (lotSize <= 0) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogWarning("TradeManager: Không thể nhồi lệnh - Lot size không hợp lệ");
        }
        return false;
    }
    
    // Tạo comment cho lệnh nhồi
    string comment = "Scale-in for #" + IntegerToString(ticket);
    
    // Thực hiện lệnh nhồi
    ulong scalingTicket = 0;
    
    if (isLong) {
        scalingTicket = OpenBuy(lotSize, currentSL, currentTP, SCENARIO_SCALING, comment, adjustedLotFactor); // Truyền adjustedLotFactor
    } else {
        scalingTicket = OpenSell(lotSize, currentSL, currentTP, SCENARIO_SCALING, comment, adjustedLotFactor); // Truyền adjustedLotFactor
    }
    
    if (scalingTicket > 0) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogInfo(StringFormat(
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
                    if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat(
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
    if (m_context && m_context->AssetProfiler != NULL) {
        double atr = m_context->AssetProfiler->GetAverageATR();
        double volatilityFactor = m_context->AssetProfiler->GetVolatilityFactor();
        
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
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Không nhồi lệnh - Thị trường không trong xu hướng");
        }
        return false;
    }
    
    // Kiểm tra volatility
    if (profile.isVolatile) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Không nhồi lệnh - Thị trường biến động cao");
        }
        return false;
    }
    
    // Kiểm tra phiên giao dịch
    if (!IsCurrentSessionSuitableForScaling()) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Không nhồi lệnh - Phiên giao dịch không phù hợp");
        }
        return false;
    }
    
    // Kiểm tra tin tức
    if (m_context && m_context->NewsFilter != NULL && m_context->NewsFilter->HasUpcomingNews()) {
        if (m_EnableDetailedLogs) {
            if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Không nhồi lệnh - Có tin tức sắp diễn ra");
        }
        return false;
    }
    
    // Kiểm tra thêm dữ liệu từ AssetProfiler nếu có
    if (m_context && m_context->AssetProfiler != NULL) {
        if (!m_context->AssetProfiler->IsMarketSuitableForTrading()) {
            if (m_EnableDetailedLogs) {
                if (m_context && m_context->Logger) m_context->Logger->LogDebug("TradeManager: Không nhồi lệnh - Asset không phù hợp theo AssetProfiler");
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
        if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat("TradeManager::HandleCloseDeal - Không tìm thấy metadata cho ticket %d", positionTicket));
        return;
    }

    // Lấy thông tin cần thiết từ metadata TRƯỚC KHI xóa
    string scenario_name = EnumToString(metadata.scenario);
    bool is_long = metadata.isLong;
    datetime entry_time = metadata.entryTime; // Thời gian vào lệnh, không phải thời gian đóng

    // Xóa metadata sau khi đã lấy đủ thông tin
    RemovePositionMetadata(positionTicket);

    // Cập nhật thông tin thắng/thua
    if (profit > 0) {
        m_ConsecutiveLosses = 0;
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("TradeManager: Vị thế #%d (%s) đóng lời: %.2f", positionTicket, scenario_name, profit));
    } else if (profit < 0) {
        m_ConsecutiveLosses++;
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("TradeManager: Vị thế #%d (%s) đóng lỗ: %.2f, Thua liên tiếp: %d", positionTicket, scenario_name, profit, m_ConsecutiveLosses));
        if (m_ConsecutiveLosses >= 3) {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat("TradeManager: Cảnh báo thua liên tiếp %d lần", m_ConsecutiveLosses));
        }
    }

    // Cập nhật thông tin thống kê với RiskManager nếu có
    if (m_context && m_context->RiskManager != NULL) {
        m_context->RiskManager->UpdateTradingStats(profit > 0, MathAbs(profit));
    }

    // Ghi lại thông tin giao dịch vào AssetProfiler
    if (m_context && m_context->AssetProfiler != NULL && m_context->MarketProfile != NULL) {
        ENUM_MARKET_REGIME regime_at_entry = REGIME_UNKNOWN; // Giá trị mặc định
        // Cố gắng lấy regime từ MarketProfile tại thời điểm vào lệnh
        // Điều này đòi hỏi MarketProfile phải có khả năng truy vấn lịch sử hoặc lưu trữ regime tại thời điểm vào lệnh
        // Hiện tại, chúng ta sẽ lấy regime hiện tại như một placeholder, cần cải thiện sau
        MarketProfileData currentMarketData;
        if(m_context->MarketProfile->GetMarketProfileData(currentMarketData)){
             regime_at_entry = currentMarketData.regime;
        } else {
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager::HandleCloseDeal - Không thể lấy MarketProfileData để xác định regime_at_entry.");
        }

        double atr_at_entry = GetCurrentATR(); // Tạm thời lấy ATR hiện tại
        double avg_atr_profiler = m_context->AssetProfiler->GetAverageATR(); // Lấy ATR trung bình từ profiler
        double atr_ratio = (avg_atr_profiler > 0) ? (atr_at_entry / avg_atr_profiler) : 1.0;

        MqlDateTime dt_struct;
        TimeToStruct(entry_time, dt_struct);
        int hour_of_day = dt_struct.hour;

        // Tính lợi nhuận theo R
        double r_profit = 0;
        if (metadata.initialSL != 0 && metadata.entryPrice != 0) {
            double risk_per_share = MathAbs(metadata.entryPrice - metadata.initialSL);
            if (risk_per_share > 0) {
                r_profit = profit / (risk_per_share * metadata.initialVolume * SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_CONTRACT_SIZE) / SymbolInfoDouble(m_Symbol, SYMBOL_POINT) ); // Cần điều chỉnh lại công thức tính R cho chính xác
                 // Đơn giản hóa: Nếu SL là X pips, và profit là Y pips, thì R = Y/X
                double sl_pips = MathAbs(metadata.entryPrice - metadata.initialSL) / m_Point;
                double profit_pips = profit / (metadata.initialVolume * SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_TICK_VALUE)); // Profit bằng tiền tệ
                // Chuyển profit tiền tệ sang pips
                double profit_in_currency_per_pip = metadata.initialVolume * SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_TICK_VALUE) / SymbolInfoDouble(m_Symbol, SYMBOL_TRADE_TICK_SIZE);
                if(profit_in_currency_per_pip > 0) {
                    profit_pips = profit / profit_in_currency_per_pip;
                     if (sl_pips > 0) r_profit = profit_pips / sl_pips;
                } else {
                    r_profit = (profit > 0) ? 1.0 : -1.0; // Fallback nếu không tính được
                }
            }
        }

        m_context->AssetProfiler->AddTrade(scenario_name, is_long, profit > 0, r_profit, regime_at_entry, atr_ratio, hour_of_day);
        if (m_context && m_context->Logger) m_context->Logger->LogInfo(StringFormat("TradeManager: Ghi nhận giao dịch vào AssetProfiler - Scenario: %s, Long: %s, Win: %s, R-Profit: %.2f, Regime: %s, ATR Ratio: %.2f, Hour: %d", 
                                scenario_name, 
                                BoolToString(is_long), 
                                BoolToString(profit > 0), 
                                r_profit, 
                                EnumToString(regime_at_entry), 
                                atr_ratio, 
                                hour_of_day));
    } else {
         if(m_context && m_context->AssetProfiler == NULL && m_context->Logger) m_context->Logger->LogWarning("TradeManager::HandleCloseDeal - m_context->AssetProfiler is NULL.");
         if(m_context && m_context->MarketProfile == NULL && m_context->Logger) m_context->Logger->LogWarning("TradeManager::HandleCloseDeal - m_context->MarketProfile is NULL.");
    }
}

//+------------------------------------------------------------------+
//| GetCurrentATR - Lấy ATR hiện tại                                |
//+------------------------------------------------------------------+
double CTradeManager::GetCurrentATR()
{
    // Nếu đã có MarketProfile, lấy ATR từ đó
    if (m_context && m_context->MarketProfile != NULL) {
        return m_context->MarketProfile->GetATR();
    }
    
    // Nếu đã có AssetProfiler, lấy ATR từ đó
    if (m_context && m_context->AssetProfiler != NULL) {
        return m_context->AssetProfiler->GetATR();
    }
    
    // Nếu không có module nào, tính ATR trực tiếp
    if (m_handleATR == INVALID_HANDLE) {
        m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
        if (m_handleATR == INVALID_HANDLE) {
            if (m_context && m_context->Logger) {
                m_context->Logger->LogError("Không thể tạo handle cho ATR.");
            }
            return 0;
        }
    }
    
    // Lấy giá trị ATR
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if (CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogError("Không thể sao chép dữ liệu từ ATR handle.");
        }
        return 0;
    }
    
    return atrBuffer[0];
}

//+------------------------------------------------------------------+
//| GetProfilerATR - Lấy ATR từ AssetProfiler                       |
//+------------------------------------------------------------------+
double CTradeManager::GetProfilerATR()
{
    if (m_context && m_context->AssetProfiler != NULL) {
        return m_context->AssetProfiler->GetAverageATR();
    }
    
    return GetCurrentATR();
}

//+------------------------------------------------------------------+
//| GetEMAValue - Lấy giá trị EMA                                   |
//+------------------------------------------------------------------+
double CTradeManager::GetEMAValue(int emaHandle, int shift)
{
    if (emaHandle == INVALID_HANDLE) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogError("EMA handle không hợp lệ.");
        }
        return 0;
    }
    
    double emaBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    
    if (CopyBuffer(emaHandle, 0, shift, 1, emaBuffer) <= 0) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogError("Không thể sao chép dữ liệu từ EMA handle.");
        }
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Giá không hợp lệ");
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
                if (m_context && m_context->Logger) m_context->Logger->LogWarning("TradeManager: Không thể tính SL tự động");
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
            if (m_context && m_context->Logger) m_context->Logger->LogWarning(StringFormat(
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
    if (m_context == NULL || m_context->MarketProfile == NULL) {
        // Lấy giờ hiện tại (GMT)
        MqlDateTime dt;
        TimeToStruct(TimeGMT(), dt);
        
        // Chỉ nhồi lệnh trong phiên châu Âu và Mỹ (8-16 GMT)
        return (dt.hour >= 8 && dt.hour < 16);
    }
    
    // Sử dụng MarketProfile để kiểm tra phiên
    ENUM_SESSION currentSession = m_context->MarketProfile->GetCurrentSession();
    
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
    if (m_context && m_context->AssetProfiler != NULL) {
        double assetFactor = m_context->AssetProfiler->GetTpSlRatio();
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

//+------------------------------------------------------------------+
//| Kiểm tra sự đồng thuận giữa MarketProfile và SwingPointDetector  |
//+------------------------------------------------------------------+
bool CTradeManager::ValidateMarketStructureConsensus(bool isLong)
{
    if (m_context == NULL || m_context->MarketProfile == NULL || m_context->SwingDetector == NULL) {
        if (m_context && m_context->Logger) {
            m_context->Logger->LogError("TradeManager: MarketProfile hoặc SwingPointDetector chưa được khởi tạo trong context");
        }
        return false;
    }

    // Kiểm tra xu hướng từ MarketProfile
    bool mpTrendValid = false;
    if (isLong) {
        mpTrendValid = m_context->MarketProfile->IsUptrend() && !m_context->MarketProfile->IsDowntrend();
    } else {
        mpTrendValid = m_context->MarketProfile->IsDowntrend() && !m_context->MarketProfile->IsUptrend();
    }

    // Kiểm tra cấu trúc thị trường từ SwingPointDetector
    bool swingStructureValid = m_context->SwingDetector->HasValidMarketStructure(isLong);

    // Ghi log chi tiết về kết quả kiểm tra
    if (m_context && m_context->Logger && m_EnableDetailedLogs) {
        m_context->Logger->LogDebugFormat("TradeManager: Kiểm tra đồng thuận - Lệnh %s", isLong ? "MUA" : "BÁN");
        m_context->Logger->LogDebugFormat("  - MarketProfile trend valid: %s", mpTrendValid ? "Có" : "Không");
        m_context->Logger->LogDebugFormat("  - SwingDetector structure valid: %s", swingStructureValid ? "Có" : "Không");
    }

    // Yêu cầu cả hai module đều xác nhận
    bool consensus = mpTrendValid && swingStructureValid;

    if (m_context && m_context->Logger) {
        if (consensus) {
            m_context->Logger->LogInfo(StringFormat("TradeManager: Đồng thuận xác nhận cho lệnh %s", isLong ? "MUA" : "BÁN"));
        } else {
            m_context->Logger->LogWarning(StringFormat("TradeManager: Không có đồng thuận cho lệnh %s", isLong ? "MUA" : "BÁN"));
        }
    }

    return consensus;
}

} // Kết thúc namespace ApexPullback

//+------------------------------------------------------------------+
//| Đặt trạng thái tạm dừng giao dịch                                |
//+------------------------------------------------------------------+
void CTradeManager::SetTradingPaused(bool paused)
{
    m_isTradingPaused = paused;
    if(m_context && m_context->Logger)
    {
        m_context->Logger->LogInfoFormat("CTradeManager: Trading paused state set to: %s", paused ? "PAUSED" : "ACTIVE");
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
    if(m_context && m_context->Logger)
    {
        m_context->Logger->LogInfoFormat("CTradeManager: Attempting to close all positions with magic number: %d (0 means all EA positions)", magicNumber);
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
            if(m_context && m_context->Logger) m_context->Logger->LogWarningFormat("CTradeManager::CloseAllPositionsByMagic - Failed to select position #%d by ticket %d", i, ticket);
            continue;
        }

        // Kiểm tra symbol và magic number
        if(posInfo.Symbol() == m_Symbol && (magicNumber == 0 || posInfo.Magic() == (ulong)magicNumber) )
        {
            if(m_context && m_context->Logger) m_context->Logger->LogDebugFormat("CTradeManager: Closing position #%d, Ticket: %d, Symbol: %s, Type: %s, Volume: %.2f", 
                                                        i, ticket, posInfo.Symbol(), EnumToString(posInfo.PositionType()), posInfo.Volume());
            
            // Logic đóng lệnh thực tế
            bool closeResult = m_trade.PositionClose(ticket);
            if(closeResult)
            {
                closedCount++;
                if(m_context && m_context->Logger) m_context->Logger->LogInfoFormat("CTradeManager: Successfully closed position ticket %d.", ticket);
            }
            else
            {
                if(m_context && m_context->Logger) m_context->Logger->LogErrorFormat("CTradeManager: Failed to close position ticket %d. Error: %d - %s", ticket, m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription());
            }
        }
    }

    if(m_context && m_context->Logger) m_context->Logger->LogInfoFormat("CTradeManager: Closed %d positions for magic %d.", closedCount, magicNumber);
    // TODO: Có thể cần ChartRedraw() hoặc thông báo cho người dùng
}

// ===== CÁC HÀM CẢI TIẾN CHO TRADE EXECUTION =====

// Pre-trade validation với anti-overfitting
bool CTradeManager::ValidateTradeConditions(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                           double sl, double tp, ENUM_ENTRY_SCENARIO scenario) {
    if (!CheckContextAndLog("ValidateTradeConditions")) return false;
    
    // 1. Kiểm tra cơ bản
    if (volume <= 0 || price <= 0) {
        m_context->Logger->LogError("ValidateTradeConditions: Volume hoặc price không hợp lệ");
        return false;
    }
    
    // 2. Kiểm tra spread và slippage
    double currentSpread = GetCurrentSpreadPips();
    double maxAcceptableSpread = CalculateDynamicSpreadThreshold();
    if (currentSpread > maxAcceptableSpread) {
        m_context->Logger->LogWarning(StringFormat("ValidateTradeConditions: Spread quá cao %.1f > %.1f pips", 
                                                  currentSpread, maxAcceptableSpread));
        return false;
    }
    
    // 3. Kiểm tra market volatility
    if (!IsMarketConditionSuitable(orderType)) {
        m_context->Logger->LogWarning("ValidateTradeConditions: Điều kiện thị trường không phù hợp");
        return false;
    }
    
    // 4. Kiểm tra correlation với các vị thế hiện tại
    if (m_context->RiskManager && !m_context->RiskManager->CheckCorrelationRisk(orderType)) {
        m_context->Logger->LogWarning("ValidateTradeConditions: Rủi ro correlation quá cao");
        return false;
    }
    
    // 5. Kiểm tra timing (tránh news, session transition)
    if (!IsOptimalTradingTime()) {
        m_context->Logger->LogWarning("ValidateTradeConditions: Thời điểm giao dịch không tối ưu");
        return false;
    }
    
    return true;
}

// Tính toán dynamic spread threshold
double CTradeManager::CalculateDynamicSpreadThreshold() {
    if (!m_context || !m_context->RiskManager) return 3.0; // Default 3 pips
    
    double baseThreshold = 2.0; // Base threshold
    double atr = GetATRValue(0); // Current ATR
    double avgATR = GetAverageATR(20); // 20-period average ATR
    
    // Điều chỉnh threshold dựa trên volatility
    double volatilityRatio = (avgATR > 0) ? atr / avgATR : 1.0;
    double adjustedThreshold = baseThreshold * MathMax(1.0, volatilityRatio * 0.5);
    
    // Điều chỉnh theo session
    if (IsLondonSession() || IsNewYorkSession()) {
        adjustedThreshold *= 1.2; // Cho phép spread cao hơn trong session chính
    }
    
    return MathMin(adjustedThreshold, 5.0); // Cap tối đa 5 pips
}

// Kiểm tra điều kiện thị trường
bool CTradeManager::IsMarketConditionSuitable(ENUM_ORDER_TYPE orderType) {
    if (!m_context) return false;
    
    // 1. Kiểm tra volatility
    double currentATR = GetATRValue(0);
    double avgATR = GetAverageATR(20);
    
    if (currentATR > avgATR * 2.0) {
        // Volatility quá cao - rủi ro
        return false;
    }
    
    if (currentATR < avgATR * 0.3) {
        // Volatility quá thấp - không có cơ hội
        return false;
    }
    
    // 2. Kiểm tra trend strength
    if (m_context->MarketProfile) {
        double trendStrength = m_context->MarketProfile->GetTrendStrength();
        if (trendStrength < 0.3) {
            // Thị trường sideway - tránh breakout trades
            if (orderType == ORDER_TYPE_BUY_STOP || orderType == ORDER_TYPE_SELL_STOP) {
                return false;
            }
        }
    }
    
    return true;
}

// Kiểm tra thời điểm giao dịch tối ưu
bool CTradeManager::IsOptimalTradingTime() {
    if (!m_context || !m_context->NewsFilter) return true;
    
    // 1. Kiểm tra news events
    if (m_context->NewsFilter->IsHighImpactNewsTime(5)) { // 5 phút trước news
        return false;
    }
    
    // 2. Kiểm tra session transition
    datetime currentTime = TimeCurrent();
    MqlDateTime timeStruct;
    TimeToStruct(currentTime, timeStruct);
    
    // Tránh 30 phút đầu và cuối session
    if (IsSessionTransitionTime(timeStruct)) {
        return false;
    }
    
    return true;
}

// Enhanced OpenPosition với retry logic
bool CTradeManager::OpenPositionWithRetry(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                         double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                                         string comment = "", int maxRetries = 3) {
    if (!ValidateTradeConditions(orderType, volume, price, sl, tp, scenario)) {
        return false;
    }
    
    int retryCount = 0;
    bool success = false;
    
    while (retryCount < maxRetries && !success) {
        // Điều chỉnh slippage động cho mỗi lần retry
        int dynamicSlippage = CalculateDynamicSlippage(retryCount);
        
        // Cập nhật giá nếu cần
        if (retryCount > 0) {
            price = GetOptimalEntryPrice(orderType);
        }
        
        success = ExecuteTradeOrder(orderType, volume, price, sl, tp, scenario, comment, dynamicSlippage);
        
        if (!success) {
            retryCount++;
            if (retryCount < maxRetries) {
                m_context->Logger->LogWarning(StringFormat("OpenPositionWithRetry: Lần thử %d/%d thất bại, đang retry...", 
                                                          retryCount, maxRetries));
                Sleep(100 * retryCount); // Exponential backoff
            }
        }
    }
    
    if (!success) {
        m_context->Logger->LogError(StringFormat("OpenPositionWithRetry: Thất bại sau %d lần thử", maxRetries));
    }
    
    return success;
}

// Tính toán dynamic slippage
int CTradeManager::CalculateDynamicSlippage(int retryAttempt) {
    if (!m_context) return 10; // Default 10 points
    
    int baseSlippage = m_context->SlippagePips;
    double atr = GetATRValue(0);
    double avgATR = GetAverageATR(20);
    
    // Điều chỉnh theo volatility
    double volatilityMultiplier = (avgATR > 0) ? MathMax(1.0, atr / avgATR) : 1.0;
    
    // Tăng slippage cho mỗi lần retry
    double retryMultiplier = 1.0 + (retryAttempt * 0.5);
    
    int dynamicSlippage = (int)(baseSlippage * volatilityMultiplier * retryMultiplier);
    
    return MathMin(dynamicSlippage, 50); // Cap tối đa 50 points
}

// Lấy giá entry tối ưu
double CTradeManager::GetOptimalEntryPrice(ENUM_ORDER_TYPE orderType) {
    if (orderType == ORDER_TYPE_BUY) {
        return SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    } else if (orderType == ORDER_TYPE_SELL) {
        return SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    }
    
    // Cho pending orders, có thể cần logic phức tạp hơn
    return 0.0;
}

// Execute trade order với enhanced logic
bool CTradeManager::ExecuteTradeOrder(ENUM_ORDER_TYPE orderType, double volume, double price, 
                                     double sl, double tp, ENUM_ENTRY_SCENARIO scenario, 
                                     string comment, int slippage) {
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_Symbol;
    request.volume = NormalizeLots(volume);
    request.magic = m_MagicNumber;
    request.comment = (comment == "") ? m_OrderComment + " " + EnumToString(scenario) : comment;
    request.type = orderType;
    request.price = NormalizePrice(price);
    request.sl = NormalizePrice(sl);
    request.tp = NormalizePrice(tp);
    request.deviation = slippage;
    request.type_filling = FillingMode();
    request.type_time = ORDER_TIME_GTC;
    
    m_EAState = EA_STATE_OPENING_POSITION;
    
    if (!m_trade.OrderSend(request, result)) {
        m_context->Logger->LogError(StringFormat("ExecuteTradeOrder: Lỗi gửi lệnh: %s (Code: %d)", 
                                                m_trade.ResultComment(), m_trade.ResultRetcode()));
        m_EAState = EA_STATE_WAITING_SIGNAL;
        return false;
    }
    
    if (result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED) {
        m_context->Logger->LogInfo(StringFormat("ExecuteTradeOrder: Lệnh thành công. Ticket: %s", 
                                               ULongToString(result.order)));
        
        // Lưu metadata và cập nhật stats
        ulong positionTicket = GetPositionTicketFromResult(result);
        if (positionTicket > 0) {
            SavePositionMetadata(positionTicket, result.price, result.sl, result.tp, 
                               result.volume, (orderType == ORDER_TYPE_BUY), scenario);
            
            if (m_context->RiskManager) {
                m_context->RiskManager->UpdateStatsOnDealOpen(positionTicket, scenario, volume, orderType);
            }
        }
        
        m_EAState = EA_STATE_POSITION_OPENED;
        return true;
    } else {
        m_context->Logger->LogError(StringFormat("ExecuteTradeOrder: Lỗi thực thi: %s (Retcode: %d)", 
                                                result.comment, result.retcode));
        m_EAState = EA_STATE_WAITING_SIGNAL;
        return false;
    }
}

// Helper function để lấy position ticket từ trade result
ulong CTradeManager::GetPositionTicketFromResult(const MqlTradeResult &result) {
    ulong positionTicket = (result.position_id > 0) ? result.position_id : result.order;
    
    if (positionTicket == 0 && result.deal > 0) {
        HistorySelect(0, TimeCurrent());
        uint totalDeals = HistoryDealsTotal();
        for(uint i = 0; i < totalDeals; i++) {
            ulong dealTicket = HistoryDealGetTicket(i);
            if(dealTicket == result.deal) {
                positionTicket = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
                break;
            }
        }
    }
    
    return positionTicket;
}

// Kiểm tra session transition time
bool CTradeManager::IsSessionTransitionTime(const MqlDateTime &timeStruct) {
    int hour = timeStruct.hour;
    int minute = timeStruct.min;
    
    // London open: 08:00 GMT (tránh 07:30-08:30)
    if ((hour == 7 && minute >= 30) || (hour == 8 && minute <= 30)) return true;
    
    // New York open: 13:00 GMT (tránh 12:30-13:30)
    if ((hour == 12 && minute >= 30) || (hour == 13 && minute <= 30)) return true;
    
    // London close: 17:00 GMT (tránh 16:30-17:30)
    if ((hour == 16 && minute >= 30) || (hour == 17 && minute <= 30)) return true;
    
    return false;
}

// Kiểm tra London session
bool CTradeManager::IsLondonSession() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    int hour = timeStruct.hour;
    return (hour >= 8 && hour < 17); // 08:00-17:00 GMT
}

// Kiểm tra New York session
bool CTradeManager::IsNewYorkSession() {
    MqlDateTime timeStruct;
    TimeToStruct(TimeCurrent(), timeStruct);
    int hour = timeStruct.hour;
    return (hour >= 13 && hour < 22); // 13:00-22:00 GMT
}

// Lấy giá trị ATR trung bình
double CTradeManager::GetAverageATR(int period) {
    if (m_handleATR == INVALID_HANDLE) return 0.0;
    
    double atrValues[];
    if (CopyBuffer(m_handleATR, 0, 1, period, atrValues) != period) {
        return 0.0;
    }
    
    double sum = 0.0;
    for (int i = 0; i < period; i++) {
        sum += atrValues[i];
    }
    
    return sum / period;
}

}; // namespace ApexPullback
#endif // TRADEMANAGER_MQH__INCLUDED
//+------------------------------------------------------------------+
//| End of TradeManager.mqh                                          |
//+------------------------------------------------------------------+