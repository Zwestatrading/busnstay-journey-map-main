import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from './useAuth';
import { supabase } from '@/lib/supabase';
import {
  flutterwavePaymentService,
  ZAMBIA_MOBILE_MONEY_PROVIDERS,
  type FlutterwavePaymentRequest,
} from '@/utils/flutterwavePaymentService';

export interface Wallet {
  id: string;
  userId: string;
  balance: number;
  currency: string;
  walletStatus: 'active' | 'suspended' | 'closed';
  createdAt: string;
  updatedAt: string;
  lastActivity: string;
  metadata?: Record<string, unknown>;
}

export interface WalletTransaction {
  id: string;
  walletId: string;
  type: 'debit' | 'credit' | 'refund' | 'transfer' | 'withdrawal' | 'deposit';
  amount: number;
  description: string;
  status: 'pending' | 'completed' | 'failed' | 'cancelled';
  relatedBookingId?: string;
  relatedOrderId?: string;
  transactionReference?: string;
  failureReason?: string;
  createdAt: string;
  completedAt?: string;
  metadata?: Record<string, unknown>;
  timestamp?: Date; // For compatibility with UI components
}

export interface PaymentMethod {
  id: string;
  userId: string;
  type: 'card' | 'mobile' | 'bank' | 'wallet';
  name: string;
  provider?: string;
  lastDigits?: string;
  expiryDate?: string;
  isDefault: boolean;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

/**
 * Hook to fetch current user's wallet
 */
export const useWalletData = () => {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['wallet', user?.id],
    queryFn: async () => {
      if (!user?.id) throw new Error('User not authenticated');

      const result = await supabase
        .from('wallets')
        .select('*')
        .eq('user_id', user.id)
        .single() as { data: { id: string; user_id: string; balance: string; currency: string; wallet_status: string; created_at: string; updated_at: string; last_activity: string; metadata?: unknown } | null; error: { code: string } | null };
      
      let data = result.data;
      const error = result.error;

      if (error) {
        if (error.code === 'PGRST116') {
          // No wallet found - create one
          const { data: newWallet, error: createError } = await supabase
            .from('wallets')
            .insert({ user_id: user.id, balance: 0, currency: 'ZMW' })
            .select()
            .single() as { data: unknown; error: unknown };

          if (createError) throw createError;
          data = newWallet as { id: string; user_id: string; balance: string; currency: string; wallet_status: string; created_at: string; updated_at: string; last_activity: string; metadata?: unknown };
        } else {
          throw error;
        }
      }

      return {
        id: data!.id,
        userId: data!.user_id,
        balance: parseFloat(data!.balance as string),
        currency: data!.currency,
        walletStatus: data!.wallet_status as 'active' | 'suspended' | 'closed',
        createdAt: data!.created_at,
        updatedAt: data!.updated_at,
        lastActivity: data!.last_activity,
        metadata: data!.metadata
      } as Wallet;
    },
    enabled: !!user?.id,
    staleTime: 5 * 60 * 1000 // 5 minutes
  });
};

/**
 * Hook to fetch wallet transactions
 */
export const useWalletTransactions = (limit = 20) => {
  const { user } = useAuth();
  const walletQuery = useWalletData();

  return useQuery({
    queryKey: ['walletTransactions', walletQuery.data?.id, limit],
    queryFn: async () => {
      if (!walletQuery.data?.id) throw new Error('Wallet not found');

      const { data, error } = await supabase
        .from('wallet_transactions')
        .select('*')
        .eq('wallet_id', walletQuery.data.id)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;

      return data.map(transaction => ({
        id: transaction.id,
        walletId: transaction.wallet_id,
        type: transaction.type,
        amount: parseFloat(transaction.amount),
        description: transaction.description,
        status: transaction.status,
        relatedBookingId: transaction.related_booking_id,
        relatedOrderId: transaction.related_order_id,
        transactionReference: transaction.transaction_reference,
        failureReason: transaction.failure_reason,
        createdAt: transaction.created_at,
        completedAt: transaction.completed_at,
        metadata: transaction.metadata
      })) as WalletTransaction[];
    },
    enabled: !!walletQuery.data?.id,
    staleTime: 3 * 60 * 1000 // 3 minutes
  });
};

/**
 * Hook to fetch payment methods
 */
export const usePaymentMethods = () => {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['paymentMethods', user?.id],
    queryFn: async () => {
      if (!user?.id) throw new Error('User not authenticated');

      const { data, error } = await supabase
        .from('payment_methods')
        .select('*')
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('is_default', { ascending: false });

      if (error) throw error;

      return data.map(method => ({
        id: method.id,
        userId: method.user_id,
        type: method.type,
        name: method.name,
        provider: method.provider,
        lastDigits: method.last_digits,
        expiryDate: method.expiry_date,
        isDefault: method.is_default,
        isActive: method.is_active,
        createdAt: method.created_at,
        updatedAt: method.updated_at
      })) as PaymentMethod[];
    },
    enabled: !!user?.id,
    staleTime: 10 * 60 * 1000 // 10 minutes
  });
};

/**
 * Hook to add funds to wallet
 */
export const useAddFunds = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const walletQuery = useWalletData();

  return useMutation({
    mutationFn: async ({
      amount,
      paymentMethodId
    }: {
      amount: number;
      paymentMethodId: string;
    }) => {
      if (!user?.id) throw new Error('User not authenticated');
      if (!walletQuery.data?.id) throw new Error('Wallet not found');
      if (amount <= 0) throw new Error('Amount must be greater than 0');

      // Create wallet deposit record
      const { data: deposit, error: depositError } = await supabase
        .from('wallet_deposits')
        .insert({
          wallet_id: walletQuery.data.id,
          amount,
          payment_method_id: paymentMethodId,
          status: 'pending'
        })
        .select()
        .single();

      if (depositError) throw depositError;

      // In production, this would call a payment processor (Stripe, PayPal, etc.)
      // For now, we'll simulate a successful payment
      const { data: completedDeposit, error: updateError } = await supabase
        .from('wallet_deposits')
        .update({
          status: 'completed',
          completed_at: new Date().toISOString()
        })
        .eq('id', deposit.id)
        .select()
        .single();

      if (updateError) throw updateError;

      // Create wallet transaction record
      const { data: transaction, error: transactionError } = await supabase
        .from('wallet_transactions')
        .insert({
          wallet_id: walletQuery.data.id,
          type: 'credit',
          amount,
          description: `Added funds via ${paymentMethodId}`,
          status: 'completed'
        })
        .select()
        .single();

      if (transactionError) throw transactionError;

      return { deposit: completedDeposit, transaction };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet', user?.id] });
      queryClient.invalidateQueries({
        queryKey: ['walletTransactions', walletQuery.data?.id]
      });
    }
  });
};

/**
 * Hook to transfer funds between wallets
 */
export const useTransferFunds = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const walletQuery = useWalletData();

  return useMutation({
    mutationFn: async ({
      recipientEmail,
      amount,
      description
    }: {
      recipientEmail: string;
      amount: number;
      description?: string;
    }) => {
      if (!user?.id) throw new Error('User not authenticated');
      if (!walletQuery.data?.id) throw new Error('Wallet not found');
      if (amount <= 0) throw new Error('Amount must be greater than 0');
      if (amount > walletQuery.data.balance) throw new Error('Insufficient balance');

      // Get recipient's user ID and wallet
      const { data: recipientProfile, error: profileError } = await supabase
        .from('user_profiles')
        .select('user_id')
        .eq('email', recipientEmail)
        .single();

      if (profileError) throw new Error('Recipient not found');

      const { data: recipientWallet, error: walletError } = await supabase
        .from('wallets')
        .select('id')
        .eq('user_id', recipientProfile.user_id)
        .single();

      if (walletError) throw new Error('Recipient wallet not found');

      // Create transfer record
      const { data: transfer, error: transferError } = await supabase
        .from('wallet_transfers')
        .insert({
          from_wallet_id: walletQuery.data.id,
          to_wallet_id: recipientWallet.id,
          amount,
          description: description || 'Wallet transfer'
        })
        .select()
        .single();

      if (transferError) throw transferError;

      // Create debit transaction for sender
      await supabase.from('wallet_transactions').insert({
        wallet_id: walletQuery.data.id,
        type: 'transfer',
        amount,
        description: `Transferred to ${recipientEmail}`,
        status: 'completed'
      });

      // Create credit transaction for recipient
      await supabase.from('wallet_transactions').insert({
        wallet_id: recipientWallet.id,
        type: 'transfer',
        amount,
        description: `Received from ${user.email}`,
        status: 'completed'
      });

      return transfer;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet', user?.id] });
      queryClient.invalidateQueries({
        queryKey: ['walletTransactions', walletQuery.data?.id]
      });
    }
  });
};

/**
 * Hook to withdraw funds from wallet
 */
export const useWithdrawFunds = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const walletQuery = useWalletData();

  return useMutation({
    mutationFn: async ({
      amount,
      paymentMethodId
    }: {
      amount: number;
      paymentMethodId: string;
    }) => {
      if (!user?.id) throw new Error('User not authenticated');
      if (!walletQuery.data?.id) throw new Error('Wallet not found');
      if (amount <= 0) throw new Error('Amount must be greater than 0');
      if (amount > walletQuery.data.balance) throw new Error('Insufficient balance');

      // Create wallet transaction record
      const { data: transaction, error: transactionError } = await supabase
        .from('wallet_transactions')
        .insert({
          wallet_id: walletQuery.data.id,
          type: 'withdrawal',
          amount,
          description: `Withdrawn to payment method`,
          payment_method_id: paymentMethodId,
          status: 'completed'
        })
        .select()
        .single();

      if (transactionError) throw transactionError;

      return transaction;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet', user?.id] });
      queryClient.invalidateQueries({
        queryKey: ['walletTransactions', walletQuery.data?.id]
      });
    }
  });
};

/**
 * Hook to add funds via Flutterwave (Mobile Money, Card, or Bank Transfer)
 * Supports MTN Mobile Money, Airtel Money, International Cards, Bank Transfers
 */
export const useAddFundsWithFlutterwave = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();
  const walletQuery = useWalletData();

  return useMutation({
    mutationFn: async ({
      amount,
      phoneNumber,
      paymentMethod,
      mobileProvider,
    }: {
      amount: number;
      phoneNumber: string;
      paymentMethod: 'mobile_money' | 'card' | 'bank_transfer';
      mobileProvider?: 'mtn' | 'airtel' | 'vodafone';
    }) => {
      if (!user?.id) throw new Error('User not authenticated');
      if (!user?.email) throw new Error('User email required');
      if (!walletQuery.data?.id) throw new Error('Wallet not found');
      if (amount <= 0) throw new Error('Amount must be greater than 0');

      // Get Flutterwave config from environment
      const flutterwavePublicKey = import.meta.env.VITE_FLUTTERWAVE_PUBLIC_KEY;
      if (!flutterwavePublicKey) {
        throw new Error('Flutterwave configuration missing');
      }

      // Generate transaction reference
      const reference = flutterwavePaymentService.generateTransactionReference();

      // Prepare payment request
      const paymentRequest: FlutterwavePaymentRequest = {
        amount,
        email: user.email,
        phoneNumber,
        fullName: user.user_metadata?.full_name || 'BusNStay User',
        paymentMethod,
        mobileProvider,
        currency: 'ZMW', // Zambian Kwacha
        description: `BusNStay Wallet Top-up`,
        reference,
      };

      // Process payment via Flutterwave
      const paymentResponse = await flutterwavePaymentService.processMobileMoneyPayment(
        paymentRequest,
        {
          publicKey: flutterwavePublicKey,
          environment: import.meta.env.MODE === 'production' ? 'production' : 'staging',
        }
      );

      if (paymentResponse.status !== 'success') {
        throw new Error(`Payment failed: ${paymentResponse.message}`);
      }

      // Create payment method record if not exists
      const provider = ZAMBIA_MOBILE_MONEY_PROVIDERS.find((p) => p.id === mobileProvider);
      const { data: pm, error: pmError } = await supabase
        .from('payment_methods')
        .insert({
          user_id: user.id,
          type: 'mobile',
          name: provider?.name || 'Mobile Money',
          provider: mobileProvider,
          payment_token: reference, // Store transaction reference
          last_digits: phoneNumber.slice(-4),
          is_default: false,
          is_active: true,
        })
        .select()
        .single();

      if (pmError) throw pmError;

      // Create wallet deposit record
      const { data: deposit, error: depositError } = await supabase
        .from('wallet_deposits')
        .insert({
          wallet_id: walletQuery.data.id,
          amount,
          payment_method_id: pm?.id,
          status: 'completed',
          completed_at: new Date().toISOString(),
          processor_response: paymentResponse,
        })
        .select()
        .single();

      if (depositError) throw depositError;

      // Create wallet transaction record
      const { data: transaction, error: transactionError } = await supabase
        .from('wallet_transactions')
        .insert({
          wallet_id: walletQuery.data.id,
          type: 'credit',
          amount,
          description: `Added funds via ${provider?.name || mobileProvider}`,
          status: 'completed',
          payment_method_id: pm?.id,
          transaction_reference: reference,
        })
        .select()
        .single();

      if (transactionError) throw transactionError;

      return { deposit, transaction, paymentResponse };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet', user?.id] });
      queryClient.invalidateQueries({
        queryKey: ['walletTransactions', walletQuery.data?.id]
      });
    },
  });
};

/**
 * Hook to get available mobile money providers for the current region (Zambia)
 */
export const useMobileMoneyProviders = () => {
  return useQuery({
    queryKey: ['mobileMoneyProviders', 'zambia'],
    queryFn: async () => {
      return ZAMBIA_MOBILE_MONEY_PROVIDERS;
    },
    staleTime: 1000 * 60 * 60, // 1 hour
  });
};

/**
 * Hook to calculate payment total with fees
 */
export const useCalculatePaymentFees = (
  amount: number,
  paymentMethod: 'mobile_money' | 'card' | 'bank_transfer' = 'mobile_money',
  mobileProvider?: string
) => {
  return useQuery({
    queryKey: ['paymentFees', amount, paymentMethod, mobileProvider],
    queryFn: async () => {
      return flutterwavePaymentService.calculateTotalWithFees(
        amount,
        paymentMethod,
        mobileProvider
      );
    },
    staleTime: 1000 * 60 * 5, // 5 minutes
    enabled: amount > 0,
  });
};
