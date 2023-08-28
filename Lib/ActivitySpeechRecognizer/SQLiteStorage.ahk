#requires AutoHotkey v1.1

class SQLiteStorage extends ActivitySpeechRecognizer.Activity.XamlStorage
{
  static DefaultIniFilePath := "SQLite\SQLiteDB.ini"
  static DefaultTableName := "SpeechRecognitionActivity"
  static DefaultColumnName := { uniqueVersion: "version" }

  __Get(key)
  {
    LogObjectPropertyDynamic(this, key)
  }

  __Call(methodName, params*)
  {
    LogObjectMethodDynamic(this, methodName, params*)
  }
  
  __New(uniqueVersion, tableName := "")
  {
    LogMethod(a_thisfunc, uniqueVersion, tableName)

    base.__New(uniqueVersion)

    this.tableName := tableName == "" ? this.base.DefaultTableName : tableName

    rereadSQLiteIniFile:
    try this.sqlDB := new SQLiteDB(this.base.DefaultIniFilePath)
    catch ex
    {
      switch (ex.Extra)
      {
        case SQLiteDB.ReturnCode("SQLITE_NODLL"): ; DLL file not found
          msgbox % format("A {}-bit SQLite DLL file was not found. "
              . "After dismissing this dialog, please select a suitable DLL file."
              , a_ptrsize == 8 ? "64" : "32")
          this.__OverwriteSettingsIniFile(this.base.DefaultIniFilePath)
          goto rereadSQLiteIniFile

        case SQLiteDB.ReturnCode("SQLITE_BADDLLFORMAT"): ; Incompatible DLL bitness (64/32)
          msgbox % format("The specified DLL file was of wrong bitness (likely {}-bit). "
              . "After dismissing this dialog, please select a suitable {}-bit DLL file."
                  , a_ptrsize == 8 ? "32" : "64", a_ptrsize == 8 ? "64" : "32")
          this.__OverwriteSettingsIniFile(this.base.DefaultIniFilePath)
          goto rereadSQLiteIniFile
        
        default:
          throw ex
      }
    }
  }

  __Delete()
  {
    LogMethod(a_thisfunc)
    
    this.Close()
  }


  ; =====================================
  ; PUBLIC INTERFACE FOR MANAGING SQLITE STORAGE
  ; =====================================

  Open(path)
  {
    if (!this.sqlDB.OpenDB(path))
    {
      throw Exception(this.sqlDB.ErrorMsg, -2, this.sqlDB.ErrorCode)
    }
  }

  Find(name, columnName := "")
  {
    ; Build a query
    numParams := 0

    stringlower, version, % this.uniqueVersion
    stringlower, name, name

    if (columnName == "")
    {
      columnName := this.base.DefaultColumnName.uniqueVersion
    }

    params := [version, name]

    query := "SELECT * FROM " this.tableName " WHERE "
        . "LOWER(" columnName ")='{" ++numParams "}' AND "
        . "LOWER(name)='{" ++numParams "}';"

    formattedQuery := format(query, params*)

    ; Execute the query
    if (!this.sqlDB.GetTable(formattedQuery, result))
    {
      throw Exception("SQL error.", , this.sqlDB.ErrorMsg)
    }

    ; Validate results
    if (!result.HasRows)
    {
      throw Exception(format("No activity was found in the database matching the "
          . "version ""{1}"" and the keyword ""{2}"".", this.uniqueVersion, name))
    }

    if (result.Rows.Length() > 1)
    {
      throw Exception("Duplicate results (" result.Rows.Length() ") found in the database "
          . "matching the version ""{1}"" and the keyword ""{2}"".", this.uniqueVersion, name)
    }

    return new UiPath.Studio.Toolkit.ActivitySpeechRecognizer.Activity(
      (join c
        result.Rows[1][1], ; id
        result.Rows[1][2], ; version
        result.Rows[1][3], ; name
        result.Rows[1][4]  ; xml
      ))
  }

  Close()
  {
    if (!this.sqlDB.CloseDB())
    {
      throw Exception(this.sqlDB.ErrorMsg ", error code: " this.sqlDB.ErrorCode, -2)
    }
  }

  /**
   * Test for the existence of a predefined table in an SQL file candidate.
   * @returns {boolean}
   */
  TestTable()
  {
    query := format("SELECT name FROM sqlite_master WHERE type='table' AND name='{}';"
        , this.tableName)
    
    ; Execute the query
    if (!this.sqlDB.GetTable(query, result))
    {
      throw Exception(this.sqlDB.ErrorMsg, -2, this.sqlDB.ErrorCode)
    }

    return result.HasRows
  }

  /**
   * Test for the existence of a predefined column in an SQL file candidate
   * @param {string} columnName Name of the column whose existence to verify in the table. 
   * Leave empty to use a predefined column name.
   * @returns {boolean}
   */
  TestColumn(columnName := "")
  {
    if (columnName == "")
    {
      columnName := this.base.DefaultColumnName.uniqueVersion
    }

    query := format("SELECT COUNT(*) FROM pragma_table_info('{}') where name='{}';"
        , this.tableName, columnName)
    
    ; Execute the query
    if (!this.sqlDB.GetTable(query, result))
    {
      throw Exception(this.sqlDB.ErrorMsg, -2, this.sqlDB.ErrorCode)
    }

    return result.Rows[1][1] == 1
  }


  ; =====================================
  ; PRIVATE HELPER METHODS
  ; =====================================

  __OverwriteSettingsIniFile(iniFilePath)
  {
    iniread, sqliteDllPathCandidate, % iniFilePath, Main, DllPath, 

    ; Prompt the user for the correct path

    if (sqliteDllPathCandidate != "")
    {
      sqliteDllBrowseStartFolder := regexreplace(sqliteDllPathCandidate, "\\[^\\]+$")
    }

    fileselectfile, sqliteDllPath, 1, % sqliteDllBrowseStartFolder "\sqlite*.dll"
        , % format("Select a {}-bit SQLite DLL file (typically sqlite3*.dll), *.dll"
            , a_ptrsize == 8 ? "64" : "32")
    
    if (errorlevel)
    {
      throw Exception(format("A proper SQLite DLL file not provided.", 
          , "A {}-bit SQLite DLL not found", a_ptrsize == 8 ? "64" : "32"))
    }

    ; Overwrite the path in the ini file

    iniwrite, % sqliteDllPath, % iniFilePath, Main, DllPath

    return true
  }
}