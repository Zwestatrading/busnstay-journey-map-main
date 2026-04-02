/**
 * Enhanced User Profile System
 * Complete profile management with preferences and settings
 */

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Mail, Phone, MapPin, User, Shield, Settings, LogOut, Save, X } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface UserProfile {
  id: string;
  name: string;
  email: string;
  phone?: string;
  location?: string;
  avatar?: string;
  bio?: string;
  joinDate: Date;
  role: 'user' | 'provider' | 'admin';
}

export interface UserPreferences {
  notifications: {
    email: boolean;
    sms: boolean;
    push: boolean;
  };
  privacy: {
    showProfile: boolean;
    allowMessages: boolean;
    shareLocation: boolean;
  };
  theme: 'dark' | 'light' | 'auto';
  language: string;
}

interface ProfileHeaderProps {
  profile: UserProfile;
  onEditClick?: () => void;
}

export const ProfileHeader = ({ profile, onEditClick }: ProfileHeaderProps) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="card-polished"
  >
    <div className="flex flex-col sm:flex-row items-start sm:items-center gap-6">
      {/* Avatar */}
      <motion.div
        whileHover={{ scale: 1.05 }}
        className="relative w-24 h-24 rounded-2xl bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center text-white text-4xl font-bold overflow-hidden"
      >
        {profile.avatar ? (
          <img src={profile.avatar} alt={profile.name} className="w-full h-full object-cover" />
        ) : (
          profile.name.charAt(0).toUpperCase()
        )}
      </motion.div>

      {/* Info */}
      <div className="flex-1 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="heading-premium text-2xl">{profile.name}</h1>
            <p className="text-sm text-gray-400 capitalize">
              {profile.role} • Joined {new Date(profile.joinDate).toLocaleDateString()}
            </p>
          </div>
          {onEditClick && (
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={onEditClick}
              className="px-4 py-2 rounded-lg bg-blue-600/20 text-blue-400 hover:bg-blue-600/30 transition-all"
            >
              Edit Profile
            </motion.button>
          )}
        </div>

        {/* Contact Info */}
        <div className="flex flex-col gap-2 text-sm text-gray-400">
          {profile.email && (
            <div className="flex items-center gap-2">
              <Mail className="w-4 h-4" />
              {profile.email}
            </div>
          )}
          {profile.phone && (
            <div className="flex items-center gap-2">
              <Phone className="w-4 h-4" />
              {profile.phone}
            </div>
          )}
          {profile.location && (
            <div className="flex items-center gap-2">
              <MapPin className="w-4 h-4" />
              {profile.location}
            </div>
          )}
        </div>

        {profile.bio && (
          <p className="body-premium text-gray-300 pt-2">{profile.bio}</p>
        )}
      </div>
    </div>
  </motion.div>
);

interface SettingToggleProps {
  label: string;
  description?: string;
  checked: boolean;
  onChange: (checked: boolean) => void;
}

export const SettingToggle = ({
  label,
  description,
  checked,
  onChange,
}: SettingToggleProps) => (
  <motion.div
    initial={{ opacity: 0, x: -10 }}
    animate={{ opacity: 1, x: 0 }}
    className="flex items-start justify-between p-4 rounded-lg border border-white/10 hover:border-white/20 transition-all"
  >
    <div>
      <p className="font-medium text-white">{label}</p>
      {description && <p className="text-sm text-gray-400 mt-1">{description}</p>}
    </div>
    <button
      onClick={() => onChange(!checked)}
      className={cn(
        'relative w-12 h-7 rounded-full transition-all duration-300',
        checked ? 'bg-blue-600' : 'bg-slate-700'
      )}
    >
      <motion.div
        animate={{ x: checked ? 20 : 4 }}
        className="absolute top-1 w-5 h-5 bg-white rounded-full"
      />
    </button>
  </motion.div>
);

interface PreferencesPanelProps {
  preferences: UserPreferences;
  onSave: (preferences: UserPreferences) => void;
}

export const PreferencesPanel = ({ preferences, onSave }: PreferencesPanelProps) => {
  const [prefs, setPrefs] = useState(preferences);
  const [hasChanges, setHasChanges] = useState(false);

  const handleChange = (updates: Partial<UserPreferences>) => {
    const newPrefs = { ...prefs, ...updates };
    setPrefs(newPrefs);
    setHasChanges(true);
  };

  const handleSave = () => {
    onSave(prefs);
    setHasChanges(false);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="space-y-6"
    >
      {/* Notifications */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.1 }}
        className="card-polished"
      >
        <h3 className="subheading-premium mb-4">Notifications</h3>
        <div className="space-y-3">
          <SettingToggle
            label="Email Notifications"
            description="Receive updates via email"
            checked={prefs.notifications.email}
            onChange={(checked) =>
              handleChange({
                notifications: { ...prefs.notifications, email: checked },
              })
            }
          />
          <SettingToggle
            label="SMS Notifications"
            description="Receive updates via text message"
            checked={prefs.notifications.sms}
            onChange={(checked) =>
              handleChange({
                notifications: { ...prefs.notifications, sms: checked },
              })
            }
          />
          <SettingToggle
            label="Push Notifications"
            description="Receive app notifications"
            checked={prefs.notifications.push}
            onChange={(checked) =>
              handleChange({
                notifications: { ...prefs.notifications, push: checked },
              })
            }
          />
        </div>
      </motion.div>

      {/* Privacy */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="card-polished"
      >
        <h3 className="subheading-premium mb-4">Privacy</h3>
        <div className="space-y-3">
          <SettingToggle
            label="Show Public Profile"
            description="Let others see your profile"
            checked={prefs.privacy.showProfile}
            onChange={(checked) =>
              handleChange({
                privacy: { ...prefs.privacy, showProfile: checked },
              })
            }
          />
          <SettingToggle
            label="Allow Messages"
            description="Let others send you messages"
            checked={prefs.privacy.allowMessages}
            onChange={(checked) =>
              handleChange({
                privacy: { ...prefs.privacy, allowMessages: checked },
              })
            }
          />
          <SettingToggle
            label="Share Location"
            description="Share your location with service providers"
            checked={prefs.privacy.shareLocation}
            onChange={(checked) =>
              handleChange({
                privacy: { ...prefs.privacy, shareLocation: checked },
              })
            }
          />
        </div>
      </motion.div>

      {/* Appearance */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.3 }}
        className="card-polished"
      >
        <h3 className="subheading-premium mb-4">Appearance</h3>
        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-white mb-2">Theme</label>
            <select
              value={prefs.theme}
              onChange={(e) => handleChange({ theme: e.target.value as 'dark' | 'light' | 'auto' })}
              className="w-full px-3 py-2 rounded-lg bg-slate-900/50 border border-white/10 text-white focus:border-blue-500/50 focus:ring-2 focus:ring-blue-500/40 transition-all"
            >
              <option value="dark">Dark</option>
              <option value="light">Light</option>
              <option value="auto">Auto</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-white mb-2">Language</label>
            <select
              value={prefs.language}
              onChange={(e) => handleChange({ language: e.target.value })}
              className="w-full px-3 py-2 rounded-lg bg-slate-900/50 border border-white/10 text-white focus:border-blue-500/50 focus:ring-2 focus:ring-blue-500/40 transition-all"
            >
              <option value="en">English</option>
              <option value="es">Spanish</option>
              <option value="fr">French</option>
            </select>
          </div>
        </div>
      </motion.div>

      {/* Save Button */}
      {hasChanges && (
        <motion.button
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          onClick={handleSave}
          className="w-full px-6 py-3 rounded-lg bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-semibold hover:from-emerald-700 hover:to-teal-700 transition-all flex items-center justify-center gap-2"
        >
          <Save className="w-4 h-4" />
          Save Changes
        </motion.button>
      )}
    </motion.div>
  );
};

/**
 * Security Panel Component
 */
interface SecurityPanelProps {
  onChangePassword?: () => void;
  onEnable2FA?: () => void;
  on2FAEnabled?: boolean;
  onLogoutAll?: () => void;
}

export const SecurityPanel = ({
  onChangePassword,
  onEnable2FA,
  on2FAEnabled = false,
  onLogoutAll,
}: SecurityPanelProps) => (
  <motion.div
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    className="card-polished space-y-4"
  >
    <h3 className="subheading-premium flex items-center gap-2">
      <Shield className="w-5 h-5" />
      Security
    </h3>

    <div className="space-y-3">
      <button
        onClick={onChangePassword}
        className="w-full px-4 py-3 rounded-lg bg-slate-800/50 text-white hover:bg-slate-800 transition-all text-left"
      >
        <p className="font-medium">Change Password</p>
        <p className="text-xs text-gray-400 mt-1">Update your password to keep your account secure</p>
      </button>

      <button
        onClick={onEnable2FA}
        className="w-full px-4 py-3 rounded-lg bg-slate-800/50 text-white hover:bg-slate-800 transition-all text-left flex items-center justify-between"
      >
        <div className="text-left">
          <p className="font-medium">Two-Factor Authentication</p>
          <p className="text-xs text-gray-400 mt-1">Add an extra layer of security</p>
        </div>
        {on2FAEnabled && <span className="text-emerald-400 text-sm font-semibold">Enabled</span>}
      </button>

      <button
        onClick={onLogoutAll}
        className="w-full px-4 py-3 rounded-lg bg-rose-600/20 text-rose-400 hover:bg-rose-600/30 transition-all text-left"
      >
        <p className="font-medium">Logout All Sessions</p>
        <p className="text-xs text-rose-300/70 mt-1">End all active sessions on other devices</p>
      </button>
    </div>
  </motion.div>
);
