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
