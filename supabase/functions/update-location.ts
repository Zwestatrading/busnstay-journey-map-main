/**
 * Supabase Edge Function: Update Journey Location
 * Called when passenger GPS location changes
 * Updates journey status, calculates town proximity, handles town closure
 */

import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL") || "",
  Deno.env.get("SUPABASE_ANON_KEY") || ""
);

interface LocationUpdate {
  journey_id: string;
  latitude: number;
  longitude: number;
  accuracy: number;
}

// Haversine distance calculation (km)
function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371; // Earth's radius in km
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

async function handleLocationUpdate(req: Request): Promise<Response> {
  try {
    // Verify auth
    const authHeader = req.headers.get("Authorization") || "";
    const token = authHeader.replace("Bearer ", "");

    if (!token) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { data: session, error: authError } = await supabase.auth.getUser(token);

    if (authError || !session.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body: LocationUpdate = await req.json();
    const { journey_id, latitude, longitude, accuracy } = body;

    if (!journey_id || latitude === undefined || longitude === undefined) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Fetch active journey
    const { data: journey, error: journeyError } = await supabase
      .from("journeys")
      .select("*")
      .eq("id", journey_id)
      .eq("status", "ACTIVE")
      .single();

    if (journeyError || !journey) {
      return new Response(JSON.stringify({ error: "Journey not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    // Update journey location
    const { error: updateError } = await supabase
      .from("journeys")
      .update({
        current_latitude: latitude,
        current_longitude: longitude,
        current_accuracy: accuracy,
        last_location_update: new Date().toISOString(),
      })
      .eq("id", journey_id);

    if (updateError) throw updateError;

    // Store location history
    const { error: historyError } = await supabase
      .from("location_history")
      .insert({
        journey_id,
        latitude,
        longitude,
        accuracy,
        source: "GPS",
      });

    if (historyError) console.error("Error storing location history:", historyError);

    // Check town proximity and handle closures
    const { data: towns, error: townsError } = await supabase
      .from("towns_on_route")
      .select("*")
      .eq("journey_id", journey_id)
      .in("status", ["OPEN", "CLOSING_SOON"]);

    if (!townsError && towns && towns.length > 0) {
      for (const town of towns) {
        const distance = calculateDistance(latitude, longitude, town.latitude, town.longitude);
        const distanceKm = distance;

        // Calculate time to arrival (assuming 100 km/h average)
        const estimatedMinutes = Math.round((distanceKm / 100) * 60);

        // Check if should close
        const shouldClose =
          distanceKm <= town.close_at_distance_km || estimatedMinutes <= town.close_at_minutes_remaining;

        if (shouldClose && town.status === "OPEN") {
          // Transition from OPEN → CLOSING_SOON
          await supabase
            .from("towns_on_route")
            .update({
              status: "CLOSING_SOON",
              closing_soon_at: new Date().toISOString(),
              distance_to_arrival: distanceKm,
              minutes_to_arrival: estimatedMinutes,
            })
            .eq("id", town.id);
        }

        if (distanceKm <= 0.5 && town.status === "CLOSING_SOON") {
          // Transition from CLOSING_SOON → CLOSED → LOCKED
          const now = new Date().toISOString();
          await supabase
            .from("towns_on_route")
            .update({
              status: "LOCKED",
              closed_at: now,
              locked_at: now,
            })
            .eq("id", town.id);

          // Notify restaurants that ordering is closed
          const { data: orders } = await supabase
            .from("orders")
            .select("restaurant_id")
            .eq("journey_id", journey_id)
            .eq("stop_id", town.id)
            .neq("status", "DELIVERED");

          if (orders) {
            const restaurantIds = [...new Set(orders.map((o) => o.restaurant_id))];

            for (const restaurantId of restaurantIds) {
              // Create notification
              await supabase
                .from("restaurant_notifications")
                .insert({
                  restaurant_id: restaurantId,
                  journey_id,
                  notification_type: "TOWN_LOCKED",
                  title: "Last Orders Accepted",
                  message: `Your town (${town.town_name}) is now locked for new orders. Existing orders continue.`,
                });
            }
          }
        }

        // Update distance/eta for this town
        if (town.status !== "LOCKED") {
          await supabase
            .from("towns_on_route")
            .update({
              distance_to_arrival: distanceKm,
              minutes_to_arrival: estimatedMinutes,
            })
            .eq("id", town.id);
        }
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        distance_updated: true,
      }),
      {
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error in location update:", error);
    return new Response(
      JSON.stringify({
        error: error instanceof Error ? error.message : "Internal server error",
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }
    );
  }
}

serve(handleLocationUpdate);
