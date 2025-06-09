//+------------------------------------------------------------------+
//|                                               AssetProfiler.mqh   |
//|                         APEX Pullback EA v14.0 - Self-Learning   |
//+------------------------------------------------------------------+

#ifndef ASSET_PROFILER_MQH_
#define ASSET_PROFILER_MQH_

#include "CommonStructs.mqh"
#include "Constants.mqh"
#include "Enums.mqh"
#include "Logger.mqh"

namespace ApexPullback {

// Các hằng số cho Asset Profiler
#define ASSET_PROFILER_VERSION "1.2"
#define DATA_VERSION 1
#define PROFILE_LOG_ALL 3
#define PROFILE_LOG_IMPORTANT 2
#define PROFILE_LOG_ERRORS 1
#define PROFILE_LOG_NONE 0
#define MAX_SCENARIOS 20

// Chế độ điều chỉnh profile
enum ENUM_PROFILE_ADJUSTMENT_MODE {
    PROFILE_ADJUST_DISABLED = 0,    // Không điều chỉnh
    PROFILE_ADJUST_BASIC = 1,       // Điều chỉnh cơ bản (theo hướng)
    PROFILE_ADJUST_ADVANCED = 2,    // Điều chỉnh nâng cao (theo hướng và kịch bản)
    PROFILE_ADJUST_FULL = 3         // Điều chỉnh đầy đủ (kết hợp cả 2 loại)
};


// Cấu trúc lưu trữ thống kê kịch bản
struct AssetScenarioStats {
    string name;          // Tên kịch bản
    int totalTrades;      // Tổng số giao dịch
    int winTrades;        // Số giao dịch thắng
    double winRate;       // Tỷ lệ thắng
    double avgProfit;     // Lợi nhuận trung bình
    double avgLoss;       // Tổn thất trung bình
    double profitFactor;  // Hệ số lợi nhuận
    double adjustment;    // Điều chỉnh
    datetime lastUpdate;  // Thời gian cập nhật
};

// Lớp lưu trữ dữ liệu profile
class CProfileStorage {
public:
    // Cấu trúc lưu trữ thông tin giao dịch
    struct TradeRecord {
        datetime time;      // Thời gian giao dịch
        string scenario;    // Kịch bản giao dịch
        bool isLong;        // Hướng giao dịch (long/short)
        bool win;           // Kết quả (thắng/thua)
        double profit;      // Lợi nhuận (tính theo R)
    };

private:
    TradeRecord m_History[];
    int m_HistoryCount;

public:
    // Constructor
    CProfileStorage() : m_HistoryCount(0) {}
    
    // Thêm giao dịch mới vào lịch sử
    void AddTrade(string scenario, bool isLong, bool win, double profit) {
        int index = m_HistoryCount;
        m_HistoryCount++;
        ArrayResize(m_History, m_HistoryCount);
        
        m_History[index].time = TimeCurrent();
        m_History[index].scenario = scenario;
        m_History[index].isLong = isLong;
        m_History[index].win = win;
        m_History[index].profit = profit;
    }
    
    // Lấy số lượng giao dịch trong lịch sử
    int GetHistoryCount() const {
        return m_HistoryCount;
    }
    
    // Lấy thống kê cho kịch bản cụ thể
    bool GetScenarioStats(string scenarioName, int &totalTrades, int &winTrades, double &winRate, double &avgProfit) {
        totalTrades = 0;
        winTrades = 0;
        double totalProfit = 0.0;
        
        // Kiểm tra có dữ liệu nào không
        if(m_HistoryCount == 0) return false;
        
        // Đếm số giao dịch và thắng thua cho kịch bản
        for(int i = 0; i < m_HistoryCount; i++) {
            if(m_History[i].scenario == scenarioName) {
                totalTrades++;
                if(m_History[i].win) winTrades++;
                totalProfit += m_History[i].profit;
            }
        }
        
        // Tính toán tỷ lệ thắng và lợi nhuận trung bình
        if(totalTrades > 0) {
            winRate = (double)winTrades / totalTrades;
            avgProfit = totalProfit / totalTrades;
            return true;
        }
        
        return false;
    }
    
    // Lấy thông tin giao dịch theo chỉ số
    bool GetTradeRecord(int index, TradeRecord &record) {
        if(index >= 0 && index < m_HistoryCount) {
            record = m_History[index];
            return true;
        }
        return false;
    }
    
    // Xóa toàn bộ lịch sử
    void ClearHistory() {
        ArrayFree(m_History);
        m_HistoryCount = 0;
    }
    
    // Lưu dữ liệu vào file
    bool SaveHistoryToFile(string filename) {
        int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
        if(fileHandle == INVALID_HANDLE) {
            Print("Không thể mở file để lưu: ", GetLastError());
            return false;
        }
        
        // Lưu version
        FileWriteInteger(fileHandle, DATA_VERSION);
        
        // Lưu số lượng bản ghi
        FileWriteInteger(fileHandle, m_HistoryCount);
        
        // Lưu từng bản ghi
        for(int i = 0; i < m_HistoryCount; i++) {
            FileWriteLong(fileHandle, m_History[i].time);
            FileWriteString(fileHandle, m_History[i].scenario);
            FileWriteInteger(fileHandle, m_History[i].isLong);
            FileWriteInteger(fileHandle, m_History[i].win);
            FileWriteDouble(fileHandle, m_History[i].profit);
        }
        
        FileClose(fileHandle);
        return true;
    }
    
    // Nạp dữ liệu từ file
    bool LoadHistoryFromFile(string filename) {
        if(!FileIsExist(filename, FILE_COMMON)) {
            return false;
        }
        
        int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
        if(fileHandle == INVALID_HANDLE) {
            Print("Không thể mở file để đọc: ", GetLastError());
            return false;
        }
        
        // Kiểm tra version
        int version = FileReadInteger(fileHandle);
        if(version != DATA_VERSION) {
            FileClose(fileHandle);
            return false;  // Không tương thích phiên bản
        }
        
        // Đọc số lượng bản ghi
        int count = FileReadInteger(fileHandle);
        
        // Xóa dữ liệu cũ
        ClearHistory();
        
        // Đọc từng bản ghi
        if(count > 0) {
            ArrayResize(m_History, count);
            m_HistoryCount = count;
            
            for(int i = 0; i < count; i++) {
                m_History[i].time = (datetime)FileReadLong(fileHandle);
                m_History[i].scenario = FileReadString(fileHandle);
                m_History[i].isLong = (bool)FileReadInteger(fileHandle);
                m_History[i].win = (bool)FileReadInteger(fileHandle);
                m_History[i].profit = FileReadDouble(fileHandle);
            }
        }
        
        FileClose(fileHandle);
        return true;
    }
    
    // Lấy thống kê theo hướng giao dịch (long/short)
    bool GetDirectionalStats(bool isLong, int &totalTrades, int &winTrades, double &winRate, double &avgProfit) {
        if(m_HistoryCount == 0) return false;
        
        totalTrades = 0;
        winTrades = 0;
        double totalProfit = 0.0;
        
        // Tính toán thống kê từ lịch sử giao dịch
        for(int i = 0; i < m_HistoryCount; i++) {
            if(m_History[i].isLong == isLong) {
                totalTrades++;
                if(m_History[i].win) winTrades++;
                totalProfit += m_History[i].profit;
            }
        }
        
        // Tính toán tỷ lệ thắng và lợi nhuận trung bình
        if(totalTrades > 0) {
            winRate = (double)winTrades / totalTrades;
            avgProfit = totalProfit / totalTrades;
            return true;
        }
        
        return false;
    }
    
    // Lấy thống kê tổng quan gần đây
    bool GetRecentStats(int &totalTrades, int &winTrades, int &lossTrades, double &winRate) {
        if(m_HistoryCount == 0) return false;
        
        totalTrades = 0;
        winTrades = 0;
        lossTrades = 0;
        
        // Tính toán thống kê từ lịch sử giao dịch
        for(int i = 0; i < m_HistoryCount; i++) {
            totalTrades++;
            if(m_History[i].win) {
                winTrades++;
            } else {
                lossTrades++;
            }
        }
        
        winRate = (totalTrades > 0) ? (double)winTrades / totalTrades : 0.0;
        return true;
    }
    
    // Lấy thống kê theo hướng
    // Phương thức GetDirectionalStats đã được định nghĩa ở trên
    
    // Lấy thống kê theo kịch bản
    // Phương thức GetScenarioStats đã được định nghĩa ở trên
};

// Lớp quản lý hồ sơ tài sản
class CAssetProfiler {
private:
    string m_Symbol;                  // Biểu tượng tiền tệ
    CProfileStorage m_Storage;        // Đối tượng lưu trữ
    // Sử dụng con trỏ để phù hợp với cách implement
    CLogger* m_Logger;   // Con trỏ đến đối tượng logger
    
    // Thống kê tổng quan
    int m_TotalTrades;                // Tổng số giao dịch
    int m_WinTrades;                  // Số giao dịch thắng
    int m_LossTrades;                 // Số giao dịch thua
    double m_LongWinRate;             // Tỷ lệ thắng khi long
    double m_ShortWinRate;            // Tỷ lệ thắng khi short
    double m_LongAdjustment;          // Điều chỉnh cho long
    double m_ShortAdjustment;         // Điều chỉnh cho short
    double m_LongAvgProfit;           // Lợi nhuận trung bình khi long
    double m_ShortAvgProfit;          // Lợi nhuận trung bình khi short
    datetime m_LastRefreshTime;       // Thời điểm làm mới cuối cùng
    
    // Thống kê theo phiên
    double m_AsianWinRate;            // Tỷ lệ thắng phiên Á
    double m_LondonWinRate;           // Tỷ lệ thắng phiên London
    double m_NewYorkWinRate;          // Tỷ lệ thắng phiên New York
    
    // Thống kê theo kịch bản
    AssetScenarioStats m_ScenarioStats[]; // Mảng thống kê kịch bản
    int m_ScenarioCount;              // Số lượng kịch bản
    
    // Cài đặt
    int m_MinimumTrades;              // Số giao dịch tối thiểu cần để tính toán
    double m_AdaptPercent;            // Phần trăm điều chỉnh
    int m_LogLevel;                   // Mức độ log
    ENUM_PROFILE_ADJUSTMENT_MODE m_AdjustmentMode; // Chế độ điều chỉnh

    // Khởi tạo các giá trị thống kê mặc định
    void InitializeDefaultStats() {
        m_TotalTrades = 0;
        m_WinTrades = 0;
        m_LossTrades = 0;
        m_LongWinRate = 0.5;
        m_ShortWinRate = 0.5;
        m_LongAdjustment = 0.0;
        m_ShortAdjustment = 0.0;
        m_LongAvgProfit = 0.0;
        m_ShortAvgProfit = 0.0;
        m_LastRefreshTime = 0;
        
        m_AsianWinRate = 0.5;
        m_LondonWinRate = 0.5;
        m_NewYorkWinRate = 0.5;
        
        // Resize mảng thống kê kịch bản nếu cần
        if (m_ScenarioCount > 0) {
            ArrayResize(m_ScenarioStats, m_ScenarioCount);
            for (int i = 0; i < m_ScenarioCount; i++) {
                m_ScenarioStats[i].name = "Scenario_" + IntegerToString(i+1);
                m_ScenarioStats[i].totalTrades = 0;
                m_ScenarioStats[i].winRate = 0.5;
                m_ScenarioStats[i].avgProfit = 0.0;
                m_ScenarioStats[i].avgLoss = 0.0;
                m_ScenarioStats[i].profitFactor = 1.0;
                m_ScenarioStats[i].adjustment = 0.0;
            }
        }
    }

public:
    // Constructor khởi tạo giá trị mặc định
    CAssetProfiler(string symbol) {
        m_Symbol = symbol;
        m_Logger = NULL;
        m_ScenarioCount = 0;
        m_MinimumTrades = 10;
        m_AdaptPercent = 0.5;
        m_LogLevel = PROFILE_LOG_IMPORTANT;
        m_AdjustmentMode = PROFILE_ADJUST_BASIC;
        
        // Khởi tạo thống kê mặc định
        InitializeDefaultStats();
    }
    
    // Lấy R-multiple tối ưu dựa trên dữ liệu lịch sử
    double GetOptimalRMultiple() {
        // Mặc định trả về 2.0 nếu không có đủ dữ liệu
        if (m_TotalTrades < m_MinimumTrades) return 2.0;
        
        // Dựa trên tỷ lệ thắng và lợi nhuận trung bình
        double winRate = (double)m_WinTrades / m_TotalTrades;
        double avgWin = m_LongAvgProfit > m_ShortAvgProfit ? m_LongAvgProfit : m_ShortAvgProfit;
        
        // Công thức: winRate * (1 + avgWin) / (1 - winRate)
        // Nhưng giới hạn trong khoảng 1.5 đến 3.0
        double rMultiple = winRate * (1.0 + avgWin) / MathMax(1.0 - winRate, 0.1);
        return MathMin(MathMax(rMultiple, 1.5), 3.0);
    }
    
    // Lấy giá trị ATR dựa trên dữ liệu thị trường
    double GetATR(int period = 14) {
        // Sử dụng indicator iATR để tính ATR
        int handle = iATR(m_Symbol, PERIOD_D1, period);
        if (handle == INVALID_HANDLE) return 0.0;
        
        double atrValues[];
        ArraySetAsSeries(atrValues, true);
        int copied = CopyBuffer(handle, 0, 0, 3, atrValues);
        IndicatorRelease(handle);
        
        if (copied > 0) {
            return atrValues[0]; // Trả về giá trị ATR mới nhất
        }
        return 0.0;
    }
    
    // Xác định chế độ thị trường (xu hướng, sideway, v.v.)
    int GetRegime() {
        // Mặc định là chế độ neutral (0)
        // Các giá trị có thể trả về:
        // 1 = Xu hướng tăng mạnh
        // 0 = Thị trường sideway/không rõ xu hướng
        // -1 = Xu hướng giảm mạnh
        
        // Đây là triển khai đơn giản, có thể mở rộng logic phức tạp hơn
        if (m_LongWinRate > 0.6 && m_LongAvgProfit > 1.5) return 1;
        if (m_ShortWinRate > 0.6 && m_ShortAvgProfit > 1.5) return -1;
        return 0;
    }
    // Lấy điểm mạnh profile (hướng và kịch bản phù hợp nhất)
    bool GetProfileStrengths(string &bestScenario, bool &preferLong) {
        if (m_TotalTrades < m_MinimumTrades) {
            return false;
        }
        
        // Xác định hướng mạnh hơn
        preferLong = (m_LongWinRate > m_ShortWinRate);
        
        // Tìm kịch bản mạnh nhất
        double highestScore = -1000.0; // Khởi tạo với giá trị thấp
        bestScenario = "";
        
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].totalTrades >= 5) {
                // Tính điểm = winRate * 2 + avgProfit
                double score = (m_ScenarioStats[i].winRate * 2.0) + m_ScenarioStats[i].avgProfit;
                
                if (score > highestScore) {
                    highestScore = score;
                    bestScenario = m_ScenarioStats[i].name;
                }
            }
        }
        
        return (bestScenario != "");
    }
    
    // Lấy tỷ lệ thắng theo kịch bản
    double GetScenarioWinRate(string scenario) {
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].name == scenario && m_ScenarioStats[i].totalTrades > 0) {
                return m_ScenarioStats[i].winRate;
            }
        }
        return 0.5; // Mặc định 50% nếu không tìm thấy
    }
    
    // Lấy thống kê profile
    string GetProfileStats() {
        string stats = StringFormat("===== ASSET PROFILE: %s =====\n", m_Symbol);
        stats += StringFormat("Version: %s\n", ASSET_PROFILER_VERSION);
        stats += StringFormat("Total Trades: %d\n", m_TotalTrades);
        
        if (m_TotalTrades > 0) {
            double winRate = (double)m_WinTrades / m_TotalTrades * 100;
            stats += StringFormat("Win Rate: %.2f%%\n", winRate);
            stats += StringFormat("Long Win Rate: %.2f%%\n", m_LongWinRate * 100);
            stats += StringFormat("Short Win Rate: %.2f%%\n", m_ShortWinRate * 100);
            stats += StringFormat("Long Adjustment: %.3f\n", m_LongAdjustment);
            stats += StringFormat("Short Adjustment: %.3f\n", m_ShortAdjustment);
            
            // Thêm thông tin kịch bản
            stats += "\n--- SCENARIO STATS ---\n";
            for (int i = 0; i < m_ScenarioCount; i++) {
                if (m_ScenarioStats[i].totalTrades > 0) {
                    stats += StringFormat("%s: %d trades, %.2f%% win, Avg: %.2fR, Adj: %.3f\n", 
                              m_ScenarioStats[i].name,
                              m_ScenarioStats[i].totalTrades,
                              m_ScenarioStats[i].winRate * 100,
                              m_ScenarioStats[i].avgProfit,
                              m_ScenarioStats[i].adjustment);
                }
            }
            
            // Thêm thông tin phiên
            stats += "\n--- SESSION STATS ---\n";
            stats += StringFormat("Asian: %.2f%%\n", m_AsianWinRate * 100);
            stats += StringFormat("London: %.2f%%\n", m_LondonWinRate * 100);
            stats += StringFormat("New York: %.2f%%\n", m_NewYorkWinRate * 100);
        }
        
        return stats;
    }
    
    // Xuất dữ liệu sang CSV cho phân tích ngoài
    bool ExportToCsv(string filename) {
        int fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON, ",");
        if (fileHandle == INVALID_HANDLE) {
            if (m_Logger != NULL) {
                string logMessage = StringFormat("[Asset Profiler] Không thể tạo file CSV: %s", filename);
                m_Logger.LogError(logMessage);
            }
            return false;
        }
        
        // Ghi tiêu đề
        FileWrite(fileHandle, "Date", "Time", "Scenario", "Direction", "Result", "Profit");
        
        // Lấy và ghi dữ liệu
        for (int i = 0; i < m_Storage.GetHistoryCount(); i++) {
            CProfileStorage::TradeRecord record;
            
            if (m_Storage.GetTradeRecord(i, record)) {
                MqlDateTime dt;
                TimeToStruct(record.time, dt);
                
                string dateStr = StringFormat("%04d-%02d-%02d", dt.year, dt.mon, dt.day);
                string timeStr = StringFormat("%02d:%02d:%02d", dt.hour, dt.min, dt.sec);
                
                FileWrite(fileHandle, 
                         dateStr, 
                         timeStr, 
                         record.scenario, 
                         record.isLong ? "LONG" : "SHORT", 
                         record.win ? "WIN" : "LOSS", 
                         DoubleToString(record.profit, 2));
            }
        }
        
        FileClose(fileHandle);
        if (m_Logger != NULL) m_Logger.LogInfo(StringFormat("[Asset Profiler] Đã xuất dữ liệu sang: %s", filename));
        return true;
    }
    
    // Cập nhật cưỡng bức thống kê (hữu ích khi muốn refresh)
    void ForceRefreshStats() {
        RefreshStats();
    }
    
    // Cập nhật thống kê từ dữ liệu lịch sử
    void RefreshStats() {
        // Khởi tạo lại thống kê mặc định
        InitializeDefaultStats();
        
        // Lấy thống kê tổng quan
        int totalTrades = 0, winTrades = 0, lossTrades = 0;
        double winRate = 0.0;
        
        if(m_Storage.GetRecentStats(totalTrades, winTrades, lossTrades, winRate)) {
            m_TotalTrades = totalTrades;
            m_WinTrades = winTrades;
            m_LossTrades = lossTrades;
        }
        
        // Lấy thống kê theo hướng
        int longTrades = 0, longWins = 0;
        double longWinRate = 0.0, longAvgProfit = 0.0;
        
        if(m_Storage.GetDirectionalStats(true, longTrades, longWins, longWinRate, longAvgProfit)) {
            m_LongWinRate = longWinRate;
            m_LongAvgProfit = longAvgProfit;
        }
        
        int shortTrades = 0, shortWins = 0;
        double shortWinRate = 0.0, shortAvgProfit = 0.0;
        
        if(m_Storage.GetDirectionalStats(false, shortTrades, shortWins, shortWinRate, shortAvgProfit)) {
            m_ShortWinRate = shortWinRate;
            m_ShortAvgProfit = shortAvgProfit;
        }
        
        m_LastRefreshTime = TimeCurrent();
        
        // Cập nhật thống kê kịch bản
        UpdateScenarioStats();
    }
    
    // Lấy điều chỉnh theo kịch bản
    double GetScenarioAdjustment(string scenario) {
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].name == scenario && m_ScenarioStats[i].totalTrades >= 5) {
                return m_ScenarioStats[i].adjustment;
            }
        }
        
        return 0.0;
    }
    
    //+------------------------------------------------------------------+
    //| Nạp dữ liệu profile                                              |
    //+------------------------------------------------------------------+
    bool LoadProfileData() {
        string historyFile = "AP_History_" + m_Symbol + ".dat";
        string configFile = "AP_Config_" + m_Symbol + ".dat";
        
        bool historyExists = FileIsExist(historyFile, FILE_COMMON);
        bool configExists = FileIsExist(configFile, FILE_COMMON);
        
        bool historyLoaded = m_Storage.LoadHistoryFromFile(historyFile);
        if (!historyLoaded) {
            LogMessage(StringFormat("Không thể nạp lịch sử từ file: %s", historyFile), PROFILE_LOG_ERRORS);
            return false;
        }
        
        if (configExists) {
            int fileHandle = FileOpen(configFile, FILE_READ|FILE_BIN|FILE_COMMON);
            if (fileHandle != INVALID_HANDLE) {
                int configVersion = FileReadInteger(fileHandle);
                m_MinimumTrades = FileReadInteger(fileHandle);
                m_AdaptPercent = FileReadDouble(fileHandle);
                m_LogLevel = (ENUM_PROFILE_LOG_LEVEL)FileReadInteger(fileHandle);
                m_AdjustmentMode = (ENUM_PROFILE_ADJUSTMENT_MODE)FileReadInteger(fileHandle);
                FileClose(fileHandle);
            }
        }
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Lưu dữ liệu profile                                          |
    //+------------------------------------------------------------------+
    bool SaveProfileData() {
        string historyFile = "AP_History_" + m_Symbol + ".dat";
        string configFile = "AP_Config_" + m_Symbol + ".dat";
        
        bool historySaved = m_Storage.SaveHistoryToFile(historyFile);
        if (!historySaved) {
            LogMessage(StringFormat("Không thể lưu lịch sử vào file: %s", historyFile), PROFILE_LOG_ERRORS);
            return false;
        }
        
        int fileHandle = FileOpen(configFile, FILE_WRITE|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            LogMessage(StringFormat("Không thể mở file để lưu dữ liệu: %s", configFile), PROFILE_LOG_ERRORS);
            return false;
        }
        
        FileWriteInteger(fileHandle, DATA_VERSION);
        FileWriteInteger(fileHandle, m_MinimumTrades);
        FileWriteDouble(fileHandle, m_AdaptPercent);
        FileWriteInteger(fileHandle, (int)m_LogLevel);
        FileWriteInteger(fileHandle, (int)m_AdjustmentMode);
        
        FileClose(fileHandle);
        LogMessage("Đã lưu profile dữ liệu thành công", PROFILE_LOG_ALL);
        return true;
    }
    
    // Hàm log chỉ khi cần thiết
    void LogMessage(string message, int level) {
        if(level <= m_LogLevel) {
            if(m_Logger != NULL) {
                string formattedMessage = StringFormat("[Asset Profiler] %s", message);
                switch(level) {
                    case PROFILE_LOG_ERRORS:
                        m_Logger.LogError(formattedMessage);
                        break;
                    case PROFILE_LOG_IMPORTANT:
                        m_Logger.LogWarning(formattedMessage);
                        break;
                    case PROFILE_LOG_ALL:
                        m_Logger.LogInfo(formattedMessage);
                        break;
                    default:
                        // Không làm gì
                        break;
                }
            } else {
                // Fallback nếu Logger chưa được khởi tạo
                Print("[Asset Profiler] " + message);
            }
        }
    }


    
    // Khởi tạo thống kê đã được định nghĩa trong phần private
    
    // Cập nhật thống kê kịch bản
    void UpdateScenarioStats() {
        // Tạo mảng kịch bản
        if (m_ScenarioCount == 0) {
            // Khởi tạo các kịch bản mặc định
            m_ScenarioCount = 5;
            ArrayResize(m_ScenarioStats, m_ScenarioCount);
            
            m_ScenarioStats[0].name = "Pullback_Strong";
            m_ScenarioStats[1].name = "Pullback_Shallow";
            m_ScenarioStats[2].name = "Breakout";
            m_ScenarioStats[3].name = "Reversal";
            m_ScenarioStats[4].name = "RangeBreak";
            
            // Khởi tạo giá trị mặc định cho tất cả
            for (int i = 0; i < m_ScenarioCount; i++) {
                m_ScenarioStats[i].totalTrades = 0;
                m_ScenarioStats[i].winTrades = 0;
                m_ScenarioStats[i].winRate = 0.5;
                m_ScenarioStats[i].avgProfit = 0.0;
                m_ScenarioStats[i].adjustment = 0.0;
                m_ScenarioStats[i].lastUpdate = TimeCurrent();
            }
        }
        
        // Cập nhật thống kê cho từng kịch bản
        for (int i = 0; i < m_ScenarioCount; i++) {
            int scenarioTrades = 0, scenarioWins = 0;
            double scenarioWinRate = 0.0, scenarioAvgProfit = 0.0;
            
            if (m_Storage.GetScenarioStats(m_ScenarioStats[i].name, scenarioTrades, scenarioWins, scenarioWinRate, scenarioAvgProfit)) {
                m_ScenarioStats[i].totalTrades = scenarioTrades;
                m_ScenarioStats[i].winTrades = scenarioWins;
                m_ScenarioStats[i].winRate = scenarioWinRate;
                m_ScenarioStats[i].avgProfit = scenarioAvgProfit;
                m_ScenarioStats[i].lastUpdate = TimeCurrent();
            }
        }
    }
    
    // Tính toán các điều chỉnh
    void CalculateAdjustments() {
        // Chỉ tính toán lại nếu đủ dữ liệu
        if (m_TotalTrades < m_MinimumTrades) {
            // Không đủ dữ liệu, thiết lập các giá trị mặc định
            m_LongAdjustment = 0.0;
            m_ShortAdjustment = 0.0;
            
            // Xóa điều chỉnh cho các kịch bản
            for (int i = 0; i < m_ScenarioCount; i++) {
                m_ScenarioStats[i].adjustment = 0.0;
            }
            return;
        }
        
        // Tính toán điều chỉnh cơ bản theo hướng
        // Điều chỉnh long: 50% = 0, 100% = +0.3, 0% = -0.3
        m_LongAdjustment = (m_LongWinRate - 0.5) * 0.6;
        
        // Điều chỉnh short: 50% = 0, 100% = +0.3, 0% = -0.3
        m_ShortAdjustment = (m_ShortWinRate - 0.5) * 0.6;
        
        // Giới hạn điều chỉnh trong khoảng [-0.3, +0.3]
        m_LongAdjustment = MathMax(-0.3, MathMin(0.3, m_LongAdjustment));
        m_ShortAdjustment = MathMax(-0.3, MathMin(0.3, m_ShortAdjustment));
        
        // Tính toán điều chỉnh cho các kịch bản
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].totalTrades >= 5) {
                // Điều chỉnh dựa trên tỷ lệ thắng và lợi nhuận trung bình
                double winRateComponent = (m_ScenarioStats[i].winRate - 0.5) * 0.5;
                double profitComponent = m_ScenarioStats[i].avgProfit * 0.2;
                
                // Kết hợp hai thành phần
                m_ScenarioStats[i].adjustment = winRateComponent + profitComponent;
                
                // Giới hạn điều chỉnh trong khoảng [-0.25, +0.25]
                m_ScenarioStats[i].adjustment = MathMax(-0.25, MathMin(0.25, m_ScenarioStats[i].adjustment));
            }
        }
        
        LogMessage("Đã tính toán điều chỉnh: Long " + DoubleToString(m_LongAdjustment, 3) + 
                  ", Short " + DoubleToString(m_ShortAdjustment, 3), PROFILE_LOG_ALL);
    }
    
    // Phương thức để thiết lập logger từ bên ngoài
    void SetLogger(CLogger *logger) {
        m_Logger = logger;
    }
};

} // namespace ApexPullback

#endif // ASSET_PROFILER_MQH_
