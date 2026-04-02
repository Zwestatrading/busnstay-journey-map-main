import { useEffect, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { useAuthContext } from '@/contexts/useAuthContext';
import { RealtimeChannel } from '@supabase/supabase-js';

export interface GPSLocation {
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: string;
}

export interface DeliveryJob {
  id: string;
  order_id: string;
  rider_id: string;
  status: 'pending' | 'accepted' | 'in_transit' | 'delivered' | 'cancelled';
  origin_stop_id: string;
  destination_stop_id: string;
  estimated_delivery_time: string;
  created_at: string;
  updated_at: string;
}

export interface RiderLocation {
  rider_id: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: string;
}

// Hook for real-time rider location tracking
export const useRiderLocation = (riderId: string | null, enabled = true) => {
  const [location, setLocation] = useState<RiderLocation | null>(null);
  const [isTracking, setIsTracking] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const channelRef = useRef<RealtimeChannel | null>(null);

  // Update location in database
  const updateLocation = useCallback(
    async (latitude: number, longitude: number, accuracy: number) => {
      if (!riderId) return;

      try {
        const { error } = await supabase.from('rider_locations').upsert(
          {
            rider_id: riderId,
            latitude,
            longitude,
            accuracy,
            timestamp: new Date().toISOString(),
          },
          { onConflict: 'rider_id' }
        );

        if (error) throw error;

        setLocation({
          rider_id: riderId,
          latitude,
          longitude,
          accuracy,
          timestamp: new Date().toISOString(),
        });
      } catch (err) {
        console.error('Error updating location:', err);
      }
    },
    [riderId]
  );

  // Start tracking rider location from device GPS
  const startTracking = useCallback(() => {
    if (!navigator.geolocation) {
      setError('Geolocation not supported');
      return;
    }

    setIsTracking(true);

    // Get initial position
    navigator.geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords;
        updateLocation(latitude, longitude, accuracy);
      },
      (err) => {
        console.error('GPS error:', err);
        setError(err.message);
      }
    );

    // Watch position updates every 10 seconds
    const watchId = navigator.geolocation.watchPosition(
      (position) => {
        const { latitude, longitude, accuracy } = position.coords;
        updateLocation(latitude, longitude, accuracy);
      },
      (err) => console.error('GPS watch error:', err),
      { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
    );

    return () => {
      navigator.geolocation.clearWatch(watchId);
      setIsTracking(false);
    };
  }, [updateLocation]);

  // Subscribe to real-time location updates
  useEffect(() => {
    if (!riderId || !enabled) return;

    channelRef.current = supabase
      .channel(`rider_location:${riderId}`)
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'rider_locations',
          filter: `rider_id=eq.${riderId}`,
        },
        (payload) => {
          setLocation(payload.new as RiderLocation);
        }
      )
      .subscribe();

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
      }
    };
  }, [riderId, enabled]);

  return { location, isTracking, error, startTracking };
};

// Import useRef
import { useRef } from 'react';

// Hook for active delivery jobs
export const useActiveDeliveryJobs = (riderId: string | null) => {
  const [jobs, setJobs] = useState<DeliveryJob[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!riderId) return;

    const fetchJobs = async () => {
      setLoading(true);
      try {
        const { data, error } = await supabase
          .from('delivery_jobs')
          .select('*')
          .eq('rider_id', riderId)
          .in('status', ['pending', 'accepted', 'in_transit'])
          .order('created_at', { ascending: false });

        if (error) throw error;
        setJobs(data || []);
      } catch (err) {
        console.error('Error fetching jobs:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch jobs');
      } finally {
        setLoading(false);
      }
    };

    fetchJobs();

    // Subscribe to job updates
    const channel = supabase
      .channel(`delivery_jobs:${riderId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'delivery_jobs',
          filter: `rider_id=eq.${riderId}`,
        },
        () => {
          fetchJobs(); // Refresh on any change
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [riderId]);

  return { jobs, loading, error };
};

// Hook for station details with restaurants
export interface StopData {
  id: string;
  name: string;
  latitude: string;
  longitude: string;
  [key: string]: unknown;
}

export interface RestaurantData {
  id: string;
  name: string;
  assigned_station_id: string;
  is_approved: boolean;
  [key: string]: unknown;
}

export const useStationWithRestaurants = (stationId: string | null) => {
  const [station, setStation] = useState<StopData | null>(null);
  const [restaurants, setRestaurants] = useState<RestaurantData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!stationId) return;

    const fetchStationData = async () => {
      setLoading(true);
      try {
        // Fetch station
        const { data: stationData, error: stationError } = await supabase
          .from('stops')
          .select('*')
          .eq('id', stationId)
          .single();

        if (stationError) throw stationError;
        setStation(stationData);

        // Fetch restaurants at this station
        const { data: restaurantData, error: restaurantError } = await supabase
          .from('restaurants')
          .select('*')
          .eq('assigned_station_id', stationId)
          .eq('is_approved', true);

        if (restaurantError) throw restaurantError;
        setRestaurants(restaurantData || []);
      } catch (err) {
        console.error('Error fetching station data:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch station');
      } finally {
        setLoading(false);
      }
    };

    fetchStationData();
  }, [stationId]);

  return { station, restaurants, loading, error };
};

export interface OrderData {
  id: string;
  order_id: string;
  customer_name: string;
  total: number;
  status: 'ready' | 'preparing' | 'pending' | 'cancelled';
  estimated_time: string;
  order_items?: Array<{
    item_name: string;
    quantity: number;
    special_instructions?: string;
  }>;
  [key: string]: unknown;
}

// Hook for restaurant orders ready for pickup
export const useRestaurantOrders = (restaurantId: string | null) => {
  const [orders, setOrders] = useState<OrderData[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!restaurantId) return;

    const fetchOrders = async () => {
      setLoading(true);
      try {
        const { data, error } = await supabase
          .from('orders')
          .select(
            `
            id, order_id, customer_name, total, status, estimated_time,
            order_items (item_name, quantity, special_instructions)
          `
          )
          .eq('restaurant_id', restaurantId)
          .in('status', ['ready', 'preparing', 'pending'])
          .order('created_at', { ascending: true });

        if (error) throw error;
        setOrders(data || []);
      } catch (err) {
        console.error('Error fetching orders:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch orders');
      } finally {
        setLoading(false);
      }
    };

    fetchOrders();

    // Subscribe to order updates
    const channel = supabase
      .channel(`restaurant_orders:${restaurantId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders',
          filter: `restaurant_id=eq.${restaurantId}`,
        },
        () => {
          fetchOrders(); // Refresh on any change
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [restaurantId]);

  return { orders, loading, error };
};

// Hook for calculating route between stops
export interface RouteData {
  origin: StopData;
  destination: StopData;
  distance: number;
  estimatedTime: number;
  [key: string]: unknown;
}

export const useCalculateRoute = (
  originStopId: string | null,
  destinationStopId: string | null
) => {
  const [route, setRoute] = useState<RouteData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!originStopId || !destinationStopId) return;

    const calculateRoute = async () => {
      setLoading(true);
      try {
        // Fetch stop coordinates
        const { data: stops, error: stopsError } = await supabase
          .from('stops')
          .select('id, name, latitude, longitude')
          .in('id', [originStopId, destinationStopId]);

        if (stopsError) throw stopsError;

        // In real app, use Google Maps API to calculate route
        // For now, return basic route with stops
        const originStop = stops?.find((s) => s.id === originStopId);
        const destStop = stops?.find((s) => s.id === destinationStopId);

        if (originStop && destStop) {
          // Calculate distance (simplified)
          const distance = calculateDistance(
            originStop.latitude,
            originStop.longitude,
            destStop.latitude,
            destStop.longitude
          );

          setRoute({
            origin: originStop,
            destination: destStop,
            distance,
            estimatedTime: Math.ceil(distance / 30) * 60, // 30 km/h average
          });
        }
      } catch (err) {
        console.error('Error calculating route:', err);
        setError(err instanceof Error ? err.message : 'Failed to calculate route');
      } finally {
        setLoading(false);
      }
    };

    calculateRoute();
  }, [originStopId, destinationStopId]);

  return { route, loading, error };
};

// Helper function to calculate distance between coordinates (Haversine formula)
function calculateDistance(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number {
  const R = 6371; // Radius of the Earth in km
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}
