import { calculateHaversineDistance } from './geoService';

interface RoutePoint {
  latitude: number;
  longitude: number;
  name: string;
}

interface JourneyRoute {
  startLocation: RoutePoint;
  endLocation: RoutePoint;
  intermediateStops: RoutePoint[];
  routeBuffer: number; // Distance in km to allow deviation from route
}

interface LocationValidationResult {
  isValid: boolean;
  reason?: string;
  distance?: number;
  nearestStopName?: string;
}

/**
 * Check if user's current location is within the journey route
 * @param userLat User's current latitude
 * @param userLon User's current longitude
 * @param journeyRoute The route to validate against
 * @param allowedDeviationKm Maximum deviation from the route in km (default: 50km)
 * @returns Validation result
 */
export const validateUserLocationOnRoute = (
  userLat: number,
  userLon: number,
  journeyRoute: JourneyRoute,
  allowedDeviationKm: number = 50
): LocationValidationResult => {
  const allStops = [
    journeyRoute.startLocation,
    ...journeyRoute.intermediateStops,
    journeyRoute.endLocation,
  ];

  // Find closest stop
  let closestStop = allStops[0];
  let closestDistance = calculateHaversineDistance(
    userLat,
    userLon,
    closestStop.latitude,
    closestStop.longitude
  );

  for (let i = 1; i < allStops.length; i++) {
    const distance = calculateHaversineDistance(
      userLat,
      userLon,
      allStops[i].latitude,
      allStops[i].longitude
    );

    if (distance < closestDistance) {
      closestDistance = distance;
      closestStop = allStops[i];
    }
  }

  // Check if user is close enough to a stop on the route
  if (closestDistance <= allowedDeviationKm) {
    // Check if the closest stop is actually on this journey route
    const isOnRoute = allStops.some(
      (stop) =>
        stop.latitude === closestStop.latitude &&
        stop.longitude === closestStop.longitude
    );

    if (isOnRoute) {
      return {
        isValid: true,
        distance: closestDistance,
        nearestStopName: closestStop.name,
      };
    }
  }

  return {
    isValid: false,
    reason: `You are ${closestDistance.toFixed(1)}km away from the route. You must be within ${allowedDeviationKm}km of the route to book this journey.`,
    distance: closestDistance,
    nearestStopName: closestStop.name,
  };
};

/**
 * Check if user is within any of the journey's cities
 * @param userLat User's current latitude
 * @param userLon User's current longitude
 * @param startCityLat Start city center latitude
 * @param startCityLon Start city center longitude
 * @param endCityLat End city center latitude
 * @param endCityLon End city center longitude
 * @param cityRadiusKm Radius of city in km (default: 30km)
 * @returns Whether user is in either city
 */
export const isUserInJourneyCity = (
  userLat: number,
  userLon: number,
  startCityLat: number,
  startCityLon: number,
  endCityLat: number,
  endCityLon: number,
  cityRadiusKm: number = 30
): boolean => {
  const distanceToStart = calculateHaversineDistance(
    userLat,
    userLon,
    startCityLat,
    startCityLon
  );

  const distanceToEnd = calculateHaversineDistance(
    userLat,
    userLon,
    endCityLat,
    endCityLon
  );

  return distanceToStart <= cityRadiusKm || distanceToEnd <= cityRadiusKm;
};

/**
 * Get detailed location validation with route visualization data
 */
export const getLocationValidationWithRoute = (
  userLat: number,
  userLon: number,
  journeyRoute: JourneyRoute
): LocationValidationResult & { allStops: RoutePoint[]; userPosition: { lat: number; lon: number } } => {
  const validation = validateUserLocationOnRoute(
    userLat,
    userLon,
    journeyRoute
  );

  const allStops = [
    journeyRoute.startLocation,
    ...journeyRoute.intermediateStops,
    journeyRoute.endLocation,
  ];

  return {
    ...validation,
    allStops,
    userPosition: { lat: userLat, lon: userLon },
  };
};
