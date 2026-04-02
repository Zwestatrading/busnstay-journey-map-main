/**
 * useBackgroundTracking Hook
 * Manages GPS tracking that continues even when app is minimized
 * Uses browser Geolocation API for web, Capacitor for native apps
 */

import { useEffect, useRef, useCallback, useState } from 'react';
import { offlineQueue } from '@/lib/offlineQueue';

// Optional Capacitor imports (for native apps)
let Geolocation: any = null;
let CapacitorApp: any = null;

// Try to import Capacitor if available (native apps)
try {
  const capacitorGeo = require('@capacitor/geolocation');
  const capacitorApp = require('@capacitor/app');
  Geolocation = capacitorGeo.Geolocation;
  CapacitorApp = capacitorApp.App;
} catch (e) {
  // Capacitor not available, will use browser Geolocation API
}

interface BackgroundTrackingConfig {
  journeyId: string;
  updateInterval: number; // ms between updates (30000 = 30s recommended)
  enableHighAccuracy: boolean; // true = uses GPS, false = network only
  maxStoreTime?: number; // ms to buffer before syncing (60000 = 1 min)
}

interface UseBackgroundTrackingReturn {
  isTracking: boolean;
  lastLocation: { latitude: number; longitude: number; accuracy: number; timestamp: string } | null;
  error: string | null;
  startTracking: (config: BackgroundTrackingConfig) => Promise<void>;
  stopTracking: () => Promise<void>;
  getCurrentLocation: () => Promise<{
    latitude: number;
    longitude: number;
    accuracy: number;
  } | null>;
}

export function useBackgroundTracking(userId?: string | null): UseBackgroundTrackingReturn {
  const [isTracking, setIsTracking] = useState(false);
  const [lastLocation, setLastLocation] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  
  const isTrackingRef = useRef(false);
  const watchIdRef = useRef<string | number | null>(null);
  const configRef = useRef<BackgroundTrackingConfig | null>(null);

  const lastLocationRef = useRef<any>(null);
  const errorRef = useRef<string | null>(null);

  /**
   * Start background GPS tracking using browser Geolocation API
   */
  const startTracking = useCallback(async () => {
    if (isTrackingRef.current) return;

    try {
      setError(null);
      isTrackingRef.current = true;
      setIsTracking(true);

      // Use browser Geolocation API
      if (navigator.geolocation) {
        watchIdRef.current = navigator.geolocation.watchPosition(
          (position) => {
            const { latitude, longitude, accuracy } = position.coords;
            const location = {
              latitude,
              longitude,
              accuracy,
              timestamp: new Date().toISOString(),
            };

            lastLocationRef.current = location;
            setLastLocation(location);

            // Store in offline queue
            offlineQueue.addLocation(location).catch((err) =>
              console.error('Failed to store location:', err)
            );
          },
          (err) => {
            const errorMsg = `Geolocation error: ${err.message}`;
            console.error(errorMsg);
            errorRef.current = errorMsg;
            setError(errorMsg);
          },
          {
            enableHighAccuracy: true,
            maximumAge: 0,
            timeout: 10000,
          }
        );
      } else {
        throw new Error('Geolocation not supported by this browser');
      }
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Failed to start tracking';
      errorRef.current = errorMsg;
      setError(errorMsg);
      isTrackingRef.current = false;
      setIsTracking(false);
    }
  }, []);

  /**
   * Stop background GPS tracking
   */
  const stopTracking = useCallback(async () => {
    if (watchIdRef.current !== null && typeof watchIdRef.current === 'number') {
      navigator.geolocation.clearWatch(watchIdRef.current);
    }
    watchIdRef.current = null;
    isTrackingRef.current = false;
    setIsTracking(false);
  }, []);

  /**
   * Get current location
   */
  const getCurrentLocation = useCallback(
    async (): Promise<{ latitude: number; longitude: number; accuracy: number } | null> => {
      return new Promise((resolve) => {
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition(
            (position) => {
              const { latitude, longitude, accuracy } = position.coords;
              resolve({ latitude, longitude, accuracy });
            },
            (err) => {
              console.error('Failed to get current location:', err);
              resolve(null);
            }
          );
        } else {
          resolve(null);
        }
      });
    },
    []
  );

  /**
   * Auto-start tracking on component mount
   */
  useEffect(() => {
    if (userId) {
      startTracking();
    }

    return () => {
      stopTracking();
    };
  }, [userId, startTracking, stopTracking]);

  return {
    isTracking,
    lastLocation,
    error,
    startTracking: async () => startTracking(),
    stopTracking,
    getCurrentLocation,
  };
}
