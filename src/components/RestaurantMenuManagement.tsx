import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import {
  Plus, Edit2, Trash2, Image as ImageIcon, Loader2, Save, X,
  UtensilsCrossed, DollarSign, AlertCircle, CheckCircle2, Eye, EyeOff
} from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  image: string;
  category: string;
  isAvailable: boolean;
  prepTime: number; // minutes
  spicy?: number; // 1-5 scale
}

interface RestaurantMenuManagementProps {
  restaurantId: string;
  restaurantName: string;
}

const categories = ['Appetizers', 'Main Course', 'Sides', 'Beverages', 'Desserts'];

export const RestaurantMenuManagement: React.FC<RestaurantMenuManagementProps> = ({
  restaurantId,
  restaurantName,
}) => {
  const { toast } = useToast();
  const [items, setItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState('All');

  useEffect(() => {
    fetchMenuItems();
  }, [restaurantId]);

  const fetchMenuItems = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('restaurant_menu_items')
        .select('*')
        .eq('restaurant_id', restaurantId)
        .order('category, name');

      if (error) throw error;

      setItems(
        (data || []).map((item: any) => ({
          id: item.id,
          name: item.name,
          description: item.description,
          price: item.price,
          image: item.image,
          category: item.category,
          isAvailable: item.is_available,
          prepTime: item.prep_time,
          spicy: item.spicy_level,
        }))
      );
    } catch (error) {
      toast({
        title: 'Error loading menu',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSaveItem = async (item: MenuItem) => {
    try {
      if (item.id.startsWith('new-')) {
        const { error } = await supabase.from('restaurant_menu_items').insert({
          restaurant_id: restaurantId,
          name: item.name,
          description: item.description,
          price: item.price,
          image: item.image,
          category: item.category,
          is_available: item.isAvailable,
          prep_time: item.prepTime,
          spicy_level: item.spicy,
        });

        if (error) throw error;
      } else {
        const { error } = await supabase
          .from('restaurant_menu_items')
          .update({
            name: item.name,
            description: item.description,
            price: item.price,
            image: item.image,
            category: item.category,
            is_available: item.isAvailable,
            prep_time: item.prepTime,
            spicy_level: item.spicy,
          })
          .eq('id', item.id);

        if (error) throw error;
      }

      toast({
        title: 'Menu item saved',
        description: `${item.name} has been saved`,
      });

      await fetchMenuItems();
      setEditingItem(null);
      setShowForm(false);
    } catch (error) {
      toast({
        title: 'Error saving item',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const handleDeleteItem = async (itemId: string) => {
    if (!confirm('Delete this menu item?')) return;

    try {
      const { error } = await supabase
        .from('restaurant_menu_items')
        .delete()
        .eq('id', itemId);

      if (error) throw error;

      toast({
        title: 'Item deleted',
        description: 'Menu item has been removed',
      });

      await fetchMenuItems();
    } catch (error) {
      toast({
        title: 'Error deleting item',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const handleToggleAvailability = async (item: MenuItem) => {
    try {
      const { error } = await supabase
        .from('restaurant_menu_items')
        .update({ is_available: !item.isAvailable })
        .eq('id', item.id);

      if (error) throw error;

      setItems(
        items.map((i) =>
          i.id === item.id ? { ...i, isAvailable: !i.isAvailable } : i
        )
      );
    } catch (error) {
      toast({
        title: 'Error updating item',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const filteredItems =
    selectedCategory === 'All'
      ? items
      : items.filter((i) => i.category === selectedCategory);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-5 h-5 animate-spin mr-2" />
        <span>Loading menu...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-display font-bold flex items-center gap-2">
            <UtensilsCrossed className="w-6 h-6 text-orange-600" />
            Menu Management
          </h2>
          <p className="text-sm text-muted-foreground">{restaurantName}</p>
        </div>
        <Button
          onClick={() => {
            setEditingItem(null);
            setShowForm(!showForm);
          }}
          className="gap-2 bg-orange-600 hover:bg-orange-700"
        >
          <Plus className="w-4 h-4" />
          Add Item
        </Button>
      </div>

      {/* Add/Edit Form */}
      <AnimatePresence>
        {showForm && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <MenuItemForm
              item={editingItem}
              onSave={handleSaveItem}
              onCancel={() => {
                setShowForm(false);
                setEditingItem(null);
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Category Tabs */}
      <Tabs
        value={selectedCategory}
        onValueChange={setSelectedCategory}
        className="w-full"
      >
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="All">All</TabsTrigger>
          {categories.map((cat) => (
            <TabsTrigger key={cat} value={cat} className="text-xs">
              {cat}
            </TabsTrigger>
          ))}
        </TabsList>
      </Tabs>

      {/* Menu Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredItems.length === 0 ? (
          <Card className="col-span-full">
            <CardContent className="pt-12 pb-12 text-center">
              <UtensilsCrossed className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
              <p className="text-muted-foreground mb-4">No items in this category</p>
              <Button onClick={() => setShowForm(true)}>Add First Item</Button>
            </CardContent>
          </Card>
        ) : (
          filteredItems.map((item) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
            >
              <Card className="h-full flex flex-col overflow-hidden hover:shadow-lg transition-shadow">
                {/* Image */}
                {item.image ? (
                  <div className="relative h-32 bg-muted overflow-hidden">
                    <img
                      src={item.image}
                      alt={item.name}
                      className="w-full h-full object-cover"
                    />
                    <Badge
                      className="absolute top-2 right-2"
                      variant={item.isAvailable ? 'default' : 'secondary'}
                    >
                      {item.isAvailable ? 'Available' : 'Out of Stock'}
                    </Badge>
                  </div>
                ) : (
                  <div className="h-32 bg-gradient-to-br from-orange-100 to-orange-50 flex items-center justify-center">
                    <ImageIcon className="w-8 h-8 text-muted-foreground opacity-50" />
                  </div>
                )}

                <CardHeader className="pb-2">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <CardTitle className="flex items-center gap-2">
                        {item.name}
                        {item.spicy && item.spicy > 0 && (
                          <span className="text-red-500">{'🌶️'.repeat(item.spicy)}</span>
                        )}
                      </CardTitle>
                      <CardDescription className="text-xs italic">
                        {item.category}
                      </CardDescription>
                    </div>
                  </div>
                </CardHeader>

                <CardContent className="flex-1 space-y-3">
                  {/* Description */}
                  <p className="text-sm text-muted-foreground line-clamp-2">
                    {item.description}
                  </p>

                  {/* Details Grid */}
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-1 text-sm font-bold text-orange-600">
                      <DollarSign className="w-4 h-4" />
                      K{item.price}
                    </div>
                    <div className="text-xs text-muted-foreground">
                      ⏱️ {item.prepTime}min
                    </div>
                  </div>
                </CardContent>

                {/* Actions */}
                <div className="border-t p-2 space-y-2">
                  <div className="flex gap-1">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1 text-xs"
                      onClick={() => {
                        setEditingItem(item);
                        setShowForm(true);
                      }}
                    >
                      <Edit2 className="w-3 h-3 mr-1" />
                      Edit
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1 text-xs"
                      onClick={() => handleToggleAvailability(item)}
                    >
                      {item.isAvailable ? (
                        <>
                          <EyeOff className="w-3 h-3" />
                        </>
                      ) : (
                        <>
                          <Eye className="w-3 h-3" />
                        </>
                      )}
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      className="flex-1 text-xs"
                      onClick={() => handleDeleteItem(item.id)}
                    >
                      <Trash2 className="w-3 h-3" />
                    </Button>
                  </div>
                </div>
              </Card>
            </motion.div>
          ))
        )}
      </div>
    </div>
  );
};

interface MenuItemFormProps {
  item: MenuItem | null;
  onSave: (item: MenuItem) => void;
  onCancel: () => void;
}

const MenuItemForm: React.FC<MenuItemFormProps> = ({ item, onSave, onCancel }) => {
  const [formData, setFormData] = useState<MenuItem>(
    item || {
      id: `new-${Date.now()}`,
      name: '',
      description: '',
      price: 0,
      image: '',
      category: 'Main Course',
      isAvailable: true,
      prepTime: 15,
      spicy: 0,
    }
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>{item ? 'Edit Menu Item' : 'Add New Item'}</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="text-sm font-medium">Item Name *</label>
            <input
              type="text"
              value={formData.name}
              onChange={(e) => setFormData({ ...formData, name: e.target.value })}
              placeholder="e.g., Nshima with Relish"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
              required
            />
          </div>

          <div>
            <label className="text-sm font-medium">Category</label>
            <select
              value={formData.category}
              onChange={(e) =>
                setFormData({ ...formData, category: e.target.value })
              }
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            >
              {categories.map((cat) => (
                <option key={cat} value={cat}>
                  {cat}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="text-sm font-medium">Price (K) *</label>
            <input
              type="number"
              value={formData.price}
              onChange={(e) =>
                setFormData({ ...formData, price: parseInt(e.target.value) || 0 })
              }
              placeholder="0"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
              required
            />
          </div>

          <div>
            <label className="text-sm font-medium">Prep Time (mins)</label>
            <input
              type="number"
              value={formData.prepTime}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  prepTime: parseInt(e.target.value) || 15,
                })
              }
              min="1"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Spicy Level (0-5)</label>
            <input
              type="number"
              value={formData.spicy || 0}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  spicy: Math.min(5, parseInt(e.target.value) || 0),
                })
              }
              min="0"
              max="5"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Image URL</label>
            <input
              type="url"
              value={formData.image}
              onChange={(e) => setFormData({ ...formData, image: e.target.value })}
              placeholder="https://..."
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>

        <div>
          <label className="text-sm font-medium">Description</label>
          <textarea
            value={formData.description}
            onChange={(e) =>
              setFormData({ ...formData, description: e.target.value })
            }
            placeholder="Item description..."
            rows={3}
            className="mt-1 w-full px-3 py-2 border rounded-lg"
          />
        </div>

        {/* Buttons */}
        <div className="flex gap-2 pt-4">
          <Button onClick={onCancel} variant="outline" className="flex-1">
            <X className="w-4 h-4 mr-2" />
            Cancel
          </Button>
          <Button onClick={() => onSave(formData)} className="flex-1 bg-orange-600 hover:bg-orange-700">
            <Save className="w-4 h-4 mr-2" />
            Save Item
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default RestaurantMenuManagement;
