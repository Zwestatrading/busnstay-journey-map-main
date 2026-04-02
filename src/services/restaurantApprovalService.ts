import { supabase } from '@/lib/supabase';

type ApprovalStatus = 'pending' | 'approved' | 'rejected' | 'suspended';

interface ApprovalLog {
  id: string;
  restaurant_id: string;
  action: string;
  admin_id: string;
  reason?: string;
  created_at: string;
}

export const getPendingRestaurants = async () => {
  const { data, error } = await supabase
    .from('restaurants')
    .select('*')
    .eq('approval_status', 'pending')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const getRestaurantsByStatus = async (status: ApprovalStatus) => {
  const { data, error } = await supabase
    .from('restaurants')
    .select('*')
    .eq('approval_status', status)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const approveRestaurant = async (
  restaurantId: string,
  reason?: string
): Promise<{ success: boolean; error?: string }> => {
  const { data: session } = await supabase.auth.getSession();
  const adminId = session?.session?.user?.id;

  const { error } = await supabase
    .from('restaurants')
    .update({
      approval_status: 'approved',
      is_approved: true,
      approval_date: new Date().toISOString(),
      approved_by_admin_id: adminId,
    })
    .eq('id', restaurantId);

  if (error) return { success: false, error: error.message };

  if (adminId) {
    await supabase.from('restaurant_approval_logs').insert({
      restaurant_id: restaurantId,
      action: 'approved',
      admin_id: adminId,
      reason: reason || 'Approved by admin',
    });
  }

  return { success: true };
};

export const rejectRestaurant = async (
  restaurantId: string,
  reason: string
): Promise<{ success: boolean; error?: string }> => {
  const { data: session } = await supabase.auth.getSession();
  const adminId = session?.session?.user?.id;

  const { error } = await supabase
    .from('restaurants')
    .update({
      approval_status: 'rejected',
      is_approved: false,
    })
    .eq('id', restaurantId);

  if (error) return { success: false, error: error.message };

  if (adminId) {
    await supabase.from('restaurant_approval_logs').insert({
      restaurant_id: restaurantId,
      action: 'rejected',
      admin_id: adminId,
      reason,
    });
  }

  return { success: true };
};

export const suspendRestaurant = async (
  restaurantId: string,
  reason: string
): Promise<{ success: boolean; error?: string }> => {
  const { data: session } = await supabase.auth.getSession();
  const adminId = session?.session?.user?.id;

  const { error } = await supabase
    .from('restaurants')
    .update({
      approval_status: 'suspended',
      is_approved: false,
    })
    .eq('id', restaurantId);

  if (error) return { success: false, error: error.message };

  if (adminId) {
    await supabase.from('restaurant_approval_logs').insert({
      restaurant_id: restaurantId,
      action: 'suspended',
      admin_id: adminId,
      reason,
    });
  }

  return { success: true };
};

export const getApprovalLogs = async (restaurantId: string): Promise<ApprovalLog[]> => {
  const { data, error } = await supabase
    .from('restaurant_approval_logs')
    .select('*')
    .eq('restaurant_id', restaurantId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return (data || []) as ApprovalLog[];
};

export const getAllRestaurantsForAdmin = async () => {
  const { data, error } = await supabase
    .from('restaurants')
    .select('*')
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const searchApprovedRestaurants = async (query: string) => {
  const { data, error } = await supabase
    .from('restaurants')
    .select('*')
    .eq('is_approved', true)
    .eq('approval_status', 'approved')
    .ilike('name', `%${query}%`)
    .order('name');

  if (error) throw error;
  return data || [];
};
