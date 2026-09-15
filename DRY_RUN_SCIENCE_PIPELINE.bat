@echo off
setlocal EnableExtensions
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0runner\RUN_SCIENCE_PIPELINE.ps1" -DryRun
set RC=%ERRORLEVEL%
echo.
echo Dry-run exit code: %RC%
pause
exit /b %RC%
