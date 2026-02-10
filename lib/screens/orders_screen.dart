// lib/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:bhumidurianapp/services/api_baru.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadOrders();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await ApiBaru.getMyOrders();
      setState(() {
        _orders = orders;
        _loading = false;
      });
      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String s) {
    final st = s.toLowerCase();
    if (st.contains('pending')) return Colors.orange;
    if (st.contains('paid') || st.contains('completed') || st.contains('done')) return Colors.green;
    if (st.contains('canceled') || st.contains('cancel')) return Colors.red;
    if (st.contains('verifying') || st.contains('review')) return Colors.amber;
    return Colors.grey;
  }

  IconData _statusIcon(String s) {
    final st = s.toLowerCase();
    if (st.contains('pending')) return Icons.schedule;
    if (st.contains('paid') || st.contains('completed') || st.contains('done')) return Icons.check_circle;
    if (st.contains('canceled') || st.contains('cancel')) return Icons.cancel;
    if (st.contains('verifying') || st.contains('review')) return Icons.hourglass_empty;
    return Icons.info;
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _fmtPrice(String price) {
    try {
      final num = int.parse(price.replaceAll(RegExp(r'[^0-9]'), ''));
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(num);
    } catch (_) {
      return 'Rp $price';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFDD835),
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          if (_orders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Filter functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur filter akan segera hadir'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        color: const Color(0xFFFDD835),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xFFFDD835),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat pesanan...',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Terjadi Kesalahan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style: TextStyle(color: Colors.red[600]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: _loadOrders,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[400],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _orders.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.receipt_long_outlined,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Belum Ada Pesanan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Anda belum memiliki riwayat pesanan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: const Icon(Icons.shopping_bag_outlined),
                                  label: const Text('Mulai Belanja'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFDD835),
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          // Summary header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFDD835),
                                  const Color(0xFFFDD835).withOpacity(0.8),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag,
                                    color: Colors.black87,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Total Pesanan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_orders.length} Pesanan',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Orders list
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, i) {
                                final o = _orders[i];
                                final orderId = o['order_id']?.toString() ?? '-';
                                final total = o['total_price']?.toString() ?? o['total']?.toString() ?? '0';
                                final status = o['status']?.toString() ?? '-';
                                final created = o['created_at']?.toString() ?? o['createdAt']?.toString() ?? '';
                                final items = (o['items'] is List) ? List.from(o['items']) : <dynamic>[];
                                final itemCount = items.length;
                                final firstItemName = items.isNotEmpty ? (items[0]['name']?.toString() ?? '-') : '-';

                                return FadeTransition(
                                  opacity: Tween<double>(begin: 0, end: 1).animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        i * 0.1,
                                        (i + 1) * 0.1,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OrderDetailScreen(
                                                orderId: int.tryParse(orderId) ?? 0,
                                              ),
                                            ),
                                          ).then((_) => _loadOrders());
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Header: Order ID & Status
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.all(10),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFDD835).withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: const Icon(
                                                          Icons.receipt_long,
                                                          color: Color(0xFFF9A825),
                                                          size: 24,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Order #$orderId',
                                                            style: const TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              fontSize: 16,
                                                              color: Colors.black87,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(
                                                            '$itemCount item${itemCount > 1 ? 's' : ''}',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _statusColor(status).withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(20),
                                                      border: Border.all(
                                                        color: _statusColor(status).withOpacity(0.3),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          _statusIcon(status),
                                                          color: _statusColor(status),
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          status,
                                                          style: TextStyle(
                                                            color: _statusColor(status),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // Divider
                                              Container(
                                                height: 1,
                                                color: Colors.grey[200],
                                              ),

                                              const SizedBox(height: 16),

                                              // Item preview
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          firstItemName,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.black87,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        if (itemCount > 1) ...[
                                                          const SizedBox(height: 4),
                                                          Text(
                                                            '+${itemCount - 1} item lainnya',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.grey[600],
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 16),

                                              // Footer: Date & Price
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.access_time,
                                                        size: 14,
                                                        color: Colors.grey[600],
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _fmtDate(created),
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      const Text(
                                                        'Total',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.black54,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        _fmtPrice(total),
                                                        style: const TextStyle(
                                                          color: Color(0xFFF9A825),
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 12),

                                              // Action button
                                              SizedBox(
                                                width: double.infinity,
                                                child: OutlinedButton(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => OrderDetailScreen(
                                                          orderId: int.tryParse(orderId) ?? 0,
                                                        ),
                                                      ),
                                                    ).then((_) => _loadOrders());
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                      color: Color(0xFFFDD835),
                                                      width: 1.5,
                                                    ),
                                                    foregroundColor: Colors.black87,
                                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Text(
                                                        'Lihat Detail',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.w600,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      SizedBox(width: 6),
                                                      Icon(
                                                        Icons.arrow_forward_ios,
                                                        size: 14,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
      ),
    );
  }
}