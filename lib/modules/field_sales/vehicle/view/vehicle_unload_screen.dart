// Dosya Adı: vehicle_unload_screen.dart
// Açıklama: Araç boşaltma dens — Kaydet ile vehicle_stocks düşüm + merkez artışı
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../stock/view/stock_slip_dens_form.dart';
import '../../vehicles/viewmodel/vehicle_provider.dart';

/// {@template vehicle_unload_line}
/// Boşaltma satırı (ürün + miktar).
/// {@endtemplate}
class _UnloadLine {
  /// [productId]: Ürün kimliği
  final String productId;

  /// [code]: Ürün kodu / kısa id
  final String code;

  /// [name]: Ürün adı
  final String name;

  /// [qty]: Boşaltılacak miktar
  final double qty;

  const _UnloadLine({
    required this.productId,
    required this.code,
    required this.name,
    required this.qty,
  });
}

/// {@template vehicle_unload_screen}
/// Araç boşaltma dens: KAYNAK (Araç Depo) → HEDEF (Merkez Depo).
/// Kaydet: `vehicle_stocks` düşümü + `products.stock_quantity` artışı.
///
/// Route: `/field-sales/vehicle-unload`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, VehicleUnloadScreen.routeName);
/// ```
/// {@endtemplate}
class VehicleUnloadScreen extends ConsumerStatefulWidget {
  /// [routeName]: Named route — `/field-sales/vehicle-unload`
  static const String routeName = '/field-sales/vehicle-unload';

  const VehicleUnloadScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VehicleUnloadScreen> createState() =>
      _VehicleUnloadScreenState();
}

class _VehicleUnloadScreenState extends ConsumerState<VehicleUnloadScreen> {
  /// [_source]: Kaynak İşyeri · Fabrika · Ambar (varsayılan Araç Depo)
  StockSlipLocation _source = const StockSlipLocation();

  /// [_target]: Hedef İşyeri · Fabrika · Ambar (varsayılan Merkez Depo)
  StockSlipLocation _target = const StockSlipLocation();

  /// [_date]: Fiş tarihi
  DateTime _date = DateTime.now();

  /// [_items]: Boşaltılacak satırlar
  final List<_UnloadLine> _items = [];

  /// [_seeded]: İlk l10n seçenekleri uygulandı mı
  bool _seeded = false;

  /// [_saving]: Kaydet işlemi sürüyor
  bool _saving = false;

  /// [_stocksLoaded]: Araç stokları forma yüklendi mi
  bool _stocksLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncLinesFromVehicleStocks();
    });
  }

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
    final vehicleWh = warehouses.length > 1 ? warehouses[1] : warehouses.first;
    final centerWh = warehouses.first;
    _source = StockSlipLocation(
      workplace: workplaces.first,
      factory: factories.first,
      warehouse: vehicleWh,
    );
    _target = StockSlipLocation(
      workplace: workplaces.first,
      factory: factories.first,
      warehouse: centerWh,
    );
  }

  /// {@template sync_lines_from_vehicle_stocks}
  /// Seçili araç stoğunu forma satır olarak yükler (bir kez).
  /// {@endtemplate}
  void _syncLinesFromVehicleStocks({bool force = false}) {
    if (!force && _stocksLoaded) return;
    final vehicleState = ref.read(vehicleProvider);
    if (vehicleState.isLoading) return;
    setState(() {
      _stocksLoaded = true;
      _items
        ..clear()
        ..addAll(
          vehicleState.stocks.where((s) => s.quantity > 0).map(
                (s) => _UnloadLine(
                  productId: s.productId,
                  code: s.productId,
                  name: s.productName ?? s.productId,
                  qty: s.quantity,
                ),
              ),
        );
    });
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
      _items.add(
        _UnloadLine(
          productId: '',
          code: 'UNL-${_items.length + 1}',
          name: l10n.translate('field_sales.stock_slip.sample_line'),
          qty: 0,
        ),
      );
    });
  }

  Future<void> _handleSave(AppLocalization l10n) async {
    final payload = _items
        .where((i) => i.productId.isNotEmpty && i.qty > 0)
        .map(
          (i) => <String, dynamic>{
            'productId': i.productId,
            'quantity': i.qty,
          },
        )
        .toList();

    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.vehicle_unload_empty'),
          ),
        ),
      );
      return;
    }

    final vehicle = ref.read(vehicleProvider).selectedVehicle;
    if (vehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.vehicle_unload_no_vehicle'),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final success = await ref
        .read(vehicleProvider.notifier)
        .unloadStockFromVehicle(items: payload);
    if (!mounted) return;
    setState(() => _saving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.vehicle_unload_saved'),
          ),
        ),
      );
      setState(() {
        _stocksLoaded = false;
      });
      _syncLinesFromVehicleStocks(force: true);
    } else {
      final error = ref.read(vehicleProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                l10n.translate('field_sales.vehicle_unload_failed'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seedLocations(l10n);
    ref.watch(vehicleProvider);
    ref.listen<VehicleState>(vehicleProvider, (prev, next) {
      if (!_stocksLoaded && !next.isLoading) {
        _syncLinesFromVehicleStocks();
      }
    });

    final lines = _items
        .map(
          (i) => StockSlipLinePlaceholder(
            code: i.code,
            name: i.name,
            qty: i.qty.toStringAsFixed(
              i.qty == i.qty.roundToDouble() ? 0 : 2,
            ),
          ),
        )
        .toList();

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
          l10n.translate('field_sales.stubs.vehicle_unload'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saving ? null : () => _handleSave(l10n),
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
                      fontWeight: FontWeight.bold,
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
        lines: lines,
        onAddLine: () => _addPlaceholderLine(l10n),
      ),
    );
  }
}
