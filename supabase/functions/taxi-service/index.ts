import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-supabase-client-platform, x-supabase-client-platform-version, x-supabase-client-runtime, x-supabase-client-runtime-version",
};

interface CreateRidePayload {
  action: "create";
  station_id: string;
  pickup_address: string;
  dropoff_address: string;
  ride_type: "to_accommodation" | "to_home" | "custom";
  accommodation_id?: string;
  pickup_location?: { lat: number; lng: number };
  dropoff_location?: { lat: number; lng: number };
}

interface UpdateRidePayload {
  action: "update_status";
  ride_id: string;
  status: "accepted" | "in_progress" | "completed" | "cancelled";
  fare_actual?: number;
}

interface AssignDriverPayload {
  action: "assign_driver";
  ride_id: string;
  driver_id: string;
}

type TaxiPayload = CreateRidePayload | UpdateRidePayload | AssignDriverPayload;

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

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: TaxiPayload = await req.json();

    if (payload.action === "create") {
      const {
        station_id,
        pickup_address,
        dropoff_address,
        ride_type,
        accommodation_id,
        pickup_location,
        dropoff_location,
      } = payload;

      // Calculate fare estimate (simplified)
      let fareEstimate = 50; // Base fare
      if (pickup_location && dropoff_location) {
        const R = 6371;
        const dLat = (dropoff_location.lat - pickup_location.lat) * Math.PI / 180;
        const dLon = (dropoff_location.lng - pickup_location.lng) * Math.PI / 180;
        const a = Math.sin(dLat / 2) ** 2 +
          Math.cos(pickup_location.lat * Math.PI / 180) *
          Math.cos(dropoff_location.lat * Math.PI / 180) *
          Math.sin(dLon / 2) ** 2;
        const distance = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        fareEstimate = Math.max(50, Math.round(distance * 10)); // K10 per km
      }

      // Create ride request
      const { data: ride, error: rideError } = await supabase
        .from("taxi_rides")
        .insert({
          passenger_user_id: user.id,
          station_id,
          pickup_address,
          dropoff_address,
          ride_type,
          accommodation_id,
          pickup_location: pickup_location ? `POINT(${pickup_location.lng} ${pickup_location.lat})` : null,
          dropoff_location: dropoff_location ? `POINT(${dropoff_location.lng} ${dropoff_location.lat})` : null,
          fare_estimate: fareEstimate,
          status: "pending",
        })
        .select()
        .single();

      if (rideError) throw rideError;

      // Find available drivers at station
      const { data: drivers } = await supabaseAdmin
        .from("taxi_drivers")
        .select("id, user_id, vehicle_type, rating")
        .eq("station_id", station_id)
        .eq("is_online", true)
        .eq("is_on_trip", false)
        .order("rating", { ascending: false })
        .limit(5);

      return new Response(
        JSON.stringify({
          success: true,
          ride,
          fare_estimate: fareEstimate,
          available_drivers: drivers?.length || 0,
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payload.action === "update_status") {
      const { ride_id, status, fare_actual } = payload;

      const updateData: Record<string, unknown> = { status };

      if (status === "in_progress") {
        updateData.started_at = new Date().toISOString();
      }

      if (status === "completed") {
        updateData.completed_at = new Date().toISOString();
        if (fare_actual) updateData.fare_actual = fare_actual;

        // Update driver stats
        const { data: ride } = await supabaseAdmin
          .from("taxi_rides")
          .select("driver_id, fare_estimate")
          .eq("id", ride_id)
          .single();

        if (ride?.driver_id) {
          await supabaseAdmin.rpc("increment", {
            table_name: "taxi_drivers",
            column_name: "total_trips",
            row_id: ride.driver_id,
          }).catch(() => {
            // Fallback: manual increment
            supabaseAdmin
              .from("taxi_drivers")
              .update({
                is_on_trip: false,
                total_trips: supabaseAdmin.rpc("sql", { query: "total_trips + 1" }),
              })
              .eq("id", ride.driver_id);
          });
        }
      }

      if (status === "cancelled") {
        // Free up driver
        const { data: ride } = await supabaseAdmin
          .from("taxi_rides")
          .select("driver_id")
          .eq("id", ride_id)
          .single();

        if (ride?.driver_id) {
          await supabaseAdmin
            .from("taxi_drivers")
            .update({ is_on_trip: false })
            .eq("id", ride.driver_id);
        }
      }

      const { data: updatedRide, error: updateError } = await supabaseAdmin
        .from("taxi_rides")
        .update(updateData)
        .eq("id", ride_id)
        .select()
        .single();

      if (updateError) throw updateError;

      return new Response(
        JSON.stringify({ success: true, ride: updatedRide }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    if (payload.action === "assign_driver") {
      const { ride_id, driver_id } = payload;

      // Update ride with driver
      const { data: ride, error: rideError } = await supabaseAdmin
        .from("taxi_rides")
        .update({
          driver_id,
          status: "accepted",
        })
        .eq("id", ride_id)
        .select()
        .single();

      if (rideError) throw rideError;

      // Update driver status
      await supabaseAdmin
        .from("taxi_drivers")
        .update({ is_on_trip: true })
        .eq("id", driver_id);

      return new Response(
        JSON.stringify({ success: true, ride }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    throw new Error("Invalid action");
  } catch (error) {
    console.error("Taxi service error:", error);
    return new Response(
      JSON.stringify({ error: error instanceof Error ? error.message : "Unknown error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
