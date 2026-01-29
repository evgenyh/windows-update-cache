#!/bin/bash

# Cache cleanup script for Windows Update Cache
# This script removes old cached files based on age

set -e

# Configuration
CACHE_DIR="/nginx/www"
MAX_AGE_DAYS=365  # Keep cache for 1 year by default
DRY_RUN=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--days)
            MAX_AGE_DAYS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --days DAYS    Maximum age of cache files in days (default: 365)"
            echo "  --dry-run          Show what would be deleted without actually deleting"
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
echo "Windows Update Cache Cleanup"
echo "=========================================="
echo "Cache directory: $CACHE_DIR"
echo "Maximum age: $MAX_AGE_DAYS days"
echo "Dry run: $DRY_RUN"
echo ""

# Get current cache size
if [ -d "$CACHE_DIR" ]; then
    BEFORE_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
    echo "Current cache size: $BEFORE_SIZE"
else
    echo "Cache directory does not exist: $CACHE_DIR"
    exit 1
fi

# Count files to be deleted
FILE_COUNT=$(find "$CACHE_DIR" -type f -mtime +$MAX_AGE_DAYS 2>/dev/null | wc -l)
echo "Files older than $MAX_AGE_DAYS days: $FILE_COUNT"
echo ""

if [ $FILE_COUNT -eq 0 ]; then
    echo "No files to clean up."
    exit 0
fi

if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN - Files that would be deleted:"
    find "$CACHE_DIR" -type f -mtime +$MAX_AGE_DAYS -ls 2>/dev/null
else
    echo "Deleting old cache files..."
    find "$CACHE_DIR" -type f -mtime +$MAX_AGE_DAYS -delete 2>/dev/null
    
    # Remove empty directories
    echo "Removing empty directories..."
    find "$CACHE_DIR" -type d -empty -delete 2>/dev/null || true
    
    AFTER_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1 || echo "0")
    echo ""
    echo "Cleanup complete!"
    echo "Cache size before: $BEFORE_SIZE"
    echo "Cache size after: $AFTER_SIZE"
fi

echo ""
echo "=========================================="
