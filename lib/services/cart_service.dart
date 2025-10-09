// services/cart_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService {
  static const String baseUrl = 'http://localhost:3000/api'; // Ganti dengan URL API Anda
  
  // Headers untuk API request
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Get cart untuk user tertentu
  static Future<Cart> getCart(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cart.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        // Cart belum ada, return cart kosong
        return Cart(
          userId: userId,
          items: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw Exception('Failed to load cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cart: $e');
    }
  }

  // Add item to cart
  static Future<Cart> addToCart({
    required String userId,
    required Product product,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'product_id': product,
        'product_name': product.name,
        'product_image': product.imageUrl,
        'price': product.price,
        'quantity': quantity,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/cart/add'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        throw Exception('Failed to add to cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }

  // Update item quantity in cart
  static Future<Cart> updateCartItem({
    required String userId,
    required String cartItemId,
    required int quantity,
  }) async {
    try {
      final requestBody = {
        'quantity': quantity,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/cart/$userId/item/$cartItemId'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        throw Exception('Failed to update cart item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  // Remove item from cart
  static Future<Cart> removeFromCart({
    required String userId,
    required String cartItemId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$userId/item/$cartItemId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Cart.fromJson(data['data']);
      } else {
        throw Exception('Failed to remove from cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing from cart: $e');
    }
  }

  // Clear entire cart
  static Future<void> clearCart(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/$userId/clear'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear cart: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  // Create order from cart
  static Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String deliveryAddress,
    required String paymentMethod,
    String? notes,
  }) async {
    try {
      final requestBody = {
        'user_id': userId,
        'delivery_address': deliveryAddress,
        'payment_method': paymentMethod,
        'notes': notes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/orders/create'),
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }
}