import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { Search, MapPin, ArrowRight, Loader2, Navigation, Bus, Map, LogIn, User, Shield, Store, MapPinCheck, Zap } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Town } from '@/types/journey';
import { searchTowns, getAllTowns, findRoutes, RouteDefinition } from '@/data/zambiaRoutes';
import { useAuthContext } from '@/contexts/useAuthContext';
import { demoAuthService } from '@/utils/demoAuthService';

interface LandingPageProps {
  onRouteSelect: (route: RouteDefinition) => void;
}

const LandingPage = ({ onRouteSelect }: LandingPageProps) => {
  const navigate = useNavigate();
  const { user, profile, signOut } = useAuthContext();
  const [fromQuery, setFromQuery] = useState('');
  const [toQuery, setToQuery] = useState('');
  const [fromTown, setFromTown] = useState<Town | null>(null);
  const [toTown, setToTown] = useState<Town | null>(null);
  const [fromSuggestions, setFromSuggestions] = useState<Town[]>([]);
  const [toSuggestions, setToSuggestions] = useState<Town[]>([]);
  const [showFromDropdown, setShowFromDropdown] = useState(false);
  const [showToDropdown, setShowToDropdown] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  
  const fromRef = useRef<HTMLDivElement>(null);
  const toRef = useRef<HTMLDivElement>(null);

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

    setIsLoading(true);
    setError(null);
    
    setTimeout(() => {
      const routes = findRoutes(fromTown.id, toTown.id);
      setIsLoading(false);
      
      if (routes.length > 0) {
        onRouteSelect(routes[0]);
      } else {
        // This should rarely happen now since we have pathfinding
        setError(`Unable to find a route from ${fromTown.name} to ${toTown.name}. These towns may not be connected.`);
      }
    }, 500);
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

  const quickRoutes = [
    { from: 'Lusaka', to: 'Livingstone', fromId: 'lusaka', toId: 'livingstone' },
    { from: 'Lusaka', to: 'Ndola', fromId: 'lusaka', toId: 'ndola' },
    { from: 'Lusaka', to: 'Chipata', fromId: 'lusaka', toId: 'chipata' },
    { from: 'Lusaka', to: 'Kasama', fromId: 'lusaka', toId: 'kasama' },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-primary/5 via-background to-background flex flex-col">
      {/* Header - Desktop Only */}
      <header className="hidden md:flex p-4 items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
            <Bus className="w-5 h-5 text-primary-foreground" />
          </div>
          <div>
            <h1 className="font-display font-bold text-lg text-foreground">BusNStay</h1>
            <p className="text-xs text-muted-foreground">Beyond City Limits</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {user ? (
            <>
              <Button variant="ghost" size="sm" onClick={() => navigate('/account')}>
                <User className="w-4 h-4 mr-1" />
                Account
              </Button>
              <Button variant="ghost" size="sm" onClick={() => navigate('/verification')}>
                <Shield className="w-4 h-4 mr-1" />
                Verification
              </Button>
              <Button variant="ghost" size="sm" onClick={() => navigate('/dashboard')}>
                {profile?.role === 'admin' ? 'Admin' : 'Dashboard'}
              </Button>
              <Button variant="outline" size="sm" onClick={async () => {
                try {
                  await signOut();
                  // Navigation will happen automatically via auth state change
                } catch (error) {
                  console.error('Sign out failed:', error);
                }
              }}>
                Sign Out
              </Button>
            </>
          ) : (
            <Button size="sm" onClick={() => navigate('/auth')}>
              <LogIn className="w-4 h-4 mr-1" />
              Sign In
            </Button>
          )}
        </div>
      </header>

      {/* Mobile Header - Show Logo Only */}
      <div className="md:hidden p-4 flex items-center justify-between border-b border-border/50">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
            <Bus className="w-5 h-5 text-primary-foreground" />
          </div>
          <div>
            <h1 className="font-display font-bold text-lg text-foreground">BusNStay</h1>
            <p className="text-xs text-muted-foreground">Beyond City Limits</p>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col justify-center px-4 pb-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-md mx-auto w-full space-y-6"
        >
          {/* Hero Text */}
          <div className="text-center space-y-2">
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ delay: 0.1 }}
              className="w-16 h-16 mx-auto rounded-2xl bg-primary/10 flex items-center justify-center mb-4"
            >
              <Map className="w-8 h-8 text-primary" />
            </motion.div>
            <h2 className="font-display text-2xl font-bold text-foreground">
              Where are you going?
            </h2>
            <p className="text-muted-foreground text-sm">
              Enter your route to start your journey
            </p>
          </div>

          {/* Route Search Form */}
          <div className="bg-card rounded-2xl p-4 shadow-lg border border-border/50 space-y-4">
            {/* From Input */}
            <div ref={fromRef} className="relative">
              <label className="text-xs font-medium text-muted-foreground mb-1.5 block">From</label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-journey-completed" />
                <Input
                  placeholder="Departure city or town"
                  value={fromQuery}
                  onChange={(e) => {
                    setFromQuery(e.target.value);
                    setFromTown(null);
                  }}
                  onFocus={() => fromQuery.length >= 2 && setShowFromDropdown(true)}
                  className="pl-11 h-12 text-base bg-muted/50 border-0"
                />
              </div>
              
              <AnimatePresence>
                {showFromDropdown && fromSuggestions.length > 0 && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="absolute top-full left-0 right-0 mt-1 z-50 bg-card rounded-xl border border-border shadow-xl overflow-hidden max-h-48 overflow-y-auto"
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
            <div className="flex justify-center -my-1">
              <Button
                variant="ghost"
                size="icon"
                onClick={swapLocations}
                className="rounded-full bg-muted hover:bg-muted/80 w-8 h-8"
              >
                <ArrowRight className="w-4 h-4 rotate-90" />
              </Button>
            </div>

            {/* To Input */}
            <div ref={toRef} className="relative">
              <label className="text-xs font-medium text-muted-foreground mb-1.5 block">To</label>
              <div className="relative">
                <MapPin className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-accent" />
                <Input
                  placeholder="Destination city or town"
                  value={toQuery}
                  onChange={(e) => {
                    setToQuery(e.target.value);
                    setToTown(null);
                  }}
                  onFocus={() => toQuery.length >= 2 && setShowToDropdown(true)}
                  className="pl-11 h-12 text-base bg-muted/50 border-0"
                />
              </div>
              
              <AnimatePresence>
                {showToDropdown && toSuggestions.length > 0 && (
                  <motion.div
                    initial={{ opacity: 0, y: -10 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    className="absolute top-full left-0 right-0 mt-1 z-50 bg-card rounded-xl border border-border shadow-xl overflow-hidden max-h-48 overflow-y-auto"
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

            {/* Error Message */}
            <AnimatePresence>
              {error && (
                <motion.p
                  initial={{ opacity: 0, height: 0 }}
                  animate={{ opacity: 1, height: 'auto' }}
                  exit={{ opacity: 0, height: 0 }}
                  className="text-sm text-destructive text-center"
                >
                  {error}
                </motion.p>
              )}
            </AnimatePresence>

            {/* Search Button */}
            <Button 
              onClick={handleSearch}
              disabled={isLoading || !fromTown || !toTown}
              className="w-full h-12 text-base bg-primary hover:bg-primary/90"
            >
              {isLoading ? (
                <>
                  <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                  Finding Route...
                </>
              ) : (
                <>
                  <Search className="w-5 h-5 mr-2" />
                  Find My Route
                </>
              )}
            </Button>
          </div>

          {/* Popular Routes */}
          <div className="space-y-3">
            <p className="text-sm text-muted-foreground text-center">Popular routes</p>
            <div className="flex flex-wrap justify-center gap-2">
              {quickRoutes.map((quick) => (
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
                  className="px-4 py-2 rounded-full bg-card border border-border/50 text-sm text-muted-foreground hover:text-foreground hover:border-primary/50 transition-colors"
                >
                  {quick.from} → {quick.to}
                </button>
              ))}
            </div>
          </div>

          {/* New Features Section */}
          <div className="mt-8 pt-8 border-t border-border/50 space-y-4">
            <p className="text-sm text-muted-foreground text-center font-medium">Enterprise Features</p>
            
            {!user && (
              <div className="p-3 rounded-lg bg-amber-500/10 border border-amber-200/30 text-center space-y-3">
                <p className="text-sm text-amber-900 font-medium">Try Demo to Access Features</p>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    size="sm"
                    className="bg-blue-600 hover:bg-blue-700 text-white"
                    onClick={() => {
                      demoAuthService.enableDemoMode('demo@restaurant', 'restaurant', 'Demo Restaurant');
                      navigate('/verification');
                    }}
                  >
                    🍽️ Restaurant
                  </Button>
                  <Button
                    size="sm"
                    className="bg-purple-600 hover:bg-purple-700 text-white"
                    onClick={() => {
                      demoAuthService.enableDemoMode('demo@rider', 'rider', 'Demo Rider');
                      navigate('/rider');
                    }}
                  >
                    🚴 Rider
                  </Button>
                  <Button
                    size="sm"
                    className="bg-green-600 hover:bg-green-700 text-white"
                    onClick={() => {
                      demoAuthService.enableDemoMode('demo@admin', 'admin', 'Demo Admin');
                      navigate('/admin');
                    }}
                  >
                    🔐 Admin
                  </Button>
                  <Button
                    size="sm"
                    className="bg-slate-600 hover:bg-slate-700 text-white"
                    onClick={() => {
                      demoAuthService.enableDemoMode('demo@passenger', 'passenger', 'Demo User');
                      navigate('/');
                    }}
                  >
                    🚗 Passenger
                  </Button>
                </div>
              </div>
            )}
            
            <div className="grid grid-cols-1 gap-3">
              <button
                onClick={() => user ? navigate('/verification') : null}
                className="group p-4 rounded-xl bg-gradient-to-br from-blue-500/10 to-blue-600/10 border border-blue-200/30 hover:border-blue-300/50 hover:from-blue-500/15 hover:to-blue-600/15 transition-all text-left"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-blue-500/20 group-hover:bg-blue-500/30 transition-colors">
                    <Shield className="w-5 h-5 text-blue-600" />
                  </div>
                  <div>
                    <p className="font-medium text-foreground">Service Provider Verification</p>
                    <p className="text-xs text-muted-foreground">Register as supplier/restaurant</p>
                  </div>
                </div>
              </button>

              <button
                onClick={() => user ? navigate('/admin') : null}
                className="group p-4 rounded-xl bg-gradient-to-br from-green-500/10 to-green-600/10 border border-green-200/30 hover:border-green-300/50 hover:from-green-500/15 hover:to-green-600/15 transition-all text-left"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-green-500/20 group-hover:bg-green-500/30 transition-colors">
                    <Zap className="w-5 h-5 text-green-600" />
                  </div>
                  <div>
                    <p className="font-medium text-foreground">Delivery Management</p>
                    <p className="text-xs text-muted-foreground">Track orders & dynamic pricing</p>
                  </div>
                </div>
              </button>

              <button
                onClick={() => user ? navigate('/rider') : null}
                className="group p-4 rounded-xl bg-gradient-to-br from-purple-500/10 to-purple-600/10 border border-purple-200/30 hover:border-purple-300/50 hover:from-purple-500/15 hover:to-purple-600/15 transition-all text-left"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 rounded-lg bg-purple-500/20 group-hover:bg-purple-500/30 transition-colors">
                    <MapPinCheck className="w-5 h-5 text-purple-600" />
                  </div>
                  <div>
                    <p className="font-medium text-foreground">Real-Time GPS Tracking</p>
                    <p className="text-xs text-muted-foreground">Live delivery location tracking</p>
                  </div>
                </div>
              </button>
            </div>
          </div>
        </motion.div>
      </div>
    </div>
  );
};

export default LandingPage;
