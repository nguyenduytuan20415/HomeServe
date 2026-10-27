import 'package:flutter/material.dart';

class ComplaintScreen extends StatefulWidget {
  final int requestId;
  const ComplaintScreen({super.key, required this.requestId});
  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  final _content = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    if (_content.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập nội dung khiếu nại')));
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi khiếu nại')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gửi khiếu nại')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _content,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Nội dung khiếu nại', hintText: 'Ví dụ: giá vượt bảng giá...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Gửi khiếu nại'),
            ),
          ],
        ),
      ),
    );
  }
}