/**
 * Error Boundary Component
 * Catches and displays React errors gracefully
 */

import { ReactNode, Component, ErrorInfo } from 'react';
import { AlertTriangle, RotateCcw } from 'lucide-react';
import { motion } from 'framer-motion';

interface Props {
  children: ReactNode;
  fallback?: (error: Error, retry: () => void) => ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  retry = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      return (
        this.props.fallback?.(this.state.error!, this.retry) || (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-slate-900 to-slate-950"
          >
            <div className="card-polished max-w-md space-y-6">
              <div className="flex items-center justify-center w-12 h-12 rounded-lg bg-rose-900/50 mx-auto">
                <AlertTriangle className="w-6 h-6 text-rose-400" />
              </div>
              <div className="space-y-2">
                <h1 className="heading-premium text-center">Oops! Something went wrong</h1>
                <p className="body-premium text-center text-gray-400">
                  {this.state.error?.message || 'An unexpected error occurred'}
                </p>
              </div>
              <div className="space-y-2">
                <button
                  onClick={this.retry}
                  className="w-full px-4 py-3 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-semibold hover:from-blue-700 hover:to-indigo-700 transition-all duration-300 flex items-center justify-center gap-2"
                >
                  <RotateCcw className="w-4 h-4" />
                  Try Again
                </button>
                <button
                  onClick={() => window.location.href = '/'}
                  className="w-full px-4 py-3 rounded-lg bg-slate-800/50 text-white font-semibold hover:bg-slate-800 transition-all duration-300"
                >
                  Go Home
                </button>
              </div>
            </div>
          </motion.div>
        )
      );
    }

    return this.props.children;
  }
}

/**
 * Offline Fallback Component
 */
export const OfflineFallback = () => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="fixed bottom-4 left-4 right-4 z-50 card-polished p-4 border-l-4 border-amber-500"
  >
    <p className="text-sm font-medium text-amber-400">
      You're currently offline. Some features may be limited.
    </p>
  </motion.div>
);

/**
 * Retry Logic Hook
 */
export const useRetry = (
  fn: () => Promise<any>,
  maxRetries = 3,
  delayMs = 1000
) => {
  const [retryCount, setRetryCount] = 0;
  const [error, setError] = null;
  const [isRetrying, setIsRetrying] = 0;

  const retry = async () => {
    setIsRetrying(1);
    setError(null);

    for (let i = 0; i < maxRetries; i++) {
      try {
        await fn();
        setIsRetrying(0);
        setRetryCount(0);
        return;
      } catch (err) {
        if (i < maxRetries - 1) {
          await new Promise((resolve) => setTimeout(resolve, delayMs));
        } else {
          setError(err);
          setIsRetrying(0);
          setRetryCount((prev) => prev + 1);
        }
      }
    }
  };

  return { retry, retryCount, error, isRetrying };
};

/**
 * Network Status Hook
 */
import { useEffect, useState } from 'react';

export const useNetworkStatus = () => {
  const [isOnline, setIsOnline] = useState(true);

  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  return { isOnline };
};
