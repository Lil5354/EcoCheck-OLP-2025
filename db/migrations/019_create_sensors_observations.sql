/*
 * MIT License
 * Copyright (c) 2025 Lil5354
 *
 * Migration: Create sensors and observations tables for SOSA/SSN Ontology
 * Supports Smart Container Monitoring with IoT sensors
 */

-- Create sensors table (SOSA Sensor)
CREATE TABLE IF NOT EXISTS sensors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    container_id VARCHAR(255) NOT NULL, -- References collection point (points.id) or schedule ID
    sensor_type VARCHAR(50) NOT NULL DEFAULT 'fill_level', -- fill_level, temperature, weight, etc.
    name VARCHAR(255),
    unit VARCHAR(50) DEFAULT 'percent', -- percent, kg, celsius, etc.
    status VARCHAR(50) DEFAULT 'active', -- active, inactive, maintenance
    metadata JSONB, -- Additional sensor metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    
    -- Note: container_id references points.id (UUID as text) or schedule IDs
    -- No foreign key constraint to allow flexibility
);

-- Create observations table (SOSA Observation)
CREATE TABLE IF NOT EXISTS observations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sensor_id UUID NOT NULL,
    observed_property VARCHAR(100) NOT NULL DEFAULT 'fillLevel', -- fillLevel, temperature, weight, etc.
    result_value NUMERIC(10, 2) NOT NULL, -- The actual measurement value
    result_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    unit VARCHAR(50) DEFAULT 'percent',
    feature_of_interest VARCHAR(255), -- References the container or location
    procedure VARCHAR(255), -- Measurement procedure/method
    quality VARCHAR(50), -- good, fair, poor
    metadata JSONB, -- Additional observation metadata
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_observation_sensor FOREIGN KEY (sensor_id) 
        REFERENCES sensors(id) ON DELETE CASCADE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sensors_container_id ON sensors(container_id);
CREATE INDEX IF NOT EXISTS idx_sensors_type ON sensors(sensor_type);
CREATE INDEX IF NOT EXISTS idx_sensors_status ON sensors(status);

CREATE INDEX IF NOT EXISTS idx_observations_sensor_id ON observations(sensor_id);
CREATE INDEX IF NOT EXISTS idx_observations_result_time ON observations(result_time DESC);
CREATE INDEX IF NOT EXISTS idx_observations_property ON observations(observed_property);
CREATE INDEX IF NOT EXISTS idx_observations_feature ON observations(feature_of_interest);

-- Create composite index for latest observation queries
CREATE INDEX IF NOT EXISTS idx_observations_sensor_time ON observations(sensor_id, result_time DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_sensors_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updated_at
CREATE TRIGGER trigger_update_sensors_updated_at
    BEFORE UPDATE ON sensors
    FOR EACH ROW
    EXECUTE FUNCTION update_sensors_updated_at();

-- Insert sample sensors for existing containers (optional)
-- This creates mock sensors for testing
DO $$
DECLARE
    container_record RECORD;
    sensor_id_val UUID;
BEGIN
    -- Create sensors for first 10 collection points (for testing)
    FOR container_record IN 
        SELECT id::text as id FROM points LIMIT 10
    LOOP
        INSERT INTO sensors (container_id, sensor_type, name, unit, status)
        VALUES (
            container_record.id,
            'fill_level',
            'Fill Level Sensor ' || container_record.id,
            'percent',
            'active'
        )
        RETURNING id INTO sensor_id_val;
        
        -- Insert sample observations
        INSERT INTO observations (sensor_id, observed_property, result_value, result_time, unit, feature_of_interest)
        VALUES (
            sensor_id_val,
            'fillLevel',
            ROUND((RANDOM() * 100)::NUMERIC, 2), -- Random fill level 0-100%
            CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '7 days'), -- Random time in last 7 days
            'percent',
            container_record.id
        );
    END LOOP;
END $$;

-- Add comment
COMMENT ON TABLE sensors IS 'SOSA Sensor entities for IoT waste container monitoring';
COMMENT ON TABLE observations IS 'SOSA Observation entities for sensor measurements';
COMMENT ON COLUMN sensors.container_id IS 'References WasteContainer entity ID';
COMMENT ON COLUMN observations.sensor_id IS 'References Sensor entity ID';
COMMENT ON COLUMN observations.observed_property IS 'SOSA observedProperty (e.g., fillLevel, temperature)';
COMMENT ON COLUMN observations.result_value IS 'SOSA hasResult - the measurement value';
COMMENT ON COLUMN observations.result_time IS 'SOSA resultTime - when the observation was made';
COMMENT ON COLUMN observations.feature_of_interest IS 'SOSA hasFeatureOfInterest - the container or location being observed';

