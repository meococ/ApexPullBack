//+------------------------------------------------------------------+
//|                                                     Logger.mqh |
//|              APEX Pullback EA v14.0 - Hệ thống ghi nhật ký      |
//+------------------------------------------------------------------+

#ifndef LOGGER_MQH
#define LOGGER_MQH

#include <Files\FileTxt.mqh>
#include "Enums.mqh"

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

// Sử dụng ENUM_LOG_LEVEL từ Enums.mqh
// Bảng tương ứng giữa LOG_LEVEL cũ và mới (các hằng để tương thích ngược)
#define LOG_LEVEL_ERROR   LOG_ERROR
#define LOG_LEVEL_WARNING LOG_WARNING
#define LOG_LEVEL_INFO    LOG_INFO
#define LOG_LEVEL_DEBUG   LOG_DEBUG

//+------------------------------------------------------------------+
//| Lớp CLogger - Quản lý ghi log chuyên nghiệp cho EA              |
//+------------------------------------------------------------------+
class CLogger {
private:
   // Biến thành viên 
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
   void           FormatLogMessage(string &formatted_message, string level, string message);
   void           WriteToFile(string message);
   bool           SendTelegramMessage(string message, bool important = false);

public:
   // Constructor và Destructor
   CLogger();
   ~CLogger();
   
   // Phương thức khởi tạo
   bool           Initialize(string prefix, bool enableDetailedLogs = false, 
                           bool enableCsvLog = false, string csvFileName = "LogFile.csv",
                           bool enableTelegram = false, string telegramToken = "", 
                           string telegramChatId = "", bool importantOnly = true);
   void           Deinitialize();
   
   // Phương thức ghi log theo cấp độ
   void           LogDebug(string message);   // Thông tin gỡ lỗi chi tiết
   void           LogInfo(string message);    // Thông tin hoạt động bình thường
   void           LogWarning(string message); // Cảnh báo, có thể cần chú ý
   void           LogError(string message);   // Lỗi nghiêm trọng
   
   // Phương thức tiện ích
   bool           IsInitialized() { return m_is_initialized; }
   string         GetPrefix() { return m_prefix; }
   string         GetLogFileName() { return m_log_file_name; }
   
   // Phương thức truy vấn và thiết lập cấu hình
   void           SetLogLevel(ENUM_LOG_LEVEL log_level);
   ENUM_LOG_LEVEL GetLogLevel() { return (ENUM_LOG_LEVEL)m_log_level; }
   void           SetLogOutput(ENUM_LOG_OUTPUT log_output);
   ENUM_LOG_OUTPUT GetLogOutput() { return m_log_output; }
   
   // Phương thức kiểm tra cấp độ log
   bool           IsDebugEnabled() { return m_log_level >= LOG_DEBUG; }
   bool           IsInfoEnabled() { return m_log_level >= LOG_INFO; }
   bool           IsWarningEnabled() { return m_log_level >= LOG_WARNING; }
   bool           IsErrorEnabled() { return m_log_level >= LOG_ERROR; }
   bool           IsVerboseEnabled() { return m_log_level >= LOG_VERBOSE; }
   
   // Phương thức thông báo Telegram
   bool           EnableTelegram(string token, string chatId, bool importantOnly = true);
   void           DisableTelegram();
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo giá trị mặc định                          |
//+------------------------------------------------------------------+
CLogger::CLogger() {
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
void CLogger::LogDebug(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_DEBUG && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "DEBUG", message);
      
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
void CLogger::LogInfo(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_INFO && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "INFO", message);
      
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
void CLogger::LogWarning(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_WARNING && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "WARNING", message);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
         
      // Gửi thông báo qua Telegram nếu được cấu hình (cảnh báo luôn được coi là quan trọng)
      if(m_enable_telegram)
         SendTelegramMessage(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ ERROR - Lỗi nghiêm trọng                       |
//+------------------------------------------------------------------+
void CLogger::LogError(string message) {
   // Lỗi luôn được ghi log bất kể cấp độ log nếu đã khởi tạo
   if(m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "ERROR", message);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
         
      // Gửi thông báo qua Telegram nếu được cấu hình (lỗi luôn được coi là quan trọng)
      if(m_enable_telegram)
         SendTelegramMessage(formatted_message);
   } else {
      // Nếu logger chưa khởi tạo, vẫn hiển thị lỗi trên màn hình
      Print("[ERROR] " + message);
   }
}

//+------------------------------------------------------------------+
//| Định dạng thông điệp log với thời gian và các thông tin khác     |
//+------------------------------------------------------------------+
void CLogger::FormatLogMessage(string &formatted_message, string level, string message) {
   // Định dạng: [YYYY.MM.DD HH:MM:SS] [SYMBOL] [LEVEL] Message
   formatted_message = "[" + TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + "] ";
   formatted_message += "[" + m_symbol + "] ";
   formatted_message += "[" + level + "] ";
   formatted_message += message;
}

//+------------------------------------------------------------------+
//| Ghi log vào file                                                 |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(string message) {
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
bool CLogger::SendTelegramMessage(string message, bool important = false) {
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
void CLogger::SetLogLevel(ENUM_LOG_LEVEL log_level) {
   m_log_level = log_level;
   if(m_is_initialized) {
      LogInfo("Đã thay đổi cấp độ log thành: " + EnumToString(log_level));
   }
}

//+------------------------------------------------------------------+
//| Thiết lập đầu ra log                                             |
//+------------------------------------------------------------------+
void CLogger::SetLogOutput(ENUM_LOG_OUTPUT log_output) {
   m_log_output = log_output;
   if(m_is_initialized) {
      LogInfo("Đã thay đổi đầu ra log thành: " + EnumToString(log_output));
   }
}

} // end namespace ApexPullback
#endif // LOGGER_MQH
