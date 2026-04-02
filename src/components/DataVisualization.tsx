/**
 * Data Visualization Components
 * Advanced charts and data display components
 */

import { motion } from 'framer-motion';
import { BarChart, Bar, LineChart, Line, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { cn } from '@/lib/utils';

interface ChartContainerProps {
  title: string;
  subtitle?: string;
  children: React.ReactNode;
  className?: string;
}

export const ChartContainer = ({ title, subtitle, children, className }: ChartContainerProps) => (
  <motion.div
    initial={{ opacity: 0, y: 10 }}
    animate={{ opacity: 1, y: 0 }}
    className={cn('card-polished space-y-4', className)}
  >
    <div className="space-y-1">
      <h3 className="subheading-premium">{title}</h3>
      {subtitle && <p className="body-premium text-gray-400">{subtitle}</p>}
    </div>
    {children}
  </motion.div>
);

interface BarChartDataItem {
  name: string;
  value: number;
  fill?: string;
}

interface BarChartProps {
  data: BarChartDataItem[];
  title: string;
  subtitle?: string;
  height?: number;
}

export const AdvancedBarChart = ({
  data,
  title,
  subtitle,
  height = 300,
}: BarChartProps) => {
  const colors = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444'];

  return (
    <ChartContainer title={title} subtitle={subtitle}>
      <ResponsiveContainer width="100%" height={height}>
        <BarChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis stroke="rgba(255,255,255,0.3)" />
          <YAxis stroke="rgba(255,255,255,0.3)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(15, 23, 42, 0.9)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
            }}
            labelStyle={{ color: '#fff' }}
          />
          <Bar dataKey="value" fill="#3b82f6" radius={[8, 8, 0, 0]}>
            {data.map((item, idx) => (
              <Cell key={`cell-${idx}`} fill={item.fill || colors[idx % colors.length]} />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
};

interface LineChartDataItem {
  name: string;
  value: number;
  value2?: number;
}

interface LineChartProps {
  data: LineChartDataItem[];
  title: string;
  subtitle?: string;
  height?: number;
}

export const AdvancedLineChart = ({
  data,
  title,
  subtitle,
  height = 300,
}: LineChartProps) => {
  return (
    <ChartContainer title={title} subtitle={subtitle}>
      <ResponsiveContainer width="100%" height={height}>
        <LineChart data={data}>
          <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
          <XAxis stroke="rgba(255,255,255,0.3)" />
          <YAxis stroke="rgba(255,255,255,0.3)" />
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(15, 23, 42, 0.9)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
            }}
            labelStyle={{ color: '#fff' }}
          />
          <Legend />
          <Line
            type="monotone"
            dataKey="value"
            stroke="#3b82f6"
            strokeWidth={2}
            dot={{ fill: '#3b82f6', r: 4 }}
            activeDot={{ r: 6 }}
          />
          {data[0]?.value2 !== undefined && (
            <Line
              type="monotone"
              dataKey="value2"
              stroke="#8b5cf6"
              strokeWidth={2}
              dot={{ fill: '#8b5cf6', r: 4 }}
              activeDot={{ r: 6 }}
            />
          )}
        </LineChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
};

interface PieChartDataItem {
  name: string;
  value: number;
  fill?: string;
}

interface PieChartProps {
  data: PieChartDataItem[];
  title: string;
  subtitle?: string;
  height?: number;
}

export const AdvancedPieChart = ({
  data,
  title,
  subtitle,
  height = 300,
}: PieChartProps) => {
  const colors = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444'];

  return (
    <ChartContainer title={title} subtitle={subtitle}>
      <ResponsiveContainer width="100%" height={height}>
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            labelLine={false}
            label={(entry) => entry.name}
            outerRadius={80}
            fill="#8884d8"
            dataKey="value"
          >
            {data.map((item, idx) => (
              <Cell key={`cell-${idx}`} fill={item.fill || colors[idx % colors.length]} />
            ))}
          </Pie>
          <Tooltip
            contentStyle={{
              backgroundColor: 'rgba(15, 23, 42, 0.9)',
              border: '1px solid rgba(255,255,255,0.2)',
              borderRadius: '8px',
            }}
            labelStyle={{ color: '#fff' }}
          />
        </PieChart>
      </ResponsiveContainer>
    </ChartContainer>
  );
};

interface StatGridItem {
  label: string;
  value: string | number;
  change?: number;
  icon?: React.ReactNode;
  trend?: 'up' | 'down' | 'neutral';
}

interface StatGridProps {
  stats: StatGridItem[];
  columns?: number;
}

export const StatsGrid = ({ stats, columns = 4 }: StatGridProps) => {
  return (
    <div className={cn('grid gap-6', {
      'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4': columns === 4,
      'grid-cols-1 sm:grid-cols-2 lg:grid-cols-3': columns === 3,
      'grid-cols-1 sm:grid-cols-2': columns === 2,
    })}>
      {stats.map((stat, idx) => (
        <motion.div
          key={idx}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: idx * 0.1 }}
          className="card-polished"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-2">
              <p className="text-sm text-gray-400">{stat.label}</p>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
              {stat.change !== undefined && (
                <p className={cn(
                  'text-xs font-semibold',
                  stat.trend === 'up' ? 'text-emerald-400' : stat.trend === 'down' ? 'text-rose-400' : 'text-gray-400'
                )}>
                  {stat.trend === 'up' ? '↑' : stat.trend === 'down' ? '↓' : '→'} {Math.abs(stat.change)}%
                </p>
              )}
            </div>
            {stat.icon && (
              <div className="text-3xl opacity-50">
                {stat.icon}
              </div>
            )}
          </div>
        </motion.div>
      ))}
    </div>
  );
};
