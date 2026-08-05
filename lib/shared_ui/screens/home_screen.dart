import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PartyForge')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: GridView.count(
            padding: const EdgeInsets.all(24),
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 2 : 1,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              _Tile(icon: Icons.timer, title: 'قفل زمان', subtitle: 'توقف در زمان هدف', onTap: () => context.go('/games/chrono-lock')),
              _Tile(icon: Icons.people, title: 'پروفایل‌ها', subtitle: 'بازیکنان محلی', onTap: () => context.go('/profiles')),
              _Tile(icon: Icons.router, title: 'ساخت اتاق LAN', subtitle: 'این دستگاه Host می‌شود', onTap: () => context.go('/lan/host')),
              _Tile(icon: Icons.login, title: 'پیوستن به اتاق', subtitle: 'ورود دستی IP و کد جلسه', onTap: () => context.go('/lan/join')),
              _Tile(icon: Icons.monitor_heart, title: 'عیب‌یابی', subtitle: 'قابلیت‌ها و وضعیت دستگاه', onTap: () => context.go('/diagnostics')),
            ],
          ),
        ),
      ),
    );
  }

}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Icon(icon, size: 48),
          const SizedBox(width: 20),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(subtitle),
          ])),
          const Icon(Icons.chevron_left),
        ]),
      ),
    ),
  );
}
