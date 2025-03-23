//+------------------------------------------------------------------+
//|                                           SonicR_ExitManager.mqh |
//|                SonicR PropFirm EA - Exit Management Component    |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

#include <Trade\Trade.mqh>
#include "SonicR_Logger.mqh"

// Exit manager class for handling trade exits
class CExitManager
{
private:
    // Logger
    CLogger* m_logger;
    
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
    bool m_useVirtualSL;              // Use virtual SL and TP
    
    // Trade execution object
    CTrade* m_trade;
    
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
        datetime openTime;            // Open time
        string symbol;                // Symbol
    };
    
    TradeInfo m_trades[50];           // Array to track open trades
    int m_tradeCount;                 // Number of trades being tracked
    
    // Virtual SL/TP tracking
    struct VirtualLevel {
        ulong ticket;                 // Ticket number
        double sl;                    // Virtual stop loss
        double tp;                    // Virtual take profit
        datetime lastCheck;           // Last check time
    };
    
    VirtualLevel m_virtualLevels[50]; // Array to track virtual levels
    int m_virtualCount;               // Number of virtual levels
    
    // Helper methods
    void UpdateTradeInfo();
    bool ClosePartialPosition(ulong ticket, double lots);
    bool ModifyStopLoss(ulong ticket, double newSL);
    bool ModifyTakeProfit(ulong ticket, double newTP);
    double CalculateOptimalTrailingStop(double entryPrice, double currentPrice, int type, double originalSL);
    double CalculateATR(int period = 14, string symbol = NULL);
    bool IsMarketOpen(string symbol = NULL);
    
    // Virtual SL/TP management
    void UpdateVirtualLevels();
    bool CheckVirtualStopLoss(TradeInfo &trade);
    bool CheckVirtualTakeProfit(TradeInfo &trade);
    void AddVirtualLevel(ulong ticket, double sl, double tp);
    void RemoveVirtualLevel(int index);
    int FindVirtualLevel(ulong ticket);
    
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
    
    // Destructor
    ~CExitManager();
    
    // Main methods
    void Update();
    void ManageExits();
    void CloseAllPositions(string reason = "Manual close");
    
    // Set dependencies
    void SetTrade(CTrade* trade) { m_trade = trade; }
    void SetLogger(CLogger* logger) { m_logger = logger; }
    
    // Set magic number and slippage
    void SetMagicNumber(int magic) { m_magicNumber = magic; }
    void SetSlippage(int slippage) { m_slippage = slippage; }
    void SetUseVirtualSL(bool virtualSL) { m_useVirtualSL = virtualSL; }
    
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
    m_logger = NULL;
    m_trade = NULL;
    
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
    m_useVirtualSL = false;
    
    // Initialize virtual SL/TP tracking
    m_virtualCount = 0;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CExitManager::~CExitManager()
{
    // Nothing to clean up
}

//+------------------------------------------------------------------+
//| Update exit manager                                              |
//+------------------------------------------------------------------+
void CExitManager::Update()
{
    // Update trade info
    UpdateTradeInfo();
    
    // Update virtual SL/TP levels
    if(m_useVirtualSL) {
        UpdateVirtualLevels();
    }
    
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
        
        if(ticket <= 0) continue;
        
        // Skip positions with different magic number
        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) {
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
        m_trades[m_tradeCount].openTime = (datetime)PositionGetInteger(POSITION_TIME);
        m_trades[m_tradeCount].symbol = PositionGetString(POSITION_SYMBOL);
        
        // For new trades, initialize tracking variables
        bool isNewTrade = true;
        
        // Check if this trade was previously tracked
        for(int j = 0; j < m_tradeCount; j++) {
            if(m_trades[j].ticket == ticket) {
                isNewTrade = false;
                break;
            }
        }
        
        if(isNewTrade) {
            // For virtual SL/TP, check if we have stored levels
            int virtualIndex = FindVirtualLevel(ticket);
            
            if(m_useVirtualSL && virtualIndex >= 0) {
                // Use stored virtual levels
                m_trades[m_tradeCount].originalSL = m_virtualLevels[virtualIndex].sl;
                m_trades[m_tradeCount].originalTP = m_virtualLevels[virtualIndex].tp;
            }
            else {
                // Use actual SL/TP as original values
                m_trades[m_tradeCount].originalSL = m_trades[m_tradeCount].stopLoss;
                m_trades[m_tradeCount].originalTP = m_trades[m_tradeCount].takeProfit;
                
                // If using virtual SL/TP, store these levels
                if(m_useVirtualSL) {
                    AddVirtualLevel(ticket, m_trades[m_tradeCount].stopLoss, m_trades[m_tradeCount].takeProfit);
                }
            }
            
            m_trades[m_tradeCount].tp1Hit = false;
            m_trades[m_tradeCount].breakEvenSet = false;
            m_trades[m_tradeCount].trailingLevel = 0;
            m_trades[m_tradeCount].maxProfit = 0;
            
            if(m_logger) {
                m_logger.Info("New trade detected: " + m_trades[m_tradeCount].symbol + 
                            " " + (m_trades[m_tradeCount].type == 0 ? "BUY" : "SELL") + 
                            " " + DoubleToString(m_trades[m_tradeCount].lots, 2) + 
                            " lots at " + DoubleToString(m_trades[m_tradeCount].openPrice, _Digits));
            }
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
//| Update virtual SL/TP levels                                      |
//+------------------------------------------------------------------+
void CExitManager::UpdateVirtualLevels()
{
    if(!m_useVirtualSL) return;
    
    for(int i = 0; i < m_tradeCount; i++) {
        // Find corresponding virtual level
        int index = FindVirtualLevel(m_trades[i].ticket);
        
        // If not found, add it
        if(index < 0) {
            AddVirtualLevel(m_trades[i].ticket, m_trades[i].stopLoss, m_trades[i].takeProfit);
            continue;
        }
        
        // Check if virtual stop loss hit
        if(CheckVirtualStopLoss(m_trades[i])) {
            // Close position at market
            if(m_trade != NULL) {
                if(m_logger) {
                    m_logger.Warning("Virtual stop loss hit for ticket " + IntegerToString(m_trades[i].ticket) + 
                                   " at price " + DoubleToString(m_virtualLevels[index].sl, _Digits));
                }
                
                // Close position
                m_trade.PositionClose(m_trades[i].ticket);
                
                // Remove virtual level
                RemoveVirtualLevel(index);
            }
        }
        
        // Check if virtual take profit hit
        if(CheckVirtualTakeProfit(m_trades[i])) {
            // Close position at market
            if(m_trade != NULL) {
                if(m_logger) {
                    m_logger.Info("Virtual take profit hit for ticket " + IntegerToString(m_trades[i].ticket) + 
                                " at price " + DoubleToString(m_virtualLevels[index].tp, _Digits));
                }
                
                // Close position
                m_trade.PositionClose(m_trades[i].ticket);
                
                // Remove virtual level
                RemoveVirtualLevel(index);
            }
        }
    }
    
    // Clean up virtual levels for closed positions
    for(int i = m_virtualCount - 1; i >= 0; i--) {
        bool found = false;
        
        // Check if position still exists
        for(int j = 0; j < m_tradeCount; j++) {
            if(m_trades[j].ticket == m_virtualLevels[i].ticket) {
                found = true;
                break;
            }
        }
        
        // If not found, remove virtual level
        if(!found) {
            RemoveVirtualLevel(i);
        }
    }
}

//+------------------------------------------------------------------+
//| Check if virtual stop loss hit                                   |
//+------------------------------------------------------------------+
bool CExitManager::CheckVirtualStopLoss(TradeInfo &trade)
{
    if(!m_useVirtualSL) return false;
    
    int index = FindVirtualLevel(trade.ticket);
    if(index < 0) return false;
    
    // Get current bid/ask
    double bid = SymbolInfoDouble(trade.symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(trade.symbol, SYMBOL_ASK);
    
    // Check if SL hit
    if(trade.type == 0) { // Buy
        if(bid <= m_virtualLevels[index].sl) {
            return true;
        }
    }
    else { // Sell
        if(ask >= m_virtualLevels[index].sl) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Check if virtual take profit hit                                 |
//+------------------------------------------------------------------+
bool CExitManager::CheckVirtualTakeProfit(TradeInfo &trade)
{
    if(!m_useVirtualSL) return false;
    
    int index = FindVirtualLevel(trade.ticket);
    if(index < 0) return false;
    
    // Get current bid/ask
    double bid = SymbolInfoDouble(trade.symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(trade.symbol, SYMBOL_ASK);
    
    // Check if TP hit
    if(trade.type == 0) { // Buy
        if(bid >= m_virtualLevels[index].tp) {
            return true;
        }
    }
    else { // Sell
        if(ask <= m_virtualLevels[index].tp) {
            return true;
        }
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Add virtual level                                                |
//+------------------------------------------------------------------+
void CExitManager::AddVirtualLevel(ulong ticket, double sl, double tp)
{
    if(m_virtualCount >= ArraySize(m_virtualLevels)) {
        if(m_logger) m_logger.Warning("Virtual levels array is full");
        return;
    }
    
    m_virtualLevels[m_virtualCount].ticket = ticket;
    m_virtualLevels[m_virtualCount].sl = sl;
    m_virtualLevels[m_virtualCount].tp = tp;
    m_virtualLevels[m_virtualCount].lastCheck = TimeCurrent();
    
    m_virtualCount++;
}

//+------------------------------------------------------------------+
//| Remove virtual level                                             |
//+------------------------------------------------------------------+
void CExitManager::RemoveVirtualLevel(int index)
{
    if(index < 0 || index >= m_virtualCount) {
        if(m_logger) m_logger.Warning("Invalid virtual level index: " + IntegerToString(index));
        return;
    }
    
    // Shift elements
    for(int i = index; i < m_virtualCount - 1; i++) {
        m_virtualLevels[i] = m_virtualLevels[i+1];
    }
    
    m_virtualCount--;
}

//+------------------------------------------------------------------+
//| Find virtual level by ticket                                     |
//+------------------------------------------------------------------+
int CExitManager::FindVirtualLevel(ulong ticket)
{
    for(int i = 0; i < m_virtualCount; i++) {
        if(m_virtualLevels[i].ticket == ticket) {
            return i;
        }
    }
    
    return -1;
}

//+------------------------------------------------------------------+
//| Manage exits for all open positions                              |
//+------------------------------------------------------------------+
void CExitManager::ManageExits()
{
    // Skip if no trade object
    if(m_trade == NULL) {
        if(m_logger) m_logger.Error("Trade object not set in ExitManager");
        return;
    }
    
    // Loop through all tracked trades
    for(int i = 0; i < m_tradeCount; i++) {
        // Skip trades with invalid SL
        if(m_trades[i].originalSL <= 0) {
            continue;
        }
        
        // Get current price
        double currentPrice = m_trades[i].type == 0 ? 
                            SymbolInfoDouble(m_trades[i].symbol, SYMBOL_BID) : 
                            SymbolInfoDouble(m_trades[i].symbol, SYMBOL_ASK);
        
        // Calculate distance from entry in pips
        double entryToCurrentPips = 0;
        if(m_trades[i].type == 0) { // Buy
            entryToCurrentPips = (currentPrice - m_trades[i].openPrice) / SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
        } else { // Sell
            entryToCurrentPips = (m_trades[i].openPrice - currentPrice) / SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
        }
        
        // Calculate distance from entry to SL in pips
        double entryToSLPips = 0;
        if(m_trades[i].type == 0) { // Buy
            entryToSLPips = (m_trades[i].openPrice - m_trades[i].originalSL) / SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
        } else { // Sell
            entryToSLPips = (m_trades[i].originalSL - m_trades[i].openPrice) / SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
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
            double minLot = SymbolInfoDouble(m_trades[i].symbol, SYMBOL_VOLUME_MIN);
            lotsToClose = MathMax(minLot, MathFloor(lotsToClose / minLot) * minLot);
            
            // Check if we have enough lots to close
            if(lotsToClose < m_trades[i].lots) {
                // Close partial position
                if(ClosePartialPosition(m_trades[i].ticket, lotsToClose)) {
                    if(m_logger) {
                        m_logger.Info("Partial close at TP1: " + DoubleToString(lotsToClose, 2) + 
                                    " lots from ticket " + IntegerToString((int)m_trades[i].ticket));
                    }
                    m_trades[i].tp1Hit = true;
                }
            }
        }
        
        // Check for break-even
        if(m_useBreakEven && !m_trades[i].breakEvenSet && entryToCurrentPips >= entryToSLPips * m_breakEvenTrigger) {
            // Calculate break-even price with offset
            double bePrice = 0;
            if(m_trades[i].type == 0) { // Buy
                bePrice = m_trades[i].openPrice + m_breakEvenOffset * SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
            } else { // Sell
                bePrice = m_trades[i].openPrice - m_breakEvenOffset * SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT);
            }
            
            // Modify stop loss (real or virtual)
            if(m_useVirtualSL) {
                // Update virtual SL
                int index = FindVirtualLevel(m_trades[i].ticket);
                if(index >= 0) {
                    m_virtualLevels[index].sl = bePrice;
                    m_trades[i].breakEvenSet = true;
                    m_trades[i].stopLoss = bePrice;
                    
                    if(m_logger) {
                        m_logger.Info("Virtual break-even set for ticket " + IntegerToString((int)m_trades[i].ticket) + 
                                    " at " + DoubleToString(bePrice, _Digits));
                    }
                }
            }
            else {
                // Modify stop loss
                if(ModifyStopLoss(m_trades[i].ticket, bePrice)) {
                    if(m_logger) {
                        m_logger.Info("Break-even set for ticket " + IntegerToString((int)m_trades[i].ticket) + 
                                    " at " + DoubleToString(bePrice, _Digits));
                    }
                    m_trades[i].breakEvenSet = true;
                    m_trades[i].stopLoss = bePrice;
                }
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
                shouldModify = (trailingStop > m_trades[i].stopLoss + m_trailingStep * SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT));
            } else { // Sell
                // New SL should be lower than current SL
                shouldModify = (trailingStop < m_trades[i].stopLoss - m_trailingStep * SymbolInfoDouble(m_trades[i].symbol, SYMBOL_POINT));
            }
            
            // Modify stop loss if needed
            if(shouldModify) {
                if(m_useVirtualSL) {
                    // Update virtual SL
                    int index = FindVirtualLevel(m_trades[i].ticket);
                    if(index >= 0) {
                        m_virtualLevels[index].sl = trailingStop;
                        m_trades[i].stopLoss = trailingStop;
                        m_trades[i].trailingLevel = entryToCurrentPips;
                        
                        if(m_logger) {
                            m_logger.Info("Virtual trailing stop updated for ticket " + IntegerToString((int)m_trades[i].ticket) + 
                                        " from " + DoubleToString(m_trades[i].stopLoss, _Digits) + 
                                        " to " + DoubleToString(trailingStop, _Digits));
                        }
                    }
                }
                else {
                    if(ModifyStopLoss(m_trades[i].ticket, trailingStop)) {
                        if(m_logger) {
                            m_logger.Info("Trailing stop updated for ticket " + IntegerToString((int)m_trades[i].ticket) + 
                                        " from " + DoubleToString(m_trades[i].stopLoss, _Digits) + 
                                        " to " + DoubleToString(trailingStop, _Digits));
                        }
                        m_trades[i].stopLoss = trailingStop;
                        m_trades[i].trailingLevel = entryToCurrentPips;
                    }
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
    // Check if we have a trade object
    if(m_trade == NULL) {
        if(m_logger) m_logger.Error("Trade object not set in ExitManager");
        return false;
    }
    
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        if(m_logger) m_logger.Warning("Cannot select position by ticket " + IntegerToString((int)ticket));
        return false;
    }
    
    // Set trade parameters
    m_trade.SetDeviationInPoints(m_slippage);
    
    // Close partial position
    return m_trade.PositionClosePartial(ticket, lots);
}

//+------------------------------------------------------------------+
//| Modify stop loss for a position                                  |
//+------------------------------------------------------------------+
bool CExitManager::ModifyStopLoss(ulong ticket, double newSL)
{
    // Check if we have a trade object
    if(m_trade == NULL) {
        if(m_logger) m_logger.Error("Trade object not set in ExitManager");
        return false;
    }
    
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        if(m_logger) m_logger.Warning("Cannot select position by ticket " + IntegerToString((int)ticket));
        return false;
    }
    
    // Get current TP
    double tp = PositionGetDouble(POSITION_TP);
    
    // Modify position
    return m_trade.PositionModify(ticket, newSL, tp);
}

//+------------------------------------------------------------------+
//| Modify take profit for a position                                |
//+------------------------------------------------------------------+
bool CExitManager::ModifyTakeProfit(ulong ticket, double newTP)
{
    // Check if we have a trade object
    if(m_trade == NULL) {
        if(m_logger) m_logger.Error("Trade object not set in ExitManager");
        return false;
    }
    
    // Set position by ticket
    if(!PositionSelectByTicket(ticket)) {
        if(m_logger) m_logger.Warning("Cannot select position by ticket " + IntegerToString((int)ticket));
        return false;
    }
    
    // Get current SL
    double sl = PositionGetDouble(POSITION_SL);
    
    // Modify position
    return m_trade.PositionModify(ticket, sl, newTP);
}

//+------------------------------------------------------------------+
//| Calculate optimal trailing stop level                            |
//+------------------------------------------------------------------+
double CExitManager::CalculateOptimalTrailingStop(double entryPrice, double currentPrice, 
                                               int type, double originalSL)
{
    string symbol = PositionGetString(POSITION_SYMBOL);
    
    // Simple trailing stop - fixed distance
    if(!m_useAdaptiveTrailing) {
        if(type == 0) { // Buy
            return currentPrice - m_trailingStep * SymbolInfoDouble(symbol, SYMBOL_POINT);
        } else { // Sell
            return currentPrice + m_trailingStep * SymbolInfoDouble(symbol, SYMBOL_POINT);
        }
    }
    
    // Adaptive trailing stop - based on ATR
    double atr = CalculateATR(14, symbol);
    
    // If ATR is 0 or invalid, use fixed distance
    if(atr <= 0) {
        if(type == 0) { // Buy
            return currentPrice - m_trailingStep * SymbolInfoDouble(symbol, SYMBOL_POINT);
        } else { // Sell
            return currentPrice + m_trailingStep * SymbolInfoDouble(symbol, SYMBOL_POINT);
        }
    }
    
    // Calculate trailing distance - smaller for larger profits
    double entryToCurrentPips = 0;
    if(type == 0) { // Buy
        entryToCurrentPips = (currentPrice - entryPrice) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    } else { // Sell
        entryToCurrentPips = (entryPrice - currentPrice) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    }
    
    double entryToSLPips = 0;
    if(type == 0) { // Buy
        entryToSLPips = (entryPrice - originalSL) / SymbolInfoDouble(symbol, SYMBOL_POINT);
    } else { // Sell
        entryToSLPips = (originalSL - entryPrice) / SymbolInfoDouble(symbol, SYMBOL_POINT);
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
double CExitManager::CalculateATR(int period, string symbol)
{
    if(symbol == NULL || symbol == "") {
        symbol = _Symbol;
    }
    
    int handle = iATR(symbol, PERIOD_CURRENT, period);
    
    if(handle == INVALID_HANDLE) {
        if(m_logger) m_logger.Warning("Failed to create ATR handle");
        return 0;
    }
    
    double atr[1];
    
    if(CopyBuffer(handle, 0, 0, 1, atr) <= 0) {
        if(m_logger) m_logger.Warning("Failed to copy ATR buffer");
        IndicatorRelease(handle);
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
    if(m_trade == NULL) {
        if(m_logger) m_logger.Error("Trade object not set in ExitManager");
        return;
    }
    
    if(m_logger) m_logger.Info("Closing all positions. Reason: " + reason);
    
    // Loop through all positions
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        
        if(ticket <= 0) continue;
        
        // Skip positions with different magic number
        if(PositionGetInteger(POSITION_MAGIC) != m_magicNumber) {
            continue;
        }
        
        // Close position
        m_trade.PositionClose(ticket);
        
        // Remove from virtual tracking if needed
        if(m_useVirtualSL) {
            int index = FindVirtualLevel(ticket);
            if(index >= 0) {
                RemoveVirtualLevel(index);
            }
        }
    }
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
        
        if(m_logger) m_logger.Info("Exit Manager switched to more conservative settings");
    }
    else {
        // Reset to normal settings
        m_tp1Distance /= 0.8;
        m_tp1Percent -= 10.0;
        m_breakEvenTrigger /= 0.8;
        m_trailingStart /= 0.8;
        m_trailingStep /= 0.75;
        
        if(m_logger) m_logger.Info("Exit Manager returned to normal settings");
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
bool CExitManager::IsMarketOpen(string symbol)
{
    if(symbol == NULL || symbol == "") {
        symbol = _Symbol;
    }
    
    // Check if we can get current bid price
    double bid = SymbolInfoDouble(symbol, SYMBOL_BID);
    double ask = SymbolInfoDouble(symbol, SYMBOL_ASK);
    
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
    
    status += "Virtual SL/TP: " + (m_useVirtualSL ? "ON" : "OFF") + "\n";
    
    // Open positions
    status += "Open Positions: " + IntegerToString(m_tradeCount) + "\n";
    
    if(m_tradeCount > 0) {
        status += "Current Trades:\n";
        
        for(int i = 0; i < MathMin(m_tradeCount, 3); i++) {
            status += "  #" + IntegerToString((int)m_trades[i].ticket) + ": ";
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