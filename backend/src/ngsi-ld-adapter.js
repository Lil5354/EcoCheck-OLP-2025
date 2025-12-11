/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - NGSI-LD Adapter
 * Utilities to convert between database format and NGSI-LD format
 */

const CONTEXT_URL = process.env.CONTEXT_URL || 'http://localhost:3000/contexts/ecocheck.jsonld';
const NGSI_LD_CORE_CONTEXT = 'https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld';

/**
 * Convert database record to NGSI-LD entity
 * @param {string} type - Entity type (Vehicle, Worker, etc.)
 * @param {object} data - Database record
 * @param {object} options - Conversion options
 * @returns {object} NGSI-LD entity
 */
function toNGSILD(type, data, options = {}) {
  const { idPrefix, includeContext = true } = options;
  
  const entity = {
    id: data.id ? (data.id.startsWith('urn:') ? data.id : `urn:ngsi-ld:${type}:${data.id}`) : undefined,
    type: type,
  };

  // Add @context if requested
  if (includeContext) {
    entity['@context'] = [
      NGSI_LD_CORE_CONTEXT,
      CONTEXT_URL
    ];
  }

  // Convert properties and relationships based on entity type
  switch (type) {
    case 'Vehicle':
      convertVehicle(entity, data);
      break;
    case 'Worker':
      convertWorker(entity, data);
      break;
    case 'Depot':
      convertDepot(entity, data);
      break;
    case 'Dump':
      convertDump(entity, data);
      break;
    case 'Route':
      convertRoute(entity, data);
      break;
    case 'WastePoint':
      convertWastePoint(entity, data);
      break;
    case 'Alert':
      convertAlert(entity, data);
      break;
    case 'CheckIn':
      convertCheckIn(entity, data);
      break;
    default:
      // Generic conversion
      convertGeneric(entity, data);
  }

  return entity;
}

/**
 * Convert Vehicle database record to NGSI-LD
 */
function convertVehicle(entity, data) {
  if (data.plate) {
    entity.licensePlate = { type: 'Property', value: data.plate };
  }
  if (data.type) {
    entity.vehicleType = { type: 'Property', value: data.type };
  }
  if (data.capacity_kg !== undefined) {
    entity.capacityKg = { type: 'Property', value: parseFloat(data.capacity_kg) };
  }
  if (data.accepted_types) {
    entity.wasteTypes = { type: 'Property', value: data.accepted_types };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }
  if (data.current_load_kg !== undefined) {
    entity.loadKg = { type: 'Property', value: parseFloat(data.current_load_kg) };
  }
  if (data.fuel_type) {
    entity.fuelType = { type: 'Property', value: data.fuel_type };
  }
  
  // Relationships
  if (data.depot_id) {
    entity.homeDepot = { 
      type: 'Relationship', 
      object: data.depot_id.startsWith('urn:') ? data.depot_id : `urn:ngsi-ld:Depot:${data.depot_id}`
    };
  }

  // Location (GeoProperty)
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  // Timestamps
  addTimestamps(entity, data);
}

/**
 * Convert Worker database record to NGSI-LD
 */
function convertWorker(entity, data) {
  if (data.full_name || data.name) {
    entity.name = { type: 'Property', value: data.full_name || data.name };
  }
  if (data.role) {
    entity.role = { type: 'Property', value: data.role };
  }
  if (data.phone) {
    entity.phone = { type: 'Property', value: data.phone };
  }
  if (data.email) {
    entity.email = { type: 'Property', value: data.email };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }

  // Relationships
  if (data.depot_id) {
    entity.homeDepot = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Depot:${data.depot_id}`
    };
  }
  if (data.group_id) {
    entity.assignedGroup = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Group:${data.group_id}`
    };
  }

  addTimestamps(entity, data);
}

/**
 * Convert Depot database record to NGSI-LD
 */
function convertDepot(entity, data) {
  if (data.name) {
    entity.name = { type: 'Property', value: data.name };
  }
  if (data.address || data.address_text) {
    entity.address = { type: 'Property', value: data.address || data.address_text };
  }
  if (data.capacity !== undefined || data.capacity_vehicles !== undefined) {
    entity.capacityVehicles = { 
      type: 'Property', 
      value: parseInt(data.capacity || data.capacity_vehicles) 
    };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }

  // Location
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  addTimestamps(entity, data);
}

/**
 * Convert Dump database record to NGSI-LD
 */
function convertDump(entity, data) {
  if (data.name) {
    entity.name = { type: 'Property', value: data.name };
  }
  if (data.address) {
    entity.address = { type: 'Property', value: data.address };
  }
  if (data.accepted_types) {
    entity.acceptedWasteTypes = { type: 'Property', value: data.accepted_types };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }

  // Location
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  addTimestamps(entity, data);
}

/**
 * Convert Route database record to NGSI-LD
 */
function convertRoute(entity, data) {
  if (data.name) {
    entity.name = { type: 'Property', value: data.name };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }
  if (data.start_at) {
    entity.startTime = { 
      type: 'Property', 
      value: { '@type': 'DateTime', '@value': data.start_at }
    };
  }
  if (data.end_at) {
    entity.endTime = { 
      type: 'Property', 
      value: { '@type': 'DateTime', '@value': data.end_at }
    };
  }

  // Relationships
  if (data.vehicle_id) {
    entity.assignedVehicle = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Vehicle:${data.vehicle_id}`
    };
  }
  if (data.depot_id) {
    entity.sourceDepot = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Depot:${data.depot_id}`
    };
  }
  if (data.dump_id) {
    entity.destinationDump = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Dump:${data.dump_id}`
    };
  }

  addTimestamps(entity, data);
}

/**
 * Convert WastePoint database record to NGSI-LD
 */
function convertWastePoint(entity, data) {
  if (data.address || data.address_text) {
    entity.address = { type: 'Property', value: data.address || data.address_text };
  }
  if (data.last_waste_type) {
    entity.wasteType = { type: 'Property', value: data.last_waste_type };
  }
  if (data.last_level !== undefined) {
    entity.fillingLevel = { type: 'Property', value: parseFloat(data.last_level) };
  }
  if (data.ghost !== undefined) {
    entity.status = { 
      type: 'Property', 
      value: data.ghost ? 'inactive' : 'active' 
    };
  }

  // Location
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  // Observed timestamp
  if (data.last_checkin_at) {
    entity.location.observedAt = data.last_checkin_at;
  }

  addTimestamps(entity, data);
}

/**
 * Convert Alert database record to NGSI-LD
 */
function convertAlert(entity, data) {
  if (data.alert_type) {
    entity.alertType = { type: 'Property', value: data.alert_type };
  }
  if (data.severity) {
    entity.severity = { type: 'Property', value: data.severity };
  }
  if (data.status) {
    entity.status = { type: 'Property', value: data.status };
  }
  if (data.description) {
    entity.description = { type: 'Property', value: data.description };
  }
  if (data.details) {
    entity.details = { 
      type: 'Property', 
      value: typeof data.details === 'string' ? JSON.parse(data.details) : data.details 
    };
  }

  // Relationships
  if (data.point_id) {
    entity.targetPoint = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:WastePoint:${data.point_id}`
    };
  }
  if (data.route_id) {
    entity.relatedRoute = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:Route:${data.route_id}`
    };
  }

  // Location
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  addTimestamps(entity, data);
}

/**
 * Convert CheckIn database record to NGSI-LD
 */
function convertCheckIn(entity, data) {
  if (data.waste_type) {
    entity.wasteType = { type: 'Property', value: data.waste_type };
  }
  if (data.filling_level !== undefined) {
    entity.fillingLevel = { type: 'Property', value: parseFloat(data.filling_level) };
  }
  if (data.photo_url) {
    entity.photoUrl = { type: 'Property', value: data.photo_url };
  }
  if (data.source) {
    entity.source = { type: 'Property', value: data.source };
  }

  // Relationships
  if (data.point_id) {
    entity.targetPoint = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:WastePoint:${data.point_id}`
    };
  }
  if (data.user_id) {
    entity.reportedBy = { 
      type: 'Relationship', 
      object: `urn:ngsi-ld:User:${data.user_id}`
    };
  }

  // Location
  if (data.lat !== undefined && data.lon !== undefined) {
    entity.location = {
      type: 'GeoProperty',
      value: {
        type: 'Point',
        coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
      }
    };
  }

  addTimestamps(entity, data);
}

/**
 * Generic conversion for unknown entity types
 */
function convertGeneric(entity, data) {
  for (const [key, value] of Object.entries(data)) {
    if (key === 'id' || key === 'type') continue;
    
    if (value !== null && value !== undefined) {
      if (key.includes('_id') || key.endsWith('Id')) {
        // Relationship
        const relationshipName = key.replace(/_id$/, '').replace(/Id$/, '');
        entity[relationshipName] = { 
          type: 'Relationship', 
          object: `urn:ngsi-ld:Entity:${value}`
        };
      } else if ((key === 'lat' && data.lon !== undefined) || (key === 'lon' && data.lat !== undefined)) {
        // Skip - will be handled together as location
        if (key === 'lat' && !entity.location) {
          entity.location = {
            type: 'GeoProperty',
            value: {
              type: 'Point',
              coordinates: [parseFloat(data.lon), parseFloat(data.lat)]
            }
          };
        }
      } else if (key.includes('_at') || key.endsWith('At') || key.includes('time') || key.includes('date')) {
        // DateTime property
        entity[key] = { 
          type: 'Property', 
          value: { '@type': 'DateTime', '@value': value }
        };
      } else {
        // Regular property
        entity[key] = { type: 'Property', value: value };
      }
    }
  }
}

/**
 * Add standard NGSI-LD timestamps
 */
function addTimestamps(entity, data) {
  if (data.created_at) {
    entity.createdAt = data.created_at;
  }
  if (data.updated_at) {
    entity.modifiedAt = data.updated_at;
  }
}

/**
 * Convert NGSI-LD entity to database format
 * @param {object} entity - NGSI-LD entity
 * @returns {object} Database record
 */
function fromNGSILD(entity) {
  const data = {
    id: entity.id ? entity.id.replace(/^urn:ngsi-ld:\w+:/, '') : undefined,
  };

  for (const [key, value] of Object.entries(entity)) {
    if (key === '@context' || key === 'id' || key === 'type') continue;

    if (value.type === 'Property') {
      // Extract value from Property
      if (value.value && typeof value.value === 'object' && value.value['@type'] === 'DateTime') {
        data[key] = value.value['@value'];
      } else {
        data[key] = value.value;
      }
    } else if (value.type === 'Relationship') {
      // Extract ID from Relationship
      const relationshipId = value.object.replace(/^urn:ngsi-ld:\w+:/, '');
      data[`${key}_id`] = relationshipId;
    } else if (value.type === 'GeoProperty') {
      // Extract coordinates
      if (value.value && value.value.coordinates) {
        data.lon = value.value.coordinates[0];
        data.lat = value.value.coordinates[1];
      }
    }
  }

  return data;
}

/**
 * Validate NGSI-LD entity structure
 * @param {object} entity - Entity to validate
 * @returns {object} { valid: boolean, errors: string[] }
 */
function validateNGSILD(entity) {
  const errors = [];

  if (!entity.id) {
    errors.push('Missing required field: id');
  } else if (!entity.id.startsWith('urn:ngsi-ld:')) {
    errors.push('Invalid id format: must start with urn:ngsi-ld:');
  }

  if (!entity.type) {
    errors.push('Missing required field: type');
  }

  // Validate properties and relationships
  for (const [key, value] of Object.entries(entity)) {
    if (key === '@context' || key === 'id' || key === 'type') continue;

    if (!value || typeof value !== 'object') {
      errors.push(`Invalid attribute ${key}: must be an object`);
      continue;
    }

    if (!value.type) {
      errors.push(`Invalid attribute ${key}: missing type field`);
      continue;
    }

    if (!['Property', 'Relationship', 'GeoProperty'].includes(value.type)) {
      errors.push(`Invalid attribute ${key}: type must be Property, Relationship, or GeoProperty`);
    }

    if (value.type === 'Property' && value.value === undefined) {
      errors.push(`Invalid attribute ${key}: Property must have a value field`);
    }

    if (value.type === 'Relationship' && !value.object) {
      errors.push(`Invalid attribute ${key}: Relationship must have an object field`);
    }

    if (value.type === 'GeoProperty' && !value.value) {
      errors.push(`Invalid attribute ${key}: GeoProperty must have a value field`);
    }
  }

  return {
    valid: errors.length === 0,
    errors
  };
}

module.exports = {
  toNGSILD,
  fromNGSILD,
  validateNGSILD,
  CONTEXT_URL,
  NGSI_LD_CORE_CONTEXT
};
