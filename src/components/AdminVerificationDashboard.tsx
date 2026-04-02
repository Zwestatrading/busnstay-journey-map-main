import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle, XCircle, Clock, AlertCircle, Eye, Download } from 'lucide-react';
import { cn } from '@/lib/utils';

interface VerificationRequest {
  id: string;
  user_id: string;
  business_name: string;
  provider_type: string;
  overall_status: 'pending' | 'approved' | 'rejected' | 'revision_requested';
  business_address: string;
  contact_phone: string;
  contact_email: string;
  submitted_at: string;
  documents: unknown[];
  admin_notes?: string;
}

export const AdminVerificationDashboard = () => {
  const [verifications, setVerifications] = useState<VerificationRequest[]>([]);
  const [filteredStatus, setFilteredStatus] = useState<string>('pending');
  const [selectedVerification, setSelectedVerification] = useState<VerificationRequest | null>(null);
  const [reviewNotes, setReviewNotes] = useState('');
  const [isLoading, setIsLoading] = useState(true);
  const [selectedDocuments, setSelectedDocuments] = useState<unknown[]>([]);

  const fetchVerifications = useCallback(async () => {
    try {
      setIsLoading(true);

      // Fetch verification requests
      const { data: verificationData, error: verificationError } = await supabase
        .from('service_provider_verifications')
        .select(`
          id,
          user_id,
          business_name,
          provider_type,
          overall_status,
          business_address,
          contact_phone,
          contact_email,
          submitted_at,
          admin_notes
        `)
        .eq('overall_status', filteredStatus)
        .order('submitted_at', { ascending: false });

      if (verificationError) throw verificationError;

      // Fetch documents for each verification
      const verificationsWithDocs = await Promise.all(
        (verificationData || []).map(async (verification) => {
          const { data: docData } = await supabase
            .from('service_provider_documents')
            .select('*')
            .eq('user_id', verification.user_id);

          return {
            ...verification,
            documents: docData || [],
          };
        })
      );

      setVerifications(verificationsWithDocs);
    } catch (error) {
      console.error('Error fetching verifications:', error);
    } finally {
      setIsLoading(false);
    }
  }, [filteredStatus]);

  useEffect(() => {
    fetchVerifications();
  }, [filteredStatus, fetchVerifications]);

  const handleApprove = async (verificationId: string) => {
    try {
      const { data: userData } = await supabase.auth.getUser();
      const { error } = await supabase
        .from('service_provider_verifications')
        .update({
          overall_status: 'approved',
          admin_notes: reviewNotes,
          reviewed_by: userData?.user?.id,
          approved_at: new Date().toISOString(),
        })
        .eq('id', verificationId);

      if (error) throw error;

      setSelectedVerification(null);
      setReviewNotes('');
      fetchVerifications();
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Error approving:', error);
      alert('Failed to approve verification');
    }
  };

  const handleReject = async (verificationId: string) => {
    if (!reviewNotes.trim()) {
      alert('Please provide a reason for rejection');
      return;
    }

    try {
      const { data: userData } = await supabase.auth.getUser();
      const { error } = await supabase
        .from('service_provider_verifications')
        .update({
          overall_status: 'rejected',
          admin_notes: reviewNotes,
          status_reason: reviewNotes,
          reviewed_by: userData?.user?.id,
          rejected_at: new Date().toISOString(),
        })
        .eq('id', verificationId);

      if (error) throw error;

      setSelectedVerification(null);
      setReviewNotes('');
      fetchVerifications();
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Error rejecting:', error);
      alert('Failed to reject verification');
    }
  };

  const handleRequestRevision = async (verificationId: string) => {
    if (!reviewNotes.trim()) {
      alert('Please provide revision details');
      return;
    }

    try {
      const { data: userData } = await supabase.auth.getUser();
      const { error } = await supabase
        .from('service_provider_verifications')
        .update({
          overall_status: 'revision_requested',
          revision_request_reason: reviewNotes,
          reviewed_by: userData?.user?.id,
          first_review_at: new Date().toISOString(),
        })
        .eq('id', verificationId);

      if (error) throw error;

      setSelectedVerification(null);
      setReviewNotes('');
      fetchVerifications();
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Error requesting revision:', error);
      alert('Failed to request revision');
    }
  ;}

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'approved':
        return 'text-green-400 bg-green-900/20 border-green-500/50';
      case 'rejected':
        return 'text-red-400 bg-red-900/20 border-red-500/50';
      case 'revision_requested':
        return 'text-yellow-400 bg-yellow-900/20 border-yellow-500/50';
      default:
        return 'text-blue-400 bg-blue-900/20 border-blue-500/50';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'approved':
        return <CheckCircle className="w-5 h-5" />;
      case 'rejected':
        return <XCircle className="w-5 h-5" />;
      case 'revision_requested':
        return <AlertCircle className="w-5 h-5" />;
      default:
        return <Clock className="w-5 h-5" />;
    }
  };

  return (
    <div className="w-full space-y-8">
      {/* Header */}
      <div>
        <h1 className="text-4xl font-bold text-white mb-2">Service Provider Verification</h1>
        <p className="text-gray-400">Review and approve service provider applications</p>
      </div>

      {/* Status Filters */}
      <div className="flex gap-2 flex-wrap">
        {[
          { value: 'pending', label: 'Pending', count: 0, color: 'from-blue-600 to-blue-700' },
          { value: 'revision_requested', label: 'Revision Needed', count: 0, color: 'from-yellow-600 to-orange-600' },
          { value: 'approved', label: 'Approved', count: 0, color: 'from-green-600 to-emerald-600' },
          { value: 'rejected', label: 'Rejected', count: 0, color: 'from-red-600 to-rose-600' },
        ].map((filter) => (
          <motion.button
            key={filter.value}
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => setFilteredStatus(filter.value)}
            className={cn(
              'px-6 py-2 rounded-lg font-semibold transition-all',
              filteredStatus === filter.value
                ? `bg-gradient-to-r ${filter.color} text-white`
                : 'bg-white/10 text-gray-300 hover:bg-white/20'
            )}
          >
            {filter.label}
          </motion.button>
        ))}
      </div>

      {/* Verifications List */}
      <div className="space-y-4">
        {isLoading ? (
          <div className="text-center py-12 text-gray-400">Loading verifications...</div>
        ) : verifications.length === 0 ? (
          <div className="text-center py-12 text-gray-400">No {filteredStatus} verifications</div>
        ) : (
          verifications.map((verification, index) => (
            <motion.div
              key={verification.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: index * 0.1 }}
              className={`p-6 rounded-xl border-2 cursor-pointer transition-all ${getStatusColor(
                verification.overall_status
              )}`}
              onClick={() => setSelectedVerification(verification)}
            >
              <div className="flex items-center justify-between">
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    {getStatusIcon(verification.overall_status)}
                    <h3 className="text-xl font-bold text-white">{verification.business_name}</h3>
                  </div>
                  <p className="text-sm text-gray-300 mb-3">
                    <span className="capitalize font-semibold">{verification.provider_type}</span> •{' '}
                    {new Date(verification.submitted_at).toLocaleDateString()}
                  </p>
                  <p className="text-sm text-gray-400">{verification.business_address}</p>
                  <p className="text-sm text-gray-400">{verification.contact_phone}</p>
                </div>
                <Eye className="w-6 h-6 opacity-50 hover:opacity-100 transition" />
              </div>
            </motion.div>
          ))
        )}
      </div>

      {/* Detail Modal */}
      <AnimatePresence>
        {selectedVerification && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4 z-50"
            onClick={() => setSelectedVerification(null)}
          >
            <motion.div
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-slate-900 border border-white/10 rounded-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto"
            >
              {/* Header */}
              <div className="p-6 border-b border-white/10 bg-gradient-to-r from-slate-800 to-slate-900">
                <div className="flex items-center justify-between mb-2">
                  <h2 className="text-2xl font-bold text-white">{selectedVerification.business_name}</h2>
                  <button
                    onClick={() => setSelectedVerification(null)}
                    className="text-gray-400 hover:text-white text-2xl"
                  >
                    ×
                  </button>
                </div>
                <p className="text-gray-400 capitalize">{selectedVerification.provider_type}</p>
              </div>

              {/* Content */}
              <div className="p-6 space-y-6">
                {/* Business Information */}
                <div>
                  <h3 className="text-lg font-bold text-white mb-4">Business Information</h3>
                  <div className="grid grid-cols-2 gap-4 p-4 bg-slate-800/50 rounded-lg">
                    <div>
                      <p className="text-sm text-gray-400">Address</p>
                      <p className="text-white font-semibold">{selectedVerification.business_address}</p>
                    </div>
                    <div>
                      <p className="text-sm text-gray-400">Phone</p>
                      <p className="text-white font-semibold">{selectedVerification.contact_phone}</p>
                    </div>
                    <div className="col-span-2">
                      <p className="text-sm text-gray-400">Email</p>
                      <p className="text-white font-semibold">{selectedVerification.contact_email}</p>
                    </div>
                  </div>
                </div>

                {/* Documents */}
                <div>
                  <h3 className="text-lg font-bold text-white mb-4">Submitted Documents</h3>
                  <div className="space-y-2">
                    {/* eslint-disable-next-line @typescript-eslint/no-explicit-any */}
                    {(selectedVerification.documents as any[]).map((doc: any) => (
                      <div
                        key={doc.id}
                        className="p-3 bg-slate-800/50 rounded-lg flex items-center justify-between"
                      >
                        <div>
                          <p className="text-white font-semibold text-sm capitalize">{doc.document_type}</p>
                          <p className="text-gray-400 text-xs">{doc.file_name}</p>
                        </div>
                        <a
                          href={doc.file_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="p-2 hover:bg-blue-600/20 rounded-lg transition"
                        >
                          <Download className="w-5 h-5 text-blue-400" />
                        </a>
                      </div>
                    ))}
                  </div>
                </div>

                {/* Review Notes */}
                <div>
                  <h3 className="text-lg font-bold text-white mb-4">Review Notes</h3>
                  <textarea
                    value={reviewNotes}
                    onChange={(e) => setReviewNotes(e.target.value)}
                    placeholder={
                      selectedVerification.overall_status === 'pending'
                        ? 'Enter review notes or reasons...'
                        : 'Enter revision request details...'
                    }
                    className="w-full px-4 py-3 bg-slate-800 border border-white/10 rounded-lg text-white placeholder-gray-500 h-24 resize-none"
                  />
                </div>

                {/* Previous Notes */}
                {selectedVerification.admin_notes && (
                  <div className="p-4 bg-slate-800/50 rounded-lg">
                    <p className="text-sm text-gray-400 mb-1">Previous Admin Notes</p>
                    <p className="text-white">{selectedVerification.admin_notes}</p>
                  </div>
                )}
              </div>

              {/* Actions */}
              <div className="p-6 border-t border-white/10 bg-slate-800/50 flex gap-3">
                {selectedVerification.overall_status === 'pending' ? (
                  <>
                    <Button
                      onClick={() => handleReject(selectedVerification.id)}
                      className="flex-1 bg-red-600 hover:bg-red-700 text-white"
                    >
                      Reject
                    </Button>
                    <Button
                      onClick={() => handleRequestRevision(selectedVerification.id)}
                      className="flex-1 bg-yellow-600 hover:bg-yellow-700 text-white"
                    >
                      Request Revision
                    </Button>
                    <Button
                      onClick={() => handleApprove(selectedVerification.id)}
                      className="flex-1 bg-green-600 hover:bg-green-700 text-white"
                    >
                      Approve
                    </Button>
                  </>
                ) : (
                  <Button
                    onClick={() => setSelectedVerification(null)}
                    className="flex-1 bg-slate-700 hover:bg-slate-600 text-white"
                  >
                    Close
                  </Button>
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
};

export default AdminVerificationDashboard;
