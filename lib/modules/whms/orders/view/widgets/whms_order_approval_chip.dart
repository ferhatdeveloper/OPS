// Dosya Adı: whms_order_approval_chip.dart
// Açıklama: WHMS emir ONAY dens chip (0–4)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localization.dart';
import '../../../../field_sales/shared/view/field_sales_dens_filter_bar.dart';
import '../../../contract/whms_bridge_dto.dart';

/// {@template whms_order_approval_chip}
/// ONAY durumu dens chip — aktif primary dil.
///
/// Kullanım örneği:
/// ```dart
/// WhmsOrderApprovalChip(approval: WhmsApprovalStatus.pending);
/// ```
/// {@endtemplate}
class WhmsOrderApprovalChip extends StatelessWidget {
  /// [approval]: ONAY 0–4
  final WhmsApprovalStatus approval;

  /// {@macro whms_order_approval_chip}
  const WhmsOrderApprovalChip({
    super.key,
    required this.approval,
  });

  /// `whms.orders.approval_*` çeviri anahtarı.
  static String l10nKey(WhmsApprovalStatus status) {
    switch (status) {
      case WhmsApprovalStatus.pending:
        return 'whms.orders.approval_pending';
      case WhmsApprovalStatus.approved:
        return 'whms.orders.approval_approved';
      case WhmsApprovalStatus.synced:
        return 'whms.orders.approval_synced';
      case WhmsApprovalStatus.rejected:
        return 'whms.orders.approval_rejected';
      case WhmsApprovalStatus.error:
        return 'whms.orders.approval_error';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    return FieldSalesDensChip(
      label: l10n.translate(l10nKey(approval)),
      selected: true,
      fontSize: 11,
      onTap: null,
    );
  }
}
