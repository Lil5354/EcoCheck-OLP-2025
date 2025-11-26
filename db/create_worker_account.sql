-- Create worker account for login
-- Email: worker@ecocheck.com
-- Password: 123456 (hashed with bcrypt)

-- First, check if user exists and delete if necessary (for clean setup)
DELETE FROM users WHERE phone = '0987654321' OR email = 'worker@ecocheck.com';

-- Insert worker account
-- Password: 123456
-- Bcrypt hash: $2b$10$N9qo8uLOickgx2ZMRZoMye3jXGqvIjT7ZoQJZUq1ql6u5xQjLqXjK
INSERT INTO users (
    id,
    phone,
    email,
    password_hash,
    role,
    status,
    profile,
    created_at,
    updated_at
) VALUES (
    gen_random_uuid(),  -- id
    '0987654321',  -- phone
    'worker@ecocheck.com',  -- email
    '$2b$10$N9qo8uLOickgx2ZMRZoMye3jXGqvIjT7ZoQJZUq1ql6u5xQjLqXjK',  -- password_hash for "123456"
    'worker',  -- role
    'active',  -- status
    jsonb_build_object(
        'fullName', 'Nguyễn Văn Worker',
        'address', '123 Đường Lê Lợi, Quận 1, TP.HCM',
        'latitude', 10.7769,
        'longitude', 106.7009,
        'avatarUrl', null,
        'isVerified', true
    ),  -- profile
    NOW(),  -- created_at
    NOW()  -- updated_at
)
ON CONFLICT (phone) DO UPDATE SET
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    role = EXCLUDED.role,
    status = EXCLUDED.status,
    profile = EXCLUDED.profile,
    updated_at = NOW();

-- Verify the account was created
SELECT 
    id,
    phone,
    email,
    role,
    status,
    profile->>'fullName' as full_name,
    profile->>'address' as address,
    created_at
FROM users 
WHERE email = 'worker@ecocheck.com';
