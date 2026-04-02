import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { 
  Hotel, Bed, Calendar, MapPin, Star, Users,
  CheckCircle2, XCircle, LogOut, AlertCircle, Loader2
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { RoomManagementTab } from '@/components/RoomManagementTab';

interface Booking {
  id: string;
  check_in_date: string;
  check_out_date: string;
  guests: number;
  total_price: number;
  status: string;
  created_at: string;
}

const HotelDashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { profile, signOut, isLoading: authLoading } = useAuthContext();
  useBackNavigation('/');
  
  const [isOpen, setIsOpen] = useState(true);
  const [bookings, setBookings] = useState<Booking[]>([]);
  const [accommodationId, setAccommodationId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({ pending: 0, confirmed: 0, checkedIn: 0 });
  const [stationName, setStationName] = useState('');

  useEffect(() => {
    if (!profile?.assigned_station_id) return;
    const fetch = async () => {
      const { data } = await supabase.from('stops').select('name').eq('id', profile.assigned_station_id).maybeSingle();
      if (data) setStationName(data.name);
    };
    fetch();
  }, [profile?.assigned_station_id]);

  // Fetch or auto-create accommodation record
  useEffect(() => {
    if (!profile?.assigned_station_id || !profile?.is_approved) { setLoading(false); return; }

    const fetchOrCreateAccommodation = async () => {
      const { data: accommodations } = await supabase
        .from('accommodations')
        .select('*')
        .eq('stop_id', profile.assigned_station_id)
        .limit(1);

      let accommodation = accommodations && accommodations.length > 0 ? accommodations[0] : null;

      // Auto-create accommodation record for approved hotel provider
      if (!accommodation) {
        const { data: newAccommodation, error } = await supabase
          .from('accommodations')
          .insert({
            name: profile.business_name || `${profile.full_name}'s Lodge`,
            stop_id: profile.assigned_station_id!,
            price_per_night: 250,
            type: 'hotel',
            is_night_arrival_friendly: true,
            rooms_available: 10,
          })
          .select()
          .single();

        if (!error && newAccommodation) {
          accommodation = newAccommodation;
        }
      }

      if (accommodation) {
        setAccommodationId(accommodation.id);
      }
      setLoading(false);
    };

    fetchOrCreateAccommodation();
  }, [profile]);

  useEffect(() => {
    if (!accommodationId) return;

    const fetchBookings = async () => {
      const { data } = await supabase
        .from('accommodation_bookings')
        .select('*')
        .eq('accommodation_id', accommodationId)
        .in('status', ['pending', 'confirmed', 'checked_in'])
        .order('check_in_date', { ascending: true });

      if (data) {
        setBookings(data as Booking[]);
        setStats({
          pending: data.filter(b => b.status === 'pending').length,
          confirmed: data.filter(b => b.status === 'confirmed').length,
          checkedIn: data.filter(b => b.status === 'checked_in').length,
        });
      }
    };

    fetchBookings();

    const channel = supabase
      .channel('hotel-bookings')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'accommodation_bookings', filter: `accommodation_id=eq.${accommodationId}` }, () => fetchBookings())
      .subscribe();

    return () => { channel.unsubscribe(); };
  }, [accommodationId]);

  const updateBookingStatus = async (bookingId: string, status: string) => {
    const { error } = await supabase.from('accommodation_bookings').update({ status }).eq('id', bookingId);
    if (error) {
      toast({ title: 'Error', description: 'Failed to update booking', variant: 'destructive' });
    } else {
      toast({ title: 'Booking Updated', description: `Booking ${status}` });
      setBookings(prev => prev.map(b => b.id === bookingId ? { ...b, status } : b));
    }
  };

  const formatDate = (dateStr: string) => new Date(dateStr).toLocaleDateString('en-ZM', { weekday: 'short', month: 'short', day: 'numeric' });
  const getNights = (checkIn: string, checkOut: string) => Math.ceil((new Date(checkOut).getTime() - new Date(checkIn).getTime()) / (1000 * 60 * 60 * 24));

  if (authLoading || loading) {
    return <div className="min-h-screen flex items-center justify-center"><Loader2 className="w-8 h-8 animate-spin" /></div>;
  }

  if (!profile?.is_approved) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2"><AlertCircle className="w-5 h-5 text-warning" /> Pending Approval</CardTitle>
            <CardDescription>Your hotel account is pending admin approval.</CardDescription>
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
              <Hotel className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-bold">{profile?.business_name || 'Hotel'}</h1>
              <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" /> {profile?.rating?.toFixed(1) || '4.5'}
                <span>•</span>
                <MapPin className="w-3 h-3" /> {stationName}
              </div>
            </div>
          </div>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="text-sm">{isOpen ? 'Accepting' : 'Not Accepting'}</span>
              <Switch checked={isOpen} onCheckedChange={setIsOpen} />
            </div>
            <Button variant="ghost" size="icon" onClick={() => signOut()}><LogOut className="w-5 h-5" /></Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-3 gap-4 mb-6">
          <Card><CardContent className="pt-4"><div className="text-2xl font-bold text-warning">{stats.pending}</div><p className="text-sm text-muted-foreground">Pending</p></CardContent></Card>
          <Card><CardContent className="pt-4"><div className="text-2xl font-bold text-primary">{stats.confirmed}</div><p className="text-sm text-muted-foreground">Confirmed</p></CardContent></Card>
          <Card><CardContent className="pt-4"><div className="text-2xl font-bold text-journey-completed">{stats.checkedIn}</div><p className="text-sm text-muted-foreground">Checked In</p></CardContent></Card>
        </div>

        <Tabs defaultValue="bookings" className="space-y-4">
          <TabsList>
            <TabsTrigger value="bookings">Bookings ({bookings.length})</TabsTrigger>
            <TabsTrigger value="rooms">Rooms</TabsTrigger>
            <TabsTrigger value="calendar">Calendar</TabsTrigger>
          </TabsList>

          <TabsContent value="bookings" className="space-y-4">
            {bookings.length === 0 ? (
              <Card><CardContent className="py-12 text-center"><Bed className="w-12 h-12 mx-auto mb-4 text-muted-foreground" /><p className="text-muted-foreground">No active bookings</p></CardContent></Card>
            ) : (
              bookings.map((booking) => (
                <motion.div key={booking.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                  <Card className={booking.status === 'pending' ? 'border-warning' : ''}>
                    <CardContent className="py-4">
                      <div className="flex items-start justify-between mb-3">
                        <Badge variant={booking.status === 'pending' ? 'destructive' : booking.status === 'confirmed' ? 'default' : 'secondary'}>{booking.status.replace('_', ' ').toUpperCase()}</Badge>
                        <span className="font-bold text-lg">K{booking.total_price}</span>
                      </div>
                      <div className="space-y-2 mb-4">
                        <div className="flex items-center gap-2 text-sm">
                          <Calendar className="w-4 h-4 text-muted-foreground" />
                          {formatDate(booking.check_in_date)} → {formatDate(booking.check_out_date)}
                          <span className="text-muted-foreground">({getNights(booking.check_in_date, booking.check_out_date)} nights)</span>
                        </div>
                        <div className="flex items-center gap-2 text-sm"><Users className="w-4 h-4 text-muted-foreground" /> {booking.guests} guest{(booking.guests || 1) > 1 ? 's' : ''}</div>
                      </div>
                      <div className="flex gap-2">
                        {booking.status === 'pending' && (
                          <>
                            <Button className="flex-1" onClick={() => updateBookingStatus(booking.id, 'confirmed')}><CheckCircle2 className="w-4 h-4 mr-2" /> Confirm</Button>
                            <Button variant="destructive" onClick={() => updateBookingStatus(booking.id, 'rejected')}><XCircle className="w-4 h-4" /></Button>
                          </>
                        )}
                        {booking.status === 'confirmed' && (<Button className="flex-1 bg-journey-completed" onClick={() => updateBookingStatus(booking.id, 'checked_in')}><CheckCircle2 className="w-4 h-4 mr-2" /> Check In</Button>)}
                        {booking.status === 'checked_in' && (<Button variant="outline" className="flex-1" onClick={() => updateBookingStatus(booking.id, 'checked_out')}>Check Out</Button>)}
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ))
            )}
          </TabsContent>

          <TabsContent value="rooms">
            {accommodationId && <RoomManagementTab accommodationId={accommodationId} />}
          </TabsContent>

          <TabsContent value="calendar">
            <Card><CardContent className="py-8 text-center"><Calendar className="w-12 h-12 mx-auto mb-4 text-muted-foreground" /><p className="text-muted-foreground">Calendar view coming soon</p></CardContent></Card>
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

export default HotelDashboard;
