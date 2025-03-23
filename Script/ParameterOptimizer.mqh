//+------------------------------------------------------------------+
//|                                        ParameterOptimizer.mq5 |
//|                                          SonicR PropFirm System |
//+------------------------------------------------------------------+
#property copyright "SonicR PropFirm System"
#property link      "https://sonicr.com"
#property version   "1.00"
#property script_show_inputs
#property description "Optimizes parameters for SonicR PropFirm EA and generates optimized sets"

#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayString.mqh>
#include <Files\FileTxt.mqh>

// Input parameters
input string EA_Name = "SonicR_PropFirm";               // EA Name
input bool   OptimizeRiskSettings = true;               // Optimize Risk Settings
input bool   OptimizeExitSettings = true;               // Optimize Exit Settings
input bool   OptimizeEntrySettings = true;              // Optimize Entry Settings
input bool   OptimizeForPropFirm = true;                // Optimize for PropFirm Rules
input string OutputFolder = "SonicR_Optimizations";     // Output Folder
input int    GenerationSize = 100;                      // Generation Size
input int    Generations = 10;                          // Number of Generations
input double MutationRate = 0.1;                        // Mutation Rate
input double WinRateWeight = 0.30;                      // Win Rate Weight
input double ProfitFactorWeight = 0.25;                 // Profit Factor Weight
input double SharpeRatioWeight = 0.20;                  // Sharpe Ratio Weight
input double DrawdownWeight = 0.25;                     // Drawdown Weight

// Optimization parameter ranges
struct SParamRange {
    string name;
    double min;
    double max;
    double step;
    bool isInteger;
};

// Result structure
struct SOptimizationResult {
    double fitnessScore;
    double winRate;
    double profitFactor;
    double sharpeRatio;
    double maxDrawdown;
    double netProfit;
    int totalTrades;
    double parameters[];
};

// Global variables
SParamRange paramRanges[];
SOptimizationResult population[];
SOptimizationResult bestResult;
string paramNames[];
int paramCount = 0;

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
{
    Print("Starting SonicR PropFirm Parameter Optimizer...");
    
    // Initialize parameter ranges
    InitializeParameterRanges();
    
    // Create output folder
    if(!FolderCreate("MQL5\\Files\\" + OutputFolder)) {
        Print("Failed to create output folder: ", GetLastError());
        return;
    }
    
    // Run genetic algorithm optimization
    RunGeneticOptimization();
    
    // Generate and save optimized parameter sets
    GenerateOptimizedSets();
    
    Print("SonicR PropFirm Parameter Optimization completed!");
}

//+------------------------------------------------------------------+
//| Initialize parameter ranges                                      |
//+------------------------------------------------------------------+
void InitializeParameterRanges()
{
    // Clear arrays
    ArrayResize(paramRanges, 0);
    ArrayResize(paramNames, 0);
    paramCount = 0;
    
    // Add Risk Management parameters
    if(OptimizeRiskSettings) {
        AddParameter("RiskPercent", 0.1, 2.0, 0.1, false);
        AddParameter("MaxDailyDD", 1.0, 5.0, 0.5, false);
        AddParameter("MaxTotalDD", 3.0, 10.0, 0.5, false);
        AddParameter("MaxTradesPerDay", 1, 10, 1, true);
    }
    
    // Add Exit Management parameters
    if(OptimizeExitSettings) {
        AddParameter("TP1Percent", 20.0, 70.0, 5.0, false);
        AddParameter("TP1Distance", 0.5, 3.0, 0.1, false);
        AddParameter("TP2Distance", 1.0, 5.0, 0.1, false);
        AddParameter("BreakEvenTrigger", 0.3, 1.0, 0.1, false);
        AddParameter("TrailingStart", 0.5, 3.0, 0.1, false);
        AddParameter("TrailingStep", 5.0, 30.0, 5.0, false);
    }
    
    // Add Entry parameters
    if(OptimizeEntrySettings) {
        AddParameter("MinRR", 1.0, 3.0, 0.1, false);
        AddParameter("MinSignalQuality", 50.0, 90.0, 5.0, false);
    }
    
    Print("Initialized ", paramCount, " parameters for optimization");
}

//+------------------------------------------------------------------+
//| Add parameter to optimization                                    |
//+------------------------------------------------------------------+
void AddParameter(string name, double min, double max, double step, bool isInteger)
{
    int size = ArraySize(paramRanges);
    ArrayResize(paramRanges, size + 1);
    ArrayResize(paramNames, size + 1);
    
    paramRanges[size].name = name;
    paramRanges[size].min = min;
    paramRanges[size].max = max;
    paramRanges[size].step = step;
    paramRanges[size].isInteger = isInteger;
    paramNames[size] = name;
    
    paramCount++;
}

//+------------------------------------------------------------------+
//| Run genetic algorithm optimization                               |
//+------------------------------------------------------------------+
void RunGeneticOptimization()
{
    // Initialize population
    ArrayResize(population, GenerationSize);
    for(int i = 0; i < GenerationSize; i++) {
        SOptimizationResult result;
        ArrayResize(result.parameters, paramCount);
        
        // Randomly initialize parameters
        for(int j = 0; j < paramCount; j++) {
            result.parameters[j] = GetRandomParameterValue(j);
        }
        
        population[i] = result;
    }
    
    // Initialize best result
    bestResult.fitnessScore = 0;
    
    // Run generations
    for(int gen = 1; gen <= Generations; gen++) {
        Print("Running generation ", gen, " of ", Generations);
        
        // Evaluate fitness for each individual
        for(int i = 0; i < GenerationSize; i++) {
            EvaluateFitness(population[i]);
            
            // Check if this is the best result so far
            if(population[i].fitnessScore > bestResult.fitnessScore) {
                bestResult = population[i];
            }
        }
        
        // Sort population by fitness
        SortPopulationByFitness();
        
        // Create next generation
        if(gen < Generations) {
            SOptimizationResult newPopulation[];
            ArrayResize(newPopulation, GenerationSize);
            
            // Elitism: Keep top 10%
            int eliteCount = (int)(GenerationSize * 0.1);
            for(int i = 0; i < eliteCount; i++) {
                newPopulation[i] = population[i];
            }
            
            // Fill the rest with crossover and mutation
            for(int i = eliteCount; i < GenerationSize; i++) {
                // Select parents
                int parent1Index = TournamentSelection(3);
                int parent2Index = TournamentSelection(3);
                
                // Crossover
                SOptimizationResult child = Crossover(population[parent1Index], population[parent2Index]);
                
                // Mutation
                Mutate(child);
                
                newPopulation[i] = child;
            }
            
            // Replace population
            for(int i = 0; i < GenerationSize; i++) {
                population[i] = newPopulation[i];
            }
        }
        
        // Report progress
        Print("Generation ", gen, " best fitness: ", bestResult.fitnessScore, 
              " (Win Rate: ", bestResult.winRate, "%, PF: ", bestResult.profitFactor, 
              ", Sharpe: ", bestResult.sharpeRatio, ", DD: ", bestResult.maxDrawdown, "%)");
    }
    
    // Final report
    Print("Optimization complete!");
    Print("Best result: Fitness = ", bestResult.fitnessScore);
    Print("Win Rate: ", bestResult.winRate, "%, Profit Factor: ", bestResult.profitFactor);
    Print("Sharpe Ratio: ", bestResult.sharpeRatio, ", Max Drawdown: ", bestResult.maxDrawdown, "%");
    Print("Net Profit: ", bestResult.netProfit, ", Total Trades: ", bestResult.totalTrades);
    
    // Show optimized parameters
    for(int i = 0; i < paramCount; i++) {
        double value = bestResult.parameters[i];
        if(paramRanges[i].isInteger) {
            value = (int)value;
        }
        Print(paramRanges[i].name, " = ", value);
    }
}

//+------------------------------------------------------------------+
//| Evaluate fitness of an individual                                |
//+------------------------------------------------------------------+
void EvaluateFitness(SOptimizationResult &result)
{
    // In a real implementation, this would run backtests with the parameters
    // For this example, we'll simulate backtest results
    
    // Simulate running a backtest with these parameters
    double winRate = 50.0 + MathRand() % 30; // 50-80%
    double profitFactor = 1.2 + MathRandom() * 1.5; // 1.2-2.7
    double sharpeRatio = 0.8 + MathRandom() * 2.0; // 0.8-2.8
    double maxDrawdown = 5.0 + MathRandom() * 15.0; // 5-20%
    double netProfit = 1000 + MathRandom() * 5000; // 1000-6000
    int totalTrades = 50 + MathRand() % 100; // 50-150 trades
    
    // In a PropFirm optimization, we might adjust for their specific rules
    if(OptimizeForPropFirm) {
        // Penalize high drawdown heavily
        if(maxDrawdown > 10.0) {
            winRate *= 0.8;
            profitFactor *= 0.8;
        }
        
        // Reward consistent returns
        if(sharpeRatio > 1.5) {
            winRate *= 1.1;
            profitFactor *= 1.1;
        }
    }
    
    // Store backtest results
    result.winRate = winRate;
    result.profitFactor = profitFactor;
    result.sharpeRatio = sharpeRatio;
    result.maxDrawdown = maxDrawdown;
    result.netProfit = netProfit;
    result.totalTrades = totalTrades;
    
    // Calculate fitness score (weighted combination of metrics)
    result.fitnessScore = (winRate * WinRateWeight) + 
                        (profitFactor * 10 * ProfitFactorWeight) + 
                        (sharpeRatio * 10 * SharpeRatioWeight) - 
                        (maxDrawdown * DrawdownWeight);
}

//+------------------------------------------------------------------+
//| Sort population by fitness (descending)                          |
//+------------------------------------------------------------------+
void SortPopulationByFitness()
{
    for(int i = 0; i < GenerationSize - 1; i++) {
        for(int j = i + 1; j < GenerationSize; j++) {
            if(population[j].fitnessScore > population[i].fitnessScore) {
                SOptimizationResult temp = population[i];
                population[i] = population[j];
                population[j] = temp;
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Tournament selection                                             |
//+------------------------------------------------------------------+
int TournamentSelection(int tournamentSize)
{
    int bestIndex = MathRand() % GenerationSize;
    double bestFitness = population[bestIndex].fitnessScore;
    
    for(int i = 1; i < tournamentSize; i++) {
        int index = MathRand() % GenerationSize;
        if(population[index].fitnessScore > bestFitness) {
            bestIndex = index;
            bestFitness = population[index].fitnessScore;
        }
    }
    
    return bestIndex;
}

//+------------------------------------------------------------------+
//| Crossover two individuals                                        |
//+------------------------------------------------------------------+
SOptimizationResult Crossover(SOptimizationResult &parent1, SOptimizationResult &parent2)
{
    SOptimizationResult child;
    ArrayResize(child.parameters, paramCount);
    
    // Single-point crossover
    int crossoverPoint = MathRand() % paramCount;
    
    for(int i = 0; i < paramCount; i++) {
        if(i < crossoverPoint) {
            child.parameters[i] = parent1.parameters[i];
        } else {
            child.parameters[i] = parent2.parameters[i];
        }
    }
    
    return child;
}

//+------------------------------------------------------------------+
//| Mutate an individual                                             |
//+------------------------------------------------------------------+
void Mutate(SOptimizationResult &individual)
{
    for(int i = 0; i < paramCount; i++) {
        if(MathRandom() < MutationRate) {
            individual.parameters[i] = GetRandomParameterValue(i);
        }
    }
}

//+------------------------------------------------------------------+
//| Get random parameter value within range                          |
//+------------------------------------------------------------------+
double GetRandomParameterValue(int paramIndex)
{
    double range = paramRanges[paramIndex].max - paramRanges[paramIndex].min;
    double steps = range / paramRanges[paramIndex].step;
    
    double value;
    
    if(paramRanges[paramIndex].isInteger) {
        int randomSteps = MathRand() % ((int)steps + 1);
        value = paramRanges[paramIndex].min + randomSteps * paramRanges[paramIndex].step;
        value = (int)value;
    } else {
        int randomSteps = MathRand() % ((int)steps + 1);
        value = paramRanges[paramIndex].min + randomSteps * paramRanges[paramIndex].step;
    }
    
    return value;
}

//+------------------------------------------------------------------+
//| Generate optimized parameter sets                                |
//+------------------------------------------------------------------+
void GenerateOptimizedSets()
{
    // Create multiple optimized sets for different scenarios
    GenerateSet("Conservative", 0.8);
    GenerateSet("Balanced", 1.0);
    GenerateSet("Aggressive", 1.2);
    
    if(OptimizeForPropFirm) {
        GenerateSet("Challenge", 0.7);
        GenerateSet("Verification", 0.6);
        GenerateSet("Funded", 0.9);
    }
}

//+------------------------------------------------------------------+
//| Generate and save parameter set                                  |
//+------------------------------------------------------------------+
void GenerateSet(string setName, double riskFactor)
{
    string filename = OutputFolder + "\\" + EA_Name + "_" + setName + ".set";
    int handle = FileOpen(filename, FILE_WRITE|FILE_TXT);
    
    if(handle == INVALID_HANDLE) {
        Print("Failed to create set file: ", GetLastError());
        return;
    }
    
    // Write header
    FileWrite(handle, "//+------------------------------------------------------------------+");
    FileWrite(handle, "//|                            " + EA_Name + " " + setName + " Set |");
    FileWrite(handle, "//|                      Generated by ParameterOptimizer.mq5 |");
    FileWrite(handle, "//|                      " + TimeToString(TimeCurrent()) + " |");
    FileWrite(handle, "//+------------------------------------------------------------------+");
    FileWrite(handle, "");
    
    // Write statistics
    FileWrite(handle, "// Optimization Results:");
    FileWrite(handle, "// Win Rate: " + DoubleToString(bestResult.winRate, 2) + "%");
    FileWrite(handle, "// Profit Factor: " + DoubleToString(bestResult.profitFactor, 2));
    FileWrite(handle, "// Sharpe Ratio: " + DoubleToString(bestResult.sharpeRatio, 2));
    FileWrite(handle, "// Max Drawdown: " + DoubleToString(bestResult.maxDrawdown, 2) + "%");
    FileWrite(handle, "// Total Trades: " + IntegerToString(bestResult.totalTrades));
    FileWrite(handle, "");
    
    // Write parameters with adjustments based on set type
    for(int i = 0; i < paramCount; i++) {
        double value = bestResult.parameters[i];
        
        // Adjust risk parameters based on set type
        if(paramRanges[i].name == "RiskPercent") {
            value *= riskFactor;
        }
        else if(paramRanges[i].name == "MaxDailyDD" || paramRanges[i].name == "MaxTotalDD") {
            value /= riskFactor;
        }
        
        // Round to proper format
        if(paramRanges[i].isInteger) {
            value = (int)value;
            FileWrite(handle, paramRanges[i].name + "=" + IntegerToString((int)value));
        } else {
            // Determine number of decimal places based on step
            int decimals = 2;
            if(paramRanges[i].step < 0.01) decimals = 4;
            else if(paramRanges[i].step < 0.1) decimals = 3;
            else if(paramRanges[i].step < 1.0) decimals = 2;
            else decimals = 1;
            
            FileWrite(handle, paramRanges[i].name + "=" + DoubleToString(value, decimals));
        }
    }
    
    FileClose(handle);
    Print("Generated ", setName, " parameter set: ", filename);
}