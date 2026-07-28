// Dosya Adı: whms_order_empty_state.dart
// Açıklama: WHMS emir listesi dens boş durum metni
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../../../../core/localization/app_localization.dart';

/// {@template whms_order_empty_state}
/// Dens boş liste — illüstrasyon / redesign yok.
///
/// Kullanım örneği:
/// ```dart
/// const WhmsOrderEmptyState();
/// ```
/// {@endtemplate}
class WhmsOrderEmptyState extends StatelessWidget {
  /// [messageKey]: Çeviri anahtarı (varsayılan boş emir)
  final String messageKey;

  /// {@macro whms_order_empty_state}
  const WhmsOrderEmptyState({
    super.key,
    this.messageKey = 'whms.orders.empty',
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(
          l10n.translate(messageKey),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: FieldSalesDensTheme.muted(context),
          ),
        ),
      ),
    );
  }
}
