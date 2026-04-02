import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from './useAuth';
import { supabase } from '@/lib/supabase';

export interface LoyaltyData {
  userId: string;
  currentPoints: number;
  totalPointsEarned: number;
  totalPointsRedeemed: number;
  tier: 'bronze' | 'silver' | 'gold' | 'platinum';
  referralCode: string;
  referralCount: number;
  pointsToNextTier: number;
  createdAt: string;
  updatedAt: string;
  lastActivity: string;
}

export interface LoyaltyTransaction {
  id: string;
  userId: string;
  type: 'earning' | 'redemption' | 'referral' | 'bonus' | 'expiration';
  points: number;
  description: string;
  relatedBookingId?: string;
  relatedReferralCode?: string;
  expiresAt?: string;
  createdAt: string;
  metadata?: Record<string, unknown>;
}

export interface LoyaltyReward {
  id: string;
  name: string;
  description: string;
  category: 'discount' | 'upgrade' | 'gift' | 'exclusive' | 'experience';
  pointsRequired: number;
  maxRedemptions?: number;
  currentRedemptions: number;
  popularityScore: number;
  imageUrl?: string;
  badgeIcon?: string;
  active: boolean;
  createdAt: string;
  updatedAt: string;
}

/**
 * Hook to fetch current user's loyalty data
 */
export const useLoyaltyData = () => {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['loyalty', user?.id],
    queryFn: async () => {
      if (!user?.id) throw new Error('User not authenticated');

      const { data, error } = await supabase
        .from('user_loyalty')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error) throw error;

      // Calculate points to next tier
      const tierThresholds = {
        bronze: { min: 0, max: 999 },
        silver: { min: 1000, max: 4999 },
        gold: { min: 5000, max: 9999 },
        platinum: { min: 10000, max: Infinity }
      };

      const currentThreshold = tierThresholds[data.tier as keyof typeof tierThresholds];
      const pointsToNext = currentThreshold.max - data.current_points;

      return {
        userId: data.user_id,
        currentPoints: data.current_points,
        totalPointsEarned: data.total_points_earned,
        totalPointsRedeemed: data.total_points_redeemed,
        tier: data.tier,
        referralCode: data.referral_code,
        referralCount: data.referral_count,
        pointsToNextTier: pointsToNext,
        createdAt: data.created_at,
        updatedAt: data.updated_at,
        lastActivity: data.last_activity
      } as LoyaltyData;
    },
    enabled: !!user?.id,
    staleTime: 5 * 60 * 1000 // 5 minutes
  });
};

/**
 * Hook to fetch loyalty transactions (earning history)
 */
export const useLoyaltyTransactions = (limit = 20) => {
  const { user } = useAuth();

  return useQuery({
    queryKey: ['loyaltyTransactions', user?.id, limit],
    queryFn: async () => {
      if (!user?.id) throw new Error('User not authenticated');

      const { data, error } = await supabase
        .from('loyalty_transactions')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', { ascending: false })
        .limit(limit);

      if (error) throw error;

      return data.map(transaction => ({
        id: transaction.id,
        userId: transaction.user_id,
        type: transaction.type,
        points: transaction.points,
        description: transaction.description,
        relatedBookingId: transaction.related_booking_id,
        relatedReferralCode: transaction.related_referral_code,
        expiresAt: transaction.expires_at,
        createdAt: transaction.created_at,
        metadata: transaction.metadata
      })) as LoyaltyTransaction[];
    },
    enabled: !!user?.id,
    staleTime: 3 * 60 * 1000 // 3 minutes
  });
};

/**
 * Hook to fetch available loyalty rewards
 */
export const useLoyaltyRewards = () => {
  return useQuery({
    queryKey: ['loyaltyRewards'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('loyalty_rewards')
        .select('*')
        .eq('active', true)
        .order('popularity_score', { ascending: false });

      if (error) throw error;

      return data.map(reward => ({
        id: reward.id,
        name: reward.name,
        description: reward.description,
        category: reward.category,
        pointsRequired: reward.points_required,
        maxRedemptions: reward.max_redemptions,
        currentRedemptions: reward.current_redemptions,
        popularityScore: reward.popularity_score,
        imageUrl: reward.image_url,
        badgeIcon: reward.badge_icon,
        active: reward.active,
        createdAt: reward.created_at,
        updatedAt: reward.updated_at
      })) as LoyaltyReward[];
    },
    staleTime: 10 * 60 * 1000 // 10 minutes
  });
};

/**
 * Hook to redeem a loyalty reward
 */
export const useRedeemReward = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (rewardId: string) => {
      if (!user?.id) throw new Error('User not authenticated');

      // Get reward details
      const { data: reward, error: rewardError } = await supabase
        .from('loyalty_rewards')
        .select('*')
        .eq('id', rewardId)
        .single();

      if (rewardError) throw rewardError;

      // Get user's current loyalty
      const { data: loyalty, error: loyaltyError } = await supabase
        .from('user_loyalty')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (loyaltyError) throw loyaltyError;

      // Validate user has enough points
      if (loyalty.current_points < reward.points_required) {
        throw new Error('Insufficient loyalty points');
      }

      // Create redemption record
      const { data: redemption, error: redemptionError } = await supabase
        .from('reward_redemptions')
        .insert({
          user_id: user.id,
          reward_id: rewardId,
          points_spent: reward.points_required
        })
        .select()
        .single();

      if (redemptionError) throw redemptionError;

      return redemption;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['loyalty', user?.id] });
      queryClient.invalidateQueries({ queryKey: ['loyaltyTransactions'] });
      queryClient.invalidateQueries({ queryKey: ['loyaltyRewards'] });
    }
  });
};

/**
 * Hook to refer a friend
 */
export const useReferFriend = () => {
  const { user } = useAuth();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (refereeEmail: string) => {
      if (!user?.id) throw new Error('User not authenticated');

      // Get referrer's referral code
      const { data: loyalty, error: loyaltyError } = await supabase
        .from('user_loyalty')
        .select('referral_code')
        .eq('user_id', user.id)
        .single();

      if (loyaltyError) throw loyaltyError;

      // Generate referral link
      const referralLink = `${window.location.origin}?ref=${loyalty.referral_code}`;

      return {
        referralCode: loyalty.referral_code,
        referralLink,
        refereeEmail
      };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['loyalty', user?.id] });
    }
  });
};
