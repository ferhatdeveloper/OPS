// Dosya Adı: production_receipt_screen.dart
// Açıklama: Üretimden giriş fişi dens form + Kaydet → sync_queue
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/job_queue_service.dart';
import '../model/production_receipt_payload.dart';
import 'stock_slip_dens_form.dart';

/// {@template production_receipt_screen}
/// Üretimden stok giriş fişi dens iskeleti
/// (İşyeri · Fabrika · Ambar · Tarih · Satırlar · Kaydet → kuyruk).
///
/// Rota: `/field-sales/stock-production`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, ProductionReceiptScreen.routeName);
/// ```
/// {@endtemplate}
class ProductionReceiptScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/stock-production';

  const ProductionReceiptScreen({Key? key}) : super(key: key);

  @override
  State<ProductionReceiptScreen> createState() =>
      _ProductionReceiptScreenState();
}

class _ProductionReceiptScreenState extends State<ProductionReceiptScreen> {
  /// [_location]: İşyeri · Fabrika · Ambar
  StockSlipLocation _location = const StockSlipLocation();

  /// [_date]: Fiş tarihi
  DateTime _date = DateTime.now();

  /// [_lines]: Görünür satır iskeleti
  final List<StockSlipLinePlaceholder> _lines = [];

  /// [_locationSeeded]: İlk l10n seçenekleri uygulandı mı
  bool _locationSeeded = false;

  /// [_saving]: Kaydet / enqueue durumu
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
          code: 'PRD-${_lines.length + 1}',
          name: l10n.translate('field_sales.stock_slip.sample_line'),
          qty: '0',
        ),
      );
    });
  }

  /// {@template production_receipt_on_save}
  /// Dens Kaydet — payload üretip [JobQueueService] kuyruğuna ekler.
  /// {@endtemplate}
  Future<void> _onSave() async {
    if (_saving) return;
    final l10n = AppLocalization.of(context);
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.stock_slip.save_requires_lines'),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final id = const Uuid().v4();
      final payload = ProductionReceiptPayload.build(
        id: id,
        workplace: _location.workplace,
        factory: _location.factory,
        warehouse: _location.warehouse,
        date: _date,
        lines: _lines
            .map(
              (line) => ProductionReceiptLineData(
                code: line.code,
                name: line.name,
                qty: line.qty,
              ),
            )
            .toList(),
      );

      await JobQueueService().enqueue(
        entityType: ProductionReceiptPayload.entityType,
        entityId: id,
        payload: payload,
        priority: 1,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.stock_slip.production_queued'),
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.translate('field_sales.stock_slip.save_queue_error'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    _seedLocation(l10n);

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
          l10n.translate('field_sales.stubs.production_receipt'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF375A7F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _saving
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
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
