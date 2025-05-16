//+------------------------------------------------------------------+
//|                          TradeDecision.mqh                       |
//|                  ApexTrading Systems- Dev v13        |
//|                           https://www.apextradingsystems.com     |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023-2025, ApexTrading Systems"
#property link      "https://www.apextradingsystems.com"
#property version   "13.0"

// Sử dụng include guard thay cho #pragma once
#ifndef _TRADE_DECISION_MQH_
#define _TRADE_DECISION_MQH_

// Các thư viện cần thiết
#include "CommonStructs.mqh"
#include "MarketProfile.mqh"
#include "MarketMonitor.mqh"
#include "MarketPhase.mqh"    // Thêm mới trong v13
#include "SwingPointDetector.mqh" // Thêm mới trong v13
#include "Logger.mqh"

//+------------------------------------------------------------------+
//| Class CTradeDecision - Bộ não của EA ApexPullback                |
//+------------------------------------------------------------------+
class CTradeDecision
{
private:
    // Các thành viên dữ liệu cơ bản
    CMarketProfile*       m_Profile;
    CMarketMonitor*       m_MarketMonitor;
    CMarketPhase*         m_PhaseAnalyzer;    // Mới v13
    CSwingPointDetector*  m_SwingDetector;    // Mới v13
    CLogger*              m_Logger;
    
    // Các tham số cho đánh giá pullback
    double      m_MinPullbackPct;
    double      m_MaxPullbackPct;
    
    // Các tham số thích ứng theo thị trường
    double      m_AsianSessionFactor;         // Hệ số điều chỉnh cho phiên Á
    double      m_EuropeanSessionFactor;      // Hệ số điều chỉnh cho phiên Âu
    double      m_AmericanSessionFactor;      // Hệ số điều chỉnh cho phiên Mỹ
    double      m_OverlapSessionFactor;       // Hệ số điều chỉnh cho phiên chồng lấp
    
    // Các ngưỡng và hệ số
    double      m_MinADXWeak;                 // ADX tối thiểu cho xu hướng yếu
    double      m_MinADXModerate;             // ADX tối thiểu cho xu hướng trung bình
    double      m_MinADXStrong;               // ADX tối thiểu cho xu hướng mạnh
    
    // Biến để theo dõi quyết định hiện tại
    ENUM_CLUSTER_TYPE m_ActiveCluster;
    ENUM_ENTRY_SCENARIO m_Scenario;
    ENUM_TRADE_SIGNAL m_Signal;
    double      m_QualityMultiplier;          // Hệ số nhân cho chất lượng tín hiệu
    
    // Thông tin về quyết định gần nhất
    struct DecisionInfo
    {
        datetime time;
        ENUM_CLUSTER_TYPE cluster;
        ENUM_ENTRY_SCENARIO scenario;
        ENUM_TRADE_SIGNAL signal;
        string reason;
    } m_LastDecision;
    
    // Trạng thái xử lý mềm mại khi chuyển tiếp (Soft Transition) - Mới v13
    double      m_TransitionScore;            // Điểm số chuyển tiếp (0-1)
    int         m_RegimeConfirmations;        // Số lần xác nhận chế độ thị trường liên tiếp
    
    // Cờ bảo vệ trong điều kiện thị trường extreme - Mới v13
    bool        m_HighRiskDetected;           // Phát hiện rủi ro cao
    bool        m_EnforceStrictFiltering;     // Bật bộ lọc nghiêm ngặt
    
public:
    // Constructor
    CTradeDecision()
    {
        m_Profile = NULL;
        m_MarketMonitor = NULL;
        m_PhaseAnalyzer = NULL;
        m_SwingDetector = NULL;
        m_Logger = NULL;
        
        m_MinPullbackPct = 20.0;
        m_MaxPullbackPct = 70.0;
        
        // Các hệ số phiên mặc định
        m_AsianSessionFactor = 0.8;
        m_EuropeanSessionFactor = 1.0;
        m_AmericanSessionFactor = 1.0;
        m_OverlapSessionFactor = 1.2;
        
        // Các ngưỡng mặc định
        m_MinADXWeak = 15.0;
        m_MinADXModerate = 20.0;
        m_MinADXStrong = 25.0;
        
        // Khởi tạo các trạng thái
        m_ActiveCluster = CLUSTER_NONE;
        m_Scenario = SCENARIO_NONE;
        m_Signal = TRADE_SIGNAL_NONE;
        m_QualityMultiplier = 1.0;
        
        // Khởi tạo các tham số chuyển tiếp mềm
        m_TransitionScore = 0.0;
        m_RegimeConfirmations = 0;
        
        // Khởi tạo cờ bảo vệ
        m_HighRiskDetected = false;
        m_EnforceStrictFiltering = false;
    }
    
    // Destructor
    ~CTradeDecision()
    {
        // Không delete các đối tượng được truyền vào
        m_Profile = NULL;
        m_MarketMonitor = NULL;
        m_PhaseAnalyzer = NULL;
        m_SwingDetector = NULL;
        m_Logger = NULL;
    }
    
    // Khởi tạo với các tham số cơ bản
    bool Initialize(CMarketProfile* profile, double minPullbackPct, double maxPullbackPct)
    {
        if(profile == NULL)
            return false;
            
        m_Profile = profile;
        m_MinPullbackPct = minPullbackPct;
        m_MaxPullbackPct = maxPullbackPct;
        
        return true;
    }
    
    // Thiết lập các đối tượng phụ thuộc - Mới v13
    void SetDependencies(CMarketMonitor* monitor, CMarketPhase* phaseAnalyzer, 
                        CSwingPointDetector* swingDetector, CLogger* logger)
    {
        m_MarketMonitor = monitor;
        m_PhaseAnalyzer = phaseAnalyzer;
        m_SwingDetector = swingDetector;
        m_Logger = logger;
    }
    
    // Thiết lập các tham số thích ứng theo phiên
    void SetSessionFactors(double asianFactor, double europeanFactor, 
                         double americanFactor, double overlapFactor)
    {
        m_AsianSessionFactor = asianFactor;
        m_EuropeanSessionFactor = europeanFactor;
        m_AmericanSessionFactor = americanFactor;
        m_OverlapSessionFactor = overlapFactor;
    }
    
    // Thiết lập các ngưỡng ADX
    void SetADXThresholds(double weakThreshold, double moderateThreshold, double strongThreshold)
    {
        m_MinADXWeak = weakThreshold;
        m_MinADXModerate = moderateThreshold;
        m_MinADXStrong = strongThreshold;
    }
    
    // Thiết lập cờ bảo vệ trong điều kiện thị trường rủi ro cao - Mới v13
    void SetRiskProtection(bool enableStrictFiltering)
    {
        m_EnforceStrictFiltering = enableStrictFiltering;
    }
    
    // Lấy quyết định giao dịch tốt nhất theo kịch bản và tình huống thị trường
    bool GetBestScenario(ENUM_CLUSTER_TYPE preferredCluster, MarketProfile &currentProfile, ENUM_ENTRY_SCENARIO &scenario)
    {
        // Đặt lại các giá trị ban đầu
        m_ActiveCluster = preferredCluster;
        m_Scenario = SCENARIO_NONE;
        m_Signal = TRADE_SIGNAL_NONE;
        m_QualityMultiplier = 1.0;
        
        // Cập nhật thông tin chuyển tiếp từ profile thị trường - Mới v13
        if(currentProfile.isTransitioning)
        {
            m_TransitionScore = 0.7; // Giá trị cao = chuyển tiếp mạnh
            m_RegimeConfirmations = 0;
        }
        else
        {
            m_TransitionScore = Math.max(0, m_TransitionScore - 0.2); // Giảm dần điểm chuyển tiếp
            m_RegimeConfirmations++;
        }
        
        // Kiểm tra các điều kiện chống sập - Mới v13
        m_HighRiskDetected = false;
        if(currentProfile.atrRatio > 2.0 || (currentProfile.isVolatile && currentProfile.isTransitioning))
        {
            m_HighRiskDetected = true;
            m_QualityMultiplier *= 0.5; // Giảm 50% chất lượng khi rủi ro cao
            
            if(m_Logger != NULL)
            {
                m_Logger.LogWarning("Phát hiện rủi ro cao: ATR Ratio = " + 
                                  DoubleToString(currentProfile.atrRatio, 2) + 
                                  ", Chuyển tiếp = " + (currentProfile.isTransitioning ? "Yes" : "No"));
            }
            
            // Nếu bật chế độ lọc nghiêm ngặt và rủi ro cực cao, từ chối tín hiệu
            if(m_EnforceStrictFiltering && currentProfile.atrRatio > 2.5)
            {
                LogDecision(false, "Từ chối tín hiệu do rủi ro quá cao (ATR Ratio > 2.5)");
                return false;
            }
        }
        
        // Xác định kịch bản giao dịch dựa trên cluster được chọn
        switch(m_ActiveCluster)
        {
            case CLUSTER_1_TREND_FOLLOWING:
                DetermineTrendFollowingScenario(currentProfile);
                break;
                
            case CLUSTER_2_COUNTERTREND:
                DetermineCounterTrendScenario(currentProfile);
                break;
                
            case CLUSTER_3_SCALING:
                DetermineScalingScenario(currentProfile);
                break;
                
            default:
                // Không xác định được cluster phù hợp
                LogDecision(false, "Không xác định được cluster phù hợp, bỏ qua tín hiệu");
                return false;
        }
        
        // Điều chỉnh theo phiên và chế độ thị trường
        if(m_Scenario != SCENARIO_NONE)
        {
            // Áp dụng điều chỉnh theo phiên
            AdjustBySession(currentProfile.currentSession);
            
            // Xác định chế độ thị trường
            ENUM_MARKET_REGIME regime = DetermineMarketRegime(currentProfile);
            
            // Áp dụng điều chỉnh theo chế độ thị trường
            AdjustByMarketRegime(regime);
            
            // Mới v13: Điều chỉnh theo pha thị trường nếu PhaseAnalyzer có sẵn
            if(m_PhaseAnalyzer != NULL)
            {
                ENUM_MARKET_PHASE currentPhase = m_PhaseAnalyzer.GetCurrentPhase();
                AdjustByMarketPhase(currentPhase);
            }
        }
        
        // Trả về kết quả
        scenario = m_Scenario;
        return (m_Scenario != SCENARIO_NONE);
    }
    
    // Xác định kịch bản giao dịch theo xu hướng - Mới v13
    void DetermineTrendFollowingScenario(MarketProfile &profile)
    {
        // Kiểm tra điều kiện cơ bản
        if(!profile.isTrending)
        {
            LogDecision(false, "Thị trường không trong xu hướng rõ ràng cho cluster Trend Following");
            return;
        }
        
        // Kiểm tra Swing Points nếu có SwingDetector - Mới v13
        bool hasValidSwing = false;
        if(m_SwingDetector != NULL)
        {
            hasValidSwing = m_SwingDetector.HasRecentSwing();
        }
        
        // Phát hiện kịch bản pullback
        if(profile.adxH4 >= m_MinADXStrong && profile.adxSlope > 0 && profile.volumeSpike)
        {
            m_Scenario = SCENARIO_STRONG_PULLBACK;
            m_Signal = profile.emaSlope > 0 ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            LogDecision(true, "Phát hiện Strong Pullback với ADX=" + DoubleToString(profile.adxH4, 1) + 
                         ", ADX Slope=" + DoubleToString(profile.adxSlope, 2));
        }
        else if(profile.adxH4 >= m_MinADXModerate && hasValidSwing)
        {
            // Phân biệt giữa bullish và bearish pullback dựa trên EMA slope
            if(profile.emaSlope > 0)
            {
                m_Scenario = SCENARIO_BULLISH_PULLBACK;
                m_Signal = TRADE_SIGNAL_BUY;
            }
            else
            {
                m_Scenario = SCENARIO_BEARISH_PULLBACK;
                m_Signal = TRADE_SIGNAL_SELL;
            }
            
            LogDecision(true, "Phát hiện " + (profile.emaSlope > 0 ? "Bullish" : "Bearish") + 
                         " Pullback với ADX=" + DoubleToString(profile.adxH4, 1));
        }
        else if(m_MarketMonitor != NULL && m_MarketMonitor.IsNearFibonacciLevel())
        {
            m_Scenario = SCENARIO_FIBONACCI_PULLBACK;
            m_Signal = profile.emaSlope > 0 ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            LogDecision(true, "Phát hiện Fibonacci Pullback");
        }
        else
        {
            // Không tìm thấy kịch bản rõ ràng
            LogDecision(false, "Không xác định được kịch bản Trend Following phù hợp");
        }
    }
    
    // Xác định kịch bản giao dịch ngược xu hướng - Mới v13
    void DetermineCounterTrendScenario(MarketProfile &profile)
    {
        // Kiểm tra các điều kiện phụ cho tín hiệu Counter-trend
        bool hasOversoldCondition = profile.IsOversold();
        bool hasOverboughtCondition = profile.IsOverbought();
        bool hasDivergence = profile.HasDivergence();
        bool hasKeyLevel = false;
        
        // Kiểm tra mức hỗ trợ/kháng cự key level nếu SwingDetector có sẵn
        if(m_SwingDetector != NULL)
        {
            hasKeyLevel = m_SwingDetector.IsNearKeyLevel();
        }
        
        // Mức độ sideway của thị trường (phù hợp với counter-trend)
        bool isStrongSideway = profile.adxH4 < m_MinADXWeak && profile.isRangebound;
        
        // Kiểm tra phiên - counter-trend thường hiệu quả hơn trong phiên Á
        bool isAsianSession = (profile.currentSession == SESSION_ASIAN);
        
        // Chế độ nghiêm ngặt khi thị trường chuyển tiếp
        bool strictMode = m_TransitionScore > 0.5 || m_HighRiskDetected;
        
        // Xác định kịch bản counter-trend
        if(hasDivergence)
        {
            m_Scenario = SCENARIO_DIVERGENCE_REVERSAL;
            m_Signal = hasOversoldCondition ? TRADE_SIGNAL_BUY : 
                      (hasOverboughtCondition ? TRADE_SIGNAL_SELL : TRADE_SIGNAL_NONE);
            
            LogDecision(true, "Phát hiện Divergence Reversal" + 
                       (hasOversoldCondition ? " Oversold" : (hasOverboughtCondition ? " Overbought" : "")));
        }
        else if(hasKeyLevel && (hasOversoldCondition || hasOverboughtCondition))
        {
            m_Scenario = SCENARIO_KEY_LEVEL_REVERSAL;
            m_Signal = hasOversoldCondition ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            
            LogDecision(true, "Phát hiện Key Level Reversal tại " + 
                       (hasOversoldCondition ? "Support" : "Resistance"));
        }
        else if(isStrongSideway && (hasOversoldCondition || hasOverboughtCondition))
        {
            // Nếu trong chế độ nghiêm ngặt, yêu cầu điều kiện phiên Á để tăng cường lọc
            if(strictMode && !isAsianSession)
            {
                LogDecision(false, "Bỏ qua tín hiệu Range Reversal vì không phải phiên Á trong chế độ nghiêm ngặt");
                return;
            }
            
            m_Scenario = SCENARIO_RANGEBOUND_REVERSAL;
            m_Signal = hasOversoldCondition ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
            
            LogDecision(true, "Phát hiện Range Reversal trong thị trường sideway" + 
                       (isAsianSession ? " (Phiên Á)" : ""));
        }
        else
        {
            // Không đủ điều kiện cho counter-trend trong phiên Á
            if(isAsianSession && (hasOversoldCondition || hasOverboughtCondition))
            {
                m_Scenario = SCENARIO_LIQUIDITY_GRAB;
                m_Signal = hasOversoldCondition ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
                
                LogDecision(true, "Phát hiện Liquidity Grab trong phiên Á");
            }
            else
            {
                // Không tìm thấy kịch bản rõ ràng
                LogDecision(false, "Không xác định được kịch bản Counter-trend phù hợp");
            }
        }
    }
    
    // Xác định kịch bản scaling - Mới v13
    void DetermineScalingScenario(MarketProfile &profile)
    {
        // Scaling cần điều kiện xu hướng mạnh
        if(!profile.isTrending || profile.adxH4 < m_MinADXStrong)
        {
            LogDecision(false, "Từ chối Scaling do thị trường không đủ mạnh (ADX = " + 
                      DoubleToString(profile.adxH4, 1) + ")");
            return;
        }
        
        // Kiểm tra phiên, scaling tốt nhất trong phiên EU-US Overlap
        bool isOptimalSession = (profile.currentSession == SESSION_EUROPEAN_AMERICAN || 
                              profile.currentSession == SESSION_AMERICAN);
        
        // Scaling nên tránh trong thời gian chuyển tiếp
        if(profile.isTransitioning)
        {
            LogDecision(false, "Từ chối Scaling do thị trường đang trong giai đoạn chuyển tiếp");
            return;
        }
        
        // Kiểm tra pha thị trường nếu có PhaseAnalyzer
        bool isImpulsePhase = false;
        if(m_PhaseAnalyzer != NULL)
        {
            ENUM_MARKET_PHASE currentPhase = m_PhaseAnalyzer.GetCurrentPhase();
            isImpulsePhase = (currentPhase == PHASE_IMPULSE);
            
            // Không scale trong pha exhaustion
            if(currentPhase == PHASE_EXHAUSTION)
            {
                LogDecision(false, "Từ chối Scaling do thị trường đang trong pha Exhaustion");
                return;
            }
        }
        
        // Phát hiện pullback nhẹ cho scaling
        double pullbackDepth = 0.0;
        double pullbackQuality = 0.0;
        bool isLong = (profile.emaSlope > 0); // Dùng EMA slope để xác định hướng
        
        if(ValidatePullback(isLong, pullbackDepth, pullbackQuality) && pullbackQuality >= 0.6)
        {
            // Đủ điều kiện cho scaling
            if(isImpulsePhase)
            {
                m_Scenario = SCENARIO_MOMENTUM_CONTINUATION;
                m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
                
                LogDecision(true, "Phát hiện Momentum Continuation trong pha Impulse cho Scaling");
            }
            else if(profile.volumeSpike)
            {
                m_Scenario = SCENARIO_BREAKOUT_CONTINUATION;
                m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
                
                LogDecision(true, "Phát hiện Breakout Continuation với Volume Spike cho Scaling");
            }
            else if(isOptimalSession)
            {
                m_Scenario = SCENARIO_MOMENTUM_SHIFT;
                m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
                
                LogDecision(true, "Phát hiện Momentum Shift trong phiên " + 
                           (profile.currentSession == SESSION_EUROPEAN_AMERICAN ? "EU-US Overlap" : "US"));
            }
            else
            {
                // Kịch bản scaling mặc định
                m_Scenario = SCENARIO_PULLBACK_ENTRY;
                m_Signal = isLong ? TRADE_SIGNAL_BUY : TRADE_SIGNAL_SELL;
                
                LogDecision(true, "Phát hiện Pullback Entry cơ bản cho Scaling");
            }
        }
        else
        {
            // Không xác định được pullback phù hợp cho scaling
            LogDecision(false, "Không xác định được pullback chất lượng cho Scaling");
        }
    }
    
    // Xác định chế độ thị trường từ profile
    ENUM_MARKET_REGIME DetermineMarketRegime(MarketProfile &profile)
    {
        if(profile.adxH4 >= 30 && profile.adxSlope > 0 && MathAbs(profile.emaSlope) > 0.001)
        {
            return REGIME_STRONG_TREND;
        }
        else if(profile.adxH4 >= 20 && profile.adxH4 < 30)
        {
            return REGIME_WEAK_TREND;
        }
        else if(profile.isRangebound || (profile.adxH4 < 20 && MathAbs(profile.emaSlope) < 0.0005))
        {
            return REGIME_RANGING;
        }
        else if(profile.isVolatile || profile.atrRatio > 1.5)
        {
            return REGIME_VOLATILE;
        }
        
        // Mặc định
        return REGIME_NORMAL;
    }
    
    // Lấy hệ số chất lượng hiện tại
    double GetCurrentQualityMultiplier()
    {
        return m_QualityMultiplier;
    }
    
    // Lấy thông tin quyết định cuối cùng
    void GetLastDecision(datetime &time, ENUM_CLUSTER_TYPE &cluster, 
                       ENUM_ENTRY_SCENARIO &scenario, ENUM_TRADE_SIGNAL &signal, string &reason)
    {
        time = m_LastDecision.time;
        cluster = m_LastDecision.cluster;
        scenario = m_LastDecision.scenario;
        signal = m_LastDecision.signal;
        reason = m_LastDecision.reason;
    }
    
    // THỰC HIỆN ĐIỀU CHỈNH THEO PHIÊN, CHẾ ĐỘ THỊ TRƯỜNG VÀ PHA THỊ TRƯỜNG
    
    //+------------------------------------------------------------------+
    //| Điều chỉnh quyết định giao dịch theo phiên hiện tại              |
    //+------------------------------------------------------------------+
    void AdjustBySession(ENUM_SESSION session)
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
    }
    
    //+------------------------------------------------------------------+
    //| Điều chỉnh quyết định dựa trên chế độ thị trường                 |
    //+------------------------------------------------------------------+
    void AdjustByMarketRegime(ENUM_MARKET_REGIME regime)
    {
        if(m_ActiveCluster == CLUSTER_NONE || m_Profile == NULL)
            return;
        
        // Áp dụng các điều chỉnh đặc biệt theo chế độ thị trường
        switch(regime)
        {
            case REGIME_STRONG_TREND:
                // Trong xu hướng mạnh, ưu tiên xu hướng và scaling
                if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
                {
                    // Tăng chất lượng xu hướng trong chế độ xu hướng mạnh
                    m_QualityMultiplier *= 1.2;
                    LogDecision(true, "Tăng chất lượng tín hiệu trong chế độ xu hướng mạnh");
                }
                else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
                {
                    // Giảm chất lượng ngược xu hướng trong chế độ xu hướng mạnh
                    m_QualityMultiplier *= 0.7;
                    LogDecision(true, "Giảm chất lượng tín hiệu ngược xu hướng trong chế độ xu hướng mạnh");
                }
                break;
                
            case REGIME_WEAK_TREND:
                // Chế độ xu hướng yếu là trung lập
                // Sử dụng điều chỉnh chất lượng mặc định
                break;
                
            case REGIME_RANGING:
                // Trong thị trường dao động, ưu tiên chiến lược ngược xu hướng
                if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
                {
                    // Giảm chất lượng xu hướng trong chế độ dao động
                    m_QualityMultiplier *= 0.8;
                    LogDecision(true, "Giảm chất lượng tín hiệu xu hướng trong chế độ dao động");
                }
                else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
                {
                    // Tăng chất lượng ngược xu hướng trong chế độ dao động
                    m_QualityMultiplier *= 1.1;
                    LogDecision(true, "Tăng chất lượng tín hiệu ngược xu hướng trong chế độ dao động");
                }
                break;
                
            case REGIME_VOLATILE:
                // Trong thị trường biến động, giảm kích thước vị thế nói chung
                m_QualityMultiplier *= 0.7;
                LogDecision(true, "Giảm chất lượng tín hiệu trong chế độ biến động cao");
                break;
                
            default:
                // Chế độ không xác định - sử dụng xử lý mặc định
                break;
        }
        
        // Mới v13: Áp dụng điều chỉnh bổ sung nếu thị trường đang trong giai đoạn chuyển tiếp
        if(m_TransitionScore > 0.3)
        {
            // Áp dụng hệ số giảm dần theo mức độ chuyển tiếp
            double transitionAdjustment = 1.0 - (m_TransitionScore * 0.3);
            m_QualityMultiplier *= transitionAdjustment;
            
            LogDecision(true, "Điều chỉnh bổ sung do thị trường đang chuyển tiếp (hệ số: " + 
                      DoubleToString(transitionAdjustment, 2) + ")");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Điều chỉnh quyết định dựa trên pha thị trường - Mới v13         |
    //+------------------------------------------------------------------+
    void AdjustByMarketPhase(ENUM_MARKET_PHASE phase)
    {
        if(m_ActiveCluster == CLUSTER_NONE)
            return;
            
        switch(phase)
        {
            case PHASE_ACCUMULATION:
                // Pha tích lũy: Tăng counter-trend, giảm trend-following
                if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
                {
                    m_QualityMultiplier *= 1.15;
                    LogDecision(true, "Tăng chất lượng counter-trend trong pha Accumulation");
                }
                else if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
                {
                    m_QualityMultiplier *= 0.8;
                    LogDecision(true, "Giảm chất lượng trend-following trong pha Accumulation");
                }
                break;
                
            case PHASE_IMPULSE:
                // Pha xung lực: Tăng trend-following và scaling
                if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING || m_ActiveCluster == CLUSTER_3_SCALING)
                {
                    m_QualityMultiplier *= 1.2;
                    LogDecision(true, "Tăng chất lượng trend-following/scaling trong pha Impulse");
                }
                else if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
                {
                    m_QualityMultiplier *= 0.6;
                    LogDecision(true, "Giảm mạnh chất lượng counter-trend trong pha Impulse");
                }
                break;
                
            case PHASE_CORRECTION:
                // Pha điều chỉnh: Cơ hội tốt cho counter-trend
                if(m_ActiveCluster == CLUSTER_2_COUNTERTREND)
                {
                    m_QualityMultiplier *= 1.1;
                    LogDecision(true, "Tăng chất lượng counter-trend trong pha Correction");
                }
                break;
                
            case PHASE_DISTRIBUTION:
                // Pha phân phối: Cẩn trọng với trend-following
                if(m_ActiveCluster == CLUSTER_1_TREND_FOLLOWING)
                {
                    m_QualityMultiplier *= 0.85;
                    LogDecision(true, "Giảm chất lượng trend-following trong pha Distribution");
                }
                break;
                
            case PHASE_EXHAUSTION:
                // Pha kiệt sức: Tránh scaling, cẩn trọng với tất cả
                if(m_ActiveCluster == CLUSTER_3_SCALING)
                {
                    m_QualityMultiplier *= 0.5;
                    LogDecision(true, "Giảm mạnh chất lượng scaling trong pha Exhaustion");
                }
                else
                {
                    m_QualityMultiplier *= 0.9;
                    LogDecision(true, "Giảm nhẹ chất lượng tín hiệu trong pha Exhaustion");
                }
                break;
                
            default:
                // Pha không xác định
                break;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Đánh giá cơ hội giao dịch theo xu hướng (trend-following)        |
    //+------------------------------------------------------------------+
    bool EvaluateTrendFollowing(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
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
    bool EvaluateCounterTrend(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
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
        
        // Mới v13: Sử dụng SwingDetector nếu có để xác định swing points
        if(m_SwingDetector != NULL)
        {
            // Cải thiện xác định hỗ trợ/kháng cự bằng SwingPoints từ v13
            if(!hasKeySupport) hasKeySupport = m_SwingDetector.IsNearSupportLevel();
            if(!hasKeyResistance) hasKeyResistance = m_SwingDetector.IsNearResistanceLevel();
        }
        
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
    bool EvaluateScalingOpportunity(bool& isLong, double& quality, double& entryPrice, double& stopLoss)
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
        
        // Mới v13: Điều chỉnh giảm trong giai đoạn chuyển tiếp
        if(m_TransitionScore > 0.3)
        {
            quality *= (1.0 - (m_TransitionScore * 0.4)); // Giảm tối đa 40%
        }
        
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
    
    //+------------------------------------------------------------------+
    //| Xác thực điều kiện pullback để vào lệnh                          |
    //+------------------------------------------------------------------+
    bool ValidatePullback(bool isLong, double& depth, double& quality)
    {
        // Khởi tạo giá trị output
        depth = 0.0;
        quality = 0.0;
        
        // Lấy dữ liệu thị trường 
        double atr = m_MarketMonitor.GetATR();
        if(atr <= 0) {
            if(m_Logger != NULL) {
                m_Logger.LogWarning("ATR không hợp lệ trong ValidatePullback");
            }
            return false;
        }
        
        // Lấy dữ liệu giá gần đây với hướng mảng phù hợp
        double high[], low[], close[];
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(close, true);
        
        if(CopyHigh(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, high) <= 0 ||
           CopyLow(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, low) <= 0 ||
           CopyClose(m_MarketMonitor.m_Symbol, PERIOD_CURRENT, 0, 50, close) <= 0) {
            if(m_Logger != NULL) {
                m_Logger.LogError("Không thể sao chép dữ liệu giá trong ValidatePullback");
            }
            return false;
        }
        
        // Phân tích độ sâu và chất lượng pullback
        if(isLong) {
            // Đối với tín hiệu mua, tìm độ sâu pullback như một sự điều chỉnh từ đỉnh gần đây
            
            // Đầu tiên, tìm đỉnh gần đây
            double swingHigh = high[0];
            int swingHighBar = 0;
            
            for(int i = 1; i < 20; i++) {
                if(high[i] > swingHigh) {
                    swingHigh = high[i];
                    swingHighBar = i;
                }
            }
            
            // Tìm đáy thấp nhất sau đỉnh
            double lowestLow = low[0];
            int lowestLowBar = 0;
            
            for(int i = 0; i < swingHighBar; i++) {
                if(low[i] < lowestLow) {
                    lowestLow = low[i];
                    lowestLowBar = i;
                }
            }
            
            // Tính toán độ sâu pullback như một phần trăm của chuyển động xung lực
            double impulseMove = swingHigh - low[swingHighBar];
            double pullback = swingHigh - lowestLow;
            
            if(impulseMove <= 0) {
                return false; // Chuyển động xung lực không hợp lệ
            }
            
            double pullbackPercent = (pullback / impulseMove) * 100.0;
            
            // Kiểm tra nếu phần trăm pullback nằm trong phạm vi chấp nhận được
            if(pullbackPercent < m_MinPullbackPct || pullbackPercent > m_MaxPullbackPct) {
                if(m_Logger != NULL && pullbackPercent > 0) {
                    m_Logger.LogDebug("Phần trăm pullback nằm ngoài phạm vi chấp nhận được: " + 
                                   DoubleToString(pullbackPercent, 1) + "%");
                }
                return false;
            }
            
            // Kiểm tra nếu giá đã bắt đầu phục hồi từ pullback
            if(close[0] <= lowestLow) {
                if(m_Logger != NULL) {
                    m_Logger.LogDebug("Giá chưa phục hồi từ pullback");
                }
                return false;
            }
            
            // Tính toán độ sâu theo ATR
            depth = pullback / atr;
            
            // Tính toán chất lượng dựa trên đặc điểm pullback
            double depthQuality = MathMin(1.0, depth / 2.0); // Pullback sâu hơn có điểm cao hơn (tối đa là 1.0)
            double bounceQuality = (close[0] - lowestLow) / pullback; // Mức độ phục hồi
            
            quality = (depthQuality * 0.7) + (bounceQuality * 0.3);
            
            if(m_Logger != NULL) {
                m_Logger.LogDebug("Pullback mua đã xác thực: Depth=" + DoubleToString(depth, 2) + 
                               " ATR, Quality=" + DoubleToString(quality, 2));
            }
            return true;
        }
        else {
            // Đối với tín hiệu bán, tìm pullback như một sự điều chỉnh từ đáy gần đây
            
            // Đầu tiên, tìm đáy gần đây
            double swingLow = low[0];
            int swingLowBar = 0;
            
            for(int i = 1; i < 20; i++) {
                if(low[i] < swingLow) {
                    swingLow = low[i];
                    swingLowBar = i;
                }
            }
            
            // Tìm đỉnh cao nhất sau đáy
            double highestHigh = high[0];
            int highestHighBar = 0;
            
            for(int i = 0; i < swingLowBar; i++) {
                if(high[i] > highestHigh) {
                    highestHigh = high[i];
                    highestHighBar = i;
                }
            }
            
            // Tính toán độ sâu pullback như một phần trăm của chuyển động xung lực
            double impulseMove = high[swingLowBar] - swingLow;
            double pullback = highestHigh - swingLow;
            
            if(impulseMove <= 0) {
                return false; // Chuyển động xung lực không hợp lệ
            }
            
            double pullbackPercent = (pullback / impulseMove) * 100.0;
            
            // Kiểm tra nếu phần trăm pullback nằm trong phạm vi chấp nhận được
            if(pullbackPercent < m_MinPullbackPct || pullbackPercent > m_MaxPullbackPct) {
                if(m_Logger != NULL && pullbackPercent > 0) {
                    m_Logger.LogDebug("Phần trăm pullback nằm ngoài phạm vi chấp nhận được: " + 
                                   DoubleToString(pullbackPercent, 1) + "%");
                }
                return false;
            }
            
            // Kiểm tra nếu giá đã bắt đầu quay trở lại từ pullback
            if(close[0] >= highestHigh) {
                if(m_Logger != NULL) {
                    m_Logger.LogDebug("Giá chưa quay trở lại từ pullback");
                }
                return false;
            }
            
            // Tính toán độ sâu theo ATR
            depth = pullback / atr;
            
            // Tính toán chất lượng dựa trên đặc điểm pullback
            double depthQuality = MathMin(1.0, depth / 2.0); // Pullback sâu hơn có điểm cao hơn (tối đa là 1.0)
            double bounceQuality = (highestHigh - close[0]) / pullback; // Mức độ quay trở lại
            
            quality = (depthQuality * 0.7) + (bounceQuality * 0.3);
            
            if(m_Logger != NULL) {
                m_Logger.LogDebug("Pullback bán đã xác thực: Depth=" + DoubleToString(depth, 2) + 
                               " ATR, Quality=" + DoubleToString(quality, 2));
            }
            return true;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Lấy hệ số phiên hiện tại                                         |
    //+------------------------------------------------------------------+
    double GetSessionFactor()
    {
        if(m_Profile == NULL) {
            return 1.0; // Mặc định nếu không có profile
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
                return 1.0; // Hệ số mặc định cho phiên không xác định
        }
    }
    
    //+------------------------------------------------------------------+
    //| Log thông tin quyết định                                         |
    //+------------------------------------------------------------------+
    void LogDecision(bool valid, string reason)
    {
        // Lưu trữ thông tin quyết định để tham khảo sau này
        m_LastDecision.time = TimeCurrent();
        m_LastDecision.cluster = m_ActiveCluster;
        m_LastDecision.scenario = m_Scenario;
        m_LastDecision.signal = m_Signal;
        m_LastDecision.reason = reason;
        
        // Sử dụng cấp độ log phù hợp dựa trên tính hợp lệ của quyết định
        if(m_Logger != NULL) {
            if(valid) {
                m_Logger.LogInfo("Quyết định giao dịch [HỢP LỆ]: " + reason);
            } else {
                m_Logger.LogDebug("Quyết định giao dịch [KHÔNG HỢP LỆ]: " + reason);
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Tính toán chất lượng tín hiệu tổng thể dựa trên nhiều yếu tố     |
    //+------------------------------------------------------------------+
    double CalculateSignalQuality(ENUM_CLUSTER_TYPE cluster, ENUM_ENTRY_SCENARIO scenario)
    {
        double baseQuality = 0.5; // Bắt đầu với chất lượng trung lập
        
        // Điều chỉnh dựa trên loại cluster
        switch(cluster)
        {
            case CLUSTER_1_TREND_FOLLOWING:
                // Đối với theo xu hướng, xem xét độ mạnh của xu hướng
                if(m_Profile.IsStrongTrend()) {
                    baseQuality += 0.2;
                } else if(m_Profile.IsTrending()) {
                    baseQuality += 0.1;
                } else {
                    baseQuality -= 0.1; // Phạt nếu xu hướng yếu
                }
                break;
                
            case CLUSTER_2_COUNTERTREND:
                // Đối với ngược xu hướng, xem xét điều kiện oversold/overbought
                if(m_Profile.IsOverbought() || m_Profile.IsOversold()) {
                    baseQuality += 0.15;
                }
                // Xem xét phân kỳ
                if(m_Profile.HasDivergence()) {
                    baseQuality += 0.2;
                }
                break;
                
            case CLUSTER_3_SCALING:
                // Đối với scaling, xem xét tín hiệu tiếp tục xu hướng
                if(m_Profile.IsStrongTrend()) {
                    baseQuality += 0.15;
                }
                if(m_Profile.HasVolumeSpike()) {
                    baseQuality += 0.1;
                }
                break;
                
            default:
                baseQuality = 0.0; // Không có cluster hợp lệ
                break;
        }
        
        // Điều chỉnh thêm dựa trên kịch bản cụ thể
        switch(scenario)
        {
            case SCENARIO_STRONG_PULLBACK:
            case SCENARIO_BULLISH_PULLBACK:
            case SCENARIO_BEARISH_PULLBACK:
                if(m_Profile.HasPullbackNearEMA()) {
                    baseQuality += 0.1; // Thưởng cho pullback gần EMA
                }
                break;
                
            case SCENARIO_FIBONACCI_PULLBACK:
                baseQuality += 0.05; // Thưởng nhẹ cho mức Fibonacci
                break;
                
            case SCENARIO_REVERSAL_CONFIRMATION:
                if(m_Profile.HasVolumeSpike()) {
                    baseQuality += 0.15; // Thưởng cho xác nhận volume
                }
                break;
                
            // Thêm điều chỉnh chất lượng theo kịch bản cụ thể nếu cần
        }
        
        // Áp dụng điều chỉnh biến động thị trường
        if(m_Profile.IsVolatile()) {
            baseQuality *= 0.9; // Giảm chất lượng trong thị trường biến động cao
        }
        
        // Áp dụng hệ số chất lượng phiên
        baseQuality *= GetSessionFactor();
        
        // Đảm bảo chất lượng nằm trong phạm vi hợp lệ [0,1]
        return MathMax(0.0, MathMin(1.0, baseQuality));
    }
    
    // ----------------------- MỚI v13: Thêm các phương thức hỗ trợ cải tiến -----------------------
    
    //+------------------------------------------------------------------+
    //| Đánh giá mức độ rủi ro thị trường - Mới v13                     |
    //+------------------------------------------------------------------+
    double CalculateMarketRiskLevel()
    {
        double riskLevel = 0.0;
        
        if(m_Profile == NULL)
            return 50.0; // Mức rủi ro mặc định
        
        // 1. Rủi ro biến động (0-40%)
        double volatilityRisk = 0;
        if(m_Profile.atrRatio > 2.0)
            volatilityRisk = 40.0;
        else if(m_Profile.atrRatio > 1.5)
            volatilityRisk = 30.0;
        else if(m_Profile.atrRatio > 1.2)
            volatilityRisk = 20.0;
        else if(m_Profile.atrRatio > 1.0)
            volatilityRisk = 10.0;
        
        // 2. Rủi ro chuyển tiếp chế độ (0-30%)
        double regimeRisk = m_TransitionScore * 30.0;
        
        // 3. Rủi ro ADX - xu hướng quá mạnh (0-15%)
        double adxRisk = 0;
        if(m_Profile.adxH4 > 40)
            adxRisk = 15.0;
        else if(m_Profile.adxH4 > 30)
            adxRisk = 10.0;
        else if(m_Profile.adxH4 > 20)
            adxRisk = 5.0;
        
        // 4. Rủi ro volume (0-15%)
        double volumeRisk = m_Profile.volumeSpike ? 15.0 : 0.0;
        
        // Tổng hợp
        riskLevel = volatilityRisk + regimeRisk + adxRisk + volumeRisk;
        
        // Giới hạn 0-100%
        riskLevel = MathMin(MathMax(riskLevel, 0.0), 100.0);
        
        return riskLevel;
    }
    
    //+------------------------------------------------------------------+
    //| Kiểm tra mức độ rủi ro trước khi giao dịch - Mới v13            |
    //+------------------------------------------------------------------+
    bool IsAcceptableRiskLevel()
    {
        double riskLevel = CalculateMarketRiskLevel();
        
        // Ngưỡng rủi ro chấp nhận được
        double acceptableRiskThreshold = 70.0; // 70% là ngưỡng cảnh báo
        
        if(riskLevel > acceptableRiskThreshold) {
            if(m_Logger != NULL) {
                m_Logger.LogWarning(StringFormat("Rủi ro thị trường quá cao (%.1f%%) - Không an toàn để giao dịch", riskLevel));
            }
            return false;
        }
        
        // Trong chế độ nghiêm ngặt, hạ ngưỡng xuống 60%
        if(m_EnforceStrictFiltering && riskLevel > 60.0) {
            if(m_Logger != NULL) {
                m_Logger.LogWarning(StringFormat("Rủi ro thị trường (%.1f%%) cao trong chế độ nghiêm ngặt - Bỏ qua cơ hội", riskLevel));
            }
            return false;
        }
        
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Điều chỉnh giao dịch với lệnh Adaptive ATR - Mới v13            |
    //+------------------------------------------------------------------+
    void AdjustTradeWithAdaptiveATR(SignalInfo &signal)
    {
        if(m_MarketMonitor == NULL) return;
        
        // Lấy ATR hiện tại và trung bình
        double currentATR = m_MarketMonitor.GetATR();
        double avgATR = m_MarketMonitor.GetAverageATR();
        
        if(currentATR <= 0 || avgATR <= 0) return;
        
        // Tính tỷ lệ ATR hiện tại/trung bình
        double atrRatio = currentATR / avgATR;
        
        // Điều chỉnh khoảng cách SL/TP dựa trên tỷ lệ ATR
        if(atrRatio > 1.2)
        {
            // ATR cao hơn trung bình 20% - điều chỉnh SL/TP
            double adjustFactor = MathMin(atrRatio, 2.0); // Giới hạn tối đa 2x
            
            if(signal.isLong)
            {
                // Mở rộng SL xuống dưới và TP lên trên
                signal.stopLoss -= currentATR * (adjustFactor - 1.0) * 0.5;
                signal.takeProfit += currentATR * (adjustFactor - 1.0) * 0.5;
            }
            else
            {
                // Mở rộng SL lên trên và TP xuống dưới
                signal.stopLoss += currentATR * (adjustFactor - 1.0) * 0.5;
                signal.takeProfit -= currentATR * (adjustFactor - 1.0) * 0.5;
            }
            
            if(m_Logger != NULL)
            {
                m_Logger.LogInfo(StringFormat("Điều chỉnh SL/TP do ATR cao (%.1f%%): SL=%.5f, TP=%.5f", 
                                         (atrRatio - 1.0) * 100.0, signal.stopLoss, signal.takeProfit));
            }
        }
        else if(atrRatio < 0.8)
        {
            // ATR thấp hơn trung bình 20% - thu hẹp SL/TP
            double adjustFactor = atrRatio / 0.8; // Điều chỉnh giảm khi ATR thấp
            
            if(signal.isLong)
            {
                // Thu hẹp SL lên trên và TP xuống dưới
                double slDistance = signal.entryPrice - signal.stopLoss;
                double tpDistance = signal.takeProfit - signal.entryPrice;
                
                signal.stopLoss = signal.entryPrice - (slDistance * adjustFactor);
                signal.takeProfit = signal.entryPrice + (tpDistance * adjustFactor);
            }
            else
            {
                // Thu hẹp SL xuống dưới và TP lên trên
                double slDistance = signal.stopLoss - signal.entryPrice;
                double tpDistance = signal.entryPrice - signal.takeProfit;
                
                signal.stopLoss = signal.entryPrice + (slDistance * adjustFactor);
                signal.takeProfit = signal.entryPrice - (tpDistance * adjustFactor);
            }
            
            if(m_Logger != NULL)
            {
                m_Logger.LogInfo(StringFormat("Điều chỉnh SL/TP do ATR thấp (%.1f%%): SL=%.5f, TP=%.5f", 
                                         (1.0 - atrRatio) * 100.0, signal.stopLoss, signal.takeProfit));
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| Lấy thông tin kịch bản hiện tại và tín hiệu                     |
    //+------------------------------------------------------------------+
    void GetActiveScenario(ENUM_ENTRY_SCENARIO &scenario, ENUM_TRADE_SIGNAL &signal)
    {
        scenario = m_Scenario;
        signal = m_Signal;
    }
};

#endif // _TRADE_DECISION_MQH_