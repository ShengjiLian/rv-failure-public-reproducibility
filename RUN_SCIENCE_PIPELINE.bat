@echo off
setlocal EnableExtensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0runner\RUN_SCIENCE_PIPELINE.ps1" -Execute
set RC=%ERRORLEVEL%
echo.
echo Science pipeline exit code: %RC%
pause
exit /b %RC%
