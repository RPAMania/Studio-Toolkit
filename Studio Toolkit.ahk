/************************************************************************
 * @description UiPath Studio utility tools to weed recurrence out of RPA development
 * @file UiPath Studio Toolkit.ahk
 * @author TJay🐦
 * @date 2024/02/10
 * @version 1.0.1
 ***********************************************************************/
/*
*/
;@Ahk2Exe-SetMainIcon rpamania.ico
;@Ahk2Exe-SetProductName UiPath Studio Toolkit
;@Ahk2Exe-SetCopyright RPA Mania
;@Ahk2Exe-SetCompanyName RPA Mania

#requires AutoHotkey v1.1
#notrayicon
#singleinstance off
#include <RevertableGuiHotkey>
#include <Logger>
#include <ScriptObj>

critical, 5000

setworkingdir % a_scriptdir
fileencoding, utf-8

; Prevent a multiple instances & display the first instance GUI instead
ForceSingleInstance()

; Prepare the logging setup
logMessageMaxDisplayChars = %1%
logMaxLogFileLineCount = %2%
; try
; {
global l := SetupLogging(Logger.LogLevel.Debug
    , UiPath.Studio.Toolkit.GithubBaseUrl "/issues"
    , logMessageMaxDisplayChars
    , logMaxLogFileLineCount)
; }
/*
catch ex
{
  msgbox % ex.Message "`r`n`r`nThe application will now exit."
  exitapp
}
*/

; Save original clipboard
oldClipboard := clipboardall


Log("======== Starting to initialize the app ========")
toolkit := new UiPath.Studio.Toolkit()

#include <ActivitySpeechRecognizer\AutoExecute>

toolkit.DisplaySettingsGui()
Log("======== Application initialization complete ========")

script.version := UiPath.Studio.Toolkit.Version.Number

critical, off

class UiPath
{
  class Studio
  {
    class Toolkit
    {
      static VendorName := "RPA Mania"
      static TitleHeading := GetScriptName() " engine"
      static Version := { Number: "1.0.1", Stage: "" }
      static GithubBaseUrl := "https://github.com/RPAMania/Studio-Toolkit"
      ;@Ahk2Exe-SetVersion 1.0.1
      static GlobalFontSize := 11
      static StartStopButtonText := { Start: "Start", Stop: "Stop" }
      static ModuleState :=
      (join c
        {
          Running:
          {
            text: "Running",
            color: "009933" ; green
          },
          NotRunning:
          {
            text: "Not running",
            color: "red"
          },
          Paused:
          {
            text: "Paused",
            color: "ddaa11" ; dark yellow
          },
          FontStyle: "bold"
        }
      )

      __Get(key)
      {
        keyFirstChar := substr(key, 1, 1)
        stringlower, keyFirstCharLower, keyFirstChar
        if (keyFirstChar == keyFirstCharLower)
        {
          ; Same case → non-dynamic property
          LogObjectPropertyDynamic(this, key)
        }
      }

      __Call(methodName, params*)
      {
        LogObjectMethodDynamic(this, methodName, params*)
      }

      __New()
      {
        LogMethod(a_thisfunc)

        this.__CreateTrayMenu()

        gui, ToolkitSettings:new, , % this.base.TitleHeading " | "
            .  ParseVersionNumberString(this.base.Version.Number, this.base.Version.Stage) 
            . " – " this.base.VendorName
        
        gui, +lastfound -minimizebox
        gui, font, % "s" this.base.GlobalFontSize
        
        this.module := {}
        this.iniFileFullPath := regexreplace(a_scriptfullpath, "\.[^.]+$", ".ini")
        this.gui := 
        (join
          {
            dimension:
            {
              containerControl:
              { 
                width: 350
              }, 
              button:
              {
                width: 100,
                height: 32
              }  
            }, 
            handle: winexist()
          }
        )
      }

      
      DisplaySettingsGui(shouldFocusFirstControl := true)
      {
        if (shouldFocusFirstControl)
        {
          guicontrol, ToolkitSettings: focus, % GetNthControlInWindow(winexist(), 1)
        }

        gui, ToolkitSettings: show, % "autosize " (!a_iscompiled ? "x10" : "")
      }

      ; =====================================
      ; PUBLIC METHODS FOR HANDLING MODULES
      ; =====================================

      ; Add a module to the main GUI
      AddModule(moduleId, hModuleSettingsGui
          , startButtonEventHandler, stopButtonEventHandler
          , configButtonEventHandler, moduleHeadingText, moduleVersionNumber
          , initRunState, moduleValidationResult)
      {
        static buttonWidth := 100

        gui, ToolkitSettings: add, groupbox, % "xm"
            . " w" (this.gui.dimension.containerControl.width) " h66"
                , % moduleHeadingText " | " moduleVersionNumber

        gui, ToolkitSettings: add, button, % "yp+20 xp+10"
            . " w" this.gui.dimension.button.width 
            . " h" this.gui.dimension.button.height
            . " section disabled" (!moduleValidationResult)
            . " hwndhStartStopButton" moduleId, % this.base.StartStopButtonText.Start
        gui, ToolkitSettings: add, button, % "x+0 ys w28"
            . " h" this.gui.dimension.button.height " right"
            . " hwndhConfigButton" moduleId, % "⚙ "
        gui, ToolkitSettings: add, text, ys+9 x+85, State:
        gui, ToolkitSettings: font, % "c" this.base.ModuleState.NotRunning.color 
            . " " this.ModuleState.FontStyle
        gui, ToolkitSettings: add, text, % "ys+9 x+5 hwndhStateText" moduleId
            ; Use the longest entry first to reserve enough width, and then set the correct state
            , % this.base.ModuleState.NotRunning.text
        
        gui, ToolkitSettings: font
        gui, ToolkitSettings: font, % "s" this.base.GlobalFontSize

        controlVar := "hStartStopButton" moduleId
        fnStartStopButton := this.__OnModuleStartStopButton.Bind(this, moduleId
            , startButtonEventHandler, stopButtonEventHandler)
        guicontrol, +g, % %controlVar%, % fnStartStopButton
        this[controlVar] := %controlVar%

        controlVar := "hConfigButton" moduleId
        fnConfigButton := this.__OnModuleConfigButton.Bind(this, moduleId, configButtonEventHandler)
        guicontrol, +g, % %controlVar%, % fnConfigButton

        controlVar := "hStateText" moduleId
        this[controlVar] := %controlVar%

        ; Default to not running
        this.module[moduleId] := { state: this.base.ModuleState.NotRunning.text
            , handle: hModuleSettingsGui }

        ; Only allow auto-restoring state back to running on startup if both are true:
        ; - was previously running/paused on exit
        ; - the module validates ok
        if (initRunState && moduleValidationResult)
        {
          this.__OnModuleStartStopButton(moduleId, startButtonEventHandler, 0)
        }
      }

      EnableModuleStartButton(moduleId)
      {
        hStateText := this["hStateText" moduleId]
        hStartStopButton := this["hStartStopButton" moduleId]

        if (hStartStopButton)
        {
          guicontrol, enable, % hStartStopButton
        }
        else
        {
          throw Exception("Received an enable start button request of an unknown section."
              , -2, moduleId)
        }
      }

      DisableModuleStartButton(moduleId)
      {
        hStateText := this["hStateText" moduleId]
        hStartStopButton := this["hStartStopButton" moduleId]

        if (hStartStopButton)
        {
          guicontrol, disable, % hStartStopButton
        }
        else
        {
          throw Exception("Received a disable start button request of an unknown section."
              , -2, moduleId)
        }

        guicontrolget, state, , hStateText
        switch (state)
        {
          case this.base.ModuleState.Running.text:
          case this.base.ModuleState.Paused.text:
          default: return
        }

        ; Set to not running
        guicontrol, % hStateText, % this.base.ModuleState.NotRunning.text
        gui, ToolkitSettings: font, % "c" this.base.ModuleState.NotRunning.color 
              . " s" this.base.GlobalFontSize " " this.ModuleState.FontStyle
        guicontrol, font, % hStateText
      }

      OnModuleSettingsGuiClose(moduleId, moduleValidationResult)
      {
        if (moduleValidationResult)
        {
          this.EnableModuleStartButton(moduleId)

          if (this.__IsModulePaused(moduleId))
          {
            this.__ResumeModule(moduleId)
          }
        }
        else
        {
          this.DisableModuleStartButton(moduleId)
          this.__StopModule(moduleId)
        }
      }


      ; =====================================
      ; MODULE STATE METHODS
      ; =====================================

      ; Get the module state (running/paused/not running)
      CurrentModuleState[moduleId]
      {
        get
        {
          LogProperty(this.base.__Class ".CurrentModuleState", this.module[moduleId].state)

          return this.module[moduleId].state
        }
      }

      __StartModule(moduleId)
      {
        hStartStopButton := this["hStartStopButton" moduleId]
        hStateText := this["hStateText" moduleId]

        guicontrol, , % hStartStopButton, % this.base.StartStopButtonText.Stop
        guicontrol, , % hStateText, % this.base.ModuleState.Running.text
        gui, ToolkitSettings: font, % "c" this.base.ModuleState.Running.color 
            . " s" this.base.GlobalFontSize " " this.ModuleState.FontStyle
        guicontrol, font, % hStateText

        this.module[moduleId].state := this.base.ModuleState.Running.text
      }

      __StopModule(moduleId)
      {
        hStartStopButton := this["hStartStopButton" moduleId]
        hStateText := this["hStateText" moduleId]

        guicontrol, , % hStartStopButton, % this.base.StartStopButtonText.Start
        guicontrol, , % hStateText, % this.base.ModuleState.NotRunning.text
        gui, ToolkitSettings: font, % "c" this.base.ModuleState.NotRunning.color 
            . " s" this.base.GlobalFontSize " " this.ModuleState.FontStyle
        guicontrol, font, % hStateText

        this.module[moduleId].state := this.base.ModuleState.NotRunning.text
      }
      
      __ResumeModule(moduleId)
      {
        hStateText := this["hStateText" moduleId]

        guicontrol, , % hStateText, % this.base.ModuleState.Running.text
        gui, ToolkitSettings: font, % "c" this.base.ModuleState.Running.color 
            . " s" this.base.GlobalFontSize " " this.ModuleState.FontStyle
        guicontrol, font, % hStateText

        this.module[moduleId].state := this.base.ModuleState.Running.text
      }

      __PauseModuleIfRunning(moduleId)
      {
        hStateText := this["hStateText" moduleId]

        if (this.__IsModuleRunning(moduleId))
        {
          gui, ToolkitSettings: font, % "c" this.base.ModuleState.Paused.color 
              . " s" this.base.GlobalFontSize " " this.ModuleState.FontStyle
          guicontrol, font, % hStateText
          guicontrol, , % hStateText, % this.base.ModuleState.Paused.text
          this.module[moduleId].state := this.base.ModuleState.Paused.text
        }
      }

      __IsModuleRunning(moduleId)
      {
        return this.CurrentModuleState[moduleId] == this.base.ModuleState.Running.text
      }

      __IsModulePaused(moduleId)
      {
        return this.CurrentModuleState[moduleId] == this.base.ModuleState.Paused.text
      }

      __IsModuleStopped(moduleId)
      {
        return this.CurrentModuleState[moduleId] == this.base.ModuleState.NotRunning.text
      }

      
      ; =====================================
      ; GUI CONTROL EVENT HANDLERS
      ; =====================================

      __OnModuleConfigButton(moduleId, configEventHandler)
      {
        LogMethod(a_thisfunc, moduleId)

        this.__PauseModuleIfRunning(moduleId)

        configEventHandler.Call()
      }

      __OnModuleStartStopButton(moduleId, startEventHandler, stopEventHandler)
      {
        LogMethod(a_thisfunc, moduleId)

        if (this.__IsModuleRunning(moduleId))
        {
          this.__StopModule(moduleId)
          stopEventHandler.Call()
        }
        else if (this.__IsModuleStopped(moduleId))
        {
          this.__StartModule(moduleId)
          startEventHandler.Call()
        }
      }


      ; =====================================
      ; TRAY MENU METHODS
      ; =====================================

      __CreateTrayMenu()
      {
        menu, tray, nostandard
        if (!a_iscompiled)
        {
          menu, tray, icon, rpamania.ico
        }
        menu, tray, tip, % GetScriptName() " – RPA Mania"

        fn := this.DisplaySettingsGui.Bind(this, false)
        menu, tray, add, Show, % fn

        menu, tray, add

        fn := this.__CheckUpdate.Bind(this, false)
        menu, tray, add, Check for updates, % fn
        
        fn := this.__ShowAuthorWebsite.Bind(this)
        menu, tray, add, RPA Mania website, % fn

        menu, tray, add

        fn := this.__ExportDebugLog.Bind(this)
        menu, tray, add, Export debug log, % fn

        menu, tray, add

        fn := this.__Exit.Bind(this)
        menu, tray, add, Exit, % fn

        menu, tray, default, Show

        menu, tray, icon
      }

      __CheckUpdate()
      {
        static confirmationExtraMessage := "`nUpdating will overwrite the settings file '{1}'"
            . " with default content.`n`n" 
        
        try
        {
          script.Update(format(confirmationExtraMessage, this.iniFileFullPath)
              , this.base.GithubBaseUrl "/releases/latest")
        }
        catch ex
        {
          if (ex.HasKey("msg"))
          {
            Log(format("Update check ended with the code {}, message: {}", ex.code, ex.msg))
            
            switch (ex.code)
            {
              case 6: ; ERR_CURRENTVERSION
                msgbox % ex.msg
              case 7, 8: ; 7 == ERR_MSGTIMEOUT, 8 == ERR_USRCANCEL
              default:
                msgbox % "There was an error during checking for updates."
            }
          }
          else
          {
            throw ex
          }
        }
      }

      __ShowAuthorWebsite()
      {
        run, https://www.rpamania.net
      }

      __ExportDebugLog()
      {
        global l

        l.ExportDebugLogFile()
      }

      __Exit()
      {
        ; Restore original clipboard contents before exiting
        clipboard := oldClipboard

        if (!fileexist(this.iniFileFullPath))
        {
          fileappend, % "", % this.iniFileFullPath
        }

        exitapp
      }


      ; =====================================
      ; GUI EVENT HANDLERS
      ; =====================================

      OnSettingsGuiClose()
      {
        wasModuleGuiClosed := false

        oldHiddenWindowSetting := a_detecthiddenwindows
        detecthiddenwindows, off

        for moduleId, module in this.module
        {
          if (module.state == this.base.ModuleState.Paused.text 
              || module.state == this.base.ModuleState.NotRunning.text)
          {
            ; Module settings GUI is visible, but the main UI disabled → the user has likely 
            ; right-clicked the taskbar icon and selected "Close" that'll have still been 
            ; available. In such case, prevent closing the main GUI as long as any module 
            ; settings GUI remains visible, and close the module settings GUI instead.

            ; Do a double check
            if (winexist("ahk_id " module.handle))
            {
              winclose
              wasModuleGuiClosed := true
            }
            else
            {
              LogError(format("Application in an unexpected state: module ""{}"" settings GUI " 
                  . "isn't visible while the module itself is {}", moduleId, module.state))
            }
          }
        }

        detecthiddenwindows % oldHiddenWindowSetting

        return wasModuleGuiClosed
      }
    }
  }
}


; =====================================
; GLOBAL GUI EVENT CALLBACKS
; =====================================

ToolkitSettingsGuiClose()
{
  global toolkit

  return toolkit.OnSettingsGuiClose()
}


; =====================================
; GLOBAL OTHER HELPER FUNCTIONS
; =====================================

SetupLogging(devSessionLogLevel, errorFollowupUrl := "", messageMaxDisplayChars := 1000, maxLogFileLineCount := 200)
{
  if (getkeystate("F12", "P"))
  {
    ; No limit on log file line length
    instance := new Logger(devSessionLogLevel, errorFollowupUrl, -1)
  }
  else
  {
    ; Default/command-line param log file line length & count limit
    instance := new Logger(devSessionLogLevel, errorFollowupUrl, messageMaxDisplayChars
        , maxLogFileLineCount)
  }
  
  OnError(instance.LogUnhandledException.Bind(instance))

  return instance
}

GetNthControlInWindow(hwnd, idx)
{
  detecthiddenwindows, on
  winget, hCtrls, controllisthwnd, % "ahk_id " hwnd
  detecthiddenwindows, off

  return strsplit(hCtrls, "`n")[idx]
}

ParseVersionNumberString(versionNumber, versionStage)
{
  return (versionNumber == "" ? "" : "v") 
      . trim(versionNumber (versionStage != "Stable" ? " " versionStage : ""))
}

ForceSingleInstance()
{
  detecthiddenwindows, on
  oldMatchMode := a_titlematchmode
  settitlematchmode, regex

  if (winexist("\Q" UiPath.Studio.Toolkit.TitleHeading "\E.*\Q" 
      . UiPath.Studio.Toolkit.VendorName "\E.*"))
  {
    ; Executable already running → show the window of the old instance and exit this one
    winshow
    exitapp
  }

  settitlematchmode % oldMatchMode
  detecthiddenwindows, off
}

ForbiddenFilePathChars(delimiter := "")
{
  static forbiddenChars := "<>:""/|?*"

  result := forbiddenChars

  if (delimiter != "")
  {
    result := ""
    for k, forbiddenChar in strsplit(ForbiddenFilePathChars())
    {
      if (strlen(result))
      {
        result .= delimiter
      }
      
      result .= forbiddenChar
    }
  }

  return result
}

GetScriptName()
{
  return regexreplace(a_scriptname, "\.[^.]+$")
}