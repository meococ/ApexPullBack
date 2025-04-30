//+------------------------------------------------------------------+
//| CTradeManager.mqh - Manages trade execution and open positions    |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

// Forward declaration for logger
class CLogger;

//+------------------------------------------------------------------+
//| CTradeManager Class - Manages trade execution and monitoring      |
//+------------------------------------------------------------------+
class CTradeManager {
private:
    // Basic properties
    string m_symbol;                   // Symbol
    int m_magicNumber;                 // Magic number
    
    // Trade settings
    double m_partialClosePercent;      // Percentage to close at TP1
    double m_breakEvenLevel;           // Level to move to breakeven (in R)
    double m_trailingActivationR;      // Level to activate trailing stop (in R)
    double m_takeProfitMultiplier;     // TP1 as multiple of risk
    int m_maxRetryAttempts;            // Maximum retry attempts for orders
    int m_retryDelayMs;                // Delay between retries in milliseconds
    
    // SuperTrend parameters
    int m_superTrendPeriod;            // SuperTrend ATR period
    double m_superTrendMultiplier;     // SuperTrend multiplier
    int m_superTrendHandle;            // Handle for SuperTrend indicator
    
    // Trade tracking
    TradeRecord m_openTrades[];        // Array of open trades
    TradeCloseRecord m_tradeHistory[]; // Array of closed trades
    
    // SuperTrend buffer
    SuperTrendValues m_superTrend[];   // Buffer for SuperTrend values
    
    // References to other components
    CLogger* m_logger;                 // Logger reference
    
    //--- Private methods
    
    // Calculate SuperTrend values
    bool CalculateSuperTrend() {
        // SuperTrend is a custom indicator so we'll calculate it directly
        int bars = iBars(m_symbol, PERIOD_H1);
        int calcBars = MathMin(bars, 100); // Calculate up to 100 bars back
        
        // Resize SuperTrend buffer
        ArrayResize(m_superTrend, calcBars);
        
        // Get ATR values
        double atr[];
        ArraySetAsSeries(atr, true);
        int atrHandle = iATR(m_symbol, PERIOD_H1, m_superTrendPeriod);
        
        if (atrHandle == INVALID_HANDLE) {
            if (m_logger != NULL) m_logger.Error("Failed to create ATR handle for SuperTrend calculation");
            return false;
        }
        
        if (CopyBuffer(atrHandle, 0, 0, calcBars, atr) <= 0) {
            if (m_logger != NULL) m_logger.Error("Failed to copy ATR data for SuperTrend calculation");
            IndicatorRelease(atrHandle);
            return false;
        }
        
        // Get price data
        double high[], low[], close[];
        ArraySetAsSeries(high, true);
        ArraySetAsSeries(low, true);
        ArraySetAsSeries(close, true);
        
        if (CopyHigh(m_symbol, PERIOD_H1, 0, calcBars, high) <= 0 ||
            CopyLow(m_symbol, PERIOD_H1, 0, calcBars, low) <= 0 ||
            CopyClose(m_symbol, PERIOD_H1, 0, calcBars, close) <= 0) {
            if (m_logger != NULL) m_logger.Error("Failed to copy price data for SuperTrend calculation");
            IndicatorRelease(atrHandle);
            return false;
        }
        
        // Calculate SuperTrend
        double upperBand[], lowerBand[], superTrend[];
        bool isUpTrend[];
        
        ArrayResize(upperBand, calcBars);
        ArrayResize(lowerBand, calcBars);
        ArrayResize(superTrend, calcBars);
        ArrayResize(isUpTrend, calcBars);
        
        // First bar
        double mediaPrice = (high[calcBars-1] + low[calcBars-1]) / 2;
        upperBand[calcBars-1] = mediaPrice + (m_superTrendMultiplier * atr[calcBars-1]);
        lowerBand[calcBars-1] = mediaPrice - (m_superTrendMultiplier * atr[calcBars-1]);
        superTrend[calcBars-1] = close[calcBars-1] > upperBand[calcBars-1] ? lowerBand[calcBars-1] : upperBand[calcBars-1];
        isUpTrend[calcBars-1] = close[calcBars-1] > superTrend[calcBars-1];
        
        // Calculate for remaining bars
        for (int i = calcBars-2; i >= 0; i--) {
            // Calculate basic bands
            mediaPrice = (high[i] + low[i]) / 2;
            double basicUpperBand = mediaPrice + (m_superTrendMultiplier * atr[i]);
            double basicLowerBand = mediaPrice - (m_superTrendMultiplier * atr[i]);
            
            // Adjust bands
            upperBand[i] = basicUpperBand < upperBand[i+1] || close[i+1] > upperBand[i+1] ? basicUpperBand : upperBand[i+1];
            lowerBand[i] = basicLowerBand > lowerBand[i+1] || close[i+1] < lowerBand[i+1] ? basicLowerBand : lowerBand[i+1];
            
            // Determine trend
            isUpTrend[i] = isUpTrend[i+1];
            
            if (isUpTrend[i+1] && close[i] < lowerBand[i]) {
                isUpTrend[i] = false;
            }
            else if (!isUpTrend[i+1] && close[i] > upperBand[i]) {
                isUpTrend[i] = true;
            }
            
            // Assign SuperTrend value
            superTrend[i] = isUpTrend[i] ? lowerBand[i] : upperBand[i];
        }
        
        // Store values in buffer
        for (int i = 0; i < calcBars; i++) {
            m_superTrend[i].upperBand = upperBand[i];
            m_superTrend[i].lowerBand = lowerBand[i];
            m_superTrend[i].superTrend = superTrend[i];
            m_superTrend[i].isUpTrend = isUpTrend[i];
        }
        
        // Release indicator handle
        IndicatorRelease(atrHandle);
        
        return true;
    }
    
    // Execute trade with retry mechanism
    bool ExecuteTradeWithRetry(MqlTradeRequest &request, MqlTradeResult &result) {
        for (int attempt = 1; attempt <= m_maxRetryAttempts; attempt++) {
            // Log attempt
            if (m_logger != NULL && attempt > 1) {
                m_logger.Info("Trade retry attempt " + IntegerToString(attempt) + " of " + 
                             IntegerToString(m_maxRetryAttempts));
            }
            
            // Send the order
            bool success = OrderSend(request, result);
            
            // Check result
            if (success && result.retcode == TRADE_RETCODE_DONE) {
                if (m_logger != NULL) {
                    m_logger.Info("Trade executed successfully: " + EnumToString(request.type) + 
                                 " " + DoubleToString(request.volume, 2) + " " + request.symbol + 
                                 " at " + DoubleToString(result.price, _Digits));
                }
                return true;
            }
            else {
                // Log error
                if (m_logger != NULL) {
                    m_logger.Warning("Trade execution failed: " + IntegerToString(result.retcode) + 
                                    " - " + GetTradeResultDescription(result.retcode));
                }
                
                // If this is not the last attempt, delay and try again
                if (attempt < m_maxRetryAttempts) {
                    // Update price for certain errors
                    if (result.retcode == TRADE_RETCODE_REQUOTE || 
                        result.retcode == TRADE_RETCODE_PRICE_CHANGED) {
                        // Update price depending on order type
                        if (request.type == ORDER_TYPE_BUY) {
                            request.price = SymbolInfoDouble(request.symbol, SYMBOL_ASK);
                        }
                        else if (request.type == ORDER_TYPE_SELL) {
                            request.price = SymbolInfoDouble(request.symbol, SYMBOL_BID);
                        }
                        
                        if (m_logger != NULL) {
                            m_logger.Info("Updated price to " + DoubleToString(request.price, _Digits));
                        }
                    }
                    // Handle invalid stops
                    else if (result.retcode == TRADE_RETCODE_INVALID_STOPS) {
                        // Get minimum stop level
                        int stopLevel = (int)SymbolInfoInteger(request.symbol, SYMBOL_TRADE_STOPS_LEVEL);
                        double point = SymbolInfoDouble(request.symbol, SYMBOL_POINT);
                        double minStopLevel = stopLevel * point;
                        
                        // Adjust SL if needed
                        if (request.type == ORDER_TYPE_BUY && 
                            request.price - request.sl < minStopLevel) {
                            request.sl = request.price - minStopLevel - point;
                            
                            if (m_logger != NULL) {
                                m_logger.Info("Adjusted stop loss to " + DoubleToString(request.sl, _Digits));
                            }
                        }
                        else if (request.type == ORDER_TYPE_SELL && 
                                 request.sl - request.price < minStopLevel) {
                            request.sl = request.price + minStopLevel + point;
                            
                            if (m_logger != NULL) {
                                m_logger.Info("Adjusted stop loss to " + DoubleToString(request.sl, _Digits));
                            }
                        }
                        
                        // Adjust TP if needed
                        if (request.type == ORDER_TYPE_BUY && 
                            request.tp - request.price < minStopLevel) {
                            request.tp = request.price + minStopLevel + point;
                            
                            if (m_logger != NULL) {
                                m_logger.Info("Adjusted take profit to " + DoubleToString(request.tp, _Digits));
                            }
                        }
                        else if (request.type == ORDER_TYPE_SELL && 
                                 request.price - request.tp < minStopLevel) {
                            request.tp = request.price - minStopLevel - point;
                            
                            if (m_logger != NULL) {
                                m_logger.Info("Adjusted take profit to " + DoubleToString(request.tp, _Digits));
                            }
                        }
                    }
                    
                    // Delay before next attempt
                    Sleep(m_retryDelayMs);
                }
                else {
                    // All retries failed
                    if (m_logger != NULL) {
                        m_logger.Error("All trade retry attempts failed");
                    }
                    return false;
                }
            }
        }
        
        return false;
    }
    
    // Create a TradeRecord from an open position
    TradeRecord CreateTradeRecord(ulong ticket) {
        TradeRecord trade;
        
        // Select the position
        if (PositionSelectByTicket(ticket)) {
            trade.ticket = ticket;
            trade.openTime = (datetime)PositionGetInteger(POSITION_TIME);
            trade.closeTime = 0; // Still open
            trade.symbol = PositionGetString(POSITION_SYMBOL);
            trade.magicNumber = (int)PositionGetInteger(POSITION_MAGIC);
            trade.lots = PositionGetDouble(POSITION_VOLUME);
            trade.openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            trade.closePrice = 0; // Still open
            trade.stopLoss = PositionGetDouble(POSITION_SL);
            trade.takeProfit = PositionGetDouble(POSITION_TP);
            trade.initialStopLoss = trade.stopLoss; // Will be updated later if needed
            trade.initialTakeProfit = trade.takeProfit; // Will be updated later if needed
            trade.commission = PositionGetDouble(POSITION_COMMISSION);
            trade.swap = PositionGetDouble(POSITION_SWAP);
            trade.profit = PositionGetDouble(POSITION_PROFIT);
            trade.positionType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            trade.status = TRADE_STATUS_NEW;
            trade.breakEvenSet = false;
            trade.partialClosed = false;
            trade.trailingActive = false;
            trade.initialLots = trade.lots;
            trade.isValid = true;
            
            // Calculate risk in price units
            if (trade.positionType == POSITION_TYPE_BUY) {
                trade.initialRisk = trade.openPrice - trade.stopLoss;
            }
            else {
                trade.initialRisk = trade.stopLoss - trade.openPrice;
            }
            
            // Calculate risk as money amount
            trade.riskMoney = trade.lots * trade.initialRisk / _Point * SymbolInfoDouble(trade.symbol, SYMBOL_TRADE_TICK_VALUE);
            
            // Calculate risk as percentage (will be updated by RiskManager)
            trade.riskPercent = 0;
        }
        
        return trade;
    }
    
    // Update information for an existing TradeRecord
    void UpdateTradeRecord(int index) {
        if (index < 0 || index >= ArraySize(m_openTrades)) return;
        if (!m_openTrades[index].isValid) return;
        
        // Select the position
        ulong ticket = m_openTrades[index].ticket;
        if (!PositionSelectByTicket(ticket)) {
            // Position might have been closed externally
            m_openTrades[index].isValid = false;
            return;
        }
        
        // Update dynamic values
        m_openTrades[index].stopLoss = PositionGetDouble(POSITION_SL);
        m_openTrades[index].takeProfit = PositionGetDouble(POSITION_TP);
        m_openTrades[index].commission = PositionGetDouble(POSITION_COMMISSION);
        m_openTrades[index].swap = PositionGetDouble(POSITION_SWAP);
        m_openTrades[index].profit = PositionGetDouble(POSITION_PROFIT);
        m_openTrades[index].lots = PositionGetDouble(POSITION_VOLUME);
    }
    
    // Move stop loss to breakeven
    bool MoveToBreakeven(int index) {
        if (index < 0 || index >= ArraySize(m_openTrades)) return false;
        if (!m_openTrades[index].isValid) return false;
        
        // Select the position
        ulong ticket = m_openTrades[index].ticket;
        if (!PositionSelectByTicket(ticket)) return false;
        
        // Calculate breakeven level
        double breakeven = m_openTrades[index].openPrice;
        double buffer = 5 * _Point; // Small buffer to ensure SL is hit after commissions
        
        // Set new SL based on position type
        double newSL;
        if (m_openTrades[index].positionType == POSITION_TYPE_BUY) {
            newSL = breakeven + buffer;
        }
        else {
            newSL = breakeven - buffer;
        }
        
        // Modify position
        return ModifyPosition(ticket, newSL, m_openTrades[index].takeProfit);
    }
    
    // Modify position SL/TP
    bool ModifyPosition(ulong ticket, double newSL, double newTP) {
        // Select the position
        if (!PositionSelectByTicket(ticket)) return false;
        
        // Check if modification is needed
        double currentSL = PositionGetDouble(POSITION_SL);
        double currentTP = PositionGetDouble(POSITION_TP);
        
        if (MathAbs(currentSL - newSL) < _Point && MathAbs(currentTP - newTP) < _Point) {
            // No change needed
            return true;
        }
        
        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_SLTP;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.sl = newSL;
        request.tp = newTP;
        request.position = ticket;
        
        // Execute with retry
        bool success = ExecuteTradeWithRetry(request, result);
        
        if (success) {
            // Update the trade record
            for (int i = 0; i < ArraySize(m_openTrades); i++) {
                if (m_openTrades[i].ticket == ticket && m_openTrades[i].isValid) {
                    m_openTrades[i].stopLoss = newSL;
                    m_openTrades[i].takeProfit = newTP;
                    break;
                }
            }
            
            if (m_logger != NULL) {
                m_logger.Info("Modified position #" + IntegerToString(ticket) + 
                             " SL: " + DoubleToString(newSL, _Digits) + 
                             " TP: " + DoubleToString(newTP, _Digits));
            }
        }
        
        return success;
    }
    
    // Partially close a position
    bool PartialClose(int index) {
        if (index < 0 || index >= ArraySize(m_openTrades)) return false;
        if (!m_openTrades[index].isValid) return false;
        
        // Select the position
        ulong ticket = m_openTrades[index].ticket;
        if (!PositionSelectByTicket(ticket)) return false;
        
        // Calculate volume to close
        double totalVolume = PositionGetDouble(POSITION_VOLUME);
        double closeVolume = totalVolume * m_partialClosePercent;
        double minLot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
        double lotStep = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
        
        // Round to valid lot size
        closeVolume = MathFloor(closeVolume / lotStep) * lotStep;
        
        // Ensure minimum lot size
        if (closeVolume < minLot) {
            closeVolume = minLot;
        }
        
        // Ensure not closing more than available
        if (closeVolume > totalVolume) {
            closeVolume = totalVolume;
        }
        
        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = closeVolume;
        request.type = m_openTrades[index].positionType == POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.position = ticket;
        request.price = m_openTrades[index].positionType == POSITION_TYPE_BUY ? 
                      SymbolInfoDouble(m_symbol, SYMBOL_BID) : SymbolInfoDouble(m_symbol, SYMBOL_ASK);
        request.deviation = 10;
        
        // Execute with retry
        bool success = ExecuteTradeWithRetry(request, result);
        
        if (success) {
            // Update the trade record
            m_openTrades[index].partialClosed = true;
            
            if (m_logger != NULL) {
                m_logger.Info("Partially closed position #" + IntegerToString(ticket) + 
                             " Volume: " + DoubleToString(closeVolume, 2) + 
                             " Remaining: " + DoubleToString(totalVolume - closeVolume, 2));
            }
        }
        
        return success;
    }
    
    // Set trailing stop using SuperTrend
    bool SetTrailingStop(int index) {
        if (index < 0 || index >= ArraySize(m_openTrades)) return false;
        if (!m_openTrades[index].isValid) return false;
        
        // Calculate SuperTrend values
        if (!CalculateSuperTrend()) {
            if (m_logger != NULL) m_logger.Warning("Failed to calculate SuperTrend for trailing stop");
            return false;
        }
        
        // Select the position
        ulong ticket = m_openTrades[index].ticket;
        if (!PositionSelectByTicket(ticket)) return false;
        
        // Get SuperTrend value for current bar
        double superTrendValue = m_superTrend[0].superTrend;
        bool isUpTrend = m_superTrend[0].isUpTrend;
        
        // Calculate new SL based on position type
        double newSL;
        if (m_openTrades[index].positionType == POSITION_TYPE_BUY) {
            if (!isUpTrend) {
                // In downtrend, not ideal for buy - use more conservative trailing
                newSL = superTrendValue - 10 * _Point;
            }
            else {
                // In uptrend, use SuperTrend as SL
                newSL = superTrendValue;
            }
            
            // Ensure SL is not below current SL
            if (newSL < m_openTrades[index].stopLoss) {
                newSL = m_openTrades[index].stopLoss;
            }
        }
        else { // POSITION_TYPE_SELL
            if (isUpTrend) {
                // In uptrend, not ideal for sell - use more conservative trailing
                newSL = superTrendValue + 10 * _Point;
            }
            else {
                // In downtrend, use SuperTrend as SL
                newSL = superTrendValue;
            }
            
            // Ensure SL is not above current SL
            if (newSL > m_openTrades[index].stopLoss && m_openTrades[index].stopLoss > 0) {
                newSL = m_openTrades[index].stopLoss;
            }
        }
        
        // Modify position
        return ModifyPosition(ticket, newSL, m_openTrades[index].takeProfit);
    }
    
    // Calculate current R multiple
    double CalculateRMultiple(int index) {
        if (index < 0 || index >= ArraySize(m_openTrades)) return 0;
        if (!m_openTrades[index].isValid) return 0;
        
        // Select the position
        ulong ticket = m_openTrades[index].ticket;
        if (!PositionSelectByTicket(ticket)) return 0;
        
        // Get current price
        double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
        double openPrice = m_openTrades[index].openPrice;
        double initialRisk = m_openTrades[index].initialRisk;
        
        // Avoid division by zero
        if (initialRisk <= _Point) return 0;
        
        // Calculate R multiple
        if (m_openTrades[index].positionType == POSITION_TYPE_BUY) {
            return (currentPrice - openPrice) / initialRisk;
        }
        else {
            return (openPrice - currentPrice) / initialRisk;
        }
    }
    
    // Clean up invalid trades from the array
    void CleanupTradeArray() {
        int validCount = 0;
        
        // Count valid trades
        for (int i = 0; i < ArraySize(m_openTrades); i++) {
            if (m_openTrades[i].isValid) {
                validCount++;
            }
        }
        
        // Create temporary array for valid trades
        TradeRecord validTrades[];
        ArrayResize(validTrades, validCount);
        
        // Copy valid trades
        int index = 0;
        for (int i = 0; i < ArraySize(m_openTrades); i++) {
            if (m_openTrades[i].isValid) {
                validTrades[index++] = m_openTrades[i];
            }
        }
        
        // Replace with valid trades only
        ArrayFree(m_openTrades);
        ArrayResize(m_openTrades, validCount);
        for (int i = 0; i < validCount; i++) {
            m_openTrades[i] = validTrades[i];
        }
    }
    
    // Get trade result description
    string GetTradeResultDescription(int retcode) {
        switch (retcode) {
            case TRADE_RETCODE_DONE: return "Request completed successfully";
            case TRADE_RETCODE_REQUOTE: return "Requote";
            case TRADE_RETCODE_REJECT: return "Request rejected";
            case TRADE_RETCODE_CANCEL: return "Request canceled by trader";
            case TRADE_RETCODE_PLACED: return "Order placed";
            case TRADE_RETCODE_DONE_PARTIAL: return "Request completed partially";
            case TRADE_RETCODE_ERROR: return "Request processing error";
            case TRADE_RETCODE_TIMEOUT: return "Request canceled by timeout";
            case TRADE_RETCODE_INVALID: return "Invalid request";
            case TRADE_RETCODE_INVALID_VOLUME: return "Invalid volume in request";
            case TRADE_RETCODE_INVALID_PRICE: return "Invalid price in request";
            case TRADE_RETCODE_INVALID_STOPS: return "Invalid stops in request";
            case TRADE_RETCODE_TRADE_DISABLED: return "Trade disabled";
            case TRADE_RETCODE_MARKET_CLOSED: return "Market closed";
            case TRADE_RETCODE_NO_MONEY: return "Not enough money for request";
            case TRADE_RETCODE_PRICE_CHANGED: return "Prices changed";
            case TRADE_RETCODE_PRICE_OFF: return "No quotes to process request";
            case TRADE_RETCODE_INVALID_EXPIRATION: return "Invalid order expiration date";
            case TRADE_RETCODE_ORDER_CHANGED: return "Order state changed";
            case TRADE_RETCODE_TOO_MANY_REQUESTS: return "Too frequent requests";
            case TRADE_RETCODE_NO_CHANGES: return "No changes in request";
            case TRADE_RETCODE_SERVER_DISABLES_AT: return "Autotrading disabled by server";
            case TRADE_RETCODE_CLIENT_DISABLES_AT: return "Autotrading disabled by client terminal";
            case TRADE_RETCODE_LOCKED: return "Request locked for processing";
            case TRADE_RETCODE_FROZEN: return "Order or position frozen";
            case TRADE_RETCODE_INVALID_FILL: return "Invalid order filling type";
            case TRADE_RETCODE_CONNECTION: return "No connection with trade server";
            case TRADE_RETCODE_ONLY_REAL: return "Operation allowed only for real accounts";
            case TRADE_RETCODE_LIMIT_ORDERS: return "Orders limit reached";
            case TRADE_RETCODE_LIMIT_VOLUME: return "Volume limit reached";
            case TRADE_RETCODE_INVALID_ORDER: return "Invalid or prohibited order type";
            case TRADE_RETCODE_POSITION_CLOSED: return "Position specified has already been closed";
            default: return "Unknown error";
        }
    }
    
public:
    // Constructor
    CTradeManager(string symbol, int magicNumber) {
        m_symbol = symbol;
        m_magicNumber = magicNumber;
        
        // Set default values
        m_partialClosePercent = DEFAULT_PARTIAL_CLOSE;
        m_breakEvenLevel = DEFAULT_BE_LEVEL;
        m_trailingActivationR = DEFAULT_TRAILING_LEVEL;
        m_takeProfitMultiplier = DEFAULT_TP1_MULTIPLIER;
        m_maxRetryAttempts = DEFAULT_MAX_RETRY;
        m_retryDelayMs = DEFAULT_RETRY_DELAY;
        
        // SuperTrend defaults
        m_superTrendPeriod = DEFAULT_SUPERTREND_PERIOD;
        m_superTrendMultiplier = DEFAULT_SUPERTREND_MULT;
        m_superTrendHandle = INVALID_HANDLE;
        
        // Set logger to NULL initially
        m_logger = NULL;
    }
    
    // Destructor
    ~CTradeManager() {
        // Clean up
        if (m_superTrendHandle != INVALID_HANDLE) {
            IndicatorRelease(m_superTrendHandle);
            m_superTrendHandle = INVALID_HANDLE;
        }
    }
    
    // Initialize TradeManager
    bool Initialize() {
        // Initialize trade history array
        ArrayResize(m_tradeHistory, 0);
        
        // Initialize open trades array
        ArrayResize(m_openTrades, 0);
        
        // Sync with existing trades
        SyncExistingTrades();
        
        // Log initialization
        if (m_logger != NULL) {
            m_logger.Info("TradeManager initialized for " + m_symbol + 
                         " with magic number " + IntegerToString(m_magicNumber));
        }
        
        return true;
    }
    
    // Sync with existing trades
    void SyncExistingTrades() {
        // Temporary array for positions
        TradeRecord newTrades[];
        int positionsTotal = PositionsTotal();
        int count = 0;
        
        // Find all positions with our magic number and symbol
        for (int i = 0; i < positionsTotal; i++) {
            ulong ticket = PositionGetTicket(i);
            
            if (ticket > 0 && 
                PositionGetInteger(POSITION_MAGIC) == m_magicNumber && 
                PositionGetString(POSITION_SYMBOL) == m_symbol) {
                
                // Create trade record
                TradeRecord trade = CreateTradeRecord(ticket);
                
                // Check if this trade is already in our array
                bool found = false;
                for (int j = 0; j < ArraySize(m_openTrades); j++) {
                    if (m_openTrades[j].ticket == ticket) {
                        found = true;
                        break;
                    }
                }
                
                // If not found, add to new array
                if (!found) {
                    ArrayResize(newTrades, count + 1);
                    newTrades[count++] = trade;
                    
                    if (m_logger != NULL) {
                        m_logger.Info("Synced existing position #" + IntegerToString(ticket) + 
                                     " " + EnumToString(trade.positionType) + 
                                     " " + DoubleToString(trade.lots, 2) + 
                                     " " + trade.symbol);
                    }
                }
            }
        }
        
        // Combine arrays
        if (count > 0) {
            int oldSize = ArraySize(m_openTrades);
            ArrayResize(m_openTrades, oldSize + count);
            
            for (int i = 0; i < count; i++) {
                m_openTrades[oldSize + i] = newTrades[i];
            }
        }
        
        // Check for closed trades
        for (int i = ArraySize(m_openTrades) - 1; i >= 0; i--) {
            if (m_openTrades[i].isValid) {
                ulong ticket = m_openTrades[i].ticket;
                
                // Check if position still exists
                if (!PositionSelectByTicket(ticket)) {
                    m_openTrades[i].isValid = false;
                    
                    if (m_logger != NULL) {
                        m_logger.Info("Position #" + IntegerToString(ticket) + " no longer exists");
                    }
                }
            }
        }
        
        // Clean up trade array
        CleanupTradeArray();
    }
    
    // Execute a buy order
    bool ExecuteBuyOrder(double entryPrice, double stopLoss, double lotSize) {
        // Safety check
        if (lotSize <= 0) {
            if (m_logger != NULL) {
                m_logger.Error("Invalid lot size: " + DoubleToString(lotSize, 2));
            }
            return false;
        }
        
        // Calculate take profit
        double takeProfit = 0;
        if (stopLoss > 0 && m_takeProfitMultiplier > 0) {
            double riskPips = entryPrice - stopLoss;
            takeProfit = entryPrice + (riskPips * m_takeProfitMultiplier);
        }
        
        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = m_symbol;
        request.volume = lotSize;
        request.type = ORDER_TYPE_BUY;
        request.price = entryPrice;
        request.sl = stopLoss;
        request.tp = takeProfit;
        request.deviation = 10;
        request.magic = m_magicNumber;
        request.comment = "SonicR EA v3.0";
        request.type_filling = ORDER_FILLING_FOK;
        
        // Execute with retry
        bool success = ExecuteTradeWithRetry(request, result);
        
        if (success) {
            // Add to open trades array
            ulong ticket = result.deal;
            if (ticket > 0) {
                TradeRecord trade = CreateTradeRecord(ticket);
                
                // Set initial values
                trade.initialStopLoss = stopLoss;
                trade.initialTakeProfit = takeProfit;
                trade.initialRisk = entryPrice - stopLoss;
                trade.initialLots = lotSize;
                
                // Add to array
                int size = ArraySize(m_openTrades);
                ArrayResize(m_openTrades, size + 1);
                m_openTrades[size] = trade;
                
                if (m_logger != NULL) {
                    m_logger.Info("Buy order executed: Ticket #" + IntegerToString(ticket) + 
                                 " Lots: " + DoubleToString(lotSize, 2) + 
                                 " Entry: " + DoubleToString(entryPrice, _Digits) + 
                                 " SL: " + DoubleToString(stopLoss, _Digits) + 
                                 " TP: " + DoubleToString(takeProfit, _Digits));
                }
            }
        }
        
        return success;
    }
    
    // Execute a sell order
    bool ExecuteSellOrder(double entryPrice, double stopLoss, double lotSize) {
        // Safety check
        if (lotSize <= 0) {
            if (m_logger != NULL) {
                m_logger.Error("Invalid lot size: " + DoubleToString(lotSize, 2));
            }
            return false;
        }
        
        // Calculate take profit
        double takeProfit = 0;
        if (stopLoss > 0 && m_takeProfitMultiplier > 0) {
            double riskPips = stopLoss - entryPrice;
            takeProfit = entryPrice - (riskPips * m_takeProfitMultiplier);
        }
        
        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = m_symbol;
        request.volume = lotSize;
        request.type = ORDER_TYPE_SELL;
        request.price = entryPrice;
        request.sl = stopLoss;
        request.tp = takeProfit;
        request.deviation = 10;
        request.magic = m_magicNumber;
        request.comment = "SonicR EA v3.0";
        request.type_filling = ORDER_FILLING_FOK;
        
        // Execute with retry
        bool success = ExecuteTradeWithRetry(request, result);
        
        if (success) {
            // Add to open trades array
            ulong ticket = result.deal;
            if (ticket > 0) {
                TradeRecord trade = CreateTradeRecord(ticket);
                
                // Set initial values
                trade.initialStopLoss = stopLoss;
                trade.initialTakeProfit = takeProfit;
                trade.initialRisk = stopLoss - entryPrice;
                trade.initialLots = lotSize;
                
                // Add to array
                int size = ArraySize(m_openTrades);
                ArrayResize(m_openTrades, size + 1);
                m_openTrades[size] = trade;
                
                if (m_logger != NULL) {
                    m_logger.Info("Sell order executed: Ticket #" + IntegerToString(ticket) + 
                                 " Lots: " + DoubleToString(lotSize, 2) + 
                                 " Entry: " + DoubleToString(entryPrice, _Digits) + 
                                 " SL: " + DoubleToString(stopLoss, _Digits) + 
                                 " TP: " + DoubleToString(takeProfit, _Digits));
                }
            }
        }
        
        return success;
    }
    
    // Manage open trades
    void ManageOpenTrades() {
        // Sync with existing trades first
        SyncExistingTrades();
        
        // Loop through open trades
        for (int i = 0; i < ArraySize(m_openTrades); i++) {
            if (!m_openTrades[i].isValid) continue;
            
            // Select the position
            ulong ticket = m_openTrades[i].ticket;
            if (!PositionSelectByTicket(ticket)) continue;
            
            // Update trade record
            UpdateTradeRecord(i);
            
            // Calculate current R multiple
            double currentR = CalculateRMultiple(i);
            
            // 1. Check for breakeven
            if (!m_openTrades[i].breakEvenSet && currentR >= m_breakEvenLevel) {
                // Move to breakeven
                if (MoveToBreakeven(i)) {
                    m_openTrades[i].breakEvenSet = true;
                    m_openTrades[i].status = TRADE_STATUS_BREAKEVEN_SET;
                    
                    if (m_logger != NULL) {
                        m_logger.Info("Moved position #" + IntegerToString(ticket) + 
                                     " to breakeven at " + DoubleToString(currentR, 2) + "R");
                    }
                }
            }
            
            // 2. Check for partial close at TP1
            if (!m_openTrades[i].partialClosed && currentR >= m_takeProfitMultiplier) {
                // Partially close
                if (PartialClose(i)) {
                    m_openTrades[i].partialClosed = true;
                    m_openTrades[i].status = TRADE_STATUS_PARTIAL_CLOSED;
                    
                    if (m_logger != NULL) {
                        m_logger.Info("Partially closed position #" + IntegerToString(ticket) + 
                                     " at " + DoubleToString(currentR, 2) + "R");
                    }
                }
            }
            
            // 3. Check for trailing stop activation
            if (m_openTrades[i].partialClosed && !m_openTrades[i].trailingActive && 
                currentR >= m_trailingActivationR) {
                // Activate trailing stop
                if (SetTrailingStop(i)) {
                    m_openTrades[i].trailingActive = true;
                    m_openTrades[i].status = TRADE_STATUS_TRAILING_ACTIVE;
                    
                    if (m_logger != NULL) {
                        m_logger.Info("Activated trailing stop for position #" + IntegerToString(ticket) + 
                                     " at " + DoubleToString(currentR, 2) + "R");
                    }
                }
            }
            
            // 4. Update trailing stop if active
            if (m_openTrades[i].trailingActive) {
                SetTrailingStop(i);
            }
        }
    }
    
    // Close all positions for this symbol
    bool CloseAllPositions() {
        bool allClosed = true;
        
        // Loop through open trades
        for (int i = ArraySize(m_openTrades) - 1; i >= 0; i--) {
            if (m_openTrades[i].isValid) {
                // Try to close this position
                if (!ClosePosition(m_openTrades[i].ticket)) {
                    allClosed = false;
                }
            }
        }
        
        // Sync to make sure all trades are properly updated
        SyncExistingTrades();
        
        return allClosed;
    }
    
    // Close a specific position
    bool ClosePosition(ulong ticket) {
        // Select the position
        if (!PositionSelectByTicket(ticket)) return false;
        
        // Prepare trade request
        MqlTradeRequest request = {};
        MqlTradeResult result = {};
        
        request.action = TRADE_ACTION_DEAL;
        request.symbol = PositionGetString(POSITION_SYMBOL);
        request.volume = PositionGetDouble(POSITION_VOLUME);
        request.type = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                      ORDER_TYPE_SELL : ORDER_TYPE_BUY;
        request.position = ticket;
        request.price = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY ? 
                      SymbolInfoDouble(request.symbol, SYMBOL_BID) : 
                      SymbolInfoDouble(request.symbol, SYMBOL_ASK);
        request.deviation = 10;
        
        // Execute with retry
        bool success = ExecuteTradeWithRetry(request, result);
        
        if (success) {
            // Mark trade as invalid
            for (int i = 0; i < ArraySize(m_openTrades); i++) {
                if (m_openTrades[i].ticket == ticket) {
                    m_openTrades[i].isValid = false;
                    break;
                }
            }
            
            if (m_logger != NULL) {
                m_logger.Info("Closed position #" + IntegerToString(ticket) + 
                             " at " + DoubleToString(request.price, _Digits));
            }
        }
        
        return success;
    }
    
    //--- Setters
    
    // Set partial close percentage
    void SetPartialClosePercent(double percent) {
        m_partialClosePercent = MathMax(0.1, MathMin(0.9, percent));
    }
    
    // Set breakeven level
    void SetBreakEvenLevel(double level) {
        m_breakEvenLevel = MathMax(0.1, level);
    }
    
    // Set trailing activation level
    void SetTrailingActivationR(double level) {
        m_trailingActivationR = MathMax(0.1, level);
    }
    
    // Set take profit multiplier
    void SetTakeProfitMultiplier(double mult) {
        m_takeProfitMultiplier = MathMax(0.1, mult);
    }
    
    // Set max retry attempts
    void SetMaxRetryAttempts(int attempts) {
        m_maxRetryAttempts = MathMax(1, attempts);
    }
    
    // Set retry delay
    void SetRetryDelayMs(int delay) {
        m_retryDelayMs = MathMax(100, delay);
    }
    
    // Set SuperTrend parameters
    void SetSuperTrendParameters(int period, double multiplier) {
        m_superTrendPeriod = MathMax(1, period);
        m_superTrendMultiplier = MathMax(0.1, multiplier);
    }
    
    // Set logger reference
    void SetLogger(CLogger* logger) {
        m_logger = logger;
    }
    
    //--- Getters
    
    // Get number of open trades
    int GetOpenTradesCount() const {
        return ArraySize(m_openTrades);
    }
    
    // Get total lot size for open trades
    double GetTotalLotSize() const {
        double total = 0;
        
        for (int i = 0; i < ArraySize(m_openTrades); i++) {
            if (m_openTrades[i].isValid) {
                total += m_openTrades[i].lots;
            }
        }
        
        return total;
    }
    
    // Get open trades array
    void GetOpenTrades(TradeRecord &trades[]) {
        int size = ArraySize(m_openTrades);
        ArrayResize(trades, size);
        
        for (int i = 0; i < size; i++) {
            trades[i] = m_openTrades[i];
        }
    }
    
    // Get trade history array
    void GetTradeHistory(TradeCloseRecord &history[]) {
        int size = ArraySize(m_tradeHistory);
        ArrayResize(history, size);
        
        for (int i = 0; i < size; i++) {
            history[i] = m_tradeHistory[i];
        }
    }
    
    // Get total profit for open trades
    double GetTotalProfit() const {
        double total = 0;
        
        for (int i = 0; i < ArraySize(m_openTrades); i++) {
            if (m_openTrades[i].isValid) {
                // Select the position to get current profit
                if (PositionSelectByTicket(m_openTrades[i].ticket)) {
                    total += PositionGetDouble(POSITION_PROFIT);
                }
            }
        }
        
        return total;
    }
};