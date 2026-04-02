/**
 * useOrderSync Hook
 * Manages order creation, offline sync, and deduplication
 */

import { useEffect, useState, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { offlineQueue } from '@/lib/offlineQueue';

export interface Order {
  id?: string;
  offline_id?: string;
  journey_id: string;
  restaurant_id: string;
  passenger_id: string;
  stop_id: string;
  items: Array<{ name: string; qty: number; price: number }>;
  notes?: string;
  total_amount: number;
  status: 'PENDING' | 'CONFIRMED' | 'PREPARING' | 'READY' | 'PICKED_UP' | 'DELIVERED' | 'FAILED';
  offline_created?: boolean;
  created_at?: string;
}

interface UseOrderSyncReturn {
  orders: Order[];
  isLoading: boolean;
  error: string | null;
  createOrder: (order: Omit<Order, 'id' | 'created_at'>) => Promise<Order>;
  loadJourneyOrders: (journeyId: string) => Promise<void>;
  syncPendingOrders: (journeyId: string) => Promise<void>;
  pendingOrdersCount: number;
}

export function useOrderSync(passengerId: string | null, deviceId: string): UseOrderSyncReturn {
  const [orders, setOrders] = useState<Order[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pendingOrdersCount, setPendingOrdersCount] = useState(0);

  /**
   * Create order (with offline support and deduplication)
   */
  const createOrder = useCallback(
    async (orderData: Omit<Order, 'id' | 'created_at'>): Promise<Order> => {
      if (!passengerId) throw new Error('No passenger ID');

      try {
        setError(null);
        const offlineId = `order_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

        const orderWithOfflineId: Order = {
          ...orderData,
          offline_id: offlineId,
          offline_created: true,
          status: 'PENDING',
        };

        // Store locally first
        await offlineQueue.storePendingOrder(offlineId, orderWithOfflineId);
        
        // Add to local state
        setOrders((prev) => [...prev, orderWithOfflineId]);

        // Try to sync immediately if online
        if (navigator.onLine) {
          try {
            const { data, error: insertError } = await supabase
              .from('orders')
              .insert([
                {
                  ...orderData,
                  offline_id: offlineId,
                  offline_created: true,
                },
              ])
              .select()
              .single();

            if (insertError) throw insertError;

            // Mark as synced
            await offlineQueue.markOrderSynced(offlineId, data.id);

            // Update local state with server ID
            setOrders((prev) =>
              prev.map((o) =>
                o.offline_id === offlineId ? { ...o, id: data.id, offline_created: false } : o
              )
            );

            return { ...data, offline_id: offlineId };
          } catch (err) {
            console.warn('Failed to sync order immediately, will retry later:', err);
            // Queue for later sync
            await offlineQueue.enqueue(
              deviceId,
              'CREATE_ORDER',
              orderWithOfflineId,
              orderData.journey_id
            );
            return orderWithOfflineId;
          }
        } else {
          // Queue for sync when online
          await offlineQueue.enqueue(
            deviceId,
            'CREATE_ORDER',
            orderWithOfflineId,
            orderData.journey_id
          );
          return orderWithOfflineId;
        }
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to create order';
        setError(message);
        throw err;
      }
    },
    [passengerId, deviceId]
  );

  /**
   * Load all orders for a journey (online + offline)
   */
  const loadJourneyOrders = useCallback(async (journeyId: string) => {
    try {
      setIsLoading(true);
      setError(null);

      // Fetch from server
      const { data: serverOrders, error: queryError } = await supabase
        .from('orders')
        .select('*')
        .eq('journey_id', journeyId)
        .order('created_at', { ascending: false });

      if (queryError) throw queryError;

      // Fetch pending offline orders
      const pendingOrders = await offlineQueue.getPendingOrders(journeyId);

      // Merge and deduplicate
      const allOrders = [
        ...serverOrders,
        ...pendingOrders.filter(
          (po) => !serverOrders.some((so) => so.offline_id === po.offline_id)
        ),
      ];

      setOrders(allOrders);
      setPendingOrdersCount(pendingOrders.length);
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load orders';
      setError(message);
      console.error('Error loading orders:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Sync pending orders to server
   */
  const syncPendingOrders = useCallback(
    async (journeyId: string) => {
      if (!navigator.onLine) return;

      try {
        setIsLoading(true);

        // Get pending offline orders
        const pendingOrders = await offlineQueue.getPendingOrders(journeyId);

        for (const order of pendingOrders) {
          try {
            // Check if order already exists on server (by offline_id)
            const { data: existing } = await supabase
              .from('orders')
              .select('id')
              .eq('offline_id', order.offline_id)
              .single();

            if (existing) {
              // Already synced, skip
              await offlineQueue.markOrderSynced(order.offline_id, existing.id);
              continue;
            }

            // Create on server
            const { data: created, error: insertError } = await supabase
              .from('orders')
              .insert([
                {
                  ...order,
                  offline_id: order.offline_id,
                  offline_created: true,
                },
              ])
              .select()
              .single();

            if (insertError) throw insertError;

            // Mark as synced
            await offlineQueue.markOrderSynced(order.offline_id, created.id);

            // Delete from pending
            setOrders((prev) =>
              prev.map((o) =>
                o.offline_id === order.offline_id
                  ? { ...o, id: created.id, offline_created: false }
                  : o
              )
            );
          } catch (err) {
            console.error('Error syncing order:', err);
            // Continue with next order
          }
        }

        // Reload to get latest state
        await loadJourneyOrders(journeyId);
      } catch (err) {
        const message = err instanceof Error ? err.message : 'Failed to sync orders';
        setError(message);
        console.error('Error syncing pending orders:', err);
      } finally {
        setIsLoading(false);
      }
    },
    [loadJourneyOrders]
  );

  // Auto-sync when coming online
  useEffect(() => {
    const handleOnline = async () => {
      console.log('Connection restored, syncing pending orders...');
      const activeJourney = orders[0]?.journey_id;
      if (activeJourney) {
        await syncPendingOrders(activeJourney);
      }
    };

    window.addEventListener('online', handleOnline);
    return () => window.removeEventListener('online', handleOnline);
  }, [syncPendingOrders, orders]);

  return {
    orders,
    isLoading,
    error,
    createOrder,
    loadJourneyOrders,
    syncPendingOrders,
    pendingOrdersCount,
  };
}
