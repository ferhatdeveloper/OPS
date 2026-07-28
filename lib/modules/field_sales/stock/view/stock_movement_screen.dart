// Dosya Adı: stock_movement_screen.dart
// Açıklama: Stok hareket dens listesi — warehouse_transfers SQLite
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../engine/stock_transfer_service.dart';
import '../model/stock_transfer_model.dart';

/// {@template stock_movement_screen}
/// Stok hareket dens listesi — `warehouse_transfers` okuma.
///
/// Rota: `/field-sales/stock-movement`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, StockMovementScreen.routeName);
/// ```
/// {@endtemplate}
class StockMovementScreen extends StatefulWidget {
  /// [routeName]: Named route yolu
  static const String routeName = '/field-sales/stock-movement';

  /// [initialRows]: Test enjeksiyonu
  final List<StockTransferModel>? initialRows;

  /// [loader]: Test / özel yükleyici
  final Future<List<StockTransferModel>> Function()? loader;

  /// {@macro stock_movement_screen}
  const StockMovementScreen({
    Key? key,
    this.initialRows,
    this.loader,
  }) : super(key: key);

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  List<StockTransferModel> _rows = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final injected = widget.initialRows;
    if (injected != null) {
      _rows = injected;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final loader = widget.loader ?? StockTransferService.getTransfers;
      final rows = await loader();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rows = const [];
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  String _fmtQty(double q) {
    if (q == q.roundToDouble()) return q.toStringAsFixed(0);
    return q.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FD),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate('field_sales.stubs.stock_movement'),
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            onPressed: _load,
            tooltip: l10n.translate('field_sales.sales_targets.refresh'),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _rows.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.translate('field_sales.stock_movement.empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  itemCount: _rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    final code = row.productCode?.trim().isNotEmpty == true
                        ? row.productCode!
                        : row.productId;
                    final name = row.productName?.trim().isNotEmpty == true
                        ? row.productName!
                        : code;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF1F1B24) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: FieldSalesDensAppBar.primaryColor
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _fmtQty(row.quantity),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${row.fromWarehouse} → ${row.toWarehouse}'
                            ' · ${_fmtDate(row.transferDate)}'
                            ' · ${row.status}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
