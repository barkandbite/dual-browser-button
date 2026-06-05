@echo off
REM Dual Browser Launcher
REM This script opens the current webpage in the opposite browser
REM with automatic window positioning for dual-monitor or split-screen setups

setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Open-DualBrowsers.ps1"

REM Check if the PowerShell script exists
if not exist "!PS_SCRIPT!" (
    echo Error: Open-DualBrowsers.ps1 not found in the same folder
    echo Please make sure both files are in the same directory
    pause
    exit /b 1
)

REM Run the PowerShell script
PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '!PS_SCRIPT!'"

REM Exit without pausing (the PowerShell script handles its own output)
