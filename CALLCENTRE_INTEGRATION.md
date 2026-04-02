# Call Centre Feature Integration Guide

## Overview

The **Text Call Centre** feature allows travelers/customers and delivery riders to request restaurants or specific services directly from a call centre agent via WhatsApp when their preferred option isn't available in the system.

## Features

✅ **Request a Restaurant** - When the desired restaurant isn't in the system
✅ **Specify Food Items** - Tell the agent exactly what you want
✅ **Add Special Requests** - Include preferences (no onions, extra sauce, etc.)
✅ **WhatsApp Contact** - Agent reaches out via WhatsApp within 5 minutes
✅ **Real-time Status** - Visual feedback as request is submitted
✅ **Station-aware** - Routes requests to the correct local call centre

## Components

### TextCallCentre.tsx
**Path**: `src/components/TextCallCentre.tsx`

A reusable modal component that provides a form for requesting a restaurant.

**Props**:
```tsx
interface TextCallCentreProps {
  stationName: string;        // Current station (e.g., "Lusaka Main Station")
  onClose?: () => void;       // Callback when dialog closes
}
```

**Usage**:
```tsx
import TextCallCentre from '@/components/TextCallCentre';

// In your component:
<TextCallCentre 
  stationName="Lusaka Main Station"
  onClose={() => console.log('Dialog closed')}
/>
```

## Integration Points

### 1. Rider Dashboard (COMPLETED)
**File**: `src/pages/RiderDashboard.tsx`
- Location: Header of "Available Deliveries" section
- Use Case: Riders can request specific restaurants/cuisines for delivery
- Status: ✅ Integrated with quick access button

### 2. Customer Booking Page (RECOMMENDED)
**Where**: Restaurant selection flow during booking
**Suggested Location**: 
- Near the "No results found" message in restaurant search
- As a "Can't find your restaurant?" action button
- In the restaurant filter/selection modal

**Example Integration**:
```tsx
import TextCallCentre from '@/components/TextCallCentre';

// In your restaurant search component:
{filteredRestaurants.length === 0 && (
  <div className="flex flex-col items-center gap-4">
    <p className="text-muted-foreground">No restaurants found</p>
    <TextCallCentre 
      stationName={currentStation.name}
      onClose={() => setSearchVisible(false)}
    />
  </div>
)}
```

### 3. Guest Info Page (OPTIONAL)
**Use Case**: Travelers can request a special restaurant preference while entering their details

## Data Flow

```
Customer/Rider Fills Form
        ↓
Submit via WhatsApp API (Future Enhancement)
        ↓
Call Centre System Receives Request
        ↓
Agent Reviews:
  - Station location
  - Restaurant name
  - Desired items
  - Special requests
        ↓
Agent Contacts via WhatsApp
        ↓
Agent Confirms Availability & Places Order
        ↓
Manual Entry into BusNStay System
        ↓
Order Status Updates Sent via Text
```

## API Integration (Future)

The component currently simulates submission with a 1.5s delay. To integrate with real WhatsApp/Call Centre system:

1. **Add API endpoint** to handle form submission
2. **Integrate WhatsApp API** (Twilio, Whatsapp Business API, etc.)
3. **Update TextCallCentre.tsx** `handleSubmit()` function:

```tsx
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
  setIsSubmitting(true);
  
  try {
    // Replace mock API call with real API
    const response = await fetch('/api/callcentre/request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        stationName,
        restaurantName: formData.restaurantName,
        foodItems: formData.foodItems,
        specialRequests: formData.specialRequests,
        phoneNumber: user?.phone,
        userId: user?.id,
      }),
    });
    
    if (!response.ok) throw new Error('Failed to submit request');
    
    setSubmitted(true);
    // Auto-close after 3 seconds...
  } catch (error) {
    toast({
      title: 'Error',
      description: 'Failed to submit request. Try again.',
      variant: 'destructive',
    });
  } finally {
    setIsSubmitting(false);
  }
};
```

## Styling & Customization

The component uses Tailwind CSS and custom UI components. To customize:

1. **Colors**: Change `bg-blue-600`, `bg-blue-100`, `text-blue-600` throughout the component
2. **Icons**: Replace with different Lucide icons
3. **Animation**: Adjust Framer Motion settings (`initial`, `animate`, `exit`)
4. **Form Fields**: Add/remove fields in the `formData` state

**Example - Change brand color to green**:
```tsx
// Change from blue-600 to green-600
className="bg-green-600 hover:bg-green-700"
className="bg-green-100"
className="text-green-600"
```

## User Experience Flow

1. **Rider/Customer**: Clicks "Text Call Centre" button
2. **Modal Opens**: Shows form with fields for restaurant name, items, requests
3. **Form Filled**: User enters desired restaurant and food details
4. **Submit**: User clicks "Send Request" button
5. **Loading**: Spinner shows "Sending..." state
6. **Success**: Confirmation screen with order summary
7. **Auto-Close**: Dialog closes after 3 seconds
8. **Agent Contact**: Call centre agent calls/texts user via WhatsApp within 5 minutes

## Testing

To test the component:

```tsx
// Test in any page:
import TextCallCentre from '@/components/TextCallCentre';

export default function TestPage() {
  return (
    <div className="p-8">
      <TextCallCentre 
        stationName="Test Station"
        onClose={() => console.log('Dialog closed')}
      />
    </div>
  );
}
```

## Requirements & Dependencies

✅ `react` - React hooks and components
✅ `framer-motion` - Animations and transitions
✅ `lucide-react` - Icons
✅ `@/components/ui/button` - Custom button component
✅ `@/components/ui/input` - Custom input component
✅ `@/components/ui/textarea` - Custom textarea component
✅ `@/components/ui/card` - Custom card component
✅ `@/hooks/use-toast` - Toast notifications

All dependencies are already installed in the project.

## Known Limitations & Future Enhancements

**Current**:
- ⚠️ Form submission is simulated (not connected to real API)
- ⚠️ No actual WhatsApp integration yet
- ⚠️ Request tracking not implemented

**Planned**:
- 📅 Real API integration with WhatsApp Business API
- 📅 Request tracking dashboard for staff/riders
- 📅 Multi-language support
- 📅 File upload for restaurant menu/images
- 📅 Rating system for agent service quality
- 📅 Integration with restaurant partner onboarding
- 📅 SMS fallback if WhatsApp unavailable

## Support

For issues or questions about the Call Centre feature:
1. Check this documentation
2. Review [TextCallCentre.tsx](src/components/TextCallCentre.tsx) source code
3. Check RiderDashboard integration in [RiderDashboard.tsx](src/pages/RiderDashboard.tsx)
