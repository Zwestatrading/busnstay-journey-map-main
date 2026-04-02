-- =============================================
-- BusNStay Production-Grade Backend Infrastructure
-- =============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- =============================================
-- 1. CORE ENTITIES
-- =============================================

-- Buses table - represents physical buses
CREATE TABLE IF NOT EXISTS public.buses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_number TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  capacity INTEGER NOT NULL DEFAULT 50,
  current_route_id UUID,
  current_position GEOGRAPHY(POINT, 4326),
  heading DECIMAL(5,2) DEFAULT 0,
  speed DECIMAL(5,2) DEFAULT 0,
  last_gps_update TIMESTAMPTZ DEFAULT now(),
  status TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'maintenance')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Routes table - defines bus routes
CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  from_town TEXT NOT NULL,
  to_town TEXT NOT NULL,
  total_distance DECIMAL(10,2) NOT NULL,
  estimated_duration INTEGER NOT NULL, -- minutes
  waypoints JSONB NOT NULL DEFAULT '[]'::JSONB, -- Array of town IDs in order
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Add foreign key for bus current route
ALTER TABLE public.buses 
ADD CONSTRAINT fk_buses_current_route 
FOREIGN KEY (current_route_id) REFERENCES public.routes(id) ON DELETE SET NULL;

-- Stops table - bus stops/stations along routes
CREATE TABLE IF NOT EXISTS public.stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  town_id TEXT NOT NULL,
  name TEXT NOT NULL,
  coordinates GEOGRAPHY(POINT, 4326) NOT NULL,
  region TEXT NOT NULL,
  size TEXT NOT NULL DEFAULT 'medium' CHECK (size IN ('major', 'medium', 'minor')),
  geofence_radius INTEGER NOT NULL DEFAULT 1000, -- meters
  services_available JSONB NOT NULL DEFAULT '{"restaurants": 0, "hotels": 0, "riders": 0, "taxis": 0}'::JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Route stops junction table (which stops belong to which routes)
CREATE TABLE IF NOT EXISTS public.route_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  sequence_order INTEGER NOT NULL,
  distance_from_start DECIMAL(10,2) NOT NULL DEFAULT 0,
  estimated_time_from_start INTEGER NOT NULL DEFAULT 0, -- minutes
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(route_id, stop_id),
  UNIQUE(route_id, sequence_order)
);

-- =============================================
-- 2. JOURNEY TRACKING
-- =============================================

-- Active journeys - represents a bus currently on a route
CREATE TABLE IF NOT EXISTS public.journeys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id UUID NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  departure_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  estimated_arrival TIMESTAMPTZ,
  actual_arrival TIMESTAMPTZ,
  current_stop_id UUID REFERENCES public.stops(id),
  next_stop_id UUID REFERENCES public.stops(id),
  progress DECIMAL(5,2) DEFAULT 0, -- 0-100
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled', 'delayed')),
  delay_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Passengers on journeys
CREATE TABLE IF NOT EXISTS public.journey_passengers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  boarding_stop_id UUID REFERENCES public.stops(id),
  alighting_stop_id UUID REFERENCES public.stops(id),
  seat_number TEXT,
  current_position GEOGRAPHY(POINT, 4326),
  last_gps_update TIMESTAMPTZ,
  boarding_status TEXT DEFAULT 'pending' CHECK (boarding_status IN ('pending', 'boarded', 'alighted', 'no_show')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- GPS position history for buses (for aggregation and accuracy)
CREATE TABLE IF NOT EXISTS public.gps_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('bus', 'passenger', 'agent')),
  source_id UUID NOT NULL, -- bus_id, passenger_id, or agent_id
  position GEOGRAPHY(POINT, 4326) NOT NULL,
  accuracy DECIMAL(10,2),
  heading DECIMAL(5,2),
  speed DECIMAL(5,2),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Journey ETAs per stop (predictive)
CREATE TABLE IF NOT EXISTS public.journey_etas (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  predicted_arrival TIMESTAMPTZ NOT NULL,
  confidence DECIMAL(5,2) DEFAULT 0.8,
  is_delayed BOOLEAN DEFAULT false,
  delay_minutes INTEGER DEFAULT 0,
  last_calculated TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(journey_id, stop_id)
);

-- =============================================
-- 3. DELIVERY AGENTS
-- =============================================

CREATE TABLE IF NOT EXISTS public.delivery_agents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  current_stop_id UUID REFERENCES public.stops(id),
  current_position GEOGRAPHY(POINT, 4326),
  heading DECIMAL(5,2),
  status TEXT NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'busy', 'on_delivery')),
  rating DECIMAL(3,2) DEFAULT 5.0,
  total_deliveries INTEGER DEFAULT 0,
  last_gps_update TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- 4. RESTAURANTS & MENUS
-- =============================================

CREATE TABLE IF NOT EXISTS public.restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  cuisine TEXT,
  rating DECIMAL(3,2) DEFAULT 4.0,
  price_range TEXT DEFAULT '$$',
  average_prep_time INTEGER DEFAULT 15, -- minutes
  is_open BOOLEAN DEFAULT true,
  opening_hours JSONB DEFAULT '{"open": "06:00", "close": "22:00"}'::JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  prep_time INTEGER DEFAULT 10, -- minutes
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- 5. ORDERS
-- =============================================

CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  journey_id UUID REFERENCES public.journeys(id),
  journey_passenger_id UUID REFERENCES public.journey_passengers(id),
  restaurant_id UUID NOT NULL REFERENCES public.restaurants(id),
  stop_id UUID NOT NULL REFERENCES public.stops(id),
  delivery_agent_id UUID REFERENCES public.delivery_agents(id),
  items JSONB NOT NULL DEFAULT '[]'::JSONB,
  subtotal DECIMAL(10,2) NOT NULL,
  delivery_fee DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery', 'delivered', 'cancelled')),
  estimated_ready_time TIMESTAMPTZ,
  actual_ready_time TIMESTAMPTZ,
  delivery_type TEXT DEFAULT 'pickup' CHECK (delivery_type IN ('pickup', 'bus_delivery')),
  special_instructions TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- 6. ACCOMMODATIONS
-- =============================================

CREATE TABLE IF NOT EXISTS public.accommodations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT DEFAULT 'hotel' CHECK (type IN ('hotel', 'lodge', 'guesthouse', 'hostel')),
  rating DECIMAL(3,2) DEFAULT 4.0,
  price_per_night DECIMAL(10,2) NOT NULL,
  distance_from_stop DECIMAL(5,2), -- km
  amenities JSONB DEFAULT '[]'::JSONB,
  is_night_arrival_friendly BOOLEAN DEFAULT false,
  rooms_available INTEGER DEFAULT 0,
  contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.accommodation_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  accommodation_id UUID NOT NULL REFERENCES public.accommodations(id),
  journey_id UUID REFERENCES public.journeys(id),
  check_in_date DATE NOT NULL,
  check_out_date DATE NOT NULL,
  guests INTEGER DEFAULT 1,
  total_price DECIMAL(10,2) NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- 7. ALERTS & DISRUPTIONS
-- =============================================

CREATE TABLE IF NOT EXISTS public.journey_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN ('delay', 'reroute', 'mechanical', 'weather', 'traffic', 'delivery_issue', 'stop_skip')),
  severity TEXT DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  affected_stop_id UUID REFERENCES public.stops(id),
  location GEOGRAPHY(POINT, 4326),
  is_resolved BOOLEAN DEFAULT false,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ
);

-- =============================================
-- 8. SHARED JOURNEY LINKS
-- =============================================

CREATE TABLE IF NOT EXISTS public.shared_journey_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_passenger_id UUID NOT NULL REFERENCES public.journey_passengers(id) ON DELETE CASCADE,
  share_code TEXT NOT NULL UNIQUE,
  created_by_user_id UUID NOT NULL,
  viewer_name TEXT, -- Optional name for who it's shared with
  permissions JSONB DEFAULT '{"view_location": true, "view_eta": true, "view_stops": true, "view_orders": false}'::JSONB,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  views_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- 9. HISTORICAL DATA FOR ETA PREDICTIONS
-- =============================================

CREATE TABLE IF NOT EXISTS public.route_performance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  from_stop_id UUID NOT NULL REFERENCES public.stops(id),
  to_stop_id UUID NOT NULL REFERENCES public.stops(id),
  day_of_week INTEGER NOT NULL, -- 0-6
  hour_of_day INTEGER NOT NULL, -- 0-23
  average_duration INTEGER NOT NULL, -- minutes
  samples_count INTEGER DEFAULT 1,
  last_updated TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

CREATE INDEX idx_buses_current_position ON public.buses USING GIST (current_position);
CREATE INDEX idx_buses_status ON public.buses(status);
CREATE INDEX idx_stops_coordinates ON public.stops USING GIST (coordinates);
CREATE INDEX idx_stops_town_id ON public.stops(town_id);
CREATE INDEX idx_journeys_bus_id ON public.journeys(bus_id);
CREATE INDEX idx_journeys_status ON public.journeys(status);
CREATE INDEX idx_journey_passengers_journey_id ON public.journey_passengers(journey_id);
CREATE INDEX idx_journey_passengers_user_id ON public.journey_passengers(user_id);
CREATE INDEX idx_gps_history_journey_id ON public.gps_history(journey_id);
CREATE INDEX idx_gps_history_recorded_at ON public.gps_history(recorded_at);
CREATE INDEX idx_delivery_agents_current_position ON public.delivery_agents USING GIST (current_position);
CREATE INDEX idx_delivery_agents_stop_id ON public.delivery_agents(current_stop_id);
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_journey_id ON public.orders(journey_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_restaurants_stop_id ON public.restaurants(stop_id);
CREATE INDEX idx_shared_links_share_code ON public.shared_journey_links(share_code);

-- =============================================
-- ENABLE RLS ON ALL TABLES
-- =============================================

ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_passengers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gps_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_etas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accommodations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accommodation_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_journey_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.route_performance_history ENABLE ROW LEVEL SECURITY;

-- =============================================
-- RLS POLICIES
-- =============================================

-- Public read access for reference data
CREATE POLICY "Anyone can view buses" ON public.buses FOR SELECT USING (true);
CREATE POLICY "Anyone can view routes" ON public.routes FOR SELECT USING (true);
CREATE POLICY "Anyone can view stops" ON public.stops FOR SELECT USING (true);
CREATE POLICY "Anyone can view route_stops" ON public.route_stops FOR SELECT USING (true);
CREATE POLICY "Anyone can view active journeys" ON public.journeys FOR SELECT USING (true);
CREATE POLICY "Anyone can view restaurants" ON public.restaurants FOR SELECT USING (true);
CREATE POLICY "Anyone can view menu items" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Anyone can view accommodations" ON public.accommodations FOR SELECT USING (true);
CREATE POLICY "Anyone can view journey ETAs" ON public.journey_etas FOR SELECT USING (true);
CREATE POLICY "Anyone can view journey alerts" ON public.journey_alerts FOR SELECT USING (true);
CREATE POLICY "Anyone can view delivery agents" ON public.delivery_agents FOR SELECT USING (true);

-- Journey passengers - users can see their own
CREATE POLICY "Users can view their passenger records" ON public.journey_passengers 
FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their passenger records" ON public.journey_passengers 
FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their passenger records" ON public.journey_passengers 
FOR UPDATE USING (auth.uid() = user_id);

-- GPS history - only system can write, passengers can read their journey's history
CREATE POLICY "Users can view GPS history for their journeys" ON public.gps_history 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.journey_passengers jp 
    WHERE jp.journey_id = gps_history.journey_id 
    AND jp.user_id = auth.uid()
  )
);
CREATE POLICY "Authenticated users can insert GPS history" ON public.gps_history 
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Orders - users can manage their own
CREATE POLICY "Users can view their orders" ON public.orders 
FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create orders" ON public.orders 
FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their orders" ON public.orders 
FOR UPDATE USING (auth.uid() = user_id);

-- Accommodation bookings - users can manage their own
CREATE POLICY "Users can view their bookings" ON public.accommodation_bookings 
FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create bookings" ON public.accommodation_bookings 
FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their bookings" ON public.accommodation_bookings 
FOR UPDATE USING (auth.uid() = user_id);

-- Shared journey links - creators can manage, anyone with code can view via function
CREATE POLICY "Users can view their shared links" ON public.shared_journey_links 
FOR SELECT USING (auth.uid() = created_by_user_id);
CREATE POLICY "Users can create shared links" ON public.shared_journey_links 
FOR INSERT WITH CHECK (auth.uid() = created_by_user_id);
CREATE POLICY "Users can update their shared links" ON public.shared_journey_links 
FOR UPDATE USING (auth.uid() = created_by_user_id);
CREATE POLICY "Users can delete their shared links" ON public.shared_journey_links 
FOR DELETE USING (auth.uid() = created_by_user_id);

-- Route performance - public read, system write
CREATE POLICY "Anyone can view route performance" ON public.route_performance_history 
FOR SELECT USING (true);

-- =============================================
-- HELPER FUNCTIONS
-- =============================================

-- Function to generate unique share codes
CREATE OR REPLACE FUNCTION public.generate_share_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..8 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::integer, 1);
  END LOOP;
  RETURN result;
END;
$$;

-- Function to calculate distance between two points (in km)
CREATE OR REPLACE FUNCTION public.calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  R CONSTANT DOUBLE PRECISION := 6371; -- Earth's radius in km
  dLat DOUBLE PRECISION;
  dLon DOUBLE PRECISION;
  a DOUBLE PRECISION;
  c DOUBLE PRECISION;
BEGIN
  dLat := radians(lat2 - lat1);
  dLon := radians(lon2 - lon1);
  a := sin(dLat/2) * sin(dLat/2) + cos(radians(lat1)) * cos(radians(lat2)) * sin(dLon/2) * sin(dLon/2);
  c := 2 * atan2(sqrt(a), sqrt(1-a));
  RETURN R * c;
END;
$$;

-- Function to get shared journey data (public access via share code)
CREATE OR REPLACE FUNCTION public.get_shared_journey(share_code_param TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
  link_record RECORD;
BEGIN
  -- Get the share link
  SELECT * INTO link_record
  FROM public.shared_journey_links
  WHERE share_code = share_code_param
    AND is_active = true
    AND (expires_at IS NULL OR expires_at > now());
    
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Invalid or expired share link');
  END IF;
  
  -- Update view count
  UPDATE public.shared_journey_links
  SET views_count = views_count + 1,
      last_viewed_at = now()
  WHERE share_code = share_code_param;
  
  -- Build response based on permissions
  SELECT jsonb_build_object(
    'journey', jsonb_build_object(
      'id', j.id,
      'status', j.status,
      'progress', j.progress,
      'departure_time', j.departure_time,
      'estimated_arrival', j.estimated_arrival,
      'delay_minutes', j.delay_minutes
    ),
    'bus', CASE WHEN (link_record.permissions->>'view_location')::boolean THEN
      jsonb_build_object(
        'current_position', ST_AsGeoJSON(b.current_position)::jsonb,
        'heading', b.heading,
        'speed', b.speed,
        'last_update', b.last_gps_update
      )
    ELSE NULL END,
    'stops', CASE WHEN (link_record.permissions->>'view_stops')::boolean THEN
      (SELECT jsonb_agg(jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'eta', je.predicted_arrival,
        'is_delayed', je.is_delayed
      ) ORDER BY rs.sequence_order)
      FROM route_stops rs
      JOIN stops s ON rs.stop_id = s.id
      LEFT JOIN journey_etas je ON je.journey_id = j.id AND je.stop_id = s.id
      WHERE rs.route_id = j.route_id)
    ELSE NULL END
  ) INTO result
  FROM journey_passengers jp
  JOIN journeys j ON jp.journey_id = j.id
  JOIN buses b ON j.bus_id = b.id
  WHERE jp.id = link_record.journey_passenger_id;
  
  RETURN result;
END;
$$;

-- =============================================
-- UPDATED_AT TRIGGER
-- =============================================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_buses_updated_at BEFORE UPDATE ON public.buses FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_routes_updated_at BEFORE UPDATE ON public.routes FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_stops_updated_at BEFORE UPDATE ON public.stops FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_journeys_updated_at BEFORE UPDATE ON public.journeys FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_journey_passengers_updated_at BEFORE UPDATE ON public.journey_passengers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_delivery_agents_updated_at BEFORE UPDATE ON public.delivery_agents FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_restaurants_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_menu_items_updated_at BEFORE UPDATE ON public.menu_items FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_accommodations_updated_at BEFORE UPDATE ON public.accommodations FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_accommodation_bookings_updated_at BEFORE UPDATE ON public.accommodation_bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- =============================================
-- ENABLE REALTIME FOR KEY TABLES
-- =============================================

ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journeys;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_passengers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_etas;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_agents;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_alerts;