import '../../../core/random/seeded_random.dart';

final class SecretRoleAssignment {
  const SecretRoleAssignment({required this.playerId, required this.prompt, required this.isImposter});
  final String playerId;
  final String prompt;
  final bool isImposter;
}

final class VectorStroke {
  const VectorStroke({required this.points, required this.width});
  final List<(double, double)> points;
  final double width;
}

abstract final class SketchImposterEngine {
  static List<SecretRoleAssignment> assignRoles({
    required List<String> playerIds,
    required String mainPrompt,
    required String similarPrompt,
    required SeededRandom random,
  }) {
    if (playerIds.length < 3) throw ArgumentError('At least three players are required.');
    final imposterIndex = random.nextInt(playerIds.length);
    return List.generate(playerIds.length, (index) => SecretRoleAssignment(
      playerId: playerIds[index],
      prompt: index == imposterIndex ? similarPrompt : mainPrompt,
      isImposter: index == imposterIndex,
    ), growable: false);
  }

  static String? validateVote({
    required String voterId,
    required String targetId,
    required Set<String> playerIds,
    required Map<String, String> existingVotes,
  }) {
    if (!playerIds.contains(voterId) || !playerIds.contains(targetId)) return 'بازیکن نامعتبر است.';
    if (voterId == targetId) return 'رأی به خود مجاز نیست.';
    if (existingVotes.containsKey(voterId)) return 'رأی قبلاً ثبت شده است.';
    return null;
  }
}
