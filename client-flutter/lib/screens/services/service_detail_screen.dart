import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/service.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../requests/create_request_screen.dart';

class ServiceDetailScreen extends StatefulWidget {
  final int serviceId;
  const ServiceDetailScreen({super.key, required this.serviceId});
  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  late Future<Service> _future;
  @override
  void initState() {
    super.initState();
    _future = ApiService.serviceDetail(widget.serviceId);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'vi_VN');
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết dịch vụ')),
      body: FutureBuilder<Service>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          final s = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(child: Icon(Icons.handyman, size: 72, color: AppTheme.primary)),
                ),
                const SizedBox(height: 16),
                Text(s.ten, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                if (s.danhMucTen != null) Text(s.danhMucTen!, style: const TextStyle(color: AppTheme.muted)),
                const SizedBox(height: 12),
                Text(s.moTa ?? '', style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _row('Giá sàn', '${fmt.format(s.giaSan)} đ'),
                        const Divider(),
                        _row('Giá trần', '${fmt.format(s.giaTran)} đ'),
                        const Divider(),
                        _row('Đơn vị', s.donVi),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CreateRequestScreen(prefillServiceId: s.id)),
                  ),
                  child: const Text('Đặt dịch vụ này'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(k, style: const TextStyle(color: AppTheme.muted)), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))],
        ),
      );
}