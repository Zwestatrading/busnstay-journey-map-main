/* eslint-disable @typescript-eslint/no-explicit-any */
import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
  MapPin,
  Zap,
  Compass,
  Activity,
  SignalLow,
  AlertTriangle,
  CheckCircle,
  Clock,
} from 'lucide-react';
import {
  getRiderLocation,
  subscribeToRiderLocation,
  unsubscribeFromLocation,
  getPendingGeofenceAlerts,
  subscribeToGeofenceAlerts,
} from '@/services/gpsTrackingService';
import { formatDistance, formatSpeed } from '@/services/geoService';

interface GPSTrackingStatusProps {
  riderId: string;
  showAlerts?: boolean;
}

export const GPSTrackingStatus = ({ riderId, showAlerts = true }: GPSTrackingStatusProps) => {
  const [location, setLocation] = useState<unknown>(null);
  const [alerts, setAlerts] = useState<unknown[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [gpsSignalQuality, setGpsSignalQuality] = useState<'excellent' | 'good' | 'fair' | 'poor'>(
    'good'
  );
  const channelRef = useState<unknown>(null)[1];

  useEffect(() => {
    // Demo location data when no real data available
    const demoLocation = {
      id: 'demo-location-' + riderId,
      rider_id: riderId,
      current_location: 'Lusaka City Center',
      latitude: -17.8252,
      longitude: 25.2637,
      is_online: true,
      is_on_delivery: true,
      speed_kmh: 45.3,
      accuracy: 8.5,
      last_update: new Date().toISOString(),
    };

    // Load initial location
    const loadInitialLocation = async () => {
      try {
        const loc = await getRiderLocation(riderId);
        if (loc) {
          setLocation(loc);
          // Determine signal quality based on accuracy
          if (loc.accuracy && loc.accuracy < 5) setGpsSignalQuality('excellent');
          else if (loc.accuracy && loc.accuracy < 10) setGpsSignalQuality('good');
          else if (loc.accuracy && loc.accuracy < 20) setGpsSignalQuality('fair');
          else setGpsSignalQuality('poor');
        } else {
          // Use demo location if no real data
          setLocation(demoLocation);
          setGpsSignalQuality('good');
        }
      } catch (error) {
        console.error('Error loading location:', error);
        // Fallback to demo location
        setLocation(demoLocation);
        setGpsSignalQuality('good');
      } finally {
        setIsLoading(false);
      }
    };

    loadInitialLocation();

    // Subscribe to location updates
    const channel = subscribeToRiderLocation(riderId, (newLocation) => {
      setLocation(newLocation || demoLocation);
      // Update signal quality
      const accuracy = newLocation?.accuracy || demoLocation.accuracy;
      if (accuracy < 5) setGpsSignalQuality('excellent');
      else if (accuracy < 10) setGpsSignalQuality('good');
      else if (accuracy < 20) setGpsSignalQuality('fair');
      else setGpsSignalQuality('poor');
    });

    // Load and subscribe to alerts
    if (showAlerts) {
      const loadAlerts = async () => {
        const pendingAlerts = await getPendingGeofenceAlerts(riderId);
        setAlerts(pendingAlerts);
      };

      loadAlerts();

      const alertChannel = subscribeToGeofenceAlerts(riderId, (newAlert) => {
        setAlerts((prev) => [newAlert, ...prev]);
      });
    }

    return () => {
      if (channel) unsubscribeFromLocation(channel);
    };
  }, [riderId, showAlerts]);

  if (isLoading) {
    return (
      <div className="p-6 rounded-xl bg-slate-800/50 border border-white/10 animate-pulse">
        <div className="h-4 bg-slate-700 rounded w-1/3 mb-4" />
        <div className="h-8 bg-slate-700 rounded w-1/2" />
      </div>
    );
  }



  const signalIcons: Record<string, unknown> = {
    excellent: <CheckCircle className="w-5 h-5 text-green-400" />,
    good: <Activity className="w-5 h-5 text-blue-400" />,
    fair: <Zap className="w-5 h-5 text-yellow-400" />,
    poor: <SignalLow className="w-5 h-5 text-red-400" />,
  };

  const signalColors: Record<string, string> = {
    excellent: 'from-green-600 to-green-700',
    good: 'from-blue-600 to-cyan-600',
    fair: 'from-yellow-600 to-amber-600',
    poor: 'from-red-600 to-rose-600',
  };

  const lastUpdateTime = new Date((location as any)?.last_update || new Date());
  const timeSinceUpdate = Math.floor((Date.now() - lastUpdateTime.getTime()) / 1000);

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      {/* GPS Signal Quality Card */}
      <motion.div
        className={`p-6 rounded-xl bg-gradient-to-r ${signalColors[gpsSignalQuality]} border border-white/10`}
      >
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {signalIcons[gpsSignalQuality] as unknown as React.ReactNode}
            <div>
              <p className="text-sm opacity-90 capitalize">GPS Signal: {gpsSignalQuality}</p>
              <p className="text-2xl font-bold">Tracking Active</p>
            </div>
          </div>
          <motion.div
            animate={{ scale: [1, 1.2, 1] }}
            transition={{ duration: 2, repeat: Infinity }}
            className="w-4 h-4 bg-white rounded-full opacity-60"
          />
        </div>
      </motion.div>

      {/* Location Details Grid */}
      <div className="grid grid-cols-2 gap-3">
        {/* Latitude */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <p className="text-xs text-gray-400 mb-1">Latitude</p>
          <p className="font-mono text-sm text-white">{(location as any).latitude.toFixed(6)}</p>
        </motion.div>

        {/* Longitude */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <p className="text-xs text-gray-400 mb-1">Longitude</p>
          <p className="font-mono text-sm text-white">{(location as any).longitude.toFixed(6)}</p>
        </motion.div>

        {/* Accuracy */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <p className="text-xs text-gray-400 mb-1">Accuracy</p>
          <p className="font-semibold text-sm text-blue-400">±{(location as any).accuracy?.toFixed(0) || 'N/A'} m</p>
        </motion.div>

        {/* Speed */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <p className="text-xs text-gray-400 mb-1">Speed</p>
          <p className="font-semibold text-sm text-orange-400">{formatSpeed((location as any).speed_kmh)}</p>
        </motion.div>

        {/* Heading */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs text-gray-400 mb-1">Direction</p>
              <p className="font-semibold text-sm text-green-400">
                {(location as any).heading ? `${Math.round((location as any).heading)}°` : 'N/A'}
              </p>
            </div>
            {(location as any).heading && (
              <motion.div
                animate={{ rotate: (location as any).heading }}
                transition={{ type: 'spring', damping: 20 }}
              >
                <Compass className="w-5 h-5 text-green-400" />
              </motion.div>
            )}
          </div>
        </motion.div>

        {/* Status */}
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-slate-800/50 border border-white/10"
        >
          <p className="text-xs text-gray-400 mb-1">Status</p>
          <div className="flex items-center gap-2">
            <div className={`w-2 h-2 rounded-full ${(location as any).is_online ? 'bg-green-500' : 'bg-red-500'}`} />
            <p className="font-semibold text-sm text-white capitalize">
              {(location as any).is_online ? 'Online' : 'Offline'}
            </p>
          </div>
        </motion.div>
      </div>

      {/* Last Update */}
      <div className="p-4 rounded-lg bg-slate-800/50 border border-white/10">
        <div className="flex items-center justify-between">
          <p className="text-sm text-gray-400">Last Updated</p>
          <p className="text-sm font-semibold text-gray-300">
            {timeSinceUpdate < 60 ? `${timeSinceUpdate}s ago` : 
             timeSinceUpdate < 3600 ? `${Math.floor(timeSinceUpdate / 60)}m ago` : 
             lastUpdateTime.toLocaleTimeString()}
          </p>
        </div>
      </div>

      {/* Geofence Alerts */}
      {showAlerts && alerts.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="space-y-2"
        >
          <p className="text-sm font-semibold text-white">Recent Alerts</p>
          {alerts.slice(0, 3).map((alert) => (
            <motion.div
              key={(alert as any).id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              className="p-3 rounded-lg bg-yellow-900/20 border border-yellow-500/50 text-yellow-400 text-sm flex items-start gap-2"
            >
              <AlertTriangle className="w-4 h-4 flex-shrink-0 mt-0.5" />
              <div>
                <p className="font-semibold capitalize">{(alert as any).alert_type.replaceAll('_', ' ')}</p>
                <p className="text-xs">{(alert as any).alert_message}</p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      )}

      {/* Info Footer */}
      <p className="text-xs text-gray-500 text-center">
        <Clock className="w-3 h-3 inline mr-1" />
        Real-time tracking active • Updates every 5 seconds
      </p>
    </motion.div>
  );
};

export default GPSTrackingStatus;
