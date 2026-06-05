@echo off
setlocal enabledelayedexpansion

REM This script automatically creates a shortcut and pins it to the taskbar
REM Run this once, then you can delete it

echo.
echo ========================================
echo Dual Browser Launcher - Setup
echo ========================================
echo.

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "LAUNCHER_BAT=%SCRIPT_DIR%launcher.bat"

REM Check if launcher.bat exists
if not exist "!LAUNCHER_BAT!" (
    echo Error: launcher.bat not found!
    echo Please make sure this setup.bat is in the same folder as launcher.bat
    pause
    exit /b 1
)

REM Create shortcut on Desktop
set "DESKTOP=%USERPROFILE%\Desktop"
set "SHORTCUT=%DESKTOP%\Dual Browser Launcher.lnk"

echo Creating shortcut on Desktop...

REM Use PowerShell to create the shortcut (more reliable than VBS)
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
"$WshShell = New-Object -ComObject WScript.Shell; ^
$Shortcut = $WshShell.CreateShortcut('%SHORTCUT%'); ^
$Shortcut.TargetPath = '%LAUNCHER_BAT%'; ^
$Shortcut.WorkingDirectory = '%SCRIPT_DIR%'; ^
$Shortcut.Description = 'Dual Browser Launcher - Open current page in Chrome or Edge'; ^
$Shortcut.Save()"

if exist "!SHORTCUT!" (
    echo Success! Shortcut created on Desktop
    echo.
    echo Next step:
    echo 1. Go to your Desktop
    echo 2. Right-click "Dual Browser Launcher.lnk" (the shortcut)
    echo 3. Click "Pin to Taskbar"
    echo.
    echo That's it! You can then delete this setup.bat file.
    echo.
    pause
) else (
    echo Error creating shortcut
    pause
    exit /b 1
)
