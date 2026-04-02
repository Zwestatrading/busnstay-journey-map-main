import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Bell, X, AlertTriangle, CheckCircle, Info, Clock, ArrowRight } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';

export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: Date;
  read: boolean;
  action?: {
    label: string;
    onClick: () => void;
  };
}

interface NotificationCenterProps {
  notifications?: Notification[];
  onDismiss?: (id: string) => void;
}

const NotificationCenter = ({ 
  notifications = [], 
  onDismiss 
}: NotificationCenterProps) => {
  const [isOpen, setIsOpen] = useState(false);
  const unreadCount = notifications.filter(n => !n.read).length;

  const getIcon = (type: string) => {
    switch(type) {
      case 'success': return <CheckCircle className="w-5 h-5 text-emerald-400" />;
      case 'warning': return <AlertTriangle className="w-5 h-5 text-amber-400" />;
      case 'error': return <AlertTriangle className="w-5 h-5 text-rose-400" />;
      default: return <Info className="w-5 h-5 text-blue-400" />;
    }
  };

  const getTypeClass = (type: string) => {
    switch(type) {
      case 'success': return 'from-emerald-900/20 to-teal-900/20 border-emerald-700/50 hover:border-emerald-600/50';
      case 'warning': return 'from-amber-900/20 to-yellow-900/20 border-amber-700/50 hover:border-amber-600/50';
      case 'error': return 'from-rose-900/20 to-red-900/20 border-rose-700/50 hover:border-rose-600/50';
      default: return 'from-blue-900/20 to-cyan-900/20 border-blue-700/50 hover:border-blue-600/50';
    }
  };

  return (
    <div className="relative">
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={() => setIsOpen(!isOpen)}
        className={cn(
          'relative p-2.5 rounded-lg transition-all duration-300',
          'bg-gradient-to-br from-slate-800/40 to-slate-900/40 border border-white/10',
          'hover:bg-slate-800/60 hover:border-white/20 focus:outline-none focus:ring-2 focus:ring-blue-500/50',
          isOpen && 'bg-slate-800/80 border-white/20'
        )}
      >
        <Bell className="w-5 h-5 text-white" />
        <AnimatePresence>
          {unreadCount > 0 && (
            <motion.div
              initial={{ scale: 0, rotate: -180 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0, rotate: 180 }}
              transition={{ type: 'spring', stiffness: 200, damping: 10 }}
              className="absolute -top-1 -right-1 w-5 h-5 bg-gradient-to-br from-rose-500 to-pink-500 rounded-full text-white text-xs font-bold flex items-center justify-center shadow-lg shadow-rose-500/50"
            >
              {unreadCount > 9 ? '9+' : unreadCount}
            </motion.div>
          )}
        </AnimatePresence>
      </motion.button>

      <AnimatePresence>
        {isOpen && (
          <>
            {/* Backdrop */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsOpen(false)}
              className="fixed inset-0 z-40"
            />
            
            {/* Notification Panel */}
            <motion.div
              initial={{ opacity: 0, y: -10, scale: 0.95 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              exit={{ opacity: 0, y: -10, scale: 0.95 }}
              transition={{ type: 'spring', stiffness: 300, damping: 25 }}
              className="absolute right-0 top-12 w-96 max-h-96 bg-gradient-to-br from-slate-900 via-slate-950 to-slate-950 border border-white/10 rounded-2xl shadow-2xl shadow-black/50 overflow-hidden z-50 backdrop-blur-xl"
            >
              {/* Header */}
              <div className="bg-gradient-to-r from-blue-600/15 to-purple-600/15 border-b border-white/10 px-6 py-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="p-2 bg-blue-600/30 rounded-lg">
                      <Bell className="w-4 h-4 text-blue-400" />
                    </div>
                    <h3 className="text-white font-semibold text-lg">Notifications</h3>
                  </div>
                  <motion.button
                    whileHover={{ rotate: 90 }}
                    onClick={() => setIsOpen(false)}
                    className="text-gray-400 hover:text-white transition"
                  >
                    <X className="w-5 h-5" />
                  </motion.button>
                </div>
              </div>

              {/* Content */}
              <div className="overflow-y-auto max-h-80 scroll-smooth">
                {notifications.length === 0 ? (
                  <motion.div
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    className="p-8 text-center space-y-3"
                  >
                    <div className="p-3 w-12 h-12 mx-auto rounded-full bg-slate-800/50 flex items-center justify-center">
                      <Bell className="w-6 h-6 text-gray-500" />
                    </div>
                    <p className="text-gray-400 text-sm font-medium">No notifications</p>
                    <p className="text-gray-500 text-xs">You're all caught up!</p>
                  </motion.div>
                ) : (
                  <div className="divide-y divide-white/5">
                    {notifications.map((notif, index) => (
                      <motion.div
                        key={notif.id}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: index * 0.05 }}
                        className={cn(
                          'bg-gradient-to-r p-4 transition-all duration-300 hover:bg-white/5',
                          getTypeClass(notif.type)
                        )}
                      >
                        <div className="flex gap-3">
                          <div className="flex-shrink-0 mt-1">
                            {getIcon(notif.type)}
                          </div>
                          <div className="flex-1 min-w-0">
                            <p className="font-semibold text-white text-sm leading-snug">
                              {notif.title}
                            </p>
                            <p className="text-gray-400 text-xs mt-1 line-clamp-2 leading-snug">
                              {notif.message}
                            </p>
                            <div className="flex items-center justify-between mt-3 pt-2 border-t border-white/5">
                              <span className="text-gray-500 text-xs flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                {notif.timestamp.toLocaleTimeString([], {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </span>
                              {notif.action ? (
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  onClick={notif.action.onClick}
                                  className="h-6 text-xs px-2 text-blue-400 hover:text-blue-300 hover:bg-blue-500/10 transition-all"
                                >
                                  {notif.action.label}
                                  <ArrowRight className="w-3 h-3 ml-1" />
                                </Button>
                              ) : (
                                onDismiss && (
                                  <motion.button
                                    whileHover={{ scale: 1.1 }}
                                    onClick={() => onDismiss(notif.id)}
                                    className="text-gray-500 hover:text-white transition flex-shrink-0"
                                  >
                                    <X className="w-4 h-4" />
                                  </motion.button>
                                )
                              )}
                            </div>
                          </div>
                        </div>
                      </motion.div>
                    ))}
                  </div>
                )}
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </div>
  );
};

export default NotificationCenter;
