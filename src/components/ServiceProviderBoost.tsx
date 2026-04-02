import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { AlertCircle, Zap, Award, TrendingUp, CreditCard, Loader2, Star } from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

interface BoostedService {
  id: string;
  serviceType: 'restaurant' | 'hotel' | 'taxi';
  serviceName: string;
  description: string;
  imageUrl: string;
  boostLevel: number; // 1-5
  boostEndDate: string;
  clickCount: number;
  rating?: number;
  location?: string;
}

interface ServiceProviderBoostProps {
  providerId: string;
  providerName: string;
  serviceType: 'restaurant' | 'hotel' | 'taxi';
  onBoostPurchase?: (level: number) => void;
}

const boostPricing = [
  { level: 1, price: 500, duration: 7, features: ['Basic visibility', '100 impressions/day'] },
  { level: 2, price: 1200, duration: 7, features: ['Standard visibility', '500 impressions/day', 'Featured in category'] },
  { level: 3, price: 2500, duration: 7, features: ['High visibility', '1000 impressions/day', 'Featured in category', 'Email campaign'] },
  { level: 4, price: 4000, duration: 7, features: ['Premium visibility', '2000 impressions/day', 'Homepage banner', 'Social media push'] },
  { level: 5, price: 6000, duration: 7, features: ['Maximum visibility', '5000 impressions/day', 'Top homepage placement', 'All social channels'] },
];

export const ServiceProviderBoost: React.FC<ServiceProviderBoostProps> = ({
  providerId,
  providerName,
  serviceType,
  onBoostPurchase,
}) => {
  const { toast } = useToast();
  const [currentBoost, setCurrentBoost] = useState<BoostedService | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedLevel, setSelectedLevel] = useState<number | null>(null);
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    fetchCurrentBoost();
  }, [providerId]);

  const fetchCurrentBoost = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('service_provider_boosts')
        .select('*')
        .eq('provider_id', providerId)
        .eq('service_type', serviceType)
        .gt('boost_end_date', new Date().toISOString())
        .single();

      if (error && error.code !== 'PGRST116') throw error;

      if (data) {
        setCurrentBoost({
          id: data.id,
          serviceType: data.service_type,
          serviceName: data.service_name,
          description: data.description,
          imageUrl: data.image_url,
          boostLevel: data.boost_level,
          boostEndDate: data.boost_end_date,
          clickCount: data.click_count,
          rating: data.rating,
          location: data.location,
        });
      }
    } catch (error) {
      console.error('Error fetching boost:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleBoostPurchase = async (level: number) => {
    setIsProcessing(true);
    try {
      const pricing = boostPricing[level - 1];
      const endDate = new Date();
      endDate.setDate(endDate.getDate() + pricing.duration);

      // In production, integrate with payment gateway (Flutterwave, etc.)
      // For now, create the boost record
      const { error } = await supabase
        .from('service_provider_boosts')
        .upsert({
          provider_id: providerId,
          service_type: serviceType,
          service_name: providerName,
          boost_level: level,
          boost_end_date: endDate.toISOString(),
          boost_price_paid: pricing.price,
          click_count: 0,
        });

      if (error) throw error;

      toast({
        title: 'Boost activated!',
        description: `Your ${serviceType} is now featured at level ${level}`,
      });

      await fetchCurrentBoost();
      onBoostPurchase?.(level);
      setSelectedLevel(null);
    } catch (error) {
      toast({
        title: 'Error activating boost',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setIsProcessing(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-5 h-5 animate-spin mr-2" />
        <span>Loading boost info...</span>
      </div>
    );
  }

  const daysRemaining = currentBoost
    ? Math.ceil(
        (new Date(currentBoost.boostEndDate).getTime() - new Date().getTime()) /
          (1000 * 60 * 60 * 24)
      )
    : 0;

  return (
    <div className="space-y-6">
      {/* Current Boost Status */}
      {currentBoost && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <Card className="bg-gradient-to-r from-yellow-50 to-orange-50 border-yellow-200">
            <CardHeader>
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-3">
                  <Zap className="w-6 h-6 text-yellow-600" />
                  <div>
                    <CardTitle className="text-lg">Boost Active</CardTitle>
                    <CardDescription>
                      Level {currentBoost.boostLevel} - {daysRemaining} days remaining
                    </CardDescription>
                  </div>
                </div>
                <Badge variant="default" className="bg-yellow-600">
                  Active
                </Badge>
              </div>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-3 gap-4 text-sm">
                <div>
                  <p className="text-muted-foreground">Impressions</p>
                  <p className="font-bold">{currentBoost.clickCount}</p>
                </div>
                <div>
                  <p className="text-muted-foreground">Level</p>
                  <p className="font-bold flex items-center gap-1">
                    {[...Array(5)].map((_, i) => (
                      <Star
                        key={i}
                        className={`w-4 h-4 ${
                          i < currentBoost.boostLevel
                            ? 'fill-yellow-500 text-yellow-500'
                            : 'text-muted-foreground'
                        }`}
                      />
                    ))}
                  </p>
                </div>
                <div>
                  <p className="text-muted-foreground">Exp. Date</p>
                  <p className="font-bold text-sm">
                    {new Date(currentBoost.boostEndDate).toLocaleDateString()}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      )}

      {/* Upgrade/Purchase Boost */}
      <div>
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          {currentBoost ? 'Upgrade Boost' : 'Boost Your Business'}
          <TrendingUp className="w-5 h-5 text-orange-600" />
        </h3>

        <p className="text-sm text-muted-foreground mb-4">
          Increase visibility like paid Facebook ads. Higher levels get more impressions and better placement.
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
          {boostPricing.map((pricing, idx) => (
            <motion.div
              key={pricing.level}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: idx * 0.1 }}
            >
              <Card
                className={`h-full flex flex-col cursor-pointer transition-all ${
                  selectedLevel === pricing.level
                    ? 'ring-2 ring-orange-600'
                    : ''
                } ${
                  currentBoost?.boostLevel === pricing.level
                    ? 'ring-2 ring-yellow-500'
                    : ''
                }`}
                onClick={() => setSelectedLevel(pricing.level)}
              >
                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="text-sm">Level {pricing.level}</CardTitle>
                      <CardDescription className="text-xs">
                        {pricing.duration} days
                      </CardDescription>
                    </div>
                    {currentBoost?.boostLevel === pricing.level && (
                      <Badge className="bg-yellow-500">Current</Badge>
                    )}
                  </div>
                </CardHeader>
                <CardContent className="flex-1 space-y-3">
                  <div className="text-2xl font-bold text-orange-600">
                    K{pricing.price}
                  </div>
                  <ul className="space-y-1">
                    {pricing.features.map((feature, i) => (
                      <li key={i} className="text-xs text-muted-foreground flex items-start gap-2">
                        <span className="text-orange-600 mt-0.5">•</span>
                        {feature}
                      </li>
                    ))}
                  </ul>

                  <Button
                    onClick={(e) => {
                      e.stopPropagation();
                      handleBoostPurchase(pricing.level);
                    }}
                    disabled={isProcessing}
                    variant={selectedLevel === pricing.level ? 'default' : 'outline'}
                    size="sm"
                    className="w-full mt-2"
                  >
                    {isProcessing ? (
                      <>
                        <Loader2 className="w-3 h-3 mr-1 animate-spin" />
                        Processing
                      </>
                    ) : (
                      <>
                        <CreditCard className="w-3 h-3 mr-1" />
                        Get Level {pricing.level}
                      </>
                    )}
                  </Button>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      </div>

      {/* How it Works */}
      <Card className="bg-blue-50 border-blue-200">
        <CardHeader>
          <CardTitle className="flex items-center gap-2 text-base">
            <Award className="w-5 h-5 text-blue-600" />
            How Boosting Works
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-2 text-sm">
          <p>
            ✓ <strong>More visibility:</strong> Higher levels get better placement on the homepage
          </p>
          <p>
            ✓ <strong>Daily impressions:</strong> Your business shown to more users searching
          </p>
          <p>
            ✓ <strong>Click tracking:</strong> See how many people viewed your boosted listing
          </p>
          <p>
            ✓ <strong>Automatic renewal:</strong> Renew your boost anytime before expiration
          </p>
        </CardContent>
      </Card>

      {/* Payment Info */}
      <Card className="bg-amber-50 border-amber-200">
        <CardContent className="pt-6">
          <div className="flex gap-3">
            <AlertCircle className="w-5 h-5 text-amber-600 flex-shrink-0" />
            <div className="text-sm">
              <p className="font-semibold mb-1">Payment Method</p>
              <p className="text-xs text-muted-foreground">
                Payments are processed securely through Flutterwave. Click "Get Level X" to proceed to payment.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

export default ServiceProviderBoost;
