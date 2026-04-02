// Distance and Geolocation utility service

/**
 * Calculate distance between two geographic points using Haversine formula
 * @param lat1 Latitude of first point
 * @param lon1 Longitude of first point
 * @param lat2 Latitude of second point
 * @param lon2 Longitude of second point
 * @returns Distance in kilometers
 */
export const calculateHaversineDistance = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const R = 6371; // Radius of the Earth in kilometers
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;

  return Math.round(distance * 100) / 100; // Round to 2 decimal places
};

/**
 * Calculate bearing between two points (useful for direction arrows)
 * @returns Bearing in degrees (0-360)
 */
export const calculateBearing = (
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number
): number => {
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const lat1Rad = (lat1 * Math.PI) / 180;
  const lat2Rad = (lat2 * Math.PI) / 180;

  const y = Math.sin(dLon) * Math.cos(lat2Rad);
  const x =
    Math.cos(lat1Rad) * Math.sin(lat2Rad) -
    Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);

  const bearing = (Math.atan2(y, x) * 180) / Math.PI;

  return (bearing + 360) % 360;
};

/**
 * Estimate delivery time based on distance and average speed
 * @param distanceKm Distance in kilometers
 * @param speedKmh Average delivery speed in kmh (default 25 kmh for city)
 * @returns Estimated time in minutes
 */
export const estimateDeliveryTime = (
  distanceKm: number,
  speedKmh: number = 25
): number => {
  const timeHours = distanceKm / speedKmh;
  const timeMinutes = Math.ceil(timeHours * 60);

  // Add 5 minutes for pickup/dropoff
  return timeMinutes + 5;
};

/**
 * Get current location using browser Geolocation API
 * @returns Promise with latitude, longitude, and accuracy
 */
export const getCurrentLocation = (): Promise<{
  latitude: number;
  longitude: number;
  accuracy: number;
  altitude?: number;
  speed?: number;
  heading?: number;
}> => {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'));
      return;
    }

    const options = {
      enableHighAccuracy: true,
      timeout: 10000,
      maximumAge: 0,
    };

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve({
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,
          altitude: position.coords.altitude || undefined,
          speed: position.coords.speed || undefined,
          heading: position.coords.heading || undefined,
        });
      },
      (error) => reject(error),
      options
    );
  });
};

/**
 * Watch location updates with callback
 * @param callback Function to call with location updates
 * @returns Watcher ID to stop watching
 */
export const watchLocation = (
  callback: (location: {
    latitude: number;
    longitude: number;
    accuracy: number;
    speed?: number;
    heading?: number;
  }) => void
): number | null => {
  if (!navigator.geolocation) {
    console.error('Geolocation not supported');
    return null;
  }

  const options = {
    enableHighAccuracy: true,
    timeout: 5000,
    maximumAge: 0,
  };

  const watchId = navigator.geolocation.watchPosition(
    (position) => {
      callback({
        latitude: position.coords.latitude,
        longitude: position.coords.longitude,
        accuracy: position.coords.accuracy,
        speed: position.coords.speed || undefined,
        heading: position.coords.heading || undefined,
      });
    },
    (error) => {
      console.error('Geolocation error:', error);
    },
    options
  );

  return watchId;
};

/**
 * Stop watching location
 */
export const stopWatchingLocation = (watchId: number): void => {
  if (watchId !== null && navigator.geolocation) {
    navigator.geolocation.clearWatch(watchId);
  }
};

/**
 * Calculate viewing area for map based on locations
 */
export const calculateMapBounds = (
  locations: Array<{ latitude: number; longitude: number }>
): {
  minLat: number;
  maxLat: number;
  minLong: number;
  maxLong: number;
  centerLat: number;
  centerLong: number;
} => {
  if (locations.length === 0) {
    return {
      minLat: 0,
      maxLat: 0,
      minLong: 0,
      maxLong: 0,
      centerLat: 0,
      centerLong: 0,
    };
  }

  const latitudes = locations.map((l) => l.latitude);
  const longitudes = locations.map((l) => l.longitude);

  const minLat = Math.min(...latitudes);
  const maxLat = Math.max(...latitudes);
  const minLong = Math.min(...longitudes);
  const maxLong = Math.max(...longitudes);

  const centerLat = (minLat + maxLat) / 2;
  const centerLong = (minLong + maxLong) / 2;

  return { minLat, maxLat, minLong, maxLong, centerLat, centerLong };
};

/**
 * Format distance for display
 */
export const formatDistance = (km: number): string => {
  if (km < 1) {
    return `${Math.round(km * 1000)} m`;
  }
  return `${km.toFixed(1)} km`;
};

/**
 * Format speed for display
 */
export const formatSpeed = (kmh: number | undefined): string => {
  if (kmh === undefined) return 'N/A';
  return `${Math.round(kmh)} km/h`;
};
