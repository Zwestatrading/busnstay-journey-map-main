import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { 
  Bed, Lock, Unlock, Plus, Edit2, Trash2, Image as ImageIcon, 
  AlertCircle, CheckCircle2, Loader2, Save, X
} from 'lucide-react';
import { supabase } from '@/lib/supabase';
import { useToast } from '@/hooks/use-toast';

interface HotelRoom {
  id: string;
  roomNumber: string;
  roomType: 'single' | 'double' | 'suite' | 'dormitory';
  capacity: number;
  price: number;
  totalRooms: number;
  availableRooms: number;
  amenities: string[];
  images: string[];
  isActive: boolean;
  description?: string;
}

interface HotelRoomManagementProps {
  hotelId: string;
  hotelName: string;
}

const roomTypeIcons: Record<string, string> = {
  single: '🛏️',
  double: '👥',
  suite: '🏨',
  dormitory: '🏛️',
};

export const HotelRoomManagement: React.FC<HotelRoomManagementProps> = ({
  hotelId,
  hotelName,
}) => {
  const { toast } = useToast();
  const [rooms, setRooms] = useState<HotelRoom[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingRoom, setEditingRoom] = useState<HotelRoom | null>(null);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    fetchRooms();
  }, [hotelId]);

  const fetchRooms = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('hotel_rooms')
        .select('*')
        .eq('hotel_id', hotelId)
        .order('room_number');

      if (error) throw error;

      setRooms(
        (data || []).map((room: any) => ({
          id: room.id,
          roomNumber: room.room_number,
          roomType: room.room_type,
          capacity: room.capacity,
          price: room.price,
          totalRooms: room.total_rooms,
          availableRooms: room.available_rooms,
          amenities: room.amenities || [],
          images: room.images || [],
          isActive: room.is_active,
          description: room.description,
        }))
      );
    } catch (error) {
      toast({
        title: 'Error loading rooms',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    } finally {
      setLoading(false);
    }
  };

  const handleSaveRoom = async (room: HotelRoom) => {
    try {
      if (room.id.startsWith('new-')) {
        // Create new room
        const { error } = await supabase.from('hotel_rooms').insert({
          hotel_id: hotelId,
          room_number: room.roomNumber,
          room_type: room.roomType,
          capacity: room.capacity,
          price: room.price,
          total_rooms: room.totalRooms,
          available_rooms: room.availableRooms,
          amenities: room.amenities,
          images: room.images,
          is_active: room.isActive,
          description: room.description,
        });

        if (error) throw error;
      } else {
        // Update existing room
        const { error } = await supabase
          .from('hotel_rooms')
          .update({
            room_number: room.roomNumber,
            room_type: room.roomType,
            capacity: room.capacity,
            price: room.price,
            total_rooms: room.totalRooms,
            available_rooms: room.availableRooms,
            amenities: room.amenities,
            images: room.images,
            is_active: room.isActive,
            description: room.description,
          })
          .eq('id', room.id);

        if (error) throw error;
      }

      toast({
        title: 'Room saved',
        description: `${room.roomNumber} has been saved successfully`,
      });

      await fetchRooms();
      setEditingRoom(null);
      setShowForm(false);
    } catch (error) {
      toast({
        title: 'Error saving room',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const handleDeleteRoom = async (roomId: string) => {
    if (!confirm('Are you sure you want to delete this room?')) return;

    try {
      const { error } = await supabase
        .from('hotel_rooms')
        .delete()
        .eq('id', roomId);

      if (error) throw error;

      toast({
        title: 'Room deleted',
        description: 'The room has been removed',
      });

      await fetchRooms();
    } catch (error) {
      toast({
        title: 'Error deleting room',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  const handleToggleAvailability = async (room: HotelRoom) => {
    const newStatus = !room.isActive;
    try {
      const { error } = await supabase
        .from('hotel_rooms')
        .update({ is_active: newStatus })
        .eq('id', room.id);

      if (error) throw error;

      setRooms(
        rooms.map((r) =>
          r.id === room.id ? { ...r, isActive: newStatus } : r
        )
      );

      toast({
        title: newStatus ? 'Room activated' : 'Room deactivated',
        description: `${room.roomNumber} is now ${newStatus ? 'available' : 'booked out'}`,
      });
    } catch (error) {
      toast({
        title: 'Error updating room status',
        description: error instanceof Error ? error.message : 'Unknown error',
        variant: 'destructive',
      });
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="w-5 h-5 animate-spin mr-2" />
        <span>Loading rooms...</span>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-display font-bold">Room Management</h2>
          <p className="text-sm text-muted-foreground">{hotelName}</p>
        </div>
        <Button
          onClick={() => {
            setEditingRoom(null);
            setShowForm(!showForm);
          }}
          className="gap-2"
        >
          <Plus className="w-4 h-4" />
          Add Room Type
        </Button>
      </div>

      {/* Add/Edit Room Form */}
      <AnimatePresence>
        {showForm && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
          >
            <RoomForm
              room={editingRoom}
              onSave={handleSaveRoom}
              onCancel={() => {
                setShowForm(false);
                setEditingRoom(null);
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Rooms Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {rooms.length === 0 ? (
          <Card className="col-span-full">
            <CardContent className="pt-12 pb-12 text-center">
              <Bed className="w-12 h-12 text-muted-foreground mx-auto mb-4 opacity-50" />
              <p className="text-muted-foreground mb-4">No rooms added yet</p>
              <Button onClick={() => setShowForm(true)}>Add Your First Room</Button>
            </CardContent>
          </Card>
        ) : (
          rooms.map((room) => (
            <motion.div
              key={room.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -20 }}
            >
              <Card className="h-full flex flex-col">
                <CardHeader className="pb-3">
                  <div className="flex items-start justify-between">
                    <div>
                      <CardTitle className="flex items-center gap-2">
                        <span className="text-2xl">
                          {roomTypeIcons[room.roomType] || '🏨'}
                        </span>
                        {room.roomNumber}
                      </CardTitle>
                      <CardDescription>{room.roomType}</CardDescription>
                    </div>
                    <Badge
                      variant={room.isActive ? 'default' : 'secondary'}
                      className="gap-1"
                    >
                      {room.isActive ? (
                        <>
                          <Unlock className="w-3 h-3" />
                          Available
                        </>
                      ) : (
                        <>
                          <Lock className="w-3 h-3" />
                          Fully Booked
                        </>
                      )}
                    </Badge>
                  </div>
                </CardHeader>

                <CardContent className="flex-1 space-y-4">
                  {/* Details */}
                  <div className="grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <p className="text-muted-foreground">Capacity</p>
                      <p className="font-bold">{room.capacity} guests</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Price</p>
                      <p className="font-bold">K{room.price}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Total</p>
                      <p className="font-bold">{room.totalRooms} room{room.totalRooms > 1 ? 's' : ''}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground">Available</p>
                      <p className="font-bold text-green-600">
                        {room.availableRooms} / {room.totalRooms}
                      </p>
                    </div>
                  </div>

                  {/* Amenities */}
                  {room.amenities.length > 0 && (
                    <div className="space-y-2">
                      <p className="text-xs font-semibold text-muted-foreground">Amenities</p>
                      <div className="flex flex-wrap gap-2">
                        {room.amenities.slice(0, 3).map((amenity, idx) => (
                          <Badge key={idx} variant="outline" className="text-xs">
                            {amenity}
                          </Badge>
                        ))}
                        {room.amenities.length > 3 && (
                          <Badge variant="outline" className="text-xs">
                            +{room.amenities.length - 3}
                          </Badge>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Images */}
                  {room.images.length > 0 && (
                    <div className="flex items-center gap-2 text-xs text-muted-foreground">
                      <ImageIcon className="w-4 h-4" />
                      {room.images.length} image{room.images.length > 1 ? 's' : ''}
                    </div>
                  )}
                </CardContent>

                {/* Actions */}
                <div className="border-t p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-xs font-medium">Full?</span>
                    <Switch
                      checked={!room.isActive}
                      onCheckedChange={() => handleToggleAvailability(room)}
                    />
                  </div>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      className="flex-1"
                      onClick={() => {
                        setEditingRoom(room);
                        setShowForm(true);
                      }}
                    >
                      <Edit2 className="w-3 h-3 mr-1" />
                      Edit
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      className="flex-1"
                      onClick={() => handleDeleteRoom(room.id)}
                    >
                      <Trash2 className="w-3 h-3 mr-1" />
                      Delete
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

interface RoomFormProps {
  room: HotelRoom | null;
  onSave: (room: HotelRoom) => void;
  onCancel: () => void;
}

const RoomForm: React.FC<RoomFormProps> = ({ room, onSave, onCancel }) => {
  const [formData, setFormData] = useState<HotelRoom>(
    room || {
      id: `new-${Date.now()}`,
      roomNumber: '',
      roomType: 'double',
      capacity: 2,
      price: 0,
      totalRooms: 1,
      availableRooms: 1,
      amenities: [],
      images: [],
      isActive: true,
    }
  );

  return (
    <Card>
      <CardHeader>
        <CardTitle>
          {room ? 'Edit Room' : 'Add New Room Type'}
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="text-sm font-medium">Room Number/Name</label>
            <input
              type="text"
              value={formData.roomNumber}
              onChange={(e) =>
                setFormData({ ...formData, roomNumber: e.target.value })
              }
              placeholder="e.g., 101, Deluxe Double"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Room Type</label>
            <select
              value={formData.roomType}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  roomType: e.target.value as HotelRoom['roomType'],
                })
              }
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            >
              <option value="single">Single</option>
              <option value="double">Double</option>
              <option value="suite">Suite</option>
              <option value="dormitory">Dormitory</option>
            </select>
          </div>

          <div>
            <label className="text-sm font-medium">Price (K)</label>
            <input
              type="number"
              value={formData.price}
              onChange={(e) =>
                setFormData({ ...formData, price: parseInt(e.target.value) || 0 })
              }
              placeholder="0"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Capacity</label>
            <input
              type="number"
              value={formData.capacity}
              onChange={(e) =>
                setFormData({ ...formData, capacity: parseInt(e.target.value) || 1 })
              }
              min="1"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Total Rooms</label>
            <input
              type="number"
              value={formData.totalRooms}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  totalRooms: parseInt(e.target.value) || 1,
                })
              }
              min="1"
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>

          <div>
            <label className="text-sm font-medium">Available</label>
            <input
              type="number"
              value={formData.availableRooms}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  availableRooms: parseInt(e.target.value) || 0,
                })
              }
              min="0"
              max={formData.totalRooms}
              className="mt-1 w-full px-3 py-2 border rounded-lg"
            />
          </div>
        </div>

        {/* Buttons */}
        <div className="flex gap-2 pt-4">
          <Button onClick={onCancel} variant="outline" className="flex-1">
            <X className="w-4 h-4 mr-2" />
            Cancel
          </Button>
          <Button
            onClick={() => onSave(formData)}
            className="flex-1"
          >
            <Save className="w-4 h-4 mr-2" />
            Save Room
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};

export default HotelRoomManagement;
