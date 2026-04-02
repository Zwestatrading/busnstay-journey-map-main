import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { MapPin, Navigation, AlertCircle, CheckCircle2, Loader2 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { getCurrentLocation } from '@/services/geoService';
import { calculateRestaurantDeliveryFeeK20, saveRestaurantK20Config } from '@/services/deliveryFeeService';

interface RestaurantPositionSetupProps {
  restaurantId: string;
  restaurantName: string;
  stationName: string;
  onComplete?: () => void;
}

export const RestaurantPositionSetup: React.FC<RestaurantPositionSetupProps> = ({
  restaurantId,
  restaurantName,
  stationName,
  onComplete,
}) => {
  const { toast } = useToast();
  const [step, setStep] = useState<'selection' | 'location' | 'pricing' | 'confirm'>('selection');
  const [positionType, setPositionType] = useState<'near' | 'away' | null>(null);
  const [restaurantLocation, setRestaurantLocation] = useState<{ lat: number; lon: number } | null>(null);
  const [loading, setLoading] = useState(false);
  const [distanceFromStation, setDistanceFromStation] = useState<number | null>(null);

  const handlePositionSelect = (type: 'near' | 'away') => {
    setPositionType(type);
    if (type === 'near') {
      // Near station - no need for detailed location
      setStep('pricing');
    } else {
      // Away from station - need to get location and calculate distance
      setStep('location');
    }
  };

  const handleGetLocation = async () => {
    setLoading(true);
    try {
      const location = await getCurrentLocation();
      setRestaurantLocation({
        lat: location.latitude,
        lon: location.longitude,
      });

      toast({
        title: 'Location Captured',
        description: 'Your restaurant location has been recorded',
      });

      setStep('pricing');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to get location';
      toast({
        title: 'Location Error',
        description: errorMessage,
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const estimatePricing = () => {
    const baseK20Fee = 20; // K20 base fee
    const distanceFeePerKm = 5; // K5 per km
    const estimatedDistance = positionType === 'away' ? 2.5 : 0; // Example distance

    return {
      baseK20Fee,
      distanceFeePerKm,
      estimatedDistance,
      estimatedTotalFee: baseK20Fee + (estimatedDistance * distanceFeePerKm),
    };
  };

  const pricing = estimatePricing();

  const handleSaveConfiguration = async () => {
    setLoading(true);
    try {
      if (!restaurantLocation && positionType === 'away') {
        throw new Error('Location not captured');
      }

      // Mock station coordinates (in real app, these would come from the database)
      const stationLat = -13.1333;
      const stationLon = 27.8493; // Example: Lusaka station

      const success = await saveRestaurantK20Config(restaurantId, {
        baseK20Fee: pricing.baseK20Fee,
        distancePerKmFee: pricing.distanceFeePerKm,
        isNearStation: positionType === 'near',
        latitude: restaurantLocation?.lat || stationLat,
        longitude: restaurantLocation?.lon || stationLon,
        stationLatitude: stationLat,
        stationLongitude: stationLon,
      });

      if (success) {
        toast({
          title: 'Configuration Saved',
          description: 'Your restaurant position and pricing has been updated',
        });
        setStep('confirm');
        setTimeout(() => onComplete?.(), 1500);
      } else {
        throw new Error('Failed to save configuration');
      }
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to save configuration';
      toast({
        title: 'Error',
        description: errorMessage,
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  if (step === 'selection') {
    return (
      <Card className="w-full max-w-2xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <MapPin className="w-5 h-5" />
            Restaurant Position Setup
          </CardTitle>
          <CardDescription>
            {restaurantName} at {stationName}
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Alert className="bg-blue-50 border-blue-200">
            <AlertCircle className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-blue-800">
              Your delivery fee model depends on your restaurant's location relative to the station
            </AlertDescription>
          </Alert>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => handlePositionSelect('near')}
              className="p-6 border-2 border-primary rounded-lg hover:bg-primary/5 transition text-left"
            >
              <div className="flex items-start gap-3">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center flex-shrink-0">
                  <MapPin className="w-6 h-6 text-primary" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">By the Station</h3>
                  <p className="text-sm text-muted-foreground">
                    Your restaurant is located at or very near the station
                  </p>
                  <Badge className="mt-3">K20 Fixed Fee</Badge>
                </div>
              </div>
            </motion.button>

            <motion.button
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
              onClick={() => handlePositionSelect('away')}
              className="p-6 border-2 border-secondary rounded-lg hover:bg-secondary/5 transition text-left"
            >
              <div className="flex items-start gap-3">
                <div className="w-12 h-12 rounded-full bg-secondary/10 flex items-center justify-center flex-shrink-0">
                  <Navigation className="w-6 h-6 text-secondary" />
                </div>
                <div>
                  <h3 className="font-semibold mb-1">Away from Station</h3>
                  <p className="text-sm text-muted-foreground">
                    Your restaurant is located away from the station
                  </p>
                  <Badge variant="outline" className="mt-3">K20 + Distance Fee</Badge>
                </div>
              </div>
            </motion.button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (step === 'location') {
    return (
      <Card className="w-full max-w-2xl">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Navigation className="w-5 h-5" />
            Capture Restaurant Location
          </CardTitle>
          <CardDescription>
            We need your exact location to calculate distance-based fees
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              Please enable location permissions and be at your restaurant for accurate location capture
            </AlertDescription>
          </Alert>

          {restaurantLocation ? (
            <div className="p-4 bg-green-50 border border-green-200 rounded-lg">
              <div className="flex items-center gap-2 text-green-900 mb-2">
                <CheckCircle2 className="w-5 h-5" />
                <span className="font-semibold">Location Captured</span>
              </div>
              <p className="text-sm text-green-800">
                Latitude: {restaurantLocation.lat.toFixed(4)}<br />
                Longitude: {restaurantLocation.lon.toFixed(4)}
              </p>
            </div>
          ) : null}

          <Button
            onClick={handleGetLocation}
            disabled={loading}
            size="lg"
            className="w-full"
          >
            {loading ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Getting Location...
              </>
            ) : (
              <>
                <MapPin className="w-4 h-4 mr-2" />
                Get Current Location
              </>
            )}
          </Button>

          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setStep('selection')}
              disabled={loading}
              className="flex-1"
            >
              Back
            </Button>
            <Button
              onClick={() => setStep('pricing')}
              disabled={!restaurantLocation || loading}
              className="flex-1"
            >
              Continue
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (step === 'pricing') {
    return (
      <Card className="w-full max-w-2xl">
        <CardHeader>
          <CardTitle>Delivery Fee Configuration</CardTitle>
          <CardDescription>
            Review your K20+ pricing model
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="p-4 bg-muted rounded-lg space-y-3">
            <div className="flex justify-between items-center">
              <span className="text-sm font-medium">Base K20 Fee:</span>
              <span className="font-bold">K{pricing.baseK20Fee}</span>
            </div>
            {positionType === 'away' && (
              <>
                <div className="h-px bg-border" />
                <div className="flex justify-between items-center">
                  <span className="text-sm font-medium">Distance from Station:</span>
                  <span className="font-bold">{pricing.estimatedDistance.toFixed(1)} km</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm font-medium">Distance Fee (K{pricing.distanceFeePerKm}/km):</span>
                  <span className="font-bold">
                    K{(pricing.estimatedDistance * pricing.distanceFeePerKm).toFixed(2)}
                  </span>
                </div>
              </>
            )}
            <div className="h-px bg-border" />
            <div className="flex justify-between items-center pt-2 border-t-2">
              <span className="text-sm font-semibold">Total Delivery Fee:</span>
              <span className="text-lg font-bold text-primary">
                K{pricing.estimatedTotalFee.toFixed(2)}
              </span>
            </div>
          </div>

          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>
              {positionType === 'near'
                ? 'Fixed K20 fee for all deliveries from your station location'
                : 'K20 base + additional fee for each km away from the station'}
            </AlertDescription>
          </Alert>

          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => setStep(positionType === 'near' ? 'selection' : 'location')}
              disabled={loading}
              className="flex-1"
            >
              Back
            </Button>
            <Button
              onClick={handleSaveConfiguration}
              disabled={loading}
              className="flex-1"
            >
              {loading ? (
                <>
                  <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                  Saving...
                </>
              ) : (
                'Save Configuration'
              )}
            </Button>
          </div>
        </CardContent>
      </Card>
    );
  }

  if (step === 'confirm') {
    return (
      <Card className="w-full max-w-2xl">
        <CardContent className="pt-12 pb-12 text-center">
          <motion.div
            initial={{ scale: 0 }}
            animate={{ scale: 1 }}
            transition={{ type: 'spring', stiffness: 100 }}
            className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6"
          >
            <CheckCircle2 className="w-8 h-8 text-green-600" />
          </motion.div>
          <h3 className="text-2xl font-bold mb-2">Configuration Complete!</h3>
          <p className="text-muted-foreground mb-6">
            Your restaurant position and K20+ pricing model is now active
          </p>
        </CardContent>
      </Card>
    );
  }

  return null;
};

export default RestaurantPositionSetup;
