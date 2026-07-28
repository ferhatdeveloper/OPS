// Dosya Adı: appearance_settings_provider.dart
// Açıklama: Görünüm ayarları Riverpod state (font + primary renk)
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/appearance_settings_record.dart';
import 'appearance_settings_store.dart';

/// [appearanceSettingsStoreProvider]: SharedPreferences store
final appearanceSettingsStoreProvider =
    Provider<AppearanceSettingsStore>((ref) {
  return const AppearanceSettingsStore();
});

/// [appearanceSettingsProvider]: Uygulama geneli görünüm state
final appearanceSettingsProvider = StateNotifierProvider<
    AppearanceSettingsNotifier, AppearanceSettingsRecord>((ref) {
  return AppearanceSettingsNotifier(
    ref.watch(appearanceSettingsStoreProvider),
  );
});

/// {@template appearance_settings_notifier}
/// Font / tema rengini yükler, kaydeder ve state'i günceller.
///
/// Kullanım örneği:
/// ```dart
/// ref.read(appearanceSettingsProvider.notifier).apply(record);
/// ```
/// {@endtemplate}
class AppearanceSettingsNotifier
    extends StateNotifier<AppearanceSettingsRecord> {
  /// [_store]: Kalıcılık katmanı
  final AppearanceSettingsStore _store;

  /// {@macro appearance_settings_notifier}
  AppearanceSettingsNotifier(this._store)
      : super(const AppearanceSettingsRecord()) {
    _init();
  }

  /// {@template appearance_settings_notifier_init}
  /// Kayıtlı görünüm ayarlarını yükler.
  /// {@endtemplate}
  Future<void> _init() async {
    try {
      state = await _store.load();
    } catch (_) {
      state = const AppearanceSettingsRecord();
    }
  }

  /// {@template appearance_settings_notifier_apply}
  /// Ayarları kaydeder ve state'i günceller.
  ///
  /// Parametreler:
  /// - [record]: Onaylanan görünüm ayarları
  /// {@endtemplate}
  Future<void> apply(AppearanceSettingsRecord record) async {
    final clamped = record.copyWith(
      fontSize: AppearanceSettingsRecord.clampFontSize(record.fontSize),
    );
    await _store.save(clamped);
    state = clamped;
  }
}
