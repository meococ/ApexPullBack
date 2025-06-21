//+------------------------------------------------------------------+
//|                                               FunctionStack.mqh |
//|      APEX Pullback EA v14.0 - Hệ thống theo dõi ngăn xếp hàm      |
//+------------------------------------------------------------------+

#ifndef FUNCTION_STACK_MQH_
#define FUNCTION_STACK_MQH_

#include <Arrays\ArrayString.mqh> // Cần cho CArrayString
// #include "Logger.mqh" // Đã xóa để phá vỡ phụ thuộc vòng
#include "CommonDefinitions.mqh" // Cho các TAG

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {

class CLogger; // Khai báo tiền định để phá vỡ phụ thuộc vòng

// Các hằng số cho FunctionStack
#define MAX_STACK_DEPTH      50    // Giới hạn độ sâu tối đa của stack
#define STACK_WARNING_LEVEL  45    // Mức cảnh báo khi stack gần đạt giới hạn

//+------------------------------------------------------------------+
//| Lớp CFunctionStack - Mô phỏng Stack Trace để gỡ lỗi             |
//+------------------------------------------------------------------+
class CFunctionStack {
private:
   CArrayString*  m_stack;
   int            m_max_size;
   CLogger*       m_logger;    // Logger để ghi nhận cảnh báo

public:
   // Constructor và Destructor
   CFunctionStack(CLogger* logger, int max_size = MAX_STACK_DEPTH);
   ~CFunctionStack();

   // Phương thức chính
   void  Push(const string function_name);
   void  Pop();
   void  Clear();
   string GetTraceAsString(const string separator = " -> ") const;
   int   GetSize() const;
};

//+------------------------------------------------------------------+
//| Constructor
//+------------------------------------------------------------------+
CFunctionStack::CFunctionStack(CLogger* logger, int max_size = MAX_STACK_DEPTH) {
   m_stack = new CArrayString();
   m_max_size = max_size;
   m_logger = logger; // Logger được truyền vào qua dependency injection
}

//+------------------------------------------------------------------+
//| Destructor
//+------------------------------------------------------------------+
CFunctionStack::~CFunctionStack() {
   if(CheckPointer(m_stack) == POINTER_DYNAMIC) {
      delete m_stack;
   }
}

//+------------------------------------------------------------------+
//| Thêm một hàm vào đỉnh của ngăn xếp
//+------------------------------------------------------------------+
void CFunctionStack::Push(const string function_name) {
   if(CheckPointer(m_stack) == POINTER_INVALID)
      return;

   int current_size = m_stack.Total();

   // Kiểm tra và cảnh báo khi gần đạt giới hạn
   if(current_size >= STACK_WARNING_LEVEL && current_size < m_max_size) {
      if(CheckPointer(m_logger) != POINTER_INVALID) {
         m_logger->LogWarning(StringFormat("Stack depth warning: %d/%d functions",
                             current_size, m_max_size),
                             TAG_WARNING_ALERT);
      }
   }

   // Kiểm tra giới hạn stack
   if(current_size >= m_max_size) {
      if(CheckPointer(m_logger) != POINTER_INVALID) {
         m_logger->LogError(StringFormat("Stack overflow prevented! Depth: %d/%d. Trace: %s",
                           current_size, m_max_size, GetTraceAsString()),
                           TAG_CRITICAL_ALERT);
      }
      return; // Ngăn chặn tràn stack
   }

   m_stack.Add(function_name);
}

//+------------------------------------------------------------------+
//| Xóa một hàm khỏi đỉnh của ngăn xếp
//+------------------------------------------------------------------+
void CFunctionStack::Pop() {
   if(CheckPointer(m_stack) == POINTER_INVALID || m_stack.Total() == 0)
      return;
   m_stack.Delete(m_stack.Total() - 1);
}

//+------------------------------------------------------------------+
//| Xóa toàn bộ ngăn xếp
//+------------------------------------------------------------------+
void CFunctionStack::Clear() {
   if(CheckPointer(m_stack) == POINTER_INVALID)
      return;
   m_stack.Clear();
}

//+------------------------------------------------------------------+
//| Lấy toàn bộ dấu vết ngăn xếp dưới dạng một chuỗi
//+------------------------------------------------------------------+
string CFunctionStack::GetTraceAsString(const string separator = " -> ") const {
   if(CheckPointer(m_stack) == POINTER_INVALID || m_stack.Total() == 0)
      return "";

   string trace = "";
   for(int i = 0; i < m_stack.Total(); i++) {
      if(i > 0)
         trace += separator;
      trace += m_stack.At(i);
   }
   return trace;
}

//+------------------------------------------------------------------+
//| Lấy kích thước hiện tại của ngăn xếp
//+------------------------------------------------------------------+
int CFunctionStack::GetSize() const {
    if(CheckPointer(m_stack) == POINTER_INVALID) return 0;
    return m_stack.Total();
}

} // end namespace ApexPullback
#endif // FUNCTION_STACK_MQH_