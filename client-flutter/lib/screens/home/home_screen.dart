import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/cards.dart';
import '../services/service_list_screen.dart';
import '../services/service_detail_screen.dart';
import '../requests/my_requests_screen.dart';
import '../requests/create_request_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadCategories();
      context.read<ServiceProvider>().loadServices();
      context.read<RequestProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      const MyRequestsScreen(embedded: true),
      const ProfileScreen(embedded: true),
    ];
    return Scaffold(
      body: pages[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Đơn của tôi'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Cá nhân'),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Đặt dịch vụ'),
            )
          : null,
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final auth = context.watch<AuthProvider>();
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await sp.loadCategories();
          await sp.loadServices();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Xin chào, ${auth.user?.hoTen ?? 'bạn'}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('Hôm nay bạn cần sửa gì?', style: TextStyle(color: AppTheme.muted)),
                        ],
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Tìm dịch vụ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (q) {
                    // filter handled below via provider.services already loaded; simple
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: const Text('Danh mục', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
            if (sp.loading && sp.categories.isEmpty)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())))
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: sp.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = sp.categories[i];
                      return GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ServiceListScreen(category: c)),
                        ),
                        child: Container(
                          width: 90,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(backgroundColor: AppTheme.primary.withValues(alpha: 0.1), child: const Icon(Icons.build, color: AppTheme.primary)),
                              const SizedBox(height: 8),
                              Text(c.ten, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                              Text('${c.soDichVu} dịch vụ', style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: const Text('Dịch vụ phổ biến', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
            ),
            if (sp.services.isEmpty && !sp.loading)
              const SliverToBoxAdapter(child: EmptyState(title: 'Chưa có dịch vụ'))
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => ServiceCard(
                      service: sp.services[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ServiceDetailScreen(serviceId: sp.services[i].id)),
                      ),
                    ),
                    childCount: sp.services.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}