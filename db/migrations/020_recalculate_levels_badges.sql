-- EcoCheck - Recalculate User Levels and Unlock Badges
-- Updates level calculation logic and triggers badge checking
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- UPDATE LEVEL CALCULATION LOGIC
-- ============================================================================

-- Function to calculate level from points (updated logic)
CREATE OR REPLACE FUNCTION calculate_level_from_points(points INT)
RETURNS INT AS $$
BEGIN
  IF points >= 5000 THEN RETURN 10;
  ELSIF points >= 2500 THEN RETURN 9;
  ELSIF points >= 2000 THEN RETURN 8;
  ELSIF points >= 1500 THEN RETURN 7;
  ELSIF points >= 1000 THEN RETURN 6;
  ELSIF points >= 500 THEN RETURN 5;
  ELSIF points >= 250 THEN RETURN 4;
  ELSIF points >= 200 THEN RETURN 3;
  ELSIF points >= 50 THEN RETURN 2;
  ELSE RETURN 1;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Update award_points_on_checkin trigger to use new level calculation
CREATE OR REPLACE FUNCTION award_points_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    points_to_award INT := 10; -- Base points
    current_date DATE := CURRENT_DATE;
    new_points INT;
    new_level INT;
BEGIN
    -- Calculate points based on waste type
    CASE NEW.waste_type
        WHEN 'recyclable' THEN points_to_award := 20;
        WHEN 'bulky' THEN points_to_award := 30;
        WHEN 'hazardous' THEN points_to_award := 25;
        WHEN 'organic' THEN points_to_award := 15;
        ELSE points_to_award := 10;
    END CASE;

    -- Insert or update user_points
    INSERT INTO user_points (user_id, points, total_checkins, last_checkin_date)
    VALUES (NEW.user_id, points_to_award, 1, current_date)
    ON CONFLICT (user_id) DO UPDATE
    SET
        points = user_points.points + points_to_award,
        total_checkins = user_points.total_checkins + 1,
        total_recyclable = CASE WHEN NEW.waste_type = 'recyclable' THEN user_points.total_recyclable + 1 ELSE user_points.total_recyclable END,
        total_bulky = CASE WHEN NEW.waste_type = 'bulky' THEN user_points.total_bulky + 1 ELSE user_points.total_bulky END,
        streak_days = CASE
            WHEN user_points.last_checkin_date = current_date - INTERVAL '1 day' THEN user_points.streak_days + 1
            WHEN user_points.last_checkin_date = current_date THEN user_points.streak_days
            ELSE 1
        END,
        last_checkin_date = current_date;

    -- Get updated points to calculate level
    SELECT points INTO new_points FROM user_points WHERE user_id = NEW.user_id;
    new_level := calculate_level_from_points(new_points);

    -- Update level
    UPDATE user_points SET level = new_level WHERE user_id = NEW.user_id;

    -- Record transaction
    INSERT INTO point_transactions (user_id, points, type, reason, reference_id, reference_type)
    VALUES (NEW.user_id, points_to_award, 'earn', 'Check-in ' || NEW.waste_type, NEW.id, 'checkin');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RECALCULATE LEVELS FOR ALL USERS
-- ============================================================================

-- Update all user levels based on current points
UPDATE user_points 
SET level = calculate_level_from_points(points),
    updated_at = NOW();

-- Success message
SELECT 'Levels recalculated successfully! All users now have correct levels based on their points.' AS message;

