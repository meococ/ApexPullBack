//+------------------------------------------------------------------+
//|                                         PerformanceTracker.mqh |
//|                          Copyright 2023, Apex Pullback EA Team |
//|                                  https://www.apexpullbackea.com |
//+------------------------------------------------------------------+
#ifndef _PERFORMANCE_TRACKER_MQH_
#define _PERFORMANCE_TRACKER_MQH_

// --- Standard MQL5 Libraries ---
// #include <Trade/AccountInfo.mqh> // For AccountInfo functions if used for balance/equity tracking
// #include <Arrays/ArrayDouble.mqh>  // For m_DailyProfit, m_WeeklyProfit, m_MonthlyProfit if dynamic arrays
// #include <Arrays/ArrayInt.mqh>     // For m_TradesByHour, m_TradesByDay if dynamic arrays
// #include <Files/FileTxt.mqh>     // If SaveReportToFile uses CFileTxt

// --- Custom EA Core Includes ---
// QUAN TRỌNG: Các tệp này định nghĩa các thành phần cốt lõi và nên được include trước các module cụ thể.
// Namespace.mqh nên được include trước khi khai báo namespace.
#include "Namespace.mqh"          // Defines namespaces (e.g., ApexPullback) and related macros
#include "CommonDefinitions.mqh"  // General definitions, possibly macros
#include "Constants.mqh"          // EA-specific constants
#include "Enums.mqh"              // Enumerations (if any are used by this module, e.g. for trade types)
#include "CommonStructs.mqh"      // Common data structures (if any are used, e.g. for trade details)
#include "FunctionDefinitions.mqh"// Global utility functions (if any are used by this module)
#include "MathHelper.mqh"         // Math utility functions (if any are used by this module)

// --- Custom EA Module Includes ---
#include "Logger.mqh"             // Logging facility (CLogger* m_Logger)

// Forward declaration cho CLogger
namespace ApexPullback {
    class CLogger;
}

//+------------------------------------------------------------------+
//| Lớp CPerformanceTracker - Theo dõi hiệu suất giao dịch           |
//+------------------------------------------------------------------+
namespace ApexPullback {

class CPerformanceTracker {
private:
    ApexPullback::CLogger* m_Logger;                    // Logger
    
    // Thống kê tổng quan
    int m_TotalTrades;                   // Tổng số giao dịch
    int m_WinningTrades;                 // Số giao dịch thắng
    int m_LosingTrades;                  // Số giao dịch thua
    int m_BreakEvenTrades;               // Số giao dịch hòa vốn
    
    double m_GrossProfit;                // Lợi nhuận gộp
    double m_GrossLoss;                  // Thua lỗ gộp
    double m_NetProfit;                  // Lợi nhuận ròng
    
    double m_MaxDrawdown;                // Drawdown tối đa
    double m_MaxDrawdownPercent;         // Drawdown tối đa theo %
    
    double m_WinRate;                    // Tỷ lệ thắng
    double m_ProfitFactor;               // Hệ số lợi nhuận
    double m_ExpectedPayoff;             // Kỳ vọng trung bình mỗi giao dịch
    double m_SharpeRatio;                // Tỷ số Sharpe
    
    // Thống kê theo thời gian
    double m_DailyProfit[];              // Lợi nhuận theo ngày
    double m_WeeklyProfit[];             // Lợi nhuận theo tuần
    double m_MonthlyProfit[];            // Lợi nhuận theo tháng
    
    // Phân tích giao dịch
    int m_ConsecutiveWins;               // Số lần thắng liên tiếp
    int m_ConsecutiveLosses;             // Số lần thua liên tiếp
    int m_MaxConsecutiveWins;            // Số lần thắng liên tiếp tối đa
    int m_MaxConsecutiveLosses;          // Số lần thua liên tiếp tối đa
    
    double m_LargestWin;                 // Giao dịch thắng lớn nhất
    double m_LargestLoss;                // Giao dịch thua lớn nhất
    double m_AverageWin;                 // Thắng trung bình
    double m_AverageLoss;                // Thua trung bình
    
    // Phân tích theo thời gian
    int m_TradesByHour[24];              // Số giao dịch theo giờ
    double m_ProfitByHour[24];           // Lợi nhuận theo giờ
    
    int m_TradesByDay[7];                // Số giao dịch theo ngày trong tuần
    double m_ProfitByDay[7];             // Lợi nhuận theo ngày trong tuần
    
public:
    // Constructor và Destructor
    CPerformanceTracker(ApexPullback::CLogger* logger = NULL);
    ~CPerformanceTracker();
    
    // Phương thức
    void Initialize();                   // Khởi tạo
    void Reset();                        // Reset số liệu
    
    // Cập nhật số liệu
    void AddTrade(double profit, datetime openTime, datetime closeTime);
    void UpdateDrawdown(double currentDrawdown, double drawdownPercent);
    
    // Tính toán số liệu
    void CalculateStatistics();          // Tính toán các thông số thống kê
    
    // Xuất báo cáo
    string GetSummaryReport();           // Báo cáo tóm tắt
    string GetDetailedReport();          // Báo cáo chi tiết
    void SaveReportToFile(string fileName); // Lưu báo cáo ra file
    
    // Getter methods
    double GetWinRate() const { return m_WinRate; }
    double GetProfitFactor() const { return m_ProfitFactor; }
    double GetNetProfit() const { return m_NetProfit; }
    double GetMaxDrawdown() const { return m_MaxDrawdown; }
    int GetConsecutiveLosses() const { return m_ConsecutiveLosses; }
    int GetMaxConsecutiveLosses() const { return m_MaxConsecutiveLosses; }
};

} // End namespace ApexPullback

#endif // _PERFORMANCE_TRACKER_MQH_
