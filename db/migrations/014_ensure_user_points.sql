-- Migration: Ensure all users have gamification records
-- Description: Create user_points records for existing users
-- Version: 014
-- Date: 2025-11-29

-- Insert user_points for users who don't have one yet
INSERT INTO user_points (user_id, points, level, total_checkins, streak_days)
SELECT 
    u.id,
    0 as points,
    1 as level,
    0 as total_checkins,
    0 as streak_days
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM user_points up WHERE up.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

-- Function to auto-create user_points when new user is created
CREATE OR REPLACE FUNCTION create_user_points()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_points (user_id, points, level, total_checkins, streak_days)
    VALUES (NEW.id, 0, 1, 0, 0)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-create user_points
DROP TRIGGER IF EXISTS trigger_create_user_points ON users;
CREATE TRIGGER trigger_create_user_points
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION create_user_points();

-- Migration completed
SELECT 'Migration 014: Ensured user_points for all users' as status;
