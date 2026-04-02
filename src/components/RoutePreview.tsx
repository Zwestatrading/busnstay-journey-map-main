import { useMemo } from 'react';
import { motion } from 'framer-motion';
import { 
  ArrowLeft, 
  ArrowRight, 
  Bus, 
  Clock, 
  MapPin, 
  Navigation, 
  Route,
  Circle,
  CheckCircle2
} from 'lucide-react';
import { Button } from '@/components/ui/button';
import { RouteDefinition, zambianTownsDatabase, calculateDistance } from '@/data/zambiaRoutes';
import { cn } from '@/lib/utils';

interface RoutePreviewProps {
  route: RouteDefinition;
  onStartJourney: () => void;
  onBack: () => void;
}

const RoutePreview = ({ route, onStartJourney, onBack }: RoutePreviewProps) => {
  // Build detailed stop information
  const stops = useMemo(() => {
    let cumulativeDistance = 0;
    let cumulativeTime = 0;
    
    return route.stops.map((stopId, index) => {
      const town = zambianTownsDatabase[stopId] || zambianTownsDatabase[stopId.replace('-', '')];
      
      if (index > 0) {
        const prevStopId = route.stops[index - 1];
        const prevTown = zambianTownsDatabase[prevStopId] || zambianTownsDatabase[prevStopId.replace('-', '')];
        if (prevTown && town) {
          const segmentDistance = calculateDistance(prevTown.coordinates, town.coordinates);
          cumulativeDistance += segmentDistance;
          cumulativeTime += (segmentDistance / route.totalDistance) * route.estimatedDuration;
        }
      }
      
      return {
        id: stopId,
        name: town?.name || stopId,
        region: town?.region || '',
        size: town?.size || 'minor',
        distance: Math.round(cumulativeDistance),
        time: Math.round(cumulativeTime),
        isStart: index === 0,
        isEnd: index === route.stops.length - 1,
        isTransfer: index > 0 && index < route.stops.length - 1 && town?.size === 'major'
      };
    });
  }, [route]);

  const formatDuration = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    if (hours === 0) return `${mins} min`;
    if (mins === 0) return `${hours}h`;
    return `${hours}h ${mins}m`;
  };

  const majorStops = stops.filter(s => s.size === 'major' || s.isStart || s.isEnd);

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/5 via-background to-background flex flex-col">
      {/* Header */}
      <header className="p-4 flex items-center gap-3 border-b border-border/50">
        <Button
          variant="ghost"
          size="icon"
          onClick={onBack}
          className="rounded-full"
        >
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div className="flex-1">
          <h1 className="font-display font-bold text-lg text-foreground">Route Preview</h1>
          <p className="text-xs text-muted-foreground">Review your journey details</p>
        </div>
      </header>

      {/* Main Content */}
      <div className="flex-1 overflow-auto px-4 py-6 space-y-6">
        {/* Route Summary Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="bg-card rounded-2xl p-5 shadow-lg border border-border/50"
        >
          {/* From → To */}
          <div className="flex items-center gap-3 mb-4">
            <div className="flex-1">
              <p className="text-xs text-muted-foreground mb-1">From</p>
              <p className="font-display font-bold text-lg text-foreground">{stops[0]?.name}</p>
              <p className="text-xs text-muted-foreground">{stops[0]?.region}</p>
            </div>
            <div className="w-10 h-10 rounded-full bg-primary/10 flex items-center justify-center">
              <ArrowRight className="w-5 h-5 text-primary" />
            </div>
            <div className="flex-1 text-right">
              <p className="text-xs text-muted-foreground mb-1">To</p>
              <p className="font-display font-bold text-lg text-foreground">{stops[stops.length - 1]?.name}</p>
              <p className="text-xs text-muted-foreground">{stops[stops.length - 1]?.region}</p>
            </div>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-4 pt-4 border-t border-border/50">
            <div className="text-center">
              <div className="w-10 h-10 mx-auto rounded-xl bg-journey-active/10 flex items-center justify-center mb-2">
                <Route className="w-5 h-5 text-journey-active" />
              </div>
              <p className="font-display font-bold text-foreground">{route.totalDistance} km</p>
              <p className="text-xs text-muted-foreground">Distance</p>
            </div>
            <div className="text-center">
              <div className="w-10 h-10 mx-auto rounded-xl bg-primary/10 flex items-center justify-center mb-2">
                <Clock className="w-5 h-5 text-primary" />
              </div>
              <p className="font-display font-bold text-foreground">{formatDuration(route.estimatedDuration)}</p>
              <p className="text-xs text-muted-foreground">Duration</p>
            </div>
            <div className="text-center">
              <div className="w-10 h-10 mx-auto rounded-xl bg-journey-completed/10 flex items-center justify-center mb-2">
                <MapPin className="w-5 h-5 text-journey-completed" />
              </div>
              <p className="font-display font-bold text-foreground">{route.stops.length}</p>
              <p className="text-xs text-muted-foreground">Stops</p>
            </div>
          </div>
        </motion.div>

        {/* Key Stops */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="space-y-3"
        >
          <h2 className="font-display font-semibold text-foreground px-1">Key Stops</h2>
          <div className="bg-card rounded-2xl overflow-hidden border border-border/50">
            {majorStops.map((stop, index) => (
              <div 
                key={stop.id}
                className={cn(
                  "flex items-center gap-3 p-4",
                  index < majorStops.length - 1 && "border-b border-border/30"
                )}
              >
                <div className="relative">
                  <div className={cn(
                    "w-10 h-10 rounded-full flex items-center justify-center",
                    stop.isStart && "bg-journey-completed text-journey-completed-foreground",
                    stop.isEnd && "bg-journey-active text-journey-active-foreground",
                    !stop.isStart && !stop.isEnd && "bg-muted text-muted-foreground"
                  )}>
                    {stop.isStart ? (
                      <Navigation className="w-5 h-5" />
                    ) : stop.isEnd ? (
                      <MapPin className="w-5 h-5" />
                    ) : (
                      <Bus className="w-5 h-5" />
                    )}
                  </div>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-semibold text-foreground">{stop.name}</p>
                  <p className="text-xs text-muted-foreground">{stop.region}</p>
                </div>
                <div className="text-right">
                  {stop.isStart ? (
                    <span className="text-xs font-medium text-journey-completed">Start</span>
                  ) : (
                    <>
                      <p className="text-sm font-medium text-foreground">{stop.distance} km</p>
                      <p className="text-xs text-muted-foreground">{formatDuration(stop.time)}</p>
                    </>
                  )}
                </div>
              </div>
            ))}
          </div>
        </motion.div>

        {/* All Stops Timeline */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="space-y-3"
        >
          <h2 className="font-display font-semibold text-foreground px-1">All Stops ({stops.length})</h2>
          <div className="bg-card rounded-2xl p-4 border border-border/50">
            <div className="relative">
              {/* Vertical Line */}
              <div className="absolute left-[11px] top-3 bottom-3 w-0.5 bg-border" />
              
              {/* Stops */}
              <div className="space-y-3">
                {stops.map((stop, index) => (
                  <motion.div
                    key={stop.id}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.3 + index * 0.03 }}
                    className="flex items-center gap-3 relative"
                  >
                    <div className={cn(
                      "w-6 h-6 rounded-full flex items-center justify-center z-10",
                      stop.isStart && "bg-journey-completed",
                      stop.isEnd && "bg-journey-active",
                      !stop.isStart && !stop.isEnd && stop.size === 'major' && "bg-primary",
                      !stop.isStart && !stop.isEnd && stop.size === 'medium' && "bg-muted-foreground",
                      !stop.isStart && !stop.isEnd && stop.size === 'minor' && "bg-border"
                    )}>
                      {(stop.isStart || stop.isEnd || stop.size === 'major') ? (
                        <CheckCircle2 className="w-3.5 h-3.5 text-white" />
                      ) : (
                        <Circle className="w-2 h-2 text-white fill-current" />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className={cn(
                        "text-sm",
                        (stop.isStart || stop.isEnd || stop.size === 'major') ? "font-semibold text-foreground" : "text-muted-foreground"
                      )}>
                        {stop.name}
                      </p>
                    </div>
                    {!stop.isStart && (
                      <p className="text-xs text-muted-foreground">{stop.distance} km</p>
                    )}
                  </motion.div>
                ))}
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Bottom Action */}
      <div className="p-4 border-t border-border/50 bg-card/80 backdrop-blur-sm">
        <Button
          onClick={onStartJourney}
          className="w-full h-14 text-base font-semibold bg-primary hover:bg-primary/90 rounded-xl"
        >
          <Bus className="w-5 h-5 mr-2" />
          Start Journey
        </Button>
      </div>
    </div>
  );
};

export default RoutePreview;
