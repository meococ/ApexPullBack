//+------------------------------------------------------------------+
//|                                        CommonDefinitions.mqh |
//|                        Copyright 2025, APEX Forex - Mèo Cọc |
//|                                      https://www.apexforex.com |
//+------------------------------------------------------------------+
#ifndef COMMON_DEFINITIONS_MQH
#define COMMON_DEFINITIONS_MQH

// Import Namespace.mqh để sử dụng các định nghĩa hằng số chung
#include "Namespace.mqh"
#include "CommonStructs.mqh"  // Sử dụng các struct từ CommonStructs.mqh

// Hằng số chung cho EA
// Hầu hết các hằng số đã được chuyển sang Constants.mqh hoặc Enums.mqh

// Các hằng số còn lại (nếu có) hoặc các định nghĩa đặc thù cho file này
// Ví dụ: (Nếu cần thiết, nếu không có thể để trống phần này)
// #define SPECIFIC_DEFINITION_FOR_COMMON_DEFINITIONS 123

// Magic number range (đã có EA_MAGIC_NUMBER_BASE trong Constants.mqh, MAGIC_NUMBER_MAX có thể không cần thiết hoặc định nghĩa ở nơi khác nếu dùng)
// #define MAGIC_NUMBER_MAX 9999999 
// Ghi chú: Các hằng số như RISK_LEVEL, MARKET_CONDITION, TRADING_HOUR, DEFAULT_ATR_PERIOD, PARTIAL_CLOSE, TRAILING_STOP
// nên được xem xét để chuyển vào Constants.mqh nếu chúng là các giá trị mặc định hoặc cấu hình cốt lõi,
// hoặc vào Enums.mqh nếu chúng đại diện cho các trạng thái hoặc loại cụ thể.

#endif // COMMON_DEFINITIONS_MQH
