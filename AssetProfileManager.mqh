//+------------------------------------------------------------------+
//|                                           AssetProfileManager.mqh |
//|                              APEX Pullback EA v14.0 - Module Code |
//|                        © 2024 APEX Trading Software               |
//+------------------------------------------------------------------+
// Copyright 2024 APEX Trading Software
// Link: https://www.apexpullback.com
// Version: 14.0

// FIX: Thêm bảo vệ include để tránh trùng lặp định nghĩa
#ifndef _ASSET_PROFILE_MANAGER_MQH_
#define _ASSET_PROFILE_MANAGER_MQH_

// Include cần thiết
#include "Logger.mqh"
#include "Enums.mqh"
#include "CommonStructs.mqh" // Đảm bảo CommonStructs được include

// Định nghĩa hằng số

// Sử dụng namespace ApexPullback để đảm bảo tính nhất quán với EA chính
namespace ApexPullback {
const int MAX_ASSETS_PROFILE = 50;     // Số lượng tài sản tối đa có thể quản lý
// const int MAX_HISTORY_DAYS = 30;    // Đã được định nghĩa trong CommonStructs.mqh (nếu có, hoặc cần thêm vào Constants.mqh)
const int TRADING_DAYS_PER_YEAR = 252; // Số ngày giao dịch trong năm

// Using AssetProfile from CommonStructs.mqh

//+------------------------------------------------------------------+
//| Lớp CAssetProfileManager - Quản lý thông tin tài sản             |
//+------------------------------------------------------------------+
class CAssetProfileManager {
private:
    string m_CurrentSymbol;                    // Biểu tượng hiện tại
    ENUM_TIMEFRAMES m_MainTimeframe;           // Khung thời gian chính
    AssetProfile m_AssetProfiles[MAX_ASSETS_PROFILE]; // Mảng lưu thông tin tài sản
    int m_ProfileCount;                        // Số lượng profile đã lưu
    CLogger *m_Logger;                         // Con trỏ đến Logger
    bool m_isInitialized;                      // Đã khởi tạo chưa
    bool m_AutoUpdateEnabled;                  // Tự động cập nhật profile
    int m_ATRPeriod;                           // Số nến cho ATR
    bool m_SaveProfiles;                       // Lưu profiles vào file
    string m_StorageFolder;                    // Thư mục lưu trữ
    
    // Biến lưu trữ dữ liệu ưu đãi
    AssetProfile m_CurrentAssetProfile;    // Thông tin tài sản hiện tại (cache)
    double m_LastSpread;                       // Giá trị spread lần cuối
    double m_CurrentATR;                       // Giá trị ATR hiện tại
    datetime m_LastATRUpdate;                  // Thời gian cập nhật ATR
    datetime m_LastSpreadUpdate;               // Thời gian cập nhật spread
    
    // Phạm vi cập nhật và lấy mẫu
    int m_UpdateIntervalMinutes;               // Khoảng thời gian cập nhật (phút)
    int m_SpreadSampleCount;                   // Số mẫu lấy cho spread
    
    // Các giá trị mặc định theo loại tài sản
    double m_DefaultSpreadThresholds[5];       // Ngưỡng spread mặc định theo loại tài sản
    double m_DefaultATRMultipliers[5];         // Hệ số ATR mặc định theo loại tài sản
    double m_DefaultRiskPercents[5];           // % Risk mặc định theo loại tài sản

public:
    // Constructor và Destructor
    CAssetProfileManager();
    ~CAssetProfileManager();
    
    // Phương thức khởi tạo
    bool Initialize(string symbol, ENUM_TIMEFRAMES timeframe, CLogger *logger);
    void SetParameters(int atrPeriod, bool saveProfiles, string storageFolder = "AssetProfiles");
    void SetUpdateParameters(int updateIntervalMins = 60, int spreadSampleCount = 50);
    void EnableAutoUpdate(bool enable);
    
    // Phương thức cập nhật và phân tích
    bool Update();
    bool UpdateCurrentSymbol(bool forceUpdate = false);
    bool AnalyzeSymbol(string symbol, AssetProfile &profile, bool forceAnalysis = false);
    bool DetectAssetClass(string symbol, AssetProfile &profile);
    bool UpdateHistoricalData(AssetProfile &profile);
    
    // Các phương thức truy vấn thông tin
    bool GetCurrentAssetProfile(AssetProfile &profile);
    bool GetAssetProfile(string symbol, AssetProfile &profile);
    ENUM_ASSET_CLASS GetAssetClass(string symbol = "");
    ENUM_SYMBOL_GROUP GetSymbolGroup(string symbol = "");
    
    // Phương thức kiểm tra sự căn chỉnh của các đường EMA
    bool IsEMAAligned(bool isLong, string symbol = "");
    
    // Phương thức kiểm tra giá nằm ngoài vùng giá trị
    bool IsPriceOutsideValueArea(double price, bool checkHigh = true, string symbol = "");
    
    // Các phương thức tính toán tối ưu
    double GetOptimalSLPoints(string symbol = "");
    double GetOptimalTPPoints(string symbol = "", double slPoints = 0);
    double GetOptimalTrailingPoints(string symbol = "");
    double GetAcceptableSpreadPoints(string symbol = "");
    double GetRecommendedRiskPercent(string symbol = "", double baseRisk = 1.0);
    int GetOptimalTradingSession(string symbol = "");
    
    // Các phương thức tiện ích
    double GetAverageATR(string symbol = "");
    double GetAverageATRPoints(string symbol = "");
    double GetCurrentATR(string symbol = "");
    double GetCurrentSpreadPoints(string symbol = "");
    double NormalizeToPoints(string symbol, double value);
    double NormalizeToPrice(string symbol, double points);
    
    // Phương thức lưu trữ và tải
    bool SaveAllProfiles();
    bool LoadAllProfiles();
    bool SaveAssetProfile(const AssetProfile &profile);
    bool LoadAssetProfile(string symbol, AssetProfile &profile);
    void CreateProfileFolderIfNotExists();
    
private:
    // Phương thức nội bộ hỗ trợ
    bool GetHistoricalATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, double &atrArray[]);
    double CalculateAverageATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, int bars);
    double CalculateYearlyVolatility(string symbol);
    double GetDefaultAcceptableSpread(ENUM_ASSET_CLASS assetClass);
    double GetDefaultATRMultiplier(ENUM_ASSET_CLASS assetClass);
    double GetDefaultRiskPercent(ENUM_ASSET_CLASS assetClass);
    int GetProfileIndex(string symbol);
    void LogInfo(string message, bool important = false);
    string GetProfileFilename(string symbol);
    void InitializeDefaultValues();
};

// FIX: Định nghĩa các phương thức trong cùng namespace

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CAssetProfileManager::CAssetProfileManager(void) {
    m_CurrentSymbol = _Symbol;
    m_MainTimeframe = PERIOD_CURRENT;
    m_ProfileCount = 0;
    m_Logger = NULL;
    m_isInitialized = false;
    m_AutoUpdateEnabled = true;
    m_ATRPeriod = DEFAULT_ATR_PERIOD;
    m_SaveProfiles = true;
    m_StorageFolder = "AssetProfiles";
    
    m_LastSpread = 0;
    m_CurrentATR = 0;
    m_LastATRUpdate = 0;
    m_LastSpreadUpdate = 0;
    
    m_UpdateIntervalMinutes = 60;
    m_SpreadSampleCount = 50;
    
    // Khởi tạo giá trị mặc định
    InitializeDefaultValues();
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CAssetProfileManager::~CAssetProfileManager() {
    // Lưu dữ liệu trước khi hủy đối tượng nếu đã khởi tạo
    if (m_isInitialized && m_SaveProfiles) {
        SaveAllProfiles();
    }
}

//+------------------------------------------------------------------+
//| Khởi tạo các giá trị mặc định theo loại tài sản                  |
//+------------------------------------------------------------------+
void CAssetProfileManager::InitializeDefaultValues() {
    // Giả định ENUM_ASSET_CLASS có các giá trị ASSET_CLASS_FOREX=0, ASSET_CLASS_METALS=1, ...
    // Nếu định nghĩa enum khác, cần điều chỉnh chỉ số hoặc sử dụng cấu trúc map/switch.
    m_DefaultSpreadThresholds[ASSET_CLASS_FOREX] = 30.0;   // ASSET_CLASS_FOREX
    m_DefaultSpreadThresholds[ASSET_CLASS_METALS] = 100.0;  // ASSET_CLASS_METALS
    m_DefaultSpreadThresholds[ASSET_CLASS_INDICES] = 50.0;   // ASSET_CLASS_INDICES
    m_DefaultSpreadThresholds[ASSET_CLASS_CRYPTO] = 200.0;  // ASSET_CLASS_CRYPTO
    m_DefaultSpreadThresholds[ASSET_CLASS_OTHER] = 50.0;   // ASSET_CLASS_OTHER

    m_DefaultATRMultipliers[ASSET_CLASS_FOREX] = 1.5;      // ASSET_CLASS_FOREX
    m_DefaultATRMultipliers[ASSET_CLASS_METALS] = 1.2;      // ASSET_CLASS_METALS
    m_DefaultATRMultipliers[ASSET_CLASS_INDICES] = 1.3;      // ASSET_CLASS_INDICES
    m_DefaultATRMultipliers[ASSET_CLASS_CRYPTO] = 2.0;      // ASSET_CLASS_CRYPTO
    m_DefaultATRMultipliers[ASSET_CLASS_OTHER] = 1.5;      // ASSET_CLASS_OTHER

    m_DefaultRiskPercents[ASSET_CLASS_FOREX] = 1.0;        // ASSET_CLASS_FOREX
    m_DefaultRiskPercents[ASSET_CLASS_METALS] = 0.75;       // ASSET_CLASS_METALS
    m_DefaultRiskPercents[ASSET_CLASS_INDICES] = 0.75;       // ASSET_CLASS_INDICES
    m_DefaultRiskPercents[ASSET_CLASS_CRYPTO] = 0.5;        // ASSET_CLASS_CRYPTO
    m_DefaultRiskPercents[ASSET_CLASS_OTHER] = 0.75;       // ASSET_CLASS_OTHER
}

//+------------------------------------------------------------------+
//| Khởi tạo Asset Profile Manager                                   |
//+------------------------------------------------------------------+
bool CAssetProfileManager::Initialize(string symbol, ENUM_TIMEFRAMES timeframe, CLogger *logger) {
    // Lưu các tham số
    m_CurrentSymbol = (symbol == "") ? _Symbol : symbol;
    m_MainTimeframe = (timeframe == PERIOD_CURRENT) ? Period() : timeframe;
    m_Logger = logger;
    
    // Kiểm tra Logger
    if (m_Logger == NULL) {
        Print("CẢNH BÁO: AssetProfileManager không được cung cấp Logger hợp lệ");
        return false;
    }
    
    // Tạo thư mục lưu trữ nếu chưa tồn tại
    CreateProfileFolderIfNotExists();
    
    // Tải các profile đã lưu
    LoadAllProfiles();
    
    // Khởi tạo profile cho symbol hiện tại nếu chưa có
    AssetProfileData currentProfile;
    if (GetProfileIndex(m_CurrentSymbol) < 0) {
        // Phân tích và tạo profile mới
        if (!AnalyzeSymbol(m_CurrentSymbol, currentProfile)) {
            LogInfo("Không thể phân tích và tạo profile cho " + m_CurrentSymbol, true);
            return false;
        }
        
        // Thêm vào danh sách profile
        if (m_ProfileCount < MAX_ASSETS_PROFILE) {
            m_AssetProfiles[m_ProfileCount] = currentProfile;
            m_ProfileCount++;
            LogInfo("Đã tạo profile mới cho " + m_CurrentSymbol);
        } else {
            LogInfo("Đã đạt giới hạn số lượng profile: " + IntegerToString(MAX_ASSETS_PROFILE), true);
            return false;
        }
    } else {
        // Lấy profile từ danh sách đã có
        currentProfile = m_AssetProfiles[GetProfileIndex(m_CurrentSymbol)];
        LogInfo("Đã tải profile cho " + m_CurrentSymbol + " từ bộ nhớ cache");
    }
    
    // Lưu profile hiện tại
    m_CurrentAssetProfile = currentProfile;
    
    // Cập nhật giá trị ATR hiện tại
    m_CurrentATR = CalculateAverageATR(m_CurrentSymbol, m_MainTimeframe, m_ATRPeriod, 1);
    m_LastATRUpdate = TimeCurrent();
    
    // Cập nhật giá trị spread hiện tại
    m_LastSpread = SymbolInfoInteger(m_CurrentSymbol, SYMBOL_SPREAD) * SymbolInfoDouble(m_CurrentSymbol, SYMBOL_POINT);
    m_LastSpreadUpdate = TimeCurrent();
    
    m_isInitialized = true;
    LogInfo("AssetProfileManager đã khởi tạo thành công cho " + m_CurrentSymbol, true);
    
    return true;
}

// FIX: Thêm các phương thức còn lại của lớp CAssetProfileManager với cùng cách định nghĩa
// Giữ nguyên các định nghĩa phương thức khác từ file gốc nhưng đảm bảo đúng cú pháp
// CAssetProfileManager::TênPhươngThức

//+------------------------------------------------------------------+
//| Thiết lập các tham số cấu hình                                   |
//+------------------------------------------------------------------+
void CAssetProfileManager::SetParameters(int atrPeriod, bool saveProfiles, string storageFolder) {
    m_ATRPeriod = atrPeriod;
    m_SaveProfiles = saveProfiles;
    m_StorageFolder = storageFolder;
    
    // Tạo thư mục mới nếu đã thay đổi
    CreateProfileFolderIfNotExists();
    
    LogInfo("Đã cập nhật tham số: ATRPeriod=" + IntegerToString(m_ATRPeriod) + 
           ", SaveProfiles=" + (m_SaveProfiles ? "true" : "false") +
           ", StorageFolder=" + m_StorageFolder);
}

//+------------------------------------------------------------------+
//| Thiết lập tham số cập nhật                                       |
//+------------------------------------------------------------------+
void CAssetProfileManager::SetUpdateParameters(int updateIntervalMins, int spreadSampleCount) {
    m_UpdateIntervalMinutes = updateIntervalMins;
    m_SpreadSampleCount = spreadSampleCount;
    
    LogInfo("Đã cập nhật tham số cập nhật: Interval=" + IntegerToString(m_UpdateIntervalMinutes) + 
           "phút, SpreadSamples=" + IntegerToString(m_SpreadSampleCount));
}

//+------------------------------------------------------------------+
//| Bật/tắt tự động cập nhật                                         |
//+------------------------------------------------------------------+
void CAssetProfileManager::EnableAutoUpdate(bool enable) {
    m_AutoUpdateEnabled = enable;
    LogInfo("Đã " + (enable ? "bật" : "tắt") + " tự động cập nhật profile");
}

//+------------------------------------------------------------------+
//| Cập nhật tất cả các profile                                      |
//+------------------------------------------------------------------+
bool CAssetProfileManager::Update() {
    if (!m_isInitialized) return false;
    
    bool success = true;
    
    // Đầu tiên cập nhật symbol hiện tại
    if (!UpdateCurrentSymbol()) {
        LogInfo("Không thể cập nhật profile cho symbol hiện tại: " + m_CurrentSymbol, true);
        success = false;
    }
    
    // Cập nhật các profile khác nếu cần
    for (int i = 0; i < m_ProfileCount; i++) {
        // Bỏ qua symbol hiện tại vì đã cập nhật ở trên
        if (m_AssetProfiles[i].symbol == m_CurrentSymbol) continue;
        
        // Kiểm tra thời gian cần cập nhật
        if (TimeCurrent() - m_AssetProfiles[i].lastUpdated > m_UpdateIntervalMinutes * 60) {
            // Sử dụng trực tiếp m_AssetProfiles[i] thay vì tham chiếu cục bộ
            if (!AnalyzeSymbol(m_AssetProfiles[i].symbol, m_AssetProfiles[i])) {
                LogInfo("Không thể cập nhật profile cho: " + m_AssetProfiles[i].symbol, true);
                success = false;
            }
        }
    }
    
    // Lưu các profile nếu được cấu hình
    if (m_SaveProfiles) {
        SaveAllProfiles();
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Cập nhật profile cho symbol hiện tại                             |
//+------------------------------------------------------------------+
bool CAssetProfileManager::UpdateCurrentSymbol(bool forceUpdate) {
    if (!m_isInitialized) return false;
    
    // Kiểm tra thời gian cần cập nhật nếu không phải force update
    if (!forceUpdate) {
        datetime currentTime = TimeCurrent();
        // Chỉ cập nhật nếu đã quá thời gian quy định
        if (currentTime - m_CurrentAssetProfile.lastUpdated < m_UpdateIntervalMinutes * 60)
            return true;
    }
    
    // Cập nhật profile cho symbol hiện tại
    if (!AnalyzeSymbol(m_CurrentSymbol, m_CurrentAssetProfile, forceUpdate)) {
        LogInfo("Không thể phân tích symbol hiện tại: " + m_CurrentSymbol, true);
        return false;
    }
    
    // Cập nhật cache hiện tại
    int index = GetProfileIndex(m_CurrentSymbol);
    if (index >= 0) {
        m_AssetProfiles[index] = m_CurrentAssetProfile;
    }
    else if (m_ProfileCount < MAX_ASSETS_PROFILE) {
        // Thêm mới nếu chưa có trong danh sách
        m_AssetProfiles[m_ProfileCount] = m_CurrentAssetProfile;
        m_ProfileCount++;
    }
    
    // Cập nhật giá trị ATR hiện tại
    m_CurrentATR = CalculateAverageATR(m_CurrentSymbol, m_MainTimeframe, m_ATRPeriod, 1);
    m_LastATRUpdate = TimeCurrent();
    
    // Cập nhật giá trị spread hiện tại
    m_LastSpread = SymbolInfoInteger(m_CurrentSymbol, SYMBOL_SPREAD) * SymbolInfoDouble(m_CurrentSymbol, SYMBOL_POINT);
    m_LastSpreadUpdate = TimeCurrent();
    
    return true;
}



//+------------------------------------------------------------------+
//| Phân tích và tạo profile cho một symbol                          |
//+------------------------------------------------------------------+
bool CAssetProfileManager::AnalyzeSymbol(string symbol, AssetProfileData &profile, bool forceAnalysis) {
    if (symbol == "") {
        LogInfo("Symbol không được trống", true);
        return false;
    }
    
    // Kiểm tra symbol tồn tại
    if (!SymbolSelect(symbol, true)) {
        LogInfo("Symbol không tồn tại hoặc không thể chọn: " + symbol, true);
        return false;
    }
    
    // Lưu symbol vào profile
    profile.symbol = symbol;
    
    // Phát hiện loại tài sản nếu chưa có
    if (profile.assetClass == ASSET_CLASS_FOREX || forceAnalysis) {
        DetectAssetClass(symbol, profile);
    }
    
    // Tính toán ATR trung bình
    double atr = CalculateAverageATR(symbol, m_MainTimeframe, m_ATRPeriod, 20);
    if (atr > 0) {
        profile.averageATR = atr;
        profile.averageATRPoints = NormalizeToPoints(symbol, atr);
    }
    
    // Tính toán biến động hàng năm
    double yearlyVol = CalculateYearlyVolatility(symbol);
    if (yearlyVol > 0) {
        profile.yearlyVolatility = yearlyVol;
    }
    
    // Lấy thông tin spread
    double currentSpread = SymbolInfoInteger(symbol, SYMBOL_SPREAD) * SymbolInfoDouble(symbol, SYMBOL_POINT);
    profile.minSpread = (profile.minSpread > 0) ? MathMin(profile.minSpread, currentSpread) : currentSpread;
    profile.maxSpread = MathMax(profile.maxSpread, currentSpread);
    
    // Cập nhật spread trung bình
    if (profile.historyCount > 0) {
        double totalSpread = 0;
        int count = MathMin(profile.historyCount, 20); // Sử dụng tối đa 20 mẫu gần nhất
        for (int i = 0; i < count; i++) {
            totalSpread += profile.spreadHistory[i];
        }
        profile.averageSpread = totalSpread / count;
    } else {
        profile.averageSpread = currentSpread;
    }
    
    // Thiết lập ngưỡng spread chấp nhận được
    if (profile.acceptableSpread <= 0 || forceAnalysis) {
        // Đặt ngưỡng là 1.5x spread trung bình hoặc giá trị mặc định theo loại tài sản
        double defaultThreshold = GetDefaultAcceptableSpread(profile.assetClass);
        profile.acceptableSpread = MathMax(profile.averageSpread * 1.5, defaultThreshold);
    }
    
    // Cập nhật các tham số tối ưu
    if (profile.optimalSLATRMulti <= 0 || forceAnalysis) {
        profile.optimalSLATRMulti = GetDefaultATRMultiplier(profile.assetClass);
    }
    
    if (profile.optimalTRAtrMulti <= 0 || forceAnalysis) {
        profile.optimalTRAtrMulti = profile.optimalSLATRMulti * 1.3; // 30% cao hơn SL
    }
    
    if (profile.optimalRRRatio <= 0 || forceAnalysis) {
        profile.optimalRRRatio = 2.0; // Mặc định R:R = 2.0
    }
    
    if (profile.recommendedRiskPercent <= 0 || forceAnalysis) {
        profile.recommendedRiskPercent = GetDefaultRiskPercent(profile.assetClass);
    }
    
    // Cập nhật phiên tốt nhất/tệ nhất nếu chưa có
    if (profile.bestTradingSession == 0 || forceAnalysis) {
        // Mặc định: London + NY
        profile.bestTradingSession = 6; // 2 + 4
    }
    
    if (profile.worstTradingSession == 0 || forceAnalysis) {
        // Mặc định: Asian
        profile.worstTradingSession = 1;
    }
    
    // Cập nhật dữ liệu lịch sử nếu cần
    UpdateHistoricalData(profile);
    
    // Cập nhật thời gian cập nhật cuối
    profile.lastUpdated = TimeCurrent();
    
    return true;
}

//+------------------------------------------------------------------+
//| Phát hiện loại tài sản dựa trên symbol                           |
//+------------------------------------------------------------------+
bool CAssetProfileManager::DetectAssetClass(string symbol, AssetProfileData &profile) {
    if (symbol == "") return false;
    
    // Mặc định là Forex
    profile.assetClass = ASSET_CLASS_FOREX;
    profile.symbolGroup = GROUP_UNDEFINED;
    
    // Kiểm tra các loại tài sản dựa trên quy tắc đặt tên thông thường
    
    // Kiểm tra Forex
    if (StringLen(symbol) == 6) {
        profile.assetClass = ASSET_CLASS_FOREX;
        
        // Xác định nhóm cặp tiền
        string baseCurrency = StringSubstr(symbol, 0, 3);
        string quoteCurrency = StringSubstr(symbol, 3, 3);
        
        // Major pairs
        if ((baseCurrency == "EUR" || baseCurrency == "GBP" || 
             baseCurrency == "AUD" || baseCurrency == "NZD" || 
             baseCurrency == "USD" || baseCurrency == "CAD" || 
             baseCurrency == "CHF" || baseCurrency == "JPY") && 
            (quoteCurrency == "USD" || quoteCurrency == "EUR" || 
             quoteCurrency == "JPY" || quoteCurrency == "GBP" || 
             quoteCurrency == "CHF" || quoteCurrency == "CAD" || 
             quoteCurrency == "AUD" || quoteCurrency == "NZD")) {
            
            // Chỉ EUR, GBP, AUD, NZD, USD, CAD, CHF, JPY là major
            if ((baseCurrency == "EUR" || baseCurrency == "GBP" || 
                 baseCurrency == "AUD" || baseCurrency == "NZD" || 
                 baseCurrency == "USD" || baseCurrency == "CAD" || 
                 baseCurrency == "CHF" || baseCurrency == "JPY") && 
                (quoteCurrency == "USD" || quoteCurrency == "EUR" || 
                 quoteCurrency == "JPY" || quoteCurrency == "GBP")) {
                profile.symbolGroup = GROUP_MAJOR;
            } else {
                profile.symbolGroup = GROUP_MINOR;
            }
        } else {
            // Exotic pairs
            profile.symbolGroup = GROUP_EXOTIC;
        }
    }
    // Kiểm tra Metals
    else if (StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "SILVER") >= 0 || 
             StringFind(symbol, "PLAT") >= 0 || StringFind(symbol, "XAU") >= 0 || 
             StringFind(symbol, "XAG") >= 0) {
        profile.assetClass = ASSET_CLASS_METALS;
        
        // Xác định nhóm kim loại
        if (StringFind(symbol, "GOLD") >= 0 || StringFind(symbol, "XAU") >= 0) {
            profile.symbolGroup = GROUP_GOLD;
        } else if (StringFind(symbol, "SILVER") >= 0 || StringFind(symbol, "XAG") >= 0) {
            profile.symbolGroup = GROUP_SILVER;
        } else {
            profile.symbolGroup = GROUP_METALS_OTHER;
        }
    }
    // Kiểm tra Indices
    else if (StringFind(symbol, "US30") >= 0 || StringFind(symbol, "US500") >= 0 || 
             StringFind(symbol, "USTEC") >= 0 || StringFind(symbol, "DE30") >= 0 || 
             StringFind(symbol, "UK100") >= 0 || StringFind(symbol, "JP225") >= 0 || 
             StringFind(symbol, "NAS") >= 0 || StringFind(symbol, "SPX") >= 0 || 
             StringFind(symbol, "DOW") >= 0 || StringFind(symbol, "DAX") >= 0 || 
             StringFind(symbol, "FTSE") >= 0 || StringFind(symbol, "NIKKEI") >= 0) {
        profile.assetClass = ASSET_CLASS_INDICES;
        
        // Xác định nhóm chỉ số
        if (StringFind(symbol, "US") >= 0 || StringFind(symbol, "NAS") >= 0 || 
            StringFind(symbol, "SPX") >= 0 || StringFind(symbol, "DOW") >= 0) {
            profile.symbolGroup = GROUP_US_INDICES;
        } else if (StringFind(symbol, "EU") >= 0 || StringFind(symbol, "DE") >= 0 || 
                  StringFind(symbol, "UK") >= 0 || StringFind(symbol, "DAX") >= 0 || 
                  StringFind(symbol, "FTSE") >= 0) {
            profile.symbolGroup = GROUP_EU_INDICES;
        } else if (StringFind(symbol, "JP") >= 0 || StringFind(symbol, "NIKKEI") >= 0) {
            profile.symbolGroup = GROUP_ASIAN_INDICES;
        } else {
            profile.symbolGroup = GROUP_INDICES_OTHER;
        }
    }
    // Kiểm tra Crypto
    else if (StringFind(symbol, "BTC") >= 0 || StringFind(symbol, "ETH") >= 0 || 
             StringFind(symbol, "LTC") >= 0 || StringFind(symbol, "XRP") >= 0 || 
             StringFind(symbol, "BCH") >= 0 || StringFind(symbol, "EOS") >= 0) {
        profile.assetClass = ASSET_CLASS_CRYPTO;
        profile.symbolGroup = GROUP_CRYPTO;
    }
    // Kiểm tra Oil/Energy
    else if (StringFind(symbol, "OIL") >= 0 || StringFind(symbol, "BRENT") >= 0 || 
             StringFind(symbol, "WTI") >= 0 || StringFind(symbol, "GAS") >= 0) {
        profile.assetClass = ASSET_CLASS_OTHER;
        profile.symbolGroup = GROUP_ENERGY;
    } else {
        // Mặc định là OTHER
        profile.assetClass = ASSET_CLASS_OTHER;
        profile.symbolGroup = GROUP_UNDEFINED;
    }
    
    // Xác định mức độ biến động dựa trên loại tài sản
    switch (profile.assetClass) {
        case ASSET_CLASS_FOREX:
            if (profile.symbolGroup == GROUP_MAJOR) {
                profile.volatilityLevel = VOLATILITY_LOW;
            } else if (profile.symbolGroup == GROUP_MINOR) {
                profile.volatilityLevel = VOLATILITY_MEDIUM;
            } else {
                profile.volatilityLevel = VOLATILITY_HIGH;
            }
            break;
            
        case ASSET_CLASS_METALS:
            profile.volatilityLevel = VOLATILITY_MEDIUM;
            break;
            
        case ASSET_CLASS_INDICES:
            profile.volatilityLevel = VOLATILITY_MEDIUM;
            break;
            
        case ASSET_CLASS_CRYPTO:
            profile.volatilityLevel = VOLATILITY_EXTREME;
            break;
            
        default:
            profile.volatilityLevel = VOLATILITY_MEDIUM;
            break;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Cập nhật dữ liệu lịch sử cho profile                             |
//+------------------------------------------------------------------+
bool CAssetProfileManager::UpdateHistoricalData(AssetProfileData &profile) {
    // Lấy thời gian hiện tại
    datetime currentTime = TimeCurrent();
    
    // Kiểm tra xem cần cập nhật không
    bool needUpdate = (profile.historyCount == 0 || 
                     currentTime - profile.historyDates[0] > 86400); // 1 ngày
    
    if (!needUpdate) return true;
    
    // Dịch chuyển dữ liệu lịch sử
    for (int i = MAX_HISTORY_DAYS - 1; i > 0; i--) {
        profile.atrHistory[i] = profile.atrHistory[i-1];
        profile.spreadHistory[i] = profile.spreadHistory[i-1];
        profile.historyDates[i] = profile.historyDates[i-1];
    }
    
    // Cập nhật mẫu mới nhất
    profile.atrHistory[0] = profile.averageATR;
    profile.spreadHistory[0] = SymbolInfoInteger(profile.symbol, SYMBOL_SPREAD) * 
                            SymbolInfoDouble(profile.symbol, SYMBOL_POINT);
    profile.historyDates[0] = currentTime;
    
    // Cập nhật số lượng mẫu
    if (profile.historyCount < MAX_HISTORY_DAYS) {
        profile.historyCount++;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Lấy thông tin profile cho symbol hiện tại                         |
//+------------------------------------------------------------------+
bool CAssetProfileManager::GetCurrentAssetProfile(AssetProfileData &profile) {
    if (m_AutoUpdateEnabled) {
        datetime currentTime = TimeCurrent();
        if (currentTime - m_CurrentAssetProfile.lastUpdated > m_UpdateIntervalMinutes * 60) {
            UpdateCurrentSymbol();
        }
    }
    profile = m_CurrentAssetProfile;
    return true;
}

//+------------------------------------------------------------------+
//| Lấy thông tin profile cho một symbol cụ thể                      |
//+------------------------------------------------------------------+
bool CAssetProfileManager::GetAssetProfile(string symbol, AssetProfileData& profile) {
    if (symbol == "" || symbol == m_CurrentSymbol) {
        return GetCurrentAssetProfile(profile);
    }
    int index = GetProfileIndex(symbol);
    if (index >= 0) {
        if (m_AutoUpdateEnabled) {
            datetime currentTime = TimeCurrent();
            if (currentTime - m_AssetProfiles[index].lastUpdated > m_UpdateIntervalMinutes * 60) {
                AnalyzeSymbol(symbol, m_AssetProfiles[index]);
            }
        }
        profile = m_AssetProfiles[index];
        return true;
    }
    if (m_ProfileCount < MAX_ASSETS_PROFILE) {
        AssetProfileData newProfile;
        if (AnalyzeSymbol(symbol, newProfile)) {
            m_AssetProfiles[m_ProfileCount] = newProfile;
            m_ProfileCount++;
            profile = m_AssetProfiles[m_ProfileCount - 1];
            return true;
        }
    }
    LogInfo("Không thể lấy hoặc tạo profile cho: " + symbol, true);
    return false;
}

//+------------------------------------------------------------------+
//| Lấy loại tài sản của symbol                                      |
//+------------------------------------------------------------------+
ENUM_ASSET_CLASS CAssetProfileManager::GetAssetClass(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile và trả về loại tài sản
    AssetProfileData profile;
    if (GetAssetProfile(symbol, profile)) {
        return profile.assetClass;
    }
    
    // Mặc định là Forex nếu không tìm thấy
    return ASSET_CLASS_FOREX;
}

//+------------------------------------------------------------------+
//| Lấy nhóm symbol                                                  |
//+------------------------------------------------------------------+
ENUM_SYMBOL_GROUP CAssetProfileManager::GetSymbolGroup(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile và trả về nhóm symbol
    AssetProfileData profile;
    if (GetAssetProfile(symbol, profile)) {
        return profile.symbolGroup;
    }
    
    // Mặc định là Undefined nếu không tìm thấy
    return GROUP_UNDEFINED;
}

//+------------------------------------------------------------------+
//| Lấy SL tối ưu (điểm) cho symbol                                  |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetOptimalSLPoints(string symbol) {
    if (symbol == "") symbol = m_CurrentSymbol;
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    double atr = profile.averageATR;
    double atrPoints = profile.averageATRPoints;
    if (atr <= 0) {
        switch (profile.assetClass) {
            case ASSET_CLASS_FOREX:    return 50.0;
            case ASSET_CLASS_METALS:   return 200.0;
            case ASSET_CLASS_INDICES:  return 100.0;
            case ASSET_CLASS_CRYPTO:   return 500.0;
            default:             return 100.0;
        }
    }
    double slPoints = atrPoints * profile.optimalSLATRMulti;
    return slPoints;
}

//+------------------------------------------------------------------+
//| Lấy TP tối ưu (điểm) cho symbol                                  |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetOptimalTPPoints(string symbol, double targetSLPoints = 0) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    
    // Nếu không cung cấp SL, tính toán SL
    if (targetSLPoints <= 0) {
        targetSLPoints = GetOptimalSLPoints(symbol);
    }
    
    // TP = SL * R:R tối ưu
    double tpPoints = targetSLPoints * profile.optimalRRRatio;
    
    return tpPoints;
}

//+------------------------------------------------------------------+
//| Lấy Trailing Stop tối ưu (điểm) cho symbol                       |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetOptimalTrailingPoints(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    
    // Trailing = ATR * hệ số trailing tối ưu
    double atrPoints = profile.averageATRPoints;
    
    // Nếu không có ATR, sử dụng giá trị mặc định
    if (atrPoints <= 0) {
        // 30 điểm cho Forex, 150 điểm cho Kim loại, 80 điểm cho chỉ số, 400 điểm cho Crypto
        switch (profile.assetClass) {
            case ASSET_CLASS_FOREX:    return 30.0;
            case ASSET_CLASS_METALS:   return 150.0;
            case ASSET_CLASS_INDICES:  return 80.0;
            case ASSET_CLASS_CRYPTO:   return 400.0;
            default:             return 80.0;
        }
    }
    
    double trailingPoints = atrPoints * profile.optimalTRAtrMulti;
    
    return trailingPoints;
}

//+------------------------------------------------------------------+
//| Lấy ngưỡng spread chấp nhận được (điểm) cho symbol              |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetAcceptableSpreadPoints(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    
    // Trả về ngưỡng spread chấp nhận được
    return profile.acceptableSpread;
}

//+------------------------------------------------------------------+
//| Lấy % risk được khuyến nghị cho symbol                           |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetRecommendedRiskPercent(string symbol, double baseRisk) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return baseRisk;
    
    // Nếu baseRisk > 0, điều chỉnh dựa trên tỷ lệ so với risk mặc định
    if (baseRisk > 0) {
        return baseRisk * (profile.recommendedRiskPercent / GetDefaultRiskPercent(profile.assetClass));
    } else {
        return profile.recommendedRiskPercent;
    }
}

//+------------------------------------------------------------------+
//| Lấy phiên giao dịch tối ưu cho symbol                            |
//+------------------------------------------------------------------+
int CAssetProfileManager::GetOptimalTradingSession(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) {
        // Mặc định là London + NY
        return 6; // 2 + 4
    }
    
    return profile.bestTradingSession;
}

//+------------------------------------------------------------------+
//| Lấy ATR trung bình cho symbol                                    |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetAverageATR(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    
    return profile.averageATR;
}

//+------------------------------------------------------------------+
//| Lấy ATR trung bình (điểm) cho symbol                             |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetAverageATRPoints(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy profile
    AssetProfileData profile;
    if (!GetAssetProfile(symbol, profile)) return 0;
    
    return profile.averageATRPoints;
}

//+------------------------------------------------------------------+
//| Lấy ATR hiện tại cho symbol                                      |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetCurrentATR(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "" || symbol == m_CurrentSymbol) {
        // Cập nhật ATR hiện tại nếu quá lâu rồi không cập nhật
        datetime currentTime = TimeCurrent();
        if (currentTime - m_LastATRUpdate > 300) { // 5 phút
            m_CurrentATR = CalculateAverageATR(m_CurrentSymbol, m_MainTimeframe, m_ATRPeriod, 1);
            m_LastATRUpdate = currentTime;
        }
        
        return m_CurrentATR;
    } else {
        // Tính ATR cho symbol khác
        return CalculateAverageATR(symbol, m_MainTimeframe, m_ATRPeriod, 1);
    }
}

//+------------------------------------------------------------------+
//| Lấy spread hiện tại (điểm) cho symbol                           |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetCurrentSpreadPoints(string symbol) {
    // Sử dụng symbol hiện tại nếu không được chỉ định
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy và trả về spread hiện tại
    double spread = SymbolInfoInteger(symbol, SYMBOL_SPREAD) * SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Cập nhật giá trị spread lần cuối nếu là symbol hiện tại
    if (symbol == m_CurrentSymbol) {
        m_LastSpread = spread;
        m_LastSpreadUpdate = TimeCurrent();
    }
    
    return spread;
}

//+------------------------------------------------------------------+
//| Chuyển đổi giá trị sang điểm cho symbol                          |
//+------------------------------------------------------------------+
double CAssetProfileManager::NormalizeToPoints(string symbol, double value) {
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy point size
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    if (point <= 0) return value; // Phòng tránh chia cho 0
    
    // Chuyển đổi giá trị sang điểm
    return value / point;
}

//+------------------------------------------------------------------+
//| Chuyển đổi điểm sang giá trị cho symbol                          |
//+------------------------------------------------------------------+
double CAssetProfileManager::NormalizeToPrice(string symbol, double points) {
    if (symbol == "") symbol = m_CurrentSymbol;
    
    // Lấy point size
    double point = SymbolInfoDouble(symbol, SYMBOL_POINT);
    
    // Chuyển đổi điểm sang giá trị
    return points * point;
}

//+------------------------------------------------------------------+
//| Lưu tất cả các profile                                           |
//+------------------------------------------------------------------+
bool CAssetProfileManager::SaveAllProfiles() {
    if (!m_SaveProfiles) return true;
    
    bool success = true;
    
    // Lưu profile hiện tại
    if (!SaveAssetProfile(m_CurrentAssetProfile)) {
        LogInfo("Không thể lưu profile cho " + m_CurrentSymbol, true);
        success = false;
    }
    
    // Lưu các profile khác
    for (int i = 0; i < m_ProfileCount; i++) {
        // Bỏ qua profile hiện tại vì đã lưu ở trên
        if (m_AssetProfiles[i].symbol == m_CurrentSymbol) continue;
        
        if (!SaveAssetProfile(m_AssetProfiles[i])) {
            LogInfo("Không thể lưu profile cho " + m_AssetProfiles[i].symbol, true);
            success = false;
        }
    }
    
    return success;
}

//+------------------------------------------------------------------+
//| Tải tất cả các profile                                           |
//+------------------------------------------------------------------+
bool CAssetProfileManager::LoadAllProfiles() {
    if (!m_SaveProfiles) return true;
    
    // Tải profile cho symbol hiện tại
    AssetProfileData currentProfile;
    if (LoadAssetProfile(m_CurrentSymbol, currentProfile)) {
        // Lưu vào cache
        m_CurrentAssetProfile = currentProfile;
        
        // Thêm vào danh sách profile nếu chưa có
        if (GetProfileIndex(m_CurrentSymbol) < 0 && m_ProfileCount < MAX_ASSETS_PROFILE) {
            m_AssetProfiles[m_ProfileCount] = currentProfile;
            m_ProfileCount++;
        }
        
        LogInfo("Đã tải profile cho " + m_CurrentSymbol);
    } else {
        LogInfo("Không tìm thấy profile cho " + m_CurrentSymbol + ", sẽ tạo mới");
    }
    
    // TODO: Tải các profile khác nếu cần
    
    return true;
}

//+------------------------------------------------------------------+
//| Lưu profile cho một symbol                                        |
//+------------------------------------------------------------------+
bool CAssetProfileManager::SaveAssetProfile(const AssetProfileData &profile) {
    if (!m_SaveProfiles) return true;
    
    // Lấy tên file
    string filename = GetProfileFilename(profile.symbol);
    
    // Mở file để ghi
    int fileHandle = FileOpen(filename, FILE_WRITE|FILE_BIN|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogInfo("Không thể mở file để lưu profile: " + filename + ", Error: " + IntegerToString(GetLastError()), true);
        return false;
    }
    
    // Ghi dữ liệu
    // Phiên bản file format
    uint fileVersion = 1;
    FileWriteInteger(fileHandle, fileVersion);
    
    // Thông tin cơ bản
    FileWriteString(fileHandle, profile.symbol);
    FileWriteInteger(fileHandle, profile.assetClass);
    FileWriteInteger(fileHandle, profile.symbolGroup);
    FileWriteInteger(fileHandle, profile.volatilityLevel);
    
    // Các thông số thống kê
    FileWriteDouble(fileHandle, profile.averageATR);
    FileWriteDouble(fileHandle, profile.averageATRPoints);
    FileWriteDouble(fileHandle, profile.yearlyVolatility);
    FileWriteDouble(fileHandle, profile.minSpread);
    FileWriteDouble(fileHandle, profile.maxSpread);
    FileWriteDouble(fileHandle, profile.averageSpread);
    FileWriteDouble(fileHandle, profile.acceptableSpread);
    FileWriteDouble(fileHandle, profile.swingMagnitude);
    FileWriteDouble(fileHandle, profile.dailyRange);
    
    // Thông số tối ưu
    FileWriteDouble(fileHandle, profile.optimalSLATRMulti);
    FileWriteDouble(fileHandle, profile.optimalTRAtrMulti);
    FileWriteDouble(fileHandle, profile.optimalRRRatio);
    FileWriteDouble(fileHandle, profile.recommendedRiskPercent);
    
    // Thông tin session
    FileWriteInteger(fileHandle, profile.bestTradingSession);
    FileWriteInteger(fileHandle, profile.worstTradingSession);
    
    // Thông tin hiệu suất
    FileWriteInteger(fileHandle, profile.totalTrades);
    FileWriteDouble(fileHandle, profile.winRate);
    FileWriteDouble(fileHandle, profile.profitFactor);
    FileWriteDouble(fileHandle, profile.expectancy);
    
    // Lịch sử dữ liệu
    FileWriteInteger(fileHandle, profile.historyCount);
    
    for (int i = 0; i < profile.historyCount; i++) {
        FileWriteDouble(fileHandle, profile.atrHistory[i]);
        FileWriteDouble(fileHandle, profile.spreadHistory[i]);
        FileWriteLong(fileHandle, profile.historyDates[i]);
    }
    
    // Thời gian cập nhật cuối
    FileWriteLong(fileHandle, profile.lastUpdated);
    
    // Đóng file
    FileClose(fileHandle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Tải profile cho một symbol                                       |
//+------------------------------------------------------------------+
bool CAssetProfileManager::LoadAssetProfile(string symbol, AssetProfileData &profile) {
    if (!m_SaveProfiles) return false;
    
    // Lấy tên file
    string filename = GetProfileFilename(symbol);
    
    // Kiểm tra file tồn tại
    if (!FileIsExist(filename, FILE_COMMON)) {
        return false;
    }
    
    // Mở file để đọc
    int fileHandle = FileOpen(filename, FILE_READ|FILE_BIN|FILE_COMMON);
    if (fileHandle == INVALID_HANDLE) {
        LogInfo("Không thể mở file để đọc profile: " + filename + ", Error: " + IntegerToString(GetLastError()), true);
        return false;
    }
    
    // Khởi tạo profile mới
    profile.Initialize();
    
    // Đọc dữ liệu
    // Phiên bản file format
    uint fileVersion = FileReadInteger(fileHandle);
    
    // Thông tin cơ bản
    profile.symbol = FileReadString(fileHandle);
    profile.assetClass = (ENUM_ASSET_CLASS)FileReadInteger(fileHandle);
    profile.symbolGroup = (ENUM_SYMBOL_GROUP)FileReadInteger(fileHandle);
    profile.volatilityLevel = (ENUM_ASSET_VOLATILITY)FileReadInteger(fileHandle);
    
    // Các thông số thống kê
    profile.averageATR = FileReadDouble(fileHandle);
    profile.averageATRPoints = FileReadDouble(fileHandle);
    profile.yearlyVolatility = FileReadDouble(fileHandle);
    profile.minSpread = FileReadDouble(fileHandle);
    profile.maxSpread = FileReadDouble(fileHandle);
    profile.averageSpread = FileReadDouble(fileHandle);
    profile.acceptableSpread = FileReadDouble(fileHandle);
    profile.swingMagnitude = FileReadDouble(fileHandle);
    profile.dailyRange = FileReadDouble(fileHandle);
    
    // Thông số tối ưu
    profile.optimalSLATRMulti = FileReadDouble(fileHandle);
    profile.optimalTRAtrMulti = FileReadDouble(fileHandle);
    profile.optimalRRRatio = FileReadDouble(fileHandle);
    profile.recommendedRiskPercent = FileReadDouble(fileHandle);
    
    // Thông tin session
    profile.bestTradingSession = FileReadInteger(fileHandle);
    profile.worstTradingSession = FileReadInteger(fileHandle);
    
    // Thông tin hiệu suất
    profile.totalTrades = FileReadInteger(fileHandle);
    profile.winRate = FileReadDouble(fileHandle);
    profile.profitFactor = FileReadDouble(fileHandle);
    profile.expectancy = FileReadDouble(fileHandle);
    
    // Lịch sử dữ liệu
    profile.historyCount = FileReadInteger(fileHandle);
    
    for (int i = 0; i < profile.historyCount; i++) {
        profile.atrHistory[i] = FileReadDouble(fileHandle);
        profile.spreadHistory[i] = FileReadDouble(fileHandle);
        profile.historyDates[i] = (datetime)FileReadLong(fileHandle);
    }
    
    // Thời gian cập nhật cuối
    profile.lastUpdated = (datetime)FileReadLong(fileHandle);
    
    // Đóng file
    FileClose(fileHandle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Tạo thư mục lưu trữ nếu chưa tồn tại                             |
//+------------------------------------------------------------------+
void CAssetProfileManager::CreateProfileFolderIfNotExists() {
    if (!m_SaveProfiles) return;
    
    string path = m_StorageFolder;
    
    if (!FolderCreate(path, FILE_COMMON)) {
        LogInfo("Không thể tạo thư mục lưu trữ: " + path + ", Error: " + IntegerToString(GetLastError()), true);
    }
}

//+------------------------------------------------------------------+
//| Lấy ATR lịch sử                                                  |
//+------------------------------------------------------------------+
bool CAssetProfileManager::GetHistoricalATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, double &atrArray[]) {
    // Khởi tạo handle cho ATR
    int atrHandle = iATR(symbol, timeframe, period);
    if (atrHandle == INVALID_HANDLE) {
        LogInfo("Không thể tạo handle ATR cho " + symbol, true);
        return false;
    }
    
    // Chuẩn bị mảng
    ArraySetAsSeries(atrArray, true);
    
    // Sao chép dữ liệu
    if (CopyBuffer(atrHandle, 0, 0, 100, atrArray) <= 0) {
        LogInfo("Không thể sao chép dữ liệu ATR cho " + symbol, true);
        IndicatorRelease(atrHandle);
        return false;
    }
    
    // Giải phóng handle
    IndicatorRelease(atrHandle);
    
    return true;
}

//+------------------------------------------------------------------+
//| Tính ATR trung bình                                              |
//+------------------------------------------------------------------+
double CAssetProfileManager::CalculateAverageATR(string symbol, ENUM_TIMEFRAMES timeframe, int period, int bars) {
    // Khởi tạo handle cho ATR
    int atrHandle = iATR(symbol, timeframe, period);
    if (atrHandle == INVALID_HANDLE) {
        LogInfo("Không thể tạo handle ATR cho " + symbol, true);
        return 0;
    }
    
    // Chuẩn bị mảng
    double atrArray[];
    ArraySetAsSeries(atrArray, true);
    
    // Số lượng thanh nến để tính trung bình (tối thiểu 1)
    bars = MathMax(1, bars);
    
    // Sao chép dữ liệu
    if (CopyBuffer(atrHandle, 0, 0, bars + 10, atrArray) <= 0) {
        LogInfo("Không thể sao chép dữ liệu ATR cho " + symbol, true);
        IndicatorRelease(atrHandle);
        return 0;
    }
    
    // Tính trung bình
    double totalATR = 0;
    for (int i = 0; i < bars; i++) {
        totalATR += atrArray[i];
    }
    
    // Giải phóng handle
    IndicatorRelease(atrHandle);
    
    // Trả về ATR trung bình
    return totalATR / bars;
}

//+------------------------------------------------------------------+
//| Tính biến động hàng năm                                          |
//+------------------------------------------------------------------+
double CAssetProfileManager::CalculateYearlyVolatility(string symbol) {
    // Lấy dữ liệu giá đóng cửa hàng ngày
    double closes[];
    ArraySetAsSeries(closes, true);
    
    if (CopyClose(symbol, PERIOD_D1, 0, 252, closes) <= 0) {
        LogInfo("Không thể lấy dữ liệu giá đóng cửa hàng ngày cho " + symbol, true);
        return 0;
    }
    
    // Tính biến động hàng năm (phương pháp đơn giản)
    double sum = 0;
    double sumSquared = 0;
    int count = 0;
    
    // Tính lợi nhuận theo ngày (%)
    for (int i = 1; i < ArraySize(closes); i++) {
        if (closes[i] <= 0) continue;
        
        double dailyReturn = (closes[i-1] - closes[i]) / closes[i] * 100;
        sum += dailyReturn;
        sumSquared += dailyReturn * dailyReturn;
        count++;
    }
    
    if (count < 20) { // Cần ít nhất 20 ngày để tính
        LogInfo("Không đủ dữ liệu để tính biến động hàng năm cho " + symbol);
        return 0;
    }
    
    // Tính độ lệch chuẩn
    double mean = sum / count;
    double variance = sumSquared / count - mean * mean;
    double dailyStdDev = MathSqrt(variance);
    
    // Biến động hàng năm = Độ lệch chuẩn hàng ngày * căn bậc 2 của số ngày giao dịch trong năm
    double annualVolatility = dailyStdDev * MathSqrt(TRADING_DAYS_PER_YEAR);
    
    return annualVolatility;
}

//+------------------------------------------------------------------+
//| Lấy ngưỡng spread mặc định theo loại tài sản                     |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetDefaultAcceptableSpread(ENUM_ASSET_CLASS assetClass) {
    int index = (int)assetClass;
    if (index < 0 || index >= 5) index = 0;
    return m_DefaultSpreadThresholds[index];
}

//+------------------------------------------------------------------+
//| Lấy hệ số ATR mặc định theo loại tài sản                         |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetDefaultATRMultiplier(ENUM_ASSET_CLASS assetClass) {
    int index = (int)assetClass;
    if (index < 0 || index >= 5) index = 0;
    
    return m_DefaultATRMultipliers[index];
}

//+------------------------------------------------------------------+
//| Lấy % risk mặc định theo loại tài sản                            |
//+------------------------------------------------------------------+
double CAssetProfileManager::GetDefaultRiskPercent(ENUM_ASSET_CLASS assetClass) {
    int index = (int)assetClass;
    if (index < 0 || index >= 5) index = 0;
    
    return m_DefaultRiskPercents[index];
}

//+------------------------------------------------------------------+
//| Tìm profile trong danh sách                                      |
//+------------------------------------------------------------------+
int CAssetProfileManager::GetProfileIndex(string symbol) {
    for (int i = 0; i < m_ProfileCount; i++) {
        if (m_AssetProfiles[i].symbol == symbol) {
            return i;
        }
    }
    
    return -1;
}

//+------------------------------------------------------------------+
//| Ghi log                                                          |
//+------------------------------------------------------------------+
void CAssetProfileManager::LogInfo(string message, bool important) {
    if (m_Logger == NULL) {
        Print("AssetProfileManager: " + message);
        return;
    }
    
    if (important) {
        m_Logger.LogInfo("AssetProfileManager: " + message);
    } else {
        m_Logger.LogDebug("AssetProfileManager: " + message);
    }
}

//+------------------------------------------------------------------+
//| Lấy tên file cho profile                                         |
//+------------------------------------------------------------------+
string CAssetProfileManager::GetProfileFilename(string symbol) {
    return m_StorageFolder + "/" + symbol + "_profile.json";
}

//+------------------------------------------------------------------+
//| Kiểm tra sự căn chỉnh của các đường EMA                           |
//+------------------------------------------------------------------+
bool CAssetProfileManager::IsEMAAligned(bool isLong, string symbol) {
    string sym = (symbol == "") ? m_CurrentSymbol : symbol;
    
    int ema34Handle = iMA(sym, m_MainTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
    int ema89Handle = iMA(sym, m_MainTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
    int ema200Handle = iMA(sym, m_MainTimeframe, 200, 0, MODE_EMA, PRICE_CLOSE);
    
    if(ema34Handle != INVALID_HANDLE && ema89Handle != INVALID_HANDLE && ema200Handle != INVALID_HANDLE) {
        double ema34Buffer[], ema89Buffer[], ema200Buffer[];
        ArraySetAsSeries(ema34Buffer, true);
        ArraySetAsSeries(ema89Buffer, true);
        ArraySetAsSeries(ema200Buffer, true);
        
        if(CopyBuffer(ema34Handle, 0, 0, 1, ema34Buffer) == 1 &&
           CopyBuffer(ema89Handle, 0, 0, 1, ema89Buffer) == 1 &&
           CopyBuffer(ema200Handle, 0, 0, 1, ema200Buffer) == 1) {
            
            // Giải phóng handles
            IndicatorRelease(ema34Handle);
            IndicatorRelease(ema89Handle);
            IndicatorRelease(ema200Handle);
            
            if(isLong) {
                // Xu hướng tăng
                return (ema34Buffer[0] > ema89Buffer[0] && ema89Buffer[0] > ema200Buffer[0]);
            } else {
                // Xu hướng giảm
                return (ema34Buffer[0] < ema89Buffer[0] && ema89Buffer[0] < ema200Buffer[0]);
            }
        }
        
        // Giải phóng handles nếu chưa return
        IndicatorRelease(ema34Handle);
        IndicatorRelease(ema89Handle);
        IndicatorRelease(ema200Handle);
    }
    
    // Mặc định trả về false nếu không thể xác định
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra giá nằm ngoài vùng giá trị                                 |
//+------------------------------------------------------------------+
bool CAssetProfileManager::IsPriceOutsideValueArea(double price, bool checkHigh, string symbol) {
    string sym = (symbol == "") ? m_CurrentSymbol : symbol;
    
    // Sử dụng EMA 34 và EMA 89 để xác định vùng giá trị
    int ema34Handle = iMA(sym, m_MainTimeframe, 34, 0, MODE_EMA, PRICE_CLOSE);
    int ema89Handle = iMA(sym, m_MainTimeframe, 89, 0, MODE_EMA, PRICE_CLOSE);
    
    if(ema34Handle != INVALID_HANDLE && ema89Handle != INVALID_HANDLE) {
        double ema34Buffer[], ema89Buffer[];
        ArraySetAsSeries(ema34Buffer, true);
        ArraySetAsSeries(ema89Buffer, true);
        
        if(CopyBuffer(ema34Handle, 0, 0, 1, ema34Buffer) == 1 &&
           CopyBuffer(ema89Handle, 0, 0, 1, ema89Buffer) == 1) {
            
            // Giải phóng handles
            IndicatorRelease(ema34Handle);
            IndicatorRelease(ema89Handle);
            
            // Xác định vùng giá trị
            double valueAreaHigh = MathMax(ema34Buffer[0], ema89Buffer[0]);
            double valueAreaLow = MathMin(ema34Buffer[0], ema89Buffer[0]);
            
            // Thêm một khoảng đệm (buffer) xung quanh vùng giá trị
            double buffer = MathAbs(valueAreaHigh - valueAreaLow) * 0.1; // 10% của khoảng
            valueAreaHigh += buffer;
            valueAreaLow -= buffer;
            
            // Kiểm tra giá so với vùng giá trị
            if(checkHigh) {
                return price > valueAreaHigh; // Giá cao hơn vùng giá trị
            } else {
                return price < valueAreaLow; // Giá thấp hơn vùng giá trị
            }
        }
        
        // Giải phóng handles nếu chưa return
        IndicatorRelease(ema34Handle);
        IndicatorRelease(ema89Handle);
    }
    
    // Mặc định trả về false nếu không thể xác định
    return false;
}

#endif // _ASSET_PROFILE_MANAGER_MQH_

//+------------------------------------------------------------------+
//| End of CAssetProfileManager class                                |
//+------------------------------------------------------------------+