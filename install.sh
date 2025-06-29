#!/bin/bash

# V2RayZone Dash - VPS Bandwidth Dashboard Installer
# Supports Ubuntu 18.04, 20.04, 22.04

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/v2rayzone-dash"
SERVICE_NAME="v2rayzone-dash"
PORT=2053
GITHUB_REPO="https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main"

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root. Use: sudo $0"
    fi
}

# Detect Ubuntu version
detect_ubuntu() {
    if [[ ! -f /etc/os-release ]]; then
        error "Cannot detect OS version. This script supports Ubuntu only."
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        error "This script supports Ubuntu only. Detected: $ID"
    fi
    
    case "$VERSION_ID" in
        "18.04"|"20.04"|"22.04")
            log "Detected Ubuntu $VERSION_ID - Supported ✓"
            ;;
        *)
            warn "Ubuntu $VERSION_ID may not be fully tested. Continuing anyway..."
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    log "Updating package list..."
    apt update -qq
    
    log "Installing dependencies..."
    apt install -y vnstat curl jq net-tools python3 python3-pip
    
    # Enable and start vnstat
    systemctl enable vnstat
    systemctl start vnstat
    
    # Wait for vnstat to initialize
    log "Initializing vnstat (this may take a moment)..."
    sleep 5
    
    # Force vnstat to create database for primary interface
    PRIMARY_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -n1)
    if [[ -n "$PRIMARY_INTERFACE" ]]; then
        vnstat -u -i "$PRIMARY_INTERFACE"
        log "Initialized vnstat for interface: $PRIMARY_INTERFACE"
    fi
}

# Create installation directory
setup_directory() {
    log "Creating installation directory..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
}

# Download dashboard files
download_dashboard() {
    log "Downloading dashboard files..."
    
    # Download HTML file
    curl -s "$GITHUB_REPO/dashboard/index.html" -o index.html
    
    # Download CSS file
    curl -s "$GITHUB_REPO/dashboard/style.css" -o style.css
    
    # Download JavaScript file
    curl -s "$GITHUB_REPO/dashboard/script.js" -o script.js
    
    # Download API script
    mkdir -p api
    curl -s "$GITHUB_REPO/api/generate_json.sh" -o api/generate_json.sh
    chmod +x api/generate_json.sh
    
    # Download Python server
    curl -s "$GITHUB_REPO/server.py" -o server.py
    
    log "Dashboard files downloaded successfully"
}

# Setup firewall
setup_firewall() {
    log "Configuring firewall..."
    
    # Check if ufw is installed and active
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            log "Opening port $PORT in UFW..."
            ufw allow $PORT/tcp
        else
            log "UFW is installed but not active. Skipping firewall configuration."
        fi
    else
        log "UFW not found. Please manually open port $PORT if needed."
    fi
}

# Create systemd service
create_service() {
    log "Creating systemd service..."
    
    cat > "/etc/systemd/system/$SERVICE_NAME.service" << EOF
[Unit]
Description=V2RayZone Dash - VPS Bandwidth Dashboard
After=network.target vnstat.service
Requires=vnstat.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStartPre=/bin/bash $INSTALL_DIR/api/generate_json.sh
ExecStart=/usr/bin/python3 $INSTALL_DIR/server.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
}

# Setup cron job for data updates
setup_cron() {
    log "Setting up cron job for data updates..."
    
    # Add cron job to update stats every minute
    (crontab -l 2>/dev/null; echo "* * * * * /bin/bash $INSTALL_DIR/api/generate_json.sh >/dev/null 2>&1") | crontab -
}

# Get server IP
get_server_ip() {
    # Try multiple methods to get public IP
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || curl -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
    
    if [[ -z "$SERVER_IP" ]]; then
        SERVER_IP="YOUR_SERVER_IP"
    fi
}

# Start service
start_service() {
    log "Starting V2RayZone Dash service..."
    
    # Generate initial data
    bash "$INSTALL_DIR/api/generate_json.sh"
    
    # Start the service
    systemctl start "$SERVICE_NAME"
    
    # Wait a moment for service to start
    sleep 3
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log "Service started successfully ✓"
    else
        error "Failed to start service. Check logs with: journalctl -u $SERVICE_NAME"
    fi
}

# Display completion message
show_completion() {
    get_server_ip
    
    echo
    echo -e "${GREEN}🎉 Installation completed successfully!${NC}"
    echo
    echo -e "${BLUE}📊 Dashboard URL:${NC} http://$SERVER_IP:$PORT"
    echo
    echo -e "${YELLOW}📋 Management Commands:${NC}"
    echo "  Start:   sudo systemctl start $SERVICE_NAME"
    echo "  Stop:    sudo systemctl stop $SERVICE_NAME"
    echo "  Status:  sudo systemctl status $SERVICE_NAME"
    echo "  Logs:    journalctl -u $SERVICE_NAME -f"
    echo
    echo -e "${YELLOW}⚠️  Security Notice:${NC}"
    echo "  This dashboard has no authentication by default."
    echo "  Consider setting up a reverse proxy with SSL for production use."
    echo
}

# Main installation function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    V2RayZone Dash Installer                 ║"
    echo "║              VPS Bandwidth Dashboard Setup                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    
    check_root
    detect_ubuntu
    install_dependencies
    setup_directory
    download_dashboard
    setup_firewall
    create_service
    setup_cron
    start_service
    show_completion
}

# Run main function
main "$@"