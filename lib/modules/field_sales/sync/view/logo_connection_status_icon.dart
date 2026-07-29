// Dosya Adı: logo_connection_status_icon.dart
// Açıklama: Logo REST bağlantı durumu göstergesi (yeşil / kırmızı kompakt ikon)
// Oluşturulma Tarihi: 2026-07-29
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-29

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../core/logo/logo_connection_health.dart';

/// {@template logo_connection_status_icon}
/// Ayarlar simgesinin yanında duran dens bağlantı göstergesi.
///
/// Yeşil = Logo REST bağlantısı kuruldu, kırmızı = kurulamadı. Dokunmak
/// uyarı = help erişilebilir ancak pull kimliği eksik. Dokunmak manuel
/// yenileme yapar; otomatik denetim
/// [LogoConnectionHealthChecker.minInterval] ile sınırlıdır (pil koruması).
///
/// Kullanım örneği:
/// ```dart
/// actions: const [LogoConnectionStatusIcon()],
/// ```
/// {@endtemplate}
class LogoConnectionStatusIcon extends StatefulWidget {
  /// [checker]: Sağlık denetleyici (test enjeksiyonu)
  final LogoConnectionHealthChecker? checker;

  /// [autoCheck]: İlk yerleşimde otomatik denetim yapılsın mı
  final bool autoCheck;

  /// {@macro logo_connection_status_icon}
  const LogoConnectionStatusIcon({
    Key? key,
    this.checker,
    this.autoCheck = true,
  }) : super(key: key);

  @override
  State<LogoConnectionStatusIcon> createState() =>
      _LogoConnectionStatusIconState();
}

class _LogoConnectionStatusIconState extends State<LogoConnectionStatusIcon> {
  /// [_greenColor]: Semantic success (kural: 4CAF50)
  static const Color _greenColor = Color(0xFF4CAF50);

  /// [_redColor]: Semantic error (kural: E53935)
  static const Color _redColor = Color(0xFFE53935);

  late LogoConnectionHealthChecker _checker;
  late LogoConnectionHealth _health;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _checker = widget.checker ?? LogoConnectionHealthChecker.shared;
    _health = _checker.last;
    if (widget.autoCheck) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    }
  }

  /// {@template logo_connection_status_icon_refresh}
  /// Bağlantıyı denetler; [force] ile aralık yok sayılır.
  /// {@endtemplate}
  Future<void> _refresh({bool force = false}) async {
    if (_checking) return;
    setState(() => _checking = true);
    final health = await _checker.check(force: force);
    if (!mounted) return;
    setState(() {
      _health = health;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final status = _checking && _health.checkedAt == null
        ? LogoConnectionStatus.checking
        : _health.status;
    final label = _checking
        ? l10n.translate('field_sales.logo_connection_checking')
        : l10n.translate(_health.labelKey);
    final detail = _health.detail;
    final tooltip = detail == null || detail.isEmpty
        ? label
        : '$label · $detail';

    return IconButton(
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: tooltip,
      onPressed: _checking ? null : () => _refresh(force: true),
      icon: _checking
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(_iconFor(status), color: _colorFor(status)),
    );
  }

  /// [_iconFor]: Duruma göre ikon.
  static IconData _iconFor(LogoConnectionStatus status) {
    switch (status) {
      case LogoConnectionStatus.online:
        return Icons.cloud_done;
      case LogoConnectionStatus.credentialsMissing:
        return Icons.warning_amber_rounded;
      case LogoConnectionStatus.offline:
        return Icons.cloud_off;
      case LogoConnectionStatus.checking:
      case LogoConnectionStatus.unknown:
        return Icons.cloud_queue;
    }
  }

  /// [_colorFor]: Yeşil / kırmızı / nötr.
  static Color _colorFor(LogoConnectionStatus status) {
    switch (status) {
      case LogoConnectionStatus.online:
        return _greenColor;
      case LogoConnectionStatus.credentialsMissing:
        return Colors.white70;
      case LogoConnectionStatus.offline:
        return _redColor;
      case LogoConnectionStatus.checking:
      case LogoConnectionStatus.unknown:
        return Colors.white70;
    }
  }
}
