import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, MapPin, ArrowRight, Loader2, Navigation } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Town } from '@/types/journey';
import { searchTowns, getAllTowns, findRoutes, RouteDefinition } from '@/data/zambiaRoutes';
import { cn } from '@/lib/utils';

interface RouteSearchFormProps {
  onRouteSelect: (route: RouteDefinition) => void;
  isLoading?: boolean;
}

const RouteSearchForm = ({ onRouteSelect, isLoading }: RouteSearchFormProps) => {
  const [fromQuery, setFromQuery] = useState('');
  const [toQuery, setToQuery] = useState('');
  const [fromTown, setFromTown] = useState<Town | null>(null);
  const [toTown, setToTown] = useState<Town | null>(null);
  const [fromSuggestions, setFromSuggestions] = useState<Town[]>([]);
  const [toSuggestions, setToSuggestions] = useState<Town[]>([]);
  const [showFromDropdown, setShowFromDropdown] = useState(false);
  const [showToDropdown, setShowToDropdown] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const fromRef = useRef<HTMLDivElement>(null);
  const toRef = useRef<HTMLDivElement>(null);

  // Search suggestions
  useEffect(() => {
    if (fromQuery.length >= 2) {
      setFromSuggestions(searchTowns(fromQuery));
      setShowFromDropdown(true);
    } else {
      setFromSuggestions([]);
      setShowFromDropdown(false);
    }
  }, [fromQuery]);

  useEffect(() => {
    if (toQuery.length >= 2) {
      setToSuggestions(searchTowns(toQuery));
      setShowToDropdown(true);
    } else {
      setToSuggestions([]);
      setShowToDropdown(false);
    }
  }, [toQuery]);

  // Click outside handler
  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (fromRef.current && !fromRef.current.contains(e.target as Node)) {
        setShowFromDropdown(false);
      }
      if (toRef.current && !toRef.current.contains(e.target as Node)) {
        setShowToDropdown(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectFromTown = (town: Town) => {
    setFromTown(town);
    setFromQuery(town.name);
    setShowFromDropdown(false);
    setError(null);
  };

  const selectToTown = (town: Town) => {
    setToTown(town);
    setToQuery(town.name);
    setShowToDropdown(false);
    setError(null);
  };

  const handleSearch = () => {
    if (!fromTown || !toTown) {
      setError('Please select both departure and destination');
      return;
    }

    if (fromTown.id === toTown.id) {
      setError('Departure and destination cannot be the same');
      return;
    }

    const routes = findRoutes(fromTown.id, toTown.id);
    if (routes.length > 0) {
      onRouteSelect(routes[0]);
    } else {
      setError(`No direct route available from ${fromTown.name} to ${toTown.name}`);
    }
  };

  const swapLocations = () => {
    const tempTown = fromTown;
    const tempQuery = fromQuery;
    setFromTown(toTown);
    setFromQuery(toQuery);
    setToTown(tempTown);
    setToQuery(tempQuery);
    setError(null);
  };

  return (
    <div className="glass-card rounded-2xl p-4 space-y-4">
      <div className="flex items-center gap-2 mb-2">
        <Navigation className="w-5 h-5 text-primary" />
        <h2 className="font-display font-bold text-foreground">Plan Your Journey</h2>
      </div>

      <div className="flex items-center gap-2">
        {/* From Input */}
        <div ref={fromRef} className="flex-1 relative">
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-journey-completed" />
            <Input
              placeholder="From where?"
              value={fromQuery}
              onChange={(e) => {
                setFromQuery(e.target.value);
                setFromTown(null);
              }}
              onFocus={() => fromQuery.length >= 2 && setShowFromDropdown(true)}
              className="pl-9 bg-background/50 border-border/50"
            />
          </div>
          
          <AnimatePresence>
            {showFromDropdown && fromSuggestions.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="absolute top-full left-0 right-0 mt-1 z-50 bg-card rounded-xl border border-border shadow-xl overflow-hidden"
              >
                {fromSuggestions.map((town) => (
                  <button
                    key={town.id}
                    onClick={() => selectFromTown(town)}
                    className="w-full px-4 py-3 text-left hover:bg-muted/50 flex items-center gap-3 transition-colors"
                  >
                    <MapPin className="w-4 h-4 text-muted-foreground" />
                    <div>
                      <p className="font-medium text-foreground">{town.name}</p>
                      <p className="text-xs text-muted-foreground">{town.region}</p>
                    </div>
                  </button>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>

        {/* Swap Button */}
        <Button
          variant="ghost"
          size="icon"
          onClick={swapLocations}
          className="shrink-0 rounded-full hover:bg-accent/10"
        >
          <ArrowRight className="w-4 h-4 rotate-90 sm:rotate-0" />
        </Button>

        {/* To Input */}
        <div ref={toRef} className="flex-1 relative">
          <div className="relative">
            <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-accent" />
            <Input
              placeholder="To where?"
              value={toQuery}
              onChange={(e) => {
                setToQuery(e.target.value);
                setToTown(null);
              }}
              onFocus={() => toQuery.length >= 2 && setShowToDropdown(true)}
              className="pl-9 bg-background/50 border-border/50"
            />
          </div>
          
          <AnimatePresence>
            {showToDropdown && toSuggestions.length > 0 && (
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                className="absolute top-full left-0 right-0 mt-1 z-50 bg-card rounded-xl border border-border shadow-xl overflow-hidden"
              >
                {toSuggestions.map((town) => (
                  <button
                    key={town.id}
                    onClick={() => selectToTown(town)}
                    className="w-full px-4 py-3 text-left hover:bg-muted/50 flex items-center gap-3 transition-colors"
                  >
                    <MapPin className="w-4 h-4 text-muted-foreground" />
                    <div>
                      <p className="font-medium text-foreground">{town.name}</p>
                      <p className="text-xs text-muted-foreground">{town.region}</p>
                    </div>
                  </button>
                ))}
              </motion.div>
            )}
          </AnimatePresence>
        </div>
      </div>

      {/* Error Message */}
      <AnimatePresence>
        {error && (
          <motion.p
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="text-sm text-destructive"
          >
            {error}
          </motion.p>
        )}
      </AnimatePresence>

      {/* Search Button */}
      <Button 
        onClick={handleSearch}
        disabled={isLoading || !fromTown || !toTown}
        className="w-full bg-primary hover:bg-primary/90"
      >
        {isLoading ? (
          <>
            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
            Finding Route...
          </>
        ) : (
          <>
            <Search className="w-4 h-4 mr-2" />
            Find Route
          </>
        )}
      </Button>

      {/* Quick Routes */}
      <div className="pt-2 border-t border-border/50">
        <p className="text-xs text-muted-foreground mb-2">Popular routes:</p>
        <div className="flex flex-wrap gap-2">
          {[
            { from: 'Lusaka', to: 'Livingstone', fromId: 'lusaka', toId: 'livingstone' },
            { from: 'Lusaka', to: 'Ndola', fromId: 'lusaka', toId: 'ndola' },
            { from: 'Lusaka', to: 'Chipata', fromId: 'lusaka', toId: 'chipata' },
          ].map((quick) => (
            <button
              key={`${quick.fromId}-${quick.toId}`}
              onClick={() => {
                const fromT = getAllTowns().find(t => t.id === quick.fromId);
                const toT = getAllTowns().find(t => t.id === quick.toId);
                if (fromT && toT) {
                  selectFromTown(fromT);
                  selectToTown(toT);
                }
              }}
              className="text-xs px-3 py-1.5 rounded-full bg-muted hover:bg-muted/80 text-muted-foreground hover:text-foreground transition-colors"
            >
              {quick.from} → {quick.to}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};

export default RouteSearchForm;
