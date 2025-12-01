-- ============================================================================
-- SEED DATA FOR GROUPS, GROUP_MEMBERS AND ENHANCED PERSONNEL
-- ============================================================================
-- Description: Complete seed data for worker groups and team management
-- Date: 2025-12-01

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. UPDATE EXISTING PERSONNEL WITH MORE DETAILS
-- ============================================================================

-- Add email and update existing personnel
UPDATE personnel SET 
  email = 'tranvanbinh@ecocheck.vn',
  meta = jsonb_set(
    COALESCE(meta, '{}'),
    '{skills}',
    '["driving", "compactor_operation"]'::jsonb
  )
WHERE name = 'Trần Văn Bình';

UPDATE personnel SET 
  email = 'levancuong@ecocheck.vn',
  meta = jsonb_set(
    COALESCE(meta, '{}'),
    '{skills}',
    '["driving", "mini_truck"]'::jsonb
  )
WHERE name = 'Lê Văn Cường';

UPDATE personnel SET 
  email = 'phamthidung@ecocheck.vn',
  role = 'collector',
  meta = jsonb_set(
    COALESCE(meta, '{}'),
    '{skills}',
    '["waste_sorting", "collection"]'::jsonb
  )
WHERE name = 'Phạm Thị Dung';

-- ============================================================================
-- 2. INSERT ADDITIONAL PERSONNEL FOR COMPLETE GROUPS
-- ============================================================================

INSERT INTO personnel (id, name, role, phone, email, status, depot_id, meta, hired_at) VALUES
  -- Quận 1 Team
  (uuid_generate_v4(), 'Nguyễn Văn Hùng', 'driver', '0907111111', 'nguyenvanhung@ecocheck.vn', 'active', 
   (SELECT id FROM depots WHERE name LIKE '%Quận 1%' LIMIT 1),
   '{"skills": ["driving", "compactor_operation"], "license": "C", "experience_years": 5}'::jsonb,
   NOW() - INTERVAL '2 years'),
   
  (uuid_generate_v4(), 'Trần Thị Mai', 'collector', '0907222222', 'tranthimai@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Quận 1%' LIMIT 1),
   '{"skills": ["waste_sorting", "collection"], "experience_years": 3}'::jsonb,
   NOW() - INTERVAL '1 year'),
   
  (uuid_generate_v4(), 'Lê Văn Tùng', 'collector', '0907333333', 'levantung@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Quận 1%' LIMIT 1),
   '{"skills": ["collection", "customer_service"], "experience_years": 2}'::jsonb,
   NOW() - INTERVAL '1 year'),

  -- Quận 3 Team
  (uuid_generate_v4(), 'Phạm Văn Nam', 'driver', '0908111111', 'phamvannam@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Quận 3%' LIMIT 1),
   '{"skills": ["driving", "compactor_operation"], "license": "C", "experience_years": 4}'::jsonb,
   NOW() - INTERVAL '1.5 years'),
   
  (uuid_generate_v4(), 'Võ Thị Lan', 'collector', '0908222222', 'vothilan@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Quận 3%' LIMIT 1),
   '{"skills": ["waste_sorting", "collection"], "experience_years": 2}'::jsonb,
   NOW() - INTERVAL '1 year'),
   
  (uuid_generate_v4(), 'Hoàng Văn Kiên', 'collector', '0908333333', 'hoangvankien@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Quận 3%' LIMIT 1),
   '{"skills": ["collection", "recycling"], "experience_years": 3}'::jsonb,
   NOW() - INTERVAL '1 year'),

  -- Bình Thạnh Team  
  (uuid_generate_v4(), 'Nguyễn Văn Đức', 'driver', '0909111111', 'nguyenvanduc@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1),
   '{"skills": ["driving", "mini_truck"], "license": "B2", "experience_years": 6}'::jsonb,
   NOW() - INTERVAL '3 years'),
   
  (uuid_generate_v4(), 'Trần Thị Hoa', 'collector', '0909222222', 'tranthihoa@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1),
   '{"skills": ["collection", "waste_sorting"], "experience_years": 2}'::jsonb,
   NOW() - INTERVAL '1 year'),
   
  (uuid_generate_v4(), 'Lê Văn Minh', 'collector', '0909333333', 'levanminh@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1),
   '{"skills": ["collection", "bulky_waste"], "experience_years": 4}'::jsonb,
   NOW() - INTERVAL '2 years'),

  -- Tân Bình Team
  (uuid_generate_v4(), 'Phạm Văn Tài', 'driver', '0910111111', 'phamvantai@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Tân Bình%' LIMIT 1),
   '{"skills": ["driving", "compactor_operation"], "license": "C", "experience_years": 5}'::jsonb,
   NOW() - INTERVAL '2 years'),
   
  (uuid_generate_v4(), 'Võ Thị Nga', 'collector', '0910222222', 'vothinga@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Tân Bình%' LIMIT 1),
   '{"skills": ["waste_sorting", "collection"], "experience_years": 3}'::jsonb,
   NOW() - INTERVAL '1.5 years'),
   
  (uuid_generate_v4(), 'Hoàng Văn Sơn', 'collector', '0910333333', 'hoangvanson@ecocheck.vn', 'active',
   (SELECT id FROM depots WHERE name LIKE '%Tân Bình%' LIMIT 1),
   '{"skills": ["collection", "customer_service"], "experience_years": 2}'::jsonb,
   NOW() - INTERVAL '1 year');

-- ============================================================================
-- 3. CREATE GROUPS WITH VEHICLES AND DEPOTS
-- ============================================================================

-- Delete test/incomplete groups first
DELETE FROM groups WHERE name IN ('Test Group', 'T01', 'Q301', 'Q101', 'A01');

-- Insert complete groups
INSERT INTO groups (id, name, code, description, vehicle_id, depot_id, operating_area, status, meta) VALUES
  -- Quận 1 Group
  (uuid_generate_v4(), 'Nhóm Thu Gom Q1-A', 'Q1A-001', 'Nhóm thu gom khu vực Quận 1 - Ca sáng',
   'VH001',
   (SELECT id FROM depots WHERE name LIKE '%Quận 1%' LIMIT 1),
   'Quận 1',
   'active',
   '{"shift": "morning", "coverage_area": ["Phường Bến Nghé", "Phường Bến Thành"], "capacity": "5000kg"}'::jsonb),

  -- Quận 3 Group  
  (uuid_generate_v4(), 'Nhóm Thu Gom Q3-A', 'Q3A-001', 'Nhóm thu gom khu vực Quận 3 - Ca sáng',
   'VH002',
   (SELECT id FROM depots WHERE name LIKE '%Quận 3%' LIMIT 1),
   'Quận 3',
   'active',
   '{"shift": "morning", "coverage_area": ["Phường 1", "Phường 2"], "capacity": "5000kg"}'::jsonb),

  -- Bình Thạnh Group
  (uuid_generate_v4(), 'Nhóm Thu Gom BT-A', 'BTA-001', 'Nhóm thu gom khu vực Bình Thạnh - Ca sáng',
   'VH003',
   (SELECT id FROM depots WHERE name LIKE '%Bình Thạnh%' LIMIT 1),
   'Bình Thạnh',
   'active',
   '{"shift": "morning", "coverage_area": ["Phường 1", "Phường 2"], "capacity": "2000kg"}'::jsonb),

  -- Tân Bình Group
  (uuid_generate_v4(), 'Nhóm Thu Gom TB-A', 'TBA-001', 'Nhóm thu gom khu vực Tân Bình - Ca sáng',
   'VH005',
   (SELECT id FROM depots WHERE name LIKE '%Tân Bình%' LIMIT 1),
   'Tân Bình',
   'active',
   '{"shift": "morning", "coverage_area": ["Phường 1", "Phường 2"], "capacity": "5000kg"}'::jsonb);

-- ============================================================================
-- 4. ASSIGN PERSONNEL TO GROUPS (GROUP_MEMBERS)
-- ============================================================================

-- Quận 1 Group - Leader + 2 Collectors
INSERT INTO group_members (group_id, personnel_id, role_in_group, status)
SELECT 
  g.id as group_id,
  p.id as personnel_id,
  CASE 
    WHEN p.role = 'driver' THEN 'leader'
    ELSE 'member'
  END as role_in_group,
  'active' as status
FROM groups g
CROSS JOIN personnel p
WHERE g.name = 'Nhóm Thu Gom Q1-A'
  AND p.name IN ('Nguyễn Văn Hùng', 'Trần Thị Mai', 'Lê Văn Tùng')
  AND p.status = 'active';

-- Quận 3 Group - Leader + 2 Collectors  
INSERT INTO group_members (group_id, personnel_id, role_in_group, status)
SELECT 
  g.id as group_id,
  p.id as personnel_id,
  CASE 
    WHEN p.role = 'driver' THEN 'leader'
    ELSE 'member'
  END as role_in_group,
  'active' as status
FROM groups g
CROSS JOIN personnel p
WHERE g.name = 'Nhóm Thu Gom Q3-A'
  AND p.name IN ('Phạm Văn Nam', 'Võ Thị Lan', 'Hoàng Văn Kiên')
  AND p.status = 'active';

-- Bình Thạnh Group - Leader + 2 Collectors
INSERT INTO group_members (group_id, personnel_id, role_in_group, status)
SELECT 
  g.id as group_id,
  p.id as personnel_id,
  CASE 
    WHEN p.role = 'driver' THEN 'leader'
    ELSE 'member'
  END as role_in_group,
  'active' as status
FROM groups g
CROSS JOIN personnel p
WHERE g.name = 'Nhóm Thu Gom BT-A'
  AND p.name IN ('Nguyễn Văn Đức', 'Trần Thị Hoa', 'Lê Văn Minh')
  AND p.status = 'active';

-- Tân Bình Group - Leader + 2 Collectors
INSERT INTO group_members (group_id, personnel_id, role_in_group, status)
SELECT 
  g.id as group_id,
  p.id as personnel_id,
  CASE 
    WHEN p.role = 'driver' THEN 'leader'
    ELSE 'member'
  END as role_in_group,
  'active' as status
FROM groups g
CROSS JOIN personnel p
WHERE g.name = 'Nhóm Thu Gom TB-A'
  AND p.name IN ('Phạm Văn Tài', 'Võ Thị Nga', 'Hoàng Văn Sơn')
  AND p.status = 'active';

-- ============================================================================
-- 5. UPDATE VEHICLES STATUS
-- ============================================================================

-- Set vehicles to in_use status (assigned to groups)
UPDATE vehicles SET status = 'in_use' 
WHERE id IN ('VH001', 'VH002', 'VH003', 'VH005');

-- Keep VH004 available for ad-hoc tasks
UPDATE vehicles SET status = 'available' WHERE id = 'VH004';

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check groups summary
SELECT 
  'Groups Summary' as info,
  COUNT(*) as total_groups,
  COUNT(*) FILTER (WHERE status = 'active') as active_groups
FROM groups;

-- Check group members
SELECT 
  g.name as group_name,
  COUNT(gm.id) as member_count,
  COUNT(*) FILTER (WHERE gm.role_in_group = 'leader') as leaders,
  COUNT(*) FILTER (WHERE gm.role_in_group = 'member') as members
FROM groups g
LEFT JOIN group_members gm ON g.id = gm.group_id AND gm.status = 'active'
WHERE g.status = 'active'
GROUP BY g.id, g.name
ORDER BY g.name;

-- Check personnel assignment
SELECT 
  'Personnel Assignment' as info,
  COUNT(*) as total_personnel,
  COUNT(*) FILTER (WHERE id IN (SELECT personnel_id FROM group_members WHERE status = 'active')) as assigned,
  COUNT(*) FILTER (WHERE id NOT IN (SELECT personnel_id FROM group_members WHERE status = 'active')) as unassigned
FROM personnel 
WHERE status = 'active' AND role IN ('driver', 'collector');
