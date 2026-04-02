import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";

// Suppress non-critical development-only errors from Supabase/browser APIs
// These are safe to ignore and don't affect functionality
window.addEventListener('unhandledrejection', (event) => {
  const reason = event.reason;
  const message = typeof reason === 'object' && reason !== null && 'message' in reason 
    ? String((reason as {message?: unknown}).message).toLowerCase()
    : String(reason).toLowerCase();
  
  // Only suppress known harmless errors
  if (
    reason?.name === 'AbortError' || 
    message.includes('signal is aborted') ||
    message.includes('timeout') ||
    message.includes('navigator lock') ||
    message.includes('operation was aborted')
  ) {
    event.preventDefault();
  }
});

// Suppress non-critical console warnings in development
const originalWarn = console.warn;
console.warn = function(...args: any[]) {
  const message = args.join(' ');
  // Suppress Supabase's GoTrueClient multiple instances warning in development
  // (happens due to React StrictMode double-mounting, not a real issue)
  if (message.includes('Multiple GoTrueClient instances')) {
    return;
  }
  originalWarn.apply(console, args);
};

createRoot(document.getElementById("root")!).render(<App />);
// Register Service Worker for PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/sw.js')
      .then((registration) => {
        console.log('Service Worker registered successfully:', registration);
      })
      .catch((error) => {
        console.log('Service Worker registration failed:', error);
      });
  });
}