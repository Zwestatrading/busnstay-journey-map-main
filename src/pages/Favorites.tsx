import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Heart, Trash2, MapPin, Star, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Breadcrumb from '../components/Breadcrumb';
import { LoadingSkeleton } from '../components/LoadingSkeleton';
import { EmptyState } from '../components/EmptyState';
import { containerVariants, itemVariants, cardVariants } from '../utils/animations';

interface FavoriteItem {
  id: string;
  name: string;
  category: 'restaurant' | 'hotel' | 'service';
  location: string;
  rating: number;
  reviews: number;
  image?: string;
  price?: string;
  savedDate: string;
}

export const Favorites = () => {
  const navigate = useNavigate();
  const [favorites, setFavorites] = useState<FavoriteItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'restaurant' | 'hotel' | 'service'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  // Load favorites from localStorage/Supabase
  useEffect(() => {
    const loadFavorites = async () => {
      setLoading(true);
      try {
        await new Promise(resolve => setTimeout(resolve, 700));
        
        // Mock data - in real app, fetch from Supabase
        const mockFavorites: FavoriteItem[] = [
          {
            id: '1',
            name: 'The Taste Kitchen',
            category: 'restaurant',
            location: 'Ridgeway Mall, Lusaka',
            rating: 4.8,
            reviews: 324,
            price: 'K50 - K200',
            savedDate: '2024-02-20'
          },
          {
            id: '2',
            name: 'Golden Valley Hotel',
            category: 'hotel',
            location: 'Livingstone',
            rating: 4.6,
            reviews: 156,
            price: 'K400/night',
            savedDate: '2024-02-15'
          },
          {
            id: '3',
            name: 'City Express Buses',
            category: 'service',
            location: 'Multiple Routes',
            rating: 4.5,
            reviews: 892,
            savedDate: '2024-02-10'
          },
          {
            id: '4',
            name: 'La Scala Restaurant',
            category: 'restaurant',
            location: 'Cairo Road, Lusaka',
            rating: 4.7,
            reviews: 245,
            price: 'K100 - K350',
            savedDate: '2024-01-28'
          },
          {
            id: '5',
            name: 'Paradise Resort',
            category: 'hotel',
            location: 'Victoria Falls',
            rating: 4.9,
            reviews: 412,
            price: 'K600/night',
            savedDate: '2024-01-15'
          },
        ];

        setFavorites(mockFavorites);
      } catch (error) {
        console.error('Failed to load favorites:', error);
      } finally {
        setLoading(false);
      }
    };

    loadFavorites();
  }, []);

  const filteredFavorites = favorites
    .filter(item => {
      if (filter !== 'all' && item.category !== filter) return false;
      if (searchTerm && !item.name.toLowerCase().includes(searchTerm.toLowerCase())) return false;
      return true;
    })
    .sort((a, b) => new Date(b.savedDate).getTime() - new Date(a.savedDate).getTime());

  const handleRemoveFavorite = (id: string) => {
    setFavorites(prev => prev.filter(item => item.id !== id));
  };

  const handleViewItem = (item: FavoriteItem) => {
    // Navigate to appropriate page based on category
    const routes: Record<string, string> = {
      restaurant: '/restaurant',
      hotel: '/hotel',
      service: '/rider',
    };
    navigate(routes[item.category] || '/dashboard');
  };

  const getCategoryColor = (category: string) => {
    switch (category) {
      case 'restaurant':
        return 'bg-orange-100 dark:bg-orange-900 text-orange-800 dark:text-orange-200';
      case 'hotel':
        return 'bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200';
      case 'service':
        return 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200';
      default:
        return 'bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200';
    }
  };

  const getCategoryIcon = (category: string) => {
    const icons: Record<string, string> = {
      restaurant: '🍽️',
      hotel: '🏨',
      service: '🚌',
    };
    return icons[category] || '⭐';
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 transition-colors pb-20">
      <div className="max-w-6xl mx-auto px-4 py-4">
        {/* Breadcrumb */}
        <Breadcrumb />

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-6 mb-6"
        >
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">Favorites</h1>
          <p className="text-slate-600 dark:text-slate-400">Your saved restaurants, hotels & services</p>
        </motion.div>

        {/* Search and Filter */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="flex flex-col md:flex-row gap-4 mb-6"
        >
          {/* Search */}
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search favorites..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Filter Tabs */}
          <div className="flex gap-2 flex-wrap">
            {['all', 'restaurant', 'hotel', 'service'].map((category) => (
              <motion.button
                key={category}
                onClick={() => setFilter(category as any)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className={`px-4 py-2 rounded-lg font-medium transition-colors text-sm capitalize ${
                  filter === category
                    ? 'bg-red-600 text-white'
                    : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-300 dark:border-slate-600'
                }`}
              >
                {category}
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Favorites Grid */}
        {loading ? (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {[1, 2, 3, 4, 5, 6].map(i => (
              <motion.div
                key={i}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: i * 0.05 }}
              >
                <LoadingSkeleton type="card" />
              </motion.div>
            ))}
          </div>
        ) : filteredFavorites.length > 0 ? (
          <motion.div
            variants={containerVariants}
            initial="initial"
            animate="animate"
            className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
          >
            <AnimatePresence mode="popLayout">
              {filteredFavorites.map((item) => (
                <motion.div
                  key={item.id}
                  variants={itemVariants}
                  layout
                  className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-lg transition-shadow"
                >
                  {/* Card Header with Image */}
                  <div className="relative h-40 bg-gradient-to-br from-slate-200 to-slate-300 dark:from-slate-700 dark:to-slate-800 flex items-center justify-center">
                    <div className="text-5xl">{getCategoryIcon(item.category)}</div>
                    <motion.button
                      whileHover={{ scale: 1.2 }}
                      whileTap={{ scale: 0.9 }}
                      onClick={() => handleRemoveFavorite(item.id)}
                      className="absolute top-2 right-2 p-2 bg-white dark:bg-slate-800 rounded-full shadow-md hover:bg-red-50 dark:hover:bg-red-900 transition-colors"
                      aria-label="Remove from favorites"
                    >
                      <Heart className="w-5 h-5 text-red-600 fill-red-600" />
                    </motion.button>
                  </div>

                  {/* Card Content */}
                  <div className="p-4">
                    {/* Category Badge */}
                    <span className={`inline-block px-2 py-1 rounded text-xs font-medium mb-2 capitalize ${getCategoryColor(item.category)}`}>
                      {item.category}
                    </span>

                    {/* Name */}
                    <h3 className="font-bold text-slate-900 dark:text-white mb-2 line-clamp-2">{item.name}</h3>

                    {/* Location */}
                    <div className="flex items-start gap-2 mb-3">
                      <MapPin className="w-4 h-4 text-slate-500 dark:text-slate-400 mt-0.5 flex-shrink-0" />
                      <p className="text-sm text-slate-600 dark:text-slate-400">{item.location}</p>
                    </div>

                    {/* Rating */}
                    <div className="flex items-center gap-2 mb-3 pb-3 border-b border-slate-200 dark:border-slate-700">
                      <div className="flex items-center gap-1">
                        <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                        <span className="font-semibold text-slate-900 dark:text-white">{item.rating}</span>
                        <span className="text-sm text-slate-600 dark:text-slate-400">({item.reviews})</span>
                      </div>
                    </div>

                    {/* Price */}
                    {item.price && (
                      <div className="mb-4">
                        <p className="text-sm text-slate-600 dark:text-slate-400">Price Range</p>
                        <p className="font-semibold text-slate-900 dark:text-white">{item.price}</p>
                      </div>
                    )}

                    {/* Saved Date */}
                    <p className="text-xs text-slate-500 dark:text-slate-500 mb-4">
                      Saved {new Date(item.savedDate).toLocaleDateString()}
                    </p>

                    {/* Action Button */}
                    <motion.button
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                      onClick={() => handleViewItem(item)}
                      className="w-full py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
                    >
                      View Details
                    </motion.button>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        ) : (
          <EmptyState
            type="favorites"
            actionLabel="Browse Services"
            onAction={() => navigate('/dashboard')}
          />
        )}

        {/* Stats Footer */}
        {!loading && favorites.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="mt-8 grid grid-cols-2 md:grid-cols-4 gap-4"
          >
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{favorites.length}</p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Total Saved</p>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-orange-600">
                {favorites.filter(f => f.category === 'restaurant').length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Restaurants</p>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-purple-600">
                {favorites.filter(f => f.category === 'hotel').length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Hotels</p>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-blue-600">
                {favorites.filter(f => f.category === 'service').length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Services</p>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
};

export default Favorites;
