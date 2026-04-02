import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';

/**
 * Custom hook to handle back navigation with:
 * - Hardware back button (Android)
 * - Swipe gesture detection (right swipe = back)
 * - Works in demo mode
 */
export const useBackNavigation = (fallbackPath = '/') => {
  const navigate = useNavigate();
  const touchStartRef = useRef<{ x: number; y: number; time: number } | null>(null);

  useEffect(() => {
    // Handle Android hardware back button via Capacitor
    const setupCapacitorBackButton = async () => {
      try {
        if ((window as any)?.capacitorPlugins?.App) {
          const listener = (window as any).capacitorPlugins.App.addListener('backButton', () => {
            navigate(fallbackPath);
          });
          return () => listener.remove?.();
        }
      } catch (error) {
        console.debug('Capacitor back button not available');
      }
      return () => {};
    };

    let removeCapacitorListener: (() => void) | null = null;
    setupCapacitorBackButton().then(remove => {
      removeCapacitorListener = remove;
    });

    // Handle swipe gesture detection - right swipe to go back
    const handleTouchStart = (e: TouchEvent) => {
      const touch = e.touches[0];
      if (touch) {
        touchStartRef.current = {
          x: touch.clientX,
          y: touch.clientY,
          time: Date.now(),
        };
      }
    };

    const handleTouchEnd = (e: TouchEvent) => {
      if (!touchStartRef.current) return;

      const touch = e.changedTouches[0];
      if (!touch) return;

      const deltaX = touch.clientX - touchStartRef.current.x;
      const deltaY = Math.abs(touch.clientY - touchStartRef.current.y);
      const deltaTime = Date.now() - touchStartRef.current.time;

      // Swipe criteria:
      // - Moved right (deltaX > 50px minimum)
      // - Minimal vertical movement (deltaY < 50px)
      // - Quick swipe (< 500ms)
      const minHorizontalDistance = 50;
      const maxVerticalDistance = 50;
      const maxSwipeTime = 500;

      if (
        deltaX > minHorizontalDistance &&
        deltaY < maxVerticalDistance &&
        deltaTime < maxSwipeTime
      ) {
        // Swipe right detected - go back
        console.debug(`Swipe detected: deltaX=${deltaX}, deltaY=${deltaY}, time=${deltaTime}ms`);
        navigate(fallbackPath);
      }

      touchStartRef.current = null;
    };

    // Use passive listeners for better performance
    document.addEventListener('touchstart', handleTouchStart, { passive: true });
    document.addEventListener('touchend', handleTouchEnd, { passive: true });

    return () => {
      document.removeEventListener('touchstart', handleTouchStart);
      document.removeEventListener('touchend', handleTouchEnd);
      removeCapacitorListener?.();
    };
  }, [navigate, fallbackPath]);
};
