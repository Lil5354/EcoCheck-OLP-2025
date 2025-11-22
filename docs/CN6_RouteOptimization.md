# CN6: Route Optimization

## Purpose
Provides AI-powered route optimization for waste collection vehicles using VRP (Vehicle Routing Problem) algorithms with time window constraints and capacity limits.

## Features
- **Smart Filtering**: Filter out grey points, select waste types (Household/Recyclable/Bulky), time window [19:00–05:00]
- **Clustering & Vehicle Selection**: Display collection points on map with clustering, select vehicles from fleet
- **VRP Optimization**: Call backend VRP API with constraints (time window, capacity, depot, dump)
- **Route Visualization**: Display optimized routes as polylines on map, color-coded by vehicle
- **Dispatch**: Send optimized routes to drivers via API

## Usage
1. Navigate to **Operations > Route Optimization**
2. Select vehicles from the fleet panel on the right
3. Click **Optimize Routes** to compute optimal routes
4. Review routes in the result panel
5. Click **Send Routes** to dispatch to drivers

## API Endpoints
- `GET /api/master/fleet` – fetch available vehicles
- `GET /api/points?type=&status=&bbox=` – fetch collection points
- `POST /api/vrp/optimize` – compute optimal routes
  - Request: `{ timeWindow, vehicles, depot, dump, points }`
  - Response: `{ ok, routes: [{ vehicleId, distance, eta, geojson, stops }] }`
- `POST /api/dispatch/send-routes` – dispatch routes to drivers

## Mock Data
When backend is offline, mock data includes 3 vehicles (V01, V02, V03) and ~120 random points around HCMC. Mock VRP returns simple split routes.

## Notes
- Ensure at least one depot and one dump are configured in Master Data > Depots & Dumps
- Grey points are automatically filtered out before optimization
- Time window constraint is hardcoded to 19:00–05:00 (night shift)

