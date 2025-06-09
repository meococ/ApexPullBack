//+------------------------------------------------------------------+
//|                      Enums.mqh - APEX Pullback EA v14.0          |
//|                           Copyright 2023-2024, APEX Forex        |
//|                             https://www.apexpullback.com         |
//+------------------------------------------------------------------+
#ifndef ENUMS_MQH
#define ENUMS_MQH

//+------------------------------------------------------------------+
//| Định nghĩa các loại cluster cho chiến lược                       |
//+------------------------------------------------------------------+
enum ENUM_CLUSTER_TYPE {
    CLUSTER_NONE = 0,             // Không xác định
    CLUSTER_1_TREND_FOLLOWING,    // Cluster 1: Theo xu hướng
    CLUSTER_2_COUNTERTREND,      // Cluster 2: Đảo chiều
    CLUSTER_3_BREAKOUT,          // Cluster 3: Breakout
    CLUSTER_4_RANGE_TRADING,     // Cluster 4: Giao dịch trong biên độ
    CLUSTER_5_VOLATILITY,        // Cluster 5: Dựa trên biến động
    CLUSTER_REVERSAL,            // Chiến lược đảo chiều
    CLUSTER_SCALING,             // Chiến lược nhồi lệnh
    CLUSTER_PATTERN_BASED,       // Chiến lược dựa trên mẫu hình
    CLUSTER_MEAN_REVERSION,      // Chiến lược hồi quy trung bình
    CLUSTER_HARMONIC,            // Chiến lược Harmonic
    CLUSTER_DIVERGENCE,          // Chiến lược phân kỳ
    CLUSTER_CUSTOM               // Chiến lược tùy chỉnh
};

// Hằng số cho việc tương thích ngược
#define CLUSTER_TYPE_TREND CLUSTER_1_TREND_FOLLOWING
#define CLUSTER_TREND_FOLLOWING CLUSTER_1_TREND_FOLLOWING
#define CLUSTER_COUNTER_TREND CLUSTER_2_COUNTERTREND
#define CLUSTER_TYPE_COUNTER CLUSTER_2_COUNTERTREND
#define CLUSTER_TYPE_BREAKOUT CLUSTER_3_BREAKOUT
#define CLUSTER_TYPE_RANGE CLUSTER_4_RANGE_TRADING
#define CLUSTER_TYPE_VOLATILITY CLUSTER_5_VOLATILITY
#define CLUSTER_3_SCALING CLUSTER_CUSTOM    // Scaling strategy mapped to custom

// Log constants are now defined in Logger.mqh as enums
// Removed conflicting #define statements to avoid identifier conflicts


//===== TRẠNG THÁI EA =====
/// @brief Trạng thái hoạt động của EA
enum ENUM_EA_STATE {
    STATE_INIT,         // Đang khởi tạo
    STATE_RUNNING,      // Đang chạy bình thường
    STATE_PAUSED,       // Tạm dừng (do volatility, DD, tin tức...)
    STATE_REDUCED_RISK, // Đang chạy với risk thấp hơn (sau DD)
    STATE_STOPPED       // EA đã dừng hoạt động
};

// Legacy compatibility
#define STATE_ERROR STATE_STOPPED

//===== XU HƯỚNG THỊ TRƯỜNG =====
/// @brief Định nghĩa chi tiết các loại xu hướng thị trường
enum ENUM_MARKET_TREND {
    TREND_SIDEWAY,        // Không có xu hướng rõ ràng
    TREND_UP_STRONG,      // Xu hướng tăng mạnh (EMA 34-89-200 cách xa)
    TREND_UP_NORMAL,      // Xu hướng tăng bình thường
    TREND_UP_PULLBACK,    // Pullback trong xu hướng tăng (cơ hội BUY)
    TREND_DOWN_STRONG,    // Xu hướng giảm mạnh (EMA 34-89-200 cách xa)
    TREND_DOWN_NORMAL,    // Xu hướng giảm bình thường
    TREND_DOWN_PULLBACK   // Pullback trong xu hướng giảm (cơ hội SELL)
};

/// @brief Loại xu hướng đơn giản hóa
enum ENUM_TREND_TYPE {
    TREND_NONE = 0,            // Không có xu hướng
    TREND_UP = TREND_UP_STRONG,        // Chỉ giao dịch theo xu hướng tăng
    TREND_DOWN = TREND_DOWN_STRONG,    // Chỉ giao dịch theo xu hướng giảm
    TREND_BIDIRECTIONAL      // Giao dịch cả 2 chiều
};

//===== CHẾ ĐỘ THỊ TRƯỜNG (REGIME) =====
/// @brief Định nghĩa các chế độ thị trường chi tiết
enum ENUM_MARKET_REGIME {
    REGIME_UNKNOWN = 0,           // Chế độ chưa xác định
    REGIME_TRENDING = 1,          // Chế độ xu hướng tổng quát
    REGIME_TRENDING_BULL = 2,     // Xu hướng tăng mạnh
    REGIME_TRENDING_BEAR = 3,     // Xu hướng giảm mạnh
    REGIME_RANGING = 4,           // Chế độ sideway tổng quát
    REGIME_RANGING_STABLE = 5,    // Sideway ổn định
    REGIME_RANGING_VOLATILE = 6,  // Sideway biến động
    REGIME_VOLATILE = 7,          // Chế độ biến động cao
    REGIME_VOLATILE_EXPANSION = 8, // Biến động mở rộng
    REGIME_VOLATILE_CONTRACTION = 9, // Biến động thu hẹp
    REGIME_TRANSITIONING = 10     // Chế độ chuyển tiếp giữa các trạng thái
};

// Định nghĩa các constant cho chế độ thị trường chi tiết để tương thích ngược
// Định nghĩa các constant cho chế độ thị trường chi tiết để tương thích ngược
#define REGIME_DETAILED_UNKNOWN           REGIME_UNKNOWN
#define REGIME_DETAILED_TRENDING          REGIME_TRENDING
#define REGIME_DETAILED_TRENDING_BULL     REGIME_TRENDING_BULL
#define REGIME_DETAILED_TRENDING_BEAR     REGIME_TRENDING_BEAR
#define REGIME_DETAILED_RANGING           REGIME_RANGING
#define REGIME_DETAILED_RANGING_STABLE    REGIME_RANGING_STABLE
#define REGIME_DETAILED_RANGING_VOLATILE  REGIME_RANGING_VOLATILE
#define REGIME_DETAILED_VOLATILE          REGIME_VOLATILE
#define REGIME_DETAILED_VOLATILE_EXPANSION REGIME_VOLATILE_EXPANSION
#define REGIME_DETAILED_VOLATILE_CONTRACTION REGIME_VOLATILE_CONTRACTION
#define REGIME_DETAILED_LOW_VOLATILITY    REGIME_RANGING_STABLE  // Map to stable ranging

// ENUM_REGIME_SIMPLIFIED đã được hợp nhất vào ENUM_MARKET_REGIME để tránh trùng lập

/// @brief Preset cấu hình cho từng loại thị trường
enum ENUM_MARKET_PRESET {
    PRESET_AUTO,        // Tự động nhận diện và điều chỉnh
    PRESET_CONSERVATIVE, // Cấu hình bảo thủ (ít tín hiệu, chất lượng cao)
    PRESET_BALANCED,    // Cấu hình cân bằng
    PRESET_AGGRESSIVE,  // Cấu hình tích cực (nhiều tín hiệu hơn)
    PRESET_FOREX,       // Cấu hình cho Forex chính
    PRESET_EXOTICS,     // Cấu hình cho Forex ngoại lai
    PRESET_INDICES,     // Cấu hình cho chỉ số
    PRESET_METALS,      // Cấu hình cho kim loại (gold, silver)
    PRESET_CRYPTO,      // Cấu hình cho tiền điện tử
    PRESET_CUSTOM       // Cấu hình tùy chỉnh
};

//===== PHIÊN GIAO DỊCH =====
/// @brief Các phiên giao dịch chính trong ngày
enum ENUM_SESSION {
    SESSION_UNKNOWN = 0,       // Phiên không xác định
    SESSION_ASIAN = 1,        // Phiên Á (Tokyo)
    SESSION_EUROPEAN = 2,     // Phiên London (Âu)
    SESSION_AMERICAN = 3,     // Phiên New York (Mỹ)
    SESSION_SYDNEY = 4,       // Phiên Sydney
    SESSION_OVERNIGHT = 5,    // Phiên qua đêm
    SESSION_EUROPEAN_AMERICAN, // Phiên giao thoa Âu-Mỹ (thanh khoản cao nhất)
    SESSION_LONDON_NY,         // Phiên giao thoa London-NY (tương tự EUROPEAN_AMERICAN)
    SESSION_CLOSING            // Phiên đóng cửa (ít thanh khoản)
};

// ENUM_SESSION đã được sử dụng trực tiếp với các giá trị SESSION_*
// Không cần alias vì enum đã được cập nhật

// Define SESSION_FILTER_ALL constant for session filter
#define SESSION_FILTER_ALL FILTER_ALL_SESSIONS

/// @brief Bộ lọc phiên giao dịch
enum ENUM_SESSION_FILTER {
    FILTER_ALL_SESSIONS,         // Giao dịch mọi phiên
    FILTER_ASIAN_ONLY,          // Chỉ giao dịch phiên Á
    FILTER_LONDON_ONLY,         // Chỉ giao dịch phiên London
    FILTER_NEWYORK_ONLY,        // Chỉ giao dịch phiên New York
    FILTER_MAJOR_SESSIONS_ONLY, // Chỉ giao dịch phiên chính (London+NY)
    FILTER_OVERLAP_ONLY,        // Chỉ giao dịch phiên giao thoa
    FILTER_CUSTOM_SESSION       // Tùy chỉnh (sử dụng bitwise mask)
};

//===== TÍN HIỆU =====
/// @brief Loại tín hiệu
enum ENUM_SIGNAL_TYPE {
    SIGNAL_BUY,   // Tín hiệu mua
    SIGNAL_SELL,  // Tín hiệu bán
    SIGNAL_NONE   // Không có tín hiệu
};

/// @brief Hướng tín hiệu
enum ENUM_SIGNAL_DIRECTION {
    SIGNAL_DIRECTION_LONG,   // Tín hiệu xu hướng tăng (BUY)
    SIGNAL_DIRECTION_SHORT,  // Tín hiệu xu hướng giảm (SELL)
    SIGNAL_DIRECTION_BOTH,   // Cả hai chiều (BUY và SELL)
    SIGNAL_DIRECTION_NONE    // Không có chiều nào
};

/// @brief Kịch bản vào lệnh
enum ENUM_ENTRY_SCENARIO {
    SCENARIO_NONE,      // Không có kịch bản
    SCENARIO_PULLBACK,  // Pullback theo xu hướng (chiến lược chính)
    SCENARIO_BREAKOUT,  // Breakout level quan trọng
    SCENARIO_REVERSAL,  // Đảo chiều tại vùng hỗ trợ/kháng cự
    SCENARIO_SCALING    // Nhồi lệnh (thêm một lệnh vào vị thế có sẵn)
};

// Legacy compatibility
#define SCENARIO_UNKNOWN ((ENUM_ENTRY_SCENARIO)SCENARIO_NONE)

/// @brief Chế độ vào lệnh
enum ENUM_ENTRY_MODE {
    MODE_MARKET,      // Lệnh thị trường (vào ngay lập tức)
    MODE_LIMIT,       // Lệnh giới hạn (đợi pullback thêm)
    MODE_SMART        // Thông minh (dựa trên chất lượng tín hiệu)
};

// Legacy compatibility for session types
#define SESSION_TYPE_ASIAN SESSION_ASIAN
#define SESSION_NONE SESSION_UNKNOWN
#define SESSION_OVERLAP SESSION_SYDNEY

//===== QUẢN LÝ RỦI RO =====
/// @brief Trạng thái rủi ro hệ thống
enum ENUM_RISK_STATE {
    RISK_NORMAL,   // Rủi ro bình thường
    RISK_CAUTION,  // Cảnh báo rủi ro (DD 5-10%)
    RISK_WARNING,  // Rủi ro báo động (DD 10-15%)
    RISK_CRITICAL, // Rủi ro nghiêm trọng (DD 15%+)
    RISK_PAUSED    // Tạm dừng giao dịch do rủi ro
};

//===== SWING POINTS =====
/// @brief Loại điểm swing
enum ENUM_SWING_POINT_TYPE {
    SWING_HIGH,   // Điểm swing cao (đỉnh)
    SWING_LOW,    // Điểm swing thấp (đáy)
    SWING_UNKNOWN // Không xác định
};

/// @brief Tầm quan trọng của điểm swing
enum ENUM_SWING_IMPORTANCE {
    SWING_MINOR,   // Đỉnh/đáy nhỏ (ngắn hạn)
    SWING_MAJOR,   // Đỉnh/đáy lớn (trung hạn)
    SWING_CRITICAL // Đỉnh/đáy quan trọng (dài hạn)
};

//===== TRAILING STOP =====
/// @brief Các phương pháp trailing stop
enum ENUM_TRAILING_MODE {
    TRAILING_NONE,         // Không sử dụng trailing stop
    TRAILING_ATR,          // Trailing dựa trên ATR
    TRAILING_CHANDELIER,   // Trailing kiểu Chandelier Exit
    TRAILING_SWING_POINTS, // Trailing dựa trên swing points
    TRAILING_EMA,          // Sử dụng đường EMA
    TRAILING_PSAR,         // Sử dụng Parabolic SAR
    TRAILING_ADAPTIVE      // Thích ứng theo Regime
};

// Legacy compatibility
#define TRAILING_FIXED TRAILING_NONE
#define TRAILING_PERCENT TRAILING_NONE
#define TRAILING_VOLATILITY TRAILING_ATR
#define TRAILING_SWING_BASED TRAILING_SWING_POINTS
#define TRAILING_STRUCTURAL TRAILING_ADAPTIVE
#define TRAILING_HYBRID TRAILING_ADAPTIVE
#define TRAILING_FIBONACCI TRAILING_NONE

//===== MULTI-TIMEFRAME =====
/// @brief Sự đồng thuận của đa khung thời gian
enum ENUM_MTF_ALIGNMENT {
    MTF_ALIGNMENT_BULLISH,      // Đồng thuận xu hướng tăng (H1+H4+D1)
    MTF_ALIGNMENT_BEARISH,      // Đồng thuận xu hướng giảm (H1+H4+D1)
    MTF_ALIGNMENT_NEUTRAL,      // Trung tính (không rõ xu hướng)
    MTF_ALIGNMENT_CONFLICTING   // Mâu thuẫn giữa các khung thời gian
};

//===== BỘ LỌC TIN TỨC =====
/// @brief Mức độ lọc tin tức
enum ENUM_NEWS_FILTER {
    NEWS_NONE,   // Không lọc tin tức
    NEWS_LOW,    // Lọc tin tức tác động thấp
    NEWS_HIGH,   // Chỉ lọc tin tức tác động cao
    NEWS_MEDIUM, // Lọc tin tức tác động trung bình và cao
    NEWS_ALL,    // Lọc tất cả các tin tức
    NEWS_CUSTOM  // Lọc tin tức tùy chỉnh theo mức độ quan trọng
};

//===== THÔNG BÁO VÀ CẢNH BÁO =====
// Cấp độ cảnh báo
enum ENUM_ALERT_LEVEL {
    ALERT_LEVEL_NORMAL = 0,    // Thông báo bình thường
    ALERT_LEVEL_INFO = 1,      // Thông tin 
    ALERT_LEVEL_WARNING = 2,   // Cảnh báo
    ALERT_LEVEL_CRITICAL = 3   // Cảnh báo quan trọng
};
/// @brief Cấp độ log
enum ENUM_LOG_LEVEL {
    LOG_CRITICAL = 0, // Lỗi nghiêm trọng, EA không thể tiếp tục
    LOG_ERROR = 1,    // Lỗi nhưng EA vẫn có thể tiếp tục
    LOG_WARNING = 2,  // Cảnh báo, có thể ảnh hưởng đến hiệu suất
    LOG_INFO = 3,     // Thông tin quan trọng
    LOG_DEBUG = 4,    // Thông tin gỡ lỗi (chỉ khi debug)
    LOG_VERBOSE = 5   // Thông tin chi tiết (dành cho nhà phát triển)
};

// Log level constants are now defined as enums in Logger.mqh
// Removed conflicting #define statements to prevent identifier conflicts


//===== HIỆU SUẤT EA =====
/// @brief Trạng thái hiệu suất
//===== HEALTH PORTFOLIO =====
/// @brief Trạng thái sức khỏe danh mục đầu tư
enum ENUM_PORTFOLIO_HEALTH {
    PORTFOLIO_HEALTH_EXCELLENT,  // Danh mục xuất sắc
    PORTFOLIO_HEALTH_GOOD,       // Danh mục tốt
    PORTFOLIO_HEALTH_AVERAGE,    // Danh mục trung bình
    PORTFOLIO_HEALTH_WARNING,    // Danh mục cần cảnh báo
    PORTFOLIO_HEALTH_DANGER,     // Danh mục nguy hiểm
    PORTFOLIO_HEALTH_UNKNOWN     // Trạng thái không xác định
};

// ENUM_TRADING_SESSION đã được hợp nhất vào ENUM_SESSION 
// Chúng ta chỉ sử dụng ENUM_SESSION để tránh xung đột

//===== PERFORMANCE STATUS =====
/// @brief Trạng thái hiệu suất
enum ENUM_PERFORMANCE_STATUS {
    PERFORMANCE_EXCELLENT, // Hiệu suất xuất sắc (profit factor > 2.0)
    PERFORMANCE_GOOD,      // Hiệu suất tốt (profit factor 1.5-2.0)
    PERFORMANCE_AVERAGE,   // Hiệu suất trung bình (profit factor 1.2-1.5)
    PERFORMANCE_POOR,      // Hiệu suất kém (profit factor 1.0-1.2)
    PERFORMANCE_CRITICAL   // Hiệu suất nghiêm trọng (profit factor < 1.0)
};

//===== MẪU HÌNH PATTERN DETECTOR =====
/// @brief Các loại mẫu hình được phát hiện bởi PatternDetector
enum ENUM_PATTERN_TYPE {
    PATTERN_NONE = 0,              // Không có mẫu hình
    SCENARIO_FIBONACCI_PULLBACK,   // Pullback Fibonacci
    SCENARIO_BULLISH_PULLBACK,     // Pullback tăng
    SCENARIO_BEARISH_PULLBACK,     // Pullback giảm
    SCENARIO_STRONG_PULLBACK,      // Pullback mạnh
    SCENARIO_MOMENTUM_SHIFT,       // Chuyển động lượng
    SCENARIO_HARMONIC_PATTERN,     // Mẫu hình harmonic (Gartley, Butterfly, Crab)
    SCENARIO_CUSTOM                // Mẫu hình tùy chỉnh
};

//===== ASSET PROFILER =====
/// @brief Loại tài sản (dùng cho AssetProfiler)
enum ENUM_ASSET_TYPE {
    ASSET_TYPE_FOREX_MAJOR,    // Cặp tiền chính (EURUSD, GBPUSD...)
    ASSET_TYPE_FOREX_MINOR,    // Cặp tiền phụ (EURGBP, AUDJPY...)
    ASSET_TYPE_FOREX_EXOTIC,   // Cặp tiền ngoại lai (USDTRY, USDZAR...)
    ASSET_TYPE_INDEX,          // Chỉ số (DAX, S&P500...)
    ASSET_TYPE_COMMODITY,      // Hàng hóa (Oil, Natural Gas...)
    ASSET_TYPE_METAL,          // Kim loại (Gold, Silver...)
    ASSET_TYPE_CRYPTO,         // Tiền điện tử (BTCUSD, ETHUSD...)
    ASSET_TYPE_CUSTOM          // Tùy chỉnh hoặc không xác định
};

/// @brief Độ thanh khoản của tài sản

//===== ASSET PROFILER LOG LEVELS =====
/// @brief Định nghĩa log levels để kiểm soát lượng log cho Asset Profiler
enum ENUM_PROFILE_LOG_LEVEL {
    PROFILE_LOG_NONE = 0,      // Không log
    PROFILE_LOG_ERRORS,        // Chỉ log lỗi
    PROFILE_LOG_IMPORTANT,     // Log thông tin quan trọng
    PROFILE_LOG_ALL            // Log tất cả
};

//===== ASSET PROFILER ADJUSTMENT MODE =====
/// @brief Enum cho loại điều chỉnh trong Asset Profiler
enum ENUM_ADJUSTMENT_MODE {
    ADJ_MODE_BASIC = 0,        // Điều chỉnh cơ bản
    ADJ_MODE_ADVANCED,         // Điều chỉnh nâng cao (sigmoid)
    ADJ_MODE_TIME_WEIGHTED     // Điều chỉnh có trọng số thời gian
};

//===== WEEKDAYS ENUM =====
/// @brief Enum cho các ngày trong tuần
enum ENUM_WEEKDAYS {
    WEEKDAY_SUNDAY = 0,   // Chủ nhật
    WEEKDAY_MONDAY,      // Thứ hai
    WEEKDAY_TUESDAY,     // Thứ ba
    WEEKDAY_WEDNESDAY,   // Thứ tư
    WEEKDAY_THURSDAY,    // Thứ năm
    WEEKDAY_FRIDAY,      // Thứ sáu
    WEEKDAY_SATURDAY     // Thứ bảy
};

//===== TREND DIRECTION =====
/// @brief Hướng xu hướng giao dịch
enum ENUM_TREND_DIRECTION {
    TREND_BOTH,        // Cả hai chiều (buy và sell)
    TREND_BUY_ONLY,    // Chỉ giao dịch mua (buy only)
    TREND_SELL_ONLY    // Chỉ giao dịch bán (sell only)
};

/// @brief Độ thanh khoản của tài sản
enum ENUM_ASSET_LIQUIDITY {
    LIQUIDITY_VERY_LOW,  // Thanh khoản rất thấp (exotic pairs)
    LIQUIDITY_LOW,       // Thanh khoản thấp
    LIQUIDITY_MEDIUM,    // Thanh khoản trung bình
    LIQUIDITY_HIGH,      // Thanh khoản cao (forex majors)
    LIQUIDITY_VERY_HIGH  // Thanh khoản rất cao (EURUSD, S&P500)
};

//===== LOẠI GIÁ TRỊ TỐI ƯU =====
/// @brief Loại giá trị tối ưu (sử dụng cho Walk-Forward)
enum ENUM_OPTIMIZATION_TYPE {
    OPT_BALANCE,           // Số dư cuối kỳ
    OPT_PROFIT_FACTOR,     // Profit Factor
    OPT_EXPECTED_PAYOFF,   // Expected Payoff
    OPT_DRAWDOWN_PERCENT,  // Drawdown tính theo %
    OPT_RECOVERY_FACTOR,   // Recovery Factor
    OPT_SHARPE_RATIO,      // Sharpe Ratio
    OPT_CUSTOM             // Tùy chỉnh (dùng với hàm tối ưu riêng)
};

//===== THIẾT LẬP HỆ THỐNG =====
/// @brief Chủ đề hiển thị dashboard
enum ENUM_DASHBOARD_THEME {
    DASHBOARD_DARK,        // Chủ đề tối
    DASHBOARD_LIGHT,       // Chủ đề sáng
    DASHBOARD_BLUE,        // Chủ đề xanh da trời
    DASHBOARD_GREEN,       // Chủ đề xanh lá
    DASHBOARD_CUSTOM       // Chủ đề tùy chỉnh
};

/// @brief Chế độ hiển thị dashboard
enum ENUM_DASHBOARD_MODE {
    DASHBOARD_FULL,       // Hiển thị đầy đủ thông tin
    DASHBOARD_MINIMAL,    // Hiển thị tối thiểu 
    DASHBOARD_PERFORMANCE,// Tập trung vào hiệu suất
    DASHBOARD_TECHNICAL,  // Tập trung vào phân tích kỹ thuật
    DASHBOARD_RISK,       // Tập trung vào quản lý rủi ro
    DASHBOARD_CUSTOM      // Tùy chỉnh
};

//===== THANH KHOẢN THỊ TRƯỜNG =====
/// @brief Trạng thái thanh khoản (từ AssetProfiler)
enum ENUM_LIQUIDITY_STATE {
    LIQUIDITY_NORMAL,      // Thanh khoản bình thường
    LIQUIDITY_DECREASING,  // Thanh khoản đang giảm
    LIQUIDITY_LOW_WARNING, // Cảnh báo thanh khoản thấp
    LIQUIDITY_EXTREME_LOW  // Thanh khoản cực thấp, cẩn thận
};
// Phân loại tài sản
enum ENUM_ASSET_CLASS {
    ASSET_CLASS_FOREX,    // Forex
    ASSET_CLASS_METALS,   // Kim loại
    ASSET_CLASS_INDICES,  // Chỉ số
    ASSET_CLASS_CRYPTO,   // Tiền điện tử
    ASSET_CLASS_OTHER     // Khác
};

// Nhóm cặp tiền
enum ENUM_SYMBOL_GROUP {
   GROUP_MAJOR,         // Cặp chính
   GROUP_MINOR,         // Cặp phụ
   GROUP_EXOTIC,        // Cặp ngoại lai
   GROUP_GOLD,          // Vàng
   GROUP_SILVER,        // Bạc
   GROUP_METALS_OTHER,  // Kim loại khác
   GROUP_US_INDICES,    // Chỉ số Mỹ
   GROUP_EU_INDICES,    // Chỉ số châu Âu
   GROUP_ASIAN_INDICES, // Chỉ số châu Á
   GROUP_INDICES_OTHER, // Chỉ số khác
   GROUP_CRYPTO,        // Tiền điện tử
   GROUP_ENERGY,        // Năng lượng
   GROUP_UNDEFINED      // Chưa xác định
};

// Mức độ biến động
enum ENUM_ASSET_VOLATILITY {
   VOLATILITY_LOW,      // Thấp
   VOLATILITY_MEDIUM,   // Trung bình
   VOLATILITY_HIGH,     // Cao
   VOLATILITY_EXTREME   // Cực cao
};


// Enum cho chế độ Take Profit (Ưu tiên #2)
enum ENUM_TP_MODE {
    TP_MODE_RR_FIXED,    // Chốt lời theo tỷ lệ R:R cố định
    TP_MODE_STRUCTURE,   // Chốt lời theo cấu trúc (đỉnh/đáy cũ)
    TP_MODE_VOLATILITY   // Chốt lời theo biến động (ADX)
};

//===== CHẾ ĐỘ THÍCH NGHI (ADAPTIVE MODE) =====
/// @brief Xác định cách EA sử dụng các tham số từ Inputs và AssetProfiler
enum ENUM_ADAPTIVE_MODE {
    MODE_MANUAL,    // EA 100% tuân theo tham số trong Inputs
    MODE_LOG_ONLY,  // EA chạy theo Inputs, AssetProfiler ghi log đề xuất
    MODE_HYBRID     // EA kết hợp tham số Inputs và đề xuất từ AssetProfiler
};

#endif // ENUMS_MQH