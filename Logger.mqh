//+------------------------------------------------------------------+
//|                                                     Logger.mqh |
//|              APEX Pullback EA v14.0 - Hệ thống ghi nhật ký      |
//+------------------------------------------------------------------+

#ifndef LOGGER_MQH_
#define LOGGER_MQH_



// === CORE INCLUDES (BẮT BUỘC CHO HẦU HẾT CÁC FILE) ===
#include "Enums.mqh"            // TẤT CẢ các enum
#include "CommonStructs.mqh"      // Core structures, enums, and inputs

// === INCLUDES CỤ THỂ (NẾU CẦN) ===
// #include "MathHelper.mqh"

// BẮT ĐẦU NAMESPACE
namespace ApexPullback {
//+------------------------------------------------------------------+
//| Enum và cấu trúc hỗ trợ                                          |
//+------------------------------------------------------------------+

// Định nghĩa đầu ra của log - Nơi ghi nhật ký
enum ENUM_LOG_OUTPUT
{
   LOG_OUTPUT_PRINT = 0,    // Chỉ hiển thị trong cửa sổ "Experts" của MT5
   LOG_OUTPUT_FILE = 1,     // Chỉ ghi vào file (không hiển thị trên màn hình)
   LOG_OUTPUT_BOTH = 2      // Hiển thị trên màn hình và ghi vào file
};

// ENUM_LOG_LEVEL is now directly used from Enums.mqh
// Removed redundant #define statements for LOG_LEVEL_ERROR, LOG_LEVEL_WARNING, etc.
// as they are now directly available via ENUM_LOG_LEVEL from Enums.mqh

//+------------------------------------------------------------------+
//| Lớp CLogger - Quản lý ghi log chuyên nghiệp cho EA              |
//+------------------------------------------------------------------+
class CLogger {
private:
   // Biến thành viên 
   EAContext*     m_context;          // Con trỏ đến context của EA để truy cập các module khác
   string         m_symbol;           // Cặp tiền tệ hiện tại
   string         m_prefix;           // Tiền tố nhận dạng EA trong log
   int            m_log_level;        // Cấp độ log (xem ENUM_LOG_LEVEL)
   ENUM_LOG_OUTPUT m_log_output;      // Nơi xuất log (xem ENUM_LOG_OUTPUT)
   string         m_log_file_name;    // Tên file log đầy đủ
   int            m_log_file_handle;  // Handle quản lý file log
   bool           m_is_initialized;   // Trạng thái khởi tạo của logger
   bool           m_enable_telegram;  // Bật/tắt gửi log qua Telegram
   string         m_telegram_token;   // Token bot Telegram
   string         m_telegram_chat_id; // Chat ID nhận thông báo Telegram
   bool           m_important_only;   // Chỉ gửi thông báo quan trọng đến Telegram
   
   // Phương thức private
   void           FormatLogMessage(string &formatted_message, const string level, const string message, const string tags) const;
   void           WriteToFile(const string message) const;
   bool           SendTelegramMessage(const string message, bool important = false) const;

public:
   // Constructor và Destructor
   CLogger(EAContext* context = NULL);
   ~CLogger();
   
   // Phương thức khởi tạo
   bool           Initialize(string prefix, bool enableDetailedLogs = false, 
                           bool enableCsvLog = false, string csvFileName = "LogFile.csv",
                           bool enableTelegram = false, string telegramToken = "", 
                           string telegramChatId = "", bool importantOnly = true);
   void           Deinitialize();
   
   // Phương thức ghi log theo cấp độ
   void           LogDebug(const string message, const string tags = "") const;   // Thông tin gỡ lỗi chi tiết
   void           LogInfo(const string message, const string tags = "") const;    // Thông tin hoạt động bình thường
   void           LogWarning(const string message, const string tags = "") const; // Cảnh báo, có thể cần chú ý
   void           LogError(const string message, const string tags = "") const;
   void           LogError(const string message, bool include_stack_trace, const string tags = "") const; // Lỗi nghiêm trọng với stack trace
   
   // Phương thức tiện ích
   bool           IsInitialized() const { return m_is_initialized; }
   string         GetPrefix() const { return m_prefix; }
   string         GetLogFileName() const { return m_log_file_name; }
   void           GenerateDailySummary();
   
   // Phương thức truy vấn và thiết lập cấu hình
   void           SetLogLevel(const ENUM_LOG_LEVEL log_level);
   ENUM_LOG_LEVEL GetLogLevel() const { return (ENUM_LOG_LEVEL)m_log_level; }
   void           SetLogOutput(const ENUM_LOG_OUTPUT log_output);
   ENUM_LOG_OUTPUT GetLogOutput() const { return m_log_output; }
   
   // Phương thức kiểm tra cấp độ log
   bool           IsDebugEnabled() const { return m_log_level >= LOG_DEBUG; }
   bool           IsInfoEnabled() const { return m_log_level >= LOG_INFO; }
   bool           IsWarningEnabled() const { return m_log_level >= LOG_WARNING; }
   bool           IsErrorEnabled() const { return m_log_level >= LOG_ERROR; }
   bool           IsVerboseEnabled() const { return m_log_level >= LOG_VERBOSE; }
   
   // Phương thức thông báo Telegram
   bool           EnableTelegram(string token, string chatId, bool importantOnly = true);
   void           DisableTelegram();
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo giá trị mặc định                          |
//+------------------------------------------------------------------+
CLogger::CLogger(EAContext* context = NULL) {
    m_context = context;
    m_symbol = Symbol();
    m_prefix = "ApexPullback";
    m_log_level = LOG_INFO;     // Mặc định: Chỉ log thông tin bình thường
    m_log_output = LOG_OUTPUT_PRINT; // Mặc định: Chỉ hiển thị trên màn hình
    m_log_file_name = "";
    m_log_file_handle = INVALID_HANDLE;
    m_is_initialized = false;
    m_enable_telegram = false;
    m_telegram_token = "";
    m_telegram_chat_id = "";
    m_important_only = true;
}

//+------------------------------------------------------------------+
//| Destructor - Dọn dẹp trước khi hủy đối tượng                     |
//+------------------------------------------------------------------+
CLogger::~CLogger() {
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize - Khởi tạo đối tượng logger với các tham số mở rộng   |
//+------------------------------------------------------------------+
bool CLogger::Initialize(string prefix, bool enableDetailedLogs = false, 
                       bool enableCsvLog = false, string csvFileName = "LogFile.csv",
                       bool enableTelegram = false, string telegramToken = "", 
                       string telegramChatId = "", bool importantOnly = true) {
    // Đặt tiền tố cho logger
    if (prefix != "") m_prefix = prefix;
    
    // Thiết lập cấp độ log
    m_log_level = enableDetailedLogs ? LOG_DEBUG : LOG_INFO;
    
    // Cấu hình file log nếu cần
    if (enableCsvLog) {
        m_log_output = LOG_OUTPUT_BOTH;
        
        // Nếu không có tên file được chỉ định, tạo tên mặc định theo định dạng
        if(csvFileName == "LogFile.csv") {
            // Tạo tên file log theo định dạng: Prefix_Symbol_YYYYMMDD.log
            m_log_file_name = m_prefix + "_" + m_symbol + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
        } else {
            // Sử dụng tên file được chỉ định
            m_log_file_name = csvFileName;
        }
        
        // Kiểm tra tên file và thêm đuôi .log nếu cần
        if(StringFind(m_log_file_name, ".log") < 0 && StringFind(m_log_file_name, ".csv") < 0) {
            m_log_file_name = m_log_file_name + ".log";
        }
        
        // Mở file log (tạo mới hoặc thêm vào file hiện có)
        m_log_file_handle = FileOpen(m_log_file_name, FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON);
        
        // Kiểm tra nếu không mở được file
        if(m_log_file_handle == INVALID_HANDLE) {
            // Ghi log lỗi khi không mở được file
            m_log_output = LOG_OUTPUT_PRINT; // Chuyển sang chế độ chỉ in ra màn hình
            Print("LOGGER ERROR: Không thể mở file log: ", m_log_file_name, ", error: ", IntegerToString(GetLastError()));
            return false;
        }
        
        // Di chuyển con trỏ đến cuối file
        FileSeek(m_log_file_handle, 0, SEEK_END);
    }
    
    // Cấu hình Telegram nếu cần
    if (enableTelegram && telegramToken != "" && telegramChatId != "") {
        EnableTelegram(telegramToken, telegramChatId, importantOnly);
    }
    
    // Đánh dấu đã khởi tạo
    m_is_initialized = true;
    
    // Ghi log thông báo khởi tạo thành công
    LogInfo("APEX Pullback EA v14.0 Logger được khởi tạo thành công.");
    return m_is_initialized;
}

//+------------------------------------------------------------------+
//| Giải phóng tài nguyên khi kết thúc EA hoặc Logger               |
//+------------------------------------------------------------------+
void CLogger::Deinitialize() {
   // Nếu chưa khởi tạo thì không làm gì
   if(!m_is_initialized)
      return;
      
   // Ghi log thông báo kết thúc
   LogInfo("Logger đang kết thúc...");
   
   // Đóng file log nếu đang mở
   if(m_log_file_handle != INVALID_HANDLE) {
      FileClose(m_log_file_handle);
      m_log_file_handle = INVALID_HANDLE;
   }
   
   // Đánh dấu chưa khởi tạo
   m_is_initialized = false;
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ DEBUG - Thông tin chi tiết cho gỡ lỗi           |
//+------------------------------------------------------------------+
void CLogger::LogDebug(const string message, const string tags = "") const {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_DEBUG && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "DEBUG", message, tags);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ INFO - Thông tin chung                         |
//+------------------------------------------------------------------+
void CLogger::LogInfo(const string message, const string tags = "") const {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_INFO && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "INFO", message, tags);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
         
      // Gửi thông báo qua Telegram nếu được cấu hình và không chỉ thông báo quan trọng
      if(m_enable_telegram && !m_important_only)
         SendTelegramMessage(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ WARNING - Cảnh báo                             |
//+------------------------------------------------------------------+
void CLogger::LogWarning(const string message, const string tags = "") const {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_WARNING && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "WARNING", message, tags);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
         
      // Gửi thông báo qua Telegram nếu được cấu hình (cảnh báo luôn được coi là quan trọng)
      if(m_enable_telegram)
         SendTelegramMessage(formatted_message, true);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ ERROR - Lỗi nghiêm trọng                       |
//+------------------------------------------------------------------+
void CLogger::LogError(const string message, const string tags = "") const {
   // Gọi phiên bản đầy đủ với include_stack_trace = false
   LogError(message, false, tags);
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ ERROR với tùy chọn Stack Trace                 |
//+------------------------------------------------------------------+
void CLogger::LogError(const string message, bool include_stack_trace, const string tags = "") const {
   // Lỗi luôn được ghi log bất kể cấp độ log nếu đã khởi tạo
   if(m_is_initialized) {
      string final_message = message;

      // Thêm stack trace nếu được yêu cầu và context hợp lệ
      if (include_stack_trace && m_context != NULL) {
         // Tạo một biến con trỏ trung gian để làm rõ kiểu dữ liệu cho trình biên dịch
         // Vì hàm này là const, m_context là const, nên con trỏ lấy ra cũng phải là const
         const ApexPullback::CFunctionStack* functionStackPtr = m_context->FunctionStack;
         if(functionStackPtr != NULL)
         {
            const string stack_trace = functionStackPtr->GetTraceAsString();
            if (stack_trace != "") { // MQL5 không có .empty(), dùng so sánh chuỗi
               final_message += "\n--- STACK TRACE ---\n" + stack_trace;
            }
         }
      }

      string formatted_message;
      FormatLogMessage(formatted_message, "ERROR", final_message, tags);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
         
      // Gửi thông báo qua Telegram nếu được cấu hình (lỗi luôn được coi là quan trọng)
      if(m_enable_telegram)
         SendTelegramMessage(formatted_message, true);
   } else {
      // Nếu logger chưa khởi tạo, vẫn hiển thị lỗi trên màn hình
      Print("[ERROR] [" + m_symbol + "] " + message);
   }
}

//+------------------------------------------------------------------+
//| Định dạng thông điệp log với thời gian và các thông tin khác     |
//+------------------------------------------------------------------+
void CLogger::FormatLogMessage(string &formatted_message, const string level, const string message, const string tags) const {
   // Định dạng: [YYYY.MM.DD HH:MM:SS] [SYMBOL] [LEVEL] [TAGS] Message
   formatted_message = "[" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "] ";
   formatted_message += "[" + m_symbol + "] ";
   formatted_message += "[" + level + "]";
   if(tags != "") {
      formatted_message += " [" + tags + "]";
   }
   formatted_message += " " + message;
}

//+------------------------------------------------------------------+
//| Ghi log vào file                                                 |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(const string message) const {
   // Nếu handle file hợp lệ thì ghi vào file
   if(m_log_file_handle != INVALID_HANDLE) {
      // Thêm ký tự xuống dòng và ghi vào file
      FileWriteString(m_log_file_handle, message + "\n");
      FileFlush(m_log_file_handle); // Đảm bảo nội dung được ghi ngay lập tức
   }
}

//+------------------------------------------------------------------+
//| Gửi thông báo qua Telegram                                       |
//+------------------------------------------------------------------+
bool CLogger::SendTelegramMessage(const string message, bool important = false) const {
   // Chỉ gửi nếu Telegram được kích hoạt
   if(!m_enable_telegram || m_telegram_token == "" || m_telegram_chat_id == "")
      return false;
   
   // Nếu chỉ gửi tin quan trọng và tin này không quan trọng thì bỏ qua
   if(m_important_only && !important)
      return false;
   
   // Xây dựng URL API Telegram
   string url = "https://api.telegram.org/bot" + m_telegram_token + "/sendMessage";
   string params = "chat_id=" + m_telegram_chat_id + "&text=" + message;
   
   // Khởi tạo WebRequest
   char post[], result[];
   StringToCharArray(params, post);
   
   // Gọi WebRequest
   string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
   int timeout = 5000; // 5 giây timeout
   string response_headers;
   int res = WebRequest("POST", url, headers, timeout, post, result, response_headers);
   
   // Kiểm tra kết quả
   if(res == -1) {
      int error = GetLastError();
      LogError("Lỗi gửi thông báo Telegram: " + IntegerToString(error));
      return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Bật thông báo Telegram với cài đặt chỉ định                      |
//+------------------------------------------------------------------+
bool CLogger::EnableTelegram(string token, string chatId, bool importantOnly = true) {
   if(token == "" || chatId == "") {
      LogError("Token hoặc Chat ID Telegram không hợp lệ");
      return false;
   }
   
   m_enable_telegram = true;
   m_telegram_token = token;
   m_telegram_chat_id = chatId;
   m_important_only = importantOnly;
   
   LogInfo("Đã bật thông báo Telegram" + (importantOnly ? " (chỉ thông báo quan trọng)" : ""));
   return true;
}

//+------------------------------------------------------------------+
//| Tắt thông báo Telegram                                           |
//+------------------------------------------------------------------+
void CLogger::DisableTelegram() {
   m_enable_telegram = false;
   LogInfo("Đã tắt thông báo Telegram");
}

//+------------------------------------------------------------------+
//| Thiết lập cấp độ log                                             |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(const ENUM_LOG_LEVEL log_level) {
   m_log_level = log_level;
   if(m_is_initialized) {
      LogInfo("Đã thay đổi cấp độ log thành: " + EnumToString(log_level));
   }
}

//+------------------------------------------------------------------+
//| Thiết lập đầu ra log                                             |
//+------------------------------------------------------------------+
void CLogger::SetLogOutput(const ENUM_LOG_OUTPUT log_output) {
   m_log_output = log_output;
   if(m_is_initialized) {
      LogInfo("Đã thay đổi đầu ra log thành: " + EnumToString(log_output));
   }
}

//+------------------------------------------------------------------+
//| Cấu trúc để lưu trữ số liệu thống kê tóm tắt từ log              |
//+------------------------------------------------------------------+
struct LogSummaryStats {
   int total_errors;
   int total_warnings;
   // Thêm các số liệu khác nếu cần, ví dụ: số lượng giao dịch, P/L...

   void Initialize() {
      total_errors = 0;
      total_warnings = 0;
   }
};

// Prototype for the helper function to be defined later
bool ParseLogFileForSummary(const string file_path, LogSummaryStats &stats, CLogger* logger_instance);

//+------------------------------------------------------------------+
//| Tạo và gửi báo cáo tóm tắt hàng ngày qua Telegram               |
//+------------------------------------------------------------------+
void CLogger::GenerateDailySummary() {
   if(!m_is_initialized || !m_enable_telegram) {
      // LogInfo("Không thể tạo báo cáo tóm tắt: Logger chưa được khởi tạo hoặc Telegram bị vô hiệu hóa.", "Logger,Summary");
      return;
   }

   string log_path = GetLogFileName();
   LogSummaryStats stats;

   // The method is no longer const, so 'this' is a non-const pointer.
   CLogger* non_const_this = this;

   if(ParseLogFileForSummary(log_path, stats, non_const_this)) {
      // Tạo thông điệp tóm tắt
      string summary_message = "\n--- BÁO CÁO HÀNG NGÀY ---";
      summary_message += "\nEA: " + m_prefix;
      summary_message += "\nSymbol: " + m_symbol;
      summary_message += "\nNgày: " + TimeToString(TimeCurrent(), TIME_DATE);
      summary_message += "\n--------------------------";
      summary_message += "\n- Tổng số Lỗi: " + (string)stats.total_errors;
      summary_message += "\n- Tổng số Cảnh báo: " + (string)stats.total_warnings;
      summary_message += "\n--------------------------";
      summary_message += "\nChúc một ngày giao dịch tốt lành!";

      // Gửi qua Telegram. Báo cáo luôn được coi là quan trọng.
      SendTelegramMessage(summary_message, true);
      LogInfo("Đã gửi báo cáo tóm tắt hàng ngày qua Telegram.", "Logger,Summary");
   } else {
      LogError("Không thể tạo báo cáo tóm tắt hàng ngày do không đọc được file log.", "Logger,Summary,Critical");
   }
}

//+------------------------------------------------------------------+
//| Phân tích file log của ngày để thu thập số liệu thống kê         |
//+------------------------------------------------------------------+
bool ParseLogFileForSummary(const string file_path, LogSummaryStats &stats, CLogger* logger_instance) {
   stats.Initialize();
   
   // Reset lỗi cuối cùng
   ResetLastError();
   
   // Mở file để đọc
   int file_handle = FileOpen(file_path, FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON);
   if(file_handle == INVALID_HANDLE) {
      // Không thể LogError ở đây vì sẽ tạo vòng lặp vô hạn nếu file log có vấn đề
      PrintFormat("ParseLogFileForSummary - Không thể mở file log '%s'. Lỗi: %d", file_path, GetLastError());
      return false;
   }

   // Đọc từng dòng
   while(!FileIsEnding(file_handle)) {
      string line = FileReadString(file_handle);
      
      // Đếm lỗi và cảnh báo
      if(StringFind(line, "[ERROR]") != -1) {
         stats.total_errors++;
      }
      if(StringFind(line, "[WARNING]") != -1) {
         stats.total_warnings++;
      }
      // TODO: Thêm logic để phân tích các thông tin khác như giao dịch, P/L từ các thẻ (tags)
   }

   FileClose(file_handle);
   return true;
}

} // end namespace ApexPullback
#endif // LOGGER_MQH_
