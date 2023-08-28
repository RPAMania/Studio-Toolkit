class Logger
{
  class LogLevel
  {
    static Off := { value: 0x0, name: "Off" }
    ; static Fatal := { value: 0x1, name: "Fatal" }
    static Error := { value: 0x2, name: "Error" }
    static Warn := { value: 0x4, name: "Warn" }
    static Info := { value: 0x8, name: "Info" }
    static Debug := { value: 0x10, name: "Debug" }
    ; static Trace := { value: 0x20, name: "Trace" }
  }

  class LogEventType
  {
    static Property := 0x0
    static Method := 0x1
  }

  static Default := { messageMaxDisplayChars: 1000, maxLogFileLineCount: 200 }
  static WINAPI :=
  (join
    {
      MB_YESNO: 0x4,
      MB_ICONQUESTION: 0x20,
      MB_DEFBUTTON1: 0x0,
      MB_DEFBUTTON2: 0x100,
      MB_TASKMODAL: 0x2000
    }
  )

  __New(consoleLogLevel, errorFollowupUrl := "", messageMaxDisplayChars := ""
      , maxLogFileLineCount := "", debugLogFileNamePostfix := "")
  {
    if (messageMaxDisplayChars == "" || (!(messageMaxDisplayChars ~= "^-?\d+$")))
    {
      messageMaxDisplayChars := this.base.Default.messageMaxDisplayChars
    }
    messageMaxDisplayChars += 0

    if (maxLogFileLineCount == "" || (!(maxLogFileLineCount ~= "^-?\d+$")))
    {
      maxLogFileLineCount := this.base.Default.maxLogFileLineCount
    }
    maxLogFileLineCount += 0

    switch (consoleLogLevel)
    {
      case this.base.LogLevel.Off, this.base.LogLevel.Fatal, this.base.LogLevel.Error
          , this.base.LogLevel.Warn, this.base.LogLevel.Info, this.base.LogLevel.Debug:
      default: throw Exception("Invalid logging level.", -2, level)
    }

    if (!this.__IsKnownLogLevel(consoleLogLevel))
    {
      throw Exception("Invalid logging level.", -2, consoleLogLevel)
    }

    this.__consoleLogLevel := consoleLogLevel
    this.__errorFollowupUrl := errorFollowupUrl
    this.__maxLogFileLineCount := maxLogFileLineCount
    this.__messageMaxDisplayChars := messageMaxDisplayChars
    this.__debugLogFileEntries := []
    this.__DebugLogFilePath := debugLogFileNamePostfix
    this.__loggingRestrictions := []
  }

  ; =====================================
  ; PUBLIC LOGGING METHODS
  ; =====================================

  Log(messageLogLevel, messageParams*)
  {
    if (!this.__IsKnownLogLevel(messageLogLevel))
    {
      messageLogLevel := this.base.LogLevel.Info
    }

    formattime, now, , yyyy-MM-dd HH:mm:ss

    message := ""
    for i, messageChunk in messageParams
    {
      if (strlen(message))
      {
        message .= ", "
      }

      if (this.__messageMaxDisplayChars > -1)
      {
        if (strlen(messageChunk) > this.__messageMaxDisplayChars)
        {
          messageChunk := substr(messageChunk, 1, this.__messageMaxDisplayChars) "..."
        }
      }

      message .= messageChunk
    }
    
    ; Store a new log file entry
    
    if (this.__debugLogFileEntries.Length() >= this.__maxLogFileLineCount 
        && this.__maxLogFileLineCount > -1)
    {
      this.__debugLogFileEntries.RemoveAt(1)
    }

    datePrefixedCSVMessage := now ";" 
        . messageLogLevel.name ";" 
        . (instr(message, ";") ? """" strreplace(message, """", "'") """" : message) "`r`n"
    
    this.__debugLogFileEntries.Push(datePrefixedCSVMessage)
    
    ; Log into the console

    if (messageLogLevel.value <= this.__consoleLogLevel.value)
    {
      datePrefixedMessage := now " – " messageLogLevel.name " – " message "`r`n"
      outputdebug % datePrefixedMessage
    }
  }

  /*
    LogMethodWithLevel(methodName, logLevel, params*)
    {
      message := this.__PrepareLogMethodMessage(methodName, params*)
      
      this.Log(logLevel, message)
    }
  */

  LogMethod(methodName, params*)
  {
    static logStat := { }

    currentTickCount := a_tickcount

    logRestriction := this.__FindRestriction(this.base.LogEventType.Method, methodName
        , this.base.LogLevel.Debug)
    
    if (isobject(logRestriction))
    {
      if (logRestriction.minimumMsToPass == -1)
      {
        ; Should always restrict
        tooltip % methodName " always restricted"
        return
      }

      if (logStat.HasKey(methodName)
          && logRestriction.minimumMsToPass 
              > currentTickCount - logStat[methodName].lastRecordedCallTicks)
      {
        ; The same method as the one before and a new log request arrived too soon
        return
      }
      else
      {
        logStat[methodName] := { lastRecordedCallTicks: 0 }
      }

      logStat[methodName].lastRecordedCallTicks := currentTickCount
    }

    message := this.__PrepareLogMethodMessage(methodName, params*)

    this.Log(this.base.LogLevel.Debug, message)
  }

  LogProperty(propertyName, propertyValue := "")
  {
    this.Log(this.base.LogLevel.Debug, propertyName 
        . (propertyValue != "" && !isobject(propertyValue) ? " == " propertyValue : ""))
  }

  LogObjectPropertyDynamic(ownerObject, key)
  {
    classOrFuncObjectCandidate := objrawget(objgetbase(ownerObject), key)

    ; Only log accessed properties, not methods or nested classes
    if (key != "base" && key != "__Class" && !isfunc(classOrFuncObjectCandidate) 
        && !(isobject(classOrFuncObjectCandidate) 
            && objhaskey(classOrFuncObjectCandidate, "__Class")))
    {
      propertyValue := objrawget(ownerObject, key)

      if (propertyValue == "")
      {
        propertyValue := objrawget(objgetbase(ownerObject), key)
        ; propertyValue := ownerObject[key]()
      }

      this.LogProperty(objrawget(objgetbase(ownerObject), "__Class") "." key
          , propertyValue)
    }
  }

  LogObjectMethodDynamic(ownerObject, methodName, params*)
  {
    this.LogMethod(objrawget(objgetbase(ownerObject), "__Class") "." methodName, params*)
  }

  LogUnhandledException(ex)
  {
    static WINAPI := Logger.WINAPI

    this.Log(this.base.LogLevel.Error
        , "Unhandled exception"
        , "file: " ex.File
        , "line: " ex.Line
        , "message: " ex.Message
        , "what: " ex.What
        , "extra: " ex.Extra)
    
    msgbox, % WINAPI.MB_YESNO | WINAPI.MB_ICONQUESTION | WINAPI.MB_DEFBUTTON1 
            | WINAPI.MB_TASKMODAL
        , % "Unexpected error"
        , % "An unexpected error just took place. The application may be in an unstable "
            . "state.`r`n`r`nDo you want to have a log file created? This file may then be "
            . "manually uploaded to vendor's GitHub issues page to help with troubleshooting."
    
    ifmsgbox, yes
    {
      this.ExportDebugLogFile()

      if (this.__errorFollowupUrl != "")
      {
        run % this.__errorFollowupUrl
      }
    }

    return true
  }

  ExportDebugLogFile()
  {
    logStream := "Timestamp;Level;Message`r`n"

    for idx, logFileEntry in this.__debugLogFileEntries
    {
      logStream .= logFileEntry
    }

    fileappend, % substr(logStream, 1, -2), % this.__DebugLogFilePath

    msgbox % "A log file exported to """ this.__DebugLogFilePath """"
  }

  AddRestriction(eventType, affectedName, minimumMsToPass, minimumLogLevel)
  {
    this.__loggingRestrictions.Push(
    (join
      {
        eventType: eventType,
        affectedName: affectedName,
        minimumMsToPass: minimumMsToPass,
        minimumLogLevel: minimumLogLevel
      }
    ))
  }


  ; =====================================
  ; HELPER METHODS AND PROPERTIES
  ; =====================================

  __FindRestriction(logEventType, name, logLevel)
  {
    for idx, restriction in this.__loggingRestrictions
    {
      if (logEventType == restriction.eventType && name == restriction.affectedName
          && logLevel >= restriction.minimumLogLevel)
      {
        return restriction
      }
    }

    return false
  }

  __PrepareLogMethodMessage(methodName, params*)
  {
    message := methodName "()"

    for idx, param in params
    {
      if (!isobject(param))
      {
        message .= " | param" idx ": " param
      }
    }

    return message
  }

  __IsKnownLogLevel(logLevelCandidate)
  {
    if (!this.base.__Class)
    {
      this := this.base
    }

    switch (logLevelCandidate)
    {
      case this.LogLevel.Off, this.LogLevel.Fatal, this.LogLevel.Error
          , this.LogLevel.Warn, this.LogLevel.Info, this.LogLevel.Debug:
          return true
      default: return false
    }
  }

  __Now[]
  {
    get
    {
      formattime, now, , yyyy-MM-dd_HHmmss
      return now
    }
  }

  __DebugLogFilePath[]
  {
    get
    {
      if (this.__debugLogFileFullPath == "")
      {
        throw Exception("Log file path has not yet been set.", -2)
      }
      
      return format(this.__debugLogFileFullPath, this.__Now)
    }

    set
    {
      if (!(value ~= "^[A-Z]:") && strlen(value))
      {
        ; Assume a relative path

        value := a_scriptdir "\" value
      }

      if (value == "")
      {
        ; Empty string → use default path

        value := a_scriptdir "\{1}_log.csv"
      }

      if (!(value ~= "\.csv$"))
      {
        value .= ".csv"
      }

      if (value ~= "x)^(?:  (?!  \{ (?:[1-9]\d*) \}  ).  )* \{\}"  "|"  "\{1\}")
      {
        ; A valid first fillable placeholder supplied
        ; EITHER {} not preceded by {idx}
        ; OR {1}

        fileFullPathCandidate := format(value, this.__Now)
      }
      else
      {
        ; A fixed path without placeholders

        pathState := fileexist(value)
        if (instr(pathState, "D"))
        {
          ; Folder instead of a file
          throw Exception(format("The log file path ""{}"" points to an existing folder.", value), -3)
        }
        else if (instr(pathState, "R"))
        {
          ; File exists and is read-only
          throw Exception(format("The log file path ""{}"" points to a read-only file.", value)
              , -3)
        }
        else if (pathState != "")
        {
          msgbox, % this.base.WINAPI.MB_YESNO | this.base.WINAPI.MB_ICONQUESTION 
              | this.base.WINAPI.MB_DEFBUTTON2, % "A log file already exists"
              , % format("The file ""{}"" already exists. Allow overwriting with a new log file?"
                  , value)

          ifmsgbox, No
          {
            throw Exception(format("The log file ""{}"" already exists", value))
          }
        }

        fileFullPathCandidate := value
      }
      
      if (regexreplace(fileFullPathCandidate, "^(?:[A-Z]:)") 
          ~= "[\Q" ForbiddenFilePathChars() "\E]")
      {
        throw Exception(format("The log file path ""{}"" can't contain any of the following "
            . "characters (except a full colon right after a drive letter):`r`n{}"
                , fileFullPathCandidate, ForbiddenFilePathChars(" ")), -2)
      }
      
      fileappend, % "", % fileFullPathCandidate
      fileWriteFailure := errorlevel
      filedelete, % fileFullPathCandidate

      if (fileWriteFailure)
      {
        throw Exception(format("Couldn't do a test write to the log file ""{}""."
            , fileFullPathCandidate), -3)
      }

      return this.__debugLogFileFullPath := value
    }
  }
}

; =====================================
; GLOBAL LOGGING HELPER FUNCTIONS
; =====================================

; Log with the default level Logger.LogLevel.Info
Log(messageParams*)
{
  LogInfo(messageParams*)
}

LogInfo(messageParams*)
{
  l.Log(Logger.LogLevel.Info, messageParams*)
}

LogDebug(messageParams*)
{
  l.Log(Logger.LogLevel.Debug, messageParams*)
}

LogWarn(messageParams*)
{
  l.Log(Logger.LogLevel.Warn, messageParams*)
}

LogError(messageParams*)
{
  l.Log(Logger.LogLevel.Error, messageParams*)
}

LogMethod(methodName, params*)
{
  l.LogMethod(methodName, params*)
}

LogProperty(propertyName, propertyValue := "")
{
  l.LogProperty(propertyName, propertyValue)
}

LogObjectPropertyDynamic(ownerObject, key)
{
  l.LogObjectPropertyDynamic(ownerObject, key)
}

LogObjectMethodDynamic(ownerObject, methodName, params*)
{
  l.LogObjectMethodDynamic(ownerObject, methodName, params*)
}

LogAddRestriction(eventType, affectedName, minimumMsToPass, minimumLogLevel)
{
  l.AddRestriction(eventType, affectedName, minimumMsToPass, minimumLogLevel)
}