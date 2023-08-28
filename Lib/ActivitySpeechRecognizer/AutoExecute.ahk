#requires AutoHotkey v1.1

#include <WINAPI\ClipboardFormats>
#include <SQLite\SQLiteDB>
#include <SAPI\BaseSpeechRecognizer>
#include %a_linefile%\..\ActivitySpeechRecognizer.ahk
#include <Tooltip>


; Attach ActivitySpeedRecognizer into UiPath.Studio.Toolkit class
UiPath.Studio.Toolkit.ActivitySpeechRecognizer := ActivitySpeechRecognizer
ActivitySpeechRecognizer := ""

Log("======== Starting to initialize a new module: """ 
    . UiPath.Studio.Toolkit.ActivitySpeechRecognizer.__Class """ ========")

; Instantiate a new speech recognizer
toolkit.activitySpeechRecognizer := new UiPath.Studio.Toolkit.ActivitySpeechRecognizer(
(join c
    toolkit, ; toolkitInstance
    toolkit.iniFileFullPath, ; iniFileFullPath
    toolkit.base.ModuleState.Running.text, ; moduleRunningStateText
    toolkit.base.ModuleState.Paused.text, ; modulePausedStateText
    toolkit.base.ModuleState.NotRunning.text ; moduleNotRunningStateText
))

; Add as a module to the application
toolkit.AddModule(
(join c
    toolkit.activitySpeechRecognizer.__Class, ; moduleId

    toolkit.activitySpeechRecognizer.gui.handle, ; hModuleSettingsGui

    toolkit.activitySpeechRecognizer.ActivateWithConfig.Bind( ; startButtonEventHandler
        toolkit.activitySpeechRecognizer), 
        
    toolkit.activitySpeechRecognizer.Deactivate.Bind( ; stopButtonEventHandler
        toolkit.activitySpeechRecognizer),
        
    toolkit.activitySpeechRecognizer.SettingsGui.Show.Bind( ; configButtonEventHandler
        toolkit.activitySpeechRecognizer.gui),
        
    toolkit.activitySpeechRecognizer.title, ; moduleHeadingText
    
    ParseVersionNumberString(UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Version.Number ; moduleVersionNumber
        , UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Version.Stage), 
    
    toolkit.activitySpeechRecognizer.iniFile.lastState ; initRunState
            == toolkit.base.ModuleState.Running.text,
    
    toolkit.activitySpeechRecognizer.gui.isValidConfigHotkeyControl && ; moduleValidationResult
        toolkit.activitySpeechRecognizer.gui.isValidConfigOtherControls)
)

; Set OnExit callback
OnExit(toolkit.activitySpeechRecognizer.OnExit.Bind(toolkit.activitySpeechRecognizer))

Log("======== Module """ UiPath.Studio.Toolkit.ActivitySpeechRecognizer.__Class 
    . """ initialization complete ========")