import 'package:flutter/material.dart';

import '../protocol/lobby_snapshot.dart';

class LobbyScreen extends StatelessWidget {
  const LobbyScreen({
    super.key,
    required this.snapshot,
    this.onReady,
  });

  final LobbySnapshot snapshot;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lobby')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final player in snapshot.players)
            ListTile(
              key: ValueKey(player.playerId),
              leading: CircleAvatar(child: Text('${player.seatIndex + 1}')),
              title: Text(player.displayName),
              trailing: Icon(
                player.ready ? Icons.check_circle : Icons.hourglass_empty,
                semanticLabel: player.ready ? 'آماده' : 'منتظر',
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onReady,
            icon: const Icon(Icons.check),
            label: const Text('آماده‌ام'),
          ),
        ],
      ),
    );
  }
}
