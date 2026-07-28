// Dosya Adı: warehouse_transfer_screen.dart
// Açıklama: Ambar transferi dens formu → SQLite + Logo stock transfer kuyruğu
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../engine/stock_transfer_service.dart';
import '../model/warehouse_master_seed.dart';
import 'stock_slip_dens_form.dart';

/// {@template warehouse_transfer_screen}
/// Ambar transferi dens: KAYNAK → HEDEF × İşyeri·Fabrika·Ambar.
/// Kaydet → `warehouse_transfers` + Logo `stock_transfer` kuyruğu.
///
/// Rota: `/field-sales/warehouse-transfer`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, WarehouseTransferScreen.routeName);
/// ```
/// {@endtemplate}
class WarehouseTransferScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/warehouse-transfer`
  static const String routeName = '/field-sales/warehouse-transfer';

  const WarehouseTransferScreen({Key? key}) : super(key: key);

  @override
  State<WarehouseTransferScreen> createState() =>
      _WarehouseTransferScreenState();
}

class _WarehouseTransferScreenState extends State<WarehouseTransferScreen> {
  /// [_source]: Kaynak İşyeri · Fabrika · Ambar
  StockSlipLocation _source = const StockSlipLocation();

  /// [_target]: Hedef İşyeri · Fabrika · Ambar
  StockSlipLocation _target = const StockSlipLocation();

  /// [_date]: Transfer fişi tarihi
  DateTime _date = DateTime.now();

  /// [_lines]: Görünür satır iskeleti
  final List<StockSlipLinePlaceholder> _lines = [];

  /// [_seeded]: İlk l10n seçenekleri uygulandı mı
  bool _seeded = false;

  /// [_saving]: Kaydet işlemi sürüyor
  bool _saving = false;

  List<String> _workplaceOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.workplace_sample'),
        l10n.translate('field_sales.stock_slip.workplace_sample_2'),
      ];

  List<String> _factoryOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.factory_sample'),
        l10n.translate('field_sales.stock_slip.factory_sample_2'),
      ];

  List<String> _warehouseOptions(AppLocalization l10n) =>
      WarehouseMasterSeed.defaultRows
          .map((row) => l10n.translate(row.nameKey))
          .toList();

  /// Görünen ambar adını seed koduna çevirir (yerel stok txn için).
  String _warehouseCode(AppLocalization l10n, String? displayName) {
    final name = (displayName ?? '').trim();
    for (final row in WarehouseMasterSeed.defaultRows) {
      if (l10n.translate(row.nameKey) == name) return row.code;
      if (row.seedName == name || row.code == name) return row.code;
    }
    return name;
  }

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
          code: 'TRF-${_lines.length + 1}',
          name: l10n.translate('field_sales.stock_slip.sample_line'),
          qty: '1',
        ),
      );
    });
  }

  Future<void> _onSave(AppLocalization l10n) async {
    if (_saving) return;
    setState(() => _saving = true);
    final result = await StockTransferService.submitDensTransfer(
      fromWarehouse: _warehouseCode(l10n, _source.warehouse),
      toWarehouse: _warehouseCode(l10n, _target.warehouse),
      date: _date,
      sourceMeta: {
        'workplace': _source.workplace,
        'factory': _source.factory,
      },
      targetMeta: {
        'workplace': _target.workplace,
        'factory': _target.factory,
      },
      lines: _lines
          .map(
            (l) => StockTransferDensLine(
              productCode: l.code,
              productName: l.name,
              quantityText: l.qty,
            ),
          )
          .toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    final messenger = ScaffoldMessenger.of(context);
    if (result.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.stock_slip.transfer_queued'),
          ),
        ),
      );
      setState(() => _lines.clear());
      return;
    }

    final key = result.errorKey ??
        'field_sales.stock_slip.transfer_save_failed';
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.translate(key))),
    );
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
          l10n.translate('field_sales.stubs.warehouse_transfer'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _onSave(l10n),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.translate('common.save'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
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
