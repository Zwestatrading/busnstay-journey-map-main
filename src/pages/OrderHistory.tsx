import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ChevronRight, MapPin, Clock, DollarSign, RefreshCw, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Breadcrumb from '../components/Breadcrumb';
import { LoadingSkeleton } from '../components/LoadingSkeleton';
import { EmptyState } from '../components/EmptyState';
import { containerVariants, itemVariants, cardVariants } from '../utils/animations';

interface Order {
  id: string;
  orderNumber: string;
  date: string;
  total: number;
  status: 'completed' | 'pending' | 'cancelled';
  pickupLocation: string;
  dropoffLocation: string;
  service: 'bus' | 'restaurant' | 'hotel' | 'taxi';
  items?: string[];
}

export const OrderHistory = () => {
  const navigate = useNavigate();
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'all' | 'completed' | 'pending' | 'cancelled'>('all');
  const [searchTerm, setSearchTerm] = useState('');

  // Load orders from localStorage/API
  useEffect(() => {
    const loadOrders = async () => {
      setLoading(true);
      try {
        // Simulate API call with demo data
        await new Promise(resolve => setTimeout(resolve, 800));
        
        // Mock data - in real app, fetch from Supabase
        const mockOrders: Order[] = [
          {
            id: '1',
            orderNumber: 'ORD-001',
            date: '2024-02-24',
            total: 45.00,
            status: 'completed',
            pickupLocation: 'Lusaka Station',
            dropoffLocation: 'Livingstone',
            service: 'bus',
            items: ['2x Seats, Express Service']
          },
          {
            id: '2',
            orderNumber: 'ORD-002',
            date: '2024-02-20',
            total: 125.00,
            status: 'completed',
            pickupLocation: 'Ridgeway Mall',
            dropoffLocation: 'Home',
            service: 'restaurant',
            items: ['Pizza Margherita, 2x Sodas, Dessert']
          },
          {
            id: '3',
            orderNumber: 'ORD-003',
            date: '2024-02-18',
            total: 200.00,
            status: 'completed',
            pickupLocation: 'Hotel',
            dropoffLocation: 'Livingstone',
            service: 'hotel',
            items: ['2 Nights, Twin Room, Breakfast']
          },
          {
            id: '4',
            orderNumber: 'ORD-004',
            date: '2024-02-15',
            total: 25.50,
            status: 'pending',
            pickupLocation: 'City Center',
            dropoffLocation: 'Airport',
            service: 'taxi',
            items: ['Standard Ride']
          },
        ];

        setOrders(mockOrders);
      } catch (error) {
        console.error('Failed to load orders:', error);
      } finally {
        setLoading(false);
      }
    };

    loadOrders();
  }, []);

  const filteredOrders = orders
    .filter(order => {
      if (filter !== 'all' && order.status !== filter) return false;
      if (searchTerm && !order.orderNumber.toLowerCase().includes(searchTerm.toLowerCase())) return false;
      return true;
    })
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  const handleReorder = (order: Order) => {
    alert(`Reordering ${order.orderNumber} - Feature coming soon!`);
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'completed':
        return 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200';
      case 'pending':
        return 'bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200';
      case 'cancelled':
        return 'bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200';
      default:
        return 'bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200';
    }
  };

  const getServiceIcon = (service: string) => {
    const icons: Record<string, string> = {
      bus: '🚌',
      restaurant: '🍕',
      hotel: '🏨',
      taxi: '🚖',
    };
    return icons[service] || '📦';
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 transition-colors pb-20">
      <div className="max-w-4xl mx-auto px-4 py-4">
        {/* Breadcrumb */}
        <Breadcrumb />

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-6 mb-6"
        >
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">Order History</h1>
          <p className="text-slate-600 dark:text-slate-400">View and manage your past orders</p>
        </motion.div>

        {/* Search and Filter */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.1 }}
          className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6"
        >
          {/* Search */}
          <div className="md:col-span-2 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-slate-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search order number..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>

          {/* Filter Tabs */}
          <div className="md:col-span-2 flex gap-2 flex-wrap">
            {['all', 'completed', 'pending', 'cancelled'].map((status) => (
              <motion.button
                key={status}
                onClick={() => setFilter(status as any)}
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                className={`px-4 py-2 rounded-lg font-medium transition-colors text-sm capitalize ${
                  filter === status
                    ? 'bg-blue-600 text-white'
                    : 'bg-white dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-300 dark:border-slate-600'
                }`}
              >
                {status}
              </motion.button>
            ))}
          </div>
        </motion.div>

        {/* Orders List */}
        {loading ? (
          <div className="space-y-4">
            {[1, 2, 3].map(i => (
              <motion.div
                key={i}
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: i * 0.1 }}
              >
                <LoadingSkeleton type="card" />
              </motion.div>
            ))}
          </div>
        ) : filteredOrders.length > 0 ? (
          <motion.div
            variants={containerVariants}
            initial="initial"
            animate="animate"
            className="space-y-4"
          >
            <AnimatePresence mode="popLayout">
              {filteredOrders.map((order) => (
                <motion.div
                  key={order.id}
                  variants={itemVariants}
                  layout
                  className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 overflow-hidden hover:shadow-lg transition-shadow"
                >
                  <div className="p-4 md:p-6 flex flex-col md:flex-row gap-4">
                    {/* Order Info */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-start gap-3 mb-3">
                        <div className="text-2xl">{getServiceIcon(order.service)}</div>
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2 flex-wrap">
                            <h3 className="font-bold text-slate-900 dark:text-white">{order.orderNumber}</h3>
                            <span className={`px-2 py-1 rounded text-xs font-medium ${getStatusColor(order.status)}`}>
                              {order.status}
                            </span>
                          </div>
                          <p className="text-sm text-slate-500 dark:text-slate-400 mt-1">
                            {new Date(order.date).toLocaleDateString('en-US', {
                              year: 'numeric',
                              month: 'long',
                              day: 'numeric'
                            })}
                          </p>
                        </div>
                      </div>

                      {/* Locations */}
                      <div className="space-y-2 mb-3">
                        <div className="flex items-start gap-2">
                          <MapPin className="w-4 h-4 text-blue-600 dark:text-blue-400 mt-0.5 flex-shrink-0" />
                          <div className="text-sm text-slate-700 dark:text-slate-300">
                            <p className="font-medium">{order.pickupLocation}</p>
                          </div>
                        </div>
                        <div className="flex items-start gap-2">
                          <MapPin className="w-4 h-4 text-green-600 dark:text-green-400 mt-0.5 flex-shrink-0" />
                          <div className="text-sm text-slate-700 dark:text-slate-300">
                            <p className="font-medium">{order.dropoffLocation}</p>
                          </div>
                        </div>
                      </div>

                      {/* Items */}
                      {order.items && order.items.length > 0 && (
                        <p className="text-sm text-slate-600 dark:text-slate-400">
                          {order.items.join(', ')}
                        </p>
                      )}
                    </div>

                    {/* Price and Action */}
                    <div className="flex flex-col items-end justify-between md:border-l border-slate-200 dark:border-slate-700 md:pl-4 pt-4 md:pt-0">
                      <div className="text-right mb-4 md:mb-0">
                        <p className="text-sm text-slate-600 dark:text-slate-400">Total</p>
                        <p className="text-2xl font-bold text-slate-900 dark:text-white">
                          K{order.total.toFixed(2)}
                        </p>
                      </div>

                      <div className="flex gap-2 w-full md:w-auto">
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          onClick={() => handleReorder(order)}
                          className="flex-1 md:flex-none px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center gap-2"
                        >
                          <RefreshCw className="w-4 h-4" />
                          Reorder
                        </motion.button>
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          className="px-4 py-2 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-900 dark:text-white rounded-lg transition-colors"
                          aria-label="View details"
                        >
                          <ChevronRight className="w-4 h-4" />
                        </motion.button>
                      </div>
                    </div>
                  </div>
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        ) : (
          <EmptyState
            type="orders"
            actionLabel="Browse Services"
            onAction={() => navigate('/dashboard')}
          />
        )}

        {/* Stats Footer */}
        {!loading && orders.length > 0 && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="mt-8 grid grid-cols-3 gap-4"
          >
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-slate-900 dark:text-white">{orders.length}</p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Total Orders</p>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-green-600">
                {orders.filter(o => o.status === 'completed').length}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Completed</p>
            </div>
            <div className="bg-white dark:bg-slate-900 rounded-lg p-4 text-center border border-slate-200 dark:border-slate-700">
              <p className="text-2xl font-bold text-slate-900 dark:text-white">
                K{orders.reduce((sum, o) => sum + o.total, 0).toFixed(2)}
              </p>
              <p className="text-sm text-slate-600 dark:text-slate-400">Total Spent</p>
            </div>
          </motion.div>
        )}
      </div>
    </div>
  );
};

export default OrderHistory;
