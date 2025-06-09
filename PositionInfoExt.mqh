//+------------------------------------------------------------------+
//|                                     PositionInfoExt.mqh (v14.0)   |
//|                                Copyright 2023-2024, ApexPullback EA |
//|                                    https://www.apexpullback.com  |
//+------------------------------------------------------------------+
//-- #property copyright "Copyright 2023-2024, ApexPullback EA"
//-- #property link      "https://www.apexpullback.com"
//-- #property version   "14.0"
//-- #property strict

#ifndef POSITION_INFO_EXT_MQH_
#define POSITION_INFO_EXT_MQH_

#include "CommonStructs.mqh"
#include "Enums.mqh"

namespace ApexPullback {

// --- ĐỊNH NGHĨA TRẠNG THÁI VỊI THẾ ---
enum ENUM_POSITION_STATE {
    POSITION_STATE_NORMAL,        // Trạng thái bình thường
    POSITION_STATE_BREAKEVEN,     // Đã đạt breakeven
    POSITION_STATE_PARTIAL1,      // Đã đóng một phần lần 1
    POSITION_STATE_PARTIAL2,      // Đã đóng một phần lần 2
    POSITION_STATE_SCALING,       // Đã nhồi lệnh
    POSITION_STATE_TRAILING,      // Đang trailing
    POSITION_STATE_WARNING        // Cảnh báo (ví dụ: thời gian giữ quá lâu)
};

// Mở rộng cấu trúc PositionInfo từ CommonStructs.mqh
struct PositionInfoExt : public PositionInfo {
    // Thêm các trường mở rộng cần thiết
    ENUM_POSITION_STATE state;         // Trạng thái hiện tại của vị thế
    
    double          riskAmount;        // Số tiền rủi ro (theo SL ban đầu)
    double          riskPercent;       // Phần trăm rủi ro
    double          currentR;          // R-multiple hiện tại (lợi nhuận/rủi ro)
    double          unrealizedPnL;     // Lợi nhuận chưa thực hiện
    double          unrealizedPnLPercent; // Lợi nhuận chưa thực hiện (%)
    
    int             holdingBars;       // Số nến đã giữ
    int             partialCloseCount; // Số lần đã đóng một phần
    int             numScalings;        // Số lần nhồi lệnh
    
    bool            isBreakevenHit;    // Đã đạt breakeven
    bool            isPartial1Done;    // Đã đóng một phần lần 1
    bool            isPartial2Done;    // Đã đóng một phần lần 2
    bool            needsTrailing;     // Cần áp dụng trailing stop
    
    // Thông tin thêm cho đánh giá
    double          qualityScore;      // Điểm chất lượng vị thế (0.0-1.0)
    double          targetR;           // R-multiple mục tiêu
    double          maxR;              // R-multiple cao nhất đã đạt được
    datetime        lastUpdateTime;    // Thời gian cập nhật cuối
    
    // Tham chiếu để map các trường từ PositionInfo
    double          entryPrice;        // Tham chiếu đến openPrice
    double          refCurrentPrice;   // Tham chiếu đến currentPrice
    double          initialSL;         // Tham chiếu đến initialStopLoss
    double          currentSL;         // Tham chiếu đến stopLoss
    double          initialTP;         // Tham chiếu đến takeProfit
    double          currentTP;         // Tham chiếu đến takeProfit
    double          initialLots;       // Tham chiếu đến initialVolume
    double          currentLots;       // Tham chiếu đến volume
    
    // Constructor
    PositionInfoExt() {
        // Gọi Clear() từ lớp cơ sở
        Clear();
        
        // Khởi tạo các trường mở rộng
        state = POSITION_STATE_NORMAL;
        
        riskAmount = 0;
        riskPercent = 0;
        currentR = 0;
        unrealizedPnLPercent = 0;
        
        holdingBars = 0;
        partialCloseCount = 0;
        numScalings = 0;
        
        isBreakevenHit = false;
        isPartial1Done = false;
        isPartial2Done = false;
        needsTrailing = false;
        
        qualityScore = 0;
        targetR = 0;
        maxR = 0;
        lastUpdateTime = 0;
        
        // Map các trường
        entryPrice = openPrice;
        refCurrentPrice = currentPrice;
        initialSL = initialStopLoss;
        currentSL = stopLoss;
        initialTP = takeProfit;
        currentTP = takeProfit;
        initialLots = initialVolume;
        currentLots = volume;
    }
    
    // Phương thức để đồng bộ dữ liệu giữa các trường tham chiếu và trường gốc
    void SyncFields() {
        // Đồng bộ từ tham chiếu sang trường gốc
        openPrice = entryPrice;
        currentPrice = refCurrentPrice;
        initialStopLoss = initialSL;
        stopLoss = currentSL;
        takeProfit = initialTP;
        takeProfit = currentTP;
        initialVolume = initialLots;
        volume = currentLots;
    }
    
    // Phương thức để đồng bộ ngược lại từ trường gốc sang tham chiếu
    void SyncReferences() {
        // Đồng bộ từ trường gốc sang tham chiếu
        entryPrice = openPrice;
        refCurrentPrice = currentPrice;
        initialSL = initialStopLoss;
        currentSL = stopLoss;
        initialTP = takeProfit;
        currentTP = takeProfit;
        initialLots = initialVolume;
        currentLots = volume;
    }
    
    // Phương thức để sao chép dữ liệu từ một đối tượng PositionInfoExt khác
    bool Copy(const PositionInfoExt &source) {
        // Sao chép dữ liệu từ lớp cơ sở PositionInfo
        ticket = source.ticket;
        type = source.type;
        openTime = source.openTime;
        openPrice = source.openPrice;
        currentPrice = source.currentPrice;
        initialStopLoss = source.initialStopLoss;
        stopLoss = source.stopLoss;
        takeProfit = source.takeProfit;
        initialVolume = source.initialVolume;
        volume = source.volume;
        profit = source.profit;
        scenario = source.scenario;
        
        // Sao chép dữ liệu từ các trường mở rộng
        state = source.state;
        
        riskAmount = source.riskAmount;
        riskPercent = source.riskPercent;
        currentR = source.currentR;
        unrealizedPnL = source.unrealizedPnL;
        unrealizedPnLPercent = source.unrealizedPnLPercent;
        
        holdingBars = source.holdingBars;
        partialCloseCount = source.partialCloseCount;
        numScalings = source.numScalings;
        
        isBreakevenHit = source.isBreakevenHit;
        isPartial1Done = source.isPartial1Done;
        isPartial2Done = source.isPartial2Done;
        needsTrailing = source.needsTrailing;
        
        qualityScore = source.qualityScore;
        targetR = source.targetR;
        maxR = source.maxR;
        lastUpdateTime = source.lastUpdateTime;
        
        // Đồng bộ các trường tham chiếu
        SyncReferences();
        
        return true;
    }
    
    // Phương thức sao chép - hoàn toàn tương thích với MQL5
    // MQL5 không hỗ trợ CObject* như trong C++
    bool Copy(PositionInfoExt &src) {
        // Sử dụng kiểu cụ thể thay vì CObject* vì MQL5 không hỗ trợ RTTI
        // hoặc dynamic_cast như C++
        
        // Không cần kiểm tra NULL vì chúng ta sử dụng tham chiếu thay vì con trỏ
        
        // Giả định rằng đối tượng đã được kiểm tra trước đó và là PositionInfoExt
        // Trong trường hợp thực tế, phải có kiểm tra loại đối tượng khác
        
        // Sao chép dữ liệu từ đối tượng nguồn
        state = src.state;
        riskAmount = src.riskAmount;
        riskPercent = src.riskPercent;
        initialStopLoss = src.initialStopLoss;
        currentR = src.currentR;
        targetR = src.targetR;
        maxR = src.maxR;
        unrealizedPnL = src.unrealizedPnL;
        unrealizedPnLPercent = src.unrealizedPnLPercent;
        qualityScore = src.qualityScore;
        scenario = src.scenario;
        isBreakevenHit = src.isBreakevenHit;
        isPartial1Done = src.isPartial1Done;
        isPartial2Done = src.isPartial2Done;
        partialCloseCount = src.partialCloseCount;
        needsTrailing = src.needsTrailing;
        holdingBars = src.holdingBars;
        initialVolume = src.initialVolume;
        
        return true;
    }
};

} // namespace ApexPullback

#endif // POSITION_INFO_EXT_MQH_
