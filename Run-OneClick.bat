@echo off
setlocal
if /i "%~1"=="ELEVATED" goto elevated
for /f "tokens=2 delims=," %%S in ('whoami /user /fo csv /nh') do set "TARGETSID=%%~S"
if not defined TARGETSID (
    echo Could not determine the current user SID.
    pause
    exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -ArgumentList 'ELEVATED','%TARGETSID%' -Verb RunAs"
exit /b
:elevated
set "TARGETSID=%~2"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair-WindowsUserProfile.ps1" -Sid "%TARGETSID%" -RepairState
set "RC=%ERRORLEVEL%"
echo.
echo Windows User Profile Repair finished with exit code %RC%.
pause
exit /b %RC%
