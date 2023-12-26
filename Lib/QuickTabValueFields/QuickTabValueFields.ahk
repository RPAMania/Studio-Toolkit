class QuickTabValueFields
{
  static VersionNumber := "0.0.1 alpha"
}

#include <UIA_Interface>
#singleinstance, force
setbatchlines, -1

new SomeClass()

class SomeClass
{
  static TabDirection := { Forward: "Tab_Forward", Backward: "Tab_Backward" }
  static ActiveControlCategory :=
  (join
    {
      Studio_Properties: "Studio_Properties",
      VariableOrArgument: "VariableOrArgument"
    }
  )
  ; ExternalDialog: "ExternalDialog"

  static DataGridCellWalker := UIA_Interface().CreateTreeWalker(
  (join
      UIA_Interface().CreatePropertyCondition(
          UIA_Enum.UIA_PropertyId("LocalizedControlType"),
          "data grid cell")
  ))
  /*
  static DataGridWalker := UIA_Interface().CreateTreeWalker(
  (join
      UIA_Interface().CreatePropertyCondition(
          UIA_Enum.UIA_PropertyId("LocalizedControlType"),
          "datagrid")
  ))
  */
  static WindowWalker := UIA_Interface().CreateTreeWalker(
  (join
      UIA_Interface().CreatePropertyCondition(
          UIA_Enum.UIA_PropertyId("ControlType"),
          UIA_Enum.UIA_WindowControlTypeId)
  ))

  static studioProcessName := "UiPath.Studio.exe"
  static studioWindow :=
  (join
    {
      title: " - UiPath Studio ahk_exe " SomeClass.studioProcessName,
      titleMatchMode: 2
    }
  )
  static dialogProcessName := "UiPath.Studio.Launcher.exe"

  static Pane :=
  (join
    { 
      Variables:  "Pane_Variables", 
      Arguments:  "Pane_Arguments", 
      Properties: "Pane_Properties",
      Imports:    "Pane_Imports"
    }
  )
  
  /*
    - Figure out if a compatible control/window is active
      * Control: input field in "Variables" pane in Studio
      * Control: input field in "Arguments" pane in Studio
      * Control: input field in "Properties" pane in Studio
        > If any, allow +#tab to activate the first control in the pane
        > If none, do nothing

      * Window: Invoke Workflow File dialog
      * Window: Arguments of a Dictionary<> type
        > Figure out if a compatible control is also active;
          ^ If so, traverse controls on tab
          ^ Else, allow +#tab to activate the first control
          
  */
  __New()
  {
    this.uia := UIA_Interface()

    ; Setup hotkeys



    ; Setup tab forward/backwards hotkeys

    fn := this.__IsCompatibleControlActive.Bind(this)
    hotkey, if, % fn


    ; ==== Move focus forward / backwards among input controls in a compatible window ====

    fn := this.__SimulateTab.Bind(this)

    hotkey, tab, % fn
    hotkey, +tab, % fn
    
    ; =============================================

    hotkey, if


    ; Setup active pane selection hotkeys

    ; ==== Set the active pane internally ====
    fn := this.__SetActivePane.Bind(this)

    ; * For the Studio window
    ;   > #+q → set the "Variables" pane internally active
    ;   > #+w → set the "Arguments" pane internally active
    ;   > #+e → set the "Properties" pane internally active
    hotkey, #+q, % fn
    hotkey, #+w, % fn
    hotkey, #+e, % fn
    hotkey, #+r, % fn
    


    ; Setup the hotkey to focus the first input field

    fn := this.__IsStudioOrCompatibleDialogWindowActive.Bind(this)

    ; fn := this.__IsStudioWindowActive.Bind(this)
    hotkey, if, % fn

    ; ==== Focus the first input field in
    ;  a) the chosen active pane in the Studio window
    ; OR
    ;  b) a compatible dialog window ====

    fn := this.__SetFocusToFirstInputFieldInActivePane.Bind(this)
    ; 
    ; * If Studio window is active
    ;   > If "Variables" or "Arguments" pane has internally been set as active
    ;     ^ Focus the first input field in the pane
    ;   > If "Properties" pane has internally been set as active 
    ;     ^ Focus the first input field in the pane
    ; * If a dialog window is active
    ;   > Focus the first input field in the window
    ; NOTE: Should we only do this if no other input field is already focused in the active pane?
    hotkey, #+tab, % fn

    ; =============================================

    hotkey, if

    ; =============================================
    ; NOTE: PICK AND IMPLEMENT A HOTKEY TO INVOKE THE "ADVANCED EDITOR"
    ; =============================================
  }

  __IsStudioOrCompatibleDialogWindowActive()
  {
    return this.__IsStudioWindowActive() || this.__TryFindCompatibleDialogWindow()
  }

  __IsStudioWindowActive()
  {
    oldTitleMatchMode := a_titlematchmode
    settitlematchmode % this.base.studioWindow.titleMatchMode

    try return winactive(this.base.studioWindow.title)
    finally
    {
      settitlematchmode % oldTitleMatchMode
    }
    
  }

  __SetFocusToFirstInputFieldInActivePane()
  {
    if (this.__IsStudioWindowActive())
    {
      switch (this.activePane)
      {
        case this.base.Pane.Variables:
          paneButton := this.__FindVariablesArgumentsImportsPaneButtons().variables
          automationId := "VariableDataGrid"
        case this.base.Pane.Arguments:
          paneButton := this.__FindVariablesArgumentsImportsPaneButtons().arguments
          automationId := "ArgumentDataGrid"
        case this.base.Pane.Properties:
        ; case this.base.Pane.Imports: return
        default: return
      }

      if (!paneButton.toggleState)
      {
        paneButton.element.Click()
      }

      uiaDataGrid := this.__FindDesignerPaneContainer()
        ; .FindFirstByType(UIA_Enum.UIA_CustomControlTypeId, UIA_Enum.TreeScope_Children)
        .FindFirstBy("AutomationId=" automationId, UIA_Enum.TreeScope_Children)
    }
    else
    {
      ; One of the compatible dialogs is active

      uiaDataGrid := this.uia
          .ElementFromHandle(this.__TryFindCompatibleDialogWindow())
          .TWFindFirstByProperty(UIA_Enum.UIA_LocalizedControlTypePropertyId, "custom"
              , UIA_Enum.Treescope_Children)
          .FindFirstBy("AutomationId=DynamicArgumentDesigner_DatGrid")
    }

    uiaDataItemList := uiaDataGrid
        .FindAllByType(UIA_Enum.UIA_DataItemControlTypeId, UIA_Enum.TreeScope_Children)
  
    if (uiaDataItemList.Length() > 1)
    {
      ; Found an input field to set active

      uiaDataGridCells := uiaDataItemList[1]
          .TWFindAllByProperty(UIA_Enum.UIA_LocalizedControlTypePropertyId, "data grid cell"
              , UIA_Enum.Treescope_Children)
      
      uiaDataGridCells[uiaDataGridCells.Length()].Click()
    }
  }

  __SetActivePane()
  {
    hotkeyWithoutModifiers := regexreplace(a_thishotkey, "^[\Q#!+\E]*(.+)$", "$1")
    switch (hotkeyWithoutModifiers)
    {
      case "q": this.activePane := this.base.Pane.Variables
      case "w": this.activePane := this.base.Pane.Arguments
      case "e": this.activePane := this.base.Pane.Properties
      case "r": this.activePane := this.base.Pane.Imports
      default: throw Exception("Unidentified hotkey.", , a_thishotkey)
    }

    this.__ActivatePane(this.activePane)
  }

  __FindPropertiesPaneButton()
  {
    oldTitleMatchMode := a_titlematchmode
    settitlematchmode % this.base.studioWindow.titleMatchMode

    try
    {
      uiaPropertiesButton := this.uia
          .ElementFromHandle(winexist(this.base.studioWindow.title))
          .TWFindFirstByProperty(UIA_Enum.UIA_LocalizedControlTypePropertyId, "dock site"
              , UIA_Enum.Treescope_Children) ; "" dock site
          .TWGetChildren()[1] ; "" dock host
          .TWFindFirstByProperty(UIA_Enum.UIA_LocalizedControlTypePropertyId, "split container"
              , UIA_Enum.Treescope_Children)
          .TWGetChildren()[3] ; "" split container
          .TWGetChildren()[1] ; "" tool window container
          .TWFindFirstByName("Properties", UIA_Enum.Treescope_Children) ; "Properties" docking window container tab

      return uiaPropertiesButton
    }
    finally
    {
      settitlematchmode % oldTitleMatchMode
    }
  }

  __ActivatePane(pane)
  { 
    switch (pane)
    {
      case this.base.Pane.Variables: 
        paneButton := this.__FindVariablesArgumentsImportsPaneButtons().variables.element
      case this.base.Pane.Arguments: 
        paneButton := this.__FindVariablesArgumentsImportsPaneButtons().arguments.element
      case this.base.Pane.Imports: 
        paneButton := this.__FindVariablesArgumentsImportsPaneButtons().imports.element
      case this.base.Pane.Properties:
        paneButton := this.__FindPropertiesPaneButton()
        if (!paneButton.TWGetChildren()[3].CurrentBoundingRectangle.l)
        {
          ; No bounding rectangle exists → the pane is currently hidden

          ; Setting focus works but always throws an exception for some reason
          try paneButton.SetFocus()
        }
        return
      default: throw Exception("Unidentified pane.", , pane)
    }
    
    ; "Variables" / "Arguments" pane toggle

    this.uia.AutoSetFocus := false
    paneButton.Click()
    this.uia.AutoSetFocus := true
  }

  __FindDesignerPaneContainer()
  {
    oldTitleMatchMode := a_titlematchmode
    settitlematchmode % this.base.studioWindow.titleMatchMode
    
    try
    {
      uiaWindows := this.uia
          .ElementFromHandle(winexist(this.base.studioWindow.title))
          .TWFindAllByProperty(UIA_Enum.UIA_ControlTypePropertyId
              , UIA_Enum.UIA_WindowControlTypeId, UIA_Enum.Treescope_Children)
      
      windowCount := uiaWindows.Length()

      loop % windowCount
      {
        uiaDesignerPaneContainerCandidate := uiaWindows[windowCount - a_index + 1]

        uiaDesignerPaneChildrenCandidates := uiaDesignerPaneContainerCandidate
            .TWGetChildren()[1].TWGetChildren()

        childCount := uiaDesignerPaneChildrenCandidates.Length()
        
        if (uiaDesignerPaneChildrenCandidates[childCount]
            .CurrentLocalizedControlType == "status bar")
        {
          return uiaDesignerPaneContainerCandidate.TWGetChildren()[1]
        }
      }
    }
    finally
    {
      settitlematchmode % oldTitleMatchMode
    }

    throw Exception("Designer pane container not found.")
  }

  __FindVariablesArgumentsImportsPaneButtons()
  {
    uiaDesignerPaneChildren := this.__FindDesignerPaneContainer().TWGetChildren()

    uiaDesignerStatusBarChildren := uiaDesignerPaneChildren[uiaDesignerPaneChildren.Length()]
        .TWGetChildren()
          
    return
    (join
      { 
        variables:
        {
          element: uiaDesignerStatusBarChildren[1], 
          toggleState: uiaDesignerStatusBarChildren[1].GetCurrentPattern("Toggle")
              .CurrentToggleState
        },
        arguments:
        {
          element: uiaDesignerStatusBarChildren[2], 
          toggleState: uiaDesignerStatusBarChildren[2].GetCurrentPattern("Toggle")
              .CurrentToggleState
        },
        imports:
        {
          element: uiaDesignerStatusBarChildren[3], 
          toggleState: uiaDesignerStatusBarChildren[3].GetCurrentPattern("Toggle")
              .CurrentToggleState
        }
      }
    )
  }

  __SimulateTab()
  {
    critical

    process, priority, , high

    /*
      if (instr(a_thishotkey, "#") && instr(a_thishotkey, "+"))
      {
        ; Advanced Editor requested by a user
        switch (this.activeCompatibleControlCategory)
        {
          case this.base.ActiveControlCategory.VariableOrArgument:
          {
            ; No Advanced Editor available
            this.__SendOriginalHotkey("tab")
            return
          }
          case this.base.ActiveControlCategory.ExternalDialog:
          {
            ; Advanced Editor available but needs extra steps
          }
        }
      }
    */

    ; Remove "Add new row" item at the end
    this.uiaVarArgDataItemList.Pop()

    ; Find value field input elements that are of "data grid cell" type
    uiaDataGridCellInputFields := this.__LastDataGridCellChildFromEveryDataItem(this.uiaVarArgDataItemList)

    ; Try find the parent of the currently focused element. 
    ; The parent should be of "data grid cell" type.

    uiaFocused := this.uia.GetFocusedElement()

    try
    {
      uiaGridCellParent := this.base.DataGridCellWalker.NormalizeElement(uiaFocused)
    }
    catch
    {
      ; The focused control is not a (grand)child of one of data item elements
      ; → pass ordinary keys
      this.__SendOriginalHotkey(a_thishotkey)
      return
    }

    ; Check presence of IntelliSense popup.

    if (this.__IsStudioWindowActive())
    {
      ; Intellisense elements are descendants of the main Studio window
      uiaFirstChild := this.uia
          .ElementFromHandle(winactive())
          .TWGetChildren()[1]
    }
    else
    {
      ; Intellisense elements are descendants of the dialog window
      uiaFirstChild := this.base.WindowWalker
          .NormalizeElement(uiaGridCellParent)
          .GetChildren()[1]
    }

    if (uiaFirstChild.CurrentName == "" 
          && uiaFirstChild.CurrentControlType == UIA_Enum.UIA_WindowControlTypeId)
      {
        uiaIntelliSense := uiaFirstChild
            .FindFirstBy("LocalizedControlType=intelliprompt completion list"
                , UIA_Enum.Treescope_Children)
        
        if (uiaIntelliSense)
        {
          ; Intellisense visible → pass ordinary keys
          this.__SendOriginalHotkey(a_thishotkey)
          return
        }
      }
    

    ; Find the index of the currently selected value field and focus prev/next value field
    for idx, valueFieldItem in uiaDataGridCellInputFields
    {
      if (this.uia.CompareElements(valueFieldItem, uiaGridCellParent))
      {
        /*
          if (instr(a_thishotkey, "<#") && instr(a_thishotkey, "+"))
          {
            ; Advanced Editor requested by a user
            switch (this.activeCompatibleControlCategory)
            {
              case this.base.ActiveControlCategory.VariableOrArgument:
              {
                ; Handled earlier
              }
              case this.base.ActiveControlCategory.ExternalDialog:
              {
                ; Find and click the button
                this.__SendOriginalHotkey("tab")
                sleep, 1000
                a := valueFieldItem.CurrentExists
                ; msgbox % valueFieldItem.TWGetParent(3).TWRecursive()
                uiaAdvancedEditorButton := valueFieldItem.FindFirstByName("Advanced Options Menu")
                uiaAdvancedEditorButton.SetFocus()
                loop 2
                {
                  sleep, 400
                  uiaAdvancedEditorButton.Click()
                }
              }
            }

            return
          }
        */
        itemCount := uiaDataGridCellInputFields.Length()
        
        if (substr(a_thishotkey, 1, 1) == "+")
        {
          newIndex := this.__CalculateInputFieldNewIndex(idx, itemCount
              , this.base.TabDirection.Backward)
        }
        else
        {
          newIndex := this.__CalculateInputFieldNewIndex(idx, itemCount
              , this.base.TabDirection.Forward)
        }
        
        uiaDataGridCellInputFields[newIndex].Click()
        return
      }
    }

    ; The focused control is a (grand)child of one of data item elements
    ; but not a value input field → pass ordinary keys
    this.__SendOriginalHotkey(a_thishotkey)
  }

  __SendOriginalHotkey(hotkey)
  {
    send % substr(hotkey, 1, 1) == "+" 
        ? "+{" substr(hotkey, 2) "}" ; +{tab}
        : "{" hotkey "}" ; {tab}
  }

  __CalculateInputFieldNewIndex(currentIndex, maxIndex, direction)
  {
    switch (direction)
    {
      case this.TabDirection.Backward:
        return currentIndex == 1 ? maxIndex : currentIndex - 1
      case this.TabDirection.Forward:
        return currentIndex == maxIndex ? 1 : currentIndex + 1
      default: throw Exception("Invalid tab direction.", -2, direction)
    }
  }

  __LastDataGridCellChildFromEveryDataItem(uiaVarArgDataItemList)
  {
    uiaValueFieldItems := []

    for k, dataItem in uiaVarArgDataItemList
    {
      uiaDataGridCells := dataItem.FindAllBy("LocalizedControlType=data grid cell"
        , UIA_Enum.Treescope_Children) 
      
      uiaValueFieldItems.Push(uiaDataGridCells[4])
    }

    return uiaValueFieldItems
  }

  __TryFindDataGridInputFieldsFromFocusedElement()
  {
    uiaFocused := this.uia.GetFocusedElement()

    ; loc := uiaFocused.CurrentLocalizedControlType
    ; if (uiaFocused.CurrentLocalizedControlType != "text area")
    if (uiaFocused.CurrentLocalizedControlType != "editor view")
    {
      return false
    }

    try
    {
      dataGridCellParent := this.base.DataGridCellWalker.NormalizeElement(uiaFocused)
      
      ; No exception thrown → a match found! Retrieve all variable/argument data item elements

      ; this.uiaVarArgDataItemList := this.base.DataGridWalker
          ; .NormalizeElement(dataGridCellParent)
      this.uiaVarArgDataItemList := dataGridCellParent
          .TWGetParent(2)
          .FindAllByType(UIA_Enum.UIA_DataItemControlTypeId, UIA_Enum.TreeScope_Children)
      
      ; "Add new row" is always present as the final data item, so we must have found at 
      ; least three items to have two actual variables/arguments defined in the pane. 
      ; With just one found "real" item, tabbing through them makes no sense.
      if (this.uiaVarArgDataItemList.Length() > 2)
      {
        ; More than one compatible input field available

        this.activeCompatibleControlCategory := this.base
            .ActiveControlCategory.VariableOrArgument

        return true
      }
    }

    return false
  }

  __TryFindCompatibleDialogWindow()
  {
    static ignoredDialogTitles := [
    (join
      "ActiproWindowChromeShadow",
      "PlaceholderWindow",
      "Browse and Select a .Net Type"
    )]

    winget, valueWindowCandidateList, list, % "ahk_exe " this.base.dialogProcessName

    loop % valueWindowCandidateList
    {
      hCandidate := valueWindowCandidateList%a_index%
      wingettitle, candidateTitle, % "ahk_id " hCandidate
      
      for k, ignoredTitle in ignoredDialogTitles
      {
        if (ignoredTitle == candidateTitle)
        {
          hCandidate := 0
          break
        }
      }

      if (hCandidate)
      {
        ; A matching window found 
        return hCandidate
      }
    }

    return false
  }

  __IsCompatibleControlActive()
  {
    critical
    
    process, priority, , high

    static hPreviousCompatibleWindow := 0
    
    
    if (!winactive("ahk_exe " this.base.dialogProcessName))
    {
      ; A dialog window is not active → must still check if Studio main window is active

      oldMatchMode := a_titlematchmode
      settitlematchmode % this.base.studioWindow.titleMatchMode

      try
      {
        if (!winactive(this.base.studioWindow.title))
        {
          ; Studio main window is not active
          return false
        }
      }
      finally
      {
        settitlematchmode % oldMatchMode
      }

      ; Studio main window is active
      

      ; Check if any "Default [value]" input field
      ; is focused in a Variables/Arguments pane
      if (this.__TryFindDataGridInputFieldsFromFocusedElement())
      {
        return true
      }

      ; Check if a field is focused in the "Properties" pane
      ; return this.__XXXXXXX()
      return false
    }

    ; Potentially a compatible dialog window in a receptive state (i.e. a value field focused)
    ; may be available → check matching windows by excluding negative criteria
    
    if (this.__TryFindCompatibleDialogWindow())
    {
      ; Matching window found → retrieve data item elements
      return this.__TryFindDataGridInputFieldsFromFocusedElement()
    }
      /*
        uiaCandidate := this.uia.ElementFromHandle(hCandidate)

        this.uiaVarArgDataItemList := uiaCandidate
            .FindFirstByType(UIA_Enum.UIA_CustomControlTypeId, UIA_Enum.TreeScope_Children)
            .FindFirstByType(UIA_Enum.UIA_DataGridControlTypeId, UIA_Enum.TreeScope_Children)
            .FindAllByType(UIA_Enum.UIA_DataItemControlTypeId, UIA_Enum.TreeScope_Children)
      
        if (this.uiaVarArgDataItemList.Length() > 2)
        {
          ; More than one value field available
          this.activeCompatibleControlCategory := this.base.ActiveControlCategory.ExternalDialog
          return true
        }
      */

    return false
  }
}