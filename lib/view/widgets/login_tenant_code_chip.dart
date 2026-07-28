// Dosya Adı: login_tenant_code_chip.dart
// Açıklama: Login üst ikon çubuğu dens bina + minimal kiracı kodu
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../core/localization/app_localization.dart';
import '../../core/utils/color_utils.dart';

/// {@template login_tenant_chip_data}
/// Login kartı üst ikon çubuğundaki dens kiracı chip durumu.
///
/// Kayıtlı/bağlıyken header’da bina + kısa kod (`T: ABC`).
/// Kayıtlı değilken form dens TextField; header chip gizli.
/// Tap → Değiştir dialog.
///
/// Kullanım örneği:
/// ```dart
/// final n = ValueNotifier(const LoginTenantChipData());
/// ```
/// {@endtemplate}
class LoginTenantChipData {
  /// [tenantCode]: Görünen / düzenlenen kiracı kodu
  final String tenantCode;

  /// [gatePassed]: Kiracı bağlandı mı (backend durumu)
  final bool gatePassed;

  /// [loadDone]: Prefs yüklemesi bitti mi
  final bool loadDone;

  /// [busy]: Bağlan / login yükleniyor
  final bool busy;

  /// {@macro login_tenant_chip_data}
  const LoginTenantChipData({
    this.tenantCode = '',
    this.gatePassed = false,
    this.loadDone = false,
    this.busy = false,
  });

  /// Header chip: yalnızca kayıtlı/bağlı kiracıda (kod + Değiştir)
  bool get visible => loadDone && gatePassed;

  /// Minimal gösterim için kısaltılmış kod (max 8)
  String get shortCode {
    final c = tenantCode.trim();
    if (c.isEmpty) return '';
    if (c.length <= 8) return c;
    return '${c.substring(0, 7)}…';
  }

  /// {@template login_tenant_chip_data_copy_with}
  /// Kopya ile güncellenmiş örnek döner.
  /// {@endtemplate}
  LoginTenantChipData copyWith({
    String? tenantCode,
    bool? gatePassed,
    bool? loadDone,
    bool? busy,
  }) {
    return LoginTenantChipData(
      tenantCode: tenantCode ?? this.tenantCode,
      gatePassed: gatePassed ?? this.gatePassed,
      loadDone: loadDone ?? this.loadDone,
      busy: busy ?? this.busy,
    );
  }
}

/// {@template login_tenant_code_chip}
/// Üst ikon çubuğu dens bina + minimal kiracı kodu.
/// Boşsa sadece ikon / "Kiracı"; doluysa ikon + kısa kod.
///
/// Kullanım örneği:
/// ```dart
/// LoginTenantCodeChip(
///   tenantCode: 'lovan',
///   onPressed: () {},
/// )
/// ```
/// {@endtemplate}
class LoginTenantCodeChip extends StatelessWidget {
  /// Widget test / semantik anahtarı
  static const Key tapKey = Key('login_tenant_code_chip');

  /// Dolu chip l10n (`{code}`)
  static const String labelKey = 'auth.tenant_chip';

  /// Boş chip l10n
  static const String emptyLabelKey = 'auth.tenant_chip_empty';

  /// [tenantCode]: Mevcut kod (boş olabilir)
  final String tenantCode;

  /// [busy]: Bağlanırken spinner
  final bool busy;

  /// [onPressed]: Tap — dialog / Bağlan / Değiştir
  final VoidCallback? onPressed;

  /// {@macro login_tenant_code_chip}
  const LoginTenantCodeChip({
    Key? key,
    required this.tenantCode,
    this.busy = false,
    this.onPressed,
  }) : super(key: key);

  /// {@template login_tenant_code_chip_resolve_label}
  /// Chip görünür metni (l10n) — tooltip / erişilebilirlik.
  ///
  /// Parametreler:
  /// - [l10n]: Yerelleştirme
  /// - [tenantCode]: Kiracı kodu
  ///
  /// Dönüş değeri:
  /// - [String]: Chip metni (`T: {code}`)
  /// {@endtemplate}
  static String resolveLabel(AppLocalization l10n, String tenantCode) {
    final code = tenantCode.trim();
    if (code.isEmpty) {
      return l10n.translate(emptyLabelKey);
    }
    final short = code.length <= 8 ? code : '${code.substring(0, 7)}…';
    return l10n.translate(labelKey, args: {'code': short});
  }

  /// Minimal satır metni: `T: kod` veya boş placeholder
  static String resolveShortDisplay(
    AppLocalization l10n,
    String tenantCode,
  ) {
    return resolveLabel(l10n, tenantCode);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final tooltip = resolveLabel(l10n, tenantCode);
    final short = resolveShortDisplay(l10n, tenantCode);
    final hasCode = tenantCode.trim().isNotEmpty;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    const accent = Color(0xFF054F99);
    final radius = BorderRadius.circular(8);

    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: tapKey,
            onTap: busy ? null : onPressed,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? ColorUtils.withAlpha(colorScheme.surface, 0.5)
                    : Colors.grey[200],
                borderRadius: radius,
                border: Border.all(
                  color: ColorUtils.withAlpha(accent, 0.22),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: accent,
                      ),
                    )
                  else
                    const Icon(
                      Icons.apartment,
                      size: 16,
                      color: accent,
                    ),
                  if (!busy) ...[
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 72),
                      child: Text(
                        short,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              hasCode ? FontWeight.w600 : FontWeight.w400,
                          color: accent,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
