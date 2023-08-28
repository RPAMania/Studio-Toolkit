static validationMessage :=
(join`s c ltrim
  {
    uniqueVersion:
    {
      ok:
      {
        title: "OK",
        text: "A valid non-blank version string."
      },
      error: 
      {
        blankOrWhitespace:
        {
          title: "A blank or whitespace version string",
          text: "A version string carries a different purpose depending on the template 
              storage type selected below:
              `r`n• XMLFile: The template storage path must point to a folder. The version
              string specifies a name for a subdirectory that must be located directly
              underneath the given template storage path. This subdirectory should
              contain activity XML files, specific to the given version number, that
              are searched through for a match to a recognized spoken keyword.
              `r`n• SQLite: The template storage path must point to an SQLite database
              file. The version string specifies the value to match under the ""{1}""
              database column. The version string determines which activity version
              rows stored in the database are searched through for a match to a
              recognized spoken keyword.`r`n
              `r`nExample 1: Given the version string ""2021.10.5"", the template storage 
              type XMLFile and the template storage path 
              ""C:\Users\Myself\Documents\ActivityTemplates\XML"", you should have
              XML activity template files sitting in the
              C:\Users\Myself\Documents\ActivityTemplates\XML\2021.10.5\ directory.`r`n
              `r`nExample 2: Given the version string ""UiPath_workplace_version_2022.10"", 
              the template storage type SQLite and the template storage path 
              ""C:\sqlite\uipath.db"", you should have activity template rows
              added in the SQLite database with the string 
              ""UiPath_workplace_version_2022.10"" in the ""{1}"" column."
        },
        forbiddenCharacters:
        {
          title: "Forbidden character(s)",
          text: "Version string can't contain any of the following characters:`r`n{1}"
        }
      }
    },
    templateStorageType:
    {
      ok:
      {
        title: "OK",
        text: "A valid template storage type and a compatible SQLite DLL binary."
      },
      error:
      {
        typeMissing:
        {
          title: "Unset template storage type",
          text: "Select one of the available storage types:`r`n
              • XMLFile: Activities to reproduce as a response to speech are stored
              as XML files on a drive.`r`n
              • SQLite: Activities to reproduce as a response to speech are stored
              as rows in an SQLite database."
        },
        typeUnknown:
        {
          title: "Unknown template storage type",
          text: "Internal error: template storage type ""{1}"" was not recognized."
        },
        unableToTestStorageType:
        {
          SQLite:
          {
            title: "Unable to test the SQLite connection",
            text: "Provide a non-blank unique version to validate SQLite database connection."
          }
        }
      }
    },
    templateStoragePath:
    {
      ok:
      {
        XMLFile:
        {
          title: "OK",
          text: "{1} XML file(s) found. Activity names include:{2}"
        },
        SQLite:
        {
          title: "OK",
          text: "A database file containing the recognized table and its version column found."
        }
      },
      warn:
      {
        unrecognizedFileType:
        {
          SQLite:
          {
            title: "Unusual database file extension",
            text: "The given file ""{1}""`r`ndoes not have the common "".db"" extension 
                typical for SQLite database storage files. This does not necessarily 
                mean that the file is invalid."
          }
        },
        filesNotFound:
        {
          XMLFile:
          {
            title: "Directory found but missing XML files",
            text: "The directory ""{1}""`r`ndoes not contain any .xml files. This is 
                fine if you know you will be later adding XML files in the directory."
          }
        }
      },
      error:
      {
        pathMissing:
        {
          title: "Missing path",
          text: "Based on the chosen template storage type, the template storage path 
              must be pointing to:`r`n
              • XMLFile: A directory that should contain a subdirectory (with activity XML 
                  files inside) whose name matches the given unique version string.`r`n
              • SQLite: A database storage file, typically with a .db extension."
        },
        pathNotFound:
        {
          XMLFile:
          {
            title: "Directory not found",
            text: "The given template storage path does not point to an existing directory."
          },
          SQLite:
          {
            title: "File not found",
            text: "The given template storage path does not point to an existing file."
          }
        },
        pathWithVersionStringNotFound: 
        {
          XMLFile:
          {
            title: "Version string subdirectory not found",
            text: "A subdirectory named according to the version string ""{1}"" not found 
                under the given path."
          }
        },
        unableToTestFile:
        {
          SQLite:
          {
            title: "Unable to test the database file",
            text: "Validity of the database file could not be confirmed due to an SQLite DLL 
                file not being available."
          }
        },
        columnNotFound:
        {
          SQLite:
          {
            title: "Column not found",
            text: "The database table ""{1}"" doesn't have a column by the name ""{2}""."
          }
        },
        tableNotFound:
        {
          SQLite:
          {
            title: "Table not found",
            text: "The database doesn't have a table by the name ""{1}""."
          }
        },
        invalidDatabaseFile:
        {
          SQLite:
          {
            title: "Invalid file",
            text: "The file is not a valid SQLite database file."
          }
        },
        unspecifiedError:
        {
          SQLite:
          {
            title: "Unspecified SQL Error",
            text: "SQLite error code {}: {}"
          }
        },
        forbiddenCharacters:
        {
          title: "Forbidden character(s)",
          text: "The template storage path can't contain any of the following characters:`r`n{1}"
        }
      }
    },
    keywordFilePath:
    {
      ok:
      {
        title: "OK",
        text: "A file containing {1} keyword(s) found. Keywords include:{2}"
      },
      error:
      {
        fileMissing:
        {
          title: "Missing location",
          text: "A keyword file is an ordinary text file with one keyword (or a phrase
              comprised of multiple words) per each line. Incoming audio signal will be
              monitored for these keywords, and when recognized, a keyword is then used 
              to search for a matching activity in the chosen storage."
        },
        fileNotFound:
        {
          title: "File not found",
          text: "Given path does not point to a file."
        },
        forbiddenCharacters:
        {
          title: "Forbidden character(s)",
          text: "Path can't contain any of the following characters:`r`n{1}"
        },
        noKeywordsInFile:
        {
          title: "Keywordless file",
          text: "The file does not define any keywords."
        }
      }
    },
    hotkey:
    {
      ok:
      {
        title: "Hotkey has been assigned",
        text: "The hotkey ""{1}"" successfully set."
      },
      error:
      {
        hotkeyAlreadyInUse:
        {
          title: "Hotkey already in use",
          text: "Hotkey ""{1}"" is already assigned for another operation."
        },
        invalidHotkey:
        {
          title: "Invalid hotkey",
          text: "Hotkey ""{1}"" is invalid/unsupported."
        },
        hotkeyNotAssigned:
        {
          title: "Unset hotkey",
          text: "A hotkey to activate listening to incoming audio has not yet been assigned."
        }
      }
    }
  }
)