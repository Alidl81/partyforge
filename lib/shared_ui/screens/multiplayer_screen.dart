import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/party_scaffold.dart';

class MultiplayerScreen extends StatelessWidget {
  const MultiplayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'بازی چندنفره',
      fallbackLocation: '/',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Text(
                'همه روی یک شبکه، بدون اینترنت',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              const Text(
                'یک دستگاه میزبان می‌شود و بقیه با IP، کد جلسه و Token موقت وارد می‌شوند.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              _NetworkActionCard(
                icon: Icons.router_rounded,
                title: 'ساخت اتاق LAN',
                description: 'این دستگاه Host می‌شود و اطلاعات اتصال را نمایش می‌دهد.',
                buttonLabel: 'ایجاد اتاق',
                onPressed: () => context.push('/lan/host'),
              ),
              const SizedBox(height: 16),
              _NetworkActionCard(
                icon: Icons.login_rounded,
                title: 'پیوستن به اتاق',
                description: 'با اطلاعاتی که میزبان نمایش می‌دهد به Lobby وصل شو.',
                buttonLabel: 'ورود به اتاق',
                onPressed: () => context.push('/lan/join'),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.push('/play'),
                icon: const Icon(Icons.grid_view_rounded),
                label: const Text('مشاهدهٔ بازی‌های LAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetworkActionCard extends StatelessWidget {
  const _NetworkActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            CircleAvatar(radius: 34, child: Icon(icon, size: 34)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 5),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 14),
            FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
          ],
        ),
      ),
    );
  }
}
