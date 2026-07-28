// Dosya Adı: field_sales_menu_l10n.dart
// Açıklama: FieldSales SQLite menü başlıkları → l10n anahtarı eşlemesi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import '../../../../core/database/migrations/SqlQuerys.dart';

/// {@template field_sales_menu_l10n}
/// Menü seed / migrate için uuid → çeviri anahtarı.
///
/// Kullanım örneği:
/// ```dart
/// final key = FieldSalesMenuL10n.storedTitleForUuid(
///   uuid: 'fs_order',
///   currentTitle: 'Sipariş',
/// );
/// ```
/// {@endtemplate}
class FieldSalesMenuL10n {
  FieldSalesMenuL10n._();

  /// Özel uuid → key (dashboard / stubs).
  static Map<String, String> get overrides =>
      SqlQuerys.fieldSalesMenuL10nByUuid;

  /// {@template field_sales_menu_l10n_title_key}
  /// Varsayılan menü anahtarı: `field_sales.menu.{uuid}`.
  /// {@endtemplate}
  static String titleKey(String uuid) => 'field_sales.menu.$uuid';

  /// Seed satırı için SQLite `title` değeri.
  static String titleForSeed(String uuid, String legacyTitle) {
    final override = overrides[uuid.trim()];
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    final legacy = legacyTitle.trim();
    if (legacy.contains('.')) return legacy;
    return titleKey(uuid.trim());
  }

  /// Migrate: mevcut başlık zaten geçerli dotted key ise dokunma.
  /// Çıplak `fs_*` / `sub_*` (uuid-as-title) → `field_sales.menu.{uuid}`.
  static String storedTitleForUuid({
    required String uuid,
    required String currentTitle,
  }) {
    final trimmedUuid = uuid.trim();
    if (trimmedUuid.isEmpty) return currentTitle;
    final title = currentTitle.trim();
    if (title.contains('.')) {
      // Yanlış strip: yalnızca `….fs_x` ve uuid eşleşiyorsa yeniden yaz
      final last = title.split('.').last;
      if (last == trimmedUuid &&
          !title.startsWith('field_sales.menu.') &&
          !title.startsWith('dashboard.') &&
          !title.startsWith('submodules.')) {
        return titleForSeed(trimmedUuid, title);
      }
      return title;
    }
    return titleForSeed(trimmedUuid, title);
  }
}
