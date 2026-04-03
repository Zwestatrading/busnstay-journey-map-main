import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing restaurant menus with professional images
class MenuManagementService {
  final SupabaseClient supabase;

  MenuManagementService({required this.supabase});

  /// Menu item model
  Future<List<MenuItem>> getMenuItems(String restaurantId) async {
    try {
      final data = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('category')
          .order('name');

      return (data as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error fetching menu items: $e');
      return [];
    }
  }

  /// Get menu items by category
  Future<List<MenuItem>> getMenuItemsByCategory({
    required String restaurantId,
    required String category,
  }) async {
    try {
      final data = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('category', category)
          .eq('is_available', true)
          .order('name');

      return (data as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error fetching menu items by category: $e');
      return [];
    }
  }

  /// Get all categories for a restaurant
  Future<List<MenuCategory>> getCategories(String restaurantId) async {
    try {
      final data = await supabase
          .from('menu_categories')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('display_order');

      return (data as List)
          .map((cat) => MenuCategory.fromJson(cat))
          .toList();
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }

  /// Upload menu item image
  Future<String?> uploadMenuItemImage({
    required File imageFile,
    required String restaurantId,
    required String itemId,
  }) async {
    try {
      final fileName = 'menu_$restaurantId\_$itemId\_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.storage.from('menu_images').upload(
        'restaurants/$restaurantId/$fileName',
        imageFile,
      );

      final publicUrl = supabase.storage
          .from('menu_images')
          .getPublicUrl('restaurants/$restaurantId/$fileName');

      print('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }

  /// Upload menu item image from bytes so it works on mobile and web.
  Future<String?> uploadMenuItemImageBytes({
    required Uint8List bytes,
    required String restaurantId,
    required String itemId,
    String extension = 'jpg',
  }) async {
    try {
      final fileName =
          'menu_${restaurantId}_${itemId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final path = 'restaurants/$restaurantId/$fileName';

      await supabase.storage.from('menu_images').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      return supabase.storage.from('menu_images').getPublicUrl(path);
    } catch (e) {
      print('❌ Error uploading image bytes: $e');
      return null;
    }
  }

  /// Create new menu item
  Future<MenuItem?> createMenuItem({
    required String restaurantId,
    required String name,
    required String category,
    required double price,
    required String description,
    String? imageUrl,
    int? preparationTimeMinutes,
    double? rating,
    bool isVegetarian = false,
    bool isSpicy = false,
  }) async {
    try {
      final response = await supabase.from('menu_items').insert({
        'restaurant_id': restaurantId,
        'name': name,
        'category': category,
        'price': price,
        'description': description,
        'image_url': imageUrl,
        'preparation_time_minutes': preparationTimeMinutes,
        'rating': rating ?? 0.0,
        'is_vegetarian': isVegetarian,
        'is_spicy': isSpicy,
        'is_available': true,
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      if (response.isNotEmpty) {
        print('✅ Menu item created: $name');
        return MenuItem.fromJson(response.first);
      }
    } catch (e) {
      print('❌ Error creating menu item: $e');
    }
    return null;
  }

  /// Update menu item
  Future<bool> updateMenuItem({
    required String itemId,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    bool? isAvailable,
    int? preparationTimeMinutes,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (isAvailable != null) updateData['is_available'] = isAvailable;
      if (preparationTimeMinutes != null) {
        updateData['preparation_time_minutes'] = preparationTimeMinutes;
      }

      await supabase
          .from('menu_items')
          .update(updateData)
          .eq('id', itemId);

      print('✅ Menu item updated: $itemId');
      return true;
    } catch (e) {
      print('❌ Error updating menu item: $e');
      return false;
    }
  }

  /// Delete menu item
  Future<bool> deleteMenuItem(String itemId) async {
    try {
      await supabase
          .from('menu_items')
          .delete()
          .eq('id', itemId);

      print('✅ Menu item deleted: $itemId');
      return true;
    } catch (e) {
      print('❌ Error deleting menu item: $e');
      return false;
    }
  }

  /// Search menu items
  Future<List<MenuItem>> searchMenuItems({
    required String restaurantId,
    required String query,
  }) async {
    try {
      final data = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_available', true)
          .ilike('name', '%$query%');

      return (data as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error searching menu items: $e');
      return [];
    }
  }

  /// Add menu rating/review from customer
  Future<bool> rateMenuItem({
    required String itemId,
    required double rating,
    required String customerId,
    String? review,
  }) async {
    try {
      await supabase.from('menu_ratings').insert({
        'menu_item_id': itemId,
        'customer_id': customerId,
        'rating': rating,
        'review': review,
        'created_at': DateTime.now().toIso8601String(),
      });

      print('✅ Rating added: $itemId - $rating/5');
      return true;
    } catch (e) {
      print('❌ Error adding rating: $e');
      return false;
    }
  }
}

/// MenuItem model
class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String category;
  final double price;
  final String description;
  final String? imageUrl;
  final int preparationTimeMinutes;
  final double rating;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isSpicy;
  final DateTime createdAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    this.imageUrl,
    required this.preparationTimeMinutes,
    required this.rating,
    required this.isAvailable,
    required this.isVegetarian,
    required this.isSpicy,
    required this.createdAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      name: json['name'] ?? 'Unknown',
      category: json['category'] ?? 'Uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] ?? '',
      imageUrl: json['image_url'],
      preparationTimeMinutes: json['preparation_time_minutes'] as int? ?? 15,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] as bool? ?? true,
      isVegetarian: json['is_vegetarian'] as bool? ?? false,
      isSpicy: json['is_spicy'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'category': category,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'preparation_time_minutes': preparationTimeMinutes,
      'rating': rating,
      'is_available': isAvailable,
      'is_vegetarian': isVegetarian,
      'is_spicy': isSpicy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// MenuCategory model
class MenuCategory {
  final String id;
  final String restaurantId;
  final String name;
  final String? description;
  final String? imageUrl;
  final int displayOrder;

  MenuCategory({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.displayOrder,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] ?? '',
      restaurantId: json['restaurant_id'] ?? '',
      name: json['name'] ?? 'Uncategorized',
      description: json['description'],
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }
}
