import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Utensils, 
  Hotel, 
  Bike, 
  Car,
  ChevronUp,
  Star,
  Clock,
  ShoppingBag,
  X
} from 'lucide-react';
import { Town, Service } from '@/types/journey';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';

interface ServicePanelProps {
  activeTown: Town | null;
  nextTown: Town | null;
  services: Service[];
  onPreOrder: (service: Service) => void;
}

const serviceConfig = {
  restaurant: { icon: Utensils, label: 'Food', colorClass: 'service-restaurant' },
  hotel: { icon: Hotel, label: 'Stay', colorClass: 'service-hotel' },
  rider: { icon: Bike, label: 'Rider', colorClass: 'service-rider' },
  taxi: { icon: Car, label: 'Taxi', colorClass: 'service-taxi' },
};

const ServicePanel = ({ activeTown, nextTown, services, onPreOrder }: ServicePanelProps) => {
  const [isExpanded, setIsExpanded] = useState(true);
  const [activeFilter, setActiveFilter] = useState<Service['type'] | 'all'>('all');
  const [selectedTown, setSelectedTown] = useState<'current' | 'next'>('current');

  const currentTown = selectedTown === 'current' ? activeTown : nextTown;
  
  const filteredServices = services.filter(s => {
    const townMatch = s.townId === currentTown?.id;
    const typeMatch = activeFilter === 'all' || s.type === activeFilter;
    return townMatch && typeMatch;
  });

  if (!activeTown) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 50 }}
      animate={{ opacity: 1, y: 0 }}
      className="absolute bottom-0 left-0 right-0 z-[1000]"
    >
      <div className="glass-card rounded-t-3xl overflow-hidden shadow-2xl">
        {/* Drag Handle */}
        <button 
          onClick={() => setIsExpanded(!isExpanded)}
          className="w-full py-3 flex justify-center"
        >
          <motion.div
            animate={{ rotate: isExpanded ? 180 : 0 }}
            className="w-10 h-1 bg-muted-foreground/30 rounded-full"
          />
        </button>

        <AnimatePresence>
          {isExpanded && (
            <motion.div
              initial={{ height: 0 }}
              animate={{ height: 'auto' }}
              exit={{ height: 0 }}
              className="overflow-hidden"
            >
              {/* Header */}
              <div className="px-4 pb-3">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h2 className="font-display text-lg font-bold text-foreground">
                      Services Available
                    </h2>
                    <p className="text-sm text-muted-foreground">
                      Pre-order for your journey
                    </p>
                  </div>
                  
                  {/* Town Toggle */}
                  <div className="flex bg-muted rounded-xl p-1">
                    <button
                      onClick={() => setSelectedTown('current')}
                      className={cn(
                        "px-3 py-1.5 rounded-lg text-sm font-medium transition-all",
                        selectedTown === 'current' 
                          ? "bg-accent text-accent-foreground shadow-sm" 
                          : "text-muted-foreground hover:text-foreground"
                      )}
                    >
                      {activeTown?.name}
                    </button>
                    {nextTown && (
                      <button
                        onClick={() => setSelectedTown('next')}
                        className={cn(
                          "px-3 py-1.5 rounded-lg text-sm font-medium transition-all",
                          selectedTown === 'next' 
                            ? "bg-primary text-primary-foreground shadow-sm" 
                            : "text-muted-foreground hover:text-foreground"
                        )}
                      >
                        {nextTown.name}
                      </button>
                    )}
                  </div>
                </div>

                {/* Service Type Filters */}
                <div className="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4">
                  <button
                    onClick={() => setActiveFilter('all')}
                    className={cn(
                      "px-4 py-2 rounded-xl text-sm font-medium transition-all whitespace-nowrap",
                      activeFilter === 'all'
                        ? "bg-primary text-primary-foreground"
                        : "bg-muted text-muted-foreground hover:bg-muted/80"
                    )}
                  >
                    All
                  </button>
                  {(Object.keys(serviceConfig) as Service['type'][]).map((type) => {
                    const config = serviceConfig[type];
                    const Icon = config.icon;
                    return (
                      <button
                        key={type}
                        onClick={() => setActiveFilter(type)}
                        className={cn(
                          "flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-medium transition-all whitespace-nowrap",
                          activeFilter === type
                            ? `${config.colorClass} text-white`
                            : "bg-muted text-muted-foreground hover:bg-muted/80"
                        )}
                      >
                        <Icon className="w-4 h-4" />
                        {config.label}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Services List */}
              <div className="px-4 pb-6 max-h-[250px] overflow-y-auto">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  {filteredServices.map((service, index) => {
                    const config = serviceConfig[service.type];
                    const Icon = config.icon;
                    
                    return (
                      <motion.div
                        key={service.id}
                        initial={{ opacity: 0, y: 10 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: index * 0.05 }}
                        className="bg-card rounded-xl p-4 border border-border hover:border-accent/50 transition-all hover:shadow-lg"
                      >
                        <div className="flex items-start gap-3">
                          <div className={cn("service-icon flex-shrink-0", config.colorClass)}>
                            <Icon className="w-5 h-5 text-white" />
                          </div>
                          <div className="flex-1 min-w-0">
                            <h3 className="font-semibold text-foreground truncate">
                              {service.name}
                            </h3>
                            <div className="flex items-center gap-3 mt-1 text-sm text-muted-foreground">
                              <div className="flex items-center gap-1">
                                <Star className="w-3 h-3 text-accent fill-accent" />
                                <span>{service.rating}</span>
                              </div>
                              <div className="flex items-center gap-1">
                                <Clock className="w-3 h-3" />
                                <span>{service.eta} min</span>
                              </div>
                              {service.price && (
                                <span className="font-semibold text-accent">
                                  ${service.price}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>
                        
                        <Button
                          onClick={() => onPreOrder(service)}
                          variant="outline"
                          size="sm"
                          className="w-full mt-3 border-accent text-accent hover:bg-accent hover:text-accent-foreground"
                        >
                          <ShoppingBag className="w-4 h-4 mr-2" />
                          {selectedTown === 'next' ? 'Pre-Order' : 'Order Now'}
                        </Button>
                      </motion.div>
                    );
                  })}
                </div>

                {filteredServices.length === 0 && (
                  <div className="text-center py-8 text-muted-foreground">
                    <p>No services available for this category</p>
                  </div>
                )}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>
    </motion.div>
  );
};

export default ServicePanel;
