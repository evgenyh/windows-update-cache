#!/bin/bash

# Cache statistics script for Windows Update Cache
# This script displays statistics about the cache

set -e

CACHE_DIR="/nginx/www"

# Check if running as root or in www-data group
if [[ $EUID -ne 0 ]] && ! groups | grep -q www-data; then
   echo "This script should be run as root or a user in the www-data group" 
   exit 1
fi

echo "=========================================="
echo "Windows Update Cache Statistics"
echo "=========================================="
echo ""

if [ ! -d "$CACHE_DIR" ]; then
    echo "Cache directory does not exist: $CACHE_DIR"
    exit 1
fi

# Total cache size
TOTAL_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
echo "Total cache size: $TOTAL_SIZE"

# Disk usage
DISK_USAGE=$(df -h "$CACHE_DIR" | awk 'NR==2 {print $5}')
echo "Disk usage: $DISK_USAGE"

# Total number of files
TOTAL_FILES=$(find "$CACHE_DIR" -type f 2>/dev/null | wc -l)
echo "Total cached files: $TOTAL_FILES"

echo ""
echo "File breakdown by extension:"
echo "----------------------------"
for ext in cab exe psf msi msp msu; do
    COUNT=$(find "$CACHE_DIR" -type f -name "*.$ext" 2>/dev/null | wc -l)
    if [ $COUNT -gt 0 ]; then
        SIZE=$(find "$CACHE_DIR" -type f -name "*.$ext" -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
        echo "  .$ext: $COUNT files ($SIZE)"
    fi
done

echo ""
echo "Cache age distribution:"
echo "----------------------"
echo "  Last 24 hours: $(find "$CACHE_DIR" -type f -mtime -1 2>/dev/null | wc -l) files"
echo "  Last 7 days: $(find "$CACHE_DIR" -type f -mtime -7 2>/dev/null | wc -l) files"
echo "  Last 30 days: $(find "$CACHE_DIR" -type f -mtime -30 2>/dev/null | wc -l) files"
echo "  Last 90 days: $(find "$CACHE_DIR" -type f -mtime -90 2>/dev/null | wc -l) files"
echo "  Older than 365 days: $(find "$CACHE_DIR" -type f -mtime +365 2>/dev/null | wc -l) files"

echo ""
echo "Largest cached files:"
echo "--------------------"
find "$CACHE_DIR" -type f -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr | head -10 | awk '{print "  " $9 " - " $5}'

echo ""
echo "=========================================="
