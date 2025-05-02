//+------------------------------------------------------------------+
//| Điều chỉnh quyết định giao dịch theo phiên hiện tại              |
//+------------------------------------------------------------------+
void CTradeDecision::AdjustBySession(ENUM_SESSION session)
{
    if(m_ActiveCluster == CLUSTER_NONE || m_Profile == NULL)
        return;
    
    // Áp dụng logic đặc thù theo phiên cho quyết định giao dịch
    switch(session)
    {
        case SESSION_ASIAN:
            // Phiên Á thường có biên độ hẹp hơn
            // Giảm tín hiệu theo xu hướng trừ khi xu hướng rất mạnh
            if(m_ActiveCluster == CLUSTER_1_TREND//+------------------------------------------------------------------+
//|                          TradeDecision.mqh                       |
//|                  Copyright 2023-2025, ApexTrading Systems        |
//|                           https://www.apextradingsystems.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "12.0"

#pragma once
#include "CommonStructs.mqh"
#include "MarketProfile.mqh"
#include "MarketMonitor.mqh"
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Trade Decision Class                                             |
//| Responsible for making trading decisions based on market profile |
//| and selecting appropriate trading clusters and scenarios         |
//+------------------------------------------------------------------+
class CTradeDecision
{
private:
    // Core components
    CMarketProfile*   m_Profile;              // Pointer to MarketProfile object
    CMarketMonitor*   m_MarketMonitor;        // Pointer to MarketMonitor object
    CLogger*          m_Logger;               // Logger object
    bool              m_IsInitialized;        // Initialization flag
    
    // Current decision state
    ENUM_CLUSTER_TYPE m_ActiveCluster;        // Currently active trading cluster
    ENUM_ENTRY_SCENARIO m_Scenario;           // Current entry scenario
    ENUM_TRADE_SIGNAL m_Signal;               // Buy/Sell/None signal
    
    // Configuration parameters
    int               m_MinADXStrong;         // Minimum ADX for strong trend (default 25)
    int               m_MaxADXSideway;        // Maximum ADX for sideway market (default 20)
    int               m_MinPullbackPct;       // Minimum pullback percentage (default 20%)
    int               m_MaxPullbackPct;       // Maximum pullback percentage (default 60%)
    double            m_MinEmaAlignment;      // Minimum EMA alignment factor (0-1)
    
    // Risk adjustment factors
    double            m_QualityMultiplier;    // Quality multiplier for position sizing
    
    // Session preference factors
    double            m_AsianSessionFactor;   // Weight for Asian session (default 0.7)
    double            m_EuropeanSessionFactor;// Weight for European session (default 1.0)
    double            m_AmericanSessionFactor;// Weight for American session (default 1.0)
    double            m_OverlapSessionFactor; // Weight for session overlaps (default 1.2)
    
    // Decision history tracking
    struct DecisionHistory
    {
        datetime time;                         // Time of decision
        ENUM_CLUSTER_TYPE cluster;             // Selected cluster
        ENUM_ENTRY_SCENARIO scenario;          // Selected scenario
        ENUM_TRADE_SIGNAL signal;              // Trading signal
        double quality;                        // Signal quality (0-1)
        string reason;                         // Reasoning behind decision
    };
    
    DecisionHistory m_LastDecision;           // Last trading decision
    
    // Private methods for decision making
    bool              EvaluateTrendFollowing(bool& isLong, double& quality, double& entryPrice, double& stopLoss);
    bool              EvaluateCounterTrend(bool& isLong, double& quality, double& entryPrice, double& stopLoss);
    bool              EvaluateScalingOpportunity(bool& isLong, double& quality, double& entryPrice, double& stopLoss);
    bool              ValidatePullback(bool isLong, double& depth, double& quality);
    double            CalculateSignalQuality(ENUM_CLUSTER_TYPE cluster, ENUM_ENTRY_SCENARIO scenario);
    void              LogDecision(bool valid, string reason);
    double            GetSessionFactor();
    
public:
                      CTradeDecision();
                     ~CTradeDecision();
    
    // Initialization
    bool              Initialize(CMarketProfile* profile, CMarketMonitor* marketMonitor);
    
    // Configuration methods
    void              SetParameters(int minADXStrong, int maxADXSideway, 
                                  int minPullbackPct, int maxPullbackPct);
    void              SetSessionFactors(double asianFactor, double europeanFactor, 
                                      double americanFactor, double overlapFactor);
    
    // Main decision methods
    bool              EvaluateTradeOpportunity(SignalInfo &signal);
    void              AdjustBySession(ENUM_SESSION session);
    void              AdjustByMarketRegime(ENUM_MARKET_REGIME regime);
    
    // Decision state accessors
    ENUM_CLUSTER_TYPE GetActiveCluster() const { return m_ActiveCluster; }
    ENUM_ENTRY_SCENARIO GetScenario() const { return m_Scenario; }
    ENUM_TRADE_SIGNAL GetSignal() const { return m_Signal; }
    double            GetQualityMultiplier() const { return m_QualityMultiplier; }
    CLogger*          GetLogger() const { return m_Logger; }
    
    // Decision history
    string            GetLastDecisionReason() const { return m_LastDecision.reason; }
    double            GetLastDecisionQuality() const { return m_LastDecision.quality; }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeDecision::CTradeDecision()
{
    // Initialize pointers
    m_Profile = NULL;
    m_MarketMonitor = NULL;
    
    // Initialize decision state
    m_ActiveCluster = CLUSTER_NONE;
    m_Scenario = SCENARIO_NONE;
    m_Signal = TRADE_SIGNAL_NONE;
    m_QualityMultiplier = 1.0;
    
    // Initialize parameters with defaults
    m_MinADXStrong = 25;
    m_MaxADXSideway = 20;
    m_MinPullbackPct = 20;
    m_MaxPullbackPct = 60;
    m_MinEmaAlignment = 0.7;
    
    // Initialize session factors
    m_AsianSessionFactor = 0.7;      // Less aggressive during Asian session
    m_EuropeanSessionFactor = 1.0;   // Normal during European session
    m_AmericanSessionFactor = 1.0;   // Normal during American session
    m_OverlapSessionFactor = 1.2;    // More aggressive during overlaps
    
    // Clear history
    ZeroMemory(m_LastDecision);
    
    // Create logger
    m_Logger = new CLogger("TradeDecision");
    
    m_IsInitialized = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeDecision::~CTradeDecision()
{
    // Clean up
    if(m_Logger != NULL)
    {
        delete m_Logger;
        m_Logger = NULL;
    }
}

//+------------------------------------------------------------------+
//| Initialize with Market Profile                                   |
//+------------------------------------------------------------------+
bool CTradeDecision::Initialize(CMarketProfile* profile, CMarketMonitor* marketMonitor)
{
    // Store pointers
    m_Profile = profile;
    m_MarketMonitor = marketMonitor;
    
    // Validate pointers
    if(m_Profile == NULL)
    {
        if(m_Logger != NULL)
            m_Logger.LogError("Failed to initialize: MarketProfile pointer is NULL");
        return false;
    }
    
    if(m_MarketMonitor == NULL)
    {
        if(m_Logger != NULL)
            m_Logger.LogError("Failed to initialize: MarketMonitor pointer is NULL");
        return false;
    }
    
    // Log successful initialization
    if(m_Logger != NULL)
        m_Logger.LogInfo("TradeDecision module initialized successfully");
    
    m_IsInitialized = true;
    return true;
}

//+------------------------------------------------------------------+
//| Set operational parameters                                       |
//+------------------------------------------------------------------+
void CTradeDecision::SetParameters(int minADXStrong, int maxADXSideway, 
                                  int minPullbackPct, int maxPullbackPct)
{
    // Validate and set parameters
    m_MinADXStrong = MathMax(15, minADXStrong);    // Min 15 for strong trend
    m_MaxADXSideway = MathMin(25, maxADXSideway);  // Max 25 for sideways
    
    // Ensure sideway ADX is less than strong ADX
    if(m_MaxADXSideway >= m_MinADXStrong)
        m_MaxADXSideway = m_MinADXStrong - 5;
    
    // Validate pullback percentages
    m_MinPullbackPct = MathMax(10, MathMin(minPullbackPct, 40));  // Between 10-40%
    m_MaxPullbackPct = MathMax(40, MathMin(maxPullbackPct, 80));  // Between 40-80%
    
    // Ensure min is less than max
    if(m_MinPullbackPct >= m_MaxPullbackPct)
        m_MinPullbackPct = m_MaxPullbackPct - 10;
    
    // Log parameter changes
    if(m_Logger != NULL)
    {
        m_Logger.LogInfo(StringFormat(
            "Parameters set: ADX Strong=%d, ADX Sideway=%d, Pullback Range=%d-%d%%",
            m_MinADXStrong, m_MaxADXSideway, m_MinPullbackPct, m_MaxPullbackPct
        ));
    }
}

//+------------------------------------------------------------------+
//| Set session weighting factors                                    |
//+------------------------------------------------------------------+
void CTradeDecision::SetSessionFactors(double asianFactor, double europeanFactor, 
                                     double americanFactor, double overlapFactor)
{
    // Validate and set session factors (keep between 0.5 and 1.5)
    m_AsianSessionFactor = MathMax(0.5, MathMin(1.5, asianFactor));
    m_EuropeanSessionFactor = MathMax(0.5, MathMin(1.5, europeanFactor));
    m_AmericanSessionFactor = MathMax(0.5, MathMin(1.5, americanFactor));
    m_OverlapSessionFactor = MathMax(0.5, MathMin(1.5, overlapFactor));
    
    // Log session factor changes
    if(m_Logger != NULL)
    {
        m_Logger.LogInfo(StringFormat(
            "Session factors set: Asian=%.1f, European=%.1f, American=%.1f, Overlap=%.1f",
            m_AsianSessionFactor, m_EuropeanSessionFactor, 
            m_AmericanSessionFactor, m_OverlapSessionFactor
        ));
    }
}

//+------------------------------------------------------------------+
//| Phương thức chính để đánh giá cơ hội giao dịch                  |
//+------------------------------------------------------------------+
bool CTradeDecision::EvaluateTradeOpportunity(SignalInfo &signal)
{
    // Kiểm tra khởi tạo
    if(!m_IsInitialized || m_Profile == NULL || m_MarketMonitor == NULL)
    {
        LogDecision(false, "Module chưa được khởi tạo đúng cách");
        return false;
    }
    
    // Reset trạng thái quyết định hiện tại
    m_ActiveCluster = CLUSTER_NONE;
    m_Scenario = SCENARIO_NONE;
    m_Signal = TRADE_SIGNAL_NONE;
    m_QualityMultiplier = 1.0;
    
    // Khởi tạo thông tin tín hiệu output
    signal.Reset();
    signal.symbol = m_MarketMonitor.m_Symbol;
    signal.signalTime = TimeCurrent();
    
    // Lấy dữ liệu thị trường từ MarketProfile
    bool isTrending = m_Profile.IsTrending();
    bool isSideway = m_Profile.IsSideway();
    bool isVolatile = m_Profile.IsVolatile();
    double adxH4 = m_Profile.GetADXH4();
    bool hasDivergence = m_Profile.HasDivergence();
    bool hasVolumeSpike = m_Profile.HasVolumeSpike();
    
    // Lấy hệ số phiên hiện tại
    double sessionFactor = GetSessionFactor();
    
    // Các biến để lưu kết quả quyết định
    bool isLong = false;
    double quality = 0.0;
    double entryPrice = 0.0;
    double stopLoss = 0.0;
    
    // Kiểm tra cơ hội scaling trước tiên
    if(m_Profile.IsScalingOpportunity())
    {
        if(EvaluateScalingOpportunity(isLong, quality, entryPrice, stopLoss))
        {
            m_ActiveCluster = CLUSTER_3_SCALING;
            m_Scenario = SCENARIO_DUAL_EMA_SUPPORT; // hoặc một scenario scaling cụ thể
            m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            
            // Điều chỉnh chất lượng theo phiên
            quality *= sessionFactor;
            m_QualityMultiplier = quality;
            
            // Điền thông tin tín hiệu
            signal.isValid = true;
            signal.isLong = isLong;
            signal.scenario = m_Scenario;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLoss;
            signal.quality = quality;
            signal.description = "Cơ hội scaling với xu hướng mạnh tiếp diễn";
            
            // Ghi log quyết định
            LogDecision(true, "Phát hiện cơ hội scaling với chất lượng " + DoubleToString(quality, 2));
            
            return true;
        }
    }
    
    // Đánh giá chiến lược theo xu hướng nếu thị trường đang có xu hướng
    if(isTrending && adxH4 > m_MinADXStrong)
    {
        if(EvaluateTrendFollowing(isLong, quality, entryPrice, stopLoss))
        {
            m_ActiveCluster = CLUSTER_1_TREND_FOLLOWING;
            
            // Xác định scenario cụ thể dựa trên điều kiện
            if(m_Profile.HasPullbackNearEMA())
            {
                m_Scenario = isLong ? SCENARIO_BULLISH_PULLBACK : SCENARIO_BEARISH_PULLBACK;
            }
            else if(hasVolumeSpike)
            {
                m_Scenario = SCENARIO_MOMENTUM_SHIFT;
            }
            else
            {
                m_Scenario = SCENARIO_STRONG_PULLBACK;
            }
            
            m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            
            // Điều chỉnh chất lượng theo phiên
            quality *= sessionFactor;
            m_QualityMultiplier = quality;
            
            // Điền thông tin tín hiệu
            signal.isValid = true;
            signal.isLong = isLong;
            signal.scenario = m_Scenario;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLoss;
            signal.quality = quality;
            signal.description = isLong ? "Xu hướng tăng tiếp diễn" : "Xu hướng giảm tiếp diễn";
            
            // Ghi log quyết định
            LogDecision(true, "Phát hiện cơ hội theo xu hướng với chất lượng " + DoubleToString(quality, 2));
            
            return true;
        }
    }
    
    // Đánh giá chiến lược ngược xu hướng nếu thị trường sideway hoặc có phân kỳ
    if((isSideway && adxH4 < m_MaxADXSideway) || hasDivergence)
    {
        if(EvaluateCounterTrend(isLong, quality, entryPrice, stopLoss))
        {
            m_ActiveCluster = CLUSTER_2_COUNTERTREND;
            
            // Xác định scenario cụ thể dựa trên điều kiện
            if(hasDivergence)
            {
                m_Scenario = SCENARIO_REVERSAL_CONFIRMATION;
            }
            else if(hasVolumeSpike)
            {
                m_Scenario = SCENARIO_LIQUIDITY_GRAB;
            }
            else
            {
                m_Scenario = SCENARIO_BREAKOUT_FAILURE;
            }
            
            m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            
            // Ngược xu hướng thường rủi ro hơn, nên giảm nhẹ chất lượng
            quality *= 0.9 * sessionFactor;
            m_QualityMultiplier = quality;
            
            // Điền thông tin tín hiệu
            signal.isValid = true;
            signal.isLong = isLong;
            signal.scenario = m_Scenario;
            signal.entryPrice = entryPrice;
            signal.stopLoss = stopLoss;
            signal.quality = quality;
            signal.description = isLong ? "Đảo chiều tăng/ngược xu hướng" : "Đảo chiều giảm/ngược xu hướng";
            
            // Ghi log quyết định
            LogDecision(true, "Phát hiện cơ hội ngược xu hướng với chất lượng " + DoubleToString(quality, 2));
            
            return true;
        }
    }
    
    // Không tìm thấy cơ hội giao dịch hợp lệ
    if(isVolatile && adxH4 >= m_MaxADXSideway && adxH4 <= m_MinADXStrong)
    {
        // Thị trường biến động với hướng không rõ ràng - tránh giao dịch
        LogDecision(false, "Thị trường biến động với hướng không rõ ràng (ADX trong vùng xám: " + DoubleToString(adxH4, 1) + ")");
    }
    else if(adxH4 < 15)
    {
        // ADX rất thấp - thị trường thiếu xu hướng rõ ràng
        LogDecision(false, "Thị trường thiếu chuyển động định hướng (ADX quá thấp: " + DoubleToString(adxH4, 1) + ")");
    }
    else
    {
        // Trường hợp chung - không tìm thấy setup giao dịch
        LogDecision(false, "Không tìm thấy setup giao dịch phù hợp với tiêu chí");
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Điều chỉnh quyết định giao dịch theo phiên hiện tại              |
//+------------------------------------------------------------------+
void CTradeDecision::AdjustBySession(ENUM_SESSION session)
{
    if(m_ActiveCluster == CLUSTER_NONE || m_Profile == NULL)
        return;
    
    // Áp dụng logic đặc thù theo phiên cho quyết định giao dịch
    switch(session)
    {
        case SESSION_ASIAN:
            // Phiên Á thường có biên độ hẹp hơn
            // Giảm tín hiệu theo xu hướng trừ khi xu hướng rất mạnh
            if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING && !m_Profile.IsStrongTrend())
            {
                double adx = m_Profile.GetADXH4();
                
                // Nếu ADX không thuyết phục trong phiên Á, tốt hơn là tránh giao dịch theo xu hướng
                if(adx < m_MinADXStrong + 5)
                {
                    m_ActiveCluster = CLUSTER_NONE;
                    m_Scenario = SCENARIO_NONE;
                    m_Signal = TRADE_SIGNAL_NONE;
                    LogDecision(false, "Tín hiệu xu hướng trong phiên Á không đủ mạnh (ADX: " + DoubleToString(adx, 1) + ")");
                }
                // Ngược lại, giảm chất lượng/kích thước
                else
                {
                    m_QualityMultiplier *= m_AsianSessionFactor;
                    LogDecision(true, "Điều chỉnh chất lượng tín hiệu xu hướng cho phiên Á (hệ số: " + DoubleToString(m_AsianSessionFactor, 2) + ")");
                }
            }
            // Chiến lược ngược xu hướng có thể hoạt động tốt hơn trong phiên Á
            else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
            {
                // Tăng nhẹ chất lượng countertrend trong phiên Á
                m_QualityMultiplier *= (1.0 + ((1.0 / m_AsianSessionFactor) - 1.0) * 0.5);
                LogDecision(true, "Tăng nhẹ chất lượng tín hiệu ngược xu hướng cho phiên Á");
            }
            break;
            
        case SESSION_EUROPEAN:
        case SESSION_AMERICAN:
            // Đây là các phiên giao dịch chính
            // Thiên về theo xu hướng nếu thị trường đang cho thấy chuyển động có định hướng
            if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
            {
                // Hoạt động bình thường, áp dụng hệ số phiên tiêu chuẩn
                m_QualityMultiplier *= (session == SESSION_EUROPEAN) ? 
                                     m_EuropeanSessionFactor : m_AmericanSessionFactor;
            }
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            // Thời gian chồng lấp thường có biến động và khối lượng cao hơn
            // Có thể tăng chất lượng cho tín hiệu mạnh
            m_QualityMultiplier *= m_OverlapSessionFactor;
            LogDecision(true, "Điều chỉnh chất lượng tín hiệu cho phiên chồng lấp (hệ số: " + 
                          DoubleToString(m_OverlapSessionFactor, 2) + ")");
            break;
            
        default:
            // Các phiên khác - sử dụng xử lý mặc định
            break;
    }
} *= m_AsianSessionFactor;
                    LogDecision(true, "Trend signal quality adjusted for Asian session (multiplier: " + DoubleToString(m_AsianSessionFactor, 2) + ")");
                }
            }
            // Counter-trend strategies may work better in Asian session
            else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
            {
                // Slightly boost countertrend quality during Asian session
                m_QualityMultiplier *= (1.0 + ((1.0 / m_AsianSessionFactor) - 1.0) * 0.5);
                LogDecision(true, "Counter-trend signal quality slightly boosted for Asian session");
            }
            break;
            
        case SESSION_EUROPEAN:
        case SESSION_AMERICAN:
            // These are primary trading sessions
            // Bias towards trend following if market is showing directional movement
            if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
            {
                // Normal operation, apply the standard session factor
                m_QualityMultiplier *= (session == SESSION_EUROPEAN) ? 
                                     m_EuropeanSessionFactor : m_AmericanSessionFactor;
            }
            break;
            
        case SESSION_EUROPEAN_AMERICAN:
            // Overlap periods often have higher volatility and volume
            // Can potentially increase quality for strong signals
            m_QualityMultiplier *= m_OverlapSessionFactor;
            LogDecision(true, "Signal quality adjusted for session overlap (multiplier: " + 
                          DoubleToString(m_OverlapSessionFactor, 2) + ")");
            break;
            
        default:
            // Other sessions - use default handling
            break;
    }
}

//+------------------------------------------------------------------+
//| Adjust trading decision based on market regime                   |
//+------------------------------------------------------------------+
void CTradeDecision::AdjustByMarketRegime(ENUM_MARKET_REGIME regime)
{
    if(m_ActiveCluster == CLUSTER_NONE || m_Profile == NULL)
        return;
    
    // Apply market regime specific adjustments
    switch(regime)
    {
        case REGIME_STRONG_TREND:
            // In strong trend, favor trend following and scale-in
            if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
            {
                // Boost trend following quality in strong trend regime
                m_QualityMultiplier *= 1.2;
                LogDecision(true, "Trend signal boosted in strong trend regime");
            }
            else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
            {
                // Reduce counter-trend quality in strong trend regime
                m_QualityMultiplier *= 0.7;
                LogDecision(true, "Counter-trend signal reduced in strong trend regime");
            }
            break;
            
        case REGIME_WEAK_TREND:
            // Weak trend regime is neutral
            // Use default quality adjustments
            break;
            
        case REGIME_RANGING:
            // In ranging markets, favor counter-trend strategies
            if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
            {
                // Reduce trend following quality in ranging regime
                m_QualityMultiplier *= 0.8;
                LogDecision(true, "Trend signal reduced in ranging regime");
            }
            else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
            {
                // Boost counter-trend quality in ranging regime
                m_QualityMultiplier *= 1.1;
                LogDecision(true, "Counter-trend signal boosted in ranging regime");
            }
            break;
            
        case REGIME_VOLATILE:
            // In volatile markets, reduce position sizing generally
            m_QualityMultiplier *= 0.7;
            LogDecision(true, "Signal quality reduced in volatile regime");
            break;
            
        default:
            // Unknown regime - use default handling
            break;
    }
}

//+------------------------------------------------------------------+
//| Đánh giá cơ hội giao dịch theo xu hướng (trend-following)        |
//+------------------------------------------------------------------+
bool CTradeDecision::EvaluateTrendFollowing(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
{
    // Khởi tạo giá trị output
    isLong = false;
    quality = 0.0;
    entryPrice = 0.0;
    stopLoss = 0.0;
    
    // Kiểm tra hướng xu hướng
    bool isTrendUp = m_Profile.IsTrendUp();
    bool isTrendDown = m_Profile.IsTrendDown();
    
    // Đảm bảo có xu hướng rõ ràng
    if(!isTrendUp && !isTrendDown)
    {
        return false;
    }
    
    // Thiết lập hướng dựa trên xu hướng
    isLong = isTrendUp;
    
    // Kiểm tra cơ hội pullback (rút về)
    double pullbackDepth = 0.0;
    double pullbackQuality = 0.0;
    
    if(!ValidatePullback(isLong, pullbackDepth, pullbackQuality))
    {
        return false;
    }
    
    // Lấy dữ liệu thị trường
    double atr = m_MarketMonitor.GetATR();
    double emaFast = m_MarketMonitor.GetEMAFast();
    double emaTrend = m_MarketMonitor.GetEMATrend();
    
    // Tính điểm chất lượng cơ bản (0-1)
    double adxQuality = MathMin(1.0, m_Profile.GetADXH4() / 40.0);
    double emaAlignmentQuality = isLong ?
                               (emaFast > emaTrend ? 1.0 : 0.5) :
                               (emaFast < emaTrend ? 1.0 : 0.5);
    
    // Kết hợp các yếu tố chất lượng
    quality = (adxQuality * 0.3) + (emaAlignmentQuality * 0.3) + (pullbackQuality * 0.4);
    
    // Đặt giá vào lệnh là giá thị trường hiện tại
    entryPrice = isLong ? 
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_ASK) :
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_BID);
    
    // Tính toán stop loss dựa trên pullback và ATR
    if(isLong)
    {
        // Với lệnh Buy, SL nằm dưới đáy pullback với buffer ATR
        stopLoss = entryPrice - (pullbackDepth * atr) - (atr * 0.3);
    }
    else
    {
        // Với lệnh Sell, SL nằm trên đỉnh pullback với buffer ATR
        stopLoss = entryPrice + (pullbackDepth * atr) + (atr * 0.3);
    }
    
    // Đảm bảo stop loss hợp lệ
    stopLoss = NormalizeDouble(stopLoss, m_MarketMonitor.m_Digits);
    
    // Kiểm tra xem khoảng cách stop có hợp lý không
    double stopDistance = MathAbs(entryPrice - stopLoss);
    if(stopDistance < atr * 0.5 || stopDistance > atr * 3.0)
    {
        // Stop loss quá gần hoặc quá xa, từ chối giao dịch
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Đánh giá cơ hội giao dịch ngược xu hướng (counter-trend)         |
//+------------------------------------------------------------------+
bool CTradeDecision::EvaluateCounterTrend(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
{
    // Khởi tạo giá trị output
    isLong = false;
    quality = 0.0;
    entryPrice = 0.0;
    stopLoss = 0.0;
    
    // Đối với chiến lược counter-trend, chúng ta thường giao dịch ngược hướng giá hiện tại
    // Cần các bằng chứng mạnh như phân kỳ (divergence), quá mua/bán, hoặc hỗ trợ/kháng cự
    
    // Kiểm tra tín hiệu đảo chiều
    bool hasBullishDivergence = m_Profile.HasBullishDivergence();
    bool hasBearishDivergence = m_Profile.HasBearishDivergence();
    bool isOverbought = m_Profile.IsOverbought();
    bool isOversold = m_Profile.IsOversold();
    bool hasKeySupport = m_Profile.HasKeySupport();
    bool hasKeyResistance = m_Profile.HasKeyResistance();
    
    // Xác định hướng giao dịch dựa trên tín hiệu đảo chiều
    if(hasBullishDivergence || isOversold || hasKeySupport)
    {
        isLong = true;
    }
    else if(hasBearishDivergence || isOverbought || hasKeyResistance)
    {
        isLong = false;
    }
    else
    {
        // Không có tín hiệu đảo chiều rõ ràng
        return false;
    }
    
    // Tính toán chất lượng dựa trên độ mạnh của tín hiệu
    double divergenceQuality = isLong ? 
                             (hasBullishDivergence ? 0.7 : 0.0) :
                             (hasBearishDivergence ? 0.7 : 0.0);
    
    double oversoldOverboughtQuality = isLong ?
                                     (isOversold ? 0.5 : 0.0) :
                                     (isOverbought ? 0.5 : 0.0);
    
    double supportResistanceQuality = isLong ?
                                    (hasKeySupport ? 0.6 : 0.0) :
                                    (hasKeyResistance ? 0.6 : 0.0);
    
    // Sử dụng yếu tố chất lượng mạnh nhất và tăng cường nếu có nhiều tín hiệu
    quality = MathMax(MathMax(divergenceQuality, oversoldOverboughtQuality), supportResistanceQuality);
    
    // Thưởng điểm cho nhiều tín hiệu xác nhận cùng lúc
    int signalCount = 0;
    if(isLong)
    {
        if(hasBullishDivergence) signalCount++;
        if(isOversold) signalCount++;
        if(hasKeySupport) signalCount++;
    }
    else
    {
        if(hasBearishDivergence) signalCount++;
        if(isOverbought) signalCount++;
        if(hasKeyResistance) signalCount++;
    }
    
    // Cộng điểm thưởng cho nhiều tín hiệu
    if(signalCount > 1)
    {
        quality += 0.1 * (signalCount - 1);
    }
    
    // Giới hạn chất lượng tối đa là 1.0
    quality = MathMin(quality, 1.0);
    
    // Nếu chất lượng quá thấp, từ chối giao dịch
    if(quality < 0.5)
    {
        return false;
    }
    
    // Lấy dữ liệu thị trường
    double atr = m_MarketMonitor.GetATR();
    
    // Đặt giá vào lệnh là giá thị trường hiện tại
    entryPrice = isLong ? 
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_ASK) :
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_BID);
    
    // Tính toán stop loss dựa trên ATR
    // Giao dịch ngược xu hướng thường cần stop rộng hơn
    if(isLong)
    {
        stopLoss = entryPrice - (atr * 1.5);
    }
    else
    {
        stopLoss = entryPrice + (atr * 1.5);
    }
    
    // Đảm bảo stop loss hợp lệ
    stopLoss = NormalizeDouble(stopLoss, m_MarketMonitor.m_Digits);
    
    return true;
}

//+------------------------------------------------------------------+
//| Đánh giá cơ hội scaling (thêm lệnh vào xu hướng hiện có)         |
//+------------------------------------------------------------------+
bool CTradeDecision::EvaluateScalingOpportunity(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
{
    // Khởi tạo giá trị output
    isLong = false;
    quality = 0.0;
    entryPrice = 0.0;
    stopLoss = 0.0;
    
    // Kiểm tra xem có lệnh đang mở hay không
    // Lưu ý: Trong thực tế, logic này phức tạp hơn và cần tương tác với TradeManager
    bool hasOpenPositions = false;
    bool existingPositionIsLong = false;
    
    // Ví dụ - Kiểm tra nếu có lệnh mở
    int totalPositions = PositionsTotal();
    for(int i = 0; i < totalPositions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(ticket > 0 && PositionSelectByTicket(ticket))
        {
            string posSymbol = PositionGetString(POSITION_SYMBOL);
            long posMagic = PositionGetInteger(POSITION_MAGIC);
            
            // Kiểm tra nếu đây là lệnh của EA này
            if(posSymbol == m_MarketMonitor.m_Symbol) // && posMagic == [EA Magic])
            {
                hasOpenPositions = true;
                existingPositionIsLong = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
                break;
            }
        }
    }
    
    // Nếu không có lệnh đang mở, không thể scaling
    if(!hasOpenPositions)
    {
        return false;
    }
    
    // Lấy hướng lệnh từ vị thế hiện tại
    isLong = existingPositionIsLong;
    
    // Kiểm tra xem xu hướng hiện tại còn mạnh không
    bool isTrendUp = m_Profile.IsTrendUp();
    bool isTrendDown = m_Profile.IsTrendDown();
    double adx = m_Profile.GetADXH4();
    
    // Kiểm tra hướng xu hướng khớp với hướng lệnh hiện tại
    if((isLong && !isTrendUp) || (!isLong && !isTrendDown))
    {
        // Không scale khi xu hướng không còn phù hợp
        return false;
    }
    
    // Kiểm tra ADX - cần xu hướng đủ mạnh để scaling
    if(adx < m_MinADXStrong)
    {
        // ADX quá yếu, không nên scaling
        return false;
    }
    
    // Kiểm tra điều kiện pullback cho điểm vào scaling
    double pullbackDepth = 0.0;
    double pullbackQuality = 0.0;
    
    if(!ValidatePullback(isLong, pullbackDepth, pullbackQuality))
    {
        return false;
    }
    
    // Các điều kiện bổ sung cho scaling
    bool hasPositiveMomentum = m_Profile.HasPositiveMomentum(isLong);
    bool hasEmaSupport = m_Profile.IsPriceNearEma(isLong);
    
    // Tính chất lượng tín hiệu scaling
    quality = 0.5 + (pullbackQuality * 0.2);
    
    // Tăng chất lượng nếu các điều kiện bổ sung được đáp ứng
    if(hasPositiveMomentum) quality += 0.1;
    if(hasEmaSupport) quality += 0.2;
    
    // Tính toán giá vào lệnh và stop loss
    double atr = m_MarketMonitor.GetATR();
    
    entryPrice = isLong ? 
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_ASK) :
               SymbolInfoDouble(m_MarketMonitor.m_Symbol, SYMBOL_BID);
    
    // Stop loss cho lệnh scaling có thể chặt hơn một chút
    if(isLong)
    {
        stopLoss = entryPrice - (atr * 1.2);
    }
    else
    {
        stopLoss = entryPrice + (atr * 1.2);
    }
    
    // Chuẩn hóa stop loss
    stopLoss = NormalizeDouble(stopLoss, m_MarketMonitor.m_Digits);
    
    return (quality >= 0.6); // Chỉ scale khi chất lượng tín hiệu đủ cao
}
    //
    //+------------------------------------------------------------------+
//| Validate pullback conditions for entry                           |
//+------------------------------------------------------------------+
bool CTradeDecision::ValidatePullback(bool isLong, double& depth, double& quality)
{
    // Initialize output values
    depth = 0.0;
    quality = 0.0;
    
    // Get market data 
    double atr = m_MarketMonitor.GetATR();
    if(atr <= 0) {
        m_Logger.LogWarning("Invalid ATR in ValidatePullback");
        return false;
    }
    
    // Get recent price data with appropriate array orientation
    double high[], low[], close[];
    ArraySetAsSeries(high, true);
    ArraySetAsSeries(low, true);
    ArraySetAsSeries(close, true);
    
    if(CopyHigh(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, high) <= 0 ||
       CopyLow(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, low) <= 0 ||
       CopyClose(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, close) <= 0) {
        m_Logger.LogError("Failed to copy price data in ValidatePullback");
        return false;
    }
    
    // Analyze pullback depth and quality
    if(isLong) {
        // For long signals, find pullback depth as a retracement from recent high
        
        // First, find recent swing high
        double swingHigh = high[0];
        int swingHighBar = 0;
        
        for(int i = 1; i < 20; i++) {
            if(high[i] > swingHigh) {
                swingHigh = high[i];
                swingHighBar = i;
            }
        }
        
        // Find lowest low after the swing high
        double lowestLow = low[0];
        int lowestLowBar = 0;
        
        for(int i = 0; i < swingHighBar; i++) {
            if(low[i] < lowestLow) {
                lowestLow = low[i];
                lowestLowBar = i;
            }
        }
        
        // Calculate pullback depth as percentage of the impulse move
        double impulseMove = swingHigh - low[swingHighBar];
        double pullback = swingHigh - lowestLow;
        
        if(impulseMove <= 0) {
            return false; // Invalid impulse move
        }
        
        double pullbackPercent = (pullback / impulseMove) * 100.0;
        
        // Check if pullback percentage is within acceptable range
        if(pullbackPercent < m_MinPullbackPct || pullbackPercent > m_MaxPullbackPct) {
            m_Logger.LogDebug("Pullback percentage outside acceptable range: " + 
                            DoubleToString(pullbackPercent, 1) + "%");
            return false;
        }
        
        // Check if price has started bouncing from the pullback
        if(close[0] <= lowestLow) {
            m_Logger.LogDebug("Price hasn't bounced from pullback yet");
            return false;
        }
        
        // Calculate depth in terms of ATR
        depth = pullback / atr;
        
        // Calculate quality based on pullback characteristics
        double depthQuality = MathMin(1.0, depth / 2.0); // Deeper pullbacks get higher score (up to 1.0)
        double bounceQuality = (close[0] - lowestLow) / pullback; // How much it has bounced back
        
        quality = (depthQuality * 0.7) + (bounceQuality * 0.3);
        
        m_Logger.LogDebug("Long pullback validated: Depth=" + DoubleToString(depth, 2) + 
                       " ATR, Quality=" + DoubleToString(quality, 2));
        return true;
    }
    else {
        // For short signals, find pullback as a retracement from recent low
        
        // First, find recent swing low
        double swingLow = low[0];
        int swingLowBar = 0;
        
        for(int i = 1; i < 20; i++) {
            if(low[i] < swingLow) {
                swingLow = low[i];
                swingLowBar = i;
            }
        }
        
        // Find highest high after the swing low
        double highestHigh = high[0];
        int highestHighBar = 0;
        
        for(int i = 0; i < swingLowBar; i++) {
            if(high[i] > highestHigh) {
                highestHigh = high[i];
                highestHighBar = i;
            }
        }
        
        // Calculate pullback depth as percentage of the impulse move
        double impulseMove = high[swingLowBar] - swingLow;
        double pullback = highestHigh - swingLow;
        
        if(impulseMove <= 0) {
            return false; // Invalid impulse move
        }
        
        double pullbackPercent = (pullback / impulseMove) * 100.0;
        
        // Check if pullback percentage is within acceptable range
        if(pullbackPercent < m_MinPullbackPct || pullbackPercent > m_MaxPullbackPct) {
            m_Logger.LogDebug("Pullback percentage outside acceptable range: " + 
                            DoubleToString(pullbackPercent, 1) + "%");
            return false;
        }
        
        // Check if price has started returning from the pullback
        if(close[0] >= highestHigh) {
            m_Logger.LogDebug("Price hasn't returned from pullback yet");
            return false;
        }
        
        // Calculate depth in terms of ATR
        depth = pullback / atr;
        
        // Calculate quality based on pullback characteristics
        double depthQuality = MathMin(1.0, depth / 2.0); // Deeper pullbacks get higher score (up to 1.0)
        double bounceQuality = (highestHigh - close[0]) / pullback; // How much it has returned
        
        quality = (depthQuality * 0.7) + (bounceQuality * 0.3);
        
        m_Logger.LogDebug("Short pullback validated: Depth=" + DoubleToString(depth, 2) + 
                       " ATR, Quality=" + DoubleToString(quality, 2));
        return true;
    }
}

//+------------------------------------------------------------------+
//| Get current session weighting factor                            |
//+------------------------------------------------------------------+
double CTradeDecision::GetSessionFactor()
{
    if(m_Profile == NULL) {
        return 1.0; // Default if profile not available
    }
    
    ENUM_SESSION currentSession = m_Profile.GetCurrentSession();
    
    switch(currentSession)
    {
        case SESSION_ASIAN:
            return m_AsianSessionFactor;
            
        case SESSION_EUROPEAN:
            return m_EuropeanSessionFactor;
            
        case SESSION_AMERICAN:
            return m_AmericanSessionFactor;
            
        case SESSION_EUROPEAN_AMERICAN:
            return m_OverlapSessionFactor;
            
        default:
            return 1.0; // Default factor for unknown session
    }
}

//+------------------------------------------------------------------+
//| Log decision details                                            |
//+------------------------------------------------------------------+
void CTradeDecision::LogDecision(bool valid, string reason)
{
    // Store decision information for future reference
    m_LastDecision.time = TimeCurrent();
    m_LastDecision.cluster = m_ActiveCluster;
    m_LastDecision.scenario = m_Scenario;
    m_LastDecision.signal = m_Signal;
    m_LastDecision.reason = reason;
    
    // Use appropriate log level based on decision validity
    if(valid) {
        m_Logger.LogInfo("Trade decision [VALID]: " + reason);
    } else {
        m_Logger.LogDebug("Trade decision [INVALID]: " + reason);
    }
}

//+------------------------------------------------------------------+
//| Calculate overall signal quality based on multiple factors       |
//+------------------------------------------------------------------+
double CTradeDecision::CalculateSignalQuality(ENUM_CLUSTER_TYPE cluster, ENUM_ENTRY_SCENARIO scenario)
{
    double baseQuality = 0.5; // Start with neutral quality
    
    // Adjust based on cluster type
    switch(cluster)
    {
        case CLUSTER_1_TREND_FOLLOWING:
            // For trend following, consider trend strength
            if(m_Profile.IsStrongTrend()) {
                baseQuality += 0.2;
            } else if(m_Profile.IsTrending()) {
                baseQuality += 0.1;
            } else {
                baseQuality -= 0.1; // Penalize if trend is weak
            }
            break;
            
        case CLUSTER_2_COUNTERTREND:
            // For countertrend, consider overbought/oversold conditions
            if(m_Profile.IsOverbought() || m_Profile.IsOversold()) {
                baseQuality += 0.15;
            }
            // Consider divergence
            if(m_Profile.HasDivergence()) {
                baseQuality += 0.2;
            }
            break;
            
        case CLUSTER_3_SCALING:
            // For scaling, consider trend continuation signals
            if(m_Profile.IsStrongTrend()) {
                baseQuality += 0.15;
            }
            if(m_Profile.HasVolumeSpike()) {
                baseQuality += 0.1;
            }
            break;
            
        default:
            baseQuality = 0.0; // No valid cluster
            break;
    }
    
    // Further adjust based on specific scenario
    switch(scenario)
    {
        case SCENARIO_STRONG_PULLBACK:
        case SCENARIO_BULLISH_PULLBACK:
        case SCENARIO_BEARISH_PULLBACK:
            if(m_Profile.HasPullbackNearEMA()) {
                baseQuality += 0.1; // Bonus for pullbacks near EMA
            }
            break;
            
        case SCENARIO_FIBONACCI_PULLBACK:
            baseQuality += 0.05; // Slight bonus for Fibonacci levels
            break;
            
        case SCENARIO_REVERSAL_CONFIRMATION:
            if(m_Profile.HasVolumeSpike()) {
                baseQuality += 0.15; // Bonus for volume confirmation
            }
            break;
            
        // Add more scenario-specific quality adjustments as needed
    }
    
    // Apply market volatility adjustment
    if(m_Profile.IsVolatile()) {
        baseQuality *= 0.9; // Reduce quality in highly volatile markets
    }
    
    // Apply session quality factor
    baseQuality *= GetSessionFactor();
    
    // Ensure quality is within valid range [0,1]
    return MathMax(0.0, MathMin(1.0, baseQuality));
}