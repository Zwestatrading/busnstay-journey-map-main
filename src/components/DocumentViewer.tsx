import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Download, Eye, FileText, Image } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface DocumentViewerProps {
  fileUrl: string;
  fileName: string;
  fileType: string;
  isOpen: boolean;
  onClose: () => void;
  onVerify?: () => void;
  isVerified?: boolean;
}

export const DocumentViewer = ({
  fileUrl,
  fileName,
  fileType,
  isOpen,
  onClose,
  onVerify,
  isVerified,
}: DocumentViewerProps) => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(false);

  const isPDF = fileType.includes('pdf');
  const isImage = fileType.includes('image') || /\.(jpg|jpeg|png|gif)$/i.test(fileName);

  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4 z-50"
          onClick={onClose}
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            onClick={(e) => e.stopPropagation()}
            className="bg-slate-900 border border-white/10 rounded-2xl max-w-4xl w-full max-h-[90vh] flex flex-col"
          >
            {/* Header */}
            <div className="p-6 border-b border-white/10 flex items-center justify-between bg-gradient-to-r from-slate-800 to-slate-900">
              <div>
                <h2 className="text-2xl font-bold text-white">{fileName}</h2>
                <p className="text-gray-400 text-sm mt-1">{fileType}</p>
              </div>
              <button onClick={onClose} className="text-gray-400 hover:text-white text-3xl">
                ×
              </button>
            </div>

            {/* Content */}
            <div className="flex-1 overflow-y-auto p-6 flex items-center justify-center">
              {error ? (
                <div className="text-center text-gray-400 space-y-4">
                  <FileText className="w-16 h-16 mx-auto opacity-50" />
                  <p>Unable to preview this file type</p>
                  <Button
                    onClick={() => window.open(fileUrl, '_blank')}
                    className="bg-blue-600 hover:bg-blue-700"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Download to View
                  </Button>
                </div>
              ) : isPDF ? (
                <div className="w-full h-full">
                  {loading && (
                    <div className="absolute inset-0 flex items-center justify-center">
                      <p className="text-gray-400">Loading PDF...</p>
                    </div>
                  )}
                  <iframe
                    src={`${fileUrl}#toolbar=1`}
                    onLoad={() => setLoading(false)}
                    onError={() => {
                      setLoading(false);
                      setError(true);
                    }}
                    className="w-full h-[600px] border border-white/10 rounded-lg"
                    title={fileName}
                  />
                </div>
              ) : isImage ? (
                <div className="w-full flex items-center justify-center">
                  {loading && <p className="text-gray-400 absolute">Loading image...</p>}
                  <img
                    src={fileUrl}
                    alt={fileName}
                    onLoad={() => setLoading(false)}
                    onError={() => {
                      setLoading(false);
                      setError(true);
                    }}
                    className="max-w-full max-h-[500px] rounded-lg"
                  />
                </div>
              ) : (
                <div className="text-center text-gray-400 space-y-4">
                  <FileText className="w-16 h-16 mx-auto opacity-50" />
                  <p>Preview not available for this file type</p>
                  <a
                    href={fileUrl}
                    download={fileName}
                    className="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Download
                  </a>
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="p-6 border-t border-white/10 bg-slate-800/50 flex gap-3">
              {onVerify && (
                <Button
                  onClick={onVerify}
                  disabled={isVerified}
                  className={`flex-1 ${
                    isVerified ? 'bg-green-600 hover:bg-green-700' : 'bg-blue-600 hover:bg-blue-700'
                  } text-white`}
                >
                  {isVerified ? '✓ Verified' : 'Mark as Verified'}
                </Button>
              )}
              <Button
                onClick={() => window.open(fileUrl, '_blank')}
                className="flex-1 bg-slate-700 hover:bg-slate-600 text-white"
              >
                <Eye className="w-4 h-4 mr-2" />
                Open in New Tab
              </Button>
              <Button onClick={onClose} className="flex-1 bg-slate-700 hover:bg-slate-600 text-white">
                Close
              </Button>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
};

export default DocumentViewer;
