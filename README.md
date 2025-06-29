# V2RayZone Dash - VPS Bandwidth Dashboard

🚀 **One-line installer for Ubuntu VPS bandwidth monitoring dashboard**

## 💡 What it does

V2RayZone Dash automatically sets up a web-based bandwidth monitoring dashboard on your Ubuntu VPS that:
- Tracks real-time bandwidth usage (upload/download)
- Shows historical daily and monthly statistics
- Provides a clean web interface accessible from anywhere
- Runs on port 2053 with minimal resource usage

## 🖥️ Requirements

- Ubuntu 18.04, 20.04, or 22.04
- Root or sudo access
- Internet connection for package installation

## ⚙️ Installation

**One-line installer:**
```bash
bash <(curl -Ls https://raw.githubusercontent.com/V2rayZone/vps-bandwidth-dashboard/main/install.sh)
```

## 🔗 Access

After installation, access your dashboard at:
```
http://YOUR_SERVER_IP:2053
```

## 📷 Features

- **Live Monitoring**: Real-time bandwidth usage display
- **Historical Data**: Daily and monthly usage graphs
- **Interface Detection**: Automatically detects network interface (eth0, ens3, etc.)
- **Lightweight**: Minimal resource usage
- **Auto-refresh**: Dashboard updates every 5 seconds

## 🛠️ What gets installed

- `vnstat` - Network statistics utility
- `curl`, `jq`, `net-tools` - Essential utilities
- Python3 HTTP server - Lightweight web server
- Dashboard files - HTML, CSS, JavaScript interface
- Systemd service - Auto-start on boot

## ⚠️ Security Notice

**Default installation has no authentication or SSL encryption.**

For production use, consider:
- Setting up a reverse proxy with SSL
- Adding password protection
- Restricting access by IP

## 🔧 Manual Management

**Start/Stop the service:**
```bash
sudo systemctl start v2rayzone-dash
sudo systemctl stop v2rayzone-dash
```

**Check service status:**
```bash
sudo systemctl status v2rayzone-dash
```

**View logs:**
```bash
journalctl -u v2rayzone-dash -f
```

## 📁 File Locations

- Dashboard files: `/opt/v2rayzone-dash/`
- Service file: `/etc/systemd/system/v2rayzone-dash.service`
- Log files: `journalctl -u v2rayzone-dash`

## 🔄 Uninstall

```bash
sudo systemctl stop v2rayzone-dash
sudo systemctl disable v2rayzone-dash
sudo rm /etc/systemd/system/v2rayzone-dash.service
sudo rm -rf /opt/v2rayzone-dash
sudo systemctl daemon-reload
```

## 📝 License

MIT License - see LICENSE file for details

## 🤝 Contributing

Pull requests welcome! Please test on fresh Ubuntu installations.

---

**Made with ❤️ for VPS monitoring**