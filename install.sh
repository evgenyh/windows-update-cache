#!/bin/bash

# Installation script for Windows Update Cache on Ubuntu 20.04
# This script installs and configures Nginx as a caching proxy for Windows Updates

set -e

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)" 
   exit 1
fi

echo "=========================================="
echo "Windows Update Cache Installation"
echo "=========================================="
echo ""

# Update package list
echo "[1/6] Updating package list..."
apt-get update -qq

# Install Nginx
echo "[2/6] Installing Nginx..."
apt-get install -y nginx

# Stop nginx if running
systemctl stop nginx || true

# Create cache directory
echo "[3/6] Creating cache directory structure..."
mkdir -p /nginx/www
mkdir -p /nginx/www/tmp
chown -R www-data:www-data /nginx/www
chmod -R 755 /nginx/www

# Backup existing nginx configuration
if [ -f /etc/nginx/nginx.conf ]; then
    echo "[4/6] Backing up existing Nginx configuration..."
    cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup.$(date +%Y%m%d-%H%M%S)
fi

# Copy nginx configuration
echo "[5/6] Installing Nginx configuration..."
cp nginx.conf /etc/nginx/nginx.conf

# Test nginx configuration
echo "Testing Nginx configuration..."
nginx -t

# Enable and start the service
echo "[6/6] Enabling and starting Windows Update Cache service..."
systemctl enable nginx
systemctl start nginx

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "The Windows Update Cache is now running on port 80."
echo "Cache directory: /nginx/www"
echo ""
echo "Next steps:"
echo "1. Configure your Windows clients to use this server as a proxy"
echo "2. Monitor cache status with: systemctl status nginx"
echo "3. View cache contents: ls -lh /nginx/www"
echo "4. Check logs: tail -f /var/log/nginx/access.log"
echo ""
echo "To manage the cache:"
echo "  - Clean old cache: sudo ./scripts/clean-cache.sh"
echo "  - View cache stats: sudo ./scripts/cache-stats.sh"
echo ""
