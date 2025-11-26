# Test script for creating worker account
# Usage: .\scripts\test-create-worker.ps1

$baseUrl = "http://localhost:3000"

Write-Host "=== Testing Worker Account Creation ===" -ForegroundColor Cyan

# Step 1: Get depots
Write-Host "`n1. Getting depots..." -ForegroundColor Yellow
$depotsResponse = Invoke-RestMethod -Uri "$baseUrl/api/master/depots" -Method GET
$depotId = $depotsResponse.data[0].id
Write-Host "   Using depot: $($depotsResponse.data[0].name) ($depotId)" -ForegroundColor Green

# Step 2: Create worker account
Write-Host "`n2. Creating worker account..." -ForegroundColor Yellow
$timestamp = [DateTimeOffset]::Now.ToUnixTimeSeconds()
$workerData = @{
    name = "Nguyễn Văn Test"
    email = "test.worker.$timestamp@ecocheck.com"
    phone = "09$($timestamp.ToString().Substring(0,8))"
    password = "123456"
    role = "driver"
    depot_id = $depotId
} | ConvertTo-Json

try {
    $createResponse = Invoke-RestMethod -Uri "$baseUrl/api/manager/personnel" -Method POST -Body $workerData -ContentType "application/json"
    
    if ($createResponse.ok) {
        Write-Host "   ✓ Worker created successfully!" -ForegroundColor Green
        Write-Host "   Worker ID: $($createResponse.data.id)" -ForegroundColor Cyan
        Write-Host "   User ID: $($createResponse.data.userId)" -ForegroundColor Cyan
        Write-Host "   Email: $($createResponse.data.credentials.email)" -ForegroundColor Cyan
        Write-Host "   Password: $($createResponse.data.credentials.password)" -ForegroundColor Cyan
        
        $testEmail = $createResponse.data.credentials.email
        $testPassword = $createResponse.data.credentials.password
    } else {
        Write-Host "   ✗ Failed: $($createResponse.error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Test login with created account
Write-Host "`n3. Testing login with created account..." -ForegroundColor Yellow
$loginData = @{
    email = $testEmail
    password = $testPassword
} | ConvertTo-Json

try {
    $loginResponse = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" -Method POST -Body $loginData -ContentType "application/json"
    
    if ($loginResponse.ok) {
        Write-Host "   ✓ Login successful!" -ForegroundColor Green
        Write-Host "   User ID: $($loginResponse.data.id)" -ForegroundColor Cyan
        Write-Host "   Role: $($loginResponse.data.role)" -ForegroundColor Cyan
        Write-Host "   Worker ID: $($loginResponse.data.workerId)" -ForegroundColor Cyan
        Write-Host "   Worker Name: $($loginResponse.data.workerName)" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ Login failed: $($loginResponse.error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ✗ Login error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== All tests passed! ===" -ForegroundColor Green
Write-Host "`nCredentials for mobile app:" -ForegroundColor Cyan
Write-Host "  Email: $testEmail" -ForegroundColor White
Write-Host "  Password: $testPassword" -ForegroundColor White

