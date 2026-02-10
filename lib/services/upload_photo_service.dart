import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UploadPhotoService {
  final picker = ImagePicker();

  // Ambil gambar dari galeri
  Future<File?> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Upload gambar ke server
  Future<bool> uploadProfilePhoto(File imageFile) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('token');

    if (userId == null || token == null) return false;

    final uri = Uri.parse('http://192.168.31.101:3000/api/user/upload-profile/$userId'); // Ganti IP sesuai server kamu

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();

    return response.statusCode == 200;
  }
}
