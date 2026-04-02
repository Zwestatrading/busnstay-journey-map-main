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
