import { useState, useEffect } from 'react';
import { User, Mail, Phone, MapPin, Shield, Settings, Edit2, LogOut, Camera, Check } from 'lucide-react';
import { motion } from 'framer-motion';
import Breadcrumb from '../components/Breadcrumb';
import { LoadingSkeleton } from '../components/LoadingSkeleton';
import { useToast } from '../contexts/ToastContext';
import { containerVariants, itemVariants } from '../utils/animations';

interface UserProfile {
  id: string;
  name: string;
  email: string;
  phone: string;
  location: string;
  profileImage?: string;
  joinDate: string;
  role: 'passenger' | 'rider' | 'restaurant' | 'hotel';
  isVerified: boolean;
  preferences: {
    emailNotifications: boolean;
    smsNotifications: boolean;
    darkMode: boolean;
    language: string;
  };
  allergies?: string[];
  preferences2?: {
    favoritePaymentMethod?: string;
    defaultPickupLocation?: string;
    tipsPreference?: boolean;
  };
}

export const ProfileEnhanced = () => {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState<Partial<UserProfile>>({});
  const { addToast } = useToast();

  useEffect(() => {
    const loadProfile = async () => {
      setLoading(true);
      try {
        await new Promise(resolve => setTimeout(resolve, 800));
        
        // Mock profile data
        const mockProfile: UserProfile = {
          id: '1',
          name: 'John Ndlela',
          email: 'john.ndlela@example.com',
          phone: '+260977123456',
          location: 'Lusaka, Zambia',
          profileImage: '👤',
          joinDate: '2023-06-15',
          role: 'passenger',
          isVerified: true,
          preferences: {
            emailNotifications: true,
            smsNotifications: true,
            darkMode: false,
            language: 'en',
          },
          allergies: ['Peanuts', 'Shellfish'],
          preferences2: {
            favoritePaymentMethod: 'Mobile Money',
            defaultPickupLocation: 'Home',
            tipsPreference: true,
          },
        };

        setProfile(mockProfile);
        setEditData(mockProfile);
      } catch (error) {
        console.error('Failed to load profile:', error);
        addToast('Failed to load profile', 'error');
      } finally {
        setLoading(false);
      }
    };

    loadProfile();
  }, [addToast]);

  const handleSaveProfile = async () => {
    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 500));
      setProfile(editData as UserProfile);
      setIsEditing(false);
      addToast('Profile updated successfully', 'success');
    } catch (error) {
      addToast('Failed to update profile', 'error');
    }
  };

  const handleLogout = () => {
    addToast('Logout functionality coming soon', 'info');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-950 pb-20">
        <div className="max-w-3xl mx-auto px-4 py-4">
          <Breadcrumb />
          <LoadingSkeleton type="card" />
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex items-center justify-center">
        <div className="text-center">
          <p className="text-slate-600 dark:text-slate-400">Could not load profile</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 transition-colors pb-20">
      <div className="max-w-3xl mx-auto px-4 py-4">
        {/* Breadcrumb */}
        <Breadcrumb />

        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-6 mb-6"
        >
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white mb-2">My Profile</h1>
          <p className="text-slate-600 dark:text-slate-400">Manage your account information</p>
        </motion.div>

        <motion.div
          variants={containerVariants}
          initial="initial"
          animate="animate"
          className="space-y-6"
        >
          {/* Profile Card */}
          <motion.div
            variants={itemVariants}
            className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
          >
            <div className="flex flex-col md:flex-row gap-6 mb-6">
              {/* Profile Picture */}
              <div className="flex flex-col items-center">
                <div className="relative mb-4">
                  <div className="w-24 h-24 bg-gradient-to-br from-blue-400 to-blue-600 rounded-full flex items-center justify-center text-5xl shadow-lg">
                    {profile.profileImage}
                  </div>
                  {!isEditing && (
                    <motion.button
                      whileHover={{ scale: 1.1 }}
                      whileTap={{ scale: 0.9 }}
                      className="absolute bottom-0 right-0 p-2 bg-blue-600 rounded-full text-white shadow-lg hover:bg-blue-700"
                    >
                      <Camera className="w-4 h-4" />
                    </motion.button>
                  )}
                </div>
                <div className="text-center">
                  <h2 className="text-xl font-bold text-slate-900 dark:text-white">{profile.name}</h2>
                  <div className="flex items-center gap-1 justify-center mt-1">
                    <span className={`px-2 py-1 rounded text-xs font-medium capitalize ${
                      profile.isVerified
                        ? 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-200'
                        : 'bg-yellow-100 dark:bg-yellow-900 text-yellow-800 dark:text-yellow-200'
                    }`}>
                      {profile.isVerified ? 'Verified' : 'Unverified'}
                    </span>
                    <Shield className="w-4 h-4 text-green-600 dark:text-green-400" />
                  </div>
                </div>
              </div>

              {/* Profile Info */}
              <div className="flex-1">
                {isEditing ? (
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Name</label>
                      <input
                        type="text"
                        value={editData.name || ''}
                        onChange={(e) => setEditData({ ...editData, name: e.target.value })}
                        className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Phone</label>
                      <input
                        type="tel"
                        value={editData.phone || ''}
                        onChange={(e) => setEditData({ ...editData, phone: e.target.value })}
                        className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Location</label>
                      <input
                        type="text"
                        value={editData.location || ''}
                        onChange={(e) => setEditData({ ...editData, location: e.target.value })}
                        className="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>
                ) : (
                  <div className="space-y-3">
                    <div className="flex items-start gap-3">
                      <Mail className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" />
                      <div>
                        <p className="text-sm text-slate-600 dark:text-slate-400">Email</p>
                        <p className="font-medium text-slate-900 dark:text-white">{profile.email}</p>
                      </div>
                    </div>
                    <div className="flex items-start gap-3">
                      <Phone className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" />
                      <div>
                        <p className="text-sm text-slate-600 dark:text-slate-400">Phone</p>
                        <p className="font-medium text-slate-900 dark:text-white">{profile.phone}</p>
                      </div>
                    </div>
                    <div className="flex items-start gap-3">
                      <MapPin className="w-5 h-5 text-blue-600 dark:text-blue-400 mt-0.5" />
                      <div>
                        <p className="text-sm text-slate-600 dark:text-slate-400">Location</p>
                        <p className="font-medium text-slate-900 dark:text-white">{profile.location}</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex gap-3 pt-6 border-t border-slate-200 dark:border-slate-700">
              <motion.button
                whileHover={{ scale: 1.05 }}
                whileTap={{ scale: 0.95 }}
                onClick={() => isEditing ? handleSaveProfile() : setIsEditing(true)}
                className="flex-1 flex items-center justify-center gap-2 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
              >
                {isEditing ? (
                  <>
                    <Check className="w-4 h-4" />
                    Save Changes
                  </>
                ) : (
                  <>
                    <Edit2 className="w-4 h-4" />
                    Edit Profile
                  </>
                )}
              </motion.button>
              {isEditing && (
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={() => {
                    setIsEditing(false);
                    setEditData(profile);
                  }}
                  className="flex-1 py-2 bg-slate-200 dark:bg-slate-700 hover:bg-slate-300 dark:hover:bg-slate-600 text-slate-900 dark:text-white rounded-lg font-medium transition-colors"
                >
                  Cancel
                </motion.button>
              )}
            </div>
          </motion.div>

          {/* Account Info */}
          <motion.div
            variants={itemVariants}
            className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
          >
            <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <User className="w-5 h-5" />
              Account Information
            </h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-slate-600 dark:text-slate-400">Member Since</p>
                <p className="font-medium text-slate-900 dark:text-white">
                  {new Date(profile.joinDate).toLocaleDateString()}
                </p>
              </div>
              <div>
                <p className="text-sm text-slate-600 dark:text-slate-400">Account Type</p>
                <p className="font-medium text-slate-900 dark:text-white capitalize">{profile.role}</p>
              </div>
            </div>
          </motion.div>

          {/* Preferences */}
          <motion.div
            variants={itemVariants}
            className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
          >
            <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
              <Settings className="w-5 h-5" />
              Preferences
            </h3>
            <div className="space-y-3">
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={profile.preferences.emailNotifications}
                  onChange={(e) => setProfile({
                    ...profile,
                    preferences: { ...profile.preferences, emailNotifications: e.target.checked }
                  })}
                  className="w-4 h-4 rounded border-slate-300 text-blue-600"
                />
                <span className="text-slate-700 dark:text-slate-300">Email Notifications</span>
              </label>
              <label className="flex items-center gap-3 cursor-pointer">
                <input
                  type="checkbox"
                  checked={profile.preferences.smsNotifications}
                  onChange={(e) => setProfile({
                    ...profile,
                    preferences: { ...profile.preferences, smsNotifications: e.target.checked }
                  })}
                  className="w-4 h-4 rounded border-slate-300 text-blue-600"
                />
                <span className="text-slate-700 dark:text-slate-300">SMS Notifications</span>
              </label>
            </div>
          </motion.div>

          {/* Allergies */}
          {profile.allergies && profile.allergies.length > 0 && (
            <motion.div
              variants={itemVariants}
              className="bg-white dark:bg-slate-900 rounded-lg border border-slate-200 dark:border-slate-700 p-6"
            >
              <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-4">Allergies & Preferences</h3>
              <div className="flex flex-wrap gap-2">
                {profile.allergies.map((allergy, idx) => (
                  <span
                    key={idx}
                    className="px-3 py-1 bg-red-100 dark:bg-red-900 text-red-800 dark:text-red-200 rounded-full text-sm font-medium"
                  >
                    {allergy}
                  </span>
                ))}
              </div>
            </motion.div>
          )}

          {/* Logout */}
          <motion.button
            variants={itemVariants}
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
            onClick={handleLogout}
            className="w-full py-3 bg-red-600 hover:bg-red-700 text-white rounded-lg font-medium transition-colors flex items-center justify-center gap-2"
          >
            <LogOut className="w-5 h-5" />
            Logout
          </motion.button>
        </motion.div>
      </div>
    </div>
  );
};

export default ProfileEnhanced;
