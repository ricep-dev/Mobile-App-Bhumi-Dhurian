// file: lib/screens/descriptionproduct_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'cart_screen.dart';

class DescriptionProductScreen extends StatelessWidget {
  final String title;
  final String price;
  final String imageUrl;
  final String rating;
  final int productId;
  final List<Map<String, dynamic>> cartItems;
  final Function(String, String, String, int) onAddToCart;

  const DescriptionProductScreen({
    Key? key,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.rating,
    required this.productId,
    required this.cartItems,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductDescriptionController());
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: const Color(0xFFFDD835),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Get.back(),
            ),
            actions: [
              IconButton(
                icon: Obx(() => Icon(
                  controller.isFavorite.value ? Icons.favorite : Icons.favorite_border,
                  color: controller.isFavorite.value ? Colors.red : Colors.black87,
                )),
                onPressed: () => controller.toggleFavorite(),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.black87),
                onPressed: () {
                  // Share functionality
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'product_$productId',
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, size: 100, color: Colors.grey),
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Rating Section
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                        ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
                        
                        const SizedBox(height: 12),
                        
                        // Rating & Reviews
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDD835).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    rating,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '(${(double.parse(rating) * 47).toInt()} reviews)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                        
                        const SizedBox(height: 20),
                        
                        // Price
                        Row(
                          children: [
                            Text(
                              price,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFDD835),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '10% OFF',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 300.ms, duration: 600.ms).scale(),
                      ],
                    ),
                  ),

                  // Quantity Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: const Color(0xFFFDD835),
                                onPressed: () => controller.decrementQuantity(),
                              ),
                              Obx(() => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${controller.quantity.value}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              )),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: const Color(0xFFFDD835),
                                onPressed: () => controller.incrementQuantity(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 600.ms),

                  const SizedBox(height: 24),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Obx(() => AnimatedCrossFade(
                          firstChild: Text(
                            _getProductDescription(title),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          secondChild: Text(
                            _getProductDescription(title),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.6,
                            ),
                          ),
                          crossFadeState: controller.isExpanded.value
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        )),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => controller.toggleExpanded(),
                          child: Obx(() => Row(
                            children: [
                              Text(
                                controller.isExpanded.value ? 'Tampilkan Lebih Sedikit' : 'Baca Selengkapnya',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFDD835),
                                ),
                              ),
                              Icon(
                                controller.isExpanded.value ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFFFDD835),
                                size: 20,
                              ),
                            ],
                          )),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                  const SizedBox(height: 24),

                  // Ingredients/Info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Produk',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(Icons.restaurant_menu, 'Kategori', _getCategory(title)),
                        const SizedBox(height: 12),
                        _buildInfoCard(Icons.local_fire_department, 'Kalori', '${(double.parse(rating) * 100).toInt()} kcal'),
                        const SizedBox(height: 12),
                        _buildInfoCard(Icons.schedule, 'Waktu Penyajian', '15-20 menit'),
                        const SizedBox(height: 12),
                        _buildInfoCard(Icons.verified, 'Status', 'Tersedia'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 600.ms, duration: 600.ms),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Total Price
              Expanded(
                child: Obx(() => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _calculateTotalPrice(price, controller.quantity.value),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFDD835),
                      ),
                    ),
                  ],
                )),
              ),
              const SizedBox(width: 16),
              // Add to Cart Button
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    for (int i = 0; i < controller.quantity.value; i++) {
                      onAddToCart(title, price, imageUrl, productId);
                    }
                    
                    Get.snackbar(
                      'Berhasil',
                      '${controller.quantity.value}x $title ditambahkan ke keranjang',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(16),
                      borderRadius: 12,
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                    );
                    
                    Future.delayed(const Duration(milliseconds: 500), () {
                      Get.to(
                        () => CartScreen(cartItems: cartItems),
                        transition: Transition.rightToLeft,
                        duration: const Duration(milliseconds: 300),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD835),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart),
                      SizedBox(width: 8),
                      Text(
                        'Tambah ke Keranjang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 600.ms),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDD835).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFDD835), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProductDescription(String productName) {
    final descriptions = {
      'default': 'Nikmati kelezatan menu spesial dari Bhumi Durian yang dibuat dengan bahan-bahan pilihan berkualitas tinggi. Setiap hidangan kami disiapkan dengan penuh perhatian untuk memberikan pengalaman kuliner terbaik. Cocok untuk dinikmati kapan saja, baik sendiri maupun bersama keluarga dan teman-teman tercinta.',
    };
    
    return descriptions['default']!;
  }

  String _getCategory(String productName) {
    if (productName.toLowerCase().contains('durian')) {
      return 'Olahan Durian';
    } else if (productName.toLowerCase().contains('minum')) {
      return 'Minuman';
    } else if (productName.toLowerCase().contains('cemilan') || productName.toLowerCase().contains('snack')) {
      return 'Cemilan';
    }
    return 'Makanan';
  }

  String _calculateTotalPrice(String priceString, int quantity) {
    final numericPrice = priceString.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(numericPrice) ?? 0;
    final total = price * quantity;
    return 'Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}

class ProductDescriptionController extends GetxController {
  var quantity = 1.obs;
  var isFavorite = false.obs;
  var isExpanded = false.obs;

  void incrementQuantity() {
    if (quantity.value < 99) {
      quantity.value++;
    }
  }

  void decrementQuantity() {
    if (quantity.value > 1) {
      quantity.value--;
    }
  }

  void toggleFavorite() {
    isFavorite.value = !isFavorite.value;
  }

  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }
}

// Extension untuk animasi (pastikan package flutter_animate sudah diinstall)
extension AnimateExtension on Widget {
  Widget animate() => this;
  
  Widget fadeIn({Duration? duration, Duration? delay}) {
    return this;
  }
  
  Widget slideX({double? begin, double? end, Duration? duration}) {
    return this;
  }
  
  Widget slideY({double? begin, double? end, Duration? duration}) {
    return this;
  }
  
  Widget scale({Duration? duration}) {
    return this;
  }
}

// Helper untuk durasi
extension DurationExtension on int {
  Duration get ms => Duration(milliseconds: this);
}