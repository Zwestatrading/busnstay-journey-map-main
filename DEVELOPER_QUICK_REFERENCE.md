# 🚀 Developer Quick Reference - April 2026 Fixes

**TL;DR:** 3 critical fixes implemented. Copy-paste these snippets into your components.

---

## 📋 Quick Links

| Issue | File | Quick Fix |
|-------|------|-----------|
| ❌ Users book from wrong location | `locationValidationService.ts` | Use `validateLocationForRoute()` |
| ❌ Map shows straight lines | `roadRoutingService.ts` | Use `getRouteGeometry()` |
| ❌ Unapproved restaurants showing | `restaurantFilteringService.ts` | Use `getApprovedRestaurantsByStation()` |

---

## 🎯 Code Snippets

### **Fix 1: Stop Wrong Location Bookings**

**Where:** Journey booking page or modal

```typescript
import { validateLocationForRoute } from '@/services/locationValidationService';

const handleBookJourney = async (fromStation: string, toStation: string) => {
  // NEW: Validate location first
  const validation = await validateLocationForRoute(fromStation, toStation);
  
  if (!validation.isValid) {
    // Show user the error
    showErrorDialog({
      title: 'Location Mismatch',
      message: validation.message,
      action: 'Show Nearest Stations'
    });
    return;
  }

  // Show ETA to user
  console.log(`✅ Journey allowed! ETA: ${validation.eta} minutes`);

  // Proceed with booking
  proceedWithBooking(fromStation, toStation);
};
```

---

### **Fix 2: Show Actual Road Routes on Map**

**Where:** Any component displaying map route (SharedJourney.tsx, etc.)

```typescript
import { getRouteGeometry } from '@/services/roadRoutingService';
import { Polyline } from 'react-leaflet';

const RouteMap = ({ startPoint, endPoint }) => {
  const [route, setRoute] = useState(null);

  useEffect(() => {
    const loadRoute = async () => {
      // Get ACTUAL road geometry from OSRM
      const routeData = await getRouteGeometry(
        startPoint.lat, startPoint.lng,
        endPoint.lat, endPoint.lng
      );
      setRoute(routeData);
    };
    loadRoute();
  }, [startPoint, endPoint]);

  if (!route) return <div>Loading route...</div>;

  // Convert OSRM format [lng,lat] to Leaflet format [lat,lng]
  const polylinePositions = route.geometry.map(([lng, lat]) => [lat, lng]);

  return (
    <MapContainer center={[startPoint.lat, startPoint.lng]} zoom={7}>
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      
      {/* Show REAL road path instead of straight line */}
      <Polyline
        positions={polylinePositions}
        color="blue"
        weight={3}
        opacity={0.8}
      />

      {/* Show distance & duration */}
      <div className="route-info">
        <p>Distance: {route.distance.toFixed(1)} km</p>
        <p>Time: {Math.round(route.duration / 60)} minutes</p>
      </div>
    </MapContainer>
  );
};
```

---

### **Fix 3: Hide Unapproved Restaurants**

**Where:** Restaurant list component

```typescript
import { getApprovedRestaurantsByStation } from '@/services/restaurantFilteringService';

const RestaurantList = ({ stationId }) => {
  const [restaurants, setRestaurants] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadRestaurants = async () => {
      // NOW ONLY SHOWS APPROVED
      const approved = await getApprovedRestaurantsByStation(stationId);
      setRestaurants(approved);
      setLoading(false);
    };
    loadRestaurants();
  }, [stationId]);

  if (loading) return <div>Loading restaurants...</div>;

  return (
    <div className="restaurant-grid">
      {restaurants.length === 0 ? (
        <p>No restaurants available at this station</p>
      ) : (
        restaurants.map(restaurant => (
          <RestaurantCard
            key={restaurant.id}
            name={restaurant.name}
            rating={restaurant.rating}
            status="✅ Verified" // All shown are approved
          />
        ))
      )}
    </div>
  );
};
```

---

## 🧪 Testing Each Fix

### **Test Fix 1: Location Validation**

```bash
# From Livingstone, try to book Ndola→Lusaka
# Expected: ❌ ERROR showing distance from route

# From Ndola, try to book Ndola→Lusaka  
# Expected: ✅ ALLOWED with ETA shown
```

### **Test Fix 2: Route Geometry**

```bash
# Open any journey map
# Expected: Blue line follows actual roads (not straight line)
# Check network tab: Should see OSRM API calls

curl "https://router.project-osrm.org/route/v1/driving/28.7015,-12.9626;28.2833,-15.4167?overview=full"
```

### **Test Fix 3: Restaurant Filtering**

```bash
# In Supabase, create test restaurants:
# INSERT INTO restaurants VALUES (
#   id, 'Test Restaurant', stop_id, 
#   is_approved=false,
#   approval_status='pending'
# )

# Visit app → Should NOT see this restaurant
# In admin panel → Should see with "Pending" badge
```

---

## 🔌 New Services Cheat Sheet

### **Road Routing Service**

```typescript
import { 
  getRouteGeometry,           // Get map polyline
  validateLocationOnRealRoute, // Check if user on route
  findNearestStations,         // Find 3 nearest stations
  getETABetweenPoints,         // Get time estimate
  getDistanceMatrix            // Distance between many points
} from '@/services/roadRoutingService';

// Example: Get nearest 3 stations
const stations = await findNearestStations(userLat, userLng, allStations, 3);
// Returns: [{name, distance, eta}, ...]
```

### **Restaurant Filtering Service**

```typescript
import {
  getApprovedRestaurantsByStation,  // Show only approved
  getAllApprovedRestaurants,        // All approved, any station
  getAllRestaurantsForAdmin,        // Admin sees all statuses
  searchApprovedRestaurants,        // Search in approved only
  getRestaurantsByRating            // Filter by rating
} from '@/services/restaurantFilteringService';

// Use this everywhere for normal users:
const restaurants = await getApprovedRestaurantsByStation(stationId);
```

### **Restaurant Approval Service (Admin Only)**

```typescript
import {
  getPendingRestaurants,      // Show pending approvals
  approveRestaurant,          // Admin approves
  rejectRestaurant,           // Admin rejects
  suspendRestaurant,          // Admin pauses
  reopenRestaurant,           // Admin resumes
  getApprovalLogs             // See change history
} from '@/services/restaurantApprovalService';

// Admin dashboard example:
const pending = await getPendingRestaurants();
pending.forEach(r => {
  <RestaurantCard
    restaurant={r}
    actions={
      <button onClick={() => approveRestaurant(r.id)}>✅ Approve</button>
      <button onClick={() => rejectRestaurant(r.id)}>❌ Reject</button>
    }
  />
})
```

---

## ⚠️ Common Issues & Solutions

### Issue: Location validation works but still slow

**Solution:** Add loading state
```typescript
const [validating, setValidating] = useState(false);

const validate = async () => {
  setValidating(true);
  const result = await validateLocationForRoute(...);
  setValidating(false); // Show spinner while loading
};
```

### Issue: OSRM timeout occasionally

**Solution:** Automatically uses fallback
- Currently: Falls back to haversine if OSRM fails
- No action needed - graceful degradation built-in

### Issue: Restaurant list shows unapproved ones

**Solution:** Change query filter
```typescript
// ❌ OLD
const all = await supabase.from('restaurants').select('*');

// ✅ NEW
const approved = await getApprovedRestaurantsByStation(stationId);
```

### Issue: Map shows straight line instead of road

**Solution:** Use `getRouteGeometry()` output
```typescript
// ❌ OLD - straight line
const straight = [[lat1, lng1], [lat2, lng2]];

// ✅ NEW - actual roads
const route = await getRouteGeometry(lat1, lng1, lat2, lng2);
const curvy = route.geometry.map(([lng, lat]) => [lat, lng]);
```

---

## 📊 Performance Tips

**Caching:**
```typescript
// Cache route geometry for 5 minutes
const routeCache = new Map();
const cacheKey = `${start}-${end}`;

if (routeCache.has(cacheKey)) {
  return routeCache.get(cacheKey);
}

const route = await getRouteGeometry(...);
routeCache.set(cacheKey, route);
```

**Batching:**
```typescript
// Instead of calling for each station:
for (const station of stations) {
  const distance = await getETABetweenPoints(...); // ❌ Slow
}

// Batch all at once:
const matrix = await getDistanceMatrix(stations); // ✅ Fast
```

---

## 🎓 Understanding OSRM

Open Source Routing Machine (OSRM) is a free routing engine:

```
User Location: -17.8252, 25.8655 (Livingstone)
         ↓
    OSRM API
    https://router.project-osrm.org/route/v1/driving/
         ↓
Returns: [[lng,lat], [lng,lat], ...] along actual roads
         ↓
    Show on Map: Real road path (not straight line)
```

**Key URLs:**
- Main: `https://router.project-osrm.org/route/v1/driving/{lng},{lat};{lng},{lat}`
- Status: `https://router.project-osrm.org/status`
- Docs: `http://project-osrm.org/docs/v5.5.1/api/`

---

## 🚀 Deployment Checklist

- [ ] Run `supabase db push` to apply migration
- [ ] Copy new service files to `src/services/`
- [ ] Update components to use new service functions
- [ ] Run test suite: `npm run test`
- [ ] Test on device with real GPS
- [ ] Check admin panel can approve restaurants
- [ ] Verify unapproved restaurants don't show

---

## ❓ Need Help?

1. **Location validation not working?**
   - Check: Device has GPS enabled
   - Check: `validateLocationForRoute()` returns error message
   - Fallback: Auto-uses haversine if OSRM down

2. **Routes showing straight lines?**
   - Check: Using `getRouteGeometry()` output
   - Check: Converting [lng,lat] → [lat,lng] for Leaflet
   - Verify: OSRM API call in network tab

3. **Unapproved restaurants still showing?**
   - Check: Database has `is_approved` column (ran migration)
   - Check: Using `getApprovedRestaurantsByStation()` not raw query
   - Check: Restaurant has `approval_status='approved'`

---

**Generated:** April 1, 2026  
**Last Updated:** Today  
**Status:** Ready for Production ✅
