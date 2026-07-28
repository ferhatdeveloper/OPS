// Dosya Adı: warehouse_receipt_screen.dart
// Açıklama: Ambar Fişi dens form iskeleti (MBT KAYNAK→HEDEF × İşyeri·Fabrika·Ambar)
// Oluşturulma Tarihi: 2024-03-20
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../model/warehouse_master_seed.dart';
import 'stock_slip_dens_form.dart';

/// {@template warehouse_receipt_screen}
/// Ambar Fişi dens iskeleti: KAYNAK / HEDEF × İŞYERİ · FABRİKA · AMBAR.
///
/// Rota: `/field-sales/stock-warehouse`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, '/field-sales/stock-warehouse');
/// ```
/// {@endtemplate}
class WarehouseReceiptScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/stock-warehouse`
  static const String routeName = '/field-sales/stock-warehouse';

  const WarehouseReceiptScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseReceiptScreen> createState() => _WarehouseReceiptScreenState();
}

class _WarehouseReceiptScreenState extends State<WarehouseReceiptScreen> {
  /// [_source]: Kaynak İşyeri · Fabrika · Ambar
  StockSlipLocation _source = const StockSlipLocation();

  /// [_target]: Hedef İşyeri · Fabrika · Ambar
  StockSlipLocation _target = const StockSlipLocation();

  /// [_date]: Fiş tarihi
  DateTime _date = DateTime.now();

  /// [_lines]: Görünür satır iskeleti
  final List<StockSlipLinePlaceholder> _lines = [];

  /// [_seeded]: İlk l10n seçenekleri uygulandı mı
  bool _seeded = false;

  List<String> _workplaceOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.workplace_sample'),
        l10n.translate('field_sales.stock_slip.workplace_sample_2'),
      ];

  List<String> _factoryOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.factory_sample'),
        l10n.translate('field_sales.stock_slip.factory_sample_2'),
      ];

  /// Ambar seçenekleri — [WarehouseMasterSeed] kodlarına bağlı l10n adları
  List<String> _warehouseOptions(AppLocalization l10n) =>
      WarehouseMasterSeed.defaultRows
          .map((row) => l10n.translate(row.nameKey))
          .toList();

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

  void _addPlaceholderLine(AppLocalization l10n) {
    setState(() {
      _lines.add(
        StockSlipLinePlaceholder(
          code: 'AMB-${_lines.length + 1}',
          name: l10n.translate('field_sales.stock_slip.sample_line'),
          qty: '0',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seedLocations(l10n);

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF375A7F), Color(0xFF00A8E8)],
            ),
          ),
        ),
        title: Text(
          l10n.translate('field_sales.stubs.warehouse_slip'),
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
        onAddLine: () => _addPlaceholderLine(l10n),
      ),
    );
  }
}
