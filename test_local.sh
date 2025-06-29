#!/bin/bash

# Local Test Script for V2RayZone Dash
# This script helps test the installation locally

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TEST_DIR="./test_installation"
PORT=5000

# Logging function
log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running on Windows with WSL or Git Bash
check_environment() {
    log "Checking environment..."
    
    if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        log "Detected Windows environment (Git Bash/MSYS)"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        log "Detected WSL environment"
    else
        warn "Environment may not be Windows. Continuing anyway..."
    fi
}

# Create test directory
setup_test_directory() {
    log "Setting up test directory..."
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
}

# Download the GitHub script
download_github_script() {
    log "Downloading install.sh from GitHub..."
    
    if command -v curl >/dev/null 2>&1; then
        curl -O "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh"
    elif command -v wget >/dev/null 2>&1; then
        wget "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
    
    if [[ ! -f "install.sh" ]]; then
        error "Failed to download install.sh"
    fi
    
    log "Downloaded install.sh successfully"
}

# Modify the script as requested
modify_script() {
    log "Checking for deprecated vnstat commands in the script..."
    
    # Create backup first
    cp install.sh install.sh.backup
    
    local changes_made=false
    
    # Check for vnstat --create and replace
    if grep -q "vnstat --create" install.sh; then
        log "Found 'vnstat --create' - replacing with 'vnstat --add -i'"
        sed -i 's/vnstat --create/vnstat --add -i/g' install.sh
        changes_made=true
    fi
    
    # Check for vnstat -u and replace (deprecated in vnstat 2.x+)
    if grep -q "vnstat -u" install.sh; then
        log "Found 'vnstat -u' - replacing with 'vnstat --add'"
        sed -i 's/vnstat -u -i/vnstat --add -i/g' install.sh
        changes_made=true
    fi
    
    if [ "$changes_made" = true ]; then
        log "Vnstat commands updated for compatibility with vnstat 2.x+"
    else
        log "No deprecated vnstat commands found in the script"
    fi
}

# Show differences
show_differences() {
    if [[ -f "install.sh.backup" ]]; then
        log "Showing differences between original and modified script:"
        echo -e "${BLUE}--- Original${NC}"
        echo -e "${GREEN}+++ Modified${NC}"
        diff install.sh.backup install.sh || true
    else
        log "No modifications were needed"
    fi
}

# Simulate installation (dry run)
simulate_installation() {
    log "Simulating installation (dry run)..."
    
    echo -e "${YELLOW}This would normally run:${NC}"
    echo "  sudo bash install.sh"
    echo
    echo -e "${YELLOW}But since we're testing locally, here's what the script contains:${NC}"
    echo
    
    # Show key parts of the script
    echo -e "${BLUE}=== Key Configuration ===${NC}"
    grep -E "^(INSTALL_DIR|SERVICE_NAME|PORT|GITHUB_REPO)=" install.sh || true
    echo
    
    echo -e "${BLUE}=== vnstat Commands ===${NC}"
    grep -n "vnstat" install.sh || true
    echo
    
    echo -e "${BLUE}=== Dependencies ===${NC}"
    grep -A 5 "install_dependencies()" install.sh || true
}

# Test local server
test_local_server() {
    log "Testing if we can run the Python server locally..."
    
    # Check if Python is available
    if command -v python3 >/dev/null 2>&1; then
        log "Python3 found: $(python3 --version)"
    elif command -v python >/dev/null 2>&1; then
        log "Python found: $(python --version)"
    else
        warn "Python not found. You'll need Python to run the server."
        return
    fi
    
    # Download server files for testing
    log "Downloading server files for local testing..."
    
    mkdir -p dashboard api
    
    # Download main files
    curl -s "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/server_local.py" -o server_local.py 2>/dev/null || warn "Could not download server_local.py"
    curl -s "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/index.html" -o dashboard/index.html 2>/dev/null || warn "Could not download index.html"
    curl -s "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/style.css" -o dashboard/style.css 2>/dev/null || warn "Could not download style.css"
    curl -s "https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/dashboard/script.js" -o dashboard/script.js 2>/dev/null || warn "Could not download script.js"
    
    if [[ -f "server_local.py" ]]; then
        log "You can now test the server locally by running:"
        echo -e "${GREEN}  cd $(pwd)${NC}"
        echo -e "${GREEN}  python3 server_local.py${NC}"
        echo -e "${GREEN}  # Then open http://localhost:$PORT in your browser${NC}"
    fi
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                 V2RayZone Dash Local Tester                ║"
    echo "║              Test GitHub Installation Script                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    
    check_environment
    setup_test_directory
    download_github_script
    modify_script
    show_differences
    simulate_installation
    test_local_server
    
    echo
    log "Local testing completed!"
    echo -e "${YELLOW}Files are available in: $(pwd)${NC}"
}

# Run main function
main "$@"