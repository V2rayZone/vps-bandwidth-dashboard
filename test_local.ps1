# V2RayZone Dash Local Tester (PowerShell)
# This script helps test the GitHub installation script locally on Windows

param(
    [string]$TestDir = "test_installation",
    [int]$Port = 2053
)

# Configuration
$GitHubUrl = "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh"
$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARN] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# Header
Write-ColorOutput "`n================================================================" "Blue"
Write-ColorOutput "                V2RayZone Dash Local Tester (PowerShell)" "Blue"
Write-ColorOutput "             Test GitHub Installation Script" "Blue"
Write-ColorOutput "================================================================`n" "Blue"

try {
    # Check PowerShell version
    Write-Info "PowerShell Version: $($PSVersionTable.PSVersion)"
    
    # Check if running on Windows
    if ($IsLinux -or $IsMacOS) {
        Write-Warning "Detected non-Windows system. This script is optimized for Windows."
    }
    
    # Create test directory
    Write-Info "Creating test directory: $TestDir"
    if (!(Test-Path $TestDir)) {
        New-Item -ItemType Directory -Path $TestDir | Out-Null
    }
    Set-Location $TestDir
    
    # Download install.sh
    Write-Info "Downloading install.sh from GitHub..."
    try {
        Invoke-WebRequest -Uri $GitHubUrl -OutFile "install.sh" -UseBasicParsing
        Write-Info "Downloaded install.sh successfully"
    }
    catch {
        Write-Error "Failed to download install.sh: $($_.Exception.Message)"
        exit 1
    }
    
    # Check file content
    if (!(Test-Path "install.sh")) {
        Write-Error "install.sh file not found after download"
        exit 1
    }
    
    $content = Get-Content "install.sh" -Raw
    
    # Check for deprecated vnstat commands
    Write-Info "Checking for deprecated vnstat commands in the script..."
    
    # Create backup first
    Copy-Item "install.sh" "install.sh.backup"
    Write-Info "Created backup: install.sh.backup"
    
    $changesMade = $false
    $modifiedContent = $content
    
    # Check for vnstat --create
    if ($content -match "vnstat --create") {
        Write-Info "Found 'vnstat --create' in the script"
        $modifiedContent = $modifiedContent -replace "vnstat --create", "vnstat --add -i"
        Write-ColorOutput "  - vnstat --create" "Red"
        Write-ColorOutput "  + vnstat --add -i" "Green"
        $changesMade = $true
    }
    
    # Check for vnstat -u (deprecated in vnstat 2.x+)
    if ($content -match "vnstat -u -i") {
        Write-Info "Found 'vnstat -u -i' in the script (deprecated in vnstat 2.x+)"
        $modifiedContent = $modifiedContent -replace "vnstat -u -i", "vnstat --add -i"
        Write-ColorOutput "  - vnstat -u -i" "Red"
        Write-ColorOutput "  + vnstat --add -i" "Green"
        $changesMade = $true
    }
    
    # Save changes if any were made
    if ($changesMade) {
        Set-Content "install.sh" $modifiedContent
        Write-Info "Updated vnstat commands for compatibility with vnstat 2.x+"
    }
    else {
        Write-Info "No deprecated vnstat commands found in the script"
    }
    
    Write-ColorOutput "`n================================================================" "Cyan"
    Write-ColorOutput "                    SCRIPT ANALYSIS" "Cyan"
    Write-ColorOutput "================================================================" "Cyan"
    
    # Extract key configuration
    Write-Info "Key Configuration:"
    $configLines = $content -split "`n" | Where-Object { $_ -match "^(INSTALL_DIR|SERVICE_NAME|PORT|GITHUB_REPO)=" }
    foreach ($line in $configLines) {
        Write-ColorOutput "  $line" "Yellow"
    }
    
    Write-Info "`nvnstat Commands Found:"
    $vnstatLines = $content -split "`n" | Select-String "vnstat" | ForEach-Object { "Line $($_.LineNumber): $($_.Line.Trim())" }
    foreach ($line in $vnstatLines) {
        Write-ColorOutput "  $line" "Cyan"
    }
    
    # Check dependencies
    Write-Info "`nDependencies mentioned in script:"
    $depLine = $content -split "`n" | Where-Object { $_ -match "apt install.*vnstat" }
    if ($depLine) {
        $deps = ($depLine -split "apt install -y ")[1]
        Write-ColorOutput "  $deps" "Yellow"
    }
    
    Write-ColorOutput "`n================================================================" "Cyan"
    Write-ColorOutput "                    TESTING OPTIONS" "Cyan"
    Write-ColorOutput "================================================================" "Cyan"
    
    # Download additional files for local testing
    Write-Info "Downloading additional files for local testing..."
    
    $files = @{
        "server_local.py" = "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/server_local.py"
        "dashboard/index.html" = "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/index.html"
        "dashboard/style.css" = "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/style.css"
        "dashboard/script.js" = "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/script.js"
    }
    
    foreach ($file in $files.GetEnumerator()) {
        $dir = Split-Path $file.Key -Parent
        if ($dir -and !(Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        try {
            Invoke-WebRequest -Uri $file.Value -OutFile $file.Key -UseBasicParsing
            Write-ColorOutput "  ✓ Downloaded $($file.Key)" "Green"
        }
        catch {
            Write-ColorOutput "  ✗ Failed to download $($file.Key)" "Red"
        }
    }
    
    Write-ColorOutput "`n================================================================" "Green"
    Write-ColorOutput "                    NEXT STEPS" "Green"
    Write-ColorOutput "================================================================" "Green"
    
    Write-Info "Local testing completed successfully!"
    Write-ColorOutput "`nFiles available in: $(Get-Location)" "Yellow"
    
    Write-ColorOutput "`nTo test the installation script:" "Cyan"
    Write-ColorOutput "  1. Use WSL (Windows Subsystem for Linux):" "White"
    Write-ColorOutput "     wsl" "Yellow"
    Write-ColorOutput "     sudo bash install.sh" "Yellow"
    
    Write-ColorOutput "`n  2. Use a Linux VM or server:" "White"
    Write-ColorOutput "     scp install.sh user@server:/tmp/" "Yellow"
    Write-ColorOutput "     ssh user@server" "Yellow"
    Write-ColorOutput "     sudo bash /tmp/install.sh" "Yellow"
    
    if (Test-Path "server_local.py") {
        Write-ColorOutput "`n  3. Test locally (if Python is installed):" "White"
        Write-ColorOutput "     python server_local.py" "Yellow"
        Write-ColorOutput "     # Then open http://localhost:$Port" "Yellow"
    }
    
    Write-ColorOutput "`nModifications made:" "Cyan"
    if (Test-Path "install.sh.backup") {
        Write-ColorOutput "  ✓ Replaced 'vnstat --create' with 'vnstat -u -i eth0'" "Green"
        Write-ColorOutput "  ✓ Original script backed up as install.sh.backup" "Green"
    } else {
        Write-ColorOutput "  ✓ No modifications needed - script already correct" "Green"
    }
    
}
catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
    exit 1
}

Write-ColorOutput "`nPress any key to continue..." "Gray"
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")