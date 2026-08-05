import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partyforge/core/domain/scoring/score_event.dart';
import 'package:partyforge/multiplayer/presentation/lobby_screen.dart';
import 'package:partyforge/multiplayer/protocol/lobby_snapshot.dart';
import 'package:partyforge/shared_ui/widgets/party_scoreboard.dart';

void main() {
  testWidgets('lobby shows players and ready action', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          snapshot: const LobbySnapshot(
            sessionId: 's',
            revision: 1,
            selectedGameId: 'chrono_lock',
            players: [
              LobbyPlayer(
                playerId: 'p1',
                displayName: 'آرین',
                ready: true,
                seatIndex: 0,
              ),
            ],
          ),
          onReady: () => pressed = true,
        ),
      ),
    );

    expect(find.text('آرین'), findsOneWidget);
    await tester.tap(find.text('آماده‌ام'));
    expect(pressed, isTrue);
  });

  testWidgets('scoreboard displays ordered scores', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PartyScoreboard(
            scores: [
              RankedScore(playerId: 'A', rawScore: 100),
              RankedScore(playerId: 'B', rawScore: 50),
            ],
          ),
        ),
      ),
    );

    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });
}
