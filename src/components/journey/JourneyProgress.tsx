import { motion } from 'framer-motion';
import { 
  Bus, 
  MapPin, 
  Clock, 
  Navigation,
  Wifi,
  Battery
} from 'lucide-react';
import { Journey, Town } from '@/types/journey';
import { cn } from '@/lib/utils';

interface JourneyProgressProps {
  journey: Journey;
  activeTown: Town | null;
  nextTown: Town | null;
  isTracking: boolean;
}

const JourneyProgress = ({ journey, activeTown, nextTown, isTracking }: JourneyProgressProps) => {
  const formatTime = (minutes: number) => {
    const hrs = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hrs > 0 ? `${hrs}h ${mins}m` : `${mins}m`;
  };

  const remainingTime = Math.round(journey.estimatedDuration * (1 - journey.progress / 100));
  const remainingDistance = Math.round(journey.totalDistance * (1 - journey.progress / 100));

  return (
    <div className="glass-card rounded-2xl p-4 space-y-4">
      {/* Header with Tracking Status */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className={cn(
            "w-8 h-8 rounded-lg flex items-center justify-center",
            isTracking ? "bg-journey-active" : "bg-muted"
          )}>
            <Bus className="w-4 h-4 text-white" />
          </div>
          <div>
            <h3 className="font-display font-bold text-foreground">Live Journey</h3>
            <p className="text-xs text-muted-foreground">
              {journey.startTown.name} → {journey.endTown.name}
            </p>
          </div>
        </div>
        
        {/* Tracking Indicator */}
        <div className="flex items-center gap-2">
          {isTracking && (
            <motion.div
              animate={{ opacity: [1, 0.5, 1] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="flex items-center gap-1 text-xs text-journey-completed"
            >
              <Wifi className="w-3 h-3" />
              <span>Live</span>
            </motion.div>
          )}
          <div className="flex items-center gap-1 text-xs text-muted-foreground">
            <Battery className="w-3 h-3" />
            <span>GPS</span>
          </div>
        </div>
      </div>

      {/* Progress Bar */}
      <div className="space-y-2">
        <div className="flex justify-between text-xs">
          <span className="text-muted-foreground">Progress</span>
          <span className="font-medium text-foreground">{journey.progress}%</span>
        </div>
        <div className="h-2 bg-muted rounded-full overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${journey.progress}%` }}
            transition={{ duration: 0.5 }}
            className="h-full journey-progress rounded-full"
          />
        </div>
      </div>

      {/* Current & Next Stop */}
      <div className="grid grid-cols-2 gap-3">
        {activeTown && (
          <div className="bg-accent/10 rounded-xl p-3">
            <div className="flex items-center gap-1 text-xs text-muted-foreground mb-1">
              <Navigation className="w-3 h-3" />
              <span>Current</span>
            </div>
            <p className="font-medium text-foreground truncate">{activeTown.name}</p>
            <p className="text-xs text-muted-foreground">{activeTown.distance} km</p>
          </div>
        )}
        
        {nextTown && (
          <div className="bg-muted/50 rounded-xl p-3">
            <div className="flex items-center gap-1 text-xs text-muted-foreground mb-1">
              <MapPin className="w-3 h-3" />
              <span>Next Stop</span>
            </div>
            <p className="font-medium text-foreground truncate">{nextTown.name}</p>
            <p className="text-xs text-muted-foreground">{nextTown.distance} km</p>
          </div>
        )}
      </div>

      {/* Stats Row */}
      <div className="flex items-center justify-between pt-2 border-t border-border/50">
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-muted-foreground" />
          <div>
            <p className="text-xs text-muted-foreground">Time Left</p>
            <p className="font-medium text-foreground">{formatTime(remainingTime)}</p>
          </div>
        </div>
        
        <div className="flex items-center gap-2">
          <MapPin className="w-4 h-4 text-muted-foreground" />
          <div className="text-right">
            <p className="text-xs text-muted-foreground">Distance Left</p>
            <p className="font-medium text-foreground">{remainingDistance} km</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default JourneyProgress;
