# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all JSX/JS files in frontend-web-manager

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Add License Headers to Frontend Web" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# License header template
$licenseHeader = @"
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Frontend Web Manager
 */

"@

# Function to add license header to a file
function Add-LicenseHeader {
    param (
        [string]$FilePath
    )
    
    $content = Get-Content $FilePath -Raw
    
    # Check if file already has license header
    if ($content -match "MIT License" -or $content -match "Copyright \(c\) 2025") {
        Write-Host "  ⏭️  Skipping (already has license): $FilePath" -ForegroundColor Yellow
        return
    }
    
    # Add header before first import or other statement
    if ($content -match "^import ") {
        $content = $content -replace "^import ", "$licenseHeader`nimport "
    } elseif ($content -match "^export ") {
        $content = $content -replace "^export ", "$licenseHeader`nexport "
    } else {
        # Add at the beginning
        $content = $licenseHeader + $content
    }
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host "  ✅ Added license header: $FilePath" -ForegroundColor Green
}

# Process Frontend Web files
Write-Host "Processing Frontend Web Manager..." -ForegroundColor Cyan
$webFiles = Get-ChildItem -Path "frontend-web-manager\src" -Include "*.js", "*.jsx" -Recurse -File
$webCount = 0
foreach ($file in $webFiles) {
    Add-LicenseHeader -FilePath $file.FullName
    $webCount++
}
Write-Host "  Processed $webCount files" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Completed!" -ForegroundColor Green
Write-Host "  Total: $webCount files" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

