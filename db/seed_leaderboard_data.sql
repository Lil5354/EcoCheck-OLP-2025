-- ============================================================================
-- SEED LEADERBOARD DATA
-- Tạo dữ liệu xếp hạng cho user_points table
-- ============================================================================

-- Xóa dữ liệu cũ (chỉ xóa dữ liệu, không xóa cấu trúc)
DELETE FROM user_points;

-- Lấy danh sách user_id từ bảng users (citizen)
DO $$
DECLARE
    user_record RECORD;
    random_points INTEGER;
    random_level INTEGER;
    random_streak INTEGER;
    random_checkins INTEGER;
BEGIN
    FOR user_record IN 
        SELECT id FROM users WHERE role = 'citizen' AND status = 'active'
    LOOP
        -- Tạo điểm ngẫu nhiên từ 0-5000
        random_points := floor(random() * 5000)::INTEGER;
        
        -- Tính level dựa trên điểm (mỗi 500 điểm = 1 level)
        random_level := LEAST(floor(random_points / 500.0) + 1, 15)::INTEGER;
        
        -- Streak ngẫu nhiên 0-30 ngày
        random_streak := floor(random() * 30)::INTEGER;
        
        -- Checkins ngẫu nhiên 0-100
        random_checkins := floor(random() * 100)::INTEGER;
        
        INSERT INTO user_points (
            user_id, 
            points, 
            level, 
            total_checkins,
            total_recyclable,
            total_bulky,
            streak_days, 
            last_checkin_date,
            created_at, 
            updated_at
        )
        VALUES (
            user_record.id,
            random_points,
            random_level,
            random_checkins,
            floor(random() * 50)::INTEGER, -- recyclable
            floor(random() * 20)::INTEGER, -- bulky
            random_streak,
            NOW()::DATE - floor(random() * 7)::INTEGER, -- last checkin trong 7 ngày
            NOW() - (random() * INTERVAL '30 days'),
            NOW()
        );
    END LOOP;
    
    RAISE NOTICE 'Seeded user_points for all active citizens';
END $$;

-- Thêm một số user nổi bật với điểm cao
UPDATE user_points 
SET points = 4800, level = 10, streak_days = 28, total_checkins = 96
WHERE user_id = (SELECT id FROM users WHERE phone = '0911111111' LIMIT 1);

UPDATE user_points 
SET points = 4200, level = 9, streak_days = 22, total_checkins = 84
WHERE user_id = (SELECT id FROM users WHERE phone = '0922222222' LIMIT 1);

UPDATE user_points 
SET points = 3800, level = 8, streak_days = 18, total_checkins = 76
WHERE user_id = (SELECT id FROM users WHERE phone = '0933333333' LIMIT 1);

UPDATE user_points 
SET points = 3200, level = 7, streak_days = 15, total_checkins = 64
WHERE user_id = (SELECT id FROM users WHERE phone = '0944444444' LIMIT 1);

UPDATE user_points 
SET points = 2800, level = 6, streak_days = 12, total_checkins = 56
WHERE user_id = (SELECT id FROM users WHERE phone = '0955555555' LIMIT 1);

-- Hiển thị top 10
SELECT 
    u.profile->>'name' as name,
    u.phone,
    up.points,
    up.level,
    up.streak_days,
    up.total_checkins,
    ROW_NUMBER() OVER (ORDER BY up.points DESC) as rank
FROM user_points up
JOIN users u ON u.id = up.user_id
ORDER BY up.points DESC
LIMIT 10;

-- Thống kê
SELECT 
    COUNT(*) as total_users,
    AVG(points)::INTEGER as avg_points,
    MAX(points) as max_points,
    MIN(points) as min_points,
    AVG(level)::NUMERIC(10,2) as avg_level,
    SUM(total_checkins) as total_checkins_all
FROM user_points;
