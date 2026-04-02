import { motion, AnimatePresence } from 'framer-motion';
import { Clock, MapPin, CheckCircle, Loader2, X, ChefHat, Package } from 'lucide-react';
import { PendingOrder, OrderStatus } from '@/types/order';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';

interface PendingOrderCardProps {
  order: PendingOrder;
  onDismiss: (orderId: string) => void;
  onPickup: (orderId: string) => void;
}

const statusConfig: Record<OrderStatus, { icon: typeof Clock; label: string; color: string }> = {
  pending: { icon: Clock, label: 'Order Placed', color: 'text-amber-500' },
  preparing: { icon: ChefHat, label: 'Preparing', color: 'text-journey-active' },
  ready: { icon: Package, label: 'Ready for Pickup', color: 'text-journey-completed' },
  completed: { icon: CheckCircle, label: 'Completed', color: 'text-muted-foreground' },
};

const PendingOrderCard = ({ order, onDismiss, onPickup }: PendingOrderCardProps) => {
  const { icon: StatusIcon, label, color } = statusConfig[order.status];
  const itemCount = order.items.reduce((sum, item) => sum + item.quantity, 0);

  return (
    <motion.div
      initial={{ opacity: 0, y: -50, scale: 0.9 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      exit={{ opacity: 0, y: -50, scale: 0.9 }}
      className="bg-card border border-border rounded-2xl shadow-lg overflow-hidden"
    >
      <div className="p-4">
        <div className="flex items-start justify-between gap-3">
          <div className="flex items-center gap-3 flex-1 min-w-0">
            {/* Status Icon */}
            <div className={cn(
              "w-12 h-12 rounded-xl flex items-center justify-center shrink-0",
              order.status === 'ready' ? "bg-journey-completed" : 
              order.status === 'preparing' ? "bg-journey-active" : "bg-warning"
            )}>
              {order.status === 'preparing' ? (
                <Loader2 className="w-5 h-5 text-journey-active-foreground animate-spin" />
              ) : (
                <StatusIcon className="w-5 h-5 text-journey-completed-foreground" />
              )}
            </div>

            {/* Order Details */}
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-2">
                <span className="font-display font-bold text-foreground truncate">
                  {order.restaurantName}
                </span>
                <span className={cn("text-xs font-medium px-2 py-0.5 rounded-full", 
                  order.status === 'ready' ? "bg-journey-completed/20 text-journey-completed" :
                  order.status === 'preparing' ? "bg-journey-active/20 text-journey-active" :
                  "bg-warning/20 text-warning"
                )}>
                  {label}
                </span>
              </div>
              <div className="flex items-center gap-2 text-sm text-muted-foreground mt-0.5">
                <MapPin className="w-3 h-3" />
                <span className="truncate">{order.stationName}</span>
                <span>•</span>
                <span>{itemCount} item{itemCount > 1 ? 's' : ''}</span>
                <span>•</span>
                <span className="font-medium text-foreground">K{order.totalPrice}</span>
              </div>
            </div>
          </div>

          {/* Actions */}
          <div className="flex items-center gap-2 shrink-0">
            {order.status === 'ready' && (
              <Button 
                size="sm" 
                onClick={() => onPickup(order.id)}
                className="bg-journey-completed hover:bg-journey-completed/90"
              >
                Picked Up
              </Button>
            )}
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8"
              onClick={() => onDismiss(order.id)}
            >
              <X className="w-4 h-4" />
            </Button>
          </div>
        </div>

        {/* Progress Indicator */}
        <div className="mt-3 flex items-center gap-1">
          {(['pending', 'preparing', 'ready'] as OrderStatus[]).map((step, index) => {
            const stepIndex = ['pending', 'preparing', 'ready'].indexOf(order.status);
            const isCompleted = index <= stepIndex;
            const isCurrent = index === stepIndex;
            
            return (
              <div key={step} className="flex-1 flex items-center gap-1">
                <div className={cn(
                  "h-1.5 flex-1 rounded-full transition-colors",
                  isCompleted ? "bg-journey-completed" : "bg-muted"
                )} />
              </div>
            );
          })}
        </div>
      </div>
    </motion.div>
  );
};

interface PendingOrdersContainerProps {
  orders: PendingOrder[];
  onDismiss: (orderId: string) => void;
  onPickup: (orderId: string) => void;
}

export const PendingOrdersContainer = ({ orders, onDismiss, onPickup }: PendingOrdersContainerProps) => {
  const activeOrders = orders.filter(o => o.status !== 'completed');

  if (activeOrders.length === 0) return null;

  return (
    <div className="absolute top-4 left-4 right-4 z-[1000] space-y-2">
      <AnimatePresence mode="popLayout">
        {activeOrders.map(order => (
          <PendingOrderCard
            key={order.id}
            order={order}
            onDismiss={onDismiss}
            onPickup={onPickup}
          />
        ))}
      </AnimatePresence>
    </div>
  );
};

export default PendingOrderCard;
