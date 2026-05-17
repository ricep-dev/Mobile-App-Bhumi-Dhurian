import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ReservationScreen extends StatefulWidget {      
  final String token;

  const ReservationScreen({super.key, required this.token});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with TickerProviderStateMixin {
  // ─── Controllers ────────────────────────────────────────────────
  final TextEditingController guestCountController = TextEditingController();
  final TextEditingController specialRequestController =
      TextEditingController();

  // ─── State ──────────────────────────────────────────────────────
  DateTime selectedDateTime = DateTime.now();
  String? selectedTable;
  List<Map<String, dynamic>> tables = [];
  bool isLoading = true;

  // ─── Config ─────────────────────────────────────────────────────
  final String baseUrl = "http://192.168.31.101:9090/api/v1";
  Timer? _timer;

  // ─── Animation ──────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ─── Theme Colors ───────────────────────────────────────────────
  static const Color kPrimary = Color(0xFFFDD835);
  static const Color kPrimaryDark = Color(0xFFF9A825);
  static const Color kBackground = Color(0xFFFAFAF8);
  static const Color kSurface = Colors.white;
  static const Color kTextPrimary = Color(0xFF1A1A1A);
  static const Color kTextSecondary = Color(0xFF757575);
  static const Color kAvailable = Color(0xFF2E7D32);
  static const Color kUnavailable = Color(0xFFB71C1C);
  static const Color kBorder = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _fetchTables();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchTables());
  }

  @override
  void dispose() {
    guestCountController.dispose();
    specialRequestController.dispose();
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _fetchTables() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/tables"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        setState(() {
          tables = List<Map<String, dynamic>>.from(body['data']);
          isLoading = false;
        });
        _fadeController.forward(from: 0);
      } else {
        throw Exception("Gagal memuat data meja");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showSnackBar("Gagal memuat meja: $e", isError: true);
    }
  }

  void _handleSubmitReservation() {
    if (selectedTable == null) {
      _showSnackBar("Pilih meja terlebih dahulu!", isError: true);
      return;
    }
    if (guestCountController.text.trim().isEmpty) {
      _showSnackBar("Jumlah tamu wajib diisi!", isError: true);
      return;
    }

    // ✅ FIX: Kirim reservation_time sebagai DateTime object,
    // bukan String, agar screen penerima bisa cast ke DateTime? dengan aman.
    // Jika screen penerima butuh String, gunakan toIso8601String() di sana.
    final data = {
      "table_number": selectedTable,
      "reservation_time": selectedDateTime, // ✅ tetap DateTime object
      "guest_count": int.parse(guestCountController.text.trim()),
      "special_request": specialRequestController.text.trim(),
    };

    Navigator.pop(context, data);
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFB71C1C) : kAvailable,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: RefreshIndicator(
                      onRefresh: _fetchTables,
                      color: kPrimaryDark,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        children: [
                          _buildSectionLabel("Pilih Meja", Icons.table_restaurant_rounded),
                          const SizedBox(height: 14),
                          _buildTableGrid(),
                          const SizedBox(height: 28),
                          _buildSectionLabel("Waktu Reservasi", Icons.schedule_rounded),
                          const SizedBox(height: 14),
                          _buildDateTimePicker(),
                          const SizedBox(height: 28),
                          _buildSectionLabel("Detail Tamu", Icons.people_alt_rounded),
                          const SizedBox(height: 14),
                          _buildTextField(
                            label: "Jumlah Tamu",
                            hint: "Masukkan jumlah tamu",
                            controller: guestCountController,
                            keyboardType: TextInputType.number,
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            label: "Permintaan Khusus",
                            hint: "Contoh: kursi roda, ruangan tenang...",
                            controller: specialRequestController,
                            icon: Icons.chat_bubble_outline_rounded,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),
                          _buildSubmitButton(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 20),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: kTextPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Reservasi Meja",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      "${tables.where((t) => t['status'] == 'available').length} meja tersedia",
                      style: TextStyle(
                        fontSize: 13,
                        color: kTextPrimary.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildLiveIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: kAvailable,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            "Live",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: kPrimaryDark,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Memuat data meja...",
            style: TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: kPrimaryDark),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTableGrid() {
    if (tables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: const Column(
          children: [
            Icon(Icons.table_restaurant_outlined, size: 40, color: kTextSecondary),
            SizedBox(height: 8),
            Text(
              "Tidak ada data meja",
              style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildLegend(kAvailable, "Tersedia"),
              const SizedBox(width: 16),
              _buildLegend(Colors.grey.shade400, "Penuh"),
              const SizedBox(width: 16),
              _buildLegend(kPrimaryDark, "Dipilih"),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, index) => _buildTableItem(tables[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextSecondary)),
      ],
    );
  }

  Widget _buildTableItem(Map<String, dynamic> table) {
    final tableNumber = table['table_number'] ?? '-';
    final status = table['status'] ?? 'available';
    final isAvailable = status == 'available';
    final isSelected = selectedTable == tableNumber;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      bgColor = kPrimaryDark;
      borderColor = kPrimaryDark;
      textColor = Colors.white;
    } else if (isAvailable) {
      bgColor = kSurface;
      borderColor = kBorder;
      textColor = kTextPrimary;
    } else {
      bgColor = const Color(0xFFF5F5F5);
      borderColor = kBorder;
      textColor = kTextSecondary;
    }

    return GestureDetector(
      onTap: isAvailable
          ? () => setState(() => selectedTable = tableNumber)
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryDark.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.2)
                    : isAvailable
                        ? kPrimary.withOpacity(0.12)
                        : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.table_restaurant_rounded,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : isAvailable
                        ? kPrimaryDark
                        : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tableNumber,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: textColor,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isAvailable ? "Tersedia" : "Penuh",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white.withOpacity(0.85)
                    : isAvailable
                        ? kAvailable
                        : kUnavailable,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return GestureDetector(
      onTap: _showDateTimePicker,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.calendar_today_rounded, size: 20, color: kPrimaryDark),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tanggal & Waktu",
                    style: TextStyle(
                      fontSize: 12,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(selectedDateTime),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm', 'id_ID').format(selectedDateTime),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: kPrimaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Ubah",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateTimePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimaryDark,
            onPrimary: kTextPrimary,
            surface: kSurface,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kPrimaryDark,
            onPrimary: kTextPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });

    _fetchTables();
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: kTextPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: kTextSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: kTextSecondary.withOpacity(0.5),
            fontSize: 13,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 14, right: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: kPrimaryDark),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kPrimaryDark, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: kBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isReady = selectedTable != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isReady
              ? [kPrimary, kPrimaryDark]
              : [Colors.grey.shade300, Colors.grey.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: kPrimaryDark.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _handleSubmitReservation,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: isReady ? kTextPrimary : Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Text(
                  selectedTable != null
                      ? "Konfirmasi Reservasi · Meja $selectedTable"
                      : "Pilih meja dahulu",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isReady ? kTextPrimary : Colors.grey.shade600,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}