@echo off
REM ============================================================
REM  Add a campus prefix to policy files
REM
REM  Double-click this file to run it. It launches the PowerShell
REM  script next to it and keeps this window open at the end.
REM
REM  Keep this file and Prefix-CampusFiles.ps1 together, in the
REM  folder that holds the policy files.
REM ============================================================

if not exist "%~dp0Prefix-CampusFiles.ps1" (
    echo Cannot find Prefix-CampusFiles.ps1 next to this file.
    echo Keep both files together in the folder with your documents.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Prefix-CampusFiles.ps1"

echo.
pause
