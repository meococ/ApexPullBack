//+------------------------------------------------------------------+
//|                 TradeManager.mqh - APEX Pullback EA v14.0        |
//|           Author: APEX Trading Team | Date: 2024-07-17           |
//|      Description: Quản lý việc thực thi giao dịch, bao gồm       |
//|        mở, đóng, và sửa đổi lệnh, sử dụng lớp CTrade của MQL5.    |
//+------------------------------------------------------------------+
#ifndef TRADEMANAGER_MQH_
#define TRADEMANAGER_MQH_

#include <Trade\Trade.mqh>   // For CTrade class
#include "CommonStructs.mqh" // For EAContext access

namespace ApexPullback
{

//+------------------------------------------------------------------+
//| Manages all trading EXECUTION.                                   |
//| This class does not make decisions. It only executes them.       |
//+------------------------------------------------------------------+
class CTradeManager
{
private:
    // --- Core Components ---
    EAContext*          m_context;          // Pointer to the global context

    // --- MQL5 Trading Object ---
    CTrade              m_trade;            // MQL5's trading class

    // --- Basic Parameters ---
    string              m_symbol;           // The symbol for trading
    long                m_magic_number;     // The magic number for trades
    int                 m_slippage;         // Allowed slippage in points
    int                 m_max_spread_points; // Maximum allowed spread in points

public:
    // --- Constructor & Destructor ---
                        CTradeManager();
                       ~CTradeManager(void);

    // --- Initialization ---
    bool                Initialize(EAContext* pContext);
    bool                Initialize();

    // --- Core Trading Actions ---
    bool                OpenPosition(ENUM_ORDER_TYPE order_type, double volume, double sl_price, double tp_price, const string comment);
    bool                ClosePosition(long ticket, const string reason, double volume_to_close = 0); // volume=0 means full close
    bool                ModifyPosition(long ticket, double new_sl_price, double new_tp_price);
    bool                DeletePendingOrder(long ticket, const string reason);

private:
    // --- Pre-flight Checks ---
    bool                IsTradeContextValid(const string calling_function);

    // --- Calculation & Query Helpers ---
    double              NormalizeLots(double lots);
    double              NormalizePrice(double price);
    int                 GetOpenPositionsCount(ENUM_ORDER_TYPE order_type = WRONG_VALUE);
    double              CalculateStopLossPrice(ENUM_ORDER_TYPE order_type, double entry_price, double sl_pips);
    double              CalculateTakeProfitPrice(ENUM_ORDER_TYPE order_type, double entry_price, double tp_pips);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeManager::CTradeManager() : m_context(NULL),
                                     m_symbol(""),
                                     m_magic_number(0),
                                     m_slippage(10),
                                     m_max_spread_points(0)
{
    // Constructor is light. Initialization in Initialize().
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CTradeManager::~CTradeManager(void)
{
    // Deinitialization logic can be added here if needed in the future.
}

//+------------------------------------------------------------------+
//| Initialize the trade manager                                     |
//+------------------------------------------------------------------+
bool CTradeManager::Initialize(EAContext* pContext)
{
    if (!pContext)
    {
        printf("FATAL: CTradeManager received NULL context during initialization.");
        return false;
    }
    
    m_context = pContext;
    return Initialize();
}

bool CTradeManager::Initialize()
{
    if (!m_context || !m_context->pLogger)
    {
        // Cannot log, but must not proceed
        printf("FATAL: CTradeManager received NULL Logger during initialization.");
        return false;
    }

    m_symbol = m_context->pSymbolInfo->Symbol();
    m_magic_number = m_context->Inputs.MagicNumber;
    m_slippage = m_context->Inputs.Slippage;
    m_max_spread_points = (int)m_context->Inputs.MarketFilters.MaxSpreadPoints;

    m_trade.SetExpertMagicNumber(m_magic_number);
    m_trade.SetMarginMode(); // Use account's default margin mode
    m_trade.SetTypeFillingBySymbol(m_symbol);

    if(m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_INFO, "TradeManager initialized for symbol " + m_symbol + " with Magic Number " + (string)m_magic_number);
    return true;
}

//+------------------------------------------------------------------+
//| Open a new market position                                       |
//+------------------------------------------------------------------+
bool CTradeManager::OpenPosition(ENUM_ORDER_TYPE order_type, double volume, double sl_price, double tp_price, const string comment)
{
    if (!IsTradeContextValid("OpenPosition")) return false;

    double normalized_volume = NormalizeLots(volume);
    if (normalized_volume <= 0)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, "Invalid trade volume: " + DoubleToString(volume) + ", Normalized: " + DoubleToString(normalized_volume));
        return false;
    }

    m_context->pSymbolInfo->RefreshRates();
    double price = (order_type == ORDER_TYPE_BUY) ? m_context->pSymbolInfo->Ask() : m_context->pSymbolInfo->Bid();

    if(m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_INFO, StringFormat("Attempting to open %s position for %s, Vol: %.2f, Price: %.5f, SL: %.5f, TP: %.5f, Comment: %s",
        EnumToString(order_type), m_symbol, normalized_volume, price, sl_price, tp_price, comment));

    bool result = m_trade.PositionOpen(m_symbol, order_type, normalized_volume, price, sl_price, tp_price, comment);

    if (result)
    {
        if(m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_INFO, "Position opened successfully. Deal: #" + (string)m_trade.ResultDeal() + ", Position: #" + (string)m_trade.ResultPosition());
        // TODO: Notify RiskManager about the new trade
        // m_context->pRiskManager->OnTradeOpened(m_trade.ResultPosition());
    }
    else
    {
        if(m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, "Failed to open position. Error: " + (string)m_trade.ResultRetcode() + " - " + m_trade.ResultRetcodeDescription());
    }

    return result;
}

//+------------------------------------------------------------------+
//| Close an existing position (fully or partially)                  |
//+------------------------------------------------------------------+
bool CTradeManager::ClosePosition(long ticket, const string reason, double volume_to_close = 0)
{
    if (!IsTradeContextValid("ClosePosition")) return false;

    if (!m_trade.PositionSelectByTicket(ticket))
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, "Failed to select position #" + (string)ticket + " for closing.");
        return false;
    }

    // Double-check if it's our position
    if (m_trade.PositionGetInteger(POSITION_MAGIC) != m_magic_number)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_WARNING, "Attempted to close position #" + (string)ticket + " which has a different magic number.");
        return false;
    }

    double position_volume = m_trade.PositionGetDouble(POSITION_VOLUME);
    double volume_to_close_normalized = (volume_to_close > 0) ? NormalizeLots(volume_to_close) : position_volume;

    if (volume_to_close_normalized > position_volume)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_WARNING, "Volume to close (" + (string)volume_to_close_normalized + ") is greater than position volume (" + (string)position_volume + "). Adjusting to full close.");
        volume_to_close_normalized = position_volume;
    }

    if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_INFO, StringFormat("Attempting to close %.2f lots of position #%d. Reason: %s", volume_to_close_normalized, ticket, reason));

    bool result = m_trade.PositionClose(ticket, volume_to_close_normalized);

    if (result)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_INFO, "Position #" + (string)ticket + " close order sent successfully. Deal: #" + (string)m_trade.ResultDeal());
    }
    else
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, "Failed to close position #" + (string)ticket + ". Error: " + (string)m_trade.ResultRetcode() + " - " + m_trade.ResultRetcodeDescription());
    }

    return result;
}

//+------------------------------------------------------------------+
//| Modify SL/TP for an open position                                |
//+------------------------------------------------------------------+
bool CTradeManager::ModifyPosition(long ticket, double new_sl_price, double new_tp_price)
{
    if (!IsTradeContextValid("ModifyPosition")) return false;

    if (!m_trade.PositionSelectByTicket(ticket))
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, "Failed to select position #" + (string)ticket + " for modification.");
        return false;
    }

    if (m_trade.PositionGetInteger(POSITION_MAGIC) != m_magic_number)
    {
        return false; // Silently ignore positions from other EAs
    }

    double current_sl = m_trade.PositionGetDouble(POSITION_SL);
    double current_tp = m_trade.PositionGetDouble(POSITION_TP);

    // Check if modification is actually needed to avoid unnecessary server calls
    if (MathAbs(new_sl_price - current_sl) < m_context->pSymbolInfo->TickSize() &&
        MathAbs(new_tp_price - current_tp) < m_context->pSymbolInfo->TickSize())
    {
        return true; // No significant change needed
    }

    m_context->pLogger->LogInfo(StringFormat("Attempting to modify position #%d: SL from %.5f to %.5f, TP from %.5f to %.5f",
        ticket, current_sl, new_sl_price, current_tp, new_tp_price), "TradeManager");

    bool result = m_trade.PositionModify(ticket, new_sl_price, new_tp_price);

    if (result)
    {
        m_context->pLogger->LogInfo("Position #" + (string)ticket + " modified successfully.", "TradeManager");
    }
    else
    {
        m_context->pLogger->LogError("Failed to modify position #" + (string)ticket + ". Error: " + (string)m_trade.ResultRetcode() + " - " + m_trade.ResultRetcodeDescription(), "TradeManager");
    }

    return result;
}

//+------------------------------------------------------------------+
//| Delete a pending order                                           |
//+------------------------------------------------------------------+
bool CTradeManager::DeletePendingOrder(long ticket, const string reason)
{
    if (!IsTradeContextValid("DeletePendingOrder")) return false;

    m_context->pLogger->LogInfo("Attempting to delete pending order #" + (string)ticket + ". Reason: " + reason, "TradeManager");

    bool result = m_trade.OrderDelete(ticket);

    if (result)
    {
        m_context->pLogger->LogInfo("Pending order #" + (string)ticket + " deleted successfully.", "TradeManager");
    }
    else
    {
        m_context->pLogger->LogError("Failed to delete pending order #" + (string)ticket + ". Error: " + (string)m_trade.ResultRetcode() + " - " + m_trade.ResultRetcodeDescription(), "TradeManager");
    }

    return result;
}

//+------------------------------------------------------------------+
//| Check if the trading context is valid                            |
//+------------------------------------------------------------------+
bool CTradeManager::IsTradeContextValid(const string calling_function)
{
    // 1. Check Server Connection & Trade Permissions
    if (!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, StringFormat("Trade context invalid in %s: Trading is not allowed.", calling_function));
        return false;
    }

    // 2. Check Spread
    m_context->pSymbolInfo->RefreshRates(); // Refresh before checking spread
    long current_spread = m_context->pSymbolInfo->Spread();
    if (m_max_spread_points > 0 && current_spread > m_max_spread_points)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_WARNING, StringFormat("Trade context invalid in %s: Current spread (%d) exceeds max allowed (%d).", calling_function, (int)current_spread, m_max_spread_points));
        return false;
    }

    // 3. Check for valid prices
    if (m_context->pSymbolInfo->Bid() <= 0 || m_context->pSymbolInfo->Ask() <= 0)
    {
        if(m_context && m_context->pLogger) m_context->pLogger->Log(ALERT_LEVEL_ERROR, StringFormat("Trade context invalid in %s: Market prices are zero.", calling_function));
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Normalize lot size to be compliant with symbol specification     |
//+------------------------------------------------------------------+
double CTradeManager::NormalizeLots(double lots)
{
    if (!m_context) return 0.0;

    double volume_step = m_context->pSymbolInfo->VolumeStep();
    double min_volume = m_context->pSymbolInfo->VolumeMin();
    double max_volume = m_context->pSymbolInfo->VolumeMax();

    // Ensure volume_step is not zero to prevent division by zero error
    if (volume_step <= 0)
    {
        if(m_context->pLogger) m_context->pLogger->LogError("Invalid volume_step: " + (string)volume_step + ". Cannot normalize lots.", "TradeManager");
        return 0.0;
    }

    double normalized_lots = MathRound(lots / volume_step) * volume_step;

    // Clamp the value within the min/max limits
    if (normalized_lots < min_volume && lots > 0) normalized_lots = min_volume;
    if (normalized_lots > max_volume) normalized_lots = max_volume;

    return normalized_lots;
}

//+------------------------------------------------------------------+
//| Lấy số lượng vị thế đang mở theo loại                             |
//+------------------------------------------------------------------+
int CTradeManager::GetOpenPositionsCount(ENUM_ORDER_TYPE order_type = WRONG_VALUE)
{
    if (!m_context) return 0;
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        if(m_trade.PositionSelectByIndex(i)) // Select by index
        {
            if(m_trade.PositionGetInteger(POSITION_MAGIC) == m_magic_number && m_trade.PositionGetString(POSITION_SYMBOL) == m_symbol)
            {
                if(order_type == WRONG_VALUE || (ENUM_ORDER_TYPE)m_trade.PositionGetInteger(POSITION_TYPE) == order_type)
                {
                    count++;
                }
            }
        }
    }
    return count;
}

//+------------------------------------------------------------------+
//| Tính toán giá Stop Loss                                          |
//+------------------------------------------------------------------+
double CTradeManager::CalculateStopLossPrice(ENUM_ORDER_TYPE order_type, double entry_price, double sl_pips)
{
    if (sl_pips <= 0 || !m_context) return 0.0;
    double pips_value = sl_pips * m_context->pSymbolInfo->Point();
    double sl_price = (order_type == ORDER_TYPE_BUY) ? entry_price - pips_value : entry_price + pips_value;
    return NormalizePrice(sl_price);
}

//+------------------------------------------------------------------+
//| Tính toán giá Take Profit                                        |
//+------------------------------------------------------------------+
double CTradeManager::CalculateTakeProfitPrice(ENUM_ORDER_TYPE order_type, double entry_price, double tp_pips)
{
    if (tp_pips <= 0 || !m_context) return 0.0;
    double pips_value = tp_pips * m_context->pSymbolInfo->Point();
    double tp_price = (order_type == ORDER_TYPE_BUY) ? entry_price + pips_value : entry_price - pips_value;
    return NormalizePrice(tp_price);
}

//+------------------------------------------------------------------+
//| Chuẩn hóa giá theo số chữ số thập phân của biểu đồ                |
//+------------------------------------------------------------------+
double CTradeManager::NormalizePrice(double price)
{
    if (!m_context) return price;
    return NormalizeDouble(price, m_context->pSymbolInfo->Digits());
}

} // END NAMESPACE ApexPullback
#endif // TRADEMANAGER_MQH_