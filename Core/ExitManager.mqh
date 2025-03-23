//+------------------------------------------------------------------+
//|                                                ExitManager.mqh |
//|                           SonicR PropFirm EA - Exit Management |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm EA"
#property link      "https://sonicr.com"

#ifndef EXIT_MANAGER_MQH
#define EXIT_MANAGER_MQH

// Exit manager class for handling trade exits
class CExitManager
{
private:
    // Exit settings
    bool m_usePartialClose;           // Use partial close
    double m_tp1Percent;              // Percentage to close at TP1
    double m_tp1Distance;             // TP1 distance as multiple of SL
    double m_tp2Distance;             // TP2 distance as multiple of SL
    
    bool m_useBreakEven;              // Use break-even
    double m_breakEvenTrigger;        // Break-even trigger as multiple of SL
    double m_breakEvenOffset;         // Break-even offset in pips
    
    bool m_useTrailing;               // Use trailing stop
    double m_trailingStart;           // Trailing start as multiple of SL
    double m_trailingStep;            // Trailing step in pips
    bool m_useAdaptiveTrailing;       // Use adaptive trailing
    
    int m_magicNumber;                // Magic number for trades
    int m_slippage;                   // Slippage in points
    
    // Trade tracking
    struct TradeInfo {
        ulong ticket;                 // Ticket number
        int type;                     // Order type (0=buy, 1=sell)
        double lots;                  // Lot size
        double openPrice;             // Open price
        double stopLoss;              // Current SL
        double takeProfit;            // Current TP
        double originalSL;            // Original SL
        double originalTP;            // Original TP
        bool tp1Hit;                  // TP1 level hit
        bool breakEvenSet;            // Break-even set
        double trailingLevel;         // Current trailing level
        double profit;                // Current profit
        double maxProfit;             // Maximum profit reached
    };
    
    TradeInfo m_trades[50];           // Array to track open trades
    int m_tradeCount;                 // Number of trades being tracked
    
    // Helper methods
    void UpdateTradeInfo();
    bool ClosePartialPosition(ulong ticket, double lots);
    bool ModifyStopLoss(ulong ticket, double newSL);
    bool ModifyTakeProfit(ulong ticket, double newTP);
    double CalculateOptimalTrailingStop(double entryPrice, double currentPrice, int type, double originalSL);
    double CalculateATR(int period = 14);
    bool IsMarketOpen();
    
    // Direct trade execution with MT5 functions
    bool OrderModify(ulong ticket, double sl, double tp);
    bool OrderClose(ulong ticket, double volume);
    
public:
    // Constructor
    CExitManager(bool usePartialClose = true,
                double tp1Percent = 50.0,
                double tp1Distance = 1.5,
                double tp2Distance = 2.5,
                bool useBreakEven = true,
                double breakEvenTrigger = 0.7,
                double breakEvenOffset = 5.0,
                bool useTrailing = true,
                double trailingStart = 1.5,
                double trailingStep = 15.0,
                bool useAdaptiveTrailing = true);
    
    // Main methods
    void Update();
    void ManageExits();
    void CloseAllPositions(string reason = "Manual close");
    
    // Set magic number and slippage
    void SetMagicNumber(int magic) { m_magicNumber = magic; }
    void SetSlippage(int slippage) { m_slippage = slippage; }
    
    // Settings
    void SetPartialCloseSettings(bool use, double percent) { 
        m_usePartialClose = use; 
        m_tp1Percent = percent; 
    }
    
    void SetBreakEvenSettings(bool use, double trigger, double offset) { 
        m_useBreakEven = use; 
        m_breakEvenTrigger = trigger; 
        m_breakEvenOffset = offset; 
    }
    
    void SetTrailingSettings(bool use, double start, double step, bool adaptive) { 
        m_useTrailing = use; 
        m_trailingStart = start; 
        m_trailingStep = step;
        m_useAdaptiveTrailing = adaptive;
    }
    
    void SetTpDistances(double tp1, double tp2) {
        m_tp1Distance = tp1;
        m_tp2Distance = tp2;
    }
    
    void SetMoreConservative(bool value);
    
    // Getters
    int GetOpenTradeCount() const { return m_tradeCount; }
    double GetTotalProfit() const;
    
    // Utility
    string GetStatusText() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CExitManager::CExitManager(bool usePartialClose,
                         double tp1Percent,
                         double tp1Distance,
                         double tp2Distance,
                         bool useBreakEven,
                         double breakEvenTrigger,
                         double breakEvenOffset,
                         bool useTrailing,
                         double trailingStart,
                         double trailingStep,
                         bool useAdaptiveTrailing)
{
    // Initialize settings
    m_usePartialClose = usePartialClose;
    m_tp1Percent = tp1Percent;
    m_tp1Distance = tp1Distance;
    m_tp2Distance = tp2Distance;
    
    m_useBreakEven = useBreakEven;
    m_breakEvenTrigger = breakEvenTrigger;
    m_breakEvenOffset = breakEvenOffset;
    
    m_useTrailing = useTrailing;
    m_trailingStart = trailingStart;
    m_trailingStep = trailingStep;
    m_useAdaptiveTrailing = useAdaptiveTrailing;
    
    // Initialize trade tracking
    m_tradeCount = 0;
    m_magicNumber = 0;
    m_slippage = 10; // Default slippage (10 points)
}

//+------------------------------------------------------------------+
//| Update exit manager                                              |
//+------------------------------------------------------------------+
void CExitManager::Update()
{
    // Update trade info
    UpdateTradeInfo();
    
    // Manage exits if market is open
    if(IsMarketOpen()) {
        ManageExits();
    }
}

//+------------------------------------------------------------------+
//| Update trade information                                         |
//+------------------------------------------------------------------+
void CExitManager::UpdateTradeInfo()
{
    // Clear trade array
    m_tradeCount = 0;
    
    // Loop through all positions
    for(int i = 0; i < PositionsTotal(); i++) {
        ulong ticket = PositionGetTicket(i);
        
        // Skip positions with different symbol or magic number
        if(PositionGetString(POSITION_SYMBOL) != _Symbol || 
           PositionGetInteger(POSITION_MAGIC) != m_magicNumber) {
            continue;
        }
        
        // Store trade info
        m_trades[m_tradeCount].ticket = ticket;
        m_trades[m_tradeCount].type = (int)PositionGetInteger(POSITION_TYPE);
        m_trades[m_tradeCount].lots = PositionGetDouble(POSITION_VOLUME);
        m_trades[m_tradeCount].openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
        m_trades[m_tradeCount].stopLoss = PositionGetDouble(POSITION_SL);
        m_trades[m_tradeCount].takeProfit = PositionGetDouble(POSITION_TP);
        m_trades[m_tradeCount].profit = PositionGetDouble(POSITION_PROFIT);
        
        // For new trades, initialize tracking variables
        bool isNewTrade = true;
        for(int j = 0; j < m_tradeCount; j++) {
            if(m_trades[j].ticket == ticket) {
                isNewTrade = false;
                break;
            }
        }
        
        if(isNewTrade) {
            m_trades[m_tradeCount].originalSL = m_trades[m_tradeCount].stopLoss;
            m_trades[m_tradeCount].originalTP = m_trades[m_tradeCount].takeProfit;
            m_trades[m_tradeCount].tp1Hit = false;
            m_trades[m_tradeCount].breakEvenSet = false;
            m_trades[m_tradeCount].trailingLevel = 0;
            m_trades[m_tradeCount].maxProfit = 0;
        }
        
        // Update max profit
        if(m_trades[m_tradeCount].profit > m_trades[m_tradeCount].maxProfit) {
            m_trades[m_tradeCount].maxProfit = m_trades[m_tradeCount].profit;
        }
        
        m_tradeCount++;
        
        // Break if array is full
        if(m_tradeCount >= ArraySize(m_trades)) {
            break;
        }
    }
}

//+------------------------------------------------------------------+
//| Manage exits for all open positions                              |
//+------------------------------------------------------------------+
void CExitManager::ManageExits()
{
    // Loop through all tracked trades
    for(int i = 0; i < m_tradeCount; i++) {
        // Skip trades with invalid SL
        if(m_trades[i].originalSL <= 0) {
            continue;
        }
        
        // Get current price
        double currentPrice = m_trades[i].type == 0 ? 
                            SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                            SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        
        // Calculate distance from entry in pips
        double entryToCurrentPips = 0;
        if(m_trades[i].type == 0) { // Buy
            entryToCurrentPips = (currentPrice - m_trades[i].openPrice) / _Point;
        } else { // Sell
            entryToCurrentPips = (m_trades[i].openPrice - currentPrice) / _Point;
        }
        
        // Calculate distance from entry to SL in pips
        double entryToSLPips = 0;
        if(m_trades[i].type == 0) { // Buy
            entryToSLPips = (m_trades[i].openPrice - m_trades[i].originalSL) / _Point;
        } else { // Sell
            entryToSLPips = (m_trades[i].originalSL - m_trades[i].openPrice) / _Point;
        }
        
        // Check if entryToSLPips is valid
        if(entryToSLPips <= 0) {
            continue;
        }
        
        // Check for partial close at TP1
        if(m_usePartialClose && !m_trades[i].tp1Hit && entryToCurrentPips >= entryToSLPips * m_tp1Distance) {
            // Calculate lots to close
            double lotsToClose = m_trades[i].lots * (m_tp1Percent / 100.0);
            
            // Ensure minimum lot size
            double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            lotsToClose = MathMax(minLot, MathFloor(lotsToClose / minLot) * minLot);
            
            // Check if we have enough lots to close
            if(lotsToClose < m_trades[i].lots) {
                // Close partial position
                if(ClosePartialPosition(m_trades[i].ticket, lotsToClose)) {
                    Print("Partial close at TP1: ", lotsToClose, " lots from ticket ", m_trades[i].ticket);
                    m_trades[i].tp1Hit = true;
                }
            }
        }
        
        // Check for break-even
        if(m_useBreakEven && !m_trades[i].breakEvenSet && entryToCurrentPips >= entryToSLPips * m_breakEvenTrigger) {
            // Calculate break-even price with offset
            double bePrice = 0;
            if(m_trades[i].type == 0) { // Buy
                bePrice = m_trades[i].openPrice + m_breakEvenOffset * _Point;
            } else { // Sell
                bePrice = m_trades[i].openPrice - m_breakEvenOffset * _Point;
            }
            
            // Modify stop loss
            if(ModifyStopLoss(m_trades[i].ticket, bePrice)) {
                Print("Break-even set for ticket ", m_trades[i].ticket);
                m_trades[i].breakEvenSet = true;
                m_trades[i].stopLoss = bePrice;
            }
        }
        
        // Check for trailing stop
        if(m_useTrailing && entryToCurrentPips >= entryToSLPips * m_trailingStart) {
            // Calculate optimal trailing stop
            double trailingStop = CalculateOptimalTrailingStop(
                m_trades[i].openPrice, 
                currentPrice, 
                m_trades[i].type, 
                m_trades[i].originalSL
            );
            
            // Check if trailing stop should be modified
            bool shouldModify = false;
            
            if(m_trades[i].type == 0) { // Buy
                // New SL should be higher than current SL
                shouldModify = (trailingStop > m_trades[i].stopLoss + m_trailingStep * _Point);
            } else { // Sell
                // New SL should be lower than current SL
                shouldModify = (trailingStop < m_trades[i].stopLoss - m_trailingStep * _Point);
            }
            
            // Modify stop loss if needed
            if(shouldModify) {
                if(ModifyStopLoss(m_trades[i].ticket, trailingStop)) {
                    Print("Trailing stop updated for ticket ", m_trades[i].ticket, 
                         " from ", m_trades[i].stopLoss, " to ", trailingStop);
                    m_trades[i].stopLoss = trailingStop;
                    m_trades[i].trailingLevel = entryToCurrentPips;
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Close a partial position                                         |
//+------------------------------------------------------------------+
bool CExitManager::ClosePartialPosition(ulong ticket, double lots)
{
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Close partial position
    return OrderClose(ticket, lots);
}

//+------------------------------------------------------------------+
//| Modify stop loss for a position                                  |
//+------------------------------------------------------------------+
bool CExitManager::ModifyStopLoss(ulong ticket, double newSL)
{
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Get current TP
    double tp = PositionGetDouble(POSITION_TP);
    
    // Modify position
    return OrderModify(ticket, newSL, tp);
}

//+------------------------------------------------------------------+
//| Modify take profit for a position                                |
//+------------------------------------------------------------------+
bool CExitManager::ModifyTakeProfit(ulong ticket, double newTP)
{
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Get current SL
    double sl = PositionGetDouble(POSITION_SL);
    
    // Modify position
    return OrderModify(ticket, sl, newTP);
}

//+------------------------------------------------------------------+
//| Order modification using MT5 core functions                      |
//+------------------------------------------------------------------+
bool CExitManager::OrderModify(ulong ticket, double sl, double tp)
{
    // Select the position
    if(!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Prepare request
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    // Fill the request
    request.action = TRADE_ACTION_SLTP;
    request.position = ticket;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.sl = sl;
    request.tp = tp;
    
    // Send the request
    bool success = OrderSend(request, result);
    
    if(!success) {
        Print("OrderModify error: ", GetLastError());
    }
    
    return (success && result.retcode == TRADE_RETCODE_DONE);
}

//+------------------------------------------------------------------+
//| Order close (partial or full) using MT5 core functions           |
//+------------------------------------------------------------------+
bool CExitManager::OrderClose(ulong ticket, double volume)
{
    // Select the position
    if(!PositionSelectByTicket(ticket)) {
        return false;
    }
    
    // Prepare request
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    
    // Fill the request
    request.action = TRADE_ACTION_DEAL;
    request.position = ticket;
    request.symbol = PositionGetString(POSITION_SYMBOL);
    request.volume = volume;
    
    // Set the price
    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
        request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
        request.type = ORDER_TYPE_SELL;
    } else {
        request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.type = ORDER_TYPE_BUY;
    }
    
    request.deviation = m_slippage;
    
    // Send the request
    bool success = OrderSend(request, result);
    
    if(!success) {
        Print("OrderClose error: ", GetLastError());
    }
    
    return (success && result.retcode == TRADE_RETCODE_DONE);
}

//+------------------------------------------------------------------+
//| Calculate optimal trailing stop level                            |
//+------------------------------------------------------------------+
double CExitManager::CalculateOptimalTrailingStop(double entryPrice, double currentPrice, 
                                               int type, double originalSL)
{
    // Simple trailing stop - fixed distance
    if(!m_useAdaptiveTrailing) {
        if(type == 0) { // Buy
            return currentPrice - m_trailingStep * _Point;
        } else { // Sell
            return currentPrice + m_trailingStep * _Point;
        }
    }
    
    // Adaptive trailing stop - based on ATR
    double atr = CalculateATR(14);
    
    // If ATR is 0 or invalid, use fixed distance
    if(atr <= 0) {
        if(type == 0) { // Buy
            return currentPrice - m_trailingStep * _Point;
        } else { // Sell
            return currentPrice + m_trailingStep * _Point;
        }
    }
    
    // Calculate trailing distance - smaller for larger profits
    double entryToCurrentPips = 0;
    if(type == 0) { // Buy
        entryToCurrentPips = (currentPrice - entryPrice) / _Point;
    } else { // Sell
        entryToCurrentPips = (entryPrice - currentPrice) / _Point;
    }
    
    double entryToSLPips = 0;
    if(type == 0) { // Buy
        entryToSLPips = (entryPrice - originalSL) / _Point;
    } else { // Sell
        entryToSLPips = (originalSL - entryPrice) / _Point;
    }
    
    // Use tighter trailing as profit increases
    double trailingFactor = 1.0;
    if(entryToSLPips > 0) {
        double profitRatio = entryToCurrentPips / entryToSLPips;
        
        if(profitRatio > 3.0) {
            trailingFactor = 0.5;
        } else if(profitRatio > 2.0) {
            trailingFactor = 0.75;
        }
    }
    
    // Calculate adaptive trailing stop
    if(type == 0) { // Buy
        return currentPrice - atr * trailingFactor;
    } else { // Sell
        return currentPrice + atr * trailingFactor;
    }
}

//+------------------------------------------------------------------+
//| Calculate ATR                                                    |
//+------------------------------------------------------------------+
double CExitManager::CalculateATR(int period)
{
    double atr[1];
    int handle = iATR(_Symbol, PERIOD_CURRENT, period);
    
    if(handle == INVALID_HANDLE) {
        return 0;
    }
    
    if(CopyBuffer(handle, 0, 0, 1, atr) <= 0) {
        return 0;
    }
    
    IndicatorRelease(handle);
    
    return atr[0];
}

//+------------------------------------------------------------------+
//| Close all open positions                                         |
//+------------------------------------------------------------------+
void CExitManager::CloseAllPositions(string reason)
{
    // Loop through all positions
    for(int i = 0; i < PositionsTotal(); i++) {
        // Get position ticket
        ulong ticket = PositionGetTicket(i);
        
        // Skip positions with different symbol or magic number
        if(PositionGetString(POSITION_SYMBOL) != _Symbol || 
           PositionGetInteger(POSITION_MAGIC) != m_magicNumber) {
            continue;
        }
        
        // Close position fully
        double volume = PositionGetDouble(POSITION_VOLUME);
        bool result = OrderClose(ticket, volume);
        
        // If position closed, decrement counter to account for removed position
        if(result) {
            i--;
        }
    }
    
    Print("All positions closed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Set more conservative exit settings for PropFirm safety          |
//+------------------------------------------------------------------+
void CExitManager::SetMoreConservative(bool value)
{
    if(value) {
        // More conservative settings
        m_tp1Distance *= 0.8;        // Take profit sooner
        m_tp1Percent += 10.0;        // Close more at first TP
        m_breakEvenTrigger *= 0.8;   // Set break-even sooner
        m_trailingStart *= 0.8;      // Start trailing sooner
        m_trailingStep *= 0.75;      // Tighter trailing
    } else {
        // Reset to normal settings
        m_tp1Distance /= 0.8;
        m_tp1Percent -= 10.0;
        m_breakEvenTrigger /= 0.8;
        m_trailingStart /= 0.8;
        m_trailingStep /= 0.75;
    }
}

//+------------------------------------------------------------------+
//| Get total profit of all open positions                           |
//+------------------------------------------------------------------+
double CExitManager::GetTotalProfit() const
{
    double totalProfit = 0;
    
    for(int i = 0; i < m_tradeCount; i++) {
        totalProfit += m_trades[i].profit;
    }
    
    return totalProfit;
}

//+------------------------------------------------------------------+
//| Check if market is open                                          |
//+------------------------------------------------------------------+
bool CExitManager::IsMarketOpen()
{
    // Check if we can get current bid price
    double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    return (bid > 0 && ask > 0 && ask > bid);
}

//+------------------------------------------------------------------+
//| Get status text for diagnostics                                  |
//+------------------------------------------------------------------+
string CExitManager::GetStatusText() const
{
    string status = "Exit Manager Status:\n";
    
    // Exit settings
    status += "Partial Close: " + (m_usePartialClose ? "ON" : "OFF");
    if(m_usePartialClose) {
        status += " (" + DoubleToString(m_tp1Percent, 1) + "% at " + 
                DoubleToString(m_tp1Distance, 1) + "x SL)\n";
    } else {
        status += "\n";
    }
    
    status += "Break-Even: " + (m_useBreakEven ? "ON" : "OFF");
    if(m_useBreakEven) {
        status += " (Trigger: " + DoubleToString(m_breakEvenTrigger, 1) + "x SL)\n";
    } else {
        status += "\n";
    }
    
    status += "Trailing Stop: " + (m_useTrailing ? "ON" : "OFF");
    if(m_useTrailing) {
        status += " (Start: " + DoubleToString(m_trailingStart, 1) + 
                "x SL, Step: " + DoubleToString(m_trailingStep, 1) + " pips)\n";
    } else {
        status += "\n";
    }
    
    // Open positions
    status += "Open Positions: " + IntegerToString(m_tradeCount) + "\n";
    
    if(m_tradeCount > 0) {
        status += "Current Trades:\n";
        
        for(int i = 0; i < MathMin(m_tradeCount, 3); i++) {
            status += "  #" + IntegerToString(m_trades[i].ticket) + ": ";
            status += (m_trades[i].type == 0 ? "BUY" : "SELL") + " ";
            status += DoubleToString(m_trades[i].lots, 2) + " lots, ";
            status += "Profit: " + DoubleToString(m_trades[i].profit, 2) + "\n";
            
            // Show exit status
            status += "    BE: " + (m_trades[i].breakEvenSet ? "Set" : "Not Set") + ", ";
            status += "TP1: " + (m_trades[i].tp1Hit ? "Hit" : "Not Hit") + "\n";
        }
        
        // If more than 3 trades, show summary
        if(m_tradeCount > 3) {
            status += "  ... and " + IntegerToString(m_tradeCount - 3) + " more positions\n";
        }
        
        // Show total profit
        status += "Total Profit: " + DoubleToString(GetTotalProfit(), 2) + "\n";
    }
    
    return status;
}

#endif // EXIT_MANAGER_MQH