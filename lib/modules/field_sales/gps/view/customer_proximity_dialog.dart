// Dosya Adı: customer_proximity_dialog.dart
// Açıklama: Yakın müşteri ziyaret teklifi dens diyalog
// Oluşturulma Tarihi: 2026-07-27
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-27

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template show_customer_proximity_dialog}
/// "{name} müşteri yakın mesafede, ziyaret etmek ister misiniz?" dens dialog.
///
/// Dönüş değeri:
/// - `true`: Evet → ziyaret
/// - `false` / `null`: Hayır / kapat
///
/// Kullanım örneği:
/// ```dart
/// final ok = await showCustomerProximityDialog(context, name: 'ABC');
/// ```
/// {@endtemplate}
Future<bool?> showCustomerProximityDialog(
  BuildContext context, {
  required String customerName,
}) {
  final l10n = AppLocalization.of(context);
  final prompt = l10n.translate(
    'field_sales.proximity_visit_prompt',
    args: {'name': customerName},
  );

  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        title: Text(
          l10n.translate('field_sales.proximity_visit_title'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          prompt,
          style: const TextStyle(fontSize: 13),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.translate('common.no'),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.translate('common.yes'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    },
  );
}
