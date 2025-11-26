# Test VRP Optimization API
# MIT License - Copyright (c) 2025 Lil5354

$ErrorActionPreference = "Stop"

$baseUrl = "http://localhost:3000"

Write-Host "🧪 Testing VRP Optimization API" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check backend health
Write-Host "1. Checking backend health..." -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri "$baseUrl/health" -Method Get -ErrorAction Stop
    Write-Host "   ✅ Backend is healthy" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Backend is not responding: $_" -ForegroundColor Red
    exit 1
}

# 2. Get depots
Write-Host "`n2. Getting depots..." -ForegroundColor Yellow
try {
    $depots = Invoke-RestMethod -Uri "$baseUrl/api/master/depots" -Method Get -ErrorAction Stop
    if ($depots.ok -and $depots.data.Count -gt 0) {
        $depotId = $depots.data[0].id
        Write-Host "   ✅ Found depot: $($depots.data[0].name) (ID: $depotId)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No depots found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Error getting depots: $_" -ForegroundColor Red
    exit 1
}

# 3. Get dumps
Write-Host "`n3. Getting dumps..." -ForegroundColor Yellow
try {
    $dumps = Invoke-RestMethod -Uri "$baseUrl/api/master/dumps" -Method Get -ErrorAction Stop
    if ($dumps.ok -and $dumps.data.Count -gt 0) {
        $dumpId = $dumps.data[0].id
        Write-Host "   ✅ Found dump: $($dumps.data[0].name) (ID: $dumpId)" -ForegroundColor Green
    } else {
        Write-Host "   ❌ No dumps found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Error getting dumps: $_" -ForegroundColor Red
    exit 1
}

# 4. Get vehicles
Write-Host "`n4. Getting vehicles..." -ForegroundColor Yellow
try {
    $fleet = Invoke-RestMethod -Uri "$baseUrl/api/master/fleet" -Method Get -ErrorAction Stop
    if ($fleet.ok -and $fleet.data.Count -gt 0) {
        $vehicleIds = $fleet.data[0..([Math]::Min(1, $fleet.data.Count - 1))].id
        Write-Host "   ✅ Found $($fleet.data.Count) vehicles" -ForegroundColor Green
        Write-Host "   Using vehicles: $($vehicleIds -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "   ❌ No vehicles found" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Error getting vehicles: $_" -ForegroundColor Red
    exit 1
}

# 5. Get schedules for today
Write-Host "`n5. Getting collection schedules..." -ForegroundColor Yellow
$today = (Get-Date).ToString("yyyy-MM-dd")
try {
    $schedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?scheduled_date=$today&status=scheduled" -Method Get -ErrorAction Stop
    if ($schedules.ok -and $schedules.data.Count -gt 0) {
        $validSchedules = $schedules.data | Where-Object { $_.latitude -and $_.longitude -and $_.route_id -eq $null }
        Write-Host "   ✅ Found $($validSchedules.Count) available schedules for today" -ForegroundColor Green
        if ($validSchedules.Count -eq 0) {
            Write-Host "   ⚠️  No schedules available for optimization (all may be assigned or missing coordinates)" -ForegroundColor Yellow
            Write-Host "   Trying with any date..." -ForegroundColor Yellow
            
            # Try to get any available schedule
            $allSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?status=scheduled&limit=100" -Method Get -ErrorAction Stop
            if ($allSchedules.ok -and $allSchedules.data.Count -gt 0) {
                $validSchedules = $allSchedules.data | Where-Object { $_.latitude -and $_.longitude -and $_.route_id -eq $null } | Select-Object -First 1
                if ($validSchedules) {
                    $today = $validSchedules.scheduled_date
                    Write-Host "   ✅ Using schedule from date: $today" -ForegroundColor Green
                } else {
                    Write-Host "   ❌ No valid schedules found. Please create some collection schedules first." -ForegroundColor Red
                    exit 1
                }
            } else {
                Write-Host "   ❌ No schedules found. Please create some collection schedules first." -ForegroundColor Red
                exit 1
            }
        }
    } else {
        Write-Host "   ⚠️  No schedules found for today. Trying with any date..." -ForegroundColor Yellow
        $allSchedules = Invoke-RestMethod -Uri "$baseUrl/api/schedules?status=scheduled&limit=100" -Method Get -ErrorAction Stop
        if ($allSchedules.ok -and $allSchedules.data.Count -gt 0) {
            $validSchedules = $allSchedules.data | Where-Object { $_.latitude -and $_.longitude -and $_.route_id -eq $null } | Select-Object -First 1
            if ($validSchedules) {
                $today = $validSchedules.scheduled_date
                Write-Host "   ✅ Using schedule from date: $today" -ForegroundColor Green
            } else {
                Write-Host "   ❌ No valid schedules found. Please create some collection schedules first." -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "   ❌ No schedules found. Please create some collection schedules first." -ForegroundColor Red
            exit 1
        }
    }
} catch {
    Write-Host "   ❌ Error getting schedules: $_" -ForegroundColor Red
    exit 1
}

# 6. Optimize routes
Write-Host "`n6. Optimizing routes..." -ForegroundColor Yellow
$optimizePayload = @{
    scheduled_date = $today
    depot_id = $depotId
    dump_id = $dumpId
    vehicles = $vehicleIds
    constraints = @{
        max_route_duration_min = 480
        max_stops_per_route = 20
        time_window_buffer_min = 30
    }
} | ConvertTo-Json -Depth 10

Write-Host "   Payload: $optimizePayload" -ForegroundColor Gray

try {
    $startTime = Get-Date
    $result = Invoke-RestMethod -Uri "$baseUrl/api/vrp/optimize" -Method Post -Body $optimizePayload -ContentType "application/json" -ErrorAction Stop
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    if ($result.ok) {
        Write-Host "   ✅ Optimization completed in $([Math]::Round($duration, 2)) seconds" -ForegroundColor Green
        Write-Host "   Routes created: $($result.data.routes.Count)" -ForegroundColor Cyan
        Write-Host "   Total distance: $($result.data.statistics.total_distance_km) km" -ForegroundColor Cyan
        Write-Host "   Total duration: $($result.data.statistics.total_duration_min) minutes" -ForegroundColor Cyan
        Write-Host "   Utilization rate: $([Math]::Round($result.data.statistics.utilization_rate * 100, 1))%" -ForegroundColor Cyan
        Write-Host "   Optimization score: $([Math]::Round($result.data.statistics.optimization_score * 100, 0))/100" -ForegroundColor Cyan
        
        if ($result.data.unassigned_schedules.Count -gt 0) {
            Write-Host "   ⚠️  Unassigned schedules: $($result.data.unassigned_schedules.Count)" -ForegroundColor Yellow
        }
        
        # Show route details
        if ($result.data.routes.Count -gt 0) {
            Write-Host "`n   Route Details:" -ForegroundColor Cyan
            foreach ($route in $result.data.routes) {
                Write-Host "   - Vehicle: $($route.vehicle_id), Stops: $($route.stops.Count), Distance: $($route.total_distance_km) km" -ForegroundColor Gray
            }
        }
        
        # 7. Save routes (optional)
        if ($result.data.routes.Count -gt 0) {
            Write-Host "`n7. Saving routes to database..." -ForegroundColor Yellow
            $savePayload = @{
                routes = $result.data.routes
                scheduled_date = $today
                depot_id = $depotId
                dump_id = $dumpId
            } | ConvertTo-Json -Depth 10
            
            try {
                $saveResult = Invoke-RestMethod -Uri "$baseUrl/api/vrp/save-routes" -Method Post -Body $savePayload -ContentType "application/json" -ErrorAction Stop
                if ($saveResult.ok) {
                    Write-Host "   ✅ Routes saved successfully!" -ForegroundColor Green
                    Write-Host "   Route IDs: $($saveResult.data.route_ids -join ', ')" -ForegroundColor Gray
                } else {
                    Write-Host "   ❌ Failed to save routes: $($saveResult.error)" -ForegroundColor Red
                }
            } catch {
                Write-Host "   ❌ Error saving routes: $_" -ForegroundColor Red
            }
        }
        
    } else {
        Write-Host "   ❌ Optimization failed: $($result.error)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "   ❌ Error during optimization: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response: $responseBody" -ForegroundColor Red
    }
    exit 1
}

Write-Host "`n✅ All tests passed!" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Cyan

