# CN14: Master Data Management

## Purpose
CRUD operations for Fleet, Personnel, Depots, and Dumps. Essential for configuring system resources used in route optimization and dispatch.

## Features

### Fleet Management
- **Table**: View all vehicles with plate, type, capacity, status
- **Add/Edit**: Create or modify vehicle records
- **Validation**: Plate required, capacity > 0
- **Types**: Compactor, Mini Truck, Electric Trike

### Personnel
- **Table**: View all personnel with name, role, status
- **Add/Edit**: Create or modify personnel records
- **Roles**: Driver, Collector, Manager, Dispatcher
- **Reset Password**: Placeholder for future implementation

### Depots & Dumps
- **Depots**: Starting points for collection routes
- **Dumps**: End points (transfer stations, landfills)
- **MapPicker**: Click or drag marker to set location
- **Validation**: Name required, coordinates must be valid

## Usage

### Fleet
1. Navigate to **Master Data > Fleet**
2. Click **Add Vehicle** to create new vehicle
3. Fill in plate, type, capacity
4. Click **Save**

### Personnel
1. Navigate to **Master Data > Personnel**
2. Click **Add Personnel** to create new user
3. Fill in name, role
4. Click **Save**

### Depots & Dumps
1. Navigate to **Master Data > Depots & Dumps**
2. Click **Add Depot** or **Add Dump**
3. Enter name and pick location on map
4. Click **Save**

## API Endpoints
- `GET /api/master/fleet` – fetch all vehicles
- `POST /api/master/fleet` – create vehicle
- `PUT /api/master/fleet/:id` – update vehicle
- `DELETE /api/master/fleet/:id` – delete vehicle
- Similar CRUD for `/api/master/personnel`, `/api/master/depots`, `/api/master/dumps`

## Mock Data
- Fleet: 3 vehicles (V01, V02, V03)
- Personnel: 3 users (driver, collector, manager)
- Depots: 1 depot at (106.7, 10.78)
- Dumps: 1 dump at (106.72, 10.81)

## Notes
- At least 1 depot and 1 dump required for route optimization
- MapPicker uses OpenStreetMap tiles
- Delete operations require confirmation (not yet implemented)

