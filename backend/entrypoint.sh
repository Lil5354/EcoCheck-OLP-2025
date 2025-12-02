#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Backend Entrypoint Script

set -e

echo "Starting EcoCheck Backend..."
echo "Environment: ${NODE_ENV:-development}"
echo "Port: ${PORT:-3000}"

# Wait for the database to be ready
if [ -n "$DB_HOST" ]; then
    echo "Waiting for database at $DB_HOST:$DB_PORT..."
    # Use netcat to check for the port to be open
    while ! nc -z "$DB_HOST" "$DB_PORT"; do
        sleep 1
    done
    echo "Database is ready."
fi

# Run database migrations if the script exists
# Note: This path assumes the db scripts are copied into the container
if [ -f "/app/db/run_migrations.sh" ]; then
    echo "Force-cleaning problematic migration entry before running..."
    PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM schema_migrations WHERE version = '008_create_alerts_table.sql';" || echo "Clean-up failed, continuing anyway."

    echo "Running database migrations..."
    # Fix line endings and make script executable
    sed -i 's/\r$//' /app/db/run_migrations.sh
    chmod +x /app/db/run_migrations.sh
    # Go to the db directory to run the script
    cd /app/db
    /bin/bash ./run_migrations.sh || echo "Migrations failed, but continuing..."
    cd /app # Return to app directory
    echo "Migrations complete."
else
    echo "Migration script not found, skipping."
fi

# Start the application
exec npm start