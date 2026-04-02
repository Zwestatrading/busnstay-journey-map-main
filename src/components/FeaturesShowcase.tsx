import { motion } from 'framer-motion';
import { GradientBg } from '@/components/ui/GradientBg';
import { Clock, Star, MapPin, Shield, AlertTriangle, MessageSquare, TrendingUp, Zap } from 'lucide-react';

const FeaturesShowcase = () => {
  const features = [
    {
      icon: AlertTriangle,
      title: 'Emergency SOS',
      description: '24/7 emergency support with one-tap access to help',
      color: 'from-red-600 to-red-700',
      badge: '🚨'
    },
    {
      icon: MessageSquare,
      title: 'Live Support Chat',
      description: 'Real-time assistance from our support team',
      color: 'from-green-600 to-emerald-700',
      badge: '💬'
    },
    {
      icon: Star,
      title: 'Ratings & Reviews',
      description: 'Community-driven reviews for buses, hotels, and restaurants',
      color: 'from-yellow-600 to-orange-700',
      badge: '⭐'
    },
    {
      icon: TrendingUp,
      title: 'Trip Analytics',
      description: 'Track spending, distances, and travel patterns',
      color: 'from-purple-600 to-indigo-700',
      badge: '📊'
    },
    {
      icon: MapPin,
      title: 'Advanced Booking',
      description: 'Seat selection, multiple payment options, instant confirmation',
      color: 'from-blue-600 to-cyan-700',
      badge: '🎫'
    },
    {
      icon: Shield,
      title: 'Secure Payments',
      description: 'Encrypted transactions with multiple payment methods',
      color: 'from-slate-700 to-slate-800',
      badge: '🔒'
    }
  ];

  return (
    <div className="relative min-h-screen bg-gradient-to-br from-slate-900 via-slate-950 to-black py-20 px-4">
      {/* Ambient Background */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <motion.div
          animate={{ 
            x: [0, 100, 0],
            y: [0, 50, 0]
          }}
          transition={{ duration: 20, repeat: Infinity }}
          className="absolute top-0 left-1/4 w-96 h-96 bg-gradient-to-r from-blue-600/10 to-purple-600/10 rounded-full blur-3xl"
        />
        <motion.div
          animate={{ 
            x: [0, -100, 0],
            y: [0, -50, 0]
          }}
          transition={{ duration: 25, repeat: Infinity }}
          className="absolute bottom-0 right-1/4 w-96 h-96 bg-gradient-to-r from-green-600/10 to-emerald-600/10 rounded-full blur-3xl"
        />
      </div>

      <div className="relative z-10 max-w-7xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -30 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-16"
        >
          <h1 className="text-5xl md:text-7xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-white via-blue-200 to-indigo-400 mb-4">
            Beyond City Limits
          </h1>
          <p className="text-xl text-gray-300 max-w-2xl mx-auto">
            Experience the future of long-distance travel with BusNStay — real-time tracking, smart booking, and comprehensive journey management
          </p>
        </motion.div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-16">
          {features.map((feature, i) => {
            const Icon = feature.icon;
            return (
              <motion.div
                key={i}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.1 }}
                whileHover={{ y: -5, scale: 1.02 }}
                className="group relative"
              >
                {/* Gradient Border */}
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.color} rounded-xl opacity-0 group-hover:opacity-20 transition-opacity duration-300 blur`} />
                
                {/* Card */}
                <div className="relative bg-gradient-to-br from-slate-800/50 to-slate-900/50 border border-white/10 group-hover:border-white/20 rounded-xl p-6 transition-all duration-300 backdrop-blur-sm">
                  {/* Icon */}
                  <div className={`inline-flex items-center justify-center w-12 h-12 rounded-lg bg-gradient-to-br ${feature.color} text-white mb-4 group-hover:scale-110 transition-transform`}>
                    <Icon className="w-6 h-6" />
                  </div>

                  {/* Title */}
                  <h3 className="text-white font-bold text-lg mb-2">{feature.title}</h3>
                  
                  {/* Description */}
                  <p className="text-gray-400 text-sm mb-4 group-hover:text-gray-300 transition-colors">
                    {feature.description}
                  </p>

                  {/* Badge */}
                  <div className="flex items-center justify-between">
                    <span className="text-2xl">{feature.badge}</span>
                    <motion.arrow 
                      className="text-transparent group-hover:text-blue-400"
                      animate={{ x: [0, 4, 0] }}
                      transition={{ duration: 2, repeat: Infinity }}
                    >
                      →
                    </motion.arrow>
                  </div>
                </div>
              </motion.div>
            );
          })}
        </div>

        {/* Stats Section */}
        <motion.div
          initial={{ opacity: 0, y: 30 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.6 }}
          className="bg-gradient-to-br from-slate-800/30 to-slate-900/30 border border-white/10 rounded-2xl p-8 mb-16 backdrop-blur-md"
        >
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            {[
              { number: '50K+', label: 'Active Users' },
              { number: '100+', label: 'Routes Covered' },
              { number: '24/7', label: 'Support Available' },
              { number: '99.9%', label: 'System Uptime' }
            ].map((stat, i) => (
              <motion.div
                key={i}
                initial={{ opacity: 0, scale: 0.8 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.7 + i * 0.1 }}
                className="text-center"
              >
                <div className="text-3xl md:text-4xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-400 mb-2">
                  {stat.number}
                </div>
                <p className="text-gray-400">{stat.label}</p>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* CTA */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.8 }}
          className="text-center"
        >
          <button className="relative group inline-block">
            <div className="absolute -inset-1 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg blur opacity-75 group-hover:opacity-100 transition duration-1000 group-hover:duration-200" />
            <div className="relative px-8 py-4 bg-black rounded-lg leading-none flex items-center divide-x divide-gray-600">
              <span className="pr-6 text-white font-bold text-lg">
                ✨ Start Your Journey Now
              </span>
              <span className="pl-6 text-indigo-400 group-hover:text-purple-400 transition-colors">
                Get Started →
              </span>
            </div>
          </button>
        </motion.div>
      </div>
    </div>
  );
};

export default FeaturesShowcase;
