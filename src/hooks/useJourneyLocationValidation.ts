import { useState, useCallback } from 'react';
import { getCurrentLocation } from '@/services/geoService';
import { validateUserLocationOnRoute, isUserInJourneyCity } from '@/services/journeyLocationValidationService';
import { useToast } from './use-toast';

interface JourneyRoute {
  startLocation: { latitude: number; longitude: number; name: string };
  endLocation: { latitude: number; longitude: number; name: string };
  intermediateStops: { latitude: number; longitude: number; name: string }[];
  routeBuffer: number;
}

export const useJourneyLocationValidation = () => {
  const { toast } = useToast();
  const [isValidating, setIsValidating] = useState(false);
  const [userLocation, setUserLocation] = useState<{ latitude: number; longitude: number } | null>(null);

  const validateLocation = useCallback(
    async (journeyRoute: JourneyRoute, allowedDeviationKm: number = 50) => {
      setIsValidating(true);
      try {
        // Get user's current location
        const location = await getCurrentLocation();
        setUserLocation({
          latitude: location.latitude,
          longitude: location.longitude,
        });

        // Validate against route
        const validation = validateUserLocationOnRoute(
          location.latitude,
          location.longitude,
          journeyRoute,
          allowedDeviationKm
        );

        if (!validation.isValid) {
          toast({
            title: 'Location Validation Failed',
            description: validation.reason,
            variant: 'destructive',
          });
          return false;
        }

        toast({
          title: 'Location Verified',
          description: `You are ${validation.distance?.toFixed(1)}km from ${validation.nearestStopName}`,
          variant: 'default',
        });

        return true;
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Failed to get location';
        toast({
          title: 'Location Error',
          description: errorMessage,
          variant: 'destructive',
        });
        return false;
      } finally {
        setIsValidating(false);
      }
    },
    [toast]
  );

  const checkCityLocation = useCallback(
    async (
      startCityLat: number,
      startCityLon: number,
      endCityLat: number,
      endCityLon: number,
      cityRadiusKm: number = 30
    ) => {
      setIsValidating(true);
      try {
        const location = await getCurrentLocation();
        setUserLocation({
          latitude: location.latitude,
          longitude: location.longitude,
        });

        const isInCity = isUserInJourneyCity(
          location.latitude,
          location.longitude,
          startCityLat,
          startCityLon,
          endCityLat,
          endCityLon,
          cityRadiusKm
        );

        if (!isInCity) {
          toast({
            title: 'Outside Service Area',
            description: `You must be in or near one of the journey cities to book this trip.`,
            variant: 'destructive',
          });
          return false;
        }

        return true;
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : 'Failed to verify location';
        toast({
          title: 'Location Error',
          description: errorMessage,
          variant: 'destructive',
        });
        return false;
      } finally {
        setIsValidating(false);
      }
    },
    [toast]
  );

  return {
    validateLocation,
    checkCityLocation,
    isValidating,
    userLocation,
  };
};
