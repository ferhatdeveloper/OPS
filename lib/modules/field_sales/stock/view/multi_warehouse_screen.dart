// Dosya Adı: multi_warehouse_screen.dart
// Açıklama: Çoklu ambar dens listesi (SQLite warehouses master)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localization.dart';
import '../../../../service/database_service.dart';
import '../model/warehouse_dens_row.dart';
import '../model/warehouse_master_seed.dart';

/// {@template multi_warehouse_screen}
/// Çoklu ambar dens listesi — SQLite `warehouses` (WHMS değil).
///
/// Dens alanlar: Kod · Ad · Tip.
/// Rota: `/field-sales/multi-warehouse`
///
/// Kullanım örneği:
/// ```dart
/// Navigator.pushNamed(context, MultiWarehouseScreen.routeName);
/// // Test:
/// MultiWarehouseScreen(rows: WarehouseDensRow.fromSeed());
/// ```
/// {@endtemplate}
class MultiWarehouseScreen extends StatefulWidget {
  /// [routeName]: GoRouter / named route yolu
  static const String routeName = '/field-sales/multi-warehouse';

  /// [rows]: Opsiyonel dens satırlar (null → SQLite / seed)
  final List<WarehouseDensRow>? rows;

  const MultiWarehouseScreen({
    Key? key,
    this.rows,
  }) : super(key: key);

  /// {@template multi_warehouse_apply_dens_cache}
  /// Test / senkron: warehouses map listesinden dens önbellek.
  ///
  /// Parametreler:
  /// - [maps]: SQLite warehouses satırları
  ///
  /// Dönüş değeri:
  /// - [int]: Aktif dens satır sayısı
  /// {@endtemplate}
  static int applyDensCacheFromMaps(List<Map<String, dynamic>> maps) {
    densRows = WarehouseDensRow.fromWarehouseMaps(maps);
    densCount = densRows.length;
    return densCount;
  }

  /// Son yüklenen dens satırlar (önbellek).
  static List<WarehouseDensRow> densRows = const [];

  /// Dashboard / menü için dens adet (önbellek).
  static int densCount = 0;

  /// {@template multi_warehouse_refresh_dens_cache}
  /// SQLite `warehouses` tablosundan dens önbelleği yeniler.
  /// Boş/hata → [WarehouseMasterSeed] fallback.
  ///
  /// Dönüş değeri:
  /// - [int]: Aktif dens satır sayısı
  /// {@endtemplate}
  static Future<int> refreshDensCache() async {
    try {
      final dbService = await DatabaseService.getInstance();
      await dbService.ensureWarehousesSchema();
      final sqliteDb = await dbService.getDatabase();
      final maps = await sqliteDb.query(WarehouseMasterSeed.tableName);
      if (maps.isEmpty) {
        return applyDensCacheFromMaps(WarehouseMasterSeed.defaultMaps);
      }
      return applyDensCacheFromMaps(maps);
    } catch (_) {
      return applyDensCacheFromMaps(WarehouseMasterSeed.defaultMaps);
    }
  }

  @override
  State<MultiWarehouseScreen> createState() => _MultiWarehouseScreenState();
}

class _MultiWarehouseScreenState extends State<MultiWarehouseScreen> {
  /// [_rows]: Dens ambar satırları
  late List<WarehouseDensRow> _rows;

  /// [_loading]: İlk yükleme
  late bool _loading;

  @override
  void initState() {
    super.initState();
    final injected = widget.rows;
    if (injected != null) {
      _rows = injected;
      _loading = false;
      MultiWarehouseScreen.densRows = injected;
      MultiWarehouseScreen.densCount = injected.length;
    } else {
      _rows = const [];
      _loading = true;
      _loadWarehouses();
    }
  }

  /// {@template multi_warehouse_load}
  /// Ambar dens satırlarını SQLite’dan yükler (inject yoksa).
  /// {@endtemplate}
  Future<void> _loadWarehouses() async {
    setState(() => _loading = true);
    try {
      await MultiWarehouseScreen.refreshDensCache();
      if (!mounted) return;
      setState(() {
        _rows = MultiWarehouseScreen.densRows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      final fallback = WarehouseDensRow.fromSeed();
      setState(() {
        _rows = fallback;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalization.of(context);
    final title = l10n.translate('field_sales.stubs.multi_warehouse');
    final rows = _rows;

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
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.rows == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadWarehouses,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
              ? Center(
                  child: Text(
                    l10n.translate('field_sales.multi_warehouse.empty'),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        l10n.translate(
                          'field_sales.multi_warehouse.list_hint',
                        ),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        l10n
                            .translate(
                              'field_sales.multi_warehouse.count_label',
                            )
                            .replaceAll('{count}', '${rows.length}'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.code_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.name_col',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              l10n.translate(
                                'field_sales.multi_warehouse.type_col',
                              ),
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
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = rows[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF375A7F)
                                      .withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    l10n.translate(item.typeNameKey),
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
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
