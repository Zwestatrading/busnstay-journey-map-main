import { supabase } from '@/lib/supabase';
import { calculateHaversineDistance } from './geoService';

interface DeliveryFeeConfig {
  baseFee: number;
  feePerKm: number;
  estimatedTimeMinutes: number;
}

interface DeliveryFeeResult {
  baseFee: number;
  distanceFee: number;
  totalFee: number;
  estimatedDeliveryTime: number;
  breakdown: string;
}

interface RestaurantDeliveryConfig {
  restaurantId: string;
  baseK20Fee: number; // Fixed K20 fee
  distanceBasedFeePerKm: number; // Additional fee per km
  isNearStation: boolean; // true if by station, false if away from station
  restaurantLatitude: number;
  restaurantLongitude: number;
  stationLatitude: number;
  stationLongitude: number;
}

/**
 * Calculate delivery fee based on restaurant rates and distance
 */
export const calculateDeliveryFee = async (
  restaurantId: string,
  distanceKm: number,
  orderTotal?: number
): Promise<DeliveryFeeResult> => {
  try {
    // Call Supabase function to calculate fee
    const { data, error } = await supabase.rpc(
      'calculate_delivery_fee',
      {
        restaurant_id: restaurantId,
        distance_km: distanceKm,
        order_total: orderTotal,
      }
    );

    if (error) throw error;

    const fee = data || 0;
    const estimatedTime = Math.ceil((distanceKm / 25) * 60) + 5; // 25 km/h average speed + 5 min buffer

    return {
      baseFee: Math.min(fee, fee * 0.3), // Estimate base portion
      distanceFee: fee - Math.min(fee, fee * 0.3),
      totalFee: fee,
      estimatedDeliveryTime: estimatedTime,
      breakdown: `Base: $${(fee * 0.3).toFixed(2)} + Distance: $${(fee - fee * 0.3).toFixed(2)}`,
    };
  } catch (error) {
    console.error('Error calculating delivery fee:', error);

    // Fallback calculation
    const baseFee = 2.5;
    const feePerKm = 0.5;
    const totalFee = baseFee + distanceKm * feePerKm;
    const estimatedTime = Math.ceil((distanceKm / 25) * 60) + 5;

    return {
      baseFee,
      distanceFee: distanceKm * feePerKm,
      totalFee,
      estimatedDeliveryTime: estimatedTime,
      breakdown: `Base: $${baseFee.toFixed(2)} + Distance: $${(distanceKm * feePerKm).toFixed(2)}`,
    };
  }
};

/**
 * Get restaurant's delivery configuration
 */
export const getRestaurantDeliveryConfig = async (
  restaurantId: string
): Promise<DeliveryFeeConfig | null> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select('base_delivery_fee, delivery_fee_per_km')
      .eq('id', restaurantId)
      .single();

    if (error) throw error;

    return {
      baseFee: data?.base_delivery_fee || 2.5,
      feePerKm: data?.delivery_fee_per_km || 0.5,
      estimatedTimeMinutes: 30,
    };
  } catch (error) {
    console.error('Error fetching restaurant delivery config:', error);
    return null;
  }
};

/**
 * Update restaurant's delivery configuration (admin/owner only)
 */
export const updateRestaurantDeliveryConfig = async (
  restaurantId: string,
  config: Partial<DeliveryFeeConfig>
): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('restaurants')
      .update({
        base_delivery_fee: config.baseFee,
        delivery_fee_per_km: config.feePerKm,
      })
      .eq('id', restaurantId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error updating delivery config:', error);
    return false;
  }
};

/**
 * Check if delivery location is in restaurant's delivery zone
 */
export const checkDeliveryZone = async (
  restaurantId: string,
  latitude: number,
  longitude: number
): Promise<boolean> => {
  try {
    const { data, error } = await supabase.rpc(
      'is_in_delivery_zone',
      {
        restaurant_id: restaurantId,
        delivery_point: {
          type: 'Point',
          coordinates: [longitude, latitude],
        },
      }
    );

    if (error) throw error;
    return data || false;
  } catch (error) {
    console.error('Error checking delivery zone:', error);
    return false;
  }
};

/**
 * Get all delivery zones for a restaurant
 */
export const getRestaurantDeliveryZones = async (restaurantId: string) => {
  try {
    const { data, error } = await supabase
      .from('delivery_zones')
      .select('*')
      .eq('restaurant_id', restaurantId)
      .eq('is_active', true);

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching delivery zones:', error);
    return [];
  }
};

/**
 * Create delivery zone for restaurant
 */
export const createDeliveryZone = async (
  restaurantId: string,
  zoneName: string,
  maxDistanceKm: number,
  minOrderValue?: number,
  deliveryTimeMinutes?: number
) => {
  try {
    // For now, we'll store the max distance as metadata
    // In production, you'd need to capture the polygon from user input
    const { data, error } = await supabase
      .from('delivery_zones')
      .insert({
        restaurant_id: restaurantId,
        zone_name: zoneName,
        max_distance_km: maxDistanceKm,
        min_order_value: minOrderValue || 0,
        delivery_time_minutes: deliveryTimeMinutes || 30,
        coverage_area: null, // Would be filled by frontend map selection
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error creating delivery zone:', error);
    return null;
  }
};

/**
 * Get delivery fee rules for a restaurant
 */
export const getDeliveryFeeRules = async (restaurantId: string) => {
  try {
    const { data, error } = await supabase
      .from('delivery_fee_rules')
      .select('*')
      .eq('restaurant_id', restaurantId)
      .eq('is_active', true);

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching delivery fee rules:', error);
    return [];
  }
};

/**
 * Create custom delivery fee rule
 */
export const createDeliveryFeeRule = async (
  restaurantId: string,
  rule: {
    distanceRangeStart: number;
    distanceRangeEnd: number;
    feeFlat?: number;
    feePercentage?: number;
    dayOfWeek?: string[];
  }
) => {
  try {
    const { data, error } = await supabase
      .from('delivery_fee_rules')
      .insert({
        restaurant_id: restaurantId,
        distance_range_start: rule.distanceRangeStart,
        distance_range_end: rule.distanceRangeEnd,
        fee_flat: rule.feeFlat,
        fee_percentage: rule.feePercentage,
        day_of_week: rule.dayOfWeek,
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error creating fee rule:', error);
    return null;
  }
};

/**
 * Format fee for display
 */
export const formatDeliveryFee = (fee: number): string => {
  return `$${fee.toFixed(2)}`;
};

/**
 * Calculate dynamic surge pricing based on demand
 */
export const calculateSurgePricing = (baseFee: number, demandLevel: number): number => {
  // demandLevel: 1 (low) to 5 (extreme)
  const surgeMultipliers: Record<number, number> = {
    1: 1.0,    // Low demand
    2: 1.1,    // Normal
    3: 1.25,   // Moderate demand
    4: 1.5,    // High demand
    5: 2.0,    // Extreme demand
  };

  const multiplier = surgeMultipliers[demandLevel] || 1.0;
  return Math.round(baseFee * multiplier * 100) / 100;
};

/**
 * Calculate promotion/discount on delivery
 */
export const applyDeliveryDiscount = (
  fee: number,
  discountPercentage: number,
  minOrderValue?: number,
  orderTotal?: number
): number => {
  // Check minimum order requirement
  if (minOrderValue && orderTotal && orderTotal < minOrderValue) {
    return fee; // No discount if minimum not met
  }

  const discount = fee * (discountPercentage / 100);
  const finalFee = Math.max(fee - discount, 0); // Don't go negative

  return Math.round(finalFee * 100) / 100;
};
/**
 * Calculate K20 + distance-based delivery fee for restaurants
 * K20 is a fixed fee + additional charge per km if restaurant is away from station
 */
export const calculateRestaurantDeliveryFeeK20 = (
  config: RestaurantDeliveryConfig
): DeliveryFeeResult => {
  const baseK20Fee = config.baseK20Fee; // Fixed K20 fee
  
  // Calculate distance between restaurant and station if restaurant is away from station
  let distanceFee = 0;
  let distanceKm = 0;

  if (!config.isNearStation) {
    // Calculate distance only if restaurant is away from station
    distanceKm = calculateHaversineDistance(
      config.restaurantLatitude,
      config.restaurantLongitude,
      config.stationLatitude,
      config.stationLongitude
    );
    
    // Add distance-based fee per km
    distanceFee = distanceKm * config.distanceBasedFeePerKm;
  }

  const totalFee = baseK20Fee + distanceFee;
  const estimatedTime = calculateDeliveryTimeK20(distanceKm, config.isNearStation);

  return {
    baseFee: baseK20Fee,
    distanceFee: Math.round(distanceFee * 100) / 100,
    totalFee: Math.round(totalFee * 100) / 100,
    estimatedDeliveryTime: estimatedTime,
    breakdown: config.isNearStation
      ? `K${baseK20Fee.toFixed(2)} (Station Location)`
      : `K${baseK20Fee.toFixed(2)} + K${distanceFee.toFixed(2)} distance fee (${distanceKm.toFixed(1)}km away)`,
  };
};

/**
 * Estimate delivery time based on restaurant location and K20 pricing model
 */
const calculateDeliveryTimeK20 = (distanceKm: number, isNearStation: boolean): number => {
  const baseTimeMinutes = isNearStation ? 15 : 20; // Faster if near station
  const distanceTime = Math.ceil((distanceKm / 25) * 60); // 25 km/h average speed
  const totalTime = baseTimeMinutes + distanceTime + 5; // +5 min buffer for prep
  
  return totalTime;
};

/**
 * Save restaurant's delivery configuration with K20 pricing
 */
export const saveRestaurantK20Config = async (
  restaurantId: string,
  config: {
    baseK20Fee: number;
    distancePerKmFee: number;
    isNearStation: boolean;
    latitude: number;
    longitude: number;
    stationLatitude: number;
    stationLongitude: number;
  }
): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('restaurants')
      .update({
        base_k20_fee: config.baseK20Fee,
        distance_fee_per_km: config.distancePerKmFee,
        is_near_station: config.isNearStation,
        latitude: config.latitude,
        longitude: config.longitude,
        station_latitude: config.stationLatitude,
        station_longitude: config.stationLongitude,
      })
      .eq('id', restaurantId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error saving K20 config:', error);
    return false;
  }
};

/**
 * Get restaurant's K20 pricing config
 */
export const getRestaurantK20Config = async (
  restaurantId: string
): Promise<RestaurantDeliveryConfig | null> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         base_k20_fee,
         distance_fee_per_km,
         is_near_station,
         latitude,
         longitude,
         station_latitude,
         station_longitude`
      )
      .eq('id', restaurantId)
      .single();

    if (error) throw error;

    return {
      restaurantId: data.id,
      baseK20Fee: data.base_k20_fee || 20,
      distanceBasedFeePerKm: data.distance_fee_per_km || 5,
      isNearStation: data.is_near_station ?? true,
      restaurantLatitude: data.latitude,
      restaurantLongitude: data.longitude,
      stationLatitude: data.station_latitude,
      stationLongitude: data.station_longitude,
    };
  } catch (error) {
    console.error('Error fetching K20 config:', error);
    return null;
  }
};

/**
 * Calculate transaction fee for restaurant orders
 * Restaurant pays a percentage of the order value
 */
export const calculateRestaurantTransactionFee = (
  orderTotal: number,
  transactionFeePercentage: number = 5 // Default 5% transaction fee
): number => {
  const fee = orderTotal * (transactionFeePercentage / 100);
  return Math.round(fee * 100) / 100;
};