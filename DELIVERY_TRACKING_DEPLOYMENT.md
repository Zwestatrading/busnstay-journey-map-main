# 🚀 Delivery Tracking - Deployment Checklist

## Phase 1: Pre-Deployment (Local Testing)

### Database Setup
- [ ] Run migration SQL: `supabase/migrations/add_delivery_tracking.sql`
  - [ ] Verify 3 tables created: `rider_locations`, `delivery_jobs`, `delivery_routes`
  - [ ] Verify RLS enabled: `SELECT tablename FROM pg_tables WHERE rowsecurity = true;`
  - [ ] Verify Realtime enabled: Check publication in Supabase dashboard

```sql
-- Run these checks:
SELECT COUNT(*) FROM pg_tables WHERE tablename IN ('rider_locations', 'delivery_jobs', 'delivery_routes');
-- Should return 3
```

### Environment Configuration
- [ ] Add to `.env.local`:
  ```env
  VITE_GOOGLE_MAPS_API_KEY=sk-xxx...
  VITE_SUPABASE_URL=https://xxx.supabase.co
  VITE_SUPABASE_ANON_KEY=eyxxx...
  ```
- [ ] Verify values are correct (no typos, proper format)
- [ ] Do NOT commit `.env.local` to git

### Code Integration
- [ ] Verify route added to `App.tsx`:
  ```tsx
  <Route path="/rider/delivery/:jobId" element={<DeliveryTracker />} />
  ```
- [ ] Verify imports exist in `App.tsx`:
  ```tsx
  import DeliveryTracker from "./pages/DeliveryTracker";
  ```
- [ ] Run compilation check:
  ```bash
  npm run build
  ```
  - [ ] Zero errors reported
  - [ ] Zero warnings (optional, but recommended)

### Local Testing
- [ ] Start dev server:
  ```bash
  npm run dev
  ```
- [ ] Navigate to app: `http://localhost:8081`
- [ ] Create test delivery job in database:
  ```sql
  INSERT INTO delivery_jobs (rider_id, order_id, status, origin_stop_id, destination_stop_id)
  VALUES ('test-rider-id', 'test-order-1', 'accepted', 'stop-1', 'stop-2');
  ```
- [ ] Navigate to tracking page: `/rider/delivery/{job-id}`
- [ ] Browser permission prompt appears → Click "Allow"
- [ ] Blue marker appears on map
- [ ] Marker has pulsing animation
- [ ] Timestamp updates every ~10 seconds
- [ ] Check database for location updates:
  ```sql
  SELECT * FROM rider_locations ORDER BY timestamp DESC LIMIT 1;
  ```

### Real-device Testing
- [ ] Build for production:
  ```bash
  npm run build
  ```
- [ ] Serve locally:
  ```bash
  npm run preview
  ```
- [ ] Get local IP:
  ```bash
  ipconfig getifaddr en0  # macOS
  # or
  hostname -I            # Linux
  # or check Settings on Windows
  ```
- [ ] On mobile, navigate to: `http://{your-ip}:4173/rider/delivery/{job-id}`
- [ ] Allow location permission
- [ ] Verify marker moves on map
- [ ] Check speed and accuracy stats display

### Component Testing
- [ ] Click on a station in timeline → Expands
- [ ] Station shows two tabs (mock UI confirmed)
- [ ] Click "View Restaurants" → Shows placeholder (or real data if implemented)
- [ ] Click "Contact Agent" → TextCallCentre appears
- [ ] Map shows:
  - [ ] Blue circle (current location)
  - [ ] Green arrow (destination)
  - [ ] Amber circles (restaurants at stops)
  - [ ] Gray circles (stops without restaurants)
- [ ] Polyline connects all waypoints
- [ ] Zoom adjusts to show entire route

---

## Phase 2: Production Preparation

### Code Review
- [ ] Review `src/pages/DeliveryTracker.tsx` - No test data hardcoded
- [ ] Review `src/hooks/useDeliveryTracking.ts` - All Realtime subscriptions cleaned up on unmount
- [ ] Review `src/components/JourneyMap.tsx` - API key from environment variable
- [ ] Verify no console errors: `grep -r "console.log" src/`
- [ ] Verify error boundaries exist:
  - [ ] GPS errors handled in `useRiderLocation`
  - [ ] Job not found shows error card
  - [ ] Map API failures handled

### Security Audit
- [ ] No API keys hardcoded anywhere
- [ ] RLS policies check user authentication:
  - [ ] Riders see only own location ✅
  - [ ] Riders see only own jobs ✅
  - [ ] Restaurants see riders at their stops ✅
  - [ ] Admins see all locations ✅
- [ ] Do NOT expose database secrets in client code
- [ ] Environment variables are properly scoped (VITE_ prefix for client)

```bash
# Search for hardcoded secrets
grep -r "sk-" src/
grep -r "sb_" src/
grep -r "Bearer" src/
# Should return ZERO results
```

### Performance Optimization
- [ ] Verify GPS update interval is 10+ seconds (battery-friendly)
- [ ] Verify subscriptions are cleaned up on unmount:
  ```tsx
  useEffect(() => {
    return () => channel.unsubscribe();  // ← This line exists
  }, []);
  ```
- [ ] Verify no unnecessary re-renders (use React DevTools Profiler)
- [ ] Verify bundle size is acceptable:
  ```bash
  npm run build
  # Check dist/ folder size
  ```

### Documentation
- [ ] Update team docs with new routes
- [ ] Add FAQ section for common issues
- [ ] Document API contract (what data DeliveryTracker expects)
- [ ] Add monitoring alerts (GPS errors, failed Realtime connections)

---

## Phase 3: Production Deployment

### Supabase Production Setup
- [ ] Create new Supabase project (or use production one)
- [ ] Run migration SQL in production database:
  ```sql
  -- Copy entire add_delivery_tracking.sql
  -- Paste into SQL Editor
  -- Run
  ```
- [ ] Verify in production:
  ```sql
  SELECT COUNT(*) FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name IN ('rider_locations', 'delivery_jobs', 'delivery_routes');
  -- Should return 3
  ```
- [ ] Check Realtime publication:
  ```sql
  SELECT * FROM pg_publication;
  -- Should include your tables
  ```

### Google Maps API
- [ ] Go to Google Cloud Console
- [ ] Enable "Maps JavaScript API"
- [ ] Create API key (or use existing)
- [ ] Add HTTP restrictions:
  - [ ] Add production domain: `yourdomain.com`
  - [ ] Add Vercel preview domains: `*.vercel.app`
- [ ] Save API key (keep secret!)
- [ ] Test API key works:
  ```bash
  curl "https://maps.googleapis.com/maps/api/js?key=YOUR_KEY&libraries=maps"
  ```

### Deployment Platform Setup
Choose one:

#### Option A: Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel

# Add environment variables in Vercel dashboard:
VITE_GOOGLE_MAPS_API_KEY=xxx
VITE_SUPABASE_URL=xxx
VITE_SUPABASE_ANON_KEY=xxx
```

#### Option B: Netlify
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Connect repo
netlify init

# Add environment variables in Netlify dashboard
# Deploy
netlify deploy
```

#### Option C: Docker
```dockerfile
# Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY . .
RUN npm install && npm run build
EXPOSE 3000
CMD ["npm", "run", "preview"]
```

### Environment Variables (Production)
Add to your deployment platform:
```
VITE_GOOGLE_MAPS_API_KEY=sk-xxxxxxxxxxxxxxx
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJxxx...
```

### SSL/TLS Certificate
- [ ] Requires HTTPS (geolocation API requirement)
- [ ] Automatic with Vercel/Netlify
- [ ] If self-hosted: use Let's Encrypt or similar
- [ ] Test HTTPS works:
  ```bash
  curl -I https://yourdomain.com
  # Should show 200 OK
  ```

---

## Phase 4: Post-Deployment Testing

### Smoke Tests
- [ ] Website loads without errors
- [ ] Navigation works: `/rider/delivery/test-job-id`
- [ ] Page shows loading state initially
- [ ] Map appears within 5 seconds
- [ ] No console errors present

### Feature Tests
- [ ] Create real delivery job
- [ ] Navigate to tracking page
- [ ] Location permission prompt appears
- [ ] Allow → GPS tracking starts
- [ ] Marker appears on map
- [ ] Marker updates every 10 seconds
- [ ] Check database shows location updates
- [ ] Timeline shows stops correctly
- [ ] Click stop → expands with tabs
- [ ] Restaurant tab accessible
- [ ] Contact agent tab accessible

### Performance Tests
- [ ] Initial page load < 3 seconds
- [ ] Map interaction smooth (60 FPS)
- [ ] No memory leaks (check DevTools → Memory)
- [ ] No console warnings
- [ ] GPS updates don't cause jank
- [ ] Works on mobile (4G connection)

### Browser Compatibility
- [ ] Chrome (latest) ✅
- [ ] Firefox (latest) ✅
- [ ] Safari (iOS 14+) ✅
- [ ] Samsung Internet ✅
- [ ] Edge ✅

### Mobile Testing
- [ ] Test on iPhone (iOS 14+)
- [ ] Test on Android (API 28+)
- [ ] Test on slow 4G connection
- [ ] Test with battery saver enabled
- [ ] Test after app backgrounded for 5 minutes

---

## Phase 5: Monitoring & Maintenance

### Setup Monitoring
- [ ] Error tracking: Sentry/LogRocket
  ```tsx
  // In main.tsx
  import * as Sentry from "@sentry/react";
  Sentry.init({ dsn: "..." });
  ```
- [ ] Performance monitoring
- [ ] Database connection health
- [ ] Realtime subscription status

### Create Alerts
- [ ] Alert if Realtime subscriptions fail
- [ ] Alert if GPS errors > 5% of sessions
- [ ] Alert if API response time > 2s
- [ ] Alert if database is disconnected

### Database Maintenance
```sql
-- Weekly: Check for orphaned location data
SELECT COUNT(*) FROM rider_locations 
WHERE timestamp < NOW() - INTERVAL '7 days';

-- Monthly: Clean up old routes
DELETE FROM delivery_routes 
WHERE created_at < NOW() - INTERVAL '30 days';

-- Check indexes are working
SELECT idx, idx_size FROM show_index_sizes();
```

### Backup Strategy
- [ ] Supabase auto-backups enabled (Pro tier minimum)
- [ ] Test restore from backup monthly
- [ ] Keep 30-day backup history
- [ ] Backup API keys separately

### Documentation
- [ ] Create runbook for common issues
- [ ] Document escalation procedure
- [ ] Add dashboard for real-time monitoring
- [ ] Keep changelog updated

---

## Phase 6: Optimization (After Launch)

### Performance Improvements
- [ ] Analyze which routes are most popular
- [ ] Cache stop data (don't refetch each trip)
- [ ] Batch location updates if > 1000 riders
- [ ] Use service worker for offline support

### Feature Enhancements
- [ ] Add offline mode (cache last known location)
- [ ] Add battery monitoring
- [ ] Add signal strength indicator
- [ ] Implement order pickup confirmation with photo

### Analytics
- [ ] Track GPS accuracy metrics
- [ ] Track delivery completion rates
- [ ] Track realtime latency percentiles
- [ ] Track restaurant fulfillment times

---

## Rollback Plan

If production deployment fails:

```bash
# 1. Check current deployment
vercel ls

# 2. View previous deployments
vercel deployments

# 3. Rollback to previous version
vercel promote <deployment-url>

# 4. Or restore from GitHub
git revert <commit-hash>
git push origin main
```

---

## Success Criteria ✅

After deployment, verify:
- [ ] 100 test tracked successfully
- [ ] Location accuracy within ±50m
- [ ] Realtime updates < 500ms latency
- [ ] Zero critical console errors
- [ ] All permission prompts working
- [ ] Mobile experience smooth
- [ ] Database queries < 500ms
- [ ] No unhandled promise rejections

---

## Contacts & Support

| Issue | Contact | Channel |
|-------|---------|---------|
| Supabase outage | Supabase Support | status.supabase.com |
| Google Maps API | Google Cloud Support | console.cloud.google.com |
| Application errors | Your team | Sentry/LogRocket |
| Database performance | Supabase | Dashboard |

---

## Maintenance Schedule

| Task | Frequency | Owner |
|------|-----------|-------|
| Update dependencies | Monthly | Dev team |
| Monitor errors | Daily | Ops team |
| Review logs | Weekly | Dev team |
| Test failover | Monthly | Ops team |
| Update documentation | Per release | Dev team |
| Security audit | Quarterly | Security team |

---

**Deployment Status:** Ready ✅  
**Version:** 1.0  
**Last Updated:** February 2026

**Questions?** See `DELIVERY_TRACKING_INTEGRATION.md` for detailed reference.
