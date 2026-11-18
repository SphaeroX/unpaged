import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paperflow/core/database/app_database.dart';
import 'package:paperflow/features/settings/data/settings_repository.dart';
import 'package:paperflow/features/settings/domain/reader_settings.dart';

/// Current reading settings; every change is applied at once and saved.
class ReaderSettingsController extends AsyncNotifier<ReaderSettings> {
  SettingsRepository get _repository =>
      SettingsRepository(ref.read(databaseProvider));

  @override
  Future<ReaderSettings> build() => _repository.load();

  Future<void> change(ReaderSettings Function(ReaderSettings) apply) async {
    final next = apply(state.value ?? ReaderSettings.defaults);
    state = AsyncData(next);
    await _repository.save(next);
  }
}

final readerSettingsProvider =
    AsyncNotifierProvider<ReaderSettingsController, ReaderSettings>(
      ReaderSettingsController.new,
    );
