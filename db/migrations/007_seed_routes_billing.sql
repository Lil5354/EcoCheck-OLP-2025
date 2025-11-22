-- EcoCheck - Seed Routes and Billing Data
-- MIT License - Copyright (c) 2025 Lil5354

-- ============================================================================
-- ROUTES (Lộ trình thu gom)
-- ============================================================================

-- Active route (in progress)
INSERT INTO routes (id, vehicle_id, depot_id, dump_id, driver_id, collector_id, start_at, status, planned_distance_km, planned_duration_min, meta) VALUES
  (uuid_generate_v4(), 
   'VH003',
   (SELECT id FROM depots LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'collector' LIMIT 1),
   NOW() - INTERVAL '2 hours', 
   'in_progress',
   25.5,
   180,
   '{"route_type": "household", "priority": "normal"}'::jsonb);

-- Planned routes for tonight
INSERT INTO routes (id, vehicle_id, depot_id, dump_id, driver_id, collector_id, start_at, status, planned_distance_km, planned_duration_min, meta) VALUES
  (uuid_generate_v4(), 
   'VH001',
   (SELECT id FROM depots LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' OFFSET 1 LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'collector' OFFSET 1 LIMIT 1),
   NOW() + INTERVAL '4 hours', 
   'planned',
   30.2,
   210,
   '{"route_type": "household", "priority": "high"}'::jsonb),
  
  (uuid_generate_v4(), 
   'VH002',
   (SELECT id FROM depots OFFSET 1 LIMIT 1),
   (SELECT id FROM dumps OFFSET 1 LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' OFFSET 2 LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'collector' OFFSET 2 LIMIT 1),
   NOW() + INTERVAL '5 hours', 
   'planned',
   28.7,
   195,
   '{"route_type": "household", "priority": "normal"}'::jsonb),
  
  (uuid_generate_v4(), 
   'VH011',
   (SELECT id FROM depots OFFSET 2 LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' OFFSET 3 LIMIT 1),
   NULL,
   NOW() + INTERVAL '6 hours', 
   'planned',
   18.3,
   150,
   '{"route_type": "bulky", "priority": "normal"}'::jsonb);

-- Completed routes (historical)
INSERT INTO routes (id, vehicle_id, depot_id, dump_id, driver_id, collector_id, start_at, end_at, status, 
                    planned_distance_km, actual_distance_km, planned_duration_min, actual_duration_min, optimization_score, meta) VALUES
  (uuid_generate_v4(), 
   'VH001',
   (SELECT id FROM depots LIMIT 1),
   (SELECT id FROM dumps LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'collector' LIMIT 1),
   NOW() - INTERVAL '1 day' - INTERVAL '8 hours',
   NOW() - INTERVAL '1 day' - INTERVAL '5 hours',
   'completed',
   32.5, 30.8, 200, 185, 0.92,
   '{"route_type": "household", "priority": "normal", "fuel_used_liters": 8.5}'::jsonb),
  
  (uuid_generate_v4(), 
   'VH002',
   (SELECT id FROM depots OFFSET 1 LIMIT 1),
   (SELECT id FROM dumps OFFSET 1 LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'driver' OFFSET 1 LIMIT 1),
   (SELECT id FROM personnel WHERE role = 'collector' OFFSET 1 LIMIT 1),
   NOW() - INTERVAL '2 days' - INTERVAL '7 hours',
   NOW() - INTERVAL '2 days' - INTERVAL '4 hours',
   'completed',
   28.3, 27.5, 180, 175, 0.95,
   '{"route_type": "household", "priority": "high", "fuel_used_liters": 7.2}'::jsonb);

-- ============================================================================
-- ROUTE STOPS (Điểm dừng trong lộ trình)
-- ============================================================================

-- Stops for the active route
INSERT INTO route_stops (id, route_id, point_id, seq, planned_eta, status, actual_arrival_at, collected_waste_type, collected_weight_kg) VALUES
  (uuid_generate_v4(), 
   (SELECT id FROM routes WHERE status = 'in_progress' LIMIT 1),
   (SELECT id FROM points WHERE ghost = false LIMIT 1),
   1, NOW() - INTERVAL '1 hour 50 minutes', 'completed', NOW() - INTERVAL '1 hour 52 minutes', 'household', 45.5),
  
  (uuid_generate_v4(), 
   (SELECT id FROM routes WHERE status = 'in_progress' LIMIT 1),
   (SELECT id FROM points WHERE ghost = false OFFSET 2 LIMIT 1),
   2, NOW() - INTERVAL '1 hour 30 minutes', 'completed', NOW() - INTERVAL '1 hour 28 minutes', 'household', 52.3),
  
  (uuid_generate_v4(), 
   (SELECT id FROM routes WHERE status = 'in_progress' LIMIT 1),
   (SELECT id FROM points WHERE ghost = false OFFSET 5 LIMIT 1),
   3, NOW() - INTERVAL '1 hour 10 minutes', 'completed', NOW() - INTERVAL '1 hour 8 minutes', 'household', 38.7),
  
  (uuid_generate_v4(), 
   (SELECT id FROM routes WHERE status = 'in_progress' LIMIT 1),
   (SELECT id FROM points WHERE ghost = false OFFSET 9 LIMIT 1),
   4, NOW() - INTERVAL '50 minutes', 'pending', NULL, NULL, NULL),
  
  (uuid_generate_v4(), 
   (SELECT id FROM routes WHERE status = 'in_progress' LIMIT 1),
   (SELECT id FROM points WHERE ghost = false OFFSET 11 LIMIT 1),
   5, NOW() - INTERVAL '30 minutes', 'pending', NULL, NULL, NULL);

-- ============================================================================
-- BILLING CYCLES (Chu kỳ tính phí)
-- ============================================================================

INSERT INTO billing_cycles (id, name, start_date, end_date, status) VALUES
  (uuid_generate_v4(), 'Tháng 1/2025', '2025-01-01', '2025-01-31', 'closed'),
  (uuid_generate_v4(), 'Tháng 2/2025', '2025-02-01', '2025-02-28', 'active'),
  (uuid_generate_v4(), 'Tháng 3/2025', '2025-03-01', '2025-03-31', 'active');

-- ============================================================================
-- USER BILLS (Hóa đơn người dùng)
-- ============================================================================

-- Bills for January 2025 (closed cycle)
INSERT INTO user_bills (id, user_id, billing_cycle_id, total_checkins, total_weight_estimated_kg, 
                        base_fee, variable_fee, discount, total_amount, status, due_date, paid_at, payment_method) VALUES
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0911111111'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 1/2025'),
   15, 112.5, 50000, 33750, 0, 83750, 'paid', '2025-02-15', '2025-02-10', 'bank_transfer'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0922222222'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 1/2025'),
   22, 165.0, 50000, 49500, 5000, 94500, 'paid', '2025-02-15', '2025-02-12', 'e_wallet'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0933333333'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 1/2025'),
   8, 90.0, 50000, 27000, 0, 77000, 'paid', '2025-02-15', '2025-02-08', 'cash'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0944444444'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 1/2025'),
   18, 135.0, 50000, 40500, 0, 90500, 'paid', '2025-02-15', '2025-02-14', 'bank_transfer');

-- Bills for February 2025 (active cycle - pending)
INSERT INTO user_bills (id, user_id, billing_cycle_id, total_checkins, total_weight_estimated_kg, 
                        base_fee, variable_fee, discount, total_amount, status, due_date) VALUES
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0911111111'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 2/2025'),
   3, 22.5, 50000, 6750, 0, 56750, 'pending', '2025-03-15'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0922222222'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 2/2025'),
   5, 37.5, 50000, 11250, 0, 61250, 'pending', '2025-03-15'),
  
  (uuid_generate_v4(),
   (SELECT id FROM users WHERE phone = '0955555555'),
   (SELECT id FROM billing_cycles WHERE name = 'Tháng 2/2025'),
   4, 30.0, 50000, 9000, 0, 59000, 'pending', '2025-03-15');

-- Success message
SELECT 'Routes and billing data seeded successfully!' AS message;

