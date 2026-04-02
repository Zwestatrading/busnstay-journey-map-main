import { useState, useEffect } from 'react';
import { MapPin, Plus, Trash2, Edit2, Check, X } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import Breadcrumb from '../components/Breadcrumb';
import { LoadingSkeleton } from '../components/LoadingSkeleton';
import { EmptyState } from '../components/EmptyState';
import { containerVariants, itemVariants } from '../utils/animations';

interface Address {
  id: string;
  label: string;
  address: string;
  type: 'home' | 'work' | 'other';
  isDefault: boolean;
  coordinates?: { lat: number; lng: number };
}

export const SavedAddresses = () => {
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showAddForm, setShowAddForm] = useState(false);
  const [formData, setFormData] = useState({
    label: '',
    address: '',
    type: 'other' as 'home' | 'work' | 'other',
  });

  // Load addresses from localStorage/Supabase
  useEffect(() => {
    const loadAddresses = async () => {
      setLoading(true);
      try {
        await new Promise(resolve => setTimeout(resolve, 600));
        
        // Mock data
        const mockAddresses: Address[] = [
          {
            id: '1',
            label: 'Home',
            address: '123 Main Street, Lusaka, Zambia',
            type: 'home',
            isDefault: true,
            coordinates: { lat: -15.3875, lng: 28.3228 }
          },
          {
            id: '2',
            label: 'Work',
            address: 'Ridgeway Mall, Cairo Rd, Lusaka',
            type: 'work',
            isDefault: false,
            coordinates: { lat: -15.4167, lng: 28.2833 }
          },
          {
            id: '3',
            label: 'Gym',
            address: '456 Fitness Avenue, Lusaka',
            type: 'other',
            isDefault: false,
            coordinates: { lat: -15.3900, lng: 28.3300 }
          },
        ];

        setAddresses(mockAddresses);
      } catch (error) {
        console.error('Failed to load addresses:', error);
      } finally {
        setLoading(false);
      }
    };

    loadAddresses();
  }, []);

  const handleAddAddress = () => {
    if (formData.label && formData.address) {
      const newAddress: Address = {
        id: Date.now().toString(),
        ...formData,
        isDefault: addresses.length === 0,
      };

      setAddresses([...addresses, newAddress]);
      setFormData({ label: '', address: '', type: 'other' });
      setShowAddForm(false);
    }
  };

  const handleDeleteAddress = (id: string) => {
    setAddresses(addresses.filter(addr => addr.id !== id));
  };

  const handleSetDefault = (id: string) => {
    setAddresses(addresses.map(addr => ({
      ...addr,
      isDefault: addr.id === id,
    })));
  };

  const handleEditAddress = (address: Address) => {
    setEditingId(address.id);
    setFormData({
      label: address.label,
      address: address.address,
      type: address.type,
    });
  };

  const handleSaveEdit = (id: string) => {
    setAddresses(addresses.map(addr => 
      addr.id === id ? { ...addr, ...formData } : addr
    ));
    setEditingId(null);
    setFormData({ label: '', address: '', type: 'other' });
  };

  const getAddressIcon = (type: string) => {
    switch (type) {
      case 'home':
        return '🏠';
      case 'work':
        return '💼';
      case 'other':
        return '📍';
      default:
        return '📍';
    }
  };

  const getTypeBadgeColor = (type: string) => {
    switch (type) {
      case 'home':
        return 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200';
      case 'work':
        return 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200';
      case 'other':
        return 'bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200';
      default:
        return 'bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-slate-200';
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 transition-colors pb-20">
      <div className="max-w-3xl mx-auto px-4 py-4">
        {/* Breadcrumb */}
        <Breadcrumb />

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-6 mb-6 flex items-start justify-between"
        >
          <div>
            <h1 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">Saved Addresses</h1>
            <p className="text-slate-600 dark:text-slate-400">Manage your delivery & pickup locations</p>
          </div>
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => {
              setShowAddForm(!showAddForm);
              setEditingId(null);
              setFormData({ label: '', address: '', type: 'other' });
            }}
            className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors mt-2 md:mt-0"
          >
            <Plus className="w-5 h-5" />
            Add Address
          </motion.button>
        </motion.div>

        {/* Add Address Form */}
        <AnimatePresence>
          {showAddForm && (
            <motion.div
              initial={{ opacity: 0, y: -20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
              className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6 mb-6"
            >
              <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4">New Address</h3>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Label
                  </label>
                  <input
                    type="text"
                    placeholder="e.g., Home, Work, Gym"
                    value={formData.label}
                    onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Full Address
                  </label>
                  <textarea
                    placeholder="Enter street address, city, and country"
                    value={formData.address}
                    onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                    rows={3}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                    Address Type
                  </label>
                  <select
                    value={formData.type}
                    onChange={(e) => setFormData({ ...formData, type: e.target.value as any })}
                    className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="home">Home</option>
                    <option value="work">Work</option>
                    <option value="other">Other</option>
                  </select>
                </div>

                <div className="flex gap-2 justify-end pt-2">
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={() => {
                      setShowAddForm(false);
                      setFormData({ label: '', address: '', type: 'other' });
                    }}
                    className="px-4 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg font-medium hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                  >
                    Cancel
                  </motion.button>
                  <motion.button
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    onClick={handleAddAddress}
                    className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
                  >
                    Save Address
                  </motion.button>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* Addresses List */}
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
        ) : addresses.length > 0 ? (
          <motion.div
            variants={containerVariants}
            initial="initial"
            animate="animate"
            className="space-y-4"
          >
            <AnimatePresence mode="popLayout">
              {addresses.map((address) => (
                <motion.div
                  key={address.id}
                  variants={itemVariants}
                  layout
                  className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-4 md:p-6"
                >
                  {editingId === address.id ? (
                    // Edit Mode
                    <div className="space-y-4">
                      <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                          Label
                        </label>
                        <input
                          type="text"
                          value={formData.label}
                          onChange={(e) => setFormData({ ...formData, label: e.target.value })}
                          className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                        />
                      </div>

                      <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                          Address
                        </label>
                        <textarea
                          value={formData.address}
                          onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                          rows={2}
                          className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500 resize-none"
                        />
                      </div>

                      <div className="flex gap-2 justify-end">
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          onClick={() => {
                            setEditingId(null);
                            setFormData({ label: '', address: '', type: 'other' });
                          }}
                          className="px-3 py-2 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
                        >
                          <X className="w-5 h-5" />
                        </motion.button>
                        <motion.button
                          whileHover={{ scale: 1.05 }}
                          whileTap={{ scale: 0.95 }}
                          onClick={() => handleSaveEdit(address.id)}
                          className="px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg"
                        >
                          <Check className="w-5 h-5" />
                        </motion.button>
                      </div>
                    </div>
                  ) : (
                    // View Mode
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3 mb-2">
                          <span className="text-2xl">{getAddressIcon(address.type)}</span>
                          <div>
                            <div className="flex items-center gap-2">
                              <h3 className="font-bold text-slate-900 dark:text-white">{address.label}</h3>
                              <span className={`px-2 py-0.5 rounded text-xs font-medium capitalize ${getTypeBadgeColor(address.type)}`}>
                                {address.type}
                              </span>
                              {address.isDefault && (
                                <span className="px-2 py-0.5 rounded text-xs font-medium bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                                  Default
                                </span>
                              )}
                            </div>
                            <p className="text-slate-600 dark:text-slate-400 mt-1">{address.address}</p>
                          </div>
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="flex gap-2 ml-4">
                        {!address.isDefault && (
                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            onClick={() => handleSetDefault(address.id)}
                            className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
                            title="Set as default"
                          >
                            <MapPin className="w-5 h-5 text-slate-600 dark:text-slate-400" />
                          </motion.button>
                        )}
                        <motion.button
                          whileHover={{ scale: 1.1 }}
                          whileTap={{ scale: 0.9 }}
                          onClick={() => handleEditAddress(address)}
                          className="p-2 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition-colors"
                          title="Edit address"
                        >
                          <Edit2 className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                        </motion.button>
                        {addresses.length > 1 && (
                          <motion.button
                            whileHover={{ scale: 1.1 }}
                            whileTap={{ scale: 0.9 }}
                            onClick={() => handleDeleteAddress(address.id)}
                            className="p-2 hover:bg-red-50 dark:hover:bg-red-900 rounded-lg transition-colors"
                            title="Delete address"
                          >
                            <Trash2 className="w-5 h-5 text-red-600 dark:text-red-400" />
                          </motion.button>
                        )}
                      </div>
                    </div>
                  )}
                </motion.div>
              ))}
            </AnimatePresence>
          </motion.div>
        ) : (
          <EmptyState
            type="addresses"
            actionLabel="Add First Address"
            onAction={() => setShowAddForm(true)}
          />
        )}
      </div>
    </div>
  );
};

export default SavedAddresses;
