import { useEffect, useRef } from 'react';
import L from 'leaflet';
import { useMap } from 'react-leaflet';
import { Town, TownSize, TownStatus } from '@/types/journey';

interface TownMarkerProps {
  town: Town;
  onClick?: (town: Town) => void;
}

const getSizeConfig = (size: TownSize) => {
  switch (size) {
    case 'major':
      return { width: 28, height: 28, fontSize: 12, labelOffset: 20 };
    case 'medium':
      return { width: 20, height: 20, fontSize: 10, labelOffset: 16 };
    case 'minor':
      return { width: 14, height: 14, fontSize: 9, labelOffset: 12 };
  }
};

const getStatusColors = (status: TownStatus) => {
  switch (status) {
    case 'completed':
      return { bg: 'hsl(152, 60%, 42%)', glow: 'hsla(152, 60%, 42%, 0.4)', border: 'hsl(152, 60%, 35%)' };
    case 'active':
      return { bg: 'hsl(32, 95%, 52%)', glow: 'hsla(32, 95%, 52%, 0.5)', border: 'hsl(32, 95%, 45%)' };
    case 'upcoming':
      return { bg: 'hsl(220, 25%, 75%)', glow: 'hsla(220, 25%, 75%, 0.3)', border: 'hsl(220, 25%, 65%)' };
  }
};

const TownMarker = ({ town, onClick }: TownMarkerProps) => {
  const map = useMap();
  const markerRef = useRef<L.Marker | null>(null);

  useEffect(() => {
    const sizeConfig = getSizeConfig(town.size);
    const colors = getStatusColors(town.status);
    
    const isActive = town.status === 'active';
    const pulseHtml = isActive ? `
      <div class="absolute inset-0 rounded-full animate-ping" 
           style="background: ${colors.glow}; animation-duration: 1.5s;"></div>
    ` : '';

    const icon = L.divIcon({
      className: 'town-marker-container',
      html: `
        <div class="relative flex flex-col items-center" style="width: ${sizeConfig.width + 40}px;">
          <div class="relative">
            ${pulseHtml}
            <div class="rounded-full shadow-lg transition-transform hover:scale-110 cursor-pointer flex items-center justify-center"
                 style="width: ${sizeConfig.width}px; 
                        height: ${sizeConfig.height}px; 
                        background: ${colors.bg};
                        box-shadow: 0 0 ${isActive ? 20 : 10}px ${colors.glow}, 0 2px 8px rgba(0,0,0,0.2);
                        border: 2px solid ${colors.border};">
              ${town.status === 'completed' ? `
                <svg width="${sizeConfig.width * 0.5}" height="${sizeConfig.height * 0.5}" viewBox="0 0 24 24" fill="none">
                  <path d="M5 12l5 5L20 7" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              ` : ''}
            </div>
          </div>
          <div class="mt-1 px-2 py-0.5 rounded-md text-center whitespace-nowrap font-semibold"
               style="font-size: ${sizeConfig.fontSize}px; 
                      background: rgba(255,255,255,0.95);
                      color: hsl(228, 40%, 12%);
                      box-shadow: 0 1px 4px rgba(0,0,0,0.15);
                      backdrop-filter: blur(4px);">
            ${town.name}
          </div>
        </div>
      `,
      iconSize: [sizeConfig.width + 40, sizeConfig.height + 30],
      iconAnchor: [(sizeConfig.width + 40) / 2, sizeConfig.height / 2],
    });

    if (markerRef.current) {
      markerRef.current.setIcon(icon);
    } else {
      markerRef.current = L.marker(town.coordinates, { icon, zIndexOffset: town.size === 'major' ? 500 : town.size === 'medium' ? 300 : 100 }).addTo(map);
      
      if (onClick) {
        markerRef.current.on('click', () => onClick(town));
      }
    }

    return () => {
      if (markerRef.current) {
        markerRef.current.remove();
        markerRef.current = null;
      }
    };
  }, [map, town, onClick]);

  return null;
};

export default TownMarker;
