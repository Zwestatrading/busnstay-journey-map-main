import { useState, useEffect, useRef, useCallback } from 'react';
import { MapContainer, TileLayer, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { motion } from 'framer-motion';

import BusMarker from './BusMarker';
import TownMarker from './TownMarker';
import RoutePolyline from './RoutePolyline';
import MapControls from './MapControls';
import RouteSearchForm from '@/components/journey/RouteSearchForm';
import JourneyProgress from '@/components/journey/JourneyProgress';
import InteractiveTimeline from '@/components/journey/InteractiveTimeline';

import { 
  zambianTownsDatabase,
  routeDefinitions,
  buildRouteTowns,
  generateRouteCoordinates,
  createJourney,
  generateServicesForTown,
  RouteDefinition
} from '@/data/zambiaRoutes';
import { Town, Journey, Service } from '@/types/journey';
import { useToast } from '@/hooks/use-toast';

// Map bounds controller component
const MapBoundsController = ({ 
  coordinates 
}: { 
  coordinates: [number, number][] 
}) => {
  const map = useMap();

  useEffect(() => {
    if (coordinates.length > 0) {
      const bounds = L.latLngBounds(coordinates);
      map.fitBounds(bounds, { padding: [80, 80] });
    }
  }, [map, coordinates]);

  return null;
};

const JourneyMap = () => {
  const { toast } = useToast();
  const [activeRoute, setActiveRoute] = useState<RouteDefinition | null>(null);
  const [journey, setJourney] = useState<Journey | null>(null);
  const [towns, setTowns] = useState<Town[]>([]);
  const [services, setServices] = useState<Service[]>([]);
  const [routeCoordinates, setRouteCoordinates] = useState<[number, number][]>([]);
  const [currentPosition, setCurrentPosition] = useState<[number, number]>([-15.3875, 28.3228]);
  const [isTracking, setIsTracking] = useState(false);
  const [progress, setProgress] = useState(0);
  const mapRef = useRef<L.Map | null>(null);

  // Find active and next towns
  const activeTown = towns.find(t => t.status === 'active') || null;
  const nextTownIndex = activeTown ? towns.findIndex(t => t.id === activeTown.id) + 1 : 0;
  const nextTown = towns[nextTownIndex] || null;
  const destinationTown = towns[towns.length - 1] || null;

  // Handle route selection
  const handleRouteSelect = useCallback((route: RouteDefinition) => {
    setActiveRoute(route);
    
    // Build towns for this route
    const routeTowns = buildRouteTowns(route, 0);
    setTowns(routeTowns);
    
    // Generate route coordinates
    const coords = generateRouteCoordinates(routeTowns);
    setRouteCoordinates(coords);
    
    // Create journey
    const newJourney = createJourney(route, 0);
    setJourney(newJourney);
    setCurrentPosition(newJourney.currentPosition);
    
    // Generate services for all towns
    const allServices: Service[] = [];
    routeTowns.forEach(town => {
      const townServices = generateServicesForTown(town.id, town.name);
      allServices.push(...townServices);
    });
    setServices(allServices);
    
    // Start tracking
    setIsTracking(true);
    setProgress(0);
    
    toast({
      title: "Route Found! 🚌",
      description: `${route.name} - ${route.totalDistance} km journey`,
    });
  }, [toast]);

  // Simulate bus movement when tracking
  useEffect(() => {
    if (!isTracking || !activeRoute || !journey) return;

    const interval = setInterval(() => {
      setProgress(prev => {
        const newProgress = Math.min(prev + 0.5, 100);
        
        // Update towns with new progress
        const updatedTowns = buildRouteTowns(activeRoute, newProgress);
        setTowns(updatedTowns);
        
        // Update journey
        const updatedJourney = createJourney(activeRoute, newProgress);
        setJourney(updatedJourney);
        setCurrentPosition(updatedJourney.currentPosition);
        
        if (newProgress >= 100) {
          setIsTracking(false);
          toast({
            title: "Journey Complete! 🎉",
            description: `You have arrived at ${activeRoute.to}`,
          });
        }
        
        return newProgress;
      });
    }, 2000);

    return () => clearInterval(interval);
  }, [isTracking, activeRoute, journey, toast]);

  const handleTownClick = useCallback((town: Town) => {
    if (mapRef.current) {
      mapRef.current.flyTo(town.coordinates, 13, { duration: 1 });
    }
  }, []);

  const handleFocusCurrent = useCallback(() => {
    if (mapRef.current && routeCoordinates.length > 0) {
      const bounds = L.latLngBounds(routeCoordinates);
      mapRef.current.fitBounds(bounds, { padding: [80, 80], duration: 1 });
    }
  }, [routeCoordinates]);

  const handleFocusNext = useCallback(() => {
    if (mapRef.current && nextTown) {
      mapRef.current.flyTo(nextTown.coordinates, 12, { duration: 1 });
    }
  }, [nextTown]);

  const handleFocusDestination = useCallback(() => {
    if (mapRef.current && destinationTown) {
      mapRef.current.flyTo(destinationTown.coordinates, 11, { duration: 1 });
    }
  }, [destinationTown]);

  const handleOrderFood = useCallback((town: Town, service: Service) => {
    toast({
      title: town.status === 'active' ? "Order Placed! 🍽️" : "Pre-Order Confirmed! 🍽️",
      description: `${service.name} - $${service.price}. Ready when you arrive at ${town.name}.`,
    });
  }, [toast]);

  const handleBookAccommodation = useCallback((town: Town, service: Service) => {
    toast({
      title: "Accommodation Booked! 🏨",
      description: `${service.name} - $${service.price}/night in ${town.name}`,
    });
  }, [toast]);

  const handleBookTaxi = useCallback((town: Town, service: Service, type: 'accommodation' | 'home') => {
    toast({
      title: "Taxi Booked! 🚕",
      description: type === 'accommodation' 
        ? `${service.name} will take you to your hotel in ${town.name}`
        : `${service.name} will take you home from ${town.name}`,
    });
  }, [toast]);

  // Calculate heading based on movement direction
  const heading = nextTown 
    ? Math.atan2(
        nextTown.coordinates[1] - currentPosition[1],
        nextTown.coordinates[0] - currentPosition[0]
      ) * (180 / Math.PI) + 90
    : 0;

  return (
    <div className="flex h-screen overflow-hidden">
      {/* Left Sidebar - Journey Panel */}
      <motion.div
        initial={{ x: -100, opacity: 0 }}
        animate={{ x: 0, opacity: 1 }}
        className="w-[380px] h-full bg-background border-r border-border flex flex-col overflow-hidden"
      >
        {/* Brand Header */}
        <div className="p-4 border-b border-border flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
            <span className="text-primary-foreground font-display font-bold text-lg">B</span>
          </div>
          <div>
            <h1 className="font-display font-bold text-lg text-foreground">BusNStay</h1>
            <p className="text-xs text-muted-foreground">Beyond City Limits</p>
          </div>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-4 space-y-4">
          {/* Route Search */}
          <RouteSearchForm 
            onRouteSelect={handleRouteSelect}
            isLoading={false}
          />

          {/* Journey Progress - Only when active */}
          {journey && (
            <JourneyProgress
              journey={journey}
              activeTown={activeTown}
              nextTown={nextTown}
              isTracking={isTracking}
            />
          )}

          {/* Interactive Timeline - Only when route is selected */}
          {towns.length > 0 && (
            <div className="glass-card rounded-2xl overflow-hidden">
              <InteractiveTimeline
                towns={towns}
                services={services}
                onTownClick={handleTownClick}
                onOrderFood={handleOrderFood}
                onBookAccommodation={handleBookAccommodation}
                onBookTaxi={handleBookTaxi}
                destinationTown={destinationTown}
              />
            </div>
          )}
        </div>
      </motion.div>

      {/* Right Side - Map */}
      <div className="flex-1 relative">
        <MapContainer
          center={currentPosition}
          zoom={7}
          className="w-full h-full"
          zoomControl={false}
          attributionControl={false}
          ref={mapRef}
        >
          {/* Light elegant map tiles */}
          <TileLayer
            url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          />

          {/* Fit bounds when route changes */}
          {routeCoordinates.length > 0 && (
            <MapBoundsController coordinates={routeCoordinates} />
          )}

          {/* Route visualization */}
          {routeCoordinates.length > 0 && (
            <RoutePolyline 
              coordinates={routeCoordinates} 
              completedIndex={progress} 
            />
          )}

          {/* All background towns (faded) */}
          {Object.values(zambianTownsDatabase)
            .filter(t => !towns.find(rt => rt.id === t.id))
            .map(town => (
              <TownMarker 
                key={town.id} 
                town={{ ...town, status: 'upcoming' }}
                onClick={handleTownClick}
              />
            ))
          }

          {/* Route town markers */}
          {towns.map(town => (
            <TownMarker 
              key={`route-${town.id}`} 
              town={town} 
              onClick={handleTownClick}
            />
          ))}

          {/* Bus marker - only when tracking */}
          {isTracking && (
            <BusMarker position={currentPosition} heading={heading} />
          )}

          {/* Map controls */}
          {journey && (
            <MapControls
              currentPosition={currentPosition}
              activeTown={activeTown}
              destinationTown={destinationTown}
              onFocusCurrent={handleFocusCurrent}
              onFocusNext={handleFocusNext}
              onFocusDestination={handleFocusDestination}
            />
          )}
        </MapContainer>

        {/* Empty State Overlay */}
        {!activeRoute && (
          <div className="absolute inset-0 flex items-center justify-center bg-background/50 backdrop-blur-sm pointer-events-none">
            <div className="text-center">
              <h2 className="font-display text-2xl font-bold text-foreground mb-2">
                Start Your Journey
              </h2>
              <p className="text-muted-foreground">
                Enter your departure and destination to see the route
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default JourneyMap;
