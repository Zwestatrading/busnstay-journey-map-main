import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import {
  Bed, Plus, Edit2, Trash2, DollarSign, Users,
  CheckCircle2, Loader2
} from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import {
  getHotelRooms,
  createHotelRoom,
  updateHotelRoom,
  deleteHotelRoom,
  toggleRoomActiveStatus,
  updateRoomOccupancy,
  HotelRoom,
} from '@/services/hotelRoomService';

interface RoomManagementTabProps {
  accommodationId: string;
}

const ROOM_TYPES = ['single', 'double', 'twin', 'suite', 'family', 'dormitory'] as const;

const OCCUPANCY_STATUSES = ['available', 'occupied', 'maintenance', 'reserved'] as const;

const occupancyColors: Record<string, string> = {
  available: 'bg-green-100 text-green-800',
  occupied: 'bg-red-100 text-red-800',
  maintenance: 'bg-yellow-100 text-yellow-800',
  reserved: 'bg-blue-100 text-blue-800',
};

const defaultFormData = {
  room_number: '',
  room_type: 'double' as const,
  capacity: 2,
  price_per_night: 0,
  base_price: 0,
  description: '',
  amenities: [] as string[],
  is_active: true,
};

export const RoomManagementTab = ({ accommodationId }: RoomManagementTabProps) => {
  const { toast } = useToast();
  const [rooms, setRooms] = useState<HotelRoom[]>([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingRoom, setEditingRoom] = useState<HotelRoom | null>(null);
  const [saving, setSaving] = useState(false);
  const [formData, setFormData] = useState(defaultFormData);
  const [amenityInput, setAmenityInput] = useState('');

  useEffect(() => {
    loadRooms();
  }, [accommodationId]);

  const loadRooms = async () => {
    setLoading(true);
    try {
      const data = await getHotelRooms(accommodationId);
      setRooms(data);
    } catch {
      toast({ title: 'Error loading rooms', variant: 'destructive' });
    } finally {
      setLoading(false);
    }
  };

  const openAddDialog = () => {
    setEditingRoom(null);
    setFormData(defaultFormData);
    setDialogOpen(true);
  };

  const openEditDialog = (room: HotelRoom) => {
    setEditingRoom(room);
    setFormData({
      room_number: room.room_number,
      room_type: room.room_type,
      capacity: room.capacity,
      price_per_night: room.price_per_night,
      base_price: room.base_price,
      description: room.description || '',
      amenities: room.amenities || [],
      is_active: room.is_active,
    });
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (!formData.room_number || !formData.price_per_night) {
      toast({ title: 'Room number and price are required', variant: 'destructive' });
      return;
    }
    setSaving(true);
    try {
      if (editingRoom) {
        await updateHotelRoom(editingRoom.id, {
          room_number: formData.room_number,
          room_type: formData.room_type,
          capacity: formData.capacity,
          price_per_night: formData.price_per_night,
          base_price: formData.base_price || formData.price_per_night,
          description: formData.description,
          amenities: formData.amenities,
          is_active: formData.is_active,
        });
        toast({ title: 'Room updated successfully' });
      } else {
        await createHotelRoom({
          accommodation_id: accommodationId,
          room_number: formData.room_number,
          room_type: formData.room_type,
          capacity: formData.capacity,
          price_per_night: formData.price_per_night,
          base_price: formData.base_price || formData.price_per_night,
          description: formData.description,
          amenities: formData.amenities,
          is_active: formData.is_active,
        });
        toast({ title: 'Room created successfully' });
      }
      setDialogOpen(false);
      loadRooms();
    } catch {
      toast({ title: 'Error saving room', variant: 'destructive' });
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async (roomId: string) => {
    if (!confirm('Are you sure you want to delete this room?')) return;
    try {
      const result = await deleteHotelRoom(roomId);
      if (result.success) {
        toast({ title: 'Room deleted' });
        loadRooms();
      } else {
        toast({ title: result.error || 'Delete failed', variant: 'destructive' });
      }
    } catch {
      toast({ title: 'Error deleting room', variant: 'destructive' });
    }
  };

  const handleToggleActive = async (roomId: string, currentStatus: boolean) => {
    try {
      await toggleRoomActiveStatus(roomId, !currentStatus);
      toast({ title: `Room ${!currentStatus ? 'activated' : 'deactivated'}` });
      loadRooms();
    } catch {
      toast({ title: 'Error toggling room status', variant: 'destructive' });
    }
  };

  const handleOccupancyChange = async (roomId: string, status: string) => {
    try {
      await updateRoomOccupancy(roomId, status as HotelRoom['occupancy_status']);
      toast({ title: `Status updated to ${status}` });
      loadRooms();
    } catch {
      toast({ title: 'Error updating occupancy', variant: 'destructive' });
    }
  };

  const addAmenity = () => {
    if (amenityInput.trim() && !formData.amenities.includes(amenityInput.trim())) {
      setFormData({ ...formData, amenities: [...formData.amenities, amenityInput.trim()] });
      setAmenityInput('');
    }
  };

  const removeAmenity = (amenity: string) => {
    setFormData({ ...formData, amenities: formData.amenities.filter(a => a !== amenity) });
  };

  const totalRooms = rooms.length;
  const activeRooms = rooms.filter(r => r.is_active).length;
  const occupiedRooms = rooms.filter(r => r.occupancy_status === 'occupied').length;
  const totalValue = rooms.reduce((sum, r) => sum + r.price_per_night, 0);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-4 pb-4">
            <div className="flex items-center space-x-2">
              <Bed className="h-5 w-5 text-blue-500" />
              <div>
                <p className="text-sm text-gray-500">Total Rooms</p>
                <p className="text-2xl font-bold">{totalRooms}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4">
            <div className="flex items-center space-x-2">
              <CheckCircle2 className="h-5 w-5 text-green-500" />
              <div>
                <p className="text-sm text-gray-500">Active</p>
                <p className="text-2xl font-bold">{activeRooms}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4">
            <div className="flex items-center space-x-2">
              <Users className="h-5 w-5 text-orange-500" />
              <div>
                <p className="text-sm text-gray-500">Occupied</p>
                <p className="text-2xl font-bold">{occupiedRooms}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-4 pb-4">
            <div className="flex items-center space-x-2">
              <DollarSign className="h-5 w-5 text-emerald-500" />
              <div>
                <p className="text-sm text-gray-500">Total Value/Night</p>
                <p className="text-2xl font-bold">K{totalValue.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold">Rooms ({totalRooms})</h3>
        <Button onClick={openAddDialog} size="sm">
          <Plus className="h-4 w-4 mr-1" /> Add Room
        </Button>
      </div>

      {rooms.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <Bed className="h-12 w-12 mx-auto text-gray-300 mb-4" />
            <p className="text-gray-500">No rooms yet. Add your first room to get started.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {rooms.map((room) => (
            <motion.div key={room.id} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }}>
              <Card className={`${!room.is_active ? 'opacity-60' : ''}`}>
                <CardHeader className="pb-2">
                  <div className="flex items-center justify-between">
                    <CardTitle className="text-base">Room {room.room_number}</CardTitle>
                    <Badge className={occupancyColors[room.occupancy_status] || ''}>
                      {room.occupancy_status}
                    </Badge>
                  </div>
                  <CardDescription className="capitalize">{room.room_type} - {room.capacity} guests</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="text-sm text-gray-500">Price/Night</span>
                      <span className="font-semibold">K{room.price_per_night.toLocaleString()}</span>
                    </div>
                    {room.average_rating > 0 && (
                      <div className="flex items-center justify-between">
                        <span className="text-sm text-gray-500">Rating</span>
                        <span className="font-semibold">{room.average_rating.toFixed(1)}/5</span>
                      </div>
                    )}
                    <Select
                      value={room.occupancy_status}
                      onValueChange={(val) => handleOccupancyChange(room.id, val)}
                    >
                      <SelectTrigger className="h-8 text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        {OCCUPANCY_STATUSES.map((s) => (
                          <SelectItem key={s} value={s} className="capitalize">{s}</SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <div className="flex items-center justify-between pt-2 border-t">
                      <div className="flex items-center space-x-1">
                        <Switch
                          checked={room.is_active}
                          onCheckedChange={() => handleToggleActive(room.id, room.is_active)}
                        />
                        <span className="text-xs text-gray-500">{room.is_active ? 'Active' : 'Inactive'}</span>
                      </div>
                      <div className="flex space-x-1">
                        <Button variant="ghost" size="sm" onClick={() => openEditDialog(room)}>
                          <Edit2 className="h-3.5 w-3.5" />
                        </Button>
                        <Button variant="ghost" size="sm" onClick={() => handleDelete(room.id)} className="text-red-500 hover:text-red-700">
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-md max-h-[85vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editingRoom ? 'Edit Room' : 'Add New Room'}</DialogTitle>
            <DialogDescription>
              {editingRoom ? 'Update room details below.' : 'Fill in the details for the new room.'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <label className="text-sm font-medium">Room Number *</label>
              <Input
                value={formData.room_number}
                onChange={(e) => setFormData({ ...formData, room_number: e.target.value })}
                placeholder="e.g. 101"
              />
            </div>
            <div>
              <label className="text-sm font-medium">Room Type</label>
              <Select
                value={formData.room_type}
                onValueChange={(val) => setFormData({ ...formData, room_type: val as typeof formData.room_type })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {ROOM_TYPES.map((t) => (
                    <SelectItem key={t} value={t} className="capitalize">{t}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="text-sm font-medium">Capacity</label>
                <Input
                  type="number"
                  min={1}
                  value={formData.capacity}
                  onChange={(e) => setFormData({ ...formData, capacity: parseInt(e.target.value) || 1 })}
                />
              </div>
              <div>
                <label className="text-sm font-medium">Price/Night (ZMW) *</label>
                <Input
                  type="number"
                  min={0}
                  value={formData.price_per_night}
                  onChange={(e) => setFormData({ ...formData, price_per_night: parseFloat(e.target.value) || 0 })}
                />
              </div>
            </div>
            <div>
              <label className="text-sm font-medium">Description</label>
              <Textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Room description..."
                rows={3}
              />
            </div>
            <div>
              <label className="text-sm font-medium">Amenities</label>
              <div className="flex space-x-2 mb-2">
                <Input
                  value={amenityInput}
                  onChange={(e) => setAmenityInput(e.target.value)}
                  onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); addAmenity(); } }}
                  placeholder="WiFi, AC, TV..."
                />
                <Button type="button" variant="outline" size="sm" onClick={addAmenity}>Add</Button>
              </div>
              <div className="flex flex-wrap gap-1">
                {formData.amenities.map((a) => (
                  <Badge key={a} variant="secondary" className="cursor-pointer" onClick={() => removeAmenity(a)}>
                    {a} &times;
                  </Badge>
                ))}
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                checked={formData.is_active}
                onCheckedChange={(checked) => setFormData({ ...formData, is_active: checked })}
              />
              <label className="text-sm font-medium">Active</label>
            </div>
            <div className="flex justify-end space-x-2 pt-2">
              <Button variant="outline" onClick={() => setDialogOpen(false)}>Cancel</Button>
              <Button onClick={handleSave} disabled={saving}>
                {saving && <Loader2 className="h-4 w-4 mr-1 animate-spin" />}
                {editingRoom ? 'Update' : 'Create'}
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
};

export default RoomManagementTab;
