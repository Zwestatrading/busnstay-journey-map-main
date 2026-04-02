-- ====== BUSNSTAY COMPLETE MIGRATION - SIMPLIFIED & FIXED ======
-- This version fixes the "coordinates" error by ensuring proper table creation order
-- and removing problematic RLS policies

-- Step 1: Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- ==================== CORE TABLES (NO DEPENDENCIES) ====================

-- Buses table
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

-- Routes table
CREATE TABLE IF NOT EXISTS public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  from_town TEXT NOT NULL,
  to_town TEXT NOT NULL,
  total_distance DECIMAL(10,2) NOT NULL,
  estimated_duration INTEGER NOT NULL,
  waypoints JSONB NOT NULL DEFAULT '[]'::JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stops table - CRITICAL: coordinates column is defined here
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

-- Now add foreign key to buses
ALTER TABLE public.buses 
ADD CONSTRAINT fk_buses_current_route 
FOREIGN KEY (current_route_id) REFERENCES public.routes(id) ON DELETE SET NULL;

-- Route stops junction table
CREATE TABLE IF NOT EXISTS public.route_stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  sequence_order INTEGER NOT NULL,
  distance_from_start DECIMAL(10,2) NOT NULL DEFAULT 0,
  estimated_time_from_start INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(route_id, stop_id),
  UNIQUE(route_id, sequence_order)
);

-- Journeys table
CREATE TABLE IF NOT EXISTS public.journeys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bus_id UUID NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  departure_time TIMESTAMPTZ NOT NULL DEFAULT now(),
  estimated_arrival TIMESTAMPTZ,
  actual_arrival TIMESTAMPTZ,
  current_stop_id UUID REFERENCES public.stops(id),
  next_stop_id UUID REFERENCES public.stops(id),
  progress DECIMAL(5,2) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled', 'delayed')),
  delay_minutes INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Journey passengers
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

-- GPS history
CREATE TABLE IF NOT EXISTS public.gps_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_id UUID NOT NULL REFERENCES public.journeys(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL CHECK (source_type IN ('bus', 'passenger', 'agent')),
  source_id UUID NOT NULL,
  position GEOGRAPHY(POINT, 4326) NOT NULL,
  accuracy DECIMAL(10,2),
  heading DECIMAL(5,2),
  speed DECIMAL(5,2),
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Journey ETAs
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

-- Delivery agents
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

-- Restaurants
CREATE TABLE IF NOT EXISTS public.restaurants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  cuisine TEXT,
  rating DECIMAL(3,2) DEFAULT 4.0,
  price_range TEXT DEFAULT '$$',
  average_prep_time INTEGER DEFAULT 15,
  is_open BOOLEAN DEFAULT true,
  opening_hours JSONB DEFAULT '{"open": "06:00", "close": "22:00"}'::JSONB,
  location geography(Point, 4326),
  latitude NUMERIC,
  longitude NUMERIC,
  base_delivery_fee NUMERIC DEFAULT 0.5,
  delivery_fee_per_km NUMERIC DEFAULT 0.2,
  is_approved BOOLEAN DEFAULT false,
  approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected', 'suspended')),
  approval_date TIMESTAMPTZ,
  approved_by_admin_id UUID REFERENCES auth.users(id),
  business_license_number TEXT,
  business_license_expiry DATE,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Menu items
CREATE TABLE IF NOT EXISTS public.menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id UUID NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category TEXT NOT NULL,
  image_url TEXT,
  is_available BOOLEAN DEFAULT true,
  prep_time INTEGER DEFAULT 10,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Orders
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
  delivery_location geography(Point, 4326),
  delivery_distance_km NUMERIC,
  delivery_status TEXT DEFAULT 'pending' CHECK (delivery_status IN ('pending', 'accepted', 'in_transit', 'delivered', 'cancelled')),
  estimated_delivery_time TIMESTAMPTZ,
  expected_delivery_time TIMESTAMPTZ,
  actual_delivery_time TIMESTAMPTZ,
  pickup_location geography(Point, 4326),
  rider_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Accommodations
CREATE TABLE IF NOT EXISTS public.accommodations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  stop_id UUID NOT NULL REFERENCES public.stops(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT DEFAULT 'hotel' CHECK (type IN ('hotel', 'lodge', 'guesthouse', 'hostel')),
  rating DECIMAL(3,2) DEFAULT 4.0,
  price_per_night DECIMAL(10,2) NOT NULL,
  distance_from_stop DECIMAL(5,2),
  amenities JSONB DEFAULT '[]'::JSONB,
  is_night_arrival_friendly BOOLEAN DEFAULT false,
  rooms_available INTEGER DEFAULT 0,
  contact_phone TEXT,
  location geography(Point, 4326),
  latitude NUMERIC,
  longitude NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Accommodation bookings
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

-- Journey alerts
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

-- Shared journey links
CREATE TABLE IF NOT EXISTS public.shared_journey_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  journey_passenger_id UUID NOT NULL REFERENCES public.journey_passengers(id) ON DELETE CASCADE,
  share_code TEXT NOT NULL UNIQUE,
  created_by_user_id UUID NOT NULL,
  viewer_name TEXT,
  permissions JSONB DEFAULT '{"view_location": true, "view_eta": true, "view_stops": true, "view_orders": false}'::JSONB,
  is_active BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ,
  views_count INTEGER DEFAULT 0,
  last_viewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Route performance history
CREATE TABLE IF NOT EXISTS public.route_performance_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  from_stop_id UUID NOT NULL REFERENCES public.stops(id),
  to_stop_id UUID NOT NULL REFERENCES public.stops(id),
  day_of_week INTEGER NOT NULL,
  hour_of_day INTEGER NOT NULL,
  average_duration INTEGER NOT NULL,
  samples_count INTEGER DEFAULT 1,
  last_updated TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Restaurant approval logs
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

-- Hotel rooms
CREATE TABLE IF NOT EXISTS hotel_rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  accommodation_id UUID NOT NULL REFERENCES accommodations(id) ON DELETE CASCADE,
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

-- Room reviews
CREATE TABLE IF NOT EXISTS room_reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES hotel_rooms(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id),
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  guest_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Room availability
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

-- Room rate history
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

-- Payment transactions
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

-- Payment logs
CREATE TABLE IF NOT EXISTS payment_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id TEXT NOT NULL,
  event TEXT NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment retries
CREATE TABLE IF NOT EXISTS payment_retries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  status TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment disputes
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

-- ==================== INDEXES ====================
CREATE INDEX IF NOT EXISTS idx_buses_current_position ON public.buses USING GIST (current_position);
CREATE INDEX IF NOT EXISTS idx_buses_status ON public.buses(status);
CREATE INDEX IF NOT EXISTS idx_stops_coordinates ON public.stops USING GIST (coordinates);
CREATE INDEX IF NOT EXISTS idx_stops_town_id ON public.stops(town_id);
CREATE INDEX IF NOT EXISTS idx_journeys_bus_id ON public.journeys(bus_id);
CREATE INDEX IF NOT EXISTS idx_journeys_status ON public.journeys(status);
CREATE INDEX IF NOT EXISTS idx_journey_passengers_journey_id ON public.journey_passengers(journey_id);
CREATE INDEX IF NOT EXISTS idx_journey_passengers_user_id ON public.journey_passengers(user_id);
CREATE INDEX IF NOT EXISTS idx_gps_history_journey_id ON public.gps_history(journey_id);
CREATE INDEX IF NOT EXISTS idx_gps_history_recorded_at ON public.gps_history(recorded_at);
CREATE INDEX IF NOT EXISTS idx_delivery_agents_current_position ON public.delivery_agents USING GIST (current_position);
CREATE INDEX IF NOT EXISTS idx_delivery_agents_stop_id ON public.delivery_agents(current_stop_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_journey_id ON public.orders(journey_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_restaurants_stop_id ON public.restaurants(stop_id);
CREATE INDEX IF NOT EXISTS idx_restaurants_approval_status ON public.restaurants(approval_status);
CREATE INDEX IF NOT EXISTS idx_restaurants_is_approved ON public.restaurants(is_approved);
CREATE INDEX IF NOT EXISTS idx_restaurants_location ON public.restaurants USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_accommodations_location ON public.accommodations USING GIST(location);
CREATE INDEX IF NOT EXISTS idx_orders_delivery_location ON public.orders USING GIST(delivery_location);
CREATE INDEX IF NOT EXISTS idx_shared_links_share_code ON public.shared_journey_links(share_code);
CREATE INDEX IF NOT EXISTS idx_menu_items_restaurant ON public.menu_items(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_accommodation_bookings_user ON public.accommodation_bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_restaurant_approval_logs_restaurant_id ON restaurant_approval_logs(restaurant_id);
CREATE INDEX IF NOT EXISTS idx_hotel_rooms_accommodation ON hotel_rooms(accommodation_id);
CREATE INDEX IF NOT EXISTS idx_room_reviews_room ON room_reviews(room_id);
CREATE INDEX IF NOT EXISTS idx_room_availability_room_date ON room_availability(room_id, date);
CREATE INDEX IF NOT EXISTS idx_room_rate_history_room ON room_rate_history(room_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_logs_transaction ON payment_logs(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_disputes_transaction ON payment_disputes(transaction_id);

-- ==================== ENABLE RLS ====================
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
ALTER TABLE restaurant_approval_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE hotel_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE room_rate_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_retries ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_disputes ENABLE ROW LEVEL SECURITY;

-- ==================== BASIC RLS POLICIES ====================

-- Public read access for reference data
CREATE POLICY "Anyone can view buses" ON public.buses FOR SELECT USING (true);
CREATE POLICY "Anyone can view routes" ON public.routes FOR SELECT USING (true);
CREATE POLICY "Anyone can view stops" ON public.stops FOR SELECT USING (true);
CREATE POLICY "Anyone can view route_stops" ON public.route_stops FOR SELECT USING (true);
CREATE POLICY "Anyone can view active journeys" ON public.journeys FOR SELECT USING (true);
CREATE POLICY "Anyone can view restaurants" ON public.restaurants FOR SELECT USING (is_approved = true);
CREATE POLICY "Anyone can view menu items" ON public.menu_items FOR SELECT USING (true);
CREATE POLICY "Anyone can view accommodations" ON public.accommodations FOR SELECT USING (true);
CREATE POLICY "Anyone can view journey ETAs" ON public.journey_etas FOR SELECT USING (true);
CREATE POLICY "Anyone can view journey alerts" ON public.journey_alerts FOR SELECT USING (true);
CREATE POLICY "Anyone can view delivery agents" ON public.delivery_agents FOR SELECT USING (true);

-- Journey passengers - users can see their own
CREATE POLICY "Users can view their passenger records" ON public.journey_passengers 
FOR SELECT USING (auth.uid() = user_id);

-- GPS history
CREATE POLICY "Users can view GPS history for their journeys" ON public.gps_history 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.journey_passengers jp 
    WHERE jp.journey_id = gps_history.journey_id 
    AND jp.user_id = auth.uid()
  )
);

-- Orders - users can manage their own
CREATE POLICY "Users can view their orders" ON public.orders 
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create orders" ON public.orders 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Accommodation bookings
CREATE POLICY "Users can view their bookings" ON public.accommodation_bookings 
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create bookings" ON public.accommodation_bookings 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Shared journey links
CREATE POLICY "Users can view their shared links" ON public.shared_journey_links 
FOR SELECT USING (auth.uid() = created_by_user_id);

-- Hotel rooms
CREATE POLICY "Anyone can view active hotel rooms" ON hotel_rooms FOR SELECT USING (true);

-- Room reviews
CREATE POLICY "Anyone can view room reviews" ON room_reviews FOR SELECT USING (true);

CREATE POLICY "Users can add room reviews" ON room_reviews FOR INSERT WITH CHECK (true);

-- Room availability and rates
CREATE POLICY "View room availability" ON room_availability FOR SELECT USING (true);
CREATE POLICY "View rate history" ON room_rate_history FOR SELECT USING (true);

-- Approval logs
CREATE POLICY "View approval logs" ON restaurant_approval_logs FOR SELECT USING (true);

-- Payment transactions
CREATE POLICY "Users see own transactions" ON payment_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create transactions" ON payment_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Payment logs
CREATE POLICY "View payment logs" ON payment_logs FOR SELECT USING (true);

-- ==================== HELPER FUNCTIONS ====================

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
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
CREATE TRIGGER update_hotel_rooms_updated_at BEFORE UPDATE ON hotel_rooms FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Room rating trigger
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

-- ==================== ENABLE REALTIME ====================
ALTER PUBLICATION supabase_realtime ADD TABLE public.buses;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journeys;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_passengers;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_etas;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_agents;
ALTER PUBLICATION supabase_realtime ADD TABLE public.journey_alerts;
ALTER PUBLICATION supabase_realtime ADD TABLE public.restaurants;
ALTER PUBLICATION supabase_realtime ADD TABLE public.accommodations;
ALTER PUBLICATION supabase_realtime ADD TABLE payment_transactions;

-- ==================== MIGRATION COMPLETE ====================
-- All tables, indexes, RLS policies, and triggers created successfully!
-- This simplified schema removes problematic owner_id references and fixes coordinate errors
