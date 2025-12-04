#!/bin/bash
# Clear All Routes and Schedules
# Purpose: Execute SQL script to remove all routes and schedules data

echo "================================================"
echo "Clear All Routes and Schedules Data"
echo "================================================"
echo ""
echo "WARNING: This will delete all route and schedule data!"
echo "Make sure you have a backup if needed."
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Operation cancelled."
    exit 0
fi

# Get database connection details from environment or use defaults
DB_HOST=${DB_HOST:-localhost}
DB_PORT=${DB_PORT:-5432}
DB_NAME=${DB_NAME:-ecocheck_db}
DB_USER=${DB_USER:-ecocheck_user}

echo ""
echo "Connecting to database: $DB_NAME on $DB_HOST:$DB_PORT"
echo ""

# Execute the SQL script
PGPASSWORD=$DB_PASSWORD psql \
    -h "$DB_HOST" \
    -p "$DB_PORT" \
    -U "$DB_USER" \
    -d "$DB_NAME" \
    -f "$(dirname "$0")/clear_all_routes_and_schedules.sql"

if [ $? -eq 0 ]; then
    echo ""
    echo "================================================"
    echo "SUCCESS: All routes and schedules cleared!"
    echo "================================================"
    echo ""
    echo "Next steps:"
    echo "1. Go to the web interface"
    echo "2. Create new routes"
    echo "3. Test the collection completion synchronization"
    echo ""
else
    echo ""
    echo "ERROR: Failed to clear routes and schedules"
    echo "Please check the error messages above"
    exit 1
fi
