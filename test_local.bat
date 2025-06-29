@echo off
REM Local Test Script for V2RayZone Dash (Windows)
REM This script helps test the installation locally on Windows

setlocal enabledelayedexpansion

REM Configuration
set "TEST_DIR=test_installation"
set "PORT=5000"
set "GITHUB_URL=https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh"

echo.
echo ================================================================
echo                 V2RayZone Dash Local Tester (Windows)
echo              Test GitHub Installation Script
echo ================================================================
echo.

REM Check if curl is available
curl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] curl is not available. Please install curl or use Git Bash.
    echo You can download curl from: https://curl.se/windows/
    pause
    exit /b 1
)

echo [INFO] Creating test directory...
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"
cd "%TEST_DIR%"

echo [INFO] Downloading install.sh from GitHub...
curl -o install.sh "%GITHUB_URL%"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to download install.sh
    pause
    exit /b 1
)

echo [INFO] Downloaded install.sh successfully
echo.

echo [INFO] Checking for deprecated vnstat commands in the script...
echo [INFO] Creating backup...
copy install.sh install.sh.backup >nul

set "CHANGES_MADE=false"

findstr /C:"vnstat --create" install.sh >nul
if %errorlevel% equ 0 (
    echo [INFO] Found 'vnstat --create' in the script
    echo [INFO] This should be replaced with 'vnstat --add -i'
    set "CHANGES_MADE=true"
)

findstr /C:"vnstat -u -i" install.sh >nul
if %errorlevel% equ 0 (
    echo [INFO] Found 'vnstat -u -i' in the script (deprecated in vnstat 2.x+)
    echo [INFO] This should be replaced with 'vnstat --add -i'
    set "CHANGES_MADE=true"
)

if "%CHANGES_MADE%"=="true" (
    echo.
    echo [INFO] To update the script for vnstat 2.x+ compatibility:
    echo   1. Open install.sh in a text editor
    echo   2. Find 'vnstat --create' and replace with 'vnstat --add -i'
    echo   3. Find 'vnstat -u -i' and replace with 'vnstat --add -i'
) else (
    echo [INFO] No deprecated vnstat commands found in the script
)

echo.
echo [INFO] Script analysis:
echo ================================================================
echo.
echo [CONFIG] Key configuration found in install.sh:
findstr /B "INSTALL_DIR=" install.sh
findstr /B "SERVICE_NAME=" install.sh
findstr /B "PORT=" install.sh
findstr /B "GITHUB_REPO=" install.sh

echo.
echo [VNSTAT] vnstat commands found:
findstr /N "vnstat" install.sh

echo.
echo ================================================================
echo [INFO] Local testing completed!
echo.
echo [NEXT STEPS]
echo 1. Review the downloaded install.sh file
echo 2. Make any necessary modifications
echo 3. Test on a Linux system or WSL with:
echo    sudo bash install.sh
echo.
echo Files are available in: %cd%
echo.
pause