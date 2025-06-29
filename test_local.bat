@echo off
REM Local Test Script for V2RayZone Dash (Windows)
REM This script helps test the installation locally on Windows

setlocal enabledelayedexpansion

REM Configuration
set "TEST_DIR=test_installation"
set "PORT=2053"
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

echo [INFO] Checking for 'vnstat --create' in the script...
findstr /C:"vnstat --create" install.sh >nul
if %errorlevel% equ 0 (
    echo [INFO] Found 'vnstat --create' in the script
    echo [INFO] You should replace it with 'vnstat -u -i eth0' as mentioned
    echo.
    echo [INFO] Creating backup...
    copy install.sh install.sh.backup >nul
    
    echo [INFO] To modify the script, you can:
    echo   1. Open install.sh in a text editor
    echo   2. Find 'vnstat --create'
    echo   3. Replace with 'vnstat -u -i eth0'
) else (
    echo [INFO] No 'vnstat --create' found in the script
    echo [INFO] The script already uses the correct vnstat commands
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