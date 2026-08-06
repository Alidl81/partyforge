import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../games/catalog/game_catalog.dart';
import '../../games/catalog/game_definition.dart';
import '../widgets/party_scaffold.dart';

class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  GamePlayKind? _filter;

  @override
  Widget build(BuildContext context) {
    final games = GameCatalog.games
        .where((game) => _filter == null || game.playKind == _filter)
        .toList(growable: false);

    return PartyScaffold(
      title: 'انتخاب بازی',
      fallbackLocation: '/',
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'امشب چه بازی کنیم؟',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'یک بازی را شروع کن یا اول قوانینش را ببین.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('همه'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                      ChoiceChip(
                        label: const Text('محلی'),
                        avatar: const Icon(Icons.phone_android, size: 18),
                        selected: _filter == GamePlayKind.local,
                        onSelected: (_) =>
                            setState(() => _filter = GamePlayKind.local),
                      ),
                      ChoiceChip(
                        label: const Text('LAN'),
                        avatar: const Icon(Icons.router_outlined, size: 18),
                        selected: _filter == GamePlayKind.lan,
                        onSelected: (_) =>
                            setState(() => _filter = GamePlayKind.lan),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width >= 1100
                    ? 3
                    : width >= 680
                        ? 2
                        : 1;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 18,
                    childAspectRatio: columns == 1 ? 0.82 : 0.86,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _GameCard(game: games[index]),
                    childCount: games.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game});

  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'game-art-${game.id}',
                  child: Image.asset(game.imageAsset, fit: BoxFit.cover),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xB0000000)],
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 14,
                  top: 14,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (game.isNew)
                        const _ImageBadge(
                          icon: Icons.auto_awesome,
                          label: 'جدید',
                        ),
                      _ImageBadge(
                        icon: game.playKind == GamePlayKind.lan
                            ? Icons.router_outlined
                            : Icons.phone_android,
                        label: game.modeLabel,
                      ),
                    ],
                  ),
                ),
                PositionedDirectional(
                  start: 18,
                  end: 18,
                  bottom: 14,
                  child: Text(
                    game.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      game.shortDescription,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.groups_2_outlined,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: Text(game.playerLabel)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/play/${game.id}/info'),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('اطلاعات'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => context.push(game.playRoute),
                          icon: Icon(
                            game.playKind == GamePlayKind.lan
                                ? Icons.router
                                : Icons.play_arrow_rounded,
                          ),
                          label: Text(
                            game.playKind == GamePlayKind.lan
                                ? 'اتصال'
                                : 'شروع',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageBadge extends StatelessWidget {
  const _ImageBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
