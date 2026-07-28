// Dosya Adı: stock_transfer_list_screen.dart
// Açıklama: Stok transfer edilen/edilmeyen dens liste — SQLite warehouse_transfers
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/localization/app_localization.dart';
import '../../shared/view/field_sales_dens_app_bar.dart';
import '../engine/stock_transfer_service.dart';
import '../model/stock_transfer_model.dart';

/// {@template stock_transfer_list_mode}
/// Transfer listesi modu (edilen / edilmeyen).
/// {@endtemplate}
enum StockTransferListMode {
  /// Transfer edilen stok fişleri (is_synced=1)
  transferred,

  /// Transfer edilmeyen stok fişleri (is_synced=0)
  untransferred,
}

/// {@template stock_transfer_dens_group}
/// Dens grup satırı: depo · tarih · satır adedi.
/// {@endtemplate}
class StockTransferDensGroup {
  /// [id]: Grup anahtarı
  final String id;

  /// [warehouse]: Kaynak→hedef özeti
  final String warehouse;

  /// [date]: Görünen tarih
  final String date;

  /// [lineCount]: Kalem sayısı
  final int lineCount;

  /// [synced]: Sync durumu
  final bool synced;

  /// {@macro stock_transfer_dens_group}
  const StockTransferDensGroup({
    required this.id,
    required this.warehouse,
    required this.date,
    required this.lineCount,
    required this.synced,
  });
}

/// {@template stock_transfer_list_screen}
/// Stok transfer listesi dens — SQLite `warehouse_transfers` gruplu.
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
class StockTransferListScreen extends StatefulWidget {
  /// [routeTransferred]: Transfer edilenler yolu
  static const String routeTransferred = '/field-sales/stock-transferred';

  /// [routeUntransferred]: Transfer edilmeyenler yolu
  static const String routeUntransferred = '/field-sales/stock-untransferred';

  /// [mode]: Liste filtresi
  final StockTransferListMode mode;

  /// [initialGroups]: Test enjeksiyonu
  final List<StockTransferDensGroup>? initialGroups;

  /// [loader]: Test / özel yükleyici
  final Future<List<StockTransferModel>> Function()? loader;

  /// {@macro stock_transfer_list_screen}
  const StockTransferListScreen({
    Key? key,
    required this.mode,
    this.initialGroups,
    this.loader,
  }) : super(key: key);

  /// {@template stock_transfer_list_group_rows}
  /// Satırları dens gruplara çevirir (gün + kaynak/hedef + sync).
  ///
  /// Parametreler:
  /// - [rows]: Ham transfer satırları
  /// - [syncedOnly]: true → is_synced=1; false → is_synced=0
  ///
  /// Dönüş değeri:
  /// - [List]<[StockTransferDensGroup]>
  /// {@endtemplate}
  static List<StockTransferDensGroup> groupRows(
    List<StockTransferModel> rows, {
    required bool syncedOnly,
  }) {
    final filtered = rows.where((r) => r.isSynced == syncedOnly);
    final map = <String, StockTransferDensGroup>{};
    for (final r in filtered) {
      final day = DateTime(
        r.transferDate.year,
        r.transferDate.month,
        r.transferDate.day,
      );
      final key =
          '${r.fromWarehouse}|${r.toWarehouse}|${day.toIso8601String()}|'
          '${r.isSynced ? 1 : 0}';
      final existing = map[key];
      if (existing == null) {
        map[key] = StockTransferDensGroup(
          id: key,
          warehouse: '${r.fromWarehouse} → ${r.toWarehouse}',
          date: _fmtDate(day),
          lineCount: 1,
          synced: r.isSynced,
        );
      } else {
        map[key] = StockTransferDensGroup(
          id: existing.id,
          warehouse: existing.warehouse,
          date: existing.date,
          lineCount: existing.lineCount + 1,
          synced: existing.synced,
        );
      }
    }
    final list = map.values.toList(growable: false);
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  @override
  State<StockTransferListScreen> createState() =>
      _StockTransferListScreenState();
}

class _StockTransferListScreenState extends State<StockTransferListScreen> {
  List<StockTransferDensGroup> _groups = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final injected = widget.initialGroups;
    if (injected != null) {
      _groups = injected;
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
        _groups = StockTransferListScreen.groupRows(
          rows,
          syncedOnly: widget.mode == StockTransferListMode.transferred,
        );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _groups = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final titleKey = widget.mode == StockTransferListMode.transferred
        ? 'field_sales.stubs.stock_transferred'
        : 'field_sales.stubs.stock_untransferred';

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: FieldSalesDensAppBar(
        title: l10n.translate(titleKey),
        actions: [
          FieldSalesDensAppBar.densIconButton(
            icon: Icons.refresh,
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              l10n.translate('field_sales.stock_slip.list_hint'),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
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
            child: _loading
                ? const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _groups.isEmpty
                    ? Center(
                        child: Text(
                          l10n.translate('field_sales.queue_empty'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        itemCount: _groups.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final g = _groups[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: FieldSalesDensTheme.surface(context),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: FieldSalesDensAppBar.primaryColor
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    g.warehouse,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 88,
                                  child: Text(
                                    g.date,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                SizedBox(
                                  width: 72,
                                  child: Text(
                                    l10n.translate(
                                      'field_sales.stock_slip.line_count',
                                    ).replaceAll(
                                      '{count}',
                                      '${g.lineCount}',
                                    ),
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
