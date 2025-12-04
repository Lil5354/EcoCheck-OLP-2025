-- Clear All Routes and Schedules Data
-- Purpose: Remove all existing routes, route_stops, and schedules to allow fresh creation from web
-- Date: 2025-12-04
-- WARNING: This will delete all route and schedule data!

-- Step 1: Delete all route stops (must delete first due to foreign key constraints)
DELETE FROM route_stops;

-- Step 2: Delete all routes
DELETE FROM routes;

-- Step 3: Delete all schedules
DELETE FROM schedules;

-- Step 4: Verify deletion - Show counts
SELECT 
    (SELECT COUNT(*) FROM routes) as remaining_routes,
    (SELECT COUNT(*) FROM route_stops) as remaining_route_stops,
    (SELECT COUNT(*) FROM schedules) as remaining_schedules;

-- Notes:
-- 1. Run this script when you want to clear all route and schedule data
-- 2. After running this, you can create new routes from the web interface
-- 3. Make sure to test the synchronization of completed collection results
