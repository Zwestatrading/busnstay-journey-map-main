 import { useState, useCallback } from 'react';
 import { supabase } from '@/integrations/supabase/client';
 import { DBOrder } from '@/types/database';
 import { useToast } from '@/hooks/use-toast';
 
 interface OrderItem {
   menu_item_id: string;
   name: string;
   quantity: number;
   price: number;
 }
 
 interface CreateOrderParams {
   journey_id?: string;
   journey_passenger_id?: string;
   restaurant_id: string;
   stop_id: string;
   items: OrderItem[];
   delivery_type: 'pickup' | 'bus_delivery';
   special_instructions?: string;
 }
 
 export const useOrderManagement = () => {
   const { toast } = useToast();
   const [isLoading, setIsLoading] = useState(false);
   const [error, setError] = useState<string | null>(null);
 
   const createOrder = useCallback(async (params: CreateOrderParams): Promise<DBOrder | null> => {
     setIsLoading(true);
     setError(null);
 
     try {
       const { data: { session } } = await supabase.auth.getSession();
       if (!session) {
         throw new Error('Please sign in to place an order');
       }
 
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-order`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${session.access_token}`,
           },
           body: JSON.stringify({
             action: 'create',
             ...params,
           }),
         }
       );
 
       if (!response.ok) {
         const errorData = await response.json();
         throw new Error(errorData.error || 'Failed to create order');
       }
 
       const data = await response.json();
       
       toast({
         title: 'Order Placed! 🍽️',
         description: `Your order from ${data.restaurant_name} is confirmed`,
       });
 
       return data.order;
     } catch (err) {
       const message = err instanceof Error ? err.message : 'Failed to create order';
       setError(message);
       toast({
         title: 'Order Failed',
         description: message,
         variant: 'destructive',
       });
       return null;
     } finally {
       setIsLoading(false);
     }
   }, [toast]);
 
   const updateOrderStatus = useCallback(async (
     orderId: string,
     status: DBOrder['status']
   ): Promise<boolean> => {
     try {
       const { data: { session } } = await supabase.auth.getSession();
       if (!session) {
         throw new Error('Not authenticated');
       }
 
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/manage-order`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${session.access_token}`,
           },
           body: JSON.stringify({
             action: 'update_status',
             order_id: orderId,
             status,
           }),
         }
       );
 
       if (!response.ok) {
         throw new Error('Failed to update order status');
       }
 
       return true;
     } catch (err) {
       console.error('Update order status error:', err);
       return false;
     }
   }, []);
 
   const getUserOrders = useCallback(async (): Promise<DBOrder[]> => {
     try {
       const { data: { user } } = await supabase.auth.getUser();
       if (!user) return [];
 
       const { data, error: fetchError } = await supabase
         .from('orders')
         .select('*')
         .eq('user_id', user.id)
         .order('created_at', { ascending: false });
 
       if (fetchError) throw fetchError;
 
       return (data || []) as unknown as DBOrder[];
     } catch (err) {
       console.error('Fetch orders error:', err);
       return [];
     }
   }, []);
 
   return {
     createOrder,
     updateOrderStatus,
     getUserOrders,
     isLoading,
     error,
   };
 };
 
 export default useOrderManagement;