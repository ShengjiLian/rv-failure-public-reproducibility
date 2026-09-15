@echo off
setlocal EnableExtensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0data\DOWNLOAD_PUBLIC_INPUTS.ps1"
set RC=%ERRORLEVEL%
echo.
pause
exit /b %RC%
