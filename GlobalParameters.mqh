//+------------------------------------------------------------------+
//|                 GlobalParameters.mqh - APEX Pullback EA v14.0    |
//|           Author: APEX Trading Team | Date: 2024-05-07           |
//|   Description: Tập trung tất cả tham số và hằng số của EA        |
//|   Hợp nhất từ Constants.mqh và Inputs.mqh theo nguyên tắc        |
//|   Single Source of Truth                                         |
//+------------------------------------------------------------------+

#ifndef GLOBALPARAMETERS_MQH_
#define GLOBALPARAMETERS_MQH_

// Include all necessary enum definitions
#include "Enums.mqh"

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

//==== THAM SỐ EA CHUNG ====
#define EA_VERSION                     "14.0"
#define EA_NAME                        "APEX Pullback"
#define EA_FULL_NAME                   "APEX Pullback EA v14.0"
#define EA_COPYRIGHT                   "Copyright 2023-2024, APEX Forex"
#define EA_MAGIC_NUMBER_BASE           14000  // Magic Number cơ sở, có thể cộng thêm identifier

//==== THAM SỐ CHIẾN LƯỢC CỐT LÕI ====
#define DEFAULT_EMA_FAST               34     // EMA nhanh (EMA 34)
#define DEFAULT_EMA_MEDIUM             89     // EMA trung bình (EMA 89)
#define DEFAULT_EMA_SLOW               200    // EMA chậm (EMA 200)
#define DEFAULT_MIN_PULLBACK_PCT       20.0   // % Pullback tối thiểu
#define DEFAULT_MAX_PULLBACK_PCT       70.0   // % Pullback tối đa 
#define DEFAULT_MIN_ADX_VALUE          18.0   // Giá trị ADX tối thiểu
#define DEFAULT_MAX_ADX_VALUE          45.0   // Giá trị ADX tối đa
#define DEFAULT_VOL_THRESHOLD          2.0    // Ngưỡng biến động (xATR)

//==== THAM SỐ PHÂN TÍCH THỊ TRƯỜNG ====
#define MIN_BARS_REQUIRED              300    // Số nến tối thiểu để EA hoạt động chính xác
#define SWING_DETECTION_PERIODS        50     // Số nến để phát hiện swing points
#define SWING_STRENGTH_THRESHOLD       0.6    // Ngưỡng tối thiểu cho swing mạnh (0.0-1.0)
#define TRANSITION_THRESHOLD           3      // Số nến để xác nhận chuyển đổi regime
#define PATTERN_MIN_SIZE_PERCENT       0.3    // Kích thước tối thiểu cho pattern (% ATR)
#define VOLATILITY_EXTREME_RATIO       2.5    // Hệ số ATR để xác định biến động cực đoan
#define DEFAULT_DATA_PERIOD            20     // Số nến mặc định cho tính toán giá trị trung bình

//==== THAM SỐ LỌC PULLBACK ====
#define MIN_ALIGNMENT_SCORE            0.7    // Điểm tối thiểu cho sự đồng thuận EMA
#define MAX_PULLBACK_DEPTH_ATR         1.5    // Độ sâu tối đa pullback (hệ số ATR)
#define PRICE_ACTION_MIN_QUALITY       0.6    // Chất lượng tối thiểu cho Price Action (0.0-1.0)
#define MOMENTUM_SLOPE_THRESHOLD       0.25   // Độ dốc tối thiểu cho momentum
#define VOLUME_CONFIRM_RATIO           1.1    // Hệ số tối thiểu cho volume (so với trung bình)

//==== THAM SỐ QUẢN LÝ RỦI RO ====
#define DEFAULT_RISK_PERCENT           1.0    // % Risk mặc định mỗi lệnh
#define DEFAULT_SL_ATR                 1.5    // Hệ số ATR cho Stop Loss
#define DEFAULT_TP_RR                  2.0    // Tỷ lệ R:R cho Take Profit

#define DEFAULT_DAILY_LOSS_LIMIT       3.0    // Giới hạn lỗ ngày (%)
#define DEFAULT_MAX_DRAWDOWN           10.0   // Drawdown tối đa (%)
#define DEFAULT_MAX_TRADES_PER_DAY     5      // Số lệnh tối đa/ngày
#define DEFAULT_MAX_CONSECUTIVE_LOSSES 5      // Số lần thua liên tiếp tối đa
#define DEFAULT_MAX_SPREAD_POINTS      10.0   // Spread tối đa (points)
#define DEFAULT_LOOKBACK_BARS          100    // Số nến để xem lại lịch sử
#define DEFAULT_ENV_FACTOR             2.0    // Hệ số cho EnvF
#define DD_REDUCE_THRESHOLD            5.0    // Ngưỡng DD để giảm risk (%)
#define MIN_RISK_MULTIPLIER            0.3    // Hệ số risk tối thiểu khi DD cao

//==== THAM SỐ QUẢN LÝ VỊ THẾ ====
#define DEFAULT_MAX_POSITIONS          2      // Số vị thế tối đa
#define DEFAULT_ORDER_COMMENT          "ApexPullback v14"  // Comment cho lệnh
#define DEFAULT_PARTIAL_CLOSE_R1       1.0    // R-multiple cho đóng phần 1
#define DEFAULT_PARTIAL_CLOSE_R2       2.0    // R-multiple cho đóng phần 2
#define DEFAULT_PARTIAL_CLOSE_PCT1     35.0   // % đóng ở mức R1
#define DEFAULT_PARTIAL_CLOSE_PCT2     35.0   // % đóng ở mức R2

//==== THAM SỐ TRAILING STOP ====
#define DEFAULT_TRAILING_ATR_MULTI     2.0    // Hệ số ATR cho trailing
#define DEFAULT_BREAKEVEN_AFTER_R      1.0    // Chuyển BE sau (R-multiple)
#define DEFAULT_BREAKEVEN_BUFFER       5.0    // Buffer cho breakeven (points)
#define DEFAULT_CHANDELIER_PERIOD      20     // Số nến lookback Chandelier
#define DEFAULT_CHANDELIER_MULTI       3.0    // Hệ số ATR Chandelier
#define DEFAULT_SCALING_RISK_PCT       0.3    // % risk cho lệnh nhồi (so với ban đầu)

//==== THAM SỐ SESSION & NEWS FILTER ====
#define GMT_DEFAULT_OFFSET             0      // Điều chỉnh GMT mặc định (giờ)
#define DEFAULT_NEWS_IMPORTANCE        2      // Độ quan trọng tin (1-3)
#define DEFAULT_MINUTES_BEFORE_NEWS    30     // Phút trước tin tức
#define DEFAULT_MINUTES_AFTER_NEWS     15     // Phút sau tin tức
#define DEFAULT_SESSION_ASIAN_START    0      // Giờ bắt đầu phiên Á (0-23)
#define DEFAULT_SESSION_ASIAN_END      8      // Giờ kết thúc phiên Á (0-23)
#define DEFAULT_SESSION_LONDON_START   8      // Giờ bắt đầu phiên London (0-23)
#define DEFAULT_SESSION_LONDON_END     16     // Giờ kết thúc phiên London (0-23)
#define DEFAULT_SESSION_NEWYORK_START  13     // Giờ bắt đầu phiên New York (0-23)
#define DEFAULT_SESSION_NEWYORK_END    21     // Giờ kết thúc phiên New York (0-23)

//==== MÃ LỖI TÙY CHỈNH ====
#define ERROR_INVALID_SIGNAL          10001   // Tín hiệu không hợp lệ
#define ERROR_TOO_MANY_POSITIONS      10002   // Quá nhiều vị thế 
#define ERROR_EXCEED_RISK_LIMIT       10003   // Vượt giới hạn rủi ro
#define ERROR_NO_NEWS_DATA_FOUND      10004   // Không tìm thấy dữ liệu tin tức
#define ERROR_INSUFFICIENT_MARGIN     10005   // Không đủ ký quỹ
#define ERROR_MARKET_CLOSED           10006   // Thị trường đóng cửa
#define ERROR_EXTREME_VOLATILITY      10007   // Biến động thị trường cực đoan
#define ERROR_MODULE_INIT_FAILED      10008   // Khởi tạo module thất bại
#define ERROR_ASSET_PROFILE_MISSING   10009   // Thiếu profile tài sản
#define ERROR_CONFIG_FILE_INVALID     10010   // File cấu hình không hợp lệ

//==== ĐƯỜNG DẪN LƯU TRỮ ====
#define DEFAULT_LOG_DIRECTORY         "ApexLogs"
#define DEFAULT_NEWS_DATA_FILE        "news_calendar.csv"
#define DEFAULT_CONFIG_FILE_PREFIX    "ApexPullback_"
#define DEFAULT_CONFIG_FILE_EXT       ".conf"
#define DEFAULT_ASSET_PROFILE_FILE    "AssetProfiles.json"

//==== HIỂN THỊ & THÔNG BÁO ====
#define EMOJI_UP_TREND                "📈"
#define EMOJI_DOWN_TREND              "📉"
#define EMOJI_SIDEWAY                 "↔️"
#define EMOJI_RISK_ON                 "🔥"
#define EMOJI_RISK_OFF                "❄️"
#define EMOJI_CAUTION                 "⚠️"
#define EMOJI_NEWS_ALERT              "📰"
#define EMOJI_PROFIT                  "💰"
#define EMOJI_LOSS                    "📉"
#define EMOJI_PAUSE                   "⏸️"
#define EMOJI_RUNNING                 "▶️"

// Màu sắc Dashboard
#define COLOR_DASHBOARD_BG            C'240,240,240'  // Màu nền
#define COLOR_DASHBOARD_HEADER        C'50,80,120'    // Màu header
#define COLOR_DASHBOARD_TEXT          C'10,10,10'     // Màu text
#define COLOR_DASHBOARD_UP            C'0,128,0'      // Màu tăng
#define COLOR_DASHBOARD_DOWN          C'178,34,34'    // Màu giảm
#define COLOR_DASHBOARD_NEUTRAL       C'100,100,100'  // Màu trung tính
#define COLOR_DASHBOARD_WARNING       C'255,140,0'    // Màu cảnh báo
#define COLOR_DASHBOARD_CRITICAL      C'220,20,60'    // Màu nguy hiểm

// Tham số Asset Profiler
#define MAX_HISTORY_DAYS              30     // Số ngày lịch sử lưu trữ dữ liệu cho AssetProfileData (sử dụng trong CommonStructs.mqh)
#define ASSET_HISTORY_DAYS            90     // Số ngày lịch sử để phân tích asset
#define SPREAD_HISTORY_SIZE           50     // Số lần ghi nhận spread để tính trung bình
#define MIN_DATA_POINTS_REQUIRED      100    // Số điểm dữ liệu tối thiểu để phân tích
#define FOREX_MAX_SPREAD_THRESHOLD    30     // Spread tối đa cho Forex (points)
#define GOLD_MAX_SPREAD_THRESHOLD     100    // Spread tối đa cho Gold (points)
#define INDICES_MAX_SPREAD_THRESHOLD  150    // Spread tối đa cho Indices (points)
#define CRYPTO_MAX_SPREAD_THRESHOLD   200    // Spread tối đa cho Crypto (points)

//==== CÁC HẰNG SỐ CHUNG KHÁC ====
#define ALERT_LEVEL_NORMAL 0
#define ALERT_LEVEL_IMPORTANT 1
#define ALERT_LEVEL_WARNING 2
#define ALERT_LEVEL_EMERGENCY 3
#define ALERT_LEVEL_CRITICAL 3  // Alias cho ALERT_LEVEL_EMERGENCY

#define MAX_HISTORY_BARS 5000
#define INVALID_VALUE -1

//==== ENTRY SCENARIO CONSTANTS ====
// Định nghĩa các hằng số cho ENUM_ENTRY_SCENARIO
#define ENTRY_PULLBACK_FIBONACCI      ((ENUM_ENTRY_SCENARIO)SCENARIO_PULLBACK)
#define ENTRY_MEAN_REVERSION          ((ENUM_ENTRY_SCENARIO)SCENARIO_REVERSAL)
#define ENTRY_BREAKOUT_MOMENTUM       ((ENUM_ENTRY_SCENARIO)SCENARIO_BREAKOUT)
#define ENTRY_RANGE_BOUNCE            ((ENUM_ENTRY_SCENARIO)SCENARIO_REVERSAL)
#define ENTRY_REVERSAL_DIVERGENCE     ((ENUM_ENTRY_SCENARIO)SCENARIO_REVERSAL)

//+------------------------------------------------------------------+
//| INPUT PARAMETERS - Tham số điều chỉnh của EA                    |
//+------------------------------------------------------------------+

//===== THÔNG TIN CHUNG =====
input group "=== THÔNG TIN CHUNG ==="
input string  EAName            = "APEX Pullback EA v14.0";  // Tên EA
input string  EAVersion         = "14.0";                   // Phiên bản
input int     MagicNumber       = 14000;                    // Magic Number
input string  OrderComment      = "ApexPullback v14";       // Ghi chú lệnh
input bool    AllowNewTrades    = true;                     // Cho phép vào lệnh mới
input bool    IsSlaveEA         = false;                    // Đánh dấu EA này là Slave

//===== HIỂN THỊ & THÔNG BÁO =====
input group "=== HIỂN THỊ & THÔNG BÁO ==="
input bool    EnableDetailedLogs = false;                   // Bật log chi tiết
input bool    EnableCsvLog = false;                         // Ghi log vào file CSV
input string  CsvLogFilename = "ApexPullback_Log.csv";      // Tên file CSV log
input bool    DisplayDashboard = true;                      // Hiển thị dashboard
input ApexPullback::ENUM_DASHBOARD_THEME DashboardTheme = ApexPullback::THEME_DARK; // Chủ đề Dashboard
input int     UpdateFrequencySeconds = 60;                // Tần suất cập nhật (giây)
input bool    SaveStatistics = true;                      // Lưu thống kê giao dịch
input bool    EnableIndicatorCache = true;                // Bật cache cho indicator
input bool    AlertsEnabled = true;                         // Bật cảnh báo
input bool    SendNotifications = false;                    // Gửi thông báo đẩy
input bool    SendEmailAlerts = false;                      // Gửi email
input bool    EnableTelegramNotify = false;                 // Bật thông báo Telegram
input string  TelegramBotToken = "";                        // Token Bot Telegram
input string  TelegramChatID = "";                          // ID Chat Telegram
input bool    TelegramImportantOnly = true;                 // Chỉ gửi thông báo quan trọng
input bool    DisableDashboardInBacktest = true;            // Tắt dashboard trong backtest

//===== CHIẾN LƯỢC CỐT LÕI =====
input group "=== CHIẾN LƯỢC CỐT LÕI ==="
input ENUM_TIMEFRAMES MainTimeframe = PERIOD_H1;            // Khung thời gian chính
input ApexPullback::ENUM_STRATEGY_ID StrategyID = ApexPullback::STRATEGY_ID_PULLBACK; // Chiến lược chính
input int     EMA_Fast = 34;                                // EMA nhanh (34)
input int     EMA_Medium = 89;                              // EMA trung bình (89) 
input int     EMA_Slow = 200;                               // EMA chậm (200)
input bool    UseMultiTimeframe = true;                     // Sử dụng đa khung thời gian
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H4;          // Khung thời gian cao hơn
input ApexPullback::ENUM_MARKET_TREND TrendDirection = ApexPullback::TREND_UP_NORMAL; // Hướng xu hướng giao dịch

//===== ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO =====
input group "=== ĐỊNH NGHĨA PULLBACK CHẤT LƯỢNG CAO ==="
input bool    EnablePriceAction = true;                     // Kích hoạt xác nhận Price Action
input bool    EnableSwingLevels = true;                     // Sử dụng Swing Levels
input double  MinPullbackPercent = 20.0;                    // % Pullback tối thiểu
input double  MaxPullbackPercent = 70.0;                    // % Pullback tối đa
input bool    RequirePriceActionConfirmation = true;        // Yêu cầu xác nhận Price Action
input bool    RequireMomentumConfirmation = false;          // Yêu cầu xác nhận Momentum
input bool    RequireVolumeConfirmation = false;            // Yêu cầu xác nhận Volume

//===== BỘ LỌC THỊ TRƯỜNG =====
input group "=== BỘ LỌC THỊ TRƯỜNG ==="
input bool    EnableMarketRegimeFilter = true;              // Bật lọc Market Regime
input bool    EnableVolatilityFilter = true;                // Lọc biến động bất thường
input bool    EnableAdxFilter = true;                       // Lọc ADX
input double  MinAdxValue = 18.0;                           // Giá trị ADX tối thiểu
input double  MaxAdxValue = 45.0;                           // Giá trị ADX tối đa
input double  VolatilityThreshold = 2.0;                    // Ngưỡng biến động (xATR)
input ApexPullback::ENUM_MARKET_PRESET MarketPreset = ApexPullback::PRESET_AUTO;                     // Preset thị trường
input double  MaxSpreadPoints = 10.0;                       // Spread tối đa (points)

//===== QUẢN LÝ RỦI RO =====
input group "=== QUẢN LÝ RỦI RO ==="
input double  RiskPercent = 1.0;                            // Risk % mỗi lệnh
input double  StopLoss_ATR = 1.5;                           // Hệ số ATR cho Stop Loss
input double  TakeProfit_RR = 2.0;                          // Tỷ lệ R:R cho Take Profit
input bool    PropFirmMode = false;                         // Chế độ Prop Firm
input double  DailyLossLimit = 3.0;                         // Giới hạn lỗ ngày (%)
input double  MaxDrawdown = 10.0;                           // Drawdown tối đa (%)
input int     MaxTradesPerDay = 5;                          // Số lệnh tối đa/ngày
input int     MaxConsecutiveLosses = 5;                     // Số lần thua liên tiếp tối đa
input int     MaxPositions = 2;                             // Số vị thế tối đa

//===== ĐIỀU CHỈNH RISK THEO DRAWDOWN =====
input group "=== ĐIỀU CHỈNH RISK THEO DRAWDOWN ==="
input double  DrawdownReduceThreshold = 5.0;                // Ngưỡng DD để giảm risk (%)
input bool    EnableTaperedRisk = true;                     // Giảm risk từ từ (không đột ngột)
input double  MinRiskMultiplier = 0.3;                      // Hệ số risk tối thiểu khi DD cao

//===== QUẢN LÝ VỊ THẾ =====
input group "=== QUẢN LÝ VỊ THẾ ==="
input ApexPullback::ENUM_ENTRY_MODE EntryMode = ApexPullback::MODE_SMART;               // Chế độ vào lệnh
input bool    UsePartialClose = true;                       // Sử dụng đóng từng phần
input double  PartialCloseR1 = 1.0;                         // R-multiple cho đóng phần 1
input double  PartialCloseR2 = 2.0;                         // R-multiple cho đóng phần 2
input double  PartialClosePercent1 = 35.0;                  // % đóng ở mức R1
input double  PartialClosePercent2 = 35.0;                  // % đóng ở mức R2

//===== TRAILING STOP =====
input group "=== TRAILING STOP ==="
input bool    UseAdaptiveTrailing = true;                   // Trailing thích ứng theo regime
input ApexPullback::ENUM_TRAILING_MODE TrailingMode = ApexPullback::TRAILING_ATR;       // Chế độ trailing mặc định
input double  TrailingAtrMultiplier = 2.0;                  // Hệ số ATR cho trailing
input double  BreakEvenAfterR = 1.0;                        // Chuyển BE sau (R-multiple)
input double  BreakEvenBuffer = 5.0;                        // Buffer cho breakeven (points)

//===== CHANDELIER EXIT =====
input group "=== CHANDELIER EXIT ==="
input bool    UseChandelierExit = true;                     // Kích hoạt Chandelier Exit
input int     ChandelierPeriod = 20;                        // Số nến lookback Chandelier
input double  ChandelierMultiplier = 3.0;                   // Hệ số ATR Chandelier

//===== LỌC PHIÊN =====
input group "=== LỌC PHIÊN ==="
input bool    FilterBySession = false;                      // Kích hoạt lọc theo phiên
input ApexPullback::ENUM_SESSION_FILTER SessionFilter = ApexPullback::FILTER_ALL_SESSIONS;               // Phiên giao dịch
input bool    UseGmtOffset = true;                          // Sử dụng điều chỉnh GMT
input int     GmtOffset = 0;                                // Điều chỉnh GMT (giờ)
input bool    TradeLondonOpen = true;                       // Giao dịch mở cửa London
input bool    TradeNewYorkOpen = true;                      // Giao dịch mở cửa New York

//===== LỌC TIN TỨC =====
input group "=== LỌC TIN TỨC ==="
input ApexPullback::ENUM_NEWS_FILTER_MODE NewsFilterModeInput = ApexPullback::NEWS_FILTER_PAUSE_EA; // Chế độ lọc tin tức
input string  NewsDataFile = "news_calendar.csv";           // File dữ liệu tin tức
input ApexPullback::ENUM_NEWS_FILTER_LEVEL NewsImportanceInput = ApexPullback::NEWS_FILTER_HIGH; // Độ quan trọng tin (Mặc định: Cao)
input int     MinutesBeforeNews = 30;                       // Phút trước tin tức
input int     MinutesAfterNews = 15;                        // Phút sau tin tức

//===== TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC =====
input group "=== TỰ ĐỘNG TẠM DỪNG & KHÔI PHỤC ==="
input bool    EnableAutoPause = true;                       // Bật tự động tạm dừng
input double  VolatilityPauseThreshold = 2.5;               // Ngưỡng biến động để tạm dừng (xATR)
input double  DrawdownPauseThreshold = 7.0;                 // Ngưỡng DD để tạm dừng (%)
input bool    EnableAutoResume = true;                      // Bật tự động khôi phục
input int     PauseDurationMinutes = 120;                   // Thời gian tạm dừng (phút)
input bool    ResumeOnLondonOpen = true;                    // Tự động khôi phục vào London Open

//===== ASSETPROFILER - MODULE MỚI =====
input group "=== ASSETPROFILER - MODULE MỚI ==="
input bool    UseAssetProfiler = true;                      // Kích hoạt AssetProfiler
input int     AssetProfileDays = 30;                        // Số ngày phân tích tài sản
input bool    AdaptRiskByAsset = true;                      // Tự động điều chỉnh risk theo tài sản
input bool    AdaptSLByAsset = true;                        // Tự động điều chỉnh SL theo tài sản
input bool    AdaptSpreadFilterByAsset = true;              // Tự động lọc spread theo tài sản
input ApexPullback::ENUM_ADAPTIVE_MODE AdaptiveMode = ApexPullback::MODE_MANUAL;      // Chế độ thích nghi (Manual, Log Only, Hybrid)

//===== CHẾ ĐỘ TAKE PROFIT (Ưu tiên #2) =====
input group "=== CHẾ ĐỘ TAKE PROFIT ==="
input ApexPullback::ENUM_TP_MODE TakeProfitMode = ApexPullback::TP_MODE_STRUCTURE; // Chế độ Take Profit (Mặc định: Cấu trúc)
input double StopLossBufferATR_Ratio = 0.2; // Tỷ lệ ATR cho vùng đệm Stop Loss theo cấu trúc
input double StopLossATR_Multiplier = 2.0; // Hệ số ATR cho Stop Loss (fallback)
input double TakeProfitStructureBufferATR_Ratio = 0.1; // Tỷ lệ ATR cho vùng đệm Take Profit theo cấu trúc
input double ADXThresholdForVolatilityTP = 25.0; // Ngưỡng ADX để xác định biến động cao/thấp cho TP
input double VolatilityTP_ATR_Multiplier_High = 2.5; // Hệ số ATR cho TP khi biến động cao
input double VolatilityTP_ATR_Multiplier_Low = 1.8; // Hệ số ATR cho TP khi biến động thấp

//===== QUẢN LÝ DANH MỤC =====
input group "=== QUẢN LÝ DANH MỤC ==="
input bool IsMasterPortfolioManager = false; // Đặt làm Master EA để quản lý danh mục

//===== ASSETDNA - TINH CHỈNH ĐỘNG CƠ CHIẾN LƯỢC =====
input group "=== ASSETDNA - TINH CHỈNH ĐỘNG CƠ CHIẾN LƯỢC ==="
input double  MarketSuitabilityWeight = 0.65;               // Trọng số điểm phù hợp thị trường (0.0-1.0)
input double  PastPerformanceWeight = 0.35;                 // Trọng số điểm hiệu suất quá khứ (0.0-1.0)
input int     MinTradesForPerformance = 10;                 // Số giao dịch tối thiểu để tính hiệu suất
input double  ColdStartDefaultScore = 0.5;                  // Điểm mặc định khi thiếu dữ liệu (0.0-1.0)
input int     HistoryAnalysisMonths = 6;                    // Số tháng phân tích lịch sử (1-24)
input double  RecentTradeDecayFactor = 0.8;                 // Hệ số phân rã cho giao dịch cũ (0.1-1.0)
input bool    EnableColdStartAdaptation = true;             // Tự động điều chỉnh trọng số khi thiếu dữ liệu

//===== ASSETDNA - NGƯỠNG ĐIỂM CHIẾN LƯỢC =====
input group "=== ASSETDNA - NGƯỠNG ĐIỂM CHIẾN LƯỢC ==="
input double  TrendScoreThreshold = 0.6;                    // Ngưỡng điểm xu hướng cho Pullback (0.0-1.0)
input double  MomentumScoreThreshold = 0.5;                  // Ngưỡng điểm momentum cho Pullback (0.0-1.0)
input double  VolatilityScoreThreshold = 0.7;                // Ngưỡng điểm biến động cho Pullback (0.0-1.0)
input double  MeanReversionRegimeThreshold = 0.4;           // Ngưỡng regime cho Mean Reversion (0.0-1.0)
input double  MeanReversionVolatilityThreshold = 0.5;       // Ngưỡng biến động cho Mean Reversion (0.0-1.0)
input double  BreakoutMomentumThreshold = 0.7;              // Ngưỡng momentum cho Breakout (0.0-1.0)
input double  BreakoutVolumeThreshold = 0.6;                // Ngưỡng volume cho Breakout (0.0-1.0)
input double  ShallowPullbackTrendThreshold = 0.75;         // Ngưỡng xu hướng cho Shallow Pullback (0.0-1.0)
input double  RangeTradingTrendThreshold = 0.4;             // Ngưỡng xu hướng cho Range Trading (0.0-1.0)
input double  RangeTradingVolatilityThreshold = 0.4;        // Ngưỡng biến động cho Range Trading (0.0-1.0)

//===== ASSETDNA - LOGGING & DEBUGGING =====
input group "=== ASSETDNA - LOGGING & DEBUGGING ==="
input bool    EnableDetailedScoreLogging = false;           // Bật log chi tiết điểm số
input bool    EnableStrategyPerformanceLogging = false;     // Bật log hiệu suất chiến lược
input bool    EnableColdStartLogging = true;                // Bật log cảnh báo cold start

// KẾT THÚC NAMESPACE - This should be at the very end of the file content, right before #endif

#endif // GLOBAL_PARAMETERS_MQH