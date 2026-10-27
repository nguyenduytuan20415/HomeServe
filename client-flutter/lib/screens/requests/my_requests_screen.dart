import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/data_providers.dart';
import '../../widgets/cards.dart';
import '../../widgets/empty_state.dart';
import 'request_detail_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  final bool embedded;
  const MyRequestsScreen({super.key, this.embedded = false});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  String? _filter;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<RequestProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final list = _filter == null ? rp.requests : rp.requests.where((r) => r.trangThai == _filter).toList();
    final body = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('Tất cả', null),
                _chip('Chờ nhận', 'CHO_NHAN'),
                _chip('Đã nhận', 'DA_NHAN'),
                _chip('Đang làm', 'DANG_LAM'),
                _chip('Hoàn tất', 'HOAN_TAT'),
                _chip('Đã hủy', 'HUY'),
              ],
            ),
          ),
        ),
        Expanded(
          child: rp.loading && rp.requests.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : list.isEmpty
                  ? const EmptyState(title: 'Chưa có yêu cầu nào', icon: Icons.receipt_long_outlined)
                  : RefreshIndicator(
                      onRefresh: () => rp.load(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        itemBuilder: (_, i) => RequestCard(
                          request: list[i],
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: list[i].id)),
                          ),
                        ),
                      ),
                    ),
        ),
      ],
    );
    if (widget.embedded) return SafeArea(child: body);
    return Scaffold(
      appBar: AppBar(title: const Text('Đơn của tôi')),
      body: body,
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}