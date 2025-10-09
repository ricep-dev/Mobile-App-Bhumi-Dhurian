import 'package:bhumidurianapp/screens/Home_screen.dart';
import 'package:bhumidurianapp/screens/login_screen.dart';
import 'package:bhumidurianapp/screens/register_screen.dart';
import 'package:bhumidurianapp/screens/forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

// 1. WAJIB TAMBAHKAN IMPORT INI
import 'package:intl/date_symbol_data_local.dart';

// 2. UBAH FUNGSI main MENJADI `async` DAN TAMBAHKAN KODE INISIALISASI
Future<void> main() async {
  // Baris ini wajib ada jika Anda menjalankan kode sebelum runApp()
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data locale untuk Bahasa Indonesia.
  // Ini akan memperbaiki error `LocaleDataException`.
  await initializeDateFormatting('id_ID', null);

  // Jalankan aplikasi Anda seperti biasa
  runApp(const BhumiDurianApp());
}

class BhumiDurianApp extends StatelessWidget {
  const BhumiDurianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhumi Durian Resto',
      theme: ThemeData(
        primarySwatch: Colors.green, // Anda bisa ganti lagi ke yellow jika mau
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // Praktik yang baik untuk mengatur bahasa default aplikasi
      locale: const Locale('id', 'ID'), 
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(), 
      },
    );
  }
}
