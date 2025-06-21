//+------------------------------------------------------------------+
//|                                          CommonDefinitions.mqh |
//+------------------------------------------------------------------+
#ifndef COMMONDEFINITIONS_MQH_
#define COMMONDEFINITIONS_MQH_

// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "CommonStructs.mqh"      // Core structures, enums, and inputs
#include "Enums.mqh"            // TẤT CẢ các enum


// === INCLUDES CỤ THỂ (NẾU CẦN) ===
// #include "Logger.mqh"
// #include "MathHelper.mqh"

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

// Hằng số chung cho EA
// Hầu hết các hằng số đã được chuyển sang Constants.mqh hoặc Enums.mqh

// Các hằng số còn lại (nếu có) hoặc các định nghĩa đặc thù cho file này

// V14.0: Định nghĩa các thẻ (tags) ghi log tiêu chuẩn
// Lợi ích: Đảm bảo tính nhất quán, tránh lỗi chính tả, dễ dàng lọc và phân tích log.
#define TAG_RISK_MANAGER      "RiskManager"
#define TAG_TRADE_MANAGER     "TradeManager"
#define TAG_POSITION_MANAGER  "PositionManager"
#define TAG_ASSET_DNA         "AssetDNA"
#define TAG_BROKER_HEALTH     "BrokerHealth"
#define TAG_CIRCUIT_BREAKER   "CircuitBreaker"
#define TAG_INITIALIZATION    "Initialization"
#define TAG_DEINITIALIZATION  "Deinitialization"
#define TAG_DATA_PROVIDER     "DataProvider"
#define TAG_OPTIMIZER         "Optimizer"
#define TAG_CRITICAL_ALERT    "CriticalAlert"
#define TAG_WARNING_ALERT     "WarningAlert"
#define TAG_INFO_ALERT        "InfoAlert"
#define TAG_ORDER_EVENT       "OrderEvent"
#define TAG_STATE_CHANGE      "StateChange"

// Magic number range (đã có EA_MAGIC_NUMBER_BASE trong Constants.mqh, MAGIC_NUMBER_MAX có thể không cần thiết hoặc định nghĩa ở nơi khác nếu dùng)
// #define MAGIC_NUMBER_MAX 9999999 
// Ghi chú: Các hằng số như RISK_LEVEL, MARKET_CONDITION, TRADING_HOUR, DEFAULT_ATR_PERIOD, PARTIAL_CLOSE, TRAILING_STOP
// nên được xem xét để chuyển vào Constants.mqh nếu chúng là các giá trị mặc định hoặc cấu hình cốt lõi,
// hoặc vào Enums.mqh nếu chúng đại diện cho các trạng thái hoặc loại cụ thể.

} // KẾT THÚC NAMESPACE

#endif // COMMONDEFINITIONS_MQH_
