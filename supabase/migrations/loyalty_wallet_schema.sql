-- BusNStay Loyalty & Wallet System Database Schema
-- This SQL script creates all necessary tables for the Loyalty Program and Digital Wallet features
-- Run this in your Supabase SQL Editor after connecting to your project

-- ============================================================================
-- SECTION 1: LOYALTY PROGRAM TABLES
-- ============================================================================

-- User Loyalty Profiles
CREATE TABLE IF NOT EXISTS public.user_loyalty (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  current_points INT DEFAULT 0 CHECK (current_points >= 0),
  total_points_earned INT DEFAULT 0 CHECK (total_points_earned >= 0),
  total_points_redeemed INT DEFAULT 0 CHECK (total_points_redeemed >= 0),
  tier VARCHAR DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  referral_code VARCHAR UNIQUE NOT NULL,
  referral_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  last_activity TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_user_loyalty_user_id ON public.user_loyalty(user_id);
CREATE INDEX idx_user_loyalty_tier ON public.user_loyalty(tier);
CREATE INDEX idx_user_loyalty_referral_code ON public.user_loyalty(referral_code);

-- Loyalty Transactions (earning, redemption, referral bonus)
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('earning', 'redemption', 'referral', 'bonus', 'expiration')),
  points INT NOT NULL CHECK (points != 0),
  description TEXT NOT NULL,
  related_booking_id UUID,
  related_referral_code VARCHAR,
  expires_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_loyalty_transactions_user_id ON public.loyalty_transactions(user_id);
CREATE INDEX idx_loyalty_transactions_type ON public.loyalty_transactions(type);
CREATE INDEX idx_loyalty_transactions_created_at ON public.loyalty_transactions(created_at);

-- Available Rewards Catalog
CREATE TABLE IF NOT EXISTS public.loyalty_rewards (
  id VARCHAR PRIMARY KEY,
  name VARCHAR NOT NULL,
  description TEXT,
  category VARCHAR NOT NULL CHECK (category IN ('discount', 'upgrade', 'gift', 'exclusive', 'experience')),
  points_required INT NOT NULL CHECK (points_required > 0),
  max_redemptions INT DEFAULT NULL, -- NULL = unlimited
  current_redemptions INT DEFAULT 0,
  popularity_score INT DEFAULT 0 CHECK (popularity_score >= 0 AND popularity_score <= 100),
  image_url VARCHAR,
  badge_icon VARCHAR,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_loyalty_rewards_category ON public.loyalty_rewards(category);
CREATE INDEX idx_loyalty_rewards_active ON public.loyalty_rewards(active);

-- Reward Redemptions
CREATE TABLE IF NOT EXISTS public.reward_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reward_id VARCHAR NOT NULL REFERENCES public.loyalty_rewards(id) ON DELETE RESTRICT,
  points_spent INT NOT NULL,
  status VARCHAR DEFAULT 'redeemed' CHECK (status IN ('redeemed', 'used', 'expired', 'cancelled')),
  expires_at TIMESTAMP,
  used_at TIMESTAMP,
  redemption_code VARCHAR UNIQUE,
  redeemed_at TIMESTAMP DEFAULT now(),
  created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_reward_redemptions_user_id ON public.reward_redemptions(user_id);
CREATE INDEX idx_reward_redemptions_status ON public.reward_redemptions(status);
CREATE INDEX idx_reward_redemptions_reward_id ON public.reward_redemptions(reward_id);

-- Referral Records
CREATE TABLE IF NOT EXISTS public.referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referee_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referral_code VARCHAR NOT NULL,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'expired')),
  bonus_points_awarded INT DEFAULT 500,
  points_awarded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT now(),
  expires_at TIMESTAMP DEFAULT (now() + INTERVAL '90 days'),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_referrals_referrer_user_id ON public.referrals(referrer_user_id);
CREATE INDEX idx_referrals_referee_user_id ON public.referrals(referee_user_id);
CREATE INDEX idx_referrals_referral_code ON public.referrals(referral_code);
CREATE INDEX idx_referrals_status ON public.referrals(status);

-- ============================================================================
-- SECTION 2: DIGITAL WALLET TABLES
-- ============================================================================

-- User Wallets
CREATE TABLE IF NOT EXISTS public.wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance DECIMAL(12, 2) DEFAULT 0 CHECK (balance >= 0),
  currency VARCHAR DEFAULT 'USD',
  wallet_status VARCHAR DEFAULT 'active' CHECK (wallet_status IN ('active', 'suspended', 'closed')),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now(),
  last_activity TIMESTAMP DEFAULT now(),
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX idx_wallets_status ON public.wallets(wallet_status);

-- Wallet Transactions
CREATE TABLE IF NOT EXISTS public.wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('debit', 'credit', 'refund', 'transfer', 'withdrawal', 'deposit')),
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  description TEXT NOT NULL,
  status VARCHAR DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  related_booking_id UUID,
  related_order_id VARCHAR,
  payment_method_id UUID REFERENCES public.payment_methods(id) ON DELETE SET NULL,
  transaction_reference VARCHAR UNIQUE,
  failure_reason VARCHAR,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  metadata JSONB DEFAULT '{}'
);

CREATE INDEX idx_wallet_transactions_wallet_id ON public.wallet_transactions(wallet_id);
CREATE INDEX idx_wallet_transactions_type ON public.wallet_transactions(type);
CREATE INDEX idx_wallet_transactions_status ON public.wallet_transactions(status);
CREATE INDEX idx_wallet_transactions_created_at ON public.wallet_transactions(created_at);

-- Payment Methods (stored securely)
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type VARCHAR NOT NULL CHECK (type IN ('card', 'mobile', 'bank', 'wallet')),
  name VARCHAR NOT NULL,
  provider VARCHAR, -- e.g., 'stripe', 'paypal', 'mtn', 'airtel'
  payment_token VARCHAR NOT NULL, -- Should be encrypted in the application layer
  last_digits VARCHAR(4), -- e.g., "4242"
  expiry_date VARCHAR, -- For cards: MM/YY
  is_default BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);

CREATE INDEX idx_payment_methods_user_id ON public.payment_methods(user_id);
CREATE INDEX idx_payment_methods_type ON public.payment_methods(type);
CREATE INDEX idx_payment_methods_is_default ON public.payment_methods(is_default) WHERE is_default = true;

-- Wallet Deposits/Top-ups
CREATE TABLE IF NOT EXISTS public.wallet_deposits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  currency VARCHAR DEFAULT 'USD',
  payment_method_id UUID NOT NULL REFERENCES public.payment_methods(id) ON DELETE RESTRICT,
  status VARCHAR DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  transaction_reference VARCHAR UNIQUE,
  processor_response JSONB,
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  failed_at TIMESTAMP,
  failure_reason VARCHAR
);

CREATE INDEX idx_wallet_deposits_wallet_id ON public.wallet_deposits(wallet_id);
CREATE INDEX idx_wallet_deposits_status ON public.wallet_deposits(status);
CREATE INDEX idx_wallet_deposits_created_at ON public.wallet_deposits(created_at);

-- Wallet Transfers (peer-to-peer)
CREATE TABLE IF NOT EXISTS public.wallet_transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  to_wallet_id UUID NOT NULL REFERENCES public.wallets(id) ON DELETE CASCADE,
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  description VARCHAR,
  status VARCHAR DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  created_at TIMESTAMP DEFAULT now(),
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP
);

CREATE INDEX idx_wallet_transfers_from_wallet_id ON public.wallet_transfers(from_wallet_id);
CREATE INDEX idx_wallet_transfers_to_wallet_id ON public.wallet_transfers(to_wallet_id);
CREATE INDEX idx_wallet_transfers_created_at ON public.wallet_transfers(created_at);

-- ============================================================================
-- SECTION 3: ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.user_loyalty ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transfers ENABLE ROW LEVEL SECURITY;

-- User Loyalty RLS
CREATE POLICY "Users can view their own loyalty profile"
  ON public.user_loyalty FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own loyalty profile"
  ON public.user_loyalty FOR UPDATE USING (auth.uid() = user_id);

-- Loyalty Transactions RLS
CREATE POLICY "Users can view their own transactions"
  ON public.loyalty_transactions FOR SELECT USING (auth.uid() = user_id);

-- Rewards RLS
CREATE POLICY "Anyone can view active rewards"
  ON public.loyalty_rewards FOR SELECT USING (active = true);

-- Reward Redemptions RLS
CREATE POLICY "Users can view their own redemptions"
  ON public.reward_redemptions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create redemptions for themselves"
  ON public.reward_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Wallets RLS
CREATE POLICY "Users can view their own wallet"
  ON public.wallets FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet"
  ON public.wallets FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Transactions RLS
CREATE POLICY "Users can view their own transactions"
  ON public.wallet_transactions FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = wallet_id)
  );

-- Payment Methods RLS
CREATE POLICY "Users can view their own payment methods"
  ON public.payment_methods FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create payment methods"
  ON public.payment_methods FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment methods"
  ON public.payment_methods FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Deposits RLS
CREATE POLICY "Users can view their own deposits"
  ON public.wallet_deposits FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = wallet_id)
  );

-- Wallet Transfers RLS
CREATE POLICY "Users can view transfers involving their wallet"
  ON public.wallet_transfers FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = from_wallet_id) OR
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = to_wallet_id)
  );

-- ============================================================================
-- SECTION 4: SEED DATA (SAMPLE REWARDS)
-- ============================================================================

INSERT INTO public.loyalty_rewards (id, name, description, category, points_required, popularity_score, badge_icon, active) VALUES
  ('free-ride-50', 'Free Ride ($50)', 'Get a $50 credit towards your next bus trip', 'discount', 1000, 92, '🎫', true),
  ('hotel-upgrade', 'Hotel Room Upgrade', 'Complimentary room upgrade at partner hotels', 'exclusive', 800, 88, '🏨', true),
  ('meals-3', '3 Meal Vouchers', 'Three $10 meal vouchers for partner restaurants', 'gift', 600, 85, '🍽️', true),
  ('credit-20', '$20 Travel Credit', 'Universal credit for any travel service', 'discount', 400, 95, '💳', true),
  ('vip-badge', '30-Day VIP Badge', 'VIP status for priority support and benefits', 'exclusive', 2000, 78, '👑', true),
  ('airport-transfer', 'Free Airport Transfer', 'One complimentary airport transfer anywhere', 'experience', 1500, 82, '🚗', true);

-- ============================================================================
-- SECTION 5: HELPER FUNCTIONS
-- ============================================================================

-- Function to calculate tier based on points
CREATE OR REPLACE FUNCTION calculate_loyalty_tier(points INT)
RETURNS VARCHAR AS $$
BEGIN
  CASE
    WHEN points >= 10000 THEN RETURN 'platinum';
    WHEN points >= 5000 THEN RETURN 'gold';
    WHEN points >= 1000 THEN RETURN 'silver';
    ELSE RETURN 'bronze';
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to update user tier and last activity
CREATE OR REPLACE FUNCTION update_loyalty_tier()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.user_loyalty
  SET
    tier = calculate_loyalty_tier(NEW.current_points),
    updated_at = now(),
    last_activity = now()
  WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update tier when points change
CREATE TRIGGER tr_update_loyalty_tier
AFTER UPDATE OF current_points ON public.user_loyalty
FOR EACH ROW
WHEN (OLD.current_points IS DISTINCT FROM NEW.current_points)
EXECUTE FUNCTION update_loyalty_tier();

-- Function to update wallet balance
CREATE OR REPLACE FUNCTION update_wallet_balance()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' THEN
    UPDATE public.wallets
    SET
      balance = CASE
        WHEN NEW.type IN ('credit', 'refund', 'transfer', 'deposit') THEN balance + NEW.amount
        WHEN NEW.type IN ('debit', 'withdrawal') THEN balance - NEW.amount
        ELSE balance
      END,
      updated_at = now(),
      last_activity = now()
    WHERE id = NEW.wallet_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update wallet balance on transaction
CREATE TRIGGER tr_update_wallet_balance
AFTER INSERT OR UPDATE ON public.wallet_transactions
FOR EACH ROW
EXECUTE FUNCTION update_wallet_balance();

-- ============================================================================
-- SECTION 6: VIEWS FOR COMMON QUERIES
-- ============================================================================

-- User Loyalty Summary View
CREATE OR REPLACE VIEW public.user_loyalty_summary AS
SELECT
  ul.user_id,
  ul.current_points,
  ul.total_points_earned,
  ul.tier,
  ul.referral_count,
  COUNT(DISTINCT CASE WHEN lt.type = 'earning' THEN lt.id END) as earning_count,
  COUNT(DISTINCT CASE WHEN lt.type = 'redemption' THEN lt.id END) as redemption_count,
  MAX(lt.created_at) as last_transaction_date
FROM public.user_loyalty ul
LEFT JOIN public.loyalty_transactions lt ON ul.user_id = lt.user_id
GROUP BY ul.user_id, ul.current_points, ul.total_points_earned, ul.tier, ul.referral_count;

-- Wallet Summary View
CREATE OR REPLACE VIEW public.wallet_summary AS
SELECT
  w.user_id,
  w.balance,
  w.currency,
  COUNT(DISTINCT CASE WHEN wt.type = 'debit' THEN wt.id END) as debit_count,
  COUNT(DISTINCT CASE WHEN wt.type = 'credit' THEN wt.id END) as credit_count,
  COALESCE(SUM(CASE WHEN wt.type IN ('debit', 'withdrawal') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as total_spent,
  COALESCE(SUM(CASE WHEN wt.type IN ('credit', 'refund') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as total_credited,
  MAX(wt.created_at) as last_transaction_date
FROM public.wallets w
LEFT JOIN public.wallet_transactions wt ON w.id = wt.wallet_id
GROUP BY w.user_id, w.balance, w.currency;

-- Monthly Wallet Analytics View
CREATE OR REPLACE VIEW public.wallet_monthly_analytics AS
SELECT
  w.user_id,
  DATE_TRUNC('month', wt.created_at)::DATE as month,
  COALESCE(SUM(CASE WHEN wt.type IN ('debit', 'withdrawal') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as monthly_spent,
  COALESCE(SUM(CASE WHEN wt.type IN ('credit', 'refund') AND wt.status = 'completed' THEN wt.amount ELSE 0 END), 0) as monthly_credited,
  COUNT(DISTINCT wt.id) as transaction_count
FROM public.wallets w
LEFT JOIN public.wallet_transactions wt ON w.id = wt.wallet_id
GROUP BY w.user_id, DATE_TRUNC('month', wt.created_at);

-- ============================================================================
-- All tables and views are now ready for use!
-- ============================================================================
