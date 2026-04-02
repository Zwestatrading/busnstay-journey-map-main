-- ==================== DIAGNOSTIC QUERY 1: Check Public.Stops Columns ====================
-- Run this first to see what schema the stops table actually has

SELECT column_name, data_type, is_nullable, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stops'
ORDER BY ordinal_position;

-- ==================== DIAGNOSTIC QUERY 2: Check Row Count ====================
-- This tells us if the table has data or is empty

SELECT COUNT(*) as row_count FROM public.stops;

-- ==================== DIAGNOSTIC QUERY 3: Sample Data ====================
-- Show first 5 rows to understand the data structure

SELECT * FROM public.stops LIMIT 5;
