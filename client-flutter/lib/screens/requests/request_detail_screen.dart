import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_request.dart';
import '../../providers/data_providers.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/status_chip.dart';
import 'payment_screen.dart';
import 'rating_screen.dart';
import 'complaint_screen.dart';

class RequestDetailScreen extends StatefulWidget {
  final int requestId;
  const RequestDetailScreen({super.key, required this.requestId});
  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  ServiceRequest? _r;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _r = await ApiService.requestDetail(widget.requestId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _simulate() async {
    await ApiService.simulateProgress(widget.requestId);
    await _load();
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy yêu cầu?'),
        content: const Text('Bạn có chắc muốn hủy yêu cầu này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hủy')),
        ],
      ),
    );
    if (ok != true) return;
    if (!mounted) return;
    await context.read<RequestProvider>().cancel(widget.requestId);
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null || _r == null) return Scaffold(appBar: AppBar(), body: Center(child: Text(_error ?? 'Lỗi')));
    final r = _r!;
    return Scaffold(
      appBar: AppBar(title: Text('Yêu cầu #${r.id}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(r.tenDichVu ?? 'Dịch vụ', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                StatusChip(status: r.trangThai),
              ],
            ),
            const SizedBox(height: 12),
            _section('Mô tả', r.moTa),
            _section('Địa chỉ', r.diaChi),
            _section('Khu vực', r.khuVuc),
            if (r.thoiGianMongMuon != null) _section('Thời gian mong muốn', r.thoiGianMongMuon!),
            if (r.thoiGianDuKienToi != null) _section('Thợ dự kiến tới', r.thoiGianDuKienToi!),
            const SizedBox(height: 12),
            if (r.tho != null) _workerCard(r.tho!),
            const SizedBox(height: 12),
            _timeline(r.trangThai),
            const SizedBox(height: 20),
            if (r.trangThai == 'CHO_NHAN' || r.trangThai == 'DA_NHAN') ...[
              ElevatedButton.icon(
                onPressed: _simulate,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Mô phỏng thợ nhận việc (demo)'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: r.trangThai != 'DANG_LAM' ? _cancel : null,
                style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
                child: const Text('Hủy yêu cầu'),
              ),
            ],
            if (r.trangThai == 'DA_NHAN' || r.trangThai == 'DANG_LAM') ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PaymentScreen(requestId: r.id))),
                child: const Text('Xác nhận hoàn tất & thanh toán'),
              ),
            ],
            if (r.trangThai == 'HOAN_TAT') ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RatingScreen(requestId: r.id, workerId: r.tho?.id ?? 0))),
                child: const Text('Đánh giá thợ'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ComplaintScreen(requestId: r.id))),
                child: const Text('Gửi khiếu nại'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: Text(k, style: const TextStyle(color: AppTheme.muted))),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
      );

  Widget _workerCard(WorkerSummary w) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.person, color: AppTheme.primary)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(w.hoTen, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('${w.diemTb.toStringAsFixed(1)} ★ · ${w.soViecDaLam} việc', style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
                  if (w.khuVuc != null) Text(w.khuVuc!, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeline(String status) {
    final steps = ['CHO_NHAN', 'DA_NHAN', 'DANG_LAM', 'HOAN_TAT'];
    final idx = steps.indexOf(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tiến trình', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(steps.length, (i) {
            final done = idx >= i && status != 'HUY';
            return Expanded(
              child: Column(
                children: [
                  Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: done ? AppTheme.primary : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(AppConstants.statusLabel(steps[i]), style: TextStyle(fontSize: 10, color: done ? AppTheme.primary : AppTheme.muted)),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

