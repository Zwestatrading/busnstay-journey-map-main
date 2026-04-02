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



