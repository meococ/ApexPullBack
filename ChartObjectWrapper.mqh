//+------------------------------------------------------------------+
//|                                         ChartObjectWrapper.mqh |
//|                                Copyright 2023, Apex Pullback EA |
//|                                https://www.apexpullbackea.com |
//+------------------------------------------------------------------+
#ifndef _CHART_OBJECT_WRAPPER_MQH_
#define _CHART_OBJECT_WRAPPER_MQH_

// Include thư viện chuẩn MQL5 ở GLOBAL scope, không đặt trong namespace
#include <ChartObjects/ChartObject.mqh>
#include <ChartObjects/ChartObjectsLines.mqh>
#include <ChartObjects/ChartObjectsShapes.mqh>

// Định nghĩa lớp wrapper đơn giản để sử dụng trong namespace
class CChartObjectWrapper {
private:
    string   m_name;       // Tên đối tượng
    long     m_chart_id;   // Chart ID
    int      m_window;     // Cửa sổ đồ thị
    datetime m_time1;      // Thời gian tọa độ 1
    double   m_price1;     // Giá tọa độ 1

public:
    CChartObjectWrapper() {
        m_name = "";
        m_chart_id = 0;
        m_window = 0;
        m_time1 = 0;
        m_price1 = 0.0;
    }
    
    ~CChartObjectWrapper() {
        // Xóa đối tượng nếu tồn tại
        if(m_name != "")
            Delete();
    }
    
    // Phương thức tạo đối tượng đơn giản
    bool Create(long chart_id, string name, int window, datetime time1, double price1) {
        m_chart_id = chart_id;
        m_name = name;
        m_window = window;
        m_time1 = time1;
        m_price1 = price1;
        
        // Tạo đối tượng trên biểu đồ bằng ObjectCreate
        return ObjectCreate(m_chart_id, m_name, OBJ_VLINE, m_window, m_time1, m_price1);
    }
    
    // Lấy tên đối tượng
    string Name() const {
        return m_name;
    }
    
    // Xóa đối tượng
    bool Delete() {
        if(m_name != "")
            return ObjectDelete(m_chart_id, m_name);
        return false;
    }
};

#endif // _CHART_OBJECT_WRAPPER_MQH_
