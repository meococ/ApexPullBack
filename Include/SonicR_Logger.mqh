//+------------------------------------------------------------------+
//|                                              SonicR_Logger.mqh |
//|                  SonicR PropFirm EA - Logging Component        |
//+------------------------------------------------------------------+
#property copyright "SonicR Trading Systems"
#property link      "https://sonicr.com"

// Logger class for comprehensive activity tracking
class CLogger
{
private:
    string m_name;                 // EA name
    int m_magicNumber;             // Magic number for identification
    bool m_detailedLogging;        // Enable detailed logging
    bool m_saveToFile;             // Save logs to file
    int m_logFileHandle;           // File handle for log file
    string m_logFileName;          // Name of the log file
    
    // Log levels
    enum ENUM_LOG_LEVEL {
        LOG_LEVEL_ERROR = 1,      // Critical errors
        LOG_LEVEL_WARNING = 2,    // Warnings and issues
        LOG_LEVEL_INFO = 3,       // Normal operational info
        LOG_LEVEL_DEBUG = 4       // Detailed debugging info
    };
    
    int m_currentLogLevel;         // Current log level
    
    // Helper methods
    string GetLogLevelString(int level);
    string FormatLogMessage(string message, int level);
    void WriteToFile(string message);
    
public:
    // Constructor
    CLogger(string name, int magicNumber, bool detailedLogging = false, bool saveToFile = false);
    
    // Destructor
    ~CLogger();
    
    // Log methods for different levels
    void Error(string message);   // For critical errors
    void Warning(string message); // For warnings and issues
    void Info(string message);    // For general information
    void Debug(string message);   // For detailed debug info
    
    // Generic log method with level
    void Log(string message, int level = LOG_LEVEL_INFO);
    
    // Settings
    void SetLogLevel(int level);
    void SetDetailedLogging(bool detailed);
    void SetSaveToFile(bool saveToFile);
    
    // File operations
    bool OpenLogFile();
    void CloseLogFile();
    
    // Utilities
    string GetLastLogMessage() const;
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CLogger::CLogger(string name, int magicNumber, bool detailedLogging = false, bool saveToFile = false)
{
    m_name = name;
    m_magicNumber = magicNumber;
    m_detailedLogging = detailedLogging;
    m_saveToFile = saveToFile;
    m_logFileHandle = INVALID_HANDLE;
    m_currentLogLevel = detailedLogging ? LOG_LEVEL_DEBUG : LOG_LEVEL_INFO;
    
    // Open log file if needed
    if(m_saveToFile) {
        OpenLogFile();
    }
    
    // Initial log
    Info("Logger initialized for " + m_name + " (Magic: " + IntegerToString(m_magicNumber) + ")");
}

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CLogger::~CLogger()
{
    // Close log file if open
    if(m_logFileHandle != INVALID_HANDLE) {
        CloseLogFile();
    }
}

//+------------------------------------------------------------------+
//| Get string representation of log level                           |
//+------------------------------------------------------------------+
string CLogger::GetLogLevelString(int level)
{
    switch(level) {
        case LOG_LEVEL_ERROR:   return "ERROR";
        case LOG_LEVEL_WARNING: return "WARNING";
        case LOG_LEVEL_INFO:    return "INFO";
        case LOG_LEVEL_DEBUG:   return "DEBUG";
        default:                return "UNKNOWN";
    }
}

//+------------------------------------------------------------------+
//| Format log message with timestamp and level                      |
//+------------------------------------------------------------------+
string CLogger::FormatLogMessage(string message, int level)
{
    // Get current time with milliseconds
    datetime currentTime = TimeCurrent();
    MqlDateTime dt;
    TimeToStruct(currentTime, dt);
    
    // Format timestamp
    string timestamp = StringFormat("%04d-%02d-%02d %02d:%02d:%02d", 
                                  dt.year, dt.mon, dt.day, 
                                  dt.hour, dt.min, dt.sec);
    
    // Format log message
    string logMsg = StringFormat("[%s] [%s] %s", 
                               timestamp, 
                               GetLogLevelString(level), 
                               message);
    
    return logMsg;
}

//+------------------------------------------------------------------+
//| Write message to log file                                        |
//+------------------------------------------------------------------+
void CLogger::WriteToFile(string message)
{
    // Check if log file is open
    if(m_logFileHandle == INVALID_HANDLE) {
        if(!OpenLogFile()) {
            Print("WARNING: Failed to open log file");
            return;
        }
    }
    
    // Write message to file
    FileWriteString(m_logFileHandle, message + "\n");
    FileFlush(m_logFileHandle);
}

//+------------------------------------------------------------------+
//| Log error messages                                               |
//+------------------------------------------------------------------+
void CLogger::Error(string message)
{
    Log(message, LOG_LEVEL_ERROR);
}

//+------------------------------------------------------------------+
//| Log warning messages                                             |
//+------------------------------------------------------------------+
void CLogger::Warning(string message)
{
    Log(message, LOG_LEVEL_WARNING);
}

//+------------------------------------------------------------------+
//| Log informational messages                                       |
//+------------------------------------------------------------------+
void CLogger::Info(string message)
{
    Log(message, LOG_LEVEL_INFO);
}

//+------------------------------------------------------------------+
//| Log debug messages                                               |
//+------------------------------------------------------------------+
void CLogger::Debug(string message)
{
    Log(message, LOG_LEVEL_DEBUG);
}

//+------------------------------------------------------------------+
//| Generic log method with level                                    |
//+------------------------------------------------------------------+
void CLogger::Log(string message, int level = LOG_LEVEL_INFO)
{
    // Check if this log level should be processed
    if(level > m_currentLogLevel) {
        return;
    }
    
    // Format message
    string formattedMessage = FormatLogMessage(message, level);
    
    // Print to console
    Print(formattedMessage);
    
    // Write to file if needed
    if(m_saveToFile) {
        WriteToFile(formattedMessage);
    }
}

//+------------------------------------------------------------------+
//| Set current log level                                            |
//+------------------------------------------------------------------+
void CLogger::SetLogLevel(int level)
{
    if(level >= LOG_LEVEL_ERROR && level <= LOG_LEVEL_DEBUG) {
        m_currentLogLevel = level;
        Debug("Log level set to " + GetLogLevelString(level));
    }
}

//+------------------------------------------------------------------+
//| Set detailed logging flag                                        |
//+------------------------------------------------------------------+
void CLogger::SetDetailedLogging(bool detailed)
{
    m_detailedLogging = detailed;
    m_currentLogLevel = detailed ? LOG_LEVEL_DEBUG : LOG_LEVEL_INFO;
    
    Debug("Detailed logging " + (detailed ? "enabled" : "disabled"));
}

//+------------------------------------------------------------------+
//| Set save to file flag                                            |
//+------------------------------------------------------------------+
void CLogger::SetSaveToFile(bool saveToFile)
{
    // Check if state is changing
    if(m_saveToFile != saveToFile) {
        m_saveToFile = saveToFile;
        
        if(saveToFile) {
            OpenLogFile();
        } else {
            CloseLogFile();
        }
        
        Debug("Log file saving " + (saveToFile ? "enabled" : "disabled"));
    }
}

//+------------------------------------------------------------------+
//| Open log file                                                    |
//+------------------------------------------------------------------+
bool CLogger::OpenLogFile()
{
    // Close existing file if open
    if(m_logFileHandle != INVALID_HANDLE) {
        FileClose(m_logFileHandle);
        m_logFileHandle = INVALID_HANDLE;
    }
    
    // Create file name based on EA name, symbol, and date
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    
    m_logFileName = StringFormat(
        "%s_%s_%d%02d%02d.log",
        m_name,
        _Symbol,
        dt.year, dt.mon, dt.day
    );
    
    // Open file for writing
    m_logFileHandle = FileOpen(m_logFileName, FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
    
    if(m_logFileHandle == INVALID_HANDLE) {
        Print("ERROR: Failed to open log file: ", GetLastError());
        return false;
    }
    
    // Write header
    FileWriteString(m_logFileHandle, "===== " + m_name + " Log - " + TimeToString(TimeCurrent()) + " =====\n");
    FileWriteString(m_logFileHandle, "Symbol: " + _Symbol + ", Period: " + EnumToString(Period()) + "\n");
    FileWriteString(m_logFileHandle, "Magic Number: " + IntegerToString(m_magicNumber) + "\n");
    FileWriteString(m_logFileHandle, "========================================\n\n");
    
    return true;
}

//+------------------------------------------------------------------+
//| Close log file                                                   |
//+------------------------------------------------------------------+
void CLogger::CloseLogFile()
{
    if(m_logFileHandle != INVALID_HANDLE) {
        // Write footer
        FileWriteString(m_logFileHandle, "\n===== Log Closed at " + TimeToString(TimeCurrent()) + " =====\n");
        
        // Close file
        FileClose(m_logFileHandle);
        m_logFileHandle = INVALID_HANDLE;
    }
}

//+------------------------------------------------------------------+
//| Get the last log message (for UI purposes)                       |
//+------------------------------------------------------------------+
string CLogger::GetLastLogMessage() const
{
    // This is a placeholder - in a real implementation, you'd keep track of recent messages
    return "Log system active";
}