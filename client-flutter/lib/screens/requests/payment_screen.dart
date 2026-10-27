import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final int requestId;
  const PaymentScreen({super.key, required this.requestId});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _method = 'TienMat';
  bool _processing = false;

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thanh toán thành công')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: const [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Tổng tiền'), Text('350.000 đ', style: TextStyle(fontWeight: FontWeight.bold))]),
                    SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Hoa hồng (10%)'), Text('35.000 đ')]),
                    SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Thợ nhận', style: TextStyle(fontWeight: FontWeight.w600)), Text('315.000 đ', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primary))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Phương thức thanh toán', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            RadioListTile<String>(value: 'TienMat', groupValue: _method, title: const Text('Tiền mặt'), onChanged: (v) => setState(() => _method = v!)),
            RadioListTile<String>(value: 'ChuyenKhoan', groupValue: _method, title: const Text('Chuyển khoản'), onChanged: (v) => setState(() => _method = v!)),
            RadioListTile<String>(value: 'ViDienTu', groupValue: _method, title: const Text('Ví điện tử'), onChanged: (v) => setState(() => _method = v!)),
            const Spacer(),
            ElevatedButton(
              onPressed: _processing ? null : _pay,
              child: _processing
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Xác nhận thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}