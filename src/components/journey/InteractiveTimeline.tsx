import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  MapPin, 
  Check, 
  Clock, 
  Utensils,
  Hotel,
  Car,
  ChevronDown,
  Star
} from 'lucide-react';
import { Town, Service } from '@/types/journey';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';

interface InteractiveTimelineProps {
  towns: Town[];
  services: Service[];
  onTownClick: (town: Town) => void;
  onOrderFood: (town: Town, service: Service) => void;
  onBookAccommodation: (town: Town, service: Service) => void;
  onBookTaxi: (town: Town, service: Service, type: 'accommodation' | 'home') => void;
  destinationTown: Town | null;
}

const InteractiveTimeline = ({ 
  towns, 
  services,
  onTownClick, 
  onOrderFood,
  onBookAccommodation,
  onBookTaxi,
  destinationTown
}: InteractiveTimelineProps) => {
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
        return 'bg-journey-active text-journey-active-foreground animate-glow';
      case 'upcoming':
        return 'bg-journey-upcoming text-journey-upcoming-foreground';
    }
  };

  const getSizeIndicator = (size: Town['size']) => {
    switch (size) {
      case 'major':
        return 'w-6 h-6';
      case 'medium':
        return 'w-5 h-5';
      case 'minor':
        return 'w-4 h-4';
    }
  };

  const getTownServices = (townId: string) => {
    return services.filter(s => s.townId === townId);
  };

  const isDestination = (town: Town) => {
    return destinationTown?.id === town.id;
  };

  return (
    <div className="space-y-1">
      <div className="flex items-center gap-2 px-2 py-3 border-b border-border/50">
        <MapPin className="w-5 h-5 text-primary" />
        <span className="font-display font-semibold text-foreground">Journey Stops</span>
        <span className="text-xs text-muted-foreground ml-auto">{towns.length} stops</span>
      </div>

      <div className="max-h-[400px] overflow-y-auto space-y-1 p-2">
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
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.03 }}
            >
              <button
                onClick={() => {
                  onTownClick(town);
                  setExpandedTown(isExpanded ? null : town.id);
                }}
                className={cn(
                  "w-full flex items-center gap-3 p-3 rounded-xl transition-all text-left",
                  "hover:bg-muted/70",
                  town.status === 'active' && "bg-accent/10 ring-1 ring-accent/30",
                  isDest && "bg-primary/10 ring-1 ring-primary/30"
                )}
              >
                {/* Status Indicator */}
                <div className="flex flex-col items-center">
                  <div className={cn(
                    "rounded-full flex items-center justify-center",
                    getSizeIndicator(town.size),
                    getStatusColor(town.status)
                  )}>
                    {getStatusIcon(town.status)}
                  </div>
                  {index < towns.length - 1 && (
                    <div className={cn(
                      "w-0.5 h-6 mt-1",
                      town.status === 'completed' 
                        ? "bg-journey-completed" 
                        : "bg-border"
                    )} />
                  )}
                </div>

                {/* Town Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className={cn(
                      "font-medium truncate",
                      town.size === 'major' && "font-display font-bold",
                      town.status === 'active' && "text-accent",
                      isDest && "text-primary"
                    )}>
                      {town.name}
                    </span>
                    {isDest && (
                      <span className="text-[10px] px-1.5 py-0.5 bg-primary/20 text-primary rounded-full">
                        Destination
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{town.distance} km</span>
                    {town.status === 'upcoming' && restaurants.length > 0 && (
                      <>
                        <span>•</span>
                        <Utensils className="w-3 h-3" />
                        <span>{restaurants.length}</span>
                      </>
                    )}
                  </div>
                </div>

                {/* Expand Icon */}
                <motion.div
                  animate={{ rotate: isExpanded ? 180 : 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <ChevronDown className="w-4 h-4 text-muted-foreground" />
                </motion.div>
              </button>

              {/* Expanded Services */}
              <AnimatePresence>
                {isExpanded && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.2 }}
                    className="overflow-hidden"
                  >
                    <div className="pl-9 pr-2 pb-3 space-y-3">
                      {/* Food Orders - Available for upcoming/active towns */}
                      {(town.status === 'upcoming' || town.status === 'active') && restaurants.length > 0 && (
                        <div>
                          <p className="text-xs font-medium text-muted-foreground mb-2 flex items-center gap-1">
                            <Utensils className="w-3 h-3" /> Order Food
                          </p>
                          <div className="space-y-2">
                            {restaurants.slice(0, 3).map(restaurant => (
                              <button
                                key={restaurant.id}
                                onClick={(e) => {
                                  e.stopPropagation();
                                  onOrderFood(town, restaurant);
                                }}
                                className="w-full p-2 rounded-lg bg-card hover:bg-muted/50 border border-border/50 flex items-center gap-2 transition-colors"
                              >
                                <div className="w-8 h-8 rounded-lg bg-service-restaurant flex items-center justify-center">
                                  <Utensils className="w-4 h-4 text-white" />
                                </div>
                                <div className="flex-1 text-left">
                                  <p className="text-sm font-medium truncate">{restaurant.name}</p>
                                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                    <Star className="w-3 h-3 text-accent fill-accent" />
                                    <span>{restaurant.rating.toFixed(1)}</span>
                                    <span>•</span>
                                    <span>${restaurant.price}</span>
                                  </div>
                                </div>
                                <span className="text-xs text-accent font-medium">
                                  {town.status === 'active' ? 'Order' : 'Pre-order'}
                                </span>
                              </button>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Destination Booking - Only for final destination */}
                      {isDest && (
                        <>
                          {/* Accommodation */}
                          {hotels.length > 0 && (
                            <div>
                              <p className="text-xs font-medium text-muted-foreground mb-2 flex items-center gap-1">
                                <Hotel className="w-3 h-3" /> Book Accommodation
                              </p>
                              <div className="space-y-2">
                                {hotels.slice(0, 2).map(hotel => (
                                  <button
                                    key={hotel.id}
                                    onClick={(e) => {
                                      e.stopPropagation();
                                      onBookAccommodation(town, hotel);
                                    }}
                                    className="w-full p-2 rounded-lg bg-card hover:bg-muted/50 border border-border/50 flex items-center gap-2 transition-colors"
                                  >
                                    <div className="w-8 h-8 rounded-lg bg-service-hotel flex items-center justify-center">
                                      <Hotel className="w-4 h-4 text-white" />
                                    </div>
                                    <div className="flex-1 text-left">
                                      <p className="text-sm font-medium truncate">{hotel.name}</p>
                                      <div className="flex items-center gap-2 text-xs text-muted-foreground">
                                        <Star className="w-3 h-3 text-accent fill-accent" />
                                        <span>{hotel.rating.toFixed(1)}</span>
                                        <span>•</span>
                                        <span>${hotel.price}/night</span>
                                      </div>
                                    </div>
                                    <span className="text-xs text-service-hotel font-medium">Book</span>
                                  </button>
                                ))}
                              </div>
                            </div>
                          )}

                          {/* Taxi Options */}
                          {taxis.length > 0 && (
                            <div>
                              <p className="text-xs font-medium text-muted-foreground mb-2 flex items-center gap-1">
                                <Car className="w-3 h-3" /> Book Transport
                              </p>
                              <div className="grid grid-cols-2 gap-2">
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onBookTaxi(town, taxis[0], 'accommodation');
                                  }}
                                  className="text-xs h-auto py-2 border-service-taxi/50 hover:bg-service-taxi/10"
                                >
                                  <Car className="w-3 h-3 mr-1" />
                                  To Hotel
                                </Button>
                                <Button
                                  variant="outline"
                                  size="sm"
                                  onClick={(e) => {
                                    e.stopPropagation();
                                    onBookTaxi(town, taxis[0], 'home');
                                  }}
                                  className="text-xs h-auto py-2 border-service-taxi/50 hover:bg-service-taxi/10"
                                >
                                  <Car className="w-3 h-3 mr-1" />
                                  Home
                                </Button>
                              </div>
                            </div>
                          )}
                        </>
                      )}

                      {/* No services message */}
                      {restaurants.length === 0 && !isDest && (
                        <p className="text-xs text-muted-foreground italic">
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
    </div>
  );
};

export default InteractiveTimeline;
