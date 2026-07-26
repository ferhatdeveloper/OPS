// Dosya Adı: vehicle_load_screen.dart
// Açıklama: Araç yükleme dens form + Kaydet → loadStockIntoVehicle
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localization.dart';
import '../../products/view/product_catalog_picker.dart';
import '../../stock/model/product_model.dart';
import '../../stock/view/stock_slip_dens_form.dart';
import '../../vehicles/viewmodel/vehicle_provider.dart';

/// {@template dens_lines_to_load_items}
/// Dens satır iskeletini [loadStockIntoVehicle] items formatına çevirir.
///
/// Parametreler:
/// - [lines]: Dens satır yer tutucuları (productId ?? code)
///
/// Dönüş değeri:
/// - [List]: {productId, name, quantity, unit} haritaları (qty > 0)
/// {@endtemplate}
List<Map<String, dynamic>> densLinesToLoadItems(
  List<StockSlipLinePlaceholder> lines,
) {
  final items = <Map<String, dynamic>>[];
  for (final line in lines) {
    final qty = double.tryParse(line.qty.replaceAll(',', '.')) ?? 0.0;
    if (qty <= 0) continue;
    final productId = (line.productId ?? line.code).trim();
    if (productId.isEmpty) continue;
    items.add({
      'productId': productId,
      'name': line.name,
      'quantity': qty,
      'unit': (line.unit == null || line.unit!.trim().isEmpty)
          ? 'Adet'
          : line.unit,
    });
  }
  return items;
}

/// {@template vehicle_load_product_picker}
/// Ürün katalog seçici imzası (test enjeksiyonu için).
/// {@endtemplate}
typedef VehicleLoadProductPicker = Future<ProductModel?> Function(
  BuildContext context,
);

/// {@template vehicle_load_screen}
/// MBT araç yükleme dens: KAYNAK (merkez) → HEDEF (araç depo).
/// Kaydet → [vehicleProvider.loadStockIntoVehicle].
/// Route: `/field-sales/vehicle-load`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VehicleLoadScreen.routeName);
/// ```
/// {@endtemplate}
class VehicleLoadScreen extends ConsumerStatefulWidget {
  /// {@template vehicle_load_screen_constructor}
  /// Araç yükleme dens ekranını oluşturur.
  /// {@endtemplate}
  const VehicleLoadScreen({
    Key? key,
    this.productPicker,
  }) : super(key: key);

  /// [routeName]: Named route — `/field-sales/vehicle-load`
  static const String routeName = '/field-sales/vehicle-load';

  /// [productPicker]: Katalog seçici (null → [showProductCatalogPicker])
  final VehicleLoadProductPicker? productPicker;

  @override
  ConsumerState<VehicleLoadScreen> createState() => _VehicleLoadScreenState();
}

class _VehicleLoadScreenState extends ConsumerState<VehicleLoadScreen> {
  /// [_source]: Kaynak İşyeri · Fabrika · Ambar (merkez)
  StockSlipLocation _source = const StockSlipLocation();

  /// [_target]: Hedef İşyeri · Fabrika · Ambar (araç)
  StockSlipLocation _target = const StockSlipLocation();

  /// [_date]: Yükleme fişi tarihi
  DateTime _date = DateTime.now();

  /// [_lines]: Görünür satır iskeleti
  final List<StockSlipLinePlaceholder> _lines = [];

  /// [_seeded]: İlk l10n seçenekleri uygulandı mı
  bool _seeded = false;

  /// [_saving]: Kaydet devam ediyor
  bool _saving = false;

  List<String> _workplaceOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.workplace_sample'),
        l10n.translate('field_sales.stock_slip.workplace_sample_2'),
      ];

  List<String> _factoryOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.factory_sample'),
        l10n.translate('field_sales.stock_slip.factory_sample_2'),
      ];

  List<String> _warehouseOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.warehouse_center'),
        l10n.translate('field_sales.stock_slip.warehouse_vehicle'),
        l10n.translate('field_sales.stock_slip.warehouse_return'),
      ];

  void _seedLocations(AppLocalization l10n) {
    if (_seeded) return;
    _seeded = true;
    final workplaces = _workplaceOptions(l10n);
    final factories = _factoryOptions(l10n);
    final warehouses = _warehouseOptions(l10n);
    _source = StockSlipLocation(
      workplace: workplaces.first,
      factory: factories.first,
      warehouse: warehouses.first,
    );
    _target = StockSlipLocation(
      workplace: workplaces.first,
      factory: factories.first,
      warehouse: warehouses.length > 1 ? warehouses[1] : warehouses.first,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 1),
      lastDate: DateTime(_date.year + 1),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  /// {@template vehicle_load_add_line_from_catalog}
  /// Satır Ekle → ürün katalog seçici; seçilen ürün dens satıra eklenir.
  /// {@endtemplate}
  Future<void> _addLineFromCatalog() async {
    final picker = widget.productPicker ?? showProductCatalogPicker;
    final product = await picker(context);
    if (product == null || !mounted) return;
    setState(() {
      _lines.add(stockSlipLineFromProduct(product));
    });
  }

  /// {@template vehicle_load_on_save}
  /// Dens satırlarını [loadStockIntoVehicle] ile kaydeder.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    final l10n = AppLocalization.of(context);
    final items = densLinesToLoadItems(_lines);

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.vehicle_load_empty'),
          ),
        ),
      );
      return;
    }

    final vehicleState = ref.read(vehicleProvider);
    if (vehicleState.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.vehicle_load_no_vehicle'),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final success = await ref
          .read(vehicleProvider.notifier)
          .loadStockIntoVehicle(items: items);

      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.translate('field_sales.vehicle_load_saved'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _lines.clear());
      } else {
        final error = ref.read(vehicleProvider).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error == null || error.isEmpty
                  ? l10n.translate('field_sales.vehicle_load_failed')
                  : error,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seedLocations(l10n);
    final vehicleState = ref.watch(vehicleProvider);
    final busy = _saving || vehicleState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.vehicle_load'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StockSlipDensForm(
        warehouses: _warehouseOptions(l10n),
        workplaces: _workplaceOptions(l10n),
        factories: _factoryOptions(l10n),
        sourceLocation: _source,
        onSourceLocationChanged: (v) => setState(() => _source = v),
        targetLocation: _target,
        onTargetLocationChanged: (v) => setState(() => _target = v),
        date: _date,
        onDateTap: _pickDate,
        lines: _lines,
        onAddLine: () {
          _addLineFromCatalog();
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: busy ? null : _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375A7F),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.translate('common.save'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
