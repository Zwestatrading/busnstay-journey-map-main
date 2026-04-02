-- ============================================================================
-- BusNStay Town Order Management & Restaurant Notification System
-- SAFE Migration (handles existing objects gracefully)
-- ============================================================================

-- Drop IF EXISTS first to handle re-runs
DROP INDEX IF EXISTS public.idx_journeys_bus_id CASCADE;
DROP INDEX IF EXISTS public.idx_journeys_is_active CASCADE;
DROP INDEX IF EXISTS public.idx_journeys_created_at CASCADE;
DROP INDEX IF EXISTS public.idx_journey_towns_journey_id CASCADE;
DROP INDEX IF EXISTS public.idx_journey_towns_status CASCADE;
DROP INDEX IF EXISTS public.idx_journey_towns_town_id CASCADE;
DROP INDEX IF EXISTS public.idx_orders_customer_id CASCADE;
DROP INDEX IF EXISTS public.idx_orders_restaurant_id CASCADE;
DROP INDEX IF EXISTS public.idx_orders_journey_id CASCADE;
DROP INDEX IF EXISTS public.idx_orders_town_id CASCADE;
DROP INDEX IF EXISTS public.idx_orders_status CASCADE;
DROP INDEX IF EXISTS public.idx_orders_created_at CASCADE;
DROP INDEX IF EXISTS public.idx_orders_payment_confirmed CASCADE;
DROP INDEX IF EXISTS public.idx_restaurant_notifications_restaurant_id CASCADE;
DROP INDEX IF EXISTS public.idx_restaurant_notifications_order_id CASCADE;
DROP INDEX IF EXISTS public.idx_restaurant_notifications_read CASCADE;
DROP INDEX IF EXISTS public.idx_restaurant_notifications_created_at CASCADE;
DROP INDEX IF EXISTS public.idx_notification_deliveries_notification_id CASCADE;
DROP INDEX IF EXISTS public.idx_notification_deliveries_channel CASCADE;
DROP INDEX IF EXISTS public.idx_notification_deliveries_sent_at CASCADE;
DROP INDEX IF EXISTS public.idx_notification_audit_restaurant_id CASCADE;
DROP INDEX IF EXISTS public.idx_notification_audit_timestamp CASCADE;
DROP INDEX IF EXISTS public.idx_town_status_updates_journey_id CASCADE;
DROP INDEX IF EXISTS public.idx_town_status_updates_created_at CASCADE;

-- Drop existing composite index if exists
DROP INDEX IF EXISTS public.idx_journey_towns_journey_town CASCADE;

-- ============= ENUMS / TYPES (create only if not exist) =============

DO $$ 
BEGIN
  CREATE TYPE town_status AS ENUM ('open', 'closed', 'locked');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  CREATE TYPE order_status AS ENUM ('pending', 'accepted', 'preparing', 'ready', 'completed', 'cancelled');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ 
BEGIN
  CREATE TYPE notification_channel AS ENUM ('inApp', 'whatsApp', 'sms', 'email');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============= JOURNEYS & TOWNS =============

-- Journeys table (bus routes)
CREATE TABLE IF NOT EXISTS public.journeys (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  bus_id TEXT NOT NULL,
  route_name TEXT NOT NULL,
  departure_time TIMESTAMPTZ NOT NULL,
  estimated_arrival_time TIMESTAMPTZ NOT NULL,
  current_latitude DOUBLE PRECISION DEFAULT 0.0,
  current_longitude DOUBLE PRECISION DEFAULT 0.0,
  last_position_update TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_coordinates CHECK (
    current_latitude BETWEEN -90 AND 90 AND
    current_longitude BETWEEN -180 AND 180
  )
);

CREATE INDEX idx_journeys_bus_id ON public.journeys(bus_id);
CREATE INDEX idx_journeys_is_active ON public.journeys(is_active);
CREATE INDEX idx_journeys_created_at ON public.journeys(created_at);

-- Journey towns (stops along the route)
CREATE TABLE IF NOT EXISTS public.journey_towns (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  journey_id TEXT NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  town_id TEXT NOT NULL,
  town_name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  pickup_station_name TEXT NOT NULL,
  estimated_stop_duration_seconds INTEGER DEFAULT 600,
  
  -- Status management
  status town_status DEFAULT 'open',
  status_changed_at TIMESTAMPTZ,
  eta_to_town INTEGER, -- In seconds
  distance_to_town DOUBLE PRECISION, -- In kilometers
  
  -- Configuration
  order_cutoff_before_minutes INTEGER DEFAULT 10,
  order_cutoff_distance_km DOUBLE PRECISION DEFAULT 3.0,
  
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_town_coordinates CHECK (
    latitude BETWEEN -90 AND 90 AND
    longitude BETWEEN -180 AND 180
  ),
  CONSTRAINT valid_distance CHECK (distance_to_town >= 0),
  UNIQUE(journey_id, town_id)
);

CREATE INDEX idx_journey_towns_journey_id ON public.journey_towns(journey_id);
CREATE INDEX idx_journey_towns_status ON public.journey_towns(status);
CREATE INDEX idx_journey_towns_town_id ON public.journey_towns(town_id);
CREATE INDEX idx_journey_towns_journey_town ON public.journey_towns(journey_id, town_id);

-- ============= ORDERS =============

-- Food orders (enhanced schema)
CREATE TABLE IF NOT EXISTS public.orders (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  
  -- Customer information
  customer_id TEXT NOT NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  
  -- Restaurant and journey information
  restaurant_id TEXT NOT NULL,
  restaurant_name TEXT NOT NULL,
  journey_id TEXT NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  town_id TEXT NOT NULL,
  town_name TEXT NOT NULL,
  
  -- Order content
  items JSONB NOT NULL,
  special_instructions TEXT,
  
  -- Pricing
  subtotal DECIMAL(10, 2) NOT NULL,
  delivery_fee DECIMAL(10, 2) DEFAULT 0,
  platform_fee DECIMAL(10, 2) DEFAULT 0,
  total_amount DECIMAL(10, 2) NOT NULL,
  currency TEXT DEFAULT 'ZMW',
  
  -- Payment & Status
  status order_status DEFAULT 'pending',
  payment_confirmed_at TIMESTAMPTZ,
  estimated_bus_arrival_time TIMESTAMPTZ,
  restaurant_notified BOOLEAN DEFAULT false,
  restaurant_notified_at TIMESTAMPTZ,
  
  -- Delivery information
  pickup_address TEXT,
  delivery_address TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT total_matches_calculation CHECK (
    total_amount = subtotal + COALESCE(delivery_fee, 0) + COALESCE(platform_fee, 0)
  )
);

CREATE INDEX idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX idx_orders_restaurant_id ON public.orders(restaurant_id);
CREATE INDEX idx_orders_journey_id ON public.orders(journey_id);
CREATE INDEX idx_orders_town_id ON public.orders(town_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_created_at ON public.orders(created_at);
CREATE INDEX idx_orders_payment_confirmed ON public.orders(payment_confirmed_at);

-- ============= RESTAURANT NOTIFICATIONS =============

-- Restaurant notifications (audit trail for order notifications)
CREATE TABLE IF NOT EXISTS public.restaurant_notifications (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  restaurant_id TEXT NOT NULL,
  order_id TEXT NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  
  -- Message content
  message TEXT NOT NULL,
  notification_type TEXT NOT NULL,
  order_details JSONB,
  town_name TEXT,
  estimated_arrival_minutes INTEGER,
  
  -- Status tracking
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMPTZ,
  acknowledged BOOLEAN DEFAULT false,
  acknowledged_at TIMESTAMPTZ,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  CONSTRAINT valid_type CHECK (
    notification_type IN ('order_placed', 'order_ready', 'pickup_ready', 'order_cancelled')
  )
);

CREATE INDEX idx_restaurant_notifications_restaurant_id 
  ON public.restaurant_notifications(restaurant_id);
CREATE INDEX idx_restaurant_notifications_order_id 
  ON public.restaurant_notifications(order_id);
CREATE INDEX idx_restaurant_notifications_read 
  ON public.restaurant_notifications(read);
CREATE INDEX idx_restaurant_notifications_created_at 
  ON public.restaurant_notifications(created_at);

-- Notification delivery tracking
CREATE TABLE IF NOT EXISTS public.notification_deliveries (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  notification_id TEXT NOT NULL REFERENCES public.restaurant_notifications(id) ON DELETE CASCADE,
  channel notification_channel NOT NULL,
  
  recipient_phone TEXT,
  recipient_email TEXT,
  
  sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMPTZ,
  delivery_status TEXT,
  error_message TEXT,
  
  retry_count INTEGER DEFAULT 0,
  last_retry_at TIMESTAMPTZ,
  
  external_message_id TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_deliveries_notification_id 
  ON public.notification_deliveries(notification_id);
CREATE INDEX idx_notification_deliveries_channel 
  ON public.notification_deliveries(channel);
CREATE INDEX idx_notification_deliveries_sent_at 
  ON public.notification_deliveries(sent_at);

-- Notification audit log
CREATE TABLE IF NOT EXISTS public.notification_audit_log (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  notification_id TEXT,
  order_id TEXT REFERENCES public.orders(id),
  restaurant_id TEXT NOT NULL,
  action TEXT NOT NULL,
  channel notification_channel,
  details JSONB,
  timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notification_audit_restaurant_id 
  ON public.notification_audit_log(restaurant_id);
CREATE INDEX idx_notification_audit_timestamp 
  ON public.notification_audit_log(timestamp);

-- ============= TOWN STATUS UPDATES =============

CREATE TABLE IF NOT EXISTS public.town_status_updates (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  journey_id TEXT NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  town_id TEXT NOT NULL,
  town_name TEXT NOT NULL,
  
  old_status town_status,
  new_status town_status NOT NULL,
  reason TEXT,
  
  changed_at TIMESTAMPTZ DEFAULT NOW(),
  triggered_by TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_town_status_updates_journey_id 
  ON public.town_status_updates(journey_id);
CREATE INDEX idx_town_status_updates_created_at 
  ON public.town_status_updates(created_at);

-- ============= RLS POLICIES =============

ALTER TABLE public.journeys ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journey_towns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_deliveries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.town_status_updates ENABLE ROW LEVEL SECURITY;

-- Public can view journeys (you may want to restrict this)
CREATE POLICY "Anyone_can_view_journeys" ON public.journeys
FOR SELECT USING (true);

-- Public can create/view orders
CREATE POLICY "Anyone_can_create_orders" ON public.orders
FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone_can_view_orders" ON public.orders
FOR SELECT USING (true);

-- Public can view restaurant notifications
CREATE POLICY "Anyone_can_view_notifications" ON public.restaurant_notifications
FOR SELECT USING (true);

CREATE POLICY "Anyone_can_view_deliveries" ON public.notification_deliveries
FOR SELECT USING (true);

CREATE POLICY "Anyone_can_view_town_updates" ON public.town_status_updates
FOR SELECT USING (true);

-- ============= COMPLETION MESSAGE =============

DO $$
BEGIN
  RAISE NOTICE 'BusNStay Order Management System initialized successfully!';
  RAISE NOTICE 'Tables created: journeys, journey_towns, orders, restaurant_notifications, notification_deliveries, town_status_updates';
END $$;
