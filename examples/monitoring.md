# Example: Monitoring with Prometheus

This example shows how to monitor the Windows Update Cache using Prometheus and the Nginx VTS module.

## Prerequisites

- Prometheus installed
- nginx-module-vts (optional, for detailed metrics)

## Basic Monitoring with nginx-prometheus-exporter

### 1. Install nginx-prometheus-exporter

```bash
wget https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
tar xzf nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz
sudo mv nginx-prometheus-exporter /usr/local/bin/
```

### 2. Create systemd service

Create `/etc/systemd/system/nginx-prometheus-exporter.service`:

```ini
[Unit]
Description=Nginx Prometheus Exporter
After=network.target

[Service]
Type=simple
User=www-data
ExecStart=/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://localhost/cache-status
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### 3. Enable and start the exporter

```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx-prometheus-exporter
sudo systemctl start nginx-prometheus-exporter
```

### 4. Configure Prometheus

Add to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'windows-update-cache'
    static_configs:
      - targets: ['localhost:9113']
        labels:
          service: 'windows-update-cache'
```

### 5. Restart Prometheus

```bash
sudo systemctl restart prometheus
```

## Metrics to Monitor

Key metrics to watch:

- **nginx_http_requests_total**: Total number of requests
- **nginx_connections_active**: Active connections
- **nginx_connections_accepted**: Accepted connections
- Cache hit rate (custom metric based on logs)

## Custom Cache Metrics Script

Create a script to export cache statistics:

```bash
#!/bin/bash
# /usr/local/bin/cache-metrics.sh

CACHE_DIR="/nginx/www"
METRICS_FILE="/var/lib/node_exporter/textfile_collector/cache.prom"

# Calculate cache size in bytes
CACHE_SIZE=$(du -sb "$CACHE_DIR" 2>/dev/null | cut -f1)
CACHE_FILES=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)

# Write metrics
cat > "$METRICS_FILE" << EOF
# HELP windows_update_cache_size_bytes Total cache size in bytes
# TYPE windows_update_cache_size_bytes gauge
windows_update_cache_size_bytes $CACHE_SIZE

# HELP windows_update_cache_files_total Total number of cached files
# TYPE windows_update_cache_files_total gauge
windows_update_cache_files_total $CACHE_FILES
EOF
```

Add to crontab to run every 5 minutes:
```bash
*/5 * * * * /usr/local/bin/cache-metrics.sh
```

## Grafana Dashboard

Import or create a Grafana dashboard with panels for:

1. **Cache Hit Rate**: Percentage of requests served from cache
2. **Cache Size**: Total size of cached data over time
3. **Request Rate**: Requests per second
4. **Active Connections**: Current active connections
5. **Top Cached Files**: Most frequently accessed files

## Example Prometheus Queries

### Cache hit rate (approximate)
```promql
rate(nginx_http_requests_total[5m])
```

### Cache size growth rate
```promql
rate(windows_update_cache_size_bytes[1h])
```

### Number of cached files
```promql
windows_update_cache_files_total
```

## Alerts

Example alert rules:

```yaml
groups:
  - name: windows_update_cache
    rules:
      - alert: CacheDiskFull
        expr: (windows_update_cache_size_bytes / 1024 / 1024 / 1024) > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Cache disk usage is high"
          description: "Cache is using more than 90GB"

      - alert: NginxDown
        expr: up{job="windows-update-cache"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Nginx is down"
          description: "Windows Update Cache service is not responding"
```
