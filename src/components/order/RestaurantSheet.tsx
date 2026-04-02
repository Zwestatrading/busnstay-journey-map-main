import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Star, Clock, ChevronRight, Utensils } from 'lucide-react';
import { Town } from '@/types/journey';
import { Restaurant } from '@/types/order';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';

interface RestaurantSheetProps {
  town: Town;
  restaurants: Restaurant[];
  isOpen: boolean;
  onClose: () => void;
  onSelectRestaurant: (restaurant: Restaurant) => void;
}

const RestaurantSheet = ({ 
  town, 
  restaurants, 
  isOpen, 
  onClose, 
  onSelectRestaurant 
}: RestaurantSheetProps) => {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/40 z-[1001]"
          />

          {/* Sheet */}
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', damping: 25, stiffness: 300 }}
            className="fixed bottom-0 left-0 right-0 z-[1002] bg-card rounded-t-3xl max-h-[70vh] flex flex-col"
          >
            {/* Handle */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-12 h-1.5 rounded-full bg-muted" />
            </div>

            {/* Header */}
            <div className="px-4 pb-4 border-b border-border flex items-center justify-between">
              <div>
                <h2 className="font-display text-xl font-bold text-foreground">
                  Restaurants at {town.name}
                </h2>
                <p className="text-sm text-muted-foreground">
                  {restaurants.length} places available
                </p>
              </div>
              <Button variant="ghost" size="icon" onClick={onClose}>
                <X className="w-5 h-5" />
              </Button>
            </div>

            {/* Restaurant List */}
            <ScrollArea className="flex-1 px-4 py-4">
              <div className="space-y-3">
                {restaurants.map((restaurant, index) => (
                  <motion.button
                    key={restaurant.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                    onClick={() => onSelectRestaurant(restaurant)}
                    className="w-full p-4 rounded-2xl bg-muted/50 hover:bg-muted transition-colors text-left flex items-center gap-4 group"
                  >
                    {/* Icon */}
                    <div className="w-14 h-14 rounded-xl bg-service-restaurant flex items-center justify-center shrink-0">
                      <Utensils className="w-6 h-6 text-white" />
                    </div>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="font-display font-bold text-foreground truncate">
                          {restaurant.name}
                        </span>
                        <span className="text-xs px-2 py-0.5 bg-muted rounded-full text-muted-foreground">
                          {restaurant.priceRange}
                        </span>
                      </div>
                      <p className="text-sm text-muted-foreground mt-0.5">
                        {restaurant.cuisine}
                      </p>
                      <div className="flex items-center gap-3 mt-1 text-sm">
                        <span className="flex items-center gap-1 text-amber-500">
                          <Star className="w-3.5 h-3.5 fill-amber-500" />
                          {restaurant.rating.toFixed(1)}
                        </span>
                        <span className="flex items-center gap-1 text-muted-foreground">
                          <Clock className="w-3.5 h-3.5" />
                          {restaurant.eta} min
                        </span>
                      </div>
                    </div>

                    {/* Arrow */}
                    <ChevronRight className="w-5 h-5 text-muted-foreground group-hover:text-foreground transition-colors" />
                  </motion.button>
                ))}
              </div>
            </ScrollArea>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

export default RestaurantSheet;
