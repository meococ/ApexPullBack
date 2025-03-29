//+------------------------------------------------------------------+
//| CLogger.mqh - Logging and reporting utility                       |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://www.sonicrsystems.com"
#property version   "3.0"
#property strict

// Include required files
#include "../Common/Constants.mqh"
#include "../Common/Enums.mqh"
#include "../Common/Structs.mqh"

//+------------------------------------------------------------------+
//| CLogger Class - Handles logging and reporting                     |
//+------------------------------------------------------------------+
class CLogger {
private:
    // Log settings
    bool m_enabled;                    // Whether logging is enabled
    ENUM_LOG_LEVEL m_logLevel;         // Current log level
    bool m_saveDailyReports;           // Whether to save daily reports
    bool m_enableEmailAlerts;          // Whether to send email alerts
    bool m_enablePushNotifications;    // Whether to send push notifications
    
    // Log file handle
    int m_fileHandle;                  // File handle for log file
    string m_logFilePath;              // Path to log file
    string m_reportFilePath;           // Path to report file
    
    // Log buffer for dashboard display
    string m_logBuffer[];              // Recent log messages for dashboard
    int m_maxBufferSize;               // Maximum size of log buffer
    
    //--- Private methods
    
    // Create directory if it doesn't exist
    bool CreateDirectoryIfNotExists(string path) {
        // Remove file part if any
        int lastSlash = StringFind(path, "\\", 0);
        if (lastSlash >= 0) {
            path = StringSubstr(path, 0, lastSlash);
        }
        
        // Check if directory exists
        if (FolderCreate(path)) {
            return true;
        } else {
            int error = GetLastError();
            // If error is not "already exists", report it
            if (error != ERR_CANNOT_OPEN_FILE) {
                Print("Error creating directory: ", error);
                return false;
            }
        }
        
        return true;
    }
    
    // Format timestamp for log
    string FormatTimestamp() {
        return TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
    }
    
    // Format log message with timestamp and level
    string FormatLogMessage(string level, string message) {
        return FormatTimestamp() + " [" + level + "] " + message;
    }
    
    // Add message to buffer
    void AddToBuffer(string message) {
        // If buffer is full, remove oldest message
        if (ArraySize(m_logBuffer) >= m_maxBufferSize) {
            // Shift all messages up one position
            for (int i = 0; i < m_maxBufferSize - 1; i++) {
                m_logBuffer[i] = m_logBuffer[i + 1];
            }
            m_logBuffer[m_maxBufferSize - 1] = message;
        } else {
            // Add to buffer
            int size = ArraySize(m_logBuffer);
            ArrayResize(m_logBuffer, size + 1);
            m_logBuffer[size] = message;
        }
    }
    
    // Write to log file
    void WriteToFile(string message) {
        // Skip if logging disabled or file not open
        if (!m_enabled || m_fileHandle <= 0) return;
        
        // Write to file
        message += "\n"; // Add newline
        
        // Check if file exists
        if (FileIsExist(m_logFilePath)) {
            // Open file for append
            m_fileHandle = FileOpen(m_logFilePath, FILE_READ | FILE_WRITE | FILE_TXT);
            
            if (m_fileHandle > 0) {
                // Move to end of file
                FileSeek(m_fileHandle, 0, SEEK_END);
                
                // Write message
                FileWriteString(m_fileHandle, message);
                
                // Close file
                FileClose(m_fileHandle);
            }
        } else {
            // Create new file
            m_fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_TXT);
            
            if (m_fileHandle > 0) {
                // Write message
                FileWriteString(m_fileHandle, message);
                
                // Close file
                FileClose(m_fileHandle);
            }
        }
    }
    
    // Send email alert
    void SendEmailAlert(string subject, string message) {
        // Skip if emails disabled
        if (!m_enableEmailAlerts) return;
        
        // Check if email sending is enabled in terminal
        if (!TerminalInfoInteger(TERMINAL_EMAIL_ENABLED)) {
            Print("WARNING: Email sending is not enabled in the terminal");
            return;
        }
        
        // Send email
        if (!SendMail(subject, message)) {
            Print("ERROR: Failed to send email. Error code: ", GetLastError());
        }
    }
    
    // Send push notification
    void SendPushNotification(string message) {
        // Skip if push notifications disabled
        if (!m_enablePushNotifications) return;
        
        // Check if push notifications are enabled in terminal
        if (!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED)) {
            Print("WARNING: Push notifications are not enabled in the terminal");
            return;
        }
        
        // Send notification
        if (!SendNotification(message)) {
            Print("ERROR: Failed to send push notification. Error code: ", GetLastError());
        }
    }
    
public:
    // Constructor
    CLogger() {
        // Initialize with default values
        m_enabled = true;
        m_logLevel = LOG_INFO;
        m_saveDailyReports = true;
        m_enableEmailAlerts = false;
        m_enablePushNotifications = false;
        
        // Set file handle to invalid
        m_fileHandle = -1;
        
        // Set buffer size
        m_maxBufferSize = 100;
        
        // Initialize log buffer
        ArrayResize(m_logBuffer, 0);
    }
    
    // Destructor
    ~CLogger() {
        // Close file if open
        if (m_fileHandle > 0) {
            FileClose(m_fileHandle);
            m_fileHandle = -1;
        }
    }
    
    // Initialize logger
    bool Initialize(bool enableLogging = true, ENUM_LOG_LEVEL level = LOG_INFO, 
                    bool enableEmailAlerts = false, bool enablePushNotifications = false) {
        // Set parameters
        m_enabled = enableLogging;
        m_logLevel = level;
        m_enableEmailAlerts = enableEmailAlerts;
        m_enablePushNotifications = enablePushNotifications;
        
        // Create log directories
        if (!CreateDirectoryIfNotExists(LOG_DIRECTORY)) {
            Print("ERROR: Failed to create log directory");
            return false;
        }
        
        if (!CreateDirectoryIfNotExists(REPORTS_DIRECTORY)) {
            Print("ERROR: Failed to create reports directory");
            return false;
        }
        
        // Set log file path
        m_logFilePath = LOG_DIRECTORY + "SonicR_" + 
                       Symbol() + "_" + 
                       TimeToString(TimeCurrent(), TIME_DATE) + ".log";
                       
        // Replace colons in filename
        m_logFilePath = StringReplace(m_logFilePath, ":", "-");
        
        // Set report file path
        m_reportFilePath = REPORTS_DIRECTORY + "SonicR_" + 
                          Symbol() + "_" + 
                          TimeToString(TimeCurrent(), TIME_DATE) + "_Report.csv";
        
        // Replace colons in filename
        m_reportFilePath = StringReplace(m_reportFilePath, ":", "-");
        
        // Open log file
        if (m_enabled) {
            m_fileHandle = FileOpen(m_logFilePath, FILE_WRITE | FILE_TXT);
            
            if (m_fileHandle <= 0) {
                Print("ERROR: Failed to open log file. Error code: ", GetLastError());
                return false;
            }
            
            // Write header
            string header = "======================================\n";
            header += "SonicR PropFirm EA v3.0 Log\n";
            header += "Symbol: " + Symbol() + "\n";
            header += "Date: " + TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS) + "\n";
            header += "======================================\n";
            
            FileWriteString(m_fileHandle, header);
            FileClose(m_fileHandle);
            m_fileHandle = -1;
            
            // Log initialization
            Info("Logger initialized. Log level: " + GetLogLevelName(m_logLevel));
        }
        
        return true;
    }
    
    // Log error message
    void Error(string message) {
        // Format message
        string formattedMessage = FormatLogMessage("ERROR", message);
        
        // Always print errors
        Print(formattedMessage);
        
        // Add to buffer
        AddToBuffer(formattedMessage);
        
        // Write to file if enabled
        if (m_enabled) {
            WriteToFile(formattedMessage);
        }
        
        // Send email/push if enabled (critical errors only)
        if (m_enableEmailAlerts) {
            SendEmailAlert("SonicR EA Error: " + Symbol(), message);
        }
        
        if (m_enablePushNotifications) {
            SendPushNotification("SonicR EA Error: " + Symbol() + " - " + message);
        }
    }
    
    // Log warning message
    void Warning(string message) {
        // Skip if log level too high
        if (m_logLevel < LOG_WARNING) return;
        
        // Format message
        string formattedMessage = FormatLogMessage("WARNING", message);
        
        // Print warning
        Print(formattedMessage);
        
        // Add to buffer
        AddToBuffer(formattedMessage);
        
        // Write to file if enabled
        if (m_enabled) {
            WriteToFile(formattedMessage);
        }
        
        // Send email/push for important warnings if enabled
        if (m_enableEmailAlerts && StringFind(message, "exceeded") >= 0) {
            SendEmailAlert("SonicR EA Warning: " + Symbol(), message);
        }
        
        if (m_enablePushNotifications && StringFind(message, "exceeded") >= 0) {
            SendPushNotification("SonicR EA Warning: " + Symbol() + " - " + message);
        }
    }
    
    // Log info message
    void Info(string message) {
        // Skip if log level too high
        if (m_logLevel < LOG_INFO) return;
        
        // Format message
        string formattedMessage = FormatLogMessage("INFO", message);
        
        // Print info (only when debugging)
        if (m_logLevel >= LOG_DEBUG) {
            Print(formattedMessage);
        }
        
        // Add to buffer
        AddToBuffer(formattedMessage);
        
        // Write to file if enabled
        if (m_enabled) {
            WriteToFile(formattedMessage);
        }
        
        // Send email/push for trade actions if enabled
        if (m_enableEmailAlerts && 
            (StringFind(message, "executed") >= 0 || 
             StringFind(message, "closed") >= 0)) {
            SendEmailAlert("SonicR EA Trade: " + Symbol(), message);
        }
        
        if (m_enablePushNotifications && 
            (StringFind(message, "executed") >= 0 || 
             StringFind(message, "closed") >= 0)) {
            SendPushNotification("SonicR EA: " + Symbol() + " - " + message);
        }
    }
    
    // Log debug message
    void Debug(string message) {
        // Skip if log level too high
        if (m_logLevel < LOG_DEBUG) return;
        
        // Format message
        string formattedMessage = FormatLogMessage("DEBUG", message);
        
        // Print debug info
        Print(formattedMessage);
        
        // Add to buffer
        AddToBuffer(formattedMessage);
        
        // Write to file if enabled
        if (m_enabled) {
            WriteToFile(formattedMessage);
        }
    }
    
    // Save daily report
    void SaveDailyReport() {
        // Skip if disabled
        if (!m_saveDailyReports) return;
        
        // Get account information
        double balance = AccountInfoDouble(ACCOUNT_BALANCE);
        double equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double margin = AccountInfoDouble(ACCOUNT_MARGIN);
        double profit = AccountInfoDouble(ACCOUNT_PROFIT);
        
        // Create report content
        string reportDate = TimeToString(TimeCurrent(), TIME_DATE);
        string reportTime = TimeToString(TimeCurrent(), TIME_SECONDS);
        string reportContent = "Date,Time,Symbol,Balance,Equity,Margin,Profit\n";
        reportContent += reportDate + "," + reportTime + "," + Symbol() + "," + 
                       DoubleToString(balance, 2) + "," + 
                       DoubleToString(equity, 2) + "," + 
                       DoubleToString(margin, 2) + "," + 
                       DoubleToString(profit, 2) + "\n";
        
        // Open report file
        int fileHandle = FileOpen(m_reportFilePath, FILE_WRITE | FILE_TXT);
        
        if (fileHandle > 0) {
            // Write report
            FileWriteString(fileHandle, reportContent);
            
            // Close file
            FileClose(fileHandle);
            
            Info("Daily report saved: " + m_reportFilePath);
        } else {
            Error("Failed to save daily report. Error code: " + IntegerToString(GetLastError()));
        }
    }
    
    // Get recent log entries for dashboard
    void GetRecentLogs(string &logs[], int count = 10) {
        int size = ArraySize(m_logBuffer);
        int copyCount = MathMin(count, size);
        
        // Resize target array
        ArrayResize(logs, copyCount);
        
        // Copy most recent entries
        for (int i = 0; i < copyCount; i++) {
            logs[i] = m_logBuffer[size - copyCount + i];
        }
    }
    
    // Get log level as string
    string GetLogLevelName(ENUM_LOG_LEVEL level) {
        switch (level) {
            case LOG_ERROR:
                return "ERROR";
            case LOG_WARNING:
                return "WARNING";
            case LOG_INFO:
                return "INFO";
            case LOG_DEBUG:
                return "DEBUG";
            default:
                return "UNKNOWN";
        }
    }
    
    //--- Setters
    
    // Set log enabled state
    void SetEnabled(bool enabled) {
        m_enabled = enabled;
    }
    
    // Set log level
    void SetLogLevel(ENUM_LOG_LEVEL level) {
        m_logLevel = level;
    }
    
    // Set daily reports enabled
    void SetSaveDailyReports(bool enabled) {
        m_saveDailyReports = enabled;
    }
    
    // Set email alerts enabled
    void SetEmailAlerts(bool enabled) {
        m_enableEmailAlerts = enabled;
    }
    
    // Set push notifications enabled
    void SetPushNotifications(bool enabled) {
        m_enablePushNotifications = enabled;
    }
};