import { useState } from 'react';
import { motion } from 'framer-motion';
import { Search, MapPin, Clock, ChefHat, AlertCircle } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import TextCallCentre from '@/components/TextCallCentre';

interface Restaurant {
  id: string;
  name: string;
  category: string;
  deliveryTime: number; // in minutes
  distance: number; // in km
  rating: number;
  isOpen: boolean;
}

interface BookingPageProps {
  stationName?: string;
  restaurants?: Restaurant[];
}

/**
 * Example Booking Page Component
 * Shows how to integrate the TextCallCentre feature for customers
 * when they can't find their desired restaurant in the system
 */
const BookingPageExample = ({ 
  stationName = "Lusaka Main Station",
  restaurants = [
    { id: '1', name: 'Nandos', category: 'Chicken', deliveryTime: 20, distance: 0.5, rating: 4.8, isOpen: true },
    { id: '2', name: 'KFC', category: 'Fried Chicken', deliveryTime: 15, distance: 0.3, rating: 4.6, isOpen: true },
    { id: '3', name: 'Chilis', category: 'International', deliveryTime: 25, distance: 1.2, rating: 4.5, isOpen: false },
  ]
}: BookingPageProps) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedRestaurant, setSelectedRestaurant] = useState<Restaurant | null>(null);

  // Filter restaurants based on search and category
  const filteredRestaurants = restaurants.filter((restaurant) => {
    const matchesSearch = restaurant.name.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || restaurant.category.toLowerCase() === selectedCategory.toLowerCase();
    return matchesSearch && matchesCategory;
  });

  const categories = ['all', 'chicken', 'burgers', 'pizza', 'international', 'local'];

  return (
    <div className="min-h-screen bg-gradient-to-b from-background to-muted/30">
      {/* Header */}
      <header className="border-b bg-card sticky top-0 z-40">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center gap-2 mb-4">
            <MapPin className="w-4 h-4 text-primary" />
            <span className="text-sm font-medium">{stationName}</span>
          </div>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Search restaurants, cuisines..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-9"
            />
          </div>
        </div>
      </header>

      <main className="container mx-auto px-4 py-6 space-y-6">
        {/* Category Filter */}
        <div className="space-y-3">
          <p className="text-sm font-medium text-muted-foreground">Filter by cuisine</p>
          <div className="flex gap-2 overflow-x-auto pb-2">
            {categories.map((category) => (
              <Button
                key={category}
                variant={selectedCategory === category ? 'default' : 'outline'}
                size="sm"
                onClick={() => setSelectedCategory(category)}
                className="capitalize whitespace-nowrap"
              >
                {category === 'all' ? 'All Cuisines' : category}
              </Button>
            ))}
          </div>
        </div>

        {/* Results Section */}
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h2 className="font-semibold text-lg">
              {searchQuery 
                ? `Results for "${searchQuery}"` 
                : selectedCategory === 'all' 
                  ? 'All Restaurants'
                  : `${selectedCategory} Restaurants`
              }
            </h2>
            {searchQuery && (
              <Button 
                variant="ghost" 
                size="sm"
                onClick={() => setSearchQuery('')}
              >
                Clear
              </Button>
            )}
          </div>

          {/* No Results State */}
          {filteredRestaurants.length === 0 ? (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
            >
              <Card className="border-dashed">
                <CardContent className="flex flex-col items-center justify-center py-12 text-center space-y-4">
                  <div className="p-3 bg-warning/10 rounded-full">
                    <ChefHat className="w-6 h-6 text-warning" />
                  </div>
                  <div>
                    <h3 className="font-semibold mb-1">Restaurant Not Found</h3>
                    <p className="text-sm text-muted-foreground mb-4">
                      We don't have"{searchQuery ? ` ${searchQuery}` : ' that restaurant'}" in our system yet.
                    </p>
                    <p className="text-sm text-muted-foreground mb-6">
                      No worries! Let our call centre agent help you.
                    </p>
                  </div>

                  {/* Call Centre Integration - Prominent placement */}
                  <div className="w-full pt-2">
                    <TextCallCentre 
                      stationName={stationName}
                      onClose={() => setSearchQuery('')}
                    />
                  </div>

                  <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-900 text-left w-full">
                    <p className="text-xs font-medium text-blue-900 dark:text-blue-100 flex items-center gap-2 mb-2">
                      <AlertCircle className="w-3 h-3" />
                      How it works
                    </p>
                    <ul className="text-xs text-blue-800 dark:text-blue-200 space-y-1">
                      <li>✓ Tell us the restaurant you want</li>
                      <li>✓ List the food items you'd like</li>
                      <li>✓ Our agent calls you via WhatsApp</li>
                      <li>✓ They place the order for you</li>
                    </ul>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ) : (
            /* Restaurant Cards */
            <div className="space-y-3">
              {filteredRestaurants.map((restaurant) => (
                <motion.div
                  key={restaurant.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  whileHover={{ y: -2 }}
                >
                  <Card 
                    className={`cursor-pointer transition-all ${selectedRestaurant?.id === restaurant.id ? 'border-primary shadow-lg' : 'hover:shadow-md'}`}
                    onClick={() => setSelectedRestaurant(restaurant)}
                  >
                    <CardContent className="p-4">
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <h3 className="font-semibold">{restaurant.name}</h3>
                            {!restaurant.isOpen && (
                              <Badge variant="destructive" className="text-xs">Closed</Badge>
                            )}
                          </div>
                          <p className="text-xs text-muted-foreground">{restaurant.category}</p>
                        </div>
                        <Badge variant="outline">{restaurant.rating} ⭐</Badge>
                      </div>

                      <div className="flex items-center gap-4 text-sm text-muted-foreground">
                        <div className="flex items-center gap-1">
                          <Clock className="w-4 h-4" />
                          {restaurant.deliveryTime} min
                        </div>
                        <div className="flex items-center gap-1">
                          <MapPin className="w-4 h-4" />
                          {restaurant.distance} km
                        </div>
                      </div>

                      {selectedRestaurant?.id === restaurant.id && (
                        <motion.div
                          initial={{ opacity: 0 }}
                          animate={{ opacity: 1 }}
                          className="mt-4 pt-4 border-t space-y-2"
                        >
                          <Button className="w-full" disabled={!restaurant.isOpen}>
                            {restaurant.isOpen ? 'Order Now' : 'Closed'}
                          </Button>
                          {!restaurant.isOpen && (
                            <p className="text-xs text-muted-foreground text-center">
                              Or request it via call centre
                            </p>
                          )}
                        </motion.div>
                      )}
                    </CardContent>
                  </Card>
                </motion.div>
              ))}
            </div>
          )}
        </div>
      </main>
    </div>
  );
};

export default BookingPageExample;
