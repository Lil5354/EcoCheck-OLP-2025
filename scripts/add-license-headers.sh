#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all Dart files in mobile apps

set -e

echo "========================================"
echo "  Add License Headers to Dart Files"
echo "========================================"
echo ""

# License header template
LICENSE_HEADER_WORKER='/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Worker
 */
'

LICENSE_HEADER_USER='/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck User
 */
'

# Function to add license header
add_license_header() {
    local file="$1"
    local app_name="$2"
    
    # Check if already has license
    if grep -q "MIT License" "$file" || grep -q "Copyright (c) 2025" "$file"; then
        echo "  ⏭️  Skipping (already has license): $file"
        return
    fi
    
    # Choose header based on app
    if [ "$app_name" = "Worker" ]; then
        HEADER="$LICENSE_HEADER_WORKER"
    else
        HEADER="$LICENSE_HEADER_USER"
    fi
    
    # Add header before first import
    if grep -q "^import " "$file"; then
        sed -i "1i\\$HEADER" "$file"
    elif grep -q "^library " "$file"; then
        sed -i "1i\\$HEADER" "$file"
    else
        # Add at beginning
        echo -e "$HEADER$(cat "$file")" > "$file"
    fi
    
    echo "  ✅ Added license header: $file"
}

# Process EcoCheck_Worker
echo "Processing EcoCheck_Worker..."
WORKER_COUNT=0
while IFS= read -r -d '' file; do
    add_license_header "$file" "Worker"
    ((WORKER_COUNT++))
done < <(find frontend-mobile/EcoCheck_Worker/lib -name "*.dart" -type f -print0)
echo "  Processed $WORKER_COUNT files"
echo ""

# Process EcoCheck_User
echo "Processing EcoCheck_User..."
USER_COUNT=0
while IFS= read -r -d '' file; do
    add_license_header "$file" "User"
    ((USER_COUNT++))
done < <(find frontend-mobile/EcoCheck_User/lib -name "*.dart" -type f -print0)
echo "  Processed $USER_COUNT files"
echo ""

echo "========================================"
echo "✅ Completed!"
echo "  Worker: $WORKER_COUNT files"
echo "  User: $USER_COUNT files"
echo "  Total: $((WORKER_COUNT + USER_COUNT)) files"
echo "========================================"

