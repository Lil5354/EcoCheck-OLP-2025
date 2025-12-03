#!/bin/sh
# Startup script for Render deployment
# Generate nginx config before starting supervisor

set -e

echo "========================================="
echo "Starting EcoCheck Render Deployment"
echo "PORT=${PORT:-10000}"
echo "========================================="

# Generate nginx configuration
echo "Generating nginx configuration..."
if ! /usr/local/bin/generate-nginx-config.sh; then
    echo "ERROR: Failed to generate nginx configuration"
    exit 1
fi

# Verify nginx config exists
if [ ! -f /etc/nginx/conf.d/default.conf ]; then
    echo "ERROR: Nginx config file not found!"
    exit 1
fi

# Test nginx config
echo "Testing nginx configuration..."
if ! /usr/sbin/nginx -t 2>&1; then
    echo "ERROR: Nginx config test failed!"
    cat /etc/nginx/conf.d/default.conf
    exit 1
fi

echo "✓ Nginx configuration OK"
echo "Verifying nginx config file..."
cat /etc/nginx/conf.d/default.conf | grep -E "listen|server_name" || echo "WARNING: Could not verify nginx config content"

echo "Starting supervisor..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf

