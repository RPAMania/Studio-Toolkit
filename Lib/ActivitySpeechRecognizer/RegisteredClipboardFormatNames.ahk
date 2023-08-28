class RegisteredClipboardFormatNames
{
  static SystemString := { Name: "System.String", Value: 0 }
  static WorkflowXamlFormat := { Name: "WorkflowXamlFormat", Value: 0 }
  static WorkflowXamlFormat_TargetFramework := { Name: "WorkflowXamlFormat_TargetFramework"
      , Value: 0 }

  ; MSDN: "RegisterClipboardFormatA -- Registered clipboard formats 
  ; are identified by values in the range 0xC000 through 0xFFFF"
  static iRegisteredClipboardFormat := { First: 0xC000, Last: 0xFFFF }

  static ClipboardFormatNameNotFoundExceptionMessage = ""
      . "Not all UiPath-related clipboard formats were found. Possible reason:`n"
      . "You haven't run UiPath Studio since the last login and/or "
      . "haven't copied any activity into the clipboard in Studio. These steps "
      . "must be carried out in order to regenerate clipboard formats.`n`n"
      . "Fix: Run Studio and copy any activity into the clipboard once. Then retry."

  __Get(key)
  {
    LogObjectPropertyDynamic(this, key)
  }

  __Call(methodName, params*)
  {
    LogObjectMethodDynamic(this, methodName, params*)
  }
  
  ; =====================================
  ; PUBLIC INTERFACE FOR UPDATING CLIPBOARD FORMATS
  ; =====================================
  
  Update()
  {
    if  (!this.SystemString.Value
      || !this.WorkflowXamlFormat.Value
      || !this.WorkflowXamlFormat_TargetFramework.Value)
    {
      LogMethod(a_thisfunc)

      this.__TryFindFormats()

      missingFormats := this.__GetMissingFormats()
      if (missingFormats.length() > 0)
      {
        missingFormatString := ""

        loop % missingFormats.length()
        {
          missingFormatString .= missingFormats[a_index] ", "
        }

        ; Remove trailing extra comma and space
        missingFormatString := substr(missingFormatString, 1, -2)

        throw Exception(this.ClipboardFormatNameNotFoundExceptionMessage
            , , missingFormatString)
      }
    }
  }


  ; =====================================
  ; METHODS FOR INTERNAL CLIPBOARD FORMAT HANDLING
  ; =====================================

  __TryFindFormats()
  {
    LogMethod(a_thisfunc)

    registeredFormatCount := this.iRegisteredClipboardFormat.Last 
        - this.iRegisteredClipboardFormat.First + 1

    ; Reserve 255 char buffer
    charBytes := a_isunicode ? 2 : 1
    formatNameMaxCharLength := floor(varsetcapacity(formatName, 255 * charBytes, 0) / charBytes)
    
    loop % registeredFormatCount
    {
      iCurrentRegisteredClipboardFormat := this.iRegisteredClipboardFormat.First + a_index - 1

      if (dllcall("GetClipboardFormatName"
        , int, iCurrentRegisteredClipboardFormat
        , str, formatName
        , int, formatNameMaxCharLength))
      {
        if (formatName == this.SystemString.Name)
        {
          this.SystemString.Value := iCurrentRegisteredClipboardFormat ; 0xc399
        }
        else if (formatName == this.WorkflowXamlFormat.Name)
        {
          this.WorkflowXamlFormat.Value := iCurrentRegisteredClipboardFormat ; 0xc002
        }
        else if (formatName == this.WorkflowXamlFormat_TargetFramework.Name)
        {
          this.WorkflowXamlFormat_TargetFramework.Value := iCurrentRegisteredClipboardFormat ; 0xc003
        }

        if (this.SystemString.Value 
            && this.WorkflowXamlFormat.Value 
            && this.WorkflowXamlFormat_TargetFramework.Value)
        {
          break
        }
      }
    }
  }

  __GetMissingFormats()
  {
    LogMethod(a_thisfunc)

    missingFormats := []
    
    if (!this.SystemString.Value)
    {
      missingFormats.Push(this.SystemString.Name)
    }
    if (!this.WorkflowXamlFormat.Value)
    {
      missingFormats.Push(this.WorkflowXamlFormat.Name)
    }
    if (!this.WorkflowXamlFormat_TargetFramework.Value)
    {
      missingFormats.Push(this.WorkflowXamlFormat_TargetFramework.Name)
    }

    return missingFormats
  }
}