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
