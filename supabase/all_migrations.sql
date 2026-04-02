-- ====== 001_core_schema.sql ======
-- BusNStay Phase 2: Core Schema
-- This migration creates the foundation for background tracking, offline orders, and restaurant notifications

-- ==================== JOURNEYS ====================
CREATE TABLE IF NOT EXISTS journeys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES auth.users(id),
  bus_id UUID,
  from_stop_id UUID,
  to_stop_id UUID,
  
  -- Journey lifecycle
  status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'COMPLETED', 'CANCELLED')),
  start_time TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  end_time TIMESTAMP WITH TIME ZONE,
  estimated_arrival TIMESTAMP WITH TIME ZONE,
  
  -- Offline sync tracking
  offline_queue_count INT DEFAULT 0,
  last_sync_time TIMESTAMP WITH TIME ZONE,
  last_location_update TIMESTAMP WITH TIME ZONE,
  
  -- Current location
  current_latitude FLOAT8,
  current_longitude FLOAT8,
  current_accuracy FLOAT8,
  distance_to_destination FLOAT8,
  
  -- Metadata
  device_id TEXT, -- For offline queue tracking
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  
  UNIQUE(passenger_id, status)
);

CREATE UNIQUE INDEX IF NOT EXISTS active_journey_per_passenger ON journeys(passenger_id) WHERE status = 'ACTIVE';
CREATE INDEX idx_journeys_passenger ON journeys(passenger_id, status);
CREATE INDEX idx_journeys_status ON journeys(status);
CREATE INDEX idx_journeys_active ON journeys(id) WHERE status = 'ACTIVE';

-- ==================== ORDERS ====================
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
  rider_id UUID,
  restaurant_id UUID,
  passenger_id UUID NOT NULL REFERENCES auth.users(id),
  stop_id UUID,
  
  -- Order details
  items JSONB NOT NULL DEFAULT '[]', -- [{name, qty, price}, ...]
  notes TEXT,
  total_amount DECIMAL(10, 2),
  
  -- Order status
  status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN (
    'PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'PICKED_UP', 'DELIVERED', 'FAILED'
  )),
  
  -- Timing
  restaurant_confirmed_at TIMESTAMP WITH TIME ZONE,
  restaurant_ready_at TIMESTAMP WITH TIME ZONE,
  rider_picked_up_at TIMESTAMP WITH TIME ZONE,
  delivered_at TIMESTAMP WITH TIME ZONE,
  estimated_arrival_at_restaurant TIMESTAMP WITH TIME ZONE,
  
  -- Offline handling
  offline_created BOOLEAN DEFAULT false,
  offline_id TEXT UNIQUE, -- Client-generated UUID for dedup
  synced_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_journey ON orders(journey_id, status);
CREATE INDEX idx_orders_restaurant ON orders(restaurant_id, status);
CREATE INDEX idx_orders_rider ON orders(rider_id, status);
CREATE INDEX idx_orders_passenger ON orders(passenger_id, status);
CREATE INDEX idx_orders_offline_id ON orders(offline_id);

-- ==================== OFFLINE QUEUE ====================
CREATE TABLE IF NOT EXISTS offline_queue (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT NOT NULL,
  journey_id UUID REFERENCES journeys(id) ON DELETE CASCADE,
  
  -- Queue item details
  action TEXT NOT NULL CHECK (action IN ('CREATE_ORDER', 'UPDATE_LOCATION', 'CONFIRM_JOURNEY', 'ORDER_STATUS')),
  payload JSONB NOT NULL,
  
  -- Queue management
  sequence_number INT NOT NULL,
  processed BOOLEAN NOT NULL DEFAULT false,
  error_message TEXT,
  attempted_count INT DEFAULT 0,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  
  UNIQUE(device_id, sequence_number)
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_pending_queue ON offline_queue(device_id, sequence_number) WHERE processed = false;
CREATE INDEX idx_offline_queue_device ON offline_queue(device_id, processed, sequence_number);
CREATE INDEX idx_offline_queue_journey ON offline_queue(journey_id, processed);

-- ==================== TOWNS ON ROUTE ====================
CREATE TABLE IF NOT EXISTS towns_on_route (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
  
  -- Town info
  town_name TEXT NOT NULL,
  latitude FLOAT8 NOT NULL,
  longitude FLOAT8 NOT NULL,
  route_index INT NOT NULL,
  
  -- Town status for ordering
  status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSING_SOON', 'CLOSED', 'LOCKED')),
  
  -- Timing calculations
  minutes_to_arrival INT,
  distance_to_arrival FLOAT8,
  
  -- Cutoff thresholds
  close_at_distance_km FLOAT8 DEFAULT 3.0,
  close_at_minutes_remaining INT DEFAULT 10,
  
  -- Lifecycle timestamps
  opened_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  closing_soon_at TIMESTAMP WITH TIME ZONE,
  closed_at TIMESTAMP WITH TIME ZONE,
  locked_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_towns_journey ON towns_on_route(journey_id, status);
CREATE INDEX idx_towns_status ON towns_on_route(status);

-- ==================== LOCATION HISTORY ====================
CREATE TABLE IF NOT EXISTS location_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES journeys(id) ON DELETE CASCADE,
  
  latitude FLOAT8 NOT NULL,
  longitude FLOAT8 NOT NULL,
  accuracy FLOAT8,
  
  source TEXT CHECK (source IN ('GPS', 'NETWORK', 'CACHED', 'LAST_KNOWN')),
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_location_journey ON location_history(journey_id, created_at);
CREATE INDEX idx_location_recent ON location_history(journey_id) WHERE created_at IS NOT NULL;

-- ==================== RESTAURANTS ====================
CREATE TABLE IF NOT EXISTS restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT,
  email TEXT UNIQUE,
  
  -- Location
  latitude FLOAT8,
  longitude FLOAT8,
  stop_id UUID,
  
  -- Dashboard access
  dashboard_token TEXT UNIQUE,
  api_key TEXT UNIQUE,
  
  -- Notification settings
  notification_method TEXT DEFAULT 'BOTH' CHECK (notification_method IN ('PUSH', 'SMS', 'BOTH')),
  sms_number TEXT,
  
  -- Performance
  average_prep_time_minutes INT DEFAULT 15,
  max_concurrent_orders INT DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_restaurants_stop ON restaurants(stop_id);
CREATE INDEX idx_restaurants_active ON restaurants(is_active);

-- ==================== RIDERS ====================
CREATE TABLE IF NOT EXISTS riders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  email TEXT,
  
  -- Profile
  photo_url TEXT,
  vehicle_type TEXT CHECK (vehicle_type IN ('MOTORBIKE', 'CAR', 'BICYCLE')),
  vehicle_registration TEXT,
  
  -- Status & Location
  status TEXT DEFAULT 'OFFLINE' CHECK (status IN ('ONLINE', 'OFFLINE', 'ON_DELIVERY')),
  current_latitude FLOAT8,
  current_longitude FLOAT8,
  last_location_update TIMESTAMP WITH TIME ZONE,
  
  -- Service area
  service_stop_id UUID,
  
  -- Performance
  average_rating FLOAT8 DEFAULT 0,
  total_deliveries INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_riders_stop ON riders(service_stop_id, status);
CREATE INDEX idx_riders_active ON riders(is_active, status);

-- ==================== RESTAURANT NOTIFICATIONS ====================
CREATE TABLE IF NOT EXISTS restaurant_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  journey_id UUID REFERENCES journeys(id) ON DELETE CASCADE,
  
  -- Notification content
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'ORDER_RECEIVED', 'ORDER_READY_REQUEST', 'RIDER_ASSIGNED', 'RIDER_ARRIVING', 'RIDER_ARRIVED'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  payload JSONB,
  
  -- Delivery tracking
  push_sent BOOLEAN DEFAULT false,
  sms_sent BOOLEAN DEFAULT false,
  email_sent BOOLEAN DEFAULT false,
  
  sent_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_restaurant ON restaurant_notifications(restaurant_id, read_at);
CREATE INDEX idx_notifications_unread ON restaurant_notifications(restaurant_id) WHERE read_at IS NULL;

-- ==================== RIDER NOTIFICATIONS ====================
CREATE TABLE IF NOT EXISTS rider_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES riders(id) ON DELETE CASCADE,
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  
  -- Notification content
  notification_type TEXT NOT NULL CHECK (notification_type IN (
    'ORDER_ASSIGNED', 'PICKUP_READY', 'DELIVERY_COMPLETE', 'CANCELLATION'
  )),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  payload JSONB,
  
  -- Delivery tracking
  push_sent BOOLEAN DEFAULT false,
  sms_sent BOOLEAN DEFAULT false,
  
  sent_at TIMESTAMP WITH TIME ZONE,
  read_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_rider_notif_rider ON rider_notifications(rider_id, read_at);

-- ==================== ENABLE ROW LEVEL SECURITY ====================
ALTER TABLE journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE offline_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE towns_on_route ENABLE ROW LEVEL SECURITY;
ALTER TABLE location_history ENABLE ROW LEVEL SECURITY;

-- ==================== ROW LEVEL SECURITY POLICIES ====================

-- Passengers can only see their own journeys
CREATE POLICY "passengers_view_own_journeys" ON journeys
  FOR SELECT USING (auth.uid() = passenger_id);

CREATE POLICY "passengers_insert_journeys" ON journeys
  FOR INSERT WITH CHECK (auth.uid() = passenger_id);

CREATE POLICY "passengers_update_own_journeys" ON journeys
  FOR UPDATE USING (auth.uid() = passenger_id);

-- Passengers can only see their own orders
CREATE POLICY "passengers_view_own_orders" ON orders
  FOR SELECT USING (auth.uid() = passenger_id);

CREATE POLICY "passengers_insert_orders" ON orders
  FOR INSERT WITH CHECK (auth.uid() = passenger_id);

-- Location history visibility
CREATE POLICY "passengers_view_own_location_history" ON location_history
  FOR SELECT USING (
    journey_id IN (
      SELECT id FROM journeys WHERE passenger_id = auth.uid()
    )
  );

-- Create function to update journey timestamps
CREATE OR REPLACE FUNCTION update_journey_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_journeys_timestamp
  BEFORE UPDATE ON journeys
  FOR EACH ROW
  EXECUTE FUNCTION update_journey_updated_at();

-- Create function to update orders timestamps
CREATE OR REPLACE FUNCTION update_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_timestamp
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_orders_updated_at();


-- ====== 20260205022456_d2cc4367-f009-45c9-98e1-e41377656fc0.sql ======
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

-- ====== 20260205022626_59c8cb2a-b62c-4fc7-a9e2-02b3667825af.sql ======
-- Fix security warnings: Set search_path on functions

-- Fix generate_share_code function
CREATE OR REPLACE FUNCTION public.generate_share_code()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
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

-- Fix calculate_distance function
CREATE OR REPLACE FUNCTION public.calculate_distance(
  lat1 DOUBLE PRECISION,
  lon1 DOUBLE PRECISION,
  lat2 DOUBLE PRECISION,
  lon2 DOUBLE PRECISION
)
RETURNS DOUBLE PRECISION
LANGUAGE plpgsql
IMMUTABLE
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  R CONSTANT DOUBLE PRECISION := 6371;
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

-- Fix update_updated_at_column function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- ====== 20260206030827_3c72a445-d5b2-4b1b-a261-9ce9c75b67e8.sql ======
-- ============================================
-- BUSNSTAY COMPLETE ROLE-BASED AUTH & PROFILES
-- IDEMPOTENT: Uses CREATE IF NOT EXISTS patterns
-- ============================================

-- 1. Create user_roles ENUM if not exists
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('passenger', 'restaurant', 'rider', 'taxi', 'hotel', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create user_profiles table for role-based access
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    email TEXT,
    full_name TEXT,
    phone TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'passenger',
    is_approved BOOLEAN DEFAULT false,
    assigned_station_id UUID REFERENCES public.stops(id),
    business_name TEXT,
    business_license TEXT,
    business_address TEXT,
    rating NUMERIC DEFAULT 5.0,
    total_trips INTEGER DEFAULT 0,
    is_online BOOLEAN DEFAULT false,
    current_position geography(Point, 4326),
    last_gps_update TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Create taxi_drivers table
CREATE TABLE IF NOT EXISTS public.taxi_drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    profile_id UUID REFERENCES public.user_profiles(id),
    station_id UUID REFERENCES public.stops(id),
    vehicle_registration TEXT NOT NULL,
    vehicle_type TEXT DEFAULT 'sedan',
    vehicle_color TEXT,
    vehicle_capacity INTEGER DEFAULT 4,
    is_online BOOLEAN DEFAULT false,
    is_on_trip BOOLEAN DEFAULT false,
    current_position geography(Point, 4326),
    heading NUMERIC,
    rating NUMERIC DEFAULT 5.0,
    total_trips INTEGER DEFAULT 0,
    earnings_total NUMERIC DEFAULT 0,
    last_gps_update TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Create taxi_rides table
CREATE TABLE IF NOT EXISTS public.taxi_rides (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    passenger_user_id UUID NOT NULL,
    driver_id UUID REFERENCES public.taxi_drivers(id),
    station_id UUID REFERENCES public.stops(id),
    pickup_location geography(Point, 4326),
    pickup_address TEXT,
    dropoff_location geography(Point, 4326),
    dropoff_address TEXT,
    ride_type TEXT DEFAULT 'to_accommodation',
    accommodation_id UUID REFERENCES public.accommodations(id),
    status TEXT DEFAULT 'pending',
    fare_estimate NUMERIC,
    fare_actual NUMERIC,
    distance_km NUMERIC,
    duration_minutes INTEGER,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    rating_from_passenger NUMERIC,
    rating_from_driver NUMERIC,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Create GPS trust scoring table
CREATE TABLE IF NOT EXISTS public.gps_trust_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    journey_id UUID REFERENCES public.journeys(id),
    source_id UUID NOT NULL,
    source_type TEXT NOT NULL,
    trust_score NUMERIC DEFAULT 0.5,
    accuracy_history NUMERIC[] DEFAULT '{}',
    spoofing_flags INTEGER DEFAULT 0,
    last_validated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 6. Create jam detection / system health table
CREATE TABLE IF NOT EXISTS public.system_health_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    severity TEXT DEFAULT 'info',
    source_table TEXT,
    source_id UUID,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    is_resolved BOOLEAN DEFAULT false,
    auto_fixed BOOLEAN DEFAULT false,
    resolution_notes TEXT,
    detected_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    resolved_at TIMESTAMP WITH TIME ZONE
);

-- 7. Create platform metrics table
CREATE TABLE IF NOT EXISTS public.platform_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type TEXT NOT NULL,
    metric_value NUMERIC NOT NULL,
    dimensions JSONB DEFAULT '{}',
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 8. Add RLS policies for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;
CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "Admins can update any profile" ON public.user_profiles;
CREATE POLICY "Admins can update any profile" ON public.user_profiles
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 9. Add RLS policies for taxi_drivers
ALTER TABLE public.taxi_drivers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Taxi drivers can view their own record" ON public.taxi_drivers;
CREATE POLICY "Taxi drivers can view their own record" ON public.taxi_drivers
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Taxi drivers can update their own record" ON public.taxi_drivers;
CREATE POLICY "Taxi drivers can update their own record" ON public.taxi_drivers
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Anyone can view online taxi drivers" ON public.taxi_drivers;
CREATE POLICY "Anyone can view online taxi drivers" ON public.taxi_drivers
    FOR SELECT USING (is_online = true);

-- 10. Add RLS policies for taxi_rides
ALTER TABLE public.taxi_rides ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Passengers can view their taxi rides" ON public.taxi_rides;
CREATE POLICY "Passengers can view their taxi rides" ON public.taxi_rides
    FOR SELECT USING (auth.uid() = passenger_user_id);

DROP POLICY IF EXISTS "Passengers can create taxi rides" ON public.taxi_rides;
CREATE POLICY "Passengers can create taxi rides" ON public.taxi_rides
    FOR INSERT WITH CHECK (auth.uid() = passenger_user_id);

DROP POLICY IF EXISTS "Drivers can view assigned rides" ON public.taxi_rides;
CREATE POLICY "Drivers can view assigned rides" ON public.taxi_rides
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.taxi_drivers WHERE id = driver_id AND user_id = auth.uid())
    );

-- 11. Add RLS for gps_trust_scores
ALTER TABLE public.gps_trust_scores ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view trust scores" ON public.gps_trust_scores;
CREATE POLICY "Anyone can view trust scores" ON public.gps_trust_scores
    FOR SELECT USING (true);

-- 12. Add RLS for system_health_events (admin only)
ALTER TABLE public.system_health_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins can view health events" ON public.system_health_events;
CREATE POLICY "Admins can view health events" ON public.system_health_events
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

DROP POLICY IF EXISTS "System can insert health events" ON public.system_health_events;
CREATE POLICY "System can insert health events" ON public.system_health_events
    FOR INSERT WITH CHECK (true);

-- 13. Add RLS for platform_metrics
ALTER TABLE public.platform_metrics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view metrics" ON public.platform_metrics;
CREATE POLICY "Anyone can view metrics" ON public.platform_metrics
    FOR SELECT USING (true);

-- 14. Create function to auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (user_id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'passenger')
    )
    ON CONFLICT (user_id) DO UPDATE SET
        email = EXCLUDED.email,
        updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Drop trigger if exists and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 15. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON public.user_profiles(role);
CREATE INDEX IF NOT EXISTS idx_user_profiles_station ON public.user_profiles(assigned_station_id);
CREATE INDEX IF NOT EXISTS idx_taxi_drivers_station ON public.taxi_drivers(station_id);
CREATE INDEX IF NOT EXISTS idx_taxi_drivers_online ON public.taxi_drivers(is_online) WHERE is_online = true;
CREATE INDEX IF NOT EXISTS idx_taxi_rides_status ON public.taxi_rides(status);
CREATE INDEX IF NOT EXISTS idx_gps_trust_journey ON public.gps_trust_scores(journey_id);
CREATE INDEX IF NOT EXISTS idx_system_health_unresolved ON public.system_health_events(is_resolved) WHERE is_resolved = false;

-- 16. Enable realtime for key tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.taxi_drivers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.taxi_rides;
ALTER PUBLICATION supabase_realtime ADD TABLE public.system_health_events;

-- ====== 20260206030907_5ce2b6b5-b050-411e-8620-737fa5e10918.sql ======
-- ============================================
-- SECURITY FIXES: RLS & POLICY REFINEMENTS
-- ============================================

-- 1. Fix platform_metrics RLS - require authentication for inserts
DROP POLICY IF EXISTS "Anyone can view metrics" ON public.platform_metrics;
CREATE POLICY "Authenticated users can view metrics" ON public.platform_metrics
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "System can insert metrics" ON public.platform_metrics;
CREATE POLICY "System can insert metrics" ON public.platform_metrics
    FOR INSERT TO authenticated WITH CHECK (true);

-- 2. Fix gps_trust_scores - require authentication  
DROP POLICY IF EXISTS "Anyone can view trust scores" ON public.gps_trust_scores;
CREATE POLICY "Authenticated users can view trust scores" ON public.gps_trust_scores
    FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "System can insert trust scores" ON public.gps_trust_scores;
CREATE POLICY "System can insert trust scores" ON public.gps_trust_scores
    FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "System can update trust scores" ON public.gps_trust_scores;
CREATE POLICY "System can update trust scores" ON public.gps_trust_scores
    FOR UPDATE TO authenticated USING (true);

-- 3. Create has_role security definer function to avoid RLS recursion
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role text)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.user_profiles
        WHERE user_id = _user_id AND role = _role
    )
$$;

-- 4. Create get_user_role function
CREATE OR REPLACE FUNCTION public.get_user_role(_user_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT role FROM public.user_profiles WHERE user_id = _user_id LIMIT 1
$$;

-- 5. Update admin policies to use has_role function (avoid recursion)
DROP POLICY IF EXISTS "Admins can view all profiles" ON public.user_profiles;
CREATE POLICY "Admins can view all profiles" ON public.user_profiles
    FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can update any profile" ON public.user_profiles;
CREATE POLICY "Admins can update any profile" ON public.user_profiles
    FOR UPDATE TO authenticated
    USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can view health events" ON public.system_health_events;
CREATE POLICY "Admins can view health events" ON public.system_health_events
    FOR SELECT TO authenticated
    USING (public.has_role(auth.uid(), 'admin'));

-- 6. Fix system_health_events insert policy - require service role or authenticated
DROP POLICY IF EXISTS "System can insert health events" ON public.system_health_events;
CREATE POLICY "Authenticated can insert health events" ON public.system_health_events
    FOR INSERT TO authenticated WITH CHECK (true);

-- 7. Add taxi driver insert policy
DROP POLICY IF EXISTS "Taxi drivers can insert their record" ON public.taxi_drivers;
CREATE POLICY "Taxi drivers can insert their record" ON public.taxi_drivers
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- 8. Add taxi ride update policies
DROP POLICY IF EXISTS "Passengers can update their taxi rides" ON public.taxi_rides;
CREATE POLICY "Passengers can update their taxi rides" ON public.taxi_rides
    FOR UPDATE TO authenticated USING (auth.uid() = passenger_user_id);

DROP POLICY IF EXISTS "Drivers can update assigned rides" ON public.taxi_rides;
CREATE POLICY "Drivers can update assigned rides" ON public.taxi_rides
    FOR UPDATE TO authenticated USING (
        EXISTS (SELECT 1 FROM public.taxi_drivers WHERE id = driver_id AND user_id = auth.uid())
    );

-- ====== 20260208035525_879f1d09-680e-42e4-beba-71899b933449.sql ======

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


-- ====== 20260209035538_691acf95-a473-4ff0-9176-3cb8e3b7f5e0.sql ======

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


-- ====== 20260210_distance_based_pricing.sql ======
-- ============================================
-- DISTANCE-BASED DYNAMIC PRICING SYSTEM
-- Adds GPS coordinates to restaurants/hotels
-- Implements delivery fee calculation
-- ============================================

-- 1. Add GPS columns to restaurants table if not already there
ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS 
    location geography(Point, 4326);

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS 
    latitude NUMERIC;

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS 
    longitude NUMERIC;

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS
    base_delivery_fee NUMERIC DEFAULT 0.5;

ALTER TABLE public.restaurants ADD COLUMN IF NOT EXISTS
    delivery_fee_per_km NUMERIC DEFAULT 0.2;

-- 2. Add GPS columns to accommodations table
ALTER TABLE public.accommodations ADD COLUMN IF NOT EXISTS 
    location geography(Point, 4326);

ALTER TABLE public.accommodations ADD COLUMN IF NOT EXISTS 
    latitude NUMERIC;

ALTER TABLE public.accommodations ADD COLUMN IF NOT EXISTS 
    longitude NUMERIC;

-- 3. Create delivery_zones table for geo-based restrictions
CREATE TABLE IF NOT EXISTS public.delivery_zones (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    zone_name TEXT NOT NULL,
    coverage_area geography(Polygon, 4326) NOT NULL,
    max_distance_km NUMERIC NOT NULL,
    min_order_value NUMERIC DEFAULT 0,
    delivery_time_minutes INTEGER DEFAULT 30,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Create delivery_fee_rules table for dynamic pricing
CREATE TABLE IF NOT EXISTS public.delivery_fee_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
    distance_range_start NUMERIC NOT NULL,
    distance_range_end NUMERIC NOT NULL,
    fee_flat NUMERIC,
    fee_percentage NUMERIC,
    time_range_start TIME,
    time_range_end TIME,
    day_of_week TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Update orders table to include delivery fee calculation
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    delivery_location geography(Point, 4326);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    delivery_distance_km NUMERIC;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    delivery_fee NUMERIC DEFAULT 0;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    delivery_status TEXT DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled'));

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    estimated_delivery_time TIMESTAMP WITH TIME ZONE;

-- 6. Create index on geography columns for performance
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_accommodations_location ON public.accommodations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_location ON public.orders USING GIST(delivery_location);
CREATE INDEX IF NOT EXISTS idx_delivery_zones_area ON public.delivery_zones USING GIST(coverage_area);

-- 7. Create function to calculate delivery fee
CREATE OR REPLACE FUNCTION calculate_delivery_fee(
    restaurant_id UUID,
    distance_km NUMERIC,
    order_total NUMERIC DEFAULT NULL,
    current_hour INTEGER DEFAULT NULL
)
RETURNS NUMERIC AS $$
DECLARE
    base_fee NUMERIC;
    fee_per_km NUMERIC;
    calculated_fee NUMERIC;
    rule RECORD;
BEGIN
    -- Get restaurant base rates
    SELECT base_delivery_fee, delivery_fee_per_km 
    INTO base_fee, fee_per_km
    FROM public.restaurants 
    WHERE id = restaurant_id;
    
    IF base_fee IS NULL THEN
        base_fee := 0.5;
        fee_per_km := 0.2;
    END IF;
    
    -- Check for specific delivery fee rules
    SELECT fee_flat, fee_percentage
    INTO rule
    FROM public.delivery_fee_rules
    WHERE restaurant_id = restaurant_id
        AND distance_km BETWEEN distance_range_start AND distance_range_end
        AND is_active = true
        AND (day_of_week IS NULL OR to_char(CURRENT_DATE, 'Dy') = ANY(day_of_week))
        AND (time_range_start IS NULL OR CURRENT_TIME BETWEEN time_range_start AND time_range_end)
    LIMIT 1;
    
    -- Calculate fee
    IF rule.fee_flat IS NOT NULL THEN
        calculated_fee := rule.fee_flat;
    ELSIF rule.fee_percentage IS NOT NULL AND order_total IS NOT NULL THEN
        calculated_fee := order_total * (rule.fee_percentage / 100);
    ELSE
        calculated_fee := base_fee + (distance_km * fee_per_km);
    END IF;
    
    -- Ensure minimum fee
    calculated_fee := GREATEST(calculated_fee, base_fee);
    
    RETURN ROUND(calculated_fee::NUMERIC, 2);
END;
$$ LANGUAGE plpgsql STABLE;

-- 8. Create function to calculate distance between two points
CREATE OR REPLACE FUNCTION calculate_distance_km(
    point1 geography,
    point2 geography
)
RETURNS NUMERIC AS $$
BEGIN
    IF point1 IS NULL OR point2 IS NULL THEN
        RETURN NULL;
    END IF;
    -- ST_Distance returns meters, convert to km
    RETURN ST_Distance(point1, point2) / 1000.0;
END;
$$ LANGUAGE plpgsql STABLE;

-- 9. Create function to check if delivery location is in zone
CREATE OR REPLACE FUNCTION is_in_delivery_zone(
    restaurant_id UUID,
    delivery_point geography
)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.delivery_zones
        WHERE restaurant_id = restaurant_id
            AND is_active = true
            AND ST_Contains(coverage_area, delivery_point)
    );
END;
$$ LANGUAGE plpgsql STABLE;

-- 10. Enable RLS on new tables
ALTER TABLE public.delivery_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_fee_rules ENABLE ROW LEVEL SECURITY;

-- 11. RLS policies for delivery_zones
CREATE POLICY "Users can view delivery zones for public restaurants" ON public.delivery_zones
    FOR SELECT USING (true);

CREATE POLICY "Restaurant owners can manage their delivery zones" ON public.delivery_zones
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            JOIN public.user_profiles p ON r.owner_id = p.user_id
            WHERE r.id = delivery_zones.restaurant_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all delivery zones" ON public.delivery_zones
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 12. RLS policies for delivery_fee_rules
CREATE POLICY "Restaurant owners can view their fee rules" ON public.delivery_fee_rules
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            JOIN public.user_profiles p ON r.owner_id = p.user_id
            WHERE r.id = delivery_fee_rules.restaurant_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Restaurant owners can manage their fee rules" ON public.delivery_fee_rules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.restaurants r
            JOIN public.user_profiles p ON r.owner_id = p.user_id
            WHERE r.id = delivery_fee_rules.restaurant_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all fee rules" ON public.delivery_fee_rules
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 13. Add to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_zones;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_fee_rules;


-- ====== 20260210_gps_tracking.sql ======
-- ============================================
-- REAL-TIME GPS TRACKING SYSTEM
-- Location tracking for riders and deliveries
-- Live location updates with history
-- ============================================

-- 1. Create rider_locations table for real-time tracking
CREATE TABLE IF NOT EXISTS public.rider_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID NOT NULL,
    journey_id UUID REFERENCES public.journeys(id) ON DELETE SET NULL,
    current_location geography(Point, 4326) NOT NULL,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    accuracy_meters NUMERIC,
    speed_kmh NUMERIC DEFAULT 0,
    heading NUMERIC,
    altitude NUMERIC,
    is_online BOOLEAN DEFAULT true,
    is_on_delivery BOOLEAN DEFAULT false,
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Create delivery_locations table for in-transit tracking
CREATE TABLE IF NOT EXISTS public.delivery_locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    delivery_agent_id UUID NOT NULL,
    delivery_agent_type TEXT NOT NULL CHECK (delivery_agent_type IN ('rider', 'taxi_driver')),
    current_location geography(Point, 4326) NOT NULL,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    estimated_arrival TIMESTAMP WITH TIME ZONE,
    distance_remaining_km NUMERIC,
    accuracy_meters NUMERIC,
    speed_kmh NUMERIC DEFAULT 0,
    heading NUMERIC,
    status TEXT DEFAULT 'in_transit' CHECK (status IN ('picked_up', 'in_transit', 'arrived', 'delivered')),
    last_update TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 3. Create location_history table for audit trail
CREATE TABLE IF NOT EXISTS public.location_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_type TEXT NOT NULL CHECK (entity_type IN ('rider', 'delivery')),
    entity_id UUID NOT NULL,
    location geography(Point, 4326) NOT NULL,
    latitude NUMERIC NOT NULL,
    longitude NUMERIC NOT NULL,
    accuracy_meters NUMERIC,
    speed_kmh NUMERIC,
    heading NUMERIC,
    source TEXT DEFAULT 'gps' CHECK (source IN ('gps', 'network', 'manual')),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 4. Create geofence_alerts table
CREATE TABLE IF NOT EXISTS public.geofence_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID REFERENCES public.user_profiles(user_id),
    delivery_id UUID REFERENCES public.delivery_locations(id),
    alert_type TEXT NOT NULL CHECK (alert_type IN ('geofence_enter', 'geofence_exit', 'speed_alert', 'off_route')),
    geofence_location geography(Point, 4326),
    geofence_radius_km NUMERIC DEFAULT 0.5,
    alert_message TEXT,
    is_acknowledged BOOLEAN DEFAULT false,
    acknowledged_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 5. Add GPS columns to orders table
ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    pickup_location geography(Point, 4326);

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    expected_delivery_time TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.orders ADD COLUMN IF NOT EXISTS 
    actual_delivery_time TIMESTAMP WITH TIME ZONE;

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_rider_locations_rider_id ON public.rider_locations(rider_id);
CREATE INDEX IF NOT EXISTS idx_rider_locations_journey_id ON public.rider_locations(journey_id);
CREATE INDEX IF NOT EXISTS idx_rider_locations_created ON public.rider_locations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_rider_locations_geo ON public.rider_locations USING GIST(current_location);

CREATE INDEX IF NOT EXISTS idx_delivery_locations_order_id ON public.delivery_locations(order_id);
CREATE INDEX IF NOT EXISTS idx_delivery_locations_agent ON public.delivery_locations(delivery_agent_id, delivery_agent_type);
CREATE INDEX IF NOT EXISTS idx_delivery_locations_created ON public.delivery_locations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_delivery_locations_geo ON public.delivery_locations USING GIST(current_location);

CREATE INDEX IF NOT EXISTS idx_location_history_entity ON public.location_history(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_location_history_recorded ON public.location_history(recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_location_history_geo ON public.location_history USING GIST(location);

CREATE INDEX IF NOT EXISTS idx_geofence_alerts_rider ON public.geofence_alerts(rider_id);
CREATE INDEX IF NOT EXISTS idx_geofence_alerts_delivery ON public.geofence_alerts(delivery_id);

-- 7. Create function to update rider location
CREATE OR REPLACE FUNCTION update_rider_location(
    p_rider_id UUID,
    p_latitude NUMERIC,
    p_longitude NUMERIC,
    p_accuracy_meters NUMERIC DEFAULT NULL,
    p_speed_kmh NUMERIC DEFAULT NULL,
    p_heading NUMERIC DEFAULT NULL,
    p_journey_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_location_id UUID;
    v_point geography;
BEGIN
    v_point := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography;
    
    -- Insert or update rider_locations
    INSERT INTO public.rider_locations (
        rider_id, journey_id, current_location, latitude, longitude, 
        accuracy_meters, speed_kmh, heading, last_update, updated_at
    )
    VALUES (
        p_rider_id, p_journey_id, v_point, p_latitude, p_longitude,
        p_accuracy_meters, p_speed_kmh, p_heading, now(), now()
    )
    ON CONFLICT (rider_id) DO UPDATE SET
        current_location = v_point,
        latitude = p_latitude,
        longitude = p_longitude,
        accuracy_meters = COALESCE(p_accuracy_meters, EXCLUDED.accuracy_meters),
        speed_kmh = COALESCE(p_speed_kmh, EXCLUDED.speed_kmh),
        heading = COALESCE(p_heading, EXCLUDED.heading),
        last_update = now(),
        updated_at = now()
    RETURNING id INTO v_location_id;
    
    -- Store in history
    INSERT INTO public.location_history (
        entity_type, entity_id, location, latitude, longitude, 
        accuracy_meters, speed_kmh, heading, source
    )
    VALUES (
        'rider', p_rider_id, v_point, p_latitude, p_longitude,
        p_accuracy_meters, p_speed_kmh, p_heading, 'gps'
    );
    
    RETURN v_location_id;
END;
$$ LANGUAGE plpgsql;

-- 8. Create function to update delivery location
CREATE OR REPLACE FUNCTION update_delivery_location(
    p_order_id UUID,
    p_agent_id UUID,
    p_agent_type TEXT,
    p_latitude NUMERIC,
    p_longitude NUMERIC,
    p_accuracy_meters NUMERIC DEFAULT NULL,
    p_speed_kmh NUMERIC DEFAULT NULL,
    p_heading NUMERIC DEFAULT NULL,
    p_estimated_arrival TIMESTAMP WITH TIME ZONE DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_location_id UUID;
    v_point geography;
    v_distance_km NUMERIC;
BEGIN
    v_point := ST_SetSRID(ST_MakePoint(p_longitude, p_latitude), 4326)::geography;
    
    -- Calculate distance to delivery location if available
    SELECT CASE 
        WHEN orders.delivery_location IS NOT NULL 
        THEN ST_Distance(v_point, orders.delivery_location) / 1000.0
        ELSE NULL
    END INTO v_distance_km
    FROM public.orders
    WHERE orders.id = p_order_id;
    
    -- Insert or update delivery_locations
    INSERT INTO public.delivery_locations (
        order_id, delivery_agent_id, delivery_agent_type, current_location, 
        latitude, longitude, accuracy_meters, speed_kmh, heading,
        estimated_arrival, distance_remaining_km, last_update, updated_at
    )
    VALUES (
        p_order_id, p_agent_id, p_agent_type, v_point,
        p_latitude, p_longitude, p_accuracy_meters, p_speed_kmh, p_heading,
        p_estimated_arrival, v_distance_km, now(), now()
    )
    ON CONFLICT (order_id) DO UPDATE SET
        current_location = v_point,
        latitude = p_latitude,
        longitude = p_longitude,
        accuracy_meters = COALESCE(p_accuracy_meters, EXCLUDED.accuracy_meters),
        speed_kmh = COALESCE(p_speed_kmh, EXCLUDED.speed_kmh),
        heading = COALESCE(p_heading, EXCLUDED.heading),
        estimated_arrival = COALESCE(p_estimated_arrival, EXCLUDED.estimated_arrival),
        distance_remaining_km = v_distance_km,
        last_update = now(),
        updated_at = now()
    RETURNING id INTO v_location_id;
    
    -- Store in history
    INSERT INTO public.location_history (
        entity_type, entity_id, location, latitude, longitude,
        accuracy_meters, speed_kmh, heading, source
    )
    VALUES (
        'delivery', p_order_id, v_point, p_latitude, p_longitude,
        p_accuracy_meters, p_speed_kmh, p_heading, 'gps'
    );
    
    RETURN v_location_id;
END;
$$ LANGUAGE plpgsql;

-- 9. Enable RLS
ALTER TABLE public.rider_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.location_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.geofence_alerts ENABLE ROW LEVEL SECURITY;

-- 10. RLS policies for rider_locations
CREATE POLICY "Riders can view their own locations" ON public.rider_locations
    FOR SELECT USING (rider_id = auth.uid());

CREATE POLICY "Admins can view all rider locations" ON public.rider_locations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

CREATE POLICY "Riders can update their own locations" ON public.rider_locations
    FOR UPDATE USING (rider_id = auth.uid());

-- 11. RLS policies for delivery_locations
CREATE POLICY "Users can view delivery locations for their orders" ON public.delivery_locations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE orders.id = delivery_locations.order_id
            AND orders.user_id = auth.uid()
        )
        OR delivery_locations.delivery_agent_id = auth.uid()
    );

CREATE POLICY "Delivery agents can update their locations" ON public.delivery_locations
    FOR UPDATE USING (delivery_agent_id = auth.uid());

CREATE POLICY "Admins can view all delivery locations" ON public.delivery_locations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 12. RLS policies for location_history
CREATE POLICY "Users can view their location history" ON public.location_history
    FOR SELECT USING (
        entity_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 13. RLS policies for geofence_alerts
CREATE POLICY "Users can view their geofence alerts" ON public.geofence_alerts
    FOR SELECT USING (
        rider_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.user_profiles WHERE user_id = auth.uid() AND role = 'admin')
    );

-- 14. Add tables to realtime publication
ALTER PUBLICATION supabase_realtime ADD TABLE rider_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE delivery_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE geofence_alerts;

-- 15. Cleanup old location history (keep last 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_location_history()
RETURNS void AS $$
BEGIN
    DELETE FROM public.location_history
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;


-- ====== 20260210_service_provider_verification.sql ======
-- ============================================
-- SERVICE PROVIDER VERIFICATION SYSTEM
-- For Restaurants, Hotels, Taxi Drivers, Riders
-- ============================================

-- 1. Create verification status ENUM
DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected', 'revision_requested');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE document_type AS ENUM (
        'business_registration',
        'proof_of_address',
        'driver_license',
        'vehicle_registration',
        'operating_permit',
        'tax_certificate',
        'health_certificate',
        'insurance_certificate'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create service_provider_documents table
CREATE TABLE IF NOT EXISTS public.service_provider_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN (
        'business_registration', 'proof_of_address', 'driver_license', 
        'vehicle_registration', 'operating_permit', 'tax_certificate',
        'health_certificate', 'insurance_certificate'
    )),
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expiry_date DATE,
    is_verified BOOLEAN DEFAULT false,
    verification_notes TEXT,
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spd_user_id ON public.service_provider_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_spd_document_type ON public.service_provider_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_spd_is_verified ON public.service_provider_documents(is_verified);

-- 3. Create service_provider_verifications table (main verification record)
CREATE TABLE IF NOT EXISTS public.service_provider_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('restaurant', 'hotel', 'taxi_driver', 'rider')),
    
    -- Business Info
    business_name TEXT NOT NULL,
    business_address TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    
    -- Station Assignment
    assigned_station_id UUID REFERENCES public.stops(id) ON DELETE SET NULL,
    
    -- Approval Status
    overall_status TEXT DEFAULT 'pending' CHECK (overall_status IN ('pending', 'approved', 'rejected', 'revision_requested')),
    status_reason TEXT,
    
    -- Document Checklist
    documents_complete BOOLEAN DEFAULT false,
    business_registration_verified BOOLEAN DEFAULT false,
    address_verified BOOLEAN DEFAULT false,
    license_verified BOOLEAN DEFAULT false,
    health_certificate_verified BOOLEAN DEFAULT false,
    insurance_verified BOOLEAN DEFAULT false,
    
    -- Admin Review
    reviewed_by UUID REFERENCES auth.users(id),
    admin_notes TEXT,
    revision_request_reason TEXT,
    
    -- Workflow Dates
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    first_review_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    
    -- Expiry
    approval_expires_at DATE,
    
    -- Contact Info for Admin
    admin_can_contact_phone TEXT,
    admin_can_contact_email TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spv_user_id ON public.service_provider_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_spv_status ON public.service_provider_verifications(overall_status);
CREATE INDEX IF NOT EXISTS idx_spv_provider_type ON public.service_provider_verifications(provider_type);
CREATE INDEX IF NOT EXISTS idx_spv_station_id ON public.service_provider_verifications(assigned_station_id);

-- 4. Create verification_history table (audit trail)
CREATE TABLE IF NOT EXISTS public.verification_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_id UUID NOT NULL REFERENCES public.service_provider_verifications(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('submitted', 'under_review', 'approved', 'rejected', 'revision_requested', 'resubmitted')),
    performed_by UUID REFERENCES auth.users(id),
    notes TEXT,
    changed_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vh_verification_id ON public.verification_history(verification_id);
CREATE INDEX IF NOT EXISTS idx_vh_created_at ON public.verification_history(created_at);

-- 5. Add RLS Policies
ALTER TABLE public.service_provider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_provider_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_history ENABLE ROW LEVEL SECURITY;

-- Service provider documents policies
DROP POLICY IF EXISTS "Users can view their own documents" ON public.service_provider_documents;
CREATE POLICY "Users can view their own documents" ON public.service_provider_documents
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can upload their own documents" ON public.service_provider_documents;
CREATE POLICY "Users can upload their own documents" ON public.service_provider_documents
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all documents" ON public.service_provider_documents;
CREATE POLICY "Admins can view all documents" ON public.service_provider_documents
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can update documents" ON public.service_provider_documents;
CREATE POLICY "Admins can update documents" ON public.service_provider_documents
    FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Verification policies
DROP POLICY IF EXISTS "Users can view their own verification" ON public.service_provider_verifications;
CREATE POLICY "Users can view their own verification" ON public.service_provider_verifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their verification" ON public.service_provider_verifications;
CREATE POLICY "Users can create their verification" ON public.service_provider_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their pending verification" ON public.service_provider_verifications;
CREATE POLICY "Users can update their pending verification" ON public.service_provider_verifications
    FOR UPDATE USING (auth.uid() = user_id AND overall_status IN ('pending', 'revision_requested'));

DROP POLICY IF EXISTS "Admins can view all verifications" ON public.service_provider_verifications;
CREATE POLICY "Admins can view all verifications" ON public.service_provider_verifications
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can update verifications" ON public.service_provider_verifications;
CREATE POLICY "Admins can update verifications" ON public.service_provider_verifications
    FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Verification history policies
DROP POLICY IF EXISTS "Users can view their verification history" ON public.verification_history;
CREATE POLICY "Users can view their verification history" ON public.verification_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.service_provider_verifications spv
            WHERE spv.id = verification_history.verification_id
            AND spv.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Admins can view all history" ON public.verification_history;
CREATE POLICY "Admins can view all history" ON public.verification_history
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "System can insert history" ON public.verification_history;
CREATE POLICY "System can insert history" ON public.verification_history
    FOR INSERT WITH CHECK (true);

-- 6. Update user_profiles table to use verification status
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS verification_id UUID REFERENCES public.service_provider_verifications(id);
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_user_profiles_verification_id ON public.user_profiles(verification_id);

-- 7. Create function to auto-approve when all documents verified
CREATE OR REPLACE FUNCTION public.check_verification_complete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.service_provider_verifications
    SET
        documents_complete = (
            business_registration_verified 
            AND address_verified 
            AND (license_verified OR provider_type = 'restaurant')
        ),
        updated_at = now()
    WHERE id = NEW.verification_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS check_verification_complete_trigger ON public.service_provider_documents;
CREATE TRIGGER check_verification_complete_trigger
    AFTER UPDATE ON public.service_provider_documents
    FOR EACH ROW EXECUTE FUNCTION public.check_verification_complete();

-- 8. Create function to auto-update user profile when approved
CREATE OR REPLACE FUNCTION public.update_profile_on_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.overall_status = 'approved' AND OLD.overall_status != 'approved' THEN
        UPDATE public.user_profiles
        SET
            is_approved = true,
            assigned_station_id = NEW.assigned_station_id,
            verification_status = 'approved',
            updated_at = now()
        WHERE user_id = NEW.user_id;
        
        INSERT INTO public.verification_history (verification_id, action, performed_by, notes)
        VALUES (NEW.id, 'approved', auth.uid(), 'Automatically updated profile on approval');
    ELSIF NEW.overall_status = 'rejected' AND OLD.overall_status != 'rejected' THEN
        UPDATE public.user_profiles
        SET
            is_approved = false,
            verification_status = 'rejected',
            updated_at = now()
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_profile_on_approval_trigger ON public.service_provider_verifications;
CREATE TRIGGER update_profile_on_approval_trigger
    AFTER UPDATE ON public.service_provider_verifications
    FOR EACH ROW EXECUTE FUNCTION public.update_profile_on_approval();

-- 9. Create function to add history entry on verification changes
CREATE OR REPLACE FUNCTION public.log_verification_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.overall_status IS DISTINCT FROM OLD.overall_status THEN
        INSERT INTO public.verification_history (
            verification_id, 
            action, 
            performed_by,
            notes,
            changed_fields
        ) VALUES (
            NEW.id,
            CASE 
                WHEN NEW.overall_status = 'approved' THEN 'approved'
                WHEN NEW.overall_status = 'rejected' THEN 'rejected'
                WHEN NEW.overall_status = 'revision_requested' THEN 'revision_requested'
                ELSE 'under_review'
            END,
            auth.uid(),
            NEW.status_reason,
            jsonb_build_object(
                'old_status', OLD.overall_status,
                'new_status', NEW.overall_status
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS log_verification_change_trigger ON public.service_provider_verifications;
CREATE TRIGGER log_verification_change_trigger
    BEFORE UPDATE ON public.service_provider_verifications
    FOR EACH ROW EXECUTE FUNCTION public.log_verification_change();

-- 10. Add realtime support
ALTER PUBLICATION supabase_realtime ADD TABLE public.service_provider_verifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_history;


-- ====== add_delivery_tracking.sql ======
-- Supabase Schema for Delivery Tracking System

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "postgis";

-- Rider Locations - Real-time GPS tracking
create table if not exists public.rider_locations (
  rider_id uuid primary key references auth.users(id) on delete cascade,
  latitude decimal(9, 6) not null,
  longitude decimal(9, 6) not null,
  accuracy decimal(5, 2),
  heading decimal(5, 2),
  speed decimal(5, 2),
  timestamp timestamp with time zone default now(),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create index for faster queries
create index if not exists idx_rider_locations_timestamp on public.rider_locations(timestamp desc);

-- RLS Policies for rider_locations
alter table public.rider_locations enable row level security;

create policy "Riders can update own location"
  on public.rider_locations
  for update
  using (auth.uid() = rider_id);

create policy "Riders can insert own location"
  on public.rider_locations
  for insert
  with check (auth.uid() = rider_id);

create policy "Restaurants and admins can view rider locations"
  on public.rider_locations
  for select
  using (
    auth.jwt() ->> 'user_metadata' ->> 'role' in ('restaurant', 'admin')
  );

-- Delivery Jobs
create table if not exists public.delivery_jobs (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references public.orders(id) on delete cascade,
  rider_id uuid not null references public.delivery_agents(user_id) on delete cascade,
  status text not null check (status in ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')) default 'pending',
  origin_stop_id uuid not null references public.stops(id),
  destination_stop_id uuid not null references public.stops(id),
  pickup_location_name text,
  delivery_location_name text,
  estimated_delivery_time timestamp with time zone,
  actual_delivery_time timestamp with time zone,
  notes text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Indexes for delivery_jobs
create index if not exists idx_delivery_jobs_rider on public.delivery_jobs(rider_id);
create index if not exists idx_delivery_jobs_status on public.delivery_jobs(status);
create index if not exists idx_delivery_jobs_created on public.delivery_jobs(created_at desc);

-- RLS Policies for delivery_jobs
alter table public.delivery_jobs enable row level security;

create policy "Riders can view own jobs"
  on public.delivery_jobs
  for select
  using (auth.uid() = rider_id OR auth.jwt() ->> 'user_metadata' ->> 'role' = 'admin');

create policy "Riders can update own jobs"
  on public.delivery_jobs
  for update
  using (auth.uid() = rider_id OR auth.jwt() ->> 'user_metadata' ->> 'role' = 'admin');

-- Route History (for analytics)
create table if not exists public.delivery_routes (
  id uuid primary key default uuid_generate_v4(),
  job_id uuid not null references public.delivery_jobs(id) on delete cascade,
  latitude decimal(9, 6) not null,
  longitude decimal(9, 6) not null,
  accuracy decimal(5, 2),
  speed decimal(5, 2),
  heading decimal(5, 2),
  timestamp timestamp with time zone default now(),
  created_at timestamp with time zone default now()
);

-- Index for route history
create index if not exists idx_delivery_routes_job on public.delivery_routes(job_id);
create index if not exists idx_delivery_routes_timestamp on public.delivery_routes(timestamp desc);

-- Update existing tables if needed
alter table public.orders add column if not exists rider_id uuid references public.delivery_agents(user_id);
alter table public.orders add column if not exists estimated_delivery_time timestamp with time zone;
alter table public.orders add column if not exists actual_delivery_time timestamp with time zone;

-- Create function to update delivery_jobs updated_at timestamp
create or replace function public.update_delivery_jobs_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

-- Create trigger for delivery_jobs
drop trigger if exists update_delivery_jobs_updated_at on public.delivery_jobs;
create trigger update_delivery_jobs_updated_at
  before update on public.delivery_jobs
  for each row
  execute function public.update_delivery_jobs_updated_at();

-- Realtime subscriptions
alter publication supabase_realtime add table public.rider_locations;
alter publication supabase_realtime add table public.delivery_jobs;

-- Grant permissions
grant select on public.rider_locations to authenticated;
grant insert on public.rider_locations to authenticated;
grant update on public.rider_locations to authenticated;

grant select on public.delivery_jobs to authenticated;
grant update on public.delivery_jobs to authenticated;


-- ====== loyalty_wallet_schema.sql ======
-- BusNStay Loyalty & Wallet System Database Schema
-- This SQL script creates all necessary tables for the Loyalty Program and Digital Wallet features
-- Run this in your Supabase SQL Editor after connecting to your project

-- ============================================================================
-- SECTION 1: LOYALTY PROGRAM TABLES
-- ============================================================================

-- User Loyalty Profiles
CREATE TABLE IF NOT EXISTS public.user_loyalty (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_points INT DEFAULT 0 CHECK (current_points >= 0),
  total_points_earned INT DEFAULT 0 CHECK (total_points_earned >= 0),
  total_points_redeemed INT DEFAULT 0 CHECK (total_points_redeemed >= 0),
  tier VARCHAR DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  referral_code VARCHAR UNIQUE NOT NULL,
  referral_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  last_activity TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_user_loyalty_user_id ON public.user_loyalty(user_id);
CREATE INDEX idx_user_loyalty_tier ON public.user_loyalty(tier);
CREATE INDEX idx_user_loyalty_referral_code ON public.user_loyalty(referral_code);

-- Loyalty Transactions (earning, redemption, referral bonus)
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('earning', 'redemption', 'referral', 'bonus', 'expiration')),
  points INT NOT NULL CHECK (points != 0),
  description TEXT NOT NULL,
  related_booking_id UUID,
  related_referral_code VARCHAR,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX idx_loyalty_transactions_type ON public.loyalty_transactions(type);
CREATE INDEX idx_loyalty_transactions_created_at ON public.loyalty_transactions(created_at);

-- Available Rewards Catalog
CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
  id VARCHAR PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  category VARCHAR NOT NULL CHECK (category IN ('discount', 'upgrade', 'gift', 'exclusive', 'experience')),
  points_required INT NOT NULL CHECK (points_required > 0),
  max_redemptions INT DEFAULT NULL, -- NULL = unlimited
  current_redemptions INT DEFAULT 0,
  popularity_score INT DEFAULT 0 CHECK (popularity_score >= 0 AND popularity_score <= 100),
  image_url VARCHAR,
  badge_icon VARCHAR,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_loyalty_rewards_category ON public.loyalty_rewards(category);
CREATE INDEX idx_loyalty_rewards_active ON public.loyalty_rewards(active);

-- Reward Redemptions
CREATE TABLE IF NOT EXISTS public.reward_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reward_id VARCHAR NOT NULL REFERENCES public.loyalty_rewards(id) ON DELETE RESTRICT,
  points_spent INT NOT NULL,
  status VARCHAR DEFAULT 'redeemed' CHECK (status IN ('redeemed', 'used', 'expired', 'cancelled')),
  expires_at TIMESTAMP,
  used_at TIMESTAMP,
  redemption_code VARCHAR UNIQUE,
  redeemed_at TIMESTAMP DEFAULT now(),
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_reward_redemptions_user_id ON public.reward_redemptions(user_id);
CREATE INDEX idx_reward_redemptions_status ON public.reward_redemptions(status);
CREATE INDEX idx_reward_redemptions_reward_id ON public.reward_redemptions(reward_id);

-- Referral Records
CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referee_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referral_code VARCHAR NOT NULL,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired')),
  bonus_points_awarded INT DEFAULT 500,
  points_awarded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  expires_at TIMESTAMP DEFAULT (now() + INTERVAL '90 days'),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_referrals_referrer_user_id ON public.referrals(referrer_user_id);
CREATE INDEX idx_referrals_referee_user_id ON public.referrals(referee_user_id);
CREATE INDEX idx_referrals_referral_code ON public.referrals(referral_code);
CREATE INDEX idx_referrals_status ON public.referrals(status);

-- ============================================================================
-- SECTION 2: DIGITAL WALLET TABLES
-- ============================================================================

-- User Wallets
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance DECIMAL(12, 2) DEFAULT 0 CHECK (balance >= 0),
  currency VARCHAR DEFAULT 'USD',
  wallet_status VARCHAR DEFAULT 'active' CHECK (wallet_status IN ('active', 'suspended', 'closed')),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  last_activity TIMESTAMP DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX idx_wallets_status ON public.wallets(wallet_status);

-- Wallet Transactions
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('debit', 'credit', 'refund', 'transfer', 'withdrawal', 'deposit')),
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  description TEXT NOT NULL,
  status VARCHAR DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  related_booking_id UUID,
  related_order_id VARCHAR,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  transaction_reference VARCHAR UNIQUE,
  failure_reason VARCHAR,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_type ON public.wallet_transactions(type);
CREATE INDEX idx_wallet_transactions_status ON public.wallet_transactions(status);
CREATE INDEX idx_wallet_transactions_created_at ON public.wallet_transactions(created_at);

-- Payment Methods (stored securely)
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('card', 'mobile', 'bank', 'wallet')),
  name VARCHAR NOT NULL,
  provider VARCHAR, -- e.g., 'stripe', 'paypal', 'mtn', 'airtel'
  payment_token VARCHAR NOT NULL, -- Should be encrypted in the application layer
  last_digits VARCHAR(4), -- e.g., "4242"
  expiry_date VARCHAR, -- For cards: MM/YY
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX idx_payment_methods_type ON public.payment_methods(type);
CREATE INDEX idx_payment_methods_is_default ON public.payment_methods(is_default) WHERE is_default = true;

-- Wallet Deposits/Top-ups
CREATE TABLE IF NOT EXISTS public.wallet_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR DEFAULT 'USD',
  payment_method_id UUID NOT NULL REFERENCES public.payment_methods(id) ON DELETE RESTRICT,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  transaction_reference VARCHAR UNIQUE,
  processor_response JSONB,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  failed_at TIMESTAMP,
  failure_reason VARCHAR
);

CREATE INDEX idx_wallet_deposits_wallet_id ON public.wallet_deposits(wallet_id);
CREATE INDEX idx_wallet_deposits_status ON public.wallet_deposits(status);
CREATE INDEX idx_wallet_deposits_created_at ON public.wallet_deposits(created_at);

-- Wallet Transfers (peer-to-peer)
CREATE TABLE IF NOT EXISTS public.wallet_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  to_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  description VARCHAR,
  status VARCHAR DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP
);

CREATE INDEX idx_wallet_transfers_from_wallet_id ON public.wallet_transfers(from_wallet_id);
CREATE INDEX idx_wallet_transfers_to_wallet_id ON public.wallet_transfers(to_wallet_id);
CREATE INDEX idx_wallet_transfers_created_at ON public.wallet_transfers(created_at);

-- ============================================================================
-- SECTION 3: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.user_loyalty ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transfers ENABLE ROW LEVEL SECURITY;

-- User Loyalty RLS
CREATE POLICY "Users can view their own loyalty profile"
  ON public.user_loyalty FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own loyalty profile"
  ON public.user_loyalty FOR UPDATE USING (auth.uid() = user_id);

-- Loyalty Transactions RLS
CREATE POLICY "Users can view their own transactions"
  ON public.loyalty_transactions FOR SELECT USING (auth.uid() = user_id);

-- Rewards RLS
CREATE POLICY "Anyone can view active rewards"
  ON public.loyalty_rewards FOR SELECT USING (active = true);

-- Reward Redemptions RLS
CREATE POLICY "Users can view their own redemptions"
  ON public.reward_redemptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create redemptions for themselves"
  ON public.reward_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Wallets RLS
CREATE POLICY "Users can view their own wallet"
  ON public.wallets FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet"
  ON public.wallets FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Transactions RLS
CREATE POLICY "Users can view their own transactions"
  ON public.wallet_transactions FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = wallet_id)
  );

-- Payment Methods RLS
CREATE POLICY "Users can view their own payment methods"
  ON public.payment_methods FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create payment methods"
  ON public.payment_methods FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment methods"
  ON public.payment_methods FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Deposits RLS
CREATE POLICY "Users can view their own deposits"
  ON public.wallet_deposits FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = wallet_id)
  );

-- Wallet Transfers RLS
CREATE POLICY "Users can view transfers involving their wallet"
  ON public.wallet_transfers FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = from_wallet_id) OR
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = to_wallet_id)
  );

-- ============================================================================
-- SECTION 4: SEED DATA (SAMPLE REWARDS)
-- ============================================================================

INSERT INTO public.loyalty_rewards (id, name, description, category, points_required, popularity_score, badge_icon, active) VALUES
  ('free-ride-50', 'Free Ride ($50)', 'Get a $50 credit towards your next bus trip', 'discount', 1000, 92, '🎫', true),
  ('hotel-upgrade', 'Hotel Room Upgrade', 'Complimentary room upgrade at partner hotels', 'exclusive', 800, 88, '🏨', true),
  ('meals-3', '3 Meal Vouchers', 'Three $10 meal vouchers for partner restaurants', 'gift', 600, 85, '🍽️', true),
  ('credit-20', '$20 Travel Credit', 'Universal credit for any travel service', 'discount', 400, 95, '💳', true),
  ('vip-badge', '30-Day VIP Badge', 'VIP status for priority support and benefits', 'exclusive', 2000, 78, '👑', true),
  ('airport-transfer', 'Free Airport Transfer', 'One complimentary airport transfer anywhere', 'experience', 1500, 82, '🚗', true);

-- ============================================================================
-- SECTION 5: HELPER FUNCTIONS
-- ============================================================================

-- Function to calculate tier based on points
CREATE OR REPLACE FUNCTION calculate_loyalty_tier(points INT)
RETURNS VARCHAR AS $$
BEGIN
  CASE
    WHEN points >= 10000 THEN RETURN 'platinum';
    WHEN points >= 5000 THEN RETURN 'gold';
    WHEN points >= 1000 THEN RETURN 'silver';
    ELSE RETURN 'bronze';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update user tier and last activity
CREATE OR REPLACE FUNCTION update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.user_loyalty
  SET
    tier = calculate_loyalty_tier(NEW.current_points),
    updated_at = now(),
    last_activity = now()
  WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update tier when points change
CREATE TRIGGER tr_update_loyalty_tier
AFTER UPDATE OF current_points ON public.user_loyalty
FOR EACH ROW
WHEN (OLD.current_points IS DISTINCT FROM NEW.current_points)
EXECUTE FUNCTION update_loyalty_tier();

-- Function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    UPDATE public.wallets
    SET
      balance = CASE
        WHEN NEW.type IN ('credit', 'refund', 'transfer', 'deposit') THEN balance + NEW.amount
        WHEN NEW.type IN ('debit', 'withdrawal') THEN balance - NEW.amount
        ELSE balance
      END,
      updated_at = now(),
      last_activity = now()
    WHERE id = NEW.wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update wallet balance on transaction
CREATE TRIGGER tr_update_wallet_balance
AFTER INSERT OR UPDATE ON public.wallet_transactions
FOR EACH ROW
EXECUTE FUNCTION update_wallet_balance();

-- ============================================================================
-- SECTION 6: VIEWS FOR COMMON QUERIES
-- ============================================================================

-- User Loyalty Summary View
CREATE OR REPLACE VIEW public.user_loyalty_summary AS
SELECT
  ul.user_id,
  ul.current_points,
  ul.total_points_earned,
  ul.tier,
  ul.referral_count,
  COUNT(DISTINCT CASE WHEN lt.type = 'earning' THEN lt.id END) as earning_count,
  COUNT(DISTINCT CASE WHEN lt.type = 'redemption' THEN lt.id END) as redemption_count,
  MAX(lt.created_at) as last_transaction_date
FROM public.user_loyalty ul
LEFT JOIN public.loyalty_transactions lt ON ul.user_id = lt.user_id
GROUP BY ul.user_id, ul.current_points, ul.total_points_earned, ul.tier, ul.referral_count;

-- Wallet Summary View
CREATE OR REPLACE VIEW public.wallet_summary AS
SELECT
  w.user_id,
  w.balance,
  w.currency,
  COUNT(DISTINCT CASE WHEN wt.type = 'debit' THEN wt.id END) as debit_count,
  COUNT(DISTINCT CASE WHEN wt.type = 'credit' THEN wt.id END) as credit_count,
  COALESCE(SUM(CASE WHEN wt.type IN ('debit', 'withdrawal') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as total_spent,
  COALESCE(SUM(CASE WHEN wt.type IN ('credit', 'refund') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as total_credited,
  MAX(wt.created_at) as last_transaction_date
FROM public.wallets w
LEFT JOIN public.wallet_transactions wt ON w.id = wt.wallet_id
GROUP BY w.user_id, w.balance, w.currency;

-- Monthly Wallet Analytics View
CREATE OR REPLACE VIEW public.wallet_monthly_analytics AS
SELECT
  w.user_id,
  DATE_TRUNC('month', wt.created_at)::DATE as month,
  COALESCE(SUM(CASE WHEN wt.type IN ('debit', 'withdrawal') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as monthly_spent,
  COALESCE(SUM(CASE WHEN wt.type IN ('credit', 'refund') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as monthly_credited,
  COUNT(DISTINCT wt.id) as transaction_count
FROM public.wallets w
LEFT JOIN public.wallet_transactions wt ON w.id = wt.wallet_id
GROUP BY w.user_id, DATE_TRUNC('month', wt.created_at);

-- ============================================================================
-- All tables and views are now ready for use!
-- ============================================================================


-- ====== 20260401_restaurant_approval_workflow.sql ======
-- Restaurant Approval Workflow Migration
-- BusNStay Platform - Ensures only admin-approved restaurants appear to users

-- Add approval columns to restaurants table
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS is_approved BOOLEAN DEFAULT false;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'suspended'));
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS approval_date TIMESTAMPTZ;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS approved_by_admin_id UUID REFERENCES auth.users(id);
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS business_license_number TEXT;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS business_license_expiry DATE;
ALTER TABLE restaurants ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

-- Create approval logs table for audit trail
CREATE TABLE IF NOT EXISTS restaurant_approval_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  restaurant_id UUID NOT NULL REFERENCES restaurants(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('submitted', 'approved', 'rejected', 'suspended', 'resubmitted')),
  admin_id UUID REFERENCES auth.users(id),
  reason TEXT,
  previous_status TEXT,
  new_status TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_restaurants_approval_status ON restaurants(approval_status);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_approved ON restaurants(is_approved);
CREATE INDEX IF NOT EXISTS idx_restaurant_approval_logs_restaurant_id ON restaurant_approval_logs(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_approval_logs_admin_id ON restaurant_approval_logs(admin_id);

-- Trigger function to auto-log approval changes
CREATE OR REPLACE FUNCTION log_restaurant_approval_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.approval_status IS DISTINCT FROM NEW.approval_status THEN
    INSERT INTO restaurant_approval_logs (restaurant_id, action, admin_id, reason, previous_status, new_status)
    VALUES (NEW.id, NEW.approval_status, NEW.approved_by_admin_id, NEW.rejection_reason, OLD.approval_status, NEW.approval_status);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_restaurant_approval_change ON restaurants;
CREATE TRIGGER trigger_restaurant_approval_change
  AFTER UPDATE OF approval_status ON restaurants
  FOR EACH ROW
  EXECUTE FUNCTION log_restaurant_approval_change();

-- Function to update restaurant GPS coordinates
CREATE OR REPLACE FUNCTION update_restaurant_gps_coordinates()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL THEN
    NEW.location = ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE restaurants ENABLE ROW LEVEL SECURITY;
ALTER TABLE restaurant_approval_logs ENABLE ROW LEVEL SECURITY;

-- Users can only see approved restaurants
DROP POLICY IF EXISTS "Users see approved restaurants" ON restaurants;
CREATE POLICY "Users see approved restaurants" ON restaurants
  FOR SELECT
  USING (is_approved = true AND approval_status = 'approved');

-- Restaurant owners can see their own restaurants regardless of status
DROP POLICY IF EXISTS "Owners see own restaurants" ON restaurants;
CREATE POLICY "Owners see own restaurants" ON restaurants
  FOR SELECT
  USING (auth.uid() = owner_id);

-- Restaurant owners can update their own restaurants
DROP POLICY IF EXISTS "Owners update own restaurants" ON restaurants;
CREATE POLICY "Owners update own restaurants" ON restaurants
  FOR UPDATE
  USING (auth.uid() = owner_id);

-- Anyone can insert (submit) a restaurant
DROP POLICY IF EXISTS "Anyone can submit restaurant" ON restaurants;
CREATE POLICY "Anyone can submit restaurant" ON restaurants
  FOR INSERT
  WITH CHECK (true);

-- Approval logs viewable by admins and restaurant owners
DROP POLICY IF EXISTS "View approval logs" ON restaurant_approval_logs;
CREATE POLICY "View approval logs" ON restaurant_approval_logs
  FOR SELECT
  USING (true);

-- Only system can insert approval logs
DROP POLICY IF EXISTS "System inserts approval logs" ON restaurant_approval_logs;
CREATE POLICY "System inserts approval logs" ON restaurant_approval_logs
  FOR INSERT
  WITH CHECK (true);

-- Update existing restaurants to approved status (so existing data isn't hidden)
UPDATE restaurants SET is_approved = true, approval_status = 'approved' WHERE is_approved IS NULL OR is_approved = false;


-- ====== 20260401_hotel_room_management.sql ======
-- Hotel Room Management Migration
-- BusNStay Platform - Hotel room CRUD, availability, reviews, and rate history

-- Hotel Rooms table
CREATE TABLE IF NOT EXISTS hotel_rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  accommodation_id UUID NOT NULL,
  room_number TEXT NOT NULL,
  room_type TEXT NOT NULL DEFAULT 'double' CHECK (room_type IN ('single', 'double', 'twin', 'suite', 'family', 'dormitory')),
  capacity INTEGER NOT NULL DEFAULT 2,
  price_per_night DECIMAL(10,2) NOT NULL DEFAULT 0,
  base_price DECIMAL(10,2) NOT NULL DEFAULT 0,
  discount_percentage DECIMAL(5,2) DEFAULT 0,
  description TEXT DEFAULT '',
  amenities JSONB DEFAULT '[]'::jsonb,
  images JSONB DEFAULT '[]'::jsonb,
  is_available BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  occupancy_status TEXT DEFAULT 'available' CHECK (occupancy_status IN ('available', 'occupied', 'maintenance', 'reserved')),
  last_cleaning TIMESTAMPTZ,
  next_available_date DATE,
  total_bookings INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(accommodation_id, room_number)
);

-- Room Reviews table
CREATE TABLE IF NOT EXISTS room_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES hotel_rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  guest_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room Availability table (for calendar blocking)
CREATE TABLE IF NOT EXISTS room_availability (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES hotel_rooms(id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'booked', 'blocked', 'maintenance')),
  price_per_night DECIMAL(10,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(room_id, date)
);

-- Room Rate History table
CREATE TABLE IF NOT EXISTS room_rate_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES hotel_rooms(id) ON DELETE CASCADE,
  previous_price DECIMAL(10,2),
  new_price DECIMAL(10,2) NOT NULL,
  changed_by UUID REFERENCES auth.users(id),
  reason TEXT,
  effective_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_accommodation ON hotel_rooms(accommodation_id);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_type ON hotel_rooms(room_type);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_status ON hotel_rooms(occupancy_status);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_active ON hotel_rooms(is_active);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_available ON hotel_rooms(is_available);
CREATE INDEX IF NOT EXISTS idx_room_reviews_room ON room_reviews(room_id);
CREATE INDEX IF NOT EXISTS idx_room_availability_room_date ON room_availability(room_id, date);
CREATE INDEX IF NOT EXISTS idx_room_rate_history_room ON room_rate_history(room_id);

-- Function to update room average rating
CREATE OR REPLACE FUNCTION update_room_average_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE hotel_rooms
  SET average_rating = (
    SELECT COALESCE(AVG(rating), 0)
    FROM room_reviews
    WHERE room_id = COALESCE(NEW.room_id, OLD.room_id)
  )
  WHERE id = COALESCE(NEW.room_id, OLD.room_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_room_rating ON room_reviews;
CREATE TRIGGER trigger_update_room_rating
  AFTER INSERT OR UPDATE OR DELETE ON room_reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_room_average_rating();

-- Function to get available rooms for date range
CREATE OR REPLACE FUNCTION get_available_rooms(
  p_accommodation_id UUID,
  p_check_in DATE,
  p_check_out DATE
)
RETURNS SETOF hotel_rooms AS $$
BEGIN
  RETURN QUERY
  SELECT r.*
  FROM hotel_rooms r
  WHERE r.accommodation_id = p_accommodation_id
    AND r.is_active = true
    AND r.is_available = true
    AND r.id NOT IN (
      SELECT ra.room_id
      FROM room_availability ra
      WHERE ra.room_id = r.id
        AND ra.date >= p_check_in
        AND ra.date < p_check_out
        AND ra.status IN ('booked', 'blocked', 'maintenance')
    )
  ORDER BY r.price_per_night ASC;
END;
$$ LANGUAGE plpgsql;

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION update_hotel_room_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_hotel_room_updated ON hotel_rooms;
CREATE TRIGGER trigger_hotel_room_updated
  BEFORE UPDATE ON hotel_rooms
  FOR EACH ROW
  EXECUTE FUNCTION update_hotel_room_timestamp();

-- RLS Policies
ALTER TABLE hotel_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_rate_history ENABLE ROW LEVEL SECURITY;

-- Anyone can view active rooms
DROP POLICY IF EXISTS "Anyone can view active rooms" ON hotel_rooms;
CREATE POLICY "Anyone can view active rooms" ON hotel_rooms
  FOR SELECT USING (true);

-- Owners can manage rooms
DROP POLICY IF EXISTS "Owners can manage rooms" ON hotel_rooms;
CREATE POLICY "Owners can manage rooms" ON hotel_rooms
  FOR ALL USING (true);

-- Anyone can view reviews
DROP POLICY IF EXISTS "Anyone can view reviews" ON room_reviews;
CREATE POLICY "Anyone can view reviews" ON room_reviews
  FOR SELECT USING (true);

-- Authenticated users can add reviews
DROP POLICY IF EXISTS "Users can add reviews" ON room_reviews;
CREATE POLICY "Users can add reviews" ON room_reviews
  FOR INSERT WITH CHECK (true);

-- Room availability policies
DROP POLICY IF EXISTS "View room availability" ON room_availability;
CREATE POLICY "View room availability" ON room_availability
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Manage room availability" ON room_availability;
CREATE POLICY "Manage room availability" ON room_availability
  FOR ALL USING (true);

-- Rate history policies
DROP POLICY IF EXISTS "View rate history" ON room_rate_history;
CREATE POLICY "View rate history" ON room_rate_history
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insert rate history" ON room_rate_history;
CREATE POLICY "Insert rate history" ON room_rate_history
  FOR INSERT WITH CHECK (true);


-- ====== 20260401_flutterwave_payment_system.sql ======
-- Flutterwave Payment System Migration
-- BusNStay Platform - Payment transactions, logs, disputes, and analytics

-- Payment method enum type (using check constraint for compatibility)
-- Payment status enum type (using check constraint for compatibility)

-- Payment Transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  flutterwave_ref TEXT,
  tx_ref TEXT NOT NULL UNIQUE,
  amount DECIMAL(12,2) NOT NULL,
  currency TEXT NOT NULL DEFAULT 'ZMW',
  payment_method TEXT NOT NULL DEFAULT 'mobile_money' CHECK (payment_method IN ('card', 'mobile_money', 'bank_transfer', 'ussd', 'wallet')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded', 'disputed')),
  description TEXT,
  booking_id UUID,
  order_id UUID,
  customer_email TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT,
  platform_fee DECIMAL(10,2) DEFAULT 0,
  net_amount DECIMAL(12,2) DEFAULT 0,
  refund_amount DECIMAL(12,2) DEFAULT 0,
  metadata JSONB DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Logs table (audit trail)
CREATE TABLE IF NOT EXISTS payment_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  event TEXT NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Retries table
CREATE TABLE IF NOT EXISTS payment_retries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Disputes table
CREATE TABLE IF NOT EXISTS payment_disputes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'under_review', 'resolved', 'rejected')),
  resolution TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_tx_ref ON payment_transactions(tx_ref);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_flw_ref ON payment_transactions(flutterwave_ref);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_booking ON payment_transactions(booking_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_order ON payment_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created ON payment_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_method ON payment_transactions(payment_method);
CREATE INDEX IF NOT EXISTS idx_payment_logs_transaction ON payment_logs(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_transaction ON payment_disputes(transaction_id);

-- Function to update payment status with logging
CREATE OR REPLACE FUNCTION update_payment_status(
  p_tx_ref TEXT,
  p_status TEXT,
  p_flutterwave_ref TEXT DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  UPDATE payment_transactions
  SET
    status = p_status,
    flutterwave_ref = COALESCE(p_flutterwave_ref, flutterwave_ref),
    updated_at = NOW()
  WHERE tx_ref = p_tx_ref;

  INSERT INTO payment_logs (transaction_id, event, payload)
  VALUES (p_tx_ref, 'status_update', jsonb_build_object('new_status', p_status, 'flutterwave_ref', p_flutterwave_ref));
END;
$$ LANGUAGE plpgsql;

-- Function to record payment retry
CREATE OR REPLACE FUNCTION record_payment_retry(
  p_transaction_id UUID,
  p_status TEXT,
  p_error_message TEXT DEFAULT NULL
)
RETURNS VOID AS $$
DECLARE
  v_attempt INTEGER;
BEGIN
  SELECT COALESCE(MAX(attempt_number), 0) + 1 INTO v_attempt
  FROM payment_retries WHERE transaction_id = p_transaction_id;

  INSERT INTO payment_retries (transaction_id, attempt_number, status, error_message)
  VALUES (p_transaction_id, v_attempt, p_status, p_error_message);
END;
$$ LANGUAGE plpgsql;

-- Function to create refund
CREATE OR REPLACE FUNCTION create_refund(
  p_transaction_id UUID,
  p_amount DECIMAL,
  p_reason TEXT DEFAULT 'Customer requested refund'
)
RETURNS VOID AS $$
BEGIN
  UPDATE payment_transactions
  SET
    status = 'refunded',
    refund_amount = p_amount,
    updated_at = NOW()
  WHERE id = p_transaction_id;

  INSERT INTO payment_logs (transaction_id, event, payload)
  VALUES (p_transaction_id::text, 'refund', jsonb_build_object('amount', p_amount, 'reason', p_reason));
END;
$$ LANGUAGE plpgsql;

-- Auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_payment_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_payment_updated ON payment_transactions;
CREATE TRIGGER trigger_payment_updated
  BEFORE UPDATE ON payment_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_timestamp();

-- Analytics view
CREATE OR REPLACE VIEW payment_analytics AS
SELECT
  DATE_TRUNC('day', created_at) AS day,
  payment_method,
  status,
  COUNT(*) AS transaction_count,
  SUM(amount) AS total_amount,
  SUM(platform_fee) AS total_fees,
  AVG(amount) AS avg_amount
FROM payment_transactions
GROUP BY DATE_TRUNC('day', created_at), payment_method, status
ORDER BY day DESC;

-- Payment success rate view
CREATE OR REPLACE VIEW payment_success_rate AS
SELECT
  payment_method,
  COUNT(*) AS total,
  COUNT(*) FILTER (WHERE status = 'completed') AS successful,
  COUNT(*) FILTER (WHERE status = 'failed') AS failed,
  ROUND(
    COUNT(*) FILTER (WHERE status = 'completed')::DECIMAL / NULLIF(COUNT(*), 0) * 100, 2
  ) AS success_rate
FROM payment_transactions
GROUP BY payment_method;

-- RLS Policies
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_retries ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_disputes ENABLE ROW LEVEL SECURITY;

-- Users can see their own transactions
DROP POLICY IF EXISTS "Users see own transactions" ON payment_transactions;
CREATE POLICY "Users see own transactions" ON payment_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- Users can create transactions
DROP POLICY IF EXISTS "Users create transactions" ON payment_transactions;
CREATE POLICY "Users create transactions" ON payment_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own transactions
DROP POLICY IF EXISTS "Users update own transactions" ON payment_transactions;
CREATE POLICY "Users update own transactions" ON payment_transactions
  FOR UPDATE USING (auth.uid() = user_id);

-- Payment logs viewable by transaction owner
DROP POLICY IF EXISTS "View payment logs" ON payment_logs;
CREATE POLICY "View payment logs" ON payment_logs
  FOR SELECT USING (true);

-- System can insert payment logs
DROP POLICY IF EXISTS "Insert payment logs" ON payment_logs;
CREATE POLICY "Insert payment logs" ON payment_logs
  FOR INSERT WITH CHECK (true);

-- Payment retries
DROP POLICY IF EXISTS "View payment retries" ON payment_retries;
CREATE POLICY "View payment retries" ON payment_retries
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Insert payment retries" ON payment_retries;
CREATE POLICY "Insert payment retries" ON payment_retries
  FOR INSERT WITH CHECK (true);

-- Disputes
DROP POLICY IF EXISTS "Users see own disputes" ON payment_disputes;
CREATE POLICY "Users see own disputes" ON payment_disputes
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users create disputes" ON payment_disputes;
CREATE POLICY "Users create disputes" ON payment_disputes
  FOR INSERT WITH CHECK (true);



