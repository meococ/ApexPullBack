//+------------------------------------------------------------------+
//|                      CommonStructs.mqh - APEX Pullback EA v14.0   |
//|             Author: APEX Forex Team | Date: 2024-05-07           |
//|     Description: Định nghĩa cấu trúc dữ liệu trung tâm cho EA    |
//+------------------------------------------------------------------+

#ifndef _COMMON_STRUCTS_MQH_
#define _COMMON_STRUCTS_MQH_

#include "Constants.mqh" // Ensure MAX_HISTORY_DAYS is defined
#include "Enums.mqh"                   // Định nghĩa enums

namespace ApexPullback {

// Forward declarations for classes used in EAContext
class CLogger;
class CMarketProfile;
class CSwingPointDetector;
class CPositionManager;
class CRiskManager;
class CTradeManager;
class CSessionManager;
class CNewsFilter;
class CDashboard;
class CPatternDetector;
class CPerformanceTracker;
class CIndicatorUtils;
class CPortfolioManager;
class CAssetDNA;

//+------------------------------------------------------------------+
//| Enum for Portfolio Manager Decisions                             |
//+------------------------------------------------------------------+
enum ENUM_PORTFOLIO_DECISION
{
    DECISION_PENDING,  // Proposal is pending review
    DECISION_APPROVED, // Proposal is approved
    DECISION_REJECTED  // Proposal is rejected
};

//+------------------------------------------------------------------+
//| Struct for Trade Proposals                                       |
//+------------------------------------------------------------------+
struct TradeProposal
{
    string            symbol;           // Symbol (e.g., "EURUSD")
    ENUM_ORDER_TYPE   orderType;        // Order type (ORDER_TYPE_BUY or ORDER_TYPE_SELL)
    double            price;            // Proposed entry price
    double            stopLoss;         // Proposed stop loss price
    double            takeProfit;       // Proposed take profit price
    double            riskPercent;      // Proposed risk percentage for this trade
    double            qualityScore;     // Quality score of the trade signal (0.0 - 1.0)
    string            strategyName;     // Name of the strategy generating the proposal
    long              magicNumber;      // Magic number for the EA instance
    datetime          proposalTime;     // Timestamp of when the proposal was generated
    string            gvProposalName;   // Global variable name used for this proposal
    string            gvDecisionName;   // Global variable name for the decision
    ENUM_PORTFOLIO_DECISION decision; // Decision made by the Portfolio Manager

    // Constructor
    TradeProposal() :
        orderType(WRONG_VALUE),
        price(0.0),
        stopLoss(0.0),
        takeProfit(0.0),
        riskPercent(0.0),
        qualityScore(0.0),
        magicNumber(0),
        proposalTime(0),
        decision(DECISION_PENDING) {}

    // Method to format proposal to string for GV
    string ToString() const
    {
        return StringFormat("PROPOSAL;%s;%s;%f;%f;%f;%f;%f;%s;%d;%s;%s",
                            symbol,
                            EnumToString(orderType),
                            price,
                            stopLoss,
                            takeProfit,
                            riskPercent,
                            qualityScore,
                            strategyName,
                            magicNumber,
                            gvProposalName, // Include GV names for easier tracking
                            gvDecisionName);
    }

    // Method to parse proposal from string (from GV)
    // Returns true if parsing is successful, false otherwise
    bool FromString(const string& s)
    {
        string parts[];
        if(StringSplit(s, ';', parts) < 12) // Expecting 12 parts now
            return false;

        if(parts[0] != "PROPOSAL") return false;

        symbol = parts[1];
        if(parts[2] == EnumToString(ORDER_TYPE_BUY)) orderType = ORDER_TYPE_BUY;
        else if(parts[2] == EnumToString(ORDER_TYPE_SELL)) orderType = ORDER_TYPE_SELL;
        else return false; // Invalid order type

        price = StringToDouble(parts[3]);
        stopLoss = StringToDouble(parts[4]);
        takeProfit = StringToDouble(parts[5]);
        riskPercent = StringToDouble(parts[6]);
        qualityScore = StringToDouble(parts[7]);
        strategyName = parts[8];
        magicNumber = StringToInteger(parts[9]);
        gvProposalName = parts[10];
        gvDecisionName = parts[11];
        proposalTime = TimeCurrent(); // Set proposal time to current time when parsing
        decision = DECISION_PENDING; // Default decision
        return true;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Market Profile                       |
//+------------------------------------------------------------------+
struct MarketProfileData {
    // Phương thức copy để thay thế cho operator= mặc định
    void CopyFrom(const MarketProfileData& src) {
        trend = src.trend;
        regime = src.regime;
        currentSession = src.currentSession;
        mtfAlignment = src.mtfAlignment;
        
        isVolatile = src.isVolatile;
        isTrending = src.isTrending;
        isSidewaysOrChoppy = src.isSidewaysOrChoppy;
        isTransitioning = src.isTransitioning;
        isPriceRangebound = src.isPriceRangebound;
        isLowMomentum = src.isLowMomentum;
        
        atrCurrent = src.atrCurrent;
        atrRatio = src.atrRatio;
        atrValue = src.atrValue;
        adxValue = src.adxValue;
        adxSlope = src.adxSlope;
        rsiValue = src.rsiValue;
        rsiSlope = src.rsiSlope;
        macdValue = src.macdValue;
        macdSignal = src.macdSignal;
        macdHistogram = src.macdHistogram;
        macdHistogramSlope = src.macdHistogramSlope;
        bbWidth = src.bbWidth;
        bbWidthRatio = src.bbWidthRatio;
        
        valueAreaHigh = src.valueAreaHigh;
        valueAreaLow = src.valueAreaLow;
        pointOfControl = src.pointOfControl;
        profileHigh = src.profileHigh;
        profileLow = src.profileLow;
        volatilityRatio = src.volatilityRatio;
        
        ema34 = src.ema34;
        ema89 = src.ema89;
        ema200 = src.ema200;
        
        ema34H4 = src.ema34H4;
        ema89H4 = src.ema89H4;
        ema200H4 = src.ema200H4;
        
        recentSwingHigh = src.recentSwingHigh;
        recentSwingLow = src.recentSwingLow;
        recentSwingHighTime = src.recentSwingHighTime;
        recentSwingLowTime = src.recentSwingLowTime;
        
        regimeConfidence = src.regimeConfidence;
        volumeRatio = src.volumeRatio;
        currentSpread = src.currentSpread;
        averageSpread = src.averageSpread;
        heatmapScore = src.heatmapScore;
        trendScore = src.trendScore;
    }
    // Thông tin cơ bản về thị trường
    ENUM_MARKET_TREND trend;            // Xu hướng thị trường hiện tại
    ENUM_MARKET_REGIME regime;          // Chế độ thị trường (Trending, Ranging, Volatile...)
    ENUM_SESSION currentSession; // Phiên giao dịch hiện tại
    ENUM_MTF_ALIGNMENT mtfAlignment;    // Sự đồng thuận giữa các khung thời gian

    // Trạng thái thị trường
    bool isVolatile;                    // Biến động cao hơn bình thường
    bool isTrending;                    // Thị trường có xu hướng rõ rệt
    bool isSidewaysOrChoppy;            // Thị trường sideway/nhiễu
    bool isTransitioning;               // Đang chuyển tiếp giữa các chế độ
    bool isPriceRangebound;             // Giá đang dao động trong biên độ
    bool isLowMomentum;                 // Động lượng thấp? (Thêm từ MarketProfile.mqh)

    // Dữ liệu các chỉ báo
    double atrCurrent;                  // ATR hiện tại
    double atrRatio;                    // Tỷ lệ ATR hiện tại/trung bình
    double atrValue;                    // Giá trị ATR (thêm mới)
    double adxValue;                    // Giá trị ADX
    double adxSlope;                    // Độ dốc của ADX
    double rsiValue;                    // Giá trị RSI
    double rsiSlope;                    // Độ dốc của RSI
    double macdValue;                   // Giá trị MACD (thêm mới)
    double macdSignal;                  // Giá trị MACD Signal (thêm mới)
    double macdHistogram;               // MACD Histogram
    double macdHistogramSlope;          // Độ dốc MACD Histogram
    double bbWidth;                     // Bollinger Bands Width
    double bbWidthRatio;                // Tỷ lệ BB Width hiện tại/trung bình
    
    // Giá trị Market Profile
    double valueAreaHigh;               // Vùng giá trị cao
    double valueAreaLow;                // Vùng giá trị thấp
    double pointOfControl;              // Điểm kiểm soát (POC)
    double profileHigh;                 // Đỉnh profile
    double profileLow;                  // Đáy profile
    double volatilityRatio;             // Tỷ lệ biến động
    
    // Giá trị EMA - Khung thời gian chính
    double ema34;                       // EMA 34 (fast) khung thời gian chính
    double ema89;                       // EMA 89 (medium) khung thời gian chính
    double ema200;                      // EMA 200 (slow) khung thời gian chính
    
    // Giá trị EMA - Khung thời gian cao hơn
    double ema34H4;                     // EMA 34 (fast) khung H4
    double ema89H4;                     // EMA 89 (medium) khung H4
    double ema200H4;                    // EMA 200 (slow) khung H4
    
    // Thông tin Swing Point gần nhất
    double recentSwingHigh;             // Giá trị swing high gần nhất
    double recentSwingLow;              // Giá trị swing low gần nhất
    datetime recentSwingHighTime;       // Thời gian swing high gần nhất
    datetime recentSwingLowTime;        // Thời gian swing low gần nhất
    
    // Thông tin tính toán kỹ thuật
    double regimeConfidence;            // Độ tin cậy của chế độ thị trường (0.0-1.0)
    double volumeRatio;                 // Tỷ lệ volume hiện tại so với trung bình
    double currentSpread;               // Spread hiện tại (points)
    double averageSpread;               // Spread trung bình gần đây
    double heatmapScore;                // Điểm đánh giá tổng thể thị trường (0.0-1.0)
    double trendScore;                  // Điểm mạnh của xu hướng (0.0-1.0) (Thêm từ MarketProfile.mqh)
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        trend = TREND_SIDEWAY;
        regime = REGIME_RANGING_STABLE;
        currentSession = SESSION_UNKNOWN; // Phù hợp với ENUM_SESSION
        mtfAlignment = MTF_ALIGNMENT_NEUTRAL;
        
        isVolatile = false;
        isTrending = false;
        isSidewaysOrChoppy = false;
        isTransitioning = false;
        isPriceRangebound = false;
        isLowMomentum = false;          // Khởi tạo giá trị mặc định
        
        atrCurrent = 0.0;
        atrRatio = 1.0;
        atrValue = 0.0;                 // Khởi tạo
        adxValue = 0.0;
        adxSlope = 0.0;
        rsiValue = 50.0;
        rsiSlope = 0.0;
        macdValue = 0.0;                // Khởi tạo
        macdSignal = 0.0;               // Khởi tạo
        macdHistogram = 0.0;
        macdHistogramSlope = 0.0;
        bbWidth = 0.0;
        bbWidthRatio = 1.0;
        
        // Khởi tạo giá trị Market Profile
        valueAreaHigh = 0.0;
        valueAreaLow = 0.0;
        pointOfControl = 0.0;
        profileHigh = 0.0;
        profileLow = 0.0;
        volatilityRatio = 1.0;
        
        ema34 = 0.0;
        ema89 = 0.0;
        ema200 = 0.0;
        ema34H4 = 0.0;
        ema89H4 = 0.0;
        ema200H4 = 0.0;
        
        recentSwingHigh = 0.0;
        recentSwingLow = 0.0;
        recentSwingHighTime = 0;
        recentSwingLowTime = 0;
        
        regimeConfidence = 0.0;
        volumeRatio = 1.0;
        currentSpread = 0.0;
        averageSpread = 0.0;
        heatmapScore = 0.5;
        trendScore = 0.0;               // Khởi tạo giá trị mặc định
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Swing Point                          |
//+------------------------------------------------------------------+

// Cấu trúc lưu trữ thông tin đỉnh/đáy
struct SwingPoint {
   datetime time;                // Thời gian
   double price;                 // Giá
   ENUM_SWING_POINT_TYPE type;   // Loại (đỉnh/đáy)
   int strength;                 // Độ mạnh (1-10)
   int barIndex;                 // Chỉ số nến
   bool confirmed;               // Đã xác nhận
   ENUM_SWING_IMPORTANCE importance; // Tầm quan trọng
   bool higherTimeframeAlign;    // Khớp với swing trên timeframe cao hơn
   double deviation;             // Độ lệch so với giá trung bình
   bool isValidForTrading;       // Có thể dùng cho giao dịch (mới v14)
   double reliability;           // Độ tin cậy 0.0-1.0 (mới v14)
   bool isStructurallySignificant; // Có ý nghĩa về cấu trúc (mới v14)
   string description;           // Mô tả (mới v14)
   int confirmationBars;         // Đã thêm: Số nến xác nhận
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        time = 0;
        price = 0.0;
        type = SWING_UNKNOWN;
        importance = SWING_MINOR;
        barIndex = -1;
        strength = 0;
        confirmed = false;
        higherTimeframeAlign = false;
        deviation = 0.0;
        isValidForTrading = false;
        reliability = 0.0;
        isStructurallySignificant = false;
        description = "";
        confirmationBars = 0;    // Đã thêm khởi tạo giá trị
    }
};

/// @brief Cấu trúc tổng hợp thông tin các điểm swing
struct SwingPointsData {
    bool hasMajorSwingHigh;             // Có điểm swing high quan trọng gần đây
    bool hasMajorSwingLow;              // Có điểm swing low quan trọng gần đây
    bool hasMinorSwingHigh;             // Có điểm swing high nhỏ gần đây
    bool hasMinorSwingLow;              // Có điểm swing low nhỏ gần đây
    
    SwingPoint nearestMajorSwingHigh;   // Điểm swing high quan trọng gần nhất
    SwingPoint nearestMajorSwingLow;    // Điểm swing low quan trọng gần nhất
    SwingPoint nearestMinorSwingHigh;   // Điểm swing high nhỏ gần nhất
    SwingPoint nearestMinorSwingLow;    // Điểm swing low nhỏ gần nhất
    
    double valueZoneHigh;               // Vùng giá trị cao
    double valueZoneLow;                // Vùng giá trị thấp
    
    int swingHighCount;                 // Số lượng swing high gần đây
    int swingLowCount;                  // Số lượng swing low gần đây
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        hasMajorSwingHigh = false;
        hasMajorSwingLow = false;
        hasMinorSwingHigh = false;
        hasMinorSwingLow = false;
        
        nearestMajorSwingHigh.Clear();
        nearestMajorSwingLow.Clear();
        nearestMinorSwingHigh.Clear();
        nearestMinorSwingLow.Clear();
        
        valueZoneHigh = 0.0;
        valueZoneLow = 0.0;
        
        swingHighCount = 0;
        swingLowCount = 0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Signal                               |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin tín hiệu giao dịch
struct SignalInfo {
    ENUM_SIGNAL_TYPE type;              // Loại tín hiệu (buy/sell)
    double entryPrice;                  // Giá vào lệnh đề xuất
    double quality;                     // Chất lượng tín hiệu (0.0-1.0)
    ENUM_ENTRY_SCENARIO scenario;       // Kịch bản vào lệnh (pullback, breakout, reversal)
    
    bool isValid;                       // Tín hiệu có hợp lệ không
    bool isLong;                        // Tín hiệu mua (true) hay bán (false)
    datetime entryTime;                 // Thời điểm phát sinh tín hiệu
    string description;                 // Mô tả ngắn gọn về tín hiệu
    
    bool momentumConfirmed;             // Xác nhận bởi momentum
    bool volumeConfirmed;               // Xác nhận bởi volume
    bool structureConfirmed;            // Xác nhận bởi cấu trúc giá
    bool patternConfirmed;              // Xác nhận bởi mẫu hình giá
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        type = SIGNAL_NONE;             // Đã thêm SIGNAL_NONE
        entryPrice = 0.0;
        quality = 0.0;
        scenario = SCENARIO_UNKNOWN;    // Đã thêm SCENARIO_UNKNOWN
        
        isValid = false;
        isLong = false;
        entryTime = 0;
        description = "";
        
        momentumConfirmed = false;
        volumeConfirmed = false;
        structureConfirmed = false;
        patternConfirmed = false;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Risk Settings                        |
//+------------------------------------------------------------------+

/// @brief Cấu trúc kết quả tính toán SL/TP
struct SLTPResult {
    double slPrice;                    // Giá Stop Loss
    double tpPrice;                    // Giá Take Profit
    bool isValid;                      // Kết quả hợp lệ
    string calculationMethod;          // Phương pháp tính toán
    double slPips;                     // Khoảng cách SL tính theo pips
    double tpPips;                     // Khoảng cách TP tính theo pips
    double riskRewardRatio;            // Tỷ lệ Risk:Reward
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        slPrice = 0.0;
        tpPrice = 0.0;
        isValid = false;
        calculationMethod = "";
        slPips = 0.0;
        tpPips = 0.0;
        riskRewardRatio = 0.0;
    }
};

/// @brief Cấu trúc thiết lập rủi ro cho lệnh
struct RiskSettings {
    double riskPercent;                // Phần trăm rủi ro
    double lotSize;                    // Kích thước lot
    double stopLoss;                   // Giá Stop Loss
    double takeProfit;                 // Giá Take Profit
    double dollarRisk;                 // Rủi ro tính bằng dollar/base currency
    double minLotAllowed;              // Lot size tối thiểu được phép
    double maxLotAllowed;              // Lot size tối đa được phép
    
    // Cấu hình rủi ro mở rộng
    ENUM_TRAILING_MODE trailingMode;   // Chế độ trailing stop
    double trailingFactor;             // Hệ số điều chỉnh trailing
    bool usePartialClose;              // Sử dụng đóng từng phần
    double partialCloseLevel1;         // Mức đóng một phần lần 1 (R-multiple)
    double partialCloseLevel2;         // Mức đóng một phần lần 2 (R-multiple)
    double partialClosePercent1;       // Phần trăm đóng lần 1
    double partialClosePercent2;       // Phần trăm đóng lần 2
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        riskPercent = 0.0;
        lotSize = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        dollarRisk = 0.0;
        minLotAllowed = 0.0;
        maxLotAllowed = 0.0;
        
        trailingMode = ENUM_TRAILING_MODE::TRAILING_NONE;
        trailingFactor = 0.0;
        usePartialClose = false;
        partialCloseLevel1 = 0.0;
        partialCloseLevel2 = 0.0;
        partialClosePercent1 = 0.0;
        partialClosePercent2 = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Position Info                        |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin vị thế đang mở
struct PositionInfo {
    ulong ticket;                      // Ticket ID của lệnh
    ENUM_POSITION_TYPE type;           // Loại lệnh (buy/sell)
    double volume;                     // Khối lượng lệnh
    double openPrice;                  // Giá mở lệnh
    double currentPrice;               // Giá hiện tại
    double stopLoss;                   // Stop Loss hiện tại
    double takeProfit;                 // Take Profit hiện tại
    double initialStopLoss;            // Stop Loss ban đầu
    double initialVolume;              // Khối lượng ban đầu
    datetime openTime;                 // Thời gian mở lệnh
    double profit;                     // Lợi nhuận hiện tại (tiền)
    double profitPips;                 // Lợi nhuận hiện tại (pips)
    double rMultiple;                  // Lợi nhuận tính theo R-multiple
    ENUM_ENTRY_SCENARIO scenario;      // Kịch bản vào lệnh
    
    // Trạng thái quản lý
    bool isBreakeven;                  // Đã đưa lệnh về breakeven chưa
    bool isPartialClose1;              // Đã đóng một phần lần 1 chưa
    bool isPartialClose2;              // Đã đóng một phần lần 2 chưa
    bool isTrailingActive;             // Trailing stop đã kích hoạt chưa
    int scalingCount;                  // Số lần đã scaling (nhồi lệnh)
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        ticket = 0;
        type = POSITION_TYPE_BUY;
        volume = 0.0;
        openPrice = 0.0;
        currentPrice = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        initialStopLoss = 0.0;
        initialVolume = 0.0;
        openTime = 0;
        profit = 0.0;
        profitPips = 0.0;
        rMultiple = 0.0;
        scenario = SCENARIO_UNKNOWN;   // Đã thêm SCENARIO_UNKNOWN
        
        isBreakeven = false;
        isPartialClose1 = false;
        isPartialClose2 = false;
        isTrailingActive = false;
        scalingCount = 0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Asset Profile                        |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ profile của tài sản giao dịch
/// @brief Cấu trúc đặc tính biến động của tài sản
struct VolatilityCharacteristics {
    double baseVolatility;              // Độ biến động cơ bản
    double volatilityMultiplier;        // Hệ số biến động
    double trendStrengthMultiplier;     // Hệ số mạnh xu hướng
    double rangeMultiplier;             // Hệ số dao động trong biên
    double noiseRatio;                  // Tỷ lệ nhiễu
    
    // Các trường cần cho SwingPointDetector
    double swingDetectionAtrFactor;     // Hệ số ATR cho phát hiện swing point
    double majorSwingMultiplier;        // Hệ số cho swing point quan trọng
    double trailingStopAtrMultiplier;   // Hệ số ATR cho trailing stop
    double volatilityThreshold;         // Ngưỡng biến động để thay đổi chiến lược
    double volumeFactor;                // Hệ số khối lượng điều chỉnh
    
    void Clear() {
        baseVolatility = 1.0;
        volatilityMultiplier = 1.0;
        trendStrengthMultiplier = 1.0;
        rangeMultiplier = 1.0;
        noiseRatio = 0.5;
        
        // Khởi tạo các giá trị mặc định mới
        swingDetectionAtrFactor = 1.0;
        majorSwingMultiplier = 1.5;
        trailingStopAtrMultiplier = 2.0;
        volatilityThreshold = 1.2;
        volumeFactor = 1.0;
    }
};

/// @brief Cấu trúc lưu trữ profile của tài sản giao dịch
struct AssetProfile {
    string symbol;                     // Symbol giao dịch
    string assetType;                  // Loại tài sản (forex, gold, indices, crypto)
    double averageDailyRange;          // Biên độ dao động trung bình ngày (pips)
    double averageATR;                 // ATR trung bình 14 ngày
    VolatilityCharacteristics volatilityCharacteristics; // Đặc tính biến động
    double typicalSpread;              // Spread điển hình cho tài sản
    double spreadThreshold;            // Ngưỡng spread chấp nhận được
    double minStopLevel;               // Khoảng cách SL tối thiểu (broker)
    double atrFactor;                  // Hệ số ATR khuyến nghị cho SL
    double volatilityRank;             // Xếp hạng độ biến động (0.0-1.0)
    double recommendedRiskPercent;     // Risk % khuyến nghị
    double swingPointValidity;         // Độ bền vững của điểm swing (ngày)
    
    // Thông tin session
    bool bestSessionAsian;             // Phù hợp giao dịch phiên Á
    bool bestSessionLondon;            // Phù hợp giao dịch phiên London
    bool bestSessionNewYork;           // Phù hợp giao dịch phiên New York
    
    // Thông tin bổ sung
    double correlationDXY;             // Tương quan với USD Index
    double correlationSPX;             // Tương quan với S&P 500
    double correlationGOLD;            // Tương quan với Gold
    double historyPerformance;         // Hiệu suất trên tài sản này (0.0-1.0)
    
    // Phương thức tính toán SL/TP theo profile tài sản
    double GetOptimalStopLoss(double entryPrice, bool isLong) {
        double slPoints = averageATR * atrFactor;
        return isLong ? entryPrice - slPoints : entryPrice + slPoints;
    }
    
    double GetOptimalTakeProfit(double entryPrice, bool isLong, double rrRatio = 2.0) {
        double slPoints = averageATR * atrFactor;
        double tpPoints = slPoints * rrRatio;
        return isLong ? entryPrice + tpPoints : entryPrice - tpPoints;
    }
    
    // Phương thức đánh giá spread hiện tại
    bool IsSpreadAcceptable(double currentSpread) {
        return currentSpread <= spreadThreshold;
    }
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        symbol = "";
        assetType = "";
        averageDailyRange = 0.0;
        averageATR = 0.0;
        typicalSpread = 0.0;
        spreadThreshold = 0.0;
        minStopLevel = 0.0;
        atrFactor = 0.0;
        volatilityRank = 0.0;
        recommendedRiskPercent = 0.0;
        swingPointValidity = 0.0;
        
        bestSessionAsian = false;
        bestSessionLondon = false;
        bestSessionNewYork = false;
        
        correlationDXY = 0.0;
        correlationSPX = 0.0;
        correlationGOLD = 0.0;
        historyPerformance = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu News Event                           |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin tin tức
struct NewsEvent {
    datetime time;                     // Thời gian tin tức
    string currency;                   // Tiền tệ liên quan
    string name;                       // Tên tin tức
    int impact;                        // Mức độ tác động (1-3)
    bool affecting;                    // Có ảnh hưởng đến cặp hiện tại không
    bool isProcessed;                  // Đã được xử lý chưa
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        time = 0;
        currency = "";
        name = "";
        impact = 0;
        affecting = false;
        isProcessed = false;
    }
};

/// @brief Cấu trúc lưu trữ lịch tin tức
struct NewsCalendar {
    NewsEvent events[100];             // Mảng các sự kiện tin tức
    int count;                         // Số lượng tin tức
    datetime lastUpdate;               // Thời gian cập nhật cuối
    
    // Kiểm tra có tin tức không
    bool HasNewsInTimeRange(datetime fromTime, datetime toTime, int minImpact = 2) {
        for (int i = 0; i < count; i++) {
            if (events[i].impact >= minImpact && 
                events[i].time >= fromTime && 
                events[i].time <= toTime &&
                events[i].affecting) {
                return true;
            }
        }
        return false;
    }
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        for (int i = 0; i < count; i++) {
            events[i].Clear();
        }
        count = 0;
        lastUpdate = 0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Performance Metrics                  |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin hiệu suất
struct PerformanceMetrics {
    // Thống kê tổng quan
    int totalTrades;                   // Tổng số lệnh
    int winningTrades;                 // Số lệnh thắng
    int losingTrades;                  // Số lệnh thua
    double winRate;                    // Tỷ lệ thắng (%)
    double profitFactor;               // Profit Factor
    double expectancy;                 // Kỳ vọng toán học (R)
    double averageWin;                 // Lợi nhuận trung bình mỗi lệnh thắng
    double averageLoss;                // Lỗ trung bình mỗi lệnh thua
    
    // Thông tin Drawdown
    double maxDrawdown;                // Drawdown tối đa
    double currentDrawdown;            // Drawdown hiện tại
    double maxDrawdownDuration;        // Thời gian DD tối đa (giờ)
    double recoveryFactor;             // Hệ số phục hồi
    
    // Phân tích nâng cao
    int consecutiveWins;               // Số lần thắng liên tiếp
    int consecutiveLosses;             // Số lần thua liên tiếp
    int maxConsecutiveWins;            // Số lần thắng liên tiếp tối đa
    int maxConsecutiveLosses;          // Số lần thua liên tiếp tối đa
    double largestWin;                 // Lệnh thắng lớn nhất
    double largestLoss;                // Lệnh thua lớn nhất
    
    // Phân tích theo tiêu chí
    double performanceByScenario[5];   // Hiệu suất theo kịch bản
    double performanceBySession[5];    // Hiệu suất theo phiên
    double performanceByDay[7];        // Hiệu suất theo ngày trong tuần
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        winRate = 0.0;
        profitFactor = 0.0;
        expectancy = 0.0;
        averageWin = 0.0;
        averageLoss = 0.0;
        
        maxDrawdown = 0.0;
        currentDrawdown = 0.0;
        maxDrawdownDuration = 0.0;
        recoveryFactor = 0.0;
        
        consecutiveWins = 0;
        consecutiveLosses = 0;
        maxConsecutiveWins = 0;
        maxConsecutiveLosses = 0;
        largestWin = 0.0;
        largestLoss = 0.0;
        
        ArrayInitialize(performanceByScenario, 0.0);
        ArrayInitialize(performanceBySession, 0.0);
        ArrayInitialize(performanceByDay, 0.0);
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Scenario Stats                       |
//+------------------------------------------------------------------+
/// @brief Cấu trúc lưu trữ thống kê theo kịch bản giao dịch
struct ScenarioStats {
    // Thống kê theo kịch bản
    int totalTradesByScenario[10];      // Tổng số lệnh theo kịch bản
    int winningTradesByScenario[10];    // Số lệnh thắng theo kịch bản
    double profitByScenario[10];        // Lợi nhuận theo kịch bản
    double winRateByScenario[10];       // Tỷ lệ thắng theo kịch bản
    
    // Thống kê theo phiên giao dịch
    int totalTradesBySession[10];       // Tổng số lệnh theo phiên
    int winningTradesBySession[10];     // Số lệnh thắng theo phiên
    double profitBySession[10];         // Lợi nhuận theo phiên
    double winRateBySession[10];        // Tỷ lệ thắng theo phiên
    
    // Thống kê theo điều kiện thị trường
    int totalTradesByRegime[10];        // Tổng số lệnh theo chế độ thị trường
    int winningTradesByRegime[10];      // Số lệnh thắng theo chế độ
    double profitByRegime[10];          // Lợi nhuận theo chế độ
    double winRateByRegime[10];         // Tỷ lệ thắng theo chế độ
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        ArrayInitialize(totalTradesByScenario, 0);
        ArrayInitialize(winningTradesByScenario, 0);
        ArrayInitialize(profitByScenario, 0.0);
        ArrayInitialize(winRateByScenario, 0.0);
        
        ArrayInitialize(totalTradesBySession, 0);
        ArrayInitialize(winningTradesBySession, 0);
        ArrayInitialize(profitBySession, 0.0);
        ArrayInitialize(winRateBySession, 0.0);
        
        ArrayInitialize(totalTradesByRegime, 0);
        ArrayInitialize(winningTradesByRegime, 0);
        ArrayInitialize(profitByRegime, 0.0);
        ArrayInitialize(winRateByRegime, 0.0);
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu EA State                             |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ trạng thái toàn cục của EA
struct EAState {
    ENUM_EA_STATE currentState;        // Trạng thái hiện tại của EA
    datetime lastUpdateTime;           // Thời gian cập nhật cuối
    datetime lastTradeTime;            // Thời gian giao dịch cuối
    datetime pauseEndTime;             // Thời gian kết thúc tạm dừng
    int currentDay;                    // Ngày hiện tại
    int dayTrades;                     // Số lệnh trong ngày
    double dayStartEquity;             // Equity đầu ngày
    double currentRisk;                // Risk % hiện tại
    double averageATR;                 // ATR trung bình
    int consecutiveLosses;             // Số lần thua liên tiếp
    int consecutiveWins;               // Số lần thắng liên tiếp
    bool isBacktestMode;               // Đang chạy backtest?
    
    // Thông tin về thị trường
    double regimeTransitionScore;      // Điểm chuyển tiếp chế độ thị trường
    int regimeConfirmCount;            // Số lần xác nhận chế độ liên tiếp
    double spreadHistory[10];          // Lịch sử spread gần đây
    double volatilityHistory[10];      // Lịch sử volatility gần đây
    
    // Thống kê hàng ngày
    double dailyPnL;                   // Lãi/lỗ trong ngày
    double dailyPnLPercent;            // Lãi/lỗ trong ngày (%)
    double dailyHighEquity;            // Equity cao nhất trong ngày
    double dailyLowEquity;             // Equity thấp nhất trong ngày
    
    // Phương thức làm sạch dữ liệu ngày mới
    void ResetDailyStats() {
        dayTrades = 0;
        dayStartEquity = 0.0;
        dailyPnL = 0.0;
        dailyPnLPercent = 0.0;
        dailyHighEquity = 0.0;
        dailyLowEquity = 0.0;
    }
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        currentState = STATE_INIT;
        lastUpdateTime = 0;
        lastTradeTime = 0;
        pauseEndTime = 0;
        currentDay = 0;
        dayTrades = 0;
        dayStartEquity = 0.0;
        currentRisk = 0.0;
        averageATR = 0.0;
        consecutiveLosses = 0;
        consecutiveWins = 0;
        isBacktestMode = false;
        
        regimeTransitionScore = 0.0;
        regimeConfirmCount = 0;
        ArrayInitialize(spreadHistory, 0.0);
        ArrayInitialize(volatilityHistory, 0.0);
        
        dailyPnL = 0.0;
        dailyPnLPercent = 0.0;
        dailyHighEquity = 0.0;
        dailyLowEquity = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Dashboard Panel                      |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin hiển thị dashboard
struct DashboardPanel {
    int x;                             // Tọa độ X
    int y;                             // Tọa độ Y
    int width;                         // Chiều rộng
    int height;                        // Chiều cao
    string title;                      // Tiêu đề panel
    color backgroundColor;             // Màu nền
    color textColor;                   // Màu chữ
    color borderColor;                 // Màu viền
    bool visible;                      // Hiển thị hay không
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        x = 0;
        y = 0;
        width = 0;
        height = 0;
        title = "";
        backgroundColor = clrWhite;
        textColor = clrBlack;
        borderColor = clrGray;
        visible = true;
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Asset Profile Data                     |
//+------------------------------------------------------------------+

struct AssetProfileDataStruct { // Đổi tên để tránh trùng lặp với struct MarketProfileData
    string symbol;                 // Biểu tượng tài sản
    ENUM_ASSET_CLASS assetClass;   // Phân loại tài sản (Forex, Gold, Indices, ...)
    ENUM_SYMBOL_GROUP symbolGroup; // Nhóm cặp tiền (Major, Minor, Exotic, ...)

    // --- Trường DNA Chiến lược (Mới) ---
    ENUM_TRADING_STRATEGY preferredStrategy; // Kịch bản giao dịch ưa thích
    double optimalSlAtrMultiplier;           // Hệ số SL ATR tối ưu
    double optimalTpRrRatio;                 // Tỷ lệ R:R tối ưu
    bool   isMeanReverting;                  // Có thiên hướng hồi quy trung bình?
    bool   isStrongTrending;                 // Có thiên hướng xu hướng mạnh?
    int    activeTradingStartHour;           // Giờ bắt đầu phiên giao dịch sôi động (GMT)
    int    activeTradingEndHour;             // Giờ kết thúc phiên giao dịch sôi động (GMT)
    ENUM_ASSET_VOLATILITY volatilityLevel; // Mức độ biến động (Low, Medium, High, ...)
    
    // Các thông số thống kê
    double averageATR;            // ATR trung bình 14 ngày
    double averageATRPoints;      // ATR trung bình tính theo điểm
    double yearlyVolatility;      // Biến động hàng năm (%)
    double minSpread;             // Spread tối thiểu
    double maxSpread;             // Spread tối đa
    double averageSpread;         // Spread trung bình
    double acceptableSpread;      // Ngưỡng spread chấp nhận được
    double swingMagnitude;        // Biên độ swing trung bình
    double dailyRange;            // Phạm vi giá trung bình hàng ngày
    
    // Thông số tối ưu cho giao dịch
    double optimalSLATRMulti;     // Hệ số ATR tối ưu cho SL
    double optimalTRAtrMulti;     // Hệ số ATR tối ưu cho Trailing
    double optimalRRRatio;        // Tỷ lệ R:R tối ưu
    double recommendedRiskPercent; // % Risk khuyến nghị
    
    // Thông tin sessison
    int bestTradingSession;       // Phiên giao dịch tốt nhất (mask: 1=Asian, 2=London, 4=NewYork)
    int worstTradingSession;      // Phiên giao dịch kém nhất (mask: 1=Asian, 2=London, 4=NewYork)
    
    // Thông tin hiệu suất giao dịch
    int totalTrades;              // Tổng số giao dịch
    double winRate;               // Tỷ lệ thắng (%)
    double profitFactor;          // Profit factor
    double expectancy;            // Kỳ vọng (R)
    
    // Lịch sử dữ liệu gần đây
    double atrHistory[MAX_HISTORY_DAYS];  // Lịch sử ATR
    double spreadHistory[MAX_HISTORY_DAYS]; // Lịch sử spread
    datetime historyDates[MAX_HISTORY_DAYS]; // Ngày tương ứng
    int historyCount;             // Số lượng mẫu lịch sử
    datetime lastUpdated;         // Thời gian cập nhật cuối
    
    // Phương thức khởi tạo giá trị mặc định
    void Initialize() {
        symbol = "";
        assetClass = ASSET_CLASS_FOREX;
        symbolGroup = GROUP_UNDEFINED;

        // Khởi tạo các trường DNA Chiến lược
        preferredStrategy = STRATEGY_UNDEFINED; // Hoặc một giá trị mặc định khác
        optimalSlAtrMultiplier = 1.5; // Giá trị mặc định ví dụ
        optimalTpRrRatio = 2.0;       // Giá trị mặc định ví dụ
        isMeanReverting = false;
        isStrongTrending = false;
        activeTradingStartHour = 7;   // GMT, ví dụ: London open
        activeTradingEndHour = 16;    // GMT, ví dụ: NY close
        volatilityLevel = VOLATILITY_MEDIUM;
        
        // Khởi tạo các giá trị khác về 0
        averageATR = 0;
        averageATRPoints = 0;
        yearlyVolatility = 0;
        minSpread = 0;
        maxSpread = 0;
        averageSpread = 0;
        acceptableSpread = 0;
        swingMagnitude = 0;
        dailyRange = 0;
        
        optimalSLATRMulti = 1.5;
        optimalTRAtrMulti = 2.0;
        optimalRRRatio = 2.0;
        recommendedRiskPercent = 1.0;
        
        bestTradingSession = 6;  // Mặc định London+NY (2+4)
        worstTradingSession = 1;  // Mặc định Asian (1)
        
        totalTrades = 0;
        winRate = 0;
        profitFactor = 0;
        expectancy = 0;
        
        historyCount = 0;
        lastUpdated = 0;
        
        // Khởi tạo mảng lịch sử
        ArrayInitialize(atrHistory, 0);
        ArrayInitialize(spreadHistory, 0);
        ArrayInitialize(historyDates, 0);
    }
};

//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Indicator Handles                       |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ các indicator handle sử dụng trong EA
struct IndicatorHandles {
    // Các handle cơ bản
    int atrHandle;                     // ATR indicator
    int maHandle;                      // Moving Average
    int rsiHandle;                     // RSI
    int stochHandle;                   // Stochastic
    int bollingerHandle;               // Bollinger Bands
    int zigzagHandle;                  // ZigZag
    int fractalsHandle;                // Fractals
    int volumeHandle;                  // Volume
    int adxHandle;                     // ADX
    int ichimokuHandle;                // Ichimoku
    int macdHandle;                    // MACD
    
    // Khởi tạo tất cả handle với giá trị mặc định là INVALID_HANDLE
    IndicatorHandles() {
        atrHandle = INVALID_HANDLE;
        maHandle = INVALID_HANDLE;
        rsiHandle = INVALID_HANDLE;
        stochHandle = INVALID_HANDLE;
        bollingerHandle = INVALID_HANDLE;
        zigzagHandle = INVALID_HANDLE;
        fractalsHandle = INVALID_HANDLE;
        volumeHandle = INVALID_HANDLE;
        adxHandle = INVALID_HANDLE;
        ichimokuHandle = INVALID_HANDLE;
        macdHandle = INVALID_HANDLE;
    }
    
    // Giải phóng bộ nhớ tất cả các handle
    void ReleaseAll() {
        if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
        if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
        if(rsiHandle != INVALID_HANDLE) IndicatorRelease(rsiHandle);
        if(stochHandle != INVALID_HANDLE) IndicatorRelease(stochHandle);
        if(bollingerHandle != INVALID_HANDLE) IndicatorRelease(bollingerHandle);
        if(zigzagHandle != INVALID_HANDLE) IndicatorRelease(zigzagHandle);
        if(fractalsHandle != INVALID_HANDLE) IndicatorRelease(fractalsHandle);
        if(volumeHandle != INVALID_HANDLE) IndicatorRelease(volumeHandle);
        if(adxHandle != INVALID_HANDLE) IndicatorRelease(adxHandle);
        if(ichimokuHandle != INVALID_HANDLE) IndicatorRelease(ichimokuHandle);
        if(macdHandle != INVALID_HANDLE) IndicatorRelease(macdHandle);
    }
};



//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu EA Context                           |
//+------------------------------------------------------------------+
struct EAContext {
    // === Các con trỏ đến các module chính ===
    CLogger*            Logger;              // Module ghi log
    CMarketProfile*     MarketProfile;       // Module phân tích thị trường
    CSwingPointDetector* SwingDetector;      // Module phát hiện swing
    CPositionManager*   PositionManager;     // Module quản lý vị thế
    CRiskManager*       RiskManager;         // Module quản lý rủi ro
    CTradeManager*      TradeManager;        // Module quản lý giao dịch
    CSessionManager*    SessionManager;      // Module quản lý phiên
    CNewsFilter*        NewsFilter;          // Module lọc tin tức
    CDashboard*         Dashboard;           // Module hiển thị
    CPatternDetector*   PatternDetector;     // Module phát hiện mẫu hình
    CPerformanceTracker* PerformanceTracker; // Module theo dõi hiệu suất
    CIndicatorUtils*    IndicatorUtils;      // Module tiện ích indicator
    CPortfolioManager*  PortfolioManager;    // Module quản lý danh mục
    CAssetDNA*          AssetDNA;            // Module Phân tích DNA Tài sản (MỚI)

    // === Các tham số từ Inputs.mqh ===
    // Thông tin chung
    bool    AllowNewTrades;         // Cho phép vào lệnh mới
    bool    EnableDetailedLogs;      // Bật log chi tiết
    bool    AlertsEnabled;           // Bật cảnh báo
    bool    SendNotifications;       // Gửi thông báo đẩy
    bool    SendEmailAlerts;         // Gửi email
    bool    EnableTelegramNotify;    // Bật thông báo Telegram
    bool    TelegramImportantOnly;   // Chỉ gửi thông báo quan trọng
    bool    DisableDashboardInBacktest; // Tắt dashboard trong backtest

    // Cài đặt chiến lược
    double  MinPullbackPct;         // % Pullback tối thiểu
    double  MaxPullbackPct;         // % Pullback tối đa
    bool    RequirePriceAction;      // Yêu cầu xác nhận Price Action
    bool    RequireMomentum;         // Yêu cầu xác nhận Momentum
    bool    RequireVolume;           // Yêu cầu xác nhận Volume
    bool    EnableMarketRegime;      // Bật lọc Market Regime
    bool    EnableVolatility;        // Lọc biến động bất thường
    bool    EnableAdx;               // Lọc ADX
    double  MinAdxValue;             // Giá trị ADX tối thiểu
    double  MaxAdxValue;             // Giá trị ADX tối đa
    double  VolatilityThreshold;     // Ngưỡng biến động (xATR)
    double  MaxSpreadPoints;         // Spread tối đa (points)

    // Quản lý rủi ro
    double  RiskPercent;             // Risk % mỗi lệnh
    double  StopLoss_ATR;            // Hệ số ATR cho Stop Loss
    double  TakeProfit_RR;           // Tỷ lệ R:R cho Take Profit
    bool    PropFirmMode;            // Chế độ Prop Firm
    double  DailyLossLimit;          // Giới hạn lỗ ngày (%)
    double  MaxDrawdown;             // Drawdown tối đa (%)
    int     MaxTradesPerDay;         // Số lệnh tối đa/ngày
    int     MaxConsecutiveLosses;    // Số lần thua liên tiếp tối đa
    int     MaxPositions;            // Số vị thế tối đa

    // Điều chỉnh risk theo drawdown
    double  DrawdownReduceThreshold; // Ngưỡng DD để giảm risk (%)
    bool    EnableTaperedRisk;       // Giảm risk từ từ
    double  MinRiskMultiplier;       // Hệ số risk tối thiểu khi DD cao

    // Quản lý vị thế
    int     EntryMode;               // Chế độ vào lệnh
    bool    UsePartialClose;         // Sử dụng đóng từng phần
    double  PartialCloseR1;          // R-multiple cho đóng phần 1
    double  PartialCloseR2;          // R-multiple cho đóng phần 2
    double  PartialClosePercent1;    // % đóng ở mức R1
    double  PartialClosePercent2;    // % đóng ở mức R2

    // Trailing stop
    bool    UseAdaptiveTrailing;     // Trailing thích ứng theo regime
    int     TrailingMode;            // Chế độ trailing mặc định
    double  TrailingAtrMultiplier;   // Hệ số ATR cho trailing
    double  BreakEvenAfterR;         // Chuyển BE sau (R-multiple)
    double  BreakEvenBuffer;         // Buffer cho breakeven (points)

    // THÔNG TIN CHUNG (tiếp theo)
    string  EAName;
    string  EAVersion;
    int     MagicNumber;
    string  OrderComment;

    // HIỂN THỊ & THÔNG BÁO (tiếp theo)
    bool    EnableCsvLog;
    string  CsvLogFilename;
    bool    DisplayDashboard;
    ENUM_DASHBOARD_THEME DashboardTheme;
    string  TelegramBotToken;
    string  TelegramChatID;

    // CHIẾN LƯỢC CỐT LÕI (tiếp theo)
    ENUM_TIMEFRAMES MainTimeframe;
    int     EMA_Fast;
    int     EMA_Medium;
    int     EMA_Slow;
    bool    UseMultiTimeframe;
    ENUM_TIMEFRAMES HigherTimeframe;
    int     TrendDirection;

    // ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO (tiếp theo)
    bool    EnablePriceActionInput; // Renamed from EnablePriceAction
    bool    EnableSwingLevels;

    // BỘ LỌC THỊ TRƯỜNG (tiếp theo)
    int     MarketPreset;

    // CHANDELIER EXIT
    bool    UseChandelierExit;
    int     ChandelierPeriod;
    double  ChandelierMultiplier;

    // LỌC PHIÊN
    bool    FilterBySession;
    int     SessionFilterMode; // Renamed from SessionFilter
    bool    UseGmtOffset;
    int     GmtOffset;
    bool    TradeLondonOpen;
    bool    TradeNewYorkOpen;

    // LỌC TIN TỨC
    int     NewsFilterLevelInput; // Renamed from NewsFilter
    string  NewsDataFile;
    int     NewsImportanceInput; // Renamed
    int     MinutesBeforeNews;
    int     MinutesAfterNews;

    // TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC
    bool    EnableAutoPause;
    double  VolatilityPauseThresholdInput; // Renamed
    double  DrawdownPauseThresholdInput; // Renamed
    bool    EnableAutoResume;
    int     PauseDurationMinutes;
    bool    ResumeOnLondonOpen;

    // ASSETPROFILER - MODULE MỚI
    bool    UseAssetProfiler;
    int     AssetProfileDays;
    bool    AdaptRiskByAsset;
    bool    AdaptSLByAsset;
    bool    AdaptSpreadFilterByAsset;
    ENUM_ADAPTIVE_MODE AdaptiveModeInput; // Renamed

    // CHẾ ĐỘ TAKE PROFIT
    ENUM_TP_MODE TakeProfitModeInput; // Renamed
    double  StopLossBufferATR_Ratio;
    double  StopLossATR_Multiplier_TP; // Renamed
    double  TakeProfitStructureBufferATR_Ratio;
    double  ADXThresholdForVolatilityTP;
    double  VolatilityTP_ATR_Multiplier_High;
    double  VolatilityTP_ATR_Multiplier_Low;

    // QUẢN LÝ DANH MỤC
    bool    IsMasterPortfolioManager;

    // Trạng thái EA
    ENUM_EA_STATE EAState;           // Trạng thái hiện tại của EA
    bool    EmergencyMode;           // Chế độ khẩn cấp
    MarketProfileData CurrentProfileData; // Dữ liệu Market Profile hiện tại

    // Constructor
    EAContext() {
        // Khởi tạo các con trỏ là NULL
        Logger = NULL;
        MarketProfile = NULL;
        SwingDetector = NULL;
        PositionManager = NULL;
        RiskManager = NULL;
        TradeManager = NULL;
        SessionManager = NULL;
        NewsFilter = NULL;
        Dashboard = NULL;
        PatternDetector = NULL;
        PerformanceTracker = NULL;
        IndicatorUtils = NULL;
        PortfolioManager = NULL;
        AssetDNA = NULL;

        // Khởi tạo các biến thành viên với giá trị mặc định
        AllowNewTrades = true;
        EnableDetailedLogs = false;
        AlertsEnabled = true;
        SendNotifications = false;
        SendEmailAlerts = false;
        EnableTelegramNotify = false;
        TelegramImportantOnly = true;
        DisableDashboardInBacktest = false;

        MinPullbackPct = 30.0;
        MaxPullbackPct = 70.0;
        RequirePriceAction = true;
        RequireMomentum = true;
        RequireVolume = false;
        EnableMarketRegime = true;
        EnableVolatility = true;
        EnableAdx = false;
        MinAdxValue = 20.0;
        MaxAdxValue = 50.0;
        VolatilityThreshold = 2.0;
        MaxSpreadPoints = 50.0;

        RiskPercent = 1.0;
        StopLoss_ATR = 1.5;
        TakeProfit_RR = 2.0;
        PropFirmMode = false;
        DailyLossLimit = 5.0;
        MaxDrawdown = 10.0;
        MaxTradesPerDay = 5;
        MaxConsecutiveLosses = 3;
        MaxPositions = 1;

        DrawdownReduceThreshold = 5.0;
        EnableTaperedRisk = true;
        MinRiskMultiplier = 0.3;

        EntryMode = 0;
        UsePartialClose = false;
        PartialCloseR1 = 1.0;
        PartialCloseR2 = 2.0;
        PartialClosePercent1 = 50.0;
        PartialClosePercent2 = 50.0;

        UseAdaptiveTrailing = true;
        TrailingMode = 0;
        TrailingAtrMultiplier = 2.0;
        BreakEvenAfterR = 0.5;
        BreakEvenBuffer = 5.0;

        // THÔNG TIN CHUNG (tiếp theo)
        EAName = "APEX Pullback EA v14.0";
        EAVersion = "14.0";
        MagicNumber = 14000;
        OrderComment = "ApexPullback v14";

        // HIỂN THỊ & THÔNG BÁO (tiếp theo)
        EnableCsvLog = false;
        CsvLogFilename = "ApexPullback_Log.csv";
        DisplayDashboard = true;
        DashboardTheme = DASHBOARD_DARK;
        TelegramBotToken = "";
        TelegramChatID = "";

        // CHIẾN LƯỢC CỐT LÕI (tiếp theo)
        MainTimeframe = PERIOD_H1;
        EMA_Fast = 34;
        EMA_Medium = 89;
        EMA_Slow = 200;
        UseMultiTimeframe = true;
        HigherTimeframe = PERIOD_H4;
        TrendDirection = 0; // 0-Cả hai

        // ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO (tiếp theo)
        EnablePriceActionInput = true;
        EnableSwingLevels = true;

        // BỘ LỌC THỊ TRƯỜNG (tiếp theo)
        MarketPreset = PRESET_AUTO; // Assuming PRESET_AUTO is defined in Enums.mqh

        // CHANDELIER EXIT
        UseChandelierExit = true;
        ChandelierPeriod = 20;
        ChandelierMultiplier = 3.0;

        // LỌC PHIÊN
        FilterBySession = false;
        SessionFilterMode = FILTER_ALL_SESSIONS; // Assuming FILTER_ALL_SESSIONS is defined
        UseGmtOffset = true;
        GmtOffset = 0;
        TradeLondonOpen = true;
        TradeNewYorkOpen = true;

        // LỌC TIN TỨC
        NewsFilterLevelInput = 2;
        NewsDataFile = "news_calendar.csv";
        NewsImportanceInput = 2;
        MinutesBeforeNews = 30;
        MinutesAfterNews = 15;

        // TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC
        EnableAutoPause = true;
        VolatilityPauseThresholdInput = 2.5;
        DrawdownPauseThresholdInput = 7.0;
        EnableAutoResume = true;
        PauseDurationMinutes = 120;
        ResumeOnLondonOpen = true;

        // ASSETPROFILER - MODULE MỚI
        UseAssetProfiler = true;
        AssetProfileDays = 30;
        AdaptRiskByAsset = true;
        AdaptSLByAsset = true;
        AdaptSpreadFilterByAsset = true;
        AdaptiveModeInput = MODE_MANUAL; // Assuming MODE_MANUAL is defined

        // CHẾ ĐỘ TAKE PROFIT
        TakeProfitModeInput = TP_MODE_STRUCTURE; // Assuming TP_MODE_STRUCTURE is defined
        StopLossBufferATR_Ratio = 0.2;
        StopLossATR_Multiplier_TP = 2.0;
        TakeProfitStructureBufferATR_Ratio = 0.1;
        ADXThresholdForVolatilityTP = 25.0;
        VolatilityTP_ATR_Multiplier_High = 2.5;
        VolatilityTP_ATR_Multiplier_Low = 1.8;

        // QUẢN LÝ DANH MỤC
        IsMasterPortfolioManager = false;

        EAState = STATE_INIT;
        EmergencyMode = false;
    }

    // Copy Assignment Operator
    EAContext& operator=(const EAContext& other)
    {
        if (this == &other) // Self-assignment check
            return *this;

        // Perform member-wise copy for all members
        this->Logger = other.Logger;
        this->MarketProfile = other.MarketProfile;
        this->SwingDetector = other.SwingDetector;
        this->PositionManager = other.PositionManager;
        this->RiskManager = other.RiskManager;
        this->TradeManager = other.TradeManager;
        this->SessionManager = other.SessionManager;
        this->NewsFilter = other.NewsFilter;
        this->Dashboard = other.Dashboard;
        this->PatternDetector = other.PatternDetector;
        this->PerformanceTracker = other.PerformanceTracker;
        this->IndicatorUtils = other.IndicatorUtils;
        this->PortfolioManager = other.PortfolioManager;
        this->AssetDNA = other.AssetDNA;

        this->Symbol = other.Symbol;
        this->Timeframe = other.Timeframe;
        this->AccountLeverage = other.AccountLeverage;
        this->IsHedgingAccount = other.IsHedgingAccount;
        this->IsStrategyTester = other.IsStrategyTester;
        this->IsOptimization = other.IsOptimization;
        this->IsVisualMode = other.IsVisualMode;
        this->MaxLot = other.MaxLot;
        this->MinLot = other.MinLot;
        this->LotStep = other.LotStep;
        this->TickValue = other.TickValue;
        this->PointSize = other.PointSize;
        this->DigitsValue = other.DigitsValue;
        this->StopLevel = other.StopLevel;
        this->FreezeLevel = other.FreezeLevel;

        this->AllowNewTrades = other.AllowNewTrades;
        this->EnableDetailedLogs = other.EnableDetailedLogs;
        this->AlertsEnabled = other.AlertsEnabled;
        this->SendNotifications = other.SendNotifications;
        this->SendEmailAlerts = other.SendEmailAlerts;
        this->EnableTelegramNotify = other.EnableTelegramNotify;
        this->TelegramImportantOnly = other.TelegramImportantOnly;
        this->DisableDashboardInBacktest = other.DisableDashboardInBacktest;

        this->MinPullbackPct = other.MinPullbackPct;
        this->MaxPullbackPct = other.MaxPullbackPct;
        this->RequirePriceAction = other.RequirePriceAction;
        this->RequireMomentum = other.RequireMomentum;
        this->RequireVolume = other.RequireVolume;
        this->EnableMarketRegime = other.EnableMarketRegime;
        this->EnableVolatility = other.EnableVolatility;
        this->EnableAdx = other.EnableAdx;
        this->MinAdxValue = other.MinAdxValue;
        this->MaxAdxValue = other.MaxAdxValue;
        this->VolatilityThreshold = other.VolatilityThreshold;
        this->MaxSpreadPoints = other.MaxSpreadPoints;

        this->RiskPercent = other.RiskPercent;
        this->StopLoss_ATR = other.StopLoss_ATR;
        this->TakeProfit_RR = other.TakeProfit_RR;
        this->PropFirmMode = other.PropFirmMode;
        this->DailyLossLimit = other.DailyLossLimit;
        this->MaxDrawdown = other.MaxDrawdown;
        this->MaxTradesPerDay = other.MaxTradesPerDay;
        this->MaxConsecutiveLosses = other.MaxConsecutiveLosses;
        this->MaxPositions = other.MaxPositions;

        this->DrawdownReduceThreshold = other.DrawdownReduceThreshold;
        this->EnableTaperedRisk = other.EnableTaperedRisk;
        this->MinRiskMultiplier = other.MinRiskMultiplier;

        this->EntryMode = other.EntryMode;
        this->UsePartialClose = other.UsePartialClose;
        this->PartialCloseR1 = other.PartialCloseR1;
        this->PartialCloseR2 = other.PartialCloseR2;
        this->PartialClosePercent1 = other.PartialClosePercent1;
        this->PartialClosePercent2 = other.PartialClosePercent2;

        this->UseAdaptiveTrailing = other.UseAdaptiveTrailing;
        this->TrailingMode = other.TrailingMode;
        this->TrailingAtrMultiplier = other.TrailingAtrMultiplier;
        this->BreakEvenAfterR = other.BreakEvenAfterR;
        this->BreakEvenBuffer = other.BreakEvenBuffer;

        this->EAName = other.EAName;
        this->EAVersion = other.EAVersion;
        this->MagicNumber = other.MagicNumber;
        this->OrderComment = other.OrderComment;

        this->EnableCsvLog = other.EnableCsvLog;
        this->CsvLogFilename = other.CsvLogFilename;
        this->DisplayDashboard = other.DisplayDashboard;
        this->DashboardTheme = other.DashboardTheme;
        this->TelegramBotToken = other.TelegramBotToken;
        this->TelegramChatID = other.TelegramChatID;

        this->MainTimeframe = other.MainTimeframe;
        this->EMA_Fast = other.EMA_Fast;
        this->EMA_Medium = other.EMA_Medium;
        this->EMA_Slow = other.EMA_Slow;
        this->UseMultiTimeframe = other.UseMultiTimeframe;
        this->HigherTimeframe = other.HigherTimeframe;
        this->TrendDirection = other.TrendDirection;

        this->EnablePriceActionInput = other.EnablePriceActionInput;
        this->EnableSwingLevels = other.EnableSwingLevels;

        this->MarketPreset = other.MarketPreset;

        this->UseChandelierExit = other.UseChandelierExit;
        this->ChandelierPeriod = other.ChandelierPeriod;
        this->ChandelierMultiplier = other.ChandelierMultiplier;

        this->FilterBySession = other.FilterBySession;
        this->SessionFilterMode = other.SessionFilterMode;
        this->UseGmtOffset = other.UseGmtOffset;
        this->GmtOffset = other.GmtOffset;
        this->TradeLondonOpen = other.TradeLondonOpen;
        this->TradeNewYorkOpen = other.TradeNewYorkOpen;

        this->NewsFilterLevelInput = other.NewsFilterLevelInput;
        this->NewsDataFile = other.NewsDataFile;
        this->NewsImportanceInput = other.NewsImportanceInput;
        this->MinutesBeforeNews = other.MinutesBeforeNews;
        this->MinutesAfterNews = other.MinutesAfterNews;

        this->EnableAutoPause = other.EnableAutoPause;
        this->VolatilityPauseThresholdInput = other.VolatilityPauseThresholdInput;
        this->DrawdownPauseThresholdInput = other.DrawdownPauseThresholdInput;
        this->EnableAutoResume = other.EnableAutoResume;
        this->PauseDurationMinutes = other.PauseDurationMinutes;
        this->ResumeOnLondonOpen = other.ResumeOnLondonOpen;

        this->UseAssetProfiler = other.UseAssetProfiler;
        this->AssetProfileDays = other.AssetProfileDays;
        this->AdaptRiskByAsset = other.AdaptRiskByAsset;
        this->AdaptSLByAsset = other.AdaptSLByAsset;
        this->AdaptSpreadFilterByAsset = other.AdaptSpreadFilterByAsset;
        this->AdaptiveModeInput = other.AdaptiveModeInput;

        this->TakeProfitModeInput = other.TakeProfitModeInput;
        this->StopLossBufferATR_Ratio = other.StopLossBufferATR_Ratio;
        this->StopLossATR_Multiplier_TP = other.StopLossATR_Multiplier_TP;
        this->TakeProfitStructureBufferATR_Ratio = other.TakeProfitStructureBufferATR_Ratio;
        this->ADXThresholdForVolatilityTP = other.ADXThresholdForVolatilityTP;
        this->VolatilityTP_ATR_Multiplier_High = other.VolatilityTP_ATR_Multiplier_High;
        this->VolatilityTP_ATR_Multiplier_Low = other.VolatilityTP_ATR_Multiplier_Low;

        this->IsMasterPortfolioManager = other.IsMasterPortfolioManager;

        this->EAState = other.EAState;
        this->EmergencyMode = other.EmergencyMode;
        this->CurrentProfileData = other.CurrentProfileData; // Uses MarketProfileData's operator=

        return *this;
    }

    // Destructor
    ~EAContext() {
        // Các module sẽ được giải phóng trong hàm CleanupPartialInit của EA
    }
};

} // Kết thúc namespace ApexPullback

#endif // _COMMON_STRUCTS_MQH_