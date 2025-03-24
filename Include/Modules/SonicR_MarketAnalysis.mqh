//+------------------------------------------------------------------+
//|                                   SonicR_MarketAnalysis.mqh      |
//|                SonicR PropFirm EA - Market Analysis Module       |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Forward declarations cho các phụ thuộc bên ngoài
class CLogger;
class CSonicRCore;

// Các thành phần gốc (được giữ trong file gốc)
#include "../SonicR_Filters.mqh"
#include "../SonicR_PVSRA.mqh"
#include "../SonicR_SimplePVSRA.mqh"

//+------------------------------------------------------------------+
//| Lớp gom nhóm cho phân tích thị trường                            |
//+------------------------------------------------------------------+
class CMarketAnalysis
{
private:
    // Các thành phần chính
    CSessionFilter*       m_sessionFilter;
    CNewsFilter*          m_newsFilter;
    CMarketRegimeFilter*  m_marketRegimeFilter;
    CPVSRA*               m_pvsra;
    CSimplePVSRA*         m_simplePvsra;
    
    // Các phụ thuộc bên ngoài
    CLogger*              m_logger;
    CSonicRCore*          m_core;
    
    // Cấu hình
    bool                  m_useNewsFilter;
    bool                  m_useMarketRegimeFilter;
    bool                  m_usePVSRA;
    int                   m_newsMinutesBefore;
    int                   m_newsMinutesAfter;
    bool                  m_highImpactOnly;
    
    // Cấu hình Session
    bool                  m_enableLondonSession;
    bool                  m_enableNewYorkSession;
    bool                  m_enableLondonNYOverlap;
    bool                  m_enableAsianSession;
    int                   m_fridayEndHour;
    bool                  m_allowMondayTrading;
    bool                  m_allowFridayTrading;
    double                m_sessionQualityThreshold;
    
    // Cấu hình Market Regime
    bool                  m_tradeBullishRegime;
    bool                  m_tradeBearishRegime;
    bool                  m_tradeRangingRegime;
    bool                  m_tradeVolatileRegime;
    
    // Cấu hình PVSRA
    int                   m_volumeAvgPeriod;
    int                   m_spreadAvgPeriod;
    int                   m_confirmationBars;
    double                m_volumeThreshold;
    double                m_spreadThreshold;
    
    // Lưu trữ trạng thái
    datetime              m_lastMarketRegimeCheck;
    bool                  m_tradingAllowed;
    
public:
    // Constructor/Destructor
    CMarketAnalysis();
    ~CMarketAnalysis();
    
    // Khởi tạo và thiết lập
    bool Initialize();
    void SetSessionFilterParams(bool enableLondon, bool enableNY, bool enableOverlap, bool enableAsian,
                               int fridayEndHour, bool allowMonday, bool allowFriday, double qualityThreshold);
    void SetNewsFilterParams(bool useNewsFilter, int minutesBefore, int minutesAfter, bool highImpactOnly);
    void SetMarketRegimeFilterParams(bool useFilter, bool tradeBullish, bool tradeBearish, bool tradeRanging, bool tradeVolatile);
    void SetPVSRAParams(bool usePVSRA, int volumeAvgPeriod, int spreadAvgPeriod, int confirmationBars, double volumeThreshold, double spreadThreshold);
    
    // Thiết lập các phụ thuộc
    void SetLogger(CLogger* logger);
    void SetCore(CSonicRCore* core);
    
    // Phân tích thị trường
    bool IsTradingAllowed();
    bool IsNewsTime();
    bool IsSessionActive();
    bool IsRegimeFavorable();
    bool IsPVSRAConfirming(int direction, string symbol = NULL);
    
    // Thông tin trạng thái
    string GetCurrentSessionName();
    string GetCurrentRegimeAsString();
    double GetSessionQuality();
    bool HasHighImpactNews();
    
    // Phương thức cập nhật
    void Update();
    void UpdateMarketRegime();
    void UpdateNewsFilter();
    
    // Phương thức truy cập
    CSessionFilter* GetSessionFilter() { return m_sessionFilter; }
    CNewsFilter* GetNewsFilter() { return m_newsFilter; }
    CMarketRegimeFilter* GetMarketRegimeFilter() { return m_marketRegimeFilter; }
    CPVSRA* GetPVSRA() { return m_pvsra; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CMarketAnalysis::CMarketAnalysis()
{
    m_sessionFilter = NULL;
    m_newsFilter = NULL;
    m_marketRegimeFilter = NULL;
    m_pvsra = NULL;
    m_simplePvsra = NULL;
    
    m_logger = NULL;
    m_core = NULL;
    
    // Giá trị mặc định
    m_useNewsFilter = true;
    m_useMarketRegimeFilter = true;
    m_usePVSRA = true;
    m_newsMinutesBefore = 30;
    m_newsMinutesAfter = 15;
    m_highImpactOnly = true;
    
    m_enableLondonSession = true;
    m_enableNewYorkSession = true;
    m_enableLondonNYOverlap = true;
    m_enableAsianSession = false;
    m_fridayEndHour = 16;
    m_allowMondayTrading = true;
    m_allowFridayTrading = true;
    m_sessionQualityThreshold = 60.0;
    
    m_tradeBullishRegime = true;
    m_tradeBearishRegime = true;
    m_tradeRangingRegime = true;
    m_tradeVolatileRegime = false;
    
    m_volumeAvgPeriod = 20;
    m_spreadAvgPeriod = 10;
    m_confirmationBars = 3;
    m_volumeThreshold = 1.5;
    m_spreadThreshold = 0.7;
    
    m_lastMarketRegimeCheck = 0;
    m_tradingAllowed = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CMarketAnalysis::~CMarketAnalysis()
{
    // Giải phóng bộ nhớ - chỉ xóa các đối tượng được tạo trong lớp này
    if(m_sessionFilter != NULL) delete m_sessionFilter;
    if(m_newsFilter != NULL) delete m_newsFilter;
    if(m_marketRegimeFilter != NULL) delete m_marketRegimeFilter;
    if(m_pvsra != NULL) delete m_pvsra;
    if(m_simplePvsra != NULL) delete m_simplePvsra;
}

//+------------------------------------------------------------------+
//| Khởi tạo các thành phần phân tích thị trường                     |
//+------------------------------------------------------------------+
bool CMarketAnalysis::Initialize()
{
    // Khởi tạo session filter
    m_sessionFilter = new CSessionFilter(
        m_enableLondonSession, m_enableNewYorkSession,
        m_enableLondonNYOverlap, m_enableAsianSession,
        m_fridayEndHour, m_allowMondayTrading, m_allowFridayTrading
    );
    
    if(m_sessionFilter == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize SessionFilter");
        return false;
    }
    
    m_sessionFilter.SetQualityThreshold(m_sessionQualityThreshold);
    
    // Khởi tạo news filter
    m_newsFilter = new CNewsFilter(m_useNewsFilter, m_newsMinutesBefore, m_newsMinutesAfter, m_highImpactOnly);
    if(m_newsFilter == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize NewsFilter");
        return false;
    }
    
    // Khởi tạo market regime filter
    m_marketRegimeFilter = new CMarketRegimeFilter();
    if(m_marketRegimeFilter == NULL) {
        if(m_logger != NULL) m_logger.Error("Failed to initialize MarketRegimeFilter");
        return false;
    }
    
    m_marketRegimeFilter.Configure(
        m_useMarketRegimeFilter,
        m_tradeBullishRegime, m_tradeBearishRegime,
        m_tradeRangingRegime, m_tradeVolatileRegime
    );
    
    // Khởi tạo PVSRA nếu sử dụng
    if(m_usePVSRA) {
        m_pvsra = new CPVSRA();
        if(m_pvsra == NULL) {
            if(m_logger != NULL) m_logger.Error("Failed to initialize PVSRA system");
            return false;
        }
        
        // Thiết lập tham số cho PVSRA
        m_pvsra.SetParameters(m_volumeAvgPeriod, m_spreadAvgPeriod, m_confirmationBars);
        m_pvsra.SetThresholds(m_volumeThreshold, m_spreadThreshold);
        
        // Khởi tạo PVSRA
        if(!m_pvsra.Initialize()) {
            if(m_logger != NULL) m_logger.Error("Failed to initialize PVSRA indicators");
            return false;
        }
    }
    
    // Khởi tạo Simple PVSRA (phiên bản đơn giản hóa)
    m_simplePvsra = new CSimplePVSRA();
    if(m_simplePvsra == NULL) {
        if(m_logger != NULL) m_logger.Warning("Failed to initialize SimplePVSRA, continuing without it");
        // Không trả về false vì đây không phải là thành phần thiết yếu
    }
    
    if(m_logger != NULL) {
        m_logger.Info("Market Analysis module initialized successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Thiết lập tham số Session Filter                                 |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetSessionFilterParams(bool enableLondon, bool enableNY, bool enableOverlap, bool enableAsian,
                                          int fridayEndHour, bool allowMonday, bool allowFriday, double qualityThreshold)
{
    m_enableLondonSession = enableLondon;
    m_enableNewYorkSession = enableNY;
    m_enableLondonNYOverlap = enableOverlap;
    m_enableAsianSession = enableAsian;
    m_fridayEndHour = fridayEndHour;
    m_allowMondayTrading = allowMonday;
    m_allowFridayTrading = allowFriday;
    m_sessionQualityThreshold = qualityThreshold;
    
    // Cập nhật bộ lọc nếu đã được khởi tạo
    if(m_sessionFilter != NULL) {
        m_sessionFilter.Configure(
            enableLondon, enableNY, 
            enableOverlap, enableAsian,
            fridayEndHour, allowMonday, allowFriday
        );
        m_sessionFilter.SetQualityThreshold(qualityThreshold);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập tham số News Filter                                    |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetNewsFilterParams(bool useNewsFilter, int minutesBefore, int minutesAfter, bool highImpactOnly)
{
    m_useNewsFilter = useNewsFilter;
    m_newsMinutesBefore = minutesBefore;
    m_newsMinutesAfter = minutesAfter;
    m_highImpactOnly = highImpactOnly;
    
    // Cập nhật bộ lọc nếu đã được khởi tạo
    if(m_newsFilter != NULL) {
        m_newsFilter.Configure(useNewsFilter, minutesBefore, minutesAfter, highImpactOnly);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập tham số Market Regime Filter                           |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetMarketRegimeFilterParams(bool useFilter, bool tradeBullish, bool tradeBearish, bool tradeRanging, bool tradeVolatile)
{
    m_useMarketRegimeFilter = useFilter;
    m_tradeBullishRegime = tradeBullish;
    m_tradeBearishRegime = tradeBearish;
    m_tradeRangingRegime = tradeRanging;
    m_tradeVolatileRegime = tradeVolatile;
    
    // Cập nhật bộ lọc nếu đã được khởi tạo
    if(m_marketRegimeFilter != NULL) {
        m_marketRegimeFilter.Configure(
            useFilter,
            tradeBullish, tradeBearish,
            tradeRanging, tradeVolatile
        );
    }
}

//+------------------------------------------------------------------+
//| Thiết lập tham số PVSRA                                          |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetPVSRAParams(bool usePVSRA, int volumeAvgPeriod, int spreadAvgPeriod, int confirmationBars, double volumeThreshold, double spreadThreshold)
{
    m_usePVSRA = usePVSRA;
    m_volumeAvgPeriod = volumeAvgPeriod;
    m_spreadAvgPeriod = spreadAvgPeriod;
    m_confirmationBars = confirmationBars;
    m_volumeThreshold = volumeThreshold;
    m_spreadThreshold = spreadThreshold;
    
    // Cập nhật PVSRA nếu đã được khởi tạo
    if(m_pvsra != NULL) {
        m_pvsra.SetParameters(volumeAvgPeriod, spreadAvgPeriod, confirmationBars);
        m_pvsra.SetThresholds(volumeThreshold, spreadThreshold);
    }
}

//+------------------------------------------------------------------+
//| Thiết lập Logger                                                 |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetLogger(CLogger* logger)
{
    m_logger = logger;
    
    // Chuyển tiếp logger cho các thành phần con
    if(m_sessionFilter != NULL) m_sessionFilter.SetLogger(logger);
    if(m_newsFilter != NULL) m_newsFilter.SetLogger(logger);
    if(m_marketRegimeFilter != NULL) m_marketRegimeFilter.SetLogger(logger);
    if(m_pvsra != NULL) m_pvsra.SetLogger(logger);
    if(m_simplePvsra != NULL) m_simplePvsra.SetLogger(logger);
}

//+------------------------------------------------------------------+
//| Thiết lập Core                                                   |
//+------------------------------------------------------------------+
void CMarketAnalysis::SetCore(CSonicRCore* core)
{
    m_core = core;
    
    // Cập nhật phụ thuộc trong các thành phần con
    if(m_marketRegimeFilter != NULL) {
        // MarketRegimeFilter cần Core để phân tích trend
        UpdateMarketRegime();
    }
}

//+------------------------------------------------------------------+
//| Kiểm tra tổng thể xem có được phép giao dịch không               |
//+------------------------------------------------------------------+
bool CMarketAnalysis::IsTradingAllowed()
{
    // Kiểm tra session filter
    if(m_sessionFilter != NULL && !m_sessionFilter.IsTradingAllowed()) {
        if(m_logger != NULL) m_logger.Debug("Trading not allowed: Outside allowed sessions");
        m_tradingAllowed = false;
        return false;
    }
    
    // Kiểm tra news filter
    if(m_newsFilter != NULL && m_useNewsFilter && m_newsFilter.IsNewsTime()) {
        if(m_logger != NULL) m_logger.Debug("Trading not allowed: High impact news nearby");
        m_tradingAllowed = false;
        return false;
    }
    
    // Kiểm tra market regime filter
    if(m_marketRegimeFilter != NULL && m_useMarketRegimeFilter && !m_marketRegimeFilter.IsRegimeFavorable()) {
        if(m_logger != NULL) m_logger.Debug("Trading not allowed: Unfavorable market regime");
        m_tradingAllowed = false;
        return false;
    }
    
    // Tất cả điều kiện đều được đáp ứng
    m_tradingAllowed = true;
    return true;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem hiện tại có thời gian tin tức không                 |
//+------------------------------------------------------------------+
bool CMarketAnalysis::IsNewsTime()
{
    if(m_newsFilter != NULL && m_useNewsFilter) {
        return m_newsFilter.IsNewsTime();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem phiên hiện tại có đang hoạt động không              |
//+------------------------------------------------------------------+
bool CMarketAnalysis::IsSessionActive()
{
    if(m_sessionFilter != NULL) {
        return m_sessionFilter.IsTradingAllowed();
    }
    
    return true; // Mặc định là cho phép nếu không có bộ lọc
}

//+------------------------------------------------------------------+
//| Kiểm tra xem chế độ thị trường có thuận lợi không                |
//+------------------------------------------------------------------+
bool CMarketAnalysis::IsRegimeFavorable()
{
    if(m_marketRegimeFilter != NULL && m_useMarketRegimeFilter) {
        return m_marketRegimeFilter.IsRegimeFavorable();
    }
    
    return true; // Mặc định là thuận lợi nếu không có bộ lọc
}

//+------------------------------------------------------------------+
//| Kiểm tra PVSRA xác nhận hướng giao dịch                         |
//+------------------------------------------------------------------+
bool CMarketAnalysis::IsPVSRAConfirming(int direction, string symbol = NULL)
{
    if(symbol == NULL) symbol = _Symbol;
    
    if(!m_usePVSRA) return true; // Mặc định nếu không dùng PVSRA
    
    if(m_pvsra != NULL && m_core != NULL) {
        if(symbol == _Symbol) {
            return m_core.IsPVSRAConfirming(direction);
        } else {
            // TODO: Xử lý đa cặp tiền cho PVSRA
            return true;
        }
    }
    
    return true; // Mặc định là xác nhận nếu không sử dụng PVSRA
}

//+------------------------------------------------------------------+
//| Lấy tên phiên hiện tại                                          |
//+------------------------------------------------------------------+
string CMarketAnalysis::GetCurrentSessionName()
{
    if(m_sessionFilter != NULL) {
        return m_sessionFilter.GetCurrentSessionName();
    }
    
    return "Unknown";
}

//+------------------------------------------------------------------+
//| Lấy tên chế độ thị trường hiện tại                              |
//+------------------------------------------------------------------+
string CMarketAnalysis::GetCurrentRegimeAsString()
{
    if(m_marketRegimeFilter != NULL) {
        return m_marketRegimeFilter.GetCurrentRegimeAsString();
    }
    
    return "Unknown";
}

//+------------------------------------------------------------------+
//| Lấy chất lượng phiên giao dịch hiện tại                         |
//+------------------------------------------------------------------+
double CMarketAnalysis::GetSessionQuality()
{
    if(m_sessionFilter != NULL) {
        return m_sessionFilter.GetSessionQuality();
    }
    
    return 0.0;
}

//+------------------------------------------------------------------+
//| Kiểm tra xem có tin tức quan trọng không                         |
//+------------------------------------------------------------------+
bool CMarketAnalysis::HasHighImpactNews()
{
    if(m_newsFilter != NULL && m_useNewsFilter) {
        return m_newsFilter.HasHighImpactNews();
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Cập nhật tất cả các thành phần phân tích                         |
//+------------------------------------------------------------------+
void CMarketAnalysis::Update()
{
    // Cập nhật session filter
    if(m_sessionFilter != NULL) {
        m_sessionFilter.Update();
    }
    
    // Cập nhật news filter
    UpdateNewsFilter();
    
    // Cập nhật market regime định kỳ
    if(TimeCurrent() - m_lastMarketRegimeCheck >= 3600) { // Cập nhật mỗi giờ
        UpdateMarketRegime();
        m_lastMarketRegimeCheck = TimeCurrent();
    }
    
    // Cập nhật PVSRA
    if(m_usePVSRA && m_pvsra != NULL) {
        m_pvsra.Update();
    }
    
    // Kiểm tra điều kiện giao dịch tổng thể
    m_tradingAllowed = IsTradingAllowed();
}

//+------------------------------------------------------------------+
//| Cập nhật phân tích chế độ thị trường                            |
//+------------------------------------------------------------------+
void CMarketAnalysis::UpdateMarketRegime()
{
    if(m_marketRegimeFilter != NULL && m_core != NULL) {
        m_marketRegimeFilter.Update(m_core);
        
        if(m_logger != NULL) {
            m_logger.Info("Market regime updated: " + m_marketRegimeFilter.GetCurrentRegimeAsString());
        }
    }
}

//+------------------------------------------------------------------+
//| Cập nhật bộ lọc tin tức                                          |
//+------------------------------------------------------------------+
void CMarketAnalysis::UpdateNewsFilter()
{
    if(m_newsFilter != NULL && m_useNewsFilter) {
        m_newsFilter.Update();
    }
} 