import { motion } from 'framer-motion';
import { LineChart, Line, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { TrendingUp, DollarSign, MapPin, Clock, Award } from 'lucide-react';
import { cn } from '@/lib/utils';

interface TripAnalyticsProps {
  totalTrips?: number;
  totalDistance?: number;
  totalSpent?: number;
  averageRating?: number;
  recentTrips?: any[];
  spendingByCategory?: any[];
  monthlyTrends?: any[];
}

const TripAnalytics = ({
  totalTrips = 24,
  totalDistance = 1240,
  totalSpent = 2850,
  averageRating = 4.7,
  recentTrips = [],
  spendingByCategory = [
    { name: 'Bus Fare', value: 1200, color: '#3b82f6' },
    { name: 'Food & Drinks', value: 950, color: '#10b981' },
    { name: 'Hotels', value: 450, color: '#f59e0b' },
    { name: 'Taxi', value: 250, color: '#8b5cf6' }
  ],
  monthlyTrends = [
    { month: 'Jan', trips: 3, spent: 250 },
    { month: 'Feb', trips: 2, spent: 180 },
    { month: 'Mar', trips: 5, spent: 450 },
    { month: 'Apr', trips: 4, spent: 380 },
    { month: 'May', trips: 6, spent: 520 },
    { month: 'Jun', trips: 4, spent: 370 }
  ]
} : TripAnalyticsProps) => {
  const stats = [
    {
      icon: MapPin,
      label: 'Total Trips',
      value: totalTrips,
      change: '+12%',
      color: 'from-blue-600 to-blue-700'
    },
    {
      icon: TrendingUp,
      label: 'Total Distance',
      value: `${totalDistance} km`,
      change: '+8%',
      color: 'from-green-600 to-green-700'
    },
    {
      icon: DollarSign,
      label: 'Total Spent',
      value: `$${totalSpent}`,
      change: '-5%',
      color: 'from-purple-600 to-purple-700'
    },
    {
      icon: Award,
      label: 'Avg Rating',
      value: averageRating,
      change: '+0.3',
      color: 'from-yellow-600 to-yellow-700'
    }
  ];

  return (
    <div className="w-full space-y-6">
      <div className="mb-8">
        <h2 className="text-3xl font-bold text-white mb-2">Your Travel Stats</h2>
        <p className="text-gray-400">Track your bus journey history and spending patterns</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, i) => {
          const Icon = stat.icon;
          return (
            <motion.div
              key={stat.label}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.1 }}
              className={cn(
                'bg-gradient-to-br rounded-xl p-5 border border-white/10 backdrop-blur-sm',
                `${stat.color}`
              )}
            >
              <div className="flex items-start justify-between mb-3">
                <div className="w-10 h-10 rounded-lg bg-white/20 flex items-center justify-center">
                  <Icon className="w-5 h-5 text-white" />
                </div>
                <span className="text-xs font-semibold text-green-300">{stat.change}</span>
              </div>
              <p className="text-gray-100 text-sm mb-1">{stat.label}</p>
              <p className="text-2xl font-bold text-white">{stat.value}</p>
            </motion.div>
          );
        })}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <motion.div
          initial={{ opacity: 0, x: -20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm"
        >
          <h3 className="text-white font-bold text-lg mb-4">Spending by Category</h3>
          <ResponsiveContainer width="100%" height={250}>
            <PieChart>
              <Pie
                data={spendingByCategory}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={90}
                paddingAngle={2}
                dataKey="value"
              >
                {spendingByCategory.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip 
                contentStyle={{
                  backgroundColor: 'rgba(15, 23, 42, 0.8)',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  borderRadius: '8px'
                }}
                formatter={(value) => `$${value}`}
              />
            </PieChart>
          </ResponsiveContainer>
          <div className="grid grid-cols-2 gap-2 mt-4">
            {spendingByCategory.map((cat) => (
              <div key={cat.name} className="flex items-center gap-2 text-sm">
                <div 
                  className="w-3 h-3 rounded-full"
                  style={{ backgroundColor: cat.color }}
                />
                <span className="text-gray-300">{cat.name}</span>
              </div>
            ))}
          </div>
        </motion.div>

        <motion.div
          initial={{ opacity: 0, x: 20 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ delay: 0.3 }}
          className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm"
        >
          <h3 className="text-white font-bold text-lg mb-4">Monthly Trends</h3>
          <ResponsiveContainer width="100%" height={250}>
            <BarChart data={monthlyTrends}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
              <XAxis dataKey="month" stroke="rgba(255,255,255,0.5)" />
              <YAxis stroke="rgba(255,255,255,0.5)" />
              <Tooltip 
                contentStyle={{
                  backgroundColor: 'rgba(15, 23, 42, 0.8)',
                  border: '1px solid rgba(255, 255, 255, 0.1)',
                  borderRadius: '8px'
                }}
              />
              <Legend />
              <Bar dataKey="trips" fill="#3b82f6" radius={[8, 8, 0, 0]} />
              <Bar dataKey="spent" fill="#10b981" radius={[8, 8, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </motion.div>
      </div>

      {recentTrips.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 rounded-xl p-6 backdrop-blur-sm"
        >
          <h3 className="text-white font-bold text-lg mb-4">Recent Trips</h3>
          <div className="space-y-3">
            {recentTrips.slice(0, 5).map((trip, i) => (
              <div key={i} className="flex items-center justify-between p-3 bg-white/5 rounded-lg hover:bg-white/10 transition">
                <div className="flex-1">
                  <p className="text-white font-semibold">{trip.from} → {trip.to}</p>
                  <p className="text-sm text-gray-400">{trip.date}</p>
                </div>
                <div className="text-right">
                  <p className="text-white font-semibold">${trip.amount}</p>
                  <p className="text-xs text-gray-400">{trip.distance} km</p>
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      )}
    </div>
  );
};

export default TripAnalytics;
