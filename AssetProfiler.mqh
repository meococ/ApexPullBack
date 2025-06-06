//+------------------------------------------------------------------+
//|                                               AssetProfiler.mqh   |
//|                         APEX Pullback EA v14.0 - Self-Learning   |
//+------------------------------------------------------------------+
// Removed #property directives - these are not allowed in .mqh files
// #property copyright "APEX Forex"
// #property link      "https://www.apexpullback.com"
// #property strict

#include "Logger.mqh"  // Thêm include cho Logger
#include "CommonStructs.mqh"
#include "Constants.mqh"
#include "Enums.mqh"

// Định nghĩa hằng số
#define ASSET_PROFILER_VERSION "2.0"
#define MAX_SCENARIOS 20       // Tăng từ 10 lên 20
#define DATA_VERSION 2         // Để xác định phiên bản dữ liệu khi cập nhật cấu trúc
#define AUTO_SAVE_TRADES 5     // Lưu sau mỗi 5 giao dịch, không phải mỗi giao dịch
#define TRIM_OLD_DATA_DAYS 180 // Dữ liệu cũ hơn 180 ngày sẽ có trọng số thấp

// Các enum đã được di chuyển sang file Enums.mqh

//+------------------------------------------------------------------+
//| Lớp hỗ trợ lưu trữ và tính toán cho profile                      |
//+------------------------------------------------------------------+
class CProfileStorage {
public:  // Chuyển TradeRecord từ private sang public
    // Dữ liệu giao dịch theo thời gian để phân tích xu hướng
    struct TradeRecord {
        datetime time;          // Thời gian giao dịch
        string scenario;        // Kịch bản
        bool isLong;            // Hướng giao dịch
        bool win;               // Kết quả
        double profit;          // Lợi nhuận (R-multiple)
    };
    
private:
    // Lưu tối đa 500 giao dịch gần nhất
    TradeRecord m_TradeHistory[500];
    int m_HistoryCount;
    
    // Dùng đếm để chỉ lưu file sau một số giao dịch, không phải sau mỗi giao dịch
    int m_UnsavedUpdates;
    
public:
    // Constructor
    CProfileStorage() {
        m_HistoryCount = 0;
        m_UnsavedUpdates = 0;
    }
    
    // Thêm giao dịch vào lịch sử
    void AddTradeRecord(datetime time, string scenario, bool isLong, bool win, double profit) {
        // Nếu lịch sử đã đầy, xóa giao dịch cũ nhất
        if (m_HistoryCount >= 500) {
            // Dịch chuyển mảng
            for (int i = 0; i < m_HistoryCount - 1; i++) {
                m_TradeHistory[i] = m_TradeHistory[i + 1];
            }
            m_HistoryCount--;
        }
        
        // Thêm giao dịch mới
        m_TradeHistory[m_HistoryCount].time = time;
        m_TradeHistory[m_HistoryCount].scenario = scenario;
        m_TradeHistory[m_HistoryCount].isLong = isLong;
        m_TradeHistory[m_HistoryCount].win = win;
        m_TradeHistory[m_HistoryCount].profit = profit;
        m_HistoryCount++;
        
        // Tăng đếm giao dịch chưa lưu
        m_UnsavedUpdates++;
    }
    
    // Kiểm tra nếu cần lưu dữ liệu
    bool NeedsSaving() {
        return (m_UnsavedUpdates >= AUTO_SAVE_TRADES);
    }
    
    // Reset đếm sau khi lưu
    void ResetSaveCounter() {
        m_UnsavedUpdates = 0;
    }
    
    // Lấy số lượng giao dịch trong lịch sử
    int GetHistoryCount() {
        return m_HistoryCount;
    }
    
    // Lấy thông tin giao dịch tại vị trí index
    bool GetTradeRecord(int index, CProfileStorage::TradeRecord &record) {
        if (index >= 0 && index < m_HistoryCount) {
            record = m_TradeHistory[index];
            return true;
        }
        return false;
    }
    
    // Tính thống kê theo thời gian gần đây 
    // (days = số ngày muốn xem, 0 = tất cả)
    bool GetRecentStats(int days, int &totalTrades, int &winTrades, double &totalProfit) {
        totalTrades = 0;
        winTrades = 0;
        totalProfit = 0.0;
        
        datetime cutoffTime = 0;
        if (days > 0) {
            cutoffTime = TimeCurrent() - days * 86400; // 86400 = số giây trong 1 ngày
        }
        
        for (int i = 0; i < m_HistoryCount; i++) {
            if (cutoffTime == 0 || m_TradeHistory[i].time >= cutoffTime) {
                totalTrades++;
                if (m_TradeHistory[i].win) {
                    winTrades++;
                }
                totalProfit += m_TradeHistory[i].profit;
            }
        }
        
        return (totalTrades > 0);
    }
    
    // Tính thống kê theo kịch bản và khoảng thời gian
    bool GetScenarioStats(string scenario, int days, int &totalTrades, int &winTrades, double &avgProfit) {
        totalTrades = 0;
        winTrades = 0;
        double totalProfit = 0.0;
        
        datetime cutoffTime = 0;
        if (days > 0) {
            cutoffTime = TimeCurrent() - days * 86400;
        }
        
        for (int i = 0; i < m_HistoryCount; i++) {
            if ((cutoffTime == 0 || m_TradeHistory[i].time >= cutoffTime) && 
                m_TradeHistory[i].scenario == scenario) {
                totalTrades++;
                if (m_TradeHistory[i].win) {
                    winTrades++;
                }
                totalProfit += m_TradeHistory[i].profit;
            }
        }
        
        avgProfit = (totalTrades > 0) ? totalProfit / totalTrades : 0.0;
        return (totalTrades > 0);
    }
    
    // Tính thống kê theo hướng giao dịch và khoảng thời gian
    bool GetDirectionalStats(bool isLong, int days, int &totalTrades, int &winTrades, double &avgProfit) {
        totalTrades = 0;
        winTrades = 0;
        double totalProfit = 0.0;
        
        datetime cutoffTime = 0;
        if (days > 0) {
            cutoffTime = TimeCurrent() - days * 86400;
        }
        
        for (int i = 0; i < m_HistoryCount; i++) {
            if ((cutoffTime == 0 || m_TradeHistory[i].time >= cutoffTime) && 
                m_TradeHistory[i].isLong == isLong) {
                totalTrades++;
                if (m_TradeHistory[i].win) {
                    winTrades++;
                }
                totalProfit += m_TradeHistory[i].profit;
            }
        }
        
        avgProfit = (totalTrades > 0) ? totalProfit / totalTrades : 0.0;
        return (totalTrades > 0);
    }
    
    // Lưu lịch sử giao dịch vào file
    bool SaveHistoryToFile(string filename) {
        int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            return false;
        }
        
        // Lưu phiên bản dữ liệu để tương thích với nâng cấp trong tương lai
        FileWriteInteger(fileHandle, DATA_VERSION);
        
        // Lưu số lượng giao dịch
        FileWriteInteger(fileHandle, m_HistoryCount);
        
        // Lưu từng giao dịch
        for (int i = 0; i < m_HistoryCount; i++) {
            FileWriteInteger(fileHandle, (int)m_TradeHistory[i].time);
            FileWriteString(fileHandle, m_TradeHistory[i].scenario);
            FileWriteInteger(fileHandle, m_TradeHistory[i].isLong ? 1 : 0);
            FileWriteInteger(fileHandle, m_TradeHistory[i].win ? 1 : 0);
            FileWriteDouble(fileHandle, m_TradeHistory[i].profit);
        }
        
        FileClose(fileHandle);
        return true;
    }
    
    // Nạp lịch sử giao dịch từ file
    bool LoadHistoryFromFile(string filename) {
        if (!FileIsExist(filename, FILE_COMMON)) {
            return false;
        }
        
        int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            return false;
        }
        
        // Đọc và kiểm tra phiên bản dữ liệu
        int dataVersion = FileReadInteger(fileHandle);
        if (dataVersion > DATA_VERSION) {
            // File từ phiên bản mới hơn, không tương thích
            FileClose(fileHandle);
            return false;
        }
        
        // Đọc số lượng giao dịch
        m_HistoryCount = FileReadInteger(fileHandle);
        if (m_HistoryCount > 500) m_HistoryCount = 500; // Đảm bảo không vượt quá kích thước mảng
        
        // Đọc từng giao dịch
        for (int i = 0; i < m_HistoryCount; i++) {
            m_TradeHistory[i].time = (datetime)FileReadInteger(fileHandle);
            m_TradeHistory[i].scenario = FileReadString(fileHandle);
            m_TradeHistory[i].isLong = (FileReadInteger(fileHandle) != 0);
            m_TradeHistory[i].win = (FileReadInteger(fileHandle) != 0);
            m_TradeHistory[i].profit = FileReadDouble(fileHandle);
        }
        
        FileClose(fileHandle);
        return true;
    }
};

//+------------------------------------------------------------------+
//| Lớp chính - Asset Profiler                                       |
//+------------------------------------------------------------------+
class CAssetProfiler {
private:
    string m_Symbol;                 // Biểu tượng cặp tiền
    CLogger *m_Logger;               // Logger - sửa thành con trỏ
    int m_MinimumTrades;             // Số lệnh tối thiểu để học
    double m_AdaptPercent;           // % ảnh hưởng Profile lên quyết định
    ENUM_PROFILE_LOG_LEVEL m_LogLevel; // Mức độ log
    ENUM_ADJUSTMENT_MODE m_AdjustmentMode; // Chế độ điều chỉnh
    
    // Lưu trữ dữ liệu
    CProfileStorage m_Storage;
    
    // Dữ liệu thống kê
    int m_TotalTrades;               // Tổng số lệnh
    int m_WinTrades;                 // Số lệnh thắng
    int m_LossTrades;                // Số lệnh thua
    
    // Dữ liệu theo kịch bản
    struct ScenarioStats {
        string name;                 // Tên kịch bản
        int totalTrades;             // Tổng số lệnh
        int winTrades;               // Số lệnh thắng
        double winRate;              // Tỷ lệ thắng
        double avgProfit;            // Lợi nhuận trung bình
        double adjustment;           // Điều chỉnh điểm tín hiệu
        datetime lastUpdate;         // Thời gian cập nhật cuối cùng
    };
    
    ScenarioStats m_ScenarioStats[MAX_SCENARIOS]; // Tối đa 20 kịch bản
    int m_ScenarioCount;              // Số kịch bản đã lưu
    
    // Dữ liệu theo hướng
    double m_LongWinRate;            // Tỷ lệ thắng lệnh mua
    double m_ShortWinRate;           // Tỷ lệ thắng lệnh bán
    double m_LongAvgProfit;          // Lợi nhuận trung bình lệnh mua
    double m_ShortAvgProfit;         // Lợi nhuận trung bình lệnh bán
    
    // Điều chỉnh tín hiệu
    double m_LongAdjustment;         // Điều chỉnh tín hiệu mua
    double m_ShortAdjustment;        // Điều chỉnh tín hiệu bán
    
    // Dữ liệu theo phiên
    double m_AsianWinRate;           // Tỷ lệ thắng phiên Á
    double m_LondonWinRate;          // Tỷ lệ thắng phiên London
    double m_NewYorkWinRate;         // Tỷ lệ thắng phiên New York
    
    // Thời gian làm mới cuối cùng
    datetime m_LastRefreshTime;
    
    // Số lượng giao dịch trong lịch sử
    int m_HistoryCount;
    
public:
    
    // Khởi tạo
    CAssetProfiler(void) {
        m_Symbol = "";
        m_Logger = NULL;
        m_MinimumTrades = 20;
        m_AdaptPercent = 20.0;
        m_LogLevel = PROFILE_LOG_IMPORTANT;
        m_AdjustmentMode = ADJ_MODE_ADVANCED;
        m_TotalTrades = 0;
        m_WinTrades = 0;
        m_LossTrades = 0;
        m_ScenarioCount = 0;
        m_LongWinRate = 0.5;
        m_ShortWinRate = 0.5;
        m_LongAvgProfit = 0.0;
        m_ShortAvgProfit = 0.0;
        m_LongAdjustment = 0.0;
        m_ShortAdjustment = 0.0;
        m_AsianWinRate = 0.5;
        m_LondonWinRate = 0.5;
        m_NewYorkWinRate = 0.5;
        m_LastRefreshTime = 0;
        m_HistoryCount = 0;
    }
    
    // Destructor
    ~CAssetProfiler(void) {
        // Đảm bảo lưu dữ liệu khi kết thúc
        if (m_Storage.NeedsSaving()) {
            SaveProfileData();
        }
    }
    
    // Khởi tạo với tham số
    bool Initialize(string symbol, int minimumTrades, double adaptPercent, CLogger *logger) {
        m_Symbol = symbol;
        m_Logger = logger;
        m_MinimumTrades = minimumTrades;
        m_AdaptPercent = adaptPercent;
        
        // Khởi tạo ra với giá trị mặc định nếu tham số không hợp lệ
        if (m_MinimumTrades < 5) m_MinimumTrades = 5;
        if (m_AdaptPercent < 0) m_AdaptPercent = 0;
        if (m_AdaptPercent > 100) m_AdaptPercent = 100;
        
        // Load dữ liệu nếu có
        if (!LoadProfileData()) {
            InitializeDefaultStats();
            
            LogMessage("Asset Profiler: Khởi tạo profile mới cho " + m_Symbol, PROFILE_LOG_IMPORTANT);
        } else {
            RefreshStats(); // Tính toán lại các chỉ số từ dữ liệu đã nạp
            
            LogMessage("Asset Profiler: Đã nạp profile cho " + m_Symbol + 
                       ", Trades: " + IntegerToString(m_TotalTrades), PROFILE_LOG_IMPORTANT);
        }
        
        return true;
    }
    
    // Cài đặt tùy chọn nâng cao
    void SetOptions(ENUM_PROFILE_LOG_LEVEL logLevel, ENUM_ADJUSTMENT_MODE adjustMode) {
        m_LogLevel = logLevel;
        m_AdjustmentMode = adjustMode;
    }
    
    // Cập nhật profile
    void UpdateProfile(string scenario, bool isLong, bool win, double profit, string session = "") {
        m_TotalTrades++;
        
        if (win) {
            m_WinTrades++;
        } else {
            m_LossTrades++;
        }
        
        // Lưu lại giao dịch trong lịch sử
        m_Storage.AddTradeRecord(TimeCurrent(), scenario, isLong, win, profit);
        
        // Cập nhật theo kịch bản
        UpdateScenarioStats(scenario, win, profit);
        
        // Cập nhật theo hướng
        if (isLong) {
            int longTrades = 0, longWins = 0;
            double avgProfit = 0.0;
            
            if (m_Storage.GetDirectionalStats(true, 0, longTrades, longWins, avgProfit)) {
                m_LongWinRate = (double)longWins / longTrades;
                m_LongAvgProfit = avgProfit;
            }
        } else {
            int shortTrades = 0, shortWins = 0;
            double avgProfit = 0.0;
            
            if (m_Storage.GetDirectionalStats(false, 0, shortTrades, shortWins, avgProfit)) {
                m_ShortWinRate = (double)shortWins / shortTrades;
                m_ShortAvgProfit = avgProfit;
            }
        }
        
        // Cập nhật theo phiên nếu cung cấp
        if (session != "") {
            UpdateSessionStats(session, win);
        }
        
        // Tính toán lại các điều chỉnh
        CalculateAdjustments();
        
        // Log thông tin
        LogMessage("Asset Profiler: Đã cập nhật " + (isLong ? "LONG" : "SHORT") + " " + 
                   scenario + (win ? " WIN " : " LOSS ") + DoubleToString(profit, 2) + "R", 
                   PROFILE_LOG_ALL);
        
        // Lưu dữ liệu nếu cần
        if (m_Storage.NeedsSaving()) {
            SaveProfileData();
            m_Storage.ResetSaveCounter();
        }
    }
    
    // Lấy điều chỉnh tín hiệu theo kịch bản/hướng
    double GetSignalAdjustment(string scenario, bool isLong) {
        // Nếu chưa đủ dữ liệu, không điều chỉnh
        if (m_TotalTrades < m_MinimumTrades) {
            return 0.0;
        }
        
        // Lấy điều chỉnh theo kịch bản
        double scenarioAdjustment = GetScenarioAdjustment(scenario);
        
        // Lấy điều chỉnh theo hướng
        double directionAdjustment = isLong ? m_LongAdjustment : m_ShortAdjustment;
        
        // Kết hợp hai điều chỉnh (trọng số 70% theo kịch bản, 30% theo hướng)
        double finalAdjustment = (scenarioAdjustment * 0.7 + directionAdjustment * 0.3);
        
        // Áp dụng % ảnh hưởng
        finalAdjustment *= (m_AdaptPercent / 100.0);
        
        // Giới hạn điều chỉnh trong phạm vi [-0.5, 0.5] để không áp đảo tín hiệu gốc
        finalAdjustment = MathMax(-0.5, MathMin(0.5, finalAdjustment));
        
        return finalAdjustment;
    }
    
    // Kiểm tra profile có đủ độ tin cậy chưa
    bool IsProfileReliable() {
        return (m_TotalTrades >= m_MinimumTrades);
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
        string stats = "===== ASSET PROFILE: " + m_Symbol + " =====\n";
        stats += "Version: " + ASSET_PROFILER_VERSION + "\n";
        stats += "Total Trades: " + IntegerToString(m_TotalTrades) + "\n";
        
        if (m_TotalTrades > 0) {
            double winRate = (double)m_WinTrades / m_TotalTrades * 100;
            stats += "Win Rate: " + DoubleToString(winRate, 2) + "%\n";
            stats += "Long Win Rate: " + DoubleToString(m_LongWinRate * 100, 2) + "%\n";
            stats += "Short Win Rate: " + DoubleToString(m_ShortWinRate * 100, 2) + "%\n";
            stats += "Long Adjustment: " + DoubleToString(m_LongAdjustment, 3) + "\n";
            stats += "Short Adjustment: " + DoubleToString(m_ShortAdjustment, 3) + "\n";
            
            // Thêm thông tin kịch bản
            stats += "\n--- SCENARIO STATS ---\n";
            for (int i = 0; i < m_ScenarioCount; i++) {
                if (m_ScenarioStats[i].totalTrades > 0) {
                    stats += m_ScenarioStats[i].name + ": " + 
                             IntegerToString(m_ScenarioStats[i].totalTrades) + " trades, " +
                             DoubleToString(m_ScenarioStats[i].winRate * 100, 2) + "% win, " +
                             "Avg: " + DoubleToString(m_ScenarioStats[i].avgProfit, 2) + "R, " +
                             "Adj: " + DoubleToString(m_ScenarioStats[i].adjustment, 3) + "\n";
                }
            }
            
            // Thêm thông tin phiên
            stats += "\n--- SESSION STATS ---\n";
            stats += "Asian: " + DoubleToString(m_AsianWinRate * 100, 2) + "%\n";
            stats += "London: " + DoubleToString(m_LondonWinRate * 100, 2) + "%\n";
            stats += "New York: " + DoubleToString(m_NewYorkWinRate * 100, 2) + "%\n";
        }
        
        return stats;
    }
    
    // Xuất dữ liệu sang CSV cho phân tích ngoài
    bool ExportToCsv(string filename) {
        int fileHandle = FileOpen(filename, FILE_WRITE|FILE_CSV|FILE_COMMON, ",");
        if (fileHandle == INVALID_HANDLE) {
            LogMessage("Không thể tạo file CSV: " + filename, PROFILE_LOG_ERRORS);
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
        LogMessage("Đã xuất dữ liệu sang: " + filename, PROFILE_LOG_IMPORTANT);
        return true;
    }
    
    // Cập nhật cưỡng bức thống kê (hữu ích khi muốn refresh)
    void ForceRefreshStats() {
        RefreshStats();
    }
    
private:
    // Khởi tạo thống kê mặc định
    void InitializeDefaultStats() {
        m_TotalTrades = 0;
        m_WinTrades = 0;
        m_LossTrades = 0;
        m_ScenarioCount = 0;
        m_LongWinRate = 0.5;
        m_ShortWinRate = 0.5;
        m_LongAvgProfit = 0.0;
        m_ShortAvgProfit = 0.0;
        m_LongAdjustment = 0.0;
        m_ShortAdjustment = 0.0;
        m_AsianWinRate = 0.5;
        m_LondonWinRate = 0.5;
        m_NewYorkWinRate = 0.5;
        m_LastRefreshTime = TimeCurrent();
    }
    
    // Làm mới thống kê từ dữ liệu lịch sử
    void RefreshStats() {
        // Reset các thống kê
        m_TotalTrades = 0;
        m_WinTrades = 0;
        
        // Lấy thống kê từ dữ liệu
        int totalTrades = 0;
        int winTrades = 0;
        double totalProfit = 0.0;
        
        if (m_Storage.GetRecentStats(0, totalTrades, winTrades, totalProfit)) {
            m_TotalTrades = totalTrades;
            m_WinTrades = winTrades;
            m_LossTrades = totalTrades - winTrades;
        }
        
        // Làm mới thống kê theo hướng
        int longTrades = 0, longWins = 0, shortTrades = 0, shortWins = 0;
        double longProfit = 0.0, shortProfit = 0.0;
        
        if (m_Storage.GetDirectionalStats(true, 0, longTrades, longWins, longProfit)) {
            m_LongWinRate = (double)longWins / longTrades;
            m_LongAvgProfit = longProfit;
        }
        
        if (m_Storage.GetDirectionalStats(false, 0, shortTrades, shortWins, shortProfit)) {
            m_ShortWinRate = (double)shortWins / shortTrades;
            m_ShortAvgProfit = shortProfit;
        }
        
        // Làm mới thống kê kịch bản 
        RefreshScenarioStats();
        
        // Tính toán các điều chỉnh
        CalculateAdjustments();
        
        m_LastRefreshTime = TimeCurrent();
        LogMessage("Đã làm mới thống kê AssetProfiler", PROFILE_LOG_ALL);
    }
    
    // Làm mới thống kê kịch bản
    void RefreshScenarioStats() {
        // Reset count
        m_ScenarioCount = 0;
        
        // Duyệt qua lịch sử để lấy tất cả kịch bản duy nhất
        string scenarios[MAX_SCENARIOS];
        int scenarioCount = 0;
        
        for (int i = 0; i < m_Storage.GetHistoryCount(); i++) {
            CProfileStorage::TradeRecord record;
            if (m_Storage.GetTradeRecord(i, record)) {
                // Kiểm tra xem kịch bản đã có trong danh sách chưa
                bool found = false;
                for (int j = 0; j < scenarioCount; j++) {
                    if (scenarios[j] == record.scenario) {
                        found = true;
                        break;
                    }
                }
                
                // Nếu chưa có, thêm mới
                if (!found && scenarioCount < MAX_SCENARIOS) {
                    scenarios[scenarioCount] = record.scenario;
                    scenarioCount++;
                }
            }
        }
        
        // Tính thống kê cho từng kịch bản
        for (int i = 0; i < scenarioCount; i++) {
            int totalTrades = 0, winTrades = 0;
            double avgProfit = 0.0;
            
            if (m_Storage.GetScenarioStats(scenarios[i], 0, totalTrades, winTrades, avgProfit)) {
                if (totalTrades > 0) {
                    m_ScenarioStats[m_ScenarioCount].name = scenarios[i];
                    m_ScenarioStats[m_ScenarioCount].totalTrades = totalTrades;
                    m_ScenarioStats[m_ScenarioCount].winTrades = winTrades;
                    m_ScenarioStats[m_ScenarioCount].winRate = (double)winTrades / totalTrades;
                    m_ScenarioStats[m_ScenarioCount].avgProfit = avgProfit;
                    m_ScenarioStats[m_ScenarioCount].adjustment = 0.0; // Sẽ tính sau
                    m_ScenarioStats[m_ScenarioCount].lastUpdate = TimeCurrent();
                    
                    m_ScenarioCount++;
                }
            }
        }
    }
    
    // Cập nhật thống kê theo kịch bản
    void UpdateScenarioStats(string scenario, bool win, double profit) {
        // Tìm kịch bản
        int index = -1;
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].name == scenario) {
                index = i;
                break;
            }
        }
        
        // Nếu chưa có, thêm mới
        if (index == -1) {
            if (m_ScenarioCount < MAX_SCENARIOS) {
                index = m_ScenarioCount;
                m_ScenarioStats[index].name = scenario;
                m_ScenarioStats[index].totalTrades = 0;
                m_ScenarioStats[index].winTrades = 0;
                m_ScenarioStats[index].winRate = 0.5;
                m_ScenarioStats[index].avgProfit = 0.0;
                m_ScenarioStats[index].adjustment = 0.0;
                m_ScenarioCount++;
            } else {
                // Tìm kịch bản ít giao dịch nhất để thay thế
                int leastUsedIndex = 0;
                int minTrades = m_ScenarioStats[0].totalTrades;
                
                for (int i = 1; i < m_ScenarioCount; i++) {
                    if (m_ScenarioStats[i].totalTrades < minTrades) {
                        minTrades = m_ScenarioStats[i].totalTrades;
                        leastUsedIndex = i;
                    }
                }
                
                index = leastUsedIndex;
                m_ScenarioStats[index].name = scenario;
                m_ScenarioStats[index].totalTrades = 0;
                m_ScenarioStats[index].winTrades = 0;
                m_ScenarioStats[index].winRate = 0.5;
                m_ScenarioStats[index].avgProfit = 0.0;
                m_ScenarioStats[index].adjustment = 0.0;
            }
        }
        
        // Cập nhật thống kê
        m_ScenarioStats[index].totalTrades++;
        if (win) {
            m_ScenarioStats[index].winTrades++;
        }
        
        // Cập nhật tỉ lệ thắng và lợi nhuận trung bình
        m_ScenarioStats[index].winRate = (double)m_ScenarioStats[index].winTrades / m_ScenarioStats[index].totalTrades;
        
        // Điều chỉnh lợi nhuận trung bình
        double oldTotal = m_ScenarioStats[index].avgProfit * (m_ScenarioStats[index].totalTrades - 1);
        m_ScenarioStats[index].avgProfit = (oldTotal + profit) / m_ScenarioStats[index].totalTrades;
        
        // Cập nhật thời gian
        m_ScenarioStats[index].lastUpdate = TimeCurrent();
    }
    
    // Cập nhật thống kê theo phiên
    void UpdateSessionStats(string session, bool win) {
        // Kiểm tra giá trị session và cập nhật tương ứng
        if (session == "Asian") {
            // Cập nhật tỷ lệ thắng phiên Á
            // Logic cập nhật tỷ lệ thắng Asian phiên sẽ được triển khai sau
            // Hiện tại giữ cài đặt đơn giản để minh họa
            if (win) {
                m_AsianWinRate = (m_AsianWinRate * 9 + 1) / 10; // Trọng số 10% cho kết quả mới
            } else {
                m_AsianWinRate = (m_AsianWinRate * 9 + 0) / 10;
            }
        } 
        else if (session == "London") {
            // Cập nhật tỷ lệ thắng phiên London
            if (win) {
                m_LondonWinRate = (m_LondonWinRate * 9 + 1) / 10;
            } else {
                m_LondonWinRate = (m_LondonWinRate * 9 + 0) / 10;
            }
        } 
        else if (session == "NewYork") {
            // Cập nhật tỷ lệ thắng phiên NewYork
            if (win) {
                m_NewYorkWinRate = (m_NewYorkWinRate * 9 + 1) / 10;
            } else {
                m_NewYorkWinRate = (m_NewYorkWinRate * 9 + 0) / 10;
            }
        }
    }
    
    // Tính toán các điều chỉnh
    void CalculateAdjustments() {
        // Chỉ tính toán lại nếu đủ dữ liệu
        if (m_TotalTrades < m_MinimumTrades) {
            return;
        }
        
        // Tính toán điều chỉnh cho các kịch bản
        for (int i = 0; i < m_ScenarioCount; i++) {
            if (m_ScenarioStats[i].totalTrades >= 5) {
                // Điều chỉnh dựa trên mode
                if (m_AdjustmentMode == ADJ_MODE_BASIC) {
                    // Tính toán đơn giản: 50% win rate = 0 adjustment, 75%+ win rate = +0.15, 25%- win rate = -0.15
                    m_ScenarioStats[i].adjustment = (m_ScenarioStats[i].winRate - 0.5) * 0.6;
                }
                else if (m_AdjustmentMode == ADJ_MODE_ADVANCED) {
                    // Dùng hàm sigmoid cho điều chỉnh mượt mà hơn
                    double winRateOffset = m_ScenarioStats[i].winRate - 0.5; // -0.5 đến +0.5
                    double profitFactor = m_ScenarioStats[i].avgProfit / 0.5; // Chuẩn hóa theo R
                    
                    // Giới hạn profitFactor trong khoảng [0.5, 2.0]
                    profitFactor = MathMax(0.5, MathMin(2.0, profitFactor));
                    
                    // Áp dụng công thức sigmoid
                    double sigmoid = 2.0 / (1.0 + MathExp(-4.0 * winRateOffset)) - 1.0; // -1 đến +1
                    
                    // Điều chỉnh cuối cùng
                    m_ScenarioStats[i].adjustment = sigmoid * 0.3 * profitFactor; // Max ±0.3 * profitFactor
                }
                else if (m_AdjustmentMode == ADJ_MODE_TIME_WEIGHTED) {
                    // Điều chỉnh có trọng số theo thời gian
                    double winRateOffset = m_ScenarioStats[i].winRate - 0.5;
                    
                    // Tính số ngày từ lần cập nhật cuối
                    datetime currentTime = TimeCurrent();
                    double daysSinceUpdate = (currentTime - m_ScenarioStats[i].lastUpdate) / 86400.0;
                    
                    // Giảm dần trọng số theo thời gian (giảm 50% sau 30 ngày)
                    double timeFactor = MathExp(-daysSinceUpdate / 30.0);
                    
                    // Điều chỉnh cuối cùng
                    m_ScenarioStats[i].adjustment = winRateOffset * 0.6 * timeFactor;
                }
            }
        }
        
        // Tính toán điều chỉnh cho lệnh mua/bán
        // Cách tiếp cận tương tự kịch bản
        if (m_AdjustmentMode == ADJ_MODE_BASIC) {
            m_LongAdjustment = (m_LongWinRate - 0.5) * 0.4;
            m_ShortAdjustment = (m_ShortWinRate - 0.5) * 0.4;
        }
        else if (m_AdjustmentMode == ADJ_MODE_ADVANCED) {
            // Kết hợp win rate và avg profit
            double longSigmoid = 2.0 / (1.0 + MathExp(-4.0 * (m_LongWinRate - 0.5))) - 1.0;
            double shortSigmoid = 2.0 / (1.0 + MathExp(-4.0 * (m_ShortWinRate - 0.5))) - 1.0;
            
            double longProfitFactor = MathMax(0.5, MathMin(2.0, m_LongAvgProfit / 0.5));
            double shortProfitFactor = MathMax(0.5, MathMin(2.0, m_ShortAvgProfit / 0.5));
            
            m_LongAdjustment = longSigmoid * 0.2 * longProfitFactor;
            m_ShortAdjustment = shortSigmoid * 0.2 * shortProfitFactor;
        }
        else if (m_AdjustmentMode == ADJ_MODE_TIME_WEIGHTED) {
            // Các điều chỉnh có thể thêm tại đây
            m_LongAdjustment = (m_LongWinRate - 0.5) * 0.4;
            m_ShortAdjustment = (m_ShortWinRate - 0.5) * 0.4;
        }
    }
    
//+------------------------------------------------------------------+
//| Nạp dữ liệu profile                                              |
//+------------------------------------------------------------------+
/* Hàm nạp profile - đã khai báo ở phần public */
bool CAssetProfiler::LoadProfileData() {
    string historyFile = "AP_History_" + m_Symbol + ".dat";
    string configFile = "AP_Config_" + m_Symbol + ".dat";
    
    bool historyExists = FileIsExist(historyFile, FILE_COMMON);
    bool configExists = FileIsExist(configFile, FILE_COMMON);
    
    bool historyLoaded = m_Storage.LoadHistoryFromFile(historyFile);
    if (!historyLoaded) {
        LogMessage("Không thể nạp lịch sử từ file: " + historyFile, PROFILE_LOG_ERRORS);
        return false;
    }
    
    if (configExists) {
        int fileHandle = FileOpen(configFile, FILE_READ|FILE_BIN|FILE_COMMON);
        if (fileHandle != INVALID_HANDLE) {
            int configVersion = FileReadInteger(fileHandle);
            m_MinimumTrades = FileReadInteger(fileHandle);
            m_AdaptPercent = FileReadDouble(fileHandle);
            m_LogLevel = (ENUM_PROFILE_LOG_LEVEL)FileReadInteger(fileHandle);
            m_AdjustmentMode = (ENUM_ADJUSTMENT_MODE)FileReadInteger(fileHandle);
            FileClose(fileHandle);
        }
    }
    return true;
}
        
//+------------------------------------------------------------------+
//| Lưu dữ liệu profile                                          |
//+------------------------------------------------------------------+
bool CAssetProfiler::SaveProfileData() {
    string historyFile = "AP_History_" + m_Symbol + ".dat";
    string configFile = "AP_Config_" + m_Symbol + ".dat";
    
    bool historySaved = m_Storage.SaveHistoryToFile(historyFile);
    if (!historySaved) {
        LogMessage("Không thể lưu lịch sử vào file: " + historyFile, PROFILE_LOG_ERRORS);
        return false;
    }
    
    int fileHandle = FileOpen(configFile, FILE_WRITE|FILE_BIN|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogMessage("Không thể mở file để lưu dữ liệu: " + configFile, PROFILE_LOG_ERRORS);
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
void CAssetProfiler::LogMessage(string message, ENUM_PROFILE_LOG_LEVEL level) {
    if (m_Logger == NULL || level > m_LogLevel) {
        return;
    }
    
    switch (level) {
        case PROFILE_LOG_ERRORS:
            m_Logger.LogError(message);
            break;
            
        case PROFILE_LOG_IMPORTANT:
            m_Logger.LogInfo(message);
            break;
            
        case PROFILE_LOG_ALL:
            m_Logger.LogDebug(message);
            break;
    }
}
    
//+------------------------------------------------------------------+
//| Phương thức lưu thông tin profile tài sản                        |
//+------------------------------------------------------------------+
bool CAssetProfiler::SaveAssetProfile(const AssetProfile &profile) {
        // Cài đặt giá trị thiết lập từ profile
        m_Symbol = profile.symbol;
        
        // Lưu dữ liệu vào file nếu cần
        string filename = "AP_Config_" + m_Symbol + ".dat";
        int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
        if (fileHandle == INVALID_HANDLE) {
            LogMessage("Không thể mở file để lưu dữ liệu: " + filename, PROFILE_LOG_ERRORS);
            return false;
        }
        
        // Lưu phiên bản dữ liệu
        FileWriteInteger(fileHandle, DATA_VERSION);
        
        // Đóng file
        FileClose(fileHandle);
        
        return true;
    }
    
//+------------------------------------------------------------------+
//| Kiểm tra xem các EMA có xếp hàng theo đúng chiều giao dịch       |
//+------------------------------------------------------------------+
bool CAssetProfiler::IsEMAAligned(bool isLong) {
    double ema34 = iMA(_Symbol, PERIOD_CURRENT, 34, 0, MODE_EMA, PRICE_CLOSE);
    double ema89 = iMA(_Symbol, PERIOD_CURRENT, 89, 0, MODE_EMA, PRICE_CLOSE);
    double ema200 = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    if (isLong) {
        return (ema34 > ema89 && ema89 > ema200);
    } else {
        return (ema34 < ema89 && ema89 < ema200);
    }
}
//+------------------------------------------------------------------+
//| Kiểm tra xem giá có nằm ngoài vùng giá trị không                 |
//+------------------------------------------------------------------+
bool CAssetProfiler::IsPriceOutsideValueArea(double price, bool checkHigh) {
    // Xác định vùng giá trị dựa trên giá cao/thấp nhất của ngày
    double valueAreaHigh = iHigh(_Symbol, PERIOD_D1, 0) * 0.99; // 99% giá cao nhất
    double valueAreaLow = iLow(_Symbol, PERIOD_D1, 0) * 1.01;   // 101% giá thấp nhất
    
    if (checkHigh) {
            // Kiểm tra xem giá có cao hơn vùng giá trị cao không
            return (price > valueAreaHigh);
        } else {
            // Kiểm tra xem giá có thấp hơn vùng giá trị thấp không
            return (price < valueAreaLow);
        }
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