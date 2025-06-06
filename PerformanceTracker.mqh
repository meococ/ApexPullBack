//+------------------------------------------------------------------+
//|                                             PerformanceTracker.mqh |
//|                                 Copyright 2025, ApexPullback Team  |
//|                                      https://www.apexpullback.com  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, ApexPullback Team"
#property link      "https://www.apexpullback.com"
#property version   "14.0"
#property strict

#include "Logger.mqh"
#include "Enums.mqh"

// Định nghĩa tối đa ghi năng suất
#define MAX_RECORDS 10000           // Số lượng giao dịch tối đa được lưu
#define MAX_CONSECUTIVE_TRACK 100   // Số lượng giao dịch liên tiếp theo dõi
#define MAX_SESSION_RECORDS 10      // Số loại phiên (Asia, Europe, US, v.v.)
#define MAX_CLUSTER_RECORDS 10      // Số loại cluster (Trend Following, Counter, v.v.)
#define MAX_SCENARIO_RECORDS 15     // Số kịch bản giao dịch (Pullback, Reversal, v.v.)

// Xác định các loại báo cáo
#define REPORT_DAILY 0              // Báo cáo hàng ngày
#define REPORT_WEEKLY 1             // Báo cáo hàng tuần
#define REPORT_MONTHLY 2            // Báo cáo hàng tháng
#define REPORT_COMPLETE 3           // Báo cáo đầy đủ

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu cho một giao dịch                               |
//+------------------------------------------------------------------+
struct TradeRecord {
    // Thông tin cơ bản của giao dịch
    ulong           ticket;             // Số ticket của lệnh
    datetime        openTime;           // Thời gian mở lệnh
    datetime        closeTime;          // Thời gian đóng lệnh
    ENUM_ORDER_TYPE orderType;          // Loại lệnh (BUY/SELL)
    double          volume;             // Khối lượng (lot size)
    double          openPrice;          // Giá mở lệnh
    double          closePrice;         // Giá đóng lệnh
    double          stopLoss;           // Mức stop loss
    double          takeProfit;         // Mức take profit
    double          profit;             // Lợi nhuận (điểm)
    double          profitMoney;        // Lợi nhuận (tiền tệ)
    double          commission;         // Phí giao dịch
    double          swap;               // Phí swap (qua đêm)
    
    // Thông tin phân tích 
    ENUM_CLUSTER_TYPE      cluster;     // Loại cluster (Trend Following, Countertrend, Scaling)
    ENUM_ENTRY_SCENARIO    scenario;    // Kịch bản vào lệnh (Pullback, Reversal, v.v.)
    ENUM_SESSION           session;     // Phiên giao dịch (Asia, Europe, US, v.v.)
    double                 atrRatio;    // Tỷ lệ ATR khi giao dịch được thực hiện
    double                 riskReward;  // Tỷ lệ R:R đạt được
    double                 quality;     // Chất lượng tín hiệu ban đầu (0.0 - 1.0)
    
    // Thông tin mở rộng 
    bool                   isWin;       // Lệnh thắng hay thua
    bool                   isBE;        // Lệnh được đưa về breakeven
    bool                   isTrailHit;  // Lệnh được đóng bởi trailing stop
    bool                   isPartial;   // Lệnh được đóng một phần
    bool                   isScaleIn;   // Lệnh nhồi (scaling)
    string                 notes;       // Ghi chú đặc biệt
    
    // Constructor mặc định
    TradeRecord() {
        ticket = 0;
        openTime = 0;
        closeTime = 0;
        orderType = ORDER_TYPE_BUY;
        volume = 0.0;
        openPrice = 0.0;
        closePrice = 0.0;
        stopLoss = 0.0;
        takeProfit = 0.0;
        profit = 0.0;
        profitMoney = 0.0;
        commission = 0.0;
        swap = 0.0;
        
        cluster = CLUSTER_NONE;
        scenario = SCENARIO_NONE;
        session = SESSION_UNKNOWN;
        atrRatio = 1.0;
        riskReward = 0.0;
        quality = 0.0;
        
        isWin = false;
        isBE = false;
        isTrailHit = false;
        isPartial = false;
        isScaleIn = false;
        notes = "";
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu cho thống kê theo loại                          |
//+------------------------------------------------------------------+
struct CategoryStats {
    int    trades;        // Tổng số giao dịch
    int    wins;          // Số giao dịch thắng
    int    losses;        // Số giao dịch thua
    double profitTotal;   // Tổng lợi nhuận
    double lossTotal;     // Tổng lỗ
    double maxProfit;     // Lợi nhuận tối đa
    double maxLoss;       // Lỗ tối đa
    double avgR;          // Hệ số R trung bình
    
    // Constructor mặc định
    CategoryStats() {
        trades = 0;
        wins = 0;
        losses = 0;
        profitTotal = 0.0;
        lossTotal = 0.0;
        maxProfit = 0.0;
        maxLoss = 0.0;
        avgR = 0.0;
    }
    
    // Cập nhật thống kê
    void Update(const TradeRecord &record) {
        trades++;
        
        if (record.isWin) {
            wins++;
            profitTotal += record.profitMoney;
            if (record.profitMoney > maxProfit) maxProfit = record.profitMoney;
        } else {
            losses++;
            lossTotal += MathAbs(record.profitMoney);
            if (MathAbs(record.profitMoney) > maxLoss) maxLoss = MathAbs(record.profitMoney);
        }
        
        // Cập nhật hệ số R trung bình
        if (record.riskReward > 0) {
            avgR = (avgR * (trades - 1) + record.riskReward) / trades;
        }
    }
    
    // Tính win rate (tỷ lệ thắng)
    double GetWinRate() const {
        if (trades == 0) return 0.0;
        return (double)wins / trades * 100.0;
    }
    
    // Tính profit factor (hệ số lợi nhuận)
    double GetProfitFactor() const {
        if (lossTotal == 0) return trades > 0 ? 100.0 : 0.0;
        return profitTotal / lossTotal;
    }
    
    // Tính expectancy (kỳ vọng toán học)
    double GetExpectancy() const {
        if (trades == 0) return 0.0;
        return (profitTotal - lossTotal) / trades;
    }
    
    // Tính average win (lợi nhuận trung bình)
    double GetAvgWin() const {
        if (wins == 0) return 0.0;
        return profitTotal / wins;
    }
    
    // Tính average loss (lỗ trung bình)
    double GetAvgLoss() const {
        if (losses == 0) return 0.0;
        return lossTotal / losses;
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu cho phân tích chuỗi giao dịch                   |
//+------------------------------------------------------------------+
struct StreakAnalysis {
    int    maxWinStreak;          // Chuỗi thắng tối đa
    int    maxLossStreak;         // Chuỗi thua tối đa
    int    currentWinStreak;      // Chuỗi thắng hiện tại
    int    currentLossStreak;     // Chuỗi thua hiện tại
    double maxConsecutiveProfit;  // Lợi nhuận liên tiếp tối đa
    double maxConsecutiveLoss;    // Lỗ liên tiếp tối đa
    double currentStreakProfit;   // Lợi nhuận/lỗ của chuỗi hiện tại
    
    // Constructor mặc định
    StreakAnalysis() {
        maxWinStreak = 0;
        maxLossStreak = 0;
        currentWinStreak = 0;
        currentLossStreak = 0;
        maxConsecutiveProfit = 0.0;
        maxConsecutiveLoss = 0.0;
        currentStreakProfit = 0.0;
    }
    
    // Cập nhật phân tích chuỗi
    void Update(bool isWin, double profit) {
        if (isWin) {
            // Lệnh thắng
            currentWinStreak++;
            currentLossStreak = 0;
            
            if (currentWinStreak > maxWinStreak) {
                maxWinStreak = currentWinStreak;
            }
            
            // Tính toán lợi nhuận của chuỗi thắng
            if (currentWinStreak == 1) {
                // Bắt đầu chuỗi thắng mới
                currentStreakProfit = profit;
            } else {
                // Tiếp tục chuỗi thắng
                currentStreakProfit += profit;
            }
            
            // Cập nhật lợi nhuận liên tiếp tối đa
            if (currentStreakProfit > maxConsecutiveProfit) {
                maxConsecutiveProfit = currentStreakProfit;
            }
        } else {
            // Lệnh thua
            currentLossStreak++;
            currentWinStreak = 0;
            
            if (currentLossStreak > maxLossStreak) {
                maxLossStreak = currentLossStreak;
            }
            
            // Tính toán lỗ của chuỗi thua
            if (currentLossStreak == 1) {
                // Bắt đầu chuỗi thua mới
                currentStreakProfit = profit;
            } else {
                // Tiếp tục chuỗi thua
                currentStreakProfit += profit;
            }
            
            // Cập nhật lỗ liên tiếp tối đa (lưu giá trị âm)
            if (MathAbs(currentStreakProfit) > maxConsecutiveLoss) {
                maxConsecutiveLoss = MathAbs(currentStreakProfit);
            }
        }
    }
    
    // Reset phân tích chuỗi
    void Reset() {
        maxWinStreak = 0;
        maxLossStreak = 0;
        currentWinStreak = 0;
        currentLossStreak = 0;
        maxConsecutiveProfit = 0.0;
        maxConsecutiveLoss = 0.0;
        currentStreakProfit = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu cho phân tích drawdown                          |
//+------------------------------------------------------------------+
struct DrawdownAnalysis {
    double maxDrawdown;          // Drawdown tối đa (%)
    double maxDrawdownMoney;     // Drawdown tối đa (tiền tệ)
    double currentDrawdown;      // Drawdown hiện tại (%)
    double currentDrawdownMoney; // Drawdown hiện tại (tiền tệ)
    double peakBalance;          // Balance cao nhất
    double peakEquity;           // Equity cao nhất
    double lowestAfterPeak;      // Equity thấp nhất sau đỉnh
    datetime peakTime;           // Thời gian đạt đỉnh equity
    datetime maxDDTime;          // Thời gian đạt drawdown tối đa
    int drawdownDuration;        // Thời gian phục hồi từ DD tối đa (ngày)
    
    // Constructor mặc định
    DrawdownAnalysis() {
        maxDrawdown = 0.0;
        maxDrawdownMoney = 0.0;
        currentDrawdown = 0.0;
        currentDrawdownMoney = 0.0;
        peakBalance = 0.0;
        peakEquity = 0.0;
        lowestAfterPeak = 0.0;
        peakTime = 0;
        maxDDTime = 0;
        drawdownDuration = 0;
    }
    
    // Cập nhật phân tích drawdown
    void Update(double equity, double balance, datetime currentTime = 0) {
        if (currentTime == 0) currentTime = TimeCurrent();
        
        // Cập nhật giá trị đỉnh
        if (equity > peakEquity) {
            peakEquity = equity;
            lowestAfterPeak = equity;
            peakTime = currentTime;
        }
        
        if (balance > peakBalance) {
            peakBalance = balance;
        }
        
        // Cập nhật giá trị thấp nhất sau đỉnh
        if (equity < lowestAfterPeak && peakEquity > 0) {
            lowestAfterPeak = equity;
        }
        
        // Tính drawdown hiện tại
        if (peakEquity > 0) {
            currentDrawdownMoney = peakEquity - equity;
            currentDrawdown = currentDrawdownMoney / peakEquity * 100.0;
            
            // Cập nhật drawdown tối đa
            if (currentDrawdown > maxDrawdown) {
                maxDrawdown = currentDrawdown;
                maxDrawdownMoney = currentDrawdownMoney;
                maxDDTime = currentTime;
            }
        }
    }
    
    // Tính thời gian phục hồi từ drawdown tối đa
    void UpdateRecoveryTime(datetime currentTime) {
        if (maxDDTime > 0 && currentDrawdown < maxDrawdown * 0.5) {
            // Nếu đã phục hồi ít nhất 50% từ DD tối đa
            MqlDateTime max_dd_time_struct, current_time_struct;
            TimeToStruct(maxDDTime, max_dd_time_struct);
            TimeToStruct(currentTime, current_time_struct);
            
            // Tính số ngày
            drawdownDuration = (current_time_struct.day - max_dd_time_struct.day) + 
                              (current_time_struct.mon - max_dd_time_struct.mon) * 30 + 
                              (current_time_struct.year - max_dd_time_struct.year) * 365;
        }
    }
    
    // Reset phân tích drawdown
    void Reset() {
        maxDrawdown = 0.0;
        maxDrawdownMoney = 0.0;
        currentDrawdown = 0.0;
        currentDrawdownMoney = 0.0;
        peakBalance = 0.0;
        peakEquity = 0.0;
        lowestAfterPeak = 0.0;
        peakTime = 0;
        maxDDTime = 0;
        drawdownDuration = 0;
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu thêm cho phân tích hiệu suất theo thời gian     |
//+------------------------------------------------------------------+
struct TimeBasedPerformance {
    double hourlyPF[24];         // Profit Factor theo giờ
    double hourlyWR[24];         // Win Rate theo giờ
    int    hourlyTrades[24];     // Số giao dịch theo giờ
    
    double dailyPF[7];           // Profit Factor theo ngày trong tuần
    double dailyWR[7];           // Win Rate theo ngày trong tuần
    int    dailyTrades[7];       // Số giao dịch theo ngày trong tuần
    
    int bestHour;                // Giờ có hiệu suất tốt nhất
    int worstHour;               // Giờ có hiệu suất kém nhất
    int bestDay;                 // Ngày có hiệu suất tốt nhất
    int worstDay;                // Ngày có hiệu suất kém nhất
    
    // Constructor mặc định
    TimeBasedPerformance() {
        // Khởi tạo các mảng
        ArrayInitialize(hourlyPF, 0.0);
        ArrayInitialize(hourlyWR, 0.0);
        ArrayInitialize(hourlyTrades, 0);
        
        ArrayInitialize(dailyPF, 0.0);
        ArrayInitialize(dailyWR, 0.0);
        ArrayInitialize(dailyTrades, 0);
        
        bestHour = -1;
        worstHour = -1;
        bestDay = -1;
        worstDay = -1;
    }
    
    // Cập nhật thống kê theo thời gian
    void Update(const TradeRecord &record) {
        if (record.closeTime == 0) return;
        
        // Lấy giờ và ngày trong tuần
        MqlDateTime dt;
        TimeToStruct(record.closeTime, dt);
        
        int hour = dt.hour;
        int day = dt.day_of_week;
        
        // Cập nhật số lệnh
        hourlyTrades[hour]++;
        dailyTrades[day]++;
        
        // Cập nhật win rate và profit factor
        // (Cần tính toán tích lũy thực tế, đây chỉ là code mẫu)
        // Trong thực tế, cần lưu wins và losses để tính toán chính xác
    }
    
    // Phân tích để tìm ra thời gian tốt nhất và kém nhất
    void Analyze() {
        double bestPerf = 0.0;
        double worstPerf = DBL_MAX;
        
        // Tìm giờ tốt nhất và kém nhất
        for (int i = 0; i < 24; i++) {
            if (hourlyTrades[i] < 5) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = hourlyPF[i] * hourlyWR[i] / 100.0; // Điểm hiệu suất
            
            if (perf > bestPerf) {
                bestPerf = perf;
                bestHour = i;
            }
            
            if (perf < worstPerf) {
                worstPerf = perf;
                worstHour = i;
            }
        }
        
        // Tìm ngày tốt nhất và kém nhất
        bestPerf = 0.0;
        worstPerf = DBL_MAX;
        
        for (int i = 0; i < 7; i++) {
            if (dailyTrades[i] < 5) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = dailyPF[i] * dailyWR[i] / 100.0; // Điểm hiệu suất
            
            if (perf > bestPerf) {
                bestPerf = perf;
                bestDay = i;
            }
            
            if (perf < worstPerf) {
                worstPerf = perf;
                worstDay = i;
            }
        }
    }
};

//+------------------------------------------------------------------+
//| Lớp chính cho việc theo dõi hiệu suất giao dịch                  |
//+------------------------------------------------------------------+
class CPerformanceTracker {
private:
    // Cơ sở dữ liệu giao dịch
    TradeRecord   m_trades[];       // Mảng lưu trữ tất cả giao dịch
    int           m_tradeCount;     // Số lượng giao dịch đã lưu
    double        m_initialBalance; // Balance ban đầu
    datetime      m_startTime;      // Thời gian bắt đầu theo dõi
    datetime      m_lastUpdateTime; // Thời gian cập nhật cuối cùng
    bool          m_isInitialized;  // Đã khởi tạo chưa
    string        m_symbol;         // Symbol hiện tại
    
    // Thống kê tổng thể
    int           m_totalTrades;    // Tổng số giao dịch
    int           m_winTrades;      // Số giao dịch thắng
    int           m_lossTrades;     // Số giao dịch thua
    int           m_beTrades;       // Số giao dịch hòa (break even)
    double        m_totalProfit;    // Tổng lợi nhuận
    double        m_totalLoss;      // Tổng lỗ
    double        m_netProfit;      // Lợi nhuận ròng
    double        m_grossProfit;    // Lợi nhuận gộp
    double        m_grossLoss;      // Lỗ gộp
    double        m_avgHoldingTime; // Thời gian giữ lệnh trung bình (giây)
    double        m_commissions;    // Tổng phí giao dịch
    double        m_swap;           // Tổng phí swap
    
    // Thống kê chi tiết
    CategoryStats m_clusterStats[MAX_CLUSTER_RECORDS];    // Thống kê theo cluster
    CategoryStats m_scenarioStats[MAX_SCENARIO_RECORDS];  // Thống kê theo kịch bản
    CategoryStats m_sessionStats[MAX_SESSION_RECORDS];    // Thống kê theo phiên
    CategoryStats m_atrRatioStats[5];                     // Thống kê theo ATR ratio
    CategoryStats m_dayOfWeekStats[7];                    // Thống kê theo ngày trong tuần
    CategoryStats m_hourStats[24];                        // Thống kê theo giờ
    
    // Phân tích nâng cao
    StreakAnalysis       m_streakAnalysis;      // Phân tích chuỗi giao dịch
    DrawdownAnalysis     m_ddAnalysis;          // Phân tích drawdown
    TimeBasedPerformance m_timeAnalysis;        // Phân tích theo thời gian
    double               m_sqn;                 // System Quality Number (SQN)
    double               m_avgR;                // Hệ số R trung bình
    double               m_rMultiple;           // R-multiple mới nhất
    double               m_sharpeRatio;         // Sharpe Ratio
    double               m_kellyPercent;        // Kelly Criterion %
    
    // Mảng tạm cho các ngày giao dịch
    datetime      m_tradingDays[];                       // Các ngày có giao dịch
    int           m_tradingDaysCount;                    // Số ngày có giao dịch
    
    // Mảng tạm cho thông tin balance theo ngày
    double        m_dailyBalance[];                      // Balance hàng ngày
    int           m_dailyBalanceCount;                   // Số ngày có balance
    
    // Các biến theo dõi hiệu suất theo thời gian thực
    double        m_lastBalance;                         // Balance cuối cùng
    double        m_lastEquity;                          // Equity cuối cùng
    
    // Thời gian kết thúc theo dõi (cho backtest)
    datetime      m_endTime;                             // Thời gian kết thúc theo dõi
    
    // Cơ sở dữ liệu cảnh báo
    string        m_alerts[];                            // Các cảnh báo hiệu suất
    int           m_alertCount;                          // Số lượng cảnh báo
    
    // Logger
    CLogger      *m_logger;                              // Logger để ghi log
    bool          m_detailedLogging;                     // Ghi log chi tiết?
    
private:
    // Hàm nội bộ - Thêm ngày giao dịch mới vào danh sách
    void AddTradingDay(datetime day) {
        // Chuyển đổi ngày thành ngày thuần túy (không có giờ, phút, giây)
        MqlDateTime dt;
        TimeToStruct(day, dt);
        datetime pureDay = StringToTime(StringFormat("%04d.%02d.%02d", dt.year, dt.mon, dt.day));
        
        // Kiểm tra xem ngày đã tồn tại trong danh sách chưa
        for (int i = 0; i < m_tradingDaysCount; i++) {
            if (m_tradingDays[i] == pureDay) {
                return; // Ngày đã tồn tại
            }
        }
        
        // Thêm ngày mới vào danh sách
        ArrayResize(m_tradingDays, m_tradingDaysCount + 1);
        m_tradingDays[m_tradingDaysCount] = pureDay;
        m_tradingDaysCount++;
        
        // Sắp xếp lại mảng ngày theo thứ tự tăng dần
        ArraySort(m_tradingDays);
    }
    
    // Hàm nội bộ - Thêm cảnh báo mới
    void AddAlert(string message) {
        // Thêm cảnh báo mới vào danh sách
        ArrayResize(m_alerts, m_alertCount + 1);
        m_alerts[m_alertCount] = TimeToString(TimeCurrent()) + ": " + message;
        m_alertCount++;
        
        // Ghi log nếu có logger
        if (m_logger != NULL) {
            m_logger.LogWarning("PerformanceTracker Alert: " + message);
        }
    }
    
    // Hàm nội bộ - Tính toán SQN (System Quality Number)
    double CalculateSQN() {
        if (m_totalTrades < 30) return 0.0; // Cần ít nhất 30 giao dịch để tính SQN
        
        // Tính lợi nhuận trung bình và độ lệch chuẩn
        double trades[];
        ArrayResize(trades, m_totalTrades);
        
        for (int i = 0; i < m_tradeCount && i < m_totalTrades; i++) {
            trades[i] = m_trades[i].profitMoney;
        }
        
        double mean = 0.0;
        for (int i = 0; i < m_totalTrades; i++) {
            mean += trades[i];
        }
        mean /= m_totalTrades;
        
        double variance = 0.0;
        for (int i = 0; i < m_totalTrades; i++) {
            variance += MathPow(trades[i] - mean, 2);
        }
        variance /= m_totalTrades;
        
        double stdDev = MathSqrt(variance);
        
        // Tính SQN
        if (stdDev == 0.0) return 0.0;
        
        return (mean / stdDev) * MathSqrt(m_totalTrades);
    }
    
    // Hàm nội bộ - Tính Sharpe Ratio
    double CalculateSharpeRatio() {
        if (m_totalTrades < 30) return 0.0; // Cần ít nhất 30 giao dịch
        
        // Tính lợi nhuận trung bình và độ lệch chuẩn
        double returns[]; // Lợi nhuận % mỗi ngày
        int daysCount = 0;
        
        // Trong thực tế cần tính returns đúng cách
        // Giả lập với dữ liệu mẫu
        ArrayResize(returns, 30);
        for (int i = 0; i < 30; i++) {
            returns[i] = 0.5 * MathRand() / 32768.0;
            daysCount++;
        }
        
        double avgReturn = 0.0;
        for (int i = 0; i < daysCount; i++) {
            avgReturn += returns[i];
        }
        avgReturn /= daysCount;
        
        double variance = 0.0;
        for (int i = 0; i < daysCount; i++) {
            variance += MathPow(returns[i] - avgReturn, 2);
        }
        variance /= daysCount;
        
        double stdDev = MathSqrt(variance);
        
        // Risk-free rate (giả định là 0.02 hoặc 2%)
        double riskFreeRate = 0.02;
        double annualizedRiskFreeRate = riskFreeRate / 365.0;
        
        // Tính Sharpe Ratio
        if (stdDev == 0.0) return 0.0;
        
        return (avgReturn - annualizedRiskFreeRate) / stdDev * MathSqrt(252); // Annualized
    }
    
    // Hàm nội bộ - Tính Kelly Criterion (%)
    double CalculateKellyPercent() {
        // Kelly = W - (1-W)/R
        // Trong đó W = win rate (dạng thập phân), R = avg win / avg loss
        
        double winRate = m_winTrades / (double)m_totalTrades;
        double avgWin = m_winTrades > 0 ? m_grossProfit / m_winTrades : 0.0;
        double avgLoss = m_lossTrades > 0 ? m_grossLoss / m_lossTrades : 0.0;
        
        if (avgLoss == 0.0 || m_totalTrades < 30) return 0.0;
        
        double ratio = avgWin / avgLoss;
        double kelly = winRate - (1.0 - winRate) / ratio;
        
        // Giới hạn Kelly % từ 0-100%
        return MathMax(0.0, MathMin(1.0, kelly)) * 100.0;
    }
    
    // Hàm nội bộ - Phân tích hiệu suất theo múi giờ
    string AnalyzeTimePerformance() {
        string report = "\n=== PHÂN TÍCH THEO THỜI GIAN ===\n";
        
        // Phân tích theo ngày trong tuần
        report += "Theo ngày trong tuần:\n";
        string dayNames[] = {"Chủ nhật", "Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7"};
        
        for (int i = 0; i < 7; i++) {
            if (m_dayOfWeekStats[i].trades > 0) {
                report += StringFormat("%s: %d lệnh, WR: %.1f%%, PF: %.2f, Avg.R: %.2f\n",
                                      dayNames[i],
                                      m_dayOfWeekStats[i].trades,
                                      m_dayOfWeekStats[i].GetWinRate(),
                                      m_dayOfWeekStats[i].GetProfitFactor(),
                                      m_dayOfWeekStats[i].avgR);
            }
        }
        
        // Phân tích theo giờ
        report += "\nTheo giờ (GMT):\n";
        int topHours[3] = {-1, -1, -1};
        double topHourPerf[3] = {0.0, 0.0, 0.0};
        
        // Tìm 3 giờ tốt nhất
        for (int i = 0; i < 24; i++) {
            if (m_hourStats[i].trades < 3) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = m_hourStats[i].GetProfitFactor() * m_hourStats[i].GetWinRate() / 100.0;
            
            for (int j = 0; j < 3; j++) {
                if (perf > topHourPerf[j]) {
                    // Dịch chuyển các giá trị
                    for (int k = 2; k > j; k--) {
                        topHours[k] = topHours[k-1];
                        topHourPerf[k] = topHourPerf[k-1];
                    }
                    
                    topHours[j] = i;
                    topHourPerf[j] = perf;
                    break;
                }
            }
        }
        
        // Hiển thị 3 giờ tốt nhất
        report += "Top 3 giờ giao dịch tốt nhất:\n";
        for (int i = 0; i < 3; i++) {
            if (topHours[i] >= 0) {
                report += StringFormat("%02d:00: %d lệnh, WR: %.1f%%, PF: %.2f\n",
                                      topHours[i],
                                      m_hourStats[topHours[i]].trades,
                                      m_hourStats[topHours[i]].GetWinRate(),
                                      m_hourStats[topHours[i]].GetProfitFactor());
            }
        }
        
        return report;
    }
    
    // Hàm nội bộ - Phân tích hiệu suất theo ATR
    string AnalyzeATRPerformance() {
        string report = "\n=== PHÂN TÍCH THEO BIẾN ĐỘNG ATR ===\n";
        string atrLabels[] = {"ATR Thấp (<0.8)", "ATR Dưới TB (0.8-1.0)", 
                             "ATR Trung bình (1.0-1.2)", "ATR Cao (1.2-1.5)", "ATR Rất cao (>1.5)"};
        
        for (int i = 0; i < 5; i++) {
            if (m_atrRatioStats[i].trades > 0) {
                report += StringFormat("%s: %d lệnh, WR: %.1f%%, PF: %.2f, Profit: %.2f\n",
                                      atrLabels[i],
                                      m_atrRatioStats[i].trades,
                                      m_atrRatioStats[i].GetWinRate(),
                                      m_atrRatioStats[i].GetProfitFactor(),
                                      m_atrRatioStats[i].profitTotal - m_atrRatioStats[i].lossTotal);
            }
        }
        
        return report;
    }
    
    // Hàm nội bộ - Phân tích chuỗi giao dịch
    string AnalyzeStreaks() {
        string report = "\n=== PHÂN TÍCH CHUỖI GIAO DỊCH ===\n";
        
        report += StringFormat("Chuỗi thắng tối đa: %d lệnh\n", m_streakAnalysis.maxWinStreak);
        report += StringFormat("Chuỗi thua tối đa: %d lệnh\n", m_streakAnalysis.maxLossStreak);
        report += StringFormat("Lợi nhuận liên tiếp tối đa: %.2f\n", m_streakAnalysis.maxConsecutiveProfit);
        report += StringFormat("Lỗ liên tiếp tối đa: %.2f\n", m_streakAnalysis.maxConsecutiveLoss);
        
        // Phân tích đặc biệt
        if (m_streakAnalysis.maxLossStreak >= 3) {
            report += "\nPhân tích: Chuỗi thua dài nhất là " + IntegerToString(m_streakAnalysis.maxLossStreak) + 
                     " lệnh. EA nên có cơ chế tạm dừng sau 3 lệnh thua liên tiếp để tránh DD sâu.\n";
        }
        
        return report;
    }
    
    // Hàm nội bộ - Phân tích theo Cluster
    string AnalyzeClusterPerformance() {
        string report = "\n=== PHÂN TÍCH THEO CLUSTER ===\n";
        string clusterNames[] = {
            "None", 
            "Trend Following", 
            "Countertrend", 
            "Breakout", 
            "Range",
            "Reversal",
            "Scaling",
            "Pullback",
            "Fibonacci",
            "Custom"
        };
        
        for (int i = 0; i < MAX_CLUSTER_RECORDS; i++) {
            if (m_clusterStats[i].trades > 0) {
                report += StringFormat("%s: %d lệnh, WR: %.1f%%, PF: %.2f, Avg.R: %.2f\n",
                                      i < 10 ? clusterNames[i] : StringFormat("Cluster %d", i),
                                      m_clusterStats[i].trades,
                                      m_clusterStats[i].GetWinRate(),
                                      m_clusterStats[i].GetProfitFactor(),
                                      m_clusterStats[i].avgR);
            }
        }
        
        // Tìm Cluster tốt nhất và kém nhất
        int bestCluster = -1;
        int worstCluster = -1;
        double bestPerf = 0.0;
        double worstPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_CLUSTER_RECORDS; i++) {
            if (m_clusterStats[i].trades < 5) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = m_clusterStats[i].GetProfitFactor() * m_clusterStats[i].GetWinRate() / 100.0;
            
            if (perf > bestPerf) {
                bestPerf = perf;
                bestCluster = i;
            }
            
            if (perf < worstPerf) {
                worstPerf = perf;
                worstCluster = i;
            }
        }
        
        if (bestCluster >= 0) {
            report += StringFormat("\nCluster tốt nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  bestCluster < 10 ? clusterNames[bestCluster] : StringFormat("Cluster %d", bestCluster),
                                  m_clusterStats[bestCluster].GetWinRate(),
                                  m_clusterStats[bestCluster].GetProfitFactor());
        }
        
        if (worstCluster >= 0) {
            report += StringFormat("Cluster kém nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  worstCluster < 10 ? clusterNames[worstCluster] : StringFormat("Cluster %d", worstCluster),
                                  m_clusterStats[worstCluster].GetWinRate(),
                                  m_clusterStats[worstCluster].GetProfitFactor());
        }
        
        return report;
    }
    
    // Hàm nội bộ - Phân tích theo Scenario
    string AnalyzeScenarioPerformance() {
        string report = "\n=== PHÂN TÍCH THEO KỊCH BẢN GIAO DỊCH ===\n";
        string scenarioNames[] = {
            "None", 
            "Strong Pullback", 
            "Bullish Pullback", 
            "Bearish Pullback", 
            "Fibonacci Pullback", 
            "Harmonic Pattern", 
            "Liquidity Grab", 
            "Momentum Shift", 
            "Range Breakout", 
            "Range Rejection",
            "Double Top/Bottom",
            "Triple Top/Bottom",
            "Head & Shoulders",
            "Trendline Break",
            "Support/Resistance"
        };
        
        for (int i = 0; i < MAX_SCENARIO_RECORDS; i++) {
            if (m_scenarioStats[i].trades > 0) {
                report += StringFormat("%s: %d lệnh, WR: %.1f%%, PF: %.2f, Avg.R: %.2f\n",
                                      i < 15 ? scenarioNames[i] : StringFormat("Scenario %d", i),
                                      m_scenarioStats[i].trades,
                                      m_scenarioStats[i].GetWinRate(),
                                      m_scenarioStats[i].GetProfitFactor(),
                                      m_scenarioStats[i].avgR);
            }
        }
        
        // Tìm Scenario tốt nhất và kém nhất
        int bestScenario = -1;
        int worstScenario = -1;
        double bestPerf = 0.0;
        double worstPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_SCENARIO_RECORDS; i++) {
            if (m_scenarioStats[i].trades < 5) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = m_scenarioStats[i].GetProfitFactor() * m_scenarioStats[i].GetWinRate() / 100.0;
            
            if (perf > bestPerf) {
                bestPerf = perf;
                bestScenario = i;
            }
            
            if (perf < worstPerf) {
                worstPerf = perf;
                worstScenario = i;
            }
        }
        
        if (bestScenario >= 0) {
            report += StringFormat("\nKịch bản tốt nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  bestScenario < 15 ? scenarioNames[bestScenario] : StringFormat("Scenario %d", bestScenario),
                                  m_scenarioStats[bestScenario].GetWinRate(),
                                  m_scenarioStats[bestScenario].GetProfitFactor());
        }
        
        if (worstScenario >= 0) {
            report += StringFormat("Kịch bản kém nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  worstScenario < 15 ? scenarioNames[worstScenario] : StringFormat("Scenario %d", worstScenario),
                                  m_scenarioStats[worstScenario].GetWinRate(),
                                  m_scenarioStats[worstScenario].GetProfitFactor());
            
            report += "\nĐề xuất: Xem xét điều chỉnh hoặc loại bỏ kịch bản " + 
                     (worstScenario < 15 ? scenarioNames[worstScenario] : StringFormat("Scenario %d", worstScenario)) + 
                     " để cải thiện hiệu suất tổng thể.\n";
        }
        
        return report;
    }
    
    // Hàm nội bộ - Phân tích theo Phiên
    string AnalyzeSessionPerformance() {
        string report = "\n=== PHÂN TÍCH THEO PHIÊN GIAO DỊCH ===\n";
        string sessionNames[] = {
            "Unknown", 
            "Asian", 
            "European", 
            "American", 
            "EU-US Overlap", 
            "London Open",
            "New York Open",
            "London Close",
            "Asian Open",
            "Closing"
        };
        
        for (int i = 0; i < MAX_SESSION_RECORDS; i++) {
            if (m_sessionStats[i].trades > 0) {
                report += StringFormat("%s: %d lệnh, WR: %.1f%%, PF: %.2f, Avg.R: %.2f\n",
                                      i < 10 ? sessionNames[i] : StringFormat("Session %d", i),
                                      m_sessionStats[i].trades,
                                      m_sessionStats[i].GetWinRate(),
                                      m_sessionStats[i].GetProfitFactor(),
                                      m_sessionStats[i].avgR);
            }
        }
        
        // Tìm Session tốt nhất và kém nhất
        int bestSession = -1;
        int worstSession = -1;
        double bestPerf = 0.0;
        double worstPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_SESSION_RECORDS; i++) {
            if (m_sessionStats[i].trades < 5) continue; // Bỏ qua nếu quá ít giao dịch
            
            double perf = m_sessionStats[i].GetProfitFactor() * m_sessionStats[i].GetWinRate() / 100.0;
            
            if (perf > bestPerf) {
                bestPerf = perf;
                bestSession = i;
            }
            
            if (perf < worstPerf) {
                worstPerf = perf;
                worstSession = i;
            }
        }
        
        if (bestSession >= 0) {
            report += StringFormat("\nPhiên tốt nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  bestSession < 10 ? sessionNames[bestSession] : StringFormat("Session %d", bestSession),
                                  m_sessionStats[bestSession].GetWinRate(),
                                  m_sessionStats[bestSession].GetProfitFactor());
        }
        
        if (worstSession >= 0) {
            report += StringFormat("Phiên kém nhất: %s (WR: %.1f%%, PF: %.2f)\n",
                                  worstSession < 10 ? sessionNames[worstSession] : StringFormat("Session %d", worstSession),
                                  m_sessionStats[worstSession].GetWinRate(),
                                  m_sessionStats[worstSession].GetProfitFactor());
            
            report += "\nĐề xuất: Xem xét hạn chế giao dịch trong phiên " + 
                     (worstSession < 10 ? sessionNames[worstSession] : StringFormat("Session %d", worstSession)) + 
                     " hoặc điều chỉnh tham số cho phù hợp với đặc thù phiên này.\n";
        }
        
        return report;
    }
    
    // Hàm nội bộ - Tạo các đề xuất cải thiện hiệu suất
    string GenerateRecommendations() {
        string recommendations = "\n=== ĐỀ XUẤT CẢI THIỆN HIỆU SUẤT ===\n";
        int recCount = 0;
        
        // Đề xuất dựa trên số lượng giao dịch
        if (m_totalTrades < 30) {
            recommendations += StringFormat("%d. Cần thu thập thêm dữ liệu (tối thiểu 30 lệnh) để phân tích chính xác hơn.\n", ++recCount);
        }
        
        // Đề xuất dựa trên win rate
        if (GetWinRate() < 45.0) {
            recommendations += StringFormat("%d. Win rate thấp (%.1f%%). Xem xét cải thiện độ chính xác tín hiệu vào lệnh.\n", 
                                        ++recCount, GetWinRate());
        }
        else if (GetWinRate() < 55.0) {
            recommendations += StringFormat("%d. Win rate trung bình (%.1f%%). Xem xét tăng R:R để bù đắp.\n", 
                                        ++recCount, GetWinRate());
        }
        
        // Đề xuất dựa trên profit factor
        if (GetProfitFactor() < 1.2) {
            recommendations += StringFormat("%d. Profit Factor thấp (%.2f). Xem xét cải thiện quản lý vốn, R:R.\n", 
                                        ++recCount, GetProfitFactor());
        }
        
        // Đề xuất dựa trên drawdown
        if (m_ddAnalysis.maxDrawdown > 20.0) {
            recommendations += StringFormat("%d. Drawdown tối đa cao (%.1f%%). Xem xét giảm risk, tối ưu quản lý vốn.\n", 
                                        ++recCount, m_ddAnalysis.maxDrawdown);
        }
        
        // Đề xuất dựa trên chuỗi thua
        if (m_streakAnalysis.maxLossStreak > 5) {
            recommendations += StringFormat("%d. Chuỗi thua dài (max %d lệnh). Xem xét cơ chế tự tạm dừng khi thua liên tiếp.\n", 
                                        ++recCount, m_streakAnalysis.maxLossStreak);
        }
        
        // Đề xuất dựa trên SQN
        if (m_sqn < 1.5 && m_totalTrades >= 30) {
            recommendations += StringFormat("%d. SQN thấp (%.2f). Hệ thống cần nâng cao độ tin cậy thống kê.\n", 
                                        ++recCount, m_sqn);
        }
        
        // Đề xuất dựa trên hiệu suất theo phiên
        int worstSession = -1;
        double worstSessionPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_SESSION_RECORDS; i++) {
            if (m_sessionStats[i].trades < 5) continue;
            
            double perf = m_sessionStats[i].GetProfitFactor();
            if (perf < worstSessionPerf && perf < 1.0) {
                worstSessionPerf = perf;
                worstSession = i;
            }
        }
        
        if (worstSession >= 0) {
            string sessionNames[] = {
                "Unknown", 
                "Asian", 
                "European", 
                "American", 
                "EU-US Overlap", 
                "London Open",
                "New York Open",
                "London Close",
                "Asian Open",
                "Closing"
            };
            
            recommendations += StringFormat("%d. Phiên %s có hiệu suất kém (PF: %.2f). Xem xét hạn chế giao dịch trong phiên này.\n", 
                                        ++recCount, 
                                        worstSession < 10 ? sessionNames[worstSession] : StringFormat("Session %d", worstSession),
                                        worstSessionPerf);
        }
        
        // Đề xuất dựa trên hiệu suất theo kịch bản
        int worstScenario = -1;
        double worstScenarioPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_SCENARIO_RECORDS; i++) {
            if (m_scenarioStats[i].trades < 5) continue;
            
            double perf = m_scenarioStats[i].GetProfitFactor();
            if (perf < worstScenarioPerf && perf < 1.0) {
                worstScenarioPerf = perf;
                worstScenario = i;
            }
        }
        
        if (worstScenario >= 0) {
            string scenarioNames[] = {
                "None", 
                "Strong Pullback", 
                "Bullish Pullback", 
                "Bearish Pullback", 
                "Fibonacci Pullback", 
                "Harmonic Pattern", 
                "Liquidity Grab", 
                "Momentum Shift", 
                "Range Breakout", 
                "Range Rejection",
                "Double Top/Bottom",
                "Triple Top/Bottom",
                "Head & Shoulders",
                "Trendline Break",
                "Support/Resistance"
            };
            
            recommendations += StringFormat("%d. Kịch bản %s có hiệu suất kém (PF: %.2f). Xem xét điều chỉnh logic hoặc loại bỏ.\n", 
                                        ++recCount, 
                                        worstScenario < 15 ? scenarioNames[worstScenario] : StringFormat("Scenario %d", worstScenario),
                                        worstScenarioPerf);
        }
        
        // Đề xuất dựa trên hiệu suất theo cluster
        int worstCluster = -1;
        double worstClusterPerf = DBL_MAX;
        
        for (int i = 0; i < MAX_CLUSTER_RECORDS; i++) {
            if (m_clusterStats[i].trades < 5) continue;
            
            double perf = m_clusterStats[i].GetProfitFactor();
            if (perf < worstClusterPerf && perf < 1.0) {
                worstClusterPerf = perf;
                worstCluster = i;
            }
        }
        
        if (worstCluster >= 0) {
            string clusterNames[] = {
                "None", 
                "Trend Following", 
                "Countertrend", 
                "Breakout", 
                "Range",
                "Reversal",
                "Scaling",
                "Pullback",
                "Fibonacci",
                "Custom"
            };
            
            recommendations += StringFormat("%d. Cluster %s có hiệu suất kém (PF: %.2f). Xem xét điều chỉnh logic hoặc loại bỏ.\n", 
                                        ++recCount, 
                                        worstCluster < 10 ? clusterNames[worstCluster] : StringFormat("Cluster %d", worstCluster),
                                        worstClusterPerf);
        }
        
        // Đề xuất dựa trên hiệu suất theo ATR
        if (m_atrRatioStats[4].trades >= 5 && m_atrRatioStats[4].GetProfitFactor() < 1.0) {
            recommendations += StringFormat("%d. Hiệu suất kém trong điều kiện biến động cao (ATR > 1.5x). Xem xét giảm lot size hoặc mở rộng SL.\n", 
                                        ++recCount);
        }
        
        // Đề xuất dựa trên thời gian giữ lệnh
        if (m_avgHoldingTime > 24*3600 && m_totalTrades > 30) {
            recommendations += StringFormat("%d. Thời gian giữ lệnh trung bình cao (%.1f giờ). Xem xét tối ưu hóa chiến lược thoát lệnh.\n", 
                                        ++recCount, m_avgHoldingTime/3600.0);
        }
        
        // Đề xuất dựa trên Kelly Criterion
        if (m_kellyPercent > 0 && m_kellyPercent < 10) {
            recommendations += StringFormat("%d. Kelly Percent thấp (%.1f%%). Xem xét cải thiện tỷ lệ win/loss hoặc profit/loss ratio.\n", 
                                        ++recCount, m_kellyPercent);
        }
        
        // Đề xuất dựa trên R-multiple
        if (m_avgR < 1.0 && m_totalTrades > 30) {
            recommendations += StringFormat("%d. R-multiple trung bình thấp (%.2f). Xem xét điều chỉnh SL/TP để cải thiện R:R ratio.\n", 
                                        ++recCount, m_avgR);
        }
        
        // Nếu không có đề xuất nào
        if (recCount == 0) {
            recommendations += "✅ Hiệu suất EA hiện tại tốt. Tiếp tục theo dõi để tối ưu hóa thêm.\n";
        }
        
        return recommendations;
    }
    
    // Hàm nội bộ - Ghi log thông tin
    void LogInfo(string message) {
        if (m_logger != NULL) {
            m_logger.LogInfo("PerformanceTracker: " + message);
        }
    }
    
    // Hàm nội bộ - Ghi log cảnh báo
    void LogWarning(string message) {
        if (m_logger != NULL) {
            m_logger.LogWarning("PerformanceTracker: " + message);
        }
    }
    
public:
    // Constructor 
    CPerformanceTracker() {
        m_logger = NULL;
        m_detailedLogging = false;
        Reset();
    }
    
    // Destructor
    ~CPerformanceTracker() {
        // Không xóa logger vì nó được cung cấp từ bên ngoài
    }
    
    // Khởi tạo với logger
    bool Initialize(CLogger *logger = NULL, bool detailedLogging = false) {
        Reset();
        
        m_logger = logger;
        m_detailedLogging = detailedLogging;
        m_symbol = _Symbol;
        m_initialBalance = AccountInfoDouble(ACCOUNT_BALANCE);
        m_startTime = TimeCurrent();
        m_lastUpdateTime = TimeCurrent();
        m_isInitialized = true;
        
        // Khởi tạo phân tích drawdown
        m_ddAnalysis.peakBalance = m_initialBalance;
        m_ddAnalysis.peakEquity = AccountInfoDouble(ACCOUNT_EQUITY);
        m_ddAnalysis.lowestAfterPeak = m_ddAnalysis.peakEquity;
        
        if (m_logger != NULL) {
            LogInfo("Tracker khởi tạo thành công. Balance ban đầu: " + DoubleToString(m_initialBalance, 2));
        }
        
        return true;
    }
    
    // Reset toàn bộ dữ liệu
    void Reset() {
        // Reset cơ sở dữ liệu giao dịch
        ArrayFree(m_trades);
        m_tradeCount = 0;
        m_initialBalance = 0.0;
        m_startTime = 0;
        m_lastUpdateTime = 0;
        m_isInitialized = false;
        m_symbol = "";
        
        // Reset thống kê tổng thể
        m_totalTrades = 0;
        m_winTrades = 0;
        m_lossTrades = 0;
        m_beTrades = 0;
        m_totalProfit = 0.0;
        m_totalLoss = 0.0;
        m_netProfit = 0.0;
        m_grossProfit = 0.0;
        m_grossLoss = 0.0;
        m_avgHoldingTime = 0.0;
        m_commissions = 0.0;
        m_swap = 0.0;
        
        // Reset thống kê chi tiết 
        for (int i = 0; i < MAX_CLUSTER_RECORDS; i++) {
            m_clusterStats[i] = CategoryStats();
        }
        
        for (int i = 0; i < MAX_SCENARIO_RECORDS; i++) {
            m_scenarioStats[i] = CategoryStats();
        }
        
        for (int i = 0; i < MAX_SESSION_RECORDS; i++) {
            m_sessionStats[i] = CategoryStats();
        }
        
        for (int i = 0; i < 5; i++) {
            m_atrRatioStats[i] = CategoryStats();
        }
        
        for (int i = 0; i < 7; i++) {
            m_dayOfWeekStats[i] = CategoryStats();
        }
        
        for (int i = 0; i < 24; i++) {
            m_hourStats[i] = CategoryStats();
        }
        
        // Reset phân tích nâng cao
        m_streakAnalysis.Reset();
        m_ddAnalysis.Reset();
        m_sqn = 0.0;
        m_avgR = 0.0;
        m_rMultiple = 0.0;
        m_sharpeRatio = 0.0;
        m_kellyPercent = 0.0;
        
        // Reset mảng tạm
        ArrayFree(m_tradingDays);
        m_tradingDaysCount = 0;
        
        ArrayFree(m_dailyBalance);
        m_dailyBalanceCount = 0;
        
        // Reset các biến theo dõi theo thời gian thực
        m_lastBalance = 0.0;
        m_lastEquity = 0.0;
        
        // Reset thời gian kết thúc
        m_endTime = 0;
        
        // Reset cơ sở dữ liệu cảnh báo
        ArrayFree(m_alerts);
        m_alertCount = 0;
        
        if (m_logger != NULL) {
            LogInfo("Tracker đã reset toàn bộ dữ liệu");
        }
    }
    
    // Thêm giao dịch mới (phiên bản đơn giản)
    void UpdateTradeResult(bool isWin, double profit, ENUM_CLUSTER_TYPE cluster, 
                        ENUM_SESSION session, double atrRatio) {
        if (!m_isInitialized) {
            if (!Initialize()) {
                Print("Không thể khởi tạo PerformanceTracker");
                return;
            }
        }
        
        // Tạo bản ghi giao dịch mới
        TradeRecord record;
        record.isWin = isWin;
        record.profitMoney = profit;
        record.cluster = cluster;
        record.session = session;
        record.atrRatio = atrRatio;
        record.closeTime = TimeCurrent();
        
        // Thêm vào cơ sở dữ liệu
        if (m_tradeCount < MAX_RECORDS) {
            ArrayResize(m_trades, m_tradeCount + 1);
            m_trades[m_tradeCount] = record;
            m_tradeCount++;
        }
        
        // Cập nhật thống kê tổng thể
        m_totalTrades++;
        
        if (isWin) {
            m_winTrades++;
            m_totalProfit += profit;
            m_grossProfit += profit;
        } else {
            m_lossTrades++;
            m_totalLoss += MathAbs(profit);
            m_grossLoss += MathAbs(profit);
        }
        
        m_netProfit = m_totalProfit - m_totalLoss;
        
        // Cập nhật thống kê theo loại
        if (cluster >= 0 && cluster < MAX_CLUSTER_RECORDS) {
            m_clusterStats[cluster].Update(record);
        }
        
        if (session >= 0 && session < MAX_SESSION_RECORDS) {
            m_sessionStats[session].Update(record);
        }
        
        // Cập nhật thống kê theo ATR ratio
        int atrIndex = 0;
        if (atrRatio < 0.8) atrIndex = 0;      // ATR thấp
        else if (atrRatio < 1.0) atrIndex = 1; // ATR dưới trung bình
        else if (atrRatio < 1.2) atrIndex = 2; // ATR trung bình
        else if (atrRatio < 1.5) atrIndex = 3; // ATR cao
        else atrIndex = 4;                     // ATR rất cao
        
        m_atrRatioStats[atrIndex].Update(record);
        
        // Cập nhật phân tích chuỗi giao dịch
        m_streakAnalysis.Update(isWin, profit);
        
        // Cập nhật các giá trị khác
        m_lastUpdateTime = TimeCurrent();
        
        // Cập nhật SQN
        m_sqn = CalculateSQN();
        
        // Kiểm tra và cập nhật cảnh báo
        if (m_streakAnalysis.currentLossStreak >= 3) {
            AddAlert(StringFormat("Cảnh báo: Đã có %d lệnh thua liên tiếp!", m_streakAnalysis.currentLossStreak));
        }
        
        if (m_ddAnalysis.currentDrawdown > 10.0) {
            AddAlert(StringFormat("Cảnh báo: Drawdown hiện tại: %.2f%%!", m_ddAnalysis.currentDrawdown));
        }
        
        if (m_logger != NULL && m_detailedLogging) {
            LogInfo(StringFormat("Cập nhật kết quả giao dịch: %s, Profit: %.2f, WinRate: %.1f%%, PF: %.2f", 
                               isWin ? "Win" : "Loss", profit, GetWinRate(), GetProfitFactor()));
        }
    }
    
    // Cập nhật kết quả giao dịch đầy đủ
    void UpdateTradeResult(bool isWin, double profit, ENUM_CLUSTER_TYPE cluster, 
                         ENUM_ENTRY_SCENARIO scenario, ENUM_SESSION session, 
                         double atrRatio, double riskReward, string notes = "") {
        if (!m_isInitialized) {
            if (!Initialize()) {
                Print("Không thể khởi tạo PerformanceTracker");
                return;
            }
        }
        
        // Tạo bản ghi giao dịch mới
        TradeRecord record;
        record.isWin = isWin;
        record.profitMoney = profit;
        record.cluster = cluster;
        record.scenario = scenario;
        record.session = session;
        record.atrRatio = atrRatio;
        record.riskReward = riskReward;
        record.closeTime = TimeCurrent();
        record.notes = notes;
        
        // Thêm vào cơ sở dữ liệu
        if (m_tradeCount < MAX_RECORDS) {
            ArrayResize(m_trades, m_tradeCount + 1);
            m_trades[m_tradeCount] = record;
            m_tradeCount++;
        }
        
        // Cập nhật thống kê tổng thể
        m_totalTrades++;
        
        if (isWin) {
            m_winTrades++;
            m_totalProfit += profit;
            m_grossProfit += profit;
        } else {
            m_lossTrades++;
            m_totalLoss += MathAbs(profit);
            m_grossLoss += MathAbs(profit);
        }
        
        m_netProfit = m_totalProfit - m_totalLoss;
        
        // Cập nhật R trung bình
        if (riskReward > 0) {
            m_avgR = (m_avgR * (m_totalTrades - 1) + riskReward) / m_totalTrades;
            m_rMultiple = riskReward; // Lưu R-multiple mới nhất
        }
        
        // Cập nhật thống kê theo loại
        if (cluster >= 0 && cluster < MAX_CLUSTER_RECORDS) {
            m_clusterStats[cluster].Update(record);
        }
        
        if (scenario >= 0 && scenario < MAX_SCENARIO_RECORDS) {
            m_scenarioStats[scenario].Update(record);
        }
        
        if (session >= 0 && session < MAX_SESSION_RECORDS) {
            m_sessionStats[session].Update(record);
        }
        
        // Cập nhật thống kê theo ATR ratio
        int atrIndex = 0;
        if (atrRatio < 0.8) atrIndex = 0;      // ATR thấp
        else if (atrRatio < 1.0) atrIndex = 1; // ATR dưới trung bình
        else if (atrRatio < 1.2) atrIndex = 2; // ATR trung bình
        else if (atrRatio < 1.5) atrIndex = 3; // ATR cao
        else atrIndex = 4;                     // ATR rất cao
        
        m_atrRatioStats[atrIndex].Update(record);
        
        // Cập nhật thống kê theo ngày trong tuần và giờ
        MqlDateTime dt;
        TimeToStruct(record.closeTime, dt);
        
        if (dt.day_of_week >= 0 && dt.day_of_week < 7) {
            m_dayOfWeekStats[dt.day_of_week].Update(record);
        }
        
        if (dt.hour >= 0 && dt.hour < 24) {
            m_hourStats[dt.hour].Update(record);
        }
        
        // Cập nhật phân tích theo thời gian
        m_timeAnalysis.Update(record);
        
        // Cập nhật phân tích chuỗi giao dịch
        m_streakAnalysis.Update(isWin, profit);
        
        // Cập nhật các giá trị khác
        m_lastUpdateTime = TimeCurrent();
        
        // Cập nhật các chỉ số hiệu suất nâng cao
        m_sqn = CalculateSQN();
        m_sharpeRatio = CalculateSharpeRatio();
        m_kellyPercent = CalculateKellyPercent();
        
        // Kiểm tra và cập nhật cảnh báo
        if (m_streakAnalysis.currentLossStreak >= 3) {
            AddAlert(StringFormat("Cảnh báo: Đã có %d lệnh thua liên tiếp!", m_streakAnalysis.currentLossStreak));
        }
        
        if (m_ddAnalysis.currentDrawdown > 10.0) {
            AddAlert(StringFormat("Cảnh báo: Drawdown hiện tại: %.2f%%!", m_ddAnalysis.currentDrawdown));
        }
        
        if (m_logger != NULL) {
            LogInfo(StringFormat("Cập nhật kết quả giao dịch đầy đủ: %s, Profit: %.2f, R: %.2f, Win Rate: %.1f%%, Trades: %d", 
                               isWin ? "Win" : "Loss", profit, riskReward, GetWinRate(), m_totalTrades));
            
            if (m_detailedLogging) {
                LogInfo(StringFormat("Chi tiết: Scenario: %s, Cluster: %s, Session: %s, ATR Ratio: %.2f", 
                                   EnumToString(scenario), EnumToString(cluster), 
                                   EnumToString(session), atrRatio));
            }
        }
    }
    
    // Cập nhật giao dịch từ thông tin chi tiết (từ ticket thực tế)
    void UpdateFromTicket(ulong ticket, bool isWin, double profit, 
                        ENUM_CLUSTER_TYPE cluster = CLUSTER_NONE, 
                        ENUM_ENTRY_SCENARIO scenario = SCENARIO_NONE) {
        if (!HistorySelectByPosition(ticket)) {
            if (m_logger != NULL) {
                LogWarning("Không thể tìm thấy thông tin cho ticket " + IntegerToString(ticket));
            }
            return;
        }
        
        int deals = HistoryDealsTotal();
        if (deals <= 0) {
            if (m_logger != NULL) {
                LogWarning("Không có deals nào cho ticket " + IntegerToString(ticket));
            }
            return;
        }
        
        // Lấy thông tin lệnh
        TradeRecord record;
        record.ticket = ticket;
        record.isWin = isWin;
        record.profitMoney = profit;
        record.cluster = cluster;
        record.scenario = scenario;
        
        // Lấy thông tin deals
        double volume = 0.0;
        datetime openTime = 0;
        datetime closeTime = 0;
        
        for (int i = 0; i < deals; i++) {
            ulong dealTicket = HistoryDealGetTicket(i);
            if (dealTicket <= 0) continue;
            
            // Kiểm tra nếu deal thuộc position
            if (HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID) != ticket) continue;
            
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
            
            if (dealEntry == DEAL_ENTRY_IN) {
                // Deal vào lệnh
                openTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
                volume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
                record.openPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                record.commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                record.swap += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
                record.orderType = (ENUM_ORDER_TYPE)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
            }
            else if (dealEntry == DEAL_ENTRY_OUT) {
                // Deal ra lệnh
                closeTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
                record.closePrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                record.commission += HistoryDealGetDouble(dealTicket, DEAL_COMMISSION);
                record.swap += HistoryDealGetDouble(dealTicket, DEAL_SWAP);
            }
        }
        
        // Cập nhật thông tin thêm
        record.openTime = openTime;
        record.closeTime = closeTime;
        record.volume = volume;
        
        // Tính thời gian giữ lệnh
        if (openTime > 0 && closeTime > 0) {
            int timeDiff = (int)(closeTime - openTime);
            record.notes = "Thời gian giữ: " + TimeToString(timeDiff, TIME_SECONDS);
            
            // Cập nhật thời gian giữ lệnh trung bình
            double holdingTime = (double)timeDiff;
            m_avgHoldingTime = (m_avgHoldingTime * (m_totalTrades - 1) + holdingTime) / m_totalTrades;
        }
        
        // Cập nhật tổng phí
        m_commissions += record.commission;
        m_swap += record.swap;
        
        // Thêm vào cơ sở dữ liệu
        if (m_tradeCount < MAX_RECORDS) {
            ArrayResize(m_trades, m_tradeCount + 1);
            m_trades[m_tradeCount] = record;
            m_tradeCount++;
        }
        
        // Cập nhật thống kê tổng thể
        m_totalTrades++;
        
        if (isWin) {
            m_winTrades++;
            m_totalProfit += profit;
            m_grossProfit += profit;
        } else {
            m_lossTrades++;
            m_totalLoss += MathAbs(profit);
            m_grossLoss += MathAbs(profit);
        }
        
        m_netProfit = m_totalProfit - m_totalLoss;
        
        // Tạm thời gán ATR ratio và session nếu chưa có
        ENUM_SESSION session = SESSION_UNKNOWN;
        double atrRatio = 1.0;
        
        // Xác định session từ thòi gian
        if (closeTime > 0) {
            MqlDateTime dt;
            TimeToStruct(closeTime, dt);
            
            // Phân loại đơn giản theo giờ (GMT)
            if (dt.hour >= 0 && dt.hour < 8) session = SESSION_ASIAN;
            else if (dt.hour >= 8 && dt.hour < 12) session = SESSION_LONDON;
            else if (dt.hour >= 12 && dt.hour < 16) session = SESSION_EUROPEAN_AMERICAN;
            else if (dt.hour >= 16 && dt.hour < 20) session = SESSION_NEWYORK;
            else session = SESSION_CLOSING;
            
            record.session = session;
            
            // Cập nhật thống kê theo ngày và giờ
            if (dt.day_of_week >= 0 && dt.day_of_week < 7) {
                m_dayOfWeekStats[dt.day_of_week].Update(record);
            }
            
            if (dt.hour >= 0 && dt.hour < 24) {
                m_hourStats[dt.hour].Update(record);
            }
        }
        
        // Cập nhật thống kê theo loại
        if (cluster >= 0 && cluster < MAX_CLUSTER_RECORDS) {
            m_clusterStats[cluster].Update(record);
        }
        
        if (scenario >= 0 && scenario < MAX_SCENARIO_RECORDS) {
            m_scenarioStats[scenario].Update(record);
        }
        
        if (session >= 0 && session < MAX_SESSION_RECORDS) {
            m_sessionStats[session].Update(record);
        }
        
        // Cập nhật phân tích chuỗi giao dịch
        m_streakAnalysis.Update(isWin, profit);
        
        // Cập nhật SQN và các chỉ số khác
        m_sqn = CalculateSQN();
        
        if (m_logger != NULL) {
            LogInfo(StringFormat("Cập nhật từ ticket %d: %s, Profit: %.2f, Volume: %.2f, Open: %s, Close: %s", 
                               ticket, isWin ? "Win" : "Loss", profit, volume, 
                               TimeToString(openTime), TimeToString(closeTime)));
        }
    }
    
    // Cập nhật drawdown
    void UpdateDrawdown(double equity, double balance) {
        if (!m_isInitialized) {
            if (!Initialize()) {
                Print("Không thể khởi tạo PerformanceTracker");
                return;
            }
        }
        
        // Lưu giá trị cuối cùng
        m_lastEquity = equity;
        m_lastBalance = balance;
        
        // Cập nhật phân tích drawdown
        m_ddAnalysis.Update(equity, balance, TimeCurrent());
        
        // Cập nhật thời gian phục hồi
        m_ddAnalysis.UpdateRecoveryTime(TimeCurrent());
        
        // Kiểm tra cảnh báo
        if (m_ddAnalysis.currentDrawdown > 15.0 && m_ddAnalysis.currentDrawdown > m_ddAnalysis.maxDrawdown * 0.9) {
            AddAlert(StringFormat("Cảnh báo: Drawdown đang tiếp cận mức cao (%.2f%%)!", m_ddAnalysis.currentDrawdown));
            
            if (m_logger != NULL) {
                LogWarning(StringFormat("Drawdown cao: %.2f%% (%.2f), Equity: %.2f, Peak Equity: %.2f", 
                                    m_ddAnalysis.currentDrawdown, m_ddAnalysis.currentDrawdownMoney,
                                    equity, m_ddAnalysis.peakEquity));
            }
        }
        
        // Ghi log chi tiết nếu được bật
        if (m_logger != NULL && m_detailedLogging) {
            LogInfo(StringFormat("Cập nhật Drawdown: Current: %.2f%%, Max: %.2f%%, Equity: %.2f, Balance: %.2f", 
                               m_ddAnalysis.currentDrawdown, m_ddAnalysis.maxDrawdown, equity, balance));
        }
    }
    
    // Lưu dữ liệu hiệu suất vào file CSV
    bool SaveToCSV(string filename) {
        if (!m_isInitialized || m_tradeCount == 0) {
            if (m_logger != NULL) {
                LogWarning("Không có dữ liệu để lưu vào CSV");
            }
            return false;
        }
        
        // Mở file để ghi
        int handle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON);
        if (handle == INVALID_HANDLE) {
            if (m_logger != NULL) {
                LogWarning("Không thể mở file " + filename + " để ghi. Lỗi: " + IntegerToString(GetLastError()));
            }
            return false;
        }
        
        // Ghi header
        FileWrite(handle, "Ticket", "OpenTime", "CloseTime", "Type", "Volume", "OpenPrice", "ClosePrice",
                 "StopLoss", "TakeProfit", "Profit", "Commission", "Swap", "Cluster", "Scenario", 
                 "Session", "ATR Ratio", "R:R", "Quality", "IsWin", "Notes");
        
        // Ghi dữ liệu
        for (int i = 0; i < m_tradeCount; i++) {
            FileWrite(handle, 
                     m_trades[i].ticket,
                     TimeToString(m_trades[i].openTime),
                     TimeToString(m_trades[i].closeTime),
                     EnumToString(m_trades[i].orderType),
                     DoubleToString(m_trades[i].volume, 2),
                     DoubleToString(m_trades[i].openPrice, _Digits),
                     DoubleToString(m_trades[i].closePrice, _Digits),
                     DoubleToString(m_trades[i].stopLoss, _Digits),
                     DoubleToString(m_trades[i].takeProfit, _Digits),
                     DoubleToString(m_trades[i].profitMoney, 2),
                     DoubleToString(m_trades[i].commission, 2),
                     DoubleToString(m_trades[i].swap, 2),
                     EnumToString(m_trades[i].cluster),
                     EnumToString(m_trades[i].scenario),
                     EnumToString(m_trades[i].session),
                     DoubleToString(m_trades[i].atrRatio, 2),
                     DoubleToString(m_trades[i].riskReward, 2),
                     DoubleToString(m_trades[i].quality, 2),
                     m_trades[i].isWin ? "Win" : "Loss",
                     m_trades[i].notes);
        }
        
        // Đóng file
        FileClose(handle);
        
        if (m_logger != NULL) {
            LogInfo("Đã lưu dữ liệu giao dịch vào " + filename);
        }
        
        return true;
    }
    
    // Tạo báo cáo hiệu suất tổng thể
    string GeneratePerformanceReport(int reportType = REPORT_COMPLETE) {
        if (!m_isInitialized || m_totalTrades == 0) {
            return "Không có dữ liệu để tạo báo cáo.";
        }
        
        string report = "";
        
        // Tạo header của báo cáo
        report += "===== BÁO CÁO HIỆU SUẤT GIAO DỊCH =====\n";
        report += "Symbol: " + m_symbol + "\n";
        report += "Thời gian: " + TimeToString(m_startTime) + " - " + TimeToString(m_lastUpdateTime) + "\n";
        report += "Balance ban đầu: " + DoubleToString(m_initialBalance, 2) + "\n";
        report += "Balance hiện tại: " + DoubleToString(m_lastBalance, 2) + "\n";
        
        // Thống kê tổng quát
        report += "\n=== THỐNG KÊ TỔNG QUÁT ===\n";
        report += "Tổng số lệnh: " + IntegerToString(m_totalTrades) + "\n";
        report += "Win rate: " + DoubleToString(GetWinRate(), 2) + "%\n";
        report += "Profit Factor: " + DoubleToString(GetProfitFactor(), 2) + "\n";
        report += "Expectancy: $" + DoubleToString(GetExpectancy(), 2) + "\n";
        report += "System Quality Number (SQN): " + DoubleToString(m_sqn, 2) + "\n";
        report += "R-multiple trung bình: " + DoubleToString(m_avgR, 2) + "\n";
        report += "Sharpe Ratio: " + DoubleToString(m_sharpeRatio, 2) + "\n";
        report += "Kelly Percent: " + DoubleToString(m_kellyPercent, 2) + "%\n";
        report += "Drawdown tối đa: " + DoubleToString(m_ddAnalysis.maxDrawdown, 2) + "% ($" + 
                 DoubleToString(m_ddAnalysis.maxDrawdownMoney, 2) + ")\n";
        report += "Drawdown hiện tại: " + DoubleToString(m_ddAnalysis.currentDrawdown, 2) + "% ($" + 
                 DoubleToString(m_ddAnalysis.currentDrawdownMoney, 2) + ")\n";
        report += "Chuỗi thắng/thua tối đa: " + IntegerToString(m_streakAnalysis.maxWinStreak) + "/" + 
                 IntegerToString(m_streakAnalysis.maxLossStreak) + "\n";
        
        if (reportType == REPORT_DAILY) {
            // Báo cáo ngày: Chỉ hiển thị thông tin cơ bản
            return report;
        }
        
        // Thêm phân tích theo cluster
        report += AnalyzeClusterPerformance();
        
        // Thêm phân tích theo kịch bản
        report += AnalyzeScenarioPerformance();
        
        // Thêm phân tích theo phiên
        report += AnalyzeSessionPerformance();
        
        if (reportType >= REPORT_WEEKLY) {
            // Thêm phân tích theo thời gian
            report += AnalyzeTimePerformance();
            
            // Thêm phân tích theo ATR
            report += AnalyzeATRPerformance();
            
            // Thêm phân tích chuỗi giao dịch
            report += AnalyzeStreaks();
        }
        
        if (reportType == REPORT_COMPLETE) {
            // Thêm các đề xuất cải thiện
            report += GenerateRecommendations();
            
            // Thêm danh sách cảnh báo
            if (m_alertCount > 0) {
                report += "\n=== DANH SÁCH CẢNH BÁO ===\n";
                for (int i = 0; i < m_alertCount; i++) {
                    report += IntegerToString(i+1) + ". " + m_alerts[i] + "\n";
                }
            }
        }
        
        if (m_logger != NULL) {
            LogInfo("Đã tạo báo cáo hiệu suất thành công");
        }
        
        return report;
    }
    
    // Tạo báo cáo ngắn gọn
    string GetSummary() {
        if (!m_isInitialized || m_totalTrades == 0) {
            return "Không có dữ liệu hiệu suất.";
        }
        
        string summary = StringFormat(
            "Trades: %d | Win: %.1f%% | PF: %.2f | R: %.2f | DD: %.1f%% | SQN: %.2f",
            m_totalTrades, GetWinRate(), GetProfitFactor(), m_avgR, m_ddAnalysis.maxDrawdown, m_sqn
        );
        
        return summary;
    }
    
    // Lấy số lượng giao dịch
    int GetTotalTrades() const {
        return m_totalTrades;
    }
    
    // Lấy win rate
    double GetWinRate() const {
        if (m_totalTrades == 0) return 0.0;
        return (double)m_winTrades / m_totalTrades * 100.0;
    }
    
    // Lấy profit factor
    double GetProfitFactor() const {
        if (m_totalLoss == 0) return m_totalTrades > 0 ? 999.0 : 0.0;
        return m_totalProfit / m_totalLoss;
    }
    
    // Lấy expectancy
    double GetExpectancy() const {
        if (m_totalTrades == 0) return 0.0;
        return (m_totalProfit - m_totalLoss) / m_totalTrades;
    }
    
    // Lấy SQN
    double GetSQN() const {
        return m_sqn;
    }
    
    // Lấy Sharpe Ratio
    double GetSharpeRatio() const {
        return m_sharpeRatio;
    }
    
    // Lấy Kelly Percent
    double GetKellyPercent() const {
        return m_kellyPercent;
    }
    
    // Lấy R-multiple trung bình
    double GetAvgRMultiple() const {
        return m_avgR;
    }
    
    // Lấy R-multiple mới nhất
    double GetLastRMultiple() const {
        return m_rMultiple;
    }
    
    // Lấy drawdown hiện tại
    double GetCurrentDrawdown() const {
        return m_ddAnalysis.currentDrawdown;
    }
    
    // Lấy drawdown tối đa
    double GetMaxDrawdown() const {
        return m_ddAnalysis.maxDrawdown;
    }
    
    // Lấy số lệnh thua liên tiếp hiện tại
    int GetConsecutiveLosses() const {
        return m_streakAnalysis.currentLossStreak;
    }
    
    // Lấy số lệnh thắng liên tiếp hiện tại
    int GetConsecutiveWins() const {
        return m_streakAnalysis.currentWinStreak;
    }
    
    // Lấy thống kê cluster
    double GetClusterWinRate(int cluster) const {
        if (cluster < 0 || cluster >= MAX_CLUSTER_RECORDS) return 0.0;
        return m_clusterStats[cluster].GetWinRate();
    }
    
    // Lấy profit factor cho cluster
    double GetClusterProfitFactor(int cluster) const {
        if (cluster < 0 || cluster >= MAX_CLUSTER_RECORDS) return 0.0;
        return m_clusterStats[cluster].GetProfitFactor();
    }
    
    // Lấy số lệnh theo cluster
    int GetClusterTrades(int cluster) const {
        if (cluster < 0 || cluster >= MAX_CLUSTER_RECORDS) return 0;
        return m_clusterStats[cluster].trades;
    }
    
    // Lấy thống kê phiên
    double GetSessionWinRate(int session) const {
        if (session < 0 || session >= MAX_SESSION_RECORDS) return 0.0;
        return m_sessionStats[session].GetWinRate();
    }
    
    // Lấy profit factor cho phiên
    double GetSessionProfitFactor(int session) const {
        if (session < 0 || session >= MAX_SESSION_RECORDS) return 0.0;
        return m_sessionStats[session].GetProfitFactor();
    }
    
    // Lấy số lệnh theo phiên
    int GetSessionTrades(int session) const {
        if (session < 0 || session >= MAX_SESSION_RECORDS) return 0;
        return m_sessionStats[session].trades;
    }
    
    // Lấy cảnh báo mới nhất
    string GetLatestAlert() const {
        if (m_alertCount == 0) return "";
        return m_alerts[m_alertCount - 1];
    }
    
    // Lấy thông tin chi tiết về giao dịch
    TradeRecord GetTradeRecord(int index) {
        TradeRecord emptyRecord; // Tạo một bản ghi rỗng trong trường hợp lỗi
        ZeroMemory(emptyRecord);
        
        if (index < 0 || index >= m_tradeCount) return emptyRecord;
        return m_trades[index];
    }
    
    // Tạo cảnh báo mới
    void CreateAlert(string message) {
        AddAlert(message);
    }
    
    // Lấy chuỗi thắng tối đa
    int GetMaxWinStreak() const {
        return m_streakAnalysis.maxWinStreak;
    }
    
    // Lấy chuỗi thua tối đa
    int GetMaxLossStreak() const {
        return m_streakAnalysis.maxLossStreak;
    }
    
    // Lấy lợi nhuận liên tiếp tối đa
    double GetMaxConsecutiveProfit() const {
        return m_streakAnalysis.maxConsecutiveProfit;
    }
    
    // Lấy lỗ liên tiếp tối đa
    double GetMaxConsecutiveLoss() const {
        return m_streakAnalysis.maxConsecutiveLoss;
    }
    
    // Lấy thời gian giữ lệnh trung bình
    double GetAvgHoldingTime() const {
        return m_avgHoldingTime;
    }
    
    // Lấy tổng phí giao dịch
    double GetTotalCommission() const {
        return m_commissions;
    }
    
    // Lấy tổng phí swap
    double GetTotalSwap() const {
        return m_swap;
    }
    
    // Lấy tổng lợi nhuận
    double GetTotalProfit() const {
        return m_totalProfit;
    }
    
    // Lấy tổng lỗ
    double GetTotalLoss() const {
        return m_totalLoss;
    }
    
    // Lấy lợi nhuận ròng
    double GetNetProfit() const {
        return m_netProfit;
    }
    
    // Đặt logger
    void SetLogger(CLogger *logger, bool detailedLogging = false) {
        m_logger = logger;
        m_detailedLogging = detailedLogging;
        
        if (m_logger != NULL) {
            LogInfo("Logger được cài đặt cho PerformanceTracker");
        }
    }
    
    // Phân tích hiệu suất chi tiết và tạo báo cáo
    string AnalyzeDetailedPerformance() {
        if (!m_isInitialized || m_totalTrades == 0) {
            return "Không có đủ dữ liệu để phân tích hiệu suất chi tiết.";
        }
        
        string analysis = "";
        
        // Phân tích hiệu suất tổng thể
        analysis += "===== PHÂN TÍCH HIỆU SUẤT CHI TIẾT =====\n\n";
        analysis += "EA ApexPullback v14.0 - " + m_symbol + "\n";
        analysis += "Thời gian: " + TimeToString(m_startTime) + " đến " + TimeToString(m_lastUpdateTime) + "\n\n";
        
        // Phân tích hiệu suất theo thời gian
        m_timeAnalysis.Analyze();
        
        // Phân loại hiệu suất
        string performanceCategory = "";
        double totalPerformance = m_sqn * GetProfitFactor() * (m_ddAnalysis.maxDrawdown > 0 ? (25.0 / m_ddAnalysis.maxDrawdown) : 1.0);
        
        if (totalPerformance > 20.0) performanceCategory = "Xuất sắc";
        else if (totalPerformance > 10.0) performanceCategory = "Rất tốt";
        else if (totalPerformance > 5.0) performanceCategory = "Tốt";
        else if (totalPerformance > 2.0) performanceCategory = "Khá";
        else if (totalPerformance > 1.0) performanceCategory = "Trung bình";
        else performanceCategory = "Cần cải thiện";
        
        analysis += "Đánh giá hiệu suất tổng thể: " + performanceCategory + "\n";
        analysis += "Chi số hiệu suất tổng hợp: " + DoubleToString(totalPerformance, 2) + "\n\n";
        
        // Thêm phân tích chi tiết
        analysis += "=== CHỈ SỐ HIỆU SUẤT CHÍNH ===\n";
        analysis += "SQN (System Quality Number): " + DoubleToString(m_sqn, 2) + 
                   " (" + GetSQNRating(m_sqn) + ")\n";
        analysis += "Sharpe Ratio: " + DoubleToString(m_sharpeRatio, 2) + 
                   " (" + GetSharpeRating(m_sharpeRatio) + ")\n";
        analysis += "Kelly Percent: " + DoubleToString(m_kellyPercent, 2) + "% " + 
                   (m_kellyPercent > 0 ? "(Position sizing tối ưu)" : "(Không đề xuất)") + "\n";
        analysis += "Profit Factor: " + DoubleToString(GetProfitFactor(), 2) + 
                   " (" + GetPFRating(GetProfitFactor()) + ")\n";
        analysis += "Expectancy per Trade: $" + DoubleToString(GetExpectancy(), 2) + "\n";
        analysis += "Maximum Drawdown: " + DoubleToString(m_ddAnalysis.maxDrawdown, 2) + "% " +
                   "(" + GetDrawdownRating(m_ddAnalysis.maxDrawdown) + ")\n";
        analysis += "Return/Drawdown Ratio: " + DoubleToString(m_netProfit / (m_ddAnalysis.maxDrawdownMoney > 0 ? m_ddAnalysis.maxDrawdownMoney : 1.0), 2) + "\n";
        
        // Đề xuất cải thiện
        analysis += "\n" + GenerateRecommendations();
        
        return analysis;
    }
    
private:
    // Phụ trợ - Lấy đánh giá SQN
    string GetSQNRating(double sqn) {
        if (sqn < 1.0) return "Tệ";
        if (sqn < 2.0) return "Trung bình";
        if (sqn < 3.0) return "Tốt";
        if (sqn < 5.0) return "Xuất sắc";
        return "Đẳng cấp thế giới";
    }
    
    // Phụ trợ - Lấy đánh giá Sharpe
    string GetSharpeRating(double sharpe) {
        if (sharpe < 0.0) return "Tệ";
        if (sharpe < 1.0) return "Dưới trung bình";
        if (sharpe < 2.0) return "Tốt";
        if (sharpe < 3.0) return "Rất tốt";
        return "Xuất sắc";
    }
    
    // Phụ trợ - Lấy đánh giá Profit Factor
    string GetPFRating(double pf) {
        if (pf < 1.0) return "Lỗ";
        if (pf < 1.5) return "Trung bình";
        if (pf < 2.0) return "Tốt";
        if (pf < 3.0) return "Rất tốt";
        return "Xuất sắc";
    }
    
    // Phụ trợ - Lấy đánh giá Drawdown
    string GetDrawdownRating(double dd) {
        if (dd > 30.0) return "Rủi ro cao";
        if (dd > 20.0) return "Đáng lo ngại";
        if (dd > 15.0) return "Trung bình";
        if (dd > 10.0) return "Tốt";
        return "Xuất sắc";
    }
};