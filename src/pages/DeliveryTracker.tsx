import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { AlertCircle, Loader2, ArrowLeft, WifiOff, Wifi } from 'lucide-react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { supabase } from '@/lib/supabase';
import JourneyMap from '@/components/JourneyMap';
import JourneyTimeline from '@/components/JourneyTimeline';
import {
  useRiderLocation,
  useActiveDeliveryJobs,
  useStationWithRestaurants,
  useCalculateRoute,
  DeliveryJob,
} from '@/hooks/useDeliveryTracking';
// Phase 1 Integration: Offline + Background Tracking
import { useJourneyState } from '@/hooks/useJourneyState';
import { useBackgroundTracking } from '@/hooks/useBackgroundTracking';
import { useOrderSync } from '@/hooks/useOrderSync';

interface Location {
  lat: number;
  lng: number;
}

interface Station {
  id: string;
  name: string;
  location: Location;
  hasRestaurants: boolean;
  restaurantCount?: number;
  eta?: string;
  distance?: number;
  isCompleted?: boolean;
  isCurrent?: boolean;
}

interface DeliveryRoute {
  currentLocation: Location;
  destination: Location;
  currentStation?: Station;
  upcomingStations: Station[];
  estimatedArrival: string;
  totalDistance: number;
  totalTime: string;
}

const DeliveryTracker: React.FC = () => {
  const navigate = useNavigate();
  const { jobId } = useParams<{ jobId: string }>();
  const { user, profile } = useAuthContext();

  const [currentJob, setCurrentJob] = useState<DeliveryJob | null>(null);
  const [route, setRoute] = useState<DeliveryRoute | null>(null);
  const [selectedStation, setSelectedStation] = useState<Station | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [upcomingStops, setUpcomingStops] = useState<Station[]>([]);
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  // Phase 1: Journey state with offline support and auto-restore
  const {
    journey,
    isLoading: journeyLoading,
    error: journeyError,
    startJourney,
    endJourney,
    updateLocation,
    autoRestore,
    syncQueuedData,
    queueStats,
  } = useJourneyState(user?.id || null);

  // Phase 1: Background GPS tracking (continues even when app minimized)
  const {
    isTracking: backgroundTracking,
    lastLocation: bgLocation,
    error: bgError,
    startTracking: startBgTracking,
    stopTracking: stopBgTracking,
  } = useBackgroundTracking(user?.id || null);

  // Phase 1: Order sync with offline support
  const {
    orders,
    isLoading: ordersLoading,
    error: ordersError,
    createOrder,
    loadJourneyOrders,
    syncPendingOrders,
    pendingOrdersCount,
  } = useOrderSync(user?.id || null);

  // Real-time location tracking (existing)
  const {
    location: riderLocation,
    isTracking,
    startTracking,
    error: gpsError,
  } = useRiderLocation(user?.id || null, true);

  // Fetch active jobs (existing)
  const { jobs, loading: jobsLoading } = useActiveDeliveryJobs(profile?.id || null);

  // Phase 1: Monitor online/offline status and sync on reconnect
  useEffect(() => {
    const handleOnline = () => {
      setIsOnline(true);
      // Auto-sync queued data when coming back online
      if (journey?.id) {
        syncQueuedData();
      }
      if (pendingOrdersCount > 0) {
        syncPendingOrders();
      }
    };

    const handleOffline = () => {
      setIsOnline(false);
    };

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, [journey?.id, pendingOrdersCount, syncQueuedData, syncPendingOrders]);

  // Phase 1: Auto-restore journey on app open
  useEffect(() => {
    if (user?.id) {
      autoRestore();
    }
  }, [user?.id, autoRestore]);

  // Phase 1: Update location to both systems
  useEffect(() => {
    if (riderLocation) {
      // Update Phase 1 journey with location
      if (journey?.id) {
        updateLocation({
          latitude: riderLocation.latitude,
          longitude: riderLocation.longitude,
          accuracy: riderLocation.accuracy,
          altitude: riderLocation.altitude,
          heading: riderLocation.heading,
          speed: riderLocation.speed,
          timestamp: new Date(riderLocation.timestamp).toISOString(),
        });
      }
    }
  }, [riderLocation, journey?.id, updateLocation]);

  // Phase 1: Load orders when journey is active
  useEffect(() => {
    if (journey?.id) {
      loadJourneyOrders();
    }
  }, [journey?.id, loadJourneyOrders]);

  // Fetch destination station details
  useEffect(() => {
    if (!currentJob) return;

    const fetchDestinationDetails = async () => {
      try {
        const { data: stop, error: stopError } = await supabase
          .from('stops')
          .select('*')
          .eq('id', currentJob.destination_stop_id)
          .single();

        if (stopError) throw stopError;

        // Fetch intermediate stops
        const { data: allStops, error: stopsError } = await supabase
          .from('stops')
          .select('*')
          .order('name');

        if (stopsError) throw stopsError;

        // Build upcoming stops list (mock for now)
        if (allStops && allStops.length > 0) {
          // eslint-disable-next-line @typescript-eslint/no-explicit-any
          const stops = allStops.map((s: any) => ({
            id: s.id,
            name: s.name,
            location: {
              lat: parseFloat(s.latitude),
              lng: parseFloat(s.longitude),
            },
            hasRestaurants: true, // Query from restaurants table
            restaurantCount: 3,
            distance: Math.random() * 20 + 5,
            eta: `${Math.random() * 20 + 10} mins`,
          }));

          setUpcomingStops(stops.slice(1, 4)); // Upcoming stops

          // Phase 1: Start journey if not already active
          if (!journey?.id) {
            startJourney({
              origin_location: {
                lat: parseFloat(stop.latitude),
                lng: parseFloat(stop.longitude),
              },
              destination_location: {
                lat: parseFloat(currentJob.origin_stop_id || '0'),
                lng: parseFloat(currentJob.destination_stop_id || '0'),
              },
              notes: `Delivery to ${stop.name}`,
              status: 'in_progress',
            });
          }
        }
      } catch (err) {
        console.error('Error fetching destination:', err);
      }
    };

    fetchDestinationDetails();
  }, [currentJob, journey?.id, startJourney]);

  // Load job and build route
  useEffect(() => {
    const loadJob = async () => {
      try {
        setLoading(true);

        // Fetch specific job or use first active job
        let job = currentJob;
        if (!job && jobId) {
          const { data, error: jobError } = await supabase
            .from('delivery_jobs')
            .select('*')
            .eq('id', jobId)
            .single();

          if (jobError) throw jobError;
          job = data;
          setCurrentJob(job);
        }

        if (!job && jobs.length > 0) {
          job = jobs[0];
          setCurrentJob(job);
        }

        if (!job) {
          setError('No active delivery job found');
          setLoading(false);
          return;
        }

        // Fetch origin and destination stops
        const { data: stops, error: stopsError } = await supabase
          .from('stops')
          .select('*')
          .in('id', [job.origin_stop_id, job.destination_stop_id]);

        if (stopsError) throw stopsError;

        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const origin = stops?.find((s: any) => s.id === job.origin_stop_id);
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const destination = stops?.find((s: any) => s.id === job.destination_stop_id);

        if (origin && destination && riderLocation) {
          // Build route with current location
          const newRoute: DeliveryRoute = {
            currentLocation: {
              lat: riderLocation.latitude,
              lng: riderLocation.longitude,
            },
            destination: {
              lat: parseFloat(destination.latitude),
              lng: parseFloat(destination.longitude),
            },
            currentStation: {
              id: origin.id,
              name: origin.name,
              location: {
                lat: parseFloat(origin.latitude),
                lng: parseFloat(origin.longitude),
              },
              hasRestaurants: true,
              restaurantCount: 5,
              isCurrent: true,
              eta: '8 mins',
              distance: 2.3,
            },
            upcomingStations: upcomingStops,
            estimatedArrival: calculateETA(new Date(), 30), // 30 mins
            totalDistance: 25.8,
            totalTime: '42 mins',
          };

          setRoute(newRoute);
        }

        setError(null);
      } catch (err) {
        console.error('Error loading job:', err);
        setError(err instanceof Error ? err.message : 'Failed to load delivery');
      } finally {
        setLoading(false);
      }
    };

    if (riderLocation && upcomingStops.length > 0) {
      loadJob();
    }
  }, [jobId, jobs, riderLocation, upcomingStops, currentJob]);

  // Start GPS tracking
  useEffect(() => {
    startTracking();
  }, [startTracking]);

  const calculateETA = (currentTime: Date, minutes: number): string => {
    const eta = new Date(currentTime.getTime() + minutes * 60000);
    return eta.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  if (loading || jobsLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center space-y-4">
          <Loader2 className="w-8 h-8 animate-spin mx-auto text-blue-400" />
          <p className="text-white font-semibold">Loading delivery route...</p>
          {gpsError && <p className="text-sm text-yellow-400">GPS: {gpsError}</p>}
        </div>
      </div>
    );
  }

  if (error || !route) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-950 p-4">
        <Button
          variant="ghost"
          onClick={() => navigate(-1)}
          className="mb-4"
        >
          <ArrowLeft className="w-4 h-4 mr-2" /> Back
        </Button>
        <Card className="bg-slate-800 border-red-500/50">
          <CardHeader>
            <CardTitle className="text-red-500 flex items-center gap-2">
              <AlertCircle className="w-5 h-5" />
              {error || 'Route Not Found'}
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-slate-400 mb-4">
              {error || 'The delivery route could not be loaded. Please try again or return to the dashboard.'}
            </p>
            <Button onClick={() => navigate(-1)}>Return to Dashboard</Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 to-slate-950">
      {/* Main Content */}
      <div className="p-4 md:p-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="max-w-7xl mx-auto space-y-6"
        >
          {/* Header */}
          <div className="flex items-center justify-between md:pr-0">
            <div className="flex items-center gap-4">
              <Button
                variant="ghost"
                onClick={() => navigate(-1)}
                className="h-10"
              >
                <ArrowLeft className="w-5 h-5" />
              </Button>
              <div>
                <h1 className="text-3xl font-bold text-white">Live Delivery Tracking</h1>
                <p className="text-slate-400">
                  {currentJob?.order_id ? `Order #${currentJob.order_id.slice(0, 8)}` : 'Active Delivery'}
                </p>
              </div>
            </div>
            
            {/* Desktop Navigation */}
            <div className="hidden md:flex items-center gap-2 flex-wrap">
              {isTracking && (
                <Badge className="bg-emerald-600 text-white px-3 py-1.5">
                  🟢 Live Tracking
                </Badge>
              )}
              {backgroundTracking && (
                <Badge className="bg-purple-600 text-white px-3 py-1.5">
                  📍 Background GPS
                </Badge>
              )}
              {isOnline ? (
                <Badge className="bg-blue-600 text-white px-3 py-1.5 flex items-center gap-1">
                  <Wifi className="w-3 h-3" /> Online
                </Badge>
              ) : (
                <Badge className="bg-orange-600 text-white px-3 py-1.5 flex items-center gap-1">
                  <WifiOff className="w-3 h-3" /> Offline
                </Badge>
              )}
              {pendingOrdersCount > 0 && (
                <Badge className="bg-yellow-600 text-white px-3 py-1.5">
                  ⏳ {pendingOrdersCount} Pending
                </Badge>
              )}
              {!isTracking && gpsError && (
                <Badge className="bg-yellow-600 text-white px-3 py-1.5">
                  ⚠️ GPS Inactive
                </Badge>
              )}
              <Button onClick={() => navigate('/dashboard')} variant="outline" size="sm">
                <BarChart3 className="w-4 h-4 mr-2" /> Dashboard
              </Button>
              <Button onClick={() => navigate('/verification')} variant="outline" size="sm">
                <Shield className="w-4 h-4 mr-2" /> Verify
              </Button>
              <Button onClick={async () => { 
                const { error } = await supabase.auth.signOut();
                if (!error) {
                  setTimeout(() => navigate('/'), 100);
                }
              }} variant="destructive" size="sm">
                <LogOut className="w-4 h-4 mr-2" /> Sign Out
              </Button>
            </div>
          </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Map Section */}
          <div className="lg:col-span-2 space-y-4">
            <JourneyMap
              route={route}
              onStationClick={setSelectedStation}
              isTracking={isTracking}
            />

            {/* Live Stats */}
            <Card className="bg-slate-800/50 border-slate-700">
              <CardContent className="pt-6">
                <div className="grid grid-cols-3 gap-4">
                  <div className="text-center">
                    <p className="text-slate-400 text-sm mb-1">Current Speed</p>
                    <p className="text-2xl font-bold text-blue-400">
                      {riderLocation ? Math.floor(Math.random() * 40 + 10) : '0'} km/h
                    </p>
                  </div>
                  <div className="text-center">
                    <p className="text-slate-400 text-sm mb-1">Accuracy</p>
                    <p className="text-2xl font-bold text-emerald-400">
                      {riderLocation?.accuracy ? `±${riderLocation.accuracy.toFixed(0)}m` : '--'}
                    </p>
                  </div>
                  <div className="text-center">
                    <p className="text-slate-400 text-sm mb-1">Last Update</p>
                    <p className="text-xs text-slate-400 mt-2">
                      {riderLocation
                        ? new Date(riderLocation.timestamp).toLocaleTimeString()
                        : 'Waiting...'}
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Timeline Sidebar */}
          <div className="lg:col-span-1">
            <JourneyTimeline
              stations={[
                route.currentStation!,
                ...route.upcomingStations,
              ]}
              currentStationIndex={0}
              activeStation={selectedStation || route.currentStation}
              onRestaurantSelect={(stationId, restaurantId) => {
                console.log(
                  `Selected restaurant ${restaurantId} at station ${stationId}`
                );
              }}
            />
          </div>
        </div>

        {/* Phase 1: Queue Status & Actions */}
        {(queueStats.queuedLocations > 0 || pendingOrdersCount > 0) && (
          <Card className="bg-slate-800/50 border-slate-700">
            <CardContent className="pt-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {queueStats.queuedLocations > 0 && (
                  <div>
                    <p className="text-slate-400 text-sm mb-1">Queued Locations</p>
                    <p className="text-2xl font-bold text-yellow-400">
                      {queueStats.queuedLocations}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">
                      Will sync when online
                    </p>
                  </div>
                )}
                {pendingOrdersCount > 0 && (
                  <div>
                    <p className="text-slate-400 text-sm mb-1">Pending Orders</p>
                    <p className="text-2xl font-bold text-orange-400">
                      {pendingOrdersCount}
                    </p>
                    <p className="text-xs text-slate-500 mt-1">
                      Awaiting sync
                    </p>
                  </div>
                )}
                {journey?.id && (
                  <div>
                    <p className="text-slate-400 text-sm mb-1">Journey Status</p>
                    <p className="text-2xl font-bold text-emerald-400 capitalize">
                      {journey.status}
                    </p>
                    <Button
                      size="sm"
                      className="mt-2 w-full"
                      onClick={() => endJourney()}
                      variant="outline"
                    >
                      End Journey
                    </Button>
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        )}
        {/* Performance Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <StatsCard label="Trip Distance" value={`${route.totalDistance.toFixed(1)} km`} />
          <StatsCard label="Est. Time" value={route.totalTime} />
          <StatsCard label="Completion Rate" value="98%" color="emerald" />
          <StatsCard label="Rider Rating" value="4.9 ⭐" color="yellow" />
        </div>
      </motion.div>
      </div>
    </div>
  );
};

interface StatsCardProps {
  label: string;
  value: string;
  color?: 'blue' | 'emerald' | 'yellow';
}

const StatsCard: React.FC<StatsCardProps> = ({ label, value, color = 'blue' }) => {
  const colorClass = {
    blue: 'text-blue-400',
    emerald: 'text-emerald-400',
    yellow: 'text-yellow-400',
  }[color];

  return (
    <Card className="bg-slate-800/30 border-slate-700">
      <CardContent className="pt-4">
        <p className="text-xs text-slate-400 mb-1">{label}</p>
        <p className={`text-2xl font-bold ${colorClass}`}>{value}</p>
      </CardContent>
    </Card>
  );
};

export default DeliveryTracker;
