import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  BarChart3,
  Wallet,
  Gift,
  Settings,
  LogOut,
  TrendingUp,
  Zap,
  Users,
  Loader2
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import LoyaltyProgram from './LoyaltyProgram';
import DigitalWallet from './DigitalWallet';
import { useLoyaltyDataSmartWithDemo, useLoyaltyTransactionsSmartWithDemo } from '@/hooks/useWithDemo';
import { useWalletDataSmartWithDemo, useWalletTransactionsSmartWithDemo, usePaymentMethodsSmartWithDemo } from '@/hooks/useWithDemo';
import { useAuth } from '@/hooks/useAuth';

type Tab = 'overview' | 'wallet' | 'rewards' | 'settings';

interface OverviewStats {
  label: string;
  value: string | number;
  icon: React.ReactNode;
  color: string;
}

const AccountDashboard = () => {
  const [activeTab, setActiveTab] = useState<Tab>('overview');
  const { user, signOut } = useAuth();

  // Loyalty hooks
  const loyaltyQuery = useLoyaltyDataSmartWithDemo();
  const transactionsQuery = useLoyaltyTransactionsSmartWithDemo(5);

  // Wallet hooks
  const walletQuery = useWalletDataSmartWithDemo();
  const walletTransactionsQuery = useWalletTransactionsSmartWithDemo(5);
  const paymentMethodsQuery = usePaymentMethodsSmartWithDemo();

  const isLoading =
    loyaltyQuery.isLoading ||
    walletQuery.isLoading ||
    transactionsQuery.isLoading ||
    walletTransactionsQuery.isLoading;

  const handleLogout = async () => {
    await signOut();
  };

  // Calculate tier progress
  const tierThresholds = {
    bronze: { min: 0, max: 999, color: '#8B7355', label: 'Bronze' },
    silver: { min: 1000, max: 4999, color: '#C0C0C0', label: 'Silver' },
    gold: { min: 5000, max: 9999, color: '#FFD700', label: 'Gold' },
    platinum: { min: 10000, max: Infinity, color: '#E5E4E2', label: 'Platinum' }
  };

  const currentTier = loyaltyQuery.data?.tier || 'bronze';
  const currentThreshold = tierThresholds[currentTier as keyof typeof tierThresholds];
  const tierProgress =
    ((loyaltyQuery.data?.currentPoints || 0) - currentThreshold.min) /
    (currentThreshold.max - currentThreshold.min);

  // Overview stats
  const overviewStats: OverviewStats[] = [
    {
      label: 'Current Balance',
      value: `$${(walletQuery.data?.balance || 0).toFixed(2)}`,
      icon: <Wallet className="w-5 h-5" />,
      color: 'from-blue-500 to-blue-600'
    },
    {
      label: 'Loyalty Points',
      value: loyaltyQuery.data?.currentPoints || 0,
      icon: <Zap className="w-5 h-5" />,
      color: 'from-amber-500 to-amber-600'
    },
    {
      label: 'Current Tier',
      value: currentTier.charAt(0).toUpperCase() + currentTier.slice(1),
      icon: <TrendingUp className="w-5 h-5" />,
      color: 'from-purple-500 to-purple-600'
    },
    {
      label: 'Referrals',
      value: loyaltyQuery.data?.referralCount || 0,
      icon: <Users className="w-5 h-5" />,
      color: 'from-green-500 to-green-600'
    }
  ];

  const tabs = [
    { id: 'overview' as Tab, label: 'Overview', icon: BarChart3 },
    { id: 'wallet' as Tab, label: 'Wallet', icon: Wallet },
    { id: 'rewards' as Tab, label: 'Rewards', icon: Gift },
    { id: 'settings' as Tab, label: 'Settings', icon: Settings }
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Header */}
      <div className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-sm sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
                <span className="text-white font-bold text-lg">
                  {user?.email?.[0]?.toUpperCase() || 'U'}
                </span>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-white">Account Dashboard</h1>
                <p className="text-sm text-slate-400">{user?.email}</p>
              </div>
            </div>
            <Button
              onClick={handleLogout}
              variant="ghost"
              className="text-slate-400 hover:text-white hover:bg-slate-800"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="border-b border-slate-800 bg-slate-900/30 sticky top-16 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex gap-1">
            {tabs.map(tab => {
              const Icon = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={cn(
                    'px-4 py-3 font-medium text-sm border-b-2 transition-colors flex items-center gap-2',
                    activeTab === tab.id
                      ? 'border-blue-500 text-blue-400'
                      : 'border-transparent text-slate-400 hover:text-slate-300'
                  )}
                >
                  <Icon className="w-4 h-4" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {isLoading && (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-8 h-8 text-blue-500 animate-spin" />
          </div>
        )}

        <AnimatePresence mode="wait">
          {!isLoading && (
            <motion.div
              key={activeTab}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.2 }}
            >
              {/* OVERVIEW TAB */}
              {activeTab === 'overview' && (
                <div className="space-y-8">
                  {/* Stats Grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    {overviewStats.map((stat, index) => (
                      <motion.div
                        key={index}
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.1 }}
                        className={`bg-gradient-to-br ${stat.color} p-6 rounded-xl shadow-lg`}
                      >
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="text-white/70 text-sm font-medium">{stat.label}</p>
                            <p className="text-2xl font-bold text-white mt-2">{stat.value}</p>
                          </div>
                          <div className="text-white/30">{stat.icon}</div>
                        </div>
                      </motion.div>
                    ))}
                  </div>

                  {/* Tier Progress */}
                  {loyaltyQuery.data && (
                    <motion.div
                      initial={{ opacity: 0, y: 20 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ delay: 0.4 }}
                      className="bg-slate-800/50 backdrop-blur border border-slate-700 rounded-xl p-6"
                    >
                      <h3 className="text-lg font-semibold text-white mb-4">
                        Tier Progress: {currentThreshold.label}
                      </h3>
                      <div className="space-y-2">
                        <div className="w-full bg-slate-700 rounded-full h-3 overflow-hidden">
                          <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: `${Math.min(tierProgress * 100, 100)}%` }}
                            transition={{ duration: 1, ease: 'easeOut' }}
                            style={{ backgroundColor: currentThreshold.color }}
                            className="h-full rounded-full"
                          />
                        </div>
                        <div className="flex justify-between text-sm">
                          <span className="text-slate-400">
                            {loyaltyQuery.data.currentPoints} points
                          </span>
                          <span className="text-slate-400">
                            {loyaltyQuery.data.pointsToNextTier} to next tier
                          </span>
                        </div>
                      </div>
                    </motion.div>
                  )}

                  {/* Recent Activity */}
                  <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.5 }}
                    className="grid grid-cols-1 lg:grid-cols-2 gap-6"
                  >
                    {/* Recent Transactions */}
                    <div className="bg-slate-800/50 backdrop-blur border border-slate-700 rounded-xl p-6">
                      <h3 className="text-lg font-semibold text-white mb-4">
                        Recent Transactions
                      </h3>
                      <div className="space-y-3">
                        {walletTransactionsQuery.data?.slice(0, 5).map(transaction => (
                          <div
                            key={transaction.id}
                            className="flex items-center justify-between text-sm"
                          >
                            <div>
                              <p className="text-white">{transaction.description}</p>
                              <p className="text-xs text-slate-400">
                                {new Date(transaction.createdAt).toLocaleDateString()}
                              </p>
                            </div>
                            <span
                              className={cn(
                                'font-semibold',
                                transaction.type === 'debit'
                                  ? 'text-red-400'
                                  : 'text-green-400'
                              )}
                            >
                              {transaction.type === 'debit' ? '-' : '+'}${transaction.amount.toFixed(2)}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Recent Loyalty Activity */}
                    <div className="bg-slate-800/50 backdrop-blur border border-slate-700 rounded-xl p-6">
                      <h3 className="text-lg font-semibold text-white mb-4">
                        Recent Loyalty Activity
                      </h3>
                      <div className="space-y-3">
                        {transactionsQuery.data?.slice(0, 5).map(transaction => (
                          <div key={transaction.id} className="flex items-center justify-between text-sm">
                            <div>
                              <p className="text-white">{transaction.description}</p>
                              <p className="text-xs text-slate-400">
                                {new Date(transaction.createdAt).toLocaleDateString()}
                              </p>
                            </div>
                            <span
                              className={cn(
                                'font-semibold',
                                transaction.points < 0 ? 'text-red-400' : 'text-blue-400'
                              )}
                            >
                              {transaction.points > 0 ? '+' : ''}{transaction.points}
                            </span>
                          </div>
                        ))}
                      </div>
                    </div>
                  </motion.div>
                </div>
              )}

              {/* WALLET TAB */}
              {activeTab === 'wallet' && (
                <DigitalWallet
                  balance={walletQuery.data?.balance}
                  currency={walletQuery.data?.currency}
                  // eslint-disable-next-line @typescript-eslint/no-explicit-any
                  transactions={walletTransactionsQuery.data as any}
                  // eslint-disable-next-line @typescript-eslint/no-explicit-any
                  paymentMethods={paymentMethodsQuery.data as any}
                />
              )}

              {/* REWARDS TAB */}
              {activeTab === 'rewards' && (
                <LoyaltyProgram
                  currentPoints={loyaltyQuery.data?.currentPoints}
                  totalPointsEarned={loyaltyQuery.data?.totalPointsEarned}
                  currentTier={loyaltyQuery.data?.tier}
                  pointsToNextTier={loyaltyQuery.data?.pointsToNextTier}
                  recentActivity={transactionsQuery.data}
                />
              )}

              {/* SETTINGS TAB */}
              {activeTab === 'settings' && (
                <div className="bg-slate-800/50 backdrop-blur border border-slate-700 rounded-xl p-8">
                  <h2 className="text-2xl font-bold text-white mb-6">Settings</h2>

                  <div className="space-y-6 max-w-2xl">
                    {/* Profile Settings */}
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-3">Profile</h3>
                      <div className="space-y-3">
                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-1">
                            Email
                          </label>
                          <input
                            type="email"
                            value={user?.email || ''}
                            disabled
                            className="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white disabled:opacity-50"
                          />
                        </div>
                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-1">
                            Referral Code
                          </label>
                          <div className="flex gap-2">
                            <input
                              type="text"
                              value={loyaltyQuery.data?.referralCode || ''}
                              disabled
                              className="flex-1 px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white disabled:opacity-50 font-mono"
                            />
                            <Button
                              onClick={() => {
                                const code = loyaltyQuery.data?.referralCode;
                                if (code) navigator.clipboard.writeText(code);
                              }}
                              className="bg-blue-600 hover:bg-blue-700"
                            >
                              Copy
                            </Button>
                          </div>
                        </div>
                      </div>
                    </div>

                    {/* Currency Settings */}
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-3">Currency</h3>
                      <div className="space-y-2">
                        <div>
                          <label className="block text-sm font-medium text-slate-400 mb-2">
                            Preferred Currency
                          </label>
                          <select
                            defaultValue="ZMW"
                            className="w-full px-4 py-2 bg-slate-700 border border-slate-600 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                          >
                            <option value="ZMW">Kwacha (ZMW) - Default</option>
                            <option value="USD">US Dollar (USD)</option>
                            <option value="GBP">British Pound (GBP)</option>
                            <option value="ZAR">South African Rand (ZAR)</option>
                          </select>
                        </div>
                        <p className="text-xs text-slate-500 mt-2">
                          All transactions and balances will be displayed in your preferred currency
                        </p>
                      </div>
                    </div>

                    {/* Notification Settings */}
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-3">Notifications</h3>
                      <div className="space-y-2">
                        {['Email Notifications', 'SMS Alerts', 'Loyalty Updates'].map(option => (
                          <label key={option} className="flex items-center gap-3">
                            <input
                              type="checkbox"
                              defaultChecked
                              className="w-4 h-4 rounded border-slate-600 text-blue-600"
                            />
                            <span className="text-slate-300">{option}</span>
                          </label>
                        ))}
                      </div>
                    </div>

                    {/* Danger Zone */}
                    <div className="pt-6 border-t border-slate-700">
                      <h3 className="text-lg font-semibold text-red-400 mb-3">Danger Zone</h3>
                      <Button variant="destructive" className="w-full">
                        Close Account
                      </Button>
                    </div>
                  </div>
                </div>
              )}
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </div>
  );
};

export default AccountDashboard;
