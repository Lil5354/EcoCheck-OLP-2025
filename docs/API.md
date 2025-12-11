# EcoCheck API Documentation

## Overview

EcoCheck API là RESTful API được xây dựng trên Node.js/Express cho hệ thống quản lý thu gom rác thải động. API tích hợp với FIWARE Orion-LD Context Broker và hỗ trợ realtime communication qua Socket.IO.

**Base URL (Production):** `https://ecocheck-olp-2025.onrender.com`  
**Base URL (Development):** `http://localhost:3000`

**API Version:** 1.0.0  
**License:** MIT

---

## Table of Contents

1. [Authentication](#authentication)
2. [Core Endpoints](#core-endpoints)
3. [Master Data Management](#master-data-management)
4. [Route & Schedule Management](#route--schedule-management)
5. [Worker Operations](#worker-operations)
6. [Real-time Operations](#real-time-operations)
7. [Analytics & Reports](#analytics--reports)
8. [Gamification System](#gamification-system)
9. [VRP (Vehicle Routing Problem)](#vrp-vehicle-routing-problem)
10. [Alert Management](#alert-management)
11. [File Upload](#file-upload)
12. [Socket.IO Events](#socketio-events)

---

## Authentication

### Manager Login
```http
POST /api/auth/login
```

**Request Body:**
```json
{
  "username": "manager1",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "manager1",
      "full_name": "Nguyen Van A",
      "role": "manager",
      "email": "manager@ecocheck.com"
    }
  }
}
```

### Worker Login
```http
POST /api/auth/worker/login
```

**Request Body:**
```json
{
  "phone": "0901234567",
  "password": "worker123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "full_name": "Tran Van B",
      "phone": "0901234567",
      "role": "worker",
      "group_id": 2
    }
  }
}
```

### Register User
```http
POST /api/auth/register
```

**Request Body:**
```json
{
  "username": "user1",
  "password": "pass123",
  "full_name": "Le Thi C",
  "email": "user@example.com",
  "phone": "0912345678"
}
```

### Get Current User Info
```http
GET /api/auth/me
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "manager1",
    "full_name": "Nguyen Van A",
    "role": "manager",
    "email": "manager@ecocheck.com"
  }
}
```

---

## Core Endpoints

### Health Check
```http
GET /health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-12-11T10:30:00Z",
  "database": "connected",
  "fiware": "connected"
}
```

### System Status
```http
GET /api/status
```

**Response:**
```json
{
  "status": "OK",
  "database": "connected",
  "fiware": "available",
  "version": "1.0.0"
}
```

### FIWARE Version
```http
GET /api/fiware/version
```

**Response:**
```json
{
  "orion": {
    "version": "1.5.0",
    "uptime": "5 days, 3:24:15",
    "git_hash": "nogitversion"
  }
}
```

---

## Master Data Management

### Fleet Management

#### Get All Vehicles
```http
GET /api/master/fleet
```

**Query Parameters:**
- `depot_id` (optional) - Filter by depot ID
- `status` (optional) - Filter by status: `active`, `inactive`, `maintenance`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "vehicle_number": "VEH-001",
      "type": "compactor",
      "capacity": 10000.00,
      "status": "active",
      "depot_id": 1,
      "depot_name": "Depot Thu Duc"
    }
  ]
}
```

#### Create Vehicle
```http
POST /api/master/fleet
```

**Request Body:**
```json
{
  "vehicle_number": "VEH-005",
  "type": "compactor",
  "capacity": 12000,
  "fuel_consumption": 15.5,
  "status": "active",
  "depot_id": 1
}
```

#### Update Vehicle
```http
PATCH /api/master/fleet/:id
```

**Request Body:**
```json
{
  "status": "maintenance",
  "capacity": 11000
}
```

#### Delete Vehicle
```http
DELETE /api/master/fleet/:id
```

### Depot Management

#### Get All Depots
```http
GET /api/master/depots
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Depot Thu Duc",
      "address": "123 Xa Lo Ha Noi, Thu Duc",
      "latitude": 10.8505,
      "longitude": 106.7718,
      "capacity": 50,
      "status": "active"
    }
  ]
}
```

#### Create Depot
```http
POST /api/master/depots
```

**Request Body:**
```json
{
  "name": "Depot Binh Thanh",
  "address": "456 Xo Viet Nghe Tinh, Binh Thanh",
  "latitude": 10.8142,
  "longitude": 106.7054,
  "capacity": 30,
  "contact_person": "Nguyen Van X",
  "contact_phone": "0908123456"
}
```

#### Update Depot
```http
PATCH /api/master/depots/:id
```

#### Delete Depot
```http
DELETE /api/master/depots/:id
```

### Dump Site Management

#### Get All Dump Sites
```http
GET /api/master/dumps
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Landfill Da Phuoc",
      "address": "Xa Da Phuoc, Binh Chanh",
      "latitude": 10.6734,
      "longitude": 106.5522,
      "capacity": 1000000,
      "current_load": 450000,
      "status": "active"
    }
  ]
}
```

#### Create Dump Site
```http
POST /api/master/dumps
```

#### Update Dump Site
```http
PATCH /api/master/dumps/:id
```

#### Delete Dump Site
```http
DELETE /api/master/dumps/:id
```

### Collection Points

#### Get Collection Points
```http
GET /api/points
```

**Query Parameters:**
- `limit` (default: 100) - Maximum number of points
- `offset` (default: 0) - Pagination offset
- `district` (optional) - Filter by district
- `latitude` (optional) - Filter by location
- `longitude` (optional) - Filter by location
- `radius` (optional) - Radius in meters

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Collection Point 1",
      "address": "123 Le Loi, District 1",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "district": "District 1",
      "waste_type": "mixed",
      "capacity": 500,
      "current_load": 350,
      "status": "active"
    }
  ],
  "pagination": {
    "total": 250,
    "limit": 100,
    "offset": 0
  }
}
```

---

## Route & Schedule Management

### Get All Schedules
```http
GET /api/schedules
```

**Query Parameters:**
- `status` (optional) - Filter: `pending`, `in_progress`, `completed`, `cancelled`
- `date` (optional) - Filter by date (YYYY-MM-DD)
- `district` (optional) - Filter by district

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "route_name": "Route District 1 - Morning",
      "district": "District 1",
      "scheduled_date": "2025-12-11",
      "scheduled_time": "06:00:00",
      "status": "pending",
      "assigned_group_id": 2,
      "vehicle_id": 5,
      "total_stops": 15,
      "completed_stops": 0
    }
  ]
}
```

### Get Assigned Schedules (Worker)
```http
GET /api/schedules/assigned
```

**Headers:**
```
Authorization: Bearer {worker_token}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "route_name": "Route District 1",
      "scheduled_date": "2025-12-11",
      "scheduled_time": "06:00:00",
      "status": "in_progress",
      "progress": 60,
      "total_stops": 15,
      "completed_stops": 9
    }
  ]
}
```

### Get Schedule Details
```http
GET /api/schedules/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "route_name": "Route District 1",
    "district": "District 1",
    "scheduled_date": "2025-12-11",
    "status": "in_progress",
    "vehicle": {
      "id": 5,
      "vehicle_number": "VEH-005"
    },
    "stops": [
      {
        "stop_id": 1,
        "point_id": 10,
        "point_name": "Collection Point A",
        "latitude": 10.7769,
        "longitude": 106.7009,
        "sequence_order": 1,
        "status": "completed",
        "estimated_time": "06:15:00",
        "actual_time": "06:12:00"
      }
    ]
  }
}
```

### Create Schedule
```http
POST /api/schedules
```

**Request Body:**
```json
{
  "route_name": "Route District 3 - Afternoon",
  "district": "District 3",
  "scheduled_date": "2025-12-12",
  "scheduled_time": "14:00:00",
  "assigned_group_id": 3,
  "vehicle_id": 7,
  "stops": [
    {
      "point_id": 25,
      "sequence_order": 1,
      "estimated_time": "14:15:00"
    },
    {
      "point_id": 26,
      "sequence_order": 2,
      "estimated_time": "14:30:00"
    }
  ]
}
```

### Update Schedule
```http
PATCH /api/schedules/:id
```

**Request Body:**
```json
{
  "scheduled_date": "2025-12-13",
  "scheduled_time": "15:00:00",
  "status": "pending"
}
```

### Cancel Schedule
```http
PATCH /api/schedules/:id/cancel
```

**Request Body:**
```json
{
  "reason": "Bad weather conditions"
}
```

### Delete Schedule
```http
DELETE /api/schedules/:id
```

---

## Worker Operations

### Get Worker Routes
```http
GET /api/worker/routes
```

**Headers:**
```
Authorization: Bearer {worker_token}
```

**Query Parameters:**
- `status` (optional) - Filter: `pending`, `in_progress`, `completed`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "route_name": "Route District 1",
      "scheduled_date": "2025-12-11",
      "status": "in_progress",
      "progress": 60.0,
      "total_stops": 15,
      "completed_stops": 9,
      "vehicle_number": "VEH-005"
    }
  ]
}
```

### Get Route Details
```http
GET /api/worker/routes/:id
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "route_name": "Route District 1",
    "status": "in_progress",
    "vehicle": {
      "vehicle_number": "VEH-005",
      "capacity": 10000
    },
    "stops": [
      {
        "stop_id": 1,
        "point_name": "Collection Point A",
        "address": "123 Le Loi",
        "latitude": 10.7769,
        "longitude": 106.7009,
        "sequence_order": 1,
        "status": "completed"
      }
    ]
  }
}
```

### Start Route
```http
POST /api/worker/routes/:id/start
```

**Request Body:**
```json
{
  "start_latitude": 10.7769,
  "start_longitude": 106.7009,
  "odometer_start": 12345
}
```

### Complete Route
```http
POST /api/worker/routes/:id/complete
```

**Request Body:**
```json
{
  "end_latitude": 10.8505,
  "end_longitude": 106.7718,
  "odometer_end": 12389,
  "notes": "Route completed successfully"
}
```

### Complete Stop
```http
POST /api/worker/route-stops/:id/complete
```

**Request Body:**
```json
{
  "latitude": 10.7769,
  "longitude": 106.7009,
  "waste_collected": 350.5,
  "photo_url": "https://example.com/photo.jpg",
  "notes": "Full bin collected"
}
```

### Skip Stop
```http
POST /api/worker/route-stops/:id/skip
```

**Request Body:**
```json
{
  "reason": "Access blocked by construction",
  "photo_url": "https://example.com/blocked.jpg"
}
```

---

## Real-time Operations

### Check-in (Real-time Location Update)
```http
POST /api/rt/checkin
```

**Request Body:**
```json
{
  "user_id": 1,
  "latitude": 10.7769,
  "longitude": 106.7009,
  "speed": 35.5,
  "heading": 180,
  "accuracy": 10
}
```

**Response:**
```json
{
  "success": true,
  "message": "Check-in recorded",
  "data": {
    "checkin_id": 12345,
    "timestamp": "2025-12-11T10:30:00Z"
  }
}
```

### Get Recent Check-ins
```http
GET /api/rt/checkins
```

**Query Parameters:**
- `user_id` (optional) - Filter by user
- `since` (optional) - ISO timestamp
- `limit` (default: 100)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 12345,
      "user_id": 1,
      "latitude": 10.7769,
      "longitude": 106.7009,
      "timestamp": "2025-12-11T10:30:00Z",
      "speed": 35.5,
      "heading": 180
    }
  ]
}
```

### Get Collection Points (Real-time)
```http
GET /api/rt/points
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Point A",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "current_load": 350,
      "capacity": 500,
      "fill_level": 70.0,
      "status": "active"
    }
  ]
}
```

### Get Active Vehicles
```http
GET /api/rt/vehicles
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 5,
      "vehicle_number": "VEH-005",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "speed": 25.5,
      "heading": 90,
      "status": "active",
      "last_update": "2025-12-11T10:28:00Z"
    }
  ]
}
```

---

## Analytics & Reports

### Analytics Summary
```http
GET /api/analytics/summary
```

**Query Parameters:**
- `from_date` (optional) - Start date (YYYY-MM-DD)
- `to_date` (optional) - End date (YYYY-MM-DD)
- `district` (optional) - Filter by district

**Response:**
```json
{
  "success": true,
  "data": {
    "total_waste_collected": 125000.50,
    "total_routes_completed": 45,
    "total_stops_completed": 675,
    "avg_completion_time": 180,
    "efficiency_rate": 92.5,
    "by_district": [
      {
        "district": "District 1",
        "waste_collected": 35000.00,
        "routes_completed": 12
      }
    ]
  }
}
```

### Time Series Data
```http
GET /api/analytics/timeseries
```

**Query Parameters:**
- `metric` (required) - Metric: `waste_collected`, `routes_completed`, `efficiency`
- `from_date` (required) - Start date
- `to_date` (required) - End date
- `interval` (default: `day`) - Interval: `hour`, `day`, `week`, `month`

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "timestamp": "2025-12-01T00:00:00Z",
      "value": 2500.50
    },
    {
      "timestamp": "2025-12-02T00:00:00Z",
      "value": 2750.25
    }
  ]
}
```

### Predict Future Waste
```http
GET /api/analytics/predict
```

**Query Parameters:**
- `district` (required) - District name
- `days` (default: 7) - Number of days to predict

**Response:**
```json
{
  "success": true,
  "data": {
    "district": "District 1",
    "predictions": [
      {
        "date": "2025-12-12",
        "predicted_waste": 2800.50,
        "confidence": 0.85
      }
    ]
  }
}
```

---

## Gamification System

### Get User Statistics
```http
GET /api/gamification/stats/:userId
```

**Response:**
```json
{
  "success": true,
  "data": {
    "user_id": 1,
    "total_points": 1250,
    "level": 5,
    "rank": 12,
    "badges_earned": 8,
    "routes_completed": 45,
    "waste_collected": 12500.00
  }
}
```

### Get Leaderboard
```http
GET /api/gamification/leaderboard
```

**Query Parameters:**
- `timeframe` (default: `all_time`) - Options: `daily`, `weekly`, `monthly`, `all_time`
- `limit` (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "rank": 1,
      "user_id": 5,
      "full_name": "Nguyen Van A",
      "total_points": 2500,
      "level": 8,
      "badges_count": 12
    }
  ]
}
```

### Get Badges
```http
GET /api/gamification/badges
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Eco Warrior",
      "description": "Complete 100 routes",
      "icon_url": "https://example.com/badge.png",
      "points_reward": 500,
      "rarity": "gold"
    }
  ]
}
```

### Adjust Points (Admin)
```http
POST /api/gamification/points/adjust
```

**Request Body:**
```json
{
  "user_id": 5,
  "points": 100,
  "reason": "Bonus for excellent performance",
  "type": "bonus"
}
```

### Assign Badge
```http
POST /api/gamification/badges/assign
```

**Request Body:**
```json
{
  "user_id": 5,
  "badge_id": 3,
  "reason": "Completed 100 routes milestone"
}
```

---

## VRP (Vehicle Routing Problem)

### Get Districts
```http
GET /api/vrp/districts
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "district": "District 1",
      "total_points": 45,
      "total_waste": 15000.00
    }
  ]
}
```

### Optimize Routes
```http
POST /api/vrp/optimize
```

**Request Body:**
```json
{
  "district": "District 1",
  "date": "2025-12-12",
  "vehicles": [
    {
      "id": 5,
      "capacity": 10000,
      "start_depot_id": 1
    }
  ],
  "algorithm": "hybrid_ci_sa",
  "max_routes": 5
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "routes": [
      {
        "vehicle_id": 5,
        "stops": [
          {
            "point_id": 10,
            "sequence": 1,
            "estimated_arrival": "06:15:00"
          }
        ],
        "total_distance": 25.5,
        "total_waste": 3500.00,
        "estimated_duration": 180
      }
    ],
    "optimization_stats": {
      "total_distance": 125.5,
      "total_duration": 720,
      "efficiency_score": 92.5
    }
  }
}
```

### Save Routes
```http
POST /api/vrp/save-routes
```

**Request Body:**
```json
{
  "routes": [
    {
      "route_name": "Route District 1 - Morning",
      "district": "District 1",
      "vehicle_id": 5,
      "assigned_group_id": 2,
      "scheduled_date": "2025-12-12",
      "scheduled_time": "06:00:00",
      "stops": [
        {
          "point_id": 10,
          "sequence_order": 1,
          "estimated_time": "06:15:00"
        }
      ]
    }
  ]
}
```

---

## Alert Management

### Get Alerts
```http
GET /api/alerts
```

**Query Parameters:**
- `status` (optional) - Filter: `new`, `assigned`, `in_progress`, `resolved`
- `priority` (optional) - Filter: `low`, `medium`, `high`, `critical`
- `type` (optional) - Filter by alert type

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "type": "overflow",
      "priority": "high",
      "status": "new",
      "point_id": 25,
      "point_name": "Collection Point X",
      "latitude": 10.7769,
      "longitude": 106.7009,
      "description": "Bin overflowing",
      "created_at": "2025-12-11T09:30:00Z"
    }
  ]
}
```

### Dispatch Alert
```http
POST /api/alerts/:alertId/dispatch
```

**Request Body:**
```json
{
  "vehicle_id": 5,
  "group_id": 2,
  "priority": "urgent",
  "notes": "Immediate response required"
}
```

### Assign Alert
```http
POST /api/alerts/:alertId/assign
```

**Request Body:**
```json
{
  "vehicle_id": 5,
  "group_id": 2,
  "estimated_arrival": "2025-12-11T10:45:00Z"
}
```

---

## File Upload

### Upload Single Image
```http
POST /api/upload
Content-Type: multipart/form-data
```

**Form Data:**
- `image` (file) - Image file (max 5MB)

**Response:**
```json
{
  "success": true,
  "data": {
    "filename": "1702294800000-photo.jpg",
    "url": "http://localhost:3000/uploads/1702294800000-photo.jpg",
    "size": 245678
  }
}
```

### Upload Multiple Images
```http
POST /api/upload/multiple
Content-Type: multipart/form-data
```

**Form Data:**
- `images` (file[]) - Multiple image files (max 5 files, 5MB each)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "filename": "1702294800000-photo1.jpg",
      "url": "http://localhost:3000/uploads/1702294800000-photo1.jpg"
    }
  ]
}
```

### AI Waste Analysis
```http
POST /api/ai/analyze-waste
```

**Request Body:**
```json
{
  "image_url": "http://localhost:3000/uploads/photo.jpg",
  "location": {
    "latitude": 10.7769,
    "longitude": 106.7009
  }
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "waste_type": "plastic",
    "estimated_weight": 15.5,
    "confidence": 0.92,
    "recommendations": [
      "Schedule pickup within 24 hours",
      "Use recycling bin"
    ]
  }
}
```

---

## Personnel & Groups Management

### Get All Personnel
```http
GET /api/manager/personnel
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "full_name": "Nguyen Van A",
      "phone": "0901234567",
      "role": "driver",
      "status": "active",
      "group_id": 2,
      "group_name": "Team Alpha"
    }
  ]
}
```

### Create Personnel
```http
POST /api/manager/personnel
```

**Request Body:**
```json
{
  "full_name": "Tran Van B",
  "phone": "0912345678",
  "password": "password123",
  "role": "driver",
  "group_id": 2
}
```

### Update Personnel
```http
PUT /api/manager/personnel/:id
```

### Delete Personnel
```http
DELETE /api/manager/personnel/:id
```

### Get All Groups
```http
GET /api/groups
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": 2,
      "name": "Team Alpha",
      "district": "District 1",
      "members_count": 5,
      "status": "active"
    }
  ]
}
```

### Create Group
```http
POST /api/groups
```

**Request Body:**
```json
{
  "name": "Team Beta",
  "district": "District 3",
  "supervisor_id": 5
}
```

### Add Member to Group
```http
POST /api/groups/:id/members
```

**Request Body:**
```json
{
  "personnel_id": 7,
  "role": "driver"
}
```

---

## Socket.IO Events

### Client → Server Events

#### Join Room
```javascript
socket.emit('join', 'driver:123');
```

#### Leave Room
```javascript
socket.emit('leave', 'driver:123');
```

#### Location Update
```javascript
socket.emit('location_update', {
  user_id: 123,
  latitude: 10.7769,
  longitude: 106.7009,
  speed: 35.5,
  heading: 180
});
```

### Server → Client Events

#### Route Update
```javascript
socket.on('route_update', (data) => {
  // data: { route_id, status, progress, ... }
});
```

#### Alert Notification
```javascript
socket.on('alert', (data) => {
  // data: { alert_id, type, priority, message, ... }
});
```

#### Vehicle Location Update
```javascript
socket.on('vehicle_location', (data) => {
  // data: { vehicle_id, latitude, longitude, speed, ... }
});
```

#### New Assignment
```javascript
socket.on('new_assignment', (data) => {
  // data: { schedule_id, route_name, scheduled_date, ... }
});
```

---

## Error Responses

All endpoints return errors in the following format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {
      "field": "Additional error details"
    }
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Invalid or missing authentication token |
| `FORBIDDEN` | 403 | User doesn't have permission |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 400 | Request validation failed |
| `CONFLICT` | 409 | Resource conflict (e.g., duplicate) |
| `INTERNAL_ERROR` | 500 | Server internal error |

---

## Rate Limiting

- **Default Limit:** 100 requests per 15 minutes per IP
- **Authenticated Users:** 1000 requests per 15 minutes
- **Upload Endpoints:** 20 requests per 15 minutes

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1702295700
```

---

## Pagination

Endpoints that return lists support pagination:

**Query Parameters:**
- `limit` - Items per page (default: 20, max: 100)
- `offset` - Number of items to skip (default: 0)

**Response:**
```json
{
  "success": true,
  "data": [...],
  "pagination": {
    "total": 250,
    "limit": 20,
    "offset": 0,
    "has_more": true
  }
}
```

---

## Webhooks (Coming Soon)

EcoCheck will support webhooks for real-time event notifications:

- Route completion
- Alert creation
- Vehicle status change
- Exception approvals

---

## Support

- **Email:** support@ecocheck.com
- **Documentation:** https://ecocheck-olp-2025.onrender.com/docs
- **GitHub Issues:** https://github.com/Lil5354/EcoCheck-OLP-2025/issues

---

**Last Updated:** December 11, 2025  
**API Version:** 1.0.0
