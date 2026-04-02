# BusNStay Deployment Checklist (April 2026)

## ⚡ Quick Start: Deploy Everything in 2.5 Hours

### Prerequisites (Do First)
- [ ] Flutterwave account created (https://dashboard.flutterwave.com/signup)
- [ ] API keys generated (Settings → API Keys)
- [ ] Test keys ready (FK_TEST_xxxxx, SK_TEST_xxxxx)
- [ ] Access to Supabase dashboard
- [ ] VS Code project open at `c:\Users\zwexm\LPSN\busnstay-journey-map-main\`

---

## 🗓️ Phase 1: Database Setup (25 minutes)

### Step 1.1: Apply Restaurant Approval Migration (5 min)
```bash
# Time: 5 minutes
File: supabase/migrations/20260401_restaurant_approval_workflow.sql

Steps:
1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Copy/paste entire file contents
4. Click "Run"
5. Wait for "Command completed" message

Verify:
✓ Table 'restaurants' updated with is_approved column
✓ Table 'restaurant_approval_logs' created
✓ New functions created (check Functions section)
✓ Triggers active (check Triggers section)
```

### Step 1.2: Apply Hotel Room Schema Migration (5 min)
```bash
# Time: 5 minutes
File: supabase/migrations/20260401_hotel_room_management.sql

Steps:
1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Copy/paste entire file contents
4. Click "Run"

Verify:
✓ Tables created: hotel_rooms, room_reviews, room_availability, room_rate_history
✓ Functions: get_available_rooms(), update_room_average_rating()
✓ Triggers active
✓ Sample data loaded (5 rooms)
✓ RLS policies applied
```

### Step 1.3: Apply Payment System Migration (15 min)
```bash
# Time: 15 minutes
File: supabase/migrations/20260401_flutterwave_payment_system.sql

Steps:
1. Open Supabase Dashboard → SQL Editor
2. Create new query
3. Copy/paste entire file contents
4. Click "Run"

Verify:
✓ Tables created:
  - payment_transactions
  - payment_logs
  - payment_retries
  - payment_disputes
✓ Views created:
  - payment_analytics
  - payment_success_rate
✓ Functions created
✓ RLS policies applied
```

**checkpoint**: All 3 migrations complete. Total: 25 minutes ✅

---

## 📦 Phase 2: Copy Files (10 minutes)

### Step 2.1: Copy Service Files (5 min)
```bash
# Copy from delivery to project:

src/services/paymentService.ts
✓ File: paymentService.ts
✓ Lines: 700+
✓ Functions: initiatePayment, verifyPayment, processRefund, etc.

src/services/revenueService.ts
✓ File: revenueService.ts
✓ Lines: 600+
✓ Functions: getRevenueAnalytics, getTopAccommodations, etc.

Existing (already may exist):
✓ roadRoutingService.ts
✓ restaurantApprovalService.ts
✓ hotelRoomService.ts
```

### Step 2.2: Copy Component Files (3 min)
```bash
# Copy to project:

src/components/PaymentModal.tsx
✓ File: PaymentModal.tsx
✓ Lines: 400+
✓ Features: Payment method selection, card entry, processing UI

src/components/RoomManagementTab.tsx
✓ File: RoomManagementTab.tsx (if not present)
✓ Lines: 400+
✓ Features: Add/edit/delete rooms, status management
```

### Step 2.3: Update Existing Files (2 min)
```bash
# Update in project:

src/pages/HotelDashboard.tsx
BEFORE: Only has 2 tabs (Bookings, Calendar)
CHANGE: Add "Rooms" tab with RoomManagementTab component
AFTER: Has 3 tabs (Bookings, Rooms, Calendar) ✓

Changes needed:
1. Add import: import RoomManagementTab from '@/components/RoomManagementTab';
2. Add tab trigger: <TabsTrigger value="rooms">Rooms</TabsTrigger>
3. Add tab content: <TabsContent value="rooms">{accommodationId && <RoomManagementTab accommodationId={accommodationId} />}</TabsContent>
```

**Checkpoint**: All files in place. Total: 10 minutes ✅

---

## ⚙️ Phase 3: Environment Setup (5 minutes)

### Step 3.1: Create .env.local File
```bash
# Time: 2 minutes
Location: Project root (same level as package.json)
File name: .env.local

Content:
```
VITE_FLUTTERWAVE_PUBLIC_KEY=FK_TEST_xxxxxxxxxxxxxxxxxxxx
VITE_FLUTTERWAVE_SECRET_KEY=SK_TEST_xxxxxxxxxxxxxxxxxxxx
VITE_FLUTTERWAVE_API_BASE_URL=https://api.flutterwave.com/v3
```

Instructions:
1. Create new file: `.env.local`
2. Copy above content
3. Replace xxxx with your actual test keys from Flutterwave dashboard
4. **DO NOT** commit this file (add to .gitignore)
5. Save file
```

### Step 3.2: Update .gitignore (1 min)
```bash
# Make sure .env.local is ignored:
echo ".env.local" >> .gitignore

Verify:
cat .gitignore | grep "env.local"
# Should show: .env.local
```

### Step 3.3: Verify package.json Has Required Dependencies (2 min)
```bash
# Check these are in package.json:
✓ "react": "^18.x"
✓ "typescript": "^5.x"
✓ "@supabase/supabase-js": "^2.x"
✓ "framer-motion": "^10.x"
✓ "lucide-react": "^0.x"

If any missing:
npm install framer-motion lucide-react
```

**Checkpoint**: Environment configured. Total: 5 minutes ✅

---

## 🔨 Phase 4: Build & Local Test (20 minutes)

### Step 4.1: Build TypeScript (10 min)
```bash
# Time: 10 minutes
Command: npm run build

Expected Output:
✓ Compiling...
✓ Successfully compiled
✓ No TypeScript errors

If errors:
1. Check file imports are correct
2. Verify all service files in src/services/
3. Verify all components in src/components/
4. Check @/ path aliases configured in tsconfig
```

### Step 4.2: Start Dev Server (5 min)
```bash
# Time: 5 minutes
Command: npm run dev

Expected Output:
✓ VITE v4.x.x  ready in xxx ms
✓ Local:   http://localhost:5173/
✓ Opening browser...

Window opens to: http://localhost:5173/
```

### Step 4.3: Manual Smoke Test (5 min)
```bash
# Test each major feature:

TEST 1: Login
✓ Can log in with test account
✓ Dashboard loads without errors

TEST 2: Hotel Features  
✓ Navigate to Hotel Dashboard
✓ Can see Bookings tab
✓ Can see NEW "Rooms" tab
✓ Click Rooms → should load room management UI
✓ Can see "Add Room" button
✓ Try adding a test room (Room 101, Double, K250)
✓ Room appears in grid

TEST 3: Payment
✓ Try booking a room
✓ Click "Proceed to Payment"
✓ PaymentModal should appear
✓ Can see payment method options
✓ Can see amount and fees
✓ Select payment method
✓ UI responds correctly

TEST 4: Console Check
✓ Open DevTools (F12)
✓ Go to Console tab
✓ Should be no RED errors
✓ Green checkmarks for service loads OK
```

**Checkpoint**: Local build successful. Total: 20 minutes ✅

---

## 🚀 Phase 5: Staging Deployment (30 minutes)

### Step 5.1: Commit Changes (5 min)
```bash
# Time: 5 minutes
Commands:
git add .
git commit -m "Deploy: Complete payment and hotel features (Apr 2026)"
git push origin main

Expected:
✓ All changes committed
✓ No uncommitted files
✓ Push successful
```

### Step 5.2: Deploy to Staging (15 min)
```bash
# Time: 15 minutes
# Depends on your hosting (Vercel, Netlify, etc.)

For Vercel:
1. Vercel automatically deploys on push
2. Go to vercel.com → your project
3. Wait for deployment to complete
4. Check: ✓ Stage environment updated

For Netlify:
1. netlify deploy --prod --dir=dist

For other hosts:
1. npm run build
2. Upload dist/ folder to hosting
3. Set environment variables in hosting dashboard
```

### Step 5.3: Test Staging (10 min)
```bash
# Time: 10 minutes
# Test on staging URL (e.g., staging.yourapp.com)

Repeat smoke tests from Phase 4.3 on staging environment:
✓ Login works
✓ Hotel Rooms tab loads
✓ Add room works
✓ Payment modal appears
✓ No console errors
```

**Checkpoint**: Staging deployment complete. Total: 30 minutes ✅

---

## 🎯 Phase 6: Production Deployment (45 minutes)

### Step 6.1: Database Backup (5 min)
```bash
# Time: 5 minutes
# Safety first!

Steps:
1. Supabase Dashboard → Database → Backups
2. Click "Start backup"
3. Wait for "Backup complete" message
4. Note the backup date/time

Verify:
✓ Backup completed successfully
```

### Step 6.2: Production Environment Variables (3 min)
```bash
# Time: 3 minutes
# Update environment variables in hosting dashboard

For Vercel/Netlify:
1. Go to hosting dashboard
2. Settings → Environment Variables
3. Update:
   - VITE_FLUTTERWAVE_PUBLIC_KEY=FK_TEST_xxxxx (or FK_LIVE_ for production)
   - VITE_FLUTTERWAVE_SECRET_KEY=SK_TEST_xxxxx
4. Save

Note: For full production, use FK_LIVE_ and SK_LIVE_ keys
```

### Step 6.3: Production Code Deployment (10 min)
```bash
# Time: 10 minutes
# Deploy to production

For Vercel:
1. Create release tag: git tag -a v2.0.0 -m "Complete platform"
2. git push origin v2.0.0
3. Vercel automatically deploys
4. Monitor: vercel.com dashboard

For other hosts:
1. npm run build
2. Upload dist/ to production
3. Verify upload complete
```

### Step 6.4: Production Verification (15 min)
```bash
# Time: 15 minutes
# Test on production URL

Critical Tests:
✓ Login works
✓ Hotel Dashboard loads
✓ Rooms tab appears and functions
✓ Add/edit/delete rooms works
✓ Payment modal opens
✓ Can select payment methods
✓ No console errors
✓ Check payment_transactions table has test records

Monitor Errors:
1. Supabase Statistics → Check for errors
2. Check logs: Supabase Dashboard → Logs
3. Browser console: No red errors
```

### Step 6.5: Communicate Launch (5 min)
```bash
# Time: 5 minutes
# Let users know!

Send to:
- [ ] Client: "Features live and tested"
- [ ] Team: "v2.0.0 deployed successfully"
- [ ] Users: Optional announcement email

Message Template:
"We've rolled out hotel management, mobile money payments, and revenue analytics. 
Available now: Hotel Dashboard Rooms tab, Flutterwave payments, revenue tracking.
Questions? Contact support."
```

**Checkpoint**: Production deployment complete. Total: 45 minutes ✅

---

## 🎉 Deployment Complete!

**Total Time**: ~2.5 hours  
**Status**: All 9 features live ✅

### Post-Deployment (First 24 Hours)
- [ ] Monitor error logs every hour
- [ ] Check payment transactions processing correctly
- [ ] Verify room bookings working
- [ ] Respond to any user issues immediately
- [ ] Collect user feedback

### Post-Deployment (First Week)
- [ ] Weekly check-in on performance metrics
- [ ] Review revenue reports
- [ ] Fix any bugs reported
- [ ] Gather usage statistics
- [ ] Plan Phase 2 enhancements

---

## 📞 Emergency Support

### If Deployment Fails

**Database Migration Failed**:
1. Check Supabase SQL error message
2. Verify file syntax (look for commas, semicolons)
3. Try running in fresh Supabase project first
4. Contact Supabase support

**Build Fails**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules
npm install
npm run build
```

**Payment Integration Not Working**:
1. Verify VITE_FLUTTERWAVE_PUBLIC_KEY is set
2. Check Flutterwave dashboard Settings → Keys
3. Ensure API keys are for correct environment (TEST vs LIVE)
4. Look for network errors in browser DevTools

**Room Management Not Showing**:
1. Check RoomManagementTab.tsx is in src/components/
2. Verify HotelDashboard.tsx has correct import
3. Check browser console for React errors

### Contact
- **Flutterwave**: support@flutterwave.com | https://support.flutterwave.com
- **Supabase**: support@supabase.com | Discord community
- **Team**: Message group chat

---

## ✅ Final Checklist

Before declaring deployment complete, verify:

### Features Working
- [ ] Location validation blocks wrong locations
- [ ] Route maps show real road geometry
- [ ] Only approved restaurants display
- [ ] Hotel rooms CRUD working
- [ ] Room management UI responsive
- [ ] Payment modal appears and functions
- [ ] Revenue analytics calculate correctly

### Security
- [ ] Payment credentials not in git
- [ ] RLS policies applied to all tables
- [ ] Admin-only features protected
- [ ] Data encryption working

### Performance
- [ ] Page loads < 2 seconds
- [ ] Room list loads < 500ms
- [ ] Payment modal responsive
- [ ] No console errors

### Documentation
- [ ] Deployment guide complete
- [ ] Payment setup documented
- [ ] Team trained on new features
- [ ] User guides available

---

## 🎊 Deployment Success!

**Date**: April 1, 2026  
**Version**: v2.0.0  
**Features Deployed**: 9/9 ✅  
**Status**: LIVE ✅  

**Open Champagne! 🍾**

---

For detailed guides, see:
- FLUTTERWAVE_PAYMENT_INTEGRATION.md (Setup)
- HOTEL_FEATURES_DEPLOYMENT.md (Hotel features)
- PROJECT_FINAL_COMPLETION_REPORT.md (Full overview)

**Happy Launching! 🚀**
