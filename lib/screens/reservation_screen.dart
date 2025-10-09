import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // <-- WAJIB DITAMBAHKAN

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final TextEditingController guestCountController = TextEditingController();
  final TextEditingController specialRequestController = TextEditingController();
  DateTime selectedDateTime = DateTime.now();

  String? selectedTable;

  // Dummy 35 meja, setiap kelipatan 5 tidak tersedia
  final List<Map<String, dynamic>> tables = List.generate(35, (index) {
    return {
      "number": "M${index + 1}",
      "available": (index + 1) % 5 != 0,
    };
  });

  @override
  void dispose() {
    guestCountController.dispose();
    specialRequestController.dispose();
    super.dispose();
  }

  // --- FUNGSI UTAMA UNTUK MENGIRIM DATA (DENGAN PERBAIKAN) ---
  void _handleSubmitReservation() {
    // Menambahkan validasi input
    if (selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih meja terlebih dahulu!")),
      );
      return;
    }
    if (guestCountController.text.trim().isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah tamu tidak boleh kosong!")),
      );
      return;
    }

    final reservationData = {
      "table_number": selectedTable,
      // [PERBAIKAN UTAMA] Kirim objek DateTime ASLI, bukan String.
      // Ini akan memperbaiki error TypeError di halaman ConfirmationScreen.
      "reservation_time": selectedDateTime,
      "guest_count": int.tryParse(guestCountController.text) ?? 1,
      "special_request": specialRequestController.text.trim(),
    };

    // Kirim data Map kembali ke ConfirmationScreen
    Navigator.pop(context, reservationData);
  }

  // --- UI (WIDGET BUILD) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reservasi Meja"),
        backgroundColor: const Color(0xFFFDD835),
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Pilih Meja",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: tables.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final table = tables[index];
                final isAvailable = table['available'] as bool;
                final isSelected = selectedTable == table['number'];

                return GestureDetector(
                  onTap: () {
                    if (isAvailable) {
                      setState(() {
                        selectedTable = table['number'];
                      });
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? (isSelected ? Colors.green[400] : Colors.white)
                          : Colors.grey.shade300,
                      border: Border.all(
                        color: isSelected ? Colors.green[700]! : Colors.grey.shade400,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          table['number'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAvailable ? (isSelected ? Colors.white : Colors.black) : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAvailable ? "Tersedia" : "Penuh",
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildDateTimePicker(),
            const SizedBox(height: 20),
            _buildTextField("Jumlah Tamu", guestCountController, TextInputType.number),
            const SizedBox(height: 20),
            _buildTextField("Permintaan Khusus (opsional)", specialRequestController),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleSubmitReservation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD835),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                child: const Text("Kirim Reservasi"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      [TextInputType type = TextInputType.text]) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      title: const Text("Waktu Reservasi"),
      subtitle: Text(
        // [PENINGKATAN UI] Menggunakan intl untuk format yang lebih baik
        DateFormat('EEEE, dd MMMM yyyy - HH:mm', 'id_ID').format(selectedDateTime),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      trailing: const Icon(Icons.calendar_month),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDateTime,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (date == null) return; // User menekan cancel

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
        );
        if (time == null) return; // User menekan cancel

        setState(() {
          selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      },
    );
  }
}