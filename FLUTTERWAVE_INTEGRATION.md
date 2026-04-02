# Flutterwave Payment Integration Guide

## Overview

BusNStay integrates with **Flutterwave**, a leading African payment processor, to handle digital wallet top-ups for Zambian users. This guide covers setup, usage, and supported payment methods.

## Supported Payment Methods

### 1. **Mobile Money** (Recommended for Zambia)
- **MTN Mobile Money** (1.5% fee)
- **Airtel Money Zambia** (1.5% fee)
- **Vodafone Cash Zambia** (2.0% fee)

Users simply enter their phone number to top up their wallet instantly.

### 2. **Card Payments**
- International credit/debit cards (Visa, Mastercard, etc.)
- Standard card processing fees (1.95%)
- 3D Secure support for additional security

### 3. **Bank Transfers**
- Direct Zambian bank transfers
- Lower fees (0.5%)
- Typically pending until confirmed by the bank

## Setup Instructions

### Step 1: Create a Flutterwave Account

1. Visit [https://flutterwave.com/us](https://flutterwave.com/us)
2. Sign up as a business (Zambia region)
3. Verify your account with business documents
4. Complete KYC verification

### Step 2: Get Your API Keys

1. Log in to [Flutterwave Dashboard](https://dashboard.flutterwave.com)
2. Navigate to **Settings > API Keys**
3. Copy your **Public Key** (test and live versions available)
4. Keep your **Secret Key** safe (only used on backend)

### Step 3: Configure Environment Variables

Update your `.env` file:

```env
# Staging (Testing)
VITE_FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_TEST_xxxxxxxxxxxxxxxx
VITE_FLUTTERWAVE_ENVIRONMENT=staging

# Production
VITE_FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_LIVE_xxxxxxxxxxxxxxxx
VITE_FLUTTERWAVE_ENVIRONMENT=production
```

### Step 4: Test with Demo Mode

The app includes a **Demo Mode** that simulates Flutterwave payments without requiring real API credentials:

1. Click "🎮 Try Demo Mode" on the login page
2. Navigate to the Wallet tab
3. Click "Add Funds"
4. Select a payment method (Mobile Money, Cards, etc.)
5. Enter test amounts
6. The demo will simulate the payment after 2 seconds

> ✅ Demo mode works without Flutterwave credentials!

## Usage in Your App

### Add Mobile Money Funds

```typescript
import { useAddFundsWithFlutterwaveDemo } from '@/hooks/useWithDemo';

export function AddFundsComponent() {
  const addFundsMutation = useAddFundsWithFlutterwaveDemo();

  const handleAddFunds = async () => {
    try {
      const result = await addFundsMutation.mutateAsync({
        amount: 100,
        phoneNumber: '+260971234567',
        paymentMethod: 'mobile_money',
        mobileProvider: 'mtn', // 'mtn' | 'airtel' | 'vodafone'
      });

      console.log('Payment successful:', result);
    } catch (error) {
      console.error('Payment failed:', error);
    }
  };

  return (
    <button onClick={handleAddFunds}>
      {addFundsMutation.isLoading ? 'Processing...' : 'Add Funds via MTN'}
    </button>
  );
}
```

### Get Available Payment Providers

```typescript
import { useMobileMoneyProvidersDemo } from '@/hooks/useWithDemo';

export function PaymentMethodSelector() {
  const providersQuery = useMobileMoneyProvidersDemo();

  if (providersQuery.isLoading) return <div>Loading providers...</div>;

  return (
    <select>
      {providersQuery.data?.map((provider) => (
        <option key={provider.id} value={provider.id}>
          {provider.name} ({provider.fees}% fee)
        </option>
      ))}
    </select>
  );
}
```

### Calculate Payment Fees

```typescript
import { useCalculatePaymentFeesDemo } from '@/hooks/useWithDemo';

export function FeeCalculator() {
  const amount = 100; // ZMW
  const feesQuery = useCalculatePaymentFeesDemo(amount, 'mobile_money', 'mtn');

  if (feesQuery.isLoading) return null;

  return (
    <div>
      <p>Amount: {feesQuery.data?.subtotal} ZMW</p>
      <p>Fees: {feesQuery.data?.fees} ZMW</p>
      <p>Total: {feesQuery.data?.total} ZMW</p>
    </div>
  );
}
```

## Payment Flow Diagram

```
User → Select Payment Method
       ↓
     Mobile Money: Enter Phone Number
     Cards: Enter Card Details
     Bank Transfer: Select Bank Account
       ↓
   Initiate Payment via Flutterwave API
       ↓
   Flutterwave Processes Payment
       ↓
   Verify Transaction Status
       ↓
   Update Wallet Balance (if successful)
       ↓
   Return to Dashboard with Updated Balance
```

## Supported Currencies

- **ZMW** (Zambian Kwacha) - Default for Zambian users
- **USD** (US Dollars) - For international payments
- **Other African currencies** - Available through Flutterwave

## Fee Structure

| Payment Method | Fee     | Min Amount | Max Amount |
| -------------- | ------- | ---------- | ---------- |
| MTN Mobile     | 1.5%    | 5 ZMW      | 50,000 ZMW |
| Airtel Money   | 1.5%    | 5 ZMW      | 50,000 ZMW |
| Vodafone Cash  | 2.0%    | 5 ZMW      | 50,000 ZMW |
| Card (Visa)    | 1.95%   | 10 ZMW     | 100,000 ZMW |
| Bank Transfer  | 0.5%    | 100 ZMW    | No limit    |

## Testing

### Test Credentials (Staging Environment)

**Mobile Money:**
- Provider: MTN/Airtel/Vodafone
- Phone: Any format (simulation uses random)
- Amount: Any positive number

**Cards:**
- Test Card: 4242 4242 4242 4242
- Expiry: Any future date (MM/YY)
- CVV: 123 (or any 3 digits)

### Demo Mode (No API Keys Needed)

The app includes a complete demo mode that:
- ✅ Simulates all payment methods
- ✅ Shows realistic loading delays
- ✅ Updates wallet balance locally
- ✅ No API credentials required
- ✅ No real charges

## Production Deployment

### Before Going Live:

1. **Get Production Keys**
   - Switch to LIVE keys in Flutterwave Dashboard
   - Update `.env` with FLWPUBK_LIVE_* key
   - Set `VITE_FLUTTERWAVE_ENVIRONMENT=production`

2. **Enable SSL/HTTPS**
   - Flutterwave requires secure connections
   - Ensure your domain has valid SSL certificate

3. **Complete Compliance**
   - Submit KYC (Know Your Customer) verification
   - Provide business documentation
   - Accept Payment Processor Agreement

4. **Test Live** (Small Amounts First)
   - Process 1-2 small transactions
   - Verify funds appear in your Flutterwave account
   - Confirm customer receives confirmations

5. **Monitor & Optimize**
   - Track payment success rates
   - Monitor for fraud patterns
   - Analyze fee impact on margins

## Troubleshooting

### "Flutterwave configuration missing"
- **Cause**: `VITE_FLUTTERWAVE_PUBLIC_KEY` not set in `.env`
- **Solution**: Add your public key from Flutterwave Dashboard

### Payment stuck on "pending"
- **Cause**: Bank transfer; some take 24-48 hours
- **Solution**: Check Flutterwave Dashboard for transaction status
- **User Action**: Check their bank account for received funds

### High Decline Rate on Cards
- **Cause**: 3D Secure not configured
- **Solution**: Contact Flutterwave support for 3D Secure setup

### Mobile Money Timeout
- **Cause**: User's mobile network or carrier issue
- **Solution**: Suggest retrying with different provider (Airtel if MTN fails)

## API Reference

### Payment Methods

```typescript
type PaymentMethod = 'mobile_money' | 'card' | 'bank_transfer';
```

### Mobile Providers

```typescript
type MobileProvider = 'mtn' | 'airtel' | 'vodafone';
```

### Transaction Status

```typescript
type TransactionStatus = 'success' | 'failed' | 'pending' | 'cancelled';
```

## Security Best Practices

1. **Never commit API keys** to version control
   - Use `.env` files (added to `.gitignore`)
   - Use environment variables in production

2. **Validate amounts** on both client and server
   - Check min/max limits
   - Verify user has sufficient balance before checkout

3. **Store payment tokens securely**
   - Encrypt in database
   - Never log full card numbers
   - Use TokenVault for PCI compliance

4. **Handle timeouts gracefully**
   - Implement retry logic
   - Show clear error messages
   - Let users check transaction status

## Support & Resources

- **Flutterwave Docs**: [https://developer.flutterwave.com/](https://developer.flutterwave.com/)
- **Flutterwave Support**: [https://support.flutterwave.com/](https://support.flutterwave.com/)
- **BusNStay Issues**: Use GitHub issues for bugs and feature requests
- **Payment Status**: Always check Flutterwave Dashboard for real transaction status

## Next Steps

1. ✅ Sign up for Flutterwave (done in this guide)
2. ✅ Get API keys (done in this guide)
3. ✅ Configure `.env` (done in this guide)
4. ⏭️ Test with Demo Mode
5. ⏭️ Test with real transactions (staging environment)
6. ⏭️ Go live with production keys
7. ⏭️ Monitor transaction success rates
8. ⏭️ Optimize based on user feedback

---

**Last Updated**: February 10, 2026
**Version**: 1.0.0
**Status**: Production Ready
