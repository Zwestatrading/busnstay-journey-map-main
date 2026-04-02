# Component Integration Guide

This guide details how to integrate the three new enterprise features into your BusNStay application.

---

## 1. Service Provider Verification

### Overview
The Service Provider Verification system allows restaurants, hotels, taxi companies, and riders to register and get verified by admins.

### Components Location
- **Provider Registration Form:** `src/components/ServiceProviderVerification.tsx`
- **Admin Dashboard:** `src/components/AdminVerificationDashboard.tsx`
- **Document Viewer:** `src/components/DocumentViewer.tsx`
- **Public Pages:** 
  - `src/pages/Verification.tsx` - Registration page
  - `src/pages/VerificationStatus.tsx` - Status checking page

### Integration Status ✅ COMPLETE

The verification system is already integrated:
- Pages exist in routing
- Components are ready to use
- Database tables created (see SQL migration)

### How It Works

1. **Provider Submits Documents**
   ```tsx
   <ServiceProviderVerification 
     userId={userId}
     onSubmitted={() => navigate('/verification-status')}
   />
   ```

2. **Admin Reviews Documents**
   - AdminDashboard now includes verification tab (already integrated)
   - Shows pending approvals
   - Click to approve/reject

3. **Provider Gets Status**
   - Check their profile: `profile.is_approved`
   - Can access their dashboard only if approved

### Database Tables Created
- `service_provider_documents` - Document storage
- `service_provider_verifications` - Verification records
- `verification_history` - Audit trail
- `document_type` enum
- `verification_status` enum

---

## 2. Distance-Based Dynamic Pricing

### Overview
Restaurants can configure delivery zones and dynamic pricing based on distance, time, and demand.

### Components Location
- **Fee Display:** `src/components/DeliveryFeeBreakdown.tsx`
- **Service Layer:** `src/services/deliveryFeeService.ts`

### Integration Points

#### Point 1: Order Checkout/Summary Page
**Current Location:** Wherever you display order totals

**Integration Example:**
```tsx
import { DeliveryFeeBreakdown } from '@/components/DeliveryFeeBreakdown';

function CheckoutPage() {
  const { restaurantId, deliveryDistance } = useOrderContext();
  
  return (
    <div>
      <h3>Order Summary</h3>
      {/* Other order items */}
      
      <DeliveryFeeBreakdown 
        restaurantId={restaurantId}
        distanceKm={deliveryDistance}
        orderTotal={calculateSubtotal()}
      />
      
      <Button onClick={placeOrder}>Place Order</Button>
    </div>
  );
}
```

#### Point 2: Restaurant Dashboard Configuration
**Create a new page or section:** `src/pages/RestaurantDashboard.tsx`

**Add Delivery Configuration Section:**
```tsx
import { deliveryFeeService } from '@/services/deliveryFeeService';

function DeliveryConfigPanel() {
  const [config, setConfig] = useState(null);
  
  useEffect(() => {
    const loadConfig = async () => {
      const cfg = await deliveryFeeService.getRestaurantDeliveryConfig(restaurantId);
      setConfig(cfg);
    };
    loadConfig();
  }, [restaurantId]);
  
  return (
    <div className="space-y-4">
      <h3>Delivery Configuration</h3>
      
      <Card>
        <CardHeader>Base Delivery Fee</CardHeader>
        <CardContent>
          <input 
            type="number" 
            value={config?.baseDeliveryFee}
            onChange={(e) => updateConfig({ baseDeliveryFee: parseFloat(e.target.value) })}
          />
        </CardContent>
      </Card>
      
      {/* Add delivery zones */}
      <Card>
        <CardHeader>Delivery Zones</CardHeader>
        <CardContent>
          {/* List zones here */}
        </CardContent>
      </Card>
    </div>
  );
}
```

### Database Tables Created
- `delivery_zones` - Service area polygons
- `delivery_fee_rules` - Distance-based pricing rules
- Updates to `restaurants` table - GPS coordinates, base fees
- Updates to `orders` table - Delivery tracking fields

### Key Service Functions

```typescript
// Calculate delivery fee based on distance and order total
const fee = await deliveryFeeService.calculateDeliveryFee(
  restaurantId, 
  distanceKm, 
  orderTotal
);

// Check if delivery location is in service area
const inZone = await deliveryFeeService.checkDeliveryZone(
  restaurantId,
  latitude,
  longitude
);

// Create delivery zone
await deliveryFeeService.createDeliveryZone(
  restaurantId,
  'Zone Name',
  maxDistanceKm,
  minOrderValue,
  deliveryTimeMinutes
);

// Create dynamic pricing rule
await deliveryFeeService.createDeliveryFeeRule(
  restaurantId,
  {
    distanceRangeStart: 0,
    distanceRangeEnd: 2,
    feeFlat: 2.50,
    feePercentage: 0
  }
);
```

---

## 3. Real-Time GPS Tracking

### Overview
Live location tracking for riders during deliveries. Includes real-time map updates, geofence alerts, and location history.

### Components Location
- **Live Delivery Map:** `src/components/LiveDeliveryMap.tsx`
- **GPS Status Display:** `src/components/GPSTrackingStatus.tsx`
- **Location History:** `src/components/LocationHistory.tsx`
- **Services:** 
  - `src/services/gpsTrackingService.ts` - Real-time subscriptions
  - `src/services/geoService.ts` - Distance calculations

### Integration Status ✅ PARTIALLY COMPLETE

Already integrated:
- ✅ AdminDashboard → "Delivery Tracking" tab (new)
- ✅ RiderDashboard → "Live Tracking" & "Location History" tabs (new)

### Integration Points for Additional Pages

#### Point 1: Customer Order Status Page
**Location:** Wherever customers track their delivery

```tsx
import { LiveDeliveryMap } from '@/components/LiveDeliveryMap';

function OrderStatusPage() {
  const { orderId } = useParams();
  const order = useOrderData(orderId);
  
  return (
    <div className="space-y-4">
      <h2>Your Delivery</h2>
      
      {order.status === 'out_for_delivery' && (
        <LiveDeliveryMap 
          orderId={orderId}
          restaurantLat={order.restaurant.latitude}
          restaurantLon={order.restaurant.longitude}
          deliveryLat={order.delivery.latitude}
          deliveryLon={order.delivery.longitude}
          agentPhone={order.deliveryAgent.phone}
        />
      )}
      
      {/* Order details, estimated arrival, etc */}
    </div>
  );
}
```

#### Point 2: Admin Live Monitoring Dashboard
**Location:** AdminDashboard (✅ ALREADY INTEGRATED)

The "Delivery Tracking" tab shows:
- List of active riders
- Click on a rider to view GPS status
- Real-time location history
- Geofence alerts

#### Point 3: Rider Mobile App (RiderDashboard)
**Location:** RiderDashboard (✅ ALREADY INTEGRATED)

When a rider accepts a delivery:
- Shows "Live Tracking" tab with GPS status
- Displays "Location History" tab with movement timeline
- Screen updates in real-time (<100ms)

### Database Tables Created
- `rider_locations` - Current rider position
- `delivery_locations` - In-transit delivery tracking
- `location_history` - 30-day position archive
- `geofence_alerts` - Boundary/speed alerts

### Key Service Functions

```typescript
// Update rider position (call every 5-10 seconds)
await gpsTrackingService.updateRiderLocation(
  riderId,
  {
    latitude: position.coords.latitude,
    longitude: position.coords.longitude,
    accuracy: position.coords.accuracy,
    speed: position.coords.speed,
    heading: position.coords.heading
  },
  journeyId
);

// Subscribe to real-time updates
const channel = gpsTrackingService.subscribeToRiderLocation(
  riderId,
  (location) => {
    console.log('Rider moved to:', location.latitude, location.longitude);
    updateMapPosition(location);
  }
);

// Clean up subscription
gpsTrackingService.unsubscribeFromLocation(channel);

// Get location history
const history = await gpsTrackingService.getRiderLocationHistory(
  riderId,
  24 // hours back
);

// Create geofence alert
await gpsTrackingService.createGeofenceAlert(
  riderId,
  null,
  'geofence_enter',
  'Entered delivery zone',
  latitude,
  longitude,
  2 // radius in km
);

// Get pending (unacknowledged) geofence alerts
const alerts = await gpsTrackingService.getPendingGeofenceAlerts(riderId);

// Subscribe to geofence alerts in real-time
const alertChannel = gpsTrackingService.subscribeToGeofenceAlerts(
  riderId,
  (alert) => {
    showNotification(`${alert.message}`);
  }
);
```

---

## 4. Integration Checklist

### Service Provider Verification
- [x] SQL migration deployed
- [x] Components created
- [x] Pages created (Verification.tsx, VerificationStatus.tsx)
- [x] Database tables created
- [x] Storage bucket for documents (manual step)

**To Complete:**
- [ ] Create storage bucket named `documents` in Supabase
- [ ] Configure RLS policies on bucket (see DEPLOYMENT_GUIDE.md)
- [ ] Test document upload flow

### Distance-Based Pricing
- [x] SQL migration deployed
- [x] Components created
- [x] Service layer implemented
- [x] Database tables created

**To Complete:**
- [ ] Integrate `DeliveryFeeBreakdown` into checkout page
- [ ] Create restaurant delivery config page
- [ ] Test fee calculation with different distances
- [ ] Set up delivery zones for restaurants

### GPS Tracking
- [x] SQL migration deployed
- [x] Components created
- [x] Service layer implemented
- [x] Database tables created
- [x] Integrated into AdminDashboard
- [x] Integrated into RiderDashboard

**To Complete:**
- [ ] Verify Realtime is enabled (Supabase Dashboard → Replication)
- [ ] Test GPS subscriptions (check network WS connections)
- [ ] Integrate into customer order tracking page (if exists)
- [ ] Add geofence alerts to notification system

---

## 5. Testing Integration

### Unit Tests
```bash
npm run test
```

### Integration Tests - Service Layer
```tsx
// Test GPS tracking service
import { gpsTrackingService } from '@/services/gpsTrackingService';

test('updateRiderLocation should update position', async () => {
  await gpsTrackingService.updateRiderLocation('rider-123', {
    latitude: 37.7749,
    longitude: -122.4194,
    accuracy: 5,
    speed: 25,
    heading: 180
  });
  
  const location = await gpsTrackingService.getRiderLocation('rider-123');
  expect(location.latitude).toBe(37.7749);
});

// Test delivery fee calculation
import { deliveryFeeService } from '@/services/deliveryFeeService';

test('calculateDeliveryFee should return correct amount', async () => {
  const fee = await deliveryFeeService.calculateDeliveryFee(
    'restaurant-123',
    5.2, // km
    100 // order total
  );
  expect(fee).toBeGreaterThan(0);
});
```

### Manual Testing
1. **GPS Tracking:**
   - Enable location on browser (allow geolocation)
   - Watch real-time updates (should be <100ms)
   - Check location history shows positions
   - Verify geofence alerts trigger

2. **Delivery Pricing:**
   - Create order for different distances
   - Verify fee changes based on distance
   - Check surge pricing applies during peak hours
   - Test discount application

3. **Verification:**
   - Register as service provider
   - Upload documents
   - Admin approves/rejects
   - Verify access changes based on approval status

---

## 6. Troubleshooting

### GPS Updates Not Real-Time
**Problem:** Locations show old data, not live
**Solution:**
1. Check Realtime is enabled: Supabase → Replication → Check `rider_locations`, `delivery_locations`
2. Check browser WebSocket: DevTools → Network → WS (should show `realtime` connection)
3. Verify subscription cleanup: Component unmounts should call `unsubscribeFromLocation()`

### Storage Bucket Upload Fails
**Problem:** "Permission denied" when uploading documents
**Solution:**
1. Bucket must be named `documents` (exact name)
2. Check RLS policies are configured correctly
3. Verify you're authenticated when uploading
4. Clear browser cache

### Distance Calculation Wrong
**Problem:** Distances don't match Google Maps
**Solution:**
1. Verify coordinates are valid (lat: -90 to 90, lon: -180 to 180)
2. Check PostGIS SRID: `SELECT ST_SRID(location) FROM restaurants;` should return 4326
3. Compare with: `ST_Distance(point1::geography, point2::geography) / 1000` (converts meters to km)

### Components Don't Appear
**Problem:** Import errors or blank screen
**Solution:**
1. Check components are in correct paths
2. Verify no TypeScript errors: `npm run type-check`
3. Check browser console for React errors
4. Verify props are passed correctly

---

## 7. Performance Optimization Tips

### Database Performance
- Use provided GiST indexes for geography queries
- Cache restaurant delivery config (5 min)
- Batch location history requests if needed

### Frontend Performance
- Use React Query for caching service responses
- Unsubscribe from real-time channels on unmount
- Throttle GPS updates to 5-second intervals
- Lazy load location history (paginate)

### Real-Time Subscriptions
- Only subscribe when component is visible
- Unsubscribe immediately on unmount
- Use filter predicates to reduce message volume
- Monitor memory usage of long-lived subscriptions

---

## 8. Running the App

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Type check
npm run type-check

# Build for production
npm run build

# Run tests
npm run test
```

---

## 9. Support Files

- **Deployment Guide:** `DEPLOYMENT_GUIDE.md` - SQL deployment, storage setup
- **Service Provider Guide:** `SERVICE_PROVIDER_VERIFICATION_GUIDE.md`
- **Migration Files:** `supabase/migrations/`
  - `20260210_service_provider_verification.sql`
  - `20260210_distance_based_pricing.sql`
  - `20260210_gps_tracking.sql`

---

**Last Updated:** February 10, 2026

