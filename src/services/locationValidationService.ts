import { Geolocation } from '@capacitor/geolocation';
import {
  validateLocationOnRealRoute,
  findNearestStations,
  getETABetweenPoints,
} from './roadRoutingService';
import { calculateHaversineDistance } from './geoService';

interface RouteLocation {
  from: string;
  to: string;
  lat?: number;
  lng?: number;
}

interface LocationCoordinates {
  latitude: number;
  longitude: number;
}

// Define station coordinates for validation (Zambian stations)
const STATION_COORDINATES: { [key: string]: { lat: number; lng: number; radius: number } } = {
  'Lusaka': { lat: -15.4167, lng: 28.2833, radius: 5 }, // 5km radius
  'Livingstone': { lat: -17.8252, lng: 25.8655, radius: 5 },
  'Ndola': { lat: -12.9626, lng: 28.7015, radius: 5 },
  'Kitwe': { lat: -12.8096, lng: 28.3026, radius: 5 },
  'Chipata': { lat: -13.6673, lng: 32.6462, radius: 5 },
  'Mongu': { lat: -15.2667, lng: 23.1167, radius: 5 },
  'Kasama': { lat: -10.2000, lng: 31.1833, radius: 5 },
  'Solwezi': { lat: -12.4833, lng: 26.3667, radius: 5 },
};

/**
 * Calculate distance between two coordinates in kilometers (simple haversine)
 */
export const calculateDistance = (lat1: number, lng1: number, lat2: number, lng2: number): number => {
  return calculateHaversineDistance(lat1, lng1, lat2, lng2);
};

/**
 * Get user's current location using Capacitor Geolocation
 */
export const getUserLocation = async (): Promise<LocationCoordinates | null> => {
  try {
    const coordinates = await Geolocation.getCurrentPosition();
    return {
      latitude: coordinates.coords.latitude,
      longitude: coordinates.coords.longitude,
    };
  } catch (error) {
    console.error('Error getting location:', error);
    return null;
  }
};

/**
 * Validate if user is on the actual route (using OSRM road routing)
 * ✅ IMPROVED: Now checks against real roads, not straight lines
 * ✅ If user is in Livingstone, they CANNOT book Ndola-Lusaka (unless on route)
 */
export const validateLocationForRoute = async (
  fromStation: string,
  toStation: string
): Promise<{ isValid: boolean; message: string; distance?: number; eta?: number }> => {
  try {
    const userLocation = await getUserLocation();

    if (!userLocation) {
      return {
        isValid: false,
        message: 'Unable to access your location. Please enable location services and try again.',
      };
    }

    const fromCoords = STATION_COORDINATES[fromStation];
    const toCoords = STATION_COORDINATES[toStation];

    if (!fromCoords || !toCoords) {
      return {
        isValid: false,
        message: `Station not found. Available stations: ${Object.keys(STATION_COORDINATES).join(', ')}`,
      };
    }

    console.log(
      `🗺️ Validating location against real route: ${fromStation} → ${toStation}`
    );
    console.log(
      `📍 User location: ${userLocation.latitude}, ${userLocation.longitude}`
    );

    // Use OSRM to get actual route and validate location
    const validation = await validateLocationOnRealRoute(
      userLocation.latitude,
      userLocation.longitude,
      fromCoords.lat,
      fromCoords.lng,
      toCoords.lat,
      toCoords.lng,
      50 // 50km tolerance
    );

    // Get ETA for the journey
    const eta = await getETABetweenPoints(
      fromCoords.lat,
      fromCoords.lng,
      toCoords.lat,
      toCoords.lng
    );

    return {
      isValid: validation.isValid,
      message: validation.message,
      distance: validation.distance,
      eta: eta || undefined,
    };
  } catch (error) {
    console.error('Location validation error:', error);
    return {
      isValid: false,
      message: 'Location validation failed. Please ensure location services are enabled.',
    };
  }
};

/**
 * Find nearest stations to user (using OSRM for accurate distances)
 */
export const getNearestStations = async (
  userLat: number,
  userLng: number
): Promise<Array<{ name: string; distance: number; eta: number }>> => {
  try {
    const stations = Object.entries(STATION_COORDINATES).map(([name, coords]) => ({
      id: name,
      name,
      lat: coords.lat,
      lng: coords.lng,
    }));

    const nearest = await findNearestStations(userLat, userLng, stations, 3);

    return nearest.map((s) => ({
      name: s.name,
      distance: s.distance,
      eta: s.eta,
    }));
  } catch (error) {
    console.error('Error finding nearest stations:', error);
    return [];
  }
};

/**
 * Validate if restaurant is within delivery area of a station
 */
export const validateRestaurantLocation = async (
  stationType: string,
  restaurantLat: number,
  restaurantLng: number
): Promise<{ isValid: boolean; distanceFromStation: number }> => {
  try {
    const stationCoords = STATION_COORDINATES[stationType];

    if (!stationCoords) {
      return { isValid: false, distanceFromStation: 0 };
    }

    const distance = calculateDistance(
      stationCoords.lat,
      stationCoords.lng,
      restaurantLat,
      restaurantLng
    );

    // Restaurant must be within 2km of station
    const isValid = distance <= 2;

    return {
      isValid,
      distanceFromStation: distance,
    };
  } catch (error) {
    console.error('Restaurant location validation error:', error);
    return { isValid: false, distanceFromStation: 0 };
  }
};
