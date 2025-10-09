// lib/services/user_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserService {
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_token';
  static const String _isLoggedInKey = 'is_logged_in';

  // Simpan data user setelah login berhasil
  static Future<void> saveUserData({
    required String username,
    required String email,
    required String token,
    String? fullName,
    String? phone,
    String? avatar,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    final userData = {
      'username': username,
      'email': email,
      'fullName': fullName ?? username,
      'phone': phone,
      'avatar': avatar,
    };
    
    await prefs.setString(_userKey, jsonEncode(userData));
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Ambil data user yang tersimpan
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  // Ambil username
  static Future<String> getUsername() async {
    final userData = await getUserData();
    return userData?['username'] ?? 'User';
  }

  // Ambil full name
  static Future<String> getFullName() async {
    final userData = await getUserData();
    return userData?['fullName'] ?? userData?['username'] ?? 'User';
  }

  // Ambil email
  static Future<String> getEmail() async {
    final userData = await getUserData();
    return userData?['email'] ?? '';
  }

  // Ambil token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Logout - hapus semua data
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  // Update data user
  static Future<void> updateUserData(Map<String, dynamic> newData) async {
    final currentData = await getUserData();
    if (currentData != null) {
      final updatedData = {...currentData, ...newData};
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(updatedData));
    }
  }
}