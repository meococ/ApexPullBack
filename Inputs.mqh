//+------------------------------------------------------------------+
//|                 Inputs.mqh - APEX Pullback EA v14.0              |
//|           Author: APEX Trading Team | Date: 2024-05-07           |
//|   Description: Tập trung các tham số điều chỉnh của EA           |
//+------------------------------------------------------------------+

#ifndef _Inputs_MQH_
#define _Inputs_MQH_

#include "Enums.mqh"                        // Định nghĩa enums
#include "CommonStructs.mqh"                // Định nghĩa structs
#include "Constants.mqh"                    // Định nghĩa constants


//===== THÔNG TIN CHUNG =====
input group "=== THÔNG TIN CHUNG ==="
input string  EAName            = "APEX Pullback EA v14.0";  // Tên EA
input string  EAVersion         = "14.0";                   // Phiên bản
input int     MagicNumber       = 14000;                    // Magic Number
input string  OrderComment      = "ApexPullback v14";       // Ghi chú lệnh
input bool    AllowNewTrades    = true;                     // Cho phép vào lệnh mới

//===== HIỂN THỊ & THÔNG BÁO =====
input group "=== HIỂN THỊ & THÔNG BÁO ==="
input bool    EnableDetailedLogs = false;                   // Bật log chi tiết
input bool    EnableCsvLog = false;                         // Ghi log vào file CSV
input string  CsvLogFilename = "ApexPullback_Log.csv";      // Tên file CSV log
input bool    DisplayDashboard = true;                      // Hiển thị dashboard
input ENUM_DASHBOARD_THEME DashboardTheme = DASHBOARD_DARK; // Chủ đề Dashboard
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
input int     EMA_Fast = 34;                                // EMA nhanh (34)
input int     EMA_Medium = 89;                              // EMA trung bình (89) 
input int     EMA_Slow = 200;                               // EMA chậm (200)
input bool    UseMultiTimeframe = true;                     // Sử dụng đa khung thời gian
input ENUM_TIMEFRAMES HigherTimeframe = PERIOD_H4;          // Khung thời gian cao hơn
input ENUM_TREND_TYPE TrendDirection = TREND_BOTH;          // Hướng xu hướng giao dịch

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
input ENUM_MARKET_PRESET MarketPreset = PRESET_AUTO;        // Preset thị trường
input double  MaxSpreadPoints = 10.0;                       // Spread tối đa (points)

//===== QUẢN LÝ RỦI RO =====
input group "=== QUẢN LÝ RỦI RO ==="
input double  RiskPercent = 1.0;                            // Risk % mỗi lệnh
input double  SL_ATR = 1.5;                                 // Hệ số ATR cho Stop Loss
input double  TP_RR = 2.0;                                  // Tỷ lệ R:R cho Take Profit
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
input ENUM_ENTRY_MODE EntryMode = MODE_SMART;               // Chế độ vào lệnh
input bool    UsePartialClose = true;                       // Sử dụng đóng từng phần
input double  PartialCloseR1 = 1.0;                         // R-multiple cho đóng phần 1
input double  PartialCloseR2 = 2.0;                         // R-multiple cho đóng phần 2
input double  PartialClosePercent1 = 35.0;                  // % đóng ở mức R1
input double  PartialClosePercent2 = 35.0;                  // % đóng ở mức R2

//===== TRAILING STOP =====
input group "=== TRAILING STOP ==="
input bool    UseAdaptiveTrailing = true;                   // Trailing thích ứng theo regime
input ENUM_TRAILING_MODE TrailingMode = TRAILING_ATR;       // Chế độ trailing mặc định
input double  TrailingAtrMultiplier = 2.0;                  // Hệ số ATR cho trailing
input double  BreakEvenAfterR = 1.0;                        // Chuyển BE sau (R-multiple)
input double  BreakEvenBuffer = 5.0;                        // Buffer cho breakeven (points)

//===== CHANDELIER EXIT =====
input group "=== CHANDELIER EXIT ==="
input bool    UseChandelierExit = true;                     // Kích hoạt Chandelier Exit
input int     ChandelierPeriod = 20;                        // Số nến lookback Chandelier
input double  ChandelierMultiplier = 3.0;                   // Hệ số ATR Chandelier

//===== SCALING (NHỒI LỆNH) =====
input group "=== SCALING (NHỒI LỆNH) ==="
input bool    EnableScaling = true;                         // Cho phép nhồi lệnh
input int     MaxScalingCount = 1;                          // Số lần nhồi tối đa
input double  ScalingRiskPercent = 0.3;                     // % risk cho lệnh nhồi (so với ban đầu)
input bool    RequireBreakEvenForScaling = true;            // Yêu cầu BE trước khi nhồi

//===== LỌC PHIÊN =====
input group "=== LỌC PHIÊN ==="
input bool    FilterBySession = false;                      // Kích hoạt lọc theo phiên
input ENUM_SESSION_FILTER SessionFilter = SESSION_ALL;      // Phiên giao dịch
input bool    UseGmtOffset = true;                          // Sử dụng điều chỉnh GMT
input int     GmtOffset = 0;                                // Điều chỉnh GMT (giờ)
input bool    TradeLondonOpen = true;                       // Giao dịch mở cửa London
input bool    TradeNewYorkOpen = true;                      // Giao dịch mở cửa New York

//===== LỌC TIN TỨC =====
input group "=== LỌC TIN TỨC ==="
input ENUM_NEWS_FILTER NewsFilter = NEWS_MEDIUM;            // Mức lọc tin tức
input string  NewsDataFile = "news_calendar.csv";           // File dữ liệu tin tức
input int     NewsImportance = 2;                           // Độ quan trọng tin (1-3)
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

#endif // _Inputs_MQH_