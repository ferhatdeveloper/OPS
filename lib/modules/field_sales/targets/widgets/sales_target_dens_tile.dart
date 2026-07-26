// Dosya Adı: sales_target_dens_tile.dart
// Açıklama: Satış hedefi dens liste satırı (plasiyer · tür · ilerleme)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/sales_target_record.dart';

/// {@template sales_target_dens_tile}
/// Satış hedefi dens kart satırı — mevcut announcements dens token’ları.
///
/// Kullanım örneği:
/// ```dart
/// SalesTargetDensTile(record: row, l10n: l10n);
/// ```
/// {@endtemplate}
class SalesTargetDensTile extends StatelessWidget {
  /// [record]: Dens satır kaydı
  final SalesTargetRecord record;

  /// [l10n]: Çeviri
  final AppLocalization l10n;

  /// {@macro sales_target_dens_tile}
  const SalesTargetDensTile({
    Key? key,
    required this.record,
    required this.l10n,
  }) : super(key: key);

  /// {@template sales_target_dens_tile_type_label}
  /// Hedef türü l10n etiketi.
  /// {@endtemplate}
  static String typeLabel(AppLocalization l10n, String type) {
    switch (type.trim().toLowerCase()) {
      case 'collection':
        return l10n.translate('field_sales.sales_targets.type_collection');
      case 'visit':
        return l10n.translate('field_sales.sales_targets.type_visit');
      case 'sales':
      default:
        return l10n.translate('field_sales.sales_targets.type_sales');
    }
  }

  /// {@template sales_target_dens_tile_format_amount}
  /// Tutar / adet dens metni (binlik ayırıcısız sade).
  /// {@endtemplate}
  static String formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final typeText = typeLabel(l10n, record.type);
    final progress = l10n
        .translate('field_sales.sales_targets.progress_fmt')
        .replaceAll('{achieved}', formatAmount(record.achievedAmount))
        .replaceAll('{target}', formatAmount(record.targetAmount));
    final percent = l10n
        .translate('field_sales.sales_targets.percent_fmt')
        .replaceAll(
          '{percent}',
          record.achievementPercent.toStringAsFixed(1),
        );
    final ratio = record.achievementRatio.clamp(0.0, 1.0);
    final barColor = record.achievementPercent >= 100
        ? Colors.green
        : (record.achievementPercent > 50
            ? const Color(0xFF00A8E8)
            : Colors.orange);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF375A7F).withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            record.userId,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$typeText · ${record.period}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: barColor,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                percent,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
