 // Database types for BusNStay real-time backend
 
 export interface DBBus {
   id: string;
   registration_number: string;
   name: string;
   capacity: number;
   current_route_id: string | null;
   current_position: string | null; // PostGIS POINT
   heading: number;
   speed: number;
   last_gps_update: string;
   status: 'active' | 'inactive' | 'maintenance';
   created_at: string;
   updated_at: string;
 }
 
 export interface DBRoute {
   id: string;
   name: string;
   from_town: string;
   to_town: string;
   total_distance: number;
   estimated_duration: number;
   waypoints: string[];
   is_active: boolean;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBStop {
   id: string;
   town_id: string;
   name: string;
   coordinates: string; // PostGIS POINT
   region: string;
   size: 'major' | 'medium' | 'minor';
   geofence_radius: number;
   services_available: {
     restaurants: number;
     hotels: number;
     riders: number;
     taxis: number;
   };
   is_active: boolean;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBJourney {
   id: string;
   bus_id: string;
   route_id: string;
   departure_time: string;
   estimated_arrival: string | null;
   actual_arrival: string | null;
   current_stop_id: string | null;
   next_stop_id: string | null;
   progress: number;
   status: 'scheduled' | 'active' | 'completed' | 'cancelled' | 'delayed';
   delay_minutes: number;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBJourneyPassenger {
   id: string;
   journey_id: string;
   user_id: string;
   boarding_stop_id: string | null;
   alighting_stop_id: string | null;
   seat_number: string | null;
   current_position: string | null;
   last_gps_update: string | null;
   boarding_status: 'pending' | 'boarded' | 'alighted' | 'no_show';
   created_at: string;
   updated_at: string;
 }
 
 export interface DBJourneyETA {
   id: string;
   journey_id: string;
   stop_id: string;
   predicted_arrival: string;
   confidence: number;
   is_delayed: boolean;
   delay_minutes: number;
   last_calculated: string;
 }
 
 export interface DBDeliveryAgent {
   id: string;
   user_id: string | null;
   name: string;
   phone: string;
   current_stop_id: string | null;
   current_position: string | null;
   heading: number | null;
   status: 'online' | 'offline' | 'busy' | 'on_delivery';
   rating: number;
   total_deliveries: number;
   last_gps_update: string;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBRestaurant {
   id: string;
   stop_id: string;
   name: string;
   cuisine: string | null;
   rating: number;
   price_range: string;
   average_prep_time: number;
   is_open: boolean;
   opening_hours: { open: string; close: string };
   created_at: string;
   updated_at: string;
 }
 
 export interface DBMenuItem {
   id: string;
   restaurant_id: string;
   name: string;
   description: string | null;
   price: number;
   category: string;
   image_url: string | null;
   is_available: boolean;
   prep_time: number;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBOrder {
   id: string;
   user_id: string;
   journey_id: string | null;
   journey_passenger_id: string | null;
   restaurant_id: string;
   stop_id: string;
   delivery_agent_id: string | null;
   items: Array<{
     menu_item_id: string;
     name: string;
     quantity: number;
     price: number;
   }>;
   subtotal: number;
   delivery_fee: number;
   total: number;
   status: 'pending' | 'confirmed' | 'preparing' | 'ready' | 'out_for_delivery' | 'delivered' | 'cancelled';
   estimated_ready_time: string | null;
   actual_ready_time: string | null;
   delivery_type: 'pickup' | 'bus_delivery';
   special_instructions: string | null;
   created_at: string;
   updated_at: string;
 }
 
 export interface DBJourneyAlert {
   id: string;
   journey_id: string;
   alert_type: 'delay' | 'reroute' | 'mechanical' | 'weather' | 'traffic' | 'delivery_issue' | 'stop_skip';
   severity: 'info' | 'warning' | 'critical';
   title: string;
   message: string;
   affected_stop_id: string | null;
   location: string | null;
   is_resolved: boolean;
   resolved_at: string | null;
   created_at: string;
   expires_at: string | null;
 }
 
 export interface DBSharedJourneyLink {
   id: string;
   journey_passenger_id: string;
   share_code: string;
   created_by_user_id: string;
   viewer_name: string | null;
   permissions: {
     view_location: boolean;
     view_eta: boolean;
     view_stops: boolean;
     view_orders: boolean;
   };
   is_active: boolean;
   expires_at: string | null;
   views_count: number;
   last_viewed_at: string | null;
   created_at: string;
 }
 
 // Helper to parse PostGIS POINT to coordinates
 export function parsePostGISPoint(point: string | null): [number, number] | null {
   if (!point) return null;
   const match = point.match(/POINT\(([-\d.]+) ([-\d.]+)\)/);
   if (!match) return null;
   return [parseFloat(match[2]), parseFloat(match[1])]; // [lat, lng]
 }
 
 // Helper to create PostGIS POINT from coordinates
 export function toPostGISPoint(lat: number, lng: number): string {
   return `POINT(${lng} ${lat})`;
 }