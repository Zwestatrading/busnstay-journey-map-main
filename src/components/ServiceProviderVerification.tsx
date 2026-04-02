import { useState } from 'react';
import { useAuthContext } from '@/contexts/useAuthContext';
import { Button } from '@/components/ui/button';
import { supabase } from '@/lib/supabase';
import { motion, AnimatePresence } from 'framer-motion';
import { Upload, CheckCircle, AlertCircle, Clock, FileText, Loader } from 'lucide-react';
import { cn } from '@/lib/utils';

interface DocumentUpload {
  type: string;
  file: File | null;
  url?: string;
  isVerified?: boolean;
}

interface VerificationFormProps {
  onSubmitSuccess?: () => void;
}

export const ServiceProviderVerification = ({ onSubmitSuccess }: VerificationFormProps) => {
  const { user } = useAuthContext();
  const [step, setStep] = useState<'provider-type' | 'business-info' | 'documents' | 'review'>('provider-type');
  const [providerType, setProviderType] = useState<'restaurant' | 'hotel' | 'taxi_driver' | 'rider' | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [documents, setDocuments] = useState<DocumentUpload[]>([]);
  const [verificationStatus, setVerificationStatus] = useState<'pending' | 'approved' | 'rejected' | null>(null);

  const [formData, setFormData] = useState({
    businessName: '',
    businessAddress: '',
    contactPhone: '',
    contactEmail: '',
    assignedStation: '',
  });

  const requiredDocuments = {
    restaurant: ['business_registration', 'proof_of_address', 'health_certificate', 'operating_permit'],
    hotel: ['business_registration', 'proof_of_address', 'operating_permit'],
    taxi_driver: ['driver_license', 'vehicle_registration', 'insurance_certificate'],
    rider: ['driver_license', 'insurance_certificate'],
  };

  const documentLabels: Record<string, string> = {
    business_registration: 'Business Registration/License',
    proof_of_address: 'Proof of Operating Address',
    driver_license: 'Valid Driver License',
    vehicle_registration: 'Vehicle Registration',
    operating_permit: 'Operating Permit',
    health_certificate: 'Health Certificate',
    insurance_certificate: 'Insurance Certificate',
    tax_certificate: 'Tax Certificate (Optional)',
  };

  const handleFileUpload = async (documentType: string, file: File) => {
    if (!user) return;

    setIsLoading(true);
    try {
      const fileExt = file.name.split('.').pop();
      const filePath = `verifications/${user.id}/${documentType}-${Date.now()}.${fileExt}`;

      const { data, error: uploadError } = await supabase.storage
        .from('documents')
        .upload(filePath, file);

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from('documents')
        .getPublicUrl(filePath);

      // Save document record
      const { error: dbError } = await supabase
        .from('service_provider_documents')
        .upsert({
          user_id: user.id,
          document_type: documentType,
          file_url: publicUrl,
          file_name: file.name,
          file_size: file.size,
          file_type: file.type,
        });

      if (dbError) throw dbError;

      // Update local state
      setDocuments((prev) => {
        const existing = prev.findIndex((d) => d.type === documentType);
        if (existing !== -1) {
          const updated = [...prev];
          updated[existing] = { type: documentType, file, url: publicUrl };
          return updated;
        }
        return [...prev, { type: documentType, file, url: publicUrl }];
      });
    } catch (error) {
      console.error('Upload error:', error);
      alert('Failed to upload document');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmitVerification = async () => {
    if (!user || !providerType) return;

    setIsLoading(true);
    try {
      const { data, error } = await supabase
        .from('service_provider_verifications')
        .upsert({
          user_id: user.id,
          provider_type: providerType,
          business_name: formData.businessName,
          business_address: formData.businessAddress,
          contact_phone: formData.contactPhone,
          contact_email: formData.contactEmail,
          overall_status: 'pending',
          submitted_at: new Date().toISOString(),
        });

      if (error) throw error;

      setVerificationStatus('pending');
      setStep('review');
      onSubmitSuccess?.();
    } catch (error) {
      console.error('Submission error:', error);
      alert('Failed to submit verification');
    } finally {
      setIsLoading(false);
    }
  };

  const getStatusIcon = () => {
    if (verificationStatus === 'approved') return <CheckCircle className="w-16 h-16 text-green-500" />;
    if (verificationStatus === 'rejected') return <AlertCircle className="w-16 h-16 text-red-500" />;
    return <Clock className="w-16 h-16 text-yellow-500" />;
  };

  const getStatusText = () => {
    if (verificationStatus === 'approved') return 'Approved! You can now start serving.';
    if (verificationStatus === 'rejected') return 'Your application was not approved. Please review the feedback and resubmit.';
    return 'Your application is under review. Our team will contact you within 24-48 hours.';
  };

  return (
    <div className="w-full space-y-6">
      <motion.div
        initial={{ opacity: 0, y: -20 }}
        animate={{ opacity: 1, y: 0 }}
        className="bg-slate-800/50 backdrop-blur-sm rounded-xl border border-white/10 p-6"
      >
        <h1 className="text-3xl font-bold text-white mb-2">Service Provider Verification</h1>
        <p className="text-gray-400">Register as a service provider to start using BusNStay</p>
      </motion.div>

      <div className="bg-slate-900/50 backdrop-blur-sm rounded-xl border border-white/10 p-8">
        <AnimatePresence mode="wait">
        {/* Step 1: Provider Type Selection */}
        {step === 'provider-type' && (
          <motion.div
            key="provider-type"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="space-y-6"
          >
            <div>
              <h2 className="text-3xl font-bold text-white mb-2">Join BusNStay</h2>
              <p className="text-gray-400">What type of service provider are you?</p>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {[
                { id: 'restaurant', icon: '🍽️', label: 'Restaurant/Cafe', color: 'from-orange-600 to-red-600' },
                { id: 'hotel', icon: '🏨', label: 'Hotel/Accommodation', color: 'from-blue-600 to-cyan-600' },
                { id: 'taxi_driver', icon: '🚕', label: 'Taxi Driver', color: 'from-yellow-600 to-orange-600' },
                { id: 'rider', icon: '🏃', label: 'Rider/Delivery', color: 'from-green-600 to-emerald-600' },
              ].map((provider) => (
                <motion.button
                  key={provider.id}
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => {
                    setProviderType(provider.id as 'restaurant' | 'hotel' | 'taxi_driver' | 'rider');
                    setStep('business-info');
                  }}
                  className={cn(
                    'p-6 rounded-xl border-2 transition-all',
                    providerType === provider.id
                      ? 'border-blue-500 bg-blue-900/20'
                      : 'border-white/10 bg-white/5 hover:border-white/20'
                  )}
                >
                  <div className={`bg-gradient-to-br ${provider.color} bg-clip-text text-5xl mb-3`}>
                    {provider.icon}
                  </div>
                  <p className="text-white font-semibold">{provider.label}</p>
                </motion.button>
              ))}
            </div>
          </motion.div>
        )}

        {/* Step 2: Business Information */}
        {step === 'business-info' && (
          <motion.div
            key="business-info"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="space-y-6"
          >
            <div>
              <h2 className="text-3xl font-bold text-white mb-2">Business Information</h2>
              <p className="text-gray-400">Tell us about your business</p>
            </div>

            <div className="space-y-4">
              <input
                type="text"
                placeholder="Business Name"
                value={formData.businessName}
                onChange={(e) => setFormData({ ...formData, businessName: e.target.value })}
                className="w-full px-4 py-3 bg-slate-800 border border-white/10 rounded-lg text-white placeholder-gray-500"
              />

              <textarea
                placeholder="Business Address"
                value={formData.businessAddress}
                onChange={(e) => setFormData({ ...formData, businessAddress: e.target.value })}
                className="w-full px-4 py-3 bg-slate-800 border border-white/10 rounded-lg text-white placeholder-gray-500 h-24 resize-none"
              />

              <input
                type="tel"
                placeholder="Contact Phone"
                value={formData.contactPhone}
                onChange={(e) => setFormData({ ...formData, contactPhone: e.target.value })}
                className="w-full px-4 py-3 bg-slate-800 border border-white/10 rounded-lg text-white placeholder-gray-500"
              />

              <input
                type="email"
                placeholder="Contact Email"
                value={formData.contactEmail}
                onChange={(e) => setFormData({ ...formData, contactEmail: e.target.value })}
                className="w-full px-4 py-3 bg-slate-800 border border-white/10 rounded-lg text-white placeholder-gray-500"
              />
            </div>

            <div className="flex gap-4">
              <Button
                onClick={() => setStep('provider-type')}
                variant="ghost"
                className="flex-1 text-gray-300"
              >
                Back
              </Button>
              <Button
                onClick={() => setStep('documents')}
                className="flex-1 bg-blue-600 hover:bg-blue-700"
              >
                Continue
              </Button>
            </div>
          </motion.div>
        )}

        {/* Step 3: Document Upload */}
        {step === 'documents' && (
          <motion.div
            key="documents"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="space-y-6"
          >
            <div>
              <h2 className="text-3xl font-bold text-white mb-2">Submit Documents</h2>
              <p className="text-gray-400">Upload required documents for verification</p>
            </div>

            <div className="space-y-4">
              {requiredDocuments[providerType!]?.map((docType) => (
                <div
                  key={docType}
                  className="p-4 bg-slate-800/50 border border-white/10 rounded-lg"
                >
                  <div className="flex items-center justify-between mb-3">
                    <label className="flex items-center gap-2 text-white font-semibold cursor-pointer flex-1">
                      <FileText className="w-5 h-5" />
                      {documentLabels[docType] || docType}
                    </label>
                    {documents.find((d) => d.type === docType)?.url && (
                      <CheckCircle className="w-5 h-5 text-green-500" />
                    )}
                  </div>

                  <input
                    type="file"
                    accept=".pdf,.doc,.docx,.jpg,.png"
                    onChange={(e) => {
                      const file = e.target.files?.[0];
                      if (file) handleFileUpload(docType, file);
                    }}
                    className="w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:bg-blue-600 file:text-white"
                    disabled={isLoading}
                  />

                  {documents.find((d) => d.type === docType)?.file && (
                    <p className="mt-2 text-sm text-green-400">
                      ✓ {documents.find((d) => d.type === docType)?.file?.name}
                    </p>
                  )}
                </div>
              ))}
            </div>

            <div className="flex gap-4">
              <Button
                onClick={() => setStep('business-info')}
                variant="ghost"
                className="flex-1 text-gray-300"
              >
                Back
              </Button>
              <Button
                onClick={() => setStep('review')}
                disabled={
                  requiredDocuments[providerType!]?.length !==
                  documents.filter((d) => d.url).length
                }
                className="flex-1 bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
              >
                Review & Submit
              </Button>
            </div>
          </motion.div>
        )}

        {/* Step 4: Review & Submit */}
        {step === 'review' && (
          <motion.div
            key="review"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="space-y-6"
          >
            <div>
              <h2 className="text-3xl font-bold text-white mb-2">Review Your Application</h2>
              <p className="text-gray-400">Please review your information before submitting</p>
            </div>

            <div className="p-6 bg-slate-800/50 border border-white/10 rounded-lg space-y-4">
              <div>
                <p className="text-gray-400 text-sm">Business Name</p>
                <p className="text-white font-semibold">{formData.businessName}</p>
              </div>
              <div>
                <p className="text-gray-400 text-sm">Address</p>
                <p className="text-white font-semibold">{formData.businessAddress}</p>
              </div>
              <div>
                <p className="text-gray-400 text-sm">Contact</p>
                <p className="text-white font-semibold">{formData.contactPhone} • {formData.contactEmail}</p>
              </div>
              <div>
                <p className="text-gray-400 text-sm">Documents ({documents.filter(d => d.url).length}/{requiredDocuments[providerType!]?.length})</p>
                <div className="mt-2 space-y-1">
                  {documents.filter(d => d.url).map((doc) => (
                    <p key={doc.type} className="text-green-400 text-sm">✓ {documentLabels[doc.type]}</p>
                  ))}
                </div>
              </div>
            </div>

            <div className="p-4 bg-blue-900/20 border border-blue-400/30 rounded-lg">
              <p className="text-sm text-blue-200">
                By submitting, you confirm that all information is accurate. Our admin team will review your application within 24-48 hours.
              </p>
            </div>

            <div className="flex gap-4">
              <Button
                onClick={() => setStep('documents')}
                variant="ghost"
                className="flex-1 text-gray-300"
              >
                Back
              </Button>
              <Button
                onClick={handleSubmitVerification}
                disabled={isLoading}
                className="flex-1 bg-green-600 hover:bg-green-700"
              >
                {isLoading ? 'Submitting...' : 'Submit Application'}
              </Button>
            </div>
          </motion.div>
        )}

        {/* Status Display */}
        {verificationStatus && (
          <motion.div
            key="status"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            className="flex flex-col items-center justify-center p-12 text-center"
          >
            {getStatusIcon()}
            <h3 className="text-2xl font-bold text-white mt-6">Application {verificationStatus}</h3>
            <p className="text-gray-400 mt-3">{getStatusText()}</p>

            <button
              onClick={() => {
                setStep('provider-type');
                setProviderType(null);
                setVerificationStatus(null);
                setFormData({ businessName: '', businessAddress: '', contactPhone: '', contactEmail: '', assignedStation: '' });
                setDocuments([]);
              }}
              className="mt-8 px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg"
            >
              Start New Application
            </button>
          </motion.div>
        )}
        </AnimatePresence>
      </div>
    </div>
  );
};

export default ServiceProviderVerification;
