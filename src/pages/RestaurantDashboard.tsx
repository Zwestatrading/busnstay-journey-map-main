import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { useNavigate } from 'react-router-dom';
import { useAuthContext } from '@/contexts/useAuthContext';
import { useBackNavigation } from '@/hooks/useBackNavigation';
import { supabase } from '@/lib/supabase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Switch } from '@/components/ui/switch';
import { 
  Utensils, Clock, CheckCircle2, XCircle, Package, 
  MapPin, Bus, AlertCircle, LogOut, Settings, Loader2
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface Order {
  id: string;
  items: Array<{ name: string; quantity: number; price: number }>;
  total: number;
  status: string;
  special_instructions: string | null;
  created_at: string;
  estimated_ready_time: string | null;
  delivery_type: string;
  journey_id: string | null;
}

interface MenuItem {
  id: string;
  name: string;
  description: string | null;
  price: number;
  category: string;
  is_available: boolean;
  prep_time: number;
}

const RestaurantDashboard = () => {
  const navigate = useNavigate();
  const { toast } = useToast();
  const { profile, signOut, isLoading: authLoading } = useAuthContext();
  useBackNavigation('/');
  
  const [isOpen, setIsOpen] = useState(true);
  const [orders, setOrders] = useState<Order[]>([]);
  const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [restaurantId, setRestaurantId] = useState<string | null>(null);
  const [stationName, setStationName] = useState('');

  // Fetch station name
  useEffect(() => {
    if (!profile?.assigned_station_id) return;
    const fetchStation = async () => {
      const { data } = await supabase
        .from('stops')
        .select('name')
        .eq('id', profile.assigned_station_id)
        .maybeSingle();
      if (data) setStationName(data.name);
    };
    fetchStation();
  }, [profile?.assigned_station_id]);

  // Fetch or auto-create restaurant record
  useEffect(() => {
    if (!profile?.assigned_station_id || !profile?.is_approved) {
      setLoading(false);
      return;
    }

    const fetchOrCreateRestaurant = async () => {
      // Try to find existing restaurant at this stop
      const { data: restaurants } = await supabase
        .from('restaurants')
        .select('*')
        .eq('stop_id', profile.assigned_station_id)
        .limit(1);

      let restaurant = restaurants && restaurants.length > 0 ? restaurants[0] : null;

      // Auto-create restaurant record if approved provider doesn't have one
      if (!restaurant) {
        const { data: newRestaurant, error } = await supabase
          .from('restaurants')
          .insert({
            name: profile.business_name || `${profile.full_name}'s Restaurant`,
            stop_id: profile.assigned_station_id!,
            cuisine: 'Local',
            is_open: true,
          })
          .select()
          .single();

        if (!error && newRestaurant) {
          restaurant = newRestaurant;
        }
      }

      if (restaurant) {
        setRestaurantId(restaurant.id);
        setIsOpen(restaurant.is_open ?? true);
        
        const { data: items } = await supabase
          .from('menu_items')
          .select('*')
          .eq('restaurant_id', restaurant.id);
        
        if (items) setMenuItems(items as MenuItem[]);
      }
      setLoading(false);
    };

    fetchOrCreateRestaurant();
  }, [profile]);

  // Fetch orders
  useEffect(() => {
    if (!restaurantId) return;

    const fetchOrders = async () => {
      const { data } = await supabase
        .from('orders')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .in('status', ['pending', 'confirmed', 'preparing', 'ready'])
        .order('created_at', { ascending: false });

      if (data) setOrders(data as unknown as Order[]);
    };

    fetchOrders();

    const channel = supabase
      .channel('restaurant-orders')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'orders',
          filter: `restaurant_id=eq.${restaurantId}`,
        },
        () => fetchOrders()
      )
      .subscribe();

    return () => { channel.unsubscribe(); };
  }, [restaurantId]);

  const updateOrderStatus = async (orderId: string, status: string) => {
    const { error } = await supabase
      .from('orders')
      .update({ 
        status,
        ...(status === 'ready' ? { actual_ready_time: new Date().toISOString() } : {})
      })
      .eq('id', orderId);

    if (error) {
      toast({ title: 'Error', description: 'Failed to update order', variant: 'destructive' });
    } else {
      toast({ title: 'Order Updated', description: `Order marked as ${status}` });
    }
  };

  const toggleItemAvailability = async (itemId: string, available: boolean) => {
    await supabase
      .from('menu_items')
      .update({ is_available: available })
      .eq('id', itemId);
    
    setMenuItems(prev => 
      prev.map(item => item.id === itemId ? { ...item, is_available: available } : item)
    );
  };

  const toggleRestaurantOpen = async () => {
    if (!restaurantId) return;
    
    const newStatus = !isOpen;
    await supabase
      .from('restaurants')
      .update({ is_open: newStatus })
      .eq('id', restaurantId);
    
    setIsOpen(newStatus);
    toast({ 
      title: newStatus ? 'Restaurant Open' : 'Restaurant Closed',
      description: newStatus ? 'You can now receive orders' : 'No new orders will be received'
    });
  };

  if (authLoading || loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin" />
      </div>
    );
  }

  if (!profile?.is_approved) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <AlertCircle className="w-5 h-5 text-warning" />
              Pending Approval
            </CardTitle>
            <CardDescription>
              Your restaurant account is pending admin approval. You'll be notified once approved.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => signOut()} variant="outline" className="w-full">
              <LogOut className="w-4 h-4 mr-2" />
              Sign Out
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!profile?.assigned_station_id) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <MapPin className="w-5 h-5 text-warning" />
              No Station Assigned
            </CardTitle>
            <CardDescription>
              Your account doesn't have a station assigned yet. Please contact an admin or re-register with a station selected.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => signOut()} variant="outline" className="w-full">
              <LogOut className="w-4 h-4 mr-2" />
              Sign Out
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  if (!restaurantId) {
    return (
      <div className="min-h-screen flex items-center justify-center p-4">
        <Card className="max-w-md">
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Loader2 className="w-5 h-5 animate-spin text-primary" />
              Setting Up Your Restaurant
            </CardTitle>
            <CardDescription>
              Creating your restaurant profile at {stationName || 'your station'}. Please refresh the page if this takes too long.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <Button onClick={() => window.location.reload()} variant="outline" className="w-full mb-2">
              Refresh Page
            </Button>
            <Button onClick={() => signOut()} variant="ghost" className="w-full">
              <LogOut className="w-4 h-4 mr-2" /> Sign Out
            </Button>
          </CardContent>
        </Card>
      </div>
    );
  }

  const pendingOrders = orders.filter(o => o.status === 'pending' || o.status === 'confirmed');
  const preparingOrders = orders.filter(o => o.status === 'preparing');
  const readyOrders = orders.filter(o => o.status === 'ready');

  return (
    <div className="min-h-screen bg-background">
      <header className="border-b bg-card sticky top-0 z-50">
        <div className="container mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center">
              <Utensils className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <h1 className="font-bold">{profile?.business_name || 'Restaurant'}</h1>
              <p className="text-xs text-muted-foreground flex items-center gap-1">
                <MapPin className="w-3 h-3" />
                {stationName}
              </p>
            </div>
          </div>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2">
              <span className="text-sm">{isOpen ? 'Open' : 'Closed'}</span>
              <Switch checked={isOpen} onCheckedChange={toggleRestaurantOpen} />
            </div>
            <Button variant="ghost" size="icon" onClick={() => signOut()}>
              <LogOut className="w-5 h-5" />
            </Button>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6">
        <div className="grid grid-cols-3 gap-4 mb-6">
          <Card>
            <CardContent className="pt-4">
              <div className="text-2xl font-bold text-warning">{pendingOrders.length}</div>
              <p className="text-sm text-muted-foreground">New Orders</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="text-2xl font-bold text-primary">{preparingOrders.length}</div>
              <p className="text-sm text-muted-foreground">Preparing</p>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-4">
              <div className="text-2xl font-bold text-journey-completed">{readyOrders.length}</div>
              <p className="text-sm text-muted-foreground">Ready</p>
            </CardContent>
          </Card>
        </div>

        <Tabs defaultValue="orders" className="space-y-4">
          <TabsList>
            <TabsTrigger value="orders">Orders ({orders.length})</TabsTrigger>
            <TabsTrigger value="menu">Menu Items</TabsTrigger>
          </TabsList>

          <TabsContent value="orders" className="space-y-4">
            {orders.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <Package className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">No active orders</p>
                </CardContent>
              </Card>
            ) : (
              orders.map((order) => (
                <motion.div key={order.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
                  <Card className={order.status === 'pending' ? 'border-warning' : ''}>
                    <CardHeader className="pb-2">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <Badge variant={
                            order.status === 'pending' ? 'destructive' :
                            order.status === 'preparing' ? 'default' : 'secondary'
                          }>
                            {order.status.toUpperCase()}
                          </Badge>
                          {order.journey_id && (
                            <Badge variant="outline" className="gap-1">
                              <Bus className="w-3 h-3" />
                              Bus Delivery
                            </Badge>
                          )}
                        </div>
                        <span className="text-sm text-muted-foreground">
                          {new Date(order.created_at).toLocaleTimeString()}
                        </span>
                      </div>
                    </CardHeader>
                    <CardContent className="space-y-3">
                      <div className="space-y-1">
                        {order.items.map((item, i) => (
                          <div key={i} className="flex justify-between text-sm">
                            <span>{item.quantity}x {item.name}</span>
                            <span>K{item.price * item.quantity}</span>
                          </div>
                        ))}
                        <div className="border-t pt-2 flex justify-between font-bold">
                          <span>Total</span>
                          <span>K{order.total}</span>
                        </div>
                      </div>

                      {order.special_instructions && (
                        <div className="bg-muted p-2 rounded text-sm">
                          <strong>Note:</strong> {order.special_instructions}
                        </div>
                      )}

                      <div className="flex gap-2">
                        {order.status === 'pending' && (
                          <>
                            <Button className="flex-1" onClick={() => updateOrderStatus(order.id, 'preparing')}>
                              <CheckCircle2 className="w-4 h-4 mr-2" />
                              Accept & Start
                            </Button>
                            <Button variant="destructive" onClick={() => updateOrderStatus(order.id, 'cancelled')}>
                              <XCircle className="w-4 h-4" />
                            </Button>
                          </>
                        )}
                        {order.status === 'preparing' && (
                          <Button className="flex-1 bg-journey-completed hover:bg-journey-completed/90" onClick={() => updateOrderStatus(order.id, 'ready')}>
                            <CheckCircle2 className="w-4 h-4 mr-2" />
                            Mark Ready
                          </Button>
                        )}
                        {order.status === 'ready' && (
                          <div className="flex-1 text-center py-2 bg-journey-completed/20 rounded">
                            <Clock className="w-4 h-4 inline mr-2" />
                            Waiting for pickup
                          </div>
                        )}
                      </div>
                    </CardContent>
                  </Card>
                </motion.div>
              ))
            )}
          </TabsContent>

          <TabsContent value="menu" className="space-y-4">
            {menuItems.length === 0 ? (
              <Card>
                <CardContent className="py-12 text-center">
                  <Utensils className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
                  <p className="text-muted-foreground">No menu items yet</p>
                  <p className="text-sm text-muted-foreground">Menu items will appear once configured by admin</p>
                </CardContent>
              </Card>
            ) : (
              menuItems.map((item) => (
                <Card key={item.id}>
                  <CardContent className="py-4">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2">
                          <h3 className="font-medium">{item.name}</h3>
                          <Badge variant="outline">{item.category}</Badge>
                        </div>
                        <p className="text-sm text-muted-foreground">{item.description}</p>
                        <p className="text-sm font-medium mt-1">K{item.price} • {item.prep_time} min</p>
                      </div>
                      <Switch
                        checked={item.is_available}
                        onCheckedChange={(checked) => toggleItemAvailability(item.id, checked)}
                      />
                    </div>
                  </CardContent>
                </Card>
              ))
            )}
          </TabsContent>
        </Tabs>
      </main>
    </div>
  );
};

export default RestaurantDashboard;
