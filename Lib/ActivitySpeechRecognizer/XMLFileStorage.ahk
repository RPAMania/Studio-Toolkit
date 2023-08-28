#requires AutoHotkey v1.1

class XMLFileStorage extends ActivitySpeechRecognizer.Activity.XamlStorage
{
  __Get(key)
  {
    LogObjectPropertyDynamic(this, key)
  }

  __Call(methodName, params*)
  {
    LogObjectMethodDynamic(this, methodName, params*)
  }

  __New(uniqueVersion, params*)
  {
    LogMethod(a_thisfunc, uniqueVersion, params*)

    base.__New(uniqueVersion)
  }


  ; =====================================
  ; PUBLIC INTERFACE FOR MANAGING XML FILE STORAGE
  ; =====================================
  
  Open(path)
  {
    this.rootPath := regexreplace(path, "\\$")
  }

  Find(name)
  {
    static XMLFileReadExceptionMessage := "Failed to read contents of the XML file ""{1}""."

    ; Build a file path, removing any whitespace in the name subcomponent
    whitespacelessName := regexreplace(name, "\s")
    fileFolder := this.rootPath "\" this.uniqueVersion
    filePath := fileFolder "\" whitespacelessName ".xml"

    if (!fileexist(filePath))
    {
      ; Try a secondary method to find a file with a substring postfix with a leading dot in
      ; its name, i.e. name == "Assign" → will find "System.Activities.Statements.Assign.xml". 
      ; This allows prefixing the file name with other metadata (namespace etc) to
      ; perhaps more easily differentiate between them.
      filePath := ""
      loop, files, % fileFolder "\*.xml"
      {
        if (a_loopfilename ~= "i)\." whitespacelessName ".xml$")
        {
          filePath := a_loopfilefullpath
          break
        }
      }

      if (filePath == "")
      {
        ; One last attempt from the 2nd line of each file's contents
        loop, files, % fileFolder "\*.xml"
        {
          filePath := a_loopfilepath
          try
          {
            filereadline, nameCandidate, % filePath, 2

            if (nameCandidate ~= "i)^\s*\Q" name "\E$")
            {
              ; Keyword matched on the 2nd line
              
              goto activityFound
            }
          }
          catch ex
          {
            if (ex.Message != 1)
            {
              throw Exception(format(XMLFileReadExceptionMessage, filePath), , ex.Message)
            }
          }
        } 
        throw Exception(format("No XML file matching the keyword ""{1}"" was found.", name))
      }
    }

    activityFound:
    try
    {
      filereadline, xmlFileContents, % filePath, 1
    }
    catch ex
    {
      throw Exception(format(XMLFileReadExceptionMessage, filePath), , ex.Message)
    }

    return new UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity(-1, this.uniqueVersion
        , name, xmlFileContents)
  }

  Close(params*)
  {
  }
}