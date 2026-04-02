import { motion } from 'framer-motion';
import { 
  MapPin, 
  Check, 
  Clock, 
  Utensils,
  Hotel,
  Car,
  ChevronRight,
  Navigation,
  Bus,
  LocateFixed
} from 'lucide-react';
import { Town } from '@/types/journey';
import { cn } from '@/lib/utils';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';

interface JourneyStopsPanelProps {
  towns: Town[];
  activeTown: Town | null;
  nextTown: Town | null;
  destinationTown: Town | null;
  onTownClick: (town: Town) => void;
  onRecenterRoute: () => void;
  onDestinationServices?: (town: Town) => void;
}

const JourneyStopsPanel = ({ 
  towns, 
  activeTown,
  nextTown,
  destinationTown,
  onTownClick,
  onRecenterRoute,
  onDestinationServices,
}: JourneyStopsPanelProps) => {

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

  const isDestination = (town: Town) => destinationTown?.id === town.id;

  return (
    <div className="flex-1 bg-card rounded-t-3xl -mt-4 relative z-10 flex flex-col shadow-[0_-4px_20px_rgba(0,0,0,0.1)]">
      {/* Handle */}
      <div className="flex justify-center py-3">
        <div className="w-12 h-1.5 rounded-full bg-muted" />
      </div>

      {/* Header */}
      <div className="px-4 pb-3 flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Bus className="w-5 h-5 text-primary" />
          <span className="font-display font-semibold text-foreground">Journey Stops</span>
          <span className="text-xs text-muted-foreground px-2 py-0.5 bg-muted rounded-full">
            {towns.length} stops
          </span>
        </div>
        <Button 
          variant="ghost" 
          size="sm" 
          onClick={onRecenterRoute}
          className="text-xs gap-1"
        >
          <LocateFixed className="w-3.5 h-3.5" />
          Re-center
        </Button>
      </div>

      {/* Quick Info */}
      {activeTown && (
        <div className="px-4 pb-3 flex gap-3">
          <div className="flex-1 bg-journey-active/10 rounded-xl p-3 border border-journey-active/20">
            <div className="flex items-center gap-2 text-journey-active mb-0.5">
              <Navigation className="w-3.5 h-3.5" />
              <span className="text-xs font-medium">Current</span>
            </div>
            <p className="font-display font-bold text-sm text-foreground truncate">
              {activeTown.name}
            </p>
          </div>
          {nextTown && (
            <div className="flex-1 bg-muted/50 rounded-xl p-3">
              <div className="flex items-center gap-2 text-muted-foreground mb-0.5">
                <MapPin className="w-3.5 h-3.5" />
                <span className="text-xs font-medium">Next</span>
              </div>
              <p className="font-display font-bold text-sm text-foreground truncate">
                {nextTown.name}
              </p>
            </div>
          )}
        </div>
      )}

      {/* Stops List */}
      <ScrollArea className="flex-1 px-4 pb-4">
        <div className="space-y-2">
          {towns.map((town, index) => {
            const isDest = isDestination(town);
            const hasRestaurants = town.services.restaurants > 0;
            const hasHotels = (town.services as any).hotels > 0;
            const hasTaxis = (town.services as any).taxis > 0;
            const hasDestServices = isDest && (hasHotels || hasTaxis);
            
            return (
              <motion.button
                key={town.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.02 }}
                onClick={() => {
                  if (hasDestServices && onDestinationServices) {
                    onDestinationServices(town);
                  } else {
                    onTownClick(town);
                  }
                }}
                className={cn(
                  "w-full flex items-center gap-3 p-3 rounded-xl transition-all text-left",
                  "active:scale-[0.98] hover:bg-muted/50",
                  town.status === 'active' && "bg-journey-active/10 ring-1 ring-journey-active/30",
                  isDest && "bg-primary/10 ring-1 ring-primary/30",
                  town.status === 'completed' && "opacity-60"
                )}
              >
                {/* Status Dot */}
                <div className={cn(
                  "w-8 h-8 rounded-lg flex items-center justify-center shrink-0",
                  getStatusColor(town.status)
                )}>
                  {getStatusIcon(town.status)}
                </div>

                {/* Town Info */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className={cn(
                      "font-semibold truncate text-sm",
                      town.status === 'active' && "text-journey-active",
                      isDest && "text-primary"
                    )}>
                      {town.name}
                    </span>
                    {isDest && (
                      <span className="text-[10px] px-1.5 py-0.5 bg-primary text-primary-foreground rounded shrink-0">
                        Destination
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground mt-0.5">
                    <span>{town.distance} km</span>
                    {hasRestaurants && (
                      <>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <Utensils className="w-3 h-3" />
                          {town.services.restaurants}
                        </span>
                      </>
                    )}
                    {isDest && hasHotels && (
                      <>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <Hotel className="w-3 h-3" />
                          Hotels
                        </span>
                      </>
                    )}
                    {isDest && hasTaxis && (
                      <>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <Car className="w-3 h-3" />
                          Taxis
                        </span>
                      </>
                    )}
                  </div>
                </div>

                {/* Tap hint */}
                {(hasRestaurants || hasDestServices) && town.status !== 'completed' && (
                  <div className="shrink-0 flex items-center gap-1 text-xs text-muted-foreground">
                    <span className="hidden sm:inline">
                      {hasDestServices ? 'Book' : 'Order'}
                    </span>
                    <ChevronRight className="w-4 h-4" />
                  </div>
                )}
              </motion.button>
            );
          })}
        </div>
      </ScrollArea>
    </div>
  );
};

export default JourneyStopsPanel;
