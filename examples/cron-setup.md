# Example: Automatic Cache Cleanup with Cron

This example shows how to set up automatic cache cleanup that runs weekly.

## Setup

1. Open the crontab editor:
   ```bash
   sudo crontab -e
   ```

2. Add the following line to run cleanup every Sunday at 2 AM:
   ```cron
   0 2 * * 0 /path/to/windows-update-cache/scripts/clean-cache.sh --days 180 >> /var/log/cache-cleanup.log 2>&1
   ```

3. Save and exit.

## Verify Cron Job

List scheduled cron jobs:
```bash
sudo crontab -l
```

## Check Cleanup Logs

View the cleanup log:
```bash
sudo tail -f /var/log/cache-cleanup.log
```

## Alternative Schedule Examples

### Daily cleanup at 3 AM (keeping 90 days)
```cron
0 3 * * * /path/to/windows-update-cache/scripts/clean-cache.sh --days 90 >> /var/log/cache-cleanup.log 2>&1
```

### Monthly cleanup on the 1st at midnight (keeping 365 days)
```cron
0 0 1 * * /path/to/windows-update-cache/scripts/clean-cache.sh --days 365 >> /var/log/cache-cleanup.log 2>&1
```

### Weekly cleanup on Monday at 1 AM (keeping 180 days)
```cron
0 1 * * 1 /path/to/windows-update-cache/scripts/clean-cache.sh --days 180 >> /var/log/cache-cleanup.log 2>&1
```

## Log Rotation

To prevent the cleanup log from growing too large, create a logrotate configuration:

1. Create `/etc/logrotate.d/cache-cleanup`:
   ```
   /var/log/cache-cleanup.log {
       weekly
       rotate 4
       compress
       missingok
       notifempty
   }
   ```

2. Test the configuration:
   ```bash
   sudo logrotate -d /etc/logrotate.d/cache-cleanup
   ```
