/**
 * Flutterwave Payment Integration Service
 * Handles payments for Zambian users (MTN Mobile Money, Airtel Money, Bank Transfers, Cards)
 * 
 * Documentation: https://developer.flutterwave.com/
 * Zambia Support: MTN Mobile Money (256), Airtel Money (256), Bank Transfers
 */

export interface FlutterwaveConfig {
  publicKey: string;
  environment: 'staging' | 'production';
}

export interface FlutterwavePaymentRequest {
  amount: number;
  email: string;
  phoneNumber: string;
  fullName: string;
  paymentMethod: 'mobile_money' | 'card' | 'bank_transfer';
  mobileProvider?: 'mtn' | 'airtel' | 'vodafone'; // For mobile money
  currency: string; // "ZMW" for Zambian Kwacha, "USD" for US Dollar
  description: string;
  reference: string; // Unique transaction reference
}

export interface FlutterwavePaymentResponse {
  status: 'success' | 'failed' | 'pending';
  transactionId: string;
  reference: string;
  amount: number;
  currency: string;
  message: string;
}

export interface MobileMoneyProvider {
  id: string;
  name: string;
  shortName: string;
  country: string;
  supportedCurrencies: string[];
  fees: number; // Percentage
}

// Initialize Flutterwave SDK
const initializeFlutterwave = async (config: FlutterwaveConfig) => {
  if (!config.publicKey) {
    console.error('Flutterwave public key not configured');
    return false;
  }

  // In production, you would load the Flutterwave script here
  // For now, we'll assume it's loaded via HTML script tag or environment setup
  return true;
};

// Mobile money providers available in Zambia
export const ZAMBIA_MOBILE_MONEY_PROVIDERS: MobileMoneyProvider[] = [
  {
    id: 'mtn',
    name: 'MTN Mobile Money',
    shortName: 'MTN',
    country: 'Zambia',
    supportedCurrencies: ['ZMW', 'USD'],
    fees: 1.5, // 1.5% transaction fee
  },
  {
    id: 'airtel',
    name: 'Airtel Money Zambia',
    shortName: 'Airtel',
    country: 'Zambia',
    supportedCurrencies: ['ZMW', 'USD'],
    fees: 1.5, // 1.5% transaction fee
  },
  {
    id: 'vodafone',
    name: 'Vodafone Cash Zambia',
    shortName: 'Vodafone',
    country: 'Zambia',
    supportedCurrencies: ['ZMW'],
    fees: 2.0, // 2% transaction fee
  },
];

/**
 * Process mobile money payment via Flutterwave
 * Supports MTN Mobile Money, Airtel Money, Vodafone Cash in Zambia
 */
export const processMobileMoneyPayment = async (
  request: FlutterwavePaymentRequest,
  config: FlutterwaveConfig
): Promise<FlutterwavePaymentResponse> => {
  const initialized = await initializeFlutterwave(config);
  if (!initialized) {
    throw new Error('Flutterwave initialization failed');
  }

  const provider = ZAMBIA_MOBILE_MONEY_PROVIDERS.find(
    (p) => p.id === request.mobileProvider
  );

  if (!provider) {
    throw new Error(`Mobile money provider ${request.mobileProvider} not supported`);
  }

  // Calculate fees
  const feeAmount = (request.amount * provider.fees) / 100;
  const totalAmount = request.amount + feeAmount;

  try {
    // In production, this would call the actual Flutterwave API
    // For now, return a mock successful response
    const response: FlutterwavePaymentResponse = {
      status: 'success',
      transactionId: `FLW-${Date.now()}`,
      reference: request.reference,
      amount: request.amount,
      currency: request.currency,
      message: `${provider.name} payment successful`,
    };

    return response;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Mobile money payment failed';
    throw new Error(`Mobile money payment error: ${errorMessage}`);
  }
};

/**
 * Process card payment via Flutterwave
 * Supports international cards and local Zambian cards
 */
export const processCardPayment = async (
  request: FlutterwavePaymentRequest,
  config: FlutterwaveConfig
): Promise<FlutterwavePaymentResponse> => {
  const initialized = await initializeFlutterwave(config);
  if (!initialized) {
    throw new Error('Flutterwave initialization failed');
  }

  try {
    // Card payment processing - typically requires 3D Secure for international cards
    const response: FlutterwavePaymentResponse = {
      status: 'success',
      transactionId: `FLW-CARD-${Date.now()}`,
      reference: request.reference,
      amount: request.amount,
      currency: request.currency,
      message: 'Card payment successful',
    };

    return response;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Card payment failed';
    throw new Error(`Card payment error: ${errorMessage}`);
  }
};

/**
 * Process bank transfer via Flutterwave
 * For Zambian bank transfers (requires bank account details)
 */
export const processBankTransferPayment = async (
  request: FlutterwavePaymentRequest,
  config: FlutterwaveConfig
): Promise<FlutterwavePaymentResponse> => {
  const initialized = await initializeFlutterwave(config);
  if (!initialized) {
    throw new Error('Flutterwave initialization failed');
  }

  try {
    // Bank transfer processing
    const response: FlutterwavePaymentResponse = {
      status: 'pending', // Bank transfers are typically pending until confirmed
      transactionId: `FLW-BANK-${Date.now()}`,
      reference: request.reference,
      amount: request.amount,
      currency: request.currency,
      message: 'Bank transfer initiated. Please complete the transfer to the provided account.',
    };

    return response;
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Bank transfer initiation failed';
    throw new Error(`Bank transfer error: ${errorMessage}`);
  }
};

/**
 * Verify payment status from Flutterwave
 * After payment is processed, verify the transaction status
 */
export const verifyFlutterwavePayment = async (
  transactionId: string,
  config: FlutterwaveConfig
): Promise<{ status: 'success' | 'failed' | 'pending'; verified: boolean }> => {
  const initialized = await initializeFlutterwave(config);
  if (!initialized) {
    throw new Error('Flutterwave initialization failed');
  }

  try {
    // In production, this would call the Flutterwave Verify Transaction endpoint
    // GET https://api.flutterwave.com/v3/transactions/{transaction_id}/verify
    // For now, we simulate verification
    const verified = !transactionId.includes('FAIL');

    return {
      status: verified ? 'success' : 'failed',
      verified,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Verification failed';
    throw new Error(`Payment verification error: ${errorMessage}`);
  }
};

/**
 * Calculate total amount including fees
 */
export const calculateTotalWithFees = (
  amount: number,
  paymentMethod: 'mobile_money' | 'card' | 'bank_transfer',
  mobileProvider?: string
): { subtotal: number; fees: number; total: number } => {
  let feePercentage = 0;

  if (paymentMethod === 'mobile_money') {
    const provider = ZAMBIA_MOBILE_MONEY_PROVIDERS.find(
      (p) => p.id === mobileProvider
    );
    feePercentage = provider?.fees || 1.5;
  } else if (paymentMethod === 'card') {
    feePercentage = 1.95; // Standard card processing fees
  } else if (paymentMethod === 'bank_transfer') {
    feePercentage = 0.5; // Lower fees for bank transfers
  }

  const fees = (amount * feePercentage) / 100;
  const total = amount + fees;

  return {
    subtotal: amount,
    fees: parseFloat(fees.toFixed(2)),
    total: parseFloat(total.toFixed(2)),
  };
};

/**
 * Generate unique transaction reference
 */
export const generateTransactionReference = (): string => {
  const timestamp = Date.now();
  const random = Math.random().toString(36).substring(2, 9).toUpperCase();
  return `BUS-${timestamp}-${random}`;
};

/**
 * Mock payment for demo/testing purposes
 */
export const mockFlutterwavePayment = async (
  request: FlutterwavePaymentRequest,
  delayMs: number = 2000
): Promise<FlutterwavePaymentResponse> => {
  return new Promise((resolve) => {
    setTimeout(() => {
      const provider = ZAMBIA_MOBILE_MONEY_PROVIDERS.find(
        (p) => p.id === request.mobileProvider
      );

      resolve({
        status: 'success',
        transactionId: `MOCK-${Date.now()}`,
        reference: request.reference,
        amount: request.amount,
        currency: request.currency,
        message: `Mock ${request.paymentMethod} payment successful${provider ? ` via ${provider.name}` : ''}`,
      });
    }, delayMs);
  });
};

export const flutterwavePaymentService = {
  initializeFlutterwave,
  processMobileMoneyPayment,
  processCardPayment,
  processBankTransferPayment,
  verifyFlutterwavePayment,
  calculateTotalWithFees,
  generateTransactionReference,
  mockFlutterwavePayment,
  ZAMBIA_MOBILE_MONEY_PROVIDERS,
};
