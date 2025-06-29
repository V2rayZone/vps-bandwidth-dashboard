#!/usr/bin/env python3
"""
V2RayZone Dash - Web Server
Lightweight Python server for the bandwidth dashboard
"""

import os
import sys
import json
import time
import threading
import subprocess
from http.server import HTTPServer, SimpleHTTPRequestHandler
from urllib.parse import urlparse, parse_qs
from datetime import datetime
import logging

# Configuration
PORT = 2053
INSTALL_DIR = '/opt/v2rayzone-dash'
STATS_FILE = '/opt/v2rayzone-dash/api/stats.json'
GENERATE_SCRIPT = '/opt/v2rayzone-dash/api/generate_json.sh'

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class DashboardHandler(SimpleHTTPRequestHandler):
    """Custom HTTP handler for the dashboard"""
    
    def __init__(self, *args, **kwargs):
        # Change to the installation directory
        os.chdir(INSTALL_DIR)
        super().__init__(*args, **kwargs)
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # API endpoints
        if path == '/api/stats':
            self.handle_stats_api()
        elif path == '/api/health':
            self.handle_health_api()
        elif path == '/api/refresh':
            self.handle_refresh_api()
        # Static files
        elif path == '/' or path == '/index.html':
            self.serve_file('index.html', 'text/html')
        elif path == '/style.css':
            self.serve_file('style.css', 'text/css')
        elif path == '/script.js':
            self.serve_file('script.js', 'application/javascript')
        else:
            self.send_error(404, 'File not found')
    
    def handle_stats_api(self):
        """Handle /api/stats endpoint"""
        try:
            # Check if stats file exists and is recent
            if not os.path.exists(STATS_FILE):
                logger.warning(f"Stats file not found: {STATS_FILE}")
                self.generate_stats()
            
            # Check if file is older than 10 seconds
            file_age = time.time() - os.path.getmtime(STATS_FILE)
            if file_age > 10:
                logger.info("Stats file is old, regenerating...")
                self.generate_stats()
            
            # Read and serve the stats file
            with open(STATS_FILE, 'r') as f:
                stats_data = f.read()
            
            # Validate JSON
            json.loads(stats_data)  # This will raise an exception if invalid
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.end_headers()
            self.wfile.write(stats_data.encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error serving stats API: {e}")
            self.send_error_json(500, f"Internal server error: {str(e)}")
    
    def handle_health_api(self):
        """Handle /api/health endpoint"""
        try:
            health_data = {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'server': 'V2RayZone Dash',
                'version': '1.0',
                'uptime': self.get_server_uptime()
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(health_data).encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error serving health API: {e}")
            self.send_error_json(500, f"Health check failed: {str(e)}")
    
    def handle_refresh_api(self):
        """Handle /api/refresh endpoint - force regenerate stats"""
        try:
            self.generate_stats()
            
            response_data = {
                'status': 'success',
                'message': 'Stats refreshed successfully',
                'timestamp': datetime.now().isoformat()
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response_data).encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error refreshing stats: {e}")
            self.send_error_json(500, f"Failed to refresh stats: {str(e)}")
    
    def serve_file(self, filename, content_type):
        """Serve a static file"""
        try:
            file_path = os.path.join(INSTALL_DIR, filename)
            
            if not os.path.exists(file_path):
                self.send_error(404, f'File not found: {filename}')
                return
            
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Cache-Control', 'public, max-age=300')  # 5 minutes cache
            self.end_headers()
            self.wfile.write(content.encode('utf-8'))
            
        except Exception as e:
            logger.error(f"Error serving file {filename}: {e}")
            self.send_error(500, f'Internal server error: {str(e)}')
    
    def send_error_json(self, code, message):
        """Send JSON error response"""
        error_data = {
            'error': True,
            'code': code,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(error_data).encode('utf-8'))
    
    def generate_stats(self):
        """Generate stats using the bash script"""
        try:
            if not os.path.exists(GENERATE_SCRIPT):
                raise FileNotFoundError(f"Generate script not found: {GENERATE_SCRIPT}")
            
            # Run the generate script
            result = subprocess.run(
                ['bash', GENERATE_SCRIPT],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode != 0:
                logger.error(f"Generate script failed: {result.stderr}")
                raise RuntimeError(f"Script execution failed: {result.stderr}")
            
            logger.info("Stats generated successfully")
            
        except subprocess.TimeoutExpired:
            logger.error("Generate script timed out")
            raise RuntimeError("Stats generation timed out")
        except Exception as e:
            logger.error(f"Error generating stats: {e}")
            raise
    
    def get_server_uptime(self):
        """Get server uptime"""
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
            
            days = int(uptime_seconds // 86400)
            hours = int((uptime_seconds % 86400) // 3600)
            minutes = int((uptime_seconds % 3600) // 60)
            
            return f"{days}d {hours}h {minutes}m"
        except:
            return "Unknown"
    
    def log_message(self, format, *args):
        """Override log message to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")

class StatsUpdater:
    """Background thread to update stats periodically"""
    
    def __init__(self, interval=60):
        self.interval = interval
        self.running = False
        self.thread = None
    
    def start(self):
        """Start the background updater"""
        if self.running:
            return
        
        self.running = True
        self.thread = threading.Thread(target=self._update_loop, daemon=True)
        self.thread.start()
        logger.info(f"Stats updater started with {self.interval}s interval")
    
    def stop(self):
        """Stop the background updater"""
        self.running = False
        if self.thread:
            self.thread.join()
        logger.info("Stats updater stopped")
    
    def _update_loop(self):
        """Main update loop"""
        while self.running:
            try:
                # Generate stats
                result = subprocess.run(
                    ['bash', GENERATE_SCRIPT],
                    capture_output=True,
                    text=True,
                    timeout=30
                )
                
                if result.returncode == 0:
                    logger.debug("Background stats update successful")
                else:
                    logger.warning(f"Background stats update failed: {result.stderr}")
                
            except Exception as e:
                logger.error(f"Error in background stats update: {e}")
            
            # Wait for next update
            for _ in range(self.interval):
                if not self.running:
                    break
                time.sleep(1)

def main():
    """Main server function"""
    try:
        # Change to installation directory
        if os.path.exists(INSTALL_DIR):
            os.chdir(INSTALL_DIR)
        else:
            logger.error(f"Installation directory not found: {INSTALL_DIR}")
            sys.exit(1)
        
        # Create stats directory if it doesn't exist
        os.makedirs(os.path.dirname(STATS_FILE), exist_ok=True)
        
        # Generate initial stats
        logger.info("Generating initial stats...")
        try:
            subprocess.run(['bash', GENERATE_SCRIPT], check=True, timeout=30)
        except Exception as e:
            logger.warning(f"Failed to generate initial stats: {e}")
        
        # Start background stats updater
        updater = StatsUpdater(interval=60)  # Update every minute
        updater.start()
        
        # Start HTTP server
        server_address = ('', PORT)
        httpd = HTTPServer(server_address, DashboardHandler)
        
        logger.info(f"V2RayZone Dash server starting on port {PORT}")
        logger.info(f"Dashboard available at: http://localhost:{PORT}")
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            logger.info("Server interrupted by user")
        finally:
            updater.stop()
            httpd.server_close()
            logger.info("Server stopped")
    
    except Exception as e:
        logger.error(f"Server startup failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()