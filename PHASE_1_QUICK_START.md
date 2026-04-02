# Phase 1 - Quick Start Guide (30 Minutes)

**Start here to integrate Phase 1 into your app.**

---

## 📋 The 5 Steps

### Step 1: Deploy Database (5 min)

Go to **Supabase Dashboard** → **SQL Editor** → **New Query**

Copy-paste entire contents of:  
📄 `supabase/migrations/001_core_schema.sql`

Click **RUN** → Wait for green checkmark ✅

**Check:** In `Table Editor`, you should see 8 new tables:
- journeys
- orders
- offline_queue
- towns_on_route
- location_history
- restaurants
- riders
- restaurant_notifications

---

### Step 2: Deploy Edge Functions (5 min)

In terminal:
```bash
cd c:\Users\zwexm\LPSN\busnstay-journey-map-main

# Deploy location update function
npx supabase functions deploy update-location

# Deploy SMS function  
npx supabase functions deploy send-sms
```

**Check:** In Supabase Dashboard → **Functions**, both should show "✅ Deployed"

---

### Step 3: Install Capacitor (5 min)

```bash
npm install -D @capacitor/cli @capacitor/core @capacitor/geolocation @capacitor/app

# Initialize
npx cap init BusNStay com.busnstay.delivery

# Add platforms
npx cap add ios
npx cap add android
```

**Check:** New folder created: `ios/` and `android/`

---

### Step 4: Add Hooks to Your Component (10 min)

In your main delivery/journey component:

```typescript
import { useJourneyState } from '@/hooks/useJourneyState';
import { useBackgroundTracking } from '@/hooks/useBackgroundTracking';
import { useOrderSync } from '@/hooks/useOrderSync';
import { useAuth } from '@/hooks/useAuth'; // Your existing auth hook

export function DeliveryTrackerScreen() {
  // Get current user
  const { user } = useAuth();
  
  // Journey management
  const {
    journey,
    startJourney,
    endJourney,
    updateLocation,
    queueStats,
    isLoading: journeyLoading,
    error: journeyError,
  } = useJourneyState(user?.id);

  // GPS tracking
  const {
    isTracking,
    lastLocation,
    startTracking,
    stopTracking,
  } = useBackgroundTracking(
    // This callback fires when GPS updates
    async (location) => {
      if (journey) {
        await updateLocation(
          location.latitude,
          location.longitude,
          location.accuracy
        );
      }
    }
  );

  // Order management
  const deviceId = localStorage.getItem('device_id') || 'unknown';
  const {
    orders,
    createOrder,
    pendingOrdersCount,
    isLoading: ordersLoading,
  } = useOrderSync(user?.id, deviceId);

  // Handle start journey button
  const handleStartJourney = async () => {
    try {
      const newJourney = await startJourney(
        'from_stop_id_here', // Replace with actual
        'to_stop_id_here',   // Replace with actual
        'bus_id_here'        // Replace with actual
      );

      // Start GPS tracking
      await startTracking({
        journeyId: newJourney.id,
        updateInterval: 30000, // Update every 30 seconds
        enableHighAccuracy: true, // Use GPS
      });
    } catch (error) {
      console.error('Failed to start journey:', error);
      alert(`Error: ${error.message}`);
    }
  };

  // Handle end journey button
  const handleEndJourney = async () => {
    try {
      await stopTracking();
      await endJourney();
      alert('Journey completed!');
    } catch (error) {
      console.error('Failed to end journey:', error);
    }
  };

  // Handle create order
  const handleCreateOrder = async (restaurantId, items, total) => {
    try {
      const order = await createOrder({
        journey_id: journey.id,
        restaurant_id: restaurantId,
        passenger_id: user.id,
        stop_id: 'current_town_id', // Get from UI
        items: items,
        total_amount: total,
        status: 'PENDING',
      });
      
      alert(`Order created! (${pendingOrdersCount} awaiting sync)`);
    } catch (error) {
      console.error('Failed to create order:', error);
    }
  };

  // Render UI
  if (journeyLoading) return <div>Loading...</div>;

  return (
    <div className="delivery-tracker">
      <h1>Journey Tracker</h1>

      {!journey ? (
        // No active journey - show start button
        <button onClick={handleStartJourney} disabled={journeyLoading}>
          {journeyLoading ? 'Starting...' : '▶️ Start Journey'}
        </button>
      ) : (
        // Active journey - show status
        <div>
          <h2>Journey Active ✅</h2>
          
          {isTracking && <p>📍 GPS Tracking Active</p>}
          {!isTracking && <p>⚠️ GPS Not Tracking</p>}
          
          {lastLocation && (
            <p>
              📍 Location: {lastLocation.latitude.toFixed(4)}, {lastLocation.longitude.toFixed(4)}
              <br />
              Accuracy: ±{lastLocation.accuracy.toFixed(0)}m
            </p>
          )}

          <h3>Queue Status</h3>
          <p>
            Total operations: {queueStats.total}
            <br />
            Pending sync: {queueStats.pending}
            <br />
            Synced: {queueStats.synced}
          </p>

          {pendingOrdersCount > 0 && (
            <div className="warning">
              ⚠️ {pendingOrdersCount} pending orders (will sync when online)
            </div>
          )}

          <h3>Orders</h3>
          <div>
            {orders.map((order) => (
              <div key={order.id || order.offline_id} className="order-item">
                <p>Restaurant: {order.restaurant_id}</p>
                <p>Total: ${order.total_amount}</p>
                <p>Status: {order.status}</p>
                {order.offline_created && <p>⚡ (Offline)</p>}
              </div>
            ))}
          </div>

          <button onClick={handleEndJourney} className="danger">
            🏁 End Journey
          </button>
        </div>
      )}

      {journeyError && <div className="error">Error: {journeyError}</div>}
      {ordersLoading && <p>Loading orders...</p>}
    </div>
  );
}
```

---

### Step 5: Configure Environment (5 min)

Create/update `.env.local`:

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGc...your-key-here

# For SMS (optional for now, needed for Phase 2)
VITE_AFRICA_TALKING_USERNAME=your-username
VITE_AFRICA_TALKING_API_KEY=your-api-key
```

---

## ✅ Test It Now

### Quick Test 1: Journey Persistence
1. Click "Start Journey"
2. See location updating
3. Close browser tab completely
4. Reopen
5. **Expected:** Journey screen appears immediately ✅

### Quick Test 2: Offline Orders
1. Turn off WiFi
2. Create order (button in form)
3. See "Order created ⚡"
4. Turn WiFi back on
5. **Expected:** Order synced, no "⚡" symbol ✅

### Quick Test 3: GPS Continues
1. Start journey
2. Minimize app (don't close)
3. Leave app in background for 1 minute
4. Reopen
5. **Expected:** Location is current ✅

---

## 🆘 If Something Breaks

### "Unauthorized" Error
**Solution:** Check Supabase anon key in `.env.local`

### "journeys table not found"
**Solution:** Run SQL migration again in Supabase SQL Editor

### GPS not updating
**Solution:** Check permissions granted on phone/browser

### Orders not syncing
**Solution:** Check online status: `console.log(navigator.onLine)`

### SMS not sending
**Solution:** Skip for now, implement in Phase 2

---

## 📱 Next: Build Mobile App

Once tested in browser:

```bash
# Build for production
npm run build

# Copy to native apps
npx cap copy

# Open iOS app in Xcode
npx cap open ios

# Open Android app in Android Studio
npx cap open android
```

---

## 📚 Full Docs

- **Integration Details:** → `PHASE_1_IMPLEMENTATION_GUIDE.md`
- **Architecture Overview:** → `PHASE_1_BUILD_COMPLETE.md`
- **Database Schema:** → `supabase/migrations/001_core_schema.sql`

---

## 🎯 What You Should See

After integration:

```
✅ Journey starts on "▶️ Start Journey" click
✅ GPS updates appear in real-time
✅ Queue shows pending operations
✅ App auto-restores journey on reopen
✅ Orders created offline, synced on reconnect
✅ No data lost when offline
```

---

**Ready?** Start with Step 1. Should be done in 30 minutes!

If you get stuck, check the "Full Docs" section above.

**Good luck! 🚀**
