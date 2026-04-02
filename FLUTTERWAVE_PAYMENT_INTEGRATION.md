# Flutterwave Payment Integration Guide

## 🎯 Overview
Complete payment integration for BusNStay using Flutterwave - the leading African payment platform supporting:
- ✅ Mobile Money (MTN, Airtel, Zamtel mobile money for Zambia)
- ✅ Credit/Debit Cards
- ✅ Bank Transfers
- ✅ USSD
- ✅ Digital Wallets

**Status**: Production-ready, ready for deployment  
**Estimated Setup Time**: 1 hour  
**Testing Time**: 30 minutes

---

## 📋 Setup Checklist

### Step 1: Create Flutterwave Account (5 min)
```bash
1. Go to https://dashboard.flutterwave.com/signup
2. Sign up with business email
3. Verify email
4. Complete KYC documentation
5. Activate account (usually 24-48 hours for ZM businesses)
```

### Step 2: Get API Keys (5 min)
```bash
# In Flutterwave Dashboard:
1. Go to Settings → API Keys
2. Copy Public Key (starts with FK_***)
3. Copy Secret Key (starts with SK_***)
4. Note: Keep Secret Key safe, never commit to git
5. Note: Use Live keys for production, Test keys for development
```

### Step 3: Add Environment Variables (5 min)
Create `.env.local` in your project root (never commit to git):
```bash
# Flutterwave Configuration
VITE_FLUTTERWAVE_PUBLIC_KEY=FK_TEST_xxxxxxxxxxxxx
VITE_FLUTTERWAVE_SECRET_KEY=SK_TEST_xxxxxxxxxxxxx
VITE_FLUTTERWAVE_API_BASE_URL=https://api.flutterwave.com/v3

# For Production (After approval):
# VITE_FLUTTERWAVE_PUBLIC_KEY=FK_LIVE_xxxxxxxxxxxxx
# VITE_FLUTTERWAVE_SECRET_KEY=SK_LIVE_xxxxxxxxxxxxx
```

**For Supabase Environment Variables** (if using serverless functions):
```bash
# In Supabase Dashboard → Project Settings → Environment Variables
FLUTTERWAVE_SECRET_KEY=SK_TEST_xxxxxxxxxxxxx
FLUTTERWAVE_API_URL=https://api.flutterwave.com/v3
```

### Step 4: Deploy Database Migration (10 min)
```bash
# Apply payment schema to Supabase
# File: supabase/migrations/20260401_flutterwave_payment_system.sql

# Manual steps:
1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Paste entire contents of 20260401_flutterwave_payment_system.sql
4. Execute

# Verify these tables created:
- payment_transactions (main payments table)
- payment_logs (audit trail)
- payment_retries (retry attempts)
- payment_disputes (disputed transactions)

# Verify views created:
- payment_analytics (revenue reporting)
- payment_success_rate (metrics)
```

### Step 5: Copy Service Files (5 min)
```bash
# Files to add to project:
src/services/paymentService.ts           # Payment service (700+ lines)
src/components/PaymentModal.tsx          # Payment UI component (400+ lines)
```

### Step 6: Integrate into Booking Flow (10 min)
Update `src/pages/CheckoutPage.tsx` or booking confirmation:
```typescript
import PaymentModal from '@/components/PaymentModal';

export function CheckoutPage() {
  const [showPayment, setShowPayment] = useState(false);
  const [bookingData, setBookingData] = useState(null);

  const handleProceedToPayment = (booking) => {
    setBookingData(booking);
    setShowPayment(true);
  };

  const handlePaymentSuccess = (transactionId) => {
    // Booking is auto-confirmed in paymentService.verifyPayment()
    navigate('/booking-confirmation', { state: { transactionId } });
  };

  return (
    <>
      {/* Booking details form */}
      <Button onClick={() => handleProceedToPayment(bookingData)}>
        Proceed to Payment
      </Button>

      <PaymentModal
        isOpen={showPayment}
        onClose={() => setShowPayment(false)}
        onSuccess={handlePaymentSuccess}
        amount={bookingData?.total_price || 0}
        description={`Hotel booking ${bookingData?.accommodation_name}`}
        bookingId={bookingData?.id}
        userEmail={userProfile?.email || ''}
        userName={userProfile?.full_name || ''}
        userPhone={userProfile?.phone || ''}
      />
    </>
  );
}
```

### Step 7: Build & Test (10 min)
```bash
# Build TypeScript
npm run build

# Start dev server
npm run dev

# Test workflow:
# 1. Navigate to booking page
# 2. Fill booking details
# 3. Click "Proceed to Payment"
# 4. PaymentModal should open
# 5. Select payment method
# 6. Complete test payment with Flutterwave test credentials
```

---

## 🧪 Testing Guide

### Test Credentials (Flutterwave Sandbox)
Use these for testing without real money:

**Card Payments:**
```
Card Number: 5531 8866 5725 2950
Expiry Date: 09/32 (any future date)
CVV: 564
```

**Mobile Money (MTN, Airtel, Zamtel):**
- Phone: +260973000000 through +260973009999 (test range)
- PIN: 0000 (for test mode)

**Test Amount:**
- Any amount works in test mode

### Manual Testing Workflow
```
1. Create booking in app
2. Click "Proceed to Payment"
3. PaymentModal opens
4. Select "Mobile Money" → "Continue"
5. Simulate Flutterwave redirect (test mode shows form)
6. Enter test phone number
7. Confirm payment
8. Should see "Payment Successful"
9. Check payment_transactions table for new record
10. Verify booking auto-confirmed
```

### Automated Testing (Recommended)
Create `src/tests/payment.test.ts`:
```typescript
import { initiatePayment, verifyPayment } from '@/services/paymentService';

describe('Payment Integration', () => {
  test('Initializes payment transaction', async () => {
    const result = await initiatePayment({
      amount: 500,
      currency: 'ZMW',
      userEmail: 'test@example.com',
      userName: 'Test User',
      userPhone: '+260973000000',
      description: 'Test booking',
    });
    
    expect(result.success).toBe(true);
    expect(result.transaction.id).toBeDefined();
  });

  test('Verifies completed payment', async () => {
    // Mock Flutterwave response
    const result = await verifyPayment('tx-123', 'fw-456');
    
    expect(result.success).toBe(true);
    expect(result.message).toContain('verified');
  });
});
```

Run tests:
```bash
npm run test -- payment.test.ts
```

---

## 🔧 Configuration Guide

### Revenue Fee Configuration
Current setting: **10% platform fee**  
Location: `src/services/paymentService.ts` line 14

To change:
```typescript
const REVENUE_FEE_PERCENTAGE = 15; // Change to 15%
```

Updates needed in:
- `paymentService.ts` (calculations)
- Database migration (documentation only)
- Payment display components (shows to users)

### Payment Methods by Region
Currently enabled for Zambia:
- Mobile Money (primary - MTN, Airtel, Zamtel)
- Card (backup - international)
- Bank Transfer (secondary)
- USSD (alternative)

To enable for other regions, add to Flutterwave integration:
```typescript
const REGION_SETTINGS = {
  ZM: ['mobile_money', 'card', 'bank_transfer', 'ussd'],
  NG: ['card', 'bank_transfer', 'mobile_money'],
  // Add more as needed
};
```

### Webhook Configuration
Flutterwave can notify your app of payment status changes.

**Setup in Flutterwave Dashboard:**
1. Settings → Webhooks
2. Add webhook URL: `https://yourdomain.com/api/webhooks/flutterwave`
3. Select events: `charge.completed`, `charge.failed`
4. Enable security hash verification

**Implement webhook handler** (if using serverless functions):
```typescript
// supabase/functions/flutterwave-webhook/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { handlePaymentWebhook } from '@/services/paymentService'

serve(async (req) => {
  if (req.method === 'POST') {
    const signature = req.headers.get('x-flutterwave-signature')
    const payload = await req.json()
    
    // Verify signature (implement security check)
    const result = await handlePaymentWebhook(payload)
    
    return new Response(JSON.stringify(result), { status: 200 })
  }
})
```

---

## 📊 Database Schema Overview

### payment_transactions
Stores all payment attempts
```
- id (UUID): Unique transaction ID
- user_id: User who paid
- booking_id: Associated booking (optional)
- amount: Payment amount in currency
- platform_fee: 10% fee kept by BusNStay
- payment_status: pending|processing|completed|failed|cancelled|refunded
- flutterwave_transaction_id: Reference from Flutterwave API
- payment_response: Full Flutterwave API response (JSONB)
- created_at, updated_at, completed_at: Timestamps
```

### payment_logs
Audit trail of all events
```
- transaction_id: Links to payment_transactions
- event_type: status_update, refund_requested, dispute_reported, etc.
- event_status: Current status at time of event
- actor_type: 'user' or 'admin' or 'system'
- error_code, error_message: If error occurred
- created_at: When event happened
```

### payment_retries
Tracks retry attempts for failed payments
```
- transaction_id: Links to payment_transactions
- attempt_number: 1st, 2nd, 3rd retry
- payment_method: mobile_money, card, bank_transfer, etc.
- is_success: TRUE if retry succeeded
- flutterwave_response: API response from retry
```

### payment_disputes
Handles disputed transactions
```
- transaction_id: Links to payment_transactions
- dispute_reason: What user claims went wrong
- dispute_status: open|investigating|resolved|refunded
- reported_by: User ID who reported
- resolved_by: Admin ID who resolved
- resolution_notes: Admin notes
```

---

## 🚀 API Functions Reference

### initiatePayment()
Start a new payment transaction
```typescript
const result = await initiatePayment({
  amount: 500,                    // ZMW
  currency: 'ZMW',
  userEmail: 'user@example.com',
  userName: 'John Doe',
  userPhone: '+260973000000',
  description: 'Hotel booking confirmation',
  bookingId: '12345',             // Optional
  metadata: { customKey: 'value' } // Optional
});

// Returns:
// { success: true, transaction, publicKey, apiUrl }
// or
// { success: false, error: 'error message' }
```

### verifyPayment()
Verify a completed payment with Flutterwave
```typescript
const result = await verifyPayment(
  transactionId,              // UUID from initiatePayment
  flutterwaveTransactionId    // ID returned by Flutterwave
);

// Returns:
// { success: true, transaction: {...}, message: 'verified' }
// or
// { success: false, error: 'error message' }
```

### processRefund()
Refund a completed payment
```typescript
const result = await processRefund(
  transactionId,    // UUID
  refundAmount,     // e.g., 500 (can be partial)
  reason            // 'User requested refund', etc.
);

// Returns:
// { success: true, refund: {...}, message: 'Refund...' }
```

### getPaymentHistory()
Fetch user's payment transactions
```typescript
const result = await getPaymentHistory(
  userId,     // Optional, defaults to current user
  limit: 10,  // Number of records
  offset: 0   // Pagination offset
);

// Returns:
// { success: true, transactions: [...], count: 10 }
```

### getPaymentAnalytics()
Get revenue analytics for dashboard
```typescript
const result = await getPaymentAnalytics({
  from: new Date('2026-04-01'),
  to: new Date('2026-04-30'),
});

// Returns:
// { success: true, analytics: [...], totals: {...} }
```

---

## 🐛 Troubleshooting

### Payment Modal Not Opening
**Problem**: PaymentModal component not displaying
**Solution**:
1. Verify PaymentModal imported correctly: `import PaymentModal from '@/components/PaymentModal'`
2. Check `isOpen` prop is `true`
3. Verify all required props passed
4. Check browser console for TypeScript errors

### "User not authenticated" Error
**Problem**: Payment fails with auth error
**Solution**:
1. Verify user is logged in before initiating payment
2. Check Supabase auth context working
3. Ensure `useAuthContext()` hook available
4. Verify auth.uid() returns valid UUID

### Flutterwave Tests Not Working
**Problem**: Test credentials failing
**Solution**:
1. Switch to Flutterwave Dashboard → Settings → Mode → Test Mode
2. Use test credentials from guide above
3. Check network tab for API calls
4. Verify API keys are TEST keys, not LIVE keys
5. Look for Flutterwave error codes in network responses

### Database Migration Failed
**Problem**: SQL migration error
**Solution**:
1. Check migration file syntax (SQL formatting)
2. Verify all tables don't already exist
3. Try running in fresh Supabase project first
4. Check Supabase logs for specific error
5. Manually create tables if auto-migration fails

### Booking Not Auto-Confirming
**Problem**: Payment successful but booking still "pending"
**Solution**:
1. Check booking_id is being passed correctly
2. Verify accommodation_bookings table exists
3. Check RLS policies allow booking updates from function
4. Verify `confirmBooking()` function completing without error
5. Check payment_logs for errors during booking confirmation

---

## 📈 Deployment Steps

### For Staging/Testing
```bash
# 1. Set test environment variables
VITE_FLUTTERWAVE_PUBLIC_KEY=FK_TEST_xxxxx
VITE_FLUTTERWAVE_SECRET_KEY=SK_TEST_xxxxx

# 2. Deploy database migration
# (See Step 4 above)

# 3. Deploy code
npm run build
npm run deploy

# 4. Test with Flutterwave test credentials

# 5. Verify payment shows in Supabase
SELECT * FROM payment_transactions WHERE created_at > now() - interval '1 hour';
```

### For Production
```bash
# 1. Switch to LIVE API keys in Flutterwave Dashboard
# 2. Update environment variables
VITE_FLUTTERWAVE_PUBLIC_KEY=FK_LIVE_xxxxx
VITE_FLUTTERWAVE_SECRET_KEY=SK_LIVE_xxxxx

# 3. Backup database
# 4. Deploy database migration
# 5. Deploy code with gradual rollout
# 6. Monitor payment_logs table for errors
# 7. Set up Flutterwave webhooks for notifications
# 8. Send launch announcement to users
```

---

## 🔐 Security Best Practices

1. **Never Commit Secrets**
   ```bash
   # Add to .gitignore
   .env.local
   .env.*.local
   ```

2. **Use Environment Variables**
   - Keep secret keys in env, not code
   - Use different keys for test/production
   - Rotate keys quarterly

3. **Enable Webhooks Verification**
   - Verify signature header from Flutterwave
   - Check request came from Flutterwave IP
   - Implement rate limiting

4. **Validate on Backend**
   - Never trust client-sent payment data
   - Always verify with Flutterwave API
   - Store full response for audits

5. **Encrypt Sensitive Data**
   - Card tokens stored by Flutterwave only
   - Payment responses stored in JSONB (encrypted at rest)
   - PII encrypted in payment_logs

6. **Audit Trail**
   - Every payment event logged
   - Admin can review payment_logs
   - Dispute system for customer protection

---

## 📞 Support & Escalation

### Flutterwave Support
- Website: https://support.flutterwave.com
- Live Chat: In Flutterwave Dashboard
- Email: support@flutterwave.com
- Test Credentials: Available in Dashboard

### Common Flutterwave Error Codes
- `INVALID_AUTH`: Wrong API credentials
- `AUTH_DECLINED`: User didn't authorize payment
- `CARD_DECLINED`: Card issuer declined
- `INSUFFICIENT_FUNDS`: Not enough money
- `INVALID_AMOUNT`: Amount not supported
- `OPERATOR_TIMEOUT`: Mobile operator timeout

### BusNStay Payment Issues
- Check payment_logs table for event history
- Verify Supabase RLS policies working
- Check browser console for client errors
- Look for Flutterwave API errors in network tab
- Contact Flutterwave support if persistent

---

## ✅ Verification Checklist Before Launch

- [ ] Flutterwave account created and approved
- [ ] API keys generated and stored in .env
- [ ] Database migration applied successfully
- [ ] Service files in correct directories
- [ ] PaymentModal component working
- [ ] Integrated into booking flow
- [ ] Test payment successful with test credentials
- [ ] Payment appears in payment_transactions table
- [ ] Booking auto-confirmed after payment
- [ ] Payment UI shows correct fees and total
- [ ] Error handling working
- [ ] Refund flow tested
- [ ] Analytics queries working
- [ ] Webhooks configured (optional for v1)
- [ ] Team trained on payment system

---

## 📚 Additional Resources

- **Flutterwave Docs**: https://developer.flutterwave.com/
- **Zambia Payment Methods**: https://support.flutterwave.com/zmb
- **API Reference**: https://docs.flutterwave.com/reference
- **Test Payment Guide**: https://docs.flutterwave.com/test

---

**Status**: Ready for deployment  
**Estimated Deployment Time**: 1 hour  
**Team**: Development Team  
**Last Updated**: April 1, 2026
