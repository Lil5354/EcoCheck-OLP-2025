# EcoCheck API - Code Examples

This document provides practical code examples for integrating with the EcoCheck API in various programming languages and platforms.

## Table of Contents

1. [JavaScript/Node.js](#javascriptnodejs)
2. [Python](#python)
3. [Flutter/Dart](#flutterdart)
4. [cURL](#curl)
5. [Postman Collection](#postman-collection)

---

## JavaScript/Node.js

### Setup

```bash
npm install axios
```

### Authentication

```javascript
const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// Manager Login
async function managerLogin(username, password) {
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      username,
      password
    });
    
    const { token, user } = response.data.data;
    console.log('Login successful:', user);
    return token;
  } catch (error) {
    console.error('Login failed:', error.response?.data);
    throw error;
  }
}

// Worker Login
async function workerLogin(phone, password) {
  try {
    const response = await axios.post(`${BASE_URL}/api/auth/worker/login`, {
      phone,
      password
    });
    
    return response.data.data.token;
  } catch (error) {
    console.error('Worker login failed:', error.response?.data);
    throw error;
  }
}

// Usage
const token = await managerLogin('manager1', 'password123');
```

### Get Schedules

```javascript
async function getSchedules(token, filters = {}) {
  try {
    const response = await axios.get(`${BASE_URL}/api/schedules`, {
      headers: {
        'Authorization': `Bearer ${token}`
      },
      params: filters // { status: 'pending', date: '2025-12-12' }
    });
    
    return response.data.data;
  } catch (error) {
    console.error('Failed to fetch schedules:', error.response?.data);
    throw error;
  }
}

// Usage
const schedules = await getSchedules(token, { status: 'pending' });
console.log('Pending schedules:', schedules);
```

### Create Schedule

```javascript
async function createSchedule(token, scheduleData) {
  try {
    const response = await axios.post(
      `${BASE_URL}/api/schedules`,
      {
        route_name: scheduleData.routeName,
        district: scheduleData.district,
        scheduled_date: scheduleData.date,
        scheduled_time: scheduleData.time,
        assigned_group_id: scheduleData.groupId,
        vehicle_id: scheduleData.vehicleId,
        stops: scheduleData.stops
      },
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    return response.data.data;
  } catch (error) {
    console.error('Failed to create schedule:', error.response?.data);
    throw error;
  }
}

// Usage
const newSchedule = await createSchedule(token, {
  routeName: 'Route District 1 - Morning',
  district: 'District 1',
  date: '2025-12-12',
  time: '06:00:00',
  groupId: 2,
  vehicleId: 5,
  stops: [
    { point_id: 10, sequence_order: 1, estimated_time: '06:15:00' },
    { point_id: 11, sequence_order: 2, estimated_time: '06:30:00' }
  ]
});
```

### Real-time Check-in

```javascript
async function sendCheckIn(userId, location) {
  try {
    const response = await axios.post(`${BASE_URL}/api/rt/checkin`, {
      user_id: userId,
      latitude: location.latitude,
      longitude: location.longitude,
      speed: location.speed || 0,
      heading: location.heading || 0,
      accuracy: location.accuracy || 10
    });
    
    return response.data.data;
  } catch (error) {
    console.error('Check-in failed:', error.response?.data);
    throw error;
  }
}

// Usage - Send location every 30 seconds
setInterval(async () => {
  const location = await getCurrentLocation(); // Your location service
  await sendCheckIn(userId, location);
}, 30000);
```

### Socket.IO Real-time Connection

```javascript
const io = require('socket.io-client');

const socket = io(BASE_URL, {
  transports: ['websocket']
});

socket.on('connect', () => {
  console.log('Connected to server:', socket.id);
  
  // Join a room (e.g., for a specific driver)
  socket.emit('join', `driver:${userId}`);
});

socket.on('route_update', (data) => {
  console.log('Route update received:', data);
  // Update UI with new route status
});

socket.on('alert', (data) => {
  console.log('New alert:', data);
  // Show notification to user
});

socket.on('new_assignment', (data) => {
  console.log('New route assigned:', data);
  // Notify driver of new assignment
});

socket.on('disconnect', () => {
  console.log('Disconnected from server');
});
```

### File Upload

```javascript
const FormData = require('form-data');
const fs = require('fs');

async function uploadImage(filePath) {
  try {
    const form = new FormData();
    form.append('image', fs.createReadStream(filePath));
    
    const response = await axios.post(`${BASE_URL}/api/upload`, form, {
      headers: {
        ...form.getHeaders()
      }
    });
    
    return response.data.data.url;
  } catch (error) {
    console.error('Upload failed:', error.response?.data);
    throw error;
  }
}

// Usage
const imageUrl = await uploadImage('./photo.jpg');
console.log('Image uploaded:', imageUrl);
```

---

## Python

### Setup

```bash
pip install requests
```

### Authentication

```python
import requests

BASE_URL = 'http://localhost:3000'

class EcoCheckClient:
    def __init__(self, base_url=BASE_URL):
        self.base_url = base_url
        self.token = None
        
    def manager_login(self, username, password):
        """Manager login"""
        response = requests.post(
            f'{self.base_url}/api/auth/login',
            json={'username': username, 'password': password}
        )
        response.raise_for_status()
        
        data = response.json()['data']
        self.token = data['token']
        return data['user']
    
    def worker_login(self, phone, password):
        """Worker login"""
        response = requests.post(
            f'{self.base_url}/api/auth/worker/login',
            json={'phone': phone, 'password': password}
        )
        response.raise_for_status()
        
        data = response.json()['data']
        self.token = data['token']
        return data['user']
    
    def get_headers(self):
        """Get authorization headers"""
        if not self.token:
            raise ValueError('Not authenticated. Please login first.')
        return {'Authorization': f'Bearer {self.token}'}
    
    def get_schedules(self, filters=None):
        """Get schedules with optional filters"""
        response = requests.get(
            f'{self.base_url}/api/schedules',
            headers=self.get_headers(),
            params=filters or {}
        )
        response.raise_for_status()
        return response.json()['data']
    
    def create_schedule(self, schedule_data):
        """Create a new schedule"""
        response = requests.post(
            f'{self.base_url}/api/schedules',
            headers=self.get_headers(),
            json=schedule_data
        )
        response.raise_for_status()
        return response.json()['data']
    
    def send_checkin(self, user_id, latitude, longitude, **kwargs):
        """Send real-time location check-in"""
        data = {
            'user_id': user_id,
            'latitude': latitude,
            'longitude': longitude,
            **kwargs  # speed, heading, accuracy
        }
        response = requests.post(
            f'{self.base_url}/api/rt/checkin',
            json=data
        )
        response.raise_for_status()
        return response.json()['data']
    
    def get_analytics_summary(self, from_date=None, to_date=None, district=None):
        """Get analytics summary"""
        params = {}
        if from_date:
            params['from_date'] = from_date
        if to_date:
            params['to_date'] = to_date
        if district:
            params['district'] = district
            
        response = requests.get(
            f'{self.base_url}/api/analytics/summary',
            headers=self.get_headers(),
            params=params
        )
        response.raise_for_status()
        return response.json()['data']
    
    def upload_image(self, file_path):
        """Upload an image file"""
        with open(file_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(
                f'{self.base_url}/api/upload',
                files=files
            )
        response.raise_for_status()
        return response.json()['data']['url']

# Usage Example
client = EcoCheckClient()

# Login
user = client.manager_login('manager1', 'password123')
print(f'Logged in as: {user["full_name"]}')

# Get pending schedules
schedules = client.get_schedules({'status': 'pending'})
print(f'Found {len(schedules)} pending schedules')

# Create new schedule
new_schedule = client.create_schedule({
    'route_name': 'Route District 1',
    'district': 'District 1',
    'scheduled_date': '2025-12-12',
    'scheduled_time': '06:00:00',
    'assigned_group_id': 2,
    'vehicle_id': 5,
    'stops': [
        {'point_id': 10, 'sequence_order': 1, 'estimated_time': '06:15:00'}
    ]
})
print(f'Created schedule: {new_schedule["id"]}')

# Send check-in
checkin = client.send_checkin(
    user_id=1,
    latitude=10.7769,
    longitude=106.7009,
    speed=35.5,
    heading=180
)
print(f'Check-in recorded: {checkin["checkin_id"]}')
```

### WebSocket with Python

```python
import socketio

sio = socketio.Client()

@sio.event
def connect():
    print('Connected to server')
    sio.emit('join', f'driver:{user_id}')

@sio.event
def disconnect():
    print('Disconnected from server')

@sio.on('route_update')
def on_route_update(data):
    print('Route update:', data)

@sio.on('alert')
def on_alert(data):
    print('New alert:', data)

@sio.on('new_assignment')
def on_assignment(data):
    print('New assignment:', data)

# Connect to server
sio.connect(BASE_URL)
sio.wait()
```

---

## Flutter/Dart

### Setup

Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.2
  dio: ^5.4.0
  socket_io_client: ^2.0.3+1
```

### API Service Class

```dart
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class EcoCheckApiService {
  final String baseUrl;
  final Dio _dio;
  String? _token;
  IO.Socket? _socket;

  EcoCheckApiService({this.baseUrl = 'http://localhost:3000'})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ));

  // Authentication
  Future<Map<String, dynamic>> workerLogin(String phone, String password) async {
    try {
      final response = await _dio.post('/api/auth/worker/login', data: {
        'phone': phone,
        'password': password,
      });

      _token = response.data['data']['token'];
      _setupAuthHeader();
      
      return response.data['data'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  void _setupAuthHeader() {
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  // Get Worker Routes
  Future<List<dynamic>> getWorkerRoutes({String? status}) async {
    try {
      final response = await _dio.get(
        '/api/worker/routes',
        queryParameters: status != null ? {'status': status} : null,
      );
      return response.data['data'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Get Route Details
  Future<Map<String, dynamic>> getRouteDetails(int routeId) async {
    try {
      final response = await _dio.get('/api/worker/routes/$routeId');
      return response.data['data'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Start Route
  Future<void> startRoute(
    int routeId, {
    required double latitude,
    required double longitude,
    int? odometerStart,
  }) async {
    try {
      await _dio.post('/api/worker/routes/$routeId/start', data: {
        'start_latitude': latitude,
        'start_longitude': longitude,
        if (odometerStart != null) 'odometer_start': odometerStart,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Complete Stop
  Future<void> completeStop(
    int stopId, {
    required double latitude,
    required double longitude,
    required double wasteCollected,
    String? photoUrl,
    String? notes,
  }) async {
    try {
      await _dio.post('/api/worker/route-stops/$stopId/complete', data: {
        'latitude': latitude,
        'longitude': longitude,
        'waste_collected': wasteCollected,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Real-time Check-in
  Future<void> sendCheckIn({
    required int userId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      await _dio.post('/api/rt/checkin', data: {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
        if (accuracy != null) 'accuracy': accuracy,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Upload Image
  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post('/api/upload', data: formData);
      return response.data['data']['url'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Socket.IO Connection
  void connectSocket(int userId) {
    _socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.on('connect', (_) {
      print('Socket connected');
      _socket!.emit('join', 'driver:$userId');
    });

    _socket!.on('route_update', (data) {
      print('Route update: $data');
      // Handle route update
    });

    _socket!.on('alert', (data) {
      print('New alert: $data');
      // Handle alert
    });

    _socket!.on('new_assignment', (data) {
      print('New assignment: $data');
      // Handle new assignment
    });

    _socket!.on('disconnect', (_) {
      print('Socket disconnected');
    });

    _socket!.connect();
  }

  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
  }

  // Error Handler
  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('error')) {
          return data['error']['message'] ?? 'Unknown error';
        }
      }
      return error.message ?? 'Network error';
    }
    return error.toString();
  }
}

// Usage Example
void main() async {
  final api = EcoCheckApiService(baseUrl: 'http://10.0.2.2:3000');

  try {
    // Login
    final loginData = await api.workerLogin('0901234567', 'worker123');
    print('Logged in: ${loginData['user']['full_name']}');

    // Get routes
    final routes = await api.getWorkerRoutes(status: 'pending');
    print('Found ${routes.length} pending routes');

    // Start route
    if (routes.isNotEmpty) {
      await api.startRoute(
        routes[0]['id'],
        latitude: 10.7769,
        longitude: 106.7009,
      );
      print('Route started');
    }

    // Connect to socket
    api.connectSocket(loginData['user']['id']);

  } catch (e) {
    print('Error: $e');
  }
}
```

---

## cURL

### Manager Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "manager1",
    "password": "password123"
  }'
```

### Get Schedules (with auth)

```bash
curl -X GET "http://localhost:3000/api/schedules?status=pending" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Create Schedule

```bash
curl -X POST http://localhost:3000/api/schedules \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "route_name": "Route District 1",
    "district": "District 1",
    "scheduled_date": "2025-12-12",
    "scheduled_time": "06:00:00",
    "assigned_group_id": 2,
    "vehicle_id": 5,
    "stops": [
      {
        "point_id": 10,
        "sequence_order": 1,
        "estimated_time": "06:15:00"
      }
    ]
  }'
```

### Upload Image

```bash
curl -X POST http://localhost:3000/api/upload \
  -F "image=@/path/to/photo.jpg"
```

### Real-time Check-in

```bash
curl -X POST http://localhost:3000/api/rt/checkin \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 1,
    "latitude": 10.7769,
    "longitude": 106.7009,
    "speed": 35.5,
    "heading": 180
  }'
```

---

## Postman Collection

Import the Postman collection from:
```
docs/postman/ecocheck-api.postman_collection.json
```

### Environment Variables

Create a Postman environment with these variables:

```json
{
  "base_url": "http://localhost:3000",
  "token": "",
  "user_id": ""
}
```

After login, use this test script to save the token:

```javascript
pm.test("Login successful", function() {
    pm.response.to.have.status(200);
    const jsonData = pm.response.json();
    pm.environment.set("token", jsonData.data.token);
    pm.environment.set("user_id", jsonData.data.user.id);
});
```

---

## Best Practices

### 1. Error Handling

Always handle errors gracefully:

```javascript
try {
  const data = await api.getSchedules();
  // Process data
} catch (error) {
  if (error.response) {
    // Server responded with error
    console.error('Server error:', error.response.data.error.message);
  } else if (error.request) {
    // No response received
    console.error('Network error: No response from server');
  } else {
    // Other errors
    console.error('Error:', error.message);
  }
}
```

### 2. Token Refresh

Store tokens securely and refresh when needed:

```javascript
function saveToken(token) {
  // Web: localStorage, Mobile: Secure Storage
  localStorage.setItem('ecocheck_token', token);
}

function getToken() {
  return localStorage.getItem('ecocheck_token');
}

async function makeAuthenticatedRequest(url, options = {}) {
  const token = getToken();
  if (!token) {
    throw new Error('Not authenticated');
  }
  
  return axios({
    url,
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${token}`
    }
  });
}
```

### 3. Real-time Updates

Implement reconnection logic for Socket.IO:

```javascript
const socket = io(BASE_URL, {
  transports: ['websocket'],
  reconnection: true,
  reconnectionDelay: 1000,
  reconnectionAttempts: 5
});

socket.on('reconnect', (attemptNumber) => {
  console.log('Reconnected after', attemptNumber, 'attempts');
  // Re-join rooms
  socket.emit('join', `driver:${userId}`);
});
```

### 4. Rate Limiting

Implement request throttling:

```javascript
const throttle = (func, delay) => {
  let lastCall = 0;
  return (...args) => {
    const now = new Date().getTime();
    if (now - lastCall < delay) {
      return;
    }
    lastCall = now;
    return func(...args);
  };
};

const throttledCheckIn = throttle(sendCheckIn, 30000); // Max once per 30s
```

---

## Support

For more examples and support:
- GitHub Issues: https://github.com/Lil5354/EcoCheck-OLP-2025/issues
- Email: support@ecocheck.com

---

**Last Updated:** December 11, 2025
