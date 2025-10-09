import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const FaIcon(
        FontAwesomeIcons.google,
        color: Colors.red, // Warna Google
        size: 20,
      ),
      label: const Text(
        "Continue with Google",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onPressed: () {
        // TODO: Tambahkan logika Google Sign-In
        print("Login dengan Google");
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFDE59), // Kuning khas Bhumi Durian
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 2,
        shadowColor: Colors.grey.shade300,
      ),
    );
  }
}
