@echo off
setlocal EnableExtensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\VERIFY_INPUTS.ps1"
set RC=%ERRORLEVEL%
echo.
pause
exit /b %RC%
