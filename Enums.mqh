//+------------------------------------------------------------------+
//|                      Enums.mqh - APEX Pullback EA v14.0          |
//|                           Copyright 2023-2024, APEX Forex        |
//|                             https://www.apexpullback.com         |
//+------------------------------------------------------------------+
#ifndef ENUMS_MQH
#define ENUMS_MQH


//===== TRẠNG THÁI EA =====
/// @brief Trạng thái hoạt động của EA
enum ENUM_EA_STATE {
    STATE_INIT,         // Đang khởi tạo
    STATE_RUNNING,      // Đang chạy bình thường
    STATE_PAUSED,       // Tạm dừng (do volatility, DD, tin tức...)
    STATE_REDUCED_RISK, // Đang chạy với risk thấp hơn (sau DD)
    STATE_ERROR         // Có lỗi, cần kiểm tra
};

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
    TREND_NONE = 0,  // Không có xu hướng
    TREND_UP,       // Chỉ giao dịch theo xu hướng tăng
    TREND_DOWN,     // Chỉ giao dịch theo xu hướng giảm
    TREND_BOTH      // Giao dịch cả 2 chiều
};

//===== CHẾ ĐỘ THỊ TRƯỜNG (REGIME) =====
/// @brief Phân loại chế độ thị trường
enum ENUM_MARKET_REGIME {
    REGIME_TRENDING_BULL,       // Xu hướng tăng mạnh (trending bull)
    REGIME_TRENDING_BEAR,       // Xu hướng giảm mạnh (trending bear)
    REGIME_RANGING_STABLE,      // Sideway ổn định, biến động thấp
    REGIME_RANGING_VOLATILE,    // Sideway nhưng biến động cao
    REGIME_VOLATILE_EXPANSION,  // Biến động mở rộng (volatility expansion)
    REGIME_VOLATILE_CONTRACTION // Biến động thu hẹp (volatility contraction)
};

/// @brief Đơn giản hóa chế độ thị trường khi cần
enum ENUM_REGIME_SIMPLIFIED {
    REGIME_TRENDING, // Trending market (bull/bear)
    REGIME_RANGING,  // Thị trường sideway 
    REGIME_VOLATILE  // Thị trường biến động cao
};

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
    SESSION_ASIAN,             // Phiên Á (Tokyo, Sydney)
    SESSION_LONDON,            // Phiên London (Âu)
    SESSION_NEWYORK,           // Phiên New York (Mỹ)
    SESSION_EUROPEAN_AMERICAN, // Phiên giao thoa Âu-Mỹ (thanh khoản cao nhất)
    SESSION_CLOSING,           // Phiên đóng cửa (ít thanh khoản)
    SESSION_UNKNOWN            // Phiên không xác định
};

/// @brief Bộ lọc phiên giao dịch
enum ENUM_SESSION_FILTER {
    SESSION_ALL,           // Giao dịch mọi phiên
    SESSION_ASIAN_ONLY,    // Chỉ giao dịch phiên Á
    SESSION_LONDON_ONLY,   // Chỉ giao dịch phiên London
    SESSION_NEWYORK_ONLY,  // Chỉ giao dịch phiên New York
    SESSION_MAJOR_ONLY,    // Chỉ giao dịch phiên chính (London+NY)
    SESSION_OVERLAP_ONLY,  // Chỉ giao dịch phiên giao thoa
    SESSION_CUSTOM         // Tùy chỉnh (sử dụng bitwise mask)
};

//===== TÍN HIỆU VÀ ENTRY =====
/// @brief Loại tín hiệu giao dịch
enum ENUM_SIGNAL_TYPE {
    SIGNAL_BUY,   // Tín hiệu mua
    SIGNAL_SELL,  // Tín hiệu bán
    SIGNAL_NONE   // Không có tín hiệu
};

/// @brief Chủ đề giao diện Dashboard
enum ENUM_DASHBOARD_THEME {
    DASHBOARD_LIGHT,     // Giao diện sáng
    DASHBOARD_DARK,      // Giao diện tối
    DASHBOARD_BLUE,      // Giao diện xanh dương
    DASHBOARD_GREEN,     // Giao diện xanh lá
    DASHBOARD_CUSTOM     // Giao diện tùy chỉnh
};

/// @brief Kịch bản vào lệnh
enum ENUM_ENTRY_SCENARIO {
    SCENARIO_NONE,      // Không có kịch bản
    SCENARIO_PULLBACK,  // Pullback theo xu hướng (chiến lược chính)
    SCENARIO_BREAKOUT,  // Breakout level quan trọng
    SCENARIO_REVERSAL,  // Đảo chiều tại vùng hỗ trợ/kháng cự
    SCENARIO_SCALING,   // Nhồi lệnh (thêm một lệnh vào vị thế có sẵn)
    SCENARIO_UNKNOWN    // Kịch bản không xác định
};

/// @brief Chế độ vào lệnh
enum ENUM_ENTRY_MODE {
    MODE_MARKET,      // Lệnh thị trường (vào ngay lập tức)
    MODE_LIMIT,       // Lệnh giới hạn (đợi pullback thêm)
    MODE_SMART        // Thông minh (dựa trên chất lượng tín hiệu)
};

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
    TRAILING_NONE,            // Không sử dụng trailing stop
    TRAILING_ATR,             // Trailing dựa trên ATR (phổ biến)
    TRAILING_BREAKEVEN_PLUS,  // Chỉ đưa về breakeven + buffer
    TRAILING_CHANDELIER,      // Chandelier Exit (theo Đỉnh/Đáy) 
    TRAILING_SWING_POINTS     // Trailing dựa trên các điểm swing
};

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
/// @brief Cấp độ log
enum ENUM_LOG_LEVEL {
    LOG_CRITICAL = 0, // Lỗi nghiêm trọng, EA không thể tiếp tục
    LOG_ERROR = 1,    // Lỗi nhưng EA vẫn có thể tiếp tục
    LOG_WARNING = 2,  // Cảnh báo, có thể ảnh hưởng đến hiệu suất
    LOG_INFO = 3,     // Thông tin quan trọng
    LOG_DEBUG = 4,    // Thông tin gỡ lỗi (chỉ khi debug)
    LOG_VERBOSE = 5   // Thông tin chi tiết (dành cho nhà phát triển)
};

//===== HIỆU SUẤT EA =====
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
    PATTERN_NONE,              // Không có mẫu hình
    SCENARIO_FIBONACCI_PULLBACK, // Pullback Fibonacci
    SCENARIO_BULLISH_PULLBACK,   // Pullback tăng
    SCENARIO_BEARISH_PULLBACK,   // Pullback giảm
    SCENARIO_STRONG_PULLBACK,    // Pullback mạnh
    SCENARIO_MOMENTUM_SHIFT,     // Chuyển động lượng
    SCENARIO_HARMONIC_PATTERN,   // Mẫu hình harmonic (Gartley, Butterfly, Crab)
    SCENARIO_CUSTOM              // Mẫu hình tùy chỉnh
};

//===== CLUSTER TYPE =====
/// @brief Loại chiến lược giao dịch
enum ENUM_CLUSTER_TYPE {
    CLUSTER_NONE,              // Không xác định
    CLUSTER_TREND_FOLLOWING,    // Chiến lược theo xu hướng
    CLUSTER_COUNTER_TREND,     // Chiến lược ngược xu hướng
    CLUSTER_BREAKOUT,          // Chiến lược breakout (vượt trở)
    CLUSTER_REVERSAL,          // Chiến lược đảo chiều
    CLUSTER_SCALING,           // Chiến lược nhồi lệnh
    CLUSTER_PATTERN_BASED,     // Chiến lược dựa trên mẫu hình
    CLUSTER_MEAN_REVERSION,    // Chiến lược hồi quy trung bình
    CLUSTER_HARMONIC,          // Chiến lược Harmonic
    CLUSTER_DIVERGENCE,        // Chiến lược phân kỳ
    CLUSTER_CUSTOM             // Chiến lược tùy chỉnh
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
#endif // ENUMS_MQH