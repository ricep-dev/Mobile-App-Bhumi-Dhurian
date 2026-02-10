// lib/services/api_baru.dart
import 'dart:convert';
import 'dart:io';
import 'package:bhumidurianapp/services/token.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiBaru {
  
  static const String baseUrl = 'http://192.168.31.101:9090/api/v1';

  // --------------------------
  // Auth & profile
  // --------------------------
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['token'] != null) {
        await TokenService.saveToken(responseData['token']);
        return {
          'success': true,
          'message': 'Login berhasil',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login gagal',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final token = await TokenService.getToken();
    if (token == null) {
      print("Token tidak ditemukan, pengguna harus login.");
      return null;
    }

    final url = Uri.parse('$baseUrl/me');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['data'] != null)
          return Map<String, dynamic>.from(data['data']);
        if (data is Map) return Map<String, dynamic>.from(data);
      } else {
        print('Gagal ambil data user: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan saat ambil data user: $e');
      return null;
    }
    return null;
  }

  // --------------------------
  // Products
  // --------------------------
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    final url = Uri.parse('$baseUrl/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) {
          return List<Map<String, dynamic>>.from(body);
        } else if (body is Map && body['products'] != null) {
          return List<Map<String, dynamic>>.from(body['products']);
        } else if (body is Map && body['data'] != null) {
          return List<Map<String, dynamic>>.from(body['data']);
        } else {
          return [];
        }
      } else {
        throw Exception(
          'Gagal memuat produk dari server: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error ambil semua produk: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getProductById(int id) async {
    final url = Uri.parse('$baseUrl/products/$id');
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['data'] != null)
          return Map<String, dynamic>.from(body['data']);
        if (body is Map) return Map<String, dynamic>.from(body);
      }
      return null;
    } catch (e) {
      print('getProductById error: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    final url = Uri.parse('$baseUrl/products/${Uri.encodeComponent(category)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return List<Map<String, dynamic>>.from(body);
        if (body is Map && body['products'] != null)
          return List<Map<String, dynamic>>.from(body['products']);
        if (body is Map && body['data'] != null)
          return List<Map<String, dynamic>>.from(body['data']);
      }
      return [];
    } catch (e) {
      print('getProductsByCategory error: $e');
      rethrow;
    }
  }

  // --------------------------
  // Order (multipart) - DENGAN BUKTI PEMBAYARAN
  // --------------------------
  static Future<Map<String, dynamic>> createOrder({
    required XFile buktiPembayaran,
    required String paymentMethod,
    required String orderType,
    required String itemsDataJson,
    String? shippingAddress,
    String? reservationTableNumber,
    String? reservationTime,
    String? reservationGuestCount,
    String? reservationSpecialRequest,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Otorisasi Gagal: Token tidak ditemukan.');
    }

    final url = Uri.parse('$baseUrl/orders');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['payment_method'] = paymentMethod;
    request.fields['order_type'] = orderType;
    request.fields['items_data'] = itemsDataJson;

    if (shippingAddress != null && shippingAddress.isNotEmpty) {
      request.fields['shipping_address'] = shippingAddress;
    }
    if (reservationTableNumber != null)
      request.fields['reservation_table_number'] = reservationTableNumber;
    if (reservationTime != null)
      request.fields['reservation_time'] = reservationTime;
    if (reservationGuestCount != null)
      request.fields['reservation_guest_count'] = reservationGuestCount;
    if (reservationSpecialRequest != null &&
        reservationSpecialRequest.isNotEmpty) {
      request.fields['reservation_special_request'] = reservationSpecialRequest;
    }

    final fileBytes = await buktiPembayaran.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'bukti_pembayaran',
      fileBytes,
      filename: buktiPembayaran.name,
    );
    request.files.add(multipartFile);

    try {
      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      final responseData = jsonDecode(resp.body);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return {'success': true, ...responseData};
      } else {
        throw Exception(
          responseData['detail'] ??
              responseData['error'] ??
              'Gagal membuat pesanan',
        );
      }
    } catch (e) {
      print('[CREATE ORDER ERROR]: $e');
      rethrow;
    }
  }

  // --------------------------
  // Order MIDTRANS - TANPA BUKTI PEMBAYARAN
  // --------------------------
  /// Membuat order dengan Midtrans (tanpa bukti pembayaran)
  /// Backend: POST /api/v1/orders
  static Future<Map<String, dynamic>> createOrderMidtrans({
    required String orderType,
    required String itemsDataJson,
    String? shippingAddress,
    String? reservationTableNumber,
    String? reservationTime,
    String? reservationGuestCount,
    String? reservationSpecialRequest,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Otorisasi Gagal: Token tidak ditemukan.');
    }

    final url = Uri.parse('$baseUrl/orders');
    
    try {
      final body = {
        'payment_method': 'midtrans',
        'order_type': orderType,
        'items_data': itemsDataJson,
      };

      if (shippingAddress != null && shippingAddress.isNotEmpty) {
        body['shipping_address'] = shippingAddress;
      }
      if (reservationTableNumber != null) {
        body['reservation_table_number'] = reservationTableNumber;
      }
      if (reservationTime != null) {
        body['reservation_time'] = reservationTime;
      }
      if (reservationGuestCount != null) {
        body['reservation_guest_count'] = reservationGuestCount;
      }
      if (reservationSpecialRequest != null && reservationSpecialRequest.isNotEmpty) {
        body['reservation_special_request'] = reservationSpecialRequest;
      }

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, ...responseData};
      } else {
        throw Exception(
          responseData['detail'] ??
              responseData['error'] ??
              'Gagal membuat pesanan Midtrans',
        );
      }
    } catch (e) {
      print('[CREATE ORDER MIDTRANS ERROR]: $e');
      rethrow;
    }
  }

  // --------------------------
  // MIDTRANS SNAP
  // --------------------------
  /// Membuat Midtrans Snap Token dari order_id yang sudah dibuat
  /// Backend: POST /api/v1/payment dengan body { "order_id": orderId }
  /// Response: { "snap_token": "..." }
  static Future<Map<String, dynamic>> createMidtransSnap({
    required int orderId,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final url = Uri.parse('$baseUrl/payment');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'order_id': orderId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Gagal membuat Snap Midtrans (${response.statusCode}): ${response.body}',
        );
      }
    } catch (e) {
      print('[CREATE MIDTRANS SNAP ERROR]: $e');
      rethrow;
    }
  }

  // --------------------------
  // Orders
  // --------------------------
  /// Ambil semua orders milik user yang sedang login
  /// Backend route: GET /api/v1/orders/me
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$baseUrl/orders/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body['data'] != null) {
        final List<dynamic> arr = body['data'];
        return List<Map<String, dynamic>>.from(arr);
      } else if (body is List) {
        return List<Map<String, dynamic>>.from(body);
      } else {
        return [];
      }
    } else {
      throw Exception(
        'Gagal memuat pesanan (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Ambil detail order berdasarkan id
  static Future<Map<String, dynamic>?> getOrderById({
    required int orderId,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception('Token tidak ditemukan');

    final url = Uri.parse('$baseUrl/orders/$orderId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is Map && body['data'] != null) {
        final data = body['data'];
        if (data is Map) return Map<String, dynamic>.from(data);
        return {'data': data};
      } else if (body is Map) {
        return Map<String, dynamic>.from(body);
      } else {
        return null;
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception(
        'Gagal memuat order (${response.statusCode}): ${response.body}',
      );
    }
  }

  // --------------------------
  // Recommendations
  // --------------------------
  /// Ambil rekomendasi untuk user
  /// Backend: GET /api/v1/recommendations/{user_id}
  static Future<List<Map<String, dynamic>>?> getRecommendationsForUser({
    required int userId,
    int limit = 10,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/recommendations/$userId');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['recommendations'] != null) {
          final list =
              List.from(
                body['recommendations'],
              ).map((e) => Map<String, dynamic>.from(e)).toList();
          return list.take(limit).toList();
        } else if (body is List) {
          return List<Map<String, dynamic>>.from(body.take(limit));
        }
      } else {
        print(
          'getRecommendationsForUser failed: ${res.statusCode} ${res.body}',
        );
      }
      return null;
    } catch (e) {
      print('getRecommendationsForUser error: $e');
      return null;
    }
  }

  /// Ambil rekomendasi berbasis item
  static Future<List<Map<String, dynamic>>?> getRecommendationsForItem({
    required int itemId,
    int limit = 8,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/recommendations/item/$itemId');
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['recommendations'] != null) {
          final list =
              List.from(
                body['recommendations'],
              ).map((e) => Map<String, dynamic>.from(e)).toList();
          return list.take(limit).toList();
        } else if (body is List) {
          return List<Map<String, dynamic>>.from(body.take(limit));
        }
      } else {
        print('getRecommendationsForItem failed: ${res.statusCode}');
      }
      return null;
    } catch (e) {
      print('getRecommendationsForItem error: $e');
      return null;
    }
  }

  /// Generic wrapper: type = 'user' | 'item'
  static Future<List<Map<String, dynamic>>?> getRecommendations({
    required int id,
    required String type,
    int limit = 8,
  }) async {
    if (type == 'user') {
      return getRecommendationsForUser(userId: id, limit: limit);
    } else if (type == 'item') {
      return getRecommendationsForItem(itemId: id, limit: limit);
    } else {
      throw Exception('Unknown recommendation type: $type');
    }
  }
}