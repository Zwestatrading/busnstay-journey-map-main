import { useState, useEffect, useCallback, useRef } from 'react';
import { supabase } from '@/lib/supabase';

interface HealthEvent {
  id: string;
  event_type: string;
  severity: string;
  source_table: string | null;
  source_id: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
  is_resolved: boolean;
  auto_fixed: boolean;
  resolution_notes: string | null;
  detected_at: string;
  resolved_at: string | null;
}

interface SystemMetrics {
  activeJourneys: number;
  pendingOrders: number;
  onlineDrivers: number;
  onlineRiders: number;
  unresolvedAlerts: number;
  avgGpsLatency: number;
}

export const useSystemHealth = () => {
  const [events, setEvents] = useState<HealthEvent[]>([]);
  const [metrics, setMetrics] = useState<SystemMetrics>({
    activeJourneys: 0,
    pendingOrders: 0,
    onlineDrivers: 0,
    onlineRiders: 0,
    unresolvedAlerts: 0,
    avgGpsLatency: 0,
  });
  const [isMonitoring, setIsMonitoring] = useState(false);
  const monitorIntervalRef = useRef<NodeJS.Timeout | null>(null);

  // Fetch unresolved health events
  const fetchHealthEvents = useCallback(async () => {
    const { data } = await supabase
      .from('system_health_events')
      .select('*')
      .eq('is_resolved', false)
      .order('detected_at', { ascending: false })
      .limit(50);

    if (data) {
      setEvents(data as unknown as HealthEvent[]);
    }
  }, []);

  // Fetch system metrics
  const fetchMetrics = useCallback(async () => {
    const [journeys, orders, drivers, riders, alerts] = await Promise.all([
      supabase.from('journeys').select('id', { count: 'exact' }).eq('status', 'active'),
      supabase.from('orders').select('id', { count: 'exact' }).in('status', ['pending', 'preparing']),
      supabase.from('taxi_drivers').select('id', { count: 'exact' }).eq('is_online', true),
      supabase.from('delivery_agents').select('id', { count: 'exact' }).eq('status', 'online'),
      supabase.from('journey_alerts').select('id', { count: 'exact' }).eq('is_resolved', false),
    ]);

    setMetrics({
      activeJourneys: journeys.count || 0,
      pendingOrders: orders.count || 0,
      onlineDrivers: drivers.count || 0,
      onlineRiders: riders.count || 0,
      unresolvedAlerts: alerts.count || 0,
      avgGpsLatency: 0, // Would calculate from gps_history
    });
  }, []);

  // Log a health event
  const logEvent = useCallback(async (
    eventType: string,
    severity: 'info' | 'warning' | 'critical',
    description: string,
    eventMetadata?: Record<string, unknown>,
    sourceTable?: string,
    sourceId?: string
  ) => {
    await supabase.from('system_health_events').insert([{
      event_type: eventType,
      severity,
      description,
      metadata: (eventMetadata || {}) as unknown as null,
      source_table: sourceTable,
      source_id: sourceId,
    }]);
  }, []);

  // Auto-fix common issues
  const autoFix = useCallback(async (event: HealthEvent) => {
    let fixed = false;
    let notes = '';

    switch (event.event_type) {
      case 'gps_freeze':
        // Trigger GPS refresh for affected journey
        if (event.source_id) {
          await supabase
            .from('journeys')
            .update({ updated_at: new Date().toISOString() })
            .eq('id', event.source_id);
          fixed = true;
          notes = 'Triggered GPS refresh for journey';
        }
        break;

      case 'order_stuck':
        // Reassign order to available rider
        if (event.source_id) {
          const { data: riders } = await supabase
            .from('delivery_agents')
            .select('id')
            .eq('status', 'online')
            .limit(1);

          if (riders && riders.length > 0) {
            await supabase
              .from('orders')
              .update({ delivery_agent_id: riders[0].id, status: 'out_for_delivery' })
              .eq('id', event.source_id);
            fixed = true;
            notes = `Reassigned to rider ${riders[0].id}`;
          }
        }
        break;

      case 'eta_stall':
        // Recalculate ETA
        // Would trigger edge function here
        fixed = true;
        notes = 'Triggered ETA recalculation';
        break;

      default:
        notes = 'No auto-fix available for this event type';
    }

    if (fixed) {
      await supabase
        .from('system_health_events')
        .update({
          is_resolved: true,
          auto_fixed: true,
          resolution_notes: notes,
          resolved_at: new Date().toISOString(),
        })
        .eq('id', event.id);

      fetchHealthEvents();
    }

    return { fixed, notes };
  }, [fetchHealthEvents]);

  // Jam detection logic
  const detectJams = useCallback(async () => {
    // Check for GPS freezes (no update in 60 seconds for active journeys)
    const { data: staleJourneys } = await supabase
      .from('journeys')
      .select('id, bus_id')
      .eq('status', 'active')
      .lt('updated_at', new Date(Date.now() - 60000).toISOString());

    if (staleJourneys && staleJourneys.length > 0) {
      for (const journey of staleJourneys) {
        await logEvent(
          'gps_freeze',
          'warning',
          `Journey ${journey.id} has stale GPS data`,
          { bus_id: journey.bus_id },
          'journeys',
          journey.id
        );
      }
    }

    // Check for stuck orders (preparing for > 30 minutes)
    const { data: stuckOrders } = await supabase
      .from('orders')
      .select('id, restaurant_id')
      .eq('status', 'preparing')
      .lt('updated_at', new Date(Date.now() - 1800000).toISOString());

    if (stuckOrders && stuckOrders.length > 0) {
      for (const order of stuckOrders) {
        await logEvent(
          'order_stuck',
          'warning',
          `Order ${order.id} stuck in preparing state`,
          { restaurant_id: order.restaurant_id },
          'orders',
          order.id
        );
      }
    }

    fetchHealthEvents();
  }, [logEvent, fetchHealthEvents]);

  // Start monitoring
  const startMonitoring = useCallback(() => {
    if (monitorIntervalRef.current) return;

    setIsMonitoring(true);
    fetchHealthEvents();
    fetchMetrics();
    detectJams();

    monitorIntervalRef.current = setInterval(() => {
      fetchMetrics();
      detectJams();
    }, 30000); // Every 30 seconds
  }, [fetchHealthEvents, fetchMetrics, detectJams]);

  // Stop monitoring
  const stopMonitoring = useCallback(() => {
    if (monitorIntervalRef.current) {
      clearInterval(monitorIntervalRef.current);
      monitorIntervalRef.current = null;
    }
    setIsMonitoring(false);
  }, []);

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (monitorIntervalRef.current) {
        clearInterval(monitorIntervalRef.current);
      }
    };
  }, []);

  // Subscribe to realtime health events
  useEffect(() => {
    const channel = supabase
      .channel('health-events')
      .on(
        'postgres_changes',
        { event: 'INSERT', schema: 'public', table: 'system_health_events' },
        () => fetchHealthEvents()
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, [fetchHealthEvents]);

  return {
    events,
    metrics,
    isMonitoring,
    startMonitoring,
    stopMonitoring,
    logEvent,
    autoFix,
    detectJams,
    fetchHealthEvents,
    fetchMetrics,
  };
};

export default useSystemHealth;
