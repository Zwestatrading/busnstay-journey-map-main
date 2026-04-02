import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { UserProfile, UserRole } from '@/hooks/useAuth';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Wallet,
  Gift,
  LogOut,
  Settings,
  Clock,
  TrendingUp,
  Loader2,
  ArrowLeft,
  AlertCircle,
} from 'lucide-react';
import DigitalWallet from '@/components/DigitalWallet';
import LoyaltyProgram from '@/components/LoyaltyProgram';
import { useToast } from '@/hooks/use-toast';
import { useLoyaltyDataWithDemo, useLoyaltyTransactionsWithDemo, useLoyaltyRewardsWithDemo, useRedeemRewardWithDemo, useReferFriendWithDemo, useAddFundsWithDemo, useTransferFundsWithDemo, useWithdrawFundsWithDemo } from '@/hooks/useWithDemo';
import { useWalletDataWithDemo, useWalletTransactionsWithDemo, usePaymentMethodsWithDemo } from '@/hooks/useWithDemo';
import { useRedeemReward, useReferFriend } from '@/hooks/useLoyaltyData';
import { useAddFunds, useTransferFunds, useWithdrawFunds } from '@/hooks/useWalletData';
import { demoAuthService } from '@/utils/demoAuthService';

interface UserAccount {
  id: string;
  name: string;
  email: string;
  phone?: string;
  joinDate: Date;
  totalTrips: number;
  memberSince: string;
}

const AccountDashboard = () => {
  const { profile, user, signOut, isLoading: authLoading } = useAuthContext();
  const navigate = useNavigate();
  const { toast } = useToast();
  useBackNavigation('/');
  const [activeTab, setActiveTab] = useState('overview');
  const [loadingTimeout, setLoadingTimeout] = useState(false);
  const isDemoMode = demoAuthService.isDemoMode();

  // Track if loading is taking too long (show error after 10 seconds)
  useEffect(() => {
    if (!authLoading || isDemoMode) return;
    
    const timer = setTimeout(() => {
      setLoadingTimeout(true);
    }, 10000);

    return () => clearTimeout(timer);
  }, [authLoading, isDemoMode]);

  // Always use demo hooks for now (real Supabase hooks need type alignment)
  const loyaltyQuery = useLoyaltyDataWithDemo();
  const loyaltyTransactionsQuery = useLoyaltyTransactionsWithDemo(5);
  const loyaltyRewardsQuery = useLoyaltyRewardsWithDemo();
  const walletQuery = useWalletDataWithDemo();
  const walletTransactionsQuery = useWalletTransactionsWithDemo(5);
  const paymentMethodsQuery = usePaymentMethodsWithDemo();

  // Mutation hooks (use demo versions)
  const redeemRewardMutation = useRedeemRewardWithDemo();
  const referFriendMutation = useReferFriendWithDemo();
  const addFundsMutation = useAddFundsWithDemo();
  const transferFundsMutation = useTransferFundsWithDemo();
  const withdrawFundsMutation = useWithdrawFundsWithDemo();

  // Safe data accessors for demo data
  const walletBalance = Number(walletQuery.data?.balance || 0);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const currentPoints = Number((loyaltyQuery.data as any)?.currentPoints || 0);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const pointsToNextTier = (loyaltyQuery.data as any)?.pointsToNextTier || 0;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const totalPointsEarned = Number((loyaltyQuery.data as any)?.totalPointsEarned || 0);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const tier = ((loyaltyQuery.data as any)?.tier || 'bronze') as 'bronze' | 'silver' | 'gold' | 'platinum';

  const isLoading =
    loyaltyQuery.isLoading ||
    walletQuery.isLoading ||
    loyaltyTransactionsQuery.isLoading ||
    walletTransactionsQuery.isLoading ||
    loyaltyRewardsQuery.isLoading ||
    paymentMethodsQuery.isLoading;

  const handleSignOut = async () => {
    try {
      if (isDemoMode) {
        demoAuthService.disableDemoMode();
        // Don't wait for toast, navigate immediately
        toast({
          title: 'Signed out',
          description: 'You have been successfully signed out.',
        });
        navigate('/auth');
      } else {
        await signOut();
        toast({
          title: 'Signed out',
          description: 'You have been successfully signed out.',
        });
        setTimeout(() => {
          navigate('/auth');
        }, 500);
      }
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to sign out. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const handleAddFunds = async (amount: number, method: string) => {
    try {
      await addFundsMutation.mutateAsync({ amount, paymentMethodId: method });
      // Refetch wallet data to update balance
      walletQuery.refetch();
      toast({
        title: 'Fund Added',
        description: `K${amount} added successfully to your wallet.`,
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to add funds. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const handleTransfer = async (recipient: string, amount: number) => {
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      await (transferFundsMutation.mutateAsync as any)({ recipientEmail: recipient, amount });
      walletQuery.refetch();
      toast({
        title: 'Transfer Completed',
        description: `K${amount} transferred successfully.`,
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to transfer funds. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const handleWithdraw = async (amount: number, method: string) => {
    try {
      await withdrawFundsMutation.mutateAsync({ amount, paymentMethodId: method });
      walletQuery.refetch();
      toast({
        title: 'Withdrawal Initiated',
        description: `K${amount} withdrawal initiated.`,
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to process withdrawal. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const handleRedeemReward = async (rewardId: string) => {
    try {
      await redeemRewardMutation.mutateAsync(rewardId);
      toast({
        title: 'Reward Redeemed!',
        description: 'Your reward is being processed.',
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to redeem reward. Please try again.',
        variant: 'destructive',
      });
    }
  };

  const handleReferFriend = async () => {
    try {
      const result = await referFriendMutation.mutateAsync('friend@example.com');
      navigator.clipboard.writeText(result.referralLink);
      toast({
        title: 'Referral Link Copied',
        description: 'Share this link with your friends to earn 500 bonus points!',
      });
    } catch (error) {
      toast({
        title: 'Error',
        description: 'Failed to generate referral link. Please try again.',
        variant: 'destructive',
      });
    }
  };

  // Demo mode loading check
  if (isDemoMode) {
    const demoUser = demoAuthService.getDemoUser();
    const demoProfile = demoAuthService.getDemoProfile();
    
    if (!demoUser || !demoProfile) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-slate-950">
          <div className="text-center space-y-4">
            <Loader2 className="w-8 h-8 animate-spin mx-auto text-primary" />
            <p className="text-white">Loading account...</p>
          </div>
        </div>
      );
    }
    // Continue with demo data (fall through to render)
  }

  // Real auth loading check
  if (!isDemoMode && authLoading) {
    if (loadingTimeout) {
      // Loading is taking too long - show error with recovery
      return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-slate-950 p-4">
          <Card className="max-w-md border-yellow-500/50">
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-yellow-600">
                <AlertCircle className="w-5 h-5" /> 
                Taking Longer Than Expected
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <p className="text-muted-foreground text-sm">
                Your account is taking longer to load than usual. This might be a network issue.
              </p>
              <div className="space-y-2">
                <Button 
                  onClick={() => {
                    setLoadingTimeout(false);
                    window.location.reload();
                  }} 
                  className="w-full"
                >
                  Retry
                </Button>
                <Button 
                  onClick={() => {
                    demoAuthService.enableDemoMode('demo@example.com', 'passenger', 'Demo User');
                    navigate('/');
                  }} 
                  variant="outline" 
                  className="w-full"
                >
                  Try Demo Mode
                </Button>
                <Button 
                  onClick={() => signOut()} 
                  variant="ghost" 
                  className="w-full"
                >
                  <LogOut className="w-4 h-4 mr-2" /> Sign Out
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      );
    }

    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-slate-950">
        <div className="text-center space-y-4">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-primary" />
          <p className="text-white">Loading your account...</p>
          <p className="text-sm text-muted-foreground">Please wait while we fetch your data</p>
        </div>
      </div>
    );
  }

  // Real auth completed but no user (and not in demo mode) - show error
  if (!isDemoMode && !authLoading && !user) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-900 to-slate-950 p-4">
        <Card className="max-w-md border-red-500/50">
          <CardHeader>
            <CardTitle className="text-red-500 flex items-center gap-2">
              <AlertCircle className="w-5 h-5" />
              Unable to Load Profile
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <p className="text-muted-foreground text-sm">
              We couldn't load your account information. This might be a permission or connectivity issue.
            </p>
            <div className="space-y-2">
              <Button 
                onClick={() => window.location.reload()} 
                className="w-full"
              >
                Try Again
              </Button>
              <Button 
                onClick={() => {
                  demoAuthService.enableDemoMode('demo@example.com', 'passenger', 'Demo User');
                  navigate('/');
                }} 
                variant="outline" 
                className="w-full"
              >
                Try Demo Mode
              </Button>
              <Button 
                onClick={() => signOut()} 
                variant="ghost" 
                className="w-full text-red-500 hover:text-red-600"
              >
                <LogOut className="w-4 h-4 mr-2" /> Sign Out
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    );
  }

  // Use demo data as fallback if auth context hasn't updated yet
  const demoData = isDemoMode ? demoAuthService.getDemoProfile() : null;
  
  // Create a minimal profile if real user is authenticated but profile fetch failed
  const minimalProfile = user && !profile ? ({
    id: user.id,
    user_id: user.id,
    email: user.email || '',
    full_name: user.user_metadata?.full_name || user.email?.split('@')[0] || 'User',
    phone: null,
    avatar_url: null,
    role: 'passenger' as UserRole,
    is_approved: true,
    assigned_station_id: null,
    business_name: null,
    rating: 0,
    is_online: false,
    total_trips: 0,
    metadata: {},
    created_at: new Date().toISOString(),
  } as UserProfile) : null;

  const displayProfile = profile || demoData || minimalProfile;
  const displayUser = user || (demoData ? { email: demoData.email, user_metadata: { full_name: demoData.full_name } } : null);

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
      },
    },
  };

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.3 },
    },
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-950 text-white p-4 md:p-8">
      {/* Header */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="max-w-7xl mx-auto"
      >
        <div className="flex items-center justify-between mb-8">
          <div className="flex-1">
            <motion.h1 variants={itemVariants} className="text-4xl font-bold mb-2 flex items-center gap-3">
              <button
                onClick={() => navigate('/')}
                className="p-2 rounded-lg hover:bg-slate-800 transition"
                title="Back to Dashboard"
              >
                <ArrowLeft className="w-6 h-6" />
              </button>
              My Account
              {isDemoMode && <Badge className="bg-emerald-600">🎮 Demo Mode</Badge>}
            </motion.h1>
            <motion.p variants={itemVariants} className="text-slate-400">
              Welcome back, {displayProfile?.full_name || displayUser?.email || 'Demo User'}
            </motion.p>
          </div>
          <div className="flex gap-4">
            <motion.button
              variants={itemVariants}
              onClick={() => setActiveTab('settings')}
              className="p-2 rounded-lg hover:bg-slate-800 transition"
              title="Settings"
            >
              <Settings className="w-6 h-6" />
            </motion.button>
            <motion.button
              variants={itemVariants}
              onClick={handleSignOut}
              className="p-2 rounded-lg hover:bg-red-900/20 transition text-red-400"
              title="Sign Out"
            >
              <LogOut className="w-6 h-6" />
            </motion.button>
          </div>
        </div>

        {/* Quick Stats */}
        <motion.div
          variants={itemVariants}
          className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8"
        >
          <Card className="bg-gradient-to-br from-blue-900/20 to-blue-950/20 border-blue-700/30">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-slate-400 text-sm">Wallet Balance</p>
                  <p className="text-2xl font-bold mt-2">
                    {isLoading ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      `$${walletBalance.toFixed(2)}`
                    )}
                  </p>
                </div>
                <Wallet className="w-10 h-10 text-blue-400 opacity-50" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-purple-900/20 to-purple-950/20 border-purple-700/30">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-slate-400 text-sm">Loyalty Points</p>
                  <p className="text-2xl font-bold mt-2">
                    {isLoading ? (
                      <Loader2 className="w-4 h-4 animate-spin" />
                    ) : (
                      currentPoints.toLocaleString()
                    )}
                  </p>
                </div>
                <Gift className="w-10 h-10 text-purple-400 opacity-50" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-amber-900/20 to-amber-950/20 border-amber-700/30">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-slate-400 text-sm">Current Tier</p>
                  <div className="flex items-center gap-2 mt-2">
                    <Badge className="capitalize bg-amber-600 hover:bg-amber-700">
                      {isLoading ? 'Loading...' : loyaltyQuery.data?.tier || 'bronze'}
                    </Badge>
                  </div>
                </div>
                <TrendingUp className="w-10 h-10 text-amber-400 opacity-50" />
              </div>
            </CardContent>
          </Card>

          <Card className="bg-gradient-to-br from-green-900/20 to-green-950/20 border-green-700/30">
            <CardContent className="p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-slate-400 text-sm">Member Since</p>
                  <p className="text-2xl font-bold mt-2">245 days</p>
                </div>
                <Clock className="w-10 h-10 text-green-400 opacity-50" />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        {/* Main Content Tabs */}
        <motion.div variants={itemVariants}>
          <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
            <TabsList className="grid w-full grid-cols-4 bg-slate-800/50 border border-slate-700/50 p-1 mb-6">
              <TabsTrigger
                value="overview"
                className="data-[state=active]:bg-blue-600 transition"
              >
                Overview
              </TabsTrigger>
              <TabsTrigger
                value="wallet"
                className="data-[state=active]:bg-blue-600 transition"
              >
                Wallet
              </TabsTrigger>
              <TabsTrigger
                value="rewards"
                className="data-[state=active]:bg-blue-600 transition"
              >
                Rewards
              </TabsTrigger>
              <TabsTrigger
                value="settings"
                className="data-[state=active]:bg-blue-600 transition"
              >
                Settings
              </TabsTrigger>
            </TabsList>

            {/* Overview Tab */}
            <TabsContent value="overview" className="space-y-6 w-full">
              <motion.div
                variants={itemVariants}
                className="grid grid-cols-1 lg:grid-cols-2 gap-6"
              >
                {/* Mini Wallet Card */}
                <Card className="bg-slate-800/30 border-slate-700/50">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <Wallet className="w-5 h-5" />
                      Quick Wallet Access
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="bg-gradient-to-r from-blue-600 to-blue-700 rounded-lg p-6 text-white">
                      <p className="text-sm opacity-80">Available Balance</p>
                      <p className="text-3xl font-bold mt-2">${walletBalance.toFixed(2)}</p>
                    </div>
                    <div className="grid grid-cols-3 gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs h-10"
                        onClick={() => setActiveTab('wallet')}
                      >
                        Add Funds
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs h-10"
                        onClick={() => setActiveTab('wallet')}
                      >
                        Transfer
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        className="text-xs h-10"
                        onClick={() => setActiveTab('wallet')}
                      >
                        Withdraw
                      </Button>
                    </div>
                  </CardContent>
                </Card>

                {/* Mini Loyalty Card */}
                <Card className="bg-slate-800/30 border-slate-700/50">
                  <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                      <Gift className="w-5 h-5" />
                      Loyalty Status
                    </CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-4">
                    <div className="space-y-2">
                      <div className="flex justify-between items-center">
                        <span className="text-sm text-slate-400">Points to Next Tier</span>
                        <span className="font-bold text-amber-400">550 / 2000</span>
                      </div>
                      <div className="w-full bg-slate-700/50 rounded-full h-2">
                        <div
                          className="bg-gradient-to-r from-amber-400 to-amber-600 h-2 rounded-full"
                          style={{ width: '27.5%' }}
                        ></div>
                      </div>
                    </div>
                    <Button
                      className="w-full bg-gradient-to-r from-amber-600 to-amber-700 hover:from-amber-700 hover:to-amber-800"
                      size="sm"
                      onClick={() => setActiveTab('rewards')}
                    >
                      View Rewards
                    </Button>
                  </CardContent>
                </Card>
              </motion.div>

              {/* Account Info */}
              <motion.div variants={itemVariants}>
                <Card className="bg-slate-800/30 border-slate-700/50">
                  <CardHeader>
                    <CardTitle>Account Information</CardTitle>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-4">
                      <div className="grid grid-cols-2 gap-6">
                        <div>
                          <p className="text-sm text-slate-400 mb-1">Full Name</p>
                          <p className="font-semibold">{displayProfile?.full_name || 'Not provided'}</p>
                        </div>
                        <div>
                          <p className="text-sm text-slate-400 mb-1">Email</p>
                          <p className="font-semibold">{displayUser?.email || 'Not provided'}</p>
                        </div>
                        <div>
                          <p className="text-sm text-slate-400 mb-1">Phone</p>
                          <p className="font-semibold">{displayProfile?.phone || 'Not provided'}</p>
                        </div>
                        <div>
                          <p className="text-sm text-slate-400 mb-1">Total Trips</p>
                          <p className="font-semibold">24</p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </TabsContent>

            {/* Wallet Tab */}
            <TabsContent value="wallet" className="space-y-6 w-full">
              {walletQuery.isLoading || walletTransactionsQuery.isLoading || paymentMethodsQuery.isLoading ? (
                <div className="flex items-center justify-center py-12">
                  <Loader2 className="w-8 h-8 animate-spin text-blue-400" />
                </div>
              ) : (
                <DigitalWallet
                  balance={walletBalance}
                  currency={walletQuery.data?.currency || 'USD'}
                  // eslint-disable-next-line @typescript-eslint/no-explicit-any
                  transactions={(walletTransactionsQuery.data as any) || undefined}
                  // eslint-disable-next-line @typescript-eslint/no-explicit-any
                  paymentMethods={(paymentMethodsQuery.data as any) || undefined}
                  onAddFunds={handleAddFunds}
                  onTransfer={handleTransfer}
                  onWithdraw={handleWithdraw}
                />
              )}
            </TabsContent>

            {/* Rewards Tab */}
            <TabsContent value="rewards" className="space-y-6 w-full">
              <LoyaltyProgram
                currentPoints={currentPoints}
                totalPointsEarned={totalPointsEarned}
                currentTier={tier}
                pointsToNextTier={pointsToNextTier}
                recentActivity={loyaltyTransactionsQuery.data}
                onRedeemReward={handleRedeemReward}
                onReferFriend={handleReferFriend}
              />
            </TabsContent>

            {/* Settings Tab */}
            <TabsContent value="settings" className="space-y-6 w-full">
              <motion.div variants={itemVariants}>
                <Card className="bg-slate-800/30 border-slate-700/50">
                  <CardHeader>
                    <CardTitle>Account Settings</CardTitle>
                  </CardHeader>
                  <CardContent className="space-y-6">
                    <div className="space-y-4">
                      <div>
                        <h4 className="font-semibold mb-2">Email Preferences</h4>
                        <div className="space-y-2 text-sm text-slate-400">
                          <label className="flex items-center gap-3 cursor-pointer">
                            <input type="checkbox" defaultChecked className="w-4 h-4" />
                            <span>Booking confirmations</span>
                          </label>
                          <label className="flex items-center gap-3 cursor-pointer">
                            <input type="checkbox" defaultChecked className="w-4 h-4" />
                            <span>Loyalty rewards updates</span>
                          </label>
                          <label className="flex items-center gap-3 cursor-pointer">
                            <input type="checkbox" defaultChecked className="w-4 h-4" />
                            <span>Special offers and promotions</span>
                          </label>
                          <label className="flex items-center gap-3 cursor-pointer">
                            <input type="checkbox" className="w-4 h-4" />
                            <span>Weekly newsletter</span>
                          </label>
                        </div>
                      </div>
                    </div>

                    <hr className="border-slate-700/50" />

                    <div className="space-y-4">
                      <h4 className="font-semibold">Security</h4>
                      <Button variant="outline" className="w-full justify-start">
                        Change Password
                      </Button>
                      <Button variant="outline" className="w-full justify-start">
                        Two-Factor Authentication
                      </Button>
                    </div>

                    <hr className="border-slate-700/50" />

                    <div className="space-y-4">
                      <h4 className="font-semibold">Account Actions</h4>
                      <Button
                        variant="outline"
                        className="w-full justify-start"
                        onClick={handleSignOut}
                      >
                        <LogOut className="w-4 h-4 mr-2" />
                        Sign Out
                      </Button>
                      <Button
                        variant="destructive"
                        className="w-full justify-start"
                      >
                        Delete Account
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            </TabsContent>
          </Tabs>
        </motion.div>
      </motion.div>
    </div>
  );
};

export default AccountDashboard;
