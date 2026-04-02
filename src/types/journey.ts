export type TownSize = 'major' | 'medium' | 'minor';
export type TownStatus = 'completed' | 'active' | 'upcoming';

export interface Town {
  id: string;
  name: string;
  coordinates: [number, number]; // [lat, lng]
  size: TownSize;
  status: TownStatus;
  region: string;
  geofenceRadius: number; // in meters
  eta?: Date;
  distance?: number; // km from start
  services: {
    restaurants: number;
    hotels: number;
    riders: number;
    taxis: number;
  };
}

export interface Journey {
  id: string;
  startTown: Town;
  endTown: Town;
  intermediateTowns: Town[];
  totalDistance: number; // km
  estimatedDuration: number; // minutes
  startTime: Date;
  currentPosition: [number, number];
  progress: number; // 0-100
  status: 'pending' | 'active' | 'completed' | 'paused';
}

export interface Service {
  id: string;
  type: 'restaurant' | 'hotel' | 'rider' | 'taxi';
  name: string;
  townId: string;
  rating: number;
  eta: number; // minutes
  available: boolean;
  price?: number;
}

export interface PreOrder {
  id: string;
  serviceId: string;
  serviceType: 'restaurant' | 'hotel' | 'rider' | 'taxi';
  townId: string;
  scheduledFor: Date;
  status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'completed';
  dispatchDistance: number; // km before town
}
