# Windows Update Cache for Ubuntu 20.04

A caching solution for Microsoft Windows Updates using Nginx on Ubuntu 20.04. This solution reduces bandwidth usage by caching Windows Update files locally, allowing multiple Windows machines on your network to download updates from a local cache server instead of directly from Microsoft's servers.

## Features

- **Local caching**: Caches Windows Update files (`.cab`, `.exe`, `.psf`, `.msi`, `.msp`, `.msu`) to reduce bandwidth usage
- **Automatic management**: Uses systemd for automatic startup and process management
- **Easy installation**: Simple installation script for Ubuntu 20.04
- **Cache management**: Scripts for cleaning old cache files and viewing cache statistics
- **High performance**: Uses Nginx as a high-performance caching proxy
- **Large file support**: Handles large Windows Update files without size limits
- **Long-term storage**: Keeps cached files for up to 365 days by default

## Requirements

- Ubuntu 20.04 LTS (Server or Desktop)
- Root/sudo access
- At least 100GB of free disk space (for cache storage)
- Internet connection

## Installation

### Quick Install

1. Clone this repository:
```bash
git clone https://github.com/evgenyh/windows-update-cache.git
cd windows-update-cache
```

2. Run the installation script:
```bash
sudo ./install.sh
```

The installation script will:
- Install Nginx
- Create the cache directory structure at `/nginx/www`
- Configure Nginx for Windows Update caching
- Enable and start the service

### Manual Installation

If you prefer to install manually:

1. Install Nginx:
```bash
sudo apt-get update
sudo apt-get install -y nginx
```

2. Create cache directory:
```bash
sudo mkdir -p /nginx/www/tmp
sudo chown -R www-data:www-data /nginx/www
sudo chmod -R 755 /nginx/www
```

3. Backup existing Nginx configuration:
```bash
sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
```

4. Copy the new configuration:
```bash
sudo cp nginx.conf /etc/nginx/nginx.conf
```

5. Test and start Nginx:
```bash
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx
```

## Configuration

### Nginx Configuration

The main configuration file is `nginx.conf`. Key settings include:

- **Cache path**: `/nginx/www` (100GB max size)
- **Cache duration**: 365 days for successful downloads, 1 day for 404 errors
- **Listening port**: 80 (HTTP)
- **DNS resolvers**: 8.8.8.8 and 8.8.4.4 (Google DNS)

To modify these settings, edit `/etc/nginx/nginx.conf` and restart Nginx:
```bash
sudo systemctl restart nginx
```

### Configuring Windows Clients

To use the cache server, configure your Windows clients to use it as a proxy:

#### Method 1: Using Group Policy (for Domain environments)

1. Open Group Policy Management
2. Create or edit a GPO
3. Navigate to: `Computer Configuration → Preferences → Windows Settings → Registry`
4. Add a new Registry Item:
   - **Action**: Update
   - **Hive**: HKEY_LOCAL_MACHINE
   - **Key Path**: `SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings`
   - **Value name**: `ProxyServer`
   - **Value type**: REG_SZ
   - **Value data**: `http://YOUR_CACHE_SERVER_IP:80`

5. Add another Registry Item:
   - **Value name**: `ProxyEnable`
   - **Value type**: REG_DWORD
   - **Value data**: `1`

#### Method 2: Using netsh (local configuration)

Run as Administrator on each Windows client:
```cmd
netsh winhttp set proxy proxy-server="http://YOUR_CACHE_SERVER_IP:80" bypass-list="<local>"
```

#### Method 3: Using Windows Settings

1. Open Windows Settings
2. Go to Network & Internet → Proxy
3. Enable "Use a proxy server"
4. Set proxy address to your cache server IP and port 80

### Verify Configuration

On the Windows client, test the proxy configuration:
```cmd
netsh winhttp show proxy
```

## Usage

### Monitoring Cache Status

Check the service status:
```bash
sudo systemctl status nginx
```

View cache statistics:
```bash
sudo ./scripts/cache-stats.sh
```

This will show:
- Total cache size
- Number of cached files
- File breakdown by extension
- Cache age distribution
- Largest cached files

### Managing the Cache

#### Clean Old Cache Files

Remove files older than 365 days (default):
```bash
sudo ./scripts/clean-cache.sh
```

Remove files older than a specific number of days:
```bash
sudo ./scripts/clean-cache.sh --days 180
```

Preview what would be deleted without actually deleting:
```bash
sudo ./scripts/clean-cache.sh --dry-run
```

#### View Logs

Access logs (shows all requests):
```bash
sudo tail -f /var/log/nginx/access.log
```

Error logs:
```bash
sudo tail -f /var/log/nginx/error.log
```

#### Check Cache Status Endpoint

From the cache server:
```bash
curl http://localhost/cache-status
```

This endpoint shows Nginx status information (only accessible from localhost).

### Maintenance

#### Restart the Service

```bash
sudo systemctl restart nginx
```

#### Reload Configuration (without downtime)

```bash
sudo nginx -t  # Test configuration first
sudo systemctl reload nginx
```

#### Stop the Service

```bash
sudo systemctl stop nginx
```

## Uninstallation

To uninstall the Windows Update Cache:

```bash
sudo ./scripts/uninstall.sh
```

To also remove all cached data:
```bash
sudo ./scripts/uninstall.sh --remove-cache
```

This will:
- Stop the Nginx service
- Disable automatic startup
- Restore the original Nginx configuration
- Optionally remove cached data

## Troubleshooting

### Service won't start

Check Nginx configuration syntax:
```bash
sudo nginx -t
```

Check for port conflicts:
```bash
sudo netstat -tlnp | grep :80
```

### Cache not working

1. Verify Nginx is running:
```bash
sudo systemctl status nginx
```

2. Check if cache directory exists and has correct permissions:
```bash
ls -la /nginx/www
```

3. Check Nginx error logs:
```bash
sudo tail -n 50 /var/log/nginx/error.log
```

4. Test if proxy is working from Windows client:
```cmd
curl -I http://YOUR_CACHE_SERVER_IP
```

### Windows clients not using cache

1. Verify proxy settings on Windows client:
```cmd
netsh winhttp show proxy
```

2. Check Windows Update logs:
   - Location: `C:\Windows\WindowsUpdate.log`

3. Ensure firewall allows connections:
```bash
sudo ufw allow 80/tcp
```

### Disk space issues

1. Check available disk space:
```bash
df -h /nginx/www
```

2. Clean old cache files:
```bash
sudo ./scripts/clean-cache.sh --days 90
```

3. Reduce max cache size in `/etc/nginx/nginx.conf`:
   - Find the line: `proxy_cache_path /nginx/www ... max_size=100g`
   - Change `100g` to a smaller value (e.g., `50g`)
   - Restart Nginx: `sudo systemctl restart nginx`

## Advanced Configuration

### Adjusting Cache Size

Edit `/etc/nginx/nginx.conf` and modify the `proxy_cache_path` directive:

```nginx
proxy_cache_path /nginx/www levels=1:2 keys_zone=wucache:500m max_size=100g inactive=365d use_temp_path=off;
```

- `max_size=100g`: Maximum cache size (adjust as needed)
- `inactive=365d`: Remove files not accessed for 365 days

### Adding HTTPS Support

To add HTTPS support, you'll need an SSL certificate:

1. Install Certbot:
```bash
sudo apt-get install certbot python3-certbot-nginx
```

2. Obtain a certificate:
```bash
sudo certbot --nginx -d your-domain.com
```

3. Certbot will automatically configure Nginx for HTTPS.

### Using a Different Port

Edit `/etc/nginx/nginx.conf` and change the listen directive:

```nginx
listen 8080 default_server;  # Change from 80 to 8080
```

Then restart Nginx:
```bash
sudo systemctl restart nginx
```

Update your Windows clients to use the new port.

### Logging HTTP Headers

To log cache status headers for debugging, add to the `http` block in `/etc/nginx/nginx.conf`:

```nginx
log_format cache '$remote_addr - $remote_user [$time_local] "$request" '
                 '$status $body_bytes_sent "$http_referer" '
                 '"$http_user_agent" "$http_x_forwarded_for" '
                 'Cache: $upstream_cache_status';

access_log /var/log/nginx/access.log cache;
```

## Performance Tips

1. **Use SSD storage**: Place `/nginx/www` on an SSD for better performance
2. **Increase worker processes**: Adjust `worker_processes` in `nginx.conf` based on CPU cores
3. **Monitor disk I/O**: Use `iotop` to monitor disk usage
4. **Regular maintenance**: Run cleanup scripts weekly to remove old files
5. **Set up monitoring**: Use tools like Prometheus and Grafana to monitor cache hit rates

## Security Considerations

1. **Firewall**: Only allow connections from trusted networks
```bash
sudo ufw allow from 192.168.1.0/24 to any port 80
```

2. **Access control**: Restrict access to management scripts
```bash
chmod 700 scripts/*.sh
```

3. **Regular updates**: Keep Ubuntu and Nginx updated
```bash
sudo apt-get update && sudo apt-get upgrade
```

4. **Log monitoring**: Regularly review logs for unusual activity

## Architecture

```
Windows Clients
      ↓
      ↓ (proxy requests)
      ↓
Nginx Cache Server (Ubuntu 20.04)
      ↓
      ↓ (cache miss only)
      ↓
Microsoft Update Servers
```

## File Structure

```
windows-update-cache/
├── nginx.conf                          # Nginx configuration
├── windows-update-cache.service        # systemd service file (reference)
├── install.sh                          # Installation script
├── README.md                           # This file
└── scripts/
    ├── clean-cache.sh                  # Cache cleanup script
    ├── cache-stats.sh                  # Cache statistics script
    └── uninstall.sh                    # Uninstallation script
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is provided as-is, without warranty of any kind.

## Credits

Inspired by the original [chris41g/windows-update-cache](https://github.com/chris41g/windows-update-cache) Docker-based solution, migrated to native Ubuntu 20.04 with systemd management.

## Support

For issues, questions, or contributions, please open an issue on GitHub.
