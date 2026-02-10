import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bhumidurianapp/screens/reservation_screen.dart';
import 'package:bhumidurianapp/services/api_baru.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const ConfirmationScreen({super.key, required this.cartItems});

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  // --- STATE UNTUK KONTROL UI & DATA ---
  String _selectedService = "Delivery";
  XFile? _buktiPembayaranFile;
  Map<String, dynamic>? _reservationData;
  String _paymentMethod = "manual"; // manual | midtrans

  final TextEditingController _addressController = TextEditingController();
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = true;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  // --- FUNGSI-FUNGSI LOGIKA ---

  Future<void> _loadUser() async {
    try {
      final user = await ApiBaru.getUserProfile();
      if (mounted) {
        setState(() {
          _userData = user;
          _addressController.text = user?['alamat'] ?? '';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUser = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data pengguna: $e")),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _buktiPembayaranFile = pickedFile;
      });
    }
  }

  Future<void> _navigateToReservation() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const ReservationScreen()),
    );

    if (result != null && mounted) {
      setState(() {
        _reservationData = result;
        _selectedService = "Dine In";
      });
    }
  }

  int _calculateTotal() {
    return widget.cartItems.fold(0, (sum, item) {
      final priceString = item['price']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
      final price = int.tryParse(priceString) ?? 0;
      final quantity = item['quantity'] as int? ?? 1;
      return sum + (price * quantity);
    });
  }
  
  // ✅ HANDLER ORDER DENGAN FLOW YANG SUDAH DISESUAIKAN
  Future<void> _handleOrder() async {
    // ================= VALIDASI =================
    if (_paymentMethod == "manual" && _buktiPembayaranFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap unggah bukti pembayaran.")),
      );
      return;
    }
    if (_selectedService == "Delivery" && _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Alamat pengiriman wajib diisi untuk layanan Delivery.")),
      );
      return;
    }
    if (_selectedService == "Dine In" && _reservationData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda harus membuat reservasi untuk layanan Dine In.")),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      // ================= PREPARE ITEMS =================
      final itemsPayload = widget.cartItems.map((item) {
        return {
          "product_id": item['product_id'],
          "quantity": item['quantity'],
          "price": int.parse(
            item['price'].toString().replaceAll(RegExp(r'[^0-9]'), ''),
          ),
        };
      }).toList();
      final itemsJsonString = jsonEncode(itemsPayload);

      // ================= JIKA MANUAL (TRANSFER BANK) =================
      if (_paymentMethod == "manual") {
        final orderResponse = await ApiBaru.createOrder(
          buktiPembayaran: _buktiPembayaranFile!,
          paymentMethod: "transfer_bank",
          orderType: _selectedService,
          itemsDataJson: itemsJsonString,
          shippingAddress: _selectedService == "Delivery" ? _addressController.text : null,
          reservationTableNumber: _reservationData?['table_number'],
          reservationTime: (_reservationData?['reservation_time'] as DateTime?)?.toUtc().toIso8601String(),
          reservationGuestCount: _reservationData?['guest_count']?.toString(),
          reservationSpecialRequest: _reservationData?['special_request'],
        );

        await _showSuccessDialog(orderResponse['message'] ?? "Pesanan berhasil dibuat!");
        return;
      }

      // ================= JIKA MIDTRANS =================
      if (_paymentMethod == "midtrans") {
        // 📌 STEP 1: Buat order dengan Midtrans (tanpa bukti pembayaran)
        final orderResponse = await ApiBaru.createOrderMidtrans(
          orderType: _selectedService,
          itemsDataJson: itemsJsonString,
          shippingAddress: _selectedService == "Delivery" ? _addressController.text : null,
          reservationTableNumber: _reservationData?['table_number'],
          reservationTime: (_reservationData?['reservation_time'] as DateTime?)?.toUtc().toIso8601String(),
          reservationGuestCount: _reservationData?['guest_count']?.toString(),
          reservationSpecialRequest: _reservationData?['special_request'],
        );

        // 📌 STEP 2: Ambil order_id dari response
        final orderId = orderResponse['data']?['order_id'];
        
        if (orderId == null) {
          throw Exception("Order ID tidak ditemukan dari server");
        }

        // 📌 STEP 3: Buat snap token menggunakan order_id
        final snapResponse = await ApiBaru.createMidtransSnap(orderId: orderId);
        final snapToken = snapResponse['snap_token'];
        
        if (snapToken == null || snapToken.toString().isEmpty) {
          throw Exception("Snap token tidak ditemukan dari server");
        }

        // 📌 STEP 4: Buka halaman pembayaran Midtrans
        final url = Uri.parse(
          "https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken",
        );
        
        final launched = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          throw Exception("Tidak dapat membuka halaman pembayaran Midtrans");
        }

        // 📌 STEP 5: Kembali ke home setelah membuka Midtrans
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Silakan selesaikan pembayaran di browser"),
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        return;
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().replaceAll("Exception: ", "")}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Pesanan Berhasil!"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // --- UI (WIDGET BUILD) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDD835),
        elevation: 0,
        title: const Text(
          "Konfirmasi Pesanan",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: _isLoadingUser
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFDD835)))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildServiceSelector(),
                      const SizedBox(height: 20),
                      if (_selectedService == "Delivery") ...[
                        _buildAddressInput(),
                        const SizedBox(height: 20),
                      ],
                      if (_selectedService == "Dine In" && _reservationData != null) ...[
                        _buildReservationSummary(),
                        const SizedBox(height: 20),
                      ],
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: 20),
                      if (_paymentMethod == "manual") ...[
                        _buildPaymentForm(),
                        const SizedBox(height: 24),
                      ],
                      _buildItemSummary(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  // --- KOMPONEN-KOMPONEN WIDGET ---

  Widget _buildServiceSelector() {
    final services = {
      "Delivery": Icons.motorcycle,
      "Pickup": Icons.shopping_bag,
      "Dine In": Icons.restaurant
    };
    
    return Row(
      children: services.entries.map((entry) {
        final isSelected = _selectedService == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (entry.key == "Dine In") {
                _navigateToReservation();
              } else {
                setState(() {
                  _selectedService = entry.key;
                  _reservationData = null;
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFDD835) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    entry.value,
                    color: isSelected ? Colors.black87 : Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddressInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Alamat Pengiriman",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: "Masukkan alamat lengkap...",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Metode Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _paymentButton(
                label: "Transfer Bank",
                value: "manual",
                icon: Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _paymentButton(
                label: "Midtrans",
                value: "midtrans",
                icon: Icons.payment,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _paymentButton({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDD835) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black87 : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black87 : Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Bukti Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: InkWell(
            onTap: _pickImage,
            child: _buktiPembayaranFile == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        "Ketuk untuk memilih gambar",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(_buktiPembayaranFile!.path, fit: BoxFit.cover)
                        : Image.file(File(_buktiPembayaranFile!.path), fit: BoxFit.cover),
                  ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReservationSummary() {
    final reservationTime = _reservationData?['reservation_time'] as DateTime?;
    final formattedTime = reservationTime != null
        ? DateFormat('EEEE, dd MMMM yyyy - HH:mm', 'id_ID').format(reservationTime)
        : 'N/A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Reservasi Meja",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.table_restaurant_outlined, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    "Meja: ${_reservationData?['table_number'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Waktu: $formattedTime")),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text("Jumlah Tamu: ${_reservationData?['guest_count'] ?? ''} orang"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Ringkasan Pesanan",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: widget.cartItems.map((item) {
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['imageUrl'] ?? 'https://via.placeholder.com/150',
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(item['title'] ?? 'Nama Produk'),
                subtitle: Text("Qty: ${item['quantity']}"),
                trailing: Text(
                  item['price'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final total = _calculateTotal();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Pesanan:",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                currencyFormatter.format(total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _handleOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD835),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isPlacingOrder
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.black87,
                      ),
                    )
                  : const Text(
                      "Buat Pesanan Sekarang",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}