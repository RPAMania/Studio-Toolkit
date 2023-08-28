class XamlStorage
{
  static ErrorCode :=
  (join
    { 
      BlankUniqueVersion: 0
    }
  )

  class Type
  {
    static XMLFile := "XMLFile", SQLite := "SQLite"
  }
  
  __New(uniqueVersion)
  {
    LogMethod(a_thisfunc, uniqueVersion)

    if (uniqueVersion == "")
    {
      throw Exception("Xaml storage options must contain a non-blank unique version.", -2
          , this.base.ErrorCode.BlankUniqueVersion)
    }

    this.uniqueVersion := uniqueVersion
  }

  Open(fullPath, params*)
  {
    throw Exception("Not implemented")
  }

  Find(name)
  {
    throw Exception("Not implemented")
  }

  Close(params*)
  {
    throw Exception("Not implemented")
  }
}