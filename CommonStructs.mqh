//+------------------------------------------------------------------+
//|                      CommonStructs.mqh - APEX Pullback EA v14.0   |
//|             Author: APEX Forex Team | Date: 2024-05-07           |
//|     Description: Định nghĩa cấu trúc dữ liệu trung tâm cho EA    |
//+------------------------------------------------------------------+

#ifndef _COMMON_STRUCTS_MQH_
#define _COMMON_STRUCTS_MQH_

#include "Enums.mqh"                        // Định nghĩa enums
//+------------------------------------------------------------------+
//| Định nghĩa cấu trúc dữ liệu Market Profile                       |
//+------------------------------------------------------------------+

/// @brief Cấu trúc lưu trữ thông tin thị trường toàn diện
struct MarketProfileData {
    // Thông tin cơ bản về thị trường
    ENUM_MARKET_TREND trend;            // Xu hướng thị trường hiện tại
    ENUM_MARKET_REGIME regime;          // Chế độ thị trường (Trending, Ranging, Volatile...)
    ENUM_SESSION currentSession;        // Phiên giao dịch hiện tại
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
        currentSession = SESSION_UNKNOWN; // Đã thêm SESSION_UNKNOWN
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
        
        trailingMode = TRAILING_NONE;
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
struct AssetProfile {
    string symbol;                     // Symbol giao dịch
    string assetType;                  // Loại tài sản (forex, gold, indices, crypto)
    double averageDailyRange;          // Biên độ dao động trung bình ngày (pips)
    double averageATR;                 // ATR trung bình 14 ngày
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
    
    // Phương thức làm sạch dữ liệu
    void Clear() {
        time = 0;
        currency = "";
        name = "";
        impact = 0;
        affecting = false;
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
#endif // _COMMON_STRUCTS_MQH_ // _STRUCTS_MQH_