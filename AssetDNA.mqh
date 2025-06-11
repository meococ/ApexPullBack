//+------------------------------------------------------------------+
//|   AssetDNA.mqh - Module Phân tích DNA Tài sản                    |
//|   Kết hợp và nâng cao chức năng của AssetProfiler và             |
//|   AssetProfileManager thành một module thông minh hơn             |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, APEX Forex - Mèo Cọc"
#property link      ""
#property version   "1.00"
#property strict

#include "CommonStructs.mqh"
#include "Logger.mqh"
#include "MathHelper.mqh"
#include "IndicatorUtils.mqh"
#include <Arrays/ArrayObj.mqh> // Include for CArrayObj

namespace ApexPullback {

// Sử dụng ENUM_TRADING_STRATEGY và ENUM_STRATEGY_ID từ Enums.mqh
#include "FunctionDefinitions.mqh" // For DecodeStrategyFromMagic

//+------------------------------------------------------------------+
//| Hàm chuyển đổi ENUM_STRATEGY_ID sang ENUM_TRADING_STRATEGY      |
//+------------------------------------------------------------------+
ENUM_TRADING_STRATEGY ConvertStrategyIDToTradingStrategy(ENUM_STRATEGY_ID strategyId) {
    switch(strategyId) {
        case STRATEGY_ID_PULLBACK:          return STRATEGY_PULLBACK_TREND;
        case STRATEGY_ID_MEAN_REVERSION:    return STRATEGY_MEAN_REVERSION;
        case STRATEGY_ID_BREAKOUT:          return STRATEGY_MOMENTUM_BREAKOUT;
        case STRATEGY_ID_SHALLOW_PULLBACK:  return STRATEGY_SHALLOW_PULLBACK; // Hoặc một giá trị phù hợp khác trong ENUM_TRADING_STRATEGY
        case STRATEGY_ID_RANGE_TRADING:     return STRATEGY_RANGE_TRADING;    // Hoặc một giá trị phù hợp khác
        // Thêm các case khác nếu cần
        default:                            return STRATEGY_UNDEFINED;
    }
}

//+------------------------------------------------------------------+
//| Cấu trúc lưu trữ một giao dịch đơn lẻ                             |
//+------------------------------------------------------------------+
struct TradeRecord {
    long ticket;                // Số ticket của giao dịch
    datetime timeOpen;          // Thời gian mở lệnh
    datetime timeClose;         // Thời gian đóng lệnh
    ENUM_POSITION_TYPE type;    // Loại lệnh (buy/sell)
    double volume;              // Khối lượng giao dịch
    double priceOpen;           // Giá mở lệnh
    double priceClose;          // Giá đóng lệnh
    double profit;              // Lợi nhuận
    string symbol;              // Symbol giao dịch
    long magicNumber;           // Magic number
    string comment;             // Comment của lệnh
    ENUM_TRADING_STRATEGY scenario; // Kịch bản/chiến lược được sử dụng

    void Clear() {
        ticket = 0;
        timeOpen = 0;
        timeClose = 0;
        type = (ENUM_POSITION_TYPE)-1; // Invalid type
        volume = 0.0;
        priceOpen = 0.0;
        priceClose = 0.0;
        profit = 0.0;
        symbol = "";
        magicNumber = 0;
        comment = "";
        scenario = STRATEGY_UNDEFINED;
    }
};

//--- Strategy Performance Struct
struct StrategyPerformance {
    ENUM_TRADING_STRATEGY strategy;
    int totalTrades;
    int winningTrades;
    double avgWinRate;   // Phần trăm
    double profitFactor;
    double expectancy;   // Kỳ vọng (có thể tính bằng R hoặc tiền tệ)
    double sharpeRatio;  // Tỷ lệ Sharpe
    // Thêm các chỉ số khác nếu cần: Max Drawdown, Avg Win/Loss Ratio

    void Clear() {
        strategy = STRATEGY_UNDEFINED;
        totalTrades = 0;
        winningTrades = 0;
        avgWinRate = 0.0;
        profitFactor = 0.0;
        expectancy = 0.0;
        sharpeRatio = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Lớp CAssetDNA - Phân tích và quản lý DNA của tài sản             |
//+------------------------------------------------------------------+
class CAssetDNA {
protected:
    CLogger* m_logger;              // Con trỏ đến logger
    EAContext& m_context;           // Tham chiếu đến EA context
    string m_symbol;                // Symbol đang phân tích
    ENUM_TIMEFRAMES m_timeframe;    // Khung thời gian chính
    
    // Lưu trữ lịch sử giao dịch và hiệu suất
    CArrayObj* m_tradeHistory;      // Mảng lưu trữ lịch sử giao dịch (TradeRecord objects)
    StrategyPerformance m_strategyStats[]; // Thống kê hiệu suất theo chiến lược

    // Thêm các biến thành viên để lưu trữ hiệu suất lịch sử cho từng chiến lược cụ thể
    // Ví dụ cho Pullback, có thể thêm tương tự cho các chiến lược khác
    double m_pullback_win_rate;        
    double m_pullback_profit_factor;   
    int    m_pullback_total_trades;

    double m_breakout_win_rate;
    double m_breakout_profit_factor;
    int    m_breakout_total_trades;

    double m_mean_reversion_win_rate;
    double m_mean_reversion_profit_factor;
    int    m_mean_reversion_total_trades;

    double m_trend_following_win_rate; // For STRATEGY_SHALLOW_PULLBACK (Trend Following)
    double m_trend_following_profit_factor;
    int    m_trend_following_total_trades;

    double m_range_trading_win_rate;
    double m_range_trading_profit_factor;
    int    m_range_trading_total_trades;

    // Input parameter - should be ideally in Inputs.mqh and passed via EAContext
    // For now, we'll assume it's accessible or add a way to set it.
    // For this exercise, we will assume m_context.InputManager.EnableSelfLearning exists.
    // bool m_EnableSelfLearning; // Will be accessed via m_context.InputManager.EnableSelfLearning
    
    // Các đặc tính tĩnh của tài sản
    AssetProfileDataStruct m_assetProfile; // Thông tin cơ bản về tài sản
    
    // Các biến phân tích
    double m_volatilityScore;       // Điểm biến động
    double m_trendScore;            // Điểm xu hướng
    double m_momentumScore;         // Điểm động lượng
    double m_regimeScore;           // Điểm chế độ thị trường
    
public:
    //+------------------------------------------------------------------+
    //| Constructor                                                        |
    //+------------------------------------------------------------------+
    CAssetDNA(EAContext& context_param) : m_context(context_param) { // Sửa lỗi constructor
        m_logger = context_param.Logger; // Khởi tạo m_logger
        m_symbol = _Symbol;
        m_timeframe = PERIOD_CURRENT;
        m_tradeHistory = new CArrayObj();
        
    // Khởi tạo mảng thống kê chiến lược với kích thước cố định dựa trên số lượng chiến lược
        ArrayResize(m_strategyStats, 7); // STRATEGY_UNDEFINED + 6 chiến lược
        for(int i = 0; i < ArraySize(m_strategyStats); i++) {
            m_strategyStats[i].Clear();
            m_strategyStats[i].strategy = (ENUM_TRADING_STRATEGY)(i - 1); // -1 là STRATEGY_UNDEFINED
        }
        
        // Khởi tạo các điểm phân tích
        m_volatilityScore = 0.0;
        m_trendScore = 0.0;
        m_momentumScore = 0.0;
        m_regimeScore = 0.0;

        // Khởi tạo các biến hiệu suất lịch sử
        m_pullback_win_rate = 0.0;
        m_pullback_profit_factor = 0.0;
        m_pullback_total_trades = 0;
        m_breakout_win_rate = 0.0;
        m_breakout_profit_factor = 0.0;
        m_breakout_total_trades = 0;
        m_mean_reversion_win_rate = 0.0;
        m_mean_reversion_profit_factor = 0.0;
        m_mean_reversion_total_trades = 0;
        m_trend_following_win_rate = 0.0;
        m_trend_following_profit_factor = 0.0;
        m_trend_following_total_trades = 0;
        m_range_trading_win_rate = 0.0;
        m_range_trading_profit_factor = 0.0;
        m_range_trading_total_trades = 0;
        
        // Initialize() sẽ được gọi từ bên ngoài sau khi AssetDNA được tạo
    }
    
    //+------------------------------------------------------------------+
    //| Destructor                                                         |
    //+------------------------------------------------------------------+
    ~CAssetDNA() {
        if(m_tradeHistory != NULL) {
            m_tradeHistory.Clear();
            delete m_tradeHistory;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Khởi tạo và phân tích ban đầu                                     |
    //+------------------------------------------------------------------+
    bool Initialize() {
        if(m_logger == NULL) return false;
        
        m_logger.LogDebug("Đang khởi tạo AssetDNA cho " + m_symbol);
        
        // Phân tích đặc tính cơ bản của tài sản
        AnalyzeAssetCharacteristics();
        
        // Tải lịch sử giao dịch
        LoadTradeHistory();
        
        // Phân tích hiệu suất các chiến lược
        AnalyzeStrategyPerformance();
        
        m_logger.LogDebug("Khởi tạo AssetDNA hoàn tất");
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Phân tích đặc tính cơ bản của tài sản                            |
    //+------------------------------------------------------------------+
    void AnalyzeAssetCharacteristics() {
        // Phân tích biến động
        double atr = m_context.IndicatorUtils.GetATR(14);
        double atrPercent = (atr / SymbolInfoDouble(m_symbol, SYMBOL_BID)) * 100;
        
        // Phân tích xu hướng
        // Đăng ký và lấy giá trị các MA
        m_context.IndicatorUtils.RegisterMA(20);
        m_context.IndicatorUtils.RegisterMA(50);
        m_context.IndicatorUtils.RegisterMA(200);
        
        double ema20 = m_context.IndicatorUtils.GetMA(20);
        double ema50 = m_context.IndicatorUtils.GetMA(50);
        double ema200 = m_context.IndicatorUtils.GetMA(200);
        
        // Phân tích động lượng
        double rsi = m_context.IndicatorUtils.GetRSI();
        double macd = m_context.IndicatorUtils.GetMACDMain();
        
        // Cập nhật điểm số
        m_volatilityScore = NormalizeScore(atrPercent, 0.1, 2.0);
        m_trendScore = CalculateTrendScore(ema20, ema50, ema200);
        m_momentumScore = CalculateMomentumScore(rsi, macd);
        m_regimeScore = (m_trendScore + m_momentumScore) / 2;
        
        // Cập nhật thông tin vào profile
        m_assetProfile.averageATR = atr;
        m_assetProfile.yearlyVolatility = atrPercent * sqrt(252);
        m_assetProfile.isStrongTrending = (m_trendScore > 0.7);
        m_assetProfile.isMeanReverting = (m_regimeScore < 0.3);
    }
    
    //+------------------------------------------------------------------+
    //| Tải và phân tích lịch sử giao dịch                               |
    //+------------------------------------------------------------------+
    void LoadTradeHistory() {
        if(m_logger == NULL) return;
        m_logger.LogInfo("AssetDNA: Loading trade history...");
        if(m_tradeHistory == NULL) {
            m_tradeHistory = new CArrayObj();
        } else {
            m_tradeHistory.Clear(); // Xóa lịch sử cũ trước khi tải mới
        }

        // Chọn toàn bộ lịch sử giao dịch của tài khoản hiện tại
        if(!HistorySelect(0, TimeCurrent())) {
            m_logger.LogError("AssetDNA: HistorySelect failed. Error: " + IntegerToString(GetLastError()));
            return;
        }

        ulong ticket;
        long totalDeals = HistoryDealsTotal();
        m_logger.LogInfo("AssetDNA: Total deals in history: " + IntegerToString(totalDeals));

        for(long i = 0; i < totalDeals; i++) {
            ticket = HistoryDealGetTicket(i);
            if(ticket > 0) {
                long dealMagic = HistoryDealGetInteger(ticket, DEAL_MAGIC);
                string dealSymbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
                long dealType = HistoryDealGetInteger(ticket, DEAL_TYPE); // DEAL_TYPE_BUY, DEAL_TYPE_SELL
                long dealEntry = HistoryDealGetInteger(ticket, DEAL_ENTRY); // DEAL_ENTRY_IN, DEAL_ENTRY_OUT, DEAL_ENTRY_INOUT
                double dealProfit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                string dealComment = HistoryDealGetString(ticket, DEAL_COMMENT);

                // Chỉ xử lý các giao dịch đóng (DEAL_ENTRY_OUT) và của EA này (đúng MagicNumber và Symbol)
                // Hoặc các giao dịch INOUT (thường là đóng một phần hoặc reversal)
                if ((dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_INOUT) && 
                    dealMagic == m_context.InputManager.MagicNumber && 
                    dealSymbol == m_symbol) {
                    
                    TradeRecord* trade = new TradeRecord();
                    trade.ticket = ticket;
                    trade.timeOpen = HistoryDealGetInteger(ticket, DEAL_TIME); // Thời gian của deal, có thể cần tìm deal mở lệnh tương ứng
                    trade.timeClose = HistoryDealGetInteger(ticket, DEAL_TIME); // Thời gian của deal đóng lệnh
                    trade.type = (ENUM_POSITION_TYPE)dealType; // Cần điều chỉnh nếu dealType không khớp ENUM_POSITION_TYPE
                    trade.volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                    trade.priceOpen = HistoryDealGetDouble(ticket, DEAL_PRICE); // Giá của deal, có thể cần tìm deal mở lệnh
                    trade.priceClose = HistoryDealGetDouble(ticket, DEAL_PRICE); // Giá của deal đóng lệnh
                    trade.profit = dealProfit;
                    trade.symbol = dealSymbol;
                    trade.magicNumber = dealMagic;
                    trade.comment = dealComment;

                    // Giải mã Strategy ID từ Magic Number
                    ENUM_STRATEGY_ID decodedStrategyId = ::ApexPullback::DecodeStrategyFromMagic((int)dealMagic);
                    trade.scenario = ConvertStrategyIDToTradingStrategy(decodedStrategyId);

                    if(trade.scenario == STRATEGY_UNDEFINED && decodedStrategyId != STRATEGY_ID_UNDEFINED && dealMagic != m_context.InputManager.MagicNumber) {
                        // Log if magic is not base and not a known strategy ID (and not explicitly STRATEGY_ID_UNDEFINED)
                        m_logger.LogWarning(StringFormat("AssetDNA: Trade %d has magic %d. Decoded Strategy ID: %s, mapped to UNDEFINED scenario.", 
                                                        ticket, dealMagic, EnumToString(decodedStrategyId)));
                    } else if (decodedStrategyId == STRATEGY_ID_UNDEFINED && dealMagic != m_context.InputManager.MagicNumber) {
                         m_logger.LogInfo(StringFormat("AssetDNA: Trade %d has magic %d, which decodes to STRATEGY_ID_UNDEFINED. This might be an old trade or a non-strategy trade.", 
                                                        ticket, dealMagic));
                    }

                    // Cần một cách tốt hơn để lấy thông tin deal mở lệnh (giá mở, thời gian mở)
                    // Ví dụ: tìm deal DEAL_ENTRY_IN có cùng DEAL_POSITION_ID
                    long position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
                    for(long j = 0; j < i; j++) { // Duyệt các deal trước đó
                        ulong prev_ticket = HistoryDealGetTicket(j);
                        if(HistoryDealGetInteger(prev_ticket, DEAL_POSITION_ID) == position_id && 
                           HistoryDealGetInteger(prev_ticket, DEAL_ENTRY) == DEAL_ENTRY_IN) {
                            trade.timeOpen = HistoryDealGetInteger(prev_ticket, DEAL_TIME);
                            trade.priceOpen = HistoryDealGetDouble(prev_ticket, DEAL_PRICE);
                            // Giả sử type của deal mở lệnh là type của position
                            trade.type = (ENUM_POSITION_TYPE)HistoryDealGetInteger(prev_ticket, DEAL_TYPE);
                            break;
                        }
                    }

                    m_tradeHistory.Add(trade);
                }
            }
        }
        m_logger.LogInfo("AssetDNA: Loaded " + IntegerToString(m_tradeHistory.Total()) + " relevant trade records for " + m_symbol);
    }
    
    //+------------------------------------------------------------------+
    //| Phân tích hiệu suất các chiến lược                               |
    //+------------------------------------------------------------------+
    void AnalyzeStrategyPerformance() {
        if(m_logger == NULL) return;
        m_logger.LogInfo("AssetDNA: Analyzing strategy performance...");

        // Reset stats
        for(int i = 0; i < ArraySize(m_strategyStats); i++) {
            m_strategyStats[i].Clear();
            // Gán lại strategy enum sau khi Clear()
            if (i == 0) m_strategyStats[i].strategy = STRATEGY_UNDEFINED; // Index 0 for undefined
            else m_strategyStats[i].strategy = (ENUM_TRADING_STRATEGY)(i-1); // STRATEGY_PULLBACK_TREND is 0, so i-1
        }
        
        m_pullback_total_trades = 0; m_pullback_win_rate = 0; m_pullback_profit_factor = 0;
        m_breakout_total_trades = 0; m_breakout_win_rate = 0; m_breakout_profit_factor = 0;
        m_mean_reversion_total_trades = 0; m_mean_reversion_win_rate = 0; m_mean_reversion_profit_factor = 0;
        m_trend_following_total_trades = 0; m_trend_following_win_rate = 0; m_trend_following_profit_factor = 0;
        m_range_trading_total_trades = 0; m_range_trading_win_rate = 0; m_range_trading_profit_factor = 0;

        if(m_tradeHistory == NULL || m_tradeHistory.Total() == 0) {
            m_logger.LogWarning("AssetDNA: No trade history to analyze.");
            return;
        }

        // Biến tạm để tính toán cho từng chiến lược
        // [Strategy Enum Index][0=TotalProfit, 1=TotalLoss, 2=Wins, 3=Losses, 4=TotalTrades]
        // Kích thước là số lượng chiến lược + 1 cho undefined
        double stats[STRATEGY_RANGE_TRADING + 2][5]; // +1 for enum count, +1 for undefined index offset
        for(int i=0; i < ArraySize(stats); i++) {
            for(int j=0; j < 5; j++) {
                stats[i][j] = 0.0;
            }
        }

        for(int i = 0; i < m_tradeHistory.Total(); i++) {
            TradeRecord* trade = (TradeRecord*)m_tradeHistory.At(i);
            if(trade == NULL) continue;

            int strategyIdx = trade.scenario + 1; // Offset by 1 because STRATEGY_UNDEFINED is -1, PULLBACK is 0
            if(strategyIdx < 0 || strategyIdx >= ArraySize(stats)) {
                 m_logger.LogWarning("AssetDNA: Invalid strategy index " + IntegerToString(trade.scenario) + " for trade " + IntegerToString(trade.ticket));
                 strategyIdx = 0; // Default to undefined if out of bounds
            }

            stats[strategyIdx][4]++; // TotalTrades
            if(trade.profit > 0) {
                stats[strategyIdx][0] += trade.profit; // TotalProfit
                stats[strategyIdx][2]++; // Wins
            } else {
                stats[strategyIdx][1] += MathAbs(trade.profit); // TotalLoss
                stats[strategyIdx][3]++; // Losses
            }
        }

        // Tính toán và lưu trữ các chỉ số
        for(int i = 0; i < ArraySize(m_strategyStats); i++) {
            int statIdx = m_strategyStats[i].strategy + 1; // Get the correct index for stats array
             if(statIdx < 0 || statIdx >= ArraySize(stats)) {
                 m_logger.LogWarning("AssetDNA: Invalid statIdx " + IntegerToString(statIdx) + " during final calculation.");
                 continue;
            }

            m_strategyStats[i].totalTrades = (int)stats[statIdx][4];
            if(m_strategyStats[i].totalTrades > 0) {
                m_strategyStats[i].winningTrades = (int)stats[statIdx][2];
                m_strategyStats[i].avgWinRate = (stats[statIdx][2] / stats[statIdx][4]) * 100.0;
                if(stats[statIdx][1] > 0) { // Avoid division by zero for profit factor
                    m_strategyStats[i].profitFactor = stats[statIdx][0] / stats[statIdx][1];
                } else if (stats[statIdx][0] > 0) {
                    m_strategyStats[i].profitFactor = 999; // Indicate very high profit factor if no losses
                } else {
                    m_strategyStats[i].profitFactor = 0;
                }
                // Kỳ vọng: (WinRate * AvgWin) - (LossRate * AvgLoss)
                double avgWin = (stats[statIdx][2] > 0) ? stats[statIdx][0] / stats[statIdx][2] : 0;
                double avgLoss = (stats[statIdx][3] > 0) ? stats[statIdx][1] / stats[statIdx][3] : 0;
                double winRateDecimal = m_strategyStats[i].avgWinRate / 100.0;
                double lossRateDecimal = 1.0 - winRateDecimal;
                m_strategyStats[i].expectancy = (winRateDecimal * avgWin) - (lossRateDecimal * avgLoss);

                // Tính Sharpe Ratio (giả sử tỷ lệ phi rủi ro là 0)
                // Cần một mảng lưu trữ lợi nhuận của từng giao dịch để tính độ lệch chuẩn
                CArrayDouble* tradeProfits = new CArrayDouble();
                for(int k=0; k < m_tradeHistory.Total(); k++) {
                    TradeRecord* tr = (TradeRecord*)m_tradeHistory.At(k);
                    if(tr == NULL) continue;
                    // Đảm bảo rằng strategy của trade record khớp với strategy đang được phân tích
                    // và trade.scenario đã được gán đúng từ magic number
                    if(tr.scenario == m_strategyStats[i].strategy) {
                        tradeProfits.Add(tr.profit);
                    }
                }
                if(tradeProfits.Total() > 1) {
                    double sumProfits = 0;
                    for(int k=0; k < tradeProfits.Total(); k++) sumProfits += tradeProfits.At(k);
                    double meanProfit = sumProfits / tradeProfits.Total();
                    double sumSqDiff = 0;
                    for(int k=0; k < tradeProfits.Total(); k++) sumSqDiff += MathPow(tradeProfits.At(k) - meanProfit, 2);
                    double stdDev = MathSqrt(sumSqDiff / tradeProfits.Total());
                    if(stdDev > 0) {
                        m_strategyStats[i].sharpeRatio = meanProfit / stdDev; // Sharpe Ratio đơn giản hóa
                    } else {
                        m_strategyStats[i].sharpeRatio = 0; // Hoặc một giá trị lớn nếu meanProfit > 0 và stdDev = 0
                    }
                } else {
                    m_strategyStats[i].sharpeRatio = 0;
                }
                delete tradeProfits;

            } else {
                m_strategyStats[i].avgWinRate = 0;
                m_strategyStats[i].profitFactor = 0;
                m_strategyStats[i].expectancy = 0;
                m_strategyStats[i].sharpeRatio = 0;
            }
            
            // Cập nhật các biến thành viên riêng lẻ
            switch(m_strategyStats[i].strategy) {
                case STRATEGY_PULLBACK_TREND:
                    m_pullback_win_rate = m_strategyStats[i].avgWinRate;
                    m_pullback_profit_factor = m_strategyStats[i].profitFactor;
                    m_pullback_total_trades = m_strategyStats[i].totalTrades;
                    break;
                case STRATEGY_MOMENTUM_BREAKOUT:
                    m_breakout_win_rate = m_strategyStats[i].avgWinRate;
                    m_breakout_profit_factor = m_strategyStats[i].profitFactor;
                    m_breakout_total_trades = m_strategyStats[i].totalTrades;
                    break;
                case STRATEGY_MEAN_REVERSION:
                    m_mean_reversion_win_rate = m_strategyStats[i].avgWinRate;
                    m_mean_reversion_profit_factor = m_strategyStats[i].profitFactor;
                    m_mean_reversion_total_trades = m_strategyStats[i].totalTrades;
                    break;
                case STRATEGY_SHALLOW_PULLBACK: // Trend Following
                    m_trend_following_win_rate = m_strategyStats[i].avgWinRate;
                    m_trend_following_profit_factor = m_strategyStats[i].profitFactor;
                    m_trend_following_total_trades = m_strategyStats[i].totalTrades;
                    break;
                case STRATEGY_RANGE_TRADING:
                    m_range_trading_win_rate = m_strategyStats[i].avgWinRate;
                    m_range_trading_profit_factor = m_strategyStats[i].profitFactor;
                    m_range_trading_total_trades = m_strategyStats[i].totalTrades;
                    break;
                default: break;
            }

            if(m_logger.IsDebugEnabled()){
                 m_logger.LogDebug(StringFormat("Strategy: %s, Trades: %d, Wins: %d, WinRate: %.2f%%, PF: %.2f, Expectancy: %.2f",
                                    EnumToString(m_strategyStats[i].strategy),
                                    m_strategyStats[i].totalTrades,
                                    m_strategyStats[i].winningTrades,
                                    m_strategyStats[i].avgWinRate,
                                    m_strategyStats[i].profitFactor,
                                    m_strategyStats[i].expectancy));
            }
        }
        m_logger.LogInfo("AssetDNA: Strategy performance analysis complete.");
    }
    
    //+------------------------------------------------------------------+
    //| Lấy chiến lược tối ưu dựa trên điều kiện thị trường hiện tại     |
    //+------------------------------------------------------------------+
    ENUM_TRADING_STRATEGY GetOptimalStrategy(MarketProfileData& currentProfile) {
        double strategyScores[5] = {0}; // Mảng điểm số cho mỗi chiến lược
        
        // 1. Đánh giá điểm cho chiến lược Pullback
        strategyScores[0] = CalculatePullbackScore(currentProfile);
        
        // 2. Đánh giá điểm cho chiến lược Breakout
        strategyScores[1] = CalculateBreakoutScore(currentProfile);
        
        // 3. Đánh giá điểm cho chiến lược Mean Reversion
        strategyScores[2] = CalculateMeanReversionScore(currentProfile);
        
        // 4. Đánh giá điểm cho chiến lược Trend Following
        strategyScores[3] = CalculateTrendFollowingScore(currentProfile);
        
        // 5. Đánh giá điểm cho chiến lược Range Trading
        strategyScores[4] = CalculateRangeScore(currentProfile);
        
        // Tìm chiến lược có điểm cao nhất
        int bestIndex = ArrayMaximum(strategyScores);
        double bestScore = strategyScores[bestIndex];
        
        // Chỉ chọn chiến lược nếu điểm đủ cao
        if(bestScore >= 0.6) {
            switch(bestIndex) {
                case 0: return STRATEGY_PULLBACK_TREND;
                case 1: return STRATEGY_MOMENTUM_BREAKOUT;
                case 2: return STRATEGY_MEAN_REVERSION;
                case 3: return STRATEGY_SHALLOW_PULLBACK;
                case 4: return STRATEGY_RANGE_TRADING;
            }
        }
        
        return STRATEGY_PULLBACK_TREND; // Mặc định là chiến lược cốt lõi
    }
    
    //+------------------------------------------------------------------+
    //| Các phương thức tính điểm cho từng chiến lược                     |
    //+------------------------------------------------------------------+
    double CalculatePullbackScore(MarketProfileData& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược pullback theo xu hướng
        score += m_context.MarketProfile.trendScore * 2.0;
        score += (m_context.MarketProfile.recentSwingLow - m_context.MarketProfile.ema89) / m_context.MarketProfile.atrValue * 1.5; // Độ sâu pullback
        score += (m_context.MarketProfile.recentSwingLow - m_context.MarketProfile.ema89) / m_context.MarketProfile.atrValue > 0.3 ? 1.0 : 0.0;
        score += m_context.MarketProfile.macdHistogram * 1.0; // Momentum score

        // Thêm logic tự học nếu được bật và có đủ dữ liệu
        if (m_context.InputManager.EnableSelfLearning && m_pullback_total_trades >= m_context.InputManager.MinTradesForSelfLearning) {
            double performanceMetric = m_pullback_profit_factor; // Hoặc m_strategyStats[STRATEGY_PULLBACK_TREND+1].expectancy
            // Lấy expectancy từ m_strategyStats đã tính toán
            for(int k=0; k < ArraySize(m_strategyStats); k++){
                if(m_strategyStats[k].strategy == STRATEGY_PULLBACK_TREND){
                    performanceMetric = m_strategyStats[k].expectancy; // Sử dụng expectancy
                    break;
                }
            }
            score += CalculateDynamicBonusPenalty(performanceMetric, true); // true vì expectancy càng cao càng tốt
        }
        
        return score;
    }
    
    double CalculateBreakoutScore(MarketProfileData& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược momentum breakout
        score += m_context.MarketProfile.volumeRatio > 1.2 ? 2.0 : 0.0; // Tích lũy khối lượng
        score += m_context.MarketProfile.volumeRatio * 1.5; // Điểm khối lượng
        score += m_context.MarketProfile.volatilityRatio * 1.0; // Tỷ lệ biến động

        // Thêm logic tự học
        if (m_context.InputManager.EnableSelfLearning && m_breakout_total_trades >= m_context.InputManager.MinTradesForSelfLearning) {
            double performanceMetric = m_breakout_profit_factor;
            for(int k=0; k < ArraySize(m_strategyStats); k++){
                if(m_strategyStats[k].strategy == STRATEGY_MOMENTUM_BREAKOUT){
                    performanceMetric = m_strategyStats[k].expectancy;
                    break;
                }
            }
            score += CalculateDynamicBonusPenalty(performanceMetric, true);
        }
        
        return score;
    }
    
    double CalculateMeanReversionScore(MarketProfileData& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược mean reversion
        score += (m_context.MarketProfile.rsiValue < 30 || m_context.MarketProfile.rsiValue > 70) ? 2.0 : 0.0; // Quá mua/bán
        score += m_context.MarketProfile.isSidewaysOrChoppy ? 1.5 : 0.0; // Thị trường sideway
        score += MathAbs((m_context.MarketProfile.ema34 - m_context.MarketProfile.ema200) / m_context.MarketProfile.atrValue) * 1.0; // Độ lệch từ trung bình

        // Thêm logic tự học
        if (m_context.InputManager.EnableSelfLearning && m_mean_reversion_total_trades >= m_context.InputManager.MinTradesForSelfLearning) {
            double performanceMetric = m_mean_reversion_profit_factor;
             for(int k=0; k < ArraySize(m_strategyStats); k++){
                if(m_strategyStats[k].strategy == STRATEGY_MEAN_REVERSION){
                    performanceMetric = m_strategyStats[k].expectancy;
                    break;
                }
            }
            score += CalculateDynamicBonusPenalty(performanceMetric, true);
        }
        
        return score;
    }
    
    double CalculateTrendFollowingScore(MarketProfileData& profile) {
        double score = 0.0;
        
        // Kiểm tra xu hướng mạnh
        if(profile.TrendStrength > 0.7) score += 0.4; // Sử dụng tên thành viên đúng
        
        // Kiểm tra momentum
        if(profile.MomentumScore > 0.6) score += 0.3; // Sử dụng tên thành viên đúng
        
        // Kiểm tra volume
        if(profile.VolumeScore > 0.6) score += 0.3; // Sử dụng tên thành viên đúng

        // Thêm logic tự học (cho STRATEGY_SHALLOW_PULLBACK)
        if (m_context.InputManager.EnableSelfLearning && m_trend_following_total_trades >= m_context.InputManager.MinTradesForSelfLearning) {
            double performanceMetric = m_trend_following_profit_factor;
            for(int k=0; k < ArraySize(m_strategyStats); k++){
                if(m_strategyStats[k].strategy == STRATEGY_SHALLOW_PULLBACK){
                    performanceMetric = m_strategyStats[k].expectancy;
                    break;
                }
            }
            score += CalculateDynamicBonusPenalty(performanceMetric, true);
        }
        
        return score;
    }
    
    double CalculateRangeScore(MarketProfileData& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược range trading
        score += m_context.MarketProfile.isSidewaysOrChoppy ? 2.0 : 0.0; // Thị trường sideway
        score += m_context.MarketProfile.volatilityRatio * 1.5; // Tỷ lệ biến động
        score += (1.0 - MathAbs(m_context.MarketProfile.volumeRatio - 1.0)) * 1.0; // Độ ổn định khối lượng

        // Thêm logic tự học
        if (m_context.InputManager.EnableSelfLearning && m_range_trading_total_trades >= m_context.InputManager.MinTradesForSelfLearning) {
            double performanceMetric = m_range_trading_profit_factor;
             for(int k=0; k < ArraySize(m_strategyStats); k++){
                if(m_strategyStats[k].strategy == STRATEGY_RANGE_TRADING){
                    performanceMetric = m_strategyStats[k].expectancy;
                    break;
                }
            }
            // Range trading có thể có kỳ vọng thấp hơn nhưng vẫn ổn định
            score += CalculateDynamicBonusPenalty(performanceMetric, true, 0.05, 0.01); // Ngưỡng khác cho range
        }
        
        return score;
    }
    
    //+------------------------------------------------------------------+
    //| Các phương thức hỗ trợ                                            |
    //+------------------------------------------------------------------+
    double NormalizeScore(double value, double min, double max) {
        return MathMax(0.0, MathMin(1.0, (value - min) / (max - min)));
    }
    
    double CalculateTrendScore(double ema20, double ema50, double ema200) {
        double score = 0.0;
        
        // Kiểm tra alignment của các EMA
        if(ema20 > ema50 && ema50 > ema200) score += 0.6; // Uptrend
        else if(ema20 < ema50 && ema50 < ema200) score += 0.6; // Downtrend
        
        // Kiểm tra khoảng cách giữa các EMA
        double ema20_50_spread = MathAbs(ema20 - ema50) / ema50 * 100;
        double ema50_200_spread = MathAbs(ema50 - ema200) / ema200 * 100;
        
        score += NormalizeScore(ema20_50_spread, 0.1, 1.0) * 0.2;
        score += NormalizeScore(ema50_200_spread, 0.1, 2.0) * 0.2;
        
        return score;
    }
    
    // Hàm tính điểm thưởng/phạt động
    double CalculateDynamicBonusPenalty(double metricValue, bool higherIsBetter, double goodThreshold = 0.1, double badThreshold = -0.05, double maxBonus = 0.3, double maxPenalty = -0.3, double scaleFactor = 0.1) {
        // Ví dụ: metricValue là Expectancy (tính bằng R)
        // goodThreshold: kỳ vọng > 0.1R là tốt
        // badThreshold: kỳ vọng < -0.05R là tệ
        // scaleFactor: mức độ thay đổi điểm cho mỗi 0.01R thay đổi trong kỳ vọng
        
        if (higherIsBetter) {
            if (metricValue > goodThreshold) {
                return MathMin(maxBonus, (metricValue - goodThreshold) / 0.01 * scaleFactor); // Thưởng điểm
            } else if (metricValue < badThreshold) {
                return MathMax(maxPenalty, (metricValue - badThreshold) / 0.01 * scaleFactor); // Phạt điểm
            }
        } else { // Lower is better (ví dụ: drawdown)
            if (metricValue < goodThreshold) { // goodThreshold lúc này là mức thấp mong muốn
                return MathMin(maxBonus, (goodThreshold - metricValue) / 0.01 * scaleFactor); // Thưởng điểm
            } else if (metricValue > badThreshold) { // badThreshold lúc này là mức cao không mong muốn
                return MathMax(maxPenalty, (badThreshold - metricValue) / 0.01 * scaleFactor); // Phạt điểm
            }
        }
        return 0.0; // Không có thưởng/phạt đáng kể
    }

    double CalculateMomentumScore(double rsi, double macd) {
        double score = 0.0;
        
        // Đánh giá RSI
        if(rsi > 70 || rsi < 30) score += 0.5;
        else if(rsi > 60 || rsi < 40) score += 0.3;
        
        // Đánh giá MACD
        if(MathAbs(macd) > 0) score += 0.5;
        
        return score;
    }
    
    //+------------------------------------------------------------------+
    //| Các phương thức truy xuất thông tin                               |
    //+------------------------------------------------------------------+
    double GetRecommendedRisk() {
        return m_assetProfile.recommendedRiskPercent;
    }
    
    double GetOptimalRR() {
        return m_assetProfile.optimalRRRatio;
    }
    
    double GetOptimalSLAtrMultiplier() {
        return m_assetProfile.optimalSLATRMulti;
    }
};

} // namespace ApexPullback