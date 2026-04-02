 import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
 import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
 
 const corsHeaders = {
   "Access-Control-Allow-Origin": "*",
   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
 };
 
 interface CreateSharePayload {
   action: "create";
   journey_passenger_id: string;
   viewer_name?: string;
   permissions?: {
     view_location: boolean;
     view_eta: boolean;
     view_stops: boolean;
     view_orders: boolean;
   };
   expires_in_hours?: number;
 }
 
 interface GetSharePayload {
   action: "get";
   share_code: string;
 }
 
 interface RevokeSharePayload {
   action: "revoke";
   share_id: string;
 }
 
 type SharePayload = CreateSharePayload | GetSharePayload | RevokeSharePayload;
 
 // Generate unique share code
 function generateShareCode(): string {
   const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
   let result = "";
   for (let i = 0; i < 8; i++) {
     result += chars.charAt(Math.floor(Math.random() * chars.length));
   }
   return result;
 }
 
 serve(async (req) => {
   if (req.method === "OPTIONS") {
     return new Response(null, { headers: corsHeaders });
   }
 
   try {
     const payload: SharePayload = await req.json();
 
     // For viewing shared journeys, no auth required
     if (payload.action === "get") {
       const supabaseAdmin = createClient(
         Deno.env.get("SUPABASE_URL")!,
         Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
       );
 
       // Use the database function to get shared journey data
       const { data, error } = await supabaseAdmin.rpc("get_shared_journey", {
         share_code_param: payload.share_code,
       });
 
       if (error) {
         throw error;
       }
 
       if (data?.error) {
         return new Response(
           JSON.stringify({ error: data.error }),
           { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
         );
       }
 
       return new Response(
         JSON.stringify({ success: true, data }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     // For creating/revoking shares, auth required
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
 
     if (payload.action === "create") {
       const {
         journey_passenger_id,
         viewer_name,
         permissions = { view_location: true, view_eta: true, view_stops: true, view_orders: false },
         expires_in_hours = 24,
       } = payload;
 
       // Generate unique share code
       let shareCode = generateShareCode();
       let attempts = 0;
       while (attempts < 10) {
         const { data: existing } = await supabase
           .from("shared_journey_links")
           .select("id")
           .eq("share_code", shareCode)
           .maybeSingle();
 
         if (!existing) break;
         shareCode = generateShareCode();
         attempts++;
       }
 
       const expiresAt = new Date(Date.now() + expires_in_hours * 60 * 60 * 1000);
 
       const { data: shareLink, error: createError } = await supabase
         .from("shared_journey_links")
         .insert({
           journey_passenger_id,
           share_code: shareCode,
           created_by_user_id: userId,
           viewer_name,
           permissions,
           expires_at: expiresAt.toISOString(),
           is_active: true,
         })
         .select()
         .single();
 
       if (createError) {
         console.error("Share creation error:", createError);
         throw createError;
       }
 
       // Generate shareable URL
       const baseUrl = Deno.env.get("SUPABASE_URL")?.replace("/rest/v1", "") || "";
       const shareUrl = `${baseUrl}/share/${shareCode}`;
 
       return new Response(
         JSON.stringify({
           success: true,
           share_code: shareCode,
           share_url: shareUrl,
           expires_at: expiresAt.toISOString(),
           share_link: shareLink,
         }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     if (payload.action === "revoke") {
       const { share_id } = payload;
 
       const { error: deleteError } = await supabase
         .from("shared_journey_links")
         .update({ is_active: false })
         .eq("id", share_id)
         .eq("created_by_user_id", userId);
 
       if (deleteError) {
         throw deleteError;
       }
 
       return new Response(
         JSON.stringify({ success: true }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     throw new Error("Invalid action");
   } catch (error) {
     console.error("Share journey error:", error);
     return new Response(
       JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
       { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   }
 });