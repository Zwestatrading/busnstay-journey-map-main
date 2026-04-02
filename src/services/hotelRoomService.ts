import { supabase } from '@/lib/supabase';

export interface HotelRoom {
  id: string;
  accommodation_id: string;
  room_number: string;
  room_type: 'single' | 'double' | 'twin' | 'suite' | 'family' | 'dormitory';
  capacity: number;
  price_per_night: number;
  base_price: number;
  discount_percentage: number;
  description?: string;
  amenities: string[];
  images: Array<{ url: string; caption?: string }>;
  is_available: boolean;
  is_active: boolean;
  occupancy_status: 'available' | 'occupied' | 'maintenance' | 'reserved';
  last_cleaning?: string;
  next_available_date?: string;
  total_bookings: number;
  average_rating: number;
  created_at: string;
  updated_at: string;
}

export interface RoomAvailability {
  date: string;
  status: 'available' | 'booked' | 'blocked' | 'maintenance';
  price_per_night?: number;
  notes?: string;
}

export const getHotelRooms = async (accommodationId: string): Promise<HotelRoom[]> => {
  const { data, error } = await supabase
    .from('hotel_rooms')
    .select('*')
    .eq('accommodation_id', accommodationId)
    .order('room_number', { ascending: true });

  if (error) throw error;
  return (data || []) as HotelRoom[];
};

export const getAvailableRoomsForDateRange = async (
  accommodationId: string,
  checkIn: string,
  checkOut: string
): Promise<HotelRoom[]> => {
  const { data, error } = await supabase
    .from('hotel_rooms')
    .select('*')
    .eq('accommodation_id', accommodationId)
    .eq('is_active', true)
    .eq('is_available', true)
    .order('price_per_night', { ascending: true });

  if (error) throw error;
  return (data || []) as HotelRoom[];
};

export const createHotelRoom = async (
  room: Partial<HotelRoom> & { accommodation_id: string; room_number: string; room_type: string; price_per_night: number }
): Promise<HotelRoom> => {
  const { data, error } = await supabase
    .from('hotel_rooms')
    .insert({
      accommodation_id: room.accommodation_id,
      room_number: room.room_number,
      room_type: room.room_type,
      capacity: room.capacity || 2,
      price_per_night: room.price_per_night,
      base_price: room.base_price || room.price_per_night,
      description: room.description || '',
      amenities: room.amenities || [],
      images: room.images || [],
      is_active: room.is_active !== false,
      is_available: true,
      occupancy_status: 'available',
    })
    .select()
    .single();

  if (error) throw error;
  return data as HotelRoom;
};

export const updateHotelRoom = async (
  roomId: string,
  updates: Partial<HotelRoom>
): Promise<void> => {
  const { error } = await supabase
    .from('hotel_rooms')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', roomId);

  if (error) throw error;
};

export const toggleRoomActiveStatus = async (
  roomId: string,
  isActive: boolean
): Promise<void> => {
  const { error } = await supabase
    .from('hotel_rooms')
    .update({ is_active: isActive, updated_at: new Date().toISOString() })
    .eq('id', roomId);

  if (error) throw error;
};

export const updateRoomOccupancy = async (
  roomId: string,
  status: HotelRoom['occupancy_status']
): Promise<void> => {
  const update: Record<string, unknown> = {
    occupancy_status: status,
    is_available: status === 'available',
    updated_at: new Date().toISOString(),
  };

  if (status === 'available') {
    update.last_cleaning = new Date().toISOString();
  }

  const { error } = await supabase.from('hotel_rooms').update(update).eq('id', roomId);
  if (error) throw error;
};

export const addRoomImages = async (
  roomId: string,
  newImages: Array<{ url: string; caption?: string }>
): Promise<void> => {
  const { data: room, error: fetchError } = await supabase
    .from('hotel_rooms')
    .select('images')
    .eq('id', roomId)
    .single();

  if (fetchError) throw fetchError;

  const existing = (room?.images as Array<{ url: string; caption?: string }>) || [];
  const { error } = await supabase
    .from('hotel_rooms')
    .update({ images: [...existing, ...newImages] })
    .eq('id', roomId);

  if (error) throw error;
};

export const blockRoomDates = async (
  roomId: string,
  dates: { start: string; end: string; reason: string }
): Promise<void> => {
  const { error } = await supabase
    .from('room_availability')
    .insert({
      room_id: roomId,
      date: dates.start,
      status: 'blocked',
      notes: dates.reason,
    });

  if (error) throw error;
};

export const getRoomBookingCalendar = async (
  roomId: string,
  month: string
): Promise<RoomAvailability[]> => {
  const startDate = `${month}-01`;
  const endDate = `${month}-31`;

  const { data, error } = await supabase
    .from('room_availability')
    .select('*')
    .eq('room_id', roomId)
    .gte('date', startDate)
    .lte('date', endDate)
    .order('date');

  if (error) throw error;
  return (data || []) as RoomAvailability[];
};

export const getRoomReviews = async (roomId: string) => {
  const { data, error } = await supabase
    .from('room_reviews')
    .select('*')
    .eq('room_id', roomId)
    .order('created_at', { ascending: false });

  if (error) throw error;
  return data || [];
};

export const addRoomReview = async (
  roomId: string,
  review: { rating: number; comment: string; guest_name: string }
): Promise<void> => {
  const { data: session } = await supabase.auth.getSession();
  const userId = session?.session?.user?.id;

  const { error } = await supabase
    .from('room_reviews')
    .insert({
      room_id: roomId,
      user_id: userId,
      rating: review.rating,
      comment: review.comment,
      guest_name: review.guest_name,
    });

  if (error) throw error;
};

export const getRoomRateHistory = async (
  roomId: string,
  limit: number = 30
) => {
  const { data, error } = await supabase
    .from('room_rate_history')
    .select('*')
    .eq('room_id', roomId)
    .order('effective_date', { ascending: false })
    .limit(limit);

  if (error) throw error;
  return data || [];
};

export const deleteHotelRoom = async (roomId: string): Promise<{ success: boolean; error?: string }> => {
  const { error } = await supabase.from('hotel_rooms').delete().eq('id', roomId);
  if (error) return { success: false, error: error.message };
  return { success: true };
};

export const getRoomRevenue = async (
  roomId: string,
  period: 'week' | 'month' | 'year' = 'month'
): Promise<{ totalRevenue: number; bookingCount: number }> => {
  const now = new Date();
  let startDate: Date;

  switch (period) {
    case 'week':
      startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
      break;
    case 'year':
      startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate());
      break;
    default:
      startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
  }

  const { data: bookings, error: bookingsError } = await supabase
    .from('bookings')
    .select('total_price')
    .eq('room_id', roomId)
    .eq('status', 'confirmed')
    .gte('created_at', startDate.toISOString());

  if (bookingsError) throw bookingsError;

  const totalRevenue = (bookings || []).reduce((sum, b) => sum + (b.total_price || 0), 0);
  return { totalRevenue, bookingCount: (bookings || []).length };
};
