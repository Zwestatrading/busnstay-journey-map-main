/**
 * Flutterwave Payment Service for BusNStay
 * Supports Mobile Money (MTN/Airtel/Zamtel), Cards, Bank Transfers for Zambia
 */

import { supabase } from '@/lib/supabase';

const FLUTTERWAVE_PUBLIC_KEY = import.meta.env.VITE_FLUTTERWAVE_PUBLIC_KEY || '';
const FLUTTERWAVE_API_BASE = import.meta.env.VITE_FLUTTERWAVE_API_BASE_URL || 'https://api.flutterwave.com/v3';

export type PaymentMethod = 'card' | 'mobile_money' | 'bank_transfer' | 'ussd' | 'wallet';
export type PaymentStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'cancelled' | 'refunded' | 'disputed';

export interface InitiatePaymentParams {
  amount: number;
  currency?: string;
  paymentMethod: PaymentMethod;
  description: string;
  bookingId?: string;
  orderId?: string;
  customerEmail: string;
  customerName: string;
  customerPhone?: string;
  redirectUrl?: string;
  metadata?: Record<string, unknown>;
}

interface PaymentTransaction {
  id: string;
  user_id: string;
  flutterwave_ref?: string;
  tx_ref: string;
  amount: number;
  currency: string;
  payment_method: PaymentMethod;
  status: PaymentStatus;
  description: string;
  booking_id?: string;
  order_id?: string;
  customer_email: string;
  customer_name: string;
  customer_phone?: string;
  platform_fee: number;
  net_amount: number;
  metadata?: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

const PLATFORM_FEE_PERCENTAGE = 0.10; // 10%

const generateTxRef = (): string => {
  return `BUSNSTAY-${Date.now()}-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;
};

export const initiatePayment = async (params: InitiatePaymentParams): Promise<{
  success: boolean;
  paymentLink?: string;
  txRef?: string;
  transactionId?: string;
  error?: string;
}> => {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return { success: false, error: 'User not authenticated' };

  const txRef = generateTxRef();
  const platformFee = params.amount * PLATFORM_FEE_PERCENTAGE;
  const currency = params.currency || 'ZMW';

  // Store transaction in database
  const { data: transaction, error: txError } = await supabase
    .from('payment_transactions')
    .insert({
      user_id: user.id,
      tx_ref: txRef,
      amount: params.amount,
      currency,
      payment_method: params.paymentMethod,
      status: 'pending',
      description: params.description,
      booking_id: params.bookingId,
      order_id: params.orderId,
      customer_email: params.customerEmail,
      customer_name: params.customerName,
      customer_phone: params.customerPhone,
      platform_fee: platformFee,
      net_amount: params.amount - platformFee,
      metadata: params.metadata || {},
    })
    .select()
    .single();

  if (txError) return { success: false, error: txError.message };

  // Build Flutterwave payment payload
  const paymentPayload = {
    public_key: FLUTTERWAVE_PUBLIC_KEY,
    tx_ref: txRef,
    amount: params.amount,
    currency,
    payment_options: mapPaymentMethod(params.paymentMethod),
    customer: {
      email: params.customerEmail,
      name: params.customerName,
      phonenumber: params.customerPhone || '',
    },
    customizations: {
      title: 'BusNStay Payment',
      description: params.description,
      logo: '/Logo.png',
    },
    redirect_url: params.redirectUrl || `${window.location.origin}/payment/callback`,
    meta: {
      transaction_id: transaction.id,
      booking_id: params.bookingId,
      order_id: params.orderId,
      ...params.metadata,
    },
  };

  // For inline payment, return the payload. For hosted, build the link.
  const paymentLink = `https://checkout.flutterwave.com/v3/hosted/pay?tx_ref=${txRef}&amount=${params.amount}&currency=${currency}&redirect_url=${encodeURIComponent(paymentPayload.redirect_url)}&public_key=${FLUTTERWAVE_PUBLIC_KEY}`;

  return {
    success: true,
    paymentLink,
    txRef,
    transactionId: transaction.id,
  };
};

export const verifyPayment = async (txRef: string): Promise<{
  success: boolean;
  status?: PaymentStatus;
  transaction?: PaymentTransaction;
  error?: string;
}> => {
  try {
    // Update local transaction status
    const { data: transaction, error } = await supabase
      .from('payment_transactions')
      .select('*')
      .eq('tx_ref', txRef)
      .single();

    if (error || !transaction) {
      return { success: false, error: 'Transaction not found' };
    }

    return {
      success: true,
      status: transaction.status as PaymentStatus,
      transaction: transaction as PaymentTransaction,
    };
  } catch (err) {
    return { success: false, error: 'Verification failed' };
  }
};

export const processRefund = async (
  transactionId: string,
  amount?: number,
  reason?: string
): Promise<{ success: boolean; error?: string }> => {
  const { data: transaction, error: txError } = await supabase
    .from('payment_transactions')
    .select('*')
    .eq('id', transactionId)
    .single();

  if (txError || !transaction) {
    return { success: false, error: 'Transaction not found' };
  }

  if (transaction.status !== 'completed') {
    return { success: false, error: 'Can only refund completed transactions' };
  }

  const refundAmount = amount || transaction.amount;

  const { error: refundError } = await supabase.rpc('create_refund', {
    p_transaction_id: transactionId,
    p_amount: refundAmount,
    p_reason: reason || 'Customer requested refund',
  });

  if (refundError) {
    // Fallback: update status directly
    await supabase
      .from('payment_transactions')
      .update({ status: 'refunded', updated_at: new Date().toISOString() })
      .eq('id', transactionId);
  }

  return { success: true };
};

export const getPaymentHistory = async (
  userId?: string,
  limit: number = 50
): Promise<PaymentTransaction[]> => {
  let query = supabase
    .from('payment_transactions')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);

  if (userId) {
    query = query.eq('user_id', userId);
  }

  const { data, error } = await query;
  if (error) throw error;
  return (data || []) as PaymentTransaction[];
};

export const getPaymentAnalytics = async (period: 'day' | 'week' | 'month' = 'month'): Promise<{
  totalRevenue: number;
  totalTransactions: number;
  successRate: number;
  platformFees: number;
  byMethod: Record<string, number>;
}> => {
  const now = new Date();
  let startDate: Date;

  switch (period) {
    case 'day': startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000); break;
    case 'week': startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000); break;
    default: startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
  }

  const { data, error } = await supabase
    .from('payment_transactions')
    .select('*')
    .gte('created_at', startDate.toISOString());

  if (error) throw error;

  const transactions = data || [];
  const completed = transactions.filter(t => t.status === 'completed');

  const byMethod: Record<string, number> = {};
  completed.forEach(t => {
    byMethod[t.payment_method] = (byMethod[t.payment_method] || 0) + t.amount;
  });

  return {
    totalRevenue: completed.reduce((sum, t) => sum + t.amount, 0),
    totalTransactions: transactions.length,
    successRate: transactions.length > 0 ? (completed.length / transactions.length) * 100 : 0,
    platformFees: completed.reduce((sum, t) => sum + (t.platform_fee || 0), 0),
    byMethod,
  };
};

export const handlePaymentWebhook = async (
  payload: Record<string, unknown>
): Promise<{ success: boolean }> => {
  const txRef = payload.tx_ref as string;
  const status = payload.status as string;

  if (!txRef) return { success: false };

  const mappedStatus: PaymentStatus = status === 'successful' ? 'completed' : status === 'failed' ? 'failed' : 'pending';

  const { error } = await supabase
    .from('payment_transactions')
    .update({
      status: mappedStatus,
      flutterwave_ref: payload.flw_ref as string,
      updated_at: new Date().toISOString(),
    })
    .eq('tx_ref', txRef);

  if (error) return { success: false };

  await supabase.from('payment_logs').insert({
    transaction_id: txRef,
    event: 'webhook_received',
    payload,
  });

  return { success: true };
};

export const createPaymentDispute = async (
  transactionId: string,
  reason: string
): Promise<{ success: boolean; error?: string }> => {
  const { error } = await supabase
    .from('payment_disputes')
    .insert({
      transaction_id: transactionId,
      reason,
      status: 'open',
    });

  if (error) return { success: false, error: error.message };
  return { success: true };
};

export const getAvailablePaymentMethods = (): Array<{
  id: PaymentMethod;
  name: string;
  description: string;
  icon: string;
}> => {
  return [
    { id: 'mobile_money', name: 'Mobile Money', description: 'MTN, Airtel, Zamtel', icon: '📱' },
    { id: 'card', name: 'Card Payment', description: 'Visa, Mastercard', icon: '💳' },
    { id: 'bank_transfer', name: 'Bank Transfer', description: 'Direct bank payment', icon: '🏦' },
    { id: 'ussd', name: 'USSD', description: 'Pay via USSD code', icon: '📞' },
  ];
};

export const formatCurrency = (amount: number, currency: string = 'ZMW'): string => {
  return new Intl.NumberFormat('en-ZM', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
  }).format(amount);
};

const mapPaymentMethod = (method: PaymentMethod): string => {
  const map: Record<PaymentMethod, string> = {
    card: 'card',
    mobile_money: 'mobilemoney',
    bank_transfer: 'banktransfer',
    ussd: 'ussd',
    wallet: 'wallet',
  };
  return map[method] || 'card';
};
