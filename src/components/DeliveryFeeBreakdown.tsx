import { useEffect, useState } from 'react';
import { DollarSign, Truck, MapPin, Clock } from 'lucide-react';
import { motion } from 'framer-motion';
import { calculateDeliveryFee, formatDeliveryFee } from '@/services/deliveryFeeService';
import { formatDistance, estimateDeliveryTime } from '@/services/geoService';

interface DeliveryFeeBreakdownProps {
  restaurantId: string;
  distanceKm: number;
  orderTotal?: number;
  isLoading?: boolean;
}

export const DeliveryFeeBreakdown = ({
  restaurantId,
  distanceKm,
  orderTotal,
  isLoading: externalLoading = false,
}: DeliveryFeeBreakdownProps) => {
  const [feeData, setFeeData] = useState<unknown>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchFee = async () => {
      try {
        setIsLoading(true);
        setError(null);
        const result = await calculateDeliveryFee(restaurantId, distanceKm, orderTotal);
        setFeeData(result);
      } catch (err) {
        setError('Failed to calculate delivery fee');
        console.error(err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchFee();
  }, [restaurantId, distanceKm, orderTotal]);

  if (isLoading || externalLoading) {
    return (
      <div className="p-6 rounded-xl bg-slate-800/50 border border-white/10 animate-pulse">
        <div className="h-4 bg-slate-700 rounded w-1/3 mb-4" />
        <div className="h-8 bg-slate-700 rounded w-1/2" />
      </div>
    );
  }

  if (error || !feeData) {
    return (
      <div className="p-6 rounded-xl bg-red-900/20 border border-red-500/50 text-red-400">
        {error || 'Unable to calculate delivery fee'}
      </div>
    );
  }

  const estimatedTime = estimateDeliveryTime(distanceKm);

  // Extract feeData properties with type assertions
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const totalFee = (feeData as any).totalFee;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const baseFee = (feeData as any).baseFee;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const distanceFeeAmount = (feeData as any).distanceFee;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-4"
    >
      {/* Main Fee Display */}
      <div className="p-6 rounded-xl bg-gradient-to-r from-green-900/30 to-emerald-900/30 border border-green-500/50">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div className="p-3 bg-green-600/20 rounded-lg">
              <Truck className="w-6 h-6 text-green-400" />
            </div>
            <div>
              <p className="text-sm text-gray-300">Delivery Fee</p>
              <p className="text-3xl font-bold text-white">{formatDeliveryFee(totalFee)}</p>
            </div>
          </div>
        </div>
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-xs text-gray-400">Distance</p>
            <p className="text-lg font-semibold text-gray-200">{formatDistance(distanceKm)}</p>
          </div>
          <div>
            <p className="text-xs text-gray-400">Estimated Time</p>
            <p className="text-lg font-semibold text-gray-200">{estimatedTime} mins</p>
          </div>
        </div>
      </div>

      {/* Fee Breakdown */}
      <div className="p-4 rounded-lg bg-slate-800/50 border border-white/10 space-y-3">
        <div className="flex items-center justify-between">
          <p className="text-sm text-gray-400">Base Delivery Fee</p>
          <p className="font-semibold text-white">{formatDeliveryFee(baseFee)}</p>
        </div>
        <div className="h-px bg-white/10" />
        <div className="flex items-center justify-between">
          <p className="text-sm text-gray-400">Distance Charge ({formatDistance(distanceKm)})</p>
          <p className="font-semibold text-white">{formatDeliveryFee(distanceFeeAmount)}</p>
        </div>
        <div className="h-px bg-white/10" />
        <div className="flex items-center justify-between">
          <p className="text-sm font-semibold text-gray-300">Total</p>
          <p className="text-lg font-bold text-green-400">{formatDeliveryFee(totalFee)}</p>
        </div>
      </div>

      {/* Details Grid */}
      <div className="grid grid-cols-3 gap-3">
        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-blue-900/20 border border-blue-500/30 text-center"
        >
          <MapPin className="w-5 h-5 text-blue-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Distance</p>
          <p className="text-sm font-bold text-white">{distanceKm.toFixed(1)} km</p>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-orange-900/20 border border-orange-500/30 text-center"
        >
          <Clock className="w-5 h-5 text-orange-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Est. Time</p>
          <p className="text-sm font-bold text-white">{estimatedTime} min</p>
        </motion.div>

        <motion.div
          whileHover={{ scale: 1.05 }}
          className="p-4 rounded-lg bg-green-900/20 border border-green-500/30 text-center"
        >
          <DollarSign className="w-5 h-5 text-green-400 mx-auto mb-2" />
          <p className="text-xs text-gray-400">Fee</p>
          <p className="text-sm font-bold text-green-400">{formatDeliveryFee(totalFee)}</p>
        </motion.div>
      </div>

      {/* Note */}
      <p className="text-xs text-gray-500 text-center">
        Delivery costs vary based on distance, demand, and time of day
      </p>
    </motion.div>
  );
};

export default DeliveryFeeBreakdown;
