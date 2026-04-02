export type OrderStatus = 'pending' | 'preparing' | 'ready' | 'completed';

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  image?: string;
  available: boolean;
}

export interface CartItem {
  menuItem: MenuItem;
  quantity: number;
}

export interface PendingOrder {
  id: string;
  stationId: string;
  stationName: string;
  restaurantId: string;
  restaurantName: string;
  items: CartItem[];
  totalPrice: number;
  status: OrderStatus;
  orderedAt: Date;
  estimatedReadyTime?: Date;
}

export interface Restaurant {
  id: string;
  name: string;
  townId: string;
  rating: number;
  priceRange: string;
  cuisine: string;
  eta: number;
  menu: MenuItem[];
}
