// V2RayZone Dash - Dashboard JavaScript

class BandwidthDashboard {
    constructor() {
        this.updateInterval = 5000; // 5 seconds
        this.maxDataPoints = 60; // Keep last 60 data points for real-time chart
        this.isPaused = false;
        this.charts = {};
        this.realtimeData = {
            labels: [],
            rx: [],
            tx: []
        };
        
        this.init();
    }

    init() {
        this.setupCharts();
        this.setupEventListeners();
        this.startDataFetching();
        this.updateTimestamp();
    }

    setupCharts() {
        // Real-time bandwidth chart
        const realtimeCtx = document.getElementById('realtime-chart').getContext('2d');
        this.charts.realtime = new Chart(realtimeCtx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Download (KB/s)',
                    data: [],
                    borderColor: '#007bff',
                    backgroundColor: 'rgba(0, 123, 255, 0.1)',
                    tension: 0.4,
                    fill: true
                }, {
                    label: 'Upload (KB/s)',
                    data: [],
                    borderColor: '#28a745',
                    backgroundColor: 'rgba(40, 167, 69, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Speed (KB/s)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Time'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    }
                },
                animation: {
                    duration: 0 // Disable animation for real-time updates
                }
            }
        });

        // Daily usage chart
        const dailyCtx = document.getElementById('daily-chart').getContext('2d');
        this.charts.daily = new Chart(dailyCtx, {
            type: 'bar',
            data: {
                labels: [],
                datasets: [{
                    label: 'Download (MB)',
                    data: [],
                    backgroundColor: 'rgba(0, 123, 255, 0.8)',
                    borderColor: '#007bff',
                    borderWidth: 1
                }, {
                    label: 'Upload (MB)',
                    data: [],
                    backgroundColor: 'rgba(40, 167, 69, 0.8)',
                    borderColor: '#28a745',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Usage (MB)'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Date'
                        }
                    }
                },
                plugins: {
                    legend: {
                        display: true,
                        position: 'top'
                    }
                }
            }
        });
    }

    setupEventListeners() {
        // Pause/Resume button
        document.getElementById('pause-btn').addEventListener('click', () => {
            this.togglePause();
        });

        // Clear chart button
        document.getElementById('clear-btn').addEventListener('click', () => {
            this.clearRealtimeChart();
        });

        // Retry button in error modal
        document.getElementById('retry-btn').addEventListener('click', () => {
            this.hideErrorModal();
            this.fetchData();
        });
    }

    async fetchData() {
        try {
            const response = await fetch('/api/stats');
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }
            
            const data = await response.json();
            this.updateDashboard(data);
            this.updateConnectionStatus(true);
            
        } catch (error) {
            console.error('Error fetching data:', error);
            this.updateConnectionStatus(false, error.message);
            this.showErrorModal(error.message);
        }
    }

    updateDashboard(data) {
        // Update current usage
        this.updateElement('current-rx', this.formatSpeed(data.current.rx_rate));
        this.updateElement('current-tx', this.formatSpeed(data.current.tx_rate));
        
        // Update today's usage
        this.updateElement('today-rx', this.formatBytes(data.today.rx));
        this.updateElement('today-tx', this.formatBytes(data.today.tx));
        this.updateElement('today-total', this.formatBytes(data.today.total));
        
        // Update monthly usage
        this.updateElement('month-rx', this.formatBytes(data.month.rx));
        this.updateElement('month-tx', this.formatBytes(data.month.tx));
        this.updateElement('month-total', this.formatBytes(data.month.total));
        
        // Update system info
        this.updateElement('interface-name', data.interface || 'Unknown');
        this.updateElement('server-ip', data.server_ip || 'Unknown');
        this.updateElement('uptime', data.uptime || 'Unknown');
        this.updateElement('vnstat-version', data.vnstat_version || 'Unknown');
        
        // Update real-time chart
        if (!this.isPaused) {
            this.updateRealtimeChart(data.current.rx_rate, data.current.tx_rate);
        }
        
        // Update daily chart
        if (data.daily_history) {
            this.updateDailyChart(data.daily_history);
        }
        
        this.updateTimestamp();
    }

    updateElement(id, value, addPulse = true) {
        const element = document.getElementById(id);
        if (element && element.textContent !== value) {
            element.textContent = value;
            if (addPulse) {
                element.classList.add('pulse');
                setTimeout(() => element.classList.remove('pulse'), 500);
            }
        }
    }

    updateRealtimeChart(rxRate, txRate) {
        const now = new Date().toLocaleTimeString();
        
        // Add new data point
        this.realtimeData.labels.push(now);
        this.realtimeData.rx.push(rxRate / 1024); // Convert to KB/s
        this.realtimeData.tx.push(txRate / 1024); // Convert to KB/s
        
        // Remove old data points if we have too many
        if (this.realtimeData.labels.length > this.maxDataPoints) {
            this.realtimeData.labels.shift();
            this.realtimeData.rx.shift();
            this.realtimeData.tx.shift();
        }
        
        // Update chart
        this.charts.realtime.data.labels = [...this.realtimeData.labels];
        this.charts.realtime.data.datasets[0].data = [...this.realtimeData.rx];
        this.charts.realtime.data.datasets[1].data = [...this.realtimeData.tx];
        this.charts.realtime.update('none'); // No animation for real-time updates
    }

    updateDailyChart(dailyHistory) {
        const labels = dailyHistory.map(day => day.date);
        const rxData = dailyHistory.map(day => day.rx / (1024 * 1024)); // Convert to MB
        const txData = dailyHistory.map(day => day.tx / (1024 * 1024)); // Convert to MB
        
        this.charts.daily.data.labels = labels;
        this.charts.daily.data.datasets[0].data = rxData;
        this.charts.daily.data.datasets[1].data = txData;
        this.charts.daily.update();
    }

    updateConnectionStatus(isOnline, errorMessage = '') {
        const statusElement = document.getElementById('connection-status');
        if (isOnline) {
            statusElement.textContent = 'Online';
            statusElement.className = 'status-value online';
        } else {
            statusElement.textContent = 'Offline';
            statusElement.className = 'status-value offline';
        }
    }

    updateTimestamp() {
        const now = new Date().toLocaleString();
        this.updateElement('last-update', now, false);
    }

    togglePause() {
        this.isPaused = !this.isPaused;
        const pauseBtn = document.getElementById('pause-btn');
        pauseBtn.textContent = this.isPaused ? '▶️ Resume' : '⏸️ Pause';
    }

    clearRealtimeChart() {
        this.realtimeData.labels = [];
        this.realtimeData.rx = [];
        this.realtimeData.tx = [];
        
        this.charts.realtime.data.labels = [];
        this.charts.realtime.data.datasets[0].data = [];
        this.charts.realtime.data.datasets[1].data = [];
        this.charts.realtime.update();
    }

    showErrorModal(message) {
        document.getElementById('error-message').textContent = message;
        document.getElementById('error-modal').classList.remove('hidden');
    }

    hideErrorModal() {
        document.getElementById('error-modal').classList.add('hidden');
    }

    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    formatSpeed(bytesPerSecond) {
        if (bytesPerSecond === 0) return '0 B/s';
        
        const k = 1024;
        const sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
        const i = Math.floor(Math.log(bytesPerSecond) / Math.log(k));
        
        return parseFloat((bytesPerSecond / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    startDataFetching() {
        // Initial fetch
        this.fetchData();
        
        // Set up interval for regular updates
        setInterval(() => {
            if (!this.isPaused) {
                this.fetchData();
            }
        }, this.updateInterval);
    }
}

// Initialize dashboard when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new BandwidthDashboard();
});

// Handle page visibility changes to pause/resume updates
document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
        console.log('Page hidden, pausing updates');
    } else {
        console.log('Page visible, resuming updates');
    }
});

// Handle window resize for responsive charts
window.addEventListener('resize', () => {
    Object.values(window.dashboard?.charts || {}).forEach(chart => {
        if (chart && typeof chart.resize === 'function') {
            chart.resize();
        }
    });
});