// Dosya Adı: warehouse_stock_query_store.dart
// Açıklama: Ambar stok sorgu — yerel StockBalancePort + ürün adı join
// Oluşturulma Tarihi: 2026-07-28
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-28

import 'package:sqflite/sqflite.dart';

import '../../../../service/database_service.dart';
import '../../../whms/contract/stock_balance.dart';
import '../../../whms/data/local_warehouse_stock_balance_port.dart';
import '../model/warehouse_master_seed.dart';

/// {@template warehouse_stock_query_row}
/// Dens stok sorgu satırı (ürün + miktar).
///
/// Kullanım örneği:
/// ```dart
/// const row = WarehouseStockQueryRow(
///   productId: 'p1',
///   productCode: 'SKU-1',
///   productName: 'Ürün',
///   quantity: 12,
///   warehouseCode: 'MRK',
///   bucket: StockBalanceBucket.warehouse,
/// );
/// ```
/// {@endtemplate}
class WarehouseStockQueryRow {
  /// [productId]: Ürün kimliği
  final String productId;

  /// [productCode]: Stok / ürün kodu
  final String productCode;

  /// [productName]: Görünen ad
  final String productName;

  /// [quantity]: Ana birim miktar
  final double quantity;

  /// [warehouseCode]: Ambar kodu
  final String warehouseCode;

  /// [bucket]: Ambar veya van
  final StockBalanceBucket bucket;

  /// {@macro warehouse_stock_query_row}
  const WarehouseStockQueryRow({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.quantity,
    required this.warehouseCode,
    required this.bucket,
  });
}

/// {@template warehouse_stock_query_store}
/// Ambar stok sorgu: `LocalWarehouseStockBalancePort` + products join.
///
/// Kullanım örneği:
/// ```dart
/// final rows = await const WarehouseStockQueryStore().listForWarehouse('MRK');
/// ```
/// {@endtemplate}
class WarehouseStockQueryStore {
  /// [dbOverride]: Test enjeksiyonu
  final DatabaseExecutor? dbOverride;

  /// [portOverride]: Test enjeksiyonu
  final LocalWarehouseStockBalancePort? portOverride;

  /// {@macro warehouse_stock_query_store}
  const WarehouseStockQueryStore({
    this.dbOverride,
    this.portOverride,
  });

  Future<DatabaseExecutor> _db() async {
    final override = dbOverride;
    if (override != null) return override;
    final svc = await DatabaseService.getInstance();
    return svc.getDatabase();
  }

  /// {@template warehouse_stock_query_store_list}
  /// Ambar koduna göre dens bakiye satırları (ürün adı ile).
  ///
  /// Parametreler:
  /// - [warehouseCode]: MRK / ARC / IAD vb.
  /// - [vehicleId]: Van kovası için opsiyonel araç
  /// - [query]: Kod/ad filtre (boş = tümü)
  ///
  /// Dönüş değeri:
  /// - [List]<[WarehouseStockQueryRow]>
  /// {@endtemplate}
  Future<List<WarehouseStockQueryRow>> listForWarehouse(
    String warehouseCode, {
    String? vehicleId,
    String query = '',
  }) async {
    final code = warehouseCode.trim().toUpperCase();
    if (code.isEmpty) return const [];

    final db = await _db();
    final port = portOverride ?? LocalWarehouseStockBalancePort(db);
    final balances = await port.listByWarehouse(
      warehouseCode: code,
      vehicleId: vehicleId,
    );
    if (balances.isEmpty) return const [];

    final names = await _productLabels(
      db,
      balances.map((b) => b.productId).toSet(),
    );

    final q = query.trim().toLowerCase();
    final rows = <WarehouseStockQueryRow>[];
    for (final bal in balances) {
      final label = names[bal.productId];
      final codeLabel = label?.$1 ?? bal.productId;
      final nameLabel = label?.$2 ?? bal.productId;
      if (q.isNotEmpty) {
        final hay = '$codeLabel $nameLabel ${bal.productId}'.toLowerCase();
        if (!hay.contains(q)) continue;
      }
      rows.add(
        WarehouseStockQueryRow(
          productId: bal.productId,
          productCode: codeLabel,
          productName: nameLabel,
          quantity: bal.quantity,
          warehouseCode: bal.warehouseCode,
          bucket: bal.bucket,
        ),
      );
    }
    rows.sort(
      (a, b) => a.productName.toLowerCase().compareTo(
            b.productName.toLowerCase(),
          ),
    );
    return rows;
  }

  /// Seed ambar kodları (chip sırası).
  List<String> warehouseCodes() {
    return WarehouseMasterSeed.defaultRows
        .map((r) => r.code)
        .toList(growable: false);
  }

  Future<Map<String, (String, String)>> _productLabels(
    DatabaseExecutor db,
    Set<String> productIds,
  ) async {
    if (productIds.isEmpty) return const {};
    final out = <String, (String, String)>{};
    try {
      final placeholders = List.filled(productIds.length, '?').join(',');
      final rows = await db.rawQuery(
        '''
        SELECT id, code, name FROM products
        WHERE id IN ($placeholders)
        ''',
        productIds.toList(growable: false),
      );
      for (final r in rows) {
        final id = r['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        out[id] = (
          r['code']?.toString() ?? id,
          r['name']?.toString() ?? id,
        );
      }
    } catch (_) {
      // products yoksa id ile devam
    }
    return out;
  }
}
