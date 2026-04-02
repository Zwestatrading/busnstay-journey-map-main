import { useState, useEffect, useCallback } from 'react';
import { Journey, Town, Service } from '@/types/journey';
import { RouteDefinition } from '@/data/zambiaRoutes';

const STORAGE_KEYS = {
  ACTIVE_JOURNEY: 'busnstay_active_journey',
  CACHED_ROUTES: 'busnstay_cached_routes',
  CACHED_TOWNS: 'busnstay_cached_towns',
  CACHED_SERVICES: 'busnstay_cached_services',
  BOOKINGS: 'busnstay_bookings',
  LAST_SYNC: 'busnstay_last_sync'
};

interface CachedJourneyData {
  route: RouteDefinition;
  journey: Journey;
  towns: Town[];
  services: Service[];
  timestamp: number;
}

interface Booking {
  id: string;
  type: 'food' | 'accommodation' | 'taxi';
  townId: string;
  townName: string;
  serviceName: string;
  price: number;
  timestamp: number;
  synced: boolean;
}

export const useOfflineStorage = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const [pendingBookings, setPendingBookings] = useState<Booking[]>([]);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    // Load pending bookings on mount
    const stored = localStorage.getItem(STORAGE_KEYS.BOOKINGS);
    if (stored) {
      const bookings: Booking[] = JSON.parse(stored);
      setPendingBookings(bookings.filter(b => !b.synced));
    }

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // Cache journey data for offline use
  const cacheJourneyData = useCallback((data: CachedJourneyData) => {
    try {
      localStorage.setItem(STORAGE_KEYS.ACTIVE_JOURNEY, JSON.stringify(data));
      localStorage.setItem(STORAGE_KEYS.LAST_SYNC, Date.now().toString());
    } catch (error) {
      console.error('Failed to cache journey data:', error);
    }
  }, []);

  // Get cached journey data
  const getCachedJourney = useCallback((): CachedJourneyData | null => {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.ACTIVE_JOURNEY);
      return stored ? JSON.parse(stored) : null;
    } catch {
      return null;
    }
  }, []);

  // Clear cached journey
  const clearCachedJourney = useCallback(() => {
    localStorage.removeItem(STORAGE_KEYS.ACTIVE_JOURNEY);
  }, []);

  // Add a booking (works offline)
  const addBooking = useCallback((booking: Omit<Booking, 'id' | 'timestamp' | 'synced'>) => {
    const newBooking: Booking = {
      ...booking,
      id: `booking_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      timestamp: Date.now(),
      synced: false
    };

    const stored = localStorage.getItem(STORAGE_KEYS.BOOKINGS);
    const bookings: Booking[] = stored ? JSON.parse(stored) : [];
    bookings.push(newBooking);
    localStorage.setItem(STORAGE_KEYS.BOOKINGS, JSON.stringify(bookings));
    
    setPendingBookings(prev => [...prev, newBooking]);
    
    return newBooking;
  }, []);

  // Get all bookings
  const getBookings = useCallback((): Booking[] => {
    const stored = localStorage.getItem(STORAGE_KEYS.BOOKINGS);
    return stored ? JSON.parse(stored) : [];
  }, []);

  // Sync pending bookings when online
  const syncPendingBookings = useCallback(async () => {
    if (!isOnline || pendingBookings.length === 0) return;

    // In a real app, this would sync with a backend
    // For now, we just mark them as synced
    const stored = localStorage.getItem(STORAGE_KEYS.BOOKINGS);
    if (stored) {
      const bookings: Booking[] = JSON.parse(stored);
      const updated = bookings.map(b => ({ ...b, synced: true }));
      localStorage.setItem(STORAGE_KEYS.BOOKINGS, JSON.stringify(updated));
      setPendingBookings([]);
    }
  }, [isOnline, pendingBookings]);

  // Auto-sync when coming back online
  useEffect(() => {
    if (isOnline) {
      syncPendingBookings();
    }
  }, [isOnline, syncPendingBookings]);

  // Check if we have cached data for offline use
  const hasCachedData = useCallback((): boolean => {
    return !!localStorage.getItem(STORAGE_KEYS.ACTIVE_JOURNEY);
  }, []);

  // Get last sync time
  const getLastSyncTime = useCallback((): Date | null => {
    const stored = localStorage.getItem(STORAGE_KEYS.LAST_SYNC);
    return stored ? new Date(parseInt(stored)) : null;
  }, []);

  return {
    isOnline,
    pendingBookings,
    cacheJourneyData,
    getCachedJourney,
    clearCachedJourney,
    addBooking,
    getBookings,
    syncPendingBookings,
    hasCachedData,
    getLastSyncTime
  };
};

export default useOfflineStorage;
