import { createContext } from 'react';
import { useAuth, UserProfile, UserRole } from '@/hooks/useAuth';
import { User, Session } from '@supabase/supabase-js';

export interface AuthContextType {
  user: User | null;
  session: Session | null;
  profile: UserProfile | null;
  isLoading: boolean;
  error: string | null;
  signUp: (
    email: string,
    password: string,
    role?: UserRole,
    metadata?: { full_name?: string; phone?: string; business_name?: string }
  ) => Promise<{ data: unknown; error: string | null }>;
  signIn: (email: string, password: string) => Promise<{ data: unknown; error: string | null }>;
  signOut: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<{ error: string | null }>;
  hasRole: (role: UserRole) => boolean;
  isAdmin: () => boolean;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);
