# CN7: Dynamic Dispatch

## Purpose
Real-time alert monitoring and dynamic re-routing for handling exceptions like late check-ins, missed points, and new hotspots.

## Features
- **Real-time Alerts**: Poll alerts every 5 seconds, display in table with time, point, vehicle, level (warning/critical), status
- **Re-routing**: Select open alert and click **Re-route** to assign nearest vehicle and update route
- **Status Tracking**: Track alert status (open/ack/resolved)

## Usage
1. Navigate to **Operations > Dynamic Dispatch**
2. Monitor alerts in the table (auto-refresh every 5s)
3. For open alerts, click **Re-route** to dispatch nearest vehicle
4. Toast notification confirms re-route creation

## API Endpoints
- `GET /api/rt/alerts` – fetch real-time alerts
- `GET /api/rt/vehicles` – fetch current vehicle positions
- `POST /api/dispatch/reroute` – create re-route for alert
  - Request: `{ alertId, vehicleId }`
  - Response: `{ ok, message, routeId }`

## Mock Data
Mock alerts include 8 sample alerts with random levels and statuses. Mock re-route returns a random routeId.

## Notes
- Alerts auto-refresh every 5 seconds
- Only open alerts can be re-routed
- Re-routing logic (nearest vehicle) is handled by backend

