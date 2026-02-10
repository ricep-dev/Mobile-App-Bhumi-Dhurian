// lib/screens/product_detail_screen.dart

import 'package:flutter/material.dart';
import 'cart_screen.dart';
import 'package:bhumidurianapp/services/api_baru.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final void Function(
    String title,
    String price,
    String imageUrl,
    int productId,
  )
  onAddToCart;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _recommended = [];
  bool _isLoadingRec = false;
  String? _recError;
  bool _imageLoading = true;

  int getProductId(Map<String, dynamic> p) {
    final rawId = p['id'] ?? p['product_id'];
    return rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _loadSimilarWithFallback();
  }

  Future<void> _loadSimilarWithFallback() async {
    setState(() {
      _isLoadingRec = true;
      _recError = null;
      _recommended = [];
    });

    try {
      final rawId = widget.product['product_id'];
      final int itemId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

      // 1) coba item-based rekomendasi dulu
      if (itemId > 0) {
        final recsByItem = await ApiBaru.getRecommendationsForItem(
          itemId: itemId,
          limit: 8,
        );
        if (recsByItem != null && recsByItem.isNotEmpty) {
          setState(() {
            _recommended =
                recsByItem.where((r) {
                  final pidRaw = r['product_id'];
                  final pid =
                      pidRaw is int ? pidRaw : int.tryParse('$pidRaw') ?? -1;
                  return pid != itemId;
                }).toList();
            _isLoadingRec = false;
          });
          return;
        }
      }

      // 2) fallback: ambil produk dalam kategori yang sama
      final category = widget.product['category']?.toString() ?? '';
      if (category.isNotEmpty) {
        final byCategory = await ApiBaru.getProductsByCategory(category);
        if (byCategory.isNotEmpty) {
          setState(() {
            final curIdRaw = widget.product['product_id'];
            final curId =
                curIdRaw is int ? curIdRaw : int.tryParse('$curIdRaw') ?? -1;
            _recommended =
                byCategory
                    .where((r) {
                      final pidRaw = r['product_id'];
                      final pid =
                          pidRaw is int
                              ? pidRaw
                              : int.tryParse('$pidRaw') ?? -1;
                      return pid != curId;
                    })
                    .take(8)
                    .toList();
            _isLoadingRec = false;
            _recError = null;
          });
          return;
        }
      }

      // 3) fallback terakhir: rekomendasi user-based
      try {
        final profile = await ApiBaru.getUserProfile();
        final userId =
            (profile != null && profile['user_id'] != null)
                ? (profile['user_id'] is int
                    ? profile['user_id']
                    : int.tryParse('${profile['user_id']}') ?? 0)
                : 0;
        if (userId > 0) {
          final recsUser = await ApiBaru.getRecommendationsForUser(
            userId: userId,
            limit: 8,
          );
          if (recsUser != null && recsUser.isNotEmpty) {
            final curIdRaw = widget.product['product_id'];
            final curId =
                curIdRaw is int ? curIdRaw : int.tryParse('$curIdRaw') ?? -1;
            setState(() {
              _recommended =
                  recsUser.where((r) {
                    final pidRaw = r['product_id'];
                    final pid =
                        pidRaw is int ? pidRaw : int.tryParse('$pidRaw') ?? -1;
                    return pid != curId;
                  }).toList();
              _isLoadingRec = false;
            });
            return;
          }
        }
      } catch (_) {}

      setState(() {
        _recommended = [];
        _isLoadingRec = false;
        _recError = null;
      });
    } catch (e) {
      setState(() {
        _recommended = [];
        _isLoadingRec = false;
        _recError = 'Gagal memuat rekomendasi';
      });
      debugPrint('Load similar error: $e');
    }
  }

  String? buildImageUrl(dynamic raw) {
    final rawStr = raw?.toString() ?? '';
    if (rawStr.isEmpty) return null;
    if (rawStr.startsWith('http')) return rawStr;
    final encoded = Uri.encodeFull(rawStr);
    return 'http://192.168.31.101:9090/$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final int productId =
        p['product_id'] is int
            ? p['product_id']
            : int.tryParse('${p['product_id']}') ?? 0;
    final String name = p['name']?.toString() ?? '-';
    final String priceText = 'Rp ${p['price']?.toString() ?? '0'}';
    final String rating = p['rating']?.toString() ?? '0.0';
    final String category = p['category']?.toString() ?? '-';
    final String description =
        p['description']?.toString() ?? p['desc']?.toString() ?? '-';
    final String? imageUrl = buildImageUrl(p['image_url']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDD835),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          'Detail Produk',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // Share functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSimilarWithFallback,
        color: const Color(0xFFFDD835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE HERO dengan loading shimmer
              Hero(
                tag: 'product_$productId',
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      if (imageUrl != null)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: const Color(0xFFFDD835),
                                ),
                              ),
                            );
                          },
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                        )
                      else
                        Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // INFORMASI PRODUK dengan card design
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama & Rating
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating & Kategori Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Harga dengan background card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDD835).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFDD835).withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Harga',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            priceText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Color(0xFFF9A825),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Deskripsi
                    const Text(
                      'Deskripsi Produk',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        description,
                        style: const TextStyle(
                          height: 1.6,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tombol Tambah ke Keranjang
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAddToCart(
                            name,
                            priceText,
                            imageUrl ?? '',
                            productId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Ditambahkan ke keranjang'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFDD835),
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shopping_cart_outlined, size: 22),
                            SizedBox(width: 10),
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

              const SizedBox(height: 8),

              // REKOMENDASI SERUPA
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.recommend,
                            color: Color(0xFFFDD835),
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Rekomendasi Serupa',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_isLoadingRec)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFDD835),
                          ),
                        ),
                      )
                    else if (_recError != null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _recError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_recommended.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada rekomendasi untuk produk ini',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 240,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: _recommended.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final r = _recommended[index];
                            final rImg = buildImageUrl(r['image_url']);
                            final rName = r['name']?.toString() ?? '-';
                            final rPrice =
                                'Rp ${r['price']?.toString() ?? '0'}';
                            final rRating = r['rating']?.toString() ?? '0.0';

                            return GestureDetector(
                              onTap: () async {
                                final prodIdRaw = r['product_id'];
                                final prodId =
                                    prodIdRaw is int
                                        ? prodIdRaw
                                        : int.tryParse('${prodIdRaw}') ?? 0;
                                if (prodId <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID produk tidak valid'),
                                    ),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder:
                                      (_) => const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFFFDD835),
                                        ),
                                      ),
                                );

                                try {
                                  final prod = await ApiBaru.getProductById(
                                    prodId,
                                  );
                                  Navigator.pop(context);
                                  if (prod != null) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => ProductDetailScreen(
                                              product: prod,
                                              onAddToCart: widget.onAddToCart,
                                            ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Gagal mengambil detail produk',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Terjadi kesalahan: $e'),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 160,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
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
                                    // Image area
                                    ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
                                      ),
                                      child: Container(
                                        height: 120,
                                        color: Colors.grey[100],
                                        child:
                                            rImg != null
                                                ? Image.network(
                                                  rImg,
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  errorBuilder:
                                                      (
                                                        _,
                                                        __,
                                                        ___,
                                                      ) => const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                )
                                                : Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 40,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                      ),
                                    ),

                                    // Info area
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              rName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                height: 1.3,
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  rPrice,
                                                  style: const TextStyle(
                                                    color: Color(0xFFF9A825),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.star,
                                                      color: Colors.amber,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      rRating,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.black54,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
