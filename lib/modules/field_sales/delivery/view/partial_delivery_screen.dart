// Dosya Adı: partial_delivery_screen.dart
// Açıklama: Kısmi teslimat dens form + Kaydet→SQLite/provider iskelet
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../stock/view/stock_slip_dens_form.dart';
import '../model/partial_delivery_model.dart';
import '../viewmodel/partial_delivery_provider.dart';

/// {@template partial_delivery_screen}
/// Kısmi teslimat dens form iskeleti
/// (İşyeri · Fabrika · Ambar · Tarih · Satırlar · Kaydet).
///
/// Route: `/field-sales/partial-delivery`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, PartialDeliveryScreen.routeName);
/// ```
/// {@endtemplate}
class PartialDeliveryScreen extends ConsumerStatefulWidget {
  /// {@template partial_delivery_screen_constructor}
  /// Kısmi teslimat dens ekranını oluşturur.
  /// {@endtemplate}
  const PartialDeliveryScreen({Key? key}) : super(key: key);

  /// [routeName]: Named route — `/field-sales/partial-delivery`
  static const String routeName = '/field-sales/partial-delivery';

  @override
  ConsumerState<PartialDeliveryScreen> createState() =>
      _PartialDeliveryScreenState();
}

class _PartialDeliveryScreenState
    extends ConsumerState<PartialDeliveryScreen> {
  /// [_location]: İşyeri · Fabrika · Ambar
  StockSlipLocation _location = const StockSlipLocation();

  /// [_date]: Teslimat tarihi
  DateTime _date = DateTime.now();

  /// [_lines]: Görünür satır iskeleti
  final List<StockSlipLinePlaceholder> _lines = [];

  /// [_locationSeeded]: İlk l10n seçenekleri uygulandı mı
  bool _locationSeeded = false;

  List<String> _workplaceOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.workplace_sample'),
        l10n.translate('field_sales.stock_slip.workplace_sample_2'),
      ];

  List<String> _factoryOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.factory_sample'),
        l10n.translate('field_sales.stock_slip.factory_sample_2'),
      ];

  List<String> _warehouseOptions(AppLocalization l10n) => [
        l10n.translate('field_sales.stock_slip.warehouse_vehicle'),
        l10n.translate('field_sales.stock_slip.warehouse_center'),
        l10n.translate('field_sales.stock_slip.warehouse_return'),
      ];

  void _seedLocation(AppLocalization l10n) {
    if (_locationSeeded) return;
    _locationSeeded = true;
    _location = StockSlipLocation(
      workplace: _workplaceOptions(l10n).first,
      factory: _factoryOptions(l10n).first,
      warehouse: _warehouseOptions(l10n).first,
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
          code: 'KSM-${_lines.length + 1}',
          name: l10n.translate('field_sales.partial_delivery.sample_line'),
          qty: l10n.translate('field_sales.partial_delivery.qty_sample'),
        ),
      );
    });
  }

  /// {@template _on_save}
  /// Kaydet → PartialDeliveryNotifier (SQLite + sync_queue).
  /// {@endtemplate}
  Future<void> _onSave(AppLocalization l10n) async {
    final saveState = ref.read(partialDeliveryProvider);
    if (saveState.isLoading) return;

    final lines = _lines
        .map(
          (e) => PartialDeliveryLine(
            code: e.code,
            name: e.name,
            qty: e.qty,
          ),
        )
        .toList();

    final ok = await ref.read(partialDeliveryProvider.notifier).save(
          workplace: _location.workplace,
          factory: _location.factory,
          warehouse: _location.warehouse,
          deliveryDate: _date,
          lines: lines,
        );

    if (!mounted) return;
    final state = ref.read(partialDeliveryProvider);
    if (!ok) {
      final key = state.error ??
          'field_sales.partial_delivery.requires_lines';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.translate(key))),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.translate('field_sales.partial_delivery.saved'),
        ),
      ),
    );
    Navigator.of(context).maybePop();
  }

  /// {@template _build_bottom_bar}
  /// Kaydet çubuğu (waybill dens stil — UI no-touch).
  /// {@endtemplate}
  Widget _buildBottomBar(AppLocalization l10n, bool saving) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF375A7F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: saving ? null : () => _onSave(l10n),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.translate('common.save'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seedLocation(l10n);
    final saving = ref.watch(partialDeliveryProvider).isLoading;

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
          l10n.translate('field_sales.stubs.partial_delivery'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StockSlipDensForm(
              warehouses: _warehouseOptions(l10n),
              workplaces: _workplaceOptions(l10n),
              factories: _factoryOptions(l10n),
              location: _location,
              onLocationChanged: (v) => setState(() => _location = v),
              date: _date,
              onDateTap: _pickDate,
              lines: _lines,
              onAddLine: () => _addPlaceholderLine(l10n),
            ),
          ),
          _buildBottomBar(l10n, saving),
        ],
      ),
    );
  }
}
