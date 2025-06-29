#!/usr/bin/env python3
"""
V2RayZone Dash - Local Test Server
Lightweight Python server for testing the bandwidth dashboard locally
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

# Configuration for local testing
PORT = 2053
INSTALL_DIR = os.path.dirname(os.path.abspath(__file__))
STATS_FILE = os.path.join(INSTALL_DIR, 'api', 'stats.json')
GENERATE_SCRIPT = os.path.join(INSTALL_DIR, 'api', 'generate_json.sh')

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
        # Serve dashboard files
        elif path == '/' or path == '/index.html':
            self.serve_file('dashboard/index.html', 'text/html')
        elif path == '/style.css':
            self.serve_file('dashboard/style.css', 'text/css')
        elif path == '/script.js':
            self.serve_file('dashboard/script.js', 'application/javascript')
        else:
            self.send_error(404, "File not found")
    
    def serve_file(self, file_path, content_type):
        """Serve a static file"""
        try:
            full_path = os.path.join(INSTALL_DIR, file_path)
            if os.path.exists(full_path):
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                self.send_response(200)
                self.send_header('Content-type', content_type)
                self.send_header('Content-Length', len(content.encode('utf-8')))
                self.end_headers()
                self.wfile.write(content.encode('utf-8'))
            else:
                self.send_error(404, f"File not found: {file_path}")
        except Exception as e:
            logger.error(f"Error serving file {file_path}: {e}")
            self.send_error(500, "Internal server error")
    
    def handle_stats_api(self):
        """Handle /api/stats endpoint"""
        try:
            # For local testing, generate mock data if stats file doesn't exist
            if not os.path.exists(STATS_FILE):
                self.generate_mock_stats()
            
            # Check if stats file is older than 10 seconds
            if os.path.exists(STATS_FILE):
                file_age = time.time() - os.path.getmtime(STATS_FILE)
                if file_age > 10:
                    self.generate_mock_stats()
            
            # Read and return stats
            if os.path.exists(STATS_FILE):
                with open(STATS_FILE, 'r') as f:
                    stats_data = json.load(f)
                
                self.send_json_response(stats_data)
            else:
                self.send_error(500, "Stats file not available")
                
        except Exception as e:
            logger.error(f"Error handling stats API: {e}")
            self.send_error(500, "Internal server error")
    
    def handle_health_api(self):
        """Handle /api/health endpoint"""
        health_data = {
            "status": "healthy",
            "timestamp": datetime.now().isoformat(),
            "server": "V2RayZone Dash Local Test",
            "uptime": self.get_uptime()
        }
        self.send_json_response(health_data)
    
    def handle_refresh_api(self):
        """Handle /api/refresh endpoint"""
        try:
            self.generate_mock_stats()
            self.send_json_response({"status": "refreshed", "timestamp": datetime.now().isoformat()})
        except Exception as e:
            logger.error(f"Error refreshing stats: {e}")
            self.send_error(500, "Failed to refresh stats")
    
    def generate_mock_stats(self):
        """Generate mock statistics for local testing"""
        try:
            # Create api directory if it doesn't exist
            api_dir = os.path.join(INSTALL_DIR, 'api')
            os.makedirs(api_dir, exist_ok=True)
            
            # Generate mock data
            import random
            current_time = datetime.now()
            
            mock_data = {
                "current": {
                    "rx_rate": random.randint(1000000, 10000000),  # 1-10 MB/s
                    "tx_rate": random.randint(500000, 5000000),    # 0.5-5 MB/s
                    "interface": "eth0"
                },
                "today": {
                    "rx": random.randint(1000000000, 10000000000),  # 1-10 GB
                    "tx": random.randint(500000000, 5000000000),    # 0.5-5 GB
                    "date": current_time.strftime("%Y-%m-%d")
                },
                "monthly": {
                    "rx": random.randint(50000000000, 500000000000),  # 50-500 GB
                    "tx": random.randint(25000000000, 250000000000),  # 25-250 GB
                    "month": current_time.strftime("%Y-%m")
                },
                "daily_history": [
                    {
                        "date": (current_time.replace(day=current_time.day-i)).strftime("%Y-%m-%d"),
                        "rx": random.randint(1000000000, 10000000000),
                        "tx": random.randint(500000000, 5000000000)
                    } for i in range(7, 0, -1)
                ],
                "system": {
                    "server_ip": "127.0.0.1",
                    "uptime": "Local Test Mode",
                    "vnstat_version": "Mock Data v1.0"
                },
                "meta": {
                    "generated_at": current_time.isoformat(),
                    "interface": "eth0",
                    "status": "mock_data"
                }
            }
            
            # Write mock data to stats file
            with open(STATS_FILE, 'w') as f:
                json.dump(mock_data, f, indent=2)
            
            logger.info("Generated mock statistics for local testing")
            
        except Exception as e:
            logger.error(f"Error generating mock stats: {e}")
    
    def send_json_response(self, data):
        """Send JSON response"""
        try:
            json_data = json.dumps(data, indent=2)
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.send_header('Content-Length', len(json_data.encode('utf-8')))
            self.end_headers()
            self.wfile.write(json_data.encode('utf-8'))
        except Exception as e:
            logger.error(f"Error sending JSON response: {e}")
            self.send_error(500, "Failed to send response")
    
    def get_uptime(self):
        """Get server uptime (mock for local testing)"""
        return "Local test mode - uptime simulation"
    
    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(f"{self.address_string()} - {format % args}")

class StatsUpdater:
    """Background thread to update stats periodically"""
    
    def __init__(self, handler_class):
        self.handler_class = handler_class
        self.running = False
        self.thread = None
    
    def start(self):
        """Start the background updater"""
        self.running = True
        self.thread = threading.Thread(target=self._update_loop, daemon=True)
        self.thread.start()
        logger.info("Started background stats updater")
    
    def stop(self):
        """Stop the background updater"""
        self.running = False
        if self.thread:
            self.thread.join()
        logger.info("Stopped background stats updater")
    
    def _update_loop(self):
        """Background update loop"""
        while self.running:
            try:
                # Create a temporary handler instance to generate mock stats
                temp_handler = self.handler_class(None, None, None)
                temp_handler.generate_mock_stats()
                logger.debug("Updated stats in background")
            except Exception as e:
                logger.error(f"Error in background stats update: {e}")
            
            # Wait 60 seconds before next update
            for _ in range(60):
                if not self.running:
                    break
                time.sleep(1)

def main():
    """Main server function"""
    try:
        # Check if installation directory exists
        if not os.path.exists(INSTALL_DIR):
            logger.error(f"Installation directory not found: {INSTALL_DIR}")
            return 1
        
        logger.info(f"Starting V2RayZone Dash Local Test Server...")
        logger.info(f"Installation directory: {INSTALL_DIR}")
        logger.info(f"Stats file: {STATS_FILE}")
        
        # Create API directory if it doesn't exist
        api_dir = os.path.join(INSTALL_DIR, 'api')
        os.makedirs(api_dir, exist_ok=True)
        
        # Start background stats updater
        updater = StatsUpdater(DashboardHandler)
        updater.start()
        
        # Create and start server
        server = HTTPServer(('localhost', PORT), DashboardHandler)
        
        logger.info(f"Server started successfully!")
        logger.info(f"Dashboard URL: http://localhost:{PORT}")
        logger.info(f"API Health: http://localhost:{PORT}/api/health")
        logger.info(f"API Stats: http://localhost:{PORT}/api/stats")
        logger.info("Press Ctrl+C to stop the server")
        
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            logger.info("Received shutdown signal")
        finally:
            updater.stop()
            server.shutdown()
            logger.info("Server stopped")
        
        return 0
        
    except Exception as e:
        logger.error(f"Failed to start server: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(main())