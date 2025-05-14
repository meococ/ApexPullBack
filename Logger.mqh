//+------------------------------------------------------------------+
//|                                                     Logger.mqh |
//|              APEX Pullback EA v14.0 - Hệ thống ghi nhật ký      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, APEX Forex Systems"
#property link      "https://www.apexpullback.com"
#property version   "14.0"
#property strict

//+------------------------------------------------------------------+
//| Enum và cấu trúc hỗ trợ                                          |
//+------------------------------------------------------------------+

// Định nghĩa các cấp độ log - Kiểm soát lượng thông tin được ghi lại
enum ENUM_LOG_LEVEL {
   LOG_LEVEL_ERROR = 0,    // Chỉ ghi log lỗi nghiêm trọng
   LOG_LEVEL_WARNING = 1,  // Ghi lỗi và cảnh báo
   LOG_LEVEL_INFO = 2,     // Ghi lỗi, cảnh báo và thông tin chung
   LOG_LEVEL_DEBUG = 3     // Ghi tất cả, bao gồm thông tin gỡ lỗi chi tiết
};

// Định nghĩa đầu ra của log - Nơi ghi nhật ký
enum ENUM_LOG_OUTPUT {
   LOG_OUTPUT_PRINT = 0,    // Chỉ hiển thị trong cửa sổ "Experts" của MT5
   LOG_OUTPUT_FILE = 1,     // Chỉ ghi vào file (không hiển thị trên màn hình)
   LOG_OUTPUT_BOTH = 2      // Hiển thị trên màn hình và ghi vào file
};

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
   bool           SendTelegramMessage(string message);

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
   
   // Phương thức thông báo Telegram
   bool           EnableTelegram(string token, string chatId, bool importantOnly = true);
   void           DisableTelegram();
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo giá trị mặc định                          |
//+------------------------------------------------------------------+
CLogger::CLogger() {
   // Khởi tạo các biến thành viên với giá trị mặc định
   m_symbol = _Symbol;
   m_prefix = "APEX";
   m_log_level = LOG_LEVEL_INFO;
   m_log_output = LOG_OUTPUT_PRINT;
   m_log_file_name = "";
   m_log_file_handle = INVALID_HANDLE;
   m_is_initialized = false;
   m_enable_telegram = false;
   m_telegram_token = "";
   m_telegram_chat_id = "";
   m_important_only = true;
}

//+------------------------------------------------------------------+
//| Destructor - Đảm bảo giải phóng tài nguyên                       |
//+------------------------------------------------------------------+
CLogger::~CLogger() {
   // Đảm bảo dọn dẹp tài nguyên khi đối tượng bị hủy
   Deinitialize();
}

//+------------------------------------------------------------------+
//| Khởi tạo Logger với các tham số cơ bản và nâng cao              |
//+------------------------------------------------------------------+
bool CLogger::Initialize(string prefix, bool enableDetailedLogs = false, 
                       bool enableCsvLog = false, string csvFileName = "LogFile.csv",
                       bool enableTelegram = false, string telegramToken = "", 
                       string telegramChatId = "", bool importantOnly = true) {
   // Nếu đã khởi tạo thì không làm gì
   if(m_is_initialized)
      return true;
      
   // Lưu thông tin cơ bản
   m_symbol = _Symbol;
   m_prefix = prefix;
   m_log_level = enableDetailedLogs ? LOG_LEVEL_DEBUG : LOG_LEVEL_INFO;
   m_log_output = enableCsvLog ? LOG_OUTPUT_BOTH : LOG_OUTPUT_PRINT;
   
   // Thiết lập Telegram nếu được kích hoạt
   m_enable_telegram = enableTelegram;
   m_telegram_token = telegramToken;
   m_telegram_chat_id = telegramChatId;
   m_important_only = importantOnly;
   
   // Tạo tên file log nếu cần
   if(enableCsvLog) {
      // Nếu không có tên file được chỉ định, tạo tên mặc định theo định dạng
      if(csvFileName == "LogFile.csv") {
         // Tạo tên file log theo định dạng: Prefix_Symbol_YYYYMMDD.log
         m_log_file_name = m_prefix + "_" + m_symbol + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
Print("File handle: ", IntegerToString(m_log_file_handle));
LogError("Lỗi: " + IntegerToString(GetLastError()));
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
   
   // Đánh dấu đã khởi tạo
   m_is_initialized = true;
   
   // Ghi log thông báo khởi tạo thành công
   LogInfo("APEX Pullback EA v14.0 Logger được khởi tạo thành công.");
   return true;
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
bool CLogger::SendTelegramMessage(string message) {
   // Chỉ gửi nếu Telegram được kích hoạt
   if(!m_enable_telegram || m_telegram_token == "" || m_telegram_chat_id == "")
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
//| Ghi log ở cấp độ DEBUG - Thông tin chi tiết cho gỡ lỗi           |
//+------------------------------------------------------------------+
void CLogger::LogDebug(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_LEVEL_DEBUG && m_is_initialized) {
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
//| Ghi log ở cấp độ INFO - Thông tin hoạt động bình thường          |
//+------------------------------------------------------------------+
void CLogger::LogInfo(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_LEVEL_INFO && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "INFO", message);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
      
      // Gửi thông báo Telegram nếu được cấu hình
      if(m_enable_telegram && !m_important_only)
         SendTelegramMessage(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ WARNING - Cảnh báo người dùng vấn đề tiềm ẩn    |
//+------------------------------------------------------------------+
void CLogger::LogWarning(string message) {
   // Chỉ ghi log nếu cấp độ log hiện tại cho phép
   if(m_log_level >= LOG_LEVEL_WARNING && m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "WARNING", message);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
      
      // Gửi thông báo Telegram nếu được cấu hình
      if(m_enable_telegram && !m_important_only)
         SendTelegramMessage(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ ERROR - Lỗi nghiêm trọng cần xử lý ngay         |
//+------------------------------------------------------------------+
void CLogger::LogError(string message) {
   // Luôn ghi log lỗi nếu đã khởi tạo
   if(m_is_initialized) {
      string formatted_message;
      FormatLogMessage(formatted_message, "ERROR", message);
      
      // Hiển thị trong cửa sổ "Experts"
      if(m_log_output == LOG_OUTPUT_PRINT || m_log_output == LOG_OUTPUT_BOTH)
         Print(formatted_message);
         
      // Ghi vào file
      if(m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)
         WriteToFile(formatted_message);
      
      // Gửi thông báo Telegram cho tất cả các lỗi
      if(m_enable_telegram)
         SendTelegramMessage(formatted_message);
   }
}

//+------------------------------------------------------------------+
//| Thiết lập cấp độ log - Điều chỉnh lượng thông tin ghi lại        |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(ENUM_LOG_LEVEL log_level) {
   if(m_is_initialized) {
      m_log_level = log_level;
      LogInfo("Đã thay đổi cấp độ log thành: " + EnumToString(log_level));
   }
}

//+------------------------------------------------------------------+
//| Thiết lập chế độ xuất log - Nơi ghi nhật ký                      |
//+------------------------------------------------------------------+
void CLogger::SetLogOutput(ENUM_LOG_OUTPUT log_output) {
   if(m_is_initialized) {
      // Nếu chuyển sang ghi file mà trước đó không ghi file
      if((log_output == LOG_OUTPUT_FILE || log_output == LOG_OUTPUT_BOTH) &&
         (m_log_output != LOG_OUTPUT_FILE && m_log_output != LOG_OUTPUT_BOTH)) {
         
         // Tạo và mở file log nếu chưa có
         if(m_log_file_handle == INVALID_HANDLE) {
            // Tạo tên file mặc định nếu chưa có
            if(m_log_file_name == "") {
               m_log_file_name = m_prefix + "_" + m_symbol + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".log";
StringReplace(m_log_file_name, ".", "_");
               m_log_file_name = m_log_file_name + ".log";
            }
            
            // Mở file log
            m_log_file_handle = FileOpen(m_log_file_name, FILE_WRITE|FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON);
            
            // Kiểm tra nếu không mở được file
            if(m_log_file_handle == INVALID_HANDLE) {
               Print("LOGGER ERROR: Không thể mở file log: ", m_log_file_name, ", error: ", IntegerToString(GetLastError()));
               return; // Giữ nguyên chế độ xuất hiện tại
            }
            
            // Di chuyển con trỏ đến cuối file
            FileSeek(m_log_file_handle, 0, SEEK_END);
         }
      }
      // Nếu chuyển sang không ghi file mà trước đó có ghi file
      else if((log_output != LOG_OUTPUT_FILE && log_output != LOG_OUTPUT_BOTH) &&
              (m_log_output == LOG_OUTPUT_FILE || m_log_output == LOG_OUTPUT_BOTH)) {
         
         // Đóng file log nếu đang mở
         if(m_log_file_handle != INVALID_HANDLE) {
            FileClose(m_log_file_handle);
            m_log_file_handle = INVALID_HANDLE;
         }
      }
      
      // Cập nhật chế độ xuất log
      m_log_output = log_output;
      LogInfo("Đã thay đổi chế độ xuất log thành: " + EnumToString(log_output));
   }
}