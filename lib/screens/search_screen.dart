// lib/screens/search_screen.dart

import 'package:flutter/material.dart';
import 'package:bhumidurianapp/screens/product_detail_screen.dart';
import 'package:bhumidurianapp/services/api_baru.dart';

class SearchScreen extends StatefulWidget {
  final Function(String, String, String, int) onAddToCart;
  final List<Map<String, dynamic>> cartItems;

  const SearchScreen({
    super.key,
    required this.onAddToCart,
    required this.cartItems,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>>? _allProducts;
  List<Map<String, dynamic>>? _filteredProducts;
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;

  // Daftar kategori untuk filter
  String _selectedCategory = 'Semua';
  final List<String> _categories = [
    'Semua',
    'Makanan',
    'Minuman Bhumi',
    'Olahan Durian',
    'Cemilan',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    // Auto focus pada search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await ApiBaru.getAllProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    if (_allProducts == null) return;

    setState(() {
      _isSearching = query.isNotEmpty;

      if (query.isEmpty && _selectedCategory == 'Semua') {
        _filteredProducts = null;
        return;
      }

      _filteredProducts =
          _allProducts!.where((product) {
            // Filter berdasarkan search query
            bool matchesQuery = true;
            if (query.isNotEmpty) {
              final name = product['name']?.toString().toLowerCase() ?? '';
              final description =
                  product['description']?.toString().toLowerCase() ?? '';
              final category =
                  product['category']?.toString().toLowerCase() ?? '';
              final searchLower = query.toLowerCase();

              matchesQuery =
                  name.contains(searchLower) ||
                  description.contains(searchLower) ||
                  category.contains(searchLower);
            }

            // Filter berdasarkan kategori
            bool matchesCategory = true;
            if (_selectedCategory != 'Semua') {
              final productCategory = product['category']?.toString() ?? '';
              matchesCategory = productCategory == _selectedCategory;
            }

            return matchesQuery && matchesCategory;
          }).toList();
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterProducts(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDD835),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Produk',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFFDD835),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _filterProducts,
                decoration: InputDecoration(
                  hintText: "Cari menu favorit kamu...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey[600],
                    size: 22,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Colors.grey[600],
                              size: 22,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),

          // Filter Kategori
          Container(
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => _selectCategory(category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? const Color(0xFFFDD835) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            isSelected
                                ? const Color(0xFFFDD835)
                                : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color(0xFFFDD835).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.black87 : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Search Info
          if (_isSearching || _selectedCategory != 'Semua')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _filteredProducts != null
                          ? 'Ditemukan ${_filteredProducts!.length} produk'
                          : 'Mencari...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (_isSearching || _selectedCategory != 'Semua')
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                        _selectCategory('Semua');
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          color: Color(0xFFFDD835),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Product Grid
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFDD835)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD835),
                foregroundColor: Colors.black87,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final displayProducts = _filteredProducts ?? _allProducts;

    if (displayProducts == null || displayProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Tidak ada produk ditemukan' : 'Belum ada produk',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Coba kata kunci lain'
                  : 'Produk akan muncul di sini',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: displayProducts.length,
      itemBuilder: (context, index) {
        return _buildProductCard(displayProducts[index]);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final title = product['name'] ?? 'Product';
    final rating = product['rating']?.toString() ?? '0.0';
    final price = 'Rp ${product['price']?.toString() ?? '0'}';
    final rawImage = product['image_url'] ?? product['image'] ?? '';
    String? imageUrl;
    if (rawImage != null && rawImage.toString().isNotEmpty) {
      final rawStr = rawImage.toString();
      final encoded = Uri.encodeFull(rawStr);
      imageUrl =
          rawStr.startsWith('http')
              ? rawStr
              : 'http://192.168.31.101:9090/$encoded';
    }
    final productId = product['product_id'] ?? product['id'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => ProductDetailScreen(
                  product: product,
                  onAddToCart: widget.onAddToCart,
                ),
          ),
        );
      },
      child: Container(
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
            // Product Image
            Container(
              height: 120,
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
                child:
                    imageUrl != null
                        ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                color: const Color(0xFFFDD835),
                              ),
                            );
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
                        )
                        : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 13,
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
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
                            widget.onAddToCart(
                              title,
                              price,
                              imageUrl ?? '',
                              productId is int
                                  ? productId
                                  : int.tryParse('$productId') ?? 0,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$title ditambahkan ke keranjang',
                                ),
                                duration: const Duration(seconds: 2),
                                backgroundColor: const Color(0xFFFDD835),
                                behavior: SnackBarBehavior.floating,
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
            ),
          ],
        ),
      ),
    );
  }
}
