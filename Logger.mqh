//+------------------------------------------------------------------+
//|                                                     Logger.mqh |
//|                Advanced Logging Class with CSV & Telegram        |
//|                            Version 10.4 (Syntax Checked)         |
//+------------------------------------------------------------------+
#property strict

#include <Arrays/ArrayString.mqh> // For WebRequest

// Forward declaration for CLogger class if needed elsewhere, though usually not necessary for .mqh
// class CLogger;

//+------------------------------------------------------------------+
//| CLogger Class                                                    |
//+------------------------------------------------------------------+
class CLogger
{
private:
   //--- Configuration ---
   string            m_moduleName;            // Name of the module/class using the logger
   bool              m_detailedLogsEnabled;   // Enable/disable DEBUG level logging
   bool              m_logToCsvEnabled;       // Enable/disable logging to CSV file
   string            m_csvFileName;           // CSV log filename
   bool              m_telegramEnabled;       // Enable/disable Telegram notifications
   string            m_telegramToken;         // Telegram Bot Token (Set via Initialize)
   string            m_telegramChatId;        // Telegram Chat ID (Set via Initialize)
   bool              m_telegramOnlyImportant; // Send only WARNING/ERROR to Telegram

   //--- File Handling ---
   int               m_csvFileHandle;         // Handle for the CSV log file
   bool              m_csvHeaderWritten;      // Flag to check if header was written

   //--- Private Methods ---
   bool              OpenCsvFile();
   void              WriteToCsv(string level, string message);
   string            FormatCsvField(string textField);
   string            UrlEncode(string textToEncode);

public:
                     CLogger(string moduleName);
                    ~CLogger();

   //--- Initialization ---
   bool              Initialize(bool enableDetailedLogs,
                                bool enableCsv, string csvFilename,
                                bool enableTelegram, string telegramToken, string telegramChatId,
                                bool telegramOnlyImportant);

   //--- Logging Methods ---
   void              LogInfo(string message);
   void              LogWarning(string message);
   void              LogError(string message, int errorCode = -1);
   void              LogDebug(string message);

   //--- Notification Method ---
   bool              SendTelegramNotification(string message, bool forceSend = false);
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger(string moduleName)
{
   m_moduleName = moduleName;
   m_detailedLogsEnabled = false;
   m_logToCsvEnabled = false;
   m_csvFileName = "";
   m_telegramEnabled = false;
   m_telegramToken = "";
   m_telegramChatId = "";
   m_telegramOnlyImportant = true;
   m_csvFileHandle = INVALID_HANDLE;
   m_csvHeaderWritten = false;
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger()
{
   if (m_csvFileHandle != INVALID_HANDLE) {
      FileClose(m_csvFileHandle);
      m_csvFileHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Initialize Logger Settings                                       |
//+------------------------------------------------------------------+
bool CLogger::Initialize(bool enableDetailedLogs,
                         bool enableCsv, string csvFilename,
                         bool enableTelegram, string telegramToken, string telegramChatId,
                         bool telegramOnlyImportant)
{
   m_detailedLogsEnabled = enableDetailedLogs;
   m_logToCsvEnabled = enableCsv;
   m_telegramEnabled = enableTelegram;
   m_telegramToken = telegramToken;
   m_telegramChatId = telegramChatId;
   m_telegramOnlyImportant = telegramOnlyImportant;

   // Initialize CSV logging if enabled
   if (m_logToCsvEnabled) {
      if (StringLen(csvFilename) < 4 || StringFind(csvFilename, ".csv", StringLen(csvFilename) - 4) == -1) {
         m_csvFileName = m_moduleName + "_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
         Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] WARNING: Invalid CSV filename provided. Using default: " + m_csvFileName);
      } else {
         m_csvFileName = csvFilename;
      }
      if (!OpenCsvFile()) {
         Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Failed to open CSV log file: " + m_csvFileName + ". Disabling CSV logging.");
         m_logToCsvEnabled = false; // Disable if opening failed
      }
   }

   // Validate Telegram settings
   if (m_telegramEnabled && (StringLen(m_telegramToken) < 10 || StringFind(m_telegramToken, ":") == -1 || StringLen(m_telegramChatId) == 0)) {
       Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Telegram notifications enabled but Token or Chat ID is missing/invalid. Disabling Telegram.");
      m_telegramEnabled = false;
   }

   // Log initialization status
   Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] INFO: Logger initialized. Detailed Logs: " + (string)m_detailedLogsEnabled +
           ", CSV Logging: " + (string)m_logToCsvEnabled + (m_logToCsvEnabled ? " (" + m_csvFileName + ")" : "") +
           ", Telegram: " + (string)m_telegramEnabled + (m_telegramEnabled ? " (Important Only: " + (string)m_telegramOnlyImportant + ")" : ""));

   return true;
}

//+------------------------------------------------------------------+
//| Open CSV File for Logging                                        |
//+------------------------------------------------------------------+
bool CLogger::OpenCsvFile()
{
   if (!m_logToCsvEnabled) return false;
   // If handle is valid and file seems open (not at end - basic check), assume it's ok
   // Note: FileIsEnding might not be reliable for checking if a handle is truly valid after external changes.
   // A more robust check might involve trying a minimal operation like FileSeek.
   if (m_csvFileHandle != INVALID_HANDLE) {
       // Try seeking to current position to check handle validity
       if(FileSeek(m_csvFileHandle, 0, SEEK_CUR)) {
            return true; // Handle seems valid
       } else {
            // Handle is invalid, close it before reopening
            FileClose(m_csvFileHandle);
            m_csvFileHandle = INVALID_HANDLE;
            Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] WARNING: Stale CSV file handle detected. Attempting to reopen.");
       }
   }


   // Reset header flag, check existence in common folder
   m_csvHeaderWritten = FileIsExist(m_csvFileName, FILE_COMMON);

   // Open file for writing, append mode, share read access, in common folder
   m_csvFileHandle = FileOpen(m_csvFileName, FILE_WRITE | FILE_CSV | FILE_ANSI | FILE_SHARE_READ, ',', FILE_COMMON);

   if (m_csvFileHandle == INVALID_HANDLE) {
      Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Opening CSV log file: " + m_csvFileName + ", Error code: " + IntegerToString(GetLastError()));
      return false;
   }

   // Ensure pointer is at the end for appending
   FileSeek(m_csvFileHandle, 0, SEEK_END);

   // Write header only if file was newly created or empty
   if (!m_csvHeaderWritten && FileSize(m_csvFileHandle) == 0) {
      if(FileWriteString(m_csvFileHandle, "Timestamp,Module,Level,Message\n") > 0) { // Check write result
         FileFlush(m_csvFileHandle);
         m_csvHeaderWritten = true; // Mark header as written only if successful
      } else {
         Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Failed to write CSV header. Error: " + IntegerToString(GetLastError()));
         FileClose(m_csvFileHandle);
         m_csvFileHandle = INVALID_HANDLE;
         return false; // Failed to write header
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Format a string for CSV field (handles quotes and commas)        |
//+------------------------------------------------------------------+
string CLogger::FormatCsvField(string textField)
{
   string output = textField;
   // Replace existing double quotes with two double quotes
   StringReplace(output, "\"", "\"\"");
   if (StringFind(output, ",") != -1 || StringFind(output, "\n") != -1 || StringFind(output, "\"") != -1) {
      output = "\"" + output + "\"";
   }
   return output;
}


//+------------------------------------------------------------------+
//| Write Log Entry to CSV File                                      |
//+------------------------------------------------------------------+
void CLogger::WriteToCsv(string level, string message)
{
   if (!m_logToCsvEnabled) return; // Exit if CSV logging is disabled

   // Check if handle is valid, try to reopen if needed
   if (m_csvFileHandle == INVALID_HANDLE) {
       if (!OpenCsvFile()) {
           // Use Print directly to avoid recursion if LogError uses WriteToCsv
           Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Cannot write to CSV. File handle invalid and reopen failed. Disabling CSV logging.");
           m_logToCsvEnabled = false; // Disable further CSV attempts for this session
           return;
       }
   }

   // Prepare CSV row data
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
   string formattedMessage = FormatCsvField(message); // Format message for CSV safety
   string csvRow = timestamp + "," + m_moduleName + "," + level + "," + formattedMessage + "\n"; // Add newline

   // Write to file and check bytes written
   if(FileWriteString(m_csvFileHandle, csvRow) != StringLen(csvRow)) {
       // Handle potential write error
       Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: Failed to write complete log entry to CSV. Error: " + IntegerToString(GetLastError()));
       // Consider closing the handle or disabling CSV logging on write failure
       FileClose(m_csvFileHandle); // Close handle on write error
       m_csvFileHandle = INVALID_HANDLE;
       m_logToCsvEnabled = false; // Disable future attempts in this session
   } else {
       FileFlush(m_csvFileHandle); // Ensure data is written to disk
   }
}

//+------------------------------------------------------------------+
//| Log Information Message                                          |
//+------------------------------------------------------------------+
void CLogger::LogInfo(string message)
{
   Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] INFO: " + message);
   WriteToCsv("INFO", message);
   if (m_telegramEnabled && !m_telegramOnlyImportant) { // Check telegram enabled status
       SendTelegramNotification("ℹ️ INFO: " + message);
   }
}

//+------------------------------------------------------------------+
//| Log Warning Message                                              |
//+------------------------------------------------------------------+
void CLogger::LogWarning(string message)
{
   Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] WARNING: " + message);
   WriteToCsv("WARNING", message);
   if (m_telegramEnabled) { // Check telegram enabled status
       SendTelegramNotification("⚠️ WARNING: " + message); // Warnings are usually important enough to send
   }
}

//+------------------------------------------------------------------+
//| Log Error Message (with optional error code)                     |
//+------------------------------------------------------------------+
void CLogger::LogError(string message, int errorCode = -1)
{
   string errorDesc = "";
   if (errorCode != -1) {
      errorDesc = " (Code: " + IntegerToString(errorCode) + ")";
   }
   string fullMessage = message + errorDesc;

   Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] ERROR: " + fullMessage);
   WriteToCsv("ERROR", fullMessage);
   if (m_telegramEnabled) { // Check telegram enabled status
       SendTelegramNotification("🛑 ERROR: " + fullMessage, true); // Force send errors
   }
}

//+------------------------------------------------------------------+
//| Log Debug Message (Conditional)                                  |
//+------------------------------------------------------------------+
void CLogger::LogDebug(string message)
{
   if (m_detailedLogsEnabled) {
      Print(TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " [" + m_moduleName + "] DEBUG: " + message);
      WriteToCsv("DEBUG", message);
   }
}

//+------------------------------------------------------------------+
//| Send Notification via Telegram Bot API                           |
//+------------------------------------------------------------------+
bool CLogger::SendTelegramNotification(string message, bool forceSend = false)
{
   if (!m_telegramEnabled) return false;

   // Check if message level warrants sending
   if (m_telegramOnlyImportant && !forceSend) {
        // Check if message starts with warning or error indicators (adjust emojis if needed)
        if (StringFind(message, "⚠️") != 0 && StringFind(message, "🛑") != 0) {
            return false; // Skip non-important messages
        }
   }

   // Validate token and chat ID again just in case
   if (StringLen(m_telegramToken) < 10 || StringLen(m_telegramChatId) == 0) {
      // Avoid repeated logging if already logged in Initialize
      return false;
   }

   // Prepare URL and Data
   string url = "https://api.telegram.org/bot" + m_telegramToken + "/sendMessage";
   string fullMessage = "[" + m_moduleName + "] " + message; // Prepend module name
   string messageEncoded = UrlEncode(fullMessage); // URL Encode the message
   char data[]; // Use char array for POST data
   // Prepare POST data string first
   string postDataStr = "chat_id=" + m_telegramChatId + "&text=" + messageEncoded + "&parse_mode=HTML";
   // Convert string to char array
   int data_size = StringToCharArray(postDataStr, data);

   // Prepare WebRequest variables
   char post_result[];    // Response body as char array
   string result_header; // Response headers as string
   int timeout = 5000;    // 5 seconds timeout
   string headers = "Content-Type: application/x-www-form-urlencoded"; // Set content type header

   // Send POST request
   ResetLastError();
   // Use the correct WebRequest overload for POST with char[] data
   int res = WebRequest("POST", url, headers, timeout, data, post_result, result_header);

   // Check result
   if (res == -1) {
      LogError("Telegram WebRequest failed.", GetLastError()); // Log MQL5 error
      return false;
   } else if (res == 200) {
      // LogDebug("Telegram notification sent successfully."); // Optional success log
      return true;
   } else {
      // Log HTTP error status and response
      LogError("Telegram notification failed. HTTP status: " + IntegerToString(res) +
               ". Response: " + CharArrayToString(post_result));
      return false;
   }
}

//+------------------------------------------------------------------+
//| URL Encode String                                                |
//+------------------------------------------------------------------+
string CLogger::UrlEncode(string textToEncode)
{
   string encoded = "";
   uchar uchar_array[];
   int size = StringToCharArray(textToEncode, uchar_array);

   for (int i = 0; i < size; i++) {
      uchar c = uchar_array[i];
      if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') ||
          c == '-' || c == '_' || c == '.' || c == '~') {
             encoded += CharToString(c);
       } else if (c == ' ') {
          encoded += "+"; // Encode space as '+'
       } else {
          encoded += StringFormat("%%%02X", c); // Percent-encode
       }
    }
    return encoded;
 }