import { Restaurant, MenuItem } from '@/types/order';

// Generate realistic menu items for Zambian restaurants
const generateMenu = (restaurantType: string): MenuItem[] => {
  const menus: Record<string, MenuItem[]> = {
    local: [
      { id: 'nshima-beef', name: 'Nshima with Beef Stew', description: 'Traditional nshima with slow-cooked beef', price: 35, category: 'Main', available: true },
      { id: 'nshima-chicken', name: 'Nshima with Grilled Chicken', description: 'Nshima served with village chicken', price: 40, category: 'Main', available: true },
      { id: 'nshima-fish', name: 'Nshima with Bream', description: 'Fresh bream from Lake Kariba', price: 45, category: 'Main', available: true },
      { id: 'kapenta', name: 'Kapenta with Vegetables', description: 'Dried kapenta with seasonal vegetables', price: 28, category: 'Main', available: true },
      { id: 'ifisashi', name: 'Ifisashi', description: 'Traditional peanut vegetable stew', price: 25, category: 'Side', available: true },
      { id: 'chibwabwa', name: 'Chibwabwa', description: 'Pumpkin leaves with groundnuts', price: 20, category: 'Side', available: true },
      { id: 'munkoyo', name: 'Munkoyo', description: 'Traditional fermented drink', price: 10, category: 'Drink', available: true },
    ],
    grill: [
      { id: 'grilled-t-bone', name: 'T-Bone Steak', description: '400g grass-fed beef steak', price: 85, category: 'Main', available: true },
      { id: 'grilled-ribs', name: 'Pork Ribs', description: 'BBQ glazed pork ribs', price: 75, category: 'Main', available: true },
      { id: 'mixed-grill', name: 'Mixed Grill Platter', description: 'Beef, chicken, pork & sausage', price: 95, category: 'Main', available: true },
      { id: 'grilled-chicken', name: 'Flame Grilled Chicken', description: 'Half chicken with peri-peri', price: 55, category: 'Main', available: true },
      { id: 'chips', name: 'Chunky Chips', description: 'Hand-cut potato chips', price: 18, category: 'Side', available: true },
      { id: 'coleslaw', name: 'Fresh Coleslaw', description: 'Creamy cabbage slaw', price: 15, category: 'Side', available: true },
      { id: 'castle', name: 'Castle Lager', description: '500ml bottle', price: 20, category: 'Drink', available: true },
    ],
    fastfood: [
      { id: 'burger-classic', name: 'Classic Beef Burger', description: 'Beef patty with fresh toppings', price: 45, category: 'Main', available: true },
      { id: 'burger-chicken', name: 'Crispy Chicken Burger', description: 'Fried chicken with mayo', price: 40, category: 'Main', available: true },
      { id: 'wrap', name: 'Chicken Wrap', description: 'Grilled chicken in tortilla', price: 35, category: 'Main', available: true },
      { id: 'nuggets', name: 'Chicken Nuggets (8pc)', description: 'Crispy nuggets with sauce', price: 30, category: 'Main', available: true },
      { id: 'fries', name: 'French Fries', description: 'Regular portion', price: 15, category: 'Side', available: true },
      { id: 'soda', name: 'Coca-Cola', description: '500ml bottle', price: 12, category: 'Drink', available: true },
      { id: 'milkshake', name: 'Chocolate Milkshake', description: 'Thick & creamy', price: 25, category: 'Drink', available: true },
    ],
    cafe: [
      { id: 'breakfast', name: 'Full English Breakfast', description: 'Eggs, bacon, sausage, beans & toast', price: 55, category: 'Main', available: true },
      { id: 'pancakes', name: 'Pancake Stack', description: 'With maple syrup & berries', price: 40, category: 'Main', available: true },
      { id: 'sandwich', name: 'Club Sandwich', description: 'Triple-decker with chips', price: 45, category: 'Main', available: true },
      { id: 'salad', name: 'Caesar Salad', description: 'With grilled chicken', price: 42, category: 'Main', available: true },
      { id: 'espresso', name: 'Espresso', description: 'Double shot', price: 18, category: 'Drink', available: true },
      { id: 'cappuccino', name: 'Cappuccino', description: 'With steamed milk', price: 25, category: 'Drink', available: true },
      { id: 'smoothie', name: 'Tropical Smoothie', description: 'Mango, pineapple & banana', price: 28, category: 'Drink', available: true },
    ],
  };

  return menus[restaurantType] || menus.local;
};

// Restaurant names by type
const restaurantNames: Record<string, string[]> = {
  local: ['Mama Africa Kitchen', 'Village Pot', 'Zambian Flavors', 'Tonga Taste', 'Bush Kitchen'],
  grill: ['Smokin\' Grill House', 'Prime Cuts', 'Safari Steakhouse', 'Cattle Baron', 'Fire & Smoke'],
  fastfood: ['Hungry Lion', 'Quick Bites', 'Tasty Express', 'Street Corner', 'Fast & Fresh'],
  cafe: ['Coffee Culture', 'The Bean House', 'Morning Glory Cafe', 'Urban Grind', 'Sunrise Deli'],
};

const cuisines: Record<string, string> = {
  local: 'Zambian',
  grill: 'Steakhouse',
  fastfood: 'Fast Food',
  cafe: 'Cafe',
};

const priceRanges: Record<string, string> = {
  local: '$',
  grill: '$$$',
  fastfood: '$',
  cafe: '$$',
};

// Generate restaurants for a town
export const generateRestaurantsForTown = (townId: string, townName: string): Restaurant[] => {
  const restaurants: Restaurant[] = [];
  const types = ['local', 'grill', 'fastfood', 'cafe'];
  
  // Generate 2-4 restaurants per town based on town name hash for consistency
  const numRestaurants = 2 + (townName.length % 3);
  
  for (let i = 0; i < numRestaurants; i++) {
    const type = types[i % types.length];
    const nameOptions = restaurantNames[type];
    const name = nameOptions[(townName.charCodeAt(0) + i) % nameOptions.length];
    
    restaurants.push({
      id: `${townId}-restaurant-${i}`,
      name: `${name}`,
      townId,
      rating: 3.5 + ((townName.charCodeAt(0) + i) % 15) / 10,
      priceRange: priceRanges[type],
      cuisine: cuisines[type],
      eta: 10 + (i * 5),
      menu: generateMenu(type),
    });
  }
  
  return restaurants;
};
