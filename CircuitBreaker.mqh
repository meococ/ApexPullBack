//+------------------------------------------------------------------+
//|                CircuitBreaker.mqh - APEX Pullback EA v14.0      |
//+------------------------------------------------------------------+
#ifndef CIRCUIT_BREAKER_MQH_
#define CIRCUIT_BREAKER_MQH_

// #include "CommonStructs.mqh" // Included via ApexPullback.mqh

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

//+------------------------------------------------------------------+
//| Enum cho các loại cảnh báo Circuit Breaker                     |
//+------------------------------------------------------------------+
enum ENUM_CIRCUIT_BREAKER_ALERT {
    CB_ALERT_NONE = 0,           // Không có cảnh báo
    CB_ALERT_SPREAD_EXPANSION,   // Spread giãn nở bất thường
    CB_ALERT_EXTREME_VOLATILITY, // Biến động cực đoan
    CB_ALERT_RAPID_PRICE_MOVE,   // Giá di chuyển quá nhanh
    CB_ALERT_LIQUIDITY_CRISIS,   // Khủng hoảng thanh khoản
    CB_ALERT_NEWS_SHOCK,         // Sốc tin tức
    CB_ALERT_MARKET_CRASH,       // Sụp đổ thị trường
    CB_ALERT_SYSTEM_OVERLOAD,    // Hệ thống quá tải
    CB_ALERT_CONSECUTIVE_LOSSES  // Chuỗi thua lỗ liên tiếp
};

//+------------------------------------------------------------------+
//| Cấu trúc dữ liệu cho Market Anomaly Detection                  |
//+------------------------------------------------------------------+
struct MarketAnomalyData {
    datetime timestamp;           // Thời gian phát hiện
    ENUM_CIRCUIT_BREAKER_ALERT alertType; // Loại cảnh báo
    double severity;              // Mức độ nghiêm trọng (0-100)
    double currentSpread;         // Spread hiện tại
    double normalSpread;          // Spread bình thường
    double spreadRatio;           // Tỷ lệ spread/normal
    double priceMovement;         // Di chuyển giá (ATR multiplier)
    double volatilityIndex;       // Chỉ số biến động
    string description;           // Mô tả chi tiết
    bool isActive;                // Cảnh báo có đang hoạt động
    
    // Constructor
    MarketAnomalyData() {
        timestamp = 0;
        alertType = CB_ALERT_NONE;
        severity = 0.0;
        currentSpread = 0.0;
        normalSpread = 0.0;
        spreadRatio = 1.0;
        priceMovement = 0.0;
        volatilityIndex = 0.0;
        description = "";
        isActive = false;
    }
};

//+------------------------------------------------------------------+
//| Cấu trúc cấu hình Circuit Breaker                              |
//+------------------------------------------------------------------+
struct CircuitBreakerConfig {
    // Spread Thresholds
    double maxSpreadMultiplier;   // Spread tối đa (x lần bình thường)
    double criticalSpreadMultiplier; // Spread nguy hiểm
    
    // Price Movement Thresholds
    double maxATRMultiplier;      // Di chuyển giá tối đa (x ATR)
    double criticalATRMultiplier; // Di chuyển nguy hiểm
    
    // Volatility Thresholds
    double maxVolatilityIndex;    // Chỉ số biến động tối đa
    double criticalVolatilityIndex; // Biến động nguy hiểm
    
    // Time Windows
    int spreadCheckPeriod;        // Thời gian kiểm tra spread (seconds)
    int volatilityCheckPeriod;    // Thời gian kiểm tra volatility
    int priceMovementPeriod;      // Thời gian kiểm tra price movement
    
    // Emergency Actions
    bool autoClosePositions;      // Tự động đóng positions
    bool pauseNewTrades;          // Tạm dừng trades mới
    bool sendAlerts;              // Gửi cảnh báo
    bool logToFile;               // Ghi log ra file
    
    // Recovery Settings
    int recoveryWaitMinutes;      // Thời gian chờ phục hồi (phút)
    double recoveryThreshold;     // Ngưỡng phục hồi
    
    // Loss Streak Settings
    int maxConsecutiveLosses;     // Số lần thua liên tiếp tối đa cho phép
    int pauseDurationOnLossStreak;// Thời gian tạm dừng sau chuỗi thua lỗ (phút)
    
    // Constructor
    CircuitBreakerConfig() {
        maxSpreadMultiplier = 3.0;        // 3x spread bình thường
        criticalSpreadMultiplier = 5.0;   // 5x = nguy hiểm
        maxATRMultiplier = 3.0;           // 3x ATR
        criticalATRMultiplier = 5.0;      // 5x ATR = nguy hiểm
        maxVolatilityIndex = 80.0;        // 80% volatility
        criticalVolatilityIndex = 95.0;   // 95% = nguy hiểm
        spreadCheckPeriod = 30;           // 30 giây
        volatilityCheckPeriod = 60;       // 60 giây
        priceMovementPeriod = 60;         // 60 giây
        autoClosePositions = true;
        pauseNewTrades = true;
        sendAlerts = true;
        logToFile = true;
        recoveryWaitMinutes = 15;         // 15 phút
        recoveryThreshold = 0.7;          // 70% recovery
        maxConsecutiveLosses = 5;         // 5 lần thua liên tiếp
        pauseDurationOnLossStreak = 240;  // 4 giờ
    }
};

//+------------------------------------------------------------------+
//| Lớp CircuitBreaker - Phòng thủ Black Swan                      |
//+------------------------------------------------------------------+
class CCircuitBreaker {
private:
    EAContext* m_context;
    CLogger* m_logger;
    
    // Configuration
    CircuitBreakerConfig m_config;
    
    // Market Monitoring Data
    MarketAnomalyData m_currentAnomaly;
    MarketAnomalyData m_anomalyHistory[];
    int m_anomalyCount;
    
    // Baseline Market Data
    double m_normalSpread;
    double m_normalATR;
    double m_normalVolatility;
    datetime m_lastBaselineUpdate;
    
    // Circuit Breaker State
    bool m_isTriggered;
    datetime m_triggerTime;
    datetime m_lastCheckTime;
    ENUM_CIRCUIT_BREAKER_ALERT m_currentAlert;
    double m_currentSeverity;
    
    // Emergency Actions State
    bool m_positionsClosedByBreaker;
    bool m_tradingPausedByBreaker;
    int m_emergencyActionsCount;
    
    // Recovery Tracking
    datetime m_recoveryStartTime;
    bool m_isInRecoveryMode;
    double m_recoveryProgress;
    
    // Loss Streak Tracking
    int m_currentConsecutiveLosses;
    bool m_isPausedDueToLossStreak;
    datetime m_pauseEndTime;
    
public:
    // Constructor & Destructor
    CCircuitBreaker() {
        m_context = NULL;
        m_logger = NULL;
        m_normalSpread = 0.0;
        m_normalATR = 0.0;
        m_normalVolatility = 0.0;
        m_lastBaselineUpdate = 0;
        m_isTriggered = false;
        m_triggerTime = 0;
        m_lastCheckTime = 0;
        m_currentAlert = CB_ALERT_NONE;
        m_currentSeverity = 0.0;
        m_positionsClosedByBreaker = false;
        m_tradingPausedByBreaker = false;
        m_emergencyActionsCount = 0;
        m_recoveryStartTime = 0;
        m_isInRecoveryMode = false;
        m_recoveryProgress = 0.0;
        m_anomalyCount = 0;
        m_currentConsecutiveLosses = 0;
        m_isPausedDueToLossStreak = false;
        m_pauseEndTime = 0;
    }

    ~CCircuitBreaker() {
        Cleanup();
    }
    
    // Initialization
    bool Initialize(EAContext* context) {
        if (context == NULL) {
            Print("[ERROR] CircuitBreaker: Context is NULL");
            return false;
        }
        
        m_context = context;
        m_logger = context->pLogger;
        
        if (m_logger != NULL) {
            m_logger->LogInfo("CircuitBreaker: Khởi tạo hệ thống phòng thủ Black Swan...");
        }
        
        // Load configuration
        LoadConfiguration();
        
        // Initialize baseline data
        UpdateMarketBaseline();
        
        // Initialize arrays
        ArrayResize(m_anomalyHistory, 0);
        
        if (m_logger != NULL) {
            m_logger->LogInfo("CircuitBreaker: Khởi tạo thành công - Hệ thống sẵn sàng giám sát");
        }
        
        return true;
    }

    void Cleanup(){}
    bool LoadConfiguration(){ return true;}
    bool SaveConfiguration(){ return true;}
    
    // Main Monitoring Functions
    bool MonitorMarketConditions() {
        if (m_context == NULL) {
            return false;
        }
        
        datetime currentTime = TimeCurrent();
        
        // Skip if checked recently (avoid overload)
        if (currentTime - m_lastCheckTime < 5) { // 5 seconds minimum interval
            return true;
        }
        
        m_lastCheckTime = currentTime;
        
        // Update baseline periodically
        if (currentTime - m_lastBaselineUpdate > 3600) { // 1 hour
            UpdateMarketBaseline();
        }
        
        bool anomalyDetected = false;
        
        // Check various anomaly types
        if (CheckSpreadAnomalies()) {
            anomalyDetected = true;
        }
        
        if (CheckVolatilityAnomalies()) {
            anomalyDetected = true;
        }
        
        if (CheckPriceMovementAnomalies()) {
            anomalyDetected = true;
        }
        
        if (CheckLiquidityConditions()) {
            anomalyDetected = true;
        }
        
        // If in recovery mode, monitor progress
        if (m_isInRecoveryMode) {
            MonitorRecoveryProgress();
        }
        
        return !anomalyDetected; // Return false if anomaly detected
    }

    bool CheckSpreadAnomalies() {
        double currentSpread = GetCurrentSpread();
        
        if (m_normalSpread <= 0) {
            return false; // No baseline yet
        }
        
        double spreadRatio = currentSpread / m_normalSpread;
        
        // Critical spread expansion (5x normal)
        if (spreadRatio >= m_config.criticalSpreadMultiplier) {
            double severity = MathMin(100.0, (spreadRatio / m_config.criticalSpreadMultiplier) * 100.0);
            TriggerCircuitBreaker(CB_ALERT_SPREAD_EXPANSION, severity);
            
            if (m_logger != NULL) {
                m_logger->LogCritical(StringFormat("CircuitBreaker: SPREAD KHỦNG HOẢNG! %.1fx bình thường (%.2f vs %.2f)", 
                                                   spreadRatio, currentSpread, m_normalSpread));
            }
            return true;
        }
        
        // Warning level spread expansion (3x normal)
        if (spreadRatio >= m_config.maxSpreadMultiplier) {
            double severity = (spreadRatio / m_config.maxSpreadMultiplier) * 60.0;
            
            if (m_logger != NULL) {
                m_logger->LogWarning(StringFormat("CircuitBreaker: Cảnh báo spread cao: %.1fx bình thường", spreadRatio));
            }
            
            // Update context state
            if (m_context != NULL) {
                m_context->IsHighSpreadDetected = true;
                m_context->CurrentSpreadRatio = spreadRatio;
            }
        }
        
        return false;
    }

    bool CheckVolatilityAnomalies() {
        double volatilityIndex = GetCurrentVolatilityIndex();
        
        // Critical volatility (95%+)
        if (volatilityIndex >= m_config.criticalVolatilityIndex) {
            TriggerCircuitBreaker(CB_ALERT_EXTREME_VOLATILITY, volatilityIndex);
            
            if (m_logger != NULL) {
                m_logger->LogCritical(StringFormat("CircuitBreaker: BIẾN ĐỘNG CỰC ĐOAN! Index: %.1f%%", volatilityIndex));
            }
            return true;
        }
        
        // Warning level volatility (80%+)
        if (volatilityIndex >= m_config.maxVolatilityIndex) {
            if (m_logger != NULL) {
                m_logger->LogWarning(StringFormat("CircuitBreaker: Cảnh báo biến động cao: %.1f%%", volatilityIndex));
            }
            
            // Update context state
            if (m_context != NULL) {
                m_context->IsHighVolatilityDetected = true;
                m_context->CurrentVolatilityIndex = volatilityIndex;
            }
        }
        
        return false;
    }

    bool CheckPriceMovementAnomalies() {
        double currentATR = GetCurrentATR();
        if (currentATR <= 0) {
            return false;
        }
        
        // Get recent price movement
        double high = iHigh(_Symbol, PERIOD_M1, 0);
        double low = iLow(_Symbol, PERIOD_M1, 0);
        double priceRange = high - low;
        double atrMultiplier = priceRange / currentATR;
        
        // Critical price movement (5x ATR in 1 minute)
        if (atrMultiplier >= m_config.criticalATRMultiplier) {
            double severity = MathMin(100.0, (atrMultiplier / m_config.criticalATRMultiplier) * 100.0);
            TriggerCircuitBreaker(CB_ALERT_RAPID_PRICE_MOVE, severity);
            
            if (m_logger != NULL) {
                m_logger->LogCritical(StringFormat("CircuitBreaker: GIÁ DI CHUYỂN CỰC NHANH! %.1fx ATR trong 1 phút", atrMultiplier));
            }
            return true;
        }
        
        // Warning level movement (3x ATR)
        if (atrMultiplier >= m_config.maxATRMultiplier) {
            if (m_logger != NULL) {
                m_logger->LogWarning(StringFormat("CircuitBreaker: Cảnh báo giá di chuyển nhanh: %.1fx ATR", atrMultiplier));
            }
        }
        
        return false;
    }

    bool CheckLiquidityConditions(){ return false; }
    
    // V14.0: Parameter Stability Monitoring
    bool MonitorParameterStability(){ return true; }
    bool CheckParameterInstability(){ return false; }
    bool TriggerParameterStabilityAlert(double instabilityIndex){ return true; }
    
    // Anomaly Detection
    bool DetectMarketAnomaly(){ return false; }
    double CalculateAnomalySeverity(ENUM_CIRCUIT_BREAKER_ALERT alertType){ return 0; }
    bool ValidateAnomaly(const MarketAnomalyData& anomaly){ return true; }
    
    // Circuit Breaker Actions
    bool TriggerCircuitBreaker(ENUM_CIRCUIT_BREAKER_ALERT alertType, double severity){ return true; }
    bool ExecuteEmergencyActions(){ return true; }
    bool CloseAllPositionsEmergency(){ return true; }
    bool PauseTradingActivities(){ return true; }
    bool SendEmergencyAlert(const string& message){ return true; }
    
    // Recovery Management
    bool StartRecoveryProcess(){ return true; }
    bool MonitorRecoveryProgress(){ return true; }
    bool CheckRecoveryConditions(){ return true; }
    bool ResumeNormalOperations(){ return true; }
    
    // Baseline Management
    bool UpdateMarketBaseline(){ return true; }
    bool CalculateNormalSpread(){ return true; }
    bool CalculateNormalATR(){ return true; }
    bool CalculateNormalVolatility(){ return true; }
    
    // State Management
    void OnDealClosed(bool isWin) {
        if (isWin) {
            m_currentConsecutiveLosses = 0;
            return;
        }
        
        m_currentConsecutiveLosses++;
        
        if (m_currentConsecutiveLosses >= m_config.maxConsecutiveLosses) {
            double severity = (double)m_currentConsecutiveLosses / m_config.maxConsecutiveLosses * 100.0;
            TriggerCircuitBreaker(CB_ALERT_CONSECUTIVE_LOSSES, severity);
            
            if (m_logger != NULL) {
                m_logger->LogWarning(StringFormat("CircuitBreaker: Phát hiện chuỗi thua lỗ (%d lần). Tạm dừng giao dịch trong %d phút.",
                                                 m_currentConsecutiveLosses, m_config.pauseDurationOnLossStreak));
            }
            
            m_isPausedDueToLossStreak = true;
            m_pauseEndTime = TimeCurrent() + m_config.pauseDurationOnLossStreak * 60; // Chuyển phút thành giây
        }
    }

    bool IsTradingAllowed() {
        if (m_isPausedDueToLossStreak) {
            if (TimeCurrent() >= m_pauseEndTime) {
                m_isPausedDueToLossStreak = false;
                m_currentConsecutiveLosses = 0;
                
                if (m_logger != NULL) {
                    m_logger->LogInfo("CircuitBreaker: Hết thời gian tạm dừng do chuỗi thua lỗ. Cho phép giao dịch trở lại.");
                }
                return true;
            }
            return false;
        }
        
        return !m_isTriggered && !m_tradingPausedByBreaker;
    }

    bool IsCircuitBreakerTriggered() const { return m_isTriggered; }
    bool IsTradingPaused() const { return m_tradingPausedByBreaker; }
    ENUM_CIRCUIT_BREAKER_ALERT GetCurrentAlert() const { return m_currentAlert; }
    double GetCurrentSeverity() const { return m_currentSeverity; }
    bool IsInRecoveryMode() const { return m_isInRecoveryMode; }
    
    // Configuration Management
    bool SetSpreadThreshold(double maxMultiplier, double criticalMultiplier){ return true; }
    bool SetVolatilityThreshold(double maxIndex, double criticalIndex){ return true; }
    bool SetPriceMovementThreshold(double maxATR, double criticalATR){ return true; }
    
    // Reporting
    string GetStatusReport(){ return ""; }
    string GetAnomalyReport(){ return ""; }
    bool GenerateEmergencyReport(){ return true; }
    bool LogAnomalyToFile(const MarketAnomalyData& anomaly){ return true; }
    
private:
    // Helper Methods
    double GetCurrentSpread();
    double GetCurrentATR();
    double GetCurrentVolatilityIndex();
    bool IsMarketHours();
    void LogCircuitBreakerEvent(const string& event, ENUM_CIRCUIT_BREAKER_ALERT alertType);
    string AlertTypeToString(ENUM_CIRCUIT_BREAKER_ALERT alertType);
}; // END of CCircuitBreaker class
// Implement other methods here...

//+------------------------------------------------------------------+
//| Helper Method Implementations                                  |
//+------------------------------------------------------------------+
double CCircuitBreaker::GetCurrentSpread() { return 0; } // Placeholder
double CCircuitBreaker::GetCurrentATR() { return 0; } // Placeholder
double CCircuitBreaker::GetCurrentVolatilityIndex() { return 0; } // Placeholder
bool CCircuitBreaker::IsMarketHours() { return true; } // Placeholder
void CCircuitBreaker::LogCircuitBreakerEvent(const string& event, ENUM_CIRCUIT_BREAKER_ALERT alertType) {} // Placeholder
string CCircuitBreaker::AlertTypeToString(ENUM_CIRCUIT_BREAKER_ALERT alertType) { return ""; } // Placeholder

bool CCircuitBreaker::CloseAllPositionsEmergency() {
    if (m_positionsClosedByBreaker) {
        return true; // Already closed
    }
    
    if (m_logger != NULL) {
        m_logger->LogCritical("CircuitBreaker: ĐÓNG TẤT CẢ POSITIONS KHẨN CẤP!");
    }
    
    int totalPositions = PositionsTotal();
    int closedCount = 0;
    
    for (int i = totalPositions - 1; i >= 0; i--) {
        if (PositionSelectByIndex(i)) {
            ulong ticket = PositionGetInteger(POSITION_TICKET);
            long magic = PositionGetInteger(POSITION_MAGIC);
            
            // Only close positions with our magic number
            if (m_context != NULL && magic == m_context->MagicNumber) {
                MqlTradeRequest request = {};
                MqlTradeResult result = {};
                
                request.action = TRADE_ACTION_DEAL;
                request.position = ticket;
                request.symbol = PositionGetString(POSITION_SYMBOL);
                request.volume = PositionGetDouble(POSITION_VOLUME);
                request.type = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
                request.comment = "CircuitBreaker Emergency Close";
                
                if (OrderSend(request, result)) {
                    closedCount++;
                }
            }
        }
    }
    
    m_positionsClosedByBreaker = true;
    
    if (m_logger != NULL) {
        m_logger->LogCritical(StringFormat("CircuitBreaker: Đã đóng %d/%d positions", closedCount, totalPositions));
    }
    
    return true;
}


//+------------------------------------------------------------------+
bool CCircuitBreaker::PauseTradingActivities() {
    m_tradingPausedByBreaker = true;
    
    // Update context to pause trading
    if (m_context != NULL) {
        m_context->IsTradingPaused = true;
        m_context->TradingPauseReason = "Circuit Breaker Triggered";
    }
    
    if (m_logger != NULL) {
        m_logger->LogCritical("CircuitBreaker: TẠM DỪNG TẤT CẢ HOẠT ĐỘNG GIAO DỊCH!");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Helper Methods Implementation                                    |
//+------------------------------------------------------------------+
double CCircuitBreaker::GetCurrentSpread() {
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    return ask - bid;
}

double CCircuitBreaker::GetCurrentATR() {
    // Simple ATR calculation using recent price data
    double high = iHigh(_Symbol, PERIOD_M5, 0);
    double low = iLow(_Symbol, PERIOD_M5, 0);
    return high - low;
}

double CCircuitBreaker::GetCurrentVolatilityIndex() {
    // Simplified volatility index based on recent price movements
    double range1 = iHigh(_Symbol, PERIOD_M1, 0) - iLow(_Symbol, PERIOD_M1, 0);
    double range2 = iHigh(_Symbol, PERIOD_M1, 1) - iLow(_Symbol, PERIOD_M1, 1);
    double range3 = iHigh(_Symbol, PERIOD_M1, 2) - iLow(_Symbol, PERIOD_M1, 2);
    
    double avgRange = (range1 + range2 + range3) / 3.0;
    double currentRange = range1;
    
    return MathMin(100.0, (currentRange / (avgRange + 0.00001)) * 50.0);
}

string CCircuitBreaker::AlertTypeToString(ENUM_CIRCUIT_BREAKER_ALERT alertType) {
    switch(alertType) {
        case CB_ALERT_SPREAD_EXPANSION: return "Spread Expansion";
        case CB_ALERT_EXTREME_VOLATILITY: return "Extreme Volatility";
        case CB_ALERT_RAPID_PRICE_MOVE: return "Rapid Price Movement";
        case CB_ALERT_LIQUIDITY_CRISIS: return "Liquidity Crisis";
        case CB_ALERT_NEWS_SHOCK: return "News Shock";
        case CB_ALERT_MARKET_CRASH: return "Market Crash";
        case CB_ALERT_SYSTEM_OVERLOAD: return "System Overload";
        case CB_ALERT_CONSECUTIVE_LOSSES: return "Consecutive Losses";
        default: return "Unknown Alert";
    }
}

//+------------------------------------------------------------------+
//| Placeholder implementations for remaining methods                |
//+------------------------------------------------------------------+
bool CCircuitBreaker::UpdateMarketBaseline() {
    m_normalSpread = GetCurrentSpread();
    m_normalATR = GetCurrentATR();
    m_normalVolatility = GetCurrentVolatilityIndex();
    m_lastBaselineUpdate = TimeCurrent();
    return true;
}

bool CCircuitBreaker::CheckLiquidityConditions() {
    // Implementation would check order book depth, slippage, etc.
    return false;
}

bool CCircuitBreaker::StartRecoveryProcess() {
    m_isInRecoveryMode = true;
    m_recoveryStartTime = TimeCurrent();
    m_recoveryProgress = 0.0;
    return true;
}

bool CCircuitBreaker::MonitorRecoveryProgress() {
    // Implementation would monitor market normalization
    return true;
}

bool CCircuitBreaker::SendEmergencyAlert(const string& message) {
    // Implementation would send alerts via email, push notifications, etc.
    Print("EMERGENCY ALERT: ", message);
    return true;
}

bool CCircuitBreaker::LoadConfiguration() {
    // Implementation would load from file
    return true;
}

void CCircuitBreaker::Cleanup() {
    ArrayFree(m_anomalyHistory);
    m_anomalyCount = 0;
}

//+------------------------------------------------------------------+

} // KẾT THÚC NAMESPACE

#endif // CIRCUIT_BREAKER_MQH_