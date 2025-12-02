# MIT License
# Copyright (c) 2025 Lil5354
# Quick build and push script for lilweyy5354

$ErrorActionPreference = "Stop"

# Set configuration
$env:DOCKER_REGISTRY = "lilweyy5354"
$env:IMAGE_TAG = "latest"
$env:VITE_API_URL = "http://localhost:3000"  # Update this with your server IP later

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "EcoCheck Build and Push Script" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Docker Registry: $env:DOCKER_REGISTRY" -ForegroundColor White
Write-Host "Image Tag: $env:IMAGE_TAG" -ForegroundColor White
Write-Host ""

# Check Docker
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    docker info | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Check login
Write-Host ""
Write-Host "Checking Docker Hub login..." -ForegroundColor Yellow
$loginCheck = docker system info 2>&1 | Select-String "Username"
if (-not $loginCheck) {
    Write-Host "⚠️  Not logged in to Docker Hub" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please login first:" -ForegroundColor Yellow
    Write-Host "  docker login" -ForegroundColor Green
    Write-Host ""
    Write-Host "Username: lilweyy5354" -ForegroundColor White
    Write-Host ""
    $login = Read-Host "Press Enter after logging in, or type 'skip' to login manually"
    if ($login -eq "skip") {
        Write-Host "Skipping login check. Please make sure you're logged in before building." -ForegroundColor Yellow
    } else {
        Write-Host "Continuing with build..." -ForegroundColor Green
    }
} else {
    Write-Host "✅ Already logged in to Docker Hub" -ForegroundColor Green
}

# Build and push
Write-Host ""
Write-Host "Starting build and push process..." -ForegroundColor Yellow
Write-Host ""

# Run the main build script
& "$PSScriptRoot\build-and-push-images.ps1"


