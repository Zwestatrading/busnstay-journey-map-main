import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { UserRole } from '@/hooks/useAuth';
import { supabase } from '@/integrations/supabase/client';
import { demoAuthService } from '@/utils/demoAuthService';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Bus, Utensils, Bike, Car, Hotel, Shield, Loader2, ArrowLeft, MapPin } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface StopOption {
  id: string;
  name: string;
  region: string;
  town_id: string;
}

const roleIcons: Record<UserRole, typeof Bus> = {
  passenger: Bus,
  restaurant: Utensils,
  rider: Bike,
  taxi: Car,
  hotel: Hotel,
  admin: Shield,
};

const roleLabels: Record<UserRole, string> = {
  passenger: 'Passenger',
  restaurant: 'Restaurant Owner',
  rider: 'Delivery Rider',
  taxi: 'Taxi Driver',
  hotel: 'Hotel/Lodge Owner',
  admin: 'Administrator',
};

const AuthPage = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { signIn, signUp, isLoading, user } = useAuthContext();
  
  const [isSignUp, setIsSignUp] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [businessName, setBusinessName] = useState('');
  const [selectedRole, setSelectedRole] = useState<UserRole>('passenger');
  const [selectedStationId, setSelectedStationId] = useState('');
  const [stops, setStops] = useState<StopOption[]>([]);
  const [stopsLoading, setStopsLoading] = useState(false);
  const [autoLogging, setAutoLogging] = useState(false);

  // Redirect if already logged in
  useEffect(() => {
    if (user) {
      navigate('/dashboard');
    }
  }, [user, navigate]);

  // Fetch stops for station selection
  useEffect(() => {
    const fetchStops = async () => {
      setStopsLoading(true);
      
      // Default stations (fallback if Supabase is empty)
      const defaultStations: StopOption[] = [
        { id: 'lusaka', name: 'Lusaka Main Station', region: 'Lusaka', town_id: 'lusaka' },
        { id: 'livingstone', name: 'Livingstone Station', region: 'Southern', town_id: 'livingstone' },
        { id: 'ndola', name: 'Ndola Station', region: 'Copperbelt', town_id: 'ndola' },
        { id: 'kitwe', name: 'Kitwe Station', region: 'Copperbelt', town_id: 'kitwe' },
        { id: 'chipata', name: 'Chipata Station', region: 'Eastern', town_id: 'chipata' },
        { id: 'mongu', name: 'Mongu Station', region: 'Western', town_id: 'mongu' },
        { id: 'kasama', name: 'Kasama Station', region: 'Northern', town_id: 'kasama' },
        { id: 'solwezi', name: 'Solwezi Station', region: 'North-Western', town_id: 'solwezi' },
      ];

      try {
        const { data } = await supabase
          .from('stops')
          .select('id, name, region, town_id')
          .eq('is_active', true)
          .order('name');
        
        if (data && data.length > 0) {
          setStops(data as StopOption[]);
        } else {
          // Use default stations if database is empty
          setStops(defaultStations);
        }
      } catch (error) {
        console.debug('Error fetching stations, using defaults', error);
        // Use default stations if fetch fails
        setStops(defaultStations);
      }
      
      setStopsLoading(false);
    };

    fetchStops();
  }, []);

  // Auto-login as admin
  const handleAdminLogin = async () => {
    setAutoLogging(true);
    const { error } = await signIn('admin@busnstay.test', 'Admin123!');
    if (error) {
      toast({ title: 'Admin Login Failed', description: error, variant: 'destructive' });
    } else {
      navigate('/dashboard');
    }
    setAutoLogging(false);
  };

  // Demo login (bypasses Supabase) - supports multiple roles
  const handleDemoLogin = async (role: string = 'passenger', destination: string = '/account') => {
    try {
      const roleNames: Record<string, string> = {
        passenger: 'Demo Passenger',
        rider: 'Demo Rider',
        restaurant: 'Demo Restaurant',
        hotel: 'Demo Hotel',
        taxi: 'Demo Taxi Driver',
        admin: 'Demo Admin'
      };
      
      demoAuthService.enableDemoMode(`demo-${role}@busnstay.local`, role, roleNames[role] || 'Demo User');
      toast({
        title: 'Demo Mode Activated',
        description: `Logged in as ${roleNames[role]}. All data is simulated.`,
      });
      
      // Add small delay to ensure AuthProvider registers demo mode change
      setTimeout(() => {
        navigate(destination);
      }, 100);
    } catch (error) {
      toast({
        title: 'Demo Login Failed',
        description: 'Failed to activate demo mode.',
        variant: 'destructive',
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (isSignUp) {
      if (needsStation && !selectedStationId) {
        toast({ title: 'Station Required', description: 'Please select the town/station your business operates from', variant: 'destructive' });
        return;
      }

      const { error } = await signUp(email, password, selectedRole, {
        full_name: fullName,
        phone,
        business_name: businessName,
      });
      
      if (error) {
        toast({ title: 'Sign Up Failed', description: error, variant: 'destructive' });
      } else {
        // Update the station assignment
        if (needsStation && selectedStationId) {
          // We need to wait a bit for the profile to be created by the trigger
          setTimeout(async () => {
            const { data: { user: newUser } } = await supabase.auth.getUser();
            if (newUser) {
              await supabase
                .from('user_profiles')
                .update({ assigned_station_id: selectedStationId })
                .eq('user_id', newUser.id);
            }
          }, 1000);
        }

        toast({ 
          title: 'Account Created!', 
          description: selectedRole === 'passenger' 
            ? 'You can now sign in.'
            : 'Your account needs admin approval before you can start.',
        });
        setIsSignUp(false);
      }
    } else {
      const { error } = await signIn(email, password);
      
      if (error) {
        toast({ title: 'Sign In Failed', description: error, variant: 'destructive' });
      } else {
        navigate('/dashboard');
      }
    }
  };

  const needsBusinessInfo = ['restaurant', 'hotel', 'taxi'].includes(selectedRole);
  const needsStation = ['restaurant', 'hotel', 'taxi', 'rider'].includes(selectedRole);

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-background to-primary/5 flex items-center justify-center p-4">
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-md"
      >
        <Button
          variant="ghost"
          size="sm"
          onClick={() => navigate('/')}
          className="mb-4"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back to Home
        </Button>

        <Card className="border-2">
          <CardHeader className="text-center">
            <div className="w-16 h-16 bg-primary rounded-2xl flex items-center justify-center mx-auto mb-4">
              <Bus className="w-8 h-8 text-primary-foreground" />
            </div>
            <CardTitle className="text-2xl font-display">BusNStay</CardTitle>
            <CardDescription>
              {isSignUp ? 'Create your account' : 'Sign in to continue'}
            </CardDescription>
          </CardHeader>

          <CardContent>
            <Tabs value={isSignUp ? 'signup' : 'signin'} onValueChange={(v) => setIsSignUp(v === 'signup')}>
              <TabsList className="grid w-full grid-cols-2 mb-6">
                <TabsTrigger value="signin">Sign In</TabsTrigger>
                <TabsTrigger value="signup">Sign Up</TabsTrigger>
              </TabsList>

              <form onSubmit={handleSubmit} className="space-y-4">
                {isSignUp && (
                  <>
                    <div className="space-y-2">
                      <Label>I am a...</Label>
                      <Select value={selectedRole} onValueChange={(v) => setSelectedRole(v as UserRole)}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {(Object.keys(roleLabels) as UserRole[]).filter(r => r !== 'admin').map((role) => {
                            const Icon = roleIcons[role];
                            return (
                              <SelectItem key={role} value={role}>
                                <div className="flex items-center gap-2">
                                  <Icon className="w-4 h-4" />
                                  {roleLabels[role]}
                                </div>
                              </SelectItem>
                            );
                          })}
                        </SelectContent>
                      </Select>
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="fullName">Full Name</Label>
                      <Input
                        id="fullName"
                        value={fullName}
                        onChange={(e) => setFullName(e.target.value)}
                        placeholder="John Doe"
                        required
                      />
                    </div>

                    <div className="space-y-2">
                      <Label htmlFor="phone">Phone Number</Label>
                      <Input
                        id="phone"
                        type="tel"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                        placeholder="+260 97 1234567"
                      />
                    </div>

                    {needsBusinessInfo && (
                      <div className="space-y-2">
                        <Label htmlFor="businessName">Business Name</Label>
                        <Input
                          id="businessName"
                          value={businessName}
                          onChange={(e) => setBusinessName(e.target.value)}
                          placeholder="Your business name"
                          required
                        />
                      </div>
                    )}

                    {needsStation && (
                      <div className="space-y-2">
                        <Label className="flex items-center gap-1">
                          <MapPin className="w-4 h-4" />
                          Operating Station (Town) *
                        </Label>
                        {stopsLoading ? (
                          <div className="w-full h-10 bg-muted rounded-md flex items-center justify-center text-sm text-muted-foreground">
                            <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                            Loading stations...
                          </div>
                        ) : stops.length === 0 ? (
                          <div className="w-full h-10 bg-red-50 rounded-md flex items-center justify-center text-sm text-red-700 border border-red-200">
                            ⚠️ No stations available
                          </div>
                        ) : (
                          <Select value={selectedStationId} onValueChange={setSelectedStationId}>
                            <SelectTrigger className="w-full">
                              <SelectValue placeholder="Select your town/station" />
                            </SelectTrigger>
                            <SelectContent className="relative z-50 w-full">
                              {stops.map((stop) => (
                                <SelectItem key={stop.id} value={stop.id}>
                                  <span>{stop.name} — {stop.region}</span>
                                </SelectItem>
                              ))}
                            </SelectContent>
                          </Select>
                        )}
                        <p className="text-xs text-muted-foreground">
                          You will only receive orders/requests from travelers at this station
                        </p>
                      </div>
                    )}
                  </>
                )}

                <div className="space-y-2">
                  <Label htmlFor="email">Email</Label>
                  <Input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="password">Password</Label>
                  <Input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    minLength={6}
                  />
                </div>

                <Button type="submit" className="w-full" disabled={isLoading}>
                  {isLoading && <Loader2 className="w-4 h-4 mr-2 animate-spin" />}
                  {isSignUp ? 'Create Account' : 'Sign In'}
                </Button>

                {isSignUp && (
                  <p className="text-xs text-muted-foreground text-center">
                    {needsStation 
                      ? 'Your account will need admin approval before you can start operating.'
                      : 'By signing up, you agree to our terms of service.'
                    }
                  </p>
                )}
              </form>
            </Tabs>

            {/* Quick Admin Login & Demo Login */}
            {!isSignUp && (
              <div className="mt-4 pt-4 border-t space-y-2">
                <p className="text-xs text-muted-foreground font-semibold mb-2">🎮 Quick Demo Access:</p>
                <div className="grid grid-cols-3 gap-2">
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1 text-xs h-auto py-2"
                    onClick={() => handleDemoLogin('passenger', '/')}
                  >
                    <MapPin className="w-3 h-3" />
                    Passenger
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1 text-xs h-auto py-2"
                    onClick={() => handleDemoLogin('rider', '/rider')}
                  >
                    <Bike className="w-3 h-3" />
                    Rider
                  </Button>
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1 text-xs h-auto py-2"
                    onClick={() => handleDemoLogin('restaurant', '/restaurant')}
                  >
                    <Utensils className="w-3 h-3" />
                    Restaurant
                  </Button>
                </div>
                
                <Button
                  variant="outline"
                  className="w-full gap-2 mt-2"
                  onClick={handleAdminLogin}
                  disabled={autoLogging}
                >
                  {autoLogging ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Shield className="w-4 h-4" />
                  )}
                  🔐 Admin Dashboard
                </Button>
              </div>
            )}
          </CardContent>
        </Card>
      </motion.div>
    </div>
  );
};

export default AuthPage;
