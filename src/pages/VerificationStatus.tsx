import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { ArrowLeft, LogOut } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { motion } from 'framer-motion';

interface VerificationStatus {
  id: string;
  overall_status: 'pending' | 'approved' | 'rejected' | 'revision_requested';
  business_name: string;
  provider_type: string;
  submitted_at: string;
  admin_notes?: string;
  revision_request_reason?: string;
}

export const VerificationStatusPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [verification, setVerification] = useState<VerificationStatus | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [user, setUser] = useState<unknown>(null);

  const fetchUserVerification = useCallback(async () => {
    try {
      const { data: userData, error } = await supabase.auth.getUser();

      // Suppress AbortError - it's a known Supabase quirk
      if (error && error.name === 'AbortError') {
        setIsLoading(false);
        return;
      }

      if (!userData?.user) {
        navigate('/auth');
        return;
      }

      setUser(userData.user);

      const { data: verificationData } = await supabase
        .from('service_provider_verifications')
        .select('*')
        .eq('user_id', userData.user.id)
        .single();

      setVerification(verificationData);
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Error fetching verification:', error);
    } finally {
      setIsLoading(false);
    }
  }, [navigate]);

  useEffect(() => {
    fetchUserVerification();
  }, [navigate, fetchUserVerification]);

  const handleSignOut = async () => {
    try {
      await supabase.auth.signOut();
      setTimeout(() => navigate('/auth'), 500);
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Sign out error:', error);
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved':
        return 'from-green-600 to-emerald-600';
      case 'rejected':
        return 'from-red-600 to-rose-600';
      case 'revision_requested':
        return 'from-yellow-600 to-orange-600';
      default:
        return 'from-blue-600 to-cyan-600';
    }
  };

  const getStatusMessage = (status: string) => {
    switch (status) {
      case 'approved':
        return {
          title: '✓ Approved',
          description: 'Your service provider application has been approved. Your business is now live on BusNStay.',
          color: 'text-green-400',
        };
      case 'rejected':
        return {
          title: '✗ Application Rejected',
          description: 'Your application did not meet our requirements. Please review the feedback below.',
          color: 'text-red-400',
        };
      case 'revision_requested':
        return {
          title: '⚠ Revision Requested',
          description: 'Please update your application according to the feedback below and resubmit.',
          color: 'text-yellow-400',
        };
      default:
        return {
          title: '⏳ Under Review',
          description: 'Our team is reviewing your application. This typically takes 1-2 business days.',
          color: 'text-blue-400',
        };
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-400">Loading your verification status...</p>
        </div>
      </div>
    );
  }

  if (!verification) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
        {/* Navigation */}
        <div className="border-b border-white/10 bg-slate-900/50 backdrop-blur-md sticky top-0 z-40">
          <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
            <Button
              onClick={() => navigate('/')}
              variant="ghost"
              size="sm"
              className="text-gray-300 hover:text-white hover:bg-white/10"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back
            </Button>
            <Button
              onClick={handleSignOut}
              variant="ghost"
              size="sm"
              className="text-gray-300 hover:text-red-400 hover:bg-red-900/20"
            >
              <LogOut className="w-4 h-4 mr-2" />
              Sign Out
            </Button>
          </div>
        </div>

        {/* Content */}
        <div className="max-w-4xl mx-auto px-4 py-12 text-center">
          <h1 className="text-4xl font-bold text-white mb-4">No Active Verification</h1>
          <p className="text-gray-400 mb-8">
            Start your service provider verification to go live on BusNstay.
          </p>
          <Button
            onClick={() => navigate('/verification')}
            className="bg-gradient-to-r from-blue-600 to-cyan-600 hover:from-blue-700 hover:to-cyan-700"
          >
            Begin Verification
          </Button>
        </div>
      </div>
    );
  }

  const statusInfo = getStatusMessage(verification.overall_status);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Navigation */}
      <div className="border-b border-white/10 bg-slate-900/50 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <Button
            onClick={() => navigate('/')}
            variant="ghost"
            size="sm"
            className="text-gray-300 hover:text-white hover:bg-white/10"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Back
          </Button>
          <Button
            onClick={handleSignOut}
            variant="ghost"
            size="sm"
            className="text-gray-300 hover:text-red-400 hover:bg-red-900/20"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Sign Out
          </Button>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-4xl mx-auto px-4 py-12 space-y-8">
        {/* Status Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className={`rounded-2xl border-2 border-white/20 overflow-hidden bg-gradient-to-br ${getStatusColor(
            verification.overall_status
          )}`}
        >
          <div className="p-8 bg-black/30 backdrop-blur-sm">
            <p className={`text-lg font-semibold mb-2 ${statusInfo.color}`}>{statusInfo.title}</p>
            <h1 className="text-3xl font-bold text-white mb-2">{verification.business_name}</h1>
            <p className="text-gray-300">{statusInfo.description}</p>
          </div>
        </motion.div>

        {/* Verification Details */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="p-6 rounded-xl border border-white/10 bg-slate-900/50"
        >
          <h2 className="text-lg font-bold text-white mb-6">Verification Details</h2>
          <div className="grid grid-cols-2 gap-6">
            <div>
              <p className="text-sm text-gray-400 mb-1">Service Type</p>
              <p className="text-white font-semibold capitalize">{verification.provider_type}</p>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">Submitted</p>
              <p className="text-white font-semibold">
                {new Date(verification.submitted_at).toLocaleDateString()}
              </p>
            </div>
            <div>
              <p className="text-sm text-gray-400 mb-1">Status</p>
              <p className="text-white font-semibold capitalize">{verification.overall_status}</p>
            </div>
          </div>
        </motion.div>

        {/* Admin Feedback */}
        {verification.admin_notes && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="p-6 rounded-xl border border-blue-500/50 bg-blue-900/20"
          >
            <h2 className="text-lg font-bold text-blue-400 mb-4">Admin Feedback</h2>
            <p className="text-gray-300">{verification.admin_notes}</p>
          </motion.div>
        )}

        {/* Revision Request Details */}
        {verification.revision_request_reason && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.2 }}
            className="p-6 rounded-xl border border-yellow-500/50 bg-yellow-900/20"
          >
            <h2 className="text-lg font-bold text-yellow-400 mb-4">Revision Request</h2>
            <p className="text-gray-300 mb-6">{verification.revision_request_reason}</p>
            <Button
              onClick={() => navigate('/verification')}
              className="bg-yellow-600 hover:bg-yellow-700 text-white"
            >
              Update & Resubmit
            </Button>
          </motion.div>
        )}

        {/* Action Buttons */}
        {verification.overall_status === 'approved' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="p-6 rounded-xl border border-green-500/50 bg-green-900/20 text-center"
          >
            <p className="text-green-400 font-semibold mb-4">🎉 Your business is now live on BusNStay!</p>
            <Button
              onClick={() => navigate('/dashboard')}
              className="bg-green-600 hover:bg-green-700 text-white"
            >
              View Your Dashboard
            </Button>
          </motion.div>
        )}

        {verification.overall_status === 'pending' && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="p-6 rounded-xl border border-blue-500/50 bg-blue-900/20"
          >
            <p className="text-blue-400 text-sm">
              We're reviewing your application. Please allow 1-2 business days. You'll receive an email notification
              when the review is complete.
            </p>
          </motion.div>
        )}
      </div>
    </div>
  );
};

export default VerificationStatusPage;
