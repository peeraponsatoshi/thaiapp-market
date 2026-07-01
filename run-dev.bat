@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run-dev.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] PowerShell script failed. Error code: %ERRORLEVEL%
    echo.
)
pause
