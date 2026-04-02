import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { MapPin, Clock, Navigation } from 'lucide-react';
import { getRiderLocationHistory, getDeliveryLocationHistory } from '@/services/gpsTrackingService';
import { calculateHaversineDistance, formatDistance } from '@/services/geoService';

interface LocationHistoryProps {
  entityType: 'rider' | 'delivery';
  entityId: string;
  hoursBack?: number;
}

export const LocationHistory = ({
  entityType,
  entityId,
  hoursBack = 24,
}: LocationHistoryProps) => {
  const [history, setHistory] = useState<unknown[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [totalDistance, setTotalDistance] = useState(0);
  const [averageSpeed, setAverageSpeed] = useState(0);

  useEffect(() => {
    const loadHistory = async () => {
      try {
        setIsLoading(true);
        let data;

        if (entityType === 'rider') {
          data = await getRiderLocationHistory(entityId, hoursBack);
        } else {
          data = await getDeliveryLocationHistory(entityId, hoursBack);
        }

        setHistory(data);

        // Calculate total distance from history
        if (data.length > 1) {
          let distance = 0;
          for (let i = 1; i < data.length; i++) {
            const d = calculateHaversineDistance(
              data[i - 1].latitude,
              data[i - 1].longitude,
              data[i].latitude,
              data[i].longitude
            );
            distance += d;
          }
          setTotalDistance(distance);

          // Calculate average speed from speed records
          const speedData = data.filter((d) => d.speed_kmh);
          if (speedData.length > 0) {
            const avgSpeed =
              speedData.reduce((sum, d) => sum + (d.speed_kmh || 0), 0) / speedData.length;
            setAverageSpeed(avgSpeed);
          }
        }
      } catch (error) {
        console.error('Error loading location history:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadHistory();
  }, [entityType, entityId, hoursBack]);

  if (isLoading) {
    return (
      <div className="p-6 rounded-xl bg-slate-800/50 border border-white/10 animate-pulse">
        <div className="h-4 bg-slate-700 rounded w-1/3 mb-4" />
        <div className="space-y-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-12 bg-slate-700 rounded" />
          ))}
        </div>
      </div>
    );
  }

  if (history.length === 0) {
    return (
      <div className="p-6 rounded-xl bg-slate-800/50 border border-white/10 text-center text-gray-400">
        No location history available
      </div>
    );
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const startTime = new Date((history as any)[history.length - 1]?.recorded_at);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const endTime = new Date((history as any)[0]?.recorded_at);
  const duration = Math.round((endTime.getTime() - startTime.getTime()) / (1000 * 60)); // minutes

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      {/* Summary Stats */}
      <div className="grid grid-cols-3 gap-3">
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-blue-900/20 border border-blue-500/30 text-center"
        >
          <MapPin className="w-5 h-5 text-blue-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Distance</p>
          <p className="text-sm font-bold text-white">{formatDistance(totalDistance)}</p>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-orange-900/20 border border-orange-500/30 text-center"
        >
          <Navigation className="w-5 h-5 text-orange-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Duration</p>
          <p className="text-sm font-bold text-white">{duration} min</p>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-purple-900/20 border border-purple-500/30 text-center"
        >
          <Navigation className="w-5 h-5 text-purple-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Avg Speed</p>
          <p className="text-sm font-bold text-white">{Math.round(averageSpeed)} km/h</p>
        </motion.div>
      </div>

      {/* Location Timeline */}
      <div className="space-y-2 max-h-96 overflow-y-auto">
        <p className="text-sm font-semibold text-white mb-4">Location Timeline</p>
                {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                {(history as any).slice(0, 20).map((location: any, index: number) => {
          const recordedTime = new Date(location.recorded_at);
          {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
          const nextLocation = (history as any)[index + 1];
          const distanceToNext = nextLocation
            ? calculateHaversineDistance(
                location.latitude,
                location.longitude,
                nextLocation.latitude,
                nextLocation.longitude
              )
            : 0;

          return (
            <motion.div
              key={location.id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: index * 0.05 }}
              className="p-3 rounded-lg bg-slate-800/50 border border-white/10 hover:border-blue-500/50 transition-colors"
            >
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-2 mb-1">
                    <div className="w-2 h-2 rounded-full bg-blue-400" />
                    <p className="font-mono text-xs text-gray-400">
                      {location.latitude.toFixed(4)}, {location.longitude.toFixed(4)}
                    </p>
                  </div>

                  <div className="flex items-center gap-3 text-xs text-gray-500 ml-4">
                    <Clock className="w-3 h-3" />
                    {recordedTime.toLocaleTimeString()}
                  </div>

                  {distanceToNext > 0 && (
                    <div className="flex items-center gap-3 text-xs text-gray-500 ml-4 mt-1">
                      <Navigation className="w-3 h-3" />
                      Next point: {formatDistance(distanceToNext)}
                    </div>
                  )}

                  {location.speed_kmh && (
                    <div className="flex items-center gap-1 mt-2">
                      <span
                        className={`inline-block px-2 py-0.5 rounded text-xs font-semibold ${
                          location.speed_kmh > 50
                            ? 'bg-red-900/30 text-red-400'
                            : location.speed_kmh > 30
                              ? 'bg-yellow-900/30 text-yellow-400'
                              : 'bg-green-900/30 text-green-400'
                        }`}
                      >
                        {Math.round(location.speed_kmh)} km/h
                      </span>
                      <span className="text-gray-500">
                        {location.source === 'gps' ? 'GPS' : 'Network'} •{' '}
                        {location.accuracy ? `±${Math.round(location.accuracy)}m` : 'N/A'}
                      </span>
                    </div>
                  )}
                </div>
              </div>
            </motion.div>
          );
        })}

        {history.length > 20 && (
          <div className="p-3 text-center text-xs text-gray-500">
            +{history.length - 20} more locations
          </div>
        )}
      </div>

      {/* Timeline Stats */}
      <div className="p-4 rounded-lg bg-slate-800/50 border border-white/10 text-sm space-y-2">
        <div className="flex justify-between">
          <span className="text-gray-400">Total Points Recorded</span>
          <span className="font-semibold text-white">{history.length}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-400">Start Time</span>
          <span className="font-semibold text-white">{startTime.toLocaleTimeString()}</span>
        </div>
        <div className="flex justify-between">
          <span className="text-gray-400">End Time</span>
          <span className="font-semibold text-white">{endTime.toLocaleTimeString()}</span>
        </div>
      </div>

      {/* Info */}
      <p className="text-xs text-gray-500 text-center">
        Showing last {hoursBack} hour(s) of location data
      </p>
    </motion.div>
  );
};

export default LocationHistory;
