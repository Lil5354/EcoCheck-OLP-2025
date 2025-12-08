# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all JS files in backend

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Add License Headers to Backend" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# License header template
$licenseHeader = @"
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend
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
    
    # Add header before first import, require, const, or other statement
    if ($content -match "^const ") {
        $content = $content -replace "^const ", "$licenseHeader`n`nconst "
    } elseif ($content -match "^let ") {
        $content = $content -replace "^let ", "$licenseHeader`n`nlet "
    } elseif ($content -match "^var ") {
        $content = $content -replace "^var ", "$licenseHeader`n`nvar "
    } elseif ($content -match "^require\(") {
        $content = $content -replace "^require\(", "$licenseHeader`n`nrequire("
    } elseif ($content -match "^import ") {
        $content = $content -replace "^import ", "$licenseHeader`n`nimport "
    } else {
        # Add at the beginning
        $content = $licenseHeader + "`n`n" + $content
    }
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host "  ✅ Added license header: $FilePath" -ForegroundColor Green
}

# Process Backend files
Write-Host "Processing Backend..." -ForegroundColor Cyan
$backendFiles = Get-ChildItem -Path "backend\src" -Filter "*.js" -Recurse -File
$backendCount = 0
foreach ($file in $backendFiles) {
    Add-LicenseHeader -FilePath $file.FullName
    $backendCount++
}
Write-Host "  Processed $backendCount files" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Completed!" -ForegroundColor Green
Write-Host "  Total: $backendCount files" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

