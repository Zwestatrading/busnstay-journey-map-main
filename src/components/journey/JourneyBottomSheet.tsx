import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  MapPin, 
  Check, 
  Clock, 
  Utensils,
  Hotel,
  Car,
  ChevronRight,
  Star,
  Navigation,
  Wifi,
  Bus
} from 'lucide-react';
import { Town, Service, Journey } from '@/types/journey';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';

interface JourneyBottomSheetProps {
  journey: Journey | null;
  towns: Town[];
  services: Service[];
  activeTown: Town | null;
  nextTown: Town | null;
  destinationTown: Town | null;
  isTracking: boolean;
  onTownClick: (town: Town) => void;
  onOrderFood: (town: Town, service: Service) => void;
  onBookAccommodation: (town: Town, service: Service) => void;
  onBookTaxi: (town: Town, service: Service, type: 'accommodation' | 'home') => void;
}

const JourneyBottomSheet = ({ 
  journey,
  towns, 
  services,
  activeTown,
  nextTown,
  destinationTown,
  isTracking,
  onTownClick, 
  onOrderFood,
  onBookAccommodation,
  onBookTaxi,
}: JourneyBottomSheetProps) => {
  const [expandedTown, setExpandedTown] = useState<string | null>(null);

  const getStatusIcon = (status: Town['status']) => {
    switch (status) {
      case 'completed':
        return <Check className="w-3 h-3" />;
      case 'active':
        return <div className="w-2 h-2 rounded-full bg-current animate-pulse" />;
      case 'upcoming':
        return <Clock className="w-3 h-3" />;
    }
  };

  const getStatusColor = (status: Town['status']) => {
    switch (status) {
      case 'completed':
        return 'bg-journey-completed text-journey-completed-foreground';
      case 'active':
        return 'bg-journey-active text-journey-active-foreground';
      case 'upcoming':
        return 'bg-journey-upcoming text-journey-upcoming-foreground';
    }
  };

  const getTownServices = (townId: string) => services.filter(s => s.townId === townId);
  const isDestination = (town: Town) => destinationTown?.id === town.id;

  const formatTime = (minutes: number) => {
    const hrs = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`;
  };

  return (
    <div className="flex-1 bg-card rounded-t-3xl -mt-4 relative z-10 flex flex-col shadow-[0_-4px_20px_rgba(0,0,0,0.1)]">
      {/* Handle */}
      <div className="flex justify-center py-3">
        <div className="w-12 h-1.5 rounded-full bg-muted" />
      </div>

      {/* Quick Stats */}
      {journey && (
        <div className="px-4 pb-3 flex gap-3">
          <div className="flex-1 bg-muted/50 rounded-xl p-3">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <Navigation className="w-4 h-4" />
              <span className="text-xs">Current</span>
            </div>
            <p className="font-display font-bold text-sm text-foreground truncate">
              {activeTown?.name || 'Starting...'}
            </p>
          </div>
          <div className="flex-1 bg-muted/50 rounded-xl p-3">
            <div className="flex items-center gap-2 text-muted-foreground mb-1">
              <MapPin className="w-4 h-4" />
              <span className="text-xs">Next Stop</span>
            </div>
            <p className="font-display font-bold text-sm text-foreground truncate">
              {nextTown?.name || destinationTown?.name || '-'}
            </p>
          </div>
        </div>
      )}

      {/* Section Header */}
      <div className="px-4 py-2 flex items-center justify-between border-b border-border/50">
        <div className="flex items-center gap-2">
          <Bus className="w-5 h-5 text-primary" />
          <span className="font-display font-semibold text-foreground">Journey Stops</span>
        </div>
        <span className="text-xs text-muted-foreground px-2 py-1 bg-muted rounded-full">
          {towns.length} stops
        </span>
      </div>

      {/* Scrollable Timeline */}
      <ScrollArea className="flex-1">
        <div className="p-4 space-y-2">
          {towns.map((town, index) => {
            const townServices = getTownServices(town.id);
            const restaurants = townServices.filter(s => s.type === 'restaurant');
            const hotels = townServices.filter(s => s.type === 'hotel');
            const taxis = townServices.filter(s => s.type === 'taxi');
            const isExpanded = expandedTown === town.id;
            const isDest = isDestination(town);
            
            return (
              <motion.div
                key={town.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: index * 0.02 }}
              >
                <button
                  onClick={() => {
                    onTownClick(town);
                    setExpandedTown(isExpanded ? null : town.id);
                  }}
                  className={cn(
                    "w-full flex items-center gap-3 p-4 rounded-2xl transition-all text-left",
                    "active:scale-[0.98]",
                    town.status === 'active' && "bg-accent/10 ring-2 ring-accent/30",
                    isDest && "bg-primary/10 ring-2 ring-primary/30",
                    town.status !== 'active' && !isDest && "bg-muted/30 hover:bg-muted/50"
                  )}
                >
                  {/* Status Indicator */}
                  <div className={cn(
                    "w-10 h-10 rounded-xl flex items-center justify-center shrink-0",
                    getStatusColor(town.status)
                  )}>
                    {getStatusIcon(town.status)}
                  </div>

                  {/* Town Info */}
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className={cn(
                        "font-display font-bold truncate",
                        town.status === 'active' && "text-accent",
                        isDest && "text-primary"
                      )}>
                        {town.name}
                      </span>
                      {isDest && (
                        <span className="text-[10px] px-2 py-0.5 bg-primary text-primary-foreground rounded-full shrink-0">
                          Destination
                        </span>
                      )}
                    </div>
                    <div className="flex items-center gap-3 text-sm text-muted-foreground mt-0.5">
                      <span>{town.distance} km</span>
                      {restaurants.length > 0 && (
                        <span className="flex items-center gap-1">
                          <Utensils className="w-3 h-3" />
                          {restaurants.length}
                        </span>
                      )}
                      {isDest && hotels.length > 0 && (
                        <span className="flex items-center gap-1">
                          <Hotel className="w-3 h-3" />
                          {hotels.length}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Expand Arrow */}
                  <motion.div
                    animate={{ rotate: isExpanded ? 90 : 0 }}
                    className="shrink-0"
                  >
                    <ChevronRight className="w-5 h-5 text-muted-foreground" />
                  </motion.div>
                </button>

                {/* Expanded Services */}
                <AnimatePresence>
                  {isExpanded && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      className="overflow-hidden"
                    >
                      <div className="pt-2 pb-4 px-2 space-y-4">
                        {/* Food Orders */}
                        {(town.status === 'upcoming' || town.status === 'active') && restaurants.length > 0 && (
                          <div className="bg-muted/30 rounded-xl p-3">
                            <p className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                              <Utensils className="w-4 h-4 text-service-restaurant" />
                              Order Food
                            </p>
                            <div className="space-y-2">
                              {restaurants.map(restaurant => (
                                <button
                                  key={restaurant.id}
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onOrderFood(town, restaurant);
                                  }}
                                  className="w-full p-3 rounded-xl bg-card border border-border/50 flex items-center gap-3 active:scale-[0.98] transition-transform"
                                >
                                  <div className="w-12 h-12 rounded-xl bg-service-restaurant flex items-center justify-center shrink-0">
                                    <Utensils className="w-5 h-5 text-white" />
                                  </div>
                                  <div className="flex-1 text-left">
                                    <p className="font-semibold text-foreground">{restaurant.name}</p>
                                    <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                      <Star className="w-3 h-3 text-accent fill-accent" />
                                      <span>{restaurant.rating.toFixed(1)}</span>
                                      <span>•</span>
                                      <span className="font-medium text-foreground">${restaurant.price}</span>
                                    </div>
                                  </div>
                                  <span className={cn(
                                    "text-sm font-bold px-3 py-1.5 rounded-lg",
                                    town.status === 'active' 
                                      ? "bg-accent text-accent-foreground" 
                                      : "bg-muted text-muted-foreground"
                                  )}>
                                    {town.status === 'active' ? 'Order' : 'Pre-order'}
                                  </span>
                                </button>
                              ))}
                            </div>
                          </div>
                        )}

                        {/* Destination Services */}
                        {isDest && (
                          <>
                            {/* Accommodation */}
                            {hotels.length > 0 && (
                              <div className="bg-muted/30 rounded-xl p-3">
                                <p className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                                  <Hotel className="w-4 h-4 text-service-hotel" />
                                  Book Accommodation
                                </p>
                                <div className="space-y-2">
                                  {hotels.map(hotel => (
                                    <button
                                      key={hotel.id}
                                      onClick={(e) => {
                                        e.stopPropagation();
                                        onBookAccommodation(town, hotel);
                                      }}
                                      className="w-full p-3 rounded-xl bg-card border border-border/50 flex items-center gap-3 active:scale-[0.98] transition-transform"
                                    >
                                      <div className="w-12 h-12 rounded-xl bg-service-hotel flex items-center justify-center shrink-0">
                                        <Hotel className="w-5 h-5 text-white" />
                                      </div>
                                      <div className="flex-1 text-left">
                                        <p className="font-semibold text-foreground">{hotel.name}</p>
                                        <div className="flex items-center gap-2 text-sm text-muted-foreground">
                                          <Star className="w-3 h-3 text-accent fill-accent" />
                                          <span>{hotel.rating.toFixed(1)}</span>
                                          <span>•</span>
                                          <span className="font-medium text-foreground">${hotel.price}/night</span>
                                        </div>
                                      </div>
                                      <span className="text-sm font-bold px-3 py-1.5 rounded-lg bg-service-hotel text-white">
                                        Book
                                      </span>
                                    </button>
                                  ))}
                                </div>
                              </div>
                            )}

                            {/* Taxi Options */}
                            {taxis.length > 0 && (
                              <div className="bg-muted/30 rounded-xl p-3">
                                <p className="text-sm font-semibold text-foreground mb-3 flex items-center gap-2">
                                  <Car className="w-4 h-4 text-service-taxi" />
                                  Book Transport
                                </p>
                                <div className="grid grid-cols-2 gap-2">
                                  <Button
                                    variant="outline"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      onBookTaxi(town, taxis[0], 'accommodation');
                                    }}
                                    className="h-auto py-3 flex-col gap-1 border-service-taxi/50 hover:bg-service-taxi/10"
                                  >
                                    <Car className="w-5 h-5 text-service-taxi" />
                                    <span className="text-sm font-medium">To Hotel</span>
                                  </Button>
                                  <Button
                                    variant="outline"
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      onBookTaxi(town, taxis[0], 'home');
                                    }}
                                    className="h-auto py-3 flex-col gap-1 border-service-taxi/50 hover:bg-service-taxi/10"
                                  >
                                    <Car className="w-5 h-5 text-service-taxi" />
                                    <span className="text-sm font-medium">Home</span>
                                  </Button>
                                </div>
                              </div>
                            )}
                          </>
                        )}

                        {/* No services */}
                        {restaurants.length === 0 && !isDest && (
                          <p className="text-sm text-muted-foreground text-center py-2">
                            No services available at this stop
                          </p>
                        )}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            );
          })}
        </div>
      </ScrollArea>
    </div>
  );
};

export default JourneyBottomSheet;
