import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { UtensilsCrossed, Star, Clock, DollarSign, ChevronRight, Loader2, MessageSquare, Phone, MapPin, AlertCircle } from 'lucide-react';
import { getApprovedRestaurantsByStation } from '@/services/restaurantFilteringService';
import { calculateRestaurantDeliveryFeeK20 } from '@/services/deliveryFeeService';
import { ApprovedRestaurant } from '@/services/restaurantFilteringService';

interface Order {
  id: string;
  orderId: string;
  customerName: string;
  items: string[];
  total: number;
  status: 'ready' | 'preparing' | 'pending';
  estimatedTime: string;
}

interface RestaurantBrowserProps {
  stationId: string;
  stationName: string;
  onSelect?: (restaurantId: string) => void;
}

const RestaurantBrowser: React.FC<RestaurantBrowserProps> = ({
  stationId,
  stationName,
  onSelect,
}) => {
  const [restaurants, setRestaurants] = useState<ApprovedRestaurant[]>([]);
  const [selectedRestaurant, setSelectedRestaurant] = useState<ApprovedRestaurant | null>(null);
  const [loading, setLoading] = useState(true);
  const [loadingOrders, setLoadingOrders] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchRestaurants = async () => {
      setLoading(true);
      setError(null);
      try {
        const approved = await getApprovedRestaurantsByStation(stationId);
        if (approved.length === 0) {
          setError('No approved restaurants available for this station');
        }
        setRestaurants(approved);
      } catch (err) {
        setError('Failed to load restaurants');
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchRestaurants();
  }, [stationId]);

  const handleSelectRestaurant = (restaurant: ApprovedRestaurant) => {
    setSelectedRestaurant(restaurant);
    setLoadingOrders(true);
    // Simulate fetching orders for this restaurant
    setTimeout(() => {
      setLoadingOrders(false);
    }, 500);
  };

  const getDeliveryFeeInfo = (restaurant: ApprovedRestaurant) => {
    // Calculate K20 pricing
    const result = calculateRestaurantDeliveryFeeK20({
      restaurantId: restaurant.id,
      baseK20Fee: restaurant.baseK20Fee,
      distanceBasedFeePerKm: restaurant.distanceFeePerKm,
      isNearStation: restaurant.isNearStation,
      restaurantLatitude: restaurant.latitude,
      restaurantLongitude: restaurant.longitude,
      stationLatitude: 0, // These would come from station data
      stationLongitude: 0,
    });
    return result;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-5 h-5 animate-spin text-primary mr-2" />
        <span className="text-muted-foreground">Loading restaurants...</span>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-destructive/10 border border-destructive rounded-lg p-4 flex items-gap-3">
        <AlertCircle className="w-5 h-5 text-destructive shrink-0" />
        <p className="text-sm text-destructive">{error}</p>
      </div>
    );
  }

  if (restaurants.length === 0) {
    return (
      <div className="text-center py-12">
        <UtensilsCrossed className="w-12 h-12 text-muted-foreground mx-auto mb-3 opacity-50" />
        <p className="text-muted-foreground mb-3">No approved restaurants available yet</p>
        <p className="text-sm text-muted-foreground">Check back soon or contact support</p>
      </div>
    );
  }

  if (selectedRestaurant) {
    const feeInfo = getDeliveryFeeInfo(selectedRestaurant);
    
    return (
      <div className="space-y-4">
        {/* Back Button */}
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setSelectedRestaurant(null)}
          className="h-8"
        >
          ← Back to Restaurants
        </Button>

        {/* Restaurant Header */}
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-start gap-4">
              <div className="text-4xl">🍽️</div>
              <div className="flex-1">
                <h3 className="font-bold text-lg">
                  {selectedRestaurant.name}
                </h3>
                <div className="flex items-center gap-3 mt-2 text-sm">
                  {selectedRestaurant.rating && (
                    <div className="flex items-center gap-1">
                      <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                      <span className="font-semibold">
                        {selectedRestaurant.rating.toFixed(1)}
                      </span>
                      {selectedRestaurant.totalOrders && (
                        <span className="text-muted-foreground">
                          ({selectedRestaurant.totalOrders} orders)
                        </span>
                      )}
                    </div>
                  )}
                </div>
                <div className="flex items-center gap-2 mt-2 text-sm text-muted-foreground">
                  <MapPin className="w-4 h-4" />
                  <span>{selectedRestaurant.stationName}</span>
                </div>
              </div>
            </div>

            {/* Delivery Fee Information */}
            <div className="mt-4 p-3 bg-muted rounded-lg">
              <p className="text-xs text-muted-foreground mb-2">Delivery Fee:</p>
              <p className="font-bold">K{feeInfo.totalFee}</p>
              <p className="text-xs text-muted-foreground mt-1">
                {selectedRestaurant.isNearStation ? 'Station Location' : 'Distance-based fee included'}
              </p>
            </div>
          </CardContent>
        </Card>

        {/* Orders Waiting for Pickup */}
        {loadingOrders ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="w-5 h-5 animate-spin" />
          </div>
        ) : (
          <div className="space-y-3">
            <h4 className="font-semibold text-sm">
              Active Orders
            </h4>
            <div className="text-center py-6 text-muted-foreground text-sm">
              <p>Orders will appear here when customers place requests</p>
              <Button
                variant="outline"
                size="sm"
                className="mt-3"
                onClick={() => setSelectedRestaurant(null)}
              >
                View Other Restaurants
              </Button>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <h3 className="font-semibold text-sm mb-4">Approved Restaurants at {stationName}</h3>
      {restaurants.map((restaurant) => {
        const feeInfo = getDeliveryFeeInfo(restaurant);
        
        return (
          <Card 
            key={restaurant.id}
            className="cursor-pointer hover:border-primary transition"
            onClick={() => handleSelectRestaurant(restaurant)}
          >
            <CardContent className="pt-4">
              <div className="flex items-start gap-3">
                <div className="text-3xl flex-shrink-0">🍽️</div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h4 className="font-semibold">
                        {restaurant.name}
                      </h4>
                      {restaurant.isNearStation && (
                        <Badge variant="secondary" className="mt-1">
                          By Station
                        </Badge>
                      )}
                    </div>
                    <span className="font-bold text-primary whitespace-nowrap">
                      K{feeInfo.totalFee}
                    </span>
                  </div>

                  <div className="flex items-center gap-2 mt-2 text-sm text-muted-foreground flex-wrap">
                    {restaurant.rating && (
                      <div className="flex items-center gap-1">
                        <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                        <span>{restaurant.rating.toFixed(1)}</span>
                      </div>
                    )}
                    {restaurant.menuItems > 0 && (
                      <span>{restaurant.menuItems} menu items</span>
                    )}
                  </div>

                  <p className="text-xs text-muted-foreground mt-2">
                    {feeInfo.breakdown}
                  </p>
                </div>

                <ChevronRight className="w-5 h-5 text-muted-foreground flex-shrink-0 mt-1" />
              </div>
            </CardContent>
          </Card>
        );
      })}
    </div>
  );
};

export default RestaurantBrowser;


  const handleSelectRestaurant = (restaurant: Restaurant) => {
    setSelectedRestaurant(restaurant);
    setLoadingOrders(true);
    // Simulate API call
    setTimeout(() => {
      setLoadingOrders(false);
    }, 500);
  };

  const PriceDisplay = ({ level }: { level: number }) => (
    <span className="text-xs text-slate-400">
      {Array(level)
        .fill('$')
        .join('')}
    </span>
  );

  if (selectedRestaurant) {
    return (
      <div className="space-y-4">
        {/* Back Button */}
        <Button
          variant="ghost"
          size="sm"
          onClick={() => setSelectedRestaurant(null)}
          className="text-blue-400 hover:text-blue-300 h-8"
        >
          ← Back to Restaurants
        </Button>

        {/* Restaurant Header */}
        <div className="bg-slate-800/50 rounded-lg p-4 border border-slate-700">
          <div className="flex items-start gap-4">
            <div className="text-4xl">{selectedRestaurant.image || '🏪'}</div>
            <div className="flex-1">
              <h3 className="font-bold text-lg text-white">
                {selectedRestaurant.name}
              </h3>
              <div className="flex items-center gap-2 mt-2">
                <div className="flex items-center gap-1">
                  <Star className="w-4 h-4 text-yellow-500 fill-yellow-500" />
                  <span className="text-sm font-semibold text-white">
                    {selectedRestaurant.rating}
                  </span>
                  <span className="text-xs text-slate-400">
                    ({selectedRestaurant.reviewCount} reviews)
                  </span>
                </div>
              </div>
              <div className="flex items-center gap-3 mt-2 text-xs text-slate-400">
                <span>{selectedRestaurant.cuisine}</span>
                <PriceDisplay level={selectedRestaurant.priceLevel} />
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {selectedRestaurant.estimatedTime}
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Orders Waiting for Pickup */}
        {loadingOrders ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="w-5 h-5 animate-spin text-blue-400" />
          </div>
        ) : (
          <div className="space-y-3">
            <h4 className="font-semibold text-white text-sm">
              Orders Ready for Pickup
            </h4>
            {MOCK_ORDERS.length > 0 ? (
              MOCK_ORDERS.map((order) => (
                <div
                  key={order.id}
                  className="bg-slate-700/50 rounded-lg p-3 border border-slate-600 hover:border-blue-500/50 transition cursor-pointer"
                  onClick={() => onSelect?.(selectedRestaurant.id)}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <p className="font-semibold text-white text-sm">
                        {order.orderId}
                      </p>
                      <p className="text-xs text-slate-400">
                        {order.customerName}
                      </p>
                    </div>
                    <Badge
                      className={
                        order.status === 'ready'
                          ? 'bg-emerald-600'
                          : 'bg-amber-600'
                      }
                    >
                      {order.status === 'ready' ? '✓ Ready' : '⏱️ Preparing'}
                    </Badge>
                  </div>

                  <p className="text-xs text-slate-400 mb-2">
                    {order.items.join(' + ')}
                  </p>

                  <div className="flex items-center justify-between">
                    <span className="text-sm font-bold text-emerald-400">
                      ${order.total.toFixed(2)}
                    </span>
                    <span className="text-xs text-slate-400">
                      {order.estimatedTime}
                    </span>
                  </div>

                  <Button
                    size="sm"
                    className="w-full mt-2 h-7 text-xs"
                    onClick={(e) => {
                      e.stopPropagation();
                      onSelect?.(selectedRestaurant.id);
                    }}
                  >
                    Pick Up Order <ChevronRight className="w-3 h-3 ml-1" />
                  </Button>
                </div>
              ))
            ) : (
              <div className="text-center py-6 text-slate-400 text-sm">
                <p>No orders available for pickup at the moment</p>
                <Button
                  variant="outline"
                  size="sm"
                  className="mt-3"
                  onClick={() => setSelectedRestaurant(null)}
                >
                  Try Another Restaurant
                </Button>
              </div>
            )}
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {MOCK_RESTAURANTS.map((restaurant) => (
        <div
          key={restaurant.id}
          className="bg-slate-700/50 rounded-lg p-4 border border-slate-600 hover:border-amber-500/50 transition cursor-pointer"
          onClick={() => handleSelectRestaurant(restaurant)}
        >
          <div className="flex items-start gap-3">
            <div className="text-3xl flex-shrink-0">{restaurant.image || '🏪'}</div>

            <div className="flex-1 min-w-0">
              <h4 className="font-semibold text-white text-sm mb-1">
                {restaurant.name}
              </h4>

              <div className="flex items-center gap-2 mb-2">
                <div className="flex items-center gap-1">
                  <Star className="w-3 h-3 text-yellow-500 fill-yellow-500" />
                  <span className="text-xs font-semibold text-white">
                    {restaurant.rating}
                  </span>
                  <span className="text-xs text-slate-400">
                    ({restaurant.reviewCount})
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2 flex-wrap text-xs text-slate-400 mb-3">
                <span className="bg-slate-800/50 px-2 py-1 rounded">
                  {restaurant.cuisine}
                </span>
                <PriceDisplay level={restaurant.priceLevel} />
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  {restaurant.estimatedTime}
                </span>
              </div>

              {/* Rider Contact Actions */}
              <div className="flex gap-2">
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    alert(`Messaging rider for ${restaurant.name}`);
                  }}
                  className="flex-1 flex items-center justify-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 rounded text-white text-xs font-medium transition"
                  title="Text the rider"
                >
                  <MessageSquare className="w-3 h-3" />
                  <span>Text Rider</span>
                </button>
                <button
                  onClick={(e) => {
                    e.stopPropagation();
                    alert(`Calling rider for ${restaurant.name}`);
                  }}
                  className="flex items-center justify-center gap-2 px-3 py-2 bg-green-600 hover:bg-green-700 rounded text-white text-xs font-medium transition"
                  title="Call the rider"
                >
                  <Phone className="w-3 h-3" />
                </button>
              </div>
            </div>

            <ChevronRight className="w-5 h-5 text-slate-400 flex-shrink-0 mt-1" />
          </div>
        </div>
      ))}
    </div>
  );
};

export default RestaurantBrowser;
