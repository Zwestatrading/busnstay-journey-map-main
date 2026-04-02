import { useEffect, useRef } from 'react';
import L from 'leaflet';
import { useMap } from 'react-leaflet';

interface BusMarkerProps {
  position: [number, number];
  heading?: number;
}

const BusMarker = ({ position, heading = 0 }: BusMarkerProps) => {
  const map = useMap();
  const markerRef = useRef<L.Marker | null>(null);

  useEffect(() => {
    const busIcon = L.divIcon({
      className: 'bus-marker-container',
      html: `
        <div class="relative">
          <div class="absolute -inset-4 rounded-full animate-ping" style="background: hsla(32, 95%, 52%, 0.3);"></div>
          <div class="absolute -inset-2 rounded-full animate-pulse" style="background: hsla(32, 95%, 52%, 0.2);"></div>
          <div class="relative w-12 h-12 rounded-full flex items-center justify-center shadow-2xl transform" 
               style="background: linear-gradient(135deg, hsl(228, 60%, 18%) 0%, hsl(228, 50%, 28%) 100%); 
                      box-shadow: 0 0 20px hsla(32, 95%, 52%, 0.5), 0 4px 15px rgba(0,0,0,0.3);
                      transform: rotate(${heading}deg);">
            <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M4 16V6a4 4 0 0 1 4-4h8a4 4 0 0 1 4 4v10" stroke="white" stroke-width="2" stroke-linecap="round"/>
              <path d="M4 16v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" stroke="white" stroke-width="2"/>
              <circle cx="7" cy="18" r="1.5" fill="#F59E0B"/>
              <circle cx="17" cy="18" r="1.5" fill="#F59E0B"/>
              <path d="M6 6h12v6H6z" stroke="white" stroke-width="1.5" fill="rgba(255,255,255,0.1)"/>
              <path d="M10 2v4M14 2v4" stroke="white" stroke-width="1.5"/>
            </svg>
          </div>
          <div class="absolute -bottom-1 left-1/2 transform -translate-x-1/2 w-8 h-2 rounded-full" 
               style="background: radial-gradient(ellipse, rgba(0,0,0,0.3) 0%, transparent 70%);"></div>
        </div>
      `,
      iconSize: [48, 48],
      iconAnchor: [24, 24],
    });

    if (markerRef.current) {
      markerRef.current.setLatLng(position);
    } else {
      markerRef.current = L.marker(position, { icon: busIcon, zIndexOffset: 1000 }).addTo(map);
    }

    return () => {
      if (markerRef.current) {
        markerRef.current.remove();
        markerRef.current = null;
      }
    };
  }, [map, position, heading]);

  return null;
};

export default BusMarker;
