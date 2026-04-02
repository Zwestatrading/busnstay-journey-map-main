import { useEffect, useRef } from 'react';
import L from 'leaflet';
import { useMap } from 'react-leaflet';

interface RoutePolylineProps {
  coordinates: [number, number][];
  completedIndex: number; // Index up to which the route is completed
}

const RoutePolyline = ({ coordinates, completedIndex }: RoutePolylineProps) => {
  const map = useMap();
  const completedLineRef = useRef<L.Polyline | null>(null);
  const upcomingLineRef = useRef<L.Polyline | null>(null);
  const glowLineRef = useRef<L.Polyline | null>(null);

  useEffect(() => {
    // Calculate split point
    const splitPoint = Math.floor(coordinates.length * (completedIndex / 100));
    const completedCoords = coordinates.slice(0, splitPoint + 1);
    const upcomingCoords = coordinates.slice(splitPoint);

    // Remove existing polylines
    if (completedLineRef.current) completedLineRef.current.remove();
    if (upcomingLineRef.current) upcomingLineRef.current.remove();
    if (glowLineRef.current) glowLineRef.current.remove();

    // Glow effect for completed route
    glowLineRef.current = L.polyline(completedCoords, {
      color: 'hsla(152, 60%, 42%, 0.3)',
      weight: 12,
      lineCap: 'round',
      lineJoin: 'round',
    }).addTo(map);

    // Completed route (green)
    completedLineRef.current = L.polyline(completedCoords, {
      color: 'hsl(152, 60%, 42%)',
      weight: 5,
      lineCap: 'round',
      lineJoin: 'round',
    }).addTo(map);

    // Upcoming route (dashed, navy with amber accent)
    upcomingLineRef.current = L.polyline(upcomingCoords, {
      color: 'hsl(228, 60%, 18%)',
      weight: 4,
      lineCap: 'round',
      lineJoin: 'round',
      dashArray: '12, 8',
      opacity: 0.7,
    }).addTo(map);

    return () => {
      if (completedLineRef.current) completedLineRef.current.remove();
      if (upcomingLineRef.current) upcomingLineRef.current.remove();
      if (glowLineRef.current) glowLineRef.current.remove();
    };
  }, [map, coordinates, completedIndex]);

  return null;
};

export default RoutePolyline;
