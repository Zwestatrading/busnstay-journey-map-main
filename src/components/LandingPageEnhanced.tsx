import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Search, MapPin, ArrowRight, Loader2,
  Star, Zap, Clock, Utensils, TrendingUp, Menu, X, LogOut, User, BarChart3, Shield,
  Users, Truck, ChevronDown
} from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Town } from '@/types/journey';
import { searchTowns, findRoutes, RouteDefinition } from '@/data/zambiaRoutes';
import { useAuthContext } from '@/contexts/useAuthContext';
import { demoAuthService } from '@/utils/demoAuthService';
import { supabase } from '@/lib/supabase';

interface LandingPageEnhancedProps {
  onRouteSelect: (route: RouteDefinition) => void;
}

interface DemoProfile {
  id?: string;
  email?: string;
  name?: string;
  [key: string]: unknown;
}

const LandingPageEnhanced = ({ onRouteSelect }: LandingPageEnhancedProps) => {
  const navigate = useNavigate();
  const { user } = useAuthContext();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isDemoMode, setIsDemoMode] = useState(demoAuthService.isDemoMode());
  const [demoProfile, setDemoProfile] = useState<DemoProfile | null>(null);
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
  const [hoveredRoute, setHoveredRoute] = useState<number | null>(null);
  
  const fromRef = useRef<HTMLDivElement>(null);
  const toRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const unsubscribe = demoAuthService.onDemoModeChange((isDemo: boolean) => {
      setIsDemoMode(isDemo);
      if (isDemo) {
        const stored = localStorage.getItem('busnstay_demo_profile');
        setDemoProfile(stored ? JSON.parse(stored) : null);
      }
    });
    return unsubscribe;
  }, []);

  useEffect(() => {
    if (isDemoMode) {
      const stored = localStorage.getItem('busnstay_demo_profile');
      setDemoProfile(stored ? JSON.parse(stored) : null);
    }
  }, [isDemoMode]);

  const isLoggedIn = user || isDemoMode;

  useEffect(() => {
    if (fromQuery.length >= 2) {
      setFromSuggestions(searchTowns(fromQuery));
      setShowFromDropdown(true);
    } else {
      setFromSuggestions([]);
    }
  }, [fromQuery]);

  useEffect(() => {
    if (toQuery.length >= 2) {
      setToSuggestions(searchTowns(toQuery));
      setShowToDropdown(true);
    } else {
      setToSuggestions([]);
    }
  }, [toQuery]);

  const selectFromTown = (town: Town) => {
    setFromTown(town);
    setFromQuery(town.name);
    setShowFromDropdown(false);
  };

  const selectToTown = (town: Town) => {
    setToTown(town);
    setToQuery(town.name);
    setShowToDropdown(false);
  };

  const handleSearch = () => {
    if (!fromTown || !toTown) {
      setError('Please select both cities');
      return;
    }

    if (fromTown.id === toTown.id) {
      setError('Please select different cities');
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
        setError('Route not available');
      }
    }, 500);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 via-white to-slate-50">
      {/* Persistent Sticky Navbar */}
      <header className="sticky top-0 z-[9999] backdrop-blur-md bg-gradient-to-r from-slate-900 to-slate-800 border-b-2 border-blue-500 shadow-2xl">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          {/* Logo */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            className="flex items-center gap-2 cursor-pointer hover:opacity-80 transition-opacity"
            onClick={() => navigate('/')}
          >
            <div className="w-9 h-9 rounded-lg bg-gradient-to-br from-blue-500 to-cyan-500 flex items-center justify-center shadow-lg">
              <Utensils className="w-5 h-5 text-white" />
            </div>
            <div>
              <h1 className="font-bold text-sm md:text-base text-white">BusNStay</h1>
              <p className="text-xs text-blue-200 leading-none">Journey Companion</p>
            </div>
          </motion.div>

          {/* Middle Menu Items */}
          <nav className="hidden md:flex items-center gap-1 flex-1 justify-center">
            {isLoggedIn ? (
              <>
                <button
                  type="button"
                  onClick={() => navigate('/account')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  <User className="w-4 h-4" />
                  Account
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/dashboard')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  <BarChart3 className="w-4 h-4" />
                  Dashboard
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/restaurant')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  <Users className="w-4 h-4" />
                  Service Providers
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/rider')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  <Truck className="w-4 h-4" />
                  Riders
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/verification')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-green-600 bg-green-700 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                  title="Get verified as a service provider"
                >
                  <Shield className="w-4 h-4" />
                  Get Verified
                </button>
              </>
            ) : (
              <>
                <button
                  type="button"
                  onClick={() => navigate('/dashboard')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  🛒 Passenger
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/restaurant')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  🍽️ Restaurant
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/rider')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  🚴 Rider
                </button>
                <button
                  type="button"
                  onClick={() => navigate('/hotel')}
                  className="px-3 py-2 rounded-lg text-white hover:bg-blue-600 transition-all flex items-center gap-2 text-sm font-medium group cursor-pointer"
                >
                  🏨 Hotel
                </button>
              </>
            )}
          </nav>

          {/* Right Actions */}
          <div className="flex items-center gap-2">
            {isLoggedIn ? (
              <motion.button
                onClick={async () => {
                  if (isDemoMode) {
                    demoAuthService.disableDemoMode();
                  } else {
                    await supabase.auth.signOut();
                  }
                  navigate('/');
                }}
                className="px-3 md:px-4 py-2 rounded-lg bg-red-600 hover:bg-red-700 text-white text-sm font-medium transition-all flex items-center gap-2 shadow-lg"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                <LogOut className="w-4 h-4" />
                <span className="hidden sm:inline">Sign Out</span>
              </motion.button>
            ) : (
              <>
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-white hover:bg-blue-600 hidden sm:inline-flex"
                  onClick={() => navigate('/auth')}
                >
                  Sign In
                </Button>
                <Button
                  size="sm"
                  className="bg-blue-600 hover:bg-blue-700 text-white shadow-lg"
                  onClick={() => navigate('/auth')}
                >
                  Get Started
                </Button>
              </>
            )}

            {/* Mobile Menu Button - Only show on small screens when logged in */}
            {isLoggedIn && (
              <motion.button
                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                className="md:hidden p-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
              </motion.button>
            )}
          </div>
        </div>

        {/* Mobile Menu Dropdown */}
        <AnimatePresence>
          {mobileMenuOpen && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              className="md:hidden bg-slate-800 border-t border-blue-500 overflow-hidden"
            >
              <div className="px-4 py-3 space-y-2">
                {isLoggedIn ? (
                  <>
                    <button
                      onClick={() => {
                        navigate('/account');
                        setMobileMenuOpen(false);
                      }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium"
                    >
                      <User className="w-4 h-4" /> Account
                    </button>
                    <button
                      onClick={() => {
                        navigate('/dashboard');
                        setMobileMenuOpen(false);
                      }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium"
                    >
                      <BarChart3 className="w-4 h-4" /> Dashboard
                    </button>
                    <button
                      onClick={() => { navigate('/restaurant'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      <Users className="w-4 h-4" /> Service Providers
                    </button>
                    <button
                      onClick={() => { navigate('/rider'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      <Truck className="w-4 h-4" /> Riders
                    </button>
                    <button
                      onClick={() => { navigate('/verification'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-green-700 hover:bg-green-800 rounded transition-all text-sm font-medium cursor-pointer"
                      title="Get verified as a service provider"
                    >
                      <Shield className="w-4 h-4" /> Get Verified
                    </button>
                  </>
                ) : (
                  <>
                    <button
                      onClick={() => { navigate('/dashboard'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      🛒 Passenger - Order Food
                    </button>
                    <button
                      onClick={() => { navigate('/restaurant'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      🍽️ Restaurant - Partner
                    </button>
                    <button
                      onClick={() => { navigate('/rider'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      🚴 Rider - Deliver
                    </button>
                    <button
                      onClick={() => { navigate('/hotel'); setMobileMenuOpen(false); }}
                      className="w-full flex items-center gap-3 px-4 py-2 text-white bg-blue-600 hover:bg-blue-700 rounded transition-all text-sm font-medium cursor-pointer"
                    >
                      🏨 Hotel - List Rooms
                    </button>
                  </>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </header>

      {/* Hero Section */}
      <section className="relative px-3 sm:px-4 py-8 md:py-20 lg:py-40 pt-12 md:pt-24 max-w-7xl mx-auto w-full overflow-hidden">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 md:gap-16 items-center">
          {/* Left: Content */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
          >
            <div className="space-y-6">
              <div>
                <motion.span
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  transition={{ delay: 0.2 }}
                  className="inline-block px-4 py-2 rounded-full bg-amber-50 text-amber-800 text-xs font-semibold tracking-wide mb-4 border border-amber-200"
                >
                  ✨ CULINARY EXCELLENCE ON EVERY ROUTE
                </motion.span>
                <h1 className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-black leading-tight text-slate-900 break-words w-full">
                  Extraordinary{' '}
                  <span className="relative">
                    <span className="relative z-10 bg-gradient-to-r from-teal-600 to-cyan-600 bg-clip-text text-transparent">
                      Food
                    </span>
                    <motion.div
                      className="absolute inset-0 top-4 bg-amber-400/20 rounded-lg -z-10"
                      animate={{ scale: [1, 1.02, 1], rotate: [0, 1, 0] }}
                      transition={{ duration: 3, repeat: Infinity }}
                    />
                  </span>
                  {' '}Every Journey
                </h1>
              </div>

              <p className="text-lg md:text-xl text-slate-600 leading-relaxed max-w-xl">
                Discover verified restaurants at bus stations across Zambia. Fresh meals, transparent K20+ pricing, and instant delivery tracking on every route.
              </p>

              <div className="flex flex-col sm:flex-row gap-4 pt-4">
                <Button size="lg" style={{ backgroundColor: 'hsl(var(--primary))', color: 'hsl(var(--primary-foreground))' }} className="shadow-lg hover:opacity-90 cursor-pointer" onClick={() => navigate('/dashboard')}>
                  <Utensils className="w-5 h-5 mr-2" />
                  Order Now
                </Button>
                <Button size="lg" variant="outline" style={{ borderColor: 'hsl(var(--primary))', color: 'hsl(var(--primary))' }} className="border-2 hover:bg-primary/5 cursor-pointer" onClick={() => navigate('/restaurant')}>
                  For Restaurants
                </Button>
              </div>

              {/* Stats Grid */}
              <motion.div className="grid grid-cols-3 gap-6 pt-12 border-t border-slate-200">
                {[
                  { value: '65+', label: 'Towns', color: 'text-teal-600' },
                  { value: '890+', label: 'Restaurants', color: 'text-amber-600' },
                  { value: '50K+', label: 'Meals Delivered', color: 'text-slate-900' },
                ].map((stat, idx) => (
                  <motion.div
                    key={idx}
                    initial={{ opacity: 0, scale: 0.8 }}
                    animate={{ opacity: 1, scale: 1 }}
                    transition={{ delay: 0.3 + idx * 0.1 }}
                  >
                    <p className={`text-3xl font-black ${stat.color}`}>{stat.value}</p>
                    <p className="text-sm text-slate-500 font-medium mt-1">{stat.label}</p>
                  </motion.div>
                ))}
              </motion.div>
            </div>
          </motion.div>

          {/* Right: Visual Card */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.25 }}
            className="relative lg:block hidden"
          >
            <div className="relative">
              <motion.div
                className="absolute inset-0 bg-gradient-to-r from-teal-500/20 to-amber-400/20 rounded-3xl blur-3xl"
                animate={{ scale: [1, 1.05, 1] }}
                transition={{ duration: 4, repeat: Infinity }}
              />
              <Card className="relative border-2 border-slate-200 shadow-2xl overflow-hidden bg-white">
                <CardContent className="p-8 space-y-6">
                  <motion.div
                    style={{ backgroundColor: 'hsl(var(--secondary) / 0.1)', borderColor: 'hsl(var(--secondary))' }}
                    className="flex items-center gap-4 p-4 rounded-xl border"
                    whileHover={{ scale: 1.02 }}
                  >
                    <Utensils style={{ color: 'hsl(var(--secondary))' }} className="w-8 h-8 flex-shrink-0" />
                    <div>
                      <p className="font-bold text-slate-900">Sofia's Premium Grill</p>
                      <p className="text-xs text-slate-500">⭐ 4.9/5 • Ready in 15 mins</p>
                    </div>
                  </motion.div>
                  <div style={{ background: 'linear-gradient(135deg, hsl(var(--accent) / 0.8), hsl(var(--accent) / 0.5))' }} className="h-40 rounded-2xl flex items-center justify-center shadow-inner">
                    <motion.span
                      className="text-7xl"
                      animate={{ scale: [1, 1.1, 1], rotate: [0, 2, 0] }}
                      transition={{ duration: 3, repeat: Infinity }}
                    >
                      🍖
                    </motion.span>
                  </div>
                  <div className="space-y-3">
                    <p className="text-sm font-semibold text-slate-900">Grilled Chicken with Rice</p>
                    <div className="flex justify-between items-center bg-slate-50 p-3 rounded-lg">
                      <span className="text-xs text-slate-600">Subtotal</span>
                      <span className="font-bold text-slate-900">K79</span>
                    </div>
                    <div className="flex justify-between items-center bg-teal-50 p-3 rounded-lg border border-teal-200">
                      <span className="text-xs font-semibold text-teal-700">Delivery + K20 Base</span>
                      <span className="font-bold text-teal-700">K28</span>
                    </div>
                    <div className="flex justify-between items-center bg-slate-900 text-white p-4 rounded-lg font-bold text-lg rounded-xl">
                      <span>Total</span>
                      <span className="text-amber-400">K107</span>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Search Section */}
      <section className="px-4 py-20 bg-gradient-to-b from-slate-900 to-slate-950 text-white" data-route-search="true">
        <div className="max-w-4xl mx-auto">
          <motion.div 
            className="text-center mb-12"
            initial={{ opacity: 0, y: -20 }}
            whileInView={{ opacity: 1, y: 0 }}
          >
            <h2 className="text-4xl md:text-5xl font-black mb-4">
              Plan Your <span className="bg-gradient-to-r from-amber-400 to-amber-300 bg-clip-text text-transparent">Food Journey</span>
            </h2>
            <p className="text-slate-300">Find delicious meals waiting at every stop</p>
          </motion.div>

          <Card className="border-0 shadow-2xl bg-white">
            <CardContent className="p-8">
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* From */}
                  <div ref={fromRef} className="relative">
                    <label className="text-sm font-bold text-slate-900">Depart From</label>
                    <div className="relative mt-3">
                      <MapPin className="absolute left-4 top-4 w-5 h-5 text-slate-400" />
                      <Input
                        placeholder="Select departure city"
                        value={fromQuery}
                        onChange={(e) => setFromQuery(e.target.value)}
                        onFocus={() => fromQuery.length >= 2 && setShowFromDropdown(true)}
                        className="pl-12 h-12 border-2 border-slate-200 focus:border-teal-600"
                      />
                      <AnimatePresence>
                        {showFromDropdown && fromSuggestions.length > 0 && (
                          <motion.div
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="absolute top-full mt-3 w-full bg-white border-2 border-slate-200 rounded-lg shadow-xl z-50"
                          >
                            {fromSuggestions.map((town) => (
                              <button
                                key={town.id}
                                onClick={() => selectFromTown(town)}
                                className="w-full text-left px-4 py-3 hover:bg-teal-50 transition text-slate-900 border-b border-slate-100 last:border-0"
                              >
                                <p className="font-medium">{town.name}</p>
                                <p className="text-xs text-slate-500">{town.region}</p>
                              </button>
                            ))}
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  </div>

                  {/* To */}
                  <div ref={toRef} className="relative">
                    <label className="text-sm font-bold text-slate-900">Arrive at</label>
                    <div className="relative mt-3">
                      <MapPin className="absolute left-4 top-4 w-5 h-5 text-slate-400" />
                      <Input
                        placeholder="Select destination city"
                        value={toQuery}
                        onChange={(e) => setToQuery(e.target.value)}
                        onFocus={() => toQuery.length >= 2 && setShowToDropdown(true)}
                        className="pl-12 h-12 border-2 border-slate-200 focus:border-teal-600"
                      />
                      <AnimatePresence>
                        {showToDropdown && toSuggestions.length > 0 && (
                          <motion.div
                            initial={{ opacity: 0, y: -10 }}
                            animate={{ opacity: 1, y: 0 }}
                            exit={{ opacity: 0, y: -10 }}
                            className="absolute top-full mt-3 w-full bg-white border-2 border-slate-200 rounded-lg shadow-xl z-50"
                          >
                            {toSuggestions.map((town) => (
                              <button
                                key={town.id}
                                onClick={() => selectToTown(town)}
                                className="w-full text-left px-4 py-3 hover:bg-teal-50 transition text-slate-900 border-b border-slate-100 last:border-0"
                              >
                                <p className="font-medium">{town.name}</p>
                                <p className="text-xs text-slate-500">{town.region}</p>
                              </button>
                            ))}
                          </motion.div>
                        )}
                      </AnimatePresence>
                    </div>
                  </div>

                  {/* Search Button */}
                  <div className="flex items-end">
                    <Button
                      onClick={handleSearch}
                      disabled={isLoading || !fromTown || !toTown}
                      className="w-full h-12 bg-gradient-to-r from-slate-900 to-slate-950 hover:from-slate-950 hover:to-black text-white font-bold rounded-lg"
                    >
                      {isLoading ? (
                        <>
                          <Loader2 className="w-5 h-5 mr-2 animate-spin" />
                          Searching
                        </>
                      ) : (
                        <>
                          <Search className="w-5 h-5 mr-2" />
                          Search Routes
                        </>
                      )}
                    </Button>
                  </div>
                </div>

                {error && (
                  <motion.div
                    initial={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    className="p-4 bg-red-50 border border-red-300 rounded-lg"
                  >
                    <p className="text-sm text-red-700 font-medium">⚠️ {error}</p>
                  </motion.div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      {/* Features Section */}
      <section className="px-4 py-24 max-w-7xl mx-auto">
        <motion.div
          initial={{ opacity: 0 }}
          whileInView={{ opacity: 1 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-black text-slate-900 mb-4">Why BusNStay?</h2>
          <p className="text-xl text-slate-600 max-w-2xl mx-auto">The smarter way to eat while traveling</p>
        </motion.div>
        
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            {
              icon: Utensils,
              title: 'Verified Restaurants',
              description: 'Hand-picked restaurants at every station',
              bgColor: 'hsl(var(--secondary) / 0.1)',
              borderColor: 'hsl(var(--secondary) / 0.3)',
              dotColor: 'hsl(var(--secondary))'
            },
            {
              icon: Zap,
              title: 'Transparent Pricing',
              description: 'K20 base + distance. Always fair.',
              bgColor: 'hsl(var(--accent) / 0.1)',
              borderColor: 'hsl(var(--accent) / 0.3)',
              dotColor: 'hsl(var(--accent))'
            },
            {
              icon: Clock,
              title: 'Real-Time Tracking',
              description: 'Know exactly when your food arrives',
              bgColor: 'hsl(var(--secondary) / 0.2)',
              borderColor: 'hsl(var(--secondary) / 0.4)',
              dotColor: 'hsl(var(--secondary))'
            },
            {
              icon: TrendingUp,
              title: 'Restaurant Growth',
              description: 'Earn 95% with boosted visibility',
              bgColor: 'hsl(var(--primary) / 0.1)',
              borderColor: 'hsl(var(--primary) / 0.3)',
              dotColor: 'hsl(var(--primary))'
            },
          ].map((feature, idx) => (
            <motion.div
              key={idx}
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.1 }}
            >
              <Card style={{ backgroundColor: feature.bgColor, borderColor: feature.borderColor }} className="h-full border-2 shadow-lg hover:shadow-xl transition">
                <CardContent className="p-6 space-y-4">
                  <div style={{ backgroundColor: feature.dotColor }} className="w-12 h-12 rounded-lg flex items-center justify-center">
                    <feature.icon className="w-6 h-6 text-white" />
                  </div>
                  <div>
                    <h3 className="font-black text-slate-900 mb-2">{feature.title}</h3>
                    <p className="text-sm text-slate-600 leading-relaxed">{feature.description}</p>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </section>

      {/* Popular Routes Section */}
      <section className="px-4 py-24 bg-white border-t-4 border-slate-200">
        <div className="max-w-7xl mx-auto">
          <motion.div
            initial={{ opacity: 0 }}
            whileInView={{ opacity: 1 }}
            className="text-center mb-16"
          >
            <h2 className="text-4xl md:text-5xl font-black text-slate-900 mb-4">Popular Routes Across Zambia</h2>
            <p className="text-xl text-slate-600">Browse thousands of delicious restaurants</p>
          </motion.div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              { from: 'Lusaka', to: 'Livingstone', km: 475, restaurants: 350, badge: 'Most Popular' },
              { from: 'Lusaka', to: 'Ndola', km: 325, restaurants: 280, badge: 'Fastest Route' },
              { from: 'Ndola', to: 'Kitwe', km: 65, restaurants: 150, badge: 'Town Route' },
              { from: 'Livingstone', to: 'Kazungula', km: 50, restaurants: 120, badge: 'Border Route' },
              { from: 'Lusaka', to: 'Chipata', km: 570, restaurants: 220, badge: 'Long Distance' },
              { from: 'Mongu', to: 'Lusaka', km: 610, restaurants: 190, badge: 'Western Route' },
            ].map((route, idx) => (
              <motion.button
                key={idx}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.05 }}
                onHoverStart={() => setHoveredRoute(idx)}
                onHoverEnd={() => setHoveredRoute(null)}
                onClick={async () => {
                  const from = searchTowns(route.from)[0];
                  const to = searchTowns(route.to)[0];
                  if (from && to) {
                    setFromTown(from);
                    setToTown(to);
                    setFromQuery(from.name);
                    setToQuery(to.name);
                    
                    // Scroll to route search section
                    setTimeout(() => {
                      document.querySelector('[data-route-search]')?.scrollIntoView({ behavior: 'smooth' });
                      // Trigger search
                      const routes = findRoutes(from.id, to.id);
                      if (routes.length > 0) {
                        onRouteSelect(routes[0]);
                      }
                    }, 100);
                  }
                }}
                className="group cursor-pointer"
              >
                <Card className={`h-full border-2 border-slate-200 transition-all overflow-hidden ${hoveredRoute === idx ? 'border-teal-400 shadow-xl' : 'shadow-lg'}`}>
                  <CardContent className="p-6">
                    <div className="space-y-4">
                      <div className="flex justify-between items-start">
                        <div className="text-left">
                          <p className="text-xs font-bold text-slate-500 tracking-wide">ROUTE</p>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="font-black text-slate-900">{route.from}</span>
                            <ArrowRight className="w-4 h-4 text-slate-400 group-hover:text-teal-600 transition" />
                            <span className="font-black text-slate-900">{route.to}</span>
                          </div>
                        </div>
                        <span className="inline-block px-3 py-1 text-xs font-bold bg-amber-100 text-amber-800 rounded-full">
                          {route.badge}
                        </span>
                      </div>
                      <div className="border-t border-slate-200 pt-4 grid grid-cols-2 gap-4">
                        <div>
                          <p className="text-xs text-slate-500 font-semibold">Distance</p>
                          <p className="text-lg font-black text-slate-900">{route.km} km</p>
                        </div>
                        <div className="text-right">
                          <p className="text-xs text-slate-500 font-semibold">Restaurants</p>
                          <p className="text-lg font-black text-teal-600">{route.restaurants}+</p>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.button>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="px-4 py-24 bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 text-white">
        <div className="max-w-4xl mx-auto text-center">
          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            whileInView={{ opacity: 1, scale: 1 }}
            className="space-y-8"
          >
            <div className="space-y-4">
              <h2 className="text-5xl md:text-6xl font-black leading-tight">
                Ready to Travel
                <br />
                <span className="bg-gradient-to-r from-amber-400 to-amber-300 bg-clip-text text-transparent">Deliciously?</span>
              </h2>
              <p className="text-xl text-slate-300 max-w-2xl mx-auto leading-relaxed">
                Join thousands of travelers enjoying premium meals from verified restaurants at every stop across Zambia
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Button size="lg" className="bg-white text-slate-900 hover:bg-slate-100 font-bold shadow-lg cursor-pointer" onClick={() => navigate('/dashboard')}>
                <Utensils className="w-5 h-5 mr-2" />
                Order Now
              </Button>
              <Button size="lg" className="bg-teal-600 hover:bg-teal-700 text-white font-bold shadow-lg border-2 border-teal-400 cursor-pointer" onClick={() => navigate('/restaurant')}>
                Become a Restaurant Partner
              </Button>
            </div>

            <p className="text-sm text-slate-400">✅ 65+ towns • 890+ restaurants • No hidden fees</p>
          </motion.div>
        </div>
      </section>

      {/* Footer */}
      <footer className="px-4 py-12 bg-slate-100 border-t border-slate-200">
        <div className="max-w-7xl mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-8">
            <div>
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 rounded-lg bg-slate-900 flex items-center justify-center">
                  <Utensils className="w-4 h-4 text-white" />
                </div>
                <span className="font-black text-slate-900">BusNStay</span>
              </div>
              <p className="text-sm text-slate-600">Premium food delivery on Zambian routes</p>
            </div>
            <div>
              <p className="font-bold text-slate-900 mb-3 text-sm">Product</p>
              <ul className="space-y-2 text-sm text-slate-600">
                <li><a href="#" className="hover:text-slate-900">For Customers</a></li>
                <li><a href="#" className="hover:text-slate-900">For Restaurants</a></li>
              </ul>
            </div>
            <div>
              <p className="font-bold text-slate-900 mb-3 text-sm">Company</p>
              <ul className="space-y-2 text-sm text-slate-600">
                <li><a href="#" className="hover:text-slate-900">About</a></li>
                <li><a href="#" className="hover:text-slate-900">Contact</a></li>
              </ul>
            </div>
            <div>
              <p className="font-bold text-slate-900 mb-3 text-sm">Legal</p>
              <ul className="space-y-2 text-sm text-slate-600">
                <li><a href="#" className="hover:text-slate-900">Privacy</a></li>
                <li><a href="#" className="hover:text-slate-900">Terms</a></li>
              </ul>
            </div>
          </div>

          <div className="border-t border-slate-300 pt-8 text-center text-sm text-slate-600">
            <p>© 2026 BusNStay. All rights reserved. Nourish every journey across Zambia.</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default LandingPageEnhanced;
