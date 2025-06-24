#ifndef ERRORHANDLER_MQH_
#define ERRORHANDLER_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback {

class CErrorHandler 
{
private:
    EAContext* m_pContext;  // Keep as pointer for now to avoid major refactoring // Pointer to the global context
    bool       m_IsInitialized;

public:
    CErrorHandler() : m_pContext(NULL), m_IsInitialized(false) {}
    ~CErrorHandler() {}

    void Initialize(EAContext& context);
    bool IsInitialized() const { return m_IsInitialized; }

    void HandleError(const int error_code, const string& function_name, const string& message, bool trip_circuit_breaker = false);
};

//+------------------------------------------------------------------+
//| Initializes the Error Handler                                    |
//+------------------------------------------------------------------+
void CErrorHandler::Initialize(EAContext& context)
{
    m_pContext = &context;
    m_IsInitialized = true;
}

// Implementation of HandleError
void CErrorHandler::HandleError(const int error_code, const string& function_name, const string& message, bool trip_circuit_breaker = false) 
{
    if (!m_IsInitialized || m_pContext == NULL)
    {
        Print("CRITICAL: HandleError called before ErrorHandler was initialized.");
        return;
    }

    string error_message = StringFormat("ERROR: Code[%d] in '%s'. Message: %s", error_code, function_name, message);

    // Log to file if the logger is available
    if (m_pContext.pLogger != NULL && m_pContext.pLogger->IsInitialized()) 
    {
        m_pContext.pLogger->LogError(error_message, false); // Don't include stack trace by default here
    }
    else
    {
        // Fallback to Print if logger is not ready
        Print(error_message);
    }

    // Optional: Trigger a circuit breaker for critical errors
    if (trip_circuit_breaker && m_pContext.pCircuitBreaker != NULL) 
    {
        m_pContext.pCircuitBreaker->Trip(error_message);
    }
}

} // namespace ApexPullback

#endif // ERRORHANDLER_MQH_