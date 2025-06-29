# V2RayZone Dash - Project Structure

This document outlines the complete structure of the V2RayZone Dash project.

## 📁 Repository Structure

```
vps-bandwidth-dashboard/
├── 📄 README.md                    # Main project documentation
├── 📄 LICENSE                      # MIT License
├── 📄 INSTALL.md                   # Detailed installation guide
├── 📄 PROJECT_STRUCTURE.md         # This file - project overview
├── 📄 .gitignore                   # Git ignore rules
├── 🔧 install.sh                   # Main installation script
├── 🐍 server.py                    # Python web server
├── 📁 dashboard/                   # Web dashboard files
│   ├── 📄 index.html              # Main dashboard HTML
│   ├── 🎨 style.css               # Dashboard styles
│   └── ⚡ script.js               # Dashboard JavaScript
└── 📁 api/                         # API and data generation
    └── 🔧 generate_json.sh         # Stats generation script
```

## 📋 File Descriptions

### Root Files

#### 📄 README.md
- **Purpose:** Main project documentation and quick start guide
- **Content:** Project overview, installation instructions, features, usage
- **Audience:** Users and developers

#### 📄 LICENSE
- **Purpose:** MIT License for the project
- **Content:** Standard MIT license text
- **Importance:** Legal protection and usage rights

#### 📄 INSTALL.md
- **Purpose:** Comprehensive installation and troubleshooting guide
- **Content:** Detailed setup instructions, troubleshooting, configuration
- **Audience:** System administrators and advanced users

#### 📄 .gitignore
- **Purpose:** Git ignore rules for the repository
- **Content:** Excludes logs, temporary files, generated data, IDE files
- **Importance:** Keeps repository clean

#### 🔧 install.sh
- **Purpose:** Main installation script
- **Functionality:**
  - Detects Ubuntu version
  - Installs dependencies (vnstat, curl, jq, python3, etc.)
  - Downloads dashboard files from GitHub
  - Sets up systemd service
  - Configures firewall
  - Creates cron jobs
- **Target:** Ubuntu 18.04, 20.04, 22.04
- **Execution:** `bash <(curl -Ls https://github.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh)`

#### 🐍 server.py
- **Purpose:** Lightweight Python web server
- **Functionality:**
  - Serves dashboard files (HTML, CSS, JS)
  - Provides API endpoints (/api/stats, /api/health, /api/refresh)
  - Handles JSON data generation
  - Background stats updating
  - Error handling and logging
- **Port:** 2053 (configurable)
- **Dependencies:** Python 3 standard library only

### 📁 dashboard/ Directory

#### 📄 index.html
- **Purpose:** Main dashboard user interface
- **Features:**
  - Real-time bandwidth display
  - Current usage statistics
  - Daily and monthly usage summaries
  - Interactive charts (Chart.js)
  - System information panel
  - Responsive design
  - Error handling modal
- **Dependencies:** Chart.js (CDN), style.css, script.js

#### 🎨 style.css
- **Purpose:** Dashboard styling and responsive design
- **Features:**
  - Modern gradient background
  - Glass-morphism design elements
  - Responsive grid layouts
  - Smooth animations and transitions
  - Mobile-friendly design
  - Dark/light theme support
  - Loading animations
- **Framework:** Pure CSS (no dependencies)

#### ⚡ script.js
- **Purpose:** Dashboard interactivity and data management
- **Features:**
  - Real-time data fetching (5-second intervals)
  - Chart.js integration for graphs
  - Auto-refresh functionality
  - Pause/resume controls
  - Error handling and retry logic
  - Data formatting utilities
  - Responsive chart resizing
- **Dependencies:** Chart.js

### 📁 api/ Directory

#### 🔧 generate_json.sh
- **Purpose:** Generate JSON statistics from vnstat data
- **Functionality:**
  - Detects primary network interface
  - Extracts current bandwidth rates
  - Parses vnstat JSON output
  - Generates daily/monthly statistics
  - Creates historical data arrays
  - Outputs formatted JSON
  - Error handling and fallbacks
- **Output:** `/opt/v2rayzone-dash/api/stats.json`
- **Execution:** Called by cron and Python server

## 🚀 Installation Flow

### 1. Pre-Installation
```bash
# User runs one-line installer
bash <(curl -Ls https://github.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh)
```

### 2. Installation Process
1. **System Check:** Verify Ubuntu version and root access
2. **Dependencies:** Install vnstat, curl, jq, python3, net-tools
3. **Directory Setup:** Create `/opt/v2rayzone-dash/`
4. **File Download:** Download all dashboard and API files from GitHub
5. **Service Creation:** Create systemd service file
6. **Firewall:** Configure UFW to allow port 2053
7. **Cron Setup:** Add cron job for data updates
8. **Service Start:** Start and enable the service

### 3. Post-Installation
- Service runs automatically on boot
- Dashboard accessible at `http://SERVER_IP:2053`
- Data updates every minute via cron
- Real-time updates every 5 seconds via JavaScript

## 🔄 Runtime Architecture

### Data Flow
```
vnstat → generate_json.sh → stats.json → server.py → dashboard
   ↑            ↑              ↑          ↑         ↑
System      Cron Job      API File   Web Server  Browser
```

### Components Interaction

1. **vnstat Service:**
   - Continuously monitors network interfaces
   - Stores historical data in database
   - Provides JSON output via CLI

2. **generate_json.sh:**
   - Runs every minute via cron
   - Queries vnstat for current and historical data
   - Formats data into JSON structure
   - Writes to stats.json file

3. **server.py:**
   - Serves static dashboard files
   - Provides API endpoints for data access
   - Handles background stats generation
   - Manages error responses

4. **Dashboard (Browser):**
   - Fetches data from API every 5 seconds
   - Updates charts and statistics
   - Handles user interactions
   - Displays error messages

## 🛠️ Development Workflow

### Local Development
1. Clone repository
2. Modify files as needed
3. Test on Ubuntu VM/container
4. Update GitHub repository
5. Test installation script

### File Modification
- **Dashboard changes:** Edit files in `dashboard/`
- **Server changes:** Modify `server.py`
- **Data processing:** Update `api/generate_json.sh`
- **Installation:** Modify `install.sh`

### Testing
- Test on fresh Ubuntu installations
- Verify all features work correctly
- Check error handling
- Validate responsive design

## 📊 Data Structure

### stats.json Format
```json
{
  "current": {
    "rx_rate": 1024,
    "tx_rate": 512
  },
  "today": {
    "rx": 1073741824,
    "tx": 536870912,
    "total": 1610612736
  },
  "month": {
    "rx": 32212254720,
    "tx": 16106127360,
    "total": 48318382080
  },
  "daily_history": [
    {
      "date": "2024-01-15",
      "rx": 1073741824,
      "tx": 536870912
    }
  ],
  "interface": "eth0",
  "server_ip": "192.168.1.100",
  "uptime": "5 days, 3 hours",
  "vnstat_version": "2.6",
  "timestamp": 1642262400
}
```

## 🔧 Configuration Options

### Customizable Settings
- **Port:** Change in `server.py` (default: 2053)
- **Update Interval:** Modify in `script.js` (default: 5 seconds)
- **Data Retention:** Adjust in `script.js` (default: 60 points)
- **Network Interface:** Configure in `generate_json.sh`
- **Cron Frequency:** Modify crontab entry (default: every minute)

### Environment Variables
- None required (all configuration is file-based)

## 🔒 Security Considerations

### Current Security Level
- ❌ No authentication
- ❌ No encryption (HTTP only)
- ❌ No access control
- ✅ Read-only data access
- ✅ No sensitive data exposure

### Recommended Improvements
- Add HTTP basic authentication
- Implement HTTPS with SSL certificates
- Add IP-based access restrictions
- Use reverse proxy (Nginx/Apache)
- Implement rate limiting

## 📈 Future Enhancements

### Planned Features
- SSL/HTTPS support
- Authentication system
- Multiple interface monitoring
- Data export (CSV/JSON)
- Email alerts for usage thresholds
- Mobile app
- Docker container support
- Configuration web interface

### Technical Improvements
- WebSocket for real-time updates
- Database storage for historical data
- API rate limiting
- Caching mechanisms
- Performance optimizations

## 🐛 Known Issues

### Current Limitations
- Requires root access for installation
- Limited to Ubuntu systems
- No data persistence across reinstalls
- Basic error handling
- No backup/restore functionality

### Workarounds
- Manual port configuration for conflicts
- Firewall rules may need manual adjustment
- vnstat may need manual interface initialization

## 📞 Support and Maintenance

### Regular Maintenance
- Monitor service status
- Check log files for errors
- Update dependencies as needed
- Backup configuration if customized

### Troubleshooting Resources
- Check `INSTALL.md` for common issues
- Review service logs: `journalctl -u v2rayzone-dash`
- Verify file permissions and ownership
- Test network connectivity and firewall rules