import 'dart:convert';

import 'package:bilisail/core/storage/app_database.dart';
import 'package:bilisail/features/settings/application/settings_controller.dart';
import 'package:bilisail/features/settings/data/sqlite_settings_repository.dart';
import 'package:bilisail/features/settings/domain/app_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'phone landscape browsing is enabled by default and survives copies',
    () {
      expect(AppSettings().allowPhoneLandscape, isTrue);
      expect(const AppSettings.defaults().allowPhoneLandscape, isTrue);
      final disabled = AppSettings(allowPhoneLandscape: false)
          .copyWith(theme: AppThemePreference.dark)
          .normalized();
      expect(disabled.allowPhoneLandscape, isFalse);
      expect(disabled.theme, AppThemePreference.dark);
    },
  );

  test('legacy snapshots without the key keep the new default', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SqliteSettingsRepository(database);
    expect((await repository.load()).allowPhoneLandscape, isTrue);
    for (final value in [null, 'yes', 1, <String>[]]) {
      await database.writeSetting(
        'preferences.v1',
        jsonEncode({
          'schemaVersion': 42,
          'allowPhoneLandscape': value,
          'theme': 'dark',
        }),
      );
      final settings = await repository.load();
      expect(settings.allowPhoneLandscape, isTrue);
      expect(settings.theme, AppThemePreference.dark);
    }
  });

  test('the preference persists and reset restores the default', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = SqliteSettingsRepository(database);
    await repository.save(AppSettings(allowPhoneLandscape: false));
    expect((await repository.load()).allowPhoneLandscape, isFalse);
    final snapshot = jsonDecode(
      (await database.readSetting('preferences.v1'))!,
    ) as Map<String, Object?>;
    expect(snapshot['allowPhoneLandscape'], isFalse);
    expect(snapshot['schemaVersion'], greaterThanOrEqualTo(43));

    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(settingsControllerProvider.future);
    await container
        .read(settingsControllerProvider.notifier)
        .setAllowPhoneLandscape(true);
    expect((await repository.load()).allowPhoneLandscape, isTrue);
  });
}
