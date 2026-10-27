import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final body = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 44, color: AppTheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(user?.hoTen ?? 'Khách', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        Center(child: Text(user?.email ?? '', style: const TextStyle(color: AppTheme.muted))),
        const SizedBox(height: 24),
        _tile(Icons.phone, 'Số điện thoại', user?.sdt ?? '—'),
        _tile(Icons.badge, 'Vai trò', user?.vaiTro ?? '—'),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Dùng dữ liệu mẫu (mock)'),
          subtitle: const Text('Tắt để gọi backend thật'),
          value: true,
          onChanged: (_) {},
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }
          },
          child: const Text('Đăng xuất'),
        ),
      ],
    );
    if (widget.embedded) return SafeArea(child: body);
    return Scaffold(appBar: AppBar(title: const Text('Cá nhân')), body: body);
  }

  Widget _tile(IconData icon, String k, String v) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppTheme.primary),
          title: Text(k, style: const TextStyle(color: AppTheme.muted, fontSize: 13)),
          subtitle: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );
}