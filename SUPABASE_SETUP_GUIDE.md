# Supabase Setup Guide for BusNStay Order Management System

## ✅ Step 1: Supabase Configuration (COMPLETED)

Your Flutter app has been updated with Supabase credentials:
- **Project URL**: `https://ksepddxhvfkjfvnaervh.supabase.co`
- **Anon Key**: Configured in `lib/main.dart`
- **Credentials Location**: `lib/main.dart` → `AppServices.initialize()`

## 📋 Step 2: Run Database Migration (NEXT)

The order management system requires specific database tables. Follow these steps:

### Option A: Using Supabase Dashboard (Easiest)

1. **Open Supabase Dashboard**: https://app.supabase.com/
2. Go to your project: **Zwelt985's Project**
3. Click **SQL Editor** (left sidebar)
4. Click **New query**
5. Copy the SQL from: `supabase/migrations/busnstay_order_management_system.sql`
6. Paste into the editor
7. Click **Run**
8. ✅ Done! Check that you see the success message

### Option B: Using Supabase CLI (Advanced)

```bash
# Install CLI (if not already installed)
npm install -g supabase

# Link to your project
supabase link --project-ref ksepddxhvfkjfvnaervh

# Run migrations
supabase migration list
supabase migration up
```

## 🔄 Step 3: Enable Realtime Subscriptions

The order system requires realtime updates for:
- New orders arriving at restaurants
- Town status changes
- Bus position updates

### Enable Realtime via Dashboard:

1. Go to **Database** → **Publications** (left sidebar)
2. Click **supabase_realtime**
3. Enable (toggle) the following tables:
   - ✅ orders
   - ✅ restaurant_notifications
   - ✅ restaurant_notification_deliveries
   - ✅ journey_towns
   - ✅ town_status_updates

## 📊 Verify Database Setup

Run these checks in Supabase SQL Editor to confirm tables exist:

```sql
-- Check all order management tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
  'orders',
  'restaurant_notifications',
  'restaurant_notification_deliveries',
  'journey_towns',
  'town_status_updates',
  'journeys',
  'restaurants'
);
```

Should return 7 tables. If not all show up, re-run the migration.

## 🧪 Test Connection in Flutter

Your app will automatically test the connection on startup.

### Expected Log Output:

```
🚀 [INIT] Initializing BusNStay services...
🔐 [INIT] Connecting to Supabase...
✅ [INIT] Supabase connected successfully
✅ [INIT] Database service initialized
✅ [INIT] Notification service initialized
✅ [INIT] Town management service initialized
✅ [INIT] Order management service initialized
✅ [INIT] All services initialized successfully!
```

### If You See Errors:

**❌ "Failed to initialize services"**
- Check Supabase credentials in `lib/main.dart`
- Verify project is running (go to Supabase dashboard and check)
- Check internet connection

**❌ "Table not found"**
- Re-run the migration SQL (Step 2)
- Verify tables exist in Supabase SQL Editor

**❌ "Permission denied"**
- Check Row-Level Security (RLS) policies
- Go to **Database** → **Authentication** and verify policies

## 🔐 Security Configuration (Optional but Recommended)

### Configure API Gateway:
1. Go to **Authentication** → **Policies**
2. For `orders` table, add policy:
   - **Authenticated users** can SELECT/INSERT their own orders
   - **Restaurants** can SELECT their own orders

### Example Policy SQL:
```sql
-- Users can see orders they created
CREATE POLICY "Users view own orders" ON orders
  FOR SELECT USING (auth.uid() = user_id);

-- Restaurants can see their notifications
CREATE POLICY "Restaurants view own notifications" ON restaurant_notifications
  FOR SELECT USING (auth.uid() = restaurant_id);
```

## 🚀 Next Steps After Setup

1. ✅ Flutter app automatically connects to Supabase on startup
2. Create test journey with towns (use BusOperatorDashboardPage)
3. Create test order (use OrderCheckoutPage)
4. Verify restaurant notification received (use RestaurantDashboardPage)
5. Test auto-close algorithm with position updates

## 📞 Troubleshooting

### Connection Issues?
- Check that `https://ksepddxhvfkjfvnaervh.supabase.co` is accessible
- Verify credentials are not changed/regenerated
- Check Flutter app has internet permission (check AndroidManifest.xml)

### Orders Not Appearing?
- Verify realtime publications are enabled
- Check that Supabase is not rate-limiting requests
- Check app logs for errors

### Notifications Not Working?
- Verify `restaurant_notifications` table exists
- Check that restaurants have valid `id` field
- Verify Twilio credentials (when configured - see next section)

## 📧 Configure External Notifications (Optional)

To enable real WhatsApp/SMS notifications:

1. **Get Twilio Account**: https://www.twilio.com/
2. Update credentials in `lib/services/restaurant_notification_service.dart`:
   ```dart
   static const String TWILIO_ACCOUNT_SID = 'your_account_sid';
   static const String TWILIO_AUTH_TOKEN = 'your_auth_token';
   static const String TWILIO_PHONE_NUMBER = '+1234567890';
   ```
3. Test with `notifyRestaurantOrderPlaced()`

## ✅ Verification Checklist

- [ ] Supabase credentials added to Flutter app
- [ ] Database migration SQL executed successfully
- [ ] All 7 tables created in Supabase
- [ ] Realtime publications enabled for 5 key tables
- [ ] Flutter app logs show successful initialization
- [ ] Test journey created in BusOperatorDashboardPage
- [ ] Test order created without errors
- [ ] Restaurant notification received (check database)

## 🎉 Success!

Once all checks pass, your BusNStay order management system is fully operational!

---

**Questions or Issues?** Check the logs in Flutter console for specific error messages.
**Need to reset?** Go to Supabase → Database Wipe and re-run migrations.
