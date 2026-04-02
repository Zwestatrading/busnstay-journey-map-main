import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { parsePostGISPoint } from '@/types/database';

interface TaxiDriver {
  id: string;
  name: string;
  vehicle_type: string;
  vehicle_color: string | null;
  rating: number;
  position: [number, number] | null;
  heading: number | null;
}

interface TaxiRide {
  id: string;
  driver_id: string | null;
  status: string;
  pickup_address: string;
  dropoff_address: string;
  fare_estimate: number;
  fare_actual: number | null;
}

interface UseTaxiServiceOptions {
  stationId: string | null;
  enabled?: boolean;
}

export const useTaxiService = ({ stationId, enabled = true }: UseTaxiServiceOptions) => {
  const [drivers, setDrivers] = useState<TaxiDriver[]>([]);
  const [activeRide, setActiveRide] = useState<TaxiRide | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Fetch available drivers at station
  const fetchDrivers = useCallback(async () => {
    if (!stationId || !enabled) return;

    try {
      const { data, error: fetchError } = await supabase
        .from('taxi_drivers')
        .select('*')
        .eq('station_id', stationId)
        .eq('is_online', true)
        .eq('is_on_trip', false);

      if (fetchError) throw fetchError;

      const mapped: TaxiDriver[] = (data || []).map(d => ({
        id: d.id,
        name: d.vehicle_registration || 'Driver',
        vehicle_type: d.vehicle_type || 'sedan',
        vehicle_color: d.vehicle_color,
        rating: Number(d.rating) || 5.0,
        position: parsePostGISPoint(d.current_position as string),
        heading: d.heading ? Number(d.heading) : null,
      }));

      setDrivers(mapped);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch drivers');
    }
  }, [stationId, enabled]);

  // Request a ride
  const requestRide = useCallback(async (
    pickupAddress: string,
    dropoffAddress: string,
    rideType: 'to_accommodation' | 'to_home' | 'custom' = 'custom',
    accommodationId?: string
  ) => {
    if (!stationId) {
      setError('No station selected');
      return null;
    }

    setIsLoading(true);
    setError(null);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/taxi-service`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            action: 'create',
            station_id: stationId,
            pickup_address: pickupAddress,
            dropoff_address: dropoffAddress,
            ride_type: rideType,
            accommodation_id: accommodationId,
          }),
        }
      );

      const result = await response.json();
      if (!response.ok) throw new Error(result.error);

      setActiveRide(result.ride);
      return result;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to request ride');
      return null;
    } finally {
      setIsLoading(false);
    }
  }, [stationId]);

  // Cancel ride
  const cancelRide = useCallback(async () => {
    if (!activeRide) return;

    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (!session) throw new Error('Not authenticated');

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/taxi-service`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${session.access_token}`,
          },
          body: JSON.stringify({
            action: 'update_status',
            ride_id: activeRide.id,
            status: 'cancelled',
          }),
        }
      );

      if (!response.ok) {
        const result = await response.json();
        throw new Error(result.error);
      }

      setActiveRide(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to cancel ride');
    }
  }, [activeRide]);

  // Subscribe to driver updates
  useEffect(() => {
    if (!stationId || !enabled) return;

    fetchDrivers();

    const channel = supabase
      .channel(`taxi-drivers-${stationId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'taxi_drivers',
          filter: `station_id=eq.${stationId}`,
        },
        () => fetchDrivers()
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [stationId, enabled, fetchDrivers]);

  // Subscribe to ride updates
  useEffect(() => {
    if (!activeRide) return;

    const channel = supabase
      .channel(`taxi-ride-${activeRide.id}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'taxi_rides',
          filter: `id=eq.${activeRide.id}`,
        },
        (payload) => {
          setActiveRide(prev => prev ? { ...prev, ...payload.new } : null);
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [activeRide?.id]);

  return {
    drivers,
    activeRide,
    isLoading,
    error,
    requestRide,
    cancelRide,
    refreshDrivers: fetchDrivers,
  };
};

export default useTaxiService;
