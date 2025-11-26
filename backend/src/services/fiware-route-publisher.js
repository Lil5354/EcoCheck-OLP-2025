/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * FIWARE Route Publisher Service
 * Publishes routes to FIWARE Orion-LD as NGSI-LD entities
 * Following Smart Data Models for Route entity
 */

const { createEntity, patchAttrs } = require("../orionld");

class FIWARERoutePublisher {
  /**
   * Publish route to FIWARE Orion-LD
   * @param {Object} route - Route data from database
   * @returns {Promise<Object>} Publication result
   */
  async publishRoute(route) {
    try {
      // Build GeoJSON LineString from route stops
      const coordinates = [];
      
      // Add depot (start point)
      if (route.depot_latitude && route.depot_longitude) {
        coordinates.push([route.depot_longitude, route.depot_latitude]);
      }

      // Add stops (ordered by seq)
      if (route.stops && route.stops.length > 0) {
        const sortedStops = route.stops.sort((a, b) => a.seq - b.seq);
        for (const stop of sortedStops) {
          if (stop.latitude && stop.longitude) {
            coordinates.push([stop.longitude, stop.latitude]);
          }
        }
      }

      // Add dump (end point)
      if (route.dump_latitude && route.dump_longitude) {
        coordinates.push([route.dump_longitude, route.dump_latitude]);
      }

      // Build NGSI-LD entity following Smart Data Models
      const entity = {
        id: `urn:ngsi-ld:Route:${route.id}`,
        type: "Route",
        "@context": [
          "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
          "https://smartdatamodels.org/context.jsonld",
        ],
        name: {
          type: "Property",
          value: `Route ${route.id.substring(0, 8)}`,
        },
        description: {
          type: "Property",
          value: `Waste collection route for ${route.scheduled_date || "date"}`,
        },
        routeCode: {
          type: "Property",
          value: route.id,
        },
        transportMode: {
          type: "Property",
          value: "road",
        },
        category: {
          type: "Property",
          value: ["wasteCollection"],
        },
        status: {
          type: "Property",
          value: route.status || "planned",
        },
        startDate: {
          type: "Property",
          value: {
            "@type": "DateTime",
            "@value": route.start_at
              ? new Date(route.start_at).toISOString()
              : new Date().toISOString(),
          },
        },
        distance: {
          type: "Property",
          value: route.planned_distance_km || 0,
          unitCode: "KMT", // Kilometers
        },
        duration: {
          type: "Property",
          value: route.planned_duration_min || 0,
          unitCode: "MIN", // Minutes
        },
        location: {
          type: "GeoProperty",
          value: {
            type: "LineString",
            coordinates: coordinates.length > 0 ? coordinates : [[0, 0]],
          },
        },
        servedBy: route.vehicle_id
          ? {
              type: "Relationship",
              object: `urn:ngsi-ld:Vehicle:${route.vehicle_id}`,
            }
          : undefined,
        driver: route.driver_id
          ? {
              type: "Relationship",
              object: `urn:ngsi-ld:Person:${route.driver_id}`,
            }
          : undefined,
        collector: route.collector_id
          ? {
              type: "Relationship",
              object: `urn:ngsi-ld:Person:${route.collector_id}`,
            }
          : undefined,
        dateCreated: {
          type: "Property",
          value: {
            "@type": "DateTime",
            "@value": route.created_at
              ? new Date(route.created_at).toISOString()
              : new Date().toISOString(),
          },
        },
        dateModified: {
          type: "Property",
          value: {
            "@type": "DateTime",
            "@value": route.updated_at
              ? new Date(route.updated_at).toISOString()
              : new Date().toISOString(),
          },
        },
        // Custom properties for optimization
        optimizationScore: {
          type: "Property",
          value: route.optimization_score || 0,
        },
        totalStops: {
          type: "Property",
          value: route.stops?.length || 0,
        },
      };

      // Remove undefined properties
      Object.keys(entity).forEach(
        (key) => entity[key] === undefined && delete entity[key]
      );

      const result = await createEntity(entity);
      console.log(
        `📡 Published route ${route.id} to FIWARE Orion-LD: ${result.status}`
      );
      return { success: true, status: result.status };
    } catch (error) {
      console.error(`❌ Error publishing route to FIWARE:`, error.message);
      // Don't throw - FIWARE publishing is optional
      return { success: false, error: error.message };
    }
  }

  /**
   * Update route status in FIWARE
   */
  async updateRouteStatus(routeId, status) {
    try {
      const entityId = `urn:ngsi-ld:Route:${routeId}`;
      await patchAttrs(entityId, {
        status: {
          type: "Property",
          value: status,
        },
        dateModified: {
          type: "Property",
          value: {
            "@type": "DateTime",
            "@value": new Date().toISOString(),
          },
        },
      });
      console.log(`📡 Updated route ${routeId} status in FIWARE: ${status}`);
      return { success: true };
    } catch (error) {
      console.error(`❌ Error updating route status in FIWARE:`, error.message);
      return { success: false, error: error.message };
    }
  }
}

module.exports = FIWARERoutePublisher;

