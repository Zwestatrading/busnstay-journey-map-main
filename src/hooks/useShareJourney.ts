 import { useState, useCallback } from 'react';
 import { supabase } from '@/integrations/supabase/client';
 import { DBSharedJourneyLink } from '@/types/database';
 import { useToast } from '@/hooks/use-toast';
 
 interface SharePermissions {
   view_location: boolean;
   view_eta: boolean;
   view_stops: boolean;
   view_orders: boolean;
 }
 
 interface CreateShareParams {
   journey_passenger_id: string;
   viewer_name?: string;
   permissions?: SharePermissions;
   expires_in_hours?: number;
 }
 
 interface SharedJourneyData {
   journey: {
     id: string;
     status: string;
     progress: number;
     departure_time: string;
     estimated_arrival: string;
     delay_minutes: number;
   };
   bus: {
     current_position: { type: string; coordinates: [number, number] } | null;
     heading: number;
     speed: number;
     last_update: string;
   } | null;
   stops: Array<{
     id: string;
     name: string;
     eta: string;
     is_delayed: boolean;
   }> | null;
 }
 
 export const useShareJourney = () => {
   const { toast } = useToast();
   const [isLoading, setIsLoading] = useState(false);
   const [error, setError] = useState<string | null>(null);
 
   const createShareLink = useCallback(async (params: CreateShareParams): Promise<{
     share_code: string;
     share_url: string;
     expires_at: string;
   } | null> => {
     setIsLoading(true);
     setError(null);
 
     try {
       const { data: { session } } = await supabase.auth.getSession();
       if (!session) {
         throw new Error('Please sign in to share your journey');
       }
 
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/share-journey`,
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
         throw new Error(errorData.error || 'Failed to create share link');
       }
 
       const data = await response.json();
       
       toast({
         title: 'Share Link Created! 🔗',
         description: 'Copy the link to share your journey',
       });
 
       return {
         share_code: data.share_code,
         share_url: data.share_url,
         expires_at: data.expires_at,
       };
     } catch (err) {
       const message = err instanceof Error ? err.message : 'Failed to create share link';
       setError(message);
       toast({
         title: 'Share Failed',
         description: message,
         variant: 'destructive',
       });
       return null;
     } finally {
       setIsLoading(false);
     }
   }, [toast]);
 
   const getSharedJourney = useCallback(async (shareCode: string): Promise<SharedJourneyData | null> => {
     setIsLoading(true);
     setError(null);
 
     try {
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/share-journey`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY}`,
           },
           body: JSON.stringify({
             action: 'get',
             share_code: shareCode,
           }),
         }
       );
 
       if (!response.ok) {
         const errorData = await response.json();
         throw new Error(errorData.error || 'Failed to fetch shared journey');
       }
 
       const result = await response.json();
       return result.data;
     } catch (err) {
       const message = err instanceof Error ? err.message : 'Failed to fetch shared journey';
       setError(message);
       return null;
     } finally {
       setIsLoading(false);
     }
   }, []);
 
   const revokeShareLink = useCallback(async (shareId: string): Promise<boolean> => {
     try {
       const { data: { session } } = await supabase.auth.getSession();
       if (!session) {
         throw new Error('Not authenticated');
       }
 
       const response = await fetch(
         `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/share-journey`,
         {
           method: 'POST',
           headers: {
             'Content-Type': 'application/json',
             'Authorization': `Bearer ${session.access_token}`,
           },
           body: JSON.stringify({
             action: 'revoke',
             share_id: shareId,
           }),
         }
       );
 
       if (!response.ok) {
         throw new Error('Failed to revoke share link');
       }
 
       toast({
         title: 'Share Link Revoked',
         description: 'The share link is no longer valid',
       });
 
       return true;
     } catch (err) {
       console.error('Revoke share error:', err);
       return false;
     }
   }, [toast]);
 
   const getUserShareLinks = useCallback(async (): Promise<DBSharedJourneyLink[]> => {
     try {
       const { data: { user } } = await supabase.auth.getUser();
       if (!user) return [];
 
       const { data, error: fetchError } = await supabase
         .from('shared_journey_links')
         .select('*')
         .eq('created_by_user_id', user.id)
         .eq('is_active', true)
         .order('created_at', { ascending: false });
 
       if (fetchError) throw fetchError;
 
       return (data || []) as unknown as DBSharedJourneyLink[];
     } catch (err) {
       console.error('Fetch share links error:', err);
       return [];
     }
   }, []);
 
   return {
     createShareLink,
     getSharedJourney,
     revokeShareLink,
     getUserShareLinks,
     isLoading,
     error,
   };
 };
 
 export default useShareJourney;