#requires AutoHotkey v1.1

#include %a_linefile%\..\QuickTabValueFields.ahk

UiPath.Studio.Toolkit.QuickTabValueFields := QuickTabValueFields
QuickTabValueFields := ""

Log("======== Starting to initialize a new module: """ 
    . UiPath.Studio.Toolkit.QuickTabValueFields.__Class """ ========")

toolkit.quickTabValueFields := new UiPath.Studio.Toolkit.QuickTabValueFields(
(join c
    toolkit, ; toolkitInstance
    toolkit.iniFileFullPath, ; iniFileFullPath
    toolkit.base.ModuleState.Running.text, ; moduleRunningStateText
    toolkit.base.ModuleState.Paused.text, ; modulePausedStateText
    toolkit.base.ModuleState.NotRunning.text ; moduleNotRunningStateText
))

toolkit.AddModule(
(join c
    toolkit.quickTabValueFields.__Class, ; moduleId

    toolkit.quickTabValueFields.gui.handle, ; hModuleSettingsGui

    toolkit.quickTabValueFields.ActivateWithConfig.Bind( ; startButtonEventHandler
        toolkit.quickTabValueFields), 
        
    toolkit.quickTabValueFields.Deactivate.Bind( ; stopButtonEventHandler
        toolkit.quickTabValueFields),
        
    toolkit.quickTabValueFields.SettingsGui.Show.Bind( ; configButtonEventHandler
        toolkit.quickTabValueFields.gui),
        
    toolkit.quickTabValueFields.title, ; moduleHeadingText
    
    ParseVersionNumberString(UiPath.Studio.Toolkit.QuickTabValueFields.Version.Number ; moduleVersionNumber
        , UiPath.Studio.Toolkit.QuickTabValueFields.Version.Stage), 
    
    toolkit.quickTabValueFields.iniFile.lastState ; initRunState
            == toolkit.base.ModuleState.Running.text,
    
    toolkit.quickTabValueFields.gui.isValidConfigHotkeyControl && ; moduleValidationResult
        toolkit.quickTabValueFields.gui.isValidConfigOtherControls)
)

Log("======== Module """ UiPath.Studio.Toolkit.QuickTabValueFields.__Class 
    . """ initialization complete ========")