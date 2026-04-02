import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Menu, X, LogOut, BarChart3, Shield, ArrowLeft, User } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { supabase } from '@/lib/supabase';
import { demoAuthService } from '@/utils/demoAuthService';

const MobileHeader: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const { user, profile } = useAuthContext();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [isDemoMode, setIsDemoMode] = useState(demoAuthService.isDemoMode());
  const [demoProfile, setDemoProfile] = useState<any>(null);

  // Listen for demo mode changes
  useEffect(() => {
    const unsubscribe = demoAuthService.onDemoModeChange((isDemo: boolean) => {
      setIsDemoMode(isDemo);
      if (isDemo) {
        const stored = localStorage.getItem('busnstay_demo_profile');
        setDemoProfile(stored ? JSON.parse(stored) : null);
      }
    });
    return unsubscribe;
  }, []);

  // Load demo profile on mount if in demo mode
  useEffect(() => {
    if (isDemoMode) {
      const stored = localStorage.getItem('busnstay_demo_profile');
      setDemoProfile(stored ? JSON.parse(stored) : null);
    }
  }, [isDemoMode]);

  // Only show hamburger menu on landing page
  const showHamburgerMenu = location.pathname === '/';
  // Show back button on logged-in pages (not home, not auth)
  // Check both user AND profile, since profile gets populated when logged in
  const isLoggedIn = user || profile || isDemoMode;
  const showBackButton = isLoggedIn && location.pathname !== '/' && location.pathname !== '/auth';

  // Hide header on auth page
  const hideHeader = location.pathname === '/auth';
  
  if (hideHeader) {
    return null;
  }

  // Get display name from user profile or demo profile
  const displayName = isDemoMode 
    ? demoProfile?.full_name 
    : profile?.display_name || user?.email;
  
  const userRole = isDemoMode 
    ? demoProfile?.role 
    : profile?.role;

  return (
    <>
      {/* Mobile Header - Hamburger on landing, Back button on other pages */}
      <div className="md:hidden fixed top-4 right-4 z-[999]">
        {showHamburgerMenu ? (
          // LANDING PAGE - Hamburger Menu
          <>
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-3 bg-blue-600 hover:bg-blue-700 rounded-lg text-white transition-all shadow-lg"
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? (
                <X className="w-6 h-6" />
              ) : (
                <Menu className="w-6 h-6" />
              )}
            </button>

            {/* Slide-out Mobile Menu */}
            {mobileMenuOpen && (
              <>
                {/* Debug: Show menu always for testing */}
                <div className="fixed inset-0 bg-black/50 z-30 md:hidden" onClick={() => setMobileMenuOpen(false)} />
                <motion.div
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: 20 }}
                  className="fixed top-16 right-4 bottom-4 bg-slate-900 border-2 border-blue-500 rounded-lg shadow-2xl overflow-y-auto w-72 z-40"
                >
                  <div className="p-4 space-y-4 bg-slate-900">
                    {/* User Info Header */}
                    <div className="border-b border-slate-600 pb-4">
                      <p className="text-white font-bold text-lg">
                        BusNStay
                      </p>
                      <p className="text-slate-300 text-xs mt-1">
                        Beyond City Limits
                      </p>
                      <p className="text-slate-400 text-xs mt-2">
                        {isLoggedIn ? 'Logged In' : 'Not Logged In'}
                      </p>
                    </div>

                    {/* Navigation Links */}
                    <div className="space-y-2">
                      {isLoggedIn ? (
                        // Show Account, Dashboard, Verification when logged in
                        <>
                          <button
                            onClick={() => {
                              console.log('Navigating to /account');
                              navigate('/account');
                              setMobileMenuOpen(false);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 text-base text-white bg-blue-600 hover:bg-blue-700 rounded transition-all font-medium"
                          >
                            <User className="w-5 h-5" /> 
                            <span>Account</span>
                          </button>
                          <button
                            onClick={() => {
                              console.log('Navigating to /dashboard');
                              navigate('/dashboard');
                              setMobileMenuOpen(false);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 text-base text-white bg-blue-600 hover:bg-blue-700 rounded transition-all font-medium"
                          >
                            <BarChart3 className="w-5 h-5" /> 
                            <span>Dashboard</span>
                          </button>
                          <button
                            onClick={() => {
                              console.log('Navigating to /verification');
                              navigate('/verification');
                              setMobileMenuOpen(false);
                            }}
                            className="w-full flex items-center gap-3 px-4 py-3 text-base text-white bg-blue-600 hover:bg-blue-700 rounded transition-all font-medium"
                          >
                            <Shield className="w-5 h-5" /> 
                            <span>Verification</span>
                          </button>
                        </>
                      ) : (
                        // Show Sign In when not logged in
                        <button
                          onClick={() => {
                            console.log('Navigating to /auth');
                            navigate('/auth');
                            setMobileMenuOpen(false);
                          }}
                          className="w-full flex items-center gap-3 px-4 py-3 text-base text-blue-200 bg-blue-700 hover:bg-blue-600 rounded transition-all font-medium"
                        >
                          🔐 <span>Sign In</span>
                        </button>
                      )}
                    </div>

                    {/* Sign Out - Only show if logged in */}
                    {isLoggedIn && (
                      <div className="border-t border-slate-600 pt-4">
                        <button
                          onClick={async () => {
                            try {
                              console.log('Signing out...');
                              if (isDemoMode) {
                                demoAuthService.disableDemoMode();
                              } else {
                                const { error } = await supabase.auth.signOut();
                                if (error) throw error;
                              }
                              setMobileMenuOpen(false);
                              setTimeout(() => navigate('/'), 100);
                            } catch (err) {
                              console.error('Sign out error:', err);
                              setMobileMenuOpen(false);
                              setTimeout(() => navigate('/'), 100);
                            }
                          }}
                          className="w-full flex items-center gap-3 px-4 py-3 text-base text-red-200 bg-red-700 hover:bg-red-600 rounded transition-all font-medium"
                        >
                          <LogOut className="w-5 h-5" /> 
                          <span>Sign Out</span>
                        </button>
                      </div>
                    )}
                  </div>
                </motion.div>
              </>
            )}
          </>
        ) : showBackButton ? (
          // OTHER PAGES - Back Button
          <button
            onClick={() => navigate(-1)}
            className="p-3 bg-blue-600 hover:bg-blue-700 rounded-lg text-white transition-all shadow-lg"
            aria-label="Go back"
          >
            <ArrowLeft className="w-6 h-6" />
          </button>
        ) : null}
      </div>

      {/* Overlay is now inside the menu component */}
    </>
  );
};

export default MobileHeader;
