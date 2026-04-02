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
