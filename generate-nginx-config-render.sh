#!/bin/sh
# Generate nginx config with PORT from Render environment
# Render injects PORT variable - nginx must listen on this port

PORT=${PORT:-10000}

echo "========================================="
echo "Generating nginx configuration for Render..."
echo "Render PORT: $PORT"
echo "========================================="

# Replace PORT placeholder in nginx config template
# Alpine Nginx includes conf.d/*.conf at ROOT level (not in http block)
# So we need to create a complete nginx.conf that includes our server config in http block
sed -e "s/listen 0.0.0.0:10000/listen 0.0.0.0:$PORT/g" \
    -e "s/listen 10000/listen 0.0.0.0:$PORT/g" \
    /etc/nginx/conf.d/default.conf.template > /tmp/server.conf

# Create a complete nginx.conf that includes our server block in http context
cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
pcre_jit on;
error_log /var/log/nginx/error.log warn;
include /etc/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    
    access_log /var/log/nginx/access.log main;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    
    gzip on;
    gzip_vary on;
    
    # Include our server config
    include /tmp/server.conf;
}
EOF

# Also create the file in conf.d for backup (but it won't be used)
cp /tmp/server.conf /etc/nginx/conf.d/default.conf

# Verify config was generated
if [ ! -f /tmp/server.conf ] || [ ! -f /etc/nginx/nginx.conf ]; then
    echo "✗ ERROR: Failed to generate nginx config"
    exit 1
fi

echo "✓ Nginx config generated successfully"
echo "Nginx will listen on port: $PORT"

# Verify the port was replaced correctly
if grep -q "listen.*$PORT" /tmp/server.conf; then
    echo "✓ Verified: Nginx config contains 'listen.*$PORT'"
    grep "listen" /tmp/server.conf
else
    echo "✗ ERROR: Nginx config does not contain 'listen.*$PORT'"
    echo "Config file preview:"
    grep "listen" /tmp/server.conf || echo "No 'listen' directive found"
    exit 1
fi

# Test nginx configuration
echo "Testing nginx configuration..."
if /usr/sbin/nginx -t 2>&1; then
    echo "✓ Nginx config test passed"
else
    echo "✗ ERROR: Nginx config test failed"
    echo "Main nginx.conf content:"
    cat /etc/nginx/nginx.conf | head -30
    echo "---"
    echo "Server config content:"
    cat /tmp/server.conf | head -20
    exit 1
fi

