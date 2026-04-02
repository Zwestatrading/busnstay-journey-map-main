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
