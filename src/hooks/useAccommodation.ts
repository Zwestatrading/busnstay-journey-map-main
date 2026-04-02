import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';

interface Accommodation {
  id: string;
  name: string;
  type: string;
  price_per_night: number;
  rating: number;
  rooms_available: number;
  distance_from_stop: number | null;
  amenities: string[];
  is_night_arrival_friendly: boolean;
  contact_phone: string | null;
}

interface Booking {
  id: string;
  accommodation_id: string;
  check_in_date: string;
  check_out_date: string;
  guests: number;
  total_price: number;
  status: string;
}

interface UseAccommodationOptions {
  stationId: string | null;
  enabled?: boolean;
}

export const useAccommodation = ({ stationId, enabled = true }: UseAccommodationOptions) => {
  const [accommodations, setAccommodations] = useState<Accommodation[]>([]);
  const [booking, setBooking] = useState<Booking | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch accommodations at station
  const fetchAccommodations = useCallback(async () => {
    if (!stationId || !enabled) return;

    try {
      const { data, error: fetchError } = await supabase
        .from('accommodations')
        .select('*')
        .eq('stop_id', stationId)
        .gt('rooms_available', 0)
        .order('rating', { ascending: false });

      if (fetchError) throw fetchError;

      const mapped: Accommodation[] = (data || []).map(a => ({
        id: a.id,
        name: a.name,
        type: a.type || 'hotel',
        price_per_night: Number(a.price_per_night),
        rating: Number(a.rating) || 4.0,
        rooms_available: a.rooms_available || 0,
        distance_from_stop: a.distance_from_stop ? Number(a.distance_from_stop) : null,
        amenities: Array.isArray(a.amenities) ? a.amenities as string[] : [],
        is_night_arrival_friendly: a.is_night_arrival_friendly || false,
        contact_phone: a.contact_phone,
      }));

      setAccommodations(mapped);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch accommodations');
    }
  }, [stationId, enabled]);

  // Book accommodation
  const bookAccommodation = useCallback(async (
    accommodationId: string,
    checkInDate: string,
    checkOutDate: string,
    guests: number = 1,
    journeyId?: string
  ) => {
    setIsLoading(true);
    setError(null);

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');

      // Get accommodation price
      const accommodation = accommodations.find(a => a.id === accommodationId);
      if (!accommodation) throw new Error('Accommodation not found');

      // Calculate nights
      const checkIn = new Date(checkInDate);
      const checkOut = new Date(checkOutDate);
      const nights = Math.ceil((checkOut.getTime() - checkIn.getTime()) / (1000 * 60 * 60 * 24));
      const totalPrice = nights * accommodation.price_per_night;

      const { data, error: bookError } = await supabase
        .from('accommodation_bookings')
        .insert({
          user_id: user.id,
          accommodation_id: accommodationId,
          journey_id: journeyId,
          check_in_date: checkInDate,
          check_out_date: checkOutDate,
          guests,
          total_price: totalPrice,
          status: 'pending',
        })
        .select()
        .single();

      if (bookError) throw bookError;

      setBooking(data as Booking);
      return data;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to book accommodation');
      return null;
    } finally {
      setIsLoading(false);
    }
  }, [accommodations]);

  // Cancel booking
  const cancelBooking = useCallback(async () => {
    if (!booking) return;

    try {
      const { error: cancelError } = await supabase
        .from('accommodation_bookings')
        .update({ status: 'cancelled' })
        .eq('id', booking.id);

      if (cancelError) throw cancelError;

      setBooking(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to cancel booking');
    }
  }, [booking]);

  // Fetch user's active booking
  const fetchActiveBooking = useCallback(async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data } = await supabase
        .from('accommodation_bookings')
        .select('*')
        .eq('user_id', user.id)
        .in('status', ['pending', 'confirmed'])
        .gte('check_out_date', new Date().toISOString().split('T')[0])
        .order('check_in_date', { ascending: true })
        .limit(1)
        .maybeSingle();

      if (data) {
        setBooking(data as Booking);
      }
    } catch (err) {
      console.error('Error fetching booking:', err);
    }
  }, []);

  useEffect(() => {
    fetchAccommodations();
    fetchActiveBooking();
  }, [fetchAccommodations, fetchActiveBooking]);

  return {
    accommodations,
    booking,
    isLoading,
    error,
    bookAccommodation,
    cancelBooking,
    refreshAccommodations: fetchAccommodations,
  };
};

export default useAccommodation;
