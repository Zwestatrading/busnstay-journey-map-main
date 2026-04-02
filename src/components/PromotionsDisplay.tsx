import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Sparkles, Tag, Calendar, Users, TrendingUp, AlertCircle, CheckCircle2,
  Clock, DollarSign, Plus, X, Save, Edit2, Trash2, Loader2
} from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

interface Promotion {
  id: string;
  title: string;
  description: string;
  discountPercent?: number;
  discountFixed?: number;
  imageUrl?: string;
  startDate: string;
  endDate: string;
  applicableItems: string[]; // menu item IDs or "all"
  maxRedemptions?: number;
  currentRedemptions: number;
  isActive: boolean;
  isPremium: boolean; // Paid promotion featured on homepage
  boostLevel: number; // 1-5, affects visibility
}

interface PromotionsDisplayProps {
  restaurantId: string;
  restaurantName: string;
  isRestaurantOwner?: boolean;
}

export const PromotionsDisplay: React.FC<PromotionsDisplayProps> = ({
  restaurantId,
  restaurantName,
  isRestaurantOwner = false,
}) => {
  const { toast } = useToast();
  const [promotions, setPromotions] = useState<Promotion[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingPromo, setEditingPromo] = useState<Promotion | null>(null);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    fetchPromotions();
  }, [restaurantId]);

  const fetchPromotions = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('restaurant_promotions')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .order('boost_level', { ascending: false })
        .order('start_date', { ascending: false });

      if (error) throw error;

      setPromotions(
        (data || []).map((promo: any) => ({
          id: promo.id,
          title: promo.title,
          description: promo.description,
          discountPercent: promo.discount_percent,
          discountFixed: promo.discount_fixed,
          imageUrl: promo.image_url,
          startDate: promo.start_date,
          endDate: promo.end_date,
          applicableItems: promo.applicable_items || [],
          maxRedemptions: promo.max_redemptions,
          currentRedemptions: promo.current_redemptions,
          isActive: promo.is_active,
          isPremium: promo.is_premium,
          boostLevel: promo.boost_level,
        }))
      );
    } catch (error) {
      toast({
        title: 'Error loading promotions',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSavePromotion = async (promo: Promotion) => {
    try {
      if (promo.id.startsWith('new-')) {
        const { error } = await supabase.from('restaurant_promotions').insert({
          restaurant_id: restaurantId,
          title: promo.title,
          description: promo.description,
          discount_percent: promo.discountPercent,
          discount_fixed: promo.discountFixed,
          image_url: promo.imageUrl,
          start_date: promo.startDate,
          end_date: promo.endDate,
          applicable_items: promo.applicableItems,
          max_redemptions: promo.maxRedemptions,
          current_redemptions: 0,
          is_active: promo.isActive,
          is_premium: promo.isPremium,
          boost_level: promo.boostLevel,
        });

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('restaurant_promotions')
          .update({
            title: promo.title,
            description: promo.description,
            discount_percent: promo.discountPercent,
            discount_fixed: promo.discountFixed,
            image_url: promo.imageUrl,
            start_date: promo.startDate,
            end_date: promo.endDate,
            applicable_items: promo.applicableItems,
            max_redemptions: promo.maxRedemptions,
            is_active: promo.isActive,
            is_premium: promo.isPremium,
            boost_level: promo.boostLevel,
          })
          .eq('id', promo.id);

        if (error) throw error;
      }

      toast({
        title: 'Promotion saved',
        description: `${promo.title} has been saved`,
      });

      await fetchPromotions();
      setEditingPromo(null);
      setShowForm(false);
    } catch (error) {
      toast({
        title: 'Error saving promotion',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const handleDeletePromotion = async (promoId: string) => {
    if (!confirm('Delete this promotion?')) return;

    try {
      const { error } = await supabase
        .from('restaurant_promotions')
        .delete()
        .eq('id', promoId);

      if (error) throw error;

      toast({
        title: 'Promotion deleted',
        description: 'Promotion has been removed',
      });

      await fetchPromotions();
    } catch (error) {
      toast({
        title: 'Error deleting promotion',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const isPromotionActive = (promo: Promotion) => {
    const now = new Date();
    const start = new Date(promo.startDate);
    const end = new Date(promo.endDate);
    return now >= start && now <= end && promo.isActive;
  };

  const activeDealLimit = promotions.filter(p => isPromotionActive(p)).length;

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-5 h-5 animate-spin mr-2" />
        <span>Loading promotions...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-display font-bold flex items-center gap-2">
            <Sparkles className="w-6 h-6 text-yellow-500" />
            Promotions & Deals
          </h2>
          <p className="text-sm text-muted-foreground">{restaurantName}</p>
        </div>
        {isRestaurantOwner && (
          <Button
            onClick={() => {
              setEditingPromo(null);
              setShowForm(!showForm);
            }}
            variant="outline"
            className="gap-2"
          >
            <Plus className="w-4 h-4" />
            New Promotion
          </Button>
        )}
      </div>

      {/* Info Banner */}
      {isRestaurantOwner && (
        <Card className="bg-gradient-to-r from-blue-50 to-purple-50 border-blue-200">
          <CardContent className="pt-6">
            <div className="flex gap-3">
              <TrendingUp className="w-5 h-5 text-blue-600 flex-shrink-0" />
              <div>
                <p className="font-semibold text-sm">
                  Boost your promotions to reach more customers!
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Pay to feature your promotions with higher visibility. Level 5 gets featured on homepage.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Form */}
      {showForm && isRestaurantOwner && (
        <PromotionForm
          promo={editingPromo}
          onSave={handleSavePromotion}
          onCancel={() => {
            setShowForm(false);
            setEditingPromo(null);
          }}
        />
      )}

      {/* Active Promotions */}
      <div>
        <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
          <CheckCircle2 className="w-5 h-5 text-green-600" />
          Active Now ({activeDealLimit})
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {promotions
            .filter(p => isPromotionActive(p))
            .map((promo) => (
              <PromotionCard
                key={promo.id}
                promo={promo}
                onEdit={isRestaurantOwner ? () => {
                  setEditingPromo(promo);
                  setShowForm(true);
                } : undefined}
                onDelete={isRestaurantOwner ? () => handleDeletePromotion(promo.id) : undefined}
              />
            ))}
        </div>
        {promotions.filter(p => isPromotionActive(p)).length === 0 && (
          <Card>
            <CardContent className="pt-12 pb-12 text-center">
              <Tag className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
              <p className="text-muted-foreground">No active promotions</p>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Upcoming & Expired */}
      {isRestaurantOwner && (
        <>
          <div>
            <h3 className="text-lg font-semibold mb-4 flex items-center gap-2">
              <Clock className="w-5 h-5 text-orange-600" />
              Upcoming
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {promotions
                .filter(p => new Date(p.startDate) > new Date())
                .map((promo) => (
                  <PromotionCard
                    key={promo.id}
                    promo={promo}
                    onEdit={() => {
                      setEditingPromo(promo);
                      setShowForm(true);
                    }}
                    onDelete={() => handleDeletePromotion(promo.id)}
                  />
                ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
};

interface PromotionCardProps {
  promo: Promotion;
  onEdit?: () => void;
  onDelete?: () => void;
}

const PromotionCard: React.FC<PromotionCardProps> = ({ promo, onEdit, onDelete }) => {
  const discount = promo.discountPercent ? `${promo.discountPercent}% OFF` : `K${promo.discountFixed} OFF`;
  const endDate = new Date(promo.endDate);
  const daysLeft = Math.ceil((endDate.getTime() - new Date().getTime()) / (1000 * 60 * 60 * 24));

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
    >
      <Card className="h-full hover:shadow-lg transition-shadow overflow-hidden">
        {promo.imageUrl && (
          <div className="relative h-24 bg-muted overflow-hidden">
            <img
              src={promo.imageUrl}
              alt={promo.title}
              className="w-full h-full object-cover"
            />
          </div>
        )}

        <CardHeader className="pb-2">
          <div className="flex items-start justify-between gap-2">
            <div className="flex-1">
              <CardTitle className="text-base flex items-center gap-2">
                {promo.title}
                {promo.isPremium && (
                  <Badge className="bg-yellow-500 text-white text-xs">
                    Premium
                  </Badge>
                )}
              </CardTitle>
            </div>
            <div className="text-right">
              <div className="text-lg font-bold text-orange-600">{discount}</div>
              {daysLeft > 0 && (
                <div className="text-xs text-muted-foreground">{daysLeft} days left</div>
              )}
            </div>
          </div>
        </CardHeader>

        <CardContent className="space-y-3">
          <p className="text-sm text-muted-foreground">{promo.description}</p>

          {promo.maxRedemptions && (
            <div className="flex items-center gap-2 text-xs">
              <Users className="w-4 h-4" />
              <span>{promo.currentRedemptions}/{promo.maxRedemptions} redeemed</span>
            </div>
          )}

          {(onEdit || onDelete) && (
            <div className="flex gap-2 pt-2">
              {onEdit && (
                <Button
                  size="sm"
                  variant="outline"
                  className="flex-1 text-xs"
                  onClick={onEdit}
                >
                  <Edit2 className="w-3 h-3 mr-1" />
                  Edit
                </Button>
              )}
              {onDelete && (
                <Button
                  size="sm"
                  variant="destructive"
                  className="flex-1 text-xs"
                  onClick={onDelete}
                >
                  <Trash2 className="w-3 h-3 mr-1" />
                  Delete
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </motion.div>
  );
};

interface PromotionFormProps {
  promo: Promotion | null;
  onSave: (promo: Promotion) => void;
  onCancel: () => void;
}

const PromotionForm: React.FC<PromotionFormProps> = ({ promo, onSave, onCancel }) => {
  const today = new Date().toISOString().split('T')[0];
  const tomorrow = new Date(Date.now() + 86400000).toISOString().split('T')[0];

  const [formData, setFormData] = useState<Promotion>(
    promo || {
      id: `new-${Date.now()}`,
      title: '',
      description: '',
      discountPercent: 0,
      discountFixed: 0,
      startDate: today,
      endDate: tomorrow,
      applicableItems: [],
      isActive: true,
      isPremium: false,
      boostLevel: 1,
      currentRedemptions: 0,
    }
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>{promo ? 'Edit Promotion' : 'Create New Promotion'}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="md:col-span-2">
            <label className="text-sm font-medium">Promotion Title *</label>
            <input
              type="text"
              value={formData.title}
              onChange={(e) => setFormData({ ...formData, title: e.target.value })}
              placeholder="e.g., Happy Hour Special"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div className="md:col-span-2">
            <label className="text-sm font-medium">Description</label>
            <textarea
              value={formData.description}
              onChange={(e) =>
                setFormData({ ...formData, description: e.target.value })
              }
              placeholder="Describe your promotion..."
              rows={2}
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Discount Percentage (%)</label>
            <input
              type="number"
              value={formData.discountPercent || 0}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  discountPercent: parseInt(e.target.value) || 0,
                })
              }
              min="0"
              max="100"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">OR Fixed Discount (K)</label>
            <input
              type="number"
              value={formData.discountFixed || 0}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  discountFixed: parseInt(e.target.value) || 0,
                })
              }
              min="0"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Start Date</label>
            <input
              type="date"
              value={formData.startDate}
              onChange={(e) => setFormData({ ...formData, startDate: e.target.value })}
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">End Date</label>
            <input
              type="date"
              value={formData.endDate}
              onChange={(e) => setFormData({ ...formData, endDate: e.target.value })}
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Boost Level (1-5)</label>
            <div className="flex gap-1 mt-1">
              {[1, 2, 3, 4, 5].map((level) => (
                <button
                  key={level}
                  onClick={() => setFormData({ ...formData, boostLevel: level })}
                  className={`flex-1 py-2 text-sm font-semibold rounded ${
                    formData.boostLevel >= level
                      ? 'bg-orange-600 text-white'
                      : 'bg-muted'
                  }`}
                >
                  {level}
                </button>
              ))}
            </div>
            <p className="text-xs text-muted-foreground mt-1">
              Level 5 gets featured on homepage
            </p>
          </div>

          <div>
            <label className="text-sm font-medium">Max Redemptions (optional)</label>
            <input
              type="number"
              value={formData.maxRedemptions || ''}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  maxRedemptions: e.target.value ? parseInt(e.target.value) : undefined,
                })
              }
              min="1"
              placeholder="Leave blank for unlimited"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>

        <div className="flex gap-2 pt-4">
          <Button onClick={onCancel} variant="outline" className="flex-1">
            <X className="w-4 h-4 mr-2" />
            Cancel
          </Button>
          <Button onClick={() => onSave(formData)} className="flex-1 bg-orange-600 hover:bg-orange-700">
            <Save className="w-4 h-4 mr-2" />
            Save Promotion
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default PromotionsDisplay;
