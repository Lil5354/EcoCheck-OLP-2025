-- EcoCheck - Seed Badges and Gamification Data
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- BADGES (Huy hiệu)
-- ============================================================================

INSERT INTO badges (code, name, description, icon_url, criteria, points_reward, rarity, active) VALUES
  -- Beginner Badges
  (
    'first_checkin',
    'Bước Đầu Xanh',
    'Hoàn thành check-in đầu tiên',
    '/badges/first_checkin.png',
    '{"min_checkins": 1}'::jsonb,
    50,
    'common',
    true
  ),
  (
    'eco_starter',
    'Người Mới Bắt Đầu',
    'Hoàn thành 10 check-in',
    '/badges/eco_starter.png',
    '{"min_checkins": 10}'::jsonb,
    100,
    'common',
    true
  ),
  
  -- Recycling Badges
  (
    'recycler_bronze',
    'Tái Chế Đồng',
    'Check-in 5 lần rác tái chế',
    '/badges/recycler_bronze.png',
    '{"min_recyclable": 5}'::jsonb,
    150,
    'common',
    true
  ),
  (
    'recycler_silver',
    'Tái Chế Bạc',
    'Check-in 20 lần rác tái chế',
    '/badges/recycler_silver.png',
    '{"min_recyclable": 20}'::jsonb,
    300,
    'rare',
    true
  ),
  (
    'recycler_gold',
    'Tái Chế Vàng',
    'Check-in 50 lần rác tái chế',
    '/badges/recycler_gold.png',
    '{"min_recyclable": 50}'::jsonb,
    500,
    'epic',
    true
  ),
  (
    'recycler_platinum',
    'Tái Chế Bạch Kim',
    'Check-in 100 lần rác tái chế',
    '/badges/recycler_platinum.png',
    '{"min_recyclable": 100}'::jsonb,
    1000,
    'legendary',
    true
  ),
  
  -- Streak Badges
  (
    'streak_7',
    'Tuần Xanh',
    'Check-in liên tục 7 ngày',
    '/badges/streak_7.png',
    '{"min_streak": 7}'::jsonb,
    200,
    'rare',
    true
  ),
  (
    'streak_30',
    'Tháng Xanh',
    'Check-in liên tục 30 ngày',
    '/badges/streak_30.png',
    '{"min_streak": 30}'::jsonb,
    500,
    'epic',
    true
  ),
  (
    'streak_100',
    'Chiến Binh Xanh',
    'Check-in liên tục 100 ngày',
    '/badges/streak_100.png',
    '{"min_streak": 100}'::jsonb,
    1500,
    'legendary',
    true
  ),
  
  -- Volume Badges
  (
    'eco_warrior',
    'Chiến Sĩ Môi Trường',
    'Hoàn thành 100 check-in',
    '/badges/eco_warrior.png',
    '{"min_checkins": 100}'::jsonb,
    500,
    'epic',
    true
  ),
  (
    'eco_champion',
    'Nhà Vô Địch Xanh',
    'Hoàn thành 500 check-in',
    '/badges/eco_champion.png',
    '{"min_checkins": 500}'::jsonb,
    2000,
    'legendary',
    true
  ),
  
  -- Special Badges
  (
    'bulky_master',
    'Chuyên Gia Rác Cồng Kềnh',
    'Check-in 10 lần rác cồng kềnh',
    '/badges/bulky_master.png',
    '{"min_bulky": 10}'::jsonb,
    400,
    'rare',
    true
  ),
  (
    'early_bird',
    'Chim Sớm',
    'Check-in trước 7h sáng 10 lần',
    '/badges/early_bird.png',
    '{"min_early_checkins": 10, "before_hour": 7}'::jsonb,
    250,
    'rare',
    true
  ),
  (
    'night_owl',
    'Cú Đêm',
    'Check-in sau 10h tối 10 lần',
    '/badges/night_owl.png',
    '{"min_late_checkins": 10, "after_hour": 22}'::jsonb,
    250,
    'rare',
    true
  ),
  (
    'community_hero',
    'Anh Hùng Cộng Đồng',
    'Báo cáo 5 sự cố',
    '/badges/community_hero.png',
    '{"min_incidents": 5}'::jsonb,
    300,
    'rare',
    true
  ),
  (
    'perfect_sorter',
    'Phân Loại Hoàn Hảo',
    'Có 50 check-in được xác thực chính xác',
    '/badges/perfect_sorter.png',
    '{"min_verified_checkins": 50}'::jsonb,
    600,
    'epic',
    true
  ),
  (
    'eco_legend',
    'Huyền Thoại Xanh',
    'Đạt level 5 và có 1000 điểm',
    '/badges/eco_legend.png',
    '{"min_level": 5, "min_points": 1000}'::jsonb,
    2500,
    'legendary',
    true
  )
ON CONFLICT (code) DO NOTHING;

-- Success message
SELECT 'Badges seeded successfully!' AS message;

