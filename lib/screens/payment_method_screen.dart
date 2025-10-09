import 'package:flutter/material.dart';
import 'dart:math';

class PaymentMethodScreen extends StatefulWidget {
  final String orderType;
  final Map<String, String> orderDetails;

  const PaymentMethodScreen({
    super.key,
    required this.orderType,
    required this.orderDetails,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String? _selectedMethod;
  String? _generatedCode;

  void _generatePaymentCode(String method) {
    final random = Random();
    String code;

    switch (method) {
      case 'QRIS':
        code = 'QRIS-${random.nextInt(9999999999).toString().padLeft(10, '0')}';
        break;
      case 'OVO':
        code = 'OVO-${random.nextInt(999999999).toString().padLeft(9, '0')}';
        break;
      case 'GoPay':
        code = 'GOPAY-${random.nextInt(999999999).toString().padLeft(9, '0')}';
        break;
      case 'DANA':
        code = 'DANA-${random.nextInt(999999999).toString().padLeft(9, '0')}';
        break;
      case 'Bank Transfer':
        code = 'VA-${random.nextInt(999999999999).toString().padLeft(12, '0')}';
        break;
      default:
        code = '';
    }

    setState(() {
      _generatedCode = code;
    });
  }

  Widget _buildPaymentButton(String method) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedMethod = method;
        });
        _generatePaymentCode(method);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade700,
        minimumSize: const Size.fromHeight(50),
      ),
      child: Text(method),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderDetails = widget.orderDetails;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Metode Pembayaran'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan (${widget.orderType.toUpperCase()}):',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text('Nama: ${orderDetails['name']}'),
            Text('Alamat: ${orderDetails['address']}'),
            Text('No HP: ${orderDetails['phone']}'),
            const SizedBox(height: 20),

            _buildPaymentButton('QRIS'),
            const SizedBox(height: 12),
            _buildPaymentButton('OVO'),
            const SizedBox(height: 12),
            _buildPaymentButton('GoPay'),
            const SizedBox(height: 12),
            _buildPaymentButton('DANA'),
            const SizedBox(height: 12),
            _buildPaymentButton('Bank Transfer'),
            const SizedBox(height: 24),

            if (_generatedCode != null)
              Card(
                color: Colors.grey.shade100,
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: ListTile(
                  title: Text(
                    'Kode Pembayaran ($_selectedMethod)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _generatedCode!,
                    style: const TextStyle(fontSize: 20, color: Colors.black87),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kode disalin ke clipboard')),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
