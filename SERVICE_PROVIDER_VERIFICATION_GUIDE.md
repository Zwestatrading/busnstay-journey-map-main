# Service Provider Verification System - Deployment Guide

## Overview
Complete end-to-end service provider verification system with provider registration, admin dashboard, and status tracking.

## What Was Built

### 1. **Database Schema** ✅
**File**: `supabase/migrations/20260210_service_provider_verification.sql` (412 lines)

**Created Tables**:
- `service_provider_documents` - Individual document uploads with verification tracking
- `service_provider_verifications` - Main verification record per provider (unique per user)
- `verification_history` - Audit trail of all status changes

**Created Enums**:
- `verification_status` - pending, approved, rejected, revision_requested
- `document_type` - 8 document types (business_registration, proof_of_address, driver_license, vehicle_registration, operating_permit, tax_certificate, health_certificate, insurance_certificate)

**Features**:
- Row-level security (RLS) policies for user/admin access
- 3 automated triggers for document verification, approval automation, and status logging
- Realtime support for live updates
- Foreign key constraints to `user_profiles` and `stops` tables

### 2. **React Components**

#### A. ServiceProviderVerification.tsx (566 lines)
**Location**: `src/components/ServiceProviderVerification.tsx`
**Purpose**: Multi-step form for service providers to register

**Workflow**:
1. Step 1: Select provider type (Restaurant, Hotel, Taxi Driver, Rider)
2. Step 2: Enter business information
3. Step 3: Upload required documents
4. Step 4: Review and submit

**Features**:
- Dynamic document requirements by provider type
- Supabase Storage integration for file uploads
- Animation with Framer Motion
- Status display (pending/approved/rejected)

**Document Requirements**:
- **Restaurant**: business_registration, proof_of_address, health_certificate, operating_permit
- **Hotel**: business_registration, proof_of_address, operating_permit
- **Taxi Driver**: driver_license, vehicle_registration, insurance_certificate
- **Rider**: driver_license, insurance_certificate

#### B. AdminVerificationDashboard.tsx (422 lines)
**Location**: `src/components/AdminVerificationDashboard.tsx`
**Purpose**: Admin interface for reviewing and approving applications

**Features**:
- Filter verifications by status (pending, revision_requested, approved, rejected)
- Detailed review modal with full application details
- Document viewer with download links
- Action buttons: Approve, Reject, Request Revision
- Admin notes and reason tracking

#### C. DocumentViewer.tsx (158 lines)
**Location**: `src/components/DocumentViewer.tsx`
**Purpose**: Modal component for previewing uploaded documents

**Features**:
- Supports PDF preview (embedded viewer)
- Supports image preview (JPG, PNG, GIF)
- File download option
- Mark as verified button (for admins)
- Open in new tab functionality

### 3. **Pages**

#### A. Verification.tsx (89 lines)
**Route**: `/verification`
**Purpose**: Public page for service providers to submit verification

**Features**:
- Access control (only service provider roles allowed)
- Authentication check
- Navigation with back button and sign-out
- Wraps ServiceProviderVerification component

#### B. VerificationStatus.tsx (297 lines)
**Route**: `/verification-status`
**Purpose**: Public page for providers to check their verification status

**Features**:
- Display current verification status
- Show admin feedback and notes
- Show revision request details (if any)
- Action button to resubmit (if revision requested)
- Success message for approved providers with dashboard link

### 4. **Router Updates**
**File**: `src/App.tsx`

**New Routes Added**:
```tsx
<Route path="/verification" element={<Verification />} />
<Route path="/verification-status" element={<VerificationStatus />} />
```

## Deployment Steps

### Step 1: Deploy SQL Migration to Supabase
1. Go to Supabase Dashboard → SQL Editor
2. Open the migration file: `supabase/migrations/20260210_service_provider_verification.sql`
3. Copy all SQL content
4. Paste into Supabase SQL Editor
5. Execute the migration
6. Verify tables created:
   - Check "service_provider_documents" exists
   - Check "service_provider_verifications" exists
   - Check "verification_history" exists
   - Check enums created (verification_status, document_type)

### Step 2: Create Supabase Storage Bucket
1. Go to Supabase Dashboard → Storage
2. Create new bucket named: `documents`
3. Set public access: **No** (keep it private)
4. Create folder structure inside bucket:
   ```
   documents/
   ├── [user-id]/
   │   ├── business_registration-[timestamp].pdf
   │   ├── proof_of_address-[timestamp].pdf
   │   └── ...
   ```
   (This is created automatically when files are uploaded)

### Step 3: Test the Workflow

**Provider Flow**:
1. Login as a service provider (restaurant, hotel, taxi_driver, or rider)
2. Navigate to `/verification`
3. Complete all 4 steps
4. Submit application
5. Navigate to `/verification-status` to check status

**Admin Flow**:
1. Login as admin user
2. Navigate to `/admin`
3. Scroll to "Service Provider Verification" section (in new AdminDashboard update needed)
4. Review pending applications
5. Approve, Reject, or Request Revision

### Step 4: Configure Email Notifications (Optional)
To add email notifications on approval/rejection:
1. Set up Supabase Edge Functions or external webhook
2. Trigger on verification status changes
3. Send email to `contact_email` in service_provider_verifications table

### Step 5: Integrate into Signup Flow (Optional)
To auto-prompt verification after signup:
1. After successful signup as service provider
2. Redirect to `/verification` instead of `/dashboard`
3. Or show setup wizard that includes verification step

## File Summary

| File | Lines | Type | Status |
|------|-------|------|--------|
| `20260210_service_provider_verification.sql` | 412 | SQL Migration | ✅ Ready to deploy |
| `ServiceProviderVerification.tsx` | 566 | Component | ✅ No errors |
| `AdminVerificationDashboard.tsx` | 422 | Component | ✅ No errors |
| `DocumentViewer.tsx` | 158 | Component | ✅ No errors |
| `Verification.tsx` | 89 | Page | ✅ No errors |
| `VerificationStatus.tsx` | 297 | Page | ✅ No errors |
| `App.tsx` | Modified | Routes | ✅ Updated |

**Total New Code**: ~1,944 lines (backend SQL + frontend React)

## Database Schema Diagram

```
user_profiles (existing)
    ↓
    ├─→ service_provider_verifications
    │       ├─→ service_provider_documents
    │       └─→ verification_history
    │
    └─→ user_id (FK to auth.users)

service_provider_verifications
├─ id: UUID (PRIMARY KEY)
├─ user_id: UUID (UNIQUE, FK → auth.users)
├─ profile_id: UUID (FK → user_profiles)
├─ provider_type: text ('restaurant', 'hotel', 'taxi_driver', 'rider')
├─ business_name: text
├─ business_address: text
├─ contact_phone: text
├─ contact_email: text
├─ overall_status: enum (pending, approved, rejected, revision_requested)
├─ submitted_at: timestamp
├─ approved_at: timestamp (nullable)
└─ [25 more columns for tracking]

service_provider_documents
├─ id: UUID (PRIMARY KEY)
├─ user_id: UUID (FK → auth.users)
├─ verification_id: UUID (FK → service_provider_verifications)
├─ document_type: enum (8 types)
├─ file_url: text (Supabase Storage URL)
├─ file_name: text
├─ is_verified: boolean
├─ verified_by: UUID (FK → auth.users, nullable)
└─ [6 more columns]

verification_history
├─ id: UUID (PRIMARY KEY)
├─ verification_id: UUID (FK → service_provider_verifications)
├─ action: enum ('submitted', 'under_review', 'approved', 'rejected', etc.)
├─ performed_by: UUID (FK → auth.users, nullable)
├─ notes: text
└─ changed_fields: JSONB
```

## API Integration Points

### Provider Operations
```typescript
// Submit verification
supabase.from('service_provider_verifications').insert({
  user_id, provider_type, business_name, 
  business_address, contact_phone, contact_email
})

// Upload document
supabase.storage.from('documents').upload(
  `${user_id}/${docType}-${timestamp}.${ext}`,
  file
)

// Check status
supabase.from('service_provider_verifications')
  .select('*')
  .eq('user_id', user_id)
  .single()
```

### Admin Operations
```typescript
// List pending verifications
supabase.from('service_provider_verifications')
  .select('*, service_provider_documents(*)')
  .eq('overall_status', 'pending')

// Approve verification
supabase.from('service_provider_verifications')
  .update({ overall_status: 'approved', approved_at: now() })
  .eq('id', verificationId)

// Request revision
supabase.from('service_provider_verifications')
  .update({ 
    overall_status: 'revision_requested',
    revision_request_reason: reason
  })
  .eq('id', verificationId)
```

## Security Considerations

✅ **Implemented**:
- Row-level security (RLS) policies
- Users can only see/modify their own verifications
- Admins can see all verifications
- File uploads restricted to authenticated users
- Document storage is private (not publicly accessible)

⚠️ **Additional Recommendations**:
- Add rate limiting on document uploads
- Implement file type validation (check magic bytes, not just extension)
- Add file size limits (recommend 10MB per document)
- Implement audit logging for admin actions
- Consider IP whitelist for admin dashboard

## Testing Checklist

- [ ] SQL migration deployed successfully
- [ ] Supabase Storage bucket `documents` created
- [ ] Provider can complete all 4 steps of verification
- [ ] Documents upload to correct storage path
- [ ] Verification record created in database
- [ ] Admin can see pending verifications
- [ ] Admin can approve application
- [ ] Provider receives approval notification
- [ ] Provider dashboard shows approved status
- [ ] Document viewer works for all file types
- [ ] RLS policies prevent unauthorized access

## Next Steps

### Phase 2: Distance-Based Dynamic Pricing
- Add GPS coordinates to restaurants/hotels
- Implement Haversine formula for distance calculation
- Auto-calculate delivery fees in order pricing

### Phase 3: GPS Tracking
- Real-time location tracking for riders/taxis
- Live map updates
- Location history storage

## Support & Troubleshooting

**Issue**: Document upload fails with 403 Forbidden
**Solution**: Check Supabase Storage bucket permissions and auth token

**Issue**: Verification status not updating
**Solution**: Check RLS policies allow the operation; verify user role is 'admin'

**Issue**: Email in document_type enum not recognized
**Solution**: Ensure database migration was fully executed; check Supabase schema

## Files Modified
1. `src/App.tsx` - Added 2 new routes
2. `supabase/migrations/` - Added new migration file

## Files Created
1. `src/components/ServiceProviderVerification.tsx`
2. `src/components/AdminVerificationDashboard.tsx`
3. `src/components/DocumentViewer.tsx`
4. `src/pages/Verification.tsx`
5. `src/pages/VerificationStatus.tsx`
6. `supabase/migrations/20260210_service_provider_verification.sql`

---

**Build Status**: ✅ All new components compile without errors  
**Status**: Ready for deployment  
**Last Updated**: Today
