#!/bin/bash
# MIT License
# Copyright (c) 2025 Lil5354
# EcoCheck Backend Entrypoint Script

# Don't exit on error - we want to continue even if migrations fail
# set -e

echo "========================================="
echo "Starting EcoCheck Backend..."
echo "Environment: ${NODE_ENV:-development}"
echo "Port: ${PORT:-3000}"
echo "========================================="

# Debug: Log database connection info (hide password)
echo "Database Configuration:"
if [ -n "$DATABASE_URL" ]; then
    echo "  DATABASE_URL: ${DATABASE_URL%%@*}@*** (hidden)"
else
    echo "  ⚠ WARNING: DATABASE_URL is NOT set!"
fi
echo "  DB_HOST: ${DB_HOST:-not set}"
echo "  DB_PORT: ${DB_PORT:-not set}"
echo "  DB_USER: ${DB_USER:-not set}"
echo "  DB_NAME: ${DB_NAME:-not set}"
echo "  DB_PASSWORD: ${DB_PASSWORD:+***hidden***}"
echo "========================================="

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
echo "========================================="
echo "Checking for migration script..."
echo "Current directory: $(pwd)"
echo "Checking /app/db/run_migrations.sh..."

if [ -f "/app/db/run_migrations.sh" ]; then
    echo "✓ Migration script found at /app/db/run_migrations.sh"
    
    # Check if we have database connection info
    if [ -z "$DB_HOST" ] && [ -z "$DATABASE_URL" ]; then
        echo "⚠ WARNING: No database connection info found (DB_HOST or DATABASE_URL)"
        echo "⚠ Skipping migrations - database connection may fail later"
    else
        echo "========================================="
        echo "Running database migrations..."
        echo "DB_HOST: ${DB_HOST:-not set}"
        echo "DB_NAME: ${DB_NAME:-not set}"
        echo "========================================="
        
        # Force-cleaning problematic migration entry before running (only if DB_HOST is set)
        if [ -n "$DB_HOST" ] && [ -n "$DB_PASSWORD" ] && [ -n "$DB_USER" ] && [ -n "$DB_NAME" ]; then
            echo "Force-cleaning problematic migration entry before running..."
            PGPASSWORD=$DB_PASSWORD psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USER" -d "$DB_NAME" -c "DELETE FROM schema_migrations WHERE version = '008_create_alerts_table.sql';" 2>/dev/null || echo "Clean-up skipped (table may not exist yet)"
        fi
        
        # Fix line endings and make script executable
        echo "Preparing migration script..."
        sed -i 's/\r$//' /app/db/run_migrations.sh
        chmod +x /app/db/run_migrations.sh
        echo "✓ Migration script is executable"
        
        # Export DB_* variables so run_migrations.sh can use them
        export DB_HOST
        export DB_PORT
        export DB_USER
        export DB_PASSWORD
        export DB_NAME
        
        # Verify migration files exist
        if [ -d "/app/db/migrations" ]; then
            MIGRATION_COUNT=$(ls -1 /app/db/migrations/*.sql 2>/dev/null | wc -l)
            echo "Found $MIGRATION_COUNT migration file(s) in /app/db/migrations"
        else
            echo "⚠ WARNING: /app/db/migrations directory not found!"
        fi
        
        # Go to the db directory to run the script
        echo "Changing to /app/db directory..."
        cd /app/db
        echo "Current directory: $(pwd)"
        echo "Running migration script..."
        
        # Run migrations and capture exit code
        if /bin/bash ./run_migrations.sh; then
            MIGRATION_EXIT_CODE=$?
            echo "========================================="
            echo "✓ Migrations completed successfully!"
            echo "========================================="
        else
            MIGRATION_EXIT_CODE=$?
            echo "========================================="
            echo "⚠ WARNING: Migration script exited with code: $MIGRATION_EXIT_CODE"
            echo "⚠ Continuing anyway, but tables may not exist..."
            echo "========================================="
        fi
        
        cd /app # Return to app directory
    fi
else
    echo "⚠ WARNING: Migration script not found at /app/db/run_migrations.sh"
    echo "Listing /app/db contents:"
    ls -la /app/db/ 2>/dev/null || echo "Directory /app/db does not exist!"
    echo "Skipping migrations."
fi

# Ensure we're in the backend directory (supervisor sets directory, but migrations may have changed it)
if [ -d "/app/backend" ]; then
    cd /app/backend
    echo "Working directory: $(pwd)"
elif [ -d "/app/src" ]; then
    cd /app
    echo "Working directory: $(pwd)"
else
    echo "ERROR: Cannot find backend directory!"
    exit 1
fi

# Verify package.json exists
if [ ! -f "package.json" ]; then
    echo "ERROR: Cannot find package.json in $(pwd)"
    exit 1
fi

# Start the application
echo "Starting Node.js backend..."
exec npm start