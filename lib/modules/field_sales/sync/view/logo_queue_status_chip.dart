// Dosya Adı: logo_queue_status_chip.dart
// Açıklama: Sync kuyruğu Logo durum chip’i (dens flat)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template logo_queue_status}
/// Logo sync_queue satır durumu.
///
/// Kullanım örneği:
/// ```dart
/// final s = LogoQueueStatus.fromJob(job);
/// ```
/// {@endtemplate}
enum LogoQueueStatus {
  /// Bekliyor — henüz hata yok
  pending,

  /// Hata — last_error var, retry yok
  error,

  /// Yeniden denenecek — last_error + retry_count > 0
  retry,

  /// Aktarılamadı — retry_count > 5 (dead letter)
  dead;

  /// {@template logo_queue_status_from_job}
  /// sync_queue satırından durum üretir.
  ///
  /// Parametreler:
  /// - [job]: `retry_count`, `last_error` alanlı map
  ///
  /// Dönüş değeri:
  /// - [LogoQueueStatus]: Çözümlenen durum
  /// {@endtemplate}
  static LogoQueueStatus fromJob(Map<String, dynamic> job) {
    final retry = job['retry_count'] as int? ?? 0;
    final error = job['last_error']?.toString();
    final hasError = error != null && error.isNotEmpty;
    if (retry > 5) return LogoQueueStatus.dead;
    if (hasError && retry > 0) return LogoQueueStatus.retry;
    if (hasError) return LogoQueueStatus.error;
    return LogoQueueStatus.pending;
  }

  /// {@template logo_queue_status_l10n_key}
  /// l10n anahtarı.
  /// {@endtemplate}
  String get l10nKey {
    switch (this) {
      case LogoQueueStatus.pending:
        return 'field_sales.logo_queue_status_pending';
      case LogoQueueStatus.error:
        return 'field_sales.logo_queue_status_error';
      case LogoQueueStatus.retry:
        return 'field_sales.logo_queue_status_retry';
      case LogoQueueStatus.dead:
        return 'field_sales.logo_queue_status_dead';
    }
  }

  /// {@template logo_queue_status_color}
  /// Chip metin / vurgu rengi.
  /// {@endtemplate}
  Color get color {
    switch (this) {
      case LogoQueueStatus.pending:
        return const Color(0xFF375A7F);
      case LogoQueueStatus.error:
        return const Color(0xFFE53935);
      case LogoQueueStatus.retry:
        return const Color(0xFFFFA726);
      case LogoQueueStatus.dead:
        return const Color(0xFFC62828);
    }
  }
}

/// {@template logo_queue_status_chip}
/// Dens flat Logo durum chip’i (visit_untransferred trailing kalıbı).
///
/// Kullanım örneği:
/// ```dart
/// LogoQueueStatusChip(status: LogoQueueStatus.pending)
/// ```
/// {@endtemplate}
class LogoQueueStatusChip extends StatelessWidget {
  /// [status]: Gösterilecek Logo kuyruk durumu
  final LogoQueueStatus status;

  /// {@macro logo_queue_status_chip}
  const LogoQueueStatusChip({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final color = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        l10n.translate(status.l10nKey),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
