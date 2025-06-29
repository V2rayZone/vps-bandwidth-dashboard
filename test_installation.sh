#!/bin/bash

# V2RayZone Dash - Installation Test Script
# This script tests the installation and verifies all components are working

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
STATS_FILE="$INSTALL_DIR/api/stats.json"
GENERATE_SCRIPT="$INSTALL_DIR/api/generate_json.sh"

# Test results
TEST_PASSED=0
TEST_FAILED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TEST_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TEST_FAILED++))
}

# Test functions
test_system_requirements() {
    log_info "Testing system requirements..."
    
    # Check Ubuntu version
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            case "$VERSION_ID" in
                "18.04"|"20.04"|"22.04"|"24.04")
                    log_success "Ubuntu $VERSION_ID detected (supported)"
                    ;;
                *)
                    log_warning "Ubuntu $VERSION_ID detected (may not be fully tested)"
                    ;;
            esac
        else
            log_error "Non-Ubuntu system detected: $ID"
        fi
    else
        log_error "Cannot detect operating system"
    fi
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_success "Running as root"
    else
        log_warning "Not running as root (some tests may fail)"
    fi
}

test_dependencies() {
    log_info "Testing dependencies..."
    
    local deps=("vnstat" "curl" "jq" "python3" "systemctl")
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            log_success "$dep is installed"
        else
            log_error "$dep is not installed"
        fi
    done
    
    # Test vnstat specifically
    if command -v vnstat >/dev/null 2>&1; then
        if systemctl is-active --quiet vnstat; then
            log_success "vnstat service is running"
        else
            log_error "vnstat service is not running"
        fi
        
        # Check if vnstat has data
        if vnstat >/dev/null 2>&1; then
            log_success "vnstat has network data"
        else
            log_warning "vnstat has no network data yet (may need time to collect)"
        fi
    fi
}

test_installation_files() {
    log_info "Testing installation files..."
    
    local files=(
        "$INSTALL_DIR/index.html"
        "$INSTALL_DIR/style.css"
        "$INSTALL_DIR/script.js"
        "$INSTALL_DIR/server.py"
        "$GENERATE_SCRIPT"
    )
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "File exists: $file"
        else
            log_error "File missing: $file"
        fi
    done
    
    # Check file permissions
    if [[ -x "$GENERATE_SCRIPT" ]]; then
        log_success "Generate script is executable"
    else
        log_error "Generate script is not executable"
    fi
    
    if [[ -x "$INSTALL_DIR/server.py" ]]; then
        log_success "Server script is executable"
    else
        log_warning "Server script is not executable (may still work)"
    fi
}

test_systemd_service() {
    log_info "Testing systemd service..."
    
    local service_file="/etc/systemd/system/$SERVICE_NAME.service"
    
    if [[ -f "$service_file" ]]; then
        log_success "Service file exists: $service_file"
    else
        log_error "Service file missing: $service_file"
        return
    fi
    
    # Check if service is enabled
    if systemctl is-enabled --quiet "$SERVICE_NAME"; then
        log_success "Service is enabled for auto-start"
    else
        log_warning "Service is not enabled for auto-start"
    fi
    
    # Check if service is running
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_success "Service is currently running"
    else
        log_error "Service is not running"
        
        # Show recent logs
        log_info "Recent service logs:"
        journalctl -u "$SERVICE_NAME" -n 5 --no-pager
    fi
}

test_network_connectivity() {
    log_info "Testing network connectivity..."
    
    # Check if port is listening
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        log_success "Port $PORT is listening"
    else
        log_error "Port $PORT is not listening"
    fi
    
    # Test HTTP connectivity
    if curl -s --connect-timeout 5 "http://localhost:$PORT" >/dev/null; then
        log_success "HTTP server is responding on port $PORT"
    else
        log_error "HTTP server is not responding on port $PORT"
    fi
    
    # Test API endpoint
    if curl -s --connect-timeout 5 "http://localhost:$PORT/api/health" >/dev/null; then
        log_success "API health endpoint is responding"
    else
        log_error "API health endpoint is not responding"
    fi
}

test_data_generation() {
    log_info "Testing data generation..."
    
    # Test manual script execution
    if bash "$GENERATE_SCRIPT" 2>/dev/null; then
        log_success "Data generation script runs successfully"
    else
        log_error "Data generation script failed"
        return
    fi
    
    # Check if stats file was created
    if [[ -f "$STATS_FILE" ]]; then
        log_success "Stats file was created: $STATS_FILE"
        
        # Validate JSON format
        if jq . "$STATS_FILE" >/dev/null 2>&1; then
            log_success "Stats file contains valid JSON"
        else
            log_error "Stats file contains invalid JSON"
        fi
        
        # Check file age
        local file_age=$(($(date +%s) - $(stat -c %Y "$STATS_FILE" 2>/dev/null || echo 0)))
        if [[ $file_age -lt 300 ]]; then  # Less than 5 minutes old
            log_success "Stats file is recent (${file_age}s old)"
        else
            log_warning "Stats file is old (${file_age}s old)"
        fi
    else
        log_error "Stats file was not created"
    fi
}

test_firewall() {
    log_info "Testing firewall configuration..."
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            if ufw status | grep -q "$PORT"; then
                log_success "UFW firewall allows port $PORT"
            else
                log_warning "UFW firewall may be blocking port $PORT"
            fi
        else
            log_info "UFW firewall is not active"
        fi
    else
        log_info "UFW firewall is not installed"
    fi
}

test_cron_job() {
    log_info "Testing cron job..."
    
    if crontab -l 2>/dev/null | grep -q "v2rayzone-dash"; then
        log_success "Cron job is configured"
    else
        log_warning "Cron job is not configured"
    fi
}

test_dashboard_content() {
    log_info "Testing dashboard content..."
    
    # Test if we can fetch the main page
    local response
    response=$(curl -s --connect-timeout 5 "http://localhost:$PORT" 2>/dev/null || echo "")
    
    if [[ -n "$response" ]]; then
        if echo "$response" | grep -q "V2RayZone Dash"; then
            log_success "Dashboard HTML contains expected title"
        else
            log_warning "Dashboard HTML may be corrupted"
        fi
        
        if echo "$response" | grep -q "Chart.js"; then
            log_success "Dashboard includes Chart.js dependency"
        else
            log_warning "Dashboard may be missing Chart.js"
        fi
    else
        log_error "Could not fetch dashboard content"
    fi
}

test_api_endpoints() {
    log_info "Testing API endpoints..."
    
    local endpoints=("/api/health" "/api/stats")
    
    for endpoint in "${endpoints[@]}"; do
        local response
        response=$(curl -s --connect-timeout 5 "http://localhost:$PORT$endpoint" 2>/dev/null || echo "")
        
        if [[ -n "$response" ]]; then
            if echo "$response" | jq . >/dev/null 2>&1; then
                log_success "API endpoint $endpoint returns valid JSON"
            else
                log_error "API endpoint $endpoint returns invalid JSON"
            fi
        else
            log_error "API endpoint $endpoint is not responding"
        fi
    done
}

show_summary() {
    echo
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║                        TEST SUMMARY                         ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${GREEN}Tests Passed: $TEST_PASSED${NC}"
    echo -e "${RED}Tests Failed: $TEST_FAILED${NC}"
    echo
    
    if [[ $TEST_FAILED -eq 0 ]]; then
        echo -e "${GREEN}🎉 All tests passed! V2RayZone Dash appears to be working correctly.${NC}"
        echo
        echo -e "${BLUE}Dashboard URL:${NC} http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):$PORT"
    else
        echo -e "${RED}⚠️  Some tests failed. Please check the errors above and refer to INSTALL.md for troubleshooting.${NC}"
    fi
    echo
}

# Main function
main() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                V2RayZone Dash Test Suite                    ║"
    echo "║              Installation Verification Tool                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
    
    test_system_requirements
    echo
    test_dependencies
    echo
    test_installation_files
    echo
    test_systemd_service
    echo
    test_network_connectivity
    echo
    test_data_generation
    echo
    test_firewall
    echo
    test_cron_job
    echo
    test_dashboard_content
    echo
    test_api_endpoints
    echo
    
    show_summary
}

# Run main function
main "$@"