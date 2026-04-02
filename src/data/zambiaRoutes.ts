import { Town, Journey, Service } from '@/types/journey';

// ============= ALL ZAMBIAN TOWNS DATABASE =============
export const zambianTownsDatabase: Record<string, Town> = {
  // Lusaka Province
  lusaka: {
    id: 'lusaka',
    name: 'Lusaka',
    coordinates: [-15.3875, 28.3228],
    size: 'major',
    status: 'upcoming',
    region: 'Lusaka Province',
    geofenceRadius: 12000,
    distance: 0,
    services: { restaurants: 85, hotels: 62, riders: 180, taxis: 120 }
  },
  chilanga: {
    id: 'chilanga',
    name: 'Chilanga',
    coordinates: [-15.5500, 28.2667],
    size: 'minor',
    status: 'upcoming',
    region: 'Lusaka Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 8, hotels: 4, riders: 15, taxis: 10 }
  },
  kafue: {
    id: 'kafue',
    name: 'Kafue',
    coordinates: [-15.7667, 28.1833],
    size: 'medium',
    status: 'upcoming',
    region: 'Lusaka Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 18, hotels: 12, riders: 35, taxis: 25 }
  },
  
  // Southern Province
  mazabuka: {
    id: 'mazabuka',
    name: 'Mazabuka',
    coordinates: [-15.8500, 27.7500],
    size: 'medium',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 5000,
    distance: 0,
    services: { restaurants: 22, hotels: 15, riders: 45, taxis: 32 }
  },
  monze: {
    id: 'monze',
    name: 'Monze',
    coordinates: [-16.2833, 27.4833],
    size: 'medium',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 4500,
    distance: 0,
    services: { restaurants: 16, hotels: 10, riders: 30, taxis: 22 }
  },
  pemba: {
    id: 'pemba',
    name: 'Pemba',
    coordinates: [-16.5333, 27.3833],
    size: 'minor',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 2000,
    distance: 0,
    services: { restaurants: 6, hotels: 4, riders: 12, taxis: 8 }
  },
  choma: {
    id: 'choma',
    name: 'Choma',
    coordinates: [-16.8167, 26.9833],
    size: 'major',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 6000,
    distance: 0,
    services: { restaurants: 28, hotels: 18, riders: 55, taxis: 40 }
  },
  batoka: {
    id: 'batoka',
    name: 'Batoka',
    coordinates: [-17.0500, 26.7500],
    size: 'minor',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 2000,
    distance: 0,
    services: { restaurants: 5, hotels: 3, riders: 10, taxis: 6 }
  },
  kalomo: {
    id: 'kalomo',
    name: 'Kalomo',
    coordinates: [-17.0333, 26.4833],
    size: 'medium',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 14, hotels: 9, riders: 28, taxis: 20 }
  },
  zimba: {
    id: 'zimba',
    name: 'Zimba',
    coordinates: [-17.2000, 26.0000],
    size: 'minor',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 2000,
    distance: 0,
    services: { restaurants: 4, hotels: 2, riders: 8, taxis: 5 }
  },
  livingstone: {
    id: 'livingstone',
    name: 'Livingstone',
    coordinates: [-17.8419, 25.8544],
    size: 'major',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 8000,
    distance: 0,
    services: { restaurants: 65, hotels: 85, riders: 100, taxis: 75 }
  },
  siavonga: {
    id: 'siavonga',
    name: 'Siavonga',
    coordinates: [-16.5333, 28.7167],
    size: 'medium',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 18, hotels: 22, riders: 25, taxis: 18 }
  },
  chirundu: {
    id: 'chirundu',
    name: 'Chirundu',
    coordinates: [-16.0333, 28.8500],
    size: 'minor',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 8, hotels: 6, riders: 12, taxis: 10 }
  },
  kazungula: {
    id: 'kazungula',
    name: 'Kazungula',
    coordinates: [-17.7833, 25.2667],
    size: 'minor',
    status: 'upcoming',
    region: 'Southern Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 6, hotels: 5, riders: 10, taxis: 8 }
  },
  
  // Central Province
  kabwe: {
    id: 'kabwe',
    name: 'Kabwe',
    coordinates: [-14.4500, 28.4500],
    size: 'major',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 6000,
    distance: 0,
    services: { restaurants: 32, hotels: 20, riders: 60, taxis: 45 }
  },
  kapiriMposhi: {
    id: 'kapiri-mposhi',
    name: 'Kapiri Mposhi',
    coordinates: [-13.9667, 28.6667],
    size: 'medium',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 15, hotels: 10, riders: 28, taxis: 20 }
  },
  chisamba: {
    id: 'chisamba',
    name: 'Chisamba',
    coordinates: [-14.9833, 28.4000],
    size: 'minor',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 2000,
    distance: 0,
    services: { restaurants: 5, hotels: 3, riders: 8, taxis: 5 }
  },
  mumbwa: {
    id: 'mumbwa',
    name: 'Mumbwa',
    coordinates: [-14.9833, 27.0667],
    size: 'medium',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 14, hotels: 9, riders: 25, taxis: 18 }
  },
  serenje: {
    id: 'serenje',
    name: 'Serenje',
    coordinates: [-13.2333, 30.2333],
    size: 'medium',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 11, hotels: 7, riders: 20, taxis: 14 }
  },
  mkushi: {
    id: 'mkushi',
    name: 'Mkushi',
    coordinates: [-13.6167, 29.4000],
    size: 'medium',
    status: 'upcoming',
    region: 'Central Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 12, hotels: 8, riders: 22, taxis: 15 }
  },
  
  // Copperbelt Province
  ndola: {
    id: 'ndola',
    name: 'Ndola',
    coordinates: [-12.9587, 28.6366],
    size: 'major',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 10000,
    distance: 0,
    services: { restaurants: 55, hotels: 42, riders: 120, taxis: 85 }
  },
  kitwe: {
    id: 'kitwe',
    name: 'Kitwe',
    coordinates: [-12.8024, 28.2132],
    size: 'major',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 10000,
    distance: 0,
    services: { restaurants: 48, hotels: 38, riders: 110, taxis: 80 }
  },
  chingola: {
    id: 'chingola',
    name: 'Chingola',
    coordinates: [-12.5333, 27.8500],
    size: 'medium',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 5000,
    distance: 0,
    services: { restaurants: 22, hotels: 15, riders: 45, taxis: 32 }
  },
  mufulira: {
    id: 'mufulira',
    name: 'Mufulira',
    coordinates: [-12.5500, 28.2333],
    size: 'medium',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 5000,
    distance: 0,
    services: { restaurants: 20, hotels: 14, riders: 40, taxis: 30 }
  },
  luanshya: {
    id: 'luanshya',
    name: 'Luanshya',
    coordinates: [-13.1333, 28.4000],
    size: 'medium',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 4500,
    distance: 0,
    services: { restaurants: 18, hotels: 12, riders: 35, taxis: 25 }
  },
  chililabombwe: {
    id: 'chililabombwe',
    name: 'Chililabombwe',
    coordinates: [-12.3667, 27.8333],
    size: 'medium',
    status: 'upcoming',
    region: 'Copperbelt Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 16, hotels: 11, riders: 32, taxis: 24 }
  },
  
  // Eastern Province
  chipata: {
    id: 'chipata',
    name: 'Chipata',
    coordinates: [-13.6333, 32.6500],
    size: 'major',
    status: 'upcoming',
    region: 'Eastern Province',
    geofenceRadius: 6000,
    distance: 0,
    services: { restaurants: 28, hotels: 18, riders: 50, taxis: 38 }
  },
  petauke: {
    id: 'petauke',
    name: 'Petauke',
    coordinates: [-14.2500, 31.3167],
    size: 'medium',
    status: 'upcoming',
    region: 'Eastern Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 12, hotels: 8, riders: 22, taxis: 15 }
  },
  nyimba: {
    id: 'nyimba',
    name: 'Nyimba',
    coordinates: [-14.5500, 30.8167],
    size: 'minor',
    status: 'upcoming',
    region: 'Eastern Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 6, hotels: 4, riders: 12, taxis: 8 }
  },
  katete: {
    id: 'katete',
    name: 'Katete',
    coordinates: [-14.1167, 31.9667],
    size: 'medium',
    status: 'upcoming',
    region: 'Eastern Province',
    geofenceRadius: 3000,
    distance: 0,
    services: { restaurants: 10, hotels: 6, riders: 18, taxis: 12 }
  },
  
  // Northern Province
  kasama: {
    id: 'kasama',
    name: 'Kasama',
    coordinates: [-10.2128, 31.1808],
    size: 'major',
    status: 'upcoming',
    region: 'Northern Province',
    geofenceRadius: 5500,
    distance: 0,
    services: { restaurants: 24, hotels: 16, riders: 45, taxis: 32 }
  },
  mbala: {
    id: 'mbala',
    name: 'Mbala',
    coordinates: [-8.8500, 31.3667],
    size: 'medium',
    status: 'upcoming',
    region: 'Northern Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 14, hotels: 10, riders: 25, taxis: 18 }
  },
  mpika: {
    id: 'mpika',
    name: 'Mpika',
    coordinates: [-11.8333, 31.4500],
    size: 'medium',
    status: 'upcoming',
    region: 'Muchinga Province',
    geofenceRadius: 4000,
    distance: 0,
    services: { restaurants: 12, hotels: 8, riders: 22, taxis: 16 }
  },
  nakonde: {
    id: 'nakonde',
    name: 'Nakonde',
    coordinates: [-9.3500, 32.7500],
    size: 'minor',
    status: 'upcoming',
    region: 'Muchinga Province',
    geofenceRadius: 3000,
    distance: 0,
    services: { restaurants: 10, hotels: 7, riders: 15, taxis: 12 }
  },
  isoka: {
    id: 'isoka',
    name: 'Isoka',
    coordinates: [-10.1500, 32.6333],
    size: 'minor',
    status: 'upcoming',
    region: 'Muchinga Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 6, hotels: 4, riders: 10, taxis: 8 }
  },
  chinsali: {
    id: 'chinsali',
    name: 'Chinsali',
    coordinates: [-10.5500, 32.0833],
    size: 'medium',
    status: 'upcoming',
    region: 'Muchinga Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 10, hotels: 6, riders: 18, taxis: 12 }
  },
  
  // Luapula Province
  mansa: {
    id: 'mansa',
    name: 'Mansa',
    coordinates: [-11.2000, 28.8833],
    size: 'major',
    status: 'upcoming',
    region: 'Luapula Province',
    geofenceRadius: 5000,
    distance: 0,
    services: { restaurants: 20, hotels: 14, riders: 38, taxis: 28 }
  },
  samfya: {
    id: 'samfya',
    name: 'Samfya',
    coordinates: [-11.3667, 29.5500],
    size: 'medium',
    status: 'upcoming',
    region: 'Luapula Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 10, hotels: 8, riders: 18, taxis: 12 }
  },
  
  // North-Western Province
  solwezi: {
    id: 'solwezi',
    name: 'Solwezi',
    coordinates: [-12.1833, 26.3833],
    size: 'major',
    status: 'upcoming',
    region: 'North-Western Province',
    geofenceRadius: 6000,
    distance: 0,
    services: { restaurants: 26, hotels: 18, riders: 48, taxis: 35 }
  },
  kasempa: {
    id: 'kasempa',
    name: 'Kasempa',
    coordinates: [-13.4500, 25.8333],
    size: 'minor',
    status: 'upcoming',
    region: 'North-Western Province',
    geofenceRadius: 2500,
    distance: 0,
    services: { restaurants: 6, hotels: 4, riders: 10, taxis: 7 }
  },
  
  // Western Province
  mongu: {
    id: 'mongu',
    name: 'Mongu',
    coordinates: [-15.2500, 23.1333],
    size: 'major',
    status: 'upcoming',
    region: 'Western Province',
    geofenceRadius: 5500,
    distance: 0,
    services: { restaurants: 22, hotels: 15, riders: 42, taxis: 30 }
  },
  senanga: {
    id: 'senanga',
    name: 'Senanga',
    coordinates: [-16.1167, 23.2667],
    size: 'medium',
    status: 'upcoming',
    region: 'Western Province',
    geofenceRadius: 3000,
    distance: 0,
    services: { restaurants: 8, hotels: 6, riders: 15, taxis: 10 }
  },
  sesheke: {
    id: 'sesheke',
    name: 'Sesheke',
    coordinates: [-17.4667, 24.3000],
    size: 'medium',
    status: 'upcoming',
    region: 'Western Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 10, hotels: 7, riders: 18, taxis: 12 }
  },
  kaoma: {
    id: 'kaoma',
    name: 'Kaoma',
    coordinates: [-14.8000, 24.8000],
    size: 'medium',
    status: 'upcoming',
    region: 'Western Province',
    geofenceRadius: 3500,
    distance: 0,
    services: { restaurants: 10, hotels: 7, riders: 18, taxis: 12 }
  }
};

// ============= ROUTE DEFINITIONS =============
export interface RouteDefinition {
  id: string;
  name: string;
  from: string;
  to: string;
  stops: string[]; // Town IDs in order
  totalDistance: number;
  estimatedDuration: number; // minutes
}

export const routeDefinitions: RouteDefinition[] = [
  // Southern Route
  {
    id: 'lusaka-livingstone',
    name: 'Lusaka → Livingstone',
    from: 'lusaka',
    to: 'livingstone',
    stops: ['lusaka', 'chilanga', 'kafue', 'mazabuka', 'monze', 'pemba', 'choma', 'batoka', 'kalomo', 'zimba', 'livingstone'],
    totalDistance: 475,
    estimatedDuration: 420
  },
  {
    id: 'livingstone-lusaka',
    name: 'Livingstone → Lusaka',
    from: 'livingstone',
    to: 'lusaka',
    stops: ['livingstone', 'zimba', 'kalomo', 'batoka', 'choma', 'pemba', 'monze', 'mazabuka', 'kafue', 'chilanga', 'lusaka'],
    totalDistance: 475,
    estimatedDuration: 420
  },
  
  // Copperbelt Route
  {
    id: 'lusaka-ndola',
    name: 'Lusaka → Ndola',
    from: 'lusaka',
    to: 'ndola',
    stops: ['lusaka', 'chisamba', 'kabwe', 'kapiri-mposhi', 'ndola'],
    totalDistance: 325,
    estimatedDuration: 300
  },
  {
    id: 'ndola-lusaka',
    name: 'Ndola → Lusaka',
    from: 'ndola',
    to: 'lusaka',
    stops: ['ndola', 'kapiri-mposhi', 'kabwe', 'chisamba', 'lusaka'],
    totalDistance: 325,
    estimatedDuration: 300
  },
  
  // Eastern Route
  {
    id: 'lusaka-chipata',
    name: 'Lusaka → Chipata',
    from: 'lusaka',
    to: 'chipata',
    stops: ['lusaka', 'nyimba', 'petauke', 'katete', 'chipata'],
    totalDistance: 570,
    estimatedDuration: 480
  },
  {
    id: 'chipata-lusaka',
    name: 'Chipata → Lusaka',
    from: 'chipata',
    to: 'lusaka',
    stops: ['chipata', 'katete', 'petauke', 'nyimba', 'lusaka'],
    totalDistance: 570,
    estimatedDuration: 480
  },
  
  // Northern Route
  {
    id: 'lusaka-kasama',
    name: 'Lusaka → Kasama',
    from: 'lusaka',
    to: 'kasama',
    stops: ['lusaka', 'kabwe', 'kapiri-mposhi', 'serenje', 'mpika', 'kasama'],
    totalDistance: 850,
    estimatedDuration: 720
  },
  {
    id: 'kasama-lusaka',
    name: 'Kasama → Lusaka',
    from: 'kasama',
    to: 'lusaka',
    stops: ['kasama', 'mpika', 'serenje', 'kapiri-mposhi', 'kabwe', 'lusaka'],
    totalDistance: 850,
    estimatedDuration: 720
  },
  
  // North-Western Route
  {
    id: 'lusaka-solwezi',
    name: 'Lusaka → Solwezi',
    from: 'lusaka',
    to: 'solwezi',
    stops: ['lusaka', 'kabwe', 'kapiri-mposhi', 'ndola', 'kitwe', 'chingola', 'solwezi'],
    totalDistance: 520,
    estimatedDuration: 450
  },
  {
    id: 'solwezi-lusaka',
    name: 'Solwezi → Lusaka',
    from: 'solwezi',
    to: 'lusaka',
    stops: ['solwezi', 'chingola', 'kitwe', 'ndola', 'kapiri-mposhi', 'kabwe', 'lusaka'],
    totalDistance: 520,
    estimatedDuration: 450
  },
  
  // Western Route
  {
    id: 'lusaka-mongu',
    name: 'Lusaka → Mongu',
    from: 'lusaka',
    to: 'mongu',
    stops: ['lusaka', 'mumbwa', 'kaoma', 'mongu'],
    totalDistance: 610,
    estimatedDuration: 540
  },
  {
    id: 'mongu-lusaka',
    name: 'Mongu → Lusaka',
    from: 'mongu',
    to: 'lusaka',
    stops: ['mongu', 'kaoma', 'mumbwa', 'lusaka'],
    totalDistance: 610,
    estimatedDuration: 540
  },

  // Additional Inter-Provincial Routes for Complete Connectivity
  {
    id: 'ndola-kitwe',
    name: 'Ndola ↔ Kitwe',
    from: 'ndola',
    to: 'kitwe',
    stops: ['ndola', 'kitwe'],
    totalDistance: 65,
    estimatedDuration: 60
  },
  {
    id: 'kitwe-ndola',
    name: 'Kitwe ↔ Ndola',
    from: 'kitwe',
    to: 'ndola',
    stops: ['kitwe', 'ndola'],
    totalDistance: 65,
    estimatedDuration: 60
  },
  {
    id: 'kitwe-chingola',
    name: 'Kitwe ↔ Chingola',
    from: 'kitwe',
    to: 'chingola',
    stops: ['kitwe', 'chingola'],
    totalDistance: 50,
    estimatedDuration: 50
  },
  {
    id: 'chingola-kitwe',
    name: 'Chingola ↔ Kitwe',
    from: 'chingola',
    to: 'kitwe',
    stops: ['chingola', 'kitwe'],
    totalDistance: 50,
    estimatedDuration: 50
  },
  {
    id: 'livingstone-kazungula',
    name: 'Livingstone → Kazungula',
    from: 'livingstone',
    to: 'kazungula',
    stops: ['livingstone', 'kazungula'],
    totalDistance: 70,
    estimatedDuration: 75
  },
  {
    id: 'kazungula-livingstone',
    name: 'Kazungula → Livingstone',
    from: 'kazungula',
    to: 'livingstone',
    stops: ['kazungula', 'livingstone'],
    totalDistance: 70,
    estimatedDuration: 75
  },
  {
    id: 'livingstone-kasane',
    name: 'Livingstone → Kasane (Border)',
    from: 'livingstone',
    to: 'kasane',
    stops: ['livingstone', 'kazungula', 'kasane'],
    totalDistance: 90,
    estimatedDuration: 100
  },
  {
    id: 'ndola-kasama',
    name: 'Ndola → Kasama',
    from: 'ndola',
    to: 'kasama',
    stops: ['ndola', 'kapiri-mposhi', 'serenje', 'mpika', 'kasama'],
    totalDistance: 650,
    estimatedDuration: 550
  },
  {
    id: 'kasama-ndola',
    name: 'Kasama → Ndola',
    from: 'kasama',
    to: 'ndola',
    stops: ['kasama', 'mpika', 'serenje', 'kapiri-mposhi', 'ndola'],
    totalDistance: 650,
    estimatedDuration: 550
  },
  {
    id: 'lusaka-monze',
    name: 'Lusaka → Monze',
    from: 'lusaka',
    to: 'monze',
    stops: ['lusaka', 'mazabuka', 'monze'],
    totalDistance: 185,
    estimatedDuration: 160
  },
  {
    id: 'monze-lusaka',
    name: 'Monze → Lusaka',
    from: 'monze',
    to: 'lusaka',
    stops: ['monze', 'mazabuka', 'lusaka'],
    totalDistance: 185,
    estimatedDuration: 160
  },
  {
    id: 'choma-livingstone',
    name: 'Choma → Livingstone',
    from: 'choma',
    to: 'livingstone',
    stops: ['choma', 'kalomo', 'zimba', 'livingstone'],
    totalDistance: 285,
    estimatedDuration: 250
  },
  {
    id: 'livingstone-choma',
    name: 'Livingstone → Choma',
    from: 'livingstone',
    to: 'choma',
    stops: ['livingstone', 'zimba', 'kalomo', 'choma'],
    totalDistance: 285,
    estimatedDuration: 250
  },
  {
    id: 'lusaka-petauke',
    name: 'Lusaka → Petauke',
    from: 'lusaka',
    to: 'petauke',
    stops: ['lusaka', 'nyimba', 'petauke'],
    totalDistance: 420,
    estimatedDuration: 360
  },
  {
    id: 'petauke-lusaka',
    name: 'Petauke → Lusaka',
    from: 'petauke',
    to: 'lusaka',
    stops: ['petauke', 'nyimba', 'lusaka'],
    totalDistance: 420,
    estimatedDuration: 360
  },
  {
    id: 'ndola-mansa',
    name: 'Ndola → Mansa',
    from: 'ndola',
    to: 'mansa',
    stops: ['ndola', 'kapiri-mposhi', 'serenje', 'mansa'],
    totalDistance: 520,
    estimatedDuration: 450
  },
  {
    id: 'mansa-ndola',
    name: 'Mansa → Ndola',
    from: 'mansa',
    to: 'ndola',
    stops: ['mansa', 'serenje', 'kapiri-mposhi', 'ndola'],
    totalDistance: 520,
    estimatedDuration: 450
  },
  {
    id: 'mongu-western',
    name: 'Mongu → Sesheke',
    from: 'mongu',
    to: 'sesheke',
    stops: ['mongu', 'sesheke'],
    totalDistance: 280,
    estimatedDuration: 260
  },
  {
    id: 'sesheke-mongu',
    name: 'Sesheke → Mongu',
    from: 'sesheke',
    to: 'mongu',
    stops: ['sesheke', 'mongu'],
    totalDistance: 280,
    estimatedDuration: 260
  },
  {
    id: 'chipata-kasama',
    name: 'Chipata → Kasama',
    from: 'chipata',
    to: 'kasama',
    stops: ['chipata', 'katete', 'mpika', 'kasama'],
    totalDistance: 650,
    estimatedDuration: 560
  },
  {
    id: 'kasama-chipata',
    name: 'Kasama → Chipata',
    from: 'kasama',
    to: 'chipata',
    stops: ['kasama', 'mpika', 'katete', 'chipata'],
    totalDistance: 650,
    estimatedDuration: 560
  },
  {
    id: 'siavonga-lusaka',
    name: 'Siavonga → Lusaka',
    from: 'siavonga',
    to: 'lusaka',
    stops: ['siavonga', 'chirundu', 'lusaka'],
    totalDistance: 165,
    estimatedDuration: 145
  },
  {
    id: 'lusaka-siavonga',
    name: 'Lusaka → Siavonga',
    from: 'lusaka',
    to: 'siavonga',
    stops: ['lusaka', 'chirundu', 'siavonga'],
    totalDistance: 165,
    estimatedDuration: 145
  },
  {
    id: 'solwezi-kasempa',
    name: 'Solwezi ↔ Kasempa',
    from: 'solwezi',
    to: 'kasempa',
    stops: ['solwezi', 'kasempa'],
    totalDistance: 110,
    estimatedDuration: 100
  },
  {
    id: 'kasempa-solwezi',
    name: 'Kasempa ↔ Solwezi',
    from: 'kasempa',
    to: 'solwezi',
    stops: ['kasempa', 'solwezi'],
    totalDistance: 110,
    estimatedDuration: 100
  }
];

// ============= UTILITY FUNCTIONS =============

// Calculate distance between two coordinates (Haversine formula)
export const calculateDistance = (coord1: [number, number], coord2: [number, number]): number => {
  const R = 6371; // Earth's radius in km
  const dLat = (coord2[0] - coord1[0]) * Math.PI / 180;
  const dLon = (coord2[1] - coord1[1]) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(coord1[0] * Math.PI / 180) * Math.cos(coord2[0] * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

// Build route towns with proper distances and statuses
export const buildRouteTowns = (
  routeDefinition: RouteDefinition, 
  currentProgress: number = 0
): Town[] => {
  const towns: Town[] = [];
  let cumulativeDistance = 0;
  
  routeDefinition.stops.forEach((stopId, index) => {
    const baseTown = zambianTownsDatabase[stopId] || zambianTownsDatabase[stopId.replace('-', '')];
    if (!baseTown) return;
    
    // Calculate distance from previous stop
    if (index > 0) {
      const prevStopId = routeDefinition.stops[index - 1];
      const prevTown = zambianTownsDatabase[prevStopId] || zambianTownsDatabase[prevStopId.replace('-', '')];
      if (prevTown) {
        cumulativeDistance += calculateDistance(prevTown.coordinates, baseTown.coordinates);
      }
    }
    
    // Determine status based on progress
    const progressPercent = (cumulativeDistance / routeDefinition.totalDistance) * 100;
    let status: Town['status'] = 'upcoming';
    if (progressPercent < currentProgress - 5) {
      status = 'completed';
    } else if (progressPercent <= currentProgress + 5) {
      status = 'active';
    }
    
    towns.push({
      ...baseTown,
      distance: Math.round(cumulativeDistance),
      status
    });
  });
  
  return towns;
};

// Generate smooth route coordinates
export const generateRouteCoordinates = (towns: Town[]): [number, number][] => {
  const coordinates: [number, number][] = [];
  
  for (let i = 0; i < towns.length - 1; i++) {
    const start = towns[i].coordinates;
    const end = towns[i + 1].coordinates;
    
    const steps = 15;
    for (let j = 0; j <= steps; j++) {
      const t = j / steps;
      const lat = start[0] + (end[0] - start[0]) * t;
      const lng = start[1] + (end[1] - start[1]) * t;
      coordinates.push([lat, lng]);
    }
  }
  
  return coordinates;
};

// Create a journey from route definition
export const createJourney = (
  routeDefinition: RouteDefinition,
  progress: number = 0
): Journey => {
  const towns = buildRouteTowns(routeDefinition, progress);
  const startTown = towns[0];
  const endTown = towns[towns.length - 1];
  
  // Calculate current position based on progress
  const progressDistance = (progress / 100) * routeDefinition.totalDistance;
  let currentPosition: [number, number] = startTown.coordinates;
  
  for (let i = 0; i < towns.length - 1; i++) {
    if (towns[i].distance <= progressDistance && towns[i + 1].distance >= progressDistance) {
      const segmentProgress = (progressDistance - towns[i].distance) / (towns[i + 1].distance - towns[i].distance);
      currentPosition = [
        towns[i].coordinates[0] + (towns[i + 1].coordinates[0] - towns[i].coordinates[0]) * segmentProgress,
        towns[i].coordinates[1] + (towns[i + 1].coordinates[1] - towns[i].coordinates[1]) * segmentProgress
      ];
      break;
    }
  }
  
  return {
    id: `journey-${routeDefinition.id}-${Date.now()}`,
    startTown,
    endTown,
    intermediateTowns: towns.slice(1, -1),
    totalDistance: routeDefinition.totalDistance,
    estimatedDuration: routeDefinition.estimatedDuration,
    startTime: new Date(Date.now() - (progress / 100) * routeDefinition.estimatedDuration * 60 * 1000),
    currentPosition,
    progress,
    status: 'active'
  };
};

// Get all towns as array for search
export const getAllTowns = (): Town[] => Object.values(zambianTownsDatabase);

// Search towns by name
export const searchTowns = (query: string): Town[] => {
  const lowerQuery = query.toLowerCase().trim();
  if (!lowerQuery) return [];
  
  return getAllTowns()
    .filter(town => 
      town.name.toLowerCase().includes(lowerQuery) ||
      town.region.toLowerCase().includes(lowerQuery)
    )
    .slice(0, 8);
};

// Find available routes between two towns (supports any town, not just endpoints)
export const findRoutes = (fromId: string, toId: string): RouteDefinition[] => {
  // First check for exact direct routes
  const directRoutes = routeDefinitions.filter(
    route => route.from === fromId && route.to === toId
  );
  if (directRoutes.length > 0) return directRoutes;

  // Check if both towns are on the same route (sub-route)
  const subRoute = findSubRoute(fromId, toId);
  if (subRoute) return [subRoute];

  // Try to find a connected route through transfer points
  const connectedRoute = findConnectedRoute(fromId, toId);
  if (connectedRoute) return [connectedRoute];

  return [];
};

// Find a sub-route when both towns are on the same existing route
const findSubRoute = (fromId: string, toId: string): RouteDefinition | null => {
  for (const route of routeDefinitions) {
    const fromIndex = route.stops.indexOf(fromId);
    const toIndex = route.stops.indexOf(toId);
    
    if (fromIndex !== -1 && toIndex !== -1 && fromIndex < toIndex) {
      // Both towns are on this route and in the right order
      const subStops = route.stops.slice(fromIndex, toIndex + 1);
      const subTowns = subStops.map(id => zambianTownsDatabase[id] || zambianTownsDatabase[id.replace('-', '')]).filter(Boolean);
      
      // Calculate distance for sub-route
      let totalDistance = 0;
      for (let i = 0; i < subTowns.length - 1; i++) {
        totalDistance += calculateDistance(subTowns[i].coordinates, subTowns[i + 1].coordinates);
      }
      
      const fromTown = zambianTownsDatabase[fromId] || zambianTownsDatabase[fromId.replace('-', '')];
      const toTown = zambianTownsDatabase[toId] || zambianTownsDatabase[toId.replace('-', '')];
      
      return {
        id: `${fromId}-${toId}-sub`,
        name: `${fromTown?.name || fromId} → ${toTown?.name || toId}`,
        from: fromId,
        to: toId,
        stops: subStops,
        totalDistance: Math.round(totalDistance),
        estimatedDuration: Math.round((totalDistance / route.totalDistance) * route.estimatedDuration)
      };
    }
  }
  return null;
};

// Build a graph of all connected towns from routes
const buildRouteGraph = (): Map<string, Set<string>> => {
  const graph = new Map<string, Set<string>>();
  
  for (const route of routeDefinitions) {
    for (let i = 0; i < route.stops.length; i++) {
      const town = route.stops[i];
      if (!graph.has(town)) {
        graph.set(town, new Set());
      }
      // Connect to adjacent towns
      if (i > 0) graph.get(town)!.add(route.stops[i - 1]);
      if (i < route.stops.length - 1) graph.get(town)!.add(route.stops[i + 1]);
    }
  }
  
  return graph;
};

// Find a path between two towns using BFS
const findPath = (fromId: string, toId: string, graph: Map<string, Set<string>>): string[] | null => {
  if (!graph.has(fromId) || !graph.has(toId)) return null;
  
  const queue: string[][] = [[fromId]];
  const visited = new Set<string>([fromId]);
  
  while (queue.length > 0) {
    const path = queue.shift()!;
    const current = path[path.length - 1];
    
    if (current === toId) return path;
    
    const neighbors = graph.get(current) || new Set();
    for (const neighbor of neighbors) {
      if (!visited.has(neighbor)) {
        visited.add(neighbor);
        queue.push([...path, neighbor]);
      }
    }
  }
  
  return null;
};

// Find a connected route through transfer points
const findConnectedRoute = (fromId: string, toId: string): RouteDefinition | null => {
  const graph = buildRouteGraph();
  const path = findPath(fromId, toId, graph);
  
  if (!path || path.length < 2) return null;
  
  // Calculate total distance
  let totalDistance = 0;
  const pathTowns: Town[] = [];
  
  for (let i = 0; i < path.length; i++) {
    const townId = path[i];
    const town = zambianTownsDatabase[townId] || zambianTownsDatabase[townId.replace('-', '')];
    if (town) {
      pathTowns.push(town);
      if (i > 0) {
        const prevTown = pathTowns[pathTowns.length - 2];
        totalDistance += calculateDistance(prevTown.coordinates, town.coordinates);
      }
    }
  }
  
  // Estimate duration based on average speed of ~60km/h
  const estimatedDuration = Math.round((totalDistance / 60) * 60);
  
  const fromTown = zambianTownsDatabase[fromId] || zambianTownsDatabase[fromId.replace('-', '')];
  const toTown = zambianTownsDatabase[toId] || zambianTownsDatabase[toId.replace('-', '')];
  
  return {
    id: `${fromId}-${toId}-connected`,
    name: `${fromTown?.name || fromId} → ${toTown?.name || toId}`,
    from: fromId,
    to: toId,
    stops: path,
    totalDistance: Math.round(totalDistance),
    estimatedDuration
  };
};

// Generate services for a town
export const generateServicesForTown = (townId: string, townName: string): Service[] => {
  const services: Service[] = [];
  const town = zambianTownsDatabase[townId];
  if (!town) return services;
  
  // Restaurants
  const restaurantNames = ['Traditional Kitchen', 'Grill House', 'Express Cafe', 'Family Restaurant'];
  for (let i = 0; i < Math.min(town.services.restaurants, 4); i++) {
    services.push({
      id: `${townId}-rest-${i}`,
      type: 'restaurant',
      name: `${townName} ${restaurantNames[i % restaurantNames.length]}`,
      townId,
      rating: 4.2 + Math.random() * 0.7,
      eta: 5 + Math.floor(Math.random() * 20),
      available: true,
      price: 25 + Math.floor(Math.random() * 50)
    });
  }
  
  // Hotels
  const hotelNames = ['Lodge', 'Hotel', 'Inn', 'Guest House'];
  for (let i = 0; i < Math.min(town.services.hotels, 4); i++) {
    services.push({
      id: `${townId}-hotel-${i}`,
      type: 'hotel',
      name: `${townName} ${hotelNames[i % hotelNames.length]}`,
      townId,
      rating: 4.0 + Math.random() * 0.9,
      eta: 0,
      available: true,
      price: 50 + Math.floor(Math.random() * 150)
    });
  }
  
  // Riders
  services.push({
    id: `${townId}-rider-1`,
    type: 'rider',
    name: `${townName} Quick Riders`,
    townId,
    rating: 4.3 + Math.random() * 0.5,
    eta: 3 + Math.floor(Math.random() * 10),
    available: true
  });
  
  // Taxis
  services.push({
    id: `${townId}-taxi-1`,
    type: 'taxi',
    name: `${townName} Taxi Services`,
    townId,
    rating: 4.2 + Math.random() * 0.6,
    eta: 5 + Math.floor(Math.random() * 15),
    available: true
  });
  
  return services;
};
