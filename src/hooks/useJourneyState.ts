/**
 * useJourneyState Hook
 * Manages journey lifecycle, persistence, and auto-restore
 */

import { useEffect, useState, useCallback, useRef } from 'react';
import { supabase } from '@/lib/supabase';
import { offlineQueue } from '@/lib/offlineQueue';

export interface Journey {
  id: string;
  passenger_id: string;
  bus_id?: string;
  from_stop_id?: string;
  to_stop_id?: string;
  status: 'ACTIVE' | 'COMPLETED' | 'CANCELLED';
  start_time: string;
  end_time?: string;
  estimated_arrival?: string;
  current_latitude?: number;
  current_longitude?: number;
  distance_to_destination?: number;
  offline_queue_count: number;
  last_sync_time?: string;
  device_id?: string;
  created_at: string;
  updated_at: string;
}

interface UseJourneyStateReturn {
  journey: Journey | null;
  isLoading: boolean;
  error: string | null;
  startJourney: (fromStopId: string, toStopId: string, busId: string) => Promise<Journey>;
  endJourney: () => Promise<void>;
  updateLocation: (latitude: number, longitude: number, accuracy: number) => Promise<void>;
  autoRestore: () => Promise<Journey | null>;
  syncQueuedData: () => Promise<void>;
  queueStats: { total: number; pending: number; synced: number };
}

export function useJourneyState(passengerId: string | null): UseJourneyStateReturn {
  const [journey, setJourney] = useState<Journey | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [queueStats, setQueueStats] = useState({ total: 0, pending: 0, synced: 0 });

  // Get or create device ID
  const getDeviceId = (): string => {
    let id = localStorage.getItem('device_id');
    if (!id) {
      id = `device_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      localStorage.setItem('device_id', id);
    }
    return id;
  };

  const deviceIdRef = useRef<string>(getDeviceId());

  // Initialize offline queue on mount
  useEffect(() => {
    offlineQueue.init().catch((err) => console.error('Failed to initialize offline queue:', err));
  }, []);

  /**
   * Auto-restore active journey on app open
   */
  const autoRestore = useCallback(async (): Promise<Journey | null> => {
    if (!passengerId) return null;

    try {
      setIsLoading(true);

      const { data, error: queryError } = await supabase
        .from('journeys')
        .select('*')
        .eq('passenger_id', passengerId)
        .eq('status', 'ACTIVE')
        .single();

      if (queryError && queryError.code !== 'PGRST116') {
        throw queryError;
      }

      if (data) {
        // Journey exists - restore it
        data.device_id = deviceIdRef.current;
        setJourney(data);

        // Check for pending offline data
        const stats = await offlineQueue.getQueueStats(deviceIdRef.current);
        setQueueStats({
          total: stats.total,
          pending: stats.pending,
          synced: stats.processed,
        });

        return data;
      }

      return null;
    } catch (err) {
      console.error('Error auto-restoring journey:', err);
      setError(err instanceof Error ? err.message : 'Failed to restore journey');
      return null;
    } finally {
      setIsLoading(false);
    }
  }, [passengerId]);

  /**
   * Start a new journey
   */
  const startJourney = useCallback(
    async (fromStopId: string, toStopId: string, busId: string): Promise<Journey> => {
      if (!passengerId) throw new Error('No passenger ID');

      try {
        setIsLoading(true);
        setError(null);

        const newJourney: Partial<Journey> = {
          passenger_id: passengerId,
          bus_id: busId,
          from_stop_id: fromStopId,
          to_stop_id: toStopId,
          status: 'ACTIVE',
          device_id: deviceIdRef.current,
          offline_queue_count: 0,
        };

        const { data, error: insertError } = await supabase
          .from('journeys')
          .insert([newJourney])
          .select()
          .single();

        if (insertError) throw insertError;

        const journeyData = data as Journey;
        setJourney(journeyData);

        // Queue this action for offline tracking
        await offlineQueue.enqueue(
          deviceIdRef.current,
          'CONFIRM_JOURNEY',
          { journey_id: journeyData.id },
          journeyData.id
        );

        return journeyData;
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to start journey';
        setError(message);
        throw err;
      } finally {
        setIsLoading(false);
      }
    },
    [passengerId]
  );

  /**
   * End active journey
   */
  const endJourney = useCallback(async () => {
    if (!journey) throw new Error('No active journey');

    try {
      setIsLoading(true);

      const { error: updateError } = await supabase
        .from('journeys')
        .update({
          status: 'COMPLETED',
          end_time: new Date().toISOString(),
        })
        .eq('id', journey.id);

      if (updateError) throw updateError;

      setJourney(null);
      setQueueStats({ total: 0, pending: 0, synced: 0 });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to end journey';
      setError(message);
      throw err;
    } finally {
      setIsLoading(false);
    }
  }, [journey]);

  /**
   * Update location and store offline
   */
  const updateLocation = useCallback(
    async (latitude: number, longitude: number, accuracy: number) => {
      if (!journey) return;

      try {
        // Always store locally first
        await offlineQueue.storeLocation(journey.id, latitude, longitude, accuracy);

        // Try to sync immediately if online
        if (navigator.onLine) {
          await supabase
            .from('location_history')
            .insert({
              journey_id: journey.id,
              latitude,
              longitude,
              accuracy,
              source: 'GPS',
            })
            .select()
            .single();

          // Also update current location on journey
          await supabase
            .from('journeys')
            .update({
              current_latitude: latitude,
              current_longitude: longitude,
              current_accuracy: accuracy,
              last_location_update: new Date().toISOString(),
            })
            .eq('id', journey.id);
        } else {
          // Queue for later sync
          await offlineQueue.enqueue(
            deviceIdRef.current,
            'UPDATE_LOCATION',
            { latitude, longitude, accuracy },
            journey.id
          );
        }

        // Update local state
        setJourney((prev) =>
          prev
            ? {
                ...prev,
                current_latitude: latitude,
                current_longitude: longitude,
              }
            : null
        );
      } catch (err) {
        console.error('Error updating location:', err);
      }
    },
    [journey]
  );

  /**
   * Sync queued data to server
   */
  const syncQueuedData = useCallback(async () => {
    if (!navigator.onLine || !journey) return;

    try {
      setIsLoading(true);

      // Get all pending operations
      const pending = await offlineQueue.getPending(deviceIdRef.current);

      for (const item of pending) {
        try {
          if (item.action === 'UPDATE_LOCATION') {
            // Batch location updates
            const locations = await offlineQueue.getUnsyncedLocations(journey.id);
            if (locations.length > 0) {
              const { data, error } = await supabase
                .from('location_history')
                .insert(
                  locations.map((loc) => ({
                    journey_id: item.journey_id || journey.id,
                    latitude: loc.latitude,
                    longitude: loc.longitude,
                    accuracy: loc.accuracy,
                    source: 'OFFLINE_CACHE',
                  }))
                );

              if (error) throw error;
              await offlineQueue.markLocationsSynced(locations.map((l) => l.id));
            }
          } else if (item.action === 'CREATE_ORDER') {
            // Orders are synced via order-specific mechanism
            // (handled in useOrderSync hook)
          }

          await offlineQueue.markProcessed(item.id);
        } catch (err) {
          await offlineQueue.incrementRetry(item.id);
          console.error(`Failed to sync ${item.action}:`, err);
        }
      }

      // Update queue stats
      const stats = await offlineQueue.getQueueStats(deviceIdRef.current);
      setQueueStats({
        total: stats.total,
        pending: stats.pending,
        synced: stats.processed,
      });

      // Clean old data
      await offlineQueue.cleanOldData(7);
    } catch (err) {
      console.error('Error syncing queued data:', err);
    } finally {
      setIsLoading(false);
    }
  }, [journey]);

  // Auto-restore on mount and when passengerId changes
  useEffect(() => {
    if (passengerId) {
      autoRestore();
    }
  }, [passengerId, autoRestore]);

  // Monitor online/offline status and sync when coming back online
  useEffect(() => {
    const handleOnline = () => {
      console.log('Connection restored, syncing queued data...');
      syncQueuedData();
    };

    window.addEventListener('online', handleOnline);
    return () => window.removeEventListener('online', handleOnline);
  }, [syncQueuedData]);

  // Auto-sync every 30 seconds if online
  useEffect(() => {
    const interval = setInterval(() => {
      if (navigator.onLine && journey) {
        syncQueuedData();
      }
    }, 30000);

    return () => clearInterval(interval);
  }, [journey, syncQueuedData]);

  return {
    journey,
    isLoading,
    error,
    startJourney,
    endJourney,
    updateLocation,
    autoRestore,
    syncQueuedData,
    queueStats,
  };
}
