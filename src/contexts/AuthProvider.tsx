import React, { ReactNode, useState, useEffect } from 'react';
import { useAuth, UserProfile, UserRole } from '@/hooks/useAuth';
import { User, Session } from '@supabase/supabase-js';
import { AuthContext, AuthContextType } from './AuthContext.ts';
import { demoAuthService } from '@/utils/demoAuthService';

// Helper function to create demo auth context
function createDemoAuthContext(): AuthContextType {
  const demoUser = demoAuthService.getDemoUser();
  const demoProfile = demoAuthService.getDemoProfile();
  
  // Create profile data with fallback defaults
  const demoProfileData: UserProfile | null = demoUser ? {
    id: demoUser.id,
    user_id: demoUser.id,
    email: demoUser.email,
    full_name: demoProfile?.full_name || 'Demo User',
    phone: demoProfile?.phone || '+260970000123',
    avatar_url: null,
    role: (demoProfile?.role || 'passenger') as UserRole,
    is_approved: demoProfile?.is_approved ?? true,
    assigned_station_id: demoProfile?.assigned_station_id || null,
    business_name: null,
    rating: 4.8,
    is_online: true,
    total_trips: demoProfile?.total_trips ?? 24,
    metadata: {},
    created_at: new Date().toISOString(),
  } : null;

  return {
    user: demoUser ? ({
      id: demoUser.id,
      email: demoUser.email,
      user_metadata: { full_name: demoProfile?.full_name || demoUser.email }
    } as unknown as User) : null,
    session: demoUser ? ({ user: { id: demoUser.id, email: demoUser.email } } as unknown as Session) : null,
    profile: demoProfileData,
    isLoading: false,
    error: null,
    signUp: async () => ({ data: null, error: 'Demo mode - use Try Demo button' }),
    signIn: async () => ({ data: null, error: 'Demo mode - use Try Demo button' }),
    signOut: async () => { demoAuthService.disableDemoMode(); },
    updateProfile: async () => ({ error: null }),
    hasRole: (role: UserRole) => demoProfileData?.role === role,
    isAdmin: () => false,
  };
}

const AuthProvider = ({ children }: { children: ReactNode }) => {
  const [isDemoMode, setIsDemoMode] = useState(demoAuthService.isDemoMode());
  const realAuth = useAuth(); // Always call the hook (rules of hooks)

  // Listen for changes to demo mode flag (instant detection)
  useEffect(() => {
    // Subscribe to demo mode changes using custom event
    const unsubscribe = demoAuthService.onDemoModeChange((newDemoMode) => {
      setIsDemoMode(newDemoMode);
    });

    return unsubscribe;
  }, []);

  const contextValue = isDemoMode ? createDemoAuthContext() : realAuth;

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthProvider;
