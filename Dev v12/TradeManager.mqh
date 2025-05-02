//+------------------------------------------------------------------+
//|              TradeManager.mqh (ApexPullback EA)                  |
//|                  Copyright 2023-2025, ApexTrading Systems        |
//|                           https://www.apextradingsystems.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "12.1"

#pragma once
#include <Trade\Trade.mqh>
#include "MarketProfile.mqh"
#include "RiskOptimizer.mqh"
#include "RiskManager.mqh" // Thêm module RiskManager theo yêu cầu whitepaper
#include "Logger.mqh"

// Các enum và constant cần thiết
enum ENUM_TRAILING_MODE {
    TRAILING_MODE_FIXED,     // Cố định (không trailing)
    TRAILING_MODE_ATR,       // Trailing theo ATR
    TRAILING_MODE_EMA,       // Trailing theo EMA
    TRAILING_MODE_PSAR,      // Trailing theo Parabolic SAR
    TRAILING_MODE_ADAPTIVE   // Trailing thông minh thích ứng theo thị trường
};

enum ENUM_ENTRY_SCENARIO {
    SCENARIO_PULLBACK,       // Pullback vào trend
    SCENARIO_FIBONACCI,      // Fibonacci retracement
    SCENARIO_MOMENTUM,       // Momentum breakout
    SCENARIO_REVERSAL,       // Reversal pattern
    SCENARIO_SCALING         // Scaling (thêm vị thế)
};

// Enum cho các phase thị trường theo yêu cầu whitepaper
enum ENUM_MARKET_PHASE {
   PHASE_ACCUMULATION,    // Tích lũy
   PHASE_IMPULSE,         // Sóng đẩy mạnh
   PHASE_CORRECTION,      // Điều chỉnh
   PHASE_DISTRIBUTION,    // Phân phối
   PHASE_EXHAUSTION       // Cạn kiệt
};

// Enum cho các phiên giao dịch
enum ENUM_SESSION {
    SESSION_ASIAN,           // Phiên Á
    SESSION_EUROPEAN,        // Phiên Âu
    SESSION_AMERICAN,        // Phiên Mỹ
    SESSION_EUROPEAN_AMERICAN, // Phiên giao thoa Âu-Mỹ
    SESSION_CLOSING,         // Phiên đóng cửa
    SESSION_UNKNOWN          // Không xác định
};

//+------------------------------------------------------------------+
//| Class Trade Manager                                              |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
    CTrade         m_trade;                // Đối tượng thực thi giao dịch
    CLogger*       m_logger;               // Logger để ghi log
    CRiskOptimizer* m_riskOptimizer;       // Risk optimizer để tính toán rủi ro
    CRiskManager*  m_riskManager;          // Risk manager để kiểm soát rủi ro tổng thể (thêm mới)
    
    int            m_MagicNumber;          // Magic number để nhận diện EA
    string         m_Symbol;               // Symbol được giao dịch
    int            m_Digits;               // Số chữ số thập phân
    
    // Cập nhật ATR trung bình theo whitepaper
    double         m_AverageATR;           // ATR trung bình 20 ngày
    datetime       m_LastATRUpdateTime;    // Thời gian cập nhật ATR cuối cùng
    
    // Các biến cấu hình
    double         m_BreakEven_R;          // Mức R-multiple để kích hoạt break-even
    bool           m_UseAdaptiveTrailing;  // Có sử dụng trailing thích ứng không
    ENUM_TRAILING_MODE m_TrailingMode;     // Chế độ trailing stop
    double         m_TrailingATRMultiplier; // Hệ số ATR cho trailing stop
    
    // Theo dõi lệnh scaling
    int            m_ScalingCount;          // Số lần đã scaling cho vị thế hiện tại
    int            m_MaxScalingCount;       // Số lần tối đa được phép scaling (giới hạn để không over-leverage)
    
    // Theo dõi partial close
    double         m_PartialCloseR1;        // Mức R-multiple cho partial close lần 1
    double         m_PartialCloseR2;        // Mức R-multiple cho partial close lần 2
    double         m_PartialClosePercent1;  // Phần trăm đóng lần 1
    double         m_PartialClosePercent2;  // Phần trăm đóng lần 2
    
    // Tracking vị thế giao dịch
    struct PositionInfo {
        ulong             ticket;           // Ticket của vị thế
        datetime          openTime;         // Thời gian mở
        double            entryPrice;       // Giá vào
        double            stopLoss;         // Mức stop loss ban đầu
        double            takeProfit;       // Take profit ban đầu
        double            volume;           // Khối lượng
        double            risk;             // % rủi ro
        bool              isLong;           // Long hay Short
        ENUM_ENTRY_SCENARIO scenario;       // Kịch bản vào lệnh
        bool              breakEvenSet;     // Đã đặt break-even chưa
        bool              partialClose1;    // Đã đóng một phần lần 1 chưa
        bool              partialClose2;    // Đã đóng một phần lần 2 chưa
        double            currentRR;        // R-multiple hiện tại
        ENUM_SESSION      openSession;      // Phiên giao dịch khi mở lệnh (thêm mới)
        ENUM_MARKET_PHASE marketPhase;      // Phase thị trường khi mở lệnh (thêm mới)
    };
    
    PositionInfo   m_CurrentPosition;       // Thông tin vị thế hiện tại
    
    // Struct lưu trữ thông tin đỉnh/đáy (thêm mới theo whitepaper)
    struct SwingPoint {
        datetime time;         // Thời gian
        double price;          // Giá
        bool isHigh;           // True = đỉnh, False = đáy
        int strength;          // Độ mạnh (1-10)
    };
    
    SwingPoint    m_RecentSwings[20];      // Mảng lưu trữ các đỉnh đáy gần đây
    
    // Các handles cho indicators (sử dụng trong trailing)
    int            m_handleATR;            // Handle cho ATR
    int            m_handleEMA;            // Handle cho EMA
    int            m_handlePSAR;           // Handle cho Parabolic SAR
    int            m_handleADX;            // Handle cho ADX (thêm mới)
    int            m_handleRSI;            // Handle cho RSI (thêm mới)

public:
    // Constructor & Destructor
    CTradeManager();
    ~CTradeManager();

    // Khởi tạo
    bool Initialize(string symbol, int magic, CLogger* logger, CRiskOptimizer* riskOpt, 
                    CRiskManager* riskMgr, double breakEvenR, bool useAdaptiveTrail, 
                    ENUM_TRAILING_MODE trailingMode);
                    
    // Thêm overload để hỗ trợ cú pháp được yêu cầu
    bool Initialize(string symbol, int magic, CLogger* logger, CRiskOptimizer* riskOpt, 
                   double breakEvenR, bool useAdaptiveTrail, ENUM_TRAILING_MODE trailingMode) {
        return Initialize(symbol, magic, logger, riskOpt, NULL, breakEvenR, useAdaptiveTrail, trailingMode);
    }

    // Quản lý lệnh đang mở
    void ManageOpenPositions(MarketProfile& profile);

    // Mở lệnh BUY/SELL
    ulong ExecuteBuyOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);
    ulong ExecuteSellOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario);

    // Xử lý Scaling (tăng vị thế)
    bool CheckAndExecuteScaling(MarketProfile& profile);

    // Quản lý trailing stop
    void ManageTrailingStop(ulong ticket, ENUM_CLUSTER_TYPE clusterType, ENUM_MARKET_REGIME regime);

    // Quản lý partial close
    void ManagePartialClose(ulong ticket, ENUM_CLUSTER_TYPE clusterType, double achievedRR);

    // Xử lý Emergency Exit
    bool ShouldEmergencyExit(ulong ticket, MarketProfile& profile);

    // Phương thức mới: Cập nhật ATR trung bình
    void UpdateAverageATR();
    
    // Phương thức mới: Xác định phiên giao dịch hiện tại
    ENUM_SESSION DetermineCurrentSession();
    
    // Phương thức mới: Phát hiện phase thị trường
    ENUM_MARKET_PHASE DetectMarketPhase();
    
    // Phương thức mới: Cập nhật danh sách đỉnh đáy
    void UpdateSwingPoints();
    
    // Phương thức mới: Lấy điểm SL tối ưu dựa trên đỉnh/đáy
    double GetOptimalStopLossLevel(bool isLong);
    
    // Phương thức mới: Điều chỉnh trailing stop theo phiên giao dịch
    double AdjustTrailingStopBySession(double baseTrailingStop, ENUM_SESSION session, bool isLong);

    // Công cụ hỗ trợ
    bool HasOpenPosition(string symbol);
    double GetCurrentRR(ulong ticket);
    int GetScalingCount() { return m_ScalingCount; }
    void ResetScalingCount() { m_ScalingCount = 0; }
    void SetTrailingATRMultiplier(double multiplier) { m_TrailingATRMultiplier = multiplier; }
    void SetPartialCloseParams(double r1, double r2, double percent1, double percent2);
    void SetMaxScalingCount(int count) { m_MaxScalingCount = MathMax(1, count); }
    double GetAverageATR() { return m_AverageATR; } // Getter cho ATR trung bình
    
private:
    // Các hàm private phụ trợ
    bool SafeModifyStopLoss(ulong ticket, double newSL);
    void SafeClosePartial(ulong ticket, double volume);
    void RegisterNewPosition(ulong ticket, ENUM_CLUSTER_TYPE cluster, ENUM_ENTRY_SCENARIO scenario);
    void UpdatePositionMetadata(ulong ticket);
    
    // Các hàm tính toán trailing stop
    double CalculateTrailingStopATR(double currentPrice, bool isLong, double atr);
    double CalculateTrailingStopEMA(bool isLong);
    double CalculateTrailingStopPSAR(bool isLong);
    double CalculateTrailingStopAdaptive(double currentPrice, bool isLong, MarketProfile& profile);
    
    // Các hàm xử lý trailing theo regime
    void HandleTrendingTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    void HandleSidewayTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    void HandleVolatileTrailing(ulong ticket, bool isLong, double currentPrice, double atr);
    
    // Phương thức mới: Điều chỉnh SL/TP theo biến động
    void AdjustSLTPBasedOnVolatility(double &stopLoss, double &takeProfit, bool isLong);
    
    // Các hàm hỗ trợ khác
    double GetValidATR();
    bool CheckEMABounce(bool isLong);
    bool DetectVolumeDump();
    bool DetectEMASlopeChange(bool isLong);
    
    // Phương thức mới: Tính độ dốc EMA
    double CalculateEMASlope(int period, int bars);
    
    // Phương thức mới: Tính biến động ATR
    double CalculateATRChange(int period, int bars);
    
    // Phương thức mới: Tính biến động Volume
    double CalculateVolumeChange(int period);
    
    // Phương thức mới: Kiểm tra điểm đỉnh/đáy cục bộ
    bool IsLocalTop(const double &high[], int index);
    bool IsLocalBottom(const double &low[], int index);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager()
{
    // Khởi tạo các biến thành viên mặc định
    m_MagicNumber = 0;
    m_Symbol = "";
    m_logger = NULL;
    m_riskOptimizer = NULL;
    m_riskManager = NULL; // Khởi tạo RiskManager mới
    m_BreakEven_R = 1.0;
    m_UseAdaptiveTrailing = true;
    m_TrailingMode = TRAILING_MODE_ATR;
    m_TrailingATRMultiplier = 2.0;
    m_ScalingCount = 0;
    m_MaxScalingCount = 2;
    m_PartialCloseR1 = 1.5;
    m_PartialCloseR2 = 2.5;
    m_PartialClosePercent1 = 0.3;
    m_PartialClosePercent2 = 0.5;
    
    // Khởi tạo ATR trung bình
    m_AverageATR = 0;
    m_LastATRUpdateTime = 0;
    
    // Khởi tạo handles indicator với giá trị không hợp lệ
    m_handleATR = INVALID_HANDLE;
    m_handleEMA = INVALID_HANDLE;
    m_handlePSAR = INVALID_HANDLE;
    m_handleADX = INVALID_HANDLE;
    m_handleRSI = INVALID_HANDLE;
    
    // Đặt lại thông tin vị thế hiện tại
    ZeroMemory(m_CurrentPosition);
    
    // Đặt lại thông tin đỉnh đáy
    ArrayInitialize(m_RecentSwings, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager()
{
    // Giải phóng handles indicators để tránh memory leak
    if(m_handleATR != INVALID_HANDLE) IndicatorRelease(m_handleATR);
    if(m_handleEMA != INVALID_HANDLE) IndicatorRelease(m_handleEMA);
    if(m_handlePSAR != INVALID_HANDLE) IndicatorRelease(m_handlePSAR);
    if(m_handleADX != INVALID_HANDLE) IndicatorRelease(m_handleADX);
    if(m_handleRSI != INVALID_HANDLE) IndicatorRelease(m_handleRSI);
}

//+------------------------------------------------------------------+
//| Khởi tạo TradeManager                                            |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(string symbol, int magic, CLogger* logger, CRiskOptimizer* riskOpt, 
                             CRiskManager* riskMgr, double breakEvenR, bool useAdaptiveTrail, 
                             ENUM_TRAILING_MODE trailingMode)
{
    // Lưu trữ các tham số
    m_Symbol = symbol;
    m_MagicNumber = magic;
    m_logger = logger;
    m_riskOptimizer = riskOpt;
    m_riskManager = riskMgr; // Lưu trữ RiskManager
    m_BreakEven_R = breakEvenR;
    m_UseAdaptiveTrailing = useAdaptiveTrail;
    m_TrailingMode = trailingMode;
    m_Digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    
    // Cấu hình đối tượng trade
    m_trade.SetExpertMagicNumber(magic);
    
    // Khởi tạo handles cho indicators
    m_handleATR = iATR(m_Symbol, PERIOD_CURRENT, 14);
    m_handleADX = iADX(m_Symbol, PERIOD_CURRENT, 14);
    m_handleRSI = iRSI(m_Symbol, PERIOD_CURRENT, 14, PRICE_CLOSE);
    
    if (m_TrailingMode == ENUM_TRAILING_MODE::TRAILING_MODE_EMA) {
        m_handleEMA = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    }
    
    if (m_TrailingMode == ENUM_TRAILING_MODE::TRAILING_MODE_PSAR) {
        m_handlePSAR = iSAR(m_Symbol, PERIOD_CURRENT, 0.02, 0.2);
    }
    
    // Đặt lại bộ đếm scaling
    m_ScalingCount = 0;
    
    // Khởi tạo ATR trung bình
    UpdateAverageATR();
    
    // Log khởi tạo
    if (m_logger) {
        m_logger.LogInfo("TradeManager initialized for " + symbol + " with magic " + IntegerToString(magic));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Cập nhật ATR trung bình 20 ngày (Tính năng mới theo whitepaper)  |
//+------------------------------------------------------------------+
void CTradeManager::UpdateAverageATR()
{
    static datetime lastUpdateTime = 0;
    datetime currentTime = TimeCurrent();
    
    // Cập nhật mỗi tuần
    if (lastUpdateTime == 0 || (currentTime - lastUpdateTime) > 7*24*60*60) {
        double atrBuffer[20];
        ArraySetAsSeries(atrBuffer, true);
        
        int atrHandle = iATR(m_Symbol, PERIOD_D1, 14);
        if (atrHandle != INVALID_HANDLE) {
            if (CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) == 20) {
                // Tính ATR trung bình 20 ngày
                double avgATR = 0;
                for (int i = 0; i < 20; i++) {
                    avgATR += atrBuffer[i];
                }
                avgATR /= 20;
                
                // Lưu giá trị trung bình để tham chiếu
                m_AverageATR = avgATR;
                
                if (m_logger) {
                    m_logger.LogInfo(StringFormat("Updated Average ATR: %.5f", m_AverageATR));
                }
                
                lastUpdateTime = currentTime;
            }
            IndicatorRelease(atrHandle);
        }
    }
}

//+------------------------------------------------------------------+
//| Điều chỉnh SL/TP dựa trên biến động thị trường (Theo whitepaper) |
//+------------------------------------------------------------------+
void CTradeManager::AdjustSLTPBasedOnVolatility(double &stopLoss, double &takeProfit, bool isLong)
{
    double currentATR = GetValidATR();
    if (currentATR <= 0 || m_AverageATR <= 0) return;
    
    // Tính tỷ lệ biến động hiện tại
    double volatilityRatio = currentATR / m_AverageATR;
    
    // Nếu biến động tăng 20% so với trung bình, mở rộng SL/TP
    if (volatilityRatio > 1.2) {
        double adjustFactor = MathMin(volatilityRatio, 2.0); // Giới hạn tối đa 2x
        
        if (isLong) {
            stopLoss = NormalizeDouble(stopLoss - (currentATR * (adjustFactor - 1.0)), m_Digits);
            takeProfit = NormalizeDouble(takeProfit + (currentATR * (adjustFactor - 1.0)), m_Digits);
        } else {
            stopLoss = NormalizeDouble(stopLoss + (currentATR * (adjustFactor - 1.0)), m_Digits);
            takeProfit = NormalizeDouble(takeProfit - (currentATR * (adjustFactor - 1.0)), m_Digits);
        }
        
        if (m_logger) {
            m_logger.LogInfo(StringFormat("Adjusted SL/TP for higher volatility (%.1f%%): SL=%.5f, TP=%.5f", 
                                       (volatilityRatio - 1.0) * 100, stopLoss, takeProfit));
        }
    }
}

//+------------------------------------------------------------------+
//| Xác định phiên giao dịch hiện tại (Theo whitepaper)              |
//+------------------------------------------------------------------+
ENUM_SESSION CTradeManager::DetermineCurrentSession()
{
    // Lấy giờ GMT
    MqlDateTime dt;
    TimeToStruct(TimeGMT(), dt);
    int hour = dt.hour;
    
    // Phiên Á: 00:00 - 08:00 GMT
    if (hour >= 0 && hour < 8) {
        return SESSION_ASIAN;
    }
    // Phiên Âu: 08:00 - 16:00 GMT
    else if (hour >= 8 && hour < 16) {
        return SESSION_EUROPEAN;
    }
    // Phiên Mỹ: 13:00 - 21:00 GMT (có overlap với phiên Âu)
    else if (hour >= 13 && hour < 21) {
        return SESSION_AMERICAN;
    }
    // Phiên Overlap Âu-Mỹ: 13:00 - 16:00 GMT
    else if (hour >= 13 && hour < 16) {
        return SESSION_EUROPEAN_AMERICAN;
    }
    // Phiên đóng cửa
    else {
        return SESSION_CLOSING;
    }
}

//+------------------------------------------------------------------+
//| Điều chỉnh trailing stop dựa trên phiên giao dịch (Theo whitepaper) |
//+------------------------------------------------------------------+
double CTradeManager::AdjustTrailingStopBySession(double baseTrailingStop, ENUM_SESSION session, bool isLong)
{
    double adjustedStop = baseTrailingStop;
    double atr = GetValidATR();
    
    // Phiên Á dao động nhỏ, trailing sát hơn
    if (session == SESSION_ASIAN) {
        double adjustFactor = 0.7; // Thu hẹp 30%
        if (isLong) {
            adjustedStop = baseTrailingStop + (atr * (1.0 - adjustFactor));
        } else {
            adjustedStop = baseTrailingStop - (atr * (1.0 - adjustFactor));
        }
    }
    // Phiên Âu/Mỹ dao động lớn, trailing rộng hơn
    else if (session == SESSION_EUROPEAN || session == SESSION_AMERICAN) {
        double adjustFactor = 1.2; // Mở rộng 20%
        if (isLong) {
            adjustedStop = baseTrailingStop - (atr * (adjustFactor - 1.0));
        } else {
            adjustedStop = baseTrailingStop + (atr * (adjustFactor - 1.0));
        }
    }
    // Phiên Overlap Âu-Mỹ biến động cao, trailing rộng nhất
    else if (session == SESSION_EUROPEAN_AMERICAN) {
        double adjustFactor = 1.5; // Mở rộng 50%
        if (isLong) {
            adjustedStop = baseTrailingStop - (atr * (adjustFactor - 1.0));
        } else {
            adjustedStop = baseTrailingStop + (atr * (adjustFactor - 1.0));
        }
    }
    
    return NormalizeDouble(adjustedStop, m_Digits);
}

//+------------------------------------------------------------------+
//| Phát hiện pha thị trường hiện tại (Theo whitepaper)              |
//+------------------------------------------------------------------+
ENUM_MARKET_PHASE CTradeManager::DetectMarketPhase()
{
   // Tính độ dốc EMA
   double emaSlope = CalculateEMASlope(34, 10);
   
   // Tính biến động ATR
   double atrChange = CalculateATRChange(14, 10);
   
   // Tính volume dynamics
   double volumeChange = CalculateVolumeChange(20);
   
   // Phân tích pha thị trường
   if (emaSlope > 0.5 && atrChange > 0.2 && volumeChange > 0.3) {
      // Sóng đẩy: EMA dốc, ATR tăng, volume tăng
      return PHASE_IMPULSE;
   }
   else if (emaSlope > 0.1 && emaSlope < 0.3 && atrChange < 0) {
      // Điều chỉnh: EMA dốc nhẹ, ATR giảm
      return PHASE_CORRECTION;
   }
   else if (emaSlope < 0.1 && atrChange < -0.3) {
      // Tích lũy: EMA ngang, ATR giảm nhiều
      return PHASE_ACCUMULATION;
   }
   else if (emaSlope > 0.7 && atrChange > 0.5 && volumeChange < 0) {
      // Cạn kiệt: EMA dốc cao, ATR cao, volume giảm
      return PHASE_EXHAUSTION;
   }
   else if (emaSlope < -0.1 && volumeChange > 0.2) {
      // Phân phối: EMA đi xuống, volume tăng
      return PHASE_DISTRIBUTION;
   }
   
   // Mặc định là điều chỉnh nếu không xác định được rõ ràng
   return PHASE_CORRECTION;
}

//+------------------------------------------------------------------+
//| Tính độ dốc EMA trong n nến                                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateEMASlope(int period, int bars)
{
    int emaHandle = iMA(m_Symbol, PERIOD_CURRENT, period, 0, MODE_EMA, PRICE_CLOSE);
    if (emaHandle == INVALID_HANDLE) return 0;
    
    double emaBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    
    if (CopyBuffer(emaHandle, 0, 0, bars + 1, emaBuffer) <= 0) {
        IndicatorRelease(emaHandle);
        return 0;
    }
    
    // Tính độ dốc (end - start) / bars
    double slope = (emaBuffer[0] - emaBuffer[bars]) / bars;
    
    // Chuẩn hóa slope theo ATR để có thể so sánh giữa các cặp tiền
    double atr = GetValidATR();
    if (atr > 0) {
        slope = slope / atr;
    }
    
    IndicatorRelease(emaHandle);
    return slope;
}

//+------------------------------------------------------------------+
//| Tính sự thay đổi ATR so với n nến trước                         |
//+------------------------------------------------------------------+
double CTradeManager::CalculateATRChange(int period, int bars)
{
    int atrHandle = iATR(m_Symbol, PERIOD_CURRENT, period);
    if (atrHandle == INVALID_HANDLE) return 0;
    
    double atrBuffer[];
    ArraySetAsSeries(atrBuffer, true);
    
    if (CopyBuffer(atrHandle, 0, 0, bars + 1, atrBuffer) <= 0) {
        IndicatorRelease(atrHandle);
        return 0;
    }
    
    // Tính % thay đổi ATR
    double change = (atrBuffer[0] - atrBuffer[bars]) / atrBuffer[bars];
    
    IndicatorRelease(atrHandle);
    return change;
}

//+------------------------------------------------------------------+
//| Tính sự thay đổi volume so với n nến trước                      |
//+------------------------------------------------------------------+
double CTradeManager::CalculateVolumeChange(int period)
{
    long volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    
    if (CopyTickVolume(m_Symbol, PERIOD_CURRENT, 0, period + 1, volumeBuffer) <= 0) {
        return 0;
    }
    
    // Tính volume trung bình 5 nến trước và hiện tại
    long currentAvg = 0;
    for (int i = 0; i < 5; i++) {
        currentAvg += volumeBuffer[i];
    }
    currentAvg /= 5;
    
    long previousAvg = 0;
    for (int i = period - 5; i < period; i++) {
        previousAvg += volumeBuffer[i];
    }
    previousAvg /= 5;
    
    // Tính % thay đổi volume
    if (previousAvg > 0) {
        return (double)(currentAvg - previousAvg) / previousAvg;
    }
    
    return 0;
}

//+------------------------------------------------------------------+
//| Cập nhật danh sách các đỉnh đáy (Tính năng mới theo whitepaper)  |
//+------------------------------------------------------------------+
void CTradeManager::UpdateSwingPoints()
{
   // Lấy dữ liệu giá
   double high[], low[];
   datetime time[];
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(time, true);
   
   CopyHigh(m_Symbol, PERIOD_H4, 0, 100, high);
   CopyLow(m_Symbol, PERIOD_H4, 0, 100, low);
   CopyTime(m_Symbol, PERIOD_H4, 0, 100, time);
   
   // Tìm các đỉnh
   int swingCount = 0;
   
   for (int i = 5; i < 95; i++) {
      // Kiểm tra swing high
      if (IsLocalTop(high, i)) {
         // Đã tìm thấy swing high
         m_RecentSwings[swingCount].time = time[i];
         m_RecentSwings[swingCount].price = high[i];
         m_RecentSwings[swingCount].isHigh = true;
         
         // Tính độ mạnh dựa trên number of bars và biên độ
         double magnitude = (high[i] - MathMin(low[i-1], low[i+1])) / GetValidATR();
         m_RecentSwings[swingCount].strength = (int)MathMin(10, magnitude * 3);
         
         swingCount++;
         if (swingCount >= 20) break;
      }
      
      // Kiểm tra swing low
      if (IsLocalBottom(low, i)) {
         // Đã tìm thấy swing low
         m_RecentSwings[swingCount].time = time[i];
         m_RecentSwings[swingCount].price = low[i];
         m_RecentSwings[swingCount].isHigh = false;
         
         // Tính độ mạnh
         double magnitude = (MathMax(high[i-1], high[i+1]) - low[i]) / GetValidATR();
         m_RecentSwings[swingCount].strength = (int)MathMin(10, magnitude * 3);
         
         swingCount++;
         if (swingCount >= 20) break;
      }
   }
}

//+------------------------------------------------------------------+
//| Kiểm tra điểm đỉnh cục bộ                                        |
//+------------------------------------------------------------------+
bool CTradeManager::IsLocalTop(const double &high[], int index)
{
   // Kiểm tra xem giá high[index] có phải là đỉnh cục bộ không
   // (cao hơn n nến trước và sau đó)
   for (int i = 1; i <= 3; i++) {
      if (high[index-i] >= high[index] || high[index+i] >= high[index]) {
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra điểm đáy cục bộ                                         |
//+------------------------------------------------------------------+
bool CTradeManager::IsLocalBottom(const double &low[], int index)
{
   // Kiểm tra xem giá low[index] có phải là đáy cục bộ không
   // (thấp hơn n nến trước và sau đó)
   for (int i = 1; i <= 3; i++) {
      if (low[index-i] <= low[index] || low[index+i] <= low[index]) {
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| Lấy đỉnh/đáy gần nhất làm điểm SL tối ưu (Theo whitepaper)       |
//+------------------------------------------------------------------+
double CTradeManager::GetOptimalStopLossLevel(bool isLong)
{
   UpdateSwingPoints();
   
   // Tìm swing point phù hợp
   for (int i = 0; i < 20; i++) {
      if (m_RecentSwings[i].time == 0) continue;
      
      if (isLong && !m_RecentSwings[i].isHigh) {
         // Tìm đáy gần nhất cho lệnh Buy
         if (m_RecentSwings[i].strength >= 5) {
            // Trả về giá đáy - buffer ATR
            return m_RecentSwings[i].price - (GetValidATR() * 0.3);
         }
      }
      else if (!isLong && m_RecentSwings[i].isHigh) {
         // Tìm đỉnh gần nhất cho lệnh Sell
         if (m_RecentSwings[i].strength >= 5) {
            // Trả về giá đỉnh + buffer ATR
            return m_RecentSwings[i].price + (GetValidATR() * 0.3);
         }
      }
   }
   
   // Nếu không tìm thấy swing point phù hợp, sử dụng SL mặc định
   double atr = GetValidATR();
   return isLong ? 
          SymbolInfoDouble(m_Symbol, SYMBOL_BID) - (atr * 1.5) : 
          SymbolInfoDouble(m_Symbol, SYMBOL_ASK) + (atr * 1.5);
}

//+------------------------------------------------------------------+
//| Đặt tham số cho Partial Close                                    |
//+------------------------------------------------------------------+
void CTradeManager::SetPartialCloseParams(double r1, double r2, double percent1, double percent2)
{
    // Thiết lập mức R-multiple cho partial close
    m_PartialCloseR1 = MathMax(0.5, r1);
    m_PartialCloseR2 = MathMax(m_PartialCloseR1 + 0.5, r2);
    
    // Thiết lập phần trăm đóng (đảm bảo giá trị hợp lệ 0-1)
    m_PartialClosePercent1 = MathMin(MathMax(0.1, percent1), 0.9);
    m_PartialClosePercent2 = MathMin(MathMax(0.1, percent2), 0.9);
    
    if (m_logger) {
        m_logger.LogInfo(StringFormat(
            "Partial close parameters set: R1=%.1f, R2=%.1f, Percent1=%.1f%%, Percent2=%.1f%%",
            m_PartialCloseR1, m_PartialCloseR2, m_PartialClosePercent1 * 100, m_PartialClosePercent2 * 100
        ));
    }
}

//+------------------------------------------------------------------+
//| Thực thi lệnh BUY                                                |
//+------------------------------------------------------------------+
ulong CTradeManager::ExecuteBuyOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
    // Kiểm tra tham số đầu vào
    if (lotSize <= 0) {
        if (m_logger) m_logger.LogError("Invalid lot size for buy order: " + DoubleToString(lotSize, 2));
        return 0;
    }
    
    // Kiểm tra RiskManager trước khi mở lệnh mới
    if (scenario != SCENARIO_SCALING && m_riskManager != NULL) {
        // Kiểm tra các ràng buộc toàn cục
        if (!m_riskManager.CanOpenNewPosition(lotSize, true)) {
            if (m_logger) {
                m_logger.LogWarning("RiskManager rejected opening new BUY position due to risk limits");
            }
            return 0;
        }
    }
    
    // Lấy giá hiện tại
    double price = SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    
    // Nếu không cung cấp stop loss, lấy từ RiskOptimizer
    if (stopLoss <= 0 && m_riskOptimizer != NULL) {
        stopLoss = m_riskOptimizer.CalculateStopLoss(true, price);
    }
    
    // Nếu vẫn không có stop loss, thử dùng GetOptimalStopLossLevel
    if (stopLoss <= 0) {
        stopLoss = GetOptimalStopLossLevel(true);
    }
    
    // Nếu vẫn không có stop loss, sử dụng ATR
    if (stopLoss <= 0) {
        double atr = GetValidATR();
        if (atr > 0) {
            stopLoss = price - (atr * 1.5);
        } else {
            if (m_logger) m_logger.LogError("Failed to calculate stop loss for buy order");
            return 0;
        }
    }
    
    // Nếu không cung cấp take profit, lấy từ RiskOptimizer
    if (takeProfit <= 0 && m_riskOptimizer != NULL) {
        takeProfit = m_riskOptimizer.CalculateTakeProfit(true, price, stopLoss);
    }
    
    // Nếu vẫn không có take profit, tính dựa trên stop loss (risk:reward 1:2)
    if (takeProfit <= 0) {
        double risk = price - stopLoss;
        takeProfit = price + (risk * 2.0);
    }
    
    // Điều chỉnh SL/TP dựa trên biến động thị trường
    AdjustSLTPBasedOnVolatility(stopLoss, takeProfit, true);
    
    // Chuẩn hóa giá trị
    stopLoss = NormalizeDouble(stopLoss, m_Digits);
    takeProfit = NormalizeDouble(takeProfit, m_Digits);
    
    // Tạo comment cho lệnh
    string orderComment = "ApexPB_";
    
    switch (scenario) {
        case SCENARIO_PULLBACK:      orderComment += "PULL"; break;
        case SCENARIO_FIBONACCI:     orderComment += "FIB"; break;
        case SCENARIO_MOMENTUM:      orderComment += "MOM"; break;
        case SCENARIO_REVERSAL:      orderComment += "REV"; break;
        case SCENARIO_SCALING:       orderComment += "SCALE"; break;
        default:                     orderComment += "BUY"; break;
    }
    
    // Xác định phiên giao dịch hiện tại và thêm vào comment
    ENUM_SESSION currentSession = DetermineCurrentSession();
    switch (currentSession) {
        case SESSION_ASIAN:            orderComment += "_AS"; break;
        case SESSION_EUROPEAN:         orderComment += "_EU"; break;
        case SESSION_AMERICAN:         orderComment += "_US"; break;
        case SESSION_EUROPEAN_AMERICAN: orderComment += "_EUUS"; break;
        default: break;
    }
    
    // Thực thi lệnh
    if (!m_trade.Buy(lotSize, m_Symbol, 0, stopLoss, takeProfit, orderComment)) {
        if (m_logger) {
            m_logger.LogError(StringFormat(
                "Failed to execute buy order: Error %d (%s)",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket từ kết quả giao dịch
    ulong ticket = m_trade.ResultOrder();
    
    // Phát hiện phase thị trường hiện tại
    ENUM_MARKET_PHASE currentPhase = DetectMarketPhase();
    
    // Lưu thông tin vị thế nếu là vị thế mới (không phải scaling)
    if (scenario != SCENARIO_SCALING) {
        m_ScalingCount = 0;
        
        // Lưu thông tin vị thế hiện tại
        m_CurrentPosition.ticket = ticket;
        m_CurrentPosition.openTime = TimeCurrent();
        m_CurrentPosition.entryPrice = price;
        m_CurrentPosition.stopLoss = stopLoss;
        m_CurrentPosition.takeProfit = takeProfit;
        m_CurrentPosition.volume = lotSize;
        m_CurrentPosition.isLong = true;
        m_CurrentPosition.scenario = scenario;
        m_CurrentPosition.breakEvenSet = false;
        m_CurrentPosition.partialClose1 = false;
        m_CurrentPosition.partialClose2 = false;
        m_CurrentPosition.openSession = currentSession;
        m_CurrentPosition.marketPhase = currentPhase;
        
        // Tính risk percentage nếu có RiskOptimizer
        if (m_riskOptimizer != NULL) {
            m_CurrentPosition.risk = m_riskOptimizer.GetLastRiskPercent();
        } else {
            m_CurrentPosition.risk = 0; // Unknown
        }
        
        // Thông báo cho RiskManager về vị thế mới
        if (m_riskManager != NULL) {
            m_riskManager.RegisterNewPosition(ticket, lotSize, m_CurrentPosition.risk);
        }
    } else {
        // Tăng số đếm scaling nếu là lệnh scaling
        m_ScalingCount++;
    }
    
    // Log thông tin lệnh
    if (m_logger) {
        m_logger.LogInfo(StringFormat(
            "BUY order executed (#%llu): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Session: %s, Phase: %s, Scenario: %s",
            ticket, lotSize, price, stopLoss, takeProfit, 
            EnumToString((ENUM_SESSION)currentSession),
            EnumToString((ENUM_MARKET_PHASE)currentPhase),
            orderComment
        ));
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| Thực thi lệnh SELL                                               |
//+------------------------------------------------------------------+
ulong CTradeManager::ExecuteSellOrder(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario)
{
    // Kiểm tra tham số đầu vào
    if (lotSize <= 0) {
        if (m_logger) m_logger.LogError("Invalid lot size for sell order: " + DoubleToString(lotSize, 2));
        return 0;
    }
    
    // Kiểm tra RiskManager trước khi mở lệnh mới
    if (scenario != SCENARIO_SCALING && m_riskManager != NULL) {
        // Kiểm tra các ràng buộc toàn cục
        if (!m_riskManager.CanOpenNewPosition(lotSize, false)) {
            if (m_logger) {
                m_logger.LogWarning("RiskManager rejected opening new SELL position due to risk limits");
            }
            return 0;
        }
    }
    
    // Lấy giá hiện tại
    double price = SymbolInfoDouble(m_Symbol, SYMBOL_BID);
    
    // Nếu không cung cấp stop loss, lấy từ RiskOptimizer
    if (stopLoss <= 0 && m_riskOptimizer != NULL) {
        stopLoss = m_riskOptimizer.CalculateStopLoss(false, price);
    }
    
    // Nếu vẫn không có stop loss, thử dùng GetOptimalStopLossLevel
    if (stopLoss <= 0) {
        stopLoss = GetOptimalStopLossLevel(false);
    }
    
    // Nếu vẫn không có stop loss, sử dụng ATR
    if (stopLoss <= 0) {
        double atr = GetValidATR();
        if (atr > 0) {
            stopLoss = price + (atr * 1.5);
        } else {
            if (m_logger) m_logger.LogError("Failed to calculate stop loss for sell order");
            return 0;
        }
    }
    
    // Nếu không cung cấp take profit, lấy từ RiskOptimizer
    if (takeProfit <= 0 && m_riskOptimizer != NULL) {
        takeProfit = m_riskOptimizer.CalculateTakeProfit(false, price, stopLoss);
    }
    
    // Nếu vẫn không có take profit, tính dựa trên stop loss (risk:reward 1:2)
    if (takeProfit <= 0) {
        double risk = stopLoss - price;
        takeProfit = price - (risk * 2.0);
    }
    
    // Điều chỉnh SL/TP dựa trên biến động thị trường
    AdjustSLTPBasedOnVolatility(stopLoss, takeProfit, false);
    
    // Chuẩn hóa giá trị
    stopLoss = NormalizeDouble(stopLoss, m_Digits);
    takeProfit = NormalizeDouble(takeProfit, m_Digits);
    
    // Tạo comment cho lệnh
    string orderComment = "ApexPB_";
    
    switch (scenario) {
        case SCENARIO_PULLBACK:      orderComment += "PULL"; break;
        case SCENARIO_FIBONACCI:     orderComment += "FIB"; break;
        case SCENARIO_MOMENTUM:      orderComment += "MOM"; break;
        case SCENARIO_REVERSAL:      orderComment += "REV"; break;
        case SCENARIO_SCALING:       orderComment += "SCALE"; break;
        default:                     orderComment += "SELL"; break;
    }
    
    // Xác định phiên giao dịch hiện tại và thêm vào comment
    ENUM_SESSION currentSession = DetermineCurrentSession();
    switch (currentSession) {
        case SESSION_ASIAN:            orderComment += "_AS"; break;
        case SESSION_EUROPEAN:         orderComment += "_EU"; break;
        case SESSION_AMERICAN:         orderComment += "_US"; break;
        case SESSION_EUROPEAN_AMERICAN: orderComment += "_EUUS"; break;
        default: break;
    }
    
    // Thực thi lệnh
    if (!m_trade.Sell(lotSize, m_Symbol, 0, stopLoss, takeProfit, orderComment)) {
        if (m_logger) {
            m_logger.LogError(StringFormat(
                "Failed to execute sell order: Error %d (%s)",
                m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
            ));
        }
        return 0;
    }
    
    // Lấy ticket từ kết quả giao dịch
    ulong ticket = m_trade.ResultOrder();
    
    // Phát hiện phase thị trường hiện tại
    ENUM_MARKET_PHASE currentPhase = DetectMarketPhase();
    
    // Lưu thông tin vị thế nếu là vị thế mới (không phải scaling)
    if (scenario != SCENARIO_SCALING) {
        m_ScalingCount = 0;
        
        // Lưu thông tin vị thế hiện tại
        m_CurrentPosition.ticket = ticket;
        m_CurrentPosition.openTime = TimeCurrent();
        m_CurrentPosition.entryPrice = price;
        m_CurrentPosition.stopLoss = stopLoss;
        m_CurrentPosition.takeProfit = takeProfit;
        m_CurrentPosition.volume = lotSize;
        m_CurrentPosition.isLong = false;
        m_CurrentPosition.scenario = scenario;
        m_CurrentPosition.breakEvenSet = false;
        m_CurrentPosition.partialClose1 = false;
        m_CurrentPosition.partialClose2 = false;
        m_CurrentPosition.openSession = currentSession;
        m_CurrentPosition.marketPhase = currentPhase;
        
        // Tính risk percentage nếu có RiskOptimizer
        if (m_riskOptimizer != NULL) {
            m_CurrentPosition.risk = m_riskOptimizer.GetLastRiskPercent();
        } else {
            m_CurrentPosition.risk = 0; // Unknown
        }
        
        // Thông báo cho RiskManager về vị thế mới
        if (m_riskManager != NULL) {
            m_riskManager.RegisterNewPosition(ticket, lotSize, m_CurrentPosition.risk);
        }
    } else {
        // Tăng số đếm scaling nếu là lệnh scaling
        m_ScalingCount++;
    }
    
    // Log thông tin lệnh
    if (m_logger) {
        m_logger.LogInfo(StringFormat(
            "SELL order executed (#%llu): %.2f lots at %.5f, SL: %.5f, TP: %.5f, Session: %s, Phase: %s, Scenario: %s",
            ticket, lotSize, price, stopLoss, takeProfit, 
            EnumToString((ENUM_SESSION)currentSession),
            EnumToString((ENUM_MARKET_PHASE)currentPhase),
            orderComment
        ));
    }
    
    return ticket;
}

//+------------------------------------------------------------------+
//| Kiểm tra và thực hiện Scaling (tăng vị thế)                     |
//+------------------------------------------------------------------+
bool CTradeManager::CheckAndExecuteScaling(MarketProfile& profile)
{
    // Kiểm tra điều kiện cơ bản trước khi xem xét scaling
    
    // 1. Phải có vị thế đang mở
    if (m_CurrentPosition.ticket == 0 || !HasOpenPosition(m_Symbol)) {
        return false;
    }
    
    // 2. Không vượt quá số lần scaling tối đa
    if (m_ScalingCount >= m_MaxScalingCount) {
        return false;
    }
    
    // 3. Tính toán RR hiện tại (profit/risk ratio)
    double currentRR = GetCurrentRR(m_CurrentPosition.ticket);
    
    // 4. Chỉ xét scaling khi profit >= 0.5R
    if (currentRR < 0.5) {
        return false;
    }
    
    // 5. Kiểm tra các điều kiện thị trường
    bool isLong = m_CurrentPosition.isLong;
    
    // 5.1. Kiểm tra bouncing trên EMA (phù hợp cho scaling)
    bool emaBounceCriteria = CheckEMABounce(isLong);
    
    // 5.2. Không scaling trong thị trường Volatile
    if (profile.isVolatile) {
        return false;
    }
    
    // 5.3. Cải tiến: Không scaling nếu volume đang giảm đột ngột
    if (profile.volumeDeclining) {
        return false;
    }
    
    // 5.4. Cải tiến: Scaling tốt nhất trong thị trường đang trending hoặc trong phase Impulse
    bool trendingCriteria = profile.isTrending || m_CurrentPosition.marketPhase == PHASE_IMPULSE;
    
    // 5.5. Cải tiến: Điều chỉnh theo phiên giao dịch
    bool sessionCriteria = true;
    ENUM_SESSION currentSession = DetermineCurrentSession();
    
    // Không scaling trong phiên Á - thị trường thường sideway và khối lượng thấp
    if (currentSession == SESSION_ASIAN) {
        sessionCriteria = false;
    }
    
    // Phiên overlap Âu-Mỹ thường biến động cao, tốt để scaling nếu đúng xu hướng
    if (currentSession == SESSION_EUROPEAN_AMERICAN && trendingCriteria) {
        sessionCriteria = true;
    }
    
    // 6. Quyết định có nên scaling hay không
    bool shouldScale = emaBounceCriteria && sessionCriteria && (trendingCriteria || profile.isSideway) && currentRR >= 0.5;
    
    if (shouldScale) {
        // Tính toán volume cho lệnh scaling (thường nhỏ hơn lệnh ban đầu)
        double originalVolume = m_CurrentPosition.volume;
        double scalingVolume = originalVolume * 0.5;  // 50% của volume ban đầu
        
        // Kiểm tra với RiskManager xem có thể thêm vị thế không
        if (m_riskManager != NULL && !m_riskManager.CanAddToPosition(scalingVolume)) {
            if (m_logger) {
                m_logger.LogWarning("RiskManager rejected scaling due to risk limits");
            }
            return false;
        }
        
        // Lấy các tham số vào lệnh
        double stopLoss = 0;  // Sẽ được tính tự động
        double takeProfit = 0; // Sẽ được tính tự động
        
        // Thực thi lệnh scaling
        ulong ticket = 0;
        
        if (isLong) {
            ticket = ExecuteBuyOrder(scalingVolume, stopLoss, takeProfit, SCENARIO_SCALING);
        } else {
            ticket = ExecuteSellOrder(scalingVolume, stopLoss, takeProfit, SCENARIO_SCALING);
        }
        
        // Kiểm tra kết quả
        if (ticket > 0) {
            // Scaling thành công
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Scaling executed: #%llu, Volume: %.2f, Current RR: %.2f, Scaling Count: %d, Session: %s",
                    ticket, scalingVolume, currentRR, m_ScalingCount, EnumToString((ENUM_SESSION)currentSession)
                ));
            }
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Quản lý các vị thế đang mở                                       |
//+------------------------------------------------------------------+
void CTradeManager::ManageOpenPositions(MarketProfile& profile)
{
    // Kiểm tra xem có vị thế nào đang mở không
    if (!HasOpenPosition(m_Symbol)) {
        return;
    }
    
    // Cập nhật ATR trung bình nếu cần
    UpdateAverageATR();
    
    // Duyệt qua tất cả các vị thế
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        // Chọn vị thế theo index
        if (!PositionSelectByIndex(i)) continue;
        
        // Kiểm tra Symbol và MagicNumber
        if (PositionGetString(POSITION_SYMBOL) != m_Symbol || 
            PositionGetInteger(POSITION_MAGIC) != m_MagicNumber) {
            continue;
        }
        
        // Lấy thông tin vị thế
        ulong ticket = PositionGetInteger(POSITION_TICKET);
        bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
        double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
        double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        double currentSL = PositionGetDouble(POSITION_SL);
        
        // Luồng xử lý quản lý vị thế
        
        // 1. Kiểm tra Emergency Exit trước tiên
        if (ShouldEmergencyExit(ticket, profile)) {
            // Đã đóng lệnh trong ShouldEmergencyExit
            continue;
        }
        
        // 2. Kiểm tra và quản lý Break-Even
        if (!m_CurrentPosition.breakEvenSet) {
            double currentRR = GetCurrentRR(ticket);
            
            if (currentRR >= m_BreakEven_R) {
                // Điều kiện để đặt break-even (đạt ngưỡng R-multiple)
                double newSL = entryPrice; // Break-even là giá vào lệnh
                
                // Thêm một chút buffer để tránh bị hit quá sớm
                if (isLong) {
                    newSL = entryPrice + (5 * _Point);
                } else {
                    newSL = entryPrice - (5 * _Point);
                }
                
                if (SafeModifyStopLoss(ticket, newSL)) {
                    // Đánh dấu đã set break-even
                    m_CurrentPosition.breakEvenSet = true;
                    
                    if (m_logger) {
                        m_logger.LogInfo(StringFormat(
                            "Break-even set for #%llu at %.5f (RR: %.2f)",
                            ticket, newSL, currentRR
                        ));
                    }
                }
            }
        }
        
        // 3. Quản lý Partial Close
        ManagePartialClose(ticket, CLUSTER_1_TREND_FOLLOWING, GetCurrentRR(ticket));
        
        // 4. Quản lý Trailing Stop
        ENUM_CLUSTER_TYPE clusterType = CLUSTER_1_TREND_FOLLOWING; // Giả định mặc định
        ENUM_MARKET_REGIME regime = REGIME_UNKNOWN;
        
        // Xác định regime từ profile
        if (profile.isTrending) {
            regime = REGIME_TRENDING;
        } else if (profile.isSideway) {
            regime = REGIME_SIDEWAY;
        } else if (profile.isVolatile) {
            regime = REGIME_VOLATILE;
        }
        
        // Áp dụng trailing stop
        ManageTrailingStop(ticket, clusterType, regime);
        
        // 5. Kiểm tra và thực hiện Scaling nếu cần
        // (Thường được gọi từ EA chính, nhưng cũng có thể gọi ở đây)
        //if (CheckAndExecuteScaling(profile)) {
        //    // Đã thực hiện scaling thành công
        //}
    }
}

//+------------------------------------------------------------------+
//| Quản lý Trailing Stop                                            |
//+------------------------------------------------------------------+
void CTradeManager::ManageTrailingStop(ulong ticket, ENUM_CLUSTER_TYPE clusterType, ENUM_MARKET_REGIME regime)
{
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) {
        if (m_logger) m_logger.LogError("Failed to select position: " + IntegerToString(ticket));
        return;
    }
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentSL = PositionGetDouble(POSITION_SL);
    double currentTP = PositionGetDouble(POSITION_TP);
    
    // Kiểm tra nếu vị thế đang lỗ, không áp dụng trailing stop
    if ((isLong && currentPrice < entryPrice) || (!isLong && currentPrice > entryPrice)) {
        return;
    }
    
    // Lấy giá trị ATR
    double atr = GetValidATR();
    if (atr <= 0) return;
    
    // Cải tiến: Xác định phiên giao dịch hiện tại
    ENUM_SESSION currentSession = DetermineCurrentSession();
    
    // Xác định loại trailing stop dựa trên chế độ
    double newSL = 0;
    
    if (m_UseAdaptiveTrailing) {
        // Dựa vào regime để áp dụng chiến lược trailing phù hợp
        switch (regime) {
            case REGIME_TRENDING:
                HandleTrendingTrailing(ticket, isLong, currentPrice, atr);
                break;
                
            case REGIME_SIDEWAY:
                HandleSidewayTrailing(ticket, isLong, currentPrice, atr);
                break;
                
            case REGIME_VOLATILE:
                HandleVolatileTrailing(ticket, isLong, currentPrice, atr);
                break;
                
            default:
                // Sử dụng trailing ATR mặc định nếu không xác định được regime
                newSL = CalculateTrailingStopATR(currentPrice, isLong, atr);
                
                // Điều chỉnh trailing theo phiên giao dịch
                newSL = AdjustTrailingStopBySession(newSL, currentSession, isLong);
                
                if (newSL > 0) {
                    SafeModifyStopLoss(ticket, newSL);
                }
                break;
        }
    } else {
        // Sử dụng chế độ trailing đã chọn
        switch (m_TrailingMode) {
            case TRAILING_MODE_ATR:
                newSL = CalculateTrailingStopATR(currentPrice, isLong, atr);
                break;
                
            case TRAILING_MODE_EMA:
                newSL = CalculateTrailingStopEMA(isLong);
                break;
                
            case TRAILING_MODE_PSAR:
                newSL = CalculateTrailingStopPSAR(isLong);
                break;
                
            case TRAILING_MODE_FIXED:
                // Không trailing, giữ nguyên stop loss
                return;
                
            case TRAILING_MODE_ADAPTIVE:
                // Đã xử lý ở trên, không cần làm gì thêm
                return;
        }
        
        // Điều chỉnh trailing theo phiên giao dịch
        if (newSL > 0) {
            newSL = AdjustTrailingStopBySession(newSL, currentSession, isLong);
        }
        
        // Áp dụng stop loss mới nếu có
        if (newSL > 0) {
            bool shouldModify = false;
            
            // Kiểm tra điều kiện để cập nhật SL
            if (isLong) {
                shouldModify = (newSL > currentSL) && (newSL < currentPrice);
            } else {
                shouldModify = (currentSL == 0 || newSL < currentSL) && (newSL > currentPrice);
            }
            
            if (shouldModify) {
                SafeModifyStopLoss(ticket, newSL);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Xử lý trailing stop trong thị trường trending                    |
//+------------------------------------------------------------------+
void CTradeManager::HandleTrendingTrailing(ulong ticket, bool isLong, double currentPrice, double atr)
{
    // Trong thị trường trending, sử dụng trailing rộng hơn để không bị dừng lỗ sớm
    double trailingMultiplier = m_TrailingATRMultiplier * 1.2; // Tăng 20% để trailing xa hơn
    
    // Tính toán stop loss mới dựa trên ATR
    double newSL = isLong ? 
                  currentPrice - (atr * trailingMultiplier) : 
                  currentPrice + (atr * trailingMultiplier);
    
    // Cải tiến: Điều chỉnh trailing theo phiên giao dịch
    ENUM_SESSION currentSession = DetermineCurrentSession();
    newSL = AdjustTrailingStopBySession(newSL, currentSession, isLong);
    
    // Chuẩn hóa giá trị
    newSL = NormalizeDouble(newSL, m_Digits);
    
    // Lấy stop loss hiện tại
    if (!PositionSelectByTicket(ticket)) return;
    double currentSL = PositionGetDouble(POSITION_SL);
    
    // Kiểm tra xem SL mới có tốt hơn SL hiện tại không
    bool shouldModify = false;
    
    if (isLong) {
        shouldModify = (newSL > currentSL) && (newSL < currentPrice);
    } else {
        shouldModify = (currentSL == 0 || newSL < currentSL) && (newSL > currentPrice);
    }
    
    if (shouldModify) {
        if (SafeModifyStopLoss(ticket, newSL)) {
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Trending market trailing: Updated SL for #%llu to %.5f (ATR: %.5f, Mult: %.2f, Session: %s)",
                    ticket, newSL, atr, trailingMultiplier, EnumToString((ENUM_SESSION)currentSession)
                ));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Xử lý trailing stop trong thị trường sideway                     |
//+------------------------------------------------------------------+
void CTradeManager::HandleSidewayTrailing(ulong ticket, bool isLong, double currentPrice, double atr)
{
    // Trong thị trường sideway, sử dụng trailing chặt hơn để bảo vệ lợi nhuận
    double trailingMultiplier = m_TrailingATRMultiplier * 0.7; // Giảm 30% để trailing chặt hơn
    
    // Tính toán stop loss mới dựa trên ATR
    double newSL = isLong ? 
                  currentPrice - (atr * trailingMultiplier) : 
                  currentPrice + (atr * trailingMultiplier);
    
    // Cải tiến: Điều chỉnh trailing theo phiên giao dịch
    ENUM_SESSION currentSession = DetermineCurrentSession();
    newSL = AdjustTrailingStopBySession(newSL, currentSession, isLong);
    
    // Chuẩn hóa giá trị
    newSL = NormalizeDouble(newSL, m_Digits);
    
    // Lấy stop loss hiện tại
    if (!PositionSelectByTicket(ticket)) return;
    double currentSL = PositionGetDouble(POSITION_SL);
    
    // Kiểm tra xem SL mới có tốt hơn SL hiện tại không
    bool shouldModify = false;
    
    if (isLong) {
        shouldModify = (newSL > currentSL) && (newSL < currentPrice);
    } else {
        shouldModify = (currentSL == 0 || newSL < currentSL) && (newSL > currentPrice);
    }
    
    if (shouldModify) {
        if (SafeModifyStopLoss(ticket, newSL)) {
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Sideway market trailing: Updated SL for #%llu to %.5f (ATR: %.5f, Mult: %.2f, Session: %s)",
                    ticket, newSL, atr, trailingMultiplier, EnumToString((ENUM_SESSION)currentSession)
                ));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Xử lý trailing stop trong thị trường biến động mạnh              |
//+------------------------------------------------------------------+
void CTradeManager::HandleVolatileTrailing(ulong ticket, bool isLong, double currentPrice, double atr)
{
    // Trong thị trường volatile, sử dụng trailing cực kỳ chặt để bảo vệ lợi nhuận
    double trailingMultiplier = m_TrailingATRMultiplier * 0.5; // Giảm 50% để trailing rất chặt
    
    // Tính toán stop loss mới dựa trên ATR
    double newSL = isLong ? 
                  currentPrice - (atr * trailingMultiplier) : 
                  currentPrice + (atr * trailingMultiplier);
    
    // Cải tiến: Điều chỉnh trailing theo phiên giao dịch
    ENUM_SESSION currentSession = DetermineCurrentSession();
    newSL = AdjustTrailingStopBySession(newSL, currentSession, isLong);
    
    // Chuẩn hóa giá trị
    newSL = NormalizeDouble(newSL, m_Digits);
    
    // Lấy stop loss hiện tại
    if (!PositionSelectByTicket(ticket)) return;
    double currentSL = PositionGetDouble(POSITION_SL);
    
    // Kiểm tra xem SL mới có tốt hơn SL hiện tại không
    bool shouldModify = false;
    
    if (isLong) {
        shouldModify = (newSL > currentSL) && (newSL < currentPrice);
    } else {
        shouldModify = (currentSL == 0 || newSL < currentSL) && (newSL > currentPrice);
    }
    
    if (shouldModify) {
        if (SafeModifyStopLoss(ticket, newSL)) {
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Volatile market trailing: Updated SL for #%llu to %.5f (ATR: %.5f, Mult: %.2f, Session: %s)",
                    ticket, newSL, atr, trailingMultiplier, EnumToString((ENUM_SESSION)currentSession)
                ));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Quản lý partial close dựa trên R-multiple đạt được               |
//+------------------------------------------------------------------+
void CTradeManager::ManagePartialClose(ulong ticket, ENUM_CLUSTER_TYPE clusterType, double achievedRR)
{
    // Lượng achieved RR là bội số của rủi ro ban đầu
    
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) return;
    
    // Kiểm tra xem đã partial close lần 1 chưa
    if (!m_CurrentPosition.partialClose1 && achievedRR >= m_PartialCloseR1) {
        // Lấy volume hiện tại
        double currentVolume = PositionGetDouble(POSITION_VOLUME);
        
        // Tính volume cần đóng (phần trăm của volume hiện tại)
        double closeVolume = NormalizeDouble(currentVolume * m_PartialClosePercent1, 2);
        
        // Kiểm tra volume tối thiểu
        double minVolume = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
        
        if (closeVolume >= minVolume && closeVolume < currentVolume) {
            // Thực hiện partial close
            SafeClosePartial(ticket, closeVolume);
            
            // Đánh dấu đã partial close lần 1
            m_CurrentPosition.partialClose1 = true;
            
            // Cập nhật RiskManager
            if (m_riskManager != NULL) {
                m_riskManager.UpdatePositionPartial(ticket, closeVolume);
            }
            
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Partial Close 1: #%llu, Volume: %.2f (%.1f%%), RR: %.2f",
                    ticket, closeVolume, m_PartialClosePercent1 * 100, achievedRR
                ));
            }
        }
    }
    
    // Kiểm tra xem đã partial close lần 2 chưa
    if (m_CurrentPosition.partialClose1 && !m_CurrentPosition.partialClose2 && achievedRR >= m_PartialCloseR2) {
        // Lấy volume hiện tại
        double currentVolume = PositionGetDouble(POSITION_VOLUME);
        
        // Tính volume cần đóng (phần trăm của volume hiện tại)
        double closeVolume = NormalizeDouble(currentVolume * m_PartialClosePercent2, 2);
        
        // Kiểm tra volume tối thiểu
        double minVolume = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
        
        if (closeVolume >= minVolume && closeVolume < currentVolume) {
            // Thực hiện partial close
            SafeClosePartial(ticket, closeVolume);
            
            // Đánh dấu đã partial close lần 2
            m_CurrentPosition.partialClose2 = true;
            
            // Cập nhật RiskManager
            if (m_riskManager != NULL) {
                m_riskManager.UpdatePositionPartial(ticket, closeVolume);
            }
            
            if (m_logger) {
                m_logger.LogInfo(StringFormat(
                    "Partial Close 2: #%llu, Volume: %.2f (%.1f%%), RR: %.2f",
                    ticket, closeVolume, m_PartialClosePercent2 * 100, achievedRR
                ));
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra emergency exit                                          |
//+------------------------------------------------------------------+
bool CTradeManager::ShouldEmergencyExit(ulong ticket, MarketProfile& profile)
{
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) return false;
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    
    // Chỉ áp dụng emergency exit cho các vị thế đang lời
    if ((isLong && currentPrice <= entryPrice) || (!isLong && currentPrice >= entryPrice)) {
        return false;
    }
    
    // Kiểm tra các điều kiện emergency exit
    
    // 1. Kiểm tra Volume Dump (giảm mạnh)
    bool volumeDumpDetected = DetectVolumeDump();
    
    // 2. Kiểm tra EMA Slope Change (thay đổi độ dốc EMA)
    bool emaSlopeChanged = DetectEMASlopeChange(isLong);
    
    // 3. Kiểm tra biến động thị trường đột ngột
    bool suddenVolatility = profile.isVolatile && profile.atrRatio > 2.0;
    
    // 4. Cải tiến: Kiểm tra Market Phase Exhaustion (cạn kiệt)
    bool exhaustionPhase = (DetectMarketPhase() == PHASE_EXHAUSTION);
    
    // Quyết định emergency exit
    bool shouldExit = (volumeDumpDetected || emaSlopeChanged || suddenVolatility || exhaustionPhase);
    
    if (shouldExit) {
        // Đóng vị thế
        if (m_trade.PositionClose(ticket)) {
            if (m_logger) {
                string reason = volumeDumpDetected ? "Volume Dump" : 
                             (emaSlopeChanged ? "EMA Slope Change" : 
                              (exhaustionPhase ? "Exhaustion Phase" : "Sudden Volatility"));
                
                m_logger.LogInfo(StringFormat(
                    "EMERGENCY EXIT for #%llu: %s detected",
                    ticket, reason
                ));
            }
            
            // Thông báo cho RiskManager
            if (m_riskManager != NULL) {
                m_riskManager.ClosePosition(ticket);
            }
            
            // Reset current position info
            ZeroMemory(m_CurrentPosition);
            
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Sửa đổi stop loss an toàn                                        |
//+------------------------------------------------------------------+
bool CTradeManager::SafeModifyStopLoss(ulong ticket, double newSL)
{
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) {
        if (m_logger) m_logger.LogError("Failed to select position for SL modification: " + IntegerToString(ticket));
        return false;
    }
    
    // Kiểm tra SL mới có hợp lệ
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    
    // Kiểm tra SL nằm trong khoảng hợp lệ
    int stopLevel = (int)SymbolInfoInteger(m_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
    double minDistance = stopLevel * _Point;
    
    if (isLong) {
        if (currentPrice - newSL < minDistance) {
            if (m_logger) m_logger.LogWarning(StringFormat(
                "New SL too close to current price: %.5f (min distance: %.5f)",
                newSL, minDistance
            ));
            return false;
        }
    } else {
        if (newSL - currentPrice < minDistance) {
            if (m_logger) m_logger.LogWarning(StringFormat(
                "New SL too close to current price: %.5f (min distance: %.5f)",
                newSL, minDistance
            ));
            return false;
        }
    }
    
    // Lấy thông tin vị thế
    double currentTP = PositionGetDouble(POSITION_TP);
    
    // Sửa đổi stop loss
    if (!m_trade.PositionModify(ticket, newSL, currentTP)) {
        if (m_logger) m_logger.LogError(StringFormat(
            "Failed to modify SL: Error %d (%s)",
            m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
        ));
        return false;
    }
    
    // Cập nhật thông tin vị thế hiện tại
    m_CurrentPosition.stopLoss = newSL;
    
    return true;
}

//+------------------------------------------------------------------+
//| Đóng một phần vị thế an toàn                                     |
//+------------------------------------------------------------------+
void CTradeManager::SafeClosePartial(ulong ticket, double volume)
{
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) {
        if (m_logger) m_logger.LogError("Failed to select position for partial close: " + IntegerToString(ticket));
        return;
    }
    
    // Lấy thông tin vị thế
    double currentVolume = PositionGetDouble(POSITION_VOLUME);
    
    // Kiểm tra volume hợp lệ
    double minVolume = SymbolInfoDouble(m_Symbol, SYMBOL_VOLUME_MIN);
    double maxVolume = currentVolume;
    
    // Đảm bảo volume nằm trong khoảng hợp lệ
    volume = MathMin(maxVolume, MathMax(minVolume, volume));
    
    // Đóng một phần vị thế
    if (!m_trade.PositionClosePartial(ticket, volume)) {
        if (m_logger) m_logger.LogError(StringFormat(
            "Failed to partial close: Error %d (%s)",
            m_trade.ResultRetcode(), m_trade.ResultRetcodeDescription()
        ));
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có vị thế đang mở cho symbol không                  |
//+------------------------------------------------------------------+
bool CTradeManager::HasOpenPosition(string symbol)
{
    for (int i = PositionsTotal() - 1; i >= 0; i--) {
        if (PositionSelectByIndex(i)) {
            if (PositionGetString(POSITION_SYMBOL) == symbol && 
                PositionGetInteger(POSITION_MAGIC) == m_MagicNumber) {
                return true;
            }
        }
    }
    return false;
}

//+------------------------------------------------------------------+
//| Tính toán R-multiple hiện tại                                    |
//+------------------------------------------------------------------+
double CTradeManager::GetCurrentRR(ulong ticket)
{
    // Chọn vị thế theo ticket
    if (!PositionSelectByTicket(ticket)) return 0;
    
    // Lấy thông tin vị thế
    bool isLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
    double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
    double stopLoss = PositionGetDouble(POSITION_SL);
    double currentPrice = isLong ? SymbolInfoDouble(m_Symbol, SYMBOL_BID) : SymbolInfoDouble(m_Symbol, SYMBOL_ASK);
    
    // Tính toán risk ban đầu (đơn vị điểm)
    double initialRisk = isLong ? (entryPrice - stopLoss) : (stopLoss - entryPrice);
    
    // Nếu không có stop loss, sử dụng giá trị mặc định (ATR * 1.5)
    if (initialRisk <= 0) {
        double atr = GetValidATR();
        initialRisk = atr * 1.5;
    }
    
    // Tính toán profit hiện tại (đơn vị điểm)
    double currentProfit = isLong ? (currentPrice - entryPrice) : (entryPrice - currentPrice);
    
    // Tính toán R-multiple (profit/risk)
    double rr = initialRisk > 0 ? (currentProfit / initialRisk) : 0;
    
    return rr;
}

//+------------------------------------------------------------------+
//| Lấy giá trị ATR hợp lệ                                           |
//+------------------------------------------------------------------+
double CTradeManager::GetValidATR()
{
    // Sử dụng handle ATR có sẵn nếu có
    if (m_handleATR != INVALID_HANDLE) {
        double atrBuffer[];
        ArraySetAsSeries(atrBuffer, true);
        
        if (CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) > 0) {
            return atrBuffer[0];
        }
    }
    
    // Nếu không có handle ATR hoặc không đọc được, tự tính
    // (Trong trường hợp thực tế nên tính toán ATR từ price data)
    
    // Trả về giá trị mặc định (điều này cần được cải thiện trong triển khai thực tế)
    double avgPoint = 0.0001; // Giá trị mặc định cho forex 5 digits
    if (m_Digits == 3) avgPoint = 0.001; // Forex 3 digits
    if (m_Digits == 2) avgPoint = 0.01; // CFD, Indices
    if (m_Digits == 0) avgPoint = 1.0; // No digits
    
    return avgPoint * 10; // Ước lượng ATR
}

//+------------------------------------------------------------------+
//| Tính toán trailing stop dựa trên ATR                             |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopATR(double currentPrice, bool isLong, double atr)
{
    if (atr <= 0) return 0;
    
    // Tính toán trailing stop dựa trên ATR và hệ số
    double distance = atr * m_TrailingATRMultiplier;
    
    // Đặt stop loss dựa trên hướng vị thế
    double stopLevel = isLong ? 
                     (currentPrice - distance) : 
                     (currentPrice + distance);
    
    // Chuẩn hóa giá trị
    return NormalizeDouble(stopLevel, m_Digits);
}

//+------------------------------------------------------------------+
//| Tính toán trailing stop dựa trên EMA                             |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopEMA(bool isLong)
{
    // Sử dụng EMA handle nếu có
    if (m_handleEMA != INVALID_HANDLE) {
        double emaBuffer[];
        ArraySetAsSeries(emaBuffer, true);
        
        if (CopyBuffer(m_handleEMA, 0, 0, 1, emaBuffer) > 0) {
            double emaValue = emaBuffer[0];
            
            // Lấy ATR để thêm buffer
            double atr = GetValidATR();
            double buffer = atr * 0.5; // Buffer 50% của ATR
            
            // Đặt stop loss dựa trên EMA và buffer
            double stopLevel = isLong ? 
                             (emaValue - buffer) : 
                             (emaValue + buffer);
            
            // Chuẩn hóa giá trị
            return NormalizeDouble(stopLevel, m_Digits);
        }
    }
    
    return 0; // Không thể tính toán
}

//+------------------------------------------------------------------+
//| Tính toán trailing stop dựa trên Parabolic SAR                   |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTrailingStopPSAR(bool isLong)
{
    // Sử dụng PSAR handle nếu có
    if (m_handlePSAR != INVALID_HANDLE) {
        double psarBuffer[];
        ArraySetAsSeries(psarBuffer, true);
        
        if (CopyBuffer(m_handlePSAR, 0, 0, 1, psarBuffer) > 0) {
            double psarValue = psarBuffer[0];
            
            // Đặt stop loss bằng giá trị PSAR hiện tại
            return NormalizeDouble(psarValue, m_Digits);
        }
    }
    
    return 0; // Không thể tính toán
}

//+------------------------------------------------------------------+
//| Kiểm tra xem giá có bounce trên EMA hay không                    |
//+------------------------------------------------------------------+
bool CTradeManager::CheckEMABounce(bool isLong)
{
    // Lấy handle EMA34 (một indicator phổ biến để check bounce)
    int emaHandle = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    
    if (emaHandle == INVALID_HANDLE) return false;
    
    // Lấy giá và EMA gần đây
    double emaBuffer[], closeBuffer[], lowBuffer[], highBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    ArraySetAsSeries(closeBuffer, true);
    ArraySetAsSeries(lowBuffer, true);
    ArraySetAsSeries(highBuffer, true);
    
    if (CopyBuffer(emaHandle, 0, 0, 5, emaBuffer) <= 0 ||
        CopyClose(m_Symbol, PERIOD_CURRENT, 0, 5, closeBuffer) <= 0 ||
        CopyLow(m_Symbol, PERIOD_CURRENT, 0, 5, lowBuffer) <= 0 ||
        CopyHigh(m_Symbol, PERIOD_CURRENT, 0, 5, highBuffer) <= 0) {
        IndicatorRelease(emaHandle);
        return false;
    }
    
    // Kiểm tra bounce cho vị thế Long
    if (isLong) {
        // Kiểm tra xem có nến nào chạm xuống EMA rồi bật lên không
        for (int i = 1; i < 4; i++) {
            if (lowBuffer[i] <= emaBuffer[i] && closeBuffer[i] > emaBuffer[i]) {
                IndicatorRelease(emaHandle);
                return true;
            }
        }
    } 
    // Kiểm tra bounce cho vị thế Short
    else {
        // Kiểm tra xem có nến nào chạm lên EMA rồi bật xuống không
        for (int i = 1; i < 4; i++) {
            if (highBuffer[i] >= emaBuffer[i] && closeBuffer[i] < emaBuffer[i]) {
                IndicatorRelease(emaHandle);
                return true;
            }
        }
    }
    
    IndicatorRelease(emaHandle);
    return false;
}

//+------------------------------------------------------------------+
//| Phát hiện khi volume giảm mạnh                                   |
//+------------------------------------------------------------------+
bool CTradeManager::DetectVolumeDump()
{
    // Lấy volume gần đây
    long volumeBuffer[];
    ArraySetAsSeries(volumeBuffer, true);
    
    if (CopyTickVolume(m_Symbol, PERIOD_CURRENT, 0, 10, volumeBuffer) <= 0) {
        return false;
    }
    
    // Tính volume trung bình 5 nến
    long avgVolume = 0;
    for (int i = 1; i < 6; i++) {
        avgVolume += volumeBuffer[i];
    }
    avgVolume /= 5;
    
    // Kiểm tra xem volume hiện tại có nhỏ hơn X% so với trung bình không
    // (dấu hiệu volume đang suy yếu)
    if (volumeBuffer[0] < avgVolume * 0.5) {
        return true;
    }
    
    // Hoặc kiểm tra xem volume có giảm liên tục không
    bool decreasingVolume = true;
    for (int i = 0; i < 3; i++) {
        if (volumeBuffer[i] >= volumeBuffer[i+1]) {
            decreasingVolume = false;
            break;
        }
    }
    
    return decreasingVolume;
}

//+------------------------------------------------------------------+
//| Phát hiện thay đổi độ dốc của EMA                                |
//+------------------------------------------------------------------+
bool CTradeManager::DetectEMASlopeChange(bool isLong)
{
    // Lấy EMA gần đây (ví dụ: EMA 34)
    int emaHandle = iMA(m_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    
    if (emaHandle == INVALID_HANDLE) return false;
    
    double emaBuffer[];
    ArraySetAsSeries(emaBuffer, true);
    
    if (CopyBuffer(emaHandle, 0, 0, 20, emaBuffer) <= 0) {
        IndicatorRelease(emaHandle);
        return false;
    }
    
    // Tính toán độ dốc gần đây và trước đó
    double recentSlope = 0;
    double previousSlope = 0;
    
    // Slope gần đây (5 nến)
    recentSlope = (emaBuffer[0] - emaBuffer[5]) / 5;
    
    // Slope trước đó (5 nến trước đó)
    previousSlope = (emaBuffer[5] - emaBuffer[10]) / 5;
    
    // Kiểm tra thay đổi độ dốc
    if (isLong) {
        // Với vị thế Long, cần phát hiện độ dốc đang giảm
        if (recentSlope < 0 && previousSlope > 0) {
            // Đổi từ dốc lên sang dốc xuống
            IndicatorRelease(emaHandle);
            return true;
        }
        
        if (recentSlope > 0 && previousSlope > 0 && recentSlope < previousSlope * 0.5) {
            // Độ dốc dương nhưng giảm đáng kể (giảm 50%)
            IndicatorRelease(emaHandle);
            return true;
        }
    } else {
        // Với vị thế Short, cần phát hiện độ dốc đang tăng
        if (recentSlope > 0 && previousSlope < 0) {
            // Đổi từ dốc xuống sang dốc lên
            IndicatorRelease(emaHandle);
            return true;
        }
        
        if (recentSlope < 0 && previousSlope < 0 && recentSlope > previousSlope * 0.5) {
            // Độ dốc âm nhưng giảm đáng kể (tăng 50%)
            IndicatorRelease(emaHandle);
            return true;
        }
    }
    
    IndicatorRelease(emaHandle);
    return false;
}

//+------------------------------------------------------------------+
//| Đăng ký vị thế mới với metadata                                  |
//+------------------------------------------------------------------+
void CTradeManager::RegisterNewPosition(ulong ticket, ENUM_CLUSTER_TYPE cluster, ENUM_ENTRY_SCENARIO scenario)
{
    // Đặt lại bộ đếm scaling
    if (scenario != SCENARIO_SCALING) {
        m_ScalingCount = 0;
    } else {
        m_ScalingCount++;
    }
    
    // Lưu metadata (trong EA thực, có thể lưu vào global variables hoặc tệp)
    if (m_logger) {
        m_logger.LogInfo(StringFormat(
            "Position registered: #%llu, Cluster: %d, Scenario: %d",
            ticket, (int)cluster, (int)scenario
        ));
    }
}

//+------------------------------------------------------------------+
//| Cập nhật metadata của vị thế                                     |
//+------------------------------------------------------------------+
void CTradeManager::UpdatePositionMetadata(ulong ticket)
{
    // Tính toán và cập nhật R-multiple hiện tại
    double currentRR = GetCurrentRR(ticket);
    m_CurrentPosition.currentRR = currentRR;
    
    // Trong EA thực, có thể lưu thêm thông tin khác
}//+------------------------------------------------------------------+
//| Advanced Trade Entry Buffer - Động theo biến động                 |
//+------------------------------------------------------------------+

//--- Thêm vào TradeManager.mqh

//+------------------------------------------------------------------+
//| Tính toán buffer cho entry lệnh dựa trên biến động               |
//+------------------------------------------------------------------+
double CTradeManager::CalculateDynamicEntryBuffer(bool isLong)
{
   // Lấy ATR hiện tại
   double atr = Market.GetATR();
   if(atr <= 0) {
      // Fallback nếu không lấy được ATR
      return 5 * _Point; // Default 5 pips
   }
   
   // Tính buffer dựa trên ATR và biến động hiện tại
   double dynamicBuffer = atr * 0.5; // Mặc định 50% ATR
   
   // Điều chỉnh dựa trên phiên giao dịch
   ENUM_SESSION currentSession = GetCurrentSession();
   
   switch(currentSession) {
      case SESSION_ASIAN: // Phiên Á biến động thấp, buffer nhỏ hơn
         dynamicBuffer *= 0.7;
         break;
         
      case SESSION_EUROPEAN_AMERICAN: // Phiên overlap biến động cao, buffer lớn hơn
         dynamicBuffer *= 1.3;
         break;
         
      case SESSION_AMERICAN: // Phiên Mỹ biến động cao, buffer lớn hơn
         dynamicBuffer *= 1.2;
         break;
   }
   
   // Kiểm tra spread hiện tại và điều chỉnh nếu cần
   double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;
   
   // Đảm bảo buffer lớn hơn spread ít nhất 50%
   if(dynamicBuffer < currentSpread * 1.5) {
      dynamicBuffer = currentSpread * 1.5;
   }
   
   // ATR ratio - Nếu ATR hiện tại cao hơn nhiều so với trung bình, tăng buffer
   double atrRatio = CalculateATRRatio();
   if(atrRatio > 1.5) {
      dynamicBuffer *= (atrRatio / 1.5);
   }
   
   // Log thông tin về buffer
   if(m_Logger != NULL && EnableDetailedLogs) {
      m_Logger->LogDebug(StringFormat("Dynamic Entry Buffer: %.5f (%.1f pips), ATR Ratio: %.2f, Session: %s", 
                                  dynamicBuffer, dynamicBuffer / _Point, atrRatio, GetSessionName(currentSession)));
   }
   
   return NormalizeDouble(dynamicBuffer, _Digits);
}

//+------------------------------------------------------------------+
//| Đặt lệnh Buy Limit với buffer động                               |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceBuyLimitDynamic(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE)
{
   // Kiểm tra dữ liệu đầu vào
   if(lotSize <= 0) {
      if(m_Logger != NULL) {
         m_Logger->LogError("PlaceBuyLimitDynamic: Invalid lot size");
      }
      return 0;
   }
   
   // Tính buffer động
   double dynamicBuffer = CalculateDynamicEntryBuffer(true);
   
   // Tính giá entry
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entryPrice = NormalizeDouble(currentPrice - dynamicBuffer, _Digits);
   
   // Kiểm tra giá entry
   double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(currentPrice - entryPrice < minDistance) {
      entryPrice = NormalizeDouble(currentPrice - minDistance, _Digits);
   }
   
   // Gọi phương thức thông thường để đặt lệnh
   return PlaceBuyLimit(lotSize, entryPrice, stopLoss, takeProfit, scenario);
}

//+------------------------------------------------------------------+
//| Đặt lệnh Sell Limit với buffer động                              |
//+------------------------------------------------------------------+
ulong CTradeManager::PlaceSellLimitDynamic(double lotSize, double stopLoss, double takeProfit, ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE)
{
   // Kiểm tra dữ liệu đầu vào
   if(lotSize <= 0) {
      if(m_Logger != NULL) {
         m_Logger->LogError("PlaceSellLimitDynamic: Invalid lot size");
      }
      return 0;
   }
   
   // Tính buffer động
   double dynamicBuffer = CalculateDynamicEntryBuffer(false);
   
   // Tính giá entry
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double entryPrice = NormalizeDouble(currentPrice + dynamicBuffer, _Digits);
   
   // Kiểm tra giá entry
   double minDistance = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   if(entryPrice - currentPrice < minDistance) {
      entryPrice = NormalizeDouble(currentPrice + minDistance, _Digits);
   }
   
   // Gọi phương thức thông thường để đặt lệnh
   return PlaceSellLimit(lotSize, entryPrice, stopLoss, takeProfit, scenario);
}

//+------------------------------------------------------------------+
//| Tính tỷ lệ ATR hiện tại so với trung bình 20 ngày               |
//+------------------------------------------------------------------+
double CTradeManager::CalculateATRRatio()
{
   // Lấy ATR hiện tại
   double currentATR = Market.GetATR();
   if(currentATR <= 0) return 1.0;
   
   // Tính ATR trung bình 20 ngày
   int atrHandle = iATR(_Symbol, PERIOD_D1, 20);
   if(atrHandle == INVALID_HANDLE) {
      return 1.0;
   }
   
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);
   
   if(CopyBuffer(atrHandle, 0, 0, 20, atrBuffer) < 20) {
      IndicatorRelease(atrHandle);
      return 1.0;
   }
   
   // Tính ATR trung bình
   double avgATR = 0;
   for(int i = 0; i < 20; i++) {
      avgATR += atrBuffer[i];
   }
   avgATR /= 20;
   
   IndicatorRelease(atrHandle);
   
   // Tránh chia cho 0
   if(avgATR <= 0) return 1.0;
   
   return currentATR / avgATR;
}

//+------------------------------------------------------------------+
//| Xác định phiên giao dịch hiện tại                                |
//+------------------------------------------------------------------+
ENUM_SESSION CTradeManager::GetCurrentSession()
{
   // Lấy giờ GMT
   MqlDateTime dt;
   TimeToStruct(TimeGMT(), dt);
   int hour = dt.hour;
   
   // Phiên Á: 00:00 - 08:00 GMT
   if(hour >= 0 && hour < 8) {
      return SESSION_ASIAN;
   }
   // Phiên Âu: 08:00 - 16:00 GMT
   else if(hour >= 8 && hour < 13) {
      return SESSION_EUROPEAN;
   }
   // Phiên Overlap Âu-Mỹ: 13:00 - 16:00 GMT
   else if(hour >= 13 && hour < 16) {
      return SESSION_EUROPEAN_AMERICAN;
   }
   // Phiên Mỹ: 16:00 - 21:00 GMT
   else if(hour >= 16 && hour < 21) {
      return SESSION_AMERICAN;
   }
   // Phiên đóng cửa
   else {
      return SESSION_CLOSING;
   }
}

//+------------------------------------------------------------------+
//| Trả về tên phiên giao dịch                                       |
//+------------------------------------------------------------------+
string CTradeManager::GetSessionName(ENUM_SESSION session)
{
   switch(session) {
      case SESSION_ASIAN: return "Asian";
      case SESSION_EUROPEAN: return "European";
      case SESSION_AMERICAN: return "American";
      case SESSION_EUROPEAN_AMERICAN: return "EU-US Overlap";
      case SESSION_CLOSING: return "Closing";
      default: return "Unknown";
   }
}

//--- Thêm vào phần xử lý trong CheckNewTradeOpportunities() trong EA chính

// Trong phần thực thi lệnh ở CheckNewTradeOpportunities(), thay phần MODE_LIMIT:
else if (EntryMode == MODE_LIMIT) {
   // Limit order execution with dynamic buffer
   if (signal.isLong) {
      // Buy limit với buffer động thay vì fixed
      ticket = TradeMan.PlaceBuyLimitDynamic(lotSize, signal.stopLoss, signal.takeProfit, signal.scenario);
   } else {
      // Sell limit với buffer động thay vì fixed
      ticket = TradeMan.PlaceSellLimitDynamic(lotSize, signal.stopLoss, signal.takeProfit, signal.scenario);
   }
}