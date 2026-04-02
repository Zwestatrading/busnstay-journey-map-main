import { motion } from 'framer-motion';
import { 
  Bus, 
  Clock, 
  MapPin, 
  Navigation2,
  ChevronDown,
  Signal
} from 'lucide-react';
import { Journey, Town } from '@/types/journey';

interface JourneyHeaderProps {
  journey: Journey;
  activeTown: Town | null;
  nextTown: Town | null;
}

const JourneyHeader = ({ journey, activeTown, nextTown }: JourneyHeaderProps) => {
  const formatTime = (minutes: number) => {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return `${hours}h ${mins}m`;
  };

  const remainingDistance = journey.totalDistance * (1 - journey.progress / 100);
  const remainingTime = journey.estimatedDuration * (1 - journey.progress / 100);

  return (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      className="absolute top-4 left-4 right-20 z-[1000]"
    >
      <div className="glass-card-dark rounded-2xl p-4 text-white">
        {/* Main Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-accent flex items-center justify-center">
              <Bus className="w-6 h-6 text-accent-foreground" />
            </div>
            <div>
              <h1 className="font-display text-lg font-bold">
                {journey.startTown.name} → {journey.endTown.name}
              </h1>
              <div className="flex items-center gap-2 text-sm text-white/70">
                <Signal className="w-3 h-3 text-journey-completed" />
                <span>Live Tracking</span>
              </div>
            </div>
          </div>
          
          <div className="flex items-center gap-4 text-right">
            <div>
              <p className="text-xs text-white/60">Remaining</p>
              <p className="font-display font-bold text-accent">
                {Math.round(remainingDistance)} km
              </p>
            </div>
            <div className="w-px h-8 bg-white/20" />
            <div>
              <p className="text-xs text-white/60">ETA</p>
              <p className="font-display font-bold">
                {formatTime(Math.round(remainingTime))}
              </p>
            </div>
          </div>
        </div>

        {/* Progress Bar */}
        <div className="relative">
          <div className="h-2 bg-white/10 rounded-full overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${journey.progress}%` }}
              transition={{ duration: 1, ease: 'easeOut' }}
              className="h-full rounded-full journey-progress"
            />
          </div>
          <div className="flex justify-between mt-2 text-xs">
            <span className="text-white/60">{journey.startTown.name}</span>
            <span className="text-accent font-semibold">{journey.progress}% complete</span>
            <span className="text-white/60">{journey.endTown.name}</span>
          </div>
        </div>

        {/* Current & Next Town */}
        <div className="mt-4 flex items-center gap-3">
          {activeTown && (
            <motion.div 
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              className="flex-1 bg-accent/20 rounded-xl p-3 border border-accent/30"
            >
              <div className="flex items-center gap-2 text-accent text-xs font-medium mb-1">
                <MapPin className="w-3 h-3" />
                CURRENT LOCATION
              </div>
              <p className="font-display font-bold">{activeTown.name}</p>
              <p className="text-xs text-white/60">{activeTown.region}</p>
            </motion.div>
          )}
          
          {nextTown && (
            <>
              <div className="flex flex-col items-center text-white/40">
                <ChevronDown className="w-4 h-4 rotate-[-90deg]" />
                <span className="text-[10px]">Next</span>
              </div>
              <motion.div 
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                transition={{ delay: 0.1 }}
                className="flex-1 bg-white/5 rounded-xl p-3 border border-white/10"
              >
                <div className="flex items-center gap-2 text-white/60 text-xs font-medium mb-1">
                  <Navigation2 className="w-3 h-3" />
                  NEXT STOP
                </div>
                <p className="font-display font-bold">{nextTown.name}</p>
                <p className="text-xs text-white/60">{nextTown.distance && activeTown?.distance 
                  ? `${nextTown.distance - activeTown.distance} km ahead` 
                  : nextTown.region}</p>
              </motion.div>
            </>
          )}
        </div>
      </div>
    </motion.div>
  );
};

export default JourneyHeader;
