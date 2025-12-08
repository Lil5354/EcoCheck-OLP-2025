#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all JS files in backend

set -e

echo "========================================"
echo "  Add License Headers to Backend"
echo "========================================"
echo ""

# License header template
LICENSE_HEADER='/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend
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
    
    # Add header before first statement
    if grep -q "^const " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
        echo "" >> "$file"
    elif grep -q "^let " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
        echo "" >> "$file"
    elif grep -q "^var " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
        echo "" >> "$file"
    elif grep -q "^require(" "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
        echo "" >> "$file"
    elif grep -q "^import " "$file"; then
        sed -i "1i\\$LICENSE_HEADER" "$file"
        echo "" >> "$file"
    else
        # Add at beginning
        echo -e "$LICENSE_HEADER\n$(cat "$file")" > "$file"
    fi
    
    echo "  ✅ Added license header: $file"
}

# Process Backend files
echo "Processing Backend..."
BACKEND_COUNT=0
while IFS= read -r -d '' file; do
    add_license_header "$file"
    ((BACKEND_COUNT++))
done < <(find backend/src -name "*.js" -type f -print0)
echo "  Processed $BACKEND_COUNT files"
echo ""

echo "========================================"
echo "✅ Completed!"
echo "  Total: $BACKEND_COUNT files"
echo "========================================"

