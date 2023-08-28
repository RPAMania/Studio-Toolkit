#requires AutoHotkey v1.1
#include <SAPI\Generics>

class SettingsGui
{
  static FieldValidationSymbol :=
  (join
    {
      ok: "✔",
      warn: " ?",
      error: "❌"
    }
  )

  __Get(key)
  {
    LogObjectPropertyDynamic(this, key)
  }

  __Call(methodName, params*)
  {
    LogObjectMethodDynamic(this, methodName, params*)
  }

  __New(activitySpeechRecognizer, toolkit
      , fnKeyDown, fnKeyDownContextSensitivity
      , fnKeyUp, fnKeyUpContextSensitivity)
  {
    LogMethod(a_thisfunc, activitySpeechRecognizer, toolkit
      , fnKeyDown, fnKeyDownContextSensitivity
      , fnKeyUp, fnKeyUpContextSensitivity)
    
    this.config := 
    (join
      { 
        feedback: 
        { 
          tooltip: 
          {

          }, 
          audio: 
          {
            
          }
        }
      }
    )

    this.owner := activitySpeechRecognizer

    this.toolkit := toolkit
    
    controlWidth := toolkit.gui.dimension.containerControl.width
    button := { width: toolkit.gui.dimension.button.width
        , height: toolkit.gui.dimension.button.height }

    iniFileSettings := this.owner.iniFile

    Log("Starting to create " this.owner.__Class " settings GUI")

    gui, % this.owner.__Class ": new", % "+lastfound -minimizebox +owner" 
        . this.toolkit.gui.handle
        , Configuration: Activity Speech-To-Clipboard

    handle := winexist()

    gui, font, % "s" UiPath.Studio.Toolkit.GlobalFontSize

    Log("Creating controls")

    gui, add, text, % "y10 w" controlWidth, Unique version string
    gui, add, edit, hwndhUniqueVersion wp, % iniFileSettings.uniqueVersion
    gui, add, text, yp+3 x+11 w18 border hwndhUniqueVersionValidation

    gui, add, text, % "xs w" controlWidth, Activity template storage type

    templateStorageTypes 
        .= activitySpeechRecognizer.base.Activity.XamlStorage.Type.XMLFile "|"
    
    switch (iniFileSettings.templateStorageType)
    {
      case activitySpeechRecognizer.base.Activity.XamlStorage.Type.XMLFile:
        templateStorageTypes .= "|" 
            . activitySpeechRecognizer.base.Activity.XamlStorage.Type.SQLite
      
      case activitySpeechRecognizer.base.Activity.XamlStorage.Type.SQLite:
        templateStorageTypes 
            .= activitySpeechRecognizer.base.Activity.XamlStorage.Type.SQLite "||"
      default:
        templateStorageTypes .= activitySpeechRecognizer.base.Activity.XamlStorage.Type.SQLite
    }
    
    gui, add, dropdownlist, % "hwndhTemplateStorageType wp ", % templateStorageTypes
    gui, add, text, yp+3 x+11 w18 border hwndhTemplateStorageTypeValidation

    gui, add, text, % "xs w" controlWidth, Activity template storage path
    gui, add, edit, hwndhTemplateStoragePath disabled wp-27
        , % iniFileSettings.templateStoragePath
    gui, add, button, hwndhBrowseStoragePath w26 h26 yp-1 x+2 disabled, ...
    gui, add, text, yp+3 x+10 w18 border hwndhTemplateStoragePathValidation
    
    gui, add, text, % "xs w" controlWidth, Keyword file location
    gui, add, edit, hwndhKeywordFilePath wp-27
        , % iniFileSettings.keywordFilePath
    gui, add, button, hwndhBrowseKeywordFile w26 h26 yp-1 x+2, ...
    gui, add, text, yp+3 x+10 w18 border hwndhKeywordFilePathValidation

    activitySpeechRecognizer.hotkey := new RevertableGuiHotkey(
    (join c
        iniFileSettings.hotkey, ; Initial key (combination)
        "Activity Speech-To-Clipboard", ; Descriptive hotkey purpose

        ; Hotkey press event callback
        {
          context: activitySpeechRecognizer,
          executeFunc: fnKeyDown,
          contextSensitivityFunc: fnKeyDownContextSensitivity
        },
        ; Hotkey release event callback
        {
          context: activitySpeechRecognizer,
          executeFunc: fnKeyUp,
          contextSensitivityFunc: fnKeyUpContextSensitivity
        },
        ; Hotkey assignment error callback
        {
          context: this,
          func: this.__OnHotkeyAssignError
        },
        ; Hotkey change callback
        {
          context: this,
          func: this.__OnHotkeyChange
        },
        ; GUI id
        this.owner.__Class,
        ; Hotkey master id 
        toolkit.__Class,
        ; Hotkey control options
        "wp",
        ; Hotkey options
        "",
        ; Modifiers that should be allowed as regular keys
        "+"
    ))
    gui, add, text, % "xs w" controlWidth, Speech recognition listener hotkey
    activitySpeechRecognizer.hotkey.CreateControl()
    gui, add, text, yp+3 x+11 w18 border hwndhListenerHotkeyValidation
    

    gui, add, groupbox, % "xm h319 w" controlWidth, Successful recognition feedback

    gui, add, text, xp+10 yp+26 section, Message
    gui, add, edit, % "r1 limit300 xs w" (controlWidth - 5 * 10) " hwndhFeedbackMessage"
        , % iniFileSettings.feedbackMessage
    gui, add, picture, yp+1 x+5 w23 h-1 icon211 hwndhFeedbackMessageHelp
        , % systemroot "\system32\shell32.dll" ; A white question mark on a blue circle
    

    gui, add, groupbox, % "xs y+14 h70 w" controlWidth - 2 * 10 - 1, % " "
    gui, add, checkbox, % "xp+10 yp hwndhTooltipFeedback "
        . "checked" iniFileSettings.tooltipFeedback.isActive, Tooltip
    fn := this.__OnTooltipPreview.Bind(this)
    gui, add, button, % "xp yp+23 h" button.height " w" controlWidth - 4 * 10 - 2
        . " hwndhTooltipPreview disabled" !iniFileSettings.tooltipFeedback.isActive
            , Tooltip preview 👀
    guicontrol, +g, % hTooltipPreview, % fn

    this.config.feedback.tooltip.isActive := iniFileSettings.tooltipFeedback.isActive

    gui, add, groupbox, % "xp-10 y+20 h140 w" controlWidth - 2 * 10 - 1, % " "
    gui, add, checkbox, % "xp+10 yp hwndhAudioFeedback "
        . "checked" iniFileSettings.audioFeedback.isActive, Audio
    

    fn := this.__OnSelectRecognitionFeedback.Bind(this)
    guicontrol, +g, % hTooltipFeedback, % fn
    guicontrol, +g, % hAudioFeedback, % fn

    this.config.feedback.audio.isActive := iniFileSettings.audioFeedback.isActive

    fn := this.__OnSelectVoiceProfile.Bind(this)

    selectableVoices := ""
    this.config.feedback.audio.voiceProfile := ""

    LogDebug("Retrieving available SAPI voices")

    sapiVoices := SAPI.SpVoice.GetVoices()
    
    LogDebug(format("Found {} voices", sapiVoices.Length()))

    for idx, voice in sapiVoices
    {
      selectableVoices .= voice.name "  |  " voice.language "^"
      
      if (voice.name = iniFileSettings.audioFeedback.voiceProfile)
      {
        this.config.feedback.audio.voiceProfile := voice.name
        this.owner.spVoice.SetVoice(voice.spObjectToken)
        this.owner.spVoice.Volume := iniFileSettings.audioFeedback.volume

        selectableVoices .= "^"
      }
      else if (idx == sapiVoices.Length())
      {
        ; Remove a lone separator after the last non-default entry to avoid an 
        ; unnecessary empty item at the end of the list
        selectableVoices := substr(selectableVoices, 1, -1)
      }
    }

    gui, add, text, xp yp+27 section, Voice
    gui +delimiter^
    gui, add, dropdownlist, % "yp-3 x+24 w" 248 " hwndhSelectVoice "
        . "disabled" !iniFileSettings.audioFeedback.isActive, % selectableVoices 
    gui +delimiter|
    guicontrol, +g, % hSelectVoice, % fn

    fn := this.__OnAdjustAudioVolume.Bind(this)
    gui, add, text, xs y+15 section, Volume
    gui, add, slider, % "ys-2 x+5 w" 264 " hwndhAudioVolume "
        . "disabled" (!iniFileSettings.audioFeedback.isActive || sapiVoices.Length() == 0)
            , % iniFileSettings.audioFeedback.volume
    guicontrol, +g, % hAudioVolume, % fn

    this.config.feedback.audio.volume := iniFileSettings.audioFeedback.volume

    gui, add, button, % "xs y+0 h" button.height " w" controlWidth - 4 * 10 - 2
        . " hwndhTestAudio disabled" (!iniFileSettings.audioFeedback.isActive
            || sapiVoices.Length() == 0), Test audio 🎧
    fn := this.__OnAudioTest.Bind(this)
    guicontrol, +g, % hTestAudio, % fn
    
    ; Add dummy blank text to increase height
    gui, font, s1
    gui, add, text, xm
    gui, font
    

    ; Set event callbacks
    fn := this.__ValidateOtherControls.Bind(this)
    guicontrol +g, % hUniqueVersion, % fn
    guicontrol +g, % hTemplateStorageType, % fn
    guicontrol +g, % hTemplateStoragePath, % fn
    guicontrol +g, % hKeywordFilePath, % fn

    fn := this.__OnBrowseTemplateStoragePath.Bind(this)
    guicontrol +g, % hBrowseStoragePath, % fn

    fn := this.__OnBrowseKeywordFile.Bind(this)
    guicontrol +g, % hBrowseKeywordFile, % fn


    ; NOTE: For whatever reason, a validation tooltip will not show unless a control
    ; has been assigned a handler
    fn := this.__NoOpHandler
    guicontrol +g, % hUniqueVersionValidation, % fn
    guicontrol +g, % hTemplateStorageTypeValidation, % fn
    guicontrol +g, % hTemplateStoragePathValidation, % fn
    guicontrol +g, % hKeywordFilePathValidation, % fn
    guicontrol +g, % hListenerHotkeyValidation, % fn
    guicontrol +g, % hFeedbackMessageHelp, % fn
    
    ; Focus the first control in the window
    guicontrol, focus, % GetNthControlInWindow(handle, 1)
    gui, show, % "autosize hide " (!a_iscompiled ? "x10": "")
    

    Log("Creating GUI tooltips")

    try
    {
      this.ctrl := 
      (join`s ltrim
        {
          uniqueVersion:
          {
            handle: hUniqueVersion,
            validationField:
            {
              handle: hUniqueVersionValidation
            },
            info:
            {
              text: "",
              title: ""
            }
          },
          templateStorageType:
          {
            handle: hTemplateStorageType,
            validationField:
            {
              handle: hTemplateStorageTypeValidation
            },
            info:
            {
              text: "",
              title: ""
            }
          },
          templateStoragePath:
          {
            handle: hTemplateStoragePath,
            validationField:
            {
              handle: hTemplateStoragePathValidation
            },
            browse:
            {
              handle: hBrowseStoragePath
            },
            info:
            {
              text: "",
              title: ""
            }
          },
          keywordFilePath:
          {
            handle: hKeywordFilePath,
            validationField:
            {
              handle: hKeywordFilePathValidation
            },
            browse:
            {
              handle: hBrowseKeywordFile
            }, 
            info:
            {
              text: "",
              title: ""
            }
          },
          listenerHotkey:
          {
            handle: activitySpeechRecognizer.hotkey.hCtrl,
            validationField:
            {
              handle: hListenerHotkeyValidation
            },
            info:
            {
              text: "",
              title: ""
            }
          },
          feedback:
          {
            message:
            {
              handle: hFeedbackMessage,
              help:
              {
                handle: hFeedbackMessageHelp,
                info:
                {
                  title: "Activity name placeholder",
                  text: "%1 in the message will refer to, and be replaced by,
                      the name of the recognized activity."
                }
              }
            },
            tooltip:
            {
              handle: hTooltipFeedback,
              preview:
              {
                handle: hTooltipPreview
              }
            },
            audio:
            {
              handle: hAudioFeedback,
              voice:
              {
                profile:
                {
                  handle: hSelectVoice
                },
                volume:
                {
                  handle: hAudioVolume
                },
                test:
                {
                  handle: hTestAudio
                }
              }
            }
          }
        }
      )

      this.ctrl.uniqueVersion.info.tooltip 
          := new Tooltip(this.ctrl.uniqueVersion.validationField.handle)
      this.ctrl.templateStorageType.info.tooltip 
          := new Tooltip(this.ctrl.templateStorageType.validationField.handle)
      this.ctrl.templateStoragePath.info.tooltip 
          := new Tooltip(this.ctrl.templateStoragePath.validationField.handle)
      this.ctrl.keywordFilePath.info.tooltip 
          := new Tooltip(this.ctrl.keywordFilePath.validationField.handle)
      this.ctrl.listenerHotkey.info.tooltip 
          := new Tooltip(this.ctrl.listenerHotkey.validationField.handle)
      this.ctrl.feedback.message.help.info.tooltip 
          := new Tooltip(this.ctrl.feedback.message.help.handle)
      this.ctrl.feedback.message.help.info.tooltip
          .Update(this.ctrl.feedback.message.help.info.text
              , this.ctrl.feedback.message.help.info.title)
      

      ; Add voice test start / end listener callbacks
      ; These are needed to help retain asynchronous playback during testing while 
      ; disabling and re-enabling the test button at right moments (enable at the 
      ; start of the test audio stream / disable at the end of the test audio stream)

      Log("Subscribing to SAPI Voice events")
      this.owner.spVoice.Subscribe(SAPI.SpVoice.Subscription.StartStream
          , this.__Class, this.__OnAudioTestStart.Bind(this))
      this.owner.spVoice.Subscribe(SAPI.SpVoice.Subscription.EndStream
          , this.__Class, this.__OnAudioTestEnd.Bind(this))

      Log("Validating control values")

      this.__ValidateOtherControls()

      if (iniFileSettings.hotkey == "")
      {
        this.__OnHotkeyAssignError(iniFileSettings.hotkey, "", 0)
      }
      else
      {
        validationResult := activitySpeechRecognizer.hotkey.ValidateAndActivate()

        if (validationResult.success)
        {
          this.__OnHotkeyChange(activitySpeechRecognizer.hotkey.keyName, "")
          /*
          this.__ValidateHotkeyControl({ success: true
              , attemptedHotkeyName: activitySpeechRecognizer.hotkey.keyName })
          */
        }
        else
        {
          validationResult.attemptedHotkeyName := iniFileSettings.hotkey
          this.__ValidateHotkeyControl(validationResult)
        }
      }

      this.handle := handle

      Log("Creating " this.owner.__Class " settings GUI finished")
    }
    catch ex
    {
      messagePrefix := "An unexpected error took place while initializing a settings GUI"
      gui, ActivitySpeechRecognizer: destroy

      LogError(messagePrefix ": " ex.Message)
      
      throw Exception(messagePrefix ".")
    }
  }


  ; =====================================
  ; PUBLIC METHODS
  ; =====================================

  Show()
  {
    if (this.handle)
    {
      if (this.owner.IsActive())
      {
        this.owner.Pause()
      }
      
      gui, % this.owner.__Class ": show"
      
      winset, disable, , % "ahk_id " this.toolkit.gui.handle
    }
  }

  ParseRecognitionFeedbackMessage(placeholderParam := "")
  {
    static defaultMessage := "This is an audio feedback test"

    guicontrolget, message, , % this.ctrl.feedback.message.handle

    if (instr(message, "%1"))
    {
      if (placeHolderParam == "")
      {
        placeHolderParam := "Placeholder"
      }

      message := regexreplace(message, "%1", placeHolderParam)
    }
    else if (message ~= "^\s*$")
    {
      message := defaultMessage
    }

    return message
  }


  ; =====================================
  ; CONTROL VALIDATION
  ; =====================================

  __ValidateHotkeyControl(validationResult)
  {
    #include %a_linefile%\..\SettingsGuiHotkeyControlValidationMessage.ahk    

    this.config.hotkey := validationResult.attemptedHotkeyName
    
    LogProperty("hotkey", validationResult.attemptedHotkeyName)

    
    Log("Validating the hotkey")

    if (validationResult.success)
    {
      ; Setting a hotkey succeeded

      LogDebug("The hotkey ok and set")

      successfulHotkeyMessage := validationMessage.ok.Clone()
      successfulHotkeyMessage.text := format(successfulHotkeyMessage.text
          , validationResult.attemptedHotkeyName)

      fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.ok
          , successfulHotkeyMessage)
    }
    else if (validationResult.attemptedHotkeyName == "")
    {
      ; Blank hotkey

      LogDebug("The hotkey is blank")

      fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
          , validationMessage.error.hotkeyNotAssigned)
    }
    else if (validationResult.reason == RevertableGuiHotkey.AssignErrorType.DUPLICATE)
    {
      ; Duplicate hotkey

      LogDebug(format("The hotkey is duplicate with another assigned for the task ""{}"""
          , validationResult.currentHotkey.description))

      duplicateHotkeyMessage := validationMessage.error.hotkeyAlreadyInUse.Clone()
      duplicateHotkeyMessage.text := format(duplicateHotkeyMessage.text
          , validationResult.attemptedHotkeyName, validationResult.currentHotkey.description)

      fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
          , duplicateHotkeyMessage)
    }
    else if (validationResult.reason == RevertableGuiHotkey.AssignErrorType.INVALID
        || validationResult.reason == RevertableGuiHotkey.AssignErrorType.ONLY_MODIFIERS)
    {
      ; Unsupported hotkey

      LogDebug("The hotkey is unsupported")

      unsupportedHotkeyMessage := validationMessage.error.invalidHotkey.Clone()
      unsupportedHotkeyMessage.text := format(unsupportedHotkeyMessage.text
          , validationResult.attemptedHotkeyName)

      fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
          , unsupportedHotkeyMessage)
    }
    else
    {
      throw Exception("Hotkey assign error type not implemented", , errorType)
    }
    
    fn.Call("listenerHotkey")

    this.isValidConfigHotkeyControl := validationResult.success

    Log("Hotkey validation result: " validationResult.success)
  }

  __ValidateOtherControls()
  {
    #include %a_linefile%\..\SettingsGuiControlValidationMessages.ahk
    static areValidationMessagesSet := false

    if (!areValidationMessagesSet)
    {
      validationMessage.uniqueVersion.error.blankOrWhitespace.text
          := format(validationMessage.uniqueVersion.error.blankOrWhitespace.text
              , UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.SQLiteStorage
                  .columnName.uniqueVersion)
      areValidationMessagesSet := true
    }

    guicontrolget, uniqueVersion, , % this.ctrl.uniqueVersion.handle
    this.config.uniqueVersion := uniqueVersion

    guicontrolget, templateStorageType, , % this.ctrl.templateStorageType.handle
    this.config.templateStorageType := templateStorageType
    
    guicontrolget, templateStoragePath, , % this.ctrl.templateStoragePath.handle
    this.config.templateStoragePath := templateStoragePath
    
    guicontrolget, keywordFilePath, , % this.ctrl.keywordFilePath.handle
    this.config.keywordFilePath := keywordFilePath

    LogProperty("uniqueVersion", uniqueVersion)
    LogProperty("templateStorageType", templateStorageType)
    LogProperty("templateStoragePath", templateStoragePath)
    LogProperty("keywordFilePath", keywordFilePath)

    templateStoragePath := regexreplace(templateStoragePath, "^(.*[^\\].*)\\*$", "$1")
    
    spaceDelimitedForbiddenFilePathChars := ForbiddenFilePathChars(" ")

    storageTypeClass := UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.XamlStorage.Type

    isValidGuiConfigOtherControls := true

    ; Validate unique version value

      Log("Validating the unique version value")

      if (uniqueVersion ~= "[\Q" ForbiddenFilePathChars() "\" "\E]")
      {
        ; Invalid character(s)

        LogDebug("Invalid characters in the unique version string")

        uniqueVersionForbiddenCharactersMessage := validationMessage.uniqueVersion
            .error.forbiddenCharacters.Clone()
        uniqueVersionForbiddenCharactersMessage.text 
            := format(uniqueVersionForbiddenCharactersMessage.text
                , spaceDelimitedForbiddenFilePathChars " \")
        
        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , uniqueVersionForbiddenCharactersMessage)
        
        isValidGuiConfigOtherControls := false
      }
      else if (uniqueVersion ~= "^\s*$")
      {
        ; Blank or whitespace

        LogDebug("The unique version is blank / whitespace")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , validationMessage.uniqueVersion.error.blankOrWhitespace)
        
        isValidGuiConfigOtherControls := false
      }
      else
      {
        ; OK

        LogDebug("The unique version is ok")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.ok
            , validationMessage.uniqueVersion.ok)
      }

      fn.Call("uniqueVersion")

    ; Validate storage type

      Log("Validating the template storage type")

      switch (templateStorageType)
      {
        case storageTypeClass.XMLFile, storageTypeClass.SQLite:

          guicontrol, enable, % this.ctrl.templateStoragePath.handle
          guicontrol, enable, % this.ctrl.templateStoragePath.browse.handle

          if (templateStorageType == storageTypeClass.SQLite)
          {
            try sqliteXamlStorage := new this.owner.base.Activity.SQLiteStorage(uniqueVersion)
            catch ex
            {
              switch (ex.Extra)
              {
                case this.owner.base.Activity.XamlStorage.ErrorCode.BlankUniqueVersion:
                  ; Can't run SQLite test with a blank unique version
                
                  LogDebug("SQLite validation halted due to a blank unique version string")
                  fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                      , validationMessage.templateStorageType.error.unableToTestStorageType.SQLite)
                  isValidGuiConfigOtherControls := false
                  goto exitStorageTypeValidation
                default:
                  ; SQLite DLL not found

                  LogDebug("SQLite DLL library file not available")

                  fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                      , { title: ex.Extra, text: ex.Message })
                  isValidGuiConfigOtherControls := false
                  goto exitStorageTypeValidation
              }
            }
          }

          ; OK

          LogDebug("Valid storage type: " templateStorageType)

          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.ok
              , validationMessage.templateStorageType.ok)
        case "":
          ; Blank storage type

          LogDebug("A blank storage type")

          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
              , validationMessage.templateStorageType.error.typeMissing)
          guicontrol, disable, % this.ctrl.templateStoragePath.handle
          guicontrol, disable, % this.ctrl.templateStoragePath.browse.handle
          isValidGuiConfigOtherControls := false
        default:
          ; Unrecognized storage type option

          LogDebug("Unrecognized storage type: " templateStorageType)

          unrecognizedStorageTypeMessage := validationMessage.templateStorageType
              .error.typeUnknown.Clone()
          unrecognizedStorageTypeMessage.text := format(unrecognizedStorageTypeMessage.text
              , templateStorageType)
          
          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
              , unrecognizedStorageTypeMessage)
          
          guicontrol, disable, % this.ctrl.templateStoragePath.handle
          guicontrol, disable, % this.ctrl.templateStoragePath.browse.handle
          isValidGuiConfigOtherControls := false
      }

      exitStorageTypeValidation:
      fn.Call("templateStorageType")

    ; Validate storage path

      Log("Validating the template storage path")

      fn := 0
      if (!(templateStoragePath ~= "i)^(?:[A-Z]:)?[^\Q" ForbiddenFilePathChars() "\E]*$"))
      {
        ; Invalid character(s)

        LogDebug("Invalid characters in given template storage path")

        templateStoragePathForbiddenCharactersMessage := validationMessage.templateStoragePath
            .error.forbiddenCharacters.Clone()
        templateStoragePathForbiddenCharactersMessage.text 
            := format(templateStoragePathForbiddenCharactersMessage.text
                , spaceDelimitedForbiddenFilePathChars)
        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , templateStoragePathForbiddenCharactersMessage)
        isValidGuiConfigOtherControls := false
      }
      else if (templateStoragePath ~= "^\s*$")
      {
        ; Path blank or whitespace

        LogDebug("The template storage path is blank / whitespace")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , validationMessage.templateStoragePath.error.pathMissing)
        isValidGuiConfigOtherControls := false
      }
      else if ((templateStorageType == storageTypeClass.XMLFile 
              && (!instr(fileexist(templateStoragePath), "D")))
          || (templateStorageType == storageTypeClass.SQLite 
              && fileexist(templateStoragePath) ~= "^D?$"))
      {
        ; Path not found

        LogDebug("The template storage path not found")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , validationMessage.templateStoragePath.error.pathNotFound[templateStorageType])
        isValidGuiConfigOtherControls := false
      }
      else
      {
        if (templateStorageType == storageTypeClass.XMLFile 
            && instr(fileexist(templateStoragePath), "D"))
        {
          if (!instr(fileexist(templateStoragePath "\" uniqueVersion), "D"))
          {
            ; Unique version subdir not found

            LogDebug("Unique version subdirectory part of the template storage path not found")

            templateStoragePathVersionStringNotFoundMessage := validationMessage
                .templateStoragePath.error.pathWithVersionStringNotFound[templateStorageType]
                    .Clone()
            templateStoragePathVersionStringNotFoundMessage.text 
                := format(templateStoragePathVersionStringNotFoundMessage.text, uniqueVersion)
            
            fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
              , templateStoragePathVersionStringNotFoundMessage)
            isValidGuiConfigOtherControls := false
          }
          else
          {
            ; Check for presence of XML files in the directory
            ; Also capture a few activity names

            xmlFileCount := 0
            activityNames := []

            LogDebug("Retrieving XML files in the found template storage path directory")

            loop, files, % templateStoragePath "\" uniqueVersion "\*.xml"
            {
              ++xmlFileCount
              activityNameCandidate := regexreplace(a_loopfilename, "i)^.*?([^.]+)\.xml$", "$1")
              
              try
              {
                ; Prioritize the 2nd line in the file, if any
                filereadline, activityNameCandidate, % a_loopfilefullpath, 2
              }
              catch ex
              {
                if (ex.Message != 1)
                {
                  ; Exception due to a reason other than the file not having a second line
                  ; that specifies the alternative name the activity should be recognized as
                  outputdebug % ex.Message
                  throw ex
                }
              }

              activityNames.Push(activityNameCandidate)
            }

            if (xmlFileCount > 0)
            {
              ; OK

              LogDebug(xmlFileCount " XML files found in the directory")
            }
            else
            {
              ; Path found but no XML files under a subdir matching the unique version string

              LogWarn("No XML files found in the directory")

              templateStoragePathFilesNotFoundMessage := validationMessage
                  .templateStoragePath.warn.filesNotFound[templateStorageType].Clone()
              templateStoragePathFilesNotFoundMessage.text
                  := format(templateStoragePathFilesNotFoundMessage.text
                      , templateStoragePath "\" uniqueVersion)
              
              fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.warn
                , templateStoragePathFilesNotFoundMessage)
            }
          }
        }
        else if (templateStorageType == storageTypeClass.SQLite)
        {
          ; Test the table name

          if (!isobject(sqliteXamlStorage))
          {
            ; Instantiating an SQLite XAML storage object failed earlier → set the error 
            ; and skip the test

            fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                , validationMessage.templateStoragePath.error.unableToTestFile.SQLite)
            isValidGuiConfigOtherControls := false
            goto exitStoragePathValidation
          }
          
          Log(format("Validating the given template storage path as an SQLite file "
              . "candidate ""{}""", templateStoragePath))
          
          ; Will succeed even with a bogus file
          sqliteXamlStorage.Open(templateStoragePath)

          try
          {
            LogDebug(format("Querying for the required activity SQL table ""{}"" and the "
                . "column ""{}""", sqliteXamlStorage.tableName
                    , sqliteXamlStorage.base.DefaultColumnName.uniqueVersion))

            if (!sqliteXamlStorage.TestTable())
            {
              ; Table not found
              
              LogDebug("SQL table not found in the database file")

              templateStoragePathTableNotFoundMessage := validationMessage.templateStoragePath
                  .error.tableNotFound.SQLite.Clone()
              
              templateStoragePathTableNotFoundMessage.text
                  := format(templateStoragePathTableNotFoundMessage.text
                      , sqliteXamlStorage.tableName)
              fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                  , templateStoragePathTableNotFoundMessage)
              isValidGuiConfigOtherControls := false
            }
            else if (!sqliteXamlStorage.TestColumn())
            {
              ; Column not found
              
              LogDebug("Column not found in the table")

              templateStoragePathColumnNotFoundMessage := validationMessage.templateStoragePath
                  .error.columnNotFound.SQLite.Clone()
              
              templateStoragePathColumnNotFoundMessage.text
                  := format(templateStoragePathColumnNotFoundMessage.text
                      , sqliteXamlStorage.tableName
                      , sqliteXamlStorage.base.defaultColumnName.uniqueVersion)
              fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                  , templateStoragePathColumnNotFoundMessage)
              isValidGuiConfigOtherControls := false
            }
          }
          catch ex
          {
            if (ex.Extra == SQLiteDB.ReturnCode("SQLITE_NOTADB"))
            {
              ; File is not a valid database

              LogDebug("The template storage path is not a valid SQLite database file")

              fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                  , validationMessage.templateStoragePath.error.invalidDatabaseFile.SQLite)
            }
            else
            {
              ; Other SQLite error

              templateStoragePathUnspecifiedErrorMessage := validationMessage
                  .templateStoragePath.error.unspecifiedError.SQLite.Clone()

              templateStoragePathUnspecifiedErrorMessage.text
                  := format(templateStoragePathUnspecifiedErrorMessage.text
                      , ex.Extra, ex.Message)
              
              LogDebug(templateStoragePathUnspecifiedErrorMessage.text)

              fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
                  , templateStoragePathUnspecifiedErrorMessage)
            }

            isValidGuiConfigOtherControls := false
          }
        }
        
        if (!fn)
        {
          ; OK

          LogDebug("Template storage path ok")
          
          templateStoragePathOkMessage := validationMessage.templateStoragePath.ok.SQLite

          if (templateStorageType == storageTypeClass.XMLFile)
          {
            activityNameListing := ""
            for index, activityName in activityNames
            {
              if (shouldBreakOutNextIteration)
              {
                activityNameListing .= "`r`n..."
                break
              }

              activityNameListing .= "`r`n• " activityName

              if (index > 5)
              {
                shouldBreakOutNextIteration := true
              }
            }

            templateStoragePathOkMessage := validationMessage.templateStoragePath.ok.XMLFile
                .Clone()
            templateStoragePathOkMessage.text := format(templateStoragePathOkMessage.text
                , xmlFileCount, activityNameListing)
          }

          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.ok
              , templateStoragePathOkMessage)
        }
      }

      exitStoragePathValidation:
      fn.Call("templateStoragePath")

    ; Validate keyword file path

      Log("Validating the keyword file path")

      if (!(keywordFilePath ~= "i)^(?:[A-Z]:)?[^\Q" ForbiddenFilePathChars() "\E]*$"))
      {
        ; Invalid character(s)

        LogDebug("Invalid characters in the keyword file path")

        keywordFilePathForbiddenCharactersMessage := validationMessage.keywordFilePath
            .error.forbiddenCharacters.Clone()
        keywordFilePathForbiddenCharactersMessage.text 
            := format(keywordFilePathForbiddenCharactersMessage.text
                , spaceDelimitedForbiddenFilePathChars)
        
        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , keywordFilePathForbiddenCharactersMessage)
        isValidGuiConfigOtherControls := false
      }
      else if (keywordFilePath ~= "^\s*$")
      {
        ; Path blank or whitespace

        LogDebug("The keyword file path is blank / whitespace")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , validationMessage.keywordFilePath.error.fileMissing)
        isValidGuiConfigOtherControls := false
      }
      else if (fileexist(keywordFilePath) ~= "^(.*D.*)?$") ; Nothing or a directory found
      {
        ; File not found

        LogDebug("The keyword file not found")

        fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.error
            , validationMessage.keywordFilePath.error.fileNotFound)
        isValidGuiConfigOtherControls := false
      }
      else
      {
        LogDebug("Found a keyword file candidate")

        ; Capture keyword count and a few keywords
        fileKeywordCount := 0
        keywordsInFile := []
        loop, read, % keywordFilePath
        {
          if (!(a_loopreadline ~= "^\s*$"))
          {
            ; Non-whitespace line

            ++fileKeywordCount
            keywordsInFile.Push(trim(a_loopreadline))
          }
        }

        if (fileKeywordCount == 0)
        {
          ; No keywords

          LogWarn("No keywords found in the file")

          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.warn
              , validationMessage.keywordFilePath.error.noKeywordsInFile)
        }
        else
        {
          ; OK

          LogDebug(format("Keyword file appears ok. Found {} keyword(s) in the file"
              , fileKeywordCount))

          shouldBreakOutNextIteration := false
          keywordListing := ""
          for idx, keywordInFile in keywordsInFile
          {
            if (shouldBreakOutNextIteration)
            {
              keywordListing .= "`r`n..."
              break
            }

            keywordListing .= "`r`n• " keywordInFile

            if (idx > 5)
            {
              shouldBreakOutNextIteration := true
            }
          }

          keywordOkMessage := validationMessage.keywordFilePath.ok.Clone()
          keywordOkMessage.text := format(keywordOkMessage.text, fileKeywordCount
              , keywordListing)
          
          fn := this.__SetValidationField.Bind(this, this.base.FieldValidationSymbol.ok
              , keywordOkMessage)
        }

        this.config.keywords := keywordsInFile
      }

      fn.Call("keywordFilePath")

    this.isValidConfigOtherControls := isValidGuiConfigOtherControls

    Log("GUI controls other than the hotkey config validation result: " 
        . isValidGuiConfigOtherControls)
  }

  __SetValidationField(validationSymbol, info, ctrlId)
  {
    LogMethod(a_thisfunc, validationSymbol, info.text, ctrlId)

    ctrl := this.ctrl[ctrlId]

    ctrl.info.title := info.title
    ctrl.info.text := info.text

    switch (validationSymbol)
    {
      case this.base.FieldValidationSymbol.ok:
        fontStyle := "cgreen"
        ctrl.info.icon := ValidationTooltip.IconType.Info
      case this.base.FieldValidationSymbol.warn:
        fontStyle := "cff7700 w1000"
        ctrl.info.icon := ValidationTooltip.IconType.Warning
      case this.base.FieldValidationSymbol.error:
        fontStyle := "cred"
        ctrl.info.icon := ValidationTooltip.IconType.Error
      default:
        throw Exception("Invalid validation symbol specifier", -2, validationSymbol)
    }

    ; Draw the symbol with appropriate font styling
    gui, ActivitySpeechRecognizer: font, % fontStyle " s" UiPath.Studio.Toolkit.GlobalFontSize
    guicontrol, font, % ctrl.validationField.handle
    guicontrol,     , % ctrl.validationField.handle, % validationSymbol
    guicontrol, show, % ctrl.validationField.handle
    gui, ActivitySpeechRecognizer: font, % "cblack s" UiPath.Studio.Toolkit.GlobalFontSize

    ; Update tooltip
    ctrl.info.tooltip.Update(ctrl.info.text, ctrl.info.title, ctrl.info.icon)
  }


  ; =====================================
  ; GUI CONTROL EVENTS 
  ; =====================================

  __OnBrowseKeywordFile(params*)
  {
    fileselectfile, keywordFileFullPath, 1, % a_scriptdir, Select keyword file
    if (errorlevel)
    {
      ; Dialog dismissed
      return
    }

    guicontrol, , % this.ctrl.keywordFilePath.handle, % keywordFileFullPath
  }

  __OnBrowseTemplateStoragePath(params*)
  {
    guicontrolget, templateStorageType, , % this.ctrl.templateStorageType.handle

    switch (templateStorageType)
    {
      case UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.XamlStorage.Type.XMLFile:
        fileselectfolder, path, % "*" a_scriptdir, 3
            , Select XML file activity template storage folder
      case UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity.XamlStorage.Type.SQLite:
        fileselectfile, path, 1, % a_scriptdir
            , Select SQLite activity template database file, SQLite database file (*.db)
      default:
        throw Exception("Unknown template storage type", -2, this.templateStorageType)
    }

    if (errorlevel)
    {
      ; Dialog dismissed
      return
    }
    
    guicontrol, , % this.ctrl.templateStoragePath.handle, % regexreplace(path, "\\*$")
  }

  __OnHotkeyChange(newHotkeyName, currentHotkey)
  {
    static combinationHotkeyPattern := "^\s*(.+)\s+&\s+.+$"

    if (regexmatch(newHotkeyName, combinationHotkeyPattern, match))
    {
      ; New hotkey is a combination key X & Y → activate a new hotkey for Y to send itself,
      ; which, as stated in AHK docs, will allow a solitary key up event to still produce 
      ; the native function of the key

      prefixKey := match1
      fn := this.__SendCombinationKeyUpEvent.Bind(this, prefixKey)
      hotkey, % prefixKey, % fn
    }

    if (currentHotkey != "")
    {
      if (regexmatch(currentHotkey.keyName, combinationHotkeyPattern, match))
      {
        ; Old hotkey was a combination key X & Y for which sending itself has been activated 
        ; earlier → disable to restore back the normal operation of the key
        prefixKey := match1
        hotkey, % prefixKey, off
      }
    }
    
    this.__ValidateHotkeyControl({ success: true, attemptedHotkeyName: newHotkeyName })
  }

  __SendCombinationKeyUpEvent(hotkey)
  {
    LogMethod(a_thisfunc, hotkey)
    
    send % hotkey
  }

  __OnHotkeyAssignError(newHotkeyName, currentHotkey, errorType)
  {
    hotkeyValidationResult :=
    (join
      { 
        success: false,
        reason: errorType,
        attemptedHotkeyName: newHotkeyName,
        currentHotkey: currentHotkey
      }
    )

    this.__ValidateHotkeyControl(hotkeyValidationResult)
  }

  __OnSelectRecognitionFeedback(hCtrl)
  {
    guicontrolget, isCheckboxTicked, , % hCtrl

    switch (hCtrl)
    {
      case this.ctrl.feedback.tooltip.handle:
        this.config.feedback.tooltip.isActive := isCheckboxTicked
        guicontrol, % "enable" isCheckboxTicked, % this.ctrl.feedback.tooltip.preview.handle
      case this.ctrl.feedback.audio.handle:
        this.config.feedback.audio.isActive := isCheckboxTicked
        guicontrol, % "enable" isCheckboxTicked, % this.ctrl.feedback.audio.voice.profile.handle
        guicontrol, % "enable" isCheckboxTicked, % this.ctrl.feedback.audio.voice.volume.handle
        guicontrol, % "enable" isCheckboxTicked, % this.ctrl.feedback.audio.voice.test.handle

        if (isCheckboxTicked)
        {
          this.__OnSelectVoiceProfile(this.ctrl.feedback.audio.voice.profile.handle)
        }
    }
  }

  __OnTooltipPreview()
  {
    message := this.ParseRecognitionFeedbackMessage()

    this.owner.__DisplayTimedTooltip(message)
  }

  __OnSelectVoiceProfile(hCtrl)
  {
    guicontrolget, selectedVoiceEntry, , % hCtrl

    selectedVoiceName := strsplit(selectedVoiceEntry, "|", " " a_tab)[1]
    
    for k, voice in SAPI.SpVoice.GetVoices()
    {
      if (voice.name == selectedVoiceName)
      {
        this.owner.spVoice.SetVoice(voice.spObjectToken)
        this.config.feedback.audio.voiceProfile := selectedVoiceName
        return
      }
    }
    
    throw Exception(format("Selected voice ""{1}"" not found among installed voices."
        , selectedVoiceName))
  }

  __OnAdjustAudioVolume(hCtrl)
  {
    guicontrolget, newVolume, , % hCtrl

    this.owner.spVoice.Volume := newVolume
    this.config.feedback.audio.volume := newVolume
  }
  
  __OnAudioTest()
  {
    message := this.ParseRecognitionFeedbackMessage()

    this.owner.spVoice.Speak(message)
  }

  ; Called by SAPI SpVoice event listening mechanism
  __OnAudioTestStart()
  {
    guicontrol, disable, % this.ctrl.feedback.audio.voice.test.handle
  }

  ; Called by SAPI SpVoice event listening mechanism
  __OnAudioTestEnd()
  {
    guicontrol, enable, % this.ctrl.feedback.audio.voice.test.handle
  }

  __NoOpHandler()
  {
  }


  ; =====================================
  ; GUI EVENTS
  ; =====================================

  __OnEscape()
  {
    this.__OnClose()
    gui, hide
  }

  __OnClose()
  {
    winset, enable, , % "ahk_id " this.toolkit.gui.handle
    
    isValidConfig := this.isValidConfigHotkeyControl && this.isValidConfigOtherControls
    if (isValidConfig)
    {
      if (this.owner.IsPaused())
      {
        this.owner.Resume(shouldReconfigure := true)
      }
    }
    else if (this.owner.IsPaused())
    {
      this.owner.Deactivate()
    }

    this.toolkit.OnModuleSettingsGuiClose(this.owner.__Class, isValidConfig)
  }
}