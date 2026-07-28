// Dosya Adı: whms_order_create_screen.dart
// Açıklama: WHMS /whms/orders/create dens — taslak emir formu
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../field_sales/shared/view/field_sales_dens_app_bar.dart';
import '../../../field_sales/shared/view/field_sales_dens_theme.dart';
import '../../../field_sales/stock/model/warehouse_master_seed.dart';
import '../../contract/whms_route_map.dart';
import '../../model/whms_order_line_dto.dart';
import '../../model/whms_order_type.dart';
import '../../viewmodel/whms_order_store.dart';
import 'whms_order_detail_screen.dart';

/// {@template whms_order_create_screen}
/// Yeni WHMS emir dens formu — `createDraft` (status=draft, ONAY=0).
/// Route: `/whms/orders/create`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WhmsOrderCreateScreen.routeName);
/// ```
/// {@endtemplate}
class WhmsOrderCreateScreen extends StatefulWidget {
  /// Named route — [WhmsRouteMap.whmsOrderCreate]
  static const String routeName = WhmsRouteMap.whmsOrderCreate;

  /// Store inject (test)
  final WhmsOrderStore? store;

  /// {@macro whms_order_create_screen}
  const WhmsOrderCreateScreen({
    super.key,
    this.store,
  });

  @override
  State<WhmsOrderCreateScreen> createState() =>
      _WhmsOrderCreateScreenState();
}

class _WhmsOrderCreateScreenState extends State<WhmsOrderCreateScreen> {
  final _notesController = TextEditingController();
  final _refController = TextEditingController();
  final _productController = TextEditingController();
  final _qtyController = TextEditingController();
  final _locationController = TextEditingController();

  WhmsOrderType _type = WhmsOrderType.malKabul;
  String? _warehouseCode;
  String? _toWarehouseCode;
  bool _saving = false;

  WhmsOrderStore get _store => widget.store ?? const WhmsOrderStore();

  List<WarehouseMasterSeedRow> get _warehouses =>
      WarehouseMasterSeed.defaultRows;

  bool get _needsTarget =>
      _type == WhmsOrderType.transfer || _type == WhmsOrderType.load;

  @override
  void initState() {
    super.initState();
    if (_warehouses.isNotEmpty) {
      _warehouseCode = _warehouses.first.code;
      if (_warehouses.length > 1) {
        _toWarehouseCode = _warehouses[1].code;
      } else {
        _toWarehouseCode = _warehouses.first.code;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _refController.dispose();
    _productController.dispose();
    _qtyController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _denseDecoration(String label) {
    return InputDecoration(
      isDense: true,
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      border: const OutlineInputBorder(),
    );
  }

  String? _validate(AppLocalization l10n) {
    if (_warehouseCode == null || _warehouseCode!.trim().isEmpty) {
      return l10n.translate('whms.orders.validation_warehouse');
    }
    if (_needsTarget) {
      final to = (_toWarehouseCode ?? '').trim();
      if (to.isEmpty) {
        return l10n.translate('whms.orders.validation_warehouse');
      }
      if (_type == WhmsOrderType.transfer &&
          to == _warehouseCode!.trim()) {
        return l10n.translate(
          'whms.orders.validation_transfer_warehouses',
        );
      }
    }

    final product = _productController.text.trim();
    final qtyRaw = _qtyController.text.trim();
    final loc = _locationController.text.trim();
    final anyLine =
        product.isNotEmpty || qtyRaw.isNotEmpty || loc.isNotEmpty;
    if (!anyLine) return null;

    final qty = double.tryParse(qtyRaw.replaceAll(',', '.'));
    if (product.isEmpty || qty == null || qty <= 0) {
      return l10n.translate('whms.orders.validation_line');
    }
    if (_type.requiresLocation && loc.isEmpty) {
      return l10n.translate('whms.orders.validation_line_location');
    }
    return null;
  }

  List<WhmsOrderLineDto> _optionalLines() {
    final product = _productController.text.trim();
    final qtyRaw = _qtyController.text.trim();
    final loc = _locationController.text.trim();
    if (product.isEmpty && qtyRaw.isEmpty && loc.isEmpty) {
      return const [];
    }
    final qty =
        double.tryParse(qtyRaw.replaceAll(',', '.')) ?? 0;
    return [
      WhmsOrderLineDto(
        id: const Uuid().v4(),
        orderId: '',
        lineNo: 1,
        productId: product,
        productCode: product,
        quantity: qty,
        locationCode: loc.isEmpty ? null : loc,
      ),
    ];
  }

  /// {@template whms_order_create_save}
  /// Taslak emir yazar; detaya geçer.
  /// {@endtemplate}
  Future<void> _save() async {
    final l10n = AppLocalization.of(context);
    final err = _validate(l10n);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err)),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final wh = _warehouseCode!.trim();
      final notes = _notesController.text.trim();
      final ref = _refController.text.trim();
      final order = await _store.createDraft(
        orderType: _type,
        warehouseCode: wh,
        fromWarehouseCode: _needsTarget ? wh : null,
        toWarehouseCode: _needsTarget
            ? (_toWarehouseCode ?? '').trim()
            : null,
        referenceNo: ref.isEmpty ? null : ref,
        notes: notes.isEmpty ? null : notes,
        lines: _optionalLines(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.orders.create_saved')),
        ),
      );
      await Navigator.of(context).pushReplacementNamed(
        WhmsOrderDetailScreen.routeName,
        arguments: order.id,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('whms.orders.create_error')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('whms.orders.create_title'),
        showCalculatorHome: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              children: [
                DropdownButtonFormField<WhmsOrderType>(
                  value: _type,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_type'),
                  ),
                  items: [
                    for (final t in WhmsOrderType.values)
                      DropdownMenuItem(
                        value: t,
                        child: Text(
                          l10n.translate(t.l10nKey),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) {
                          if (v == null) return;
                          setState(() => _type = v);
                        },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _warehouseCode,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_warehouse'),
                  ),
                  items: [
                    for (final w in _warehouses)
                      DropdownMenuItem(
                        value: w.code,
                        child: Text(
                          w.code,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                  ],
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _warehouseCode = v),
                ),
                if (_needsTarget) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _toWarehouseCode,
                    isDense: true,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    decoration: _denseDecoration(
                      l10n.translate(
                        'whms.orders.field_target_warehouse',
                      ),
                    ),
                    items: [
                      for (final w in _warehouses)
                        DropdownMenuItem(
                          value: w.code,
                          child: Text(
                            w.code,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (v) =>
                            setState(() => _toWarehouseCode = v),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _refController,
                  enabled: !_saving,
                  style: const TextStyle(fontSize: 13),
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_reference'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  enabled: !_saving,
                  style: const TextStyle(fontSize: 13),
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLines: 2,
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_notes'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.translate('whms.orders.optional_line'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _productController,
                  enabled: !_saving,
                  style: const TextStyle(fontSize: 13),
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_product_code'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _qtyController,
                  enabled: !_saving,
                  style: const TextStyle(fontSize: 13),
                  textCapitalization: TextCapitalization.none,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_qty'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  enabled: !_saving,
                  style: const TextStyle(fontSize: 13),
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: _denseDecoration(
                    l10n.translate('whms.orders.field_location'),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l10n.translate('whms.orders.save'),
                          style: const TextStyle(fontSize: 14),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
