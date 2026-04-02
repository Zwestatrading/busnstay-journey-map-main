import React, { useEffect, useRef, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { MapPin, Clock, AlertCircle, Navigation } from 'lucide-react';
import { Loader2 } from 'lucide-react';

interface Location {
  lat: number;
  lng: number;
}

interface Station {
  id: string;
  name: string;
  location: Location;
  hasRestaurants: boolean;
  restaurantCount?: number;
  eta?: string; // "5 mins", "10 mins", etc.
  distance?: number; // in km
}

interface DeliveryRoute {
  currentLocation: Location;
  destination: Location;
  currentStation?: Station;
  upcomingStations: Station[];
  estimatedArrival: string; // Time string like "2:30 PM"
  totalDistance: number; // in km
  totalTime: string; // "45 mins"
}

interface JourneyMapProps {
  route: DeliveryRoute;
  onStationClick?: (station: Station) => void;
  isTracking?: boolean;
}

declare global {
  interface Window {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    google: any;
  }
}

interface GoogleMapsGlobal {
  maps: {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Map: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Marker: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    SymbolPath: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    LatLngBounds: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Polyline: any;
  };
}

const JourneyMap: React.FC<JourneyMapProps> = ({ 
  route, 
  onStationClick,
  isTracking = true 
}) => {
  const mapContainer = useRef<HTMLDivElement>(null);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const map = useRef<any>(null);
  const [mapLoaded, setMapLoaded] = useState(false);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const markerRefs = useRef<any[]>([]);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const polylineRef = useRef<any>(null);

  // Load Google Maps API
  useEffect(() => {
    const loadGoogleMaps = () => {
      const script = document.createElement('script');
      script.src = `https://maps.googleapis.com/maps/api/js?key=${import.meta.env.VITE_GOOGLE_MAPS_API_KEY || 'YOUR_API_KEY_HERE'}`;
      script.async = true;
      script.onload = () => {
        setMapLoaded(true);
      };
      document.head.appendChild(script);
    };

    if (!window.google) {
      loadGoogleMaps();
    } else {
      setMapLoaded(true);
    }
  }, []);

  // Initialize map and markers
  useEffect(() => {
    if (!mapLoaded || !mapContainer.current || !window.google) return;

    // Create map
    const mapCenter = route.currentLocation;
    map.current = new window.google.maps.Map(mapContainer.current, {
      zoom: 14,
      center: mapCenter,
      mapTypeId: 'roadmap',
      fullscreenControl: true,
      zoomControl: true,
      mapTypeControl: false,
      streetViewControl: false,
    });

    // Current location marker (rider's vehicle)
    new window.google.maps.Marker({
      position: route.currentLocation,
      map: map.current,
      title: 'Your Location',
      icon: {
        path: window.google.maps.SymbolPath.CIRCLE,
        scale: 12,
        fillColor: '#3B82F6',
        fillOpacity: 1,
        strokeColor: '#1E40AF',
        strokeWeight: 3,
      },
    });

    // Destination marker
    new window.google.maps.Marker({
      position: route.destination,
      map: map.current,
      title: route.currentStation?.name || 'Destination',
      icon: {
        path: window.google.maps.SymbolPath.BACKWARD_CLOSED_ARROW,
        scale: 8,
        fillColor: '#10B981',
        fillOpacity: 1,
        strokeColor: '#059669',
        strokeWeight: 2,
      },
    });

    // Upcoming stations markers
    route.upcomingStations.forEach((station) => {
      const marker = new window.google.maps.Marker({
        position: station.location,
        map: map.current,
        title: station.name,
        icon: {
          path: window.google.maps.SymbolPath.CIRCLE,
          scale: 8,
          fillColor: station.hasRestaurants ? '#F59E0B' : '#6B7280',
          fillOpacity: 0.7,
          strokeColor: station.hasRestaurants ? '#D97706' : '#4B5563',
          strokeWeight: 2,
        },
      });

      marker.addListener('click', () => {
        onStationClick?.(station);
        // Center map on clicked station
        map.current?.setCenter(station.location);
        map.current?.setZoom(15);
      });

      markerRefs.current.push(marker);
    });

    // Draw route polyline
    const allPoints = [route.currentLocation, ...route.upcomingStations.map(s => s.location), route.destination];
    polylineRef.current = new window.google.maps.Polyline({
      path: allPoints,
      geodesic: true,
      strokeColor: '#3B82F6',
      strokeOpacity: 0.7,
      strokeWeight: 3,
      map: map.current,
    });

    // Auto zoom to fit route
    const bounds = new window.google.maps.LatLngBounds();
    allPoints.forEach(point => bounds.extend(point));
    map.current.fitBounds(bounds);
  }, [mapLoaded, route, onStationClick]);

  if (!mapLoaded) {
    return (
      <div className="w-full h-[500px] bg-slate-900 rounded-lg flex items-center justify-center">
        <div className="text-center space-y-2">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-blue-400" />
          <p className="text-slate-400">Loading map...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Map Container */}
      <Card className="bg-slate-900 border-slate-700">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Navigation className="w-5 h-5" />
            Live Delivery Route
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div
            ref={mapContainer}
            className="w-full h-[500px] rounded-lg overflow-hidden"
            style={{ border: '1px solid #475569' }}
          />
        </CardContent>
      </Card>

      {/* Route Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card className="bg-slate-800/50 border-slate-700">
          <CardContent className="pt-6">
            <div className="space-y-2">
              <p className="text-slate-400 text-sm">Total Distance</p>
              <p className="text-2xl font-bold text-white">{route.totalDistance.toFixed(1)} km</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-800/50 border-slate-700">
          <CardContent className="pt-6">
            <div className="space-y-2">
              <p className="text-slate-400 text-sm flex items-center gap-1">
                <Clock className="w-4 h-4" /> Estimated Time
              </p>
              <p className="text-2xl font-bold text-white">{route.totalTime}</p>
            </div>
          </CardContent>
        </Card>

        <Card className="bg-emerald-900/30 border-emerald-700/50">
          <CardContent className="pt-6">
            <div className="space-y-2">
              <p className="text-emerald-400 text-sm flex items-center gap-1">
                <MapPin className="w-4 h-4" /> Arrival
              </p>
              <p className="text-2xl font-bold text-emerald-400">{route.estimatedArrival}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Upcoming Stations */}
      {route.upcomingStations.length > 0 && (
        <Card className="bg-slate-800/50 border-slate-700">
          <CardHeader>
            <CardTitle className="text-lg">Upcoming Stops</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              {route.upcomingStations.map((station, idx) => (
                <div
                  key={station.id}
                  className="p-3 bg-slate-900/50 rounded-lg border border-slate-700 cursor-pointer hover:border-blue-500/50 transition"
                  onClick={() => onStationClick?.(station)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2 mb-1">
                        <span className="text-sm font-semibold text-white">Stop {idx + 1}</span>
                        {station.hasRestaurants && (
                          <Badge className="bg-amber-600 text-white text-xs">
                            🍽️ {station.restaurantCount} Restaurants
                          </Badge>
                        )}
                      </div>
                      <p className="text-slate-300 font-medium">{station.name}</p>
                      {station.distance && (
                        <p className="text-xs text-slate-400 mt-1">
                          {station.distance.toFixed(1)} km away
                        </p>
                      )}
                    </div>
                    <div className="text-right">
                      {station.eta && (
                        <p className="text-sm font-semibold text-emerald-400">{station.eta}</p>
                      )}
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={(e) => {
                          e.stopPropagation();
                          onStationClick?.(station);
                        }}
                        className="mt-1 h-6 text-xs"
                      >
                        View Details
                      </Button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
};

export default JourneyMap;
