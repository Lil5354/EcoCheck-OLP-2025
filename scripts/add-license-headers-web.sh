#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all JSX/JS files in frontend-web-manager

set -e

echo "========================================"
echo "  Add License Headers to Frontend Web"
echo "========================================"
echo ""

# License header template
LICENSE_HEADER='/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 */
'

# Function to add license header
add_license_header() {
    local file="$1"
    
    # Check if already has license
    if grep -q "MIT License" "$file" || grep -q "Copyright (c) 2025" "$file"; then
        echo "  ⏭️  Skipping (already has license): $file"
        return
    fi
    
    # Add header before first import
    if grep -q "^import " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
    elif grep -q "^export " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
    else
        # Add at beginning
        echo -e "$LICENSE_HEADER$(cat "$file")" > "$file"
    fi
    
    echo "  ✅ Added license header: $file"
}

# Process Frontend Web files
echo "Processing Frontend Web Manager..."
WEB_COUNT=0
while IFS= read -r -d '' file; do
    add_license_header "$file"
    ((WEB_COUNT++))
done < <(find frontend-web-manager/src -name "*.js" -o -name "*.jsx" -type f -print0)
echo "  Processed $WEB_COUNT files"
echo ""

echo "========================================"
echo "✅ Completed!"
echo "  Total: $WEB_COUNT files"
echo "========================================"

