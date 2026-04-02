import { supabase } from '@/lib/supabase';
import { RealtimeChannel } from '@supabase/supabase-js';

interface LocationUpdate {
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  heading?: number;
}

interface RiderLocation {
  id: string;
  rider_id: string;
  current_location: string;
  latitude: number;
  longitude: number;
  is_online: boolean;
  is_on_delivery: boolean;
  speed_kmh?: number;
  accuracy?: number; // GPS accuracy in meters
  last_update: string;
}

interface DeliveryLocation {
  id: string;
  order_id: string;
  delivery_agent_id: string;
  latitude: number;
  longitude: number;
  status: string;
  distance_remaining_km?: number;
  estimated_arrival?: string;
  speed_kmh?: number;
  last_update: string;
}

/**
 * Update rider's location in real-time
 */
export const updateRiderLocation = async (
  riderId: string,
  location: LocationUpdate,
  journeyId?: string
): Promise<string | null> => {
  try {
    const { data, error } = await supabase.rpc(
      'update_rider_location',
      {
        p_rider_id: riderId,
        p_latitude: location.latitude,
        p_longitude: location.longitude,
        p_accuracy_meters: location.accuracy,
        p_speed_kmh: location.speed,
        p_heading: location.heading,
        p_journey_id: journeyId,
      }
    );

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error updating rider location:', error);
    return null;
  }
};

/**
 * Update delivery location in real-time
 */
export const updateDeliveryLocation = async (
  orderId: string,
  agentId: string,
  agentType: 'rider' | 'taxi_driver',
  location: LocationUpdate,
  estimatedArrival?: Date
): Promise<string | null> => {
  try {
    const { data, error } = await supabase.rpc(
      'update_delivery_location',
      {
        p_order_id: orderId,
        p_agent_id: agentId,
        p_agent_type: agentType,
        p_latitude: location.latitude,
        p_longitude: location.longitude,
        p_accuracy_meters: location.accuracy,
        p_speed_kmh: location.speed,
        p_heading: location.heading,
        p_estimated_arrival: estimatedArrival?.toISOString(),
      }
    );

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error updating delivery location:', error);
    return null;
  }
};

/**
 * Get rider's current location
 */
export const getRiderLocation = async (riderId: string): Promise<RiderLocation | null> => {
  try {
    const { data, error } = await supabase
      .from('rider_locations')
      .select('*')
      .eq('rider_id', riderId)
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error fetching rider location:', error);
    return null;
  }
};

/**
 * Get delivery location (for orders)
 */
export const getDeliveryLocation = async (orderId: string): Promise<DeliveryLocation | null> => {
  try {
    const { data, error } = await supabase
      .from('delivery_locations')
      .select('*')
      .eq('order_id', orderId)
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error fetching delivery location:', error);
    return null;
  }
};

/**
 * Subscribe to rider location updates (real-time)
 */
export const subscribeToRiderLocation = (
  riderId: string,
  callback: (location: RiderLocation) => void
): RealtimeChannel | null => {
  try {
    const channel = supabase
      .channel(`rider_location:${riderId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'rider_locations',
          filter: `rider_id=eq.${riderId}`,
        },
        (payload) => {
          if (payload.new) {
            callback(payload.new as RiderLocation);
          }
        }
      )
      .subscribe();

    return channel;
  } catch (error) {
    console.error('Error subscribing to rider location:', error);
    return null;
  }
};

/**
 * Subscribe to delivery location updates (real-time)
 */
export const subscribeToDeliveryLocation = (
  orderId: string,
  callback: (location: DeliveryLocation) => void
): RealtimeChannel | null => {
  try {
    const channel = supabase
      .channel(`delivery_location:${orderId}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'delivery_locations',
          filter: `order_id=eq.${orderId}`,
        },
        (payload) => {
          if (payload.new) {
            callback(payload.new as DeliveryLocation);
          }
        }
      )
      .subscribe();

    return channel;
  } catch (error) {
    console.error('Error subscribing to delivery location:', error);
    return null;
  }
};

/**
 * Unsubscribe from location updates
 */
export const unsubscribeFromLocation = (channel: RealtimeChannel): void => {
  supabase.removeChannel(channel);
};

/**
 * Get location history for a rider
 */
export const getRiderLocationHistory = async (
  riderId: string,
  hoursBack: number = 24
) => {
  try {
    const cutoffTime = new Date(Date.now() - hoursBack * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('location_history')
      .select('*')
      .eq('entity_type', 'rider')
      .eq('entity_id', riderId)
      .gte('recorded_at', cutoffTime)
      .order('recorded_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching location history:', error);
    return [];
  }
};

/**
 * Get location history for a delivery
 */
export const getDeliveryLocationHistory = async (
  orderId: string,
  hoursBack: number = 24
) => {
  try {
    const cutoffTime = new Date(Date.now() - hoursBack * 60 * 60 * 1000).toISOString();

    const { data, error } = await supabase
      .from('location_history')
      .select('*')
      .eq('entity_type', 'delivery')
      .eq('entity_id', orderId)
      .gte('recorded_at', cutoffTime)
      .order('recorded_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching delivery location history:', error);
    return [];
  }
};

/**
 * Create geofence alert (e.g., arriving at destination)
 */
export const createGeofenceAlert = async (
  riderId: string | null,
  deliveryId: string | null,
  alertType: 'geofence_enter' | 'geofence_exit' | 'speed_alert' | 'off_route',
  message: string,
  latitude?: number,
  longitude?: number,
  radiusKm: number = 0.5
) => {
  try {
    const { data, error } = await supabase
      .from('geofence_alerts')
      .insert({
        rider_id: riderId,
        delivery_id: deliveryId,
        alert_type: alertType,
        alert_message: message,
        geofence_location: latitude && longitude ? 
          { type: 'Point', coordinates: [longitude, latitude] } : null,
        geofence_radius_km: radiusKm,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error creating geofence alert:', error);
    return null;
  }
};

/**
 * Acknowledge geofence alert
 */
export const acknowledgeGeofenceAlert = async (alertId: string) => {
  try {
    const { data, error } = await supabase
      .from('geofence_alerts')
      .update({
        is_acknowledged: true,
        acknowledged_at: new Date().toISOString(),
      })
      .eq('id', alertId)
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error acknowledging alert:', error);
    return null;
  }
};

/**
 * Get pending geofence alerts for a rider
 */
export const getPendingGeofenceAlerts = async (riderId: string) => {
  try {
    const { data, error } = await supabase
      .from('geofence_alerts')
      .select('*')
      .eq('rider_id', riderId)
      .eq('is_acknowledged', false)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching geofence alerts:', error);
    return [];
  }
};

/**
 * Subscribe to geofence alerts for a rider
 */
export const subscribeToGeofenceAlerts = (
  riderId: string,
  callback: (alert: unknown) => void
): RealtimeChannel | null => {
  try {
    const channel = supabase
      .channel(`geofence_alerts:${riderId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'geofence_alerts',
          filter: `rider_id=eq.${riderId}`,
        },
        (payload) => {
          if (payload.new) {
            callback(payload.new);
          }
        }
      )
      .subscribe();

    return channel;
  } catch (error) {
    console.error('Error subscribing to geofence alerts:', error);
    return null;
  }
};

/**
 * Check if location is speeding (speed > 60 km/h in city)
 */
export const isLocationSpeeding = (speedKmh?: number): boolean => {
  if (!speedKmh) return false;
  return speedKmh > 60; // City speed limit assumption
};

/**
 * Get most recent locations for multiple riders
 */
export const getRidersLocations = async (riderIds: string[]) => {
  try {
    const { data, error } = await supabase
      .from('rider_locations')
      .select('*')
      .in('rider_id', riderIds);

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching riders locations:', error);
    return [];
  }
};
