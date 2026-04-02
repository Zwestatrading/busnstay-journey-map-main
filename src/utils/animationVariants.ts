/**
 * Advanced Animation Utilities
 * Reusable animation variants and transition helpers
 */

import { Variants } from 'framer-motion';

/**
 * Page Transition Variants
 */
export const pageVariants: Variants = {
  hidden: { opacity: 0, y: 20 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: 'easeOut' },
  },
  exit: { opacity: 0, y: -20, transition: { duration: 0.3 } },
};

/**
 * Stagger Container Variants (for animating children)
 */
export const containerVariants: Variants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

/**
 * Card Entrance Variants
 */
export const cardVariants: Variants = {
  hidden: { opacity: 0, y: 20, scale: 0.95 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: { duration: 0.3, ease: 'easeOut' },
  },
  hover: {
    y: -5,
    boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.3)',
    transition: { duration: 0.2 },
  },
};

/**
 * Skeleton Loader Animation
 */
export const skeletonVariants: Variants = {
  loading: {
    backgroundColor: ['rgba(255,255,255,0.1)', 'rgba(255,255,255,0.2)', 'rgba(255,255,255,0.1)'],
    transition: { duration: 1.5, repeat: Infinity },
  },
};

/**
 * Modal/Overlay Variants
 */
export const modalVariants: Variants = {
  hidden: { opacity: 0, scale: 0.8 },
  visible: {
    opacity: 1,
    scale: 1,
    transition: { type: 'spring', stiffness: 300, damping: 25 },
  },
  exit: { opacity: 0, scale: 0.8 },
};

/**
 * Badge Animation
 */
export const badgeVariants: Variants = {
  initial: { scale: 0, rotate: -180 },
  animate: { scale: 1, rotate: 0, transition: { type: 'spring', stiffness: 200 } },
  exit: { scale: 0, rotate: 180 },
};

/**
 * Rotation Animation
 */
export const rotationVariants: Variants = {
  rotating: {
    rotate: 360,
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'linear',
    },
  },
};

/**
 * Pulse Animation
 */
export const pulseVariants: Variants = {
  pulsing: {
    scale: [1, 1.1, 1],
    opacity: [1, 0.8, 1],
    transition: {
      duration: 2,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

/**
 * Slide Animation
 */
export const slideVariants: Variants = {
  hidden: { x: -100, opacity: 0 },
  visible: {
    x: 0,
    opacity: 1,
    transition: { duration: 0.4, ease: 'easeOut' },
  },
};

/**
 * Bounce Animation
 */
export const bounceVariants: Variants = {
  bounce: {
    y: [0, -10, 0],
    transition: {
      duration: 0.6,
      repeat: Infinity,
      ease: 'easeInOut',
    },
  },
};

/**
 * Skeleton Loader Component
 */
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface SkeletonProps {
  width?: string;
  height?: string;
  count?: number;
  circle?: boolean;
  className?: string;
}

export const Skeleton = ({
  width = '100%',
  height = '20px',
  count = 1,
  circle = false,
  className,
}: SkeletonProps) => {
  return (
    <div className="space-y-2">
      {Array.from({ length: count }).map((_, idx) => (
        <motion.div
          key={idx}
          variants={skeletonVariants}
          animate="loading"
          className={cn(
            'bg-slate-800/50 rounded',
            circle && 'rounded-full',
            className
          )}
          style={{ width, height }}
        />
      ))}
    </div>
  );
};
