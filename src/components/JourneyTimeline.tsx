import React, { useState, Suspense } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { MapPin, UtensilsCrossed, AlertCircle, MessageCircle, ChevronDown, MapPinCheck } from 'lucide-react';
import TextCallCentre from './TextCallCentre';

interface Station {
  id: string;
  name: string;
  hasRestaurants: boolean;
  restaurantCount?: number;
  eta?: string;
  distance?: number;
  isCompleted?: boolean;
  isCurrent?: boolean;
}

interface JourneyTimelineProps {
  stations: Station[];
  currentStationIndex: number;
  onRestaurantSelect?: (stationId: string, restaurantId: string) => void;
  activeStation?: Station | null;
}

const JourneyTimeline: React.FC<JourneyTimelineProps> = ({
  stations,
  currentStationIndex,
  onRestaurantSelect,
  activeStation,
}) => {
  const [expandedStation, setExpandedStation] = useState<string | null>(
    activeStation?.id || null
  );

  return (
    <Card className="bg-slate-800/50 border-slate-700 w-full">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <MapPin className="w-5 h-5" />
          Journey Timeline
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Timeline */}
          <div className="relative pl-8 space-y-6">
            {stations.map((station, index) => {
              const isCompleted = station.isCompleted;
              const isCurrent = station.isCurrent;
              const isUpcoming = !isCompleted && !isCurrent;
              const isExpanded = expandedStation === station.id;

              return (
                <div key={station.id} className="relative">
                  {/* Timeline Line */}
                  {index < stations.length - 1 && (
                    <div
                      className={`absolute left-0 top-8 w-1 h-12 ${
                        isCompleted || isCurrent
                          ? 'bg-emerald-500'
                          : 'bg-slate-600'
                      }`}
                    />
                  )}

                  {/* Timeline Dot */}
                  <div
                    className={`absolute -left-8 top-1.5 w-6 h-6 rounded-full border-2 flex items-center justify-center ${
                      isCompleted
                        ? 'bg-emerald-500 border-emerald-600'
                        : isCurrent
                        ? 'bg-blue-500 border-blue-600'
                        : 'bg-slate-700 border-slate-600'
                    }`}
                  >
                    {isCompleted && (
                      <MapPinCheck className="w-3 h-3 text-white" />
                    )}
                    {isCurrent && (
                      <div className="w-2 h-2 bg-white rounded-full animate-pulse" />
                    )}
                  </div>

                  {/* Station Card */}
                  <div
                    className={`rounded-lg border p-4 cursor-pointer transition ${
                      isExpanded
                        ? 'bg-slate-700/50 border-blue-500/50'
                        : isCompleted
                        ? 'bg-slate-900/30 border-emerald-500/30'
                        : isCurrent
                        ? 'bg-blue-900/20 border-blue-500/50'
                        : 'bg-slate-900/50 border-slate-600 hover:border-slate-500'
                    }`}
                    onClick={() => setExpandedStation(
                      isExpanded ? null : station.id
                    )}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="font-semibold text-white">{station.name}</h3>
                          {isCompleted && (
                            <Badge className="bg-emerald-600 text-white text-xs">
                              ✓ Completed
                            </Badge>
                          )}
                          {isCurrent && (
                            <Badge className="bg-blue-600 text-white text-xs animate-pulse">
                              ► Current
                            </Badge>
                          )}
                        </div>

                        {/* Station Info Row */}
                        <div className="flex items-center gap-4 text-sm text-slate-400">
                          {station.distance && (
                            <span>{station.distance.toFixed(1)} km</span>
                          )}
                          {station.eta && (
                            <span className="text-emerald-400">
                              ETA: {station.eta}
                            </span>
                          )}
                        </div>

                        {/* Restaurant Badge */}
                        {station.hasRestaurants && (
                          <div className="mt-2">
                            <Badge className="bg-amber-600/80 text-white text-xs">
                              <UtensilsCrossed className="w-3 h-3 mr-1" />
                              {station.restaurantCount || 1} Restaurant
                              {station.restaurantCount !== 1 ? 's' : ''}
                            </Badge>
                          </div>
                        )}
                      </div>

                      {/* Expand Indicator */}
                      <ChevronDown
                        className={`w-5 h-5 text-slate-400 transition ${
                          isExpanded ? 'rotate-180' : ''
                        }`}
                      />
                    </div>

                    {/* Expanded Content */}
                    {isExpanded && (
                      <div className="mt-4 pt-4 border-t border-slate-700">
                        <Tabs defaultValue={station.hasRestaurants ? 'restaurants' : 'contact'} className="w-full">
                          <TabsList className="grid w-full grid-cols-2 bg-slate-800">
                            {station.hasRestaurants && (
                              <TabsTrigger
                                value="restaurants"
                                className="text-xs"
                              >
                                <UtensilsCrossed className="w-3 h-3 mr-1" />
                                Restaurants
                              </TabsTrigger>
                            )}
                            <TabsTrigger
                              value="contact"
                              className={station.hasRestaurants ? 'text-xs' : 'col-span-2 text-xs'}
                            >
                              <MessageCircle className="w-3 h-3 mr-1" />
                              Contact Agent
                            </TabsTrigger>
                          </TabsList>

                          {station.hasRestaurants && (
                            <TabsContent value="restaurants" className="mt-4">
                              <div className="space-y-3">
                                <div className="bg-slate-700/50 rounded-lg p-4 border border-slate-600">
                                  <p className="text-white font-semibold mb-2">Available Restaurants</p>
                                  <p className="text-sm text-slate-400 mb-3">
                                    {station.restaurantCount || 0} restaurants available at this station
                                  </p>
                                  <Button 
                                    size="sm" 
                                    className="w-full"
                                    onClick={() => {
                                      console.log(`Browse restaurants at ${station.name}`);
                                      // This will be expanded with full restaurant browser on first load
                                    }}
                                  >
                                    View Restaurants
                                  </Button>
                                </div>
                              </div>
                            </TabsContent>
                          )}

                          <TabsContent value="contact" className="mt-4">
                            <TextCallCentre stationId={station.id} />
                          </TabsContent>
                        </Tabs>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </CardContent>
    </Card>
  );
};

export default JourneyTimeline;
