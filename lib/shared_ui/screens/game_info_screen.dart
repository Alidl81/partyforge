import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../games/catalog/game_definition.dart';
import '../widgets/party_scaffold.dart';

class GameInfoScreen extends StatelessWidget {
  const GameInfoScreen({super.key, required this.game});

  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    return PartyScaffold(
      title: 'دربارهٔ ${game.title}',
      fallbackLocation: '/play',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final image = Hero(
            tag: 'game-art-${game.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.asset(game.imageAsset, fit: BoxFit.cover),
              ),
            ),
          );
          final details = _GameDetails(game: game);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: image),
                          const SizedBox(width: 28),
                          Expanded(child: details),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          image,
                          const SizedBox(height: 24),
                          details,
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: () => context.push(game.playRoute),
          icon: Icon(
            game.playKind == GamePlayKind.lan
                ? Icons.router_outlined
                : Icons.play_arrow_rounded,
          ),
          label: Text(
            game.playKind == GamePlayKind.lan
                ? 'رفتن به بخش چندنفره'
                : 'شروع ${game.title}',
          ),
        ),
      ),
    );
  }
}

class _GameDetails extends StatelessWidget {
  const _GameDetails({required this.game});

  final GameDefinition game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                game.title,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),
            if (game.isNew)
              const Chip(
                avatar: Icon(Icons.auto_awesome, size: 18),
                label: Text('جدید'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetaChip(icon: Icons.groups_2_outlined, label: game.playerLabel),
            _MetaChip(
              icon: game.playKind == GamePlayKind.lan
                  ? Icons.router_outlined
                  : Icons.phone_android,
              label: game.modeLabel,
            ),
            _MetaChip(icon: Icons.speed_outlined, label: game.difficultyLabel),
          ],
        ),
        const SizedBox(height: 20),
        Text(game.description, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        Text('روش بازی', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (var index = 0; index < game.instructions.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(game.instructions[index])),
              ],
            ),
          ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final tag in game.tags) Chip(label: Text(tag))],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}
