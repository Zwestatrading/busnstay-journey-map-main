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