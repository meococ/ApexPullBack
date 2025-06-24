//+------------------------------------------------------------------+
//|                                                     Logger.mqh |
//|              APEX Pullback EA v14.0 - Hệ thống ghi nhật ký      |
//+------------------------------------------------------------------+

#ifndef LOGGER_MQH_
#define LOGGER_MQH_

#include "CommonStructs.mqh" // Phụ thuộc duy nhất

// BẮT ĐẦU NAMESPACE
namespace ApexPullback
{

//+------------------------------------------------------------------+
//| Lớp CLogger - Quản lý ghi log chuyên nghiệp cho EA              |
//+------------------------------------------------------------------+
class CLogger
{
private:
    // --- Phụ thuộc Cốt lõi ---
    EAContext*      m_pContext;         // Pointer to the Single Source of Truth

    // --- Cấu hình được sao chép --- 
    SInputParameters m_config;          // Copy of all inputs for easy access

    // --- Trạng thái Nội tại ---
    string     m_symbol_name;       // Tên biểu tượng được lưu trữ
    string     m_log_file_name;     // Tên file log đầy đủ
    int        m_log_file_handle;   // Handle quản lý file log
    bool       m_is_initialized;    // Trạng thái khởi tạo của logger

    // --- Phương thức Nội bộ ---
    void   FormatLogMessage(string &formatted_message, const string level, const string message, const string tags) const;
    void   WriteToFile(const string message) const;
    bool   SendTelegramMessage(const string message, bool important = false) const;

public:
    // --- Constructor & Destructor ---
    CLogger();
    ~CLogger();
    
    // --- Khởi tạo và Dọn dẹp ---
    bool Initialize(EAContext* pContext); // Initialize with the context
    void Deinitialize();

    // --- Phương thức Ghi log Chính ---
    void LogDebug(const string message, const string tags = "") const;
    void LogInfo(const string message, const string tags = "") const;
    void LogWarning(const string message, const string tags = "") const;
    void LogError(const string message, bool include_stack_trace = false, const string tags = "") const;

    // --- Phương thức Tiện ích ---
    bool   IsInitialized() const { return m_is_initialized; }
    string GetLogFileName() const { return m_log_file_name; }
    void   GenerateDailySummary();

    // --- Phương thức Kiểm tra Cấp độ Log (để tối ưu hóa) ---
    bool IsDebugEnabled() const;
    bool IsInfoEnabled() const;
    bool IsWarningEnabled() const;
    bool IsErrorEnabled() const;
};

//+------------------------------------------------------------------+
//| Constructor - Khởi tạo trạng thái ban đầu an toàn               |
//+------------------------------------------------------------------+
CLogger::CLogger()
{
    m_pContext = NULL;
    m_symbol_name = "";
    m_log_file_name = "";
    m_log_file_handle = INVALID_HANDLE;
    m_is_initialized = false;
}

//+------------------------------------------------------------------+
//| Destructor - Dọn dẹp trước khi hủy đối tượng                     |
//+------------------------------------------------------------------+
CLogger::~CLogger() {
    Deinitialize();
}

//+------------------------------------------------------------------+
//| Initialize - Thiết lập Logger từ EAContext                      |
//+------------------------------------------------------------------+
bool CLogger::Initialize(EAContext* pContext)
{
    if (m_is_initialized) return true;
    if (pContext == NULL) return false;
    
    m_pContext = pContext;

    // Sao chép toàn bộ cấu hình từ context
    m_config = m_pContext.Inputs;
    
    if(m_pContext.pSymbolInfo) m_symbol_name = m_pContext.pSymbolInfo->Name();
     else m_symbol_name = Symbol();

    // --- Cấu hình File Log ---
    if (m_config.LogOutput == LOG_OUTPUT_FILE || m_config.LogOutput == LOG_OUTPUT_BOTH)
    {
        string date_str = TimeToString(TimeCurrent(), TIME_DATE);
        StringReplace(date_str, ".", "");
        m_log_file_name = "Logs\\" + m_config.EAName + "_" + m_symbol_name + "_" + date_str + ".log";

        m_log_file_handle = FileOpen(m_log_file_name, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);

        if (m_log_file_handle == INVALID_HANDLE)
        {
            PrintFormat("LOGGER ERROR: Cannot open log file '%s', error: %d. File logging is disabled.", m_log_file_name, GetLastError());
        }
        else
        {
            FileSeek(m_log_file_handle, 0, SEEK_END);
        }
    }

    m_is_initialized = true;

    LogInfo("Logger initialized successfully.", "Logger");
    if(m_config.EnableTelegramNotify)
    {
         LogInfo("Telegram notifications enabled." + (m_config.TelegramImportantOnly ? " (Important Only)" : ""), "Logger,Telegram");
    }

    return m_is_initialized;
}

//+------------------------------------------------------------------+
//| Giải phóng tài nguyên khi kết thúc EA hoặc Logger               |
//+------------------------------------------------------------------+
void CLogger::Deinitialize() {
   if(!m_is_initialized) return;

   LogInfo("Logger is shutting down...", "Logger");
   
   if(m_log_file_handle != INVALID_HANDLE) {
      FileClose(m_log_file_handle);
      m_log_file_handle = INVALID_HANDLE;
   }
   
   m_is_initialized = false;
   m_pContext = NULL; // Reset pointer
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ DEBUG                                           |
//+------------------------------------------------------------------+
void CLogger::LogDebug(const string message, const string tags = "") const
{
    if (!IsDebugEnabled()) return;

    string formatted_message;
    FormatLogMessage(formatted_message, "DEBUG", message, tags);

    const ENUM_LOG_OUTPUT output_mode = m_config.LogOutput;

    if (output_mode == LOG_OUTPUT_PRINT || output_mode == LOG_OUTPUT_BOTH)
        Print(formatted_message);

    if (output_mode == LOG_OUTPUT_FILE || output_mode == LOG_OUTPUT_BOTH)
        WriteToFile(formatted_message);
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ INFO                                            |
//+------------------------------------------------------------------+
void CLogger::LogInfo(const string message, const string tags = "") const
{
    if (!IsInfoEnabled()) return;

    string formatted_message;
    FormatLogMessage(formatted_message, "INFO", message, tags);

    if (m_config.LogOutput == LOG_OUTPUT_PRINT || m_config.LogOutput == LOG_OUTPUT_BOTH)
        Print(formatted_message);

    if (m_config.LogOutput == LOG_OUTPUT_FILE || m_config.LogOutput == LOG_OUTPUT_BOTH)
        WriteToFile(formatted_message);

    // Gửi Telegram nếu được bật và không phải chế độ chỉ quan trọng
    if (m_config.EnableTelegramNotify && !m_config.TelegramImportantOnly)
        SendTelegramMessage(formatted_message, false);
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ WARNING                                         |
//+------------------------------------------------------------------+
void CLogger::LogWarning(const string message, const string tags = "") const
{
    if (!IsWarningEnabled()) return;

    string formatted_message;
    FormatLogMessage(formatted_message, "WARNING", message, tags);

    const ENUM_LOG_OUTPUT output_mode = m_config.LogOutput;

    if (output_mode == LOG_OUTPUT_PRINT || output_mode == LOG_OUTPUT_BOTH)
        Print(formatted_message);

    if (output_mode == LOG_OUTPUT_FILE || output_mode == LOG_OUTPUT_BOTH)
        WriteToFile(formatted_message);

    // Cảnh báo luôn được coi là quan trọng đối với Telegram
    if (m_config.EnableTelegramNotify)
        SendTelegramMessage(formatted_message, true);
}

//+------------------------------------------------------------------+
//| Ghi log ở cấp độ ERROR với tùy chọn Stack Trace                 |
//+------------------------------------------------------------------+
void CLogger::LogError(const string message, bool include_stack_trace = false, const string tags = "") const
{
    if (!IsErrorEnabled()) return;

    string final_message = message;

    // Thêm stack trace nếu được yêu cầu và có thể
    if (include_stack_trace && m_pContext != NULL && m_pContext.pFuncStack != NULL)
     {
         const string stack_trace = m_pContext.pFuncStack->GetTraceAsString();
         if (stack_trace != "")
         {
            final_message += "\n--- STACK TRACE ---\n" + stack_trace;
        }
    }

    string formatted_message;
    FormatLogMessage(formatted_message, "ERROR", final_message, tags);

    const ENUM_LOG_OUTPUT output_mode = m_config.LogOutput;

    if (output_mode == LOG_OUTPUT_PRINT || output_mode == LOG_OUTPUT_BOTH)
        Print(formatted_message);

    if (output_mode == LOG_OUTPUT_FILE || output_mode == LOG_OUTPUT_BOTH)
        WriteToFile(formatted_message);

    // Lỗi luôn được coi là quan trọng đối với Telegram
    if (m_config.EnableTelegramNotify)
        SendTelegramMessage(formatted_message, true);
}

//+------------------------------------------------------------------+
//| Định dạng thông điệp log                                         |
//+------------------------------------------------------------------+
void CLogger::FormatLogMessage(string &formatted_message, const string level, const string message, const string tags) const
{
    if (!m_is_initialized) return; // An toàn là trên hết

    // Định dạng: [YYYY.MM.DD HH:MM:SS] [SYMBOL] [LEVEL] [TAGS] Message
    formatted_message = "[" + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "] ";
    formatted_message += "[" + m_symbol_name + "] ";
    formatted_message += "[" + level + "]";
    if (tags != "")
    {
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
bool CLogger::SendTelegramMessage(const string message, bool important = false) const
{
    // Sử dụng cấu hình đã sao chép
    // Kiểm tra xem có nên gửi không
    if (!m_config.EnableTelegramNotify || m_config.TelegramBotToken == "" || m_config.TelegramChatID == "")
        return false;

    if (m_config.TelegramImportantOnly && !important)
        return false;

    // Xây dựng URL và tham số
    string url = "https://api.telegram.org/bot" + m_config.TelegramBotToken + "/sendMessage";
    string params = "chat_id=" + m_config.TelegramChatID + "&text=" + message;

    // Gửi yêu cầu
    char post[], result[];
    StringToCharArray(params, post);
    string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
    int timeout = 5000; // 5 giây
    string response_headers;

    ResetLastError();
    int res = WebRequest("POST", url, headers, timeout, post, result, response_headers);

    if (res == -1)
    {
        // Ghi log lỗi mà không kích hoạt một thông báo Telegram khác (tránh vòng lặp vô hạn)
        LogError("Lỗi gửi thông báo Telegram: " + IntegerToString(GetLastError()), false, "Telegram,Critical");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Các phương thức kiểm tra cấp độ log (để tối ưu hóa)             |
//+------------------------------------------------------------------+
bool CLogger::IsDebugEnabled() const
{
    return m_is_initialized && m_config.LogLevel >= LOG_LEVEL_DEBUG;
}

bool CLogger::IsInfoEnabled() const
{
    return m_is_initialized && m_config.LogLevel >= LOG_LEVEL_INFO;
}

bool CLogger::IsWarningEnabled() const
{
    return m_is_initialized && m_config.LogLevel >= LOG_LEVEL_WARNING;
}

bool CLogger::IsErrorEnabled() const
{
    return m_is_initialized && m_config.LogLevel >= LOG_LEVEL_ERROR;
}

// Cấu trúc để lưu trữ số liệu thống kê tóm tắt từ log
struct LogSummaryStats {
   int total_errors;
   int total_warnings;

   void Initialize() {
      total_errors = 0;
      total_warnings = 0;
   }
};

// --- Forward declaration for helper function ---
bool ParseLogFileForSummary(const string file_path, LogSummaryStats &stats, const CLogger* logger_instance);

void CLogger::GenerateDailySummary()
{
    if (!m_is_initialized || !m_config.EnableTelegramNotify)
    {
        return;
    }


    string log_path = GetLogFileName();
    if (log_path == "")
    {
        LogWarning("Không thể tạo báo cáo tóm tắt: không có file log nào được cấu hình.", "Summary");
        return;
    }

    LogSummaryStats stats;
    if (ParseLogFileForSummary(log_path, stats, this))
    {
        // Tạo thông điệp tóm tắt
        string summary_message = "\n--- BÁO CÁO HÀNG NGÀY ---";
        summary_message += "\nEA: " + m_config.EAName;
        summary_message += "\nSymbol: " + m_symbol_name;
        summary_message += "\nNgày: " + TimeToString(TimeCurrent(), TIME_DATE);
        summary_message += "\n--------------------------";
        summary_message += "\n- Tổng số Lỗi: " + (string)stats.total_errors;
        summary_message += "\n- Tổng số Cảnh báo: " + (string)stats.total_warnings;
        summary_message += "\n--------------------------";
        summary_message += "\nChúc một ngày giao dịch tốt lành!";

        // Gửi qua Telegram. Báo cáo luôn được coi là quan trọng.
        SendTelegramMessage(summary_message, true);
        LogInfo("Đã gửi báo cáo tóm tắt hàng ngày qua Telegram.", "Logger,Summary");
    }
    else
    {
        LogError("Không thể tạo báo cáo tóm tắt hàng ngày do không đọc được file log.", false, "Logger,Summary,Critical");
    }
}

bool ParseLogFileForSummary(const string file_path, LogSummaryStats &stats, const CLogger* logger_instance) {
     stats.Initialize();
     ResetLastError();

     int file_handle = FileOpen(file_path, FILE_READ|FILE_TXT|FILE_ANSI|FILE_SHARE_READ|FILE_COMMON);
     if(file_handle == INVALID_HANDLE) {
        // Sử dụng Print thay vì logger_instance->LogError để tránh các vấn đề về const-correctness và vòng lặp vô hạn
        PrintFormat("ParseLogFileForSummary - Could not open log file '%s'. Error: %d", file_path, GetLastError());
        return false;
     }

     while(!FileIsEnding(file_handle)) {
        string line = FileReadString(file_handle);
        if(StringFind(line, "[ERROR]") != -1) {
           stats.total_errors++;
        }
        if(StringFind(line, "[WARNING]") != -1) {
           stats.total_warnings++;
        }
     }

     FileClose(file_handle);
     return true;
}

} // END NAMESPACE ApexPullback
#endif // LOGGER_MQH_
