/**
 * Road Routing Service - OSRM Integration
 * Uses free Open Source Routing Machine for real road routing in Zambia
 */

const OSRM_BASE_URL = 'https://router.project-osrm.org';

interface RoutePoint {
  lat: number;
  lng: number;
}

interface RouteGeometry {
  coordinates: [number, number][];
  distance: number;
  duration: number;
}

interface NearestStation {
  name: string;
  lat: number;
  lng: number;
  distanceKm: number;
}

const ZAMBIA_STATIONS: { [key: string]: { lat: number; lng: number } } = {
  'Lusaka': { lat: -15.4167, lng: 28.2833 },
  'Livingstone': { lat: -17.8252, lng: 25.8655 },
  'Ndola': { lat: -12.9626, lng: 28.7015 },
  'Kitwe': { lat: -12.8096, lng: 28.3026 },
  'Chipata': { lat: -13.6673, lng: 32.6462 },
  'Mongu': { lat: -15.2667, lng: 23.1167 },
  'Kasama': { lat: -10.2000, lng: 31.1833 },
  'Solwezi': { lat: -12.4833, lng: 26.3667 },
};

const haversineDistance = (lat1: number, lng1: number, lat2: number, lng2: number): number => {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLng = ((lng2 - lng1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos((lat1 * Math.PI) / 180) * Math.cos((lat2 * Math.PI) / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
};

export const getRouteGeometry = async (
  from: RoutePoint,
  to: RoutePoint
): Promise<RouteGeometry | null> => {
  try {
    const url = `${OSRM_BASE_URL}/route/v1/driving/${from.lng},${from.lat};${to.lng},${to.lat}?overview=full&geometries=geojson`;
    const response = await fetch(url);
    if (!response.ok) throw new Error(`OSRM error: ${response.status}`);

    const data = await response.json();
    if (data.code !== 'Ok' || !data.routes?.length) return null;

    const route = data.routes[0];
    return {
      coordinates: route.geometry.coordinates.map((c: [number, number]) => [c[1], c[0]]),
      distance: route.distance / 1000,
      duration: route.duration / 60,
    };
  } catch (error) {
    console.error('OSRM route error, using fallback:', error);
    return {
      coordinates: [[from.lat, from.lng], [to.lat, to.lng]],
      distance: haversineDistance(from.lat, from.lng, to.lat, to.lng),
      duration: haversineDistance(from.lat, from.lng, to.lat, to.lng) * 0.8,
    };
  }
};

export const validateLocationOnRealRoute = async (
  userLat: number,
  userLng: number,
  fromStation: string,
  toStation: string,
  maxDistanceKm: number = 15
): Promise<{ isValid: boolean; distanceFromRoute: number; message: string }> => {
  const from = ZAMBIA_STATIONS[fromStation];
  const to = ZAMBIA_STATIONS[toStation];

  if (!from || !to) {
    return { isValid: false, distanceFromRoute: -1, message: `Unknown station: ${!from ? fromStation : toStation}` };
  }

  try {
    const url = `${OSRM_BASE_URL}/route/v1/driving/${from.lng},${from.lat};${to.lng},${to.lat}?overview=full&geometries=geojson`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code !== 'Ok' || !data.routes?.length) {
      const distToFrom = haversineDistance(userLat, userLng, from.lat, from.lng);
      const distToTo = haversineDistance(userLat, userLng, to.lat, to.lng);
      const minDist = Math.min(distToFrom, distToTo);
      return {
        isValid: minDist <= maxDistanceKm,
        distanceFromRoute: minDist,
        message: minDist <= maxDistanceKm ? 'Near station (fallback)' : `Too far from route (${minDist.toFixed(1)}km)`,
      };
    }

    const routeCoords: [number, number][] = data.routes[0].geometry.coordinates;
    let minDistance = Infinity;

    for (const coord of routeCoords) {
      const dist = haversineDistance(userLat, userLng, coord[1], coord[0]);
      if (dist < minDistance) minDistance = dist;
    }

    return {
      isValid: minDistance <= maxDistanceKm,
      distanceFromRoute: minDistance,
      message: minDistance <= maxDistanceKm
        ? `Valid: ${minDistance.toFixed(1)}km from route`
        : `Invalid: ${minDistance.toFixed(1)}km from route (max ${maxDistanceKm}km)`,
    };
  } catch {
    const distToFrom = haversineDistance(userLat, userLng, from.lat, from.lng);
    const distToTo = haversineDistance(userLat, userLng, to.lat, to.lng);
    const minDist = Math.min(distToFrom, distToTo);
    return {
      isValid: minDist <= maxDistanceKm,
      distanceFromRoute: minDist,
      message: `Fallback validation: ${minDist.toFixed(1)}km from nearest station`,
    };
  }
};

export const validateLocationOnHaversineRoute = (
  userLat: number,
  userLng: number,
  fromStation: string,
  toStation: string,
  maxDistanceKm: number = 15
): { isValid: boolean; distanceFromRoute: number; message: string } => {
  const from = ZAMBIA_STATIONS[fromStation];
  const to = ZAMBIA_STATIONS[toStation];

  if (!from || !to) {
    return { isValid: false, distanceFromRoute: -1, message: 'Unknown station' };
  }

  const distToFrom = haversineDistance(userLat, userLng, from.lat, from.lng);
  const distToTo = haversineDistance(userLat, userLng, to.lat, to.lng);
  const minDist = Math.min(distToFrom, distToTo);

  return {
    isValid: minDist <= maxDistanceKm,
    distanceFromRoute: minDist,
    message: minDist <= maxDistanceKm ? 'Location valid' : `Too far (${minDist.toFixed(1)}km)`,
  };
};

export const findNearestStations = (
  lat: number,
  lng: number,
  limit: number = 3
): NearestStation[] => {
  const stations = Object.entries(ZAMBIA_STATIONS).map(([name, coords]) => ({
    name,
    lat: coords.lat,
    lng: coords.lng,
    distanceKm: haversineDistance(lat, lng, coords.lat, coords.lng),
  }));

  return stations.sort((a, b) => a.distanceKm - b.distanceKm).slice(0, limit);
};

export const getETABetweenPoints = async (
  from: RoutePoint,
  to: RoutePoint
): Promise<{ distanceKm: number; durationMinutes: number }> => {
  try {
    const url = `${OSRM_BASE_URL}/route/v1/driving/${from.lng},${from.lat};${to.lng},${to.lat}?overview=false`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code === 'Ok' && data.routes?.length) {
      return {
        distanceKm: data.routes[0].distance / 1000,
        durationMinutes: data.routes[0].duration / 60,
      };
    }
  } catch (error) {
    console.error('ETA calculation error:', error);
  }

  const dist = haversineDistance(from.lat, from.lng, to.lat, to.lng);
  return { distanceKm: dist, durationMinutes: dist * 0.8 };
};

export const getDistanceMatrix = async (
  points: RoutePoint[]
): Promise<number[][]> => {
  const matrix: number[][] = [];
  for (let i = 0; i < points.length; i++) {
    matrix[i] = [];
    for (let j = 0; j < points.length; j++) {
      if (i === j) {
        matrix[i][j] = 0;
      } else {
        matrix[i][j] = haversineDistance(points[i].lat, points[i].lng, points[j].lat, points[j].lng);
      }
    }
  }
  return matrix;
};
