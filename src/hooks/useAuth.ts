import { useState, useEffect, useCallback } from 'react';
import { supabase } from '@/lib/supabase';
import { User, Session } from '@supabase/supabase-js';
import { demoAuthService } from '@/utils/demoAuthService';

export type UserRole = 'passenger' | 'restaurant' | 'rider' | 'taxi' | 'hotel' | 'admin';

export interface UserProfile {
  id: string;
  user_id: string;
  email: string | null;
  full_name: string | null;
  phone: string | null;
  avatar_url: string | null;
  role: UserRole;
  is_approved: boolean;
  assigned_station_id: string | null;
  business_name: string | null;
  rating: number;
  is_online: boolean;
  total_trips: number;
  metadata: unknown;
  created_at: string;
}

interface AuthState {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  isLoading: boolean;
  error: string | null;
}

export const useAuth = () => {
  // Skip all Supabase calls if in demo mode
  const isDemoMode = demoAuthService.isDemoMode();
  
  const [state, setState] = useState<AuthState>({
    user: null,
    session: null,
    profile: null,
    isLoading: isDemoMode ? false : true, // Demo mode loads instantly
    error: null,
  });

  // Fetch user profile with timeout
  const fetchProfile = useCallback(async (userId: string) => {
    // Skip fetching if in demo mode - this shouldn't be called anyway
    if (isDemoMode) {
      return null;
    }

    try {
      // Add timeout to profile fetch to prevent hanging
      const profilePromise = supabase
        .from('user_profiles')
        .select('*')
        .eq('user_id', userId)
        .maybeSingle();

      const timeoutPromise = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Profile fetch timeout')), 6000)
      );

      const result = await Promise.race([profilePromise, timeoutPromise]) as any;
      
      // Check for errors in the result
      if (result.error) {
        console.warn('Profile fetch error:', result.error.message);
        return null;
      }

      return result.data as UserProfile | null;
    } catch (err) {
      // Log warning but don't throw - allow app to continue without profile
      const message = err instanceof Error ? err.message : String(err);
      console.warn('Profile fetch issue:', message);
      return null;
    }
  }, [isDemoMode]);

  // Initialize auth state
  useEffect(() => {
    // Skip all Supabase calls if in demo mode
    if (isDemoMode) {
      return; // Demo mode will be handled by AuthContext
    }

    let isMounted = true;

    // Set up auth state listener FIRST (for ONGOING changes)
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        if (!isMounted) return;
        setState(prev => ({ ...prev, session, user: session?.user ?? null }));
        
        if (session?.user) {
          const profile = await fetchProfile(session.user.id);
          if (isMounted) {
            setState(prev => ({ ...prev, profile, isLoading: false }));
          }
        } else {
          setState(prev => ({ ...prev, profile: null, isLoading: false }));
        }
      }
    );

    // INITIAL load
    const initializeAuth = async () => {
      try {
        // Add timeout to getSession to prevent hanging
        const sessionPromise = supabase.auth.getSession();
        const timeoutPromise = new Promise((_, reject) =>
          setTimeout(() => reject(new Error('Session fetch timeout')), 8000)
        );

        const { data: { session }, error } = await Promise.race([sessionPromise, timeoutPromise]) as any;
        
        // Suppress AbortError - it's a known Supabase quirk
        if (error && error.name === 'AbortError') {
          if (isMounted) {
            setState(prev => ({ ...prev, isLoading: false }));
          }
          return;
        }

        if (!isMounted) return;

        setState(prev => ({ ...prev, session, user: session?.user ?? null }));

        if (session?.user) {
          const profile = await fetchProfile(session.user.id);
          if (isMounted) {
            setState(prev => ({ ...prev, profile }));
          }
        }
      } catch (err) {
        // Suppress AbortError and timeout errors
        if (err instanceof Error && (err.name === 'AbortError' || err.message.includes('timeout'))) {
          if (isMounted) {
            setState(prev => ({ ...prev, isLoading: false }));
          }
          return;
        }
        console.warn('Auth init warning:', err instanceof Error ? err.message : err);
      } finally {
        if (isMounted) {
          setState(prev => ({ ...prev, isLoading: false }));
        }
      }
    };

    initializeAuth();

    return () => {
      isMounted = false;
      subscription?.unsubscribe?.();
    };
  }, [fetchProfile, isDemoMode]);

  // Sign up with role
  const signUp = useCallback(async (
    email: string,
    password: string,
    role: UserRole = 'passenger',
    metadata?: { full_name?: string; phone?: string; business_name?: string }
  ) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));
    
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          emailRedirectTo: window.location.origin,
          data: {
            role,
            full_name: metadata?.full_name,
          },
        },
      });

      if (error) throw error;

      // Update profile with additional metadata if user was created
      if (data.user) {
        await supabase
          .from('user_profiles')
          .update({
            phone: metadata?.phone,
            business_name: metadata?.business_name,
            role,
          })
          .eq('user_id', data.user.id);
      }

      return { data, error: null };
    } catch (err) {
      // Suppress AbortError
      if (err instanceof Error && err.name === 'AbortError') {
        setState(prev => ({ ...prev, isLoading: false }));
        return { data: null, error: 'Request aborted' };
      }
      const error = err instanceof Error ? err.message : 'Sign up failed';
      setState(prev => ({ ...prev, error, isLoading: false }));
      return { data: null, error };
    }
  }, []);

  // Sign in
  const signIn = useCallback(async (email: string, password: string) => {
    setState(prev => ({ ...prev, isLoading: true, error: null }));
    
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;
      return { data, error: null };
    } catch (err) {
      // Suppress AbortError
      if (err instanceof Error && err.name === 'AbortError') {
        setState(prev => ({ ...prev, isLoading: false }));
        return { data: null, error: 'Request aborted' };
      }
      const error = err instanceof Error ? err.message : 'Sign in failed';
      setState(prev => ({ ...prev, error, isLoading: false }));
      return { data: null, error };
    }
  }, []);

  // Sign out
  const signOut = useCallback(async () => {
    try {
      await supabase.auth.signOut();
    } catch (err) {
      // Suppress AbortError
      if (!(err instanceof Error && err.name === 'AbortError')) {
        console.error('Sign out error:', err);
      }
    }
    setState({
      user: null,
      session: null,
      profile: null,
      isLoading: false,
      error: null,
    });
    // Navigate to auth page
    window.location.href = '/auth';
  }, []);

  // Update profile
  const updateProfile = useCallback(async (updates: Partial<Omit<UserProfile, 'metadata'>>) => {
    if (!state.user) return { error: 'Not authenticated' };

    try {
      const { error } = await supabase
        .from('user_profiles')
        .update(updates as Record<string, unknown>)
        .eq('user_id', state.user.id);

      if (error) throw error;

      const profile = await fetchProfile(state.user.id);
      setState(prev => ({ ...prev, profile }));
      
      return { error: null };
    } catch (err) {
      return { error: err instanceof Error ? err.message : 'Update failed' };
    }
  }, [state.user, fetchProfile]);

  // Check if user has specific role
  const hasRole = useCallback((role: UserRole) => {
    return state.profile?.role === role;
  }, [state.profile]);

  // Check if user is admin
  const isAdmin = useCallback(() => hasRole('admin'), [hasRole]);

  return {
    ...state,
    signUp,
    signIn,
    signOut,
    updateProfile,
    hasRole,
    isAdmin,
    refetchProfile: () => state.user && fetchProfile(state.user.id),
  };
};

export default useAuth;
