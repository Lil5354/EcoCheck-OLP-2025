# CN14 - Master Data Management (NGSI-LD / Orion-LD)

This document specifies the NGSI-LD data models and operational conventions for EcoCheck/DWC Master Data: Fleet (Vehicles), Workers, Depots, and Dumps (Transfer Stations). It targets Orion-LD and is aligned with the competition's Open Standards requirements.

## 1. Orion-LD Runtime
- Broker: fiware/orion-ld (port 1026)
- DB: MongoDB 6+
- Network: docker bridge
- Multi-tenant: use headers FIWARE-Service and FIWARE-ServicePath
- ENV (backend):
  - ORION_LD_URL=http://orion-ld:1026
  - FIWARE_SERVICE=ecocheck
  - FIWARE_SERVICE_PATH=/hcm

## 2. HTTP Headers (always)
- Content-Type: application/ld+json
- Accept: application/ld+json
- FIWARE-Service: ecocheck
- FIWARE-ServicePath: /hcm

## 3. @context
- Core: https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld
- Project: http://localhost:3000/contexts/ecocheck.jsonld
  - Defines: vehicleType, wasteTypes, capacityKg, acceptedWasteTypes, homeDepot, assignedVehicle, assignedRoute, etc.

## 4. Entity Models (Summary)

### 4.1 Depot
- id: urn:ngsi-ld:Depot:<UUID>
- type: Depot
- Properties:
  - name (Text)
  - capacityVehicles (Number, optional)
  - openingHours (Text, optional; schema.org)
- GeoProperty:
  - location (Point [lon, lat])

### 4.2 Dump (Transfer Station)
- id: urn:ngsi-ld:Dump:<UUID>
- type: Dump
- Properties:
  - name (Text)
  - acceptedWasteTypes (List)
  - openingHours (Text, optional)
- GeoProperty:
  - location (Point [lon, lat])

### 4.3 Vehicle
- id: urn:ngsi-ld:Vehicle:<UUID>
- type: Vehicle
- Properties:
  - licensePlate (Text)
  - vehicleType (Text) [garbage_truck_small|garbage_truck_medium|compactor|electric_trike]
  - capacityKg (Number)
  - wasteTypes (List) [household|recyclable|bulky]
  - status (Text) [available|assigned|maintenance|offline]
  - loadKg (Number, optional)
  - fuelType (Text, optional)
- GeoProperty:
  - location (Point [lon, lat])
- Relationships:
  - homeDepot (→ Depot)
  - assignedRoute (→ Route, optional)

### 4.4 Worker
- id: urn:ngsi-ld:Worker:<UUID>
- type: Worker
- Properties:
  - name (Text)
  - role (Text) [driver|collector|supervisor]
  - phone (Text)
  - status (Text) [active|inactive|on_shift|off_shift]
  - certifications (List, optional)
- Relationships:
  - homeDepot (→ Depot)
  - assignedVehicle (→ Vehicle, optional)

## 5. Seed Data
Seed files are provided under seeds/ngsi-ld/cn14/*.jsonld. Minimum set:
- Depots: depot-001, depot-002
- Dump: dump-001
- Vehicles: veh-001 … veh-005
- Workers: wrk-001, wrk-002

## 6. API Endpoints (Orion-LD)
- Create entity: POST /ngsi-ld/v1/entities
- Query entities: GET /ngsi-ld/v1/entities?type=Vehicle
- Update attributes: PATCH /ngsi-ld/v1/entities/{entityId}/attrs
- Subscriptions: POST /ngsi-ld/v1/subscriptions

## 7. cURL Examples
Create Depot:
```
curl -X POST "http://localhost:1026/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -H "Accept: application/ld+json" \
  -H "FIWARE-Service: ecocheck" \
  -H "FIWARE-ServicePath: /hcm" \
  --data @seeds/ngsi-ld/cn14/depot-001.jsonld
```

Query Vehicles:
```
curl -G "http://localhost:1026/ngsi-ld/v1/entities" \
  -H "Accept: application/ld+json" \
  -H "FIWARE-Service: ecocheck" \
  -H "FIWARE-ServicePath: /hcm" \
  --data-urlencode "type=Vehicle"
```

Patch Vehicle status:
```
curl -X PATCH "http://localhost:1026/ngsi-ld/v1/entities/urn:ngsi-ld:Vehicle:veh-001/attrs" \
  -H "Content-Type: application/ld+json" \
  -H "FIWARE-Service: ecocheck" \
  -H "FIWARE-ServicePath: /hcm" \
  --data '{"status":{"type":"Property","value":"assigned"}}'
```

Create Subscription (Vehicle status/location):
```
curl -X POST "http://localhost:1026/ngsi-ld/v1/subscriptions" \
  -H "Content-Type: application/ld+json" \
  -H "Accept: application/ld+json" \
  -H "FIWARE-Service: ecocheck" \
  -H "FIWARE-ServicePath: /hcm" \
  --data '{
    "type": "Subscription",
    "entities": [{ "type": "Vehicle" }],
    "watchedAttributes": ["status", "location"],
    "notification": {
      "endpoint": { "uri": "http://backend:3000/fiware/notify", "accept": "application/ld+json" }
    }
  }'
```

## 8. Conventions
- GeoJSON order: [longitude, latitude]
- Units: kg for capacity/load
- IDs: URN pattern urn:ngsi-ld:<Type>:<slug-or-uuid>
- Tenancy: Use service=ecocheck, servicePath=/hcm (can add more servicePaths per district)

## 9. Acceptance Criteria (AC)
- AC1: Orion-LD + MongoDB start via docker-compose with healthchecks OK.
- AC2: POST seeds returns 201 Created for each entity.
- AC3: GET by type returns schema-compliant JSON-LD, with @context resolvable.
- AC4: PATCH Vehicle.status triggers notification to backend /fiware/notify (visible in logs).
- AC5: Queries scoped by FIWARE-Service/ServicePath return correct partitioned data.

