# Quick Start Guide

This is a quick start guide to get the Windows Update Cache up and running in minutes.

## Prerequisites

- Ubuntu 20.04 LTS system
- Root or sudo access
- At least 100GB free disk space
- Internet connection

## Installation (5 minutes)

1. **Clone the repository**
   ```bash
   git clone https://github.com/evgenyh/windows-update-cache.git
   cd windows-update-cache
   ```

2. **Run the installer**
   ```bash
   sudo ./install.sh
   ```

3. **Verify the service is running**
   ```bash
   sudo systemctl status nginx
   ```

That's it! The cache server is now running on port 80.

## Configure Windows Clients (2 minutes)

### Option 1: Command Line (Recommended)

Open **Command Prompt as Administrator** on your Windows machine and run:

```cmd
netsh winhttp set proxy proxy-server="http://YOUR_SERVER_IP:80" bypass-list="<local>"
```

Replace `YOUR_SERVER_IP` with the IP address of your Ubuntu cache server.

### Option 2: Windows Settings

1. Open **Settings** → **Network & Internet** → **Proxy**
2. Enable **Use a proxy server**
3. Address: `YOUR_SERVER_IP`
4. Port: `80`
5. Click **Save**

## Test It

1. **On Windows**: Run Windows Update
2. **On Ubuntu Server**: Watch the cache in action
   ```bash
   sudo tail -f /var/log/nginx/access.log
   ```

You should see Windows Update requests being cached!

## View Cache Statistics

```bash
sudo ./scripts/cache-stats.sh
```

## Common Commands

| Task | Command |
|------|---------|
| Check service status | `sudo systemctl status nginx` |
| View access logs | `sudo tail -f /var/log/nginx/access.log` |
| View cache stats | `sudo ./scripts/cache-stats.sh` |
| Clean old cache | `sudo ./scripts/clean-cache.sh --days 180` |
| Restart service | `sudo systemctl restart nginx` |

## Troubleshooting

### Service not running?

```bash
sudo systemctl start nginx
sudo systemctl status nginx
```

### Windows not using cache?

Verify proxy settings on Windows:
```cmd
netsh winhttp show proxy
```

### Check firewall

Ensure port 80 is open:
```bash
sudo ufw allow 80/tcp
```

## Next Steps

- Read the full [README.md](README.md) for detailed configuration options
- Set up automatic cache cleanup with cron
- Monitor disk usage regularly

## Support

For detailed documentation, see [README.md](README.md)

For issues, visit: https://github.com/evgenyh/windows-update-cache/issues
