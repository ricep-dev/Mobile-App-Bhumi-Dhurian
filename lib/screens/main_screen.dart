import 'package:bhumidurianapp/screens/Home_screen.dart';
import 'package:bhumidurianapp/screens/cart_screen.dart';
import 'package:bhumidurianapp/screens/orders_screen.dart';
import 'package:bhumidurianapp/screens/profile_screen.dart';
import 'package:flutter/material.dart';

/// MainApp sekarang menjadi "Stateful Widget" yang mengontrol semua navigasi
/// dan state keranjang belanja.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _selectedIndex = 0;

  // 1. State untuk keranjang belanja (_cartItems) sekarang dikelola di sini.
  final List<Map<String, dynamic>> _cartItems = [];

  // 2. Fungsi untuk menambah item ke keranjang.
  //    Fungsi ini akan kita "oper" ke HomeScreen sebagai parameter.
  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      // Cek apakah produk sudah ada di keranjang berdasarkan product_id
      final index = _cartItems.indexWhere((item) => item['product_id'] == product['product_id']);

      if (index != -1) {
        // Jika produk sudah ada, cukup tambahkan kuantitasnya
        _cartItems[index]['quantity']++;
      } else {
        // Jika belum ada, tambahkan produk baru ke keranjang dengan kuantitas 1
        _cartItems.add({...product, 'quantity': 1});
      }
    });

    // Beri feedback langsung ke pengguna bahwa item berhasil ditambahkan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name']} ditambahkan ke keranjang!'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'LIHAT',
          onPressed: () {
            // Pindah ke tab keranjang (indeks ke-1) saat "LIHAT" diklik
            _onItemTapped(1);
          },
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Daftar layar yang akan ditampilkan di IndexedStack.
    // Kita definisikan di dalam build agar CartScreen selalu mendapat data _cartItems terbaru.
    final List<Widget> screens = [
      CartScreen(cartItems: _cartItems),   // Kirim daftar _cartItems ke CartScreen
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // IndexedStack menjaga state setiap layar agar tidak hilang saat berpindah tab
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFFFDD835),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        elevation: 10,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart, size: 28),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long, size: 28),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 28),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
