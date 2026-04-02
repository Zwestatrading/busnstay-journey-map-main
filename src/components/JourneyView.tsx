import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { MapContainer, TileLayer, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { motion } from 'framer-motion';
import { ArrowLeft, Bus, Navigation2, Locate, WifiOff, LocateFixed } from 'lucide-react';

import BusMarker from '@/components/map/BusMarker';
import TownMarker from '@/components/map/TownMarker';
import RoutePolyline from '@/components/map/RoutePolyline';
import JourneyStopsPanel from '@/components/journey/JourneyStopsPanel';
import RestaurantSheet from '@/components/order/RestaurantSheet';
import MenuSheet from '@/components/order/MenuSheet';
import { PendingOrdersContainer } from '@/components/order/PendingOrderCard';
import ShareJourneyButton from '@/components/journey/ShareJourneyButton';
import DestinationServicesSheet from '@/components/journey/DestinationServicesSheet';
import useGPSTracking from '@/hooks/useGPSTracking';
import { generateRestaurantsForTown } from '@/data/restaurantData';

import { 
  buildRouteTowns,
  generateRouteCoordinates,
  createJourney,
  RouteDefinition
} from '@/data/zambiaRoutes';
import { Town, Journey } from '@/types/journey';
import { Restaurant, CartItem, PendingOrder, OrderStatus } from '@/types/order';
import { useToast } from '@/hooks/use-toast';
import { Button } from '@/components/ui/button';

interface JourneyViewProps {
  route: RouteDefinition;
  onBack: () => void;
}

const MapBoundsController = ({ coordinates }: { coordinates: [number, number][] }) => {
  const map = useMap();

  useEffect(() => {
    if (coordinates.length > 0) {
      const bounds = L.latLngBounds(coordinates);
      map.fitBounds(bounds, { padding: [60, 60] });
    }
  }, [map, coordinates]);

  return null;
};

const MapPositionFollower = ({ position, shouldFollow }: { position: [number, number] | null; shouldFollow: boolean }) => {
  const map = useMap();

  useEffect(() => {
    if (position && shouldFollow) {
      map.setView(position, map.getZoom(), { animate: true });
    }
  }, [map, position, shouldFollow]);

  return null;
};

const JourneyView = ({ route, onBack }: JourneyViewProps) => {
  const { toast } = useToast();
  const [journey, setJourney] = useState<Journey | null>(null);
  const [towns, setTowns] = useState<Town[]>([]);
  const [routeCoordinates, setRouteCoordinates] = useState<[number, number][]>([]);
  const [useRealGPS, setUseRealGPS] = useState(true);
  const [followBus, setFollowBus] = useState(false);
  const [simulatedProgress, setSimulatedProgress] = useState(0);
  const mapRef = useRef<L.Map | null>(null);
 
   // Journey passenger ID for sharing (would come from real DB in production)
   const [journeyPassengerId] = useState<string | null>(null);

  // Order flow state
  const [selectedTown, setSelectedTown] = useState<Town | null>(null);
  const [selectedRestaurant, setSelectedRestaurant] = useState<Restaurant | null>(null);
  const [pendingOrders, setPendingOrders] = useState<PendingOrder[]>([]);
  const [destinationServicesTown, setDestinationServicesTown] = useState<Town | null>(null);

  // Initialize route data
  useEffect(() => {
    const routeTowns = buildRouteTowns(route, 0);
    setTowns(routeTowns);
    
    const coords = generateRouteCoordinates(routeTowns);
    setRouteCoordinates(coords);
    
    const newJourney = createJourney(route, 0);
    setJourney(newJourney);
    
    toast({
      title: "Route Found! 🚌",
      description: `${route.name} - ${route.totalDistance} km journey`,
    });
  }, [route, toast]);

  // GPS Tracking Hook
  const gps = useGPSTracking({
    enabled: useRealGPS,
    towns,
    routeCoordinates,
    onTownReached: (town) => {
      toast({
        title: `Arrived at ${town.name}! 📍`,
        description: `You've reached ${town.name}. Check available services.`,
      });
    },
    onTownDeparted: (town) => {
      toast({
        title: `Departed ${town.name} 🚌`,
        description: `On your way to the next stop.`,
      });
    }
  });

  // Fallback simulation when GPS is not available
  useEffect(() => {
    if (useRealGPS && !gps.error) return;

    const interval = setInterval(() => {
      setSimulatedProgress(prev => {
        const newProgress = Math.min(prev + 0.5, 100);
        
        if (newProgress >= 100) {
          toast({
            title: "Journey Complete! 🎉",
            description: `You have arrived at ${route.to}`,
          });
          return 100;
        }
        
        return newProgress;
      });
    }, 2000);

    return () => clearInterval(interval);
  }, [useRealGPS, gps.error, route.to, toast]);

  // Update towns and journey based on progress
  const currentProgress = useRealGPS && !gps.error ? gps.progress : simulatedProgress;
  
  useEffect(() => {
    const updatedTowns = buildRouteTowns(route, currentProgress);
    setTowns(updatedTowns);
    
    const updatedJourney = createJourney(route, currentProgress);
    setJourney(updatedJourney);
  }, [currentProgress, route]);

  // Simulate order status progression
  useEffect(() => {
    const interval = setInterval(() => {
      setPendingOrders(prev => prev.map(order => {
        if (order.status === 'completed') return order;
        
        const statusFlow: OrderStatus[] = ['pending', 'preparing', 'ready'];
        const currentIndex = statusFlow.indexOf(order.status);
        if (currentIndex < statusFlow.length - 1) {
          return { ...order, status: statusFlow[currentIndex + 1] };
        }
        return order;
      }));
    }, 8000);

    return () => clearInterval(interval);
  }, []);

  // Current position (GPS or simulated)
  const currentPosition: [number, number] = gps.position && useRealGPS && !gps.error
    ? gps.position
    : journey?.currentPosition || [-15.3875, 28.3228];

  // Derived town states
  const activeTown = towns.find(t => t.status === 'active') || null;
  const nextTownIndex = activeTown ? towns.findIndex(t => t.id === activeTown.id) + 1 : 0;
  const nextTown = towns[nextTownIndex] || null;
  const destinationTown = towns[towns.length - 1] || null;

  // Is actively tracking (real GPS or simulation)
  const isTracking = (useRealGPS && gps.isTracking && !gps.error) || (!useRealGPS && simulatedProgress < 100);

  // Get restaurants for selected town
  const townRestaurants = useMemo(() => {
    if (!selectedTown) return [];
    return generateRestaurantsForTown(selectedTown.id, selectedTown.name);
  }, [selectedTown]);

  const handleTownClick = useCallback((town: Town) => {
    if (mapRef.current) {
      mapRef.current.flyTo(town.coordinates, 13, { duration: 0.5 });
    }
    setFollowBus(false);
    
    // Open restaurant sheet if town has restaurants and is not completed
    if (town.services.restaurants > 0 && town.status !== 'completed') {
      setSelectedTown(town);
    }
  }, []);

  const handleRecenterRoute = useCallback(() => {
    if (mapRef.current && routeCoordinates.length > 0) {
      const bounds = L.latLngBounds(routeCoordinates);
      mapRef.current.fitBounds(bounds, { padding: [60, 60], duration: 0.5 });
    }
    setFollowBus(false);
  }, [routeCoordinates]);

  const handleSelectRestaurant = useCallback((restaurant: Restaurant) => {
    setSelectedRestaurant(restaurant);
  }, []);

  const handlePlaceOrder = useCallback((items: CartItem[], total: number) => {
    if (!selectedTown || !selectedRestaurant) return;

    const newOrder: PendingOrder = {
      id: `order-${Date.now()}`,
      stationId: selectedTown.id,
      stationName: selectedTown.name,
      restaurantId: selectedRestaurant.id,
      restaurantName: selectedRestaurant.name,
      items,
      totalPrice: total,
      status: 'pending',
      orderedAt: new Date(),
    };

    setPendingOrders(prev => [...prev, newOrder]);
    setSelectedRestaurant(null);
    setSelectedTown(null);

    toast({
      title: "Order Placed! 🍽️",
      description: `Your order from ${selectedRestaurant.name} will be ready at ${selectedTown.name}`,
    });
  }, [selectedTown, selectedRestaurant, toast]);

  const handleDismissOrder = useCallback((orderId: string) => {
    setPendingOrders(prev => prev.filter(o => o.id !== orderId));
  }, []);

  const handlePickupOrder = useCallback((orderId: string) => {
    setPendingOrders(prev => prev.map(o => 
      o.id === orderId ? { ...o, status: 'completed' as OrderStatus } : o
    ));
    
    setTimeout(() => {
      setPendingOrders(prev => prev.filter(o => o.id !== orderId));
    }, 1000);

    toast({
      title: "Order Picked Up! ✅",
      description: "Enjoy your meal!",
    });
  }, [toast]);

  const handleCenterOnBus = useCallback(() => {
    if (mapRef.current && currentPosition) {
      mapRef.current.flyTo(currentPosition, 14, { duration: 0.5 });
      setFollowBus(true);
    }
  }, [currentPosition]);

  const handleDestinationServices = useCallback((town: Town) => {
    setDestinationServicesTown(town);
  }, []);

  const toggleGPSMode = useCallback(() => {
    setUseRealGPS(prev => {
      const newMode = !prev;
      toast({
        title: newMode ? "Real GPS Enabled 📍" : "Simulation Mode",
        description: newMode 
          ? "Tracking your actual location" 
          : "Using simulated bus movement",
      });
      return newMode;
    });
  }, [toast]);

  const heading = gps.heading || (nextTown 
    ? Math.atan2(
        nextTown.coordinates[1] - currentPosition[1],
        nextTown.coordinates[0] - currentPosition[0]
      ) * (180 / Math.PI) + 90
    : 0);

  const formatTime = (minutes: number) => {
    const hrs = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`;
  };

  const remainingTime = journey ? Math.round(journey.estimatedDuration * (1 - currentProgress / 100)) : 0;

  return (
    <div className="h-screen flex flex-col bg-background">
      {/* Map Section - 65-70% of screen */}
      <div className="relative flex-[2] min-h-[60vh]">
        {/* Pending Orders - Fixed at top */}
        <PendingOrdersContainer 
          orders={pendingOrders}
          onDismiss={handleDismissOrder}
          onPickup={handlePickupOrder}
        />

        {/* Back Button */}
        <div className="absolute top-4 left-4 z-[999]">
          <Button
            variant="secondary"
            size="icon"
            onClick={onBack}
            className="rounded-full shadow-lg bg-card/95 backdrop-blur-sm"
          >
            <ArrowLeft className="w-5 h-5" />
          </Button>
        </div>

        {/* Route Info - Adjust position when orders present */}
        <div className={`absolute left-16 right-4 z-[999] transition-all ${pendingOrders.length > 0 ? 'top-24' : 'top-4'}`}>
          <div className="bg-card/95 backdrop-blur-sm rounded-xl p-3 shadow-lg">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-journey-active flex items-center justify-center">
                  <Bus className="w-4 h-4 text-white" />
                </div>
                <div>
                  <p className="font-display font-bold text-sm text-foreground">
                    {route.from} → {route.to}
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {route.totalDistance} km • {formatTime(remainingTime)} left
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                {gps.error && useRealGPS && (
                  <div className="flex items-center gap-1 px-2 py-1 bg-destructive/20 rounded-full">
                    <WifiOff className="w-3 h-3 text-destructive" />
                    <span className="text-xs font-medium text-destructive">GPS Error</span>
                  </div>
                )}
                {isTracking && !gps.error && (
                  <div className="flex items-center gap-1 px-2 py-1 bg-journey-completed/20 rounded-full">
                    <div className="w-2 h-2 rounded-full bg-journey-completed animate-pulse" />
                    <span className="text-xs font-medium text-journey-completed">
                      {useRealGPS ? 'GPS' : 'Sim'}
                    </span>
                  </div>
                )}
              </div>
            </div>
            {/* Progress Bar */}
            <div className="mt-2 h-1.5 bg-muted rounded-full overflow-hidden">
              <motion.div
                initial={{ width: 0 }}
                animate={{ width: `${currentProgress}%` }}
                className="h-full bg-gradient-to-r from-journey-completed to-journey-active rounded-full"
              />
            </div>
          </div>
        </div>

        {/* Map Controls */}
        <div className="absolute bottom-4 right-4 z-[999] flex flex-col gap-2">
          <Button
            variant="secondary"
            size="icon"
            onClick={handleRecenterRoute}
            className="rounded-full shadow-lg bg-card/95 backdrop-blur-sm"
            title="Re-center route"
          >
            <LocateFixed className="w-5 h-5" />
          </Button>
          <Button
            variant="secondary"
            size="icon"
            onClick={handleCenterOnBus}
            className="rounded-full shadow-lg bg-card/95 backdrop-blur-sm"
            title="Center on bus"
          >
            <Locate className="w-5 h-5" />
          </Button>
          <Button
            variant={useRealGPS ? "default" : "secondary"}
            size="icon"
            onClick={toggleGPSMode}
            className="rounded-full shadow-lg"
            title={useRealGPS ? "Using Real GPS" : "Using Simulation"}
          >
            <Navigation2 className="w-5 h-5" />
          </Button>
         <ShareJourneyButton journeyPassengerId={journeyPassengerId} />
        </div>

        {/* Map */}
        <MapContainer
          center={currentPosition}
          zoom={7}
          className="w-full h-full"
          zoomControl={false}
          attributionControl={false}
          ref={mapRef}
        >
          <TileLayer
            url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
            attribution='&copy; OpenStreetMap'
          />

          {routeCoordinates.length > 0 && (
            <MapBoundsController coordinates={routeCoordinates} />
          )}

          <MapPositionFollower position={currentPosition} shouldFollow={followBus} />

          {routeCoordinates.length > 0 && (
            <RoutePolyline coordinates={routeCoordinates} completedIndex={currentProgress} />
          )}

          {towns.map(town => (
            <TownMarker key={town.id} town={town} onClick={handleTownClick} />
          ))}

          {isTracking && (
            <BusMarker position={currentPosition} heading={heading} />
          )}
        </MapContainer>
      </div>

      {/* Journey Stops Panel - Bottom section ~30-35% */}
      <JourneyStopsPanel
        towns={towns}
        activeTown={activeTown}
        nextTown={nextTown}
        destinationTown={destinationTown}
        onTownClick={handleTownClick}
        onRecenterRoute={handleRecenterRoute}
        onDestinationServices={handleDestinationServices}
      />

      {/* Restaurant Selection Sheet */}
      <RestaurantSheet
        town={selectedTown!}
        restaurants={townRestaurants}
        isOpen={!!selectedTown && !selectedRestaurant}
        onClose={() => setSelectedTown(null)}
        onSelectRestaurant={handleSelectRestaurant}
      />

      {/* Menu & Order Sheet */}
      {selectedRestaurant && selectedTown && (
        <MenuSheet
          restaurant={selectedRestaurant}
          stationName={selectedTown.name}
          isOpen={!!selectedRestaurant}
          onClose={() => {
            setSelectedRestaurant(null);
            setSelectedTown(null);
          }}
          onBack={() => setSelectedRestaurant(null)}
          onPlaceOrder={handlePlaceOrder}
        />
      )}

      {/* Destination Services Sheet (Accommodation & Taxi) */}
      {destinationServicesTown && (
        <DestinationServicesSheet
          town={destinationServicesTown}
          isOpen={!!destinationServicesTown}
          onClose={() => setDestinationServicesTown(null)}
        />
      )}
    </div>
  );
};

export default JourneyView;
