import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { demoAuthService } from '@/utils/demoAuthService';
import { Loader2 } from 'lucide-react';

// Dashboard router - redirects to role-specific dashboard
const Dashboard = () => {
  const navigate = useNavigate();
  const { profile, isLoading, user } = useAuthContext();
  const isDemoMode = demoAuthService.isDemoMode();

  useEffect(() => {
    // In demo mode, wait a tiny bit for auth context to update
    if (isDemoMode && (isLoading || !profile || !user)) {
      const timeout = setTimeout(() => {
        // Check again with demo data as fallback
        const demoProfile = demoAuthService.getDemoProfile();
        if (demoProfile) {
          // Route based on demo profile
          switch (demoProfile.role) {
            case 'admin':
              navigate('/admin');
              break;
            case 'restaurant':
              navigate('/restaurant');
              break;
            case 'rider':
              navigate('/rider');
              break;
            case 'taxi':
              navigate('/taxi');
              break;
            case 'hotel':
              navigate('/hotel');
              break;
            case 'passenger':
            default:
              navigate('/');
              break;
          }
        } else {
          navigate('/auth');
        }
      }, 100);
      return () => clearTimeout(timeout);
    }

    if (isLoading) return;

    if (!user) {
      navigate('/auth');
      return;
    }

    if (!profile) {
      // If no profile after auth loaded, wait max 3s then go home
      const timeout = setTimeout(() => navigate('/'), 3000);
      return () => clearTimeout(timeout);
    }

    // Route to role-specific dashboard
    switch (profile.role) {
      case 'admin':
        navigate('/admin');
        break;
      case 'restaurant':
        navigate('/restaurant');
        break;
      case 'rider':
        navigate('/rider');
        break;
      case 'taxi':
        navigate('/taxi');
        break;
      case 'hotel':
        navigate('/hotel');
        break;
      case 'passenger':
      default:
        navigate('/');
        break;
    }
  }, [profile, isLoading, user, navigate, isDemoMode]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-background">
      <div className="text-center">
        <Loader2 className="w-8 h-8 animate-spin mx-auto mb-4 text-primary" />
        <p className="text-muted-foreground">Loading your dashboard...</p>
      </div>
    </div>
  );
};

export default Dashboard;
