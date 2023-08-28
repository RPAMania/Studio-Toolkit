#requires AutoHotkey v1.1
#include <SAPI\Generics>

class ActivitySpeechRecognizer extends BaseSpeechRecognizer
{
  static Version := { Number: "0.0.1", Stage: "alpha" }

  __Get(key)
  {
    LogObjectPropertyDynamic(this, key)
  }

  __Call(methodName, params*)
  {
    LogObjectMethodDynamic(this, methodName, params*)
  }

  __New(toolkitInstance, iniFileFullPath
      , moduleRunningStateText, modulePausedStateText, moduleNotRunningStateText)
  {
    LogMethod(a_thisfunc, toolkitInstance, iniFileFullPath
      , moduleRunningStateText, modulePausedStateText, moduleNotRunningStateText)

    base.__New()


    ; Prevent log flooding

    LogAddRestriction(Logger.LogEventType.Method ; eventType
        , this.IsEngaged.Name ; affectedName
        , 400 ; minimumMsToPass
        , Logger.LogLevel.Debug) ; minimumLogLevel

    LogAddRestriction(Logger.LogEventType.Method ; eventType
        , this.IsActive.Name ; affectedName
        , 400 ; minimumMsToPass
        , Logger.LogLevel.Debug) ; minimumLogLevel

    LogAddRestriction(Logger.LogEventType.Method ; eventType
        , this.__ShouldAllowEngage.Name ; affectedName
        , 400 ; minimumMsToPass
        , Logger.LogLevel.Debug) ; minimumLogLevel

    LogAddRestriction(Logger.LogEventType.Method ; eventType
        , this.__ShouldAllowDisengage.Name ; affectedName
        , 400 ; minimumMsToPass
        , Logger.LogLevel.Debug) ; minimumLogLevel
    
    
    this.iniFile := new this.base.SettingsIniFile(
    (join
        iniFileFullPath, 
        this.__Class, 
        moduleRunningStateText,
        modulePausedStateText,
        moduleNotRunningStateText
    ))

    this.owner := toolkitInstance
    this.spVoice := new SAPI.SpVoice()
    this.gui := new this.SettingsGui(this, toolkitInstance
        , this.__EngageListening ; fnKeyDown
        
        ; Skip using __ShouldAllowEngage as the context sensitivity callback because
        ; combination hotkeys (e.g. X & Y) will trigger the latter key Y even when
        ; the key up event context sensitivity callback is still operational.
        ; This doesn't seem necessary with any other ordinary non-combination hotkey
        ; as they play nice, preventing the native key down action from leaking into 
        ; the active application as long as the up event callback keeps returning true
        ; (btw, this looks like it's undocumented but that's how it appears to work).
        ; , this.__ShouldAllowEngage ; fnKeyDownContextSensitivity
        , 0

        , this.__DisengageListening ; fnKeyUp
        , this.__ShouldAllowDisengage) ; fnKeyUpContextSensitivity)
    this.title := "Activity Speech-To-Clipboard"
    
    this.moduleRunningStateText := moduleRunningStateText
  }

  __Delete()
  {
    LogMethod(a_thisfunc)

    this.Deactivate()
    this.__DisableRecognition()
    this.activityXamlStorage.Close()
  }


  ; =====================================
  ; PUBLIC METHODS FOR RECOGNIZER STATE HANDLING
  ; =====================================

  ; Activate the recognizer with previously parsed configuration
  Activate()
  {
    if (!this.__IsValidConfig)
    {
      throw Exception("Invalid configuration.", -2)
    }

    if (!this.activityXamlStorage)
    {
      throw Exception("Must call " this.base.ActivateWithConfig.Name "() at least once prior "
          . "to using " regexreplace(a_thisfunc, ".*\.(?=[^.]+$)") "()", -2)
    }

    this.hotkey.isActive := true
  }

  ; Parse the config and activate the recognizer with fresh config values
  ActivateWithConfig()
  {
    if (!this.__IsValidConfig)
    {
      throw Exception("Invalid configuration.", -2)
    }

    if (this.activityXamlStorage)
    {
      this.activityXamlStorage.Close()
    }

    ; Returns one of the derived storage types
    switch (this.gui.config.templateStorageType)
    {
      case this.base.Activity.XamlStorage.Type.XMLFile:
        this.activityXamlStorage := new this.base.Activity
            .XMLFileStorage(this.gui.config.uniqueVersion)
      case this.base.Activity.XamlStorage.Type.SQLite:
        this.activityXamlStorage := new this.base.Activity
            .SQLiteStorage(this.gui.config.uniqueVersion)
      default:
        throw Exception("Unknown storage type.", -2, this.gui.config.templateStorageType)
    }
    
    this.activityXamlStorage.Open(this.gui.config.templateStoragePath)

    this.Recognize(this.gui.config.keywords).Listen(false)
    this.Activate()
  }

  ; Deactivate the recognizer
  Deactivate()
  {
    this.hotkey.isActive := false
    this.hotkey.isPaused := false
  }

  ; Pause recognizer operation
  Pause()
  {
    this.Deactivate()

    this.hotkey.isPaused := true

    if (this.IsEngaged())
    {
      this.__DisengageListening()
    }
  }

  ; Resume paused recognizer operation
  Resume(shouldReconfigure := false)
  {
    this.hotkey.isPaused := false

    if (shouldReconfigure)
    {
      this.ActivateWithConfig()
    }
    else
    {
      this.Activate()
    }
  }

  ; Is recognizer currently active
  IsActive()
  {
    return this.hotkey.isActive
  }

  ; Is recognizer currently paused (i.e. was running but config dialog now visible)
  IsPaused()
  {
    return this.hotkey.isPaused
  }

  ; Get recognizer's current active listening state (i.e. if hotkey is being pressed 
  ; down and audio currently being listened to)
  IsEngaged()
  {
    return this.hotkey.isEngaged
  }


  ; =====================================
  ; RECOGNIZER HOTKEY DOWN & UP TRIGGER CONDITION CALLBACKS
  ; =====================================
  
  __ShouldAllowEngage()
  {
    LogMethod(a_thisfunc)

    return this.IsActive() && !this.IsEngaged()
  }

  __ShouldAllowDisengage()
  {
    LogMethod(a_thisfunc)

    ; Use logical-OR to ensure disengaging listening takes place on a key release 
    ; even if a user enters a settings page (leading to this.hotkey.isActive 
    ; becoming false) while holding down the hotkey
    return this.IsActive() || this.IsEngaged()
  }
  

  ; =====================================
  ; RECOGNIZER HOTKEY DOWN & UP EVENT HANDLERS
  ; =====================================

  __EngageListening()
  {
    if (!this.IsActive() || this.IsEngaged())
    {
      ; Skip using __ShouldAllowEngage()
      return
    }

    LogMethod(a_thisfunc)

    this.hotkey.isEngaged := true
    
    fn := this.__EnableRecognition.Bind(this)
    settimer, % fn, -1
  }
  
  __DisengageListening()
  {
    LogMethod(a_thisfunc)

    if (this.hotkey.isEngaged && this.SpokenText == "")
    {
      ; Log release of the key only if no successful recognition took place, because
      ; otherwise log line will appear twice
      Log("Ending listening to incoming audio")
    }
    else
    {
      ; Ending a listening stage already logged → clear the member that's now only 
      ; functioning as a boolean flag
      this.SpokenText := ""
    }

    ; Reset the key release flag
    this.hotkey.isEngaged := false

    this.__DisableRecognition()
  }


  ; =====================================
  ; INPUT AUDIO LISTENING ON/OFF SWITCHES
  ; =====================================

  __EnableRecognition()
  {
    LogMethod(a_thisfunc)

    Log("Starting to listen to incoming audio for keywords")

    this.Prompting := true
    
    ; Activate COM object listening 
    this.Listen()

    ; Wait for a successful keyword detection or a cancelled prompt
    activityName := this.Prompt()

    if (activityName != "")
    {
      this.__DisableRecognition()

      Log("A keyword captured: """ activityName """")

      this.__AssignActivityToClipboard(activityName)
    }
  }

  __DisableRecognition()
  {
    if (this.SpokenText != "")
    {
      Log("Ending listening to incoming audio")
    }

    ; Reset the prompt flag to have an active listener break out of a listening loop
    this.Prompting := false

    ; Turn recognizer COM object listening state off
    this.Listen(false)
  }


  ; =====================================
  ; SUCCESSFUL RECOGNITION HANDLING METHODS
  ; =====================================

  __AssignActivityToClipboard(activityName)
  {
    try
    {
      LogDebug(format("Searching for data for a matching activity in the {} storage"
          , this.activityXamlStorage.base.__Class))
      
      activity := this.activityXamlStorage.Find(activityName)
    }
    catch ex
    {
      LogError(ex.Message)
      msgbox % ex.Message

      return
    }

    try
    {
      LogDebug(format("Attempting to create UiPath Studio–compatible activity data format"
          , this.activityXamlStorage.base.__Class))
      
      this.base.XamlUtils.XamlStringToClipboard(activity.xml)
    }
    catch ex
    {
      LogError("Missing clipboard formats: " ex.Extra)
      msgbox % ex.Message

      return
    }

    this.__OnClipboardAssignCompleteEvent(activity)
  }

  __OnClipboardAssignCompleteEvent(activity)
  {
    activityName := activity.name
    stringupper, activityName, activityName, T
    message := this.gui.ParseRecognitionFeedbackMessage(activityName)

    if (this.gui.config.feedback.tooltip.isActive)
    {
      LogDebug("Clipboard assignment notification by tooltip")
      this.__DisplayTimedTooltip(message)
    }
    
    if (this.gui.config.feedback.audio.isActive 
        && this.gui.config.feedback.audio.voiceProfile != "")
    {
      LogDebug("Clipboard assignment notification by SAPI voice")
      this.spVoice.Speak(message)
    }
  }


  ; =====================================
  ; RECOGNITION FEEDBACK TOOLTIP METHODS
  ; =====================================

  __DisplayTimedTooltip(message, displayPeriodMs := 2000)
  {
    static fnClearTooltip := 0

    if (fnClearTooltip == 0)
    {
      fnClearTooltip := this.__ClearTooltip.Bind(this)
    }

    tooltip % message
    settimer, % fnClearTooltip, % -1 * displayPeriodMs
  }

  __ClearTooltip()
  {
    tooltip
  }

  ; Are all GUI configuration values supplied by the user valid
  __IsValidConfig[]
  {
    get
    {
      LogProperty(this.base.__Class ".IsValidConfig"
          , this.gui.isValidConfigHotkeyControl && this.gui.isValidConfigOtherControls)

      return this.gui.isValidConfigHotkeyControl && this.gui.isValidConfigOtherControls
    }
  }


  ; =====================================
  ; SETTINGS GUI
  ; =====================================

  #include %a_linefile%\..\SettingsGui.ahk

  
  ; =====================================
  ; IMPLEMENTATION FOR READING ACTIVITIES FROM XML / SQLITE
  ; =====================================

  class Activity
  {
    __New(id, uniqueVersion, name, xml)
    {
      LogMethod(a_thisfunc, id, uniqueVersion, name, xml)

      this.id := id
      this.uniqueVersion := uniqueVersion
      this.name := name
      this.xml := xml
    }

    #include %a_linefile%\..\XamlStorage.ahk
    #include %a_linefile%\..\SQLiteStorage.ahk
    #include %a_linefile%\..\XMLFileStorage.ahk
  }


  ; =====================================
  ; IMPLEMENTATION FOR CREATING STUDIO-COMPATIBLE ACTIVITY DATA AND ASSIGNING IT TO CLIPBOARD
  ; =====================================  

  class XamlUtils
  {
    __Get(key)
    {
      LogObjectPropertyDynamic(this, key)
    }

    __Call(methodName, params*)
    {
      LogObjectMethodDynamic(this, methodName, params*)
    }

    #include %a_linefile%\..\DotNetRemotingBinarySerializationStream.ahk

    class ClipboardManager
    {
      __Get(key)
      {
        LogObjectPropertyDynamic(this, key)
      }

      __Call(methodName, params*)
      {
        LogObjectMethodDynamic(this, methodName, params*)
      }

      #include %a_linefile%\..\RegisteredClipboardFormatNames.ahk

      TransferDataToClipboard(hexByteString, clipboardFormat, clearClipboard := false)
      {
        LogMethod(a_thisfunc, hexByteString, clipboardFormat, clearClipboard)

        pMemory := this.__AllocateClipboardMemory(hexByteString
            , clipboardFormat == ClipboardFormats.CF_TEXT, hMemory)
        
        clipboardOpenResult := dllcall("OpenClipboard", int, 0)
        
        if (clipboardOpenResult)
        {
          if (clearClipboard)
          {
            dllcall("EmptyClipboard")
          }

          dllcall("SetClipboardData", int, clipboardFormat, ptr, pMemory)
          dllcall("CloseClipboard")
        }
      }

      __AllocateClipboardMemory(hexByteString, includeNullChar, byref hMemory)
      {
        static GHND := 0x0042

        LogMethod(a_thisfunc, hexByteString, includeNullChar, hMemory)

        numBytes := strlen(hexByteString) / 2 + (includeNullChar ? 1 : 0)
        
        ; Allocate memory
        ; NOTE: No need to release by calling GlobalFree.
        ; "If SetClipboardData succeeds, the system owns the object identified by the hMem
        ; parameter. The application may not write to or free the data once ownership has
        ; been transferred to the system --"
        hMemory := dllcall("GlobalAlloc", int, GHND, int, numBytes)

        ; Write bytes to memory
        pMemory := dllcall("GlobalLock", ptr, hMemory, ptr)

        loop % numBytes
        {
          byte := "0x" + substr(hexByteString, a_index * 2 - 1, 2)
          
          numput(byte, pMemory + (a_index - 1), 0, "uchar")
        }

        ; Release memory
        unlockResult := dllcall("GlobalUnlock", ptr, hMemory)

        return pMemory
      }
    }

    XamlStringToClipboard(xamlString)
    {
      LogMethod(a_thisfunc, xamlString)

      this.ClipboardManager.RegisteredClipboardFormatNames.Update()

      ; Sets following formats:
      ; - CF_TEXT
      ; - CF_OEMTEXT
      ; - CF_UNICODETEXT
      clipboardBytes := this
          .DotNetRemotingBinarySerializationStream
          .GetStringBytes(xamlString)

      this.ClipboardManager.TransferDataToClipboard(clipboardBytes
          , ClipboardFormats.CF_TEXT
          , true)

      ; Sets the following format:
      ; - WorkflowXamlFormat
      clipboardBytes := this.DotNetRemotingBinarySerializationStream
          .GetXamlStreamData(xamlString)
      
      this.ClipboardManager.TransferDataToClipboard(clipboardBytes
          , this.ClipboardManager.RegisteredClipboardFormatNames.WorkflowXamlFormat.Value)

      ; Sets the following format:
      ; - System.String
      this.ClipboardManager.TransferDataToClipboard(clipboardBytes
          , this.ClipboardManager.RegisteredClipboardFormatNames.SystemString.Value)

      ; Sets the following format:
      ; - WorkflowXamlFormat_TargetFramework
      clipboardBytes := this.DotNetRemotingBinarySerializationStream
          .GetTargetFrameworkStreamData()

      this.ClipboardManager.TransferDataToClipboard(clipboardBytes
          , this.ClipboardManager
              .RegisteredClipboardFormatNames.WorkflowXamlFormat_TargetFramework.Value)
    }
  }


  ; =====================================
  ; SETTINGS INI FILE ENTITY
  ; =====================================
  
  class SettingsIniFile
  {
    __Get(key)
    {
      LogObjectPropertyDynamic(this, key)
    }

    __Call(methodName, params*)
    {
      LogObjectMethodDynamic(this, methodName, params*)
    }

    __New(fullPath, sectionName, runningStateText, pausedStateText, notRunningStateText)
    {
      LogMethod(a_thisfunc, fullPath, sectionName, runningStateText, pausedStateText
          , notRunningStateText)
      
      this.fullPath := fullPath
      this.__Read(sectionName)
      this.__Validate(runningStateText, pausedStateText, notRunningStateText)
    }

    __Read(sectionName)
    {
      Log("Reading settings from the .ini file")

      fullPath := this.fullPath
      iniread, lastState, % fullPath, % sectionName, % "lastState", % " "

      iniread, uniqueVersion, % fullPath, % sectionName, % "uniqueVersion", % " "
      iniread, templateStorageType, % fullPath, % sectionName, % "templateStorageType", % " "
      iniread, templateStoragePath, % fullPath, % sectionName, % "templateStoragePath", % " "
      iniread, keywordFilePath, % fullPath, % sectionName, % "keywordFilePath", % " "
      iniread, hotkey, % fullPath, % sectionName, % "hotkey", % " "
      iniread, feedbackMessage, % fullPath, % sectionName, % "feedbackmessage", % " "

      iniread, tooltipFeedbackIsActive, % fullPath, % sectionName
          , % "tooltipFeedback.isActive", 0
      iniread, audioFeedbackIsActive, % fullPath, % sectionName
          , % "audioFeedback.isActive", 0
      iniread, audioFeedbackVoiceProfile, % fullPath, % sectionName
          , % "audioFeedback.voiceProfile", % " "
      iniread, audioFeedbackVolume, % fullPath, % sectionName
          , % "audioFeedback.volume", % SAPI.SpVoice.VolumeLimit.Max
      
      this.lastState := lastState
      this.uniqueVersion := uniqueVersion
      this.templateStorageType := templateStorageType
      this.templateStoragePath := templateStoragePath
      this.keywordFilePath := keywordFilePath

      this.hotkey := hotkey
      
      this.feedbackMessage := feedbackMessage
      this.tooltipFeedback := { isActive: tooltipFeedbackIsActive }
      
      this.audioFeedback := { isActive: audioFeedbackIsActive
          , voiceProfile: audioFeedbackVoiceProfile, volume: audioFeedbackVolume }
    }

    __Validate(runningStateText, pausedStateText, notRunningStateText)
    {
      if (this.lastState = runningStateText || this.lastState = pausedStateText)
      {
        this.lastState := runningStateText
      }
      else
      {
        this.lastState := notRunningStateText
      }

      switch (this.templateStorageType)
      {
        case UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.XamlStorage.Type.XMLFile:
          ; Fix potentially wrong character case
          this.templateStorageType := UiPath.Studio.Toolkit.ActivitySpeechRecognizer
              .Activity.XamlStorage.Type.XMLFile

        case UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.XamlStorage.Type.SQLite:
          ; Fix potentially wrong character case
          this.templateStorageType := UiPath.Studio.Toolkit.ActivitySpeechRecognizer
              .Activity.XamlStorage.Type.SQLite
        
        default: this.templateStorageType := ""
      }
      
      isActive := this.tooltipFeedback.isActive
      if isActive is not digit
      {
        this.tooltipFeedback.isActive := 0
      }
      else
      {
        this.tooltipFeedback.isActive := !!(this.tooltipFeedback.isActive + 0)
      }

      isActive := this.audioFeedback.isActive
      if isActive is not digit
      {
        this.audioFeedback.isActive := 0
      }
      else
      {
        this.audioFeedback.isActive := !!(this.audioFeedback.isActive + 0)
      }

      isMatchingVoiceProfileFound := false
      loop, parse, % SAPI.SpVoice.GetVoicesString("`n", [ "Name" ]), `n
      {
        if (a_index == 1)
        {
          firstAvailableVoiceProfile := a_loopfield
        }

        if (a_loopfield = this.audioFeedback.voiceProfile)
        {
          isMatchingVoiceProfileFound := true
          this.audioFeedback.voiceProfile := a_loopfield ; Fix potentially wrong character case
          break
        }
      }

      if (!isMatchingVoiceProfileFound)
      {
        this.audioFeedback.voiceProfile := firstAvailableVoiceProfile
      }

      if this.audioFeedback.volume is not digit
      {
        this.audioFeedback.volume := SAPI.SpVoice.VolumeLimit.Max
      }
      else
      {
        this.audioFeedback.volume += 0

        if (this.audioFeedback.volume < SAPI.SpVoice.VolumeLimit.Min
            || this.audioFeedback.volume > SAPI.SpVoice.VolumeLimit.Max)
        {
          this.audioFeedback.volume := SAPI.SpVoice.VolumeLimit.Max
        }
      }
    }

    Write(sectionName, state
        , uniqueVersion, templateStorageType, templateStoragePath, keywordFilePath, hotkey
        , feedbackMessage
        , tooltipFeedbackIsActive
        , audioFeedbackIsActive, audioFeedbackVoiceProfile, audioFeedbackVolume)
    {
      Log("Saving settings to the .ini file")

      iniwrite, % format("
      (ltrim
          lastState={}
          uniqueVersion={}
          templateStorageType={}
          templateStoragePath={}
          keywordFilePath={}
          hotkey={}
          feedbackMessage={}
          tooltipFeedback.isActive={}
          audioFeedback.isActive={}
          audioFeedback.voiceProfile={}
          audioFeedback.volume={}"
      )
          , state
          , uniqueVersion
          , templateStorageType
          , templateStoragePath
          , keywordFilePath
          , hotkey
          , feedbackMessage
          , tooltipFeedbackIsActive
          , audioFeedbackIsActive
          , audioFeedbackVoiceProfile
          , audioFeedbackVolume)
      , % this.fullPath, % sectionName
    }
  }


  ; =====================================
  ; EXIT ROUTINE (set in AutoExecute.ahk)
  ; =====================================

  OnExit()
  {
    if (!fileexist(this.iniFile.fullPath))
    {
      ; Should exist at this point, so an unlikely failure has occurred
      Log("Ini file missing → recreating.")

      fileappend, , % this.iniFile.fullPath
    }

    ; Collect values to backup

    state := this.owner.CurrentModuleState[this.__Class]

    if (this.IsPaused())
    {
      ; A configuration window must be visible during exit because the module state is paused.
      ; This is an indication that the module is running instead of stopped, so attempt to 
      ; restore it back to running state upon restart.
      state := this.moduleRunningStateText
    }

    if (!this.gui.handle)
    {
      ; Failure in app startup → do not update the settings file
    }
    else
    {
      ; The settings GUI has been successfully created → collect its values and
      ; write to the .ini file

      uniqueVersion := this.gui.config.uniqueVersion
      templateStorageType := this.gui.config.templateStorageType
      templateStoragePath := this.gui.config.templateStoragePath
      keywordFilePath := this.gui.config.keywordFilePath
      hotkey := this.gui.config.hotkey
      
      guicontrolget, feedbackMessage, , % this.gui.ctrl.feedback.message.handle

      tooltipFeedback := { isActive: !!this.gui.config.feedback.tooltip.isActive }
      audioFeedback :=
      (join
        {
          isActive: !!this.gui.config.feedback.audio.isActive, 
          voiceProfile: this.gui.config.feedback.audio.voiceProfile, 
          volume: this.gui.config.feedback.audio.volume
        }
      )

      if (audioFeedback.voiceProfile == "")
      {
        voices := SAPI.SpVoice.GetVoices()

        if (voices.Length() > 0)
        {
          audioFeedback.voiceProfile := voices[1].name
        }
      }

      if (audioFeedback.volume == "")
      {
        audioFeedback.volume := SAPI.SpVoice.VolumeLimit.Max
      }
    }
    
    try
    {
      this.iniFile.Write(this.__Class
          , state
          , uniqueVersion
          , templateStorageType
          , templateStoragePath
          , keywordFilePath
          , hotkey
          , feedbackMessage
          , tooltipFeedback.isActive
          , audioFeedback.isActive
          , audioFeedback.voiceProfile
          , audioFeedback.volume)
    }
    catch ex
    {
      msgbox % format("Error writing the settings file ""{}"".", this.iniFile.fullPath) 
    }
  }
}


; =====================================
; GLOBAL GUI EVENT CALLBACKS
; =====================================

ActivitySpeechRecognizerGuiEscape()
{
  global toolkit

  toolkit.activitySpeechRecognizer.gui.__OnEscape()
}

ActivitySpeechRecognizerGuiClose()
{
  global toolkit

  toolkit.activitySpeechRecognizer.gui.__OnClose()
}