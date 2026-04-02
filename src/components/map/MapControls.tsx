import { motion } from 'framer-motion';
import { useMap } from 'react-leaflet';
import { 
  Plus, 
  Minus, 
  Locate, 
  Map as MapIcon,
  Navigation,
  Flag
} from 'lucide-react';
import { Town } from '@/types/journey';

interface MapControlsProps {
  currentPosition: [number, number];
  activeTown: Town | null;
  destinationTown: Town;
  onFocusCurrent: () => void;
  onFocusNext: () => void;
  onFocusDestination: () => void;
}

const MapControls = ({ 
  currentPosition,
  activeTown,
  destinationTown,
  onFocusCurrent,
  onFocusNext,
  onFocusDestination
}: MapControlsProps) => {
  const map = useMap();

  const handleZoomIn = () => {
    map.zoomIn();
  };

  const handleZoomOut = () => {
    map.zoomOut();
  };

  const handleLocate = () => {
    map.flyTo(currentPosition, 14, { duration: 1 });
  };

  const handleFitRoute = () => {
    // This will be called from parent with route bounds
    onFocusCurrent();
  };

  return (
    <div className="absolute right-4 top-1/2 -translate-y-1/2 z-[1000] flex flex-col gap-2">
      {/* Zoom Controls */}
      <motion.div 
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: 0.2 }}
        className="glass-card rounded-xl overflow-hidden"
      >
        <button
          onClick={handleZoomIn}
          className="w-11 h-11 flex items-center justify-center hover:bg-primary/10 transition-colors border-b border-border"
        >
          <Plus className="w-5 h-5 text-foreground" />
        </button>
        <button
          onClick={handleZoomOut}
          className="w-11 h-11 flex items-center justify-center hover:bg-primary/10 transition-colors"
        >
          <Minus className="w-5 h-5 text-foreground" />
        </button>
      </motion.div>

      {/* Quick Navigation */}
      <motion.div 
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: 0.3 }}
        className="glass-card rounded-xl overflow-hidden"
      >
        <button
          onClick={handleLocate}
          className="w-11 h-11 flex items-center justify-center hover:bg-accent/20 transition-colors group border-b border-border"
          title="Current Location"
        >
          <Locate className="w-5 h-5 text-accent group-hover:text-accent" />
        </button>
        <button
          onClick={onFocusNext}
          className="w-11 h-11 flex items-center justify-center hover:bg-primary/10 transition-colors border-b border-border"
          title="Next Stop"
        >
          <Navigation className="w-5 h-5 text-foreground" />
        </button>
        <button
          onClick={onFocusDestination}
          className="w-11 h-11 flex items-center justify-center hover:bg-journey-completed/20 transition-colors"
          title="Final Destination"
        >
          <Flag className="w-5 h-5 text-journey-completed" />
        </button>
      </motion.div>

      {/* Fit Route */}
      <motion.button
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ delay: 0.4 }}
        onClick={handleFitRoute}
        className="glass-card w-11 h-11 rounded-xl flex items-center justify-center hover:bg-primary/10 transition-colors"
        title="View Full Route"
      >
        <MapIcon className="w-5 h-5 text-foreground" />
      </motion.button>
    </div>
  );
};

export default MapControls;
