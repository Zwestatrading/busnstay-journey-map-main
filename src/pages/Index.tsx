import { useState } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import LandingPageEnhanced from '@/components/LandingPageEnhanced';
import RoutePreview from '@/components/RoutePreview';
import JourneyView from '@/components/JourneyView';
import { RouteDefinition } from '@/data/zambiaRoutes';

type ViewState = 'landing' | 'preview' | 'journey';

const Index = () => {
  const [view, setView] = useState<ViewState>('landing');
  const [activeRoute, setActiveRoute] = useState<RouteDefinition | null>(null);

  const handleRouteSelect = (route: RouteDefinition) => {
    setActiveRoute(route);
    setView('preview');
  };

  const handleStartJourney = () => {
    setView('journey');
  };

  const handleBackToLanding = () => {
    setActiveRoute(null);
    setView('landing');
  };

  const handleBackToPreview = () => {
    setView('preview');
  };

  return (
    <main className="w-full h-screen bg-background">
      <AnimatePresence mode="wait">
        {view === 'landing' && (
          <motion.div
            key="landing"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="h-full"
          >
            <LandingPageEnhanced onRouteSelect={handleRouteSelect} />
          </motion.div>
        )}
        
        {view === 'preview' && activeRoute && (
          <motion.div
            key="preview"
            initial={{ opacity: 0, x: 50 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -50 }}
            className="h-full"
          >
            <RoutePreview 
              route={activeRoute} 
              onStartJourney={handleStartJourney}
              onBack={handleBackToLanding}
            />
          </motion.div>
        )}
        
        {view === 'journey' && activeRoute && (
          <motion.div
            key="journey"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="h-full"
          >
            <JourneyView route={activeRoute} onBack={handleBackToPreview} />
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
};

export default Index;
