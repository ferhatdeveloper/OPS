// Dosya Adı: stock_transfer_list_screen.dart
// Açıklama: Stok transfer edilen/edilmeyen dens liste iskeleti
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';

/// {@template stock_transfer_list_mode}
/// Transfer listesi modu (edilen / edilmeyen).
/// {@endtemplate}
enum StockTransferListMode {
  /// Transfer edilen stok fişleri
  transferred,

  /// Transfer edilmeyen stok fişleri
  untransferred,
}

/// {@template stock_transfer_list_screen}
/// Stok transfer listesi dens iskeleti — her satırda Depo · Tarih · Satırlar.
///
/// Rotalar:
/// - `/field-sales/stock-transferred`
/// - `/field-sales/stock-untransferred`
///
/// Kullanım örneği:
/// ```dart
/// const StockTransferListScreen(mode: StockTransferListMode.transferred);
/// ```
/// {@endtemplate}
class StockTransferListScreen extends StatelessWidget {
  /// [routeTransferred]: Transfer edilenler yolu
  static const String routeTransferred = '/field-sales/stock-transferred';

  /// [routeUntransferred]: Transfer edilmeyenler yolu
  static const String routeUntransferred = '/field-sales/stock-untransferred';

  /// [mode]: Liste filtresi
  final StockTransferListMode mode;

  const StockTransferListScreen({
    Key? key,
    required this.mode,
  }) : super(key: key);

  /// Yer tutucu dens satırlar (alanlar görünür olsun).
  List<Map<String, String>> _placeholderRows(AppLocalization l10n) {
    final warehouseCenter =
        l10n.translate('field_sales.stock_slip.warehouse_center');
    final warehouseVehicle =
        l10n.translate('field_sales.stock_slip.warehouse_vehicle');
    if (mode == StockTransferListMode.transferred) {
      return [
        {
          'id': 'STK-T-001',
          'warehouse': warehouseCenter,
          'date': '24.07.2026',
          'lines': '4',
        },
        {
          'id': 'STK-T-002',
          'warehouse': warehouseVehicle,
          'date': '25.07.2026',
          'lines': '2',
        },
      ];
    }
    return [
      {
        'id': 'STK-U-001',
        'warehouse': warehouseVehicle,
        'date': '26.07.2026',
        'lines': '3',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final titleKey = mode == StockTransferListMode.transferred
        ? 'field_sales.stubs.stock_transferred'
        : 'field_sales.stubs.stock_untransferred';
    final rows = _placeholderRows(l10n);

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
          l10n.translate(titleKey),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              l10n.translate('field_sales.stock_slip.list_hint'),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.translate('field_sales.stock_slip.warehouse'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 88,
                  child: Text(
                    l10n.translate('field_sales.stock_slip.date'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    l10n.translate('field_sales.stock_slip.lines'),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final row = rows[index];
                final linesLabel = l10n
                    .translate('field_sales.stock_slip.line_count')
                    .replaceAll('{count}', row['lines']!);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF375A7F).withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row['id']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              row['warehouse']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 88,
                            child: Text(
                              row['date']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              linesLabel,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
