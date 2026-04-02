
-- Fix RLS: Allow restaurant owners to manage their restaurant and orders
CREATE POLICY "Restaurant owners can update their restaurant"
  ON public.restaurants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
        AND up.role = 'restaurant'
        AND up.assigned_station_id = restaurants.stop_id
        AND up.is_approved = true
    )
  );

CREATE POLICY "Restaurant owners can update menu items"
  ON public.menu_items FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      JOIN restaurants r ON r.stop_id = up.assigned_station_id
      WHERE up.user_id = auth.uid()
        AND up.role = 'restaurant'
        AND up.is_approved = true
        AND r.id = menu_items.restaurant_id
    )
  );

-- Allow restaurant/rider roles to view and update orders for their station
CREATE POLICY "Restaurant owners can view station orders"
  ON public.orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
        AND up.role IN ('restaurant', 'rider', 'admin')
        AND (up.assigned_station_id = orders.stop_id OR up.role = 'admin')
    )
  );

CREATE POLICY "Restaurant owners can update station orders"
  ON public.orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid()
        AND up.role IN ('restaurant', 'rider')
        AND up.assigned_station_id = orders.stop_id
    )
  );

-- Allow riders to insert and update delivery_agents records
CREATE POLICY "Riders can insert their agent record"
  ON public.delivery_agents FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Riders can update their own record"
  ON public.delivery_agents FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow admin to view all orders
CREATE POLICY "Admins can view all orders"
  ON public.orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid() AND up.role = 'admin'
    )
  );

-- Allow system_health_events to be updated by admins
CREATE POLICY "Admins can update health events"
  ON public.system_health_events FOR UPDATE
  USING (has_role(auth.uid(), 'admin'::text));

-- Allow restaurants to be inserted (when admin approves and creates the restaurant record)
CREATE POLICY "Admins can insert restaurants"
  ON public.restaurants FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid() AND up.role = 'admin'
    )
  );

-- Allow admin to insert menu items
CREATE POLICY "Admins can insert menu items"
  ON public.menu_items FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.user_id = auth.uid() AND up.role = 'admin'
    )
  );
