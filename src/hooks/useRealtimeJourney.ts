 import { useState, useEffect, useCallback, useRef } from 'react';
 import { supabase } from '@/integrations/supabase/client';
 import {
   DBBus,
   DBJourney,
   DBJourneyETA,
   DBOrder,
   DBJourneyAlert,
   DBDeliveryAgent,
   parsePostGISPoint
 } from '@/types/database';
 import { useToast } from '@/hooks/use-toast';
 
 interface RealtimeJourneyState {
   journey: DBJourney | null;
   bus: DBBus | null;
   busPosition: [number, number] | null;
   etas: DBJourneyETA[];
   orders: DBOrder[];
   alerts: DBJourneyAlert[];
   deliveryAgents: DBDeliveryAgent[];
   isConnected: boolean;
   error: string | null;
 }
 
 interface UseRealtimeJourneyOptions {
   journeyId: string | null;
   enabled?: boolean;
 }
 
 export const useRealtimeJourney = ({ journeyId, enabled = true }: UseRealtimeJourneyOptions) => {
   const { toast } = useToast();
   const [state, setState] = useState<RealtimeJourneyState>({
     journey: null,
     bus: null,
     busPosition: null,
     etas: [],
     orders: [],
     alerts: [],
     deliveryAgents: [],
     isConnected: false,
     error: null,
   });
 
   const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
 
   // Fetch initial data
   const fetchInitialData = useCallback(async () => {
     if (!journeyId) return;
 
     try {
       // Fetch journey and bus data
       const { data: journey, error: journeyError } = await supabase
         .from('journeys')
         .select('*')
         .eq('id', journeyId)
         .maybeSingle();
 
       if (journeyError) throw journeyError;
       if (!journey) return;
 
       // Fetch bus data
       const { data: bus } = await supabase
         .from('buses')
         .select('*')
         .eq('id', journey.bus_id)
         .maybeSingle();
 
       // Fetch ETAs
       const { data: etas } = await supabase
         .from('journey_etas')
         .select('*')
         .eq('journey_id', journeyId);
 
       // Fetch alerts
       const { data: alerts } = await supabase
         .from('journey_alerts')
         .select('*')
         .eq('journey_id', journeyId)
         .eq('is_resolved', false);
 
       setState(prev => ({
         ...prev,
         journey: journey as unknown as DBJourney,
         bus: bus as unknown as DBBus,
         busPosition: bus ? parsePostGISPoint(bus.current_position as string) : null,
         etas: (etas || []) as unknown as DBJourneyETA[],
         alerts: (alerts || []) as unknown as DBJourneyAlert[],
         error: null,
       }));
     } catch (error) {
       console.error('Error fetching journey data:', error);
       setState(prev => ({
         ...prev,
         error: error instanceof Error ? error.message : 'Failed to fetch journey data',
       }));
     }
   }, [journeyId]);
 
   // Fetch user orders
   const fetchOrders = useCallback(async () => {
     const { data: { user } } = await supabase.auth.getUser();
     if (!user) return;
 
     const { data: orders } = await supabase
       .from('orders')
       .select('*')
       .eq('user_id', user.id)
       .neq('status', 'delivered')
       .neq('status', 'cancelled');
 
     setState(prev => ({
       ...prev,
       orders: (orders || []) as unknown as DBOrder[],
     }));
   }, []);
 
   // Set up real-time subscriptions
   useEffect(() => {
     if (!enabled || !journeyId) return;
 
     fetchInitialData();
     fetchOrders();
 
     // Create realtime channel
     const channel = supabase
       .channel(`journey-${journeyId}`)
       // Subscribe to bus position updates
       .on(
         'postgres_changes',
         {
           event: 'UPDATE',
           schema: 'public',
           table: 'buses',
         },
         (payload) => {
           const updatedBus = payload.new as unknown as DBBus;
           if (state.journey?.bus_id === updatedBus.id) {
             setState(prev => ({
               ...prev,
               bus: updatedBus,
               busPosition: parsePostGISPoint(updatedBus.current_position),
             }));
           }
         }
       )
       // Subscribe to journey updates
       .on(
         'postgres_changes',
         {
           event: 'UPDATE',
           schema: 'public',
           table: 'journeys',
           filter: `id=eq.${journeyId}`,
         },
         (payload) => {
           const updatedJourney = payload.new as unknown as DBJourney;
           setState(prev => ({
             ...prev,
             journey: updatedJourney,
           }));
 
           // Show toast for status changes
           if (updatedJourney.status === 'delayed') {
             toast({
               title: 'Journey Delayed ⏰',
               description: `Delay of ${updatedJourney.delay_minutes} minutes`,
               variant: 'destructive',
             });
           }
         }
       )
       // Subscribe to ETA updates
       .on(
         'postgres_changes',
         {
           event: '*',
           schema: 'public',
           table: 'journey_etas',
           filter: `journey_id=eq.${journeyId}`,
         },
         (payload) => {
           if (payload.eventType === 'INSERT' || payload.eventType === 'UPDATE') {
             const updatedETA = payload.new as unknown as DBJourneyETA;
             setState(prev => ({
               ...prev,
               etas: prev.etas.map(e => 
                 e.stop_id === updatedETA.stop_id ? updatedETA : e
               ).concat(prev.etas.some(e => e.stop_id === updatedETA.stop_id) ? [] : [updatedETA]),
             }));
           }
         }
       )
       // Subscribe to alerts
       .on(
         'postgres_changes',
         {
           event: 'INSERT',
           schema: 'public',
           table: 'journey_alerts',
           filter: `journey_id=eq.${journeyId}`,
         },
         (payload) => {
           const newAlert = payload.new as unknown as DBJourneyAlert;
           setState(prev => ({
             ...prev,
             alerts: [...prev.alerts, newAlert],
           }));
 
           // Show toast for alerts
           toast({
             title: newAlert.title,
             description: newAlert.message,
             variant: newAlert.severity === 'critical' ? 'destructive' : 'default',
           });
         }
       )
       // Subscribe to order updates
       .on(
         'postgres_changes',
         {
           event: '*',
           schema: 'public',
           table: 'orders',
         },
         (payload) => {
           if (payload.eventType === 'UPDATE') {
             const updatedOrder = payload.new as unknown as DBOrder;
             setState(prev => ({
               ...prev,
               orders: prev.orders.map(o => 
                 o.id === updatedOrder.id ? updatedOrder : o
               ),
             }));
 
             // Show toast for order status changes
             if (updatedOrder.status === 'ready') {
               toast({
                 title: 'Order Ready! 🍽️',
                 description: 'Your order is ready for pickup',
               });
             }
           }
         }
       )
       .subscribe((status) => {
         setState(prev => ({
           ...prev,
           isConnected: status === 'SUBSCRIBED',
         }));
       });
 
     channelRef.current = channel;
 
     return () => {
       channel.unsubscribe();
     };
   }, [enabled, journeyId, fetchInitialData, fetchOrders, toast, state.journey?.bus_id]);
 
   // Send GPS update to backend
   const sendGPSUpdate = useCallback(async (
     position: { lat: number; lng: number },
     accuracy?: number,
     heading?: number,
     speed?: number
   ) => {
     if (!journeyId) return;
 
     const { data: { session } } = await supabase.auth.getSession();
     if (!session) return;
 
     try {
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/gps-update`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${session.access_token}`,
           },
           body: JSON.stringify({
             journey_id: journeyId,
             source_type: 'passenger',
             source_id: session.user.id,
             position,
             accuracy,
             heading,
             speed,
           }),
         }
       );
 
       if (!response.ok) {
         throw new Error('Failed to send GPS update');
       }
     } catch (error) {
       console.error('GPS update error:', error);
     }
   }, [journeyId]);
 
   // Request ETA recalculation
   const refreshETAs = useCallback(async () => {
     if (!journeyId) return;
 
     try {
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/calculate-eta`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY}`,
           },
           body: JSON.stringify({ journey_id: journeyId }),
         }
       );
 
       if (!response.ok) {
         throw new Error('Failed to refresh ETAs');
       }
 
       const data = await response.json();
       setState(prev => ({
         ...prev,
         etas: data.etas || prev.etas,
       }));
     } catch (error) {
       console.error('ETA refresh error:', error);
     }
   }, [journeyId]);
 
   return {
     ...state,
     sendGPSUpdate,
     refreshETAs,
     refetch: fetchInitialData,
   };
 };
 
 export default useRealtimeJourney;