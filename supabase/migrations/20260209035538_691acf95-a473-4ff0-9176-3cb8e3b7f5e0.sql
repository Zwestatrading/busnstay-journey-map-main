
-- Allow approved restaurant providers to insert their restaurant record
CREATE POLICY "Approved restaurant owners can insert their restaurant"
ON public.restaurants
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.user_id = auth.uid()
      AND up.role = 'restaurant'
      AND up.is_approved = true
      AND up.assigned_station_id = restaurants.stop_id
  )
);

-- Allow approved hotel providers to insert their accommodation record
CREATE POLICY "Approved hotel owners can insert accommodations"
ON public.accommodations
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.user_id = auth.uid()
      AND up.role = 'hotel'
      AND up.is_approved = true
      AND up.assigned_station_id = accommodations.stop_id
  )
);

-- Allow approved hotel owners to update their accommodation
CREATE POLICY "Approved hotel owners can update their accommodation"
ON public.accommodations
FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM user_profiles up
    WHERE up.user_id = auth.uid()
      AND up.role = 'hotel'
      AND up.is_approved = true
      AND up.assigned_station_id = accommodations.stop_id
  )
);

-- Allow approved restaurant owners to insert menu items
CREATE POLICY "Restaurant owners can insert menu items"
ON public.menu_items
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM user_profiles up
    JOIN restaurants r ON r.stop_id = up.assigned_station_id
    WHERE up.user_id = auth.uid()
      AND up.role = 'restaurant'
      AND up.is_approved = true
      AND r.id = menu_items.restaurant_id
  )
);
