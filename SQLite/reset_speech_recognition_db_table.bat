@ECHO off

set exe=sqlite3
set errorPrefix=SQLite3 DB engine not installed / sqlite3.exe not found.
set errorPostfix=You may supply a double-quoted full path to the executable as an only command-line argument or add the containing folder to the PATH environment variable.

rem sqlite3.exe availability check
WHERE %exe% >nul 2>nul
IF %ERRORLEVEL% NEQ 0 (
  if [%1]==[] (
    rem No command-line args given
    ECHO ERROR: %errorPrefix% %errorPostfix%
    PAUSE
    EXIT /B
  )
  
  set exe=%1
  WHERE %exe% >nul 2>nul
  IF %ERRORLEVEL% NEQ 0 (
    rem Arg given but not a valid exe
    ECHO ERROR: %errorPrefix% Given command-line argument %~f1 is invalid. %errorPostfix%
    PAUSE
    EXIT /B
  )
  
)

rem Delete an old activity dump file
IF EXIST scripts\speech_recognition_activity_dump.sql (
  del scripts\speech_recognition_activity_dump.sql
)

rem Create an SQL dump of all activity files
type scripts\SpeechRecognitionActivities\*.sql > scripts\speech_recognition_activity_dump.sql 2>nul

rem Recreate the table
%exe% uipath.db < scripts\recreate_speech_recognition_activity_table.sql
IF %ERRORLEVEL% NEQ 0 (
  ECHO ERROR: Failed to run CREATE TABLE SQL script.
  PAUSE
  EXIT /B
)

rem Import the activity dump
%exe% uipath.db < scripts\speech_recognition_activity_dump.sql
IF %ERRORLEVEL% NEQ 0 (
  ECHO ERROR: Failed to import SQL files.
  PAUSE
  EXIT /B
)

ECHO Resetting SQLite activity data completed.