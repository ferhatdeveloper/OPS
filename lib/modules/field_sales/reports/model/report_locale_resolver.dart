// Dosya Adı: report_locale_resolver.dart
// Açıklama: Rapor PDF dili — dizayn → ayar varsayılanı → uygulama dili
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import '../../../../core/localization/app_localization.dart';

/// {@template report_locale_resolver}
/// Rapor çıktı dilini çözümler.
///
/// Öncelik: layout.locale → ayarlar varsayılanı → uygulama dili.
///
/// Kullanım örneği:
/// ```dart
/// final code = ReportLocaleResolver.resolve(
///   layoutLocale: layout.locale,
///   settingsDefault: 'en',
///   appLocale: 'tr',
/// );
/// ```
/// {@endtemplate}
class ReportLocaleResolver {
  ReportLocaleResolver._();

  /// Desteklenen rapor dil kodları (uygulama locale’leri).
  static List<String> get supportedCodes {
    final codes = <String>[];
    for (final loc in AppLocalization.supportedLocales()) {
      final c = loc.languageCode;
      if (c == 'ckb') continue;
      if (!codes.contains(c)) codes.add(c);
    }
    return codes;
  }

  /// {@template report_locale_resolver_normalize}
  /// Dil kodunu desteklenen forma getirir; yoksa null.
  ///
  /// Parametreler:
  /// - [raw]: Ham dil kodu
  ///
  /// Dönüş değeri:
  /// - [String?]: Normalize kod veya null
  /// {@endtemplate}
  static String? normalize(String? raw) {
    final code = (raw ?? '').trim().toLowerCase();
    if (code.isEmpty) return null;
    if (code == 'ckb') return 'ku';
    if (supportedLanguageFiles.containsKey(code)) return code;
    return null;
  }

  /// {@template report_locale_resolver_resolve}
  /// Fall-back zinciri ile dil kodu üretir.
  ///
  /// Parametreler:
  /// - [layoutLocale]: Dizayn override
  /// - [settingsDefault]: Ayarlar varsayılanı
  /// - [appLocale]: Uygulama dili
  ///
  /// Dönüş değeri:
  /// - [String]: Kullanılacak dil kodu
  /// {@endtemplate}
  static String resolve({
    String? layoutLocale,
    String? settingsDefault,
    required String appLocale,
  }) {
    return normalize(layoutLocale) ??
        normalize(settingsDefault) ??
        normalize(appLocale) ??
        'tr';
  }
}
