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
    
    # Check for vnstat --create
    Write-Info "Checking for 'vnstat --create' in the script..."
    if ($content -match "vnstat --create") {
        Write-Info "Found 'vnstat --create' in the script"
        
        # Create backup
        Copy-Item "install.sh" "install.sh.backup"
        Write-Info "Created backup: install.sh.backup"
        
        # Replace vnstat --create with vnstat -u -i eth0
        $modifiedContent = $content -replace "vnstat --create", "vnstat -u -i eth0"
        Set-Content "install.sh" $modifiedContent
        
        Write-Info "Replaced 'vnstat --create' with 'vnstat -u -i eth0'"
        
        # Show differences
        Write-Info "Changes made:"
        Write-ColorOutput "  - vnstat --create" "Red"
        Write-ColorOutput "  + vnstat -u -i eth0" "Green"
    }
    else {
        Write-Info "No 'vnstat --create' found in the script"
        Write-Info "The script already uses the correct vnstat commands"
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