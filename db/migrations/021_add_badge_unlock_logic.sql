-- EcoCheck - Add Badge Unlock Logic
-- Automatically check and unlock badges when users meet criteria
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- FUNCTION: Check and unlock badges for a user
-- ============================================================================

CREATE OR REPLACE FUNCTION check_and_unlock_badges(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_user_stats RECORD;
    v_badge RECORD;
    v_criteria JSONB;
    v_meets_criteria BOOLEAN;
    v_already_unlocked BOOLEAN;
BEGIN
    -- Get user statistics
    SELECT 
        COALESCE(up.points, 0) as points,
        COALESCE(up.level, 1) as level,
        COALESCE(up.total_checkins, 0) as total_checkins,
        COALESCE(up.total_recyclable, 0) as total_recyclable,
        COALESCE(up.total_bulky, 0) as total_bulky,
        COALESCE(up.streak_days, 0) as streak_days,
        COALESCE((
            SELECT COUNT(*) 
            FROM checkins c 
            WHERE c.user_id = p_user_id 
            AND EXTRACT(HOUR FROM c.created_at) < 7
        ), 0) as early_checkins,
        COALESCE((
            SELECT COUNT(*) 
            FROM checkins c 
            WHERE c.user_id = p_user_id 
            AND EXTRACT(HOUR FROM c.created_at) >= 22
        ), 0) as late_checkins
    INTO v_user_stats
    FROM user_points up
    WHERE up.user_id = p_user_id;

    -- If user doesn't have user_points entry, create one
    IF v_user_stats IS NULL THEN
        INSERT INTO user_points (user_id, points, level, total_checkins)
        VALUES (p_user_id, 0, 1, 0)
        ON CONFLICT (user_id) DO NOTHING;
        
        SELECT 
            COALESCE(up.points, 0) as points,
            COALESCE(up.level, 1) as level,
            COALESCE(up.total_checkins, 0) as total_checkins,
            COALESCE(up.total_recyclable, 0) as total_recyclable,
            COALESCE(up.total_bulky, 0) as total_bulky,
            COALESCE(up.streak_days, 0) as streak_days,
            COALESCE((
                SELECT COUNT(*) 
                FROM checkins c 
                WHERE c.user_id = p_user_id 
                AND EXTRACT(HOUR FROM c.created_at) < 7
            ), 0) as early_checkins,
            COALESCE((
                SELECT COUNT(*) 
                FROM checkins c 
                WHERE c.user_id = p_user_id 
                AND EXTRACT(HOUR FROM c.created_at) >= 22
            ), 0) as late_checkins
        INTO v_user_stats
        FROM user_points up
        WHERE up.user_id = p_user_id;
    END IF;

    -- Check all active badges
    FOR v_badge IN 
        SELECT id, code, name, criteria, points_reward
        FROM badges
        WHERE active = true
    LOOP
        v_criteria := v_badge.criteria;
        v_meets_criteria := false;
        
        -- Check if user already has this badge
        SELECT EXISTS(
            SELECT 1 FROM user_badges 
            WHERE user_id = p_user_id AND badge_id = v_badge.id
        ) INTO v_already_unlocked;
        
        IF NOT v_already_unlocked THEN
            -- Check criteria based on badge type
            IF v_criteria ? 'min_checkins' THEN
                v_meets_criteria := v_user_stats.total_checkins >= (v_criteria->>'min_checkins')::INT;
            ELSIF v_criteria ? 'min_recyclable' THEN
                v_meets_criteria := v_user_stats.total_recyclable >= (v_criteria->>'min_recyclable')::INT;
            ELSIF v_criteria ? 'min_bulky' THEN
                v_meets_criteria := v_user_stats.total_bulky >= (v_criteria->>'min_bulky')::INT;
            ELSIF v_criteria ? 'min_streak' THEN
                v_meets_criteria := v_user_stats.streak_days >= (v_criteria->>'min_streak')::INT;
            ELSIF v_criteria ? 'min_early_checkins' THEN
                v_meets_criteria := v_user_stats.early_checkins >= (v_criteria->>'min_early_checkins')::INT;
            ELSIF v_criteria ? 'min_late_checkins' THEN
                v_meets_criteria := v_user_stats.late_checkins >= (v_criteria->>'min_late_checkins')::INT;
            ELSIF v_criteria ? 'min_level' AND v_criteria ? 'min_points' THEN
                v_meets_criteria := v_user_stats.level >= (v_criteria->>'min_level')::INT 
                    AND v_user_stats.points >= (v_criteria->>'min_points')::INT;
            ELSIF v_criteria ? 'min_level' THEN
                v_meets_criteria := v_user_stats.level >= (v_criteria->>'min_level')::INT;
            ELSIF v_criteria ? 'min_points' THEN
                v_meets_criteria := v_user_stats.points >= (v_criteria->>'min_points')::INT;
            END IF;
            
            -- Unlock badge if criteria met
            IF v_meets_criteria THEN
                INSERT INTO user_badges (user_id, badge_id, earned_at)
                VALUES (p_user_id, v_badge.id, NOW())
                ON CONFLICT (user_id, badge_id) DO NOTHING;
                
                -- Award points if badge has points reward
                IF v_badge.points_reward > 0 THEN
                    INSERT INTO point_transactions (user_id, points, type, reason, reference_id, reference_type)
                    VALUES (p_user_id, v_badge.points_reward, 'bonus', 'Badge reward: ' || v_badge.name, v_badge.id, 'badge');
                    
                    UPDATE user_points
                    SET points = points + v_badge.points_reward,
                        level = calculate_level_from_points(points + v_badge.points_reward),
                        updated_at = NOW()
                    WHERE user_id = p_user_id;
                END IF;
            END IF;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- UPDATE TRIGGER: Check badges after points update
-- ============================================================================

CREATE OR REPLACE FUNCTION award_points_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    points_to_award INT := 10;
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

    -- Check and unlock badges
    PERFORM check_and_unlock_badges(NEW.user_id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- RECALCULATE BADGES FOR ALL USERS
-- ============================================================================

-- Check and unlock badges for all existing users
DO $$
DECLARE
    v_user_id UUID;
BEGIN
    FOR v_user_id IN SELECT id FROM users WHERE status = 'active'
    LOOP
        PERFORM check_and_unlock_badges(v_user_id);
    END LOOP;
END $$;

-- Success message
SELECT 'Badge unlock logic added and badges recalculated for all users!' AS message;
