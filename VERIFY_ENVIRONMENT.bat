@echo off
setlocal EnableExtensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0environment\VERIFY_ENVIRONMENT.ps1"
set RC=%ERRORLEVEL%
echo.
pause
exit /b %RC%
