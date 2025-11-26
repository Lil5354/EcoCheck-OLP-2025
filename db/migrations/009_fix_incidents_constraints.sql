-- 009_fix_incidents_constraints.sql
-- Fix incidents table: add default UUID and update type constraints

BEGIN;

-- Add default UUID generation for id column
ALTER TABLE incidents ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Drop old type constraint
ALTER TABLE incidents DROP CONSTRAINT IF EXISTS incidents_type_check;

-- Add updated type constraint with worker_not_collected
ALTER TABLE incidents ADD CONSTRAINT incidents_type_check 
CHECK (type = ANY (ARRAY[
  'illegal_dump'::text,
  'wrong_classification'::text,
  'overloaded_bin'::text,
  'littering'::text,
  'burning_waste'::text,
  'worker_not_collected'::text,
  'broken_bin'::text,
  'damaged_equipment'::text,
  'road_damage'::text,
  'facility_damage'::text,
  'missed_collection'::text,
  'overflow'::text,
  'vehicle_issue'::text,
  'other'::text
]));

COMMENT ON CONSTRAINT incidents_type_check ON incidents IS 
'Valid incident types for both violation and damage categories';

COMMIT;
