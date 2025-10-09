// file: lib/screens/home_screen.dart

import 'package:bhumidurianapp/screens/profile_screen.dart';
import 'package:bhumidurianapp/services/api_baru.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package.http.dart' as http;
import 'cart_screen.dart';

// Impor halaman kategori generik
import 'package:bhumidurianapp/screens/category_products_screen.dart';

class HomeScreen extends StatefulWidget {
  // Constructor tidak perlu menerima onAddToCart lagi karena sudah dikelola di dalam state
  const HomeScreen({super.key, required Null Function(dynamic item) onAddToCart});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Semua state Anda tetap sama
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  final List<Map<String, dynamic>> _bannerList = [
      {
        'image': 'assets/durian_montong.jpg',
        'title': 'Durian Montong',
        'subtitle': 'Diskon!!!',
        'discount': '40%',
        'price': 'Rp 81.000/kg',
        'color': const Color(0xFF2E7D32),
      },
      {
        'image': 'assets/promo_stecu.png',
        'title': 'Mie Nyemek',
        'subtitle': 'Promo Spesial',
        'discount': '10%',
        'price': 'Rp 7.500',
        'color': const Color(0xFFE91E63),
      },
      {
        'image': 'assets/promo 3.jpg',
        'title': 'Iga Bhumi + Sambel Penyet',
        'subtitle': 'Hemat Banget!',
        'discount': '20%',
        'price': 'Rp 50.000',
        'color': const Color(0xFF3F51B5),
      },
    ];
  List<Map<String, dynamic>>? _products;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _cartItems = [];
  Map<String, dynamic>? _userData;
  bool _isUserLoading = false;
  String? _userError;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
    _loadProducts();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _bannerList.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadProducts() async {
    if (_products == null && !_isLoading) {
      setState(() {
        _isLoading = true;
      });
      try {
        final products = await ApiBaru.getAllProducts();
        setState(() {
          _products = products;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Error loading products: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (_userData == null && !_isUserLoading) {
      setState(() {
        _isUserLoading = true;
      });
      try {
        final userData = await ApiBaru.getUserProfile();
        if (userData != null) {
          print('User Data successfully fetched: $userData');
          setState(() {
            _userData = userData;
            _isUserLoading = false;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() {
          _userError = 'Error loading user profile: $e';
          _isUserLoading = false;
        });
      }
    }
  }

  // Fungsi ini yang akan dikirimkan ke halaman kategori
  void _addToCart(String title, String price, String imageUrl, int productId) {
    setState(() {
      _cartItems.add({
        'title': title,
        'price': price,
        'imageUrl': imageUrl,
        'quantity': 1,
        'product_id': productId,
      });
    });
    print('Item added to cart: $title, Price: $price, Product ID: $productId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Header dan Banner (Tidak ada perubahan)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDD835),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage('assets/user1.jpg'),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isUserLoading
                              ? "Memuat..."
                              : _userError != null
                                  ? "Gagal memuat"
                                  : _userData != null
                                      ? "Hai, ${_userData!['username'] ?? 'User'}!"
                                      : "Hai, Guest!",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Cari menu favorit kamu",
                          hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 200,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _bannerList.length,
                      itemBuilder: (context, index) {
                        final banner = _bannerList[index];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  banner['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            banner['color'],
                                            banner['color'].withOpacity(0.7),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withOpacity(0.6),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 20,
                                  top: 15,
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange[300],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.local_dining,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: const [
                                          Text(
                                            "Promo ",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "🔥",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        banner['title'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        banner['subtitle'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        banner['discount'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        banner['price'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 15,
                                  left: 20,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDD835),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: const Text(
                                      "Buy Now",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 10,
                      right: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          _bannerList.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color:
                                  _currentPage == index
                                      ? const Color(0xFFFDD835)
                                      : Colors.white.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Kategori",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFFDD835),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // --- PERUBAHAN DI SINI: Mengirim fungsi dan data ke CategoryProductsScreen ---
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildCategoryCard(
                      "Makanan",
                      const Color(0xFFFDD835),
                      'assets/makanan.png',
                      CategoryProductsScreen(
                        categoryName: 'Makanan',
                        onAddToCart: _addToCart, // Kirim fungsi
                        cartItems: _cartItems,   // Kirim data keranjang
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCategoryCard(
                      "Minuman Bhumi",
                      const Color(0xFFFFE082),
                      'assets/minuman_bhumi.png',
                      CategoryProductsScreen(
                        categoryName: 'Minuman Bhumi',
                        onAddToCart: _addToCart,
                        cartItems: _cartItems,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCategoryCard(
                      "Olahan Durian",
                      const Color(0xFFFFE082),
                      'assets/olahan_durian.png',
                      CategoryProductsScreen(
                        categoryName: 'Olahan Durian',
                        onAddToCart: _addToCart,
                        cartItems: _cartItems,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCategoryCard(
                      "Cemilan",
                      const Color(0xFFFFE082),
                      'assets/cemilan.png',
                      CategoryProductsScreen(
                        categoryName: 'Cemilan',
                        onAddToCart: _addToCart,
                        cartItems: _cartItems,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Daftar Menu Bhumi Durian",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildProductGrid(),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(cartItems: _cartItems),
                ),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFFFDD835),
          selectedItemColor: Colors.black87,
          unselectedItemColor: Colors.black54,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long, size: 28),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 28),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(child: Text(_error!));
    } else if (_products == null || _products!.isEmpty) {
      return const Center(child: Text('No products available'));
    }
    return Column(
      children: [
        for (int i = 0; i < _products!.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom:12.0),
            child: Row(
              children: [
                Expanded(
                  child: () {
                    final product = _products![i];
                    final productId = product['product_id'];
                    return _buildPopularCard(
                      product['name'] ?? 'Product',
                      product['rating']?.toString() ?? '0.0',
                      'Rp ${product['price']?.toString() ?? '0'}',
                      'http://192.168.1.3:9090/${product['image_url'] ?? ''}',
                      productId ?? 0,
                    );
                  }(),
                ),
                if (i + 1 < _products!.length) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: () {
                      final product = _products![i + 1];
                      final productId = product['product_id'];
                      return _buildPopularCard(
                        product['name'] ?? 'Product',
                        product['rating']?.toString() ?? '0.0',
                        'Rp ${product['price']?.toString() ?? '0'}',
                        'http://1192.168.1.3:9090/${product['image_url'] ?? ''}',
                        productId ?? 0,
                      );
                    }(),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryCard(
      String title, Color color, String imageAsset, Widget destinationScreen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  imageAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      _getCategoryIcon(title),
                      size: 24,
                      color: Colors.black87,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String title) {
    switch (title) {
      case "Makanan":
        return Icons.restaurant;
      case "Minuman Bhumi":
        return Icons.local_drink;
      case "Olahan Durian":
        return Icons.cake;
      case "Cemilan":
        return Icons.fastfood;
      default:
        return Icons.category;
    }
  }

  Widget _buildPopularCard(
    String title,
    String rating,
    String price,
    String imageUrl,
    int productId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 100,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFDD835),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        // Memanggil fungsi utama untuk tambah ke keranjang
                        _addToCart(title, price, imageUrl, productId);
                        // Langsung navigasi ke keranjang
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => CartScreen(cartItems: _cartItems),
                          ),
                        );
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDD835),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          size: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}