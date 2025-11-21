#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Backend Entrypoint Script

set -e

echo "Starting EcoCheck Backend..."
echo "Environment: ${NODE_ENV:-development}"
echo "Port: ${PORT:-3000}"

# Wait for database if needed
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database connection..."
    sleep 5
fi

# Start the application
exec npm start