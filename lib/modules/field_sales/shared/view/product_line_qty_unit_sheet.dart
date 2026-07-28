// Dosya Adı: product_line_qty_unit_sheet.dart
// Açıklama: Sipariş/fatura satırına ürün eklerken dens birim + miktar seçimi
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localization.dart';
import '../../stock/engine/unit_conversion_service.dart';
import 'field_sales_dens_theme.dart';

/// {@template product_line_qty_unit_result}
/// Birim + miktar seçim sonucu.
/// {@endtemplate}
class ProductLineQtyUnitResult {
  /// [unitName]: Seçilen birim
  final String unitName;

  /// [quantity]: Girilen miktar (> 0)
  final double quantity;

  const ProductLineQtyUnitResult({
    required this.unitName,
    required this.quantity,
  });
}

/// {@template show_product_line_qty_unit_sheet}
/// Ürün için dens birim + miktar bottom sheet açar.
///
/// Parametreler:
/// - [context]: BuildContext
/// - [product]: SQLite ürün satırı (`id`, `name`, `unit` / `main_unit`, `unit_set_id`)
///
/// Dönüş değeri:
/// - [ProductLineQtyUnitResult] veya iptalde null
/// {@endtemplate}
Future<ProductLineQtyUnitResult?> showProductLineQtyUnitSheet({
  required BuildContext context,
  required Map<String, dynamic> product,
}) async {
  final l10n = AppLocalization.of(context);
  final productName = (product['name'] ?? '').toString();
  final fallbackUnit = () {
    final u = (product['unit'] ?? product['main_unit'] ?? '').toString().trim();
    return u.isEmpty ? l10n.translate('field_sales.unit_piece') : u;
  }();

  final unitSetId = product['unit_set_id'] as String?;
  final lines = await UnitConversionService.getUnitsForProduct(unitSetId);
  final unitNames = <String>[
    if (lines.isNotEmpty) ...lines.map((e) => e.unitName),
    if (lines.isEmpty) fallbackUnit,
  ];
  // Tekrarları temizle, sırayı koru
  final uniqueUnits = <String>[];
  for (final u in unitNames) {
    if (!uniqueUnits.contains(u)) uniqueUnits.add(u);
  }

  if (!context.mounted) return null;

  return showModalBottomSheet<ProductLineQtyUnitResult>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) {
      return _ProductLineQtyUnitBody(
        productName: productName,
        units: uniqueUnits,
        initialUnit: uniqueUnits.first,
      );
    },
  );
}

/// {@template product_line_qty_unit_body}
/// Dens birim + miktar form gövdesi.
/// {@endtemplate}
class _ProductLineQtyUnitBody extends StatefulWidget {
  const _ProductLineQtyUnitBody({
    required this.productName,
    required this.units,
    required this.initialUnit,
  });

  final String productName;
  final List<String> units;
  final String initialUnit;

  @override
  State<_ProductLineQtyUnitBody> createState() =>
      _ProductLineQtyUnitBodyState();
}

class _ProductLineQtyUnitBodyState extends State<_ProductLineQtyUnitBody> {
  late String _unit;
  late final TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _unit = widget.initialUnit;
    _qtyCtrl = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _submit(AppLocalization l10n) {
    final raw = _qtyCtrl.text.trim().replaceAll(',', '.');
    final qty = double.tryParse(raw) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.line_qty_invalid'),
          ),
        ),
      );
      return;
    }
    Navigator.pop(
      context,
      ProductLineQtyUnitResult(unitName: _unit, quantity: qty),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.translate('field_sales.select_unit'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          InputDecorator(
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _unit,
                style: TextStyle(
                  fontSize: 13,
                  color: FieldSalesDensTheme.title(context),
                ),
                items: widget.units
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u, style: const TextStyle(fontSize: 13)),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _unit = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _qtyCtrl,
            style: const TextStyle(fontSize: 13),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.none,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              isDense: true,
              labelText: l10n.translate('field_sales.quantity'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onFieldSubmitted: (_) => _submit(l10n),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => _submit(l10n),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF375A7F),
                foregroundColor: Colors.white,
              ),
              child: Text(
                l10n.translate('field_sales.line_add_confirm'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
