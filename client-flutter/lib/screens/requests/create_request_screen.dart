import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/data_providers.dart';
import 'request_detail_screen.dart';

class CreateRequestScreen extends StatefulWidget {
  final int? prefillServiceId;
  const CreateRequestScreen({super.key, this.prefillServiceId});
  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _desc = TextEditingController();
  final _addr = TextEditingController();
  final _area = TextEditingController();
  final _time = TextEditingController();
  int? _serviceId;
  final List<String> _images = [];
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _serviceId = widget.prefillServiceId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadServices();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x != null) setState(() => _images.add(x.path));
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn dịch vụ')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final r = await context.read<RequestProvider>().create(
            dichVuId: _serviceId!,
            moTa: _desc.text.trim(),
            diaChi: _addr.text.trim(),
            khuVuc: _area.text.trim(),
            thoiGianMongMuon: _time.text.trim().isEmpty ? null : _time.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo yêu cầu')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: r.id)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final services = sp.services;
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo yêu cầu dịch vụ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _serviceId,
                decoration: const InputDecoration(labelText: 'Dịch vụ', prefixIcon: Icon(Icons.build_outlined)),
                items: services.map((s) => DropdownMenuItem(value: s.id, child: Text(s.ten))).toList(),
                onChanged: (v) => setState(() => _serviceId = v),
                validator: (v) => v == null ? 'Chọn dịch vụ' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Mô tả vấn đề', prefixIcon: Icon(Icons.description_outlined)),
                validator: (v) => (v == null || v.trim().length < 5) ? 'Mô tả ít nhất 5 ký tự' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addr,
                decoration: const InputDecoration(labelText: 'Địa chỉ', prefixIcon: Icon(Icons.location_on_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa chỉ' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _area,
                decoration: const InputDecoration(labelText: 'Khu vực (quận/huyện)', prefixIcon: Icon(Icons.map_outlined)),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập khu vực' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _time,
                decoration: const InputDecoration(labelText: 'Thời gian mong muốn (tuỳ chọn)', prefixIcon: Icon(Icons.schedule)),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Ảnh/video', style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.add_a_photo), label: const Text('Thêm ảnh')),
                ],
              ),
              if (_images.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_images[i], width: 90, height: 90, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: Colors.grey.shade200, child: const Icon(Icons.image))),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Gửi yêu cầu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}