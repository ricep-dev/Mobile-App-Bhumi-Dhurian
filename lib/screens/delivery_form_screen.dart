import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DeliveryFormScreen extends StatefulWidget {
  const DeliveryFormScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _DeliveryFormScreenState createState() => _DeliveryFormScreenState();
}

class _DeliveryFormScreenState extends State<DeliveryFormScreen> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _hpController = TextEditingController();

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Layanan lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Izin lokasi ditolak permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print("Latitude: ${position.latitude}, Longitude: ${position.longitude}");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.postalCode}, ${place.country}";

        setState(() {
          _alamatController.text = address;
        });
      } else {
        _showSnackbar('Gagal menemukan alamat dari koordinat');
      }
    } catch (e) {
      print("ERROR: $e");
      _showSnackbar('Terjadi kesalahan saat mengambil lokasi');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Pengantaran'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama'),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _alamatController,
                    decoration: InputDecoration(labelText: 'Alamat Pengantaran'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.my_location),
                  onPressed: _getCurrentLocation,
                  tooltip: 'Isi otomatis dari GPS',
                )
              ],
            ),
            TextField(
              controller: _hpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: 'Nomor HP'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // lanjut ke pembayaran
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30))),
              child: Text('Lanjut ke Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}