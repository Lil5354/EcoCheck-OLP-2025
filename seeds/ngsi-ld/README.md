# NGSI-LD Seed Data

This directory contains NGSI-LD compliant entity definitions for initializing the EcoCheck system.

## Structure

```
seeds/ngsi-ld/
└── cn14/                    # Challenge 14 - Waste Management
    ├── vehicle-*.jsonld     # Vehicle entities
    ├── worker-*.jsonld      # Worker entities
    ├── depot-*.jsonld       # Depot entities
    ├── dump-*.jsonld        # Dump site entities
    ├── route-*.jsonld       # Route entities
    ├── wastepoint-*.jsonld  # Waste collection point entities
    ├── alert-*.jsonld       # Alert entities
    ├── checkin-*.jsonld     # Check-in entities
    └── schedule-*.jsonld    # Schedule entities
```

## Entity Types

### 1. Vehicle
Waste collection vehicles with capacity, type, and status information.

**Example:** `vehicle-001.jsonld`
```json
{
  "@context": [...],
  "id": "urn:ngsi-ld:Vehicle:veh-001",
  "type": "Vehicle",
  "licensePlate": { "type": "Property", "value": "59A-123.45" },
  "vehicleType": { "type": "Property", "value": "garbage_truck_small" },
  "capacityKg": { "type": "Property", "value": 1500 },
  "location": { "type": "GeoProperty", ... },
  "homeDepot": { "type": "Relationship", "object": "urn:ngsi-ld:Depot:depot-001" }
}
```

### 2. Worker
Collection personnel with roles and assignments.

**Example:** `worker-001.jsonld`

### 3. Depot
Vehicle depots/stations where vehicles are based.

**Example:** `depot-001.jsonld`

### 4. Dump
Waste disposal/landfill sites.

**Example:** `dump-001.jsonld`

### 5. Route
Collection routes with start/end times and assignments.

**Example:** `route-001.jsonld`

### 6. WastePoint
Individual waste collection points with location and status.

**Example:** `wastepoint-001.jsonld`

### 7. Alert
System alerts for missed collections, overdue points, etc.

**Example:** `alert-001.jsonld`

### 8. CheckIn
Waste collection check-ins with photo evidence.

**Example:** `checkin-001.jsonld`

### 9. Schedule
Recurring collection schedules.

**Example:** `schedule-001.jsonld`

## Loading Seed Data

### Using curl

```bash
# Load a single entity
curl -X POST "http://localhost:3000/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -d @seeds/ngsi-ld/cn14/vehicle-001.jsonld

# Load all vehicles
for file in seeds/ngsi-ld/cn14/vehicle-*.jsonld; do
  curl -X POST "http://localhost:3000/ngsi-ld/v1/entities" \
    -H "Content-Type: application/ld+json" \
    -d @$file
  echo "Loaded $file"
done
```

### Using Node.js script

```javascript
const fs = require('fs');
const axios = require('axios');

const API_URL = 'http://localhost:3000/ngsi-ld/v1/entities';
const SEED_DIR = './seeds/ngsi-ld/cn14';

async function loadSeedData() {
  const files = fs.readdirSync(SEED_DIR).filter(f => f.endsWith('.jsonld'));
  
  for (const file of files) {
    const data = JSON.parse(fs.readFileSync(`${SEED_DIR}/${file}`, 'utf8'));
    try {
      await axios.post(API_URL, data, {
        headers: { 'Content-Type': 'application/ld+json' }
      });
      console.log(`✅ Loaded ${file}`);
    } catch (error) {
      console.error(`❌ Failed to load ${file}:`, error.response?.data || error.message);
    }
  }
}

loadSeedData();
```

## Context Definition

All entities use the EcoCheck JSON-LD context:
```
http://localhost:3000/contexts/ecocheck.jsonld
```

This context defines:
- Entity types (Vehicle, Worker, etc.)
- Property types (licensePlate, capacityKg, etc.)
- Relationship types (homeDepot, assignedVehicle, etc.)
- GeoProperty mappings

See `backend/public/contexts/ecocheck.jsonld` for the full context definition.

## NGSI-LD Compliance

These seed files are compliant with:
- **ETSI GS CIM 009 V1.6.1** - NGSI-LD API specification
- **JSON-LD 1.1** - JSON-based Linked Data format
- **GeoJSON** - Geospatial data encoding (for GeoProperty values)

## Validation

To validate an NGSI-LD entity:

```javascript
const { validateNGSILD } = require('../backend/src/ngsi-ld-adapter');

const entity = JSON.parse(fs.readFileSync('vehicle-001.jsonld', 'utf8'));
const validation = validateNGSILD(entity);

if (validation.valid) {
  console.log('✅ Valid NGSI-LD entity');
} else {
  console.error('❌ Validation errors:', validation.errors);
}
```

## References

- [NGSI-LD API Documentation](../docs/NGSI-LD.md)
- [ETSI NGSI-LD Specification](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.06.01_60/gs_CIM009v010601p.pdf)
- [FIWARE Smart Data Models](https://github.com/smart-data-models)
- [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/)
