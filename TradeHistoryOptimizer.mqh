//+------------------------------------------------------------------+
//|              TradeHistoryOptimizer.mqh - APEX Pullback EA v14.0 |
//|                           Copyright 2023-2024, APEX Forex        |
//|                             https://www.apexpullback.com         |
//+------------------------------------------------------------------+
#pragma once

#include "CommonStructs.mqh"
#include "Enums.mqh"
#include "Logger.mqh"

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Cấu trúc thống kê giao dịch tóm tắt                             |
//+------------------------------------------------------------------+
struct TradeStatsSummary {
    int totalTrades;              // Tổng số giao dịch
    int winningTrades;            // Số giao dịch thắng
    int losingTrades;             // Số giao dịch thua
    double totalProfit;           // Tổng lợi nhuận
    double totalLoss;             // Tổng lỗ
    double winRate;               // Tỷ lệ thắng (%)
    double profitFactor;          // Hệ số lợi nhuận
    double averageWin;            // Lợi nhuận trung bình
    double averageLoss;           // Lỗ trung bình
    double maxWin;                // Lợi nhuận lớn nhất
    double maxLoss;               // Lỗ lớn nhất
    double maxDrawdown;           // Drawdown tối đa
    datetime firstTradeTime;      // Thời gian giao dịch đầu tiên
    datetime lastTradeTime;       // Thời gian giao dịch cuối cùng
    int tradingDays;              // Số ngày giao dịch
    double dailyAverage;          // Lợi nhuận trung bình/ngày
    
    TradeStatsSummary() {
        totalTrades = 0;
        winningTrades = 0;
        losingTrades = 0;
        totalProfit = 0.0;
        totalLoss = 0.0;
        winRate = 0.0;
        profitFactor = 0.0;
        averageWin = 0.0;
        averageLoss = 0.0;
        maxWin = 0.0;
        maxLoss = 0.0;
        maxDrawdown = 0.0;
        firstTradeTime = 0;
        lastTradeTime = 0;
        tradingDays = 0;
        dailyAverage = 0.0;
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc giao dịch đơn giản                                     |
//+------------------------------------------------------------------+
struct SimpleTrade {
    ulong ticket;                 // Ticket giao dịch
    datetime openTime;            // Thời gian mở
    datetime closeTime;           // Thời gian đóng
    double profit;                // Lợi nhuận
    double volume;                // Khối lượng
    string symbol;                // Symbol
    int type;                     // Loại lệnh
    
    SimpleTrade() {
        ticket = 0;
        openTime = 0;
        closeTime = 0;
        profit = 0.0;
        volume = 0.0;
        symbol = "";
        type = -1;
    }
};

//+------------------------------------------------------------------+
//| Lớp tối ưu hóa phân tích lịch sử giao dịch                      |
//+------------------------------------------------------------------+
// Cấu trúc lưu trữ ma trận hiệu suất
struct PerformanceMatrix {
    // Key: Một chuỗi kết hợp, ví dụ: "STRATEGY_PULLBACK_TREND|REGIME_TRENDING_BULL"
    // Value: Con trỏ đến một đối tượng TradeStatsSummary
    // Chúng ta sẽ sử dụng một CMapStringToString hoặc tương tự để đơn giản hóa
    // Hoặc một mảng struct nếu số lượng trạng thái là cố định
    TradeStatsSummary stats[ENUM_TRADING_STRATEGY_COUNT][ENUM_MARKET_REGIME_COUNT];

    void Initialize() {
        for(int i = 0; i < ENUM_TRADING_STRATEGY_COUNT; i++) {
            for(int j = 0; j < ENUM_MARKET_REGIME_COUNT; j++) {
                stats[i][j] = TradeStatsSummary(); // Reset bằng constructor
            }
        }
    }
};

class CTradeHistoryOptimizer {
private:
    EAContext* m_context; // << CON TRỎ NGỮ CẢNH EA
    CLogger* m_Logger;
    bool m_EnableOptimization;
    int m_MaxTradesAnalyze;       // Số giao dịch tối đa phân tích
    int m_MaxDaysAnalyze;         // Số ngày tối đa phân tích
    bool m_QuickAnalysisMode;     // Chế độ phân tích nhanh
    bool m_CacheResults;          // Cache kết quả
    string m_CacheFile;           // File cache
    
    SimpleTrade m_RecentTrades[]; // Giao dịch gần đây
    TradeStatsSummary m_CachedStats; // Thống kê đã cache
    datetime m_LastCacheUpdate;   // Lần cập nhật cache cuối
    
public:
    CTradeHistoryOptimizer();
    ~CTradeHistoryOptimizer();
    
    bool Initialize(EAContext* context, bool enableOptimization = true); // << THAY ĐỔI SIGNATURE
    
    // Hàm phân tích chính mới
    bool AnalyzePerformanceByContext(PerformanceMatrix &matrix);

private:
    // Hàm helper để xác định context của một giao dịch
    bool GetTradeContext(ulong ticket, ENUM_TRADING_STRATEGY &strategy, ENUM_MARKET_REGIME &regime);
    void UpdateStats(TradeStatsSummary &stats, double profit);

    void Cleanup();
    
    // Main analysis functions
    bool LoadTradeHistoryOptimized(int maxTrades = 1000, int maxDays = 30);
    TradeStatsSummary GetTradeStatistics(bool forceRefresh = false);
    bool AnalyzeRecentPerformance(int days = 7);
    
    // Configuration
    void SetMaxTradesAnalyze(int maxTrades) { m_MaxTradesAnalyze = maxTrades; }
    void SetMaxDaysAnalyze(int maxDays) { m_MaxDaysAnalyze = maxDays; }
    void EnableQuickMode(bool enable = true) { m_QuickAnalysisMode = enable; }
    void EnableCaching(bool enable = true) { m_CacheResults = enable; }
    
    // Utility functions
    int GetRecentTradeCount() { return ArraySize(m_RecentTrades); }
    double GetRecentProfitFactor(int days = 7);
    double GetRecentWinRate(int days = 7);
    bool IsPerformanceImproving(int compareDays = 14);
    
    // Cache management
    bool SaveStatsToCache();
    bool LoadStatsFromCache();
    void ClearCache();
    bool IsCacheValid(int maxAgeMinutes = 60);
    
private:
    bool LoadTradesFromHistory(datetime fromDate, datetime toDate, int maxTrades);
    bool LoadTradesQuick(int maxTrades);
    void CalculateStatistics();
    bool FilterTradesByMagicNumber(int magicNumber);
    bool FilterTradesBySymbol(string symbol);
    void SortTradesByTime();
    double CalculateDrawdown();
    void LogAnalysisProgress(int processed, int total);
    string GetCacheFileName();
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeHistoryOptimizer::CTradeHistoryOptimizer() {
    m_context = NULL;
    m_Logger = NULL;
    m_EnableOptimization = true;
    m_MaxTradesAnalyze = 1000;
    m_MaxDaysAnalyze = 30;
    m_QuickAnalysisMode = true;
    m_CacheResults = true;
    m_CacheFile = "trade_stats_cache.dat";
    m_LastCacheUpdate = 0;
    
    ArrayResize(m_RecentTrades, 0);
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeHistoryOptimizer::~CTradeHistoryOptimizer() {
    Cleanup();
}

//+------------------------------------------------------------------+
//| Khởi tạo TradeHistoryOptimizer                                  |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::Initialize(EAContext* context, bool enableOptimization = true) {
    m_context = context;
    if (m_context != NULL) {
        m_Logger = m_context->Logger;
    } else {
        // Xử lý lỗi nếu context là NULL
        printf("Error: EAContext is NULL in CTradeHistoryOptimizer::Initialize");
        return false;
    }

    m_EnableOptimization = enableOptimization;
    
    if (m_Logger) {
        m_Logger->LogInfo(StringFormat("TradeHistoryOptimizer initialized - Optimization: %s, MaxTrades: %d, MaxDays: %d",
            m_EnableOptimization ? "Enabled" : "Disabled", m_MaxTradesAnalyze, m_MaxDaysAnalyze));
    }
    
    // Thử load cache nếu có
    if (m_CacheResults && IsCacheValid()) {
        LoadStatsFromCache();
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Dọn dẹp tài nguyên                                              |
//+------------------------------------------------------------------+
void CTradeHistoryOptimizer::Cleanup() {
    // Lưu cache trước khi thoát
    if (m_CacheResults && ArraySize(m_RecentTrades) > 0) {
        SaveStatsToCache();
    }
    
    ArrayFree(m_RecentTrades);
    
    if (m_Logger) {
        m_Logger->LogInfo("TradeHistoryOptimizer cleanup completed");
    }
}

//+------------------------------------------------------------------+
//| Tải lịch sử giao dịch tối ưu                                    |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::LoadTradeHistoryOptimized(int maxTrades = 1000, int maxDays = 30) {
    if (!m_EnableOptimization) {
        if (m_Logger) {
            m_Logger->LogInfo("Trade history optimization disabled, using full analysis");
        }
        return LoadTradesFromHistory(0, TimeCurrent(), 0); // Load all
    }
    
    // Cập nhật giới hạn
    m_MaxTradesAnalyze = maxTrades;
    m_MaxDaysAnalyze = maxDays;
    
    // Kiểm tra cache trước
    if (m_CacheResults && IsCacheValid()) {
        if (m_Logger) {
            m_Logger->LogInfo("Using cached trade statistics");
        }
        return true;
    }
    
    datetime startTime = GetTickCount();
    bool success = false;
    
    if (m_QuickAnalysisMode) {
        // Chế độ nhanh: chỉ load số lượng giao dịch giới hạn
        success = LoadTradesQuick(maxTrades);
    } else {
        // Chế độ đầy đủ nhưng có giới hạn thời gian
        datetime fromDate = TimeCurrent() - (maxDays * 24 * 3600);
        success = LoadTradesFromHistory(fromDate, TimeCurrent(), maxTrades);
    }
    
    if (success) {
        CalculateStatistics();
        
        if (m_CacheResults) {
            SaveStatsToCache();
        }
        
        uint elapsed = GetTickCount() - startTime;
        if (m_Logger) {
            m_Logger->LogInfo(StringFormat("Trade history analysis completed in %d ms, %d trades analyzed",
                elapsed, ArraySize(m_RecentTrades)));
        }
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Lấy thống kê giao dịch                                          |
//+------------------------------------------------------------------+
TradeStatsSummary CTradeHistoryOptimizer::GetTradeStatistics(bool forceRefresh = false) {
    if (forceRefresh || m_CachedStats.totalTrades == 0) {
        CalculateStatistics();
    }
    
    return m_CachedStats;
}

//+------------------------------------------------------------------+
//| Phân tích hiệu suất gần đây                                     |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::AnalyzeRecentPerformance(int days = 7) {
    datetime cutoffTime = TimeCurrent() - (days * 24 * 3600);
    
    int recentTrades = 0;
    double recentProfit = 0.0;
    int recentWins = 0;
    
    for (int i = 0; i < ArraySize(m_RecentTrades); i++) {
        if (m_RecentTrades[i].closeTime >= cutoffTime) {
            recentTrades++;
            recentProfit += m_RecentTrades[i].profit;
            if (m_RecentTrades[i].profit > 0) {
                recentWins++;
            }
        }
    }
    
    if (m_Logger && recentTrades > 0) {
        double recentWinRate = (double)recentWins / recentTrades * 100.0;
        m_Logger->LogInfo(StringFormat("Recent %d days: %d trades, %.2f profit, %.1f%% win rate",
            days, recentTrades, recentProfit, recentWinRate));
    }
    
    return recentTrades > 0;
}

//+------------------------------------------------------------------+
//| Lấy Profit Factor gần đây                                       |
//+------------------------------------------------------------------+
double CTradeHistoryOptimizer::GetRecentProfitFactor(int days = 7) {
    datetime cutoffTime = TimeCurrent() - (days * 24 * 3600);
    
    double totalProfit = 0.0;
    double totalLoss = 0.0;
    
    for (int i = 0; i < ArraySize(m_RecentTrades); i++) {
        if (m_RecentTrades[i].closeTime >= cutoffTime) {
            if (m_RecentTrades[i].profit > 0) {
                totalProfit += m_RecentTrades[i].profit;
            } else {
                totalLoss += MathAbs(m_RecentTrades[i].profit);
            }
        }
    }
    
    return totalLoss > 0 ? totalProfit / totalLoss : 0.0;
}

//+------------------------------------------------------------------+
//| Lấy Win Rate gần đây                                            |
//+------------------------------------------------------------------+
double CTradeHistoryOptimizer::GetRecentWinRate(int days = 7) {
    datetime cutoffTime = TimeCurrent() - (days * 24 * 3600);
    
    int totalTrades = 0;
    int winningTrades = 0;
    
    for (int i = 0; i < ArraySize(m_RecentTrades); i++) {
        if (m_RecentTrades[i].closeTime >= cutoffTime) {
            totalTrades++;
            if (m_RecentTrades[i].profit > 0) {
                winningTrades++;
            }
        }
    }
    
    return totalTrades > 0 ? (double)winningTrades / totalTrades * 100.0 : 0.0;
}

//+------------------------------------------------------------------+
//| Kiểm tra hiệu suất có cải thiện không                          |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::IsPerformanceImproving(int compareDays = 14) {
    int halfPeriod = compareDays / 2;
    
    double recentPF = GetRecentProfitFactor(halfPeriod);
    
    // Tính PF của nửa thời kỳ trước đó
    datetime recentStart = TimeCurrent() - (halfPeriod * 24 * 3600);
    datetime olderStart = recentStart - (halfPeriod * 24 * 3600);
    
    double olderProfit = 0.0;
    double olderLoss = 0.0;
    
    for (int i = 0; i < ArraySize(m_RecentTrades); i++) {
        if (m_RecentTrades[i].closeTime >= olderStart && m_RecentTrades[i].closeTime < recentStart) {
            if (m_RecentTrades[i].profit > 0) {
                olderProfit += m_RecentTrades[i].profit;
            } else {
                olderLoss += MathAbs(m_RecentTrades[i].profit);
            }
        }
    }
    
    double olderPF = olderLoss > 0 ? olderProfit / olderLoss : 0.0;
    
    return recentPF > olderPF;
}

//+------------------------------------------------------------------+
//| Lưu thống kê vào cache                                          |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::SaveStatsToCache() {
    string filename = GetCacheFileName();
    
    int handle = FileOpen(filename, FILE_WRITE | FILE_BIN | FILE_COMMON);
    if (handle == INVALID_HANDLE) {
        return false;
    }
    
    // Ghi header
    FileWriteInteger(handle, 20241201); // Version
    FileWriteLong(handle, TimeCurrent()); // Cache time
    
    // Ghi thống kê
    FileWriteInteger(handle, m_CachedStats.totalTrades);
    FileWriteInteger(handle, m_CachedStats.winningTrades);
    FileWriteInteger(handle, m_CachedStats.losingTrades);
    FileWriteDouble(handle, m_CachedStats.totalProfit);
    FileWriteDouble(handle, m_CachedStats.totalLoss);
    FileWriteDouble(handle, m_CachedStats.winRate);
    FileWriteDouble(handle, m_CachedStats.profitFactor);
    FileWriteDouble(handle, m_CachedStats.maxDrawdown);
    FileWriteLong(handle, m_CachedStats.firstTradeTime);
    FileWriteLong(handle, m_CachedStats.lastTradeTime);
    
    // Ghi một số giao dịch gần đây (tối đa 100)
    int tradesToSave = MathMin(ArraySize(m_RecentTrades), 100);
    FileWriteInteger(handle, tradesToSave);
    
    for (int i = 0; i < tradesToSave; i++) {
        FileWriteLong(handle, m_RecentTrades[i].ticket);
        FileWriteLong(handle, m_RecentTrades[i].closeTime);
        FileWriteDouble(handle, m_RecentTrades[i].profit);
    }
    
    FileClose(handle);
    m_LastCacheUpdate = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Tải thống kê từ cache                                           |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::LoadStatsFromCache() {
    string filename = GetCacheFileName();
    
    if (!FileIsExist(filename, FILE_COMMON)) {
        return false;
    }
    
    int handle = FileOpen(filename, FILE_READ | FILE_BIN | FILE_COMMON);
    if (handle == INVALID_HANDLE) {
        return false;
    }
    
    // Đọc header
    int version = FileReadInteger(handle);
    if (version != 20241201) {
        FileClose(handle);
        return false; // Version không khớp
    }
    
    m_LastCacheUpdate = (datetime)FileReadLong(handle);
    
    // Đọc thống kê
    m_CachedStats.totalTrades = FileReadInteger(handle);
    m_CachedStats.winningTrades = FileReadInteger(handle);
    m_CachedStats.losingTrades = FileReadInteger(handle);
    m_CachedStats.totalProfit = FileReadDouble(handle);
    m_CachedStats.totalLoss = FileReadDouble(handle);
    m_CachedStats.winRate = FileReadDouble(handle);
    m_CachedStats.profitFactor = FileReadDouble(handle);
    m_CachedStats.maxDrawdown = FileReadDouble(handle);
    m_CachedStats.firstTradeTime = (datetime)FileReadLong(handle);
    m_CachedStats.lastTradeTime = (datetime)FileReadLong(handle);
    
    // Đọc giao dịch
    int tradesCount = FileReadInteger(handle);
    ArrayResize(m_RecentTrades, tradesCount);
    
    for (int i = 0; i < tradesCount; i++) {
        m_RecentTrades[i].ticket = FileReadLong(handle);
        m_RecentTrades[i].closeTime = (datetime)FileReadLong(handle);
        m_RecentTrades[i].profit = FileReadDouble(handle);
    }
    
    FileClose(handle);
    
    if (m_Logger) {
        m_Logger->LogInfo(StringFormat("Loaded cached trade statistics: %d trades, PF: %.2f",
            m_CachedStats.totalTrades, m_CachedStats.profitFactor));
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Xóa cache                                                        |
//+------------------------------------------------------------------+
void CTradeHistoryOptimizer::ClearCache() {
    string filename = GetCacheFileName();
    if (FileIsExist(filename, FILE_COMMON)) {
        FileDelete(filename, FILE_COMMON);
    }
    m_LastCacheUpdate = 0;
}

//+------------------------------------------------------------------+
//| Phân tích hiệu suất dựa trên bối cảnh (Chiến lược/Chế độ)      |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::AnalyzePerformanceByContext(PerformanceMatrix &matrix) {
    if (!m_context || !m_Logger) {
        printf("CTradeHistoryOptimizer not initialized properly!");
        return false;
    }

    m_Logger->LogInfo("Starting performance analysis by context...");
    matrix.Initialize(); // Reset ma trận thống kê

    // Chọn toàn bộ lịch sử cho phân tích này
    if (!HistorySelect(0, TimeCurrent())) {
        m_Logger->LogError("Failed to select trade history!");
        return false;
    }

    int totalDeals = HistoryDealsTotal();
    ulong ticket = 0;
    
    for (int i = 0; i < totalDeals; i++) {
        ticket = HistoryDealGetTicket(i);
        if (ticket == 0) continue;

        // Chỉ xử lý các giao dịch "out" (đóng vị thế)
        if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) {
            continue;
        }

        // Lọc theo magic number của EA
        if (HistoryDealGetInteger(ticket, DEAL_MAGIC) != m_context->MagicNumber) {
            continue;
        }

        ENUM_TRADING_STRATEGY strategy = STRATEGY_UNDEFINED;
        ENUM_MARKET_REGIME regime = REGIME_UNDEFINED;

        if (GetTradeContext(ticket, strategy, regime)) {
            if (strategy != STRATEGY_UNDEFINED && regime != REGIME_UNDEFINED) {
                double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                UpdateStats(matrix.stats[strategy][regime], profit);
            }
        }
    }

    m_Logger->LogInfo("Performance analysis by context finished.");
    return true;
}

//+------------------------------------------------------------------+
//| Lấy bối cảnh của một giao dịch (từ comment)                     |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::GetTradeContext(ulong ticket, ENUM_TRADING_STRATEGY &strategy, ENUM_MARKET_REGIME &regime) {
    string comment = HistoryDealGetString(ticket, DEAL_COMMENT);
    if (comment == "") return false;

    // Đây là một ví dụ giả định. Cần một định dạng comment chuẩn.
    // Ví dụ comment: "[APEX_PB_TREND][REG_TREND_BULL] Entry"
    if (StringFind(comment, "APEX_PB_TREND") != -1) {
        strategy = STRATEGY_PULLBACK_TREND;
    } else if (StringFind(comment, "APEX_MEAN_REV") != -1) {
        strategy = STRATEGY_MEAN_REVERSION;
    } // ... thêm các chiến lược khác

    if (StringFind(comment, "REG_TREND_BULL") != -1) {
        regime = REGIME_TRENDING_BULL;
    } else if (StringFind(comment, "REG_TREND_BEAR") != -1) {
        regime = REGIME_TRENDING_BEAR;
    } else if (StringFind(comment, "REG_RANGING") != -1) {
        regime = REGIME_RANGING;
    } // ... thêm các chế độ khác

    return (strategy != STRATEGY_UNDEFINED && regime != REGIME_UNDEFINED);
}

//+------------------------------------------------------------------+
//| Cập nhật thống kê cho một danh mục                              |
//+------------------------------------------------------------------+
void CTradeHistoryOptimizer::UpdateStats(TradeStatsSummary &stats, double profit) {
    stats.totalTrades++;
    if (profit > 0) {
        stats.winningTrades++;
        stats.totalProfit += profit;
        if (profit > stats.maxWin) stats.maxWin = profit;
    } else {
        stats.losingTrades++;
        stats.totalLoss += profit; // profit đã là số âm
        if (profit < stats.maxLoss) stats.maxLoss = profit;
    }

    // Cập nhật các chỉ số khác sau khi vòng lặp kết thúc
    if (stats.totalTrades > 0) {
        stats.winRate = (double)stats.winningTrades / stats.totalTrades * 100.0;
    }
    if (stats.totalLoss != 0) {
        stats.profitFactor = MathAbs(stats.totalProfit / stats.totalLoss);
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra cache có hợp lệ không                                  |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::IsCacheValid(int maxAgeMinutes = 60) {
    if (m_LastCacheUpdate == 0) {
        return false;
    }
    
    return (TimeCurrent() - m_LastCacheUpdate) < (maxAgeMinutes * 60);
}

//+------------------------------------------------------------------+
//| Tải giao dịch từ lịch sử                                        |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::LoadTradesFromHistory(datetime fromDate, datetime toDate, int maxTrades) {
    if (!HistorySelect(fromDate, toDate)) {
        if (m_Logger) {
            m_Logger->LogError("Failed to select history range");
        }
        return false;
    }
    
    int totalDeals = HistoryDealsTotal();
    if (totalDeals == 0) {
        if (m_Logger) {
            m_Logger->LogInfo("No deals found in history range");
        }
        return true;
    }
    
    // Giới hạn số lượng nếu cần
    int dealsToProcess = (maxTrades > 0) ? MathMin(totalDeals, maxTrades) : totalDeals;
    
    ArrayResize(m_RecentTrades, 0);
    ArrayResize(m_RecentTrades, dealsToProcess);
    
    int validTrades = 0;
    
    for (int i = totalDeals - 1; i >= totalDeals - dealsToProcess; i--) {
        ulong ticket = HistoryDealGetTicket(i);
        if (ticket == 0) continue;
        
        // Chỉ lấy deals đóng lệnh
        if (HistoryDealGetInteger(ticket, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;
        
        m_RecentTrades[validTrades].ticket = ticket;
        m_RecentTrades[validTrades].closeTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
        m_RecentTrades[validTrades].profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
        m_RecentTrades[validTrades].volume = HistoryDealGetDouble(ticket, DEAL_VOLUME);
        m_RecentTrades[validTrades].symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
        m_RecentTrades[validTrades].type = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);
        
        validTrades++;
        
        // Log progress cho các tập dữ liệu lớn
        if (dealsToProcess > 1000 && (validTrades % 500) == 0) {
            LogAnalysisProgress(validTrades, dealsToProcess);
        }
    }
    
    ArrayResize(m_RecentTrades, validTrades);
    SortTradesByTime();
    
    return true;
}

//+------------------------------------------------------------------+
//| Tải giao dịch nhanh                                             |
//+------------------------------------------------------------------+
bool CTradeHistoryOptimizer::LoadTradesQuick(int maxTrades) {
    // Chỉ lấy 30 ngày gần nhất để tăng tốc
    datetime fromDate = TimeCurrent() - (30 * 24 * 3600);
    return LoadTradesFromHistory(fromDate, TimeCurrent(), maxTrades);
}

//+------------------------------------------------------------------+
//| Tính toán thống kê                                              |
//+------------------------------------------------------------------+
void CTradeHistoryOptimizer::CalculateStatistics() {
    int tradesCount = ArraySize(m_RecentTrades);
    if (tradesCount == 0) {
        return;
    }
    
    // Reset stats
    m_CachedStats.totalTrades = tradesCount;
    m_CachedStats.winningTrades = 0;
    m_CachedStats.losingTrades = 0;
    m_CachedStats.totalProfit = 0.0;
    m_CachedStats.totalLoss = 0.0;
    m_CachedStats.maxWin = 0.0;
    m_CachedStats.maxLoss = 0.0;
    
    double winSum = 0.0;
    double lossSum = 0.0;
    
    // Tính toán cơ bản
    for (int i = 0; i < tradesCount; i++) {
        double profit = m_RecentTrades[i].profit;
        
        if (profit > 0) {
            m_CachedStats.winningTrades++;
            m_CachedStats.totalProfit += profit;
            winSum += profit;
            if (profit > m_CachedStats.maxWin) {
                m_CachedStats.maxWin = profit;
            }
        } else if (profit < 0) {
            m_CachedStats.losingTrades++;
            m_CachedStats.totalLoss += MathAbs(profit);
            lossSum += MathAbs(profit);
            if (MathAbs(profit) > m_CachedStats.maxLoss) {
                m_CachedStats.maxLoss = MathAbs(profit);
            }
        }
        
        // Thời gian
        if (i == 0 || m_RecentTrades[i].closeTime < m_CachedStats.firstTradeTime) {
            m_CachedStats.firstTradeTime = m_RecentTrades[i].closeTime;
        }
        if (i == 0 || m_RecentTrades[i].closeTime > m_CachedStats.lastTradeTime) {
            m_CachedStats.lastTradeTime = m_RecentTrades[i].closeTime;
        }
    }
    
    // Tính toán các chỉ số
    m_CachedStats.winRate = (double)m_CachedStats.winningTrades / tradesCount * 100.0;
    m_CachedStats.profitFactor = (m_CachedStats.totalLoss > 0) ? m_CachedStats.totalProfit / m_CachedStats.totalLoss : 0.0;
    m_CachedStats.averageWin = (m_CachedStats.winningTrades > 0) ? winSum / m_CachedStats.winningTrades : 0.0;
    m_CachedStats.averageLoss = (m_CachedStats.losingTrades > 0) ? lossSum / m_CachedStats.losingTrades : 0.0;
    
    // Tính số ngày giao dịch
    if (m_CachedStats.lastTradeTime > m_CachedStats.firstTradeTime) {
        m_CachedStats.tradingDays = (int)((m_CachedStats.lastTradeTime - m_CachedStats.firstTradeTime) / (24 * 3600));
        if (m_CachedStats.tradingDays > 0) {
            m_CachedStats.dailyAverage = (m_CachedStats.totalProfit - m_CachedStats.totalLoss) / m_CachedStats.tradingDays;
        }
    }
    
    // Tính drawdown
    m_CachedStats.maxDrawdown = CalculateDrawdown();
}

//+------------------------------------------------------------------+
//| Sắp xếp giao dịch theo thời gian                                |
//+------------------------------------------------------------------+
void CTradeHistoryOptimizer::SortTradesByTime() {
    int count = ArraySize(m_RecentTrades);
    if (count <= 1) return;
    
    // Simple bubble sort cho dữ liệu nhỏ
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (m_RecentTrades[j].closeTime > m_RecentTrades[j + 1].closeTime) {
                SimpleTrade temp = m_RecentTrades[j];
                m_RecentTrades[j] = m_RecentTrades[j + 1];
                m_RecentTrades[j + 1] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Tính toán Drawdown                                              |
//+------------------------------------------------------------------+
double CTradeHistoryOptimizer::CalculateDrawdown() {
    int count = ArraySize(m_RecentTrades);
    if (count == 0) return 0.0;
    
    double runningBalance = 0.0;
    double peak = 0.0;
    double maxDrawdown = 0.0;
    
    for (int i = 0; i < count; i++) {
        runningBalance += m_RecentTrades[i].profit;
        
        if (runningBalance > peak) {
            peak = runningBalance;
        }
        
        double currentDrawdown = peak - runningBalance;
        if (currentDrawdown > maxDrawdown) {
            maxDrawdown = currentDrawdown;
        }
    }
    
    return maxDrawdown;
}

//+------------------------------------------------------------------+
//| Log tiến trình phân tích                                        |
//+------------------------------------------------------------------+


// Hàm trợ giúp để xác định chế độ thị trường tại một thời điểm cụ thể
// Đây là một phiên bản giả định, cần được triển khai đầy đủ hơn
// Implementation using ADX to determine market regime.
ENUM_MARKET_REGIME GetMarketRegimeAtTime(const EAContext* context, datetime time) {
    if (context == NULL || context->Logger == NULL) {
        // Cannot log if context or logger is NULL
        return REGIME_UNDEFINED;
    }

    // Define ADX parameters - assuming ADXPeriod is available in context.
    int adxPeriod = (context->ADXPeriod > 0) ? context->ADXPeriod : 14;
    double adxThreshold = 25.0;

    // Get the index for the given time
    int barIndex = iBarShift(context->Symbol, context->Timeframe, time);
    if (barIndex < 0) {
        context->Logger->LogWarning("Could not find bar for the specified time.");
        return REGIME_UNDEFINED;
    }

    // Get ADX handle
    int adxHandle = iADX(context->Symbol, context->Timeframe, adxPeriod);
    if(adxHandle == INVALID_HANDLE) {
        context->Logger->LogWarning("Failed to create ADX indicator handle.");
        return REGIME_UNDEFINED;
    }

    // Get ADX value
    double adxValue[1];
    if (CopyBuffer(adxHandle, 0, barIndex, 1, adxValue) <= 0) {
        context->Logger->LogWarning("Failed to get ADX value.");
        return REGIME_UNDEFINED;
    }

    // Determine regime
    if (adxValue[0] > adxThreshold) {
        // Trending market. Now determine if it's bull or bear.
        double plusDI[1], minusDI[1];
        if (CopyBuffer(adxHandle, 1, barIndex, 1, plusDI) <= 0 ||
            CopyBuffer(adxHandle, 2, barIndex, 1, minusDI) <= 0) {
            context->Logger->LogWarning("Failed to get +DI/-DI values.");
            return REGIME_TRENDING; // Fallback to general trending
        }

        if (plusDI[0] > minusDI[0]) {
            return REGIME_TRENDING_BULL;
        } else {
            return REGIME_TRENDING_BEAR;
        }
    } else {
        // Ranging market. Now determine volatility.
        // For simplicity, we'll just classify as stable ranging for now.
        // A more complex implementation could use Bollinger Bands width.
        return REGIME_RANGING_STABLE;
    }
}

// Hàm chính để phân tích hiệu suất
bool CTradeHistoryOptimizer::AnalyzePerformanceByContext(PerformanceMatrix &matrix) {
    if (m_context == NULL || m_Logger == NULL) return false;

    m_Logger->LogInfo("Starting performance analysis by context...");

    // 1. Tải lịch sử giao dịch
    if (!LoadTradeHistoryOptimized(m_MaxTradesAnalyze, m_MaxDaysAnalyze)) {
        m_Logger->LogError("Failed to load trade history for analysis.");
        return false;
    }

    int totalTrades = GetRecentTradeCount();
    if (totalTrades == 0) {
        m_Logger->LogWarning("No trades found in history to analyze.");
        return true; // Không phải lỗi, chỉ là không có dữ liệu
    }

    // 2. Khởi tạo ma trận
    matrix.Initialize();

    // 3. Lặp qua từng giao dịch
    for (int i = 0; i < totalTrades; i++) {
        SimpleTrade &trade = m_RecentTrades[i];

        datetime tradeTime = trade.closeTime; // Use close time for analysis
         if (!HistorySelect(trade.ticket, SYMBOL_GROUP_ALL, 0, TimeCurrent())) continue;
         long deal_ticket = HistoryDealGetTicket(0);
         if(deal_ticket <= 0) continue;

         string comment = HistoryDealGetString(deal_ticket, DEAL_COMMENT);
         long magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
        
        // Giả sử bạn có một hàm để phân tích comment ra chiến lược
        ENUM_TRADING_STRATEGY strategy = STRATEGY_PULLBACK_TREND; // << GIẢ ĐỊNH

        // Xác định chế độ thị trường tại thời điểm mở lệnh
        ENUM_MARKET_REGIME regime = GetMarketRegimeAtTime(tradeTime);

        if (strategy == STRATEGY_UNDEFINED || regime == REGIME_UNDEFINED) {
            continue; // Bỏ qua nếu không xác định được
        }

        // 4. Cập nhật thống kê trong ma trận
        TradeStatsSummary &stats = matrix.stats[strategy][regime];
        stats.totalTrades++;
        if (trade.profit > 0) {
            stats.winningTrades++;
            stats.totalProfit += trade.profit;
            if(trade.profit > stats.maxWin) stats.maxWin = trade.profit;
        } else if (trade.profit < 0) {
            stats.losingTrades++;
            stats.totalLoss += trade.profit; // profit is already negative
             if(trade.profit < stats.maxLoss) stats.maxLoss = trade.profit;
        }
    }

    // 5. Tính toán các chỉ số phái sinh (WinRate, ProfitFactor, v.v.)
    for (int i = 0; i < ENUM_TRADING_STRATEGY_COUNT; i++) {
        for (int j = 0; j < ENUM_MARKET_REGIME_COUNT; j++) {
            TradeStatsSummary &stats = matrix.stats[i][j];
            if (stats.totalTrades > 0) {
                stats.winRate = (double)stats.winningTrades / stats.totalTrades * 100.0;
                double totalLossAbs = MathAbs(stats.totalLoss);
                 stats.profitFactor = (totalLossAbs > 0) ? stats.totalProfit / totalLossAbs : 0;
                stats.averageWin = (stats.winningTrades > 0) ? stats.totalProfit / stats.winningTrades : 0;
                stats.averageLoss = (stats.losingTrades > 0) ? stats.totalLoss / stats.losingTrades : 0;
                // Tính Expectancy (ví dụ: (WinRate * AvgWin) - (LossRate * AvgLoss))
            }
        }
    }

    m_Logger->LogInfo("Performance analysis by context finished.");
    // Có thể thêm log chi tiết kết quả ma trận ở đây nếu cần

    return true;
}

void CTradeHistoryOptimizer::LogAnalysisProgress(int processed, int total) {
    if (m_Logger) {
        double percent = (double)processed / total * 100.0;
        m_Logger->LogInfo(StringFormat("Trade analysis progress: %d/%d (%.1f%%)", processed, total, percent));
    }
}

//+------------------------------------------------------------------+
//| Lấy tên file cache                                              |
//+------------------------------------------------------------------+
string CTradeHistoryOptimizer::GetCacheFileName() {
    return "TradeStats_" + IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)) + "_" + m_CacheFile;
}

} // namespace ApexPullback

#endif // TRADE_HISTORY_OPTIMIZER_MQH