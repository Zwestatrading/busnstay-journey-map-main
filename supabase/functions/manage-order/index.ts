 import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
 import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
 
 const corsHeaders = {
   "Access-Control-Allow-Origin": "*",
   "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
 };
 
 interface OrderItem {
   menu_item_id: string;
   name: string;
   quantity: number;
   price: number;
 }
 
 interface CreateOrderPayload {
   action: "create";
   journey_id?: string;
   journey_passenger_id?: string;
   restaurant_id: string;
   stop_id: string;
   items: OrderItem[];
   delivery_type: "pickup" | "bus_delivery";
   special_instructions?: string;
 }
 
 interface UpdateOrderPayload {
   action: "update_status";
   order_id: string;
   status: "confirmed" | "preparing" | "ready" | "out_for_delivery" | "delivered" | "cancelled";
 }
 
 interface AssignAgentPayload {
   action: "assign_agent";
   order_id: string;
   agent_id: string;
 }
 
 type OrderPayload = CreateOrderPayload | UpdateOrderPayload | AssignAgentPayload;
 
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
 
     const supabaseAdmin = createClient(
       Deno.env.get("SUPABASE_URL")!,
       Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
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
     const payload: OrderPayload = await req.json();
 
     if (payload.action === "create") {
       const { items, restaurant_id, stop_id, delivery_type, special_instructions, journey_id, journey_passenger_id } = payload;
 
       // Calculate totals
       const subtotal = items.reduce((sum, item) => sum + item.price * item.quantity, 0);
       const deliveryFee = delivery_type === "bus_delivery" ? 10 : 0;
       const total = subtotal + deliveryFee;
 
       // Get restaurant prep time to estimate ready time
       const { data: restaurant } = await supabaseAdmin
         .from("restaurants")
         .select("average_prep_time, name")
         .eq("id", restaurant_id)
         .single();
 
       const prepTime = restaurant?.average_prep_time || 15;
       const estimatedReadyTime = new Date(Date.now() + prepTime * 60 * 1000);
 
       // Create order
       const { data: order, error: orderError } = await supabase
         .from("orders")
         .insert({
           user_id: userId,
           journey_id,
           journey_passenger_id,
           restaurant_id,
           stop_id,
           items: items,
           subtotal,
           delivery_fee: deliveryFee,
           total,
           status: "pending",
           delivery_type,
           special_instructions,
           estimated_ready_time: estimatedReadyTime.toISOString(),
         })
         .select()
         .single();
 
       if (orderError) {
         console.error("Order creation error:", orderError);
         throw orderError;
       }
 
       // Auto-confirm order (in production, this would go through restaurant confirmation)
       await supabaseAdmin
         .from("orders")
         .update({ status: "confirmed" })
         .eq("id", order.id);
 
       return new Response(
         JSON.stringify({
           success: true,
           order: { ...order, status: "confirmed" },
           restaurant_name: restaurant?.name,
           estimated_ready_time: estimatedReadyTime.toISOString(),
         }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     if (payload.action === "update_status") {
       const { order_id, status } = payload;
 
       const updateData: Record<string, unknown> = { status };
       if (status === "ready") {
         updateData.actual_ready_time = new Date().toISOString();
       }
 
       const { data: order, error: updateError } = await supabaseAdmin
         .from("orders")
         .update(updateData)
         .eq("id", order_id)
         .select()
         .single();
 
       if (updateError) {
         throw updateError;
       }
 
       // Create alert if order is ready
       if (status === "ready" && order.journey_id) {
         await supabaseAdmin.from("journey_alerts").insert({
           journey_id: order.journey_id,
           alert_type: "delivery_issue",
           severity: "info",
           title: "Order Ready!",
           message: `Your order is ready for pickup at the station.`,
           affected_stop_id: order.stop_id,
         });
       }
 
       return new Response(
         JSON.stringify({ success: true, order }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     if (payload.action === "assign_agent") {
       const { order_id, agent_id } = payload;
 
       // Update order with agent
       const { data: order, error: orderError } = await supabaseAdmin
         .from("orders")
         .update({
           delivery_agent_id: agent_id,
           status: "out_for_delivery",
         })
         .eq("id", order_id)
         .select()
         .single();
 
       if (orderError) {
         throw orderError;
       }
 
       // Update agent status
       await supabaseAdmin
         .from("delivery_agents")
         .update({ status: "on_delivery" })
         .eq("id", agent_id);
 
       return new Response(
         JSON.stringify({ success: true, order }),
         { headers: { ...corsHeaders, "Content-Type": "application/json" } }
       );
     }
 
     throw new Error("Invalid action");
   } catch (error) {
     console.error("Order management error:", error);
     return new Response(
       JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
       { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
     );
   }
 });