//+------------------------------------------------------------------+
//|                 Constants.mqh - APEX Pullback EA v14.0           |
//|           Copyright 2023-2024, APEX Forex                        |
//|   Mô tả: Tập trung tất cả hằng số cho EA để dễ bảo trì và tối ưu |
//+------------------------------------------------------------------+

#ifndef _Constants_MQH_
#define _Constants_MQH_

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

#endif // _Constants_MQH_