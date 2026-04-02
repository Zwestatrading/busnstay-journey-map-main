import { useEffect, useState, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '@/lib/supabase';
import ServiceProviderVerification from '@/components/ServiceProviderVerification';
import { Button } from '@/components/ui/button';
import { LogOut, ArrowLeft, AlertCircle } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { demoAuthService } from '@/utils/demoAuthService';

export const VerificationPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const [user, setUser] = useState<unknown>(null);
  const [userRole, setUserRole] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const isDemoMode = demoAuthService.isDemoMode();

  const checkUserAccessAndRole = useCallback(async () => {
    try {
      // In demo mode, skip Supabase and use demo data
      if (isDemoMode) {
        const demoUser = demoAuthService.getDemoUser();
        const demoProfile = demoAuthService.getDemoProfile();
        
        if (!demoUser) {
          navigate('/auth');
          setIsLoading(false);
          return;
        }

        setUser({
          id: demoUser.id,
          email: demoUser.email,
          user_metadata: { full_name: demoProfile?.full_name },
        });

        // Demo profile role can be any service provider role
        const demoRole = demoProfile?.role || 'rider';
        const serviceProviderRoles = ['restaurant', 'hotel', 'taxi_driver', 'rider', 'taxi'];
        
        if (serviceProviderRoles.includes(demoRole)) {
          setUserRole(demoRole);
        } else {
          toast({
            title: 'Access Denied',
            description: 'Your account is not eligible for service provider verification. Please sign up as a Driver, Restaurant, Hotel, or Taxi Driver.',
            variant: 'destructive',
          });
          setTimeout(() => navigate('/'), 2000);
        }
        setIsLoading(false);
        return;
      }

      const { data: userData, error } = await supabase.auth.getUser();

      // Suppress AbortError - it's a known Supabase quirk
      if (error && error.name === 'AbortError') {
        setIsLoading(false);
        return;
      }

      if (!userData?.user) {
        navigate('/auth');
        return;
      }

      setUser(userData.user);

      // Fetch user profile to check if they're a service provider
      const { data: profileData } = await supabase
        .from('user_profiles')
        .select('role')
        .eq('user_id', userData.user.id)
        .maybeSingle();

      if (!profileData) {
        // Profile doesn't exist yet - might be new user, allow verification anyway
        const role = userData.user.user_metadata?.role || 'rider';
        const serviceProviderRoles = ['restaurant', 'hotel', 'taxi_driver', 'rider', 'taxi'];
        
        if (serviceProviderRoles.includes(role)) {
          setUserRole(role);
          setIsLoading(false);
          return;
        } else {
          toast({
            title: 'Access Denied',
            description: 'Your account is not eligible for service provider verification.',
            variant: 'destructive',
          });
          setTimeout(() => navigate('/'), 2000);
          setIsLoading(false);
          return;
        }
      }

      // Check if role is service provider eligible
      const serviceProviderRoles = ['restaurant', 'hotel', 'taxi_driver', 'rider', 'taxi'];
      if (!serviceProviderRoles.includes(profileData.role)) {
        toast({
          title: 'Access Denied',
          description: 'Your account is not eligible for service provider verification',
          variant: 'destructive',
        });
        navigate('/');
        return;
      }

      setUserRole(profileData.role);
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Error checking access:', error);
    } finally {
      setIsLoading(false);
    }
  }, [navigate, toast, isDemoMode]);

  useEffect(() => {
    checkUserAccessAndRole();
  }, [navigate, toast, isDemoMode, checkUserAccessAndRole]);

  const handleSignOut = async () => {
    try {
      if (!isDemoMode) {
        await supabase.auth.signOut();
      } else {
        demoAuthService.disableDemoMode();
      }
      toast({ title: 'Signed out successfully' });
      setTimeout(() => navigate('/auth'), 500);
    } catch (error) {
      // Suppress AbortError
      if (error instanceof Error && error.name === 'AbortError') {
        return;
      }
      console.error('Sign out error:', error);
      toast({
        title: 'Sign out failed',
        description: 'Please try again',
        variant: 'destructive',
      });
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 flex items-center justify-center">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto mb-4" />
          <p className="text-gray-400">Checking your profile...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950">
      {/* Navigation */}
      <div className="border-b border-white/10 bg-slate-900/50 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Button
              onClick={() => navigate('/')}
              variant="ghost"
              size="sm"
              className="text-gray-300 hover:text-white hover:bg-white/10"
            >
              <ArrowLeft className="w-4 h-4 mr-2" />
              Back to Home
            </Button>
          </div>
          <Button
            onClick={handleSignOut}
            variant="ghost"
            size="sm"
            className="text-gray-300 hover:text-red-400 hover:bg-red-900/20"
          >
            <LogOut className="w-4 h-4 mr-2" />
            Sign Out
          </Button>
        </div>
      </div>

      {/* Content */}
      <div className="max-w-4xl mx-auto px-4 py-8">
        {user ? (
          <ServiceProviderVerification />
        ) : (
          <div className="text-center py-12">
            <AlertCircle className="w-12 h-12 mx-auto mb-4 text-warning" />
            <p className="text-gray-400 mb-4">Please sign in to verify as a service provider</p>
            <Button onClick={() => navigate('/auth')}>Sign In</Button>
          </div>
        )}
      </div>
    </div>
  );
};

export default VerificationPage;
