import { motion } from 'framer-motion';
import { Button } from '@/components/ui/button';
import {
  ShoppingCart,
  Heart,
  MapPin,
  Search,
  AlertCircle,
  Package,
  Smile,
} from 'lucide-react';

interface EmptyStateProps {
  type?: 'orders' | 'favorites' | 'addresses' | 'search' | 'error' | 'generic';
  title?: string;
  description?: string;
  actionLabel?: string;
  onAction?: () => void;
  icon?: React.ReactNode;
}

const emptyStateConfigs = {
  orders: {
    icon: ShoppingCart,
    title: "No Orders Yet",
    description: "You haven't placed any orders yet. Start exploring restaurants and place your first order!",
    actionLabel: "Browse Restaurants",
  },
  favorites: {
    icon: Heart,
    title: "No Favorites",
    description: "Add your favorite restaurants here for quick access next time!",
    actionLabel: "Explore Restaurants",
  },
  addresses: {
    icon: MapPin,
    title: "No Saved Addresses",
    description: "Save your favorite addresses for faster checkout.",
    actionLabel: "Add Address",
  },
  search: {
    icon: Search,
    title: "No Results Found",
    description: "Try adjusting your search terms or filters.",
    actionLabel: "Clear Filters",
  },
  error: {
    icon: AlertCircle,
    title: "Something Went Wrong",
    description: "An error occurred while loading. Please try again.",
    actionLabel: "Try Again",
  },
  generic: {
    icon: Package,
    title: "Nothing Here Yet",
    description: "Check back later or explore other options.",
    actionLabel: "Go Back",
  },
};

export const EmptyState = ({
  type = 'generic',
  title,
  description,
  actionLabel,
  onAction,
  icon: customIcon,
}: EmptyStateProps) => {
  const config = emptyStateConfigs[type] || emptyStateConfigs.generic;
  const Icon = customIcon ? null : config.icon;

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      className="flex flex-col items-center justify-center py-12 px-4 text-center"
    >
      {/* Icon */}
      <motion.div
        animate={{ scale: [1, 1.1, 1] }}
        transition={{ duration: 2, repeat: Infinity }}
        className="mb-4"
      >
        {customIcon ? (
          customIcon
        ) : (
          <div className="w-16 h-16 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center">
            {Icon && <Icon className="w-8 h-8 text-slate-400 dark:text-slate-500" />}
          </div>
        )}
      </motion.div>

      {/* Title */}
      <h3 className="text-lg font-semibold text-slate-900 dark:text-slate-100 mb-2">
        {title || config.title}
      </h3>

      {/* Description */}
      <p className="text-sm text-slate-500 dark:text-slate-400 max-w-sm mb-6">
        {description || config.description}
      </p>

      {/* Action Button */}
      {onAction && (
        <motion.div whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}>
          <Button onClick={onAction} size="sm" className="cursor-pointer">
            {actionLabel || config.actionLabel}
          </Button>
        </motion.div>
      )}
    </motion.div>
  );
};

export default EmptyState;
