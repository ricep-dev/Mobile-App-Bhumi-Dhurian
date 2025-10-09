import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static final _storage = FlutterSecureStorage();
  static const _tokenKey = 'token';

  /// Simpan token ke secure storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Ambil token dari secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Hapus token dari secure storage (misal saat logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Cek apakah token ada
  static Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }
}
