import 'dart:convert';
import 'package:bhumidurianapp/services/token.dart'; // Sesuaikan dengan path proyek Anda
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Diperlukan untuk tipe data XFile

/// Kelas ini menangani semua komunikasi dengan API backend.
class ApiBaru {
  static const String baseUrl = 'http://192.168.1.6:9090/api/v1';

  /// Fungsi untuk melakukan login pengguna.
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
      return {'success': false, 'message': 'Terjadi kesalahan koneksi'};
    }
  }

  /// Fungsi untuk mendapatkan profil pengguna yang sedang login.
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
        return data['data'];
      } else {
        print('Gagal ambil data user: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Terjadi kesalahan saat ambil data user: $e');
      return null;
    }
  }

  /// Fungsi untuk mengambil semua data produk.
  static Future<List<Map<String, dynamic>>> getAllProducts() async {
    // Endpoint ini tidak memerlukan token
    final url = Uri.parse('$baseUrl/products');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Backend Anda mengembalikan array JSON langsung
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat produk dari server.');
      }
    } catch (e) {
      print('Error ambil semua produk: $e');
      rethrow;
    }
  }

  // --- FUNGSI BARU DITAMBAHKAN DI SINI ---

  /// Fungsi untuk mengambil produk berdasarkan kategori.
  static Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    // Endpoint ini juga publik dan tidak memerlukan token
    final url = Uri.parse('$baseUrl/products/${Uri.encodeComponent(category)}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Sama seperti getAllProducts, backend mengembalikan array JSON
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Gagal memuat produk untuk kategori: $category');
      }
    } catch (e) {
      print('Error ambil produk by category: $e');
      rethrow;
    }
  }

  // --- BATAS PENAMBAHAN FUNGSI BARU ---

  /// Fungsi untuk membuat pesanan baru (checkout).
  /// Versi final ini menggunakan `MultipartFile.fromBytes` agar kompatibel
  /// dengan platform Mobile dan Web.
  static Future<Map<String, dynamic>> createOrder({
    required XFile buktiPembayaran,
    required String paymentMethod,
    required String orderType,
    required String itemsDataJson,
    // Parameter opsional (nullable)
    String? shippingAddress,
    String? reservationTableNumber,
    String? reservationTime, // Format ISO 8601
    String? reservationGuestCount,
    String? reservationSpecialRequest,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Otorisasi Gagal: Token tidak ditemukan.');
    }

    final url = Uri.parse('$baseUrl/orders');
    final request = http.MultipartRequest('POST', url);

    // 1. Tambahkan Headers
    request.headers['Authorization'] = 'Bearer $token';

    // 2. Tambahkan Fields (data teks)
    request.fields['payment_method'] = paymentMethod;
    request.fields['order_type'] = orderType;
    request.fields['items_data'] = itemsDataJson;

    // Tambahkan field opsional hanya jika ada nilainya
    if (shippingAddress != null && shippingAddress.isNotEmpty) {
      request.fields['shipping_address'] = shippingAddress;
    }
    if (reservationTableNumber != null) {
      request.fields['reservation_table_number'] = reservationTableNumber;
    }
    if (reservationTime != null) {
      request.fields['reservation_time'] = reservationTime;
    }
    if (reservationGuestCount != null) {
      request.fields['reservation_guest_count'] = reservationGuestCount;
    }
    if (reservationSpecialRequest != null &&
        reservationSpecialRequest.isNotEmpty) {
      request.fields['reservation_special_request'] = reservationSpecialRequest;
    }

    // 3. Tambahkan File menggunakan metode yang kompatibel dengan semua platform
    final fileBytes = await buktiPembayaran.readAsBytes();
    final multipartFile = http.MultipartFile.fromBytes(
      'bukti_pembayaran', // Key field, harus cocok dengan backend
      fileBytes, // Isi file dalam bentuk bytes
      filename: buktiPembayaran.name, // Nama file asli
    );
    request.files.add(multipartFile);

    print('Mengirim pesanan ke server...');

    try {
      // 4. Kirim request dan tunggu response
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // 201 Created
        print('Pesanan berhasil dibuat: $responseData');
        return {'success': true, ...responseData};
      } else {
        // Jika gagal, lemparkan pesan error dari backend
        print('Gagal membuat pesanan: ${response.body}');
        throw Exception(
          responseData['detail'] ??
              responseData['error'] ??
              'Gagal membuat pesanan',
        );
      }
    } catch (e) {
      print('[CREATE ORDER ERROR]: $e');
      rethrow; // Lemparkan kembali error untuk ditangani oleh UI
    }
  }
}
