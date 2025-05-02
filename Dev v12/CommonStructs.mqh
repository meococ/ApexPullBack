//+------------------------------------------------------------------+
//|              CommonStructs.mqh (ApexPullback EA)                 |
//|                  Copyright 2023-2025, ApexTrading Systems        |
//|                           https://www.apextradingsystems.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "12.1"

#pragma once

// Các Enum cần thiết
enum ENUM_MARKET_PRESET {
    PRESET_FOREX_MAJORS,       // Forex Majors (EURUSD, GBPUSD, etc.)
    PRESET_FOREX_CROSSES,      // Forex Crosses (EURJPY, GBPAUD, etc.)
    PRESET_INDICES,            // Indices (US30, SPX500, etc.)
    PRESET_COMMODITIES,        // Commodities (GOLD, OIL, etc.)
    PRESET_CRYPTO,             // Cryptocurrencies
    PRESET_CUSTOM              // Tùy chỉnh thủ công
};

// Struct cho thông tin vị thế
struct PositionInfo {
    ulong    ticket;           // Ticket của vị thế
    string   symbol;           // Symbol của vị thế
    int      type;             // Loại vị thế (buy/sell)
    double   volume;           // Khối lượng
    double   openPrice;        // Giá mở lệnh
    double   stopLoss;         // Giá stop loss
    double   takeProfit;       // Giá take profit
    datetime openTime;         // Thời gian mở lệnh
    bool     isPartialClosed;  // Đã đóng một phần chưa
    int      partialCloseCount;// Số lần đóng một phần
    bool     isBreakEven;      // Đã đưa về hòa vốn chưa
    bool     isTrailing;       // Đang trailing stop chưa
    int      entryScenario;    // Kịch bản mở lệnh
    double   riskAmount;       // Lượng rủi ro
};

// Struct cho thông tin thị trường
struct MarketInfo {
    string   symbol;           // Symbol
    datetime timestamp;        // Thời gian cập nhật
    double   bid;              // Giá bid
    double   ask;              // Giá ask
    double   spread;           // Spread
    double   atr;              // ATR
    double   dailyVolatility;  // Độ biến động hàng ngày
    double   trendStrength;    // Độ mạnh của xu hướng
    int      marketPhase;      // Giai đoạn thị trường
    int      currentSession;   // Phiên giao dịch hiện tại
    double   supportLevel;     // Mức hỗ trợ gần nhất
    double   resistanceLevel;  // Mức kháng cự gần nhất
    double   psarValue;        // Giá trị Parabolic SAR
    bool     isTrending;       // Có đang trending không
    bool     isVolatile;       // Có đang biến động mạnh không
    double   pullbackLevel;    // Mức pullback hiện tại
    double   rsi;              // Giá trị RSI
};

// Struct cho tín hiệu giao dịch
struct TradeSignal {
    bool     isValid;          // Tín hiệu có hợp lệ không
    bool     isLong;           // Là tín hiệu mua hay bán
    double   entryPrice;       // Giá vào lệnh
    double   stopLoss;         // Giá dừng lỗ
    double   takeProfit;       // Giá chốt lời
    double   riskRewardRatio;  // Tỉ lệ reward:risk
    double   lotSize;          // Khối lượng đề xuất
    int      scenario;         // Kịch bản mở lệnh
    double   trendStrength;    // Độ mạnh xu hướng
    double   entryQuality;     // Chất lượng tín hiệu
    datetime signalTime;       // Thời điểm tạo tín hiệu
    string   comment;          // Ghi chú về tín hiệu
};

// Struct cho các thông số hiệu suất
struct PerformanceMetrics {
    int      totalTrades;      // Tổng số giao dịch
    int      winningTrades;    // Số giao dịch thắng
    int      losingTrades;     // Số giao dịch thua
    double   winRate;          // Tỉ lệ thắng
    double   profitFactor;     // Hệ số lợi nhuận
    double   expectancy;       // Kỳ vọng trung bình/giao dịch
    double   avgWin;           // Lãi trung bình/giao dịch thắng
    double   avgLoss;          // Lỗ trung bình/giao dịch thua
    double   maxDrawdown;      // Rút vốn tối đa
    double   maxConsecutiveLosses; // Số lần thua liên tiếp tối đa
    double   totalProfit;      // Tổng lợi nhuận
    double   sharpeRatio;      // Tỉ số Sharpe
    double   recoveryFactor;   // Hệ số phục hồi
};

// Struct cho thống kê theo kịch bản
struct ScenarioStats {
    int      scenario;         // ID kịch bản
    int      totalTrades;      // Tổng số giao dịch
    int      winningTrades;    // Số giao dịch thắng
    double   winRate;          // Tỉ lệ thắng
    double   profitFactor;     // Hệ số lợi nhuận
    double   expectancy;       // Kỳ vọng trung bình/giao dịch
    double   averageRRR;       // Tỉ lệ reward:risk trung bình
};

// Các biến toàn cục
extern double g_MinPullbackPct = 0.382;   // Giá trị pullback tối thiểu (%)
extern double g_MaxPullbackPct = 0.618;   // Giá trị pullback tối đa (%)
extern int LookbackBars = 100;            // Số nến nhìn lại để phân tích
extern int MaxSpreadPoints = 10;          // Spread tối đa cho phép (điểm)
extern double EnvF = 1.5;                 // Hệ số envelope
extern double SL_ATR = 1.5;               // Hệ số ATR cho Stop Loss
extern double TP_RR = 2.0;                // Tỉ lệ Risk:Reward cho Take Profit
