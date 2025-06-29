# V2RayZone Dash - Local Testing Guide

This guide helps you test the GitHub installation script locally before deploying it to a production server.

## 📋 Overview

The V2RayZone Dash installation script from GitHub can be tested locally using the provided testing scripts. This is useful for:

- Verifying script modifications
- Understanding the installation process
- Testing before production deployment
- Learning about the dashboard components

## 🔍 Current Script Analysis

After examining your current `install.sh` file, here's what we found:

⚠️ **Important Update**: The script has been updated for vnstat 2.x+ compatibility!
- Now uses: `vnstat --add -i "$PRIMARY_INTERFACE"`
- Previously used: `vnstat -u -i "$PRIMARY_INTERFACE"` (deprecated in vnstat 2.x+)
- Avoids: `vnstat --create` (older syntax)

The script has been updated to work with modern vnstat versions (2.x+).

## 🛠️ Testing Options

We've created three different testing scripts for different environments:

### 1. Bash Script (`test_local.sh`) - Recommended for Git Bash/WSL

```bash
# Make executable and run
chmod +x test_local.sh
./test_local.sh
```

**Features:**
- Downloads the latest script from GitHub
- Checks for `vnstat --create` and replaces if found
- Shows script analysis
- Downloads dashboard files for local testing
- Works with Git Bash, WSL, or Linux

### 2. Batch Script (`test_local.bat`) - For Windows Command Prompt

```cmd
# Double-click or run from Command Prompt
test_local.bat
```

**Features:**
- Simple Windows batch file
- Downloads and analyzes the script
- Shows key configuration and vnstat commands
- Requires curl to be installed

### 3. PowerShell Script (`test_local.ps1`) - Advanced Windows Testing

```powershell
# Run from PowerShell
.\test_local.ps1
```

**Features:**
- Most comprehensive testing
- Color-coded output
- Downloads all dashboard components
- Detailed script analysis
- Error handling and backup creation

## 📁 What Gets Downloaded

All testing scripts will download:

1. **install.sh** - Main installation script
2. **server_local.py** - Local development server
3. **dashboard/index.html** - Dashboard HTML
4. **dashboard/style.css** - Dashboard styles
5. **dashboard/script.js** - Dashboard JavaScript

## 🔧 vnstat Version Compatibility

Different versions of vnstat use different commands for creating interface databases:

### vnstat 1.x (Older versions)
```bash
vnstat --create -i eth0
# or
vnstat -u -i eth0
```

### vnstat 2.x+ (Current versions)
```bash
vnstat --add -i eth0
```

### How to Check Your vnstat Version
```bash
vnstat --version
```

### Error: "The -u parameter is not supported"
If you see this error, you're running vnstat 2.x+ and need to use `--add` instead of `-u`.

Our testing scripts automatically detect and fix these compatibility issues.

## 🧪 Testing Process

### Step 1: Choose Your Testing Method

Pick the script that matches your environment:
- **Windows + Git Bash/WSL**: Use `test_local.sh`
- **Windows Command Prompt**: Use `test_local.bat`
- **Windows PowerShell**: Use `test_local.ps1` (recommended)

### Step 2: Run the Testing Script

The script will:
1. Create a `test_installation` directory
2. Download the latest `install.sh` from GitHub
3. Analyze the script for vnstat commands
4. Show you what the script does
5. Download dashboard files for local testing

### Step 3: Review the Results

After running, you'll see:
- Script configuration (ports, directories, etc.)
- All vnstat commands used
- Dependencies that will be installed
- Files downloaded for testing

## 🚀 Actual Installation Testing

To test the actual installation, you have several options:

### Option 1: WSL (Windows Subsystem for Linux)

```bash
# Install WSL if not already installed
wsl --install

# Enter WSL
wsl

# Copy the script to WSL
cp /mnt/c/Users/YourUsername/Desktop/"New folder (2)"/test_installation/install.sh .

# Run the installation (requires sudo)
sudo bash install.sh
```

### Option 2: Linux Virtual Machine

1. Set up a Linux VM (Ubuntu 18.04, 20.04, or 22.04)
2. Copy `install.sh` to the VM
3. Run: `sudo bash install.sh`

### Option 3: Remote Linux Server

```bash
# Copy script to server
scp install.sh user@your-server:/tmp/

# SSH to server and run
ssh user@your-server
sudo bash /tmp/install.sh
```

## 🔧 Manual Modifications

If you need to modify the script:

1. **Edit the downloaded script**:
   ```bash
   nano test_installation/install.sh
   ```

2. **Common modifications**:
   - Change port: Modify `PORT=2053`
   - Change install directory: Modify `INSTALL_DIR="/opt/v2rayzone-dash"`
   - Add custom vnstat commands

3. **Test your changes**:
   - Re-run the testing script
   - Check the analysis output

## 📊 Local Dashboard Testing

If Python is installed, you can test the dashboard locally:

```bash
# Navigate to test directory
cd test_installation

# Run local server (if downloaded)
python3 server_local.py
# or
python server_local.py

# Open browser to:
# http://localhost:2053
```

## ⚠️ Important Notes

1. **vnstat Dependency**: The dashboard requires vnstat, which is Linux-only
2. **Root Privileges**: The installation script requires sudo/root access
3. **Network Interfaces**: Script auto-detects primary network interface
4. **Firewall**: Script configures UFW if available

## 🐛 Troubleshooting

### Script Download Fails
- Check internet connection
- Verify curl/wget is installed
- Try different testing script

### Permission Denied
```bash
# Make script executable
chmod +x test_local.sh
```

### PowerShell Execution Policy
```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### WSL Issues
```bash
# Update WSL
wsl --update

# Install Ubuntu if needed
wsl --install -d Ubuntu
```

## 📝 Script Analysis Results

Based on the current script analysis:

- **Install Directory**: `/opt/v2rayzone-dash`
- **Service Name**: `v2rayzone-dash`
- **Default Port**: `2053`
- **Dependencies**: `vnstat curl jq net-tools python3 python3-pip`
- **vnstat Commands**: Updated to use modern format (`vnstat --add -i interface`)
- **Compatibility**: Works with vnstat 2.x+ (current versions)

## 🎯 Next Steps

1. Run one of the testing scripts
2. Review the downloaded `install.sh`
3. Test on a Linux system if needed
4. Deploy to production server

## 📞 Support

If you encounter issues:
1. Check the script output for error messages
2. Verify all dependencies are available
3. Test on a clean Linux system
4. Review the GitHub repository for updates

---

**Happy Testing! 🚀**