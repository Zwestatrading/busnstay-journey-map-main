-- Get EXACT list of all columns in public.stops
SELECT 
  column_name, 
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'stops'
ORDER BY ordinal_position;
