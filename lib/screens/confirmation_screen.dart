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
  String _selectedBank = "BCA"; // BCA | BRI | Mandiri | BNI

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
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          token: _userData?['token'] ?? '',
        ),
      ),
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
        final orderResponse = await ApiBaru.createOrderMidtrans(
          orderType: _selectedService,
          itemsDataJson: itemsJsonString,
          shippingAddress: _selectedService == "Delivery" ? _addressController.text : null,
          reservationTableNumber: _reservationData?['table_number'],
          reservationTime: (_reservationData?['reservation_time'] as DateTime?)?.toUtc().toIso8601String(),
          reservationGuestCount: _reservationData?['guest_count']?.toString(),
          reservationSpecialRequest: _reservationData?['special_request'],
        );

        final orderId = orderResponse['order_id'];

        if (orderId == null) {
          print("Response order dari server: $orderResponse");
          throw Exception("Order ID tidak ditemukan dari server");
        }

        final snapResponse = await ApiBaru.createMidtransSnap(orderId: orderId);
        final snapToken = snapResponse['snap_token'];

        if (snapToken == null || snapToken.toString().isEmpty) {
          throw Exception("Snap token tidak ditemukan dari server");
        }

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

  // =====================================================
  // ✅ UI BARU: METODE PEMBAYARAN (REDESIGN)
  // =====================================================
  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label seksi
        Text(
          "METODE PEMBAYARAN",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // --- Opsi: Transfer Bank ---
        _buildPaymentOptionCard(
          value: "manual",
          icon: Icons.account_balance_outlined,
          label: "Transfer Bank",
          description: "Konfirmasi manual via bukti transfer",
          badgeLabel: "Gratis",
          badgeColor: const Color(0xFFEAF3DE),
          badgeTextColor: const Color(0xFF3B6D11),
        ),

        // Ekspansi: pilihan bank & upload (muncul saat Transfer Bank dipilih)
        if (_paymentMethod == "manual") ...[
          _buildBankChips(),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 8),

        // --- Opsi: Midtrans ---
        _buildPaymentOptionCard(
          value: "midtrans",
          icon: Icons.credit_card_outlined,
          label: "Midtrans",
          description: "Kartu kredit, GoPay, OVO, QRIS",
          badgeLabel: "Otomatis",
          badgeColor: const Color(0xFFE6F1FB),
          badgeTextColor: const Color(0xFF185FA5),
        ),
      ],
    );
  }

  /// Kartu opsi pembayaran dengan radio button & badge
  Widget _buildPaymentOptionCard({
    required String value,
    required IconData icon,
    required String label,
    required String description,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    final isSelected = _paymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFAEEDA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFBA7517) : Colors.grey[300]!,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            // Radio button custom
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFBA7517) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFBA7517),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Ikon metode
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: Colors.grey[700]),
            ),
            const SizedBox(width: 12),

            // Nama & deskripsi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badgeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: badgeTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chip pilihan bank (BCA, BRI, Mandiri, BNI)
  Widget _buildBankChips() {
    final banks = ["BCA", "BRI", "Mandiri", "BNI"];
    return Padding(
      padding: const EdgeInsets.only(left: 32, top: 6),
      child: Wrap(
        spacing: 8,
        children: banks.map((bank) {
          final isSelected = _selectedBank == bank;
          return GestureDetector(
            onTap: () => setState(() => _selectedBank = bank),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFAEEDA) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? const Color(0xFFBA7517) : Colors.grey[300]!,
                  width: isSelected ? 1.5 : 0.8,
                ),
              ),
              child: Text(
                bank,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF633806) : Colors.grey[700],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // =====================================================
  // ✅ UI BARU: UPLOAD BUKTI PEMBAYARAN (REDESIGN)
  // =====================================================
  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upload Bukti Pembayaran",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _buktiPembayaranFile != null
                    ? const Color(0xFFBA7517)
                    : Colors.grey[350]!,
                width: _buktiPembayaranFile != null ? 1.5 : 1,
                // Dashed border menggunakan CustomPainter tidak tersedia di Container,
                // border solid sudah cukup profesional untuk Flutter native.
              ),
            ),
            child: _buktiPembayaranFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 36,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload bukti pembayaran",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "JPG, PNG, atau PDF · Maks 5 MB",
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        kIsWeb
                            ? Image.network(_buktiPembayaranFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_buktiPembayaranFile!.path), fit: BoxFit.cover),
                        // Overlay "Ganti" di pojok kanan bawah
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit, size: 12, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  "Ganti",
                                  style: TextStyle(fontSize: 11, color: Colors.white),
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

  // =====================================================
  // ✅ UI BARU: BOTTOM BAR (REDESIGN)
  // =====================================================
  Widget _buildBottomBar() {
    final total = _calculateTotal();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
          // Baris subtotal (bisa dikembangkan untuk ongkir dsb)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Subtotal", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text(currencyFormatter.format(total),
                  style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Biaya pengiriman", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text("Rp 0", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Biaya layanan", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              Text("Rp 0", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, thickness: 0.8),
          ),

          // Baris total utama
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total Pesanan:",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              Text(
                currencyFormatter.format(total),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBA7517),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Tombol order
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPlacingOrder ? null : _handleOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD835),
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.grey[300],
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
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

          const SizedBox(height: 8),

          // Catatan keamanan SSL
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 12, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                "Transaksi dilindungi enkripsi SSL",
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}