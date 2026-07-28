// Dosya Adı: collections_transferred_screen.dart
// Açıklama: Transfer edilen tahsilat dens listesi (SQLite is_synced=1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';
import '../../shared/view/field_sales_dens_theme.dart';

import '../../../../core/database/migrations/SqlQuerys.dart';
import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/collection_transferred_row.dart';

/// {@template collections_transferred_screen}
/// Transfer edilen tahsilatlar dens listesi (MBT FİNANS).
/// Kaynak: SQLite `collections` WHERE `is_synced = 1`.
/// Route: `/field-sales/finance-transferred`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, CollectionsTransferredScreen.routeName);
/// ```
/// {@endtemplate}
class CollectionsTransferredScreen extends StatefulWidget {
  /// [routeName]: Named route — `/field-sales/finance-transferred`
  static const String routeName = '/field-sales/finance-transferred';

  /// Dens önbellek — transfer edilen satır adedi.
  static int densCount = 0;

  /// Son yüklenen dens satırlar (test / senkron).
  static List<CollectionTransferredRow> densRows = const [];

  const CollectionsTransferredScreen({Key? key}) : super(key: key);

  /// {@template applyDensCacheFromMaps}
  /// Test / senkron: collections map listesinden dens önbelleğini günceller.
  ///
  /// Parametreler:
  /// - [maps]: SQLite collections satırları
  ///
  /// Dönüş değeri:
  /// - [int]: Transfer dens satır sayısı
  /// {@endtemplate}
  static int applyDensCacheFromMaps(List<Map<String, dynamic>> maps) {
    densRows = CollectionTransferredRow.fromCollectionMaps(maps);
    densCount = densRows.length;
    return densCount;
  }

  /// {@template refreshDensCache}
  /// SQLite’tan transfer edilen tahsilat dens önbelleğini yeniler.
  ///
  /// Dönüş değeri:
  /// - [int]: Dens satır sayısı (hata → 0)
  /// {@endtemplate}
  static Future<int> refreshDensCache() async {
    try {
      final db = await DatabaseService.getInstance();
      await db.ensureCollectionsTableSchema();
      final sqliteDb = await db.getDatabase();
      final maps = await sqliteDb.rawQuery(
        SqlQuerys.collectionsTransferredDensSql,
      );
      return applyDensCacheFromMaps(maps);
    } catch (_) {
      densRows = const [];
      densCount = 0;
      return 0;
    }
  }

  @override
  State<CollectionsTransferredScreen> createState() =>
      _CollectionsTransferredScreenState();
}

class _CollectionsTransferredScreenState
    extends State<CollectionsTransferredScreen> {
  /// [_rows]: Transfer dens satırları
  List<CollectionTransferredRow> _rows = const [];

  /// [_loading]: İlk yükleme
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTransferred();
  }

  /// {@template _loadTransferred}
  /// is_synced=1 tahsilatları SQLite’tan yükler.
  /// {@endtemplate}
  Future<void> _loadTransferred() async {
    setState(() => _loading = true);
    try {
      await CollectionsTransferredScreen.refreshDensCache();
      if (!mounted) return;
      setState(() {
        _rows = CollectionsTransferredScreen.densRows;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.collections_transferred');
    final rows = _rows;

    return Scaffold(
      backgroundColor: FieldSalesDensTheme.bodyBackground(context),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF375A7F),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate(
                      'field_sales.collections_transferred_empty',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        l10n
                            .translate(
                              'field_sales.collections_transferred_count',
                            )
                            .replaceAll('{count}', '${rows.length}'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadTransferred,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: rows.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return _TransferredDensTile(
                              row: rows[index],
                              l10n: l10n,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

/// {@template transferred_dens_tile}
/// Tek transfer edilen tahsilat dens satırı.
/// {@endtemplate}
class _TransferredDensTile extends StatelessWidget {
  /// [row]: Dens satır
  final CollectionTransferredRow row;

  /// [l10n]: Yerelleştirme
  final AppLocalization l10n;

  /// {@macro transferred_dens_tile}
  const _TransferredDensTile({
    required this.row,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final typeLabel = l10n.translate(row.paymentTypeL10nKey);
    final metaParts = <String>[
      row.dateDisplay,
      typeLabel,
      if (row.documentNo != null) row.documentNo!,
      if (row.cashCode != null) row.cashCode!,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FieldSalesDensTheme.surface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FieldSalesDensTheme.bodyBackground(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.cloud_done_outlined,
              color: Color(0xFF375A7F),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  metaParts.join(' · '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.amountDisplay,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF375A7F),
            ),
          ),
        ],
      ),
    );
  }
}
