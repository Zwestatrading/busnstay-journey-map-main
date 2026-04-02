import { motion } from 'framer-motion';

interface LoadingSkeletonProps {
  type?: 'card' | 'text' | 'circle' | 'rectangle' | 'restaurant' | 'grid';
  count?: number;
  className?: string;
}

const pulse = {
  opacity: [0.6, 1, 0.6],
  transition: { duration: 1.5, repeat: Infinity },
};

// Individual skeleton line
const SkeletonLine = ({ width = 'w-full', height = 'h-4' }: { width?: string; height?: string }) => (
  <motion.div
    className={`${width} ${height} bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 dark:from-slate-700 dark:via-slate-600 dark:to-slate-700 rounded`}
    animate={pulse}
  />
);

// Restaurant card skeleton
const RestaurantSkeleton = () => (
  <motion.div
    className="bg-white dark:bg-slate-800 rounded-lg shadow overflow-hidden"
    animate={pulse}
  >
    <div className="h-40 bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 dark:from-slate-700 dark:via-slate-600 dark:to-slate-700" />
    <div className="p-4 space-y-3">
      <SkeletonLine height="h-5" />
      <SkeletonLine width="w-3/4" height="h-3" />
      <div className="flex gap-2">
        <SkeletonLine width="w-20" height="h-3" />
        <SkeletonLine width="w-20" height="h-3" />
      </div>
    </div>
  </motion.div>
);

// Text skeleton (multiple lines)
const TextSkeleton = ({ lines = 3 }: { lines?: number }) => (
  <div className="space-y-3">
    {Array.from({ length: lines }).map((_, i) => (
      <SkeletonLine
        key={i}
        width={i === lines - 1 ? 'w-3/4' : 'w-full'}
        height={i === 0 ? 'h-6' : 'h-4'}
      />
    ))}
  </div>
);

// Circle skeleton (for avatars)
const CircleSkeleton = ({ size = 'w-12 h-12' }: { size?: string }) => (
  <motion.div
    className={`${size} bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 dark:from-slate-700 dark:via-slate-600 dark:to-slate-700 rounded-full`}
    animate={pulse}
  />
);

// Rectangle skeleton
const RectangleSkeleton = ({ width = 'w-full', height = 'h-32' }: { width?: string; height?: string }) => (
  <motion.div
    className={`${width} ${height} bg-gradient-to-r from-slate-200 via-slate-100 to-slate-200 dark:from-slate-700 dark:via-slate-600 dark:to-slate-700 rounded-lg`}
    animate={pulse}
  />
);

// Grid skeleton
const GridSkeleton = ({ columns = 2 }: { columns?: number }) => (
  <div className={`grid grid-cols-1 md:grid-cols-${columns} gap-4`}>
    {Array.from({ length: columns * 2 }).map((_, i) => (
      <RestaurantSkeleton key={i} />
    ))}
  </div>
);

export const LoadingSkeleton = ({
  type = 'text',
  count = 3,
  className = '',
}: LoadingSkeletonProps) => {
  let content;

  switch (type) {
    case 'card':
      content = <RestaurantSkeleton />;
      break;
    case 'circle':
      content = <CircleSkeleton />;
      break;
    case 'rectangle':
      content = <RectangleSkeleton />;
      break;
    case 'restaurant':
      content = (
        <div className="space-y-4">
          {Array.from({ length: count }).map((_, i) => (
            <RestaurantSkeleton key={i} />
          ))}
        </div>
      );
      break;
    case 'grid':
      content = <GridSkeleton columns={count} />;
      break;
    case 'text':
    default:
      content = <TextSkeleton lines={count} />;
  }

  return <div className={className}>{content}</div>;
};

export { SkeletonLine, RestaurantSkeleton, TextSkeleton, CircleSkeleton, RectangleSkeleton, GridSkeleton };
