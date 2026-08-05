import 'package:flutter/material.dart';

import '../../core/domain/scoring/score_event.dart';

class PartyScoreboard extends StatelessWidget {
  const PartyScoreboard({super.key, required this.scores});

  final List<RankedScore> scores;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: scores.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final score = scores[index];
        return ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(score.playerId),
          trailing: Text(
            '${score.rawScore}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        );
      },
    );
  }
}
