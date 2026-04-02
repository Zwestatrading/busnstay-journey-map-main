import { useState, useEffect, useCallback, useRef } from 'react';
import { Town } from '@/types/journey';

interface GPSState {
  position: [number, number] | null;
  heading: number;
  speed: number; // km/h
  accuracy: number; // meters
  isTracking: boolean;
  error: string | null;
  lastUpdate: Date | null;
}

interface UseGPSTrackingOptions {
  enabled: boolean;
  towns: Town[];
  routeCoordinates: [number, number][];
  onTownReached?: (town: Town) => void;
  onTownDeparted?: (town: Town) => void;
}

// Dynamic geofencing radius based on town size
const getGeofenceRadius = (size: Town['size']): number => {
  switch (size) {
    case 'major': return 2000; // 2km for major cities
    case 'medium': return 1000; // 1km for medium towns
    case 'minor': return 500; // 500m for small towns
    default: return 1000;
  }
};

// Calculate distance between two coordinates in meters
const calculateDistance = (
  lat1: number, 
  lon1: number, 
  lat2: number, 
  lon2: number
): number => {
  const R = 6371000; // Earth's radius in meters
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

// Calculate progress along route based on current position
const calculateRouteProgress = (
  position: [number, number],
  routeCoordinates: [number, number][],
  towns: Town[]
): number => {
  if (routeCoordinates.length < 2 || towns.length < 2) return 0;

  const startTown = towns[0];
  const endTown = towns[towns.length - 1];
  
  const totalDistance = calculateDistance(
    startTown.coordinates[0],
    startTown.coordinates[1],
    endTown.coordinates[0],
    endTown.coordinates[1]
  );

  const distanceFromStart = calculateDistance(
    startTown.coordinates[0],
    startTown.coordinates[1],
    position[0],
    position[1]
  );

  return Math.min(100, Math.max(0, (distanceFromStart / totalDistance) * 100));
};

export const useGPSTracking = ({
  enabled,
  towns,
  routeCoordinates,
  onTownReached,
  onTownDeparted
}: UseGPSTrackingOptions) => {
  const [state, setState] = useState<GPSState>({
    position: null,
    heading: 0,
    speed: 0,
    accuracy: 0,
    isTracking: false,
    error: null,
    lastUpdate: null
  });

  const watchIdRef = useRef<number | null>(null);
  const previousTownRef = useRef<Town | null>(null);
  const [progress, setProgress] = useState(0);

  // Check if position is within a town's geofence
  const checkTownProximity = useCallback((position: [number, number]) => {
    for (const town of towns) {
      const distance = calculateDistance(
        position[0],
        position[1],
        town.coordinates[0],
        town.coordinates[1]
      );
      const radius = getGeofenceRadius(town.size);

      if (distance <= radius) {
        // Entered a town
        if (previousTownRef.current?.id !== town.id) {
          if (previousTownRef.current && onTownDeparted) {
            onTownDeparted(previousTownRef.current);
          }
          if (onTownReached) {
            onTownReached(town);
          }
          previousTownRef.current = town;
        }
        return town;
      }
    }
    return null;
  }, [towns, onTownReached, onTownDeparted]);

  // Start GPS tracking
  const startTracking = useCallback(() => {
    if (!navigator.geolocation) {
      setState(prev => ({
        ...prev,
        error: 'Geolocation is not supported by this browser',
        isTracking: false
      }));
      return;
    }

    setState(prev => ({ ...prev, isTracking: true, error: null }));

    watchIdRef.current = navigator.geolocation.watchPosition(
      (position) => {
        const newPosition: [number, number] = [
          position.coords.latitude,
          position.coords.longitude
        ];

        const newProgress = calculateRouteProgress(newPosition, routeCoordinates, towns);
        setProgress(newProgress);

        // Check town proximity
        checkTownProximity(newPosition);

        setState(prev => ({
          ...prev,
          position: newPosition,
          heading: position.coords.heading || prev.heading,
          speed: position.coords.speed ? position.coords.speed * 3.6 : 0, // Convert m/s to km/h
          accuracy: position.coords.accuracy,
          lastUpdate: new Date(),
          error: null
        }));
      },
      (error) => {
        let errorMessage = 'Unknown error occurred';
        switch (error.code) {
          case error.PERMISSION_DENIED:
            errorMessage = 'Location permission denied. Please enable GPS.';
            break;
          case error.POSITION_UNAVAILABLE:
            errorMessage = 'Location unavailable. Check GPS signal.';
            break;
          case error.TIMEOUT:
            errorMessage = 'Location request timed out. Retrying...';
            break;
        }
        setState(prev => ({
          ...prev,
          error: errorMessage,
          isTracking: error.code === error.TIMEOUT // Keep tracking on timeout
        }));
      },
      {
        enableHighAccuracy: true,
        timeout: 10000,
        maximumAge: 5000
      }
    );
  }, [routeCoordinates, towns, checkTownProximity]);

  // Stop GPS tracking
  const stopTracking = useCallback(() => {
    if (watchIdRef.current !== null) {
      navigator.geolocation.clearWatch(watchIdRef.current);
      watchIdRef.current = null;
    }
    setState(prev => ({ ...prev, isTracking: false }));
  }, []);

  // Request single position
  const requestPosition = useCallback(() => {
    if (!navigator.geolocation) {
      setState(prev => ({
        ...prev,
        error: 'Geolocation is not supported'
      }));
      return;
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const newPosition: [number, number] = [
          position.coords.latitude,
          position.coords.longitude
        ];
        setState(prev => ({
          ...prev,
          position: newPosition,
          heading: position.coords.heading || prev.heading,
          speed: position.coords.speed ? position.coords.speed * 3.6 : 0,
          accuracy: position.coords.accuracy,
          lastUpdate: new Date()
        }));
      },
      (error) => {
        setState(prev => ({
          ...prev,
          error: `Failed to get position: ${error.message}`
        }));
      },
      { enableHighAccuracy: true }
    );
  }, []);

  // Auto start/stop based on enabled prop
  useEffect(() => {
    if (enabled) {
      startTracking();
    } else {
      stopTracking();
    }

    return () => {
      stopTracking();
    };
  }, [enabled, startTracking, stopTracking]);

  return {
    ...state,
    progress,
    startTracking,
    stopTracking,
    requestPosition,
    currentTown: previousTownRef.current
  };
};

export default useGPSTracking;
