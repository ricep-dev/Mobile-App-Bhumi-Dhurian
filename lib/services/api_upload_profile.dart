import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'token.dart';

class ApiUploadProfile {
  static const String baseUrl = 'http://192.168.31.101:9090';

  static Future<String?> uploadProfilePhoto({
    required File imageFile,
    required int userId,
  }) async {
    final token = await TokenService.getToken();
    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final uri = Uri.parse('$baseUrl/api/v1/users/$userId/photo');

    final request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      await http.MultipartFile.fromPath(
        'photo', // SAMA dengan backend Gin
        imageFile.path,
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['image']; // ⬅️ sesuai response Postman
    }

    throw Exception('Upload gagal (${response.statusCode}): ${response.body}');
  }
}
