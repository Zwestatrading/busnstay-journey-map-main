-- ==================== ADD MISSING COLUMNS TO PUBLIC.STOPS ====================
-- This adds all missing columns to make the table match the new schema
-- Data is preserved, new columns are nullable (safe)

-- Add coordinates column (nullable for now, can be backfilled later)
ALTER TABLE public.stops
ADD COLUMN coordinates geography(POINT, 4326);

-- Add other missing columns from the new schema
ALTER TABLE public.stops
ADD COLUMN size TEXT DEFAULT 'medium' CHECK (size IN ('major', 'medium', 'minor'));

ALTER TABLE public.stops
ADD COLUMN geofence_radius INTEGER DEFAULT 1000;

ALTER TABLE public.stops
ADD COLUMN services_available JSONB DEFAULT '{"restaurants": 0, "hotels": 0, "riders": 0, "taxis": 0}'::JSONB;

ALTER TABLE public.stops
ADD COLUMN updated_at TIMESTAMPTZ DEFAULT now();

-- ==================== ADD INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_stops_coordinates ON public.stops USING GIST (coordinates);
CREATE INDEX IF NOT EXISTS idx_stops_town_id ON public.stops(town_id);

-- ==================== VERIFY ====================
-- Check that all columns exist now
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stops'
ORDER BY ordinal_position;
