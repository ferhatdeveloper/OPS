// Dosya Adı: order_type_sheet.dart
// Açıklama: MBT Sipariş tip seçimi bottom sheet (Satış / Alış)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/order_model.dart';

/// {@template show_order_type_sheet}
/// Satış / Alış tip seçim sheet'ini açar; seçilen tipi döner.
///
/// Kullanım örneği:
/// ```dart
/// final type = await showOrderTypeSheet(context);
/// ```
/// {@endtemplate}
Future<OrderType?> showOrderTypeSheet(BuildContext context) {
  final l10n = AppLocalization.of(context);
  return showModalBottomSheet<OrderType>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.translate('field_sales.order_type_select_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(
                  Icons.point_of_sale_outlined,
                  color: Color(0xFF00A8E8),
                ),
                title: Text(
                  l10n.translate('field_sales.order_type_sales'),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.pop(ctx, OrderType.sales),
              ),
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Color(0xFF375A7F),
                ),
                title: Text(
                  l10n.translate('field_sales.order_type_purchase'),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => Navigator.pop(ctx, OrderType.purchase),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// {@template order_type_dens_selector}
/// Satış / Alış dens 2 sütun seçici (order_entry üstü).
/// {@endtemplate}
class OrderTypeDensSelector extends StatelessWidget {
  /// [value]: Seçili tip
  final OrderType value;

  /// [onChanged]: Tip değişince
  final ValueChanged<OrderType> onChanged;

  /// [enabled]: Değiştirilebilir mi
  final bool enabled;

  const OrderTypeDensSelector({
    Key? key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final types = [
      {
        'val': OrderType.sales,
        'label': l10n.translate('field_sales.order_type_sales'),
        'icon': Icons.point_of_sale_outlined,
      },
      {
        'val': OrderType.purchase,
        'label': l10n.translate('field_sales.order_type_purchase'),
        'icon': Icons.shopping_bag_outlined,
      },
    ];

    return Row(
      children: types.map((t) {
        final type = t['val'] as OrderType;
        final isSelected = value == type;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: enabled ? () => onChanged(type) : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00A8E8)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00A8E8)
                        : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey.shade500,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade700,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
