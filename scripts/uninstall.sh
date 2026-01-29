#!/bin/bash

# Uninstallation script for Windows Update Cache
# This script removes the Windows Update Cache service and optionally removes cached data

set -e

REMOVE_CACHE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --remove-cache)
            REMOVE_CACHE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --remove-cache     Also remove cached data from /nginx/www"
            echo "  -h, --help         Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "=========================================="
echo "Windows Update Cache Uninstallation"
echo "=========================================="
echo ""

# Stop nginx service
if systemctl is-active --quiet nginx; then
    echo "Stopping Nginx service..."
    systemctl stop nginx
fi

# Disable nginx service
if systemctl is-enabled --quiet nginx 2>/dev/null; then
    echo "Disabling Nginx service..."
    systemctl disable nginx
fi

# Restore backup configuration if exists
if [ -f /etc/nginx/nginx.conf.backup.* ]; then
    LATEST_BACKUP=$(ls -t /etc/nginx/nginx.conf.backup.* | head -1)
    echo "Restoring Nginx configuration from backup..."
    cp "$LATEST_BACKUP" /etc/nginx/nginx.conf
fi

# Remove cache data if requested
if [ "$REMOVE_CACHE" = true ]; then
    echo "Removing cached data..."
    if [ -d "/nginx/www" ]; then
        rm -rf /nginx/www
        echo "Cache directory removed: /nginx/www"
    fi
else
    echo "Cache data preserved in /nginx/www"
    echo "To remove it manually, run: sudo rm -rf /nginx/www"
fi

echo ""
echo "=========================================="
echo "Uninstallation Complete!"
echo "=========================================="
echo ""
echo "Nginx has been stopped and disabled."
if [ "$REMOVE_CACHE" = false ]; then
    echo "Cache data is still present in /nginx/www"
fi
echo ""
