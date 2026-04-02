import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Zap, Crown, Gift, TrendingUp, Lock, Sparkles, ArrowRight, Star, Target } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

interface LoyaltyReward {
  id: string;
  name: string;
  description: string;
  pointsRequired: number;
  discount?: number;
  icon: string;
  category: 'discount' | 'upgrade' | 'gift' | 'exclusive';
  available: boolean;
  popularity: number;
}

interface UserLoyaltyTier {
  tier: 'bronze' | 'silver' | 'gold' | 'platinum';
  minPoints: number;
  maxPoints: number;
  benefits: string[];
  color: string;
  icon: string;
}

interface LoyaltyProgramProps {
  currentPoints?: number;
  totalPointsEarned?: number;
  currentTier?: 'bronze' | 'silver' | 'gold' | 'platinum';
  pointsToNextTier?: number;
  recentActivity?: any[];
  rewards?: LoyaltyReward[];
  onRedeemReward?: (rewardId: string) => void;
  onReferFriend?: () => void;
}

const LoyaltyProgram = ({
  currentPoints = 2450,
  totalPointsEarned = 5230,
  currentTier = 'silver',
  pointsToNextTier = 550,
  recentActivity = [],
  rewards = [
    {
      id: '1',
      name: 'Free Ride',
      description: 'Complimentary bus journey up to $50',
      pointsRequired: 1000,
      discount: 100,
      icon: '🎫',
      category: 'upgrade',
      available: true,
      popularity: 92
    },
    {
      id: '2',
      name: 'Hotel Upgrade',
      description: 'Free upgrade to premium room',
      pointsRequired: 800,
      discount: 80,
      icon: '🏨',
      category: 'exclusive',
      available: true,
      popularity: 85
    },
    {
      id: '3',
      name: 'Meals Package',
      description: '3 meal vouchers for your journey',
      pointsRequired: 600,
      discount: 60,
      icon: '🍽️',
      category: 'gift',
      available: true,
      popularity: 88
    },
    {
      id: '4',
      name: 'Premium Support',
      description: '1 year VIP customer support',
      pointsRequired: 1200,
      discount: 120,
      icon: '👑',
      category: 'exclusive',
      available: false,
      popularity: 78
    },
    {
      id: '5',
      name: '$20 Credit',
      description: 'Usable on any booking',
      pointsRequired: 400,
      discount: 20,
      icon: '💳',
      category: 'discount',
      available: true,
      popularity: 95
    },
    {
      id: '6',
      name: 'Travel Kit',
      description: 'Exclusive BusNStay travel accessories',
      pointsRequired: 750,
      discount: 75,
      icon: '🎒',
      category: 'gift',
      available: true,
      popularity: 82
    }
  ],
  onRedeemReward,
  onReferFriend
}: LoyaltyProgramProps) => {
  const [selectedCategory, setSelectedCategory] = useState<'all' | 'discount' | 'upgrade' | 'gift' | 'exclusive'>('all');
  const [showTierInfo, setShowTierInfo] = useState(false);
  const [claimedRewards, setClaimedRewards] = useState<string[]>([]);

  const tiers: Record<string, UserLoyaltyTier> = {
    bronze: {
      tier: 'bronze',
      minPoints: 0,
      maxPoints: 999,
      benefits: ['2% points on every booking', 'Birthday discount coupon'],
      color: 'from-amber-700 to-yellow-700',
      icon: '🥉'
    },
    silver: {
      tier: 'silver',
      minPoints: 1000,
      maxPoints: 4999,
      benefits: ['5% points on every booking', 'Priority customer support', 'Free meal on 10th booking', 'Exclusive member events'],
      color: 'from-slate-400 to-slate-500',
      icon: '🥈'
    },
    gold: {
      tier: 'gold',
      minPoints: 5000,
      maxPoints: 9999,
      benefits: ['10% points on every booking', '24/7 VIP support', 'Free hotel upgrade', 'Quarterly lounge access', 'Travel insurance included'],
      color: 'from-yellow-500 to-yellow-600',
      icon: '🥇'
    },
    platinum: {
      tier: 'platinum',
      minPoints: 10000,
      maxPoints: Infinity,
      benefits: ['20% points on every booking', 'Concierge service', 'Lifetime discount', 'Free travel companion seat', 'Annual rewards redemption'],
      color: 'from-blue-400 to-purple-500',
      icon: '💎'
    }
  };

  const currentTierInfo = tiers[currentTier];
  const tierProgression = ((currentPoints - currentTierInfo.minPoints) / (currentTierInfo.maxPoints - currentTierInfo.minPoints)) * 100;

  const filteredRewards = selectedCategory === 'all' 
    ? rewards 
    : rewards.filter(r => r.category === selectedCategory);

  const handleRedeem = (rewardId: string) => {
    setClaimedRewards([...claimedRewards, rewardId]);
    onRedeemReward?.(rewardId);
  };

  return (
    <div className="w-full space-y-8">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="text-center mb-8"
      >
        <h1 className="text-4xl font-bold text-gradient mb-2">BusNStay Rewards</h1>
        <p className="text-gray-400">Earn points on every journey and unlock exclusive benefits</p>
      </motion.div>

      {/* Main Tier Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className={cn(
          'bg-gradient-to-br rounded-2xl border border-white/10 p-8 backdrop-blur-sm overflow-hidden relative',
          `${currentTierInfo.color}`
        )}
      >
        {/* Animated Background */}
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ duration: 20, repeat: Infinity, ease: 'linear' }}
          className="absolute top-0 right-0 w-96 h-96 rounded-full bg-white/5 blur-3xl -z-0"
        />

        <div className="relative z-10">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {/* Left: Tier Info */}
            <div className="space-y-6">
              <div>
                <p className="text-white/80 text-sm uppercase tracking-wider mb-2">Your Tier</p>
                <div className="flex items-center gap-3 mb-4">
                  <span className="text-5xl">{currentTierInfo.icon}</span>
                  <div>
                    <h2 className="text-3xl font-bold text-white capitalize">
                      {currentTier} Member
                    </h2>
                    <p className="text-white/70 text-sm">Since your first booking</p>
                  </div>
                </div>
              </div>

              {/* Points Display */}
              <div className="bg-black/30 rounded-lg p-4 border border-white/20">
                <p className="text-white/80 text-sm mb-2">Available Points</p>
                <div className="flex items-baseline gap-2 mb-3">
                  <span className="text-4xl font-bold text-white">{currentPoints.toLocaleString()}</span>
                  <span className="text-white/60">pts</span>
                </div>
                <p className="text-white/70 text-sm">
                  {pointsToNextTier} points to next tier
                </p>
              </div>

              {/* Progress Bar */}
              <div>
                <div className="h-3 bg-black/40 rounded-full overflow-hidden border border-white/20">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${tierProgression}%` }}
                    transition={{ duration: 1, ease: 'easeOut' }}
                    className="h-full bg-gradient-to-r from-white to-white/50"
                  />
                </div>
                <div className="flex justify-between text-xs text-white/60 mt-2">
                  <span>{currentTierInfo.minPoints.toLocaleString()}</span>
                  <span>{currentTierInfo.maxPoints === Infinity ? '∞' : currentTierInfo.maxPoints.toLocaleString()}</span>
                </div>
              </div>
            </div>

            {/* Right: Benefits */}
            <div>
              <p className="text-white/80 text-sm uppercase tracking-wider mb-4">Current Benefits</p>
              <div className="space-y-2">
                {currentTierInfo.benefits.map((benefit, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: i * 0.1 }}
                    className="flex items-center gap-3 bg-white/10 rounded-lg p-3 border border-white/20"
                  >
                    <Sparkles className="w-5 h-5 text-white flex-shrink-0" />
                    <span className="text-white text-sm">{benefit}</span>
                  </motion.div>
                ))}
              </div>
            </div>
          </div>

          {/* Next Tier Preview */}
          {currentTier !== 'platinum' && (
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.3 }}
              className="mt-6 pt-6 border-t border-white/20"
            >
              <button
                onClick={() => setShowTierInfo(!showTierInfo)}
                className="w-full flex items-center justify-between text-white hover:text-white/80 transition"
              >
                <span className="text-sm font-semibold">
                  See what's next: {Object.keys(tiers)[Object.keys(tiers).indexOf(currentTier) + 1]}
                </span>
                <ArrowRight className={cn(
                  'w-4 h-4 transition-transform',
                  showTierInfo && 'rotate-90'
                )} />
              </button>
            </motion.div>
          )}
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {[
          { icon: Zap, label: 'Points Earned This Month', value: '480 pts', color: 'from-yellow-600 to-yellow-700' },
          { icon: Gift, label: 'Rewards Redeemed', value: claimedRewards.length, color: 'from-green-600 to-emerald-700' },
          { icon: TrendingUp, label: 'Total Lifetime Points', value: totalPointsEarned.toLocaleString(), color: 'from-blue-600 to-indigo-700' }
        ].map((stat, i) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={i}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className={cn(
                'bg-gradient-to-br rounded-xl p-5 border border-white/10 backdrop-blur-sm',
                `${stat.color}`
              )}
            >
              <div className="flex items-center justify-between mb-3">
                <Icon className="w-6 h-6 text-white" />
                <span className="text-xs font-semibold text-white/70">{stat.label}</span>
              </div>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
            </motion.div>
          );
        })}
      </div>

      {/* Referral CTA */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.4 }}
        className="bg-gradient-to-r from-purple-900/30 to-indigo-900/30 border border-purple-700/50 rounded-xl p-6"
      >
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-white font-bold mb-1">Refer a Friend</h3>
            <p className="text-gray-300 text-sm">Earn 500 bonus points for every friend who books their first journey</p>
          </div>
          <Button
            onClick={onReferFriend}
            className="bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white border-0 whitespace-nowrap"
          >
            Share Link
          </Button>
        </div>
      </motion.div>

      {/* Rewards Marketplace */}
      <div>
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-white mb-4">Redeem Your Points</h2>
          
          {/* Category Filters */}
          <div className="flex gap-2 overflow-x-auto pb-2">
            {['all', 'discount', 'upgrade', 'gift', 'exclusive'].map((cat) => (
              <button
                key={cat}
                onClick={() => setSelectedCategory(cat as any)}
                className={cn(
                  'px-4 py-2 rounded-lg font-semibold text-sm whitespace-nowrap transition-all',
                  selectedCategory === cat
                    ? 'bg-blue-600 text-white'
                    : 'bg-slate-800 text-gray-300 hover:bg-slate-700'
                )}
              >
                {cat === 'all' ? 'All' : cat.charAt(0).toUpperCase() + cat.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* Rewards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredRewards.map((reward, i) => (
            <motion.div
              key={reward.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className="group relative"
            >
              {/* Card */}
              <div className={cn(
                'h-full bg-gradient-to-br from-slate-800/50 to-slate-900/50 border rounded-xl p-5 backdrop-blur-sm transition-all',
                reward.available ? 'border-white/10 hover:border-white/20 hover:bg-slate-800/70' : 'border-white/5 opacity-60'
              )}>
                {/* Header */}
                <div className="flex items-start justify-between mb-3">
                  <span className="text-3xl">{reward.icon}</span>
                  <div className="flex items-center gap-1 bg-white/10 px-2 py-1 rounded-lg">
                    <Star className="w-3 h-3 text-yellow-400" />
                    <span className="text-xs text-white">{reward.popularity}%</span>
                  </div>
                </div>

                {/* Content */}
                <h3 className="text-white font-bold mb-1">{reward.name}</h3>
                <p className="text-gray-400 text-xs mb-4">{reward.description}</p>

                {/* Points Required */}
                <div className="bg-black/30 rounded-lg p-3 mb-4 border border-white/10">
                  <div className="flex items-center justify-between">
                    <span className="text-gray-400 text-xs">Points Required</span>
                    <span className="text-lg font-bold text-blue-400">
                      {reward.pointsRequired.toLocaleString()} pts
                    </span>
                  </div>
                  <div className="mt-2 h-2 bg-white/10 rounded-full overflow-hidden">
                    <motion.div
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.min((currentPoints / reward.pointsRequired) * 100, 100)}%` }}
                      transition={{ duration: 0.8 }}
                      className="h-full bg-gradient-to-r from-blue-500 to-blue-400"
                    />
                  </div>
                </div>

                {/* Redeem Button */}
                <Button
                  onClick={() => handleRedeem(reward.id)}
                  disabled={!reward.available || currentPoints < reward.pointsRequired || claimedRewards.includes(reward.id)}
                  className={cn(
                    'w-full transition-all',
                    claimedRewards.includes(reward.id)
                      ? 'bg-green-600 text-white border-0'
                      : reward.available && currentPoints >= reward.pointsRequired
                      ? 'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white border-0'
                      : 'bg-slate-700 text-gray-400 border-0 cursor-not-allowed'
                  )}
                >
                  {claimedRewards.includes(reward.id) ? '✓ Redeemed' : currentPoints < reward.pointsRequired ? 'Not Enough Points' : 'Redeem'}
                </Button>

                {!reward.available && (
                  <div className="absolute top-4 right-4 bg-red-600/20 p-2 rounded-lg">
                    <Lock className="w-4 h-4 text-red-400" />
                  </div>
                )}
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* How It Works */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5 }}
        className="bg-slate-800/30 border border-white/10 rounded-xl p-6"
      >
        <h3 className="text-white font-bold text-lg mb-4">How It Works</h3>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          {[
            { step: 1, title: 'Book Journey', desc: 'Earn 2-20% points per booking' },
            { step: 2, title: 'Complete Travel', desc: 'Points added after trip completion' },
            { step: 3, title: 'Reach Milestones', desc: 'Unlock higher tier benefits' },
            { step: 4, title: 'Redeem Rewards', desc: 'Exchange points for exclusive perks' }
          ].map((item) => (
            <div key={item.step} className="text-center">
              <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-bold flex items-center justify-center mx-auto mb-3">
                {item.step}
              </div>
              <p className="text-white font-semibold text-sm mb-1">{item.title}</p>
              <p className="text-gray-400 text-xs">{item.desc}</p>
            </div>
          ))}
        </div>
      </motion.div>
    </div>
  );
};

export default LoyaltyProgram;
