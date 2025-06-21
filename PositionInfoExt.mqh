//+------------------------------------------------------------------+
//|                                          PositionInfoExt.mqh |
//|                         Copyright 2023-2024, ApexPullback EA |
//|                                     https://www.apexpullback.com |
//+------------------------------------------------------------------+

#ifndef POSITIONINFOEXT_MQH_
#define POSITIONINFOEXT_MQH_

//--- Standard Library Includes
#include <Trade/PositionInfo.mqh> // Standard MQL5 PositionInfo class

//--- Core Project Includes
#include "CommonStructs.mqh"      // Core structures, enums, and inputs
#include "Enums.mqh"       // For ENUM_POSITION_STATE, ENUM_ENTRY_SCENARIO etc.


//+------------------------------------------------------------------+
//| Namespace: ApexPullback                                          |
//| Purpose: Encapsulates all custom code for the EA.                |
//+------------------------------------------------------------------+
namespace ApexPullback {


// --- ĐỊNH NGHĨA TRẠNG THÁI VỊ THẾ ---
// ENUM_POSITION_STATE đã được cung cấp trong user_input, giữ nguyên nếu nó ở đây
// Nếu nó được định nghĩa ở nơi khác (ví dụ Enums.mqh), thì có thể xóa ở đây.
// Giả sử nó được định nghĩa ở đây theo user_input.
enum ENUM_POSITION_STATE {
    POSITION_STATE_NORMAL,        // Trạng thái bình thường
    POSITION_STATE_BREAKEVEN,     // Đã đạt breakeven
    POSITION_STATE_PARTIAL1,      // Đã đóng một phần lần 1
    POSITION_STATE_PARTIAL2,      // Đã đóng một phần lần 2
    POSITION_STATE_SCALING,       // Đã nhồi lệnh
    POSITION_STATE_TRAILING,      // Đang trailing
    POSITION_STATE_WARNING        // Cảnh báo (ví dụ: thời gian giữ quá lâu)
};

struct PositionInfoExt {
    // Chứa một đối tượng CPositionInfo làm thành viên
    CPositionInfo  m_coreInfo; // Đổi tên để rõ ràng hơn là thành viên nội bộ

    // Các trường mở rộng
    ENUM_POSITION_STATE state;         // Trạng thái hiện tại của vị thế
    ENUM_ENTRY_SCENARIO scenario;      // Kịch bản vào lệnh (giữ lại từ cấu trúc cũ nếu cần)
    ENUM_TRADING_STRATEGY entryStrategy; // <<-- THÊM MỚI: Chiến lược đã sử dụng để vào lệnh
    
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
    
    // Dữ liệu bối cảnh thị trường tại thời điểm vào lệnh
    MarketProfileData entryMarketContext; // "Dấu vân tay" thị trường
    
    // Các trường này không còn là tham chiếu trực tiếp nữa
    // mà sẽ được truy cập qua m_coreInfo hoặc được tính toán/lưu trữ riêng
    // double          entryPrice;        
    // double          refCurrentPrice;   
    // double          initialSL;         
    // double          currentSL;         
    // double          initialTP;         
    // double          currentTP;         
    // double          initialLots;       
    // double          currentLots;       

    // Constructor
    PositionInfoExt() {
        // m_coreInfo sẽ được tự động khởi tạo bởi constructor mặc định của CPositionInfo
        // Không cần gọi Clear() cho m_coreInfo ở đây trừ khi CPositionInfo yêu cầu
        
        // Khởi tạo các trường mở rộng
        state = POSITION_STATE_NORMAL;
        scenario = SCENARIO_UNKNOWN; // Hoặc giá trị mặc định phù hợp
        entryStrategy = STRATEGY_UNKNOWN; // Khởi tạo giá trị mặc định
        
        riskAmount = 0.0;
        riskPercent = 0.0;
        currentR = 0.0;
        unrealizedPnL = 0.0;
        unrealizedPnLPercent = 0.0;
        
        holdingBars = 0;
        partialCloseCount = 0;
        numScalings = 0;
        
        isBreakevenHit = false;
        isPartial1Done = false;
        isPartial2Done = false;
        needsTrailing = false;
        
        qualityScore = 0.0;
        targetR = 0.0;
        maxR = 0.0;
        lastUpdateTime = 0;
    }

    // Hàm để tải dữ liệu từ một ticket vị thế
    bool SelectByTicket(ulong ticket) {
        if (m_coreInfo.SelectByTicket(ticket)) {
            lastUpdateTime = TimeCurrent();
            // Có thể cập nhật thêm các trường mở rộng khác dựa trên m_coreInfo nếu cần
            return true;
        }
        return false;
    }

    // Các hàm helper để truy cập dữ liệu của CPositionInfo một cách thuận tiện
    ulong Ticket()           const { return m_coreInfo.Ticket(); }
    datetime Time()          const { return m_coreInfo.Time(); }
    datetime TimeMsc()       const { return (datetime)m_coreInfo.TimeMsc(); }
    datetime TimeUpdate()    const { return m_coreInfo.TimeUpdate(); }
    datetime TimeUpdateMsc() const { return (datetime)m_coreInfo.TimeUpdateMsc(); }
    ENUM_POSITION_TYPE Type() const { return (ENUM_POSITION_TYPE)m_coreInfo.Type(); } // Cần cast nếu ENUM_POSITION_TYPE của bạn khác
    ulong Magic()            const { return m_coreInfo.Magic(); }
    ulong Identifier()       const { return m_coreInfo.Identifier(); }

    double PriceOpen()       const { return m_coreInfo.PriceOpen(); }
    double PriceCurrent()    const { return m_coreInfo.PriceCurrent(); }
    double StopLoss()        const { return m_coreInfo.StopLoss(); }
    double TakeProfit()      const { return m_coreInfo.TakeProfit(); }
    double Volume()          const { return m_coreInfo.Volume(); }
    double Profit()          const { return m_coreInfo.Profit(); }
    double Swap()            const { return m_coreInfo.Swap(); }
    double Commission()      const { return m_coreInfo.Commission(); }
    string Symbol()          const { return m_coreInfo.Symbol(); }
    string Comment()         const { return m_coreInfo.Comment(); }
    // Thêm các hàm helper khác nếu cần...

    // Phương thức để sao chép dữ liệu từ một đối tượng PositionInfoExt khác
    // (Giữ lại logic sao chép các trường mở rộng, m_coreInfo tự quản lý việc sao chép của nó nếu cần thiết
    // hoặc chúng ta có thể sao chép tường minh các thuộc tính của m_coreInfo nếu không có hàm Copy trực tiếp)
    bool Copy(const PositionInfoExt &source) {
        // Sao chép các trường của CPositionInfo nếu không có hàm copy trực tiếp
        // Hoặc nếu CPositionInfo có hàm SelectByTicket, có thể dùng nó
        // Tuy nhiên, cách an toàn là sao chép từng trường nếu không chắc chắn
        // Giả sử chúng ta cần sao chép thủ công các trường quan trọng từ m_coreInfo của source
        // Điều này không lý tưởng, CPositionInfo nên có cơ chế sao chép riêng
        // Nếu không, chúng ta chỉ có thể sao chép các trường mở rộng
        // và giả định m_coreInfo được xử lý riêng (ví dụ: SelectByTicket sau đó)

        // Sao chép dữ liệu từ các trường mở rộng
        state = source.state;
        scenario = source.scenario;
        entryStrategy = source.entryStrategy;
        
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

        // QUAN TRỌNG: Xử lý sao chép cho m_coreInfo
        // Cách 1: Nếu CPositionInfo có hàm Copy hoặc toán tử gán được định nghĩa tốt
        // this.m_coreInfo = source.m_coreInfo; 
        // Cách 2: Select lại ticket nếu có thể (không phải lúc nào cũng đúng ngữ cảnh)
        // if (source.Ticket() > 0) this.SelectByTicket(source.Ticket());
        // Cách 3: Sao chép thủ công các trường của CPositionInfo (ít mong muốn nhất)
        // Ví dụ:
        // this.m_coreInfo.Ticket(source.m_coreInfo.Ticket()); // Giả sử CPositionInfo có setter, điều này không chuẩn
        // Do CPositionInfo là lớp chuẩn, nó không có setter. Chúng ta không thể gán trực tiếp các trường private.
        // => Cách tốt nhất là dựa vào việc SelectByTicket() sau khi tạo đối tượng mới, hoặc nếu CPositionInfo
        // được thiết kế để sao chép (ví dụ qua constructor sao chép hoặc hàm Clone() nào đó).
        // Vì user_input không nói rõ về CPositionInfo, tôi sẽ để trống phần này và giả định người dùng
        // sẽ xử lý việc sao chép/khởi tạo m_coreInfo một cách phù hợp bên ngoài hàm Copy này nếu cần.
        // Hoặc, nếu mục đích của Copy là tạo một bản sao hoàn chỉnh, thì cần đảm bảo m_coreInfo cũng được sao chép.
        // Một cách đơn giản là nếu source.Ticket() có giá trị, thì this cũng select ticket đó.
        if (source.Ticket() > 0) {
             // Cố gắng lấy thông tin mới nhất cho ticket đó
             // Tuy nhiên, điều này có thể không phải là một "bản sao" chính xác nếu trạng thái vị thế đã thay đổi
             this.m_coreInfo.SelectByTicket(source.Ticket());
        } else {
            // Nếu source không có ticket, có thể m_coreInfo của this cũng nên được reset
            // Hoặc giữ nguyên trạng thái hiện tại của this.m_coreInfo
        }

        return true;
    }

    // Xóa các hàm SyncFields và SyncReferences vì chúng không còn phù hợp
    // với mô hình bao bọc (wrapping)

    // Các hàm còn lại của file gốc (nếu có) sẽ ở dưới đây
    // ...
}; // Kết thúc struct PositionInfoExt

// Định nghĩa xung đột đã được loại bỏ - chỉ giữ lại phiên bản wrapping ở trên

} // namespace ApexPullback

#endif // POSITIONINFOEXT_MQH_ // POSITIONINFOEXT_MQH
