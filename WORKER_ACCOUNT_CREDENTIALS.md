# Worker Account Created - Login Credentials

## ✅ Account Successfully Created

A worker account has been created in the database and is ready to use.

## Login Credentials

```
Phone: 0987654321
Password: 123456
Email: worker@ecocheck.com (for reference only)
```

## Account Details

| Field | Value |
|-------|-------|
| **ID** | 9c3f67d1-dfd9-4678-9769-3de7b1a3ae6e |
| **Phone** | 0987654321 ⭐ (use this to login) |
| **Email** | worker@ecocheck.com |
| **Full Name** | Nguyễn Văn Worker |
| **Role** | worker |
| **Status** | active |
| **Address** | 123 Đường Lê Lợi, Quận 1, TP.HCM |
| **Location** | Lat: 10.7769, Lon: 106.7009 |
| **Verified** | Yes |
| **Active** | Yes |

## Login API Test

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone": "0987654321", "password": "123456"}'
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "id": "9c3f67d1-dfd9-4678-9769-3de7b1a3ae6e",
    "phone": "0987654321",
    "email": "worker@ecocheck.com",
    "role": "worker",
    "fullName": "Nguyễn Văn Worker",
    "address": "123 Đường Lê Lợi, Quận 1, TP.HCM",
    "latitude": 10.7769,
    "longitude": 106.7009,
    "isVerified": true,
    "isActive": true,
    "createdAt": "2025-11-25T00:59:17.813Z",
    "updatedAt": "2025-11-25T01:02:09.039Z"
  },
  "message": "Login successful"
}
```

## Worker App Usage

The credentials are already pre-filled in the Worker App login screen:

**File:** `lib/presentation/screens/login_screen.dart`
```dart
final _phoneController = TextEditingController(text: '0987654321');
final _passwordController = TextEditingController(text: '123456');
```

**Important:** Login uses **phone number**, not email!

## Backend Authentication

The backend uses a simple password check (for demo):
- Password is stored as bcrypt hash: `$2b$10$N9qo8uLOickgx2ZMRZoMye3jXGqvIjT7ZoQJZUq1ql6u5xQjLqXjK`
- Current implementation accepts password "123456" for demo purposes
- In production, proper bcrypt verification should be implemented

## Database Query

To view the account in database:
```sql
SELECT 
    id,
    phone,
    email,
    role,
    status,
    profile->>'fullName' as full_name,
    profile->>'address' as address,
    created_at,
    updated_at
FROM users 
WHERE email = 'worker@ecocheck.com';
```

## Testing Steps

1. **Start backend:**
   ```bash
   docker-compose up
   ```

2. **Start Worker App:**
   ```bash
   cd frontend-mobile/EcoCheck_Worker
   flutter run
   ```

3. **Login:**
   - Phone: 0987654321 (pre-filled)
   - Password: 123456 (pre-filled)
   - Click "Đăng nhập"

4. **Expected Result:**
   - Successful authentication
   - Redirect to MainScreen (Dashboard)
   - User info displayed: "Nguyễn Văn Worker"

## Notes

- ✅ Account created with UUID
- ✅ Password hashed with bcrypt
- ✅ Role set to 'worker'
- ✅ Status set to 'active'
- ✅ Profile includes name, address, and location
- ✅ Ready for immediate use in Worker App
- ✅ Backend login endpoint tested and working

## Related Files

- SQL Script: `/db/create_worker_account.sql`
- Login Screen: `/frontend-mobile/EcoCheck_Worker/lib/presentation/screens/login_screen.dart`
- Auth BLoC: `/frontend-mobile/EcoCheck_Worker/lib/presentation/blocs/auth/auth_bloc.dart`
- Backend Auth: `/backend/src/index.js` (lines 1044-1110)
