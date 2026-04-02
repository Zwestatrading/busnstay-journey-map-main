/**
 * Enhanced Dashboard Layout Component
 * Provides consistent, polished dashboard layouts with premium styling
 */

import { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { cn } from '@/lib/utils';

interface DashboardLayoutProps {
  title: string;
  subtitle?: string;
  children: ReactNode;
  className?: string;
  headerAction?: ReactNode;
}

export const DashboardLayout = ({
  title,
  subtitle,
  children,
  className,
  headerAction,
}: DashboardLayoutProps) => {
  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
      className={cn(
        'min-h-screen bg-gradient-to-br from-slate-900 via-slate-950 to-black',
        className
      )}
    >
      {/* Premium Header */}
      <header className="sticky top-0 z-40 border-b border-white/10 bg-slate-950/80 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4"
          >
            <div className="space-y-2">
              <h1 className="text-3xl sm:text-4xl font-bold text-gradient">
                {title}
              </h1>
              {subtitle && (
                <p className="text-gray-400 text-sm sm:text-base">
                  {subtitle}
                </p>
              )}
            </div>
            {headerAction && <div className="w-full sm:w-auto">{headerAction}</div>}
          </motion.div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 sm:py-12">
        {children}
      </main>
    </motion.div>
  );
};

interface StatCardProps {
  icon: ReactNode;
  label: string;
  value: string | number;
  change?: { value: number; positive: boolean };
  gradient?: 'blue' | 'purple' | 'emerald' | 'rose';
}

export const StatCard = ({
  icon,
  label,
  value,
  change,
  gradient = 'blue',
}: StatCardProps) => {
  const gradientClass = {
    blue: 'from-blue-600/20 to-indigo-600/20 border-blue-500/20',
    purple: 'from-purple-600/20 to-pink-600/20 border-purple-500/20',
    emerald: 'from-emerald-600/20 to-teal-600/20 border-emerald-500/20',
    rose: 'from-rose-600/20 to-pink-600/20 border-rose-500/20',
  }[gradient];

  const iconColorClass = {
    blue: 'text-blue-400',
    purple: 'text-purple-400',
    emerald: 'text-emerald-400',
    rose: 'text-rose-400',
  }[gradient];

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      whileHover={{ y: -4, transform: 'scale(1.02)' }}
      className={cn(
        'glass-effect bg-gradient-to-br p-6 rounded-xl border transition-all duration-300',
        gradientClass
      )}
    >
      <div className="flex items-start justify-between">
        <div className="space-y-2">
          <p className="text-gray-400 text-sm font-medium">{label}</p>
          <p className="text-3xl sm:text-4xl font-bold text-white">{value}</p>
          {change && (
            <p
              className={cn(
                'text-xs font-semibold flex items-center gap-1',
                change.positive ? 'text-emerald-400' : 'text-rose-400'
              )}
            >
              {change.positive ? '↑' : '↓'} {Math.abs(change.value)}% from last month
            </p>
          )}
        </div>
        <div className={cn('text-2xl opacity-80', iconColorClass)}>{icon}</div>
      </div>
    </motion.div>
  );
};

interface EnhancedTabsProps {
  tabs: Array<{
    id: string;
    label: string;
    icon?: ReactNode;
    content: ReactNode;
  }>;
  defaultTab?: string;
  onChange?: (tabId: string) => void;
}

export const EnhancedTabs = ({ tabs, defaultTab, onChange }: EnhancedTabsProps) => {
  const [activeTab, setActiveTab] = React.useState(defaultTab || tabs[0]?.id);

  const handleTabChange = (tabId: string) => {
    setActiveTab(tabId);
    onChange?.(tabId);
  };

  return (
    <div className="space-y-6">
      {/* Tab Navigation */}
      <div className="flex overflow-x-auto border-b border-white/10 gap-0 -mx-4 px-4 sm:mx-0 sm:px-0">
        {tabs.map((tab) => (
          <motion.button
            key={tab.id}
            onClick={() => handleTabChange(tab.id)}
            className={cn(
              'relative px-4 py-4 font-medium text-sm sm:text-base whitespace-nowrap transition-colors duration-300',
              activeTab === tab.id
                ? 'text-white'
                : 'text-gray-400 hover:text-gray-300'
            )}
          >
            <div className="flex items-center gap-2">
              {tab.icon && <span className="text-lg">{tab.icon}</span>}
              {tab.label}
            </div>
            {activeTab === tab.id && (
              <motion.div
                layoutId="activeTab"
                className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-blue-500 to-purple-500"
                transition={{ duration: 0.3 }}
              />
            )}
          </motion.button>
        ))}
      </div>

      {/* Tab Content */}
      <motion.div
        key={activeTab}
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: -10 }}
        transition={{ duration: 0.3 }}
      >
        {tabs.find((tab) => tab.id === activeTab)?.content}
      </motion.div>
    </div>
  );
};

interface PremiumCardProps {
  title?: string;
  subtitle?: string;
  children: ReactNode;
  className?: string;
  hover?: boolean;
}

export const PremiumCard = ({
  title,
  subtitle,
  children,
  className,
  hover = true,
}: PremiumCardProps) => {
  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4 }}
      whileHover={hover ? { y: -4 } : undefined}
      className={cn(
        'glass-effect bg-gradient-to-br from-slate-800/50 to-slate-900/50 p-6 sm:p-8 rounded-xl border border-white/10 transition-all duration-300',
        hover && 'hover:border-white/20 hover:shadow-xl hover:shadow-blue-500/10',
        className
      )}
    >
      {(title || subtitle) && (
        <div className="mb-6 pb-4 border-b border-white/10">
          {title && <h3 className="text-lg font-bold text-white">{title}</h3>}
          {subtitle && <p className="text-sm text-gray-400 mt-1">{subtitle}</p>}
        </div>
      )}
      {children}
    </motion.div>
  );
};

// Add required React import
import React from 'react';
