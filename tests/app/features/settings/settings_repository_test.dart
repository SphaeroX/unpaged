import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/features/settings/data/settings_repository.dart';
import 'package:paperflow/features/settings/domain/reader_settings.dart';

void main() {
  test('loads defaults from an empty database', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await SettingsRepository(db).load(), ReaderSettings.defaults);
  });

  test('saved settings survive reopening the repository', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final saved = ReaderSettings.defaults
        .copyWith(theme: ReaderTheme.dark)
        .biggerFont();

    await SettingsRepository(db).save(saved);

    expect(await SettingsRepository(db).load(), saved);
  });
}
