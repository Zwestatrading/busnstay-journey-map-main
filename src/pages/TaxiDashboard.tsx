import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { supabase } from '@/lib/supabase';
import { parsePostGISPoint, toPostGISPoint } from '@/types/database';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { 
  Car, MapPin, Navigation, User, CheckCircle2, LogOut, AlertCircle, Loader2, DollarSign, Star
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface TaxiRide {
  id: string;
  pickup_address: string;
  dropoff_address: string;
  ride_type: string;
  fare_estimate: number;
  status: string;
}

const TaxiDashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { profile, signOut, user, isLoading: authLoading } = useAuthContext();
  useBackNavigation('/');
  
  const [isOnline, setIsOnline] = useState(false);
  const [currentRide, setCurrentRide] = useState<TaxiRide | null>(null);
  const [availableRides, setAvailableRides] = useState<TaxiRide[]>([]);
  const [earnings, setEarnings] = useState({ today: 0, total: 0 });
  const [taxiDriverId, setTaxiDriverId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [stationName, setStationName] = useState('');

  useEffect(() => {
    if (!profile?.assigned_station_id) return;
    const fetch = async () => {
      const { data } = await supabase.from('stops').select('name').eq('id', profile.assigned_station_id).maybeSingle();
      if (data) setStationName(data.name);
    };
    fetch();
  }, [profile?.assigned_station_id]);

  // Initialize or auto-create taxi driver record
  useEffect(() => {
    if (!user || !profile || !profile.is_approved) { setLoading(false); return; }

    const initDriver = async () => {
      const { data: existingDriver } = await supabase
        .from('taxi_drivers')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (existingDriver) {
        setTaxiDriverId(existingDriver.id);
        setIsOnline(existingDriver.is_online ?? false);
        setEarnings({ today: 0, total: Number(existingDriver.earnings_total) || 0 });
      } else if (profile.assigned_station_id) {
        // Auto-create taxi driver record for approved provider
        const { data: newDriver } = await supabase
          .from('taxi_drivers')
          .insert({
            user_id: user.id,
            vehicle_registration: 'PENDING',
            station_id: profile.assigned_station_id,
            vehicle_type: 'sedan',
            is_online: false,
            profile_id: profile.id,
          })
          .select()
          .single();
        
        if (newDriver) {
          setTaxiDriverId(newDriver.id);
        }
      }
      setLoading(false);
    };

    initDriver();
  }, [user, profile]);

  const toggleOnline = async () => {
    if (!taxiDriverId) return;
    const newStatus = !isOnline;
    await supabase.from('taxi_drivers').update({ is_online: newStatus }).eq('id', taxiDriverId);
    setIsOnline(newStatus);
    toast({ title: newStatus ? 'You are now online' : 'You are now offline' });
  };

  const acceptRide = async (ride: TaxiRide) => {
    if (!taxiDriverId) return;
    const { error } = await supabase.from('taxi_rides').update({ driver_id: taxiDriverId, status: 'accepted' }).eq('id', ride.id);
    if (error) {
      toast({ title: 'Error', description: 'Failed to accept ride', variant: 'destructive' });
    } else {
      setCurrentRide({ ...ride, status: 'accepted' });
      setAvailableRides(prev => prev.filter(r => r.id !== ride.id));
      await supabase.from('taxi_drivers').update({ is_on_trip: true }).eq('id', taxiDriverId);
      toast({ title: 'Ride Accepted' });
    }
  };

  const startRide = async () => {
    if (!currentRide) return;
    await supabase.from('taxi_rides').update({ status: 'in_progress', started_at: new Date().toISOString() }).eq('id', currentRide.id);
    setCurrentRide({ ...currentRide, status: 'in_progress' });
    toast({ title: 'Ride Started' });
  };

  const completeRide = async () => {
    if (!currentRide || !taxiDriverId) return;
    const fare = currentRide.fare_estimate;
    await supabase.from('taxi_rides').update({ status: 'completed', fare_actual: fare, completed_at: new Date().toISOString() }).eq('id', currentRide.id);
    await supabase.from('taxi_drivers').update({ is_on_trip: false, earnings_total: earnings.total + fare }).eq('id', taxiDriverId);
    setEarnings(prev => ({ today: prev.today + fare, total: prev.total + fare }));
    setCurrentRide(null);
    toast({ title: 'Ride Complete!', description: `You earned K${fare}` });
  };

  if (authLoading || loading) {
    return <div className="min-h-screen flex items-center justify-center"><Loader2 className="w-8 h-8 animate-spin" /></div>;
  }

  if (!profile?.is_approved) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2"><AlertCircle className="w-5 h-5 text-warning" /> Pending Approval</CardTitle>
            <CardDescription>Your taxi driver account is pending admin approval.</CardDescription>
          </CardHeader>
          <CardContent><Button onClick={() => signOut()} variant="outline" className="w-full"><LogOut className="w-4 h-4 mr-2" /> Sign Out</Button></CardContent>
        </Card>
      </div>
    );
  }

  if (!profile?.assigned_station_id) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2"><MapPin className="w-5 h-5 text-warning" /> No Station Assigned</CardTitle>
            <CardDescription>Please contact admin or re-register with a station.</CardDescription>
          </CardHeader>
          <CardContent><Button onClick={() => signOut()} variant="outline" className="w-full"><LogOut className="w-4 h-4 mr-2" /> Sign Out</Button></CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
              <Car className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-bold">{profile?.full_name || 'Driver'}</h1>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                {profile?.rating?.toFixed(1) || '5.0'}
                <span>•</span>
                <MapPin className="w-3 h-3" /> {stationName}
              </div>
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
              <div className="flex items-center gap-2"><Car className="w-5 h-5 text-primary" /><span className="text-sm text-muted-foreground">Total Trips</span></div>
              <p className="text-2xl font-bold">{profile?.total_trips || 0}</p>
            </CardContent>
          </Card>
        </div>

        {currentRide && (
          <Card className="border-primary">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Car className="w-5 h-5" />
                {currentRide.status === 'accepted' ? 'Pickup Passenger' : 'In Progress'}
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-3">
                <div className="flex items-start gap-3">
                  <div className="w-3 h-3 rounded-full bg-journey-completed mt-1.5" />
                  <div><p className="text-sm text-muted-foreground">Pickup</p><p className="font-medium">{currentRide.pickup_address}</p></div>
                </div>
                <div className="flex items-start gap-3">
                  <div className="w-3 h-3 rounded-full bg-primary mt-1.5" />
                  <div><p className="text-sm text-muted-foreground">Dropoff</p><p className="font-medium">{currentRide.dropoff_address}</p></div>
                </div>
              </div>
              <div className="bg-muted p-3 rounded flex justify-between items-center"><span>Fare</span><span className="font-bold">K{currentRide.fare_estimate}</span></div>
              <div className="flex gap-2">
                <Button variant="outline" className="flex-1"><Navigation className="w-4 h-4 mr-2" /> Navigate</Button>
                {currentRide.status === 'accepted' ? (
                  <Button className="flex-1" onClick={startRide}><User className="w-4 h-4 mr-2" /> Start Ride</Button>
                ) : (
                  <Button className="flex-1 bg-journey-completed" onClick={completeRide}><CheckCircle2 className="w-4 h-4 mr-2" /> Complete</Button>
                )}
              </div>
            </CardContent>
          </Card>
        )}

        {!currentRide && isOnline && (
          <div className="space-y-4">
            <h2 className="font-semibold">Ride Requests</h2>
            {availableRides.length === 0 ? (
              <Card>
                <CardContent className="py-8 text-center">
                  <Car className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">No ride requests</p>
                  <p className="text-sm text-muted-foreground">New requests will appear here</p>
                </CardContent>
              </Card>
            ) : (
              availableRides.map((ride) => (
                <motion.div key={ride.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                  <Card>
                    <CardContent className="py-4 space-y-3">
                      <div className="flex justify-between items-start">
                        <Badge variant="outline">{ride.ride_type}</Badge>
                        <span className="font-bold text-lg">K{ride.fare_estimate}</span>
                      </div>
                      <div className="space-y-2">
                        <div className="flex items-center gap-2 text-sm"><div className="w-2 h-2 rounded-full bg-journey-completed" /> {ride.pickup_address}</div>
                        <div className="flex items-center gap-2 text-sm"><div className="w-2 h-2 rounded-full bg-primary" /> {ride.dropoff_address}</div>
                      </div>
                      <Button className="w-full" onClick={() => acceptRide(ride)}>Accept Ride</Button>
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
              <p className="text-sm text-muted-foreground mb-4">Go online to receive ride requests</p>
              <Button onClick={toggleOnline}>Go Online</Button>
            </CardContent>
          </Card>
        )}
      </main>
    </div>
  );
};

export default TaxiDashboard;
