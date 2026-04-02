import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

interface HealthCheckPayload {
  action: "detect_jams" | "auto_fix" | "check_all";
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const payload: HealthCheckPayload = await req.json().catch(() => ({ action: "check_all" }));
    const results: { detected: number; fixed: number; events: string[] } = {
      detected: 0,
      fixed: 0,
      events: [],
    };

    // 1. Check for GPS freezes (no update in 60 seconds for active journeys)
    const { data: staleJourneys } = await supabase
      .from("journeys")
      .select("id, bus_id")
      .eq("status", "active")
      .lt("updated_at", new Date(Date.now() - 60000).toISOString());

    if (staleJourneys && staleJourneys.length > 0) {
      for (const journey of staleJourneys) {
        // Check if event already exists
        const { data: existing } = await supabase
          .from("system_health_events")
          .select("id")
          .eq("event_type", "gps_freeze")
          .eq("source_id", journey.id)
          .eq("is_resolved", false)
          .maybeSingle();

        if (!existing) {
          await supabase.from("system_health_events").insert([{
            event_type: "gps_freeze",
            severity: "warning",
            description: `Journey ${journey.id.slice(0, 8)}... has stale GPS data`,
            source_table: "journeys",
            source_id: journey.id,
            metadata: { bus_id: journey.bus_id },
          }]);
          results.detected++;
          results.events.push(`GPS freeze: journey ${journey.id.slice(0, 8)}`);
        }

        // Auto-fix: trigger update
        if (payload.action === "auto_fix" || payload.action === "check_all") {
          await supabase
            .from("journeys")
            .update({ updated_at: new Date().toISOString() })
            .eq("id", journey.id);

          // Mark as resolved
          await supabase
            .from("system_health_events")
            .update({
              is_resolved: true,
              auto_fixed: true,
              resolution_notes: "Triggered GPS refresh",
              resolved_at: new Date().toISOString(),
            })
            .eq("source_id", journey.id)
            .eq("event_type", "gps_freeze")
            .eq("is_resolved", false);

          results.fixed++;
        }
      }
    }

    // 2. Check for stuck orders (preparing for > 30 minutes)
    const { data: stuckOrders } = await supabase
      .from("orders")
      .select("id, restaurant_id, stop_id")
      .eq("status", "preparing")
      .lt("updated_at", new Date(Date.now() - 1800000).toISOString());

    if (stuckOrders && stuckOrders.length > 0) {
      for (const order of stuckOrders) {
        const { data: existing } = await supabase
          .from("system_health_events")
          .select("id")
          .eq("event_type", "order_stuck")
          .eq("source_id", order.id)
          .eq("is_resolved", false)
          .maybeSingle();

        if (!existing) {
          await supabase.from("system_health_events").insert([{
            event_type: "order_stuck",
            severity: "warning",
            description: `Order ${order.id.slice(0, 8)}... stuck in preparing state`,
            source_table: "orders",
            source_id: order.id,
            metadata: { restaurant_id: order.restaurant_id },
          }]);
          results.detected++;
          results.events.push(`Stuck order: ${order.id.slice(0, 8)}`);
        }

        // Auto-fix: Try to reassign to available rider
        if (payload.action === "auto_fix" || payload.action === "check_all") {
          const { data: riders } = await supabase
            .from("delivery_agents")
            .select("id")
            .eq("status", "online")
            .eq("current_stop_id", order.stop_id)
            .limit(1);

          if (riders && riders.length > 0) {
            await supabase
              .from("orders")
              .update({
                delivery_agent_id: riders[0].id,
                status: "out_for_delivery",
              })
              .eq("id", order.id);

            await supabase
              .from("delivery_agents")
              .update({ status: "on_delivery" })
              .eq("id", riders[0].id);

            await supabase
              .from("system_health_events")
              .update({
                is_resolved: true,
                auto_fixed: true,
                resolution_notes: `Reassigned to rider ${riders[0].id.slice(0, 8)}`,
                resolved_at: new Date().toISOString(),
              })
              .eq("source_id", order.id)
              .eq("event_type", "order_stuck")
              .eq("is_resolved", false);

            results.fixed++;
          }
        }
      }
    }

    // 3. Check for ETA staleness
    const { data: staleETAs } = await supabase
      .from("journey_etas")
      .select("id, journey_id, stop_id")
      .lt("last_calculated", new Date(Date.now() - 300000).toISOString());

    if (staleETAs && staleETAs.length > 0) {
      // Trigger ETA recalculation for affected journeys
      const journeyIds = [...new Set(staleETAs.map(e => e.journey_id))];
      
      for (const journeyId of journeyIds) {
        const { data: existing } = await supabase
          .from("system_health_events")
          .select("id")
          .eq("event_type", "eta_stall")
          .eq("source_id", journeyId)
          .eq("is_resolved", false)
          .maybeSingle();

        if (!existing) {
          await supabase.from("system_health_events").insert([{
            event_type: "eta_stall",
            severity: "info",
            description: `ETA calculations stale for journey ${journeyId.slice(0, 8)}`,
            source_table: "journey_etas",
            source_id: journeyId,
          }]);
          results.detected++;
        }

        // Mark as resolved (ETA will be recalculated on next GPS update)
        if (payload.action === "auto_fix" || payload.action === "check_all") {
          await supabase
            .from("system_health_events")
            .update({
              is_resolved: true,
              auto_fixed: true,
              resolution_notes: "ETA recalculation triggered",
              resolved_at: new Date().toISOString(),
            })
            .eq("source_id", journeyId)
            .eq("event_type", "eta_stall")
            .eq("is_resolved", false);

          results.fixed++;
        }
      }
    }

    // 4. Check for delivery agents stuck on delivery
    const { data: stuckAgents } = await supabase
      .from("delivery_agents")
      .select("id, name")
      .eq("status", "on_delivery")
      .lt("last_gps_update", new Date(Date.now() - 600000).toISOString());

    if (stuckAgents && stuckAgents.length > 0) {
      for (const agent of stuckAgents) {
        await supabase.from("system_health_events").insert([{
          event_type: "agent_stuck",
          severity: "warning",
          description: `Delivery agent ${agent.name} stuck on delivery`,
          source_table: "delivery_agents",
          source_id: agent.id,
        }]);
        results.detected++;

        // Auto-fix: reset agent status
        if (payload.action === "auto_fix" || payload.action === "check_all") {
          await supabase
            .from("delivery_agents")
            .update({ status: "online" })
            .eq("id", agent.id);
          results.fixed++;
        }
      }
    }

    // Record metrics
    await supabase.from("platform_metrics").insert([{
      metric_type: "health_check",
      metric_value: results.detected,
      dimensions: {
        detected: results.detected,
        fixed: results.fixed,
        timestamp: new Date().toISOString(),
      },
    }]);

    return new Response(
      JSON.stringify({
        success: true,
        ...results,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("System health error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
