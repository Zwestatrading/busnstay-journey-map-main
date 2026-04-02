import { useState, useMemo } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Star, Clock, Plus, Minus, ShoppingBag, ArrowLeft } from 'lucide-react';
import { Restaurant, MenuItem, CartItem } from '@/types/order';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import { ScrollArea } from '@/components/ui/scroll-area';

interface MenuSheetProps {
  restaurant: Restaurant;
  stationName: string;
  isOpen: boolean;
  onClose: () => void;
  onBack: () => void;
  onPlaceOrder: (items: CartItem[], total: number) => void;
}

const MenuSheet = ({ 
  restaurant, 
  stationName,
  isOpen, 
  onClose, 
  onBack,
  onPlaceOrder 
}: MenuSheetProps) => {
  const [cart, setCart] = useState<Map<string, CartItem>>(new Map());

  const categories = useMemo(() => {
    const cats = new Set(restaurant.menu.map(item => item.category));
    return Array.from(cats);
  }, [restaurant.menu]);

  const cartTotal = useMemo(() => {
    let total = 0;
    cart.forEach(item => {
      total += item.menuItem.price * item.quantity;
    });
    return total;
  }, [cart]);

  const cartItemCount = useMemo(() => {
    let count = 0;
    cart.forEach(item => {
      count += item.quantity;
    });
    return count;
  }, [cart]);

  const addToCart = (menuItem: MenuItem) => {
    setCart(prev => {
      const newCart = new Map(prev);
      const existing = newCart.get(menuItem.id);
      if (existing) {
        newCart.set(menuItem.id, { ...existing, quantity: existing.quantity + 1 });
      } else {
        newCart.set(menuItem.id, { menuItem, quantity: 1 });
      }
      return newCart;
    });
  };

  const removeFromCart = (menuItemId: string) => {
    setCart(prev => {
      const newCart = new Map(prev);
      const existing = newCart.get(menuItemId);
      if (existing) {
        if (existing.quantity > 1) {
          newCart.set(menuItemId, { ...existing, quantity: existing.quantity - 1 });
        } else {
          newCart.delete(menuItemId);
        }
      }
      return newCart;
    });
  };

  const getItemQuantity = (menuItemId: string) => {
    return cart.get(menuItemId)?.quantity || 0;
  };

  const handlePlaceOrder = () => {
    const items = Array.from(cart.values());
    onPlaceOrder(items, cartTotal);
    setCart(new Map());
  };

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
            className="fixed bottom-0 left-0 right-0 z-[1002] bg-card rounded-t-3xl max-h-[85vh] flex flex-col"
          >
            {/* Handle */}
            <div className="flex justify-center pt-3 pb-2">
              <div className="w-12 h-1.5 rounded-full bg-muted" />
            </div>

            {/* Header */}
            <div className="px-4 pb-4 border-b border-border">
              <div className="flex items-center gap-3">
                <Button variant="ghost" size="icon" onClick={onBack}>
                  <ArrowLeft className="w-5 h-5" />
                </Button>
                <div className="flex-1">
                  <h2 className="font-display text-xl font-bold text-foreground">
                    {restaurant.name}
                  </h2>
                  <div className="flex items-center gap-3 text-sm text-muted-foreground">
                    <span className="flex items-center gap-1">
                      <Star className="w-3.5 h-3.5 fill-amber-500 text-amber-500" />
                      {restaurant.rating.toFixed(1)}
                    </span>
                    <span>•</span>
                    <span>{restaurant.cuisine}</span>
                    <span>•</span>
                    <span className="flex items-center gap-1">
                      <Clock className="w-3.5 h-3.5" />
                      {restaurant.eta} min
                    </span>
                  </div>
                </div>
                <Button variant="ghost" size="icon" onClick={onClose}>
                  <X className="w-5 h-5" />
                </Button>
              </div>
            </div>

            {/* Menu */}
            <ScrollArea className="flex-1 px-4 py-4">
              <div className="space-y-6 pb-24">
                {categories.map(category => (
                  <div key={category}>
                    <h3 className="font-display font-bold text-lg text-foreground mb-3">
                      {category}
                    </h3>
                    <div className="space-y-2">
                      {restaurant.menu
                        .filter(item => item.category === category)
                        .map((item, index) => {
                          const quantity = getItemQuantity(item.id);
                          return (
                            <motion.div
                              key={item.id}
                              initial={{ opacity: 0, y: 10 }}
                              animate={{ opacity: 1, y: 0 }}
                              transition={{ delay: index * 0.02 }}
                              className={cn(
                                "p-4 rounded-xl bg-muted/50 flex items-center gap-4",
                                quantity > 0 && "ring-2 ring-accent/50 bg-accent/5"
                              )}
                            >
                              <div className="flex-1 min-w-0">
                                <p className="font-semibold text-foreground">
                                  {item.name}
                                </p>
                                <p className="text-sm text-muted-foreground line-clamp-1">
                                  {item.description}
                                </p>
                                <p className="text-sm font-bold text-primary mt-1">
                                  K{item.price}
                                </p>
                              </div>

                              {/* Quantity Controls */}
                              <div className="flex items-center gap-2">
                                {quantity > 0 ? (
                                  <>
                                    <Button
                                      variant="outline"
                                      size="icon"
                                      className="h-8 w-8 rounded-full"
                                      onClick={() => removeFromCart(item.id)}
                                    >
                                      <Minus className="w-4 h-4" />
                                    </Button>
                                    <span className="w-6 text-center font-bold">
                                      {quantity}
                                    </span>
                                    <Button
                                      variant="outline"
                                      size="icon"
                                      className="h-8 w-8 rounded-full"
                                      onClick={() => addToCart(item)}
                                    >
                                      <Plus className="w-4 h-4" />
                                    </Button>
                                  </>
                                ) : (
                                  <Button
                                    variant="outline"
                                    size="icon"
                                    className="h-8 w-8 rounded-full"
                                    onClick={() => addToCart(item)}
                                  >
                                    <Plus className="w-4 h-4" />
                                  </Button>
                                )}
                              </div>
                            </motion.div>
                          );
                        })}
                    </div>
                  </div>
                ))}
              </div>
            </ScrollArea>

            {/* Cart Footer */}
            <AnimatePresence>
              {cartItemCount > 0 && (
                <motion.div
                  initial={{ y: 100 }}
                  animate={{ y: 0 }}
                  exit={{ y: 100 }}
                  className="absolute bottom-0 left-0 right-0 p-4 bg-card border-t border-border"
                >
                  <Button 
                    className="w-full h-14 text-lg font-bold"
                    onClick={handlePlaceOrder}
                  >
                    <ShoppingBag className="w-5 h-5 mr-2" />
                    Place Order • K{cartTotal}
                    <span className="ml-2 px-2 py-0.5 bg-white/20 rounded-full text-sm">
                      {cartItemCount} item{cartItemCount > 1 ? 's' : ''}
                    </span>
                  </Button>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

export default MenuSheet;
