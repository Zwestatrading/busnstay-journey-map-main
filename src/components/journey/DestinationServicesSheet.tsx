import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { supabase } from '@/integrations/supabase/client';
import { useAuthContext } from '@/contexts/useAuthContext';
import { Sheet, SheetContent, SheetHeader, SheetTitle } from '@/components/ui/sheet';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Hotel, Car, Star, MapPin, Bed, Users, Calendar, 
  CheckCircle2, Loader2, Moon, DollarSign 
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { Town } from '@/types/journey';

interface Accommodation {
  id: string;
  name: string;
  type: string;
  price_per_night: number;
  rating: number;
  rooms_available: number;
  is_night_arrival_friendly: boolean;
  distance_from_stop: number | null;
  amenities: string[];
  contact_phone: string | null;
}

interface TaxiDriver {
  id: string;
  vehicle_type: string;
  vehicle_color: string | null;
  vehicle_registration: string;
  rating: number;
  vehicle_capacity: number;
}

interface DestinationServicesSheetProps {
  town: Town;
  isOpen: boolean;
  onClose: () => void;
}

const DestinationServicesSheet = ({ town, isOpen, onClose }: DestinationServicesSheetProps) => {
  const { toast } = useToast();
  const { user } = useAuthContext();
  const [accommodations, setAccommodations] = useState<Accommodation[]>([]);
  const [taxis, setTaxis] = useState<TaxiDriver[]>([]);
  const [loading, setLoading] = useState(true);
  const [bookingAccommodation, setBookingAccommodation] = useState<Accommodation | null>(null);
  const [requestingTaxi, setRequestingTaxi] = useState(false);
  const [guests, setGuests] = useState(1);
  const [nights, setNights] = useState(1);
  const [dropoffAddress, setDropoffAddress] = useState('');
  const [submitting, setSubmitting] = useState(false);

  // Fetch accommodations and taxis for the destination stop
  useEffect(() => {
    if (!isOpen || !town) return;

    const fetchServices = async () => {
      setLoading(true);
      
      // We need to find the stop_id for this town
      const { data: stop } = await supabase
        .from('stops')
        .select('id')
        .eq('town_id', town.id)
        .maybeSingle();

      if (!stop) {
        setLoading(false);
        return;
      }

      const [accResult, taxiResult] = await Promise.all([
        supabase
          .from('accommodations')
          .select('*')
          .eq('stop_id', stop.id)
          .gt('rooms_available', 0),
        supabase
          .from('taxi_drivers')
          .select('*')
          .eq('station_id', stop.id)
          .eq('is_online', true)
          .eq('is_on_trip', false),
      ]);

      if (accResult.data) {
        setAccommodations(accResult.data.map(a => ({
          ...a,
          rating: Number(a.rating) || 4.0,
          rooms_available: a.rooms_available || 0,
          amenities: Array.isArray(a.amenities) ? a.amenities as string[] : [],
          distance_from_stop: a.distance_from_stop ? Number(a.distance_from_stop) : null,
        })));
      }
      
      if (taxiResult.data) {
        setTaxis(taxiResult.data.map(t => ({
          ...t,
          rating: Number(t.rating) || 5.0,
          vehicle_capacity: t.vehicle_capacity || 4,
        })));
      }

      setLoading(false);
    };

    fetchServices();
  }, [isOpen, town]);

  const handleBookAccommodation = async () => {
    if (!bookingAccommodation || !user) {
      toast({ title: 'Sign in required', description: 'Please sign in to book accommodation', variant: 'destructive' });
      return;
    }

    setSubmitting(true);
    const checkIn = new Date();
    const checkOut = new Date();
    checkOut.setDate(checkOut.getDate() + nights);

    const { error } = await supabase.from('accommodation_bookings').insert({
      user_id: user.id,
      accommodation_id: bookingAccommodation.id,
      check_in_date: checkIn.toISOString().split('T')[0],
      check_out_date: checkOut.toISOString().split('T')[0],
      guests,
      total_price: bookingAccommodation.price_per_night * nights,
      status: 'pending',
    });

    setSubmitting(false);

    if (error) {
      toast({ title: 'Booking Failed', description: error.message, variant: 'destructive' });
    } else {
      toast({ title: 'Booking Submitted! 🏨', description: `${nights} night(s) at ${bookingAccommodation.name}` });
      setBookingAccommodation(null);
    }
  };

  const handleRequestTaxi = async (taxi: TaxiDriver) => {
    if (!user) {
      toast({ title: 'Sign in required', description: 'Please sign in to request a taxi', variant: 'destructive' });
      return;
    }

    setSubmitting(true);

    const { data: stop } = await supabase
      .from('stops')
      .select('id')
      .eq('town_id', town.id)
      .maybeSingle();

    const fareEstimate = 50 + Math.random() * 100;

    const { error } = await supabase.from('taxi_rides').insert({
      passenger_user_id: user.id,
      driver_id: taxi.id,
      station_id: stop?.id,
      pickup_address: `${town.name} Bus Station`,
      dropoff_address: dropoffAddress || 'Home',
      ride_type: 'from_station',
      fare_estimate: Math.round(fareEstimate),
      status: 'pending',
    });

    setSubmitting(false);

    if (error) {
      toast({ title: 'Request Failed', description: error.message, variant: 'destructive' });
    } else {
      toast({ title: 'Taxi Requested! 🚕', description: `A ${taxi.vehicle_type} is being notified` });
      setRequestingTaxi(false);
      setDropoffAddress('');
    }
  };

  return (
    <Sheet open={isOpen} onOpenChange={(open) => !open && onClose()}>
      <SheetContent side="bottom" className="h-[85vh] rounded-t-3xl">
        <SheetHeader>
          <SheetTitle className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-primary" />
            Services at {town.name}
          </SheetTitle>
        </SheetHeader>

        {loading ? (
          <div className="flex items-center justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-primary" />
          </div>
        ) : (
          <Tabs defaultValue="accommodation" className="mt-4">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="accommodation" className="gap-1">
                <Hotel className="w-4 h-4" />
                Stay ({accommodations.length})
              </TabsTrigger>
              <TabsTrigger value="taxi" className="gap-1">
                <Car className="w-4 h-4" />
                Taxi ({taxis.length})
              </TabsTrigger>
            </TabsList>

            <TabsContent value="accommodation" className="mt-4 space-y-3 max-h-[60vh] overflow-y-auto">
              {bookingAccommodation ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
                  <Card className="border-primary">
                    <CardContent className="pt-4 space-y-4">
                      <h3 className="font-bold text-lg">{bookingAccommodation.name}</h3>
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                        <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
                        {bookingAccommodation.rating.toFixed(1)}
                        <span>•</span>
                        K{bookingAccommodation.price_per_night}/night
                        {bookingAccommodation.is_night_arrival_friendly && (
                          <Badge variant="outline" className="gap-1 ml-2">
                            <Moon className="w-3 h-3" /> Late check-in
                          </Badge>
                        )}
                      </div>

                      <div className="grid grid-cols-2 gap-3">
                        <div>
                          <Label>Guests</Label>
                          <Input type="number" min={1} max={10} value={guests} onChange={e => setGuests(Number(e.target.value))} />
                        </div>
                        <div>
                          <Label>Nights</Label>
                          <Input type="number" min={1} max={30} value={nights} onChange={e => setNights(Number(e.target.value))} />
                        </div>
                      </div>

                      <div className="bg-muted p-3 rounded-lg flex justify-between">
                        <span>Total</span>
                        <span className="font-bold">K{bookingAccommodation.price_per_night * nights}</span>
                      </div>

                      <div className="flex gap-2">
                        <Button variant="outline" className="flex-1" onClick={() => setBookingAccommodation(null)}>Back</Button>
                        <Button className="flex-1" onClick={handleBookAccommodation} disabled={submitting}>
                          {submitting ? <Loader2 className="w-4 h-4 animate-spin mr-2" /> : <CheckCircle2 className="w-4 h-4 mr-2" />}
                          Book Now
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ) : accommodations.length === 0 ? (
                <Card>
                  <CardContent className="py-8 text-center">
                    <Hotel className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                    <p className="text-muted-foreground">No accommodations available at this stop</p>
                  </CardContent>
                </Card>
              ) : (
                accommodations.map((acc) => (
                  <motion.div key={acc.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                    <Card className="hover:border-primary/50 transition-colors cursor-pointer" onClick={() => setBookingAccommodation(acc)}>
                      <CardContent className="py-4">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-2">
                              <h3 className="font-semibold">{acc.name}</h3>
                              <Badge variant="outline">{acc.type}</Badge>
                            </div>
                            <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground">
                              <span className="flex items-center gap-1">
                                <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                                {acc.rating.toFixed(1)}
                              </span>
                              <span className="flex items-center gap-1">
                                <Bed className="w-3 h-3" />
                                {acc.rooms_available} rooms
                              </span>
                              {acc.is_night_arrival_friendly && (
                                <span className="flex items-center gap-1 text-primary">
                                  <Moon className="w-3 h-3" /> Late OK
                                </span>
                              )}
                            </div>
                          </div>
                          <div className="text-right">
                            <p className="font-bold text-lg">K{acc.price_per_night}</p>
                            <p className="text-xs text-muted-foreground">/night</p>
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  </motion.div>
                ))
              )}
            </TabsContent>

            <TabsContent value="taxi" className="mt-4 space-y-3 max-h-[60vh] overflow-y-auto">
              {requestingTaxi ? (
                <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-4">
                  <Card>
                    <CardContent className="pt-4 space-y-4">
                      <Label>Where are you going?</Label>
                      <Input 
                        placeholder="Enter destination address or 'Home'" 
                        value={dropoffAddress} 
                        onChange={e => setDropoffAddress(e.target.value)} 
                      />
                      <p className="text-sm text-muted-foreground">Select a driver below to request a ride</p>
                    </CardContent>
                  </Card>
                  {taxis.map((taxi) => (
                    <Card key={taxi.id} className="hover:border-primary/50 transition-colors">
                      <CardContent className="py-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <div className="flex items-center gap-2">
                              <Car className="w-5 h-5 text-primary" />
                              <span className="font-medium capitalize">{taxi.vehicle_type}</span>
                              {taxi.vehicle_color && <span className="text-sm text-muted-foreground">({taxi.vehicle_color})</span>}
                            </div>
                            <div className="flex items-center gap-2 mt-1 text-sm text-muted-foreground">
                              <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" />
                              {taxi.rating.toFixed(1)}
                              <span>•</span>
                              <Users className="w-3 h-3" />
                              {taxi.vehicle_capacity} seats
                            </div>
                          </div>
                          <Button size="sm" onClick={() => handleRequestTaxi(taxi)} disabled={submitting}>
                            {submitting ? <Loader2 className="w-4 h-4 animate-spin" /> : 'Request'}
                          </Button>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                  <Button variant="outline" className="w-full" onClick={() => setRequestingTaxi(false)}>Back</Button>
                </motion.div>
              ) : taxis.length === 0 ? (
                <Card>
                  <CardContent className="py-8 text-center">
                    <Car className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                    <p className="text-muted-foreground">No taxis available at this stop</p>
                    <p className="text-sm text-muted-foreground mt-1">Taxis will appear when drivers go online</p>
                  </CardContent>
                </Card>
              ) : (
                <>
                  <Button className="w-full gap-2" onClick={() => setRequestingTaxi(true)}>
                    <Car className="w-4 h-4" />
                    Request a Taxi ({taxis.length} available)
                  </Button>
                  {taxis.map((taxi) => (
                    <Card key={taxi.id}>
                      <CardContent className="py-3">
                        <div className="flex items-center gap-3">
                          <Car className="w-5 h-5 text-muted-foreground" />
                          <div className="flex-1">
                            <span className="font-medium capitalize">{taxi.vehicle_type}</span>
                            <div className="flex items-center gap-2 text-xs text-muted-foreground">
                              <Star className="w-3 h-3 fill-yellow-400 text-yellow-400" /> {taxi.rating.toFixed(1)}
                              <span>•</span> {taxi.vehicle_capacity} seats
                            </div>
                          </div>
                          <Badge variant="outline" className="text-xs">Available</Badge>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </>
              )}
            </TabsContent>
          </Tabs>
        )}
      </SheetContent>
    </Sheet>
  );
};

export default DestinationServicesSheet;
