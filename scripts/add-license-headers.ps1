# MIT License
# Copyright (c) 2025 Lil5354
# Script to add license headers to all Dart files in mobile apps

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Add License Headers to Dart Files" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# License header template
$licenseHeader = @"
/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck - [APP_NAME]
 */

"@

# Function to add license header to a file
function Add-LicenseHeader {
    param (
        [string]$FilePath,
        [string]$AppName
    )
    
    $content = Get-Content $FilePath -Raw
    $header = $licenseHeader -replace "\[APP_NAME\]", $AppName
    
    # Check if file already has license header
    if ($content -match "MIT License" -or $content -match "Copyright \(c\) 2025") {
        Write-Host "  ⏭️  Skipping (already has license): $FilePath" -ForegroundColor Yellow
        return
    }
    
    # Add header before first import or other statement
    if ($content -match "^import ") {
        $content = $content -replace "^import ", "$header`nimport "
    } elseif ($content -match "^library ") {
        $content = $content -replace "^library ", "$header`nlibrary "
    } elseif ($content -match "^part ") {
        $content = $content -replace "^part ", "$header`npart "
    } else {
        # Add at the beginning
        $content = $header + $content
    }
    
    Set-Content -Path $FilePath -Value $content -NoNewline
    Write-Host "  ✅ Added license header: $FilePath" -ForegroundColor Green
}

# Process EcoCheck_Worker
Write-Host "Processing EcoCheck_Worker..." -ForegroundColor Cyan
$workerFiles = Get-ChildItem -Path "frontend-mobile\EcoCheck_Worker\lib" -Filter "*.dart" -Recurse -File
$workerCount = 0
foreach ($file in $workerFiles) {
    Add-LicenseHeader -FilePath $file.FullName -AppName "EcoCheck Worker"
    $workerCount++
}
Write-Host "  Processed $workerCount files" -ForegroundColor Green
Write-Host ""

# Process EcoCheck_User
Write-Host "Processing EcoCheck_User..." -ForegroundColor Cyan
$userFiles = Get-ChildItem -Path "frontend-mobile\EcoCheck_User\lib" -Filter "*.dart" -Recurse -File
$userCount = 0
foreach ($file in $userFiles) {
    Add-LicenseHeader -FilePath $file.FullName -AppName "EcoCheck User"
    $userCount++
}
Write-Host "  Processed $userCount files" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Completed!" -ForegroundColor Green
Write-Host "  Worker: $workerCount files" -ForegroundColor White
Write-Host "  User: $userCount files" -ForegroundColor White
Write-Host "  Total: $($workerCount + $userCount) files" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

