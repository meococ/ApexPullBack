#ifndef BROKERHEALTHMONITOR_MQH_
#define BROKERHEALTHMONITOR_MQH_

//+------------------------------------------------------------------+
//|                                           BrokerHealthMonitor.mqh |
//|                                    APEX PULLBACK EA v14.0        |
//|                                    Broker Quality Assessment      |
//+------------------------------------------------------------------+

#property copyright "APEX PULLBACK EA v14.0"
#property version   "1.00"
// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "Enums.mqh"
#include "CommonStructs.mqh"      // Core structures, enums, and inputs
#include "Logger.mqh"

namespace ApexPullback {

//+------------------------------------------------------------------+
//| Broker Health Metrics Structure                                   |
//+------------------------------------------------------------------+
struct BrokerHealthMetrics {
    // Core Health Indicators
    double HealthScore;              // Overall health score (0-100)
    double SlippageScore;            // Slippage quality score (0-100)
    double LatencyScore;             // Execution speed score (0-100)
    double RequoteScore;             // Requote frequency score (0-100)
    double SuccessRateScore;         // Execution success score (0-100)
    
    // Trend Analysis
    double HealthTrend;              // Health trend (-1 to +1)
    double SlippageTrend;            // Slippage trend
    double LatencyTrend;             // Latency trend
    
    // Alert Levels
    ENUM_HEALTH_STATUS HealthStatus; // Current health status
    datetime LastUpdate;             // Last metrics update time
    
    // Constructor
    BrokerHealthMetrics() {
        HealthScore = 100.0;
        SlippageScore = 100.0;
        LatencyScore = 100.0;
        RequoteScore = 100.0;
        SuccessRateScore = 100.0;
        HealthTrend = 0.0;
        SlippageTrend = 0.0;
        LatencyTrend = 0.0;
        HealthStatus = HEALTH_EXCELLENT;
        LastUpdate = 0;
    }
};

//+------------------------------------------------------------------+
//| Broker Health Thresholds                                         |
//+------------------------------------------------------------------+
struct BrokerHealthThresholds {
    // Score Thresholds (0-100)
    double ExcellentThreshold;       // Above this = Excellent
    double GoodThreshold;            // Above this = Good
    double WarningThreshold;         // Above this = Warning
    double CriticalThreshold;        // Below this = Critical
    
    // Raw Metric Thresholds
    double MaxAcceptableSlippage;    // Maximum acceptable slippage (pips)
    double MaxAcceptableLatency;     // Maximum acceptable latency (ms)
    double MinSuccessRate;           // Minimum execution success rate (%)
    double MaxRequoteRate;           // Maximum requote rate (%)
    
    // Trend Thresholds
    double DeterioratingTrend;       // Trend below this = deteriorating
    double ImprovingTrend;           // Trend above this = improving
    
        // Constructor with default values
    BrokerHealthThresholds() {
        ExcellentThreshold = 90.0;
        GoodThreshold = 75.0;
        WarningThreshold = 60.0;
        CriticalThreshold = 40.0;
        
        MaxAcceptableSlippage = 1.0;  // 1 pip
        MaxAcceptableLatency = 500.0; // 500ms
        MinSuccessRate = 95.0;        // 95%
        MaxRequoteRate = 5.0;         // 5%
        
        DeterioratingTrend = -0.3;
        ImprovingTrend = 0.3;
    }
};

//+------------------------------------------------------------------+
//| Broker Health Monitor Class                                      |
//+------------------------------------------------------------------+
class CBrokerHealthMonitor : public CObject {
private:
    // Core Components
    CLogger* m_Logger;
    EAContext* m_Context;
    
    // Health Metrics
    BrokerHealthMetrics m_CurrentMetrics;
    BrokerHealthMetrics m_PreviousMetrics;
    BrokerHealthThresholds m_Thresholds;
    
    // Historical Data for Trend Analysis
    double m_HealthHistory[];
    double m_SlippageHistory[];
    double m_LatencyHistory[];
    int m_HistorySize;
    int m_MaxHistorySize;
    
    // Alert Management
    datetime m_LastAlertTime;
    ENUM_HEALTH_STATUS m_LastAlertLevel;
    int m_AlertCooldownMinutes;
    
    // Internal Methods
    double CalculateSlippageScore(double avgSlippage, double maxSlippage);
    double CalculateLatencyScore(double avgLatency, double maxLatency);
    double CalculateRequoteScore(double requoteRate);
    double CalculateSuccessRateScore(double successRate);
    double CalculateOverallHealthScore();
    
    void UpdateTrendAnalysis();
    void UpdateHealthHistory(double healthScore);
    void CheckAndTriggerAlerts();
    
    ENUM_HEALTH_STATUS DetermineHealthStatus(double healthScore);
    string GetHealthStatusString(ENUM_HEALTH_STATUS status);
    
public:
    // Constructor & Destructor
    CBrokerHealthMonitor();
    ~CBrokerHealthMonitor();
    
    // Initialization
    bool Initialize(EAContext* context);
    void SetThresholds(const BrokerHealthThresholds& thresholds);
    
    // Core Functionality
    void UpdateMetrics(double avgSlippage, double maxSlippage, 
                      double avgLatency, double maxLatency,
                      double requoteRate, double successRate);
    
    void AnalyzeBrokerHealth();
    void UpdateWithNewDataPoint(double slippagePips, double executionTimeMs); // V14.0: Thêm phương thức mới
    void GenerateHealthReport(string& report);
    
    // Getters
    BrokerHealthMetrics GetCurrentMetrics() const { return m_CurrentMetrics; }
    double GetHealthScore() const { return m_CurrentMetrics.HealthScore; }
    ENUM_HEALTH_STATUS GetHealthStatus() const { return m_CurrentMetrics.HealthStatus; }
    double GetHealthTrend() const { return m_CurrentMetrics.HealthTrend; }
    
    // Risk Management Integration
    double GetRiskAdjustmentFactor();
    double GetHealthBasedRiskFactor();  // V14.0: Hệ số rủi ro dựa trên sức khỏe broker
    bool ShouldReduceRisk();
    bool ShouldIncreaseSpread();
    bool ShouldTriggerCircuitBreaker();
    
    // Alert Management
    void SetAlertCooldown(int minutes) { m_AlertCooldownMinutes = minutes; }
    bool IsAlertCooldownActive();
    
    // Utility
    void Reset();
    void SaveMetricsToFile(const string& filename);
    bool LoadMetricsFromFile(const string& filename);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CBrokerHealthMonitor::CBrokerHealthMonitor() 
{
    // Initialization is handled in the Initialize() method
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
bool CBrokerHealthMonitor::Initialize(EAContext* context) {
    m_Context = context;
    if (CheckPointer(m_Context) == POINTER_INVALID) {
        printf("CBrokerHealthMonitor::Initialize - EAContext is null");
        return false;
    }

    m_Logger = m_Context->Logger;
    if (CheckPointer(m_Logger) == POINTER_INVALID) {
        printf("CBrokerHealthMonitor::Initialize - CLogger is null");
        // Non-fatal, we can proceed without logging
    }

    // Initialize history arrays
    ArrayResize(m_HealthHistory, m_MaxHistorySize);
    ArrayResize(m_SlippageHistory, m_MaxHistorySize);
    ArrayResize(m_LatencyHistory, m_MaxHistorySize);
    
    ArrayInitialize(m_HealthHistory, 100.0);
    ArrayInitialize(m_SlippageHistory, 0.0);
    ArrayInitialize(m_LatencyHistory, 0.0);
    m_HistorySize = 0;

    if (m_Logger != NULL) {
        m_Logger->LogInfo("Broker Health Monitor Initialized.");
    }

    return true;
}

//+------------------------------------------------------------------+
//| Set Thresholds                                                   |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::SetThresholds(const BrokerHealthThresholds& thresholds) {
    m_Thresholds = thresholds;
    if (m_Logger != NULL) {
        m_Logger->LogInfo("Broker health thresholds updated.");
    }
}

//+------------------------------------------------------------------+
//| Calculate Slippage Score                                         |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateSlippageScore(double avgSlippage, double maxSlippage) {
    // Simple linear score. 0 slippage = 100 score. MaxAcceptableSlippage = 50 score.
    double score = 100.0 - (avgSlippage / m_Thresholds.MaxAcceptableSlippage) * 50.0;
    return MathMax(0.0, MathMin(100.0, score)); // Clamp between 0 and 100
}

//+------------------------------------------------------------------+
//| Calculate Latency Score                                          |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateLatencyScore(double avgLatency, double maxLatency) {
    // Similar linear score for latency.
    double score = 100.0 - (avgLatency / m_Thresholds.MaxAcceptableLatency) * 50.0;
    return MathMax(0.0, MathMin(100.0, score));
}

//+------------------------------------------------------------------+
//| Calculate Requote Score                                          |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateRequoteScore(double requoteRate) {
    double score = 100.0 - (requoteRate / m_Thresholds.MaxRequoteRate) * 100.0;
    return MathMax(0.0, MathMin(100.0, score));
}

//+------------------------------------------------------------------+
//| Calculate Success Rate Score                                     |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateSuccessRateScore(double successRate) {
    // Score is based on how close it is to 100% from the minimum acceptable rate.
    if (successRate < m_Thresholds.MinSuccessRate) return 0;
    double score = ((successRate - m_Thresholds.MinSuccessRate) / (100.0 - m_Thresholds.MinSuccessRate)) * 100.0;
    return MathMax(0.0, MathMin(100.0, score));
}

//+------------------------------------------------------------------+
//| Update Metrics                                                   |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateMetrics(double avgSlippage, double maxSlippage, 
                                          double avgLatency, double maxLatency,
                                          double requoteRate, double successRate) {
    m_PreviousMetrics = m_CurrentMetrics;

    m_CurrentMetrics.SlippageScore = CalculateSlippageScore(avgSlippage, maxSlippage);
    m_CurrentMetrics.LatencyScore = CalculateLatencyScore(avgLatency, maxLatency);
    m_CurrentMetrics.RequoteScore = CalculateRequoteScore(requoteRate);
    m_CurrentMetrics.SuccessRateScore = CalculateSuccessRateScore(successRate);
    m_CurrentMetrics.HealthScore = CalculateOverallHealthScore();
    m_CurrentMetrics.LastUpdate = TimeCurrent();

    UpdateHealthHistory(m_CurrentMetrics.HealthScore);
    UpdateTrendAnalysis();

    m_CurrentMetrics.HealthStatus = DetermineHealthStatus(m_CurrentMetrics.HealthScore);
}

//+------------------------------------------------------------------+
//| Calculate Overall Health Score                                   |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateOverallHealthScore() {
    // Weighted average of the individual scores. Weights can be adjusted.
    double slippageWeight = 0.35;
    double latencyWeight = 0.35;
    double requoteWeight = 0.15;
    double successRateWeight = 0.15;

    double totalScore = (m_CurrentMetrics.SlippageScore * slippageWeight) +
                        (m_CurrentMetrics.LatencyScore * latencyWeight) +
                        (m_CurrentMetrics.RequoteScore * requoteWeight) +
                        (m_CurrentMetrics.SuccessRateScore * successRateWeight);

    return totalScore;
}

//+------------------------------------------------------------------+
//| Update Health History                                            |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateHealthHistory(double healthScore) {
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
void CBrokerHealthMonitor::UpdateTrendAnalysis() {
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
//| Analyze Broker Health (Main coordinating function)               |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::AnalyzeBrokerHealth() {
    // In a real implementation, you would get these values from a TradeManager
    // or by observing trade execution results.
    // For now, we use placeholder values.
    double avgSlippage = 0.2; // example
    double maxSlippage = 0.5; // example
    double avgLatency = 150;  // example
    double maxLatency = 300;  // example
    double requoteRate = 1.0; // example
    double successRate = 99.0;// example

    UpdateMetrics(avgSlippage, maxSlippage, avgLatency, maxLatency, requoteRate, successRate);
    CheckAndTriggerAlerts();

    if (m_Logger != NULL && m_Context != NULL && m_Context->InputLogLevel >= LOG_LEVEL_INFO) {
        string report;
        GenerateHealthReport(report);
        m_Logger->LogInfo(report);
    }
}

//+------------------------------------------------------------------+
//| Generate Health Report                                           |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::GenerateHealthReport(string& report) {
    report = "--- Broker Health Report ---\
";
    report += StringFormat("Overall Score: %.2f (%s)\
", m_CurrentMetrics.HealthScore, GetHealthStatusString(m_CurrentMetrics.HealthStatus));
    report += StringFormat("Score Trend: %.3f\n", m_CurrentMetrics.HealthTrend);
    report += StringFormat("Slippage Score: %.2f | Latency Score: %.2f\n", m_CurrentMetrics.SlippageScore, m_CurrentMetrics.LatencyScore);
    report += StringFormat("Requote Score: %.2f | Success Rate: %.2f\n", m_CurrentMetrics.RequoteScore, m_CurrentMetrics.SuccessRateScore);
    report += "----------------------------";
}

//+------------------------------------------------------------------+
//| Determine Health Status from Score                               |
//+------------------------------------------------------------------+
ENUM_HEALTH_STATUS CBrokerHealthMonitor::DetermineHealthStatus(double healthScore) {
    if (healthScore >= m_Thresholds.ExcellentThreshold) return HEALTH_EXCELLENT;
    if (healthScore >= m_Thresholds.GoodThreshold) return HEALTH_GOOD;
    if (healthScore >= m_Thresholds.WarningThreshold) return HEALTH_WARNING;
    return HEALTH_CRITICAL;
}

//+------------------------------------------------------------------+
//| Get Health Status as a String                                    |
//+------------------------------------------------------------------+
string CBrokerHealthMonitor::GetHealthStatusString(ENUM_HEALTH_STATUS status) {
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
void CBrokerHealthMonitor::CheckAndTriggerAlerts() {
    if (IsAlertCooldownActive()) return;

    ENUM_HEALTH_STATUS currentStatus = m_CurrentMetrics.HealthStatus;
    if (currentStatus <= HEALTH_WARNING && currentStatus < m_LastAlertLevel) {
        string alertMessage = StringFormat("Broker Health Alert: Status downgraded to %s (Score: %.2f)",
                                           GetHealthStatusString(currentStatus), m_CurrentMetrics.HealthScore);
        if (m_Logger != NULL) {
            m_Logger->LogWarning(alertMessage);
        }
        // Potentially send a push notification or email here
        // SendNotification(alertMessage);

        m_LastAlertTime = TimeCurrent();
        m_LastAlertLevel = currentStatus;
    }
}

//+------------------------------------------------------------------+
//| Check if Alert Cooldown is Active                                |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::IsAlertCooldownActive() {
    if (TimeCurrent() - m_LastAlertTime < m_AlertCooldownMinutes * 60) {
        return true;
    }
    return false;
}

//+------------------------------------------------------------------+
//| Get Risk Adjustment Factor                                       |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::GetRiskAdjustmentFactor() {
    switch(m_CurrentMetrics.HealthStatus) {
        case HEALTH_EXCELLENT: return 1.0;  // No adjustment
        case HEALTH_GOOD:      return 0.9;  // Slight reduction
        case HEALTH_WARNING:   return 0.6;  // Moderate reduction
        case HEALTH_CRITICAL:  return 0.3;  // Significant reduction
        default:               return 1.0;
    }
}

//+------------------------------------------------------------------+
//| Get Health-Based Risk Factor (V14.0)                             |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::GetHealthBasedRiskFactor() {
    // More granular adjustment based on the score itself
    if (m_CurrentMetrics.HealthScore > 95.0) return 1.0;
    if (m_CurrentMetrics.HealthScore < 50.0) return 0.25; // Minimum risk factor
    
    // Linear interpolation between 50 and 95
    return 0.25 + (m_CurrentMetrics.HealthScore - 50.0) / (95.0 - 50.0) * 0.75;
}

//+------------------------------------------------------------------+
//| Should Reduce Risk                                               |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldReduceRisk() {
    return m_CurrentMetrics.HealthStatus <= HEALTH_WARNING;
}

//+------------------------------------------------------------------+
//| Should Increase Spread for pending orders                        |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldIncreaseSpread() {
    // If slippage is trending badly, add a buffer to pending orders
    return m_CurrentMetrics.SlippageTrend < m_Thresholds.DeterioratingTrend;
}

//+------------------------------------------------------------------+
//| Should Trigger Circuit Breaker                                   |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldTriggerCircuitBreaker() {
    return m_CurrentMetrics.HealthStatus == HEALTH_CRITICAL;
}

//+------------------------------------------------------------------+
//| Reset Metrics                                                    |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::Reset() {
    m_CurrentMetrics = BrokerHealthMetrics();
    m_PreviousMetrics = BrokerHealthMetrics();
    ArrayInitialize(m_HealthHistory, 100.0);
    m_HistorySize = 0;
    if (m_Logger != NULL) {
        m_Logger->LogInfo("Broker Health Monitor has been reset.");
    }
}

//+------------------------------------------------------------------+
//| Save Metrics to File                                             |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::SaveMetricsToFile(const string& filename) {
    // Implementation for saving metrics to a file (e.g., CSV or binary)
    // This is a placeholder for future implementation.
    if (m_Logger != NULL) {
        m_Logger->LogInfo("SaveMetricsToFile is not yet implemented.");
    }
}

//+------------------------------------------------------------------+
//| Load Metrics from File                                           |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::LoadMetricsFromFile(const string& filename) {
    // Implementation for loading metrics from a file
    // This is a placeholder for future implementation.
    if (m_Logger != NULL) {
        m_Logger->LogInfo("LoadMetricsFromFile is not yet implemented.");
    }
    return false;
}

} // namespace ApexPullback
#endif // BROKERHEALTHMONITOR_MQH_


//+------------------------------------------------------------------+
//| Initialize                                                       |

#endif // BROKERHEALTHMONITOR_MQH_
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::Initialize(EAContext* context) {
    if (context == NULL) {
        Print("[BrokerHealthMonitor] ERROR: Context is NULL");
        return false;
    }
    
    m_Context = context;
    m_Logger = context->Logger;
    
    if (m_Logger != NULL) {
        m_Logger->LogInfo("BrokerHealthMonitor initialized successfully");
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Set Custom Thresholds                                           |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::SetThresholds(const BrokerHealthThresholds& thresholds) {
    m_Thresholds = thresholds;
    
    if (m_Logger != NULL) {
        m_Logger->LogInfo("BrokerHealthMonitor thresholds updated");
    }
}

//+------------------------------------------------------------------+
//| Update Metrics from Performance Tracker                         |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateMetrics(double avgSlippage, double maxSlippage, 
                                        double avgLatency, double maxLatency,
                                        double requoteRate, double successRate) {
    // Store previous metrics
    m_PreviousMetrics = m_CurrentMetrics;
    
    // Calculate individual scores
    m_CurrentMetrics.SlippageScore = CalculateSlippageScore(avgSlippage, maxSlippage);
    m_CurrentMetrics.LatencyScore = CalculateLatencyScore(avgLatency, maxLatency);
    m_CurrentMetrics.RequoteScore = CalculateRequoteScore(requoteRate);
    m_CurrentMetrics.SuccessRateScore = CalculateSuccessRateScore(successRate);
    
    // Calculate overall health score
    m_CurrentMetrics.HealthScore = CalculateOverallHealthScore();
    
    // Update trend analysis
    UpdateTrendAnalysis();
    
    // Update health history
    UpdateHealthHistory(m_CurrentMetrics.HealthScore);
    
    // Determine health status
    m_CurrentMetrics.HealthStatus = DetermineHealthStatus(m_CurrentMetrics.HealthScore);
    
    // Update timestamp
    m_CurrentMetrics.LastUpdate = TimeCurrent();
    
    // Check for alerts
    CheckAndTriggerAlerts();
    
    if (m_Logger != NULL) {
        string logMsg = StringFormat("Health Score: %.1f, Status: %s, Trend: %.3f",
                                   m_CurrentMetrics.HealthScore,
                                   GetHealthStatusString(m_CurrentMetrics.HealthStatus),
                                   m_CurrentMetrics.HealthTrend);
        m_Logger->LogInfo(logMsg);
    }
}

//+------------------------------------------------------------------+
//| Calculate Slippage Score                                         |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateSlippageScore(double avgSlippage, double maxSlippage) {
    // Convert slippage to pips (assuming 5-digit broker)
    double avgSlippagePips = avgSlippage * 100000;
    double maxSlippagePips = maxSlippage * 100000;
    
    // Score based on average slippage (weighted 70%)
    double avgScore = 100.0;
    if (avgSlippagePips > 0) {
        avgScore = MathMax(0.0, 100.0 - (avgSlippagePips / m_Thresholds.MaxAcceptableSlippage) * 50.0);
    }
    
    // Score based on max slippage (weighted 30%)
    double maxScore = 100.0;
    if (maxSlippagePips > 0) {
        maxScore = MathMax(0.0, 100.0 - (maxSlippagePips / (m_Thresholds.MaxAcceptableSlippage * 3.0)) * 50.0);
    }
    
    return (avgScore * 0.7 + maxScore * 0.3);
}

//+------------------------------------------------------------------+
//| Calculate Latency Score                                          |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateLatencyScore(double avgLatency, double maxLatency) {
    // Score based on average latency (weighted 70%)
    double avgScore = 100.0;
    if (avgLatency > 0) {
        avgScore = MathMax(0.0, 100.0 - (avgLatency / m_Thresholds.MaxAcceptableLatency) * 50.0);
    }
    
    // Score based on max latency (weighted 30%)
    double maxScore = 100.0;
    if (maxLatency > 0) {
        maxScore = MathMax(0.0, 100.0 - (maxLatency / (m_Thresholds.MaxAcceptableLatency * 2.0)) * 50.0);
    }
    
    return (avgScore * 0.7 + maxScore * 0.3);
}

//+------------------------------------------------------------------+
//| Calculate Requote Score                                          |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateRequoteScore(double requoteRate) {
    if (requoteRate <= 0) return 100.0;
    
    // Linear decrease from 100 to 0 as requote rate increases
    return MathMax(0.0, 100.0 - (requoteRate / m_Thresholds.MaxRequoteRate) * 100.0);
}

//+------------------------------------------------------------------+
//| Calculate Success Rate Score                                     |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateSuccessRateScore(double successRate) {
    if (successRate >= 100.0) return 100.0;
    
    // Linear mapping: MinSuccessRate = 50 points, 100% = 100 points
    double minScore = 50.0;
    double range = 100.0 - minScore;
    double rateRange = 100.0 - m_Thresholds.MinSuccessRate;
    
    if (successRate < m_Thresholds.MinSuccessRate) {
        return MathMax(0.0, minScore * (successRate / m_Thresholds.MinSuccessRate));
    }
    
    return minScore + range * ((successRate - m_Thresholds.MinSuccessRate) / rateRange);
}

//+------------------------------------------------------------------+
//| Calculate Overall Health Score                                   |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateOverallHealthScore() {
    // Weighted average of all scores
    double weights[] = {0.3, 0.3, 0.2, 0.2}; // Slippage, Latency, Success Rate, Requotes
    double scores[] = {
        m_CurrentMetrics.SlippageScore,
        m_CurrentMetrics.LatencyScore,
        m_CurrentMetrics.SuccessRateScore,
        m_CurrentMetrics.RequoteScore
    };
    
    double weightedSum = 0.0;
    for (int i = 0; i < 4; i++) {
        weightedSum += scores[i] * weights[i];
    }
    
    return MathMax(0.0, MathMin(100.0, weightedSum));
}

//+------------------------------------------------------------------+
//| Update Trend Analysis                                            |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateTrendAnalysis() {
    if (m_HistorySize < 5) {
        m_CurrentMetrics.HealthTrend = 0.0;
        return;
    }
    
    // Calculate trend using linear regression on last 10 points
    int lookback = MathMin(10, m_HistorySize);
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    
    for (int i = 0; i < lookback; i++) {
        int index = (m_HistorySize - lookback + i) % m_MaxHistorySize;
        double x = i;
        double y = m_HealthHistory[index];
        
        sumX += x;
        sumY += y;
        sumXY += x * y;
        sumX2 += x * x;
    }
    
    double slope = (lookback * sumXY - sumX * sumY) / (lookback * sumX2 - sumX * sumX);
    
    // Normalize slope to -1 to +1 range
    m_CurrentMetrics.HealthTrend = MathMax(-1.0, MathMin(1.0, slope / 10.0));
}

//+------------------------------------------------------------------+
//| Update Health History                                            |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateHealthHistory(double healthScore) {
    int index = m_HistorySize % m_MaxHistorySize;
    m_HealthHistory[index] = healthScore;
    
    if (m_HistorySize < m_MaxHistorySize) {
        m_HistorySize++;
    }
}

//+------------------------------------------------------------------+
//| Determine Health Status                                          |
//+------------------------------------------------------------------+
ENUM_HEALTH_STATUS CBrokerHealthMonitor::DetermineHealthStatus(double healthScore) {
    if (healthScore >= m_Thresholds.ExcellentThreshold) return HEALTH_EXCELLENT;
    if (healthScore >= m_Thresholds.GoodThreshold) return HEALTH_GOOD;
    if (healthScore >= m_Thresholds.WarningThreshold) return HEALTH_WARNING;
    if (healthScore >= m_Thresholds.CriticalThreshold) return HEALTH_CRITICAL;
    return HEALTH_CRITICAL;
}

//+------------------------------------------------------------------+
//| Get Health Status String                                         |
//+------------------------------------------------------------------+
string CBrokerHealthMonitor::GetHealthStatusString(ENUM_HEALTH_STATUS status) {
    switch(status) {
        case HEALTH_EXCELLENT: return "EXCELLENT";
        case HEALTH_GOOD: return "GOOD";
        case HEALTH_WARNING: return "WARNING";
        case HEALTH_CRITICAL: return "CRITICAL";
        default: return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Check and Trigger Alerts                                        |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::CheckAndTriggerAlerts() {
    // Check if we need to send an alert
    bool shouldAlert = false;
    
    // Alert if status changed to worse
    if (m_CurrentMetrics.HealthStatus > m_LastAlertLevel) {
        shouldAlert = true;
    }
    
    // Alert if health score dropped significantly
    if (m_CurrentMetrics.HealthScore < m_PreviousMetrics.HealthScore - 20.0) {
        shouldAlert = true;
    }
    
    // Alert if trend is strongly negative
    if (m_CurrentMetrics.HealthTrend < m_Thresholds.DeterioratingTrend) {
        shouldAlert = true;
    }
    
    // Check cooldown
    if (shouldAlert && !IsAlertCooldownActive()) {
        string alertMsg = StringFormat("BROKER HEALTH ALERT: Status=%s, Score=%.1f, Trend=%.3f",
                                     GetHealthStatusString(m_CurrentMetrics.HealthStatus),
                                     m_CurrentMetrics.HealthScore,
                                     m_CurrentMetrics.HealthTrend);
        
        if (m_Logger != NULL) {
            m_Logger->LogWarning(alertMsg);
        }
        
        // Send notification
        SendNotification(alertMsg);
        
        m_LastAlertTime = TimeCurrent();
        m_LastAlertLevel = m_CurrentMetrics.HealthStatus;
    }
}

//+------------------------------------------------------------------+
//| Check Alert Cooldown                                            |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::IsAlertCooldownActive() {
    return (TimeCurrent() - m_LastAlertTime) < (m_AlertCooldownMinutes * 60);
}

//+------------------------------------------------------------------+
//| Get Risk Adjustment Factor                                       |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::GetRiskAdjustmentFactor() {
    // Return factor between 0.1 and 1.0 based on health score
    double factor = m_CurrentMetrics.HealthScore / 100.0;
    
    // Apply more aggressive reduction for poor health
    if (m_CurrentMetrics.HealthStatus == HEALTH_CRITICAL) {
        factor *= 0.3;  // Reduce to 30% of normal risk
    } else if (m_CurrentMetrics.HealthStatus == HEALTH_WARNING) {
        factor *= 0.6;  // Reduce to 60% of normal risk
    }
    
    return MathMax(0.1, MathMin(1.0, factor));
}

//+------------------------------------------------------------------+
//| Should Reduce Risk                                               |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldReduceRisk() {
    return (m_CurrentMetrics.HealthStatus >= HEALTH_WARNING) ||
           (m_CurrentMetrics.HealthTrend < m_Thresholds.DeterioratingTrend);
}

//+------------------------------------------------------------------+
//| Should Increase Spread                                           |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldIncreaseSpread() {
    return (m_CurrentMetrics.SlippageScore < 60.0) ||
           (m_CurrentMetrics.RequoteScore < 70.0);
}

//+------------------------------------------------------------------+
//| Should Trigger Circuit Breaker                                   |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldTriggerCircuitBreaker() {
    return (m_CurrentMetrics.HealthStatus == HEALTH_CRITICAL) &&
           (m_CurrentMetrics.HealthTrend < -0.5);
}

//+------------------------------------------------------------------+
//| Get Health Based Risk Factor - V14.0 Enhancement                |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::GetHealthBasedRiskFactor() {
    // Kiểm tra slippage trung bình
    if (m_Context != NULL && m_Context->AverageSlippagePips > 2.0) {
        if (m_Logger != NULL) {
            m_Logger->LogWarning(StringFormat("High slippage detected: %.2f pips, reducing risk to 70%%", 
                                            m_Context->AverageSlippagePips));
        }
        return 0.7;  // Giảm 30% rủi ro khi slippage cao
    }
    
    // Kiểm tra độ trễ thực thi
    if (m_Context != NULL && m_Context->AverageExecutionMs > 500.0) {
        if (m_Logger != NULL) {
            m_Logger->LogWarning(StringFormat("High execution latency: %.0f ms, reducing risk to 80%%", 
                                            m_Context->AverageExecutionMs));
        }
        return 0.8;  // Giảm 20% rủi ro khi độ trễ cao
    }
    
    // Kiểm tra tổng thể health status
    switch(m_CurrentMetrics.HealthStatus) {
        case HEALTH_CRITICAL:
            if (m_Logger != NULL) {
                m_Logger->LogCritical("Broker health CRITICAL - reducing risk to 50%");
            }
            return 0.5;  // Giảm 50% rủi ro khi broker trong tình trạng nghiêm trọng
            
        case HEALTH_WARNING:
            if (m_Logger != NULL) {
                m_Logger->LogWarning("Broker health WARNING - reducing risk to 75%");
            }
            return 0.75; // Giảm 25% rủi ro khi broker có cảnh báo
            
        case HEALTH_GOOD:
        case HEALTH_EXCELLENT:
        default:
            return 1.0;  // Không điều chỉnh rủi ro khi broker hoạt động tốt
    }
}

//+------------------------------------------------------------------+
//| Generate Health Report                                           |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::GenerateHealthReport(string& report) {
    report = "\n=== BROKER HEALTH REPORT ===\n";
    report += StringFormat("Overall Health Score: %.1f/100\n", m_CurrentMetrics.HealthScore);
    report += StringFormat("Health Status: %s\n", GetHealthStatusString(m_CurrentMetrics.HealthStatus));
    report += StringFormat("Health Trend: %.3f\n", m_CurrentMetrics.HealthTrend);
    report += "\n--- Component Scores ---\n";
    report += StringFormat("Slippage Score: %.1f/100\n", m_CurrentMetrics.SlippageScore);
    report += StringFormat("Latency Score: %.1f/100\n", m_CurrentMetrics.LatencyScore);
    report += StringFormat("Success Rate Score: %.1f/100\n", m_CurrentMetrics.SuccessRateScore);
    report += StringFormat("Requote Score: %.1f/100\n", m_CurrentMetrics.RequoteScore);
    report += "\n--- Risk Management ---\n";
    report += StringFormat("Risk Adjustment Factor: %.2f\n", GetRiskAdjustmentFactor());
    report += StringFormat("Should Reduce Risk: %s\n", ShouldReduceRisk() ? "YES" : "NO");
    report += StringFormat("Should Increase Spread: %s\n", ShouldIncreaseSpread() ? "YES" : "NO");
    report += StringFormat("Circuit Breaker Trigger: %s\n", ShouldTriggerCircuitBreaker() ? "YES" : "NO");
    report += StringFormat("\nLast Update: %s\n", TimeToString(m_CurrentMetrics.LastUpdate));
}

//+------------------------------------------------------------------+
//| Reset                                                            |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::Reset() {
    m_CurrentMetrics = BrokerHealthMetrics();
    m_PreviousMetrics = BrokerHealthMetrics();
    m_HistorySize = 0;
    m_LastAlertTime = 0;
    m_LastAlertLevel = HEALTH_EXCELLENT;
    
    ArrayInitialize(m_HealthHistory, 100.0);
    ArrayInitialize(m_SlippageHistory, 0.0);
    ArrayInitialize(m_LatencyHistory, 0.0);
    
    if (m_Logger != NULL) {
        m_Logger->LogInfo("BrokerHealthMonitor reset completed");
    }
}

//+------------------------------------------------------------------+
//| Tính toán điểm sức khỏe tổng thể                                |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateOverallHealthScore()
  {
   double slippage_score = CalculateSlippageScore();
   double latency_score = CalculateLatencyScore();
   double execution_score = CalculateExecutionScore();
   double spread_score = CalculateSpreadScore();
   double connection_score = CalculateConnectionScore();
   
   // Trọng số cho từng yếu tố
   double weights[] = {0.25, 0.20, 0.25, 0.15, 0.15}; // Slippage, Latency, Execution, Spread, Connection
   double scores[] = {slippage_score, latency_score, execution_score, spread_score, connection_score};
   
   double weighted_score = 0.0;
   for(int i = 0; i < 5; i++)
     {
      weighted_score += weights[i] * scores[i];
     }
   
   // Lưu vào lịch sử
   if(ArraySize(m_HealthScoreHistory) >= 100)
     {
      ArrayCopy(m_HealthScoreHistory, m_HealthScoreHistory, 0, 1, 99);
      m_HealthScoreHistory[99] = weighted_score;
     }
   else
     {
      int size = ArraySize(m_HealthScoreHistory);
      ArrayResize(m_HealthScoreHistory, size + 1);
      m_HealthScoreHistory[size] = weighted_score;
     }
   
   return weighted_score;
  }

//+------------------------------------------------------------------+
//| Tính toán điểm execution                                        |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateExecutionScore()
  {
   if(m_Metrics.TotalTrades == 0) return 100.0;
   
   double rejection_rate = (double)m_Metrics.OrderRejections / m_Metrics.TotalTrades;
   double requote_rate = (double)m_Metrics.Requotes / m_Metrics.TotalTrades;
   
   // Điểm dựa trên tỷ lệ từ chối và requote
   double score = 100.0;
   score -= (rejection_rate * 100.0 * 2.0);  // Penalty x2 cho rejection
   score -= (requote_rate * 100.0 * 1.5);   // Penalty x1.5 cho requote
   
   return MathMax(0.0, MathMin(100.0, score));
  }

//+------------------------------------------------------------------+
//| Tính toán điểm spread                                           |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateSpreadScore()
  {
   if(m_Metrics.AvgSpread <= 0) return 100.0;
   
   // So sánh với threshold
   double spread_ratio = m_Metrics.AvgSpread / m_Thresholds.MaxSpread;
   
   double score = 100.0;
   if(spread_ratio > 1.0)
     {
      score = 100.0 / spread_ratio; // Giảm điểm khi spread vượt threshold
     }
   
   return MathMax(0.0, MathMin(100.0, score));
  }

//+------------------------------------------------------------------+
//| Tính toán điểm connection                                       |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::CalculateConnectionScore()
  {
   if(m_Metrics.TotalTrades == 0) return 100.0;
   
   double disconnection_rate = (double)m_Metrics.Disconnections / m_Metrics.TotalTrades;
   
   double score = 100.0 - (disconnection_rate * 100.0 * 3.0); // Penalty x3 cho disconnection
   
   return MathMax(0.0, MathMin(100.0, score));
  }

//+------------------------------------------------------------------+
//| Phân tích xu hướng sức khỏe                                     |
//+------------------------------------------------------------------+
string CBrokerHealthMonitor::AnalyzeHealthTrend()
  {
   int history_size = ArraySize(m_HealthScoreHistory);
   if(history_size < 10) return "Chưa đủ dữ liệu để phân tích xu hướng";
   
   // Tính xu hướng 10 điểm gần nhất
   double recent_avg = 0.0;
   double older_avg = 0.0;
   
   int recent_count = MathMin(5, history_size);
   int older_count = MathMin(5, history_size - recent_count);
   
   // Tính trung bình gần đây
   for(int i = history_size - recent_count; i < history_size; i++)
     {
      recent_avg += m_HealthScoreHistory[i];
     }
   recent_avg /= recent_count;
   
   // Tính trung bình cũ hơn
   for(int i = history_size - recent_count - older_count; i < history_size - recent_count; i++)
     {
      older_avg += m_HealthScoreHistory[i];
     }
   older_avg /= older_count;
   
   double trend = recent_avg - older_avg;
   
   if(trend > 5.0)
      return "Xu hướng CẢI THIỆN mạnh (+" + DoubleToString(trend, 1) + ")";
   else if(trend > 2.0)
      return "Xu hướng cải thiện nhẹ (+" + DoubleToString(trend, 1) + ")";
   else if(trend < -5.0)
      return "Xu hướng XẤU ĐI mạnh (" + DoubleToString(trend, 1) + ")";
   else if(trend < -2.0)
      return "Xu hướng xấu đi nhẹ (" + DoubleToString(trend, 1) + ")";
   else
      return "Xu hướng ổn định (" + DoubleToString(trend, 1) + ")";
  }

//+------------------------------------------------------------------+
//| Tạo cảnh báo dựa trên health score                              |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::GenerateHealthAlert(double health_score)
  {
   string alert_message = "";
   ENUM_BROKER_HEALTH_LEVEL level = HEALTH_EXCELLENT;
   
   if(health_score >= 90.0)
     {
      level = HEALTH_EXCELLENT;
      alert_message = "Broker hoạt động xuất sắc";
     }
   else if(health_score >= 75.0)
     {
      level = HEALTH_GOOD;
      alert_message = "Broker hoạt động tốt";
     }
   else if(health_score >= 60.0)
     {
      level = HEALTH_FAIR;
      alert_message = "Broker hoạt động trung bình - Cần theo dõi";
     }
   else if(health_score >= 40.0)
     {
      level = HEALTH_POOR;
      alert_message = "CẢNH BÁO: Broker hoạt động kém - Giảm rủi ro";
     }
   else
     {
      level = HEALTH_CRITICAL;
      alert_message = "NGUY HIỂM: Broker hoạt động rất kém - Dừng giao dịch";
     }
   
   // Log cảnh báo
   if(m_Logger != NULL)
     {
      if(level >= HEALTH_POOR)
        {
         m_Logger->LogWarning("BrokerHealth: " + alert_message + " (Score: " + 
                             DoubleToString(health_score, 1) + ")");
        }
      else
        {
         m_Logger->LogInfo("BrokerHealth: " + alert_message + " (Score: " + 
                          DoubleToString(health_score, 1) + ")");
        }
     }
   
   // Lưu alert vào lịch sử
   BrokerHealthAlert alert;
   alert.Timestamp = TimeCurrent();
   alert.HealthScore = health_score;
   alert.Level = level;
   alert.Message = alert_message;
   alert.IsActive = (level >= HEALTH_POOR);
   
   // Thêm vào mảng alerts (giới hạn 50 alerts)
   if(ArraySize(m_RecentAlerts) >= 50)
     {
      ArrayCopy(m_RecentAlerts, m_RecentAlerts, 0, 1, 49);
      m_RecentAlerts[49] = alert;
     }
   else
     {
      int size = ArraySize(m_RecentAlerts);
      ArrayResize(m_RecentAlerts, size + 1);
      m_RecentAlerts[size] = alert;
     }
  }

//+------------------------------------------------------------------+
//| Tính toán hệ số điều chỉnh rủi ro                               |
//+------------------------------------------------------------------+
double CBrokerHealthMonitor::GetRiskAdjustmentFactor()
  {
   double health_score = CalculateOverallHealthScore();
   
   if(health_score >= 90.0)
      return 1.0;      // Không điều chỉnh
   else if(health_score >= 75.0)
      return 0.9;      // Giảm 10%
   else if(health_score >= 60.0)
      return 0.75;     // Giảm 25%
   else if(health_score >= 40.0)
      return 0.5;      // Giảm 50%
   else
      return 0.0;      // Dừng giao dịch
  }

//+------------------------------------------------------------------+
//| Kiểm tra có nên giảm rủi ro không                               |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldReduceRisk()
  {
   double health_score = CalculateOverallHealthScore();
   return (health_score < 75.0);
  }

//+------------------------------------------------------------------+
//| Kiểm tra có nên dừng giao dịch không                            |
//+------------------------------------------------------------------+
bool CBrokerHealthMonitor::ShouldStopTrading()
  {
   double health_score = CalculateOverallHealthScore();
   return (health_score < 40.0);
  }

//+------------------------------------------------------------------+
//| V14.0: Nhận dữ liệu mới từ RiskManager                          |
//+------------------------------------------------------------------+
void CBrokerHealthMonitor::UpdateWithNewDataPoint(double slippagePips, double executionTimeMs)
{
    if (CheckPointer(m_Logger) != POINTER_INVALID) {
        m_Logger->LogInfo(StringFormat("BrokerHealthMonitor: Received new data point. Slippage: %.2f pips, Latency: %.1f ms", slippagePips, executionTimeMs));
    }

    // --- Cập nhật Lịch sử Dữ liệu --- 
    // Trong một hệ thống thực tế, bạn sẽ cập nhật các giá trị trung bình động (EMA)
    // hoặc thêm vào một bộ đệm để xử lý hàng loạt.
    // Ví dụ, cập nhật trực tiếp vào cấu trúc metrics:
    m_Metrics.TotalTrades++;
    m_Metrics.TotalSlippage += slippagePips;
    m_Metrics.AvgSlippage = m_Metrics.TotalSlippage / m_Metrics.TotalTrades;
    
    m_Metrics.TotalLatency += executionTimeMs;
    m_Metrics.AvgLatency = m_Metrics.TotalLatency / m_Metrics.TotalTrades;

    // --- Kích hoạt Phân tích lại --- 
    // Sau khi cập nhật dữ liệu, chúng ta có thể tính toán lại điểm số tổng thể
    // và tạo cảnh báo nếu cần.
    double new_score = CalculateOverallHealthScore();
    GenerateHealthAlert(new_score);
    
    // Cập nhật lịch sử điểm số
    int history_size = ArraySize(m_HealthScoreHistory);
    if(history_size >= 100) // Giới hạn lịch sử
    {
        ArrayCopy(m_HealthScoreHistory, m_HealthScoreHistory, 0, 1, 99);
        m_HealthScoreHistory[99] = new_score;
    }
    else
    {
        ArrayResize(m_HealthScoreHistory, history_size + 1);
        m_HealthScoreHistory[history_size] = new_score;
    }
}

//+------------------------------------------------------------------+
//| Tạo báo cáo chi tiết                                            |
//+------------------------------------------------------------------+
string CBrokerHealthMonitor::GenerateDetailedReport()
  {
   double overall_score = CalculateOverallHealthScore();
   
   string report = "\n=== BÁO CÁO SỨC KHỎE BROKER ===\n";
   report += "Thời gian: " + TimeToString(TimeCurrent()) + "\n";
   report += "Điểm tổng thể: " + DoubleToString(overall_score, 1) + "/100\n\n";
   
   // Chi tiết từng thành phần
   report += "CHI TIẾT ĐÁNH GIÁ:\n";
   report += "- Slippage: " + DoubleToString(CalculateSlippageScore(), 1) + "/100\n";
   report += "- Latency: " + DoubleToString(CalculateLatencyScore(), 1) + "/100\n";
   report += "- Execution: " + DoubleToString(CalculateExecutionScore(), 1) + "/100\n";
   report += "- Spread: " + DoubleToString(CalculateSpreadScore(), 1) + "/100\n";
   report += "- Connection: " + DoubleToString(CalculateConnectionScore(), 1) + "/100\n\n";
   
   // Thống kê thô
   report += "THỐNG KÊ THÔ:\n";
   report += "- Tổng lệnh: " + IntegerToString(m_Metrics.TotalTrades) + "\n";
   report += "- Slippage TB: " + DoubleToString(m_Metrics.AvgSlippage, 2) + " pips\n";
   report += "- Latency TB: " + DoubleToString(m_Metrics.AvgLatency, 1) + " ms\n";
   report += "- Spread TB: " + DoubleToString(m_Metrics.AvgSpread, 2) + " pips\n";
   report += "- Từ chối: " + IntegerToString(m_Metrics.OrderRejections) + "\n";
   report += "- Requotes: " + IntegerToString(m_Metrics.Requotes) + "\n";
   report += "- Mất kết nối: " + IntegerToString(m_Metrics.Disconnections) + "\n\n";
   
   // Xu hướng
   report += "XU HƯỚNG: " + AnalyzeHealthTrend() + "\n\n";
   
   // Khuyến nghị
   report += "KHUYẾN NGHỊ:\n";
   if(overall_score >= 90.0)
      report += "- Broker hoạt động xuất sắc, duy trì chiến lược hiện tại\n";
   else if(overall_score >= 75.0)
      report += "- Broker hoạt động tốt, có thể tăng nhẹ rủi ro\n";
   else if(overall_score >= 60.0)
      report += "- Theo dõi chặt chẽ, cân nhắc giảm 25% rủi ro\n";
   else if(overall_score >= 40.0)
      report += "- GIẢM 50% rủi ro, tăng cường monitoring\n";
   else
      report += "- DỪNG giao dịch mới, kiểm tra kết nối broker\n";
   
   report += "\n=== KẾT THÚC BÁO CÁO ===\n";
   
   return report;
  }

} // namespace ApexPullback