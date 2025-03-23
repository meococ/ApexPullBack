//+------------------------------------------------------------------+
//|                                      PropAccount_Analyzer.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm System"
#property link      "https://sonicr.com"
#property version   "1.00"
#property script_show_inputs
#property description "Analyzes PropFirm account conditions and generates a report"

// Input parameters
input string LogoURL = "";                 // URL to PropFirm Logo (optional)
input string PropFirmName = "FTMO";        // PropFirm Name
input double TargetProfitPercent = 10.0;   // Target Profit (%)
input double MaxDrawdownLimit = 10.0;      // Max Drawdown Limit (%)
input double DailyDrawdownLimit = 5.0;     // Daily Drawdown Limit (%)
input int ChallengeLength = 30;            // Challenge Length (days)
input int MinTradingDays = 10;             // Minimum Trading Days
input bool WeekendHoldsPositions = false;  // Weekend Holds Positions
input double AccountCommission = 0.0;      // Account Commission per Lot
input double AccountSwapMultiplier = 1.0;  // Account Swap Multiplier

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    // Get account information
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double margin = AccountInfoDouble(ACCOUNT_MARGIN);
    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string currency = AccountInfoString(ACCOUNT_CURRENCY);
    
    // Calculate key metrics
    double currentProfit = equity - balance;
    double currentProfitPercent = balance > 0 ? (currentProfit / balance * 100) : 0;
    double marginLevel = margin > 0 ? (equity / margin * 100) : 0;
    
    // Get trading history statistics
    int totalTrades = 0;
    int winTrades = 0;
    int lossTrades = 0;
    double totalProfit = 0;
    double totalLoss = 0;
    double maxConsecutiveWins = 0;
    double maxConsecutiveLosses = 0;
    double currentDD = 0;
    double maxDD = 0;
    double peakBalance = balance;
    double averageWin = 0;
    double averageLoss = 0;
    
    // Calculate days left in challenge
    MqlDateTime today;
    TimeToStruct(TimeCurrent(), today);
    int daysElapsed = 0; // Would need account history to determine
    int daysLeft = ChallengeLength - daysElapsed;
    
    // Calculate required daily profit
    double requiredProfit = balance * (TargetProfitPercent / 100);
    double currentDailyProfit = daysElapsed > 0 ? (currentProfit / daysElapsed) : 0;
    double requiredDailyProfit = daysLeft > 0 ? ((requiredProfit - currentProfit) / daysLeft) : 0;
    double requiredDailyPercent = balance > 0 ? (requiredDailyProfit / balance * 100) : 0;
    
    // Generate report
    string report = 
        "\n------ " + PropFirmName + " Account Analysis ------" +
        "\n" +
        "\nAccount Balance: " + DoubleToString(balance, 2) + " " + currency +
        "\nAccount Equity: " + DoubleToString(equity, 2) + " " + currency +
        "\nCurrent Profit: " + DoubleToString(currentProfit, 2) + " " + currency + " (" + DoubleToString(currentProfitPercent, 2) + "%)" +
        "\nMargin Level: " + DoubleToString(marginLevel, 2) + "%" +
        "\n" +
        "\n------ Challenge Status ------" +
        "\n" +
        "\nTarget Profit: " + DoubleToString(TargetProfitPercent, 2) + "% (" + DoubleToString(requiredProfit, 2) + " " + currency + ")" +
        "\nProgress: " + DoubleToString(currentProfitPercent / TargetProfitPercent * 100, 2) + "% of target" +
        "\nMax Drawdown Limit: " + DoubleToString(MaxDrawdownLimit, 2) + "%" +
        "\nDaily Drawdown Limit: " + DoubleToString(DailyDrawdownLimit, 2) + "%" +
        "\n" +
        "\nDays Elapsed: " + IntegerToString(daysElapsed) +
        "\nDays Remaining: " + IntegerToString(daysLeft) +
        "\nRequired Daily Profit: " + DoubleToString(requiredDailyProfit, 2) + " " + currency + " (" + DoubleToString(requiredDailyPercent, 2) + "%)" +
        "\n" +
        "\n------ Recommendations ------" +
        "\n";
    
    // Add recommendations based on account state
    if(currentProfitPercent < 0) {
        report += "\n1. CAUTION: Account is currently in loss. Consider reducing position sizes.";
    }
    
    if(currentProfitPercent / TargetProfitPercent < 0.5 && daysElapsed > ChallengeLength / 2) {
        report += "\n2. WARNING: You are behind schedule to reach profit target. Consider adjusting strategy.";
    }
    
    if(requiredDailyPercent > 1.0) {
        report += "\n3. ALERT: Required daily profit is high (>1%). Focus on capital preservation and consistent trading.";
    }
    
    if(marginLevel < 500) {
        report += "\n4. WARNING: Margin level is low. Consider reducing open positions to avoid margin call.";
    }
    
    // Print report
    Print(report);
    Comment(report);
    
    // Create visual report window (would require custom UI implementation)
    MessageBox("PropFirm Account Analysis Complete!\n\nSee detailed report in Experts tab.", "SonicR PropFirm Analyzer", MB_OK);
}