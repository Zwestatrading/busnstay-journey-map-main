/**
 * Revenue Tracking Service for BusNStay Platform
 * Tracks platform fees, accommodation revenue, and payment analytics
 */

import { supabase } from '@/lib/supabase';

const PLATFORM_FEE_RATE = 0.10; // 10%

export interface RevenueAnalytics {
  totalRevenue: number;
  platformFees: number;
  netPayouts: number;
  transactionCount: number;
  averageTransactionValue: number;
  byPaymentMethod: Record<string, { count: number; total: number }>;
  dailyRevenue: Array<{ date: string; revenue: number; count: number }>;
}

export interface AccommodationRevenue {
  accommodationId: string;
  accommodationName: string;
  totalRevenue: number;
  bookingCount: number;
  averageBookingValue: number;
  occupancyRate: number;
}

export const getRevenueAnalytics = async (
  period: 'day' | 'week' | 'month' | 'year' = 'month'
): Promise<RevenueAnalytics> => {
  const now = new Date();
  let startDate: Date;

  switch (period) {
    case 'day': startDate = new Date(now.getTime() - 24 * 60 * 60 * 1000); break;
    case 'week': startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000); break;
    case 'year': startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate()); break;
    default: startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
  }

  const { data: analyticsData, error } = await supabase
    .from('payment_transactions')
    .select('*')
    .eq('status', 'completed')
    .gte('created_at', startDate.toISOString());

  if (error) throw error;

  const transactions = analyticsData || [];

  const byPaymentMethod: Record<string, { count: number; total: number }> = {};
  const dailyMap: Record<string, { revenue: number; count: number }> = {};

  transactions.forEach(tx => {
    // By method
    const method = tx.payment_method || 'unknown';
    if (!byPaymentMethod[method]) byPaymentMethod[method] = { count: 0, total: 0 };
    byPaymentMethod[method].count++;
    byPaymentMethod[method].total += tx.amount;

    // By day
    const day = tx.created_at.substring(0, 10);
    if (!dailyMap[day]) dailyMap[day] = { revenue: 0, count: 0 };
    dailyMap[day].revenue += tx.amount;
    dailyMap[day].count++;
  });

  const totalRevenue = transactions.reduce((sum, t) => sum + t.amount, 0);
  const platformFees = transactions.reduce((sum, t) => sum + (t.platform_fee || t.amount * PLATFORM_FEE_RATE), 0);

  return {
    totalRevenue,
    platformFees,
    netPayouts: totalRevenue - platformFees,
    transactionCount: transactions.length,
    averageTransactionValue: transactions.length > 0 ? totalRevenue / transactions.length : 0,
    byPaymentMethod,
    dailyRevenue: Object.entries(dailyMap)
      .map(([date, data]) => ({ date, ...data }))
      .sort((a, b) => a.date.localeCompare(b.date)),
  };
};

export const getPaymentSuccessMetrics = async (): Promise<{
  total: number;
  completed: number;
  failed: number;
  pending: number;
  successRate: number;
}> => {
  const { data, error } = await supabase
    .from('payment_transactions')
    .select('status');

  if (error) throw error;

  const transactions = data || [];
  const completed = transactions.filter(t => t.status === 'completed').length;
  const failed = transactions.filter(t => t.status === 'failed').length;
  const pending = transactions.filter(t => t.status === 'pending' || t.status === 'processing').length;

  return {
    total: transactions.length,
    completed,
    failed,
    pending,
    successRate: transactions.length > 0 ? (completed / transactions.length) * 100 : 0,
  };
};

export const getAccommodationRevenueMetrics = async (
  accommodationId: string,
  period: 'week' | 'month' | 'year' = 'month'
): Promise<AccommodationRevenue> => {
  const now = new Date();
  let startDate: Date;

  switch (period) {
    case 'week': startDate = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000); break;
    case 'year': startDate = new Date(now.getFullYear() - 1, now.getMonth(), now.getDate()); break;
    default: startDate = new Date(now.getFullYear(), now.getMonth() - 1, now.getDate());
  }

  const { data: accommodation, error: acError } = await supabase
    .from('accommodations')
    .select('name')
    .eq('id', accommodationId)
    .single();

  if (acError) throw acError;

  const { data: bookings, error: bookError } = await supabase
    .from('bookings')
    .select('total_price, status')
    .eq('accommodation_id', accommodationId)
    .eq('status', 'confirmed')
    .gte('created_at', startDate.toISOString());

  if (bookError) throw bookError;

  const confirmedBookings = bookings || [];
  const totalRevenue = confirmedBookings.reduce((sum, b) => sum + (b.total_price || 0), 0);

  // Calculate occupancy
  const { data: rooms } = await supabase
    .from('hotel_rooms')
    .select('id, occupancy_status')
    .eq('accommodation_id', accommodationId)
    .eq('is_active', true);

  const totalRooms = (rooms || []).length;
  const occupiedRooms = (rooms || []).filter(r => r.occupancy_status === 'occupied').length;

  return {
    accommodationId,
    accommodationName: accommodation?.name || 'Unknown',
    totalRevenue,
    bookingCount: confirmedBookings.length,
    averageBookingValue: confirmedBookings.length > 0 ? totalRevenue / confirmedBookings.length : 0,
    occupancyRate: totalRooms > 0 ? (occupiedRooms / totalRooms) * 100 : 0,
  };
};

export const getTopAccommodations = async (
  limit: number = 10
): Promise<AccommodationRevenue[]> => {
  const { data: accommodations, error } = await supabase
    .from('accommodations')
    .select('id, name')
    .limit(limit);

  if (error) throw error;

  const results: AccommodationRevenue[] = [];
  for (const acc of (accommodations || [])) {
    try {
      const metrics = await getAccommodationRevenueMetrics(acc.id);
      results.push(metrics);
    } catch {
      results.push({
        accommodationId: acc.id,
        accommodationName: acc.name,
        totalRevenue: 0,
        bookingCount: 0,
        averageBookingValue: 0,
        occupancyRate: 0,
      });
    }
  }

  return results.sort((a, b) => b.totalRevenue - a.totalRevenue);
};

export const exportRevenueReport = async (
  period: 'week' | 'month' | 'year' = 'month'
): Promise<string> => {
  const analytics = await getRevenueAnalytics(period);

  let csv = 'Date,Revenue (ZMW),Transactions\n';
  analytics.dailyRevenue.forEach(day => {
    csv += `${day.date},${day.revenue.toFixed(2)},${day.count}\n`;
  });
  csv += `\nTotal,${analytics.totalRevenue.toFixed(2)},${analytics.transactionCount}\n`;
  csv += `Platform Fees,${analytics.platformFees.toFixed(2)},\n`;
  csv += `Net Payouts,${analytics.netPayouts.toFixed(2)},\n`;

  return csv;
};

export const getAdminDashboardRevenue = async (): Promise<{
  today: number;
  thisWeek: number;
  thisMonth: number;
  thisYear: number;
}> => {
  const [day, week, month, year] = await Promise.all([
    getRevenueAnalytics('day'),
    getRevenueAnalytics('week'),
    getRevenueAnalytics('month'),
    getRevenueAnalytics('year'),
  ]);

  return {
    today: day.totalRevenue,
    thisWeek: week.totalRevenue,
    thisMonth: month.totalRevenue,
    thisYear: year.totalRevenue,
  };
};

export const calculateAccommodationPayout = (
  grossRevenue: number
): { gross: number; platformFee: number; net: number; feeRate: number } => {
  const platformFee = grossRevenue * PLATFORM_FEE_RATE;
  return {
    gross: grossRevenue,
    platformFee,
    net: grossRevenue - platformFee,
    feeRate: PLATFORM_FEE_RATE * 100,
  };
};
