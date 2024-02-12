/**
 * ============================================================================ *
 * @Author           : RaptorX <graptorx@gmail.com>, modified by TJay🐦
 * @Script Name      : Script Object
 * @Script Version   : 0.20.2
 * @Homepage         :
 *
 * @Creation Date    : November 09, 2020
 * @Modification Date: July 02, 2021
 *
 * @Description      :
 * -------------------
 * This is an object used to have a few common functions between scripts
 * Those are functions and variables related to basic script information,
 * upgrade and configuration.
 *
 * ============================================================================ *
 */

; global script := {base         : script
;                  ,name          : regexreplace(A_ScriptName, "\.\w+")
;                  ,version      : "0.1.0"
;                  ,author       : ""
;                  ,email        : ""
;                  ,crtdate      : ""
;                  ,moddate      : ""
;                  ,homepagetext : ""
;                  ,homepagelink : ""
;                  ,donateLink   : "https://www.paypal.com/donate?hosted_button_id=MBT5HSD9G94N6"
;                  ,resfolder    : A_ScriptDir "\res"
;                  ,iconfile     : A_ScriptDir "\res\sct.ico"
;                  ,configfile   : A_ScriptDir "\settings.ini"
;                  ,configfolder : A_ScriptDir ""}

#requires AutoHotkey v1.1

class script
{
  static DBG_NONE     := 0
        ,DBG_ERRORS   := 1
        ,DBG_WARNINGS := 2
        ,DBG_VERBOSE  := 3

  static name         := ""
        ,version      := ""
        ,author       := ""
        ,email        := ""
        ,crtdate      := ""
        ,moddate      := ""
        ,homepagetext := ""
        ,homepagelink := ""
        ,resfolder    := ""
        ,icon         := ""
        ,config       := ""
        ,systemID     := ""
        ,dbgFile      := ""
        ,dbgLevel     := this.DBG_NONE


  /**
    Function: Update
    Checks for the current script version
    Downloads the remote version information
    Compares and automatically downloads the new script file and reloads the script.

    Parameters:
    vfile - Version File
            Remote version file to be validated against. If rfile is blank, vfile 
            will be treated both
            * as a URL to a releases HTML page of a version (specific or 
              "latest") from which the version number will be extracted.
            and
            * as the URL to a GitHub releases page from which to extract the
              download link

    rfile - Remote File
            Script file to be downloaded and installed if a new version is found.
            Should be a zip file that will be unzipped by the function.
    

    Notes:
    The versioning file should only contain a version string and nothing else.
    The matching will be performed against a SemVer format and only the three
    major components will be taken into account.

    e.g. '1.0.0'

    For more information about SemVer and its specs click here: <https://semver.org/>
  */
  Update(downloadConfirmationExtraMessage, vfile, rfile := "")
  {
    ; Error Codes
    static ERR_INVALIDVFILE := 1
    ,ERR_INVALIDRFILE       := 2
    ,ERR_NOCONNECT          := 3
    ,ERR_NORESPONSE         := 4
    ,ERR_INVALIDVER         := 5
    ,ERR_CURRENTVER         := 6
    ,ERR_MSGTIMEOUT         := 7
    ,ERR_USRCANCEL          := 8

    ; IWinHttpRequest COM object's WinHttpRequestOption for retrieving the URL from a response
    static WinHttpRequestOption_URL := 1
    
    if (rfile == "")
    {
      rfile := vfile
    }

    ; A URL is expected in this parameter, we just perform a basic check
    if (!(vfile ~= "i)^((?:http(?:s)?|ftp):\/\/)?((?:[a-z0-9_\-]+\.)+.*$)"))
      throw {code: ERR_INVALIDVFILE, msg: "Invalid URL`n`n"
          . "The version file parameter must point to a valid URL."}

    ; This function expects a ZIP file or a GitHub URL ending "/latest" or "/tag/v[versionNumber]"
    if (!(rfile ~= "i)\.zip") && 
        !(rfile ~= "i)^(https?:\/\/)?github.com/.*/releases/(latest|(tag/)?v(\d\.){2}\d)$"))
      throw {code: ERR_INVALIDRFILE, msg: "Invalid Zip or URL to a GitHub release page`n`n"
          . "The remote file parameter must either point to "
          . "a zip file or be a URL to a page of a specific GitHub release version." }

    ; Check if we are connected to the internet
    http := ComObjCreate("WinHttp.WinHttpRequest.5.1")
    http.Open("GET", "https://www.google.com", true)
    http.Send()
    try
      http.WaitForResponse(1)
    catch e
      throw {code: ERR_NOCONNECT, msg: e.message}

    Progress, 50, 50/100, % "Checking for updates", % "Updating"

    ; Download remote version file
    http.Open("GET", vfile, true)
    http.Send(), http.WaitForResponse()

    if (!http.responseText)
    {
      Progress, OFF
      throw {code: ERR_NORESPONSE
          , msg: "There was an error trying to download the version info.`n"
              . "The server did not respond."}
    }

    if (http.Status == 404)
    {
      Progress, OFF
      throw {code: ERR_INVALIDVFILE
          , msg: "Version file was not found via the given url." }
    }

    regexmatch(this.version, "\d+\.\d+\.\d+", loVersion)
    regexmatch(http.responseText, "(?<=\bv)\d+\.\d+\.\d+\b", remVersion)

    Progress, 100, 100/100, % "Checking for updates", % "Updating"
    sleep 500 	; allow progress to update
    Progress, OFF

    ; Make sure SemVer is used
    if (!loVersion || !remVersion)
      throw {code: ERR_INVALIDVER, msg: "Invalid version.`nThis function works with SemVer. "
                      . "For more information refer to the documentation in the function"}

    ; Compare against current stated version
    ver1 := strsplit(loVersion, ".")
    ver2 := strsplit(remVersion, ".")
    
    newVersion := false

    for i1,num1 in ver1
    {
      for i2,num2 in ver2
      {
        if (i1 == i2)
          if (num2 > num1)
          {
            newVersion := true
            break 2
          }
          else if (num2 < num1)
          {
            break 2
          }
      }
    }

    if (!newVersion)
      throw {code: ERR_CURRENTVER, msg: "You are using the latest version"}
    else
    {
      ; If new version ask user what to do
			; Yes/No | Icon Question | System Modal
			msgbox % 0x4 + 0x20 + 0x1000
          , % "New Update Available"
          , % "There is a new update available for this application.`n"
            . downloadConfirmationExtraMessage
            . "Do you wish to upgrade to v" remVersion "?"
          , 20	; timeout
      

      ifmsgbox timeout
				throw {code: ERR_MSGTIMEOUT, msg: "The Message Box timed out."}
			ifmsgbox no
				throw {code: ERR_USRCANCEL, msg: "The user pressed the cancel button."}

      ; Create temporal dirs
      zipFileContainerDirCandidates := []
      extensionlessFileName := regexreplace(a_scriptname, "\..*$")
      if (InStr(rfile, "github"))
      {
        zipFileContainerDirCandidates.Push(format("{}-{}", extensionlessFileName, remVersion))
      }

      filecreatedir % tmpDir := a_temp "\" extensionlessFileName

      zipDir := tmpDir "\uzip"
      try
      {
        fileremovedir, % zipDir, true
      }
			filecreatedir % zipDir

      ; Create lock file
      try
      {
        filedelete % tmpDir "\lock"
      }
      fileappend % a_now, % lockFile := tmpDir "\lock"

      ; Download zip file
      try
      {
        try
        {
          filedelete, % tmpDir "\temp.zip"
        }
        
        if (rfile ~= "i)\.zip$")
        {
          ; .zip location given directly
          
          zipFileDownloadUrl := rfile
        }
        else
        {
          ; GitHub release page URL given
          
          ; https://github.com
          domain := regexreplace(rfile, "^(.*?)(?<![:\/])(?=\/).*", "$1")

          if (rfile ~= "i)latest$")
          {
            if (instr(http.ResponseText, ">Pre-release<"))
            {
              ; No "latest" version available → grab a tag from a pre-release page

              ; From https://github.com/[Account]/[project]/releases
              ; to   https://github.com/[Account]/[project]/releases/v[versionNumber]
              regexmatch(http.ResponseText, "(?<=<a href="")[^\n]+\/tag\/v\Q" remVersion "\E(?="")"
                  , tagUrlSnippet)
              gitReleasePageUrl := domain tagUrlSnippet
            }
            else
            {
              ; From  https://github.com/[Account]/[project]/releases/latest
              ; to    https://github.com/[Account]/[project]/releases/tag/v[latestVersionNumber]
              gitReleasePageUrl := http.Option(WinHttpRequestOption_URL)
            }
          }
          else if (rfile ~= "i)(?<!tag/)v\Q" remVersion "\E$")
          {
            ; From  https://github.com/[Account]/[project]/releases/v[versionNumber]
            ; to    https://github.com/[Account]/[project]/releases/tag/v[versionNumber]
            gitReleasePageUrl := regexreplace(rFile, "^(.*)?\/(v" remVersion ")$", "$1/tag/$2")
          }
          else
          {
            ; Already https://github.com/[Account]/[project]/releases/tag/v[versionNumber]
            gitReleasePageUrl := rFile
          }
          
          ; https://github.com/[Account]/[project]/releases/expanded_assets/v[versionNumber]
          gitDownloadPageUrl := strreplace(gitReleasePageUrl, "/tag/", "/expanded_assets/")
          http.Open("GET", gitDownloadPageUrl, true)
          http.Send()
          http.WaitForResponse()

          if (http.Status != 200)
          {
            throw {code: ERR_NORESPONSE, msg: format("There was an error trying to retrieve a "
                . ".zip file download link from a GitHub page.`n`n"
                . "Status code: {1}`nServer response: {2}", http.Status, http.responseText)}
          }

          if (a_iscompiled)
          {
            ; Pinpoint download URL of the .zip file containing the executable in GitHub
            ; /[Account]/[Project]/releases/download/v[versionNumber]/[filenameWithoutExtension].zip
            ; OR
            ; /[Account]/[Project]/releases/download/v[versionNumber]/[filenameWithoutExtension]_[versionNumber].zip
            regexmatch(http.responseText, "(?<=<a href="")[^\n]*\/releases\/[^\n]*" 
                . "(?:_\Q" remVersion "\E)?\.zip(?="" )", urlWithoutDomain)
          }
          else
          {
            ; Pinpoint download URL of the .zip file containing script source code in GitHub
            ; /[Account]/[Project]/archive/refs/tags/v[versionNumber].zip
            regexmatch(http.responseText
                , "(?<=<a href="")[^\n]*?\/tags\/v\Q" remVersion "\E\.zip(?="" )", urlWithoutDomain)
          }

          ; https://github.com/[Account]/[Project]/releases/download/v[versionNumber]/[filenameWithoutExtension].zip
          ; OR
          ; https://github.com/[Account]/[Project]/releases/download/v[versionNumber]/[filenameWithoutExtension]_[versionNumber].zip
          ; OR
          ; https://github.com/[Account]/[Project]/archive/refs/tags/v[versionNumber].zip
          zipFileDownloadUrl := domain urlWithoutDomain
        }

        urldownloadtofile % zipFileDownloadUrl, % tmpDir "\temp.zip"
      }
      catch e
      {
        throw {code: ERR_NORESPONSE, msg: "There was an error trying to download the "
            . ".zip file.`nThe server did not respond."}
      }
      
      ; Extract zip file to temporal folder
      oShell := ComObjCreate("Shell.Application")
      oDir := oShell.NameSpace(zipDir), oZip := oShell.NameSpace(tmpDir "\temp.zip")
      oDir.CopyHere(oZip.Items), oShell := oDir := oZip := ""

      try
      {
        filedelete % tmpDir "\temp.zip"
      }

      /*
      ******************************************************
      * Wait for lock file to be released
      * Copy all files to current script directory
      * Cleanup temporal files
      * Run main script
      * EOF
      *******************************************************
      */

      if (!a_iscompiled && zipFileContainerDirCandidates.Length() > 0)
      {
        ; Validate a container subdirectory inside the .zip file that contains sources

        containerCandidateDirsString := ""
        for idx, dirCandidate in zipFileContainerDirCandidates
        {
          ; Build comma-separated string for logging
          containerCandidateDirsString .= "> " dirCandidate ", "
          
          if (instr(fileexist(zipDir "\" dirCandidate), "D"))
          {
            zipFileContainerDir := dirCandidate "\"
            break
          }

          if (instr(fileexist(zipDir "\" strreplace(dirCandidate, " ", "-")), "D"))
          {
            zipFileContainerDir := strreplace(dirCandidate, " ", "-") "\"
            break
          }
        }

        containerCandidateDirsString := substr(containerCandidateDirsString, 1, -2)
        
        if (zipFileContainerDir == "")
        {
          ; Prepare and throw the error

          ; Build comma-separated string for logging
          actualContainerDirsString := "> [root], "
          loop, files, % zipDir "\*.*", % "D"
          {
            actualContainerDirsString .= "`r`n> " a_loopfilename ", "
          }

          actualContainerDirsString := SubStr(actualContainerDirsString, 1, -2)

          throw Exception(format("A container subdirectory inside the .zip file downloaded "
              . "from GitHub was not`nrecognized among preset subdirectories.`n`nFollowing "
              . "presets were searched in '{1}':`n{2}`n`nFollowing subdirectories were "
              . "found:`n{3}", zipDir, containerCandidateDirsString, actualContainerDirsString))
        }
      }
      else
      {
        ; .zip file contains a naked executable, no container subdirectory expected
        zipFileContainerDir := ""
      }

      if (a_iscompiled)
      {
        tmpBatch = 
        (Ltrim
					:lock
					if not exist "%lockFile%" goto continue
					timeout /t 10
					goto lock
					:continue

					xcopy "%zipDir%\%zipFileContainerDir%*.*" "%a_scriptdir%\" /E /C /I /Q /R /K /Y
					if exist "%a_scriptfullpath%" cmd /C "%a_scriptfullpath%"

					cmd /C "rmdir "%tmpDir%" /S /Q"
					exit
				)
        
        try
        {
          filedelete % tmpDir "\update.bat"
        }
        fileappend % tmpBatch, % tmpDir "\update.bat"
        run % a_comspec " /c """ tmpDir "\update.bat""",, hide
      }
      else
      {
        tmpScript =
        (Ltrim
					while (fileExist("%lockFile%"))
						sleep 10

					FileCopyDir %zipDir%\%zipFileContainerDir%, %a_scriptdir%, true
					FileRemoveDir %tmpDir%, true

					if (fileExist("%a_scriptfullpath%"))
						run %a_scriptfullpath%
					else
						msgbox `% 0x10 + 0x1000
                , `% "Update Error"
                , `% "There was an error while running the updated version.``n"
                . "Try to run the program manually."
                ,  10
						exitapp
				)
        try
        {
          filedelete % tmpDir "\update.ahk"
        }
        fileappend % tmpScript, % tmpDir "\update.ahk"
        run % a_ahkpath " " tmpDir "\update.ahk"
      }

      try
      {
        filedelete % lockFile
      }
      exitapp
    }
  }
}