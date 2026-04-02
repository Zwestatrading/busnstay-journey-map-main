import React, { useState, useEffect, useRef } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import {
  MapPin, Navigation, AlertCircle, CheckCircle2, Loader2, X,
  Navigation2, Zap, Clock
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';

interface LocationCoord {
  latitude: number;
  longitude: number;
}

interface TaxiLocation {
  address: string;
  coordinates: LocationCoord;
  distanceToStation: number; // in kilometers
  estimatedFare: number; // in Kwacha
  estimatedTime: number; // in minutes
}

interface TaxiLocationPickerProps {
  stationLocation: LocationCoord;
  stationName: string;
  cityName: string;
  baseFare?: number; // Base fare in K
  farePerKm?: number; // Fare per km in K
  onLocationSelected: (location: TaxiLocation) => void;
  onCancel: () => void;
}

// Mock addresses within towns - in production, use a real geocoding service
const townAddresses: Record<string, Array<{ name: string; lat: number; lng: number }>> = {
  'Lusaka': [
    { name: 'Ridgeway, Lusaka', lat: -15.3915, lng: 28.2832 },
    { name: 'Kabulonga, Lusaka', lat: -15.4189, lng: 28.2889 },
    { name: 'Northmead, Lusaka', lat: -15.3667, lng: 28.2833 },
    { name: 'Kamwala, Lusaka', lat: -15.4128, lng: 28.2819 },
    { name: 'Chilenje, Lusaka', lat: -15.4278, lng: 28.2750 },
    { name: 'Mandevu, Lusaka', lat: -15.4519, lng: 28.2694 },
    { name: 'Libala, Lusaka', lat: -15.4833, lng: 28.2333 },
    { name: 'Downtown, Lusaka', lat: -15.3868, lng: 28.2876 },
  ],
  'Ndola': [
    { name: 'Masala, Ndola', lat: -12.9462, lng: 28.6486 },
    { name: 'Lubuto, Ndola', lat: -12.9667, lng: 28.6500 },
    { name: 'Ndola City Centre', lat: -12.9458, lng: 28.6528 },
    { name: 'Kopala, Ndola', lat: -12.9661, lng: 28.6200 },
    { name: 'Milofwe, Ndola', lat: -12.9500, lng: 28.6300 },
  ],
  'Kitwe': [
    { name: 'Nkana, Kitwe', lat: -12.8175, lng: 28.6558 },
    { name: 'Kitwe City Centre', lat: -12.8156, lng: 28.6453 },
    { name: 'Nkubika, Kitwe', lat: -12.8389, lng: 28.6667 },
  ],
  'Zambian': [
    { name: 'City Centre', lat: 0, lng: 0 },
    { name: 'Business District', lat: 0.1, lng: 0.1 },
  ],
};

export const TaxiLocationPicker: React.FC<TaxiLocationPickerProps> = ({
  stationLocation,
  stationName,
  cityName,
  baseFare = 20,
  farePerKm = 5,
  onLocationSelected,
  onCancel,
}) => {
  const { toast } = useToast();
  const [searchInput, setSearchInput] = useState('');
  const [suggestions, setSuggestions] = useState<Array<{ name: string; lat: number; lng: number }>>([]);
  const [selectedLocation, setSelectedLocation] = useState<TaxiLocation | null>(null);
  const [userLocation, setUserLocation] = useState<LocationCoord | null>(null);
  const [loading, setLoading] = useState(false);
  const [usingCurrentLocation, setUsingCurrentLocation] = useState(false);
  const mapRef = useRef<HTMLDivElement>(null);

  // Get addresses for the city
  const cityAddresses = townAddresses[cityName] || townAddresses['Zambian'] || [];

  // Handle search input
  const handleSearch = (input: string) => {
    setSearchInput(input);

    if (input.trim().length === 0) {
      setSuggestions([]);
      return;
    }

    const filtered = cityAddresses.filter((addr) =>
      addr.name.toLowerCase().includes(input.toLowerCase())
    );

    setSuggestions(filtered);
  };

  // Calculate distance using Haversine formula
  const calculateDistance = (
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
  ): number => {
    const R = 6371; // Earth's radius in km
    const dLat = ((lat2 - lat1) * Math.PI) / 180;
    const dLon = ((lon2 - lon1) * Math.PI) / 180;
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  };

  // Handle location selection
  const handleSelectLocation = (locationName: string, lat: number, lng: number) => {
    const distance = calculateDistance(
      stationLocation.latitude,
      stationLocation.longitude,
      lat,
      lng
    );

    const fare = Math.round(baseFare + distance * farePerKm);
    const estimatedTime = Math.round(distance * 2 + 5); // Rough estimate: 2 min per km + 5 min wait

    const location: TaxiLocation = {
      address: locationName,
      coordinates: { latitude: lat, longitude: lng },
      distanceToStation: Math.round(distance * 10) / 10,
      estimatedFare: fare,
      estimatedTime: estimatedTime,
    };

    setSelectedLocation(location);
    setSuggestions([]);
    setSearchInput('');
  };

  // Get current location
  const handleUseCurrentLocation = async () => {
    setLoading(true);
    try {
      if ('geolocation' in navigator) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            const { latitude, longitude } = position.coords;
            setUserLocation({ latitude, longitude });
            setUsingCurrentLocation(true);

            const distance = calculateDistance(
              stationLocation.latitude,
              stationLocation.longitude,
              latitude,
              longitude
            );

            const fare = Math.round(baseFare + distance * farePerKm);
            const estimatedTime = Math.round(distance * 2 + 5);

            const location: TaxiLocation = {
              address: 'Current Location',
              coordinates: { latitude, longitude },
              distanceToStation: Math.round(distance * 10) / 10,
              estimatedFare: fare,
              estimatedTime: estimatedTime,
            };

            setSelectedLocation(location);
            toast({
              title: 'Location captured',
              description: `Distance to ${stationName}: ${location.distanceToStation}km`,
            });
          },
          (error) => {
            toast({
              title: 'Unable to access location',
              description: 'Please enable location permission or search manually',
              variant: 'destructive',
            });
            console.error('Geolocation error:', error);
          }
        );
      } else {
        toast({
          title: 'Geolocation not supported',
          description: 'Please search for your location manually',
          variant: 'destructive',
        });
      }
    } finally {
      setLoading(false);
    }
  };

  // Handle confirmation
  const handleConfirm = () => {
    if (!selectedLocation) {
      toast({
        title: 'Select a location',
        description: 'Please choose a pickup location',
        variant: 'destructive',
      });
      return;
    }

    onLocationSelected(selectedLocation);
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: 20 }}
      className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
    >
      <Card className="w-full max-w-md max-h-[90vh] overflow-y-auto">
        <CardHeader className="border-b">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="flex items-center gap-2">
                <MapPin className="w-5 h-5 text-orange-500" />
                Select Pickup Location
              </CardTitle>
              <CardDescription>{cityName}</CardDescription>
            </div>
            <button onClick={onCancel} className="mt-[-8px]">
              <X className="w-5 h-5" />
            </button>
          </div>
        </CardHeader>

        <CardContent className="space-y-4 pt-6">
          {/* Location Options */}
          <div className="space-y-3">
            {/* Current Location Button */}
            <Button
              onClick={handleUseCurrentLocation}
              disabled={loading}
              variant="outline"
              className="w-full justify-start gap-2"
            >
              {loading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Navigation className="w-4 h-4" />
              )}
              {usingCurrentLocation && userLocation
                ? `Current Location (${selectedLocation?.distanceToStation}km)`
                : 'Use Current Location'}
            </Button>

            {/* Or */}
            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-white px-2 text-muted-foreground">Or</span>
              </div>
            </div>

            {/* Search Input */}
            <div>
              <label className="text-xs font-semibold block mb-2">Search Location</label>
              <input
                type="text"
                value={searchInput}
                onChange={(e) => handleSearch(e.target.value)}
                placeholder="Search within town..."
                className="w-full px-3 py-2 border rounded-lg text-sm"
              />
            </div>

            {/* Suggestions */}
            {suggestions.length > 0 && (
              <div className="space-y-1 max-h-40 overflow-y-auto border rounded-lg">
                {suggestions.map((suggestion, idx) => (
                  <button
                    key={idx}
                    onClick={() =>
                      handleSelectLocation(suggestion.name, suggestion.lat, suggestion.lng)
                    }
                    className="w-full px-3 py-2 text-left text-sm hover:bg-accent border-b last:border-b-0"
                  >
                    <MapPin className="w-3 h-3 inline mr-2 text-orange-500" />
                    {suggestion.name}
                  </button>
                ))}
              </div>
            )}

            {/* Quick Selection */}
            {suggestions.length === 0 && searchInput === '' && (
              <>
                <label className="text-xs font-semibold block mt-4">Popular Locations</label>
                <div className="space-y-1 max-h-40 overflow-y-auto">
                  {cityAddresses.slice(0, 5).map((location, idx) => (
                    <button
                      key={idx}
                      onClick={() =>
                        handleSelectLocation(location.name, location.lat, location.lng)
                      }
                      className="w-full px-3 py-2 text-left text-sm hover:bg-accent border rounded-lg"
                    >
                      <MapPin className="w-3 h-3 inline mr-2 text-orange-500" />
                      {location.name}
                    </button>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* Selected Location Summary */}
          {selectedLocation && (
            <motion.div
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
              className="p-3 bg-orange-50 border border-orange-200 rounded-lg space-y-3"
            >
              <div className="flex items-start justify-between">
                <div>
                  <p className="text-xs font-semibold text-muted-foreground">Selected Location</p>
                  <p className="font-semibold text-sm flex items-center gap-1 mt-1">
                    <CheckCircle2 className="w-4 h-4 text-green-600" />
                    {selectedLocation.address}
                  </p>
                </div>
              </div>

              {/* Fare Details */}
              <div className="grid grid-cols-3 gap-2 text-xs">
                <div className="p-2 bg-white rounded border">
                  <p className="text-muted-foreground">Distance</p>
                  <p className="font-bold text-orange-600">
                    {selectedLocation.distanceToStation} km
                  </p>
                </div>
                <div className="p-2 bg-white rounded border flex items-center justify-center">
                  <Navigation2 className="w-4 h-4 text-orange-500" />
                </div>
                <div className="p-2 bg-white rounded border">
                  <p className="text-muted-foreground">To {stationName}</p>
                </div>
              </div>

              {/* Fare Breakdown */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="flex items-center gap-1">
                    <Zap className="w-3 h-3 text-orange-500" />
                    Estimated Fare
                  </span>
                  <span className="font-bold">K{selectedLocation.estimatedFare}</span>
                </div>
                <div className="flex items-center justify-between text-xs">
                  <span className="flex items-center gap-1">
                    <Clock className="w-3 h-3 text-blue-500" />
                    Estimated Time
                  </span>
                  <span className="font-bold">{selectedLocation.estimatedTime} min</span>
                </div>
              </div>

              {/* Fare Formula */}
              <div className="text-xs text-muted-foreground bg-white p-2 rounded border">
                <p>Fare = K{baseFare} + ({selectedLocation.distanceToStation}km × K{farePerKm}/km)</p>
              </div>
            </motion.div>
          )}

          {/* Info Message */}
          {!selectedLocation && (
            <div className="p-3 bg-blue-50 border border-blue-200 rounded-lg flex gap-2">
              <AlertCircle className="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5" />
              <p className="text-xs text-blue-700">
                Select your exact pickup location to calculate fare and estimated time to {stationName}
              </p>
            </div>
          )}

          {/* Action Buttons */}
          <div className="grid grid-cols-2 gap-2 pt-4 border-t">
            <Button variant="outline" onClick={onCancel}>
              Close
            </Button>
            <Button
              onClick={handleConfirm}
              disabled={!selectedLocation}
              className="bg-orange-600 hover:bg-orange-700"
            >
              Confirm
            </Button>
          </div>
        </CardContent>
      </Card>
    </motion.div>
  );
};

export default TaxiLocationPicker;
