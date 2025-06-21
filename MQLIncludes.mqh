//+------------------------------------------------------------------+
//|                                                 MQLIncludes.mqh |
//|                          Copyright 2023, Apex Pullback EA Team |
//|                                https://www.apexpullbackea.com |
//+------------------------------------------------------------------+
#ifndef MQLINCLUDES_MQH
#define MQLINCLUDES_MQH

// Định nghĩa các macro để tránh include lặp thư viện chuẩn MQL5
#ifndef _TRADE_MQH_INCLUDED_
#define _TRADE_MQH_INCLUDED_
#include <Trade/Trade.mqh>
#endif

#ifndef _POSITION_INFO_MQH_INCLUDED_
#define _POSITION_INFO_MQH_INCLUDED_
#include <Trade/PositionInfo.mqh>
#endif

#ifndef _SYMBOL_INFO_MQH_INCLUDED_
#define _SYMBOL_INFO_MQH_INCLUDED_
#include <Trade/SymbolInfo.mqh>
#endif

#ifndef _ACCOUNT_INFO_MQH_INCLUDED_
#define _ACCOUNT_INFO_MQH_INCLUDED_
#include <Trade/AccountInfo.mqh>
#endif

#ifndef _FILES_TXT_MQH_INCLUDED_
#define _FILES_TXT_MQH_INCLUDED_
#include <Files/FileTxt.mqh>
#endif

#ifndef _FILE_MQH_INCLUDED_
#define _FILE_MQH_INCLUDED_
#include <Files/File.mqh>
#endif

#ifndef _ARRAY_OBJ_MQH_INCLUDED_
#define _ARRAY_OBJ_MQH_INCLUDED_
#include <Arrays/ArrayObj.mqh>
#endif

#ifndef _CHART_MQH_INCLUDED_
#define _CHART_MQH_INCLUDED_
#include <Charts/Chart.mqh>
#endif

// QUAN TRỌNG: Đảm bảo include ChartObject base class trước các lớp dẫn xuất
#ifndef _CHARTOBJECT_MQH_INCLUDED_
#define _CHARTOBJECT_MQH_INCLUDED_
#include <ChartObjects/ChartObject.mqh>
#endif

#ifndef _CHARTOBJECTS_LINES_MQH_INCLUDED_
#define _CHARTOBJECTS_LINES_MQH_INCLUDED_
#include <ChartObjects/ChartObjectsLines.mqh>
#endif

#ifndef _CHARTOBJECTS_SHAPES_MQH_INCLUDED_
#define _CHARTOBJECTS_SHAPES_MQH_INCLUDED_
#include <ChartObjects/ChartObjectsShapes.mqh>
#endif

// Include từ ChartObjects.mqh
#ifndef _OBJECT_MQH_INCLUDED_ // Thêm kiểm tra để tránh include lại nếu Object.mqh đã có
#define _OBJECT_MQH_INCLUDED_
#include <Object.mqh>
#endif
// Kết thúc phần include từ ChartObjects.mqh

// Định nghĩa các hằng số cần thiết (đã có sẵn, không cần thêm từ ChartObjects.mqh vì giống nhau)
#ifndef OBJPROP_TIME1
#define OBJPROP_TIME1   300
#define OBJPROP_TIME2   301
#define OBJPROP_PRICE1  302
#define OBJPROP_PRICE2  303
#define OBJPROP_POINT1  304
#define OBJPROP_POINT2  305
#endif

#endif // MQLINCLUDES_MQH
