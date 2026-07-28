// Dosya Adı: whms_order_list_tile.dart
// Açıklama: WHMS emir dens liste satırı (WhmsOrderDto)
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/app_localization.dart';
import '../../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../../model/whms_order_dto.dart';

/// {@template whms_order_list_tile}
/// Kompakt dens emir satırı — kod · tip · durum · tarih.
///
/// Kullanım örneği:
/// ```dart
/// WhmsOrderListTile(order: order, onTap: () {});
/// ```
/// {@endtemplate}
class WhmsOrderListTile extends StatelessWidget {
  /// [order]: Emir DTO
  final WhmsOrderDto order;

  /// [onTap]: Satır dokunma
  final VoidCallback? onTap;

  /// {@macro whms_order_list_tile}
  const WhmsOrderListTile({
    super.key,
    required this.order,
    this.onTap,
  });

  /// Görünen emir kodu — referans veya id.
  static String displayCode(WhmsOrderDto order) {
    final ref = order.referenceNo?.trim();
    if (ref != null && ref.isNotEmpty) return ref;
    return order.id;
  }

  /// Emir tarihini dens görünüme çevirir.
  static String formatOrderDate(String raw) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed == null) {
      final s = raw.trim();
      return s.isEmpty ? '—' : s;
    }
    return DateFormat('dd.MM.yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final dateText = formatOrderDate(order.orderDate);
    final wh = (order.warehouseCode ?? '').trim();
    final subtitle = [
      l10n.translate('whms.orders.type_${order.orderType.wireName}'),
      l10n.translate('whms.orders.status_${order.status.storageCode}'),
      if (wh.isNotEmpty) wh,
      dateText,
    ].join(' · ');

    return Material(
      color: FieldSalesDensTheme.surface(context),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: FieldSalesDensTheme.border(context),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                size: 18,
                color: FieldSalesDensAppBar.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayCode(order),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FieldSalesDensTheme.title(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: FieldSalesDensTheme.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (order.lines.isNotEmpty) ...[
                Text(
                  '${order.lines.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: FieldSalesDensTheme.muted(context),
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right,
                size: 18,
                color: FieldSalesDensTheme.muted(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
