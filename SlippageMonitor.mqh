#ifndef SLIPPAGEMONITOR_MQH_
#define SLIPPAGEMONITOR_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback {

class CSlippageMonitor {
private:
    EAContext* m_context;
    double     m_slippage_history[];
    int        m_history_count;
    int        m_max_history_size;
    double     m_total_slippage;

public:
    CSlippageMonitor(EAContext* context) : m_context(context), 
                                           m_history_count(0),
                                           m_max_history_size(100), // Default size, can be configurable
                                           m_total_slippage(0.0) {
        ArrayResize(m_slippage_history, m_max_history_size);
    }

    ~CSlippageMonitor() {}

    bool Initialize() {
        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "CSlippageMonitor initialized.");
        return true;
    }

    void RecordSlippage(const double slippage_points) {
        if (m_history_count < m_max_history_size) {
            m_slippage_history[m_history_count] = slippage_points;
            m_history_count++;
        } else {
            // Shift history to make space for the new value
            for (int i = 0; i < m_max_history_size - 1; i++) {
                m_slippage_history[i] = m_slippage_history[i + 1];
            }
            m_slippage_history[m_max_history_size - 1] = slippage_points;
        }
        m_total_slippage += slippage_points;
    }

    double GetAverageSlippage() const {
        if (m_history_count == 0) return 0.0;
        return m_total_slippage / m_history_count;
    }

    double GetMaxSlippage() const {
        if (m_history_count == 0) return 0.0;
        return ArrayMaximum(m_slippage_history, 0, m_history_count);
    }

    void Reset() {
        m_history_count = 0;
        m_total_slippage = 0.0;
        ArrayInitialize(m_slippage_history, 0.0);
        if(m_context.pLogger) m_context.pLogger->Log(ALERT_LEVEL_INFO, "SlippageMonitor reset.");
    }
};

} // namespace ApexPullback

#endif // SLIPPAGEMONITOR_MQH_