import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { supabase } from '@/lib/supabase';
import { useSystemHealth } from '@/hooks/useSystemHealth';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { 
  Shield, Bus, Users, Utensils, Car, Bike, Hotel, 
  MapPin, AlertTriangle, CheckCircle2, XCircle, Activity,
  LogOut, RefreshCw, Loader2, TrendingUp, Clock, Package
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { LiveDeliveryMap } from '@/components/LiveDeliveryMap';
import { GPSTrackingStatus } from '@/components/GPSTrackingStatus';
import { LocationHistory } from '@/components/LocationHistory';

interface PendingApproval {
  id: string;
  user_id: string;
  full_name: string | null;
  email: string | null;
  role: string;
  business_name: string | null;
  phone: string | null;
  created_at: string;
}

const roleIcons: Record<string, typeof Bus> = {
  restaurant: Utensils,
  rider: Bike,
  taxi: Car,
  hotel: Hotel,
  passenger: Users,
};

const AdminDashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { profile, signOut, isLoading: authLoading } = useAuthContext();
  useBackNavigation('/');
  const { 
    events: healthEvents, 
    metrics, 
    startMonitoring, 
    stopMonitoring, 
    isMonitoring,
    autoFix 
  } = useSystemHealth();
  
  const [pendingApprovals, setPendingApprovals] = useState<PendingApproval[]>([]);
  const [loading, setLoading] = useState(true);
  const [activeRiders, setActiveRiders] = useState<unknown[]>([]);
  const [selectedRiderId, setSelectedRiderId] = useState<string | null>(null);
  const [stats, setStats] = useState({
    totalUsers: 0,
    activeJourneys: 0,
    pendingOrders: 0,
    onlineDrivers: 0,
  });

  // Fetch pending approvals
  useEffect(() => {
    const fetchPendingApprovals = async () => {
      const { data } = await supabase
        .from('user_profiles')
        .select('*')
        .eq('is_approved', false)
        .in('role', ['restaurant', 'rider', 'taxi', 'hotel'])
        .order('created_at', { ascending: false });

      if (data) {
        setPendingApprovals(data as unknown as PendingApproval[]);
      }
      setLoading(false);
    };

    fetchPendingApprovals();

    // Subscribe to new registrations
    const channel = supabase
      .channel('admin-approvals')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'user_profiles' },
        () => fetchPendingApprovals()
      )
      .subscribe();

    return () => { channel.unsubscribe(); };
  }, []);

  // Fetch platform stats
  useEffect(() => {
    const fetchStats = async () => {
      const [users, journeys, orders, drivers] = await Promise.all([
        supabase.from('user_profiles').select('id', { count: 'exact' }),
        supabase.from('journeys').select('id', { count: 'exact' }).eq('status', 'active'),
        supabase.from('orders').select('id', { count: 'exact' }).in('status', ['pending', 'preparing']),
        supabase.from('taxi_drivers').select('id', { count: 'exact' }).eq('is_online', true),
      ]);

      setStats({
        totalUsers: users.count || 0,
        activeJourneys: journeys.count || 0,
        pendingOrders: orders.count || 0,
        onlineDrivers: drivers.count || 0,
      });
    };

    fetchStats();
    const interval = setInterval(fetchStats, 30000);
    return () => clearInterval(interval);
  }, []);

  // Fetch active riders for delivery tracking
  useEffect(() => {
    const fetchActiveRiders = async () => {
      const { data } = await supabase
        .from('user_profiles')
        .select('id, full_name, phone')
        .eq('role', 'rider')
        .eq('is_online', true);
      
      if (data) setActiveRiders(data);
    };

    fetchActiveRiders();
    const interval = setInterval(fetchActiveRiders, 10000);
    return () => clearInterval(interval);
  }, []);

  // Start health monitoring
  useEffect(() => {
    startMonitoring();
    return () => stopMonitoring();
  }, [startMonitoring, stopMonitoring]);

  const approveUser = async (userId: string) => {
    const { error } = await supabase
      .from('user_profiles')
      .update({ is_approved: true })
      .eq('user_id', userId);

    if (error) {
      toast({ title: 'Error', description: 'Failed to approve user', variant: 'destructive' });
    } else {
      toast({ title: 'User Approved', description: 'User can now access their dashboard' });
      setPendingApprovals(prev => prev.filter(p => p.user_id !== userId));
    }
  };

  const rejectUser = async (userId: string) => {
    const { error } = await supabase
      .from('user_profiles')
      .delete()
      .eq('user_id', userId);

    if (error) {
      toast({ title: 'Error', description: 'Failed to reject user', variant: 'destructive' });
    } else {
      toast({ title: 'User Rejected', description: 'Registration rejected' });
      setPendingApprovals(prev => prev.filter(p => p.user_id !== userId));
    }
  };

  const handleAutoFix = async (event: typeof healthEvents[0]) => {
    const result = await autoFix(event);
    if (result.fixed) {
      toast({ title: 'Issue Fixed', description: result.notes });
    } else {
      toast({ title: 'Manual Fix Required', description: result.notes, variant: 'destructive' });
    }
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin" />
      </div>
    );
  }

  if (profile?.role !== 'admin') {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-destructive">
              <XCircle className="w-5 h-5" />
              Access Denied
            </CardTitle>
            <CardDescription>
              You don't have permission to access the admin dashboard.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => navigate('/')} className="w-full">
              Go to Home
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <header className="border-b bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
              <Shield className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-bold">Admin Dashboard</h1>
              <p className="text-xs text-muted-foreground">BusNStay Platform Control</p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <Badge variant={isMonitoring ? 'default' : 'secondary'} className="gap-1">
              <Activity className="w-3 h-3" />
              {isMonitoring ? 'Monitoring' : 'Paused'}
            </Badge>
            <Button variant="ghost" size="icon" onClick={() => signOut()}>
              <LogOut className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6">
        {/* Stats Grid */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2 mb-2">
                <Users className="w-5 h-5 text-primary" />
                <span className="text-sm text-muted-foreground">Total Users</span>
              </div>
              <p className="text-2xl font-bold">{stats.totalUsers}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2 mb-2">
                <Bus className="w-5 h-5 text-journey-active" />
                <span className="text-sm text-muted-foreground">Active Journeys</span>
              </div>
              <p className="text-2xl font-bold">{metrics.activeJourneys}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2 mb-2">
                <Package className="w-5 h-5 text-warning" />
                <span className="text-sm text-muted-foreground">Pending Orders</span>
              </div>
              <p className="text-2xl font-bold">{metrics.pendingOrders}</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="flex items-center gap-2 mb-2">
                <Car className="w-5 h-5 text-journey-completed" />
                <span className="text-sm text-muted-foreground">Online Drivers</span>
              </div>
              <p className="text-2xl font-bold">{metrics.onlineDrivers}</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="approvals" className="space-y-4">
          <TabsList>
            <TabsTrigger value="approvals">
              Approvals ({pendingApprovals.length})
            </TabsTrigger>
            <TabsTrigger value="delivery">
              <MapPin className="w-4 h-4 mr-2" />
              Delivery Tracking ({activeRiders.length})
            </TabsTrigger>
            <TabsTrigger value="health">
              System Health ({healthEvents.length})
            </TabsTrigger>
            <TabsTrigger value="metrics">
              Metrics
            </TabsTrigger>
          </TabsList>

          <TabsContent value="approvals" className="space-y-4">
            {pendingApprovals.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <CheckCircle2 className="w-12 h-12 mx-auto mb-4 text-journey-completed" />
                  <p className="text-muted-foreground">No pending approvals</p>
                </CardContent>
              </Card>
            ) : (
              pendingApprovals.map((approval) => {
                const RoleIcon = roleIcons[approval.role] || Users;
                return (
                  <motion.div
                    key={approval.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                  >
                    <Card>
                      <CardContent className="py-4">
                        <div className="flex items-start justify-between">
                          <div className="flex items-start gap-3">
                            <div className="w-10 h-10 rounded-lg bg-muted flex items-center justify-center">
                              <RoleIcon className="w-5 h-5" />
                            </div>
                            <div>
                              <p className="font-medium">{approval.full_name || 'Unknown'}</p>
                              <p className="text-sm text-muted-foreground">{approval.email}</p>
                              <div className="flex items-center gap-2 mt-1">
                                <Badge variant="outline">{approval.role}</Badge>
                                {approval.business_name && (
                                  <span className="text-sm text-muted-foreground">
                                    {approval.business_name}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                          <div className="flex gap-2">
                            <Button 
                              size="sm"
                              onClick={() => approveUser(approval.user_id)}
                            >
                              <CheckCircle2 className="w-4 h-4 mr-1" />
                              Approve
                            </Button>
                            <Button 
                              variant="destructive"
                              size="sm"
                              onClick={() => rejectUser(approval.user_id)}
                            >
                              <XCircle className="w-4 h-4" />
                            </Button>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </motion.div>
                );
              })
            )}
          </TabsContent>

          <TabsContent value="delivery" className="space-y-4">
            {activeRiders.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <MapPin className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">No active riders online</p>
                </CardContent>
              </Card>
            ) : (
              <div className="space-y-4">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                  {activeRiders.map((rider) => {
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    const riderId = (rider as any).id;
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    const riderFullName = (rider as any).full_name;
                    // eslint-disable-next-line @typescript-eslint/no-explicit-any
                    const riderPhone = (rider as any).phone;
                    return (
                      <motion.button
                        key={riderId}
                        onClick={() => setSelectedRiderId(selectedRiderId === riderId ? null : riderId)}
                        whileHover={{ scale: 1.02 }}
                        className={`p-3 rounded-lg border text-left transition-all ${
                          selectedRiderId === riderId
                            ? 'border-primary bg-primary/10'
                            : 'border-border hover:border-primary'
                        }`}
                      >
                        <div className="flex items-center gap-2 mb-1">
                          <Bike className="w-4 h-4 text-primary" />
                          <span className="font-medium text-sm">{riderFullName || 'Unknown'}</span>
                        </div>
                        <p className="text-xs text-muted-foreground">{riderPhone || 'No phone'}</p>
                      </motion.button>
                    );
                  })}
                </div>

                {selectedRiderId && (
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="space-y-4"
                  >
                    <GPSTrackingStatus riderId={selectedRiderId} showAlerts={true} />
                    <LocationHistory entityType="rider" entityId={selectedRiderId} hoursBack={24} />
                  </motion.div>
                )}
              </div>
            )}
          </TabsContent>

          <TabsContent value="health" className="space-y-4">
            {healthEvents.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <Activity className="w-12 h-12 mx-auto mb-4 text-journey-completed" />
                  <p className="text-muted-foreground">All systems operational</p>
                </CardContent>
              </Card>
            ) : (
              healthEvents.map((event) => (
                <motion.div
                  key={event.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                >
                  <Card className={
                    event.severity === 'critical' ? 'border-destructive' :
                    event.severity === 'warning' ? 'border-warning' : ''
                  }>
                    <CardContent className="py-4">
                      <div className="flex items-start justify-between">
                        <div className="flex items-start gap-3">
                          <AlertTriangle className={`w-5 h-5 ${
                            event.severity === 'critical' ? 'text-destructive' :
                            event.severity === 'warning' ? 'text-warning' : 'text-muted-foreground'
                          }`} />
                          <div>
                            <div className="flex items-center gap-2">
                              <p className="font-medium">{event.event_type.replace('_', ' ')}</p>
                              <Badge variant={
                                event.severity === 'critical' ? 'destructive' :
                                event.severity === 'warning' ? 'default' : 'secondary'
                              }>
                                {event.severity}
                              </Badge>
                            </div>
                            <p className="text-sm text-muted-foreground mt-1">
                              {event.description}
                            </p>
                            <p className="text-xs text-muted-foreground mt-1">
                              <Clock className="w-3 h-3 inline mr-1" />
                              {new Date(event.detected_at).toLocaleString()}
                            </p>
                          </div>
                        </div>
                        <Button 
                          size="sm" 
                          variant="outline"
                          onClick={() => handleAutoFix(event)}
                        >
                          <RefreshCw className="w-4 h-4 mr-1" />
                          Auto-Fix
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ))
            )}
          </TabsContent>

          <TabsContent value="metrics">
            <div className="grid grid-cols-2 md:grid-cols-3 gap-4">
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Riders Online</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold">{metrics.onlineRiders}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Unresolved Alerts</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold text-warning">{metrics.unresolvedAlerts}</p>
                </CardContent>
              </Card>
              <Card>
                <CardHeader>
                  <CardTitle className="text-sm font-medium">Avg GPS Latency</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="text-3xl font-bold">{metrics.avgGpsLatency}ms</p>
                </CardContent>
              </Card>
            </div>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

export default AdminDashboard;
