import { motion } from 'framer-motion';
import { 
  MapPin, 
  Check, 
  Clock, 
  ChevronRight,
  Building2
} from 'lucide-react';
import { Town } from '@/types/journey';
import { cn } from '@/lib/utils';

interface JourneyTimelineProps {
  towns: Town[];
  onTownClick: (town: Town) => void;
  isExpanded: boolean;
  onToggle: () => void;
}

const JourneyTimeline = ({ towns, onTownClick, isExpanded, onToggle }: JourneyTimelineProps) => {
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

  return (
    <motion.div
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      className="absolute left-4 bottom-24 z-[1000] w-72"
    >
      <div className="glass-card rounded-2xl overflow-hidden">
        {/* Header */}
        <button 
          onClick={onToggle}
          className="w-full p-4 flex items-center justify-between hover:bg-muted/50 transition-colors"
        >
          <div className="flex items-center gap-2">
            <Building2 className="w-5 h-5 text-primary" />
            <span className="font-display font-semibold text-foreground">Journey Timeline</span>
          </div>
          <motion.div
            animate={{ rotate: isExpanded ? 90 : 0 }}
            transition={{ duration: 0.2 }}
          >
            <ChevronRight className="w-5 h-5 text-muted-foreground" />
          </motion.div>
        </button>

        {/* Timeline */}
        <motion.div
          initial={false}
          animate={{ 
            height: isExpanded ? 'auto' : 0,
            opacity: isExpanded ? 1 : 0
          }}
          transition={{ duration: 0.3 }}
          className="overflow-hidden"
        >
          <div className="p-4 pt-0 max-h-[300px] overflow-y-auto space-y-1">
            {towns.map((town, index) => (
              <motion.button
                key={town.id}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
                onClick={() => onTownClick(town)}
                className={cn(
                  "w-full flex items-center gap-3 p-2 rounded-xl transition-all text-left",
                  "hover:bg-muted/70",
                  town.status === 'active' && "bg-accent/10"
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
                      town.status === 'active' && "text-accent"
                    )}>
                      {town.name}
                    </span>
                    {town.size === 'major' && (
                      <span className="text-[10px] px-1.5 py-0.5 bg-primary/10 text-primary rounded-full">
                        Major
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{town.region}</span>
                    <span>•</span>
                    <span>{town.distance} km</span>
                  </div>
                </div>

                {/* Services Count */}
                <div className="text-right">
                  <div className="text-xs text-muted-foreground">Services</div>
                  <div className="text-sm font-semibold text-foreground">
                    {town.services.restaurants + town.services.hotels + town.services.riders + town.services.taxis}
                  </div>
                </div>
              </motion.button>
            ))}
          </div>
        </motion.div>
      </div>
    </motion.div>
  );
};

export default JourneyTimeline;
