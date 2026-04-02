import { useNavigate, useLocation } from 'react-router-dom';
import { ChevronRight, Home } from 'lucide-react';
import { motion } from 'framer-motion';

interface BreadcrumbItem {
  label: string;
  path?: string;
}

interface BreadcrumbProps {
  items?: BreadcrumbItem[];
  className?: string;
}

// Auto-generate breadcrumbs from current path
const getDefaultBreadcrumbs = (pathname: string): BreadcrumbItem[] => {
  const breadcrumbMap: Record<string, string> = {
    'dashboard': 'Dashboard',
    'account': 'Account',
    'restaurant': 'Restaurants',
    'rider': 'Riders',
    'hotel': 'Hotels',
    'taxi': 'Taxi',
    'admin': 'Admin',
    'verification': 'Verification',
    'order-history': 'Order History',
    'favorites': 'Favorites',
    'addresses': 'Addresses',
    'profile': 'Profile',
  };

  const path = pathname.split('/').filter(Boolean);
  const items: BreadcrumbItem[] = [{ label: 'Home', path: '/' }];

  path.forEach((segment, index) => {
    const fullPath = '/' + path.slice(0, index + 1).join('/');
    const label = breadcrumbMap[segment] || segment.charAt(0).toUpperCase() + segment.slice(1);
    items.push({ label, path: fullPath });
  });

  return items;
};

export const Breadcrumb = ({ items, className = '' }: BreadcrumbProps) => {
  const navigate = useNavigate();
  const location = useLocation();

  const breadcrumbs = items || getDefaultBreadcrumbs(location.pathname);

  if (breadcrumbs.length <= 1) return null;

  return (
    <motion.nav
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className={`flex items-center gap-1 text-sm text-slate-600 dark:text-slate-400 overflow-x-auto pb-2 ${className}`}
      aria-label="Breadcrumb"
    >
      {breadcrumbs.map((item, index) => {
        const isLast = index === breadcrumbs.length - 1;

        return (
          <div key={index} className="flex items-center gap-1 whitespace-nowrap">
            {index === 0 && (
              <motion.button
                onClick={() => navigate(item.path || '/')}
                className="p-1 hover:bg-slate-100 dark:hover:bg-slate-800 rounded transition-colors"
                whileHover={{ scale: 1.1 }}
                whileTap={{ scale: 0.95 }}
                aria-label="Go to home"
              >
                <Home className="w-4 h-4" />
              </motion.button>
            )}

            {index > 0 && <ChevronRight className="w-4 h-4 text-slate-300 dark:text-slate-600 flex-shrink-0" />}

            {isLast ? (
              <span className="font-medium text-slate-900 dark:text-slate-100">{item.label}</span>
            ) : (
              <motion.button
                onClick={() => item.path && navigate(item.path)}
                className="text-blue-600 dark:text-blue-400 hover:underline transition-colors cursor-pointer"
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
              >
                {item.label}
              </motion.button>
            )}
          </div>
        );
      })}
    </motion.nav>
  );
};

export default Breadcrumb;
