 import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
 import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
 
 const corsHeaders = {
   "Access-Control-Allow-Origin": "*",
   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
 };
 
 interface ETARequest {
   journey_id: string;
 }
 
 // Calculate distance between two points in km
 function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
   const R = 6371;
   const dLat = ((lat2 - lat1) * Math.PI) / 180;
   const dLon = ((lon2 - lon1) * Math.PI) / 180;
   const a =
     Math.sin(dLat / 2) * Math.sin(dLat / 2) +
     Math.cos((lat1 * Math.PI) / 180) *
       Math.cos((lat2 * Math.PI) / 180) *
       Math.sin(dLon / 2) *
       Math.sin(dLon / 2);
   const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
   return R * c;
 }
 
 serve(async (req) => {
   if (req.method === "OPTIONS") {
     return new Response(null, { headers: corsHeaders });
   }
 
   try {
     const supabaseAdmin = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
     );
 
     const { journey_id }: ETARequest = await req.json();
 
     // Get journey with bus and route info
     const { data: journey, error: journeyError } = await supabaseAdmin
       .from("journeys")
       .select(`
         *,
         buses!inner(current_position, speed, last_gps_update),
         routes!inner(total_distance, estimated_duration)
       `)
       .eq("id", journey_id)
       .single();
 
     if (journeyError || !journey) {
       throw new Error("Journey not found");
     }
 
     // Get all stops for this route in order
     const { data: routeStops, error: stopsError } = await supabaseAdmin
       .from("route_stops")
       .select(`
         *,
         stops!inner(*)
       `)
       .eq("route_id", journey.route_id)
       .order("sequence_order", { ascending: true });
 
     if (stopsError || !routeStops) {
       throw new Error("Route stops not found");
     }
 
     // Get historical performance data
     const now = new Date();
     const dayOfWeek = now.getDay();
     const hourOfDay = now.getHours();
 
     const { data: historicalData } = await supabaseAdmin
       .from("route_performance_history")
       .select("*")
       .eq("route_id", journey.route_id)
       .eq("day_of_week", dayOfWeek)
       .eq("hour_of_day", hourOfDay);
 
     // Parse current bus position
     let busLat = 0, busLng = 0;
     if (journey.buses?.current_position) {
       const match = journey.buses.current_position.match(/POINT\(([-\d.]+) ([-\d.]+)\)/);
       if (match) {
         busLng = parseFloat(match[1]);
         busLat = parseFloat(match[2]);
       }
     }
 
     const currentSpeed = journey.buses?.speed || 60; // Default 60 km/h
     const baseTime = journey.departure_time ? new Date(journey.departure_time) : now;
     
     const etaUpdates: Array<{
       journey_id: string;
       stop_id: string;
       predicted_arrival: string;
       confidence: number;
       is_delayed: boolean;
       delay_minutes: number;
     }> = [];
 
     let accumulatedTime = 0;
 
     for (const routeStop of routeStops) {
       // Parse stop coordinates
       const stopMatch = routeStop.stops?.coordinates?.match(/POINT\(([-\d.]+) ([-\d.]+)\)/);
       if (!stopMatch) continue;
 
       const stopLng = parseFloat(stopMatch[1]);
       const stopLat = parseFloat(stopMatch[2]);
 
       // Calculate distance from bus to this stop
       const distanceToStop = calculateDistance(busLat, busLng, stopLat, stopLng);
 
       // Estimate time to stop based on speed and distance
       const timeToStopHours = distanceToStop / currentSpeed;
       const timeToStopMinutes = timeToStopHours * 60;
 
       // Apply historical adjustments if available
       let adjustedTime = timeToStopMinutes;
       const historicalMatch = historicalData?.find(
         (h) => h.from_stop_id === journey.current_stop_id && h.to_stop_id === routeStop.stop_id
       );
       if (historicalMatch) {
         const historicalFactor = historicalMatch.average_duration / (routeStop.estimated_time_from_start || 1);
         adjustedTime *= historicalFactor;
       }
 
       accumulatedTime = Math.max(accumulatedTime, adjustedTime);
 
       const predictedArrival = new Date(now.getTime() + accumulatedTime * 60 * 1000);
       
       // Calculate expected arrival based on schedule
       const expectedArrival = new Date(
         baseTime.getTime() + (routeStop.estimated_time_from_start || 0) * 60 * 1000
       );
       
       const delayMinutes = Math.round((predictedArrival.getTime() - expectedArrival.getTime()) / 60000);
       const isDelayed = delayMinutes > 5;
 
       // Confidence based on distance and data freshness
       const lastUpdate = journey.buses?.last_gps_update
         ? new Date(journey.buses.last_gps_update)
         : null;
       const dataAge = lastUpdate ? (now.getTime() - lastUpdate.getTime()) / 60000 : 999;
       const confidence = Math.max(0.3, Math.min(0.95, 1 - dataAge / 30));
 
       etaUpdates.push({
         journey_id,
         stop_id: routeStop.stop_id,
         predicted_arrival: predictedArrival.toISOString(),
         confidence,
         is_delayed: isDelayed,
         delay_minutes: Math.max(0, delayMinutes),
       });
     }
 
     // Upsert all ETA predictions
     for (const eta of etaUpdates) {
       await supabaseAdmin.from("journey_etas").upsert(eta, {
         onConflict: "journey_id,stop_id",
       });
     }
 
     // Update journey delay status
     const maxDelay = Math.max(...etaUpdates.map((e) => e.delay_minutes));
     await supabaseAdmin
       .from("journeys")
       .update({
         delay_minutes: maxDelay,
         status: maxDelay > 15 ? "delayed" : journey.status === "delayed" ? "active" : journey.status,
       })
       .eq("id", journey_id);
 
     return new Response(
       JSON.stringify({
         success: true,
         etas: etaUpdates,
         delay_minutes: maxDelay,
       }),
       { headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   } catch (error) {
     console.error("ETA calculation error:", error);
     return new Response(
       JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
       { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   }
 });