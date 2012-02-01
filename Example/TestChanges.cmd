@echo off
rem **********************************************************************
rem Test script to convert the sql script to C-code and run a diff on
rem the results to show what's broken.
rem
rem NB: The diff is done using SourceSafe and is against the currently
rem checked in revision.
rem **********************************************************************

PowerShell ..\sql2doxygen.ps1 Example.sql > Output.sql
if errorlevel 1 (
    echo.
    echo ERROR: Failed to convert Example.sql
    echo.
    PowerShell ..\sql2doxygen.ps1 Example.sql
    exit /b 1
)

ss diff -DS Output.sql
if errorlevel 1 (
    echo ERROR: Differences detected
    exit /b 1
)
