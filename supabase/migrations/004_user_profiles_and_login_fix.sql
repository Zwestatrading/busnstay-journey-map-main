-- ============================================================================
-- 004: Create user_profiles table + handle_new_user trigger (login fix)
-- SAFE TO RE-RUN: all statements are idempotent
-- Run this in Supabase SQL Editor if login fails with
--   "could not find public.user_profiles in schema"
-- ============================================================================

-- 1. Create user_profiles if it doesn't already exist
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL UNIQUE,
    email          TEXT,
    full_name      TEXT,
    phone          TEXT,
    avatar_url     TEXT,
    role           TEXT NOT NULL DEFAULT 'passenger',
    is_approved    BOOLEAN DEFAULT false,
    business_name  TEXT,
    business_license TEXT,
    business_address TEXT,
    rating         NUMERIC DEFAULT 5.0,
    total_trips    INTEGER DEFAULT 0,
    is_online      BOOLEAN DEFAULT false,
    metadata       JSONB DEFAULT '{}',
    created_at     TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at     TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- 2. Add any missing columns (idempotent via DO blocks)
DO $$ BEGIN
    ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
EXCEPTION WHEN others THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS is_online BOOLEAN DEFAULT false;
EXCEPTION WHEN others THEN null; END $$;

-- 3. Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Service role can do everything (needed for handle_new_user trigger)
DROP POLICY IF EXISTS "Service role full access" ON public.user_profiles;
CREATE POLICY "Service role full access"
    ON public.user_profiles
    USING (true)
    WITH CHECK (true);

-- 4. Create/replace handle_new_user function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user profile
    INSERT INTO public.user_profiles (user_id, email, full_name, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'role', 'passenger')
    )
    ON CONFLICT (user_id) DO UPDATE SET
        email       = EXCLUDED.email,
        updated_at  = now();

    -- Create loyalty profile
    INSERT INTO public.user_loyalty (user_id, referral_code)
    VALUES (
        NEW.id,
        'BNS-' || UPPER(SUBSTRING(MD5(NEW.id::text || now()::text) FROM 1 FOR 8))
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- Create wallet
    INSERT INTO public.wallets (user_id, currency)
    VALUES (NEW.id, 'ZMW')
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5. Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Indexes
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role    ON public.user_profiles(role);

-- 7. Backfill: create profiles for all existing auth users who don't have one
INSERT INTO public.user_profiles (user_id, email, full_name, role)
SELECT
    u.id,
    u.email,
    COALESCE(u.raw_user_meta_data->>'full_name', split_part(u.email, '@', 1)),
    COALESCE(u.raw_user_meta_data->>'role', 'passenger')
FROM auth.users u
WHERE NOT EXISTS (
    SELECT 1 FROM public.user_profiles p WHERE p.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

-- 8. Enable realtime (wrapped to avoid error if already added)
DO $$
BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
EXCEPTION WHEN others THEN null;
END $$;
