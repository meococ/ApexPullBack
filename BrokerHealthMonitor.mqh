#ifndef BROKERHEALTHMONITOR_MQH_
#define BROKERHEALTHMONITOR_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Broker Health Monitor Class                                      |
//+------------------------------------------------------------------+
class CBrokerHealthMonitor {
private:
    EAContext* m_context;
    
    BrokerHealthMetrics m_CurrentMetrics;
    BrokerHealthMetrics m_PreviousMetrics;
    BrokerHealthThresholds m_Thresholds;
    
    // Historical data for trend analysis
    double m_HealthHistory[];
    double m_SlippageHistory[];
    double m_LatencyHistory[];
    int m_HistorySize;
    int m_MaxHistorySize;
    
    // Alert management
    datetime m_LastAlertTime;
    ENUM_HEALTH_STATUS m_LastAlertLevel;
    int m_AlertCooldownMinutes;
    
public:
    CBrokerHealthMonitor(EAContext* context);
    ~CBrokerHealthMonitor();
    
    bool Initialize();
    void SetThresholds(const BrokerHealthThresholds& thresholds);
    
    // Core monitoring functions
    void UpdateMetrics();
    void AnalyzeBrokerHealth();
    void UpdateWithNewDataPoint(double slippagePips, double executionTimeMs);
    
    // Getters
    BrokerHealthMetrics GetCurrentMetrics() const { return m_CurrentMetrics; }
    double GetHealthScore() const { return m_CurrentMetrics.HealthScore; }
    ENUM_HEALTH_STATUS GetHealthStatus() const { return m_CurrentMetrics.HealthStatus; }
    
    // Risk management integration
    double GetRiskAdjustmentFactor();
    double GetHealthBasedRiskFactor();
    bool ShouldReduceRisk();
    bool ShouldIncreaseSpread();
    bool ShouldTriggerCircuitBreaker();
    
    // Reporting
    void GenerateHealthReport(string& report);
    string GenerateDetailedReport();
    
    // Utility
    void Reset();
    void SaveMetricsToFile(const string& filename);
    bool LoadMetricsFromFile(const string& filename);
    
private:
    // Internal calculation methods
    double CalculateSlippageScore();
    double CalculateLatencyScore();
    double CalculateRequoteScore();
    double CalculateSuccessRateScore();
    double CalculateOverallHealthScore();
    
    // Trend analysis
    void UpdateHealthHistory(double healthScore);
    void UpdateTrendAnalysis();
    
    // Alert system
    void CheckAndTriggerAlerts();
    bool IsAlertCooldownActive();
    
    // Utility methods
    ENUM_HEALTH_STATUS DetermineHealthStatus(double healthScore);
    string GetHealthStatusString(ENUM_HEALTH_STATUS status);
    
    //+------------------------------------------------------------------+
    //| Constructor                                                      |
    //+------------------------------------------------------------------+
    CBrokerHealthMonitor::CBrokerHealthMonitor(EAContext* context) :
        m_context(context),
        m_HistorySize(0),
        m_MaxHistorySize(100),
        m_LastAlertTime(0),
        m_LastAlertLevel(HEALTH_EXCELLENT),
        m_AlertCooldownMinutes(15)
    {
        // Initialize metrics to default values
        m_CurrentMetrics.HealthScore = 100.0;
        m_CurrentMetrics.HealthStatus = HEALTH_EXCELLENT;
        m_CurrentMetrics.SlippageScore = 100.0;
        m_CurrentMetrics.LatencyScore = 100.0;
        m_CurrentMetrics.RequoteScore = 100.0;
        m_CurrentMetrics.SuccessRateScore = 100.0;
        m_CurrentMetrics.HealthTrend = 0.0;
        
        m_PreviousMetrics = m_CurrentMetrics;
        
        // Initialize thresholds to default values
        m_Thresholds.ExcellentThreshold = 95.0;
        m_Thresholds.GoodThreshold = 80.0;
        m_Thresholds.WarningThreshold = 60.0;
        m_Thresholds.CriticalThreshold = 40.0;
        m_Thresholds.DeterioratingTrend = -2.0;
        
        // Resize history arrays
        ArrayResize(m_HealthHistory, m_MaxHistorySize);
        ArrayResize(m_SlippageHistory, m_MaxHistorySize);
        ArrayResize(m_LatencyHistory, m_MaxHistorySize);
        
        // Initialize arrays with neutral values
        ArrayInitialize(m_HealthHistory, 100.0);
        ArrayInitialize(m_SlippageHistory, 0.0);
        ArrayInitialize(m_LatencyHistory, 0.0);
    }
    
    //+------------------------------------------------------------------+
    //| Destructor                                                       |
    //+------------------------------------------------------------------+
    CBrokerHealthMonitor::~CBrokerHealthMonitor() {
        // Cleanup if needed
    }
    
    //+------------------------------------------------------------------+
    //| Initialize                                                       |
    //+------------------------------------------------------------------+
    bool CBrokerHealthMonitor::Initialize() {
        if (m_context.pLogger != NULL) {
            m_context.pLogger->Log(ALERT_LEVEL_INFO, "BrokerHealthMonitor initialized successfully");
        }
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Set Custom Thresholds                                           |
    //+------------------------------------------------------------------+
    void CBrokerHealthMonitor::SetThresholds(const BrokerHealthThresholds& thresholds) {
        m_Thresholds = thresholds;
        
        if (m_context.pLogger != NULL) {
            m_context.pLogger->Log(ALERT_LEVEL_INFO, "Custom broker health thresholds applied");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Calculate Slippage Score                                         |
    //+------------------------------------------------------------------+
    double CalculateSlippageScore() {
        // Placeholder implementation
        // In a real implementation, this would analyze recent slippage data
        // and return a score from 0-100 where 100 is excellent (low slippage)
        
        // For now, return a simulated score based on current market conditions
        double baseScore = 85.0;
        
        // Add some randomness to simulate real broker conditions
        // In production, this would be based on actual slippage measurements
        double variation = (MathRand() % 21 - 10) * 0.5; // ±5 points
        
        return MathMax(0.0, MathMin(100.0, baseScore + variation));
    }
    
    //+------------------------------------------------------------------+
    //| Calculate Latency Score                                          |
    //+------------------------------------------------------------------+
    double CalculateLatencyScore() {
        // Placeholder implementation
        // In a real implementation, this would measure order execution times
        
        double baseScore = 90.0;
        double variation = (MathRand() % 21 - 10) * 0.3; // ±3 points
        
        return MathMax(0.0, MathMin(100.0, baseScore + variation));
    }
    
    //+------------------------------------------------------------------+
    //| Calculate Requote Score                                          |
    //+------------------------------------------------------------------+
    double CalculateRequoteScore() {
        // Placeholder implementation
        // In a real implementation, this would track requote frequency
        
        double baseScore = 95.0;
        double variation = (MathRand() % 11 - 5) * 0.4; // ±2 points
        
        return MathMax(0.0, MathMin(100.0, baseScore + variation));
    }
    
    //+------------------------------------------------------------------+
    //| Calculate Success Rate Score                                     |
    //+------------------------------------------------------------------+
    double CalculateSuccessRateScore() {
        // Placeholder implementation
        // In a real implementation, this would track order execution success rate
        
        double baseScore = 98.0;
        double variation = (MathRand() % 5 - 2) * 0.2; // ±0.4 points
        
        return MathMax(0.0, MathMin(100.0, baseScore + variation));
    }
    
    //+------------------------------------------------------------------+
    //| Update Metrics                                                   |
    //+------------------------------------------------------------------+
    void UpdateMetrics() {
        // Store previous metrics for comparison
        m_PreviousMetrics = m_CurrentMetrics;
        
        // Calculate individual component scores
        m_CurrentMetrics.SlippageScore = CalculateSlippageScore();
        m_CurrentMetrics.LatencyScore = CalculateLatencyScore();
        m_CurrentMetrics.RequoteScore = CalculateRequoteScore();
        m_CurrentMetrics.SuccessRateScore = CalculateSuccessRateScore();
        
        // Calculate overall health score
        m_CurrentMetrics.HealthScore = CalculateOverallHealthScore();
        
        // Determine health status
        m_CurrentMetrics.HealthStatus = DetermineHealthStatus(m_CurrentMetrics.HealthScore);
        
        // Update historical data and trends
        UpdateHealthHistory(m_CurrentMetrics.HealthScore);
        UpdateTrendAnalysis();
        
        if (m_Logger != NULL && m_Context != NULL && m_Context->InputLogLevel >= LOG_LEVEL_DEBUG) {
            m_Logger->LogDebug(StringFormat("Health metrics updated: Score=%.2f, Status=%s", 
                                            m_CurrentMetrics.HealthScore, 
                                            GetHealthStatusString(m_CurrentMetrics.HealthStatus)));
        }
    }
    
    //+------------------------------------------------------------------+
    //| Calculate Overall Health Score                                   |
    //+------------------------------------------------------------------+
    double CalculateOverallHealthScore() {
        // Weighted average of component scores
        double slippageWeight = 0.3;
        double latencyWeight = 0.25;
        double requoteWeight = 0.25;
        double successRateWeight = 0.2;
        
        double totalScore = (m_CurrentMetrics.SlippageScore * slippageWeight) +
                            (m_CurrentMetrics.LatencyScore * latencyWeight) +
                            (m_CurrentMetrics.RequoteScore * requoteWeight) +
                            (m_CurrentMetrics.SuccessRateScore * successRateWeight);
        
        return totalScore;
    }
    
    //+------------------------------------------------------------------+
    //| Update Health History                                            |
    //+------------------------------------------------------------------+
    void UpdateHealthHistory(double healthScore) {
        if (m_HistorySize < m_MaxHistorySize) {
            m_HealthHistory[m_HistorySize] = healthScore;
            m_HistorySize++;
        } else {
            // Shift history to the left
            for (int i = 0; i < m_MaxHistorySize - 1; i++) {
                m_HealthHistory[i] = m_HealthHistory[i+1];
            }
            m_HealthHistory[m_MaxHistorySize - 1] = healthScore;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Update Trend Analysis                                            |
    //+------------------------------------------------------------------+
    void UpdateTrendAnalysis() {
        if (m_HistorySize < 2) {
            m_CurrentMetrics.HealthTrend = 0.0;
            return;
        }
        
        // Simple linear trend: (last value - first value) / number of periods
        // A more sophisticated method like linear regression could be used here.
        double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
        int n = MathMin(m_HistorySize, 20); // Use last 20 data points for trend
        
        for (int i = 0; i < n; i++) {
            int index = m_HistorySize - n + i;
            sumX += i;
            sumY += m_HealthHistory[index];
            sumXY += i * m_HealthHistory[index];
            sumX2 += i * i;
        }
        
        double denominator = n * sumX2 - sumX * sumX;
        if (denominator != 0) {
            m_CurrentMetrics.HealthTrend = (n * sumXY - sumX * sumY) / denominator;
        } else {
            m_CurrentMetrics.HealthTrend = 0.0;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Update With New Data Point (Called by TradeManager)              |
    //+------------------------------------------------------------------+
    void UpdateWithNewDataPoint(double slippagePips, double executionTimeMs) {
        // This is the primary method for receiving new data from actual trades
        // For now, we'll just log it. A more complex implementation would update
        // rolling averages of slippage, latency, etc.
        
        if(m_Logger != NULL) {
            m_Logger->LogDebug(StringFormat("New broker data point: Slippage=%.2f pips, Latency=%.1f ms", slippagePips, executionTimeMs));
        }
        
        // Future implementation: Update rolling averages and recalculate scores.
    }
    
    //+------------------------------------------------------------------+
    //| Analyze Broker Health (Called periodically, e.g., OnTick)        |
    //+------------------------------------------------------------------+
    void AnalyzeBrokerHealth() {
        // This function is now responsible for periodic analysis and reporting,
        // not for generating fake data.
        // The actual data crunching and score updates should happen when new data arrives
        // or on a less frequent timer basis.
        
        // For v14.0, we will assume metrics are updated elsewhere and just focus on alerts.
        CheckAndTriggerAlerts();
        
        // Optional: Log a summary report periodically if debugging is enabled
        static datetime lastReportTime = 0;
        if(m_Context != NULL && m_Context->InputLogLevel >= LOG_LEVEL_DEBUG && TimeCurrent() - lastReportTime > 300) { // Report every 5 mins
            string report;
            GenerateHealthReport(report);
            if(m_Logger != NULL) m_Logger->LogDebug(report);
            lastReportTime = TimeCurrent();
        }
    }
    
    //+------------------------------------------------------------------+
    //| Generate Health Report                                           |
    //+------------------------------------------------------------------+
    void GenerateHealthReport(string& report) {
        report = "--- Broker Health Report ---\n";
        report += StringFormat("Overall Score: %.2f (%s)\n", m_CurrentMetrics.HealthScore, GetHealthStatusString(m_CurrentMetrics.HealthStatus));
        report += StringFormat("Score Trend: %.3f\n", m_CurrentMetrics.HealthTrend);
        report += StringFormat("Slippage Score: %.2f | Latency Score: %.2f\n", m_CurrentMetrics.SlippageScore, m_CurrentMetrics.LatencyScore);
        report += StringFormat("Requote Score: %.2f | Success Rate: %.2f\n", m_CurrentMetrics.RequoteScore, m_CurrentMetrics.SuccessRateScore);
        report += "----------------------------";
    }
    
    //+------------------------------------------------------------------+
    //| Determine Health Status from Score                               |
    //+------------------------------------------------------------------+
    ENUM_HEALTH_STATUS DetermineHealthStatus(double healthScore) {
        if (healthScore >= m_Thresholds.ExcellentThreshold) return HEALTH_EXCELLENT;
        if (healthScore >= m_Thresholds.GoodThreshold) return HEALTH_GOOD;
        if (healthScore >= m_Thresholds.WarningThreshold) return HEALTH_WARNING;
        return HEALTH_CRITICAL;
    }
    
    //+------------------------------------------------------------------+
    //| Get Health Status as a String                                    |
    //+------------------------------------------------------------------+
    string GetHealthStatusString(ENUM_HEALTH_STATUS status) {
        switch(status) {
            case HEALTH_EXCELLENT: return "Excellent";
            case HEALTH_GOOD:      return "Good";
            case HEALTH_WARNING:   return "Warning";
            case HEALTH_CRITICAL:  return "Critical";
            default:               return "Unknown";
        }
    }
    
    //+------------------------------------------------------------------+
    //| Check and Trigger Alerts                                         |
    //+------------------------------------------------------------------+
    void CheckAndTriggerAlerts() {
        ENUM_HEALTH_STATUS currentStatus = m_CurrentMetrics.HealthStatus;
        
        if (currentStatus <= HEALTH_WARNING && !IsAlertCooldownActive()) {
            string alertMessage = StringFormat("Broker Health Alert: Status is now %s (Score: %.2f)", 
                                               GetHealthStatusString(currentStatus), 
                                               m_CurrentMetrics.HealthScore);
            
            if (m_Logger != NULL) {
                if(currentStatus == HEALTH_WARNING)
                    m_Logger->LogWarning(alertMessage);
                else // CRITICAL
                    m_Logger->LogError(alertMessage);
            }
            
            // Send alert to user (e.g., via mobile notification or email)
            SendNotification(alertMessage);
            
            m_LastAlertTime = TimeCurrent();
            m_LastAlertLevel = currentStatus;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Is Alert Cooldown Active                                         |
    //+------------------------------------------------------------------+
    bool IsAlertCooldownActive() {
        if (m_LastAlertTime == 0) return false;
        return (TimeCurrent() - m_LastAlertTime) < (m_AlertCooldownMinutes * 60);
    }
    
    //+------------------------------------------------------------------+
    //| Get Risk Adjustment Factor                                       |
    //+------------------------------------------------------------------+
    double GetRiskAdjustmentFactor() {
        // This is a simple implementation. A more advanced version could use a curve.
        switch(m_CurrentMetrics.HealthStatus) {
            case HEALTH_EXCELLENT:
                return 1.0; // No adjustment
            case HEALTH_GOOD:
                return 0.9; // Slight reduction
            case HEALTH_WARNING:
                return 0.7; // Moderate reduction
            case HEALTH_CRITICAL:
                return 0.5; // Significant reduction
            default:
                return 1.0;
        }
    }
    
    //+------------------------------------------------------------------+
    //| Should Reduce Risk                                               |
    //+------------------------------------------------------------------+
    bool ShouldReduceRisk() {
        return (m_CurrentMetrics.HealthStatus <= HEALTH_WARNING);
    }
    
    //+------------------------------------------------------------------+
    //| Should Increase Spread                                           |
    //+------------------------------------------------------------------+
    bool ShouldIncreaseSpread() {
        // Example logic: if slippage score is poor, assume wider spreads are needed
        return (m_CurrentMetrics.SlippageScore < m_Thresholds.WarningThreshold);
    }
    
    //+------------------------------------------------------------------+
    //| Should Trigger Circuit Breaker                                   |
    //+------------------------------------------------------------------+
    bool ShouldTriggerCircuitBreaker() {
        // Trigger if health is critical or has a strong negative trend
        bool isCritical = (m_CurrentMetrics.HealthStatus == HEALTH_CRITICAL);
        bool isDeterioratingFast = (m_CurrentMetrics.HealthTrend < m_Thresholds.DeterioratingTrend * 1.5);
        
        if(isCritical) {
            if(m_Logger != NULL) m_Logger->LogError("Circuit Breaker Condition: Broker health is CRITICAL.");
            return true;
        }
        if(isDeterioratingFast) {
            if(m_Logger != NULL) m_Logger->LogWarning("Circuit Breaker Condition: Broker health is deteriorating rapidly.");
            return true;
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| Reset                                                            |
    //+------------------------------------------------------------------+
    void Reset() {
        m_CurrentMetrics = BrokerHealthMetrics(); // Reset to defaults
        m_PreviousMetrics = BrokerHealthMetrics();
        m_HistorySize = 0;
        m_LastAlertTime = 0;
        m_LastAlertLevel = HEALTH_EXCELLENT;
        
        // Clear history arrays
        ArrayInitialize(m_HealthHistory, 0.0);
        ArrayInitialize(m_SlippageHistory, 0.0);
        ArrayInitialize(m_LatencyHistory, 0.0);
        
        if (m_Logger != NULL) {
            m_Logger->LogInfo("Broker Health Monitor has been reset.");
        }
    }
    
    //+------------------------------------------------------------------+
    //| Save Metrics to File                                             |
    //+------------------------------------------------------------------+
    void SaveMetricsToFile(const string& filename) {
        // Implementation for persistence
    }
    
    //+------------------------------------------------------------------+
    //| Load Metrics from File                                           |
    //+------------------------------------------------------------------+
    bool LoadMetricsFromFile(const string& filename) {
        // Implementation for persistence
        return true;
    }
    
    //+------------------------------------------------------------------+
    //| Generate Detailed Report                                         |
    //+------------------------------------------------------------------+
    string GenerateDetailedReport() {
        string report = "=== DETAILED BROKER HEALTH REPORT ===\n";
        report += StringFormat("Timestamp: %s\n", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES));
        report += StringFormat("Overall Health Score: %.2f/100\n", m_CurrentMetrics.HealthScore);
        report += StringFormat("Health Status: %s\n", GetHealthStatusString(m_CurrentMetrics.HealthStatus));
        report += StringFormat("Health Trend: %.3f\n", m_CurrentMetrics.HealthTrend);
        report += "\n--- Component Scores ---\n";
        report += StringFormat("Slippage Score: %.2f/100\n", m_CurrentMetrics.SlippageScore);
        report += StringFormat("Latency Score: %.2f/100\n", m_CurrentMetrics.LatencyScore);
        report += StringFormat("Requote Score: %.2f/100\n", m_CurrentMetrics.RequoteScore);
        report += StringFormat("Success Rate Score: %.2f/100\n", m_CurrentMetrics.SuccessRateScore);
        report += "\n--- Risk Recommendations ---\n";
        report += StringFormat("Risk Adjustment Factor: %.2f\n", GetRiskAdjustmentFactor());
        report += StringFormat("Should Reduce Risk: %s\n", ShouldReduceRisk() ? "YES" : "NO");
        report += StringFormat("Should Increase Spread: %s\n", ShouldIncreaseSpread() ? "YES" : "NO");
        report += StringFormat("Circuit Breaker Trigger: %s\n", ShouldTriggerCircuitBreaker() ? "YES" : "NO");
        report += "=====================================\n";
        return report;
    }
    
    //+------------------------------------------------------------------+
    //| Send Notification (placeholder implementation)                   |
    //+------------------------------------------------------------------+
    void SendNotification(const string& message) {
        // Placeholder for notification system
        // Could integrate with mobile alerts, email, etc.
        if(m_Logger != NULL) {
            m_Logger->LogInfo("NOTIFICATION: " + message);
        }
    }
}; // End of CBrokerHealthMonitor class

} // namespace ApexPullback

#endif // BROKERHEALTHMONITOR_MQH_