 import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
 import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
 
 const corsHeaders = {
   "Access-Control-Allow-Origin": "*",
   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
 };
 
 interface GPSUpdatePayload {
   journey_id: string;
   source_type: "bus" | "passenger" | "agent";
   source_id: string;
   position: { lat: number; lng: number };
   accuracy?: number;
   heading?: number;
   speed?: number;
 }
 
 serve(async (req) => {
   if (req.method === "OPTIONS") {
     return new Response(null, { headers: corsHeaders });
   }
 
   try {
     const authHeader = req.headers.get("Authorization");
     if (!authHeader?.startsWith("Bearer ")) {
       return new Response(JSON.stringify({ error: "Unauthorized" }), {
         status: 401,
         headers: { ...corsHeaders, "Content-Type": "application/json" },
       });
     }
 
     const supabase = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_ANON_KEY")!,
       { global: { headers: { Authorization: authHeader } } }
     );
 
     const token = authHeader.replace("Bearer ", "");
     const { data: claims, error: claimsError } = await supabase.auth.getClaims(token);
     if (claimsError || !claims?.claims) {
       return new Response(JSON.stringify({ error: "Invalid token" }), {
         status: 401,
         headers: { ...corsHeaders, "Content-Type": "application/json" },
       });
     }
 
     const userId = claims.claims.sub;
     const payload: GPSUpdatePayload = await req.json();
 
     // Insert GPS history record
     const { error: insertError } = await supabase.from("gps_history").insert({
       journey_id: payload.journey_id,
       source_type: payload.source_type,
       source_id: payload.source_id,
       position: `POINT(${payload.position.lng} ${payload.position.lat})`,
       accuracy: payload.accuracy,
       heading: payload.heading,
       speed: payload.speed,
       recorded_at: new Date().toISOString(),
     });
 
     if (insertError) {
       console.error("GPS insert error:", insertError);
       throw insertError;
     }
 
     // Update passenger position if source is passenger
     if (payload.source_type === "passenger") {
       await supabase
         .from("journey_passengers")
         .update({
           current_position: `POINT(${payload.position.lng} ${payload.position.lat})`,
           last_gps_update: new Date().toISOString(),
         })
         .eq("journey_id", payload.journey_id)
         .eq("user_id", userId);
     }
 
     // Aggregate bus position from all passengers (if bus GPS unavailable)
     if (payload.source_type === "passenger") {
       // Get recent passenger positions for this journey
       const { data: recentPositions } = await supabase
         .from("gps_history")
         .select("position, accuracy, recorded_at")
         .eq("journey_id", payload.journey_id)
         .eq("source_type", "passenger")
         .gte("recorded_at", new Date(Date.now() - 60000).toISOString())
         .order("recorded_at", { ascending: false })
         .limit(10);
 
       if (recentPositions && recentPositions.length > 0) {
         // Calculate weighted average position
         // For now, use the most recent passenger position
         const latestPosition = recentPositions[0];
         
         // Get the journey's bus_id
         const { data: journey } = await supabase
           .from("journeys")
           .select("bus_id")
           .eq("id", payload.journey_id)
           .single();
 
         if (journey) {
           // Update bus position with aggregated passenger data
           await supabase
             .from("buses")
             .update({
               current_position: latestPosition.position,
               heading: payload.heading,
               speed: payload.speed,
               last_gps_update: new Date().toISOString(),
             })
             .eq("id", journey.bus_id);
         }
       }
     }
 
     // Update bus directly if source is bus
     if (payload.source_type === "bus") {
       await supabase
         .from("buses")
         .update({
           current_position: `POINT(${payload.position.lng} ${payload.position.lat})`,
           heading: payload.heading,
           speed: payload.speed,
           last_gps_update: new Date().toISOString(),
         })
         .eq("id", payload.source_id);
     }
 
     return new Response(
       JSON.stringify({ success: true, timestamp: new Date().toISOString() }),
       { headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   } catch (error) {
     console.error("GPS update error:", error);
     return new Response(
       JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
       { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   }
 });