/**
 * Mobile Navigation Component
 * Bottom tab navigation optimized for mobile experiences
 */

import { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { useLocation, useNavigate } from 'react-router-dom';
import { cn } from '@/lib/utils';

export interface MobileNavItem {
  icon: ReactNode;
  label: string;
  path: string;
  badge?: number;
}

interface MobileNavProps {
  items: MobileNavItem[];
  className?: string;
}

export const MobileBottomNav = ({ items, className }: MobileNavProps) => {
  const location = useLocation();
  const navigate = useNavigate();

  return (
    <motion.nav
      initial={{ y: 100 }}
      animate={{ y: 0 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className={cn(
        'fixed bottom-0 left-0 right-0 z-40 md:hidden',
        'bg-gradient-to-t from-slate-950 via-slate-900 to-slate-900/95',
        'border-t border-white/10 backdrop-blur-xl',
        'safe-area-inset-bottom',
        className
      )}
    >
      <div className="flex items-center justify-around h-20 px-2">
        {items.map((item) => {
          const isActive = location.pathname === item.path;
          
          return (
            <motion.button
              key={item.path}
              onClick={() => navigate(item.path)}
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.95 }}
              className={cn(
                'relative flex flex-col items-center justify-center w-16 h-16 rounded-lg transition-all duration-300',
                'group',
                isActive
                  ? 'text-blue-400'
                  : 'text-gray-400 hover:text-white'
              )}
            >
              {/* Background active indicator */}
              {isActive && (
                <motion.div
                  layoutId="mobileNav"
                  className="absolute inset-0 bg-blue-600/20 rounded-lg"
                  transition={{ type: 'spring', stiffness: 300, damping: 30 }}
                />
              )}

              {/* Icon */}
              <motion.div
                className="relative z-10 text-2xl"
                animate={isActive ? { scale: 1.1 } : { scale: 1 }}
              >
                {item.icon}
              </motion.div>

              {/* Label */}
              <motion.span
                className="text-xs mt-1 font-medium relative z-10"
                animate={isActive ? { opacity: 1 } : { opacity: 0.7 }}
              >
                {item.label}
              </motion.span>

              {/* Badge */}
              {item.badge && item.badge > 0 && (
                <motion.span
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  className="absolute -top-1 -right-1 w-5 h-5 bg-rose-500 rounded-full text-white text-xs font-bold flex items-center justify-center shadow-lg"
                >
                  {item.badge > 99 ? '99+' : item.badge}
                </motion.span>
              )}
            </motion.button>
          );
        })}
      </div>
    </motion.nav>
  );
};

/**
 * Mobile gesture handler
 */
export const useMobileGestures = (
  onSwipeLeft?: () => void,
  onSwipeRight?: () => void,
  onLongPress?: () => void
) => {
  const touchStartX = { current: 0 };
  const touchStartTime = { current: 0 };

  const handleTouchStart = (e: React.TouchEvent) => {
    touchStartX.current = e.touches[0].clientX;
    touchStartTime.current = Date.now();
  };

  const handleTouchEnd = (e: React.TouchEvent) => {
    const touchEndX = e.changedTouches[0].clientX;
    const touchDuration = Date.now() - touchStartTime.current;
    const diff = touchStartX.current - touchEndX;

    // Long press (held for > 500ms)
    if (touchDuration > 500 && Math.abs(diff) < 10) {
      onLongPress?.();
      return;
    }

    // Swipe threshold: 50px
    if (Math.abs(diff) > 50) {
      if (diff > 0) {
        onSwipeLeft?.();
      } else {
        onSwipeRight?.();
      }
    }
  };

  return { handleTouchStart, handleTouchEnd };
};
