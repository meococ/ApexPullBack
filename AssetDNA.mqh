//+------------------------------------------------------------------+
//|                      AssetDNA.mqh                                |
//+------------------------------------------------------------------+
#ifndef ASSETDNA_MQH_
#define ASSETDNA_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "Enums.mqh"            // TẤT CẢ các enum
#include "CommonStructs.mqh"    // TẤT CẢ các struct (bao gồm EAContext)
#include "Inputs.mqh" // Unified constants and input parameters

// === INCLUDES CỤ THỂ (NẾU CẦN) ===
// Include các thư viện MQL5 cần thiết
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/SymbolInfo.mqh>
#include <Arrays/ArrayObj.mqh>
#include <Arrays/Array.mqh>
#include "Logger.mqh"         // Cần cho CLogger
#include "MathHelper.mqh"     // Nếu bạn có các hàm toán học tùy chỉnh
#include "../Optimization/TradeHistoryOptimizer.mqh" // Cần cho CTradeHistoryOptimizer



// BẮT ĐẦU NAMESPACE
namespace ApexPullback {


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
class TradeRecord : public CObject {
public:
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

    //--- Constructor
    TradeRecord() {
        Clear();
    }

    //--- Method to clear data
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
class CAssetDNA : public CObject {
private:
    ApexPullback::EAContext* m_context;             // Con trỏ tới EAContext
    CLogger* m_logger;                          // Con trỏ đến logger
    CTradeHistoryOptimizer* m_optimizer;        // Con trỏ tới bộ tối ưu hóa lịch sử giao dịch
    string m_symbol;                            // Symbol đang phân tích
    ENUM_TIMEFRAMES m_timeframe;                // Khung thời gian chính

    // Lưu trữ lịch sử giao dịch và hiệu suất
    CArrayObj m_tradeHistory;                     // Mảng lưu trữ lịch sử giao dịch (TradeRecord objects)
    StrategyPerformance m_strategyStats[];          // Thống kê hiệu suất theo chiến lược


    // Các biến hiệu suất riêng lẻ đã được loại bỏ và thay thế bằng mảng m_strategyStats.

    // Input parameter - should be ideally in Inputs.mqh and passed via EAContext
    // For now, we'll assume it's accessible or add a way to set it.
    // For this exercise, we will assume m_context->InputManager.EnableSelfLearning exists.
    // bool m_EnableSelfLearning; // Will be accessed via m_context->InputManager.EnableSelfLearning
    
    // Các đặc tính tĩnh của tài sản
    ApexPullback::AssetProfileData m_assetProfile; // Thông tin cơ bản về tài sản (Đảm bảo struct này được định nghĩa trong namespace ApexPullback)
    
    // Các biến phân tích
    double m_volatilityScore;       // Điểm biến động
    double m_trendScore;            // Điểm xu hướng
    double m_momentumScore;         // Điểm động lượng
    double m_regimeScore;           // Điểm chế độ thị trường
    
    // --- Cross-Validation và Anti-Overfitting Structures ---
    struct CrossValidationResult {
        double avgWinRate;           // Win rate trung bình từ CV
        double avgProfitFactor;      // Profit factor trung bình từ CV
        double avgExpectancy;        // Expectancy trung bình từ CV
        double winRateVariance;      // Phương sai của win rate
        double profitFactorVariance; // Phương sai của profit factor
        double expectancyVariance;   // Phương sai của expectancy
        int validFolds;              // Số fold hợp lệ
        double stabilityIndex;       // Chỉ số ổn định (0-1)
        
        void Clear() {
            avgWinRate = 0.0;
            avgProfitFactor = 0.0;
            avgExpectancy = 0.0;
            winRateVariance = 0.0;
            profitFactorVariance = 0.0;
            expectancyVariance = 0.0;
            validFolds = 0;
            stabilityIndex = 0.0;
        }
    };
    
public:
    //+------------------------------------------------------------------+
//| Constructor                                                        |
//+------------------------------------------------------------------+
CAssetDNA() { // Hàm khởi tạo mặc định
    m_context = NULL;
    m_logger = NULL;
    m_symbol = "";
    m_timeframe = PERIOD_CURRENT;
    // m_tradeHistory is now an object member, no 'new' needed.
    // Các khởi tạo khác sẽ được thực hiện trong Initialize
}

//+------------------------------------------------------------------+
//| Initialize Method                                                  |
//+------------------------------------------------------------------+
void Initialize(ApexPullback::EAContext &context) {
    m_context = &context;
    m_logger = m_context->Logger;
    m_optimizer = m_context->TradeHistoryOptimizer; // Lấy con trỏ từ context
    m_symbol = m_context->Symbol;
    m_timeframe = m_context->MainTimeframe;

    // Set free mode for the trade history array object.
    // It will now automatically delete the TradeRecord objects it contains.
    m_tradeHistory.SetFreeMode(true);

    // Khởi tạo mảng thống kê chiến lược
    // Sử dụng ENUM_TRADING_STRATEGY_COUNT để code linh hoạt, không hard-code
    int numStrategies = ENUM_TRADING_STRATEGY_COUNT; 
    ArrayResize(m_strategyStats, numStrategies);
    for(int i = 0; i < numStrategies; i++) {
        m_strategyStats[i].Clear();
        m_strategyStats[i].strategy = (ENUM_TRADING_STRATEGY)i;
    }

    // Khởi tạo các điểm phân tích
    m_volatilityScore = 0.0;
    m_trendScore = 0.0;
    m_momentumScore = 0.0;
    m_regimeScore = 0.0;

    // Các biến hiệu suất lịch sử riêng lẻ đã được loại bỏ,
    // tất cả sẽ được quản lý trong mảng m_strategyStats.
}
    
    //+------------------------------------------------------------------+
    //| Destructor                                                         |
    //+------------------------------------------------------------------+
    ~CAssetDNA() {
        // m_tradeHistory is now an object member, its destructor will be called automatically.
        // Since SetFreeMode(true) was set, it will also clear its contents (delete objects).
        // No manual cleanup is needed.
    }
    
    //+------------------------------------------------------------------+
//| Thực hiện phân tích toàn diện                                      |
//+------------------------------------------------------------------+
bool FullAnalysis() {
    if(m_logger == NULL || m_context == NULL) return false;
    
    m_logger->LogDebug("Bắt đầu phân tích toàn diện AssetDNA cho " + m_symbol);
    
    AnalyzeAssetCharacteristics();
    LoadTradeHistory();
    AnalyzeStrategyPerformance();
    
    m_logger->LogDebug("Phân tích toàn diện AssetDNA hoàn tất");
    return true;
}
    
    //+------------------------------------------------------------------+
    //| Phân tích đặc tính cơ bản của tài sản                            |
    //+------------------------------------------------------------------+
    void AnalyzeAssetCharacteristics() {
        // Phân tích biến động
        double atr = m_context->IndicatorUtils->GetATR(14);
        double atrPercent = (atr / SymbolInfoDouble(m_symbol, SYMBOL_BID)) * 100;
        
        // Phân tích xu hướng
        // Đăng ký và lấy giá trị các MA
        m_context->IndicatorUtils->RegisterMA(20);
        m_context->IndicatorUtils->RegisterMA(50);
        m_context->IndicatorUtils->RegisterMA(200);
        
        double ema20 = m_context->IndicatorUtils->GetMA(20);
        double ema50 = m_context->IndicatorUtils->GetMA(50);
        double ema200 = m_context->IndicatorUtils->GetMA(200);
        
        // Phân tích động lượng
        double rsi = m_context->IndicatorUtils->GetRSI();
        double macd = m_context->IndicatorUtils->GetMACDMain();
        
        // Cập nhật điểm số (Giả sử các hàm này được định nghĩa trong class hoặc là static)
// Ví dụ: m_volatilityScore = MathHelper::Normalize(atrPercent, 0.1, 2.0);
m_volatilityScore = CalculateVolatilityScore(atrPercent);
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
        m_logger->LogInfo("AssetDNA: Loading trade history...");
        
        // m_tradeHistory is now an object, no need to check for NULL or 'new' it.
        // Just clear the existing history before loading new data.
        m_tradeHistory.Clear(); 

        // Chọn toàn bộ lịch sử giao dịch của tài khoản hiện tại
        if(!HistorySelect(0, TimeCurrent())) {
            m_logger->LogError("AssetDNA: HistorySelect failed. Error: " + IntegerToString(GetLastError()));
            return;
        }

        ulong ticket;
        long totalDeals = HistoryDealsTotal();
        m_logger->LogInfo("AssetDNA: Total deals in history: " + IntegerToString(totalDeals));

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
                    (dealMagic == m_context->MagicNumber || (dealMagic >= EA_MAGIC_NUMBER_BASE && dealMagic < EA_MAGIC_NUMBER_BASE + 1000)) && // Chấp nhận dải magic number
                    dealSymbol == m_symbol) {
                    
                    // TradeRecord is now a class, creating an instance with 'new' is correct for CArrayObj
                    TradeRecord* trade = new TradeRecord();
                    if(trade == NULL) continue; // Kiểm tra cấp phát bộ nhớ

                    trade->ticket = ticket;
                    trade->timeClose = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
                    trade->priceClose = HistoryDealGetDouble(ticket, DEAL_PRICE);
                    trade->volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
                    trade->profit = dealProfit;
                    trade->symbol = dealSymbol;
                    trade->magicNumber = dealMagic;
                    trade->comment = dealComment;

                    // Tìm deal mở lệnh tương ứng một cách hiệu quả
                    long position_id = HistoryDealGetInteger(ticket, DEAL_POSITION_ID);
                    if(position_id > 0) {
                        if(HistorySelectByPosition(position_id)) {
                            // Deal đầu tiên (index 0) trong một position là deal mở lệnh
                            ulong open_deal_ticket = HistoryDealGetTicket(0);
                            if(open_deal_ticket > 0) {
                                trade->timeOpen = (datetime)HistoryDealGetInteger(open_deal_ticket, DEAL_TIME);
                                trade->priceOpen = HistoryDealGetDouble(open_deal_ticket, DEAL_PRICE);
                                trade->type = (ENUM_POSITION_TYPE)HistoryDealGetInteger(open_deal_ticket, DEAL_TYPE);
                            }
                        }
                    }

                    ENUM_STRATEGY_ID decodedStrategyId = DecodeStrategyFromMagic((int)dealMagic);
                    trade->scenario = ConvertStrategyIDToTradingStrategy(decodedStrategyId);

                    m_tradeHistory.Add(trade); // Use '.' instead of '->'
                }
            }
        }
        m_logger->LogInfo("AssetDNA: Loaded " + IntegerToString(m_tradeHistory.Total()) + " relevant trade records for " + m_symbol);
    }

    //+------------------------------------------------------------------+
    //| Các hàm tính điểm (Helper functions)                             |
    //+------------------------------------------------------------------+
    double CalculateVolatilityScore(double atrPercent) {
        // Chuẩn hóa điểm từ 0 đến 1. Ví dụ: atr 0.1% là 0, 2.0% là 1
        return MathHelper::Normalize(atrPercent, 0.1, 2.0);
    }

    double CalculateTrendScore(double ema20, double ema50, double ema200) {
        // Logic tính điểm xu hướng dựa trên vị trí tương đối của các đường MA
        if (ema20 > ema50 && ema50 > ema200) return 1.0; // Xu hướng tăng mạnh
        if (ema20 < ema50 && ema50 < ema200) return 0.0; // Xu hướng giảm mạnh
        return 0.5; // Thị trường đi ngang hoặc không rõ xu hướng
    }

    double CalculateMomentumScore(double rsi, double macd) {
        // Logic tính điểm động lượng
        double rsiScore = MathHelper::Normalize(rsi, 30, 70);
        // Cần thêm logic cho MACD, ở đây chỉ là ví dụ
        return rsiScore;
    }

    //+------------------------------------------------------------------+
    //| Phân tích hiệu suất các chiến lược                               |
    //+------------------------------------------------------------------+
    //+------------------------------------------------------------------+
//| Analyzes historical trades to calculate performance metrics      |
//| for each strategy, applying a time-decay weight to recent trades.|
//+------------------------------------------------------------------+
void AnalyzeStrategyPerformance() {
    if (m_logger != NULL && m_context != NULL && m_context->EnableMethodLogging) {
        m_logger->LogDebug("AssetDNA: Starting strategy performance analysis...");
    }

    // 1. Reset all current strategy statistics
    for (int i = 0; i < ENUM_TRADING_STRATEGY_COUNT; i++) {
        m_strategyStats[i].Clear();
        // Re-assign the strategy enum after clearing
        m_strategyStats[i].strategy = (ENUM_TRADING_STRATEGY)i;
    }

    // 2. Check if there is any trade history to analyze
    if (m_tradeHistory.Total() == 0) {
        if (m_logger != NULL && m_context != NULL && m_context->EnableMethodLogging) {
            m_logger->LogDebug("AssetDNA: No trade history found to analyze.");
        }
        return;
    }

    // 3. Define temporary arrays for weighted calculations
    double weighted_total_profit[ENUM_TRADING_STRATEGY_COUNT];
    double weighted_total_loss[ENUM_TRADING_STRATEGY_COUNT];
    double weighted_wins[ENUM_TRADING_STRATEGY_COUNT];
    double weighted_losses[ENUM_TRADING_STRATEGY_COUNT];
    double weighted_total_trades[ENUM_TRADING_STRATEGY_COUNT];
    
    // Initialize temporary arrays
    for(int i = 0; i < ENUM_TRADING_STRATEGY_COUNT; i++) {
        weighted_total_profit[i] = 0.0;
        weighted_total_loss[i] = 0.0;
        weighted_wins[i] = 0.0;
        weighted_losses[i] = 0.0;
        weighted_total_trades[i] = 0.0;
    }

    // 4. Iterate through trade history and aggregate weighted stats
    datetime cutoffTime = 0;
    if (m_context != NULL && m_context->HistoryAnalysisMonths > 0) {
        cutoffTime = TimeCurrent() - ((long)m_context->HistoryAnalysisMonths * 30 * 24 * 3600);
    }

    for (int i = 0; i < m_tradeHistory.Total(); i++) {
        TradeRecord* trade = (TradeRecord*)m_tradeHistory.At(i);
        if (trade == NULL) continue;

        // Skip old trades if a time limit is set
        if (cutoffTime > 0 && trade->timeOpen < cutoffTime) continue;

        int strategyIdx = (int)trade->scenario;
        if (strategyIdx < 0 || strategyIdx >= ENUM_TRADING_STRATEGY_COUNT) {
            if (m_logger != NULL) m_logger->LogWarning(StringFormat("AssetDNA: Invalid strategy index %d for trade #%d", strategyIdx, trade->ticket));
            continue;
        }

        double decayWeight = CalculateTradeDecayWeight(trade->timeOpen);
        
        m_strategyStats[strategyIdx].totalTrades++; // Unweighted count
        weighted_total_trades[strategyIdx] += decayWeight;

        if (trade->profit > 0) {
            weighted_total_profit[strategyIdx] += trade->profit * decayWeight;
            weighted_wins[strategyIdx] += decayWeight;
        } else {
            weighted_total_loss[strategyIdx] += fabs(trade->profit) * decayWeight;
            weighted_losses[strategyIdx] += decayWeight;
        }
    }

    // 5. Calculate final performance metrics from aggregated stats
    for (int i = 0; i < ENUM_TRADING_STRATEGY_COUNT; i++) {
        if (weighted_total_trades[i] > 0.01) { // Check for a minimum weight to avoid division by zero
            
            // Weighted Win Rate
            m_strategyStats[i].avgWinRate = (weighted_wins[i] / weighted_total_trades[i]) * 100.0;
            
            // Weighted Profit Factor
            if (weighted_total_loss[i] > 0) {
                m_strategyStats[i].profitFactor = weighted_total_profit[i] / weighted_total_loss[i];
            } else if (weighted_total_profit[i] > 0) {
                m_strategyStats[i].profitFactor = 999.0; // A large number to represent infinite PF
            } else {
                m_strategyStats[i].profitFactor = 0.0;
            }
            
            // Weighted Expectancy
            m_strategyStats[i].expectancy = (weighted_total_profit[i] - weighted_total_loss[i]) / weighted_total_trades[i];
            
            // Weighted Sharpe Ratio (simplified)
            double avgReturn = m_strategyStats[i].expectancy;
            double weightedVariance = 0.0;
            
            for(int j = 0; j < m_tradeHistory.Total(); j++) {
                TradeRecord* tr = (TradeRecord*)m_tradeHistory.At(j);
                if (tr == NULL || (int)tr->scenario != i) continue;
                if (cutoffTime > 0 && tr->timeOpen < cutoffTime) continue;
                
                double weight = CalculateTradeDecayWeight(tr->timeOpen);
                double deviation = tr->profit - avgReturn;
                weightedVariance += weight * deviation * deviation;
            }
            
            if (weighted_total_trades[i] > 1.0) { // Need more than one effective trade
                double stdDev = sqrt(weightedVariance / weighted_total_trades[i]);
                if (stdDev > 0) {
                    m_strategyStats[i].sharpeRatio = avgReturn / stdDev;
                }
            }
        }
        
        // Log results for this strategy if enabled
        if (m_context != NULL && m_context->EnableStrategyPerformanceLogging && m_strategyStats[i].totalTrades > 0) {
            m_logger->LogInfo(StringFormat("Strategy [%s]: Trades=%d, WinRate=%.2f%%, PF=%.2f, Expectancy=%.2f, Sharpe=%.2f",
                EnumToString((ENUM_TRADING_STRATEGY)i),
                m_strategyStats[i].totalTrades,
                m_strategyStats[i].avgWinRate,
                m_strategyStats[i].profitFactor,
                m_strategyStats[i].expectancy,
                m_strategyStats[i].sharpeRatio));
        }
    }
    
    if (m_logger != NULL && m_context != NULL && m_context->EnableMethodLogging) {
        m_logger->LogDebug("AssetDNA: Strategy performance analysis finished.");
    }
}

    //+------------------------------------------------------------------+
    //| Giải mã ID chiến lược từ Magic Number                            |
    //+------------------------------------------------------------------+
    ENUM_STRATEGY_ID DecodeStrategyFromMagic(int magic) {
        if (magic >= EA_MAGIC_NUMBER_BASE && magic < EA_MAGIC_NUMBER_BASE + 1000) {
            int strategyPart = magic - EA_MAGIC_NUMBER_BASE;
            // Giả sử 100 số đầu tiên cho mỗi chiến lược
            if (strategyPart < 100) return STRATEGY_ID_PULLBACK;
            if (strategyPart < 200) return STRATEGY_ID_MEAN_REVERSION;
            if (strategyPart < 300) return STRATEGY_ID_BREAKOUT;
            if (strategyPart < 400) return STRATEGY_ID_SHALLOW_PULLBACK;
            if (strategyPart < 500) return STRATEGY_ID_RANGE_TRADING;
        }
        return STRATEGY_ID_UNDEFINED;
    }

    //+------------------------------------------------------------------+
    //| Các hàm Getters để các module khác truy cập thông tin            |
    //+------------------------------------------------------------------+
    const AssetProfileData* GetAssetProfile() const { return &m_assetProfile; }
    double GetVolatilityScore() const { return m_volatilityScore; }
    double GetTrendScore() const { return m_trendScore; }
    double GetMomentumScore() const { return m_momentumScore; }
    double GetRegimeScore() const { return m_regimeScore; }

    // Lấy hiệu suất của một chiến lược cụ thể
    bool GetStrategyPerformance(ENUM_TRADING_STRATEGY strategy, StrategyPerformance &perf_out) {
        int index = (int)strategy;
        if(index >= 0 && index < ArraySize(m_strategyStats)) {
            perf_out = m_strategyStats[index];
            return true;
        }
        return false;
    }

    //+------------------------------------------------------------------+
    //| Lấy Enum chiến lược tối ưu dựa trên phân tích                    |
    //+------------------------------------------------------------------+
    ENUM_TRADING_STRATEGY GetOptimalStrategyEnum() {
        if (m_logger != NULL && m_logger->IsDebugEnabled()) {
            m_logger->LogDebug("GetOptimalStrategyEnum: Determining optimal strategy...");
        }

        double bestScore = -1.0;
        ENUM_TRADING_STRATEGY bestStrategy = STRATEGY_UNDEFINED;

        for(int i = 0; i < ArraySize(m_strategyStats); i++) {
            StrategyPerformance perf = m_strategyStats[i];
            if(perf.totalTrades < m_context->MinTradesForStats) continue;

            // Tính điểm phù hợp của chiến lược với thị trường hiện tại
            double marketFitScore = GetMarketSuitabilityScore(perf.strategy);

            // Tính điểm hiệu suất lịch sử (ví dụ: kết hợp PF và WinRate)
            double performanceScore = (perf.profitFactor * 0.6) + (perf.avgWinRate/100.0 * 0.4);
            performanceScore = MathHelper::Normalize(performanceScore, 0.5, 5.0); // Chuẩn hóa

            // Điểm cuối cùng = Hiệu suất * Phù hợp thị trường
            double finalScore = performanceScore * marketFitScore;

            if (m_logger != NULL && m_context->EnableStrategyPerformanceLogging) {
                 m_logger->LogInfo(StringFormat("Strategy [%s]: MarketFit=%.2f, PerfScore=%.2f, FinalScore=%.2f",
                    EnumToString(perf.strategy), marketFitScore, performanceScore, finalScore));
            }

            if(finalScore > bestScore) {
                bestScore = finalScore;
                bestStrategy = perf.strategy;
            }
        }
        
        if (m_logger != NULL && m_logger->IsDebugEnabled()) {
            m_logger->LogDebug("GetOptimalStrategyEnum: Optimal strategy found: " + EnumToString(bestStrategy));
        }

        return bestStrategy;
    }

    //+------------------------------------------------------------------+
    //| Thực hiện Cross-Validation cho một chiến lược cụ thể             |
    //+------------------------------------------------------------------+
    CrossValidationResult PerformCrossValidation(ENUM_TRADING_STRATEGY strategy, int folds = 5) {
        CrossValidationResult cvResult;
        if (m_tradeHistory.Total() < folds * 2) {
            if(m_logger != NULL) m_logger->LogWarning("Not enough data for Cross-Validation.");
            return cvResult;
        }

        CArrayObj foldResults;
        int foldSize = m_tradeHistory.Total() / folds;

        for (int k = 0; k < folds; k++) {
            // Logic để chia dữ liệu thành training/testing sets
            // Đây là một ví dụ đơn giản, thực tế cần phức tạp hơn
            // Ví dụ: Fold k là test set, còn lại là train set
            // ... (Phần này cần được cài đặt chi tiết)
        }

        // Sau khi có kết quả từ các fold, tính toán các chỉ số
        // ... (Tính toán avg, variance)
        cvResult.stabilityIndex = CalculateStabilityIndex(cvResult);
        return cvResult;
    }

    //+------------------------------------------------------------------+
    //| Tính chỉ số ổn định từ kết quả Cross-Validation                  |
    //+------------------------------------------------------------------+
    double CalculateStabilityIndex(const CrossValidationResult &cvResult) {
        if (cvResult.validFolds == 0) return 0.0;
        // Công thức ví dụ:
        double normalizedWinRateVariance = cvResult.winRateVariance / (cvResult.avgWinRate > 0 ? cvResult.avgWinRate : 1.0);
        double normalizedPfVariance = cvResult.profitFactorVariance / (cvResult.avgProfitFactor > 0 ? cvResult.avgProfitFactor : 1.0);
        double instability = (normalizedWinRateVariance + normalizedPfVariance) / 2.0;
        return fmax(0.0, 1.0 - instability);
    }

    //+------------------------------------------------------------------+
    //| Ghi log tóm tắt hiệu suất                                        |
    //+------------------------------------------------------------------+
    void LogPerformanceSummary() {
        if (m_logger == NULL || !m_context->EnableStrategyPerformanceLogging) return;

        m_logger->LogInfo("--- AssetDNA Performance Summary for " + m_symbol + " ---");
        for (int i = 0; i < ArraySize(m_strategyStats); i++) {
            StrategyPerformance perf = m_strategyStats[i];
            if (perf.totalTrades > 0) {
                m_logger->LogInfo(StringFormat("Strategy [%s]: Trades=%d, WinRate=%.2f%%, PF=%.2f, Expectancy=%.2f",
                    EnumToString(perf.strategy),
                    perf.totalTrades,
                    perf.avgWinRate,
                    perf.profitFactor,
                    perf.expectancy));
            }
        }
        m_logger->LogInfo("---------------------------------------------------");
    }

    //+------------------------------------------------------------------+
    //| Lấy hiệu suất lịch sử của một chiến lược cụ thể (dùng cho RiskManager) |
    //+------------------------------------------------------------------+
    bool GetHistoricalPerformance(ENUM_TRADING_STRATEGY strategy, double &winRate, double &profitFactor) {
        int index = (int)strategy;
        if (index >= 0 && index < ArraySize(m_strategyStats) && m_strategyStats[index].totalTrades > 0) {
            winRate = m_strategyStats[index].avgWinRate;
            profitFactor = m_strategyStats[index].profitFactor;
            return true;
        }
        winRate = 0.0;
        profitFactor = 0.0;
        return false;
    }

    //+------------------------------------------------------------------+
    //| Tính điểm phù hợp của chiến lược với thị trường hiện tại         |
    //+------------------------------------------------------------------+
    double GetMarketSuitabilityScore(ENUM_TRADING_STRATEGY strategy) {
        // Đây là logic cốt lõi, quyết định EA sẽ thông minh đến đâu
        // Ví dụ đơn giản:
        switch(strategy) {
            case STRATEGY_PULLBACK_TREND:
            case STRATEGY_SHALLOW_PULLBACK:
                return m_trendScore; // Càng có trend càng tốt

            case STRATEGY_MEAN_REVERSION:
                return 1.0 - m_trendScore; // Càng không có trend càng tốt

            case STRATEGY_MOMENTUM_BREAKOUT:
                return m_volatilityScore * m_momentumScore; // Cần cả biến động và động lượng

            case STRATEGY_RANGE_TRADING:
                return (1.0 - m_trendScore) * (1.0 - m_volatilityScore); // Không trend, không biến động

            default:
                return 0.0;
        }
    }

}; // Kết thúc class CAssetDNA

} // KẾT THÚC NAMESPACE ApexPullback

#endif // ASSETDNA_MQH_
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

            if(m_logger != NULL && m_logger->IsDebugEnabled()){
                 m_logger->LogDebug(StringFormat("Strategy: %s, Trades: %d, Wins: %d, WinRate: %.2f%%, PF: %.2f, Expectancy: %.2f",
                                    EnumToString(m_strategyStats[i].strategy),
                                    m_strategyStats[i].totalTrades,
                                    m_strategyStats[i].winningTrades,
                                    m_strategyStats[i].avgWinRate,
                                    m_strategyStats[i].profitFactor,
                                    m_strategyStats[i].expectancy));
            }
        }
        if(m_logger) m_logger->LogInfo("AssetDNA: Strategy performance analysis complete.");
    }
    
    //+------------------------------------------------------------------+
    //| Lấy chiến lược giao dịch tối ưu (có xem xét hiệu suất)          |
    //+------------------------------------------------------------------+
    //+------------------------------------------------------------------+
    //| Hàm chính: Chọn chiến lược tối ưu và tạo cấu hình hoàn chỉnh     |
    //| Input: Nhận thông tin từ MarketProfile (Trend, Volatility...)     |
    //| Processing: Tính điểm phù hợp thị trường + điểm hiệu suất quá khứ |
    //| Output: Trả về StrategyConfiguration hoàn chỉnh đã được tinh chỉnh|
    //+------------------------------------------------------------------+
    StrategyConfiguration GetOptimalStrategyConfiguration(MarketProfileDataStruct& currentProfile) {
        StrategyConfiguration config;
        
        // Gọi phương thức cũ để lấy chiến lược tối ưu
        ENUM_TRADING_STRATEGY optimalStrategy = GetOptimalStrategyEnum(currentProfile);
        config.strategyType = ConvertToStrategyType(optimalStrategy);
        
        // Tinh chỉnh cấu hình dựa trên điều kiện thị trường hiện tại
        OptimizeConfigurationForMarket(config, currentProfile);
        
        // Áp dụng cross-validation để điều chỉnh tham số
        ApplyCrossValidationOptimization(config);
        
        if(m_logger) {
            m_logger->LogInfo(StringFormat("AssetDNA: Cấu hình hoàn chỉnh cho %s - Entry: %.3f, Risk: %.2f%%, SL: %.1fx, TP: %.1fx",
                           EnumToString(config.strategyType), config.entryThreshold, config.maxRiskPerTrade, 
                           config.stopLossMultiplier, config.takeProfitMultiplier));
        }
        
        return config;
    }
    
    //+------------------------------------------------------------------+
    //| Phương thức cũ để tương thích ngược                              |
    //+------------------------------------------------------------------+
    ENUM_TRADING_STRATEGY GetOptimalStrategy(MarketProfileDataStruct& currentProfile) {
        return GetOptimalStrategyEnum(currentProfile);
    }
    
    //+------------------------------------------------------------------+
    //| Hàm chính: Chọn chiến lược tối ưu dựa trên hệ thống tính điểm    |
    //| Input: Nhận thông tin từ MarketProfile (Trend, Volatility...)     |
    //| Processing: Tính điểm phù hợp thị trường + điểm hiệu suất quá khứ |
    //| Output: Trả về chiến lược có điểm tổng hợp cao nhất               |
    //+------------------------------------------------------------------+
    ENUM_TRADING_STRATEGY GetOptimalStrategyEnum(MarketProfileDataStruct& currentProfile) {
        if(m_logger) m_logger->LogDebug("AssetDNA: Bắt đầu phân tích chiến lược tối ưu...");
        
        ENUM_TRADING_STRATEGY bestStrategy = STRATEGY_UNDEFINED;
        double highestCompositeScore = -1.0;
        
        // Danh sách các chiến lược khả dụng
        ENUM_TRADING_STRATEGY availableStrategies[];
        ArrayResize(availableStrategies, 5);
        availableStrategies[0] = STRATEGY_PULLBACK_TREND;
        availableStrategies[1] = STRATEGY_MEAN_REVERSION;
        availableStrategies[2] = STRATEGY_MOMENTUM_BREAKOUT;
        availableStrategies[3] = STRATEGY_SHALLOW_PULLBACK;
        availableStrategies[4] = STRATEGY_RANGE_TRADING;
        
        // Lấy trọng số từ tham số đầu vào
        double marketWeightA = m_context->MarketSuitabilityWeight;
        double performanceWeightB = m_context->PastPerformanceWeight;
        
        // Xử lý Cold Start: Điều chỉnh trọng số nếu thiếu dữ liệu lịch sử
        if(m_context->EnableColdStartAdaptation) {
            int totalHistoricalTrades = GetTotalHistoricalTrades();
            if(totalHistoricalTrades < m_context->MinTradesForPerformance) {
                marketWeightA = 1.0;
                performanceWeightB = 0.0;
                if(m_logger != NULL && m_context->EnableColdStartLogging) {
                    m_logger->LogWarning(StringFormat("AssetDNA: Cold Start - Chỉ có %d giao dịch lịch sử (cần tối thiểu %d). Chuyển sang 100%% Market Analysis. Decay Factor: %.3f",
                                       totalHistoricalTrades, m_context->MinTradesForPerformance, m_context->RecentTradeDecayFactor));
                }
            } else {
                if(m_logger != NULL && m_context->EnableColdStartLogging) {
                    m_logger->LogInfo(StringFormat("AssetDNA: Đủ dữ liệu lịch sử (%d giao dịch). Sử dụng trọng số chuẩn. Decay Factor: %.3f",
                                     totalHistoricalTrades, m_context->RecentTradeDecayFactor));
                }
            }
        }
        
        if(m_logger) {
            m_logger->LogDebug(StringFormat("AssetDNA: Trọng số - Thị trường: %.2f, Hiệu suất: %.2f", 
                             marketWeightA, performanceWeightB));
        }
        
        // Lặp qua từng chiến lược để tính điểm
        for(int i = 0; i < ArraySize(availableStrategies); i++) {
            ENUM_TRADING_STRATEGY strategy = availableStrategies[i];
            
            // BƯỚC 1: Tính "Điểm phù hợp thị trường" (0.0 - 1.0)
            double marketSuitabilityScore = CalculateMarketSuitabilityScore(strategy, currentProfile);
            
            // BƯỚC 2: Tính "Điểm hiệu suất quá khứ" (0.0 - 1.0)
            double pastPerformanceScore = CalculatePastPerformanceScore(strategy);
            
            // BƯỚC 3: Tính "Điểm tổng hợp"
            double compositeScore = (marketSuitabilityScore * marketWeightA) + (pastPerformanceScore * performanceWeightB);
            
            // Log chi tiết cho debugging
            if(m_logger != NULL) {
                m_logger->LogDebug(StringFormat("AssetDNA: %s - Market: %.3f, Performance: %.3f, Composite: %.3f",
                                 EnumToString(strategy), marketSuitabilityScore, pastPerformanceScore, compositeScore));
            }
            
            // Cập nhật chiến lược tốt nhất
            if(compositeScore > highestCompositeScore) {
                highestCompositeScore = compositeScore;
                bestStrategy = strategy;
            }
        }
        
        // Log kết quả cuối cùng
        if(m_logger != NULL) {
            if(bestStrategy != STRATEGY_UNDEFINED) {
                m_logger->LogInfo(StringFormat("AssetDNA: Chiến lược tối ưu: %s (Điểm: %.3f)",
                               EnumToString(bestStrategy), highestCompositeScore));
            } else {
                m_logger->LogWarning("AssetDNA: Không tìm thấy chiến lược phù hợp!");
            }
        }
        
        return bestStrategy;
    }
    
    //+------------------------------------------------------------------+
    //| Tính điểm phù hợp thị trường cho từng chiến lược                 |
    //| Dựa trên dữ liệu MarketProfile: Trend, Volatility, Momentum...    |
    //+------------------------------------------------------------------+
    double CalculateMarketSuitabilityScore(ENUM_TRADING_STRATEGY strategy, MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        switch(strategy) {
            case STRATEGY_PULLBACK_TREND:
                // Pullback cần: Xu hướng rõ ràng + Momentum tốt + Không quá volatile
                if(m_trendScore > m_context->TrendScoreThreshold) score += 0.4;  // Xu hướng mạnh
                if(m_momentumScore > m_context->MomentumScoreThreshold) score += 0.3;  // Momentum tốt
                if(m_volatilityScore < m_context->VolatilityScoreThreshold) score += 0.2;  // Không quá biến động
                if(profile.TrendStrength > 0.65) score += 0.1;  // Bonus cho trend strength cao
                break;
                
            case STRATEGY_MEAN_REVERSION:
                // Mean Reversion cần: Thị trường sideway + Volatility cao + Oversold/Overbought
                if(m_regimeScore < m_context->MeanReversionRegimeThreshold) score += 0.3;  // Thị trường không trending
                if(m_volatilityScore > m_context->MeanReversionVolatilityThreshold) score += 0.3;  // Volatility cao
                if(profile.RSIValue < 30 || profile.RSIValue > 70) score += 0.3;  // Oversold/Overbought
                if(profile.IsSidewaysOrChoppy) score += 0.1;  // Bonus cho sideway market
                break;
                
            case STRATEGY_MOMENTUM_BREAKOUT:
                // Breakout cần: Momentum cao + Volume lớn + Volatility tăng
                if(m_momentumScore > m_context->BreakoutMomentumThreshold) score += 0.4;  // Momentum rất mạnh
                if(profile.VolumeScore > m_context->BreakoutVolumeThreshold) score += 0.3;  // Volume cao
                if(m_volatilityScore > 0.6) score += 0.2;  // Volatility cao
                if(profile.MACDHistogram > 0) score += 0.1;  // MACD tích cực
                break;
                
            case STRATEGY_SHALLOW_PULLBACK:
                // Shallow Pullback cần: Xu hướng rất mạnh + Momentum ổn định
                if(m_trendScore > m_context->ShallowPullbackTrendThreshold) score += 0.5;  // Xu hướng rất mạnh
                if(m_momentumScore > 0.6) score += 0.3;  // Momentum tốt
                if(profile.TrendStrength > 0.8) score += 0.2;  // Trend strength rất cao
                break;
                
            case STRATEGY_RANGE_TRADING:
                // Range Trading cần: Thị trường sideway + Volatility thấp + Volume ổn định
                if(m_trendScore < m_context->RangeTradingTrendThreshold) score += 0.3;  // Không có xu hướng rõ ràng
                if(m_volatilityScore < m_context->RangeTradingVolatilityThreshold) score += 0.3;  // Volatility thấp
                if(profile.IsSidewaysOrChoppy) score += 0.3;  // Thị trường sideway
                if(MathAbs(profile.VolumeScore - 0.5) < 0.2) score += 0.1;  // Volume ổn định
                break;
                
            default:
                score = 0.0;
                break;
        }
        
        // Đảm bảo điểm trong khoảng [0.0, 1.0]
        return MathMax(0.0, MathMin(1.0, score));
    }
    
    //+------------------------------------------------------------------+
    //| Tính điểm hiệu suất quá khứ cho từng chiến lược                  |
    //| Dựa trên winrate, profit factor từ lịch sử giao dịch             |
    //| V14.1: Thêm regularization và cross-validation để giảm overfitting|
    //+------------------------------------------------------------------+
    double CalculatePastPerformanceScore(ENUM_TRADING_STRATEGY strategy) {
        double score = m_context->ColdStartDefaultScore;  // Điểm mặc định từ tham số
        
        // Tìm thống kê hiệu suất cho chiến lược này
        StrategyPerformance* perf = GetStrategyPerformanceEntry(strategy);
        
        if(perf != NULL && perf.totalTrades >= m_context->MinTradesForPerformance) {  // Sử dụng tham số
            // ANTI-OVERFITTING: Áp dụng regularization dựa trên số lượng giao dịch
            double regularizationFactor = CalculateRegularizationFactor(perf.totalTrades);
            
            // CROSS-VALIDATION: Chia dữ liệu thành train/test sets
            CrossValidationResult cvResult = PerformCrossValidation(strategy, perf);
            
            double winRateScore = 0.0;
            double profitFactorScore = 0.0;
            double expectancyScore = 0.0;
            double stabilityScore = 0.0;
            
            // Sử dụng kết quả cross-validation thay vì toàn bộ dữ liệu
            double adjustedWinRate = cvResult.avgWinRate * regularizationFactor;
            double adjustedProfitFactor = cvResult.avgProfitFactor * regularizationFactor;
            double adjustedExpectancy = cvResult.avgExpectancy * regularizationFactor;
            
            // Tính điểm Win Rate với regularization (0.0 - 0.3)
            if(adjustedWinRate >= 55.0) winRateScore = 0.3;
            else if(adjustedWinRate >= 45.0) winRateScore = 0.25;
            else if(adjustedWinRate >= 35.0) winRateScore = 0.15;
            else if(adjustedWinRate >= 25.0) winRateScore = 0.05;
            
            // Tính điểm Profit Factor với regularization (0.0 - 0.3)
            if(adjustedProfitFactor >= 1.8) profitFactorScore = 0.3;
            else if(adjustedProfitFactor >= 1.4) profitFactorScore = 0.25;
            else if(adjustedProfitFactor >= 1.15) profitFactorScore = 0.15;
            else if(adjustedProfitFactor >= 1.0) profitFactorScore = 0.05;
            
            // Tính điểm Expectancy với regularization (0.0 - 0.2)
            if(adjustedExpectancy >= 0.15) expectancyScore = 0.2;
            else if(adjustedExpectancy >= 0.08) expectancyScore = 0.15;
            else if(adjustedExpectancy >= 0.03) expectancyScore = 0.1;
            else if(adjustedExpectancy >= 0.0) expectancyScore = 0.05;
            
            // STABILITY SCORE: Đánh giá tính ổn định của chiến lược (0.0 - 0.2)
            stabilityScore = CalculateStabilityScore(cvResult);
            
            // Tổng hợp điểm hiệu suất với trọng số cân bằng
            score = winRateScore + profitFactorScore + expectancyScore + stabilityScore;
            
            // Penalty cho overfitting: Giảm điểm nếu variance quá cao
            double overfittingPenalty = CalculateOverfittingPenalty(cvResult);
            score = MathMax(0.0, score - overfittingPenalty);
            
            if(m_logger && m_context->EnableStrategyPerformanceLogging) {
                m_logger.LogDebug(StringFormat("AssetDNA: %s Performance (CV) - WR: %.1f%% (%.1f%%), PF: %.2f (%.2f), Exp: %.3f (%.3f), Stability: %.3f, Trades: %d",
                                 EnumToString(strategy), adjustedWinRate, perf.avgWinRate, adjustedProfitFactor, perf.profitFactor, 
                                 adjustedExpectancy, perf.expectancy, stabilityScore, perf.totalTrades));
            }
            
            // Log chi tiết điểm số nếu được bật
            if(m_logger && m_context->EnableDetailedScoreLogging) {
                m_logger.LogDebug(StringFormat("AssetDNA: %s Score Breakdown - WR: %.3f, PF: %.3f, Exp: %.3f, Stability: %.3f, Penalty: %.3f, Total: %.3f",
                                 EnumToString(strategy), winRateScore, profitFactorScore, expectancyScore, 
                                 stabilityScore, overfittingPenalty, score));
            }
        } else {
            if(m_logger && m_context->EnableColdStartLogging) {
                m_logger.LogWarning(StringFormat("AssetDNA: %s - Không đủ dữ liệu lịch sử (Trades: %d < %d). Sử dụng điểm mặc định: %.3f",
                                   EnumToString(strategy), perf ? perf.totalTrades : 0, 
                                   m_context->MinTradesForPerformance, score));
            }
        }
        
        // Đảm bảo điểm trong khoảng [0.0, 1.0]
        return MathMax(0.0, MathMin(1.0, score));
    }
    
    //+------------------------------------------------------------------+
    //| Các phương thức tính điểm cho từng chiến lược                     |
    //+------------------------------------------------------------------+
    double CalculatePullbackScore(MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược pullback theo xu hướng
        score += profile.trendScore * 2.0;
        score += (profile.recentSwingLow - profile.ema89) / profile.atrValue * 1.5; // Độ sâu pullback
        score += (profile.recentSwingLow - profile.ema89) / profile.atrValue > 0.3 ? 1.0 : 0.0;
        score += profile.macdHistogram * 1.0; // Momentum score

        // Thêm logic tự học nếu được bật và có đủ dữ liệu
        // Self-learning feature disabled - using fixed strategy weights
        {
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
    
    double CalculateBreakoutScore(MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược momentum breakout
        score += profile.volumeRatio > 1.2 ? 2.0 : 0.0; // Tích lũy khối lượng
        score += profile.volumeRatio * 1.5; // Điểm khối lượng
        score += profile.volatilityRatio * 1.0; // Tỷ lệ biến động

        // Thêm logic tự học
        // Self-learning feature disabled - using fixed strategy weights
        {
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
    
    double CalculateMeanReversionScore(MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược mean reversion
        score += (profile.rsiValue < 30 || profile.rsiValue > 70) ? 2.0 : 0.0; // Quá mua/bán
        score += profile.isSidewaysOrChoppy ? 1.5 : 0.0; // Thị trường sideway
        score += MathAbs((profile.ema34 - profile.ema200) / profile.atrValue) * 1.0; // Độ lệch từ trung bình

        // Thêm logic tự học
        // Self-learning feature disabled - using fixed strategy weights
        {
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
    
    double CalculateTrendFollowingScore(MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        // Kiểm tra xu hướng mạnh
        if(profile.TrendStrength > 0.7) score += 0.4; // Sử dụng tên thành viên đúng
        
        // Kiểm tra momentum
        if(profile.MomentumScore > 0.6) score += 0.3; // Sử dụng tên thành viên đúng
        
        // Kiểm tra volume
        if(profile.VolumeScore > 0.6) score += 0.3; // Sử dụng tên thành viên đúng

        // Thêm logic tự học (cho STRATEGY_SHALLOW_PULLBACK)
        // Self-learning feature disabled - using fixed strategy weights
        {
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
    
    double CalculateRangeScore(MarketProfileDataStruct& profile) {
        double score = 0.0;
        
        // Tính điểm cho chiến lược range trading
        score += m_context->MarketProfile.isSidewaysOrChoppy ? 2.0 : 0.0; // Thị trường sideway
        score += m_context->MarketProfile.volatilityRatio * 1.5; // Tỷ lệ biến động
        score += (1.0 - MathAbs(m_context->MarketProfile.volumeRatio - 1.0)) * 1.0; // Độ ổn định khối lượng

        // Thêm logic tự học
        // Self-learning feature disabled - using fixed strategy weights
        {
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
    //| Lấy con trỏ đến thống kê hiệu suất của một chiến lược            |
    //+------------------------------------------------------------------+
    StrategyPerformance* GetStrategyPerformanceEntry(ENUM_TRADING_STRATEGY strategy) {
        for(int i = 0; i < ArraySize(m_strategyStats); i++) {
            if(m_strategyStats[i].strategy == strategy) {
                return &m_strategyStats[i];
            }
        }
        return NULL;  // Không tìm thấy
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
    //| Tính Z-score cho volume để đánh giá sự bất thường                |
    //+------------------------------------------------------------------+
    double CalculateVolumeZScore(int period = 20) {
        if(period <= 0) return 0.0;
        
        // Lấy dữ liệu volume
        double volumes[];
        ArrayResize(volumes, period + 1);
        
        for(int i = 0; i <= period; i++) {
            volumes[i] = (double)iVolume(m_symbol, m_timeframe, i);
        }
        
        // Tính mean và standard deviation của volume
        double mean = 0.0;
        for(int i = 1; i <= period; i++) { // Bỏ qua volume hiện tại (index 0)
            mean += volumes[i];
        }
        mean /= period;
        
        double variance = 0.0;
        for(int i = 1; i <= period; i++) {
            double diff = volumes[i] - mean;
            variance += diff * diff;
        }
        double stdDev = MathSqrt(variance / period);
        
        // Tính Z-score cho volume hiện tại
        if(stdDev > 0) {
            return (volumes[0] - mean) / stdDev;
        }
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Tính độ dốc momentum bằng linear regression                      |
    //+------------------------------------------------------------------+
    double CalculateMomentumSlope(int period = 14) {
        if(period <= 0) return 0.0;
        
        // Lấy dữ liệu RSI
        double rsiValues[];
        ArrayResize(rsiValues, period);
        
        for(int i = 0; i < period; i++) {
            rsiValues[i] = iRSI(m_symbol, m_timeframe, 14, PRICE_CLOSE, i);
        }
        
        // Tạo mảng X (thời gian)
        double xValues[];
        ArrayResize(xValues, period);
        for(int i = 0; i < period; i++) {
            xValues[i] = (double)i;
        }
        
        // Tính linear regression slope
        return m_context->MathHelper->LinearRegressionSlope(rsiValues, xValues, 0, period);
    }
    
    //+------------------------------------------------------------------+
    //| Cải thiện Cross-Validation với bootstrap sampling               |
    //+------------------------------------------------------------------+
    CrossValidationResult PerformEnhancedCrossValidation(ENUM_TRADING_STRATEGY strategy, StrategyPerformance* perf, int folds = 5, int bootstrapSamples = 100) {
        CrossValidationResult result;
        result.Clear();
        
        if(perf == NULL || perf->totalTrades < 10) {
            return result;
        }
        
        // Lấy trades cho strategy này
        CArrayObj tradesForStrategy;
        for(int i = 0; i < m_tradeHistory.Total(); i++) {
            TradeRecord* trade = (TradeRecord*)m_tradeHistory.At(i);
            if(trade != NULL && trade->scenario == strategy) {
                tradesForStrategy.Add(trade);
            }
        }
        
        if(tradesForStrategy.Total() < 10) {
            return result;
        }
        
        // Thực hiện K-Fold Cross Validation
        double winRates[];
        double profitFactors[];
        double expectancies[];
        ArrayResize(winRates, folds);
        ArrayResize(profitFactors, folds);
        ArrayResize(expectancies, folds);
        
        int tradesPerFold = tradesForStrategy.Total() / folds;
        int validFolds = 0;
        
        for(int fold = 0; fold < folds; fold++) {
            int startIdx = fold * tradesPerFold;
            int endIdx = (fold == folds - 1) ? tradesForStrategy.Total() - 1 : (fold + 1) * tradesPerFold - 1;
            
            if(endIdx - startIdx < 5) continue; // Cần ít nhất 5 trades cho mỗi fold
            
            // Tính metrics cho fold này
            int wins = 0;
            double totalProfit = 0.0;
            double totalLoss = 0.0;
            int totalTrades = endIdx - startIdx + 1;
            
            for(int i = startIdx; i <= endIdx; i++) {
                TradeRecord* trade = (TradeRecord*)tradesForStrategy.At(i);
                if(trade != NULL) {
                    if(trade->profit > 0) {
                        wins++;
                        totalProfit += trade->profit;
                    } else {
                        totalLoss += MathAbs(trade->profit);
                    }
                }
            }
            
            winRates[validFolds] = (double)wins / totalTrades * 100.0;
            profitFactors[validFolds] = (totalLoss > 0) ? totalProfit / totalLoss : (totalProfit > 0 ? 999.0 : 0.0);
            expectancies[validFolds] = (totalProfit - totalLoss) / totalTrades;
            validFolds++;
        }
        
        if(validFolds == 0) {
            return result;
        }
        
        // Tính trung bình và phương sai
        result.validFolds = validFolds;
        
        // Tính trung bình
        for(int i = 0; i < validFolds; i++) {
            result.avgWinRate += winRates[i];
            result.avgProfitFactor += profitFactors[i];
            result.avgExpectancy += expectancies[i];
        }
        result.avgWinRate /= validFolds;
        result.avgProfitFactor /= validFolds;
        result.avgExpectancy /= validFolds;
        
        // Tính phương sai
        for(int i = 0; i < validFolds; i++) {
            double wrDiff = winRates[i] - result.avgWinRate;
            double pfDiff = profitFactors[i] - result.avgProfitFactor;
            double expDiff = expectancies[i] - result.avgExpectancy;
            
            result.winRateVariance += wrDiff * wrDiff;
            result.profitFactorVariance += pfDiff * pfDiff;
            result.expectancyVariance += expDiff * expDiff;
        }
        result.winRateVariance /= validFolds;
        result.profitFactorVariance /= validFolds;
        result.expectancyVariance /= validFolds;
        
        // Tính stability index (0-1, càng cao càng ổn định)
        double avgVariance = (result.winRateVariance / 10000.0 + result.profitFactorVariance / 100.0 + result.expectancyVariance) / 3.0;
        result.stabilityIndex = MathMax(0.0, 1.0 - avgVariance);
        
        return result;
    }
    
    //+------------------------------------------------------------------+
    //| Phương thức PerformEnhancedCrossValidation với signature mới     |
    //+------------------------------------------------------------------+
    bool PerformEnhancedCrossValidation(ENUM_TRADING_STRATEGY strategy, int folds,
                                       double &avgWinRate, double &avgProfitFactor, double &avgExpectancy,
                                       double &winRateVariance, double &profitFactorVariance, double &expectancyVariance) {
        // Khởi tạo các giá trị output
        avgWinRate = 0.0;
        avgProfitFactor = 0.0;
        avgExpectancy = 0.0;
        winRateVariance = 0.0;
        profitFactorVariance = 0.0;
        expectancyVariance = 0.0;
        
        // Lấy trades cho strategy này
        CArrayObj* tradesForStrategy = GetTradesForStrategy(strategy);
        if(tradesForStrategy == NULL || tradesForStrategy.Total() < 10) {
            if(tradesForStrategy != NULL) delete tradesForStrategy;
            return false;
        }
        
        // Thực hiện K-Fold Cross Validation
        double winRates[];
        double profitFactors[];
        double expectancies[];
        ArrayResize(winRates, folds);
        ArrayResize(profitFactors, folds);
        ArrayResize(expectancies, folds);
        
        int tradesPerFold = tradesForStrategy.Total() / folds;
        int validFolds = 0;
        
        for(int fold = 0; fold < folds; fold++) {
            int startIdx = fold * tradesPerFold;
            int endIdx = (fold == folds - 1) ? tradesForStrategy.Total() - 1 : (fold + 1) * tradesPerFold - 1;
            
            if(endIdx - startIdx < 5) continue; // Cần ít nhất 5 trades cho mỗi fold
            
            double foldWinRate, foldProfitFactor, foldExpectancy;
            if(CalculateFoldMetrics(tradesForStrategy, startIdx, endIdx + 1, foldWinRate, foldProfitFactor, foldExpectancy)) {
                winRates[validFolds] = foldWinRate;
                profitFactors[validFolds] = foldProfitFactor;
                expectancies[validFolds] = foldExpectancy;
                validFolds++;
            }
        }
        
        delete tradesForStrategy;
        
        if(validFolds == 0) {
            return false;
        }
        
        // Tính trung bình
        for(int i = 0; i < validFolds; i++) {
            avgWinRate += winRates[i];
            avgProfitFactor += profitFactors[i];
            avgExpectancy += expectancies[i];
        }
        avgWinRate /= validFolds;
        avgProfitFactor /= validFolds;
        avgExpectancy /= validFolds;
        
        // Tính phương sai
        for(int i = 0; i < validFolds; i++) {
            double wrDiff = winRates[i] - avgWinRate;
            double pfDiff = profitFactors[i] - avgProfitFactor;
            double expDiff = expectancies[i] - avgExpectancy;
            
            winRateVariance += wrDiff * wrDiff;
            profitFactorVariance += pfDiff * pfDiff;
            expectancyVariance += expDiff * expDiff;
        }
        winRateVariance /= validFolds;
        profitFactorVariance /= validFolds;
        expectancyVariance /= validFolds;
        
        if(m_logger) {
            m_logger->LogDebug(StringFormat("AssetDNA: Cross-validation completed for %s - %d folds, WR: %.1f%% (var: %.3f), PF: %.2f (var: %.3f)",
                             EnumToString(strategy), validFolds, avgWinRate, winRateVariance, avgProfitFactor, profitFactorVariance));
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Tính điểm strategy với các phương pháp định lượng nâng cao      |
    //+------------------------------------------------------------------+
    double CalculateQuantitativeStrategyScore(ENUM_TRADING_STRATEGY strategy) {
        double baseScore = CalculatePastPerformanceScore(strategy);
        
        // Thêm điểm từ volume analysis
        double volumeZScore = CalculateVolumeZScore(20);
        double volumeBonus = 0.0;
        if(MathAbs(volumeZScore) > 2.0) { // Volume bất thường
            volumeBonus = (strategy == STRATEGY_MOMENTUM_BREAKOUT) ? 0.1 : -0.05;
        }
        
        // Thêm điểm từ momentum slope
        double momentumSlope = CalculateMomentumSlope(14);
        double momentumBonus = 0.0;
        if(strategy == STRATEGY_PULLBACK_TREND || strategy == STRATEGY_MOMENTUM_BREAKOUT) {
            if(MathAbs(momentumSlope) > 1.0) { // Momentum mạnh
                momentumBonus = 0.1;
            }
        } else if(strategy == STRATEGY_MEAN_REVERSION) {
            if(MathAbs(momentumSlope) < 0.5) { // Momentum yếu
                momentumBonus = 0.1;
            }
        }
        
        // Cross-validation penalty
        StrategyPerformance* perf = GetStrategyPerformance(strategy);
        double stabilityPenalty = 0.0;
        if(perf != NULL && perf->totalTrades > 10) {
            CrossValidationResult cvResult = PerformEnhancedCrossValidation(strategy, perf);
            if(cvResult.stabilityIndex < 0.7) {
                stabilityPenalty = (0.7 - cvResult.stabilityIndex) * 0.2; // Phạt tối đa 0.2 điểm
            }
        }
        
        return MathMax(0.0, MathMin(1.0, baseScore + volumeBonus + momentumBonus - stabilityPenalty));
    }
    
    //+------------------------------------------------------------------+
    //| Các phương thức truy xuất thông tin                               |
    //+------------------------------------------------------------------+
    double GetRecommendedRisk() const {
        return m_assetProfile.recommendedRiskPercent;
    }
    
    double GetOptimalRR() const {
        return m_assetProfile.optimalRRRatio;
    }
    
    double GetOptimalSLAtrMultiplier() const {
        return m_assetProfile.optimalSLATRMulti;
    }
    
    //+------------------------------------------------------------------+
    //| Đếm tổng số giao dịch lịch sử                                     |
    //+------------------------------------------------------------------+
    int GetTotalHistoricalTrades() const {
        if(m_tradeHistory == NULL) return 0;
        
        // Lọc theo thời gian nếu được cấu hình
        if(m_context->HistoryAnalysisMonths > 0) {
            datetime cutoffTime = TimeCurrent() - (m_context->HistoryAnalysisMonths * 30 * 24 * 3600);
            int recentTrades = 0;
            
            for(int i = 0; i < m_tradeHistory.Total(); i++) {
                TradeRecord* trade = (TradeRecord*)m_tradeHistory.At(i);
                if(trade != NULL && trade->timeOpen >= cutoffTime) {
                    recentTrades++;
                }
            }
            return recentTrades;
        }
        
        return m_tradeHistory.Total();
    }
    
    //+------------------------------------------------------------------+
    //| Tính trọng số decay cho giao dịch theo thời gian                  |
    //+------------------------------------------------------------------+
    double CalculateTradeDecayWeight(datetime tradeTime) {
        if(m_context->RecentTradeDecayFactor >= 1.0) return 1.0; // Không decay
        
        datetime currentTime = TimeCurrent();
        int daysDiff = (int)((currentTime - tradeTime) / (24 * 3600));
        
        // Áp dụng decay factor: weight = decayFactor^(days/30)
        // Giao dịch 30 ngày trước sẽ có trọng số = decayFactor
        double weight = MathPow(m_context->RecentTradeDecayFactor, (double)daysDiff / 30.0);
        return MathMax(0.1, weight); // Tối thiểu 10% trọng số
    }
    
    //+------------------------------------------------------------------+
    //| ANTI-OVERFITTING: Tính hệ số regularization dựa trên số giao dịch |
    //+------------------------------------------------------------------+
    double CalculateRegularizationFactor(int totalTrades) {
        // Regularization factor giảm dần khi số giao dịch ít
        // Công thức: factor = sqrt(trades / minTrades) nhưng không vượt quá 1.0
        double minTrades = MathMax(10.0, m_context->MinTradesForPerformance);
        double factor = MathSqrt((double)totalTrades / minTrades);
        return MathMin(1.0, factor);
    }
    
    //+------------------------------------------------------------------+
    //| CROSS-VALIDATION: Thực hiện k-fold cross validation               |
    //+------------------------------------------------------------------+
    CrossValidationResult PerformCrossValidation(ENUM_TRADING_STRATEGY strategy, StrategyPerformance* perf) {
        CrossValidationResult result;
        result.Clear();
        
        if(perf == NULL || perf.totalTrades < 10) {
            // Không đủ dữ liệu cho CV, trả về kết quả mặc định
            result.avgWinRate = perf ? perf.avgWinRate : 0.0;
            result.avgProfitFactor = perf ? perf.profitFactor : 0.0;
            result.avgExpectancy = perf ? perf.expectancy : 0.0;
            result.validFolds = 0;
            result.stabilityIndex = 0.0;
            return result;
        }
        
        // Lấy danh sách giao dịch cho chiến lược này
        CArrayObj* strategyTrades = GetTradesForStrategy(strategy);
        if(strategyTrades == NULL || strategyTrades.Total() < 10) {
            delete strategyTrades;
            return result;
        }
        
        int totalTrades = strategyTrades.Total();
        int kFolds = MathMin(5, totalTrades / 2); // Tối đa 5 folds, tối thiểu 2 trades/fold
        
        if(kFolds < 2) {
            delete strategyTrades;
            return result;
        }
        
        double winRates[];
        double profitFactors[];
        double expectancies[];
        ArrayResize(winRates, kFolds);
        ArrayResize(profitFactors, kFolds);
        ArrayResize(expectancies, kFolds);
        
        int validFolds = 0;
        
        // Thực hiện k-fold cross validation
        for(int fold = 0; fold < kFolds; fold++) {
            int startIdx = (totalTrades * fold) / kFolds;
            int endIdx = (totalTrades * (fold + 1)) / kFolds;
            
            // Tính metrics cho fold này
            double foldWinRate, foldProfitFactor, foldExpectancy;
            if(CalculateFoldMetrics(strategyTrades, startIdx, endIdx, foldWinRate, foldProfitFactor, foldExpectancy)) {
                winRates[validFolds] = foldWinRate;
                profitFactors[validFolds] = foldProfitFactor;
                expectancies[validFolds] = foldExpectancy;
                validFolds++;
            }
        }
        
        if(validFolds > 0) {
            // Tính trung bình và phương sai
            result.avgWinRate = CalculateArrayMean(winRates, validFolds);
            result.avgProfitFactor = CalculateArrayMean(profitFactors, validFolds);
            result.avgExpectancy = CalculateArrayMean(expectancies, validFolds);
            
            result.winRateVariance = CalculateArrayVariance(winRates, validFolds, result.avgWinRate);
            result.profitFactorVariance = CalculateArrayVariance(profitFactors, validFolds, result.avgProfitFactor);
            result.expectancyVariance = CalculateArrayVariance(expectancies, validFolds, result.avgExpectancy);
            
            result.validFolds = validFolds;
            result.stabilityIndex = CalculateStabilityIndex(result.winRateVariance, result.profitFactorVariance, result.expectancyVariance);
        }
        
        delete strategyTrades;
        return result;
    }
    
    //+------------------------------------------------------------------+
    //| Tính stability score dựa trên kết quả cross-validation            |
    //+------------------------------------------------------------------+
    double CalculateStabilityScore(CrossValidationResult &cvResult) {
        if(cvResult.validFolds < 2) return 0.0;
        
        // Stability score cao khi variance thấp
        double maxVariance = 0.1; // Ngưỡng variance tối đa
        double avgVariance = (cvResult.winRateVariance + cvResult.profitFactorVariance + cvResult.expectancyVariance) / 3.0;
        
        double stabilityScore = MathMax(0.0, 1.0 - (avgVariance / maxVariance));
        return MathMin(0.2, stabilityScore * 0.2); // Tối đa 0.2 điểm
    }
    
    //+------------------------------------------------------------------+
    //| Tính penalty cho overfitting                                      |
    //+------------------------------------------------------------------+
    double CalculateOverfittingPenalty(CrossValidationResult &cvResult) {
        if(cvResult.validFolds < 2) return 0.1; // Penalty cao nếu không có CV
        
        // Penalty cao khi variance cao (không ổn định)
        double varianceThreshold = 0.05;
        double avgVariance = (cvResult.winRateVariance + cvResult.profitFactorVariance + cvResult.expectancyVariance) / 3.0;
        
        if(avgVariance > varianceThreshold) {
            return MathMin(0.3, (avgVariance - varianceThreshold) * 2.0); // Tối đa penalty 0.3
        }
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Lấy danh sách giao dịch cho một chiến lược cụ thể                 |
    //+------------------------------------------------------------------+
    CArrayObj* GetTradesForStrategy(ENUM_TRADING_STRATEGY strategy) {
        CArrayObj* strategyTrades = new CArrayObj();
        
        if(m_tradeHistory == NULL) return strategyTrades;
        
        for(int i = 0; i < m_tradeHistory.Total(); i++) {
            TradeRecord* trade = (TradeRecord*)m_tradeHistory.At(i);
            if(trade != NULL && trade->scenario == strategy) {
                strategyTrades.Add(trade);
            }
        }
        
        return strategyTrades;
    }
    
    //+------------------------------------------------------------------+
    //| Tính metrics cho một fold trong cross-validation                  |
    //+------------------------------------------------------------------+
    bool CalculateFoldMetrics(CArrayObj* trades, int startIdx, int endIdx, 
                             double &winRate, double &profitFactor, double &expectancy) {
        if(trades == NULL || startIdx >= endIdx || endIdx > trades.Total()) return false;
        
        int totalTrades = endIdx - startIdx;
        if(totalTrades < 2) return false;
        
        int wins = 0;
        double totalProfit = 0.0;
        double totalLoss = 0.0;
        
        for(int i = startIdx; i < endIdx; i++) {
            TradeRecord* trade = (TradeRecord*)trades.At(i);
            if(trade == NULL) continue;
            
            if(trade->profit > 0) {
                wins++;
                totalProfit += trade->profit;
            } else if(trade->profit < 0) {
                totalLoss += MathAbs(trade->profit);
            }
        }
        
        winRate = (double)wins / totalTrades * 100.0;
        profitFactor = (totalLoss > 0) ? totalProfit / totalLoss : (totalProfit > 0 ? 10.0 : 1.0);
        expectancy = (totalProfit - totalLoss) / totalTrades;
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Utility functions cho statistical calculations                    |
    //+------------------------------------------------------------------+
    double CalculateArrayMean(double &array[], int size) {
        if(size <= 0) return 0.0;
        
        double sum = 0.0;
        for(int i = 0; i < size; i++) {
            sum += array[i];
        }
        return sum / size;
    }
    
    double CalculateArrayVariance(double &array[], int size, double mean) {
        if(size <= 1) return 0.0;
        
        double sumSquaredDiff = 0.0;
        for(int i = 0; i < size; i++) {
            double diff = array[i] - mean;
            sumSquaredDiff += diff * diff;
        }
        return sumSquaredDiff / (size - 1);
    }
    
    double CalculateStabilityIndex(double winRateVar, double profitFactorVar, double expectancyVar) {
        // Chỉ số ổn định dựa trên variance thấp
        double maxVar = 0.1;
        double avgVar = (winRateVar + profitFactorVar + expectancyVar) / 3.0;
        return MathMax(0.0, 1.0 - (avgVar / maxVar));
    }
    
    // Removed ConvertToStrategyType function - ENUM_STRATEGY_TYPE không tồn tại
    
    //+------------------------------------------------------------------+
    //| Tối ưu hóa cấu hình dựa trên điều kiện thị trường hiện tại       |
    //+------------------------------------------------------------------+
    void OptimizeConfigurationForMarket(StrategyConfiguration &config, ::ApexPullback::MarketProfileDataStruct& profile) {
        // Điều chỉnh dựa trên volatility
        double currentVolatility = profile.atr / profile.closePrice;
        if(currentVolatility > 0.002) { // High volatility
            config.stopLossMultiplier *= 1.2;
            config.takeProfitMultiplier *= 1.1;
            config.maxRiskPerTrade *= 0.8; // Giảm risk
            config.entryThreshold += 0.1; // Tăng threshold
        } else if(currentVolatility < 0.0005) { // Low volatility
            config.stopLossMultiplier *= 0.9;
            config.takeProfitMultiplier *= 0.95;
            config.maxRiskPerTrade *= 1.1; // Tăng risk nhẹ
            config.entryThreshold -= 0.05; // Giảm threshold
        }
        
        // Điều chỉnh dựa trên trend strength
        if(profile.TrendStrength > 0.8) { // Strong trend
            config.takeProfitMultiplier *= 1.2;
            config.trailingStopMultiplier *= 0.9;
        } else if(profile.TrendStrength < 0.3) { // Weak trend
            config.stopLossMultiplier *= 0.9;
            config.takeProfitMultiplier *= 0.9;
        }
        
        // Điều chỉnh theo chiến lược cụ thể
        switch(config.strategyType) {
            case STRATEGY_PULLBACK_TREND:
                if(m_trendScore > 0.8) {
                    config.pullbackDepth = 0.5; // Deeper pullback in strong trend
                    config.entryThreshold -= 0.05;
                }
                break;
                
            case STRATEGY_MEAN_REVERSION:
                if(currentVolatility > 0.001) {
                    config.meanReversionLevel += 0.1; // More conservative in volatile market
                }
                break;
                
            case STRATEGY_MOMENTUM_BREAKOUT:
                if(m_momentumScore > 0.7) {
                    config.momentumThreshold -= 0.1; // Lower threshold in strong momentum
                    config.takeProfitMultiplier *= 1.3;
                }
                break;
                
            case STRATEGY_RANGE_TRADING:
                if(profile.TrendStrength < 0.2) { // Very weak trend, good for ranging
                    config.rangeBreakoutLevel += 0.1;
                    config.maxRiskPerTrade *= 1.2;
                }
                break;
        }
        
        // Đảm bảo các giá trị trong giới hạn hợp lý
        config.entryThreshold = MathMax(0.3, MathMin(0.9, config.entryThreshold));
        config.maxRiskPerTrade = MathMax(0.5, MathMin(5.0, config.maxRiskPerTrade));
        config.stopLossMultiplier = MathMax(1.0, MathMin(5.0, config.stopLossMultiplier));
        config.takeProfitMultiplier = MathMax(1.0, MathMin(10.0, config.takeProfitMultiplier));
    }
    
    //+------------------------------------------------------------------+
    //| Áp dụng tối ưu hóa cross-validation cho cấu hình                 |
    //+------------------------------------------------------------------+
    void ApplyCrossValidationOptimization(StrategyConfiguration &config) {
        // Lấy kết quả cross-validation cho chiến lược này
        ENUM_TRADING_STRATEGY strategy = config.strategyType;
        
        double avgWinRate, avgProfitFactor, avgExpectancy;
        double winRateVariance, profitFactorVariance, expectancyVariance;
        
        bool hasValidation = PerformEnhancedCrossValidation(strategy, 5, // 5-fold CV
                                                           avgWinRate, avgProfitFactor, avgExpectancy,
                                                           winRateVariance, profitFactorVariance, expectancyVariance);
        
        if(!hasValidation) {
            if(m_logger) {
                m_logger->LogWarning("AssetDNA: Không đủ dữ liệu cho cross-validation, sử dụng cấu hình mặc định");
            }
            return;
        }
        
        // Điều chỉnh risk dựa trên stability
        double stabilityScore = CalculateStabilityScore(winRateVariance, profitFactorVariance, expectancyVariance);
        if(stabilityScore < 0.5) { // Low stability
            config.maxRiskPerTrade *= 0.8;
            config.entryThreshold += 0.1;
            if(m_logger) {
                m_logger->LogInfo(StringFormat("AssetDNA: Stability thấp (%.3f), giảm risk và tăng threshold", stabilityScore));
            }
        } else if(stabilityScore > 0.8) { // High stability
            config.maxRiskPerTrade *= 1.1;
            config.entryThreshold -= 0.05;
        }
        
        // Điều chỉnh take profit dựa trên profit factor
        if(avgProfitFactor > 2.0) {
            config.takeProfitMultiplier *= 1.2;
        } else if(avgProfitFactor < 1.3) {
            config.takeProfitMultiplier *= 0.9;
            config.stopLossMultiplier *= 0.95;
        }
        
        // Điều chỉnh entry threshold dựa trên win rate
        if(avgWinRate > 65.0) {
            config.entryThreshold -= 0.05; // Có thể nới lỏng threshold
        } else if(avgWinRate < 45.0) {
            config.entryThreshold += 0.1; // Tăng threshold để cải thiện win rate
        }
        
        // Áp dụng adaptive configuration nếu được bật
        if(config.enableAdaptiveRisk || config.enableAdaptiveEntry) {
            config.AdaptToPerformance(avgWinRate, avgProfitFactor, avgExpectancy);
        }
        
        if(m_logger) {
            m_logger->LogDebug(StringFormat("AssetDNA: Cross-validation applied - WR: %.1f%%, PF: %.2f, Exp: %.4f, Stability: %.3f",
                             avgWinRate, avgProfitFactor, avgExpectancy, stabilityScore));
        }
    }
    
    // Removed ConvertToTradingStrategy function - ENUM_STRATEGY_TYPE không tồn tại
    
}; // KẾT THÚC CLASS CAssetDNA

} // KẾT THÚC NAMESPACE

#endif // ASSETDNA_MQH_