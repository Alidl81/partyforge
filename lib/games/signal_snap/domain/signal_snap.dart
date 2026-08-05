import 'dart:math' as math;

final class SignalTap {
  const SignalTap({required this.playerId, required this.hostTimeUs, required this.uncertaintyUs});
  final String playerId;
  final int hostTimeUs;
  final double uncertaintyUs;
}

enum SignalSnapOutcomeType { winner, tie, falseStartOnly, noValidTap }

final class SignalSnapOutcome {
  const SignalSnapOutcome({required this.type, required this.playerIds, required this.falseStartIds});
  final SignalSnapOutcomeType type;
  final List<String> playerIds;
  final List<String> falseStartIds;
}

abstract final class SignalSnapResolver {
  static SignalSnapOutcome resolve({required int cueAtHostUs, required List<SignalTap> taps}) {
    final falseStarts = taps.where((tap) => tap.hostTimeUs < cueAtHostUs).map((tap) => tap.playerId).toList();
    final valid = taps.where((tap) => tap.hostTimeUs >= cueAtHostUs).toList()
      ..sort((a, b) => a.hostTimeUs.compareTo(b.hostTimeUs));
    if (valid.isEmpty) {
      return SignalSnapOutcome(
        type: falseStarts.isEmpty ? SignalSnapOutcomeType.noValidTap : SignalSnapOutcomeType.falseStartOnly,
        playerIds: const [],
        falseStartIds: falseStarts,
      );
    }
    final first = valid.first;
    final tied = valid.where((tap) {
      final delta = (tap.hostTimeUs - first.hostTimeUs).abs();
      final combined = math.sqrt(
        first.uncertaintyUs * first.uncertaintyUs +
            tap.uncertaintyUs * tap.uncertaintyUs,
      );
      return delta <= combined;
    }).map((tap) => tap.playerId).toList(growable: false);
    return SignalSnapOutcome(
      type: tied.length > 1 ? SignalSnapOutcomeType.tie : SignalSnapOutcomeType.winner,
      playerIds: tied,
      falseStartIds: falseStarts,
    );
  }
}
