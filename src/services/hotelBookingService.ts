import { supabase } from '@/lib/supabase';

export interface HotelBooking {
  id: string;
  hotelId: string;
  userId: string;
  roomId: string;
  checkInDate: string;
  checkOutDate: string;
  numberOfGuests: number;
  totalPrice: number;
  status: 'pending' | 'confirmed' | 'cancelled';
  createdAt: string;
}

export interface HotelRoom {
  id: string;
  hotelId: string;
  roomNumber: string;
  roomType: 'single' | 'double' | 'suite' | 'dormitory';
  capacity: number;
  price: number;
  totalRooms: number;
  availableRooms: number;
  amenities: string[];
  images: string[];
  isActive: boolean;
  description?: string;
}

export interface Hotel {
  id: string;
  name: string;
  city: string;
  station: string;
  latitude: number;
  longitude: number;
  isApproved: boolean;
  isActive: boolean;
}

/**
 * Get all available rooms for a hotel
 */
export async function getHotelRooms(hotelId: string): Promise<HotelRoom[]> {
  try {
    const { data, error } = await supabase
      .from('hotel_rooms')
      .select('*')
      .eq('hotel_id', hotelId)
      .eq('is_active', true)
      .order('room_number');

    if (error) throw error;

    return (data || []).map((room: any) => ({
      id: room.id,
      hotelId: room.hotel_id,
      roomNumber: room.room_number,
      roomType: room.room_type,
      capacity: room.capacity,
      price: room.price,
      totalRooms: room.total_rooms,
      availableRooms: room.available_rooms,
      amenities: room.amenities || [],
      images: room.images || [],
      isActive: room.is_active,
      description: room.description,
    }));
  } catch (error) {
    console.error('Error fetching hotel rooms:', error);
    throw error;
  }
}

/**
 * Get rooms available for a specific date range
 */
export async function getAvailableRoomsForDates(
  hotelId: string,
  checkInDate: string,
  checkOutDate: string
): Promise<HotelRoom[]> {
  try {
    // Get all bookings for the hotel in the date range
    const { data: bookings, error: bookingError } = await supabase
      .from('hotel_bookings')
      .select('room_id')
      .eq('hotel_id', hotelId)
      .eq('status', 'confirmed')
      .gte('check_out_date', checkInDate)
      .lte('check_in_date', checkOutDate);

    if (bookingError) throw bookingError;

    const bookedRoomIds = (bookings || []).map((b: any) => b.room_id);

    // Get all active rooms
    const { data: rooms, error: roomError } = await supabase
      .from('hotel_rooms')
      .select('*')
      .eq('hotel_id', hotelId)
      .eq('is_active', true)
      .order('room_number');

    if (roomError) throw roomError;

    // Filter out booked rooms
    return (rooms || [])
      .filter((room: any) => !bookedRoomIds.includes(room.id))
      .map((room: any) => ({
        id: room.id,
        hotelId: room.hotel_id,
        roomNumber: room.room_number,
        roomType: room.room_type,
        capacity: room.capacity,
        price: room.price,
        totalRooms: room.total_rooms,
        availableRooms: room.available_rooms,
        amenities: room.amenities || [],
        images: room.images || [],
        isActive: room.is_active,
        description: room.description,
      }));
  } catch (error) {
    console.error('Error fetching available rooms:', error);
    throw error;
  }
}

/**
 * Get bookings for a specific hotel
 */
export async function getHotelBookings(hotelId: string): Promise<HotelBooking[]> {
  try {
    const { data, error } = await supabase
      .from('hotel_bookings')
      .select('*')
      .eq('hotel_id', hotelId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return (data || []).map((booking: any) => ({
      id: booking.id,
      hotelId: booking.hotel_id,
      userId: booking.user_id,
      roomId: booking.room_id,
      checkInDate: booking.check_in_date,
      checkOutDate: booking.check_out_date,
      numberOfGuests: booking.number_of_guests,
      totalPrice: booking.total_price,
      status: booking.status,
      createdAt: booking.created_at,
    }));
  } catch (error) {
    console.error('Error fetching hotel bookings:', error);
    throw error;
  }
}

/**
 * Create a new hotel booking
 */
export async function createHotelBooking(
  hotelId: string,
  userId: string,
  roomId: string,
  checkInDate: string,
  checkOutDate: string,
  numberOfGuests: number,
  totalPrice: number
): Promise<HotelBooking> {
  try {
    const { data, error } = await supabase
      .from('hotel_bookings')
      .insert({
        hotel_id: hotelId,
        user_id: userId,
        room_id: roomId,
        check_in_date: checkInDate,
        check_out_date: checkOutDate,
        number_of_guests: numberOfGuests,
        total_price: totalPrice,
        status: 'pending',
      })
      .select()
      .single();

    if (error) throw error;

    return {
      id: data.id,
      hotelId: data.hotel_id,
      userId: data.user_id,
      roomId: data.room_id,
      checkInDate: data.check_in_date,
      checkOutDate: data.check_out_date,
      numberOfGuests: data.number_of_guests,
      totalPrice: data.total_price,
      status: data.status,
      createdAt: data.created_at,
    };
  } catch (error) {
    console.error('Error creating hotel booking:', error);
    throw error;
  }
}

/**
 * Confirm a hotel booking
 */
export async function confirmHotelBooking(bookingId: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('hotel_bookings')
      .update({ status: 'confirmed' })
      .eq('id', bookingId);

    if (error) throw error;
  } catch (error) {
    console.error('Error confirming hotel booking:', error);
    throw error;
  }
}

/**
 * Cancel a hotel booking
 */
export async function cancelHotelBooking(bookingId: string): Promise<void> {
  try {
    const { error } = await supabase
      .from('hotel_bookings')
      .update({ status: 'cancelled' })
      .eq('id', bookingId);

    if (error) throw error;
  } catch (error) {
    console.error('Error cancelling hotel booking:', error);
    throw error;
  }
}

/**
 * Calculate nights between two dates
 */
export function calculateNights(checkIn: string, checkOut: string): number {
  const start = new Date(checkIn);
  const end = new Date(checkOut);
  const nights = Math.ceil(
    (end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)
  );
  return Math.max(nights, 1);
}

/**
 * Calculate total hotel booking price
 */
export function calculateHotelBookingPrice(
  nightly: number,
  nights: number,
  taxPercentage: number = 10
): { nightly: number; subtotal: number; tax: number; total: number } {
  const subtotal = nightly * nights;
  const tax = Math.round((subtotal * taxPercentage) / 100);
  const total = subtotal + tax;

  return { nightly, subtotal, tax, total };
}

/**
 * Update room availability
 */
export async function updateRoomAvailability(
  roomId: string,
  availableRooms: number
): Promise<void> {
  try {
    const { error } = await supabase
      .from('hotel_rooms')
      .update({ available_rooms: availableRooms })
      .eq('id', roomId);

    if (error) throw error;
  } catch (error) {
    console.error('Error updating room availability:', error);
    throw error;
  }
}

/**
 * Toggle room active status (fully booked or available)
 */
export async function toggleRoomActive(
  roomId: string,
  isActive: boolean
): Promise<void> {
  try {
    const { error } = await supabase
      .from('hotel_rooms')
      .update({ is_active: isActive })
      .eq('id', roomId);

    if (error) throw error;
  } catch (error) {
    console.error('Error toggling room active status:', error);
    throw error;
  }
}

/**
 * Get hotels available in a city with approved status
 */
export async function getHotelsByCity(city: string): Promise<Hotel[]> {
  try {
    const { data, error } = await supabase
      .from('hotels')
      .select('*')
      .eq('city', city)
      .eq('is_approved', true)
      .eq('is_active', true)
      .order('name');

    if (error) throw error;

    return (data || []).map((hotel: any) => ({
      id: hotel.id,
      name: hotel.name,
      city: hotel.city,
      station: hotel.station,
      latitude: hotel.latitude,
      longitude: hotel.longitude,
      isApproved: hotel.is_approved,
      isActive: hotel.is_active,
    }));
  } catch (error) {
    console.error('Error fetching hotels by city:', error);
    throw error;
  }
}
