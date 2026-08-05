import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLoggerProvider = Provider<AppLogger>((_) => DebugAppLogger());

abstract interface class AppLogger {
  void debug(String event, [Map<String, Object?> fields = const {}]);
  void info(String event, [Map<String, Object?> fields = const {}]);
  void warning(String event, [Map<String, Object?> fields = const {}]);
  void error(String event, Object error, StackTrace stackTrace);
}

final class DebugAppLogger implements AppLogger {
  static const Set<String> _sensitive = {
    'token',
    'joinToken',
    'resumeToken',
    'privatePrompt',
    'roleSecret',
    'sensitivePlayerData',
  };

  @override
  void debug(String event, [Map<String, Object?> fields = const {}]) {
    if (kDebugMode) debugPrint('[D] $event ${_redact(fields)}');
  }

  @override
  void info(String event, [Map<String, Object?> fields = const {}]) {
    if (kDebugMode) debugPrint('[I] $event ${_redact(fields)}');
  }

  @override
  void warning(String event, [Map<String, Object?> fields = const {}]) {
    if (kDebugMode) {
      debugPrint('[W] $event ${_redact(fields)}');
    } else {
      debugPrint('[W] $event');
    }
  }

  @override
  void error(String event, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('[E] $event $error\n$stackTrace');
    } else {
      debugPrint('[E] $event ${error.runtimeType}');
    }
  }

  Map<String, Object?> _redact(Map<String, Object?> fields) {
    return fields.map(
      (key, value) => MapEntry(
        key,
        _sensitive.contains(key) ? '<redacted>' : value,
      ),
    );
  }
}
