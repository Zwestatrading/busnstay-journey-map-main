/* eslint-disable @typescript-eslint/no-explicit-any */
import { useEffect, useRef, useState } from 'react';
import { MapPin, Phone, MessageSquare, AlertCircle, CheckCircle } from 'lucide-react';
import { motion } from 'framer-motion';
import { subscribeToDeliveryLocation, unsubscribeFromLocation, getDeliveryLocation } from '@/services/gpsTrackingService';
import { calculateHaversineDistance, formatDistance } from '@/services/geoService';
import { Button } from '@/components/ui/button';

interface LiveDeliveryMapProps {
  orderId: string;
  restaurantLat?: number;
  restaurantLon?: number;
  deliveryLat?: number;
  deliveryLon?: number;
  agentPhone?: string;
}

export const LiveDeliveryMap = ({
  orderId,
  restaurantLat = 40.7128,
  restaurantLon = -74.006,
  deliveryLat = 40.7580,
  deliveryLon = -73.9855,
  agentPhone,
}: LiveDeliveryMapProps) => {
  const [deliveryLocation, setDeliveryLocation] = useState<unknown>(null);
  const [distance, setDistance] = useState<number>(0);
  const [isLoading, setIsLoading] = useState(true);
  const channelRef = useRef<unknown>(null);

  useEffect(() => {
    // Load initial location
    const loadInitialLocation = async () => {
      const location = await getDeliveryLocation(orderId);
      if (location) {
        setDeliveryLocation(location);
        const dist = calculateHaversineDistance(
          location.latitude,
          location.longitude,
          deliveryLat || 40.7580,
          deliveryLon || -73.9855
        );
        setDistance(dist);
      }
      setIsLoading(false);
    };

    loadInitialLocation();

    // Subscribe to real-time updates
    const channel = subscribeToDeliveryLocation(
      orderId,
      (newLocation) => {
        setDeliveryLocation(newLocation);
        const dist = calculateHaversineDistance(
          newLocation.latitude,
          newLocation.longitude,
          deliveryLat || 40.7580,
          deliveryLon || -73.9855
        );
        setDistance(dist);
      }
    );

    channelRef.current = channel;

    return () => {
      if (channel) {
        unsubscribeFromLocation(channel);
      }
    };
  }, [orderId, deliveryLat, deliveryLon]);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'picked_up':
        return 'from-blue-600 to-blue-700';
      case 'in_transit':
        return 'from-orange-600 to-amber-600';
      case 'arrived':
        return 'from-green-600 to-emerald-600';
      case 'delivered':
        return 'from-green-700 to-green-800';
      default:
        return 'from-gray-600 to-gray-700';
    }
  };

  const getStatusLabel = (status: string) => {
    switch (status) {
      case 'picked_up':
        return 'Picked Up - On the way!';
      case 'in_transit':
        return 'In Transit';
      case 'arrived':
        return 'Arrived at Destination';
      case 'delivered':
        return 'Delivered';
      default:
        return 'Pending';
    }
  };

  if (isLoading) {
    return (
      <div className="w-full h-80 bg-slate-900 rounded-xl flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-400">Loading delivery location...</p>
        </div>
      </div>
    );
  }

  if (!deliveryLocation) {
    return (
      <div className="w-full h-80 bg-slate-900 rounded-xl flex items-center justify-center">
        <div className="text-center">
          <AlertCircle className="w-12 h-12 text-yellow-400 mx-auto mb-4" />
          <p className="text-gray-400">Delivery location not available</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="w-full space-y-4"
    >
      {/* Map Container */}
      <div className="relative w-full h-80 bg-slate-800 rounded-xl overflow-hidden border border-white/10">
        {/* Simple map representation - Replace with actual map library if needed */}
        <div className="w-full h-full flex flex-col items-center justify-center">
          <div className="text-center space-y-4">
            <MapPin className="w-16 h-16 text-blue-400 mx-auto" />
            <div>
              <p className="text-white font-semibold">
                {(deliveryLocation as any).latitude.toFixed(4)}, {(deliveryLocation as any).longitude.toFixed(4)}
              </p>
              <p className="text-sm text-gray-400 mt-2">
                Distance remaining: {formatDistance((deliveryLocation as any).distance_remaining_km || distance)}
              </p>
              <p className="text-sm text-gray-400">
                Speed: {(deliveryLocation as any).speed_kmh ? `${Math.round((deliveryLocation as any).speed_kmh)} km/h` : 'N/A'}
              </p>
            </div>
          </div>

          {/* Marker for current location */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <motion.div
              animate={{ scale: [1, 1.2, 1] }}
              transition={{ duration: 2, repeat: Infinity }}
              className="w-4 h-4 bg-blue-500 rounded-full ring-4 ring-blue-400/30"
            />
          </div>
        </div>
      </div>

      {/* Status Card */}
      <motion.div
        className={`p-6 rounded-xl bg-gradient-to-r ${getStatusColor(
          (deliveryLocation as any).status
        )} border border-white/10`}
      >
        <div className="flex items-center justify-between text-white">
          <div>
            <p className="text-sm opacity-90">Delivery Status</p>
            <p className="text-xl font-bold">{getStatusLabel((deliveryLocation as any).status)}</p>
          </div>
          {(deliveryLocation as any).status === 'delivered' ? (
            <CheckCircle className="w-8 h-8" />
          ) : (
            <MapPin className="w-8 h-8" />
          )}
        </div>
      </motion.div>

      {/* Details and Actions */}
      <div className="grid grid-cols-2 gap-4">
        {/* Distance */}
        <div className="p-4 bg-slate-800/50 rounded-lg border border-white/10">
          <p className="text-sm text-gray-400 mb-2">Distance Remaining</p>
          <p className="text-2xl font-bold text-white">
            {formatDistance((deliveryLocation as any).distance_remaining_km || distance)}
          </p>
        </div>

        {/* ETA */}
        <div className="p-4 bg-slate-800/50 rounded-lg border border-white/10">
          <p className="text-sm text-gray-400 mb-2">Estimated Arrival</p>
          {(deliveryLocation as any).estimated_arrival ? (
            <p className="text-lg font-semibold text-white">
              {new Date((deliveryLocation as any).estimated_arrival).toLocaleTimeString([], {
                hour: '2-digit',
                minute: '2-digit',
              })}
            </p>
          ) : (
            <p className="text-lg font-semibold text-gray-400">Calculating...</p>
          )}
        </div>
      </div>

      {/* Contact & Actions */}
      <div className="flex gap-3">
        {agentPhone && (
          <Button className="flex-1 bg-blue-600 hover:bg-blue-700 text-white">
            <Phone className="w-4 h-4 mr-2" />
            Call Delivery Partner
          </Button>
        )}
        <Button className="flex-1 bg-slate-700 hover:bg-slate-600 text-white" variant="outline">
          <MessageSquare className="w-4 h-4 mr-2" />
          Message
        </Button>
      </div>

      {/* Last Updated */}
      <p className="text-xs text-gray-500 text-center">
        Last updated: {new Date((deliveryLocation as any).last_update).toLocaleTimeString()}
      </p>
    </motion.div>
  );
};

export default LiveDeliveryMap;
