import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { 
  Bike, Package, MapPin, Navigation, CheckCircle2, LogOut, AlertCircle, Loader2, DollarSign, Radio, ArrowLeft
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { useNavigate } from 'react-router-dom';
import { GPSTrackingStatus } from '@/components/GPSTrackingStatus';
import { LocationHistory } from '@/components/LocationHistory';
import DigitalWallet from '@/components/DigitalWallet';
import TextCallCentre from '@/components/TextCallCentre';
import { useWalletDataWithDemo, useWalletTransactionsWithDemo, usePaymentMethodsWithDemo, useAddFundsWithDemo, useTransferFundsWithDemo, useWithdrawFundsWithDemo } from '@/hooks/useWithDemo';
import { demoAuthService } from '@/utils/demoAuthService';

interface DeliveryJob {
  id: string;
  order_id: string;
  restaurant_name: string;
  stop_name: string;
  items_count: number;
  total: number;
  status: string;
}

const RiderDashboard = () => {
  const { toast } = useToast();
  const navigate = useNavigate();
  const { profile, signOut, user, isLoading: authLoading } = useAuthContext();
  useBackNavigation('/');
  
  const [isOnline, setIsOnline] = useState(false);
  const [currentJob, setCurrentJob] = useState<DeliveryJob | null>(null);
  const [availableJobs, setAvailableJobs] = useState<DeliveryJob[]>([]);
  const [earnings, setEarnings] = useState({ today: 0, total: 0 });
  const [deliveryAgentId, setDeliveryAgentId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [stationName, setStationName] = useState('Lusaka Main Station');
  const isDemoMode = demoAuthService.isDemoMode();

  // Wallet hooks
  const walletQuery = useWalletDataWithDemo();
  const walletTransactionsQuery = useWalletTransactionsWithDemo(5);
  const paymentMethodsQuery = usePaymentMethodsWithDemo();
  const addFundsMutation = useAddFundsWithDemo();
  const transferFundsMutation = useTransferFundsWithDemo();
  const withdrawFundsMutation = useWithdrawFundsWithDemo();

  const walletBalance = Number(walletQuery.data?.balance || 0);

  // Fetch station name (demo mode - skip Supabase)
  useEffect(() => {
    if (!profile?.assigned_station_id || isDemoMode) return;
    const fetch = async () => {
      const { data } = await supabase.from('stops').select('name').eq('id', profile.assigned_station_id).maybeSingle();
      if (data) setStationName(data.name);
    };
    fetch();
  }, [profile?.assigned_station_id, isDemoMode]);

  // Initialize delivery agent record (demo mode - skip Supabase)
  useEffect(() => {
    if (!user || !profile) { setLoading(false); return; }

    // In demo mode, skip Supabase and use generated ID
    if (isDemoMode) {
      setDeliveryAgentId(`demo_rider_${user.id}`);
      setLoading(false);
      return;
    }

    const initAgent = async () => {
      const { data: existingAgent } = await supabase
        .from('delivery_agents')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (existingAgent) {
        setDeliveryAgentId(existingAgent.id);
        setIsOnline(existingAgent.status === 'online');
      } else if (profile.assigned_station_id) {
        const { data: newAgent } = await supabase
          .from('delivery_agents')
          .insert({
            user_id: user.id,
            name: profile.full_name || 'Rider',
            phone: profile.phone || '',
            current_stop_id: profile.assigned_station_id,
            status: 'offline',
          })
          .select()
          .single();

        if (newAgent) setDeliveryAgentId(newAgent.id);
      }
      setLoading(false);
    };

    initAgent();
  }, [user, profile, isDemoMode]);

  // GPS Tracking (skip Supabase updates in demo mode)
  useEffect(() => {
    if (!isOnline || !deliveryAgentId || isDemoMode) return;

    const watchId = navigator.geolocation.watchPosition(
      async (pos) => {
        await supabase
          .from('delivery_agents')
          .update({
            current_position: toPostGISPoint(pos.coords.latitude, pos.coords.longitude) as unknown as null,
            heading: pos.coords.heading,
            last_gps_update: new Date().toISOString(),
          })
          .eq('id', deliveryAgentId);
      },
      (err) => console.error('GPS error:', err),
      { enableHighAccuracy: true, maximumAge: 5000 }
    );

    return () => navigator.geolocation.clearWatch(watchId);
  }, [isOnline, deliveryAgentId, isDemoMode]);

  const toggleOnline = async () => {
    if (!deliveryAgentId) return;
    const newStatus = !isOnline;
    if (!isDemoMode) {
      await supabase.from('delivery_agents').update({ status: newStatus ? 'online' : 'offline' }).eq('id', deliveryAgentId);
    }
    setIsOnline(newStatus);
    toast({ title: newStatus ? 'You are now online' : 'You are now offline' });
  };

  const acceptJob = async (job: DeliveryJob) => {
    if (!deliveryAgentId) return;
    if (!isDemoMode) {
      const { error } = await supabase.from('orders').update({ delivery_agent_id: deliveryAgentId, status: 'out_for_delivery' }).eq('id', job.order_id);
      if (error) {
        toast({ title: 'Error', description: 'Failed to accept job', variant: 'destructive' });
        return;
      }
    }
    setCurrentJob({ ...job, status: 'delivering' });
    setAvailableJobs(prev => prev.filter(j => j.id !== job.id));
    if (!isDemoMode) {
      await supabase.from('delivery_agents').update({ status: 'on_delivery' }).eq('id', deliveryAgentId);
    }
    toast({ title: 'Job Accepted' });
  };

  const completeDelivery = async () => {
    if (!currentJob || !deliveryAgentId) return;
    if (!isDemoMode) {
      await supabase.from('orders').update({ status: 'delivered' }).eq('id', currentJob.order_id);
      await supabase.from('delivery_agents').update({ status: 'online' }).eq('id', deliveryAgentId);
    }
    setEarnings(prev => ({ today: prev.today + 10, total: prev.total + 10 }));
    setCurrentJob(null);
    toast({ title: 'Delivery Complete!' });
  };

  if (authLoading || loading) {
    return <div className="min-h-screen flex items-center justify-center"><Loader2 className="w-8 h-8 animate-spin" /></div>;
  }

  // Show loading state while auth is loading in non-demo mode
  if (!isDemoMode && authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <div className="text-center space-y-4">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-primary" />
          <p className="text-muted-foreground">Loading your rider dashboard...</p>
        </div>
      </div>
    );
  }

  if (!profile?.is_approved) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2"><AlertCircle className="w-5 h-5 text-warning" /> Pending Approval</CardTitle>
            <CardDescription>Your rider account is pending admin approval.</CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => signOut()} variant="outline" className="w-full"><LogOut className="w-4 h-4 mr-2" /> Sign Out</Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!profile?.assigned_station_id) {
    // If demo mode is enabled, use demo data
    if (isDemoMode) {
      const demoProfile = demoAuthService.getDemoProfile();
      
      if (!demoProfile || !demoProfile.assigned_station_id) {
        return (
          <div className="min-h-screen flex items-center justify-center p-4">
            <Card className="max-w-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2"><MapPin className="w-5 h-5 text-warning" /> No Station Assigned</CardTitle>
                <CardDescription>Please contact admin or re-register with a station selected.</CardDescription>
              </CardHeader>
              <CardContent>
                <Button onClick={() => signOut()} variant="outline" className="w-full"><LogOut className="w-4 h-4 mr-2" /> Sign Out</Button>
              </CardContent>
            </Card>
          </div>
        );
      }
      // Continue with demo data (fall through to render)
    } else if (!authLoading) {
      // Real mode and auth has finished loading, but no station assigned
      return (
        <div className="min-h-screen flex items-center justify-center p-4">
          <Card className="max-w-md">
            <CardHeader>
              <CardTitle className="flex items-center gap-2"><MapPin className="w-5 h-5 text-warning" /> No Station Assigned</CardTitle>
              <CardDescription>Please contact admin or re-register with a station selected.</CardDescription>
            </CardHeader>
            <CardContent>
              <Button onClick={() => signOut()} variant="outline" className="w-full"><LogOut className="w-4 h-4 mr-2" /> Sign Out</Button>
            </CardContent>
          </Card>
        </div>
      );
    }
    // If authLoading is still true, just continue (profile should load soon)
  }

  // Use demo data as fallback if auth context hasn't updated yet
  const demoData = isDemoMode ? demoAuthService.getDemoProfile() : null;
  const displayProfile = profile || demoData;

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
              <Bike className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-bold">{displayProfile?.full_name || 'Rider'}</h1>
              <p className="text-xs text-muted-foreground flex items-center gap-1">
                <MapPin className="w-3 h-3" /> {stationName}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <Badge variant={isOnline ? 'default' : 'secondary'}>{isOnline ? 'Online' : 'Offline'}</Badge>
              <Switch checked={isOnline} onCheckedChange={toggleOnline} />
            </div>
            <Button variant="ghost" size="icon" onClick={() => signOut()}><LogOut className="w-5 h-5" /></Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        <div className="grid grid-cols-2 gap-4">
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2"><DollarSign className="w-5 h-5 text-journey-completed" /><span className="text-sm text-muted-foreground">Today</span></div>
              <p className="text-2xl font-bold">K{earnings.today}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2"><Package className="w-5 h-5 text-primary" /><span className="text-sm text-muted-foreground">Total Deliveries</span></div>
              <p className="text-2xl font-bold">{displayProfile?.total_trips || 0}</p>
            </CardContent>
          </Card>
        </div>

        {currentJob && (
          <Tabs defaultValue="delivery" className="space-y-4">
            <TabsList>
              <TabsTrigger value="delivery"><Package className="w-4 h-4 mr-2" /> Delivery</TabsTrigger>
              <TabsTrigger value="tracking"><MapPin className="w-4 h-4 mr-2" /> Live Tracking</TabsTrigger>
              <TabsTrigger value="history">Location History</TabsTrigger>
              <TabsTrigger value="wallet"><DollarSign className="w-4 h-4 mr-2" /> Wallet</TabsTrigger>
            </TabsList>

            <TabsContent value="delivery" className="space-y-4">
              <Card className="border-primary">
                <CardHeader><CardTitle className="flex items-center gap-2"><Package className="w-5 h-5" /> Active Delivery</CardTitle></CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-start gap-3">
                    <MapPin className="w-5 h-5 text-primary mt-0.5" />
                    <div>
                      <p className="font-medium">{currentJob.restaurant_name}</p>
                      <p className="text-sm text-muted-foreground">{currentJob.stop_name} Station</p>
                    </div>
                  </div>
                  <div className="bg-muted p-3 rounded"><p className="text-sm">{currentJob.items_count} items • K{currentJob.total}</p></div>
                  <div className="flex gap-2">
                    <Button variant="outline" className="flex-1"><Navigation className="w-4 h-4 mr-2" /> Navigate</Button>
                    <Button className="flex-1 bg-journey-completed" onClick={completeDelivery}><CheckCircle2 className="w-4 h-4 mr-2" /> Complete</Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="tracking" className="space-y-4">
              <div className="space-y-4">
                <div className="p-4 rounded-lg bg-blue-900/30 border border-blue-500/50 flex items-center gap-2">
                  <Radio className="w-5 h-5 text-blue-400 animate-pulse" />
                  <span className="text-blue-100">Live GPS tracking active - Updates every 5 seconds</span>
                </div>
                {user?.id && <GPSTrackingStatus riderId={user.id} showAlerts={true} />}
              </div>
            </TabsContent>

            <TabsContent value="history" className="space-y-4">
              {user?.id && <LocationHistory entityType="rider" entityId={user.id} hoursBack={24} />}
            </TabsContent>

            <TabsContent value="wallet" className="space-y-4">
              <DigitalWallet 
                balance={walletBalance}
                currency="ZMW"
                transactions={walletTransactionsQuery.data || []}
                paymentMethods={paymentMethodsQuery.data || []}
                onAddFunds={async (amount, method) => {
                  try {
                    await addFundsMutation.mutateAsync({ amount, paymentMethodId: method });
                    walletQuery.refetch();
                    toast({ title: 'Fund Added', description: `K${amount} added successfully.` });
                  } catch (error) {
                    toast({ title: 'Error', description: 'Failed to add funds.', variant: 'destructive' });
                  }
                }}
                onTransfer={async (recipient, amount) => {
                  try {
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    await (transferFundsMutation.mutateAsync as any)({ recipientEmail: recipient, amount });
                    walletQuery.refetch();
                    toast({ title: 'Transfer Completed', description: `K${amount} transferred successfully.` });
                  } catch (error) {
                    toast({ title: 'Error', description: 'Failed to transfer funds.', variant: 'destructive' });
                  }
                }}
                onWithdraw={async (amount, method) => {
                  try {
                    await withdrawFundsMutation.mutateAsync({ amount, paymentMethodId: method });
                    walletQuery.refetch();
                    toast({ title: 'Withdrawal Initiated', description: `K${amount} withdrawal initiated.` });
                  } catch (error) {
                    toast({ title: 'Error', description: 'Failed to process withdrawal.', variant: 'destructive' });
                  }
                }}
              />
            </TabsContent>
          </Tabs>
        )}

        {!currentJob && isOnline && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold">Available Deliveries</h2>
              <TextCallCentre stationName={stationName} onClose={() => {}} />
            </div>{availableJobs.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <Package className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">No deliveries available</p>
                  <p className="text-sm text-muted-foreground">New orders will appear here</p>
                </CardContent>
              </Card>
            ) : (
              availableJobs.map((job) => (
                <motion.div key={job.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                  <Card>
                    <CardContent className="py-4">
                      <div className="flex items-center justify-between mb-3">
                        <div>
                          <p className="font-medium">{job.restaurant_name}</p>
                          <p className="text-sm text-muted-foreground">{job.stop_name}</p>
                        </div>
                        <Badge>K10 fee</Badge>
                      </div>
                      <div className="flex items-center justify-between">
                        <span className="text-sm">{job.items_count} items • K{job.total}</span>
                        <Button size="sm" onClick={() => acceptJob(job)}>Accept</Button>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ))
            )}
          </div>
        )}

        {!isOnline && (
          <Card>
            <CardContent className="py-12 text-center">
              <AlertCircle className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
              <p className="text-muted-foreground">You are currently offline</p>
              <p className="text-sm text-muted-foreground mb-4">Go online to receive delivery requests</p>
              <Button onClick={toggleOnline}>Go Online</Button>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  );
};

export default RiderDashboard;
