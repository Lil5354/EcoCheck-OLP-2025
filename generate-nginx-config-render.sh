#!/bin/sh
# Generate nginx config with PORT from Render environment
# Render injects PORT variable - nginx must listen on this port

PORT=${PORT:-10000}

echo "========================================="
echo "Generating nginx configuration for Render..."
echo "Render PORT: $PORT"
echo "========================================="

# Replace PORT placeholder in nginx config template
# Replace both "listen 10000" and "listen 0.0.0.0:10000" patterns
sed -e "s/listen 0.0.0.0:10000/listen 0.0.0.0:$PORT/g" \
    -e "s/listen 10000/listen 0.0.0.0:$PORT/g" \
    /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Verify config was generated
if [ ! -f /etc/nginx/conf.d/default.conf ]; then
    echo "✗ ERROR: Failed to generate nginx config"
    exit 1
fi

echo "✓ Nginx config generated successfully"
echo "Nginx will listen on port: $PORT"

# Verify the port was replaced correctly
if grep -q "listen.*$PORT" /etc/nginx/conf.d/default.conf; then
    echo "✓ Verified: Nginx config contains 'listen.*$PORT'"
    grep "listen" /etc/nginx/conf.d/default.conf
else
    echo "✗ ERROR: Nginx config does not contain 'listen.*$PORT'"
    echo "Config file preview:"
    grep "listen" /etc/nginx/conf.d/default.conf || echo "No 'listen' directive found"
    exit 1
fi

# Test nginx configuration
echo "Testing nginx configuration..."
if /usr/sbin/nginx -t 2>&1; then
    echo "✓ Nginx config test passed"
else
    echo "✗ ERROR: Nginx config test failed"
    echo "Config file content:"
    cat /etc/nginx/conf.d/default.conf
    exit 1
fi

