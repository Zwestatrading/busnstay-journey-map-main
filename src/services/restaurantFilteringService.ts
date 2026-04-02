import { supabase } from '@/lib/supabase';

export interface ApprovedRestaurant {
  id: string;
  name: string;
  stationId: string;
  stationName: string;
  isApproved: boolean;
  isNearStation: boolean;
  latitude: number;
  longitude: number;
  baseK20Fee: number;
  distanceFeePerKm: number;
  isActive: boolean;
  menuItems: number; // Count of menu items
  rating?: number;
  totalOrders?: number;
  approvalStatus: string;
}

/**
 * Get only APPROVED restaurants for a specific station
 * ✅ IMPROVED: Now filters by is_approved=true AND approval_status='approved'
 */
export const getApprovedRestaurantsByStation = async (
  stationId: string
): Promise<ApprovedRestaurant[]> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         stop_id,
         stops (name),
         is_approved,
         approval_status,
         is_open,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .eq('stop_id', stationId)
      .eq('is_approved', true)
      .eq('approval_status', 'approved')
      .eq('is_active', true);

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.stop_id,
      stationName: restaurant.stops?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      approvalStatus: restaurant.approval_status,
      isNearStation: true, // Validated by DB
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0, // Will be counted separately if needed
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error fetching approved restaurants:', error);
    return [];
  }
};

/**
 * Get all APPROVED restaurants (for customer view)
 */
export const getAllApprovedRestaurants = async (): Promise<ApprovedRestaurant[]> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         stop_id,
         stops (name),
         is_approved,
         approval_status,
         is_open,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .eq('is_approved', true)
      .eq('approval_status', 'approved')
      .eq('is_active', true)
      .order('rating', { ascending: false });

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.stop_id,
      stationName: restaurant.stops?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      approvalStatus: restaurant.approval_status,
      isNearStation: true,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error fetching all approved restaurants:', error);
    return [];
  }
};

/**
 * Admin view: Get ALL restaurants (including pending, rejected, suspended)
 */
export const getAllRestaurantsForAdmin = async (): Promise<ApprovedRestaurant[]> => {
  try {
    const { data: session } = await supabase.auth.getSession();

    // Check if user is admin
    if (session?.user?.user_metadata?.role !== 'admin') {
      console.warn('Access denied: Not an admin');
      return [];
    }

    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         stop_id,
         stops (name),
         is_approved,
         approval_status,
         is_open,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .order('approval_status', { ascending: false });

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.stop_id,
      stationName: restaurant.stops?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      approvalStatus: restaurant.approval_status,
      isNearStation: true,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error fetching restaurants for admin:', error);
    return [];
  }
};

/**
 * Search approved restaurants by name or cuisine
 */
export const searchApprovedRestaurants = async (
  query: string
): Promise<ApprovedRestaurant[]> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         stop_id,
         stops (name),
         is_approved,
         approval_status,
         is_open,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .eq('is_approved', true)
      .eq('approval_status', 'approved')
      .or(`name.ilike.%${query}%,cuisine.ilike.%${query}%`);

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.stop_id,
      stationName: restaurant.stops?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      approvalStatus: restaurant.approval_status,
      isNearStation: true,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error searching restaurants:', error);
    return [];
  }
};

/**
 * Filter restaurants by rating
 */
export const getRestaurantsByRating = async (
  minRating: number = 3.5
): Promise<ApprovedRestaurant[]> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         stop_id,
         stops (name),
         is_approved,
         approval_status,
         is_open,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .eq('is_approved', true)
      .eq('approval_status', 'approved')
      .gte('rating', minRating)
      .order('rating', { ascending: false });

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.stop_id,
      stationName: restaurant.stops?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      approvalStatus: restaurant.approval_status,
      isNearStation: true,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error filtering restaurants by rating:', error);
    return [];
  }
};


    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.station_id,
      stationName: restaurant.stations?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      isNearStation: restaurant.is_near_station,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error fetching all approved restaurants:', error);
    return [];
  }
};

/**
 * Get pending restaurant approvals (for admin)
 */
export const getPendingRestaurantApprovals = async () => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         station_id,
         stations (name),
         is_approved,
         created_at,
         latitude,
         longitude`
      )
      .eq('is_approved', false)
      .order('created_at', { ascending: false });

    if (error) throw error;
    return data || [];
  } catch (error) {
    console.error('Error fetching pending approvals:', error);
    return [];
  }
};

/**
 * Approve a restaurant (admin only)
 */
export const approveRestaurant = async (
  restaurantId: string
): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('restaurants')
      .update({ is_approved: true, approved_at: new Date().toISOString() })
      .eq('id', restaurantId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error approving restaurant:', error);
    return false;
  }
};

/**
 * Reject a restaurant (admin only)
 */
export const rejectRestaurant = async (
  restaurantId: string,
  reason: string
): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('restaurants')
      .update({
        is_approved: false,
        rejection_reason: reason,
        rejected_at: new Date().toISOString(),
      })
      .eq('id', restaurantId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error rejecting restaurant:', error);
    return false;
  }
};

/**
 * Deactivate a restaurant (removes from listings)
 */
export const deactivateRestaurant = async (
  restaurantId: string
): Promise<boolean> => {
  try {
    const { error } = await supabase
      .from('restaurants')
      .update({ is_active: false })
      .eq('id', restaurantId);

    if (error) throw error;
    return true;
  } catch (error) {
    console.error('Error deactivating restaurant:', error);
    return false;
  }
};

/**
 * Search approved restaurants by name or station
 */
export const searchApprovedRestaurants = async (
  query: string
): Promise<ApprovedRestaurant[]> => {
  try {
    const { data, error } = await supabase
      .from('restaurants')
      .select(
        `id,
         name,
         station_id,
         stations (name),
         is_approved,
         is_near_station,
         latitude,
         longitude,
         base_k20_fee,
         distance_fee_per_km,
         is_active,
         rating,
         total_orders`
      )
      .eq('is_approved', true)
      .eq('is_active', true)
      .or(`name.ilike.%${query}%,stations.name.ilike.%${query}%`);

    if (error) throw error;

    return (data || []).map((restaurant: any) => ({
      id: restaurant.id,
      name: restaurant.name,
      stationId: restaurant.station_id,
      stationName: restaurant.stations?.name || 'Unknown Station',
      isApproved: restaurant.is_approved,
      isNearStation: restaurant.is_near_station,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      baseK20Fee: restaurant.base_k20_fee || 20,
      distanceFeePerKm: restaurant.distance_fee_per_km || 5,
      isActive: restaurant.is_active,
      menuItems: 0,
      rating: restaurant.rating,
      totalOrders: restaurant.total_orders || 0,
    })) as ApprovedRestaurant[];
  } catch (error) {
    console.error('Error searching restaurants:', error);
    return [];
  }
};
