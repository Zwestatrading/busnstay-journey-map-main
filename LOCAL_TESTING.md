# 🧪 Local Testing Guide

## Quick Start (5 minutes)

```bash
# 1. Navigate to your project
cd C:\Users\zwexm\LPSN\busnstay-journey-map-main

# 2. Install dependencies (if not done)
npm install

# 3. Start dev server
npm run dev

# 4. Open browser
# http://localhost:5173

# 5. Navigate to Account page
# http://localhost:5173/account
```

---

## Complete Setup (30 minutes)

### **Step 1: Environment Variables**

Create file: `.env.local`

```env
# Supabase
VITE_SUPABASE_URL=your_supabase_url_here
VITE_SUPABASE_ANON_KEY=your_anon_key_here

# Stripe (optional for local testing)
VITE_STRIPE_PUBLIC_KEY=pk_test_your_test_key_here

# App
VITE_APP_ENV=development
```

**Get Supabase credentials:**
1. Go to https://app.supabase.com/
2. Select your project
3. Click Settings → API
4. Copy "Project URL" and "anon key"
5. Paste into `.env.local`

### **Step 2: Run Database Migrations**

```bash
# Option A: Via Supabase Dashboard (Recommended)
1. Open: https://app.supabase.com/
2. Click: SQL Editor
3. Click: New Query
4. Copy: supabase/migrations/loyalty_wallet_schema.sql
5. Click: Run
```

**Option B: Via CLI (if installed)**
```bash
supabase migration up
```

### **Step 3: Create Test User & Data**

1. In your app, click "Sign In"
2. Create test account (email: `test@busnstay.local`, password: anything)
3. Run this SQL to add test data:

```sql
-- Copy this into Supabase SQL Editor and run:

-- Add test loyalty points
UPDATE public.user_loyalty
SET current_points = 2450
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'test@busnstay.local');

-- Add test wallet balance
UPDATE public.wallets
SET balance = 2850.50
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'test@busnstay.local');

-- Add test transactions
INSERT INTO public.wallet_transactions
(wallet_id, type, amount, description, status)
SELECT id, 'credit', 100.00, 'Welcome bonus', 'completed'
FROM public.wallets
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'test@busnstay.local');

INSERT INTO public.wallet_transactions
(wallet_id, type, amount, description, status)
SELECT id, 'debit', 25.50, 'Bus Booking - Lusaka to Ndola', 'completed'
FROM public.wallets
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'test@busnstay.local');
```

### **Step 4: Start Development Server**

```bash
npm run dev
```

**Output should show:**
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  press h to show help
```

### **Step 5: Test the System**

1. Open: http://localhost:5173/
2. Click "Sign In" button
3. Login with test account
4. Click "Account" in header
5. Should see:
   - Wallet balance: $2,850.50
   - Loyalty points: 2,450
   - Current tier: Silver
   - Transaction history showing your test transactions

✅ **Local setup complete!**

---

## Testing Each Feature

### **Test 1: View Account Dashboard**

```
URL: http://localhost:5173/account

VERIFY:
✅ Page loads without errors
✅ Wallet balance displays: $2,850.50
✅ Loyalty points display: 2,450
✅ Current tier shows: Silver
✅ Member since shows: 245 days (or similar)
✅ All 4 tabs visible: Overview, Wallet, Rewards, Settings
```

### **Test 2: Wallet Tab**

```
Click: Wallet tab

VERIFY:
✅ Balance card displays: $2,850.50
✅ Show/hide balance toggle works
✅ 3 quick action buttons visible: Add Funds, Transfer, Withdraw
✅ Transaction history shows 2 transactions
✅ Each transaction shows: type, amount, description, status
✅ Can expand transactions to see details
```

### **Test 3: Rewards Tab**

```
Click: Rewards tab

VERIFY:
✅ Tier progress bar visible (Silver, 550 points to next tier)
✅ 4 tier benefits sections visible
✅ 6 reward cards visible from marketplace:
   - Free Ride ($50)
   - Hotel Room Upgrade
   - 3 Meal Vouchers
   - $20 Travel Credit
   - VIP Badge
   - Free Airport Transfer
✅ Can filter by category
✅ "How It Works" section visible with 4 steps
✅ Referral section shows referral code & bonus
```

### **Test 4: Browser Console**

```
1. Press F12 to open Developer Tools
2. Check Console tab
3. Should see NO errors
4. Should see network requests to Supabase
```

### **Test 5: Network Requests**

```
1. Press F12 → Network tab
2. Refresh page
3. Should see requests to:
   ✅ supabase (auth requests)
   ✅ user_loyalty table query
   ✅ wallets table query
   ✅ wallet_transactions query
   ✅ payment_methods query
   ✅ loyalty_rewards query

All should return 200 status
```

---

## Testing Without Database Setup (Demo Mode)

If you want to test WITHOUT setting up Supabase:

### **Option 1: Mock Data in Component**

Edit `src/pages/AccountDashboard.tsx`:

```typescript
// Find these lines near the top:
const { loyalty, isLoadingLoyalty, redeemReward } = useLoyaltyData();
const { wallet, isLoadingWallet, addFunds } = useWalletData();

// Temporarily comment them out and add mock data:
// const { loyalty, isLoadingLoyalty, redeemReward } = useLoyaltyData();
// const { wallet, isLoadingWallet, addFunds } = useWalletData();

const mockLoyalty = {
  current_points: 2450,
  total_points_earned: 5230,
  tier: 'silver',
  referral_code: 'REF-12345678',
};

const mockWallet = {
  balance: 2850.50,
  currency: 'USD',
  wallet_status: 'active',
};

// Then use mockLoyalty and mockWallet in render
// instead of loyalty and wallet
```

This lets you see the UI without a database!

### **Option 2: Inspect Network Response**

1. Open DevTools → Network tab
2. Click on wallet transactions request
3. Can see actual JSON response from Supabase
4. Verify structure matches expectations

---

## Common Testing Scenarios

### **Scenario 1: Fresh User Sign Up**

```
1. Create new email (e.g., newuser@test.com)
2. Sign up
3. Navigate to /account
4. Should see:
   ✅ No balance (0)
   ✅ No points (0)
   ✅ Tier: Bronze
   ✅ No transactions
   ✅ No payment methods
5. useInitializeLoyaltyWallet should have created records
```

**Test Command:**
```sql
-- Check if records created
SELECT * FROM public.user_loyalty WHERE user_id = '...new_user_id...';
SELECT * FROM public.wallets WHERE user_id = '...new_user_id...';
```

### **Scenario 2: Add Wallet Funds (Demo)**

```
1. Click "Wallet" tab
2. Click "Add Funds" button
3. Modal appears with options: $25, $50, $100, or custom
4. Select $25
5. Modal shows payment method selection
6. Choose "Card" or "Mobile Money"
7. Click "Submit" (in dev mode, just logs to console)
8. Toast notification appears
```

**Note:** Actual payment only works with Stripe setup. For demo, the transaction is created as "pending".

### **Scenario 3: Redeem Loyalty Reward**

```
1. Click "Rewards" tab
2. Find "Free Ride ($50)" reward (1000 points required)
3. Notice button says "Redeem" (you have 2450 points, so eligible)
4. Click "Redeem" button
5. Should see:
   ✅ Toast: "Reward Redeemed!"
   ✅ Points decrease: 2450 → 1450
   ✅ Reward marked as "Redeemed"
   ✅ Appears in "My Rewards" section
```

**Test Command:**
```sql
-- Check if redemption created
SELECT * FROM public.reward_redemptions WHERE user_id = '...test_user_id...';
```

### **Scenario 4: Tier Progression**

```
1. Start with 2450 points (Silver tier)
2. Add more points via SQL:
   UPDATE public.user_loyalty SET current_points = 5000;
3. Refresh page
4. Should see:
   ✅ Tier changed to "Gold"
   ✅ Progress bar updated
   ✅ New tier benefits visible
```

### **Scenario 5: Settings & Preferences**

```
1. Click "Settings" tab
2. Should see:
   ✅ Email notification checkboxes
   ✅ Security options
   ✅ Change Password link
   ✅ Two-Factor Authentication link
   ✅ Sign Out button
   ✅ Delete Account button
3. Click "Sign Out"
4. Should redirect to auth page
```

---

## Debugging Checklist

### **If the page doesn't load:**

```bash
# Check console for errors
# Press F12 → Console tab

# Common issues:
❌ "Cannot read property of undefined"
   → Hook not returning data yet
   → Check Supabase credentials in .env.local

❌ "401 Unauthorized"
   → Supabase anon key is wrong
   → Double-check in .env.local

❌ "Network error"
   → Supabase URL is wrong
   → Check internet connection
   → Check Supabase project status
```

### **If data doesn't show:**

```bash
# 1. Check browser Network tab
# Should see requests to Supabase

# 2. Check Supabase SQL Editor
# Run: SELECT * FROM user_loyalty;
# Should see your test user's record

# 3. Check RLS policies
# Supabase → Table Editor → Click table → RLS policies tab
# Verify "Users can view their own loyalty profile" is enabled

# 4. Clear browser cache
# Ctrl+Shift+Delete → Clear all
# Refresh page
```

### **If you see "Loading..."**

```bash
# 1. Check that useInitializeLoyaltyWallet ran
# Open DevTools → Network → Look for:
#    - user_loyalty SELECT
#    - user_loyalty INSERT (if new user)
#    - wallets SELECT
#    - wallets INSERT (if new user)

# 2. Wait 2-3 seconds
# Initial query might be slow first time

# 3. Check Supabase status
# Go to: https://status.supabase.com/
# Verify no incidents

# 4. Manually create records in Supabase
# Use SQL commands above
```

---

## Testing Payment Flow (Demo)

```
1. Click Wallet tab
2. Click "Add Funds" button
3. Modal appears

WITHOUT Stripe setup:
├─ Fill in amount ($25)
├─ Select payment method
├─ Click "Submit"
├─ Toast shows "Fund Added (Demo mode)"
└─ Transaction created as "pending" in database

WITH Stripe setup:
├─ Fill in amount
├─ Enter test card: 4242 4242 4242 4242
├─ Use any future date and CVC
├─ Click "Submit"
└─ Payment processes and balance updates
```

**Test Cards (Stripe):**
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
Decline (CVC): 4000 0000 0000 0127
```

---

## Performance Testing

```bash
# Open DevTools → Performance tab
# Click Record
# Interact with page
# Stop recording

CHECK:
✅ Page load: < 3 seconds
✅ Tab transitions: < 500ms
✅ Reward redemption: < 1 second
✅ No long tasks blocking main thread
```

---

## Mobile Testing

```bash
# Test responsive design
# Press F12 → Toggle device toolbar (Ctrl+Shift+M)

TEST DEVICES:
✅ iPhone 12 (390x844)
✅ Pixel 5 (393x851)
✅ iPad (768x1024)
✅ Desktop (1920x1080)

VERIFY:
✅ Layout adapts
✅ Buttons clickable
✅ Forms responsive
✅ No horizontal scroll
✅ Text readable
```

---

## Full Test Case Template

```gherkin
Feature: Account Dashboard - Loyalty & Wallet

Scenario: View account overview as authenticated user
  Given I'm logged in as test@busnstay.local
  When I navigate to /account
  Then I should see:
    - Wallet balance: $2,850.50
    - Loyalty points: 2,450
    - Current tier: Silver
    - Member since: 245 days

Scenario: Redeem loyalty reward
  Given I'm on the Rewards tab
  And I have 2,450 loyalty points
  When I click "Redeem" on Free Ride ($50) reward
  Then:
    - Points should decrease to 1,450
    - Toast notification appears
    - Reward marked as "Redeemed"

Scenario: Add funds to wallet
  Given I'm on the Wallet tab
  When I click "Add Funds"
  And I enter amount: $50
  And I select payment method: Card
  And I click "Submit"
  Then:
    - Modal closes
    - Success toast appears
    - New transaction appears in history

Scenario: Navigate between tabs
  Given I'm on the Account page
  When I click different tabs
  Then:
    - Content updates correctly
    - No errors in console
    - Previous tab state lost (not persisted)
```

---

## Monitoring During Local Testing

```bash
# Watch console for errors
# Open DevTools → Console
# Devices: Real-time errors show here

# Watch Network tab
# DevTools → Network
# All requests should be successful (200, 201)

# Watch Application tab
# DevTools → Application → Storage
# Check:
  - Supabase auth token in localStorage
  - Session data
  - No errors in console

# Performance Profiling
# DevTools → Performance
# Record interactions
# Check for bottlenecks
```

---

## Troubleshooting Test Issues

### **"useInitializeLoyaltyWallet didn't run"**

Add to `App.tsx` (right at the start):

```typescript
import { useInitializeLoyaltyWallet } from '@/hooks/useInitializeLoyaltyWallet';

const App = () => {
  useInitializeLoyaltyWallet(); // Add this line
  
  // ... rest of app
  return (
    // ...
  );
};
```

### **"Loyalty data not loading"**

Check these things:
```bash
1. Is Supabase URL in .env.local? (with full path)
2. Is anon key in .env.local? (not secret key)
3. Does user exist in auth.users?
4. Do loyalty_records exist for that user?
5. Are RLS policies enabled?
6. Does browser show request in Network tab?
```

### **"Wallet balance showing $0"**

```sql
-- Check wallet exists
SELECT * FROM public.wallets WHERE user_id = '...';

-- If empty, create one
INSERT INTO public.wallets (user_id, balance) 
VALUES ('your-user-id', 2850.50);

-- Check balance updated
SELECT balance FROM public.wallets WHERE user_id = '...';
```

### **"TypeScript errors about hooks"**

```bash
# Make sure hooks exist:
# src/hooks/useLoyaltyData.ts
# src/hooks/useWalletData.ts
# src/hooks/useInitializeLoyaltyWallet.ts

# If missing, create them from ACTIONPLAN.md

# Clear TypeScript cache:
rm -r node_modules/.vite
npm run dev
```

---

## Quick Commands Reference

```bash
# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Type check
npx tsc --noEmit

# Clear cache
rm -r node_modules/.vite
rm -r .next (if using Next.js)

# Fresh install
rm package-lock.json
npm install

# View Supabase logs
# https://app.supabase.com/ → Logs → Edge Functions
```

---

## Test Data Reset

To start fresh:

```sql
-- Delete all transactions for test user
DELETE FROM public.wallet_transactions 
WHERE wallet_id IN (
  SELECT id FROM public.wallets 
  WHERE user_id = '...'
);

-- Reset wallet balance
UPDATE public.wallets 
SET balance = 0 
WHERE user_id = '...';

-- Reset loyalty points
UPDATE public.user_loyalty 
SET current_points = 0, tier = 'bronze' 
WHERE user_id = '...';

-- Delete redemptions
DELETE FROM public.reward_redemptions 
WHERE user_id = '...';
```

---

## Success Checklist

After local testing, you should be able to:

- [x] Start dev server without errors
- [x] Login with test account
- [x] Navigate to /account
- [x] See wallet balance & loyalty points
- [x] View all 4 tabs (Overview, Wallet, Rewards, Settings)
- [x] See transactions in wallet
- [x] See rewards in marketplace
- [x] Redeem a reward (points decrease)
- [x] Click "Add Funds" (modal appears)
- [x] No console errors
- [x] Mobile view looks good

✅ **If all checked:** You're ready for next phase! 🚀

---

## Next Steps After Testing

1. ✅ Local testing done
2. ➡️ Follow [ACTIONPLAN.md](./ACTIONPLAN.md) Phase 4 (Stripe setup)
3. ➡️ Deploy to production
4. ➡️ Real user testing

---

Questions? Check:
- Browser console for errors (F12)
- Supabase logs: https://app.supabase.com/ → Logs
- Network requests (F12 → Network tab)
- [NEXT_STEPS.md](./NEXT_STEPS.md) Troubleshooting section
