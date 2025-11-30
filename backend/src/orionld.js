/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * EcoCheck Backend - Orion-LD client utilities
 * FIWARE Orion-LD Context Broker integration
 */

const axios = require('axios');

const ORION_LD_URL = process.env.ORION_LD_URL || 'http://localhost:1026';
const FIWARE_SERVICE = process.env.FIWARE_SERVICE || 'ecocheck';
const FIWARE_SERVICE_PATH = process.env.FIWARE_SERVICE_PATH || '/hcm';

const client = axios.create({
  baseURL: ORION_LD_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/ld+json',
    Accept: 'application/ld+json',
    'FIWARE-Service': FIWARE_SERVICE,
    'FIWARE-ServicePath': FIWARE_SERVICE_PATH,
  },
});

async function createEntity(payload) {
  const { data, status } = await client.post('/ngsi-ld/v1/entities', payload);
  return { data, status };
}

async function queryEntities(params) {
  const { data } = await client.get('/ngsi-ld/v1/entities', { params });
  return data;
}

async function patchAttrs(entityId, attrs) {
  const url = `/ngsi-ld/v1/entities/${encodeURIComponent(entityId)}/attrs`;
  const { status } = await client.patch(url, attrs);
  return { status };
}

async function createSubscription(payload) {
  const { data, status } = await client.post('/ngsi-ld/v1/subscriptions', payload);
  return { data, status };
}

module.exports = {
  client,
  createEntity,
  queryEntities,
  patchAttrs,
  createSubscription,
};

