# 🚀 Delivery Tracking - Quick Start (5 Minutes)

## What This Does
Real-time GPS tracking for delivery riders. Shows:
- 📍 Live location on Google Map
- 🗺️ Route to destination
- ⏱️ ETA for each stop
- 🍽️ Restaurants at stops
- 📞 Call center contact option

## Components
```
/src/pages/DeliveryTracker.tsx          Main page
/src/components/JourneyMap.tsx           Google Map
/src/components/JourneyTimeline.tsx      Station list + tabs
/src/hooks/useDeliveryTracking.ts        Data layer (6 hooks)
/supabase/migrations/*.sql               Database schema
```

## Setup (3 Steps)

### 1️⃣ Environment
```env
# Add to .env.local
VITE_GOOGLE_MAPS_API_KEY=your_key_here
```

### 2️⃣ Database
```sql
-- Copy entire contents of: supabase/migrations/add_delivery_tracking.sql
-- Paste into Supabase SQL editor and run
```

### 3️⃣ Routing
```tsx
// In App.tsx, add:
<Route path="/rider/delivery/:jobId" element={<DeliveryTracker />} />
```

## Usage

### For Riders
```
Navigate to: /rider/delivery/{job_id}
```

### For Developers
```tsx
import { useRiderLocation, useActiveDeliveryJobs } from "@/hooks/useDeliveryTracking";

// Get GPS location (auto-starts tracking)
const { location, error } = useRiderLocation(userId);
// location = { latitude, longitude, accuracy, timestamp }

// Get active jobs
const { jobs } = useActiveDeliveryJobs(riderId);
// jobs = [{ id, status, origin_stop_id, destination_stop_id, ... }]
```

## Database Tables

### 1. rider_locations
```sql
--  Stores GPS coordinates
| rider_id | latitude | longitude | accuracy | timestamp |
```

### 2. delivery_jobs
```
-- Tracks delivery status
| id | rider_id | status | origin_stop_id | destination_stop_id |
```

### 3. delivery_routes
```sql
-- Historical trail (optional)
| job_id | latitude | longitude | timestamp |
```

All tables have:
- ✅ Auto-updating timestamps
- ✅ RLS policies (secure by default)
- ✅ Real-time subscriptions enabled
- ✅ Performance indexes

## Hooks (Ready to Use)

| Hook | Returns | What It Does |
|------|---------|-------------|
| `useRiderLocation(id)` | `{ location, isTracking, error }` | GPS tracking |
| `useActiveDeliveryJobs(id)` | `{ jobs, loading, error }` | Fetch jobs |
| `useStationWithRestaurants(id)` | `{ station, restaurants }` | Stop details |
| `useRestaurantOrders(id)` | `{ orders, loading, error }` | Pending orders |
| `useCalculateRoute(from, to)` | `{ route, loading, error }` | Distance + ETA |

## Real-time Updates

Everything auto-updates:
- ✅ Location updates every 10 seconds (Geolocation API)
- ✅ Job status updates instantly (Supabase Realtime)
- ✅ Order changes stream live
- ✅ UI refreshes automatically

## Testing

### Create Test Job
```sql
INSERT INTO public.delivery_jobs (
  rider_id, order_id, status, 
  origin_stop_id, destination_stop_id
) VALUES (
  'your-rider-id', 'order-123', 'accepted',
  'stop-1', 'stop-2'
);
```

### Test Tracking
1. Go to: `http://localhost:8081/rider/delivery/job-id`
2. Browser should ask for location permission → Allow
3. Watch marker move on map (updates every 10 seconds)
4. Check `SELECT * FROM rider_locations;` in Supabase

## Common Issues

| Problem | Fix |
|---------|-----|
| Map not showing | Add Google Maps API key to .env.local |
| GPS not updating | Allow location permission + check HTTPS |
| Realtime not working | Run migration SQL + check RLS |
| Job not found | Verify job exists + rider_id matches `auth.uid()` |

## Files to Know

```
DELIVERY_TRACKING_INTEGRATION.md  ← Full reference
useDeliveryTracking.ts            ← Hook implementations
DeliveryTracker.tsx               ← Main page logic
add_delivery_tracking.sql         ← Database schema
.env.local                        ← Config (add API key)
```

## Next: Deploy to Production

1. ✅ Test locally with real mobile device (geolocation requires HTTPS)
2. ✅ Deploy to production (Vercel, Netlify, etc.)
3. ✅ Run migration SQL in production Supabase
4. ✅ Add API keys to production env
5. ✅ Monitor realtime subscriptions performance

## Debug Commands

```bash
# Check Supabase status
curl https://your-project.supabase.co/rest/v1/

# Watch location updates
SELECT COUNT(*) FROM rider_locations 
WHERE timestamp > NOW() - INTERVAL '1 minute';

# Check subscriptions
SELECT * FROM pg_subscription;
```

## Key Features Implemented ✅

- [x] Real-time GPS tracking
- [x] Google Maps visualization
- [x] Live job status updates
- [x] Station/restaurant integration
- [x] Call center contact option
- [x] ETA calculation
- [x] Error handling
- [x] Mobile-first design
- [x] Secure RLS policies
- [x] Zero compilation errors

---

**Need More Details?** → See `DELIVERY_TRACKING_INTEGRATION.md`  
**Status:** ✅ Production Ready  
**Version:** 1.0
