// Dosya Adı: app_version_label.dart
// Açıklama: pubspec / package_info sürümünü dens satırda gösteren widget
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../localization/app_localization.dart';

/// {@template format_app_version_string}
/// `vX.Y.Z+build` formatında sürüm metni üretir.
///
/// Parametreler:
/// - [version]: Semantik sürüm (ör. `1.0.0`)
/// - [buildNumber]: Build numarası (ör. `1`)
///
/// Dönüş değeri:
/// - [String]: `v1.0.0+1` gibi görünen metin
/// {@endtemplate}
String formatAppVersionString(String version, String buildNumber) {
  final v = version.trim();
  final b = buildNumber.trim();
  if (v.isEmpty) return b.isEmpty ? '' : 'v+$b';
  if (b.isEmpty) return 'v$v';
  return 'v$v+$b';
}

/// {@template app_version_label}
/// package_info_plus ile okunan uygulama sürümünü dens satırda gösterir.
///
/// Kullanım örneği:
/// ```dart
/// const AppVersionLabel()
/// ```
/// {@endtemplate}
class AppVersionLabel extends StatelessWidget {
  /// [compact]: true → yalnızca `vX.Y.Z+build` (etiket yok)
  final bool compact;

  /// [textAlign]: Metin hizası
  final TextAlign textAlign;

  /// {@macro app_version_label}
  const AppVersionLabel({
    super.key,
    this.compact = false,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final info = snapshot.data!;
        final formatted = formatAppVersionString(
          info.version,
          info.buildNumber,
        );
        if (formatted.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalization.of(context);
        final versionText = l10n.translate(
          'common.app_version',
          args: {'version': '${info.version}+${info.buildNumber}'},
        );
        final label = l10n.translate('field_sales.app_version_label');
        final display = compact ? versionText : '$label  $versionText';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            display,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color ??
                  Colors.grey[600],
            ),
          ),
        );
      },
    );
  }
}
