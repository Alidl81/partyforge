import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    children: [
                      _HeroPanel(wide: wide),
                      const SizedBox(height: 22),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: wide ? 3 : 1,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: wide ? 1.8 : 3.2,
                        children: [
                          _HomeAction(
                            icon: Icons.router_outlined,
                            title: 'چندنفره',
                            subtitle: 'ساخت یا ورود به اتاق LAN',
                            onTap: () => context.push('/multiplayer'),
                          ),
                          _HomeAction(
                            icon: Icons.people_alt_outlined,
                            title: 'پروفایل‌ها',
                            subtitle: 'بازیکنان، بردها و رکوردها',
                            onTap: () => context.push('/profiles'),
                          ),
                          _HomeAction(
                            icon: Icons.monitor_heart_outlined,
                            title: 'عیب‌یابی',
                            subtitle: 'وضعیت قابلیت‌ها و شبکه',
                            onTap: () => context.push('/diagnostics'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment:
          wide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'PartyForge',
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          'مجموعه‌ای از بازی‌های واقعی، سریع و گروهی برای دورهمی',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'برای دیدن همهٔ بازی‌ها، قوانین و حالت‌های اجرا وارد بخش بازی شو.',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => context.push('/play'),
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: const Text('بازی'),
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.tertiaryContainer,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: content),
                    const SizedBox(width: 24),
                    const Expanded(child: _HeroIllustration()),
                  ],
                )
              : Column(
                  children: [
                    const SizedBox(height: 190, child: _HeroIllustration()),
                    const SizedBox(height: 16),
                    content,
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.blur_circular_rounded,
          size: 220,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
        ),
        Transform.rotate(
          angle: -0.18,
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(26),
              child: Icon(
                Icons.sports_esports_rounded,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(radius: 27, child: Icon(icon, size: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
