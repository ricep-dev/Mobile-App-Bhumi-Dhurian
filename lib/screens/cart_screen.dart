// ✅ CART SCREEN (CartScreen)
import 'package:flutter/material.dart';
import 'confirmation_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  const CartScreen({super.key, required this.cartItems});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late List<Map<String, dynamic>> _cartItems;

  @override
  void initState() {
    super.initState();
    _cartItems = List<Map<String, dynamic>>.from(widget.cartItems);
  }

  int calculateTotal() {
    return _cartItems.fold(0, (sum, item) {
      final price = int.tryParse(item['price'].replaceAll('Rp ', '').replaceAll('.', '')) ?? 0;
      final quantity = item['quantity'] is int ? item['quantity'] : int.tryParse(item['quantity'].toString()) ?? 1;
      return sum + (price * quantity).toInt();
    });
  }

  void incrementQuantity(int index) {
    setState(() {
      _cartItems[index]['quantity'] += 1;
    });
  }

  void decrementQuantity(int index) {
    setState(() {
      if (_cartItems[index]['quantity'] > 1) {
        _cartItems[index]['quantity'] -= 1;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int total = calculateTotal();
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFDD835),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "Keranjangku",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
            ),

            // --- KONTEN KERANJANG ---
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(
                      child: Text("Keranjang kosong", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) {
                        final item = _cartItems[index];
                        return _buildCartItem(
                          item['title'], item['price'], item['imageUrl'], item['quantity'], index,
                        );
                      },
                    ),
            ),
            // --- FOOTER CHECKOUT ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text("${_cartItems.length} item", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    _cartItems.isEmpty ? "Rp 0" : "Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  ElevatedButton(
                    onPressed: _cartItems.isEmpty
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ConfirmationScreen(cartItems: _cartItems),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD835),
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      disabledBackgroundColor: Colors.grey[300],
                      disabledForegroundColor: Colors.black26,
                    ),
                    child: const Text("Checkout"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET UNTUK ITEM DI KERANJANG ---
  Widget _buildCartItem(String title, String price, String imageUrl, int quantity, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/placeholder.png', width: 80, height: 80, fit: BoxFit.cover);
              },
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // --- KONTROL KUANTITAS ---
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () => decrementQuantity(index),
              ),
              Text("$quantity", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFDD835)),
                onPressed: () => incrementQuantity(index),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
