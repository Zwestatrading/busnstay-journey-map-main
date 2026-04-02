# Enterprise Features Deployment Guide

Complete setup instructions for the three new enterprise features:
1. Service Provider Verification
2. Distance-Based Dynamic Pricing
3. Real-Time GPS Tracking

---

## Phase 1: SQL Migrations Deployment

### Step 1.1 - Open Supabase Dashboard
1. Go to https://app.supabase.com
2. Select your project
3. Navigate to **SQL Editor**

### Step 1.2 - Deploy Service Provider Verification Migration
1. Click **New Query**
2. Copy the contents of `supabase/migrations/20260210_service_provider_verification.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify: Check that these tables were created:
   - `service_provider_documents`
   - `service_provider_verifications`
   - `verification_history`

### Step 1.3 - Deploy Distance-Based Pricing Migration
1. Click **New Query**
2. Copy the contents of `supabase/migrations/20260210_distance_based_pricing.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify: Check that these tables were created/updated:
   - `delivery_zones` (new)
   - `delivery_fee_rules` (new)
   - `restaurants` (columns added: location, latitude, longitude, base_delivery_fee, delivery_fee_per_km)
   - `orders` (columns added: delivery_location, delivery_distance_km, delivery_fee, delivery_status, estimated_delivery_time)

### Step 1.4 - Deploy GPS Tracking Migration
1. Click **New Query**
2. Copy the contents of `supabase/migrations/20260210_gps_tracking.sql`
3. Paste into the SQL editor
4. Click **Run**
5. Verify: Check that these tables were created:
   - `rider_locations`
   - `delivery_locations`
   - `location_history`
   - `geofence_alerts`

---

## Phase 2: Storage Bucket Setup

### Step 2.1 - Create Documents Storage Bucket
1. Go to Supabase Dashboard
2. Navigate to **Storage** → **Buckets**
3. Click **New Bucket**
4. Name it: `documents`
5. Make it **Private** (not public)
6. Click **Create Bucket**

### Step 2.2 - Configure Bucket Policies
1. Click on the `documents` bucket
2. Go to **Policies** tab
3. Click **New Policy**
4. Create "Upload documents" policy:
   - **User:** Authenticated
   - **Operations:** SELECT, INSERT
   - **Target roles:** Check `Authenticated users`
   - **Custom expression:** `bucket_id = 'documents' AND auth.uid() = owner_id`
5. Click **Save**

### Step 2.3 - Enable PostGIS Extension (If Not Already Enabled)
1. Go to Supabase Dashboard → **SQL Editor**
2. Run this query:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;
   CREATE EXTENSION IF NOT EXISTS postgis_raster WITH SCHEMA public;
   ```
3. This enables geographic functions for distance calculations

---

## Phase 3: Environment Configuration

### Step 3.1 - Verify .env Configuration
Ensure your `.env.local` has:
```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### Step 3.2 - Test Services
Run the app and check browser console for errors:
```bash
npm run dev
```

---

## Phase 4: Component Integration

### Components Already Integrated ✅
The following components are already in the codebase and imported correctly:

**Service Provider Verification:**
- `src/components/ServiceProviderVerification.tsx` - Provider registration form
- `src/components/AdminVerificationDashboard.tsx` - Admin approval interface
- `src/pages/Verification.tsx` - Public verification page
- `src/pages/VerificationStatus.tsx` - Provider status dashboard

**Distance-Based Pricing:**
- `src/components/DeliveryFeeBreakdown.tsx` - Fee display component
- `src/services/deliveryFeeService.ts` - Fee calculation service

**GPS Tracking:**
- `src/components/LiveDeliveryMap.tsx` - Real-time delivery map
- `src/components/GPSTrackingStatus.tsx` - GPS signal quality display
- `src/components/LocationHistory.tsx` - Historical location timeline
- `src/services/gpsTrackingService.ts` - Real-time subscription service
- `src/services/geoService.ts` - Distance calculation utilities

### Step 4.1 - Integration Points (See INTEGRATION_GUIDE.md)

The components are ready to integrate into:
- **AdminDashboard.tsx** → Add "Delivery Tracking" tab with GPS tracking components
- **RiderDashboard.tsx** → Add "Location Sharing" section with GPS status and history
- **RestaurantDashboard.tsx** → Add "Delivery Fee Configuration" section
- **Account pages** → Add "Delivery Fee Breakdown" to checkout/order summary

---

## Phase 5: Testing Checklist

### Backend Tests
- [ ] SQL migrations executed without errors
- [ ] New tables appear in Supabase dashboard
- [ ] PostGIS functions working (run: `SELECT ST_Distance(...)` in SQL editor)
- [ ] RLS policies active (check Table → Policies tab)

### Frontend Tests
- [ ] App compiles: `npm run dev` (no errors in terminal)
- [ ] No TypeScript errors: `npm run type-check`
- [ ] All new components import correctly
- [ ] Services initialize without errors (check browser console)

### Feature Tests
1. **Service Provider Verification:**
   - Register a service provider
   - Upload verification documents
   - Admin can approve/reject

2. **Distance-Based Pricing:**
   - Restaurant has delivery zones set up
   - Fee calculation works based on distance
   - Delivery fee displays in order summary

3. **GPS Tracking:**
   - Rider can share location
   - Real-time updates appear in map (<100ms latency)
   - Location history saves correctly
   - Geofence alerts trigger on zone entry/exit

---

## Phase 6: Deployment to Production

### Prerequisites
- All SQL migrations deployed ✅
- Storage bucket created ✅
- Components integrated ✅
- All tests passing ✅

### Production Deployment Steps

1. **Build the app:**
   ```bash
   npm run build
   ```

2. **Deploy to Vercel/hosting:**
   ```bash
   npm run deploy
   # or use your hosting provider's deploy command
   ```

3. **Run database backups** (Supabase Dashboard → Backups)

4. **Monitor system health** (Check AdminDashboard → System Health tab)

---

## Troubleshooting

### Migration Not Applying
**Problem:** "UUID type not found" or "Function does not exist"
**Solution:**
- Make sure you ran migrations IN ORDER
- Verify PostGIS extension is enabled
- Check that all previous migrations are in the database

### GPS Updates Not Real-Time
**Problem:** Locations aren't updating in <100ms
**Solution:**
- Verify Realtime is enabled: Dashboard → Replication → Check rider_locations, delivery_locations tables
- Check WebSocket connection in browser DevTools → Network → WS
- Ensure JWT token has correct permissions

### Storage Bucket Upload Failing
**Problem:** "Permission denied" when uploading documents
**Solution:**
- Check bucket policies are correct
- Verify bucket is named `documents` (case-sensitive)
- Clear browser cache and try again

### Distance Calculation Wrong
**Problem:** Calculated distance doesn't match real distance
**Solution:**
- Verify coordinates are in correct format (latitude between -90/90, longitude between -180/180)
- Enable PostGIS: Run `SELECT postgis_version();` in SQL editor
- Check SRID is 4326 (WGS84): `SELECT ST_SRID(location) FROM restaurants;`

---

## Performance Optimization

### Database Indexes (Already Applied in Migrations)
- GiST index on `location` (geography) for fast distance queries
- B-tree index on timestamps for history queries
- Composite index on `rider_id, recorded_at` for location history

### Caching Strategy
- Cache restaurant delivery config for 5 minutes
- Subscribe to real-time updates instead of polling
- Use React Query for efficient server state management

### Monitoring
- Check AdminDashboard → System Health for issues
- Monitor real-time subscriptions for memory leaks
- Review LocationHistory for storage patterns

---

## Support & Resources

**Documentation:**
- [Service Provider Verification Guide](./SERVICE_PROVIDER_VERIFICATION_GUIDE.md)
- [GPS Tracking Implementation](./GPS_GUIDE.md)
- [Delivery Fee Configuration](./DELIVERY_PRICING_GUIDE.md)

**APIs Used:**
- Supabase: https://supabase.com/docs
- PostGIS: https://postgis.net/docs/
- Browser Geolocation API: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation

---

## Completion Checklist

- [ ] All 3 SQL migrations deployed
- [ ] Storage bucket created (`documents`)
- [ ] PostGIS extension enabled
- [ ] Components integrated into dashboard pages
- [ ] All tests passing
- [ ] Production deployment complete
- [ ] Monitoring dashboard active
- [ ] Backup strategy configured

**Deployment Date:** February 10, 2026

