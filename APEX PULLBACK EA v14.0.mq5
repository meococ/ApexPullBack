//+------------------------------------------------------------------+
//|   APEX PULLBACK EA v14.0 - Professional Edition                  |
//|   Module hóa xuất sắc - Quản lý rủi ro - EA chuẩn Prop   |
//|   Copyright 2025, APEX Forex - Mèo Cọc                           |
//+------------------------------------------------------------------+

// === CORE PROJECT INCLUDES (ORDER IS CRITICAL) ===
#include "MQLIncludes.mqh"          // 1. Standard MQL5 libraries (e.g., Trade.mqh, SymbolInfo.mqh)
#include "Enums.mqh"                // 2. All enumerations for type safety and clarity
#include "Inputs.mqh"               // 3. Unified constants and input parameters
#include "CommonStructs.mqh"        // 4. All structs, including the central EAContext (depends on Enums)

// === UTILITY & HELPER MODULES (Provide foundational functionalities) ===
#include "Logger.mqh"               // For logging messages and debugging
#include "MathHelper.mqh"           // Mathematical utility functions
#include "SafeDataProvider.mqh"     // For safe access to market data
#include "ChartObjectWrapper.mqh"   // Wrapper for easy chart object manipulation
#include "FunctionDefinitions.mqh"  // Common function definitions
#include "IndicatorUtils.mqh"       // Utilities for managing MQL5 indicators

// === MARKET ANALYSIS MODULES (Interpret market conditions) ===
#include "MarketProfile.mqh"        // Analyzes market profile data
#include "SwingPointDetector.mqh"   // Detects swing points in price action
#include "PatternDetector.mqh"      // Identifies chart patterns

// === CORE MANAGEMENT MODULES (Handle operational aspects of trading) ===
#include "RiskManager.mqh"          // Manages risk parameters and exposure
#include "PositionManager.mqh"      // Manages open positions
#include "TradeManager.mqh"         // Executes and manages trades
#include "SessionManager.mqh"       // Manages trading sessions
#include "NewsFilter.mqh"           // Filters trades based on news events
#include "FileCommunication.mqh"    // Handles communication via files (e.g., for inter-EA comms)

// === STRATEGIC & OPTIMIZATION MODULES (Implement trading logic and performance enhancement) ===
#include "AssetDNA.mqh"             // Core logic for asset analysis and strategy selection
#include "PortfolioManager.mqh"     // Manages a portfolio of assets/strategies
#include "RiskOptimizer.mqh"        // Optimizes risk parameters
#include "StrategyOptimizer.mqh"    // Optimizes strategy parameters
#include "TradeHistoryOptimizer.mqh"// Optimizes based on trade history analysis
#include "RecoveryManager.mqh"      // Manages drawdown recovery strategies
#include "CircuitBreaker.mqh"       // Implements circuit breaker logic to halt trading

// === SUPPORTING & UI MODULES (Enhance usability and provide information) ===
#include "Dashboard.mqh"            // Displays EA information on the chart
#include "PerformanceTracker.mqh"   // Tracks and reports performance metrics
#include "PerformanceDashboard.mqh" // Real-time performance visualization dashboard
#include "PresetManager.mqh"        // Manages EA input presets
#include "NewsDownloader.mqh"       // Downloads news data for the NewsFilter
#include "FunctionStack.mqh"        // For stack trace on errors

// === MISCELLANEOUS PROJECT INCLUDES (Other project-specific headers) ===
#include "PositionInfoExt.mqh"      // Extended position information structure
#include "CommonDefinitions.mqh"    // Other common definitions for the project

#property

// Wrap the entire EA logic in the ApexPullback namespace
namespace ApexPullback
{

// === BƯỚC 3: KHAI BÁO CON TRỎ EA CONTEXT TOÀN CỤC (DUY NHẤT) ===
// EAContext is defined in CommonStructs.mqh (included in "Core Includes" section above).
EAContext* g_EAContext = NULL; // Initialize as a pointer

// === BƯỚC 5: KHAI BÁO CÁC BIẾN TOÀN CỤC CẦN THIẾT ===
// Chỉ giữ lại các biến thực sự cần thiết ở global scope
static int G_TIMER_ID = 1;                  // Timer ID for periodic tasks


// Các biến toàn cục đã được khai báo ở trên sau các #include

// Các tham số đầu vào được khai báo trong Inputs.mqh và được include thông qua CommonStructs.mqh.
// MQL5 sẽ tự động tạo các biến toàn cục tương ứng với các khai báo input trong Inputs.mqh.
// Không cần khai báo lại input ở đây.

//+------------------------------------------------------------------+
//| Lấy mô tả lý do deinitialization                                 |
//+------------------------------------------------------------------+
string GetDeinitReasonText(const int reason_code)
  {
   string reason_str = "Unknown reason";
   switch(reason_code)
     {
      case REASON_PROGRAM:
         reason_str = "Expert removed from chart";
         break;
      case REASON_REMOVE:
         reason_str = "Expert removed from chart by user";
         break;
      case REASON_RECOMPILE:
         reason_str = "Expert recompiled";
         break;
      case REASON_CHARTCHANGE:
         reason_str = "Symbol or timeframe changed";
         break;
      case REASON_CHARTCLOSE:
         reason_str = "Chart closed";
         break;
      case REASON_PARAMETERS:
         reason_str = "Input parameters changed by user";
         break;
      case REASON_ACCOUNT:
         reason_str = "Account changed";
         break;
      case REASON_TEMPLATE:
         reason_str = "New template applied";
         break;
      case REASON_INITFAILED:
         reason_str = "OnInit() handler failed";
         break;
      case REASON_CLOSE:
         reason_str = "Terminal closed";
         break;
      default:
         reason_str = "Unknown reason code: " + IntegerToString(reason_code);
     }
   return reason_str;
  }


//+------------------------------------------------------------------+
//| Các hàm khởi tạo indicator và cache - nằm trong namespace        |
//+------------------------------------------------------------------+
// Removed redundant nested namespace ApexPullback block start

// ENUM_SESSION_TYPE đã được loại bỏ vì ENUM_SESSION đã được định nghĩa trong Enums.mqh

//+------------------------------------------------------------------+
//| Kiểm tra xem thời gian hiện tại có cho phép giao dịch                   |
//+------------------------------------------------------------------+
bool IsAllowedTradingSession()
  {
   if(::g_EAContext == NULL || ::g_EAContext->SessionManager == NULL)
     {
      if(::g_EAContext != NULL && ::g_EAContext->Logger != NULL)
        {
         ::g_EAContext->Logger->LogWarning("SessionManager is not initialized in IsAllowedTradingSession. Defaulting to true.");
        }
      else
        {
         Print("Warning: SessionManager is not initialized in IsAllowedTradingSession. Defaulting to true.");
        }
      return true; // Default to true to avoid blocking trades if not properly set up
     }
   return ::g_EAContext->SessionManager->IsSessionActive();
  }

//+------------------------------------------------------------------+
//| Kiểm tra xem thời gian hiện tại có ảnh hưởng tin tức kinh tế       |
//+------------------------------------------------------------------+
bool IsNewsImpactPeriod()
  {
   if(::g_EAContext == NULL || ::g_EAContext->NewsFilter == NULL)
     {
      if(::g_EAContext != NULL && ::g_EAContext->Logger != NULL)
        {
         ::g_EAContext->Logger->LogWarning("NewsFilter is not initialized in IsNewsImpactPeriod. Defaulting to false.");
        }
      else
        {
         Print("Warning: NewsFilter is not initialized in IsNewsImpactPeriod. Defaulting to false.");
        }
      return false; // Default to false if not properly set up
     }
   return ::g_EAContext->NewsFilter->IsInNewsWindow();
  }

// GlobalInitializeIndicatorCache đã được định nghĩa trong IndicatorUtils.mqh

// InitializeIndicators đã được định nghĩa trong IndicatorUtils.mqh

//+------------------------------------------------------------------+
//| Load all input parameters into the EAContext struct              |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Điều chỉnh tham số theo preset thị trường                        |
//+------------------------------------------------------------------+
void AdjustParametersByPreset(EAContext* context)
  {
   if(context == NULL)
     {
      Print("Error: EAContext is NULL in AdjustParametersByPreset.");
      return;
     }

   switch(context->MarketPreset)
     {
      case PRESET_CONSERVATIVE:
         context->RiskPercent *= 0.8; // Giảm rủi ro
         context->TakeProfit_RR *= 1.1; // Tăng mục tiêu RR
         context->MinAdxValue = 25;
         context->VolatilityThreshold *= 0.9;
         if(context->Logger)
            context->Logger->LogInfo("Market Preset: CONSERVATIVE applied.");
         break;
      case PRESET_AGGRESSIVE:
         context->RiskPercent *= 1.2; // Tăng rủi ro
         context->TakeProfit_RR *= 0.9; // Giảm mục tiêu RR
         context->MinAdxValue = 20;
         context->VolatilityThreshold *= 1.1;
         if(context->Logger)
            context->Logger->LogInfo("Market Preset: AGGRESSIVE applied.");
         break;
      // Các case PRESET_SIDEWAYS_OPTIMIZED và PRESET_TRENDING_OPTIMIZED đã bị loại bỏ vì chưa được định nghĩa trong Enums.mqh
      // Thêm các preset khác nếu cần
      default: // PRESET_STANDARD hoặc không có preset
         if(context->Logger)
            context->Logger->LogInfo("Market Preset: STANDARD (default) applied.");
         break;
     }
  }

//+------------------------------------------------------------------+
//| Load all input parameters into the EAContext struct              |
//+------------------------------------------------------------------+
void LoadParametersToContext(EAContext* context)
  {
   if(context == NULL)
     {
      Print("Error: EAContext is NULL in LoadParametersToContext. Cannot load parameters.");
      return;
     }

// THÔNG TIN CHUNG
   context->EAName = EAName;
   context->EAVersion = EAVersion;
   context->MagicNumber = MagicNumber;
   context->OrderComment = OrderComment;
   context->AllowNewTrades = AllowNewTrades; // Sử dụng tên biến từ Inputs.mqh
   context->IsSlaveEA = IsSlaveEA; // Nạp giá trị IsSlaveEA

// HIỂN THỊ & THÔNG BÁO
   context->EnableDetailedLogs = EnableDetailedLogs; // Sử dụng tên biến từ Inputs.mqh
   context->EnableCsvLog = EnableCsvLog;
   context->CsvLogFilename = CsvLogFilename;
   context->DisplayDashboard = DisplayDashboard; // Sử dụng tên biến từ Inputs.mqh
   context->DashboardTheme = (ENUM_DASHBOARD_THEME)DashboardTheme;
   context->AlertsEnabled = AlertsEnabled;
   context->SendNotifications = SendNotifications;
   context->SendEmailAlerts = SendEmailAlerts;
   context->EnableTelegramNotify = EnableTelegramNotify;
   context->TelegramBotToken = TelegramBotToken;
   context->TelegramChatID = TelegramChatID;
   context->TelegramImportantOnly = TelegramImportantOnly;
   context->DisableDashboardInBacktest = DisableDashboardInBacktest;
   context->UpdateFrequencySeconds = UpdateFrequencySeconds; // Added from Inputs.mqh
   context->SaveStatistics = SaveStatistics;                 // Added from Inputs.mqh
   context->EnableIndicatorCache = EnableIndicatorCache;       // Added from Inputs.mqh

// CHIẾN LƯỢC CỐT LÕI
   context->MainTimeframe = (ENUM_TIMEFRAMES)MainTimeframe;
   context->EMA_Fast = EMA_Fast;
   context->EMA_Medium = EMA_Medium;
   context->EMA_Slow = EMA_Slow;
   context->ATR_Period = 14; // Default or ensure ATR_Period is in Inputs.mqh // Added from input
   context->ADXPeriod = InpADX_Period; // Tải tham số ADX Period
   context->UseMultiTimeframe = UseMultiTimeframe;
   context->HigherTimeframe = (ENUM_TIMEFRAMES)HigherTimeframe;
   context->TrendDirection = (ENUM_TREND_DIRECTION)TrendDirection;

// ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO
   context->EnablePriceAction = EnablePriceAction;
   context->EnableSwingLevels = EnableSwingLevels;
   context->MinPullbackPercent = MinPullbackPercent;
   context->MaxPullbackPercent = MaxPullbackPercent;
   context->RequirePriceActionConfirmation = RequirePriceActionConfirmation;
   context->RequireMomentumConfirmation = RequireMomentumConfirmation;
   context->RequireVolumeConfirmation = RequireVolumeConfirmation;

// BỘ LỌC THỊ TRƯỜNG
   context->EnableMarketRegimeFilter = EnableMarketRegimeFilter; // Khớp với tên trong EAContext và Inputs.mqh
   context->EnableVolatilityFilter = EnableVolatilityFilter;   // Khớp với tên trong EAContext và Inputs.mqh
   context->EnableAdxFilter = EnableAdxFilter; // Khớp với tên trong EAContext và Inputs.mqh
   context->MarketPreset = (ENUM_MARKET_PRESET)MarketPreset;
   context->MinAdxValue = MinAdxValue;
   context->MaxAdxValue = MaxAdxValue;
   context->VolatilityThreshold = VolatilityThreshold;
   context->MaxSpreadPoints = MaxSpreadPoints;

// QUẢN LÝ RỦI RO
   context->RiskPercent = RiskPercent;
   context->StopLoss_ATR = StopLoss_ATR;
   context->TakeProfit_RR = TakeProfit_RR;
   context->PropFirmMode = PropFirmMode;
   context->DailyLossLimit = DailyLossLimit;
   context->MaxDrawdown = MaxDrawdown;
   context->MaxTradesPerDay = MaxTradesPerDay;
   context->MaxConsecutiveLosses = MaxConsecutiveLosses;
   context->MaxPositions = MaxPositions;

// ĐIỀU CHỈNH RISK THEO DRAWDOWN
   context->DrawdownReduceThreshold = DrawdownReduceThreshold;
   context->EnableTaperedRisk = EnableTaperedRisk;
   context->MinRiskMultiplier = MinRiskMultiplier;

// QUẢN LÝ VỊ THẾ
   context->EntryMode = (ENUM_ENTRY_MODE)EntryMode;
   context->UsePartialClose = UsePartialClose;
   context->PartialCloseR1 = PartialCloseR1;
   context->PartialCloseR2 = PartialCloseR2;
   context->PartialClosePercent1 = PartialClosePercent1;
   context->PartialClosePercent2 = PartialClosePercent2;

// TRAILING STOP
   context->UseAdaptiveTrailing = UseAdaptiveTrailing;
   context->TrailingMode = (ENUM_TRAILING_MODE)TrailingMode;
   context->TrailingAtrMultiplier = TrailingAtrMultiplier;
   context->BreakEvenAfterR = BreakEvenAfterR;
   context->BreakEvenBuffer = BreakEvenBuffer;

// CHANDELIER EXIT (Inputs from Inputs.mqh)
   context->UseChandelierExit = UseChandelierExit;
   context->ChandelierPeriod = ChandelierPeriod;
   context->ChandelierMultiplier = ChandelierMultiplier;

// LỌC PHIÊN (Inputs from Inputs.mqh)
   context->FilterBySession = FilterBySession;
   context->SessionFilter = (ENUM_SESSION_FILTER)SessionFilter;
   context->UseGmtOffset = UseGmtOffset;
   context->GmtOffset = GmtOffset;
   context->TradeLondonOpen = TradeLondonOpen;
   context->TradeNewYorkOpen = TradeNewYorkOpen;

// LỌC TIN TỨC (Inputs from Inputs.mqh)
   context->NewsFilterMode = (ENUM_NEWS_FILTER_MODE)NewsFilterModeInput; // Corrected to use NewsFilterModeInput and assign to NewsFilterMode
   context->NewsDataFile = NewsDataFile;
   context->NewsImportance = (ENUM_NEWS_FILTER_LEVEL)NewsImportanceInput; // Corrected to use NewsImportanceInput and cast to ENUM_NEWS_FILTER_LEVEL
   context->MinutesBeforeNews = MinutesBeforeNews;
   context->MinutesAfterNews = MinutesAfterNews;

// TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC (Inputs from Inputs.mqh)
   context->EnableAutoPause = EnableAutoPause;
   context->VolatilityPauseThreshold = VolatilityPauseThreshold;
   context->DrawdownPauseThreshold = DrawdownPauseThreshold;
   context->EnableAutoResume = EnableAutoResume;
   context->PauseDurationMinutes = PauseDurationMinutes;
   context->ResumeOnLondonOpen = ResumeOnLondonOpen;

// ASSETPROFILER - MODULE MỚI (Inputs from Inputs.mqh)
   context->UseAssetProfiler = UseAssetProfiler;
   context->AssetProfileDays = AssetProfileDays;
   context->AdaptRiskByAsset = AdaptRiskByAsset;
   context->AdaptSLByAsset = AdaptSLByAsset;
   context->AdaptSpreadFilterByAsset = AdaptSpreadFilterByAsset;
   context->AdaptiveMode = (ENUM_ADAPTIVE_MODE)AdaptiveMode;

// CHẾ ĐỘ TAKE PROFIT (Inputs from Inputs.mqh)
   context->TakeProfitMode = (ENUM_TP_MODE)TakeProfitMode;
   context->StopLossBufferATR_Ratio = StopLossBufferATR_Ratio;
   context->StopLossATR_Multiplier = StopLossATR_Multiplier;
   context->TakeProfitStructureBufferATR_Ratio = TakeProfitStructureBufferATR_Ratio;
   context->ADXThresholdForVolatilityTP = ADXThresholdForVolatilityTP;
   context->VolatilityTP_ATR_Multiplier_High = VolatilityTP_ATR_Multiplier_High;
   context->VolatilityTP_ATR_Multiplier_Low = VolatilityTP_ATR_Multiplier_Low;

// QUẢN LÝ DANH MỤC (Inputs from Inputs.mqh)
   context->IsMasterPortfolioManager = IsMasterPortfolioManager;

// MISC INPUTS - These are now loaded above
// context->DisplayDashboard = DisplayDashboard; // Already added, ensure it's correct

// Điều chỉnh tham số dựa trên preset sau khi đã load giá trị gốc
   AdjustParametersByPreset(context);
  }

} // Kết thúc namespace ApexPullback

// Các khai báo input này đã được chuyển vào Inputs.mqh và sẽ được load từ đó.
// Xóa bỏ để tránh trùng lặp và đảm bảo chỉ có một nguồn khai báo input duy nhất.
// Các biến input này sẽ được MQL5 tự động tạo và có sẵn ở global scope do #include "Inputs.mqh".

// Định nghĩa namespace variables trong namespace ApexPullback
namespace ApexPullback
{
// Global variables have been moved to EAContext.
// Access them via g_EAContext.variableName (since g_EAContext is a pointer, it would be g_EAContext->variableName, but the struct itself is often passed by value or reference in functions)
// Indicator handles are now managed by CIndicatorUtils within g_EAContext

// Các hàm inline hỗ trợ đã được chuyển sang sử dụng g_EAContext hoặc loại bỏ nếu không cần thiết
// Example: inline bool IsAlertsEnabled() { return g_EAContext != NULL && g_EAContext->AlertsEnabled; }
// Direct access like ApexPullback::g_EAContext->AlertsEnabled is preferred.

// Placeholder for any remaining essential global-like accessors or definitions within this namespace
// that are not directly tied to the removed EA state variables.
}







// =====================================================================================================================
// Định nghĩa các enum cần thiết và hằng số
// =====================================================================================================================

// Sử dụng các hằng số cho Log Level và Alert
#ifndef ALERT_LEVEL_CRITICAL
#define ALERT_LEVEL_CRITICAL 3
#endif

// Định nghĩa các hằng số đơn giản hóa cho TREND và REGIME để tránh lỗi biên dịch
#define TREND_BULLISH      ENUM_MARKET_TREND::TREND_UP_STRONG
#define TREND_BEARISH      ENUM_MARKET_TREND::TREND_DOWN_STRONG
#define TREND_NEUTRAL      ENUM_MARKET_TREND::TREND_SIDEWAY
#define REGIME_TRENDING    ENUM_MARKET_REGIME::REGIME_TRENDING
#define REGIME_RANGING     ENUM_MARKET_REGIME::REGIME_RANGING
#define REGIME_TRANSITIONING ENUM_MARKET_REGIME::REGIME_VOLATILE_EXPANSION

// Log level constants are now defined as enums in Logger.mqh
// Removed conflicting #define statements

// ENUM_MARKET_PRESET đã được định nghĩa trong Enums.mqh

// Định nghĩa enum ENUM_ALERT_LEVEL đã được thay thế bằng các hằng số để tránh xung đột

// Forward declarations cho các lớp và structs từ namespace ApexPullback

// Không khai báo lại các biến đã có trong namespace ApexPullback cho các module và đối tượng
// Khai báo các biến global từ namespace ApexPullback

namespace ApexPullback
{



} // End namespace ApexPullback

// GlobalSendAlert đã được định nghĩa ở phần sau





// Khai báo biến toàn cục cho EA
// bool g_EnableDetailedLogs = false;             // Bật logs chi tiết

// Các hàm inline trong namespace ApexPullback
namespace ApexPullback
{
// Indicator handles have been removed and are managed by CIndicatorUtils in EAContext.

// Loại bỏ các khai báo trùng lặp
// bool   g_AlertsEnabled = true;                   // Bật cảnh báo
// bool   g_SendNotifications = true;               // Gửi thông báo
// bool   g_SendEmailAlerts = false;                // Gửi email
// bool   g_EnableTelegramNotify = false;           // Gửi Telegram
// bool   g_TelegramImportantOnly = true;           // Chỉ gửi Telegram quan trọng
// bool   g_DisplayDashboard = true;                // Hiển thị dashboard
// bool   g_EnableIndicatorCache = true;            // Bật cache indicator

// Các hàm inline hỗ trợ đã được định nghĩa ở phần trước
// Không định nghĩa lại
// inline bool IsAlertsEnabled() { return g_AlertsEnabled; }
// inline bool IsSendNotificationsEnabled() { return g_SendNotifications; }
// inline bool IsSendEmailAlertsEnabled() { return g_SendEmailAlerts; }
// inline bool IsTelegramNotifyEnabled() { return g_EnableTelegramNotify; }
// inline bool IsTelegramImportantOnly() { return g_TelegramImportantOnly; }
// inline bool IsDashboardEnabled() { return g_DisplayDashboard; }
// Removed premature closing of namespace ApexPullback. Functions below are now inside.

//+------------------------------------------------------------------+
//| Hàm kiểm tra tính hợp lệ của các tham số đầu vào (Cải tiến)    |
//+------------------------------------------------------------------+
bool ValidateInputParameters(ApexPullback::EAContext &context)
  {
// Logger may or may not be initialized at this stage if called very early.
// If context->Logger is NULL, messages will be printed to Experts log.
   CLogger* logger = context->Logger; // Use context's logger if available

   bool isValid = true;
   string errorMsg = "";

// Kiểm tra Magic Number với phạm vi hợp lý
   if(context->MagicNumber <= 0 || context->MagicNumber > 2147483647)
     {
      errorMsg += "Magic Number phải trong khoảng 1-2147483647. ";
      isValid = false;
     }

// Kiểm tra các tham số EMA với giới hạn thực tế
   if(context->EMA_Fast <= 0 || context->EMA_Fast > 1000)
     {
      errorMsg += "EMA_Fast phải trong khoảng 1-1000. ";
      isValid = false;
     }
   if(context->EMA_Medium <= 0 || context->EMA_Medium > 1000)
     {
      errorMsg += "EMA_Medium phải trong khoảng 1-1000. ";
      isValid = false;
     }
   if(context->EMA_Slow <= 0 || context->EMA_Slow > 1000)
     {
      errorMsg += "EMA_Slow phải trong khoảng 1-1000. ";
      isValid = false;
     }

   if(context->EMA_Fast >= context->EMA_Medium || context->EMA_Medium >= context->EMA_Slow)
     {
      errorMsg += "Thứ tự EMA phải: EMA_Fast < EMA_Medium < EMA_Slow. ";
      isValid = false;
     }

// Kiểm tra ATR Period với phạm vi hợp lý
   if(context->ATR_Period <= 0 || context->ATR_Period > 200)
     {
      errorMsg += "ATR Period phải trong khoảng 1-200. ";
      isValid = false;
     }

// Kiểm tra các tham số Risk Management
   if(context->RiskPercent <= 0 || context->RiskPercent > 10)
     {
      errorMsg += "Risk Percent phải trong khoảng 0.1-10%. ";
      isValid = false;
     }

   if(context->StopLoss_ATR <= 0 || context->StopLoss_ATR > 10)
     {
      errorMsg += "StopLoss ATR multiplier phải trong khoảng 0.1-10. ";
      isValid = false;
     }

   if(context->TakeProfit_RR <= 0 || context->TakeProfit_RR > 20)
     {
      errorMsg += "TakeProfit R:R phải trong khoảng 0.1-20. ";
      isValid = false;
     }

// Kiểm tra các giới hạn giao dịch
   if(context->MaxTradesPerDay <= 0 || context->MaxTradesPerDay > 100)
     {
      errorMsg += "Max Trades Per Day phải trong khoảng 1-100. ";
      isValid = false;
     }

   if(context->MaxPositions <= 0 || context->MaxPositions > 10)
     {
      errorMsg += "Max Positions phải trong khoảng 1-10. ";
      isValid = false;
     }

// Kiểm tra Telegram settings nếu được bật
   if(context->EnableTelegramNotify)
     {
      if(StringLen(context->TelegramBotToken) < 10)
        {
         errorMsg += "Telegram Bot Token quá ngắn (tối thiểu 10 ký tự). ";
         isValid = false;
        }
      if(StringLen(context->TelegramChatID) == 0)
        {
         errorMsg += "Telegram Chat ID không được để trống. ";
         isValid = false;
        }
     }

// Kiểm tra CSV log filename nếu được bật
   if(context->EnableCsvLog)
     {
      if(StringLen(context->CsvLogFilename) == 0)
        {
         errorMsg += "Tên file CSV log không được để trống. ";
         isValid = false;
        }
      if(StringFind(context->CsvLogFilename, ".csv") == -1)
        {
         errorMsg += "File CSV log phải có đuôi .csv. ";
         isValid = false;
        }
     }

// Kiểm tra tính hợp lý của Pullback parameters
   if(context->MinPullbackPct <= 0 || context->MinPullbackPct >= 100)    // Sử dụng MinPullbackPct từ context
     {
      errorMsg += "Min Pullback Percent phải trong khoảng 1-99%. ";
      isValid = false;
     }

   if(context->MaxPullbackPct <= context->MinPullbackPct || context->MaxPullbackPct >= 100)    // Sử dụng MaxPullbackPct và MinPullbackPct từ context
     {
      errorMsg += "Max Pullback Percent phải lớn hơn Min và nhỏ hơn 100%. ";
      isValid = false;
     }

// Log lỗi nếu có
   if(!isValid)
     {
      if(logger != NULL)
        {
         logger->LogError("Lỗi tham số đầu vào: " + errorMsg);
        }
      else
        {
         Print("[LỖI NGHIÊM TRỌNG] Tham số đầu vào không hợp lệ: " + errorMsg);
        }
     }
   else
     {
      if(logger != NULL)
        {
         logger->LogInfo("Tất cả tham số đầu vào đã được xác thực thành công.");
        }
      else
        {
         Print("Tất cả tham số đầu vào đã được xác thực thành công (Logger không khả dụng).");
        }
     }

   return isValid;
  }

//+------------------------------------------------------------------+
//| Hàm dọn dẹp khi khởi tạo thất bại                              |
//+------------------------------------------------------------------+
void CleanupPartialInit()
  {
   CLogger* loggerToUse = NULL;
   if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL)
     {
      loggerToUse = ApexPullback::g_EAContext->Logger;
     }
   else
     {
      // loggerToUse remains NULL, subsequent checks will handle Print
     }

   if(loggerToUse != NULL)
     {
      loggerToUse->LogInfo("Bắt đầu dọn dẹp do khởi tạo thất bại...");
     }
   else
     {
      Print("Bắt đầu dọn dẹp do khởi tạo thất bại (Logger không khả dụng)...");
     }

   if(ApexPullback::g_EAContext != NULL)
     {
      // Dọn dẹp theo thứ tự ngược lại với khởi tạo, using context members
      if(ApexPullback::g_EAContext->Dashboard != NULL)
        {
         delete ApexPullback::g_EAContext->Dashboard;
         ApexPullback::g_EAContext->Dashboard = NULL;
        }
      if(ApexPullback::g_EAContext->AssetProfileManager != NULL)
        {
         delete ApexPullback::g_EAContext->AssetProfileManager;
         ApexPullback::g_EAContext->AssetProfileManager = NULL;
        }
      if(ApexPullback::g_EAContext->NewsFilter != NULL)
        {
         delete ApexPullback::g_EAContext->NewsFilter;
         ApexPullback::g_EAContext->NewsFilter = NULL;
        }
      if(ApexPullback::g_EAContext->SessionManager != NULL)
        {
         delete ApexPullback::g_EAContext->SessionManager;
         ApexPullback::g_EAContext->SessionManager = NULL;
        }
      if(ApexPullback::g_EAContext->RiskManager != NULL)
        {
         delete ApexPullback::g_EAContext->RiskManager;
         ApexPullback::g_EAContext->RiskManager = NULL;
        }
      if(ApexPullback::g_EAContext->TradeManager != NULL)
        {
         delete ApexPullback::g_EAContext->TradeManager;
         ApexPullback::g_EAContext->TradeManager = NULL;
        }
      if(ApexPullback::g_EAContext->PositionManager != NULL)
        {
         delete ApexPullback::g_EAContext->PositionManager;
         ApexPullback::g_EAContext->PositionManager = NULL;
        }
      if(ApexPullback::g_EAContext->SwingDetector != NULL)
        {
         delete ApexPullback::g_EAContext->SwingDetector;
         ApexPullback::g_EAContext->SwingDetector = NULL;
        }
      if(ApexPullback::g_EAContext->MarketProfile != NULL)
        {
         delete ApexPullback::g_EAContext->MarketProfile;
         ApexPullback::g_EAContext->MarketProfile = NULL;
        }
      if(ApexPullback::g_EAContext->PatternDetector != NULL)
        {
         delete ApexPullback::g_EAContext->PatternDetector;
         ApexPullback::g_EAContext->PatternDetector = NULL;
        }
      if(ApexPullback::g_EAContext->PerformanceTracker != NULL)
        {
         delete ApexPullback::g_EAContext->PerformanceTracker;
         ApexPullback::g_EAContext->PerformanceTracker = NULL;
        }
      if(ApexPullback::g_EAContext->PerformanceDashboard != NULL)
        {
         delete ApexPullback::g_EAContext->PerformanceDashboard;
         ApexPullback::g_EAContext->PerformanceDashboard = NULL;
        }
      if(ApexPullback::g_EAContext->PortfolioManager != NULL)
        {
         delete ApexPullback::g_EAContext->PortfolioManager;
         ApexPullback::g_EAContext->PortfolioManager = NULL;
        }
      if(ApexPullback::g_EAContext->IndicatorUtils != NULL)
        {
         // IndicatorUtils might handle its own indicator handle releases in its destructor
         // Or call a specific cleanup method if needed before deleting IndicatorUtils
         // ApexPullback::g_EAContext->IndicatorUtils->ReleaseAllIndicators(); // Example
         delete ApexPullback::g_EAContext->IndicatorUtils;
         ApexPullback::g_EAContext->IndicatorUtils = NULL;
        }

      // Cleanup new optimization modules
      if(ApexPullback::g_EAContext->TradeHistoryOptimizer != NULL)
        {
         delete ApexPullback::g_EAContext->TradeHistoryOptimizer;
         ApexPullback::g_EAContext->TradeHistoryOptimizer = NULL;
        }
      if(ApexPullback::g_EAContext->NewsDownloader != NULL)
        {
         delete ApexPullback::g_EAContext->NewsDownloader;
         ApexPullback::g_EAContext->NewsDownloader = NULL;
        }
      if(ApexPullback::g_EAContext->PresetManager != NULL)
        {
         delete ApexPullback::g_EAContext->PresetManager;
         ApexPullback::g_EAContext->PresetManager = NULL;
        }

      // Cleanup FunctionStack before Logger
      if(ApexPullback::g_EAContext->FunctionStack != NULL)
        {
         delete ApexPullback::g_EAContext->FunctionStack;
         ApexPullback::g_EAContext->FunctionStack = NULL;
        }
      // Note: Global indicator handles like g_hMA_Fast are now ideally managed by IndicatorUtils.
      // If not, they need separate handling or to be added to EAContext for cleanup.
      // ReleaseIndicatorHandles(); // This global function will need to be updated or its logic moved.

      // Logger (part of context) is deleted when g_EAContext is deleted
      if(ApexPullback::g_EAContext->Logger != NULL)
        {
         // Log final cleanup message with the context's logger before it's deleted with the context
         // No need to delete ApexPullback::g_EAContext.Logger separately if g_EAContext itself is deleted.
        }
      delete ApexPullback::g_EAContext;
      ApexPullback::g_EAContext = NULL;
     }
   else
     {
      // Fallback to old global variable cleanup if g_EAContext was never initialized or already cleaned up - This block should ideally not be reached.
      Print("CleanupPartialInit: EAContext was NULL. Global fallbacks for Dashboard, AssetProfileManager, Logger are removed.");
     }
// Global indicator handles are now managed by CIndicatorUtils within g_EAContext.

   if(loggerToUse != NULL)
     {
      loggerToUse.LogInfo("Hoàn tất dọn dẹp do khởi tạo thất bại.");
     }
   else
     {
      Print("Hoàn tất dọn dẹp do khởi tạo thất bại (Logger không khả dụng).");
     }
  }

// Removed redundant re-opening of namespace ApexPullback. Helper functions are now inside the main namespace.

//+------------------------------------------------------------------+
//| HELPER: Khởi tạo các module cốt lõi                             |
//+------------------------------------------------------------------+
bool InitializeCoreModules(EAContext* context)
  {
// Kiểm tra bộ nhớ khả dụng trước khi khởi tạo Logger
   if(!CheckMemoryAvailable())    // CheckMemoryAvailable is global
     {
      Print("[LỖI NGHIÊM TRỌNG] Không đủ bộ nhớ để khởi tạo Logger.");
      return false;
     }

   context->Logger = new CLogger(context);
   if(context->Logger == NULL)
     {
      Print("[LỖI NGHIÊM TRỌNG] Không thể cấp phát bộ nhớ cho Logger. EA không thể tiếp tục.");
      return false;
     }
   if(!context->Logger->Initialize(
         context->EAName,
         context->EnableDetailedLogs,
         context->EnableCsvLog,
         context->CsvLogFilename,
         context->EnableTelegramNotify,
         context->TelegramBotToken,
         context->TelegramChatID,
         context->TelegramImportantOnly
      ))
     {
      Print("[LỖI NGHIÊM TRỌNG] Không thể khởi tạo Logger với các tham số. EA không thể tiếp tục.");
      delete context->Logger;
      context->Logger = NULL;
      return false;
     }
   context->Logger->LogInfo("Logger đã được khởi tạo thành công.");

   context->Logger->LogDebug("Khởi tạo IndicatorUtils...");
   context->IndicatorUtils = new CIndicatorUtils(context->Logger, context->MainTimeframe, context->EnableIndicatorCache);
   if(context->IndicatorUtils == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho IndicatorUtils.");
      return false;
     }
   if(!context->IndicatorUtils->Initialize(_Symbol, (ENUM_TIMEFRAMES)context->MainTimeframe, (ENUM_TIMEFRAMES)context->HigherTimeframe, context->EnableIndicatorCache, context->EnableDetailedLogs, true))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo CIndicatorUtils (bao gồm các indicators kỹ thuật).");
      delete context->IndicatorUtils;
      context->IndicatorUtils = NULL;
      return false;
     }
   context->Logger->LogDebug("IndicatorUtils (bao gồm các indicators kỹ thuật) đã được khởi tạo thành công.");

// Khởi tạo PresetManager
   context->Logger->LogDebug("Khởi tạo PresetManager...");
   context->PresetManager = new CPresetManager();
   if(context->PresetManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho PresetManager.");
      return false;
     }
   if(!context->PresetManager->Initialize(context->Logger))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo PresetManager.");
      delete context->PresetManager;
      context->PresetManager = NULL;
      return false;
     }
   context->Logger->LogDebug("PresetManager đã được khởi tạo thành công.");

// Khởi tạo NewsDownloader
   context->Logger->LogDebug("Khởi tạo NewsDownloader...");
   context->NewsDownloader = new CNewsDownloader();
   if(context->NewsDownloader == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho NewsDownloader.");
      return false;
     }
   if(!context->NewsDownloader->Initialize(context->Logger, "NewsData", true))
     {
      context->Logger->LogWarning("CẢNH BÁO: Không thể khởi tạo NewsDownloader. Tính năng tự động tải tin tức sẽ bị vô hiệu hóa.");
      // Không return false vì NewsDownloader không phải là module quan trọng
     }
   else
     {
      context->Logger->LogDebug("NewsDownloader đã được khởi tạo thành công.");
     }

// Khởi tạo TradeHistoryOptimizer
   context->Logger->LogDebug("Khởi tạo TradeHistoryOptimizer...");
   context->TradeHistoryOptimizer = new CTradeHistoryOptimizer();
   if(context->TradeHistoryOptimizer == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho TradeHistoryOptimizer.");
      return false;
     }
   if(!context->TradeHistoryOptimizer->Initialize(context->Logger, true))
     {
      context->Logger->LogWarning("CẢNH BÁO: Không thể khởi tạo TradeHistoryOptimizer. Phân tích lịch sử giao dịch sẽ sử dụng phương pháp chuẩn.");
      // Không return false vì TradeHistoryOptimizer không phải là module quan trọng
     }
   else
     {
      context->Logger->LogDebug("TradeHistoryOptimizer đã được khởi tạo thành công.");
     }

   // Khởi tạo FunctionStack
   context->Logger->LogDebug("Khởi tạo FunctionStack...");
   context->FunctionStack = new CFunctionStack(context->Logger);
   if(context->FunctionStack == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho FunctionStack.");
      return false;
     }
   context->Logger->LogDebug("FunctionStack đã được khởi tạo thành công.");

   return true;
  }

//+------------------------------------------------------------------+
//| HELPER: Khởi tạo các module phân tích                            |
//+------------------------------------------------------------------+
bool InitializeAnalysisModules(EAContext* context)
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("InitializeAnalysisModules: Context or Logger is NULL");
      return false;
     }

   context->Logger->LogDebug("Khởi tạo Module MarketProfile...");
   context->MarketProfile = new CMarketProfile(*context);
   if(context->MarketProfile == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module MarketProfile.");
      return false;
     }
   context->Logger->LogDebug("Module MarketProfile đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module SwingDetector...");
   context->SwingDetector = new CSwingPointDetector(context);
   if(context->SwingDetector == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module SwingDetector.");
      return false;
     }
   context->Logger->LogDebug("Module SwingDetector đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module PatternDetector...");
   context->PatternDetector = new CPatternDetector(context);
   if(context->PatternDetector == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module PatternDetector.");
      return false;
     }
   context->Logger->LogDebug("Module PatternDetector đã được khởi tạo.");
   return true;
  }

//+------------------------------------------------------------------+
//| HELPER: Khởi tạo các module quản lý                            |
//+------------------------------------------------------------------+
bool InitializeManagementModules(EAContext* context)
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("InitializeManagementModules: Context or Logger is NULL");
      return false;
     }

   context->Logger->LogDebug("Khởi tạo Module PositionManager...");
   context->PositionManager = new CPositionManager(context);
   if(context->PositionManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module PositionManager.");
      return false;
     }
   context->Logger->LogDebug("Module PositionManager đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module RiskManager...");
   context->RiskManager = new CRiskManager(*context);
   if(context->RiskManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module RiskManager.");
      return false;
     }
   context->Logger->LogDebug("Module RiskManager đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module TradeManager...");
   context->TradeManager = new CTradeManager(*context);
   if(context->TradeManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module TradeManager.");
      return false;
     }
   context->Logger->LogDebug("Module TradeManager đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module SessionManager...");
   context->SessionManager = new CSessionManager(context);
   if(context->SessionManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module SessionManager.");
      return false;
     }
   context->Logger->LogDebug("Module SessionManager đã được khởi tạo.");

   context->Logger->LogDebug("Khởi tạo Module NewsFilter...");
   context->NewsFilter = new CNewsFilter(context);
   if(context->NewsFilter == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module NewsFilter.");
      return false;
     }
   context->Logger->LogDebug("Module NewsFilter đã được khởi tạo.");
   return true;
  }

//+------------------------------------------------------------------+
//| HELPER: Khởi tạo các module chiến lược                          |
//+------------------------------------------------------------------+
bool InitializeStrategicModules(EAContext* context)
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("InitializeStrategicModules: Context or Logger is NULL");
      return false;
     }

   context->Logger->LogDebug("Khởi tạo Module AssetDNA...");
   context->AssetDNA = new CAssetDNA(*context);
   if(context->AssetDNA == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module AssetDNA.");
      return false;
     }
   context->Logger->LogDebug("Module AssetDNA đã được khởi tạo.");

// Initialize PortfolioManager (only for the Master EA instance)
   if(context->IsMasterPortfolioManager)
     {
      context->Logger->LogDebug("Khởi tạo Module PortfolioManager...");
      if(context->NewsFilter == NULL || context->PositionManager == NULL || context->RiskManager == NULL)
        {
         context->Logger->LogError("LỖI: Các module phụ thuộc (NewsFilter, PositionManager, RiskManager) chưa được khởi tạo trước PortfolioManager.");
         return false; // Do not proceed with PortfolioManager if dependencies are missing
        }
      context->PortfolioManager = new CPortfolioManager(context);
      if(context->PortfolioManager == NULL)
        {
         context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho PortfolioManager.");
         return false;
        }
      if(!context->PortfolioManager->Initialize(context->PortfolioMaxTotalRisk, context->PortfolioMaxCorrelation))
        {
         context->Logger->LogError("LỖI: Không thể khởi tạo Module PortfolioManager.");
         delete context->PortfolioManager;
         context->PortfolioManager = NULL;
         return false;
        }
      context->Logger->LogDebug("Module PortfolioManager đã được khởi tạo cho Master EA.");
     }
   else
     {
      context->PortfolioManager = NULL;
      context->Logger->LogInfo("Module PortfolioManager không được khởi tạo (không phải Master EA hoặc chưa được kích hoạt).");
     }
   return true;
  }

//+------------------------------------------------------------------+
//| HELPER: Khởi tạo các module hỗ trợ                             |
//+------------------------------------------------------------------+
bool InitializeSupportingModules(EAContext* context)
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("InitializeSupportingModules: Context or Logger is NULL");
      return false;
     }

   context->Logger->LogDebug("Khởi tạo Module PerformanceTracker...");
   context->PerformanceTracker = new CPerformanceTracker(context);
   if(context->PerformanceTracker == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module PerformanceTracker.");
      return false;
     }
   context->Logger->LogDebug("Module PerformanceTracker đã được khởi tạo.");

// Khởi tạo Module RecoveryManager
   context->Logger->LogDebug("Khởi tạo Module RecoveryManager...");
   context->RecoveryManager = new CRecoveryManager();
   if(context->RecoveryManager == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module RecoveryManager.");
      return false;
     }
   if(!context->RecoveryManager->Initialize(context))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo RecoveryManager.");
      delete context->RecoveryManager;
      context->RecoveryManager = NULL;
      return false;
     }
   context->Logger->LogDebug("Module RecoveryManager đã được khởi tạo.");

// Khởi tạo Module CircuitBreaker
   context->Logger->LogDebug("Khởi tạo Module CircuitBreaker...");
   context->CircuitBreaker = new CCircuitBreaker();
   if(context->CircuitBreaker == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module CircuitBreaker.");
      return false;
     }
   if(!context->CircuitBreaker->Initialize(context))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo CircuitBreaker.");
      delete context->CircuitBreaker;
      context->CircuitBreaker = NULL;
      return false;
     }
   context->Logger->LogDebug("Module CircuitBreaker đã được khởi tạo.");

// Khởi tạo Module StrategyOptimizer
   context->Logger->LogDebug("Khởi tạo Module StrategyOptimizer...");
   context->StrategyOptimizer = new CStrategyOptimizer();
   if(context->StrategyOptimizer == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module StrategyOptimizer.");
      return false;
     }
   if(!context->StrategyOptimizer->Initialize(context))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo StrategyOptimizer.");
      delete context->StrategyOptimizer;
      context->StrategyOptimizer = NULL;
      return false;
     }
   context->Logger->LogDebug("Module StrategyOptimizer đã được khởi tạo.");

// Nâng cấp FileCommunication cho Portfolio Mode
   context->Logger->LogDebug("Khởi tạo Module FileCommunication (Portfolio Mode)...");
   context->FileCommunication = new CFileCommunication();
   if(context->FileCommunication == NULL)
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo Module FileCommunication.");
      return false;
     }
   if(!context->FileCommunication->Initialize(context->EAName, context->MagicNumber))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo FileCommunication.");
      delete context->FileCommunication;
      context->FileCommunication = NULL;
      return false;
     }

// Khởi tạo Portfolio Mode nếu được kích hoạt
   if(context->EnablePortfolioMode)
     {
      if(!context->FileCommunication->InitializePortfolioMode(context->PortfolioId, context->PortfolioMasterEA))
        {
         context->Logger->LogError("LỖI: Không thể khởi tạo Portfolio Mode.");
         return false;
        }
      context->Logger->LogInfo("Portfolio Mode đã được kích hoạt.");
     }
   context->Logger->LogDebug("Module FileCommunication đã được khởi tạo.");

   // Khởi tạo TradeHistoryOptimizer
   context->Logger->LogDebug("Khởi tạo Module TradeHistoryOptimizer...");
   context->TradeHistoryOptimizer = new CTradeHistoryOptimizer();
   if(context->TradeHistoryOptimizer == NULL)
     {
      context->Logger->LogError("LỖI: Không thể cấp phát bộ nhớ cho TradeHistoryOptimizer.");
      return false;
     }
   if(!context->TradeHistoryOptimizer->Initialize(context))
     {
      context->Logger->LogError("LỖI: Không thể khởi tạo TradeHistoryOptimizer.");
      delete context->TradeHistoryOptimizer;
      context->TradeHistoryOptimizer = NULL;
      return false;
     }
   context->Logger->LogDebug("Module TradeHistoryOptimizer đã được khởi tạo.");

   return true;
  }

//+------------------------------------------------------------------+
//| Khởi tạo các module UI và Dashboard                             |
//+------------------------------------------------------------------+
bool InitializeUIModules(EAContext* context)
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("InitializeUIModules: Context or Logger is NULL");
      return false;
     }

// Khởi tạo Module Dashboard
   if(context->DisplayDashboard && (!::MQLInfoInteger(MQL_TESTER) || !context->DisableDashboardInBacktest))
     {
      context->Logger->LogDebug("Khởi tạo Module Dashboard...");
      context->Dashboard = new CDashboard(*context);
      if(context->Dashboard == NULL)
        {
         context->Logger->LogWarning("LƯU Ý: Không thể khởi tạo Module Dashboard. Tiếp tục mà không có Dashboard.");
         // Không trả về false ở đây, Dashboard là tùy chọn
        }
      else
        {
         context->Logger->LogDebug("Module Dashboard đã được khởi tạo.");
        }
     }
   else
     {
      context->Logger->LogInfo("Module Dashboard không được kích hoạt hoặc đang trong backtest.");
     }

// Khởi tạo Module PerformanceDashboard
   if(context->DisplayDashboard && (!::MQLInfoInteger(MQL_TESTER) || !context->DisableDashboardInBacktest))
     {
      context->Logger->LogDebug("Khởi tạo Module PerformanceDashboard...");
      context->PerformanceDashboard = new CPerformanceDashboard();
      if(context->PerformanceDashboard == NULL)
        {
         context->Logger->LogWarning("LƯU Ý: Không thể khởi tạo Module PerformanceDashboard. Tiếp tục mà không có Performance Dashboard.");
        }
      else
        {
         if(!context->PerformanceDashboard->Initialize(context))
           {
            context->Logger->LogWarning("LƯU Ý: Không thể khởi tạo PerformanceDashboard. Tiếp tục mà không có Performance Dashboard.");
            delete context->PerformanceDashboard;
            context->PerformanceDashboard = NULL;
           }
         else
           {
            context->Logger->LogDebug("Module PerformanceDashboard đã được khởi tạo.");
           }
        }
     }
   else
     {
      context->Logger->LogInfo("Module PerformanceDashboard không được kích hoạt hoặc đang trong backtest.");
     }

   return true;
  }

} // END namespace ApexPullback

//+------------------------------------------------------------------+
//| Hàm khởi tạo EA                                                |
//+------------------------------------------------------------------+
int OnInit()
  {
   using namespace ApexPullback; // Ensure namespace is used for g_EAContext and other types

// Initialize EA Context first
   g_EAContext = new EAContext();
   if(g_EAContext == NULL)
     {
      Print("[LỖI NGHIÊM TRỌNG] Không thể khởi tạo EAContext. EA không thể khởi động.");
      return INIT_FAILED;
     }

   // --- BƯỚC 1: Nạp tất cả các tham số đầu vào vào Context ---
   LoadParametersToContext(g_EAContext);

   // --- BƯỚC 2: Thiết lập các thuộc tính Context ban đầu ---
   g_EAContext->ChartId = ChartID();
   g_EAContext->ChartPrefix = "APEX_PB_" + IntegerToString(g_EAContext->ChartId) + "_";
   g_EAContext->Symbol = _Symbol;
   g_EAContext->MainTimeframe = (ENUM_TIMEFRAMES)_Period;
   g_EAContext->DebugMode = InDebugMode; // From Inputs.mqh
   g_EAContext->VerboseMode = InVerboseMode; // From Inputs.mqh

   // --- BƯỚC 3: Xác thực các tham số đã nạp ---
   if(!ValidateInputParameters(*g_EAContext))
     {
      Print("[LỖI NGHIÊM TRỌNG] Tham số đầu vào không hợp lệ. EA không thể khởi động.");
      delete g_EAContext;
      g_EAContext = NULL;
      return INIT_PARAMETERS_INCORRECT;
     }

// Khởi tạo các module thông qua helper functions
// InitializeCoreModules sẽ khởi tạo Logger trước tiên.
   if(!InitializeCoreModules(*g_EAContext))
     {
      Print("[LỖI NGHIÊM TRỌNG] Khởi tạo Core Modules thất bại. EA không thể khởi động.");
      CleanupPartialInit();
      return INIT_FAILED;
     }
// Từ đây, g_EAContext->Logger đã sẵn sàng để sử dụng.

   // --- BƯỚC 3.5: Khởi tạo FunctionStack NGAY SAU Logger ---
   // Phải khởi tạo ở đây để mọi lỗi sau đó đều có thể được bắt và ghi lại stack trace
   g_EAContext->FunctionStack = new CFunctionStack();
   if(g_EAContext->FunctionStack == NULL)
     {
      g_EAContext->Logger->LogError("LỖI NGHIÊM TRỌNG: Không thể cấp phát bộ nhớ cho FunctionStack. Tắt EA.");
      CleanupPartialInit();
      return INIT_FAILED;
     }
   g_EAContext->FunctionStack->Initialize(g_EAContext->Logger);
   g_EAContext->Logger->LogDebug("Module FunctionStack đã được khởi tạo.");

   g_EAContext->Logger->LogInfo("Bắt đầu khởi tạo APEX Pullback EA v14.0...");
   g_EAContext->Logger->LogDebug("Các biến context đã được nạp từ LoadParametersToContext.");

   try
     {
      g_EAContext->Logger->LogInfo("Bắt đầu khởi tạo các module chính thông qua helper functions...");

      if(!InitializeAnalysisModules(*g_EAContext))
        {
         // Logger đã sẵn sàng, không cần Print() nữa
         g_EAContext->Logger->LogError("Khởi tạo Analysis Modules thất bại.");
         throw new CException("Khởi tạo Analysis Modules thất bại.");
        }

      if(!InitializeManagementModules(*g_EAContext))
        {
         g_EAContext->Logger->LogError("Khởi tạo Management Modules thất bại.");
         throw new CException("Khởi tạo Management Modules thất bại.");
        }

      if(!InitializeStrategicModules(*g_EAContext))
        {
         g_EAContext->Logger->LogError("Khởi tạo Strategic Modules thất bại.");
         throw new CException("Khởi tạo Strategic Modules thất bại.");
        }

      if(!InitializeSupportingModules(*g_EAContext))
        {
         g_EAContext->Logger->LogError("Khởi tạo Supporting Modules thất bại.");
         throw new CException("Khởi tạo Supporting Modules thất bại.");
        }

      if(!InitializeUIModules(*g_EAContext))
        {
         g_EAContext->Logger->LogWarning("Khởi tạo UI Modules thất bại. Tiếp tục mà không có UI.");
         // Không throw exception vì UI modules là tùy chọn
        }

      g_EAContext->Logger->LogInfo("Hoàn tất khởi tạo tất cả các module chính.");

      // --- Bước 5: Cập nhật dữ liệu và cấu hình ban đầu ---
      g_EAContext->Logger->LogDebug("Cập nhật dữ liệu thị trường ban đầu...");
      if(!UpdateMarketData())    // UpdateMarketData là hàm toàn cục, cần xem xét đưa vào context hoặc namespace
        {
         g_EAContext->Logger->LogWarning("Không thể cập nhật dữ liệu thị trường ban đầu. Tiếp tục với dữ liệu mặc định.");
        }
      g_EAContext->Logger->LogDebug("Dữ liệu thị trường ban đầu đã được cập nhật.");

      if(g_EAContext->MarketPreset != ENUM_MARKET_PRESET::PRESET_AUTO)
        {
         g_EAContext->Logger->LogDebug("Áp dụng preset thị trường: " + EnumToString(g_EAContext->MarketPreset) + "...");
         AdjustParametersByPreset(g_EAContext);    // AdjustParametersByPreset là hàm toàn cục, kiểu void
         g_EAContext->Logger->LogDebug("Preset thị trường đã được áp dụng.");
        }

      g_EAContext->Logger->LogDebug("Nạp cấu hình từ file (nếu có)...");
      if(!LoadConfiguration(g_EAContext))    // LoadConfiguration là hàm toàn cục
        {
         g_EAContext->Logger->LogWarning("Không thể nạp cấu hình từ file. Sử dụng cấu hình mặc định.");
        }
      g_EAContext->Logger->LogDebug("Cấu hình đã được nạp.");

      g_EAContext->Logger->LogDebug("Thiết lập các biến toàn cục của Terminal...");
      GlobalVariableSet("EMA_Fast", g_EAContext->EMA_Fast);
      GlobalVariableSet("EMA_Medium", g_EAContext->EMA_Medium);
      GlobalVariableSet("EMA_Slow", g_EAContext->EMA_Slow);
      g_EAContext->Logger->LogDebug("Các biến toàn cục của Terminal đã được thiết lập.");

      g_EAContext->IsInitialized = true;

      string initSuccessMessage = "APEX Pullback EA v14.0 đã khởi động thành công!";
      initSuccessMessage += " | Ticks: 0 | Errors: 0 | Memory: " + DoubleToString(GetMemoryUsage(g_EAContext), 2) + "MB";

      g_EAContext->Logger->LogInfo(initSuccessMessage);
      if(g_EAContext->EnableTelegramNotify)
        {
         g_EAContext->Logger->SendTelegramMessage(initSuccessMessage, true);
        }

      LogSystemInfo(g_EAContext); // LogSystemInfo là hàm toàn cục

      if(EventSetMillisecondTimer(1000))
        {
         G_TIMER_ID = 1; // Giá trị dương để biểu thị timer đã được thiết lập
         g_EAContext->Logger->LogInfo("Timer được thiết lập thành công.");
        }
      else
        {
         G_TIMER_ID = -1;
         g_EAContext->Logger->LogError("Không thể tạo timer!");
        }

      return INIT_SUCCEEDED;

     }
   catch(CException* e)
     {
      string error_message = "LỖI NGOẠI LỆ trong OnInit: " + e.Description();
      // Logger có thể chưa được khởi tạo nếu lỗi xảy ra rất sớm trong InitializeCoreModules
      if(g_EAContext != NULL && g_EAContext->Logger != NULL)
        {
         g_EAContext->Logger->LogError(error_message);
        }
      else
        {
         Print(error_message);
        }
      if(e != NULL)
         e.Delete(); // Kiểm tra e trước khi Delete
      CleanupPartialInit();
      return INIT_FAILED;
     }
   catch(...)
     {
      string error_message = "LỖI NGOẠI LỆ KHÔNG XÁC ĐỊNH trong OnInit.";
      if(g_EAContext != NULL && g_EAContext->Logger != NULL)
        {
         g_EAContext->Logger->LogError(error_message);
        }
      else
        {
         Print(error_message);
        }
      CleanupPartialInit();
      return INIT_FAILED;
     }
  }

//+------------------------------------------------------------------+
//| Hàm xử lý mỗi tick                                              |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Expert tick function - MT5 entry point                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   // The global OnTick() now directly calls the namespaced OnTickLogic with the context.
   // Dashboard updates are handled within OnTickLogic or its helpers.


// The global OnTick() now directly calls the namespaced OnTickLogic with the context.
   if(ApexPullback::g_EAContext != NULL)
     {
      ApexPullback::OnTickLogic(ApexPullback::g_EAContext);
     }
   else
     {
      // Minimal logging if context is not available, to avoid spamming Print
      static ulong error_print_counter = 0;
      error_print_counter++;
      if(error_print_counter % 1000 == 0)    // Print every 1000th uninitialized tick
        {
         Print("APEX Pullback EA Error: EAContext is NULL in OnTick. Initialization might have failed.");
        }
     }
  }

//+------------------------------------------------------------------+
//| Implementation của các hàm bổ sung                               |
//+------------------------------------------------------------------+

namespace ApexPullback
{

// Hàm logic chính của OnTick, nhận EAContext làm tham số
void OnTickLogic(EAContext* context)
  {
   if(context == NULL)
     {
      // This case should ideally be caught by the caller, but as a safeguard:
      static ulong internal_error_counter = 0;
      internal_error_counter++;
      if(internal_error_counter % 1000 == 0)
        {
         Print("APEX Pullback EA Error: EAContext is NULL inside OnTickLogic.");
        }
      return;
     }

// Kiểm tra trạng thái khẩn cấp và khởi tạo
   if(context->EmergencyStop || context->IsShuttingDown || !context->IsInitialized)
     {
      return;
     }

// Kiểm tra xem các module quan trọng đã được khởi tạo chưa
   if(context->Logger == NULL || context->TradeManager == NULL || context->PositionManager == NULL)
     {
      context->ErrorCounter++;
      if(context->ErrorCounter % 100 == 0)    // Chỉ log mỗi 100 lần để tránh spam
        {
         Print("LỖI: Các module chính (Logger, TradeManager, PositionManager) chưa được khởi tạo trong EAContext. OnTick bị bỏ qua. (Lần thứ " + IntegerToString(context->ErrorCounter) + ")");
        }
      return;
     }

// Sử dụng try-catch để bắt lỗi trong OnTick
   try
     {
      datetime currentTime = TimeCurrent();
      datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      bool isNewBar = (currentBarTime != context->LastBarTime);

      // KIỂM TRA CIRCUIT BREAKER - Ưu tiên cao nhất
      if(context->CircuitBreaker != NULL)
        {
         context->CircuitBreaker->MonitorMarketConditions();
         if(context->CircuitBreaker->IsEmergencyTriggered())
           {
            context->Logger->LogCritical("CIRCUIT BREAKER ACTIVATED: Tạm dừng mọi hoạt động giao dịch!");
            context->EmergencyStop = true;
            context->CircuitBreakerActive = true;

            // Gửi cảnh báo khẩn cấp qua Portfolio Communication
            if(context->FileCommunication != NULL && context->EnablePortfolioMode)
              {
               context->FileCommunication->SendEmergencyStop("Circuit Breaker Triggered", "Market anomaly detected");
              }
            return;
           }
        }

      context->TickCounter++;
      context->LastTickTime = currentTime;

      // Kiểm tra tần suất tick quá cao (có thể là lỗi)
      static datetime lastTickCheck = 0;
      static int ticksInSecond = 0;

      if(currentTime != lastTickCheck)
        {
         if(ticksInSecond > 1000)    // Quá 1000 ticks/giây
           {
            context->Logger->LogWarning("Phát hiện tần suất tick bất thường: " + IntegerToString(ticksInSecond) + " ticks/giây");
           }
         ticksInSecond = 0;
         lastTickCheck = currentTime;
        }
      else
        {
         ticksInSecond++;
        }

      // Ghi log debug có điều kiện và thông minh hơn
      if(context->EnableDetailedLogs)
        {
         if(isNewBar || (context->TickCounter % 500 == 0))
           {
            context->Logger->LogDebug("OnTick #" + IntegerToString(context->TickCounter) +
                                      " - Bar: " + TimeToString(currentBarTime) +
                                      " - Spread: " + DoubleToString(GetCachedSpread(context), 1)); // GetCachedSpread now takes context
           }
        }

      // Kiểm tra điều kiện giao dịch cơ bản
      if(!context->AllowNewTrades)
        {
         if(context->EnableDetailedLogs && isNewBar)
           {
            context->Logger->LogDebug("Giao dịch mới hiện đang bị vô hiệu hóa.");
           }
         ManageExistingPositions(context);
         UpdateDashboardIfNeeded(currentTime, context);
         return;
        }

      // Xử lý nến mới và cập nhật hồ sơ tài sản
      if(isNewBar)
        {
         context->LastBarTime = currentBarTime;

         // STRATEGY OPTIMIZER - Walk-Forward Analysis
         if(context->StrategyOptimizer != NULL)
           {
            context->StrategyOptimizer->OnNewBar();

            // Kiểm tra tính ổn định của tham số
            if(!context->StrategyOptimizer->AreParametersStable())
              {
               context->Logger->LogWarning("STRATEGY OPTIMIZER: Tham số không ổn định, cần tối ưu hóa lại.");
               context->CurrentParameterStability = context->StrategyOptimizer->GetParameterStability();

               // Tạm dừng giao dịch mới nếu tham số quá không ổn định
               if(context->CurrentParameterStability < 0.3) // Ngưỡng 30%
                 {
                  context->AllowNewPositions = false;
                  context->Logger->LogWarning("Tạm dừng giao dịch mới do tham số không ổn định.");
                 }
              }
            else
              {
               context->AllowNewPositions = true;
               context->CurrentParameterStability = context->StrategyOptimizer->GetParameterStability();
              }
           }

         // PARAMETER STABILITY ANALYZER - Enhanced Monitoring
         if(context->ParameterStabilityAnalyzer != NULL)
           {
            context->ParameterStabilityAnalyzer->Update();
            context->ParameterStabilityIndex = context->ParameterStabilityAnalyzer->GetIndex();
            context->IsStrategyUnstable = !context->ParameterStabilityAnalyzer->IsStrategyStable(0.6);

            // Ngay trước khi tìm tín hiệu vào lệnh mới
            if(context->IsStrategyUnstable)
              {
               context->AllowNewTrades = false;
               context->Logger->LogCritical("GIAO DỊCH TẠM DỪNG: Tham số chiến lược không còn ổn định! Index: " + DoubleToString(context->ParameterStabilityIndex, 3));

               // Gửi cảnh báo qua Portfolio Communication
               if(context->FileCommunication != NULL && context->EnablePortfolioMode)
                 {
                  context->FileCommunication->SendEmergencyStop("Parameter Instability", "Strategy parameters are no longer stable");
                 }

               ManageExistingPositions(context);
               UpdateDashboardIfNeeded(currentTime, context);
               return; // Bỏ qua việc tìm kiếm tín hiệu mới
              }
           }

         // Bước 1: Cập nhật dữ liệu thị trường cho AssetDNA (nếu cần, hoặc AssetDNA tự quản lý)
         // Ví dụ: context->AssetDNA->UpdateMarketData(context->CurrentMarketData); // Giả sử có hàm này

         // Bước 2: Lựa chọn chiến lược tối ưu từ AssetDNA
         if(context->AssetDNA != NULL)
           {
            ENUM_TRADING_STRATEGY activeStrategy = context->AssetDNA->GetOptimalStrategy(); // Không cần truyền CurrentProfileData nữa nếu AssetDNA tự quản lý
            context->CurrentStrategy = activeStrategy; // Lưu chiến lược hiện tại vào context
            context->Logger->LogDebug("AssetDNA đã chọn chiến lược: " + EnumToString(activeStrategy));

            // Bước 3: Thực thi theo chiến lược được chọn
            switch(activeStrategy)
              {
               case STRATEGY_PULLBACK_TREND:
                  context->Logger->LogDebug("Thực thi chiến lược PULLBACK_TREND");
                  ProcessPullbackStrategy(context);
                  break;
               case STRATEGY_MEAN_REVERSION:
                  context->Logger->LogDebug("Thực thi chiến lược MEAN_REVERSION");
                  ProcessMeanReversionStrategy(context);
                  break;
               case STRATEGY_MOMENTUM_BREAKOUT:
                  context->Logger->LogDebug("Thực thi chiến lược MOMENTUM_BREAKOUT");
                  ProcessMomentumBreakoutStrategy(context);
                  break;
               case STRATEGY_RANGE_TRADING:
                  context->Logger->LogDebug("Thực thi chiến lược RANGE_TRADING");
                  ProcessRangeStrategy(context);
                  break;
               default:
                  context->Logger->LogDebug("AssetDNA không đề xuất chiến lược nào hoặc điểm số quá thấp.");
                  break;
              }
           }
         else
           {
            context->Logger->LogWarning("AssetDNA chưa được khởi tạo. Không thể lựa chọn chiến lược động.");
           }

         // *** LOẠI BỎ LUỒNG XỬ LÝ SONG SONG - KHÔNG GỌI ProcessNewBar ***
         // ProcessNewBar(currentTime, currentBarTime, context); // COMMENTED OUT
        }

      // Kiểm tra các điều kiện giao dịch với cache
      if(!CheckTradingConditionsOptimized(currentTime, context))
        {
         ManageExistingPositions(context);
         UpdateDashboardIfNeeded(currentTime, context);
         return;
        }

      // PORTFOLIO COMMUNICATION - Nâng cấp với FileCommunication
      if(context->FileCommunication != NULL && context->EnablePortfolioMode)
        {
         // Gửi heartbeat định kỳ
         static datetime lastHeartbeat = 0;
         if(currentTime - lastHeartbeat >= 30) // Mỗi 30 giây
           {
            context->FileCommunication->SendHeartbeat();
            lastHeartbeat = currentTime;
           }

         // Xử lý tin nhắn Portfolio
         PortfolioMessage messages[];
         int messageCount = context->FileCommunication->ReceivePortfolioMessages(messages);

         if(messageCount > 0)
           {
            context->Logger->LogInfo("Nhận được " + IntegerToString(messageCount) + " tin nhắn Portfolio.");
            context->LastPortfolioMessageTime = currentTime;
           }

         if(context->PortfolioMasterEA)
           {
            // Master EA: Xử lý đề xuất giao dịch từ các Slave EA
            if(context->PortfolioManager != NULL)
              {
               context->PortfolioManager->ProcessTradeProposals();
               context->Logger->LogDebug("Master EA: Đã xử lý các đề xuất giao dịch.");
              }
           }
         else
           {
            // Slave EA: Gửi đề xuất giao dịch qua FileCommunication
            if(context->PatternDetector != NULL && context->PatternDetector->HasNewSignal())
              {
               ENUM_ORDER_TYPE direction = context->PatternDetector->GetSignalDirection();
               double signalQuality = context->PatternDetector->GetSignalQuality();
               double riskPercent = context->RiskManager->GetCurrentRiskPercent();
               double lotSize = context->RiskManager->CalculateOptimalLotSize();

               if(context->FileCommunication->SendTradeProposal(_Symbol, direction, lotSize,
                     SymbolInfoDouble(_Symbol, SYMBOL_BID),
                     SymbolInfoDouble(_Symbol, SYMBOL_ASK),
                     signalQuality, riskPercent, "Pattern Signal"))
                 {
                  context->Logger->LogInfo("Slave EA: Đã gửi đề xuất giao dịch cho " + _Symbol);
                  context->isWaitingForDecision = true;
                  context->decisionSentTime = currentTime;
                 }
               else
                 {
                  context->Logger->LogError("Slave EA: Không thể gửi đề xuất giao dịch.");
                 }
              }
           }
        }

      // Quản lý các vị thế đang mở
      ManageExistingPositions(context);

      // Các tác vụ cập nhật định kỳ (Dashboard, Performance Metrics, Memory Check)
      // đã được chuyển sang OnTimerLogic để giảm tải cho OnTick.

      // Reset error counter khi thành công
      if(context->ErrorCounter > 0)
        {
         context->ErrorCounter = 0;
        }

     }
   catch(CException* e)
     {
      context->ErrorCounter++;
      context->Logger->LogError("Lỗi ngoại lệ trong OnTick #" + IntegerToString(context->TickCounter) + ": " + e.Description());
      // Keep original catch blocks for CException and generic exception

      e->Delete(); // Assuming e is a pointer to CException

      // Kích hoạt emergency stop nếu quá nhiều lỗi
      if(context->ErrorCounter > 1000)    // Use context's error counter
        {
         context->EmergencyStop = true;
         context->Logger->LogError("EMERGENCY STOP: Quá nhiều lỗi liên tiếp (" + IntegerToString(context->ErrorCounter) + ")");
        }
     }
   catch(...)
     {
      context->ErrorCounter++; // Use context's error counter
      if(context->Logger != NULL)    // Use context's logger
        {
         context->Logger->LogError("Lỗi không xác định trong OnTick #" + IntegerToString(context->TickCounter)); // Use context's tick counter
        }

      // Kích hoạt emergency stop nếu quá nhiều lỗi
      if(context->ErrorCounter > 1000)    // Use context's error counter
        {
         context->EmergencyStop = true;
         if(context->Logger != NULL)    // Use context's logger
           {
            context->Logger->LogError("EMERGENCY STOP: Quá nhiều lỗi không xác định (" + IntegerToString(context->ErrorCounter) + ")");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Hàm kiểm tra các điều kiện giao dịch với tối ưu hóa cache      |
//+------------------------------------------------------------------+
bool ApexPullback::CheckTradingConditionsOptimized(datetime currentTime, EAContext* context)
  {
// Cache kết quả kiểm tra để tránh tính toán lặp lại
   static bool lastSessionCheck = true;
   static bool lastNewsCheck = false;
   static datetime lastSessionCheckTime = 0;
   static datetime lastNewsCheckTime = 0;

// Kiểm tra phiên giao dịch (cache 60 giây)
   if(currentTime - lastSessionCheckTime > 60)
     {
      lastSessionCheck = IsAllowedTradingSession();
      lastSessionCheckTime = currentTime;
     }

   if(!lastSessionCheck)
     {
      if(g_EAContext->Logger != NULL && g_EAContext->Logger->IsVerboseLogging() && currentTime - lastSessionCheckTime < 5)
        {
         g_EAContext->Logger->LogDebug("Ngoài phiên giao dịch cho phép.");
        }
      return false;
     }

// Kiểm tra ảnh hưởng tin tức (cache 30 giây)
   if(currentTime - lastNewsCheckTime > 30)
     {
      lastNewsCheck = IsNewsImpactPeriod();
      lastNewsCheckTime = currentTime;
     }

   if(lastNewsCheck)
     {
      if(g_EAContext->Logger != NULL && g_EAContext->Logger->IsVerboseLogging() && currentTime - lastNewsCheckTime < 5)
        {
         g_EAContext->Logger->LogDebug("Hiện đang trong thời gian ảnh hưởng tin tức. Giao dịch tạm dừng.");
        }
      return false;
     }

// Kiểm tra spread với cache thông minh
   double currentSpread = GetCachedSpread(context); // Bây giờ đã đúng vì context được truyền vào hàm
   double maxSpreadValue = context->MaxSpreadPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   if(currentSpread > maxSpreadValue)
     {
      if(context->EnableDetailedLogs && context->Logger != NULL)
        {
         context->Logger->LogDebug("Spread hiện tại (" + DoubleToString(currentSpread, 2) +
                                   ") vượt quá ngưỡng tối đa (" + DoubleToString(maxSpreadValue, 2) + ")");
        }
      return false;
     }

// Kiểm tra drawdown hiện tại
   if(context->RiskManager != NULL && context->RiskManager->GetCurrentDrawdownPercent() > context->MaxDrawdown * 0.8)    // Cảnh báo khi gần đạt max drawdown
     {
      if(context->Logger != NULL && context->EnableDetailedLogs)
        {
         context->Logger->LogWarning("Drawdown hiện tại (" + DoubleToString(context->RiskManager->GetCurrentDrawdownPercent(), 2) +
                                     "%) gần đạt giới hạn tối đa (" + DoubleToString(context->MaxDrawdown, 2) + "%)");
        }
      return false;
     }

// Kiểm tra số lệnh trong ngày
   if(context->DayTrades >= context->MaxTradesPerDay)
     {
      if(context->EnableDetailedLogs && context->Logger != NULL)
        {
         context->Logger->LogDebug("Đã đạt số lệnh tối đa trong ngày: " + IntegerToString(context->DayTrades));
        }
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Hàm lấy spread với cache để tối ưu hiệu suất                   |
//+------------------------------------------------------------------+
double GetCachedSpread(EAContext* context)   // Accept context
  {
   if(context == NULL)
      return SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT); // Fallback if context is null

   datetime currentTime = TimeCurrent();

// Cache spread trong 2 giây
   if(currentTime - context->SpreadCacheTime > 2)
     {
      context->CachedSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      context->SpreadCacheTime = currentTime;
     }

   return context->CachedSpread;
  }

//+------------------------------------------------------------------+
//| Hàm quản lý các vị thế đang mở                                  |
//+------------------------------------------------------------------+
void ApexPullback::ManageExistingPositions(EAContext* context)   // Accept context
  {
   if(context == NULL || context->PositionManager == NULL)
      return;

   try
     {
      context->PositionManager->UpdateOpenPositions();
     }
   catch(...)
     {
      if(context->Logger != NULL)
        {
         context->Logger->LogError("Lỗi khi cập nhật vị thế đang mở");
        }
     }
  }

//+------------------------------------------------------------------+
//| Hàm cập nhật dashboard có điều kiện và tối ưu                  |
//+------------------------------------------------------------------+
void ApexPullback::UpdateDashboardIfNeeded(datetime currentTime, EAContext* context)   // Accept context
  {
   if(context == NULL || !context->DisplayDashboard)
      return;

// Cập nhật dashboard mỗi 5 giây để tránh lag (tăng từ 3 giây)
   if(currentTime - context->LastDashboardUpdateTime >= 5)
     {
      try
        {
         // Cập nhật Dashboard chính
         if(context->Dashboard != NULL)
           {
            context->Dashboard->Update();
           }

         // Cập nhật PerformanceDashboard
         if(context->PerformanceDashboard != NULL)
           {
            context->PerformanceDashboard->Update();
           }

         context->LastDashboardUpdateTime = currentTime;

         // Reset error count khi thành công
         if(context->DashboardErrorCount > 0)
           {
            context->DashboardErrorCount = 0;
           }
        }
      catch(...)
        {
         context->DashboardErrorCount++;
         if(context->Logger != NULL && context->DashboardErrorCount < 10)    // Chỉ log 10 lỗi đầu tiên
           {
            context->Logger->LogError("Lỗi khi cập nhật dashboard (lần thứ " + IntegerToString(context->DashboardErrorCount) + ")");
           }

         // Vô hiệu hóa dashboard nếu quá nhiều lỗi
         if(context->DashboardErrorCount > 50)
           {
            context->DisplayDashboard = false; // Update context's display flag
            if(context->Logger != NULL)
              {
               context->Logger->LogError("Vô hiệu hóa dashboard do quá nhiều lỗi liên tiếp");
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Hàm xử lý nến mới với logic tối ưu                             |
//+------------------------------------------------------------------+
void ApexPullback::ProcessNewBar(datetime currentTime, datetime currentBarTime, EAContext* context)
  {
   if(context == NULL)
      return;

   if(context->Logger != NULL)
     {
      context->Logger->LogInfo("Nến mới được phát hiện tại " + TimeToString(currentBarTime));
     }

// Cập nhật dữ liệu thị trường với xử lý lỗi
   if(!UpdateMarketDataOptimized(currentTime, context))    // Call with context
     {
      if(context->Logger != NULL)
        {
         context->Logger->LogWarning("Không thể cập nhật dữ liệu thị trường.");
        }
      return;
     }

// Cập nhật các điểm swing nếu cần
   if(context->SwingDetector != NULL)
     {
      try
        {
         context->SwingDetector->Update();
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi khi cập nhật SwingDetector");
           }
        }
     }

// Phân tích và tìm tín hiệu với xử lý lỗi
   ProcessNewBarSignals(context); // Call with context

// Thích ứng với điều kiện thị trường dài hạn (mỗi 4 giờ thay vì 24 giờ)
   if(currentTime - context->LastAdaptationTime > 14400)    // 14400 giây = 4 giờ
     {
      if(context->RiskManager != NULL)
        {
         try
           {
            if(context->RiskManager->AdaptToMarketCycle())
              {
               context->LastAdaptationTime = currentTime;
               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Đã thích ứng với chu kỳ thị trường.");
                 }
              }
           }
         catch(...)
           {
            if(context->Logger != NULL)
              {
               context->Logger->LogError("Lỗi khi thích ứng chu kỳ thị trường");
              }
           }
        }
     }

// Reset daily trade counter vào đầu ngày mới
   static int lastDay = -1;
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   if(dt.day != lastDay)
     {
      context->DayTrades = 0; // Use context->DayTrades
      lastDay = dt.day;
      if(context->Logger != NULL)
        {
         context->Logger->LogInfo("Reset bộ đếm giao dịch ngày mới: " + TimeToString(currentTime));
        }
     }


//+------------------------------------------------------------------+
//| Hàm cập nhật dữ liệu thị trường với tối ưu hóa                 |
//+------------------------------------------------------------------+
   bool ApexPullback::UpdateMarketDataOptimized(datetime currentTime, EAContext* context)
     {
      if(context == NULL)
         return false;

      // Chỉ cập nhật nếu đã qua 30 giây từ lần cập nhật cuối
      if(currentTime - context->LastMarketDataUpdate < 30)
        {
         return true; // Sử dụng dữ liệu cache
        }

      try
        {
         // UpdateMarketData will need to be refactored to use context or be context-aware
         bool result = UpdateMarketData(); // Assuming UpdateMarketData will be refactored or is context-aware
         if(result)
           {
            context->LastMarketDataUpdate = currentTime;
           }
         return result;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong UpdateMarketDataOptimized");
           }
         return false;
        }
     }

//+------------------------------------------------------------------+
//| Hàm xử lý tín hiệu giao dịch với bảo vệ lỗi nâng cao           |
//+------------------------------------------------------------------+
   void ApexPullback::ProcessTradeSignalsWithProtection(EAContext* context)
     {
      static int signalErrorCount = 0;
      static datetime lastSignalError = 0;

      try
        {
         ProcessTradeSignals(context);

         // Reset error count khi thành công
         if(signalErrorCount > 0)
           {
            signalErrorCount = 0;
           }
        }
      catch(...)
        {
         signalErrorCount++;
         datetime currentTime = TimeCurrent();

         if(context->Logger != NULL && (currentTime - lastSignalError > 60))    // Chỉ log mỗi phút
           {
            context->Logger->LogError("Lỗi khi xử lý tín hiệu giao dịch (lần thứ " + IntegerToString(signalErrorCount) + ")");
            lastSignalError = currentTime;
           }

         // Tạm dừng xử lý tín hiệu nếu quá nhiều lỗi
         if(signalErrorCount > 20)
           {
            context->AllowNewTrades = false;
            if(context->Logger != NULL)
              {
               context->Logger->LogError("Tạm dừng giao dịch mới do quá nhiều lỗi xử lý tín hiệu");
              }
           }
        }
     }

//+------------------------------------------------------------------+
//| Hàm cập nhật các chỉ số hiệu suất                              |
//+------------------------------------------------------------------+
   void ApexPullback::UpdatePerformanceMetrics(datetime currentTime, EAContext* context)
     {
      // Cập nhật mỗi 5 phút
      if(currentTime - context->LastPerformanceUpdate < 300)
        {
         return;
        }

      try
        {
         if(context->PerformanceTracker != NULL)
           {
            context->PerformanceTracker->UpdateMetrics();
           }

         // Cập nhật drawdown hiện tại
         if(context->RiskManager != NULL)
           {
            context->CurrentDrawdownPct = context->RiskManager->GetCurrentDrawdownPercent();
           }

         context->LastPerformanceUpdate = currentTime;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi khi cập nhật chỉ số hiệu suất");
           }
        }
     }

//+------------------------------------------------------------------+
//| Logic được thực thi bởi OnTimer                                  |
//+------------------------------------------------------------------+
   void ApexPullback::OnTimerLogic(EAContext* context)
     {
      if(context == NULL || context->IsShuttingDown)
        {
         return;
        }

      datetime currentTime = TimeCurrent();

      // === Logic cho Slave EA chờ quyết định ===
      // Giả sử EA này có thể là Slave, kiểm tra cờ isWaitingForDecision
      // Cần có một cách để xác định EA này là Slave, ví dụ: một input bool IsSlaveEA = true;
      // Hoặc dựa vào việc PortfolioManager có được khởi tạo hay không (nếu PM chỉ cho Master)
      // IsSlaveEA đã được chuyển vào Inputs.mqh và nạp vào context

      if(context->IsSlaveEA && context->isWaitingForDecision)    // Sử dụng context->IsSlaveEA
        {
         string decisionGvName = "GV_Decision_" + _Symbol;
         if(GlobalVariableCheck(decisionGvName))
           {
            string decisionValue = GlobalVariableGet(decisionGvName);
            GlobalVariableDel(decisionGvName); // Xóa GV sau khi đọc

            if(context->Logger != NULL)
               context->Logger->LogInfoFormat("Slave EA: Nhận được quyết định từ Master: %s cho %s", decisionValue, _Symbol);

            string parts[];
            StringSplit(decisionValue, ';', parts);

            if(ArraySize(parts) >= 2)
              {
               string decision = parts[0];
               double adjustedLotFactor = StringToDouble(parts[1]);

               if(decision == "APPROVE")
                 {
                  ProcessTradeSignalsWithProtection(context, adjustedLotFactor); // Giả sử adjustedLotFactor = 1.0 nếu chỉ approve
                  if(context->Logger != NULL)
                     context->Logger->LogInfo("Slave EA: Đề xuất được CHẤP NHẬN, thực hiện giao dịch.");
                 }
               else
                  if(decision == "ADJUST_LOT")
                    {
                     ProcessTradeSignalsWithProtection(context, adjustedLotFactor);
                     if(context->Logger != NULL)
                        context->Logger->LogInfo("Slave EA: Đề xuất được CHẤP NHẬN VỚI ĐIỀU CHỈNH KHỐI LƯỢNG, thực hiện giao dịch.");
                    }
                  else     // REJECT hoặc các trường hợp khác
                    {
                     if(context->Logger != NULL)
                        context->Logger->LogInfo("Slave EA: Đề xuất bị TỪ CHỐI hoặc HOÃN LẠI bởi Master.");
                    }
              }
            context->isWaitingForDecision = false; // Reset trạng thái chờ
           }
         else
           {
            // Chưa có quyết định, kiểm tra timeout (ví dụ: 30 giây)
            if(TimeCurrent() - context->decisionSentTime >= 30)    // Sử dụng context->decisionSentTime
              {
               if(context->Logger != NULL)
                  context->Logger->LogWarningFormat("Slave EA: Timeout khi chờ quyết định từ Master cho %s. Hủy đề xuất.", _Symbol);
               string proposalGvName = "GV_Proposal_" + _Symbol;
               GlobalVariableDel(proposalGvName); // Xóa GV đề xuất nếu timeout
               context->isWaitingForDecision = false; // Reset trạng thái chờ
              }
            else
              {
               // Vẫn đang trong thời gian chờ, không làm gì cả, đợi OnTimer tiếp theo
               if(context->Logger != NULL && (int)currentTime % 10 == 0)    // Log mỗi 10s để biết nó vẫn đang chờ
                 {
                  context->Logger->LogDebugFormat("Slave EA: Vẫn đang chờ quyết định từ Master cho %s... (%d giây đã trôi qua)", _Symbol, TimeCurrent() - context->decisionSentTime);
                 }
              }
           }
        }
      // === Kết thúc Logic cho Slave EA ===


      // Cập nhật Dashboard nếu cần
      UpdateDashboardIfNeeded(currentTime, context);

      // Cập nhật chỉ số hiệu suất
      UpdatePerformanceMetrics(currentTime, context);

      // Kiểm tra bộ nhớ định kỳ (ví dụ mỗi 60 giây)
      static datetime lastMemoryCheckTimer = 0;
      if(currentTime - lastMemoryCheckTimer >= 60)
        {
         if(!CheckMemoryAvailable())    // CheckMemoryAvailable is a global function
           {
            if(context->Logger != NULL)
              {
               context->Logger->LogWarning("Bộ nhớ khả dụng thấp, cân nhắc giảm tải hoặc khởi động lại EA.");
              }
           }
         lastMemoryCheckTimer = currentTime;
        }
     }

//+------------------------------------------------------------------+
//| Hàm xử lý tín hiệu trên nến mới                                 |
//+------------------------------------------------------------------+
   void ApexPullback::ProcessNewBarSignals(EAContext* context)
     {
      if(context == NULL)
         return;
      try
        {
         // Tìm kiếm tín hiệu giao dịch
         FindTradeSignals(context); // Call with context
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi khi tìm kiếm tín hiệu giao dịch");
           }
        }
     }

// Hàm tìm kiếm tín hiệu giao dịch
   bool ApexPullback::FindTradeSignals(EAContext* context)
     {
      if(context == NULL || context->Logger == NULL || context->MarketProfile == NULL || context->SwingDetector == NULL)
        {
         if(context != NULL && context->Logger != NULL)
           {
            context->Logger->LogError("Không thể tìm tín hiệu giao dịch: Module thiếu trong context.");
           }
         return false;
        }

      // Cài đặt cờ tín hiệu
      bool signalFound = false;

      // Thực hiện tìm kiếm tín hiệu
      try
        {
         // BƯỚC 1: Cập nhật dữ liệu thị trường mới nhất
         if(!context->MarketProfile->UpdateMarketData())
           {
            if(context->Logger != NULL)
              {
               context->Logger->LogWarning("Không thể cập nhật dữ liệu thị trường");
              }
            return false;
           }

         // BƯỚC 2: Lấy thông tin thị trường hiện tại
         ENUM_MARKET_TREND currentTrend = context->CurrentProfileData.trend;
         ENUM_MARKET_REGIME currentRegime = context->CurrentProfileData.regime;
         double volatilityLevel = context->CurrentProfileData.volatility;
         double momentumStrength = context->CurrentProfileData.momentum;

         // BƯỚC 3: Sử dụng AssetDNA để chọn chiến lược tối ưu
         ENUM_TRADING_STRATEGY optimalStrategy = STRATEGY_UNDEFINED;
         if(context->AssetDNA != NULL)
           {
            optimalStrategy = context->AssetDNA->GetOptimalStrategy(context->CurrentProfileData);
            if(context->EnableDetailedLogs && context->Logger != NULL)
              {
               context->Logger->LogDebug("AssetDNA đã chọn chiến lược: " + EnumToString(optimalStrategy));
              }
           }

         // BƯỚC 4: Kiểm tra điều kiện thị trường cơ bản
         if(!ValidateBasicMarketConditions(context))
           {
            if(context->EnableDetailedLogs && context->Logger != NULL)
              {
               context->Logger->LogDebug("Điều kiện thị trường cơ bản không phù hợp");
              }
            return false;
           }

         // BƯỚC 5: Tìm kiếm tín hiệu dựa trên chiến lược được chọn
         switch(optimalStrategy)
           {
            case STRATEGY_PULLBACK_TREND:
               signalFound = FindPullbackTrendSignals(context, currentTrend);
               break;

            case STRATEGY_MEAN_REVERSION:
               signalFound = FindMeanReversionSignals(context, currentRegime);
               break;

            case STRATEGY_MOMENTUM_BREAKOUT:
               signalFound = FindMomentumBreakoutSignals(context, momentumStrength);
               break;

            case STRATEGY_SHALLOW_PULLBACK:
               signalFound = FindShallowPullbackSignals(context, currentTrend);
               break;

            case STRATEGY_RANGE_TRADING:
               signalFound = FindRangeTradingSignals(context, currentRegime);
               break;

            default:
               if(context->Logger != NULL)
                 {
                  context->Logger->LogWarning("Chiến lược không được hỗ trợ: " + EnumToString(optimalStrategy));
                 }
               break;
           }

         // BƯỚC 6: Xác thực tín hiệu với các bộ lọc bổ sung
         if(signalFound)
           {
            signalFound = ValidateSignalWithFilters(context);
           }

         // BƯỚC 7: Log kết quả
         if(context->EnableDetailedLogs && context->Logger != NULL)
           {
            if(signalFound)
              {
               context->Logger->LogInfo("Tín hiệu giao dịch được phát hiện và xác thực");
              }
            else
              {
               context->Logger->LogDebug("Không tìm thấy tín hiệu giao dịch phù hợp");
              }
           }

         return signalFound;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi không xác định trong FindTradeSignals()");
           }
         return false;
        }
     }

// Hàm xử lý tín hiệu giao dịch
   void ApexPullback::ProcessTradeSignals(EAContext* context)
     {
      if(context == NULL || context->Logger == NULL || context->TradeManager == NULL || context->RiskManager == NULL ||
         context->PositionManager == NULL || context->MarketProfile == NULL || context->SwingDetector == NULL)
        {
         if(context != NULL && context->Logger != NULL)
           {
            context->Logger->LogError("Không thể xử lý tín hiệu giao dịch: Module thiếu trong context.");
           }
         return;
        }

      try
        {
         // BƯỚC 1: Kiểm tra các điều kiện tiên quyết
         if(!ValidatePrerequisites(context))
           {
            return;
           }

         // BƯỚC 2: Lấy chiến lược tối ưu từ AssetDNA
         ENUM_TRADING_STRATEGY currentStrategy = STRATEGY_UNDEFINED;
         if(context->AssetDNA != NULL)
           {
            currentStrategy = context->AssetDNA->GetOptimalStrategy(context->CurrentProfileData);
           }

         if(currentStrategy == STRATEGY_UNDEFINED)
           {
            if(context->Logger != NULL && context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Không có chiến lược phù hợp được AssetDNA chọn");
              }
            return;
           }

         // BƯỚC 3: Kiểm tra Risk Management trước khi giao dịch
         if(!context->RiskManager->CanOpenNewTrade())
           {
            if(context->Logger != NULL && context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Risk Manager không cho phép mở lệnh mới");
              }
            return;
           }

         // BƯỚC 4: Tính toán kích thước lệnh tối ưu
         double optimalLotSize = 0.0;
         if(context->RiskOptimizer != NULL)
           {
            double riskPercent = context->RiskOptimizer->GetOptimizedRiskPercent();
            optimalLotSize = context->RiskManager->CalculateOptimalLotSize(riskPercent);
           }
         else
           {
            optimalLotSize = context->RiskManager->CalculateOptimalLotSize(context->RiskPercent);
           }

         if(optimalLotSize <= 0)
           {
            if(context->Logger != NULL)
              {
               context->Logger->LogWarning("Không thể tính toán kích thước lệnh phù hợp");
              }
            return;
           }

         // BƯỚC 5: Xử lý tín hiệu theo chiến lược được chọn
         bool tradeExecuted = false;
         switch(currentStrategy)
           {
            case STRATEGY_PULLBACK_TREND:
               tradeExecuted = ProcessPullbackTrendStrategy(context, optimalLotSize);
               break;

            case STRATEGY_MEAN_REVERSION:
               tradeExecuted = ProcessMeanReversionStrategyAdvanced(context, optimalLotSize);
               break;

            case STRATEGY_MOMENTUM_BREAKOUT:
               tradeExecuted = ProcessMomentumBreakoutStrategyAdvanced(context, optimalLotSize);
               break;

            case STRATEGY_SHALLOW_PULLBACK:
               tradeExecuted = ProcessShallowPullbackStrategy(context, optimalLotSize);
               break;

            case STRATEGY_RANGE_TRADING:
               tradeExecuted = ProcessRangeTradingStrategyAdvanced(context, optimalLotSize);
               break;

            default:
               if(context->Logger != NULL)
                 {
                  context->Logger->LogWarning("Chiến lược không được hỗ trợ trong ProcessTradeSignals: " + EnumToString(currentStrategy));
                 }
               break;
           }

         // BƯỚC 6: Cập nhật thống kê và trạng thái
         if(tradeExecuted)
           {
            context->DayTrades++;

            // Cập nhật AssetDNA với kết quả giao dịch
            if(context->AssetDNA != NULL)
              {
               context->AssetDNA->UpdateStrategyUsage(currentStrategy);
              }

            // Log thành công
            if(context->Logger != NULL)
              {
               context->Logger->LogInfo(StringFormat("Đã thực thi giao dịch thành công - Chiến lược: %s, Lot: %.2f, Tổng lệnh trong ngày: %d",
                                                     EnumToString(currentStrategy), optimalLotSize, context->DayTrades));
              }
           }
         else
           {
            if(context->Logger != NULL && context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Không thể thực thi giao dịch cho chiến lược: " + EnumToString(currentStrategy));
              }
           }
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi không xác định trong ProcessTradeSignals()");
           }
        }
     }

//+------------------------------------------------------------------+
//| Các hàm xử lý chiến lược được AssetDNA lựa chọn                |
//+------------------------------------------------------------------+

// Xử lý chiến lược Pullback Trend
   void ProcessPullbackStrategy(EAContext* context)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return;

      try
        {
         // Gọi trực tiếp PatternDetector để phát hiện pullback patterns
         if(context->PatternDetector->DetectPullbackPatterns())
           {
            // Lấy thông tin chi tiết về pattern đã phát hiện
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               bool isLong = patternInfo.isBullish;
               ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_PULLBACK_FIBONACCI;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Pullback Trend: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager
               if(context->TradeManager->OpenPosition(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, detectedPattern))
                 {
                  context->DayTrades++;
                 }
              }
           }
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessPullbackStrategy");
           }
        }
     }

// Xử lý chiến lược Mean Reversion
   void ProcessMeanReversionStrategy(EAContext* context)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return;

      try
        {
         // Bước 2: Gọi DetectMeanReversionPattern cho thị trường đi ngang
         bool isBullish = false;
         ApexPullback::DetectedPattern patternInfo;

         if(context->PatternDetector->DetectMeanReversionPattern(isBullish, patternInfo))
           {
            ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_MEAN_REVERSION;

            if(context->Logger != NULL)
              {
               context->Logger->LogInfo("Phát hiện tín hiệu Mean Reversion: " + (isBullish ? "LONG" : "SHORT") +
                                        ", Strength: " + DoubleToString(patternInfo.strength, 2) +
                                        ", Description: " + patternInfo.description);
              }

            // Mở lệnh thông qua TradeManager
            if(context->TradeManager->OpenPosition(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, detectedPattern))
              {
               context->DayTrades++;
              }
           }
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessMeanReversionStrategy");
           }
        }
     }

// Xử lý chiến lược Momentum Breakout
   void ProcessMomentumBreakoutStrategy(EAContext* context)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return;

      try
        {
         // Gọi trực tiếp PatternDetector để phát hiện breakout patterns
         if(context->PatternDetector->DetectBreakoutPatterns())
           {
            // Lấy thông tin chi tiết về pattern đã phát hiện
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               bool isLong = patternInfo.isBullish;
               ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_BREAKOUT_MOMENTUM;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Momentum Breakout: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager
               if(context->TradeManager->OpenPosition(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, detectedPattern))
                 {
                  context->DayTrades++;
                 }
              }
           }
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessMomentumBreakoutStrategy");
           }
        }
     }

// Xử lý chiến lược Range Trading
   void ProcessRangeStrategy(EAContext* context)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return;

      try
        {
         // Logic cho range trading - có thể sử dụng cả pullback và reversal
         bool foundSignal = false;
         bool isLong = true; // Sẽ được xác định từ pattern detector
         ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_RANGE_BOUNCE;

         // Thử phát hiện pullback trong range
         if(context->PatternDetector->DetectPullbackPatterns())
           {
            foundSignal = true;
            detectedPattern = ENTRY_PULLBACK_FIBONACCI;
           }
         // Nếu không có pullback, thử reversal
         else
            if(context->PatternDetector->DetectReversalPatterns())
              {
               foundSignal = true;
               detectedPattern = ENTRY_REVERSAL_DIVERGENCE;
              }

         if(foundSignal)
           {
            // Lấy thông tin chi tiết về pattern đã phát hiện
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               isLong = patternInfo.isBullish;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Range Trading: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager
               if(context->TradeManager->OpenPosition(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, detectedPattern))
                 {
                  context->DayTrades++;
                 }
              }
           }
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessRangeStrategy");
           }
        }
     }

//+------------------------------------------------------------------+
//| Helper Functions cho FindTradeSignals                           |
//+------------------------------------------------------------------+

// Kiểm tra điều kiện thị trường cơ bản
   bool ValidateBasicMarketConditions(EAContext* context)
     {
      if(context == NULL || context->MarketProfile == NULL || context->Logger == NULL)
         return false;

      try
        {
         // Kiểm tra spread
         double currentSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double maxAllowedSpread = context->MaxSpreadPoints * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

         if(currentSpread > maxAllowedSpread)
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug(StringFormat("Spread quá cao: %.1f > %.1f", currentSpread/_Point, maxAllowedSpread/_Point));
              }
            return false;
           }

         // Kiểm tra volatility
         if(context->CurrentProfileData.volatility > context->MaxVolatilityThreshold)
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug(StringFormat("Volatility quá cao: %.3f > %.3f",
                                                      context->CurrentProfileData.volatility, context->MaxVolatilityThreshold));
              }
            return false;
           }

         // Kiểm tra thời gian giao dịch
         datetime currentTime = TimeCurrent();
         MqlDateTime timeStruct;
         TimeToStruct(currentTime, timeStruct);

         if(timeStruct.hour < context->TradingStartHour || timeStruct.hour >= context->TradingEndHour)
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug(StringFormat("Ngoài giờ giao dịch: %d (cho phép: %d-%d)",
                                                      timeStruct.hour, context->TradingStartHour, context->TradingEndHour));
              }
            return false;
           }

         return true;
        }
      catch(...)
        {
         context->Logger->LogError("Lỗi trong ValidateBasicMarketConditions");
         return false;
        }
     }

// Tìm tín hiệu Pullback Trend
   bool FindPullbackTrendSignals(EAContext* context, ENUM_MARKET_TREND trend)
     {
      if(context == NULL || context->PatternDetector == NULL)
         return false;

      try
        {
         // Chỉ tìm pullback khi có xu hướng rõ ràng
         if(trend != TREND_UP_STRONG && trend != TREND_UP_NORMAL &&
            trend != TREND_DOWN_STRONG && trend != TREND_DOWN_NORMAL)
           {
            return false;
           }

         // Sử dụng PatternDetector để phát hiện pullback
         bool pullbackFound = context->PatternDetector->DetectPullbackPatterns();

         if(pullbackFound && context->EnableDetailedLogs)
           {
            context->Logger->LogDebug("Phát hiện tín hiệu Pullback Trend");
           }

         return pullbackFound;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong FindPullbackTrendSignals");
         return false;
        }
     }

// Tìm tín hiệu Mean Reversion
   bool FindMeanReversionSignals(EAContext* context, ENUM_MARKET_REGIME regime)
     {
      if(context == NULL || context->PatternDetector == NULL)
         return false;

      try
        {
         // Mean reversion hoạt động tốt trong thị trường đi ngang
         if(regime != REGIME_RANGING && regime != REGIME_CONSOLIDATION)
           {
            return false;
           }

         bool isBullish = false;
         ApexPullback::DetectedPattern patternInfo;
         bool reversionFound = context->PatternDetector->DetectMeanReversionPattern(isBullish, patternInfo);

         if(reversionFound && context->EnableDetailedLogs)
           {
            context->Logger->LogDebug("Phát hiện tín hiệu Mean Reversion");
           }

         return reversionFound;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong FindMeanReversionSignals");
         return false;
        }
     }

// Tìm tín hiệu Momentum Breakout
   bool FindMomentumBreakoutSignals(EAContext* context, double momentumStrength)
     {
      if(context == NULL || context->PatternDetector == NULL)
         return false;

      try
        {
         // Cần momentum đủ mạnh cho breakout
         if(momentumStrength < context->MinMomentumForBreakout)
           {
            return false;
           }

         bool breakoutFound = context->PatternDetector->DetectBreakoutPatterns();

         if(breakoutFound && context->EnableDetailedLogs)
           {
            context->Logger->LogDebug("Phát hiện tín hiệu Momentum Breakout");
           }

         return breakoutFound;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong FindMomentumBreakoutSignals");
         return false;
        }
     }

// Tìm tín hiệu Shallow Pullback
   bool FindShallowPullbackSignals(EAContext* context, ENUM_MARKET_TREND trend)
     {
      if(context == NULL || context->PatternDetector == NULL)
         return false;

      try
        {
         // Shallow pullback cần xu hướng mạnh
         if(trend != TREND_UP_STRONG && trend != TREND_DOWN_STRONG)
           {
            return false;
           }

         // Sử dụng logic tương tự pullback nhưng với tiêu chí nghiêm ngặt hơn
         bool shallowFound = context->PatternDetector->DetectPullbackPatterns();

         // Thêm kiểm tra độ sâu của pullback
         if(shallowFound)
           {
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               // Chỉ chấp nhận pullback nông (< 50% retracement)
               if(patternInfo.strength > 0.5)
                 {
                  shallowFound = false;
                 }
              }
           }

         if(shallowFound && context->EnableDetailedLogs)
           {
            context->Logger->LogDebug("Phát hiện tín hiệu Shallow Pullback");
           }

         return shallowFound;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong FindShallowPullbackSignals");
         return false;
        }
     }

// Tìm tín hiệu Range Trading
   bool FindRangeTradingSignals(EAContext* context, ENUM_MARKET_REGIME regime)
     {
      if(context == NULL || context->PatternDetector == NULL)
         return false;

      try
        {
         // Range trading chỉ hoạt động trong thị trường đi ngang
         if(regime != REGIME_RANGING)
           {
            return false;
           }

         // Tìm cả pullback và reversal patterns
         bool rangeSignalFound = context->PatternDetector->DetectPullbackPatterns() ||
                                 context->PatternDetector->DetectReversalPatterns();

         if(rangeSignalFound && context->EnableDetailedLogs)
           {
            context->Logger->LogDebug("Phát hiện tín hiệu Range Trading");
           }

         return rangeSignalFound;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong FindRangeTradingSignals");
         return false;
        }
     }

// Xác thực tín hiệu với các bộ lọc bổ sung
   bool ValidateSignalWithFilters(EAContext* context)
     {
      if(context == NULL)
         return false;

      try
        {
         // Kiểm tra news filter nếu có
         if(context->NewsFilter != NULL && !context->NewsFilter->IsTradeAllowed())
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Tín hiệu bị từ chối bởi News Filter");
              }
            return false;
           }

         // Kiểm tra circuit breaker
         if(context->CircuitBreaker != NULL && !context->CircuitBreaker->IsTradeAllowed())
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Tín hiệu bị từ chối bởi Circuit Breaker");
              }
            return false;
           }

         // Kiểm tra correlation với các cặp tiền tệ khác
         if(context->CorrelationAnalyzer != NULL && !context->CorrelationAnalyzer->ValidateSignal())
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Tín hiệu bị từ chối bởi Correlation Analyzer");
              }
            return false;
           }

         return true;
        }
      catch(...)
        {
         if(context->Logger)
            context->Logger->LogError("Lỗi trong ValidateSignalWithFilters");
         return false;
        }
     }

//+------------------------------------------------------------------+
//| Helper Functions cho ProcessTradeSignals                        |
//+------------------------------------------------------------------+

// Kiểm tra các điều kiện tiên quyết
   bool ValidatePrerequisites(EAContext* context)
     {
      if(context == NULL || context->Logger == NULL)
         return false;

      try
        {
         // Kiểm tra đồng thuận cấu trúc thị trường
         if(!context->TradeManager->ValidateMarketStructureConsensus())
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Không có đồng thuận về cấu trúc thị trường giữa MarketProfile và SwingDetector.");
              }
            return false;
           }

         // Kiểm tra số lệnh tối đa trong ngày
         if(context->DayTrades >= context->MaxTradesPerDay)
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Đã đạt số lệnh tối đa trong ngày (" + IntegerToString(context->MaxTradesPerDay) + ")");
              }
            return false;
           }

         // Kiểm tra các vị thế đang mở
         int openPositions = 0;
         if(context->PositionManager != NULL)
           {
            openPositions = context->PositionManager->GetOpenPositionsCount();
           }

         if(openPositions >= context->MaxPositions)
           {
            if(context->EnableDetailedLogs)
              {
               context->Logger->LogDebug("Đã đạt số vị thế tối đa (" + IntegerToString(context->MaxPositions) + ")");
              }
            return false;
           }

         return true;
        }
      catch(...)
        {
         context->Logger->LogError("Lỗi trong ValidatePrerequisites");
         return false;
        }
     }

// Xử lý chiến lược Pullback Trend nâng cao
   bool ProcessPullbackTrendStrategy(EAContext* context, double lotSize)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return false;

      try
        {
         // Gọi trực tiếp PatternDetector để phát hiện pullback patterns
         if(context->PatternDetector->DetectPullbackPatterns())
           {
            // Lấy thông tin chi tiết về pattern đã phát hiện
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               bool isLong = patternInfo.isBullish;
               ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_PULLBACK_FIBONACCI;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Pullback Trend: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager với lot size được tối ưu
               return context->TradeManager->OpenPositionWithLotSize(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                      detectedPattern, lotSize);
              }
           }

         return false;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessPullbackTrendStrategy");
           }
         return false;
        }
     }

// Xử lý chiến lược Mean Reversion nâng cao
   bool ProcessMeanReversionStrategyAdvanced(EAContext* context, double lotSize)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return false;

      try
        {
         bool isBullish = false;
         ApexPullback::DetectedPattern patternInfo;

         if(context->PatternDetector->DetectMeanReversionPattern(isBullish, patternInfo))
           {
            ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_MEAN_REVERSION;

            if(context->Logger != NULL)
              {
               context->Logger->LogInfo("Phát hiện tín hiệu Mean Reversion: " + (isBullish ? "LONG" : "SHORT") +
                                        ", Strength: " + DoubleToString(patternInfo.strength, 2) +
                                        ", Description: " + patternInfo.description);
              }

            // Mở lệnh thông qua TradeManager với lot size được tối ưu
            return context->TradeManager->OpenPositionWithLotSize(isBullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                   detectedPattern, lotSize);
           }

         return false;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessMeanReversionStrategyAdvanced");
           }
         return false;
        }
     }

// Xử lý chiến lược Momentum Breakout nâng cao
   bool ProcessMomentumBreakoutStrategyAdvanced(EAContext* context, double lotSize)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return false;

      try
        {
         if(context->PatternDetector->DetectBreakoutPatterns())
           {
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               bool isLong = patternInfo.isBullish;
               ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_BREAKOUT_MOMENTUM;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Momentum Breakout: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager với lot size được tối ưu
               return context->TradeManager->OpenPositionWithLotSize(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                      detectedPattern, lotSize);
              }
           }

         return false;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessMomentumBreakoutStrategyAdvanced");
           }
         return false;
        }
     }

// Xử lý chiến lược Shallow Pullback
   bool ProcessShallowPullbackStrategy(EAContext* context, double lotSize)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return false;

      try
        {
         if(context->PatternDetector->DetectPullbackPatterns())
           {
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               // Kiểm tra độ sâu pullback (chỉ chấp nhận shallow pullback)
               if(patternInfo.strength <= 0.5) // Shallow pullback
                 {
                  bool isLong = patternInfo.isBullish;
                  ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_SHALLOW_PULLBACK;

                  if(context->Logger != NULL)
                    {
                     context->Logger->LogInfo("Phát hiện tín hiệu Shallow Pullback: " + (isLong ? "LONG" : "SHORT") +
                                              ", Depth: " + DoubleToString(patternInfo.strength, 2));
                    }

                  // Mở lệnh thông qua TradeManager với lot size được tối ưu
                  return context->TradeManager->OpenPositionWithLotSize(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                         detectedPattern, lotSize);
                 }
              }
           }

         return false;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessShallowPullbackStrategy");
           }
         return false;
        }
     }

// Xử lý chiến lược Range Trading nâng cao
   bool ProcessRangeTradingStrategyAdvanced(EAContext* context, double lotSize)
     {
      if(context == NULL || context->PatternDetector == NULL || context->TradeManager == NULL)
         return false;

      try
        {
         bool foundSignal = false;
         bool isLong = true;
         ENUM_ENTRY_SCENARIO detectedPattern = ENTRY_RANGE_BOUNCE;

         // Thử phát hiện pullback trong range
         if(context->PatternDetector->DetectPullbackPatterns())
           {
            foundSignal = true;
            detectedPattern = ENTRY_PULLBACK_FIBONACCI;
           }
         // Nếu không có pullback, thử reversal
         else
            if(context->PatternDetector->DetectReversalPatterns())
              {
               foundSignal = true;
               detectedPattern = ENTRY_REVERSAL_DIVERGENCE;
              }

         if(foundSignal)
           {
            ApexPullback::DetectedPattern patternInfo;
            if(context->PatternDetector->GetPatternDetails(patternInfo))
              {
               isLong = patternInfo.isBullish;

               if(context->Logger != NULL)
                 {
                  context->Logger->LogInfo("Phát hiện tín hiệu Range Trading: " + (isLong ? "LONG" : "SHORT") +
                                           ", Strength: " + DoubleToString(patternInfo.strength, 2));
                 }

               // Mở lệnh thông qua TradeManager với lot size được tối ưu
               return context->TradeManager->OpenPositionWithLotSize(isLong ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,
                      detectedPattern, lotSize);
              }
           }

         return false;
        }
      catch(...)
        {
         if(context->Logger != NULL)
           {
            context->Logger->LogError("Lỗi trong ProcessRangeTradingStrategyAdvanced");
           }
         return false;
        }
     }

  } // End namespace ApexPullback

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   // Pass all chart events to the dashboard if it exists.
   if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Dashboard != NULL)
     {
      ApexPullback::g_EAContext->Dashboard->OnClick(id, lparam, dparam, sparam);
     }
  }

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer(const int id) // id is the timer ID returned by EventSetMillisecondTimer
  {
//--- Check if it's our specific timer that triggered the event
   if(id == G_TIMER_ID)
     {
      if(ApexPullback::g_EAContext != NULL && !ApexPullback::g_EAContext->IsShuttingDown)
        {
         // Call the timer logic within the namespace
         ApexPullback::OnTimerLogic(ApexPullback::g_EAContext);
        }
     }
  }

// GetDeinitReasonText đã được định nghĩa trong FunctionDefinitions.mqh

// SaveConfiguration đã được định nghĩa trong FunctionDefinitions.mqh

// Định nghĩa OnDeinit
void OnDeinit(const int reason)
  {

// Kill the timer first
   if(G_TIMER_ID != -1 && G_TIMER_ID != 0)    // Check if timer was successfully created
     {
      EventKillTimer(G_TIMER_ID);
      // Log timer kill, check context and logger availability
      if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL)
        {
         ApexPullback::g_EAContext->Logger->LogInfo("Timer ID " + IntegerToString(G_TIMER_ID) + " đã được hủy.");
        }
      else
        {
         Print("Timer ID " + IntegerToString(G_TIMER_ID) + " đã được hủy (Logger không khả dụng).");
        }
      G_TIMER_ID = -1; // Reset timer ID
     }

   if(ApexPullback::g_EAContext != NULL)
     {
      ApexPullback::g_EAContext->IsShuttingDown = true;
     }


   string deinit_reason_text = ApexPullback::GetDeinitReasonText(reason);
   string deinitMessage = "APEX Pullback EA v14.0 đang kết thúc. Lý do: " + deinit_reason_text;

// Thêm thống kê tổng quan (sử dụng context nếu có, fallback to globals if not)
   long tickCounter = (ApexPullback::g_EAContext != NULL) ? ApexPullback::g_EAContext->TickCounter : 0; // Fallback to 0 if context is null
   long errorCounter = (ApexPullback::g_EAContext != NULL) ? ApexPullback::g_EAContext->ErrorCounter : 0; // Fallback to 0 if context is null
   int successfulTrades = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->PerformanceTracker != NULL) ? ApexPullback::g_EAContext->PerformanceTracker->GetSuccessfulTrades() : 0; // Fallback to 0
   int failedTrades = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->PerformanceTracker != NULL) ? ApexPullback::g_EAContext->PerformanceTracker->GetFailedTrades() : 0; // Fallback to 0

   deinitMessage += " | Tổng Ticks: " + IntegerToString(tickCounter);
   deinitMessage += " | Tổng Lỗi: " + IntegerToString(errorCounter);
   deinitMessage += " | Giao dịch thành công: " + IntegerToString(successfulTrades);
   deinitMessage += " | Giao dịch thất bại: " + IntegerToString(failedTrades);

   CLogger* logger = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL) ? ApexPullback::g_EAContext->Logger : NULL;

// Dọn dẹp Global Variables nếu là Master EA
   if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->IsMasterPortfolioManager)
     {
      CleanupAllTradeGVs(*ApexPullback::g_EAContext);
     }

   if(logger != NULL)
     {
      logger->LogInfo(deinitMessage);
     }
   else
     {
      Print(deinitMessage);
     }

// Lưu cấu hình và thống kê nếu cần
   try
     {
      if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->SaveStatistics && ApexPullback::g_EAContext->PerformanceTracker != NULL)
        {
         if(logger != NULL)
            logger->LogInfo("Đang lưu thống kê hiệu suất...");
         if(!ApexPullback::g_EAContext->PerformanceTracker->SavePerformanceData("PerformanceStats.csv"))
           {
            if(logger != NULL)
               logger->LogWarning("Không thể lưu thống kê hiệu suất.");
           }
         else
           {
            if(logger != NULL)
               logger->LogInfo("Thống kê hiệu suất đã được lưu thành công.");
           }
        }

      // Lưu cấu hình hiện tại (SaveConfiguration might need access to g_EAContext or its logger)
      if(ApexPullback::SaveConfiguration(ApexPullback::g_EAContext))    // Pass context if needed
        {
         if(logger != NULL)
            logger->LogInfo("Cấu hình EA đã được lưu thành công.");
        }
      else
        {
         if(logger != NULL)
            logger->LogWarning("Không thể lưu cấuHình EA.");
        }
     }
   catch(...)
     {
      if(logger != NULL)
         logger->LogError("Lỗi khi lưu cấu hình và thống kê.");
      else
         Print("Lỗi khi lưu cấu hình và thống kê.");
     }

// Giải phóng các module thông qua EAContext
   try
     {
      if(ApexPullback::g_EAContext != NULL)
        {
         if(ApexPullback::g_EAContext->Dashboard != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng Dashboard...");
            delete ApexPullback::g_EAContext->Dashboard;
            ApexPullback::g_EAContext->Dashboard = NULL;
           }
         if(ApexPullback::g_EAContext->TradeManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng TradeManager...");
            delete ApexPullback::g_EAContext->TradeManager;
            ApexPullback::g_EAContext->TradeManager = NULL;
           }
         if(ApexPullback::g_EAContext->PositionManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng PositionManager...");
            delete ApexPullback::g_EAContext->PositionManager;
            ApexPullback::g_EAContext->PositionManager = NULL;
           }
         if(ApexPullback::g_EAContext->RiskManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng RiskManager...");
            delete ApexPullback::g_EAContext->RiskManager;
            ApexPullback::g_EAContext->RiskManager = NULL;
           }
         if(ApexPullback::g_EAContext->PatternDetector != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng PatternDetector...");
            delete ApexPullback::g_EAContext->PatternDetector;
            ApexPullback::g_EAContext->PatternDetector = NULL;
           }
         if(ApexPullback::g_EAContext->SwingDetector != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng SwingDetector...");
            delete ApexPullback::g_EAContext->SwingDetector;
            ApexPullback::g_EAContext->SwingDetector = NULL;
           }
         if(ApexPullback::g_EAContext->MarketProfile != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng MarketProfile...");
            delete ApexPullback::g_EAContext->MarketProfile;
            ApexPullback::g_EAContext->MarketProfile = NULL;
           }
         // if (ApexPullback::g_EAContext->AssetProfiler != NULL) { if (logger != NULL) logger->LogDebug("Giải phóng AssetProfiler..."); delete ApexPullback::g_EAContext->AssetProfiler; ApexPullback::g_EAContext->AssetProfiler = NULL; } // Assuming AssetProfiler is part of AssetProfileManager or distinct
         if(ApexPullback::g_EAContext->NewsFilter != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng NewsFilter...");
            delete ApexPullback::g_EAContext->NewsFilter;
            ApexPullback::g_EAContext->NewsFilter = NULL;
           }
         if(ApexPullback::g_EAContext->SessionManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng SessionManager...");
            delete ApexPullback::g_EAContext->SessionManager;
            ApexPullback::g_EAContext->SessionManager = NULL;
           }
         if(ApexPullback::g_EAContext->AssetDNA != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng AssetDNA...");
            delete ApexPullback::g_EAContext->AssetDNA;
            ApexPullback::g_EAContext->AssetDNA = NULL;
           }
         if(ApexPullback::g_EAContext->PerformanceTracker != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng PerformanceTracker...");
            delete ApexPullback::g_EAContext->PerformanceTracker;
            ApexPullback::g_EAContext->PerformanceTracker = NULL;
           }
         if(ApexPullback::g_EAContext->PortfolioManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng PortfolioManager...");
            delete ApexPullback::g_EAContext->PortfolioManager;
            ApexPullback::g_EAContext->PortfolioManager = NULL;
           }
         // Cleanup new optimization modules
         if(ApexPullback::g_EAContext->TradeHistoryOptimizer != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng TradeHistoryOptimizer...");
            delete ApexPullback::g_EAContext->TradeHistoryOptimizer;
            ApexPullback::g_EAContext->TradeHistoryOptimizer = NULL;
           }

         if(ApexPullback::g_EAContext->FunctionStack != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng FunctionStack...");
            delete ApexPullback::g_EAContext->FunctionStack;
            ApexPullback::g_EAContext->FunctionStack = NULL;
           }
         if(ApexPullback::g_EAContext->NewsDownloader != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng NewsDownloader...");
            delete ApexPullback::g_EAContext->NewsDownloader;
            ApexPullback::g_EAContext->NewsDownloader = NULL;
           }
         if(ApexPullback::g_EAContext->PresetManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng PresetManager...");
            delete ApexPullback::g_EAContext->PresetManager;
            ApexPullback::g_EAContext->PresetManager = NULL;
           }

         // Cleanup các module mới
         if(ApexPullback::g_EAContext->RecoveryManager != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng RecoveryManager...");
            delete ApexPullback::g_EAContext->RecoveryManager;
            ApexPullback::g_EAContext->RecoveryManager = NULL;
           }

         if(ApexPullback::g_EAContext->CircuitBreaker != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng CircuitBreaker...");
            delete ApexPullback::g_EAContext->CircuitBreaker;
            ApexPullback::g_EAContext->CircuitBreaker = NULL;
           }

         if(ApexPullback::g_EAContext->StrategyOptimizer != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng StrategyOptimizer...");
            delete ApexPullback::g_EAContext->StrategyOptimizer;
            ApexPullback::g_EAContext->StrategyOptimizer = NULL;
           }

         if(ApexPullback::g_EAContext->TradeHistoryOptimizer != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng TradeHistoryOptimizer...");
            delete ApexPullback::g_EAContext->TradeHistoryOptimizer;
            ApexPullback::g_EAContext->TradeHistoryOptimizer = NULL;
           }

         if(ApexPullback::g_EAContext->FileCommunication != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng FileCommunication...");
            ApexPullback::g_EAContext->FileCommunication->Cleanup();
            delete ApexPullback::g_EAContext->FileCommunication;
            ApexPullback::g_EAContext->FileCommunication = NULL;
           }

         if(ApexPullback::g_EAContext->FunctionStack != NULL)
           {
              if(logger != NULL)
                  logger->LogDebug("Giải phóng FunctionStack...");
              delete ApexPullback::g_EAContext->FunctionStack;
              ApexPullback::g_EAContext->FunctionStack = NULL;
           }

         if(ApexPullback::g_EAContext->IndicatorUtils != NULL)
           {
            if(logger != NULL)
               logger->LogDebug("Giải phóng IndicatorUtils...");
            // IndicatorUtils destructor should handle releasing its own indicators
            delete ApexPullback::g_EAContext->IndicatorUtils;
            ApexPullback::g_EAContext->IndicatorUtils = NULL;
           }
        }
      else     // Fallback to old global deallocation if context is null - This block should ideally not be reached.
        {
         Print("OnDeinit: EAContext was NULL. Global fallbacks for Dashboard and other managers are removed.");
        }

      // Global indicator handles and cache are now managed by CIndicatorUtils within g_EAContext.
      // Calls to ApexPullback::ReleaseIndicatorHandles() and ApexPullback::ClearIndicatorCache() are removed.

     }
   catch(...)
     {
      if(logger != NULL)
         logger->LogError("Lỗi trong quá trình giải phóng các module.");
      else
         Print("Lỗi trong quá trình giải phóng các module.");
     }

   if(logger != NULL)
     {
      logger->LogInfo("APEX Pullback EA v14.0 đã giải phóng tất cả các module.");
      bool enableTelegram = (ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL) ? ApexPullback::g_EAContext->Logger->IsTelegramEnabled() : (ApexPullback::g_EAContext != NULL ? ApexPullback::g_EAContext->EnableTelegramNotify : false);
      if(enableTelegram && logger != NULL)
        {
         logger->SendTelegramMessage("APEX Pullback EA v14.0 đã kết thúc. Lý do: " + deinit_reason_text, true);
        }
     }

// Giải phóng Logger LÀ BƯỚC CUỐI CÙNG, if it's the one in context, it will be deleted with the context.
// If it was the old global g_Logger and context was null, delete it here.
   try
     {
      if(ApexPullback::g_EAContext != NULL)
        {
         if(ApexPullback::g_EAContext->Logger != NULL)
           {
            ApexPullback::g_EAContext->Logger->Deinitialize();
            // Logger will be deleted when g_EAContext is deleted
           }
         delete ApexPullback::g_EAContext;
         ApexPullback::g_EAContext = NULL;
        }
      else     // If context was null and its logger was null, or old global logger was already handled/null
        {
         Print("OnDeinit: EAContext was NULL and no fallback global logger to deinitialize.");
        }
     }
   catch(...)
     {
      Print("APEX Pullback EA v14.0 - Lỗi khi giải phóng Logger hoặc EAContext.");
     }

   ObjectsDeleteAll(0, -1, -1);
   ChartRedraw();

   Print("APEX Pullback EA v14.0 đã kết thúc hoàn toàn.");
  }

// Hàm phụ trợ để dọn dẹp tất cả các GV liên quan đến proposal và decision
void CleanupAllTradeGVs(ApexPullback::EAContext &context)
  {
   if(context.Logger == NULL)
     {
      Print("CleanupAllTradeGVs: Logger không hợp lệ.");
      return;
     }

   if(!context.IsMasterPortfolioManager)
      return; // Chỉ Master EA mới dọn dẹp

   context.Logger->LogInfo("Master EA: Bắt đầu dọn dẹp tất cả Global Variables cho proposals/decisions.");

   long totalGVs = GlobalVariablesTotal();
   int deletedCount = 0;
   for(long i = totalGVs - 1; i >= 0; i--)    // Duyệt ngược để việc xóa không ảnh hưởng index
     {
      string gvName = GlobalVariableName(i);
      if(StringFind(gvName, "GV_Proposal_") == 0 || StringFind(gvName, "GV_Decision_") == 0)
        {
         if(GlobalVariableDel(gvName))
           {
            context.Logger->LogDebugFormat("Đã xóa GV: %s", gvName);
            deletedCount++;
           }
         else
           {
            context.Logger->LogWarningFormat("Không thể xóa GV: %s", gvName);
           }
        }
     }
   context.Logger->LogInfoFormat("Master EA: Đã xóa %d Global Variables liên quan đến trade.", deletedCount);
  }

//+------------------------------------------------------------------+
//| Hàm kiểm tra bộ nhớ khả dụng                                   |
//+------------------------------------------------------------------+
bool CheckMemoryAvailable()
  {
// Kiểm tra bộ nhớ khả dụng (ít nhất 50MB)
   double memoryUsage = GetMemoryUsage(ApexPullback::g_EAContext);
   if(memoryUsage > 500.0)    // Hơn 500MB có thể có vấn đề
     {
      if(ApexPullback::g_EAContext != NULL && ApexPullback::g_EAContext->Logger != NULL)
         ApexPullback::g_EAContext->Logger->LogWarning("Sử dụng bộ nhớ cao: " + DoubleToString(memoryUsage, 2) + "MB");
      else
         Print("CẢNH BÁO: Sử dụng bộ nhớ cao: " + DoubleToString(memoryUsage, 2) + "MB");
      return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Hàm lấy thông tin sử dụng bộ nhớ                               |
//+------------------------------------------------------------------+
double GetMemoryUsage(EAContext* context)   // Added EAContext* context
  {
   double estimatedMemory = 0.0;
   if(context != NULL)    // Use passed context
     {
      if(context->Logger != NULL)
         estimatedMemory += 2.0;
      if(context->Dashboard != NULL)
         estimatedMemory += 5.0;
      if(context->TradeManager != NULL)
         estimatedMemory += 3.0;
      if(context->PositionManager != NULL)
         estimatedMemory += 2.0;
      if(context->RiskManager != NULL)
         estimatedMemory += 2.0;
      if(context->MarketProfile != NULL)
         estimatedMemory += 4.0;
      if(context->SwingDetector != NULL)
         estimatedMemory += 3.0;
      if(context->IndicatorUtils != NULL)
        {
         // Estimate memory for IndicatorUtils, including its managed indicators
         // This is a rough estimate; IndicatorUtils could provide a more accurate GetMemoryUsage method.
         estimatedMemory += 2.0 + context->IndicatorUtils->GetManagedIndicatorCount() * 1.0;
        }
     }
   else
     {
      // Fallback to old global estimates if context is null - This should not happen in normal operation.
      Print("GetMemoryUsage: EAContext is NULL. Cannot estimate memory accurately.");
      // Globals like g_Logger, g_Dashboard are removed, so no direct estimation here.
      // g_IndicatorCount is no longer used, CIndicatorUtils manages its own indicator counts/memory.
     }
   return estimatedMemory;
  }

//+------------------------------------------------------------------+
//| Hàm log thông tin hệ thống                                     |
//+------------------------------------------------------------------+
void LogSystemInfo(const EAContext* context)   // Added EAContext* context
  {
   if(context == NULL || context->Logger == NULL)
     {
      Print("LogSystemInfo: Context hoặc Logger không hợp lệ.");
      return;
     }

   string systemInfo = "Thông tin hệ thống: ";
   systemInfo += "Symbol: " + context->Symbol; // Use context->Symbol
   systemInfo += " | Timeframe: " + EnumToString((ENUM_TIMEFRAMES)context->MainTimeframe); // Assuming MainTimeframe is the relevant one, cast to ENUM_TIMEFRAMES
   systemInfo += " | Digits: " + IntegerToString(_Digits); // _Digits is a global MQL5 variable, keep as is
   systemInfo += " | Point: " + DoubleToString(_Point, _Digits); // _Point is a global MQL5 variable, keep as is
   systemInfo += " | Spread: " + DoubleToString(SymbolInfoInteger(context->Symbol, SYMBOL_SPREAD), 1); // Use context->Symbol
   systemInfo += " | Account: " + AccountInfoString(ACCOUNT_LOGIN); // Added Account Login
   systemInfo += " | Company: " + AccountInfoString(ACCOUNT_COMPANY); // Added Account Company
   systemInfo += " | Server: " + AccountInfoString(ACCOUNT_SERVER); // ACCOUNT_SERVER is global, keep as is
   systemInfo += " | Build: " + IntegerToString(TerminalInfoInteger(TERMINAL_BUILD)); // TERMINAL_BUILD is global, keep as is

   context->Logger->LogInfo(systemInfo);
// Log memory usage as well
   context->Logger->LogInfo("Estimated Memory Usage: " + DoubleToString(GetMemoryUsage(context),2) + "MB");
  }



} // End namespace ApexPullback


//+------------------------------------------------------------------+
