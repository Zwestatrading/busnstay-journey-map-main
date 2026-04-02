import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useLoyaltyData, useLoyaltyTransactions, useLoyaltyRewards } from './useLoyaltyData';
import { useWalletData, useWalletTransactions, usePaymentMethods } from './useWalletData';
import { demoAuthService } from '@/utils/demoAuthService';
import {
  flutterwavePaymentService,
  ZAMBIA_MOBILE_MONEY_PROVIDERS,
} from '@/utils/flutterwavePaymentService';

/**
 * Demo mode hook that wraps loyalty/wallet hooks
 * Returns demo data when demo mode is active, otherwise delegates to real hooks
 */

// Helper to create a mock query result for demo data (no loading state)
const createDemoQueryResult = <T,>(data: T) => ({
  data,
  isLoading: false,
  isFetching: false,
  isError: false,
  error: null,
  refetch: async () => ({ data }),
  isPending: false,
  isSuccess: true,
  status: 'success' as const,
});

export const useLoyaltyDataWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();
  
  // Always call useQuery - never call conditionally
  const realQuery = useQuery({
    queryKey: ['loyalty', 'real'],
    queryFn: async () => {
      return demoAuthService.createTestLoyaltyData();
    },
    staleTime: Infinity,
    enabled: !isDemo  // Disable real query when in demo mode
  });

  // Return demo data immediately when in demo mode
  if (isDemo) {
    return createDemoQueryResult(demoAuthService.createTestLoyaltyData());
  }

  return realQuery;
};

export const useLoyaltyTransactionsWithDemo = (limit = 20) => {
  const isDemo = demoAuthService.isDemoMode();

  const realQuery = useQuery({
    queryKey: ['loyaltyTransactions', 'real', limit],
    queryFn: async () => {
      return demoAuthService.createTestLoyaltyTransactions().slice(0, limit);
    },
    staleTime: Infinity,
    enabled: !isDemo
  });

  if (isDemo) {
    return createDemoQueryResult(demoAuthService.createTestLoyaltyTransactions().slice(0, limit));
  }

  return realQuery;
};

export const useLoyaltyRewardsWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();

  const mockRewards = [
    {
      id: '1',
      name: 'Free Ride',
      description: 'Complimentary bus journey up to $50',
      category: 'upgrade',
      pointsRequired: 1000,
      maxRedemptions: null,
      currentRedemptions: 15,
      popularityScore: 92,
      imageUrl: undefined,
      badgeIcon: '🎫',
      active: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: '2',
      name: 'Hotel Upgrade',
      description: 'Free upgrade to premium room',
      category: 'exclusive',
      pointsRequired: 800,
      maxRedemptions: null,
      currentRedemptions: 8,
      popularityScore: 85,
      imageUrl: undefined,
      badgeIcon: '🏨',
      active: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: '3',
      name: 'Meals Package',
      description: '3 meal vouchers for your journey',
      category: 'gift',
      pointsRequired: 600,
      maxRedemptions: null,
      currentRedemptions: 22,
      popularityScore: 88,
      imageUrl: undefined,
      badgeIcon: '🍽️',
      active: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: '4',
      name: 'Premium Support',
      description: '1 year VIP customer support',
      category: 'exclusive',
      pointsRequired: 1200,
      maxRedemptions: null,
      currentRedemptions: 3,
      popularityScore: 78,
      imageUrl: undefined,
      badgeIcon: '👑',
      active: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: '5',
      name: '$20 Credit',
      description: 'Usable on any booking',
      category: 'discount',
      pointsRequired: 400,
      maxRedemptions: null,
      currentRedemptions: 89,
      popularityScore: 95,
      imageUrl: undefined,
      badgeIcon: '💳',
      active: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
  ];

  const realQuery = useQuery({
    queryKey: ['loyaltyRewards', 'real'],
    queryFn: async () => {
        return mockRewards;
    },
    staleTime: Infinity,
    enabled: !isDemo
  });

  if (isDemo) {
    return createDemoQueryResult(mockRewards);
  }

  return realQuery;
};

export const useWalletDataWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();

  const realQuery = useQuery({
    queryKey: ['wallet', 'real'],
    queryFn: async () => {
      return demoAuthService.createTestWalletData();
    },
    staleTime: Infinity,
    enabled: !isDemo
  });

  if (isDemo) {
    return createDemoQueryResult(demoAuthService.createTestWalletData());
  }

  return realQuery;
};

export const useWalletTransactionsWithDemo = (limit = 20) => {
  const isDemo = demoAuthService.isDemoMode();

  const realQuery = useQuery({
    queryKey: ['walletTransactions', 'real', limit],
    queryFn: async () => {
      return demoAuthService.createTestTransactions().slice(0, limit);
    },
    staleTime: Infinity,
    enabled: !isDemo
  });

  if (isDemo) {
    return createDemoQueryResult(demoAuthService.createTestTransactions().slice(0, limit));
  }

  return realQuery;
};

export const usePaymentMethodsWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();

  const mockPaymentMethods = [
    {
      id: 'pm_1',
      userId: demoAuthService.getDemoUser()?.id || '',
      type: 'card',
      name: 'Visa Card',
      provider: 'stripe',
      lastDigits: '4242',
      expiryDate: '12/26',
      isDefault: true,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: 'pm_2',
      userId: demoAuthService.getDemoUser()?.id || '',
      type: 'mobile',
      name: 'MTN Mobile Money',
      provider: 'mtn',
      lastDigits: '0977123456',
      expiryDate: undefined,
      isDefault: false,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    },
    {
      id: 'pm_3',
      userId: demoAuthService.getDemoUser()?.id || '',
      type: 'bank',
      name: 'Zanaco Savings',
      provider: 'zanaco',
      lastDigits: '****1234',
      expiryDate: undefined,
      isDefault: false,
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
  ];

  const realQuery = useQuery({
    queryKey: ['paymentMethods', 'real'],
    queryFn: async () => {
      return mockPaymentMethods;
    },
    staleTime: Infinity,
    enabled: !isDemo
  });

  if (isDemo) {
    return createDemoQueryResult(mockPaymentMethods);
  }

  return realQuery;
};

/**
 * Smart hooks that auto-select between demo and real based on mode
 */

export const useLoyaltyDataSmartWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = useLoyaltyDataWithDemo();
  const realQuery = useLoyaltyData();

  return isDemo ? demoQuery : realQuery;
};

export const useLoyaltyTransactionsSmartWithDemo = (limit = 20) => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = useLoyaltyTransactionsWithDemo(limit);
  const realQuery = useLoyaltyTransactions(limit);

  return isDemo ? demoQuery : realQuery;
};

export const useLoyaltyRewardsSmartWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = useLoyaltyRewardsWithDemo();
  const realQuery = useLoyaltyRewards();

  return isDemo ? demoQuery : realQuery;
};

export const useWalletDataSmartWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = useWalletDataWithDemo();
  const realQuery = useWalletData();

  return isDemo ? demoQuery : realQuery;
};

export const useWalletTransactionsSmartWithDemo = (limit = 20) => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = useWalletTransactionsWithDemo(limit);
  const realQuery = useWalletTransactions(limit);

  return isDemo ? demoQuery : realQuery;
};

export const usePaymentMethodsSmartWithDemo = () => {
  const isDemo = demoAuthService.isDemoMode();
  const demoQuery = usePaymentMethodsWithDemo();
  const realQuery = usePaymentMethods();

  return isDemo ? demoQuery : realQuery;
};

/**
 * Demo mutations for loyalty operations
 */

export const useRedeemRewardWithDemo = () => {
  return useMutation({
    mutationFn: async (rewardId: string) => {
      // Simulate redemption delay
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Return mock redemption
      return {
        id: `redemption_${Date.now()}`,
        userId: demoAuthService.getDemoUser()?.id || '',
        rewardId,
        pointsSpent: 500,
        createdAt: new Date().toISOString(),
        status: 'completed'
      };
    }
  });
};

export const useReferFriendWithDemo = () => {
  return useMutation({
    mutationFn: async (refereeEmail: string) => {
      // Simulate API delay
      await new Promise(resolve => setTimeout(resolve, 300));
      
      const user = demoAuthService.getDemoUser();
      const referralCode = `DEMO${user?.id?.slice(-6).toUpperCase() || '123'}`;
      const referralLink = `${window.location.origin}?ref=${referralCode}`;

      return {
        referralCode,
        referralLink,
        refereeEmail
      };
    }
  });
};

/**
 * Demo mutations for wallet operations
 */

export const useAddFundsWithDemo = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (params: { amount: number; paymentMethodId: string }) => {
      // Simulate payment processing
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      return {
        id: `transaction_${Date.now()}`,
        userId: demoAuthService.getDemoUser()?.id || '',
        type: 'deposit' as const,
        amount: params.amount,
        currency: 'ZMW',
        status: 'completed',
        paymentMethodId: params.paymentMethodId,
        createdAt: new Date().toISOString()
      };
    },
    onSuccess: () => {
      // Invalidate wallet queries to trigger refetch
      queryClient.invalidateQueries({ queryKey: ['wallet'] });
      queryClient.invalidateQueries({ queryKey: ['userWallet'] });
    }
  });
};

export const useTransferFundsWithDemo = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (params: { recipientId: string; amount: number }) => {
      // Simulate transfer
      await new Promise(resolve => setTimeout(resolve, 500));
      
      return {
        id: `transfer_${Date.now()}`,
        userId: demoAuthService.getDemoUser()?.id || '',
        type: 'transfer' as const,
        amount: params.amount,
        currency: 'ZMW',
        status: 'completed',
        recipientId: params.recipientId,
        createdAt: new Date().toISOString()
      };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet'] });
      queryClient.invalidateQueries({ queryKey: ['userWallet'] });
    }
  });
};

export const useWithdrawFundsWithDemo = () => {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (params: { amount: number; paymentMethodId: string }) => {
      // Simulate withdrawal
      await new Promise(resolve => setTimeout(resolve, 800));
      
      return {
        id: `withdrawal_${Date.now()}`,
        userId: demoAuthService.getDemoUser()?.id || '',
        type: 'withdrawal' as const,
        amount: params.amount,
        currency: 'ZMW',
        status: 'pending',
        paymentMethodId: params.paymentMethodId,
        createdAt: new Date().toISOString()
      };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['wallet'] });
      queryClient.invalidateQueries({ queryKey: ['userWallet'] });
    }
  });
};

/**
 * Demo hook for Flutterwave payments (Mobile Money, Cards, Bank Transfers)
 */
export const useAddFundsWithFlutterwaveDemo = () => {
  return useMutation({
    mutationFn: async (params: {
      amount: number;
      phoneNumber: string;
      paymentMethod: 'mobile_money' | 'card' | 'bank_transfer';
      mobileProvider?: 'mtn' | 'airtel' | 'vodafone';
    }) => {
      // Simulate Flutterwave payment processing
      const reference = flutterwavePaymentService.generateTransactionReference();
      const provider = ZAMBIA_MOBILE_MONEY_PROVIDERS.find(
        (p) => p.id === params.mobileProvider
      );

      return await flutterwavePaymentService.mockFlutterwavePayment(
        {
          amount: params.amount,
          email: 'demo@busnstay.com',
          phoneNumber: params.phoneNumber,
          fullName: 'Demo User',
          paymentMethod: params.paymentMethod,
          mobileProvider: params.mobileProvider,
          currency: 'ZMW',
          description: 'BusNStay Wallet Top-up (Demo)',
          reference,
        },
        2000 // 2 second delay
      );
    }
  });
};

/**
 * Demo hook for getting mobile money providers
 */
export const useMobileMoneyProvidersDemo = () => {
  return useQuery({
    queryKey: ['mobileMoneyProviders', 'demo'],
    queryFn: async () => {
      await new Promise(resolve => setTimeout(resolve, 300));
      return ZAMBIA_MOBILE_MONEY_PROVIDERS;
    },
    staleTime: Infinity,
  });
};

/**
 * Demo hook for calculating payment fees
 */
export const useCalculatePaymentFeesDemo = (
  amount: number,
  paymentMethod: 'mobile_money' | 'card' | 'bank_transfer' = 'mobile_money',
  mobileProvider?: string
) => {
  return useQuery({
    queryKey: ['paymentFees', 'demo', amount, paymentMethod, mobileProvider],
    queryFn: async () => {
      return flutterwavePaymentService.calculateTotalWithFees(
        amount,
        paymentMethod,
        mobileProvider
      );
    },
    staleTime: Infinity,
    enabled: amount > 0,
  });
};
