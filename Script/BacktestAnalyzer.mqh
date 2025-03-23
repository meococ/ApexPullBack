//+------------------------------------------------------------------+
//|                                          BacktestAnalyzer.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm System"
#property link      "https://sonicr.com"
#property version   "1.00"
#property script_show_inputs
#property description "Analyzes backtest results for SonicR PropFirm EA and generates reports"

#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayString.mqh>
#include <Charts\Chart.mqh>
#include <Files\FileTxt.mqh>

// Input parameters
input string ReportTitle = "SonicR PropFirm Backtest Analysis";  // Report Title
input string ReportFolder = "SonicR_Reports";                    // Report Folder
input bool   IncludeTradeDetails = true;                         // Include Trade Details
input bool   GenerateCharts = true;                              // Generate Performance Charts
input bool   SaveToFile = true;                                  // Save Report to File
input int    MinTradesForAnalysis = 30;                          // Min Trades for Valid Analysis

// Analysis parameters
struct STradeData {
    int ticket;
    datetime openTime;
    datetime closeTime;
    int type;               // 0=buy, 1=sell
    double lots;
    double openPrice;
    double closePrice;
    double stopLoss;
    double takeProfit;
    double profit;
    double pips;
    double riskReward;
    int dayOfWeek;
    int hour;
    int holdTimeHours;
    string symbol;
    string comment;
};

// Global variables
CArrayDouble profitArray;
CArrayDouble drawdownArray;
CArrayDouble balanceArray;
CArrayDouble timeArray;
CArrayString tradeResultLabels;
STradeData trades[];
int totalTrades = 0;
double initialBalance = 0;
double finalBalance = 0;
double maxDrawdown = 0;
double profitFactor = 0;
double winRate = 0;
double averageWin = 0;
double averageLoss = 0;
double averageTradeResult = 0;
double maxConsecutiveWins = 0;
double maxConsecutiveLosses = 0;
double sharpeRatio = 0;
double sortinoRatio = 0;
double calmarRatio = 0;
MqlDateTime startDate, endDate;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("Starting SonicR PropFirm Backtest Analysis...");
    
    // Check if Tester is running
    if(!MQLInfoInteger(MQL_TESTER)) {
        MessageBox("This script must be run in the Strategy Tester!", "Error", MB_ICONERROR);
        return;
    }
    
    // Create folders if needed
    if(SaveToFile) {
        string folderPath = "MQL5\\Files\\" + ReportFolder;
        if(!FolderCreate(folderPath)) {
            Print("Failed to create report folder: ", GetLastError());
            SaveToFile = false;
        }
    }
    
    // Initialize arrays
    ArrayResize(trades, 0);
    profitArray.Clear();
    drawdownArray.Clear();
    balanceArray.Clear();
    timeArray.Clear();
    tradeResultLabels.Clear();
    
    // Get initial balance
    initialBalance = TesterStatistics(STAT_INITIAL_DEPOSIT);
    
    // Load trade history
    LoadTradeHistory();
    
    // If not enough trades, exit
    if(totalTrades < MinTradesForAnalysis) {
        MessageBox("Not enough trades for analysis. Minimum required: " + 
                  IntegerToString(MinTradesForAnalysis) + ", Found: " + 
                  IntegerToString(totalTrades), "Warning", MB_ICONWARNING);
        return;
    }
    
    // Perform analysis
    AnalyzeResults();
    
    // Show dashboard
    ShowDashboard();
    
    // Generate and save report
    if(SaveToFile) {
        GenerateReport();
    }
    
    Print("SonicR PropFirm Backtest Analysis completed successfully!");
}

//+------------------------------------------------------------------+
//| Load trade history from tester                                   |
//+------------------------------------------------------------------+
void LoadTradeHistory()
{
    // Get trade history
    HistorySelect(0, TimeCurrent());
    int historyTotal = HistoryDealsTotal();
    
    // Initialize variables for tracking deals
    ulong prevPositionID = 0;
    STradeData currentTrade;
    ResetTradeData(currentTrade);
    
    double balance = initialBalance;
    double maxBalance = balance;
    double currentDrawdown = 0;
    
    MqlDateTime dt;
    
    // Loop through all deals in history
    for(int i = 0; i < historyTotal; i++) {
        ulong dealTicket = HistoryDealGetTicket(i);
        if(dealTicket == 0) continue;
        
        // Get deal properties
        ulong positionID = HistoryDealGetInteger(dealTicket, DEAL_POSITION_ID);
        int dealType = (int)HistoryDealGetInteger(dealTicket, DEAL_TYPE);
        double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
        double dealVolume = HistoryDealGetDouble(dealTicket, DEAL_VOLUME);
        double dealPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
        datetime dealTime = (datetime)HistoryDealGetInteger(dealTicket, DEAL_TIME);
        string dealComment = HistoryDealGetString(dealTicket, DEAL_COMMENT);
        string dealSymbol = HistoryDealGetString(dealTicket, DEAL_SYMBOL);
        
        // Skip non-trade deals
        if(dealType != DEAL_TYPE_BUY && dealType != DEAL_TYPE_SELL) continue;
        
        // New position
        if(positionID != prevPositionID) {
            // Save previous position if valid
            if(currentTrade.ticket != 0) {
                trades = ArrayAppend(trades, currentTrade);
                totalTrades++;
            }
            
            // Start tracking new position
            ResetTradeData(currentTrade);
            currentTrade.ticket = (int)positionID;
            currentTrade.openTime = dealTime;
            currentTrade.type = (dealType == DEAL_TYPE_BUY) ? 0 : 1;
            currentTrade.lots = dealVolume;
            currentTrade.openPrice = dealPrice;
            currentTrade.symbol = dealSymbol;
            
            // Extract SL/TP from comment if possible
            if(StringLen(dealComment) > 0) {
                currentTrade.comment = dealComment;
                // Parse comment for SL/TP here if needed
            }
            
            // Record day of week and hour
            TimeToStruct(dealTime, dt);
            currentTrade.dayOfWeek = dt.day_of_week;
            currentTrade.hour = dt.hour;
            
            prevPositionID = positionID;
        }
        // Position closed
        else if(dealType == DEAL_TYPE_BUY || dealType == DEAL_TYPE_SELL) {
            currentTrade.closeTime = dealTime;
            currentTrade.closePrice = dealPrice;
            currentTrade.profit = dealProfit;
            
            // Calculate pips (approximation)
            double pips = 0;
            if(currentTrade.type == 0) { // Buy
                pips = (currentTrade.closePrice - currentTrade.openPrice) / _Point;
            } else { // Sell
                pips = (currentTrade.openPrice - currentTrade.closePrice) / _Point;
            }
            currentTrade.pips = pips / 10; // Convert to standard 5-digit pips
            
            // Calculate holding time in hours
            currentTrade.holdTimeHours = (int)((currentTrade.closeTime - currentTrade.openTime) / 3600);
            
            // Update balance and drawdown
            balance += currentTrade.profit;
            
            // Add to arrays for charts
            balanceArray.Add(balance);
            profitArray.Add(currentTrade.profit);
            timeArray.Add((double)currentTrade.closeTime);
            
            // Update max balance and drawdown
            if(balance > maxBalance) {
                maxBalance = balance;
                currentDrawdown = 0;
            } else {
                currentDrawdown = (maxBalance - balance) / maxBalance * 100;
                drawdownArray.Add(currentDrawdown);
                if(currentDrawdown > maxDrawdown) {
                    maxDrawdown = currentDrawdown;
                }
            }
            
            // Add label
            string label = currentTrade.profit > 0 ? "Win" : "Loss";
            tradeResultLabels.Add(label);
        }
    }
    
    // Add last trade if still open
    if(currentTrade.ticket != 0 && currentTrade.closeTime == 0) {
        currentTrade.closeTime = TimeCurrent();
        currentTrade.profit = 0; // Assuming flat for open positions
        trades = ArrayAppend(trades, currentTrade);
        totalTrades++;
    }
    
    // Set final balance
    finalBalance = balance;
    
    // Set date range
    if(totalTrades > 0) {
        TimeToStruct(trades[0].openTime, startDate);
        TimeToStruct(trades[totalTrades-1].closeTime, endDate);
    }
}

//+------------------------------------------------------------------+
//| Analyze backtest results                                         |
//+------------------------------------------------------------------+
void AnalyzeResults()
{
    if(totalTrades == 0) return;
    
    int winCount = 0;
    int lossCount = 0;
    double totalWinAmount = 0;
    double totalLossAmount = 0;
    double totalProfit = 0;
    int consecutiveWins = 0;
    int consecutiveLosses = 0;
    int maxConsWins = 0;
    int maxConsLosses = 0;
    double dailyReturns[];
    double riskFreeRate = 0.02 / 252; // 2% annual risk-free rate converted to daily
    
    // Initialize arrays for daily returns
    datetime currentDay = 0;
    double dailyPL = 0;
    
    // Process each trade
    for(int i = 0; i < totalTrades; i++) {
        // Win/loss statistics
        if(trades[i].profit > 0) {
            winCount++;
            totalWinAmount += trades[i].profit;
            consecutiveWins++;
            consecutiveLosses = 0;
            if(consecutiveWins > maxConsWins) maxConsWins = consecutiveWins;
        } 
        else if(trades[i].profit < 0) {
            lossCount++;
            totalLossAmount += MathAbs(trades[i].profit);
            consecutiveLosses++;
            consecutiveWins = 0;
            if(consecutiveLosses > maxConsLosses) maxConsLosses = consecutiveLosses;
        }
        
        // Total profit
        totalProfit += trades[i].profit;
        
        // Daily returns processing
        MqlDateTime tradeTime;
        TimeToStruct(trades[i].closeTime, tradeTime);
        
        // New day - restart daily PL
        if(currentDay == 0) {
            currentDay = trades[i].closeTime;
            dailyPL = trades[i].profit;
        } 
        else if(tradeTime.day != TimeDay(currentDay) || tradeTime.mon != TimeMonth(currentDay) || tradeTime.year != TimeYear(currentDay)) {
            // Add previous day's return
            double previousBalance = initialBalance;
            for(int j = 0; j < ArraySize(dailyReturns); j++) {
                previousBalance += dailyReturns[j];
            }
            double dailyReturn = dailyPL / previousBalance;
            ArrayResize(dailyReturns, ArraySize(dailyReturns) + 1);
            dailyReturns[ArraySize(dailyReturns) - 1] = dailyReturn;
            
            // Reset for new day
            currentDay = trades[i].closeTime;
            dailyPL = trades[i].profit;
        } 
        else {
            // Add to current day's PL
            dailyPL += trades[i].profit;
        }
    }
    
    // Add the last day if needed
    if(dailyPL != 0) {
        double previousBalance = initialBalance;
        for(int j = 0; j < ArraySize(dailyReturns); j++) {
            previousBalance += dailyReturns[j];
        }
        double dailyReturn = dailyPL / previousBalance;
        ArrayResize(dailyReturns, ArraySize(dailyReturns) + 1);
        dailyReturns[ArraySize(dailyReturns) - 1] = dailyReturn;
    }
    
    // Calculate statistics
    winRate = (double)winCount / totalTrades * 100;
    averageWin = winCount > 0 ? totalWinAmount / winCount : 0;
    averageLoss = lossCount > 0 ? totalLossAmount / lossCount : 0;
    averageTradeResult = totalProfit / totalTrades;
    maxConsecutiveWins = maxConsWins;
    maxConsecutiveLosses = maxConsLosses;
    profitFactor = totalLossAmount > 0 ? totalWinAmount / totalLossAmount : 0;
    
    // Calculate Sharpe Ratio
    if(ArraySize(dailyReturns) > 0) {
        double meanReturn = 0;
        double stdDevReturn = 0;
        
        // Calculate mean
        for(int i = 0; i < ArraySize(dailyReturns); i++) {
            meanReturn += dailyReturns[i];
        }
        meanReturn /= ArraySize(dailyReturns);
        
        // Calculate standard deviation
        for(int i = 0; i < ArraySize(dailyReturns); i++) {
            stdDevReturn += MathPow(dailyReturns[i] - meanReturn, 2);
        }
        stdDevReturn = MathSqrt(stdDevReturn / ArraySize(dailyReturns));
        
        // Calculate Sharpe Ratio
        if(stdDevReturn > 0) {
            sharpeRatio = (meanReturn - riskFreeRate) / stdDevReturn * MathSqrt(252); // Annualized
        }
        
        // Calculate Sortino Ratio (only negative returns for denominator)
        double sumNegativeSquared = 0;
        int negativeCount = 0;
        
        for(int i = 0; i < ArraySize(dailyReturns); i++) {
            if(dailyReturns[i] < 0) {
                sumNegativeSquared += MathPow(dailyReturns[i], 2);
                negativeCount++;
            }
        }
        
        double downwardDeviation = negativeCount > 0 ? MathSqrt(sumNegativeSquared / negativeCount) : 0;
        
        if(downwardDeviation > 0) {
            sortinoRatio = (meanReturn - riskFreeRate) / downwardDeviation * MathSqrt(252); // Annualized
        }
        
        // Calculate Calmar Ratio
        if(maxDrawdown > 0) {
            double annualizedReturn = totalProfit / initialBalance * 252 / ArraySize(dailyReturns);
            calmarRatio = annualizedReturn / (maxDrawdown / 100);
        }
    }
}

//+------------------------------------------------------------------+
//| Show analysis dashboard                                          |
//+------------------------------------------------------------------+
void ShowDashboard()
{
    string stats = 
        "\n--------------------------------------------------" +
        "\n      SonicR PropFirm Backtest Analysis Report    " +
        "\n--------------------------------------------------" +
        "\n" +
        "\nTest Period: " + TimeToString(StructToTime(startDate)) + " to " + TimeToString(StructToTime(endDate)) +
        "\nTotal Trades: " + IntegerToString(totalTrades) +
        "\nInitial Balance: " + DoubleToString(initialBalance, 2) +
        "\nFinal Balance: " + DoubleToString(finalBalance, 2) +
        "\nNet Profit: " + DoubleToString(finalBalance - initialBalance, 2) + " (" + DoubleToString((finalBalance - initialBalance) / initialBalance * 100, 2) + "%)" +
        "\nMax Drawdown: " + DoubleToString(maxDrawdown, 2) + "%" +
        "\n" +
        "\nWin Rate: " + DoubleToString(winRate, 2) + "%" +
        "\nProfit Factor: " + DoubleToString(profitFactor, 2) +
        "\nAverage Win: " + DoubleToString(averageWin, 2) +
        "\nAverage Loss: " + DoubleToString(averageLoss, 2) +
        "\nAverage Trade: " + DoubleToString(averageTradeResult, 2) +
        "\nMax Consecutive Wins: " + DoubleToString(maxConsecutiveWins, 0) +
        "\nMax Consecutive Losses: " + DoubleToString(maxConsecutiveLosses, 0) +
        "\n" +
        "\nSharpe Ratio: " + DoubleToString(sharpeRatio, 2) +
        "\nSortino Ratio: " + DoubleToString(sortinoRatio, 2) +
        "\nCalmar Ratio: " + DoubleToString(calmarRatio, 2) +
        "\n--------------------------------------------------";
    
    Print(stats);
    Comment(stats);
    
    if(GenerateCharts) {
        CreatePerformanceCharts();
    }
}

//+------------------------------------------------------------------+
//| Generate report file                                             |
//+------------------------------------------------------------------+
void GenerateReport()
{
    string filename = ReportFolder + "\\" + ReportTitle + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".html";
    int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
    
    if(handle == INVALID_HANDLE) {
        Print("Failed to create report file: ", GetLastError());
        return;
    }
    
    // HTML Header
    FileWrite(handle, "<!DOCTYPE html>");
    FileWrite(handle, "<html lang='en'>");
    FileWrite(handle, "<head>");
    FileWrite(handle, "  <meta charset='UTF-8'>");
    FileWrite(handle, "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>");
    FileWrite(handle, "  <title>" + ReportTitle + "</title>");
    FileWrite(handle, "  <style>");
    FileWrite(handle, "    body { font-family: Arial, sans-serif; margin: 20px; }");
    FileWrite(handle, "    .header { text-align: center; margin-bottom: 20px; }");
    FileWrite(handle, "    .section { margin-bottom: 30px; }");
    FileWrite(handle, "    .summary-box { border: 1px solid #ddd; padding: 15px; margin-bottom: 20px; border-radius: 5px; }");
    FileWrite(handle, "    .stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }");
    FileWrite(handle, "    .stat-item { padding: 10px; border: 1px solid #eee; border-radius: 4px; }");
    FileWrite(handle, "    .stat-name { font-weight: bold; color: #555; }");
    FileWrite(handle, "    .stat-value { font-size: 1.2em; color: #333; }");
    FileWrite(handle, "    .positive { color: green; }");
    FileWrite(handle, "    .negative { color: red; }");
    FileWrite(handle, "    table { width: 100%; border-collapse: collapse; }");
    FileWrite(handle, "    th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }");
    FileWrite(handle, "    th { background-color: #f2f2f2; }");
    FileWrite(handle, "  </style>");
    FileWrite(handle, "</head>");
    FileWrite(handle, "<body>");
    
    // Report Header
    FileWrite(handle, "  <div class='header'>");
    FileWrite(handle, "    <h1>" + ReportTitle + "</h1>");
    FileWrite(handle, "    <p>Generated on " + TimeToString(TimeCurrent()) + "</p>");
    FileWrite(handle, "  </div>");
    
    // Test Information
    FileWrite(handle, "  <div class='section'>");
    FileWrite(handle, "    <h2>Test Information</h2>");
    FileWrite(handle, "    <div class='summary-box'>");
    FileWrite(handle, "      <p><strong>Period:</strong> " + TimeToString(StructToTime(startDate)) + " to " + TimeToString(StructToTime(endDate)) + "</p>");
    FileWrite(handle, "      <p><strong>Symbol:</strong> " + _Symbol + "</p>");
    FileWrite(handle, "      <p><strong>Timeframe:</strong> " + EnumToString((ENUM_TIMEFRAMES)Period()) + "</p>");
    FileWrite(handle, "    </div>");
    FileWrite(handle, "  </div>");
    
    // Performance Summary
    FileWrite(handle, "  <div class='section'>");
    FileWrite(handle, "    <h2>Performance Summary</h2>");
    FileWrite(handle, "    <div class='stat-grid'>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Total Trades</div>");
    FileWrite(handle, "        <div class='stat-value'>" + IntegerToString(totalTrades) + "</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Net Profit</div>");
    string profitClass = finalBalance > initialBalance ? "positive" : "negative";
    FileWrite(handle, "        <div class='stat-value " + profitClass + "'>" + DoubleToString(finalBalance - initialBalance, 2) + " (" + DoubleToString((finalBalance - initialBalance) / initialBalance * 100, 2) + "%)</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Max Drawdown</div>");
    FileWrite(handle, "        <div class='stat-value negative'>" + DoubleToString(maxDrawdown, 2) + "%</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Win Rate</div>");
    FileWrite(handle, "        <div class='stat-value'>" + DoubleToString(winRate, 2) + "%</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Profit Factor</div>");
    FileWrite(handle, "        <div class='stat-value'>" + DoubleToString(profitFactor, 2) + "</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "      <div class='stat-item'>");
    FileWrite(handle, "        <div class='stat-name'>Sharpe Ratio</div>");
    FileWrite(handle, "        <div class='stat-value'>" + DoubleToString(sharpeRatio, 2) + "</div>");
    FileWrite(handle, "      </div>");
    FileWrite(handle, "    </div>");
    FileWrite(handle, "  </div>");
    
    // Detailed Statistics
    FileWrite(handle, "  <div class='section'>");
    FileWrite(handle, "    <h2>Detailed Statistics</h2>");
    FileWrite(handle, "    <table>");
    FileWrite(handle, "      <tr><th>Metric</th><th>Value</th></tr>");
    FileWrite(handle, "      <tr><td>Initial Balance</td><td>" + DoubleToString(initialBalance, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Final Balance</td><td>" + DoubleToString(finalBalance, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Average Win</td><td>" + DoubleToString(averageWin, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Average Loss</td><td>" + DoubleToString(averageLoss, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Average Trade</td><td>" + DoubleToString(averageTradeResult, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Max Consecutive Wins</td><td>" + DoubleToString(maxConsecutiveWins, 0) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Max Consecutive Losses</td><td>" + DoubleToString(maxConsecutiveLosses, 0) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Sortino Ratio</td><td>" + DoubleToString(sortinoRatio, 2) + "</td></tr>");
    FileWrite(handle, "      <tr><td>Calmar Ratio</td><td>" + DoubleToString(calmarRatio, 2) + "</td></tr>");
    FileWrite(handle, "    </table>");
    FileWrite(handle, "  </div>");
    
    // Trade List
    if(IncludeTradeDetails) {
        FileWrite(handle, "  <div class='section'>");
        FileWrite(handle, "    <h2>Trade List</h2>");
        FileWrite(handle, "    <table>");
        FileWrite(handle, "      <tr><th>#</th><th>Open Time</th><th>Type</th><th>Lots</th><th>Open Price</th><th>Close Price</th><th>Profit</th><th>Pips</th></tr>");
        
        for(int i = 0; i < totalTrades; i++) {
            string type = trades[i].type == 0 ? "Buy" : "Sell";
            string profitClass = trades[i].profit > 0 ? "positive" : (trades[i].profit < 0 ? "negative" : "");
            
            FileWrite(handle, "      <tr>");
            FileWrite(handle, "        <td>" + IntegerToString(i+1) + "</td>");
            FileWrite(handle, "        <td>" + TimeToString(trades[i].openTime) + "</td>");
            FileWrite(handle, "        <td>" + type + "</td>");
            FileWrite(handle, "        <td>" + DoubleToString(trades[i].lots, 2) + "</td>");
            FileWrite(handle, "        <td>" + DoubleToString(trades[i].openPrice, _Digits) + "</td>");
            FileWrite(handle, "        <td>" + DoubleToString(trades[i].closePrice, _Digits) + "</td>");
            FileWrite(handle, "        <td class='" + profitClass + "'>" + DoubleToString(trades[i].profit, 2) + "</td>");
            FileWrite(handle, "        <td>" + DoubleToString(trades[i].pips, 1) + "</td>");
            FileWrite(handle, "      </tr>");
        }
        
        FileWrite(handle, "    </table>");
        FileWrite(handle, "  </div>");
    }
    
    // HTML Footer
    FileWrite(handle, "  <div class='footer'>");
    FileWrite(handle, "    <p>SonicR PropFirm System - Report generated by BacktestAnalyzer</p>");
    FileWrite(handle, "  </div>");
    FileWrite(handle, "</body>");
    FileWrite(handle, "</html>");
    
    FileClose(handle);
    
    Print("Report saved to: ", filename);
}

//+------------------------------------------------------------------+
//| Create performance charts                                        |
//+------------------------------------------------------------------+
void CreatePerformanceCharts()
{
    // Implementation would require custom charts
    // In a real scenario, we would use ChartCreate and related functions
    // But for simplicity, this is left as a placeholder
    Print("Performance charts would be created here in a real implementation");
}

//+------------------------------------------------------------------+
//| Reset trade data                                                 |
//+------------------------------------------------------------------+
void ResetTradeData(STradeData &trade)
{
    trade.ticket = 0;
    trade.openTime = 0;
    trade.closeTime = 0;
    trade.type = -1;
    trade.lots = 0;
    trade.openPrice = 0;
    trade.closePrice = 0;
    trade.stopLoss = 0;
    trade.takeProfit = 0;
    trade.profit = 0;
    trade.pips = 0;
    trade.riskReward = 0;
    trade.dayOfWeek = 0;
    trade.hour = 0;
    trade.holdTimeHours = 0;
    trade.symbol = "";
    trade.comment = "";
}

//+------------------------------------------------------------------+
//| Append element to trade array                                    |
//+------------------------------------------------------------------+
STradeData[] ArrayAppend(STradeData &array[], STradeData &element)
{
    int size = ArraySize(array);
    ArrayResize(array, size + 1);
    array[size] = element;
    return array;
}

//+------------------------------------------------------------------+
//| Convert MqlDateTime structure to datetime                        |
//+------------------------------------------------------------------+
datetime StructToTime(MqlDateTime &dt)
{
    return StringToTime(StringFormat("%04d.%02d.%02d %02d:%02d:%02d", 
                                    dt.year, dt.mon, dt.day, 
                                    dt.hour, dt.min, dt.sec));
}