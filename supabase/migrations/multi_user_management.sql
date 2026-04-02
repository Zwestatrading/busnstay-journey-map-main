-- ============================================================================
-- BusNStay Multi-User Management System - Database Migration
-- Run this in Supabase SQL Editor to set up complete user management
-- ============================================================================

-- Step 1: Create ENUM types
CREATE TYPE user_account_status AS ENUM ('active', 'suspended', 'deleted', 'pending_verification');
CREATE TYPE user_role_type AS ENUM (
  'passenger',
  'bus_operator',
  'delivery_agent',
  'restaurant_staff',
  'restaurant_admin',
  'hotel_staff',
  'hotel_manager',
  'platform_admin',
  'support_staff'
);
CREATE TYPE verification_status AS ENUM ('pending', 'verified', 'rejected', 'suspended');
CREATE TYPE kyc_document_type AS ENUM ('national_id', 'passport', 'driver_license', 'business_license');
CREATE TYPE loyalty_tier AS ENUM ('bronze', 'silver', 'gold', 'platinum');
CREATE TYPE audit_action AS ENUM ('create', 'update', 'delete', 'login', 'logout', 'verify', 'suspend', 'activate');

-- ============================================================================
-- Step 2: Core Users Table
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  phone_number VARCHAR(20),
  full_name VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  profile_image_url TEXT,
  date_of_birth DATE,
  
  -- Account Status
  account_status user_account_status DEFAULT 'pending_verification',
  is_email_verified BOOLEAN DEFAULT FALSE,
  is_phone_verified BOOLEAN DEFAULT FALSE,
  email_verified_at TIMESTAMPTZ,
  phone_verified_at TIMESTAMPTZ,
  last_login TIMESTAMPTZ,
  
  -- 2FA/Security
  two_factor_enabled BOOLEAN DEFAULT FALSE,
  two_factor_method VARCHAR(50) DEFAULT 'email',
  two_factor_secret VARCHAR(255),
  backup_codes TEXT[],
  
  -- Account Settings
  notification_preferences JSONB DEFAULT '{"email": true, "sms": false, "push": true}',
  language_preference VARCHAR(5) DEFAULT 'en',
  timezone VARCHAR(50) DEFAULT 'UTC',
  currency VARCHAR(3) DEFAULT 'ZMW',
  
  -- Preferences
  marketing_consent BOOLEAN DEFAULT FALSE,
  terms_accepted BOOLEAN DEFAULT FALSE,
  privacy_accepted BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ,
  
  CONSTRAINT email_valid CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}$')
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone_number);
CREATE INDEX idx_users_created_at ON users(created_at DESC);
CREATE INDEX idx_users_account_status ON users(account_status);

-- Auto-update trigger for updated_at
CREATE OR REPLACE FUNCTION update_users_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER users_updated_at_trigger
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_users_timestamp();

-- ============================================================================
-- Step 3: User Roles & Permissions
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role user_role_type NOT NULL,
  
  -- Role-specific metadata
  metadata JSONB,
  
  -- Role activation/deactivation
  is_active BOOLEAN DEFAULT TRUE,
  activated_at TIMESTAMPTZ DEFAULT now(),
  deactivated_at TIMESTAMPTZ,
  
  -- For operators/admins
  verification_status verification_status DEFAULT 'pending',
  verified_by UUID REFERENCES users(id),
  verified_at TIMESTAMPTZ,
  verification_documents JSONB,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, role)
);

CREATE INDEX idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX idx_user_roles_role ON user_roles(role);
CREATE INDEX idx_user_roles_is_active ON user_roles(is_active);

-- Permissions table
CREATE TABLE IF NOT EXISTS role_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  role VARCHAR(50) NOT NULL,
  permission VARCHAR(100) NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(role, permission)
);

-- Insert default permissions
INSERT INTO role_permissions (role, permission, description) VALUES
-- Passenger permissions
('passenger', 'view_routes', 'View available routes'),
('passenger', 'book_seat', 'Book a seat on a bus'),
('passenger', 'cancel_booking', 'Cancel their own bookings'),
('passenger', 'rate_trip', 'Rate completed trips'),
('passenger', 'order_food', 'Order from restaurants'),
('passenger', 'book_hotel', 'Book hotel accommodations'),
('passenger', 'make_payments', 'Make payments'),
('passenger', 'view_loyalty', 'View loyalty points'),
('passenger', 'use_wallet', 'Use wallet for payments'),

-- Bus Operator permissions
('bus_operator', 'manage_buses', 'Add/edit/delete buses'),
('bus_operator', 'manage_routes', 'Create and manage routes'),
('bus_operator', 'view_bookings', 'View passenger bookings'),
('bus_operator', 'view_revenue', 'View revenue reports'),
('bus_operator', 'manage_seats', 'Manage seat availability'),
('bus_operator', 'issue_refund', 'Issue refunds to passengers'),

-- Delivery Agent permissions
('delivery_agent', 'view_deliveries', 'View assigned deliveries'),
('delivery_agent', 'update_delivery_status', 'Update delivery status'),
('delivery_agent', 'track_location', 'Use location tracking'),
('delivery_agent', 'confirm_delivery', 'Confirm deliveries'),

-- Restaurant Admin permissions
('restaurant_admin', 'manage_menu', 'Manage menu items'),
('restaurant_admin', 'view_orders', 'View all restaurant orders'),
('restaurant_admin', 'manage_staff', 'Manage restaurant staff'),
('restaurant_admin', 'view_revenue', 'View restaurant revenue'),
('restaurant_admin', 'update_restaurant_info', 'Update restaurant info'),

-- Hotel Manager permissions
('hotel_manager', 'manage_rooms', 'Manage hotel rooms'),
('hotel_manager', 'manage_bookings', 'Manage room bookings'),
('hotel_manager', 'manage_staff', 'Manage hotel staff'),
('hotel_manager', 'view_revenue', 'View hotel revenue'),
('hotel_manager', 'update_hotel_info', 'Update hotel information'),

-- Platform Admin permissions
('platform_admin', 'manage_users', 'Manage all users'),
('platform_admin', 'view_analytics', 'View platform analytics'),
('platform_admin', 'manage_disputes', 'Handle disputes'),
('platform_admin', 'system_configuration', 'Configure system settings'),
('platform_admin', 'moderate_content', 'Moderate user content') ON CONFLICT DO NOTHING;

-- ============================================================================
-- Step 4: Session Management
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  refresh_token VARCHAR(500) UNIQUE NOT NULL,
  
  -- Device info
  device_info JSONB,
  ip_address INET,
  user_agent TEXT,
  
  -- Security
  is_active BOOLEAN DEFAULT TRUE,
  is_revoked BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '7 days'),
  last_activity TIMESTAMPTZ DEFAULT now(),
  revoked_at TIMESTAMPTZ,
  
  CONSTRAINT token_format CHECK (char_length(token) > 50)
);

CREATE INDEX idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(token);
CREATE INDEX idx_sessions_is_active ON user_sessions(is_active);
CREATE INDEX idx_sessions_expires_at ON user_sessions(expires_at);

-- ============================================================================
-- Step 5: User Profiles
-- ============================================================================
CREATE TABLE IF NOT EXISTS passenger_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Preferences
  preferred_seats VARCHAR(50) DEFAULT 'any',
  accessibility_needs TEXT,
  emergency_contact_name VARCHAR(255),
  emergency_contact_phone VARCHAR(20),
  
  -- Travel preferences
  frequent_routes TEXT[],
  preferred_travel_times TIME[],
  
  -- Loyalty
  loyalty_points INTEGER DEFAULT 0,
  total_trips INTEGER DEFAULT 0,
  total_spent DECIMAL(10,2) DEFAULT 0,
  member_since TIMESTAMPTZ DEFAULT now(),
  loyalty_tier loyalty_tier DEFAULT 'bronze',
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_passenger_user_id ON passenger_profiles(user_id);
CREATE INDEX idx_passenger_loyalty_tier ON passenger_profiles(loyalty_tier);

-- Bus Operator profile
CREATE TABLE IF NOT EXISTS operator_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Company info
  company_name VARCHAR(255) NOT NULL,
  company_registration_number VARCHAR(100),
  company_logo_url TEXT,
  company_address TEXT,
  
  -- Contact
  support_email VARCHAR(255),
  support_phone VARCHAR(20),
  
  -- Bank details
  bank_account_holder VARCHAR(255),
  bank_name VARCHAR(100),
  bank_account_number VARCHAR(50),
  bank_code VARCHAR(10),
  swift_code VARCHAR(11),
  
  -- Verification
  is_verified BOOLEAN DEFAULT FALSE,
  verification_documents JSONB,
  
  -- Statistics
  total_routes INTEGER DEFAULT 0,
  total_passengers INTEGER DEFAULT 0,
  average_rating DECIMAL(3,2),
  total_revenue DECIMAL(12,2) DEFAULT 0,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_operator_user_id ON operator_profiles(user_id);
CREATE INDEX idx_operator_verification ON operator_profiles(is_verified);

-- Restaurant owner profile
CREATE TABLE IF NOT EXISTS restaurant_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  restaurant_id UUID REFERENCES restaurants(id),
  
  -- Permissions
  can_manage_menu BOOLEAN DEFAULT TRUE,
  can_manage_orders BOOLEAN DEFAULT TRUE,
  can_manage_staff BOOLEAN DEFAULT FALSE,
  can_view_financials BOOLEAN DEFAULT FALSE,
  
  -- Contact
  position_title VARCHAR(100),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_restaurant_profile_user_id ON restaurant_profiles(user_id);

-- Hotel manager profile
CREATE TABLE IF NOT EXISTS hotel_manager_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  accommodation_id UUID REFERENCES accommodations(id),
  
  -- Permissions
  can_manage_rooms BOOLEAN DEFAULT TRUE,
  can_manage_bookings BOOLEAN DEFAULT TRUE,
  can_manage_staff BOOLEAN DEFAULT FALSE,
  can_view_financials BOOLEAN DEFAULT FALSE,
  
  -- Contact
  position_title VARCHAR(100),
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_hotel_manager_profile_user_id ON hotel_manager_profiles(user_id);

-- ============================================================================
-- Step 6: Account Verification
-- ============================================================================
CREATE TABLE IF NOT EXISTS email_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email VARCHAR(255) NOT NULL,
  verification_code VARCHAR(6) NOT NULL,
  
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours'),
  
  CONSTRAINT valid_code CHECK (char_length(verification_code) = 6)
);

CREATE INDEX idx_email_verif_user_id ON email_verifications(user_id);
CREATE INDEX idx_email_verif_code ON email_verifications(verification_code);

-- Phone verification
CREATE TABLE IF NOT EXISTS phone_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phone_number VARCHAR(20) NOT NULL,
  verification_code VARCHAR(6) NOT NULL,
  
  is_verified BOOLEAN DEFAULT FALSE,
  verified_at TIMESTAMPTZ,
  
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 5,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '10 minutes'),
  
  CONSTRAINT valid_code CHECK (char_length(verification_code) = 6)
);

CREATE INDEX idx_phone_verif_user_id ON phone_verifications(user_id);

-- KYC documents
CREATE TABLE IF NOT EXISTS kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  document_type kyc_document_type NOT NULL,
  document_number VARCHAR(100) NOT NULL,
  document_url TEXT NOT NULL,
  
  -- Verification
  verification_status verification_status DEFAULT 'pending',
  verified_by UUID REFERENCES users(id),
  verified_at TIMESTAMPTZ,
  verification_notes TEXT,
  
  -- Expiry
  issued_date DATE,
  expiry_date DATE,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  UNIQUE(user_id, document_type)
);

CREATE INDEX idx_kyc_user_id ON kyc_documents(user_id);
CREATE INDEX idx_kyc_status ON kyc_documents(verification_status);

-- ============================================================================
-- Step 7: Audit Logging
-- ============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  
  action audit_action NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id UUID,
  
  old_values JSONB,
  new_values JSONB,
  changes JSONB,
  
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_user_id ON audit_logs(user_id);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created_at ON audit_logs(created_at DESC);

-- ============================================================================
-- Step 8: Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE passenger_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE operator_profiles ENABLE ROW LEVEL SECURITY;

-- Users can view their own profile
CREATE POLICY "users_view_own" ON users
  FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Users can view their own roles
CREATE POLICY "users_view_own_roles" ON user_roles
  FOR SELECT USING (auth.uid() = user_id);

-- Users can view their own sessions
CREATE POLICY "users_view_own_sessions" ON user_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- Email verifications - users can view their own
CREATE POLICY "users_view_own_verification" ON email_verifications
  FOR SELECT USING (auth.uid() = user_id);

-- Passenger profiles - users can view/update their own
CREATE POLICY "users_view_own_passenger_profile" ON passenger_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_update_own_passenger_profile" ON passenger_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- Operator profiles - users can view/update their own
CREATE POLICY "users_view_own_operator_profile" ON operator_profiles
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_update_own_operator_profile" ON operator_profiles
  FOR UPDATE USING (auth.uid() = user_id);

-- ============================================================================
-- Step 9: Realtime Subscriptions
-- ============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE users;
ALTER PUBLICATION supabase_realtime ADD TABLE user_roles;
ALTER PUBLICATION supabase_realtime ADD TABLE user_sessions;

-- ============================================================================
-- Step 10: Helper Functions
-- ============================================================================

-- Function to get user with roles and permissions
CREATE OR REPLACE FUNCTION get_user_with_roles(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_user_data JSONB;
  v_roles JSONB;
  v_permissions JSONB;
BEGIN
  -- Get user data
  SELECT jsonb_build_object(
    'id', id,
    'email', email,
    'full_name', full_name,
    'account_status', account_status,
    'is_email_verified', is_email_verified,
    'is_phone_verified', is_phone_verified
  ) INTO v_user_data FROM users WHERE id = p_user_id;

  -- Get roles
  SELECT jsonb_agg(jsonb_build_object('role', role, 'is_active', is_active))
  INTO v_roles FROM user_roles WHERE user_id = p_user_id;

  -- Get permissions
  SELECT jsonb_agg(DISTINCT permission)
  INTO v_permissions FROM role_permissions
  WHERE role IN (SELECT role FROM user_roles WHERE user_id = p_user_id AND is_active);

  RETURN jsonb_build_object(
    'user', v_user_data,
    'roles', COALESCE(v_roles, '[]'::jsonb),
    'permissions', COALESCE(v_permissions, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add role to user
CREATE OR REPLACE FUNCTION add_user_role(p_user_id UUID, p_role user_role_type)
RETURNS UUID AS $$
DECLARE
  v_role_id UUID;
BEGIN
  INSERT INTO user_roles (user_id, role, is_active)
  VALUES (p_user_id, p_role, TRUE)
  ON CONFLICT (user_id, role) DO UPDATE SET
    is_active = TRUE,
    activated_at = now()
  RETURNING id INTO v_role_id;

  RETURN v_role_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check permission
CREATE OR REPLACE FUNCTION has_permission(p_user_id UUID, p_permission VARCHAR)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM role_permissions rp
    INNER JOIN user_roles ur ON ur.role = rp.role
    WHERE ur.user_id = p_user_id
      AND ur.is_active = TRUE
      AND rp.permission = p_permission
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Step 11: Summary
-- ============================================================================
-- All tables have been created successfully!
-- Next steps:
-- 1. Set up email service (Resend, SendGrid, etc.)
-- 2. Implement frontend auth service
-- 3. Create auth pages (Login, Register, Verify)
-- 4. Deploy to Vercel
-- 5. Test all flows
