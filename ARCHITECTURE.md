# 🏗️ Architecture & Data Flow Guide

## System Architecture Diagram

```
┌──────────────────────────────────────────────────────────────────────┐
│                        BUSNSTAY APP FRONTEND                         │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │              AccountDashboard (/account)                    │    │
│  ├─────────────────────────────────────────────────────────────┤    │
│  │                          Tabs                               │    │
│  │  ┌──────────── ┌─────────── ┌───────────── ┌────────────┐  │    │
│  │  │  Overview   │   Wallet   │   Rewards    │  Settings  │  │    │
│  │  └──────┬──────┴──────┬──────┴──────┬───────┴─────┬──────┘  │    │
│  │         │             │             │             │         │    │
│  │    [Quick Stats]  [DigitalWallet] [LoyaltyProgram][Prefs] │    │
│  │         │             │             │             │         │    │
│  └─────────┼─────────────┼─────────────┼─────────────┼─────────┘    │
│            │             │             │             │               │
└────────────┼─────────────┼─────────────┼─────────────┼───────────────┘
             │             │             │             │
      useLoyaltyData() useWalletData()  useWalletData()│
             │             │             │             │
┌────────────┼─────────────┼─────────────┼─────────────┼───────────────┐
│            │             │             │             │               │
│  ┌─────────▼─────────────▼─────────────▼─────────────▼──────────┐   │
│  │              @tanstack/react-query (Data Cache)              │   │
│  │         Manages state, caching, and real-time updates        │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              │                                       │
│  ┌───────────────────────────▼──────────────────────────────────┐   │
│  │            Supabase Client (supabase/client)                 │   │
│  │         Handles auth, RLS, and database queries              │   │
│  └───────────────────────────┬──────────────────────────────────┘   │
│                              │                                       │
│                            API                                       │
│                              │                                       │
└──────────────────────────────┼───────────────────────────────────────┘
                               │
        ┌──────────────────────┴──────────────────────┐
        │                                             │
        │                                             │
   ┌────▼─────────────────────────────────────────────────┐
   │         SUPABASE BACKEND (PostgreSQL Database)       │
   ├──────────────────────────────────────────────────────┤
   │                                                      │
   │  LOYALTY TABLES:                WALLET TABLES:       │
   │  ├─ user_loyalty               ├─ wallets            │
   │  ├─ loyalty_transactions        ├─ wallet_transaction │
   │  ├─ loyalty_rewards             ├─ payment_methods    │
   │  ├─ reward_redemptions          ├─ wallet_deposits    │
   │  └─ referrals                   └─ wallet_transfers   │
   │                                                      │
   │  ┌────────────────────────────────────────────┐    │
   │  │  RLS Policies (User data isolation)         │    │
   │  │  Triggers & Functions (Auto-calculations)   │    │
   │  │  Views (Analytics & reporting)              │    │
   │  └────────────────────────────────────────────┘    │
   │                                                      │
   └──────────────────────────────────────────────────────┘
```

---

## Data Flow: User Journey

### **1. User Signs Up / Logs In**

```
User clicks "Sign In"
  ↓
AuthPage component
  ↓
Supabase auth.signUp() / signIn()
  ↓
useInitializeLoyaltyWallet() hook runs
  ↓
Check user_loyalty table for user_id
  ├─ If not found: INSERT into user_loyalty (points=0, tier='bronze')
  └─ If found: Skip
  ↓
Check wallets table for user_id
  ├─ If not found: INSERT into wallets (balance=0)
  └─ If found: Skip
  ↓
✅ User ready for loyalty & wallet features
```

### **2. User Views Account Dashboard**

```
User navigates to /account
  ↓
AccountDashboard component mounted
  ↓
useLoyaltyData() hook fires:
  ├─ Query: SELECT * FROM user_loyalty WHERE user_id = auth.uid()
  ├─ Query: SELECT * FROM loyalty_transactions WHERE user_id = auth.uid()
  └─ Result cached by React Query
  ↓
useWalletData() hook fires:
  ├─ Query: SELECT * FROM wallets WHERE user_id = auth.uid()
  ├─ Query: SELECT * FROM wallet_transactions WHERE wallet_id = ?
  ├─ Query: SELECT * FROM payment_methods WHERE user_id = auth.uid()
  └─ Result cached by React Query
  ↓
✅ Dashboard renders with real data
```

### **3. User Makes a Booking**

```
User completes booking ($120)
  ↓
Backend creates booking record
  ↓
Business logic:
  ├─ Calculate loyalty points: $120 × 5% = 6 points (for silver tier)
  ├─ Deduct from wallet OR request payment
  └─ Log transaction
  ↓
Insert loyalty_transaction:
  (user_id, type='earning', points=6, description='...)
  ↓
Trigger: update_loyalty_tier() fires
  ├─ Recalculates tier: 2450 + 6 = 2456 points → still 'silver'
  └─ Updates user_loyalty.updated_at
  ↓
Insert wallet_transaction:
  (wallet_id, type='debit', amount=120, status='completed')
  ↓
Trigger: update_wallet_balance() fires
  ├─ Updates wallets.balance = 2850.50 - 120 = 2730.50
  └─ Updates wallets.updated_at
  ↓
React Query invalidates cache & refetches
  ↓
✅ Dashboard updates automatically with new balance & points
```

### **4. User Redeems a Reward**

```
User clicks "Redeem" on $50 Free Ride reward
  ↓
Component calls redeemReward(reward_id='free-ride-50')
  ↓
Hook validates:
  ├─ Check loyalty.current_points >= reward.points_required (1000)
  ├─ Check reward.active = true
  └─ Check max_redemptions not exceeded
  ↓
If valid:
  ├─ INSERT reward_redemptions (user_id, reward_id, points_spent=1000)
  ├─ UPDATE user_loyalty: current_points = 2456 - 1000 = 1456
  ├─ INSERT loyalty_transactions (type='redemption', points=-1000)
  └─ UPDATE loyalty_rewards: current_redemptions += 1
  ↓
Trigger: update_loyalty_tier() fires
  ├─ Recalculates tier: 1456 points → still 'silver' (requires 1000-4999)
  └─ Updates last_activity timestamp
  ↓
React Query invalidates cache & refetches
  ↓
✅ Dashboard shows reduced points, reward marked as "Redeemed"
```

### **5. User Adds Wallet Funds**

```
User clicks "Add Funds" button
  ↓
Modal opens with amount options ($25, $50, $100) or custom input
  ↓
User selects payment method (Card / Mobile / Bank)
  ↓
Submit → calls addFunds(amount=100, paymentMethodId)
  ↓
Hook:
  ├─ INSERT wallet_deposits (status='pending')
  ├─ Call payment processor (Stripe/PayPal/MMoney)
  └─ Wait for webhook confirmation
  ↓
Webhook received (payment processor → backend):
  ├─ Verify payment_reference
  ├─ UPDATE wallet_deposits: status='completed'
  ├─ INSERT wallet_transactions (type='credit', amount=100)
  └─ Make webhook call to update balance
  ↓
Trigger: update_wallet_balance() fires when transaction inserted
  ├─ Updates wallets.balance = 2730.50 + 100 = 2830.50
  └─ Updates last_activity
  ↓
React Query refetches wallet data
  ↓
✅ Dashboard shows new balance instantly
```

---

## Component Architecture

### **AccountDashboard.tsx** (Parent)
- Manages tab state (overview, wallet, rewards, settings)
- Loads loyalty and wallet data
- Passes data & callbacks to child components
- Handles sign-out, referral copy, etc.

### **DigitalWallet.tsx** (Child)
- Displays wallet balance & toggles show/hide
- Shows payment methods list
- Shows transaction history
- "Add Funds" modal
- Quick action buttons (Transfer, Withdraw)

### **LoyaltyProgram.tsx** (Child)
- Displays tier progress bar
- Shows tier benefits
- Rewards marketplace with filtering
- Referral code & bonus info
- "How It Works" section

---

## Database Schema Summary

### **Loyalty System**

**user_loyalty**
- PK: id
- FK: user_id
- Fields: current_points, total_points_earned, tier, referral_code
- Indexes: user_id, tier, referral_code
- RLS: Users can only see/update their own

**loyalty_transactions**
- PK: id
- FK: user_id
- Type: earning | redemption | referral | bonus
- Used for: Point history audit trail

**loyalty_rewards** (Admin-managed)
- PK: id (string)
- Fields: name, points_required, category, popularity_score
- Used for: Rewards marketplace catalog

**reward_redemptions**
- PK: id
- FK: user_id, reward_id
- Fields: points_spent, status, expires_at
- Used for: Track which users claimed which rewards

**referrals**
- PK: id
- FK: referrer_user_id, referee_user_id
- Status: pending | completed | expired
- Bonus: 500 points per successful referral

---

### **Wallet System**

**wallets**
- PK: id
- FK: user_id (unique - one wallet per user)
- Fields: balance, currency, wallet_status
- Auto-calculated: Updated by triggers on transactions

**wallet_transactions**
- PK: id
- FK: wallet_id, payment_method_id
- Type: debit | credit | refund | transfer | withdrawal | deposit
- Status: pending | completed | failed | cancelled
- Auto-updates: wallet.balance via trigger

**payment_methods**
- PK: id
- FK: user_id (multiple per user)
- Type: card | mobile | bank | wallet
- Security: Store token encrypted only, last 4 digits visible

**wallet_deposits**
- PK: id
- FK: wallet_id, payment_method_id
- Status: pending → processing → completed
- Tracks: Third-party payment processor responses

**wallet_transfers**
- PK: id
- FK: from_wallet_id, to_wallet_id
- Type: User-to-user transfers
- Peer-to-peer payments

---

## Security Implementation

### **Row-Level Security (RLS)**
```sql
-- Users can only see their own loyalty data
CREATE POLICY "Users can view their own loyalty profile"
  ON public.user_loyalty FOR SELECT 
  USING (auth.uid() = user_id);

-- Wallet transactions are isolated by RLS
CREATE POLICY "Users can view their own transactions"
  ON public.wallet_transactions FOR SELECT 
  USING (
    auth.uid() = (SELECT user_id FROM public.wallets WHERE id = wallet_id)
  );
```

### **Payment Security**
- Payment tokens never stored in plaintext
- Encryption at application level before storage
- PCI compliance via third-party processor (Stripe/PayPal)
- Rate limiting on sensitive endpoints
- Webhook signature verification

### **Authentication**
- Supabase JWT tokens (expires 1 hour default)
- Refresh tokens stored in secure HTTP-only cookie
- Sign-out clears refresh token

---

## Real-Time Features (Optional Future)

```typescript
// Listen to loyalty points changes in real-time
const loyaltySubscription = supabase
  .from('user_loyalty')
  .on('UPDATE', payload => {
    queryClient.invalidateQueries(['loyalty']);
  })
  .subscribe();

// Listen to wallet balance changes
const walletSubscription = supabase
  .from('wallets')
  .on('UPDATE', payload => {
    queryClient.invalidateQueries(['wallet']);
  })
  .subscribe();
```

---

## Performance Considerations

### **Query Optimization**
- Indexes on: user_id, type, created_at, status
- Pagination on transactions (LIMIT 50)
- View materialization for analytics queries

### **Caching Strategy**
- React Query cache: 5 minutes default
- Disable cache on mutations (auto-refetch)
- Use `queryClient.prefetchQuery()` for next page

### **Database Triggers**
- Auto-calculate tier on points change
- Auto-update wallet balance on transactions
- Reduce N+1 queries

---

## Monitoring & Analytics

### **Views Available**
1. `user_loyalty_summary` - Aggregate loyalty stats per user
2. `wallet_summary` - Wallet balance and transaction count per user
3. `wallet_monthly_analytics` - Monthly spending by user

### **Metrics to Track**
- Daily active users with wallet
- Average wallet balance
- Total transaction volume by type
- Redemption rate (earned vs redeemed points)
- Average points per tier
- Referral conversion rate

---

## Deployment Checklist

- [ ] Database migrations run successfully
- [ ] RLS policies verified
- [ ] Sample rewards loaded (`loyalty_rewards` table)
- [ ] Test user created and initialized
- [ ] Account dashboard accessible at `/account`
- [ ] Real data flowing from backend
- [ ] Payment processor credentials set
- [ ] Error boundaries added
- [ ] Loading states tested
- [ ] Rate limiting configured
- [ ] Monitoring set up (Sentry, LogRocket, etc.)

---

This architecture is scalable to 100K+ users and handles all redemptions, transfers, and payments securely. 🚀
