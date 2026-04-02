import { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { containerVariants, itemVariants } from '../utils/animations';

interface ResponsiveGridProps {
  children: ReactNode;
  columns?: {
    sm?: number;
    md?: number;
    lg?: number;
  };
  gap?: number;
  animated?: boolean;
  className?: string;
}

export const ResponsiveGrid = ({
  children,
  columns = { sm: 1, md: 2, lg: 3 },
  gap = 4,
  animated = true,
  className = '',
}: ResponsiveGridProps) => {
  const gridColsClass = `
    ${columns.sm ? `grid-cols-${columns.sm}` : 'grid-cols-1'}
    ${columns.md ? `md:grid-cols-${columns.md}` : 'md:grid-cols-2'}
    ${columns.lg ? `lg:grid-cols-${columns.lg}` : 'lg:grid-cols-3'}
  `.trim().split('\n').join(' ');

  const gapClass = `gap-${gap}`;

  const wrapper = animated
    ? (
        <motion.div
          variants={containerVariants}
          initial="initial"
          animate="animate"
          className={`grid ${gridColsClass} ${gapClass} ${className}`}
        >
          {children}
        </motion.div>
      )
    : (
        <div className={`grid ${gridColsClass} ${gapClass} ${className}`}>
          {children}
        </div>
      );

  return wrapper;
};

interface ResponsiveGridItemProps {
  children: ReactNode;
  span?: {
    sm?: number;
    md?: number;
    lg?: number;
  };
  className?: string;
}

export const ResponsiveGridItem = ({
  children,
  span = { sm: 1, md: 1, lg: 1 },
  className = '',
}: ResponsiveGridItemProps) => {
  const spanClass = `
    ${span.sm ? `col-span-${span.sm}` : 'col-span-1'}
    ${span.md ? `md:col-span-${span.md}` : ''}
    ${span.lg ? `lg:col-span-${span.lg}` : ''}
  `.trim().split('\n').join(' ');

  return (
    <motion.div
      variants={itemVariants}
      className={`${spanClass} ${className}`}
    >
      {children}
    </motion.div>
  );
};

export default ResponsiveGrid;
