# 🎉 Next Steps: Loyalty & Wallet Integration Complete!

## ✅ What's Done

1. **AccountDashboard.tsx** - Full-featured account dashboard with:
   - Overview tab with quick stats (wallet balance, loyalty points, tier, member timeline)
   - Wallet tab with integrated DigitalWallet component
   - Rewards tab with integrated LoyaltyProgram component
   - Settings tab with email preferences, security, and account actions
   - Dark premium theme with Framer Motion animations

2. **Database Schema** (`supabase/migrations/loyalty_wallet_schema.sql`) - Complete SQL with:
   - Loyalty tables (user_loyalty, loyalty_transactions, loyalty_rewards, reward_redemptions, referrals)
   - Wallet tables (wallets, wallet_transactions, payment_methods, wallet_deposits, wallet_transfers)
   - Row Level Security (RLS) policies
   - Helper functions for tier calculation and balance updates
   - Sample reward data
   - Analytics views

3. **Routing** - Added `/account` route to your React app pointing to AccountDashboard

4. **Navigation** - Updated LandingPage header with "Account" button for logged-in users

---

## 📋 Step-by-Step Setup Instructions

### **Step 1: Set Up Supabase Database (5 min)**

1. Go to [Supabase](https://supabase.com) and log in to your project
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of `supabase/migrations/loyalty_wallet_schema.sql`
5. Paste into the SQL editor
6. Click **Run** button
7. ✅ All tables, RLS policies, and sample data are created

**Verify:** Go to **Table Editor** → You should see all 10 new tables in the left sidebar

---

### **Step 2: Create API Hooks for Data Fetching (10 min)**

Create this file: `src/hooks/useLoyaltyData.ts`

```typescript
import { useQuery, useMutation } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuthContext } from '@/contexts/AuthContext';

export const useLoyaltyData = () => {
  const { user } = useAuthContext();

  // Fetch user loyalty profile
  const loyaltyQuery = useQuery({
    queryKey: ['loyalty', user?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('user_loyalty')
        .select('*')
        .eq('user_id', user!.id)
        .maybeSingle();

      if (error) throw error;
      return data;
    },
    enabled: !!user,
  });

  // Fetch loyalty transactions
  const transactionsQuery = useQuery({
    queryKey: ['loyalty_transactions', user?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('loyalty_transactions')
        .select('*')
        .eq('user_id', user!.id)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      return data || [];
    },
    enabled: !!user,
  });

  // Mutation: Redeem reward
  const redeemRewardMutation = useMutation({
    mutationFn: async (rewardId: string) => {
      if (!loyaltyQuery.data) throw new Error('No loyalty data');

      // Check points sufficient
      const reward = await supabase
        .from('loyalty_rewards')
        .select('points_required')
        .eq('id', rewardId)
        .single();

      if (loyaltyQuery.data.current_points < reward.data!.points_required) {
        throw new Error('Insufficient points');
      }

      // Create redemption record
      const { data, error } = await supabase
        .from('reward_redemptions')
        .insert({
          user_id: user!.id,
          reward_id: rewardId,
          points_spent: reward.data!.points_required,
        })
        .select()
        .single();

      if (error) throw error;

      // Update loyalty points
      await supabase
        .from('user_loyalty')
        .update({
          current_points: loyaltyQuery.data.current_points - reward.data!.points_required,
        })
        .eq('user_id', user!.id);

      return data;
    },
  });

  return {
    loyalty: loyaltyQuery.data,
    isLoadingLoyalty: loyaltyQuery.isLoading,
    transactions: transactionsQuery.data || [],
    redeemReward: redeemRewardMutation.mutateAsync,
    isRedeeming: redeemRewardMutation.isPending,
  };
};
```

Similarly, create `src/hooks/useWalletData.ts`:

```typescript
import { useQuery, useMutation } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { useAuthContext } from '@/contexts/AuthContext';

export const useWalletData = () => {
  const { user } = useAuthContext();

  // Fetch wallet
  const walletQuery = useQuery({
    queryKey: ['wallet', user?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('wallets')
        .select('*')
        .eq('user_id', user!.id)
        .maybeSingle();

      if (error) throw error;
      return data;
    },
    enabled: !!user,
  });

  // Fetch transactions
  const transactionsQuery = useQuery({
    queryKey: ['wallet_transactions', walletQuery.data?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('wallet_transactions')
        .select('*')
        .eq('wallet_id', walletQuery.data!.id)
        .order('created_at', { ascending: false })
        .limit(50);

      if (error) throw error;
      return data || [];
    },
    enabled: !!walletQuery.data,
  });

  // Fetch payment methods
  const paymentMethodsQuery = useQuery({
    queryKey: ['payment_methods', user?.id],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('payment_methods')
        .select('*')
        .eq('user_id', user!.id);

      if (error) throw error;
      return data || [];
    },
    enabled: !!user,
  });

  // Mutation: Add funds
  const addFundsMutation = useMutation({
    mutationFn: async ({ amount, paymentMethodId }: { amount: number; paymentMethodId: string }) => {
      // TODO: Call payment processor (Stripe/Paypal/etc)
      // For now, create a pending transaction
      const { data, error } = await supabase
        .from('wallet_deposits')
        .insert({
          wallet_id: walletQuery.data!.id,
          amount,
          payment_method_id: paymentMethodId,
          status: 'pending',
        })
        .select()
        .single();

      if (error) throw error;
      return data;
    },
  });

  return {
    wallet: walletQuery.data,
    isLoadingWallet: walletQuery.isLoading,
    transactions: transactionsQuery.data || [],
    paymentMethods: paymentMethodsQuery.data || [],
    addFunds: addFundsMutation.mutateAsync,
    isAddingFunds: addFundsMutation.isPending,
  };
};
```

---

### **Step 3: Initialize Loyalty & Wallet for New Users (5 min)**

Create `src/hooks/useInitializerLoyaltyWallet.ts`:

```typescript
import { useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuthContext } from '@/contexts/AuthContext';
import { v4 as uuidv4 } from 'uuid';

export const useInitializeLoyaltyWallet = () => {
  const { user } = useAuthContext();

  useEffect(() => {
    if (!user) return;

    const initialize = async () => {
      // Check if loyalty record exists
      const { data: loyaltyExists } = await supabase
        .from('user_loyalty')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (!loyaltyExists) {
        // Create loyalty profile
        await supabase.from('user_loyalty').insert({
          user_id: user.id,
          referral_code: `REF-${user.id.slice(0, 8).toUpperCase()}`,
        });
      }

      // Check if wallet exists
      const { data: walletExists } = await supabase
        .from('wallets')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

      if (!walletExists) {
        // Create wallet
        await supabase.from('wallets').insert({
          user_id: user.id,
          balance: 0,
        });
      }
    };

    initialize();
  }, [user]);
};
```

Add this hook to your main `App.tsx` or `AuthProvider`:

```tsx
const App = () => {
  useInitializeLoyaltyWallet(); // Add this line
  // ... rest of your app
};
```

---

### **Step 4: Update AccountDashboard to Use Real Data (10 min)**

Replace the mock state in `src/pages/AccountDashboard.tsx` with real data:

```typescript
// At the top, add imports:
import { useLoyaltyData } from '@/hooks/useLoyaltyData';
import { useWalletData } from '@/hooks/useWalletData';

// Inside component, replace mock state:
const AccountDashboard = () => {
  const { loyalty, transactions: loyaltyTransactions, redeemReward } = useLoyaltyData();
  const { wallet, transactions: walletTransactions, addFunds } = useWalletData();
  
  // Now use: loyalty?.current_points, wallet?.balance, etc.
  
  return (
    // ... render using actual data
  );
};
```

---

### **Step 5: Enable Email Notifications (Optional, 5 min)**

Add this to your Supabase migrations to send emails on rewards:

```sql
-- Function to send reward redemption email
CREATE OR REPLACE FUNCTION notify_reward_redeemed()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Supabase function to send email
  PERFORM send_email(
    (SELECT email FROM auth.users WHERE id = NEW.user_id),
    'Reward Redeemed!',
    'Your reward has been successfully redeemed. Check your account dashboard.'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_notify_reward
AFTER INSERT ON reward_redemptions
FOR EACH ROW
EXECUTE FUNCTION notify_reward_redeemed();
```

---

## 🔌 Payment Integration Options

### **Stripe (Recommended)**

```typescript
// Install: npm install @stripe/react-stripe-js stripe

import { loadStripe } from '@stripe/stripe-js';
import { Elements, CardElement, useStripe, useElements } from '@stripe/react-stripe-js';

const stripePromise = loadStripe('your-stripe-public-key');

// In AddFundsModal:
const handleAddFunds = async (amount: number) => {
  const stripe = useStripe();
  const elements = useElements();
  
  const { token } = await stripe.createToken(elements.getElement(CardElement));
  
  // Call backend to process payment
  const response = await fetch('/api/process-payment', {
    method: 'POST',
    body: JSON.stringify({ token: token.id, amount }),
  });
  
  if (response.ok) {
    // Update wallet balance
    await addFunds(amount, paymentMethod);
  }
};
```

### **Mobile Money (For Zambian Users)**

```typescript
// For MTN/Airtel integration in Zambia
const processMMPayment = async (amount: number, provider: 'mtn' | 'airtel') => {
  const response = await fetch('/api/mobile-money/initiate', {
    method: 'POST',
    body: JSON.stringify({
      amount,
      phone: userPhone,
      provider,
      wallet_id: wallet.id,
    }),
  });
  
  // Returns USSD code or payment link
  return response.json();
};
```

---

## 📊 Business Metrics to Track

Add these to your analytics dashboard:

```typescript
// Loyalty Metrics
const loyaltyMetrics = {
  avgPointsPerUser: 0,
  redemptionRate: 0, // % of earned points actually redeemed
  referralConversions: 0,
  tierDistribution: {
    bronze: 0,
    silver: 0,
    gold: 0,
    platinum: 0,
  },
};

// Wallet Metrics
const walletMetrics = {
  totalWalletsCreated: 0,
  avgBalance: 0,
  monthlyTransactionVolume: 0,
  uniquePaymentMethods: 0,
};
```

---

## 🧪 Testing Checklist

- [ ] Create account → Loyalty and wallet auto-created
- [ ] Navigate to `/account` → Dashboard loads
- [ ] View wallet balance → Shows $0 (new user)
- [ ] View loyalty points → Shows 0 (new user)
- [ ] Make test booking → Points earned (if integrated)
- [ ] Redeem reward → Points deducted, reward added
- [ ] Add funds → Transaction recorded (mock for now)
- [ ] Sign out / Sign in → Data persists

---

## 🚀 Production Checklist

Before going live:

- [ ] Set up Stripe or payment processor account
- [ ] Create backend API endpoints for payment processing
- [ ] Set up email templates for notifications
- [ ] Enable Supabase backups
- [ ] Set up monitoring/alerts for wallet transactions
- [ ] Create admin dashboard for managing rewards catalog
- [ ] Test with real payments (small amounts)
- [ ] Set up fraud detection

---

## 📞 Support & Troubleshooting

**Q: Loyalty tables created but account page shows error?**
A: Make sure to run the `useInitializeLoyaltyWallet` hook to create the initial records.

**Q: Payment integration not working?**
A: Implement `/api/process-payment` backend endpoint to handle Stripe/Paypal tokens.

**Q: RLS policies denying access?**
A: Ensure `auth.uid()` matches the `user_id` in your tables. Check Supabase authentication logs.

**Q: Points not updating after booking?**
A: Add trigger to booking table to call `insert_loyalty_transaction` when booking status = 'completed'.

---

## 📂 File Structure Summary

```
src/
├── pages/
│   └── AccountDashboard.tsx ✅ NEW
├── components/
│   ├── LoyaltyProgram.tsx ✅ (already created)
│   ├── DigitalWallet.tsx ✅ (already created)
│   └── LandingPage.tsx ✅ UPDATED (added Account button)
├── hooks/
│   ├── useLoyaltyData.ts 🔧 TODO
│   ├── useWalletData.ts 🔧 TODO
│   └── useInitializeLoyaltyWallet.ts 🔧 TODO
├── App.tsx ✅ UPDATED (added /account route)
└── ...

supabase/
└── migrations/
    └── loyalty_wallet_schema.sql ✅ NEW
```

---

## 🎯 Quick Win: Test with Demo Data

Don't want to integrate payment yet? Use this for testing:

```sql
-- Add test points to a user (run in SQL editor)
UPDATE public.user_loyalty
SET current_points = 2450
WHERE user_id = 'YOUR-USER-ID';

-- Add test wallet balance
UPDATE public.wallets
SET balance = 2850.50
WHERE user_id = 'YOUR-USER-ID';

-- Add test transaction
INSERT INTO public.wallet_transactions
(wallet_id, type, amount, description, status)
VALUES
((SELECT id FROM public.wallets WHERE user_id = 'YOUR-USER-ID'), 'credit', 100.00, 'Welcome bonus', 'completed');
```

---

## ✨ What You Can Do Next

1. **Run Steps 1-4 above** (estimated 30 minutes)
2. **Test the account page** with demo data
3. **Integrate payment processor** (Stripe recommended)
4. **Set up email notifications**
5. **Track business metrics** via views
6. **Launch to users!**

Need help? Check `LOYALTY_WALLET_GUIDE.md` for detailed integration examples. 🚀
