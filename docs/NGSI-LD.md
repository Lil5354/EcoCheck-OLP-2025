# NGSI-LD API Documentation

## Overview

EcoCheck now supports **NGSI-LD v1.6.1** specification, the standard API for context information management defined by ETSI. This enables interoperability with FIWARE ecosystem and other smart city platforms.

## Base URL

```
http://localhost:3000/ngsi-ld/v1
https://ecocheck-olp-2025.onrender.com/ngsi-ld/v1
```

## JSON-LD Context

All NGSI-LD entities use the EcoCheck context:
```
http://localhost:3000/contexts/ecocheck.jsonld
```

The context is automatically included in Link headers or can be embedded in responses.

---

## Entity Types

EcoCheck supports the following NGSI-LD entity types:

| Entity Type | Description | URN Prefix |
|------------|-------------|-----------|
| `Vehicle` | Waste collection vehicles | `urn:ngsi-ld:Vehicle:` |
| `Worker` | Collection personnel | `urn:ngsi-ld:Worker:` |
| `Depot` | Vehicle depots/stations | `urn:ngsi-ld:Depot:` |
| `Dump` | Waste disposal sites | `urn:ngsi-ld:Dump:` |
| `Route` | Collection routes | `urn:ngsi-ld:Route:` |
| `WastePoint` | Waste collection points | `urn:ngsi-ld:WastePoint:` |
| `Alert` | System alerts | `urn:ngsi-ld:Alert:` |
| `CheckIn` | Waste collection check-ins | `urn:ngsi-ld:CheckIn:` |
| `Schedule` | Collection schedules | `urn:ngsi-ld:Schedule:` |

---

## API Endpoints

### 1. Query Entities

Get a list of entities with optional filters.

**Request:**
```http
GET /ngsi-ld/v1/entities?type=Vehicle&limit=10
```

**Query Parameters:**
- `type` - Entity type (can be comma-separated list)
- `id` - Specific entity ID(s) (comma-separated)
- `idPattern` - Regex pattern for entity IDs
- `attrs` - Specific attributes to return (comma-separated)
- `q` - Query filter expression
- `georel` - Geographical relationship (e.g., `near;maxDistance==1000`)
- `geometry` - Geometry type (`Point`, `Polygon`, etc.)
- `coordinates` - Coordinates for geo-query
- `limit` - Maximum number of results (default: 20)
- `offset` - Pagination offset (default: 0)

**Response:**
```json
[
  {
    "id": "urn:ngsi-ld:Vehicle:veh-001",
    "type": "Vehicle",
    "licensePlate": { "type": "Property", "value": "59A-123.45" },
    "vehicleType": { "type": "Property", "value": "garbage_truck_small" },
    "capacityKg": { "type": "Property", "value": 1500 },
    "status": { "type": "Property", "value": "available" },
    "location": {
      "type": "GeoProperty",
      "value": { "type": "Point", "coordinates": [106.7015, 10.7769] }
    },
    "homeDepot": { 
      "type": "Relationship", 
      "object": "urn:ngsi-ld:Depot:depot-001" 
    }
  }
]
```

**Headers:**
```
Link: <http://localhost:3000/contexts/ecocheck.jsonld>; rel="http://www.w3.org/ns/json-ld#context"; type="application/ld+json"
```

---

### 2. Get Entity by ID

Retrieve a specific entity.

**Request:**
```http
GET /ngsi-ld/v1/entities/urn:ngsi-ld:Vehicle:veh-001
```

**Query Parameters:**
- `attrs` - Specific attributes to return (comma-separated)

**Response:**
```json
{
  "id": "urn:ngsi-ld:Vehicle:veh-001",
  "type": "Vehicle",
  "licensePlate": { "type": "Property", "value": "59A-123.45" },
  "vehicleType": { "type": "Property", "value": "garbage_truck_small" },
  "capacityKg": { "type": "Property", "value": 1500 },
  "wasteTypes": { "type": "Property", "value": ["household", "recyclable"] },
  "status": { "type": "Property", "value": "available" },
  "location": {
    "type": "GeoProperty",
    "value": { "type": "Point", "coordinates": [106.7015, 10.7769] }
  },
  "homeDepot": { 
    "type": "Relationship", 
    "object": "urn:ngsi-ld:Depot:depot-001" 
  }
}
```

**Error Response (404):**
```json
{
  "type": "https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound",
  "title": "Entity Not Found",
  "detail": "Entity with id urn:ngsi-ld:Vehicle:veh-999 not found"
}
```

---

### 3. Create Entity

Create a new NGSI-LD entity.

**Request:**
```http
POST /ngsi-ld/v1/entities
Content-Type: application/ld+json
```

**Body:**
```json
{
  "@context": [
    "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "http://localhost:3000/contexts/ecocheck.jsonld"
  ],
  "id": "urn:ngsi-ld:Vehicle:veh-new",
  "type": "Vehicle",
  "licensePlate": { "type": "Property", "value": "59B-999.99" },
  "vehicleType": { "type": "Property", "value": "compactor" },
  "capacityKg": { "type": "Property", "value": 5000 },
  "status": { "type": "Property", "value": "available" },
  "location": {
    "type": "GeoProperty",
    "value": { "type": "Point", "coordinates": [106.70, 10.77] }
  },
  "homeDepot": { 
    "type": "Relationship", 
    "object": "urn:ngsi-ld:Depot:depot-001" 
  }
}
```

**Response (201 Created):**
```json
{
  "created": true
}
```

**Headers:**
```
Location: /ngsi-ld/v1/entities/urn:ngsi-ld:Vehicle:veh-new
```

**Error Response (400):**
```json
{
  "type": "https://uri.etsi.org/ngsi-ld/errors/BadRequestData",
  "title": "Invalid NGSI-LD Entity",
  "detail": "Missing required field: id"
}
```

**Error Response (409):**
```json
{
  "type": "https://uri.etsi.org/ngsi-ld/errors/AlreadyExists",
  "title": "Entity Already Exists",
  "detail": "An entity with this ID already exists"
}
```

---

### 4. Update Entity Attributes

Update specific attributes of an entity.

**Request:**
```http
PATCH /ngsi-ld/v1/entities/urn:ngsi-ld:Vehicle:veh-001/attrs
Content-Type: application/ld+json
```

**Body:**
```json
{
  "status": { "type": "Property", "value": "in_use" },
  "loadKg": { "type": "Property", "value": 1200 }
}
```

**Response (204 No Content)**

**Error Response (404):**
```json
{
  "type": "https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound",
  "title": "Entity Not Found"
}
```

---

### 5. Delete Entity

Delete an entity.

**Request:**
```http
DELETE /ngsi-ld/v1/entities/urn:ngsi-ld:Vehicle:veh-001
```

**Response (204 No Content)**

**Error Response (404):**
```json
{
  "type": "https://uri.etsi.org/ngsi-ld/errors/ResourceNotFound",
  "title": "Entity Not Found"
}
```

---

## Examples

### Example 1: Query All Vehicles in Area

```bash
curl -X GET "http://localhost:3000/ngsi-ld/v1/entities?type=Vehicle&georel=near;maxDistance==5000&geometry=Point&coordinates=106.70,10.77" \
  -H "Accept: application/ld+json"
```

### Example 2: Create Waste Point

```bash
curl -X POST "http://localhost:3000/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "@context": [
      "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
      "http://localhost:3000/contexts/ecocheck.jsonld"
    ],
    "id": "urn:ngsi-ld:WastePoint:point-123",
    "type": "WastePoint",
    "address": { "type": "Property", "value": "123 Main St, District 1" },
    "wasteType": { "type": "Property", "value": "household" },
    "fillingLevel": { "type": "Property", "value": 0.6 },
    "location": {
      "type": "GeoProperty",
      "value": { "type": "Point", "coordinates": [106.70, 10.77] }
    }
  }'
```

### Example 3: Update Alert Status

```bash
curl -X PATCH "http://localhost:3000/ngsi-ld/v1/entities/urn:ngsi-ld:Alert:alert-001/attrs" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "status": { "type": "Property", "value": "resolved" }
  }'
```

### Example 4: Query Overdue Alerts

```bash
curl -X GET "http://localhost:3000/ngsi-ld/v1/entities?type=Alert&q=status==open;severity==high" \
  -H "Accept: application/ld+json"
```

---

## Entity Models

### Vehicle Entity

```json
{
  "id": "urn:ngsi-ld:Vehicle:{id}",
  "type": "Vehicle",
  "licensePlate": { "type": "Property", "value": "string" },
  "vehicleType": { "type": "Property", "value": "compactor|mini-truck|electric-trike" },
  "capacityKg": { "type": "Property", "value": number },
  "wasteTypes": { "type": "Property", "value": ["household", "recyclable", ...] },
  "status": { "type": "Property", "value": "available|in_use|maintenance" },
  "loadKg": { "type": "Property", "value": number },
  "fuelType": { "type": "Property", "value": "diesel|electric|hybrid" },
  "location": { "type": "GeoProperty", "value": { "type": "Point", "coordinates": [lon, lat] } },
  "homeDepot": { "type": "Relationship", "object": "urn:ngsi-ld:Depot:{id}" }
}
```

### WastePoint Entity

```json
{
  "id": "urn:ngsi-ld:WastePoint:{id}",
  "type": "WastePoint",
  "address": { "type": "Property", "value": "string" },
  "wasteType": { "type": "Property", "value": "household|recyclable|hazardous|bulky" },
  "fillingLevel": { "type": "Property", "value": number (0-1) },
  "status": { "type": "Property", "value": "active|inactive" },
  "location": { 
    "type": "GeoProperty", 
    "value": { "type": "Point", "coordinates": [lon, lat] },
    "observedAt": "ISO8601 timestamp"
  }
}
```

### Alert Entity

```json
{
  "id": "urn:ngsi-ld:Alert:{id}",
  "type": "Alert",
  "alertType": { "type": "Property", "value": "missed_collection|overdue_point|vehicle_issue" },
  "severity": { "type": "Property", "value": "low|medium|high|critical" },
  "status": { "type": "Property", "value": "open|acknowledged|resolved" },
  "description": { "type": "Property", "value": "string" },
  "dateIssued": { "type": "Property", "value": { "@type": "DateTime", "@value": "ISO8601" } },
  "targetPoint": { "type": "Relationship", "object": "urn:ngsi-ld:WastePoint:{id}" },
  "location": { "type": "GeoProperty", "value": { "type": "Point", "coordinates": [lon, lat] } }
}
```

### Route Entity

```json
{
  "id": "urn:ngsi-ld:Route:{id}",
  "type": "Route",
  "name": { "type": "Property", "value": "string" },
  "status": { "type": "Property", "value": "planned|active|completed|cancelled" },
  "startTime": { "type": "Property", "value": { "@type": "DateTime", "@value": "ISO8601" } },
  "endTime": { "type": "Property", "value": { "@type": "DateTime", "@value": "ISO8601" } },
  "assignedVehicle": { "type": "Relationship", "object": "urn:ngsi-ld:Vehicle:{id}" },
  "sourceDepot": { "type": "Relationship", "object": "urn:ngsi-ld:Depot:{id}" },
  "destinationDump": { "type": "Relationship", "object": "urn:ngsi-ld:Dump:{id}" }
}
```

---

## NGSI-LD Compliance

EcoCheck implements the following NGSI-LD features:

✅ **Core Context Information Management API**
- Entity CRUD operations
- Property and Relationship attributes
- GeoProperty support

✅ **Context Discovery**
- Entity type queries
- Attribute filtering
- ID pattern matching

✅ **Geospatial Queries**
- Point-based proximity queries
- Distance filtering

✅ **JSON-LD Context**
- Link header context references
- Custom EcoCheck vocabulary
- Standard NGSI-LD core context

⚠️ **Partial Support**
- Temporal API (planned)
- Subscriptions (via Orion-LD integration)
- Batch operations (planned)

---

## Integration with FIWARE Orion-LD

EcoCheck can be integrated with FIWARE Orion-LD Context Broker for:

1. **Real-time subscriptions** - Get notified when entities change
2. **Federation** - Share data across multiple systems
3. **Advanced querying** - Complex temporal and spatial queries

See `backend/src/orionld.js` for integration utilities.

---

## Related Documentation

- [ETSI NGSI-LD Specification](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.06.01_60/gs_CIM009v010601p.pdf)
- [FIWARE NGSI-LD Tutorial](https://ngsi-ld-tutorials.readthedocs.io/)
- [EcoCheck API Documentation](./API.md)
