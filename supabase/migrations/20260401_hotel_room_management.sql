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
