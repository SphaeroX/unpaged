import 'package:drift/drift.dart' show InsertMode;
import 'package:unpaged/core/database/app_database.dart';
import 'package:unpaged/features/settings/domain/reader_settings.dart';

const _prefix = 'reader.';

/// Stores [ReaderSettings] as key/value rows in the `preferences` table.
class SettingsRepository {
  new(this.db);

  final AppDatabase db;

  Future<ReaderSettings> load() async {
    final rows = await db.select(db.preferences).get();
    return ReaderSettings.fromMap({
      for (final r in rows)
        if (r.key.startsWith(_prefix)) r.key.substring(_prefix.length): r.value,
    });
  }

  Future<void> save(ReaderSettings settings) => db.batch((b) {
    for (final MapEntry(:key, :value) in settings.toMap().entries) {
      b.insert(
        db.preferences,
        PreferencesCompanion.insert(key: '$_prefix$key', value: value),
        mode: InsertMode.insertOrReplace,
      );
    }
  });
}
