// Dosya Adı: local_warehouse_stock_balance_port.dart
// Açıklama: Yerel SQLite StockBalancePort (warehouse_stocks + vehicle_stocks)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import 'package:sqflite/sqflite.dart';

import '../../field_sales/stock/model/warehouse_master_seed.dart';
import '../contract/stock_balance.dart';
import '../contract/stock_balance_port.dart';
import '../mapper/whms_payload_mapper.dart';
import 'warehouse_stocks_table.dart';

/// {@template local_warehouse_stock_balance_port}
/// R1 yerel implementasyon: ambar → `warehouse_stocks`, araç → `vehicle_stocks`.
///
/// Kullanım örneği:
/// ```dart
/// final port = LocalWarehouseStockBalancePort(db);
/// final bal = await port.getBalance(
///   productId: 'prod_1',
///   warehouseCode: 'MRK',
/// );
/// ```
/// {@endtemplate}
class LocalWarehouseStockBalancePort implements StockBalancePort {
  /// [db]: SQLite executor
  final DatabaseExecutor db;

  /// {@macro local_warehouse_stock_balance_port}
  const LocalWarehouseStockBalancePort(this.db);

  @override
  Future<StockBalance> getBalance({
    required String productId,
    required String warehouseCode,
    String? vehicleId,
  }) async {
    final code = WhmsPayloadMapper.normalizeWarehouseCode(warehouseCode);
    final seed = WarehouseMasterSeed.byCode(code);
    final isVan = seed?.type == WarehouseMasterSeed.typeVehicle ||
        code == 'ARC';

    if (isVan) {
      return _vanBalance(
        productId: productId,
        warehouseCode: code,
        vehicleId: vehicleId,
      );
    }

    return _warehouseBalance(
      productId: productId,
      warehouseCode: code,
    );
  }

  @override
  Future<List<StockBalance>> listByWarehouse({
    required String warehouseCode,
    String? vehicleId,
  }) async {
    final code = WhmsPayloadMapper.normalizeWarehouseCode(warehouseCode);
    final seed = WarehouseMasterSeed.byCode(code);
    final isVan = seed?.type == WarehouseMasterSeed.typeVehicle ||
        code == 'ARC';

    if (isVan) {
      final vid = vehicleId?.trim();
      if (vid == null || vid.isEmpty) return const [];
      final rows = await db.query(
        'vehicle_stocks',
        where: 'vehicle_id = ?',
        whereArgs: [vid],
      );
      return rows
          .map(
            (r) => StockBalance(
              productId: r['product_id']?.toString() ?? '',
              warehouseCode: code,
              quantity: (r['quantity'] as num?)?.toDouble() ?? 0,
              bucket: StockBalanceBucket.van,
              source: 'local',
              vehicleId: vid,
            ),
          )
          .where((b) => b.productId.isNotEmpty)
          .toList(growable: false);
    }

    final rows = await db.query(
      WarehouseStocksTable.name,
      where: '${WarehouseStocksTable.colWarehouseCode} = ?',
      whereArgs: [code],
    );
    return rows
        .map(
          (r) => StockBalance(
            productId: r[WarehouseStocksTable.colProductId]?.toString() ?? '',
            warehouseCode: code,
            quantity:
                (r[WarehouseStocksTable.colQuantity] as num?)?.toDouble() ?? 0,
            bucket: StockBalanceBucket.warehouse,
            source: 'local',
          ),
        )
        .where((b) => b.productId.isNotEmpty)
        .toList(growable: false);
  }

  Future<StockBalance> _warehouseBalance({
    required String productId,
    required String warehouseCode,
  }) async {
    try {
      final rows = await db.query(
        WarehouseStocksTable.name,
        columns: [WarehouseStocksTable.colQuantity],
        where:
            '${WarehouseStocksTable.colWarehouseCode} = ? AND '
            '${WarehouseStocksTable.colProductId} = ?',
        whereArgs: [warehouseCode, productId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return StockBalance(
          productId: productId,
          warehouseCode: warehouseCode,
          quantity:
              (rows.first[WarehouseStocksTable.colQuantity] as num?)
                      ?.toDouble() ??
                  0,
          bucket: StockBalanceBucket.warehouse,
          source: 'local',
        );
      }
    } catch (_) {
      // tablo yoksa products fallback
    }

    // Geriye dönük: tek products.stock_quantity (yalnız MRK)
    if (warehouseCode == 'MRK') {
      try {
        final products = await db.query(
          'products',
          columns: ['stock_quantity'],
          where: 'id = ?',
          whereArgs: [productId],
          limit: 1,
        );
        if (products.isNotEmpty) {
          return StockBalance(
            productId: productId,
            warehouseCode: warehouseCode,
            quantity:
                (products.first['stock_quantity'] as num?)?.toDouble() ?? 0,
            bucket: StockBalanceBucket.warehouse,
            source: 'local',
          );
        }
      } catch (_) {}
    }

    return StockBalance(
      productId: productId,
      warehouseCode: warehouseCode,
      quantity: 0,
      bucket: StockBalanceBucket.warehouse,
      source: 'local',
    );
  }

  Future<StockBalance> _vanBalance({
    required String productId,
    required String warehouseCode,
    String? vehicleId,
  }) async {
    var vid = vehicleId?.trim();
    if (vid == null || vid.isEmpty) {
      try {
        final vehicles = await db.query(
          'vehicles',
          columns: ['id'],
          where: 'is_active = 1',
          limit: 1,
        );
        if (vehicles.isNotEmpty) {
          vid = vehicles.first['id']?.toString();
        }
      } catch (_) {}
    }

    if (vid == null || vid.isEmpty) {
      return StockBalance(
        productId: productId,
        warehouseCode: warehouseCode,
        quantity: 0,
        bucket: StockBalanceBucket.van,
        source: 'local',
      );
    }

    try {
      final rows = await db.query(
        'vehicle_stocks',
        columns: ['quantity'],
        where: 'vehicle_id = ? AND product_id = ?',
        whereArgs: [vid, productId],
        limit: 1,
      );
      final qty = rows.isEmpty
          ? 0.0
          : (rows.first['quantity'] as num?)?.toDouble() ?? 0;
      return StockBalance(
        productId: productId,
        warehouseCode: warehouseCode,
        quantity: qty,
        bucket: StockBalanceBucket.van,
        source: 'local',
        vehicleId: vid,
      );
    } catch (_) {
      return StockBalance(
        productId: productId,
        warehouseCode: warehouseCode,
        quantity: 0,
        bucket: StockBalanceBucket.van,
        source: 'local',
        vehicleId: vid,
      );
    }
  }
}
