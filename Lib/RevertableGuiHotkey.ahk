/************************************************************************
 * @description An improved AHK hotkey control encapsulated inside a class.
 * Primary improvements to the native hotkey control:
 * - When a user is inputting a new hotkey in the control and cancels the input sequence 
 *   after having held modifier(s) down, restore the earlier hotkey back to the control 
 *   instead of displaying "None".
 * - Parametrize context-sensitivity, error and change callback functions.
 * - Validate the newly typed hotkey
 * - Allow Nordic keyboard owners to use the (non-numpad) plus key as part of a hotkey.
 * @file RevertableGuiHotkey.ahk
 * @author TJay🐦
 * @date 2023/08/11
 * @version 0.1.0
 ***********************************************************************/
*/

; How-to-use sample code 
/*
  tc := new HotkeyTestClass()
return

; NOTE: This file must be in one of Lib folders when
; using the class from a file in another location
#Include <RevertableGuiHotkey>

class HotkeyTestClass
{
  __New()
  {
    this.hotkeys := {}

    this.SetupGui()
  }

  SetupGui()
  {
    ; gui, % this.__Class "Gui: default"

    this.hotkeys.TestHotkeyCombination := new RevertableGuiHotkey(""
        . "^+" ; Initial hotkey combination to start with
        , "TestHotkeyCombination" ; Unique hotkey control handle variable name

        ; Hotkey press event callbacks
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Hotkey press callback function; using a class method requires the instance to be passed above
            , executeFunc: this.ExecuteHotkeyPressCallback
            ; (optional) Hotkey press event context-sensitivity callback function; using a class method requires the instance context to be passed above
            , contextSensitivityFunc: this.IfShouldFireHotkeyCallback }

        ; (optional) Hotkey release event callbacks
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Hotkey release callback function; using a class method requires the instance to be passed above
            , executeFunc: this.ExecuteHotkeyReleaseCallback
            ; (optional) Hotkey release event context-sensitivity callback function; using a class method requires the instance to be passed above
            , contextSensitivityFunc: this.IfShouldFireHotkeyCallback }
        
        ; (optional) Hotkey assignment error callback
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Error callback function
            , func: this.AssignHotkeyErrorCallback }
        
        ; (optional) Hotkey change callback
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Change callback function
            , func: this.HotkeyChangeCallback }

        , this.__Class "Gui" ; (optional) Either set the default GUI & leave this param out or give the GUI id if not using the default GUI
        , "" ; (optional) Either set a master ID by which to combine & detect unique hotkeys or leave this param out to use whatever the GUI is (default or explicit)
        , "" ; (optional) Hotkey control options
        , "" ; (optional) Hotkey command options
        , "") ; Modifiers (any combination of +!^) whose symbol can be produced by a single keypress, and
              ; such key should be specially handled to allow using it as a regular key (f.ex. Nordic keyboards & a plus key)

    ; Creates the hotkey control and assigns the hotkey control handle to an instance variable 'hCtrl'
    ; which can be used to differentiate between hotkeys if you decide to use same event handler
    ; callback(s) for multiple hotkeys.
    this.hotkeys.TestHotkeyCombination.CreateControl()

    ; Activates the hotkey if valid and no duplicates exist for the master ID.
    ; Will also add the hotkey control if CreateControl() hasn't yet been called.
    ; If validation fails, assignment error callback is going to get called if supplied in the call to the constructor.
    ; If validation succeeds, change callback is going to get called if supplied in the call to the constructor.
    this.hotkeys.TestHotkeyCombination.ValidateAndActivate()

    this.hotkeys.NotepadHotkey := new RevertableGuiHotkey(""
        . "n" ; Initial hotkey combination to start with
        , "NotepadAddHelloWorldHotkey" ; Unique hotkey control variable name

        ; Hotkey press event callbacks
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Hotkey press callback function; using a class method requires the instance to be passed above
            , executeFunc: this.ExecuteHotkeyPressCallback
            ; (optional) Hotkey press event context-sensitivity callback function; using a class method requires the instance context to be passed above
            , contextSensitivityFunc: this.IfShouldFireHotkeyCallback }

        ; (optional) Hotkey release event callbacks
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Hotkey release callback function; using a class method requires the instance to be passed above
            , executeFunc: this.ExecuteHotkeyReleaseCallback
            ; (optional) Hotkey release event context-sensitivity callback function; using a class method requires the instance to be passed above
            , contextSensitivityFunc: this.IfShouldFireHotkeyCallback }
        
        ; (optional) Hotkey assignment error callback
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Error callback function
            , func: this.AssignHotkeyErrorCallback }
        
        ; (optional) Hotkey change callback
            ; The calling entity - leave blank (=non-object) if using non-class functions as callbacks
        , {   context: this
            ; Change callback function
            , func: this.HotkeyChangeCallback }
        , this.__Class "Gui" ; (optional) Either set the default GUI & leave this param out or give the GUI id if not using the default GUI
        , "" ; (optional) Either set a master ID by which to combine & detect unique hotkeys or leave this param out to use whatever the GUI is (default or explicit)
        , "" ; (optional) Hotkey control options
        , "" ; (optional) Hotkey command options
        , "") ; Modifiers (any combination of +!^) whose symbol can be produced by a single keypress, and
              ; such key should be specially handled to allow using it as a regular key (f.ex. Nordic keyboards & a plus key)
    this.hotkeys.NotepadHotkey.CreateControl()
    this.hotkeys.NotepadHotkey.ValidateAndActivate()

    ; this.hotkeys.YetAnotherHotkey := new RevertableGuiHotkey("..." etc)
    ; this.hotkeys.YetAnotherHotkey.CreateControl()
    ; this.hotkeys.YetAnotherHotkey.ValidateAndActivate()

    gui, % this.__Class "Gui: show", w230, Test gui
  }

  ExecuteHotkeyPressCallback(hotkey)
  {
    tooltip % a_thisfunc " - key name: " hotkey.keyName

    if (hotkey.hCtrl == this.hotkeys.TestHotkeyCombination.hCtrl)
    {
      ; Implement logic here
      msgbox Test hotkey combination was pressed
    }
    else if (hotkey.hCtrl == this.hotkeys.NotepadHotkey.hCtrl)
    {
      ; Implement logic here
      controlsettext, Edit1, % "Hello notepad world!", A
    }
  }

  ExecuteHotkeyReleaseCallback(hotkey)
  {
    tooltip % a_thisfunc " - key name: " hotkey.keyName

    if (hotkey.hCtrl == this.hotkeys.TestHotkeyCombination.hCtrl)
    {
      ; Implement logic here
      msgbox Test hotkey combination was pressed
    }
    else if (hotkey.hCtrl == this.hotkeys.NotepadHotkey.hCtrl)
    {
      ; Implement logic here
      controlsettext, Edit1, % "Hello notepad world!", A
    }
  }
  
  AssignHotkeyErrorCallback(newKeyName, oldHotkey, errorType)
  {
    if (errorType == RevertableGuiHotkey.AssignErrorType.DUPLICATE)
    {
      ; The hotkey control will have reverted the duplicate hotkey back to its 
      ; previous value, both for the hotkey control display text and also functionally
      tooltip % Format("{1} - hotkey {2} already assigned for the purposes of '{3}'.", a_thisfunc, newKeyName, oldHotkey.description)
    }
    else if (errorType == RevertableGuiHotkey.AssignErrorType.INVALID)
    {
      ; Likely possible only with an invalid initial hotkey keyname taken from a corrupted config file etc.
      tooltip % Format("{1} - error assigning a new hotkey '{2}'.", a_thisfunc, newKeyName)
    }
    else
    {
      throw Exception("Hotkey assign error type not implemented", a_thisfunc, errorType)
    }
  }

  HotkeyChangeCallback(newKeyName, oldHotkey)
  {
    msgbox % "Attempting to change the hotkey from " oldHotkey.keyName " to " newKeyName
  }

  IfShouldFireHotkeyCallback(hotkey)
  {
    if (hotkey.hCtrl == this.hotkeys.TestHotkeyCombination.hCtrl)
    {
      ; Will practically always fire
      return winexist("ahk_class Shell_TrayWnd ahk_exe explorer.exe")
    }
    else if (hotkey.hCtrl == this.hotkeys.NotepadHotkey.hCtrl)
    {
      ; Only fire if a blank Notepad instance is active
      if (!winactive("ahk_class Notepad ahk_exe notepad.exe"))
      {
        return false
      }

      controlgettext, notepadText, Edit1
      
      return notepadText == ""
    }
  }
}
*/

class RevertableGuiHotkey
{
  
  class AssignErrorType
  {
    static DUPLICATE := "DUPLICATE", INVALID := "INVALID"
        , ONLY_MODIFIERS := "ONLY_MODIFIERS"
  }

  static HotkeysByMaster := {}
  static HOTKEYF_SHIFT := 0x1, HOTKEYF_CONTROL := 0x2, HOTKEYF_ALT := 0x4, HOTKEYF_EXT := 0x8

  /**
   * Instantiates a RevertableGuiHotkey object that encapsulates AHK's hotkey control.
   * @param {string} An initial hotkey to associate with this instance.
   * @param {string} A descriptive text associated with a hotkey that can be consulted
   *  for info about the purpose of the hotkey, for example as a part of an error message 
   *  when setting a hotkey fails due to another duplicate hotkey.
   * @param {object} An object that defines a key down event handler. Should include the 
   *  following keys:
   *  a) "context" - to use class methods as down event callbacks, pass the method owner
   *  object. To use top-level procedural functions instead, leave the value empty.
   *  b) "executeFunc" - a class method object or a procedural function object
   *  (neither should be a BoundFunc!) to call when a key press-down event is detected. 
   *  The function accepts no extra parameters.
   *  c) (optional) "contextSensitivityFunc" - a class method object or a procedural function 
   *  object (neither should be a BoundFunc!) to use as a context sensitivity function to 
   *  determine if the hotkey down action should be captured as a hotkey, or instead passed 
   *  down to the system as an ordinary keypress. The context-sensitivity function can accept
   *  one parameter, the name of the hotkey being tested. Inside the context-sensitivity 
   *  function implementation, return a non-zero number to allow the down action to be
   *  captured. To have the hotkey ignore context-sensitivity and always remain active, 
   *  pass zero as the context-sensitivity function.
   * @param {object} (optional) An object that defines a key up event handler. Should include 
   *  the following keys:
   *  a) "context" - to use class methods as up event callbacks, pass the method owner
   *  object. To use top-level procedural functions instead, leave the value empty. 
   *  b) "executeFunc" - a class method object or a procedural function object
   *  (neither should be a BoundFunc!) to call when a key release event is detected.
   *  The function accepts no extra parameters.
   *  c) (optional) "contextSensitivityFunc" - a class method object or a procedural function 
   *  object (neither should be a BoundFunc!) to use as a context sensitivity function to 
   *  determine if the hotkey release action should be captured as a hotkey, or instead passed 
   *  down to the system as an ordinary key release. The context-sensitivity function can 
   *  accept one parameter, the name of the hotkey being tested. Inside the context-sensitivity 
   *  function implementation, return a non-zero number to allow the up action to be
   *  captured. To have the hotkey ignore context-sensitivity and always remain active, 
   *  pass zero as the context-sensitivity function.
   * @param {object} (optional) An object that defines a handler to call when setting a new 
   *  hotkey fails. Should include the following keys: a) "context" - to use a class method 
   *  as a fail event callback, pass the method owner object. To use a top-level procedural 
   *  function instead, leave the value empty. b) "func" - a class method object or a 
   *  procedural function object (neither should be a BoundFunc!) to call when trying to set 
   *  a new hotkey fails. The function can accept up to three parameters:
   *    1) a new hotkey candidate that failed to be set.
   *    2) a RevertableGuiHotkey object. Which hotkey the object represents depends on the 
   *    third parameter.
   *    3) One of two enum values:
   *     a) RevertableGuiHotkey.AssignErrorType.INVALID - provided hotkey is not supported. 
   *     The second parameter {RevertableGuiHotkey} is the instance whose associated hotkey's 
   *     change attempt failed.
   *     b) RevertableGuiHotkey.AssignErrorType.DUPLICATE - an attempt to set a duplicate 
   *     hotkey belonging to the same masterId param. The second parameter
   *     {RevertableGuiHotkey} is the instance associated with the existing same key.
   * @param {object} (optional) An object that defines a handler to call when setting a new 
   *  hotkey succeeds. Should include the following keys: a) "context" - to use a class method 
   *  as a change event callback, pass the method owner object. To use a top-level procedural 
   *  function instead, leave the value empty. b) "func" - a class method object or a 
   *  procedural function object (neither should be a BoundFunc!) to call when trying to set 
   *  a new hotkey succeeds. The function can accept one parameter, the {RevertableGuiHotkey}
   *  object whose associated hotkey was just changed.
   * @param {number} (optional) ID of a GUI the hotkey control should be added to. 
   *  Alternatively, set the default GUI prior to calling and pass an empty string.
   *  @param {any} (optional) An ID of a unique owner of the new hotkey. Either set a master 
   *  ID by which hotkeys are grouped and duplicates detected, or pass an empty string to 
   *  use the ID of the GUI (default or explicit).
   * @param {string} Options to pass to AHK's [Gui, Add] command. Options must not include
   *  a handle ("hwnd...") or a hotkey variable ("v..."). Specifying a g-label will be 
   *  useless, as it will be replaced with key down and key up event handlers.
   * @param {string} Options to pass to AHK's [Hotkey] command. "UseErrorLevel", "On" and 
   * "Off" are redundant, as they will be internally filtered out.
   * @param {string} Any combination of AHK's hotkey modifier symbols (^!+), supported by
   *  the native WINAPI hotkey control, that should be treated as legit ordinary keys as well.
   *  Usable mostly by owners of certain regions where keyboards have regular keys that alone
   *  produce a modifier symbol. Consider a Nordic keyboard that has an ordinary (non-numpad) 
   *  plus key. By providing "+" as the parameter value, the created hotkey control will 
   *  accept the plus key as a (part of a) hotkey, e.g. "++" for a Shift-plus.
   * @returns {RevertableGuiHotkey}
   */
  __New(keyName, description
      , downEventCallbacks, upEventCallbacks := 0, errorCallback := 0, changeCallback := 0
      , guiId := 1, masterId := "", controlOptions := "", hotkeyOptions := ""
      , modifiersAllowedAsRegularKeys := "")
  {
    this.keyName := keyName
    this.description := description

    this.controlOptions := controlOptions

    ; Remove "on" and "useerrorlevel" options if present
    this.hotkeyOptions := regexreplace(hotkeyOptions, "i)\b(?:on|off|useerrorlevel)\b")

    this.guiId := guiId
    this.modifiersAllowedAsRegularKeys := modifiersAllowedAsRegularKeys

    if (a_defaultgui != 1 && (this.guiId == "" || this.guiId == 1))
    {
      ; Use default GUI if other than the first and custom GUI id not supplied
      this.guiId := a_defaultgui
    }

    ; Allow overriding unique-hotkeys-per-gui by supplying a 
    ; separate value by which to combine unique hotkeys
    if (masterId == "")
    {
      masterId := guiId
    }
    this.masterId := masterId

    if (!this.base.HotkeysByMaster.HasKey(this.masterId))
    {
      this.base.HotkeysByMaster[this.masterId] := []
    }
    this.base.HotkeysByMaster[this.masterId].Push(this)


    ; Set callbacks

    if (isobject(downEventCallbacks.context))
    {
      this.executeFnKeyDown := downEventCallbacks.executeFunc
          .Bind(downEventCallbacks.context, this)

      this.contextSensitivityFnKeyDown := downEventCallbacks
          .contextSensitivityFunc.Bind(downEventCallbacks.context, this)
    }
    else
    {
      this.executeFnKeyDown := downEventCallbacks.executeFunc.Bind(this)

      this.contextSensitivityFnKeyDown := downEventCallbacks
          .contextSensitivityFunc.Bind(this)
    }


    if (isobject(upEventCallbacks))
    {
      if (isobject(upEventCallbacks.context))
      {
        this.executeFnKeyUp := upEventCallbacks.executeFunc
            .Bind(upEventCallbacks.context, this)

        this.contextSensitivityFnKeyUp := upEventCallbacks
            .contextSensitivityFunc.Bind(upEventCallbacks.context, this)
      }
      else
      {
        this.executeFnKeyUp := upEventCallbacks.executeFunc.Bind(this)

        this.contextSensitivityFnKeyUp := upEventCallbacks
            .contextSensitivityFunc.Bind(this)
      }
    }

    if (isobject(errorCallback))
    {
      if (isobject(errorCallback.context))
      { 
        this.errorFn := errorCallback.func.Bind(errorCallback.context)
      }
      else
      {
        this.errorFn := errorCallback.func
      }
    }

    if (isobject(changeCallback))
    {
      if (isobject(changeCallback.context))
      { 
        this.changeFn := changeCallback.func.Bind(changeCallback.context)
      }
      else
      {
        this.changeFn := changeCallback.func
      }
    }
  }

  __Delete()
  {
    if (this.contextSensitivityFnKeyDown)
    {
      ; Turn off hotkey down event handler

      ; Set context sensitivity
      fn := this.contextSensitivityFnKeyDown
      hotkey, if, % fn
    }
    else
    {
      hotkey, if
    }

    hotkey, % this.keyName, off, useErrorLevel
    hotkey, if

    if (this.executeFnKeyUp)
    {
      ; Turn off hotkey up event handler

      if (this.contextSensitivityFnKeyUp)
      {
        ; Set context sensitivity
        fn := this.contextSensitivityFnKeyUp
        hotkey, if, % fn
      }
      else
      {
        hotkey, if
      }

      hotkey, % this.keyName " up", off, useErrorLevel
      hotkey, if
    }
  }

  /**
   * Creates a hotkey control according to instructions passed to the class constructor.
   */
  CreateControl()
  {
    
    if (!this.hCtrl)
    {
      ; Add a hotkey control
      gui, % this.guiId ": add", hotkey, % "hwndh " this.controlOptions
          , % this.keyName
      
      this.hCtrl := h

      ; Set the function to trigger when the value in the hotkey control is changed
      fn := this.ValidateAndActivate.Bind(this, false)
      guicontrol, +g, % this.hCtrl, % fn
    }
  }

  /**
   * Validates and, if valid, activates an initial hotkey supplied in the call to the class
   * constructor. Also called internally whenever a user types in a new hotkey in the control.
   * @param {number} Do not set. This parameter is used internally.
   * @returns {object} A validation result with two keys:
   * 1) "success" - a boolean value indicating the result of the validation and activation 
   * operations.
   * 2) "reason" - An empty string when the validation succeeds. Otherwise, one of the 
   * RevertableGuiHotkey.AssignErrorType enum values depending on the validation result:
   *  a) DUPLICATE - the hotkey already exists under the same master ID.
   *  b) INVALID - the hotkey is invalid and therefore can't be used.
   *  c) ONLY_MODIFIERS - the hotkey consists of only modifier keys Ctrl/Alt/Shift.
   */
  ValidateAndActivate(isHotkeyInit := true)
  {
    static HKM_GETHOTKEY := 0x402

    result := { success: true, reason: "" }

    if (isHotkeyInit)
    {
      ; Only during the first call right after this object has been instantiated

      if (!this.hCtrl)
      {
        this.CreateControl()
      }

      newHotkeyCandidate := this.keyName
    }
    else
    {
      ; Whenever a user is typing a new hotkey in the control

      ; Get text from the hotkey control
      sendmessage, % HKM_GETHOTKEY, 0, 0, , % "ahk_id " this.hCtrl
      vkCode := errorlevel & 0xff

      ; AHK's getkeyname(vkXX) is buggy with the "Extended key" bit, but scan code-based 
      ; approach works 
      scCode := getkeysc(format("vk{:x}", vkCode)) 
      modifiers := (errorlevel & 0xff00) >> 8

      newHotkeyCandidate := ""
      
      if (modifiers & this.base.HOTKEYF_CONTROL)
      {
        newHotkeyCandidate .= "^"
      }
      if (modifiers & this.base.HOTKEYF_SHIFT)
      {
        newHotkeyCandidate .= "+"
      }
      if (modifiers & this.base.HOTKEYF_ALT)
      {
        newHotkeyCandidate .= "!"
      }
      if (modifiers & this.base.HOTKEYF_EXT)
      {
        scCode |= 0x100
      }

      newHotkeyCandidate .= getkeyname(Format("sc{:x}", scCode))
    }

    ; Check for duplicates
    for k, hotkeyByOwner in this.base.HotkeysByMaster[this.masterId]
    {
      if (hotkeyByOwner.keyName == newHotkeyCandidate && hotkeyByOwner.hCtrl != this.hCtrl)
      {
        this.errorFn.Call(newhotkeyCandidate, hotkeyByOwner, this.base.AssignErrorType.DUPLICATE)

        newhotkeyCandidate := ""

        result := { success: false, reason: this.base.AssignErrorType.DUPLICATE }

        break
      }
    }

    if (newHotkeyCandidate == "" && this.keyName == "")
    {
      ; Empty hotkey and no backup to revert to -> let the hotkey control deal with it
      return result
    }

    modifiersAllowedAsRegularKeys := this.modifiersAllowedAsRegularKeys
    if modifiersAllowedAsRegularKeys contains +,^,!
    {
      ; In the new hotkey candidate there may be a regular key whose character resembles 
      ; a modifier symbol ("^", "!", or "+"). If such key has been flagged allowed 
      ; as a "standalone key", determine its current press state

      if (isHotkeyInit)
      {
        ; Initializing the hotkey control

        ; Use the hardcoded hotkey candidate (or a candidate supplied from a config file 
        ; etc.) to determine if the candidate should be allowed to end with a modifier symbol.
        plusKeyState := this.modifiersAllowedAsRegularKeys ~= "\+" && newHotkeyCandidate ~= "\+$"
        cflxKeyState := this.modifiersAllowedAsRegularKeys ~= "\^" && newHotkeyCandidate ~= "\^$"
        exclKeyState := this.modifiersAllowedAsRegularKeys ~= "!"  && newHotkeyCandidate ~= "!$"
      }
      else
      {
        ; A user is assigning a new hotkey (combination) through the control

        ; Use the hotkey candidate pressed down by a user to determine if the candidate 
        ; should be allowed to contain a regular key matching a modifier symbol

        ; NOTE: GetKeyState() will not return true for the modifier key with a matching 
        ; symbol but only for a matching regular key (if available) being pressed

        ; To distinguish a Plus key from Shift
        plusKeyState := this.modifiersAllowedAsRegularKeys ~= "\+" && GetKeyState("+")
        ; To distinguish a Circumflex key from Ctrl
        cflxKeyState := this.modifiersAllowedAsRegularKeys ~= "\^" && GetKeyState("^") 
        ; To distinguish an Exclamation point key from Alt
        exclKeyState := this.modifiersAllowedAsRegularKeys ~= "!"  && GetKeyState("!") 
      }
    }

    
    if (newHotkeyCandidate != "")
    {
      ; Test a new hotkey candidate down event
      
      if (this.contextSensitivityFnKeyDown)
      {
        ; Set context sensitivity
        fn := this.contextSensitivityFnKeyDown
        hotkey, if, % fn
      }
      else
      {
        hotkey, if
      }

      fn := this.executeFnKeyDown
      dummyBoundFunc := func("abs").Bind(1)

      ; By leaving the label/function empty, check if the hotkey already exists
      hotkey, % newHotkeyCandidate, , useerrorlevel
      hotkeyAssignError := errorlevel
      hotkey, if

      if ((hotkeyAssignError == 5 || hotkeyAssignError == 6) 
          && numget(&fn) != numget(&dummyBoundFunc))
      {
        ; A non-existent hotkey with an invalid execution callback

        ; Overwrite the hotkey variable with a blank value to have 
        ; the previous value returned to the respective control
        newHotkeyCandidate := ""
      }
    }

    RevertInvalidHotkey:

    ; If plus, circumflex or exclamation point *regular key* potentially with 
    ; some modifiers OR any other valid key combination
    if ((hotkeyContainsMoreThanJustModifiers
        ; Replace up to 3 modifiers
        := RegExReplace(newHotkeyCandidate, "[\+\^!]", "", "", 3) <> "")
        ; or, if empty after replacement, allow +/^/! flagged as a regular key
        || plusKeyState || cflxKeyState || exclKeyState)
    {

      ; Activate the new hotkey

      ; Set context sensitivity
      if (this.contextSensitivityFnKeyDown)
      {
        fn := this.contextSensitivityFnKeyDown
        hotkey, if, % fn
      }
      else
      {
        hotkey, if
      }

      ; Try to activate the hotkey down event
      fn := this.executeFnKeyDown
      ; hotkey, % " ef", % fn, % " useerrorlevel on"

      hotkey, % newHotkeyCandidate, % fn, % this.hotkeyOptions " useerrorlevel on"
      hotkeyAssignError := errorlevel
      hotkey, if

      if (hotkeyAssignError)
      {
        ; Activation failed

        this.errorFn.Call(newHotkeyCandidate, this, this.base.AssignErrorType.INVALID)

        ; Wipe the hotkey candidate and clear flags to force subsequent 
        ; execution to the invalid hotkey branch and rerun the check
        newHotkeyCandidate := ""
        plusKeyState := cflxKeyState := exclKeyState := 0

        result := { success: false, reason: this.base.AssignErrorType.INVALID }
        goto, RevertInvalidHotkey
      }
      
      ; Activate the hotkey up event if requested
      if (this.executeFnKeyUp)
      {
        ; Set context sensitivity
        if (this.contextSensitivityFnKeyUp)
        {
          fn := this.contextSensitivityFnKeyUp
          hotkey, if, % fn
        }
        else
        {
          hotkey, if
        }

        fn := this.executeFnKeyUp
        hotkey, % newHotkeyCandidate " up", % fn, % this.hotkeyOptions " on"
        hotkey, if
      }


      if (newHotkeyCandidate != this.keyName)
      {
        ; A hotkey different from the previous one is being assigned
        ; and hotkey activation was requested

        if (this.keyName != "")
        {
          ; A previous hotkey exists 
          
          ; Disable the previous hotkey

          ; Set context sensitivity
          if (this.contextSensitivityFnKeyDown)
          {
            fn := this.contextSensitivityFnKeyDown
            hotkey, if, % fn
          }
          else
          {
            hotkey, if
          }

          ; Disable the hotkey down event
          hotkey, % this.keyName, off
          hotkey, if

          ; Disable the hotkey up event if active
          if (this.executeFnKeyUp)
          {
            ; Set context sensitivity
            if (this.contextSensitivityFnKeyUp)
            {
              fn := this.contextSensitivityFnKeyUp
              hotkey, if, % fn
            }
            else
            {
              hotkey, if
            }

            ; Disable the hotkey up event
            hotkey, % this.keyName " up", off
            hotkey, if
          }
        }

        if (this.changeFn)
        {
          this.changeFn.Call(newHotkeyCandidate, this)
        }

        ; Update the new valid hotkey as a backup to revert back 
        ; to if an invalid key combination is provided later
        this.keyName := newHotkeyCandidate
      }
      
      if (isHotkeyInit && (plusKeyState || cflxKeyState || exclKeyState))
      {
        ; Initializing the hotkey control and the initial hotkey contains 
        ; an allowed regular key matching a modifier symbol.

        ; If there are also modifiers present in the initial hotkey combination,
        ; a native WINAPI hotkey control's edit field will not play nice with the
        ; hotkey, refusing to display a valid text instead of "None". This can be
        ; worked around by manually putting together params and sending the
        ; HKM_SETHOTKEY message to force the control to display the combination
        ; correctly.
        this.__HKM_SETHOTKEY(plusKeyState, cflxKeyState, exclKeyState)
      }
    }
    else ; Hotkey consists of only modifier keys / unsupported keys / has been invalidated earlier in this method
    {
      ; Upon release of an unsupported key combination, such as a
      ; naked modifier key (combination), a blank hotkey is sent
      if (newHotkeyCandidate == "")
      {
        if (hasPreviousHotkeyOnlyModifierSymbols 
            := regExReplace(this.keyName, "^[+^!]", "", "", 4) == "")
        {
          ; Previously assigned hotkey contains only modifier symbols, the
          ; last one being implicitly a regular key with an overlapping symbol
          modifiersAllowedAsRegularKeys := this.modifiersAllowedAsRegularKeys
          if modifiersAllowedAsRegularKeys contains +,^,!
          {
            ; Regular keys matching modifiers allowed

            ; Get states for each regular key matching a modifier symbol in the previously assigned hotkey 
            plusKeyState  := this.modifiersAllowedAsRegularKeys ~= "\+" && this.keyName ~= "\+$" ; Test for Plus
            cflxKeyState  := this.modifiersAllowedAsRegularKeys ~= "\^" && this.keyName ~= "\^$" ; Test for Circumflex
            exclKeyState  := this.modifiersAllowedAsRegularKeys ~= "!"  && this.keyName ~= "!$"  ; Test for Exclamation point

            ; Restore the old value in the control. As the old value contains both 
            ; modifiers and a regular key matching a modifier symbol, the value
            ; must be restored by preparing and sending a message to force display
            ; of a correct text in the hotkey control.
            this.__HKM_SETHOTKEY(plusKeyState, cflxKeyState, exclKeyState)
          }
          else
          {
            ; Previous hotkey has a regular key with a modifier symbol but it's not allowed.
            ; Therefore, "None" needs to be restored to the control. Do this by trying to
            ; set the value to the previous combination by ordinary means without a message.
            guicontrol, , % this.hCtrl, % this.keyName
          }
        }
        else
        {
          ; Previous hotkey has an ordinary key (combination) without a regular key 
          ; matching a modifier symbol. Therefore it'll be safe to revert back to 
          ; the last valid hotkey.
          guicontrol, , % this.hCtrl, % this.keyName
        }
      }
      else
      {
        ; guicontrol, , % this.hCtrl, % this.keyName

        ; Hotkey consists of just modifier keys
        result := { success: false, reason: this.base.AssignErrorType.ONLY_MODIFIERS }
      }
    }

    return result
  }

  ; Send a string to a hotkey control
  __HKM_SETHOTKEY(plusKeyState, cflxKeyState, exclKeyState)
  {
    static HKM_SETHOTKEY := 0x401

    ; Determine any modifiers the hotkey combination contains
    shiftKeyState := this.keyName ~= "^[!^]{0,2}\+(?!$)" ; Test for Shift
    ctrlKeyState  := this.keyName ~= "^[!+]{0,2}\^(?!$)" ; Test for Ctrl
    altKeyState   := this.keyName ~= "^[+^]{0,2}!(?!$)"  ; Test for Alt

    ; Construct the message to force the control to display the hotkey
    wParam := 0
        | (this.base.HOTKEYF_SHIFT * shiftKeyState 
        |  this.base.HOTKEYF_CONTROL * ctrlKeyState 
        |  this.base.HOTKEYF_ALT * altKeyState) << 8

        | plusKeyState * GetKeyVK("+")
        | cflxKeyState * GetKeyVK("^")
        | exclKeyState * GetKeyVK("!")

    ; Send the replacement value to the control
    sendmessage, HKM_SETHOTKEY, wParam, 0, , % "ahk_id  " this.hCtrl
  }
}