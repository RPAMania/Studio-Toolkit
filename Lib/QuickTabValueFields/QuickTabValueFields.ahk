class QuickTabValueFields
{
  static VersionNumber := "0.0.1 alpha"
}

#include <UIA_Interface>

; setbatchlines, -1

; new SomeClass()

class SomeClass
{
  static TabDirection := { Forward: "Tab_Forward", Backward: "Tab_Backward" }
  static DataGridCellWalker := UIA_Interface().CreateTreeWalker(
  (join
      UIA_Interface().CreatePropertyCondition(
          UIA_Enum.UIA_PropertyId("LocalizedControlType"),
          "data grid cell")
  ))
    
  __New()
  {
    this.uia := UIA_Interface()

    ; Setup a hotkey
    fn := this.IsCompatibleValueWindowActive.Bind(this)
    hotkey, if, % fn
    
    fn := this.SimulateTab.Bind(this)
    hotkey, tab, % fn
    hotkey, +tab, % fn

    hotkey, if

  }

  SimulateTab()
  {
    critical

    ; Remove "Add new row" item at the end
    this.uiaDataItemList.Pop()

    ; Find parent elements of "data grid cell" type
    uiaValueFieldItems := this.__ExtractDataGridCellChildren(this.uiaDataItemList)

    ; Try find the parent of the currently focused element. 
    ; The parent should be of "data grid cell" type.
    uiaFocused := this.uia.GetFocusedElement()
    uiaGridCellParent := this.DataGridCellWalker.NormalizeElement(uiaFocused)

    if (!uiaGridCellParent)
    {
      ; The focused control is not a (grand)child of one of data item elements
      ; → pass ordinary keys
      this.__SendOriginalTabHotkey()
      return
    }

    ; Check presence of IntelliSense popup
    uiaFirstChild := this.base.WindowWalker.NormalizeElement(uiaGridCellParent)
        .GetChildren()[1]
    
    if (uiaFirstChild.CurrentName == "" 
        && uiaFirstChild.CurrentControlType == UIA_Enum.UIA_WindowControlTypeId)
    {
      uiaIntelliSense := uiaFirstChild.FindFirstBy(""
          . "LocalizedControlType=intelliprompt completion list"
          , UIA_Enum.Treescope_Children)
      
      if (uiaIntelliSense)
      {
        ; Intellisense visible → pass ordinary keys
        this.__SendOriginalTabHotkey()
        return
      }
    }

    ; Find the index of the currently selected value field and focus prev/next value field
    for idx, valueFieldItem in uiaValueFieldItems
    {
      if (this.uia.CompareElements(valueFieldItem, uiaGridCellParent))
      {
        itemCount := uiaValueFieldItems.Length()
        
        if (substr(a_thishotkey, 1, 1) == "+")
        {
          newIndex := this.__CalculateValueFieldNewIndex(idx, itemCount
              , this.base.TabDirection.Backward)
        }
        else
        {
          newIndex := this.__CalculateValueFieldNewIndex(idx, itemCount
              , this.base.TabDirection.Forward)
        }
        
        uiaValueFieldItems[newIndex].Click()
        return
      }
    }

    ; The focused control is a (grand)child of one of data item elements
    ; but not a value input field → pass ordinary keys
    this.__SendOriginalTabHotkey()
  }

  __SendOriginalTabHotkey()
  {
    send % substr(a_thishotkey, 1, 1) == "+" 
        ? "+{" substr(a_thishotkey, 2) "}" ; +{tab}
        : "{" a_thishotkey "}" ; {tab}
  }

  __CalculateValueFieldNewIndex(currentIndex, maxIndex, direction)
  {
    switch (direction)
    {
      case this.TabDirection.Backward:
        return currentIndex == 1 ? maxIndex : currentIndex - 1
      case this.TabDirection.Forward:
        return currentIndex == maxIndex ? 1 : currentIndex + 1
      default:
          throw Exception("Invalid tab direction.", -2, direction)
    }
  }

  __ExtractDataGridCellChildren(uiaDataItemList)
  {
    uiaValueFieldItems := []

    for k, dataItem in uiaDataItemList
    {
      uiaDataGridCells := dataItem.FindAllBy("LocalizedControlType=data grid cell"
        , UIA_Enum.Treescope_Children) 
      
      uiaValueFieldItems.Push(uiaDataGridCells[4])
    }

    return uiaValueFieldItems
  }

  IsCompatibleValueWindowActive()
  {
    critical

    static hPreviousCompatibleWindow := 0
    static validProcessName := "UiPath.Studio.Launcher.exe"
    static invalidTitles := [ "ActiproWindowChromeShadow", "PlaceholderWindow" ]
    
    if (!winactive("ahk_exe " validProcessName))
    {
      oldMatchMode := a_titlematchmode
      settitlematchmode, regex

      try
      {
        if (!winactive(".*- UiPath Studio ahk_exe UiPath\.Studio\.exe"))
        {
          ; Studio not the active window
          return false
        }
      }
      finally
      {
        settitlematchmode % oldMatchMode
      }

      ; Studio active → keep checking if any "Default [value]" field  
      ; is focused in Variables/Arguments panel

      uiaFocused := this.uia.GetFocusedElement()

      try
      {
        dataGridCellParent := this.base.DataGridCellWalker.NormalizeElement(uiaFocused)

        ; A match found! Retrieve all variable/argument data item elements

        twt := this.uia.TreewalkerTrue

        this.uiaDataItemList := twt.GetParentElement(twt.GetParentElement(dataGridCellParent))
            .FindAllByType(UIA_Enum.UIA_DataItemControlTypeId, UIA_Enum.TreeScope_Children)

        if (this.uiaDataItemList.Length() > 2)
        {
          ; More than one variable/argument available
          return true
        }
      }

      return false
    }

    ; Potentially a compatible window in a receptive state (i.e. a value field focused)
    ; may be available → check matching windows by excluding negative criteria
    winget, valueWindowCandidateList, list, % "ahk_exe " validProcessName

    loop % valueWindowCandidateList
    {
      hCandidate := valueWindowCandidateList%a_index%
      wingettitle, candidateTitle, % "ahk_id " hCandidate
      
      for k, invalidTitle in invalidTitles
      {
        if (invalidTitle == candidateTitle)
        {
          hCandidate := 0
          break
        }
      }

      if (!hCandidate)
      {
        ; No matching window found 
        continue
      }

      ; Matching window found → retrieve data item elements
      uiaCandidate := this.uia.ElementFromHandle(hCandidate)

      this.uiaDataItemList := uiaCandidate
          .FindFirstByType(UIA_Enum.UIA_CustomControlTypeId, UIA_Enum.TreeScope_Children)
          .FindFirstByType(UIA_Enum.UIA_DataGridControlTypeId, UIA_Enum.TreeScope_Children)
          .FindAllByType(UIA_Enum.UIA_DataItemControlTypeId, UIA_Enum.TreeScope_Children)
    
      if (this.uiaDataItemList.Length() > 2)
      {
        ; More than one value field available
        return true
      }
    }

    return false
  }
}