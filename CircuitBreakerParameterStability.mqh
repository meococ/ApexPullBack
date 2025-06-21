//+------------------------------------------------------------------+
//|                           CircuitBreakerParameterStability.mqh |
//|                         Copyright 2023-2024, ApexPullback EA |
//|                                     https://www.apexpullback.com |
//+------------------------------------------------------------------+

#ifndef CIRCUIT_BREAKER_PARAMETER_STABILITY_MQH_
#define CIRCUIT_BREAKER_PARAMETER_STABILITY_MQH_

// Implementation cho Parameter Stability monitoring trong CircuitBreaker
// Theo đề xuất kỹ thuật: Tích hợp với ParameterStabilityAnalyzer

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Monitor Parameter Stability - Main Entry Point                  |
//+------------------------------------------------------------------+
bool CCircuitBreaker::MonitorParameterStability()
{
    if (!m_context || !m_context->ParameterStabilityAnalyzer) {
        return false;
    }
    
    // Cập nhật Parameter Instability Index
    m_context->ParameterStabilityAnalyzer->UpdateParameterInstabilityIndex();
    
    // Kiểm tra instability
    bool hasInstability = CheckParameterInstability();
    
    if (hasInstability) {
        double instabilityIndex = m_context->CurrentParameterInstabilityIndex;
        
        // Log chi tiết
        if (m_logger) {
            string logMsg = StringFormat(
                "[CIRCUIT BREAKER] Parameter instability detected: %.1f%% (Critical: %.1f%%, Unstable: %.1f%%)",
                instabilityIndex * 100,
                70.0, // Critical threshold
                60.0  // Unstable threshold
            );
            m_logger->LogWarning(logMsg);
        }
        
        // Trigger appropriate response
        return TriggerParameterStabilityAlert(instabilityIndex);
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Check Parameter Instability Levels                              |
//+------------------------------------------------------------------+
bool CCircuitBreaker::CheckParameterInstability()
{
    if (!m_context) return false;
    
    double instabilityIndex = m_context->CurrentParameterInstabilityIndex;
    
    // Định nghĩa thresholds theo đề xuất kỹ thuật
    const double CRITICAL_THRESHOLD = 0.7;  // 70% - Emergency Stop
    const double UNSTABLE_THRESHOLD = 0.6;  // 60% - Risk Reduction
    const double ATTENTION_THRESHOLD = 0.4; // 40% - Attention Required
    
    // Cập nhật trạng thái trong context
    if (instabilityIndex >= CRITICAL_THRESHOLD) {
        m_context->IsParameterStabilityDegraded = true;
        return true; // Cần hành động khẩn cấp
    }
    else if (instabilityIndex >= UNSTABLE_THRESHOLD) {
        m_context->IsParameterStabilityDegraded = true;
        return true; // Cần giảm rủi ro
    }
    else if (instabilityIndex >= ATTENTION_THRESHOLD) {
        // Chỉ cần theo dõi, chưa cần hành động
        if (m_logger) {
            string logMsg = StringFormat(
                "[PARAMETER MONITOR] Attention required - Instability: %.1f%%",
                instabilityIndex * 100
            );
            m_logger->LogInfo(logMsg);
        }
        return false;
    }
    else {
        m_context->IsParameterStabilityDegraded = false;
        return false; // Ổn định
    }
}

//+------------------------------------------------------------------+
//| Trigger Parameter Stability Alert & Actions                     |
//+------------------------------------------------------------------+
bool CCircuitBreaker::TriggerParameterStabilityAlert(double instabilityIndex)
{
    if (!m_context) return false;
    
    const double CRITICAL_THRESHOLD = 0.7;  // 70%
    const double UNSTABLE_THRESHOLD = 0.6;  // 60%
    
    bool actionTaken = false;
    
    if (instabilityIndex >= CRITICAL_THRESHOLD) {
        // CRITICAL: Emergency Stop theo đề xuất
        if (m_logger) {
            string alertMsg = StringFormat(
                "[EMERGENCY] Parameter Instability Critical: %.1f%% - Triggering Emergency Stop",
                instabilityIndex * 100
            );
            m_logger->LogError(alertMsg);
        }
        
        // Trigger Emergency Stop
        m_context->EmergencyStop = true;
        m_context->EmergencyStopReason = "Parameter Instability Critical";
        
        // Đóng tất cả positions nếu được cấu hình
        if (m_config.autoClosePositions) {
            CloseAllPositionsEmergency();
        }
        
        // Dừng trading
        if (m_config.pauseNewTrades) {
            PauseTradingActivities();
        }
        
        // Gửi alert
        if (m_config.sendAlerts) {
            string emergencyMsg = StringFormat(
                "APEX EA EMERGENCY: Parameter instability %.1f%% exceeded critical threshold. Trading stopped.",
                instabilityIndex * 100
            );
            SendEmergencyAlert(emergencyMsg);
        }
        
        actionTaken = true;
    }
    else if (instabilityIndex >= UNSTABLE_THRESHOLD) {
        // UNSTABLE: Risk Reduction theo đề xuất
        if (m_logger) {
            string alertMsg = StringFormat(
                "[WARNING] Parameter Instability High: %.1f%% - Reducing Risk",
                instabilityIndex * 100
            );
            m_logger->LogWarning(alertMsg);
        }
        
        // Giảm rủi ro thông qua RiskManager
        if (m_context->RiskManager) {
            // Áp dụng temporary risk multiplier = 0.5 (giảm 50%)
            double riskMultiplier = 0.5;
            
            // Cập nhật vào context để RiskManager sử dụng
            m_context->CurrentRiskMultiplier = riskMultiplier;
            
            if (m_logger) {
                string riskMsg = StringFormat(
                    "[RISK ADJUSTMENT] Risk multiplier set to %.1f due to parameter instability",
                    riskMultiplier
                );
                m_logger->LogInfo(riskMsg);
            }
        }
        
        // Tăng cường các bộ lọc
        m_context->UseEnhancedFilters = true;
        m_context->RequireHighConfidenceSignals = true;
        
        actionTaken = true;
    }
    
    // Log action summary
    if (actionTaken && m_logger) {
        string summaryMsg = StringFormat(
            "[PARAMETER STABILITY] Action taken for instability %.1f%%. Emergency: %s, Risk reduced: %s",
            instabilityIndex * 100,
            (instabilityIndex >= CRITICAL_THRESHOLD) ? "YES" : "NO",
            (instabilityIndex >= UNSTABLE_THRESHOLD && instabilityIndex < CRITICAL_THRESHOLD) ? "YES" : "NO"
        );
        m_logger->LogInfo(summaryMsg);
    }
    
    // Cập nhật timestamp
    m_context->LastParameterStabilityAction = TimeCurrent();
    
    return actionTaken;
}

} // End namespace ApexPullback

#endif // CIRCUIT_BREAKER_PARAMETER_STABILITY_MQH_