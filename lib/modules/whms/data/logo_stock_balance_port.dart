// Dosya Adı: logo_stock_balance_port.dart
// Açıklama: Logo getStock / inventory → StockBalancePort (WHMS Faz 2.1)
// Oluşturulma Tarihi: 2026-07-26
// Geliştirici: Ferhat NAS
// Son Güncelleme: 2026-07-26

import '../../../core/services/logo_api_service.dart';
import '../../field_sales/stock/model/warehouse_master_seed.dart';
import '../contract/stock_balance.dart';
import '../contract/stock_balance_port.dart';
import '../mapper/whms_payload_mapper.dart';
import 'logo_stock_row_parser.dart';

/// {@template logo_stock_fetcher}
/// Tek ürün için Logo stok satırları.
///
/// Parametreler:
/// - [itemCode]: Malzeme kodu
///
/// Dönüş değeri:
/// - [List]: Ham satır map listesi
/// {@endtemplate}
typedef LogoStockFetcher = Future<List<Map<String, dynamic>>> Function(
  String itemCode,
);

/// {@template logo_inventory_fetcher}
/// Envanter / tüm stok satırları (listByWarehouse).
///
/// Dönüş değeri:
/// - [List]: Ham satır map listesi
/// {@endtemplate}
typedef LogoInventoryFetcher = Future<List<Map<String, dynamic>>> Function();

/// {@template logo_stock_balance_port}
/// Ambar bakiyesini Logo'dan okur; van (ARC) her zaman [fallback] üzerinden.
/// Logo hata / boş yanıtta yerel porta düşer (offline-first).
///
/// Kullanım örneği:
/// ```dart
/// final port = LogoStockBalancePort.fromApi(
///   api: LogoApiService(),
///   fallback: LocalWarehouseStockBalancePort(db),
/// );
/// final bal = await port.getBalance(
///   productId: 'SKU-1',
///   warehouseCode: 'MRK',
/// );
/// ```
/// {@endtemplate}
class LogoStockBalancePort implements StockBalancePort {
  /// [fallback]: Van + Logo başarısızlığında yerel port
  final StockBalancePort fallback;

  /// [fetchStock]: Ürün stok satırları
  final LogoStockFetcher fetchStock;

  /// [fetchInventory]: Ambar listesi için envanter
  final LogoInventoryFetcher fetchInventory;

  /// {@macro logo_stock_balance_port}
  const LogoStockBalancePort({
    required this.fallback,
    required this.fetchStock,
    required this.fetchInventory,
  });

  /// {@template logo_stock_balance_port_from_api}
  /// [LogoApiService] bağlayan fabrika.
  ///
  /// Parametreler:
  /// - [api]: Logo REST istemcisi
  /// - [fallback]: Yerel / van portu
  ///
  /// Dönüş değeri:
  /// - [LogoStockBalancePort]: Hazır port
  /// {@endtemplate}
  factory LogoStockBalancePort.fromApi({
    required LogoApiService api,
    required StockBalancePort fallback,
  }) {
    return LogoStockBalancePort(
      fallback: fallback,
      fetchStock: (itemCode) => api.getStockStatus(itemCode: itemCode),
      fetchInventory: () => api.getStockStatus(),
    );
  }

  @override
  Future<StockBalance> getBalance({
    required String productId,
    required String warehouseCode,
    String? vehicleId,
  }) async {
    final code = WhmsPayloadMapper.normalizeWarehouseCode(warehouseCode);
    if (_isVan(code)) {
      return fallback.getBalance(
        productId: productId,
        warehouseCode: code,
        vehicleId: vehicleId,
      );
    }

    try {
      final rows = await fetchStock(productId);
      final qty = _sumForWarehouse(
        rows: rows,
        productId: productId,
        warehouseCode: code,
      );
      if (rows.isEmpty) {
        return fallback.getBalance(
          productId: productId,
          warehouseCode: code,
          vehicleId: vehicleId,
        );
      }
      return StockBalance(
        productId: productId,
        warehouseCode: code,
        quantity: qty,
        bucket: StockBalanceBucket.warehouse,
        source: 'logo',
      );
    } catch (_) {
      return fallback.getBalance(
        productId: productId,
        warehouseCode: code,
        vehicleId: vehicleId,
      );
    }
  }

  @override
  Future<List<StockBalance>> listByWarehouse({
    required String warehouseCode,
    String? vehicleId,
  }) async {
    final code = WhmsPayloadMapper.normalizeWarehouseCode(warehouseCode);
    if (_isVan(code)) {
      return fallback.listByWarehouse(
        warehouseCode: code,
        vehicleId: vehicleId,
      );
    }

    try {
      final rows = await fetchInventory();
      if (rows.isEmpty) {
        return fallback.listByWarehouse(
          warehouseCode: code,
          vehicleId: vehicleId,
        );
      }
      final byProduct = <String, double>{};
      for (final row in rows) {
        if (!LogoStockRowParser.matchesWarehouse(row, code)) continue;
        final pid = LogoStockRowParser.itemCode(row);
        if (pid.isEmpty) continue;
        byProduct[pid] =
            (byProduct[pid] ?? 0) + LogoStockRowParser.quantity(row);
      }
      if (byProduct.isEmpty) {
        return fallback.listByWarehouse(
          warehouseCode: code,
          vehicleId: vehicleId,
        );
      }
      return byProduct.entries
          .map(
            (e) => StockBalance(
              productId: e.key,
              warehouseCode: code,
              quantity: e.value,
              bucket: StockBalanceBucket.warehouse,
              source: 'logo',
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return fallback.listByWarehouse(
        warehouseCode: code,
        vehicleId: vehicleId,
      );
    }
  }

  bool _isVan(String code) {
    final seed = WarehouseMasterSeed.byCode(code);
    return seed?.type == WarehouseMasterSeed.typeVehicle || code == 'ARC';
  }

  double _sumForWarehouse({
    required List<Map<String, dynamic>> rows,
    required String productId,
    required String warehouseCode,
  }) {
    var sum = 0.0;
    var matched = false;
    for (final row in rows) {
      final item = LogoStockRowParser.itemCode(row);
      if (item.isNotEmpty &&
          item != productId &&
          item.toUpperCase() != productId.toUpperCase()) {
        continue;
      }
      if (!LogoStockRowParser.matchesWarehouse(row, warehouseCode)) {
        continue;
      }
      matched = true;
      sum += LogoStockRowParser.quantity(row);
    }
    if (!matched && rows.length == 1) {
      return LogoStockRowParser.quantity(rows.first);
    }
    return sum;
  }
}
