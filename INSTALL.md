# V2RayZone Dash - Installation Guide

## Quick Installation

### One-Line Installer (Recommended)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh)
```

### Manual Installation

If you prefer to install manually or the one-line installer doesn't work:

1. **Download the project:**
   ```bash
   git clone https://github.com/V2rayZone/vps-bandwidth-dashboard.git
   cd vps-bandwidth-dashboard
   ```

2. **Make the installer executable:**
   ```bash
   chmod +x install.sh
   ```

3. **Run the installer:**
   ```bash
   sudo ./install.sh
   ```

## System Requirements

### Supported Operating Systems
- Ubuntu 18.04 LTS
- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS (should work)

### Hardware Requirements
- **RAM:** Minimum 512MB, Recommended 1GB+
- **Storage:** 100MB free space
- **Network:** Active internet connection

### Required Permissions
- Root access or sudo privileges
- Ability to install packages via apt
- Permission to create systemd services

## What Gets Installed

### System Packages
- `vnstat` - Network statistics utility
- `curl` - HTTP client for API calls
- `jq` - JSON processor
- `net-tools` - Network utilities
- `python3` - Python runtime
- `python3-pip` - Python package manager

### Files and Directories
- `/opt/v2rayzone-dash/` - Main installation directory
- `/opt/v2rayzone-dash/index.html` - Dashboard HTML
- `/opt/v2rayzone-dash/style.css` - Dashboard styles
- `/opt/v2rayzone-dash/script.js` - Dashboard JavaScript
- `/opt/v2rayzone-dash/server.py` - Python web server
- `/opt/v2rayzone-dash/api/` - API directory
- `/opt/v2rayzone-dash/api/generate_json.sh` - Data generation script
- `/opt/v2rayzone-dash/api/stats.json` - Generated statistics (auto-created)
- `/etc/systemd/system/v2rayzone-dash.service` - Systemd service file

### Network Configuration
- Port 2053 opened in UFW firewall (if UFW is active)
- Systemd service configured to start on boot

## Post-Installation

### Accessing the Dashboard

After installation, you can access your dashboard at:
```
http://YOUR_SERVER_IP:2053
```

Replace `YOUR_SERVER_IP` with your actual server IP address.

### Service Management

**Check service status:**
```bash
sudo systemctl status v2rayzone-dash
```

**Start the service:**
```bash
sudo systemctl start v2rayzone-dash
```

**Stop the service:**
```bash
sudo systemctl stop v2rayzone-dash
```

**Restart the service:**
```bash
sudo systemctl restart v2rayzone-dash
```

**Enable auto-start on boot:**
```bash
sudo systemctl enable v2rayzone-dash
```

**Disable auto-start on boot:**
```bash
sudo systemctl disable v2rayzone-dash
```

### Viewing Logs

**Real-time logs:**
```bash
journalctl -u v2rayzone-dash -f
```

**Recent logs:**
```bash
journalctl -u v2rayzone-dash -n 50
```

**Logs from today:**
```bash
journalctl -u v2rayzone-dash --since today
```

## Troubleshooting

### Common Issues

#### 1. Service Won't Start

**Check logs:**
```bash
journalctl -u v2rayzone-dash -n 20
```

**Common causes:**
- Port 2053 already in use
- Missing dependencies
- Permission issues

**Solutions:**
```bash
# Check if port is in use
sudo netstat -tlnp | grep 2053

# Kill process using the port (if needed)
sudo kill -9 $(sudo lsof -t -i:2053)

# Restart the service
sudo systemctl restart v2rayzone-dash
```

#### 2. Dashboard Shows No Data

**Check vnstat:**
```bash
vnstat
```

**If vnstat shows no data:**
```bash
# Find your network interface
ip addr show

# Initialize vnstat for your interface (replace eth0 with your interface)
sudo vnstat -u -i eth0

# Wait a few minutes for data collection
```

#### 3. Can't Access Dashboard

**Check firewall:**
```bash
sudo ufw status
```

**Open port manually:**
```bash
sudo ufw allow 2053/tcp
```

**Check if service is listening:**
```bash
sudo netstat -tlnp | grep 2053
```

#### 4. Permission Denied Errors

**Fix file permissions:**
```bash
sudo chown -R root:root /opt/v2rayzone-dash
sudo chmod +x /opt/v2rayzone-dash/api/generate_json.sh
sudo chmod +x /opt/v2rayzone-dash/server.py
```

### Getting Help

1. **Check the logs first:**
   ```bash
   journalctl -u v2rayzone-dash -n 50
   ```

2. **Verify installation:**
   ```bash
   ls -la /opt/v2rayzone-dash/
   systemctl status v2rayzone-dash
   ```

3. **Test manual data generation:**
   ```bash
   sudo bash /opt/v2rayzone-dash/api/generate_json.sh
   cat /opt/v2rayzone-dash/api/stats.json
   ```

4. **Check network interface:**
   ```bash
   ip route | grep default
   vnstat --iflist
   ```

## Advanced Configuration

### Changing the Port

1. **Edit the server file:**
   ```bash
   sudo nano /opt/v2rayzone-dash/server.py
   ```
   
   Change `PORT = 2053` to your desired port.

2. **Update firewall:**
   ```bash
   sudo ufw allow YOUR_NEW_PORT/tcp
   sudo ufw delete allow 2053/tcp
   ```

3. **Restart service:**
   ```bash
   sudo systemctl restart v2rayzone-dash
   ```

### Custom Network Interface

If you want to monitor a specific network interface:

1. **Edit the generation script:**
   ```bash
   sudo nano /opt/v2rayzone-dash/api/generate_json.sh
   ```
   
   Modify the `get_primary_interface()` function to return your desired interface.

2. **Restart service:**
   ```bash
   sudo systemctl restart v2rayzone-dash
   ```

### Adding SSL/HTTPS

For production use, consider setting up a reverse proxy with SSL:

1. **Install Nginx:**
   ```bash
   sudo apt install nginx
   ```

2. **Configure Nginx:**
   ```bash
   sudo nano /etc/nginx/sites-available/v2rayzone-dash
   ```
   
   Add your SSL configuration and proxy to `localhost:2053`.

3. **Enable the site:**
   ```bash
   sudo ln -s /etc/nginx/sites-available/v2rayzone-dash /etc/nginx/sites-enabled/
   sudo systemctl restart nginx
   ```

## Uninstallation

To completely remove V2RayZone Dash:

```bash
# Stop and disable the service
sudo systemctl stop v2rayzone-dash
sudo systemctl disable v2rayzone-dash

# Remove service file
sudo rm /etc/systemd/system/v2rayzone-dash.service

# Remove installation directory
sudo rm -rf /opt/v2rayzone-dash

# Remove cron job
crontab -l | grep -v v2rayzone-dash | crontab -

# Reload systemd
sudo systemctl daemon-reload

# Optional: Remove vnstat if not needed
# sudo apt remove vnstat
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **No Authentication:** The default installation has no password protection
2. **No Encryption:** Traffic is sent over HTTP, not HTTPS
3. **Public Access:** The dashboard is accessible to anyone who knows your IP and port

**For production use, consider:**
- Setting up a reverse proxy with SSL
- Adding HTTP basic authentication
- Restricting access by IP address
- Using a VPN for access

## Support

If you encounter issues:

1. Check this installation guide
2. Review the main README.md
3. Check the GitHub issues page
4. Create a new issue with:
   - Your Ubuntu version
   - Error messages from logs
   - Steps to reproduce the problem