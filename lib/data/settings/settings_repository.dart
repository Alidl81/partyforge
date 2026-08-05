import 'package:drift/drift.dart';

import '../../core/domain/settings/settings_repository.dart';
import '../database/app_database.dart';

final class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._database);

  final AppDatabase _database;

  @override
  Future<String?> read(String key) async {
    final row = await _database.customSelect(
      'SELECT value FROM app_settings WHERE key = ?',
      variables: [Variable.withString(key)],
      readsFrom: const {},
    ).getSingleOrNull();
    return row?.read<String>('value');
  }

  @override
  Future<void> write(String key, String value) => _database.customStatement(
    'INSERT INTO app_settings(key, value) VALUES (?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    [key, value],
  );
}
