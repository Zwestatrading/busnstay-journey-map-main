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