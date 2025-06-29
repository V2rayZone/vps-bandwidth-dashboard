#!/bin/bash

# V2RayZone Dash - API Data Generator
# Generates JSON data from vnstat for the dashboard

set -e

# Configuration
OUTPUT_FILE="/opt/v2rayzone-dash/api/stats.json"
TEMP_FILE="/tmp/vnstat_temp.json"

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Function to get primary network interface
get_primary_interface() {
    # Try multiple methods to get the primary interface
    local interface
    
    # Method 1: Default route interface
    interface=$(ip route | grep default | awk '{print $5}' | head -n1 2>/dev/null)
    
    # Method 2: First active interface from vnstat
    if [[ -z "$interface" ]]; then
        interface=$(vnstat --iflist 2>/dev/null | grep -v "Available interfaces:" | head -n1 | awk '{print $1}' 2>/dev/null)
    fi
    
    # Method 3: Common interface names
    if [[ -z "$interface" ]]; then
        for iface in eth0 ens3 ens18 enp0s3 wlan0; do
            if [[ -d "/sys/class/net/$iface" ]]; then
                interface="$iface"
                break
            fi
        done
    fi
    
    # Fallback
    if [[ -z "$interface" ]]; then
        interface="eth0"
    fi
    
    echo "$interface"
}

# Function to get current bandwidth rates
get_current_rates() {
    local interface="$1"
    local rx_bytes tx_bytes
    
    # Read current interface statistics
    if [[ -f "/sys/class/net/$interface/statistics/rx_bytes" ]]; then
        rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo "0")
        tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo "0")
    else
        rx_bytes=0
        tx_bytes=0
    fi
    
    # Calculate rates (simplified - in real implementation you'd need previous values)
    # For now, we'll use a simple approximation or rely on vnstat live data
    local rx_rate=0
    local tx_rate=0
    
    # Try to get live data from vnstat if available
    if command -v vnstat >/dev/null 2>&1; then
        local vnstat_live
        vnstat_live=$(vnstat -i "$interface" --live --json 2>/dev/null || echo "{}")
        
        # Parse live data if available (vnstat 2.6+)
        if echo "$vnstat_live" | jq -e '.interfaces[0].traffic.live' >/dev/null 2>&1; then
            rx_rate=$(echo "$vnstat_live" | jq -r '.interfaces[0].traffic.live.rx_rate // 0' 2>/dev/null || echo "0")
            tx_rate=$(echo "$vnstat_live" | jq -r '.interfaces[0].traffic.live.tx_rate // 0' 2>/dev/null || echo "0")
        fi
    fi
    
    echo "{\"rx_rate\": $rx_rate, \"tx_rate\": $tx_rate}"
}

# Function to get vnstat data
get_vnstat_data() {
    local interface="$1"
    local vnstat_json
    
    # Get vnstat JSON data
    if command -v vnstat >/dev/null 2>&1; then
        vnstat_json=$(vnstat -i "$interface" --json 2>/dev/null || echo '{"interfaces": []}')
    else
        vnstat_json='{"interfaces": []}'
    fi
    
    echo "$vnstat_json"
}

# Function to get system information
get_system_info() {
    local interface="$1"
    local server_ip uptime vnstat_version
    
    # Get server IP
    server_ip=$(curl -s --connect-timeout 5 ifconfig.me 2>/dev/null || curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}' || echo "Unknown")
    
    # Get uptime
    uptime=$(uptime -p 2>/dev/null || uptime | awk '{print $3, $4}' | sed 's/,//' || echo "Unknown")
    
    # Get vnstat version
    vnstat_version=$(vnstat --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "Unknown")
    
    cat << EOF
{
    "interface": "$interface",
    "server_ip": "$server_ip",
    "uptime": "$uptime",
    "vnstat_version": "$vnstat_version"
}
EOF
}

# Function to parse vnstat data and extract required information
parse_vnstat_data() {
    local vnstat_json="$1"
    local interface="$2"
    
    # Check if vnstat data is available
    if ! echo "$vnstat_json" | jq -e '.interfaces[0]' >/dev/null 2>&1; then
        # Return default data if vnstat is not available
        cat << EOF
{
    "today": {"rx": 0, "tx": 0, "total": 0},
    "month": {"rx": 0, "tx": 0, "total": 0},
    "daily_history": []
}
EOF
        return
    fi
    
    # Extract today's data
    local today_rx today_tx today_total
    today_rx=$(echo "$vnstat_json" | jq -r '.interfaces[0].traffic.day[0].rx // 0' 2>/dev/null || echo "0")
    today_tx=$(echo "$vnstat_json" | jq -r '.interfaces[0].traffic.day[0].tx // 0' 2>/dev/null || echo "0")
    today_total=$((today_rx + today_tx))
    
    # Extract monthly data
    local month_rx month_tx month_total
    month_rx=$(echo "$vnstat_json" | jq -r '.interfaces[0].traffic.month[0].rx // 0' 2>/dev/null || echo "0")
    month_tx=$(echo "$vnstat_json" | jq -r '.interfaces[0].traffic.month[0].tx // 0' 2>/dev/null || echo "0")
    month_total=$((month_rx + month_tx))
    
    # Extract daily history (last 30 days)
    local daily_history
    daily_history=$(echo "$vnstat_json" | jq -r '
        .interfaces[0].traffic.day[0:30] | map({
            date: (.date.year|tostring) + "-" + (.date.month|tostring|if length == 1 then "0" + . else . end) + "-" + (.date.day|tostring|if length == 1 then "0" + . else . end),
            rx: .rx,
            tx: .tx
        })
    ' 2>/dev/null || echo '[]')
    
    cat << EOF
{
    "today": {
        "rx": $today_rx,
        "tx": $today_tx,
        "total": $today_total
    },
    "month": {
        "rx": $month_rx,
        "tx": $month_tx,
        "total": $month_total
    },
    "daily_history": $daily_history
}
EOF
}

# Main function
main() {
    # Get primary interface
    local interface
    interface=$(get_primary_interface)
    
    # Get current rates
    local current_rates
    current_rates=$(get_current_rates "$interface")
    
    # Get vnstat data
    local vnstat_data
    vnstat_data=$(get_vnstat_data "$interface")
    
    # Parse vnstat data
    local parsed_data
    parsed_data=$(parse_vnstat_data "$vnstat_data" "$interface")
    
    # Get system info
    local system_info
    system_info=$(get_system_info "$interface")
    
    # Combine all data
    local final_json
    final_json=$(jq -n \
        --argjson current "$current_rates" \
        --argjson parsed "$parsed_data" \
        --argjson system "$system_info" \
        '{
            current: $current,
            today: $parsed.today,
            month: $parsed.month,
            daily_history: $parsed.daily_history,
            interface: $system.interface,
            server_ip: $system.server_ip,
            uptime: $system.uptime,
            vnstat_version: $system.vnstat_version,
            timestamp: now
        }')
    
    # Write to temporary file first, then move to final location
    echo "$final_json" > "$TEMP_FILE"
    mv "$TEMP_FILE" "$OUTPUT_FILE"
    
    # Set appropriate permissions
    chmod 644 "$OUTPUT_FILE"
    
    # Optional: Log success (comment out for production)
    # echo "$(date): Generated stats.json successfully" >> /var/log/v2rayzone-dash.log
}

# Error handling
trap 'echo "Error occurred in generate_json.sh at line $LINENO" >&2; exit 1' ERR

# Run main function
main "$@"