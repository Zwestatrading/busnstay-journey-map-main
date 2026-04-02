-- ==================== FIX OPTIONS FOR PUBLIC.STOPS ====================
-- Choose OPTION A or OPTION B based on your diagnostic results

-- OPTION A: If stops table has 0 rows (empty)
-- ============================================
-- Run this to add the missing coordinates column as NOT NULL:

ALTER TABLE public.stops
ADD COLUMN coordinates geography(POINT, 4326) NOT NULL;

-- Then create the index:
CREATE INDEX IF NOT EXISTS idx_stops_coordinates
ON public.stops USING GIST (coordinates);


-- OPTION B: If stops table has rows (data exists)
-- ============================================
-- Step 1: Add column as nullable first (safe)

ALTER TABLE public.stops
ADD COLUMN coordinates geography(POINT, 4326);

-- Step 2: Check if you have latitude/longitude columns to backfill from
-- If stops has latitude & longitude columns, run this:

UPDATE public.stops
SET coordinates = ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)::geography
WHERE coordinates IS NULL
  AND latitude IS NOT NULL
  AND longitude IS NOT NULL;

-- Step 3: After backfilling, enforce NOT NULL (optional, only if all rows are filled)
-- ALTER TABLE public.stops ALTER COLUMN coordinates SET NOT NULL;

-- Step 4: Create the index:
CREATE INDEX IF NOT EXISTS idx_stops_coordinates
ON public.stops USING GIST (coordinates);


-- OPTION C: Nuclear reset (only if you can lose all stops data)
-- ============================================
-- This completely recreates the table with proper schema
-- WARNING: ALL DATA IN public.stops WILL BE LOST

DROP TABLE IF EXISTS public.stops CASCADE;

CREATE TABLE IF NOT EXISTS public.stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  town_id TEXT NOT NULL,
  name TEXT NOT NULL,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  region TEXT NOT NULL,
  size TEXT NOT NULL DEFAULT 'medium' CHECK (size IN ('major', 'medium', 'minor')),
  geofence_radius INTEGER NOT NULL DEFAULT 1000,
  services_available JSONB NOT NULL DEFAULT '{"restaurants": 0, "hotels": 0, "riders": 0, "taxis": 0}'::JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_stops_coordinates ON public.stops USING GIST (coordinates);
CREATE INDEX IF NOT EXISTS idx_stops_town_id ON public.stops(town_id);

ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can view stops" ON public.stops FOR SELECT USING (true);
