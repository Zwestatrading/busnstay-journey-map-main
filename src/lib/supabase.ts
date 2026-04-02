import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables. Check your .env file.');
}

// Create Supabase client with resilient auth configuration
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: typeof window !== 'undefined' ? window.localStorage : undefined,
  },
  global: {
    headers: {
      'x-application-name': 'busnstay',
    },
  },
});

// Initialize auth without blocking - wrap in try-catch and ignore common errors
export const initializeAuthSession = async () => {
  try {
    const { data } = await Promise.race([
      supabase.auth.getSession(),
      new Promise((_, reject) => setTimeout(() => reject(new Error('Auth init timeout')), 5000)),
    ]);
    return data;
  } catch (error) {
    // Suppress non-critical errors (AbortError, timeouts, etc.)
    // These are expected in development with React StrictMode
    if (error instanceof Error && (error.name === 'AbortError' || error.message.includes('timeout'))) {
      return null;
    }
    console.warn('Auth initialization issue:', error instanceof Error ? error.message : error);
    return null;
  }
};

export default supabase;
