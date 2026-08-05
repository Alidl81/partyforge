import 'dart:convert';
import 'dart:math';

final class ExpiringToken {
  const ExpiringToken({required this.value, required this.expiresAt});
  final String value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}

final class TokenService {
  TokenService({Random? secureRandom}) : _random = secureRandom ?? Random.secure();
  final Random _random;

  ExpiringToken issue({Duration lifetime = const Duration(minutes: 2)}) {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256), growable: false);
    return ExpiringToken(
      value: base64UrlEncode(bytes).replaceAll('=', ''),
      expiresAt: DateTime.now().toUtc().add(lifetime),
    );
  }
}
