# Wati WhatsApp Integration Guide

## 🎉 Wati is Now Integrated!

Your BusNStay app now supports **Wati** for WhatsApp restaurant notifications. This is a free/cheap alternative to Twilio.

## ✅ Quick Start (5 minutes)

### Step 1: Create Wati Account
1. Go to https://www.wati.io/
2. Sign up (free account)
3. Connect your WhatsApp Business Account
4. Verify your phone number

### Step 2: Get API Credentials
1. In Wati dashboard, go to **Settings** → **API**
2. Copy your **API Key**
3. Copy your **Phone Number ID** (from WhatsApp Business Account)

### Step 3: Configure in Flutter App
Update `lib/main.dart` line 58:

```dart
// Before AppServices.initialize(), uncomment and add your credentials:
RestaurantNotificationService.initializeWati(
  apiKey: 'your_wati_api_key_here',
  phoneNumberId: 'your_phone_number_id_here',
);
```

Full example:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Wati (optional - for WhatsApp notifications)
  RestaurantNotificationService.initializeWati(
    apiKey: 'abc123def456...',
    phoneNumberId: '1234567890123',
  );
  
  await AppServices.initialize();
  runApp(const BusNStayApp());
}
```

### Step 4: Build & Test
```bash
flutter run
```

Check logs for:
```
📱 [WATI] Status: Configured ✅
💬 [WATI] Sending WhatsApp to +265977123456...
✅ [WATI] WhatsApp sent successfully.
```

## 🧪 Test Flow

1. **Start the app** - Check WATI status in logs
2. **Create an order** - RestaurantDashboardPage
3. **Check restaurant WhatsApp** - You should get a message!

### Test Numbers
- Use your own number for testing
- Wati free tier: 1,000 messages/month
- After: $20/month unlimited

## 📊 Pricing Comparison

| Provider | Free Tier | Then | Best For |
|----------|-----------|------|----------|
| **Wati** | 1,000/mo | $20/mo | Startups, fast setup |
| Twilio | None | $0.005/msg | Enterprise, flexibility |
| Meta WhatsApp API | None | $0.001/msg | High volume (1M+) |
| AWS SNS | 1,000/mo | $0.005/msg | AWS users |

## 🔧 How It Works

### Restaurant gets WhatsApp message like:

```
🔔 *NEW ORDER - Lusaka*

📋 *Order #ABC123*
👤 *Customer:* John Doe
📱 *Phone:* +265977123456

*Items:*
• 2x Chicken Pizza
• 1x Coca Cola

💰 *Total:* K450.00
⏱️ *Bus Arrival:* ~45m from now

🚌 *Pickup Location:* Lusaka Bus Station
📍 *Town:* Lusaka

---
👉 Click link to confirm order
👉 Start preparing now! ⏱️

Sent from *BusNStay* 🍽️🚌
```

## 🛡️ Security Notes

**IMPORTANT:** 
- ✅ API key is safe to include in Flutter (it's meant for frontend)
- ✅ Phone Number ID is public data
- ❌ Never share Wati login password
- ✅ Create separate API key for production

### For Production:
```dart
// Use environment variables instead of hardcoding:
import 'package:flutter_dotenv/flutter_dotenv.dart';

RestaurantNotificationService.initializeWati(
  apiKey: dotenv.env['WATI_API_KEY']!,
  phoneNumberId: dotenv.env['WATI_PHONE_ID']!,
);
```

## 🚀 Current Implementation

### Supported Channels:
- ✅ **WhatsApp** - Via Wati API (requires configuration)
- ✅ **In-App** - Dashboard notifications (automatic)
- ✅ **SMS** - Via Wati SMS API (optional)
- 🟡 **Email** - Placeholder (not implemented)

### Code Location:
- API Integration: `lib/services/restaurant_notification_service.dart`
- Initialization: `lib/main.dart` (line 40-60)
- Usage: `lib/services/order_management_service.dart`

## 📱 Test Message Format

When restaurant receives WhatsApp:
```
🔔 NEW ORDER - [Town Name]
📋 Order #[SHORT_ID]
👤 Customer: [Name]
📱 Phone: [Phone]

Items:
• Qty x Item Name

💰 Total: K[Amount]
⏱️ Bus Arrival: ~[Minutes]m from now
```

## 🐛 Troubleshooting

### "WhatsApp not configured"
```
⚠️ [WATI] Not configured. Skipping WhatsApp notification.
```
**Fix:** Add credentials to main.dart lines 45-48

### "API error 401"
```
❌ [WATI] API error 401
```
**Fix:** Check API key is correct

### "API error 400"
```
❌ [WATI] API error 400
```
**Fix:** Check phone number format (should be +265977123456)

### "Timeout"
```
❌ [WATI] Wati API timeout
```
**Fix:** Check internet connection, or Firebase might be rate-limiting

## 📞 Wati Support

- **Docs:** https://docs.wati.io/
- **Dashboard:** https://app.wati.io/
- **Support:** support@wati.io

## 🎯 Next Steps

1. ✅ Wati integration added to code
2. 📝 Create Wati account
3. 🔑 Get API credentials
4. 🚀 Add to main.dart
5. 🧪 Test with real WhatsApp
6. 📊 Monitor message delivery
7. 💰 Scale to production ($20/mo plan)

## 📊 Monitoring

Check notification delivery in Wati dashboard:
- Message sent count
- Delivery rate
- Failed messages
- Cost tracking

## 💡 Pro Tips

- Test with your own number first
- Save restaurant WhatsApp numbers in `restaurants` table
- Set up Wati webhook to track delivery status (advanced)
- Use Wati dashboard for manual messages during testing

---

**System Status:** ✅ Fully integrated and ready to test!

**To Enable:** Uncomment lines 45-48 in `lib/main.dart` and add your Wati credentials.
