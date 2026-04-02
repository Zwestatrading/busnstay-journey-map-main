-- ============================================
-- SERVICE PROVIDER VERIFICATION SYSTEM
-- For Restaurants, Hotels, Taxi Drivers, Riders
-- ============================================

-- 1. Create verification status ENUM
DO $$ BEGIN
    CREATE TYPE verification_status AS ENUM ('pending', 'approved', 'rejected', 'revision_requested');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE document_type AS ENUM (
        'business_registration',
        'proof_of_address',
        'driver_license',
        'vehicle_registration',
        'operating_permit',
        'tax_certificate',
        'health_certificate',
        'insurance_certificate'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create service_provider_documents table
CREATE TABLE IF NOT EXISTS public.service_provider_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN (
        'business_registration', 'proof_of_address', 'driver_license', 
        'vehicle_registration', 'operating_permit', 'tax_certificate',
        'health_certificate', 'insurance_certificate'
    )),
    file_url TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size INTEGER,
    file_type TEXT,
    upload_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
    expiry_date DATE,
    is_verified BOOLEAN DEFAULT false,
    verification_notes TEXT,
    verified_by UUID REFERENCES auth.users(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spd_user_id ON public.service_provider_documents(user_id);
CREATE INDEX IF NOT EXISTS idx_spd_document_type ON public.service_provider_documents(document_type);
CREATE INDEX IF NOT EXISTS idx_spd_is_verified ON public.service_provider_documents(is_verified);

-- 3. Create service_provider_verifications table (main verification record)
CREATE TABLE IF NOT EXISTS public.service_provider_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('restaurant', 'hotel', 'taxi_driver', 'rider')),
    
    -- Business Info
    business_name TEXT NOT NULL,
    business_address TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT NOT NULL,
    
    -- Station Assignment
    assigned_station_id UUID REFERENCES public.stops(id) ON DELETE SET NULL,
    
    -- Approval Status
    overall_status TEXT DEFAULT 'pending' CHECK (overall_status IN ('pending', 'approved', 'rejected', 'revision_requested')),
    status_reason TEXT,
    
    -- Document Checklist
    documents_complete BOOLEAN DEFAULT false,
    business_registration_verified BOOLEAN DEFAULT false,
    address_verified BOOLEAN DEFAULT false,
    license_verified BOOLEAN DEFAULT false,
    health_certificate_verified BOOLEAN DEFAULT false,
    insurance_verified BOOLEAN DEFAULT false,
    
    -- Admin Review
    reviewed_by UUID REFERENCES auth.users(id),
    admin_notes TEXT,
    revision_request_reason TEXT,
    
    -- Workflow Dates
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    first_review_at TIMESTAMP WITH TIME ZONE,
    approved_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    
    -- Expiry
    approval_expires_at DATE,
    
    -- Contact Info for Admin
    admin_can_contact_phone TEXT,
    admin_can_contact_email TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spv_user_id ON public.service_provider_verifications(user_id);
CREATE INDEX IF NOT EXISTS idx_spv_status ON public.service_provider_verifications(overall_status);
CREATE INDEX IF NOT EXISTS idx_spv_provider_type ON public.service_provider_verifications(provider_type);
CREATE INDEX IF NOT EXISTS idx_spv_station_id ON public.service_provider_verifications(assigned_station_id);

-- 4. Create verification_history table (audit trail)
CREATE TABLE IF NOT EXISTS public.verification_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_id UUID NOT NULL REFERENCES public.service_provider_verifications(id) ON DELETE CASCADE,
    action TEXT NOT NULL CHECK (action IN ('submitted', 'under_review', 'approved', 'rejected', 'revision_requested', 'resubmitted')),
    performed_by UUID REFERENCES auth.users(id),
    notes TEXT,
    changed_fields JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_vh_verification_id ON public.verification_history(verification_id);
CREATE INDEX IF NOT EXISTS idx_vh_created_at ON public.verification_history(created_at);

-- 5. Add RLS Policies
ALTER TABLE public.service_provider_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_provider_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_history ENABLE ROW LEVEL SECURITY;

-- Service provider documents policies
DROP POLICY IF EXISTS "Users can view their own documents" ON public.service_provider_documents;
CREATE POLICY "Users can view their own documents" ON public.service_provider_documents
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can upload their own documents" ON public.service_provider_documents;
CREATE POLICY "Users can upload their own documents" ON public.service_provider_documents
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can view all documents" ON public.service_provider_documents;
CREATE POLICY "Admins can view all documents" ON public.service_provider_documents
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can update documents" ON public.service_provider_documents;
CREATE POLICY "Admins can update documents" ON public.service_provider_documents
    FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Verification policies
DROP POLICY IF EXISTS "Users can view their own verification" ON public.service_provider_verifications;
CREATE POLICY "Users can view their own verification" ON public.service_provider_verifications
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create their verification" ON public.service_provider_verifications;
CREATE POLICY "Users can create their verification" ON public.service_provider_verifications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their pending verification" ON public.service_provider_verifications;
CREATE POLICY "Users can update their pending verification" ON public.service_provider_verifications
    FOR UPDATE USING (auth.uid() = user_id AND overall_status IN ('pending', 'revision_requested'));

DROP POLICY IF EXISTS "Admins can view all verifications" ON public.service_provider_verifications;
CREATE POLICY "Admins can view all verifications" ON public.service_provider_verifications
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "Admins can update verifications" ON public.service_provider_verifications;
CREATE POLICY "Admins can update verifications" ON public.service_provider_verifications
    FOR UPDATE USING (public.has_role(auth.uid(), 'admin'));

-- Verification history policies
DROP POLICY IF EXISTS "Users can view their verification history" ON public.verification_history;
CREATE POLICY "Users can view their verification history" ON public.verification_history
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.service_provider_verifications spv
            WHERE spv.id = verification_history.verification_id
            AND spv.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Admins can view all history" ON public.verification_history;
CREATE POLICY "Admins can view all history" ON public.verification_history
    FOR SELECT USING (public.has_role(auth.uid(), 'admin'));

DROP POLICY IF EXISTS "System can insert history" ON public.verification_history;
CREATE POLICY "System can insert history" ON public.verification_history
    FOR INSERT WITH CHECK (true);

-- 6. Update user_profiles table to use verification status
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS verification_id UUID REFERENCES public.service_provider_verifications(id);
ALTER TABLE public.user_profiles ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'pending';

CREATE INDEX IF NOT EXISTS idx_user_profiles_verification_id ON public.user_profiles(verification_id);

-- 7. Create function to auto-approve when all documents verified
CREATE OR REPLACE FUNCTION public.check_verification_complete()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.service_provider_verifications
    SET
        documents_complete = (
            business_registration_verified 
            AND address_verified 
            AND (license_verified OR provider_type = 'restaurant')
        ),
        updated_at = now()
    WHERE id = NEW.verification_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS check_verification_complete_trigger ON public.service_provider_documents;
CREATE TRIGGER check_verification_complete_trigger
    AFTER UPDATE ON public.service_provider_documents
    FOR EACH ROW EXECUTE FUNCTION public.check_verification_complete();

-- 8. Create function to auto-update user profile when approved
CREATE OR REPLACE FUNCTION public.update_profile_on_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.overall_status = 'approved' AND OLD.overall_status != 'approved' THEN
        UPDATE public.user_profiles
        SET
            is_approved = true,
            assigned_station_id = NEW.assigned_station_id,
            verification_status = 'approved',
            updated_at = now()
        WHERE user_id = NEW.user_id;
        
        INSERT INTO public.verification_history (verification_id, action, performed_by, notes)
        VALUES (NEW.id, 'approved', auth.uid(), 'Automatically updated profile on approval');
    ELSIF NEW.overall_status = 'rejected' AND OLD.overall_status != 'rejected' THEN
        UPDATE public.user_profiles
        SET
            is_approved = false,
            verification_status = 'rejected',
            updated_at = now()
        WHERE user_id = NEW.user_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS update_profile_on_approval_trigger ON public.service_provider_verifications;
CREATE TRIGGER update_profile_on_approval_trigger
    AFTER UPDATE ON public.service_provider_verifications
    FOR EACH ROW EXECUTE FUNCTION public.update_profile_on_approval();

-- 9. Create function to add history entry on verification changes
CREATE OR REPLACE FUNCTION public.log_verification_change()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.overall_status IS DISTINCT FROM OLD.overall_status THEN
        INSERT INTO public.verification_history (
            verification_id, 
            action, 
            performed_by,
            notes,
            changed_fields
        ) VALUES (
            NEW.id,
            CASE 
                WHEN NEW.overall_status = 'approved' THEN 'approved'
                WHEN NEW.overall_status = 'rejected' THEN 'rejected'
                WHEN NEW.overall_status = 'revision_requested' THEN 'revision_requested'
                ELSE 'under_review'
            END,
            auth.uid(),
            NEW.status_reason,
            jsonb_build_object(
                'old_status', OLD.overall_status,
                'new_status', NEW.overall_status
            )
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS log_verification_change_trigger ON public.service_provider_verifications;
CREATE TRIGGER log_verification_change_trigger
    BEFORE UPDATE ON public.service_provider_verifications
    FOR EACH ROW EXECUTE FUNCTION public.log_verification_change();

-- 10. Add realtime support
ALTER PUBLICATION supabase_realtime ADD TABLE public.service_provider_verifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.verification_history;
