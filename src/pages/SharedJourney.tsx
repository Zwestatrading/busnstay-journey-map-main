 import { useState, useEffect } from 'react';
 import { useParams } from 'react-router-dom';
 import { MapContainer, TileLayer, Marker, Polyline } from 'react-leaflet';
 import L from 'leaflet';
 import 'leaflet/dist/leaflet.css';
 import { motion } from 'framer-motion';
 import { Bus, Clock, MapPin, AlertTriangle, Eye } from 'lucide-react';
 import { useShareJourney } from '@/hooks/useShareJourney';
 import { format } from 'date-fns';
 
 const SharedJourney = () => {
   const { shareCode } = useParams<{ shareCode: string }>();
   const { getSharedJourney, isLoading, error } = useShareJourney();
   const [journeyData, setJourneyData] = useState<Awaited<ReturnType<typeof getSharedJourney>>>(null);
 
   useEffect(() => {
     if (shareCode) {
       getSharedJourney(shareCode).then(setJourneyData);
     }
   }, [shareCode, getSharedJourney]);
 
   // Refresh every 30 seconds
   useEffect(() => {
     if (!shareCode) return;
 
     const interval = setInterval(() => {
       getSharedJourney(shareCode).then(setJourneyData);
     }, 30000);
 
     return () => clearInterval(interval);
   }, [shareCode, getSharedJourney]);
 
   if (isLoading && !journeyData) {
     return (
       <div className="h-screen flex items-center justify-center bg-background">
         <div className="text-center">
           <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-primary/10 flex items-center justify-center animate-pulse">
             <Bus className="w-8 h-8 text-primary" />
           </div>
           <p className="text-muted-foreground">Loading journey...</p>
         </div>
       </div>
     );
   }
 
   if (error || !journeyData) {
     return (
       <div className="h-screen flex items-center justify-center bg-background">
         <div className="text-center max-w-md p-8">
           <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-destructive/10 flex items-center justify-center">
             <AlertTriangle className="w-8 h-8 text-destructive" />
           </div>
           <h1 className="text-xl font-display font-bold text-foreground mb-2">
             Journey Not Found
           </h1>
           <p className="text-muted-foreground">
             {error || 'This share link may be invalid or expired.'}
           </p>
         </div>
       </div>
     );
   }
 
   const { journey, bus, stops } = journeyData;
 
   // Parse bus position
   let busPosition: [number, number] | null = null;
   if (bus?.current_position?.coordinates) {
     busPosition = [bus.current_position.coordinates[1], bus.current_position.coordinates[0]];
   }
 
   // Generate stop coordinates for polyline
   const stopCoordinates: [number, number][] = [];
 
   // Create bus icon
   const busIcon = L.divIcon({
     className: 'bus-marker-shared',
     html: `
       <div class="relative">
         <div class="absolute -inset-3 rounded-full animate-ping bg-primary/30"></div>
         <div class="w-10 h-10 rounded-full bg-primary flex items-center justify-center shadow-lg">
           <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2">
             <path d="M4 16V6a4 4 0 0 1 4-4h8a4 4 0 0 1 4 4v10"/>
             <path d="M4 16v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2"/>
             <circle cx="7" cy="18" r="1.5" fill="white"/>
             <circle cx="17" cy="18" r="1.5" fill="white"/>
           </svg>
         </div>
       </div>
     `,
     iconSize: [40, 40],
     iconAnchor: [20, 20],
   });
 
   const formatTime = (isoString: string) => {
     try {
       return format(new Date(isoString), 'HH:mm');
     } catch {
       return '--:--';
     }
   };
 
   return (
     <div className="h-screen flex flex-col bg-background">
       {/* Header */}
       <div className="p-4 border-b border-border bg-card">
         <div className="flex items-center gap-3">
           <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
             <Eye className="w-5 h-5 text-primary-foreground" />
           </div>
           <div className="flex-1">
             <h1 className="font-display font-bold text-lg text-foreground">
               Shared Journey
             </h1>
             <p className="text-xs text-muted-foreground">
               Live tracking view • Updates every 30s
             </p>
           </div>
           <div className={`px-3 py-1 rounded-full text-xs font-medium ${
             journey.status === 'active' ? 'bg-journey-completed/20 text-journey-completed' :
             journey.status === 'delayed' ? 'bg-destructive/20 text-destructive' :
             'bg-muted text-muted-foreground'
           }`}>
             {journey.status === 'delayed' && journey.delay_minutes > 0 
               ? `Delayed ${journey.delay_minutes}m` 
               : journey.status.charAt(0).toUpperCase() + journey.status.slice(1)}
           </div>
         </div>
       </div>
 
       {/* Map */}
       <div className="flex-[2] relative">
         <MapContainer
           center={busPosition || [-15.3875, 28.3228]}
           zoom={busPosition ? 12 : 7}
           className="w-full h-full"
           zoomControl={false}
           attributionControl={false}
         >
           <TileLayer
             url="https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png"
           />
 
           {stopCoordinates.length > 1 && (
             <Polyline
               positions={stopCoordinates}
               pathOptions={{ color: 'hsl(var(--primary))', weight: 4, opacity: 0.6 }}
             />
           )}
 
           {busPosition && (
             <Marker position={busPosition} icon={busIcon} />
           )}
         </MapContainer>
 
         {/* Speed & Info overlay */}
         {bus && (
           <div className="absolute bottom-4 left-4 right-4 bg-card/95 backdrop-blur-sm rounded-xl p-4 shadow-lg">
             <div className="grid grid-cols-3 gap-4 text-center">
               <div>
                 <p className="text-2xl font-display font-bold text-foreground">
                   {Math.round(bus.speed || 0)}
                 </p>
                 <p className="text-xs text-muted-foreground">km/h</p>
               </div>
               <div>
                 <p className="text-2xl font-display font-bold text-foreground">
                   {Math.round(journey.progress)}%
                 </p>
                 <p className="text-xs text-muted-foreground">Progress</p>
               </div>
               <div>
                 <p className="text-2xl font-display font-bold text-foreground">
                   {journey.estimated_arrival ? formatTime(journey.estimated_arrival) : '--:--'}
                 </p>
                 <p className="text-xs text-muted-foreground">ETA</p>
               </div>
             </div>
 
             {/* Progress bar */}
             <div className="mt-3 h-1.5 bg-muted rounded-full overflow-hidden">
               <motion.div
                 initial={{ width: 0 }}
                 animate={{ width: `${journey.progress}%` }}
                 className="h-full bg-gradient-to-r from-journey-completed to-journey-active rounded-full"
               />
             </div>
           </div>
         )}
       </div>
 
       {/* Stops list */}
       {stops && stops.length > 0 && (
         <div className="flex-1 overflow-y-auto p-4 bg-card border-t border-border">
           <h2 className="font-display font-bold text-sm text-foreground mb-3">Journey Stops</h2>
           <div className="space-y-2">
             {stops.map((stop, index) => (
               <motion.div
                 key={stop.id}
                 initial={{ opacity: 0, x: -20 }}
                 animate={{ opacity: 1, x: 0 }}
                 transition={{ delay: index * 0.05 }}
                 className="flex items-center gap-3 p-2 rounded-lg bg-muted/50"
               >
                 <div className={`w-8 h-8 rounded-full flex items-center justify-center ${
                   stop.is_delayed ? 'bg-destructive/20' : 'bg-primary/20'
                 }`}>
                   <MapPin className={`w-4 h-4 ${stop.is_delayed ? 'text-destructive' : 'text-primary'}`} />
                 </div>
                 <div className="flex-1">
                   <p className="font-medium text-sm text-foreground">{stop.name}</p>
                   <div className="flex items-center gap-1">
                     <Clock className="w-3 h-3 text-muted-foreground" />
                     <span className="text-xs text-muted-foreground">
                       ETA: {formatTime(stop.eta)}
                     </span>
                     {stop.is_delayed && (
                       <span className="text-xs text-destructive ml-2">Delayed</span>
                     )}
                   </div>
                 </div>
               </motion.div>
             ))}
           </div>
         </div>
       )}
     </div>
   );
 };
 
 export default SharedJourney;