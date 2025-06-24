#ifndef PARAMETERSTORE_MQH_
#define PARAMETERSTORE_MQH_

#include "CommonStructs.mqh"

namespace ApexPullback {

class CParameterStore 
{
private:
    EAContext* m_pContext;      // Pointer to the global context
    bool       m_IsInitialized;

public:
    CParameterStore() : m_pContext(NULL), m_IsInitialized(false) {}
    ~CParameterStore() {}

    bool Initialize(EAContext* pContext);
    bool IsInitialized() const { return m_IsInitialized; }

private:
    void LoadAllParameters();
};

//+------------------------------------------------------------------+
//| Initializes the Parameter Store                                  |
//+------------------------------------------------------------------+
bool CParameterStore::Initialize(EAContext* pContext)
{
    m_pContext = pContext;
    if (m_pContext == NULL)
    {
        // Cannot use logger here as it might not be initialized
        Print("FATAL: CParameterStore received a NULL context during initialization.");
        return false;
    }

    LoadAllParameters();
    
    if(m_pContext->pLogger) m_pContext->pLogger->Log(LOG_INFO, "CParameterStore initialized and parameters loaded.");
    
    m_IsInitialized = true;
    return true;
}

    // This function centralizes the mapping from EA inputs to the operational parameters
    void LoadAllParameters() 
    {
        if (!m_pContext) return;

        // --- Copy all parameters from m_pContext.Inputs to m_pContext.Params ---
        // This creates a mutable copy of the parameters that can be changed during optimization
        // or by other EA logic without affecting the original input settings.
        m_pContext->Params = m_pContext->Inputs;
        
        if(m_pContext->pLogger) m_pContext->pLogger->Log(LOG_DEBUG, "All operational parameters loaded from initial Inputs.");
    }
};

} // namespace ApexPullback

#endif // PARAMETERSTORE_MQH_