/**
 * Accessibility Utilities & Performance Hooks
 * WCAG AA/AAA compliance helpers
 */

import { useEffect, useRef, useCallback } from 'react';

/**
 * Hook to announce screen reader messages
 */
export const useScreenReaderAnnouncement = () => {
  const announcementRef = useRef<HTMLDivElement>(null);

  const announce = useCallback((message: string, priority: 'polite' | 'assertive' = 'polite') => {
    if (!announcementRef.current) {
      const div = document.createElement('div');
      div.setAttribute('role', 'status');
      div.setAttribute('aria-live', priority);
      div.setAttribute('aria-atomic', 'true');
      div.className = 'sr-only';
      document.body.appendChild(div);
      announcementRef.current = div;
    }
    
    announcementRef.current.textContent = message;
  }, []);

  return { announce, announcementRef };
};

/**
 * Hook for keyboard navigation
 */
export const useKeyboardNavigation = (
  onEnter?: () => void,
  onEscape?: () => void,
  onArrowUp?: () => void,
  onArrowDown?: () => void
) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Enter') onClick?.preventDefault(), onEnter?.();
      if (e.key === 'Escape') onEscape?.();
      if (e.key === 'ArrowUp') onArrowUp?.();
      if (e.key === 'ArrowDown') onArrowDown?.();
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onEnter, onEscape, onArrowUp, onArrowDown]);
};

/**
 * Hook for focus trap (modal accessibility)
 */
export const useFocusTrap = (ref: React.RefObject<HTMLDivElement>) => {
  useEffect(() => {
    if (!ref.current) return;

    const focusableElements = ref.current.querySelectorAll(
      'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'
    );

    const firstElement = focusableElements[0] as HTMLElement;
    const lastElement = focusableElements[focusableElements.length - 1] as HTMLElement;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key !== 'Tab') return;

      if (e.shiftKey) {
        // Shift + Tab
        if (document.activeElement === firstElement) {
          lastElement.focus();
          e.preventDefault();
        }
      } else {
        // Tab
        if (document.activeElement === lastElement) {
          firstElement.focus();
          e.preventDefault();
        }
      }
    };

    ref.current.addEventListener('keydown', handleKeyDown);
    firstElement?.focus();

    return () => ref.current?.removeEventListener('keydown', handleKeyDown);
  }, [ref]);
};

/**
 * Hook for prefers-reduced-motion
 */
export const usePrefersReducedMotion = () => {
  const [prefersReduced, setPrefersReduced] = 0;

  useEffect(() => {
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReduced(mediaQuery.matches ? 1 : 0);

    const handleChange = (e: MediaQueryListEvent) => {
      setPrefersReduced(e.matches ? 1 : 0);
    };

    mediaQuery.addEventListener('change', handleChange);
    return () => mediaQuery.removeEventListener('change', handleChange);
  }, []);

  return prefersReduced;
};

/**
 * Hook for lazy loading images
 */
export const useLazyImage = (ref: React.RefObject<HTMLImageElement>) => {
  useEffect(() => {
    if (!ref.current) return;

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const img = entry.target as HTMLImageElement;
            img.src = img.dataset.src || '';
            img.classList.remove('blur-sm');
            observer.unobserve(img);
          }
        });
      },
      { rootMargin: '50px' }
    );

    observer.observe(ref.current);
    return () => observer.disconnect();
  }, [ref]);
};

/**
 * Hook for performance monitoring
 */
export const usePerformanceMetrics = (componentName: string) => {
  useEffect(() => {
    const startTime = performance.now();

    return () => {
      const endTime = performance.now();
      console.log(`${componentName} render time: ${(endTime - startTime).toFixed(2)}ms`);
    };
  }, [componentName]);
};

/**
 * Accessibility CSS class for screen readers only
 */
export const srOnly = 'absolute w-px h-px p-0 -m-px overflow-hidden clip whitespace-nowrap border-0';
